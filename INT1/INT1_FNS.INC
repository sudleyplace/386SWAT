;' $Header:   P:/PVCS/386SWAT/INT1/INT1_FNS.INV   1.6   20 Sep 1994 16:58:48   BOB  $
;
; (C) Copyright 1987-94 Qualitas, Inc.	All rights reserved.
;
; INT1_FNS.INC
;
; Structures and equates for 386SWAT's INT 01h handler
;

ID_STR	 struc

ID_PDEF  dw	 ?		; Default instruction prefixes (see below)
ID_PRES  dw	 ?		; Present instruction prefixes (see below)
ID_FLAG  dw	 ?		; Local flags (see below)
ID_MODRM db	 ?		; Instruction MOD/RM byte
ID_NCOMP db	 ?		; # components displayed so far (excluding opcode)
ID_IINS  dd	 ?		; Offset in FS of initial instruction byte
ID_CINS  dd	 ?		; Offset in FS of current instruction byte
ID_BASE  dd	 ?		; Offset in FS for JMP and CALL
ID_IOUT  dd	 ?		; Offset in ES of initial output stream

ID_STR	 ends

ID_FORW_STR struc

	 db	 (type ID_STR) dup (?)
ID_FORW_EBP dd	?		; Offset of old EBP ==> FORW_STR

ID_FORW_STR ends

; Equates for ID_PDEF and ID_PRES

@PREF_REPE  equ  8000h		; REPE
@PREF_REPNE equ  4000h		; REPNE
@PREF_LOCK  equ  2000h		; LOCK
@PREF_OSP   equ  1000h		; OSP
@PREF_ASP   equ  0800h		; ASP
@PREF_WAIT  equ  0400h		; WAIT
@PREF_OSP2  equ  0200h		; Secondary OSP used with GRP6-7

@PREF_GS    equ  0020h		; GS	The segment overrides *MUST* be last
@PREF_FS    equ  0010h		; FS	and in this order
@PREF_DS    equ  0008h		; DS
@PREF_SS    equ  0004h		; SS
@PREF_CS    equ  0002h		; CS
@PREF_ES    equ  0001h		; ES
@PREF_SREG  equ  @PREF_CS or @PREF_DS or @PREF_ES or @PREF_FS or @PREF_GS or @PREF_SS

; Equates for ID_FLAG

@FLAG_MODRM equ  8000h		; MOD/RM byte saved
@FLAG_OSP   equ  4000h		; OSP used
@FLAG_ASP   equ  2000h		; ASP used
@FLAG_SREG  equ  1000h		; Segment register override used
@FLAG_REP   equ  0800h		; Repeat prefix used
@FLAG_LOCK  equ  0400h		; Lock prefix used
@FLAG_WAIT  equ  0200h		; Wait prefix used
@FLAG_FILL  equ  0100h		; Opcode filled out
@FLAG_PTR   equ  0080h		; Ptr filled in
@FLAG_OPER  equ  0040h		; Operand analysis in effect
@FLAG_USE32 equ  0020h		; Code segment is USE32
@FLAG_PM    equ  0010h		; Protected mode disassembly

@FILL_OPCODE equ 8		; Opcode fill amount
@FILL_COMMENT equ 35		; Comment offset


; Instruction operand data structure

OPER_STR struc

; Operand #1 data

OPER1_FLAG  dw	 ?		; Flags
OPER1_CC    db	 ?		; Condition code
OPER1_SEG   db	 ?		; Segment
OPER1_MODRM db	 ?		; Mod R/M
OPER1_SIB   db	 ?		; SIB
OPER1_DWID  dd	 ?		; Data width (see @DWIDTH_ flags below)
OPER1_DISP  dd	 ?		; Displacement
OPER1_IMM   dd	 ?		; Immediate value

; Operand #2 data

OPER2_FLAG  dw	 ?		; Flags
OPER2_CC    db	 ?		; Condition code
OPER2_SEG   db	 ?		; Segment
OPER2_MODRM db	 ?		; Mod R/M
OPER2_SIB   db	 ?		; SIB
OPER2_DWID  dd	 ?		; Data width (see @DWIDTH_ flags below)
OPER2_DISP  dd	 ?		; Displacement
OPER2_IMM   dd	 ?		; Immediate value

OPER_STR ends

OPER1_DATA equ	 OPER1_FLAG	; Equates for operand data area
OPER2_DATA equ	 OPER2_FLAG


; Flags for OPERx_FLAG

@OPER_JCC equ	 8000h		; Instruction is a Jcc
@OPER_MEM equ	 4000h		; Operand references memory
@OPER_MRM equ	 2000h		; Operand has Mod R/M
@OPER_SIB equ	 1000h		; Operand has SIB
@OPER_RD  equ	 0800h		; Operand is read
@OPER_WR  equ	 0400h		; Operand is written
@OPER_OSP equ	 0200h		; Operand size prefix is present
@OPER_ASP equ	 0100h		; Address ...
@OPER_DSP equ	 0080h		; Displacement present
@OPER_SEG equ	 0040h		; Segment register override present
@OPER_DWID equ	 0020h		; Data width specified
@OPER_STK equ	 0010h		; Implicit stack reference
@OPER_JCC_BACK equ 0008h	; Jcc is jumping backwards


; Data width flags
; The table DWIDTAB in SWAT_OPR.ASM is order-dependent
; upon the following equates

@DWIDTH_BYTE   equ 00000001h	; Byte				     00    1
@DWIDTH_WORD   equ 00000002h	; Word				   1100    2
@DWIDTH_DWORD  equ 00000004h	; Dword 		       33221100    4
@DWIDTH_QWORD  equ 00000008h	; Qword 	       7766554433221100    8
@DWIDTH_TBYTE  equ 00000010h	; Tbyte 	   99887766554433221100   10
@DWIDTH_PTR16  equ 00000020h	; PTR16:16		      3322:1100    4
@DWIDTH_PTR32  equ 00000040h	; PTR16:32		  5544:33221100    6
@DWIDTH_PTR16F equ 00000080h	; PTR16:16 FL		 3322:1100 5544    6
@DWIDTH_PTR32F equ 00000100h	; PTR16:32 EFL	 5544:33221100 BBAA9988   12
@DWIDTH_DTR    equ 00000200h	; DTR			  1100 55443322    6
@DWIDTH_BNDW   equ 00000400h	; BOUND word		      1100 3322    4
@DWIDTH_BNDD   equ 00000800h	; BOUND Dword	      33221100 77665544    8
@DWIDTH_WORD2  equ 00001000h	; Two words		      1100 3322    4
@DWIDTH_WORD3  equ 00002000h	; Three words		 1100 3322 5544    6
@DWIDTH_WORD4  equ 00004000h	; Four words	    1100 3322 5544 7766    8
@DWIDTH_DWORD2 equ 00008000h	; Two dwords	      33221100 77665544    8
@DWIDTH_DWORD3 equ 00010000h	; Three dwords	      33221100 77665544...12
@DWIDTH_POPA   equ 00020000h	; Eight words	    1100 3322 5544 7766...16
@DWIDTH_POPAD  equ 00040000h	; Eight dwords	      33221100 77665544...32
@DWIDTH_BTREG  equ 00080000h	; Byte with BT disp register	     00    1
@DWIDTH_BTIMM  equ 00100000h	; Byte with BT disp immediate	     00    1
@DWIDTH_INT    equ 00200000h	; Two words		      3322:1100    4
@DWIDTH_POPW   equ 00400000h	; Word				   1100    2
@DWIDTH_POPD   equ 00800000h	; Dword 		       33221100    4
@DWIDTH_XLAT   equ 01000000h	; Byte				     00    1


; Segment register numberings

@SEG_ES  equ	 000b		; ES
@SEG_CS  equ	 001b		; CS
@SEG_SS  equ	 010b		; SS
@SEG_DS  equ	 011b		; DS
@SEG_FS  equ	 100b		; FS
@SEG_GS  equ	 101b		; GS


