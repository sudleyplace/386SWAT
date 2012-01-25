;' $Header:   P:/PVCS/386SWAT/SWAT_KEY.ASV   1.20   10 Aug 1998 11:01:12   BOB  $
	title	SWAT_KEY -- 386MAX Debugger Keyboard Routines
	page	58,122
	name	SWAT_KEY

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
	include ASCII.INC
	include 8253.INC
	include 8255.INC
	include 8259.INC
	include 386.INC
	include PTR.INC
	include BITFLAGS.INC
	include CPUFLAGS.INC
	include BIOSDATA.INC
	include KEYCALL.INC
	include SCANCODE.INC
	include KEYCODE.INC
	include CPUID.INC
	include ALLMEM.INC
	include DEBUGSYS.INC

	include SWAT_COM.INC
	include SWAT_DRV.INC
	include SWAT_LOG.INC
	include SWAT_SEG.INC
.list

SAVEINT macro	NUM,NAM

	mov	ax,cs		; Get our selector
	xchg	ax,AGROUP:[ebx+&NUM&*(size IDT_STR)].IDT_SELECT ; Swap 'em
	mov	KEYINT&NAM&_FVEC.FSEL,ax ; Save to restore later

	lea	eax,KEY_INT&NAM ; Get our 32-bit offset
	xchg	ax,AGROUP:[ebx+&NUM&*(size IDT_STR)].IDT_OFFLO ; Swap 'em
	mov	KEYINT&NAM&_FVEC.FOFF.ELO,ax ; Save to restore later

	shr	eax,16		; Shift down the high-order word
	xchg	ax,AGROUP:[ebx+&NUM&*(size IDT_STR)].IDT_OFFHI ; Swap 'em
	mov	KEYINT&NAM&_FVEC.FOFF.EHI,ax ; Save to restore later

	mov	al,CPL0_INTR3 or CPL3 ; Get our access rights byte
	xchg	al,AGROUP:[ebx+&NUM&*(size IDT_STR)].IDT_ACCESS ; Swap 'em
	mov	KEYINT&NAM&_ARB,al ; Save to restore later

	endm			; SAVEINT

RESTINT macro	NUM,NAM

	mov	ax,KEYINT&NAM&_FVEC.FSEL ; Get original selector
	mov	AGROUP:[ebx+&NUM&*(size IDT_STR)].IDT_SELECT,ax ; Save it back

	mov	eax,KEYINT&NAM&_FVEC.FOFF ; Get original offset
	mov	AGROUP:[ebx+&NUM&*(size IDT_STR)].IDT_OFFLO,ax ; Save it back

	shr	eax,16		; Shift down the high-order word
	mov	AGROUP:[ebx+&NUM&*(size IDT_STR)].IDT_OFFHI,ax ; Save it back

	mov	al,KEYINT&NAM&_ARB ; Get original access rights byte
	mov	AGROUP:[ebx+&NUM&*(size IDT_STR)].IDT_ACCESS,al ; Save it back

	endm			; RESTINT


DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	public	@SWAT_KEY_DATA16
@SWAT_KEY_DATA16 label byte	; Mark module start in .MAP file

	extrn	COMMON:tbyte
	include QMAX_FIL.INC

	extrn	ARG_FLAG:word
	include SWAT_ARG.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	LC3_FLAG:dword
	include SWAT_LC3.INC

	extrn	DBG_FLAG:word
	include SWAT_DBG.INC

	extrn	VIDBASE_FVEC:fword
	extrn	PORTIRQ:byte

	public	PASSTHROUGH1,PASSTHROUGH2
PASSTHROUGH1 db 0ffh		; Interrupts on PIC1 to pass through (none)
PASSTHROUGH2 db 0ffh		; Interrupts on PIC2 to pass through (none)

	public	OLDIBV0
OLDIBV0 db	08h		; Old master interrupt base vector

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	@SWAT_KEY_DATA
@SWAT_KEY_DATA label byte	; Mark module start in .MAP file

	extrn	INT_FLAG:word
	include SWAT_INT.INC

	extrn	SER_TIMEOUT:word

;;;;;;; extrn	SELFDBG:dword
	extrn	DSP_STATE:byte
	extrn	INSTRNLN:dword

	public	SHORT_DUR,SHORT_FRQ
SHORT_DUR dw	-1		; Duration
SHORT_FRQ dw	800		; Frequency

	public	FREQ
FREQ	dd	1193182 	; Fundamental frequency

	public	LCLTIMER,LCLTIMER_OFL
LCLTIMER dd	?		; Local timer dword
LCLTIMER_OFL db ?		; ...	      overflow

	align	4

	public	IDT_REBOOT
IDT_REBOOT df	0		; IDT with zero limit to reboot the system

	public	OLDIMR1,OLDIMR2
OLDIMR1 db	?		; Save area for original master IMR
OLDIMR2 db	?		; ...			 slave	IMR

	align	4

	public	LBUF_START,LBUF_HEAD,LBUF_TAIL,LBUF_END
LBUF_START dd	offset DGROUP:LBUF  ; Start of buffer (static)
LBUF_HEAD  dd	offset DGROUP:LBUF  ; Head position in buffer (dynamic)
LBUF_TAIL  dd	offset DGROUP:LBUF  ; Tail position in buffer (dynamic)
LBUF_END   dd	offset DGROUP:LBUF[size LBUF] ; End+1 of buffer (static)

	public	LBUF
LBUF	dw	500 dup (-1)	; Keyboard buffer

	public	KEYINT08_FVEC,KEYINT09_FVEC,KEYINT0A_FVEC,KEYINT0F_FVEC
	public	KEYINT74_FVEC,KEYINT76_FVEC,KEYINT77_FVEC
	public	KEYINT08_ARB, KEYINT09_ARB, KEYINT0A_ARB, KEYINT0F_ARB
	public	KEYINT74_ARB, KEYINT76_ARB, KEYINT77_ARB
KEYINT08_FVEC df ?		; Save area for old INT 08h handler
KEYINT09_FVEC df ?		; ...			09h ...
KEYINT0A_FVEC df ?		; ...			0Ah ...
KEYINT0F_FVEC df ?		; ...			0Fh ...
KEYINT74_FVEC df ?		; ...			74h ...
KEYINT76_FVEC df ?		; ...			76h ...
KEYINT77_FVEC df ?		; ...			77h ...
KEYINT08_ARB db ?		; Save area for old INT 08h access rights byte
KEYINT09_ARB db ?		;			09h
KEYINT0A_ARB db ?		;			0Ah
KEYINT0F_ARB db ?		;			0Fh
KEYINT74_ARB db ?		;			74h
KEYINT76_ARB db ?		;			76h
KEYINT77_ARB db ?		;			77h

I09_REC record	$I09_PAD5:1=0,$I09_INT01:1=0

	public	I09_FLAG
I09_FLAG I09_REC <>		; INT 09h flags

	public	ALT_NUM
ALT_NUM db	0		; Accumulator for Alt-numpad


	public	SHIFT_PREC	; LR LR 	 Shift precedence table
;				; AACSS 	A=Alt, C=Ctl, S=Shift
SHIFT_PREC db	0		; 00000 	0=Unshift
	db	1		; 00001 	1=Shift
	db	1		; 00010 	2=Control
	db	1		; 00011 	3=R-Alt
	db	2		; 00100 	4=L-Alt
	db	2		; 00101
	db	2		; 00110
	db	2		; 00111
	db	3		; 01000
	db	3		; 01001
	db	3		; 01010
	db	3		; 01011
	db	3		; 01100
	db	3		; 01101
	db	3		; 01110
	db	3		; 01111
	db	4		; 10000
	db	4		; 10001
	db	4		; 10010
	db	4		; 10011
	db	4		; 10100
	db	4		; 10101
	db	4		; 10110
	db	4		; 10111
	db	4		; 11000
	db	4		; 11001
	db	4		; 11010
	db	4		; 11011
	db	4		; 11100
	db	4		; 11101
	db	4		; 11110
	db	4		; 11111

	public	LKB_FLAG,LKB_FLAG1,LKB_FLAG2,LKB_FLAG3
	public	LKB_FLAG4
LKB_FLAG db	?		; Main keyboard flag byte
LKB_FLAG1 db	?		; 1st secondary ...
LKB_FLAG2 db	?		; 2nd ...
LKB_FLAG3 db	?		; 3rd ...
KB4REC	record	$KB4_RSVD:6, $KB4_LWIN:1, $KB4_RWIN:1
LKB_FLAG4 db	?		; 4th ...

	public	KEY_NUM
KEY_NUM db	@SSC_INS	; 0
	db	@SSC_END	; 1
	db	@SSC_DN 	; 2
	db	@SSC_PGDN	; 3
	db	@SSC_LEFT	; 4
	db	@SSC_PAD5	; 5
	db	@SSC_RIGHT	; 6
	db	@SSC_HOME	; 7
	db	@SSC_UP 	; 8
	db	@SSC_PGUP	; 9
KEY_NUMLEN equ	$-KEY_NUM	; # entries in table

;;;	     public  KEYBAR
;;; KEYBAR   db      '컴컴컴컴컴컴컴컴컴컴컴�',0





	public	UNITS_DUR,UNITS_FRQ
UNITS_DUR dw	-1		; Duration
UNITS_FRQ dw	800		; Frequency

	public	FIVES_DUR,FIVES_FRQ
FIVES_DUR dw	-1		; Duration
FIVES_FRQ dw	400		; Frequency

	public	TENS_DUR,TENS_FRQ
TENS_DUR dw	-1		; Duration
TENS_FRQ dw	200		; Frequency

	public	DIVISOR
DIVISOR db	5		; High/low sound divisor

DATA	ends			; End DATA segment


KSEGTAB segment use32 word public 'data' ; Start KSEGTAB segment
	assume	ds:DGROUP

	extrn	KEY_TAB:word
	extrn	KEY_TABLEN:abs
	extrn	KEYE0_TAB:word

KSEGTAB ends			; End KSEGTAB segment


KSEGTOG segment use32 byte public 'data' ; Start KSEGTOG segment
	assume	ds:DGROUP

	extrn	KEY_TOG:byte

KSEGTOG ends			; End KSEGTOG segment


KSEGCOD segment use32 byte public 'data' ; Start KSEGCOD segment
	assume	ds:DGROUP

	extrn	KEYE0_COD:byte
	extrn	KEYE0_CODLEN:abs

	extrn	KEYSP_COD:byte
	extrn	KEYSP_CODLEN:abs

	extrn	KEYSF_COD:byte
	extrn	KEYSF_CODLEN:abs

KSEGCOD ends			; End KSEGCOD segment


KSEGACT segment use32 dword public 'data' ; Start KSEGACT segment
	assume	ds:DGROUP

	extrn	KEYE0_ACT:dword
	extrn	KEYSP_ACT:dword
	extrn	KEYSF_ACT:dword

KSEGACT ends			; End KSEGACT segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP,ds:PGROUP

	public	@SWAT_KEY_PROG
@SWAT_KEY_PROG: 		; Mark module start in .MAP file

	extrn	GETBDA:near
	extrn	DEVLOAD:byte
	extrn	DVGASEL0:near
	extrn	SWATINI:tbyte
U32_SWATINI equ SWATINI 	; Just so we don't have to change all occurrences

	include MAXDEV.INC

	extrn	REMOTE_ACT:near
	extrn	INTxx_ORIG:near

	extrn	LDISPMSG:near
	extrn	LDISPTXTB:near
	extrn	SWAP_NMI_FLAG:near

	NPPROC	SAVE_IRQS -- Save IRQ-specific Values And Install Our Handlers
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save the old and swap in the new timer, keyboard, and mouse handlers.
Copy low memory timer values and keyboard flags to local memory.

This routine is designed to be called with minimal assumptions
so it can be used very generally.

|

SK_STR	struc

SK_IDT	df	?		; Save area for IDT

SK_STR	ends

	push	ebp		; Prepare to address the stack
	sub	esp,size SK_STR ; Make room on stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ebx,ecx,edx,es> ; Save registers

	pushfd			; Save flags
	cli			; Disallow interrupts

	call	SWAP_NMI_FLAG	; Swap NMI handlers and complement flag

	mov	es,COMMON.FILE_4GB ; Address all of memory
	assume	es:AGROUP	; Tell the assembler about it

; Get 32-bit linear address of the IDT

	SIDTD	[ebp].SK_IDT	; Save on stack
	mov	ebx,[ebp].SK_IDT.DTR_BASE
	movzx	edx,[ebp].DTR_LIM ; EDX = IDT limit
	inc	edx		; Convert from limit to length
	shr	edx,3-0 	; Convert from bytes to qwords (and INTs)

	movzx	ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
;;;;;;; add	ecx,0-0 	; Skip to timer interrupt (IRQ0)

	cmp	edx,ecx 	; Check against maximum interrupt #
	ja	short @F	; Jump if in range

	or	INT_FLAG,@INT_Q0 ; Mark as clobbered
@@:
	SAVEINT ecx,08		; EAX clobbered

	movzx	ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	add	ecx,1-0 	; Skip to keyboard interrupt (IRQ1)

	cmp	edx,ecx 	; Check against maximum interrupt #
	ja	short @F	; Jump if in range

	or	INT_FLAG,@INT_Q1 ; Mark as clobbered
@@:
	SAVEINT ecx,09		; EAX clobbered

	movzx	ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	add	ecx,2-0 	; Skip to cascade interrupt (IRQ2)

	cmp	edx,ecx 	; Check against maximum interrupt #
	ja	short @F	; Jump if in range

	or	INT_FLAG,@INT_Q2 ; Mark as not saved

	jmp	short SAVE_IRQS1 ; Skip SAVEINT


@@:
	SAVEINT ecx,0A		; EAX clobbered
SAVE_IRQS1:
	movzx	ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	add	ecx,3-0 	; Skip to COM2 interrupt (IRQ3)

;;;;;;; cmp	edx,ecx 	; Check against maximum interrupt #
;;;;;;; ja	short @F	; Jump if in range
;;;;;;;
;;;;;;; or	INT_FLAG,@INT_Q3 ; Mark as clobbered
;;;;;;;@@:
;;;;;;;  SAVEINT ecx,0B 	; EAX clobbered
;;;;;;;
	movzx	ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	add	ecx,4-0 	; Skip to COM1 interrupt (IRQ4)

;;;;;;; cmp	edx,ecx 	; Check against maximum interrupt #
;;;;;;; ja	short @F	; Jump if in range
;;;;;;;
;;;;;;; or	INT_FLAG,@INT_Q4 ; Mark as clobbered
;;;;;;;@@:
;;;;;;;  SAVEINT ecx,0C 	; EAX clobbered
;;;;;;;
	movzx	ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	add	ecx,7		; Skip to spurious interrupt (IRQ7)

	cmp	edx,ecx 	; Check against maximum interrupt #
	ja	short @F	; Jump if in range

	or	INT_FLAG,@INT_Q7 ; Mark as not saved

	jmp	short SAVE_IRQS1A ; Skip SAVEINT


@@:
	SAVEINT ecx,0F		; EAX clobbered
SAVE_IRQS1A:
	movzx	ecx,SWATINI.MD_IBV1 ; Get slave IMR base vector (IRQ8)
	add	ecx,12-8	; Skip to mouse interrupt (IRQ12)

	cmp	edx,ecx 	; Check against maximum interrupt #
	ja	short @F	; Jump if in range

	or	INT_FLAG,@INT_Q12 ; Mark as not saved

	jmp	short SAVE_IRQS1B ; Skip SAVEINT


@@:
	SAVEINT ecx,74		; EAX clobbered
SAVE_IRQS1B:
	movzx	ecx,SWATINI.MD_IBV1 ; Get slave IMR base vector (IRQ8)
	add	ecx,14-8	; Skip to hard disk interrupt (IRQ14)

	cmp	edx,ecx 	; Check against maximum interrupt #
	ja	short @F	; Jump if in range

	or	INT_FLAG,@INT_Q14 ; Mark as clobbered

	jmp	short SAVE_IRQS1C ; Skip SAVEINT


@@:
	SAVEINT ecx,76		; EAX clobbered
SAVE_IRQS1C:
	movzx	ecx,SWATINI.MD_IBV1 ; Get slave IMR base vector (IRQ8)
	add	ecx,15-8	; Skip to IRQ15 (used by some network cards)

	cmp	edx,ecx 	; Check against maximum interrupt #
	ja	short @F	; Jump if in range

	or	INT_FLAG,@INT_Q15 ; Mark as clobbered

	jmp	short SAVE_IRQS2 ; Skip SAVEINT


@@:
	SAVEINT ecx,77		; EAX clobbered
SAVE_IRQS2:

; Copy low memory timer values and keyboard flags to local memory

	call	GETBDA		; Return with EBX=linear address of BIOS data area
	jc	short SAVE_IRQS_EXIT ; Jump if something went wrong

	assume	es:BIOSDATA	; Tell the assembler about it

; Save timer values

	mov	eax,TIMER_LOW.EDD[ebx] ; Get both words of timer count
	mov	LCLTIMER,eax	; Save in local storage

	mov	al,TIMER_OFL[ebx] ; Get timer overflow value
	mov	LCLTIMER_OFL,al ; Save in local storage

; Save keyboard flags

	mov	al,KB_FLAG[ebx] ; Get main keyboard flag byte
	mov	LKB_FLAG,al	; Save for later use

	mov	al,KB_FLAG_1[ebx] ; Get 1st secondary keyboard flag byte
	mov	LKB_FLAG1,al	; Save for later use

	mov	al,KB_FLAG_2[ebx] ; Get 2nd secondary keyboard flag byte
	mov	LKB_FLAG2,al	; Save for later use

	mov	al,KB_FLAG_3[ebx] ; Get 3rd secondary keyboard flag byte
	mov	LKB_FLAG3,al	; Save for later use
SAVE_IRQS_EXIT:
	popfd			; Restore flags

	REGREST <es,edx,ecx,ebx,eax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	add	esp,size SK_STR ; Strip structure from stack
	pop	ebp		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_IRQS endp			; End SAVE_IRQS procedure
	NPPROC	REST_IRQS -- Restore Original IRQ-specific Handlers
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore the original timer, keyboard, and mouse interrupt handler.
Copy local memory timer values and keyboard flags to low memory.

This routine runs in protected mode.

This routine is designed to be called with minimal assumptions
so it can be used very generally.

|

RK_STR	struc

RK_IDT	df	?		; Save area for IDT

RK_STR	ends

	push	ebp		; Prepare to address the stack
	sub	esp,size RK_STR ; Make room on stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ebx,ecx,es> ; Save registers

	pushfd			; Save flags
	cli			; Disallow interrupts

;;;;;;; SELFBREAK INTXXSWT,2000h ; Break if SELFDBG&2000h

	call	SWAP_NMI_FLAG	; Swap NMI handlers and complement flag

	mov	es,COMMON.FILE_4GB ; Address all of memory
	assume	es:AGROUP	; Tell the assembler about it

; Get 32-bit linear address of the IDT

	SIDTD	[ebp].RK_IDT	; Save on stack
	mov	ebx,[ebp].RK_IDT.DTR_BASE
	movzx	ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
;;;;;;; add	ecx,0-0 	; Skip to timer interrupt (IRQ0)

	and	INT_FLAG,not @INT_Q0 ; Mark as restored
	RESTINT ecx,08		; EAX clobbered

	movzx	ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	add	ecx,1-0 	; Skip to keyboard interrupt (IRQ1)

	and	INT_FLAG,not @INT_Q1 ; Mark as restored
	RESTINT ecx,09		; EAX clobbered

	movzx	ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	add	ecx,2-0 	; Skip to cascade interrupt (IRQ2)

	btr	INT_FLAG,$INT_Q2 ; Clear and check for previous problem
	jc	short @F	; Jump if not previously saved

	RESTINT ecx,0A		; EAX clobbered
@@:
	movzx	ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	add	ecx,3-0 	; Skip to COM2 interrupt (IRQ3)

;;;;;;; and	INT_FLAG,not @INT_Q3 ; Mark as restored
;;;;;;; RESTINT ecx,0B		; EAX clobbered
;;;;;;;
	movzx	ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	add	ecx,4-0 	; Skip to COM1 interrupt (IRQ4)

;;;;;;; and	INT_FLAG,not @INT_Q4 ; Mark as restored
;;;;;;; RESTINT ecx,0C		; EAX clobbered
;;;;;;;
	movzx	ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	add	ecx,7		; Skip to spurious interrupt (IRQ7)

	btr	INT_FLAG,$INT_Q7 ; Clear and check for previous problem
	jc	short @F	; Jump if not previously saved

	RESTINT ecx,0F		; EAX clobbered
@@:
	movzx	ecx,SWATINI.MD_IBV1 ; Get slave  IMR base vector (IRQ8)
	add	ecx,12-8	; Skip to mouse interrupt (IRQ12)

	btr	INT_FLAG,$INT_Q12 ; Clear and check for previous problem
	jc	short @F	; Jump if not previously saved

	RESTINT ecx,74		; EAX clobbered
@@:
	movzx	ecx,SWATINI.MD_IBV1 ; Get slave IMR base vector (IRQ8)
	add	ecx,14-8	; Skip to hard disk interrupt (IRQ14)

	btr	INT_FLAG,$INT_Q14 ; Clear and check for previous problem
	jc	short @F	; Jump if not previously saved

	RESTINT ecx,76		; EAX clobbered
@@:
	movzx	ecx,SWATINI.MD_IBV1 ; Get slave IMR base vector (IRQ8)
	add	ecx,15-8	; Skip to IRQ15 (used by some network cards)

	btr	INT_FLAG,$INT_Q15 ; Clear and check for previous problem
	jc	short @F	; Jump if not previously saved

	RESTINT ecx,77		; EAX clobbered
@@:

; Copy local memory timer values and keyboard flags to low memory

	call	GETBDA		; Return with EBX=linear address of BIOS data area
	jc	short REST_IRQS_EXIT ; Jump if something went wrong

	assume	es:BIOSDATA	; Tell the assembler about it

; Restore low memory timer values

	mov	eax,LCLTIMER	; Get local timer count
	mov	TIMER_LOW.EDD[ebx],eax ; Save in BIOS data area

	mov	al,LCLTIMER_OFL ; Get local timer overflow value
	mov	TIMER_OFL[ebx],al ; Save in BIOS DATA area

; Restore low memory keyboard flags

	mov	al,LKB_FLAG	; Get main keyboard flag byte
	mov	KB_FLAG[ebx],al ; Save in low memory

	mov	al,LKB_FLAG1	; Get 1st secondary keyboard flag byte
	mov	KB_FLAG_1[ebx],al ; Save in low memory

	mov	al,LKB_FLAG2	; Get 2nd secondary keyboard flag byte
	mov	KB_FLAG_2[ebx],al ; Save in low memory

	mov	al,LKB_FLAG3	; Get 3rd secondary keyboard flag byte
	mov	KB_FLAG_3[ebx],al ; Save in low memory
REST_IRQS_EXIT:
	popfd			; Restore flags

	REGREST <es,ecx,ebx,eax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	add	esp,size RK_STR ; Strip structure from stack
	pop	ebp		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_IRQS endp			; End REST_IRQS procedure
	NPPROC	ENABLE_IRQS -- Enable The IRQs We Need
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable the IRQs we need.
In particular, we need IRQ0, IRQ1, and (if slave PIC present) IRQ2 and IRQ12.
Note that to test for IRQ12 in the slave PIC, we use IRQ4 (=12-8).
Ensure IRQ0 and IRQ1 are clear.  We also enable IRQ3 and IRQ4 only
when they're needed.  IRQ14 and IRQ15 are enabled only if device SWAT
is not active.	If we're not in Windows, enable PASSTHROUGH IRQs such
as IRQ14 and IRQ15.  There's a very long period in the Windows VxD
initialization where interrupts are disabled via CLI (although
enabled in the IMRs), so we also check the flags saved on the stack.
Furthermore, we can't handle remote debugging interrupts in Windows
at all, as the IMR bases are no longer 8 and 70.

Note that we also cannot pass through interrupts in device SWAT,
since we don't currently support the required return of control
to SWAT via Int FF or similar mechanism.

On entry:

SS:EBP	==>	FORW_STR

|

	pushfd			; Save flags
	cli			; Disallow interrupts

	REGSAVE <eax>		; Save register

	test	SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
	jnz	short ENABLE_IRQS1 ; Yes, no 8042

; Ensure the keyboard is in a stable state

;;;;;;; mov	ah,@S2C_PULSE or @BIT0 or @BIT1 or @BIT2 ; Pulse nothing
;;;;;;; call	U32_PPI_S2C	; Send command AH to 8042
				; Ignore return code
; Ensure the keyboard is enabled

	mov	ah,@S2C_ENA	; Enable the keyboard interface
	call	U32_PPI_S2C	; Send command AH to 8042
				; Ignore return code
	jmp	short ENABLE_IRQS2 ; Join common code


ENABLE_IRQS1:
	call	ENABLE8255	; Enable XT keyboard
ENABLE_IRQS2:

; Ensure IRQ0 and IRQ1 are enabled in the master PIC

	mov	al,not ((mask $IRQ0) or (mask $IRQ1)) ; Disable all interrupts
				; but these
; If we're debugging remotely, ensure the appropriate IRQ3-4 is enabled
; if not in Windows

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short ENABLE_IRQS_XSER ; Jump if so

	test	LC3_FLAG,@LC3_SERINT ; Is serial I/O interrupt driven?
	jz	short ENABLE_IRQS_XSER ; Jump if so

	cmp	PORTIRQ,$IRQ4	; Are we hooking IRQ4?
	jne	short @F	; Jump if not

	and	al,not (mask $IRQ4) ; Enable interrupts

	jmp	short ENABLE_IRQS_XSER ; Join common code


@@:
	cmp	PORTIRQ,$IRQ3	; Are we hooking IRQ3?
	jne	ENABLE_IRQS_XSER ; Jump if not

	and	al,not (mask $IRQ3) ; Enable interrupts
ENABLE_IRQS_XSER:

; If any other interrupts are to be passed through and we're not in
; device SWAT or running with CLI in effect, enable 'em.

	test	DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	jnz	short @F	; Jump if so

	test	[ebp].FORW_EFL.ELO,mask $IF ; Are interrupts enabled?
	jz	short @F	; Jump if not

	mov	ah,PASSTHROUGH1 ; Get mask for interrupts to enable in PIC1
	or	ah,OLDIMR1	; Mask off interrupts currently disabled
	and	al,ah		; Enable interrupts remaining
@@:
	out	@IMR,al 	; Tell the master PIC about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	test	SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
	jnz	short ENABLE_IRQS3 ; Yes, no slave PIC

; Ensure IRQ2 is enabled in the master PIC

	and	al,not (mask $IRQ2) ; Enable IRQ2
	out	@IMR,al 	; Tell the master PIC about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	call	LDISPTXTB	; Dump binary AL to error log
	LOGDISP '=master PIC'   ; Display to error log

	mov	al,OLDIMR1	; Get orig master IMR
	call	LDISPTXTB	; Dump binary AL to error log
	LOGDISP '=old master PIC' ; Display to error log

; Ensure IRQ12 is enabled in the slave PIC

	mov	al,not (mask $IRQ4) ; Disable all interrupts but these

; If any other interrupts are to be passed through and we're not in
; device SWAT or running with CLI in effect, enable 'em.

	test	DEVLOAD,@DEVL_LOAD ; Izit from device driver?
	jnz	short @F	; Jump if so

	test	[ebp].FORW_EFL.ELO,mask $IF ; Are interrupts enabled?
	jz	short @F	; Jump if not

	mov	ah,PASSTHROUGH2 ; Get mask for interrupts to enable in PIC2
	or	ah,OLDIMR2	; Mask off interrupts currently disabled
	and	al,ah		; Enable interrupts remaining
@@:
	out	@IMR2,al	; Tell the slave PIC about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	call	LDISPTXTB	; Dump binary AL to error log
	LOGDISP '=slave PIC'    ; Display to error log

	mov	al,OLDIMR2	; Get orig slave IMR
	call	LDISPTXTB	; Dump binary AL to error log
	LOGDISP '=old slave PIC' ; Display to error log

ENABLE_IRQS3:

; Read the master ISR and clear IRQ0 and/or IRQ1 if in-service

	mov	al,@GETISR	; Code to request ISR from 8259
	out	@ICR,al 	; Tell the master PIC about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	in	al,@ICR 	; Read the master ISR
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
	mov	ah,al		; Save for testing

	test	SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
	jnz	short @F	; Yes, no slave PIC

	test	ah,mask $IRQ2	; Check for IRQ2 in-service
	jz	short @F	; Not this time

	mov	al,@EOI2	; Get specific EOI for IRQ2
	out	@ICR,al 	; Ensure it's clear
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
@@:
	test	ah,mask $IRQ1	; Check for IRQ1 in-service
	jz	short @F	; Not this time

	in	al,@8255_A	; Clear the command
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	al,@EOI1	; Get specific EOI for IRQ1
	out	@ICR,al 	; Ensure it's clear
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
@@:
	test	ah,mask $IRQ0	; Check for IRQ0 in-service
	jz	short @F	; Not this time

	mov	al,@EOI0	; Get specific EOI for IRQ0
	out	@ICR,al 	; Ensure it's clear
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
@@:

; Read the slave ISR and clear IRQ12 if in-service

	test	SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
	jnz	short ENABLE_IRQS4 ; Yes, no slave PIC

	mov	al,@GETISR	; Code to request ISR from 8259
	out	@ICR2,al	; Tell the slave PIC about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	in	al,@ICR2	; Read the slave ISR
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
	mov	ah,al		; Save for testing

	test	ah,mask $IRQ4	; Check for IRQ12 in-service
	jz	short @F	; Not this time

	mov	al,@EOI4	; Get specific EOI for IRQ12
	out	@ICR2,al	; Ensure it's clear
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
@@:
ENABLE_IRQS4:
	REGREST <eax>		; Restore

	popfd			; Restore flags

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENABLE_IRQS endp		; End ENABLE_IRQS procedure
	FPPROC	ENABLE_PAD5 -- Enable Ctrl-Alt-Pad5
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable Ctrl-Alt-Pad5 to activate the debugger.

|

	or	I09_FLAG,mask $I09_PAD5 ; Mark as active

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENABLE_PAD5 endp		; End ENABLE_PAD5 procedure
	NPPROC	SAVE_IMR -- Save and Disable the IMR
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save the original IMR and disable them both.

|

	REGSAVE <eax>		; Save register

; Disable both the master and slave IMR

	in	al,@IMR 	; Get current master interrupt mask register
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	OLDIMR1,al	; Save to restore later

	test	SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
	jnz	short SAVE_IMR_NOXT1 ; Yes, so there's no slave controller

	in	al,@IMR2	; Get current slave IMR
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	OLDIMR2,al	; Save to restore later
SAVE_IMR_NOXT1:
	mov	al,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	xchg	al,OLDIBV0	; Swap 'em

	cmp	al,OLDIBV0	; Same value?
	je	short SAVE_IMR_DISABLE ; Jump if so

; * Program the 8259

	test	SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
	jz	short SAVE_IMR_NOXT2 ; Not this time

; ICW1

	mov	al,13h		; ICW1 -- edge-triggered, single, ICW4 needed
	out	@ICR,al 	; Send to 8259
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

; ICW2

	mov	al,OLDIBV0	; ICW2 -- start of 8259 vector
	out	@IMR,al 	; Send to 8259
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

; ICW3 (none because it's not in cascade mode)
; ICW4

	mov	al,09h		; ICW4 -- buffered slave, normal EOI, 8086 mode
	out	@IMR,al 	; Send to 8259
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	jmp	short SAVE_IMR_DISABLE ; Join common disable code

SAVE_IMR_NOXT2:

; ICW1 -- master 8259

	mov	al,11h		; ICW1 -- edge-triggered, cascade, ICW4 needed

	test	SWATINI.MD_ATTR,@MD_MCA ; Izit an MCA-compatible?
	jz	short @F	; Not this time

	or	al,08h		; Mark as level-triggered
@@:
	out	@ICR,al 	; Send to master 8259
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

; ICW2 -- master 8259

	mov	al,OLDIBV0	; ICW2 -- start of 8259 vector
	out	@IMR,al 	; Send to 8259
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

; ICW3 -- master 8259

	mov	al,@BIT2	; ICW3 -- master level 2
	out	@IMR,al 	; Send to master 8259
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

; ICW4 -- master 8259

	mov	al,01h		; ICW4 -- not SFNM, normal EOI, 8086 mode
	out	@IMR,al 	; Send to master 8259
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
SAVE_IMR_DISABLE:

; Disable the master IMR

	mov	al,0FFh 	; Disable all interrupts
	out	@IMR,al 	; Tell the master PIC about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	test	SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
	jnz	short SAVE_IMR_EXIT ; Jump if so

; Disable the slave IMR

	mov	al,0FFh 	; Disable all interrupts
	out	@IMR2,al	; Tell the slave PIC about it
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
SAVE_IMR_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_IMR endp			; End SAVE_IMR procedure
	NPPROC	REST_IMR -- Restore IMR to Original Value
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore IMR to original value.

|

	REGSAVE <eax>		; Save register

	mov	al,OLDIMR1	; Copy original master IMR value
	out	@IMR,al 	; Tell the PIC about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	test	SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
	jnz	short REST_IMR_EXIT ; Yes, no second controller

	mov	al,OLDIMR2	; Copy original slave IMR value
	out	@IMR2,al	; Tell the PIC about it
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
REST_IMR_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_IMR endp			; End REST_IMR procedure
	NPPROC	PURGE_KBUFF -- Purge The Keyboard Buffer
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Purge the keyboard buffer

On entry:

SS:EBP	==>	FORW_STR

|

	pushfd			; Save flags
	cli			; Disallow interrupts

	push	eax		; Save for a moment

	mov	eax,LBUF_HEAD	; Get pointer to buffer head
	mov	LBUF_TAIL,eax	; Save as tail pointer

	pop	eax		; Restore

	popfd			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PURGE_KBUFF endp		; End PURGE_KBUFF procedure
	NPPROC	GETNDKEY -- Wait for Keystroke Non-destructively
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return the next keystroke non-destructively, wait if necessary.

On entry:

SS:EBP	==>	FORW_STR

On exit:

AX	=	keyboard code

|

	pushfd			; Save flags

	sti			; Allow interrupts

	push	esi		; Save for a moment
GETNDKEY1:
	mov	esi,LBUF_HEAD	; Get pointer to buffer head

	cmp	esi,LBUF_TAIL	; Check against tail pointer
	jne	short @F	; Jump if key available

	call	REMOTE_ACT	; Call remote debugging function dispatcher
	jnc	short GETNDKEY1  ; Jump if no key available remotely

	call	PUTKEY		; Append keystroke to buffer

	jmp	short GETNDKEY2 ; Join common code


@@:
	lods	ds:[esi].ELO	; Get the head key
GETNDKEY2:
	cmp	al,0F0h 	; Check for special low-order flag
	jne	short GETNDKEY3 ; Not this time

	cmp	ah,00h		; Check for Alt-240
	je	short GETNDKEY3 ; Leave it alone

	mov	al,0		; Zero the special flag
GETNDKEY3:
	pop	esi		; Restore

	popfd			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETNDKEY endp			; End GETNDKEY procedure
	NPPROC	GETKEY -- Wait for Keystroke
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return the next keystroke, wait if necessary.
This routine behaves like AH=10h, INT 16h.

On entry:

SS:EBP	==>	FORW_STR

On exit:

AX	=	keyboard code

|

	pushfd			; Save flags

	sti			; Allow interrupts

	push	esi		; Save for a moment
GETKEY1:
	mov	esi,LBUF_HEAD	; Get pointer to buffer head

	cmp	esi,LBUF_TAIL	; Check against tail pointer
	jne	short @F	; Jump if key available

	call	REMOTE_ACT	; Call remote debugging function dispatcher
	jnc	short GETKEY1	; Jump if no key available

	jmp	short GETKEY3	; Join common exit


@@:
	lods	ds:[esi].ELO	; Get the head key

	cmp	esi,LBUF_END	; Check against buffer end
	jb	short GETKEY2	; Jump if within range

	mov	esi,LBUF_START	; Wrap to start of buffer
GETKEY2:
	mov	LBUF_HEAD,esi	; Save as new buffer head

	cmp	al,0F0h 	; Check for special low-order flag
	jne	short GETKEY3	; Not this time

	cmp	ah,00h		; Check for Alt-240
	je	short GETKEY3	; Leave it alone

	mov	al,0		; Zero the special flag
GETKEY3:
	pop	esi		; Restore

	popfd			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETKEY	endp			; End GETKEY procedure
	NPPROC	PUTKEY -- Append Key to Buffer
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Append the key in AX to the local buffer.

On entry:

AX	=	keycode

|

	push	edi		; Save register

	pushfd			; Save flags
	cli			; Disallow interrupts

	mov	edi,LBUF_TAIL	; Get offset of tail position
S32	stos	LBUF[edi]	; Save the word

	cmp	edi,LBUF_END	; At the end as yet?
	jb	short @F	; Not this time

	mov	edi,LBUF_START	; Get offset of start of buffer
@@:
	mov	LBUF_TAIL,edi	; Save for next time

	popfd			; Restore flags

	pop	edi		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PUTKEY	endp			; End PUTKEY procedure
	FPPROC	KEY_INT09 -- Local INT 09h Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local INT 09h handler.

|

	REGSAVE <eax,ebx,ecx,edi,es> ; Save registers

	cld			; Ensure string ops forwardly

	SETDATA es		; Set data selector into ES
	assume	es:DGROUP	; Tell the assembler about it

; Disable the keyboard if we're on an AT

	test	SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
	jnz	short @F	; Yes, no 8042

	mov	ah,@S2C_DIS	; Disable the keyboard interface
	call	U32_PPI_S2C	; Send command AH to 8042
				; Ignore return code
@@:
	in	al,@8255_A	; Get the scan code
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	sti			; Allow interrupts

	lea	edi,KEYSP_COD	; ES:EDI ==> special key table
	mov	ecx,KEYSP_CODLEN ; Get # keys in table
  repne scas	KEYSP_COD[edi]	; Search for it
	jne	short KEY_INT09_CHKE0 ; Jump if not found

	sub	edi,(type KEYSP_COD)+offset es:KEYSP_COD ; Convert to origin-0
LOG2 LOG2@KEYSP_COD,<type KEYSP_COD>
	shr	edi,LOG2@KEYSP_COD ; Convert to item index

	jmp	KEYSP_ACT[edi*(type KEYSP_ACT)] ; Take appropriate action


; Resend received -- mark as present

	public	KEY_INT09_RESEND
KEY_INT09_RESEND:
	or	LKB_FLAG2,mask $KB2_RESEND ; Mark as received

	jmp	KEY_INT09_EOI	; Join common EOI code


; Acknowledge received -- mark as present

	public	KEY_INT09_ACK
KEY_INT09_ACK:
	or	LKB_FLAG2,mask $KB2_ACK ; Mark as received

	jmp	KEY_INT09_EOI	; Join common EOI code


; Overrun received -- beep the speaker

	public	KEY_INT09_OVER
KEY_INT09_OVER:
	call	ERR_BEEP	; Beep it

	jmp	KEY_INT09_EOI	; Join common EOI code


; General marker code E0

	public	KEY_INT09_E0
KEY_INT09_E0:
	or	LKB_FLAG3,mask $KB3_E0 ; Mark as present

	jmp	KEY_INT09_EOI	; Join common EOI code


; General marker code E1

	public	KEY_INT09_E1
KEY_INT09_E1:
	or	LKB_FLAG3,mask $KB3_E1 ; Mark as present

	jmp	KEY_INT09_EOI	; Join common EOI code


KEY_INT09_CHKE0:
	btr	LKB_FLAG3,$KB3_E0 ; Last key a general marker?
	jnc	near ptr KEY_INT09_CHKE1 ; Not this time

	lea	edi,KEYE0_COD	; ES:EDI ==> special key table
	mov	ecx,KEYE0_CODLEN ; Get # keys in table
  repne scas	KEYE0_COD[edi]	; Search for it
	jne	short KEY_INT09_CHKE1 ; Jump if not found

	sub	edi,(type KEYE0_COD)+offset es:KEYE0_COD ; Convert to origin-0
LOG2 LOG2@KEYE0_COD,<type KEYE0_COD>
	shr	edi,LOG2@KEYE0_COD ; Convert to item index

	jmp	KEYE0_ACT[edi*(type KEYE0_ACT)] ; Take appropriate action


; L-Windows key press

	public	KEY_INT09_LWIN0
KEY_INT09_LWIN0:
	or	LKB_FLAG4,mask $KB4_LWIN ; Mark as pressed

	jmp	KEY_INT09_EOI	; Join common EOI code


; L-Windows key release

	public	KEY_INT09_LWIN1
KEY_INT09_LWIN1:
	and	LKB_FLAG4,not (mask $KB4_LWIN) ; Mark as released

	jmp	KEY_INT09_EOI	; Join common EOI code


; R-Windows key press

	public	KEY_INT09_RWIN0
KEY_INT09_RWIN0:
	or	LKB_FLAG4,mask $KB4_RWIN ; Mark as pressed

	jmp	KEY_INT09_EOI	; Join common EOI code


; R-Windows key release

	public	KEY_INT09_RWIN1
KEY_INT09_RWIN1:
	and	LKB_FLAG4,not (mask $KB4_RWIN) ; Mark as released

	jmp	KEY_INT09_EOI	; Join common EOI code


; X-Insert key press

	public	KEY_INT09_XINS0
KEY_INT09_XINS0:
	or	LKB_FLAG1,mask $KB1_INS ; Mark as pressed
	xor	LKB_FLAG,mask $KB_INS ; Toggle active state

	jmp	short KEY_INT09_E0COM ; Join common code


; X-Insert key release

	public	KEY_INT09_XINS1
KEY_INT09_XINS1:
	and	LKB_FLAG1,not (mask $KB1_INS) ; Mark as released

	jmp	KEY_INT09_EOI	; Join common EOI code


	public	KEY_INT09_E0COM
KEY_INT09_E0COM:
	mov	eax,edi 	; Copy byte index
	lea	edi,KEYE0_TAB	; ES:EDI ==> Key translate table

	jmp	KEY_INT09_XLAT	; Join common translate code


KEY_INT09_CHKE1:
	btr	LKB_FLAG3,$KB3_E1 ; Last key a general marker?
	jnc	short KEY_INT09_CHKSHF ; Not this time







; Check for shift keys

KEY_INT09_CHKSHF:
	lea	edi,KEYSF_COD	; ES:EDI ==> special key table
	mov	ecx,KEYSF_CODLEN ; Get # keys in table
  repne scas	KEYSF_COD[edi]	; Search for it
	jne	near ptr KEY_INT09_COM ; Jump if not found

	sub	edi,(type KEYSF_COD)+offset es:KEYSF_COD ; Convert to origin-0
LOG2 LOG2@KEYSF_COD,<type KEYSF_COD>
	shr	edi,LOG2@KEYSF_COD ; Convert to item index

	jmp	KEYSF_ACT[edi*(type KEYSF_ACT)] ; Take appropriate action


; Insert key press

	public	KEY_INT09_INS0
KEY_INT09_INS0:
	or	LKB_FLAG1,mask $KB1_INS ; Mark as pressed
	xor	LKB_FLAG,mask $KB_INS ; Toggle active state

	jmp	KEY_INT09_COM	; Join common code


; Insert key release

	public	KEY_INT09_INS1
KEY_INT09_INS1:
	and	LKB_FLAG1,not (mask $KB1_INS) ; Mark as released

	jmp	KEY_INT09_COM	; Join common code


; X-Delete key press

	public	KEY_INT09_XDEL
KEY_INT09_XDEL:

; Check for Ctrl- and Alt- keys pressed

	call	CHK_CTLALT	; Check Ctrl- and Alt- state
	je	short KEY_INT09_CAD ; Jump if both pressed

	jmp	short KEY_INT09_E0COM ; Join common code


; Pad5 key press

	public	KEY_INT09_PAD5
KEY_INT09_PAD5:
	test	I09_FLAG,mask $I09_PAD5 ; Treat it specially?
	jz	near ptr KEY_INT09_COM ; Not this time

; Check for Ctrl- and Alt- keys pressed

	call	CHK_CTLALT	; Check Ctrl- and Alt- state
	jne	near ptr KEY_INT09_COM ; Jump if not both pressed

	or	I09_FLAG,mask $I09_INT01 ; Mark as INT 01h needed on exit

	jmp	KEY_INT09_EOI	; Join common EOI code


; Delete key press

	public	KEY_INT09_DEL
KEY_INT09_DEL:

; Check for Ctrl- and Alt- keys pressed

	call	CHK_CTLALT	; Check Ctrl- and Alt- state
	jne	short KEY_INT09_COM ; Jump if not both pressed
KEY_INT09_CAD:
	call	CMD_REBOOT	; Reboot the system

; Padstar key pressed
; Check for s-PrtSc

	public	KEY_INT09_PRTSC
KEY_INT09_PRTSC:
	test	LKB_FLAG,(mask $KB_LSHFT) or (mask $KB_RSHFT) ; Either pressed?
	jz	short KEY_INT09_COM ; Join common code

; Print the screen to LPT1

PRTSC_REC record \
 $PRTSC_INSTR:1, \
 $PRTSC_ERRLOG:1,\
 $PRTSC_MEM:1


@PRTSC_INSTR  equ (mask $PRTSC_INSTR)  ; Print instruction window only
@PRTSC_ERRLOG equ (mask $PRTSC_ERRLOG) ; ...   error log text only
@PRTSC_MEM    equ (mask $PRTSC_MEM)    ; ...   memory screen text only

	xor	eax,eax 	; Assume not instruction display

	cmp	DSP_STATE,@DSP_ERRLOG ; Izit error log?
	jne	short @F	; Jump if not

	movzx	eax,LKB_FLAG	; Get keyboard flags
	and	eax,mask $KB_CTL ; Isolate the Ctl key
	shr	eax,$KB_CTL	; Shift to low order
	shl	eax,$PRTSC_ERRLOG ; Shift back
@@:
	cmp	DSP_STATE,@DSP_IREGS ; Izit instructions?
	jne	short @F	; Jump if not

	movzx	eax,LKB_FLAG	; Get keyboard flags
	and	eax,mask $KB_CTL ; Isolate the Ctl key
	shr	eax,$KB_CTL	; Shift to low order
	shl	eax,$PRTSC_INSTR ; Shift back
@@:
	cmp	DSP_STATE,@DSP_MEM ; Izit memory?
	jne	short @F	; Jump if not

	movzx	eax,LKB_FLAG	; Get keyboard flags
	and	eax,mask $KB_CTL ; Isolate the Ctl key
	shr	eax,$KB_CTL	; Shift to low order
	shl	eax,$PRTSC_MEM	; Shift back
@@:
	push	eax		; Pass flags as argument
	call	PRTSC		; Print it
;;;;;;; jnc	short KEY_INT09_EOI  ; Join common EOI code
;;;;;;;
;;;;;;; mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
;;;;;;; or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	jmp	KEY_INT09_EOI	; Join common EOI code


; Common routine to put key into buffer

KEY_INT09_COM:
	test	al,80h		; Check for key release
	jnz	near ptr KEY_INT09_EOI ; Ignore it

; The key is to be combined with the appropriate shift state
; (Unshift-, Shift-, Ctrl-, and  Alt-) and translated into a 16-bit quantity

	cmp	al,KEY_TABLEN	; Check for valid range
	jae	near ptr KEY_INT09_EOI ; Too big, ignore it

	test	LKB_FLAG,mask $KB_ALT ; Is an Alt-key pressed?
	jz	short KEY_INT09_XNUM ; Not this time

	lea	edi,KEY_NUM	; ES:EDI ==> numeric key table
	mov	ecx,KEY_NUMLEN	; Get # keys in table
  repne scas	KEY_NUM[edi]	; Search for it
	jne	short KEY_INT09_XNUM ; Jump if not found

	mov	al,10		; Multiplier
	mul	ALT_NUM 	; Shift previous value over by 10

	sub	edi,(type KEY_NUM)+offset es:KEY_NUM ; Convert to origin-0
LOG2 LOG2@KEYNUM_COD,<type KEYSP_COD>
	shr	edi,LOG2@KEYNUM_COD ; Convert to item index

	add	ax,di		; Add into previous value
	mov	ALT_NUM,al	; Save in accumulator

	jmp	KEY_INT09_EOI	; Continue on


KEY_INT09_XNUM:
	lea	edi,KEY_TAB	; ES:EDI ==> key translate table
KEY_INT09_XLAT:
	movzx	ebx,al		; Copy to index register

	mov	al,LKB_FLAG	; Get current shift states
	and	eax,(mask $KB_CTL) or (mask $KB_LSHFT) or (mask $KB_RSHFT) ; Isolate

; Because some International keyboards distinguish between
; the left and right Alt-keys, we use separate bits for them

	test	LKB_FLAG1,mask $KB1_LALT ; Is Left Alt-key pressed?
	setnz	ah		; AH = 1 iff pressed
	shl	ah,$KB_ALT+1	; Shift into position
	or	al,ah		; Include in shift states

	test	LKB_FLAG3,mask $KB3_RALT ; Is Right Alt-key pressed?
	setnz	ah		; AH = 1 iff pressed
	shl	ah,$KB_ALT	; Shift into position
	or	al,ah		; Include in shift states
	mov	ah,0		; Zero to use EAX as dword

	mov	al,SHIFT_PREC[eax] ; Translate shift states

	mov	ah,KEY_TOG[ebx] ; Get toggle bits

	and	ah,LKB_FLAG	; Isolate CapsLock and NumLock
	jz	short @F	; Jump if nothing there

	mov	ah,0		; Zero to use EAX as dword

	cmp	al,1		; Izit a shifted or unshifted state?
	ja	short @F	; Not this time

	xor	al,1		; Toggle state
@@:
	imul	ebx,5		; Times five to index table of five words
	add	ebx,eax 	; Include shift states in scancode
	mov	ax,es:[ebx*2+edi] ; Get the key

	cmp	ax,-1		; Check for invalid key
	je	near ptr KEY_INT09_EOI ; Ignore it

	call	PUTKEY		; Append the key in AX to the local buffer

	test	SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
	jz	short @F	; Not this time

; Ensure the XT keyboard is enabled

	call	ENABLE8255	; Enable it
@@:
	jmp	KEY_INT09_EOI	; Join common EOI code


; Left control key press

	public	KEY_INT09_LCTL0
KEY_INT09_LCTL0:
	and	LKB_FLAG3,not (mask $KB3_E0) ; Remove general marker flag
	or	LKB_FLAG1,mask $KB1_LCTL ; Mark as Left Ctl-key pressed
	or	LKB_FLAG,mask $KB_CTL ; Mark as any Ctl-key pressed

	jmp	KEY_INT09_EOI	; Join common EOI code


; Left control key release

	public	KEY_INT09_LCTL1
KEY_INT09_LCTL1:
	and	LKB_FLAG3,not (mask $KB3_E0) ; Remove general marker flag
	and	LKB_FLAG1,not (mask $KB1_LCTL) ; Mark as Left Ctl-key released

	test	LKB_FLAG3,mask $KB3_RCTL ; Is the Right Ctl-key pressed?
	jnz	short @F	; Yes, skip this

	and	LKB_FLAG,not (mask $KB_CTL) ; Mark as neither Ctl-key pressed
@@:
	jmp	KEY_INT09_EOI	; Join common EOI code


; Right control key press

	public	KEY_INT09_RCTL0
KEY_INT09_RCTL0:
	and	LKB_FLAG3,not (mask $KB3_E0) ; Remove general marker flag
	or	LKB_FLAG3,mask $KB3_RCTL ; Mark as Right Ctl-key pressed
	or	LKB_FLAG,mask $KB_CTL ; Mark as any Ctl-key pressed

	jmp	KEY_INT09_EOI	; Join common EOI code


; Right control key release

	public	KEY_INT09_RCTL1
KEY_INT09_RCTL1:
	and	LKB_FLAG3,not (mask $KB3_E0) ; Remove general marker flag
	and	LKB_FLAG3,not (mask $KB3_RCTL) ; Mark as Right Ctl-key released

	test	LKB_FLAG1,mask $KB1_LCTL ; Is the Left Ctl-key pressed?
	jnz	short @F	; Yes, skip this

	and	LKB_FLAG,not (mask $KB_CTL) ; Mark as neither Ctl-key pressed
@@:
	jmp	KEY_INT09_EOI	; Join common EOI code


; Left Alt-key press

	public	KEY_INT09_LALT0
KEY_INT09_LALT0:
	and	LKB_FLAG3,not (mask $KB3_E0) ; Remove general marker flag
	or	LKB_FLAG1,mask $KB1_LALT ; Mark as Left Alt-key pressed
	or	LKB_FLAG,mask $KB_ALT ; Mark as any Alt-key pressed

	jmp	KEY_INT09_EOI	; Join common EOI code


; Left Alt-key release

	public	KEY_INT09_LALT1
KEY_INT09_LALT1:
	and	LKB_FLAG3,not (mask $KB3_E0) ; Remove general marker flag
	and	LKB_FLAG1,not (mask $KB1_LALT) ; Mark as Left Alt-key released

	test	LKB_FLAG3,mask $KB3_RCTL ; Is the Right Alt-key pressed?
	jnz	short @F	; Yes, skip this

	and	LKB_FLAG,not (mask $KB_ALT) ; Mark as neither Alt-key pressed
@@:
	jmp	short KEY_INT09_ALT1COM ; Join common Alt-ley release code


; Right Alt-key press

	public	KEY_INT09_RALT0
KEY_INT09_RALT0:
	or	LKB_FLAG3,mask $KB3_RALT ; Mark as Right Alt-key pressed
	or	LKB_FLAG,mask $KB_ALT ; Mark as any Alt-key pressed

	jmp	KEY_INT09_EOI	; Join common EOI code


; Right Alt-key release

	public	KEY_INT09_RALT1
KEY_INT09_RALT1:
	and	LKB_FLAG3,not (mask $KB3_RALT) ; Mark as Right Alt-key released

	test	LKB_FLAG1,mask $KB1_LALT ; Is the Left Alt-key pressed?
	jnz	short @F	; Yes, skip this

	and	LKB_FLAG,not (mask $KB_ALT) ; Mark as neither Alt-key pressed
@@:
KEY_INT09_ALT1COM:
	test	LKB_FLAG,mask $KB_ALT ; Is either Alt-key pressed?
	jnz	short @F	; Yes

	xor	ax,ax		; Zero the register
	xchg	al,ALT_NUM	; Swap and zero

	cmp	al,0		; Is Alt-numpad active?
	je	short @F	; Not this time

	call	PUTKEY		; Append the key in AX to the local buffer
@@:
	jmp	KEY_INT09_EOI	; Join common EOI code


; Left Shift-key press

	public	KEY_INT09_LSHFT0
KEY_INT09_LSHFT0:
	or	LKB_FLAG,mask $KB_LSHFT ; Mark as pressed

	jmp	short KEY_INT09_EOI ; Join common EOI code


; Left Shift-key release

	public	KEY_INT09_LSHFT1
KEY_INT09_LSHFT1:
	and	LKB_FLAG,not (mask $KB_LSHFT) ; Mark as released

	jmp	short KEY_INT09_EOI ; Join common EOI code


; Right Shift-key press

	public	KEY_INT09_RSHFT0
KEY_INT09_RSHFT0:
	or	LKB_FLAG,mask $KB_RSHFT ; Mark as pressed

	jmp	short KEY_INT09_EOI ; Join common EOI code


; Right Shift-key release

	public	KEY_INT09_RSHFT1
KEY_INT09_RSHFT1:
	and	LKB_FLAG,not (mask $KB_RSHFT) ; Mark as released

	jmp	short KEY_INT09_EOI ; Join common EOI code


; Caps Lock pressed

	public	KEY_INT09_CAPL
KEY_INT09_CAPL:
	xor	LKB_FLAG,mask $CP ; Toggle state

	jmp	short KEY_INT09_LED ; Join common LED setting code


; Num Lock pressed

	public	KEY_INT09_NUML
KEY_INT09_NUML:
	xor	LKB_FLAG,mask $NM ; Toggle state

	jmp	short KEY_INT09_LED ; Join common LED setting code


; Scroll Lock pressed

	public	KEY_INT09_SCRL
KEY_INT09_SCRL:
	xor	LKB_FLAG,mask $SCRL ; Toggle state
KEY_INT09_LED:
	cli			; Disable interrupts

	bts	LKB_FLAG2,$KB2_UPD ; Test and set as updating
	jc	short KEY_INT09_EOI ; Skip if already in progress

; Ensure EOI sent

	mov	al,@EOI 	; Non-specific EOI
	out	@ICR,al 	; Tell the PIC about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	ah,@S2K_LED	; Set/reset LED Indicators
	call	U32_PPI_S2K_K2S ; Send command AH to keyboard, response in AL
	jc	short KEY_INT09_LEDERR ; Jump if keyboard not responding

	mov	ah,LKB_FLAG	; Get keyboard flags
	and	ah,(mask $KB_CAPL) or (mask $KB_NUML) or (mask $KB_SCRL) ; Isolate
	shr	ah,4		; Shift to low-order nibble
	call	U32_PPI_S2K_K2S ; Send command AH to keyboard, response in AL
				; Ignore return code
KEY_INT09_LEDERR:
	and	LKB_FLAG2,not (mask $KB2_UPD) ; No longer updating LEDs

	jmp	short KEY_INT09_ENA ; Join common enable code


; Ensure EOI sent

	public	KEY_INT09_EOI
KEY_INT09_EOI:
	mov	al,@EOI 	; Non-specific EOI
	out	@ICR,al 	; Tell the PIC about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

; Enable the keyboard

KEY_INT09_ENA:
	test	SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
	jnz	short KEY_INT09_XT ; Yes, use different approach

	mov	ah,@S2C_ENA	; Enable the keyboard interface
	call	U32_PPI_S2C	; Send command AH to 8042
				; Ignore return code
	jmp	short KEY_INT09_EXIT ; Join common exit code

KEY_INT09_XT:
	in	al,@8255_B	; Get the control port
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	or	al,mask $KEYB	; Toggle bit for keyboard
	out	@8255_B,al	; Send back to 8255
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	and	al,not mask $KEYB ; Enable keyboard
	out	@8255_B,al	; Send back to 8255
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
KEY_INT09_EXIT:
	btr	I09_FLAG,$I09_INT01 ; Signal INT 01h on exit?
	REGREST <es,edi,ecx,ebx,eax> ; Restore
	assume	es:nothing	; Tell the assembler about it
	jnc	short @F	; Not this time

	or	[esp].IRETD_EFL,mask $TF ; Set the trap flag
@@:
	iretd			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

KEY_INT09 endp			; End KEY_INT09 procedure
	NPPROC	CMD_REBOOT -- Force an immediate reboot
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

This is called from SWAT's local Int 9 handler, and also by the REBOOT
command (useful for remote debugging).

No return.

|

	mov	eax,es		; Get DGROUP selector
	mov	ds,eax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

; If DVGA is enabled, disable it

	test	ARG_FLAG,@ARG_DVGA ; Izit specified?
	jz	short @F	; Jump if not

	call	DVGASEL0	; Select original VGA screen
@@:
	mov	ax,1234h	; Warm boot value

	test	LC2_FLAG,@LC2_COLDBOOT ; Do we want to cold boot?
	jz	short @F	; Jump if not

	xchg	ah,al		; Cold boot value
@@:
	mov	es,COMMON.FILE_4GB ; Address all of memory
	assume	es:AGROUP	; Tell the assembler about it

	call	GETBDA		; Return with EBX=linear address of BIOS data area
	jc	short REBOOT_NOXBDA ; Jump if something went wrong

	assume	es:BIOSDATA	; Tell the assembler about it

	mov	RESET_FLAG[ebx],ax ; Set flag to avoid or force memory test

; If we've relocated the XBDA to high DOS, move it back to low DOS
; so the startup code in the BIOS can reference the values therein.

	mov	ax,XBDA_SEG[ebx] ; Get the XBDA segment

	cmp	ax,0A000h	; Izit in high DOS?
	jb	short REBOOT_NOXBDA ; Jump if not

	movzx	esi,ax		; Copy as source segment
	shl	esi,4-0 	; Convert from paras to bytes

	mov	edi,9000h	; Use arbitrary segment as destination
	mov	XBDA_SEG[ebx],di ; Save as new XBDA segment
	shl	edi,4-0 	; Convert from paras to bytes

	assume	es:AGROUP	; Tell the assembler about it

	movzx	ecx,AGROUP:[esi].LO ; Get size of XBIOS in 1KB
	shl	ecx,10-2	; Convert from 1KB to dwords

	cld			; String ops forwardly
S32 rep movs	<AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy back to where it used to be
REBOOT_NOXBDA:

; If we're on an MCA machine, disable the watchdog timer
; to avoid spurious NMI

	test	SWATINI.MD_ATTR,@MD_MCA ; Izit an MCA-compatible?
	jz	short @F	; Not this time

	call	HOUSE_DOG	; Disable watchdog timer
@@:
	test	SWATINI.MD_ATTR,@MD_INBRD ; Izit an Inboard/AT?
	jz	short REBOOT_XINBRD ; Jump if not

; Ensure A20 gated on (huh????)

	mov	ah,@S2C_WOUT	; Write output port byte
	mov	al,@S2O_E20	; Tell it to enable A20
;;;;;;; or	al,10010000b	; Ensure 6805 data line high,
				; output buffer full
	call	U32_PPI_S2C_S2K ; Write command AH, data AL to 8042

	mov	al,0		; Value for high speed (80h = slow)
	mov	dx,674h 	; I/O port for speed
	out	dx,al		; Tell the board to run at high speed
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	al,0		; Value to disable cache (1 = enable)
	mov	dx,670h 	; I/O port for cache
	out	dx,al		; Tell the board to stop caching
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
REBOOT_XINBRD:
	test	DBG_FLAG,@DBG_TRIP ; Using triple fault method?
	jz	short REBOOT_XTRIP ; Jump if not

	mov	ebx,cr0 	; Get current control register
	and	ebx,not ((mask $PG) or (mask $PE)) ; Disable paging and PM
	xor	eax,eax 	; A handy zero for CR3

	LIDTD	IDT_REBOOT	; Set IDT limit to zero

; On some machines, it appears to be important that the OUT
; instruction following the MOV into CR0 which disables paging and
; protect enable be in the prefetch queue so the CPU doesn't
; generate another bus event.  If we flush the PIQ now, the CPU
; fills the PIQ entirely before executing the first instruction.

; This technique doesn't work here as this segment is byte-aligned.

;;;;;;; DDALIGN @SWAT_KEY_PROG,4-2 ; Align so that MOV CR0,EBX
;;;;;;; 			; is on a dword boundary
;;;;;;; jmp	short $+2	; Flush the prefetch instruction queue
;;;;;;;
	mov	cr0,ebx 	; Tell the CPU about it
	mov	cr3,eax 	; No more paging

COMMENT|

To reboot the system, we set the IDT limit to zero and then issue an
interrupt (any interrupt).  This causes a GP Fault because the
interrupt # is beyond the IDT limit.  This then causes a Double Fault
because the GP Fault interrupt # is beyond the IDT limit.  This then
causes a Triple Fault (system reset) because the Double Fault
interrupt # is beyond the IDT limit.  This way, we don't have to
depend upon peripherals such the 8042 which might or might not work
correctly.

|

	int	03h		; Issue an interrupt
REBOOT_XTRIP:
	mov	al,@S2C_SHUT	; Command for system shutdown

	mov	ebx,cr0 	; Get current control register
	and	ebx,not ((mask $PG) or (mask $PE)) ; Disable paging and PM
	mov	cr0,ebx 	; Tell the CPU about it

	out	@8042_ST,al	; Initiate system shutdown
	hlt
	jmp	short $ 	; We're not going anywhere

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_REBOOT endp 		; End CMD_REBOOT procedure
	NPPROC	PRTSC -- Print Screen
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Print the screen to LPT1

On exit:

CF	=	0 if all went well
	=	1 if something went wrong

|

PRTSC_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
PRTSC_FLAG dd	?		; Flags (see PRTSC_REC)

PRTSC_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ebx,ecx,edx,esi,ds> ; Save registers

	mov	ds,COMMON.FILE_4GB ; Get our all memory descriptor
	assume	ds:AGROUP	; Tell the assembler about it

	xor	ebx,ebx 	; Zero to use as dword
	mov	bx,seg BIOSDATA ; Get segment of BIOS data area
	shl	ebx,4-0 	; Convert from paras to bytes
	assume	ds:BIOSDATA	; Tell the assembler about it

	mov	dx,PRINTER_BASE[ebx+(1-1)*(type PRINTER_BASE)] ; Get LPT1 base
	mov	bl,PRINT_TIM_OUT[ebx+(1-1)*(type PRINT_TIM_OUT)] ; Get LPT1 timeout base

	lds	esi,VIDBASE_FVEC ; DS:ESI ==> screen base to print
	assume	ds:nothing	; Tell the assembler about it

	mov	ecx,@NROWS	; ECX = # rows to print

	test	[ebp].PRTSC_FLAG,@PRTSC_MEM ; Printing memory screen window only?
	jz	short @F	; Jump if not

	sub	ecx,2		; Skip over screen title & command line
	add	esi,@NCOLS * 2	; Add to skip over the screen title
@@:
	test	[ebp].PRTSC_FLAG,@PRTSC_ERRLOG ; Printing error log window only?
	jz	short @F	; Jump if not

	sub	ecx,2		; Skip over screen title & command line
	add	esi,@NCOLS * 2	; Add to skip over the screen title
@@:
	test	[ebp].PRTSC_FLAG,@PRTSC_INSTR ; Printing instruction window only?
	jz	short @F	; Jump if not

	dec	ecx		; Back off to the command line
	imul	ecx,@NCOLS * 2	; Times # (Char,Attr) pairs per line
	add	esi,ecx 	; Add to get to start of command line
	mov	ecx,INSTRNLN	; # rows in instr window
	imul	eax,ecx,@NCOLS * 2 ; Times # (Char,Attr) pairs per line
	sub	esi,eax 	; Less # (Char,Attr) pairs in instr window
@@:
PRTSC_NEXTROW:
	push	ecx		; Save for a moment

	mov	ecx,@NCOLS	; ECX = # cols to print
PRTSC_NEXTCOL:
	lods	ds:[esi].ELO	; Get next character/attribute

	call	PRINTL		; Launder the character
	call	PRINT		; Print the character in AL
	jc	short @F	; Jump if something went wrong (note CF=1)

	loop	PRTSC_NEXTCOL	; Jump if more columns to print
@@:
	pop	ecx		; Restore row count
	jc	short PRTSC_EXIT ; Jump if something went wrong (note CF=1)

	mov	al,CR		; End the line
	call	PRINT		; Print the character in AL
	jc	short PRTSC_EXIT ; Jump if something went wrong (note CF=1)

	mov	al,LF		; Got to the next line
	call	PRINT		; Print the character in AL
	jc	short PRTSC_EXIT ; Jump if something went wrong (note CF=1)

	loop	PRTSC_NEXTROW	; Jump if more rows to print

	clc			; Indicate all went well
PRTSC_EXIT:
	REGREST <ds,esi,edx,ecx,ebx,eax> ; Restore
	assume	ds:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PRTSC	endp			; End PRTSC procedure
	NPPROC	PRINTL -- Print Launder
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Launder a character washing out characters between 00-1F and 80-9F.

|

	push	eax		; Save for a moment
	and	al,not @BIT7	; Clear high-order bit
	cmp	al,1Fh		; Check against upper limit
	pop	eax		; Restore
	ja	short @F	; Jump if

	mov	al,'.'          ; Use substitute character
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PRINTL	endp			; End PRINTL procedure
	NPPROC	PRINT -- Print A Character
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Print a character.  Launder characters from 00h-1Fh and 80h-9Fh to avoid
confusion at the printer end with control characters.

On entry:

AL	=	character to print
DX	=	I/O port
BL	=	timeout value

On exit:

CF	=	0 if all went OK
	=	1 otherwise

|

	REGSAVE <eax,ecx,edx>	; Save registers

	out	dx,al		; Print the character
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	inc	dx		; Skip to status port

; Wait for the printer to clear

	movzx	ecx,bl		; Copy timer value
	shl	ecx,16+2	; Times 4*64K
PRINT1:
	in	al,dx		; Get status
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	test	al,@BIT7	; Check busy bit
	jnz	short PRINT2	; Jump if OK

	loop	PRINT1		; Jump if still patient

	stc			; Indicate something went wrong

	jmp	short PRINT_EXIT ; Join common exit code

PRINT2:
	inc	dx		; Skip to command port
	mov	al,0Dh		; Strobe high

	out	dx,al
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	al,0Ch		; Strobe low
	out	dx,al
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	clc			; Indicate all went well
PRINT_EXIT:
	REGREST <edx,ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PRINT	endp			; End PRINT procedure
	NPPROC	CHK_CTLALT -- Check Ctrl- and Alt- State
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check Ctrl- and Alt- state

On exit:

ZF	=	0 if Ctrl- and Alt- both pressed
	=	1 otherwise

|

	REGSAVE <eax>		; Save register

	mov	ah,LKB_FLAG	; Get keyboard shift states
	and	ah,(mask $KB_CTL) or (mask $KB_ALT) ; Isolate Ctl- and Alt-

	cmp	ah,(mask $KB_CTL) or (mask $KB_ALT) ; Check for Ctl-Alt-Del

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHK_CTLALT endp 		; End CHK_CTLALT procedure
	NPPROC	HOUSE_DOG -- Disable Watchdog Timer
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable watchdog timer on MCA machine.

|

	REGSAVE <eax,ds>	; Save registers

	in	al,@8255_B	; Read System Control Port B
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	or	al,mask $CLRIRQ0 ; Set high-order bit to reset IRQ0
	out	@8255_B,al	; Reset the level for level-triggered ints
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	al,@TIMER_MSB	; R/W counter bits 0-7 only
	out	@8253_CTL3,al	; Tell the 8253 about it
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

; Reset the Watchdog timer value in the XBIOS data area
; unless we're running under Windows 3

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short HOUSE_DOG_EXIT ; Jump if so

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	mov	ds,COMMON.FILE_4GB ; Address it
	assume	ds:BIOSDATA	; Tell the assembler about it

	xor	eax,eax 	; Zero entire register
	mov	ax,seg BIOSDATA ; Get segment of BIOS data area
	shl	eax,4-0 	; Convert from paras to bytes
	movzx	eax,PRINTER_BASE[eax+(4-1)*(type PRINTER_BASE)] ; Get XBIOS base
	shl	eax,4-0 	; Convert from paras to bytes
	mov	ds:[eax+0039h].LO,0 ; Zero it
HOUSE_DOG_EXIT:
	REGREST <ds,eax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HOUSE_DOG endp			; End HOUSE_DOG procedure
	NPPROC	ENABLE8255 -- Enable XT Keyboard
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable keyboard on XT through the 8255.

|

	REGSAVE <eax>		; Save register

	in	al,@8255_B	; Get the control port
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	and	al,not @BIT2	; Ensure reset to read key

	mov	ah,al		; Save the value
	or	al,mask $KEYB	; Reset bit for keyboard
	out	@8255_B,al	; Tell the 8255 about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

;;;;;;; and	al,not (mask $KEYB) ; Enable keyboard
	mov	al,ah		; Restore original value
	out	@8255_B,al	; Tell the 8255 about it
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENABLE8255 endp 		; End ENABLE8255 procedure

PPI_S2C_MAC macro PREF

	NPPROC	PREF&PPI_S2C -- PPI System to Controller
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI System to Controller.
Send a command to the controller (8042).

Note that it's the caller's responsibility to ensure that
the 8042 output buffer is clear.

1.  Wait for the input buffer to clear to avoid overrun.
2.  Send the command in AH to the keyboard controller port 64h.
    There is no acknowledgement of this command.

On entry:

AH	=	command
IF	=	0

On exit:

CF	=	1 if keyboard controller not responding
	=	0 otherwise

|

	call	PREF&WAITIBUF_CLR ; Wait for input buffer to clear
	jc	short @F	; Error, controller not reading data (note CF=1)

	xchg	al,ah		; Swap to put command in AL
	out	@8042_ST,al	; Send the command
	call	PREF&DRAINPIQ	; Drain the Prefetch Instruction Queue
	xchg	al,ah		; Restore
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&PPI_S2C endp		; End PREF&PPI_S2C procedure

	endm			; End PPI_S2C_MAC

	PPI_S2C_MAC U32_	; Define in PGROUP

PPI_S2C_S2K_MAC macro PREF

	NPPROC	PREF&PPI_S2C_S2K -- PPI System to Controller, System to Keyboard
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI System to Controller, System to Keyboard.

Note that it's the caller's responsibility to ensure that
the 8042 output buffer is clear.

1.  Send the command to the 8042.
2.  Send the data to the 8042.

On entry:

AH	=	S2C command
AL	=	byte to send
IF	=	0

On exit:

CF	=	0 if all went OK
	=	1 otherwise

|

	call	PREF&PPI_S2C	; Send command AH to 8042
	jc	short @F	; Jump if something went wrong (note CF=1)

	call	PREF&WAITIBUF_CLR ; Wait for input buffer to clear
	jc	short @F	; Error, controller not reading data (note CF=1)

	out	@8255_A,al	; Send data AL to 8042
	call	PREF&DRAINPIQ	 ; Drain the Prefetch Instruction Queue
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&PPI_S2C_S2K endp		; End PREF&PPI_S2C_S2K procedure

	endm			; End PPI_S2C_S2K_MAC

	PPI_S2C_S2K_MAC U32_	; Define in PGROUP

PPI_S2C_K2S_MAC macro PREF

	NPPROC	PREF&PPI_S2C_K2S -- PPI System to Controller, Keyboard to System
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI System to Controller, Keyboard to System
Send a command to the controller (8042), wait for a response.

Note that it's the caller's responsibility to ensure that
the 8042 output buffer is clear.

1.  Send the command to the 8042.
2.  Wait for the output buffer to fill.
3.  Read the response.

Note that resend does not occur with the controller (8042)
(although it can with the keyboard (6805)).

On entry:

AH	=	S2C command
IF	=	0

On exit:

CF	=	0 if all went OK
	=	1 otherwise

AL	=	byte read (if CF=0)

|

	call	PREF&PPI_S2C	; Send command AH to 8042
	jc	short @F	; Jump if something went wrong (note CF=1)

	call	PREF&PPI_K2S	; Wait for a response, returned in AL
				; Return with CF significant
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&PPI_S2C_K2S endp		; End PREF&PPI_S2C_K2S procedure

	endm			; End PPI_S2C_K2S_MAC

PPI_S2K_MAC macro PREF

	NPPROC	PREF&PPI_S2K -- PPI System to Keyboard
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI System to Keyboard.
Send command to keyboard.

1.  Wait for the input buffer to clear to avoid overrun.
2.  Send the command in AH to the keyboard port 60h.
    There is no acknowledgement of this command.

On entry:

AH	=	command to send
IF	=	0

On exit:

CF	=	1 if timeout
	=	0 otherwise

AL	=	keyboard response if CF=0

|

	call	PREF&WAITIBUF_CLR ; Wait for input buffer to clear
	jc	short @F	; Error, controller not reading data (note CF=1)

	xchg	al,ah		; Swap to put command in AL
	out	@8255_A,al	; Issue the command
	call	PREF&DRAINPIQ	 ; Drain the Prefetch Instruction Queue
	xchg	al,ah		; Restore
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&PPI_S2K endp		; End PREF&PPI_S2K procedure

	endm			; End PPI_S2K_MAC

	PPI_S2K_MAC U32_	; Define in PGROUP

PPI_K2S_MAC macro PREF

	NPPROC	PREF&PPI_K2S -- PPI Keyboard to System
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI Keyboard to System.
Wait for a response from the keyboard or its controller.

On entry:

IF	=	0

On exit:

CF	=	1 if no response
	=	0 otherwise

AL	=	response if CF=0

|

	call	PREF&WAITOBUF_SET ; Wait for the output buffer to fill
	jc	short @F	; Jump if no timely response (note CF=1)

	in	al,@8255_A	; Read in the code
	call	PREF&DRAINPIQ	; Drain the Prefetch Instruction Queue
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&PPI_K2S endp		; End PREF&PPI_K2S procedure

	endm			; End PPI_K2S_MAC

	PPI_K2S_MAC U32_	; Define in PGROUP

PPI_S2K_K2S_MAC macro PREF

	NPPROC	PREF&PPI_S2K_K2S -- PPI System to Keyboard, Keyboard to System
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI System to Keyboard, Keyboard to System.
Send command to keyboard (6805), wait for its response.

Note that it's the caller's responsibility to ensure that
the 6805 output buffer is clear.

1.  Send the command to the 6805.
2.  Wait for the output buffer to fill.
3.  Read the response.
4.  Check for resend.

On entry:

AH	=	command to send
IF	=	0

On exit:

CF	=	1 if timeout
	=	0 otherwise

AL	=	keyboard response if CF=0

|

	push	ecx		; Save for a moment

	mov	ecx,6		; # retries of resend (arbitrary value)
PREF&PPI_S2K_K2S_AGAIN:
	call	PREF&PPI_S2K	; Send command AH to 6805
	jc	short PREF&PPI_S2K_K2S_EXIT ; Jump if something went wrong (note CF=1)

	call	PREF&PPI_K2S	; Wait for a response, returned in AL
	jc	short PREF&PPI_S2K_K2S_EXIT ; Jump if something went wrong (note CF=1)

	cmp	al,@K2S_RESEND	; Izit a resend?
	clc			; In case not
	jne	short PREF&PPI_S2K_K2S_EXIT ; Jump if not (note CF=0)

	loop	PREF&PPI_S2K_K2S_AGAIN ; Jump if more retries

	stc			; Indicate something went wrong
PREF&PPI_S2K_K2S_EXIT:
	pop	ecx		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&PPI_S2K_K2S endp		; End PREF&PPI_S2K_K2S procedure

	endm			; End PPI_S2K_K2S_MAC

	PPI_S2K_K2S_MAC U32_	; Define in PGROUP

WAITIBUF_CLR_MAC macro PREF

	NPPROC	PREF&WAITIBUF_CLR -- Wait For The Input Buffer To Clear
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Wait for the one-byte input buffer to clear.

On entry:

IF	=	0

On exit:

CF	=	0 if buffer empty
	=	1 otherwise

|

	REGSAVE <eax,ecx>	; Save registers

	mov	ecx,60000h	; Loop counter (arbitrary value)
	in	al,@8255_B	; Get port B value
	and	al,mask $REFRESH ; Isolate refresh bit
	mov	ah,al		; Save for later use
PREF&WAITIBUF_CLR1:
	test	PREF&SWATINI.MD_ATTR,@MD_MCA ; Izit an MCA-compatible?
	jz	short PREF&WAITIBUF_CLR2 ; Jump if not

; Wait for next refresh

@@:
	in	al,@8255_B	; Get port B value
	and	al,mask $REFRESH ; Isolate refresh bit

	cmp	al,ah		; Izit the same as last time?
	je	short @B	; Jump if so

	mov	ah,al		; Save for next time
PREF&WAITIBUF_CLR2:
	in	al,@8042_ST	; Get status from keyboard
	call	PREF&DRAINPIQ	; Drain the Prefetch Instruction Queue

	and	al,mask $INPFULL ; Check Input Buffer Full flag
	loopnz	PREF&WAITIBUF_CLR1 ; Last char not read as yet
	jz	short PREF&WAITIBUF_CLR_EXIT ; Jump if buffer clear (note CF=0)

	stc			; Indicate something went wrong
PREF&WAITIBUF_CLR_EXIT:
	REGREST <ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&WAITIBUF_CLR endp		; End PREFWAITIBUF_CLR procedure

	endm			; End WAITIBUF_CLR_MAC

	WAITIBUF_CLR_MAC U32_	; Define in PGROUP

WAITOBUF_SET_MAC macro PREF

	NPPROC	PREF&WAITOBUF_SET -- Wait for Output Buffer Full
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Wait for the output buffer to fill.

On entry:

IF	=	0

On exit:

CF	=	1 if no response
	=	0 otherwise

|

	REGSAVE <eax,ecx>	; Save registers

; Wait for a response

	mov	ecx,60000h	; Loop counter (arbitrary value)
PREF&WAITOBUF_SET1:
	in	al,@8042_ST	; Get status from keyboard
	call	PREF&DRAINPIQ	; Drain the Prefetch Instruction Queue

	and	al,mask $OUTFULL ; Check Output Buffer Full flag
	loopz	PREF&WAITOBUF_SET1 ; Jump if no response as yet
	jnz	short PREF&WAITOBUF_SET_EXIT ; Join common exit code (note CF=0)

	stc			; Indicate something went wrong
PREF&WAITOBUF_SET_EXIT:
	REGREST <ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&WAITOBUF_SET endp		; End PREF&WAITOBUF_SET procedure

	endm			; End WAITOBUF_SET_MAC

	WAITOBUF_SET_MAC U32_	; Define in PGROUP

WAITOBUF_CLR_MAC macro PREF

	NPPROC	PREF&WAITOBUF_CLR -- Wait For The Output Buffer To Clear
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

IF	=	0

Wait for the one-byte output buffer to clear.

|

	push	eax		; Save for a moment
PREF&WAITOBUF_CLR1:
	in	al,@8042_ST	; Get status from keyboard
	call	PREF&DRAINPIQ	; Drain the Prefetch Instruction Queue

	and	al,mask $OUTFULL ; Check Output Buffer Full flag
	jz	short PREF&WAITOBUF_CLR_EXIT ; Jump if buffer clear before

	in	al,@8255_A	; Purge the character
	call	PREF&DRAINPIQ	; Drain the Prefetch Instruction Queue

	jmp	short PREF&WAITOBUF_CLR1 ; Go around again

PREF&WAITOBUF_CLR_EXIT:
	pop	eax		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&WAITOBUF_CLR endp		; End PREF&WAITOBUF_CLR procedure

	endm			; End WAITOBUF_CLR_MAC

	WAITOBUF_CLR_MAC U32_	; Define in PGROUP

	NPPROC	BEEP -- Beep On Key
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

BEEP_STR struc

	dd	?		; Caller's EBP
	dd	?		; Caller's EIP
BEEP_FRQ dw	?		; Frequency
BEEP_DUR dw	?		; Duration

BEEP_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ecx,edx>	; Save registers

; Program timer 2 to generate square wave

	mov	al,(2*@TIMER_CH) or @TIMER_LMSB or (3*@TIMER_MODE) or @TIMER_BIN
;;;;;;; mov	al,10110110b	; 10xxxxxx = Timer 2,
				; xx11xxxx = Read/write LSB, then MSB
				; xxxx011x = Mode 3
				; xxxxxxx0 = Binary
	out	@8253_CTL,al	; Send to control register
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	dx,FREQ.EHI	; Hi part of fundamental frequency
	mov	ax,FREQ.ELO	; Lo part ...
	mov	cx,[ebp].BEEP_FRQ ; CX = frequency

	cmp	cx,dx		; Ensure above high-order word
	ja	short BEEP1	; It's OK

	mov	cx,dx		; Use minimum to avoid divide overflow
	inc	cx
BEEP1:
	div	cx		; AX = 8253 counter value, DX ignored

	out	@8253_CH2,al	; Send LSB to timer 2
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	al,ah		; Copy MSB of value
	out	@8253_CH2,al	; Send MSB to timer 2
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

; Read and save current state of 8255, port B

	in	al,@8255_B	; Read it in
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	push	eax		; Save it

	or	al,(mask $SPKR) or (mask $TIMER2) ; Turn on Spkr & Timer2
	out	@8255_B,al	; Tell 8255 about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	movzx	ecx,[ebp].BEEP_DUR ; Get duration
	shl	ecx,1		; Increase the duration
	loop	$		; Wait for a moment

	pop	eax		; Restore initial state of 8255, port B

	out	@8255_B,al	; Restore it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	REGREST <edx,ecx,eax>	; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BEEP	endp			; End BEEP procedure
	NPPROC	ERR_BEEP -- Error Beep
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Error beep

|

	push	es		; Save register

	SETDATA es		; Set data selector into ES
	assume	es:DGROUP	; Tell the assembler about it

	push	SHORT_DUR	; Duration
	push	SHORT_FRQ	; Frequency
	call	BEEP		; Beep the speaker

	pop	es		; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ERR_BEEP endp			; End ERR_BEEP procedure
	FPPROC	KEY_INT08 -- Local INT 08h Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Hardware timer interrupt handler.

This routine runs in protected mode.

|

	pushfd			; Save flags
	cli			; Disallow interrupts

	PUSHW	ds		; Save for a moment

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	dec	SER_TIMEOUT	; Decrement timeout for serial I/O

	test	INT_FLAG,@INT_I08 ; Reflect to VM86 mode?
	jz	short @F	; Jump if not

	LOGDISP 'KEY_INT08: chaining!' ; This should not happen

; Continue with previous handler

	push	KEYINT08_FVEC.FSEL ; Pass selector
	push	KEYINT08_FVEC.FOFF ; Pass offset

KI08_STR struc

	df	?		; Return address
KI08_DS dw	?		; Caller's DS
	dd	?		; Return EFL

KI08_STR ends

	mov	ds,[esp].KI08_DS ; Restore
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with next handler

	jmp	near ptr KEY_INT08 ; In case we're returning to a TSS

	assume	ds:DGROUP	; Tell the assembler about it

@@:
	push	eax		; Save for a moment

	test	SWATINI.MD_ATTR,@MD_MCA ; Izit an MCA-compatible?
	jz	short @F	; Not this time

	in	al,@8255_B	; Read System Control Port B
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	or	al,mask $CLRIRQ0 ; Set high-order bit to reset IRQ0
	out	@8255_B,al	; Reset the level for level-triggered ints
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
@@:
	inc	LCLTIMER	; Increment count

	cmp	LCLTIMER,001800B0h ; Check for 24 hour overflow
	jne	short @F	; Not this time

	mov	LCLTIMER,0	; Zero timer values
	mov	LCLTIMER_OFL,1	; Mark as overflowed
@@:
	mov	al,@EOI 	; Get non-specific EOI
	out	@ICR,al 	; Tell the 8259 about it
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	pop	eax		; Restore

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore flags

	iretd			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

KEY_INT08 endp			; End KEY_INT08 procedure
	FPPROC	KEY_INT0A -- Local INT 0Ah Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Cascade interrupt handler.

This routine runs in protected mode.

|

	push	eax		; Save for a moment

	mov	al,@EOI 	; Get non-specific EOI
	out	@ICR,al 	; Tell the master PIC about it
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	pop	eax		; Restore

	iretd			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

KEY_INT0A endp			; End KEY_INT0A procedure
	FPPROC	KEY_INT0F -- Local INT 0Fh Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Spurious interrupt handler.

This routine runs in protected mode.

|

	push	eax		; Save for a moment

	mov	al,@EOI 	; Get non-specific EOI
	out	@ICR,al 	; Tell the master PIC about it
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	pop	eax		; Restore

	iretd			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

KEY_INT0F endp			; End KEY_INT0F procedure
	FPPROC	KEY_INT74 -- Local INT 74h Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Hardware mouse interrupt handler.

This routine runs in protected mode.

|

	push	eax		; Save for a moment

; Disable the auxiliary device if we're on a Micro Channel system

	test	SWATINI.MD_ATTR,@MD_MCA ; Izit an MCA-compatible?
	jz	short @F	; Not this time

	mov	ah,@S2C_AUXDIS	; Disable the auxiliary device interface
	call	U32_PPI_S2C	; Send command AH to 8042
				; Ignore return code
@@:

; Read in the mousestroke to clear it from the PPI

	in	al,@8255_A	; Get the scan code
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

; Enable the auxiliary device if we're on a Micro Channel system

	test	SWATINI.MD_ATTR,@MD_MCA ; Izit an MCA-compatible?
	jz	short @F	; Not this time

	mov	ah,@S2C_AUXENA	; Enable the auxiliary device interface
	call	U32_PPI_S2C	; Send command AH to 8042
				; Ignore return code
@@:
	mov	al,@EOI 	; Get non-specific EOI
	out	@ICR2,al	; Tell the slave PIC about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
	out	@ICR,al 	; Tell the master PIC about it
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	pop	eax		; Restore

	iretd			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

KEY_INT74 endp			; End KEY_INT74 procedure
	FPPROC	KEY_INT76 -- Local INT 76h Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Hardware disk interrupt handler.

This routine runs in protected mode.

|

	pushfd			; Create IRETD frame

	PUSHW	ds		; Save caller's DS (filler for old selector)

	SETDATA ds		; Get addressability to DGROUP
	assume	ds:DGROUP	; Tell the assembler

	push	KEYINT76_FVEC.FSEL ; Pass old selector
	push	KEYINT76_FVEC.FOFF ; Pass old offset

	jmp	INTxx_ORIG	; Fake a ring transition and chain to previous
				; handler

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

KEY_INT76 endp			; End KEY_INT76 procedure
	FPPROC	KEY_INT77 -- Local INT 77h Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Hardware disk interrupt handler.

This routine runs in protected mode.

|

	pushfd			; Create IRETD frame

	PUSHW	ds		; Save caller's DS (filler for old selector)

	SETDATA ds		; Get addressability to DGROUP
	assume	ds:DGROUP	; Tell the assembler

	push	KEYINT77_FVEC.FSEL ; Pass old selector
	push	KEYINT77_FVEC.FOFF ; Pass old offset

	jmp	INTxx_ORIG	; Fake a ring transition and chain to previous
				; handler

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

KEY_INT77 endp			; End KEY_INT77 procedure

DRAINPIQ_MAC macro PREF

	NPPROC	PREF&DRAINPIQ -- Drain The Prefetch Instruction Queue
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Drain the Prefetch Instruction Queue.

If we're on a Micro Channel system, write to I/O port 4Fh.
Otherwise, just jump a few times.

Flags are saved and restored over this routine to allow it
to be used with impunity.

|

	pushfd			; Save flags

	test	PREF&SWATINI.MD_ATTR,@MD_MCA ; Izit an MCA-compatible?
	jz	short @F	; Not this time

	out	@8253_XCIO,al	; Write to (presumably uncached) port
@@:
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay

	popfd			; Restore flags

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&DRAINPIQ endp		; End PREF&DRAINPIQ procedure

	endm			; DRAINPIQ_MAC

	DRAINPIQ_MAC U32_	; Define in PGROUP

	NPPROC	CHECKPOINT -- Mark Checkpoint Number
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Mark the checkpoint number passed on the stack.

|

CHKPT_STR struc

	dd	?		; Caller's EBP
	dd	?		; Caller's EIP
CHKPT_VAL dw	?,?		; The checkpoint #

CHKPT_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ebx,es>	; Save registers

	SETDATA es		; Set data selector into ES
	assume	es:DGROUP	; Tell the assembler about it

	mov	ax,[ebp].CHKPT_VAL ; Get the checkpoint #

	push	eax		; Pass as argument
	call	U32_BLINK_LED	; Blink the LEDs for a moment

	div	DIVISOR 	; Split into high and low part
				; AL = quotient, AH = remainder
	mov	bl,al		; Copy quotient
	shr	bl,1		; BL = # tens notes
	and	al,1		; AL = # fives notes
				; AH = # units notes
CHKPT_TENS:
	dec	bl		; Check for more tens notes
	js	short CHKPT_FIVES ; No more, do fives notes now

	push	TENS_DUR	; Duration
	push	TENS_FRQ	; Frequency
	call	BEEP		; Beep the speaker

	call	PAUSE		; Pause between notes

	jmp	short CHKPT_TENS ; Go around again


CHKPT_FIVES:
	dec	al		; Check for no more fives notes
	js	short CHKPT_UNITS ; No more, do units notes

	push	FIVES_DUR	; Duration
	push	FIVES_FRQ	; Frequency
	call	BEEP		; Beep the speaker

	call	PAUSE		; Pause between notes

	jmp	short CHKPT_FIVES ; Go around again


CHKPT_UNITS:
	dec	ah		; Check for no more units notes
	js	short CHKPT_XNOTES ; No more

	push	UNITS_DUR	; Duration
	push	UNITS_FRQ	; Frequency
	call	BEEP		; Beep the speaker

	call	PAUSE		; Pause between notes

	jmp	short CHKPT_UNITS ; Go around again


CHKPT_XNOTES:
	REGREST <es,ebx,eax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECKPOINT endp 		; End CHECKPOINT procedure

BLINK_LED_MAC macro PREF

	public	PREF&LED_TRANS
PREF&LED_TRANS db 0, 1, 4, 5, 2, 3, 6, 7

	NPPROC	PREF&BLINK_LED -- Blink LEDs
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Blink LED indicator(s) according to the byte on the stack.
The value may range from 1 to 26.

Base 3 arithmetic is used to display the value.
That is, represent the value in AL in base 3 with digits 0, 1, 2.

A digit of 0 means the corresponding light is off
	   1				      on
	   2				      blinking

|

ifidni <PREF>,<U32_>
PREF&BLINK_STR struc

	dd	?		; Caller's EBP
	dd	?		; Caller's EIP
PREF&BLINK_VAL dw ?,?		; LED byte

PREF&BLINK_STR ends
else
PREF&BLINK_STR struc

	dw	?		; Caller's BP
	dw	?		; Caller's IP
PREF&BLINK_VAL dw ?		; LED byte

PREF&BLINK_STR ends
endif

ifidni <PREF>,<U32_>
	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	pushfd			; Save flags so we can blink in-line
else
	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	pushf			; Save flags so we can blink in-line
endif
	REGSAVE <eax,ebx,ecx,edx> ; Save registers

COMMENT|

Convert the value as follows:

Represent it in base 3 with digits 0, 1, 2.

For each of the three digits,
  put into BL the constant states,
       and BH the blinking states
as follows:

	 Corresponding
	    Bit in
   Digit    BH	 BL
     0	    0	 0
     1	    0	 1
     2	    1	 0

Note that this corresponds to putting the high-order bit of the digit
into BH and the low-order bit into BL.

|

	test	PREF&SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
	jnz	short PREF&BLINK_LED_EXIT ; Yes, so there are no LEDs
ifidni <PREF>,<U32_>
	mov	al,[ebp].&PREF&BLINK_VAL.LO ; Get the value
else
	mov	al,[bp].&PREF&BLINK_VAL.LO ; Get the value
endif
	mov	cx,3		; # digits to convert
	xor	bx,bx		; Zero BH and BL
	mov	dl,3		; Divisor
PREF&BLINK_CONV:
	xor	ah,ah		; Zero to use as word
	div	dl		; Strip off a digit into AH
				; with quotient in AL
	shr	ah,1		; Pick off bit 0
	rcr	bl,1		; Put into high-order of BL

	shr	ah,1		; Pick off bit 1
	rcr	bh,1		; Put into high-order of BH

	LOOPS	PREF&BLINK_CONV ; Jump if more digits

	shr	bx,8-3		; Shift to low-order

	mov	cx,60		; # times to blink the LEDs
	call	PREF&WAITOBUF_CLR ; Wait for the output buffer to clear

	mov	ah,@S2C_DIS	; Disable the keyboard interface
	call	PREF&PPI_S2C	; Send command AH to 8042
;;;;;;; jc	short PREF&ERR_BLINK1 ; Not programmable???
PREF&BLINK_NEXT:
	mov	ah,@S2K_LED	; Set/reset LED Indicators
	call	PREF&PPI_S2K_K2S ; Send command AH to keyboard, response in AL
	jc	short PREF&ERR_BLINK1 ; Jump if controller not responding

	cmp	al,@K2S_ACK	; Izit an ACK?
	jne	short PREF&ERR_BLINK1 ; Jump if something went wrong

;;;;;;; mov	ah,bl		; Set LED indicator(s)

; The original PC/XT keyboard has the LEDs laid out as Caps/Num/Scroll.
; Later keyboards switched Caps and Num, so we must switch them here
; so as to get adjacency of digits.

	push	ebx		; Save for a moment

	mov	al,bl		; Copy to translate register
	lea	ebx,PREF&LED_TRANS ; CS:EBX ==> translate table
	xlat	PREF&LED_TRANS[ebx] ; Translate
	mov	ah,al		; Copy back to PPI register

	pop	ebx		; Restore

	call	PREF&PPI_S2K_K2S ; Send command AH to keyboard, response in AL
	jc	short PREF&ERR_BLINK1 ; Jump if controller not responding

	cmp	al,@K2S_ACK	; Izit an ACK?
	jne	short PREF&ERR_BLINK1 ; Something went wrong
PREF&ERR_BLINK1:
	push	ecx		; Save for a moment
	mov	ecx,900000h	; Loop for a while
@@:
	LOOPD	@B
	pop	ecx		; Restore

	xor	bl,bh		; Complement the bit(s)

	LOOPS	PREF&BLINK_NEXT ; Jump if more to do
PREF&ERR_BLINK2:

; Finally, turn off all indicators

	mov	ah,@S2K_LED	; Set/reset LED Indicators
	call	PREF&PPI_S2K_K2S ; Send command AH to keyboard, response in AL
				; Ignore error return

	mov	ah,0		; Set LED indicator(s)
	call	PREF&PPI_S2K_K2S ; Send command AH to keyboard, response in AL
				; Ignore error return

	mov	ah,@S2C_ENA	; Enable the keyboard interface
	call	PREF&PPI_S2C	; Send command AH to 8042
				; Ignore return code

	call	PREF&WAITOBUF_CLR ; Wait for the output buffer to clear
				; in case there are any keystrokes left over
PREF&BLINK_LED_EXIT:
	REGREST <edx,ecx,ebx,eax>  ; Restore

ifidni <PREF>,<U32_>
	popfd			; Restore flags

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument
else
	popf			; Restore flags

	pop	bp		; Restore

	ret	2		; Return to caller, popping argument
endif
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&BLINK_LED endp		; End PREF&BLINK_LED procedure

	endm			; End BLINK_LED_MAC

	BLINK_LED_MAC U32_	; Define in PGROUP

	NPPROC	PAUSE -- Pause Between Notes
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Pause between notes

|

	REGSAVE <ecx>		; Save register

	xor	cx,cx		; Start with a full loop

	LOOPS	$		; Wait for a moment
	LOOPS	$		; Wait for a moment

	REGREST <ecx>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PAUSE	endp			; End PAUSE procedure

PROG	ends			; End PROG segment


NCODE	segment use16 para public 'ncode' ; Start NCODE segment
	assume	cs:NGROUP,ds:NGROUP

	public	@SWAT_KEY_NCODE
@SWAT_KEY_NCODE:		; Mark module start in .MAP file

	public	U16_SWATINI
U16_SWATINI MD_STR <>

	DRAINPIQ_MAC U16_	; Define in NGROUP
;;;;;;; BLINK_LED_MAC U16_	; ...
;;	WAITOBUF_CLR_MAC U16_	; ...
;;	PPI_S2C_MAC U16_	; ...
;;	WAITIBUF_CLR_MAC U16_	; ...
;;	PPI_S2K_K2S_MAC U16_	; ...
;;	PPI_S2K_MAC U16_	; ...
;;	PPI_K2S_MAC U16_	; ...
;;	WAITOBUF_SET_MAC U16_	; ...

NCODE	ends			; End NCODE segment


RCODE	segment use16 para public 'rcode' ; Start RCODE segment
	assume	cs:RGROUP,ds:RGROUP

	public	@SWAT_KEY_RCODE
@SWAT_KEY_RCODE:		; Mark module start in .MAP file

	extrn	DEV_SWATINI:tbyte

	DRAINPIQ_MAC DEV_	; Define in RGROUP
	WAITIBUF_CLR_MAC DEV_	; ...
	WAITOBUF_CLR_MAC DEV_	; ...
	WAITOBUF_SET_MAC DEV_	; ...
	PPI_S2C_MAC DEV_	; ...
	PPI_K2S_MAC DEV_	; ...
	PPI_S2C_K2S_MAC DEV_	; ...
	PPI_S2C_S2K_MAC DEV_	; ...

	align	16		; Fill tail with NOPs

RCODE	ends			; End RCODE segment

	MEND			; End SWAT_KEY module
