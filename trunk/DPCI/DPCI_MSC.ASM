	title	DPCI_MSC -- Dual PCI VGA Adapters, Miscellaneous Routines
	page	58,122
	name	DPCI_MSC

.386
	include MASM.INC
	include PTR.INC
	include ASCII.INC
	include 386.INC
	include DPCI.INC
	include DOSCALL.INC
	include 6845.INC

PGROUP	group	CODE,DATA,DATA2,TEXT


DATA	segment use16 dword public 'data' ; Start DATA segment
	assume	ds:PGROUP

	extrn	PSP_PARM_COUNT:byte
	extrn	PSP_PARM_STRING:byte
	extrn	LCL_FLAG:word

	extrn	DirectPCI:byte
	extrn	@DIRPCI_BIOS:abs
	extrn	@DIRPCI_REGS:abs

	public	CRTC
CRTC	dw	@CRT_CLR	; CRT controller port (3x4h)

	public	MSG_UNK
MSG_UNK db	'*** Unknown argument',CR,LF,EOS

	 public  NUMBERS_HI
NUMBERS_HI db	 '0123456789ABCDEF'

DATA	ends			; End DATA segment


CMDARG_MAC macro TXT,ACT
	local	L1,L2

TEXT	segment use16 byte public 'data' ; Start TEXT segment
	assume	ds:PGROUP

L1	db	TXT		; Argument name
L2	equ	$-L1		; Length not counting

TEXT	ends			; End TEXT segment


DATA2	segment use16 word public 'data' ; Start DATA2 segment
	assume	ds:PGROUP

	ARG_STR <offset PGROUP:L1,L2,offset PGROUP:ACT> ; Offset, length, and action

DATA2	ends			; End DATA2 segment

	endm			; CMDARG_MAC


ARG_STR struc

ARG_OFF dw	?		; Offset in PGROUP of text
ARG_LEN dw	?		; Length of ...
ARG_ACT dw	?		; Offset in PGROUP of action

ARG_STR ends


DATA2	segment use16 word public 'data' ; Start DATA2 segment
	assume	ds:PGROUP

	public	ARGSTR
ARGSTR	label	tbyte

DATA2	ends			; End DATA2 segment


	CMDARG_MAC 'MONO',ACT_MONO
	CMDARG_MAC 'DVGA',ACT_DVGA


DATA2	segment use16 word public 'data' ; Start DATA2 segment
	assume	ds:PGROUP

	public	NARGS
NARGS	equ	($-ARGSTR)/(type ARG_STR) ; # arguments

DATA2	ends			; End DATA2 segment


CODE	segment use16 byte public 'code' ; Start CODE segment
	assume	cs:PGROUP

	NPPROC	DRAINPIQ -- Drain The Prefetch Instruction Queue
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Drain the Prefetch Instruction Queue.

If we're on a Micro Channel system, write to I/O port 4Fh.
Otherwise, just jump a few times.

Flags are saved and restored over this routine to allow it
to be used with impunity.

|

	pushfd			; Save flags

;;;;;;; test	SWATINI.MD_ATTR,@MD_MCA ; Izit an MCA-compatible?
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

DRAINPIQ endp			; End DRAINPIQ procedure
	NPPROC	SET6845 -- Set 6845 Registers
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set 6845 registers indexed by AH+0 1 to (CH,CL)

On entry:

(CH,CL) =	CRTC register values

|

	REGSAVE <eax,edx>	; Save registers

	mov	al,ah		; Cursor low location register
	mov	dx,CRTC 	; Get CRT controller I/O port address

	out	dx,al		; Tell the CRTC about it
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	al,ch		; Get high-order bits
	inc	dx		; Skip to data port

	out	dx,al		; Tell the CRTC about it
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	al,ah		; Cursor high location register
	inc	al		; Skip to next index register
	dec	dx		; Back to command port

	out	dx,al		; Tell the CRTC about it
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	al,cl		; Get low-order bits
	inc	dx		; Skip to data port
	out	dx,al		; Tell the CRTC about it
;;;;;;; call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	REGREST <edx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET6845 endp			; End SET6845 procedure
	NPPROC	GET6845 -- Get 6845 Registers
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get 6845 registers indexed by AH+0 1 into (CH,CL)

On exit:

(CH,CL)  =	 CRTC register values

|

	REGSAVE <eax,edx>	; Save registers

	mov	al,ah		; Cursor low location register
	mov	dx,CRTC 	; Get CRT controller I/O port address

	out	dx,al		; Tell the CRTC about it
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	inc	dx		; Skip to data port

	in	al,dx		; Ask the CRTC about it
	mov	ch,al		; Set high-order bits
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	al,ah		; Cursor high location register
	inc	al		; Skip to next index register
	dec	dx		; Back to command port

	out	dx,al		; Tell the CRTC about it
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	inc	dx		; Skip to data port
	in	al,dx		; Ask the CRTC about it
	mov	cl,al		; Set low-order bits
;;;;;;; call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	REGREST <edx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET6845 endp			; End GET6845 procedure
	NPPROC	GET_CURPOS -- Get Cursor Position
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get cursor position as (Row,Col) = (CH,CL)

|

;;;;;;; test	LC3_FLAG,@LC3_NOVID ; Is display disabled?
;;;;;;; jnz	short @F	; Jump if so
;;;;;;;
	push	eax		; Save for a moment

	mov	ah,@VID_POSHI	; Cursor high location register
	call	GET6845 	; Get 6845 registers into CX

	pop	eax		; Restore
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_CURPOS endp 		; End GET_CURPOS procedure
	NPPROC	SET_CURPOS -- Set Cursor Position
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set cursor position to (Row,Col) = (CH,CL)

|

SETCUR_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
SETCUR_VAL dw	?		; New cursor position/type value

SETCUR_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <eax,ecx>	; Save registers

;;;;;;; test	LC3_FLAG,@LC3_NOVID ; Is display disabled?
;;;;;;; jnz	short SETCUR_EXIT ; Jump if so

	mov	cx,[bp].SETCUR_VAL ; Get new cursor position value
	mov	al,@NCOLS	; Get # screen columns
	mul	ch		; Times row #
	xor	ch,ch		; Cursor row zero
	add	cx,ax		; Add together to get linear offset

	mov	ah,@VID_POSHI	; Cursor high location register
	call	SET6845 	; Set 6845 registers from CX
SETCUR_EXIT:
	REGREST <ecx,eax>	; Restore

	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_CURPOS endp 		; End SET_CURPOS procedure
	NPPROC	CHK_CREG -- Check Cursor Register DX For Adapter Presence
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	REGSAVE <ax,dx> 	; Save registers

	mov	al,0Fh		; Set CRTC to address cursor register
	out	dx,al		; Tell CRTC about it
;;;;;;; call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue
	jmp	short $+2      ; I/O delay
	jmp	short $+2      ; I/O delay
	jmp	short $+2      ; I/O delay
	inc	dx		; Point to data register

	in	al,dx		; Save original value
;;;;;;; call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue
	jmp	short $+2      ; I/O delay
	jmp	short $+2      ; I/O delay
	jmp	short $+2      ; I/O delay

	push	ax		; on the stack
	mov	al,5Ah		; Test value for cursor position
	out	dx,al		; Tell CRTC about it
;;;;;;; call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue
	jmp	short $+2      ; I/O delay
	jmp	short $+2      ; I/O delay
	jmp	short $+2      ; I/O delay

	in	al,dx		; Read it back in
;;;;;;; call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue
	jmp	short $+2      ; I/O delay
	jmp	short $+2      ; I/O delay
	jmp	short $+2      ; I/O delay

; Note the long scope of the following comparison

	cmp	al,5Ah		; Check against test value
	pop	ax		; Restore original cursor value

	out	dx,al		; Restore original value in CRTC
;;;;;;; call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue
;;;;;;; jmp	short $+2      ; I/O delay
;;;;;;; jmp	short $+2      ; I/O delay
;;;;;;; jmp	short $+2      ; I/O delay
	jne	short CHK_CREG_NO ; Not present

	clc			; Indicate it's present

	jmp	short CHK_CREG_EXIT ; Join common exit code

CHK_CREG_NO:
	stc			; Indicate it's not present
CHK_CREG_EXIT:
	REGREST <dx,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHK_CREG endp			; End CHK_CREG procedure
	NPPROC	CHECK_ARGS -- Parse The Command Line
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Parse the command line

On exit:

CF	=	0 if successful
	=	1 if not

|

	pusha			; Save registers

	lea	si,PSP_PARM_STRING ; DS:SI ==> command line

	movzx	bx,PSP_PARM_COUNT ; Get the string count
	mov	PGROUP:[bx+si].LO,0 ; Terminate it
	call	STR_UPPER	; Convert the string to upper case
CHECK_ARGS_NEXT1:
	call	SKIP_WHITE	; Skip over white space
				; Return current char in AL
	cmp	al,0		; Izit EOL?
	je	short CHECK_ARGS_EXIT ; Jump if so (note CF=0)

	cmp	al,CR		; Izit EOL?
	je	short CHECK_ARGS_EXIT ; Jump if so (note CF=0)

	mov	cx,NARGS	; Get # arguments we know about
	xor	bx,bx		; Initialize index into ARGSTR
CHECK_ARGS_NEXT2:
	REGSAVE <cx,si> 	; Save for a moment

	mov	di,ARGSTR[bx].ARG_OFF ; ES:DI ==> next argument text
	mov	cx,ARGSTR[bx].ARG_LEN ; CX = length of ...
   repe cmps	PSP_PARM_STRING[si],PGROUP:[di].LO ; Compare 'em

	REGREST <si,cx> 	; Restore
	je	short CHECK_ARGS1 ; Jump if it matches

	add	bx,type ARG_STR ; Skip to next argument

	loop	CHECK_ARGS_NEXT2 ; Jump if more arguments to check

	DOSCALL @STROUT,MSG_UNK ; Tell 'em to type better

	stc			; Mark as not found

	jmp	short CHECK_ARGS_EXIT ; Join common exit code


CHECK_ARGS1:
	mov	di,si		; Copy start of command line argument
	add	di,ARGSTR[bx].ARG_LEN ; Skip over the argument
	mov	al,PGROUP:[di]	; Get next char on command line

	cmp	al,0		; Izit EOL?
	je	short CHECK_ARGS2 ; Jump if so

	cmp	al,CR		; Izit EOL?
	je	short CHECK_ARGS2 ; Jump if so

	cmp	al,'='          ; Izit separator?
	je	short CHECK_ARGS2 ; Jump if so

	cmp	al,' '          ; Izit white space?
	je	short CHECK_ARGS2 ; Jump if so

	cmp	al,TAB		; Izit white space?
	jne	short CHECK_ARGS_NEXT2 ; Jump if so
CHECK_ARGS2:
	add	si,ARGSTR[bx].ARG_LEN ; Skip over the argument

	call	ARGSTR[bx].ARG_ACT ; Take appropriate action
	jnc	short CHECK_ARGS_NEXT1 ; Jump if successful
				; Fall through with CF=1
CHECK_ARGS_EXIT:
	popa			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ARGS endp 		; End CHECK_ARGS procedure
	NPPROC	SKIP_WHITE -- Skip Over White Space
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over white space

On entry:

DS:SI	==>	command line

On exit:

AL	=	non-white space character
DS:SI	==>	(updated)

|

@@:
	lods	ds:[si].LO	; Get next character

	cmp	al,' '          ; Izit white space?
	je	short @B	; Yes, go around again

	cmp	al,TAB		; Izit white space?
	je	short @B	; Yes, go around again

	dec	si		; Back off to previous character

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SKIP_WHITE endp 		; End SKIP_WHITE procedure
	NPPROC	STR_UPPER -- Convert String to Uppercase
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert ASCIIZ string at DS:SI to uppercase

|

	REGSAVE <ax,si> 	; Save registers
STR_UPPER_NEXT:
	lods	ds:[si].LO	; Get next character

	and	al,al		; Check for end-of-the-line
	jz	short STR_UPPER_EXIT ; Good guess

	cmp	al,EOF		; Check for end-of-the-file
	je	short STR_UPPER_EXIT ; Good guess

	cmp	al,'a'          ; Check against lower limit
	jb	short STR_UPPER_NEXT ; Jump if too small

	cmp	al,'z'          ; Check against upper limit
	ja	short STR_UPPER_NEXT ; Jump if too large

	add	al,'A'-'a'      ; Convert to uppercase

	mov	ds:[si-1],al	; Save back in text

	jmp	short STR_UPPER_NEXT ; Go around again

STR_UPPER_EXIT:
	REGREST <si,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

STR_UPPER endp			; End STR_UPPER procedure
	NPPROC	ACT_MONO -- Command Line Action for MONO
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Command line action for MONO

On exit:

CF	=	0 if successful
	=	1 if not

|

	or	LCL_FLAG,@LCL_MONO ; Mark as present
				; Fall through with CF=0
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_MONO endp			; End ACT_MONO procedure
	NPPROC	ACT_DVGA -- Command Line Action for DVGA
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Command line action for DVGA

On entry:

AL	=	next char (after keyword)
DS:SI	==>	text (after keyword)

On exit:

CF	=	0 if successful
	=	1 if not

|

; Check for optional =BIOS or =REGS

	cmp	al,'='          ; Izit separator?
	jne	short ACT_DVGA_DONE ; Jump if not

	inc	si		; Skip over separator

	call	SKIP_WHITE	; Skip over white space
				; Return current char in AL
	cmp	ds:[si].EDD,'SOIB' ; Izit BIOS?
	je	short ACT_DVGA_BIOS ; Jump if so

	cmp	ds:[si].EDD,'SGER' ; Izit REGS?
	je	short ACT_DVGA_REGS ; Jump if so

	stc			; Mark as in error

	jmp	short ACT_DVGA_EXIT ; Join common exit code


ACT_DVGA_BIOS:
	mov	DirectPCI,@DIRPCI_BIOS ; Mark as using BIOS calls

	jmp	short ACT_DVGA_SKIP ; Join common code


ACT_DVGA_REGS:
	mov	DirectPCI,@DIRPCI_REGS ; Mark as using registers

;;;;;;; jmp	short ACT_DVGA_SKIP ; Join common code


ACT_DVGA_SKIP:
	add	si,4		; Skip over 'BIOS' or 'REGS'
ACT_DVGA_DONE:
	or	LCL_FLAG,@LCL_DVGA ; Mark as present
				; Fall through with CF=0
ACT_DVGA_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_DVGA endp			; End ACT_DVGA procedure
	NPPROC	DB2HEX -- Convert AL to Hex At ES:EDI
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	push	cx		; Save for a moment
	mov	cx,2		; # hex digits
	call	BIN2HEX_SUB	; Handle by subroutine
	pop	cx		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DB2HEX	endp			; End DB2HEX procedure
	NPPROC	DW2HEX -- Convert AX to Hex At ES:EDI
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	push	cx		; Save for a moment
	mov	cx,4		; # hex digits
	call	BIN2HEX_SUB	; Handle by subroutine
	pop	cx		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DW2HEX	endp			; End DW2HEX procedure
	NPPROC	DD2HEX -- Convert EAX to Hex At ES:EDI
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	push	cx		; Save for a moment
	mov	cx,8		; # hex digits
	call	BIN2HEX_SUB	; Handle by subroutine
	pop	cx		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DD2HEX	endp			; End DD2HEX procedure
	NPPROC	BIN2HEX_SUB
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	REGSAVE <eax,ebx,edx>	; Save registers

	pushf			; Save flags
	std			; Store backwards

	mov	edx,eax 	; Copy to secondary register
	lea	bx,NUMBERS_HI	; XLAT table
	add	di,cx		; Skip to the end+1

	push	di		; Save to return

	dec	di		; Now the last digit
BIN2HEX_MORE:
	mov	al,dl		; Copy to XLAT register
	and	al,0Fh		; Isolate low-order digit
	xlat	NUMBERS_HI[bx]	; Convert to ASCII hex
	stos	es:[di].LO	; Save in output stream

	shr	edx,4		; Shift next digit down to low-order

	loop	BIN2HEX_MORE	; Jump if more digits to format

	pop	di		; Restore

	popf			; Restore flags

	REGREST <edx,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2HEX_SUB endp		; End BIN2HEX_SUB procedure

CODE	ends			; End CODE segment

	MEND			; End DPCI_MSC module
