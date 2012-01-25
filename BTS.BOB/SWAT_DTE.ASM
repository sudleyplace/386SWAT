;' $Header:   P:/PVCS/386SWAT/SWAT_DTE.ASV   1.23   20 Aug 1998 23:05:52   BOB  $
	title	SWAT_DTE -- 386SWAT DTE Display Routines
	page	58,122
	name	SWAT_DTE

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-1999 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.


|
.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include ALLMEM.INC
	include IOPBITS.INC
	include MOVSPR.INC
	include CPUFET.INC
	include MAC.INC

	include SWAT_COM.INC
	include SWAT_SEG.INC
	include PDTGRP.INC
	include MAXDEV.INC
	include DEBUGSYS.INC
.list

SWAPIDT macro	NUM,NAM

	mov	ax,KEYINT&NAM&_FVEC.FSEL ; Get original selector
	xchg	ax,gs:[esi+&NUM&*(size IDT_STR)].IDT_SELECT ; Save it back
	mov	[ebp].SWAP_INTS.SWAP_I&NAM.IDT_SELECT,ax ; Save selector

	mov	eax,KEYINT&NAM&_FVEC.FOFF ; Get original offset
	xchg	ax,gs:[esi+&NUM&*(size IDT_STR)].IDT_OFFLO ; Save it back
	mov	[ebp].SWAP_INTS.SWAP_I&NAM.IDT_OFFLO,ax ; Save low-order word of offset

	shr	eax,16		; Shift down the high-order word
	xchg	ax,gs:[esi+&NUM&*(size IDT_STR)].IDT_OFFHI ; Save it back
	mov	[ebp].SWAP_INTS.SWAP_I&NAM.IDT_OFFHI,ax ; Save high-order word of offset

	mov	al,KEYINT&NAM&_ARB ; Get original ARB
	xchg	al,gs:[esi+&NUM&*(size IDT_STR)].IDT_ACCESS ; Save it back
	mov	[ebp].SWAP_INTS.SWAP_I&NAM.IDT_ACCESS,al ; Save A/R byte

	endm			; SWAPIDT

RESTIDT macro	NUM,NAM

	mov	al,[ebp].SWAP_INTS.SWAP_I&NAM.IDT_ACCESS ; Get ARB
	mov	gs:[esi+&NUM&*(size IDT_STR)].IDT_ACCESS,al ; Save it back

	mov	ax,[ebp].SWAP_INTS.SWAP_I&NAM.IDT_OFFHI ; Get OFFHI
	mov	gs:[esi+&NUM&*(size IDT_STR)].IDT_OFFHI,ax ; Save it back

	mov	ax,[ebp].SWAP_INTS.SWAP_I&NAM.IDT_OFFLO ; Get OFFLO
	mov	gs:[esi+&NUM&*(size IDT_STR)].IDT_OFFLO,ax ; Save it back

	mov	ax,[ebp].SWAP_INTS.SWAP_I&NAM.IDT_SELECT ; Get SELECT
	mov	gs:[esi+&NUM&*(size IDT_STR)].IDT_SELECT,ax ; Save it back

	endm			; RESTIDT


DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	public	@SWAT_DTE_DATA16
@SWAT_DTE_DATA16 label byte	; Mark module start in .MAP file

	extrn	COMMON:tbyte
	include SWAT_FIL.INC

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	DEFATTR:byte
	extrn	TTLATTR:byte

	extrn	CPUFET_FLAG:dword

	extrn	MACBASE:dword
	extrn	MACOFF:dword
	extrn	ORG_GDINT01_OFF:dword

	public	BLCLPDIR
BLCLPDIR dd	?		; Base offset in DGROUP of local PDIR (byte boundary)

	public	PLCLPDIR,PaLCLPDIR
PLCLPDIR dd	?		; Offset in DGROUP of local PDIR (4KB boundary)
PaLCLPDIR dd	?		; Physical address of local PDIR

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	@SWAT_DTE_DATA
@SWAT_DTE_DATA label byte	; Mark module start in .MAP file

	extrn	PTE_START:dword
	extrn	PTE_NEXT:dword
	extrn	PTE_SEQ:dword
	extrn	PDE_START:dword
	extrn	PDE_SEQ:dword
	extrn	SCROFF:dword
	extrn	CON4KB:dword
	extrn	CON8KB:dword
	extrn	CON4MB:dword

	extrn	KEYINT08_FVEC:fword
	extrn	KEYINT08_ARB:byte
	extrn	KEYINT09_FVEC:fword
	extrn	KEYINT09_ARB:byte
	extrn	KEYINT0A_FVEC:fword
	extrn	KEYINT0A_ARB:byte
	extrn	KEYINT0F_FVEC:fword
	extrn	KEYINT0F_ARB:byte
	extrn	KEYINT74_FVEC:fword
	extrn	KEYINT74_ARB:byte
	extrn	KEYINT76_FVEC:fword
	extrn	KEYINT76_ARB:byte
	extrn	KEYINT77_FVEC:fword
	extrn	KEYINT77_ARB:byte

	extrn	GDTOFF:dword
	extrn	IDTOFF:dword
	extrn	LDTOFF:dword
	extrn	IVTNDX:dword
	extrn	SWATDATA:dword

	extrn	MSGOFF:dword
	extrn	NOWINERR:byte
	extrn	SYNTERR:byte
	extrn	OVFERR:byte
	extrn	SELERR:byte

	public	LCL_PDE,LCL_CR3,INIT_PDELIN
LCL_PDE dd	?		; Saved PDE from DISP_PTE
LCL_CR3 dd	?		; ...	CR3 ...
INIT_PDELIN dd	?		; Initial @PDELIN value for DISP_PTE

	public	CURCR4
CURCR4	dd	?		; Current value for CR4 (set in SETUP)

	public	PDISPTRUNC
PDISPTRUNC dd	offset PGROUP:DISPTRUNC ; Ptr to DISPTRUNC

	public	IOMAP_LINE,IOMAP_LINE_MAX
IOMAP_LINE dd	0		; I/O bit permission starting line #
IOMAP_LINE_MAX dd -1		; Last line in I/O bit permission map

	public	DTE_TYP
DTE_TYP dw	?

	public	DTE_TYPFL
DTE_TYPFL dw	0		; DISP_DTE type flags
@DTE_TYP0 equ	0001h		; Type 0 error
@DTE_TYP1 equ	0002h		; ...  1 ...

	public	MSG_IDTE
MSG_IDTE label	byte
MSG_IDTE0 db	'__  '
MSG_IDTE1 db	'____|'
MSG_IDTE2 db	'________  ('
MSG_IDTE3 db	'________) '
MSG_IDTE4 db	'__  '
	db	0

	public	MSG_GDTR,MSG_IDTR,MSG_LDTR
MSG_GDTR db	' -- GDTR = ',0
MSG_IDTR db	' -- IDTR = ',0
MSG_LDTR db	' -- LDTR = ',0

	public	MSG_IDT
MSG_IDT db	'Int  '
	db	'Sel|Offset    '
	db	'(Lin Addr) '
	db	'A/R '
	db	'Type PL  '
	db	'Class'
	db	0

	public	MSG_IVT
MSG_IVT db	'Int '
	db	' Seg:Off   Linear Addr'
	db	0

	public	MSG_IVTE
MSG_IVTE label	byte
MSG_IVTE0 db	'__  '
MSG_IVTE1 db	'____:'
MSG_IVTE2 db	'____   '
MSG_IVTE3 db	'________  '
MSG_IVTE4 db	'________  '
	db	0

	public	MSG_IVTE_NOMAC
MSG_IVTE_NOMAC db '--------'

	public	MSG_IVTE_FREE
MSG_IVTE_FREE db '*** POINTS INTO FREE SPACE ***',0

	public	MSG_DTE
MSG_DTE db	'Indx  '
	db	'Base Addr '
	db	'Limit     '
	db	'A/R  '
	db	'Type PL  '
	db	'Class'
	db	0

	public	MSG_TSS1,MSG_TSS2
MSG_TSS1 db	'ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ TSS ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ'
	db	0
MSG_TSS2 db	'Sel   Base Addr Limit     A/R  Type PL  Class'
	db	0

	public	MSG_PTE
;;;;;;;  db	'PTEs:  CR3 ________ (PDE ________) -- Linear addresses ________ to ________',0
MSG_PTE db	'PTEs:  CR3 '
MSG_PTE1 db	'________ (PDE '
MSG_PTE2 db	'________) -- Linear addresses '
MSG_PTE3 db	'________ to '
MSG_PTE4 db	'________',0

	public	MSG_PDE
;;;;;;;  db	'PDEs:  CR3 ________ -- Linear addresses ________ to ________',0
MSG_PDE db	'PDEs:  CR3 '
MSG_PDE1 db	'________ -- Linear addresses '
MSG_PDE2 db	'________ to '
MSG_PDE3 db	'________',0

	public	MSG_GDTE
MSG_GDTE label	byte
MSG_GDTE0 db	'____  '
MSG_GDTE1 db	'________  '
MSG_GDTE2 db	'________  '
MSG_GDTE3 db	'___  '
	db	0

	public	MSG_SYST,MSG_CODE,MSG_DATA
MSG_SYST db	'Syst '
MSG_SYST1 db	'_:  ',0
MSG_CODE db	'Code '
MSG_CODE1 db	'_:  ',0
MSG_DATA db	'Data '
MSG_DATA1 db	'_:  ',0

	public	SYS_TYPE
	align	4
SYS_TYPE dd	offset DGROUP:SDTE_0
	dd	offset DGROUP:SDTE_1
	dd	offset DGROUP:SDTE_2
	dd	offset DGROUP:SDTE_3
	dd	offset DGROUP:SDTE_4
	dd	offset DGROUP:SDTE_5
	dd	offset DGROUP:SDTE_6
	dd	offset DGROUP:SDTE_7
	dd	offset DGROUP:SDTE_8
	dd	offset DGROUP:SDTE_9
	dd	offset DGROUP:SDTE_A
	dd	offset DGROUP:SDTE_B
	dd	offset DGROUP:SDTE_C
	dd	offset DGROUP:SDTE_D
	dd	offset DGROUP:SDTE_E
	dd	offset DGROUP:SDTE_F

SDTE_0	db	'Reserved',0
SDTE_1	db	'Available 286 TSS',0
SDTE_2	db	'LDT',0
SDTE_3	db	'Busy 286 TSS',0
SDTE_4	db	'286 Call gate',0
SDTE_5	db	'Task gate',0
SDTE_6	db	'286 interrupt gate',0
SDTE_7	db	'286 trap gate',0
SDTE_8	db	'Reserved',0
SDTE_9	db	'Available 386 TSS',0
SDTE_A	db	'Reserved',0
SDTE_B	db	'Busy 386 TSS',0
SDTE_C	db	'386 call gate',0
SDTE_D	db	'Reserved',0
SDTE_E	db	'386 interrupt gate',0
SDTE_F	db	'386 trap gate',0

	public	CODE_TYPE
	align	4
CODE_TYPE dd	offset DGROUP:CDTE_00
	dd	offset DGROUP:CDTE_01
	dd	offset DGROUP:CDTE_02
	dd	offset DGROUP:CDTE_03
	dd	offset DGROUP:CDTE_04
	dd	offset DGROUP:CDTE_05
	dd	offset DGROUP:CDTE_06
	dd	offset DGROUP:CDTE_07
	dd	offset DGROUP:CDTE_08
	dd	offset DGROUP:CDTE_09
	dd	offset DGROUP:CDTE_0A
	dd	offset DGROUP:CDTE_0B
	dd	offset DGROUP:CDTE_0C
	dd	offset DGROUP:CDTE_05
	dd	offset DGROUP:CDTE_0E
	dd	offset DGROUP:CDTE_0F

CDTE_00 db	'Exec-only',0
CDTE_01 db	'Exec-only, accessed',0
CDTE_02 db	'Readable',0
CDTE_03 db	'Readable, accessed',0
CDTE_04 db	'Conforming, exec-only',0
CDTE_05 db	'Conforming, exec-only, accessed',0
CDTE_06 db	'Conforming, readable',0
CDTE_07 db	'Conforming, readable, accessed',0
CDTE_08 db	'Use32, exec-only',0
CDTE_09 db	'Use32, exec-only, accessed',0
CDTE_0A db	'Use32, readable',0
CDTE_0B db	'Use32, readable, accessed',0
CDTE_0C db	'Use32, conforming, exec-only',0
CDTE_0D db	'Use32, conforming, exec-only, accessed',0
CDTE_0E db	'Use32, conforming, readable',0
CDTE_0F db	'Use32, conforming, readable, accessed',0

	public	DATA_TYPE
	align	4
DATA_TYPE dd	offset DGROUP:DDTE_00
	dd	offset DGROUP:DDTE_01
	dd	offset DGROUP:DDTE_02
	dd	offset DGROUP:DDTE_03
	dd	offset DGROUP:DDTE_04
	dd	offset DGROUP:DDTE_05
	dd	offset DGROUP:DDTE_06
	dd	offset DGROUP:DDTE_07
	dd	offset DGROUP:DDTE_08
	dd	offset DGROUP:DDTE_09
	dd	offset DGROUP:DDTE_0A
	dd	offset DGROUP:DDTE_0B
	dd	offset DGROUP:DDTE_0C
	dd	offset DGROUP:DDTE_0D
	dd	offset DGROUP:DDTE_0E
	dd	offset DGROUP:DDTE_0F

DDTE_00 db	'Read-only',0
DDTE_01 db	'Read-only, accessed',0
DDTE_02 db	'Writable',0
DDTE_03 db	'Writable, accessed',0
DDTE_04 db	'Expand down, read-only',0
DDTE_05 db	'Expand down, read-only, accessed',0
DDTE_06 db	'Expand down, writable',0
DDTE_07 db	'Expand down, writable, accessed',0
DDTE_08 db	'Big, read-only',0
DDTE_09 db	'Big, read-only, accessed',0
DDTE_0A db	'Big, writable',0
DDTE_0B db	'Big, writable, accessed',0
DDTE_0C db	'Big, expand down, read-only',0
DDTE_0D db	'Big, expand down, read-only, accessed',0
DDTE_0E db	'Big, expand down, writable',0
DDTE_0F db	'Big, expand down, writable, accessed',0

	public	MSG_PRES
MSG_PRES db	', present',0

	public	MSG_TSSL0
MSG_TSSL0 db	'TSS Sel: ',0

	public	MSG_TSSL1
MSG_TSSL1 db	'Back link: '
MSG_TSS_LINK db '____  PL0: '
MSG_TSS_SS0 db	'____|'
MSG_TSS_ESP0 db '________  PL1: '
MSG_TSS_SS1 db	'____|'
MSG_TSS_ESP1 db '________  PL2: '
MSG_TSS_SS2 db	'____|'
MSG_TSS_ESP2 db '________',0

	public	MSG_TSSL2
MSG_TSSL2 db	'CR3: '
MSG_TSS_CR3 db	'________  LDT: '
MSG_TSS_LDT db	'____  Debug: '
MSG_TSS_DBG db	'____  I/O base: '
MSG_TSS_IO db	'____',0

	public	MSG_TSSL3
MSG_TSSL3 db	'EFL: '
MSG_TSS_EFL db	'________  EAX: '
MSG_TSS_EAX db	'________  EBX: '
MSG_TSS_EBX db	'________  ECX: '
MSG_TSS_ECX db	'________  EDX: '
MSG_TSS_EDX db	'________',0

	public	MSG_TSSL4
MSG_TSSL4 db	'EIP: '
MSG_TSS_EIP db	'________  ESI: '
MSG_TSS_ESI db	'________  EDI: '
MSG_TSS_EDI db	'________  ESP: '
MSG_TSS_ESP db	'________  EBP: '
MSG_TSS_EBP db	'________',0

	public	MSG_TSSL5
MSG_TSSL5 db	' CS: '
MSG_TSS_CS db	'____       DS: '
MSG_TSS_DS db	'____       ES: '
MSG_TSS_ES db	'____       SS: '
MSG_TSS_SS db	'____       FS: '
MSG_TSS_FS db	'____  GS: '
MSG_TSS_GS db	'____',0

	public	MSG_IOMAP_HDR,MSG_IOMAP
MSG_IOMAP_HDR db 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ I/O Bit Permission Map ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',0
MSG_IOMAP db	((6+4)*8) dup (' '),0

	public	MSG_SIRB_HDR
MSG_SIRB_HDR db 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Software Interrupt Redirection Map ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',0
MSG_SIRB equ	MSG_IOMAP

	public	BufIndex,Buffer
	align	4
BufIndex dd	?		; Index into buffer
Buffer	db	128 dup (?)	; The local buffer for DISP2BUF

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP,ds:PGROUP

	public	@SWAT_DTE_PROG
@SWAT_DTE_PROG: 		; Mark module start in .MAP file

	extrn	SWATINI:tbyte

	extrn	REMROW:near
	extrn	BIN2DIGIT:near
	extrn	BIN2BYTE:near
	extrn	BIN2WORD:near
	extrn	BIN2DWORD:near
	extrn	GETBASE:near
	extrn	GETLBASE:near
	extrn	DISPTXT:near
	extrn	DISPTRUNC:near
	extrn	DISPASCIIZ:near
	extrn	NEXTLINE:near
	extrn	DISPHEX1:near
	extrn	DISPHEX2:near
	extrn	DISPHEX4:near
	extrn	DISPROWPTE:near
	extrn	DISPROWPDE:near
	extrn	DISP_SREG:near
	extrn	CLEAR_EOL:near
	extrn	CLEAR_EOP:near
	extrn	READ_CR3:near
	extrn	FLUSH_CACHE:near
	extrn	LIN2PPDIR:near
	extrn	LIN2PPTEZ:near
	extrn	CMD_WHITE:near
	extrn	PARSE_EXPR:near
	extrn	GETLADTE:near
	extrn	DISP_CMDLINE:near
	extrn	COPYTO_CMDLINE:near
	extrn	PURGE_KBUFF:near
	extrn	GETNDKEY:near
	extrn	IZIT_PSE:near

	NPPROC	DISP_IVT -- Display The IVT Entries
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display the entries in the RM IVT.

On entry:

SS:EBP	==>	FORW_STR
GS	=	DTE_D4GB

|

	pushad			; Save all EGP registers

; If we're in Windows and Win386 services aren't available
; skip this display as we can't be sure that low memory (the
; first megabyte is mapped in.	If they are available, map in
; the first megabyte, and unmap it on the way out.

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	jz	short @F	; Jump if not

	test	SWATINI.MD_ATTR,@MD_WSVC ; Are Win386 services available?
	jz	near ptr DISP_IVT_ERR ; Jump if not

	mov	eax,Win386_MapVM ; Function code to map in VM's low memory
	int	Win386_Query_Int ; Request Win386 services
@@:
	mov	SCROFF,0	; Start at top of screen

	mov	bl,TTLATTR	; Get title attribute
	xchg	bl,DEFATTR	; Swap with default attribute

	lea	esi,MSG_IVT	; Line 1 of IVT header
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line

	xchg	bl,DEFATTR	; Restore default attribute
	call	NEXTLINE	; End the line

	cmp	IVTNDX,0FFh	; Check maximum value
	jbe	short @F	; Jump if within range

	mov	IVTNDX,0FFh	; Save for next time
@@:

; Display the smaller of the Remaining Rows and (Size-Offset)

	call	REMROW		; Return with ECX = # remaining rows
	dec	ecx		; Back off to allow room for command line

	mov	ebx,100h	; Copy maximum index
	mov	edx,IVTNDX	; Get current index
	sub	ebx,edx 	; Less index

	cmp	ecx,ebx 	; Use the smaller of the two
	jbe	short @F	; Jump if REMROW is smaller

	mov	ecx,ebx 	; (Max-index) is smaller
@@:
IVTR_NEXT:
	call	DISP_IVTLIN	; Display a line's worth

	loop	IVTR_NEXT	; Jump if more entries

	call	CLEAR_EOP	; Clear to the end-of-the-page

; If we're in Windows and the Win386 services are available
; unmap the first megabyte.

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	jz	short @F	; Jump if not

; @MD_WSC already checked above
;;;;;;; test	SWATINI.MD_ATTR,@MD_WSVC ; Are Win386 services available?
;;;;;;; jz	short @F	; Jump if not

	mov	eax,Win386_UnmapVM ; Function code to map out VM's low memory
	int	Win386_Query_Int ; Request Win386 services
@@:
	jmp	short DISP_IVT_EXIT ; Join common exit code


DISP_IVT_ERR:
	mov	MSGOFF,offset DGROUP:NOWINERR ; Save offset of error message
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display
DISP_IVT_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_IVT endp			; End DISP_IVT procedure
	NPPROC	DISP_IVTLIN -- Display IVT Line
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display a single IVT line.

On entry:

EDX	=	index value

On exit:

EDX	=	updated

|

	REGSAVE <eax,ebx,ecx,esi,edi> ; Save registers

; Display the interrupt #

	mov	ax,dx		; Copy index value
	lea	edi,MSG_IVTE0[0] ; Put result here
	call	BIN2BYTE	; Convert AL to hex at ES:EDI

; Display the segment:offset

	clc			; Assume no error
	mov	eax,gs:[edx*4]	; Get the segment:offset
	jc	near ptr DISP_IVTLIN_ERR1 ; Jump on error

	lea	edi,MSG_IVTE2[0] ; Put result here
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	ror	eax,16		; Swap high- and low-order words
	lea	edi,MSG_IVTE1[0] ; Put result here
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display the 32-bit linear address

	movzx	ebx,ax		; Copy the segment
	shl	ebx,4-0 	; Convert from paras to bytes
	shr	eax,16		; Shift the offset down
	add	eax,ebx 	; Add to get the linear address
	lea	edi,MSG_IVTE3[0] ; Put result here
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

; Lookup this linear address in the MAC chain

	mov	esi,MACBASE	; Get current base
	add	esi,MACOFF	; Plus current offset

	cmp	eax,esi 	; Izit below the first entry?
	jb	short DISP_IVTLIN_NOMAC ; Jump if so
DISP_IVTLIN_NEXTMAC:
	movzx	edi,AGROUP:[esi].MAC_NPAR ; Get # paras in MAC entry
	inc	edi		; Skip over the MAC para
	shl	edi,4-0 	; Convert from paras to bytes
	add	edi,esi 	; Skip to next entry

	cmp	eax,edi 	; Izit below the next entry?
	jb	short DISP_IVTLIN_THISMAC ; Jump if so (it's a match)
@@:
	mov	esi,edi 	; Skip to next entry

	jmp	DISP_IVTLIN_NEXTMAC ; Go around again


DISP_IVTLIN_NOMAC:
	push	esi		; Save MAC linear address

	lea	esi,MSG_IVTE_NOMAC ; DS:ESI ==> text to display
	add	esi,SWATDATA	; Plus linear address of DGROUP

	jmp	short DISP_IVTLIN_COMMAC ; Join common code


DISP_IVTLIN_THISMAC:
	push	esi		; Save MAC linear address

	lea	esi,AGROUP:[esi].MAC_NAME ; Point to MAC name (if present)
DISP_IVTLIN_COMMAC:
	lea	edi,MSG_IVTE4	; ES:EDI ==> save area for MAC name
	mov	ecx,8		; # bytes in MAC_NAME
DISP_IVTLIN_NEXTNAME:
	lods	AGROUP:[esi].LO ; Get next byte

	cmp	al,0		; Izit ASCIIZ terminator?
	je	short DISP_IVTLIN_TAIL ; Jump if so

S32	stos	MSG_IVTE4[edi]	; Save in string

	loop	DISP_IVTLIN_NEXTNAME ; Jump if more chars in name

	jmp	short DISP_IVTLIN_DISP ; Join common code


DISP_IVTLIN_TAIL:
	mov	al,' '          ; Substitute a blank
    rep stos	MSG_IVTE4[edi]	; Save in string
DISP_IVTLIN_DISP:
	lea	esi,MSG_IVTE	; DS:ESI ==> string to display
	call	PDISPTRUNC	; Display truncated ASCIIZ string from ESI

	pop	esi		; Restore MAC linear address

; If the entry is free, complain

	cmp	AGROUP:[esi].MAC_OWNR,@MAC_FREE ; Izit free?
	jne	short @F	; Jump if not

	lea	esi,MSG_IVTE_FREE ; DS:ESI ==> string to display
	call	PDISPTRUNC	; Display truncated ASCIIZ string from ESI
@@:
	jmp	short DISP_IVTLIN_COM ; Join common code

DISP_IVTLIN_ERR1:
	mov	MSG_IVTE1[0].EDD,'????' ; ...
	mov	MSG_IVTE2[0].EDD,'????' ; ...
	mov	MSG_IVTE3[0].EDQLO,'????' ; ...
	mov	MSG_IVTE3[0].EDQHI,'????' ; ...

	lea	esi,MSG_IVTE	; DS:ESI ==> string to display
	call	PDISPTRUNC	; Display truncated ASCIIZ string from ESI
DISP_IVTLIN_COM:
	inc	edx		; Skip to next entry

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

	REGREST <edi,esi,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_IVTLIN endp		; End DISP_IVTLIN procedure
	NPPROC	DISP_IDT -- Display The IDT Entries
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the entries in the IDT.

On entry:

SS:EBP	==>	FORW_STR
GS	=	DTE_D4GB

|

	pushad			; Save all EGP registers

	pushfd			; Save flags
	cli			; Disallow interrupts

; Swap back the original interrupts which we've hooked

	call	SWAP_OLDINTS	; Swap 'em using SS|EBP and GS

	mov	SCROFF,0	; Start at top of screen

	mov	bl,TTLATTR	; Get title attribute
	xchg	bl,DEFATTR	; Swap with default attribute

	lea	esi,MSG_IDT	; Line 1 of IDT header
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	lea	esi,MSG_IDTR	; Display "IDT=" text
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	mov	ax,[ebp-@BPBACK].BACK_IDT.DTR_LIM ; Get IDTR limit
	call	DISPHEX2	; Display the word

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

	mov	eax,[ebp-@BPBACK].BACK_IDT.DTR_BASE ; Get IDTR base
	call	DISPHEX4	; Display the dword
	call	CLEAR_EOL	; Clear to the end-of-the-line

	xchg	bl,DEFATTR	; Restore default attribute
	call	NEXTLINE	; End the line

	movzx	eax,[ebp-@BPBACK].BACK_IDT.DTR_LIM ; Get selector limit
	inc	eax		; Convert from limit to length
	mov	edx,IDTOFF	; Get the current GDT offset

	cmp	eax,edx 	; Check relative value
	ja	short @F	; Jump if Size > Offset

	mov	edx,eax 	; Copy as new offset
	sub	edx,size IDT_STR ; Back off one entry
	mov	IDTOFF,edx	; Save for next time
@@:

; Display the smaller of the Remaining Rows and (Size-Offset)

	call	REMROW		; Return with ECX = # remaining rows
	dec	ecx		; Back off to allow room for command line

	mov	ebx,eax 	; Copy selector length
	sub	ebx,edx 	; Less offset
	shr	ebx,3-0 	; Convert from bytes to qwords

	cmp	ecx,ebx 	; Use the smaller of the two
	jbe	short @F	; Jump if REMROW is smaller

	mov	ecx,ebx 	; (Size-Offset) is smaller
@@:
	mov	esi,[ebp-@BPBACK].BACK_IDT.DTR_BASE ; GS:ESI ==> current IDT
	add	esi,edx 	; Add into base address
	shr	edx,3-0 	; Convert from qwords to bytes
	or	LCL_FLAG,@LCL_IDX ; Mark as displaying index
IDTR_NEXT:
	call	DISP_IDTLIN	; Display a line's worth

	loop	IDTR_NEXT	; Jump if more entries

	call	CLEAR_EOP	; Clear to the end-of-the-page

; Restore the interrupts which we've hooked

	call	REST_OLDINTS	; Restore 'em using SS|EBP and GS

	popfd			; Restore flags

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_IDT endp			; End DISP_IDT procedure
	NPPROC	SWAP_OLDINTS -- Swap Back Original Interrupts
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Swap back original interrupts

|

SWAPINT_STR struc

SWAP_I01 dq	?		; Save area for INT 01h
SWAP_I08 dq	?		; ...		    08h
SWAP_I09 dq	?		; ...		    09h
SWAP_I0A dq	?		; ...		    0Ah
SWAP_I0F dq	?		; ...		    0Fh
SWAP_I74 dq	?		; ...		    74h
SWAP_I76 dq	?		; ...		    76h
SWAP_I77 dq	?		; ...		    77h

SWAPINT_STR ends


SWAP_STR struc

	dd	?		; Caller's EBP
SWAP_RET dd	?		; ...	   EIP
SWAP_INTS db	(size SWAPINT_STR) dup (?) ; Save area for VMCREGS

SWAP_STR ends

	sub	esp,(size SWAPINT_STR)-(size SWAP_RET) ; Make room for it less return address

; Copy return address to bottom of stack

	push	(type SWAP_RET) ptr [esp+(size SWAPINT_STR)-(size SWAP_RET)]

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ecx,esi>	; Save registers

; Swap back the original INT 08h, 09h, 0Ah, 0Fh, 74h, 76h, and 77h handlers

	sub	esp,type DTR_STR ; Make room for IDTR
	SIDTD	[esp].EDF	; Save on the stack
	mov	esi,[esp].DTR_BASE ; GS:ESI ==> IDT
	add	esp,type DTR_STR ; Stripfrom the stack

	movzx	ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	SWAPIDT ecx,08		; EAX clobbered
	inc	ecx		; Skip to keyboard interrupt (IRQ1)
	SWAPIDT ecx,09		; EAX clobbered
	inc	ecx		; Skip to cascade interrupt (IRQ2)
	SWAPIDT ecx,0A		; EAX clobbered
	add	ecx,0Fh-0Ah	; Skip to spurious interrupt (IRQ7)
	SWAPIDT ecx,0F		; EAX clobbered

	movzx	ecx,SWATINI.MD_IBV1 ; Get slave IMR base vector (IRQ8)
	add	ecx,12-8	; Skip to mouse interrupt (IRQ12)
	SWAPIDT ecx,74		; EAX clobbered
	add	ecx,76h-74h	; Skip to hard disk interrupt (IRQ14)
	SWAPIDT ecx,76		; EAX clobbered
	inc	ecx		; Skip to sometimes network interrupt (IRQ15)
	SWAPIDT ecx,77		; EAX clobbered

; If ORG_GDINT01_OFF is valid, swap it in

	mov	ecx,ORG_GDINT01_OFF ; Get offset in DGROUP of orig INT 01h IDT entry

	cmp	ecx,-1		; Izit invalid?
	je	short @F	; Jump if so

	mov	eax,DGROUP:[ecx].EDQLO ; Get low-order dword
	xchg	eax,AGROUP:[esi+01h*(type IDT_STR)].EDQLO ; Swap with current entry
	mov	[ebp].SWAP_INTS.SWAP_I01.EDQLO,eax ; Save to restore later

	mov	eax,DGROUP:[ecx].EDQHI ; Get high-order dword
	xchg	eax,AGROUP:[esi+01h*(type IDT_STR)].EDQHI ; Swap with current entry
	mov	[ebp].SWAP_INTS.SWAP_I01.EDQHI,eax ; Save to restore later
@@:
	REGREST <esi,ecx,eax>	; Restore

	pop	ebp		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SWAP_OLDINTS endp		; End SWAP_OLDINTS procedure
	NPPROC	REST_OLDINTS -- Restore Hooked Interrupts
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Restore hooked interrupts

|

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ecx,esi>	; Save registers

; Restore our INT 08h, 09h, 0Ah, 0Fh, 74h, 76h, and 77h handlers

	sub	esp,type DTR_STR ; Make room for IDTR
	SIDTD	[esp].EDF	; Save on the stack
	mov	esi,[esp].DTR_BASE ; GS:ESI ==> IDT
	add	esp,type DTR_STR ; Stripfrom the stack

	movzx	ecx,SWATINI.MD_IBV1 ; Get slave IMR base vector (IRQ8)
	add	ecx,15-8	; Skip to sometimes network interrupt (IRQ15)
	RESTIDT ecx,77		; AX clobbered
	dec	ecx		; Skip to hard disk interrupt (IRQ14)
	RESTIDT ecx,76		; AX clobbered
	sub	ecx,14-12	; Skip to mouse interrupt (IRQ12)
	RESTIDT ecx,74		; AX clobbered

	movzx	ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	add	ecx,7-0 	; Skip to spurious interrupt (IRQ7)
	RESTIDT ecx,0F		; AX clobbered
	sub	ecx,7-2 	; Skip to cascade  interrupt (IRQ2)
	RESTIDT ecx,0A		; AX clobbered
	dec	ecx		; Skip to keyboard interrupt (IRQ1)
	RESTIDT ecx,09		; AX clobbered
	dec	ecx		; Skip to timer    interrupt (IRQ0)
	RESTIDT ecx,08		; AX clobbered

; If ORG_GDINT01_OFF is valid, restore it

	mov	ecx,ORG_GDINT01_OFF ; Get offset in DGROUP of orig INT 01h IDT entry

	cmp	ecx,-1		; Izit invalid?
	je	short @F	; Jump if so

	mov	eax,[ebp].SWAP_INTS.SWAP_I01.EDQLO ; Get original value
	mov	AGROUP:[esi+01h*(type IDT_STR)].EDQLO,eax ; Restore

	mov	eax,[ebp].SWAP_INTS.SWAP_I01.EDQHI ; Get original value
	mov	AGROUP:[esi+01h*(type IDT_STR)].EDQHI,eax ; Restore
@@:
	REGREST <esi,ecx,eax>	; Restore

	pop	ebp		; Restore

	ret	size SWAP_INTS	; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_OLDINTS endp		; End REST_OLDINTS procedure
	NPPROC	DISP_IDTLIN -- Display IDT Line
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display a single IDT line.

On entry:

DX	=	index value
GS:ESI	==>	IDT

On exit:

DX	=	updated
GS:ESI	==>	updated

|

	REGSAVE <eax,ebx,edi>	; Save registers

; Display the selector

	lea	edi,MSG_IDTE1[0] ; Put result here
	mov	DGROUP:[edi].EDD,'????' ; Assume error
	mov	MSG_IDTE3[0].EDQLO,'????'
	mov	MSG_IDTE3[0].EDQHI,'????'

	clc			; Assume no error
	mov	al,gs:[esi].IDT_SELECT.LO ; Get low-order byte of selector
	mov	ah,gs:[esi].IDT_SELECT.HI ; Get high-...
	jc	short DISP_IDTLIN_ERR1 ; Jump on error

	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display the 32-bit linear address

;;;;;;; push	gs:[esi].IDT_SELECT ; Pass selector as argument
	push	ax		; Pass selector as argument
	call	GETBASE 	; Return with EAX = selector base
;;;;;;; jc	???		; Ignore error return

; If this is a task gate, the offset is ignored

	mov	bl,gs:[esi].IDT_ACCESS ; Get the access rights byte
	and	bl,mask $DT_TYP ; Isolate the type bits

	cmp	bl,CPL0_TASK and (not (mask $DT_P)) ; Izit a task?
	je	short @F	; Jump if so

	mov	ebx,gs:[esi].IDT_UNUSED.EDD ; Get offset 16-31 into high-order
	mov	bx,gs:[esi].IDT_OFFLO ; Get offset 0-15
	add	eax,ebx 	; Add to base
@@:
	lea	edi,MSG_IDTE3[0] ; Put result here
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI
DISP_IDTLIN_ERR1:

; Display the interrupt #

	mov	ax,dx		; Copy index register
	lea	edi,MSG_IDTE0[0] ; Put result here
	call	BIN2BYTE	; Convert AL to hex at ES:EDI

; Display the offset bits 0-15

	lea	edi,MSG_IDTE2[4] ; Put result here
	mov	DGROUP:[edi].EDD,'????' ; Assume error

	clc			; Assume no error
	mov	al,gs:[esi].IDT_OFFLO.LO ; Get low-order byte of offset 0-15
	mov	ah,gs:[esi].IDT_OFFLO.HI ; Get high-...
	jc	short DISP_IDTLIN_ERR2 ; Jump on error

	call	BIN2WORD	; Convert AX to hex at ES:EDI
DISP_IDTLIN_ERR2:
	lea	edi,MSG_IDTE4[0] ; Put result here
	mov	DGROUP:[edi].ELO,'??' ; Assume error

	clc			; Assume no error
	mov	al,gs:[esi].IDT_ACCESS ; Get access rights byte
	jc	short DISP_IDTLIN_ERR3 ; Jump on error

	call	BIN2BYTE	; Convert AL to hex at ES:EDI
DISP_IDTLIN_ERR3:
	lea	edi,MSG_IDTE2[0] ; Put result here
	mov	DGROUP:[edi].EDD,'????' ; Assume error

	clc			; Assume no error
	mov	al,gs:[esi].IDT_OFFHI.LO ; Get low-order byte of offset 16-31
	mov	ah,gs:[esi].IDT_OFFHI.HI ; Get high-...
	jc	short DISP_IDTLIN_ERR4 ; Jump on error

	call	BIN2WORD	; Convert AX to hex at ES:EDI
DISP_IDTLIN_ERR4:
	push	esi		; Save for a moment

	lea	esi,MSG_IDTE1	; ESI = message to display

	test	LCL_FLAG,@LCL_IDX ; Display the index?
	jz	short @F	; Not this time

	lea	esi,MSG_IDTE	; ESI = message to display
@@:
	call	PDISPTRUNC	; Display truncated ASCIIZ string from ESI
	pop	esi		; Restore
	jc	short @F	; Jump if no more columns

	clc			; Assume no error
	movzx	bx,gs:[esi].IDT_ACCESS ; Get access rights byte
	jc	short @F	; Jump on error

	call	DISP_TYPE	; Display the entry and type bits of the DTE
@@:
	inc	dx		; Skip to next interrupt #
	add	esi,size IDT_STR ; Skip to next entry

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

	REGREST <edi,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_IDTLIN endp		; End DISP_IDTLIN procedure
	NPPROC	DISP_GDT -- Display The GDT Entries
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the entries in the GDT.

On entry:

SS:EBP	==>	FORW_STR
GS	=	DTE_D4GB

|

	pushad			; Save all EGP registers

	mov	SCROFF,0	; Start at top of screen

	mov	bl,TTLATTR	; Get title attribute
	xchg	bl,DEFATTR	; Swap with default attribute

	lea	esi,MSG_DTE	; Line 1 of GDT/LDT header
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	lea	esi,MSG_GDTR	; Display "GDT=" text
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	mov	ax,[ebp-@BPBACK].BACK_GDT.DTR_LIM ; Get GDTR limit
	call	DISPHEX2	; Display the word

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

	mov	eax,[ebp-@BPBACK].BACK_GDT.DTR_BASE ; Get GDTR base
	call	DISPHEX4	; Display the dword
	call	CLEAR_EOL	; Clear to the end-of-the-line

	xchg	bl,DEFATTR	; Restore default attribute
	call	NEXTLINE	; End the line

	movzx	eax,[ebp-@BPBACK].BACK_GDT.DTR_LIM ; Get selector limit
	inc	eax		; Convert from limit to length
	and	eax,not ((size DESC_STR)-1) ; Round down to DTE boundary
				; in case someone uses a length instead
				; of a limit
	mov	edx,GDTOFF	; Get the current GDT offset

	cmp	eax,edx 	; Check relative value
	ja	short @F	; Jump if Size > Offset

	mov	edx,eax 	; Copy as new offset
	sub	edx,size DESC_STR ; Back off one entry
	mov	GDTOFF,edx	; Save for next time
@@:

; Display the smaller of the Remaining Rows and (Size-Offset) shr (3-0)

	call	REMROW		; Return with ECX = # remaining rows
	dec	ecx		; Back off to allow room for command line

	mov	ebx,eax 	; Copy selector length
	sub	ebx,edx 	; Less offset
	shr	ebx,3-0 	; Convert from bytes to qwords

	cmp	ecx,ebx 	; Use the smaller of the two
	jbe	short @F	; Jump if REMROW is smaller

	mov	ecx,ebx 	; (Size-Offset) is smaller
@@:
	mov	esi,[ebp-@BPBACK].BACK_GDT.DTR_BASE ; GS:ESI ==> current GDT
	add	esi,edx 	; Add into base address

	or	LCL_FLAG,@LCL_IDX ; Mark as displaying index
	or	dx,0		; Indicate it's from the GDT
	call	DISP_DTE	; Display ECX descriptor table entries at GS:ESI

	call	CLEAR_EOP	; Clear to the end-of-the-page

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_GDT endp			; End DISP_GDT procedure
	NPPROC	DISP_LDT -- Display LDT Entries
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the LDT entries at PLESC_TAB.

On entry:

SS:EBP	==>	FORW_STR
GS	=	DTE_D4GB

|

	pushad			; Save all EGP registers

	mov	SCROFF,0	; Start at top of screen

	mov	bl,TTLATTR	; Get title attribute
	xchg	bl,DEFATTR	; Swap with default attribute

	lea	esi,MSG_DTE	; Line 1 of GDT/LDT header
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

; Because DISP_SREG is sensitive to the $VM flag, we trick it here
; into thinking it's in protected mode

;;;;;;; push	[ebp].FORW_EFL.EHI ; Save high-order word
	mov	ax,[ebp].FORW_EFL.EHI ; Get high-order word
	push	ax		; Save it
	and	[ebp].FORW_EFL.EHI,not (mask $VM) ; Clear VM bit

	PUSHD	0		; Pass Unreal Mode data
	push	offset ds:MSG_LDTR ; Offset of message to display
	push	[ebp-@BPBACK].BACK_LDT.DTR_LIM ; Pass as old value
	push	[ebp-@BPBACK].BACK_LDT.DTR_LIM ; Pass selector
	call	DISP_SREG	; Display a selector/segment register

	pop	ax		; Get high-order word
	mov	[ebp].FORW_EFL.EHI,ax ; Restore it
;;;;;;; pop	[ebp].FORW_EFL.EHI ; Restore
	call	CLEAR_EOL	; Clear to the end-of-the-line

	xchg	bl,DEFATTR	; Restore default attribute
	call	NEXTLINE	; End the line

	movzx	eax,[ebp-@BPBACK].BACK_LDT.DTR_LIM ; Get selector value
S16	lsl	<eax,eax>	; Get LDT selector limit into EAX
	jnz	short DISP_LDT_EXIT ; Jump if invalid

	cmp	eax,size DESC_STR ; Check for essentially empty
	jb	short DISP_LDT_EXIT ; Jump if there's nothing to display

	inc	eax		; Convert from limit to length
	and	eax,not ((size DESC_STR)-1) ; Round down to DTE boundary
				; in case someone uses a length instead
				; of a limit
	mov	edx,LDTOFF	; Get the current LDT offset

	cmp	eax,edx 	; Check relative value
	ja	short @F	; Jump if Size > Offset

	mov	edx,eax 	; Copy as new offset
	sub	edx,size DESC_STR ; Back off one entry
	mov	LDTOFF,edx	; Save for next time
@@:

; Display the smaller of the Remaining Rows and (Size-Offset)

	call	REMROW		; Return with ECX = # remaining rows
	dec	ecx		; Back off to allow room for command line

	mov	ebx,eax 	; Copy selector length
	sub	ebx,edx 	; Less offset
	shr	ebx,3-0 	; Convert from bytes to qwords

	cmp	ecx,ebx 	; Use the smaller of the two
	jbe	short @F	; Jump if REMROW is smaller

	mov	ecx,ebx 	; (Size-Offset) is smaller
@@:
	mov	esi,[ebp-@BPBACK].BACK_LDT.DTR_BASE ; GS:ESI ==> current LDT
	add	esi,edx 	; Add into base address

	or	LCL_FLAG,@LCL_IDX ; Mark as displaying index
	or	dx,mask $TI	; Indicate it's from the LDT
	call	DISP_DTE	; Display ECX descriptor table entries at GS:ESI
DISP_LDT_EXIT:
	call	CLEAR_EOP	; Clear to the end-of-the-page

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_LDT endp			; End DISP_LDT procedure
	NPPROC	DISP_DTE -- Display DTEs
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display ECX descriptor table entries starting at DS:ESI

On entry:

ECX	=	# DTEs to display
DX	=	initial index with Table Index bit set if LDT
GS:ESI	==>	DTEs to display

|

	REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save registers
GDT_NEXT:
	mov	ax,dx		; Copy index register
	lea	edi,MSG_GDTE0[0] ; Put result here
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	lea	edi,MSG_GDTE1[4] ; Put result here
	mov	DGROUP:[edi].EDD,'????' ; Assume error

	clc			; Assume no error
	lods	gs:[esi].LO	; Get low-order byte of limit 0-15
;;;;;;; jc	short DISP_DTE_ERR1 ; Jump on error
	mov	ah,al		; Save for a moment
;;;;;;; clc			; Assume no error
	lods	gs:[esi].LO	; Get high-order byte of limit 0-15
	jc	short DISP_DTE_ERR1 ; Jump on error

	xchg	al,ah		; Swap to normal order
	shl	eax,16		; Shift to high-order

	clc			; Assume no error
	lods	gs:[esi].LO	; Get low-order byte of base 0-15
;;;;;;; jc	short DISP_DTE_ERR1 ; Jump on error
	mov	ah,al		; Save for a moment
;;;;;;; clc			; Assume no error
	lods	gs:[esi].LO	; Get high-order byte of base 0-15
	jc	short DISP_DTE_ERR1 ; Jump on error

	xchg	al,ah		; Swap to normal order
	call	BIN2WORD	; Convert AX to hex at ES:EDI
DISP_DTE_ERR1:
	lea	edi,MSG_GDTE1[2] ; Put result here
	mov	DGROUP:[edi].ELO,'??' ; Assume error

	clc			; Assume no error
	lods	gs:[esi].LO	; Get base 16-23
	jc	short DISP_DTE_ERR2 ; Jump on error

	call	BIN2BYTE	; Convert AL to hex at ES:EDI
DISP_DTE_ERR2:
	lea	edi,MSG_GDTE3[1] ; Put result here
	mov	DGROUP:[edi].ELO,'??' ; Assume error
	or	DTE_TYPFL,@DTE_TYP0 ; Assume error

	clc			; Assume no error
	lods	gs:[esi].LO	; Get low type bits
	jc	short DISP_DTE_ERR3 ; Jump on error

	and	DTE_TYPFL,not @DTE_TYP0 ; Mark as no error
	mov	DTE_TYP.LO,al	; Save for later use
	call	BIN2BYTE	; Convert AL to hex at ES:EDI
DISP_DTE_ERR3:
	lea	edi,MSG_GDTE2[0] ; Put result here
	mov	DGROUP:[edi].EDQLO,'????' ; Assume error
	mov	DGROUP:[edi].EDQHI,'????' ; Assume error
	or	DTE_TYPFL,@DTE_TYP1 ; Assume error

	clc			; Assume no error
	lods	gs:[esi].LO	; Get limit 16-19 and flags
	jc	short DISP_DTE_ERR4 ; Jump on error

	and	DTE_TYPFL,not @DTE_TYP1 ; Mark as no error
	mov	DTE_TYP.HI,al	; Save for later use
	mov	bl,al		; Copy for later use
	and	al,mask $SEGLM1 ; Isolate limit bits
	xor	ah,ah		; Zero high-order word
	rol	eax,16		; Rotate into normal order

	test	bl,mask $DTE_G	; Check granularity
	jz	short @F	; Jump if byte-granular

	shl	eax,12		; Shift up
	or	ax,0FFFh	; Append low-order bits
@@:
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI
DISP_DTE_ERR4:
	lea	edi,MSG_GDTE3[0] ; Put result here
	mov	DGROUP:[edi].LO,'?' ; Assume error

	test	DTE_TYPFL,@DTE_TYP1 ; Check for invalid limit and flag bits
	jnz	short DISP_DTE_ERR5 ; Jump if error

	mov	al,bl		; Copy type bits
	shr	al,4		; Get high-order type bits
	call	BIN2DIGIT	; Convert digit AL to hex at ES:EDI
DISP_DTE_ERR5:
	lea	edi,MSG_GDTE1[0] ; Put result here
	mov	DGROUP:[edi].ELO,'??' ; Assume error

	clc			; Assume no error
	lods	gs:[esi].LO	; Get base 24-31
	jc	short DISP_DTE_ERR6 ; Jump on error

	call	BIN2BYTE	; Convert AL to hex at ES:EDI
DISP_DTE_ERR6:

; If this is a call gate, move over the parm count field to be
; more visible

	mov	bl,DTE_TYP.LO	; Get the A/R byte

; Check for data/code, not call gate

	test	bl,(mask $DT_DC) or (mask $DS_BUSY) or (mask $DS_TASK) ; Izit?
	jnz	short DISP_DTE_XCG ; Jump if so

	test	bl,mask $DS_GATE ; Izit a gate?
	jz	short DISP_DTE_XCG ; Jump if not

	mov	ax,'  '         ; Parm count separators
	xchg	ax,MSG_GDTE1.ELO[2] ; Get bytes 2-3 of base address, set to blank
	mov	MSG_GDTE1.ELO[0],ax ; Save back
DISP_DTE_XCG:
	push	esi		; Save for a moment

	lea	esi,MSG_GDTE1	; ESI = message to display

	test	LCL_FLAG,@LCL_IDX ; Display the index?
	jz	short @F	; Not this time

	lea	esi,MSG_GDTE	; ESI = message to display
@@:
	call	PDISPTRUNC	; Display truncated ASCIIZ string from ESI
	pop	esi		; Restore
	jc	short @F	; Jump if no more columns

	test	DTE_TYPFL,@DTE_TYP0 or @DTE_TYP1 ; Check for any error
	jnz	short @F	; Jump if error

	mov	bx,DTE_TYP	; Get the type bits
	call	DISP_TYPE	; Display the entry and type bits of the DTE
@@:
	add	dx,type DESC_STR ; Skip to next entry

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; End the line

;;;;;;; loop	GDT_NEXT	; Jump if more entries
	dec	ecx		; Count in one fewer
	jnz	near ptr GDT_NEXT ; Jump if more entries

	REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DTE endp			; End DISP_DTE procedure
	NPPROC	DISP_TYPE -- Display GDT/IDT Type
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

ESI	=	initial message to display
BL	=	type bits

|

	REGSAVE <eax,edx,esi,ds> ; Save registers

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	mov	al,bl		; Copy low-order type bits
	and	al,mask $DT_DPL ; Isolate DPL bits
	shr	al,$DT_DPL	; Shift DPL to low-order
	add	al,'0'          ; Convert to ASCII

	test	bl,mask $DT_DC	; Izit data/code or system descriptor?
	jnz	short DT_USER	; It's a data/code descriptor

	mov	MSG_SYST1,al	; Save in message
	lea	esi,MSG_SYST	; Tell 'em it's a system descriptor
	call	PDISPTRUNC	; Display truncated ASCIIZ string from ESI
	jc	near ptr DT_EXIT ; Jump if no more columns

	push	ebx		; Save for a moment
	and	ebx,mask $DT_TYP ; Isolate type bits
	mov	esi,SYS_TYPE[ebx*(type SYS_TYPE)] ; Get type message
	call	PDISPTRUNC	; Display truncated ASCIIZ string from ESI
	pop	ebx		; Restore
	jc	near ptr DT_EXIT ; Jump if no more columns

	jmp	short DT_PRES	; Join common code

DT_USER:
	test	bl,mask $DC_COD ; Izit code or data descriptor?
	jnz	short DT_CODE	; It's a code descriptor

	mov	MSG_DATA1,al	; Save in message
	lea	esi,MSG_DATA	; Tell 'em it's a data descriptor
	call	PDISPTRUNC	; Display truncated ASCIIZ string from ESI
	jc	short DT_EXIT	; Jump if no more columns

COMMENT|

Isolate type bits for data selector into the following scheme in BX:

Bit 0	=	$DD_ACC
Bit 1	=	$DD_WRIT
Bit 2	=	$DD_EXPD
Bit 3	=	$DTE_B

|

	push	ebx		; Save for a moment
	and	ebx,((mask $DTE_B) shl 8) or (mask $DD_EXPD) or (mask $DD_WRIT) or (mask $DD_ACC)
if $DTE_B ge 3
	shr	bh,$DTE_B-3	; Shift to bit 3
else
	shl	bh,3-$DTE_B	; Shift to bit 3
endif
	or	bl,bh		; Include in low-order bits
	mov	bh,0		; Zero high-order byte
	mov	esi,DATA_TYPE[ebx*(type DATA_TYPE)] ; Get type message
	call	PDISPTRUNC	; Display truncated ASCIIZ string from ESI
	pop	ebx		; Restore
	jc	short DT_EXIT	; Jump if no more columns

	jmp	short DT_PRES	; Join common code

DT_CODE:
	mov	MSG_CODE1,al	; Save in message
	lea	esi,MSG_CODE	; Tell 'em it's a code descriptor
	call	PDISPTRUNC	; Display truncated ASCIIZ string from ESI
	jc	short DT_EXIT	; Jump if no more columns

COMMENT|

Isolate type bits for code selector into the following scheme in BX:

Bit 0	=	$DD_ACC
Bit 1	=	$DD_READ
Bit 2	=	$DD_CONF
Bit 3	=	$DTE_B

|

	push	ebx		; Save for a moment
	and	ebx,((mask $DTE_B) shl 8) or (mask $DC_CONF) or (mask $DC_READ) or (mask $DC_ACC)
if $DTE_B ge 3
	shr	bh,$DTE_B-3	; Shift to bit 3
else
	shl	bh,3-$DTE_B	; Shift to bit 3
endif
	or	bl,bh		; Include in low-order bits
	mov	bh,0		; Zero high-order byte
	mov	esi,CODE_TYPE[ebx*(type CODE_TYPE)] ; Get type message
	call	PDISPTRUNC	; Display truncated ASCIIZ string from ESI
	pop	ebx		; Restore
	jc	short DT_EXIT	; Jump if no more columns
DT_PRES:
	test	bl,mask $DT_P	; Izit present?
	jz	short DT_EXIT	; Not this time

	lea	esi,MSG_PRES	; Display the message
	call	PDISPTRUNC	; Display truncated ASCIIZ string from ESI
;;;;;;; jc	short DT_EXIT	; Jump if no more columns
DT_EXIT:
	REGREST <ds,esi,edx,eax> ; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_TYPE endp			; End DISP_TYPE procedure
	NPPROC	DISP_TSS -- Display The TSS
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the TSS entries at TR.

On entry:

SS:EBP	==>	FORW_STR
GS	=	DTE_D4GB

|

	pushad			; Save all EGP registers
	REGSAVE <ds>		; Save segment register

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	mov	SCROFF,0	; Start at top of screen

	mov	bl,TTLATTR	; Get title attribute
	xchg	bl,DEFATTR	; Swap with default attribute

	lea	esi,MSG_TSS1	; Line 1 of TSS header
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	lea	esi,MSG_TSS2	; Line 2 of TSS header
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	xchg	bl,DEFATTR	; Restore default attribute
	call	NEXTLINE	; End the line

; Format TSS selector

	mov	dx,[ebp-@BPBACK].BACK_TR.DTR_LIM ; Get task register

	and	dx,dx		; Izit valid?
	jz	short DISP_TSS_EXIT ; Jump if not

	movzx	esi,dx		; Get the selector
	and	si,not (mask $PL) ; Clear PL bits in case set
	add	esi,[ebp-@BPBACK].BACK_GDT.DTR_BASE ; Plus GDT base

	mov	ecx,1		; Display a single descriptor
	or	LCL_FLAG,@LCL_IDX ; Mark as displaying index
	or	dx,0		; Indicate it's from the GDT
	call	DISP_DTE	; Display ECX descriptor table entries at GS:ESI

	movzx	bx,gs:[esi].DESC_ACCESS ; Get the access rights byte
	and	bl,mask $DS_386 ; Isolate 286/386 flag
	shr	bl,$DS_386	; Shift to low-order bit
				; BX = 0 if 286 TSS
				;    = 1 if 386

; Get TSS base address

	mov	eax,gs:[esi].DESC_BASE01.EDD ; Get bytes 0-2
	shl	eax,8		; Make room for byte 3
	mov	al,gs:[esi].DESC_BASE3 ; Get byte 3
	ror	eax,8		; Rotate back to normal order
	mov	esi,eax 	; Save in index register

	push	bx		; Pass 286/386 flag
	push	dx		; Pass selector to use
	call	DISP_TSSMEM	; Display GS:ESI in TSS format
DISP_TSS_EXIT:
	call	CLEAR_EOP	; Clear to the end-of-the-page

	REGREST <ds>		; Restore
	assume	ds:nothing	; Tell the assembler about it
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_TSS endp			; End DISP_TSS procedure
	NPPROC	DISP_TSSMEM -- Display Memory in TSS Format
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display memory in TSS format

On entry:

GS:ESI	==>	memory to display

|

TSSMEM_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
TSSMEM_SEL dw	?		; Selector to use
TSSMEM_FLG dw	?		; Flags:  0 = 286 TSS, 1 = 386 TSS

TSSMEM_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,edx,edi,es> ; Save registers

	SETDATA es		; Set data selector into ES
	assume	es:DGROUP	; Tell the assembler about it

	cmp	[ebp].TSSMEM_FLG,@TSS386 ; Izit a 386 TSS?
	je	near ptr DISP_TSSMEM386 ; Jump if so

	lea	edi,MSG_TSS_LINK ; Put result here
	push	TSS2_LINK	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_ESP0[0] ; Put result here
	push	TSS2_SP0	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word/dword

	lea	edi,MSG_TSS_SS0 ; Put result here
	push	TSS2_SS0	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_ESP1[0] ; Put result here
	push	TSS2_SP1	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word/dword

	lea	edi,MSG_TSS_SS1 ; Put result here
	push	TSS2_SS1	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_ESP2[0] ; Put result here
	push	TSS2_SP2	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word/dword

	lea	edi,MSG_TSS_SS2 ; Put result here
	push	TSS2_SS2	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_EIP[0] ; Put result here
	push	TSS2_IP 	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_EFL[0] ; Put result here
	push	TSS2_FL 	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_EAX[0] ; Put result here
	push	TSS2_AX 	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_EBX[0] ; Put result here
	push	TSS2_BX 	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_ECX[0] ; Put result here
	push	TSS2_CX 	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_EDX[0] ; Put result here
	push	TSS2_DX 	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_ESP[0] ; Put result here
	push	TSS2_SP 	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_EBP[0] ; Put result here
	push	TSS2_BP 	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_ESI[0] ; Put result here
	push	TSS2_SI 	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_EDI[0] ; Put result here
	push	TSS2_DI 	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_CS	; Put result here
	push	TSS2_CS 	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_DS	; Put result here
	push	TSS2_DS 	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_ES	; Put result here
	push	TSS2_ES 	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_SS	; Put result here
	push	TSS2_SS 	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_LDT ; Put result here
	push	TSS2_LDT	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

; Clear unused halves of 32-bit fields to '    '

	mov	eax,'    '      ; A convenient clear value
	mov	MSG_TSS_ESP0.EDQHI,eax ; Clear low-order word in the low-order position
	mov	MSG_TSS_ESP1.EDQHI,eax ; ...
	mov	MSG_TSS_ESP2.EDQHI,eax ; ...
	mov	MSG_TSS_EIP.EDQHI,eax ; ...
	mov	MSG_TSS_EFL.EDQHI,eax ; ...

	mov	MSG_TSS_EAX.EDQHI,eax ; ...
	mov	MSG_TSS_EBX.EDQHI,eax ; ...
	mov	MSG_TSS_ECX.EDQHI,eax ; ...
	mov	MSG_TSS_EDX.EDQHI,eax ; ...
	mov	MSG_TSS_ESP.EDQHI,eax ; ...
	mov	MSG_TSS_EBP.EDQHI,eax ; ...
	mov	MSG_TSS_ESI.EDQHI,eax ; ...
	mov	MSG_TSS_EDI.EDQHI,eax ; ...

; Clear unused fields to '____'

	mov	eax,'____'      ; A convenient clear value
	mov	MSG_TSS_CR3.EDQLO,eax ; Clear the dword
	mov	MSG_TSS_CR3.EDQHI,eax ; ...

	mov	MSG_TSS_DBG.EDD,eax ; Clear the word
	mov	MSG_TSS_IO.EDD,eax ; ...

	mov	MSG_TSS_FS.EDD,eax ; Clear the word
	mov	MSG_TSS_GS.EDD,eax ; ...

	jmp	DISP_TSSMEM_COM ; Join common code

DISP_TSSMEM386:
	lea	edi,MSG_TSS_LINK ; Put result here
	push	TSS_LINK	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_ESP0 ; Put result here
	push	TSS_ESP0	; Pass offset as argument
	call	DDSPL		; Get, format, and save a word/dword

	lea	edi,MSG_TSS_SS0 ; Put result here
	push	TSS_SS0 	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_ESP1 ; Put result here
	push	TSS_ESP1	; Pass offset as argument
	call	DDSPL		; Get, format, and save a word/dword

	lea	edi,MSG_TSS_SS1 ; Put result here
	push	TSS_SS1 	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_ESP2 ; Put result here
	push	TSS_ESP2	; Pass offset as argument
	call	DDSPL		; Get, format, and save a word/dword

	lea	edi,MSG_TSS_SS2 ; Put result here
	push	TSS_SS2 	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_CR3 ; Put result here
	push	TSS_CR3 	; Pass offset as argument
	call	DDSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_EIP ; Put result here
	push	TSS_EIP 	; Pass offset as argument
	call	DDSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_EFL ; Put result here
	push	TSS_EFL 	; Pass offset as argument
	call	DDSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_EAX ; Put result here
	push	TSS_EAX 	; Pass offset as argument
	call	DDSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_EBX ; Put result here
	push	TSS_EBX 	; Pass offset as argument
	call	DDSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_ECX ; Put result here
	push	TSS_ECX 	; Pass offset as argument
	call	DDSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_EDX ; Put result here
	push	TSS_EDX 	; Pass offset as argument
	call	DDSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_ESP ; Put result here
	push	TSS_ESP 	; Pass offset as argument
	call	DDSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_EBP ; Put result here
	push	TSS_EBP 	; Pass offset as argument
	call	DDSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_ESI ; Put result here
	push	TSS_ESI 	; Pass offset as argument
	call	DDSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_EDI ; Put result here
	push	TSS_EDI 	; Pass offset as argument
	call	DDSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_CS	; Put result here
	push	TSS_CS		; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_DS	; Put result here
	push	TSS_DS		; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_ES	; Put result here
	push	TSS_ES		; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_FS	; Put result here
	push	TSS_FS		; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_GS	; Put result here
	push	TSS_GS		; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_SS	; Put result here
	push	TSS_SS		; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_LDT ; Put result here
	push	TSS_LDT 	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_DBG ; Put result here
	push	TSS_DBG 	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word

	lea	edi,MSG_TSS_IO	; Put result here
	push	TSS_IOMAP	; Pass offset as argument
	call	DWSPL		; Get, format, and save a word
DISP_TSSMEM_COM:

; Display the lines

	push	esi		; Save for a moment

	lea	esi,MSG_TSSL1	; Line 1 of TSS body
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; End the line


	lea	esi,MSG_TSSL2	; Line 2 of TSS body
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; End the line


	lea	esi,MSG_TSSL3	; Line 3 of TSS body
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; End the line


	lea	esi,MSG_TSSL4	; Line 4 of TSS body
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; End the line


	lea	esi,MSG_TSSL5	; Line 5 of TSS body
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; End the line

	pop	esi		; Restore

; Avoid display of I/O bit permission map if 286 TSS

	cmp	[ebp].TSSMEM_FLG,@TSS386 ; Izit a 386 TSS?
	jne	short DISP_TSSMEM1 ; Jump if not

	movzx	edx,[ebp].TSSMEM_SEL ; Get the TSS selector

; Display the Software Interrupt Re-direction Bitmap
; if it's a P5 or later and CR4.VME=1

	test	CPUFET_FLAG,mask $CPUFET_VME ; Is VME supported?
	jz	short @F	; Jump if not

	MOVSPR	eax,cr4 	; Get CPU extensions register

	test	eax,mask $VME	; Izit enabled?
	jz	short @F	; Jump if not

	call	DISP_SIRB	; Display the Software Interrupt Re-direction
				; Bitmap for TSS in EDX
@@:
	call	DISP_IOMAP	; Display the I/O bit permission map
				; for TSS in EDX
DISP_TSSMEM1:
	REGREST <es,edi,edx,eax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_TSSMEM endp		; End DISP_TSSMEM procedure
	NPPROC	DWSPL -- Get, Format, And Save Word
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get, format, and save a word.

On entry:

SS:ESP+2 =	 offset
GS:ESI+offset ==> word to get
ES:EDI	==>	output save area

|

DWSPL_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
DWSPL_OFF dd	?		; ...	   offset

DWSPL_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,esi>	; Save registers

	mov	eax,[ebp].DWSPL_OFF ; Get the offset
	add	esi,eax 	; Add into base

	mov	DGROUP:[edi].EDD,'????' ; Assume error

	clc			; Assume no error
	mov	al,gs:[esi].LO	; Get low-order byte of data
	mov	ah,gs:[esi].HI	; Get high-...
	jc	short DWSPL_EXIT ; Jump on error

	call	BIN2WORD	; Convert AX to hex at ES:EDI
DWSPL_EXIT:
	REGREST <esi,eax>	; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DWSPL	endp			; End DWSPL procedure
	NPPROC	DDSPL -- Get, Format, And Save Dword
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get, format, and save a dword.

On entry:

SS:ESP+2 =	 offset
GS:ESI+offset ==> dword to get
ES:EDI	==>	output save area

|

DDSPL_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
DDSPL_OFF dd	?		; ...	   offset

DDSPL_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,esi>	; Save registers

	mov	eax,[ebp].DDSPL_OFF ; Get the offset
	add	esi,eax 	; Add into base

	mov	DGROUP:[edi].EDQLO,'????' ; Assume error
	mov	DGROUP:[edi].EDQHI,'????'

	clc			; Assume no error
	mov	al,gs:[esi].EHI.LO ; Get midhigh-order byte of ESP0
	mov	ah,gs:[esi].EHI.HI ; Get high-...
	jc	short DDSPL_EXIT ; Jump on error

	shl	eax,16		; Shift to high-order word

	clc			; Assume no error
	mov	al,gs:[esi].ELO.LO ; Get low-order byte of ESP0
	mov	ah,gs:[esi].ELO.HI ; Get midlow-...
	jc	short DDSPL_EXIT ; Jump on error

	call	BIN2DWORD	; Convert EAX to hex at ES:EDI
DDSPL_EXIT:
	REGREST <esi,eax>	; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DDSPL	endp			; End DDSPL procedure
	NPPROC	DISP_SIRB -- Display Software Redirection Map
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display Software Interrupt Redirection Bitmap

On entry:

GS:ESI	==>	TSS
EDX	=	TSS selector

|

	pushad			; Save all EGP registers
	push	es		; Save segment register

	movzx	eax,AGROUP:[esi].TSS_IOMAP ; Get I/O map offset

	and	eax,eax 	; Izit valid?
	jz	near ptr DISP_SIRB_EXIT ; Not this time

;;;;;;; cmp	dx,-1		; Izit valid
;;;;;;; je	near ptr DISP_SIRB_EXIT ; Not this time

	SETDATA es		; Set data selector into ES
	assume	es:DGROUP	; Tell the assembler about it

	push	esi		; Save for a moment

	lea	esi,MSG_SIRB_HDR ; Display the bit map header
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

;;;;;;; call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; End the line

	pop	esi		; Restore

	mov	ecx,-2		; In case DX is invalid
S16	lsl	<ecx,edx>	; Get TSS selector limit into ECX
;;;;;;; inc	ecx		; Convert from limit to length
;;;;;;; dec	ecx		; less I/O bit permission map terminator

	sub	eax,256/8	; Less offset to SIRB
	jbe	near ptr DISP_SIRB_EXIT ; Nothing remains

	sub	ecx,eax 	; Less I/O map offset
	jbe	near ptr DISP_SIRB_EXIT ; Nothing remains

	add	esi,eax 	; Bump to base
				; AGROUP:[esi] ==> SIRB

@SIRB_NSBI equ	2		; # spaces between INTs
@SIRB_NIPL equ	80/(2+@SIRB_NSBI) ; # INTS per line

	mov	dl,00h		; Initialize INT counter
DISP_SIRB_NEXTLINE:

; Clear out the map message area

	call	DISP_SIRBCLR	; Clear it out

	xor	ebx,ebx 	; Initialize # INTs displayed this line
	lea	edi,MSG_SIRB	; Put result here
DISP_SIRB_NEXTBYTE:
	clc			; Assume no error
	lods	AGROUP:[esi].LO ; Get next byte
	jc	short DISP_SIRB_LOOP ; Jump on error

	REGSAVE <edx>		; Save for a moment

	mov	ecx,8		; # bits to check
DISP_SIRB_NEXTBIT:
	ror	al,1		; Check next bit
	jnc	short DISP_SIRB2 ; Jump if not special

	inc	ebx		; Count in another INT displayed

	push	eax		; Save for a moment

	mov	al,dl		; Copy INT #
	call	BIN2BYTE	; Convert AL to hex at ES:EDI

	pop	eax		; Restore

	add	edi,@SIRB_NSBI	; Plus # bytes to skip over between displayed INTs
DISP_SIRB2:
	inc	dl		; Next interrupt #

	cmp	bx,@SIRB_NIPL	; Are we still within range?
	jb	short DISP_SIRB4 ; Jump if so

	push	esi		; Save for a moment

	lea	esi,MSG_SIRB	; Display the bit map
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

;;;;;;; call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; End the line

	pop	esi		; Restore

; Clear out the map message area

	call	DISP_SIRBCLR	; Clear it out

	xor	ebx,ebx 	; Initialize # INTs displayed this line
	lea	edi,MSG_SIRB	; Put result here
DISP_SIRB4:
	loop	DISP_SIRB_NEXTBIT ; Jump if more bits in the byte

	REGREST <edx>		; Restore
DISP_SIRB_LOOP:
	cmp	SCROFF,2*(@NROWS-2)*@NCOLS ; On the next-to-the-last line?
	ja	short DISP_SIRB_EXIT ; Yes, skip out

	add	dl,8		; Skip to next interrupt #
	loopnz	DISP_SIRB_NEXTBYTE ; Jump if more interrupts in this line
				; and no wrap at 256

	cmp	dl,00h		; Are we back at square 00h?
	jne	short DISP_SIRB_NEXTLINE ; Jump if more INTs to check

	and	ebx,ebx 	; Were any INTs displayed on the last line?
	jz	short @F	; Jump if not

	lea	esi,MSG_SIRB	; Display the bit map
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

;;;;;;; call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; End the line
@@:
DISP_SIRB_EXIT:
	pop	es		; Restore
	assume	es:nothing	; Tell the assembler about it
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_SIRB endp			; End DISP_SIRB procedure
	NPPROC	DISP_SIRBCLR -- Clear MSG_SIRB line
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Clear MSG_SIRB line.

|

	REGSAVE <eax,ecx,edi>	; Save registers

	mov	ecx,size MSG_SIRB ; # bytes in message area
	mov	al,' '          ; Fill with this one
	lea	edi,MSG_SIRB	; Put result here
    rep stos	MSG_SIRB[edi]	; Consider it blanked

	REGREST <edi,ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_SIRBCLR endp		; End DISP_SIRBCLR procedure
	NPPROC	DISP_IOMAP -- Display I/O Bit Permission Map
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

On entry:

GS:ESI	==>	TSS
EDX	=	TSS selector

|

	pushad			; Save all EGP registers
	push	es		; Save segment register

	movzx	eax,AGROUP:[esi].TSS_IOMAP ; Get I/O map offset

	and	eax,eax 	; Izit valid?
	jz	near ptr DISP_IOMAP_EXIT ; Not this time

;;;;;;; cmp	dx,-1		; Izit valid
;;;;;;; je	near ptr DISP_IOMAP_EXIT ; Not this time

	SETDATA es		; Set data selector into ES
	assume	es:DGROUP	; Tell the assembler about it

	push	esi		; Save for a moment

	lea	esi,MSG_IOMAP_HDR ; Display the bit map header
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

;;;;;;; call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; End the line

	pop	esi		; Restore

	mov	ecx,-2		; In case DX is invalid
S16	lsl	<ecx,edx>	; Get TSS selector limit into ECX
;;;;;;; inc	ecx		; Convert from limit to length
;;;;;;; dec	ecx		; less I/O bit permission map terminator

	sub	ecx,eax 	; Less I/O map offset
	jbe	near ptr DISP_IOMAP_EXIT ; Nothing remains

	add	esi,eax 	; Bump to base
				; AGROUP:[esi] ==> I/O bit permission map

; Skip over IOMAP_LINE leading lines of data
; One such line can display up to 8 bits of data

DISP_IOMAP_NEXTPUSH:
	push	ecx		; Save I/O bit permission map limit

	cmp	ecx,CON8KB	; Ensure not too large
	jbe	short @F	; Jump if it's within range

	mov	ecx,CON8KB	; Use maximum
@@:
	mov	edi,esi 	; Save base of I/O bit permission map
	xor	edx,edx 	; Initialize line counter
DISP_IOMAP_NEXTBYTE:
	clc			; Assume no error
	lods	AGROUP:[esi].LO ; Get next byte
	jc	short @F	; Jump on error

	and	al,al		; Anybody home?
	jz	short @F	; Jump if not

	cmp	edx,IOMAP_LINE	; Are we at the right line?
	je	short DISP_IOMAP_LOOPEND ; Jump if so

	inc	edx		; Count in another line
@@:
	loop	DISP_IOMAP_NEXTBYTE ; Jump if more

; Not enough lines found

	pop	ecx		; Restore I/O bit permission map limit

	mov	esi,edi 	; Restore base of I/O bit permission map

	and	edx,edx 	; Are there any lines remaining?
	jz	short DISP_IOMAP_LOOPEND1 ; Jump if not

; Reduce IOMAP_LINE modulo actual line count (in DX)

	add	IOMAP_LINE,edx	; Add in case IOMAP_LINE is negative
@@:
	cmp	edx,IOMAP_LINE	; Izit too large?
	ja	short DISP_IOMAP_NEXTPUSH ; Jump if not

	sub	IOMAP_LINE,edx	; Less one chunk

	jmp	short @B	; Go around again

DISP_IOMAP_LOOPEND:
	pop	eax		; Strip off ECX
	dec	esi		; Back off to previous byte
DISP_IOMAP_LOOPEND1:
	mov	edx,esi 	; Copy address
	sub	edx,edi 	; Less base of I/O bit permission map
	shl	edx,3-0 	; Convert from bytes to bit

	mov	ebx,edi 	; Save as base
	add	ebx,0400h/8	; Skip to next row
DISP_IOMAP_NEXT:
	clc			; Assume no error
	lods	AGROUP:[esi].LO ; Get next byte
	jc	short DISP_IOMAP_LOOP ; Jump on error

	and	al,al		; Anybody home?
	jz	short DISP_IOMAP_LOOP ; Not this time

; Are we in the first row?

	cmp	ebx,esi 	; Check against start of second row
	jae	short @F	; Jump if we're in the first row

; If the same bits in the preceding 0400h byte are set, ignore this byte

	mov	ah,AGROUP:[esi-0400h/8-1] ; Get the previous byte
	not	ah		; Complement the bits

	and	al,ah		; Isolate the difference
	jz	short DISP_IOMAP_LOOP ; Jump if all the same
@@:
	REGSAVE <ecx,edx>	; Save for a moment

	lea	edi,MSG_IOMAP	; Put result here

; Clear out the map message area

	REGSAVE <eax,edi>	; Save registers

	mov	ecx,size MSG_IOMAP ; # bytes in message area
	mov	al,' '          ; Fill with this one
    rep stos	MSG_IOMAP[edi]	; Consider it blanked

	REGREST <edi,eax>	; Restore

	mov	ecx,8		; # bits to check
DISP_IOMAP1:
	ror	al,1		; Check next bit
	jnc	short DISP_IOMAP2 ; Jump if not special

	push	eax		; Save for a moment

	mov	ax,dx		; Copy value to convert
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	call	IOMAP_APV	; Search for other entries

	mov	ax,'  '         ; Separators
S32	stos	MSG_IOMAP.ELO[edi] ; Save in ouput area

	pop	eax		; Restore

	jmp	short DISP_IOMAP3 ; Join common code

DISP_IOMAP2:
	add	edi,4+4+2	; # bytes to skip over
DISP_IOMAP3:
	inc	edx		; Next I/O port address

	loop	DISP_IOMAP1	; Jump if more bits in the byte

	push	esi		; Save for a moment

	lea	esi,MSG_IOMAP	; Display the bit map
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

;;;;;;; call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; End the line

	pop	esi		; Restore

	REGREST <edx,ecx>	; Restore
DISP_IOMAP_LOOP:
	cmp	SCROFF,2*(@NROWS-2)*@NCOLS ; On the next-to-the-last line?
	ja	short DISP_IOMAP_EXIT ; Yes, skip out

	add	edx,8		; Skip to next I/O port address
	jz	short @F	; Jump if we're at the wrap point

;;;;;;; loopnz	DISP_IOMAP_NEXT ; Jump if more entries and not at wrap
	dec	ecx		; Account for one fewer entry
	jnz	DISP_IOMAP_NEXT ; Jump if more entries
@@:
	mov	eax,IOMAP_LINE	; Get current top of screen
	mov	IOMAP_LINE_MAX,eax ; Indicate we can't scroll any further
DISP_IOMAP_EXIT:
	pop	es		; Restore
	assume	es:nothing	; Tell the assembler about it
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_IOMAP endp 		; End DISP_IOMAP procedure
	NPPROC	IOMAP_APV -- Search for Arithmetic Progression Vector
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Search for other I/O map entries at multiples of 0400h.

On entry:

EDX	=	I/O port address
EBX	=	start of second row
GS:ESI-1 ==>	 current byte
ES:EDI	==>	output area

On exit:

ES:EDI	==>	updated

|

	REGSAVE <eax,ecx,edx,esi> ; Save registers

	cmp	edx,0400h	; Bigger than our limit
	jae	short IOMAP_APV_FILL ; Yes

	dec	esi		; Back off to the last byte

	mov	cl,dl		; Copy port address low-order byte
	and	cl,111b 	; Isolate bit address
	mov	al,1		; Strobe bit
	shl	al,cl		; Shift into position
;;;;;;; mov	ah,al		; Copy for complement
;;;;;;; not	ah		; Used to clear entry in APV
	xor	edx,edx 	; Initialize counter
	mov	ecx,64*(1024/1024) ; # multiples of 1024 in 64KB
IOMAP_APV_NEXT:
	test	al,gs:[esi]	; Check next value
	jz	short IOMAP_APV_END ; No more entries

;;;;;;; and	gs:[esi],ah	; Clear the bit
	inc	edx		; Count in another one
	add	esi,0400h/8	; Skip to next entry

	loop	IOMAP_APV_NEXT	; Jump if more entries to test
IOMAP_APV_END:
	cmp	edx,1		; Only one entry?
	je	short IOMAP_APV_FILL ; Yes, no repetition factor

	mov	al,'('          ; Leading separator
S32	stos	es:[edi].LO	; Save in output area

	mov	al,dl		; Copy value to convert
	call	BIN2BYTE	; Convert AL to hex at ES:EDI

	mov	al,')'          ; Trailing separator
S32	stos	es:[edi].LO	; Save in output area

	jmp	short IOMAP_APV_EXIT ; Join common exit code

IOMAP_APV_FILL:
	add	edi,4		; # bytes to skip over
IOMAP_APV_EXIT:
	REGREST <esi,edx,ecx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IOMAP_APV endp			; End IOMAP_APV procedure
	NPPROC	GetPDE -- Get PDE Covering Linear Address
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Get PDE which covers a given linear address

On exit:

EAX	=	PDE

|

GetPDE_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
GetPDE_CR3 dd	?		; CR3 to use
GetPDE_LA dd	?		; Linear address

GetPDE_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	PUSHD	0		; Make room for original PTE
	PUSHD	1		; # PTEs to follow
	PUSHD	0		; Make room for original PDE
	push	[ebp].GetPDE_LA ; Pass the linear address
	push	[ebp].GetPDE_CR3 ; ...	   CR3 to use
	call	LIN2PPDIR	; Return with AGROUP:EAX ==> corresponding PDIR

	mov	eax,AGROUP:[eax] ; Get the corresponding PDIR

	call	LIN2PPTEZ	; Cleanup after LIN2PPDIR
	add	esp,1*4 	; Pop the PTE

	pop	ebp		; Restore

	ret	4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GetPDE	endp			; End GetPDE procedure
	NPPROC	CheckOrigPDE -- Check On Original PDE
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on original PDE

On entry:

EAX	=	PDE
EBP	=	original PDE

On exit:

|

	REGSAVE <edx>		; Save register

	mov	edx,eax 	; Copy to scratch
	and	edx,@PTE_FRM	; Isolate the 4KB frame

	cmp	edx,PaLCLPDIR	; Izit physical address of our local PDIR?
	jne	short @F	; Jump if not

	mov	eax,ebp 	; Use original PDE
@@:
	REGREST <edx>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CheckOrigPDE endp		; End CheckOrigPDE procedure
	NPPROC	DISP_PTE -- Display PTEs
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display the first few PTEs starting at PTE_START

|

	pushad			; Save all EGP registers
	REGSAVE <fs>		; Save segment register

	mov	SCROFF,0	; Start at top of screen

	mov	fs,COMMON.FILE_CR3 ; Get our CR3 selector
	assume	fs:PDTGRP	; Tell the assembler about it

	mov	ebp,OFFPDT[@PDELOC].EDD ; Get the PDE where we will store
				; our local PDIR
	mov	bl,TTLATTR	; Get title attribute
	xchg	bl,DEFATTR	; Swap with default attribute

; Format CR3 into the line

	call	READ_CR3	; Get the value
	mov	LCL_CR3,eax	; Save for later use
	lea	edi,MSG_PTE1	; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

; Format the PDE into the line

	mov	esi,PTE_START	; PDT:ESI ==> PTEs starting here

; If offset is negative, bring the offset to within the first row

	cmp	esi,0		; Izit negative?
	jge	short @F	; Jump if not

	inc	esi		; Plus to change to origin-1
	neg	esi		; Negate to get positive value
	and	esi,8*4-1	; Modulo a line's worth
	neg	esi		; Back to negative value
	add	esi,8*4-1	; Plus a line's worth, less origin
	mov	PTE_START,esi	; Save for later use
@@:

; If the offset is beyond 4GB, bring the offset to within the last row

	mov	eax,1 shl (32-(12-2)) ; Get selector length of 4GB/(4KB in dwords)

	cmp	esi,eax 	; Izit at the end?
	jb	short DISP_PTE1 ; Jump if not

	sub	esi,eax 	; Back off to first row
	and	esi,8*4-1	; Modulo a line's worth
	sub	esi,8*4 	; Less a line's worth
	add	esi,eax 	; Skip to the last row
	mov	PTE_START,esi	; Save for later use
DISP_PTE1:
	mov	eax,esi 	; Copy PTE_START
	shl	eax,(12-2)-0	; Convert from 4KB in dwords to bytes

; Get the PDE which covers this linear address

	push	eax		; Pass the linear address
	push	LCL_CR3 	; ...	   CR3 to use
	call	GetPDE		; Get the PDE which covers this linear address
				; Return with EAX = PDE
	call	CheckOrigPDE	; Check on original PDE (in EAX)
				; Return with EAX = PDE
; Save the PDE for later use

	mov	LCL_PDE,eax	; Save it

; Handle Page Size Extensions
; If this is a 4MB PDE, round down PTE_START to 4KB boundary

	call	IZIT_PSE	; Are Page Size Extensions supported and active?
	jnc	short @F	; Jump if not

	test	LCL_PDE,mask $PTE_PS ; Is the PDE a 4MB page?
	jz	short @F	; Jump if not

	and	esi,not (4*1024-1) ; Round down to 4KB boundary
	mov	PTE_START,esi	; Save for later use
@@:

; Format the PDE

;;;;;;; mov	eax,LCL_PDE	; Get the PDE
	lea	edi,MSG_PTE2	; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

; Calculate the # entries to display

	mov	eax,1 shl (32-(12-2)) ; Get selector length of 4GB/(4KB in dwords)
	mov	edx,eax 	; Copy for later use
	sub	edx,esi 	; Subtract to get # bytes to display
	shr	edx,2-0 	; Convert from bytes to dwords

	push	eax		; Save for a moment

; Format the starting linear address into the line

	mov	eax,esi 	; PDT:EAX ==> PTEs starting here
	shl	eax,(12-2)-0	; Convert from 4KB in dwords to bytes
	mov	ecx,8*4*1024-1	; Set linear address range of one row

; Handle Page Size Extensions

	call	IZIT_PSE	; Are Page Size Extensions supported and active?
	jnc	short @F	; Jump if not

	test	LCL_PDE,mask $PTE_PS ; Is the PDE a 4MB page?
	jz	short @F	; Jump if not

	mov	ecx,4*1024*1024-1 ; Set linear address range of one row
@@:
	lea	edi,MSG_PTE3	; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

; Format the ending linear address into the line

	add	eax,ecx 	; Plus linear address range of one row
	jnc	short @F	; Jump if it fits

	mov	eax,-1		; Use highest ending address
@@:
	lea	edi,MSG_PTE4	; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

; Display the line

	lea	esi,MSG_PTE	; Line 1 of PTE header
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	xchg	bl,DEFATTR	; Restore default attribute
	call	NEXTLINE	; Skip to next line, first column

	pop	eax		; Restore

; Display the smaller of the Remaining Rows and (Size-Offset)

	call	REMROW		; Return with ECX = # remaining rows
	dec	ecx		; Back off to allow room for command line
	shl	ecx,(3+2)-0	; Convert from rows (8-dwords) to bytes

	mov	esi,PTE_START	; PDT:ESI ==> PTEs starting here
	mov	ebx,eax 	; Copy selector length
	sub	ebx,esi 	; Less offset to get length in bytes

	cmp	ecx,ebx 	; Use the smaller of the two
	jbe	short @F	; Jump if REMROW is smaller

	mov	ecx,ebx 	; (Size-Offset) is smaller
@@:
	add	ecx,(8*4)-1	; Round up to row boundary
	shr	ecx,(3+2)-0	; Convert from bytes to rows (8-dwords)
	jz	near ptr DISP_PTE_DONE ; Jump if nothing to display

	shr	esi,22-(12-2)	; Convert from 4KB in dwords to 4MB

; Split cases depending upon whether paging is enabled

	mov	eax,cr0 	; Get control register

	test	eax,mask $PG	; Check for paging enabled
	jz	short DISP_PTE_XPAGE1 ; Jump if not

; Establish addressibility to our local PDIR

	mov	ebx,PLCLPDIR	; Get offset to our local PDIR

	push	ebp		; Save the PDE there (if any)

; So we can be re-entrant, save the existing PDEs

	push	DGROUP:[ebx].EDQLO ; Save 1st PDE in our local PDIR
	push	DGROUP:[ebx].EDQHI ; ...  2nd ...

	mov	eax,PaLCLPDIR	; Get physical address of our local PDIR
	or	ax,@PTE_URP	; Mark as User/Read-write/Present
	mov	OFFPDT[@PDELOC],eax ; Save as new PDE

; Note that not present PDEs are handled in DISPROWPTE

	mov	eax,OFFPDT[esi*4].EDQLO ; Get 1st PDE
	call	CheckOrigPDE	; Check on original PDE (in EAX)
				; Return with EAX = PDE
	mov	DGROUP:[ebx].EDQLO,eax ; Save to establish addressibility

	mov	eax,OFFPDT[esi*4].EDQHI ; Get 2nd PDE
	call	CheckOrigPDE	; Check on original PDE (in EAX)
				; Return with EAX = PDE
	mov	DGROUP:[ebx].EDQHI,eax ; Save to establish addressibility

	call	FLUSH_CACHE	; Flush the TLB

	mov	ebx,@PDELIN	; Get starting linear address

	jmp	short DISP_PTE_COM1 ; Join common code

DISP_PTE_XPAGE1:
	mov	eax,LCL_CR3	; Get the value
	and	eax,@PTE_FRM	; Isolate the 4KB frame

	mov	ebx,AGROUP:[eax+esi*4] ; Get the next PDE
	mov	ebp,-1		; Mark as no original PDE
	and	ebx,@PTE_FRM	; Isolate the 4KB frame

; The two PDEs to display are now addressible at linear address AGROUP:EBX

DISP_PTE_COM1:
	mov	INIT_PDELIN,ebx ; Save for later use

; Calculate the effective linear address for PTE_START

	mov	esi,PTE_START	; PDT:ESI ==> PTEs starting here
	mov	eax,esi 	; Copy offset in PDT
	and	eax,not ((4*1024)-1) ; Isolate 4KB frame
	sub	ebx,eax 	; Subtract to take into account the fact
				; that ESI might cross into another PDE
	mov	edi,esi 	; Initialize as initial PTE value
	shl	edi,(12-2)-0	; Convert from 4KB in dwords to bytes
	mov	PTE_SEQ,edi	; Initialize sequential PTE value
DISP_PTE_NEXT:

; We can fit six digits on the line, so display it as
; @NIB5-4 as a byte
; @NIB3-0 as a word

	mov	eax,esi 	; Get PDT offset
	shr	eax,4*4 	; Shift down NIB4
	call	DISPHEX1	; Display the byte

	mov	eax,esi 	; Get PDT offset
;;;;;;; shr	eax,0*4 	; Shift down NIB0
	call	DISPHEX2	; Display the word

	mov	al,':'          ; Separator
	call	DISPTXT 	; Display byte on screen as text

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

; If this row is from a 4MB PDE, display a single
; entry which is the 4MB PDE

	call	IZIT_PSE	; Are Page Size Extensions supported and active?
	jnc	near ptr DISP_PTE_XPSE1 ; Jump if not

	mov	eax,esi 	; Get PDT offset
	shl	eax,12-2	; Convert from PTE offset (4KB in dwords)
				; to address (bytes)
	push	eax		; Pass as linear address
	push	LCL_CR3 	; ...	   CR3 to use
	call	GetPDE		; Get the PDE which covers this lienar address
				; Return with EAX = PDE
	call	CheckOrigPDE	; Check on original PDE (in EAX)
				; Return with EAX = PDE
	test	eax,mask $PTE_PS ; Izit a 4MB page?
	jz	short DISP_PTE_XPSE1 ; Jump if not

	call	DISPHEX4	; Display the dword

	add	esi,CON4KB	; Skip to next PDE
	add	edi,CON4MB	; ...
	mov	PTE_SEQ,eax	; Save as last PDE
	and	PTE_SEQ,@PSE_FRM ; Isolate the PSE frame
	sub	edx,1024	; Less a row's worth

; Because a 4MB page PDE will point us beyond the two PDEs
; we put into place above, we need to refresh the entries

	REGSAVE <ebx,edx,esi>	; Save for a moment

	mov	ebx,PLCLPDIR	; Get offset to our local PDIR
	shr	esi,22-(12-2)	; Convert from 4KB in dwords to 4MB

; If either PDE location is where we store our local PDIR,
; use the original PDE

	mov	eax,OFFPDT[esi*4].EDQLO ; Get 1st PDE
	call	CheckOrigPDE	; Check on original PDE (in EAX)
				; Return with EAX = PDE
	mov	DGROUP:[ebx].EDQLO,eax ; Save to establish addressibility

	mov	eax,OFFPDT[esi*4].EDQHI ; Get 2nd PDE
	call	CheckOrigPDE	; Check on original PDE (in EAX)
				; Return with EAX = PDE
	mov	DGROUP:[ebx].EDQHI,eax ; Save to establish addressibility

	call	FLUSH_CACHE	; Flush the TLB

	REGREST <esi,edx,ebx>	; Restore

	mov	ebx,INIT_PDELIN ; Get initial @PDELIN
	mov	eax,esi 	; Copy offset in PDT
	and	eax,not ((4*1024)-1) ; Isolate 4KB frame
	sub	ebx,eax 	; Subtract to take into account the fact
				; that ESI might cross into another PDE
	jmp	short DISP_PTE_XPSE2 ; Join common code

DISP_PTE_XPSE1:
	add	esi,ebx 	; Make absolute for GS selector
	call	DISPROWPTE	; Display PTEs from GS:ESI, max EDX, init EDI
				; updating ESI, EDX, EDI, and PTE_SEQ
	sub	esi,ebx 	; Make relative
DISP_PTE_XPSE2:
	call	CLEAR_EOL	; Clear to the end-of-the-line

; Skip to next line, first column

	call	NEXTLINE	; End the line

	and	edx,edx 	; Any more to display?
	jz	short @F	; Jump if not

;;;;;;; loop	DISP_PTE_NEXT	; Jump if more rows of PTEs to display
	dec	ecx		; Account for one less
	jnz	DISP_PTE_NEXT	; Jump if more rows of PTEs to display
@@:

; Restore local PDIR entries if paging enabled

	mov	eax,cr0 	; Get control register

	test	eax,mask $PG	; Check for paging enabled
	jz	short DISP_PTE_XPAGE2 ; Jump if not

	mov	ebx,PLCLPDIR	; Get offset to our local PDIR
	pop	DGROUP:[ebx].EDQHI ; Restore 2nd PDE in our local PDIR
	pop	DGROUP:[ebx].EDQLO ; ...     1st ...
	pop	OFFPDT[@PDELOC].EDD ; Restore the PDE there (if any)
	call	FLUSH_CACHE	; Flush the TLB
DISP_PTE_XPAGE2:
DISP_PTE_DONE:
	mov	PTE_NEXT,esi	; Save as next PTE for PgDn

	call	CLEAR_EOP	; Clear to the end-of-the-page

	REGREST <fs>		; Restore
	assume	fs:nothing	; Tell the assembler about it
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_PTE endp			; End DISP_PTE procedure
	NPPROC	DISP_PDE -- Display PDEs
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display the first few PDEs starting at PDE_START

|

	pushad			; Save all EGP registers

	mov	SCROFF,0	; Start at top of screen

	mov	bl,TTLATTR	; Get title attribute
	xchg	bl,DEFATTR	; Swap with default attribute

; Format CR3 into the line

	call	READ_CR3	; Get the value
	lea	edi,MSG_PDE1	; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	mov	esi,PDE_START	; PDE:ESI ==> PDEs starting here

; If offset is negative, bring the offset to within the first row

	cmp	esi,0		; Izit negative?
	jge	short @F	; Jump if not

	inc	esi		; Plus to change to origin-1
	neg	esi		; Negate to get positive value
	and	esi,8*4-1	; Modulo a line's worth
	neg	esi		; Back to negative value
	add	esi,8*4-1	; Plus a line's worth, less origin
	mov	PDE_START,esi	; Save for later use
@@:

; If the offset is beyond 4GB, bring the offset to within the last row

	mov	eax,4*1024	; Get length of region to display

	cmp	esi,eax 	; Izit at the end?
	jb	short DISP_PDE1 ; Jump if not

	sub	esi,eax 	; Back off to first row
	and	esi,8*4-1	; Modulo a line's worth
	sub	esi,8*4 	; Less a line's worth
	add	esi,eax 	; Skip to the last row
	mov	PDE_START,esi	; Save for later use
DISP_PDE1:

; Calculate the # entries to display

;;;;;;; mov	eax,4*1024	; Get length of region to display
	mov	edx,eax 	; Copy for later use
	sub	edx,esi 	; Subtract to get # bytes to display
	shr	edx,2-0 	; Convert from bytes to dwords

	push	eax		; Save for a moment

; Format the starting linear address into the line

	mov	eax,esi 	; PDE:EAX ==> PDEs starting here
	shl	eax,(22-2)-0	; Convert from 4MB in dwords to bytes
	lea	edi,MSG_PDE2	; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

; Format the ending linear address into the line

	add	eax,8*4*1024*1024-1 ; Plus linear address range of one row
	jnc	short @F	; Jump if it fits

	mov	eax,-1		; Use highest ending address
@@:
	lea	edi,MSG_PDE3	; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

; Display the line

	lea	esi,MSG_PDE	; Line 1 of PDE header
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	xchg	bl,DEFATTR	; Restore default attribute
	call	NEXTLINE	; Skip to next line, first column

	pop	eax		; Restore

; Display the smaller of the Remaining Rows and (Size-Offset)

	call	REMROW		; Return with ECX = # remaining rows
	dec	ecx		; Back off to allow room for command line
	shl	ecx,(3+2)-0	; Convert from rows (8-dwords) to bytes

	mov	esi,PDE_START	; PDE:ESI ==> PDEs starting here
	mov	ebx,eax 	; Copy selector length
	sub	ebx,esi 	; Less offset

	cmp	ecx,ebx 	; Use the smaller of the two
	jbe	short @F	; Jump if REMROW is smaller

	mov	ecx,ebx 	; (Size-Offset) is smaller
@@:
	add	ecx,(8*4)-1	; Round up to row boundary
	shr	ecx,(3+2)-0	; Convert from bytes to rows (8-dwords)
	jz	short DISP_PDE_EXIT ; Jump if nothing to display

	push	COMMON.FILE_CR3 ; Address our CR3 selector
	call	GETLBASE	; Return with EAX = selector base

	mov	ebx,eax 	; Save to use later
	mov	edi,esi 	; Initialize as initial PDE value
	shl	edi,(12-2)-0	; Convert from 4KB in dwords to bytes
	mov	PDE_SEQ,edi	; Initialize sequential PDE value
DISP_PDE_NEXT:
	mov	ax,si		; Get PDE offset
	call	DISPHEX2	; Display the word

	mov	al,':'          ; Separator
	call	DISPTXT 	; Display byte on screen as text

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

	add	esi,ebx 	; Make absolute for GS selector
	call	DISPROWPDE	; Display PDEs from GS:ESI, max EDX, init EDI
				; updating ESI, EDX, EDI, and PDE_SEQ
	sub	esi,ebx 	; Make relative

	call	CLEAR_EOL	; Clear to the end-of-the-line

; Skip to next line, first column

	call	NEXTLINE	; End the line

	loop	DISP_PDE_NEXT	; Jump if more rows of PDEs to display
DISP_PDE_EXIT:
	call	CLEAR_EOP	; Clear to the end-of-the-page

	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_PDE endp			; End DISP_PDE procedure
	NPPROC	CMD_DTE -- DTE Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

DTE sel

where sel is a selector.

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax,ecx,edx,esi> ; Save registers

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	or	al,al		; Izit the end of the line?
	jz	short CMD_DTE_SYNTERR ; Jump if so

	call	PARSE_EXPR	; Parse command line for an expression
	jc	short CMD_DTE_OVFERR ; Jump if error in conversion

	cmp	eax,0000FFFFh	; Izit a valid line number?
	ja	short CMD_DTE_OVFERR ; Jump if not

	mov	dx,ax		; Copy the selector

	push	ax		; Pass the selector
	call	GETLADTE	; Return with EAX = linear address of DTE
	jc	short CMD_DTE_SELERR ; Jump if not valid selector

	mov	BufIndex,0	; Initialize buffer index

	push	PDISPTRUNC	; Save old value

	mov	PDISPTRUNC,offset PGROUP:DISP2BUF ; Use local routine

	mov	ecx,1		; Display one DTE in DX
	mov	esi,eax 	; ...at GS:ESI
	call	DISP_DTE	; Display ECX descriptor table entries at GS:ESI

	pop	PDISPTRUNC	; Restore

; Copy Buffer to the command line

	lea	esi,Buffer	; DS:ESI ==> buffer to copy to command line
	call	COPYTO_CMDLINE	; Copy ASCIIZ string at DS:ESI to end of command line

; Display the command line, and wait for a keystroke

	call	DISP_CMDLINE	; Display the command line
	call	PURGE_KBUFF	; First purge the keyboard buffer
	call	GETNDKEY	; Get non-destructive key

	clc			; Indicate all went well

	jmp	short CMD_DTE_EXIT ; Join common code

CMD_DTE_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	jmp	short CMD_DTE_ERR ; Join common error exit code

CMD_DTE_OVFERR:
	mov	MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

	jmp	short CMD_DTE_ERR ; Join common error exit code

CMD_DTE_SELERR:
	mov	MSGOFF,offset DGROUP:SELERR ; Save offset of error message

;;;;;;; jmp	short CMD_DTE_ERR ; Join common error exit code

CMD_DTE_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_DTE_EXIT:
	REGREST <esi,edx,ecx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_DTE endp			; End CMD_DTE procedure
	NPPROC	DISP2BUF -- Display Values To Buffer
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Copy the ASCIIZ string from DS:ESI to the buffer at Buffer[BufIndex]

On entry:

DS:ESI	==>	ASCIIZ string

On exit:

CF	=	1 if truncated
	=	0 if not

|

	REGSAVE <eax,esi,edi>	; Save registers

	lea	edi,Buffer	; ES:EDI ==> buffer start
	add	edi,BufIndex	; Plus current index
@@:
	lods	ds:[esi].LO	; Get next character

	and	al,al		; End of the message?
	jz	short @F	; Yes

	stos	Buffer[edi]	; Save char in buffer

	jmp	@B		; Go around again

@@:
	sub	edi,offset es:Buffer ; Less start of buffer
	mov	BufIndex,edi	; Save for later use

	REGREST <edi,esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP2BUF endp			; End DISP2BUF procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_DTE module
