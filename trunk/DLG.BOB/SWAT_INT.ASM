;' $Header:   P:/PVCS/386SWAT/SWAT_INT.ASV   1.29   10 Aug 1998 11:01:10   BOB  $
	title	SWAT_INT -- 386SWAT Interrupt Handlers
	page	58,122
	name	SWAT_INT

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.


|
.386p
.xlist
	include MASM.INC
	include 386.INC
	include 8255.INC
	include 8259.INC
	include PTR.INC
	include KEYCALL.INC
	include OPCODES.INC
	include SCANCODE.INC
	include BIOSDATA.INC
	include CPUFLAGS.INC
	include CPUFET.INC
	include BITFLAGS.INC
	include ALLMEM.INC
	include MASM5.MAC
	include MSR.INC
	include IOPBITS.INC
	include MOVSPR.INC
	include DEBUGSYS.INC

	include SWAT_DRV.INC
	include SWAT_COM.INC
	include SWAT_LBR.INC
	include SWAT_SEG.INC
	include SWAT_TSC.INC
.list


RCODE	segment use16 para public 'rcode' ; Start RCODE segment
	assume	cs:RGROUP

	extrn	RM_ERM:far

RCODE	ends			; End RCODE segment


DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	public	@SWAT_INT_DATA16
@SWAT_INT_DATA16 label byte	; Mark module start in .MAP file

SWAT_DATA label  dword

	extrn	COMMON:tbyte
	include QMAX_FIL.INC

	extrn	LC4_FLAG:dword
	include SWAT_LC4.INC

	extrn	OLDINT00_FVEC:dword
	extrn	OLDINT01_FVEC:dword
	extrn	OLDINT03_FVEC:dword
	extrn	OLDINT05_FVEC:dword
	extrn	OLDINT06_FVEC:dword
	extrn	OLDINT0A_FVEC:dword
	extrn	OLDINT0B_FVEC:dword
	extrn	OLDINT0C_FVEC:dword
	extrn	OLDINT0D_FVEC:dword
	extrn	OLDINT0E_FVEC:dword

	extrn	CPUFET_FLAG:dword

	public	OLDINT09_FVEC,OLDINT09_ARB
	public	OLDREMINT0B_FVEC,OLDREMINT0B_ARB
	public	OLDREMINT0C_FVEC,OLDREMINT0C_ARB
	public	OLDINT41_FVEC,OLDINT41_ARB
	public	OLDINT67_FVEC,OLDINT67_ARB
	public	OLDINT68_FVEC,OLDINT68_ARB
OLDINT09_FVEC PTR32_STR <>	; Save area for INT 09h handler
OLDREMINT0B_FVEC PTR32_STR <>	; ...		    0Bh
OLDREMINT0C_FVEC PTR32_STR <>	; ...		    0Ch
OLDINT41_FVEC PTR32_STR <>	; ...		    41h
OLDINT67_FVEC PTR32_STR <>	; ...		    67h
OLDINT68_FVEC PTR32_STR <>	; ...		    68h

OLDINT09_ARB db  CPL0_INTR3 or CPL3 ; Save erae for INT 09h access rights byte
OLDREMINT0B_ARB db CPL0_INTR3 or CPL3 ; ...		0Bh
OLDREMINT0C_ARB db CPL0_INTR3 or CPL3 ; ...		0Ch
OLDINT41_ARB db  CPL0_INTR3 or CPL3 ; ...		41h
OLDINT67_ARB db  CPL0_INTR3 or CPL3 ; ...		67h
OLDINT68_ARB db  CPL0_INTR3 or CPL3 ; ...		68h

	DDALIGN SWAT_DATA	; Ensure aligned on dword boundary

	public	LCLINT09_FVEC
	public	LCLREMINT0B_FVEC,LCLREMINT0C_FVEC
	public	LCLINT41_FVEC
	public	LCLINT67_FVEC
	public	LCLINT68_FVEC
LCLINT09_FVEC label fword	; Save area for INT 09h handler
	dd	offset PGROUP:LCL_INT09,?
LCLREMINT0B_FVEC label fword	; ...		    0Bh
	dd	offset PGROUP:LCL_INT0B2,?
LCLREMINT0C_FVEC label fword	; ...		    0Ch
	dd	offset PGROUP:LCL_INT0C2,?
LCLINT41_FVEC label fword	; ...		    41h
	dd	offset PGROUP:LCL_INT41,?
LCLINT67_FVEC label fword	; ...		    67h
	dd	offset PGROUP:LCL_INT67,?
LCLINT68_FVEC label fword	; ...		    68h
	dd	offset PGROUP:LCL_INT68,?

	public	LCLINT09_ARB
	public	LCLREMINT0B_ARB,LCLREMINT0C_ARB
	public	LCLINT41_ARB
	public	LCLINT67_ARB
	public	LCLINT68_ARB
LCLINT09_ARB db  CPL0_INTR3 or CPL3 ; Save area for INT 09h A/R byte
LCLREMINT0B_ARB db CPL0_INTR3 or CPL3 ; ...		0Bh
LCLREMINT0C_ARB db CPL0_INTR3 or CPL3 ; ...		0Ch
LCLINT41_ARB db  CPL0_INTR3 or CPL3 ; ...		41h
LCLINT67_ARB db  CPL0_INTR3 or CPL3 ; ...		67h
LCLINT68_ARB db  CPL0_INTR3 or CPL3 ; ...		68h

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	NEW_TSC:qword
	extrn	OLD_TSC:qword

	public	LCLINTxx
LCLINTxx dd	offset PGROUP:WIN_INT00 ; Offset to INT 00h
	dd	offset PGROUP:WIN_INT01 ; ...		01h
	dd	offset PGROUP:WIN_INT02 ; ...		02h
	dd	offset PGROUP:WIN_INT03 ; ...		03h
	dd	?			; ...		04h
	dd	offset PGROUP:LCL_INT05 ; ...		05h *FIXME*
	dd	offset PGROUP:LCL_INT06 ; ...		06h *FIXME*
	dd	?			; ...		07h
	dd	?			; ...		08h
	dd	offset PGROUP:WIN_INT09 ; ...		09h
	dd	offset PGROUP:LCL_INT0A ; ...		0Ah *FIXME*
	dd	offset PGROUP:LCL_INT0B ; ...		0Bh *FIXME*
	dd	offset PGROUP:LCL_INT0C ; ...		0Ch *FIXME*
	dd	offset PGROUP:LCL_INT0D ; ...		0Dh *FIXME*
	dd	offset PGROUP:LCL_INT0E ; ...		0Eh *FIXME*
	dd	?			; ...		0Fh
	dd	?			; ...		10h
	dd	?			; ...		11h
	dd	?			; ...		12h
	dd	?			; ...		13h
	dd	?			; ...		14h
	dd	?			; ...		15h
	dd	?			; ...		16h
	dd	?			; ...		17h
	dd	?			; ...		18h
	dd	?			; ...		19h
	dd	?			; ...		1Ah
	dd	?			; ...		1Bh
	dd	?			; ...		1Ch
	dd	?			; ...		1Dh
	dd	?			; ...		1Eh
	dd	?			; ...		1Fh
	dd	offset PGROUP:WIN_INT41 ; ...		41h

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP,ds:PGROUP

	public	@SWAT_INT_PROG
@SWAT_INT_PROG: 		; Mark module start in .MAP file

	extrn	SWATINI:tbyte
	include MAXDEV.INC

	extrn	DEVLOAD:byte
	extrn	LCL_INT41:far
	extrn	WIN_INT41:far
	extrn	LCL_INT67:far
	extrn	LCL_INT68:far
	extrn	SAVEMSG:far
	extrn	SWATTER:far
	extrn	ENABLE8255:near
	extrn	ENABLE_NMI:near
	extrn	DISABLE_NMI:near
	extrn	GETLBASE:near
	extrn	U32_DRAINPIQ:near

	extrn	SEL2BASE:near
	extrn	CHECK_GPS:near

	extrn	LCL_INT0B2:far
	extrn	LCL_INT0C2:far

	extrn	SET_LBR:near
	extrn	Phys2LinBias:dword

	public	INT00_MSG1,INT02_MSG1,INT05_MSG1,INT06_MSG1,INT0A_MSG1
	public	INT0B_MSG1,INT0C_MSG1,INT0D_MSG1,INT0E_MSG1
INT00_MSG1 db	 'Divide Overflow',0
INT02_MSG1 db	 'NMI Interrupt',0
INT05_MSG1 db	 'BOUND Interrupt',0
INT06_MSG1 db	 'Invalid Opcode',0
INT0A_MSG1 db	 'TSS Fault',0
INT0B_MSG1 db	 'Segment Not Present Fault',0
INT0C_MSG1 db	 'Stack Fault',0
INT0D_MSG1 db	 'GP Fault',0
INT0E_MSG1 db	 'Page Fault',0

	public	LCL_INT01_TAB
LCL_INT01_TAB label dword
	dd	offset PGROUP:LCL_INT01_DR0_READ ; Action to read DR0
	dd	offset PGROUP:LCL_INT01_DR1_READ ; ...		    1
	dd	offset PGROUP:LCL_INT01_DR2_READ ; ...		    2
	dd	offset PGROUP:LCL_INT01_DR3_READ ; ...		    3
	dd	offset PGROUP:LCL_INT01_DR4_READ ; ...		    4
	dd	offset PGROUP:LCL_INT01_DR5_READ ; ...		    5
	dd	offset PGROUP:LCL_INT01_DR6_READ ; ...		    6
	dd	offset PGROUP:LCL_INT01_DR7_READ ; ...		    7

	NPPROC	LCL_INTCOM_DEVORIG -- Return To Original Device Driver Handler
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return To Original Device Driver Handler

|

DEVORIG_STR struc

	dd	?		; Caller's EBP
	dw	?		; ...	   DS
	dd	?		; ...	   EFL
DEVO_NXT db	(size DEVSTK_STR) dup (?) ; The rest of the stack

DEVORIG_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

; SS:ESP ==>	 DEVORIG_STR

	REGSAVE <eax,ebx,edi,es> ; Save registers

	mov	es,COMMON.FILE_4GB ; Get all memory selector
	assume	es:AGROUP	; Tell the assembler about it

	movzx	edi,[ebp].DEVO_NXT.DEVSTK_SS ; Get caller's SS
	shl	edi,4-0 	; Convert from paras to bytes

	sub	[ebp].DEVO_NXT.DEVSTK_ESP.ELO,size IRET_STR ; Make room for
				; IRET frame
	movzx	ebx,[ebp].DEVO_NXT.DEVSTK_ESP.ELO ; Get caller's SP

	mov	eax,[ebp].DEVO_NXT.DEVSTK_ORIG ; Get address of next handler
	xchg	ax,[ebp].DEVO_NXT.DEVSTK_EIP.ELO ; Swap with current IP
	mov	AGROUP:[edi+ebx],ax ; Save on VM stack

	shr	eax,16		; Shift down high-order word (CS)
	xchg	ax,[ebp].DEVO_NXT.DEVSTK_CS ; Swap with current CS
	inc	bx		; Account for saved word, emulate 64KB wrap
	inc	bx
	mov	AGROUP:[edi+ebx],ax ; Save on VM stack

	mov	ax,[ebp].DEVO_NXT.DEVSTK_EFL.ELO ; Get return FL
	inc	bx		; Account for saved word, emulate 64KB wrap
	inc	bx
	mov	AGROUP:[edi+ebx],ax ; Save on VM stack

; Turn off resume, trap, and interrupt flags in VM stack for next handler

	and	[ebp].DEVO_NXT.DEVSTK_EFL,not ((mask $RFHI) or (mask $TF) or (mask $IF)) ; RF=TF=IF=0

	REGREST <es,edi,ebx,eax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

	public	LCL_INTCOM_DEVDONE
LCL_INTCOM_DEVDONE:
	FIJMP32 RGROUP:RM_ERM,DTE_CS ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INTCOM_DEVORIG endp 	; End LCL_INTCOM_DEVORIG procedure

PRE_INT00_MAC macro PRE

	pushfd			; Save EFL
	PUSHW	ds		; Save for a moment

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	MASK_STKREG	; Mask off the high-order word of stack
				; registers if 16-bit stack
	push	esi		; Save for a moment

	mov	ds,COMMON.FILE_4GB ; Get all memory selector
	assume	ds:AGROUP	; Tell the assembler about it

	movzx	esi,[ebp].&PRE&00STK_CS ; Get caller's CS
	shl	esi,4-0 	; Convert from paras to bytes
	add	esi,[ebp].&PRE&00STK_EIP ; DS:ESI ==> caller's next instruction

	cmp	esi,2		; Izit too small?
	jb	short @F	; Jump if so (note ZF=0)

	cmp	AGROUP:[esi-2].ELO,00CDh ; Izit INT 00h?
@@:
	pop	esi		; Restore
	pop	ebp		; Restore
	je	short PRE&_INT00_ORIG ; Jump if so

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

; Note that we can't use "offset PGROUP:";
; instead we *MUST* use "offset cs:" (thanks Microsoft)

	PUSHD	0		; Pass pseudo-error code
	PUSHD	cs		; Segment of error message
	push	dword ptr (offset cs:INT00_MSG1) ; Offset of ...
	FCALLD	SAVEMSG 	; Call message save routine

	endm			; PRE_INT00_MAC

	FPPROC	WIN_INT00 -- Divide Overflow Interrupt Handler, Windows
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Divide overflow interrupt (00h) with no error code on the stack.

If we're in VM 8086 mode and the two bytes preceding the caller
are CD 00, continue with INTPROC0.  Otherwise, call SWAT.

Called from SWATVXD.

On exit:

CF	=	0 if we handled the interrupt
	=	1 if not

|

WIN00STK_STR struc

	     dd ?		; Caller's EBP
WIN00STK_DS  dw ?		; ...	   DS
	     dd ?		; ...	   EFLAGS (IF=TF=0)
	     dq ?		; Intermediate far return address
WIN00STK_EIP dd ?		; Caller's EIP
WIN00STK_CS  dw ?,?		; ...	   CS with fill
WIN00STK_EFL dd ?		; ...	   EFLAGS

WIN00STK_STR ends

	PRE_INT00_MAC WIN

	FCALLD	SWATTER 	; Call our debugger

	clc			; Indicate we handled it

	retf			; Return to caller

WIN_INT00_ORIG:
	stc			; Indicate we didn't handle it

	retf			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WIN_INT00 endp			; End LCL_INT00 procedure
	FPPROC	LCL_INT00 -- Divide Overflow Interrupt Handler, Interrupt
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Divide overflow interrupt (00h) with no error code on the stack.

If we're in VM 8086 mode and the two bytes preceding the caller
are CD 00, continue with INTPROC0.  Otherwise, call SWAT.

|

LCL00STK_STR struc

	     dd ?		; Caller's EBP
LCL00STK_DS  dw ?		; ...	   DS
	     dd ?		; ...	   EFLAGS (IF=TF=0)
LCL00STK_EIP dd ?		; ...	   EIP
LCL00STK_CS  dw ?,?		; ...	   CS with fill
LCL00STK_EFL dd ?		; ...	   EFLAGS

LCL00STK_STR ends

	PRE_INT00_MAC LCL

	sub	esp,size FORW_RET2 ; Make room for pseudo-return address
	FCALLD	SWATTER 	; Call our debugger
	lea	esp,[esp+(size FORW_RET2)] ; Strip from the stack

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short @F	; Jump if so

	test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	jz	short @F	; Jump if not

	test	DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	jnz	near ptr LCL_INTCOM_DEVDONE ; Jump if so
@@:
	iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_INT00 ; In case we're returning from a TSS

	assume	ds:AGROUP	; Tell the assembler about it

LCL_INT00_ORIG:
	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short @F	; Jump if so

	test	[esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	jz	short @F	; Jump if not

	test	DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	jnz	near ptr LCL_INTCOM_DEVORIG ; Jump if so
@@:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	push	OLDINT00_FVEC.FSEL ; Pass old selector
	push	OLDINT00_FVEC.FOFF ; Pass old offset

LCL00_STR struc

LCL00_FOFF dd	?		; Old offset
LCL00_FSEL dw	?		; ... selector
LCL00_DS   dw	?		; ... DS
LCL00_EFL  dd	?		; ... EFL (IF=TF=0)

LCL00_STR ends

	mov	ds,[esp].LCL00_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_INT00 ; In case we're returning from a TSS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT00 endp			; End LCL_INT00 procedure

PRE_INT03_MAC macro PRE

	pushad			; Save all EGP registers
	mov	ebp,esp 	; Hello, Mr. Stack

	push	ds		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	MASK_STKREG	; Mask off the high-order word of stack
				; registers if 16-bit stack
; If we're to trap INT 03h in PL0 only, test for that

	test	LC4_FLAG,@LC4_INTPL0 ; Trapping PL0 only?
	jz	short @F	; Jump if not

	test	[ebp].&PRE&03STK_EFL.EHI,mask $VM ; Izit from V86 mode?
	jnz	short @F	; Jump if so (not PL0)

	test	[ebp].&PRE&03STK_CS,mask $PL ; Izit PL0?
	jnz	short PRE&_INT03_SKIP ; Jump if not (note CF=0)
@@:
	dec	[ebp].&PRE&03STK_EIP ; Backup to the breakpoint instruction
				; Note that if this routine was called via
				; two-byte interrupt (CD 03), we're not backing
				; up far enough
	stc			; Mark as not skipping
PRE&_INT03_SKIP:
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it
	popad			; ...
	jc	near ptr PRE&_INT01_COMMON ; Jump if not skipping

	endm			; PRE_INT03_MAC

	FPPROC	WIN_INT03 -- Breakpoint Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Breakpoint interrupt handler.

Called from SWATVXD.

|

WIN03STK_STR struc

WIN03STK_EGP db (type PUSHAD_STR) dup (?) ; Caller's EGP registers
	     dq ?		; Intermediate far return address
WIN03STK_EIP dd  ?		; Caller's EIP
WIN03STK_CS  dw  ?,?		;	   CS with fill
WIN03STK_EFL dd  ?		;	   EFLAGS

WIN03STK_STR ends

	PRE_INT03_MAC WIN

	stc			; Indicate we didn't handle it

	retf			; Return to caller

WIN_INT03_COMMON:
	FCALLD	SWATTER 	; Call our debugger

	clc			; Indicate we handled it

	retf			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WIN_INT03 endp			; End WIN_INT03 procedure
	FPPROC	LCL_INT03 -- Breakpoint Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Breakpoint interrupt handler.

|

LCL03STK_STR struc

LCL03STK_EGP db (type PUSHAD_STR) dup (?) ; Caller's EGP registers
LCL03STK_EIP dd  ?		; Caller's EIP
LCL03STK_CS  dw  ?,?		;	   CS with fill
LCL03STK_EFL dd  ?		;	   EFLAGS

LCL03STK_STR ends

	PRE_INT03_MAC LCL

	pushfd			; Save flags
	PUSHW	ds		; Save register

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	push	OLDINT03_FVEC.FSEL ; Pass selector
	push	OLDINT03_FVEC.FOFF ; ...  offset

LCL03_STR struc

LCL03_FOFF dd	?		; Old offset
LCL03_FSEL dw	?		; ... selector
LCL03_DS   dw	?		; ... DS
LCL03_EFL  dd	?		; ... EFL (IF=TF=0)

LCL03_STR ends

	mov	ds,[esp].LCL03_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT03 endp			; End LCL_INT03 procedure

PRE_INT01_MAC macro PRE

	pushad			; Save all EGP registers
	mov	ebp,esp 	; Hello, Mr. Stack

	push	ds		; Save segment register

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	GET_TSC NEW		; Get current Time Stamp Counter

	call	MASK_STKREG	; Mask off the high-order word of stack
				; registers if 16-bit stack
; If we're to trap INT 01h in PL0 only, test for that

	test	LC4_FLAG,@LC4_INTPL0 ; Trapping PL0 only?
	jz	short @F	; Jump if not

	test	[ebp].&PRE&01STK_EFL.EHI,mask $VM ; Izit from V86 mode?
	jnz	short @F	; Jump if so (not PL0)

	test	[ebp].&PRE&01STK_CS,mask $PL ; Izit PL0?
	jz	near ptr LCL_INT01_ORIG ; Jump if so (note CF=0)
@@:

; If this event is from within SWAT, continue processing

	test	[ebp].&PRE&01STK_EFL.EHI,mask $VM ; Izit from V86 mode?
	jnz	short @F	; Jump if so (not within SWAT)

	mov	ax,cs		; Get our code selector
	cmp	ax,[ebp].&PRE&01STK_CS ; Izit the same as the caller's CS?
	je	near ptr PRE&_INT01_XGD ; Jump if so (note CF=0)
@@:
	public	PRE&_INT01_DR6
PRE&_INT01_DR6:
	mov	eax,dr6 	; Get the debug status register

	btr	eax,$BD 	; Izit from a debug register reference/set?
	jnc	near ptr PRE&_INT01_XGD ; Jump if not (note CF=0)

	mov	dr6,eax 	; Clear the bit

; Interpret the instruction at CS|EIP to see if it's a
; reference or set as well as how long it is so we can skip over it

	movzx	esi,[ebp].&PRE&01STK_CS ; Get the caller's CS

	test	[ebp].&PRE&01STK_EFL.EHI,mask $VM ; Izit from V86 mode?
	jz	short @F	; Jump if not

	shl	esi,4-0 	; Convert from paras to bytes
	add	esi,[ebp].&PRE&01STK_EIP ; Plus the offset

	mov	ds,COMMON.FILE_4GB ; Get all memory selector
	assume	ds:nothing     ; Tell the assembler about it

	jmp	short PRE&_INT01_GDCOM ; Join common code

@@:

; Note that the following code won't work if the code selector
; is execute-only (I've never seen that, though).

	mov	ds,si		; Address it
	assume	ds:nothing     ; Tell the assembler about it

	mov	esi,[ebp].&PRE&01STK_EIP ; Get the offset
PRE&_INT01_GDCOM:

; DS:ESI ==> caller's CS:EIP

	cld			; String ops forwardly
	xor	ecx,ecx 	; Initialize instruction byte count
@@:
	lods	ds:[esi].LO	; Get the instruction byte
	inc	ecx		; Count in another

	cmp	al,@OPCOD_OSP	; Izit OSP?
	je	short @B	; Jump if so (ignore it)

	mov	ah,al		; Copy the first byte
	lods	ds:[esi].LO	; Get the instruction byte
	inc	ecx		; Count in another
	xchg	al,ah		; Swap to comparison order

	cmp	ax,@OPCOD_MOV_R32_DRn ; Izit a read of DRn?
	je	short PRE&_INT01_GDREAD ; Jump if so

	cmp	ax,@OPCOD_MOV_DRn_R32 ; Izit a write to DRn?
	clc			; Assume not
	jne	short PRE&_INT01_XGD ; Jump if not (ignore it) (note CF=0)

;;;;;;; lods	ds:[esi].LO	; Get the instruction byte
	inc	ecx		; Count in another

	add	[ebp].&PRE&01STK_EIP,ecx ; Skip over the instruction

	jmp	short PRE&_INT01_GD_EXIT ; Join common exit code

PRE&_INT01_GDREAD:
	lods	ds:[esi].LO	; Get the MOD R/M byte
	inc	ecx		; Count in another

	add	[ebp].&PRE&01STK_EIP,ecx ; Skip over the instruction

; Determine which register it is and give it back to them
; The REG bits contain the DRn register #
; The RM  bits contain the r32 register #

	mov	ecx,eax 	; Save the MOD R/M byte
	and	eax,mask $REG	; Isolate the REG bits
	shr	eax,$REG	; Shift to low-order

	call	LCL_INT01_TAB[eax*(type LCL_INT01_TAB)] ; Take appropriate action

	and	ecx,mask $RM	; Isolate the RM bits
	shr	ecx,$RM 	; Shift to low order
	sub	ecx,7		; Subtract
	neg	ecx		; ...from 7 to index PUSHAD struc

	mov	[ebp].&PRE&01STK_EGP[ecx*4].EDD,eax ; Save back
PRE&_INT01_GD_EXIT:

; Set the GD bit again to catch the next read/write

	mov	eax,dr7 	; Get current contents
	or	eax,mask $GD	; Set the bit
	mov	dr7,eax 	; Tell the CPU about it

	stc			; Mark as skipping this instruction
PRE&_INT01_XGD:
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popad			; Restore
	jnc	short PRE&_INT01_COMMON ; Jump if we're continuing

	endm			; PRE_INT01_MAC

LCL_INT01_DR0_READ:
	mov	eax,dr0 	; Get the register

	retn			; Return to caller

LCL_INT01_DR1_READ:
	mov	eax,dr1 	; Get the register

	retn			; Return to caller

LCL_INT01_DR2_READ:
	mov	eax,dr2 	; Get the register

	retn			; Return to caller

LCL_INT01_DR3_READ:
	mov	eax,dr3 	; Get the register

	retn			; Return to caller

LCL_INT01_DR4_READ:
	MOVSPR	eax,dr4 	; Get the register

	retn			; Return to caller

LCL_INT01_DR5_READ:
	MOVSPR	eax,dr5 	; Get the register

	retn			; Return to caller

LCL_INT01_DR6_READ:
	mov	eax,dr6 	; Get the register

	retn			; Return to caller

LCL_INT01_DR7_READ:
	mov	eax,dr7 	; Get the register

	retn			; Return to caller

	FPPROC	WIN_INT01 -- Single-step Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Single-step interrupt handler.

In order to maintain control of the debug registers, we might set the
GD bit in DR7.	In this case, we need to launder references and sets
to any of the DRn registers.  A reference to a debug register is
returned the actual value.  A set is ignored.

If the GD bit is set, and a program references a debug register, SWAT
is entered via a debug exception, and the CPU clears the GD bit thus
allowing further access to the debug registers.

Called from SWATVXD.

|

WIN01STK_STR struc

WIN01STK_EGP db (type PUSHAD_STR) dup (?) ; Caller's EGP registers
	     dq ?		; Intermediate far return address
WIN01STK_EIP dd ?		; ...	   EIP
WIN01STK_CS  dw ?,?		; ...	   CS w/filler
WIN01STK_EFL dd ?		; ...	   EFL

WIN01STK_STR ends

	PRE_INT01_MAC WIN

; Fall through here if we encountered an INT 01h which we're ignoring
; say, because it's a spurious GD bit hit within SWAT

	clc			; Indicate we handle it

	retf			; Skip over the instruction

WIN_INT01_ORIG:
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popad			; Restore

	stc			; Indicate we didn't handle it

	retf			; Return to caller

WIN_INT01_COMMON:
	FCALLD	SWATTER 	; Call our debugger

	public	WIN1_RETURN
WIN1_RETURN:
	clc			; Indicate we handled it

	retf			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WIN_INT01 endp			; End WIN_INT01 procedure
	FPPROC	LCL_INT01 -- Single-step Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Single-step interrupt handler.

In order to maintain control of the debug registers, we might set the
GD bit in DR7.	In this case, we need to launder references and sets
to any of the DRn registers.  A reference to a debug register is
returned the actual value.  A set is ignored.

If the GD bit is set, and a program references a debug register, SWAT
is entered via a debug exception, and the CPU clears the GD bit thus
allowing further access to the debug registers.

|

LCL01STK_STR struc

LCL01STK_EGP db (type PUSHAD_STR) dup (?) ; Caller's EGP registers
LCL01STK_EIP dd ?		; ...	   EIP
LCL01STK_CS  dw ?,?		; ...	   CS w/filler
LCL01STK_EFL dd ?		; ...	   EFL

LCL01STK_STR ends

	PRE_INT01_MAC LCL

	iretd			; Skip over the instruction

LCL_INT01_ORIG:
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popad			; Restore

	pushfd			; Save flags
	PUSHW	ds		; Save register

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	push	OLDINT01_FVEC.FSEL ; Pass selector
	push	OLDINT01_FVEC.FOFF ; ...  offset

LCL01_STR struc

LCL01_FOFF dd	?		; Old offset
LCL01_FSEL dw	?		; ... selector
LCL01_DS   dw	?		; ... DS
LCL01_EFL  dd	?		; ... EFL (IF=TF=0)

LCL01_STR ends

	mov	ds,[esp].LCL01_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

LCL_INT01_COMMON:
	sub	esp,size FORW_RET2 ; Make room for pseudo-return address
	FCALLD	SWATTER 	; Call our debugger

	public	LCL1_RETURN
LCL1_RETURN:
	lea	esp,[esp+(size FORW_RET2)] ; Strip from the stack

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short @F	; Jump if so

	test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	jz	short @F	; Jump if not

	test	DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	jnz	near ptr LCL_INTCOM_DEVDONE ; Jump if so
@@:
	iretd			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT01 endp			; End LCL_INT01 procedure

PRE_INT02_MAC macro PRE

	pushfd			; Save EFL
	PUSHW	ds		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	MASK_STKREG	; Mask off the high-order word of stack
				; registers if 16-bit stack
	call	DISABLE_NMI	; Disable NMI until the end
	jc	short PRE&_INT02_ORIG ; Jump if NMI handler already active
;;;
;;;	     REGSAVE <eax,ebx,ds>   ; Save for a moment
;;;
;;; @PIC0    equ     08h	    ; Master PIC base
;;; @PIC1    equ     70h	    ; Slave ...
;;;
;;;	     test    DBG_FLAG,@DBG_NMIPIC ; Izit specified?
;;;	     jz      short LCL_INT02_XPIC ; Jump if not
;;;
;;;	     call    REPROG_PIC     ; Reprogram the PIC for a specific INT base
;;;
;;;	     mov     ds,COMMON.FILE_4GB ; Get our all memory selector
;;;	     assume  ds:PGROUP	    ; Tell the assembler about it (note lie)
;;;
;;;	     PUSHW   cs 	    ; Pass selector as argument
;;;	     call    GETBASE	    ; Return with EAX = selector base
;;;
;;;	     mov     ebx,@PIC0	    ; Get new value
;;;	     xchg    bl,SWATINI.MD_IBV0[eax] ; Set master IMR base vector (IRQ0)
;;;	     mov     cr2,ebx	    ; Save for later use
;;; LCL_INT02_XPIC:
;;;	     REGREST <ds,ebx,eax>   ; Restore
;;;	     assume  ds:nothing     ; Tell the assembler about it

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

; Note that we can't use "offset PGROUP:";
; instead we *MUST* use "offset cs:" (thanks Microsoft)

	PUSHD	0		; Pass pseudo-error code
	PUSHD	cs		; Segment of error message
	push	dword ptr (offset cs:INT02_MSG1) ; Offset of ...
	FCALLD	SAVEMSG 	; Call message save routine

	endm			; PRE_INT02_MAC

	FPPROC	WIN_INT02 -- NMI Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

NMI interrupt handler.

Called from SWATVXD.

|

	PRE_INT02_MAC WIN

	FCALLD	SWATTER 	; Call our debugger

	cli			; Disallow interrupts
	call	ENABLE_NMI	; Enable NMI, clear the parity latches

	retf			; Return to caller

WIN_INT02_ORIG:

; At this point, only EFL and DS are extra on the stack

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

	stc			; Indicate we didn't handled it

	retf			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WIN_INT02 endp			; End WIN_INT02 procedure
	FPPROC	LCL_INT02 -- NMI Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

NMI interrupt handler.

|

	PRE_INT02_MAC LCL

	sub	esp,size FORW_RET2 ; Make room for pseudo-return address
	FCALLD	SWATTER 	; Call our debugger
	lea	esp,[esp+(size FORW_RET2)] ; Strip from the stack

	cli			; Disallow interrupts
	call	ENABLE_NMI	; Enable NMI, clear the parity latches

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short @F	; Jump if so

	test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	jz	short @F	; Jump if not

	test	DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	jnz	near ptr LCL_INTCOM_DEVDONE ; Jump if so
@@:
	iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_INT02 ; In case we're returning from a TSS

LCL_INT02_ORIG:
	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short @F	; Jump if so

	test	[esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	jz	short @F	; Jump if not

	test	DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	jnz	near ptr LCL_INTCOM_DEVORIG ; Jump if so
@@:

; At this point, only EFL and DS are extra on the stack

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

	iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_INT02 ; In case we're returning from a TSS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT02 endp			; End LCL_INT02 procedure
	FPPROC	LCL_INT05 -- BOUND Instruction Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BOUND instruction interrupt (05h) with no error code on the stack.

If we're in VM 8086 mode and the two bytes preceding the caller
are CD 05, continue with INTPROC5.  Otherwise, call SWAT.

|

INT05STK_STR struc

	     dd ?		; Caller's EBP
INT05STK_DS  dw ?		; ...	   DS
	     dd ?		; ...	   EFLAGS (IF=TF=0)
INT05STK_EIP dd ?		; ...	   EIP
INT05STK_CS  dw ?,?		; ...	   CS with fill
INT05STK_EFL dd ?		; ...	   EFLAGS

INT05STK_STR ends

	pushfd			; Save EFL
	PUSHW	ds		; Save for a moment

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	push	esi		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	MASK_STKREG	; Mask off the high-order word of stack
				; registers if 16-bit stack
	mov	ds,COMMON.FILE_4GB ; Get all memory selector
	assume	ds:AGROUP	; Tell the assembler about it

	movzx	esi,[ebp].INT05STK_CS ; Get caller's CS
	shl	esi,4-0 	; Convert from paras to bytes
	add	esi,[ebp].INT05STK_EIP ; DS:ESI ==> caller's next instruction

	cmp	esi,2		; Izit too small?
	jb	short @F	; Jump if so (note ZF=0)

	cmp	AGROUP:[esi-2].ELO,05CDh ; Izit INT 05h?
@@:
	pop	esi		; Restore
	pop	ebp		; Restore
	je	short LCL_INT05_ORIG ; Jump if so

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

; Note that we can't use "offset PGROUP:";
; instead we *MUST* use "offset cs:" (thanks Microsoft)

	PUSHD	0		; Pass pseudo-error code
	PUSHD	cs		; Segment of error message
	push	dword ptr (offset cs:INT05_MSG1) ; Offset of ...
	FCALLD	SAVEMSG 	; Call message save routine

	FCALLD	SWATTER 	; Call our debugger

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short @F	; Jump if so

	test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	jz	short @F	; Jump if not

	test	DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	jnz	near ptr LCL_INTCOM_DEVDONE ; Jump if so
@@:
	iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_INT05 ; In case we're returning from a TSS

	assume	ds:nothing	; Tell the assembler about it

LCL_INT05_ORIG:
	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short @F	; Jump if so

	test	[esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	jz	short @F	; Jump if not

	test	DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	jnz	near ptr LCL_INTCOM_DEVORIG ; Jump if so
@@:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	push	OLDINT05_FVEC.FSEL ; Pass old selector
	push	OLDINT05_FVEC.FOFF ; Pass old offset

INT05_STR struc

INT05_FOFF dd	?		; Old offset
INT05_FSEL dw	?		; ... selector
INT05_DS   dw	?		; ... DS
INT05_EFL  dd	?		; ... EFL (IF=TF=0)

INT05_STR ends

	mov	ds,[esp].INT05_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_INT05 ; In case we're returning from a TSS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT05 endp			; End LCL_INT05 procedure
	FPPROC	LCL_INT06 -- Invalid Opcode Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Invalid Opcode interrupt handler.

|

INT06STK_STR struc

	     dd ?		; Caller's EBP
INT06STK_DS  dw ?		; ...	   DS
	     dd ?		; ...	   EFLAGS (IF=TF=0)
INT06STK_EIP dd ?		; ...	   EIP
INT06STK_CS  dw ?,?		; ...	   CS with fill
INT06STK_EFL dd ?		; ...	   EFLAGS

INT06STK_STR ends

; If we're inside Windows and this comes from VM,
; and it's an ARPL, let Windows handle it

; If we're inside Windows and this comes from PM,
; and it's a 0F FF, let Windows handle it

	pushfd			; Save EFL
	PUSHW	ds		; Save for a moment

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	push	eax		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	MASK_STKREG	; Mask off the high-order word of stack
				; registers if 16-bit stack
	mov	ds,COMMON.FILE_4GB ; Get all memory selector
	assume	ds:AGROUP	; Tell the assembler about it

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jz	short LCL_INT06_XWIN ; Jump if not

	test	[ebp].INT06STK_EFL.EHI,mask $VM ; Izit VM86 mode?
	jz	short LCL_INT06_PM ; Jump if not

	movzx	eax,[ebp].INT06STK_CS ; Get caller's CS
	shl	eax,4-0 	; Convert from paras to bytes
	add	eax,[ebp].INT06STK_EIP ; DS:EAX ==> caller's next instruction

	cmp	AGROUP:[eax].ELO.LO,@OPCOD_ARPL ; Izit an ARPL?
	je	near ptr LCL_INT06_ORIG ; Jump if it is

	jmp	short LCL_INT06_XWIN ; Join common code

LCL_INT06_PM:
	push	[ebp].INT06STK_CS ; Get caller's CS
	call	GETLBASE	; Return with EAX = selector base

	add	eax,[ebp].INT06STK_EIP ; DS:ESI ==> caller's next instruction

	cmp	AGROUP:[eax].ELO,0FF0Fh ; Izit 0F FF?
	je	short LCL_INT06_ORIG ; Jump if it is
LCL_INT06_XWIN:

; If this comes from VM, and it's BSWAP, let the VM handler handle it

	test	[ebp].INT06STK_EFL.EHI,mask $VM ; Izit VM86 mode?
	jz	short LCL_INT06_XVM ; Jump if not

	movzx	eax,[ebp].INT06STK_CS ; Get caller's CS
	shl	eax,4-0 	; Convert from paras to bytes
	add	eax,[ebp].INT06STK_EIP ; DS:EAX ==> caller's next instruction

	cmp	AGROUP:[eax].LO,@OPCOD_OSP ; Izit 32-bit form of BSWAP?
	jne	short @F	; Jump if not

	inc	eax		; Skip over it
@@:
	cmp	AGROUP:[eax].ELO,@OPCOD_BSWAPLO ; Izit a BSWAP?
	jb	short LCL_INT06_XVM ; Jump if not

	cmp	AGROUP:[eax].ELO,@OPCOD_BSWAPHI ; Izit a BSWAP?
	jbe	short LCL_INT06_ORIG ; Jump if so
LCL_INT06_XVM:
	pop	eax		; Restore
	pop	ebp		; Restore

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

; Note that we can't use "offset PGROUP:";
; instead we *MUST* use "offset cs:" (thanks Microsoft)

	PUSHD	0		; Pass pseudo-error code
	PUSHD	cs		; Segment of error message
	push	dword ptr (offset cs:INT06_MSG1) ; Offset of ...
	FCALLD	SAVEMSG 	; Call message save routine

	FCALLD	SWATTER 	; Call our debugger

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short @F	; Jump if so

	test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	jz	short @F	; Jump if not

	test	DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	jnz	near ptr LCL_INTCOM_DEVDONE ; Jump if so
@@:
	iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_INT06 ; In case we're returning from a TSS

LCL_INT06_ORIG:
	pop	eax		; Restore
	pop	ebp		; Restore

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short @F	; Jump if so

	test	[esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	jz	short @F	; Jump if not

	test	DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	jnz	near ptr LCL_INTCOM_DEVORIG ; Jump if so
@@:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	push	OLDINT06_FVEC.FSEL ; Pass old selector
	push	OLDINT06_FVEC.FOFF ; Pass old offset

INT06_STR struc

INT06_FOFF dd	?		; Old offset
INT06_FSEL dw	?		; ... selector
INT06_DS   dw	?		; ... DS
INT06_EFL  dd	?		; ... EFL (IF=TF=0)

INT06_STR ends

	mov	ds,[esp].INT06_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_INT06 ; In case we're returning from a TSS

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT06 endp			; End LCL_INT06 procedure

PRE_INT09_MAC macro PRE

	pushfd			; Save EFL
	PUSHW	ds		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	MASK_STKREG	; Mask off the high-order word of stack
				; registers if 16-bit stack
	push	eax		; Save for a moment

; Ensure shift states are Ctrl- and Alt-

	call	GETSHIFT	; Return with shift states in AL
	jc	short PRE&_INT09_ORIG ; Jump if something went wrong

	and	al,(mask $DALT) or (mask $DCTL) ; Isolate just these two

	cmp	al,(mask $DALT) or (mask $DCTL) ; Ctrl and Alt pressed?
	jne	short PRE&_INT09_ORIG ; Jump if something else pressed

; Read in the scan code to check for the PAD5 or SYSREQ keys

	in	al,@8255_A	; Read in the scan code
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	cmp	al,@SSC_PAD5	; Check for PAD5 key
	je	short @F	; Jump if so

	cmp	al,@SSC_SYSREQ	; Check for SysReq key
	jne	short PRE&_INT09_ORIG ; Not this time
@@:
	test	SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
	jz	short @F	; Not this time

	call	ENABLE8255	; Enable XT keyboard
@@:
	mov	al,@EOI 	; Send an EOI
	out	@ICR,al 	; Tell the 8259 about it
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	pop	eax		; Restore

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

	endm			; PRE_INT09_MAC

	FPPROC	WIN_INT09 -- Hardware Keyboard Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Hardware keyboard interrupt handler

|

	PRE_INT09_MAC WIN

	FCALLD	SWATTER 	; Call our debugger

	jmp	WIN1_RETURN	; Join common code

	assume	ds:DGROUP	; Tell the assembler about it
WIN_INT09_ORIG:
	pop	eax		; Restore

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

	stc			; Indicate we didn't handle it

	retf			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WIN_INT09 endp			; End WIN_INT09 procedure
	FPPROC	LCL_INT09 -- Hardware Keyboard Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Hardware keyboard interrupt handler

|

	PRE_INT09_MAC LCL

	sub	esp,size FORW_RET2 ; Make room for pseudo-return address
	FCALLD	SWATTER 	; Call our debugger
;;;;;;; lea	esp,[esp+(size FORW_RET2)] ; Strip from the stack

	jmp	LCL1_RETURN	; Join common code

	assume	ds:DGROUP	; Tell the assembler about it
LCL_INT09_ORIG:
	pop	eax		; Restore

	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short @F	; Jump if so

	test	[esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	jz	short @F	; Jump if not

	test	DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	jnz	near ptr LCL_INTCOM_DEVORIG ; Jump if so
@@:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	push	OLDINT09_FVEC.FSEL ; Pass old selector
	push	OLDINT09_FVEC.FOFF ; Pass old offset

INT09_STR struc

INT09_FOFF dd	?		; Old offset
INT09_FSEL dw	?		; ... selector
INT09_DS   dw	?		; ... DS
INT09_EFL  dd	?		; ... EFL (IF=TF=0)

INT09_STR ends

	mov	ds,[esp].INT09_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_INT09 ; In case we're returning from a TSS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT09 endp			; End LCL_INT09 procedure
	NPPROC	GETBDA -- Get The BIOS Data Area Linear Address
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get the linear address of the BIOS data area

On exit:

CF	=	0 if successful
	=	1 if not
EBX	=	linear address of BIOS data area

|

	REGSAVE <eax,ecx,edx,esi,edi,gs> ; Save registers

	SETDATA gs		; Set data selector into DS
	assume	gs:DGROUP	; Tell the assembler about it

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

	xor	ebx,ebx 	; Zero to use as dword
	mov	bx,seg BIOSDATA ; Get segment of BIOS data area
	shl	ebx,4-0 	; Convert from paras to bytes

; If we're in W, ensure that the BIOS data area is mapped in

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	jz	short GETBDA_EXIT ; Jump if not (note CF=0)

	test	SWATINI.MD_ATTR,@MD_WSVC ; Are Win386 services available?
;;;;;;; jz	short GETBDA_ERR ; Jump if not
	jmp	short GETBDA_ERR ; Jump if not *FIXME*

	mov	eax,Win386_GetThreadID ; Function code to get thread ID
	int	Win386_Query_Int ; Request Win386 services
				; Return with AX = thread ID
	mov	edx,ebx 	; Copy linear address
	mov	bx,ax		; Copy thread ID
	mov	eax,Win386_GetPDE ; Function code to get PDE for a thread BX
	int	Win386_Query_Int ; Request Win386 services
				; Return with EAX = 0 if successful
				; ...		 != 0 if not
				; ...	      ECX = PDE
	and	eax,eax 	; Izit successful?
	jnz	short GETBDA_ERR ; Jump if not

	mov	edi,Phys2LinBias ; Get W's physical-to-linear bias
	and	ecx,@PTE_FRM	; Isolate 4KB frame
	add	ecx,edi 	; Plus W's physical-to-linear bias

	mov	eax,edx 	; Copy linear address
	and	eax,mask $LA_PAGE ; Isolate the page index
	shr	eax,$LA_PAGE	; Shift down the page index
	lea	esi,AGROUP:[ecx+eax*4] ; Get address of this PTE

; During bootup, the address [ecx+eax*4] might be invalid
; (meaning that W hasn't filled in all the PTEs as yet),
; so we check on its state before touching it

	mov	ecx,4		; # bytes we need
	mov	eax,Win386_AddrValid ; Function code to check validity of
				; linear address in ESI for CX bytes
	int	Win386_Query_Int ; Request Win386 services
				; Return with AX = 1 if OK, 0 if not
	cmp	ax,1		; Izit valid?
	jc	short GETBDA_ERR ; Jump if not

	mov	ebx,AGROUP:[esi] ; Get address of this PTE

	and	ebx,@PTE_FRM	; Isolate 4KB frame
	add	ebx,edi 	; Plus W's physical-to-linear bias

	and	edx,not @PTE_FRM ; Isolate the offset within 4KB
	add	ebx,edx 	; Plus offset to get linear address

	clc			; Mark as successful

	jmp	short GETBDA_EXIT ; Join common exit code

GETBDA_ERR:
	stc			; Mark as in error
GETBDA_EXIT:
	REGREST <gs,edi,esi,edx,ecx,eax> ; Restore
	assume	gs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETBDA	endp			; End GETBDA procedure
	 NPPROC  GETSHIFT -- Get Keyboard Shift States
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get keyboard shift states

On exit:

CF	=	0 if successful
	=	1 if not
AL	 =	 keyboard Ctrl-, Alt-, and L&R-shift states
ZF	 =	 1 if all states off
	 =	 0 otherwise

|

	 REGSAVE <ebx,ds>	; Save for a moment

	call	GETBDA		; Return with EBX=linear address of BIOS data area
	jc	short GETSHIFT_ERR ; Jump if something went wrong

	 mov	 ds,COMMON.FILE_4GB ; Address it
	 assume  ds:BIOSDATA	; Tell the assembler about it

	 mov	 al,KB_FLAG[ebx] ; Get keyboard flags

; Isolate Ctrl, Alt, and L&R Shift states

	 and	 al,(mask $DALT) or (mask $DCTL) or (mask $DLSH) or (mask $DRSH)
				; Return with ZF significant
				; and CF=0
GETSHIFT_ERR:
	 REGREST <ds,ebx>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETSHIFT endp			; End GETSHIFT procedure
	 NPPROC  IZIT_IRQ2 -- Is IRQ2 Active?
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if we're called with IRQ2 in-service

On exit:

ZF	 =	 1 if so
	 =	 0 if not

|

	 push	 eax		; Save for a moment

	 mov	 al,@GETISR	; Code to read ISR
	 out	 @ICR,al	; Tell the 8259 about it
	 call	 U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	 in	 al,@ICR	; Read the ISR
;;;;;;;; call	 U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	 test	 al,mask $IRQ2	; Izit in service?
	 pop	 eax		; Restore
				; Return with ZF=1 iff so
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_IRQ2 endp			; End IZIT_IRQ2 procedure
	 NPPROC  IZIT_IRQ3 -- Is IRQ3 Active?
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if we're called with IRQ3 in-service

On exit:

ZF	 =	 1 if so
	 =	 0 if not

|

	 push	 eax		; Save for a moment

	 mov	 al,@GETISR	; Code to read ISR
	 out	 @ICR,al	; Tell the 8259 about it
	 call	 U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	 in	 al,@ICR	; Read the ISR
;;;;;;;; call	 U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	 test	 al,mask $IRQ3	; Izit in service?
	 pop	 eax		; Restore
				; Return with ZF=1 iff so
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_IRQ3 endp			; End IZIT_IRQ3 procedure
	 NPPROC  IZIT_IRQ4 -- Is IRQ4 Active?
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if we're called with IRQ4 in-service

On exit:

ZF	 =	 1 if so
	 =	 0 if not

|

	 push	 eax		; Save for a moment

	 mov	 al,@GETISR	; Code to read ISR
	 out	 @ICR,al	; Tell the 8259 about it
	 call	 U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	 in	 al,@ICR	; Read the ISR
;;;;;;;; call	 U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	 test	 al,mask $IRQ4	; Izit in service?
	 pop	 eax		; Restore
				; Return with ZF=1 iff so
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_IRQ4 endp			; End IZIT_IRQ4 procedure
	 NPPROC  IZIT_IRQ5 -- Is IRQ5 Active?
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if we're called with IRQ5 in-service

On exit:

ZF	 =	 1 if so
	 =	 0 if not

|

	 push	 eax		; Save for a moment

	 mov	 al,@GETISR	; Code to read ISR
	 out	 @ICR,al	; Tell the 8259 about it
	 call	 U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	 in	 al,@ICR	; Read the ISR
;;;;;;;; call	 U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	 test	 al,mask $IRQ5	; Izit in service?
	 pop	 eax		; Restore
				; Return with ZF=1 iff so
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_IRQ5 endp			; End IZIT_IRQ5 procedure
	NPPROC	IZIT_IRQ6 -- Is IRQ6 Active?
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if we're called with IRQ6 in-service

On exit:

ZF	=	1 if so
	=	0 if not

|

	push	eax		; Save for a moment

	mov	al,@GETISR	; Code to read ISR
	out	@ICR,al 	; Tell the 8259 about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	in	al,@ICR 	; Read the ISR
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	test	al,mask $IRQ6	; Izit in service?
	pop	eax		; Restore
				; Return with ZF=1 iff so
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_IRQ6 endp			; End IZIT_IRQ6 procedure
	 FPPROC  LCL_INT0A -- Invalid TSS Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Invalid TSS interrupt handler.

|

	 pushfd 		; Save EFL
	PUSHW	ds		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	MASK_STKREG	; Mask off the high-order word of stack
				; registers if 16-bit stack
; Check for IRQ2 instead of a fault

	 call	 IZIT_IRQ2	; Izit IRQ2?
	 jnz	 short LCL_INT0A_ORIG ; Jump if so

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	 popfd			; Restore

; Note that we can't use "offset PGROUP:";
; instead we *MUST* use "offset cs:" (thanks Microsoft)

;;;;;;;; push	 eax		; Pass error code (already on the stack)
	 PUSHD	 cs		; Segment of error message
	 push	 dword ptr (offset cs:INT0A_MSG1) ; Offset of ...
	 FCALLD  SAVEMSG	; Call message save routine

	 FCALLD  SWATTER	; Call our debugger

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short @F	; Jump if so

	 test	 [esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	 jz	 short @F	; Jump if not

	 test	 DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	 jnz	 near ptr LCL_INTCOM_DEVDONE ; Jump if so
@@:
	 iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	 jmp	 near ptr LCL_INT0A ; In case we're returning from a TSS

	 assume  ds:DGROUP	; Tell the assembler about it
LCL_INT0A_ORIG:
	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short @F	; Jump if so

	 test	 [esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	 jz	 short @F	; Jump if not

	 test	 DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	 jnz	 near ptr LCL_INTCOM_DEVORIG ; Jump if so
@@:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	 push	 OLDINT0A_FVEC.FSEL ; Pass old selector
	 push	 OLDINT0A_FVEC.FOFF ; Pass old offset

INT0AX_STR struc

INT0AX_FOFF dd	 ?		; Old offset
INT0AX_FSEL dw	 ?		; ... selector
INT0AX_DS   dw	 ?		; ... DS
INT0AX_EFL  dd	 ?		; ... EFL (IF=TF=0)

INT0AX_STR ends

	 mov	 ds,[esp].INT0AX_DS ; Restore DS
	 assume  ds:nothing	; Tell the assembler about it

	 iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	 jmp	 near ptr LCL_INT0A ; In case we're returning from a TSS

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT0A endp			; End LCL_INT0A procedure
	 FPPROC  LCL_INT0B -- Segment Not Present Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Segment Not Present interrupt handler.

|

	 pushfd 		; Save EFL
	 PUSHW	 ds		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	MASK_STKREG	; Mask off the high-order word of stack
				; registers if 16-bit stack
; Check for IRQ3 instead of a fault

	 call	 IZIT_IRQ3	; Izit IRQ3?
	 jnz	 short LCL_INT0B_ORIG ; Jump if so

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	 popfd			; Restore

	 test	 [esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	 jz	 short @F	; Jump if not

	 test	 DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	 jz	 short @F	; Jump if not

	 PUSHD	 0		; Pass pseudo-error code
@@:

; Note that we can't use "offset PGROUP:";
; instead we *MUST* use "offset cs:" (thanks Microsoft)

;;;;;;;; push	 eax		; Pass error code (already on the stack)
	 PUSHD	 cs		; Segment of error message
	 push	 dword ptr (offset cs:INT0B_MSG1) ; Offset of ...
	 FCALLD  SAVEMSG	; Call message save routine

	 FCALLD  SWATTER	; Call our debugger

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short @F	; Jump if so

	 test	 [esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	 jz	 short @F	; Jump if not

	 test	 DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	 jnz	 near ptr LCL_INTCOM_DEVDONE ; Jump if so
@@:
	 iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	 jmp	 near ptr LCL_INT0B ; In case we're returning from a TSS

	assume	ds:DGROUP	; Tell the assembler about it
LCL_INT0B_ORIG:
	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

; We always go to the previous PM interrupt handler for INT 0Bh
; as remote SWAT is always behind us.

;;;	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;	jnz	short @F	; Jump if so
;;;
;;;	 test	 [esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;	 jz	 short @F	; Jump if not
;;;
;;;	 test	 DEVLOAD,@DEVL_LOAD ; Izit from device driver?
;;;	 jnz	 near ptr LCL_INTCOM_DEVORIG ; Jump if so
;;; @@:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	 push	 OLDINT0B_FVEC.FSEL ; Pass old selector
	 push	 OLDINT0B_FVEC.FOFF ; Pass old offset

INT0BX_STR struc

INT0BX_FOFF dd	  ?		 ; Old offset
INT0BX_FSEL dw	  ?		 ; ... selector
INT0BX_DS   dw	  ?		 ; ... DS
INT0BX_EFL  dd	  ?		 ; ... EFL (IF=TF=0)

INT0BX_STR ends

	 mov	 ds,[esp].INT0BX_DS ; Restore DS
	 assume  ds:nothing	; Tell the assembler about it

	 iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	 jmp	 near ptr LCL_INT0B ; In case we're returning from a TSS

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT0B endp			; End LCL_INT0B procedure
	 FPPROC  LCL_INT0C -- Stack Fault Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Stack Fault interrupt handler.

|

	 pushfd 		; Save EFL
	PUSHW	ds		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	MASK_STKREG	; Mask off the high-order word of stack
				; registers if 16-bit stack
; Check for IRQ4 instead of a fault

	 call	 IZIT_IRQ4	; Izit IRQ4?
	 jnz	 short LCL_INT0C_ORIG ; Jump if so

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	 popfd			; Restore

	 test	 [esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	 jz	 short @F	; Jump if not

	 test	 DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	 jz	 short @F	; Jump if not

	 PUSHD	 0		; Pass pseudo-error code
@@:

; Note that we can't use "offset PGROUP:";
; instead we *MUST* use "offset cs:" (thanks Microsoft)

;;;;;;;; push	 eax		; Pass error code (already on the stack)
	 PUSHD	 cs		; Segment of error message
	 push	 dword ptr (offset cs:INT0C_MSG1) ; Offset of ...
	 FCALLD  SAVEMSG	; Call message save routine

	 FCALLD  SWATTER	; Call our debugger

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short @F	; Jump if so

	 test	 [esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	 jz	 short @F	; Jump if not

	 test	 DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	 jnz	 near ptr LCL_INTCOM_DEVDONE ; Jump if so
@@:
	 iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	 jmp	 near ptr LCL_INT0C ; In case we're returning from a TSS

	assume	ds:DGROUP	; Tell the assembler about it
LCL_INT0C_ORIG:
	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

; We always go to the previous PM interrupt handler for INT 0Ch
; as remote SWAT is always behind us.

;;;	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;	jnz	short @F	; Jump if so
;;;
;;;	 test	 [esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;	 jz	 short @F	; Jump if not
;;;
;;;	 test	 DEVLOAD,@DEVL_LOAD ; Izit from device driver?
;;;	 jnz	 near ptr LCL_INTCOM_DEVORIG ; Jump if so
;;; @@:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	 push	 OLDINT0C_FVEC.FSEL ; Pass old selector
	 push	 OLDINT0C_FVEC.FOFF ; Pass old offset

INT0CX_STR struc

INT0CX_FOFF dd	  ?		 ; Old offset
INT0CX_FSEL dw	  ?		 ; ... selector
INT0CX_DS   dw	  ?		 ; ... DS
INT0CX_EFL  dd	  ?		 ; ... EFL (IF=TF=0)

INT0CX_STR ends

	 mov	 ds,[esp].INT0CX_DS ; Restore DS
	 assume  ds:nothing	; Tell the assembler about it

	 iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	 jmp	 near ptr LCL_INT0C ; In case we're returning from a TSS

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT0C endp			; End LCL_INT0C procedure
	 FPPROC  LCL_INT0D -- General Protection Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

General Protection interrupt handler.

|

	 pushfd 		; Save EFL
	PUSHW	ds		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	MASK_STKREG	; Mask off the high-order word of stack
				; registers if 16-bit stack
; Check for IRQ5 instead of a fault

	call	IZIT_IRQ5      ; Izit IRQ5?
	jnz	near ptr LCL_INT0D_ORIG ; Jump if so

INT0D_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   DS as word
	 dd	 ?		; Local copy of flags
INT0D_ERR dd	 ?		; Error code
INT0D_EIP dd	 ?		; EIP
INT0D_CS  dw	 ?,?		; CS w/filler
INT0D_EFL dd	 ?		; EFL

INT0D_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ds,es>	; Save for a moment

	SETDATAX es		; Set data selector into ES
	assume	es:DGROUP	; Tell the assembler about it

	 mov	 ds,COMMON.FILE_4GB ; Get all memory selector
	 assume  ds:AGROUP	; Tell the assembler about it

	 movzx	 eax,[ebp].INT0D_CS ; Get code segment/selector
	 shl	 eax,4-0	; Convert from paras to bytes

	 test	 [ebp].INT0D_EFL.EHI,mask $VM ; Izit from VM86?
	 jnz	 short @F	; Jump if so (EAX has base linear address of CS)

	 push	 [ebp].INT0D_CS.EDD ; Pass the code selector (as dword for alignment)
	 call	 SEL2BASE	; Return with EAX == selector base address
@@:
	 add	 eax,[ebp].INT0D_EIP ; Plus the EIP to get linear address

	 call	 CHECK_GPS	; Check on GP Skip at EAX
				; Return with CF significant
	 REGREST <es,ds,eax>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 pop	 ebp		; Restore
	 jc	 short LCL_INT0D_ORIG ; Jump if we're to skip this instruction

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	 popfd			; Restore

	 test	 [esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	 jz	 short @F	; Jump if not

	 test	 DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	 jz	 short @F	; Jump if not

	 PUSHD	 0		; Pass pseudo-error code
@@:

; Note that we can't use "offset PGROUP:";
; instead we *MUST* use "offset cs:" (thanks Microsoft)

;;;;;;;; push	 eax		; Pass error code (already on the stack)
	 PUSHD	 cs		; Segment of error message
	 push	 dword ptr (offset cs:INT0D_MSG1) ; Offset of ...
	 FCALLD  SAVEMSG	; Call message save routine

	 FCALLD  SWATTER	; Call our debugger

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short @F	; Jump if so

	 test	 [esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	 jz	 short @F	; Jump if not

	 test	 DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	 jnz	 near ptr LCL_INTCOM_DEVDONE ; Jump if so
@@:
	 iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	 jmp	 near ptr LCL_INT0D ; In case we're returning from a TSS

	assume	ds:DGROUP	; Tell the assembler about it
LCL_INT0D_ORIG:
	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short @F	; Jump if so

	 test	 [esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	 jz	 short @F	; Jump if not

	 test	 DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	 jnz	 near ptr LCL_INTCOM_DEVORIG ; Jump if so
@@:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	 push	 OLDINT0D_FVEC.FSEL ; Pass old selector
	 push	 OLDINT0D_FVEC.FOFF ; Pass old offset

INT0DX_STR struc

INT0DX_FOFF dd	 ?		; Old offset
INT0DX_FSEL dw	 ?		; ... selector
INT0DX_DS   dw	 ?		; ... DS
INT0DX_EFL  dd	 ?		; ... EFL (IF=TF=0)

INT0DX_STR ends

	 mov	 ds,[esp].INT0DX_DS ; Restore DS
	 assume  ds:nothing	; Tell the assembler about it

	 iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	 jmp	 near ptr LCL_INT0D ; In case we're returning from a TSS

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT0D endp			; End LCL_INT0D procedure
	 FPPROC  LCL_INT0E -- Page Fault Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Page Fault interrupt handler.

|

	 pushfd 		; Save EFL
	PUSHW	ds		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	MASK_STKREG	; Mask off the high-order word of stack
				; registers if 16-bit stack
; Check for IRQ6 instead of a fault

	call	IZIT_IRQ6      ; Izit IRQ6?
	jnz	short LCL_INT0E_ORIG ; Jump if so

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	 popfd			; Restore

;;;	     test    [esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;	     jz      short @F	    ; Jump if not
;;;
;;;	     test    DEVLOAD,@DEVL_LOAD ; Izit from device driver?
;;;	     jz      short @F	    ; Jump if not
;;;
;;;	     PUSHD   0		    ; Pass pseudo-error code
;;; @@:
;;;
; Note that we can't use "offset PGROUP:";
; instead we *MUST* use "offset cs:" (thanks Microsoft)

;;;;;;;; push	 eax		; Pass error code (already on the stack)
	 PUSHD	 cs		; Segment of error message
	 push	 dword ptr (offset cs:INT0E_MSG1) ; Offset of ...
	 FCALLD  SAVEMSG	; Call message save routine

	 FCALLD  SWATTER	; Call our debugger

;;;	   test    SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;	   jnz	   short @F	   ; Jump if so
;;;
;;;	     test    [esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;	     jz      short @F	    ; Jump if not
;;;
;;;;	     test    DEVLOAD,@DEVL_LOAD ; Izit from device driver?
;;;	     jnz     near ptr LCL_INTCOM_DEVDONE ; Jump if so
;;; @@:
	 iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	 jmp	 short LCL_INT0E ; In case we're returning from a TSS

	assume	ds:DGROUP	; Tell the assembler about it
LCL_INT0E_ORIG:
	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

;;;	    test    SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;	    jnz     short @F	    ; Jump if so
;;;
;;;	     test    [esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;	     jz      short @F	    ; Jump if not
;;;
;;;	     test    DEVLOAD,@DEVL_LOAD ; Izit from device driver?
;;;	     jnz     near ptr LCL_INTCOM_DEVORIG ; Jump if so
;;; @@:
;;;
; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	 push	 OLDINT0E_FVEC.FSEL ; Pass old selector
	 push	 OLDINT0E_FVEC.FOFF ; Pass old offset

INT0E_STR struc

INT0E_FOFF dd	 ?		; Old offset
INT0E_FSEL dw	 ?		; ... selector
INT0E_DS   dw	 ?		; ... DS
INT0E_EFL  dd	 ?		; ... EFL (IF=TF=0)

INT0E_STR ends

	 mov	 ds,[esp].INT0E_DS ; Restore DS
	 assume  ds:nothing	; Tell the assembler about it

	 iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	LCL_INT0E	; In case we're returning from a TSS

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT0E endp			; End LCL_INT0E procedure
;;;	     NPPROC  REPROG_PIC -- Reprogram the PIC
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Repogram the PIC to a specific INT base
;;;
;;; |
;;;
;;;	     REGSAVE <eax,ebx>	    ; Save registers
;;;
;;;	     mov     bh,@PIC0	    ; Use default base for master PIC
;;;	     mov     bl,@PIC1	    ; ...		   slave ...
;;;
;;; ; * Program the 8259
;;;
;;;	     test    SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
;;;	     jz      short REPROG_PIC1 ; Not this time
;;;
;;; ; ICW1
;;;
;;;	     mov     al,13h	    ; ICW1 -- edge-triggered, single, ICW4 needed
;;;	     out     @ICR,al	    ; Send to 8259
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;
;;; ; ICW2
;;;
;;;	     mov     al,bh	    ; ICW2 -- start of 8259 vector
;;;	     out     @IMR,al	    ; Send to 8259
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;
;;; ; ICW3 (none because it's not in cascade mode)
;;; ; ICW4
;;;
;;;	     mov     al,09h	    ; ICW4 -- buffered slave, normal EOI, 8086 mode
;;;	     out     @IMR,al	    ; Send to 8259
;;; ;;;;;;;; jmp     short $+2	    ; I/O delay
;;; ;;;;;;;; jmp     short $+2	    ; I/O delay
;;; ;;;;;;;; jmp     short $+2	    ; I/O delay
;;;
;;;	     jmp     short REPROG_PIC2 ; Join common code
;;;
;;; REPROG_PIC1:
;;;
;;; ; ICW1 -- master 8259
;;;
;;;	     mov     al,11h	    ; ICW1 -- edge-triggered, cascade, ICW4 needed
;;;
;;;	     test    SWATINI.MD_ATTR,@MD_MCA ; Izit an MCA-compatible?
;;;	     jz      short @F	    ; Not this time
;;;
;;;	     or      al,08h	    ; Mark as level-triggered
;;; @@:
;;;	     mov     ah,al	    ; Save for later use
;;;	     out     @ICR,al	    ; Send to master 8259
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;
;;; ; ICW2 -- master 8259
;;;
;;;	     mov     al,bh	    ; ICW2 -- start of 8259 vector
;;;	     out     @IMR,al	    ; Send to 8259
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;
;;; ; ICW3 -- master 8259
;;;
;;;	     mov     al,@BIT2	    ; ICW3 -- master level 2
;;;	     out     @IMR,al	    ; Send to master 8259
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;
;;; ; ICW4 -- master 8259
;;;
;;;	     mov     al,01h	    ; ICW4 -- not SFNM, normal EOI, 8086 mode
;;;	     out     @IMR,al	    ; Send to master 8259
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;
;;; ; ICW1 -- slave 8259
;;;
;;;	     mov     al,ah	    ; ICW1 -- level/edge-triggered, cascade, ICW4 needed
;;;	     out     @ICR2,al	    ; Send to slave 8259
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;
;;; ; ICW2 -- slave 8259
;;;
;;;	     mov     al,bl	    ; ICW2 -- start of slave 8259 vector
;;;	     out     @IMR2,al	    ; Send to slave 8259
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;
;;; ; ICW3 -- slave 8259
;;;
;;;	     mov     al,02h	    ; ICW3 -- slave level 2
;;;	     out     @IMR2,al	    ; Send to slave 8259
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;
;;; ; ICW34-- slave 8259
;;;
;;;	     mov     al,01h	    ; ICW4 -- not SFNM, normal EOI, 8086 mode
;;;	     out     @IMR2,al	    ; Send to slave 8259
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;; REPROG_PIC2:
;;;	     REGREST <ebx,eax>	    ; Restore
;;;
;;;	     ret		    ; Return to caller
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; REPROG_PIC endp		    ; End REPROG_PIC procedure
	NPPROC	MASK_STKREG -- Mask High-order Word of Stack Registers
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Mask off high-order word of stack registers
if we're running on a 16-bit stack

On exit:

EBP	=	high-order word might be zeroed
ESP	=	...

|

; If the caller's SS does not have the B-bit set, clear the
; high-order word of EBP and ESP so we can use them as base registers.

	push	eax		; Save for a moment

	mov	eax,ss		; Copy the selector
	lar	eax,eax 	; Get the A/R word

	test	eax,(mask $DTE_B) shl 16 ; Izit a 32-bit selector?
	jnz	short @F	; Jump if so

	movzx	ebp,bp		; Clear to use as dword
	movzx	esp,sp		; ...
@@:
	pop	eax		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MASK_STKREG endp		; End MASK_STKREG procedure

PROG	 ends			; End PROG segment

	 MEND			; End SWAT_INT module
