;' $Header$
	title	SWAT_MMX -- 386SWAT MMX and SSE Functions
	page	58,122
	name	SWAT_MMX

COMMENT|		Module Specifications

Copyright:  (C) Copyright 2001-2002 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, January, 2001.

Modifications by:  None.


|
.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include CPUFET.INC
	include MMXSSE.INC
	include MOVSPR.INC
	include IOPBITS.INC

	include SWAT_COM.INC
	include SWAT_SEG.INC
.list

DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	public	@SWAT_MMX_DATA16
@SWAT_MMX_DATA16 label byte	; Mark module start in .MAP file

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	MMXATTR:byte

	extrn	CPUFET_FLAG:dword

	public	PFXSAVE
PFXSAVE dd	?		; Offset in DGROUP of FXSAVE buffer

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	@SWAT_MMX_DATA
@SWAT_MMX_DATA label byte	; Mark module start in .MAP file

	extrn	MSGOFF:dword
	extrn	SYNTERR:byte
	extrn	MMXERR:byte

; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; MMX data values
; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

@NMMX	equ	8		; # MMX registers
@NXMM	equ	8		; # XMM registers

	public	W_MMX
W_MMX	W_STR	<>		; Temporary window structure

	public	MMX_WIN
MMX_WIN db	'ีอออออออออออออ MMX Registers อออออออออออออธ'
NMMXCOLS equ	$-MMX_WIN	; # cols in MMX window
MMX_LN1 db	'ณ MMX0 = ________________                 ณ'
	db	'ณ MMX1 = ________________                 ณ'
	db	'ณ MMX2 = ________________                 ณ'
	db	'ณ MMX3 = ________________                 ณ'
	db	'ณ MMX4 = ________________                 ณ'
	db	'ณ MMX5 = ________________                 ณ'
	db	'ณ MMX6 = ________________                 ณ'
	db	'ณ MMX7 = ________________                 ณ'
XMM_WIN db	'รฤฤฤฤฤฤฤฤฤฤฤฤฤ XMM Registers ฤฤฤฤฤฤฤฤฤฤฤฤฤด'
NXMMCOLS equ	$-XMM_WIN	; # cols in XMM window
XMM_LN1 db	'ณ XMM0 =  SSE not supported on this CPU   ณ'
	db	'ณ XMM1 = ________________________________ ณ'
	db	'ณ XMM2 = ________________________________ ณ'
	db	'ณ XMM3 = ________________________________ ณ'
	db	'ณ XMM4 = ________________________________ ณ'
	db	'ณ XMM5 = ________________________________ ณ'
	db	'ณ XMM6 = ________________________________ ณ'
	db	'ณ XMM7 = ________________________________ ณ'
	db	'ิอออออออออออออออออออออออออออออออออออออออออพ'
NMMXROWS equ	($-MMX_WIN)/NMMXCOLS ; # rows in MMX window

MMX_WIN_IN0 equ 5		; Offset from MMX_LN1 to register index
MMX_WIN_HI0 equ 9		; ...				  value (high-dword)
MMX_WIN_LO0 equ 17		; ...				  value (low-dword)
XMM_WIN_IN0 equ 5		; Offset from XMM_LN1 to register index
XMM_WIN_HI0 equ 9		; ...				  value (high-dword)
XMM_WIN_HI1 equ 17		; ...				  value (high-dword)
XMM_WIN_LO0 equ 25		; ...				  value (low-dword)
XMM_WIN_LO1 equ 33		; ...				  value (low-dword)

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP

	public	@SWAT_MMX_PROG
@SWAT_MMX_PROG: 		; Mark module start in .MAP file

	extrn	CMD_WHITE:near
	extrn	WPUT_CSA:near
	extrn	BIN2DWORD:near
	extrn	SET_STATE:near

	NPPROC	CMD_MMX -- MMX Registers Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

MMX Register display command

MMX

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax,esi>	; Save registers

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	jne	near ptr CMD_MMX_SYNTERR ; Jump if error

	test	CPUFET_FLAG,mask $CPUFET_FXSR ; Is FXSAVE supported?
	jz	short CMD_MMX_XAVL ; Jump if not

	test	CPUFET_FLAG,mask $CPUFET_MMX ; Is MMX supported?
	jz	short CMD_MMX_XAVL ; Jump if not

	call	DISP_MMX	; Display 'em

	clc			; Indicate all went well

	jmp	short CMD_MMX_EXIT ; Join common exit code


CMD_MMX_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	jmp	short CMD_MMX_ERR ; Join common error code


CMD_MMX_XAVL:
	mov	MSGOFF,offset DGROUP:MMXERR ; Save offset of error message
CMD_MMX_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_MMX_EXIT:
	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_MMX endp			; End CMD_MMX procedure
	NPPROC	DISP_MMX -- MMX and SSE Register Display
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display MMX and SSE register values

|

	pushad			; Save all EGP registers

; Handle DSP_STATE & DSP_STAT2

; *FIXME*


; Save MMX registers into memory

	clts			; Ensure no pending interrupts

; Ensure that we execute an MMX instruction so that FXSAVE saves
; the MMX registers instead of the FPU registers

	MOVD	eax,mm0 	; Any MMX instruction will do

; Ensure that the OSFXSR bit is set in CR4

	MOVSPR	eax,cr4 	; Get current Arch Ext register
	mov	ecx,eax 	; Save original value to restore later
	or	eax,@OSFXSR	; Set the bit
	MOVSPR	cr4,eax 	; Tell the CPU about it

	mov	ebx,PFXSAVE	; Get offset in DGROUP of FXSAVE buffer
	FXSAVE	DGROUP:[ebx]	; Save the state

	MOVSPR	cr4,ecx 	; Restore original value

; Format MMX registers into window

	mov	ecx,@NMMX	; Get # MMX registers
	xor	esi,esi 	; Initialize index
	lea	edx,MMX_LN1	; Initialize index into MMX_WIN
DISP_MMX_NEXT:
	mov	eax,DGROUP:[ebx+esi].FXSAVE_ST0MM0.EDQHI ; Get MMX register value
	lea	edi,MMX_WIN_HI0[edx] ; ES:EDI ==> register display
	call	BIN2DWORD	; Convert the dword

	mov	eax,DGROUP:[ebx+esi].FXSAVE_ST0MM0.EDQLO ; Get MMX register value
	lea	edi,MMX_WIN_LO0[edx] ; ES:EDI ==> register display
	call	BIN2DWORD	; Convert the dword

	add	esi,16		; Skip to next row in FXSAVE_STR
	add	edx,NMMXCOLS	; Skip to next row in MMX_WIN

	loop	DISP_MMX_NEXT	; Jump if more rows to format

; Format XMM registers into window

	test	CPUFET_FLAG,mask $CPUFET_SSE ; Are they present?
	jz	short DISP_XMM_EXIT ; Jump if not

	mov	ecx,@NXMM	; Get # XMM registers
	xor	esi,esi 	; Initialize index
	lea	edx,XMM_LN1	; Initialize index into MMX_WIN
DISP_XMM_NEXT:
	mov	eax,DGROUP:[ebx+esi].FXSAVE_XMM0.EDQ2HI.EDQHI ; Get XMM register value
	lea	edi,XMM_WIN_HI0[edx] ; ES:EDI ==> register display
	call	BIN2DWORD	; Convert the dword

	mov	eax,DGROUP:[ebx+esi].FXSAVE_XMM0.EDQ2HI.EDQLO ; Get XMM register value
	lea	edi,XMM_WIN_HI1[edx] ; ES:EDI ==> register display
	call	BIN2DWORD	; Convert the dword

	mov	eax,DGROUP:[ebx+esi].FXSAVE_XMM0.EDQ2LO.EDQHI ; Get XMM register value
	lea	edi,XMM_WIN_LO0[edx] ; ES:EDI ==> register display
	call	BIN2DWORD	; Convert the dword

	mov	eax,DGROUP:[ebx+esi].FXSAVE_XMM0.EDQ2LO.EDQLO ; Get XMM register value
	lea	edi,XMM_WIN_LO1[edx] ; ES:EDI ==> register display
	call	BIN2DWORD	; Convert the dword

	add	esi,16		; Skip to next row in FXSAVE_STR
	add	edx,NXMMCOLS	; Skip to next row in XMM_WIN

	loop	DISP_XMM_NEXT	; Jump if more rows to format
DISP_XMM_EXIT:

; Display the window

	mov	W_MMX.SROW,(@NROWS-NMMXROWS)/2 ; Start in middle row
	mov	W_MMX.SCOL,(@NCOLS-NMMXCOLS)/2 ; Start in middle col
	mov	W_MMX.NROW,NMMXROWS ; # rows in debug window
	mov	W_MMX.NCOL,NMMXCOLS ; # cols ...

	mov	al,MMXATTR	; Get MMX window attribute
	push	ax		; Pass as attribute to smear
	push	offset ds:MMX_WIN ; Pass address of debug window
	push	offset ds:W_MMX ; Pass address of window descriptor
	call	WPUT_CSA	; Output the characters, smear attribute

	mov	al,@DSP_MMX	; Set new display state
	call	SET_STATE	; Set new state

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_MMX endp			; End DISP_MMX procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_MMX module
