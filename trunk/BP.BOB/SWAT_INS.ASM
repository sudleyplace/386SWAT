;' $Header$
	title	SWAT_INS -- 386SWAT INSERT Command
	page	58,122
	name	SWAT_INS

COMMENT|		Module Specifications

Copyright:  (C) Copyright 2001 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, January, 2001.

Modifications by:  None.


|
.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include ALLMEM.INC
	include VCPI.INC

	include SWAT_CMD.INC
	include SWAT_COM.INC
	include SWAT_DRV.INC
	include SWAT_SEG.INC
	include SWAT_VCP.INC
.list

RCODE	segment use16 para public 'rcode' ; Start RCODE segment
	assume	cs:RGROUP,ds:RGROUP

	public	@SWAT_INS_RCODE
@SWAT_INS_RCODE label byte	; Mark module start in .MAP file

	extrn	TRP_FLAG:dword

RCODE	ends			; End RCODE segment


DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	public	@SWAT_INS_DATA16
@SWAT_INS_DATA16 label byte	; Mark module start in .MAP file

	extrn	COMMON:tbyte
	include SWAT_FIL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	SWATCODE:dword
	extrn	SWATDATA:dword
	extrn	VCPICODE:dword
	extrn	VCPICODE_LIM:dword
	extrn	VCPIDATA:dword
	extrn	RGRSEG2:word

	public	CntINSERT,PINSERT,PaINSERT
CntINSERT dd	2		; # pages needed by INSERT command
PINSERT dd	?		; Offset in DGROUP of INSERT pages
PaINSERT dd	?		; Physical address of 1st INSERT page

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	@SWAT_INS_DATA
@SWAT_INS_DATA label byte	; Mark module start in .MAP file

	extrn	CON4KB:dword
	extrn	MSGOFF:dword
	extrn	SYNTERR:byte
	extrn	OVFERR:byte

@INSINTS equ	<01,03,0D,0E>

%	irp	XX,<@INSINTS>
	extrn	LCLPMG&XX&:tbyte
	extrn	LCLPMG&XX&_FVEC:fword
	endm			; IRP

	extrn	VCP_FLAG:word
	extrn	CODESEL:word
;;;;;;; extrn	INDVCP_GDT:dword

	public	INSERT_EPM
INSERT_EPM VCPEPM_STR <>	; Save area for INSERT data values

	public	INS_SEL
INS_SEL dd	?		; INSERT initial selector

	public	INSERT_TSS
INSERT_TSS TSS_STR <>		; Local TSS for INSERT clients

	public	INSERT_LaPDE
INSERT_LaPDE dd ?		; LA of SWAT PDEs (/4MB)

	public	INSERT_FLAG
INSERT_FLAG dd	0		; INSERT flags

INS_REC record	\
$INS_GDTP:1,\
$INS_IDTP:1,\
$INS_CR3P:1, \
$INS_LaP:1, \
$INS_TRP:1, \
$INS_LDTRP:1

@INS_GDTP equ	mask $INS_GDTP	; GDT present
@INS_IDTP equ	mask $INS_IDTP	; IDT ...
@INS_CR3P equ	mask $INS_CR3P	; CR3 ...
@INS_LaP  equ	mask $INS_LaP	; La  ...
@INS_TRP  equ	mask $INS_TRP	; TR  ...
@INS_LDTRP equ	mask $INS_LDTRP ; LDTR	...

	public	INSERT_TR,INSERT_LDTR
INSERT_TR dd	18h		; ...	 TR
INSERT_LDTR dd	160h		; ...	 LDTR

	public	OLDGATE03_FVEC,OLDGATE03_ARB
OLDGATE03_FVEC df ?		; Save area for old INT 03h handler
OLDGATE03_ARB  db ?		; Save area for old INT 03h A/R byte
	db	?		; For alignment

	public	INSERT_SEL4GB
INSERT_SEL4GB dw ?		; 4GB selector for INSERT

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP

	public	@SWAT_INS_PROG
@SWAT_INS_PROG: 		; Mark module start in .MAP file

	extrn	CMD_WHITE:near
	extrn	PARSE_ADDR:near
	extrn	PARSE_EXPR:near
	extrn	IZITEOL:near
	extrn	LIN2PPTE:near
	extrn	LIN2PPDIR:near
	extrn	LIN2PPTEZ:near
	extrn	SET_TSSCR3:near
	extrn	FIND_OLDVCP_GDT:near
	extrn	INST_PMG:near
	extrn	SETTSS:near
;;;;;;; extrn	SEL2GDT:near
;;;;;;; extrn	MASK_STKREGS:near

	NPPROC	CMD_INSERT -- INSERT Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT!

INSERT [gdtr[#sel]|*] [idtr|*] [cr3|*] [lapde|*] [tr|*] [ldtr|*]

where gdtr = linear address of fword describing the GDT
      idtr = ...				    IDT
      cr3  = incoming CR3
      lapde= linear address of 4MB block where SWAT PDE(s) should be copied
      tr   = task register
      ldtr = LDT register

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

!

	pushad			; Save all EGP registers

; Parse the (actual or placeholder) GDTR

	call	IZITEOL 	; Izit end-of-the-line?
	je	near ptr CMD_INSERT_SYNTERR ; Yes, so that's an error

	mov	INSERT_EPM.VCPEPM_CR3,-1 ; Assume none
	mov	INSERT_EPM.VCPEPM_GDTP,-1 ; ...
	mov	INSERT_LaPDE,-1 ; ...
	mov	INSERT_FLAG,0	; ...

	cmp	ds:[esi].LO,'*' ; Izit omitted?
	je	short CMD_INSERT_XGDT ; Jump if so

	call	PARSE_ADDR	; Parse DS:ESI for address
	jc	near ptr CMD_INSERT_ERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)
	test	cx,@ADDR_SEP	; Separator specified?
	jz	near ptr CMD_INSERT_SYNTERR ; Not this time

	add	eax,edx 	; Add to get linear address
	mov	INSERT_EPM.VCPEPM_GDTP,eax ; Save for later use

	or	INSERT_FLAG,@INS_GDTP ; Mark as GDT present

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	cmp	al,'#'          ; Izit selector separator?
	jne	short @F	; Jump if not

	inc	esi		; Skip over it

	call	PARSE_EXPR	; Parse command line for an expression
	jc	near ptr CMD_INSERT_SYNTERR ; Jump if error

	mov	INS_SEL,eax	; Save for later use
@@:
	jmp	short CMD_INSERT_GDTCOM ; Join common code


CMD_INSERT_XGDT:
	inc	esi		; Skip over it
CMD_INSERT_GDTCOM:

; Parse the (actual or placeholder) IDTR

	call	IZITEOL 	; Izit end-of-the-line?
	je	near ptr CMD_INSERT_SYNTERR ; Yes, so that's an error

	cmp	ds:[esi].LO,'*' ; Izit omitted?
	je	short CMD_INSERT_XIDT ; Jump if so

	call	PARSE_ADDR	; Parse DS:ESI for address
	jc	near ptr CMD_INSERT_ERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)
	test	cx,@ADDR_SEP	; Separator specified?
	jz	near ptr CMD_INSERT_SYNTERR ; Not this time

	add	eax,edx 	; Add to get linear address
	mov	INSERT_EPM.VCPEPM_IDTP,eax ; Save for later use

	or	INSERT_FLAG,@INS_IDTP ; Mark as IDT present

	jmp	short CMD_INSERT_IDTCOM ; Join common code


CMD_INSERT_XIDT:
	inc	esi		; Skip over it
CMD_INSERT_IDTCOM:

; Parse the (optional) CR3

	call	IZITEOL 	; Izit end-of-the-line?
	je	short CMD_INSERT_CR3COM ; Jump if so

	cmp	ds:[esi].LO,'*' ; Izit omitted?
	je	short CMD_INSERT_XCR3 ; Jump if so

	call	PARSE_EXPR	; Parse command line for an expression
	jc	near ptr CMD_INSERT_SYNTERR ; Jump if error

	and	eax,@PTE_FRM	; Isolate the 4KB frame
	mov	INSERT_EPM.VCPEPM_CR3,eax ; Save for later use

	or	INSERT_FLAG,@INS_CR3P ; Mark as CR3 present

	jmp	short CMD_INSERT_CR3COM ; Join common code


CMD_INSERT_XCR3:
	inc	esi		; Skip over it
CMD_INSERT_CR3COM:

; Parse the (required) LA

	call	IZITEOL 	; Izit end-of-the-line?
	je	short CMD_INSERT_LaCOM ; Jump if so

	cmp	ds:[esi].LO,'*' ; Izit omitted?
	je	short CMD_INSERT_XLa ; Jump if so

	call	PARSE_EXPR	; Parse command line for an expression
	jc	near ptr CMD_INSERT_SYNTERR ; Jump if error

	and	eax,mask $LA_DIR ; Isolate the 4MB frame
	mov	INSERT_LaPDE,eax ; Save for later use

	or	INSERT_FLAG,@INS_LaP ; Mark as La present

	jmp	short CMD_INSERT_LaCOM ; Join common code


CMD_INSERT_XLa:
	inc	esi		; Skip over it
CMD_INSERT_LaCOM:

; Parse (optional) TR

	mov	edx,INSERT_EPM.VCPEPM_GDTP ; Get ptr to GDTR
	movzx	edx,AGROUP:[edx].DTR_LIM ; Get GDT limit

	call	IZITEOL 	; Izit end-of-the-line?
	je	short CMD_INSERT_TRCOM ; Jump if so

	cmp	ds:[esi].LO,'*' ; Izit omitted?
	je	short CMD_INSERT_XTR ; Jump if so

	call	PARSE_EXPR	; Parse command line for an expression
	jc	near ptr CMD_INSERT_SYNTERR ; Jump if error

	cmp	eax,edx 	; Izit too large?
	ja	near ptr CMD_INSERT_SYNTERR ; Jump if so

	and	eax,not (mask $PL) ; Clear PL bits
	mov	INSERT_TR,eax	; Save for later use

	or	INSERT_FLAG,@INS_TRP ; Mark as TR present

	jmp	short CMD_INSERT_TRCOM ; Join common code


CMD_INSERT_XTR:
	inc	esi		; Skip over it
CMD_INSERT_TRCOM:

; Parse (optional) LDTR

	call	IZITEOL 	; Izit end-of-the-line?
	je	short CMD_INSERT_LDTRCOM ; Jump if so

	cmp	ds:[esi].LO,'*' ; Izit omitted?
	je	short CMD_INSERT_XLDTR ; Jump if so

	call	PARSE_EXPR	; Parse command line for an expression
	jc	near ptr CMD_INSERT_SYNTERR ; Jump if error

	cmp	eax,edx 	; Izit too large?
	ja	near ptr CMD_INSERT_SYNTERR ; Jump if so

	mov	INSERT_LDTR,eax ; Save for later use

	or	INSERT_FLAG,@INS_LDTRP ; Mark as LDTR present

	jmp	short CMD_INSERT_LDTRCOM ; Join common code


CMD_INSERT_XLDTR:
	inc	esi		; Skip over it
CMD_INSERT_LDTRCOM:

; Set new linear address

	test	INSERT_FLAG,@INS_LaP ; Izit present?
	jz	near ptr CMD_INSERT3 ; Jump if not

	mov	eax,INSERT_LaPDE ; Get new linear address of PDE (/4MB)
;;;;;;; and	eax,mask $LA_DIR ; Isolate the 4MB frame
	mov	ebx,SWATCODE	; Get current linear address
	and	ebx,not (mask $LA_DIR) ; Isolate the offset within 4MB frame
	or	eax,ebx 	; Preserve our offset

	xchg	eax,VCPICODE	; Save for later use
	sub	eax,VCPICODE	; Get difference
	neg	eax		; Negate to get difference of new-old
	add	eax,VCPIDATA	; Plus old data address
	mov	VCPIDATA,eax	; Save for later use

; Put the current PTEs into the new CR3 via INSERT PDIRs

	mov	ecx,VCPICODE	; Get old linear address
	add	ecx,VCPICODE_LIM ; Plus its length
	add	ecx,(1 shl $LA_DIR)-1 ; Round up to 4MB boundary
	and	ecx,not ((1 shl $LA_DIR)-1) ; ...

	sub	ecx,INSERT_LaPDE ; Less starting PDE address
	shr	ecx,$LA_DIR-0	; Convert from bytes to 4MB

; Copy the PTEs to the local pages

	mov	edx,SWATCODE	; Get linear address of start of SWAT
	and	edx,mask $LA_DIR ; Round down to 4MB boundary
	mov	edi,PINSERT	; DGROUP:EDI ==> destin

	push	ecx		; Save for a moment

; If paging is off, there are no PTEs to copy, so we manufacturer them
; as our physical address

	mov	eax,cr0 	; Get register with Paging bit

	test	eax,mask $PG	; Izit enabled?
	jnz	short CMD_INSERT2 ; Jump if so

	mov	eax,edx 	; Get physical address of first PTE
	or	eax,@PTE_URP	; Mark as User/Read-write/Present
CMD_INSERT1A:
	push	ecx		; Save for a moment
	mov	ecx,1024	; Get # PTEs in a page
@@:
	stos	DGROUP:[edi].EDD ; Save in local pages

	add	eax,CON4KB	; Skip to next 4KB page

	loop	@B		; Jump if more PTEs

	pop	ecx		; Restore

	loop	CMD_INSERT1A	; Jump if more PDEs

	jmp	short CMD_INSERT2A ; Join common code


CMD_INSERT2:
	PUSHD	0		; Make room for original PTE
	PUSHD	1		; # PTEs to follow
	PUSHD	0		; Make room for original PDE
	push	edx		; Pass the linear address
	mov	eax,cr3 	; Copy our CR3
	push	eax		; Pass the CR3 to use
	call	LIN2PPTE	; Return with AGROUP:EAX ==> corresponding PTE

	mov	esi,eax 	; AGROUP:ESI ==> source
	push	ecx		; Save for a moment
	mov	ecx,1024	; Get # PTEs in a page
    rep movs	DGROUP:[edi].EDD,AGROUP:[esi].EDD ; Copy to local pages
	pop	ecx		; Restore

	call	LIN2PPTEZ	; Cleanup after LIN2PPTE
	add	esp,1*4 	; Pop the PTE

	add	edx,4*1024*1024 ; Skip to next 4MB block

	loop	CMD_INSERT2	; Jump if more PDEs
CMD_INSERT2A:
	pop	ecx		; Restore

	push	es		; Save for a moment

	mov	es,COMMON.FILE_4GB ; Get AGROUP data selector
	assume	es:AGROUP	; Tell the assembler about it

; Store the PDEs to the incoming CR3

	PUSHD	0		; Make room for original PTE
	PUSHD	1		; # PTEs to follow
	PUSHD	0		; Make room for original PDE
	push	INSERT_LaPDE	; Pass the linear address
	push	INSERT_EPM.VCPEPM_CR3 ; Pass the CR3 to use
	call	LIN2PPDIR	; Return with AGROUP:EAX ==> corresponding PDIR

	mov	edi,eax 	; AGROUP:EDI ==> destin
	mov	eax,PaINSERT	; Get phys addr of 1st INSERT page (/4MB)

; Mark as AV0/Supervisor/Read-write/Present

	or	eax,(mask $PTE_AV0) or (mask $PTE_RW) or (mask $PTE_P) ; Mark it
@@:
	stos	AGROUP:[edi].EDD ; Save in new CR3
	add	eax,4*1024	; Skip to next INSERT page

	loop	@B		; Jump if more PTEs

	call	LIN2PPTEZ	; Cleanup after LIN2PPDIR
	add	esp,1*4 	; Pop the PTE

	pop	es		; Restore
	assume	es:DGROUP	; Tell the assembler about it
CMD_INSERT3:

; Point ESI to INSERT_EPM as if it were a VCPI EPM structure

	lea	esi,INSERT_EPM	; Get offset in DGROUP
	add	esi,SWATDATA	; Plus linear address of DGROUP

; Capture the caller's CR3 and insert into our LCLTSSxx structures

	test	INSERT_FLAG,@INS_CR3P ; Izit present?
	jz	short @F	; Jump if not

	mov	eax,INSERT_EPM.VCPEPM_CR3 ; Get caller's CR3

	cmp	eax,-1		; Izit unspecified?
	je	short @F	; Jump if so

	call	SET_TSSCR3	; Set new CR3 in the local TSSs to EAX
@@:
	test	INSERT_FLAG,@INS_GDTP ; Izit present?
	jz	near ptr CMD_INSERT4 ; Jump if not

	test	INSERT_FLAG,@INS_IDTP ; Izit present?
	jz	near ptr CMD_INSERT4 ; Jump if not

	or	VCP_FLAG,@VCP_PMG ; Mark as installing PMG entries

	call	FIND_OLDVCP_GDT ; Find the next free entry in OLDVCP_GDT
				; Return index in EDX
	mov	eax,INS_SEL	; Get INSERT selector
	mov	CODESEL[edx*(type CODESEL)],ax ; Save for later use

	mov	edi,INSERT_EPM.VCPEPM_GDTP ; AGROUP:EDI ==> GDTR
	mov	edi,AGROUP:[edi].DTR_BASE ; Get GDT base
	add	edi,eax 	; Plus our initial selector
	call	INST_PMG	; Install our selectors into the GDT
				; AGROUP:EDI ==> GDT

	mov	edi,INSERT_EPM.VCPEPM_IDTP ; AGROUP:EDI ==> IDTR
	mov	edi,AGROUP:[edi].DTR_BASE ; Get IDT base

; AGROUP:EBX ==> caller's IDT entry for this interrupt
; DS:ESI ==>	LCLPMGxx ...
; eAX	==>	code selector

	lea	esi,LCLPMG01	; DS:ESI ==> INT 01h struc
	lea	ebx,[edi+01h * (type IDT_STR)] ; DS:EBX ==> IDT entry for INT 01h
	mov	LCLPMG01_FVEC.FSEL,ax ; Save as code selector

	PUSHD	1		; Pass do/don't install flag (0 = don't)
	call	SETTSS		; Setup the TSS

; AGROUP:EBX ==> caller's IDT entry for this interrupt
; DS:ESI ==>	LCLPMGxx ...
; eAX	==>	code selector

	lea	esi,LCLPMG03	; DS:ESI ==> INT 03h struc
	lea	ebx,[edi+03h * (type IDT_STR)] ; DS:EBX ==> IDT entry for INT 03h
	mov	LCLPMG03_FVEC.FSEL,ax ; Save as code selector

	PUSHD	1		; Pass do/don't install flag (0 = don't)
	call	SETTSS		; Setup the TSS

; AGROUP:EBX ==> caller's IDT entry for this interrupt
; DS:ESI ==>	LCLPMGxx ...
; eAX	==>	code selector

	lea	esi,LCLPMG0D	; DS:ESI ==> INT 0Dh struc
	lea	ebx,[edi+0Dh * (type IDT_STR)] ; DS:EBX ==> IDT entry for INT 0Dh
	mov	LCLPMG0D_FVEC.FSEL,ax ; Save as code selector

	PUSHD	0		; Pass do/don't install flag (0 = don't)
	call	SETTSS		; Setup the TSS

; AGROUP:EBX ==> caller's IDT entry for this interrupt
; DS:ESI ==>	LCLPMGxx ...
; eAX	==>	code selector

	lea	esi,LCLPMG0E	; DS:ESI ==> INT 0Eh struc
	lea	ebx,[edi+0Eh * (type IDT_STR)] ; DS:EBX ==> IDT entry for INT 0Eh
	mov	LCLPMG0E_FVEC.FSEL,ax ; Save as code selector

	PUSHD	0		; Pass do/don't install flag (0 = don't)
	call	SETTSS		; Setup the TSS

;;;;;;; push	VMSINT_PTR	; Save old ptr
;;;;;;; mov	VMSINT_PTR,offset DGROUP:INSINT_TAB ; Use INSERT interrupt table
;;;;;;; call	TRAP_EPM	; Insinuate ourselves into the new GDT/IDT
;;;;;;; pop	VMSINT_PTR	; Restore
;;;;;;; jc	near ptr CMD_INSERT_OVFERR ; Jump if not enough GDT entries
CMD_INSERT4:

;;; ; Insert a special INT 03h interrupt gate handler to set the TR
;;;
;;;	    test    INSERT_FLAG,@INS_IDTP ; Izit present?
;;;	    jz	    short CMD_INSERT_XINT03 ; Jump if not
;;;
;;;	    mov     ebx,INSERT_EPM.VCPEPM_IDTP ; AGROUP:EBX ==> IDTR
;;;
;;; ; Translate the IDT base address to the corresponding linear address
;;; ; according to the caller's CR3
;;;
;;;	    push    AGROUP:[ebx].DTR_BASE ; AGROUP:EBX ==> IDT
;;;	    push    INSERT_EPM.VCPEPM_CR3 ; Pass caller's CR3 for L2P
;;;	    call    LIN2LIN	    ; Return with EAX = corresponding linear addr
;;;
;;;	    mov     esi,eax	    ; AGROUP:ESI ==> caller's IDT
;;;
;;; ; AGROUP:ESI ==> caller's IDT
;;;
;;;	    mov     eax,INDVCP_GDT  ; Get current index
;;;	    mov     ax,CODESEL[eax*(type CODESEL)] ; Get the code selector
;;;	    xchg    ax,AGROUP:[esi+03h*(type IDT_STR)].IDT_SELECT ; Swap 'em
;;;	    mov     OLDGATE03_FVEC.FSEL,ax ; Save to restore later
;;;
;;;	    lea     eax,LCL_GATE03  ; Get INT 03h offset in CODESEL
;;;	    rol     eax,16	    ; Swap high- and low-order words
;;;	    xchg    ax,AGROUP:[esi+03h*(type IDT_STR)].IDT_OFFHI ; Get old offset
;;;	    rol     eax,16	    ; Shift to high-order
;;;	    xchg    ax,AGROUP:[esi+03h*(type IDT_STR)].IDT_OFFLO ; Get old offset
;;;	    mov     OLDGATE03_FVEC.FOFF,eax ; Save to restore later
;;;
;;;	    mov     al,CPL0_INTR3 or CPL3 ; Get our access rights byte
;;;	    xchg    al,AGROUP:[esi+03h*(type IDT_STR)].IDT_ACCESS ; Swap 'em
;;;	    mov     OLDGATE03_ARB,al ; Save to restore later
;;; CMD_INSERT_XINT03:

; Setup the pseudo-TR TSS










; Mark as in INSERT mode

	movzx	eax,RGRSEG2	; Get low DOS memory segment
	shl	eax,4-0 	; Convert from paras to bytes

	assume	gs:RGROUP	; Tell a white lie
	or	TRP_FLAG[eax],@TRP_INS ; Mark as in INSERT mode
	assume	gs:AGROUP	; Retract nose

	clc			; Indicate success

	jmp	short CMD_INSERT_EXIT ; Join common exit code

CMD_INSERT_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	jmp	short CMD_INSERT_ERRCOM ; Join common error message code

CMD_INSERT_OVFERR:
	mov	MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

;;;;;;; jmp	short CMD_INSERT_ERRCOM ; Join common error message code

CMD_INSERT_ERRCOM:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

;;;;;;; jmp	short CMD_INSERT_ERR ; Join common error exit code

CMD_INSERT_ERR:
	stc			; Mark as in error
CMD_INSERT_EXIT:
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_INSERT endp 		; End CMD_INSERT procedure
;;;	    FPPROC  LCL_GATE03 -- Local INT 03h Handler
;;;	    assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Local INT 03h handler
;;;
;;; |
;;;
;;; GATE03_STR struc
;;;
;;;	    dd	    ?		    ; Caller's EBP
;;; GATE03_IDTR df  ?		    ; IDTR
;;; GATE03_EIP dd   ?		    ; Caller's EIP
;;; GATE03_CSF dw   ?,? 	    ; ...      CS w/filler
;;; GATE03_EFL dd   ?		    ; ...      EFL
;;;
;;; GATE03_STR ends
;;;
;;;	    sub     esp,size DTR_STR ; Make room on stack
;;;	    push    ebp 	    ; Prepare to address the stack
;;;	    mov     ebp,esp	    ; Hello, Mr. Stack
;;;
;;; ; If the B-bit is clear in the stack selector, we need to zero
;;; ; the high-order word in EBP in order to properly address the stack
;;;
;;;	    REGSAVE <eax,ebx,ds,es> ; Save for a moment
;;;
;;;	    call    MASK_STKREGS    ; Mask off the high-order word of stack
;;;				    ; registers if 16-bit stack
;;;	    SETDATA es		    ; Set data selector into DS
;;;	    assume  es:DGROUP	    ; Tell the assembler about it
;;;
;;;	    mov     ds,INSERT_SEL4GB ; Get AGROUP data selector
;;;	    assume  ds:AGROUP	    ; Tell the assembler about it
;;;
;;; ; Put the new TR into effect
;;; ; unless there's a valid already busy TSS
;;;
;;;	    xor     ebx,ebx	    ; Zero to use as dword
;;;	    str     bx		    ; Get the current TR
;;;
;;;	    call    SEL2GDT	    ; Convert selector in EBX to GDT address in EBX
;;;	    jc	    short LCL_GATE03_INV ; Jump if it's invalid
;;;
;;;	    mov     al,AGROUP:[ebx].DESC_ACCESS ; Get the A/R byte
;;;
;;;	    test    al,mask $DT_DC  ; Izit code/data?
;;;	    jnz     short LCL_GATE03_INV ; Jump if so (not TSS)
;;;
;;;	    and     al,not (mask $DT_DPL) ; Clear DPL bits
;;;
;;;	    cmp     al,CPL0_BUSY3   ; Izit a busy 386 TSS?
;;;	    je	    short @F	    ; Jump if so
;;; LCL_GATE03_INV:
;;;	    mov     eax,INDVCP_GDT  ; Get current index
;;;	    mov     ax,CODESEL[eax*(type CODESEL)] ; Get the code selector
;;;	    add     ax,VCP_TR	    ; Skip to our TR selector
;;;	    ltr     ax		    ; Put it into effect
;;; @@:
;;;
;;; ; Put the previous INT 03h handler into effect
;;;
;;;	    SIDTD   [ebp].GATE03_IDTR ; Save IDTR on stack
;;;	    mov     ebx,[ebp].GATE03_IDTR.DTR_BASE ; AGROUP:EBX ==> IDT
;;;
;;;	    mov     eax,OLDGATE03_FVEC.FOFF ; Get previous offset
;;;	    mov     AGROUP:[ebx+03h*(type IDT_STR)].IDT_OFFLO,ax ; Restore
;;;	    shr     eax,16	    ; Shift down the high-order word
;;;	    mov     AGROUP:[ebx+03h*(type IDT_STR)].IDT_OFFHI,ax ; Restore
;;;
;;;	    mov     ax,OLDGATE03_FVEC.FSEL ; Get previous selector
;;;	    mov     AGROUP:[ebx+03h*(type IDT_STR)].IDT_SELECT,ax ; Restore
;;;
;;;	    mov     al,OLDGATE03_ARB ; Get previous A/R byte
;;;	    mov     AGROUP:[ebx+03h*(type IDT_STR)].IDT_ACCESS,al ; Restore
;;;
;;;	    REGREST <es,ds,ebx,eax> ; Restore
;;;	    assume  ds:nothing,es:nothing ; Tell the assembler about it
;;;
;;;	    dec     [ebp].GATE03_EIP ; Back off to the INT 03h
;;;
;;;	    pop     ebp 	    ; Restore
;;;	    add     esp,size DTR_STR ; Strip from the stack
;;;
;;;	    iretd		    ; Re-execute the INT 03h
;;;
;;;	    assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; LCL_GATE03 endp		    ; End LCL_GATE03 procedure
;;;	    NPPROC  LDTR_INSERT -- Insert LDTR Into TSS
;;;	    assume  ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Insert LDTR into TSS as appropriate
;;;
;;; |
;;;
;;;	    REGSAVE <eax,ebx,edx>   ; Save registers
;;;
;;; ; Determine if we should save the LDTR into the TSS
;;;
;;;	    test    INSERT_FLAG,@INS_TRP ; Izit present?
;;;	    jz	    short LDTR_INSERT_EXIT ; Jump if not
;;;
;;;	    sub     esp,size DTR_STR ; Make room for GDTR
;;;	    SGDTD   [esp].EDF	    ; Save address of current GDT
;;;	    mov     ebx,[esp].DTR_BASE ; AGROUP:EBX ==> GDT
;;;	    add     esp,size DTR_STR ; Strip
;;;
;;; ; Ensure that the LDTR is setup in the GDT
;;;
;;;	    mov     edx,INSERT_LDTR ; Get LDTR
;;;
;;;	    cmp     AGROUP:[ebx+edx].DESC_ACCESS,CPL0_LDT ; Izit an LDT?
;;;	    jne     short LDTR_INSERT_EXIT ; Jump if not
;;;
;;; ; Ensure that the LDTR base is non-zero
;;;
;;;	    mov     eax,AGROUP:[ebx+edx].DESC_BASE01.EDD ; Get bytes 0-2
;;;	    rol     eax,8	    ; Rotate out high-order byte
;;;	    mov     al,AGROUP:[ebx+edx].DESC_BASE3 ; Get byte 3
;;;	    ror     eax,8	    ; Rotate back
;;;
;;;	    and     eax,eax	    ; Izit valid?
;;;	    jz	    short LDTR_INSERT_EXIT ; Jump if not
;;;
;;; ; Ensure that the TR is setup in the GDT
;;;
;;;	    mov     edx,INSERT_TR   ; Get TR
;;;	    mov     al,AGROUP:[ebx+edx].DESC_ACCESS ; Get the A/R byte
;;;	    and     al,not (mask $DS_BUSY) ; Clear the busy bit
;;;
;;;	    cmp     al,CPL0_IDLE3   ; Izit a 386 TSS?
;;;	    jne     short LDTR_INSERT_EXIT ; Jump if not
;;;
;;; ; Save LDTR in TSS
;;;
;;;	    mov     eax,AGROUP:[ebx+edx].DESC_BASE01.EDD ; Get bytes 0-2
;;;	    rol     eax,8	    ; Rotate out high-order byte
;;;	    mov     al,AGROUP:[ebx+edx].DESC_BASE3 ; Get byte 3
;;;	    ror     eax,8	    ; Rotate back
;;;
;;;	    mov     edx,INSERT_LDTR ; Get LDTR
;;;	    mov     AGROUP:[eax].TSS_LDT,dx ; Save for later use
;;;
;;;	    and     INSERT_FLAG,not @INS_TRP ; Mark as not present
;;; LDTR_INSERT_EXIT:
;;;	    REGREST <edx,ebx,eax>   ; Restore
;;;
;;;	    ret 		    ; Return to caller
;;;
;;;	    assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; LDTR_INSERT endp		    ; End LDTR_INSERT procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_INS module
