;' $Header$
	title	SWAT_IGT -- 386SWAT Interrupt Gate Handlers
	page	58,122
	name	SWAT_IGT

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-2002 Qualitas, Inc.  All rights reserved.

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
	include DEBUGSYS.INC

	include SWAT_DRV.INC
	include SWAT_COM.INC
	include SWAT_LBR.INC
	include SWAT_SEG.INC
	include SWAT_TSC.INC
.list


DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	public	@SWAT_IGT_DATA16
@SWAT_IGT_DATA16 label byte	; Mark module start in .MAP file

SWAT_DATA label dword

	extrn	COMMON:tbyte
	include QMAX_FIL.INC

	extrn	LC4_FLAG:dword
	include SWAT_LC4.INC

	extrn	OLDIGT00_FVEC:dword
	extrn	OLDIGT01_FVEC:dword
	extrn	OLDIGT03_FVEC:dword
	extrn	OLDIGT05_FVEC:dword
	extrn	OLDIGT06_FVEC:dword
	extrn	OLDIGT09_FVEC:dword
	extrn	OLDIGT0A_FVEC:dword
	extrn	OLDIGT0B_FVEC:dword
	extrn	OLDIGT0C_FVEC:dword
	extrn	OLDIGT0D_FVEC:dword
	extrn	OLDIGT0E_FVEC:dword

	extrn	CPUFET_FLAG:dword

;;;;;;; public	OLDIGT09_FVEC,OLDIGT09_ARB
	public	OLDREMIGT0B_FVEC,OLDREMIGT0B_ARB
	public	OLDREMIGT0C_FVEC,OLDREMIGT0C_ARB
;;;OLDIGT09_FVEC PTR32_STR <>	   ; Save area for INT 09h handler
OLDREMIGT0B_FVEC PTR32_STR <>	; Save area for INT 0Bh handler
OLDREMIGT0C_FVEC PTR32_STR <>	; ...		    0Ch
;;;OLDIGT09_ARB db CPL0_INTR3 or CPL3 ; Save area for INT 09h A/R byte
OLDREMIGT0B_ARB db CPL0_INTR3 or CPL3 ; Save area for INT 0Bh A/R byte
OLDREMIGT0C_ARB db CPL0_INTR3 or CPL3 ; ...		  0Ch

	DDALIGN SWAT_DATA	; Ensure aligned on dword boundary

;;;	public	LCLIGT09_FVEC
	public	LCLREMIGT0B_FVEC,LCLREMIGT0C_FVEC
;;;LCLIGT09_FVEC label fword	   ; Save area for INT 09h handler
;;;	   dd	   offset PGROUP:LCL_IGT09,?
LCLREMIGT0B_FVEC label fword	; Save area for INT 0Bh handler
	dd	offset PGROUP:LCL_IGT0B2,?
LCLREMIGT0C_FVEC label fword	; ...		    0Ch
	dd	offset PGROUP:LCL_IGT0C2,?

;;;	public	LCLIGT09_ARB
	public	LCLREMIGT0B_ARB,LCLREMIGT0C_ARB
;;;LCLIGT09_ARB db CPL0_INTR3 or CPL3 ; Save area for INT 09h A/R byte
LCLREMIGT0B_ARB db CPL0_INTR3 or CPL3 ; Save area for INT 0Bh A/R byte
LCLREMIGT0C_ARB db CPL0_INTR3 or CPL3 ; ...		  0Ch

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	@SWAT_IGT_DATA
@SWAT_IGT_DATA	label byte	; Mark module start in .MAP file

	extrn	NEW_TSC:qword
	extrn	OLD_TSC:qword

	extrn	EMU_DR0:dword

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP,ds:PGROUP

	public	@SWAT_IGT_PROG
@SWAT_IGT_PROG: 		; Mark module start in .MAP file

	extrn	SWATINI:tbyte
	include MAXDEV.INC

	extrn	SAVEMSG:far
	extrn	SWATTER:far
	extrn	ENABLE8255:near
	extrn	ENABLE_NMI:near
	extrn	DISABLE_NMI:near
	extrn	GETLBASE:near
	extrn	U32_DRAINPIQ:near

	extrn	SEL2BASE:near
	extrn	CHECK_GPS:near

	extrn	SET_LBR:near

	extrn	MASK_STKREGS:near
	extrn	MASK_STKREG1:near

	extrn	INT00_MSG1:byte
	extrn	INT02_MSG1:byte
	extrn	INT05_MSG1:byte
	extrn	INT06_MSG1:byte
	extrn	INT0A_MSG1:byte
	extrn	INT0B_MSG1:byte
	extrn	INT0C_MSG1:byte
	extrn	INT0D_MSG1:byte
	extrn	INT0E_MSG1:byte

	extrn	LCL_INT01_TAB:dword

	extrn	IZIT_IRQ2:near
	extrn	IZIT_IRQ3:near
	extrn	IZIT_IRQ4:near
	extrn	IZIT_IRQ5:near
	extrn	IZIT_IRQ6:near
	extrn	GETSHIFT:near

	extrn	LCL_INTCOM_DEVDONE:near
	extrn	LCL_INTCOM_DEVORIG:near
	extrn	LCL_INT0B2:near
	extrn	LCL_INT0C2:near
	extrn	LCL_INT67:near

	extrn	SetPMG:near

	FPPROC	LCL_IGT00 -- Divide Overflow Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Divide overflow interrupt (00h) with no error code on the stack.

If we're in VM 8086 mode and the two bytes preceding the caller
are CD 00, continue with INTPROC0.  Otherwise, call SWAT.

|

IGT00STK_STR struc

	     dd ?		; Caller's EBP
IGT00STK_DS  dw ?		; ...	   DS
	     dd ?		; ...	   EFLAGS (IF=TF=0)
IGT00STK_EIP dd ?		; ...	   EIP
IGT00STK_CS  dw ?,?		; ...	   CS with fill
IGT00STK_EFL dd ?		; ...	   EFLAGS

IGT00STK_STR ends

	pushfd			; Save EFL
	PUSHW	ds		; Save for a moment

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	SetPMG		; Set PM Interrupt Gate mode
	call	MASK_STKREGS	; Mask off the high-order word of stack
				; registers if 16-bit stack
	push	esi		; Save for a moment

	mov	ds,COMMON.FILE_4GB ; Get all memory selector
	assume	ds:AGROUP	; Tell the assembler about it

	movzx	esi,[ebp].IGT00STK_CS ; Get caller's CS
	shl	esi,4-0 	; Convert from paras to bytes
	add	esi,[ebp].IGT00STK_EIP ; DS:ESI ==> caller's next instruction

	cmp	esi,2		; Izit too small?
	jb	short @F	; Jump if so (note ZF=0)

	cmp	AGROUP:[esi-2].ELO,00CDh ; Izit INT 00h?
@@:
	pop	esi		; Restore
	pop	ebp		; Restore
	je	short LCL_IGT00_ORIG ; Jump if so

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

; Note that we can't use "offset PGROUP:";
; instead we *MUST* use "offset cs:" (thanks Microsoft)

	PUSHD	0		; Pass pseudo-error code
	PUSHD	cs		; Segment of error message
	push	dword ptr (offset cs:INT00_MSG1) ; Offset of ...
	FCALLD	SAVEMSG 	; Call message save routine

	FCALLD	SWATTER 	; Call our debugger

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not

	test	[esp].DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVDONE ; Jump if so
;;;@@:
	iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	LCL_IGT00	; In case we're returning from a TSS


	assume	ds:AGROUP	; Tell the assembler about it

LCL_IGT00_ORIG:
	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].LCLINT_NXT.DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVORIG ; Jump if so
;;;@@:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	push	OLDIGT00_FVEC.FSEL ; Pass old selector
	push	OLDIGT00_FVEC.FOFF ; Pass old offset

IGT00_STR struc

IGT00_FOFF dd	?		; Old offset
IGT00_FSEL dw	?		; ... selector
IGT00_DS   dw	?		; ... DS
IGT00_EFL  dd	?		; ... EFL (IF=TF=0)

IGT00_STR ends

	mov	ds,[esp].IGT00_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_IGT00 ; In case we're returning from a TSS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_IGT00 endp			; End LCL_IGT00 procedure
	FPPROC	LCL_IGT03 -- Breakpoint Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Breakpoint interrupt handler.

|

IGT03STK_STR struc

IGT03STK_EGP db (type PUSHAD_STR) dup (?) ; Caller's EGP registers
IGT03STK_EIP dd ?		; Caller's EIP
IGT03STK_CS  dw ?,?		;	   CS with fill
IGT03STK_EFL dd ?		;	   EFLAGS

IGT03STK_STR ends

	pushad			; Save all EGP registers
	mov	ebp,esp 	; Hello, Mr. Stack

	push	ds		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	SetPMG		; Set PM Interrupt Gate mode
	call	MASK_STKREGS	; Mask off the high-order word of stack
				; registers if 16-bit stack
; If we're to trap INT 03h in PL0 only, test for that

	test	LC4_FLAG,@LC4_INTPL0 ; Trapping PL0 only?
	jz	short @F	; Jump if not

	test	[ebp].IGT03STK_EFL.EHI,mask $VM ; Izit from V86 mode?
	jnz	short @F	; Jump if so (not PL0)

	test	[ebp].IGT03STK_CS,mask $PL ; Izit PL0?
	jnz	short LCL_IGT03_SKIP ; Jump if not (note CF=0)
@@:
	dec	[ebp].IGT03STK_EIP ; Backup to the breakpoint instruction
				; Note that if this routine was called via
				; two-byte interrupt (CD 03), we're not backing
				; up far enough
	stc			; Mark as not skipping
LCL_IGT03_SKIP:
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it
	popad			; ...
	jc	near ptr LCL_IGT01_COMMON ; Jump if not skipping

	pushfd			; Save flags
	PUSHW	ds		; Save register

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	push	OLDIGT03_FVEC.FSEL ; Pass selector
	push	OLDIGT03_FVEC.FOFF ; ...  offset

IGT03_STR struc

IGT03_FOFF dd	?		; Old offset
IGT03_FSEL dw	?		; ... selector
IGT03_DS   dw	?		; ... DS
IGT03_EFL  dd	?		; ... EFL (IF=TF=0)

IGT03_STR ends

	mov	ds,[esp].IGT03_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_IGT03 endp			; End LCL_IGT03 procedure
	FPPROC	LCL_IGT01 -- Single-step Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Single-step interrupt handler.

In order to maintain control of the debug registers, we might set the
GD bit in DR7.	In this case, we need to emulate references and sets
to any of the DRn registers.

If the GD bit is set, and a program references a debug register, SWAT
is entered via a debug exception, and the CPU clears the GD bit thus
allowing further access to the debug registers.

|

IGT01STK_STR struc

IGT01STK_EGP db (type PUSHAD_STR) dup (?) ; Caller's EGP registers
IGT01STK_EIP dd ?		; ...	   EIP
IGT01STK_CS  dw ?,?		; ...	   CS w/filler
IGT01STK_EFL dd ?		; ...	   EFL

IGT01STK_STR ends

	pushad			; Save all EGP registers
	mov	ebp,esp 	; Hello, Mr. Stack

	push	ds		; Save segment register

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	GET_TSC NEW		; Get current Time Stamp Counter

	call	SetPMG		; Set PM Interrupt Gate mode
	call	MASK_STKREGS	; Mask off the high-order word of stack
				; registers if 16-bit stack
; If we're to trap INT 01h in PL0 only, test for that

	test	LC4_FLAG,@LC4_INTPL0 ; Trapping PL0 only?
	jz	short @F	; Jump if not

	test	[ebp].IGT01STK_EFL.EHI,mask $VM ; Izit from V86 mode?
	jnz	short @F	; Jump if so (not PL0)

	test	[ebp].IGT01STK_CS,mask $PL ; Izit PL0?
	jz	near ptr LCL_IGT01_ORIG ; Jump if so (note CF=0)
@@:

; If this event is from within SWAT, continue processing

	test	[ebp].IGT01STK_EFL.EHI,mask $VM ; Izit from V86 mode?
	jnz	short @F	; Jump if so (not within SWAT)

	mov	ax,cs		; Get our code selector
	cmp	ax,[ebp].IGT01STK_CS ; Izit the same as the caller's CS?
	je	near ptr LCL_IGT01_XGD ; Jump if so (note CF=0)
@@:
	public	LCL_IGT01_DR6
LCL_IGT01_DR6:
	mov	eax,dr6 	; Get the debug status register

	btr	eax,$BD 	; Izit from a debug register reference/set?
	jnc	near ptr LCL_IGT01_XGD ; Jump if not (note CF=0)

	mov	dr6,eax 	; Clear the bit

; Interpret the instruction at CS|EIP to see if it's a
; reference or set as well as how long it is so we can skip over it

	movzx	esi,[ebp].IGT01STK_CS ; Get the caller's CS

	test	[ebp].IGT01STK_EFL.EHI,mask $VM ; Izit from V86 mode?
	jz	short @F	; Jump if not

	shl	esi,4-0 	; Convert from paras to bytes
	add	esi,[ebp].IGT01STK_EIP ; Plus the offset

	mov	ds,COMMON.FILE_4GB ; Get all memory selector
	assume	ds:nothing	; Tell the assembler about it

	jmp	short LCL_IGT01_GDCOM ; Join common code


@@:

; Note that the following code won't work if the code selector
; is execute-only (I've never seen that, though).

	mov	ds,si		; Address it
	assume	ds:nothing	; Tell the assembler about it

	mov	esi,[ebp].IGT01STK_EIP ; Get the offset
LCL_IGT01_GDCOM:

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
	je	short LCL_IGT01_GDREAD ; Jump if so

	cmp	ax,@OPCOD_MOV_DRn_R32 ; Izit a write to DRn?
	clc			; Assume not
	jne	short LCL_IGT01_XGD ; Jump if not (huh??) (note CF=0)

	lods	ds:[esi].LO	; Get the MOD R/M byte
	inc	ecx		; Count in another

	add	[ebp].IGT01STK_EIP,ecx ; Skip over the instruction

; Determine which register it is and save their value
; The REG bits contain the DRn register #
; The RM  bits contain the r32 register #

	mov	ecx,eax 	; Save the MOD R/M byte

	and	ecx,mask $RM	; Isolate the RM bits
	shr	ecx,$RM 	; Shift to low order
	sub	ecx,7		; Subtract
	neg	ecx		; ...from 7 to index PUSHAD struc

	mov	ecx,[ebp].IGT01STK_EGP[ecx*4].EDD ; Get the incoming value

	push	es		; Save for a moment

	SETDATAX es		; Set data selector into DS
	assume	es:DGROUP	; Tell the assembler about it

	and	eax,mask $REG	; Isolate the REG bits
	shr	eax,$REG	; Shift to low-order
	mov	EMU_DR0[eax*(type EMU_DR0)],ecx ; Save for later use

	pop	es		; Restore
	assume	es:nothing	; Tell the assembler about it

	jmp	short LCL_IGT01_GD_EXIT ; Join common exit code


LCL_IGT01_GDREAD:
	lods	ds:[esi].LO	; Get the MOD R/M byte
	inc	ecx		; Count in another

	add	[ebp].IGT01STK_EIP,ecx ; Skip over the instruction

; Determine which register it is and give it back to them
; The REG bits contain the DRn register #
; The RM  bits contain the r32 register #

	mov	ecx,eax 	; Save the MOD R/M byte

	and	eax,mask $REG	; Isolate the REG bits
	shr	eax,$REG	; Shift to low-order

	push	es		; Save for a moment

	SETDATAX es		; Set data selector into DS
	assume	es:DGROUP	; Tell the assembler about it

	call	LCL_INT01_TAB[eax*(type LCL_INT01_TAB)] ; Take appropriate action

	pop	es		; Restore
	assume	es:nothing	; Tell the assembler about it

	and	ecx,mask $RM	; Isolate the RM bits
	shr	ecx,$RM 	; Shift to low order
	sub	ecx,7		; Subtract
	neg	ecx		; ...from 7 to index PUSHAD struc

	mov	[ebp].IGT01STK_EGP[ecx*4].EDD,eax ; Save back
LCL_IGT01_GD_EXIT:

; Set the GD bit again to catch the next read/write

	mov	eax,dr7 	; Get current contents
	or	eax,mask $GD	; Set the bit
	mov	dr7,eax 	; Tell the CPU about it

	stc			; Mark as skipping this instruction
LCL_IGT01_XGD:
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popad			; Restore
	jnc	short LCL_IGT01_COMMON ; Jump if we're continuing

	jmp	short IGT1_RETURN ; Skip over the instruction


LCL_IGT01_ORIG:
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popad			; Restore

	pushfd			; Save flags
	PUSHW	ds		; Save register

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	push	OLDIGT01_FVEC.FSEL ; Pass selector
	push	OLDIGT01_FVEC.FOFF ; ...  offset

IGT01_STR struc

IGT01_FOFF dd	?		; Old offset
IGT01_FSEL dw	?		; ... selector
IGT01_DS   dw	?		; ... DS
IGT01_EFL  dd	?		; ... EFL (IF=TF=0)

IGT01_STR ends

	mov	ds,[esp].IGT01_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

LCL_IGT01_COMMON:
	FCALLD	SWATTER 	; Call our debugger

	public	IGT1_RETURN
IGT1_RETURN:
;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVDONE ; Jump if so
;;;@@:
	iretd			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_IGT01 endp			; End LCL_IGT01 procedure
	FPPROC	LCL_IGT02 -- NMI Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

NMI interrupt handler.

|

	pushfd			; Save EFL
	PUSHW	ds		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	SetPMG		; Set PM Interrupt Gate mode
	call	MASK_STKREG1	; Mask off the high-order word of stack
				; register if 16-bit stack
	call	DISABLE_NMI	; Disable NMI until the end
	jc	short LCL_IGT02_ORIG ; Jump if NMI handler already active
;;;
;;;	     REGSAVE <eax,ebx,ds>   ; Save for a moment
;;;
;;; @PIC0    equ     08h	    ; Master PIC base
;;; @PIC1    equ     70h	    ; Slave ...
;;;
;;;	     test    DBG_FLAG,@DBG_NMIPIC ; Izit specified?
;;;	     jz      short LCL_IGT02_XPIC ; Jump if not
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
;;; LCL_IGT02_XPIC:
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

	FCALLD	SWATTER 	; Call our debugger

	cli			; Disallow interrupts
	call	ENABLE_NMI	; Enable NMI, clear the parity latches

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVDONE ; Jump if so
;;;@@:
	iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	LCL_IGT02	; In case we're returning from a TSS


LCL_IGT02_ORIG:
;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].LCLINT_NXT.DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVORIG ; Jump if so
;;;@@:

; At this point, only EFL and DS are extra on the stack

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

	iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_IGT02 ; In case we're returning from a TSS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_IGT02 endp			; End LCL_IGT02 procedure
	FPPROC	LCL_IGT05 -- BOUND Instruction Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BOUND instruction interrupt (05h) with no error code on the stack.

If we're in VM 8086 mode and the two bytes preceding the caller
are CD 05, continue with INTPROC5.  Otherwise, call SWAT.

|

IGT05STK_STR struc

	     dd ?		; Caller's EBP
IGT05STK_DS  dw ?		; ...	   DS
	     dd ?		; ...	   EFLAGS (IF=TF=0)
IGT05STK_EIP dd ?		; ...	   EIP
IGT05STK_CS  dw ?,?		; ...	   CS with fill
IGT05STK_EFL dd ?		; ...	   EFLAGS

IGT05STK_STR ends

	pushfd			; Save EFL
	PUSHW	ds		; Save for a moment

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	push	esi		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	SetPMG		; Set PM Interrupt Gate mode
	call	MASK_STKREGS	; Mask off the high-order word of stack
				; registers if 16-bit stack
	mov	ds,COMMON.FILE_4GB ; Get all memory selector
	assume	ds:AGROUP	; Tell the assembler about it

	movzx	esi,[ebp].IGT05STK_CS ; Get caller's CS
	shl	esi,4-0 	; Convert from paras to bytes
	add	esi,[ebp].IGT05STK_EIP ; DS:ESI ==> caller's next instruction

	cmp	esi,2		; Izit too small?
	jb	short @F	; Jump if so (note ZF=0)

	cmp	AGROUP:[esi-2].ELO,05CDh ; Izit INT 05h?
@@:
	pop	esi		; Restore
	pop	ebp		; Restore
	je	short LCL_IGT05_ORIG ; Jump if so

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

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVDONE ; Jump if so
;;;@@:
	iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	LCL_IGT05	; In case we're returning from a TSS


	assume	ds:nothing	; Tell the assembler about it

LCL_IGT05_ORIG:
	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].LCLINT_NXT.DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVORIG ; Jump if so
;;;@@:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	push	OLDIGT05_FVEC.FSEL ; Pass old selector
	push	OLDIGT05_FVEC.FOFF ; Pass old offset

IGT05_STR struc

IGT05_FOFF dd	?		; Old offset
IGT05_FSEL dw	?		; ... selector
IGT05_DS   dw	?		; ... DS
IGT05_EFL  dd	?		; ... EFL (IF=TF=0)

IGT05_STR ends

	mov	ds,[esp].IGT05_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_IGT05 ; In case we're returning from a TSS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_IGT05 endp			; End LCL_IGT05 procedure
	FPPROC	LCL_IGT06 -- Invalid Opcode Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Invalid Opcode interrupt handler.

|

IGT06STK_STR struc

	     dd ?		; Caller's EBP
IGT06STK_DS  dw ?		; ...	   DS
	     dd ?		; ...	   EFLAGS (IF=TF=0)
IGT06STK_EIP dd ?		; ...	   EIP
IGT06STK_CS  dw ?,?		; ...	   CS with fill
IGT06STK_EFL dd ?		; ...	   EFLAGS

IGT06STK_STR ends

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

	call	SetPMG		; Set PM Interrupt Gate mode
	call	MASK_STKREGS	; Mask off the high-order word of stack
				; registers if 16-bit stack
	mov	ds,COMMON.FILE_4GB ; Get all memory selector
	assume	ds:AGROUP	; Tell the assembler about it

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jz	short LCL_IGT06_XWIN ; Jump if not

	test	[ebp].IGT06STK_EFL.EHI,mask $VM ; Izit VM86 mode?
	jz	short LCL_IGT06_PM ; Jump if not

	movzx	eax,[ebp].IGT06STK_CS ; Get caller's CS
	shl	eax,4-0 	; Convert from paras to bytes
	add	eax,[ebp].IGT06STK_EIP ; DS:EAX ==> caller's next instruction

	cmp	AGROUP:[eax].ELO.LO,@OPCOD_ARPL ; Izit an ARPL?
	je	near ptr LCL_IGT06_ORIG ; Jump if it is

	jmp	short LCL_IGT06_XWIN ; Join common code


LCL_IGT06_PM:
	push	[ebp].IGT06STK_CS ; Get caller's CS
	call	GETLBASE	; Return with EAX = selector base

	add	eax,[ebp].IGT06STK_EIP ; DS:ESI ==> caller's next instruction

	cmp	AGROUP:[eax].ELO,0FF0Fh ; Izit 0F FF?
	je	short LCL_IGT06_ORIG ; Jump if it is
LCL_IGT06_XWIN:

; If this comes from VM, and it's BSWAP, let the VM handler handle it

	test	[ebp].IGT06STK_EFL.EHI,mask $VM ; Izit VM86 mode?
	jz	short LCL_IGT06_XVM ; Jump if not

	movzx	eax,[ebp].IGT06STK_CS ; Get caller's CS
	shl	eax,4-0 	; Convert from paras to bytes
	add	eax,[ebp].IGT06STK_EIP ; DS:EAX ==> caller's next instruction

	cmp	AGROUP:[eax].LO,@OPCOD_OSP ; Izit 32-bit form of BSWAP?
	jne	short @F	; Jump if not

	inc	eax		; Skip over it
@@:
	cmp	AGROUP:[eax].ELO,@OPCOD_BSWAPLO ; Izit a BSWAP?
	jb	short LCL_IGT06_XVM ; Jump if not

	cmp	AGROUP:[eax].ELO,@OPCOD_BSWAPHI ; Izit a BSWAP?
	jbe	short LCL_IGT06_ORIG ; Jump if so
LCL_IGT06_XVM:
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

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVDONE ; Jump if so
;;;@@:
	iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_IGT06 ; In case we're returning from a TSS


LCL_IGT06_ORIG:
	pop	eax		; Restore
	pop	ebp		; Restore

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].LCLINT_NXT.DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVORIG ; Jump if so
;;;@@:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	push	OLDIGT06_FVEC.FSEL ; Pass old selector
	push	OLDIGT06_FVEC.FOFF ; Pass old offset

IGT06_STR struc

IGT06_FOFF dd	?		; Old offset
IGT06_FSEL dw	?		; ... selector
IGT06_DS   dw	?		; ... DS
IGT06_EFL  dd	?		; ... EFL (IF=TF=0)

IGT06_STR ends

	mov	ds,[esp].IGT06_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_IGT06 ; In case we're returning from a TSS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_IGT06 endp			; End LCL_IGT06 procedure
	FPPROC	LCL_IGT09 -- Hardware Keyboard Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Hardware keyboard interrupt handler

|

	pushfd			; Save EFL
	PUSHW	ds		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	SetPMG		; Set PM Interrupt Gate mode
	call	MASK_STKREG1	; Mask off the high-order word of stack
				; register if 16-bit stack
	push	eax		; Save for a moment

; Ensure shift states are Ctrl- and Alt-

	call	GETSHIFT	; Return with shift states in AL
	jc	short LCL_IGT09_ORIG ; Jump if something went wrong

	and	al,(mask $DALT) or (mask $DCTL) ; Isolate just these two

	cmp	al,(mask $DALT) or (mask $DCTL) ; Ctrl and Alt pressed?
	jne	short LCL_IGT09_ORIG ; Jump if something else pressed

; Read in the scan code to check for the PAD5 or SYSREQ keys

	in	al,@8255_A	; Read in the scan code
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	cmp	al,@SSC_PAD5	; Check for PAD5 key
	je	short @F	; Jump if so

	cmp	al,@SSC_SYSREQ	; Check for SysReq key
	jne	short LCL_IGT09_ORIG ; Not this time
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

	FCALLD	SWATTER 	; Call our debugger

	jmp	IGT1_RETURN	; Join common code


	assume	ds:DGROUP	; Tell the assembler about it
LCL_IGT09_ORIG:
	pop	eax		; Restore

	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].LCLINT_NXT.DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVORIG ; Jump if so
;;;@@:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	push	OLDIGT09_FVEC.FSEL ; Pass old selector
	push	OLDIGT09_FVEC.FOFF ; Pass old offset

IGT09_STR struc

IGT09_FOFF dd	?		; Old offset
IGT09_FSEL dw	?		; ... selector
IGT09_DS   dw	?		; ... DS
IGT09_EFL  dd	?		; ... EFL (IF=TF=0)

IGT09_STR ends

	mov	ds,[esp].IGT09_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_IGT09 ; In case we're returning from a TSS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_IGT09 endp			; End LCL_IGT09 procedure
	FPPROC	LCL_IGT0A -- Invalid TSS Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Invalid TSS interrupt handler.

|

	pushfd			; Save EFL
	PUSHW	ds		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	SetPMG		; Set PM Interrupt Gate mode
	call	MASK_STKREG1	; Mask off the high-order word of stack
				; register if 16-bit stack
; Check for IRQ2 instead of a fault

	call	IZIT_IRQ2	; Izit IRQ2?
	jnz	short LCL_IGT0A_ORIG ; Jump if so

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

; Note that we can't use "offset PGROUP:";
; instead we *MUST* use "offset cs:" (thanks Microsoft)

;;;;;;; push	eax		; Pass error code (already on the stack)
	PUSHD	cs		; Segment of error message
	push	dword ptr (offset cs:INT0A_MSG1) ; Offset of ...
	FCALLD	SAVEMSG 	; Call message save routine

	FCALLD	SWATTER 	; Call our debugger

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVDONE ; Jump if so
;;;@@:
	iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_IGT0A ; In case we're returning from a TSS


	assume	ds:DGROUP	; Tell the assembler about it
LCL_IGT0A_ORIG:
	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].LCLINT_NXT.DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVORIG ; Jump if so
;;;@@:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	push	OLDIGT0A_FVEC.FSEL ; Pass old selector
	push	OLDIGT0A_FVEC.FOFF ; Pass old offset

IGT0AX_STR struc

IGT0AX_FOFF dd	?		; Old offset
IGT0AX_FSEL dw	?		; ... selector
IGT0AX_DS   dw	?		; ... DS
IGT0AX_EFL  dd	?		; ... EFL (IF=TF=0)

IGT0AX_STR ends

	mov	ds,[esp].IGT0AX_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_IGT0A ; In case we're returning from a TSS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_IGT0A endp			; End LCL_IGT0A procedure
	FPPROC	LCL_IGT0B -- Segment Not Present Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Segment Not Present interrupt handler.

|

	pushfd			; Save EFL
	PUSHW	ds		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	SetPMG		; Set PM Interrupt Gate mode
	call	MASK_STKREG1	; Mask off the high-order word of stack
				; register if 16-bit stack
; Check for IRQ3 instead of a fault

	call	IZIT_IRQ3	; Izit IRQ3?
	jnz	short LCL_IGT0B_ORIG ; Jump if so

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

;;;;;;; test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].DEVSTK_EFL,mask $R2 ; Izit from RM?
	jz	short @F	; Jump if not

	PUSHD	0		; Pass pseudo-error code
@@:

; Note that we can't use "offset PGROUP:";
; instead we *MUST* use "offset cs:" (thanks Microsoft)

;;;;;;; push	eax		; Pass error code (already on the stack)
	PUSHD	cs		; Segment of error message
	push	dword ptr (offset cs:INT0B_MSG1) ; Offset of ...
	FCALLD	SAVEMSG 	; Call message save routine

	FCALLD	SWATTER 	; Call our debugger

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVDONE ; Jump if so
;;;@@:
	iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_IGT0B ; In case we're returning from a TSS


	assume	ds:DGROUP	; Tell the assembler about it
LCL_IGT0B_ORIG:
	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

; We always go to the previous PM interrupt handler for INT 0Bh
; as remote SWAT is always behind us.

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
;;;	test	[esp].LCLINT_NXT.DEVSTK_EFL,mask $R2 ; Izit from RM?
;;;	jnz	near ptr LCL_INTCOM_DEVORIG ; Jump if so
;;;@@:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	push	OLDIGT0B_FVEC.FSEL ; Pass old selector
	push	OLDIGT0B_FVEC.FOFF ; Pass old offset

IGT0BX_STR struc

IGT0BX_FOFF dd	  ?		 ; Old offset
IGT0BX_FSEL dw	  ?		 ; ... selector
IGT0BX_DS   dw	  ?		 ; ... DS
IGT0BX_EFL  dd	  ?		 ; ... EFL (IF=TF=0)

IGT0BX_STR ends

	mov	ds,[esp].IGT0BX_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_IGT0B ; In case we're returning from a TSS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_IGT0B endp			; End LCL_IGT0B procedure
	FPPROC	LCL_IGT0B2 -- IRQ3 handler (COM2/COM4)
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Process serial port interrupts for COM2 or COM4.

|

	pushfd			; Save EFL
	PUSHW	ds		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	SetPMG		; Set PM Interrupt Gate mode
	call	MASK_STKREG1	; Mask off the high-order word of stack
				; register if 16-bit stack
	call	IZIT_IRQ3	; Izit IRQ3?
	jz	near ptr LCL_IGT0C2_ORIG ; Jump if not

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

	jmp	near ptr LCL_INT0B2 ; Join common code


	assume	ds:DGROUP	; Tell the assembler
LCL_IGT0B2_ORIG:
	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	push	OLDREMIGT0B_FVEC.FSEL ; Pass old selector
	push	OLDREMIGT0B_FVEC.FOFF ; Pass old offset

IGT0B2X_STR struc

IGT0B2X_FOFF dd ?		; Old offset
IGT0B2X_FSEL dw ?		; ... selector
IGT0B2X_DS   dw ?		; ... DS
IGT0B2X_EFL  dd ?		; ... EFL (IF=TF=0)

IGT0B2X_STR ends

	mov	ds,[esp].IGT0B2X_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_IGT0B2 ; In case we're returning from a TSS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_IGT0B2 endp 		; End LCL_IGT0B2 procedure
	FPPROC	LCL_IGT0C -- Stack Fault Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Stack Fault interrupt handler.

|

	pushfd			; Save EFL
	PUSHW	ds		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	SetPMG		; Set PM Interrupt Gate mode
	call	MASK_STKREG1	; Mask off the high-order word of stack
				; register if 16-bit stack
; Check for IRQ4 instead of a fault

	call	IZIT_IRQ4	; Izit IRQ4?
	jnz	short LCL_IGT0C_ORIG ; Jump if so

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

;;;;;;; test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].DEVSTK_EFL,mask $R2 ; Izit from RM?
	jz	short @F	; Jump if not

	PUSHD	0		; Pass pseudo-error code
@@:

; Note that we can't use "offset PGROUP:";
; instead we *MUST* use "offset cs:" (thanks Microsoft)

;;;;;;; push	eax		; Pass error code (already on the stack)
	PUSHD	cs		; Segment of error message
	push	dword ptr (offset cs:INT0C_MSG1) ; Offset of ...
	FCALLD	SAVEMSG 	; Call message save routine

	FCALLD	SWATTER 	; Call our debugger

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVDONE ; Jump if so
;;;@@:
	iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_IGT0C ; In case we're returning from a TSS


	assume	ds:DGROUP	; Tell the assembler about it
LCL_IGT0C_ORIG:
	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

; We always go to the previous PM interrupt handler for INT 0Ch
; as remote SWAT is always behind us.

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
;;;	test	[esp].LCLINT_NXT.DEVSTK_EFL,mask $R2 ; Izit from RM?
;;;	jnz	near ptr LCL_INTCOM_DEVORIG ; Jump if so
;;;@@:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	push	OLDIGT0C_FVEC.FSEL ; Pass old selector
	push	OLDIGT0C_FVEC.FOFF ; Pass old offset

IGT0CX_STR struc

IGT0CX_FOFF dd	?		 ; Old offset
IGT0CX_FSEL dw	?		 ; ... selector
IGT0CX_DS   dw	?		 ; ... DS
IGT0CX_EFL  dd	?		 ; ... EFL (IF=TF=0)

IGT0CX_STR ends

	mov	ds,[esp].IGT0CX_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_IGT0C ; In case we're returning from a TSS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_IGT0C endp			; End LCL_IGT0C procedure
	FPPROC	LCL_IGT0C2 -- IRQ4 handler (COM1/COM3)
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Process serial port interrupts for COM1 or COM3.

|

	pushfd			; Save EFL
	PUSHW	ds		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	SetPMG		; Set PM Interrupt Gate mode
	call	MASK_STKREG1	; Mask off the high-order word of stack
				; register if 16-bit stack
	call	IZIT_IRQ4	; Izit IRQ4?
	jz	near ptr LCL_IGT0C2_ORIG ; Jump if not

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

	jmp	near ptr LCL_INT0C2 ; Join common code


	assume	ds:DGROUP	; Tell the assembler
LCL_IGT0C2_ORIG:
	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	push	OLDREMIGT0C_FVEC.FSEL ; Pass old selector
	push	OLDREMIGT0C_FVEC.FOFF ; Pass old offset

IGT0C2X_STR struc

IGT0C2X_FOFF dd ?		; Old offset
IGT0C2X_FSEL dw ?		; ... selector
IGT0C2X_DS   dw ?		; ... DS
IGT0C2X_EFL  dd ?		; ... EFL (IF=TF=0)

IGT0C2X_STR ends

	mov	ds,[esp].IGT0C2X_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_IGT0C2 ; In case we're returning from a TSS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_IGT0C2 endp 		; End LCL_IGT0C2 procedure
	FPPROC	LCL_IGT0D -- General Protection Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

General Protection interrupt handler.

|

	pushfd			; Save EFL
	PUSHW	ds		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	SetPMG		; Set PM Interrupt Gate mode
	call	MASK_STKREG1	; Mask off the high-order word of stack
				; register if 16-bit stack
; Check for IRQ5 instead of a fault

	call	IZIT_IRQ5	; Izit IRQ5?
	jnz	near ptr LCL_IGT0D_ORIG ; Jump if so

IGT0D_STR struc

	dd	?		; Caller's EBP
	dw	?		; ...	   DS as word
	dd	?		; Local copy of flags
IGT0D_ERR dd	?		; Error code
IGT0D_EIP dd	?		; EIP
IGT0D_CS  dw	?,?		; CS w/filler
IGT0D_EFL dd	?		; EFL

IGT0D_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ds,es>	; Save for a moment

	SETDATAX es		; Set data selector into ES
	assume	es:DGROUP	; Tell the assembler about it

	mov	ds,COMMON.FILE_4GB ; Get all memory selector
	assume	ds:AGROUP	; Tell the assembler about it

	movzx	eax,[ebp].IGT0D_CS ; Get code segment/selector
	shl	eax,4-0 	; Convert from paras to bytes

	test	[ebp].IGT0D_EFL.EHI,mask $VM ; Izit from VM86?
	jnz	short @F	; Jump if so (EAX has base linear address of CS)

	push	[ebp].IGT0D_CS.EDD ; Pass the code selector (as dword for alignment)
	call	SEL2BASE	; Return with EAX == selector base address
@@:
	add	eax,[ebp].IGT0D_EIP ; Plus the EIP to get linear address

	call	CHECK_GPS	; Check on GP Skip at EAX
				; Return with CF significant
	REGREST <es,ds,eax>	; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	pop	ebp		; Restore
	jc	short LCL_IGT0D_ORIG ; Jump if we're to skip this instruction

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

;;;;;;; test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].DEVSTK_EFL,mask $R2 ; Izit from RM?
	jz	short @F	; Jump if not

	PUSHD	0		; Pass pseudo-error code
@@:

; Note that we can't use "offset PGROUP:";
; instead we *MUST* use "offset cs:" (thanks Microsoft)

;;;;;;; push	eax		; Pass error code (already on the stack)
	PUSHD	cs		; Segment of error message
	push	dword ptr (offset cs:INT0D_MSG1) ; Offset of ...
	FCALLD	SAVEMSG 	; Call message save routine

	FCALLD	SWATTER 	; Call our debugger

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVDONE ; Jump if so
;;;@@:
	iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_IGT0D ; In case we're returning from a TSS


	assume	ds:DGROUP	; Tell the assembler about it
LCL_IGT0D_ORIG:
	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].LCLINT_NXT.DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVORIG ; Jump if so
;;;@@:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	push	OLDIGT0D_FVEC.FSEL ; Pass old selector
	push	OLDIGT0D_FVEC.FOFF ; Pass old offset

IGT0DX_STR struc

IGT0DX_FOFF dd	?		; Old offset
IGT0DX_FSEL dw	?		; ... selector
IGT0DX_DS   dw	?		; ... DS
IGT0DX_EFL  dd	?		; ... EFL (IF=TF=0)

IGT0DX_STR ends

	mov	ds,[esp].IGT0DX_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_IGT0D ; In case we're returning from a TSS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_IGT0D endp			; End LCL_IGT0D procedure
	FPPROC	LCL_IGT0E -- Page Fault Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Page Fault interrupt handler.

|

	pushfd			; Save EFL
	PUSHW	ds		; Save for a moment

	SETDATAX ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	CLR_LBR 		; Clear Last Branch Reporting registers
	GET_TSC NEW		; Get current Time Stamp Counter

	call	SetPMG		; Set PM Interrupt Gate mode
	call	MASK_STKREG1	; Mask off the high-order word of stack
				; register if 16-bit stack
; Check for IRQ6 instead of a fault

	call	IZIT_IRQ6	; Izit IRQ6?
	jnz	short LCL_IGT0E_ORIG ; Jump if so

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

;;;;;;; test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].DEVSTK_EFL,mask $R2 ; Izit from RM?
	jz	short @F	; Jump if not

	PUSHD	0		; Pass pseudo-error code
@@:

; Note that we can't use "offset PGROUP:";
; instead we *MUST* use "offset cs:" (thanks Microsoft)

;;;;;;; push	eax		; Pass error code (already on the stack)
	PUSHD	cs		; Segment of error message
	push	dword ptr (offset cs:INT0E_MSG1) ; Offset of ...
	FCALLD	SAVEMSG 	; Call message save routine

	FCALLD	SWATTER 	; Call our debugger

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not

	test	[esp].DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVDONE ; Jump if so
;;;@@:
	iretd			; Return to caller

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	near ptr LCL_IGT0E ; In case we're returning from a TSS


	assume	ds:DGROUP	; Tell the assembler about it
LCL_IGT0E_ORIG:
	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Set Last Branch Reporting registers

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
;;;;;;; test	[esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].LCLINT_NXT.DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVORIG ; Jump if so
;;;@@:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	push	OLDIGT0E_FVEC.FSEL ; Pass old selector
	push	OLDIGT0E_FVEC.FOFF ; Pass old offset

IGT0E_STR struc

IGT0E_FOFF dd	?		; Old offset
IGT0E_FSEL dw	?		; ... selector
IGT0E_DS   dw	?		; ... DS
IGT0E_EFL  dd	?		; ... EFL (IF=TF=0)

IGT0E_STR ends

	mov	ds,[esp].IGT0E_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

;;;;;;; CLR_LBR 		; Clear Last Branch Reporting registers *FIXME*

	jmp	LCL_IGT0E	; In case we're returning from a TSS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_IGT0E endp			; End LCL_IGT0E procedure
	FPPROC	LCL_IGT67 -- EMS Function Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMS function interrupt (67h) with no error code on the stack.

|

IGT67STK_STR struc

	     dd ?		; Caller's EBP
IGT67STK_DS  dw ?		; ...	   DS
	     dd ?		; ...	   EFLAGS (IF=TF=0)
IGT67STK_EIP dd ?		; ...	   EIP
IGT67STK_CS  dw ?,?		; ...	   CS with fill
IGT67STK_EFL dd ?		; ...	   EFLAGS

IGT67STK_STR ends

	call	SetPMG		; Set PM Interrupt Gate mode
	call	MASK_STKREG1	; Mask off the high-order word of stack
				; register if 16-bit stack
	jmp	near ptr LCL_INT67 ; Continue with INT 67h handler

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_IGT67 endp			; End LCL_IGT67 procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_IGT module
