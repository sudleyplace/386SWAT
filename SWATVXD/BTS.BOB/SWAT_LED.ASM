;'$Header$
	title	SWAT_LED -- SWATVXD LED Routines
	page	78,130
	name	SWAT_LED

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1990-2002 Qualitas, Inc.  All rights reserved.

Segmentation:  Group _IGROUP:
	       Program segment _ITEXT,	dword-aligned,	use32,	public, 'ICODE'
	       Data    segment _IDATA,	dword-aligned,	use32,	public, 'ICODE'
	       Group _LGROUP:
	       Program segment _LTEXT,	dword-aligned,	use32,	public, 'CODE'
	       Data    segment _LDATA,	dword-aligned,	use32,	public, 'CODE'
	       Group _PGROUP:
	       Program segment _TEXT,	dword-aligned,	use32,	public, 'PCODE'
	       Data    segment _DATA,	dword-aligned,	use32,	public, 'PCODE'

	       Segment	       _RCODE,	word-aligned,	use16,	public, 'RCODE'

Program derived from:  None.

Original code by:  Bob Smith

Modifications by:  None.

|

.386p
.xlist
	include VMM.INC 	; Fixed version of file from DDK

	include MASM.INC	; From Bob's standard includes
	include 386.INC
	include PTR.INC
	include 8255.INC
.list

;******************************************************************************

VxD_LOCKED_DATA_SEG		; Begin _LDATA segment


VxD_LOCKED_DATA_ENDS		; End _LDATA segment

VxD_LOCKED_CODE_SEG		; Begin _LCODE segment

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

;;;;;;; test	PREF&SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
;;;;;;; jnz	short PREF&BLINK_LED_EXIT ; Yes, so there are no LEDs
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

;;;;;;; test	PREF&SWATINI.MD_ATTR,@MD_MCA ; Izit an MCA-compatible?
;;;;;;; jz	short @F	; Not this time
;;;;;;;
;;;;;;; out	@8253_XCIO,al	; Write to (presumably uncached) port
@@:
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay

	popfd			; Restore flags

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&DRAINPIQ endp		; End PREF&DRAINPIQ procedure

	endm			; DRAINPIQ_MAC

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

WAITIBUF_CLR_MAC macro PREF

	NPPROC	PREF&WAITIBUF_CLR -- Wait For The Input Buffer To Clear
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
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
;;;;	     test    PREF&SWATINI.MD_ATTR,@MD_MCA ; Izit an MCA-compatible?
;;;;	     jz      short PREF&WAITIBUF_CLR2 ; Jump if not
;;;;
;;;; ; Wait for next refresh
;;;;
;;;; @@:
;;;;	     in      al,@8255_B      ; Get port B value
;;;;	     and     al,mask $REFRESH ; Isolate refresh bit
;;;;
;;;;	     cmp     al,ah	     ; Izit the same as last time?
;;;;	     je      short @B	     ; Jump if so
;;;;
;;;;	     mov     ah,al	     ; Save for next time
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








	BLINK_LED_MAC U32_	; Define in LOCKED_CODE
	WAITOBUF_CLR_MAC U32_	; Define in LOCKED_CODE
	DRAINPIQ_MAC U32_	; Define in LOCKED_CODE
	PPI_S2C_MAC U32_	; Define in LOCKED_CODE
	PPI_S2K_K2S_MAC U32_	; Define in LOCKED_CODE
	PPI_S2K_MAC U32_	; Define in LOCKED_CODE
	PPI_K2S_MAC U32_	; Define in LOCKED_CODE
	WAITIBUF_CLR_MAC U32_	; Define in LOCKED_CODE
	WAITOBUF_SET_MAC U32_	; Define in LOCKED_CODE

VxD_LOCKED_CODE_ENDS		; End LOCKED_CODE segment

	MEND			; End SWAT_LED module
