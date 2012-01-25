;' $Header:   P:/PVCS/386SWAT/SWAT_SCR.ASV   1.21   20 Aug 1998 23:05:58   BOB  $
	title	SWAT_SCR -- 386SWAT Screen Display Functions
	page	58,122
	name	SWAT_SCR

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-2001 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include 8259.INC
	include BITFLAGS.INC
	include ALLMEM.INC
	include MAXDEV.INC
	include ASCII.INC
	include CPUFLAGS.INC
	include CPUFET.INC

	include SWAT_AGR.INC
	include SWAT_COM.INC
	include SWAT_DRV.INC
	include SWAT_LBR.INC
	include SWAT_SEG.INC
.list

RCODE	segment use16 para public 'rcode' ; Start RCODE segment
	assume	ds:RGROUP

	extrn	TRP_FLAG:dword

RCODE	ends			; End RCODE segment


DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	public	@SWAT_SCR_DATA16
@SWAT_SCR_DATA16 label byte	; Mark module start in .MAP file

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC4_FLAG:dword
	include SWAT_LC4.INC

	extrn	VIDBASE_FVEC:fword

	extrn	DEFATTR:byte
	extrn	DEFBATTR:byte
	extrn	STKATTR:byte
	extrn	BARATTR:byte
	extrn	ERRATTR:byte
	extrn	REGATTR:byte

	extrn	CPUFAM:byte

	extrn	ARET_CNT:word

	extrn	PCUR_VM_HANDLE:fword

	extrn	RGRSEG2:word

	public	MSG_FLAG
;		   1 0
MSG_FLAG dd	'AO  '          ; Bit 18
MSG_FLVM dd	'VM  '          ; Bit 17
	dd	'RF  '          ; Bit 16
	dd	'NT  '          ; Bit 14
	dd	'OVNV'          ; Bit 11
	dd	'DNUP'          ; Bit 10
	dd	'EIDI'          ; Bit  9
	dd	'NGPL'          ; Bit  7
	dd	'ZRNZ'          ; Bit  6
	dd	'ACNA'          ; Bit  4
	dd	'PEPO'          ; Bit  2
	dd	'CYNC'          ; Bit  0
NFLAGS	equ	($-MSG_FLAG)/(type MSG_FLAG) ; # flags to display

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	@SWAT_SCR_DATA
@SWAT_SCR_DATA label byte	; Mark module start in .MAP file

	extrn	SCROFF:dword
	extrn	MODOFF:dword
	extrn	CON4KB:dword
	extrn	CON4MB:dword
	extrn	ERRMSG:byte
	extrn	HEXTABLE:byte

	extrn	TSSINT_FLAG:dword

	extrn	TOGINT_TAB:tbyte
	extrn	TOGINT_CNT:abs
	extrn	TSS_CNT:dword

	extrn	CURCR4:dword
	extrn	CPUFET_FLAG:dword

	public	PTE_SEQ,PDE_SEQ
PTE_SEQ dd	?		; PTE in sequence
PDE_SEQ dd	?		; PDE ...

	public	OLDEAX,OLDEBX,OLDECX,OLDEDX,OLDESI,OLDEDI,OLDEBP,OLDESP
	public	OLDEIP,OLDEFL,OLDCR0,OLDCR2
OLDEAX	dd	0			; Previous screen's EAX
OLDEBX	dd	0			; ...		    EBX
OLDECX	dd	0			; ...		    ECX
OLDEDX	dd	0			; ...		    EDX
OLDESI	dd	0			; ...		    ESI
OLDEDI	dd	0			; ...		    EDI
OLDEBP	dd	0			; ...		    EBP
OLDESP	dd	0			; ...		    ESP
OLDEIP	dd	0			; ...		    EIP
OLDEFL	dd	0			; ...		    EFL
OLDCR0	dd	0			; ...		    CR0
OLDCR2	dd	0			; ...		    CR2

	public	OLDCS,OLDDS,OLDES,OLDFS,OLDGS,OLDSS
OLDCS	dw	0			; Previous screen's CS
OLDDS	dw	0			; ...		    DS
OLDES	dw	0			; ...		    ES
OLDFS	dw	0			; ...		    FS
OLDGS	dw	0			; ...		    GS
OLDSS	dw	0			; ...		    SS

	public	MSG_SSON,MSG_SSOFF
MSG_SSON db	'SS=ON  ',0
MSG_SSOFF db	'SS=OFF ',0

	public	MSG_ARET
MSG_ARET db	'LVL=',0

	public	MSG_BTFON,MSG_BTFOFF
MSG_BTFON db	' BTF=ON ',0
MSG_BTFOFF db	' BTF=OFF',0

	public	MSG_OFF
MSG_OFF db	'ÄÄÄ',0

MSG_MAC macro	NN,SEP

	public	MSG_&NN&ON
MSG_&NN&ON db	'&NN&'
ifnb <SEP>
	db	SEP
endif
	db	0
TAIL&NN&_LEN equ $-MSG_&NN&ON-1 ; Length of message

	endm			; MSG_MAC

	MSG_MAC 00,'Á'
	MSG_MAC 01,'Ä'
	MSG_MAC 02,'Ä'
	MSG_MAC 03,'Ä'
	MSG_MAC 05,'Ä'
	MSG_MAC 06,'Ä'
	MSG_MAC 0A,'Ä'
	MSG_MAC 0B,'Ä'
	MSG_MAC 0C,'Ä'
	MSG_MAC 0D,'Ä'
	MSG_MAC 0E

TAIL_LEN equ	TAIL00_LEN+TAIL01_LEN+TAIL02_LEN+TAIL03_LEN+TAIL05_LEN+\
		TAIL06_LEN+TAIL0A_LEN+TAIL0B_LEN+TAIL0C_LEN+TAIL0D_LEN+\
		TAIL0E_LEN

	public	CUR_VM_HANDLE, OLD_CUR_VM_HANDLE, MSG_VM_HANDLE
CUR_VM_HANDLE	dd	0
OLD_CUR_VM_HANDLE dd	0		; Previous screen's VM_Handle
MSG_VM_HANDLE	db	'VM=', 0

	public	MSG_EGP1
MSG_EGP1 db	'EAX      EBX      ECX      EDX      ESI      EDI      EBP      ESP      EIP     ',0

	public	MASK_FLAG
;			     111 1  11
;			     876 4  109 76 4 2 0
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;			     AVR N  ODI SZ A P C
;			     CMF T  FFF FF F F F
MASK_FLAG dd	00000000000001110100111011010101b

	public	MSG_SEGSP,MSG_SEGINV
MSG_SEGSP db	19 dup (' '),0  ; SREG skip
MSG_SEGINV db	'|*Selector Invalid*',0 ; SREG invalid

	public	AZS_SREGTOP,AZS_SREGBOT
AZS_SREGTOP db	26 dup ('Ä'),'Â',26 dup ('Ä'),'Â',26 dup ('Ä'),0
AZS_SREGBOT db	26 dup ('Ä'),'Á',26 dup ('Ä'),'Á',26 dup ('Ä'),0

	public	AZS_DECFMT
	db	13 dup (' ')    ; Space for left-justified 32-bit decimal value
AZS_DECFMT db	' ',0           ; Units digit and trailing NULL

	public	AZS_PNP
AZS_PNP db	'????????',0    ; Display entry for Page Not Present

	public	PxE_FLAG
PxE_FLAG db	?		; DISPROWPTE/DISPROWPDE flag
@DISP_PTE equ	0		; Displaying PTEs
@DISP_PDE equ	1		; ...	     PDEs

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP,ds:PGROUP

	public	@SWAT_SCR_PROG
@SWAT_SCR_PROG: 		; Mark module start in .MAP file

	extrn	SWATINI:tbyte
;;;;;;; extrn	DEVLOAD:byte

	extrn	DISPTXT:near
	extrn	REMCOL:near

	extrn	INST_OPR0E:near
	extrn	REST_OPR0E:near

	extrn	DWGET:near
	extrn	DDGET:near
	extrn	DISP_LBRWIN:near
	extrn	CLEAR_EOL:near

	NPPROC	DISPHEX0 -- Display a Nibble in Hex on the Screen
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert the nibble in low-order of AL to ASCII hex and display on the screen
at DTE_VID:SCROFF and following skipping over the attribute bytes.

|

	REGSAVE <eax,ebx,edi,ds,es> ; Save registers

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	les	edi,VIDBASE_FVEC ; ES:EDI ==> video base
	assume	es:nothing	; Tell the assembler about it

	add	edi,SCROFF	; Plus current offset

	and	al,@NIB0	; Isolate the low-order nibble
	lea	ebx,HEXTABLE	; Translate table
	xlat	HEXTABLE[ebx]	; Translate
	mov	ah,DEFATTR	; Get default attribute
S32	stos	es:[edi].ELO	; Save char/attr on screen

	sub	edi,VIDBASE_FVEC.FOFF ; Less video base offset
	mov	SCROFF,edi	; Save for next time

	REGREST <es,ds,edi,ebx,eax> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPHEX0 endp			; End DISPHEX0 procedure
	NPPROC	DISPHEX1 -- Display a Byte in Hex on the Screen
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert the byte in AL to ASCII hex and display on the screen
at DTE_VID:SCROFF and following skipping over the attribute bytes.

|

	REGSAVE <eax,ebx,edi,ds,es> ; Save registers

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	les	edi,VIDBASE_FVEC ; ES:EDI ==> video base
	assume	es:nothing	; Tell the assembler about it

	add	edi,SCROFF	; Plus current offset

	xor	ah,ah		; Zero to use as word
	mov	bl,16		; Base for conversion
	div	bl		; AH has remainder, AL quotient
	lea	ebx,HEXTABLE	; Translate table
	xlat	HEXTABLE[ebx]	; Translate

	push	eax		; Save for a moment
	mov	ah,DEFATTR	; Get default attribute
S32	stos	es:[edi].ELO	; Save char/attr on screen
	pop	eax		; Restore

	xchg	al,ah		; Get low-order byte
	xlat	HEXTABLE[ebx]	; Translate

	push	eax		; Save for a moment
	mov	ah,DEFATTR	; Get default attribute
S32	stos	es:[edi].ELO	; Save char/attr on screen
	pop	eax		; Restore

	sub	edi,VIDBASE_FVEC.FOFF ; Less video base offset
	mov	SCROFF,edi	; Save for next time

	REGREST <es,ds,edi,ebx,eax> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPHEX1 endp			; End DISPHEX1 procedure
	NPPROC	DISPHEX2 -- Display a Word in Hex on the Screen
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert the word in AX to ASCII hex and display on the screen
at DTE_VID:SCROFF and following skipping over the attribute bytes.

|

	xchg	al,ah		; Display high-order byte first
	call	DISPHEX1	; Display byte on screen in hex

	xchg	al,ah		; Display low-order byte next
	call	DISPHEX1	; Display byte on screen in hex

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPHEX2 endp			; End DISPHEX2 procedure
	NPPROC	DISPHEX4 -- Display a Dword in Hex on the Screen
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert the dword in EAX to ASCII hex and display on the screen
at DTE_VID:SCROFF and following skipping over the attribute bytes.

|

	rol	eax,16		; Shift high-order word to low-order
	call	DISPHEX2	; Display word on screen in hex

	rol	eax,16		; Shift back
	call	DISPHEX2	; Display word on screen in hex

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPHEX4 endp			; End DISPHEX4 procedure
	NPPROC	IZIT_PSE -- Are Page Size Extensions Supported And Active
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Are Page Size Extensions supported and active?

On exit:

CF	=	1 if so
	=	0 if not

|

	test	CPUFET_FLAG,@CPUFET_PSE ; Are 4MB pages supported?
	jz	short @F	; Jump if not (note CF=0)

	test	CURCR4,@PSE	; Are 4MB pages enabled?
	jz	short @F	; Jump if not (note CF=0)

	stc			; Mark as supported and active
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_PSE endp			; End IZIT_PSE procedure
	NPPROC	DISPROWPTE -- Display A Row of PTEs
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display a row of PTEs.

On entry:

GS:ESI	==>	starting address
EDX	=	maximum # to display
EDI	=	initial PTE
PTE_SEQ =	sequential PTE

On exit:

ESI	=	updated
EDI	=	updated
EDX	=	updated
PTE_SEQ =	updated

|

	push	ebp		; Save for a moment

	mov	ebp,PTE_SEQ	; Get sequential PTE
	mov	PxE_FLAG,@DISP_PTE ; Mark as displaying PTEs

	call	DISPROWPxE	; Call common code

	mov	PTE_SEQ,ebp	; Save for later use

	pop	ebp		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPROWPTE endp 		; End DISPROWPTE procedure
	NPPROC	DISPROWPDE -- Display A Row of PDEs
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display a row of PDEs.

On entry:

GS:ESI	==>	starting address
EDX	=	maximum # to display
EDI	=	initial PDE
PDE_SEQ =	sequential PDE

On exit:

ESI	=	updated
EDI	=	updated
EDX	=	updated
PDE_SEQ =	updated

|

	push	ebp		; Save for a moment

	mov	ebp,PDE_SEQ	; Get sequential PTE
	mov	PxE_FLAG,@DISP_PDE ; Mark as displaying PDEs

	call	DISPROWPxE	; Call common code

	mov	PDE_SEQ,ebp	; Save for later use

	pop	ebp		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPROWPDE endp 		; End DISPROWPDE procedure
	NPPROC	DISPROWPxE -- Display A Row of PTEs/PDEs
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display a row of PTEs/PDEs.

On entry:

GS:ESI	==>	starting address
EDX	=	maximum # to display
EDI	=	initial PTE/PDE
EBP	=	sequential PTE/PDE

On exit:

ESI	=	updated
EDI	=	updated
EDX	=	updated
EBP	=	updated

|

	REGSAVE <eax,ebx,ecx>	; Save for a moment

	PUSHD	8+1		; Pass the divisor as argument
	call	REMCOL		; Return with ECX = # entries remaining

	cmp	ecx,edx 	; Check against maximum
	jbe	short @F	; Jump if below maximum

	mov	ecx,edx 	; Use maximum
@@:
	sub	edx,ecx 	; Account for entries to be displayed

	and	ecx,ecx 	; Anything to display?
	jz	near ptr DISPROWPxE_EXIT ; Jump if not

	call	INST_OPR0E	; Install our local Page Fault handler
DISPROWPxE_NEXT:
	clc			; Mark as no error
	lods	AGROUP:[esi].EDD ; Get next dword
	jc	short DISPROWPxE_PF ; Jump if Page Fault

	push	eax		; Save for a moment

	mov	bl,DEFATTR	; Get default attribute

; Handle Page Size Extensions

	push	edi		; Save for a moment

	cmp	PxE_FLAG,@DISP_PDE ; Are we displaying PDEs?
	jne	short @F	; Jump if not

	call	IZIT_PSE	; Are Page Size Extensions supported and active?
	jnc	short @F	; Jump if not

	test	eax,mask $PTE_PS ; Is the PDE a 4MB page?
	jz	short @F	; Jump if not

	shl	edi,22-12	; Convert from 4KB to 4MB
@@:
	and	eax,@PTE_FRM	; Isolate the 4KB frame

	cmp	eax,edi 	; Izit one-to-one?
	pop	edi		; Restore
	je	short DISPROWPxE1 ; Jump if so

	mov	bl,BARATTR	; Get attribute if sequential

	cmp	eax,ebp 	; Izit sequential?
	je	short @F	; Jump if so

	mov	bl,REGATTR	; Get attribute if not sequential
@@:
	xchg	bl,DEFATTR	; Swap 'em
DISPROWPxE1:
	mov	ebp,eax 	; Save as next sequential PTE
	pop	eax		; Restore

	call	DISPHEX4	; Display the dword

	jmp	short DISPROWPxE2 ; Join common code

DISPROWPxE_PF:
	add	esi,4		; Skip to next PTE

	push	esi		; Save for a moment

	mov	bl,REGATTR	; Get attribute if not sequential
	xchg	bl,DEFATTR	; Swap 'em
	lea	esi,AZS_PNP	; ESI ==> Page Not Present line
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	pop	esi		; Restore
DISPROWPxE2:
	xchg	bl,DEFATTR	; Restore original attribute

	push	eax		; Save for a moment

	mov	al,' '
	call	DISPTXT 	; Display space on screen as text

	pop	eax		; Restore

	mov	ebx,CON4KB	; Assume it's a 4KB page

; Handle Page Size Extensions

	cmp	PxE_FLAG,@DISP_PDE ; Are we displaying PDEs?
	jne	short @F	; Jump if not

	call	IZIT_PSE	; Are Page Size Extensions supported and active?
	jnc	short @F	; Jump if not

	test	eax,mask $PTE_PS ; Is the PDE a 4MB page?
	jz	short @F	; Jump if not

	mov	ebx,CON4MB	; It's an 4MB page
@@:
	add	edi,CON4KB	; Skip to next PTE/PDE
	add	ebp,ebx 	; ...

;;;;;;; loop	DISPROWPxE_NEXT ; Jump if more PTEs to display
	dec	ecx		; Account for one less element
	jnz	DISPROWPxE_NEXT ; Jump if more PTEs to display
DISPROWPxE_EXIT:
	call	REST_OPR0E	; Restore previous Page Fault handler

	REGREST <ecx,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPROWPxE endp 		; End DISPROWPxE procedure
	NPPROC	DISPASCIIZ -- Display ASCIIZ String From ESI
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the ASCIIZ string from DS:ESI on the screen at DTE_VID:SCROFF.

|

	REGSAVE <eax,esi,edi,ds,es,gs> ; Save registers

	cld			; String ops forwardly

	SETDATA gs		; Set data selector into GS
	assume	gs:DGROUP	; Tell the assembler about it

	les	edi,VIDBASE_FVEC ; ES:EDI ==> video base
	assume	es:nothing	; Tell the assembler about it

	add	edi,SCROFF	; Plus current offset

	mov	ah,DEFATTR	; Get default attribute
DISPASCIIZ_NEXT:
	lods	ds:[esi].LO	; Get next character

	and	al,al		; End of the message?
	jz	short DISPASCIIZ_EXIT ; Yes

	call	DISP_SPEC	; Handle special characters
	jc	short DISPASCIIZ_NEXT ; Jump if it was handled, EDI updated

S32	stos	es:[edi].ELO	; Save char/attr on screen

	jmp	DISPASCIIZ_NEXT ; Go around again

DISPASCIIZ_EXIT:
	sub	edi,VIDBASE_FVEC.FOFF ; Less video base offset
	mov	SCROFF,edi	; Save for next time

	REGREST <gs,es,ds,edi,esi,eax> ; Restore
	assume	ds:nothing,es:nothing,gs:nothing ; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPASCIIZ endp 		; End DISPASCIIZ procedure
	NPPROC	DISP_SPEC -- Display Special Characters
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display special characters

On entry:

AL	=	character
ES:EDI	==>	video screen

On exit:

ED:EDI	==>	(updated)
CF	=	1 if we handled it here
	=	0 if not

|

	REGSAVE <eax,ecx,edx>	; Save registers

	cmp	al,CR		; Izit start of line?
	je	short DISP_SPEC_CR ; Jump if so

	cmp	al,LF		; Izit new line?
	je	short DISP_SPEC_LF ; Jump if so

	clc			; Indicate we didn't handle the char

	jmp	short DISP_SPEC_EXIT ; Join common exit code

DISP_SPEC_CR:
	sub	edi,VIDBASE_FVEC.FOFF ; Less video base offset
	mov	SCROFF,edi	; Update

	call	CLEAR_EOL	; Clear to the EOL

	mov	eax,edi 	; Next char/attr on screen
	xor	edx,edx 	; Zero to use as dword EDX:EAX
	mov	ecx,@NCOLS*2	; # chars per screen row
	div	ecx		; Return with EAX as screen row (origin-0)
				; EDX = screen col
	mul	ecx		; EAX = offset of start of row
	mov	edi,eax 	; Back off to start of line

	jmp	short DISP_SPEC_COM ; Join common code

DISP_SPEC_LF:
	sub	edi,VIDBASE_FVEC.FOFF ; Less video base offset
	add	edi,@NCOLS*2	; Skip to next line
;;;;;;;
;;;;;;; cmp	edi,(@NROWS-1)*@NCOLS*2 ; Still on the screen?
;;;;;;; jb	short @F	; Yes
;;;;;;;
;;;;;;; xor	edi,edi 	; Start again at the top
;;;@@:
DISP_SPEC_COM:
	mov	SCROFF,edi	; Update
	add	edi,VIDBASE_FVEC.FOFF ; Less video base offset

;;;;;;; jmp	short DISP_SPEC_DONE ; Join common exit code

DISP_SPEC_DONE:
	stc			; Mark as handled
DISP_SPEC_EXIT:
	REGREST <edx,ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_SPEC endp			; End DISP_SPEC procedure
	NPPROC	DISPASCLEN -- Display ASCIIZ String From ESI For ECX bytes
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the ASCIIZ string from DASCLEN_FVEC for DASCLEN_LEN bytes
on the screen at DTE_VID:SCROFF.

On entry:

SS:ESP	==>	DASCLEN_STR (before PUSH EBP)

|

DASCLEN_STR struc

	dd	?		; Caller's EIP
	dd	?		; ...	   EBP
DASCLEN_LEN dd	?		; String length in bytes
DASCLEN_FVEC df ?		; Ptr to string to display

DASCLEN_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ecx,esi,edi,ds,es,fs> ; Save registers

	mov	ecx,[ebp].DASCLEN_LEN ; Get the string length
	jecxz	DISPASCLEN_EXIT ; Jump if string is empty

	lfs	esi,[ebp].DASCLEN_FVEC ; FS:ESI ==> string to display
	assume	fs:nothing	; Tell the assembler about it

	cld			; String ops forwardly

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	les	edi,VIDBASE_FVEC ; ES:EDI ==> video base
	assume	es:nothing	; Tell the assembler about it

	add	edi,SCROFF	; Plus current offset

	mov	ah,DEFATTR	; Get default attribute
DISPASCLEN_NEXT:
	lods	fs:[esi].LO	; Get next character

	and	al,al		; End of the message?
	jz	short @F	; Yes

;;;;;;; call	DISP_SPEC	; Handle special characters
;;;;;;; jc	short DISPASCLEN_NEXT ; Jump if it was handled, EDI updated

S32	stos	es:[edi].ELO	; Save char/attr on screen

	loop	DISPASCLEN_NEXT ; Jump if more bytes to display
@@:
	sub	edi,VIDBASE_FVEC.FOFF ; Less video base offset
	mov	SCROFF,edi	; Save for next time
DISPASCLEN_EXIT:
	REGREST <fs,es,ds,edi,esi,ecx,eax> ; Restore
	assume	ds:nothing,es:nothing,fs:nothing ; Tell the assembler about it

	pop	ebp		; Restore

	ret	4+4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPASCLEN endp 		; End DISPASCLEN procedure
	NPPROC	DISPTRUNC -- Display ASCIIZ String From DS:ESI Truncated
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the ASCIIZ string from DS:ESI on the screen at DTE_VID:SCROFF
truncated at the end-of-the-line.

On exit:

CF	=	1 if truncated
	=	0 if not

|

	pushad			; Save all EGP registers
	REGSAVE <ds,es,gs>	; Save registers

	cld			; String ops forwardly

	SETDATA gs		; Set data selector into GS
	assume	gs:DGROUP	; Tell the assembler about it

	les	edi,VIDBASE_FVEC ; ES:EDI ==> video base
	assume	es:nothing	; Tell the assembler about it

	add	edi,SCROFF	; Plus current offset

	mov	ah,DEFATTR	; Get default attribute
DISPTRUNC_NEXT0:
	PUSHD	0+1		; Pass the divisor as argument
	call	REMCOL		; Return with ECX = # entries remaining
DISPTRUNC_NEXT:

; Ensure we don't overwrite the screen

	mov	ebx,edi 	; Copy current screen offset
	sub	ebx,VIDBASE_FVEC.FOFF ; Less video base offset

	cmp	ebx,(@NROWS - 1) * @NCOLS * 2 ; Izit on the last line?
	jae	short DISPTRUNC_EXIT ; Jump if too much

	lods	ds:[esi].LO	; Get next character

	and	al,al		; End of the message?
	jz	short DISPTRUNC_EXIT ; Yes

	call	DISP_SPEC	; Handle special characters
	jc	short DISPTRUNC_NEXT0 ; Jump if it was handled, EDI updated

S32	stos	es:[edi].ELO	; Save char/attr on screen

	loop	DISPTRUNC_NEXT	; Jump if more columns to display into
DISPTRUNC_EXIT:
	sub	edi,VIDBASE_FVEC.FOFF ; Less video base offset
	mov	SCROFF,edi	; Save for next time

	cmp	ecx,1		; Check sign of ECX

	REGREST <gs,es,ds>	; Restore
	assume	ds:nothing,es:nothing,gs:nothing ; Tell the assembler about it
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPTRUNC endp			; End DISPTRUNC procedure
	NPPROC	NEXTLINE -- Skip To Next Screen Row
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip to the next screen line in the first column
unless we're already in the first column.

|

	REGSAVE <eax,edx,edi,ds> ; Save registers

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	mov	eax,SCROFF	; Next char/attr on screen

	xor	edx,edx 	; Zero to use as dword EDX:EAX
	mov	edi,@NCOLS*2	; # chars per screen row
	div	edi		; Return with AX as screen row (origin-0)

	cmp	edx,1		; Check for in column zero
	cmc
	adc	eax,0		; Skip to the next line

	cmp	eax,@NROWS	; Still on the screen?
	jb	short NEXTLINE1 ; Yes

	xor	eax,eax 	; Start again at the top
NEXTLINE1:
	mul	edi		; Back again, ignoring remainder

	mov	SCROFF,eax	; Save for next time

	REGREST <ds,edi,edx,eax> ; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

NEXTLINE endp			; End NEXTLINE procedure
	NPPROC	DISPTXTATTR -- Display Word in AX As Text/Attribute
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the word in AX as text/attribute.

On entry:

AL	=	char to display
AH	=	attribute

|

	REGSAVE <edi,ds,es>	; Save registers

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	les	edi,VIDBASE_FVEC ; ES:EDI ==> video base
	assume	es:nothing	; Tell the assembler about it

	add	edi,SCROFF	; Plus current offset

S32	stos	es:[edi].ELO	; Save char/attr on screen

	sub	edi,VIDBASE_FVEC.FOFF ; Less video base offset
	mov	SCROFF,edi	; Save for next time

	REGREST <es,ds,edi>	; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPTXTATTR endp		; End DISPTXTATTR procedure
	NPPROC	DISP_STK -- Display the Stack
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the stack

|

DISP_STK_STR struc

DISP_STK_EBP dd ?		; Caller's EBP
	dd	?		; Caller's EIP
DISP_STK_BPLA dd ?		; Linear address of SS:eBP
DISP_STK_SPLA dd ?		; ...		    SS:eSP

DISP_STK_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ebx,esi,edi>	; Save registers

	mov	ebx,[ebp].DISP_STK_BPLA ; Get LA of SS:eBP
	mov	esi,[ebp].DISP_STK_SPLA ; Get LA of SS:eSP
	mov	ebp,[ebp].DISP_STK_EBP ; Restore EBP for access to FORW_STR

@STKROW equ	8		; Starting row
@STKCOLSIZ equ	5		; Column size

	call	INST_OPR0E	; Install our local Page Fault handler

	test	LCL_FLAG,@LCL_STKD ; Display in double words?
	jnz	short DISP_STK_DD ; Yes

	mov	edi,2*((@STKROW+1)*@NCOLS-2*@STKCOLSIZ) ; Column 1 screen offset
	push	offset cs:DISP_STKW ; Display values as words
	call	DISP_STK_COL	; Display one column's worth

	mov	edi,2*((@STKROW+1)*@NCOLS-1*@STKCOLSIZ) ; Column 2 screen offset
	push	offset cs:DISP_STKW ; Load values as words
	call	DISP_STK_COL	; Display one column's worth

	jmp	short DISP_STK_EXIT ; Join common exit code

DISP_STK_DD:
	mov	edi,2*((@STKROW+1)*@NCOLS-2*@STKCOLSIZ) ; Column 1 screen offset
	push	offset cs:DISP_STKD ; Display values as dwords
	call	DISP_STK_COL	; Display one column's worth
DISP_STK_EXIT:

; Display the LBR window if enabled

	test	LC4_FLAG,@LC4_LBRWIN ; Displaying LBR window?
	jz	short @F	; Jump if not

	call	DISP_LBRWIN	; Display it
@@:
	call	REST_OPR0E	; Restore previous Page Fault handler

	REGREST <edi,esi,ebx>	; Restore

	pop	ebp		; Restore

	ret	4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_STK endp			; End DISP_STK procedure
	NPPROC	DISP_STK_COL -- Display A Stack Column
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display one stack column.

On entry:

EDI	==>	starting screen location
GS:EBX	==>	linear address of SS:eBP
GS:ESI	==>	next stack location to display

On exit:

GS:ESI	==>	updated

|

DISP_STKC_STR struc

	dd	?		; Caller's EBP
	dd	?		; Caller's EIP
DISP_STKC_NXT dd ?		; Offset of next value function

DISP_STKC_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ecx,edx,edi> ; Save registers

	xor	dl,dl		; Initialize # rows displayed
	mov	ecx,@NROWS-1-@STKROW ; # rows to display

	test	LC4_FLAG,@LC4_LBRWIN ; Displaying LBR window?
	jz	short @F	; Jump if not

	sub	ecx,@LBR_NROW	; Less # rows in LBR window
@@:
	mov	ah,STKATTR	; Get stack attribute
	mov	dh,ah		; Copy
	xchg	dh,DEFATTR	; Swap with default attribute
DISP_STKC_NEXT:
	mov	SCROFF,edi	; Save for later use

	mov	al,'³'          ; Separator if ESP .ne. EBP and DX MOD 8 .ne. 0

	test	dl,8-1		; Display a tick mark?
	jnz	short @F	; Not this time

	mov	al,'Å'          ; Mark as tick mark
@@:
	cmp	esi,ebx 	; Same as EBP?
	jne	short @F	; Not this time

	mov	al,'¯'          ; Mark as same as EBP
@@:
	call	DISPTXTATTR	; Display AX on screen as text/attribute

	call	[ebp].DISP_STKC_NXT ; Get next value from the stack
				; and display it

	add	edi,@NCOLS*2	; Skip to next row

	loop	DISP_STKC_NEXT	; Jump if more rows to display

	xchg	dh,DEFATTR	; Restore default attribute

	REGREST <edi,edx,ecx,eax> ; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_STK_COL endp		; End DISP_STK_COL procedure
	NPPROC	DISP_STKW -- Load A Word From GS:ESI
	assume	ds:nothing,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Load a word from GS:ESI into AX, incrementing ESI.

On entry:

DL	=	# rows displayed so far
GS:ESI	==>	next stack location to display

On exit:

DL	=	updated
GS:ESI	==>	updated

|

	push	eax		; Save for a moment

;;;;;;; lods	AGROUP:[esi].ELO ; Get next word from the stack into AX
	xchg	ebx,esi 	; Swap for DWGET input
	PUSHD	0		; Pass offset as argument
	call	DWGET		; Get, format, and display a word
	xchg	ebx,esi 	; Restore
	add	esi,2		; Skip to next word

;;;;;;; call	DISPHEX2	; Display word on screen in hex

	pop	eax		; Restore

	inc	dl		; Mark as another row displayed

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_STKW endp			; End DISP_STKW procedure
	NPPROC	DISP_STKD -- Load A Dword From GS:ESI
	assume	ds:nothing,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Load a dword from GS:ESI into EAX, incrementing ESI.

On entry:

AX	=	tick mark/attribute
DL	=	# rows displayed so far
GS:ESI	==>	next stack location to display

On exit:

DL	=	updated
GS:ESI	==>	updated

|

	push	eax		; Save tick mark/attr

;;;;;;; lods	AGROUP:[esi].EDD ; Get next dword from the stack into AX
	xchg	ebx,esi 	; Swap for DDGET input
	PUSHD	0		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword
	xchg	ebx,esi 	; Restore
	add	esi,4		; Skip to next dword

;;;;;;; call	DISPHEX4	; Display the dword

	pop	eax		; Restore tick mark/attr

	call	DISPTXTATTR	; Display AX on screen as text/attribute

	inc	dl		; Mark as another row displayed
	inc	dl		; Actually, two rows

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_STKD endp			; End DISP_STKD procedure
	NPPROC	DISPBAR -- Display Bar Across the Screen
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display a bar line across the screen.

|

	REGSAVE <eax,ecx,edi,ds,es> ; Save registers

	cld			; String ops forwardly

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	les	edi,VIDBASE_FVEC ; ES:EDI ==> video base
	assume	es:nothing	; Tell the assembler about it

	add	edi,SCROFF	; Plus current offset

	mov	ah,BARATTR	; Get attribute to use
	mov	al,'Ä'          ; Smear this character
	mov	ecx,@NCOLS	; # characters per screen line
    rep stos	es:[edi].ELO	; Store on screen

	sub	edi,VIDBASE_FVEC.FOFF ; Less video base offset
	mov	SCROFF,edi	; Save for next time

	REGREST <es,ds,edi,ecx,eax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPBAR endp			; End DISPBAR procedure
	NPPROC	DISPBAR1 -- Display Bar Across the Screen
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display a bar line across the screen.

|

	REGSAVE <eax,esi>	; Save registers

	mov	al,BARATTR	; Get bar attribute
	xchg	al,DEFATTR	; Swap with default attribute
	lea	esi,AZS_SREGTOP ; ESI ==> segment register top line
	call	DISPASCIIZ	; Display ASCIIZ string from ESI
	xchg	al,DEFATTR	; Swap back

	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPBAR1 endp			; End DISPBAR1 procedure
	NPPROC	DISPBAR2 -- Display Bar Across the Screen
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display a bar line across the screen.

|

	REGSAVE <eax,esi>	; Save register

	mov	al,BARATTR	; Get bar attribute
	xchg	al,DEFATTR	; Swap with default attribute
	lea	esi,AZS_SREGBOT ; ESI ==> segment register bottom line
	call	DISPASCIIZ	; Display ASCIIZ string from ESI
	xchg	al,DEFATTR	; Swap back

	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPBAR2 endp			; End DISPBAR2 procedure
	NPPROC	DISPERRMSG -- Display Error Message
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display any error message on the preceding line.

|

	REGSAVE <eax,esi>	; Save registers

	test	LCL_FLAG,@LCL_MSG ; Did we receive one?
	jz	short DISPERRMSG_EXIT ; Not this time

	push	SCROFF		; Save current screen offset

	sub	SCROFF,2*@NCOLS-2 ; Back off one row less 2 columns

	mov	al,ERRATTR	; Get error message attribute
	xchg	al,DEFATTR	; Make that the default attribute

	lea	esi,ERRMSG	; Display error message
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	xchg	al,DEFATTR	; Restore default attribute

	pop	SCROFF		; Restore
DISPERRMSG_EXIT:
	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPERRMSG endp 		; End DISPERRMSG procedure
	NPPROC	DISPVMHANDLE -- Windows VM_Handle
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display Windows VM_Handle on the preceding line.

|

	REGSAVE <eax,esi>	; Save registers

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Are we running under Windows?
	jz	short DISPVMHANDLE_EXIT ; Not this time

	push	SCROFF		; Save current screen offset

	sub	SCROFF,2*@NCOLS-(2*(80-(3+8+1)))
				; Back off one row less space for text

	lea	esi,MSG_VM_HANDLE ; Display prefix text
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	mov	ax,PCUR_VM_HANDLE.FSEL ; DS:EAX ==> Cur_VM_Handle in WIN386
	or	ax,ax		; Is it still NULL?
	jz	short DISPVMHANDLE_XPTR ; Skip using a foul pointer

	mov	eax,PCUR_VM_HANDLE.FOFF ; Offset of Cur_VM_Handle in WIN386
	or	eax,eax 	; Is it still NULL?
	jz	short DISPVMHANDLE_XPTR ; Skip using a foul pointer

	push	ds		; Save

	mov	ds,PCUR_VM_HANDLE.FSEL ; DS:EAX ==> Cur_VM_Handle in WIN386
	assume	ds:nothing	; Tell the assembler about it

	mov	eax,ds:[eax]	; Pick up Cur_VM_Handle

	pop	ds		; Restore
	assume	ds:DGROUP	; Tell the assembler

	mov	CUR_VM_HANDLE,eax ; Save for next time
DISPVMHANDLE_XPTR:
	push	OLD_CUR_VM_HANDLE ; Pass former value
	push	CUR_VM_HANDLE	; Pass current value
	call	DISP_EREG	; Display it

	pop	SCROFF		; Restore
DISPVMHANDLE_EXIT:
	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPVMHANDLE endp		; End DISPVMHANDLE procedure
	NPPROC	DISPEGP -- Display All EGP Registers
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display all EGP registers.

On entry:

SS:EBP	==>	FORW_STR

|

	REGSAVE <eax,esi,ds>	; Save registers

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	lea	esi,MSG_EGP1
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	NEXTLINE	; Skip to a new line

	push	OLDEAX		; Pass former value
	push	[ebp].FORW_EAX	; Pass current value
	call	DISP_EREG	; Display it

	mov	al,' '
	call	DISPTXT 	; Display byte on screen as text

	push	OLDEBX		; Pass former value
	push	[ebp].FORW_EBX	; Pass current value
	call	DISP_EREG	; Display it

	mov	al,' '
	call	DISPTXT 	; Display byte on screen as text

	push	OLDECX		; Pass former value
	push	[ebp].FORW_ECX	; Pass current value
	call	DISP_EREG	; Display it

	mov	al,' '
	call	DISPTXT 	; Display byte on screen as text

	push	OLDEDX		; Pass former value
	push	[ebp].FORW_EDX	; Pass current value
	call	DISP_EREG	; Display it

	mov	al,' '
	call	DISPTXT 	; Display byte on screen as text

	push	OLDESI		; Pass former value
	push	[ebp].FORW_ESI	; Pass current value
	call	DISP_EREG	; Display it

	mov	al,' '
	call	DISPTXT 	; Display byte on screen as text

	push	OLDEDI		; Pass former value
	push	[ebp].FORW_EDI	; Pass current value
	call	DISP_EREG	; Display it

	mov	al,' '
	call	DISPTXT 	; Display byte on screen as text

	push	OLDEBP		; Pass former value
	push	[ebp].FORW_EBP	; Pass current value
	call	DISP_EREG	; Display it

	mov	al,' '
	call	DISPTXT 	; Display byte on screen as text

	push	OLDESP		; Pass former value
	push	[ebp].FORW_ESP	; Pass current value
	call	DISP_EREG	; Display it

	mov	al,' '
	call	DISPTXT 	; Display byte on screen as text

	push	OLDEIP		; Pass former value
	push	[ebp].FORW_EIP	; Pass current value
	call	DISP_EREG	; Display it

	call	NEXTLINE	; Skip to a new line

	REGREST <ds,esi,eax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPEGP endp			; End DISPEGP procedure
	NPPROC	DISP_EREG -- Display Extended Register
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display extended register along with change attribute.

|

EREG_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
EREG_NEW dd	?		; New value
EREG_OLD dd	?		; Old value

EREG_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ebx>	; Save registers

	mov	eax,[ebp].EREG_NEW ; Get new register value

	cmp	eax,[ebp].EREG_OLD ; Check against previous value
	je	short DISP_EREG2 ; Jump if same

	rol	eax,16		; Swap high- and low-order words

	cmp	ax,[ebp].EREG_OLD.EHI ; Check against previous high-order word
	jne	short DISP_EREG1 ; Jump if different

	call	DISPHEX2	; Display the word

	ror	eax,16		; Swap high- and low-order words

	mov	bl,REGATTR	; Get register changed attribute
	xchg	bl,DEFATTR	; Swap with default attibute
	call	DISPHEX2	; Display the word
	xchg	bl,DEFATTR	; Restore

	jmp	short DISP_EREG_EXIT ; Join common exit code

DISP_EREG1:
	ror	eax,16		; Swap high- and low-order words

	mov	bl,REGATTR	; Get register changed attribute
	xchg	bl,DEFATTR	; Swap with default attibute
	call	DISPHEX4	; Display the dword
	xchg	bl,DEFATTR	; Restore

	jmp	short DISP_EREG_EXIT ; Join common exit code

DISP_EREG2:
	call	DISPHEX4	; Display the dword
DISP_EREG_EXIT:
	REGREST <ebx,eax>	; Restore

	pop	ebp		; Restore

	ret	2*4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_EREG endp			; End DISP_EREG procedure
	NPPROC	DISP_SREG -- Display Selector/Segment Register
	assume	ds:nothing,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display a selector/segment register

On entry:

SS:EBP	==>	FORW_STR

|

DISP_SREG_STR struc

DISP_SREG_EBP dd ?		; Caller's EBP
	dd	?		; Caller's EIP
DISP_SREG_SR dw ?		; Selector/segment register
DISP_SREG_OLD dw ?		; Previous screen's value
DISP_SREG_MSG dd ?		; Offset of message to display
DISP_SREG_UNR dd ?		; Unreal Mode data (1=enabled, 0 = disabled)

DISP_SREG_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ebx,esi,ds> ; Save registers

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	mov	MSG_SEGSP[0],' ' ; Mark as not Unreal

	mov	esi,[ebp].DISP_SREG_MSG ; Get offset of message to display
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	movzx	esi,[ebp].DISP_SREG_SR ; Get the selector/segment register

	mov	ax,si		; Copy to AX
	mov	bl,DEFATTR	; Get default attribute

	cmp	ax,[ebp].DISP_SREG_OLD ; Check against old value
	je	short @F	; Jump if same value

	mov	bl,REGATTR	; Get changed register attribute
	xchg	bl,DEFATTR	; Swap with default attribute
@@:
	call	DISPHEX2	; Display word on screen in hex
	xchg	bl,DEFATTR	; Restore original value

	mov	ebx,ebp 	; Save old EBP for use in ..._VM
	mov	ebp,[ebp].DISP_SREG_EBP ; Restore EBP for access to FORW_STR

; If the caller is not in VM86 mode, display the DTE or LDTE

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	jnz	short DISP_SREG_VM ; Join common VM code

	and	si,not (mask $PL) ; Clear the privilege level bits

	btr	si,$TI		; Test and reset the Table Index bit
	jnc	short DISP_SREG_GDT ; Jump if it's in the GDT

	movzx	eax,[ebp-@BPBACK].BACK_LDT.DTR_LIM ; Get LDT selector
S16	lsl	<eax,eax>	; Get LDT selector limit into EAX

	cmp	esi,eax 	; Ensure it's within limits
	jae	short DISP_SREG_INV ; Jump if too large

	add	esi,[ebp-@BPBACK].BACK_LDT.DTR_BASE ; Plus the LDT's base

	jmp	short DISP_SREG_DTCOM ; Join common code

DISP_SREG_GDT:
	cmp	si,[ebp-@BPBACK].BACK_GDT.DTR_LIM ; Ensure it's within limits
	jae	short DISP_SREG_INV ; Jump if too large

	add	esi,[ebp-@BPBACK].BACK_GDT.DTR_BASE ; Plus GDT base
DISP_SREG_DTCOM:
	mov	al,'|'          ; Separator
	call	DISPTXT 	; Display byte on screen as text

; Display the selector's base

	mov	eax,AGROUP:[esi].DESC_BASE01.EDD ; Get bytes 0-2
	shl	eax,8		; Make room for byte 3
	mov	al,AGROUP:[esi].DESC_BASE3 ; Get byte 3
	ror	eax,8		; Rotate back to normal order
	call	DISPHEX4	; Display the dword

	mov	al,'-'          ; Separator
	call	DISPTXT 	; Display byte on screen as text

; Display the selector's limit

	mov	al,AGROUP:[esi].DESC_SEGLM1 ; Get the high-order nibble
	call	DISPHEX0	; Display the nibble

	mov	ax,AGROUP:[esi].DESC_SEGLM0 ; Get the low-order word
	call	DISPHEX2	; Display word on screen in hex

	mov	al,'-'          ; Separator
	call	DISPTXT 	; Display byte on screen as text

; Display the selector's flags nibble and access rights byte

	mov	al,AGROUP:[esi].DESC_SEGLM1 ; Get the high-order flags nibble
	shr	al,4		; Shift to low-order nibble
	call	DISPHEX0	; Display the nibble

	mov	al,AGROUP:[esi].DESC_ACCESS ; Get the access rights byte
	call	DISPHEX1	; Display the byte

	jmp	short DISP_SREG_EXIT ; Join common exit code

DISP_SREG_VM:
	cmp	ss:[ebx].DISP_SREG_UNR,1 ; Izit enabled?
	jne	short DISP_SREG_SKIP ; Jump if not

	mov	MSG_SEGSP[0],'+' ; Mark as Unreal
DISP_SREG_SKIP:
	lea	esi,MSG_SEGSP	; Skip over this many blanks
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	jmp	short DISP_SREG_EXIT ; Join common code

DISP_SREG_INV:
	mov	al,DEFATTR	; Save default attribute
	mov	ah,DEFBATTR	; Get default blinking attribute
	mov	DEFATTR,ah	; Put into effect
	lea	esi,MSG_SEGINV	; Display this message
	call	DISPASCIIZ	; Display ASCIIZ string from ESI
	mov	DEFATTR,al	; Restore
DISP_SREG_EXIT:
	REGREST <ds,esi,ebx,eax> ; Restore
	assume	ds:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	2*2+2*4 	; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_SREG endp			; End DISP_SREG procedure
	NPPROC	DISP_FLAG -- Display Flag Status
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display flag status

On entry:

EAX	=	flags to display
SS:EBP	==>	FORW_STR

|

	pushad			; Save all EGP registers

	mov	edx,[ebp].FORW_EFL ; Get current flags

; Set MSG_FLVM as per RM

	test	edx,mask $R2	; Izit from RM?
	mov	al,'V'          ; Assume not
	jz	short @F	; Jump if not

	mov	al,'R'          ; Assume so
@@:
	mov	MSG_FLVM.LO[3],al ; Save as VM/RM state

	mov	ebx,MASK_FLAG	; Get flag mask
	mov	ecx,NFLAGS	; Get # flags to display
	mov	edi,OLDEFL	; Get previous value of EFL
	xor	edi,edx 	; Get unequal values
	xor	esi,esi 	; Initialize index into MSG_FLAG

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text
DISP_FLAG_NEXT:
	shl	ebx,1		; Shift out one mask bit
	jc	short @F	; Jump if we should display it

	shl	edx,1		; Shift out actual flag bit
	shl	edi,1		; ...	    old ...

	jmp	short DISP_FLAG_NEXT ; Go around again

@@:
	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

	mov	eax,MSG_FLAG[esi] ; Get both possible flags
	add	esi,type MSG_FLAG ; Skip to next set

	shl	edx,1		; Shift out actual flag bit
	jnc	short DISP_FLAG1 ; Jump if it's clear

	shr	eax,16		; Shift down the high-order word
DISP_FLAG1:
	push	ebx		; Save for a moment

	mov	bl,DEFATTR	; Get default attribute

	shl	edi,1		; Shift out OLDEFL unequal flag
	jnc	short DISP_FLAG2 ; Jump if the bits were equal

	cmp	ax,'  '         ; Displaying blanks?
	je	short DISP_FLAG2 ; Yes, no need to change attributes

	mov	bl,REGATTR	; Get register changed attribute
	xchg	bl,DEFATTR	; Swap with default attibute
DISP_FLAG2:
	xchg	al,ah		; High-order byte
	call	DISPTXT 	; Display byte on screen as text

	xchg	al,ah		; Low-order byte
	call	DISPTXT 	; Display byte on screen as text

	xchg	bl,DEFATTR	; Restore

	pop	ebx		; Restore

	loop	DISP_FLAG_NEXT	; Jump if more flags to display
DISP_FLAG_EXIT:
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_FLAG endp			; End DISP_FLAG procedure
	NPPROC	DISP_INTR -- Display Intercepted Interrupt State
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display intercepted interrupt state

On entry:

DS:EBX	==>	INTRxx table
SS:EBP	==>	FORW_STR

|

	REGSAVE <eax,ebx,esi>	; Save registers

; If we're running as a TSS, use the TSSINT_FLAG entries

	cmp	TSS_CNT,0	; Izit TSS mode?
	je	short DISP_INTR_XTSS ; Jump if not

	mov	eax,DGROUP:[ebx].INTR_IMSK ; Get interrupt # mask

	test	eax,TSSINT_FLAG ; Izit intercepted?

	jmp	short DISP_INTR_COM ; Join common code with ZF significant


; If this is device SWAT, use the RGROUP entries

DISP_INTR_XTSS:
;;;;;;; test	DEVLOAD,@DEVL_LOAD ; Are we loading as device driver?
	test	[ebp].FORW_EFL,mask $R2 ; Izit device load?
	jnz	short DISP_INTR_DEVL ; Jump if so

	mov	esi,DGROUP:[ebx].INTR_DOFF ; Get flag dword offset in DGROUP
	mov	eax,DGROUP:[ebx].INTR_DMSK ; Get flag mask

	test	eax,DGROUP:[esi] ; Izit intercepted?

	jmp	short DISP_INTR_COM ; Join common code with ZF significant


DISP_INTR_DEVL:
	movzx	esi,RGRSEG2	; Get the (relocated) segment of RGROUP
	shl	esi,4-0 	; Convert from paras to bytes

	mov	eax,DGROUP:[ebx].INTR_RMSK ; Get flag mask

	assume	gs:RGROUP	; Tell a white lie to get addressibility
	test	eax,TRP_FLAG[esi] ; Izit intercepted?
	assume	gs:AGROUP	; Retract nose
DISP_INTR_COM:
	mov	esi,DGROUP:[ebx].INTR_ON ; Get offset in DGROUP if ON
	jnz	short DISP_INTR_DISP ; Jump if so

	mov	esi,DGROUP:[ebx].INTR_OFF ; Get offset in DGROUP if OFF
DISP_INTR_DISP:
	and	esi,esi 	; Izit invalid?
	jz	short @F	; Jump if so

	call	DISPASCIIZ	; Display ASCIIZ string from ESI
@@:
	REGREST <esi,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_INTR endp			; End DISP_INTR procedure
	NPPROC	DISP_MODE -- Display Program Modes
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display program modes such as Screen Save, Operand Analysis,
and hooked intercepts.

On entry:

SS:EBP	==>	FORW_STR

|

	REGSAVE <ebx,ecx,esi,SCROFF> ; Save registers and data

	push	MODOFF		; Get offset of mode line
	pop	SCROFF		; Save as current screen offset

; Display Screen Restore state

	test	LCL_FLAG,@LCL_SCRN ; Check screen restore state
	jz	short DISP_MODE1 ; Jump if off

	lea	esi,MSG_SSON	; Display "SS=ON "
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	jmp	short DISP_MODE1COM ; Join common code

DISP_MODE1:
	lea	esi,MSG_SSOFF	; Display "SS=OFF"
	call	DISPASCIIZ	; Display ASCIIZ string from ESI
DISP_MODE1COM:

; Display ARET level

	lea	esi,MSG_ARET	; Display "LVL="
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	mov	ax,@ARET_CNT	; Get maximum value
	sub	ax,ARET_CNT	; Less current value
	call	DISPHEX2	; Display word on screen in hex

; Display Branch Trace Facility state

	cmp	CPUFAM,06h	; Izit supported?
	jne	short DISP_MODE2COM ; Jump if not

	test	LC4_FLAG,@LC4_BTF ; Check Branch Trace Facility state
	jz	short DISP_MODE2 ; Jump if off

	lea	esi,MSG_BTFON	; Display "BTF=ON "
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	jmp	short DISP_MODE2COM ; Join common code

DISP_MODE2:
	lea	esi,MSG_BTFOFF	; Display "BTF=OFF"
	call	DISPASCIIZ	; Display ASCIIZ string from ESI
DISP_MODE2COM:

; Display text at end of line

	mov	eax,MODOFF	; Get start of line
	add	eax,2*(@NCOLS-TAIL_LEN) ; Skip to end of the line
	mov	SCROFF,eax	; Save as new offset

; Display Interrupt Intercept State

	mov	ecx,TOGINT_CNT	; Get # entries in the table
	lea	ebx,TOGINT_TAB	; Get table offset
@@:
	call	DISP_INTR	; Display the appropriate message

	add	ebx,type INTR_STR ; Skip to the next entry

	loop	@B		; Jump if more entries to display

	REGREST <SCROFF,esi,ecx,ebx> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_MODE endp			; End DISP_MODE procedure
	NPPROC	DISPDEC -- Display an unsigned long integer on the Screen
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the unsigned dword in EAX at DTE_VID:SCROFF and following
skipping over the attribute bytes.  Display is left justified.

|

	REGSAVE <esi,edi,ds,es> ; Save

	SETDATA ds		; Address DGROUP
	assume	ds:DGROUP	; Tell the assembler

	push	ds		; Copy DGROUP segment
	pop	es		; Address for FMTDEC
	assume	es:DGROUP	; Tell the assembler

	lea	edi,AZS_DECFMT	; Address ones place in decimal output string
	call	FMTDEC		; Format EAX in decimal ending at ES:EDI

	mov	esi,edi 	; Address output for DISPASCIIZ
	call	DISPASCIIZ	; Display string at DGROUP:ESI

	REGREST <es,ds,edi,esi> ; Restore
	assume	es:nothing	; Tell the assembler

	ret			; Return to caller

DISPDEC endp			; End DISPDEC procedure
	NPPROC	FMTDEC -- Format EAX in decimal ending at ES:EDI
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format EAX as a decimal number with the units digit at ES:EDI.

On entry:
EAX		Number to format
ES:EDI ==>	Units digit of destination string

On exit:
ES:EDI ==>	Most significant digit of formatted string

|

	REGSAVE <eax,ecx,edx>	; Save registers

	std			; Set backwards direction

	mov	ecx,10		; Divisor
FMTDEC_NEXT:
	sub	edx,edx 	; Prepare for divide
	div	ecx		; Get remainder in edx
	xchg	eax,edx 	; Save quotient
	add	al,'0'          ; Convert remainder to ASCII
S32	stos	es:[edi].LO	; Save in output string
	mov	eax,edx 	; Get quotient for next divide
	or	eax,eax 	; Are we done?
	jnz	short FMTDEC_NEXT ; Jump if not

	inc	edi		; Point to most significant digit of string

	cld			; Restore direction flag

	REGREST <edx,ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMTDEC	endp			; End FMTDEC procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_SCR module
