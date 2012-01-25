;' $Header:   P:/PVCS/386SWAT/SWAT_AFL.ASV   1.8   21 Aug 1997 15:00:22   BOB  $
	title	SWAT_AFL -- 386SWAT Autofault Functions
	page	58,122
	name	SWAT_AFL

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-2002 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, July, 1994.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include CPUFLAGS.INC
	include ALLMEM.INC
	include IOPBITS.INC
	include MOVSPR.INC
	include OPCODES.INC

	include SWAT_COM.INC
	include SWAT_MOD.INC
	include SWAT_SEG.INC
	include INT1_FNS.INC
.list


DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC4_FLAG:dword
	include SWAT_LC4.INC

	extrn	WINBASE:dword

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	ERRMSG:byte
	extrn	ERRCODE:dword
	extrn	EA1MODE:word
	extrn	EA1TSEL:word
	extrn	EA1SEL:word
	extrn	EA1BASE:dword
	extrn	EA1OFF:dword
	extrn	EA1LIM:dword
	extrn	EA1WID:dword

	extrn	EA2MODE:word
	extrn	EA2SEL:word
	extrn	EA2OFF:dword
	extrn	EA2LIM:dword
	extrn	EA2WID:dword

	public	LAST_AFLERR,LAST_AFLWIN
LAST_AFLERR dd	-1		; Offset in DGROUP of last error message (-1=none)
LAST_AFLWIN dd	?		; ...			   window descriptor

	public	SAVE_CR2,SAVE_CR3,SAVE_CR4,SAVE_PDE,SAVE_PTE
SAVE_CR2 dd	?		; Save area for CR2 (Page Fault linear address)
SAVE_CR3 dd	?		; ...		CR3 (Page Directory base address)
SAVE_CR4 dd	?		; ...		CR4 (Feature Determination register)
SAVE_PDE dd	?		; ...		Page Directory entry
SAVE_PTE dd	?		; ...		Page Table ...

	public	PREFLAGS
PREFLAGS dd	?		; Prefix flags

	public	AUTO_CPL,AUTO_IOPL,AUTO_ARW,AUTO_CS,AUTO_DS,AUTO_SS,AUTO_LDT
AUTO_CPL dw	?		; Current Privilege Level
AUTO_IOPL dw	?		; I/O ...
AUTO_ARW dw	?		; A/R word
AUTO_CS dw	?		; Code selector
AUTO_DS dw	?		; Data ...
AUTO_SS dw	?		; Stack ...
AUTO_LDT dw	?		; LDT	...

	public	INTNO
INTNO	db	?		; Interrupt #

DATA	ends			; End DATA segment


WTXT	segment use32 byte public 'wdata' ; Start WTXT segment
	assume	ds:WGROUP

ACT_MAC macro	TAB,COD,ACT
	local	L1
L1	label	dword

; If ACT is missing, it is assumed that this entry has
; the same action as the last.	Otherwise, there's a
; new action to be counted.

ifnb <ACT>
CNT	=	CNT+1		; Count in a new action
endif				; IFNB <ACT>

; Place the action byte into the appropriate table

if (COD and 0FFh) eq @OPCOD_2ND
	org	TAB&2+COD/256	; Put into the secondary opcode table
else
	org	TAB&1+COD	; Put into the primary opcode table
endif
	db	CNT

	org	L1
ifnb <ACT>
	dd	offset PGROUP:ACT ; With matching action
endif				; IFNB <ACT>

	endm			; ACT_MAC


	public	GPFTAB1,GPFTAB2
GPFTAB1 db	256 dup (0)	; Primary opcode index for GP Faults
GPFTAB2 db	256 dup (0)	; Secondary ...

	public	GPFACT
GPFACT	label	dword		; GP Fault action table
	dd	offset PGROUP:AUTO_GPF_UNK ; Unknown GP Fault
CNT	=	0		; Initialize table index
	ACT_MAC GPFTAB,@OPCOD_CLI,	   AUTO_GPF_CLISTI
	ACT_MAC GPFTAB,@OPCOD_STI

	ACT_MAC GPFTAB,@OPCOD_PUSHF,	   AUTO_GPF_PPF
	ACT_MAC GPFTAB,@OPCOD_POPF

	ACT_MAC GPFTAB,@OPCOD_INT,	   AUTO_GPF_INT
	ACT_MAC GPFTAB,@OPCOD_INT3,	   AUTO_GPF_INT3
	ACT_MAC GPFTAB,@OPCOD_INTO,	   AUTO_GPF_INTO

	ACT_MAC GPFTAB,@OPCOD_IRET,	   AUTO_GPF_IRET

	ACT_MAC GPFTAB,@OPCOD_INIB,	   AUTO_GPF_INIB
	ACT_MAC GPFTAB,@OPCOD_INIW,	   AUTO_GPF_INIW
	ACT_MAC GPFTAB,@OPCOD_INDB,	   AUTO_GPF_INDB
	ACT_MAC GPFTAB,@OPCOD_INDW,	   AUTO_GPF_INDW
	ACT_MAC GPFTAB,@OPCOD_OUTIB,	   AUTO_GPF_OUTIB
	ACT_MAC GPFTAB,@OPCOD_OUTIW,	   AUTO_GPF_OUTIW
	ACT_MAC GPFTAB,@OPCOD_OUTDB,	   AUTO_GPF_OUTDB
	ACT_MAC GPFTAB,@OPCOD_OUTDW,	   AUTO_GPF_OUTDW
	ACT_MAC GPFTAB,@OPCOD_INSB,	   AUTO_GPF_INSB
	ACT_MAC GPFTAB,@OPCOD_INSW,	   AUTO_GPF_INSW
	ACT_MAC GPFTAB,@OPCOD_OUTSB,	   AUTO_GPF_OUTSB
	ACT_MAC GPFTAB,@OPCOD_OUTSW,	   AUTO_GPF_OUTSW

	ACT_MAC GPFTAB,@OPCOD_CLTS,	   AUTO_GPF_PL0
	ACT_MAC GPFTAB,@OPCOD_HLT
	ACT_MAC GPFTAB,@OPCOD_INVD
	ACT_MAC GPFTAB,@OPCOD_WBINVD
	ACT_MAC GPFTAB,@OPCOD_MOV_R32_CRn
	ACT_MAC GPFTAB,@OPCOD_MOV_R32_DRn
	ACT_MAC GPFTAB,@OPCOD_MOV_R32_TRn
	ACT_MAC GPFTAB,@OPCOD_MOV_CRn_R32
	ACT_MAC GPFTAB,@OPCOD_MOV_DRn_R32
	ACT_MAC GPFTAB,@OPCOD_MOV_TRn_R32
	ACT_MAC GPFTAB,@OPCOD_RDMSR,	   AUTO_GPF_RDMSR
	ACT_MAC GPFTAB,@OPCOD_WRMSR,	   AUTO_GPF_WRMSR
	ACT_MAC GPFTAB,@OPCOD_GRP6,	   AUTO_GPF_GRP6
	ACT_MAC GPFTAB,@OPCOD_GRP7,	   AUTO_GPF_GRP7

	ACT_MAC GPFTAB,@OPCOD_JCCLO+0,	   AUTO_GPF_REL8
	ACT_MAC GPFTAB,@OPCOD_JCCLO+1
	ACT_MAC GPFTAB,@OPCOD_JCCLO+2
	ACT_MAC GPFTAB,@OPCOD_JCCLO+3
	ACT_MAC GPFTAB,@OPCOD_JCCLO+4
	ACT_MAC GPFTAB,@OPCOD_JCCLO+5
	ACT_MAC GPFTAB,@OPCOD_JCCLO+6
	ACT_MAC GPFTAB,@OPCOD_JCCLO+7
	ACT_MAC GPFTAB,@OPCOD_JMPS
	ACT_MAC GPFTAB,@OPCOD_JCXZ
	ACT_MAC GPFTAB,@OPCOD_LOOP
	ACT_MAC GPFTAB,@OPCOD_LOOPE
	ACT_MAC GPFTAB,@OPCOD_LOOPNE

	ACT_MAC GPFTAB,@OPCOD_JCCLO2+0,    AUTO_GPF_RELX
	ACT_MAC GPFTAB,@OPCOD_JCCLO2+1
	ACT_MAC GPFTAB,@OPCOD_JCCLO2+2
	ACT_MAC GPFTAB,@OPCOD_JCCLO2+3
	ACT_MAC GPFTAB,@OPCOD_JCCLO2+4
	ACT_MAC GPFTAB,@OPCOD_JCCLO2+5
	ACT_MAC GPFTAB,@OPCOD_JCCLO2+6
	ACT_MAC GPFTAB,@OPCOD_JCCLO2+7
	ACT_MAC GPFTAB,@OPCOD_JMPN
	ACT_MAC GPFTAB,@OPCOD_CALLN

	ACT_MAC GPFTAB,@OPCOD_JMPF,	   AUTO_GPF_FJMP
	ACT_MAC GPFTAB,@OPCOD_CALLF
	ACT_MAC GPFTAB,@OPCOD_GRP5,	   AUTO_GPF_GRP5

	ACT_MAC GPFTAB,@OPCOD_LODSB,	   AUTO_GPF_CHK_DSR
	ACT_MAC GPFTAB,@OPCOD_LODSW

	ACT_MAC GPFTAB,@OPCOD_SCASB,	   AUTO_GPF_CHK_ESR
	ACT_MAC GPFTAB,@OPCOD_SCASW

	ACT_MAC GPFTAB,@OPCOD_STOSB,	   AUTO_GPF_CHK_ESW
	ACT_MAC GPFTAB,@OPCOD_STOSW

	ACT_MAC GPFTAB,@OPCOD_MOVSB,	   AUTO_GPF_CHK_DSR_ESW
	ACT_MAC GPFTAB,@OPCOD_MOVSW

	ACT_MAC GPFTAB,@OPCOD_CMPSB,	   AUTO_GPF_CHK_DSR_ESR
	ACT_MAC GPFTAB,@OPCOD_CMPSW

	ACT_MAC GPFTAB,@OPCOD_MOVR8,	   AUTO_GPF_LIM
	ACT_MAC GPFTAB,@OPCOD_MOVR16
	ACT_MAC GPFTAB,@OPCOD_MOVALM
	ACT_MAC GPFTAB,@OPCOD_MOVAXM
	ACT_MAC GPFTAB,@OPCOD_MOVMAL
	ACT_MAC GPFTAB,@OPCOD_MOVMAX
	ACT_MAC GPFTAB,@OPCOD_MOVAXIM
	ACT_MAC GPFTAB,@OPCOD_RET
	ACT_MAC GPFTAB,@OPCOD_RETF
	ACT_MAC GPFTAB,@OPCOD_RETP
	ACT_MAC GPFTAB,@OPCOD_RETFP
	ACT_MAC GPFTAB,@OPCOD_ADDMR8
	ACT_MAC GPFTAB,@OPCOD_ADDMR16
	ACT_MAC GPFTAB,@OPCOD_ADDR8M
	ACT_MAC GPFTAB,@OPCOD_ADDR16M
	ACT_MAC GPFTAB,@OPCOD_ORMR8
	ACT_MAC GPFTAB,@OPCOD_ORMR16
	ACT_MAC GPFTAB,@OPCOD_ORR8M
	ACT_MAC GPFTAB,@OPCOD_ORR16M
	ACT_MAC GPFTAB,@OPCOD_ADCMR8
	ACT_MAC GPFTAB,@OPCOD_ADCMR16
	ACT_MAC GPFTAB,@OPCOD_ADCR8M
	ACT_MAC GPFTAB,@OPCOD_ADCR16M
	ACT_MAC GPFTAB,@OPCOD_SBBMR8
	ACT_MAC GPFTAB,@OPCOD_SBBMR16
	ACT_MAC GPFTAB,@OPCOD_SBBR8M
	ACT_MAC GPFTAB,@OPCOD_SBBR16M
	ACT_MAC GPFTAB,@OPCOD_ANDMR8
	ACT_MAC GPFTAB,@OPCOD_ANDMR16
	ACT_MAC GPFTAB,@OPCOD_ANDR8M
	ACT_MAC GPFTAB,@OPCOD_ANDR16M
	ACT_MAC GPFTAB,@OPCOD_SUBMR8
	ACT_MAC GPFTAB,@OPCOD_SUBMR16
	ACT_MAC GPFTAB,@OPCOD_SUBR8M
	ACT_MAC GPFTAB,@OPCOD_SUBR16M
	ACT_MAC GPFTAB,@OPCOD_XORMR8
	ACT_MAC GPFTAB,@OPCOD_XORMR16
	ACT_MAC GPFTAB,@OPCOD_XORR8M
	ACT_MAC GPFTAB,@OPCOD_XORR16M
	ACT_MAC GPFTAB,@OPCOD_CMPMR8
	ACT_MAC GPFTAB,@OPCOD_CMPMR16
	ACT_MAC GPFTAB,@OPCOD_CMPR8M
	ACT_MAC GPFTAB,@OPCOD_CMPR16M
	ACT_MAC GPFTAB,@OPCOD_GRP1R8I
	ACT_MAC GPFTAB,@OPCOD_GRP1R16I
	ACT_MAC GPFTAB,@OPCOD_GRP1R16S

; The following actions are commented out because the action
; we would take is the default initial action before splitting cases
; (check for EIP after fetch beyond CS limit).

;;;;;;; ACT_MAC GPFTAB,@OPCOD_ADDAL,	   AUTO_GPF_EIP
;;;;;;; ACT_MAC GPFTAB,@OPCOD_ADDAX
;;;;;;; ACT_MAC GPFTAB,@OPCOD_ORAL
;;;;;;; ACT_MAC GPFTAB,@OPCOD_ORAX
;;;;;;; ACT_MAC GPFTAB,@OPCOD_ADCAL
;;;;;;; ACT_MAC GPFTAB,@OPCOD_ADCAX
;;;;;;; ACT_MAC GPFTAB,@OPCOD_SBBAL
;;;;;;; ACT_MAC GPFTAB,@OPCOD_SBBAX
;;;;;;; ACT_MAC GPFTAB,@OPCOD_ANDAL
;;;;;;; ACT_MAC GPFTAB,@OPCOD_ANDAX
;;;;;;; ACT_MAC GPFTAB,@OPCOD_SUBAL
;;;;;;; ACT_MAC GPFTAB,@OPCOD_SUBAX
;;;;;;; ACT_MAC GPFTAB,@OPCOD_XORAL
;;;;;;; ACT_MAC GPFTAB,@OPCOD_XORAX
;;;;;;; ACT_MAC GPFTAB,@OPCOD_CMPAL
;;;;;;; ACT_MAC GPFTAB,@OPCOD_CMPAX


AFL_WMAC macro	NAM,LCNT	; Macro for defining AFL windows (centered)

	public	NAM,W_&NAM
W_&NAM	W_STR	<@NROWS-1-LCNT, \
		0, \
		NROWS_&NAM, \
		NCOLS_&NAM>

	endm			; AFL_WMAC

AFL1MAC macro	NAM,TXT1,TXT2,TXT3 ; One-line AFL macro with optional fill-ins

NAM	db	TXT1
ifnb <TXT2>
NAM&A	db	TXT2
endif				; IFNB <TXT2>
ifnb <TXT3>
NAM&B	db	TXT3
endif				; IFNB <TXT3>
NCOLS_&NAM equ	$-NAM		; # columns
NROWS_&NAM equ	1		; # rows
	AFL_WMAC NAM,1

	endm			; AFL1MAC

AFL2MAC macro	NAM,TXT1,TXT2,TXT2F,TXT3F ; Two-line AFL macro with two fill-ins

NAM	db	TXT1
NCOLS_&NAM equ	$-NAM		; # columns
NROWS_&NAM equ	2		; # rows
	db	TXT2
NAM&2	db	TXT2F
NAM&3	db	TXT3F
	AFL_WMAC NAM,2

	endm			; AFL2MAC

; Because MASM can't handle embedded < and > within strings, we
; define equates for them

@GT	equ	'>'
@LT	equ	'<'

; TSS Fault messages

	AFL1MAC AFL_TSS_EXT, <' TSS:  EXT bit set in error code '>
	AFL1MAC AFL_TSS_GDT0,<' TSS:  Back link selector ('>, \
			     <'____) in LDT '>
	AFL1MAC AFL_TSS_GDT1,<' TSS:  Back link selector ('>, \
			     <'____) outside GDT limits '>
	AFL1MAC AFL_TSS_GDT2,<' TSS:  Back link selector ('>, \
			     <'____) A/R byte not TSS '>
	AFL1MAC AFL_TSS_GDT3,<' TSS:  Back link selector ('>, \
			     <'____) not busy '>
	AFL1MAC AFL_TSS_GDT4,<' TSS:  Back link selector ('>, \
			     <'____) not present '>
	AFL1MAC AFL_TSS_SMALL,<' TSS:  Segment limit ('>, \
			      <'________) too small '>
	AFL1MAC AFL_TSS_LDT0,<' TSS:  LDT selector ('>, \
			     <'____) in LDT '>
	AFL1MAC AFL_TSS_LDT1,<' TSS:  LDT selector ('>, \
			     <'____) outside GDT limits '>
	AFL1MAC AFL_TSS_LDT2,<' TSS:  LDT selector ('>, \
			     <'____) A/R byte not LDT '>
	AFL1MAC AFL_TSS_LDT3,<' TSS:  LDT selector ('>, \
			     <'____) not present '>
	AFL1MAC AFL_TSS_STK1,<' TSS:  Inner SS selector ('>, \
			     <'____) outside GDT limits '>
	AFL1MAC AFL_TSS_STK2,<' TSS:  Inner SS selector ('>, \
			     <'____) A/R byte not R/W data '>
	AFL1MAC AFL_TSS_COD1,<' TSS:  Inner CS selector ('>, \
			     <'____) outside GDT limits'>
	AFL1MAC AFL_TSS_COD2,<' TSS:  Inner CS selector ('>, \
			     <'____) A/R byte not code '>
	AFL1MAC AFL_TSS_DPL, <' TSS:  Inner SS selector ('>, \
			     <'____) DPL ',@LT,@GT,' CPL '>
	AFL1MAC AFL_TSS_RPL, <' TSS:  Inner SS selector ('>, \
			     <'____) RPL ',@LT,@GT,' CPL '>
	AFL1MAC AFL_TSS_CSDPL1,<' TSS:  Inner non-conforming CS selector ('>, \
			     <'____) DPL ',@LT,@GT,' CPL '>
	AFL1MAC AFL_TSS_CSDPL2,<' TSS:  Inner conforming CS selector ('>, \
			     <'____) DPL ',@GT,' CPL '>
	AFL1MAC AFL_TSS_DSEL1,<' TSS:  Inner selector '>, \
			     <'__ ('>, \
			     <'____) is outside GDT/LDT limits '>
	AFL1MAC AFL_TSS_DSEL2,<' TSS:  Inner selector '>, \
			     <'__ ('>, \
			     <'____) is not type data '>

	AFL1MAC AFL_TSS_UNK,<' TSS:  Unknown cause '>

; General Protection Fault messages

	AFL1MAC AFL_GPF_IOPL,	 <' GPF:  IOPL-sensitive instruction with CPL ',@GT,' IOPL '>
	AFL1MAC AFL_GPF_NOTPL0,  <' GPF:  PL0-sensitive instruction with CPL ',@GT,' 0 '>
	AFL1MAC AFL_GPF_IOMAP1,  <' GPF:  I/O instruction with CPL ',@GT,' IOPL w/ I/O permission bit set'>
	AFL1MAC AFL_GPF_IOMAP2,  <' GPF:  I/O instruction in VM w/ I/O permission bit set '>
	AFL1MAC AFL_GPF_MEM,	 <' GPF:  Memory operand out of range '>
	AFL1MAC AFL_GPF_SEL,	 <' GPF:  Invalid selector '>
	AFL1MAC AFL_GPF_LTRBUSY, <' GPF:  LTR selector ('>, \
				 <'____) busy '>
	AFL1MAC AFL_GPF_LTRLDT,  <' GPF:  LTR selector ('>, \
				 <'____) in LDT '>
	AFL1MAC AFL_GPF_LDTLDT,  <' GPF:  LDT selector ('>, \
				 <'____) in LDT '>
	AFL1MAC AFL_GPF_MSR,	 <' GPF:  RDMSR/WRMSR with ECX out of range '>
	AFL1MAC AFL_GPF_CR0,	 <' GPF:  Move to CR0 with PG=1/PE=0 '>
	AFL1MAC AFL_GPF_CR4,	 <' GPF:  Move to CR4 with reserved bits set '>
	AFL1MAC AFL_GPF_REL,	 <' GPF:  Relative jump beyond CS limit '>
	AFL1MAC AFL_GPF_EIP,	 <' GPF:  Instruction pointer (eIP) beyond CS limit '>
	AFL1MAC AFL_GPF_IDTLIM,  <' GPF:  Interrupt # beyond IDT limit '>
	AFL1MAC AFL_GPF_IDTGAT,  <' GPF:  Interrupt IDT entry is not an interrupt/trap/task gate '>
	AFL1MAC AFL_GPF_IDTDPL,  <' GPF:  Interrupt IDT entry DPL ',@LT,' CPL '>
	AFL1MAC AFL_GPF_IDTDPL3, <' GPF:  VM Interrupt/trap IDT entry DPL ',@LT,' 3 '>
	AFL1MAC AFL_GPF_IDTCPL0, <' GPF:  VM Interrupt/trap IDT entry CS CPL ',@GT,' 0 '>
	AFL1MAC AFL_GPF_IDTCSNUL,<' GPF:  Interrupt/trap IDT entry CS is zero '>
	AFL1MAC AFL_GPF_IDTCSBIG,<' GPF:  Interrupt/trap IDT entry CS is beyond GDT limit '>
	AFL1MAC AFL_GPF_IDTCSCOD,<' GPF:  Interrupt/trap IDT entry CS is not code selector '>
	AFL1MAC AFL_GPF_IDTCSEIP,<' GPF:  Interrupt IDT entry EIP is beyond CS limit '>
	AFL1MAC AFL_GPF_IDTDCPL, <' GPF:  Interrupt/trap IDT entry CS DPL ',@GT,' CPL '>
	AFL1MAC AFL_GPF_IRETCS,  <' GPF:  IRETd CS ('>, \
				 <'____) is invalid '>
	AFL1MAC AFL_GPF_IRETIP,  <' GPF:  IRETd eIP is beyond CS limit '>
	AFL1MAC AFL_GPF_JMP1,	 <' GPF:  JMP/CALL target selector ('>, \
				 <'____) is invalid or outside GDT/LDT limits '>
	AFL1MAC AFL_GPF_JMP2,	 <' GPF:  JMP/CALL target selector ('>, \
				 <'____) is not type code '>
	AFL1MAC AFL_GPF_JMP3,	 <' GPF:  JMP/CALL non-conforming target selector ('>, \
				 <'____) has DPL ',@LT,@GT,' CPL '>
	AFL1MAC AFL_GPF_JMP4,	 <' GPF:  JMP/CALL non-conforming target selector ('>, \
				 <'____) has RPL ',@GT,' CPL '>
	AFL1MAC AFL_GPF_JMP5,	 <' GPF:  JMP/CALL conforming target selector ('>, \
				 <'____) has DPL ',@GT,' CPL '>
	AFL1MAC AFL_GPF_LONG,	 <' GPF:  Instruction length exceeds 15-byte limit '>
	AFL1MAC AFL_GPF_DSR,	 <' GPF:  Source CMPS/LODS/MOVS/OUTS selector invalid or not readable '>
	AFL1MAC AFL_GPF_ESR,	 <' GPF:  Destination CMPS/SCAS selector invalid or not readable '>
	AFL1MAC AFL_GPF_ESW,	 <' GPF:  Destination INS/MOVS/STOS selector invalid or not writable '>

	AFL1MAC AFL_GPF_UNK,	 <' GPF:  Unknown cause '>

; Page Fault messages

	AFL1MAC AFL_PF_RSVPDE,<' PF:  Reserved bit set in PDE ('>, \
			     <'________) '>
	AFL1MAC AFL_PF_RSVPTE,<' PF:  Reserved bit set in PTE ('>, \
			     <'________) '>
	AFL1MAC AFL_PF_RSVUNK,<' PF:  Unknown reserved bit error '>
	AFL1MAC AFL_PF_NPPDE,<' PF:  PDE not present ('>, \
			     <'________) '>
	AFL1MAC AFL_PF_NPPTE,<' PF:  PTE not present ('>, \
			     <'________) '>
	AFL1MAC AFL_PF_NPUNK,<' PF:  Unknown not present page error '>
	AFL2MAC AFL_PF_USER,<' PF:  User level access to Supervisor level page '>, \
			    <'          PDE: '>,<'________   PTE: '>,<'________          '>
	AFL2MAC AFL_PF_ROM,<' PF:  Write to read-only page '>, \
			   <' PDE: '>,<'________  PTE: '>,<'________ '>

	AFL1MAC AFL_PF_UNK,<' PF:  Unknown cause '>

WTXT	ends			; End WTXT segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP,ds:PGROUP

	extrn	BIN2WORD:near
	extrn	BIN2DWORD:near
	extrn	SEL2TSS:near
	extrn	LIN2PPTE:near
	extrn	LIN2PPDIR:near
	extrn	LIN2PPTEZ:near
	extrn	READ_CR3:near
	extrn	GETARW:near
	extrn	GETBASE:near
	extrn	GETLIMIT:near
	extrn	GETILEN:near

	extrn	INT0A_MSG1:byte
	extrn	INT0C_MSG1:byte
	extrn	INT0D_MSG1:byte
	extrn	INT0E_MSG1:byte
	extrn	INT08_MSG:byte
	extrn	INT0A_MSG:byte
	extrn	INT0C_MSG:byte
	extrn	INT0D_MSG:byte
	extrn	INT0E_MSG:byte

FLT_STR struc

FLT_MSG dd	?		; Fault message
FLT_ACT dd	?		; Fault action

FLT_STR ends

	public	FLTTAB
FLTTAB	FLT_STR <offset PGROUP:INT0A_MSG1,offset PGROUP:AUTO_TSS> ; INT 0Ah
	FLT_STR <offset PGROUP:INT0C_MSG1,offset PGROUP:AUTO_STK> ; INT 0Ch
	FLT_STR <offset PGROUP:INT0D_MSG1,offset PGROUP:AUTO_GPF> ; INT 0Dh
	FLT_STR <offset PGROUP:INT0E_MSG1,offset PGROUP:AUTO_PF > ; INT 0Eh

	FLT_STR <offset PGROUP:MAX08_MSG1,offset PGROUP:AUTO_DBL> ; INT 08h
	FLT_STR <offset PGROUP:MAX0A_MSG1,offset PGROUP:AUTO_TSS> ; INT 0Ah
	FLT_STR <offset PGROUP:MAX0C_MSG1,offset PGROUP:AUTO_STK> ; INT 0Ch
	FLT_STR <offset PGROUP:MAX0D_MSG1,offset PGROUP:AUTO_GPF> ; INT 0Dh
	FLT_STR <offset PGROUP:MAX0D_MSG2,offset PGROUP:AUTO_GPF> ; INT 0Dh
	FLT_STR <offset PGROUP:MAX0E_MSG1,offset PGROUP:AUTO_PF > ; INT 0Eh

	FLT_STR <offset PGROUP:INT08_MSG ,offset PGROUP:AUTO_DBL> ; INT 08h
	FLT_STR <offset PGROUP:INT0A_MSG ,offset PGROUP:AUTO_TSS> ; INT 0Ah
	FLT_STR <offset PGROUP:INT0C_MSG ,offset PGROUP:AUTO_STK> ; INT 0Ch
	FLT_STR <offset PGROUP:INT0D_MSG ,offset PGROUP:AUTO_GPF> ; INT 0Dh
	FLT_STR <offset PGROUP:INT0E_MSG ,offset PGROUP:AUTO_PF > ; INT 0Eh
FLTTAB_LEN equ	($-FLTTAB)/(type FLT_STR) ; # entries in the table

	public	MAX08_MSG1,MAX0A_MSG1,MAX0C_MSG1,MAX0D_MSG1,MAX0E_MSG1
MAX08_MSG1 db	'Double Fault',0        ; 386MAX's error messages
MAX0A_MSG1 db	'A TSS Fault',0
MAX0C_MSG1 db	'A Stack Fault',0
MAX0D_MSG1 db	'A GP Fault',0
MAX0D_MSG2 db	'GP (',0
MAX0E_MSG1 db	'A Page Fault',0

	NPPROC	AUTOFAULT -- AutoFault Handler
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

AutoFault analysis.

Use our knowledge of how these various faults can occur to make it easier
for the user to figure out what happened.

Operand analysis has already been done on the current instruction.

On entry:

SS:EBP	==>	FORW_STR

|

	push	es		; Save register
	pushad			; Save all EGP registers

	mov	ax,cs		; Copy code selector
	mov	es,ax		; Address it
	assume	es:PGROUP	; Tell the assembler about it

; Check for various faults we know how to analyze

	lea	esi,ERRMSG[1]	; Skip over leading chevron
	mov	ecx,FLTTAB_LEN	; Get # entries
	xor	ebx,ebx 	; Index into table
AUTOFAULT_NEXT:
	REGSAVE <ecx,esi>	; Save for a moment

	mov	edx,FLTTAB.FLT_MSG[ebx] ; Get next offset
	mov	edi,edx 	; Copy to destin register
	mov	al,0		; Search for the end
	mov	ecx,-1		; We know it's there
  repne scas	MAX0A_MSG1[edi] ; Find the terminator
	lea	ecx,[edi-1]	; Back up to terminator
	sub	ecx,edx 	; Less starting point

	mov	edi,edx 	; Get next offset
   repe cmps	DGROUP:[esi].LO,MAX0A_MSG1[edi] ; Izit a match?
	REGREST <esi,ecx>	; Restore
	je	short AUTOFAULT_WORK ; Jump if so

	add	ebx,type FLT_STR ; Skip to next entry

	loop	AUTOFAULT_NEXT	; Jump if more faults to check

; The fault was not recognized

	jmp	short AUTOFAULT_EXIT ; Join common exit code


AUTOFAULT_WORK:
	mov	ax,ds		; Copy data selector
	mov	es,ax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	call	FLTTAB[ebx].FLT_ACT ; Take appropriate action
AUTOFAULT_EXIT:
	popad			; Restore
	pop	es		; ...
	assume	es:DGROUP	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

AUTOFAULT endp			; End AUTOFAULT procedure
	NPPROC	AUTO_DBL -- Analyze Double Faults
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Analyze Double Faults

On entry:

SS:EBP	==>	FORW_STR

On exit:

All EGP registers may be clobbered except EBP and ESP.

|











	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

AUTO_DBL endp			; End AUTO_DBL procedure
	NPPROC	AUTO_TSS -- Analyze TSS Faults
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Analyze TSS Faults

On entry:

SS:EBP	==>	FORW_STR

On exit:

All EGP registers may be clobbered except EBP and ESP.

|

; If the EXT bit is set in the error code, there's not much we can analyze

	test	ERRCODE,mask $FEXT ; Izit set?
	jnz	near ptr AUTO_TSS_ERREXT ; Jump if so

; If it's RM, it's a mystery to me

	test	[ebp].FORW_EFL,mask $R2 ; Izit RM?
	jnz	near ptr AUTO_TSS_UNK ; Jump if so

; If it's VM, handle separately

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM?
	jnz	near ptr AUTO_TSS_VM ; Jump if so

; Split cases based upon the instruction

	mov	ebx,[ebp-@BPBACK].BACK_CS.DTR_BASE ; Get base address of CS
	add	ebx,[ebp].FORW_EIP ; Plus EIP to get linear address of the
				; current instruction at CS:EIP

; Check for CALLFd

	cmp	AGROUP:[ebx].LO,@OPCOD_CALLF ; Izit CALLF immediate?
	je	near ptr AUTO_TSS_CALLF ; Jump if so

	cmp	AGROUP:[ebx].ELO,@OPCOD_CALLFD ; Izit CALLFD immediate?
	je	near ptr AUTO_TSS_CALLF ; Jump if so

; Check for IRETd

	cmp	AGROUP:[ebx].LO,@OPCOD_IRET ; Izit IRET?
	je	short @F	; Jump if so

	cmp	AGROUP:[ebx].ELO,@OPCOD_IRETD ; Izit IRETD?
	jne	near ptr AUTO_TSS_XIRET ; Jump if not
@@:

; If it's PM, ...
; If the NT bit is set, check the TSS back link

	mov	ecx,[ebp-@BPBACK].BACK_TR.DTR_BASE ; Get the base address

; AGROUP:ECX ==> current TSS

	mov	ax,AGROUP:[ecx].TSS_LINK ; Get the back link
	and	ax,not (mask $PL) ; Ignore the PL bits

	test	[ebp].FORW_EFL,mask $NT ; Izit set?
	jz	short AUTO_TSS_IRETXNT ; Jump if not

; Ensure that the TI bit is clear (it's in the GDT)

	test	ax,mask $TI	; Ensure that local/global bit is clear
	jnz	near ptr AUTO_TSS_ERRGDT0 ; Jump if not valid

; Ensure that the index is within GDT limits

	add	ax,(size DESC_STR)-1 ; Add to get highest address

	cmp	ax,[ebp-@BPBACK].BACK_GDT.DTR_LIM ; Izit within limits?
	ja	near ptr AUTO_TSS_ERRGDT1 ; Jump if not

	sub	ax,(size DESC_STR)-1 ; Restore

; Ensure that the A/R byte is that of a TSS

	mov	bx,ax		; Save for a moment

	push	ax		; Pass the selector
	call	GETARW		; Return with AX = access rights word
	xchg	ax,bx		; Swap so AX = selector for error msgs
	jc	near ptr AUTO_TSS_ERRGDT2 ; Jump if something went wrong

	mov	bh,bl		; Save for later use
	and	bl,not (mask $DT_DPL) ; Clear the DPL bits
	or	bl,(mask $DT_P) or (mask $DS_BUSY) ; P=BUSY=1

	cmp	bl,CPL0_BUSY2	; Izit a 286 TSS?
	je	short @F	; Jump if so

	cmp	bl,CPL0_BUSY3	; Izit a 386 TSS?
	jne	near ptr AUTO_TSS_ERRGDT2 ; Jump if not
@@:

; Ensure that the A/R byte says the TSS is busy

	test	bh,mask $DS_BUSY ; Izit busy?
	jz	near ptr AUTO_TSS_ERRGDT3 ; Jump if not
AUTO_TSS_IRETXNT:
	call	GET_TSSSEL	; Return the TSS selector in BX

	push	bx		; Pass the selector
	call	GETBASE 	; Return with EAX = selector base
	jc	near ptr AUTO_TSS_UNK ; Jump if something went wrong

	mov	edx,eax 	; AGROUP:EDX ==> TSS

	jmp	short AUTO_TSS_CALLF1 ; Join common code


AUTO_TSS_CALLF:

; Ensure that the TSS segment limit is large enough
; If it isn't, then TR doesn't get changed, so EA1TSEL has the bad selector

	call	GET_TSSSEL	; Return the TSS selector in BX

; If this selector is a call gate, extract the TSS selector

	call	SEL2TSS 	; Convert BX to TSS selector
				; BX = TSS selector
				; CX = flags
				; EDX = TSS
	jc	near ptr AUTO_TSS_UNK ; Jump if something went wrong
AUTO_TSS_CALLF1:
	push	bx		; Pass the selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_TSS_UNK ; Jump if something went wrong

	mov	AUTO_ARW,ax	; Save for later use

	test	al,mask $DS_386 ; Izit a 386 TSS?
	mov	ecx,(type TSS_STR)-1 ; Assume so
	jnz	short @F	; Jump if so

	mov	ecx,(type TSS2_STR)-1 ; Assume so
@@:
	push	bx		; Pass the selector
	call	GETLIMIT	; Return with EAX = selector limit
	jc	near ptr AUTO_TSS_UNK ; Jump if something went wrong

	cmp	eax,ecx 	; Izit large enough?
	jb	near ptr AUTO_TSS_ERRSMALL ; Jump if not

; AGROUP:EDX ==> TSS

; Check the LDT

; Ensure that the TI bit is clear (it's in the GDT)

	test	AUTO_ARW,mask $DS_386 ; Izit a 386 TSS?
	mov	ax,AGROUP:[edx].TSS_LDT ; Get the LDT
	jnz	short @F	; Jump if so

	mov	ax,AGROUP:[edx].TSS2_LDT ; Get the LDT
@@:
	mov	AUTO_LDT,ax	; Save for later use

	test	ax,mask $TI	; Ensure that local/global bit is clear
	jnz	near ptr AUTO_TSS_ERRLDT0 ; Jump if not valid

	and	ax,not (mask $PL) ; Ignore the PL bits

; Ensure that the index is within GDT limits

	add	ax,(size DESC_STR)-1 ; Add to get highest address

	cmp	ax,[ebp-@BPBACK].BACK_GDT.DTR_LIM ; Izit within limits?
	ja	near ptr AUTO_TSS_ERRLDT1 ; Jump if not

	sub	ax,(size DESC_STR)-1 ; Restore

; Ensure that the A/R byte is that of a LDT

	push	ax		; Pass the selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_TSS_ERRLDT2 ; Jump if something went wrong

	mov	al,ah		; Copy for destructive testing
	and	al,not (mask $DT_DPL) ; Clear the DPL bits
	or	al,mask $DT_P	; P=1

	cmp	al,CPL0_LDT	; Izit an LDT?
	jne	near ptr AUTO_TSS_ERRLDT2 ; Jump if not

; Ensure that the A/R byte says the LDT is present

	test	ah,mask $DT_P	; Izit present?
	jz	near ptr AUTO_TSS_ERRLDT3 ; Jump if not

; Save inner SS and CS values

	mov	bl,AUTO_ARW.LO	; Get the A/R byte of the TSS
	and	ebx,mask $DT_DPL ; Isolate the DPL bits
	shr	ebx,$DT_DPL	; Shift to low-order

	test	AUTO_ARW,mask $DS_386 ; Izit a 386 TSS?
	mov	ax,AGROUP:[edx+ebx*8].TSS_CS ; Get the Code Selector
	mov	cx,AGROUP:[edx+ebx*8].TSS_SS0 ; Get the Stack Selector
	jnz	short @F	; Jump if so

	mov	ax,AGROUP:[edx+ebx*4].TSS2_CS ; Get the Code Selector
	mov	cx,AGROUP:[edx+ebx*4].TSS2_SS0 ; Get the Stack Selector
@@:
	mov	AUTO_CS,ax	; Save for later use
	mov	AUTO_SS,cx	; ...

	and	eax,mask $PL	; Isolate the RPL (which for CS is the CPL)
;;;;;;; shr	eax,$PL 	; Shift to low-order (already there)
	mov	AUTO_CPL,ax	; Save for later use

; Ensure that the Inner-level Stack Segment is valid
; Ensure that SS is within GDT/LDT table limits

	push	AUTO_SS 	; Pass the selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_TSS_ERRSTK1 ; Jump if invalid

; Ensure that the A/R byte is that of a R/W data selector

	mov	ah,al		; Copy for destructive testing
	and	al,not ((mask $DT_DPL) or (mask $DD_EXPD) or (mask $DD_ACC)) ; DPL=EXPD=ACC=0
	or	al,mask $DT_P	; P=1

	cmp	al,CPL0_DATA	; Izit a R/W data selector?
	jne	near ptr AUTO_TSS_ERRSTK2 ; Jump if not

; Ensure that the SS DPL = incoming CPL

	mov	ax,AUTO_SS	; Get the selector
	and	eax,mask $DT_DPL ; Isolate the DPL bits
	shr	eax,$DT_DPL	; Shift to low-order

	cmp	ax,AUTO_CPL	; Izit valid?
	jne	near ptr AUTO_TSS_SSDPL ; Jump if not

; Ensure that the SS RPL = incoming CPL

	mov	ax,AUTO_SS	; Get the selector
	and	eax,mask $PL	; Isolate the RPL
;;;;;;; shr	eax,$PL 	; Shift to low-order (already there)

	cmp	ax,AUTO_CPL	; Izit valid?
	jne	near ptr AUTO_TSS_SSRPL ; Jump if not

; Ensure that the Inner-level Code Segment is valid
; Ensure that CS is within GDT/LDT table limits

	push	AUTO_CS 	; Pass the selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_TSS_ERRCOD1 ; Jump if invalid

; Ensure that the A/R byte is that of a code selector

	mov	ah,al		; Copy for destructive testing
	and	al,not ((mask $DT_DPL) or (mask $DC_CONF) or (mask $DC_READ) or (mask $DC_ACC)) ; DPL=CONF=READ=ACC=0
	or	al,mask $DT_P	; P=1

	cmp	al,CPL0_CODE	; Izit a code selector?
	jne	near ptr AUTO_TSS_ERRCOD2 ; Jump if not

; If CS is non-conforming, ensure that DPL = CPL

	test	ah,mask $DC_CONF ; Izit conforming?
	jnz	short AUTO_TSS_CONF ; Jump if so

	mov	ax,AUTO_CS	; Get the selector
	and	eax,mask $DT_DPL ; Isolate the DPL bits
	shr	eax,$DT_DPL	; Shift to low-order

	cmp	ax,AUTO_CPL	; Izit valid?
	jne	near ptr AUTO_TSS_CSDPL1 ; Jump if not

	jmp	short AUTO_TSS_CONFCOM ; Join common code


; If CS is conforming, ensure that DPL <= CPL

AUTO_TSS_CONF:
	mov	ax,AUTO_CS	; Get the selector
	and	eax,mask $DT_DPL ; Isolate the DPL bits
	shr	eax,$DT_DPL	; Shift to low-order

	cmp	ax,AUTO_CPL	; Izit valid?
	ja	near ptr AUTO_TSS_CSDPL2 ; Jump if not
AUTO_TSS_CONFCOM:

; For all data selectors, ensure that they are within GDT/LDT limits,
; and for all non-zero data selectors, ensure that they are readable

	test	AUTO_ARW,mask $DS_386 ; Izit a 386 TSS?
	jnz	short AUTO_TSS_386 ; Jump if so

; Ensure that DS is valid

	mov	ax,AGROUP:[edx].TSS2_DS ; Get the Data Selector
	and	eax,not (mask $PL) ; Clear PL bits
	jz	short @F	; Jump if zero

	mov	cx,'SD'         ; Get name of selector
	mov	AUTO_DS,ax	; Save the selector

	push	ax		; Pass selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_TSS_DSEL1 ; Jump if something went wrong

	and	al,(mask $DT_DC) or (mask $DC_COD) ; Isolate bits

	cmp	al,mask $DT_DC	; Izit data type?
	jne	near ptr AUTO_TSS_DSEL2 ; Jump if not
@@:

; Ensure that ES is valid

	mov	ax,AGROUP:[edx].TSS2_ES ; Get the Data Selector
	and	eax,not (mask $PL) ; Clear PL bits
	jz	short @F	; Jump if zero

	mov	cx,'SE'         ; Get name of selector
	mov	AUTO_DS,ax	; Save the selector

	push	ax		; Pass selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_TSS_DSEL1 ; Jump if something went wrong

	and	al,(mask $DT_DC) or (mask $DC_COD) ; Isolate bits

	cmp	al,mask $DT_DC	; Izit data type?
	jne	near ptr AUTO_TSS_DSEL2 ; Jump if not
@@:
	jmp	AUTO_TSS_COM	; Join common code


AUTO_TSS_386:

; Ensure that DS is valid

	mov	ax,AGROUP:[edx].TSS_DS ; Get the Data Selector
	and	eax,not (mask $PL) ; Clear PL bits
	jz	short @F	; Jump if zero

	mov	cx,'SD'         ; Get name of selector
	mov	AUTO_DS,ax	; Save the selector

	push	ax		; Pass selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_TSS_DSEL1 ; Jump if something went wrong

	and	al,(mask $DT_DC) or (mask $DC_COD) ; Isolate bits

	cmp	al,mask $DT_DC	; Izit data type?
	jne	near ptr AUTO_TSS_DSEL2 ; Jump if not
@@:

; Ensure that ES is valid

	mov	ax,AGROUP:[edx].TSS_ES ; Get the Data Selector
	and	eax,not (mask $PL) ; Clear PL bits
	jz	short @F	; Jump if zero

	mov	cx,'SE'         ; Get name of selector
	mov	AUTO_DS,ax	; Save the selector

	push	ax		; Pass selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_TSS_DSEL1 ; Jump if something went wrong

	and	al,(mask $DT_DC) or (mask $DC_COD) ; Isolate bits

	cmp	al,mask $DT_DC	; Izit data type?
	jne	near ptr AUTO_TSS_DSEL2 ; Jump if not
@@:

; Ensure that FS is valid

	mov	ax,AGROUP:[edx].TSS_FS ; Get the Data Selector
	and	eax,not (mask $PL) ; Clear PL bits
	jz	short @F	; Jump if zero

	mov	cx,'SF'         ; Get name of selector
	mov	AUTO_DS,ax	; Save the selector

	push	ax		; Pass selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_TSS_DSEL1 ; Jump if something went wrong

	and	al,(mask $DT_DC) or (mask $DC_COD) ; Isolate bits

	cmp	al,mask $DT_DC	; Izit data type?
	jne	near ptr AUTO_TSS_DSEL2 ; Jump if not
@@:

; Ensure that GS is valid

	mov	ax,AGROUP:[edx].TSS_GS ; Get the Data Selector
	and	eax,not (mask $PL) ; Clear PL bits
	jz	short @F	; Jump if zero

	mov	cx,'SG'         ; Get name of selector
	mov	AUTO_DS,ax	; Save the selector

	push	ax		; Pass selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_TSS_DSEL1 ; Jump if something went wrong

	and	al,(mask $DT_DC) or (mask $DC_COD) ; Isolate bits

	cmp	al,mask $DT_DC	; Izit data type?
	jne	near ptr AUTO_TSS_DSEL2 ; Jump if not
@@:
AUTO_TSS_COM:











AUTO_TSS_VM:




AUTO_TSS_XIRET:















;;;;;;; jmp	short AUTO_TSS_UNK ; Join common code


; The TSS fault is unknown:  admit defeat

AUTO_TSS_UNK:
	lea	ebx,WGROUP:AFL_TSS_UNK ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_UNK ; Get offset of window descriptor

	jmp	AUTO_TSS_ERRCOM ; Join common error code


AUTO_TSS_ERREXT:
	lea	ebx,WGROUP:AFL_TSS_EXT ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_EXT ; Get offset of window descriptor

	jmp	AUTO_TSS_ERRCOM ; Join common error code


AUTO_TSS_ERRGDT0:
	lea	ebx,WGROUP:AFL_TSS_GDT0 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_GDT0 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_TSS_GDT0A ; Get offset of word save area

	jmp	AUTO_TSS_ERRWORD ; Join common error code


AUTO_TSS_ERRGDT1:
	lea	ebx,WGROUP:AFL_TSS_GDT1 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_GDT1 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_TSS_GDT1A ; Get offset of word save area

	jmp	AUTO_TSS_ERRWORD ; Join common error code


AUTO_TSS_ERRGDT2:
	lea	ebx,WGROUP:AFL_TSS_GDT2 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_GDT2 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_TSS_GDT2A ; Get offset of word save area

	jmp	AUTO_TSS_ERRWORD ; Join common error code


AUTO_TSS_ERRGDT3:
	lea	ebx,WGROUP:AFL_TSS_GDT3 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_GDT3 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_TSS_GDT3A ; Get offset of word save area

	jmp	AUTO_TSS_ERRWORD ; Join common error code


AUTO_TSS_ERRSMALL:
	lea	ebx,WGROUP:AFL_TSS_SMALL ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_SMALL ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_TSS_SMALL ; Get offset of word save area

	jmp	AUTO_TSS_ERRWORD ; Join common error code


AUTO_TSS_ERRLDT0:
	mov	ax,AUTO_LDT	; Get the inner LDT selector
	lea	ebx,WGROUP:AFL_TSS_LDT0 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_LDT0 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_TSS_LDT0A ; Get offset of word save area

	jmp	AUTO_TSS_ERRWORD ; Join common error code


AUTO_TSS_ERRLDT1:
	mov	ax,AUTO_LDT	; Get the inner LDT selector
	lea	ebx,WGROUP:AFL_TSS_LDT1 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_LDT1 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_TSS_LDT1A ; Get offset of word save area

	jmp	AUTO_TSS_ERRWORD ; Join common error code


AUTO_TSS_ERRLDT2:
	mov	ax,AUTO_LDT	; Get the inner LDT selector
	lea	ebx,WGROUP:AFL_TSS_LDT2 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_LDT2 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_TSS_LDT2A ; Get offset of word save area

	jmp	AUTO_TSS_ERRWORD ; Join common error code


AUTO_TSS_ERRLDT3:
	mov	ax,AUTO_LDT	; Get the inner LDT selector
	lea	ebx,WGROUP:AFL_TSS_LDT3 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_LDT3 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_TSS_LDT3A ; Get offset of word save area

	jmp	AUTO_TSS_ERRWORD ; Join common error code


AUTO_TSS_ERRSTK1:
	mov	ax,AUTO_SS	; Get the inner stack selector
	lea	ebx,WGROUP:AFL_TSS_STK1 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_STK1 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_TSS_STK1A ; Get offset of word save area

	jmp	AUTO_TSS_ERRWORD ; Join common error code


AUTO_TSS_ERRSTK2:
	mov	ax,AUTO_SS	; Get the inner stack selector
	lea	ebx,WGROUP:AFL_TSS_STK2 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_STK2 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_TSS_STK2A ; Get offset of word save area

	jmp	AUTO_TSS_ERRWORD ; Join common error code


AUTO_TSS_ERRCOD1:
	mov	ax,AUTO_CS	; Get the inner code selector
	lea	ebx,WGROUP:AFL_TSS_COD1 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_COD1 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_TSS_COD1A ; Get offset of word save area

	jmp	AUTO_TSS_ERRWORD ; Join common error code


AUTO_TSS_ERRCOD2:
	mov	ax,AUTO_CS	; Get the inner code selector
	lea	ebx,WGROUP:AFL_TSS_COD2 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_COD2 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_TSS_COD2A ; Get offset of word save area

	jmp	AUTO_TSS_ERRWORD ; Join common error code


AUTO_TSS_SSDPL:
	mov	ax,AUTO_SS	; Get the inner stack selector
	lea	ebx,WGROUP:AFL_TSS_DPL ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_DPL ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_TSS_DPLA ; Get offset of word save area

	jmp	AUTO_TSS_ERRWORD ; Join common error code


AUTO_TSS_SSRPL:
	mov	ax,AUTO_SS	; Get the inner stack selector
	lea	ebx,WGROUP:AFL_TSS_RPL ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_RPL ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_TSS_RPLA ; Get offset of word save area

	jmp	AUTO_TSS_ERRWORD ; Join common error code


AUTO_TSS_CSDPL1:
	mov	ax,AUTO_CS	; Get the inner code selector
	lea	ebx,WGROUP:AFL_TSS_CSDPL1 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_CSDPL1 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_TSS_CSDPL1A ; Get offset of word save area

	jmp	short AUTO_TSS_ERRWORD ; Join common error code


AUTO_TSS_CSDPL2:
	mov	ax,AUTO_CS	; Get the inner code selector
	lea	ebx,WGROUP:AFL_TSS_CSDPL2 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_CSDPL2 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_TSS_CSDPL2A ; Get offset of word save area

	jmp	short AUTO_TSS_ERRWORD ; Join common error code


AUTO_TSS_DSEL1:
	lea	edi,WGROUP:AFL_TSS_DSEL1A ; Get offset of word save area
	add	edi,WINBASE	; Plus base of Autofault group in DGROUP
	mov	DGROUP:[edi].ELO,cx ; Save name of register

	mov	ax,AUTO_DS	; Get the value of the selector
	lea	ebx,WGROUP:AFL_TSS_DSEL1 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_DSEL1 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_TSS_DSEL1B ; Get offset of word save area

	jmp	short AUTO_TSS_ERRWORD ; Join common error code


AUTO_TSS_DSEL2:
	lea	edi,WGROUP:AFL_TSS_DSEL2A ; Get offset of word save area
	add	edi,WINBASE	; Plus base of Autofault group in DGROUP
	mov	DGROUP:[edi].ELO,cx ; Save name of register

	mov	ax,AUTO_DS	; Get the value of the selector
	lea	ebx,WGROUP:AFL_TSS_DSEL2 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_TSS_DSEL2 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_TSS_DSEL2B ; Get offset of word save area

	jmp	short AUTO_TSS_ERRWORD ; Join common error code


; Format a word value into ES:EDI

AUTO_TSS_ERRWORD:
	add	edi,WINBASE	; Plus base of Autofault group in DGROUP
	call	BIN2WORD	; Convert AX to hex at ES:EDI
AUTO_TSS_ERRCOM:
	add	ebx,WINBASE	; Plus base of Autofault group in DGROUP
	add	ecx,WINBASE	; ...
	mov	LAST_AFLERR,ebx ; Save for next time
	mov	LAST_AFLWIN,ecx ; ...

	or	LC4_FLAG,@LC4_AFLTBD ; Mark as AutoFault message
				; to be displayed
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

AUTO_TSS endp			; End AUTO_TSS procedure
	NPPROC	GET_TSSSEL -- Get TSS Selector
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Get TSS selector

On exit:

BX	=	TSS selector

|

	REGSAVE <eax>		; Save register

	mov	bx,ERRCODE.ELO	; Get error code in case that's the TSS

	push	bx		; Pass selector
	call	GETARW		; Return with AX = access rights word
	jc	short GET_TSSSEL_XEC ; Jump on error

	and	al,not (mask $DT_DPL) ; Clear DPL bits

; Check for TSS

	cmp	al,CPL0_BUSY3	; Izit a busy 386 TSS?
	je	short GET_TSSSEL_EXIT ; Jump if so

	cmp	al,CPL0_IDLE3	; Izit an idle 386 TSS?
	je	short GET_TSSSEL_EXIT ; Jump if so

	cmp	al,CPL0_BUSY2	; Izit a busy 286 TSS?
	je	short GET_TSSSEL_EXIT ; Jump if so

	cmp	al,CPL0_IDLE2	; Izit an idle 286 TSS?
	je	short GET_TSSSEL_EXIT ; Jump if so
GET_TSSSEL_XEC:
	mov	bx,EA1TSEL	; Get the selector
GET_TSSSEL_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_TSSSEL endp 		; End GET_TSSSEL procedure
	NPPROC	AUTO_STK -- Analyze Stack Faults
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Analyze Stack Faults

On entry:

SS:EBP	==>	FORW_STR

On exit:

All EGP registers may be clobbered except EBP and ESP.

|











	call	AUTO_GPF	; Try GP Faults

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

AUTO_STK endp			; End AUTO_STK procedure
	NPPROC	AUTO_GPF -- Analyze GP Faults
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Analyze GP Faults

On entry:

SS:EBP	==>	FORW_STR

On exit:

All EGP registers may be clobbered except EBP and ESP.

|

; Save local variables to be re-entrant

	REGSAVE <AUTO_CPL,AUTO_IOPL,AUTO_ARW,PREFLAGS,\
		EA1OFF,EA1BASE,EA1LIM,EA1TSEL,EA1SEL,EA1MODE,EA1WID>

; Calculate CPL and IOPL

	mov	ax,[ebp].FORW_CS ; Get caller's CS
	and	eax,mask $PL	; Isolate the RPL (which for CS is the CPL)
;;;;;;; shr	eax,$PL 	; Shift to low-order (already there)

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM?
	jz	short @F	; Jump if not

	mov	al,3		; In VM, CPL = 3
@@:
	mov	AUTO_CPL,ax	; Save for later use

	mov	ax,[ebp].FORW_EFL.ELO ; Get FL
	and	eax,mask $IOPL	; Isolate IOPL
	shr	eax,$IOPL	; Shift to low-order
	mov	AUTO_IOPL,ax	; Save for later use

; Check CS:EIP fetch out of bounds

	push	ds		; Save for a moment

; Get pointer to CS:EIP depending upon whether or not we're in VM

	mov	ax,gs		; Get AGROUP data selector
	mov	ds,ax		; Address it
	assume	ds:AGROUP	; Tell the assembler about it

	sldt	bx		; Save current LDTR

	mov	esi,[ebp-@BPBACK].BACK_CS.DTR_BASE ; Get base address of CS
	add	esi,[ebp].FORW_EIP ; Plus EIP to get linear address of the
				; current instruction at CS:EIP
	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM?
	jnz	short @F	; Jump if so

	lldt	[ebp].FORW_LDT	; Install caller's LDTR in case
				; the caller's CS is in it
	lds	esi,[ebp].FORW_EIP.EDF ; DS:ESI ==> instruction
	assume	ds:nothing	; Tell the assembler about it
@@:
	call	GETILEN 	; Return with EAX = length of instruction
				;  with DS:ESI==> 1st byte of next instruction
	lldt	bx		; Restore previous LDTR

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM?
	jz	short @F	; Jump if not

	sub	esi,[ebp-@BPBACK].BACK_CS.DTR_BASE ; Less base address of CS
@@:
	pop	ds		; Restore
	assume	ds:DGROUP	; Tell the assembler about it

	cmp	eax,15		; Izit too large?
	ja	near ptr AUTO_GPF_LONG ; Jump if so

	mov	eax,0FFFFh	; Get limit if VM

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM?
	jnz	short @F	; Jump if so

	push	[ebp].FORW_CS	; Pass the selector
	call	GETLIMIT	; Return with EAX = selector limit
;;;;;;; jc	near ptr AUTO_GPF_UNK ; Jump if something went wrong
@@:
	cmp	esi,eax 	; Izit beyond fetch limit?
	ja	near ptr AUTO_GPF_EIP ; Jump if so

; Split cases based upon the instruction

	mov	ebx,[ebp-@BPBACK].BACK_CS.DTR_BASE ; Get base address of CS
	add	ebx,[ebp].FORW_EIP ; Plus EIP to get linear address of the
				; current instruction at CS:EIP
	mov	PREFLAGS,0	; Clear prefix flags

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM?
	jnz	short @F	; Jump if so

	push	[ebp].FORW_CS	; Pass the code selector
	call	GETARW		; Return with AX = access rights word

	test	ah,mask $DTE_B	; Izit USE32?
	jz	short @F	; Jump if not

	mov	PREFLAGS,@PREF_OSP or @PREF_ASP ; Mark as present
@@:
	xor	eax,eax 	; Zero to use as dword
AUTO_GPF_NEXTBYTE:
	mov	al,AGROUP:[ebx] ; Get the next byte
	inc	ebx		; Skip to next byte

	cmp	al,@OPCOD_OSP	; Izit OSP?
	jne	short @F	; Jump if not

	xor	PREFLAGS,@PREF_OSP ; Mark as toggled

	jmp	AUTO_GPF_NEXTBYTE ; Go around again


@@:
	cmp	al,@OPCOD_ASP	; Izit ASP?
	jne	short @F	; Jump if not

	xor	PREFLAGS,@PREF_ASP ; Mark as toggled

	jmp	AUTO_GPF_NEXTBYTE ; Go around again


@@:
	cmp	al,@OPCOD_REPE	; Izit REP/REPE?
	jne	short @F	; Jump if not

	or	PREFLAGS,@PREF_REPE ; Mark as present

	jmp	AUTO_GPF_NEXTBYTE ; Go around again


@@:
	cmp	al,@OPCOD_REPNE ; Izit REPNE?
	jne	short @F	; Jump if not

	or	PREFLAGS,@PREF_REPNE ; Mark as present

	jmp	AUTO_GPF_NEXTBYTE ; Go around again


@@:
	cmp	al,@OPCOD_LOCK	; Izit LOCK?
	jne	short @F	; Jump if not

	or	PREFLAGS,@PREF_LOCK ; Mark as present

	jmp	AUTO_GPF_NEXTBYTE ; Go around again


@@:
	cmp	al,@OPCOD_SS	; Izit SS?
	jne	short @F	; Jump if not

	or	PREFLAGS,@PREF_SS ; Mark as present

	jmp	AUTO_GPF_NEXTBYTE ; Go around again


@@:
	cmp	al,@OPCOD_GS	; Izit GS?
	jne	short @F	; Jump if not

	or	PREFLAGS,@PREF_GS ; Mark as present

	jmp	AUTO_GPF_NEXTBYTE ; Go around again


@@:
	cmp	al,@OPCOD_FS	; Izit FS?
	jne	short @F	; Jump if not

	or	PREFLAGS,@PREF_FS ; Mark as present

	jmp	AUTO_GPF_NEXTBYTE ; Go around again


@@:
	cmp	al,@OPCOD_ES	; Izit ES?
	jne	short @F	; Jump if not

	or	PREFLAGS,@PREF_ES ; Mark as present

	jmp	AUTO_GPF_NEXTBYTE ; Go around again


@@:
	cmp	al,@OPCOD_DS	; Izit DS?
	jne	short @F	; Jump if not

	or	PREFLAGS,@PREF_DS ; Mark as present

	jmp	AUTO_GPF_NEXTBYTE ; Go around again


@@:
	cmp	al,@OPCOD_CS	; Izit CS?
	jne	short @F	; Jump if not

	or	PREFLAGS,@PREF_CS ; Mark as present

	jmp	AUTO_GPF_NEXTBYTE ; Go around again


@@:
	lea	edx,WGROUP:GPFTAB1 ; Assume it's the 1st table

	cmp	al,@OPCOD_2ND	; Izit in the 2nd table?
	jne	short @F	; Jump if not

	lea	edx,WGROUP:GPFTAB2 ; Assume it's the 2nd table
	mov	al,AGROUP:[ebx] ; Use 2nd opcode
	inc	ebx		; Skip over the secondary opcode
@@:
	add	edx,WINBASE	; Plus base of Autofault group in DGROUP
	movzx	eax,DGROUP:[edx+eax*(type GPFTAB1)] ; Get the opcode index
	lea	eax,WGROUP:GPFACT[eax*(type GPFACT)] ; Plus base of GPF action table
	add	eax,WINBASE	; Plus base of Autofault group in DGROUP

	jmp	DGROUP:[eax].EDD ; Take appropriate action


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; Check for CLI/STI in either PM or VM

	public	AUTO_GPF_CLISTI
AUTO_GPF_CLISTI:

; If the CPL > IOPL, it's a GPF

	mov	ax,AUTO_CPL	; Get CPL

	cmp	ax,AUTO_IOPL	; Izit valid (CPL <= IOPL)?
	ja	near ptr AUTO_GPF_IOPL ; Jump if not

	jmp	AUTO_GPF_UNK	; Join common unknown code


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; Check for PUSHFd/POPFd in VM

	public	AUTO_GPF_PPF
AUTO_GPF_PPF:
	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM?
	jz	near ptr AUTO_GPF_UNK ; Jump if not (huh??)

; If CPL > IOPL, it's a GPF

	mov	ax,AUTO_CPL	; Get CPL

	cmp	ax,AUTO_IOPL	; Izit valid (CPL <= IOPL)?
	ja	near ptr AUTO_GPF_IOPL ; Jump if not

	jmp	AUTO_GPF_UNK	; Join common unknown code


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; Check for INT/INTO/INT 03h

	public	AUTO_GPF_INT
AUTO_GPF_INT:
	mov	al,AGROUP:[ebx] ; Get the interrupt #

	jmp	short @F	; Join common code


	public	AUTO_GPF_INT3
AUTO_GPF_INT3:
	mov	al,03h		; Get the interrupt #

	jmp	short @F	; Join common code


	public	AUTO_GPF_INTO
AUTO_GPF_INTO:
	mov	al,04h		; Get the interrupt #
@@:
	mov	INTNO,al	; Save for later use

; Split out RM

	test	[ebp].FORW_EFL,mask $R2 ; Izit RM?
	jnz	near ptr AUTO_GPF_INTRM ; Jump if so

; Ensure the interrupt # is within the IDT limit

	movzx	edx,INTNO	; Get the interrupt #
	shl	edx,3-0 	; Convert from qwords to bytes

	add	edx,(size DESC_STR)-1 ; Add to get highest address

	cmp	dx,[ebp-@BPBACK].BACK_IDT.DTR_LIM ; Izit within the limit?
	ja	near ptr AUTO_GPF_IDTLIM ; Jump if not

	sub	edx,(size DESC_STR)-1 ; Restore

; Ensure the IDT descriptor is an interrupt, trap, or task gate

	add	edx,[ebp-@BPBACK].BACK_IDT.DTR_BASE ; Plus base of the IDT
	mov	al,AGROUP:[edx].IDT_ACCESS ; Get the A/R byte
	and	al,not (mask $DT_DPL) ; Clear the DPL bits

	cmp	al,CPL0_TASK	; Izit a task gate?
	je	short @F	; Jump if so

	cmp	al,CPL0_INTR2	; Izit a 286 interrupt gate?
	je	short @F	; Jump if so

	cmp	al,CPL0_TRAP2	; Izit a 286 trap gate?
	je	short @F	; Jump if so

	cmp	al,CPL0_INTR3	; Izit a 386 interrupt gate?
	je	short @F	; Jump if so

	cmp	al,CPL0_TRAP3	; Izit a 386 trap gate?
	jne	near ptr AUTO_GPF_IDTGAT ; Jump if not
@@:

; Ensure that the gate descriptor DPL >= CPL

	mov	al,AGROUP:[edx].IDT_ACCESS ; Get the A/R byte
	and	eax,mask $DT_DPL ; Isolate the DPL bits
	shr	eax,$DT_DPL	; Shift to low-order

	cmp	ax,AUTO_CPL	; Izit valid?
	jb	near ptr AUTO_GPF_IDTDPL ; Jump if not

; If it's not a task gate,
; ensure that the incoming CS is non-zero
; ...			      is within GDT/LDT limits
; ...			      A/R byte is CPL0_CODE

	mov	al,AGROUP:[edx].IDT_ACCESS ; Get the A/R byte
	and	al,not (mask $DT_DPL) ; Clear the DPL bits

	cmp	al,CPL0_TASK	; Izit a task gate?
	je	near ptr AUTO_GPF_INTTASK ; Jump if so

	movzx	ecx,AGROUP:[edx].IDT_SELECT ; Get the incoming selector
	and	cx,not (mask $PL) ; Clear the PL bits
	jz	near ptr AUTO_GPF_IDTCSNUL ; Jump if it's null

	movzx	eax,[ebp-@BPBACK].BACK_GDT.DTR_LIM ; Get the GDT limit

	btr	ecx,$TI 	; Izit in the LDT?
	jz	short @F	; Jump if not

	push	[ebp].FORW_LDT	; Pass the LDT selector
	call	GETLIMIT	; Return with EAX = selector limit
	jc	near ptr AUTO_GPF_IDTCSCOD ; Jump if something went wrong
@@:
	add	ecx,(size DESC_STR)-1 ; Add to get highest address

	cmp	ecx,eax 	; Izit within the limit?
	ja	near ptr AUTO_GPF_IDTCSBIG ; Jump if not

	sub	ecx,(size DESC_STR)-1 ; Restore

	push	AGROUP:[edx].IDT_SELECT ; Pass the incoming selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_GPF_UNK ; Jump if something went wrong

	mov	ah,al		; Save for later use
	and	ah,(mask $DT_DC) or (mask $DC_COD) ; Isolate code bits

	cmp	ah,(mask $DT_DC) or (mask $DC_COD) ; Izit a code selector?
	jne	near ptr AUTO_GPF_IDTCSCOD ; Jump if not

; If the code segment is non-conforming and DPL < CPL, ...

	test	ah,mask $DC_CONF ; Izit conforming?
	jnz	short AUTO_GPF_INTCONF ; Jump if so

	and	eax,mask $DT_DPL ; Isolate the DPL bits
	shr	eax,$DT_DPL	; Shift to low-order

	cmp	ax,AUTO_CPL	; Izit in this block?
	je	short AUTO_GPF_INTCONF ; Jump if not (DPL = CPL)
	ja	near ptr AUTO_GPF_IDTDCPL ; Jump if not valid

; If VM, ...

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM?
	jz	short AUTO_GPF_INTPM ; Jump if not

; If the gate's DPL < 3, it's a GPF

	cmp	ax,3		; Izit valid?
	jb	near ptr AUTO_GPF_IDTDPL3 ; Jump if not

; If CPL > IOPL, it's a GPF

	mov	ax,AUTO_CPL	; Get CPL

	cmp	ax,AUTO_IOPL	; Izit valid (CPL <= IOPL)?
	ja	near ptr AUTO_GPF_IOPL ; Jump if not

; If the target CS selector's CPL > 0, it's a GPF

	cmp	ax,0		; Izit valid?
	ja	near ptr AUTO_GPF_IDTCPL0 ; Jump if not

	jmp	AUTO_GPF_IDTCSEIP ; Join common code


; The interrupt/trap is in PM, code segment is conforming or DPL = CPL, ...

AUTO_GPF_INTPM:
AUTO_GPF_INTCONF:

; The interrupt is in a task gate, ...

AUTO_GPF_INTTASK:

; The only GPF here is if the EIP is beyond the CS limit

	jmp	AUTO_GPF_IDTCSEIP ; Join common code


; The interrupt is in RM, ...

AUTO_GPF_INTRM:









	jmp	AUTO_GPF_UNK	; Join common unknown code


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; Check for IRET

	public	AUTO_GPF_IRET
AUTO_GPF_IRET:

; If VM, ...

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM?
	jz	short AUTO_GPF_IRETPM ; Jump if not

; If IOPL < 3, it's a GPF

	cmp	AUTO_IOPL,3	; Izit valid?
	jb	near ptr AUTO_GPF_IOPL ; Jump if not

	jmp	AUTO_GPF_UNK	; Join common unknown code


AUTO_GPF_IRETPM:

; Ensure that the target CS is a valid selector

	mov	esi,[ebp-@BPBACK].BACK_SS.DTR_BASE ; Get base address of SS
	add	esi,[ebp].FORW_ESP ; Plus ESP to get linear address of the
				; stack at SS:ESP

; Split cases between IRET and IRETD

	test	PREFLAGS,@PREF_OSP ; Izit IRETD?
	jnz	short AUTO_GPF_IRETPM1 ; Jump if so

	mov	cx,AGROUP:[esi].IRET_CS ; Get the code selector
	movzx	ebx,AGROUP:[esi].IRET_IP ; Get the code offset

	jmp	short @F	; Join common code


AUTO_GPF_IRETPM1:
	mov	cx,AGROUP:[esi].IRETD_CS ; Get the code selector
	mov	ebx,AGROUP:[esi].IRETD_EIP ; Get the code offset
@@:
	push	cx		; Pass the selector
	call	GETLIMIT	; Return with EAX = selector limit
	xchg	eax,ecx 	; Swap so AX = selector
	jc	near ptr AUTO_GPF_IRETCS ; Jump if invalid selector

	cmp	ebx,ecx 	; Check against eIP
	ja	near ptr AUTO_GPF_IRETIP ; Jump if it's out of range





	jmp	AUTO_GPF_UNK	; Join common unknown code


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; Check LODS reading from DS (or segment override)

	public	AUTO_GPF_CHK_DSR
AUTO_GPF_CHK_DSR:

; If this is in VM, just check for bad limit

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM?
	jnz	near ptr AUTO_GPF_EA1 ; Jump if so

; Ensure that EA1SEL is valid and readable

	push	EA1SEL		; Pass the selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_GPF_DSR ; Jump if invalid (note CF=1)

	test	al,mask $DT_DC	; Izit data/code type?
	jz	near ptr AUTO_GPF_DSR ; Jump if not

	jmp	AUTO_GPF_EA1	; Join common code


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; Check SCAS reading from ES

	public	AUTO_GPF_CHK_ESR
AUTO_GPF_CHK_ESR:

; If this is in VM, just check for bad limit

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM?
	jnz	near ptr AUTO_GPF_EA1 ; Jump if so

; Ensure that EA1SEL is valid and readable

	push	EA1SEL		; Pass the selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_GPF_ESR ; Jump if invalid (note CF=1)

	test	al,mask $DT_DC	; Izit data/code type?
	jz	near ptr AUTO_GPF_ESR ; Jump if not

	jmp	AUTO_GPF_EA1	; Join common code


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; Check STOS writing into ES

	public	AUTO_GPF_CHK_ESW
AUTO_GPF_CHK_ESW:

; If this is in VM, just check for bad limit

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM?
	jnz	near ptr AUTO_GPF_EA1 ; Jump if so

; Ensure that ES is valid and writable

	push	EA1SEL		; Pass the selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_GPF_ESW ; Jump if invalid (note CF=1)

	and	al,(mask $DT_DC) or (mask $DC_COD) ; Isolate bits

	cmp	al,mask $DT_DC	; Izit data type?
	jne	near ptr AUTO_GPF_ESW ; Jump if not

	jmp	AUTO_GPF_EA1	; Join common code


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; Check MOVS reading from DS (or segment override) and writing into ES

	public	AUTO_GPF_CHK_DSR_ESW
AUTO_GPF_CHK_DSR_ESW:

; If this is in VM, just check for bad limit

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM?
	jnz	near ptr AUTO_GPF_EA1 ; Jump if so

; Ensure that EA1SEL is valid and readable

	push	EA1SEL		; Pass the selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_GPF_DSR ; Jump if invalid (note CF=1)

	test	al,mask $DT_DC	; Izit data/code type?
	jz	near ptr AUTO_GPF_DSR ; Jump if not

; Ensure that ES is valid and writable

	push	EA2SEL		; Pass the selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_GPF_ESW ; Jump if invalid (note CF=1)

	and	al,(mask $DT_DC) or (mask $DC_COD) ; Isolate bits

	cmp	al,mask $DT_DC	; Izit data type?
	jne	near ptr AUTO_GPF_ESW ; Jump if not

	jmp	AUTO_GPF_EA2	; Join common code


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; Check CMPS reading from DS (or segment override) and reading from ES

	public	AUTO_GPF_CHK_DSR_ESR
AUTO_GPF_CHK_DSR_ESR:

; If this is in VM, just check for bad limit

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM?
	jnz	near ptr AUTO_GPF_EA1 ; Jump if so

; Ensure that EA1SEL is valid and readable

	push	EA1SEL		; Pass the selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_GPF_DSR ; Jump if invalid (note CF=1)

	test	al,mask $DT_DC	; Izit data/code type?
	jz	near ptr AUTO_GPF_DSR ; Jump if not

; Ensure that ES is valid and readable

	push	EA2SEL		; Pass the selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_GPF_ESR ; Jump if invalid (note CF=1)

	test	al,mask $DT_DC	; Izit data/code type?
	jz	near ptr AUTO_GPF_ESR ; Jump if not

	jmp	AUTO_GPF_EA2	; Join common code


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; Check for I/O instructions

	public	AUTO_GPF_INIB,AUTO_GPF_OUTIB
AUTO_GPF_INIB:
AUTO_GPF_OUTIB:
	mov	ecx,1		; Assume byte width

	jmp	short AUTO_GPF_IO_IMMB ; Join common code


	public	AUTO_GPF_INIW,AUTO_GPF_OUTIW
AUTO_GPF_INIW:
AUTO_GPF_OUTIW:
	mov	ecx,2		; Assume word width

	jmp	short AUTO_GPF_IO_IMMW ; Join common code


	public	AUTO_GPF_INDB, AUTO_GPF_INSB
	public	AUTO_GPF_OUTDB,AUTO_GPF_OUTSB
AUTO_GPF_INDB:
AUTO_GPF_INSB:
AUTO_GPF_OUTDB:
AUTO_GPF_OUTSB:
	mov	ecx,1		; Assume byte width

	jmp	short AUTO_GPF_IO_DXB ; Join common code


	public	AUTO_GPF_INDW, AUTO_GPF_INSW
	public	AUTO_GPF_OUTDW,AUTO_GPF_OUTSW
AUTO_GPF_INDW:
AUTO_GPF_INSW:
AUTO_GPF_OUTDW:
AUTO_GPF_OUTSW:
	mov	ecx,2		; Assume word width

;;;;;;; jmp	short AUTO_GPF_IO_DXW ; Join common code


AUTO_GPF_IO_DXW:
	test	PREFLAGS,@PREF_OSP ; Izit dword width?
	jz	short @F	; Jump if not

	shl	ecx,1		; Mark as dword width
@@:
AUTO_GPF_IO_DXB:
	movzx	edx,[ebp].FORW_EDX.ELO ; Get the I/O port from DX

	jmp	short AUTO_GPF_IO_COM ; Join common code


AUTO_GPF_IO_IMMW:
	test	PREFLAGS,@PREF_OSP ; Izit dword width?
	jz	short @F	; Jump if not

	shl	ecx,1		; Mark as dword width
@@:
AUTO_GPF_IO_IMMB:
	movzx	edx,AGROUP:[ebx] ; Get the immediate I/O port
AUTO_GPF_IO_COM:

; If ((CPL > IOPL) or VM) and the corresponding bit in the I/O bit
; permission map is set, it's a GPF

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM?
	jnz	short @F	; Jump if so

	mov	ax,AUTO_CPL	; Get CPL

	cmp	ax,AUTO_IOPL	; Izit valid (CPL <= IOPL)?
	jbe	near ptr AUTO_GPF_UNK ; Jump if so
@@:

; Check the bit in the I/O bit permission map

	mov	edi,[ebp-@BPBACK].BACK_TR.DTR_BASE ; Get the base address

; AGROUP:EDI ==> current TSS

	movzx	eax,AGROUP:[edi].TSS_IOMAP ; Get offset to I/O bit permission map
@@:
	bt	AGROUP:[edi+eax],edx ; Izit set?
	jc	near ptr AUTO_GPF_IOMAP ; Jump if so

	inc	edx		; Skip to next I/O port

	loop	@B		; Jump if more I/O ports to check

; Perhaps it's INSB/W/D with a memory operand out of range

	cmp	AGROUP:[ebx-1].LO,@OPCOD_INSB ; Izit INSB?
	je	short AUTO_GPF_LIM ; Jump if so

	cmp	AGROUP:[ebx-1].LO,@OPCOD_INSW ; Izit INSW?
	je	short AUTO_GPF_LIM ; Jump if so

	jmp	AUTO_GPF_UNK	; Jump if not


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; Check MOV, SCAS, and STOS for target out of range

	public	AUTO_GPF_LIM
AUTO_GPF_EA1:
AUTO_GPF_LIM:

; Ensure EA1SEL is valid and EA1OFF is within EA1LIM limits

	call	CHECK_EA1	; Check EA1SEL, EA1OFF, and EA1LIM
	jc	near ptr AUTO_GPF_SEL ; Jump if invalid selector
	ja	near ptr AUTO_GPF_MEM ; Jump if invalid offset

	jmp	AUTO_GPF_UNK	; Join common unknown code


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; Check MOV and CMPS for target out of range

	public	AUTO_GPF_EA2
AUTO_GPF_EA2:

; Ensure EA2SEL is valid and EA2OFF is within EA2LIM limits

	call	CHECK_EA2	; Check EA2SEL, EA2OFF, and EA1LIM
	jc	near ptr AUTO_GPF_SEL ; Jump if invalid selector
	ja	near ptr AUTO_GPF_MEM ; Jump if invalid offset

	jmp	AUTO_GPF_UNK	; Join common unknown code


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; Check RET and RETP for target out of range

	public	AUTO_GPF_RET
AUTO_GPF_RET:

; Ensure EA1SEL is valid and EA1OFF is within EA1LIM limits

	call	CHECK_EA1	; Check EA1SEL, EA1OFF, and EA1LIM
	jc	near ptr AUTO_GPF_SEL ; Jump if invalid selector
	ja	near ptr AUTO_GPF_MEM ; Jump if invalid offset

	jmp	AUTO_GPF_UNK	; Join common unknown code


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; Check for Privileged (PL0-only) instructions

; CLTS
; HLT
; INVD
; WBINVD
; MOV r32,CRn
; MOV r32,DRn
; MOV r32,TRn
; MOV CRn,r32	 also if MOV CR0,r32 with PG=1/PE=0
;		 also if MOV CR4,r32 with reserved bits set
; MOV DRn,r32
; MOV TRn,r32
; RDMSR 	 also if ECX out of range
; WRMSR 	 ...
; INVLPG
; LGDTd
; LIDTd
; LLDT		 also if bad/LDT selector
; LMSW
; LTR		 also if bad/busy/LDT selector

AUTO_GPF_GRP6:
	mov	al,AGROUP:[ebx] ; Get the Mod R/M byte (if GRP6/7)
	and	al,mask $REG	; Isolate the REG bits

	cmp	al,010b shl $REG ; Izit LLDT?
	je	short AUTO_GPF_LLDT ; Jump if so

	cmp	al,011b shl $REG ; Izit LTR?
	je	short AUTO_GPF_LTR ; Jump if so

; Ensure EA1SEL is valid and EA1OFF is within EA1LIM limits

	call	CHECK_EA1	; Check EA1SEL, EA1OFF, and EA1LIM
	jc	near ptr AUTO_GPF_SEL ; Jump if invalid selector
	ja	near ptr AUTO_GPF_MEM ; Jump if invalid offset

	jmp	AUTO_GPF_UNK	; Join common unknown code


; If LLDT with bad or LDT selector, it's a GPF

AUTO_GPF_LLDT:

; If CPL > 0, it's a GPF

	cmp	AUTO_CPL,0	; Izit valid?
	ja	near ptr AUTO_GPF_NOTPL0 ; Jump if not

; Distinguish memory from register operand

	mov	al,AGROUP:[ebx] ; Get the Mod R/M byte
	and	al,mask $MOD	; Isolate the MOD bits

	cmp	al,11b shl $MOD ; Izit a register operand?
	jne	short AUTO_GPF_LLDT1 ; Jump if not

	mov	al,AGROUP:[ebx] ; Get the Mod R/M byte
	and	eax,mask $RM	; Isolate the R/M bits
	shr	eax,$RM 	; Shift to low-order
	sub	eax,(type PUSHAD_STR)/4-1 ; Subtract from top index of
	neg	eax		; ...struc to index from the top
	mov	ax,[ebp].FORW_EDI.ELO[eax*4] ; Get the GP register

	jmp	short AUTO_GPF_LLDT2 ; Join common code


AUTO_GPF_LLDT1:

; Ensure EA1SEL is valid and EA1OFF is within EA1LIM limits

	call	CHECK_EA1	; Check EA1SEL, EA1OFF, and EA1LIM
	jc	near ptr AUTO_GPF_SEL ; Jump if invalid selector
	ja	near ptr AUTO_GPF_MEM ; Jump if invalid offset

	mov	eax,EA1OFF	; Get the offset
	add	eax,EA1BASE	; Plus EA1 base
	mov	ax,AGROUP:[eax] ; Get the selector
AUTO_GPF_LLDT2:
	test	ax,mask $TI	; Izit in the LDT?
	jnz	near ptr AUTO_GPF_ERRLDTLDT ; Jump if so

	push	ax		; Pass the selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_GPF_SEL ; Jump if invalid selector

	jmp	AUTO_GPF_UNK	; Join common unknown code


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; If LTR with bad, busy, or LDT selector, it's a GPF

AUTO_GPF_LTR:

; If CPL > 0, it's a GPF

	cmp	AUTO_CPL,0	; Izit valid?
	ja	near ptr AUTO_GPF_NOTPL0 ; Jump if not

; Distinguish memory from register operand

	mov	al,AGROUP:[ebx] ; Get the Mod R/M byte
	and	al,mask $MOD	; Isolate the MOD bits

	cmp	al,11b shl $MOD ; Izit a register operand?
	jne	short AUTO_GPF_LTR1 ; Jump if not

	mov	al,AGROUP:[ebx] ; Get the Mod R/M byte
	and	eax,mask $RM	; Isolate the R/M bits
	shr	eax,$RM 	; Shift to low-order
	sub	eax,(type PUSHAD_STR)/4-1 ; Subtract from top index of
	neg	eax		; ...struc to index from the top
	mov	ax,[ebp].FORW_EDI.ELO[eax*4] ; Get the GP register

	jmp	short AUTO_GPF_LTR2 ; Join common code


AUTO_GPF_LTR1:

; Ensure EA1SEL is valid and EA1OFF is within EA1LIM limits

	call	CHECK_EA1	; Check EA1SEL, EA1OFF, and EA1LIM
	jc	near ptr AUTO_GPF_SEL ; Jump if invalid selector
	ja	near ptr AUTO_GPF_MEM ; Jump if invalid offset

	mov	eax,EA1OFF	; Get the offset
	add	eax,EA1BASE	; Plus EA1 base
	mov	ax,AGROUP:[eax] ; Get the selector
AUTO_GPF_LTR2:
	test	ax,mask $TI	; Izit in the LDT?
	jnz	near ptr AUTO_GPF_ERRLTRLDT ; Jump if so

	push	ax		; Pass the selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_GPF_SEL ; Jump if invalid selector

	and	al,not (mask $DT_DPL) ; Clear the DPL bits

	cmp	al,CPL0_BUSY2 ; Izit a busy 286 TSS?
	je	near ptr AUTO_GPF_ERRLTRBUSY ; Jump if so

	cmp	al,CPL0_BUSY3 ; Izit a busy 386 TSS?
	je	near ptr AUTO_GPF_ERRLTRBUSY ; Jump if so

; Ensure EA1SEL is valid and EA1OFF is within EA1LIM limits

	call	CHECK_EA1	; Check EA1SEL, EA1OFF, and EA1LIM
	jc	near ptr AUTO_GPF_SEL ; Jump if invalid selector
	ja	near ptr AUTO_GPF_MEM ; Jump if invalid offset

	jmp	AUTO_GPF_UNK	; Join common unknown code


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

AUTO_GPF_GRP7:
	mov	al,AGROUP:[ebx] ; Get the Mod R/M byte (if GRP6/7)
	and	al,mask $REG	; Isolate the REG bits

	cmp	al,010b shl $REG ; Izit LGDT?
	je	short AUTO_GPF_PL0 ; Jump if so

	cmp	al,011b shl $REG ; Izit LIDT?
	je	short AUTO_GPF_PL0 ; Jump if so

	cmp	al,110b shl $REG ; Izit LMSW?
	je	short AUTO_GPF_PL0 ; Jump if so

	cmp	al,111b shl $REG ; Izit INVLPG?
	je	short AUTO_GPF_PL0 ; Jump if so

; Ensure EA1SEL is valid and EA1OFF is within EA1LIM limits

	call	CHECK_EA1	; Check EA1SEL, EA1OFF, and EA1LIM
	jc	near ptr AUTO_GPF_SEL ; Jump if invalid selector
	ja	near ptr AUTO_GPF_MEM ; Jump if invalid offset

	jmp	AUTO_GPF_UNK	; Join common unknown code


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

AUTO_GPF_RDMSR:
AUTO_GPF_WRMSR:

; If CPL > 0, it's a GPF

	cmp	AUTO_CPL,0	; Izit valid?
	ja	near ptr AUTO_GPF_NOTPL0 ; Jump if not

; If RDMSR/WRMSR with ECX out of range, it's a GPF
; We're assuming that ECX is out of range

	jmp	AUTO_GPF_MSR	; Join common error code


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

AUTO_GPF_PL0:

; If CPL > 0, it's a GPF

	cmp	AUTO_CPL,0	; Izit valid?
	ja	near ptr AUTO_GPF_NOTPL0 ; Jump if not

; If MOV CR0,r32 with PG=1/PE=0, it's a GPF

	cmp	AGROUP:[ebx-2].ELO,@OPCOD_MOV_CRn_R32 ; Izit MOV CRn,r32?
	jne	short AUTO_GPF_XCR0 ; Jump if not

	mov	al,AGROUP:[ebx] ; Get the Mod R/M byte
	and	al,mask $REG	; Isolate the REG bits

	cmp	al,0 shl $REG	; Izit CR0?
	jne	short AUTO_GPF_XCR0 ; Jump if not

; Get the general register involved

	mov	al,AGROUP:[ebx] ; Get the Mod R/M byte
	and	eax,mask $RM	; Isolate the R/M bits
	shr	eax,$RM 	; Shift to low-order
	sub	eax,(type PUSHAD_STR)/4-1 ; Subtract from top index of
	neg	eax		; ...struc to index from the top
	mov	eax,[ebp].FORW_EDI[eax*4] ; Get the EGP register

	test	eax,mask $PG	; Izit set?
	jz	short @F	; Jump if not

	test	eax,mask $PE	; Izit set?
	jz	near ptr AUTO_GPF_CR0 ; Join if so
@@:
	jmp	AUTO_GPF_UNK	; Join common unknown code


AUTO_GPF_XCR0:

; If MOV CR4,r32 with reserved bits set, it's a GPF

	cmp	AGROUP:[ebx-2].ELO,@OPCOD_MOV_CRn_R32 ; Izit MOV CRn,r32?
	jne	short AUTO_GPF_XCR4 ; Jump if not

	mov	al,AGROUP:[ebx] ; Get the Mod R/M byte
	and	al,mask $REG	; Isolate the REG bits

	cmp	al,4 shl $REG	; Izit CR4?
	jne	short AUTO_GPF_XCR4 ; Jump if not

; We're assuming that some reserved bits are set

	jmp	AUTO_GPF_CR4	; Join common error code


AUTO_GPF_XCR4:
	jmp	AUTO_GPF_UNK	; Join common unknown code


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; Check for JeCXZ/JMP/Jcc/LOOPd to address out of range of CS limit

AUTO_GPF_REL8:
	movzx	eax,AGROUP:[ebx].LO ; Get the rel8 value

	jmp	short AUTO_GPF_RELCOM ; Join common code


AUTO_GPF_RELX:
	mov	eax,AGROUP:[ebx] ; Get the rel16/32 value

; If the instruction is USE32, use EAX, otherwise use AX

	test	PREFLAGS,@PREF_OSP ; Izit USE32?
	jnz	short AUTO_GPF_RELCOM ; Jump if so

	movzx	eax,ax		; Use AX
AUTO_GPF_RELCOM:
	add	eax,[ebp].FORW_EIP ; Plus the EIP

	cmp	eax,EA1LIM	; Izit within limits?
	ja	near ptr AUTO_GPF_REL ; Jump if not

	jmp	AUTO_GPF_UNK	; Join common unknown code


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

AUTO_GPF_GRP5:
	mov	al,AGROUP:[ebx] ; Get MOD R/M byte
	and	al,mask $REG	; Isolate the REG bits

	cmp	al,011b shl $REG ; Izit far CALL indirect?
	je	short AUTO_GPF_FJMP ; Jump if so

	cmp	al,101b shl $REG ; Izit far JMP indirect?
	je	short AUTO_GPF_FJMP ; Jump if so

	jmp	AUTO_GPF_UNK	; Jump if not


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Check for Far JMP/CALL

AUTO_GPF_FJMP:

; Ensure that the target selector is valid

	push	EA1TSEL 	; Get the target selector
	call	GETARW		; Return with AX = access rights word
	jc	near ptr AUTO_GPF_JMP1 ; Jump if something went wrong

	mov	AUTO_ARW,ax	; Save for later use

; Split cases based on the target selector type

	test	al,mask $DT_DC	; Izit a system selector?
	jz	short AUTO_GPF_JMPSYS ; Jump if so

	test	al,mask $DC_COD ; Izit code?
	jz	near ptr AUTO_GPF_JMP2 ; Jump if not

; Split cases based upon conforming vs. non-conforming

	test	al,mask $DC_CONF ; Izit conforming?
	jnz	short AUTO_GPF_JMPCONF ; Jump if so

; If non-conforming, ensure that DPL = CPL

	and	eax,mask $DT_DPL ; Isolate the DPL bits
	shr	eax,$DT_DPL	; Shift to low-order

	cmp	ax,AUTO_CPL	; Izit the same?
	jne	near ptr AUTO_GPF_JMP3 ; Jump if not

; If non-conforming, ensure that RPL <= CPL

	mov	ax,EA1TSEL	; Get the target selector
	and	ax,mask $PL	; Isolate the RPL bits

	cmp	ax,AUTO_CPL	; Izit valid?
	ja	near ptr AUTO_GPF_JMP4 ; Jump if not

	jmp	AUTO_GPF_UNK	; Join common unknown code


AUTO_GPF_JMPCONF:

; AX = A/R word
; If conforming, ensure that DPL <= CPL

	and	eax,mask $DT_DPL ; Isolate the DPL bits
	shr	eax,$DT_DPL	; Shift to low-order

	cmp	ax,AUTO_CPL	; Izit the same?
	ja	near ptr AUTO_GPF_JMP5 ; Jump if not

	jmp	AUTO_GPF_UNK	; Join common unknown code


; The target selector is a system selector
; We can assume it's present; otherwise, we'd get a #NP() error
; AX = A/R word

AUTO_GPF_JMPSYS:
	and	al,not (mask $DT_DPL) ; Clear the DPL bits

	cmp	al,CPL0_IDLE2	; Izit an idle 286 TSS?
	je	short AUTO_GPF_JMPTSS ; Jump if so

	cmp	al,CPL0_IDLE3	; Izit an idle 386 TSS?
	je	short AUTO_GPF_JMPTSS ; Jump if so

	cmp	al,CPL0_CALL2	; Izit a 286 call gate?
	je	short AUTO_GPF_JMPGATE ; Jump if so

	cmp	al,CPL0_CALL3	; Izit a 386 call gate?
	je	short AUTO_GPF_JMPGATE ; Jump if so

	cmp	al,CPL0_TASK	; Izit a task gate?
	je	short AUTO_GPF_JMPTASK ; Jump if so

; JMP/CALL target is TSS, task gate, or unknown

AUTO_GPF_JMPTSS:
AUTO_GPF_JMPTASK:
	jmp	AUTO_GPF_UNK	; Join common unknown code


; JMP/CALL target is call gate *FIXME*

AUTO_GPF_JMPGATE:

; Ensure that call gate DPL >= CPL


; Ensure that call gate DPL >= RPL


; Ensure that selector in call gate is non-zero and within GDT/LDT limits


; Ensure that selector in call gate is code


; Ensure that selector in call gate DPL <= CPL





	jmp	AUTO_GPF_UNK	; Join common unknown code


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

AUTO_GPF_LONG:
	lea	ebx,WGROUP:AFL_GPF_LONG ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_LONG ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_EIP:
	lea	ebx,WGROUP:AFL_GPF_EIP ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_EIP ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_IOPL:
	lea	ebx,WGROUP:AFL_GPF_IOPL ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_IOPL ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_NOTPL0:
	lea	ebx,WGROUP:AFL_GPF_NOTPL0 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_NOTPL0 ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_IOMAP:
	lea	ebx,WGROUP:AFL_GPF_IOMAP1 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_IOMAP1 ; Get offset of window descriptor

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM?
	jz	short @F	; Jump if not

	lea	ebx,WGROUP:AFL_GPF_IOMAP2 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_IOMAP2 ; Get offset of window descriptor
@@:
	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_MEM:
	lea	ebx,WGROUP:AFL_GPF_MEM ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_MEM ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_SEL:
	lea	ebx,WGROUP:AFL_GPF_SEL ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_SEL ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_ERRLTRBUSY:
	lea	ebx,WGROUP:AFL_GPF_LTRBUSY ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_LTRBUSY ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_GPF_LTRBUSYA ; Get offset of word save area

	jmp	AUTO_GPF_ERRWORD ; Join common error code


AUTO_GPF_ERRLTRLDT:
	lea	ebx,WGROUP:AFL_GPF_LTRLDT ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_LTRLDT ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_GPF_LTRLDTA ; Get offset of word save area

	jmp	AUTO_GPF_ERRWORD ; Join common error code


AUTO_GPF_ERRLDTLDT:
	lea	ebx,WGROUP:AFL_GPF_LDTLDT ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_LDTLDT ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_GPF_LDTLDTA ; Get offset of word save area

	jmp	AUTO_GPF_ERRWORD ; Join common error code


AUTO_GPF_MSR:
	lea	ebx,WGROUP:AFL_GPF_MSR ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_MSR ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_CR4:
	lea	ebx,WGROUP:AFL_GPF_CR4 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_CR4 ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_CR0:
	lea	ebx,WGROUP:AFL_GPF_CR0 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_CR0 ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_REL:
	lea	ebx,WGROUP:AFL_GPF_REL ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_REL ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_UNK:
	lea	ebx,WGROUP:AFL_GPF_UNK ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_UNK ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_IDTLIM:
	lea	ebx,WGROUP:AFL_GPF_IDTLIM ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_IDTLIM ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_IDTGAT:
	lea	ebx,WGROUP:AFL_GPF_IDTGAT ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_IDTGAT ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_IDTDPL:
	lea	ebx,WGROUP:AFL_GPF_IDTDPL ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_IDTDPL ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_IDTCSNUL:
	lea	ebx,WGROUP:AFL_GPF_IDTCSNUL ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_IDTCSNUL ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_IDTCSBIG:
	lea	ebx,WGROUP:AFL_GPF_IDTCSBIG ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_IDTCSBIG ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_IDTCSCOD:
	lea	ebx,WGROUP:AFL_GPF_IDTCSCOD ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_IDTCSCOD ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_IDTCSEIP:
	lea	ebx,WGROUP:AFL_GPF_IDTCSEIP ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_IDTCSEIP ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_IDTDPL3:
	lea	ebx,WGROUP:AFL_GPF_IDTDPL3 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_IDTDPL3 ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_IDTCPL0:
	lea	ebx,WGROUP:AFL_GPF_IDTCPL0 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_IDTCPL0 ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_IDTDCPL:
	lea	ebx,WGROUP:AFL_GPF_IDTDCPL ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_IDTDCPL ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_IRETCS:
	lea	ebx,WGROUP:AFL_GPF_IRETCS ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_IRETCS ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_GPF_IRETCSA ; Get offset of word save area

	jmp	AUTO_GPF_ERRWORD ; Join common error code


AUTO_GPF_IRETIP:
	lea	ebx,WGROUP:AFL_GPF_IRETIP ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_IRETIP ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_DSR:
	lea	ebx,WGROUP:AFL_GPF_DSR ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_DSR ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_ESR:
	lea	ebx,WGROUP:AFL_GPF_ESR ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_ESR ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_ESW:
	lea	ebx,WGROUP:AFL_GPF_ESW ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_ESW ; Get offset of window descriptor

	jmp	AUTO_GPF_ERRCOM ; Join common error code


AUTO_GPF_JMP1:
	mov	ax,EA1TSEL	; Get the target selector
	lea	ebx,WGROUP:AFL_GPF_JMP1 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_JMP1 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_GPF_JMP1A ; Get offset of word save area

	jmp	short AUTO_GPF_ERRWORD ; Join common error code


AUTO_GPF_JMP2:
	mov	ax,EA1TSEL	; Get the target selector
	lea	ebx,WGROUP:AFL_GPF_JMP2 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_JMP2 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_GPF_JMP2A ; Get offset of word save area

	jmp	short AUTO_GPF_ERRWORD ; Join common error code


AUTO_GPF_JMP3:
	mov	ax,EA1TSEL	; Get the target selector
	lea	ebx,WGROUP:AFL_GPF_JMP3 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_JMP3 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_GPF_JMP3A ; Get offset of word save area

	jmp	short AUTO_GPF_ERRWORD ; Join common error code


AUTO_GPF_JMP4:
	mov	ax,EA1TSEL	; Get the target selector
	lea	ebx,WGROUP:AFL_GPF_JMP4 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_JMP4 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_GPF_JMP4A ; Get offset of word save area

	jmp	short AUTO_GPF_ERRWORD ; Join common error code


AUTO_GPF_JMP5:
	mov	ax,EA1TSEL	; Get the target selector
	lea	ebx,WGROUP:AFL_GPF_JMP5 ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_GPF_JMP5 ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_GPF_JMP5A ; Get offset of word save area

	jmp	short AUTO_GPF_ERRWORD ; Join common error code


; Format a dword value into ES:EDI

AUTO_GPF_ERRDWORD:
	add	edi,WINBASE	; Plus base of Autofault group in DGROUP
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	jmp	short AUTO_GPF_ERRCOM ; Join common error code


; Format a word value into ES:EDI

AUTO_GPF_ERRWORD:
	add	edi,WINBASE	; Plus base of Autofault group in DGROUP
	call	BIN2WORD	; Convert AX to hex at ES:EDI
AUTO_GPF_ERRCOM:
	add	ebx,WINBASE	; Plus base of Autofault group in DGROUP
	add	ecx,WINBASE	; Plus base of Autofault group in DGROUP
	mov	LAST_AFLERR,ebx ; Save for next time
	mov	LAST_AFLWIN,ecx ; ...

	or	LC4_FLAG,@LC4_AFLTBD ; Mark as AutoFault message
				; to be displayed
AUTO_GPF_EXIT:
	REGREST <EA1WID,EA1MODE,EA1SEL,EA1TSEL,EA1LIM,EA1BASE,EA1OFF, \
		PREFLAGS,AUTO_ARW,AUTO_IOPL,AUTO_CPL>
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

AUTO_GPF endp			; End AUTO_GPF procedure
	NPPROC	AUTO_PF -- Analyze Page Faults
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Analyze Page Faults

On entry:

SS:EBP	==>	FORW_STR

On exit:

All EGP registers may be clobbered except EBP and ESP.

|

; Save CR2, CR3, and CR4

	mov	eax,cr2 	; Get the PF linear address
	mov	SAVE_CR2,eax	; Save for later use

	call	READ_CR3	; Get the value into EAX
	and	ax,mask $PTE_FRM ; Isolate 4KB frame
	mov	SAVE_CR3,eax	; Save for later use

	test	LCL_FLAG,@LCL_CPUID ; Is CPUID supported (and hence CR4)?
	jz	short @F	; Jump if not

	MOVSPR	eax,cr4 	; Get CPU extensions register
	mov	SAVE_CR4,eax	; Save for later use
@@:

; Save the Page Directory entry

	PUSHD	0		; Make room for original PDE
	PUSHD	1		; # PTEs to follow
	PUSHD	0		; Make room for original PDE
	push	SAVE_CR2	; Pass the linear address
	push	SAVE_CR3	; Pass the CR3 to use
	call	LIN2PPDIR	; Return with AGROUP:EAX ==> corresponding PDIR

	mov	eax,AGROUP:[eax] ; Get the corresponding PDIR

	call	LIN2PPTEZ	; Cleanup after LIN2PPDIR
	add	esp,1*4 	; Pop the PTE

; If this CPU doesn't support 4MB pages, clear the 4MB page bit so it doesn't
; confuse us later on.	Note that the CPUs which don't support this feature
; (486 and earlier) also don't complain about spurious reserved bits set,
; so we're not losing any information.

	test	SAVE_CR4,@PSE	; Izit supported?
	jnz	short @F	; Jump if so

	and	eax,not (mask $PTE_PS) ; Clear the PS bit
@@:
	mov	SAVE_PDE,eax	; Save for later use
	mov	SAVE_PTE,eax	; ...

; Split cases based upon the bits in the error code

	test	ERRCODE,mask $PF_RSV ; Izit due to a set reserved bit?
	jnz	near ptr AUTO_PF_RSV ; Jump if so

	test	ERRCODE,mask $PF_P ; Izit due to a not-present page?
	jz	near ptr AUTO_PF_NP ; Jump if so

; From here on we can be assured that the PTE is present
; so we read and save it for later use

; If this is a 4MB page, skip the PTE check

	test	SAVE_PDE,mask $PTE_PS ; Izit a 4MB page?
	jnz	short AUTO_PF1	; Jump if so

; Save the Page Table entry

	PUSHD	0		; Make room for original PDE
	PUSHD	1		; # PTEs to follow
	PUSHD	0		; Make room for original PDE
	push	SAVE_CR2	; Pass the linear address
	push	SAVE_CR3	; Pass the CR3 to use
	call	LIN2PPTE	; Return with AGROUP:EAX ==> corresponding PTE

	mov	eax,AGROUP:[eax] ; Get the corresponding PTE
	mov	SAVE_PTE,eax	; Save for later use

	call	LIN2PPTEZ	; Cleanup after LIN2PPTE
	add	esp,1*4 	; Pop the PTE
AUTO_PF1:

; Check for User-Supervisor mismatch

	test	ERRCODE,mask $PF_US ; Is the caller in User mode?
	jz	short @F	; Jump if not (no mismatch)

	test	SAVE_PTE,mask $PTE_US ; Does the PTE allow User access?
	jz	near ptr AUTO_PF_USER ; Jump if not (that's an error)
@@:

; Check for write into read-only page

	test	ERRCODE,mask $PF_RW ; Is the operation a write?
	jz	short @F	; Jump if not (not write into ROM)

	test	SAVE_PTE,mask $PTE_RW ; Does the PTE allow Write access?
	jz	near ptr AUTO_PF_ROM ; Jump if not (that's an error)
@@:

; The PF fault is unknown:  admit defeat

	lea	ebx,WGROUP:AFL_PF_UNK ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_PF_UNK ; Get offset of window descriptor

	jmp	AUTO_PF_ERRCOM	; Join common error code


; The Page Fault is due to a set reserved bit

AUTO_PF_RSV:

; Check for reserved bits in use

	lea	ebx,WGROUP:AFL_PF_RSVPDE ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_PF_RSVPDE ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_PF_RSVPDEA ; Get offset of dword save area

	mov	eax,SAVE_PDE	; Get the corresponding PDE

	test	SAVE_CR4,@PGE	; Are PTE Global Extensions enabled?
	jnz	short @F	; Jump if so

	test	eax,mask $PTE_G ; Is reserved bit in use?
	jnz	near ptr AUTO_PF_ERRDWORD ; Jump if so
@@:

; If this is a 4MB page, skip the PTE check

	test	eax,mask $PTE_PS ; Izit a 4MB page?
	jnz	short AUTO_PF_RSVUNK ; Jump if so

; Check the Page Table entry

	PUSHD	0		; Make room for original PDE
	PUSHD	1		; # PTEs to follow
	PUSHD	0		; Make room for original PDE
	push	SAVE_CR2	; Pass the linear address
	push	SAVE_CR3	; Pass the CR3 to use
	call	LIN2PPTE	; Return with AGROUP:EAX ==> corresponding PTE

	mov	eax,AGROUP:[eax] ; Get the corresponding PTE

	call	LIN2PPTEZ	; Cleanup after LIN2PPTE
	add	esp,1*4 	; Pop the PTE

; Check for reserved bits in use

	lea	ebx,WGROUP:AFL_PF_RSVPTE ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_PF_RSVPTE ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_PF_RSVPTEA ; Get offset of dword save area

	test	SAVE_CR4,@PGE	; Are PTE Global Extensions enabled?
	jnz	short @F	; Jump if so

	test	eax,mask $PTE_G ; Is reserved bit in use?
	jnz	near ptr AUTO_PF_ERRDWORD ; Jump if so
@@:
	test	SAVE_CR4,@PSE	; Are Page Size Extensions enabled?
	jnz	short @F	; Jump if so

	test	eax,mask $PTE_PS ; Is reserved bit in use?
	jnz	near ptr AUTO_PF_ERRDWORD ; Jump if so
@@:

; Unknown Reserved bits in use error

AUTO_PF_RSVUNK:
	lea	ebx,WGROUP:AFL_PF_RSVUNK ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_PF_RSVUNK ; Get offset of window descriptor

	jmp	AUTO_PF_ERRCOM	; Join common error code


; The Page Fault is due to a not-present page

AUTO_PF_NP:

; Check the Page Directory entry

	mov	eax,SAVE_PDE	; Get the PDE

	lea	ebx,WGROUP:AFL_PF_NPPDE ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_PF_NPPDE ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_PF_NPPDEA ; Get offset of dword save area

	test	eax,mask $PTE_P ; Izit present?
	jz	near ptr AUTO_PF_ERRDWORD ; Jump if not

; If this is a 4MB page, skip the PTE check

	test	eax,mask $PTE_PS ; Izit a 4MB page?
	jnz	short AUTO_PF_NPUNK ; Jump if so

; Check the Page Table entry

	PUSHD	0		; Make room for original PDE
	PUSHD	1		; # PTEs to follow
	PUSHD	0		; Make room for original PDE
	push	SAVE_CR2	; Pass the linear address
	push	SAVE_CR3	; Pass the CR3 to use
	call	LIN2PPTE	; Return with AGROUP:EAX ==> corresponding PTE

	mov	eax,AGROUP:[eax] ; Get the corresponding PTE

	call	LIN2PPTEZ	; Cleanup after LIN2PPTE
	add	esp,1*4 	; Pop the PTE

	lea	ebx,WGROUP:AFL_PF_NPPTE ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_PF_NPPTE ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_PF_NPPTEA ; Get offset of dword save area

	test	eax,mask $PTE_P ; Izit present?
	jz	near ptr AUTO_PF_ERRDWORD ; Jump if not

; Unknown Not-present page error

AUTO_PF_NPUNK:
	lea	ebx,WGROUP:AFL_PF_NPUNK ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_PF_NPUNK ; Get offset of window descriptor

	jmp	AUTO_PF_ERRCOM	; Join common error code


; The Page Fault is due to a User-Supervisor error

AUTO_PF_USER:

; Format the PDE

	mov	eax,SAVE_PDE	; Get the PDE
	mov	edx,WINBASE	; Get base of Autofault group in DGROUP
	lea	edi,WGROUP:AFL_PF_USER2[edx] ; Get offset of dword save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	lea	ebx,WGROUP:AFL_PF_USER ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_PF_USER ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_PF_USER3 ; Get offset of dword save area

; If this is a 4MB page, skip the PTE check

	test	eax,mask $PTE_PS ; Izit a 4MB page?
	jnz	short @F	; Jump if so

	test	eax,mask $PTE_P ; Izit present?
	mov	eax,SAVE_PTE	; Get the PTE
	jnz	short AUTO_PF_ERRDWORD ; Jump if so
@@:

; Clear the PTE

	mov	AGROUP:[edi+edx].EDQLO,'____' ; Clear 'em
	mov	AGROUP:[edi+edx].EDQHI,'____' ; ...

	jmp	AUTO_PF_ERRCOM	; Join common error code


; The Page Fault is due to a write to a read-only page

AUTO_PF_ROM:

; Format the PDE

	mov	eax,SAVE_PDE	; Get the PDE
	mov	edx,WINBASE	; Get base of Autofault group in DGROUP
	lea	edi,WGROUP:AFL_PF_ROM2[edx] ; Get offset of dword save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	lea	ebx,WGROUP:AFL_PF_ROM ; Get offset of error message
	lea	ecx,WGROUP:W_AFL_PF_ROM ; Get offset of window descriptor
	lea	edi,WGROUP:AFL_PF_ROM3 ; Get offset of dword save area

	test	eax,mask $PTE_PS ; Izit a 4MB page?
	jnz	short @F	; Jump if so

	test	eax,mask $PTE_P ; Izit present?
	mov	eax,SAVE_PTE	; Get the PTE
	jnz	short AUTO_PF_ERRDWORD ; Jump if so
@@:

; Clear the PTE

	mov	AGROUP:[edi+edx].EDQLO,'____' ; Clear 'em
	mov	AGROUP:[edi+edx].EDQHI,'____' ; ...

	jmp	AUTO_PF_ERRCOM	; Join common error code


; Format a dword value into ES:EDI

AUTO_PF_ERRDWORD:
	add	edi,WINBASE	; Plus base of Autofault group in DGROUP
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	jmp	AUTO_PF_ERRCOM	; Join common error code


; Format a word value into ES:EDI

AUTO_PF_ERRWORD:
	add	edi,WINBASE	; Plus base of Autofault group in DGROUP
	call	BIN2WORD	; Convert AX to hex at ES:EDI
AUTO_PF_ERRCOM:
	add	ebx,WINBASE	; Plus base of Autofault group in DGROUP
	add	ecx,WINBASE	; ...
	mov	LAST_AFLERR,ebx ; Save for next time
	mov	LAST_AFLWIN,ecx ; ...

	or	LC4_FLAG,@LC4_AFLTBD ; Mark as AutoFault message
				; to be displayed
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

AUTO_PF endp			; End AUTO_PF  procedure
	NPPROC	CHECK_EA1 -- Ensure EA1SEL, EA1OFF, and EA1LIM Are Valid
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Ensure EA1SEL, EA1OFF, and EA1LIM are valid

On entry:

SS:EBP	==>	FORW_STR

On exit:

CF	=	1 if invalid selector

|

	REGSAVE <eax>		; Save register

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM?
	jnz	short @F	; Jump if so (selector OK)

	test	EA1MODE,@MODE_SEP ; Is there a separator (and thus a selector)?
	jz	short @F	; Jump if not

	push	EA1SEL		; Pass the selector
	call	GETARW		; Return with AX = access rights word
	jc	short CHECK_EA1_EXIT ; Jump if invalid (note CF=1)
@@:

; Ensure it's within memory limits

	mov	eax,EA1OFF	; Get the offset
	add	eax,EA1WID	; Plus the width of the operand
	dec	eax		; Less one to get last valid address

	cmp	eax,EA1LIM	; Izit within limits?
	ja	short CHECK_EA1_EXIT ; Jump if invalid offset (note CF=ZF=0)

	cmp	ax,ax		; CF=0, ZF=1
CHECK_EA1_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_EA1 endp			; End CHECK_EA1 procedure
	NPPROC	CHECK_EA2 -- Ensure EA2SEL, EA2OFF, and EA2LIM Are Valid
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Ensure EA2SEL, EA2OFF, and EA2LIM are valid

On entry:

SS:EBP	==>	FORW_STR

On exit:

CF	=	1 if invalid selector

|

	REGSAVE <eax>		; Save register

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM?
	jnz	short @F	; Jump if so (selector OK)

	test	EA2MODE,@MODE_SEP ; Is there a separator (and thus a selector)?
	jz	short @F	; Jump if not

	push	EA2SEL		; Pass the selector
	call	GETARW		; Return with AX = access rights word
	jc	short CHECK_EA2_EXIT ; Jump if invalid (note CF=1)
@@:

; Ensure it's within memory limits

	mov	eax,EA2OFF	; Get the offset
	add	eax,EA2WID	; Plus the width of the operand
	dec	eax		; Less one to get last valid address

	cmp	eax,EA2LIM	; Izit within limits?
	ja	short CHECK_EA2_EXIT ; Jump if invalid offset (note CF=ZF=0)

	cmp	ax,ax		; CF=0, ZF=1
CHECK_EA2_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_EA2 endp			; End CHECK_EA2 procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_AFL module
