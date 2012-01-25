;' $Header:   P:/PVCS/386SWAT/INT1/INT1_FOP.ASV   1.5   01 Jul 1997 17:55:56   BOB  $
	 title	 INT1_FOP -- INT 01h Floating Point Operation Functions
	 page	 58,122
	 name	 INT1_FOP

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-2001 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, April, 1988.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include BITFLAGS.INC
	 include IOPBITS.INC

	 include INT1_FNS.INC
	 include SWAT_SEG.INC
.list

FREG4_STR struc

OPC	 dd	 ?		; Offset of opcode text
ARG	 dd	 ?		; ...	    argument

FREG4_STR ends


TEXT	 segment use32 byte public 'data' ; Start TEXT segment
	 assume  ds:DGROUP

	 extrn	 TXT_UNK:byte
	 extrn	 TXT_AX:byte

	 extrn	 MSG_BPTR:byte
	 extrn	 MSG_WPTR:byte
	 extrn	 MSG_DPTR:byte
	 extrn	 MSG_QPTR:byte
	 extrn	 MSG_TPTR:byte
	 extrn	 MSG_14PTR:byte
	 extrn	 MSG_28PTR:byte
	 extrn	 MSG_94PTR:byte
	 extrn	 MSG_108PTR:byte

	 extrn	 TXT_2XM1:byte

	 extrn	 TXT_ABS:byte
	 extrn	 TXT_ADD:byte
	 extrn	 TXT_ADDP:byte

	 extrn	 TXT_BLD:byte
	 extrn	 TXT_BSTP:byte

	 extrn	 TXT_CHS:byte
	 extrn	 TXT_CLEX:byte
	 extrn	 TXT_CMOVB:byte
	 extrn	 TXT_CMOVBE:byte
	 extrn	 TXT_CMOVE:byte
	 extrn	 TXT_CMOVNB:byte
	 extrn	 TXT_CMOVNBE:byte
	 extrn	 TXT_CMOVNE:byte
	 extrn	 TXT_CMOVNU:byte
	 extrn	 TXT_CMOVU:byte
	 extrn	 TXT_COM:byte
	 extrn	 TXT_COMI:byte
	 extrn	 TXT_COMIP:byte
	 extrn	 TXT_COMP:byte
	 extrn	 TXT_COMPP:byte
	 extrn	 TXT_COS:byte

	 extrn	 TXT_DECSTP:byte
	 extrn	 TXT_DISI:byte
	 extrn	 TXT_DIV:byte
	 extrn	 TXT_DIVP:byte
	 extrn	 TXT_DIVR:byte
	 extrn	 TXT_DIVRP:byte

	 extrn	 TXT_ENI:byte

	 extrn	 TXT_FREE:byte

	 extrn	 TXT_IADD:byte
	 extrn	 TXT_ICOM:byte
	 extrn	 TXT_ICOMP:byte
	 extrn	 TXT_IDIV:byte
	 extrn	 TXT_IDIVR:byte
	 extrn	 TXT_ILD:byte
	 extrn	 TXT_IMUL:byte
	 extrn	 TXT_INCSTP:byte
	 extrn	 TXT_INIT:byte
	 extrn	 TXT_IST:byte
	 extrn	 TXT_ISTP:byte
	 extrn	 TXT_ISUB:byte
	 extrn	 TXT_ISUBR:byte

	 extrn	 TXT_LD:byte
	 extrn	 TXT_LD1:byte
	 extrn	 TXT_LDCW:byte
	 extrn	 TXT_LDENV:byte
	 extrn	 TXT_LDL2E:byte
	 extrn	 TXT_LDL2T:byte
	 extrn	 TXT_LDLG2:byte
	 extrn	 TXT_LDLN2:byte
	 extrn	 TXT_LDPI:byte
	 extrn	 TXT_LDZ:byte

	 extrn	 TXT_MUL:byte
	 extrn	 TXT_MULP:byte

	 extrn	 TXT_NOP:byte

	 extrn	 TXT_PATAN:byte
	 extrn	 TXT_PREM:byte
	 extrn	 TXT_PREM1:byte
	 extrn	 TXT_PTAN:byte

	 extrn	 TXT_RNDINT:byte
	 extrn	 TXT_RSTOR:byte

	 extrn	 TXT_SAVE:byte
	 extrn	 TXT_SCALE:byte
	 extrn	 TXT_SETPM:byte
	 extrn	 TXT_SIN:byte
	 extrn	 TXT_SINCOS:byte
	 extrn	 TXT_SQRT:byte
	 extrn	 TXT_ST:byte
	 extrn	 TXT_STCW:byte
	 extrn	 TXT_STENV:byte
	 extrn	 TXT_STP:byte
	 extrn	 TXT_STSW:byte
	 extrn	 TXT_SUB:byte
	 extrn	 TXT_SUBP:byte
	 extrn	 TXT_SUBR:byte
	 extrn	 TXT_SUBRP:byte

	 extrn	 TXT_TST:byte

	 extrn	 TXT_UCOM:byte
	 extrn	 TXT_UCOMI:byte
	 extrn	 TXT_UCOMIP:byte
	 extrn	 TXT_UCOMP:byte
	 extrn	 TXT_UCOMPP:byte

	 extrn	 TXT_XAM:byte
	 extrn	 TXT_XCH:byte
	 extrn	 TXT_XTRACT:byte

	 extrn	 TXT_YL2X:byte
	 extrn	 TXT_YL2XP1:byte

	 extrn	 FSTn:byte
	 extrn	 FST@STn:byte
	 extrn	 FSTn@ST:byte

	 public  FREG0_TAB
FREG0_TAB dd	 offset DGROUP:TXT_ADD ,offset DGROUP:FST@STn ; 000
	 dd	 offset DGROUP:TXT_MUL ,offset DGROUP:FST@STn ; 001
	 dd	 offset DGROUP:TXT_COM ,offset DGROUP:FSTn    ; 010
	 dd	 offset DGROUP:TXT_COMP,offset DGROUP:FSTn    ; 011
	 dd	 offset DGROUP:TXT_SUB ,offset DGROUP:FST@STn ; 100
	 dd	 offset DGROUP:TXT_SUBR,offset DGROUP:FST@STn ; 101
	 dd	 offset DGROUP:TXT_DIV ,offset DGROUP:FST@STn ; 110
	 dd	 offset DGROUP:TXT_DIVR,offset DGROUP:FST@STn ; 111

	 public  FMOD0
FMOD0	 dd	 offset DGROUP:TXT_ADD	       ; 000
	 dd	 offset DGROUP:TXT_MUL	       ; 001
	 dd	 offset DGROUP:TXT_COM	       ; 010
	 dd	 offset DGROUP:TXT_COMP        ; 011
	 dd	 offset DGROUP:TXT_SUB	       ; 100
	 dd	 offset DGROUP:TXT_SUBR        ; 101
	 dd	 offset DGROUP:TXT_DIV	       ; 110
	 dd	 offset DGROUP:TXT_DIVR        ; 111

	 public  FTYP0
FTYP0	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_DPTR

	 public  FREG1_TAB
FREG1_TAB dd	 offset DGROUP:TXT_LD	       ; 000rrr
	 dd	 offset DGROUP:TXT_XCH	       ; 001rrr
	 dd	 offset DGROUP:TXT_NOP	       ; 010000
	 dd	 offset DGROUP:TXT_UNK	       ; 010xxx
	 dd	 offset DGROUP:TXT_STP	       ; 011rrr
	 dd	 offset DGROUP:TXT_CHS	       ; 100000
	 dd	 offset DGROUP:TXT_ABS	       ; 100001
	 dd	 offset DGROUP:TXT_UNK	       ; 100010
	 dd	 offset DGROUP:TXT_UNK	       ; 100011
	 dd	 offset DGROUP:TXT_TST	       ; 100100
	 dd	 offset DGROUP:TXT_XAM	       ; 100101
	 dd	 offset DGROUP:TXT_UNK	       ; 100110
	 dd	 offset DGROUP:TXT_UNK	       ; 100111
	 dd	 offset DGROUP:TXT_LD1	       ; 101000
	 dd	 offset DGROUP:TXT_LDL2T       ; 101001
	 dd	 offset DGROUP:TXT_LDL2E       ; 101010
	 dd	 offset DGROUP:TXT_LDPI        ; 101011
	 dd	 offset DGROUP:TXT_LDLG2       ; 101100
	 dd	 offset DGROUP:TXT_LDLN2       ; 101101
	 dd	 offset DGROUP:TXT_LDZ	       ; 101110
	 dd	 offset DGROUP:TXT_UNK	       ; 101111
	 dd	 offset DGROUP:TXT_2XM1        ; 110000
	 dd	 offset DGROUP:TXT_YL2X        ; 110001
	 dd	 offset DGROUP:TXT_PTAN        ; 110010
	 dd	 offset DGROUP:TXT_PATAN       ; 110011
	 dd	 offset DGROUP:TXT_XTRACT      ; 110100
	 dd	 offset DGROUP:TXT_PREM1       ; 110101
	 dd	 offset DGROUP:TXT_DECSTP      ; 110110
	 dd	 offset DGROUP:TXT_INCSTP      ; 110111
	 dd	 offset DGROUP:TXT_PREM        ; 111000
	 dd	 offset DGROUP:TXT_YL2XP1      ; 111001
	 dd	 offset DGROUP:TXT_SQRT        ; 111010
	 dd	 offset DGROUP:TXT_SINCOS      ; 111011
	 dd	 offset DGROUP:TXT_RNDINT      ; 111100
	 dd	 offset DGROUP:TXT_SCALE       ; 111101
	 dd	 offset DGROUP:TXT_SIN	       ; 111110
	 dd	 offset DGROUP:TXT_COS	       ; 111111

FREG1_ARG   equ  FSTn

	 public  FMOD1
FMOD1	 dd	 offset DGROUP:TXT_LD	       ; 000
	 dd	 offset DGROUP:TXT_UNK	       ; 001
	 dd	 offset DGROUP:TXT_ST	       ; 010
	 dd	 offset DGROUP:TXT_STP	       ; 011
	 dd	 offset DGROUP:TXT_LDENV       ; 100
	 dd	 offset DGROUP:TXT_LDCW        ; 101
	 dd	 offset DGROUP:TXT_STENV       ; 110
	 dd	 offset DGROUP:TXT_STCW        ; 111

	 public  FTYP1
FTYP1	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_BPTR
	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_14PTR
	 dd	 offset DGROUP:MSG_WPTR
	 dd	 offset DGROUP:MSG_14PTR
	 dd	 offset DGROUP:MSG_WPTR

	public	FREG2_TAB
FREG2_TAB dd	offset DGROUP:TXT_UNK		; 0
	dd	offset DGROUP:TXT_UCOMPP	; 1

	public	FCMOV_TAB1
FCMOV_TAB1 label dword
	dd	offset DGROUP:TXT_CMOVB 	; 000
	dd	offset DGROUP:TXT_CMOVE 	; 001
	dd	offset DGROUP:TXT_CMOVBE	; 010
	dd	offset DGROUP:TXT_CMOVU 	; 011

	public	FCMOV_TAB2
FCMOV_TAB2 label dword
	dd	offset DGROUP:TXT_CMOVNB	; 000
	dd	offset DGROUP:TXT_CMOVNE	; 001
	dd	offset DGROUP:TXT_CMOVNBE	; 010
	dd	offset DGROUP:TXT_CMOVNU	; 011

FCMOV_ARG equ	FST@STn

	 public  FMOD2
FMOD2	 dd	 offset DGROUP:TXT_IADD        ; 000
	 dd	 offset DGROUP:TXT_IMUL        ; 001
	 dd	 offset DGROUP:TXT_ICOM        ; 010
	 dd	 offset DGROUP:TXT_ICOMP       ; 011
	 dd	 offset DGROUP:TXT_ISUB        ; 100
	 dd	 offset DGROUP:TXT_ISUBR       ; 101
	 dd	 offset DGROUP:TXT_IDIV        ; 110
	 dd	 offset DGROUP:TXT_IDIVR       ; 111

	 public  FTYP2
FTYP2	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_DPTR

	 public  FREG3_TAB
FREG3_TAB dd	 offset DGROUP:TXT_UNK	       ; 0
	 dd	 offset DGROUP:TXT_ENI	       ; 1
	 dd	 offset DGROUP:TXT_DISI        ; 2
	 dd	 offset DGROUP:TXT_CLEX        ; 3
	 dd	 offset DGROUP:TXT_INIT        ; 4
	 dd	 offset DGROUP:TXT_SETPM       ; 5

	public	FCOMI_TAB
FCOMI_TAB label dword
	dd	offset DGROUP:TXT_UCOMI 	; 101
	dd	offset DGROUP:TXT_COMI		; 110

FCOMI_ARG equ	FST@STn

	 public  FMOD3
FMOD3	 dd	 offset DGROUP:TXT_ILD	       ; 000
	 dd	 offset DGROUP:TXT_UNK	       ; 001
	 dd	 offset DGROUP:TXT_IST	       ; 010
	 dd	 offset DGROUP:TXT_ISTP        ; 011
	 dd	 offset DGROUP:TXT_UNK	       ; 100
	 dd	 offset DGROUP:TXT_LD	       ; 101
	 dd	 offset DGROUP:TXT_UNK	       ; 110
	 dd	 offset DGROUP:TXT_STP	       ; 111

	 public  FTYP3
FTYP3	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_BPTR
	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_DPTR
	 dd	 offset DGROUP:MSG_BPTR
	 dd	 offset DGROUP:MSG_TPTR
	 dd	 offset DGROUP:MSG_BPTR
	 dd	 offset DGROUP:MSG_TPTR

	 public  FREG4_TAB
FREG4_TAB dd	 offset DGROUP:TXT_ADD	       ; 000
	 dd	 offset DGROUP:TXT_MUL	       ; 001
	 dd	 offset DGROUP:TXT_UNK	       ; 010
	 dd	 offset DGROUP:TXT_UNK	       ; 011
	 dd	 offset DGROUP:TXT_SUBR        ; 100
	 dd	 offset DGROUP:TXT_SUB	       ; 101
	 dd	 offset DGROUP:TXT_DIVR        ; 110
	 dd	 offset DGROUP:TXT_DIV	       ; 111

FREG4_ARG equ	 FSTn@ST

	 public  FMOD4
FMOD4	 dd	 offset DGROUP:TXT_ADD	       ; 000
	 dd	 offset DGROUP:TXT_MUL	       ; 001
	 dd	 offset DGROUP:TXT_COM	       ; 010
	 dd	 offset DGROUP:TXT_COMP        ; 011
	 dd	 offset DGROUP:TXT_SUB	       ; 100
	 dd	 offset DGROUP:TXT_SUBR        ; 101
	 dd	 offset DGROUP:TXT_DIV	       ; 110
	 dd	 offset DGROUP:TXT_DIVR        ; 111

	 public  FTYP4
FTYP4	 dd	 offset DGROUP:MSG_QPTR
	 dd	 offset DGROUP:MSG_QPTR
	 dd	 offset DGROUP:MSG_QPTR
	 dd	 offset DGROUP:MSG_QPTR
	 dd	 offset DGROUP:MSG_QPTR
	 dd	 offset DGROUP:MSG_QPTR
	 dd	 offset DGROUP:MSG_QPTR
	 dd	 offset DGROUP:MSG_QPTR

	 public  FREG5_TAB
FREG5_TAB dd	 offset DGROUP:TXT_FREE        ; 000
	 dd	 offset DGROUP:TXT_UNK	       ; 001
	 dd	 offset DGROUP:TXT_ST	       ; 010
	 dd	 offset DGROUP:TXT_STP	       ; 011
	 dd	 offset DGROUP:TXT_UCOM        ; 100
	 dd	 offset DGROUP:TXT_UCOMP       ; 101
	 dd	 offset DGROUP:TXT_UNK	       ; 110
	 dd	 offset DGROUP:TXT_UNK	       ; 111

FREG5_ARG equ	 FSTn

	 public  FMOD5
FMOD5	 dd	 offset DGROUP:TXT_LD	       ; 000
	 dd	 offset DGROUP:TXT_UNK	       ; 001
	 dd	 offset DGROUP:TXT_ST	       ; 010
	 dd	 offset DGROUP:TXT_STP	       ; 011
	 dd	 offset DGROUP:TXT_RSTOR       ; 100
	 dd	 offset DGROUP:TXT_UNK	       ; 101
	 dd	 offset DGROUP:TXT_SAVE        ; 110
	 dd	 offset DGROUP:TXT_STSW        ; 111

	 public  FTYP5
FTYP5	 dd	 offset DGROUP:MSG_QPTR
	 dd	 offset DGROUP:MSG_BPTR
	 dd	 offset DGROUP:MSG_QPTR
	 dd	 offset DGROUP:MSG_QPTR
	 dd	 offset DGROUP:MSG_94PTR
	 dd	 offset DGROUP:MSG_BPTR
	 dd	 offset DGROUP:MSG_94PTR
	 dd	 offset DGROUP:MSG_WPTR

	 public  FREG6_TAB
FREG6_TAB dd	 offset DGROUP:TXT_ADDP        ; 000
	 dd	 offset DGROUP:TXT_MULP        ; 001
	 dd	 offset DGROUP:TXT_UNK	       ; 010
	 dd	 offset DGROUP:TXT_COMPP       ; 011
	 dd	 offset DGROUP:TXT_SUBRP       ; 100
	 dd	 offset DGROUP:TXT_SUBP        ; 101
	 dd	 offset DGROUP:TXT_DIVRP       ; 110
	 dd	 offset DGROUP:TXT_DIVP        ; 111

FREG6_ARG equ	 FSTn@ST

	 public  FMOD6
FMOD6	 dd	 offset DGROUP:TXT_IADD        ; 000
	 dd	 offset DGROUP:TXT_IMUL        ; 001
	 dd	 offset DGROUP:TXT_ICOM        ; 010
	 dd	 offset DGROUP:TXT_ICOMP       ; 011
	 dd	 offset DGROUP:TXT_ISUB        ; 100
	 dd	 offset DGROUP:TXT_ISUBR       ; 101
	 dd	 offset DGROUP:TXT_IDIV        ; 110
	 dd	 offset DGROUP:TXT_IDIVR       ; 111

	 public  FTYP6
FTYP6	 dd	 offset DGROUP:MSG_WPTR
	 dd	 offset DGROUP:MSG_WPTR
	 dd	 offset DGROUP:MSG_WPTR
	 dd	 offset DGROUP:MSG_WPTR
	 dd	 offset DGROUP:MSG_WPTR
	 dd	 offset DGROUP:MSG_WPTR
	 dd	 offset DGROUP:MSG_WPTR
	 dd	 offset DGROUP:MSG_WPTR

FREG7_1  equ	 TXT_STSW

	public	FCOMIP_TAB
FCOMIP_TAB label dword
	dd	offset DGROUP:TXT_UCOMIP	; 101
	dd	offset DGROUP:TXT_COMIP 	; 110

FCOMIP_ARG equ	FST@STn

	 public  FMOD7
FMOD7	 dd	 offset DGROUP:TXT_ILD	       ; 000
	 dd	 offset DGROUP:TXT_UNK	       ; 001
	 dd	 offset DGROUP:TXT_IST	       ; 010
	 dd	 offset DGROUP:TXT_ISTP        ; 011
	 dd	 offset DGROUP:TXT_BLD	       ; 100
	 dd	 offset DGROUP:TXT_ILD	       ; 101
	 dd	 offset DGROUP:TXT_BSTP        ; 110
	 dd	 offset DGROUP:TXT_ISTP        ; 111

	 public  FTYP7
FTYP7	 dd	 offset DGROUP:MSG_WPTR
	 dd	 offset DGROUP:MSG_BPTR
	 dd	 offset DGROUP:MSG_WPTR
	 dd	 offset DGROUP:MSG_WPTR
	 dd	 offset DGROUP:MSG_TPTR
	 dd	 offset DGROUP:MSG_QPTR
	 dd	 offset DGROUP:MSG_TPTR
	 dd	 offset DGROUP:MSG_QPTR

TEXT	 ends			; End TEXT segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 extrn	 GET_MODRM:near
	 extrn	 COPY_ASCIIZ:near
	 extrn	 FILL_OPCODE:near
	 extrn	 DISP_SRO:near
	 extrn	 @UNDEF:near
	 extrn	 RM_ADDR:near
	 extrn	 @EXIT:near

	 NPPROC  @FLOP -- Display Floating Point Instructions
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display floating point instructions.

On entry:

DS:ESI	 ==>	 action stream
ES:EDI	 ==>	 output stream

On exit:

DS:ESI	 ==>	 action stream, updated
ES:EDI	 ==>	 output stream, updated
EAX	 =	 destroyed

|

	 call	 GET_MODRM	; Return MOD/RM byte in AL

	 cmp	 al,11000000b	; Check MOD bits
	 jb	 short @FLOP1	; Jump if MOD < 11

	 lods	 ds:[esi].EDD	; Get REG function offset

	 jmp	 eax		; Take appropriate action

@FLOP1:
	 add	 esi,4		; Strip off REG function offset

	 call	 FN_PREF	; Fill in FN prefix, return ECX = starting offset

	 push	 eax		; Save for a moment
	 lods	 ds:[esi].EDD	; Get the MOD table offset
	 mov	 ebx,eax	; Save for later use
	 pop	 eax		; Restore MOD R/M byte

	 push	 esi		; Save for a moment

	 movzx	 esi,al 	; Copy to index register
	 and	 esi,mask $REG	; Isolate register bits
	 shr	 esi,$REG	; Shift to low-order
	 mov	 esi,[ebx+esi*4].EDD ; DS:ESI ==> FLOP instruction name
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	 call	 FILL_OPCODE	; Fill out the opcode text from ECX

	 pop	 esi		; Restore

	 mov	 ebx,eax	; Save MOD R/M byte
	 lods	 ds:[esi].EDD	; Get TYP table offset
	 xchg	 eax,ebx	; Swap 'em

	 push	 esi		; Save for a moment

	 movzx	 esi,al 	; Copy MOD R/M byte to index register
	 and	 esi,mask $REG	; Isolate register bits
	 shr	 esi,$REG	; Shift to low-order
	 mov	 esi,[ebx+esi*4].EDD ; DS:ESI ==> pointer override

; If the pointer override is "14byte" and the OSP is present,
; use "28byte" instead

	 cmp	 esi,offset ds:MSG_14PTR ; Izit 14byte?
	 jne	 short @FLOP_X14 ; Not this time

	 test	 [ebp].ID_PDEF,@PREF_OSP ; Check on default behavior
	 jz	 short @FLOP_X14 ; Jump if 14-byte data

	 lea	 esi,MSG_28PTR	; Use 28byte form
	 or	 [ebp].ID_FLAG,@FLAG_OSP ; Mark as used
@FLOP_X14:

; If the pointer override is "94byte" and the OSP is present,
; use "108byte" instead

	 cmp	 esi,offset ds:MSG_94PTR ; Izit 94byte?
	 jne	 short @FLOP_X94 ; Not this time

	 test	 [ebp].ID_PDEF,@PREF_OSP ; Check on default behavior
	 jz	 short @FLOP_X94 ; Jump if not 108-byte data

	 lea	 esi,MSG_108PTR ; Use 108byte form
	 or	 [ebp].ID_FLAG,@FLAG_OSP ; Mark as used
@FLOP_X94:
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

	 test	 [ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	 jz	 short @FLOP_XOPER ; Not this time

	 cmp	 esi,offset ds:MSG_BPTR ; Izit a one-byte data reference?
	 jne	 short @F	; Not this time

	 or	 es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_DWID ; Mark it
	 or	 es:[edi].OPER1_DWID,@DWIDTH_BYTE

	 jmp	 short @FLOP_XOPER ; Join common code

@@:
	 cmp	 esi,offset ds:MSG_WPTR ; Izit a two-byte data reference?
	 jne	 short @F	; Not this time

	 or	 es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_DWID ; Mark it
	 or	 es:[edi].OPER1_DWID,@DWIDTH_WORD

	 jmp	 short @FLOP_XOPER ; Join common code

@@:

; The data reference is not one or two bytes:  call it four-bytes

	 or	 es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_DWID ; Mark it
	 or	 es:[edi].OPER1_DWID,@DWIDTH_DWORD
@FLOP_XOPER:
	 pop	 esi		; Restore

	 call	 DISP_SRO	; Display any segment register overrides
	 jc	 @UNDEF 	; Handle as undefined opcode

	 call	 GET_MODRM	; Return MOD/RM byte in AL

	 jmp	 RM_ADDR	; Jump to common routine

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@FLOP	 endp			; End @FLOP procedure
	 NPPROC  @FREG0 -- Display FREG #0 Instructions
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display FREG #0 instructions (D8) with MOD=11.

On entry:

DS:ESI	 ==>	 action stream
ES:EDI	 ==>	 output stream

On exit:

DS:ESI	 ==>	 action stream, updated
ES:EDI	 ==>	 output stream, updated
EAX	 =	 destroyed

|

	 call	 FN_PREF	; Fill in FN prefix, return ECX = starting offset

	 call	 GET_MODRM	; Return MOD/RM byte in AL

	 movzx	 ebx,al 	; Copy to index register
	 and	 ebx,mask $REG	; Isolate REG bits
	 shr	 ebx,$REG	; Shift to low-order

	 mov	 esi,FREG0_TAB.OPC[ebx*(type FREG4_STR)] ; DS:ESI ==> FREG #0 table opcode
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	 call	 FILL_OPCODE	; Fill out the opcode text from ECX

	 mov	 esi,FREG0_TAB.ARG[ebx*(type FREG4_STR)] ; DS:ESI ==> FREG #0 table argument
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

; Fill in register # (if any) from R/M bits in AL

	 call	 FILL_FREG	; Fill it in

	 jmp	 @EXIT		; That's all folks

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@FREG0	 endp			; End @FREG0 procedure
	 NPPROC  @FREG1 -- Display FREG #1 Instructions
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display FREG #1 instructions (D9) with MOD=11.

On entry:

DS:ESI	 ==>	 action stream
ES:EDI	 ==>	 output stream

On exit:

DS:ESI	 ==>	 action stream, updated
ES:EDI	 ==>	 output stream, updated
EAX	 =	 destroyed

|

	 call	 FN_PREF	; Fill in FN prefix, return ECX = starting offset

	 call	 GET_MODRM	; Return MOD/RM byte in AL

	 cmp	 al,11100000b	; Check for special cases
	 jae	 short @FREG1A	; Not special

; There are five special case below this point
; 1100 0 reg	 FLD  ST(i)
; 1100 1 reg	 FXCH ST(i)
; 1101 0000	 FNOP
; 1101 0xxx	 F???
; 1101 1 reg	 FSTP ST(i)

	 cmp	 al,11001000b	; Check for 1st special case
	 mov	 esi,0		; Assume it's 1st
	 jb	 short @FREG1_COM ; Good guess

	 cmp	 al,11010000b	; Check for 2nd and 3rd special cases
	 mov	 esi,1		; Assume it's 2nd
	 jb	 short @FREG1_COM ; Good guess
	 mov	 esi,2		; Assume it's 3rd
	 je	 short @FREG1_COM ; Good guess

	 cmp	 al,11011000b	; Check for 4th and 5th special cases
	 mov	 esi,3		; Assume it's 4th
	 jb	 short @FREG1_COM ; Good guess
	 mov	 esi,4		; Assume it's 5th

	 jmp	 short @FREG1_COM ; Join common code

@FREG1A:
	 movzx	 esi,al 	; Copy to index register
	 sub	 esi,11100000b-5 ; Convert to origin-11100000b-5
@FREG1_COM:
	 mov	 esi,FREG1_TAB[esi*(type FREG1_TAB)] ; DS:ESI ==> FREG #1 table
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

	 cmp	 al,11010000b	; Check for 1st, 2nd and 3rd special cases
	 jbe	 short @FREG1_REG ; Jump if register value to fill in

	 cmp	 al,11011000b	; Check for 4th special case
	 jb	 short @FREG1_EXIT ; No register value to fill in

	 cmp	 al,11100000b	; Check for 5th special case
	 jae	 short @FREG1_EXIT ; No register value to fill in
@FREG1_REG:
	 call	 FILL_OPCODE	; Fill out the opcode text from ECX

	 lea	 esi,FREG1_ARG	; DS:ESI ==> argument
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

; Fill in register # (if any) from R/M bits in AL

	 call	 FILL_FREG	; Fill it in
@FREG1_EXIT:
	 jmp	 @EXIT		; That's all folks

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@FREG1	 endp			; End @FREG1 procedure
	NPPROC	@FREG2 -- Display FREG #2 Instructions
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display FREG #2 instructions (DA) with MOD=11.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	FN_PREF 	; Fill in FN prefix, return ECX = starting offset

	call	GET_MODRM	; Return MOD/RM byte in AL

	cmp	al,11011111b	; Check for FCMOVcc upper limit
	ja	short @FREG2A	; Jump if too large

	movzx	esi,al		; Copy MOD/RM byte
	and	esi,mask $REG	; Isolate register bits
	shr	esi,$REG	; Shift to low-order
	mov	esi,FCMOV_TAB1[esi*(type FCMOV_TAB1)] ; DS:ESI ==> FCMOV table
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	call	FILL_OPCODE	; Fill out the opcode text from ECX

	lea	esi,FCMOV_ARG	; DS:ESI ==> argument
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

; Fill in register # (if any) from R/M bits in AL

	call	FILL_FREG	; Fill it in

	jmp	@EXIT		; That's all folks


@FREG2A:
	mov	esi,0		; Assume unknown

	cmp	al,11101001b	; Check for the only valid instruction
	jne	short @FREG2_UNK ; Jump if it's unknown

	mov	esi,1		; It's the only one
@FREG2_UNK:
	mov	esi,FREG2_TAB[esi*(type FREG2_TAB)] ; DS:ESI ==> FREG #2 table
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

	jmp	@EXIT		; That's all folks

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@FREG2	endp			; End @FREG2 procedure
	 NPPROC  @FREG3 -- Display FREG #3 Instructions
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display FREG #3 instructions (DB) with MOD=11.

On entry:

DS:ESI	 ==>	 action stream
ES:EDI	 ==>	 output stream

On exit:

DS:ESI	 ==>	 action stream, updated
ES:EDI	 ==>	 output stream, updated
EAX	 =	 destroyed

|

	call	FN_PREF 	; Fill in FN prefix, return ECX = starting offset

	call	GET_MODRM	; Return MOD/RM byte in AL

	cmp	al,11011111b	; Check for FCMOVcc upper limit
	ja	short @FREG3A	; Jump if too large

	movzx	esi,al		; Copy MOD/RM byte
	and	esi,mask $REG	; Isolate register bits
	shr	esi,$REG	; Shift to low-order
	mov	esi,FCMOV_TAB2[esi*(type FCMOV_TAB2)] ; DS:ESI ==> FCMOV table
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	call	FILL_OPCODE	; Fill out the opcode text from ECX

	lea	esi,FCMOV_ARG	; DS:ESI ==> argument
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

; Fill in register # (if any) from R/M bits in AL

	call	FILL_FREG	; Fill it in

	jmp	@EXIT		; That's all folks


@FREG3A:
	cmp	al,11101000b	; Check for FCOMI/FUCOMI lower limit
	jb	short @FREG3B	; Jump if too small

	cmp	al,11110111b	; Cehck for FCOMI/FUCOMI upper limit
	ja	short @FREG3B	; Jump if too large

	movzx	esi,al		; Copy MOD/RM byte
	and	esi,mask $REG	; Isolate register bits
	shr	esi,$REG	; Shift to low-order
	sub	esi,101b	; Convert to origin-5
	mov	esi,FCOMI_TAB[esi*(type FCOMI_TAB)] ; DS:ESI ==> FCMOV table
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	call	FILL_OPCODE	; Fill out the opcode text from ECX

	lea	esi,FCOMI_ARG	; DS:ESI ==> argument
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

; Fill in register # (if any) from R/M bits in AL

	call	FILL_FREG	; Fill it in

	jmp	@EXIT		; That's all folks


@FREG3B:
	mov	esi,0		; Assume unknown

	cmp	al,11100000b	; Check for the only valid instructions
	jb	short @FREG3_UNK ; Jump if it's unknown

	cmp	al,11100100b	; Check for the only valid instructions
	ja	short @FREG3_UNK ; Jump if it's unknown

	movzx	esi,al		; Copy to index register
	and	esi,mask $RM	; Isolate RM bits
	shr	esi,$RM 	; Shift to low-order
	inc	esi		; Convert to origin-1
@FREG3_UNK:
	mov	esi,FREG3_TAB[esi*(type FREG3_TAB)] ; DS:ESI ==> FREG #3 table
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

	jmp	@EXIT		; That's all folks

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@FREG3	endp			; End @FREG3 procedure
	 NPPROC  @FREG4 -- Display FREG #4 Instructions
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display FREG #4 instructions (DC) with MOD=11.

On entry:

DS:ESI	 ==>	 action stream
ES:EDI	 ==>	 output stream

On exit:

DS:ESI	 ==>	 action stream, updated
ES:EDI	 ==>	 output stream, updated
EAX	 =	 destroyed

|

	 call	 FN_PREF	; Fill in FN prefix, return ECX = starting offset

	 call	 GET_MODRM	; Return MOD/RM byte in AL

	 movzx	 esi,al 	; Copy to index register
	 and	 esi,mask $REG	; Isolate REG bits
	 shr	 esi,$REG	; Shift to low-order
	 mov	 esi,FREG4_TAB[esi*(type FREG4_TAB)] ; DS:ESI ==> FREG #4 table
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	 call	 FILL_OPCODE	; Fill out the opcode text from ECX

	 lea	 esi,FREG4_ARG	; DS:ESI ==> argument
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

; Fill in register # (if any) from R/M bits in AL

	 call	 FILL_FREG	; Fill it in

	 jmp	 @EXIT		; That's all folks

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@FREG4	 endp			; End @FREG4 procedure
	 NPPROC  @FREG5 -- Display FREG #5 Instructions
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display FREG #5 instructions (DD) with MOD=11.

On entry:

DS:ESI	 ==>	 action stream
ES:EDI	 ==>	 output stream

On exit:

DS:ESI	 ==>	 action stream, updated
ES:EDI	 ==>	 output stream, updated
EAX	 =	 destroyed

|

	 call	 FN_PREF	; Fill in FN prefix, return ECX = starting offset

	 call	 GET_MODRM	; Return MOD/RM byte in AL

	 movzx	 esi,al 	; Copy to index register
	 and	 esi,mask $REG	; Isolate REG bits
	 shr	 esi,$REG	; Shift to low-order
	 mov	 esi,FREG5_TAB[esi*(type FREG5_TAB)] ; DS:ESI ==> FREG #5 table
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	 call	 FILL_OPCODE	; Fill out the opcode text from ECX

	 lea	 esi,FREG5_ARG	; DS:ESI ==> argument
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

; Fill in register # (if any) from R/M bits in AL

	 call	 FILL_FREG	; Fill it in

	 jmp	 @EXIT		; That's all folks

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@FREG5	 endp			; End @FREG5 procedure
	 NPPROC  @FREG6 -- Display FREG #6 Instructions
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display FREG #6 instructions (DE) with MOD=11.

On entry:

DS:ESI	 ==>	 action stream
ES:EDI	 ==>	 output stream

On exit:

DS:ESI	 ==>	 action stream, updated
ES:EDI	 ==>	 output stream, updated
EAX	 =	 destroyed

|

	 call	 FN_PREF	; Fill in FN prefix, return ECX = starting offset

	 call	 GET_MODRM	; Return MOD/RM byte in AL

	 lea	 esi,TXT_UNK	; Assume unknown

	 cmp	 al,11011001b	; Check for FCOMPP
	 je	 short @FREG6A	; Good guess

	 cmp	 al,11010000b	; Check for below reserved
	 jb	 short @FREG6A	; It's OK

	 cmp	 al,11011111b	; Check for above reserved
	 jbe	 short @FREG6B	; Jump if it's unknown
@FREG6A:
	 movzx	 esi,al 	; Copy to index register
	 and	 esi,mask $REG	; Isolate REG bits
	 shr	 esi,$REG	; Shift to low-order
	 mov	 esi,FREG6_TAB[esi*(type FREG6_TAB)] ; DS:ESI ==> FREG #6 table
@FREG6B:
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	 call	 FILL_OPCODE	; Fill out the opcode text from ECX

	 cmp	 al,11011001b	; Check for FCOMPP
	 je	 short @FREG6C	; Yes, skip argument append

	 cmp	 al,11010000b	; Check for below reserved
	 jb	 short @F	; It's OK

	 cmp	 al,11011111b	; Check for above reserved
	 jbe	 short @FREG6C	; Skip argument append
@@:
	 lea	 esi,FREG6_ARG	; DS:ESI ==> argument
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

; Fill in register # (if any) from R/M bits in AL

	 call	 FILL_FREG	; Fill it in
@FREG6C:
	 jmp	 @EXIT		; That's all folks

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@FREG6	 endp			; End @FREG6 procedure
	 NPPROC  @FREG7 -- Display FREG #7 Instructions
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display FREG #7 instructions (DF) with MOD=11.

On entry:

DS:ESI	 ==>	 action stream
ES:EDI	 ==>	 output stream

On exit:

DS:ESI	 ==>	 action stream, updated
ES:EDI	 ==>	 output stream, updated
EAX	 =	 destroyed

|

	 call	 FN_PREF	; Fill in FN prefix, return ECX = starting offset

	 call	 GET_MODRM	; Return MOD/RM byte in AL

	cmp	al,11101000b	; Check for FCOMIP/FUCOMIP lower limit
	jb	short @FREG7A	; Jump if too small

	cmp	al,11110111b	; Cehck for FCOMIP/FUCOMIP upper limit
	ja	short @FREG7A	; Jump if too large

	movzx	esi,al		; Copy MOD/RM byte
	and	esi,mask $REG	; Isolate register bits
	shr	esi,$REG	; Shift to low-order
	sub	esi,101b	; Convert to origin-5
	mov	esi,FCOMIP_TAB[esi*(type FCOMIP_TAB)] ; DS:ESI ==> FCMOV table
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	call	FILL_OPCODE	; Fill out the opcode text from ECX

	lea	esi,FCOMIP_ARG	; DS:ESI ==> argument
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

; Fill in register # (if any) from R/M bits in AL

	call	FILL_FREG	; Fill it in

	jmp	@EXIT		; That's all folks


@FREG7A:
	 lea	 esi,TXT_UNK	; Assume unknown

	 cmp	 al,11100000b	; Check for the only valid instruction
	 jne	 short @FREG7_UNK ; Jump if it's unknown

	 lea	 esi,FREG7_1	; Use this text
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	 call	 FILL_OPCODE	; Fill out the opcode text from ECX

	 lea	 esi,TXT_AX	; Append AX register
@FREG7_UNK:
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

	 jmp	 @EXIT		; That's all folks

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@FREG7	 endp			; End @FREG7 procedure
	 NPPROC  FILL_FREG -- Fill In FREG
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill in FREG

On entry:

AL	 =	 MOD R/M byte
ES:EDI	 ==>	 output stream

|

	 REGSAVE <ecx,edi>	; Save for a moment

	 push	 eax		; Save MOD R/M byte

	 mov	 al,'*'         ; Search for substitution
	 mov	 ecx,10 	; Look no further than this
	 std
   repne scas	 es:[edi].LO	; Search for it
	 pop	 eax		; Restore
	 cld
	 jne	 short FILL_FREG_EXIT ; Jump if not found

	 and	 al,mask $RM	; Isolate register #
	 shr	 al,$RM 	; Shift to low-order
	 add	 al,'0'         ; Convert to ASCII

	 mov	 es:[edi+1].LO,al ; Save register # in output stream
FILL_FREG_EXIT:
	 REGREST <edi,ecx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_FREG endp			; End FILL_FREG procedure
	 NPPROC  FN_PREF -- Fill in FN Prefix
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill in the FN prefix in a floating point instruction.

On entry:

ES:EDI	 ==>	 output stream

On exit:

ECX	 =	 starting offset of output stream
ES:EDI	 ==>	 output stream, updated

|

	 push	 eax		; Save for a moment

	 mov	 ecx,edi	; Save starting offset

	 test	 [ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	 jnz	 short @F	; Yes, skip this

	 mov	 al,'F'         ; Instruction prefix
S32	 stos	 es:[edi].LO	; Save in output stream
@@:
	 test	 [ebp].ID_PDEF,@PREF_WAIT ; WAIT prefix present?
	 jnz	 short FN_PREF1 ; Yes, skip 'N'

	 test	 [ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	 jnz	 short @F	; Yes, skip this

	 mov	 al,'N'         ; No-WAIT indicator
S32	 stos	 es:[edi].LO	; Save in output stream
@@:
	 jmp	 short FN_PREF_EXIT ; Join common code

FN_PREF1:
	 or	 [ebp].ID_FLAG,@FLAG_WAIT ; Mark as used
FN_PREF_EXIT:
	 pop	 eax		; Restore MOD R/M byte

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FN_PREF  endp			; End FN_PREF procedure

PROG	 ends			; End PROG segment

	 MEND			; End INT1_FOP module
