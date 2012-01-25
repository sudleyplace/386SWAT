	 title	 HELLO_PM -- Say hello in protected mode
	 page	 58,122
	 name	 HELLO_PM

COMMENT|

Copyright (C) 1992-93, Qualitas Inc.  All Rights Reserved.

This program is an example of a DPMI application that enters
protected mode via DPMI services, prints "Hello, world," then
returns to DOS (and V86 mode).

For a more complete example of DPMI services, see SWATDPMI.ASM.

To compile and link:
nmake /f hello_pm.mak

To debug:
swatrun hello_pm

|
.386p

CR	equ	0dh
LF	equ	0ah
EOS	equ	'$'

PPROC	macro	@PROCNAME
Public	@PROCNAME
@PROCNAME	proc
	endm

DISP_STR macro	@MSG
ifnb <@MSG>
	lea	dx,@MSG
endif
	mov	ah,9		; DOS display string function
	int	21h
	endm

if @Version GE 600
OPTION	OLDSTRUCTS		; Allow simplified typecasting
OPTION	READONLY		; Make all code segments READONLY
endif

VSEG_STR	struc		; V86 mode segment:offset vector
VOFF	dw	?
VSEG	dw	?
VSEG_STR	ends

EDD_STR 	struc		; Structure for typecasting
EDD	dd	?
EDD_STR 	ends

PGROUP	group	CODE,DATA

; Declare all the segments in the order we want them in the .EXE file
CODE	segment use16 public dword 'CODE'
CODE	ends

DATA	segment use16 public dword 'DATA'
DATA	ends

STACK	segment use16 stack dword 'STACK'
STACK	ends

DATA	segment
	assume ds:PGROUP

	Public	Init_msg,PM_hello,ERR_failed
Init_msg db	'HELLO_PM v0.10 ออ A Sample DPMI Application For SWAT Debugging',CR,LF,EOS
PM_hello db	'Hello, world from protected mode - returning to V86 mode.',CR,LF,EOS
ERR_failed db	7,'Unable to activate DPMI services.',CR,LF,EOS

	Public	PM_entry,HPDASEG
PM_entry dd	?		; Far entry to DPMI enter PM function
HPDASEG dw	?		; Segment of HPDA in low DOS

DATA	ends

CODE	segment
	assume cs:PGROUP

;------------ No 286 or 386 instructions until we check CPU type -----------
Public	Start
Start:
	assume	ds:nothing,es:nothing,ss:nothing

	mov	ax,seg PGROUP	; Get addressability to PGROUP
	mov	ds,ax
	assume	ds:PGROUP	; Tell the assembler

	DISP_STR Init_msg	; Display message

	call	Init		; Perform initialization, return with CF=?
	jc	short Exit_err	; Init failed

	mov	ax,0		; Clear bit 0 for 16-bit application
	mov	es,HPDASEG	; Segment of HPDA
	assume	es:nothing	; Tell assembler ES changed

	call	PM_entry	; Return in PM
	assume	es:nothing	; ES changed

	jc	short Exit_err	; Enter PM failed

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
	may be the same.  In particular, you may NOT use the code selector
	in CS to write to a data location.  The following example code
	will generate a GP fault:

	push	cs		; Copy code segment
	pop	ds
	assume	ds:nothing

	mov	word ptr ds:[0],0ffffh ; This will generate a GP fault
	mov	word ptr cs:[0],0ffffh ; This will, too
	mov	ax,word ptr cs:[0] ; But this is OK

|

	DISP_STR PM_hello	; Tell 'em we're here

	mov	bx,2000h	; 128K
	mov	ah,48h		; Allocate BX paras
	int	21h		; Return AX = selector of allocated block
	jc	short Exit_err	; Jump if we failed

	mov	es,ax		; Segment of allocated block
	mov	eax,'IMPD'      ; Filler pattern
	mov	ecx,20000h / 4	; Number of dwords to fill
	sub	edi,edi 	; Start at beginning of block
   rep	stos	es:[edi].EDD	; Blast away
	db	66h		; NOPD
	nop

	push	es
	push	ds
	pop	es
	assume	es:PGROUP
	pop	ds
	assume	ds:nothing


	mov	al,00h		; Return to DOS with error code 0
	jmp	short Exit	; Join common exit

	Public	Exit_err
Exit_err:
	DISP_STR ERR_failed	; Display generic error message

	mov	al,-1		; Error level to return
;;;;;	jmp	short Exit	; Join common exit code

	Public	Exit
Exit:
; AL contains error code
	mov	ah,4ch		; Terminate process with errorlevel in AL
	int	21h

	int	20h		; In case we're running DOS 4.0
	assume	ds:nothing,es:nothing,ss:nothing


	PPROC	Init
	assume	ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Perform initialization.  Return failure/success in CF.

On entry:
Nothing.

On exit:
CF=0		Initialization succeeded.
CF=1		Initialization failed.

|

	push	ax		; Save registers
	push	bx
	push	cx
	push	dx
	push	si
	push	di

; Check to ensure this is a 286 or better
	push	sp		; 8086: push (++sp); 286+: push sp
	pop	ax		; Get pushed value for comparison
	cmp	ax,sp		; Was it incremented before or after?
	jne	short Init_err	; Join common error code if 8086

;--------- OK to use 286 instructions ------------------------
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

	or	ax,ax		; Are DPMI services present?
	jnz	short Init_err	; Jump if not

; Allocate HPDA in low DOS.  Paragraphs to allocate are in SI.
	mov	ah,48h		; DOS GETMEM function
	mov	bx,si		; Paragraphs needed for HPDA
	int	21h		; CF=?, AX=segment
	jc	short Init_err	; Jump if we couldn't allocate HPDA

	mov	HPDASEG,ax	; Save segment of HPDA

;;;;;	clc			; Indicate success
	jmp	short Init_exit ; Join common exit code

;--------- 8086 instructions only --------------------------
Init_err:
	lea	dx,ERR_failed	; Generic error message
	stc			; Indicate failure

Init_exit:
	pop	di		; Restore registers
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax

	ret

;--------- OK to use 386 instructions -----------------------
	assume	ds:nothing,es:nothing,ss:nothing

Init	endp			; End procedure Init

CODE	ends

	end	Start

; End module HELLO_PM
