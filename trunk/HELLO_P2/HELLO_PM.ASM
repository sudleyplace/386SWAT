	 title	 HELLO_PM -- Say hello in protected mode
	 page	 58,122
	 name	 HELLO_PM

COMMENT|

Copyright (C) 1992-93, Qualitas Inc.  All Rights Reserved.

This program is an example of a DPMI application that enters
protected mode via DPMI services, prints "Hello, world," then
returns to DOS (and V86 mode).

To compile and link:
nmake /f hello_pm.mak

To debug:
swatrun hello_pm

|

if @Version GE 600
OPTION	OLDSTRUCTS		; Allow simplified typecasting
OPTION	READONLY		; Make all code segments READONLY
endif

.486p
.xlist
	include 386.INC
	include PTR.INC
	include DPMI.INC
.list

BEL	equ	07h
CR	equ	0Dh
LF	equ	0Ah
EOS	equ	'$'

NPPROC	macro	@PROCNAME
	Public	@PROCNAME
@PROCNAME proc	near
	endm

FPPROC	macro	@PROCNAME
	Public	@PROCNAME
@PROCNAME proc	far
	endm

DISP_STR macro	@MSG
ifnb <@MSG>
	lea	edx,@MSG
endif
	mov	ah,9		; DOS display string function
	int	21h
	endm

PGROUP	group	CODE,DATA,STACK

; Declare all the segments in the order we want them in the .EXE file
CODE	segment use16 public dword 'CODE'
CODE	ends


DATA	segment use16 public dword 'DATA'
DATA	ends


STACK	segment use16 stack dword 'STACK'
	assume	ds:PGROUP

	dw	1024 dup (?)

STACK	ends


DATA	segment
	assume ds:PGROUP

	public	SelDescDn,SelDescUp
SelDescDn DESC_STR < ?,\
		     ?,\
		     ?,\
		     CPL0_DATA or (mask $DD_EXPD),\
		     0,\
		     ?>
SelDescUp DESC_STR < ?,\
		     ?,\
		     ?,\
		     CPL0_DATA,\
		     0,\
		     ?>

	public	INT0D_FVEC,INT0D_VEC
INT0D_FVEC df	?		; Save area for 32-bit GP Fault handler
INT0D_VEC dd	?		; ...		16-...

	Public	PM_entry,HPDASEG,SelStart,DPMITYPE,CurSel
PM_entry dd	?		; Far entry to DPMI enter PM function
HPDASEG dw	?		; Segment of HPDA in low DOS
SelStart dw	?		; Starting selector
DPMITYPE dw	?		; DPMI type:  0 = 16-bit, 1 = 32-bit client
CurSel	dw	?		; Current selector

	public	NUMBERS_HI
NUMBERS_HI db	'0123456789ABCDEF' ; Conversion table for BIN2HEX_SUB

	public	ROMDATA,ROMDATA_DIR,ROMDATA1
ROMDATA label	byte		; Display area for ROM data
ROMDATA_DIR dw	?		; 'Up' or 'Dn'
	db	', B=G='
ROMDATA_BG db	?		; '0 or '1'
	db	': '            ; Separator
ROMDATA1 db	16 dup ('??')   ; Store ROM data here in hex
	db	', Base = '
ROMDATA_BASE dw 4 dup ('??')    ; Segment base address
	db	', Limit = '
ROMDATA_LIM  dw 4 dup ('??')    ; Segment limit
	db	CR,LF,EOS

	public	MODULUS0,MODULUS1
MODULUS0 db	'The modulus is 64 KB.',CR,LF,EOS
MODULUS1 db	'The modulus is 4 GB.',CR,LF,EOS

	Public	PM_hello,ERR_failed
PM_hello db	'Hello, world from protected mode.',CR,LF,EOS
ERR_failed db	BEL,'Unable to activate DPMI services.',CR,LF,EOS

DATA	ends


CODE	segment
	assume cs:PGROUP

	Public	Start
Start:
	assume	ds:nothing,es:nothing,ss:nothing

	mov	ax,seg PGROUP	; Get addressability to PGROUP
	mov	ds,ax
	assume	ds:PGROUP	; Tell the assembler

	call	Init		; Perform initialization, return with CF=?
	jc	near ptr Exit_err ; Init failed

;;;;;;; mov	ax,0		; Clear bit 0 for 16-bit application
	mov	ax,1		; Set	...	  32-...
	mov	DPMITYPE,ax	; Save for later use
	mov	es,HPDASEG	; Segment of HPDA
	assume	es:nothing	; Tell assembler ES changed

	call	PM_entry	; Return in PM
	assume	ds:PGROUP	; DS same
	assume	es:nothing	; ES changed

	jc	near ptr Exit_err ; Enter PM failed

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
|

	DISP_STR PM_hello	; Tell 'em we're here

	push	ds		; Copy data selector
	pop	es		; ES:0 ==> data segment
	assume	es:PGROUP	; Tell the assembler about it

; Hook the GP Fault handler

	mov	bl,0Dh		; Interrupt handler #
	DPMICALL @DPMI_GETPEHV	; Request DPMI service
				; Return with CX:eDX ==> current handler
;;;;;;; jc	short ???	; Ignore error return

	mov	INT0D_FVEC.FOFF,edx ; Save offset
	mov	INT0D_VEC.VOFF,dx   ; ...
	mov	INT0D_FVEC.FSEL,cx  ; Save selector
	mov	INT0D_VEC.VSEG,cx   ; ...

;;;;;;; mov	bl,0Dh		; Interrupt handler #
	mov	cx,cs		; CX:eDX ==> new handler

	cmp	DPMITYPE,1	; Are we a 32-bit client?
	lea	edx,INT0D_32	; Assume so
	je	short @F	; Jump if so

	lea	edx,INT0D_16	; We are a 16-bit client
@@:
	DPMICALL @DPMI_SETPEHV	; Request DPMI service
;;;;;;; jc	short ???	; Ignore error return


; Allocate selectors

@NSELS	equ	2*(1+2) 	; # selectors to allocate

	mov	cx,@NSELS	; # selectors to allocate
	DPMICALL @DPMI_GETLDT	; Request DPMI service
				; Return with AX = selector
;;;;;;; jc	short ???	; Ignore error return

	mov	SelStart,ax	; Save for later use

SetDesc macro	BASE,LIM,DIR

	mov	SelDesc&DIR.DESC_SEGLM0,(LIM  and 00000FFFFh) shr  0 ; Bits  0-15
	mov	SelDesc&DIR.DESC_BASE01,(BASE and 00000FFFFh) shr  0 ; Bits  0-15
	mov	SelDesc&DIR.DESC_BASE2, (BASE and 000FF0000h) shr 16 ; Bits 16-23
	and	SelDesc&DIR.DESC_SEGLM1,not (mask $SEGLM1) ; Clear Bits 16-19
	or	SelDesc&DIR.DESC_SEGLM1,(LIM  and 0000F0000h) shr 16 ; Bits 16-19
	mov	SelDesc&DIR.DESC_BASE3, (BASE and 0FF000000h) shr 24 ; Bits 24-31
if MODULUS eq 0
	or	SelDesc&DIR.DESC_SEGLM1,(mask $DTE_B) or (mask $DTE_G) ; B=G=1
else
	and	SelDesc&DIR.DESC_SEGLM1,not ((mask $DTE_B) or (mask $DTE_G)); B=G=0
endif
	lea	edi,SelDesc&DIR ; ES:EDI ==> selector descriptor
	mov	bx,SelStart	; Get starting selector
	add	bx,SELNO*8	; Skip to selector #
	mov	CurSel,bx	; Save for later use
	DPMICALL @DPMI_SETLDTE	; Set descriptor
;;;;;;; jc	short ???	; Ignore error return

if MODULUS eq 0
	mov	ROMDATA_BG,'1'
else
	mov	ROMDATA_BG,'0'
endif

if '&DIR' eq 'Up'
	mov	ROMDATA_DIR,'pU'
	ACCDATA 0,%SELNO
else
	mov	ROMDATA_DIR,'nD'
	ACCDATA MODULUS-LEN,%SELNO
endif
SELNO	=	SELNO + 1	; Skip to next selector #
	endm

ACCDATA macro	START,SELNO

	mov	fs,CurSel	; Address it
	assume	fs:nothing	; Tell the assembler about it

	mov	esi,START	; FS:eSI ==> segment offset start
	lea	di,ROMDATA1	; ES:DI ==> save area
	mov	ecx,LEN 	; Get length of the segment
L_ACCDATA&SELNO&A:
if MODULUS eq 65536
	lods	byte ptr fs:[si] ; Get next byte
else
	lods	byte ptr fs:[esi] ; Get next byte
endif
	call	DB2HEX		; Convert AL to ASCII hex at ES:DI
				; Return with DI ==> next byte
L_ACCDATA&SELNO&B:
	loop	L_ACCDATA&SELNO&A ; Jump if more bytes to process

; Get and display the selector's base address

	mov	bx,CurSel	; Get current selector
	DPMICALL @DPMI_GSELBAS	; Request DPMI service
				; Return with CX:DX = base address
;;;;;;; jc	short ???	; Ignore error return

	mov	ax,cx		; Get high-order word
	shl	eax,16		; Shift to high-order
	mov	ax,dx		; Get low-order word
	lea	di,ROMDATA_BASE ; ES:DI ==> output save area
	call	DD2HEX		; Convert EAX to ASCII hex at ES:DI
				; Return with DI ==> next byte
	lsl	eax,ebx 	; Get segment limit
	lea	di,ROMDATA_LIM	; ES:DI ==> output save area
	call	DD2HEX		; Convert EAX to ASCII hex at ES:DI
				; Return with DI ==> next byte

	DISP_STR ROMDATA	; Display the data

	endm

LA	equ	0F0010h
LEN	equ	10h
SELNO	=	0


MODULUS =	64*1024 	; B=G=0
	DISP_STR MODULUS0

	SetDesc %LA		 , %LEN-1	 , Up ; Common
	SetDesc %LA+LEN-MODULUS  , %MODULUS-1-LEN, Dn ; Me
	SetDesc %LA+LEN-MODULUS-1, %MODULUS-LEN  , Dn ; You

MODULUS =	4*1024*1024*1024 ; B=G=1
	DISP_STR MODULUS1

	SetDesc %LA		 , %LEN-1	 , Up ; Common
	SetDesc %LA+LEN-MODULUS  , %MODULUS-1-LEN, Dn ; Me
	SetDesc %LA+LEN-MODULUS-1, %MODULUS-LEN  , Dn ; You

;;;;;;; int	01h		; Call our debugger

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


	NPPROC	Init
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
	NPPROC	DB2HEX
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	push	ecx		; Save for a moment
	mov	ecx,2		; # hex digits
	call	BIN2HEX_SUB	; Handle by subroutine
	pop	ecx		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DB2HEX	endp			; End DB2HEX procedure
	NPPROC	DW2HEX
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	push	ecx		; Save for a moment
	mov	ecx,4		; # hex digits
	call	BIN2HEX_SUB	; Handle by subroutine
	pop	ecx		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DW2HEX	endp			; End DW2HEX procedure
	NPPROC	DD2HEX
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	push	ecx		; Save for a moment
	mov	ecx,8		; # hex digits
	call	BIN2HEX_SUB	; Handle by subroutine
	pop	ecx		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DD2HEX	endp			; End DD2HEX procedure
	NPPROC	BIN2HEX_SUB
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	push	eax		; Save registers
	push	ebx		; ...
	push	edx		; ...

	pushfd			; Save flags
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

	popfd			; Restore flags

	pop	edx		; Restore
	pop	ebx		; ...
	pop	eax		; ...

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2HEX_SUB endp		; End BIN2HEX_SUB procedure
	FPPROC	INT0D_16
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

GP Fault handler for 16-bit client

On entry:

ES:DI	==>	output save area
SS:SP	==>	PMINT16_STR

On exit:

PMINT16_IP changed.

|

GEN16_MAC macro SELNO

	cmp	[bp+2].PMINT16_IP,offset cs:L_ACCDATA&SELNO&A
	jne	short @F	; Jump if not

	mov	[bp+2].PMINT16_IP,offset cs:L_ACCDATA&SELNO&B

	jmp	INT0D_16_DONE	; Join common done code with ZF=1


@@:
	endm

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

SELNO	=	0
	repeat	@NSELS

	GEN16_MAC %SELNO
SELNO	=	SELNO + 1
	endm

	pop	bp		; Restore

	jmp	INT0D_FVEC	; Continue with next handler in sequence


INT0D_16_DONE:
	inc	si	       ; Skip to next source byte
	mov	word ptr es:[di],'??' ; Mark as GP Fault
	add	di,2		; Skip to next output word

	pop	bp		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT0D_16 endp			; End INT0D_16 procedure
	FPPROC	INT0D_32
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

GP Fault handler for 32-bit client

On entry:

ES:DI	==>	output save area
SS:SP	==>	PMINT32_STR

On exit:

PMINT32_EIP changed.

|

GEN32_MAC macro SELNO

	cmp	[ebp+4].PMINT32_EIP,offset cs:L_ACCDATA&SELNO&A
	jne	short @F	; Jump if not

	mov	[ebp+4].PMINT32_EIP,offset cs:L_ACCDATA&SELNO&B

	jmp	INT0D_32_DONE	; Join common done code


@@:
	endm

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

SELNO	=	0
	repeat	@NSELS

	GEN32_MAC %SELNO
SELNO	=	SELNO + 1
	endm

	pop	ebp		; Restore

	jmp	INT0D_FVEC	; Continue with next handler in sequence


INT0D_32_DONE:
	inc	si	       ; Skip to next source byte
	mov	word ptr es:[di],'??' ; Mark as GP Fault
	add	di,2		; Skip to next output word

	pop	ebp		; Restore

	retd			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT0D_32 endp			; End INT0D_32 procedure

CODE	ends

	end	Start		; End module HELLO_PM