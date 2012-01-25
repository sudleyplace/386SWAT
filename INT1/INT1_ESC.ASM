;' $Header:   P:/PVCS/386SWAT/INT1/INT1_ESC.ASV   1.7   01 Jul 1997 17:55:52   BOB  $
	 title	 INT1_ESC -- INT 01h Escape Code Tables
	 page	 58,122
	 name	 INT1_ESC

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, April, 1988.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include BITFLAGS.INC

	 include INT1_FNS.INC
	 include INT1_TAB.INC
	 include SWAT_SEG.INC
.list

PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 extrn	 @OPCODE:near

	 extrn	 @IFOSP:near
	 extrn	 @ELSEOSP:near
	 extrn	 @IFOSP2:near
	 extrn	 @ELSEOSP2:near
	 extrn	 @ENDOSP:near
	 extrn	 @IGNOREOSP:near

	 extrn	 @R8:near
	 extrn	 @R16:near
	 extrn	 @R32:near

	 extrn	 @RM8:near
	 extrn	 @RM16:near
	 extrn	 @RM32:near
	 extrn	 @RM64:near

	 extrn	 @RM8P:near
	 extrn	 @RM16P:near
	 extrn	 @RM32P:near

	 extrn	 @IMM8:near

	 extrn	 @STACK1:near

	 extrn	 @DWIDTH:near

	 extrn	 @GRP6:near
	 extrn	 @GRP7:near
	 extrn	 @GRP8:near

	 extrn	 @CR32:near
	 extrn	 @DR32:near
	 extrn	 @TR32:near

	 extrn	 @REL16:near
	 extrn	 @REL32:near

	 extrn	 @EXIT:near

PROG	 ends			; End PROG segment


TEXT	 segment use32 byte public 'data' ; Start TEXT segment
	 assume  ds:DGROUP

	 extrn	 TXT_AX:byte
	 extrn	 TXT_BP:byte
	 extrn	 TXT_BX:byte
	 extrn	 TXT_CX:byte
	 extrn	 TXT_DI:byte
	 extrn	 TXT_DX:byte
	 extrn	 TXT_SI:byte
	 extrn	 TXT_SP:byte

	 extrn	 TXT_EAX:byte
	 extrn	 TXT_EBP:byte
	 extrn	 TXT_EBX:byte
	 extrn	 TXT_ECX:byte
	 extrn	 TXT_EDI:byte
	 extrn	 TXT_EDX:byte
	 extrn	 TXT_ESI:byte
	 extrn	 TXT_ESP:byte

	 extrn	 TXT_FS:byte
	 extrn	 TXT_GS:byte

	 extrn	 TXT_@CL:byte

	 extrn	 TXT_BSF:byte
	 extrn	 TXT_BSR:byte
	 extrn	 TXT_BSWAP:byte
	 extrn	 TXT_BT:byte
	 extrn	 TXT_BTC:byte
	 extrn	 TXT_BTR:byte
	 extrn	 TXT_BTS:byte

	 extrn	 TXT_CLTS:byte
	 extrn	 TXT_CMPXCHG:byte
	 extrn	 TXT_CMPXCHG8B:byte
	 extrn	 TXT_CMOVA:byte
	 extrn	 TXT_CMOVBE:byte
	 extrn	 TXT_CMOVC:byte
	 extrn	 TXT_CMOVG:byte
	 extrn	 TXT_CMOVGE:byte
	 extrn	 TXT_CMOVL:byte
	 extrn	 TXT_CMOVLE:byte
	 extrn	 TXT_CMOVNC:byte
	 extrn	 TXT_CMOVNO:byte
	 extrn	 TXT_CMOVNS:byte
	 extrn	 TXT_CMOVNZ:byte
	 extrn	 TXT_CMOVO:byte
	 extrn	 TXT_CMOVPE:byte
	 extrn	 TXT_CMOVPO:byte
	 extrn	 TXT_CMOVS:byte
	 extrn	 TXT_CMOVZ:byte
	 extrn	 TXT_CPUID:byte

	 extrn	 TXT_IBTS:byte
	 extrn	 TXT_IMUL:byte
	 extrn	 TXT_INVD:byte

	 extrn	 TXT_JA:byte
	 extrn	 TXT_JBE:byte
	 extrn	 TXT_JC:byte
	 extrn	 TXT_JG:byte
	 extrn	 TXT_JGE:byte
	 extrn	 TXT_JL:byte
	 extrn	 TXT_JLE:byte
	 extrn	 TXT_JNC:byte
	 extrn	 TXT_JNO:byte
	 extrn	 TXT_JNS:byte
	 extrn	 TXT_JNZ:byte
	 extrn	 TXT_JO:byte
	 extrn	 TXT_JPE:byte
	 extrn	 TXT_JPO:byte
	 extrn	 TXT_JS:byte
	 extrn	 TXT_JZ:byte

	 extrn	 TXT_LAR:byte
	 extrn	 TXT_LOADALL:byte
	 extrn	 TXT_LOADALLD:byte
	 extrn	 TXT_LFS:byte
	 extrn	 TXT_LGS:byte
	 extrn	 TXT_LSL:byte
	 extrn	 TXT_LSS:byte

	 extrn	 TXT_MOV:byte
	 extrn	 TXT_MOVSX:byte
	 extrn	 TXT_MOVZX:byte

	 extrn	 TXT_POP:byte
	 extrn	 TXT_POPD:byte
	 extrn	 TXT_PUSH:byte
	 extrn	 TXT_PUSHD:byte

	 extrn	 TXT_RDMSR:byte
	 extrn	 TXT_RDPMC:byte
	 extrn	 TXT_RDTSC:byte
	 extrn	 TXT_RSM:byte

	 extrn	 TXT_SETA:byte
	 extrn	 TXT_SETC:byte
	 extrn	 TXT_SETG:byte
	 extrn	 TXT_SETL:byte
	 extrn	 TXT_SETNA:byte
	 extrn	 TXT_SETNC:byte
	 extrn	 TXT_SETNG:byte
	 extrn	 TXT_SETNL:byte
	 extrn	 TXT_SETNO:byte
	 extrn	 TXT_SETNS:byte
	 extrn	 TXT_SETNZ:byte
	 extrn	 TXT_SETO:byte
	 extrn	 TXT_SETPE:byte
	 extrn	 TXT_SETPO:byte
	 extrn	 TXT_SETS:byte
	 extrn	 TXT_SETZ:byte

	 extrn	 TXT_SHLD:byte
	 extrn	 TXT_SHRD:byte

	 extrn	 TXT_SYSENTER:byte
	 extrn	 TXT_SYSEXIT:byte

	 extrn	 TXT_WBINVD:byte
	 extrn	 TXT_WIN06:byte

	 extrn	 TXT_WRMSR:byte

	 extrn	 TXT_XADD:byte
	 extrn	 TXT_XBTS:byte

	 extrn	 P@UNDEF:dword

TEXT	 ends			; End TEXT segment


ESCOD	 segment use32 dword public 'data' ; Start ESCOD segment
	 assume  ds:DGROUP

ELBL	 macro	 OPC

ESCOD&OPC label  dword

	 org	 ESCOD_TAB+OPC*(type ESCOD_TAB)
	 dd	 offset DGROUP:ESCOD&OPC
	 org	 ESCOD&OPC

	 endm			; ELBL

	 public  ESCOD_TAB
ESCOD_TAB dd	 256 dup (offset DGROUP:P@UNDEF) ; Initially all undefined

$$ASP	 =	 0
$$OSP	 =	 0

	 ELBL	 0		; 00
	 GRP6
	 IFOSP2
	 RM32P
	 ELSEOSP2
	 RM16P
	 ENDOSP
	 EXIT

	 ELBL	 1		; 01
	 GRP7
	 IFOSP2
	 RM32P
	 ELSEOSP2
	 RM16P
	 ENDOSP
	 EXIT

	 ELBL	 2		; 02
	 OPCODE  LAR
	 IFOSP
	 R32
	 RM32
	 DWIDTH  WORD
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ELBL	 3		; 03
	 OPCODE  LSL
	 IFOSP
	 R32
	 RM32
	 DWIDTH  WORD
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ELBL	 5		; 05
	 OPCODE  LOADALL
	 EXIT

	 ELBL	 6		; 06
	 OPCODE  CLTS
	 EXIT

	 ELBL	 7		; 07
	 OPCODE  LOADALLD
	 EXIT

	 ELBL	 8		; 08
	 OPCODE  INVD
	 EXIT

	 ELBL	 9		; 09
	 OPCODE  WBINVD
	 EXIT

	 ELBL	 16		; 10 -- Undocumented
	 OPCODE  MOV		; Just like 88
	 RM8
	 R8
	 EXIT

	 ELBL	 17		; 11 -- Undocumented
	 OPCODE  MOV		; Just like 8B
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ELBL	 18		; 12 -- Undocumented
	 OPCODE  MOV		; Just like 8A
	 R8
	 RM8
	 EXIT

	 ELBL	 19		; 13 -- Undocumented
	 OPCODE  MOV		; Just like 89
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 EXIT

	 ELBL	 32		; 20
	 IGNOREOSP
	 OPCODE  MOV
	 RM32
	 CR32
	 EXIT

	 ELBL	 33		; 21
	 IGNOREOSP
	 OPCODE  MOV
	 RM32
	 DR32
	 EXIT

	 ELBL	 34		; 22
	 IGNOREOSP
	 OPCODE  MOV
	 CR32
	 RM32
	 EXIT

	 ELBL	 35		; 23
	 IGNOREOSP
	 OPCODE  MOV
	 DR32
	 RM32
	 EXIT

	 ELBL	 36		; 24
	 IGNOREOSP
	 OPCODE  MOV
	 RM32
	 TR32
	 EXIT

	 ELBL	 38		; 26
	 IGNOREOSP
	 OPCODE  MOV
	 TR32
	 RM32
	 EXIT

	 ELBL	 48		; 30
	 OPCODE  WRMSR
	 EXIT

	 ELBL	 49		; 31
	 OPCODE  RDTSC
	 EXIT

	 ELBL	 50		; 32
	 OPCODE  RDMSR
	 EXIT

	 ELBL	 51		; 33
	 OPCODE  RDPMC
	 EXIT

	 ELBL	 52		; 34
	 OPCODE  SYSENTER
	 EXIT

	 ELBL	 53		; 35
	 OPCODE  SYSEXIT
	 EXIT

	 ELBL	 64		; 40
	 OPCODE  CMOVO
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ELBL	 65		; 41
	 OPCODE  CMOVNO
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ELBL	 66		; 42
	 OPCODE  CMOVC
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ELBL	 67		; 43
	 OPCODE  CMOVNC
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ELBL	 68		; 44
	 OPCODE  CMOVZ
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ELBL	 69		; 45
	 OPCODE  CMOVNZ
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ELBL	 70		; 46
	 OPCODE  CMOVBE
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ELBL	 71		; 47
	 OPCODE  CMOVA
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ELBL	 72		; 48
	 OPCODE  CMOVS
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 73		; 49
	 OPCODE  CMOVNS
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 74		; 4A
	 OPCODE  CMOVPE
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 75		; 4B
	 OPCODE  CMOVPO
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 76		; 4C
	 OPCODE  CMOVL
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 77		; 4D
	 OPCODE  CMOVGE
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 78		; 4E
	 OPCODE  CMOVLE
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 79		; 4F
	 OPCODE  CMOVG
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 128		; 80
	 OPCODE  JO
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 129		; 81
	 OPCODE  JNO
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 130		; 82
	 OPCODE  JC
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 131		; 83
	 OPCODE  JNC
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 132		; 84
	 OPCODE  JZ
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 133		; 85
	 OPCODE  JNZ
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 134		; 86
	 OPCODE  JBE
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 135		; 87
	 OPCODE  JA
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 136		; 88
	 OPCODE  JS
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 137		; 89
	 OPCODE  JNS
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 138		; 8A
	 OPCODE  JPE
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 139		; 8B
	 OPCODE  JPO
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 140		; 8C
	 OPCODE  JL
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 141		; 8D
	 OPCODE  JGE
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 142		; 8E
	 OPCODE  JLE
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 143		; 8F
	 OPCODE  JG
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ELBL	 144		; 90
	 OPCODE  SETO
	 RM8P
	 EXIT

	 ELBL	 145		; 91
	 OPCODE  SETNO
	 RM8P
	 EXIT

	 ELBL	 146		; 92
	 OPCODE  SETC
	 RM8P
	 EXIT

	 ELBL	 147		; 93
	 OPCODE  SETNC
	 RM8P
	 EXIT

	 ELBL	 148		; 94
	 OPCODE  SETZ
	 RM8P
	 EXIT

	 ELBL	 149		; 95
	 OPCODE  SETNZ
	 RM8P
	 EXIT

	 ELBL	 150		; 96
	 OPCODE  SETA
	 RM8P
	 EXIT

	 ELBL	 151		; 97
	 OPCODE  SETNA
	 RM8P
	 EXIT

	 ELBL	 152		; 98
	 OPCODE  SETS
	 RM8P
	 EXIT

	 ELBL	 153		; 99
	 OPCODE  SETNS
	 RM8P
	 EXIT

	 ELBL	 154		; 9A
	 OPCODE  SETPE
	 RM8P
	 EXIT

	 ELBL	 155		; 9B
	 OPCODE  SETPO
	 RM8P
	 EXIT

	 ELBL	 156		; 9C
	 OPCODE  SETL
	 RM8P
	 EXIT

	 ELBL	 157		; 9D
	 OPCODE  SETNL
	 RM8P
	 EXIT

	 ELBL	 158		; 9E
	 OPCODE  SETG
	 RM8P
	 EXIT

	 ELBL	 159		; 9F
	 OPCODE  SETNG
	 RM8P
	 EXIT

	 ELBL	 160		; A0
	 IFOSP
	 OPCODE  PUSHD
	 ELSEOSP
	 OPCODE  PUSH
	 ENDOSP
	 OPCODE  FS
	 EXIT

	 ELBL	 161		; A1
	 IFOSP
	 OPCODE  POPD
	 ELSEOSP
	 OPCODE  POP
	 ENDOSP
	 OPCODE  FS
	 STACK1  WORD
	 EXIT

	 ELBL	 162		; A2
	 OPCODE  CPUID
	 EXIT

	 ELBL	 163		; A3
	 OPCODE  BT
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 DWIDTH  BTREG
	 EXIT

	 ELBL	 164		; A4
	 OPCODE  SHLD
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 IMM8
	 EXIT

	 ELBL	 165		; A5
	 OPCODE  SHLD
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 OPCODE  @CL
	 EXIT

	 ELBL	 166		; A6
	 OPCODE  XBTS
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 EXIT

	 ELBL	 167		; A7
	 OPCODE  IBTS
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 EXIT

	 ELBL	 168		; A8
	 IFOSP
	 OPCODE  PUSHD
	 ELSEOSP
	 OPCODE  PUSH
	 ENDOSP
	 OPCODE  GS
	 EXIT

	 ELBL	 169		; A9
	 IFOSP
	 OPCODE  POPD
	 ELSEOSP
	 OPCODE  POP
	 ENDOSP
	 OPCODE  GS
	 STACK1  WORD
	 EXIT

	 ELBL	 170		; AA -- 386 SL
	 OPCODE  RSM
	 EXIT

	 ELBL	 171		; AB
	 OPCODE  BTS
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 DWIDTH  BTREG
	 EXIT

	 ELBL	 172		; AC
	 OPCODE  SHRD
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 IMM8
	 EXIT

	 ELBL	 173		; AD
	 OPCODE  SHRD
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 OPCODE  @CL
	 EXIT

	 ELBL	 175		; AF
	 OPCODE  IMUL
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ELBL	 176		; B0
	 OPCODE  CMPXCHG
	 RM8
	 R8
	 EXIT

	 ELBL	 177		; B1
	 OPCODE  CMPXCHG
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 EXIT

	 ELBL	 178		; B2
	 OPCODE  LSS
	 IFOSP
	 R32
	 RM32
	 DWIDTH  PTR32
	 ELSEOSP
	 R16
	 RM16
	 DWIDTH  PTR16
	 ENDOSP
	 EXIT

	 ELBL	 179		; B3
	 OPCODE  BTR
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 DWIDTH  BTREG
	 EXIT

	 ELBL	 180		; B4
	 OPCODE  LFS
	 IFOSP
	 R32
	 RM32
	 DWIDTH  PTR32
	 ELSEOSP
	 R16
	 RM16
	 DWIDTH  PTR16
	 ENDOSP
	 EXIT

	 ELBL	 181		; B5
	 OPCODE  LGS
	 IFOSP
	 R32
	 RM32
	 DWIDTH  PTR32
	 ELSEOSP
	 R16
	 RM16
	 DWIDTH  PTR16
	 ENDOSP
	 EXIT

	 ELBL	 182		; B6
	 OPCODE  MOVZX
	 IFOSP
	 R32
	 ELSEOSP
	 R16
	 ENDOSP
	 RM8P
	 EXIT

	 ELBL	 183		; B7
	 OPCODE  MOVZX
	 R32
	 RM16P
	 EXIT

	 ELBL	 186		; BA
	 GRP8
	 IFOSP
	 RM32P
	 ELSEOSP
	 RM16P
	 ENDOSP
	 IMM8
	 EXIT

	 ELBL	 187		; BB
	 OPCODE  BTC
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 DWIDTH  BTREG
	 EXIT

	 ELBL	 188		; BC
	 OPCODE  BSF
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ELBL	 189		; BD
	 OPCODE  BSR
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ELBL	 190		; BE
	 OPCODE  MOVSX
	 IFOSP
	 R32
	 ELSEOSP
	 R16
	 ENDOSP
	 RM8P
	 EXIT

	 ELBL	 191		; BF
	 OPCODE  MOVSX
	 R32
	 RM16P
	 EXIT

	 ELBL	 192		; C0
	 OPCODE  XADD
	 RM8
	 R8
	 EXIT

	 ELBL	 193		; C1
	 OPCODE  XADD
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 EXIT

	 ELBL	 199		; C7
	 OPCODE  CMPXCHG8B
	 RM64
	 EXIT

	 ELBL	 200		; C8
	 OPCODE  BSWAP
	 IFOSP
	 OPCODE  EAX
	 ELSEOSP
	 OPCODE  AX
	 ENDOSP
	 EXIT

	 ELBL	 201		; C9
	 OPCODE  BSWAP
	 IFOSP
	 OPCODE  ECX
	 ELSEOSP
	 OPCODE  CX
	 ENDOSP
	 EXIT

	 ELBL	 202		; CA
	 OPCODE  BSWAP
	 IFOSP
	 OPCODE  EDX
	 ELSEOSP
	 OPCODE  DX
	 ENDOSP
	 EXIT

	 ELBL	 203		; CB
	 OPCODE  BSWAP
	 IFOSP
	 OPCODE  EBX
	 ELSEOSP
	 OPCODE  BX
	 ENDOSP
	 EXIT

	 ELBL	 204		; CC
	 OPCODE  BSWAP
	 IFOSP
	 OPCODE  ESP
	 ELSEOSP
	 OPCODE  SP
	 ENDOSP
	 EXIT

	 ELBL	 205		; CD
	 OPCODE  BSWAP
	 IFOSP
	 OPCODE  EBP
	 ELSEOSP
	 OPCODE  BP
	 ENDOSP
	 EXIT

	 ELBL	 206		; CE
	 OPCODE  BSWAP
	 IFOSP
	 OPCODE  ESI
	 ELSEOSP
	 OPCODE  SI
	 ENDOSP
	 EXIT

	 ELBL	 207		; CF
	 OPCODE  BSWAP
	 IFOSP
	 OPCODE  EDI
	 ELSEOSP
	 OPCODE  DI
	 ENDOSP
	 EXIT

	 ELBL	 255		; FF
	 OPCODE  WIN06
	 EXIT

ESCOD	 ends			; End ESCOD segment

	 MEND			; End INT1_ESC module
