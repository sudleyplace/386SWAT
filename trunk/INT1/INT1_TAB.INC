;' $Header:   P:/PVCS/386SWAT/INT1/INT1_TAB.INV   1.4   20 Sep 1994 16:58:56   BOB  $
;
; (C) Copyright 1987-94 Qualitas, Inc.	All rights reserved.
;
; INT1_TAB.INC
;
; Macros for 386SWAT's interrupt handlers
;

IPROC	 macro	 ADDR,LBL,SUF
LBL&SUF  dd	 offset ADDR
	 endm			; IPROC


MLBL	 macro	 LBL1,CNT,LBL0
	 dd	 LBL1&CNT-LBL0&CNT
	 endm			; MLBL


IFOSP	 macro
$$OSP	 =	 $$OSP+1
	 IPROC	 PGROUP:@IFOSP,$IFOSP,%$$OSP
	 MLBL	 $ELSEOSP,%$$OSP,$IFOSP
	 endm			; IFOSP


IFOSP2	 macro
$$OSP	 =	 $$OSP+1
	 IPROC	 PGROUP:@IFOSP2,$IFOSP,%$$OSP
	 MLBL	 $ELSEOSP,%$$OSP,$IFOSP
	 endm			; IFOSP2


ELSEOSP  macro
	 IPROC	 PGROUP:@ELSEOSP,$ELSEOSP,%$$OSP
	 MLBL	 $ENDOSP,%$$OSP,$ELSEOSP
	 endm			; ELSEOSP


ELSEOSP2 macro
	 IPROC	 PGROUP:@ELSEOSP2,$ELSEOSP,%$$OSP
	 MLBL	 $ENDOSP,%$$OSP,$ELSEOSP
	 endm			; ELSEOSP2


ENDOSP	 macro
	 IPROC	 PGROUP:@ENDOSP,$ENDOSP,%$$OSP
	 dd	 0
	 endm			; ENDOSP


IGNOREOSP macro
	 IPROC	 PGROUP:@IGNOREOSP
	 endm			; IGNOREOSP


IFASP	 macro
$$ASP	 =	 $$ASP+1
	 IPROC	 PGROUP:@IFASP,$IFASP,%$$ASP
	 MLBL	 $ELSEASP,%$$ASP,$IFASP
	 endm			; IFASP


ELSEASP  macro
	 IPROC	 PGROUP:@ELSEASP,$ELSEASP,%$$ASP
	 MLBL	 $ENDASP,%$$ASP,$ELSEASP
	 endm			; ELSEASP


ENDASP	 macro
	 IPROC	 PGROUP:@ENDASP,$ENDASP,%$$ASP
	 dd	 0
	 endm			; ENDASP


R8	 macro
	 dd	 offset PGROUP:@R8
	 endm			; R8


R16	 macro
	 dd	 offset PGROUP:@R16
	 endm			; R16


R32	 macro
	 dd	 offset PGROUP:@R32
	 endm			; R32


CR32	 macro
	 dd	 offset PGROUP:@CR32
	 endm			; CR32


DR32	 macro
	 dd	 offset PGROUP:@DR32
	 endm			; DR32


TR32	 macro
	 dd	 offset PGROUP:@TR32
	 endm			; TR32


SR32	 macro
	 dd	 offset PGROUP:@SR32
	 endm			; SR32


RM8	 macro
	 dd	 offset PGROUP:@RM8
	 endm			; RM8


RM16	 macro
	 dd	 offset PGROUP:@RM16
	 endm			; RM16


RM32	 macro
	 dd	 offset PGROUP:@RM32
	 endm			; RM32


RM64	 macro
	 dd	 offset PGROUP:@RM64
	 endm			; RM64


RM8P	 macro
	 dd	 offset PGROUP:@RM8P
	 endm			; RM8P


RM16P	 macro
	 dd	 offset PGROUP:@RM16P
	 endm			; RM16P


RM32P	 macro
	 dd	 offset PGROUP:@RM32P
	 endm			; RM32P


IMM8	 macro
	 dd	 offset PGROUP:@IMM8
	 endm			; IMM8


IMM8D	 macro
	 dd	 offset PGROUP:@IMM8D
	 endm			; IMM8D


IMM8W	 macro
	 dd	 offset PGROUP:@IMM8W
	 endm			; IMM8W


IMM16	 macro
	 dd	 offset PGROUP:@IMM16
	 endm			; IMM16


IMM32	 macro
	 dd	 offset PGROUP:@IMM32
	 endm			; IMM32


DSP16	 macro	 DSP
	 dd	 offset PGROUP:@DSP16
	 dd	 DSP
	 endm			; DSP16


DSP32	 macro	 DSP
	 dd	 offset PGROUP:@DSP32
	 dd	 DSP
	 endm			; DSP32


ESC0F	 macro
	 dd	 offset PGROUP:@ESC0F
	 endm			; ESC0F


RPT	 macro	 NUM
	 dd	 offset PGROUP:@RPT
	 dd	 NUM
	 endm			; RPT


OPCODE	 macro	 INSTR
	 dd	 offset PGROUP:@OPCODE
	 dd	 offset DGROUP:TXT_&INSTR
	 endm			; OPCODE


EXIT	 macro
	 dd	 offset PGROUP:@EXIT
	 endm			; EXIT


STACK1	 macro	 TYP
	 dd	 offset PGROUP:@STACK1
	 dd	 @DWIDTH_&TYP
	 endm			; STACK1


STACK2	 macro	 TYP
	 dd	 offset PGROUP:@STACK2
	 dd	 @DWIDTH_&TYP
	 endm			; STACK2


SETPREF  macro	 PREF
	 dd	 offset PGROUP:@SETPREF
	 dd	 PREF
	 endm			; SETPREF


DWIDTH	 macro	 DWID
	 dd	 offset PGROUP:@DWIDTH
	 dd	 @DWIDTH_&DWID
	 endm			; DWIDTH


MODRM	 macro	 R1,R2
	 dd	 offset PGROUP:@MODRM1
	 dd	 (00b shl $MOD) or (000b shl $REG) or (@&R1 shl $RM)
ifnb <R2>
	 dd	 offset PGROUP:@MODRM2
	 dd	 (00b shl $MOD) or (000b shl $REG) or (@&R2 shl $RM)
endif
	 endm			; MODRM


SRO	 macro
	 dd	 offset PGROUP:@SRO
	 endm			; SRO


REL8	 macro
	 dd	 offset PGROUP:@REL8
	 endm			; REL8


REL16	 macro
	 dd	 offset PGROUP:@REL16
	 endm			; REL16


REL32	 macro
	 dd	 offset PGROUP:@REL32
	 endm			; REL32


GRP1	 macro
	 dd	 offset PGROUP:@GRP1
	 endm			; GRP1


GRP2	 macro
	 dd	 offset PGROUP:@GRP2
	 endm			; GRP2


GRP3	 macro
	 dd	 offset PGROUP:@GRP3
	 endm			; GRP3


GRP3Z	 macro	 DWID
	 dd	 offset PGROUP:@GRP3Z
	 dd	 DWID
	 endm			; GRP3Z


GRP4	 macro
	 dd	 offset PGROUP:@GRP4
	 endm			; GRP4


GRP5	 macro
	 dd	 offset PGROUP:@GRP5
	 endm			; GRP5


GRP6	 macro
	 dd	 offset PGROUP:@GRP6
	 endm			; GRP6


GRP7	 macro
	 dd	 offset PGROUP:@GRP7
	 endm			; GRP7


GRP8	 macro
	 dd	 offset PGROUP:@GRP8
	 endm			; GRP8


SREG	 macro
	 dd	 offset PGROUP:@SREG
	 endm			; SREG


PTR16@16 macro
	 dd	 offset PGROUP:@PTR16@16
	 endm			; PTR16@16


PTR16@32 macro
	 dd	 offset PGROUP:@PTR16@32
	 endm			; PTR16@32


FLOP	 macro	 REG
	 dd	 offset PGROUP:@FLOP
	 dd	 offset PGROUP:@FREG&REG
	 dd	 offset DGROUP:FMOD&REG
	 dd	 offset DGROUP:FTYP&REG
	 endm			; FLOP


INTMSG	 macro	 TYP
	 dd	 offset PGROUP:@INTMSG
	 dd	 TYP		; 0 = two-byte opcode, INT # precedes
				; Otherwise, TYP = INT #
	 endm			; INTMSG


