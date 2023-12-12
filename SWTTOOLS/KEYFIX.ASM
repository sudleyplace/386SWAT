	TITLE	KEYFIX - Int 9 TSR to disable/enable keyboard around Int 9 chain
	PAGE	60,132
	Name	Keyfix

COMMENT |

************************* QUALITAS CONFIDENTIAL ****************************

Copyright (C) 1991 Qualitas, Inc.	All rights reserved

Original code by: Henry Groover, June 1991

|

.xlist
Include	MASM.INC
Include DOSCALL.INC
Include ASCII.INC
Include	PTR.INC
Include 8255.INC
.list

CRLF	equ	<CR,LF>
@WAIT8042 equ	12			; Wait counter for 8042 timeout

CODE SEGMENT PUBLIC DWORD 'CODE'
     Assume CS:Code,DS:nothing, ES:nothing

	Org	0
.xlist
Include	PSP.INC
.list


Start:

	jmp	Install

Oldvec	 dd	?				; Vector to chain to

	 NPPROC  WAITIBUF_CLR -- Wait For The Input Buffer To Clear
	 assume  cs:Code,ds:nothing,es:nothing,ss:nothing
COMMENT|

Wait for the one-byte input buffer to clear.

On entry:

IF	 =	 0

On exit:

CF	 =	 0 if buffer empty
	 =	 1 otherwise

|

	 REGSAVE <ax,cx>	; Save registers

	 mov	 ah,@WAIT8042	; Outer loop counter (arbitrary value)
	 xor	 cx,cx		; Inner loop counter (arbitrary value)
WAITIBUF_CLR1:
	 in	 al,@8042_ST	; Get status from keyboard

	 and	 al,mask $INPFULL ; Check Input Buffer Full flag
	 loopnz  WAITIBUF_CLR1	; Last char not read as yet
	 jz	 short WAITIBUF_CLR_EXIT ; Jump if buffer clear (note CF=0)

	 dec	 ah		; One fewer time
	 jnz	 short WAITIBUF_CLR1 ; Go around again

	 stc			; Indicate something went wrong
WAITIBUF_CLR_EXIT:
	 REGREST <cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

WAITIBUF_CLR endp		; End WAITIBUF_CLR procedure

	 NPPROC  PPI_S2C -- PPI System to Controller
	 assume  cs:Code,ds:nothing,es:nothing,ss:nothing
COMMENT|

PPI System to Controller.
Send a command to the controller (8042).

Note that it's the caller's responsibility to ensure that
the 8042 output buffer is clear.

1.  Wait for the input buffer to clear to avoid overrun.
2.  Send the command in AH to the keyboard controller port 64h.
    There is no acknowledgement of this command.

On entry:

AH	 =	 command
IF	 =	 0

On exit:

CF	 =	 1 if keyboard controller not responding
	 =	 0 otherwise

|

	 call	 WAITIBUF_CLR	; Wait for input buffer to clear
	 jc	 short @F	; Error, controller not reading data (note CF=1)

	 xchg	 al,ah		; Swap to put command in AL
	 out	 @8042_ST,al	; Send the command
	 xchg	 al,ah		; Restore
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

PPI_S2C  endp			; End PPI_S2C procedure

Keyfix_sig db	'KeYfIx10'			; Signature to see if we're in
KEYFIX_LEN EQU	$-Keyfix_sig			; Length of signature

FPPROC	Int9 -- IRQ1 handler
	assume cs:Code,ds:nothing,es:nothing,ss:nothing
KEYFIX_OFF EQU	$-Keyfix_sig			; neg. offset of signature

COMMENT |

Int9 hooks into the Int9 (IRQ1 handler) chain, preferably as the last
TSR loaded.  It disables the keyboard, simulates an interrupt 9 via a
PUSHF/far call, and re-enables the keyboard before performing an IRET.

Registers on entry:	None defined.
Registers on exit:	Hardware interrupt handler - all registers and flags
			MUST be preserved.

|

	 REGSAVE ax			; Save caller's register

	 mov	 ah,@S2C_DIS		; Disable keyboard
	 call	 PPI_S2C		; Send command to keyboard controller

	 pushf				; Put flags on stack
	 call	 oldvec			; Simulate an INT

	 cli				; Interrupts were re-enabled by IRET

	 mov	 ah,@S2C_ENA		; Enable keyboard
	 call	 PPI_S2C		; Send command to keyboard controller

	 REGREST ax			; Restore caller's register

	iret				; Return to caller
	assume ds:nothing,es:nothing,ss:nothing ; Tell the assembler

Int9	endp				; End of Int 9 procedure

;------------ END OF RESIDENT SECTION ---------------------------------------

Nonres_data	label	byte		; beginning of non-resident code/data

Banner	db	'Keyfix 0.10     Copyright (C) 1991, Qualitas, Inc.     All rights reserved.',CRLF,EOS
Already_installed db 'Keyfix is already installed.',CRLF,EOS

	assume	cs:Code,ds:nothing,es:nothing,ss:nothing
Install:
;------------ BEGIN INSTALLATION CODE ---------------------------------------
	mov	ax,cs			; Get code segment
	mov	ds,ax			; Put it in DS
	assume	ds:Code			; Tell the assembler

	; Get current Int 9 vector
	mov	al,9
	DOSCALL	@GETINT			; Get int AL vector in ES:BX
	assume	es:nothing		; Tell the assembler ES was changed
	mov	Oldvec.VOFF,bx		; Save offset
	mov	ax,es			; Get segment
	mov	Oldvec.VSEG,ax		; Save segment portion

	; Check to see if we're already installed
	lea	di,[bx-KEYFIX_OFF]	; Get signature offset - ignore wrap
	lea	si,Keyfix_sig		; Get our copy of signature
	mov	cx,KEYFIX_LEN		; Number of bytes to compare
   rep	cmpsb				; Compare ES:DI with DS:SI for CX bytes
	jne	short @F		; Not already installed
	lea	dx,Already_installed	; Display "Already installed"
	jmp	Keyfix_err		; Terminate with error

@@:
	; Display banner
	lea	dx,Banner		; Display "Keyfix (C) 1991..."
	DOSCALL	@STROUT			; Display string

	; Hook Int 9
	lea	dx,Int9			; DS:DX ==> new int 9 vector
	mov	al,9			; Interrupt 9 vector index
	DOSCALL	@SETINT			; Set interrupt vector

	; Calculate resident size
	lea	dx,Nonres_data		; Get offset of non-resident portion
	test	dl,0fh			; Any portion of a paragraph?
	jz	short @F		; No; DX is OK
	add	dx,10h			; Round up
@@:
	mov	cl,4			; Convert bytes to paragraphs
	shr	dx,cl			; DX = # of paras to keep

	; Go resident
	sub	al,al			; Return errorlevel 0
	DOSCALL	@KEEPRC			; Terminate and stay resident

Keyfix_err:
	Doscall	@STROUT			; DS:DX already points to error msg
	Mov	al, 0ffh		; return code -1

Keyfix_exit:
	DOSCALL	@EXITRC			; return to DOS

CODE	ENDS
	END	Start
