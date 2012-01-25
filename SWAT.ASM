;' $Header:   P:/PVCS/386SWAT/SWAT.ASV   1.85   10 Aug 1998 11:00:46   BOB  $
	 title	 SWAT -- 386MAX Debugger
	 page	 58,122
	 name	 SWAT

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.  All rights reserved.

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
	 include MASM5.MAC
	 include BITFLAGS.INC
	 include CPUFLAGS.INC
	 include LOADALL.INC
	 include KEYCODE.INC
	 include IOPBITS.INC
	 include OPCODES.INC
	 include 8255.INC
	 include 8259.INC
	 include ALLMEM.INC
	 include INTVEC.INC
	 include MOVSPR.INC
	 include CPUFET.INC
	 include SWAT_I3.INC
	include MSR.INC
	include WKD.INC
	include WINSTR.INC

	 include SWAT_AGR.INC
	 include SWAT_CMD.INC
	 include SWAT_COM.INC
	 include SWAT_DRV.INC
	 include SWAT_FMT.INC
	include SWAT_LBR.INC
	 include SWAT_LOG.INC
	 include SWAT_SEG.INC
	include SWAT_TSC.INC
	 include SWAT_VID.INC
	include SWATVXD.INC
.list

@MON_DEBUG equ	0

PDTGRP	 group	 PDTSEG


PDTSEG	 segment use32 dword at 0 ; Start PDTSEG segment
	 assume  ds:PDTGRP

	 public  OFFPDT
OFFPDT	 label	 dword

PDTSEG	 ends			; End PDTSEG segment


CODEZ	 segment use16 para public 'codez' ; Start CODEZ segment
	 assume  ds:PCODEZ

	 extrn	 ZTAIL:byte

CODEZ	 ends			; End CODEZ segment


DATA16	 segment use32 dword public 'data' ; Start DATA16 segment
	 assume  ds:DGROUP

	public	@SWAT_DATA16
@SWAT_DATA16 label byte 	; Mark module start in .MAP file

	 extrn	 CURPOSN:word
	 extrn	 CURTYPE:word

	 extrn	 NLSTBUF:dword
	 extrn	 PLSTBUF_IND:dword
	 extrn	 PPLSTBUF_TAB:dword
	 extrn	 PSCRBUF:dword

	 extrn	 ERRATTR:byte
	 extrn	 CPUFET_FLAG:dword

	extrn	LOGLEN:dword
	extrn	LOGOFF:dword
	extrn	LOGHEAD:dword

; The following structure *MUST* be first in DGROUP

	 public  COMMON
	 include QMAX_FIL.INC
COMMON	 FILE_STR <>		; Common data structure

	 public  LCLSTK_FVEC
LCLSTK_FVEC df	 ?		; Pointer to local stack

	 public  ARET_CNT,ARETBASE
ARET_CNT dw	 @ARET_CNT	; Current count of ARET entries
ARETBASE dd	 ?		; Base address of ARET_STR

	 public  ARG_FLAG
	 include SWAT_ARG.INC
ARG_FLAG dw	 0		; Argument flags (defined in SWAT_ARG.INC)

	 public  AR2_FLAG
;;;;;;;; include SWAT_AR2.INC
AR2_FLAG dw	 0		; Argument flags (defined in SWAT_AR2.INC)

	 public  LCL_FLAG
	 include SWAT_LCL.INC
LCL_FLAG dd	 0		; Local flags

	 public  LC2_FLAG
	 include SWAT_LC2.INC
LC2_FLAG dd	 0		; Local flags #2

	 public  LC3_FLAG
	 include SWAT_LC3.INC
LC3_FLAG dd	 0		; Local flags #3

	 public  LC4_FLAG
	 include SWAT_LC4.INC
LC4_FLAG dd	 0		; Local flags #4

	 public  PS4IO
PS4IO	 dw	 ?		; Periscope 4 board I/O port

	 public  SWATINFO
	 include SWAT_INF.INC
SWATINFO SWATINFO_STR <SWATINFO_LEN,		\
		       ?,			\
		       @SWATINFO_VER,		\
		       (offset DGROUP:ARG_FLAG)-(offset DGROUP:COMMON),  \
		       (offset DGROUP:LCL_FLAG)-(offset DGROUP:COMMON),  \
		       ,			\
		       ,			\
		       ,			\
		       (offset DGROUP:LC2_FLAG)-(offset DGROUP:COMMON),  \
		       (offset DGROUP:LC3_FLAG)-(offset DGROUP:COMMON)>
SWATINFO_LEN equ $-SWATINFO	; Length of above structure

DATA16	 ends			; End DATA16 segment


DATA	 segment use32 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	public	@SWAT_DATA
@SWAT_DATA label byte		; Mark module start in .MAP file

	 extrn	 @KEY_CTL_ESC:abs

	 extrn	 UNAMODE:word
	 include SWAT_MOD.INC

	 extrn	 MEMMODE:word
	 extrn	 MEMTYPE:dword
	 extrn	 @MEM_TSS:abs
	 extrn	 IOMAP_LINE:dword
	 extrn	 IOMAP_LINE_MAX:dword

	 extrn	 CMDOFF:dword
	 extrn	 MEMSIZE:dword
	 extrn	 W_TMP:tbyte

	 extrn	 INSTRLEN:dword
	 extrn	 INSTRLDN:dword
	 extrn	 INSTRPDN:dword
	 extrn	 INSTROUT:byte
	 extrn	 INSTRNLN:byte
	 extrn	 UNAOFF:dword
	 extrn	 UNASEL:word
	 extrn	 UNABASE:dword
	 extrn	 UNAMASK:dword
	 extrn	 UNACR3:dword
	 extrn	 CUR_INSTR:dword
	 extrn	 CUR_INSTR_ARW:word

	 extrn	 FIRST_INSTR:dword
	 extrn	 NEXT_INSTR:dword
	 extrn	 LAST_INSTR:dword
	 extrn	 MEMMASK:dword

	 extrn	 OLDEAX:dword
	 extrn	 OLDEBX:dword
	 extrn	 OLDECX:dword
	 extrn	 OLDEDX:dword
	 extrn	 OLDESI:dword
	 extrn	 OLDEDI:dword
	 extrn	 OLDEBP:dword
	 extrn	 OLDESP:dword
	 extrn	 OLDEIP:dword
	 extrn	 OLDEFL:dword
	 extrn	 OLDCR0:dword
	 extrn	 OLDCR2:dword

	 extrn	 OLDCS:word
	 extrn	 OLDDS:word
	 extrn	 OLDES:word
	 extrn	 OLDFS:word
	 extrn	 OLDGS:word
	 extrn	 OLDSS:word

	 extrn	 CUR_VM_HANDLE:dword
	 extrn	 OLD_CUR_VM_HANDLE:dword

	 extrn	 MSGOFF:dword
	 extrn	 ROMERR:byte
	 extrn	 NDPERR:byte
	 extrn	 PAGERR:byte
	 extrn	 SELERR:byte
	 extrn	 LNKERR:byte

	 extrn	 TOGINT01:tbyte
	 extrn	 TOGINT02:tbyte
	 extrn	 TOGINT03:tbyte
	 extrn	 TOGINT06:tbyte
	 extrn	 TOGINT0C:tbyte
	 extrn	 TOGINT0D:tbyte
	 extrn	 TOGINT0E:tbyte

	 extrn	 MEMGRAN:dword
	 extrn	 SYMCOUNT:dword
	 extrn	 @NSYMROWS:abs

	 extrn	 FBROWS_NAME:byte

	 extrn	 ERRLOG_CLINE:dword

;;;;;;; extrn	SELFDBG:dword

	 extrn	 LaSIGINT_BP:dword
	 extrn	 LaSIGINT_OLD:dword
	 extrn	 SIGINT_OLD:word
	extrn	SIGINT_SEL:word
	extrn	SIGINT_OFF:dword
	extrn	SIGINT_FLAG:word

	 extrn	 LAST_AFLERR:dword
	 extrn	 LAST_AFLWIN:dword

	 extrn	 BREAKPT_PTR:dword
	 extrn	 BREAKPT_VAL:byte
	 extrn	 BREAKPT_SEL:word
	 extrn	 BREAKPT_OFF:dword
	 extrn	 BREAKPT_FLAG:word

	extrn	ERRLOG_KEY:word

	extrn	OLD_TSC:qword
	extrn	KVARS_VEC:dword
	extrn	TDBSEL:word
	extrn	MDBSEL:word

	public	TSS_CNT
TSS_CNT dd	0		; Count of active TSSs

; Individual DRn references which we should ignore

	public	IND_DRn
IND_DRn dd	offset PGROUP:LCL_INT01_DR6
	dd	offset PGROUP:INIT_PROT_DR7R
	dd	offset PGROUP:INIT_PROT_DR7W
	dd	offset PGROUP:SWATTER_DR6
	dd	offset PGROUP:SWATTER_XSTK_DR6
	dd	offset PGROUP:SWATTER_XSTK_DR7
@IND_DRn_LEN equ ($-IND_DRn)/(type IND_DRn) ; # individual entries

RNG_STR struc

RNG_BEG dd	?		; Start of range
RNG_END dd	?		; End of range+1

RNG_STR ends

; Ranges of DRn references which we should ignore

	public	RNG_DRn
RNG_DRn RNG_STR <offset PGROUP:CMD_BDSET_A,offset PGROUP:CMD_BDSET_Z>
	RNG_STR <offset PGROUP:READ_CR3,   offset PGROUP:READ_CR3Z  >
	RNG_STR <offset PGROUP:WKD_DRnA,   offset PGROUP:WKD_DRnZ>
@RNG_DRn_LEN equ ($-RNG_DRn)/(type RNG_STR) ; # range entries

	 public  SAVE_DR6,SAVE_DR7,FORCE_DR7
	 align	 4		; Ensure dword-alignment
SAVE_DR6 dd	 ?		; Save area for DR6
SAVE_DR7 dd	 ?		; Save area for DR7
FORCE_DR7 dd	 0		; Forced bits (GD, that is)

	 public  ROMSKIP_MASK,ROMSKIP_DRN,ROMSKIP_DR7
ROMSKIP_MASK dd  0		; DR7 mask used for ROM single skip (Gn,Ln bits)
ROMSKIP_DRN  dd  0		; Storage for DRn during ROMSKIP
ROMSKIP_DR7  dd  0		; Storage for DR7 during ROMSKIP (Len,R/W bits)

	 public  IRET_VEC
IRET_VEC dd	 ?		; Segment:offset of an IRET in ROM

	 public  GDTOFF,IDTOFF,LDTOFF,MEMOFF,MACNDX,IVTNDX,WGHNDX
GDTOFF	 dd	 0		; GDT offset
IDTOFF	 dd	 0		; IDT ...
LDTOFF	 dd	 0		; LDT ...
MEMOFF	 dd	 0		; Memory ...
MACNDX	 dd	 0		; MAC entries
IVTNDX	 dd	 0		; IVT ...
WGHNDX	 dd	 0		; WGH ...

	 public  CON4KB,CON8KB,CON32KB,CON64KB,CON1MB
	 public  CON1P1MB
CON4KB	 dd	    4*1024	; Constant  4KB
CON8KB	 dd	    8*1024	; Constant  8KB
CON32KB  dd	   32*1024	; Constant 32KB
CON64KB  dd	   64*1024	; Constant 64KB
CON1MB	 dd	 1024*1024	; Constant  1MB
CON1P1MB dd (1024+64)*1024	; ...	  1.1MB

	 public  STACK_eSP,STACK_eBP
STACK_eSP dd	 ?		; SS:eSP linear address
STACK_eBP dd	 ?		; SS:eBP ...

	 public  PTE_START,PDE_START
PTE_START dd	 0		; Starting PTE offset for DISP_PTE
PDE_START dd	 0		; ...	   PDE ...	  DISP_PDE

	 public  SYMTAB_START
SYMTAB_START dd  0		; Starting record index into symbol table
				; This value ranges from zero to SYMCOUNT-1

	 public  LSCR_CNT
LSCR_CNT dd	 0		; Counter for last screens

	 public  OLDSS_STK
OLDSS_STK dw	 0		; Old SS for stack width display

	 public  INT_FLAG
;;;;;;;; include SWAT_INT.INC
INT_FLAG dw	 0		; Interrupt flags

	 align	 4		; Ensure aligned on dword boundary

	 public  REG_EAXDS,REG_RETEIP,REG_RETCSF,REG_EIP,REG_CSF,REG_EFL
	 public  REG_ESP,REG_SSF,REG_DSF,REG_ESF,REG_FSF,REG_GSF
REG_EAXDS dq	 ?		; Save area for INT 01h caller's DS:EAX
REG_RETEIP dd	 ?		;				 Return EIP
REG_RETCSF dd	 ?		;				 ...	CS w/filler
REG_EIP  dd	 ?		;				 EIP
REG_CSF  dd	 ?		;				 CS with filler
REG_EFL  dd	 ?		;				 EFL
REG_ESP  dd	 ?		;				 ESP
REG_SSF  dd	 ?		;				 SS with filler
REG_DSF  dd	 ?		;				 DS with filler
REG_ESF  dd	 ?		;				 ES with filler
REG_FSF  dd	 ?		;				 FS with filler
REG_GSF  dd	 ?		;				 GS with filler

	 public  ERRCODE
ERRCODE  dd	 ?		; Caller's error code

	 public  RETFL
RETFL	 dd	 ?		; DISPSINTR caller's flags

	 public  XPMSTK_FVEC
XPMSTK_FVEC df	 ?		; Save area for caller's stack pointer

	 public  REENTRY
REENTRY  dw	 0		; Re-entry count

	public	FORWSTR_FVEC
FORWSTR_FVEC df ?		; Ptr to last valid FORW_STR

	 public  ERRMSG
ERRMSG	 db	 @NCOLS dup (?) ; Save area for error message

	 public  DSP_STATE,DSP_STAT2,DSP_STAT3
DSP_STATE db	 ?		; Screen state
DSP_STAT2 db	 ?		; Secondary screen state for overlays
DSP_STAT3 db	 0		; Prior DSP_STATE value for source debugging

if @MON_DEBUG
	 public  MON_CURINST
MON_CURINST db	 'cs:eip '
MON_CURINSTCS db 'xxxx:'
MON_CURINSTEIP db 'xxxxxxxx ('
MON_CURINSTLA db 'xxxxxxxx)',0
endif				; Monitor debugging on

@KMSG_DEBUG	equ	0

if @KMSG_DEBUG
	 public  KMSG_COMP
KMSG_COMP db	 '.csip = '
KMSG_LA  db	 'xxxxxxxx, {.csip = '
KMSG_DW1 db	 'xxxxxxxx, '
KMSG_DW2 db	 'xxxxxxxx',0
endif				; Kluge message debugging on

	 align	 4		; Ensure aligned on dword boundary

	 public  DISP_ACT
	 public  SCRUP_ACT,SCRDN_ACT
	 public  SCRPGUP_ACT,SCRPGDN_ACT
	 public  INCLOC_ACT,DECLOC_ACT
DISP_ACT    dd	 @DSP_CNT dup (?) ; Display actions
SCRUP_ACT   dd	 @DSP_CNT dup (?) ; Scroll up ...
SCRDN_ACT   dd	 @DSP_CNT dup (?) ; Scroll down ...
SCRPGUP_ACT dd	 @DSP_CNT dup (?) ; Page up ...
SCRPGDN_ACT dd	 @DSP_CNT dup (?) ; Page down ...
INCLOC_ACT  dd	 @DSP_CNT dup (?) ; Increment location ...
DECLOC_ACT  dd	 @DSP_CNT dup (?) ; Decrement ...

ACT_MAC  macro	 NAM
	 local	 L1
L1	 label	 dword

	 org	 DISP_ACT+@DSP_&NAM*(type DISP_ACT)
	 dd	 offset PGROUP:DISP_&NAM

	 org	 SCRUP_ACT+@DSP_&NAM*(type SCRUP_ACT)
	 dd	 offset PGROUP:SCRUP_&NAM

	 org	 SCRDN_ACT+@DSP_&NAM*(type SCRDN_ACT)
	 dd	 offset PGROUP:SCRDN_&NAM

	 org	 SCRPGUP_ACT+@DSP_&NAM*(type SCRPGUP_ACT)
	 dd	 offset PGROUP:SCRPGUP_&NAM

	 org	 SCRPGDN_ACT+@DSP_&NAM*(type SCRPGDN_ACT)
	 dd	 offset PGROUP:SCRPGDN_&NAM

	 org	 INCLOC_ACT+@DSP_&NAM*(type INCLOC_ACT)
	 dd	 offset PGROUP:INCLOC_&NAM

	 org	 DECLOC_ACT+@DSP_&NAM*(type DECLOC_ACT)
	 dd	 offset PGROUP:DECLOC_&NAM

	 org	 L1

	 endm			; ACT_MAC

	 ACT_MAC IREGS		; Display instructions
	 ACT_MAC GDT		; ... GDT entries
	 ACT_MAC IDT		; ... IDT ...
	 ACT_MAC LDT		; ... LDT ...
	 ACT_MAC TSS		; ... TSS
	 ACT_MAC PTE		; ... PTE
	 ACT_MAC PDE		; ... PDE
	 ACT_MAC MEM		; ... memory
	 ACT_MAC DRn		; ... debug registers
	 ACT_MAC SRCH		; ... search screen
	 ACT_MAC BC		; ... code breakpoints
	 ACT_MAC LSCR		; ... last screen
	 ACT_MAC SYMTAB 	; ... symbol table
	 ACT_MAC FBROWS 	; ... file browser
	 ACT_MAC ERRLOG 	; ... error log
	 ACT_MAC MAC		; ... MAC entries
	 ACT_MAC IVT		; ... IVT ...
	 ACT_MAC WGH		; ... WGH ...
	 ACT_MAC TDB		; ... TDB ...
	 ACT_MAC MDB		; ... MDB ...

	 public  MSG_BT,MSG_BD,MSG_B0,MSG_B1,MSG_B2,MSG_B3
MSG_BT	 db	 'TSS debug trap',0
MSG_BD	 db	 'GD debug trap',0
MSG_B0	 db	 'DR0 trap',0
MSG_B1	 db	 'DR1 trap',0
MSG_B2	 db	 'DR2 trap',0
MSG_B3	 db	 'DR3 trap',0

	 public  MSG_LAST
MSG_LAST db	 'Last screen-' ; Message when displaying last screen
MSG_LAST0 db	 'xx'
MSG_LAST1 db	 'x'            ; Units digit of #
MSG_LASTLEN equ  $-MSG_LAST	; Length of message

DATA	 ends			; End DATA segment


KEYMAC	 macro	 KEY,ACT,SAV

KEYSEG	 segment use32 word public 'data' ; Start KEYSEG segment
	 assume  ds:DGROUP

	 dw	 @KEY_&KEY

KEYSEG	 ends			; End KEYSEG segment


ACTSEG	 segment use32 dword public 'data' ; Start ACTSEG segment
	 assume  ds:DGROUP

	 public  SWATTER_&ACT
	 dd	 offset PGROUP:SWATTER_&ACT

ACTSEG	 ends			; End ACTSEG segment

	 endm			; KEYMAC


KEYSEG	 segment use32 word public 'data' ; Start KEYSEG segment
	 assume  ds:DGROUP

	public	@SWAT_KEYVAL
@SWAT_KEYVAL label byte 	; Mark module start in .MAP file

	 public  KEYVAL
KEYVAL	 label	 word

KEYSEG	 ends			; End KEYSEG segment


ACTSEG	 segment use32 dword public 'data' ; Start ACTSEG segment
	 assume  ds:DGROUP

	public	@SWAT_KEYACT
@SWAT_KEYACT label byte 	; Mark module start in .MAP file

	 public  KEYACT
KEYACT	 label	 dword

ACTSEG	 ends			; End ACTSEG segment


	 KEYMAC  AWIN,		HELP	; Display help screen
	 KEYMAC  F1,		HELP	; Display help screen
	 KEYMAC  F2,		GDT	; Display GDT
	 KEYMAC  F3,		LDT	; Display LDT
	 KEYMAC  F4,		IDT	; Display IDT
	 KEYMAC  F5,		PTE	; Display PTEs
	 KEYMAC  F6,		SRCH	; Display search
	 KEYMAC  F7,		MEM	; Display memory
	 KEYMAC  F8,		TSS	; Display TSS
	 KEYMAC  F9,		REGS	; Display registers
	 KEYMAC  F10,		SCR	; Display program screen
	 KEYMAC  F11,		TRACE	; Single-step
	 KEYMAC  F12,		SKIP	; Single-skip

	 KEYMAC  SHF_F1,	AGOTO	; Push current addr, goto addr ref top
	 KEYMAC  SHF_F2,	ARET	; Return from addr
	 KEYMAC  SHF_F3,	BGOTO	; Breakpoint to top line address
	 KEYMAC  SHF_F4,	AFL	; Display last AutoFault message
	 KEYMAC  SHF_F5,	IVT	; Display RM IVT
;;;;;;;; KEYMAC  SHF_F6,
;;;;;;;; KEYMAC  SHF_F7,
;;;;;;;; KEYMAC  SHF_F8,
;;;;;;;; KEYMAC  SHF_F9,
	 KEYMAC  SHF_F10,	ASCR	; Append current screen to last screen buffer
;;;;;;;; KEYMAC  SHF_F11,
;;;;;;;; KEYMAC  SHF_F12,

	 KEYMAC  ALT_F1,	I0103	; Toggle intercept of INT 01h/03h
	 KEYMAC  ALT_F2,	I02	; Toggle intercept of INT 02h
	 KEYMAC  ALT_F3,	I0D	; Toggle intercept of INT 0Dh
	 KEYMAC  ALT_F4,	I0E	; Toggle intercept of INT 0Eh
	 KEYMAC  ALT_F5,	STK	; Toggle stack display width
	 KEYMAC  ALT_F6,	SCRN	; Toggle screen save on/off
	 KEYMAC  ALT_F7,	VBASE	; Toggle video base address
	 KEYMAC  ALT_F8,	NDP	; Display NDP registers
	 KEYMAC  ALT_F9,	DRn	; Display debug registers
	 KEYMAC  ALT_F10,	LSCR	; Display last screen buffer
;;;;;;;; KEYMAC  ALT_F11,
;;;;;;;; KEYMAC  ALT_F12,

	 KEYMAC  ALT_F, 	GRETF	; Goto .RETF
	 KEYMAC  ALT_N, 	GRETN	; ...  .RETN
	 KEYMAC  ALT_COMMA,	CMDPREV ; Retrieve previous command
	 KEYMAC  ALT_PERIOD,	CMDNEXT ; ...	   next     ...
	 KEYMAC  ALT_SLASH,	CMDHIST ; Display command history

	 KEYMAC  CTL_F1,	I01	; Toggle intercept of INT 01h
	 KEYMAC  CTL_F2,	I03	; ...			  03h
	 KEYMAC  CTL_F3,	I06	; ...			  06h
	 KEYMAC  CTL_F4,	I0C	; ...			  0Ch
	 KEYMAC  CTL_F5,	PDE	; Display PDE entries
	 KEYMAC  CTL_F6,	SYMTAB	; Display symbol table
	 KEYMAC  CTL_F7,	FBROWS	; Display file browser screen
	 KEYMAC  CTL_F8,	CHAT	; Enter CHAT mode
	 KEYMAC  CTL_F9,	REMDBG	; Enter remote debugging mode
	 KEYMAC  CTL_F10,	ERRLOG	; Display error log screen
	 KEYMAC  CTL_F11,	CTLTRACE; Single-step INT into PM
;;;;;;;; KEYMAC  CTL_F12,

	 KEYMAC  CTL_B, 	MBYTE	; Display memory in byte format
	 KEYMAC  CTL_D, 	MDWORD	; ...		    dword ...
	 KEYMAC  CTL_G, 	MGDT	; ...		    GDT ...
	 KEYMAC  CTL_I, 	MIDT	; ...		    IDT ...
	 KEYMAC  CTL_K, 	WKD	; ... WKD menu
	 KEYMAC  CTL_M, 	MAC	; Display memory in MAC format
	 KEYMAC  CTL_T, 	MTSS	; ...		    TSS ...
	 KEYMAC  CTL_V, 	MVECT	; ...		    vector...
	 KEYMAC  CTL_W, 	MWORD	; ...		    word ...
	 KEYMAC  CTL_Z, 	ZAP	; Convert top instruction to NOPs

	 KEYMAC  ESC,		ESC	; Quit
	 KEYMAC  CTL_ESC,	CTLESC	; Quit and skip over INT 03h
	 KEYMAC  PADPLUS,	TRACE	; Single-step
	 KEYMAC  CTL_PADPLUS	CTLTRACE; Single-step INT into PM
	 KEYMAC  PADMINUS,	SKIP	; Single-skip
	 KEYMAC  PADSTAR,	BGOTO	; Breakpoint to top line address
	 KEYMAC  CTL_UP,	DECLOC	; Decrement location
	 KEYMAC  CTL_XUP,	DECLOC	; ...
	 KEYMAC  CTL_DN,	INCLOC	; Increment location
	 KEYMAC  CTL_XDN,	INCLOC	; ...
	 KEYMAC  CTL_HOME,	HOME	; Home to current instruction
	 KEYMAC  CTL_XHOME,	HOME	; Home to current instruction
	 KEYMAC  UP,		SCRUP	; Scroll screen up
	 KEYMAC  XUP,		SCRUP	; Scroll screen up
	 KEYMAC  DN,		SCRDN	; Scroll screen down
	 KEYMAC  XDN,		SCRDN	; Scroll screen down
	 KEYMAC  PGUP,		SCRPGUP ; Scroll screen page up
	 KEYMAC  XPGUP, 	SCRPGUP ; Scroll screen page up
	 KEYMAC  PGDN,		SCRPGDN ; Scroll screen page down
	 KEYMAC  XPGDN, 	SCRPGDN ; Scroll screen page down


KEYSEG	 segment use32 word public 'data' ; Start KEYSEG segment
	 assume  ds:DGROUP

	 public  NKEYVAL
NKEYVAL  equ	 ($-KEYVAL)/(type KEYVAL) ; # valid keystrokes

KEYSEG	 ends			; End KEYSEG segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 extrn	 INIT_VIRT:far

XCODE	 ends			; End XCODE segment


XDATAZ	 segment use16 para public 'xdataz' ; Start XDATAZ segment
	 assume  ds:XGROUP

	 extrn	 XTAIL:byte

XDATAZ	 ends			; End XDATAZ segment


NCODE	 segment use16 para public 'ncode' ; Start NCODE segment
	 assume  cs:NGROUP,ds:NGROUP

	 extrn	 DEV_INTR_NR:far
	 extrn	 INIT_REAL:far

	 public  PTAIL
PTAIL	 label	 byte		; Note the PARA-alignment of this segment

NCODE	 ends			; End NCODE segment


RCODE	 segment use16 para public 'rcode' ; Start RCODE segment
	 assume  cs:RGROUP

	 extrn	 DEV_STRA:far

RCODE	 ends			; End RCODE segment


PROG0	segment use32 byte public 'prog' ; Start PROG0 segment
	assume	cs:PGROUP,ds:PGROUP

	public	@SWAT_PROG0
@SWAT_PROG0:			; Mark module start in .MAP file

	 public  SWATSTART
SWATSTART label  near

; SWATINI must be the first variable in this group

	 public  SWATINI
	 include MAXDEV.INC
SWATINI  MD_STR  <,			\
		  @MD_EXE or @MD_VER or @MD_USE32,\
		  '386SWAT ',           \
		  NGROUP:INIT_REAL,	\
		  offset PGROUP:INIT_PROT,\
		  offset PGROUP:REST_PROT,\
		  NGROUP:PTAIL, 	\
		  PCODEZ:ZTAIL, 	\
		  offset PGROUP:SWATTER,\
		  offset PGROUP:SAVEMSG,\
		  @IMRBASE,@IMR2BASE,	\
		  ,			\
		  @APIVER,		\
		  ,			\
		  XGROUP:INIT_VIRT,	\
		  ,			\
		  ,			\
		  ,			\
		  XGROUP:XTAIL>
L1:

; Define segment values in DDs for Seg:Off which the LINKer forgets

	 org	 SWATINI.MD_IREAL.VSEG
	 dw	 seg NGROUP		; For INIT_REAL
	 org	 SWATINI.MD_SIZE.VSEG
	 dw	 seg NGROUP		; For PTAIL
	 org	 SWATINI.MD_DATA.VSEG
	 dw	 seg PCODEZ		; For ZTAIL
	 org	 SWATINI.MD_IVIRT.VSEG
	 dw	 seg XGROUP		; For INIT_VIRT
	 org	 SWATINI.MD_VSIZE.VSEG
	 dw	 seg XGROUP		; For XTAIL

; Define DOS device driver header

	 org	 SWATINI
	 include DEVDRV.INC
	 DD_STR  <,			\
		  DRV_ATTR_CHAR,	\
		  PGROUP:LDEV_STRA-PGROUP:SWATSTART,\
		  PGROUP:LDEV_INTR-PGROUP:SWATSTART,\
		  '386SWAT$'>
	 org	 L1

; PMSWAT_WKD must be the second entry in this group
; so that the corresponding variable in SWAT_DRV.ASM is
; at the same offset within the code segment

	extrn	PM_WKDCB:near
	extrn	LCL_INT41:near

	public	PMSWAT_WKDCB
PMSWAT_WKDCB:
	jmp	PM_WKDCB	; Jump to actual code

	public	PMSWAT_INT41
PMSWAT_INT41:
	jmp	LCL_INT41	; Jump to actual code

	FPPROC	DEV_FNS -- Local DEV_STRA and DEV_INTR Routines
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	public	DEVLOAD
DEVLOAD db	0		; Device load flags

; We need to contruct the following JMPs by hand as the USE32
; setting of this segment produces an OSP when we don't want one.

	public	LDEV_STRA
LDEV_STRA:
	FIJMP	RGROUP:DEV_STRA,<seg RGROUP>

	public	LDEV_INTR
LDEV_INTR:
	FIJMP	NGROUP:DEV_INTR_NR,<seg NGROUP>

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEV_FNS endp			; End DEV_FNS procedure

PROG0	ends			; End PROG0 segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	public	@SWAT_PROG
@SWAT_PROG:			; Mark module start in .MAP file

	 extrn	 INIT_PROT:far
	 extrn	 REST_PROT:far
	 extrn	 SETUP:near

	 extrn	 SAVE_IRQS:near
	 extrn	 ENABLE_IRQS:near
	 extrn	 REST_IRQS:near
	extrn	U32_PPI_S2K_K2S:near

;;;;;;;; extrn	 HOUSE_DOG:near
	 extrn	 IZIT286:near

	 extrn	 GETKEY:near

	 extrn	 GETBASE:near
	 extrn	 GETARW:near

	 extrn	 DISP_IREGS:near
	 extrn	 DISP_HELP:near
	 extrn	 DISP_GDT:near
	 extrn	 DISP_IDT:near
	 extrn	 DISP_LDT:near
	 extrn	 DISP_TSS:near
	 extrn	 DISP_MEM:near
	 extrn	 DISP_DRn:near
	 extrn	 DISP_SRCH:near
	 extrn	 DISP_NDP:near
	 extrn	 DISP_STK:near
	 extrn	 DISP_PTE:near
	 extrn	 DISP_PDE:near
	 extrn	 DISP_SYMTAB:near
	 extrn	 DISP_FBROWS:near
	 extrn	 DISP_ERRLOG:near
	 extrn	 DISP_MSGLINE:near
	 extrn	 DISP_BC:near
	 extrn	 DISP_MAC:near
	 extrn	 DISP_IVT:near
	 extrn	 DISP_WGH:near
	 extrn	 DISP_WKD:near
	 extrn	 DISP_BLK1:near
	extrn	DISP_TDB:near
	extrn	DISP_MDB:near
	extrn	CMD_RETR_PREV:near
	extrn	CMD_RETR_NEXT:near
	extrn	CMD_DISP_HIST:near

	 extrn	 DISPPHYS:near
	 extrn	 DISPVIRT:near

	 extrn	 MEMACT_B:near
	 extrn	 MEMACT_W:near
	 extrn	 MEMACT_D:near
	 extrn	 MEMACT_V:near
	 extrn	 MEMACT_G:near
	 extrn	 MEMACT_I:near
	 extrn	 MEMACT_T:near

	 extrn	 CMD_CHAR:near

	 extrn	 DISP_CMDLINE:near
	 extrn	 CLEAR_MSG:near

	 extrn	 INST_BCVAL:near
	 extrn	 CHECK_BCVAL:near
	 extrn	 REST_BCVAL:near

	 extrn	 SAVE_IMR:near
	 extrn	 REST_IMR:near

	 extrn	 SAVE_SCR:near
	 extrn	 REST_SCR:near
	 extrn	 CHECK_VMOD:near

	 extrn	 SAVE_SCRDATA:near
	 extrn	 SET_CURPOS:near
	 extrn	 SET_CURTYP:near

	 extrn	 DISASSEMBLE:near
	 extrn	 BIN2WORD:near
if @MON_DEBUG
	 extrn	 BIN2DWORD:near
endif				; Monitor debugging on
	 extrn	 DD2DEC:near
	 extrn	 WPUT_CSA:near

	 extrn	 FLIPVBASE:near

	 extrn	 DECODE_ADDR:near

	 extrn	 DVGASEL0:near
	 extrn	 DVGASEL1:near

	 extrn	 CHECK_PMTSS:near

	 extrn	 ADJUST_SLINE:near
	 extrn	 SYMHASH_SRCH:near

	 extrn	 CMD_CHAT:near
	 extrn	 CMD_REMDBG:near
	 extrn	 SER_INIT:near
	 extrn	 LDISPMSG:near
	 extrn	 LDISPTXT:near

	 extrn	 READ_CR3:near
	 extrn	 READ_CR3Z:near

	 extrn	 ACT_TOGINT:near

	 extrn	 AUTOFAULT:near

	 extrn	 PARSE_RETF:near
	 extrn	 PARSE_RETN:near

	 extrn	 IS_MONITOR:near

	 extrn	 INT1_RETURN:near

	extrn	READ_LBR:near
	extrn	SET_LBR:near
	extrn	SET_BTF:near
	extrn	CLR_BTF:near

	extrn	LCL_INT01_DR6:near
	extrn	INIT_PROT_DR7R:near
	extrn	INIT_PROT_DR7W:near
	extrn	CMD_BDSET_A:near
	extrn	CMD_BDSET_Z:near

	extrn	WKD_DRnA:near
	extrn	WKD_DRnZ:near

	 FPPROC  SAVEMSG -- Save Error Message
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save error message address

Note that this routine returns via RETFD.

|

SAVEMSG_STR struc

	 dd	 ?		; Caller's EBP
SAVEMSG_EIP dd	 ?		; ...	   EIP
SAVEMSG_CSF dw	 ?,?		; ...	   CS with filler
SAVEMSG_VEC df	 ?		; Address of error message
	 dw	 ?		; Filler
SAVEMSG_ERR dd	 ?		; Error code

SAVEMSG_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,esi,edi,ds,es> ; Save registers

	 cld			; Ensure pointing forwards

	 lds	 esi,[ebp].SAVEMSG_VEC ; DS:ESI ==> error message
	 assume  ds:nothing	; Tell the assembler about it

	 SETDATA es		; Set data selector into ES
	 assume  es:DGROUP	; Tell the assembler about it

	 lea	 edi,ERRMSG	; ES:EDI ==> local save area

	 mov	 al,'¯'         ; Save leading separator
S32	 stos	 ERRMSG[edi]	; Save in output area

; Copy the message to our local buffer

	 cld			; String ops forwardly
@@:
	 lods	 ds:[esi].LO	; Get the next byte
S32	 stos	 ERRMSG[edi]	; Save in output area

	 and	 al,al		; Check for terminator
	 jnz	 short @B	; Jump if more to copy

	 dec	 edi		; Backup to terminator

	 mov	 eax,[ebp].SAVEMSG_ERR ; Get caller's error code
	 mov	 ERRCODE,eax	; Save for later use

	 and	 ax,ax		; Izit zero?
	 jz	 short SAVEMSG1 ; Yes, so don't display it

	 push	 eax		; Save for a moment
	 mov	 ax,' :'        ; Separator
S32	 stos	 ERRMSG.ELO[edi] ; Save in output area
	 pop	 eax		; Restore

	 call	 BIN2WORD	; Convert AX to hex at ES:EDI
SAVEMSG1:
	 mov	 DGROUP:[edi].ELO,'®' ; Save trailing separator,0

	 push	 offset DGROUP:ERRMSG ; Pass offset of local buffer
	 call	 LDISPMSG	; Send to error log

	 or	 LCL_FLAG,@LCL_MSG ; Mark as received

	 REGREST <es,ds,edi,esi,eax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

; Because the A0-step of the P5 is broken on RETFD n, we use a
; different but equivalent technique

	 push	 [ebp].SAVEMSG_CSF ; Get return CS
	 pop	 [ebp].SAVEMSG_ERR.ELO ; ...on stack

	 push	 [ebp].SAVEMSG_EIP ; Get return EIP
	 pop	 [ebp].SAVEMSG_VEC.FSEL.EDD ; ...on stack

	 pop	 ebp		; Restore

	 add	 esp,4*3	; Strip off arguments

	 RETFD			; Return to 32-bit caller

;;;;;;;; RETFD	 4*3		; Return to 32-bit caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVEMSG  endp			; End SAVEMSG procedure
	 FPPROC  SWATTER -- SWAT Display
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display instructions

Note that this routine returns via RETFD.

On entry:

Stack as in DI_STR

|

DI_STR	 struc

DI_RETEIP dd	 ?		; SWATTER caller's EIP
DI_RETCSF dw	 ?,?		; ...		   CS with filler
DI_EIP	 dd	 ?		; INT 01h caller's EIP
DI_CS	 dw	 ?,?		; ...		   CS with filler
DI_EFL	 dd	 ?		; ...		   EFL

; The following elements are valid only in VM86 or TSS mode,
; or if there was a ring transition to our code
; i.e., (DI_CS RPL > CPL) where CPL=0 for us

DI_ESP	 dd	 ?		; INT 01h caller's ESP
DI_SSF	 dd	 ?		; ...		   SS with filler

; The following elements are valid only in VM86 or TSS mode

DI_ESF	 dd	 ?		; ...		   ES with filler
DI_DSF	 dd	 ?		; ...		   DS with filler
DI_FSF	 dd	 ?		; ...		   FS with filler
DI_GSF	 dd	 ?		; ...		   GS with filler

DI_STR	 ends

	 REGSAVE <eax,ds>	; Save for a moment

	 pushfd 		; Save SWATTER caller's flags

XDI_STR  struc

	 dd	 ?		; Caller's EFL
	 dd	 ?		; ...	   DS
	 dd	 ?		; ...	   EAX
XDI_LCL  db	 (size DI_STR) dup (?)

XDI_STR  ends

; If the caller's SS does not have the B-bit set, clear
; the high-order word of ESP so we can use it as a base register.

	mov	eax,ss		; Copy the selector
	lar	eax,eax 	; Get the A/R word

	test	eax,(mask $DTE_B) shl 16 ; Izit a 32-bit selector?
	jnz	short @F	; Jump if so

	movzx	esp,sp		; Clear to use as dword
@@:
	 SETDATA ds		; Set data selector into DS
	 assume  ds:DGROUP	; Tell the assembler about it

	call	READ_LBR	; Read and save the LBR registers
	call	CLR_BTF 	; Disable BTF if appropriate

COMMENT|

Check for trap at locations other than from a debug exception where we
might be entered and reference a debug register.  In these cases, if
the GD bit is set in DR7, we don't want to stop on a GD Fault.

These locations include

* SWATTER_DR6
* Several places in READ_CR3
* LCL_INT01_DR6 (because we might entered via a software INT 01h)
* INIT_PROT_DR7R/W ...
* CMD_BDSET_A through CMD_BDSET_Z

This check is necessary to allow SWAT to be entered at various points
(other than through a debug exception) such as via an INT 67h call
from (say) SWATCMD at the same time the GD bit is set in DR7.

If the GD bit is set and SWAT is entered via a debug exception, the
CPU clears the GD bit thus allowing further access to the debug
registers.  However, SWAT can be entered other than through a debug
exception, in which case SWAT's own reference to a debug register can
trigger a General Detect Fault.  Thus, we need to check for the first
occurrence on each entry path of a reference to a debug register and,
if it's a match, continue processing.  The General Detect Fault itself
clears the GD bit, so that's why we need check the first occurrence
only.  The value in FORCE_DR7 restores the GD bit upon exit.

For this path, the first occurrence is at SWATTER_DR6; for another
path via an INT 67h call, it's in READ_CR3.

|

	 mov	 ax,cs		; Get our code selector

	 cmp	 ax,[esp].XDI_LCL.DI_CS ; Izit us?
	 jne	 short SWATTER_XGD ; Jump if not

; Check individual entries

	mov	eax,[esp].XDI_LCL.DI_EIP ; Get EIP for comparison

	REGSAVE <ebx,ecx>	; Save for a moment

	mov	ecx,@IND_DRn_LEN ; Get # individual entries
	xor	ebx,ebx 	; Initialize index into IND_DRn
SWATTER_IND_NEXT:
	cmp	eax,IND_DRn[ebx*(type IND_DRn)] ; Duzit match?
	je	short SWATTER_IND_DONE ; Jump if so (note ZF=1)

	inc	ebx		; Skip to next entry (note ZF=0)

	loop	SWATTER_IND_NEXT ; Jump if more entries
SWATTER_IND_DONE:
	REGREST <ecx,ebx>	; Restore
	je	short SWATTER_CONT ; Jump if a match (continue on)

; Check ranges

	REGSAVE <ebx,ecx>	; Save for a moment

	mov	ecx,@RNG_DRn_LEN ; Get # range entries
	xor	ebx,ebx 	; Initialize index into RNG_DRn
SWATTER_RNG_NEXT:
	cmp	RNG_DRn[ebx*(type RNG_DRn)].RNG_BEG,eax ; Izit in range?
	ja	short @F	; Jump if not (note CF=0)

	cmp	eax,RNG_DRn[ebx*(type RNG_DRn)].RNG_END ; Izit in range?
	jb	short SWATTER_RNG_DONE ; Jump if so (note CF=1)
				; Fall through with CF=0
@@:
	inc	ebx		; Skip to next entry (note CF unchanged)

	loop	SWATTER_RNG_NEXT ; Jump if more entries
SWATTER_RNG_DONE:
	REGREST <ecx,ebx>	; Restore
	jc	short SWATTER_CONT ; Jump if a match (continue on)
SWATTER_XGD:
SWATTER_DR6:
	 mov	 eax,dr6	; Get debug status register
	 mov	 SAVE_DR6,eax	; Save for later use

; Check for BC trace in effect

	 test	 LC2_FLAG,mask $LC2_BCT ; Is BC trace in effect?
	 jz	 short SWATTER_XBCT ; Jump if not

; Ensure we're coming from single-step

	 btr	 eax,$BS	; Test and reset the bit
	 jnc	 short SWATTER_XBCT ; Jump if not single-step

	 and	 LC2_FLAG,not (mask $LC2_BCT) ; Not any more

; Install any previous breakpoint values

	 push	 gs		; Save for a moment

	 mov	 gs,COMMON.FILE_4GB ; Address all of memory
	 assume  gs:AGROUP	; Tell the assembler about it

	 call	 INST_BCVAL	; Install code breakpoints (INT 03)

	 pop	 gs		; Restore
	 assume  gs:nothing	; Tell the assembler about it
SWATTER_CONT:

; Clear the debug status register for next time

	 xor	 eax,eax	; A convenient zero
	 mov	 dr6,eax	; Clear it

; Stop single-stepping

	 and	 [esp].XDI_LCL.DI_EFL.ELO,not (mask $TF) ; Clear the trap flag
	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Enable the LBR registers

	 popfd			; Restore

	 stc			; Tell caller to stop single-stepping

	 REGREST <ds,eax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 RETFD			; Return to 32-bit caller

SWATTER_XBCT:
	 assume  ds:DGROUP	; Tell the assembler about it

; Check for SIGINT in effect

	 btr	 LC3_FLAG,$LC3_SIGINT ; Izit in effect?
	 jnc	 short @F	; Jump if not

	 REGSAVE <eax,esi,gs>	; Save for a moment

	 mov	 esi,LaSIGINT_OLD ; Get linear address of word to restore
	 mov	 ax,SIGINT_OLD	; Get the word to restore

	 mov	 gs,COMMON.FILE_4GB ; Address all of memory
	 assume  gs:AGROUP	; Tell the assembler about it

	 mov	 AGROUP:[esi],ax ; Restore the value

	 REGREST <gs,esi,eax>	; Restore
	 assume  gs:nothing	; Tell the assembler about it
@@:

; Disable Periscope 4 board if present

	 test	 LC2_FLAG,mask $LC2_PS4 ; Is Periscope 4 board present?
	 jz	 short @F	; Jump if not

	 push	 edx		; Save for a moment

	 mov	 dx,PS4IO	; Get the I/O port #
	 mov	 al,0DBh	; Get stop flag
	 out	 dx,al		; Tell it stop capturing trace info

	 pop	 edx		; Restore
@@:
	 mov	 eax,dr7	; Get debug control register
	 or	 eax,FORCE_DR7	; Include any forced bits
	 mov	 SAVE_DR7,eax	; Save for later use
	 xor	 eax,eax	; Clear the bits
	 mov	 dr7,eax	; Disable all triggers

	 pop	 RETFL		; ...for a moment

	 REGREST <REG_EAXDS.EDQHI,REG_EAXDS.EDQLO> ; Save to restore later

; Switch to local stack unless we're re-entering

	 cld			; String ops forwardly

; Increment the re-entry count

	 inc	 REENTRY	; Bump the counter

	 cmp	 REENTRY,1	; Check re-entry level
	 jne	 near ptr SWATTER_XSTK1 ; Jump if we're re-entering

	 mov	 LCLSTK_FVEC.FSEL,ds ; Save as LCL stack selector

COMMENT|

Setup EAX for state testing

If the caller came from VM86 mode or we're using our own TSSs
or there was a ring transition, the values in DI_ESP and DI_SSF are valid.

If the caller came from VM86 mode or we're using our own TSSs
the values in DI_ESF, DI_DSF, DI_FSF, and DI_GSF are also valid.

Because VM86 and TSS mode have the same stack frame, we set the
$VM bit in EAX if we're in TSS mode and test $VM only thereafter.

Because no other bits in EAX are of interest, if the caller came
from PM, we load the caller's CS into AX so we can test its RPL via $PL.
If the caller came from VM86 mode, we zero the RPL bits

|

@VMTSS	 equ	 ((mask $VM) shl 16) ; Mask for VM86 or TSS mode
@VMTSSRT equ	 (@VMTSS or (mask $PL)) ; Mark for VM86 or TSS mode or RPL > 0

	 mov	 eax,[esp].DI_EFL ; Get caller's VM bit into $VM
	 xor	 ax,ax		; In case we're coming from VM86 mode

	 test	 eax,@VMTSS	; Izit VM86 mode?
	 jnz	 short @F	; Jump if so

	 mov	 ax,[esp].DI_CS ; Get caller's RPL into $PL

	cmp	TSS_CNT,0	; Izit TSS mode?
	je	short @F	; Jump if not

	 or	 eax,@VMTSS	; Mark as TSS mode
@@:

; Save to restore later

	 pop	 REG_RETEIP	; Caller's EIP
	 pop	 REG_RETCSF	; Caller's CSF
	 pop	 REG_EIP	; INT 01 caller's EIP
	 pop	 REG_CSF	; INT 01 caller's CSF
	 pop	 REG_EFL	; INT 01 caller's EFLAGS

; If we're in VM86 or TSS mode, or there was a ring transition,
; pop the stack selector and offset

	 test	 eax,@VMTSSRT	; Izit VM86 or TSS mode or RPL > 0?
	 jz	 short SWATTER_PM1B ; Jump if not

	 pop	 REG_ESP	; Save to restore later
	 pop	 REG_SSF

; If not in VM86 or TSS mode, skip selector register POPs

	 test	 eax,@VMTSS	; Izit VM86 or TSS mode?
	 jz	 short SWATTER_PM1A ; Jump if not (must be ring transition)

	 pop	 REG_ESF	; Save to restore later
	 pop	 REG_DSF
	 pop	 REG_FSF
	 pop	 REG_GSF

	 mov	 XPMSTK_FVEC.FOFF,esp ; Save caller's stack pointer
	 mov	 XPMSTK_FVEC.FSEL,ss

	 jmp	 short SWATTER_PM1C ; Join common code

; We came through a ring transition and must save our caller's SS:ESP
; to restore later

SWATTER_PM1A:
	 mov	 XPMSTK_FVEC.FOFF,esp ; Save caller's stack pointer
	 mov	 XPMSTK_FVEC.FSEL,ss

; We came from PM or through a ring transition (also PM)

SWATTER_PM1B:
	 push	 REG_EAXDS.EDQHI ; Get caller's DS
	 pop	 REG_DSF	; Save for later use
	 mov	 REG_ESF.ELO,es ; ...
	 mov	 REG_FSF.ELO,fs ; ...
	 mov	 REG_GSF.ELO,gs ; ...

; If we came from PM (but not a ring transition), save caller's SS|ESP

	 test	 eax,@VMTSSRT	; Izit VM86 or TSS mode or RPL > 0?
	 jnz	 short SWATTER_PM1C ; Jump if so

	 mov	 REG_SSF.ELO,ss ; ...
	 mov	 REG_ESP,esp	; ...
SWATTER_PM1C:
	 lss	 esp,LCLSTK_FVEC ; Switch to our own stack
	 assume  ss:nothing	; Tell the assembler about it

	 push	 REG_GSF	; Put onto our own stack
	 push	 REG_FSF
	 push	 REG_DSF
	 push	 REG_ESF
	 push	 REG_SSF
	 push	 REG_ESP
	 push	 REG_EFL	; Put onto our own stack
	 push	 REG_CSF
	 push	 REG_EIP
	 push	 REG_RETCSF
	 push	 REG_RETEIP

; Restore caller's registers

SWATTER_XSTK1:
	 lds	 eax,REG_EAXDS.EDF ; Restore 'em
	 assume  ds:nothing	; Tell the assembler about it

; Save caller's EGP registers

	 pushad 		; Save all EGP registers
	 mov	 ebp,esp	; Hello, Mr. Stack

	 sub	 esp,@BPBACK	; Make room for structure

	 REGSAVE <ds,es,fs,gs>	; Save segment registers

ESP_STR  struc

ESP_GS	 dw	 ?,?		; Caller's GS w/filler
ESP_FS	 dw	 ?,?		; ...	   FS ...
ESP_ES	 dw	 ?,?		; ...	   ES ...
ESP_DS	 dw	 ?,?		; ...	   DS ...

ESP_STR  ends

; Don't push anything else onto the stack until this
; structure has been fully used -- it is addressed via [esp].

; Ensure the above selectors are valid; if not, zero them

VERR_MAC macro	 SREG

	 verr	 [esp].&SREG	; Check selector
	 jmp	 short $+2	; Jump in case bad selector
	 jz	 short @F	; Jump if accessible

	 mov	 [esp].&SREG,0	; Zero the selector
@@:
	 endm			; VERR_MAC

	 VERR_MAC ESP_DS	; Check DS selector
	 VERR_MAC ESP_ES	; ...	ES
	 VERR_MAC ESP_FS	; ...	FS
	 VERR_MAC ESP_GS	; ...	GS

	 SETDATA ds		; Set data selector into DS
	 assume  ds:DGROUP	; Tell the assembler about it

	 push	 ds		; Get data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 xor	 ax,ax		; A convenient zero
	 mov	 fs,ax		; Ensure it's valid
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 gs,COMMON.FILE_4GB ; Address all of memory
	 assume  gs:AGROUP	; Tell the assembler about it

	cmp	REENTRY,1	; Check re-entry level
	jne	short @F	; Jump if we're re-entering

	mov	FORWSTR_FVEC.FOFF,ebp ; Save for later use
	mov	FORWSTR_FVEC.FSEL,ss ; ...
@@:
	 test	 LC3_FLAG,@LC3_INTERNAL ; Are we executing an internal command?
	 jnz	 near ptr SWATTER_INTERNAL1 ; Jump if so

; Restore DR6 and DR7 if called from single-skipping through ROM

	 cmp	 ROMSKIP_MASK,0 ; Might we be coming from ROM single skip?
	 je	 near ptr NOT_ROMSKIP ; Jump if not

; Restore DR7 (turn off the Gn and Ln bits)

	 mov	 eax,ROMSKIP_MASK ; Get DR7 bit mask
	 not	 eax		; Negate to turn off bits
	 and	 SAVE_DR7,eax	; Turn off Debug Control Register bits

; Restore DR7 (replace orig Len and R/W bits for DRn)

	 mov	 eax,ROMSKIP_DR7 ; Get original Len and R/W bits for DRn
	 or	 SAVE_DR7,eax	; ... and store back in DR7

; Restore original DRn linear address

	 mov	 eax,ROMSKIP_DRN ; Get original linear address

	 test	 ROMSKIP_MASK,(mask $G0) or (mask $L0) ; Did we use DR0?
	 jnz	 short REST_DR0 ; Jump if so

	 test	 ROMSKIP_MASK,(mask $G1) or (mask $L1) ; Did we use DR1?
	 jnz	 short REST_DR1 ; Jump if so

	 test	 ROMSKIP_MASK,(mask $G2) or (mask $L2) ; Did we use DR2?
	 jnz	 short REST_DR2 ; Jump if so

REST_DR3:
	 mov	 dr3,eax	; Restore DR3 linear address
	 mov	 ebx,mask $B3	; Set BD bit for comparision

	 jmp	 short REST_DRN ; Join common code

REST_DR2:
	 mov	 dr2,eax	; Restore DR2 linear address
	 mov	 ebx,mask $B2	; Set BD bit for comparision

	 jmp	 short REST_DRN ; Join common code

REST_DR1:
	 mov	 dr1,eax	; Restore DR1 linear address
	 mov	 ebx,mask $B1	; Set BD bit for comparision

	 jmp	 short REST_DRN ; Join common code

REST_DR0:
	 mov	 dr0,eax	; Restore DR0 linear address
	 mov	 ebx,mask $B0	; Set BD bit for comparision

;;;;;;;; jmp	 short REST_DRN ; Join common code

REST_DRN:

; Reset our ROM single skip mask

	 mov	 ROMSKIP_MASK,0 ; Zero our mask

; If the reason we entered SWAT matched the current DR6 bits, clear 'em

	 mov	 eax,dr6	; Get current Debug Status Register

	 test	 eax,ebx	; Is ROMSKIP the reason for entering SWAT?
	 jz	 short NOT_ROMSKIP ; Jump if not

; Restore DR6 - called via ROM single-skip

	 not	 ebx		; Complement to clear
	 and	 eax,ebx	; Clear the specific reason bit
	 mov	 dr6,eax	; Store back in Debug Status Register
NOT_ROMSKIP:
	 test	 LC2_FLAG,@LC2_MONITOR ; Are we in monitor mode?
	 jz	 near ptr NOT_MONITORMODE ; Jump if not

; Check for monitor mode _if_ called from our Int 1 or Int 3 handlers
; FIXME we must also handle TSS entry.
	 mov	 eax,REG_RETEIP ; Get return address of caller to SWATTER

	 cmp	 eax,offset PGROUP:INT1_RETURN ; Izit our boy?
	 jne	 short END_MONITORMODE ; Jump if not

;;;;;;;  call	 GET_CURINSTR	; AGROUP:EAX ==> Current instruction

	 movzx	 eax,[ebp].FORW_CS ; Got caller's CS

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	 jz	 short @F	; Jump if not

	 shl	 eax,4-0	; Convert paras to bytes

	 jmp	 short MONITOR_COM ; Join common code

@@:
	 push	 ax		; Pass selector
	 call	 GETBASE	; EAX = linear address of selector base
MONITOR_COM:
	 add	 eax,[ebp].FORW_EIP ; Add EIP to CS base
	 mov	 CUR_INSTR,eax	; Save for later
	 call	 IS_MONITOR	; Return CF=1 if we should keep going

	 jnc	 short END_MONITORMODE0 ; Jump if we should display

if @MON_DEBUG
;;;;;;;  SELFBREAK MONITOR,100h ; Break if SELFDBG & 100
	 test	 SELFDBG,0100h	; Are we debugging ourselves?
	 jz	 short @F	; If not, then skip this section

	 and	 SELFDBG,not 0100h ; Clear self debug flag so we don't get
				; a breakpoint on top of a breakpoint...
	 and	 LC2_FLAG,not @LC2_MONITOR ; Turn off monitor mode

	 public  MONITOR_BREAKPT
MONITOR_BREAKPT:
	 int	 3		; Trigger breakpoint
@@:
endif				; Monitor debugging on

; We can't check yet because [ebp-@BPBACK].BACK_* isn't set up yet
;;;;;;;  call	 CHECK_BACKLINK ; If we're in TSS mode, ensure back link valid
;;;;;;;  jc	 short END_MONITORMODE ; Jump if not

; Ensure the IMR is saved

	 call	 SAVE_IMR	; Save it

; Restore any previous breakpoint values

	 call	 REST_BCVAL	; Restore 'em

; Resume via single-step

if @MON_DEBUG
	 mov	 ax,[ebp].FORW_CS ; Got caller's CS
	 lea	 edi,MON_CURINSTCS ; Address to format hex word at
	 call	 BIN2WORD	; Convert AX to hex at ES:EDI

	 mov	 eax,[ebp].FORW_EIP ; Get caller's EIP
	 lea	 edi,MON_CURINSTEIP ; Address to format hex dword at
	 call	 BIN2DWORD	; Convert EAX to hex at ES:EDI

	 mov	 eax,CUR_INSTR	; Get linear address of current instruction
	 lea	 edi,MON_CURINSTLA ; Address to format hex dword at
	 call	 BIN2DWORD	; Convert EAX to hex at ES:EDI

	 push	 offset DGROUP:MON_CURINST ; Formatted message to display
	 call	 LDISPMSG	; Display it
endif				; Monitor debugging on

	 jmp	 SWATTER_INTERNAL2 ; Skip message, screen and IRQ setup

END_MONITORMODE0:
	 LOGDISP 'monexpr TRUE'
END_MONITORMODE:
	 and	 LC2_FLAG,not @LC2_MONITOR ; Turn off monitor mode

	 LOGDISP 'End monitor mode'

NOT_MONITORMODE:
; Check for the following set of conditions:
;	1) EAX = '386S' (33383653)
;	2) {.csip = ED8603CD (int 03, xchg ch,ch)
;	3) {.csip+4 = CCD286CC (int 3, xchg dl,dl, int 3)
; If all TRUE, skip all 8 instruction bytes and display DS:ESI.
; If BX != 0, break.

; Condition 1: EAX = '386S'
	 cmp	 [ebp].FORW_EAX,@SWI3_SIG ; Izit our signature?
	 jne	 near ptr NOT_KLUGEMSG ; Jump if not

;;;;;;;  call	 GET_CURINSTR	; AGROUP:EAX ==> Current instruction

	 movzx	 eax,[ebp].FORW_CS ; Got caller's CS

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	 jz	 short @F	; Jump if not

	 shl	 eax,4-0	; Convert paras to bytes
	 jmp	 short KLUGEMSG_COM ; Join common code

@@:
	 push	 ax		; Pass selector
	 call	 GETBASE	; EAX = linear address of selector base
	 jnc	 short KLUGEMSG_COM ; Jump if OK

	 sub	 eax,eax	; Assume flat selector
KLUGEMSG_COM:
	 add	 eax,[ebp].FORW_EIP ; Add EIP to CS base

	 dec	 eax		; Back off one (CD already skipped)

if @KMSG_DEBUG
	 mov	 esi,eax	; AGROUP:ESI ==> first instruction byte
	 lea	 edi,KMSG_LA	; Address to format hex word at
	 call	 BIN2DWORD	; Convert EAX to hex at ES:EDI

	 mov	 eax,AGROUP:[esi].EDD ; Get first group of instructions
	 lea	 edi,KMSG_DW1	; Address to format hex word at
	 call	 BIN2DWORD	; Convert EAX to hex at ES:EDI

	 mov	 eax,AGROUP:[esi+4].EDD ; Get next group of instructions
	 lea	 edi,KMSG_DW2	; Address to format hex dword at
	 call	 BIN2DWORD	; Convert EAX to hex at ES:EDI

	 push	 offset DGROUP:KMSG_COMP ; Formatted message to display
	 call	 LDISPMSG	; Display it

	 mov	 eax,esi	; Restore EAX
endif				; Kluge message debugging on

; Condition 2: {.csip = ED8603CD
	 cmp	 AGROUP:[eax].EDD,@SWI3_OP1 ; Does the first part match?
	 jne	 short NOT_KLUGEMSG ; Jump if not

; Condition 3: {.csip+4 = CCD286CC
	 cmp	 AGROUP:[eax+4].EDD,@SWI3_OP2 ; Does the second part match?
	 jne	 short NOT_KLUGEMSG ; Jump if not

; Get linear address of DS:ESI
	 movzx	 eax,[ebp].FORW_DS ; Got caller's DS

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	 jz	 short @F	; Jump if not

	 shl	 eax,4-0	; Convert paras to bytes
	 jmp	 short KLUGEMSG2_COM ; Join common code

@@:
	 push	 ax		; Pass selector
	 call	 GETBASE	; EAX = linear address of selector base
	 jnc	 short KLUGEMSG2_COM ; Jump if we got selector base

	 sub	 eax,eax	; Assume flat selector
KLUGEMSG2_COM:
	 add	 eax,[ebp].FORW_ESI ; Add ESI to DS base

	 mov	 esi,eax	; AGROUP:ESI ==> message
	 mov	 ecx,255	; Maximum length to display
@@:
	 lods	 AGROUP:[esi].LO ; Get a byte
	 or	 al,al		; Izit the end?
	 jz	 short @F	; Jump if so

	 call	 LDISPTXT	; Display AL to log
	 loop	 @B		; Go around again

@@:

; Skip these odd instructions.	Note that the sequence must execute
; identically in USE16 and USE32 modes.
	 add	 [ebp].FORW_EIP,8-1 ; Skip the remainder of the sequence
				; (CD already skipped in Int 3 handler)

	 or	 bx,bx		; Should we stop?
	 jnz	 short NOT_KLUGEMSG ; Jump if so

; Ensure the IMR is saved

	 call	 SAVE_IMR	; Save it

; Restore any previous breakpoint values

	 call	 REST_BCVAL	; Restore 'em

	 jmp	 SWATTER_INTERNAL3 ; Exit SWATTER

NOT_KLUGEMSG:

; Save message if called from debug register

	 test	 LCL_FLAG,@LCL_MSG ; Message already received?
	 jnz	 near ptr SWATTER_XMSG ; Jump if so

	 mov	 eax,dr6	; Get debug status register

	 lea	 ebx,MSG_BT	; DS:EBX ==> message to display

	 test	 LC2_FLAG,mask $LC2_TDB ; Izit to be cleared?
	 jnz	 short @F	; Jump if so

	 test	 eax,mask $BT	; Izit TSS trap?
	 jnz	 short SWATTER_MSGCOM1 ; Yes, join common message code
@@:
	 lea	 ebx,MSG_BD	; DS:EBX ==> message to display

	 test	 eax,mask $BD	; Izit GD trap?
	 jnz	 short SWATTER_MSGCOM1 ; Yes, join common message code

	 lea	 ebx,MSG_B3	; DS:EBX ==> message to display
	 mov	 ecx,(mask $G3) or (mask $L3) ; Save for false BD disable

	 test	 eax,mask $B3	; Izit DR3 trap?
	 jnz	 short SWATTER_MSGCOM ; Yes, join common message code

	 lea	 ebx,MSG_B2	; DS:EBX ==> message to display
	 mov	 ecx,(mask $G2) or (mask $L2) ; Save for false BD disable

	 test	 eax,mask $B2	; Izit DR2 trap?
	 jnz	 short SWATTER_MSGCOM ; Yes, join common message code

	 lea	 ebx,MSG_B1	; DS:EBX ==> message to display
	 mov	 ecx,(mask $G1) or (mask $L1) ; Save for false BD disable

	 test	 eax,mask $B1	; Izit DR1 trap?
	 jnz	 short SWATTER_MSGCOM ; Yes, join common message code

	 lea	 ebx,MSG_B0	; DS:EBX ==> message to display
	 mov	 ecx,(mask $G0) or (mask $L0) ; Save for false BD disable

	 test	 eax,mask $B0	; Izit DR0 trap?
	 jz	 short SWATTER_XMSG ; No, join common code
SWATTER_MSGCOM:
	 test	 SAVE_DR7,ecx	; Izit actually enabled?
	 jz	 short SWATTER_XMSG ; Jump if not
SWATTER_MSGCOM1:
	 PUSHD	 0		; Pass pseudo-error code
	 PUSHD	 ds		; Pass message selector
	 push	 ebx		; Pass message offset
	 FCALLD  SAVEMSG	; Call message save routine
SWATTER_XMSG:
SWATTER_INTERNAL1:

; Ensure the IMR is saved

	 call	 SAVE_IMR	; Save it

	test	LC4_FLAG,@LC4_ERRLOG ; Displaying error log?
	jnz	short @F	; Jump if so (we need the keyboard)

	 test	 LC3_FLAG,@LC3_INTERNAL ; Are we executing an internal command?
	 jnz	 near ptr SWATTER_INTERNAL2 ; Jump if so
@@:

; Ensure the keyboard and timer are installed and enabled

	 cmp	 REENTRY,1	; Check re-entry level
	 jne	 short @F	; Jump if we're re-entering

	 call	 SAVE_IRQS	; Save original IRQ-specific interrupt handlers,
				; install ours
@@:
	 call	 ENABLE_IRQS	; Enable the IRQs we need

	test	LC3_FLAG,@LC3_INTERNAL ; Are we executing an internal command?
	jnz	near ptr SWATTER_INTERNAL2 ; Jump if so

; If we're on an MCA machine, disable the watchdog timer
; to avoid spurious keyboard lockups????
;;;;;;;;
;;;;;;;; test	 SWATINI.MD_ATTR,@MD_MCA ; Izit an MCA-compatible?
;;;;;;;; jz	 short @F	; Not this time
;;;;;;;;
;;;;;;;; call	 HOUSE_DOG	; Disable watchdog timer
;;;@@:

COMMENT|

If we come up without displaying a message (typically on a single-step
or single-skip), don't enable the keyboard as it should already be
enabled.  Moreover, we need to limit the occasions where we do
re-enable the keyboard because some 8042s don't take kindly to being
kicked in the pants and they stop auto-repeating in protest.

Note that messages such as "DRn trap" will cause us to continue to
give the keyboard a kick in the pants and consequently we might stop
autorepeating.

|

	 test	 LCL_FLAG,@LCL_MSG ; Message already received?
	 jz	 short @F	; Jump if not

; Give the keyboard a kick in the pants in case it's disabled

	 test	 SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
	 jnz	 short @F	; Yes, don't bother

	 mov	 ah,@S2K_ENABLE ; Enable command
	call	U32_PPI_S2K_K2S ; Send command AH to keyboard, response in AL
				; Ignore response
@@:

; Switch to DVGA screen if specified

	 test	 ARG_FLAG,@ARG_DVGA ; Izit present?
	 jz	 short @F	; Jump if not

	 call	 DVGASEL1	; Select DVGA section 1
@@:

; Save the screen data values

	 call	 SAVE_SCRDATA	; Save screen data

; Set video mode if not in text mode

	 call	 CHECK_VMOD	; Check it out

; Save the screen contents unless disabled

	 test	 LCL_FLAG,@LCL_SCRN ; Screen restore disabled?
	 jnz	 short @F	; Yes, so don't save it

	 push	 PSCRBUF	; Pass address of screen buffer
	 PUSHD	 1		; Use actual screen
	 call	 SAVE_SCR	; Save all screen text
@@:

; Set new cursor position and type

	 push	 CURPOSN	; Get new cursor position
	 call	 SET_CURPOS	; Set it

	 push	 CURTYPE	; Get new cursor type
	 call	 SET_CURTYP	; Set it
SWATTER_INTERNAL2:

; Save GDTR

	 SGDTD	 [ebp-@BPBACK].BACK_GDT ; Save GDTR

; Save IDTR

	 SIDTD	 [ebp-@BPBACK].BACK_IDT ; Save IDTR

; Save TR

	 str	 ax		; Get current task register

	cmp	TSS_CNT,0	; Izit TSS mode?
	je	short @F	; Jump if not

; Get back link from our own TSS

	 push	 ax		; Pass selector as argument
	 call	 GETBASE	; Return with EAX = selector base

	 mov	 ax,AGROUP:[eax].TSS_LINK ; Get our back link
@@:
	 mov	 [ebp-@BPBACK].BACK_TR.DTR_LIM,ax ; Save the value

	 push	 ax		; Pass as argument
	 call	 GETBASE	; Return with EAX = selector base
	 jnc	 short @F	; Jump if OK

	 xor	 eax,eax	; Call it zero-based
	 mov	 [ebp-@BPBACK].BACK_TR.DTR_LIM,ax ; Save the value
@@:
	 mov	 [ebp-@BPBACK].BACK_TR.DTR_BASE,eax ; Save the base address

	 btr	 LC2_FLAG,$LC2_TDB ; Izit to be cleared?
	 jnc	 short @F	; Jump if not

	 btr	 AGROUP:[eax].TSS_DBG,0 ; Clear the debug bit
@@:

; Save LDTR

	 sldt	 ax		; Get current LDT selector

	cmp	TSS_CNT,0	; Izit TSS mode?
	je	short SWATTER_XTSS1 ; Jump if not

	 xor	 ax,ax		; Assume invalid back link

	 cmp	 [ebp-@BPBACK].BACK_TR.DTR_LIM,0 ; Izit invalid?
	 je	 short SWATTER_XTSS1 ; Jump if so

	 mov	 eax,[ebp-@BPBACK].BACK_TR.DTR_BASE ; Get the task's base address

; Split cases sepending upon 286 vs. 386 TSS

	 push	 ds		; Save for a moment

	 mov	 ds,COMMON.FILE_4GB ; Address all of memory
	 assume  ds:AGROUP	; Tell the assembler about it

	 push	 [ebp-@BPBACK].BACK_TR.DTR_LIM ; Pass the caller's TSS selector
	 call	 IZIT286	; Izit a 286 TSS?
	 pop	 ds		; Restore
	 assume  ds:DGROUP	; Tell the assembler about it
	 jc	 short @F	; Jump if so

	 mov	 ax,AGROUP:[eax].TSS_LDT ; Get the caller's LDTR from 386 TSS

	 jmp	 short SWATTER_XTSS1 ; Join common code

@@:
	 mov	 ax,AGROUP:[eax].TSS2_LDT ; Get the caller's LDTR from 286 TSS
SWATTER_XTSS1:
	 mov	 [ebp-@BPBACK].BACK_LDT.DTR_LIM,ax ; Save selector
	 mov	 [ebp].FORW_LDT,ax ; Save for non-SWATTER calls to GETBASE

	 push	 ax		; Pass as argument
	 call	 GETBASE	; Return with EAX = selector base
	 jnc	 short @F	; Jump if OK

	 xor	 eax,eax	; Call it zero-based
@@:
	 mov	 [ebp-@BPBACK].BACK_LDT.DTR_BASE,eax ; Save the base address

	 test	 LC2_FLAG,@LC2_MONITOR ; Are we in monitor mode?
	 jnz	 short @F	; Jump if so

; SETUP may depend upon the LDT base, so don't move it up any earlier

	 call	 SETUP		; Call setup code
@@:

; Save all segment registers

	 movzx	 eax,[ebp].FORW_CS
	 mov	 [ebp-@BPBACK].BACK_CS.DTR_LIM,ax

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	 jz	 short SWATTER_PM2 ; Not this time

; Save VM 8086 Mode segment registers from FORW_STR

	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 [ebp-@BPBACK].BACK_CS.DTR_BASE,eax

	 movzx	 eax,[ebp].FORW_DS
	 mov	 [ebp-@BPBACK].BACK_DS.DTR_LIM,ax
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 [ebp-@BPBACK].BACK_DS.DTR_BASE,eax

	 movzx	 eax,[ebp].FORW_ES
	 mov	 [ebp-@BPBACK].BACK_ES.DTR_LIM,ax
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 [ebp-@BPBACK].BACK_ES.DTR_BASE,eax

	 movzx	 eax,[ebp].FORW_FS
	 mov	 [ebp-@BPBACK].BACK_FS.DTR_LIM,ax
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 [ebp-@BPBACK].BACK_FS.DTR_BASE,eax

	 movzx	 eax,[ebp].FORW_GS
	 mov	 [ebp-@BPBACK].BACK_GS.DTR_LIM,ax
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 [ebp-@BPBACK].BACK_GS.DTR_BASE,eax

	 movzx	 eax,[ebp].FORW_SS
	 mov	 [ebp-@BPBACK].BACK_SS.DTR_LIM,ax
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 [ebp-@BPBACK].BACK_SS.DTR_BASE,eax

	 jmp	 SWATTER_COM1	; Join common code

; Save protected mode selectors and their 32-bit linear base addresses

SWATTER_PM2:
	 mov	 ax,[ebp].FORW_CS ; Get caller's CS
	 mov	 [ebp-@BPBACK].BACK_CS.DTR_LIM,ax
	 push	 ax		; Pass selector
	 call	 GETBASE	; Return with EAX = selector base
;;;;;;;; jc	 ???		; Ignore error return
	 mov	 [ebp-@BPBACK].BACK_CS.DTR_BASE,eax

	cmp	TSS_CNT,0	; Izit TSS mode?
	jne	short SWATTER_TSS1 ; Yes, handle specially

	 mov	 ax,[esp].ESP_DS ; Get caller's DS
	 mov	 [ebp-@BPBACK].BACK_DS.DTR_LIM,ax
	 push	 ax		; Pass selector
	 call	 GETBASE	; Return with EAX = selector base
;;;;;;;; jc	 ???		; Ignore error return
	 mov	 [ebp-@BPBACK].BACK_DS.DTR_BASE,eax

	 mov	 ax,[esp].ESP_ES ; Get caller's ES
	 mov	 [ebp-@BPBACK].BACK_ES.DTR_LIM,ax
	 push	 ax		; Pass selector
	 call	 GETBASE	; Return with EAX = selector base
;;;;;;;; jc	 ???		; Ignore error return
	 mov	 [ebp-@BPBACK].BACK_ES.DTR_BASE,eax

	 mov	 ax,[esp].ESP_FS ; Get caller's FS
	 mov	 [ebp-@BPBACK].BACK_FS.DTR_LIM,ax
	 push	 ax		; Pass selector
	 call	 GETBASE	; Return with EAX = selector base
;;;;;;;; jc	 ???		; Ignore error return
	 mov	 [ebp-@BPBACK].BACK_FS.DTR_BASE,eax

	 mov	 ax,[esp].ESP_GS ; Get caller's GS
	 mov	 [ebp-@BPBACK].BACK_GS.DTR_LIM,ax
	 push	 ax		; Pass selector
	 call	 GETBASE	; Return with EAX = selector base
;;;;;;;; jc	 ???		; Ignore error return
	 mov	 [ebp-@BPBACK].BACK_GS.DTR_BASE,eax

	 jmp	 short SWATTER_PMCOM ; Join common code

; TSS mode

SWATTER_TSS1:
	 mov	 ax,[ebp].FORW_DS ; Get caller's DS
	 mov	 [ebp-@BPBACK].BACK_DS.DTR_LIM,ax
	 push	 ax		; Pass selector
	 call	 GETBASE	; Return with EAX = selector base
;;;;;;;; jc	 ???		; Ignore error return
	 mov	 [ebp-@BPBACK].BACK_DS.DTR_BASE,eax

	 mov	 ax,[ebp].FORW_ES ; Get caller's ES
	 mov	 [ebp-@BPBACK].BACK_ES.DTR_LIM,ax
	 push	 ax		; Pass selector
	 call	 GETBASE	; Return with EAX = selector base
;;;;;;;; jc	 ???		; Ignore error return
	 mov	 [ebp-@BPBACK].BACK_ES.DTR_BASE,eax

	 mov	 ax,[ebp].FORW_FS ; Get caller's FS
	 mov	 [ebp-@BPBACK].BACK_FS.DTR_LIM,ax
	 push	 ax		; Pass selector
	 call	 GETBASE	; Return with EAX = selector base
;;;;;;;; jc	 ???		; Ignore error return
	 mov	 [ebp-@BPBACK].BACK_FS.DTR_BASE,eax

	 mov	 ax,[ebp].FORW_GS ; Get caller's GS
	 mov	 [ebp-@BPBACK].BACK_GS.DTR_LIM,ax
	 push	 ax		; Pass selector
	 call	 GETBASE	; Return with EAX = selector base
;;;;;;;; jc	 ???		; Ignore error return
	 mov	 [ebp-@BPBACK].BACK_GS.DTR_BASE,eax
SWATTER_PMCOM:
	 mov	 ax,ss		; Get current stack selector

	 cmp	 REENTRY,1	; Check re-entry level
	 jne	 short @F	; Jump if we're re-entering

	 mov	 ax,[ebp].FORW_SS ; Get from extended stack
@@:
	 mov	 [ebp-@BPBACK].BACK_SS.DTR_LIM,ax
	 push	 ax		; Pass selector
	 call	 GETBASE	; Return with EAX = selector base
;;;;;;;; jc	 ???		; Ignore error return
	 mov	 [ebp-@BPBACK].BACK_SS.DTR_BASE,eax
SWATTER_COM1:
	 or	 [ebp].FORW_EFL.ELO,mask $TF ; Set the trap flag in case
				; we're called with INT 01h
	 push	 RETFL		; Save SWATTER caller's flags on stack

; If we're in monitor mode, leave interrupts off and set up for the next trace
	 test	 LC2_FLAG,@LC2_MONITOR ; Are we in monitor mode?
	 jz	 short @F	; Jump if not

	 call	 SET_UNAVARS	; Set UNAMODE and UNABASE
	 call	 SET_NEXTINSTR	; Set NEXT_INSTR for PUSHF & others

	 sub	 dl,dl		; Calculate STACK_eSP and STACK_eBP but
				; don't display EGP registers
	 call	 DISP_BLK1	; Calculate stack addresses

	 jmp	 SWATTER_TRACE	; Join common code

@@:
	 sti			; Allow interrupts

; If we're executing a command via INT 67h, don't set the current
; instruction, restore BP values, or clear any pending BP
; in case we're single-skipping or the like over such an INT 67h.

	 test	 LC3_FLAG,@LC3_INTERNAL ; Are we executing an internal command?
	 jnz	 short SWATTER_NOBP ; Jump if so

	 call	 SET_CURINSTR	; Set current instruction disassembly values

; Restore any previous breakpoint values

	 call	 REST_BCVAL	; Restore 'em
SWATTER_NOBP:
	test	LC4_FLAG,@LC4_ERRLOG ; Display the error log?
	jz	short SWATTER_NOERRLOG ; Jump if not

; Set video mode if not in text mode

	call	CHECK_VMOD	; Check it out

; Save the screen contents

	push	PSCRBUF 	; Pass address of screen buffer
	PUSHD	1		; Use actual screen
	call	SAVE_SCR	; Save all screen text

; Calculate the offset into the log error buffer for the line which
; is at most @NROWS-2 from the end so that the last line in the buffer
; is displayed at the bottom of the screen.

	push	ERRLOG_CLINE	; Save the current line #

	mov	eax,LOGOFF	; Get current tail
	sub	eax,LOGHEAD	; Less the start
	jae	short @F	; Jump if no underflow

	add	eax,LOGLEN	; Wrap to the buffer end
@@:
	cdq			; Zero high dword of dividend
	mov	ebx,@NCOLS	; Divisor (record length)
	div	ebx		; EAX = new ERRLOG_CLINE value

	sub	eax,@NROWS-2	; Less # lines from end
	jae	short @F	; Jump if there's more

	xor	eax,eax 	; Display starting at the eop
@@:
	mov	ERRLOG_CLINE,eax ; Save as new line #

	call	DISP_ERRLOG	; Display it

	pop	ERRLOG_CLINE	; Restore

	call	GETKEY		; Wait for keystroke, return in AX
	mov	ERRLOG_KEY,ax	; Return to caller

	push	PSCRBUF 	; Pass address of screen buffer
	call	REST_SCR	; Restore the original screen

	jmp	SWATTER_CLC	; We're done

SWATTER_NOERRLOG:
	 btr	 LC3_FLAG,$LC3_SERINIT ; Initialize the serial port?
	 jnc	 short @F	; Jump if not

	 call	 SER_INIT	; Initialize it

	 jmp	 SWATTER_CLC	; We're done

@@:
	 btr	 LC3_FLAG,$LC3_COMMAND ; Was a command specified via Int 67h?
	 jnc	 short @F	; Jump if not

	 mov	 CURPOSN.LO,0	; Move cursor to start of command line
	 mov	 ax,@KEY_CR	; Execute command line already copied in
	 call	 CMD_CHAR	; Process CMD_LINE for CMD_LINE_LEN bytes

	 jmp	 SWATTER_CLC	; We're done

@@:
	 test	 LC3_FLAG,@LC3_SERINT ; Is serial I/O established?
	 jz	 short @F	; Jump if not

	 btr	 LC3_FLAG,$LC3_PORTINIT ; Was PORTINIT specified?
	 jnc	 short @F	; Jump if not

	 call	 CMD_REMDBG	; Attempt to establish remote connection
@@:
	 test	 LC2_FLAG,@LC2_SRC ; Are we in source browse mode?
	 jz	 short @F	; Jump if not

	 cmp	 FBROWS_NAME,0	; Do we have a file loaded?
	 je	 short @F	; Jump if not

	 cmp	 DSP_STATE,@DSP_FBROWS ; Are we already in the source browser?
	 jne	 short @F	; Jump if not

	 call	 DISP_IREGS	; Display instructions to get current line ptr
	 test	 LC2_FLAG,@LC2_SFND ; Is current line a source line?
	 jnz	 near ptr SWATTER_FBROWS ; Redisplay browser screen if so

	 mov	 DSP_STAT3,@DSP_FBROWS ; Remember where we came from
@@:
	 mov	 DSP_STATE,@DSP_IREGS ; Initial screen state is instructions

	 and	 LC4_FLAG,not @LC4_AFLCHK ; Mark as not already checked

	 test	 LCL_FLAG,@LCL_MSG ; Message received?
	 jnz	 short @F	; Jump if so

	 or	 LC4_FLAG,@LC4_AFLCHK ; Mark as already checked (no message)
@@:
	 jmp	 short @F	; Join common code

SWATTER_REGS:
	 mov	 DSP_STAT3,@DSP_IREGS ; Ensure we don't act on it again
@@:
	 call	 DISP_IREGS	; Display instructions

	 bts	 LC4_FLAG,$LC4_AFLCHK ; Izit already checked?
	 jc	 short @F	; Jump if so

	 call	 AUTOFAULT	; Check on AutoFault handling
@@:
	 btr	 LC4_FLAG,$LC4_AFLTBD ; Is there a message to be displayed?
	 jnc	 short @F	; Jump if not (displayed once per entry only)

	 mov	 al,ERRATTR	; Get error window attribute
	 push	 ax		; Pass as attribute to smear
	 push	 LAST_AFLERR	; Pass offset of error message
	 push	 LAST_AFLWIN	; Pass offset of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute
@@:
	mov	eax,LC2_FLAG	; Get flags
	and	eax,@LC2_SRC or @LC2_SFND or @LC2_IGNMOD ; Isolate bits
	cmp	eax,@LC2_SRC or @LC2_SFND ; Are we in source browse mode?
	 jne	 short SWATTER_GETKEY ; Jump if not, or not on a source line

	 cmp	 DSP_STAT3,@DSP_FBROWS ; Did we come from source browser?
	 je	 near ptr SWATTER_FBROWS ; Display file browser if so
SWATTER_GETKEY:
	 call	 GETKEY 	; Wait for keystroke, return in AX
	 call	 CLEAR_MSG	; Clear any message text
SWATTER_WAITKEY:
	 lea	 edi,KEYVAL	; ES:EDI ==> valid keystrokes
	 mov	 ecx,NKEYVAL	; ECX = # valid keystrokes
   repne scas	 KEYVAL[edi]	; Search for it
	 je	 short SWATTER_VALID ; Jump if valid

	 call	 CMD_CHAR	; Process as command line character

	 btr	 LC2_FLAG,$LC2_ESC ; Should we escape?
	 jc	 near ptr SWATTER_ESC ; Jump if so

	 test	 LC3_FLAG,@LC3_SIGINT ; Did we just signal an interrupt
	 jnz	 near ptr SWATTER_SIGINT ; Jump if so

	 test	 LC4_FLAG,@LC4_MONCMD ; Izit a go monitor command?
	 jnz	 near ptr SWATTER_TRACE ; Jump if so
SWATTER_WAIT:
	 test	 LCL_FLAG,@LCL_REDI ; Forced re-display of screen?
	 jz	 short SWATTER_GETKEY ; Not this time

	 and	 LCL_FLAG,not @LCL_REDI ; Clear for next time

	 public  SWATTER_REDISP
SWATTER_REDISP:
	call	SWATTER_DISP	; Display the screen

	 jmp	 SWATTER_GETKEY ; Go around again


SWATTER_VALID:
	 sub	 edi,(type KEYVAL)+offset DGROUP:KEYVAL ; Convert to origin-0 in units of words
LOG2 LOG2@KEYVAL,<type KEYVAL>
	 shr	 edi,LOG2@KEYVAL ; Divide by two to index table of bytes

	 jmp	 KEYACT[edi*(type KEYACT)]  ; Take appropriate action


SWATTER_ASCR:

; Save the screen contents in the last screen buffer

	call	SAVE_LSCR	; Save the current screen in the last screen buffer

	jmp	SWATTER_GETKEY	; Go around again


; Display memory in byte format

SWATTER_MBYTE:
	 call	 MEMACT_B	; Mark as byte format

	 jmp	 short SWATTER_MCOM ; Join common memory display code


; Display memory in word format

SWATTER_MWORD:
	 call	 MEMACT_W	; Mark as word format

	 jmp	 short SWATTER_MCOM ; Join common memory display code


; Display memory in dword format

SWATTER_MDWORD:
	 call	 MEMACT_D	; Mark as dword format

	 jmp	 short SWATTER_MCOM ; Join common memory display code


; Display memory in vector format

SWATTER_MVECT:
	 call	 MEMACT_V	; Mark as vector format

	 jmp	 short SWATTER_MCOM ; Join common memory display code


; Display memory in GDT format

SWATTER_MGDT:
	 call	 MEMACT_G	; Mark as GDT format

	 jmp	 short SWATTER_MCOM ; Join common memory display code


; Display memory in IDT format

SWATTER_MIDT:
	 call	 MEMACT_I	; Mark as IDT format

	 jmp	 short SWATTER_MCOM ; Join common memory display code


; Display memory in TSS format

SWATTER_MTSS:
	 call	 MEMACT_T	; Mark as TSS format

;;;;;;;; jmp	 short SWATTER_MCOM ; Join common memory display code

SWATTER_MCOM:
	 and	 MEMMODE,not @MODE_NEW ; Clear it (used by Dx actions only)

;;;;;;;; jmp	 short SWATTER_MEM ; Join common memory display code


; Display memory

SWATTER_MEM:
	 mov	 al,@DSP_MEM	; Screen state is memory
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Display MAC entries

SWATTER_MAC:
	 mov	 al,@DSP_MAC	; Screen state is MAC
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Display RM IVT

SWATTER_IVT:
	mov	al,@DSP_IVT	; Screen state is IVT
	call	SET_STATE	; Set new state

	jmp	SWATTER_REDISP	; Join common re-display code


; Scroll screen up depending upon the current mode

SWATTER_SCRUP:
	 movzx	 eax,DSP_STATE	; Get primary state

	 jmp	 SCRUP_ACT[eax*(type SCRUP_ACT)] ; Take appropriate action


SCRUP_IREGS:
	 mov	 eax,FIRST_INSTR ; Get linear address of top instr
	 call	 GET_LASTILEN	; Return with EAX=length of previous instr
	 sub	 UNAOFF,eax	; Subtract from offset of top instr

	 mov	 eax,UNAMASK	; Get current mask
	 and	 UNAOFF,eax	; Ensure it's within limits

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRUP_GDT:
	 sub	 GDTOFF,size DESC_STR ; Scroll up one
	 jnc	 short @F	; Jump if we didn't sink below zero

	 mov	 GDTOFF,0	; Cut back to zero
@@:
	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRUP_IDT:
	 sub	 IDTOFF,size IDT_STR ; Scroll up one
	 jnc	 short @F	; Jump if we didn't sink below zero

	 mov	 IDTOFF,0	; Cut back to zero
@@:
	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRUP_LDT:
	 sub	 LDTOFF,size DESC_STR ; Scroll up one
	 jnc	 short @F	; Jump if we didn't sink below zero

	 mov	 LDTOFF,0	; Cut back to zero
@@:
	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRUP_MEM:
	 mov	 eax,MEMSIZE	; Get size of one memory row
	 sub	 MEMOFF,eax	; Skip to previous row
	 mov	 eax,MEMMASK	; Get the mask value
	 and	 MEMOFF,eax	; Mask off wrapped bits (if VM86 mode)

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRUP_DRn:
	 movzx	 eax,DSP_STAT2	; Get secondary state

	 cmp	 al,DSP_STATE	; Same as secondary state?
	 je	 near ptr SWATTER_WAIT ; Yes

	 or	 LCL_FLAG,@LCL_REDI ; Force screen re-display

	 jmp	 SCRUP_ACT[eax*(type SCRUP_ACT)] ; Take appropriate action


SCRUP_SRCH:
	 movzx	 eax,DSP_STAT2	; Get secondary state

	 cmp	 al,@DSP_SRCH	; Same as secondary state?
	 je	 near ptr SWATTER_WAIT ; Yes

	 or	 LCL_FLAG,@LCL_REDI ; Force screen re-display

	 jmp	 SCRUP_ACT[eax*(type SCRUP_ACT)] ; Take appropriate action


SCRUP_PTE:
	 sub	 PTE_START,8*4	; Skip to previous row

	cmp	PTE_START,0	; Izit negative?
	jge	short @F	; Jump if not

	neg	PTE_START	; Negate to get positive value
	and	PTE_START,8*4-1 ; Modulo a line's worth
	neg	PTE_START	; Negate to subtract from 0
@@:
	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRUP_PDE:
	 sub	 PDE_START,8*4	; Skip to previous row

	cmp	PDE_START,0	; Izit negative?
	jge	short @F	; Jump if not

	neg	PDE_START	; Negate to get positive value
	and	PDE_START,8*4-1 ; Modulo a line's worth
	neg	PDE_START	; Negate to subtract from 0
@@:
	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRUP_SYMTAB:
	 sub	 SYMTAB_START,1 ; Decrement index into symbol table
	 jnc	 short @F	; Jump if we didn't sink below zero

	 mov	 SYMTAB_START,0 ; Cut back to zero
@@:
	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRUP_FBROWS:
	 mov	 eax,-1 	; Subtract 1 from SLINE
	 call	 ADJUST_SLINE	; Check range and adjust pointers

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRUP_LSCR:
	 inc	 LSCR_CNT	; Count in another last screen
	 mov	 eax,NLSTBUF	; Get # last screen buffers

	 cmp	 LSCR_CNT,eax	; Izit below the maximum?
	 jb	 short @F	; Jump if so

	 mov	 LSCR_CNT,0	; Wrap to zero
@@:
	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRUP_ERRLOG:
	 sub	 ERRLOG_CLINE,1 ; Back off by 1 line
	 jnc	 short @F	; Jump if OK

	 mov	 ERRLOG_CLINE,0 ; Minimum value
@@:
	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRUP_MAC:
	 sub	 MACNDX,1	; Scroll up one
	 jnc	 short @F	; Jump if we didn't sink below zero

	 mov	 MACNDX,0	; Cut back to zero
@@:
	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRUP_IVT:
	sub	IVTNDX,1	; Scroll up one
	jnc	short @F	; Jump if we didn't sink below zero

	mov	IVTNDX,0	; Cut back to zero
@@:
	jmp	SWATTER_REDISP	; Join common re-display code


SCRUP_WGH:
	sub	WGHNDX,1	; Scroll up one
	jnc	short @F	; Jump if we didn't sink below zero

	mov	WGHNDX,0	; Cut back to zero
@@:
	jmp	SWATTER_REDISP	; Join common re-display code


SCRUP_TDB:
SCRPGUP_TDB:
DECLOC_TDB:
	push	fs		; Save for a moment

	lfs	bx,KVARS_VEC	; FS:BX ==> KVARS_STR
	assume	fs:nothing	; Tell the assembler about it

	mov	cx,fs:[bx].KV_headTDB ; Get head TDB selector
@@:
	jcxz	PREV_TDB_NF	; Jump if invalid

	mov	fs,cx		; Address the next TDB
	assume	fs:nothing	; Tell the assembler about it

	mov	cx,fs:[0].TDB_NEXT ; Get the next selector

	cmp	cx,TDBSEL	; Izit the next one?
	jne	short @B	; Jump if not

	mov	TDBSEL,fs	; Save as selector of previous TDB
PREV_TDB_NF:
	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler about it

	jmp	SWATTER_REDISP	; Join common re-display code



SCRUP_MDB:
SCRPGUP_MDB:
DECLOC_MDB:
	push	fs		; Save for a moment

	lfs	bx,KVARS_VEC	; FS:BX ==> KVARS_STR
	assume	fs:nothing	; Tell the assembler about it

	mov	cx,fs:[bx].KV_hExeHead ; Get head EXE selector
@@:
	jcxz	PREV_MDB_NF	; Jump if invalid

	mov	fs,cx		; Address the next TDB
	assume	fs:nothing	; Tell the assembler about it

	mov	cx,fs:[0].MOD_NEXT ; Get the next selector

	cmp	cx,MDBSEL	; Izit the next one?
	jne	short @B	; Jump if not

	mov	MDBSEL,fs	; Save as selector of previous TDB
PREV_MDB_NF:
	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler about it

	jmp	SWATTER_REDISP	; Join common re-display code



SCRUP_TSS:
SCRUP_BC:
	 jmp	 SWATTER_WAIT	; Wait for the next keystroke


; Scroll screen down

SWATTER_SCRDN:
	 movzx	 eax,DSP_STATE	; Get primary state

	 jmp	 SCRDN_ACT[eax*(type SCRDN_ACT)] ; Take appropriate action


SCRDN_IREGS:
	 mov	 eax,INSTRLDN	; Get top instruction's length
	 add	 UNAOFF,eax	; Add into offset of top instr

	 mov	 eax,UNAMASK	; Get current mask
	 and	 UNAOFF,eax	; Ensure it's within limits

	 mov	 al,@DSP_IREGS	; Screen state is instructions
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRDN_GDT:
	 add	 GDTOFF,size DESC_STR ; Skip to next row

	 mov	 al,@DSP_GDT	; Screen state is GDT
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRDN_IDT:
	 add	 IDTOFF,size IDT_STR ; Skip to next row

	 mov	 al,@DSP_IDT	; Screen state is IDT
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRDN_LDT:
	 add	 LDTOFF,size DESC_STR ; Skip to next row

	 mov	 al,@DSP_LDT	; Screen state is LDT
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRDN_MEM:
	 mov	 eax,MEMSIZE	; Get size of one memory row
	 add	 MEMOFF,eax	; Skip to next row
	 mov	 eax,MEMMASK	; Get the mask value
	 and	 MEMOFF,eax	; Mask off wrapped bits (if VM86 mode)

	 mov	 al,@DSP_MEM	; Screen state is memory
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRDN_DRn:
	 movzx	 eax,DSP_STAT2	; Get secondary state

	 cmp	 al,DSP_STATE	; Same as secondary state?
	 je	 near ptr SWATTER_WAIT ; Yes

	 or	 LCL_FLAG,@LCL_REDI ; Force screen re-display

	 jmp	 SCRDN_ACT[eax*(type SCRDN_ACT)] ; Take appropriate action


SCRDN_SRCH:
	 movzx	 eax,DSP_STAT2	; Get secondary state

	 cmp	 al,@DSP_SRCH	; Same as secondary state?
	 je	 near ptr SWATTER_WAIT ; Yes

	 or	 LCL_FLAG,@LCL_REDI ; Force screen re-display

	 jmp	 SCRDN_ACT[eax*(type SCRDN_ACT)] ; Take appropriate action


SCRDN_PTE:
	 add	 PTE_START,8*4	; Skip to next row

	 mov	 al,@DSP_PTE	; Screen state is PTE
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRDN_PDE:
	 add	 PDE_START,8*4	; Skip to next row

	 mov	 al,@DSP_PDE	; Screen state is PDE
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRDN_SYMTAB:
	 mov	 eax,SYMCOUNT	; Get # symbols in the table

	 sub	 eax,1		; Less one to get maximum value for SYMTAB_START
	 jc	 short @F	; Jump if no symbols

	 inc	 SYMTAB_START	; Skip to next symbol

	 cmp	 eax,SYMTAB_START ; Izit beyond the end?
	 jae	 short @F	; Jump if not

	 mov	 SYMTAB_START,eax ; Truncate to last symbol
@@:
	 mov	 al,@DSP_SYMTAB ; Screen state is SYMTAB
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRDN_FBROWS:
	 mov	 eax,1		; Add 1 to SLINE
	 call	 ADJUST_SLINE	; Check range and adjust pointers

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRDN_LSCR:
	 cmp	 LSCR_CNT,0	; Izit at the minimum?
	 jne	 short @F	; Jump if not

	 mov	 eax,NLSTBUF	; Get # last screen buffers
	 mov	 LSCR_CNT,eax	; Wrap to maximum+1
@@:
	 dec	 LSCR_CNT	; Count out another last screen

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRDN_ERRLOG:
	 inc	 ERRLOG_CLINE	; Count in another line

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRDN_MAC:
	 inc	 MACNDX 	; Scroll down one

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRDN_IVT:
	inc	IVTNDX		; Scroll down one

	jmp	SWATTER_REDISP	; Join common re-display code


SCRDN_WGH:
	inc	WGHNDX		; Scroll down one

	jmp	SWATTER_REDISP	; Join common re-display code


SCRDN_TDB:
SCRPGDN_TDB:
INCLOC_TDB:
	push	fs		; Save for a moment

	mov	fs,TDBSEL	; Address TDB
	assume	fs:nothing	; Tell the assembler about it

	mov	cx,fs:[0].TDB_NEXT ; Get the next selector
	jcxz	@F		; Jump if invalid

	mov	TDBSEL,cx	; Save as next TDB selector
@@:
	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler about it

	jmp	SWATTER_REDISP	; Join common re-display code



SCRDN_MDB:
SCRPGDN_MDB:
INCLOC_MDB:
	push	fs		; Save for a moment

	mov	fs,MDBSEL	; Address MDB
	assume	fs:nothing	; Tell the assembler about it

	mov	cx,fs:[0].MOD_NEXT ; Get the next selector
	jcxz	@F		; Jump if invalid

	mov	MDBSEL,cx	; Save as next MDB selector
@@:
	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler about it

	jmp	SWATTER_REDISP	; Join common re-display code



SCRDN_TSS:
SCRDN_BC:
	 jmp	 SWATTER_WAIT	; Wait for the next keystroke


; Scroll screen page up depending upon the current mode

SWATTER_SCRPGUP:
	 movzx	 eax,DSP_STATE	; Get primary state

	 jmp	 SCRPGUP_ACT[eax*(type SCRPGUP_ACT)] ; Take appropriate action


SCRPGUP_IREGS:
	 call	 GET_LASTPLEN	; Return with EAX=length of previous page
	 sub	 UNAOFF,eax	; Subtract from offset of top instr

	 mov	 eax,UNAMASK	; Get current mask
	 and	 UNAOFF,eax	; Ensure it's within limits

	 mov	 al,@DSP_IREGS	; Screen state is instructions
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGUP_GDT:
	 sub	 GDTOFF,(@NROWS-2)*(size DESC_STR) ; Skip to previous page
	 jnc	 short @F	; Jump if we didn't sink below zero

	 mov	 GDTOFF,0	; Cut back to zero
@@:
	 mov	 al,@DSP_GDT	; Screen state is GDT
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGUP_IDT:
	 sub	 IDTOFF,(@NROWS-2)*(size IDT_STR) ; Skip to previous page
	 jnc	 short @F	; Jump if we didn't sink below zero

	 mov	 IDTOFF,0	; Cut back to zero
@@:
	 mov	 al,@DSP_IDT	; Screen state is IDT
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGUP_LDT:
	 sub	 LDTOFF,(@NROWS-2)*(size DESC_STR) ; Skip to previous page
	 jnc	 short @F	; Jump if we didn't sink below zero

	 mov	 LDTOFF,0	; Cut back to zero
@@:
	 mov	 al,@DSP_LDT	; Screen state is LDT
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGUP_MEM:
	 mov	 eax,@NROWS-2	; Get # screen rows in memory display
	 mul	 MEMSIZE	; Times size of one memory row
	 sub	 MEMOFF,eax	; Skip to previous page
	 mov	 eax,MEMMASK	; Get the mask value
	 and	 MEMOFF,eax	; Mask off wrapped bits (if VM86 mode)

	 mov	 al,@DSP_MEM	; Screen state is memory
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGUP_DRn:
	 movzx	 eax,DSP_STAT2	; Get secondary state

	 cmp	 al,DSP_STATE	; Same as secondary state?
	 je	 near ptr SWATTER_WAIT ; Yes

	 or	 LCL_FLAG,@LCL_REDI ; Force screen re-display

	 jmp	 SCRPGUP_ACT[eax*(type SCRPGUP_ACT)] ; Take appropriate action


SCRPGUP_SRCH:
	 movzx	 eax,DSP_STAT2	; Get secondary state

	 cmp	 al,@DSP_SRCH	; Same as secondary state?
	 je	 near ptr SWATTER_WAIT ; Yes

	 or	 LCL_FLAG,@LCL_REDI ; Force screen re-display

	 jmp	 SCRPGUP_ACT[eax*(type SCRPGUP_ACT)] ; Take appropriate action


SCRPGUP_PTE:
	 sub	 PTE_START,(@NROWS-2)*(8*4) ; Skip to previous page

	cmp	PTE_START,0	; Izit negative?
	jge	short @F	; Jump if not

	neg	PTE_START	; Negate to get positive value
	and	PTE_START,8*4-1 ; Modulo a line's worth
	neg	PTE_START	; Negate to subtract from 0
@@:
	 mov	 al,@DSP_PTE	; Screen state is PTE
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGUP_PDE:
	 sub	 PDE_START,(@NROWS-2)*(8*4) ; Skip to previous page

	cmp	PDE_START,0	; Izit negative?
	jge	short @F	; Jump if not

	neg	PDE_START	; Negate to get positive value
	and	PDE_START,8*4-1 ; Modulo a line's worth
	neg	PDE_START	; Negate to subtract from 0
@@:
	 mov	 al,@DSP_PDE	; Screen state is PDE
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGUP_SYMTAB:
	 sub	 SYMTAB_START,@NSYMROWS ; Skip to previous page
	 jnc	 short @F	; Jump if we didn't sink below zero

	 mov	 SYMTAB_START,0 ; Cut back to zero
@@:
	 mov	 al,@DSP_SYMTAB ; Screen state is SYMTAB
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGUP_FBROWS:
	 mov	 eax,-(@FBROWS_NROWS-1) ; Subtract a page-1 from SLINE
	 call	 ADJUST_SLINE	; Check range and adjust pointers

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGUP_ERRLOG:
	 sub	 ERRLOG_CLINE,(@NROWS-2) ; Subtract a page from current line
	 jnc	 short @F	; Jump if >= 0

	 mov	 ERRLOG_CLINE,0 ; Starting line
@@:
	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGUP_MAC:
	 sub	 MACNDX,@NROWS-2 ; Skip to previous page
	 jnc	 short @F	; Jump if we didn't sink below zero

	 mov	 MACNDX,0	; Cut back to zero
@@:
	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGUP_IVT:
	sub	IVTNDX,@NROWS-2 ; Skip to previous page
	jnc	short @F	; Jump if we didn't sink below zero

	mov	IVTNDX,0	; Cut back to zero
@@:
	jmp	SWATTER_REDISP	; Join common re-display code


SCRPGUP_WGH:
	sub	WGHNDX,@NROWS-2 ; Skip to previous page
	jnc	short @F	; Jump if we didn't sink below zero

	mov	WGHNDX,0	; Cut back to zero
@@:
	jmp	SWATTER_REDISP	; Join common re-display code


SCRPGUP_TSS:
SCRPGUP_BC:
SCRPGUP_LSCR:
	 jmp	 SWATTER_WAIT	; Wait for the next keystroke


; Scroll screen page down

SWATTER_SCRPGDN:
	 movzx	 eax,DSP_STATE	; Get primary state

	 jmp	 SCRPGDN_ACT[eax*(type SCRPGDN_ACT)] ; Take appropriate action


SCRPGDN_IREGS:
	 mov	 eax,INSTRPDN	; Get page of instruction's length
	 add	 UNAOFF,eax	; Add into offset of top instr

	 mov	 eax,UNAMASK	; Get current mask
	 and	 UNAOFF,eax	; Ensure it's within limits

	 mov	 al,@DSP_IREGS	; Screen state is instructions
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGDN_GDT:
	 add	 GDTOFF,(@NROWS-2)*(size DESC_STR) ; Skip to next page

	 mov	 al,@DSP_GDT	; Screen state is GDT
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGDN_IDT:
	 add	 IDTOFF,(@NROWS-2)*(size IDT_STR) ; Skip to next page

	 mov	 al,@DSP_IDT	; Screen state is IDT
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGDN_LDT:
	 add	 LDTOFF,(@NROWS-2)*(size DESC_STR) ; Skip to next page

	 mov	 al,@DSP_LDT	; Screen state is LDT
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGDN_MEM:
	 mov	 eax,@NROWS-2	; Get # screen rows in memory display
	 mul	 MEMSIZE	; Times size of one memory row
	 add	 MEMOFF,eax	; Skip to next page
	 mov	 eax,MEMMASK	; Get the mask value
	 and	 MEMOFF,eax	; Mask off wrapped bits (if VM86 mode)

	 mov	 al,@DSP_MEM	; Screen state is memory
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGDN_DRn:
	 movzx	 eax,DSP_STAT2	; Get secondary state

	 cmp	 al,DSP_STATE	; Same as secondary state?
	 je	 near ptr SWATTER_WAIT ; Yes

	 or	 LCL_FLAG,@LCL_REDI ; Force screen re-display

	 jmp	 SCRPGDN_ACT[eax*(type SCRPGDN_ACT)] ; Take appropriate action


SCRPGDN_SRCH:
	 movzx	 eax,DSP_STAT2	; Get secondary state

	 cmp	 al,@DSP_SRCH	; Same as secondary state?
	 je	 near ptr SWATTER_WAIT ; Yes

	 or	 LCL_FLAG,@LCL_REDI ; Force screen re-display

	 jmp	 SCRPGDN_ACT[eax*(type SCRPGDN_ACT)] ; Take appropriate action


SCRPGDN_PTE:
	 add	 PTE_START,(@NROWS-2)*(8*4) ; Skip to next page

	 mov	 al,@DSP_PTE	; Screen state is PTE
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGDN_PDE:
	 add	 PDE_START,(@NROWS-2)*(8*4) ; Skip to next page

	 mov	 al,@DSP_PDE	; Screen state is PDE
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGDN_SYMTAB:
	 mov	 eax,SYMCOUNT	; Get # symbols in the table

	 sub	 eax,1		; Less one to get maximum value for SYMTAB_START
	 jc	 short @F	; Jump if no symbols

	 add	 SYMTAB_START,@NSYMROWS ; Skip to next page

	 cmp	 eax,SYMTAB_START ; Izit beyond the end?
	 jae	 short @F	; Jump if not

	 mov	 SYMTAB_START,eax ; Truncate to last symbol
@@:
	 mov	 al,@DSP_SYMTAB ; Screen state is SYMTAB
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGDN_FBROWS:
	 mov	 eax,@FBROWS_NROWS-1 ; Add a page-1 to SLINE
	 call	 ADJUST_SLINE	; Check range and adjust pointers

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGDN_ERRLOG:
	 add	 ERRLOG_CLINE,(@NROWS-2) ; Add a page to current line

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGDN_MAC:
	 add	 MACNDX,@NROWS-2 ; Skip to next page

	 jmp	 SWATTER_REDISP ; Join common re-display code


SCRPGDN_IVT:
	add	IVTNDX,@NROWS-2 ; Skip to next page

	jmp	SWATTER_REDISP	; Join common re-display code


SCRPGDN_WGH:
	add	WGHNDX,@NROWS-2 ; Skip to next page

	jmp	SWATTER_REDISP	; Join common re-display code


SCRPGDN_TSS:
SCRPGDN_BC:
SCRPGDN_LSCR:
	 jmp	 SWATTER_WAIT	; Wait for the next keystroke


; Display debug registers
; Because this is an overlay window, let DISP_DRn handle setting DSP_STAT2

SWATTER_DRn:
	 call	 DISP_DRn	; Display 'em

	 jmp	 SWATTER_WAIT	; Wait for the next keystroke


; Display NDP registers
; Because this is an overlay window, let DISP_NDP handle setting DSP_STAT2

SWATTER_NDP:
	 test	 LC2_FLAG,mask $LC2_NDP ; Izit present
	 jz	 short SWATTER_XNDP ; Jump if not

	 call	 DISP_NDP	; Display 'em

	 jmp	 SWATTER_WAIT	; Wait for the next keystroke

; NDP not present

SWATTER_XNDP:
	 mov	 MSGOFF,offset DGROUP:NDPERR ; Save offset of error message
	 or	 LC2_FLAG,mask $LC2_MSG ; Mark as message to display

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Toggle the stack display width

SWATTER_STK:
	 xor	 LCL_FLAG,@LCL_STKD ; Toggle the state

	 cmp	 DSP_STATE,@DSP_IREGS ; Are we displaying instructions?
	 jne	 short @F	; No, so don't display the stack

; Display the stack

	 push	 STACK_eSP	; Pass SS:eSP linear address
	 push	 STACK_eBP	; ...  SS:eBP ...
	 call	 DISP_STK	; Display it
@@:
	 jmp	 SWATTER_WAIT	; Wait for the next keystroke


; Toggle the screen restore state

SWATTER_SCRN:
	 xor	 LCL_FLAG,@LCL_SCRN ; Toggle the state

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Home to the current instruction

SWATTER_HOME:
	 mov	 FIRST_INSTR,-1 ; Clobber to force to top
	 call	 SET_CURINSTR	; Set current instruction disassembly values

	 mov	 al,@DSP_IREGS	; Screen state is instructions
	 call	 SET_STATE	; Set new state

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Toggle INT 01h and 03h intercepts

SWATTER_I0103:
	 lea	 edx,TOGINT01	; DS:EDX ==> interrupt intercept data
	 call	 ACT_TOGINT	; Toggle an interrupt intercept

	 lea	 edx,TOGINT03	; DS:EDX ==> interrupt intercept data
	 call	 ACT_TOGINT	; Toggle an interrupt intercept

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Toggle INT 01h intercept

SWATTER_I01:
	 lea	 edx,TOGINT01	; DS:EDX ==> interrupt intercept data
	 call	 ACT_TOGINT	; Toggle an interrupt intercept

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Toggle INT 02h intercept

SWATTER_I02:
	 lea	 edx,TOGINT02	; DS:EDX ==> interrupt intercept data
	 call	 ACT_TOGINT	; Toggle an interrupt intercept

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Toggle INT 03h intercept

SWATTER_I03:
	 lea	 edx,TOGINT03	; DS:EDX ==> interrupt intercept data
	 call	 ACT_TOGINT	; Toggle an interrupt intercept

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Toggle INT 06h intercept

SWATTER_I06:
	 lea	 edx,TOGINT06	; DS:EDX ==> interrupt intercept data
	 call	 ACT_TOGINT	; Toggle an interrupt intercept

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Toggle INT 0Ch intercept

SWATTER_I0C:
	 lea	 edx,TOGINT0C	; DS:EDX ==> interrupt intercept data
	 call	 ACT_TOGINT	; Toggle an interrupt intercept

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Toggle INT 0Dh intercept

SWATTER_I0D:
	 lea	 edx,TOGINT0D	; DS:EDX ==> interrupt intercept data
	 call	 ACT_TOGINT	; Toggle an interrupt intercept

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Toggle INT 0Eh intercept

SWATTER_I0E:
	 lea	 edx,TOGINT0E	; DS:EDX ==> interrupt intercept data
	 call	 ACT_TOGINT	; Toggle an interrupt intercept

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Decrement the location

SWATTER_DECLOC:
	 movzx	 eax,DSP_STATE	; Get primary state

	 jmp	 DECLOC_ACT[eax*(type DECLOC_ACT)] ; Take appropriate action


DECLOC_IREGS:
	 call	 GET_CURINSTR	; Return with EAX ==> current instruction
	 call	 GET_LASTILEN	; Return with EAX=length of previous instr

	 sub	 [ebp].FORW_EIP,eax ; Decrement instruction pointer

	 call	 SET_CURINSTR	; Set current instruction disassembly values

;;;;;;;; mov	 al,@DSP_IREGS	; Screen state is instructions
;;;;;;;; call	 SET_STATE	; Set new state
;;;;;;;;
	 jmp	 SWATTER_REDISP ; Join common re-display code


DECLOC_MEM:
	 cmp	 MEMTYPE,@MEM_TSS ; Are we displaying in TSS format?
	 jne	 short @F	; Jump if not
DECLOC_TSS:
	 dec	 IOMAP_LINE	; Skip to previous I/O map line
	 jns	 SWATTER_REDISP ; Join common re-display code

	 mov	 IOMAP_LINE,0	; Oops, we can't decrement below 0

	 jmp	 SWATTER_REDISP ; Join common re-display code

@@:
	 mov	 eax,MEMGRAN	; Get # bytes in memory display type
	 sub	 MEMOFF,eax	; Skip backward by that amount
	 mov	 eax,MEMMASK	; Get the mask value
	 and	 MEMOFF,eax	; Mask off wrapped bits (if VM86 mode)

	 jmp	 SWATTER_REDISP ; Join common re-display code


DECLOC_PTE:
	sub	PTE_START,4	; Back off to previous PTE

	cmp	PTE_START,0	; Izit negative?
	jge	short @F	; Jump if not

	neg	PTE_START	; Negate to get positive value
	and	PTE_START,8*4-1 ; Modulo a line's worth
	neg	PTE_START	; Negate to subtract from 0
@@:
	jmp	SWATTER_REDISP	; Join common re-display code


DECLOC_PDE:
	sub	PDE_START,4	; Back off to previous PDE

	cmp	PDE_START,0	; Izit negative?
	jge	short @F	; Jump if not

	neg	PDE_START	; Negate to get positive value
	and	PDE_START,8*4-1 ; Modulo a line's worth
	neg	PDE_START	; Negate to subtract from 0
@@:
	jmp	SWATTER_REDISP	; Join common re-display code


DECLOC_GDT:
DECLOC_IDT:
DECLOC_LDT:
DECLOC_SYMTAB:
DECLOC_FBROWS:
DECLOC_ERRLOG:
DECLOC_DRn:
DECLOC_SRCH:
DECLOC_BC:
DECLOC_LSCR:
DECLOC_MAC:
DECLOC_IVT:
DECLOC_WGH:
	 jmp	 SWATTER_REDISP ; Join common re-display code



; Increment the location

SWATTER_INCLOC:
	 movzx	 eax,DSP_STATE	; Get primary state

	 jmp	 INCLOC_ACT[eax*(type INCLOC_ACT)] ; Take appropriate action


INCLOC_IREGS:
	 mov	 eax,INSTRLEN	; Get current instruction's length
	 add	 [ebp].FORW_EIP,eax ; Increment instruction pointer

	 call	 SET_CURINSTR	; Set current instruction disassembly values

;;;;;;;; mov	 al,@DSP_IREGS	; Screen state is instructions
;;;;;;;; call	 SET_STATE	; Set new state
;;;;;;;;
	 jmp	 SWATTER_REDISP ; Join common re-display code


INCLOC_MEM:
	 cmp	 MEMTYPE,@MEM_TSS ; Are we displaying in TSS format?
	 jne	 short @F	; Jump if not
INCLOC_TSS:
	 mov	 eax,IOMAP_LINE ; Get current line

	 cmp	 eax,IOMAP_LINE_MAX ; Have we reached the end of the map?
	 jae	 SWATTER_REDISP ; Join common re-display code if so

	 inc	 IOMAP_LINE	; Skip to next I/O map line

	 jmp	 SWATTER_REDISP ; Join common re-display code

@@:
	 mov	 eax,MEMGRAN	; Get # bytes in memory display type
	 add	 MEMOFF,eax	; Skip forward by that amount
	 mov	 eax,MEMMASK	; Get the mask value
	 and	 MEMOFF,eax	; Mask off wrapped bits (if VM86 mode)

	 jmp	 SWATTER_REDISP ; Join common re-display code


INCLOC_PTE:
	add	PTE_START,4	; Skip to next PTE

	jmp	SWATTER_REDISP ; Join common re-display code


INCLOC_PDE:
	add	PDE_START,4	; Skip to next PDE

	jmp	SWATTER_REDISP ; Join common re-display code


INCLOC_GDT:
INCLOC_IDT:
INCLOC_LDT:
INCLOC_SYMTAB:
INCLOC_FBROWS:
INCLOC_ERRLOG:
INCLOC_DRn:
INCLOC_SRCH:
INCLOC_BC:
INCLOC_LSCR:
INCLOC_MAC:
INCLOC_IVT:
INCLOC_WGH:
	 jmp	 SWATTER_REDISP ; Join common re-display code


; Display the last AutoFault message

SWATTER_AFL:
	 cmp	 LAST_AFLERR,-1 ; Izit valid
	 je	 short @F	; Jump if not

	 mov	 al,ERRATTR	; Get error window attribute
	 push	 ax		; Pass as attribute to smear
	 push	 LAST_AFLERR	; Pass offset of error message
	 push	 LAST_AFLWIN	; Pass offset of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute
@@:
	 jmp	 SWATTER_GETKEY ; Join common code


; Goto .RETN

SWATTER_GRETN:
	 call	 PARSE_RETN	; Parse RETN address from stack
				; Return with EAX = offset
				; ...	       BX = segment/selector (if @ADDR_SEP)
				; ...	       CX = flags
				; ...	      EDX = 32-bit base address for BX
	 jc	 short SWATTER_SELERR ; Jump if invalid selector

	 add	 edx,eax	; Add to get 32-bit linear address

	 jmp	 SWATTER_SKIP1	; Join common skip code


; Goto .RETF

SWATTER_GRETF:
	 call	 PARSE_RETF	; Parse RETF address from stack
				; Return with EAX = offset
				; ...	       BX = segment/selector (if @ADDR_SEP)
				; ...	       CX = flags
				; ...	      EDX = 32-bit base address for BX
	 jc	 short SWATTER_SELERR ; Jump if invalid selector

	 add	 edx,eax	; Add to get 32-bit linear address

	 jmp	 SWATTER_SKIP1	; Join common skip code


; Retrieve previous command

SWATTER_CMDPREV:
	call	CMD_RETR_PREV	; Retrieve the previous command

	jmp	SWATTER_WAIT	; Wait for the next keystroke


; Retrieve next command

SWATTER_CMDNEXT:
	call	CMD_RETR_NEXT	; Retrieve the next command

	jmp	SWATTER_WAIT	; Wait for the next keystroke


; Display command history

SWATTER_CMDHIST:
	call	CMD_DISP_HIST	; Display the command history

	jmp	SWATTER_WAIT	; Wait for the next keystroke


SWATTER_SELERR:
	 mov	 MSGOFF,offset DGROUP:SELERR ; Save offset of error message
	 or	 LC2_FLAG,mask $LC2_MSG ; Mark as message to display

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Breakpoint to the address of the instruction on the top line

SWATTER_BGOTO:
	 cmp	 DSP_STATE,@DSP_IREGS ; Ensure we're displaying instructions
	 jne	 short SWATTER_BGOTO_ERR ; Jump if not

	 mov	 edx,FIRST_INSTR ; Get linear address of top instr

	 jmp	 SWATTER_SKIP0	; Join common skip code

SWATTER_BGOTO_ERR:
	 jmp	 SWATTER_REDISP ; Join common re-display code


; Push current address, goto address referenced by the top line
; If the current instruction references an address directly or indirectly,
; display the instructions beginning with that address

SWATTER_AGOTO:
	 cmp	 DSP_STATE,@DSP_IREGS ; Ensure we're displaying instructions
	 jne	 near ptr SWATTER_AGOTO_ERR ; Jump if not

; Ensure there's enough room in the ARET table

	 cmp	 ARET_CNT,0	; Izit at the bottom?
	 je	 near ptr SWATTER_AGOTO_ERR ; Jump if so

; Save the current segment/selector and offset

	 mov	 esi,ARETBASE	; DS:ESI ==> offset into ARET table

	 mov	 eax,UNAOFF	; Get offset of top instr
	 mov	 DGROUP:[esi].ARET_FVEC.FOFF,eax ; Save to restore later
	 mov	 ax,UNASEL	; Get segment of top instr
	 mov	 DGROUP:[esi].ARET_FVEC.FSEL,ax ; Save to restore later

	 mov	 ax,UNAMODE	; Get mode
	 mov	 DGROUP:[esi].ARET_MODE,ax ; Save to restore later
	 mov	 eax,UNAMASK	; Get mask
	 mov	 DGROUP:[esi].ARET_MASK,eax ; Save to restore later
	 mov	 eax,UNABASE	; Get base address of top instr
	 mov	 DGROUP:[esi].ARET_BASE,eax ; Save to restore later

; Decode the first instruction at the top of the screen

	 mov	 esi,FIRST_INSTR ; Get linear address of first instr
	 call	 DECODE_ADDR	; Decode the target address of the instr
				; at AGROUP:ESI
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base	 (if @ADDR_SEP)
	 jc	 short SWATTER_AGOTO_ERR ; Jump if none

; Set new values for UNAOFF, UNASEL, and UNABASE

	 mov	 UNAOFF,eax	; Save as offset of top instr

	 test	 cx,@ADDR_SEP	; Separator specified?
	 jz	 short @F	; Not this time

	 mov	 UNABASE,edx	; Save as base address of top instr
	 mov	 UNASEL,bx	; Save as segment of ...

	 and	 UNAMODE,not @MODE_USE32 ; Assume it's USE16
	 mov	 UNAMASK,0000FFFFh ; ...

	 test	 cx,@ADDR_USE32 ; Izit USE32?
	 jz	 short @F	; Jump if not

	 or	 UNAMODE,@MODE_USE32 ; Mark as USE32
	 mov	 UNAMASK,0FFFFFFFFh ; ...
@@:

; Bump ARET pointers now that we have a new address

	 add	 ARETBASE,size ARET_STR ; Skip to next entry
	 dec	 ARET_CNT	; Count out another one

	 or	 LCL_FLAG,@LCL_REDI ; Mark as forced re-display of screen

;;;;;;;; jmp	 SWATTER_REDISP ; Join common re-display code

SWATTER_AGOTO_ERR:
	 jmp	 SWATTER_REDISP ; Join common re-display code


; Return from an address

SWATTER_ARET:

; Ensure no underflow

	 cmp	 ARET_CNT,@ARET_CNT ; Izit at the maximum?
	 jae	 short SWATTER_ARET_ERR ; Jump if so

; Bump ARET pointers now that we have an old address

	 inc	 ARET_CNT	; Count in another one
	 sub	 ARETBASE,size ARET_STR ; Skip to previous entry

; Restore old values for UNAOFF, UNASEL, and UNABASE

	 mov	 esi,ARETBASE	; DS:ESI ==> offset into ARET table

	 mov	 eax,DGROUP:[esi].ARET_FVEC.FOFF ; Get old value
	 mov	 UNAOFF,eax	; Save as offset of top instr
	 mov	 ax,DGROUP:[esi].ARET_FVEC.FSEL ; Get old value
	 mov	 UNASEL,ax	; Save as segment of top instr

	 mov	 ax,DGROUP:[esi].ARET_MODE ; Get old value
	 mov	 UNAMODE,ax	; Save as mode
	 mov	 eax,DGROUP:[esi].ARET_MASK ; Get old value
	 mov	 UNAMASK,eax	; Save as mask
	 mov	 eax,DGROUP:[esi].ARET_BASE ; Get old value
	 mov	 UNABASE,eax	; Save as base address of top instr

	 or	 LCL_FLAG,@LCL_REDI ; Mark as forced re-display of screen

;;;;;;;; jmp	 SWATTER_REDISP ; Join common re-display code

SWATTER_ARET_ERR:
	 jmp	 SWATTER_REDISP ; Join common re-display code


SWATTER_SIGINT:
	 mov	 edx,LaSIGINT_BP ; Get linear address of SIGINT breakpoint
	mov	eax,SIGINT_OFF	; Get the offset
	mov	bx,SIGINT_SEL	; Get segment/selector
	mov	cx,SIGINT_FLAG	; Get flags of SIGINT breakpoint

	 jmp	 short SWATTER_SKIP1 ; Join common code

; Put a breakpoint interrupt (0CCh) at caller's CS:EIP unless the first
; instruction is a jump of any kind (JMP, Jcc, etc.)

SWATTER_SKIP:
	 call	 CHECK_JMPRET	; Check for jump/return instructions
	 jc	 near ptr SWATTER_TRACE ; Trace it instead

	 mov	 edx,NEXT_INSTR ; Get linear address of next instruction
SWATTER_SKIP0:
	mov	bx,[ebp].FORW_CS ; Get the segment/selector
	mov	eax,edx 	; Copy the linear address
	sub	eax,UNABASE	; Less base address to get offset

	xor	cx,cx		; Assume it's VM86 mode

	test	UNAMODE,@MODE_VM ; Izit VM86 mode?
	jnz	short @F	; Jump if so

	mov	cx,@ADDR_PM	; Mark as PM
@@:

COMMENT|

Enter here to set a temporary breakpoint

On entry:

EAX	=	offset
BX	=	segment/selector
CX	=	flags
EDX	=	linear address

|

SWATTER_SKIP1:
; If we're forcing use of BD registers (i.e. in a paging environment like
; Win95) don't use BC for single-skip.
; We _could_ have an option here to fall through the code at SWATTER_SKIPOUT
; to using an Int 3 if no BD registers are free, but that doesn't seem to
; be a common occurrence...
	 test	 SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	 jnz	 short SWATTER_SKIPOUT ; Jump if so

	 call	 CHECK_BACKLINK ; If we're in TSS mode, ensure back link valid
	 jc	 near ptr SWATTER_REDISP ; Jump if not

	mov	esi,eax 	; Save offset

	 mov	 al,@OPCOD_INT3 ; Breakpoint interrupt
	 xchg	 al,AGROUP:[edx] ; Swap with the data

; In case we're dealing with a cached ROM on a 486, invalidate
; the cache before comparing the values.

	 test	 LC2_FLAG,@LC2_486 ; Izit a 486 or later?
	 jz	 short @F	; Jump if not

	 WBINVD 		; Write back and invalidate the cache
@@:
	 cmp	 AGROUP:[edx].LO,@OPCOD_INT3 ; Did it take?
	 jne	 short SWATTER_SKIPOUT ; Jump if not

	mov	BREAKPT_SEL,bx	; Save the segment/selector
	mov	BREAKPT_OFF,esi ; Save the offset
	mov	BREAKPT_PTR,edx ; Save the base address
	mov	BREAKPT_VAL,al ; Save to restore the next time
	or	cx,@ADDR_INUSE or @ADDR_ENA ; Mark as enabled and in use
	mov	BREAKPT_FLAG,cx ; Save for later use

; Note that breakpoint address may be invalid over an instruction or
; routine which enables paging *FIXME*

	 jmp	 SWATTER_XTF	; Join common trap flag clear code

; The breakpoint was into ROM and did not stick,
; try using a temporary code breakpoint instead.

SWATTER_SKIPOUT:
;;;;;;;; mov	 edx,?? 	; Get breakpoint address (already set)
	 mov	 eax,SAVE_DR7	; Get the Debug Control register

	 mov	 ecx,(mask $G0 or mask $L0) ; Initialize DR7 (Gn/Ln) mask
	 mov	 esi,(mask $LEN0 or mask $RW0) ; Initialize DR7 (Len,R/W) mask
				; Assume DR0 will be used

	 test	 eax,ecx	; Is DR0 in use?
	 jz	 short SWATTER_ROMREG0 ; Jump if available

	 shl	 ecx,(width $L0) + (width $G0) ; Assume DR1 will be used
	 shl	 esi,(width $LEN0) + (width $RW0) ; Assume DR1 will be used

	 test	 eax,ecx	; Is DR1 in use?
	 jz	 short SWATTER_ROMREG1 ; Jump if available

	 shl	 ecx,(width $L0) + (width $G0) ; Assume DR2 will be used
	 shl	 esi,(width $LEN0) + (width $RW0) ; Assume DR2 will be used

	 test	 eax,ecx	; Is DR2 in use?
	 jz	 short SWATTER_ROMREG2 ; Jump if so available

	 shl	 ecx,(width $L0) + (width $G0) ; Assume DR3 will be used
	 shl	 esi,(width $LEN0) + (width $RW0) ; Assume DR3 will be used

	 test	 eax,ecx	; Is DR3 in use?
	 jnz	 short SWATTER_XROMREG ; Jump if not available

SWATTER_ROMREG3:
	 mov	 ebx,dr3	; Save old linear address
	 mov	 dr3,edx	; Set breakpoint at next instr

	 jmp	 SWATTER_ROMREG ; Join common code

SWATTER_ROMREG2:
	 mov	 ebx,dr2	; Save old linear address
	 mov	 dr2,edx	; Set breakpoint at next instr

	 jmp	 SWATTER_ROMREG ; Join common code

SWATTER_ROMREG1:
	 mov	 ebx,dr1	; Save old linear address
	 mov	 dr1,edx	; Set breakpoint at next instr

	 jmp	 SWATTER_ROMREG ; Join common code

SWATTER_ROMREG0:
	 mov	 ebx,dr0	; Save old linear address
	 mov	 dr0,edx	; Set breakpoint at next instr

;;;;;;;; jmp	 SWATTER_ROMREG ; Join common code

SWATTER_ROMREG:

; Save orig DR7 (Len, R/W bits)

	 mov	 eax,esi	; Get DR7 (Len,R/W) mask
	 and	 eax,SAVE_DR7	; Get orig DR7 bits corresponding to our DRn
	 mov	 ROMSKIP_DR7,eax ; Save old DR7 value (Len + R/W)

; Enable breakpoint as CODE, Length=0

	 not	 esi		; Negate DR7 mask
	 and	 SAVE_DR7,esi	; Ensure breakpoint is type CODE, Len=0

; Save orig DRn linear address

	 mov	 ROMSKIP_DRN,ebx ; Save original DR(0-4) linear address

; Save new DR7 (Gn,Ln bits)

	 mov	 ROMSKIP_MASK,ecx ; Save DR7 (Gn,Ln) breakpoint mask

; Enable the available DRn register through DR7

	 or	 SAVE_DR7,ecx	; Enable the available DRn register

	 jmp	 SWATTER_XTF	; Join common trap flag clear code

SWATTER_XROMREG:

; Tell 'em you can't write into ROM
; If we're using BD by default, try using BC (FIXME)

	 mov	 MSGOFF,offset DGROUP:ROMERR ; Save offset of error message
	 or	 LC2_FLAG,mask $LC2_MSG ; Mark as message to display

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Convert the instruction at the top of the screen to NOPs

SWATTER_ZAP:
	 mov	 ecx,INSTRLDN	; Length of instruction at top of screen
	 mov	 edi,FIRST_INSTR ; Get linear address of top instr

	 push	 es		; Save for a moment

	 mov	 es,COMMON.FILE_4GB ; Address all of memory
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 eax,@OPCOD_NOP4 ; Get (four-byte) do-nothing opcode (SHL EAX,00)

	 push	 ecx		; Save for a moment
	 shr	 ecx,2-0	; Convert from bytes to dwords
     rep stos	 AGROUP:[edi].EDD ; Save four-byte opcode
	 pop	 ecx		; Restore

	 and	 ecx,4-1	; Isolate residue MOD 4

; If we have exactly three bytes remaining, use NOP3

	 cmp	 ecx,3		; Izit exactly three bytes?
	 jne	 short @F	; Jump if not

	 mov	 eax,@OPCOD_NOP3 ; Get (three-byte) do-nothing opcode (XCHG EAX,EAX)
S32	 stos	 AGROUP:[edi].ELO ; Save two-byte opcode
	 shr	 eax,16 	; Shift down to low-order
S32	 stos	 AGROUP:[edi].LO ; Save one-byte opcode
	 xor	 ecx,ecx	; No more bytes to store
@@:
	 mov	 ax,@OPCOD_NOP2 ; Get (two-byte) do-nothing opcode (XCHG AX,AX)

	 push	 ecx		; Save for a moment
	 shr	 ecx,1-0	; Convert from bytes to words
     rep stos	 AGROUP:[edi].ELO ; Save two-byte opcode
	 pop	 ecx		; Restore

	 and	 ecx,2-1	; Isolate residue MOD 2

	 mov	 al,@OPCOD_NOP	; Get (one-byte) do-nothing opcode (XCHG AX,AX)

;;;;;;;; push	 ecx		; Save for a moment
;;;;;;;; shr	 ecx,0-0	; Convert from bytes to bytes
     rep stos	 AGROUP:[edi].LO ; Save one-byte opcode
;;;;;;;; pop	 ecx		; Restore

	 pop	 es		; Restore
	 assume  es:DGROUP	; Tell the assembler about it

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Display the help screen

SWATTER_HELP:
	 call	 DISP_HELP	; Display it

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Display the WKD menu

SWATTER_WKD:
	call	DISP_WKD	; Display it

	jmp	SWATTER_REDISP	; Join common re-display code


; Display the GDT

SWATTER_GDT:
	 mov	 al,@DSP_GDT	; Screen state is GDT
	 mov	 DSP_STATE,al	; Set primary state
	 mov	 DSP_STAT2,al	; ... secondary ...

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Display the IDT

SWATTER_IDT:
	 mov	 al,@DSP_IDT	; Screen state is IDT
	 mov	 DSP_STATE,al	; Set primary state
	 mov	 DSP_STAT2,al	; ... secondary ...

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Display the LDT

SWATTER_LDT:
	 mov	 al,@DSP_LDT	; Screen state is LDT
	 mov	 DSP_STATE,al	; Set primary state
	 mov	 DSP_STAT2,al	; ... secondary ...

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Display the TSS

SWATTER_TSS:
	 mov	 al,@DSP_TSS	; Screen state is TSS
	 mov	 DSP_STATE,al	; Set primary state
	 mov	 DSP_STAT2,al	; ... secondary ...

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Display the PTEs

SWATTER_PTE:

; If paging is disabled, signal an error

	 mov	 eax,cr0	; Get control register

	 test	 eax,mask $PG	; Check for paging enabled
	 jz	 short SWATTER_XPAGE ; Jump if not

	 mov	 al,@DSP_PTE	; Screen state is PTE
	 mov	 DSP_STATE,al	; Set primary state
	 mov	 DSP_STAT2,al	; ... secondary ...

	 jmp	 SWATTER_REDISP ; Join common re-display code

SWATTER_XPAGE:
	 mov	 MSGOFF,offset DGROUP:PAGERR ; Save offset of error message
	 or	 LC2_FLAG,mask $LC2_MSG ; Mark as message to display

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Display the search screen

SWATTER_SRCH:
	 mov	 al,@DSP_SRCH	; Screen state is search
	 mov	 DSP_STATE,al	; Set primary state
	 mov	 DSP_STAT2,al	; ... secondary ...

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Display the PDEs

SWATTER_PDE:

; If paging is disabled, signal an error

	 mov	 eax,cr0	; Get control register

	 test	 eax,mask $PG	; Check for paging enabled
	 jz	 short SWATTER_XPAGE ; Jump if not

	 mov	 al,@DSP_PDE	; Screen state is PDE
	 mov	 DSP_STATE,al	; Set primary state
	 mov	 DSP_STAT2,al	; ... secondary ...

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Display symbol table

SWATTER_SYMTAB:
	 mov	 al,@DSP_SYMTAB ; Screen state is display symtab
	 mov	 DSP_STATE,al	; Set primary state
	 mov	 DSP_STAT2,al	; Set secondary "

	 jmp	 SWATTER_REDISP ; Join common re-display code

; Display file browser

SWATTER_FBROWS:
	 mov	 al,@DSP_FBROWS ; Screen state is display file browser
	 mov	 DSP_STATE,al	; Set primary state
	 mov	 DSP_STAT2,al	; Set secondary "
	 mov	 DSP_STAT3,@DSP_IREGS ; Ensure we don't re-enter browser

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Enter chat mode.  Ctrl-F8 again brings us back to Kansas

SWATTER_CHAT:
	 call	 CMD_CHAT	; Chat with remote SWAT user
	 call	 DISP_CMDLINE	; Re-display the command line

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Enter remote debugging session.  Ctrl-F9 brings us back.

SWATTER_REMDBG:
	 call	 CMD_REMDBG	; Hook up for remote debugging
	 call	 DISP_CMDLINE	; Re-display the command line

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Display error log

SWATTER_ERRLOG:
	call	SetErrorLog	; Set displaying error log state

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Toggle the video base address

SWATTER_VBASE:
	 push	 PSCRBUF	; Pass address of screen buffer
	 call	 REST_SCR	; Restore the original screen

	 call	 FLIPVBASE	; Switch to other video base

	 push	 PSCRBUF	; Pass address of screen buffer
	 PUSHD	 1		; Use actual screen base
	 call	 SAVE_SCR	; Save all screen text

	 call	 DISP_CMDLINE	; Re-display the command line

	 jmp	 SWATTER_REDISP ; Join common re-display code


; Swap screens unless DVGA specified

SWATTER_SCR:
	 test	 ARG_FLAG,@ARG_DVGA ; Izit specfied?
	 jnz	 short SWATTER_SCR1 ; Jump if so

	 push	 PSCRBUF	; Pass address of screen buffer
	 call	 REST_SCR	; Restore the original screen

	 call	 GETKEY 	; Get and discard a keystroke

	 push	 CURPOSN	; Get new cursor position
	 call	 SET_CURPOS	; Set it

	 push	 CURTYPE	; Get new cursor type
	 call	 SET_CURTYP	; Set it

	 call	 DISP_CMDLINE	; Re-display the command line
SWATTER_SCR1:
	 jmp	 SWATTER_REDISP ; Join common re-display code


; Display last screen buffer

SWATTER_LSCR:
	 mov	 al,@DSP_LSCR	; Screen state is Last Screen
	 mov	 DSP_STATE,al	; Set primary state
	 mov	 DSP_STAT2,al	; ... secondary ...

	 jmp	 SWATTER_REDISP ; Join common re-display code


SWATTER_CTLTRACE:
	 or	 LC4_FLAG,@LC4_CTRACE ; Mark as Ctrl-trace

; Check for INT or any of the flag changing instructions such as
; POPF, POPFD, IRET, IRETD which might clear the trap flag

SWATTER_TRACE:
	 call	 CHECK_BACKLINK ; If we're in TSS mode, ensure back link valid
	 jc	 near ptr SWATTER_REDISP ; Jump if not

	 or	 [ebp].FORW_EFL.ELO,mask $TF ; Set the trap flag to trace
	call	SET_BTF 	; Enable BTF if appropriate

	 mov	 esi,CUR_INSTR ; Get linear address of cur instr
SWATTER_TRACE1:
	 lods	 AGROUP:[esi].ELO ; Get the next two instruction bytes

; Because PUSHFd pushes TF, we convert a trace into a skip
; unless we're BTFing in which case we can't afford for the
; matching POPFd to turn off TF.

	test	LC4_FLAG,@LC4_BTF ; Are we BTFing?
	jnz	short @F	; Jump if so

	 cmp	 al,@OPCOD_PUSHF ; Izit PUSHF?
	 je	 near ptr SWATTER_SKIP ; Jump if so

	 cmp	 ax,@OPCOD_PUSHFD ; Izit PUSHFD?
	 je	 near ptr SWATTER_SKIP ; Jump if so
@@:
	 mov	 esi,STACK_eSP	; Get caller's stack linear address

; Check for ARPL in VM86 mode

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	 jz	 short @F	; Jump if not

	 cmp	 al,@OPCOD_ARPL ; Izit ARPL?
	 je	 near ptr SWATTER_TRACEARPL ; Yes, handle it specially
@@:

; Check for INT 0FFh in VM86 mode

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	 jz	 short @F	; Jump if not

	 cmp	 ax,(0FFh shl 8) or @OPCOD_INT ; Izit INT 0FFh?
	 je	 near ptr SWATTER_TRACEINTFF ; Yes, handle it specially
@@:
	 cmp	 al,@OPCOD_INT	; Check for INT
	 je	 near ptr SWATTER_INT ; Good guess

	 cmp	 al,@OPCOD_INT3 ; Check for INT 03h
	 je	 near ptr SWATTER_INT3 ; Good guess

	 test	 [ebp].FORW_EFL.ELO,mask $OF ; Check overflow flag for INTO
	 jz	 short @F	; Jump if clear

	 cmp	 al,@OPCOD_INTO ; Check for INTO
	 je	 near ptr SWATTER_INTO ; Good guess
@@:

; Handle trace over far JMP/CALL which performs a task switch in PM

	 call	 CHECK_PMTSS	; Check for PM TSS task switch
	 jnc	 short SWATTER_TRACE_TSS ; Jump if so with BX = TSS selector

; Handle instruction meaning depending upon the D-bit

	 test	 CUR_INSTR_ARW.HI,mask $DTE_B ; Check for D-bit
	 jz	 short SWATTER_TRACE16 ; Jump if USE16
				       ; Fall through if USE32

	 cmp	 al,@OPCOD_POPF ; Check for POPF
	 je	 near ptr SWATTER_TRACEIT ; Good guess

	 cmp	 ax,@OPCOD_POPFD ; Check for POPFD
	 je	 near ptr SWATTER_TRACEIT ; Good guess

	 add	 esi,2+2	; Skip over IP, CS if USE16 IRET

	 cmp	 ax,@OPCOD_IRETD ; Check for USE16 IRET
	 je	 short SWATTER_IRET ; Good guess

	 add	 esi,2+2	; Skip over EIP, CS, fill

	 cmp	 al,@OPCOD_IRET ; Check for USE32 IRET
	 je	 short SWATTER_IRET ; Good guess
SWATTER_LOADALLD:
	 cmp	 ax,@OPCOD_LOADALLD ; Check for LOADALLD
	 jne	 short @F	; Join common exit code

; Set trap flag in caller's ES:[EDI].LA32_EFL

	 mov	 eax,[ebp-@BPBACK].BACK_ES.DTR_BASE ; Get base of caller's ES
	 add	 eax,[ebp].FORW_EDI ; Plus EDI
	 or	 AGROUP:[eax].LA32_EFL.ELO,mask $TF ; Set TF in caller's EFL
@@:
	 jmp	 SWATTER_CLC	; Join common exit code

SWATTER_TRACE16:
	 cmp	 al,@OPCOD_POPF ; Check for POPF
	 je	 short SWATTER_TRACEIT ; Good guess

	 cmp	 ax,@OPCOD_POPFD ; Check for POPFD
	 je	 short SWATTER_TRACEIT ; Good guess

	 add	 esi,2+2	; Skip over IP, CS if USE16 IRET

	 cmp	 al,@OPCOD_IRET ; Check for USE16 IRET
	 je	 short SWATTER_IRET ; Good guess

	 add	 esi,2+2	; Skip over EIP, CS, fill

	 cmp	 ax,@OPCOD_IRETD ; Check for USE32 IRET
	 jne	 short SWATTER_LOADALLD ; No, check for LOADALLD

; We're about to trace over an IRET or IRETD
; If the NT bit is set, we must set the debug bit in the TSS_DBG flag
; and mark it to be cleared the next time unless it was already set

	 public  SWATTER_IRET
SWATTER_IRET:
	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	 jnz	 short SWATTER_TRACEIT ; Jump if so

	 test	 [ebp].FORW_EFL.ELO,mask $NT ; Izit NT mode?
	 jz	 short SWATTER_TRACEIT ; Jump if not

	 cmp	 [ebp-@BPBACK].BACK_TR.DTR_LIM,0 ; Izit invalid?
	 je	 short SWATTER_TRACEIT ; Jump if so

	 mov	 eax,[ebp-@BPBACK].BACK_TR.DTR_BASE ; Get base address of TSS
	 mov	 bx,AGROUP:[eax].TSS_LINK ; Get the back link TSS selector
SWATTER_TRACE_TSS:
	 push	 bx		; Pass the TSS selector
	 call	 GETBASE	; Return with EAX = selector base
	 jc	 near ptr SWATTER_CLC ; Jump if something went wrong

	 bts	 AGROUP:[eax].TSS_DBG,0 ; Set and test the debug bit
	 jc	 short @F	   ; Jump if already set

	 or	 LC2_FLAG,mask $LC2_TDB ; Tell SWATTER to clear it the next time
@@:
	 jmp	 SWATTER_XTF	; Join common trap flag clear code
				; so the EFL saved in the current TSS won't
				; have it set.
SWATTER_TRACEIT:
	 or	 AGROUP:[esi].ELO,mask $TF ; Ensure trap flag set

	 jmp	 SWATTER_CLC	; Join common exit code

COMMENT|

Trace through an ARPL instruction by going to the first instruction
in the PM Invalid Opcode handler.  This helps debugging in a Windows
context which uses ARPL to return to PM.

Note we're assuming that this interrupt # is handled by an interrupt,
trap, or 386 task gate.  We do *NOT* handle 286 task gates as yet.

|

SWATTER_TRACEARPL:
	 mov	 ah,06h 	; Set interrupt #

	 jmp	 SWATTER_INTPM	; Join common PM interrupt code

COMMENT|

Trace through an INT 0FFh instruction by going to the first
instruction in the PM INT 0FFh handler.  This helps debugging in a
DPMI context which uses this instruction to return to PM.

Note we're assuming that this interrupt # is handled by an interrupt,
trap, or 386 task gate.  We do *NOT* handle 286 task gates as yet.

|

SWATTER_TRACEINTFF:
	 jmp	 SWATTER_INTPM	; Join common PM interrupt code

COMMENT|

Simulate INT instruction

On entry:

AH	 =	 interrupt #
GS:ESI	 ==>	 caller's stack

|

SWATTER_INTO:
	 mov	 ah,04h 	; Use interrupt # 04h
	 mov	 ebx,1		; Instruction length

	 jmp	 short SWATTER_INT1 ; Join common code

SWATTER_INT3:
	 mov	 ah,03h 	; Use interrupt # 03h
	 mov	 ebx,1		; Instruction length

	 jmp	 short SWATTER_INT1 ; Join common code

SWATTER_INT:
	 mov	 ebx,2		; Instruction length
SWATTER_INT1:
	 test	 [ebp].FORW_EFL.EHI,mask $VM ; VM 8086 or protected mode?
	 jz	 near ptr SWATTER_INTPM ; Jump if protected mode

	 test	 LC4_FLAG,@LC4_CTRACE ; Izit Ctrl-trace?
	 jnz	 near ptr SWATTER_INTPM0 ; Jump if so
SWATTER_INT2:

; INT-like instruction in VM86 mode

; Calculate IRET_VEC

	 test	 LCL_FLAG,@LCL_IRET ; Izit already calculated?
	 jnz	 short SWATTER_INT_XIRET ; Jump if so

	 REGSAVE <eax,ecx,edi,es> ; Save for a moment

	 push	 gs		; Get all memory selector
	 pop	 es		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 edi,0FFFFFh	; Get end of ROM
	 mov	 al,@OPCOD_IRET ; Opcode for an IRET
	 mov	 ecx,CON64KB	; We know it's there
	 std			; Search backwards
   repne scas	 es:[edi].LO	; Search for it
	 cld			; Back to forwards
;;;;;;;; jne	 ???		; It can't fail

	 sub	 edi,0EFFFFh	; Convert to origin-0
	 mov	 IRET_VEC.VOFF,di ; Save for later use
	 mov	 IRET_VEC.VSEG,0F000h ; Set segment address

	 or	 LCL_FLAG,@LCL_IRET ; Mark as calculated

	 REGREST <es,edi,ecx,eax> ; Restore
	 assume  es:DGROUP	; Tell the assembler about it
SWATTER_INT_XIRET:

IRETX_STR struc

IRET1_IP dw	 ?		; IRET in F000 ROM
IRET1_CS dw	 ?
IRET1_FL dw	 ?
IRET2_IP dw	 ?		; INT address from 0:0
IRET2_CS dw	 ?
IRET2_FL dw	 ?

IRETX_STR ends

COMMENT|

Register usage:

AH	 =	 interrupt #
EBX	 =	 instruction length (1 or 2)
GS:ESI	 ==>	 caller's stack

|

	 sub	 [ebp].FORW_ESP.ELO,size IRETX_STR ; Make room for IP, CS, and FL twice

; Note that the middle instruction in the three below must subtract
; from SI, not ESI as we're emulating the 64KB segment wrap.

	 sub	 esi,[ebp-@BPBACK].BACK_SS.DTR_BASE ; Convert to offset
	 sub	 si,size IRETX_STR ; Back off from linear address, too
	 add	 esi,[ebp-@BPBACK].BACK_SS.DTR_BASE ; Convert to linear address

	 movzx	 eax,ah 	; Copy interrupt #

	 assume  gs:INTVEC	; Address the RM IDT (not the redirected IDT)
	 mov	 eax,INT00_VEC[eax*(type INT00_VEC)] ; Get the INT's Seg:Off
	 assume  gs:AGROUP	; Restore the truth
	 mov	 AGROUP:[esi].IRET1_IP.EDD,eax ; Save on stack

	 mov	 eax,IRET_VEC	; Get segment:offset of an IRET
	 xchg	 ax,[ebp].FORW_EIP.ELO ; Swap IP
	 add	 ax,bx		; Skip over INT instruction
	 mov	 AGROUP:[esi].IRET2_IP,ax ; Save on stack

	 shr	 eax,16 	; Shift down segment
	 mov	 [ebp-@BPBACK].BACK_CS.DTR_LIM,ax ; Save for later use
	 xchg	 ax,[ebp].FORW_CS ; Swap CS
	 mov	 AGROUP:[esi].IRET2_CS,ax  ; Save on stack

	 mov	 ax,[ebp].FORW_EFL.ELO ; Get FL
	 mov	 AGROUP:[esi].IRET2_FL,ax ; Save on stack
	 or	 ax,mask $TF	; Ensure trap flag set
	 and	 ax,not (mask $IF) ; Ensure IF clear
	 mov	 AGROUP:[esi].IRET1_FL,ax  ; Save on stack

	 jmp	 SWATTER_CLC	; Join common exit code

; INT instruction in protected mode

COMMENT|

Register usage:

AH	 =	 interrupt #
EBX	 =	 instruction length (1 or 2)
GS:ESI	 ==>	 caller's stack

Note we're assuming that this interrupt # is handled by an interrupt,
trap, or 386 task gate.  We do *NOT* handle 286 task gates as yet.

|

; Enter here when Ctl-Tracing
; If VME is enabled and this interrupt is
; not reflected to PM, go back to VM

SWATTER_INTPM0:
	 test	 CPUFET_FLAG,mask $CPUFET_VME ; Is VME supported?
	 jz	 short SWATTER_INTPM ; Jump if not

	 MOVSPR  edx,cr4	; Get CPU extensions register

	 test	 edx,mask $VME	; Izit enabled?
	 jz	 short SWATTER_INTPM ; Jump if not

	 mov	 dx,[ebp-@BPBACK].BACK_TR.DTR_LIM ; Get task register

	 and	 dx,dx		; Izit valid?
	 jz	 short SWATTER_INTPM ; Jump if not

	 push	 eax		; Save for a moment

	 push	 dx		; Pass selector
	 call	 GETBASE	; Return with EAX = selector base

	 mov	 edx,eax	; Copy to safe register

	 pop	 eax		; Restore

	 movzx	 edi,AGROUP:[edx].TSS_IOMAP ; Get I/O map offset

	 and	 edi,edi	; Izit valid?
	 jz	 short SWATTER_INTPM ; Not this time

	 sub	 edi,256/8	; Less offset to SIRB
	 jbe	 short SWATTER_INTPM ; Nothing remains

	 movzx	 ecx,ah 	; Copy interrupt #

	 bt	 AGROUP:[edx+edi].EDD,ecx ; Izit being reflected to PM?
	 jnc	 near ptr SWATTER_INT2 ; Jump if not
SWATTER_INTPM:
	 movzx	 ebx,ah 	; Copy interrupt #

; If it's INT 01h or 03h, we must not trace into it

	 cmp	 ebx,01h	; Izit INT 01h?
	 je	 near ptr SWATTER_CLC ; Jump if so

	 cmp	 ebx,03h	; Izit INT 03h?
	 je	 near ptr SWATTER_CLC ; Jump if so

	 mov	 ecx,[ebp-@BPBACK].BACK_IDT.DTR_BASE ; Get IDTR base
	 mov	 dx,AGROUP:[ecx+ebx*(type IDT_STR)].IDT_OFFHI ; Get high-order word of address
	 shl	 edx,16 	; Shift to high-order
	 mov	 dx,AGROUP:[ecx+ebx*(type IDT_STR)].IDT_OFFLO ; Get low-order ...

	 mov	 bx,AGROUP:[ecx+ebx*(type IDT_STR)].IDT_SELECT ; Get selector

	 push	 bx		; Get selector
	 call	 GETARW 	; Return with AX = access rights word

	 test	 al,mask $DT_DC ; Izit code/data?
	 jnz	 short @F	; Jump if so (not TSS)

	 test	 al,mask $DT_P	; Izit present?
	 jz	 short @F	; Jump if not (who cares?)

	 and	 al,not (mask $DT_DPL) ; Clear DPL bits

	 cmp	 al,CPL0_IDLE3	; Izit an idle 386 TSS?
	 je	 near ptr SWATTER_TRACE_TSS ; Jump if so with BX = TSS selector
@@:
	 push	 bx		; Pass selector
	 call	 GETBASE	; Return with EAX = selector base

	xchg	eax,edx 	; Swap base address and offset
	 add	 edx,eax	; Add base into offset
	mov	cx,@ADDR_PM	; Mark as PM

	 jmp	 SWATTER_SKIP1	; Join common skip code


SWATTER_CTLESC:
	 mov	 eax,CUR_INSTR	; Get linear address of current instruction

	 cmp	 AGROUP:[eax].LO,@OPCOD_INT3 ; Izit an INT 03h?
	 jne	 short SWATTER_ESC ; Jump if not

	 test	 CUR_INSTR_ARW.HI,mask $DTE_B ; Check for D-bit
	 jz	 short @F	; Jump if USE16

	 inc	 [ebp].FORW_EIP ; Increment USE32 EIP

	 jmp	 short SWATTER_ESC ; Join common code

@@:
	 inc	 [ebp].FORW_EIP.ELO ; Increment USE16 IP
SWATTER_ESC:
	 call	 CHECK_BACKLINK ; If we're in TSS mode, ensure back link valid
	 jc	 near ptr SWATTER_REDISP ; Jump if not

; See if the current instruction matches a code breakpoint
; Note that there's a slight chance that we'll miss a breakpoint
; if the current instruction is in BCDATA, we then trace it, but
; an interrupt occurs at that time.  In this case, if the user
; has requested a breakpoint in the interrupt handler, we won't
; have enabled it as yet.

	 call	 CHECK_BCVAL	; Check 'em
	 jnc	 short @F	; Jump if it didn't match

	 or	 LC2_FLAG,mask $LC2_BCT ; Mark as BC trace in effect

	 jmp	 SWATTER_TRACE	; Trace the instruction instead

@@:

; Install any previous breakpoint values

	 call	 INST_BCVAL	; Install 'em

	 and	 [ebp].FORW_EFL.ELO,not (mask $TF) ; Clear the trap flag
	 cli			; Disallow interrupts

	 pop	 RETFL		; Save SWATTER caller's flags
	 or	 RETFL,mask $CF ; Tell the caller to stop single-stepping

	 jmp	 short SWATTER_EXIT ; Join common exit code

SWATTER_XTF:
	 and	 [ebp].FORW_EFL.ELO,not (mask $TF) ; Clear the trap flag
SWATTER_CLC:
	 cli			; Disallow interrupts

	 pop	 RETFL		; Save SWATTER caller's flags
	 and	 RETFL,not (mask $CF) ; Tell the caller to continue single-stepping

; See if the current instruction matches a code breakpoint
; Note that there's a slight chance that we'll miss a breakpoint
; if the current instruction is in BCDATA, we then trace it, but
; an interrupt occurs at that time.  In this case, if the user
; has requested a breakpoint in the interrupt handler, we won't
; have enabled it as yet.

	 test	 LC3_FLAG,@LC3_INTERNAL ; Are we executing an internal command?
	 jnz	 short @F	; Jump if so

	 test	 LC2_FLAG,mask $LC2_BCT ; Izit already in effect (from ESC)?
	 jnz	 short @F	; Jump if so

	 call	 CHECK_BCVAL	; Check 'em
	 jc	 short @F	; Jump if it matches current instruction

; Install any previous breakpoint values

	 call	 INST_BCVAL	; Install 'em
@@:
SWATTER_EXIT:

; Clear exit flag (set by remote SWAT)

	 and	 LC3_FLAG,not @LC3_EXITSWAT ; Turn off Esc

; Clear Ctrl-trace flag

	 and	 LC4_FLAG,not @LC4_CTRACE ; Clear it

; Re-save segment register values into FORW_STR if in VM86 mode

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	 jnz	 short SWATTER_TSSVM ; Jump if so

; Protected mode

	cmp	TSS_CNT,0	; Izit TSS mode?
	jne	short SWATTER_TSSVM ; Yes, handle specially

	 mov	 ax,[ebp-@BPBACK].BACK_DS.DTR_LIM ; Get new DS
	 mov	 [esp].ESP_DS,ax ; Save in caller's registers

	 mov	 ax,[ebp-@BPBACK].BACK_ES.DTR_LIM ; Get new ES
	 mov	 [esp].ESP_ES,ax ; Save in caller's registers

	 mov	 ax,[ebp-@BPBACK].BACK_FS.DTR_LIM ; Get new FS
	 mov	 [esp].ESP_FS,ax ; Save in caller's registers

	 mov	 ax,[ebp-@BPBACK].BACK_GS.DTR_LIM ; Get new GS
	 mov	 [esp].ESP_GS,ax ; Save in caller's registers

	 jmp	 short SWATTER_PM4 ; Join common code

; TSS or VM86 mode

SWATTER_TSSVM:
	 mov	 ax,[ebp-@BPBACK].BACK_CS.DTR_LIM ; Get new CS
	 mov	 [ebp].FORW_CS,ax ; Save in caller's registers

	 mov	 ax,[ebp-@BPBACK].BACK_DS.DTR_LIM ; Get new DS
	 mov	 [ebp].FORW_DS,ax ; Save in caller's registers

	 mov	 ax,[ebp-@BPBACK].BACK_ES.DTR_LIM ; Get new ES
	 mov	 [ebp].FORW_ES,ax ; Save in caller's registers

	 mov	 ax,[ebp-@BPBACK].BACK_FS.DTR_LIM ; Get new FS
	 mov	 [ebp].FORW_FS,ax ; Save in caller's registers

	 mov	 ax,[ebp-@BPBACK].BACK_GS.DTR_LIM ; Get new GS
	 mov	 [ebp].FORW_GS,ax ; Save in caller's registers

	 mov	 ax,[ebp-@BPBACK].BACK_SS.DTR_LIM ; Get new SS
	 mov	 [ebp].FORW_SS,ax ; Save in caller's registers
SWATTER_PM4:
	 test	 LC3_FLAG,@LC3_INTERNAL ; Are we executing an internal command?
	 jnz	 near ptr SWATTER_PM4A ; Jump if so

	 test	 LC2_FLAG,@LC2_MONITOR ; Are we in monitor mode?
	 jnz	 near ptr SWATTER_PM4A ; Jump if so

	 mov	 ax,[ebp-@BPBACK].BACK_CS.DTR_LIM ; Get new CS
	 mov	 OLDCS,ax	; Save for next time
	 mov	 ax,[ebp-@BPBACK].BACK_DS.DTR_LIM ; Get new DS
	 mov	 OLDDS,ax	; Save for next time
	 mov	 ax,[ebp-@BPBACK].BACK_ES.DTR_LIM ; Get new ES
	 mov	 OLDES,ax	; Save for next time
	 mov	 ax,[ebp-@BPBACK].BACK_FS.DTR_LIM ; Get new FS
	 mov	 OLDFS,ax	; Save for next time
	 mov	 ax,[ebp-@BPBACK].BACK_GS.DTR_LIM ; Get new GS
	 mov	 OLDGS,ax	; Save for next time
	 mov	 ax,[ebp-@BPBACK].BACK_SS.DTR_LIM ; Get new SS
	 mov	 OLDSS,ax	; Save for next time

	 mov	 eax,[ebp].FORW_EAX ; Get current EAX
	 mov	 OLDEAX,eax	; Save for next time
	 mov	 eax,[ebp].FORW_EBX ; Get current EBX
	 mov	 OLDEBX,eax	; ...
	 mov	 eax,[ebp].FORW_ECX ; Get current ECX
	 mov	 OLDECX,eax	; ...
	 mov	 eax,[ebp].FORW_EDX ; Get current EDX
	 mov	 OLDEDX,eax	; ...
	 mov	 eax,[ebp].FORW_ESI ; Get current ESI
	 mov	 OLDESI,eax	; ...
	 mov	 eax,[ebp].FORW_EDI ; Get current EDI
	 mov	 OLDEDI,eax	; ...
	 mov	 eax,[ebp].FORW_EBP ; Get current EBP
	 mov	 OLDEBP,eax	; ...
	 mov	 eax,[ebp].FORW_ESP ; Get current ESP
	 mov	 OLDESP,eax	; ...
	 mov	 eax,[ebp].FORW_EIP ; Get current EIP
	 mov	 OLDEIP,eax	; ...
	 mov	 eax,[ebp].FORW_EFL ; Get current EFL
	 mov	 OLDEFL,eax	; ...
	 mov	 eax,cr0	    ; Get current CR0

; If we're device SWAT, and the $VM bit is set, clear the $PE bit
; as we're not really in PM.

	 test	 DEVLOAD,@DEVL_LOAD ; Izit device load?
	 jz	 short @F	; Jump if not

	 test	 [ebp].FORW_EFL,mask $VMHI ; Izit VM 8086 mode?
	 jz	 short @F	; Jump if not

	 and	 eax,not (mask $PE) ; PE=0
@@:
	 mov	 OLDCR0,eax	; ...
	 mov	 eax,cr2	; Get current CR2
	 mov	 OLDCR2,eax	; ...

	 test	 SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	 jz	 short @F	; Not this time

	 mov	 eax,CUR_VM_HANDLE	; Get current Cur_VM_Handle
	 mov	 OLD_CUR_VM_HANDLE,eax	; Save for next time
@@:
SWATTER_PM4A:
	 or	 [ebp].FORW_EFL.EHI,mask $RF ; Ensure resume set in case DRs

; If we're in monitor mode, we've left IRQs and display alone.

	 test	 LC2_FLAG,@LC2_MONITOR ; Are we in monitor mode?
	jnz	near ptr SWATTER_INTERNAL3 ; Jump if so

; If we're executing an internal command, don't restore IRQs and
; don't save the old screen, and don't restore the current screen.

	test	LC4_FLAG,@LC4_ERRLOG ; Displaying error log?
	jnz	short @F	; Jump if so (we need the keyboard)

	 test	 LC3_FLAG,@LC3_INTERNAL ; Are we executing an internal command?
	 jnz	 short SWATTER_INTERNAL3 ; Jump if so
@@:

; Restore the IRQ-specific interrupt handlers

	 cmp	 REENTRY,1	; Check re-entry level
	 jne	 short @F	; Jump if we're re-entering

	 call	 REST_IRQS	; Restore original IRQ-specific interrupt
				; handlers
@@:
	test	LC3_FLAG,@LC3_INTERNAL ; Are we executing an internal command?
	jnz	short SWATTER_INTERNAL3 ; Jump if so

; Save the contents of the current screen to display as last screen

	call	SAVE_LSCR	; Save the current screen in the last screen buffer

; Reset the last screen count so we start at the same point each time

	 mov	 LSCR_CNT,0	; Reset it

	 and	 LCL_FLAG,not @LCL_MSG ; Clear error message flag

; Restore the screen unless asked not to

	 test	 LCL_FLAG,@LCL_SCRN ; Screen restore disabled?
	 jnz	 short @F	; Yes, don't restore it

	 push	 PSCRBUF	; Pass address of screen buffer
	 call	 REST_SCR	; Restore all screen text
@@:

; Switch to original VGA screen if specified

	 test	 ARG_FLAG,@ARG_DVGA ; Izit present?
	 jz	 short @F	; Jump if not

	 call	 DVGASEL0	; Select original VGA screen
@@:
SWATTER_INTERNAL3:

; If switching to monitor mode make the change now

	 btr	 LC4_FLAG,$LC4_MONCMD ; Test and clear monitor flag
	 jnc	 short @F	; Jump if not set

	 or	 LC2_FLAG,@LC2_MONITOR ; Turn on monitor mode
@@:
	 call	 REST_IMR	; Restore IMR to original value

	 REGREST <gs,fs,es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it

	 mov	 esp,ebp	; Strip off structure

	 popad			; Restore

; Decrement the re-entry count

	 REGSAVE <eax,ds>	; Save for a moment

	 SETDATA ds		; Set data selector into DS
	 assume  ds:DGROUP	; Tell the assembler about it

	 REGREST <REG_EAXDS.EDQHI,REG_EAXDS.EDQLO> ; Save to restore later

	 dec	 REENTRY	; Reduce the re-entry counter
	 jnz	 near ptr SWATTER_XSTK2 ; Jump if we're re-entering

; Switch to caller's stack and copy EIP, CS, and EFL unless we're re-entering

	 mov	 eax,[esp].DI_EFL ; Get caller's flags
	 xor	 ax,ax		; In case we're coming from VM86 mode

	 test	 eax,@VMTSS	; Izit VM86 mode?
	 jnz	 short @F	; Jump if so

	 mov	 ax,[esp].DI_CS ; Get caller's RPL into $PL

	cmp	TSS_CNT,0	; Izit TSS mode?
	je	short @F	; Jump if not

	 or	 eax,@VMTSS	; Mark as TSS mode
@@:
	 pop	 REG_RETEIP	; Save to restore later
	 pop	 REG_RETCSF
	 pop	 REG_EIP
	 pop	 REG_CSF
	 pop	 REG_EFL
	 pop	 REG_ESP	; Save to restore later
	 pop	 REG_SSF
	 pop	 REG_ESF
	 pop	 REG_DSF
	 pop	 REG_FSF
	 pop	 REG_GSF

; If in VM86 or TSS mode or a ring transition, restore stack from XPMSTK_FVEC

	 test	 eax,@VMTSSRT	; Izit VM86 or TSS mode or RPL > 0?
	 jz	 short SWATTER_PM5 ; Jump if not

	 lss	 esp,XPMSTK_FVEC ; Switch to caller's stack
	 assume  ss:nothing	; Tell the assembler about it

	 jmp	 short SWATTER_PM5A ; Join common code

SWATTER_PM5:
	 lss	 esp,REG_ESP.EDF ; Switch to caller's stack
	 assume  ss:nothing	; Tell the assembler about it
SWATTER_PM5A:

; If not in VM86 or TSS mode, skip selector register PUSHes

	 test	 eax,@VMTSS	; Izit VM86 or TSS mode?
	 jz	 short SWATTER_PM5B ; Jump if not

	 push	 REG_GSF	; Put onto caller's stack
	 push	 REG_FSF
	 push	 REG_DSF
	 push	 REG_ESF
SWATTER_PM5B:

; If we're in VM86 or TSS mode, or there was a ring transition,
; push the stack selector and offset

	 test	 eax,@VMTSSRT	; Izit VM86 or TSS mode or RPL > 0?
	 jz	 short SWATTER_PM5C ; Jump if not

	 push	 REG_SSF	; Put onto caller's stack
	 push	 REG_ESP
SWATTER_PM5C:
	 push	 REG_EFL	; Put onto caller's stack
	 push	 REG_CSF
	 push	 REG_EIP
	 push	 REG_RETCSF
	 push	 REG_RETEIP

; Restore caller's registers

SWATTER_XSTK2:

; If we're inside Windows and we're exiting via Escape,
; clear the Ctl- and Alt-keys.

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	jz	short @F	; Jump if not

	test	RETFL,mask $CF	; Did we Escape?
	jz	short @F	; Jump if not

;;;;;;; call	CLEAR_KEYS	; Clear 'em
@@:

; Clear DR6 to avoid confusion next time

	 xor	 eax,eax	; A convenient zero
SWATTER_XSTK_DR6:
	 mov	 dr6,eax	; Clear it

; Restore original DR7

	 mov	 eax,SAVE_DR7	; Get original DR7
SWATTER_XSTK_DR7:
	 mov	 dr7,eax	; Restore it

	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Enable the LBR registers

	 push	 RETFL		; Put return flags onto the stack
	 popfd			; ...and into the flags

	 lds	 eax,REG_EAXDS.EDF ; Restore 'em
	 assume  ds:nothing	; Tell the assembler about it

	 RETFD			; Return to 32-bit caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SWATTER  endp			; End SWATTER procedure
	NPPROC	SetErrorLog -- Set Displaying Error Log State
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set displaying error log state

|

	REGSAVE <eax>		; Save register

	mov	al,@DSP_ERRLOG	; Screen state is display error log
	mov	DSP_STATE,al	; Set primary state
	mov	DSP_STAT2,al	; Set secondary "

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SetErrorLog endp		; End SetErrorLog procedure
	NPPROC	CLEAR_KEYS -- Clear Ctl- and Alt-keys In Windows
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear Ctl- and Alt- keys in Windows

|

	cmp	SWATINFO.SWTINF_VER,7 ; Duzit support PM API entry?
	jb	short CLEAR_KEYS_EXIT ; Jump if not

	cmp	SWATINFO.SWTINF_VxD_PMAPI.FOFF,0 ; Izit undefined?
	je	short CLEAR_KEYS_EXIT ; Jump if so

	REGSAVE <eax,ds,es,gs>	; Save registers

	mov	ax,ds		; Copy DGROUP selector
	mov	gs,ax		; Address it
	assume	gs:DGROUP	; Tell the assembler about it

	mov	ax,COMMON.FILE_4GB ; Get all memory selector

	mov	ds,ax		; Address it
	assume	ds:AGROUP	; Tell the assembler about it

	mov	es,ax		; Address it
	assume	ds:AGROUP	; Tell the assembler about it

	push	SWAT_Clear_Keys ; Pass parameter
	call	SWATINFO.SWTINF_VxD_PMAPI ; Request VxD service

	REGREST <gs,es,ds,eax>	; Restore
	assume	ds:DGROUP,es:nothing,gs:nothing ; Tell the assembler about it
CLEAR_KEYS_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLEAR_KEYS endp 		; End CLEAR_KEYS procedure
	 NPPROC  CHECK_BACKLINK -- Ensure Back Link Valid
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure back link valid

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if back link is valid
	 =	 1 otherwise

|

	 REGSAVE <eax>		; Save registers

	cmp	TSS_CNT,0	; Izit TSS mode?
	je	short CHECK_BACKLINK_EXIT ; Jump if not (note CF=0)

	 mov	 ax,[ebp-@BPBACK].BACK_TR.DTR_LIM ; Get task register
	 and	 ax,not (mask $PL) ; Clear the PL bits

	 btr	 ax,$TI 	; Izit in the LDT?
	 jc	 short CHECK_BACKLINK_ERR ; Jump if so

	 push	 ax		; Pass selector
	 call	 GETARW 	; Return with AX = access rights word
	 jc	 short CHECK_BACKLINK_ERR ; Jump if invalid

	 and	 al,not ((mask $DT_DPL) or (mask $DS_BUSY)) ; Clear the DPL and busy bits
	 or	 al,(mask $DT_P) or (mask $DS_386) ; Mark as present and 386

	 cmp	 al,CPL0_IDLE3	; Izit a 386 TSS?
	 je	 short CHECK_BACKLINK_EXIT ; Jump if so (note CF=0)
CHECK_BACKLINK_ERR:
	 mov	 MSGOFF,offset DGROUP:LNKERR ; Save offset of error message
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Mark as invalid
CHECK_BACKLINK_EXIT:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_BACKLINK endp		; End CHECK_BACKLINK procedure
	 NPPROC  SET_STATE -- Set New State
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set new state taking into account overlays

On entry:

AL	 =	 new state

|

	 REGSAVE <eax>		; Save register

	 mov	 ah,al		; Save new state
	 xchg	 al,DSP_STATE	; Save new state, copy old one

	 cmp	 al,@DSP_BC	; Were we displaying BC values?
	 je	 short @F	; Jump if so

	 cmp	 al,@DSP_DRn	; Were we displaying debug registers?
	 jne	 short SET_STATE1 ; Not this time
@@:
	 xchg	 al,DSP_STATE	; Restore old state
	 mov	 DSP_STAT2,al	; Mark as secondary state

	 jmp	 short SET_STATE_EXIT ; Join common exit code

SET_STATE1:
	 mov	 DSP_STAT2,ah	; Save as secondary state, too
SET_STATE_EXIT:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_STATE endp			; End SET_STATE procedure
	 NPPROC  CHECK_JMPRET -- Check for JMP/RET Instructions
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Check for jump/return and ARPL instructions.

On exit:

CF	 =	 1 next instruction is a jump or return
	 =	 0 not

|

	 REGSAVE <eax,ebx>	; Save registers

	 mov	 ebx,CUR_INSTR ; Get linear address of cur instr

; Skip over segment overrides, LOCK, ASP, and OSP

CHECK_JMPRET_SEG:
	 inc	 ebx		; Assume override

	 cmp	 AGROUP:[ebx-1].LO,@OPCOD_CS ; Izit CS: ?
	 je	 short CHECK_JMPRET_SEG ; Jump if so

	 cmp	 AGROUP:[ebx-1].LO,@OPCOD_DS ; Izit DS: ?
	 je	 short CHECK_JMPRET_SEG ; Jump if so

	 cmp	 AGROUP:[ebx-1].LO,@OPCOD_ES ; Izit ES: ?
	 je	 short CHECK_JMPRET_SEG ; Jump if so

	 cmp	 AGROUP:[ebx-1].LO,@OPCOD_FS ; Izit FS: ?
	 je	 short CHECK_JMPRET_SEG ; Jump if so

	 cmp	 AGROUP:[ebx-1].LO,@OPCOD_GS ; Izit GS: ?
	 je	 short CHECK_JMPRET_SEG ; Jump if so

	 cmp	 AGROUP:[ebx-1].LO,@OPCOD_SS ; Izit SS: ?
	 je	 short CHECK_JMPRET_SEG ; Jump if so

	 cmp	 AGROUP:[ebx-1].LO,@OPCOD_LOCK ; Izit LOCK: ?
	 je	 short CHECK_JMPRET_SEG ; Jump if so

	 cmp	 AGROUP:[ebx-1].LO,@OPCOD_ASP ; Izit ASP: ?
	 je	 short CHECK_JMPRET_SEG ; Jump if so

	 cmp	 AGROUP:[ebx-1].LO,@OPCOD_OSP ; Izit OSP: ?
	 je	 short CHECK_JMPRET_SEG ; Jump if so

	 dec	 ebx		; Back off

	 mov	 ax,AGROUP:[ebx] ; Get the first two bytes of the instruction

; Check for change to SS

	 cmp	 al,@OPCOD_POPSS ; Izit POP SS?
	 je	 near ptr CHECK_JMPRET_TRACE ; Yes, trace it instead

	 cmp	 al,8Eh 	; Izit MOV Sreg,xx ?
	 jne	 short CHECK_JMPRET_IRET ; Not this time

	 shr	 ax,8		; Move MOD R/M byte to AL

	 and	 al,mask $REG	; Isolate segment register bits

	 cmp	 al,010b shl $REG ; Izit SS?
	 je	 near ptr CHECK_JMPRET_TRACE ; Yes, trace it instead

	 jmp	 CHECK_JMPRET_BP ; No, breakpoint OK

CHECK_JMPRET_IRET:

; Check for IRETs

	 cmp	 al,@OPCOD_IRET ; Izit an IRET?
	 je	 near ptr CHECK_JMPRET_TRACE ; Yes, trace it instead

; Check for RETs

	 cmp	 al,@OPCOD_RET	; Izit a near return?
	 je	 short CHECK_JMPRET_TRACE ; Yes, trace it instead

	 cmp	 al,@OPCOD_RETF ; Izit a far return?
	 je	 short CHECK_JMPRET_TRACE ; Yes, trace it instead

	 cmp	 al,@OPCOD_RETP ; Izit a near return with pop?
	 je	 short CHECK_JMPRET_TRACE ; Yes, trace it instead

	 cmp	 al,@OPCOD_RETFP ; Izit a far return with pop?
	 je	 short CHECK_JMPRET_TRACE ; Yes, trace it instead

; Check for JCXZ and JECXZ

	 cmp	 al,@OPCOD_JCXZ ; Izit JCXZ
	 je	 short CHECK_JMPRET_TRACE ; Yes, trace it instead

; Check for far jumps

	 cmp	 al,@OPCOD_JMPF ; Izit a far jump?
	 je	 short CHECK_JMPRET_TRACE ; Yes, trace it instead

; Check for short jumps

	 cmp	 al,@OPCOD_JMPS ; Izit a short jump?
	 je	 short CHECK_JMPRET_TRACE ; Yes, trace it instead

; Check for near jumps

	 cmp	 al,@OPCOD_JMPN ; Izit a near jump?
	 je	 short CHECK_JMPRET_TRACE ; Yes, trace it instead

; Check for Group 5 jumps

	 cmp	 al,@OPCOD_GRP5 ; Izit a Group 5 instruction?
	 je	 short CHECK_JMPRET_GRP5 ; Yes, handle separately

; Check for near conditional jumps

	 cmp	 al,@OPCOD_2ND	; Izit a secondary escape code?
	 je	 short CHECK_JMPRET_2ND ; Yes, handle separately

; Check for short conditional jumps

	 cmp	 al,70h 	; Izit a conditional jump?
	 jb	 short CHECK_JMPRET_BP ; No, too small

	 cmp	 al,7Fh 	; Izit a conditional jump?
	 jbe	 short CHECK_JMPRET_TRACE ; Yes, trace it instead

; Check for ARPL in VM86 mode

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	 jz	 short @F	; Jump if not

	 cmp	 al,@OPCOD_ARPL ; Izit ARPL?
	 je	 short CHECK_JMPRET_TRACE ; Yes, trace it instead
@@:
	 jmp	 short CHECK_JMPRET_BP ; Join common breakpoint code

CHECK_JMPRET_GRP5:
	 shr	 ax,8		; Get next instruction byte
	 and	 al,mask $REG	; Isolate the secondary opcode bits

	 cmp	 al,100b shl $REG ; Check for JMP RM16 or JMP RM32
	 je	 short CHECK_JMPRET_TRACE ; Yes, trace it instead

	 cmp	 al,101b shl $REG ; Check for JMP M16:16 or JMP M16:32
	 je	 short CHECK_JMPRET_TRACE ; Yes, trace it instead

	 jmp	 short CHECK_JMPRET_BP ; Set breakpoint

CHECK_JMPRET_2ND:
	 cmp	 ah,80h 	; Izit a conditional jump?
	 jb	 short CHECK_JMPRET_BP ; No, too small

	 cmp	 ah,8Fh 	; Izit a conditional jump?
	 ja	 short CHECK_JMPRET_BP ; No, too large
CHECK_JMPRET_TRACE:
	 stc			; Indicate we should trace the instruction instead

	 jmp	 short CHECK_JMPRET_EXIT ; Join common exit code

CHECK_JMPRET_BP:
	 clc			; Indicate we can set a breakpoint
CHECK_JMPRET_EXIT:
	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_JMPRET endp		; End CHECK_JMPRET procedure
	 NPPROC  GET_LASTILEN -- Get Length of Previous Instruction Line
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get length of previous instruction line

On entry:

EAX	 ==>	 instruction
SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 =	 length of previous instruction line

|

	 REGSAVE <ebx,edx,esi,edi,fs> ; Save registers

	 mov	 edi,eax	; Copy to use later

	 push	 UNABASE	; Save base

	 test	 UNAMODE,@MODE_PHYS ; Izit in physical mode?
	 jz	 short @F	; Jump if not

	 push	 UNACR3 	; Pass new CR3 to use (if non-zero)
	 push	 UNABASE	; Pass base memory to use
	 push	 UNAOFF 	; Pass memory offset to use
	 call	 DISPPHYS	; Setup for physical memory display

	 mov	 UNABASE,eax	; Save as new base address
@@:

; Back off by the maximum instruction length plus some slop, and
; disassemble forwards until we meet or exceed EDI.
; Return EDI less the previous offset.

	 mov	 esi,edi	; Get offset of top instruction

	 mov	 fs,COMMON.FILE_4GB ; FS:ESI ==> caller's CS:EIP
	 assume  fs:AGROUP	; Tell the assembler about it

	 sub	 esi,UNABASE	; Less base address of top instr

	 sub	 esi,60 	; Slop for instruction synchronization
	 jae	 short @F	; Jump if no wrap

	 xor	 esi,esi	; Start at zero
@@:
	 add	 esi,UNABASE	; Plus base address of top instr

	 xor	 ebx,ebx	; Zero instruction base
GET_LASTILEN1:

; Disassemble the instruction at FS:ESI into ES:EDI using EBX as an offset base

	 mov	 edx,esi	; Save current offset
	 push	 edi		; Save for a moment

	 lea	 edi,INSTROUT	; ES:EDI ==> output line
	 call	 DISASSEMBLE	; Disassemble the next instruction
				; returning FS:ESI ==> next instruction
				; ...	    ES:EDI  ==> next output byte
	 pop	 edi		; Restore

	 cmp	 esi,edi	; Back where we started?
	 jb	 short GET_LASTILEN1 ; Not as yet

	 mov	 eax,edi	; Get offset of top instruction
	 sub	 eax,edx	; Subtract previous offset

	 test	 UNAMODE,@MODE_PHYS ; Izit in physical mode?
	 jz	 short @F	; Jump if not

	 call	 DISPVIRT	; Restore virtual mode display
@@:
	 pop	 UNABASE	; Restore

	 REGREST <fs,edi,esi,edx,ebx> ; Restore
	 assume  fs:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_LASTILEN endp		; End GET_LASTILEN procedure
	 NPPROC  GET_LASTPLEN -- Get Length of Previous Instruction Page
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get length of previous instruction page

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 =	 length of previous instruction page

|

GLP_STR  struc

		db 3 dup (?)	; Filler to keep stack dword-aligned
GLP_INSTRNLN	db ?		; INSTRNLN
GLP_FIRST_INSTR dd ?		; FIRST_INSTR
GLP_UNABASE	dd ?		; UNABASE
GLP_EBP 	dd ?		; Caller's EBP (==> FORW_STR)

GLP_STR  ends

	 push	 ebp		; Save for a moment
	 sub	 esp,(type GLP_STR)-(type GLP_EBP) ; Make room for structure on stack
	 mov	 ebp,esp	; Address it

	 REGSAVE <ebx,ecx,edx,esi,edi,fs> ; Save registers

	 push	 UNABASE	; Save base

	 test	 UNAMODE,@MODE_PHYS ; Izit in physical mode?
	 jz	 short @F	; Jump if not

	 push	 UNACR3 	; Pass new CR3 to use (if non-zero)
	 push	 UNABASE	; Pass base memory to use
	 push	 UNAOFF 	; Pass memory offset to use
	 call	 DISPPHYS	; Setup for physical memory display
@@:
	 mov	 al,INSTRNLN	; Get value
	 mov	 [ebp].GLP_INSTRNLN,al ; Save on stack

	 mov	 eax,FIRST_INSTR ; Get value
	 mov	 [ebp].GLP_FIRST_INSTR,eax ; Save on stack

	 mov	 eax,UNABASE	; Get value
	 mov	 [ebp].GLP_UNABASE,eax ; Save on stack

; Make room on the stack for INSTRNLN dwords

	 movzx	 ecx,[ebp].GLP_INSTRNLN ; Get # lines in instruction window
	 shl	 ecx,2-0	; Convert from dwords to bytes
	 sub	 esp,ecx	; Make room
	 shr	 ecx,2-0	; Convert from bytes to dwords

; Back off by the maximum instruction length plus some slop, and
; disassemble forwards until we meet or exceed FIRST_INSTR.
; Return FIRST_INSTR less the previous offset.

	 mov	 esi,[ebp].GLP_FIRST_INSTR ; Get linear address of top instr

	 mov	 fs,COMMON.FILE_4GB ; Get our all memory selector
	 assume  fs:AGROUP	; Tell the assembler about it

	 sub	 esi,[ebp].GLP_UNABASE ; Less base address of top instr

	 sub	 esi,200	; Slop for instruction synchronization
	 jae	 short @F	; Jump if no wrap

	 xor	 esi,esi	; Start at zero
@@:
	 add	 esi,[ebp].GLP_UNABASE ; Plus base address of top instr
	 xor	 ebx,ebx	; Zero instruction base
	 xor	 edx,edx	; Zero the index

; Disassemble the instruction at FS:ESI into ES:EDI using EBX as an offset base

GET_LASTPLEN3:
	 mov	 eax,esi	; Copy linear address for later use
	 mov	 [esp+edx*4],eax ; Save current offset
	 lea	 edi,INSTROUT	; ES:EDI ==> output line
	 push	 ebp		; Save to address FORW_STR
	 mov	 ebp,[ebp].GLP_EBP ; SS:EBP ==> FORW_STR
	 call	 DISASSEMBLE	; Disassemble the next instruction
				; returning FS:ESI ==> next instruction
				; ...	    ES:EDI ==> next output byte
	 pop	 ebp		; Restore
	 inc	 edx		; Skip to next index

	 cmp	 ecx,1		; Izit the last line?
	 je	 short GET_LASTPLEN4 ; Jump if so

; If this line is also a label, duplicate the offset
; on the stack structure of offsets

	 mov	 [esp+edx*4],eax ; Save current offset
	 call	 SYMHASH_SRCH	; Look for EAX in symbol hash table
				; Return with DGROUP:EAX ==> symbol record
	 jc	 short GET_LASTPLEN4 ; Jump if not found

	 dec	 ecx		; Account for label line display
	 inc	 edx		; Skip to next index
GET_LASTPLEN4:
	 loop	 GET_LASTPLEN3	; Jump if more instructions to disassemble

	 cmp	 esi,[ebp].GLP_FIRST_INSTR ; Back where we started?
	 jae	 short GET_LASTPLEN_EXIT ; Yes

	 dec	 edx		; Back up one dword

; Move stack structure down one dword

	 mov	 edi,esp	; ES:EDI ==> destin

	 push	 esi		; Save for a moment

	 lea	 esi,[edi+4]	; SS:ESI ==> source
	 movzx	 ecx,[ebp].GLP_INSTRNLN ; Get # lines in instruction window
	 dec	 ecx		; Less one we're overwriting
S32  rep movs	 <es:[edi].EDD,ss:[esi].EDD> ; Move it down

	 pop	 esi		; Restore

	 mov	 ecx,1		; Set for above loop

; If this line is also a label, duplicate the offset
; on the stack structure of offsets

	 mov	 [esp+edx*4],eax ; Save current offset
	 call	 SYMHASH_SRCH	; Look for EAX in symbol hash table
				; Return with DGROUP:EAX ==> symbol record
	 jc	 short GET_LASTPLEN3 ; Jump if not found

; Move stack structure down one dword

	 mov	 edi,esp	; ES:EDI ==> destin

	 push	 esi		; Save for a moment

	 lea	 esi,[edi+4]	; SS:ESI ==> source
	 movzx	 ecx,[ebp].GLP_INSTRNLN ; Get # lines in instruction window
	 dec	 ecx		; Less one we're overwriting
S32  rep movs	 <es:[edi].EDD,ss:[esi].EDD> ; Move it down

	 pop	 esi		; Restore

	 mov	 ecx,1		; Set for above loop

	 jmp	 short GET_LASTPLEN3 ; Go around again

GET_LASTPLEN_EXIT:
	 mov	 eax,[ebp].GLP_FIRST_INSTR ; Get linear address of top instr
	 sub	 eax,[esp]	; Subtract previous offset

; Strip off the stack INSTRNLN dwords

	 movzx	 ecx,[ebp].GLP_INSTRNLN ; Get # lines in instruction window
	 shl	 ecx,2-0	; Convert from dwords to bytes
	 add	 esp,ecx	; Make room

	 test	 UNAMODE,@MODE_PHYS ; Izit in physical mode?
	 jz	 short @F	; Jump if not

	 call	 DISPVIRT	; Restore virtual mode display
@@:
	 pop	 UNABASE	; Restore base

	 REGREST <fs,edi,esi,edx,ecx,ebx> ; Restore
	 assume  fs:nothing	; Tell the assembler about it

	 add	 esp,(type GLP_STR)-(type GLP_EBP) ; Strip structure from the stack
	 pop	 ebp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_LASTPLEN endp		; End GET_LASTPLEN procedure
	 NPPROC  GET_CURINSTR -- Get Current Instruction Offset
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get current instruction offset

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 ==>	 current instruction

|

	 mov	 eax,[ebp].FORW_EIP ; EAX = caller's EIP
	 add	 eax,[ebp-@BPBACK].BACK_CS.DTR_BASE ; Plus caller's CS base

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_CURINSTR endp		; End GET_CURINSTR procedure
	 NPPROC  SET_NEXTINSTR -- Set NEXT_INSTR approximately
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Set NEXT_INSTR only for certain instructions:

PUSHF
PUSHFD

On entry:

SS:EBP	 ==>	 FORW_STR
CUR_INSTR =	 Linear address of current instruction

On exit:

NEXT_INSTR =	 Linear address of next instruction if current instruction
		 is recognizable.

|

	 REGSAVE <eax,ebx>	; Save

	 mov	 ebx,CUR_INSTR	; Address current instruction
	 mov	 ax,AGROUP:[ebx].ELO ; Get first 2 bytes

	 inc	 ebx		; Assume 1 byte opcode

	 cmp	 al,@OPCOD_PUSHF ; Izit PUSHF?
	 je	 short SET_NEXTI_EXIT0 ; Jump if so

	 inc	 ebx		; Assume 2 byte opcode

	 cmp	 ax,@OPCOD_PUSHFD ; Izit PUSHFD?
	 jne	 short SET_NEXTI_EXIT ; Jump if not
SET_NEXTI_EXIT0:
	 mov	 NEXT_INSTR,ebx ; Save next instruction's address
SET_NEXTI_EXIT:
	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_NEXTINSTR endp		; End SET_NEXTINSTR procedure
	 NPPROC  SET_UNAVARS -- Set UNA* variables for unassembly
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set UNA* variables.  Called by SET_CURINSTR.

On entry:

SS:EBP	 ==>	 FORW_STR
CUR_INSTR =	 Linear address of current instruction

|

	 REGSAVE <eax,ebx>	; Save registers

	 mov	 ax,[ebp-@BPBACK].BACK_CS.DTR_LIM ; Get caller's CS
	 mov	 UNASEL,ax	; Save as segment of top instr

	 mov	 eax,[ebp-@BPBACK].BACK_CS.DTR_BASE ; Get caller's CS base
	 mov	 UNABASE,eax	; Save as base address of top instr

	 mov	 eax,FIRST_INSTR ; Get linear address of top instr
	 sub	 eax,UNABASE	; Less base ...
	 mov	 UNAOFF,eax	; Save as offset of top instr

COMMENT|

If the code selector from the last time is different from now,
set stack width display to words if VM 8086 mode or B-bit in SS clear,
and to dwords otherwise

In particular,

* If we're in a different mode than last time, set the stack width.
* Otherwise, if we're now in PM and the code selector from last time
  is different from now, set the stack width.

|

	 mov	 bx,[ebp].FORW_SS ; Get current stack segment/selector
	 xchg	 bx,OLDSS_STK	; Swap with previous ...

; * If we're in a different mode than last time, set the stack width.

	 mov	 ax,@MODE_VM	; Assume we're now in VM 8086 mode

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Izit now VM 8086 mode?
	 jnz	 short @F	; Jump if so

	 xor	 ax,ax		; Mark as not
@@:
	 xor	 ax,UNAMODE	; Merge with previous mode

	 test	 ax,@MODE_VM	; Izit different?
	 jnz	 short SET_CURINSTR_STK ; Yes, set stack width

; * Otherwise, if we're now in PM and the stack selector from last time
;   is different from now, set the stack width.

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	 jnz	 short SET_CURINSTR_XSTK ; Yes, don't set stack width

	 cmp	 bx,[ebp].FORW_SS ; Izit the same?
	 je	 short SET_CURINSTR_XSTK ; Yes, don't set stack width
SET_CURINSTR_STK:
	 and	 LCL_FLAG,not @LCL_STKD ; Mark as displaying in words

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	 jnz	 short SET_CURINSTR_XSTK ; Yes, leave stack width at words

	 push	 [ebp].FORW_SS	; Pass selector as argument
	 call	 GETARW 	; Return with AX = access rights word

	 test	 ah,mask $DTE_B ; Check for B-bit
	 jz	 short SET_CURINSTR_XSTK ; It's clear, so leave stack width at words

	 or	 LCL_FLAG,@LCL_STKD ; Mark as displaying in dwords
SET_CURINSTR_XSTK:

; Set Virtual or Protected Mode flag

	 mov	 ax,gs		; Assume VM 8086 mode
	 or	 UNAMODE,@MODE_VM ; Assume VM 8086 mode

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	 jnz	 short @F	; Yes

	 and	 UNAMODE,not @MODE_VM ; It's PM
	 mov	 ax,UNASEL	; Get actual selector
@@:

; Set USE16 or USE32 flag

	 push	 ax		; Pass selector as argument
	 call	 GETARW 	; Return with AX = access rights word

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	 jz	 short @F	; No, leave it alone

	 and	 ah,not (mask $DTE_B)	; VM 8086 mode is always USE16
@@:
	 mov	 CUR_INSTR_ARW,ax ; Save for later use
	 and	 UNAMODE,not @MODE_USE32 ; Assume it's USE16
	 mov	 UNAMASK,0000FFFFh ; ...

	 test	 ah,mask $DTE_B ; Check for B-bit
	 jz	 short @F	; Jump if USE16

	 or	 UNAMODE,@MODE_USE32 ; Mark as USE32
	 mov	 UNAMASK,0FFFFFFFFh ; ...
@@:
	 and	 UNAMODE,not @MODE_PHYS ; Mark as no longer PHYSICAL

	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_UNAVARS endp		; End SET_UNAVARS procedure
	 NPPROC  SET_CURINSTR -- Set Current Instruction Disassembly Values
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set current instruction disassembly values.

On entry:

SS:EBP	 ==>	 FORW_STR

|

	 REGSAVE <eax>		; Save registers

; If the current instruction is between FIRST_INSTR and LAST_INSTR
; inclusive, begin the display at FIRST_INSTR

	 call	 GET_CURINSTR	; Get linear address of current instruction
	 mov	 CUR_INSTR,eax	; Save for later use

	 cmp	 eax,FIRST_INSTR ; Check against first one
	 jb	 short SET_CURINSTR1 ; Jump if too small

	 cmp	 eax,LAST_INSTR ; Check against last one
	 jbe	 short SET_CURINSTR2 ; Jump if within range
SET_CURINSTR1:
	 mov	 FIRST_INSTR,eax ; Save as linear address of top instr
SET_CURINSTR2:
	 call	 SET_UNAVARS	; Set CUR_INSTR_ARW and remaining UNA* variables

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_CURINSTR endp		; End SET_CURINSTR procedure
	NPPROC	SAVE_LSCR -- Save As Last Screen
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Save the current screen in the last screen buffer.

|

	REGSAVE <eax,ebx>	; Save registers

	mov	ebx,PLSTBUF_IND ; Get last screen buffer table index
	inc	ebx		; Skip to next last screen buffer

	cmp	ebx,NLSTBUF	; Izit out of range?
	jb	short @F	; Jump if not

	xor	ebx,ebx 	; Start again at zero
@@:
	mov	PLSTBUF_IND,ebx ; Save for next time

	mov	eax,PPLSTBUF_TAB ; Get ptr to last screen buffer table
	push	DGROUP:[eax+ebx*(type PLSTBUF_STR)].PLSTBUF ; Pass address of last screen buffer
	PUSHD	0		; Use VIDBASE
	call	SAVE_SCR	; Save all screen text

	REGREST <ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_LSCR endp			; End SAVE_LSCR procedure
	 NPPROC  DISP_LSCR -- Display Last Screens
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display last screens

|

	 REGSAVE <eax,ebx,ecx,edx,edi> ; Save registers

; Setup window descriptor for message display

	 xor	 edx,edx	; Zero high-order word for division
	 mov	 eax,CMDOFF	; Get offset of command line
	 mov	 ecx,2*@NCOLS	; Get # char/attrs per line
	 div	 ecx		; Divide to get row # of mode line
	 mov	 W_TMP.SROW,ax	; Start on mode line
	 mov	 W_TMP.SCOL,(@NCOLS-MSG_LASTLEN)/2-9 ; Centered
	 mov	 W_TMP.NROW,1	; # rows on message line
	 mov	 W_TMP.NCOL,MSG_LASTLEN ; # cols ...

; PLSTBUF_IND contains the index to "Last screen-000".
; LSCR_CNT contains the # screens back we should display when requested
; to do so.  If that number is zero, we display -000, if it's one,
; we display -001, etc.

	 mov	 ebx,PLSTBUF_IND ; Get last screen buffer table index
	 mov	 eax,LSCR_CNT	; Initialize last screen counter

	 sub	 ebx,eax	; Back off that many screens
	 jnc	 short @F	; Jump if it's within range

	 add	 ebx,NLSTBUF	; Modulo NLSTBUF
@@:
	 mov	 ecx,PPLSTBUF_TAB ; Get ptr to last screen buffer table
	 push	 DGROUP:[ecx+ebx*(type PLSTBUF_STR)].PLSTBUF ; Pass address of last screen buffer
	 call	 REST_SCR	; Restore the original screen

; Display "Last screen-nnn" text from LSCR_CNT

;;;;;;;; mov	 eax,LSCR_CNT	; Initialize last screen counter (already in AX)
	 mov	 MSG_LAST0.ELO,'00' ; Ensure leading digits filled in
	 lea	 edi,MSG_LAST1	; ES:EDI ==> units digit

	 push	 @DEC_RIGHT	; Mark as right-justified
	 call	 DD2DEC 	; Convert EAX to decimal at ES:EDI

	 mov	 al,ERRATTR	; Get message line attribute
	 push	 ax		; Pass as attribute to smear
	 push	 offset DGROUP:MSG_LAST ; Pass address of message line
	 push	 offset DGROUP:W_TMP ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

	 REGREST <edi,edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_LSCR endp			; End DISP_LSCR procedure
	NPPROC	SWATTER_DISP -- Display The Screen
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display the screen

|

	REGSAVE <eax,ecx>	; Save registers

	movzx	ecx,DSP_STATE	; Get primary state
	movzx	eax,DSP_STAT2	; Get secondary state
	call	DISP_ACT[eax*(type DISP_ACT)] ; Display the corresponding screen

	cmp	al,cl		; Primary and secondary the same?
	je	short @F	; Yes

	call	DISP_ACT[ecx*(type DISP_ACT)] ; Display the corresponding screen
@@:
	call	DISP_MSGLINE	; Display the message line

	REGREST <ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SWATTER_DISP endp		; End SWATTER_DISP procedure

PROG	 ends			; End PROG segment

	 MEND	 SWATSTART	; End SWAT module
