;' $Header:   P:/PVCS/386SWAT/INT1/INT1_TAB.ASV   1.7   17 Jul 1997 13:54:10   BOB  $
	 title	 INT1_TAB -- INT 01h Tables
	 page	 58,122
	 name	 INT1_TAB

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
	 include IOPBITS.INC

	 include INT1_FNS.INC
	 include INT1_TAB.INC
	 include SWAT_SEG.INC
.list

PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 extrn	 @OPCODE:near

	 extrn	 @IFOSP:near
	 extrn	 @ELSEOSP:near
	 extrn	 @ENDOSP:near
	 extrn	 @IGNOREOSP:near

	 extrn	 @IFASP:near
	 extrn	 @ELSEASP:near
	 extrn	 @ENDASP:near

	 extrn	 @R8:near
	 extrn	 @R16:near
	 extrn	 @R32:near

	 extrn	 @RM8:near
	 extrn	 @RM16:near
	 extrn	 @RM32:near

	 extrn	 @RM8P:near
	 extrn	 @RM16P:near
	 extrn	 @RM32P:near

	 extrn	 @IMM8:near
	 extrn	 @IMM8D:near
	 extrn	 @IMM8W:near
	 extrn	 @IMM16:near
	 extrn	 @IMM32:near
	 extrn	 @INTMSG:near

	 extrn	 @DSP16:near
	 extrn	 @DSP32:near

	 extrn	 @MODRM1:near
	 extrn	 @MODRM2:near

	 extrn	 @STACK1:near
	 extrn	 @STACK2:near

	 extrn	 @DWIDTH:near

	 extrn	 @GRP1:near
	 extrn	 @GRP2:near
	 extrn	 @GRP3:near
	 extrn	 @GRP3Z:near
	 extrn	 @GRP4:near
	 extrn	 @GRP5:near

	 extrn	 @PTR16@16:near
	 extrn	 @PTR16@32:near

	 extrn	 @REL8:near
	 extrn	 @REL16:near
	 extrn	 @REL32:near

	 extrn	 @FLOP:near
	 extrn	 @FREG0:near
	 extrn	 @FREG1:near
	 extrn	 @FREG2:near
	 extrn	 @FREG3:near
	 extrn	 @FREG4:near
	 extrn	 @FREG5:near
	 extrn	 @FREG6:near
	 extrn	 @FREG7:near

	 extrn	 @RPT:near
	 extrn	 @SRO:near
	 extrn	 @SREG:near
	 extrn	 @ESC0F:near
	 extrn	 @SETPREF:near

	 extrn	 @EXIT:near

PROG	 ends			; End PROG segment


TEXT	 segment use32 byte public 'data' ; Start TEXT segment
	 assume  ds:DGROUP

	 extrn	 TXT_AL:byte
	 extrn	 TXT_AH:byte
	 extrn	 TXT_BL:byte
	 extrn	 TXT_BH:byte
	 extrn	 TXT_CL:byte
	 extrn	 TXT_CH:byte
	 extrn	 TXT_DL:byte
	 extrn	 TXT_DH:byte

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

	 extrn	 TXT_CS:byte
	 extrn	 TXT_DS:byte
	 extrn	 TXT_ES:byte
	 extrn	 TXT_SS:byte

	 extrn	 TXT_AL@DX:byte
	 extrn	 TXT_AX@BP:byte
	 extrn	 TXT_AX@BX:byte
	 extrn	 TXT_AX@CX:byte
	 extrn	 TXT_AX@DI:byte
	 extrn	 TXT_AX@DX:byte
	 extrn	 TXT_AX@SI:byte
	 extrn	 TXT_AX@SP:byte
	 extrn	 TXT_DX@AL:byte
	 extrn	 TXT_DX@AX:byte
	 extrn	 TXT_DX@EAX:byte
	 extrn	 TXT_EAX@DX:byte
	 extrn	 TXT_EAX@EBP:byte
	 extrn	 TXT_EAX@EBX:byte
	 extrn	 TXT_EAX@ECX:byte
	 extrn	 TXT_EAX@EDI:byte
	 extrn	 TXT_EAX@EDX:byte
	 extrn	 TXT_EAX@ESI:byte
	 extrn	 TXT_EAX@ESP:byte

	 extrn	 TXT_LBR:byte
	 extrn	 TXT_RBR:byte
	 extrn	 TXT_RBR@AL:byte
	 extrn	 TXT_RBR@AX:byte
	 extrn	 TXT_RBR@EAX:byte

	 extrn	 TXT_$EBX$:byte
	 extrn	 TXT_$EDI$:byte
	 extrn	 TXT_$ESI$:byte

	 extrn	 TXT_@1:byte
	 extrn	 TXT_@AL:byte
	 extrn	 TXT_@CL:byte
	 extrn	 TXT_@AX:byte
	 extrn	 TXT_@EAX:byte
	 extrn	 TXT_01:byte
	 extrn	 TXT_03:byte

; Instruction names

	 extrn	 TXT_AAA:byte
	 extrn	 TXT_AAD:byte
	 extrn	 TXT_AAM:byte
	 extrn	 TXT_AAS:byte
	 extrn	 TXT_ADC:byte
	 extrn	 TXT_ADD:byte
	 extrn	 TXT_AND:byte
	 extrn	 TXT_ARPL:byte

	 extrn	 TXT_BOUND:byte

	 extrn	 TXT_CALL:byte
	 extrn	 TXT_CBW:byte
	 extrn	 TXT_CDQ:byte
	 extrn	 TXT_CLC:byte
	 extrn	 TXT_CLD:byte
	 extrn	 TXT_CLI:byte
	 extrn	 TXT_CMC:byte
	 extrn	 TXT_CMP:byte
	 extrn	 TXT_CMPSB:byte
	 extrn	 TXT_CMPSD:byte
	 extrn	 TXT_CMPSW:byte
	 extrn	 TXT_CWD:byte
	 extrn	 TXT_CWDE:byte

	 extrn	 TXT_DAA:byte
	 extrn	 TXT_DAS:byte
	 extrn	 TXT_DEC:byte

	 extrn	 TXT_ENTER:byte
	 extrn	 TXT_ENTERD:byte

	 extrn	 TXT_IMUL:byte
	 extrn	 TXT_IN:byte
	 extrn	 TXT_INC:byte
	 extrn	 TXT_INSB:byte
	 extrn	 TXT_INSD:byte
	 extrn	 TXT_INSW:byte
	 extrn	 TXT_INT:byte
	 extrn	 TXT_ICE:byte
	 extrn	 TXT_INTO:byte
	 extrn	 TXT_IRET:byte
	 extrn	 TXT_IRETD:byte

	 extrn	 TXT_JA:byte
	 extrn	 TXT_JBE:byte
	 extrn	 TXT_JC:byte
	 extrn	 TXT_JCXZ:byte
	 extrn	 TXT_JECXZ:byte
	 extrn	 TXT_JG:byte
	 extrn	 TXT_JGE:byte
	 extrn	 TXT_JL:byte
	 extrn	 TXT_JLE:byte
	 extrn	 TXT_JMP:byte
	 extrn	 TXT_JNC:byte
	 extrn	 TXT_JNO:byte
	 extrn	 TXT_JNS:byte
	 extrn	 TXT_JNZ:byte
	 extrn	 TXT_JO:byte
	 extrn	 TXT_JPE:byte
	 extrn	 TXT_JPO:byte
	 extrn	 TXT_JS:byte
	 extrn	 TXT_JZ:byte

	 extrn	 TXT_HLT:byte

	 extrn	 TXT_LAHF:byte
	 extrn	 TXT_LDS:byte
	 extrn	 TXT_LEA:byte
	 extrn	 TXT_LEAVE:byte
	 extrn	 TXT_LEAVED:byte
	 extrn	 TXT_LES:byte
	 extrn	 TXT_LODSB:byte
	 extrn	 TXT_LODSD:byte
	 extrn	 TXT_LODSW:byte
	 extrn	 TXT_LOOP:byte
	 extrn	 TXT_LOOPD:byte
	 extrn	 TXT_LOOPDE:byte
	 extrn	 TXT_LOOPDNE:byte
	 extrn	 TXT_LOOPE:byte
	 extrn	 TXT_LOOPNE:byte

	 extrn	 TXT_MOV:byte
	 extrn	 TXT_MOVSB:byte
	 extrn	 TXT_MOVSD:byte
	 extrn	 TXT_MOVSW:byte
	 extrn	 TXT_NOP:byte
	 extrn	 TXT_NOPD:byte
	 extrn	 TXT_OR:byte
	 extrn	 TXT_OUT:byte
	 extrn	 TXT_OUTSB:byte
	 extrn	 TXT_OUTSD:byte
	 extrn	 TXT_OUTSW:byte
	 extrn	 TXT_POP:byte
	 extrn	 TXT_POPA:byte
	 extrn	 TXT_POPAD:byte
	 extrn	 TXT_POPD:byte
	 extrn	 TXT_POPF:byte
	 extrn	 TXT_POPFD:byte
	 extrn	 TXT_PUSH:byte
	 extrn	 TXT_PUSHA:byte
	 extrn	 TXT_PUSHAD:byte
	 extrn	 TXT_PUSHD:byte
	 extrn	 TXT_PUSHF:byte
	 extrn	 TXT_PUSHFD:byte

	 extrn	 TXT_RET:byte
	 extrn	 TXT_RETD:byte
	 extrn	 TXT_RETF:byte
	 extrn	 TXT_RETFD:byte

	 extrn	 TXT_SAHF:byte
	 extrn	 TXT_SALC:byte
	 extrn	 TXT_SBB:byte
	 extrn	 TXT_SCASB:byte
	 extrn	 TXT_SCASD:byte
	 extrn	 TXT_SCASW:byte
	 extrn	 TXT_STC:byte
	 extrn	 TXT_STD:byte
	 extrn	 TXT_STI:byte
	 extrn	 TXT_STOSB:byte
	 extrn	 TXT_STOSD:byte
	 extrn	 TXT_STOSW:byte
	 extrn	 TXT_SUB:byte

	 extrn	 TXT_TEST:byte

	 extrn	 TXT_XCHG:byte
	 extrn	 TXT_XLAT:byte
	 extrn	 TXT_XOR:byte

	 extrn	 FMOD0:dword
	 extrn	 FMOD1:dword
	 extrn	 FMOD2:dword
	 extrn	 FMOD3:dword
	 extrn	 FMOD4:dword
	 extrn	 FMOD5:dword
	 extrn	 FMOD6:dword
	 extrn	 FMOD7:dword

	 extrn	 FTYP0:dword
	 extrn	 FTYP1:dword
	 extrn	 FTYP2:dword
	 extrn	 FTYP3:dword
	 extrn	 FTYP4:dword
	 extrn	 FTYP5:dword
	 extrn	 FTYP6:dword
	 extrn	 FTYP7:dword

	 extrn	 P@UNDEF:dword

TEXT	 ends			; End TEXT segment


INSTR	 segment use32 dword public 'data' ; Start INSTR segment
	 assume  ds:DGROUP

ILBL	 macro	 OPC

INSTR&OPC label  word

	 org	 INSTR_TAB+OPC*(type INSTR_TAB)
	 dd	 offset DGROUP:INSTR&OPC
	 org	 INSTR&OPC

	 endm

	 public  INSTR_TAB
INSTR_TAB dd	 256 dup (offset DGROUP:P@UNDEF) ; Initially it's all undefined

$$ASP	 =	 0
$$OSP	 =	 0

	 ILBL	 0		; 00
	 OPCODE  ADD
	 RM8
	 R8
	 EXIT

	 ILBL	 1		; 01
	 OPCODE  ADD
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 EXIT

	 ILBL	 2		; 02
	 OPCODE  ADD
	 R8
	 RM8
	 EXIT

	 ILBL	 3		; 03
	 OPCODE  ADD
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ILBL	 4		; 04
	 OPCODE  ADD
	 OPCODE  AL
	 IMM8
	 EXIT

	 ILBL	 5		; 05
	 OPCODE  ADD
	 IFOSP
	 OPCODE  EAX
	 IMM32
	 ELSEOSP
	 OPCODE  AX
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 6		; 06
	 IFOSP
	 OPCODE  PUSHD
	 ELSEOSP
	 OPCODE  PUSH
	 ENDOSP
	 OPCODE  ES
	 EXIT

	 ILBL	 7		; 07
	 IFOSP
	 OPCODE  POPD
	 ELSEOSP
	 OPCODE  POP
	 ENDOSP
	 OPCODE  ES
	 STACK1  WORD
	 EXIT

	 ILBL	 8		; 08
	 OPCODE  OR
	 RM8
	 R8
	 EXIT

	 ILBL	 9		; 09
	 OPCODE  OR
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 EXIT

	 ILBL	 10		; 0A
	 OPCODE  OR
	 R8
	 RM8
	 EXIT

	 ILBL	 11		; 0B
	 OPCODE  OR
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ILBL	 12		; 0C
	 OPCODE  OR
	 OPCODE  AL
	 IMM8
	 EXIT

	 ILBL	 13		; 0D
	 OPCODE  OR
	 IFOSP
	 OPCODE  EAX
	 IMM32
	 ELSEOSP
	 OPCODE  AX
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 14		; 0E
	 IFOSP
	 OPCODE  PUSHD
	 ELSEOSP
	 OPCODE  PUSH
	 ENDOSP
	 OPCODE  CS
	 EXIT

	 ILBL	 15		; 0F
	 ESC0F
;;;;;;;; EXIT

	 ILBL	 16		; 10
	 OPCODE  ADC
	 RM8
	 R8
	 EXIT

	 ILBL	 17		; 11
	 OPCODE  ADC
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 EXIT

	 ILBL	 18		; 12
	 OPCODE  ADC
	 R8
	 RM8
	 EXIT

	 ILBL	 19		; 13
	 OPCODE  ADC
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ILBL	 20		; 14
	 OPCODE  ADC
	 OPCODE  AL
	 IMM8
	 EXIT

	 ILBL	 21		; 15
	 OPCODE  ADC
	 IFOSP
	 OPCODE  EAX
	 IMM32
	 ELSEOSP
	 OPCODE  AX
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 22		; 16
	 IFOSP
	 OPCODE  PUSHD
	 ELSEOSP
	 OPCODE  PUSH
	 ENDOSP
	 OPCODE  SS
	 EXIT

	 ILBL	 23		; 17
	 IFOSP
	 OPCODE  POPD
	 ELSEOSP
	 OPCODE  POP
	 ENDOSP
	 OPCODE  SS
	 STACK1  WORD
	 EXIT

	 ILBL	 24		; 18
	 OPCODE  SBB
	 RM8
	 R8
	 EXIT

	 ILBL	 25		; 19
	 OPCODE  SBB
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 EXIT

	 ILBL	 26		; 1A
	 OPCODE  SBB
	 R8
	 RM8
	 EXIT

	 ILBL	 27		; 1B
	 OPCODE  SBB
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ILBL	 28		; 1C
	 OPCODE  SBB
	 OPCODE  AL
	 IMM8
	 EXIT

	 ILBL	 29		; 1D
	 OPCODE  SBB
	 IFOSP
	 OPCODE  EAX
	 IMM32
	 ELSEOSP
	 OPCODE  AX
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 30		; 1E
	 IFOSP
	 OPCODE  PUSHD
	 ELSEOSP
	 OPCODE  PUSH
	 ENDOSP
	 OPCODE  DS
	 EXIT

	 ILBL	 31		; 1F
	 IFOSP
	 OPCODE  POPD
	 ELSEOSP
	 OPCODE  POP
	 ENDOSP
	 OPCODE  DS
	 STACK1  WORD
	 EXIT

	 ILBL	 32		; 20
	 OPCODE  AND
	 RM8
	 R8
	 EXIT

	 ILBL	 33		; 21
	 OPCODE  AND
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 EXIT

	 ILBL	 34		; 22
	 OPCODE  AND
	 R8
	 RM8
	 EXIT

	 ILBL	 35		; 23
	 OPCODE  AND
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ILBL	 36		; 24
	 OPCODE  AND
	 OPCODE  AL
	 IMM8
	 EXIT

	 ILBL	 37		; 25
	 OPCODE  AND
	 IFOSP
	 OPCODE  EAX
	 IMM32
	 ELSEOSP
	 OPCODE  AX
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 38		; 26
	 SETPREF @PREF_ES

	 ILBL	 39		; 27
	 OPCODE  DAA
	 EXIT

	 ILBL	 40		; 28
	 OPCODE  SUB
	 RM8
	 R8
	 EXIT

	 ILBL	 41		; 29
	 OPCODE  SUB
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 EXIT

	 ILBL	 42		; 2A
	 OPCODE  SUB
	 R8
	 RM8
	 EXIT

	 ILBL	 43		; 2B
	 OPCODE  SUB
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ILBL	 44		; 2C
	 OPCODE  SUB
	 OPCODE  AL
	 IMM8
	 EXIT

	 ILBL	 45		; 2D
	 OPCODE  SUB
	 IFOSP
	 OPCODE  EAX
	 IMM32
	 ELSEOSP
	 OPCODE  AX
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 46		; 2E
	 SETPREF @PREF_CS

	 ILBL	 47		; 2F
	 OPCODE  DAS
	 EXIT

	 ILBL	 48		; 30
	 OPCODE  XOR
	 RM8
	 R8
	 EXIT

	 ILBL	 49		; 31
	 OPCODE  XOR
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 EXIT

	 ILBL	 50		; 32
	 OPCODE  XOR
	 R8
	 RM8
	 EXIT

	 ILBL	 51		; 33
	 OPCODE  XOR
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ILBL	 52		; 34
	 OPCODE  XOR
	 OPCODE  AL
	 IMM8
	 EXIT

	 ILBL	 53		; 35
	 OPCODE  XOR
	 IFOSP
	 OPCODE  EAX
	 IMM32
	 ELSEOSP
	 OPCODE  AX
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 54		; 36
	 SETPREF @PREF_SS

	 ILBL	 55		; 37
	 OPCODE  AAA
	 EXIT

	 ILBL	 56		; 38
	 OPCODE  CMP
	 RM8
	 R8
	 EXIT

	 ILBL	 57		; 39
	 OPCODE  CMP
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 EXIT

	 ILBL	 58		; 3A
	 OPCODE  CMP
	 R8
	 RM8
	 EXIT

	 ILBL	 59		; 3B
	 OPCODE  CMP
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ILBL	 60		; 3C
	 OPCODE  CMP
	 OPCODE  AL
	 IMM8
	 EXIT

	 ILBL	 61		; 3D
	 OPCODE  CMP
	 IFOSP
	 OPCODE  EAX
	 IMM32
	 ELSEOSP
	 OPCODE  AX
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 62		; 3E
	 SETPREF @PREF_DS

	 ILBL	 63		; 3F
	 OPCODE  AAS
	 EXIT

	 ILBL	 64		; 40
	 OPCODE  INC
	 IFOSP
	 OPCODE  EAX
	 ELSEOSP
	 OPCODE  AX
	 ENDOSP
	 EXIT

	 ILBL	 65		; 41
	 OPCODE  INC
	 IFOSP
	 OPCODE  ECX
	 ELSEOSP
	 OPCODE  CX
	 ENDOSP
	 EXIT

	 ILBL	 66		; 42
	 OPCODE  INC
	 IFOSP
	 OPCODE  EDX
	 ELSEOSP
	 OPCODE  DX
	 ENDOSP
	 EXIT

	 ILBL	 67		; 43
	 OPCODE  INC
	 IFOSP
	 OPCODE  EBX
	 ELSEOSP
	 OPCODE  BX
	 ENDOSP
	 EXIT

	 ILBL	 68		; 44
	 OPCODE  INC
	 IFOSP
	 OPCODE  ESP
	 ELSEOSP
	 OPCODE  SP
	 ENDOSP
	 EXIT

	 ILBL	 69		; 45
	 OPCODE  INC
	 IFOSP
	 OPCODE  EBP
	 ELSEOSP
	 OPCODE  BP
	 ENDOSP
	 EXIT

	 ILBL	 70		; 46
	 OPCODE  INC
	 IFOSP
	 OPCODE  ESI
	 ELSEOSP
	 OPCODE  SI
	 ENDOSP
	 EXIT

	 ILBL	 71		; 47
	 OPCODE  INC
	 IFOSP
	 OPCODE  EDI
	 ELSEOSP
	 OPCODE  DI
	 ENDOSP
	 EXIT

	 ILBL	 72		; 48
	 OPCODE  DEC
	 IFOSP
	 OPCODE  EAX
	 ELSEOSP
	 OPCODE  AX
	 ENDOSP
	 EXIT

	 ILBL	 73		; 49
	 OPCODE  DEC
	 IFOSP
	 OPCODE  ECX
	 ELSEOSP
	 OPCODE  CX
	 ENDOSP
	 EXIT

	 ILBL	 74		; 4A
	 OPCODE  DEC
	 IFOSP
	 OPCODE  EDX
	 ELSEOSP
	 OPCODE  DX
	 ENDOSP
	 EXIT

	 ILBL	 75		; 4B
	 OPCODE  DEC
	 IFOSP
	 OPCODE  EBX
	 ELSEOSP
	 OPCODE  BX
	 ENDOSP
	 EXIT

	 ILBL	 76		; 4C
	 OPCODE  DEC
	 IFOSP
	 OPCODE  ESP
	 ELSEOSP
	 OPCODE  SP
	 ENDOSP
	 EXIT

	 ILBL	 77		; 4D
	 OPCODE  DEC
	 IFOSP
	 OPCODE  EBP
	 ELSEOSP
	 OPCODE  BP
	 ENDOSP
	 EXIT

	 ILBL	 78		; 4E
	 OPCODE  DEC
	 IFOSP
	 OPCODE  ESI
	 ELSEOSP
	 OPCODE  SI
	 ENDOSP
	 EXIT

	 ILBL	 79		; 4F
	 OPCODE  DEC
	 IFOSP
	 OPCODE  EDI
	 ELSEOSP
	 OPCODE  DI
	 ENDOSP
	 EXIT

	 ILBL	 80		; 50
	 OPCODE  PUSH
	 IFOSP
	 OPCODE  EAX
	 ELSEOSP
	 OPCODE  AX
	 ENDOSP
	 EXIT

	 ILBL	 81		; 51
	 OPCODE  PUSH
	 IFOSP
	 OPCODE  ECX
	 ELSEOSP
	 OPCODE  CX
	 ENDOSP
	 EXIT

	 ILBL	 82		; 52
	 OPCODE  PUSH
	 IFOSP
	 OPCODE  EDX
	 ELSEOSP
	 OPCODE  DX
	 ENDOSP
	 EXIT

	 ILBL	 83		; 53
	 OPCODE  PUSH
	 IFOSP
	 OPCODE  EBX
	 ELSEOSP
	 OPCODE  BX
	 ENDOSP
	 EXIT

	 ILBL	 84		; 54
	 OPCODE  PUSH
	 IFOSP
	 OPCODE  ESP
	 ELSEOSP
	 OPCODE  SP
	 ENDOSP
	 EXIT

	 ILBL	 85		; 55
	 OPCODE  PUSH
	 IFOSP
	 OPCODE  EBP
	 ELSEOSP
	 OPCODE  BP
	 ENDOSP
	 EXIT

	 ILBL	 86		; 56
	 OPCODE  PUSH
	 IFOSP
	 OPCODE  ESI
	 ELSEOSP
	 OPCODE  SI
	 ENDOSP
	 EXIT

	 ILBL	 87		; 57
	 OPCODE  PUSH
	 IFOSP
	 OPCODE  EDI
	 ELSEOSP
	 OPCODE  DI
	 ENDOSP
	 EXIT

	 ILBL	 88		; 58
	 OPCODE  POP
	 IFOSP
	 OPCODE  EAX
	 STACK1  DWORD
	 ELSEOSP
	 OPCODE  AX
	 STACK1  WORD
	 ENDOSP
	 EXIT

	 ILBL	 89		; 59
	 OPCODE  POP
	 IFOSP
	 OPCODE  ECX
	 STACK1  DWORD
	 ELSEOSP
	 OPCODE  CX
	 STACK1  WORD
	 ENDOSP
	 EXIT

	 ILBL	 90		; 5A
	 OPCODE  POP
	 IFOSP
	 OPCODE  EDX
	 STACK1  DWORD
	 ELSEOSP
	 OPCODE  DX
	 STACK1  WORD
	 ENDOSP
	 EXIT

	 ILBL	 91		; 5B
	 OPCODE  POP
	 IFOSP
	 OPCODE  EBX
	 STACK1  DWORD
	 ELSEOSP
	 OPCODE  BX
	 STACK1  WORD
	 ENDOSP
	 EXIT

	 ILBL	 92		; 5C
	 OPCODE  POP
	 IFOSP
	 OPCODE  ESP
	 STACK1  DWORD
	 ELSEOSP
	 OPCODE  SP
	 STACK1  WORD
	 ENDOSP
	 EXIT

	 ILBL	 93		; 5D
	 OPCODE  POP
	 IFOSP
	 OPCODE  EBP
	 STACK1  DWORD
	 ELSEOSP
	 OPCODE  BP
	 STACK1  WORD
	 ENDOSP
	 EXIT

	 ILBL	 94		; 5E
	 OPCODE  POP
	 IFOSP
	 OPCODE  ESI
	 STACK1  DWORD
	 ELSEOSP
	 OPCODE  SI
	 STACK1  WORD
	 ENDOSP
	 EXIT

	 ILBL	 95		; 5F
	 OPCODE  POP
	 IFOSP
	 OPCODE  EDI
	 STACK1  DWORD
	 ELSEOSP
	 OPCODE  DI
	 STACK1  WORD
	 ENDOSP
	 EXIT

	 ILBL	 96		; 60
	 IFOSP
	 OPCODE  PUSHAD
	 ELSEOSP
	 OPCODE  PUSHA
	 ENDOSP
	 EXIT

	 ILBL	 97		; 61
	 IFOSP
	 OPCODE  POPAD
	 STACK1  POPAD
	 ELSEOSP
	 OPCODE  POPA
	 STACK1  POPA
	 ENDOSP
	 EXIT

	 ILBL	 98		; 62
	 OPCODE  BOUND
	 IFOSP
	 R32
	 RM32
	 DWIDTH  BNDD
	 ELSEOSP
	 R16
	 RM16
	 DWIDTH  BNDW
	 ENDOSP
	 EXIT

	 ILBL	 99		; 63
	 OPCODE  ARPL
	 RM16
	 R16
	 EXIT

	 ILBL	 100		; 64
	 SETPREF @PREF_FS

	 ILBL	 101		; 65
	 SETPREF @PREF_GS

	 ILBL	 102		; 66
	 SETPREF @PREF_OSP

	 ILBL	 103		; 67
	 SETPREF @PREF_ASP

	 ILBL	 104		; 68
	 OPCODE  PUSH
	 IFOSP
	 IMM32
	 ELSEOSP
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 105		; 69
	 OPCODE  IMUL
	 IFOSP
	 R32
	 RM32
	 IMM32
	 ELSEOSP
	 R16
	 RM16
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 106		; 6A
	 OPCODE  PUSH
	 IFOSP
	 IMM8D
	 ELSEOSP
	 IMM8W
	 ENDOSP
	 EXIT

	 ILBL	 107		; 6B
	 OPCODE  IMUL
	 IFOSP
	 R32
	 RM32
	 IMM8W
	 ELSEOSP
	 R16
	 RM16
	 IMM8W
	 ENDOSP
	 EXIT

	 ILBL	 108		; 6C
	 RPT	 0
	 OPCODE  INSB
	 IFASP
	 OPCODE  $EDI$
	 MODRM	 EDI
	 ELSEASP
	 MODRM	 DI
	 ENDASP
	 EXIT

	 ILBL	 109		; 6D
	 RPT	 0
	 IFOSP
	 OPCODE  INSD
	 ELSEOSP
	 OPCODE  INSW
	 ENDOSP
	 IFASP
	 OPCODE  $EDI$
	 MODRM	 EDI
	 ELSEASP
	 MODRM	 DI
	 ENDASP
	 EXIT

	 ILBL	 110		; 6E
	 RPT	 0
	 OPCODE  OUTSB
	 SRO
	 IFASP
	 OPCODE  $ESI$
	 MODRM	 ESI
	 ELSEASP
	 MODRM	 SI
	 ENDASP
	 EXIT

	 ILBL	 111		; 6F
	 RPT	 0
	 IFOSP
	 OPCODE  OUTSD
	 ELSEOSP
	 OPCODE  OUTSW
	 ENDOSP
	 SRO
	 IFASP
	 OPCODE  $ESI$
	 MODRM	 ESI
	 ELSEASP
	 MODRM	 SI
	 ENDASP
	 EXIT

	 ILBL	 112		; 70
	 OPCODE  JO
	 REL8
	 EXIT

	 ILBL	 113		; 71
	 OPCODE  JNO
	 REL8
	 EXIT

	 ILBL	 114		; 72
	 OPCODE  JC
	 REL8
	 EXIT

	 ILBL	 115		; 73
	 OPCODE  JNC
	 REL8
	 EXIT

	 ILBL	 116		; 74
	 OPCODE  JZ
	 REL8
	 EXIT

	 ILBL	 117		; 75
	 OPCODE  JNZ
	 REL8
	 EXIT

	 ILBL	 118		; 76
	 OPCODE  JBE
	 REL8
	 EXIT

	 ILBL	 119		; 77
	 OPCODE  JA
	 REL8
	 EXIT

	 ILBL	 120		; 78
	 OPCODE  JS
	 REL8
	 EXIT

	 ILBL	 121		; 79
	 OPCODE  JNS
	 REL8
	 EXIT

	 ILBL	 122		; 7A
	 OPCODE  JPE
	 REL8
	 EXIT

	 ILBL	 123		; 7B
	 OPCODE  JPO
	 REL8
	 EXIT

	 ILBL	 124		; 7C
	 OPCODE  JL
	 REL8
	 EXIT

	 ILBL	 125		; 7D
	 OPCODE  JGE
	 REL8
	 EXIT

	 ILBL	 126		; 7E
	 OPCODE  JLE
	 REL8
	 EXIT

	 ILBL	 127		; 7F
	 OPCODE  JG
	 REL8
	 EXIT

	 ILBL	 128		; 80
	 GRP1
	 RM8P
	 IMM8
	 EXIT

	 ILBL	 129		; 81
	 GRP1
	 IFOSP
	 RM32P
	 IMM32
	 ELSEOSP
	 RM16P
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 130		; 82
	 GRP1
	 RM8P
	 IMM8
	 EXIT

	 ILBL	 131		; 83
	 GRP1
	 IFOSP
	 RM32P
	 ELSEOSP
	 RM16P
	 ENDOSP
	 IMM8W
	 EXIT

	 ILBL	 132		; 84
	 OPCODE  TEST
	 RM8
	 R8
	 EXIT

	 ILBL	 133		; 85
	 OPCODE  TEST
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 EXIT

	 ILBL	 134		; 86
	 OPCODE  XCHG
	 R8
	 RM8
	 EXIT

	 ILBL	 135		; 87
	 OPCODE  XCHG
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ILBL	 136		; 88
	 OPCODE  MOV
	 RM8
	 R8
	 EXIT

	 ILBL	 137		; 89
	 OPCODE  MOV
	 IFOSP
	 RM32
	 R32
	 ELSEOSP
	 RM16
	 R16
	 ENDOSP
	 EXIT

	 ILBL	 138		; 8A
	 OPCODE  MOV
	 R8
	 RM8
	 EXIT

	 ILBL	 139		; 8B
	 OPCODE  MOV
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ILBL	 140		; 8C
	 IGNOREOSP
	 OPCODE  MOV
	 RM16
	 SREG
	 EXIT

	 ILBL	 141		; 8D
	 OPCODE  LEA
	 IFOSP
	 R32
	 RM32
	 ELSEOSP
	 R16
	 RM16
	 ENDOSP
	 EXIT

	 ILBL	 142		; 8E
	 IGNOREOSP
	 OPCODE  MOV
	 SREG
	 RM16
	 EXIT

	 ILBL	 143		; 8F
	 OPCODE  POP
	 IFOSP
	 RM32P
	 STACK2  DWORD
	 DWIDTH  POPD
	 ELSEOSP
	 RM16P
	 STACK2  WORD
	 DWIDTH  POPW
	 ENDOSP
	 EXIT

	 ILBL	 144		; 90
	 IGNOREOSP
;;;;;;;; OPCODE  XCHG
;;;;;;;; OPCODE  EAX@EAX
	 IFASP
	 OPCODE  NOPD
	 ELSEASP
	 OPCODE  NOP
	 ENDASP
	 EXIT

	 ILBL	 145		; 91
	 OPCODE  XCHG
	 IFOSP
	 OPCODE  EAX@ECX
	 ELSEOSP
	 OPCODE  AX@CX
	 ENDOSP
	 EXIT

	 ILBL	 146		; 92
	 OPCODE  XCHG
	 IFOSP
	 OPCODE  EAX@EDX
	 ELSEOSP
	 OPCODE  AX@DX
	 ENDOSP
	 EXIT

	 ILBL	 147		; 93
	 OPCODE  XCHG
	 IFOSP
	 OPCODE  EAX@EBX
	 ELSEOSP
	 OPCODE  AX@BX
	 ENDOSP
	 EXIT

	 ILBL	 148		; 94
	 OPCODE  XCHG
	 IFOSP
	 OPCODE  EAX@ESP
	 ELSEOSP
	 OPCODE  AX@SP
	 ENDOSP
	 EXIT

	 ILBL	 149		; 95
	 OPCODE  XCHG
	 IFOSP
	 OPCODE  EAX@EBP
	 ELSEOSP
	 OPCODE  AX@BP
	 ENDOSP
	 EXIT

	 ILBL	 150		; 96
	 OPCODE  XCHG
	 IFOSP
	 OPCODE  EAX@ESI
	 ELSEOSP
	 OPCODE  AX@SI
	 ENDOSP
	 EXIT

	 ILBL	 151		; 97
	 OPCODE  XCHG
	 IFOSP
	 OPCODE  EAX@EDI
	 ELSEOSP
	 OPCODE  AX@DI
	 ENDOSP
	 EXIT

	 ILBL	 152		; 98
	 IFOSP
	 OPCODE  CWDE
	 ELSEOSP
	 OPCODE  CBW
	 ENDOSP
	 EXIT

	 ILBL	 153		; 99
	 IFOSP
	 OPCODE  CDQ
	 ELSEOSP
	 OPCODE  CWD
	 ENDOSP
	 EXIT

	 ILBL	 154		; 9A
	 OPCODE  CALL
	 IFOSP
	 PTR16@32
	 ELSEOSP
	 PTR16@16
	 ENDOSP
	 EXIT

	 ILBL	 155		; 9B
	 SETPREF @PREF_WAIT

	 ILBL	 156		; 9C
	 IFOSP
	 OPCODE  PUSHFD
	 ELSEOSP
	 OPCODE  PUSHF
	 ENDOSP
	 EXIT

	 ILBL	 157		; 9D
	 IFOSP
	 OPCODE  POPFD
	 STACK1  DWORD
	 ELSEOSP
	 OPCODE  POPF
	 STACK1  WORD
	 ENDOSP
	 EXIT

	 ILBL	 158		; 9E
	 OPCODE  SAHF
	 EXIT

	 ILBL	 159		; 9F
	 OPCODE  LAHF
	 EXIT

	 ILBL	 160		; A0
	 OPCODE  MOV
	 OPCODE  AL
	 SRO
	 OPCODE  LBR
	 IFASP
	 DSP32	 1		; Data width is one byte
	 ELSEASP
	 DSP16	 1		; Data width is one byte
	 ENDASP
	 OPCODE  RBR
	 EXIT

	 ILBL	 161		; A1
	 OPCODE  MOV
	 IFOSP
	 OPCODE  EAX
	 ELSEOSP
	 OPCODE  AX
	 ENDOSP
	 SRO
	 OPCODE  LBR
	 IFASP
	 DSP32	 0		; Data width depends on OSP
	 ELSEASP
	 DSP16	 0		; Data width depends on OSP
	 ENDASP
	 OPCODE  RBR
	 EXIT

	 ILBL	 162		; A2
	 OPCODE  MOV
	 SRO
	 OPCODE  LBR
	 IFASP
	 DSP32	 1		; Data width is one byte
	 ELSEASP
	 DSP16	 1		; Data width is one byte
	 ENDASP
	 OPCODE  RBR@AL
	 EXIT

	 ILBL	 163		; A3
	 OPCODE  MOV
	 SRO
	 OPCODE  LBR
	 IFASP
	 DSP32	 0		; Data width depends on OSP
	 ELSEASP
	 DSP16	 0		; Data width depends on OSP
	 ENDASP
	 IFOSP
	 OPCODE  RBR@EAX
	 ELSEOSP
	 OPCODE  RBR@AX
	 ENDOSP
	 EXIT

	 ILBL	 164		; A4
	 RPT	 0
	 OPCODE  MOVSB
	 SRO
	 IFASP
	 OPCODE  $ESI$
	 MODRM	 ESI,EDI
	 ELSEASP
	 MODRM	 SI,DI
	 ENDASP
	 EXIT

	 ILBL	 165		; A5
	 RPT	 0
	 IFOSP
	 OPCODE  MOVSD
	 ELSEOSP
	 OPCODE  MOVSW
	 ENDOSP
	 SRO
	 IFASP
	 OPCODE  $ESI$
	 MODRM	 ESI,EDI
	 ELSEASP
	 MODRM	 SI,DI
	 ENDASP
	 EXIT

	 ILBL	 166		; A6
	 RPT	 1
	 OPCODE  CMPSB
	 SRO
	 IFASP
	 OPCODE  $ESI$
	 MODRM	 ESI,EDI
	 ELSEASP
	 MODRM	 SI,DI
	 ENDASP
	 EXIT

	 ILBL	 167		; A7
	 RPT	 1
	 IFOSP
	 OPCODE  CMPSD
	 ELSEOSP
	 OPCODE  CMPSW
	 ENDOSP
	 SRO
	 IFASP
	 OPCODE  $ESI$
	 MODRM	 ESI,EDI
	 ELSEASP
	 MODRM	 SI,DI
	 ENDASP
	 EXIT

	 ILBL	 168		; A8
	 OPCODE  TEST
	 OPCODE  AL
	 IMM8
	 EXIT

	 ILBL	 169		; A9
	 OPCODE  TEST
	 IFOSP
	 OPCODE  EAX
	 IMM32
	 ELSEOSP
	 OPCODE  AX
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 170		; AA
	 RPT	 0
	 OPCODE  STOSB
	 IFASP
	 OPCODE  $EDI$
	 MODRM	 EDI
	 ELSEASP
	 MODRM	 DI
	 ENDASP
	 EXIT

	 ILBL	 171		; AB
	 RPT	 0
	 IFOSP
	 OPCODE  STOSD
	 ELSEOSP
	 OPCODE  STOSW
	 ENDOSP
	 IFASP
	 OPCODE  $EDI$
	 MODRM	 EDI
	 ELSEASP
	 MODRM	 DI
	 ENDASP
	 EXIT

	 ILBL	 172		; AC
	 RPT	 0
	 OPCODE  LODSB
	 SRO
	 IFASP
	 OPCODE  $ESI$
	 MODRM	 ESI
	 ELSEASP
	 MODRM	 SI
	 ENDASP
	 EXIT

	 ILBL	 173		; AD
	 RPT	 0
	 IFOSP
	 OPCODE  LODSD
	 ELSEOSP
	 OPCODE  LODSW
	 ENDOSP
	 SRO
	 IFASP
	 OPCODE  $ESI$
	 MODRM	 ESI
	 ELSEASP
	 MODRM	 SI
	 ENDASP
	 EXIT

	 ILBL	 174		; AE
	 RPT	 1
	 OPCODE  SCASB
	 IFASP
	 OPCODE  $EDI$
	 MODRM	 EDI
	 ELSEASP
	 MODRM	 DI
	 ENDASP
	 EXIT

	 ILBL	 175		; AF
	 RPT	 1
	 IFOSP
	 OPCODE  SCASD
	 ELSEOSP
	 OPCODE  SCASW
	 ENDOSP
	 IFASP
	 OPCODE  $EDI$
	 MODRM	 EDI
	 ELSEASP
	 MODRM	 DI
	 ENDASP
	 EXIT

	 ILBL	 176		; B0
	 OPCODE  MOV
	 OPCODE  AL
	 IMM8
	 EXIT

	 ILBL	 177		; B1
	 OPCODE  MOV
	 OPCODE  CL
	 IMM8
	 EXIT

	 ILBL	 178		; B2
	 OPCODE  MOV
	 OPCODE  DL
	 IMM8
	 EXIT

	 ILBL	 179		; B3
	 OPCODE  MOV
	 OPCODE  BL
	 IMM8
	 EXIT

	 ILBL	 180		; B4
	 OPCODE  MOV
	 OPCODE  AH
	 IMM8
	 EXIT

	 ILBL	 181		; B5
	 OPCODE  MOV
	 OPCODE  CH
	 IMM8
	 EXIT

	 ILBL	 182		; B6
	 OPCODE  MOV
	 OPCODE  DH
	 IMM8
	 EXIT

	 ILBL	 183		; B7
	 OPCODE  MOV
	 OPCODE  BH
	 IMM8
	 EXIT

	 ILBL	 184		; B8
	 OPCODE  MOV
	 IFOSP
	 OPCODE  EAX
	 IMM32
	 ELSEOSP
	 OPCODE  AX
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 185		; B9
	 OPCODE  MOV
	 IFOSP
	 OPCODE  ECX
	 IMM32
	 ELSEOSP
	 OPCODE  CX
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 186		; BA
	 OPCODE  MOV
	 IFOSP
	 OPCODE  EDX
	 IMM32
	 ELSEOSP
	 OPCODE  DX
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 187		; BB
	 OPCODE  MOV
	 IFOSP
	 OPCODE  EBX
	 IMM32
	 ELSEOSP
	 OPCODE  BX
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 188		; BC
	 OPCODE  MOV
	 IFOSP
	 OPCODE  ESP
	 IMM32
	 ELSEOSP
	 OPCODE  SP
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 189		; BD
	 OPCODE  MOV
	 IFOSP
	 OPCODE  EBP
	 IMM32
	 ELSEOSP
	 OPCODE  BP
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 190		; BE
	 OPCODE  MOV
	 IFOSP
	 OPCODE  ESI
	 IMM32
	 ELSEOSP
	 OPCODE  SI
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 191		; BF
	 OPCODE  MOV
	 IFOSP
	 OPCODE  EDI
	 IMM32
	 ELSEOSP
	 OPCODE  DI
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 192		; C0
	 GRP2
	 RM8P
	 IMM8
	 EXIT

	 ILBL	 193		; C1
	 GRP2
	 IFOSP
	 RM32P
	 ELSEOSP
	 RM16P
	 ENDOSP
	 IMM8
	 EXIT

	 ILBL	 194		; C2
	 IFOSP
	 OPCODE  RETD
	 STACK1  DWORD
	 ELSEOSP
	 OPCODE  RET
	 STACK1  WORD
	 ENDOSP
	 IMM16
	 EXIT

	 ILBL	 195		; C3
	 IFOSP
	 OPCODE  RETD
	 STACK1  DWORD
	 ELSEOSP
	 OPCODE  RET
	 STACK1  WORD
	 ENDOSP
	 EXIT

	 ILBL	 196		; C4
	 OPCODE  LES
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

	 ILBL	 197		; C5
	 OPCODE  LDS
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

	 ILBL	 198		; C6
	 OPCODE  MOV
	 RM8P
	 IMM8
	 EXIT

	 ILBL	 199		; C7
	 OPCODE  MOV
	 IFOSP
	 RM32P
	 IMM32
	 ELSEOSP
	 RM16P
	 IMM16
	 ENDOSP
	 EXIT

	 ILBL	 200		; C8
	 IFOSP
	 OPCODE  ENTERD
	 ELSEOSP
	 OPCODE  ENTER
	 ENDOSP
	 IMM16
	 IMM8
	 EXIT

	 ILBL	 201		; C9
	 IFOSP
	 OPCODE  LEAVED
	 ELSEOSP
	 OPCODE  LEAVE
	 ENDOSP
	 EXIT

	 ILBL	 202		; CA
	 IFOSP
	 OPCODE  RETFD
	 STACK1  PTR32
	 ELSEOSP
	 OPCODE  RETF
	 STACK1  PTR16
	 ENDOSP
	 IMM16
	 EXIT

	 ILBL	 203		; CB
	 IFOSP
	 OPCODE  RETFD
	 STACK1  PTR32
	 ELSEOSP
	 OPCODE  RETF
	 STACK1  PTR16
	 ENDOSP
	 EXIT

	 ILBL	 204		; CC
	 OPCODE  INT
	 DWIDTH  INT		; *MUST* immediately follow the OPCODE
	 OPCODE  03
	 INTMSG  03
	 EXIT

	 ILBL	 205		; CD
	 OPCODE  INT
	 DWIDTH  INT		; *MUST* immediately follow the OPCODE
	 IMM8
	 INTMSG  00
	 EXIT

	 ILBL	 206		; CE
	 OPCODE  INTO
	 DWIDTH  INT		; *MUST* immediately follow the OPCODE
	 INTMSG  04
	 EXIT

	 ILBL	 207		; CF
	 IFOSP
	 OPCODE  IRETD
	 STACK1  PTR32F
	 ELSEOSP
	 OPCODE  IRET
	 STACK1  PTR16F
	 ENDOSP
	 EXIT

	 ILBL	 208		; D0
	 GRP2
	 RM8P
	 OPCODE  @1
	 EXIT

	 ILBL	 209		; D1
	 GRP2
	 IFOSP
	 RM32P
	 ELSEOSP
	 RM16P
	 ENDOSP
	 OPCODE  @1
	 EXIT

	 ILBL	 210		; D2
	 GRP2
	 RM8P
	 OPCODE  @CL
	 EXIT

	 ILBL	 211		; D3
	 GRP2
	 IFOSP
	 RM32P
	 ELSEOSP
	 RM16P
	 ENDOSP
	 OPCODE  @CL
	 EXIT

	 ILBL	 212		; D4
	 OPCODE  AAM
	 IMM8
	 EXIT

	 ILBL	 213		; D5
	 OPCODE  AAD
	 IMM8
	 EXIT

	 ILBL	 214		; D6 -- Undocumented
	 OPCODE  SALC		; Smear CF throughout AL
	 EXIT

	 ILBL	 215		; D7
	 OPCODE  XLAT
	 SRO
	 IFASP
	 OPCODE  $EBX$
	 MODRM	 EBX
	 ELSEASP
	 MODRM	 BX
	 ENDASP
	 DWIDTH  XLAT
	 EXIT

	 ILBL	 216		; D8
	 FLOP	 0
	 EXIT

	 ILBL	 217		; D9
	 FLOP	 1
	 EXIT

	 ILBL	 218		; DA
	 FLOP	 2
	 EXIT

	 ILBL	 219		; DB
	 FLOP	 3
	 EXIT

	 ILBL	 220		; DC
	 FLOP	 4
	 EXIT

	 ILBL	 221		; DD
	 FLOP	 5
	 EXIT

	 ILBL	 222		; DE
	 FLOP	 6
	 EXIT

	 ILBL	 223		; DF
	 FLOP	 7
	 EXIT

	 ILBL	 224		; E0
	 IFASP
	 OPCODE  LOOPDNE
	 ELSEASP
	 OPCODE  LOOPNE
	 ENDASP
	 REL8
	 EXIT

	 ILBL	 225		; E1
	 IFASP
	 OPCODE  LOOPDE
	 ELSEASP
	 OPCODE  LOOPE
	 ENDASP
	 REL8
	 EXIT

	 ILBL	 226		; E2
	 IFASP
	 OPCODE  LOOPD
	 ELSEASP
	 OPCODE  LOOP
	 ENDASP
	 REL8
	 EXIT

	 ILBL	 227		; E3
	 IFASP
	 OPCODE  JECXZ
	 ELSEASP
	 OPCODE  JCXZ
	 ENDASP
	 REL8
	 EXIT

	 ILBL	 228		; E4
	 OPCODE  IN
	 OPCODE  AL
	 IMM8
	 EXIT

	 ILBL	 229		; E5
	 OPCODE  IN
	 IFOSP
	 OPCODE  EAX
	 ELSEOSP
	 OPCODE  AX
	 ENDOSP
	 IMM8
	 EXIT

	 ILBL	 230		; E6
	 OPCODE  OUT
	 IMM8
	 OPCODE  @AL
	 EXIT

	 ILBL	 231		; E7
	 OPCODE  OUT
	 IMM8
	 IFOSP
	 OPCODE  @EAX
	 ELSEOSP
	 OPCODE  @AX
	 ENDOSP
	 EXIT

	 ILBL	 232		; E8
	 OPCODE  CALL
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ILBL	 233		; E9
	 OPCODE  JMP
	 IFOSP
	 REL32
	 ELSEOSP
	 REL16
	 ENDOSP
	 EXIT

	 ILBL	 234		; EA
	 OPCODE  JMP
	 IFOSP
	 PTR16@32
	 ELSEOSP
	 PTR16@16
	 ENDOSP
	 EXIT

	 ILBL	 235		; EB
	 OPCODE  JMP
	 REL8
	 EXIT

	 ILBL	 236		; EC
	 OPCODE  IN
	 OPCODE  AL@DX
	 EXIT

	 ILBL	 237		; ED
	 OPCODE  IN
	 IFOSP
	 OPCODE  EAX@DX
	 ELSEOSP
	 OPCODE  AX@DX
	 ENDOSP
	 EXIT

	 ILBL	 238		; EE
	 OPCODE  OUT
	 OPCODE  DX@AL
	 EXIT

	 ILBL	 239		; EF
	 OPCODE  OUT
	 IFOSP
	 OPCODE  DX@EAX
	 ELSEOSP
	 OPCODE  DX@AX
	 ENDOSP
	 EXIT

	 ILBL	 240		; F0
	 SETPREF @PREF_LOCK

	 ILBL	 241		; F1
	 OPCODE  ICE
	 DWIDTH  INT		; *MUST* immediately follow the OPCODE
	 OPCODE  01
	 INTMSG  01
	 EXIT

	 ILBL	 242		; F2
	 SETPREF @PREF_REPNE

	 ILBL	 243		; F3
	 SETPREF @PREF_REPE

	 ILBL	 244		; F4
	 OPCODE  HLT
	 EXIT

	 ILBL	 245		; F5
	 OPCODE  CMC
	 EXIT

	 ILBL	 246		; F6
	 GRP3
	 RM8P
	 GRP3Z	 8
	 EXIT

	 ILBL	 247		; F7
	 GRP3
	 IFOSP
	 RM32P
	 GRP3Z	 32
	 ELSEOSP
	 RM16P
	 GRP3Z	 16
	 ENDOSP
	 EXIT

	 ILBL	 248		; F8
	 OPCODE  CLC
	 EXIT

	 ILBL	 249		; F9
	 OPCODE  STC
	 EXIT

	 ILBL	 250		; FA
	 OPCODE  CLI
	 EXIT

	 ILBL	 251		; FB
	 OPCODE  STI
	 EXIT

	 ILBL	 252		; FC
	 OPCODE  CLD
	 EXIT

	 ILBL	 253		; FD
	 OPCODE  STD
	 EXIT

	 ILBL	 254		; FE
	 GRP4
	 RM8P
	 EXIT

	 ILBL	 255		; FF
	 GRP5
	 IFOSP
	 RM32P
	 ELSEOSP
	 RM16P
	 ENDOSP
	 EXIT

INSTR	 ends			; End INSTR segment

	 MEND			; End INT1_TAB module
