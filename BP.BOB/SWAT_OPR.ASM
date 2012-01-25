;' $Header:   P:/PVCS/386SWAT/SWAT_OPR.ASV   1.17   25 Jun 1997 13:19:58   BOB  $
	title	SWAT_OPR -- 386MAX Debugger Operand Data Routines
	page	58,122
	name	SWAT_OPR

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
	include BITFLAGS.INC
	include CPUFLAGS.INC
	include IOPBITS.INC
	include ALLMEM.INC
	include OPCODES.INC

	include INT1_FNS.INC
	include SWAT_CMD.INC
	include SWAT_COM.INC
	include SWAT_MOD.INC
	include SWAT_SEG.INC
.list

DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume  ds:DGROUP

	extrn	DEFATTR:byte
	extrn	CURATTR:byte
	extrn	REGATTR:byte

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume  ds:DGROUP

	extrn	SCROFF:dword
	extrn	JCCOFF:dword
	extrn	OPROFF:dword
	extrn	OPERAND:tbyte
	extrn	CUR_INSTR:dword
	extrn	CUR_INSTR_ARW:word
	extrn	FIRST_INSTR:dword
	extrn	LAST_INSTR:dword
	extrn	SELFDBG:dword

	public  EA1BASE,EA1OFF,EA1MODE,EA1SEL,EA1LIM,EA1WID
	public  EA1TSEL
EA1BASE dd	?		; Linear address of EA1SEL
EA1OFF	dd	?		; EA1 offset
EA1MODE dw	@MODE_NEW	; EA1 mode (NEW = invalid, i.e. no EA)
EA1SEL	dw	?		; EA1 segment/selector
EA1LIM	dd	?		; EA1 ...	       limit
EA1WID	dd	?		; EA1 ...	       width (1=byte, 2=word, etc.)
EA1TSEL dw	?		; EA1 target segment/selector

	public  EA2BASE,EA2OFF,EA2MODE,EA2SEL,EA2LIM,EA2WID
EA2BASE dd	?		; Linear address of EA2SEL
EA2OFF	dd	?		; EA2 offset
EA2MODE dw	@MODE_NEW	; EA2 mode (NEW = invalid, i.e. no EA)
EA2SEL	dw	?		; EA2 segment/selector
EA2LIM	dd	?		; EA2 ...	       limit
EA2WID	dd	?		; EA2 ...	       width (1=byte, 2=word, etc.)

	public  OPRINT0E_CR2
OPRINT0E_CR2 dd ?		; Save area for old CR2

	public  OPRINT0E_FVEC,OPRINT0E_ARB
OPRINT0E_FVEC df ?		; Save area for old INT 0Eh handler
OPRINT0E_ARB  db ?		; ...			    access rights byte

	public  OPR_I0ECNT
	align	2
OPR_I0ECNT dw	0		; Local INT 0Eh install count

	public  OPR_FLAG
OPR_FLAG dw	0		; Operand analysis flags
@OPR_ESP equ	8000h		; ESP used as base register
@OPR_EA equ	4000h		; Effective address computation only

; Note that $R1 present in the mask is treated as a special case.
; If $R1 is present in the mask but not in the flags, the result
; will always be false.  This is only the case for LOOPZ and LOOPNZ
; when ZF is correct but CX=1.

	public  JCCMASK
JCCMASK dw	  mask $OF			; 00-01 for JO and JNO
	dw	  mask $CF			; 02-03     JC	   JNC
	dw	  mask $ZF			; 04-05     JZ	   JNZ
	dw	(mask $CF) or (mask $ZF)	; 06-07     JBE    JA
	dw	  mask $SF			; 08-09     JS	   JNS
	dw	  mask $PF			; 0A-0B     JPE    JPO
	dw	  mask $R3			; 0C-0D     JL	   JGE
	dw	(mask $ZF) or (mask $R3)	; 0E-0F     JLE    JG
	dw	  mask $R2			; 10-11     JCXZ   --
	dw	  mask $R1			; 12-13     LOOP   --
	dw	(mask $R1) or (mask $ZF)	; 14-15     LOOPZ  LOOPNZ

	public  SEGTXT
SEGTXT	dd	offset DGROUP:SEGES ; 000
	dd	offset DGROUP:SEGCS ; 001
	dd	offset DGROUP:SEGSS ; 010
	dd	offset DGROUP:SEGDS ; 011
	dd	offset DGROUP:SEGFS ; 100
	dd	offset DGROUP:SEGGS ; 101

SEGES	db	' ES',0
SEGCS	db	' CS',0
SEGSS	db	' SS',0
SEGDS	db	' DS',0
SEGFS	db	' FS',0
SEGGS	db	' GS',0

	public  MSG_BROK_BACK,MSG_BROK_FORW,MSG_BRNO
MSG_BROK_BACK db '; Jump ', 0
MSG_BROK_FORW db '; Jump ', 0
MSG_BRNO      db '; No jump',0

	public  MSG_INTVM,MSG_INTPM
MSG_INTVM db	'IDT[4*',0
MSG_INTPM db	'IDT[8*',0

	public  MRM16BIT
	align	4
MRM16BIT dd	offset DGROUP:MRM16_00000
	dd	offset DGROUP:MRM16_00001
	dd	offset DGROUP:MRM16_00010
	dd	offset DGROUP:MRM16_00011
	dd	offset DGROUP:MRM16_00100
	dd	offset DGROUP:MRM16_00101
	dd	offset DGROUP:MRM16_00110
	dd	offset DGROUP:MRM16_00111
	dd	offset DGROUP:MRM16_01000
	dd	offset DGROUP:MRM16_01001
	dd	offset DGROUP:MRM16_01010
	dd	offset DGROUP:MRM16_01011
	dd	offset DGROUP:MRM16_01100
	dd	offset DGROUP:MRM16_01101
	dd	offset DGROUP:MRM16_01110
	dd	offset DGROUP:MRM16_01111
	dd	offset DGROUP:MRM16_10000
	dd	offset DGROUP:MRM16_10001
	dd	offset DGROUP:MRM16_10010
	dd	offset DGROUP:MRM16_10011
	dd	offset DGROUP:MRM16_10100
	dd	offset DGROUP:MRM16_10101
	dd	offset DGROUP:MRM16_10110
	dd	offset DGROUP:MRM16_10111
	dd	offset DGROUP:MRM16_11000

DD_MAC	macro	NAM,LBL

NAM	label	dword

	irp	XX,<LBL>
	dd	offset PGROUP:XX
	endm			; IRP

	endm			; DD_MAC

DD_MAC MRM16_00000,<ADD_EBX,ADD_ESI,ADD_END>  ; MOD=00
DD_MAC MRM16_00001,<ADD_EBX,ADD_EDI,ADD_END>
DD_MAC MRM16_00010,<ADD_EBP,ADD_ESI,ADD_END>
DD_MAC MRM16_00011,<ADD_EBP,ADD_EDI,ADD_END>
DD_MAC MRM16_00100,<ADD_ESI,	    ADD_END>
DD_MAC MRM16_00101,<ADD_EDI,	    ADD_END>
DD_MAC MRM16_00110,<		    ADD_END>
DD_MAC MRM16_00111,<ADD_EBX,	    ADD_END>

DD_MAC MRM16_01000,<ADD_EBX,ADD_ESI,ADD_END>  ; MOD=01
DD_MAC MRM16_01001,<ADD_EBX,ADD_EDI,ADD_END>
DD_MAC MRM16_01010,<ADD_EBP,ADD_ESI,ADD_END>
DD_MAC MRM16_01011,<ADD_EBP,ADD_EDI,ADD_END>
DD_MAC MRM16_01100,<ADD_ESI,	    ADD_END>
DD_MAC MRM16_01101,<ADD_EDI,	    ADD_END>
DD_MAC MRM16_01110,<ADD_EBP,	    ADD_END>
DD_MAC MRM16_01111,<ADD_EBX,	    ADD_END>

DD_MAC MRM16_10000,<ADD_EBX,ADD_ESI,ADD_END>  ; MOD=10
DD_MAC MRM16_10001,<ADD_EBX,ADD_EDI,ADD_END>
DD_MAC MRM16_10010,<ADD_EBP,ADD_ESI,ADD_END>
DD_MAC MRM16_10011,<ADD_EBP,ADD_EDI,ADD_END>
DD_MAC MRM16_10100,<ADD_ESI,	    ADD_END>
DD_MAC MRM16_10101,<ADD_EDI,	    ADD_END>
DD_MAC MRM16_10110,<ADD_EBP,	    ADD_END>
DD_MAC MRM16_10111,<ADD_EBX,	    ADD_END>

DD_MAC MRM16_11000,<ADD_ESP,	    ADD_END>  ; MOD=11

	public  MRM32BIT
	align	4
MRM32BIT dd	offset DGROUP:MRM32_00000
	dd	offset DGROUP:MRM32_00001
	dd	offset DGROUP:MRM32_00010
	dd	offset DGROUP:MRM32_00011
	dd	offset DGROUP:MRM32_00100
	dd	offset DGROUP:MRM32_00101
	dd	offset DGROUP:MRM32_00110
	dd	offset DGROUP:MRM32_00111
	dd	offset DGROUP:MRM32_01000
	dd	offset DGROUP:MRM32_01001
	dd	offset DGROUP:MRM32_01010
	dd	offset DGROUP:MRM32_01011
	dd	offset DGROUP:MRM32_01100
	dd	offset DGROUP:MRM32_01101
	dd	offset DGROUP:MRM32_01110
	dd	offset DGROUP:MRM32_01111
	dd	offset DGROUP:MRM32_10000
	dd	offset DGROUP:MRM32_10001
	dd	offset DGROUP:MRM32_10010
	dd	offset DGROUP:MRM32_10011
	dd	offset DGROUP:MRM32_10100
	dd	offset DGROUP:MRM32_10101
	dd	offset DGROUP:MRM32_10110
	dd	offset DGROUP:MRM32_10111
	dd	offset DGROUP:MRM32_11000

DD_MAC MRM32_00000,<ADD_EAX,	    ADD_END>  ; MOD=00
DD_MAC MRM32_00001,<ADD_ECX,	    ADD_END>
DD_MAC MRM32_00010,<ADD_EDX,	    ADD_END>
DD_MAC MRM32_00011,<ADD_EBX,	    ADD_END>
DD_MAC MRM32_00100,<ADD_SIB		   >
DD_MAC MRM32_00101,<		    ADD_END>
DD_MAC MRM32_00110,<ADD_ESI,	    ADD_END>
DD_MAC MRM32_00111,<ADD_EDI,	    ADD_END>

DD_MAC MRM32_01000,<ADD_EAX,	    ADD_END>  ; MOD=01
DD_MAC MRM32_01001,<ADD_ECX,	    ADD_END>
DD_MAC MRM32_01010,<ADD_EDX,	    ADD_END>
DD_MAC MRM32_01011,<ADD_EBX,	    ADD_END>
DD_MAC MRM32_01100,<ADD_SIB		   >
DD_MAC MRM32_01101,<ADD_EBP,	    ADD_END>
DD_MAC MRM32_01110,<ADD_ESI,	    ADD_END>
DD_MAC MRM32_01111,<ADD_EDI,	    ADD_END>

DD_MAC MRM32_10000,<ADD_EAX,	    ADD_END>  ; MOD=10
DD_MAC MRM32_10001,<ADD_ECX,	    ADD_END>
DD_MAC MRM32_10010,<ADD_EDX,	    ADD_END>
DD_MAC MRM32_10011,<ADD_EBX,	    ADD_END>
DD_MAC MRM32_10100,<ADD_SIB		   >
DD_MAC MRM32_10101,<ADD_EBP,	    ADD_END>
DD_MAC MRM32_10110,<ADD_ESI,	    ADD_END>
DD_MAC MRM32_10111,<ADD_EDI,	    ADD_END>

DD_MAC MRM32_11000,<ADD_ESP,	    ADD_END>  ; MOD=11

	public  SIB_BASE
	align	4
SIB_BASE dd	offset DGROUP:SIBB000
	dd	offset DGROUP:SIBB001
	dd	offset DGROUP:SIBB010
	dd	offset DGROUP:SIBB011
	dd	offset DGROUP:SIBB100
	dd	offset DGROUP:SIBB101
	dd	offset DGROUP:SIBB110
	dd	offset DGROUP:SIBB111

DD_MAC SIBB000,<ADD_EAX,SIB_XBASE>
DD_MAC SIBB001,<ADD_ECX,SIB_XBASE>
DD_MAC SIBB010,<ADD_EDX,SIB_XBASE>
DD_MAC SIBB011,<ADD_EBX,SIB_XBASE>
DD_MAC SIBB100,<ADD_ESP,SIB_XBASE>
DD_MAC SIBB101,<ADD_EBP,SIB_XBASE>
DD_MAC SIBB110,<ADD_ESI,SIB_XBASE>
DD_MAC SIBB111,<ADD_EDI,SIB_XBASE>

	public  SIB_SIND
	align	4
SIB_SIND dd	offset DGROUP:SIBS00000
	dd	offset DGROUP:SIBS00001
	dd	offset DGROUP:SIBS00010
	dd	offset DGROUP:SIBS00011
	dd	offset DGROUP:SIBS00100
	dd	offset DGROUP:SIBS00101
	dd	offset DGROUP:SIBS00110
	dd	offset DGROUP:SIBS00111
	dd	offset DGROUP:SIBS01000
	dd	offset DGROUP:SIBS01001
	dd	offset DGROUP:SIBS01010
	dd	offset DGROUP:SIBS01011
	dd	offset DGROUP:SIBS01100
	dd	offset DGROUP:SIBS01101
	dd	offset DGROUP:SIBS01110
	dd	offset DGROUP:SIBS01111
	dd	offset DGROUP:SIBS10000
	dd	offset DGROUP:SIBS10001
	dd	offset DGROUP:SIBS10010
	dd	offset DGROUP:SIBS10011
	dd	offset DGROUP:SIBS10100
	dd	offset DGROUP:SIBS10101
	dd	offset DGROUP:SIBS10110
	dd	offset DGROUP:SIBS10111
	dd	offset DGROUP:SIBS11000
	dd	offset DGROUP:SIBS11001
	dd	offset DGROUP:SIBS11010
	dd	offset DGROUP:SIBS11011
	dd	offset DGROUP:SIBS11100
	dd	offset DGROUP:SIBS11101
	dd	offset DGROUP:SIBS11110
	dd	offset DGROUP:SIBS11111

DD_MAC SIBS00000,<ADD_EAX, ADD_END>	      ; SS=00
DD_MAC SIBS00001,<ADD_ECX, ADD_END>
DD_MAC SIBS00010,<ADD_EDX, ADD_END>
DD_MAC SIBS00011,<ADD_EBX, ADD_END>
DD_MAC SIBS00100,<	   ADD_END>
DD_MAC SIBS00101,<ADD_EBP, ADD_END>
DD_MAC SIBS00110,<ADD_ESI, ADD_END>
DD_MAC SIBS00111,<ADD_EDI, ADD_END>

DD_MAC SIBS01000,<ADD_EAX2,ADD_END>	      ; SS=01
DD_MAC SIBS01001,<ADD_ECX2,ADD_END>
DD_MAC SIBS01010,<ADD_EDX2,ADD_END>
DD_MAC SIBS01011,<ADD_EBX2,ADD_END>
DD_MAC SIBS01100,<	   ADD_END>
DD_MAC SIBS01101,<ADD_EBP2,ADD_END>
DD_MAC SIBS01110,<ADD_ESI2,ADD_END>
DD_MAC SIBS01111,<ADD_EDI2,ADD_END>

DD_MAC SIBS10000,<ADD_EAX4,ADD_END>	      ; SS=10
DD_MAC SIBS10001,<ADD_ECX4,ADD_END>
DD_MAC SIBS10010,<ADD_EDX4,ADD_END>
DD_MAC SIBS10011,<ADD_EBX4,ADD_END>
DD_MAC SIBS10100,<	   ADD_END>
DD_MAC SIBS10101,<ADD_EBP4,ADD_END>
DD_MAC SIBS10110,<ADD_ESI4,ADD_END>
DD_MAC SIBS10111,<ADD_EDI4,ADD_END>

DD_MAC SIBS11000,<ADD_EAX8,ADD_END>	      ; SS=11
DD_MAC SIBS11001,<ADD_ECX8,ADD_END>
DD_MAC SIBS11010,<ADD_EDX8,ADD_END>
DD_MAC SIBS11011,<ADD_EBX8,ADD_END>
DD_MAC SIBS11100,<	   ADD_END>
DD_MAC SIBS11101,<ADD_EBP8,ADD_END>
DD_MAC SIBS11110,<ADD_ESI8,ADD_END>
DD_MAC SIBS11111,<ADD_EDI8,ADD_END>

	public	SEGOFF
SEGOFF	dd	BACK_ES
	dd	BACK_CS
	dd	BACK_SS
	dd	BACK_DS
	dd	BACK_FS
	dd	BACK_GS

	public	DWIDTAB
DWIDTAB dd	@DWIDTH_BYTE	; Byte
	dd	@DWIDTH_WORD	; Word
	dd	@DWIDTH_DWORD	; Dword
	dd	@DWIDTH_QWORD	; Qword
	dd	@DWIDTH_TBYTE	; Tbyte
	dd	@DWIDTH_PTR16	; PTR16:16
	dd	@DWIDTH_PTR32	; PTR16:32
	dd	@DWIDTH_PTR16F	; PTR16:16 FL
	dd	@DWIDTH_PTR32F	; PTR16:32 EFL
	dd	@DWIDTH_DTR	; DTR
	dd	@DWIDTH_BNDW	; BOUND word
	dd	@DWIDTH_BNDD	; BOUND Dword
	dd	@DWIDTH_WORD2	; Two words
	dd	@DWIDTH_WORD3	; Three words
	dd	@DWIDTH_WORD4	; Four words
	dd	@DWIDTH_DWORD2	; Two dwords
	dd	@DWIDTH_DWORD3	; Three dwords
	dd	@DWIDTH_POPA	; Eight words
	dd	@DWIDTH_POPAD	; Eight dwords
	dd	@DWIDTH_BTREG	; One byte with displacement
	dd	@DWIDTH_BTIMM	; One byte with displacement
	dd	@DWIDTH_INT	; Two words
	dd	@DWIDTH_POPW	; Word
	dd	@DWIDTH_POPD	; Dword
	dd	@DWIDTH_XLAT	; Byte
DWIDTAB_LEN equ ($-DWIDTAB)/(type DWIDTAB)

	public  DWIDACT
DWIDACT dd	offset PGROUP:DWID_BYTE
	dd	offset PGROUP:DWID_WORD
	dd	offset PGROUP:DWID_DWORD
	dd	offset PGROUP:DWID_QWORD
	dd	offset PGROUP:DWID_TBYTE
	dd	offset PGROUP:DWID_PTR16
	dd	offset PGROUP:DWID_PTR32
	dd	offset PGROUP:DWID_PTR16F
	dd	offset PGROUP:DWID_PTR32F
	dd	offset PGROUP:DWID_DTR
	dd	offset PGROUP:DWID_BNDW
	dd	offset PGROUP:DWID_BNDD
	dd	offset PGROUP:DWID_WORD2
	dd	offset PGROUP:DWID_WORD3
	dd	offset PGROUP:DWID_WORD4
	dd	offset PGROUP:DWID_DWORD2
	dd	offset PGROUP:DWID_DWORD3
	dd	offset PGROUP:DWID_POPA
	dd	offset PGROUP:DWID_POPAD
	dd	offset PGROUP:DWID_BT
	dd	offset PGROUP:DWID_BT
	dd	offset PGROUP:DWID_INT
	dd	offset PGROUP:DWID_POPW
	dd	offset PGROUP:DWID_POPD
	dd	offset PGROUP:DWID_XLAT


$P	equ	00h		; Prefix

$M	equ	01h		; MOD R/M byte present
$A	equ	02h		; Immediate word:word (OSP=0) or word:dword (OSP=1)
$O	equ	04h		; Immediate word (ASP=0) or dword (ASP=1)
$B	equ	08h		; Immediate byte
$W	equ	10h		; Immediate word
$V	equ	20h		; Immediate word (OSP=0) or dword (OSP=1)
$OSP	equ	40h		; Operand size prefix
$ASP	equ	80h		; Address ...

$BW	equ	$B or $W	; Immediate word and immediate byte
$MB	equ	$M or $B	; MOD R/M byte with immediate byte
$MV	equ	$M or $V	; MOD R/M byte with immediate word (OSP=0) or dword (OSP=1)

	public  OPCOD1
;		 x0  x1  x2  x3  x4  x5  x6  x7  x8  x9  xA  xB  xC  xD  xE  xF
OPCOD1	db	$M ,$M ,$M ,$M ,$MB,$MV, 0 , 0 ,$M ,$M ,$M ,$M ,$MB,$MV, 0 ,$P  ; 0x
	db	$M ,$M ,$M ,$M ,$MB,$MV, 0 , 0 ,$M ,$M ,$M ,$M ,$MB,$MV, 0 , 0  ; 1x
	db	$M ,$M ,$M ,$M ,$MB,$MV,$P , 0 ,$M ,$M ,$M ,$M ,$MB,$MV,$P , 0  ; 2x
	db	$M ,$M ,$M ,$M ,$MB,$MV,$P , 0 ,$M ,$M ,$M ,$M ,$MB,$MV,$P , 0  ; 3x
	db	  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0  ; 4x
	db	  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0  ; 5x
	db	  0 , 0 ,$M ,$M ,$P ,$P ,$P ,$P ,$V ,$MV,$B ,$MB, 0 , 0 , 0 , 0  ; 6x
	db	$B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$B  ; 7x
	db	$MB,$MV,$MB,$MB,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M  ; 8x
	db	  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ,$A , 0 , 0 , 0 , 0 , 0  ; 9x
	db	$O ,$O ,$O ,$O , 0 , 0 , 0 , 0 ,$B ,$V , 0 , 0 , 0 , 0 , 0 , 0  ; Ax
	db	$B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$V ,$V ,$V ,$V ,$V ,$V ,$V ,$V  ; Bx
	db	$MB,$MB,$W , 0 ,$M ,$M ,$MB,$MV,$BW, 0 ,$W , 0 , 0 ,$B , 0 , 0  ; Cx
	db	$M ,$M ,$M ,$M ,$B ,$B , 0 , 0 ,$P ,$P ,$P ,$P ,$P ,$P ,$P ,$P  ; Dx
	db	$B ,$B ,$B ,$B ,$B ,$B ,$B ,$B ,$V ,$V ,$A ,$B , 0 , 0 , 0 , 0  ; Ex
	db	$P , ? ,$P ,$P , 0 , 0 ,$M ,$M , 0 , 0 , 0 , 0 , 0 , 0 ,$M ,$M  ; Fx

	public  OPCOD2
;		 x0  x1  x2  x3  x4  x5  x6  x7  x8  x9  xA  xB  xC  xD  xE  xF
OPCOD2	db	$M ,$M ,$M ,$M , ? , 0 , 0 , 0 , 0 , 0 , ? , ? , ? , ? , ? , ?  ; 0x
	db	$M ,$M ,$M ,$M , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ?  ; 1x
	db	  0 , 0 , 0 , 0 , 0 , ? , 0 , ? , ? , ? , ? , ? , ? , ? , ? , ?  ; 2x
	db	  0 , 0 , 0 , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ?  ; 3x
	db	  ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ?  ; 4x
	db	  ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ?  ; 5x
	db	  ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ?  ; 6x
	db	  ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ?  ; 7x
	db	$V ,$V ,$V ,$V ,$V ,$V ,$V ,$V ,$V ,$V ,$V ,$V ,$V ,$V ,$V ,$V  ; 8x
	db	$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M  ; 9x
	db	  0 , 0 , 0 ,$M ,$MB,$M ,$M ,$M , 0 , 0 , 0 ,$M ,$MB,$M , ? ,$M  ; Ax
	db	$M ,$M ,$M ,$M ,$M ,$M ,$M ,$M , ? , ? ,$MB,$M ,$M ,$M ,$M ,$M  ; Bx
	db	$M ,$M , ? , ? , ? , ? , ? ,$M , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0  ; Cx
	db	  ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ?  ; Dx
	db	  ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ?  ; Ex
	db	  ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ?  ; Fx

	public  MSG_INVBACK,MSG_INVCR3
MSG_INVBACK db	'INVALID BACK LINK',0
MSG_INVCR3  db	'INVALID CR3 IN BACK LINK TSS',0

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume  cs:PGROUP

	extrn	DISPHEX1:near
	extrn	DISPHEX2:near
	extrn	DISPHEX4:near
	extrn	DISPTXT:near
	extrn	DISPASCIIZ:near
	extrn	GETARW:near
	extrn	GETBASE:near
	extrn	GETLIMIT:near
	extrn	SELOFF2ADDR:near

	NPPROC  DISP_OPER -- Display Operand Data Structure
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display operand analysis data.

On entry:

SS:EBP	==>	FORW_STR

|

	pushad  		; Save all EGP registers

	mov	EA1MODE,@MODE_NEW ; Assume invalid
	mov	EA2MODE,@MODE_NEW ; Assume invalid
	mov	EA1LIM,0	; Mark as invalid
	mov	EA1WID,1	; Mark as byte width

	mov	edx,SCROFF	; In case not used

; Determine whether or not this is a jump instruction

	test	OPERAND.OPER1_FLAG,@OPER_JCC ; Izit a Jcc instruction?
	jz	near ptr DISP_OPER_XJCC ; Not this time

; Ensure the current instruction is visible

	mov	eax,CUR_INSTR ; Get offset of current instruction

	cmp	eax,FIRST_INSTR ; Izit at or above the first instruction?
	jb	near ptr DISP_OPER_EXIT ; Not this time

	cmp	eax,LAST_INSTR  ; Izit at or below the last instruction?
	ja	near ptr DISP_OPER_EXIT ; Not this time

	mov	edx,JCCOFF	; Get Jcc offset
	xchg	edx,SCROFF	; Swap with screen offset

; Setup flags

	mov	ax,[ebp].FORW_EFL.ELO ; Get caller's flags

; Clear reserved flags

	and	ax,not ((mask $R1) or (mask $R2) or (mask $R3)) ; Clear 'em

; Set $R2 to indicate whether or not OF .ne. SF

	mov	bx,ax		; Copy to set SF .ne. OF flag

	and	bx,(mask $OF) or (mask $SF) ; Isolate the OF and SF flags
	jz	short @F	; Jump if both clear

	cmp	bx,(mask $OF) or (mask $SF) ; Check for both set
	je	short @F	; Jump if so

	or	ax,mask $R3	; Set reserved flag to indicate OF .ne. SF
@@:

; Set reserved flags w.r.t. eCX

	mov	ecx,[ebp].FORW_ECX ; Get caller's ECX

	test	OPERAND.OPER1_FLAG,@OPER_ASP ; Izit present?
	jnz	short @F	; Yes

	movzx	ecx,cx  	; Clear high-order word
@@:

; Set $R2 to indicate whether or not eCX is zero

	and	ecx,ecx 	; Check for zero
	jnz	short @F	; Jump if not-zero

	or	ax,mask $R2	; Set reserved flag to indicate eCX = 0
@@:

; Set $R1 to indicate whether or not eCX is one

	cmp	ecx,1		; Check the value
	je	short @F	; Jump if eCX = 1

	or	ax,mask $R1	; Set reserved flag to indicate eCX .ne. 1
@@:

; The low-order bit of the condition code controls whether the
; mask is used directly or by complement.  $R1 is a special case
; in that it always forces a no branch if specified in the mask
; but is not present (in other words, we're at the bottom of a loop
; with ECX=1).	$R1 does not get complemented.

	movzx	ecx,OPERAND.OPER1_CC ; Get the condition code
	mov	ebx,ecx 	; Copy to index register

	SELFBREAK DISP_OPER,4000h ; Break if SELFDBG & 4000h

	and	bx,not @BIT0	; Clear low-order bit
	and	ecx,@BIT0	; Isolate low-order bit
	mov	si,JCCMASK[ebx] ; Get mask bits
	mov	di,si		; Copy mask bits
	and	di,mask $R1	; Isolate $R1
	and	ax,si		; Mask off all others
	xor	ax,di		; Set $R1 if present in mask but not AX
	bt	ax,$R1  	; Did $R1 fail?
	jc	short DISP_OPER_JCCNO ; Branch never taken if so

	xor	si,di		; Exclude $R1 from test
	jz	short DISP_OPER_JCCYES ; ZF=1 only if SI==0 and DI==0 or if
				; SI==mask $R1 and DI==SI.  The mask will
				; never be 0, so we're testing for a
				; simple LOOP instruction.  We've already
				; passed the test for $R1.

	and	ax,si		; Are any other bits set?
	jnz	short DISP_OPER_JCCBR ; Branch taken if CX = 0

; Branch taken if eCX = 1

	loop	DISP_OPER_JCCNO ; Jump if branch not taken
DISP_OPER_JCCYES:

; Mark the instruction as branch taken

	lea	esi,MSG_BROK_FORW ; Offset of assumed forward text

	test	OPERAND.OPER1_FLAG,@OPER_JCC_BACK ; Going backwards
	jz	@F

	lea	esi,MSG_BROK_BACK ; Offset of backward text
@@:
	jmp	short DISP_OPER_JCCOM ; Join common code


; Branch taken if eCX = 0

DISP_OPER_JCCBR:
	jecxz	DISP_OPER_JCCYES ; Jump if branch taken
DISP_OPER_JCCNO:

; Mark the instruction as branch not taken

	lea	esi,MSG_BRNO	; Offset of text to display
DISP_OPER_JCCOM:
	mov	al,CURATTR	; Get current instruction attr
	xchg	al,DEFATTR	; Swap with default attr
	call	DISPASCIIZ	; Display ASCIIZ string from ESI
	xchg	al,DEFATTR	; Restore default attr

	jmp	short DISP_OPER_EXIT ; Join common exit code


; Determine whether or not the instruction references memory

DISP_OPER_XJCC:
	mov	edx,OPROFF	; Get operand offset
	xchg	edx,SCROFF	; Swap with screen offset

	test	OPERAND.OPER2_FLAG,@OPER_MEM ; Does it?
	jz	short @F	; Not this time

	mov	edi,OPER2_DATA  ; Initialize index
	call	DISP_REF	; Display it

	mov	ax,EA1MODE	; Get EA1 mode
	mov	EA2MODE,ax	; Save as EA2 mode
	mov	eax,EA1OFF	; Get EA1 offset
	mov	EA2OFF,eax	; Save as EA2 offset
	mov	eax,EA1BASE	; Get EA1 base
	mov	EA2BASE,eax	; Save as EA2 base
	mov	ax,EA1SEL	; Get EA1 segment/selector
	mov	EA2SEL,ax	; Save as EA2 segment/selector
	mov	eax,EA1LIM	; Get EA1 segment/selector limit
	mov	EA2LIM,eax	; Save as EA2 ...
	mov	eax,EA1WID	; Get EA1 operand width
	mov	EA2WID,eax	; Save as EA2 ...
@@:
	mov	EA1MODE,@MODE_NEW ; Mark as invalid

	test	OPERAND.OPER1_FLAG,@OPER_MEM ; Does it?
	jz	short @F	; Not this time

	mov	edi,OPER1_DATA  ; Initialize index
	call	DISP_REF	; Display it
@@:
DISP_OPER_EXIT:
	mov	SCROFF,edx	; Restore

	popad			; Restore all EGP registers

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_OPER endp			; End DISP_OPER procedure
	NPPROC  DISP_REF -- Display Memory References
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display memory references to operand data.

On entry:

EDI	=	offset into OPERAND

On exit:

If we're computing the EA,
ESI	=	32-bit linear address of the EA

|

; Note that the code at DISP_REF_EA assumes that the stack
; on entry is formed by PUSHAD.

	pushad  		; Save all EGP registers

	call	INST_OPR0E	; Install our local Page Fault handler

	and	OPR_FLAG,not @OPR_ESP ; Mark as not present

; Check for special INT address
; INT is special because it references memory from the IDT
; at 0:0 if VM bit set, or IDTR otherwise

	test	OPERAND.OPER1_DWID[edi],@DWIDTH_INT ; Izit INT?
	jnz	near ptr DWID_INT ; Yes, handle specially

; Display the segment register name

	movzx	esi,OPERAND.OPER1_SEG[edi] ; Get the segment register #

	cmp	si,101b 	; Check against upper limit
	ja	near ptr DISP_REF_EXIT ; Jump if out of range

	test	OPR_FLAG,@OPR_EA ; Izit EA comp only?
	jnz	short @F	; Jump if so

	mov	esi,SEGTXT[esi*(type SEGTXT)] ; DS:ESI ==> segment register name
	call	DISPASCIIZ	; Display ASCIIZ string from ESI
	call	DISPSEP 	; Display selector/segment separator
@@:

; Check for special XLAT displacement

	test	OPERAND.OPER1_DWID[edi],@DWIDTH_XLAT ; Izit XLAT?
	jz	short @F	; Not this time

	movzx	eax,[ebp].FORW_EAX.ELO.LO ; Get byte to translate
	add	OPERAND.OPER1_DISP[edi],eax ; Add into displacement
	or	OPERAND.OPER1_FLAG[edi],@OPER_DSP ; Mark as present
@@:

; Check for special BTx displacement
; BTx is special because its range can extend 2GB in either direction
; depending upon the value in the register operand.

	test	OPERAND.OPER1_DWID[edi],@DWIDTH_BTREG or @DWIDTH_BTIMM ; Izit BTx?
	jz	short @F	; Not this time

	call	BTDISP  	; Return with BT displacement in EAX,
				; bit index in BL

	mov	OPERAND.OPER1_CC[edi],bl ; Save bit index
	add	OPERAND.OPER1_DISP[edi],eax ; Add into displacement
	or	OPERAND.OPER1_FLAG[edi],@OPER_DSP ; Mark as present
@@:

; Determine the offset from the Mod R/M and SIB bytes

	test	OPERAND.OPER1_FLAG[edi],@OPER_ASP ; ASP used?
	jnz	near ptr DISP_REF_ASP ; Yes, handle separately

; No ASP, use 16-bit addressing for effective address calculation

; Shift the Mod R/M byte so the $MOD and $RM fields are adjacent
; for table indexing

	test	OPERAND.OPER1_FLAG[edi],@OPER_MRM ; Izit present?
	jnz	short @F	; Yes

; No Mod R/M byte:  use displacement only of MOD=00, RM=110

	mov	OPERAND.OPER1_MODRM[edi],(00b shl $MOD) or (110b shl $RM)
@@:
	movzx	ebx,OPERAND.OPER1_MODRM[edi] ; Get the Mod R/M byte, clear others
	and	bl,not (mask $REG) ; Clear the REG bits
	mov	bh,bl		; Copy it
	shr	bh,$MOD 	; Shift MOD bits down to bottom of BH
	shl	bl,8-$REG	; Shift RM  bits up   to top	of BL
	shr	bx,8-$REG	; Shift back to bottom

	mov	esi,MRM16BIT[ebx*(type MRM16BIT)] ; DS:ESI ==> initial action for this Mod R/M byte
	xor	ebx,ebx 	; Zero the accumulator

	lods	ds:[esi].EDD	; Get next pointer

	jmp	eax		; Take appropriate action

ADD_OCTUPLE:
	shl	eax,1		; Double it
ADD_QUADRUPLE:
	shl	eax,1		; Double it
ADD_DOUBLE:
	shl	eax,1		; Double it
ADD_SINGLE:
	add	ebx,eax 	; Add it in

	lods	ds:[esi].EDD	; Get next pointer

	jmp	eax		; Take appropriate action

ADD_EAX:
	mov	eax,[ebp].FORW_EAX ; Get it

	jmp	ADD_SINGLE	; Join common code

ADD_EAX2:
	mov	eax,[ebp].FORW_EAX ; Get it

	jmp	ADD_DOUBLE	; Join common doubling code

ADD_EAX4:
	mov	eax,[ebp].FORW_EAX ; Get it

	jmp	ADD_QUADRUPLE	; Join common quadrupling code

ADD_EAX8:
	mov	eax,[ebp].FORW_EAX ; Get it

	jmp	ADD_OCTUPLE	; Join common octupling code

ADD_EBX:
	mov	eax,[ebp].FORW_EBX ; Get it

	jmp	ADD_SINGLE	; Join common code

ADD_EBX2:
	mov	eax,[ebp].FORW_EBX ; Get it

	jmp	ADD_DOUBLE	; Join common doubling code

ADD_EBX4:
	mov	eax,[ebp].FORW_EBX ; Get it

	jmp	ADD_QUADRUPLE	; Join common quadrupling code

ADD_EBX8:
	mov	eax,[ebp].FORW_EBX ; Get it

	jmp	ADD_OCTUPLE	; Join common octupling code

ADD_ECX:
	mov	eax,[ebp].FORW_ECX ; Get it

	jmp	ADD_SINGLE	; Join common code

ADD_ECX2:
	mov	eax,[ebp].FORW_ECX ; Get it

	jmp	ADD_DOUBLE	; Join common doubling code

ADD_ECX4:
	mov	eax,[ebp].FORW_ECX ; Get it

	jmp	ADD_QUADRUPLE	; Join common quadrupling code

ADD_ECX8:
	mov	eax,[ebp].FORW_ECX ; Get it

	jmp	ADD_OCTUPLE	; Join common octupling code

ADD_EDX:
	mov	eax,[ebp].FORW_EDX ; Get it

	jmp	ADD_SINGLE	; Join common code

ADD_EDX2:
	mov	eax,[ebp].FORW_EDX ; Get it

	jmp	ADD_DOUBLE	; Join common doubling code

ADD_EDX4:
	mov	eax,[ebp].FORW_EDX ; Get it

	jmp	ADD_QUADRUPLE	; Join common quadrupling code

ADD_EDX8:
	mov	eax,[ebp].FORW_EDX ; Get it

	jmp	ADD_OCTUPLE	; Join common octupling code

ADD_ESI:
	mov	eax,[ebp].FORW_ESI ; Get it

	jmp	ADD_SINGLE	; Join common code

ADD_ESI2:
	mov	eax,[ebp].FORW_ESI ; Get it

	jmp	ADD_DOUBLE	; Join common doubling code

ADD_ESI4:
	mov	eax,[ebp].FORW_ESI ; Get it

	jmp	ADD_QUADRUPLE	; Join common quadrupling code

ADD_ESI8:
	mov	eax,[ebp].FORW_ESI ; Get it

	jmp	ADD_OCTUPLE	; Join common octupling code

ADD_EDI:
	mov	eax,[ebp].FORW_EDI ; Get it

	jmp	ADD_SINGLE	; Join common code

ADD_EDI2:
	mov	eax,[ebp].FORW_EDI ; Get it

	jmp	ADD_DOUBLE	; Join common doubling code

ADD_EDI4:
	mov	eax,[ebp].FORW_EDI ; Get it

	jmp	ADD_QUADRUPLE	; Join common quadrupling code

ADD_EDI8:
	mov	eax,[ebp].FORW_EDI ; Get it

	jmp	ADD_OCTUPLE	; Join common octupling code

ADD_EBP:
	mov	eax,[ebp].FORW_EBP ; Get it

	jmp	ADD_SINGLE	; Join common code

ADD_EBP2:
	mov	eax,[ebp].FORW_EBP ; Get it

	jmp	ADD_DOUBLE	; Join common doubling code

ADD_EBP4:
	mov	eax,[ebp].FORW_EBP ; Get it

	jmp	ADD_QUADRUPLE	; Join common quadrupling code

ADD_EBP8:
	mov	eax,[ebp].FORW_EBP ; Get it

	jmp	ADD_OCTUPLE	; Join common octupling code

ADD_ESP:			; Note there are no ESP2, ESP4, or ESP8 labels
	mov	eax,[ebp].FORW_ESP ; Get it
	or	OPR_FLAG,@OPR_ESP ; Mark as present

	jmp	ADD_SINGLE	; Join common code


; Display data with ASP

DISP_REF_ASP:

; Shift the Mod R/M byte so the $MOD and $RM fields are adjacent
; for table indexing

	test	OPERAND.OPER1_FLAG[edi],@OPER_MRM ; Izit present?
	jnz	short @F	; Yes

; No Mod R/M byte:  use displacement only of MOD=00, RM=101

	mov	OPERAND.OPER1_MODRM[edi],(00b shl $MOD) or (101b shl $RM)
@@:

; Form an index with the MOD and RM bits

	movzx	eax,OPERAND.OPER1_MODRM[edi] ; Get the Mod R/M byte, clear others
	shl	ax,8-$MOD	; Shift MOD bits into AH
	shl	al,(8-$REG)-(8-$MOD) ; Shift RM bits to top of AL
	shr	ax,8-$REG	; Shift all bits to bottom of AL

	mov	esi,MRM32BIT[eax*(type MRM32BIT)] ; DS:ESI ==> initial action for this Mod R/M byte
	xor	ebx,ebx 	; Zero the accumulator

	lods	ds:[esi].EDD	; Get next pointer

	jmp	eax		; Take appropriate action


; SIB byte
;
; On entry:
;
; EBX	 =	 0

ADD_SIB:

; Check for special case MOD=00, BASE=101

	movzx	eax,OPERAND.OPER1_SIB[edi] ; Get the SIB, clear others
	and	al,mask $BASE	; Isolate BASE bits
	shr	al,$BASE	; Shift to low-order

	test	OPERAND.OPER1_MODRM[edi],mask $MOD ; Check for MOD=00
	jnz	short @F	; Not this time

	cmp	al,101b 	; Check for special case
	je	short SIB_XBASE ; Jump if no base used
@@:

; Add the base to use into EBX

	mov	esi,SIB_BASE[eax*(type SIB_BASE)] ; DS:ESI ==> action vector

	lods	ds:[esi].EDD	; Get next pointer

	jmp	eax		; Take appropriate action


; Form an index with the SS and IND bits

SIB_XBASE:
	movzx	eax,OPERAND.OPER1_SIB[edi] ; Get the SIB, clear others
	shr	al,$IND 	; Shift SS and IND bits to bottom of AL

; Add the scaled index to use into EBX

	mov	esi,SIB_SIND[eax*(type SIB_SIND)] ; DS:ESI ==> action vector

	lods	ds:[esi].EDD	; Get next pointer

	jmp	eax		; Take appropriate action


; Ending action for 16- and 32-bit addressing including SIB

	public  ADD_END
ADD_END:
	test	OPERAND.OPER1_FLAG[edi],@OPER_DSP ; Displacement found?
	jz	short @F	; Not this time

	add	ebx,OPERAND.OPER1_DISP[edi] ; Add it in
@@:

; Check for POP Word/Dword using ESP as base register

	test	OPR_FLAG,@OPR_ESP ; Using ESP as base register?
	jz	short ADD_END_XESP ; Not this time

	cmp	OPERAND.OPER1_DWID[edi],@DWIDTH_POPW ; Check for POP Word Ptr ...
	je	short ADD_END_POPW ; Good guess

	cmp	OPERAND.OPER1_DWID[edi],@DWIDTH_POPD ; Check for POP Dword Ptr ...
	jne	short ADD_END_XESP ; Not this time

	add	ebx,2		; Skip to next word
ADD_END_POPW:
	add	ebx,2		; Skip to next word
ADD_END_XESP:
	mov	eax,ebx 	; Copy to display register

COMMENT|

Determine if we should enforce 16- or 32-bit addressing.

Use 32 bits if ASP present (D-bit in CS has already been taken into account)
or if implicit stack reference in PM with big stack; otherwise, use
16-bit addressing.

|

	test	OPERAND.OPER1_FLAG[edi],@OPER_STK ; Izit an implicit stack ref?
	jnz	short @F	; Jump if so

	test	OPERAND.OPER1_FLAG[edi],@OPER_ASP ; Address size prefix present?
	jnz	short DISP_REF32 ; Yes, use 32-bit addressing
	jmp	short DISP_REF16 ; No, use 16-bit addressing
@@:
	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM86 mode?
	jnz	short DISP_REF16 ; Jump if so

	push	eax		; Save for a moment

	push	[ebp].FORW_SS	; Pass caller's stack selector as argument
	call	GETARW  	; Return with AX = access rights word

	test	ah,mask $DTE_B  ; Izit big?
	pop	eax		; Restore
	jnz	short DISP_REF32 ; Yes, use 32-bit addressing
DISP_REF16:
	test	OPR_FLAG,@OPR_EA ; Izit EA comp only?
	jnz	short @F	; Jump if so

	call	DISPHEX2	; Display the word
@@:
	movzx	ebx,bx  	; Zero high-order word

	jmp	short DISP_REF_SEP ; Join common code

DISP_REF32:
	test	OPR_FLAG,@OPR_EA ; Izit EA comp only?
	jnz	short @F	; Jump if so

	call	DISPHEX4	; Display the dword
@@:
DISP_REF_SEP:
	test	OPR_FLAG,@OPR_EA ; Izit EA comp only?
	jnz	short @F	; Jump if so

	mov	al,'='          ; Separator
	call	DISPTXT 	; Display byte on screen as text

	mov	EA1OFF,ebx	; Save as EA1 offset
@@:

; Include the segment base

	movzx	esi,OPERAND.OPER1_SEG[edi] ; Get the segment #
	mov	esi,SEGOFF[esi*(type SEGOFF)] ; Get offset

	mov	ecx,[ebp+esi-@BPBACK].DTR_BASE ; Get segment/selector base
	add	ebx,ecx 	; Plus base to get 32-bit LA

	test	OPR_FLAG,@OPR_EA ; Izit EA comp only?
	jnz	near ptr DISP_REF_EA ; Jump if so

	mov	ax,[ebp+esi-@BPBACK].DTR_LIM ; Get segment/selector value
	mov	EA1SEL,ax	; Save as EA1 segment/selector
	mov	EA1BASE,ecx	; Save as EA1 base

	mov	ax,@MODE_VM or @MODE_SEP ; Assume VM
	mov	EA1LIM,0FFFFh	; Save as EA1 segment/selector limit

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	jnz	short DISP_REF_VM ; Jump if so

	push	EA1SEL  	; Pass EA1 selector
	call	GETLIMIT	; Return with EAX = selector limit
	mov	EA1LIM,eax	; Save as EA1 segment/selector limit

	push	EA1SEL  	; Pass EA1 selector
	call	GETARW  	; Return with AX = access rights word

	test	ah,mask $DTE_B  ; Izit USE32?
	mov	ax,@MODE_SEP	; It's PM
	jz	short @F	; Jump if not

	or	ax,@MODE_USE32  ; Mark as USE32
@@:
DISP_REF_VM:
	mov	EA1MODE,ax	; Save as EA1 mode

	mov	esi,edi 	; Save for a moment
	mov	eax,OPERAND.OPER1_DWID[edi] ; Get the data width flag
	lea	edi,DWIDTAB	; ES:EDI ==> # data widths allowed
	mov	ecx,DWIDTAB_LEN ; ECX = # entries in the table
  repne scas	DWIDTAB[edi]	; Search for it
	jne	near ptr DISP_REF_EXIT ; Not found, so we ignore it

	xchg	esi,edi 	; Swap to get original EDI back
	sub	esi,offset es:DWIDTAB[type DWIDTAB] ; Convert to origin-0

	jmp	DWIDACT[esi]	; Take appropriate action


DISP_REF_EA:
	mov	[esp].PUSHAD_ESI,ebx ; Return EA in ESI

	jmp	DISP_REF_EXIT	; Join common exit code


DWID_BT:			; Byte with BT disp		  00	1
;;;;;;; mov	al,gs:[ebx+0]	; Get the byte to format
	mov	ah,OPERAND.OPER1_CC[edi] ; Get bit index
	mov	al,2		; Get bit display flag
	push	eax		; Pass bit display flag/bit index
	PUSHD	0		; Pass offset as argument
	call	DBGET		; Get, format, and display a byte as bits

	jmp	DISP_REFCOM	; Join common code


DWID_XLAT:			; Byte				  00	1
DWID_BYTE:			; Byte				  00	1
;;;;;;; mov	al,gs:[ebx+0]	; Get the byte to format
	PUSHD	0		; Pass hex display flag
	PUSHD	0		; Pass offset as argument
	call	DBGET		; Get, format, and display a byte

	jmp	DISP_REFCOM	; Join common code


DWID_POPW:			; Word				1100	2
DWID_WORD:			; Word				1100	2
	mov	EA1WID,2	; Mark as word width

;;;;;;; mov	ax,gs:[ebx+0]	; Get the word to format
	PUSHD	0		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	jmp	DISP_REFCOM	; Join common code


DWID_POPD:			; Dword 		    33221100	4
DWID_DWORD:			; Dword 		    33221100	4
	mov	EA1WID,4	; Mark as dword width

;;;;;;; mov	eax,gs:[ebx+0]  ; Get the dword to format
	PUSHD	0		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword

	jmp	DISP_REFCOM	; Join common code


DWID_QWORD:			; Qword 	    7766554433221100	8
	mov	EA1WID,8	; Mark as qword width

;;;;;;; mov	eax,gs:[ebx+4]  ; Get the dword to format
	PUSHD	4		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword

;;;;;;; mov	eax,gs:[ebx+0]  ; Get the dword to format
	PUSHD	0		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword

	jmp	DISP_REFCOM	; Join common code


DWID_TBYTE:			; Tbyte 	99887766554433221100   10
	mov	EA1WID,10	; Mark as tbyte width

;;;;;;; mov	ax,gs:[ebx+8]	; Get the word to format
	PUSHD	8		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

;;;;;;; mov	eax,gs:[ebx+4]  ; Get the dword to format
	PUSHD	4		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword

;;;;;;; mov	eax,gs:[ebx+0]  ; Get the dword to format
	PUSHD	0		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword

	jmp	DISP_REFCOM	; Join common code


				; If in Virtual 8086 Mode,
DWID_INT:			; PTR16:16		   3322:1100	4
				; If in Protected Mode,
				; DTE		       3322|77661100	6
	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

	movzx	eax,OPERAND.OPER1_CC[edi] ; Get the interrupt #

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	jnz	short DWID_INT1 ; Yes

	lea	esi,MSG_INTPM	; DS:ESI ==> "IDT[8*"

	jmp	short DWID_INT2 ; Join common code

DWID_INT1:
	lea	esi,MSG_INTVM	; DS:ESI ==> "IDT[4*"
DWID_INT2:
	call	DISPASCIIZ	; Display ASCIIZ string from ESI
	call	DISPHEX1	; Display the byte

	push	eax		; Save for a moment
	mov	al,'='          ; Separator
	call	DISPTXT 	; Display byte on screen as text
	pop	eax		; Restore

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	jnz	short DWID_INT3 ; Yes, continue on

	shl	eax,3-0 	; Convert from qwords to bytes

	jmp	short DWID_INT4 ; Join common code

DWID_INT3:
	shl	eax,2-0 	; Convert from dwords to bytes
DWID_INT4:
	call	DISPHEX2	; Display the word

	mov	ebx,eax 	; Copy offset into the IDT

	mov	al,']'          ; Separator
	call	DISPTXT 	; Display byte on screen as text

	mov	al,'='          ; Separator
	call	DISPTXT 	; Display byte on screen as text

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	jnz	short DWID_PTR16 ; Yes, continue on

DWID_DTE:			; DTE		       3322:77661100	6
	mov	EA1WID,6	; Mark as 6byte width

	add	ebx,[ebp-@BPBACK].BACK_IDT.DTR_BASE ; Plus base of the IDT

;;;;;;; mov	ax,gs:[ebx].IDT_SELECT ; Get the word to format
	push	dword ptr IDT_SELECT ; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	mov	EA1TSEL,ax	; Save as target segment/selector

	call	DISPSEP 	; Display selector/segment separator

;;;;;;; mov	ax,gs:[ebx].IDT_OFFHI ; Get the word to format
	push	dword ptr IDT_OFFHI ; Pass offset as argument
	call	DWGET		; Get, format, and display a word

;;;;;;; mov	ax,gs:[ebx].IDT_OFFLO ; Get the word to format
	push	dword ptr IDT_OFFLO ; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	jmp	DISP_REFCOM	; Join common code


DWID_PTR16:			; PTR16:16		   3322:1100	4
	mov	EA1WID,2+2	; Mark as two-word width

;;;;;;; mov	ax,gs:[ebx+2]	; Get the word to format
	PUSHD	2		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	mov	EA1TSEL,ax	; Save as target segment/selector

	call	DISPSEP 	; Display selector/segment separator

;;;;;;; mov	ax,gs:[ebx+0]	; Get the word to format
	PUSHD	0		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	jmp	DISP_REFCOM	; Join common code


DWID_PTR32:			; PTR16:32	       5544:33221100	6
	mov	EA1WID,2*4	; Mark as two-dword width

;;;;;;; mov	ax,gs:[ebx+4]	; Get the word to format
	PUSHD	4		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	mov	EA1TSEL,ax	; Save as target segment/selector

	call	DISPSEP 	; Display selector/segment separator

;;;;;;; mov	eax,gs:[ebx+0]  ; Get the dword to format
	PUSHD	0		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword

	jmp	DISP_REFCOM	; Join common code


DWID_PTR16F:			; PTR16:16 FL	      3322:1100 5544	6
	mov	EA1WID,3*2	; Mark as three-word width

; This format is used by IRET.	If VM=0 and NT=1, display
; the destination CS:eIP, eFL, eSP, and SS.

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM86 mode?
	jnz	short @F	; Jump if so

	test	[ebp].FORW_EFL,mask $NT ; Izit a task switch?
	jnz	short DWID_PTR16F_TSS ; Jump if so
@@:
;;;;;;; mov	ax,gs:[ebx+2]	; Get the word to format
	PUSHD	2		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	mov	EA1TSEL,ax	; Save as target segment/selector

	call	DISPSEP 	; Display selector/segment separator

;;;;;;; mov	ax,gs:[ebx+0]	; Get the word to format
	PUSHD	0		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	ax,gs:[ebx+4]	; Get the word to format
	PUSHD	4		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

; If we're currently in PM and about to undergo
; a ring transition to a less privileged level, also display the SS:SP

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	jnz	short DWID_PTR16F1 ; Jump if so (not in PM)

	mov	al,[ebp].FORW_CS.LO ; Get current CS low-order byte
	mov	ah,gs:[ebx+2].LO ; Get new CS low-order byte
	and	ax,((mask $PL) shl 8) or (mask $PL) ; Isolate PL bits

	cmp	al,ah		; Izit a ring transition?
	je	short DWID_PTR16F1 ; Jump if not
@@:
	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	ax,gs:[ebx+8]	; Get the word to format
	PUSHD	8		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	mov	al,'|'          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	ax,gs:[ebx+6]	; Get the word to format
	PUSHD	6		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	add	EA1WID,2+2	; Add in two-word width
DWID_PTR16F1:
	jmp	DISP_REFCOM	; Join common code


; Because this is a task switch, the OSP on the IRETd is irrelevant
; so we can use the same code for both 16- and 32-bit cases.

DWID_PTR16F_TSS:
DWID_PTR32F_TSS:
	push	[ebp-@BPBACK].BACK_TR.DTR_LIM ; Pass TSS selector
	call	GETBASE 	; Return with EAX = selector base
	jc	near ptr DWID_PTR_TSSERR1 ; Jump if it's invalid

	mov	ax,AGROUP:[eax].TSS_LINK ; Get back link TSS
	mov	bx,ax		; Copy to SELOFF2ADDR register

	push	bx		; Pass selector as argument
	call	GETARW  	; Return with AX = access rights word
	jc	near ptr DWID_PTR_TSSERR1 ; Jump if it's invalid

	mov	di,ax		; Copy for later use

	push	bx		; Pass back link selector
	call	GETBASE 	; Return with EAX = selector base
	mov	esi,eax 	; Save for later use

; As a precaution, if paging is enabled, ensure that the value of
; CR3 in the back link TSS is valid.  If it isn't, the CPU goes poof.

	mov	eax,cr0 	; Get register with paging bit

	test	eax,mask $PG	; Are we paging?
	jz	short @F	; Jump if not

	test	di,mask $DS_386 ; Izit 386 TSS?
	jz	short @F	; Jump if not (no CR3)

	mov	eax,AGROUP:[esi].TSS_CR3 ; Get the value
	and	eax,@PTE_FRM	; Isolate the frame
	jz	near ptr DWID_PTR_TSSERR2 ; Jump if invalid
@@:
	xor	eax,eax 	; Zero the offset

	call	SELOFF2ADDR	; Convert BX|EAX to address
				; Return with BX = selector
				; ...	     EAX = offset
				; ...	     EDX = selector base
				; ...	      CX = flags
	jc	near ptr DWID_PTR_TSSERR1 ; Jump if it's invalid

	xchg	eax,ebx 	; Swap to display selector in BX
	call	DISPHEX2	; Display the word
	xchg	eax,ebx 	; Restore

	push	eax		; Save for a moment

	mov	al,'|'          ; Separator if in PM

	test	cx,@ADDR_PM	; Izit in PM?
	jnz	short @F	; Jump if so

	mov	al,':'          ; Separator if in VM
@@:
	call	DISPTXT 	; Display byte on screen as text

	pop	eax		; Restore

; If the resulting CS is USE32, display the dword offset,
; otherwise, display the word offset

	test	cx,@ADDR_USE32  ; Izit a big selector?
	jnz	short @F	; Jump if so

	call	DISPHEX2	; Display the word

	jmp	short DWID_PTR_TSS1 ; Join common code

@@:
	call	DISPHEX4	; Display the dword
DWID_PTR_TSS1:
	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

; Display eFL (depending upon 286/386 TSS)

	test	di,mask $DS_386 ; Izit 386 TSS?
	jnz	short @F	; Jump if so

	mov	ax,AGROUP:[esi].TSS2_FL ; Get the flags if 286 TSS
	call	DISPHEX2	; Display the word

	jmp	short DWID_PTR_TSSCOM1 ; Join common code

@@:
	mov	eax,AGROUP:[esi].TSS_EFL ; Get the flags if 386 TSS
	call	DISPHEX4	; Display the dword
DWID_PTR_TSSCOM1:

; Display eSP (depending upon B-bit in SS and 286/386 TSS)

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

	test	di,mask $DS_386 ; Izit 386 TSS?
	jnz	short @F	; Jump if so

	mov	ax,AGROUP:[esi].TSS2_SP ; Get the flags if 286 TSS
	call	DISPHEX2	; Display the word

	jmp	short DWID_PTR_TSSCOM2 ; Join common code

@@:

; Check the B-bit in the stack selector

	mov	ebx,AGROUP:[esi].TSS_ESP ; Get the stack offset

	test	cx,@ADDR_PM	; Izit in PM?
	jz	short DWID_PTR_TSSCOM1A ; Jump if not (it's big)

	mov	ax,AGROUP:[esi].TSS_SS ; Get the stack segment/selector if 386 TSS

	test	di,mask $DS_386 ; Izit 386 TSS?
	jnz	short @F	; Jump if so

	mov	ax,AGROUP:[esi].TSS2_SS ; Get the stack segment/selector if 286 TSS
@@:
	push	ax		; Pass selector as argument
	call	GETARW  	; Return with AX = access rights word

	test	ah,mask $DTE_B  ; Izit big?
	jnz	short DWID_PTR_TSSCOM1A ; Jump if so

	movzx	ebx,bx  	; Zero the high-order word
DWID_PTR_TSSCOM1A:
	mov	eax,ebx 	; Copy stack offset
	call	DISPHEX4	; Display the dword
DWID_PTR_TSSCOM2:

; Display SS (depending upon 286/386 TSS)

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

	mov	ax,AGROUP:[esi].TSS_SS ; Get the stack segment/selector if 386 TSS

	test	di,mask $DS_386 ; Izit 386 TSS?
	jnz	short @F	; Jump if so

	mov	ax,AGROUP:[esi].TSS2_SS ; Get the stack segment/selector if 286 TSS
@@:
	call	DISPHEX2	; Display the word

	jmp	DISP_REFCOM	; Join common code

DWID_PTR_TSSERR1:
	lea	esi,MSG_INVBACK ; DS:ESI ==> invalid back link format
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	jmp	DISP_REFCOM	; Join common code

DWID_PTR_TSSERR2:
	lea	esi,MSG_INVCR3  ; DS:ESI ==> invalid CR3 in back link TSS
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	jmp	DISP_REFCOM	; Join common code


DWID_PTR32F:			; PTR16:32 EFL 5544:33221100 BBAA9988  10
	mov	EA1WID,3*4	; Mark as three-dword width

; This format is used by IRETD.  If VM=0 and NT=1, display
; the destination CS:eIP, eFL, eSP, and SS.

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM86 mode?
	jnz	short @F	; Jump if so

	test	[ebp].FORW_EFL,mask $NT ; Izit a task switch?
	jnz	near ptr DWID_PTR32F_TSS ; Jump if so
@@:
;;;;;;; mov	ax,gs:[ebx+4]	; Get the word to format
	PUSHD	4		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	mov	EA1TSEL,ax	; Save as target segment/selector

; Display selector/segment separator based upon VM bit in EFL
; That is, depending upon whether or not we're switching
; from Protected Mode to VM 8086 mode.

	mov	al,':'          ; VM86 separator

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	jnz	short @F	; Yes, hence VM bit is ignored

	test	gs:[ebx+8].EHI,mask $VM ; Izit VM 8086 mode?
	jnz	short @F	; Yes

	mov	al,'|'          ; PM separator
@@:
	mov	cl,al		; Save separator and mode indicator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	eax,gs:[ebx+0]  ; Get the dword to format
	PUSHD	0		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	eax,gs:[ebx+8]  ; Get the dword to format
	PUSHD	8		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword

; If we're currently in PM returning to VM or about to undergo
; a ring transition to a less privileged level, also display the SS:ESP

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	jnz	short DWID_PTR32F1 ; Jump if so (not in PM)

	test	gs:[ebx+8].EHI,mask $VM ; Izit returning to VM 8086 mode?
	jnz	short @F	; Jump if so

	mov	al,[ebp].FORW_CS.LO ; Get current CS low-order byte
	mov	ah,gs:[ebx+4].LO ; Get new CS low-order byte
	and	ax,((mask $PL) shl 8) or (mask $PL) ; Isolate PL bits

	cmp	al,ah		; Izit a ring transition?
	je	short DWID_PTR32F1 ; Jump if not
@@:
	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	ax,gs:[ebx+16]  ; Get the word to format
	PUSHD	16		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	mov	al,cl		; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	eax,gs:[ebx+12] ; Get the dword to format
	PUSHD	12		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword

	add	EA1WID,4+4	; Add in two-dword width
DWID_PTR32F1:
	jmp	DISP_REFCOM	; Join common code


DWID_DTR:			; DTR		       1100 55443322	6
	mov	EA1WID,2+4	; Mark as word-dword width

;;;;;;; mov	ax,gs:[ebx+0]	; Get the word to format
	PUSHD	0		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	eax,gs:[ebx+2]  ; Get the dword to format
	PUSHD	2		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword

	jmp	DISP_REFCOM	; Join common code


DWID_WORD2:			; Two words		   1100 3322	4
DWID_BNDW:			; BOUND word		   1100 3322	4
	mov	EA1WID,2*2	; Mark as two-word width

;;;;;;; mov	ax,gs:[ebx+0]	; Get the word to format
	PUSHD	0		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	ax,gs:[ebx+2]	; Get the word to format
	PUSHD	2		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	jmp	DISP_REFCOM	; Join common code


DWID_DWORD2:			; Two dwords	   33221100 77665544	8
DWID_BNDD:			; BOUND Dword	   33221100 77665544	8
	mov	EA1WID,2*4	; Mark as two-dword width

;;;;;;; mov	eax,gs:[ebx+0]  ; Get the dword to format
	PUSHD	0		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	eax,gs:[ebx+4]  ; Get the dword to format
	PUSHD	4		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword

	jmp	DISP_REFCOM	; Join common code


DWID_DWORD3:			; Three dwords	   33221100 77665544...12
	mov	EA1WID,3*4	; Mark as three-dword width

;;;;;;; mov	eax,gs:[ebx+0]  ; Get the dword to format
	PUSHD	0		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	eax,gs:[ebx+4]  ; Get the dword to format
	PUSHD	4		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	eax,gs:[ebx+8]  ; Get the dword to format
	PUSHD	8		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword

	jmp	DISP_REFCOM	; Join common code


DWID_WORD3:			; Three words	      1100 3322 5544	6
	mov	EA1WID,3*2	; Mark as three-word width

;;;;;;; mov	ax,gs:[ebx+0]	; Get the word to format
	PUSHD	0		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	ax,gs:[ebx+2]	; Get the word to format
	PUSHD	2		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	ax,gs:[ebx+4]	; Get the word to format
	PUSHD	4		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	jmp	DISP_REFCOM	; Join common code


DWID_POPA:			; Eight words	 1100 3322 5544 7766...16
	mov	EA1WID,8*2	; Mark as eight-word width

	jmp	short DWID_WORD4A ; Join common code

DWID_WORD4:			; Four words	 1100 3322 5544 7766	8
	mov	EA1WID,4*2	; Mark as four-word width
DWID_WORD4A:
;;;;;;; mov	ax,gs:[ebx+0]	; Get the word to format
	PUSHD	0		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	ax,gs:[ebx+2]	; Get the word to format
	PUSHD	2		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	ax,gs:[ebx+4]	; Get the word to format
	PUSHD	4		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	ax,gs:[ebx+6]	; Get the word to format
	PUSHD	6		; Pass offset as argument
	call	DWGET		; Get, format, and display a word

	jmp	short DISP_REFCOM ; Join common code


DWID_POPAD:			; Eight dwords	   33221100 77665544...32
	mov	EA1WID,8*4	; Mark as eight-dword width

	jmp	short DWID_DWORD4A ; Join common code

DWID_DWORD4:			; Four dwords	   33221100 77665544...12
	mov	EA1WID,4*4	; Mark as four-dword width
DWID_DWORD4A:
;;;;;;; mov	eax,gs:[ebx+0]  ; Get the dword to format
	PUSHD	0		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	eax,gs:[ebx+4]  ; Get the dword to format
	PUSHD	4		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	eax,gs:[ebx+8]  ; Get the dword to format
	PUSHD	8		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	eax,gs:[ebx+12] ; Get the dword to format
	PUSHD	12		; Pass offset as argument
	call	DDGET		; Get, format, and display a dword
DISP_REFCOM:
	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text
DISP_REF_EXIT:
	call	REST_OPR0E	; Restore previous Page Fault handler

	popad			; Restore all EGP registers

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_REF endp			; End DISP_REF procedure
	NPPROC  BTDISP -- Get BT Displacement
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get BT displacement.

On entry:

SS:EBP	==>	FORW_STR
EDI	=	offset into OPERAND

On exit:

EAX	=	displacement
BL	=	bit index (0-7)

|

	push	esi		; Save for a moment

	movzx	esi,OPERAND.OPER1_MODRM[edi] ; Get it

; Note that the following mechanism doesn't correctly handle
; a register operand of eSP, but then who would use that in
; a BTx instruction?

; Distinguish register vs. immediate form

	test	OPERAND.OPER1_DWID[edi],@DWIDTH_BTIMM ; Izit immediate form?
	jnz	short BTDISP_IMM ; Jump if so
				; Fall through if register form
	and	si,mask $REG	; Isolate the register operand
	shr	si,$REG 	; Shift to low-order
	sub	si,7		; Complement in 7
	neg	si		; To match PUSHA order
	shl	si,2-0  	; Times four to index table of words
	mov	eax,[ebp+esi].FORW_EDI ; Get the register operand

; If there is an operand size prefix, use the register directly;
; otherwise sign-extend it from 16 to 32 bits

	test	OPERAND.OPER1_FLAG[edi],@OPER_OSP ; Check for OSP
	jnz	short @F	; Jump if present

	movsx	eax,ax  	; Sign-extend into high-order word
@@:
	jmp	short BTDISP_COM ; Join common code


; It's immediate form of BTx instruction

BTDISP_IMM:
	mov	eax,OPERAND.OPER1_IMM[edi] ; Get the immediate value
	and	eax,32-1	; Isolate modulo 32 (that's what the CPU does)

; If this is the 16-bit form of the BTx instruction,
; the immediate value is taken modulo 16

	test	OPERAND.OPER1_FLAG[edi],@OPER_OSP ; Check for OSP
	jnz	short BTDISP_COM ; Jump if present

	and	eax,16-1	; Isolate modulo 16 (that's what the CPU does)
BTDISP_COM:
	mov	bl,al		; Copy low-order byte
	and	bl,(1 shl 3)-1  ; Isolate bit index
	sar	eax,3		; Signed-divide by eight to get byte index

	pop	esi		; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BTDISP	endp			; End BTDISP procedure
	NPPROC  DISPSEP -- Display Selector/Segment Separator
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display selector/segment separator

On entry:

SS:EBP	==>	FORW_STR

|

	REGSAVE <eax>		; Save register

	mov	al,':'          ; VM86 separator

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	jnz	short @F	; Yes

	mov	al,'|'          ; PM separator
@@:
	call	DISPTXT 	; Display byte on screen as text

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPSEP endp			; End DISPSEP procedure
	NPPROC  DBGET -- Get, Format, And Display Byte
	assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get, format, and display a byte.

On entry:

Offset on stack
GS:EBX+offset ==> byte to format

|

DBGET_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
DBGET_OFF dd	?		; ...	   offset
DBGET_FLG db	?		; ...	   display flag (0=hex, 1=text, 2=bits)
DBGET_NDX db	?		; If bit display, bit index
	dw	?		; Dword filler

DBGET_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ebx,ecx>	; Save registers

	mov	eax,[ebp].DBGET_OFF ; Get offset

	clc			; Mark as no error
	mov	al,gs:[ebx+eax] ; AL = byte to format
	jc	short DBGET_ERR ; Jump if error

	cmp	[ebp].DBGET_FLG,1 ; Check for hex (0) vs. text (1) vs. bits (2)
	je	short DBGET_TXT1 ; Jump if text display
	jb	short DBGET_BYTE ; Jump if byte display
				; Fall through if bit display

	mov	bl,al		; Get byte to format into bits
	mov	ecx,8		; # bits in a byte
	inc	[ebp].DBGET_NDX ; Increment bit index to track CL
DBGET_NEXTBIT:
	shl	bl,1		; Shift next higher bit into CF
	setc	al		; Copy CF to AL
	add	al,'0'          ; Convert from 0/1 to '0'/'1'

	mov	bh,DEFATTR	; Get default attr

	cmp	cl,[ebp].DBGET_NDX ; Izit our index?
	jne	short @F	; Jump if not

	mov	bh,REGATTR	; Get value to be tested attribute
	xchg	bh,DEFATTR	; Swap with default attr
@@:
	call	DISPTXT 	; Display char on screen as text
	xchg	bh,DEFATTR	; Restore default attr

	loop	DBGET_NEXTBIT	; Jump if more bits to display

	jmp	short DBGET_EXIT ; Join common exit code

DBGET_BYTE:
	call	DISPHEX1	; Display the byte

	jmp	short DBGET_EXIT ; Join common exit code

DBGET_ERR:
	mov	al,'?'          ; Illegal byte value

	cmp	[ebp].DBGET_FLG,1 ; Check for hex (0) vs. text (1) vs. bits (2)
	je	short DBGET_TXT1 ; Jump if text display (one char)
	jb	short DBGET_TXT2 ; Jump if byte display (two chars)
				; Fall through if bit display (eight chars)

	call	DISPTXT 	; Display char on screen as text
	call	DISPTXT 	; Display char on screen as text
	call	DISPTXT 	; Display char on screen as text
	call	DISPTXT 	; Display char on screen as text
	call	DISPTXT 	; Display char on screen as text
	call	DISPTXT 	; Display char on screen as text
DBGET_TXT2:
	call	DISPTXT 	; Display char on screen as text
DBGET_TXT1:
	call	DISPTXT 	; Display char on screen as text
DBGET_EXIT:
	REGREST <ecx,ebx,eax>	; Restore

	pop	ebp		; Restore

	ret	4+4		; Return to caller, popping arguments

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DBGET	endp			; End DBGET procedure
	NPPROC  DWGET -- Get, Format, And Display Word
	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get, format, and display a word.

On entry:

Offset on stack
GS:EBX+offset ==> word to format

On exit:

AX	=	destroyed

|

DWGET_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
DWGET_OFF dd	?		; ...	   offset

DWGET_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax>		; Save register

	mov	eax,[ebp].DWGET_OFF ; Get the offset
	inc	eax		; Skip to high-order byte

	PUSHD	0		; Pass hex display flag
	push	eax		; Pass offset as argument
	call	DBGET		; Get, format, and display a byte

	dec	eax		; Skip to low-order byte

	PUSHD	0		; Pass hex display flag
	push	eax		; Pass offset as argument
	call	DBGET		; Get, format, and display a byte

	REGREST <eax>		; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DWGET	endp			; End DWGET procedure
	NPPROC  DDGET -- Get, Format, And Display Dword
	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get, format, and display a dword.

On entry:

Offset on stack
GS:EBX+offset ==> dword to format

|

DDGET_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
DDGET_OFF dd	?		; ...	   offset

DDGET_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax>		; Save register

	mov	eax,[ebp].DDGET_OFF ; Get the offset
	add	eax,3		; Skip to high-order byte

	PUSHD	0		; Pass hex display flag
	push	eax		; Pass offset as argument
	call	DBGET		; Get, format, and display a byte

	dec	eax		; Skip to midhigh-order byte

	PUSHD	0		; Pass hex display flag
	push	eax		; Pass offset as argument
	call	DBGET		; Get, format, and display a byte

	dec	eax		; Skip to midlow-order byte

	PUSHD	0		; Pass hex display flag
	push	eax		; Pass offset as argument
	call	DBGET		; Get, format, and display a byte

	dec	eax		; Skip to low-order byte

	PUSHD	0		; Pass hex display flag
	push	eax		; Pass offset as argument
	call	DBGET		; Get, format, and display a byte

	REGREST <eax>		; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DDGET	endp			; End DDGET procedure
	FPPROC  OPR_INT0E -- Local Page Fault Interrupt Handler
	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local Page Fault interrupt handler

|

OPR0E_STR struc

	  dd	?		; 00-03:  Caller's EBP
OPR0E_ERR dd	?		; 04-07:  ...	   error code
OPR0E_EIP dd	?		; 08-0B:  ...	   EIP
OPR0E_CS  dw	?,?		; 0C-0F:  ...	   CS w/filler
OPR0E_EFL dd	?		; 10-13:  ...	   EFL

OPR0E_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,esi,ds,es> ; Save registers

	cld			; Ensure string ops forwardly

	SETDATA es		; Set data selector into ES
	assume  es:DGROUP	; Tell the assembler about it

	lds	esi,[ebp].OPR0E_EIP.EDF ; DS:ESI ==> 1st byte of instruction
	assume	ds:nothing	; Tell the assembler about it

; Mark as in error through carry flag

	or	[ebp].OPR0E_EFL.ELO,mask $CF ; CF=1

; and ZF=1 in case REPNE SCAS
; or  ZF=0 in case REPE SCAS

	mov	eax,-1		; Initialize index
@@:
	inc	eax		; Skip to next instruction byte

	cmp	ds:[eax+esi].LO,@OPCOD_REPE ; Izit REPE?
	je	short OPR_INT0E_REPE ; Jump if so

	cmp	ds:[eax+esi].LO,@OPCOD_REPNE ; Izit REPNE?
	je	short OPR_INT0E_REPNE ; Jump if so

	cmp	ds:[eax+esi].LO,@OPCOD_OSP ; Izit OSP?
	je	short @B	; Jump if so

	cmp	ds:[eax+esi].LO,@OPCOD_ASP ; Izit ASP?
	je	short @B	; Jump if so

	jmp	short OPR_INT0E_COM ; Join common code

OPR_INT0E_REPE:
	and	[ebp].OPR0E_EFL.ELO,not (mask $ZF) ; ZF=0

	jmp	short OPR_INT0E_COM ; Join common code

OPR_INT0E_REPNE:
	or	[ebp].OPR0E_EFL.ELO,mask $ZF ; ZF=1

;;;;;;; jmp	short OPR_INT0E_COM ; Join common code


; Skip over the instruction

OPR_INT0E_COM:
	call	GETILEN 	; Return with EAX = length of instruction
				;  with DS:ESI==> 1st byte of next instruction
	add	[ebp].OPR0E_EIP,eax ; Skip to the next insrtuction

	REGREST <es,ds,esi,eax> ; Restore
	assume  ds:nothing,es:nothing ; Tell the assembler about it

	pop	ebp		; Restore

	add	esp,size OPR0E_ERR ; Strip off error code

	iretd			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OPR_INT0E endp			; End OPR_INT0E procedure
	NPPROC  GETILEN -- Get Instruction Length
	assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get instruction length

On entry:

DS:ESI	==>	First byte of instruction

On exit:

EAX	=	length of instruction
DS:ESI	==>	changed

|

	REGSAVE <ebx,ecx,edx>	; Save registers

	push	esi		; Save original offset

	mov	dl,0		; Initialize USE16 flags

	mov	ax,ds		; Get incoming selector (assumed to be code)
	lar	eax,eax 	; Get A/R dword with D-bit in it

	bt	eax,$DT_DC  + (8*(DESC_ACCESS-DESC_BASE2)) ; Test DT_DC-bit
	jnc	short @F	; Jump if not data/code

	bt	eax,$DC_COD + (8*(DESC_ACCESS-DESC_BASE2)) ; Test DC_COD-bit
	jnc	short @F	; Jump if not code

	bt	eax,$DTE_B + (8*(DESC_SEGLM1-DESC_BASE2)) ; Test D-bit
	jnc	short @F	; Jump if USE16

	mov	dl,$OSP or $ASP ; Initialize USE32 flags
@@:
	xor	ecx,ecx 	; Initialize byte count
	cld			; String ops forwardly
GETILEN_NEXT:
	lods	ds:[esi].LO	; Get next instruction byte
	inc	ecx		; Count it in

	cmp	al,@OPCOD_CS	; Check for CS:
	je	short GETILEN_NEXT ; Jump if so

	cmp	al,@OPCOD_DS	; Check for DS:
	je	short GETILEN_NEXT ; Jump if so

	cmp	al,@OPCOD_ES	; Check for ES:
	je	short GETILEN_NEXT ; Jump if so

	cmp	al,@OPCOD_FS	; Check for FS:
	je	short GETILEN_NEXT ; Jump if so

	cmp	al,@OPCOD_GS	; Check for GS:
	je	short GETILEN_NEXT ; Jump if so

	cmp	al,@OPCOD_SS	; Check for SS:
	je	short GETILEN_NEXT ; Jump if so

	cmp	al,@OPCOD_REPE  ; Check for REPE
	je	short GETILEN_NEXT ; Jump if so

	cmp	al,@OPCOD_REPNE ; Check for REPNE
	je	short GETILEN_NEXT ; Jump if so

	cmp	al,@OPCOD_LOCK  ; Check for LOCK
	je	short GETILEN_NEXT ; Jump if so

	cmp	al,@OPCOD_ESC0  ; Izit below ESC 0?
	jb	short @F	; Jump if so

	cmp	al,@OPCOD_ESC7  ; Izit above ESC 7?
	jbe	short GETILEN_NEXT ; Jump if not
@@:
	cmp	al,@OPCOD_OSP ; Check for OSP
	jne	short @F	; Jump if not

	xor	dl,$OSP 	; Toggle the state

	jmp	short GETILEN_NEXT ; Jump if so

@@:
	cmp	al,@OPCOD_ASP ; Check for ASP
	jne	short @F	; Jump if not

	xor	dl,$ASP 	; Toggle the state

	jmp	short GETILEN_NEXT ; Jump if so

@@:
	lea	ebx,OPCOD1	; ES:EBX ==> one-byte opcode table

	cmp	al,@OPCOD_2ND	; Check for secondary opcodes
	jne	short @F	; Jump if not

	lods	ds:[esi].LO	; Get next instruction byte (opcode)
	inc	ecx		; Count it in
	lea	ebx,OPCOD2	; ES:EBX ==> two-byte opcode table
@@:
	xlat	OPCOD1[ebx]	; Translate opcode into flags
	or	dl,al		; Include with OSP/ASP flags

; Check for immediate word:word (OSP=0) or word:dword (OSP=1)

	test	dl,$A		; Check it
	jz	short GETILEN_XA ; Jump if not

	add	ecx,2+2 	; Count in word:word

	test	dl,$OSP 	; Check for OSP
	jz	short GETILEN_XA ; Jump if OSP=0

	add	ecx,2		; Count in extra word
GETILEN_XA:

; Check for immediate word (ASP=0) or dword (ASP=1)

	test	dl,$O		; Check it
	jz	short GETILEN_XO ; Jump if not

	add	ecx,2		; Count in word

	test	dl,$ASP 	; Check for ASP
	jz	short GETILEN_XO ; Jump if ASP=0

	add	ecx,2		; Count in extra word
GETILEN_XO:

; Check for immediate byte

	test	dl,$B		; Check it
	jz	short GETILEN_XB ; Jump if not

	inc	ecx		; Count in byte
GETILEN_XB:

; Check for immediate word

	test	dl,$W		; Check it
	jz	short GETILEN_XW ; Jump if not

	add	ecx,2		; Count in word
GETILEN_XW:

; Check for immediate word (OSP=0) or dword (OSP=1)

	test	dl,$V		; Check it
	jz	short GETILEN_XV ; Jump if not

	add	ecx,2		; Count in word

	test	dl,$OSP 	; Check for OSP
	jz	short GETILEN_XV ; Jump if OSP=0

	add	ecx,2		; Count in extra word
GETILEN_XV:
	test	dl,$M		; Izit present?
	jz	short GETILEN_EXIT ; Jump if not

	lods	ds:[esi].LO	; Get next instruction byte (mod R/M)
	inc	ecx		; Count it in
	mov	ah,al		; Save for later use

;;;;;;; mov	al,ah		; Copy for destructive test
	and	al,mask $MOD	; Isolate the MOD bits

	test	dl,$ASP 	; Check for Address Size Prefix
	jnz	short GETILEN_ASP ; Jump if so

	cmp	al,11b shl $MOD ; Check for MOD=11 (register operand)
	je	short GETILEN_EXIT ; Jump if that's all

	cmp	al,10b shl $MOD ; Check for MOD=10 (DISP16)
	je	short GETILEN_D16 ; Jump if so

	cmp	al,01b shl $MOD ; Check for MOD=01 (DISP8)
	je	short GETILEN_D8 ; Jump if so

	mov	al,ah		; Copy for destructive test
	and	al,mask $RM	; Isolate the RM bits

	cmp	al,110b shl $RM ; Check for special DISP16
	jne	short GETILEN_EXIT ; Not this time
GETILEN_D16:
	inc	ecx		; Count in another byte
	inc	esi		; Skip past the instruction byte
GETILEN_D8:
	inc	ecx		; Count in another byte
	inc	esi		; Skip past the instruction byte

	jmp	short GETILEN_EXIT ; Join common code


; There's an Address Size Prefix, hence maybe an SIB byte

GETILEN_ASP:
	mov	al,ah		; Copy for destructive test
	and	al,mask $MOD	; Isolate the MOD bits

	cmp	al,11b shl $MOD ; Check for MOD=11 (register operand)
	je	short GETILEN_EXIT ; Jump if that's all

	mov	dh,ah		; Copy for destructive test
	and	dh,mask $RM	; Isolate the RM bits

	cmp	dh,100b shl $RM ; Check for special SIB byte
	jne	short @F	; Not this time

	inc	ecx		; Count in another byte
	inc	esi		; Skip past the instruction byte
@@:
	cmp	al,10b shl $MOD ; Check for MOD=10 (DISP32)
	je	short GETILEN_D32 ; Jump if so

	cmp	al,01b shl $MOD ; Check for MOD=01 (DISP8)
	je	short GETILEN_D8 ; Jump if so

	mov	al,ah		; Copy for destructive test
	and	al,mask $RM	; Isolate the RM bits

	cmp	al,101b shl $RM ; Check for special DISP32
	jne	short GETILEN_EXIT ; Not this time
GETILEN_D32:
	add	ecx,4		; Count in another dword
	add	esi,4		; Skip past the DISP32
GETILEN_EXIT:
	mov	eax,ecx 	; Copy to return register

	pop	esi		; Restore original offset

	add	esi,eax 	; Skip to next instruction byte

	REGREST <edx,ecx,ebx>	; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETILEN endp			; End GETILEN procedure
	NPPROC  INST_OPR0E -- Install Local INT 0Eh Handler
	assume  ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Install local INT 0Eh handler.

Error code is on the stack.

|

	REGSAVE <eax,ebx>	; Save registers

	cmp	OPR_I0ECNT,0	; Izit already installed?
	jne	short INST_OPR0E_EXIT ; Jump if so

	sub	esp,size DTR_STR ; Make room for IDTR
	SIDTD	[esp].EDF	; Store on stack
	mov	ebx,[esp].DTR_BASE ; Get base address of IDT
	add	esp,size DTR_STR ; Remove IDTR from stack

	mov	ax,cs		; Get our selector
	xchg	ax,AGROUP:[ebx+0Eh*(size IDT_STR)].IDT_SELECT ; Swap 'em
	mov	OPRINT0E_FVEC.FSEL,ax ; Save to restore later

	lea	eax,OPR_INT0E	; Get our 32-bit offset
	xchg	ax,AGROUP:[ebx+0Eh*(size IDT_STR)].IDT_OFFLO ; Swap 'em
	mov	OPRINT0E_FVEC.FOFF.ELO,ax ; Save to restore later

	shr	eax,16  	; Shift down the high-order word
	xchg	ax,AGROUP:[ebx+0Eh*(size IDT_STR)].IDT_OFFHI ; Swap 'em
	mov	OPRINT0E_FVEC.FOFF.EHI,ax ; Save to restore later

	mov	al,CPL0_INTR3 or CPL3 ; Get our access rights byte
	xchg	al,AGROUP:[ebx+0Eh*(size IDT_STR)].IDT_ACCESS ; Swap 'em
	mov	OPRINT0E_ARB,al ; Save to restore later

	mov	eax,cr2 	; Get previous Page fault linear address
	mov	OPRINT0E_CR2,eax ; Save to restore later
INST_OPR0E_EXIT:
	inc	OPR_I0ECNT	; Mark as installed again

	REGREST <ebx,eax>	; Restore

	ret			; Return to caller


	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST_OPR0E endp 		; End INST_OPR0E procedure
	NPPROC  REST_OPR0E -- Restore Global INT 0Eh Handler
	assume  ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Restore global INT 0Eh handler

|

	REGSAVE <eax,ebx>	; Save registers

	dec	OPR_I0ECNT	; Mark as uninstalled again
	jnz	short REST_OPR0E_EXIT ; Jump if not bottomed out as yet

	sub	esp,size DTR_STR ; Make room for IDTR
	SIDTD	[esp].EDF	; Store on stack
	mov	ebx,[esp].DTR_BASE ; Get base address of IDT
	add	esp,size DTR_STR ; Remove IDTR from stack

	mov	ax,OPRINT0E_FVEC.FSEL ; Get original selector
	mov	AGROUP:[ebx+0Eh*(size IDT_STR)].IDT_SELECT,ax ; Save it back

	mov	eax,OPRINT0E_FVEC.FOFF ; Get original offset
	mov	AGROUP:[ebx+0Eh*(size IDT_STR)].IDT_OFFLO,ax ; Save it back

	shr	eax,16  	; Shift down the high-order word
	mov	AGROUP:[ebx+0Eh*(size IDT_STR)].IDT_OFFHI,ax ; Save it back

	mov	al,OPRINT0E_ARB ; Get original access rights byte
	mov	AGROUP:[ebx+0Eh*(size IDT_STR)].IDT_ACCESS,al ; Save it back

	mov	eax,OPRINT0E_CR2 ; Get original Page Fault linear address
	mov	cr2,eax 	; Restore
REST_OPR0E_EXIT:
	REGREST <ebx,eax>	; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_OPR0E endp 		; End REST_OPR0E procedure
	NPPROC  CHECK_PMTSS -- Check on PM TSS Task Switch
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Check on PM TSS task switch

We're tracing an instruction.  If it's a far JMP/CALL to a TSS
or task gate, we must recognize that and handle it differently.

The various opcodes which can generate a task switch include

EA oooo ssss		far jump immediate
9A oooo ssss		far call immediate
66 EA oooooooo ssss	far jump dword immediate
66 9A oooooooo ssss	far call dword immediate
FF /5 m16:16		grp5 jump
FF /3 m16:16		grp5 call
66 FF /5 m16:32 	grp5 dword jump
66 FF /3 m16:32 	grp5 dword call

Actually, the word/dword interpretation depends upon the D-bit
in the corresponding code selector and the presence/absence of
the Operand Size Prefix.

On entry:

SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if TSS task switch
	=	1 if not
EBX	=	TSS selector if so

|

	REGSAVE <eax,esi,edi>	; Save registers

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	jnz	near ptr CHECK_PMTSS_NONE ; Jump if so

	mov	esi,CUR_INSTR ; Get linear address of cur instr
	mov	eax,AGROUP:[esi] ; Get the next four instruction bytes

; Save current instruction A/R byte to detect 16-bit vs. 32-bit instructions

	mov	bl,CUR_INSTR_ARW.HI ; Save it

; Check for far JMP/CALL immediates

	cmp	ax,@OPCOD_JMPFD ; Izit a dword jump immediate?
	je	short CHECK_PMTSS_IMMED1 ; Jump if so

	cmp	al,@OPCOD_JMPF  ; Izit a far jump immediate?
	je	short CHECK_PMTSS_IMMED2 ; Jump if so

	cmp	ax,@OPCOD_CALLFD ; Izit a dword call immeidate?
	je	short CHECK_PMTSS_IMMED1 ; Jump if so

	cmp	al,@OPCOD_CALLF ; Izit a far call immediate?
	je	short CHECK_PMTSS_IMMED2 ; Jump if so

; Check for GRP5 indirect JMP/CALL

	cmp	al,@OPCOD_GRP5  ; Izit a GRP5 instruction?
	je	short @F	; Jump if so

	cmp	ax,@OPCOD_GRP5D ; Izit a GRP5 dword instruction?
	jne	near ptr CHECK_PMTSS_NONE ; Jump if not

	shr	eax,8		; Shift out OSP byte
	xor	bl,mask $DTE_B  ; Toggle default action
@@:

; The MOD R/M byte is in AH, the GRP5 byte is in AL

	and	ah,mask $REG	; Isolate the secondary opcode bits

	cmp	ah,101b shl $REG ; Check for JMP M16:16 or JMP M16:32
	je	short @F	; Jump if so

	cmp	ah,011b shl $REG ; Check for CALL M16:16 or CALL M16:32
	jne	short CHECK_PMTSS_NONE ; Jump if not
@@:

COMMENT|

We've encountered a far JMP/CALL M16:16 or M16:32.  Compute
the effective address of the argument and check the contents
to which it points.

We're assuming that OPERAND has already been filled in.

|

	or	OPR_FLAG,@OPR_EA ; Mark as EA computation only

	mov	edi,OPER1_DATA  ; Initialize index
	call	DISP_REF	; Return with ESI = 32-bit linear address

	and	OPR_FLAG,not @OPR_EA ; Clear it

	jmp	short CHECK_PMTSS_COM ; Join common code

CHECK_PMTSS_IMMED1:
	inc	esi		; Skip over OSP byte
	xor	bl,mask $DTE_B  ; Toggle default action
CHECK_PMTSS_IMMED2:
	inc	esi		; Skip over opcode byte

COMMENT!

Check for an idle 386 TSS selector or task gate
as they cause a task switch.

If it's a 16-bit immediate or M16:16, the data at GS|ESI look like

dw	 offset
dw	 selector

If it's a 32-bit immediate or M16:32, the data at GS|ESI look like

dd	 offset
dw	 selector

BL	=	A/R byte (with $DTE_B significant)

!

CHECK_PMTSS_COM:
	test	bl,mask $DTE_B  ; Check for D-bit
	jz	short @F	; Jump if it's 16-bits

	add	esi,2		; Skip over extra word in offset
@@:
	mov	ax,AGROUP:[esi+2] ; Get the selector, skipping over offset
	movzx	ebx,ax  	; Save for later use
	and	ax,not (mask $PL) ; Clear PL bits

	push	ax		; Pass selector as argument
	call	GETARW  	; Return with AX = access rights word

	test	al,mask $DT_DC  ; Izit code/data?
	jnz	short CHECK_PMTSS_NONE ; Jump if so (not TSS)

	test	al,mask $DT_P	; Izit present?
	jz	short CHECK_PMTSS_NONE ; Jump if not (who cares?)

	and	al,not (mask $DT_DPL) ; Clear DPL bits

	test	bx,mask $TI	; Izit in the LDT?
	jnz	short @F	; Jump if so (can't be a TSS)

	cmp	al,CPL0_IDLE3	; Izit an idle 386 TSS?
	je	short CHECK_PMTSS_CLC ; Jump if so with BX = TSS selector
@@:
	cmp	al,CPL0_TASK	; Izit a task gate?
	jne	short CHECK_PMTSS_NONE ; Jump if not

; BX has the task gate selector.  The DTE for this selector has the
; corresponding TSS selector in the segment base 0-15 field.  By
; calling GETBASE and ignoring the high-order word of the result,
; we can obtain this value.

	push	bx		; Pass task gate selector as argument
	call	GETBASE 	; Return with EAX = selector base

	movzx	ebx,ax  	; Copy to return register
CHECK_PMTSS_CLC:
	clc			; Indicate we found it

	jmp	short CHECK_PMTSS_EXIT ; Join common exit code

CHECK_PMTSS_NONE:
	stc			; Mark as not found
CHECK_PMTSS_EXIT:
	REGREST <edi,esi,eax>	; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PMTSS endp		; End CHECK_PMTSS procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_OPR module
