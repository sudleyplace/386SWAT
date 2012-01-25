	 title	 DPMITSR -- Sample DPMI TSR
	 page	 58,122
	 name	 DPMITSR

COMMENT|

Copyright (C) 1993, Qualitas Inc.  All Rights Reserved.

This program is an example of a simple DPMI TSR.  It hooks Int 21
function 4B.

For a simpler example of DPMI, see HELLO_PM.ASM.

To compile and link:
nmake /f dpmitsr.mak

To debug:
swatrun dpmitsr

|
.386p

CR	equ	0dh
LF	equ	0ah
EOS	equ	'$'

@OPCOD_NOP	equ	90h
@OPCOD_JMPF	equ	0EAh
@OPCOD_CALLF    equ	9Ah

PPROC	macro	@PROCNAME
Public	@PROCNAME
@PROCNAME	proc
	endm

DISP_STR macro	@MSG,@REG
ifnb <@MSG>
ifnb <@REG>
	lea	@REG,@MSG	; Used to specify EDX
else
	lea	dx,@MSG
endif
endif
	mov	ah,9		; DOS display string function
	int	21h
	endm

if @Version GE 600
OPTION	OLDSTRUCTS		; Allow simplified typecasting
OPTION	READONLY		; Make all code segments READONLY
else
PUSHD	macro	NN
	db	66h		; OSP
	push	NN
	endm
NOPD	macro
	db	66h		; OSP
	nop
	endm
endif

HILO_STR	struc
LO	db	?
HI	db	?
HILO_STR	ends

EHILO_STR	struc
ELO	dw	?
EHI	dw	?
EHILO_STR	ends

VSEG_STR	struc		; V86 mode segment:offset vector
VOFF	dw	?
VSEG	dw	?
VSEG_STR	ends

EDD_STR		struc
EDD	dd	?
EDD_STR		ends

FSEG_STR	struc		; PM selector:offset32 vector
FOFF	dd	?
FSEL	dw	?
	dw	0		; Filler
FSEG_STR	ends

FARJMP_STR	struc		; Far jump to raw mode switch code
FJ_NOP	db	90h		; NOP (for patching in CC)
FJ_CALLF db	@OPCOD_CALLF	; Far call immediate
FJ_OFF	dw	?		; Offset
FJ_SEG	dw	?		; Segment
FARJMP_STR	ends

VMC_STR  struc			; VM call structure

VMC_EDI  dd	 ?		; 00-03:  EDI to use in VM
VMC_ESI  dd	 ?		; 04-07:  ESI ...
VMC_EBP  dd	 ?		; 08-0B:  EBP ...
	 dd	 ?		; 0C-0F:  (reserved)
VMC_EBX  dd	 ?		; 10-13:  EBX ...
VMC_EDX  dd	 ?		; 14-17:  EDX ...
VMC_ECX  dd	 ?		; 18-1B:  ECX ...
VMC_EAX  dd	 ?		; 1C-1F:  EAX ...
VMC_FL	 dw	 ?		; 20-21:  FL ...
VMC_ES	 dw	 ?		; 22-23:  ES ...
VMC_DS	 dw	 ?		; 24-25:  DS ...
VMC_FS	 dw	 ?		; 26-27:  FS ...
VMC_GS	 dw	 ?		; 28-29:  GS ...
VMC_IP	 dw	 ?		; 2A-2A:  IP ...
VMC_CS	 dw	 ?		; 2C-2D:  CS ...
VMC_SP	 dw	 ?		; 2E-2F:  SP ...
VMC_SS	 dw	 ?		; 30-31:  SS ...

VMC_STR  ends

@MAXENTRY equ	80h/(size FARJMP_STR) ; How many to fit in PSP

NGROUP	group	NCODE,NDATA,STACK,ZNDATA
PGROUP	group	CODE,DATA,EDATA,ZDATA

; Declare all the segments in the order we want them in the .EXE file
NCODE	segment use16 public dword 'CODE'
NCODE	ends

NDATA	segment use16 public dword 'DATA'
NDATA	ends

STACK	segment use16 stack dword 'STACK'
STACK	ends

ZNDATA	segment use16 public dword 'DATA'
ZNDAT	label byte
ZNDATA	ends

; Protected mode segments.  ZDATA is used as an end marker for PGROUP.
CODE	segment use16 public dword 'CODE'
CODE	ends

DATA	segment use16 public dword 'DATA'
DATA	ends

EDATA	segment use16 public dword 'DATA'
EDATA	ends

ZDATA	segment use16 public dword 'DATA'
ZDAT	label	byte
ZDATA	ends

EDATA	segment
	assume ds:PGROUP

	Public	PM_extmem
PM_extmem db	'Executing code in extended memory in protected mode',CR,LF,EOS

	Public	VMCallback_regs
VMCallback_regs VMC_STR <>	; Registers for real mode callback

	Public	PrevInt21
PrevInt21 dd	?		; Segment:offset of previous Int 21 handler

	Public	PM2VM
PM2VM	df	?		; Protected mode to V86 mode raw mode switch

EDATA	ends

DATA	segment
	assume ds:PGROUP

	Public	PSPSEG,HPDASEG,UMBSEG,PSPSEL,PM_entry,XMS_entry
PSPSEG	dw	?		; Segment of V86 mode PSP (DS on entry)
HPDASEG dw	?		; Segment of Host Private Data Area
UMBSEG	dw	0		; Segment of UMB to free on exit (if any)
PSPSEL	dw	?		; PSP segment converted to PM selector
PM_entry dd	?		; Far entry to DPMI enter PM function
XMS_entry dd	?		; Far entry to XMS services API

	Public	Ext_mainp
Ext_mainp dd	PGROUP:Ext_main ; Selector:offset for main body of code

LDTSEL_STR	struc		; LDT selectors we allocate and use
LDTSEL_NGROUP	dw	?	; Selector for NGROUP
LDTSEL_PGROUPC	dw	?	; Selector for PGROUP code in extended memory
LDTSEL_PGROUPD	dw	?	; Selector for PGROUP data ...
LDTSEL_ALLMEM	dw	?	; All memory selector
LDTSEL_STR	ends

	Public	LDTSEL
LDTSEL	LDTSEL_STR <>		; Dynamic LDT entries
@LDTCOUNT equ	(size LDTSEL_STR) / 2 ; Number of entries in LDTSEL_STR

DPMIMEM_STR	struc		; DPMI memory block data
DPMIMEM_HDL	dd	?	; Handle
DPMIMEM_BASE	dd	?	; Base linear address of block
DPMIMEM_LIM	dd	?	; Limit of block (size-1)
DPMIMEM_STR	ends

	Public	MEM_HDL,MEM_BASE,MEM_LIM
MEM_HDL 	dd	?	; Handle for extended memory block
MEM_BASE	dd	?	; Linear address of memory block
MEM_LIM 	dd	?	; Limit (size-1) of memory block

	Public	PMErr_LDT_failed,PMErr_SetBase_failed
PMErr_LDT_failed db 7,'Allocate LDT entry failed.',CR,LF,EOS
PMErr_SetBase_failed db 7,'Set selector base failed.',CR,LF,EOS

	Public	Err_not386,Err_notVM,Err_noDPMI
	Public	Err_no32bit,Err_HPDA_failed,Err_CBFailed
Err_not386 db	7,'80386 CPU required.',CR,LF,EOS
Err_notVM db	7,'System is not in protected mode.',CR,LF,EOS
Err_noDPMI db	7,'DPMI services are not available.',CR,LF,EOS
Err_no32bit db	7,'This application requires 32-bit DPMI services.',CR,LF,EOS
Err_HPDA_failed db 7,'Unable to allocate Host Private Data Area.',CR,LF,EOS
Err_CBFailed db	7,'Unable to allocate VM callback.',CR,LF,EOS

	Public	PM_msg,PM_reloc,PM_idone,PM_done
PM_msg	db	'In protected mode, PL3.  Allocating extended memory',CR,LF,EOS
PM_reloc db	'Relocating code and data to extended memory',CR,LF,EOS
PM_idone db	'Ready to jump to code in extended memory',CR,LF,EOS
PM_done db	'Done.  Returning to V86 mode via DOS function 4Ch',CR,LF,EOS

	Public	PMErr_noextmem,PMErr_setsel
PMErr_noextmem db 7,'Unable to allocate extended memory',CR,LF,EOS
PMErr_setsel db 7,'Unable to set selector base/limit',CR,LF,EOS

	Public	DPMI_stats
DPMI_stats label byte
	db	'DPMI version '
DPMI_sver db	'x.xx',CR,LF
	db	'CPU type is 80'
DPMI_scpu db	'x86',CR,LF,EOS

DATA	ends

NDATA	segment
	assume es:NGROUP

	Public	Init_msg,RMS_Stack
Init_msg db	'DPMITSR v0.10 ออ A Sample DPMI TSR',CR,LF,EOS
	db	512	dup (?)
RMS_Stack dw	?		; Stack to use in V86 mode for raw mode switch

	Public	RMS_DS,RMS_ES,RMS_SS,RMS_ESP,RMS_CS
RMS_DS	dw	?		; Registers to restore for return to protected
RMS_ES	dw	?		; mode
RMS_SS	dw	?
RMS_ESP	dd	?
RMS_CS	dw	?

	Public	VM2PM_entry
VM2PM_entry dd	?		; Far entry for raw mode switch, VM -> PM

NDATA	ends

NCODE	segment
	assume cs:NGROUP

;------------ No 286 or 386 instructions until we check CPU type -----------
Public	Start
Start:
	assume	ds:nothing,es:nothing,ss:nothing

	mov	bx,ds		; Save PSP segment

	mov	ax,seg PGROUP	; Get addressability to PGROUP
	mov	ds,ax
	assume	ds:PGROUP	; Tell the assembler

	mov	ax,seg NGROUP	; Get addressability to NGROUP
	mov	es,ax
	assume	es:NGROUP	; Tell the assembler

	mov	PSPSEG,bx	; Save PSP segment

	push	ds		; Save PGROUP segment

	mov	ds,ax		; Get addressability to NGROUP
	assume	ds:NGROUP	; Tell the assembler

	DISP_STR Init_msg	; Display message

	pop	ds		; Restore
	assume	ds:PGROUP	; Tell the assembler

	call	Init		; Perform initialization, return with CF=?
	jc	short Exit_err	; Init failed, message in DS:DX

	call	PM_init 	; Perform PM initialization, return in
				; PL3 protected mode.
	jc	short Exit_err	; PM_init failed, message in DS:DX

	call	Ext_mainp	; Call far indirect; selector set in PM_init
	jnc	short @F	; Jump if OK

	lea	edx,Err_CBFailed ; "VM Callback allocate failed"
	jmp	short Exit_err	; Join common error code

@@:
	DISP_STR PM_done,edx	; Tell 'em we're done

; Return to V86 mode via a raw mode switch
; Hook V86 mode interrupts
; Terminate and stay resident

	mov	ax,3100h	; Terminate and stay resident, errorlevel 0
	mov	dx,10h		; Just keep the PSP

	int	21h		; Call DOS via host translation

	Public	Exit_err
Exit_err:
; DS:eDX ==> error message to display
	DISP_STR		; Display string

	mov	al,-1		; Error level to return

; AL contains error code
	mov	dx,UMBSEG	; Get UMB segment (if we allocated it)
	or	dx,dx		; Did we allocate a UMB?
	jz	short @F	; Jump if not

	push	ax		; Save errorlevel

	mov	ah,11h		; XMS Release UMB function
	call	PM_XMS		; Return status in AX, error code in BL
				; if AX=0.  Ignore return code

	pop	ax		; Restore errorlevel

@@:
	mov	ah,4ch		; Terminate process with errorlevel in AL
	int	21h

	int	20h		; In case we're running DOS 4.0
	assume	ds:nothing,es:nothing,ss:nothing


	PPROC	Init
	assume	ds:PGROUP,es:NGROUP,ss:nothing
COMMENT|

Perform initialization.  Return failure/success in CF.

On entry:
Nothing.

On exit:
CF=0		Initialization succeeded.
CF=1		Initialization failed, error code in DS:DX.
DS:DX ==>	Error message if CF=1

|

	push	ax		; Save registers
	push	bx
	push	cx
	push	si
	push	di

; Check to ensure this is a 286 or better
	lea	dx,Err_not386	; Error message (in case we fail)
	push	sp		; 8086: push (++sp); 286+: push sp
	pop	ax		; Get pushed value for comparison
	cmp	ax,sp		; Was it incremented before or after?
	jne	short Init_err	; Join common error code if 8086

;--------- OK to use 286 instructions ------------------------
	lea	dx,Err_notVM	; Error message (in case we fail)
	smsw	ax		; Get MSW
	test	ax,1		; Is PM bit set?
	jz	short Init_err	; Join common error code

;--------- OK to use 386 instructions -----------------------
	mov	ax,1687h	; Presence check/get protected mode entry point
	int	2fh		; Return with AX=0 if available
	assume	es:nothing	; Tell the assembler ES changed

COMMENT|

BX	 =	 flags; bit 0 set means 32-bit clients supported
CL	 =	 CPU type (02 = 286, 03 = 386, 04 = 486, etc.)
DH	 =	 DPMI major version # (in decimal)
DL	 =	 ...  minor ...
SI	 =	 # paras needed for host private data area
ES:DI	 ==>	 VM -> PM entry point

|

	mov	PM_entry.VSEG,es ; Save vector for protected mode entry point
	mov	PM_entry.VOFF,di

	push	seg NGROUP	; Restore addressability to NGROUP
	pop	es
	assume	es:NGROUP	; Tell the assembler

	or	cl,'0'          ; Convert CPU type to ASCII
	mov	DPMI_scpu,cl	; Save in status message

	or	dh,'0'          ; Convert major version # to ASCII
	mov	DPMI_sver[0],dh ; Save in status message
	xchg	ax,dx		; Prepare to unpack BCD value
	aam			; DH=tens, DL=ones
	or	ax,'00'         ; Convert to ASCII
	mov	DPMI_sver[2],ah
	mov	DPMI_sver[3],al
	mov	ax,dx		; Restore return code

	lea	dx,Err_noDPMI	; Error message if we fail
	or	ax,ax		; Are DPMI services present?
	jnz	short Init_err	; Jump if not

	DISP_STR DPMI_stats	; Display status message

	lea	dx,Err_no32bit	; Error message if failure
	test	bx,1		; Are 32-bit services available?
	jz	short Init_err	; Jump if not

	mov	ax,si		; Paragraphs needed for HPDA
	lea	dx,Err_HPDA_failed ; Error message if we fail
	call	Get_HPDA	; Return HPDA segment in AX or CF=1 if failed
	jc	short Init_err	; Jump if we couldn't allocate HPDA

	mov	HPDASEG,ax	; Save segment of HPDA

;;;;;	clc			; Indicate success
	jmp	short Init_exit ; Join common exit code

;--------- 8086 instructions only --------------------------
Init_err:
	stc			; Indicate failure

Init_exit:
	pop	di		; Restore registers
	pop	si
	pop	cx
	pop	bx
	pop	ax

	ret

;--------- OK to use 386 instructions -----------------------
	assume	ds:nothing,es:nothing,ss:nothing

Init	endp			; End procedure Init

	PPROC	Get_HPDA
	assume	ds:PGROUP,es:NGROUP,ss:nothing
COMMENT|

Allocate Host Private Data Area in (first choice) high DOS via XMS
UMB allocation or (second choice) in low DOS via DOS GETMEM.

On entry:
AX	=	# of paragraphs to allocate

On exit:
AX	=	segment of HPDA
CF=0		allocation was successful
CF=1		allocation in low DOS failed

|

	push	bx
	push	cx
	push	dx

	push	ax		; Save paragraphs to allocate

	mov	ax,4300h	; XMS installation check
	int	2fh		; AL=80h if present

	pop	dx		; Get paragraphs

	cmp	al,80h		; Are XMS services present?
	jne	short Get_HPDA_noXMS ; Jump if not (allocate in low DOS)

	push	dx		; Save paragraphs
	push	es		; Save PGROUP segment

	mov	ax,4310h	; Get XMS entry point
	int	2fh		; Vector in ES:BX
	assume	es:nothing	; Tell the assembler ES changed

	mov	XMS_entry.VSEG,es
	mov	XMS_entry.VOFF,bx

	pop	es		; Restore addressability to NGROUP
	assume	es:NGROUP	; Tell the assembler

	pop	dx		; Paragraphs to allocate
	push	dx		; Save
	mov	ah,10h		; Allocate UMB for DX paras
	call	XMS_entry	; AX=status, BX=UMB segment
	pop	dx		; Restore
	cmp	ax,1		; Did call succeed?
	jne	short Get_HPDA_noXMS ; Try low DOS

	mov	UMBSEG,bx	; Save segment
	mov	ax,bx		; Put in AX for return
	jmp	short Get_HPDA_exit ; Exit with CF=0

Get_HPDA_noXMS:
; Allocate HPDA in low DOS.  Paragraphs to allocate are in DX.
	mov	ah,48h		; DOS GETMEM function
	mov	bx,dx		; Paragraphs to allocate
	int	21h		; CF=?, AX=segment
				; Return with CF significant

Get_HPDA_exit:
	pop	dx
	pop	cx
	pop	bx

	ret

	assume	ds:nothing,es:nothing,ss:nothing

Get_HPDA endp			; End procedure Get_HPDA

	PPROC	PM_init
	assume	ds:PGROUP,es:NGROUP,ss:nothing
COMMENT|

Protected mode initialization.	Allocate extended memory via DPMI services,
move code to extended memory, and return in protected mode.

On entry:
Nothing.

On exit:
CF=0		Success
CF=1		Failure
DS:EDX ==>	error message if CF=1

|

	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di

	mov	ax,1		; Set flag for 32-bit application
	mov	es,HPDASEG	; Segment of HPDA
	assume	es:nothing	; Tell assembler ES changed

	call	PM_entry	; Return in PM
	assume	es:nothing	; ES changed

	jnc	short @F	; Jump if successful

; Call failed; we're in V86 mode.  Restore addressability to NGROUP.
	push	seg NGROUP
	pop	es
	assume	es:NGROUP	; Tell the assembler
	jmp	near ptr PM_init_exit ; Return with CF significant

@@:
COMMENT|

Segment register contents:

	CS	16-bit selector with base of V86 mode CS and 64K limit
	DS	Selector with base of V86 mode DS and 64K limit
	SS	Selector with base of V86 mode SS and 64K limit
	ES	Selector with base equal to PSP with 256 byte limit
	FS,GS	0

	Note that CS, DS, and SS have automatically been translated
	from segment values into selectors for the same address ranges.
	ES points to our PSP, and can be saved for later use.
	Also note that even if CS, DS, and SS are the same, the selectors
	returned will NOT be the same, although the bases and limits
	may be the same.

|
	mov	PSPSEL,es	; Save selector to PSP
	push	ds
	pop	es
	assume	es:PGROUP	; Get a sane value in ES until we get NGROUP

; To get addressability to NGROUP, we need to allocate an LDT selector.
	mov	ax,0		; Function 0: allocate LDT selector(s).
	mov	cx,@LDTCOUNT	; Selectors to allocate.
	int	31h		; Return with CF=? and AX=base selector.
	lea	edx,PMErr_LDT_failed ; Error message to display if we failed
	jc	near ptr PM_init_exit ; Exit with CF significant if we failed

	push	ax		; Save base of selector array allocated
	mov	ax,0003h	; Function 3: Get selector increment value
	int	31h		; Return with AX=8 (ignore CF)
	pop	bx		; Restore selector base value

	mov	dx,bx		; Start with base value
	mov	LDTSEL.LDTSEL_NGROUP,dx ; Save NGROUP selector
	add	dx,ax		; Next selector
	mov	LDTSEL.LDTSEL_PGROUPC,dx ; Save PGROUP code selector
	mov	Ext_mainp.VSEG,dx ; Set selector for far indirect call
	add	dx,ax		; Next selector
	mov	LDTSEL.LDTSEL_PGROUPD,dx ; Save PGROUP data selector
	add	dx,ax		; Next selector
	mov	LDTSEL.LDTSEL_ALLMEM,dx; Save all memory selector

	mov	bx,LDTSEL.LDTSEL_NGROUP ; Get NGROUP selector
	mov	cx,seg NGROUP	; Segment in paras
	mov	dx,cx		; Segment in paras
	shl	dx,4		; Convert to bytes (low order 16 bits)
	shr	cx,12		; High order 16-bits of 32-bit offset
	mov	ax,7		; Set selector base
	int	31h		; Return with CF significant
	lea	edx,PMErr_SetBase_failed ; Error message to display if we failed
	jc	near ptr PM_init_exit ; Jump if failed

	mov	bx,LDTSEL.LDTSEL_NGROUP ; Get NGROUP selector
	lea	ecx,ZNDAT	; Segment length
	dec	ecx		; Convert to limit
	mov	dx,cx		; Low word of limit
	shr	ecx,16		; High word in CX
	mov	ax,0008h	; Set selector base
	int	31h		; Return with CF significant
	lea	edx,PMErr_SetBase_failed ; Error message to display if we failed
	jc	near ptr PM_init_exit ; Jump if failed

	mov	bx,LDTSEL.LDTSEL_ALLMEM ; Get all memory selector
	sub	ecx,ecx		; Segment base at 0
	mov	edx,ecx		; Low word of base
	mov	ax,0007h	; Set selector base
	int	31h		; Return with CF significant
	lea	edx,PMErr_SetBase_failed ; Error message to display if we failed
	jc	near ptr PM_init_exit ; Jump if failed

	mov	bx,LDTSEL.LDTSEL_ALLMEM ; Get all memory selector
	mov	ecx,-1		; Segment length (4GB)
	mov	edx,-1		; Low word of limit
	mov	ax,0008h	; Set selector limit
	int	31h		; Return with CF significant
	lea	edx,PMErr_SetBase_failed ; Error message to display if we failed
	jc	near ptr PM_init_exit ; Jump if failed

	mov	es,LDTSEL.LDTSEL_NGROUP ; Get NGROUP selector
	assume	es:NGROUP	; Tell the assembler

	DISP_STR PM_msg,edx	; Tell 'em we made it into PM

; Now allocate memory for moving PGROUP into extended memory
	lea	ebx,ZDAT	; End of PGROUP
	mov	MEM_LIM,ebx	; Save size
	dec	MEM_LIM 	; Convert to limit (size-1)
	mov	cx,bx		; Low 16 bits of size
	shr	ebx,16		; High word
	mov	ax,0501h	; Allocate memory block for BX:CX bytes
	int	31h		; BX:CX = linear address, SI:DI = handle
	lea	edx,PMErr_noextmem ; Message to display if we failed
	jc	near ptr PM_init_exit ; Jump if call failed

	mov	MEM_HDL.VSEG,si ; Save high 16 bits of handle
	mov	MEM_HDL.VOFF,di ; Low 16 bits
	mov	MEM_BASE.VSEG,bx ; High 16 bits of linear address
	mov	MEM_BASE.VOFF,cx ; Low 16 bits

SETUP_SEG	macro	@SELNAME
	mov	dx,MEM_BASE.VOFF ; Prepare to set segment base
	mov	cx,MEM_BASE.VSEG ; CX:DX = new base
	mov	bx,LDTSEL.LDTSEL_&@SELNAME ; Selector value for segment
	mov	ax,0007h	; Set segment base
	int	31h		; Return with CF significant
	lea	edx,PMErr_setsel ; Message to display if we failed
	jc	near ptr PM_init_exit ; Jump if call failed

	mov	dx,MEM_LIM.VOFF ; Get low 16 bits of limit
	mov	cx,MEM_LIM.VSEG ; High 16 bits
	mov	bx,LDTSEL.LDTSEL_&@SELNAME ; Selector value segment
	mov	ax,0008h	; Set segment limit
	int	31h		; Return with CF significant
	lea	edx,PMErr_setsel ; Message for failure
	jc	near ptr PM_init_exit ; Jump if call failed

	endm			; end SETUP_SEG macro

; Both selectors refer to the same block of memory, with the same
; base and limit.
	SETUP_SEG	PGROUPC ; Extended memory code segment
	SETUP_SEG	PGROUPD ; Extended memory data segment

; We set the code selector's ARB to read-only.
	mov	bx,LDTSEL.LDTSEL_PGROUPC ; Get code selector
	lar	cx,bx		; Get current ARW for code selector
	xchg	ch,cl		; Swap byte order
	and	cl,not 00001110b ; Mask off Code/conform/read-write bits
	or	cl,00001010b	; Code, non-conforming, readable
	mov	ax,0009h	; Set descriptor access rights
	int	31h		; Return with CF significant
	lea	edx,PMErr_setsel ; Message for failure
	jc	short PM_init_exit ; Jump if call failed

	DISP_STR PM_reloc,edx	; Tell 'em we're moving

	push	es		; Save NGROUP

	mov	es,LDTSEL.LDTSEL_PGROUPD ; Extended memory data segment
	assume	es:nothing
	sub	esi,esi 	; Beginning of low DOS PGROUP
	sub	edi,edi 	; Beginning of extended memory PGROUP
	lea	ecx,ZDAT	; Bytes in PGROUP
   rep	movs	es:[edi].LO,PGROUP:[esi].LO ; Move it
	NOPD

	pop	es		; Restore NGROUP

	DISP_STR PM_idone,edx	; Message to display

PM_init_exit:
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax

	ret

	assume	ds:nothing,es:nothing,ss:nothing

PM_init endp			; End procedure PM_init

	PPROC	PM_XMS
	assume	ds:PGROUP,es:NGROUP,ss:nothing
COMMENT|

Make a bimodal XMS call.

|

	push	es

	push	ax		; Save XMS function code
	mov	ax,1686h	; Get current mode
	int	2fh		; AX=0 if in protected mode
	or	ax,ax
	pop	ax		; Restore XMS function code

	jz	short @F	; Jump if in PM

	call	XMS_entry	; Regular real mode call to XMS
	jmp	short PM_XMS_exit ; Join common exit

@@:
; Create real mode call structure
	PUSHD	0		; Null SS:SP; DPMI host will provide a small
				; real-mode stack for us
	push	XMS_entry	; CS:IP
	push	0		; GS
	push	0		; FS
	push	seg PGROUP	; DS
	push	seg NGROUP	; ES

	pushf
	push	eax
	push	ecx
	push	edx
	push	ebx
	PUSHD	0		; Reserved
	push	ebp
	push	esi
	push	edi

	mov	cx,0		; Words to copy on stack
	mov	ax,0302h	; Call real mode procedure with far return
	mov	bh,0		; All flags 0

	mov	edi,esp 	; Address call structure
	push	ss
	pop	es		; ES|EDI ==> real mode call structure

	int	31h		; Return with CF significant

	pop	edi
	pop	esi
	pop	ebp
	pop	ebx		; Remove reserved value
	pop	ebx		; Restore EGP regs returned by XMS call
	pop	edx
	pop	ecx
	pop	eax
	popf

	lea	esp,[esp+4*2+2*4] ; Strip 4 words & 2 dwords from stack

PM_XMS_exit:
	pop	es
	assume	es:NGROUP

	ret

	assume	ds:nothing,es:nothing,ss:nothing

PM_XMS	endp			; End procedure PM_XMS

	PPROC	RMS_VM
	assume	ds:NGROUP,es:NGROUP
COMMENT|

We get here via raw mode switch.  We switch back to protected mode.

|

	mov	ax,RMS_DS	; DS selector for return to protected mode
	mov	cx,RMS_ES	; ES ...
	mov	dx,RMS_SS	; SS ...
	mov	ebx,RMS_ESP	; ESP for return to protected mode
	mov	si,RMS_CS	; Code selector
	lea	edi,EM_Exit	; EIP in protected mode

	jmp	VM2PM_entry	; Switch to protected mode

RMS_VM	endp			; End procedure RMS_VM

NCODE	ends

CODE	segment
	assume	cs:PGROUP

	PPROC	PMInt21
	assume	ds:nothing,es:nothing
COMMENT|

Int 21 handler in protected mode called via VM callback.

On entry:
VMCallback_regs contain VM registers
DS:ESI	==>	Real mode SS:SP with far return from call to mode switch
ES:EDI	==>	VMCallback_regs
SS:ESP	==>	Host's locked protected mode stack

On exit:
ES:EDI	==>	(Possibly changed) VMCallback_regs

|

	pushad			; All we really need to save is ES:EDI
	push	fs

	mov	eax,PrevInt21	; Get address of previous Int 21 handler
	mov	ds:[esi].EDD,eax ; RETF ==> previous handler

	mov	ds,LDTSEL.LDTSEL_PGROUPD ; Get extended memory data selector
	assume	ds:PGROUP	; Tell the assembler

	mov	ax,es:[edi].VMC_EAX.ELO ; Get caller's AX

	cmp	ah,4Bh		; Izit an EXEC call?
	jne	short PMInt21_Exit ; Jump if not

	cmp	al,01h		; Izit Exec and load or load?
	ja	short PMInt21_Exit ; Jump if not

	mov	fs,LDTSEL.LDTSEL_ALLMEM ; Get all memory selector
	assume	fs:nothing	; Tell the assembler

	sub	esi,esi		; Clear high order word
	mov	eax,esi
	mov	si,es:[edi].VMC_DS ; Get caller's data seg
	shl	esi,4-0		; Convert paras to bytes
	mov	ax,es:[edi].VMC_EDX.ELO ; Get caller's offset
	add	esi,eax		; FS:ESI ==> file to load

PMInt21_Exit:
	pop	fs
	assume	fs:nothing

	popad

	IRETD			; Return to caller

PMInt21 endp			; End procedure PMInt21

	PPROC	Ext_main
	assume	ds:PGROUP,es:nothing
COMMENT|

This is the main procedural body executing in protected mode
from extended memory.

On entry:
DS	==>	PGROUP in low memory

On exit:
nothing.

|

	push	ds		; Save low memory selectors
	push	es

	mov	ds,LDTSEL.LDTSEL_PGROUPD ; Get extended memory data selector
	assume	ds:PGROUP	; Tell the assembler

	lea	edx,PM_extmem	; Message to display
	mov	ah,9		; DOS display string
	int	21h

	push	ds		; Save data selector

	lea	esi,PGROUP:PMInt21 ; DS:ESI ==> PM procedure for callback
	mov	es,LDTSEL.LDTSEL_PGROUPD ; Get extended memory data selector
	assume	es:PGROUP	; Tell the assembler

	lea	edi,PGROUP:VMCallback_regs ; ES:EDI ==> VM register structure

	push	cs		; Get code selector
	pop	ds		; DS:ESI ==> PM procedure
	assume	ds:nothing	; Tell the assembler

	mov	ax,0303h	; Allocate VM callback
	int	31h		; CX:DX ==> seg:off of VM callback

	pop	ds		; Restore
	assume	ds:PGROUP	; Tell the assembler

	jc	near ptr EM_Exit ; Jump if call failed

	mov	es,PSPSEL	; Address PSP
	assume	es:nothing	; Tell the assembler

	mov	es:[80h].FJ_NOP,@OPCOD_NOP ; Save space for Int 3
	mov	es:[80h].FJ_CALLF,@OPCOD_CALLF ; Far call immediate
	mov	es:[80h].FJ_OFF,dx ; Save offset of callback
	mov	es:[80h].FJ_SEG,cx ; ... segment

	mov	ax,0200h	; Get VM interrupt vector
	mov	bl,21h		; Interrupt to get vector for
	int	31h		; CX:DX ==> previous vector

	mov	PrevInt21.VOFF,dx ; Save address of previous handler
	mov	PrevInt21.VSEG,cx

	mov	ax,0201h	; Set VM interrupt handler
	mov	bl,21h		; Interrupt to hook
	mov	cx,PSPSEG	; Segment of Int 21 handler (in PSP)
	mov	dx,0080h	; Offset
	int	31h		; Ignore result in CF

; We use the Allocate VM Callback (AX=303) to switch to protected mode
; from our VM interrupt handler.  We'll do a raw mode switch here just
; to show how it's done...
	mov	ax,0306h	; Get raw mode switch addresses
	int	31h		; BX:CX ==> VM2PM, SI:EDI ==> PM2VM

	mov	PM2VM.FOFF,edi	; Set up far call for PM -> VM
	mov	PM2VM.FSEL,si

; Save registers for return.
	mov	ax,es		; Save PSP selector

	mov	es,LDTSEL.LDTSEL_NGROUP ; Get NGROUP selector
	assume	es:NGROUP	; Tell the assembler

	mov	VM2PM_entry.VOFF,cx ; Set up far call for VM -> PM
	mov	VM2PM_entry.VSEG,bx

	mov	RMS_DS,ds	; Save return DS
	mov	RMS_ES,ax	;	  ... ES
	mov	RMS_CS,cs	;	  ... CS
	mov	RMS_SS,ss	; Save return stack
	mov	RMS_ESP,esp

	mov	ax,seg NGROUP	; New DS in VM
	mov	cx,ax		; ... ES
	mov	dx,ax		; ... SS
	lea	bx,NGROUP:RMS_Stack ; ... SP

	mov	si,ax		; New CS
	lea	di,NGROUP:RMS_VM ; Code to switch back to PM
	jmp	PM2VM		; Raw mode switch to SI:DI in VM

	int	3		; We'll never get here...

	public	EM_Exit
EM_Exit:
	pop	es
	pop	ds
	assume	ds:nothing,es:nothing

	retf			; Far return to caller

	assume	ds:nothing,es:nothing,ss:nothing

Ext_main endp			; End procedure Ext_main
CODE	ends

	end	Start

; End module DPMITSR

