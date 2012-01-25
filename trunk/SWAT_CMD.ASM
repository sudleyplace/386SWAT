;' $Header:   P:/PVCS/386SWAT/SWAT_CMD.ASV   1.51   20 Aug 1998 23:05:44   BOB  $
	 title	 SWAT_CMD -- 386SWAT Command Line Functions
	 page	 58,122
	 name	 SWAT_CMD

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
	 include ASCII.INC
	 include PTR.INC
	 include 386.INC
	 include KEYCODE.INC
	 include CPUFLAGS.INC
	 include BITFLAGS.INC
	 include INTVEC.INC
	 include ALLMEM.INC
	 include MAC.INC
	 include MAXDEV.INC
	include DEBUGSYS.INC

	 include SWAT_COM.INC
	 include SWAT_CMD.INC
	 include SWAT_DRV.INC
	 include SWAT_MOD.INC
	 include SWAT_SEG.INC
	 include SWAT_SYM.INC
	 include SWAT_WKD.INC

	include VMM.INC
.list

DATA16	 segment use32 dword public 'data' ; Start DATA16 segment
	 assume  ds:DGROUP

	public	@SWAT_CMD_DATA16
@SWAT_CMD_DATA16 label byte	; Mark module start in .MAP file

	 extrn	 AR2_FLAG:word
	 include SWAT_AR2.INC

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	LC3_FLAG:dword
	include SWAT_LC3.INC

	extrn	LC4_FLAG:dword
	include SWAT_LC4.INC

	 extrn	 LaDEVINTCOM:dword
	 extrn	 LaRM_IDT:dword

	 extrn	 CURTYPE:word
	 extrn	 CURPOSN:word

	 extrn	 VIDTYPE:dword

	 extrn	 SWATDATA:dword

	 extrn	 LaLSTLST:dword

	 extrn	 PCUR_VM_HANDLE:fword
	extrn	RGRSEG2:word

	public	CMD_LINE_OFF
CMD_LINE_OFF dd ?		; Offset of next char in command line

	 public  CMD_LINE_LEN,CMD_LINE,CMD_LINE_TERM
CMD_LINE_LEN dd  size CMD_LINE	; Length of ... excluding terminator
CMD_LINE db	 @NCOLS dup (' ') ; The command line
CMD_LINE_TERM db 0		; Terminator

	 public  DIVINT00_FVEC
	 align	 4
DIVINT00_FVEC label fword	; ...		new ...
	 dd	 offset PGROUP:DIV_INT00
	 dw	 ?

	 public  CMD_FLAG
CMD_FLAG dw	 0		; Command flags

DATA16	 ends			; End DATA16 segment


RCODE	segment use16 para public 'rcode' ; Start RCODE segment
	assume	cs:RGROUP,ds:RGROUP

	extrn	WKDDOT_TAB:tbyte
	extrn	WKD_AGRSEL:word

	extrn	PDTE_CS:word
	extrn	PDTE_DS:word
	extrn	PDTE_ES:word
	extrn	PDTE_FS:word
	extrn	PDTE_GS:word
	extrn	PDTE_SS:word

RCODE	ends			; End RCODE segment


DATA	 segment use32 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	public	@SWAT_CMD_DATA
@SWAT_CMD_DATA	label byte	; Mark module start in .MAP file

	 extrn	 MEMSEL:word
	 extrn	 MEMOFF:dword
	 extrn	 MEMBASE:dword
	 extrn	 MEMMODE:word
	 extrn	 MEMMASK:dword

	 extrn	 UNASEL:word
	 extrn	 UNAOFF:dword
	 extrn	 UNABASE:dword
	 extrn	 UNAMODE:word

	 extrn	 EA1MODE:word
	 extrn	 EA1SEL:word
	 extrn	 EA1BASE:dword
	 extrn	 EA1OFF:dword

	 extrn	 EA2MODE:word
	 extrn	 EA2SEL:word
	 extrn	 EA2BASE:dword
	 extrn	 EA2OFF:dword

	 extrn	 STACK_eSP:dword
	 extrn	 CUR_INSTR_ARW:word

	extrn	LBRFREIP:dword
	extrn	LBRTOEIP:dword
	extrn	LEXFREIP:dword
	extrn	LEXTOEIP:dword
	extrn	ERRLOG_CLINE:dword

	extrn	SAVE_DR6:dword
	extrn	SAVE_DR7:dword
	extrn	ERRCODE:dword
	extrn	FORWSTR_FVEC:fword

	public	CMD_CHAR_FVEC
CMD_CHAR_FVEC df ?		; Save area for stack when calling Win386

	public	UNR_FLAG
	include SWAT_UNR.INC
UNR_FLAG dw	0		; Unreal flags

	public	SaveRegs
SaveRegs SaveRegs_Struc <>	; Save register struc for Win386 commands

	 public  OLDDIVINT00_FVEC,OLDDIVINT00_ARB
	 public  DIVINT00_ARB
OLDDIVINT00_FVEC df ?		; Save area for old INT 00h handler

OLDDIVINT00_ARB db  ?		; ...		old INT 00h access rights byte
DIVINT00_ARB db  CPL0_INTR3 or CPL3 ; ...	new ...

; Note that the following two variables *MUST* be consecutive
; as the call to LCL_SYMSRCH assumes that they are

	 public  CMD_TOKL,CMD_TOKN,CMD_TOKZ
CMD_TOKL db	 ?		; Length in bytes of following token
CMD_TOKN db	 @NCOLS dup (' ') ; Save area for a token
CMD_TOKZ dw	 0		; Terminator (double-zero)

	 public  CMDHIGH
	 align	 4
CMDHIGH  dd	 0		; Command line high water mark length

	 public  U32_NUMBERS_LO
U32_NUMBERS_LO db '0123456789abcdef' ; Conversion table for HEX2DD

	 public  MSGOFF
MSGOFF	 dd	 ?		; Offset of message

	 public  SYNTERR,OVFERR,REGERR,CMDERR,BDREGERR,BCREGERR
	 public  RSERR,RRERR,ROMERR,X486ERR,NDPERR,VALERR,STRERR
	 public  SELERR,SYMBERR,NOFBROWS,NOXBDA,SIGERR,PAGERR,NOEADDR
	public	INITERR,LNKERR,VMERR,VMCRSERR,VMRETERR,XAVLERR
	public	NOWINERR,WINERR,VNFERR,FULLERR
SYNTERR  db	 'Syntax Error',0
OVFERR	 db	 'Value Out Of Range',0
REGERR	 db	 'Invalid Register',0
CMDERR	 db	 'Unknown Command',0
BDREGERR db	 'No Available Debug Register',0
BCREGERR db	 'No Available Code Breakpoints',0
RSERR	 db	 'Registers Already Saved',0
RRERR	 db	 'No Registers Saved',0
ROMERR	 db	 'Cannot Write Into ROM',0
X486ERR  db	 'Processor Not A 486',0
NDPERR	 db	 'No NDP Present',0
VALERR	 db	 'Invalid Value',0
STRERR	 db	 'Invalid Mask',0
SELERR	 db	 'Invalid Selector',0
SYMBERR  db	 'No Symbols',0
NOFBROWS db	 'No File In Browser',0
NOXBDA	 db	 'No XBDA',0
SIGERR	 db	 'EIP too small for SIGINT',0
PAGERR	 db	 'Paging Not Enabled',0
NOEADDR  db	 'No Effective Address',0
INITERR  db	 'Feature Not Initialized',0
LNKERR	 db	 'Invalid Back Link -- Use R TR= to set',0
VMERR	 db	 'No valid Windows VM handle',0
VMCRSERR db	 'Windows VM Client Register Struc invalid',0
VMRETERR db	 'No valid RETF address found on Windows VM stack',0
XAVLERR  db	 'Feature Not Available',0
NOWINERR db	'Not from within Windows',0
WINERR	 db	'Only from within Windows',0
VNFERR	 db	'Value Not Found',0
FULLERR  db	'Table Full',0

	 public  TERMERR
TERMERR  db	 '<Command line terminator clobbered; last BX=',0

DATA	 ends			; End DATA segment


KEYSEG	segment use32 word public 'data' ; Start KEYSEG segment
	assume	ds:DGROUP

	public	@SWAT_CMD_KEYSEG
@SWAT_CMD_KEYSEG label byte	; Mark module start in .MAP file

	public	CMD_KEY
CMD_KEY label	word		; First word in the table

KEYSEG	ends			; End KEYSEG segment


ACTSEG	segment use32 dword public 'data' ; Start ACTSEG segment
	assume	ds:DGROUP

	public	@SWAT_CMD_ACTSEG
@SWAT_CMD_ACTSEG label byte	; Mark module start in .MAP file

	public	CMD_ACT
CMD_ACT label	dword		; First action in the table

ACTSEG	ends			; End ACTSEG segment


	KSTMAC	CR	, CMD_CR	 ; CR	     = Process
	KSTMAC	SHF_CR	, CMD_CR	 ; Shift-CR  = Process
	KSTMAC	PADENTER, CMD_CR	 ; Padenter  = Process
	KSTMAC	LEFT	, CMD_LFT	 ; Left      = Move left
	KSTMAC	XLEFT	, CMD_LFT	 ; X-Left    = Move left
	KSTMAC	RIGHT	, CMD_RHT	 ; Right     = Move right
	KSTMAC	XRIGHT	, CMD_RHT	 ; X-Right   = Move right
	KSTMAC	HOME	, CMD_HOM	 ; Home      = Move to col 0
	KSTMAC	XHOME	, CMD_HOM	 ; X-Home    = Move to col 0
	KSTMAC	END	, CMD_END	 ; End	     = Move to end-of-the-line
	KSTMAC	XEND	, CMD_END	 ; X-End     = Move to end-of-the-line
	KSTMAC	INS	, CMD_INS	 ; Ins	     = Insert
	KSTMAC	XINS	, CMD_INS	 ; X-Ins     = Insert
	KSTMAC	DEL	, CMD_DEL	 ; Del	     = Delete
	KSTMAC	XDEL	, CMD_DEL	 ; X-Del     = Delete
	KSTMAC	BS	, CMD_BS	 ; BS	     = Erase left
	KSTMAC	CTL_BS	, CMD_CHAR_CLEAR ; X-BS      = Erase entire line


KEYSEG	segment use32 word public 'data' ; Start KEYSEG segment
	assume	ds:DGROUP

CMD_NKEY equ	($-CMD_KEY)/(type CMD_KEY) ; # valid special keys

KEYSEG	ends			; End KEYSEG segment


SEG_TAB  segment use32 dword public 'data' ; Start SEG_TAB segment
	 assume  ds:DGROUP

	public	@SWAT_CMD_SEG_TAB@CMD
@SWAT_CMD_SEG_TAB@CMD label byte ; Mark module start in .MAP file

	 public  CMDARG_TAB
CMDARG_TAB label dword

SEG_TAB  ends			; End SEG_TAB segment


SEG_LEN  segment use32 dword public 'data' ; Start SEG_LEN segment
	 assume  ds:DGROUP

	public	@SWAT_CMD_SEG_LEN@CMD
@SWAT_CMD_SEG_LEN@CMD label byte ; Mark module start in .MAP file

	 public  CMDARG_LEN
CMDARG_LEN label dword

SEG_LEN  ends			; End SEG_LEN segment


SEG_ACT  segment use32 dword public 'data' ; Start SEG_ACT segment
	 assume  ds:DGROUP

	public	@SWAT_CMD_SEG_ACT@CMD
@SWAT_CMD_SEG_ACT@CMD label byte ; Mark module start in .MAP file

	 public  CMDARG_ACT
CMDARG_ACT label dword

SEG_ACT  ends			; End SEG_ACT segment


; All keywords in this table *MUST* be in lowercase

	 CMDARG_MAC 'appkey',   CMD_APPKEY

	 CMDARG_MAC 'bc',       CMD_BCSET
	 CMDARG_MAC 'bd',       CMD_BD
	 CMDARG_MAC 'bd0',      CMD_BD0
	 CMDARG_MAC 'bd1',      CMD_BD1
	 CMDARG_MAC 'bd2',      CMD_BD2
	 CMDARG_MAC 'bd3',      CMD_BD3
	 CMDARG_MAC 'btf',      CMD_BTF

	 CMDARG_MAC 'cd',       CMD_CHDIR
	 CMDARG_MAC 'chat',     CMD_CHAT
	 CMDARG_MAC 'chdir',    CMD_CHDIR

	 CMDARG_MAC 'd',        CMD_DATA
	 CMDARG_MAC 'db',       CMD_DATAB
	 CMDARG_MAC 'dd',       CMD_DATAD
	 CMDARG_MAC 'dg',       CMD_DATAG
	 CMDARG_MAC 'di',       CMD_DATAI
	 CMDARG_MAC 'dt',       CMD_DATAT
	 CMDARG_MAC 'dte',      CMD_DTE
	 CMDARG_MAC 'dt2',      CMD_DATAT2
	 CMDARG_MAC 'dt3',      CMD_DATAT3
	 CMDARG_MAC 'dv',       CMD_DATAV
	 CMDARG_MAC 'dw',       CMD_DATAW
	 CMDARG_MAC 'dvga1',    CMD_DVGA1

	 CMDARG_MAC 'e',        CMD_ENTER
	 CMDARG_MAC 'exit',     CMD_EXIT

	 CMDARG_MAC 'f',        CMD_FILL
	 CMDARG_MAC 'fs',       CMD_FLUSHTAB

	 CMDARG_MAC 'g',        CMD_GOTO
	 CMDARG_MAC 'gm',       CMD_GOMONITOR

	 CMDARG_MAC 'h',        CMD_HEX

	 CMDARG_MAC 'i',        CMD_INPUTB
	 CMDARG_MAC 'ib',       CMD_INPUTB
	 CMDARG_MAC 'iw',       CMD_INPUTW
	 CMDARG_MAC 'id',       CMD_INPUTD
	 CMDARG_MAC 'imr',      CMD_IMR
	 CMDARG_MAC 'insert',   CMD_INSERT
	 CMDARG_MAC 'ipf',      CMD_IPF
	 CMDARG_MAC 'irr',      CMD_IRR
	 CMDARG_MAC 'isr',      CMD_ISR

	 CMDARG_MAC 'lbr',      CMD_LBR
	 CMDARG_MAC 'lf',       CMD_LOADFIL
	 CMDARG_MAC 'li',       CMD_GOLINE
	 CMDARG_MAC 'line',     CMD_GOLINE
	 CMDARG_MAC 'ls',       CMD_LOADSYM

	 CMDARG_MAC 'm',        CMD_MOVE
	 CMDARG_MAC 'macbase',  CMD_MACBASE
	 CMDARG_MAC 'mdb',      CMD_MDB
	 CMDARG_MAC 'mode',     CMD_MODE

	 CMDARG_MAC 'o',        CMD_OUTPUTB
	 CMDARG_MAC 'ob',       CMD_OUTPUTB
	 CMDARG_MAC 'ow',       CMD_OUTPUTW
	 CMDARG_MAC 'od',       CMD_OUTPUTD

	 CMDARG_MAC 'path',     CMD_PATH
	 CMDARG_MAC 'ps',       CMD_PROXSRCH
	 CMDARG_MAC 'pte',      CMD_PTE

	 CMDARG_MAC 'qs',       CMD_QUERYSYMB

	 CMDARG_MAC 'r',        CMD_REG
	 CMDARG_MAC 'rc',       CMD_REGCLEAR
	 CMDARG_MAC 'remdbg',   CMD_REMDBG
	 CMDARG_MAC 'rr',       CMD_REGREST
	 CMDARG_MAC 'rs',       CMD_REGSAVE

	 CMDARG_MAC 's',        CMD_SRCH
	 CMDARG_MAC 's1',       CMD_SRC1
	 CMDARG_MAC 'sb',       CMD_SBMODE
	 CMDARG_MAC 'setcom',   CMD_SETCOM
	 CMDARG_MAC 'sgh',      CMD_SGH
	 CMDARG_MAC 'sigint',   CMD_SIGINT
	 CMDARG_MAC 'spte',     CMD_SPTE

	 CMDARG_MAC 'tdb',      CMD_TDB
	 CMDARG_MAC 'togint',   CMD_TOGINT
	 CMDARG_MAC 'ts',       CMD_TRANSYM

	 CMDARG_MAC 'u',        CMD_UNASM
	 CMDARG_MAC 'u16',      CMD_UNASM16
	 CMDARG_MAC 'u32',      CMD_UNASM32
	 CMDARG_MAC 'unreal',   CMD_UNREAL,     LCL

	 CMDARG_MAC 'vmscount', CMD_VMSCOUNT
	 CMDARG_MAC 'vmsint',   CMD_VMSINT

	 CMDARG_MAC 'w',        CMD_WKD
	 CMDARG_MAC 'wkd',      CMD_WKD


SEG_TAB  segment use32 dword public 'data' ; Start SEG_TAB segment
	 assume  ds:DGROUP

	 public  NCMDARGS
NCMDARGS equ	 ($-CMDARG_TAB)/(type CMDARG_TAB) ; Its length

SEG_TAB  ends			; End SEG_TAB segment


SEG_TAB  segment use32 dword public 'data' ; Start SEG_TAB segment
	 assume  ds:DGROUP

	public	@SWAT_CMD_SEG_TAB@DOT
@SWAT_CMD_SEG_TAB@DOT label byte ; Mark module start in .MAP file

	 public  DOTCMD_TAB
DOTCMD_TAB label dword

SEG_TAB  ends			; End SEG_TAB segment


SEG_LEN  segment use32 dword public 'data' ; Start SEG_LEN segment
	 assume  ds:DGROUP

	public	@SWAT_CMD_SEG_LEN@DOT
@SWAT_CMD_SEG_LEN@DOT label byte ; Mark module start in .MAP file

	 public  DOTCMD_LEN
DOTCMD_LEN label dword

SEG_LEN  ends			; End SEG_LEN segment


SEG_ACT  segment use32 dword public 'data' ; Start SEG_ACT segment
	 assume  ds:DGROUP

	public	@SWAT_CMD_SEG_ACT@DOT
@SWAT_CMD_SEG_ACT@DOT label byte ; Mark module start in .MAP file

	 public  DOTCMD_ACT
DOTCMD_ACT label dword

SEG_ACT  ends			; End SEG_ACT segment


; All keywords in this table *MUST* be in lowercase

	 CMDARG_MAC 'cmac',     PARSE_EA_CMAC,  LCL
	 CMDARG_MAC 'code',     PARSE_EA_CODE,  LCL
	 CMDARG_MAC 'csip',     PARSE_EA_CSIP,  LCL
	 CMDARG_MAC 'data',     PARSE_EA_DATA,  LCL
	 CMDARG_MAC 'dmac',     PARSE_EA_DMAC,  LCL
	 CMDARG_MAC 'ea',       PARSE_EA_EA,    LCL
	 CMDARG_MAC 'ea2',      PARSE_EA_EA2,   LCL
	 CMDARG_MAC 'gdt',      PARSE_EA_GDT,   LCL
	 CMDARG_MAC 'idt',      PARSE_EA_IDT,   LCL
	 CMDARG_MAC 'iret',     PARSE_EA_IRET,  LCL
	 CMDARG_MAC 'iretd',    PARSE_EA_IRETD, LCL
	 CMDARG_MAC 'ldt',      PARSE_EA_LDT,   LCL
	 CMDARG_MAC 'mdb',      PARSE_EA_MDB,   LCL
	 CMDARG_MAC 'nmac',     PARSE_EA_NMAC,  LCL
	 CMDARG_MAC 'retf',     PARSE_EA_RETF,  LCL
	 CMDARG_MAC 'retfd',    PARSE_EA_RETFD, LCL
	 CMDARG_MAC 'retfs',    PARSE_EA_RETFS, LCL
	 CMDARG_MAC 'retn',     PARSE_EA_RETN,  LCL
	 CMDARG_MAC 'retnd',    PARSE_EA_RETND, LCL
	 CMDARG_MAC 'retns',    PARSE_EA_RETNS, LCL
	 CMDARG_MAC 'tdb',      PARSE_EA_TDB,   LCL
	 CMDARG_MAC 'tss',      PARSE_EA_TSS,   LCL
	 CMDARG_MAC 'vm',       PARSE_EA_VM,    LCL
	 CMDARG_MAC 'vmret',    PARSE_EA_VMRET, LCL
	 CMDARG_MAC 'vmcrs',    PARSE_EA_VMCRS, LCL
	 CMDARG_MAC 'xbda',     PARSE_EA_XBDA,  LCL
	 CMDARG_MAC 'xbda2',    PARSE_EA_XBDA2, LCL


SEG_TAB  segment use32 dword public 'data' ; Start SEG_TAB segment
	 assume  ds:DGROUP

	 public  NDOTCMDS
NDOTCMDS equ	 ($-DOTCMD_TAB)/(type DOTCMD_TAB) ; Its length

SEG_TAB  ends			; End SEG_TAB segment


SEG_TAB  segment use32 dword public 'data' ; Start SEG_TAB segment
	 assume  ds:DGROUP

	public	@SWAT_CMD_SEG_TAB@OPR
@SWAT_CMD_SEG_TAB@OPR label byte ; Mark module start in .MAP file

	 public  OPERATOR_TAB
OPERATOR_TAB label dword

SEG_TAB  ends			; End SEG_TAB segment


SEG_LEN  segment use32 dword public 'data' ; Start SEG_LEN segment
	 assume  ds:DGROUP

	public	@SWAT_CMD_SEG_LEN@OPR
@SWAT_CMD_SEG_LEN@OPR label byte ; Mark module start in .MAP file

	 public  OPERATOR_PREC
OPERATOR_PREC label dword

SEG_LEN  ends			; End SEG_LEN segment


SEG_ACT  segment use32 dword public 'data' ; Start SEG_ACT segment
	 assume  ds:DGROUP

	public	@SWAT_CMD_SEG_ACT@OPR
@SWAT_CMD_SEG_ACT@OPR label byte ; Mark module start in .MAP file

	 public  OPERATOR_ACT
OPERATOR_ACT label dword

SEG_ACT  ends			; End SEG_ACT segment


OPERATOR_MAC macro operator,action,precedence

SEG_LEN  segment use32 dword public 'data' ; Start SEG_LEN segment
	 assume  ds:DGROUP

	 dd	 precedence

SEG_LEN  ends

SEG_TAB  segment use32 dword public 'data' ; Start SEG_TAB segment
	 assume  ds:DGROUP

	 dd	 operator

SEG_TAB  ends

SEG_ACT  segment use32 dword public 'data' ; Start SEG_ACT segment
	 assume  ds:DGROUP

	 dd	 offset PGROUP:action

SEG_ACT  ends

	 endm			; OPERATOR_MAC

; Define a minimum precedence for all callers to PARSE_DFNS and for
; address calculations.
	 public  @MINDFN_PREC,@ADDRFN_PREC
@MINDFN_PREC equ	0	; All functions allowed
@ADDRFN_PREC equ	8	; Only * / + and - allowed; others cause return

; Precedence per C language...

	 OPERATOR_MAC '*',  MEMMUL,     9
	 OPERATOR_MAC '/',  MEMDIV,     9
	 OPERATOR_MAC '+',  MEMADD,     8
	 OPERATOR_MAC '-',  MEMSUB,     8
	 OPERATOR_MAC '>>', MEMBSR,     7
	 OPERATOR_MAC '<<', MEMBSL,     7
	 OPERATOR_MAC '<',  MEMLT,      6
	 OPERATOR_MAC '=<', MEMLE,      6
	 OPERATOR_MAC '>',  MEMGT,      6
	 OPERATOR_MAC '=>', MEMGE,      6
	 OPERATOR_MAC '==', MEMEQ,      5
	 OPERATOR_MAC '=!', MEMNEQ,     5
	 OPERATOR_MAC '&',  MEMAND,     4
	 OPERATOR_MAC '^',  MEMXOR,     3
	 OPERATOR_MAC '&&', MEMLAND,    1
	 OPERATOR_MAC '||', MEMLOR,     0


SEG_TAB  segment use32 dword public 'data' ; Start SEG_TAB segment
	 assume  ds:DGROUP

	 public  NOPERATORS
NOPERATORS equ ($-OPERATOR_TAB)/(type OPERATOR_TAB) ; Table's length

SEG_TAB  ends			; End SEG_TAB segment


SREG_TAB segment use32 dword public 'data' ; Start SREG_TAB segment
	 assume  ds:DGROUP

	 extrn	 REG_NTAB:abs
	 extrn	 REG_TAB:dword

SREG_TAB ends			; End SREG_TAB segment


SREG_LEN segment use32 dword public 'data' ; Start SREG_LEN segment
	 assume  ds:DGROUP

	 extrn	 REG_LEN:dword

SREG_LEN ends			; End SREG_LEN segment


SREG_OFF segment use32 word public 'data' ; Start SREG_OFF segment
	 assume  ds:DGROUP

	 extrn	 REG_OFF:word

SREG_OFF ends			; End SREG_OFF segment


SREG_ACTGET segment use32 dword public 'data' ; Start SREG_ACTGET segment
	 assume  ds:DGROUP

	 extrn	 REG_ACTGET:dword

SREG_ACTGET ends		; End SREG_ACTGET segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP,ds:PGROUP

	public	@SWAT_CMD_PROG
@SWAT_CMD_PROG: 		; Mark module start in .MAP file

	 extrn	 SWATINI:tbyte

	 extrn	 DEVLOAD:byte

	 extrn	 ERR_BEEP:near

	 extrn	 SET_CURPOS:near
	 extrn	 SET_CURTYP:near

	 extrn	 DISP_MSGLINE:near
	 extrn	 DISP_CMDLINE:near
	 extrn	 GETBASE:near
	 extrn	 LCL_SYMSRCH:near
	 extrn	 IZITDIGIT:near
	 extrn	 IZITSYMB:near
	 extrn	 LIN2PHYS:near
	 extrn	 SELOFF2ADDR:near

	 extrn	 SWAP_OLDINTS:near
	 extrn	 REST_OLDINTS:near

	 extrn	 LDISPTXT:near
	 extrn	 LDISPASCIIZ:near

	extrn	CMD_APPEND:near
	extrn	SetErrorLog:near
	extrn	CALC_LOGLINE:near

	extrn	GetCurMDBSel:near
	extrn	GetCurTDBSel:near

	 NPPROC  CMD_CHAR -- Command Character In
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Process a command line character

On entry:

AX	 =	 incoming keystroke
SS:EBP	 ==>	 FORW_STR

|

	 REGSAVE <eax,ebx,ecx,esi,edi> ; Save registers

; Process the keystroke

	 lea	 edi,CMD_KEY	; ES:EDI ==> valid keys
	 mov	 ecx,CMD_NKEY	; ECX = # valid keys
   repne scas	 CMD_KEY[edi]	; Search for it
	 je	 near ptr CMD_CHAR_ACT ; Jump if found

	 and	 al,al		; Izit an extended code?
	 jz	 near ptr CMD_CHAR_ERR ; Jump if so

	 movzx	 edi,CURPOSN.LO ; Get current cursor position

	 cmp	 edi,@NCOLS-1	; Are we at the end-of-the-line?
	 jae	 near ptr CMD_CHAR_ERR ; Jump if so

; Handle insert mode

	 test	 CMD_FLAG,@CMD_INS ; Check for insert mode
	 jz	 short CMD_CHAR_XINS ; Not this time

	 mov	 ecx,CMD_LINE_LEN ; Get length of command line
	 dec	 ecx		; Back off to last byte

	 cmp	 ecx,CMDHIGH	 ; Ensure enough room
	 jbe	 near ptr CMD_CHAR_ERR ; Jump if not

	 REGSAVE <esi,edi>	; Save registers

	 sub	 ecx,edi	; Get size of the tail excluding trailing zero

	 mov	 edi,CMD_LINE_LEN ; Get length of command line
	 lea	 edi,CMD_LINE[edi-1] ; ES:EDI ==> ending position in command line
	 mov	 esi,edi	; Copy as source
	 dec	 esi		; Back off to previous character

	 inc	 CMDHIGH	; Increment new command line high water mark

	 std			; String ops backwards
S32  rep movs	 <es:[edi].LO,ds:[esi].LO> ; Make room
	 cld			; String ops forwards

	 REGREST <edi,esi>	; Restore
CMD_CHAR_XINS:
	 lea	 edi,CMD_LINE[edi] ; ES:EDI ==> current position in command line

S32	 stos	 CMD_LINE[edi]	; Save in the command line
	 inc	 CURPOSN.LO	; Skip to the next position
	 movzx	 eax,CURPOSN.LO ; Get current cursor position

	 cmp	 eax,CMDHIGH	; Check against high water mark
	 jbe	 short @F	; Jump if it's lower

	 mov	 CMDHIGH,eax	; Save as new high water mark
@@:
	or	LC4_FLAG,@LC4_CMDNEW ; Mark as new command

	 jmp	 CMD_CHAR_DISP	; Re-display the command line

CMD_CHAR_ACT:
	 sub	 edi,(type CMD_KEY)+offset es:CMD_KEY ; Convert to origin-0
	 shl	 edi,2-1	; Convert from words to dwords

	 jmp	 CMD_ACT[edi]	; Take appropriate action


; Toggle insert state

CMD_INS:
	 xor	 CMD_FLAG,@CMD_INS ; Toggle the flag

	 mov	 ax,VIDTYPE.ELO ; Get normal state type

	 test	 CMD_FLAG,@CMD_INS ; Check the state
	 jz	 short @F	; Jump if normal

	 mov	 ax,VIDTYPE.EHI ; Get insert state type
@@:
	 mov	 CURTYPE,ax	; Save as new type

	 push	 CURTYPE	; Get cursor type
	 call	 SET_CURTYP	; Set it

	 jmp	 CMD_CHAR_DISP	; Join common display code


; Erase to the left

CMD_BS:
	 mov	 al,CURPOSN.LO	; Get cursor column position

	 sub	 al,1		; Back off by one
	 jc	 near ptr CMD_CHAR_CLC ; Jump if not valid

	 mov	 CURPOSN.LO,al	; Save back
				; Fall through to character delete code
; Delete current character

CMD_DEL:
	 mov	 eax,CMDHIGH	; Get high water mark
	 movzx	 edi,CURPOSN.LO ; Get current offset

	 cmp	 edi,eax	; Check against high water mark
	 jae	 near ptr CMD_CHAR_CUR ; Jump if out of range

	 dec	 CMDHIGH	; Decrease high water mark

	 mov	 ecx,CMD_LINE_LEN ; Get length of command line
	 sub	 ecx,edi	; Get size of the tail including trailing zero
	 dec	 ecx		; Excluding ...

	 lea	 edi,CMD_LINE[edi] ; ES:EDI ==> current point in command line
	 lea	 esi,[edi+1]	; DS:ESI ==> next ...
S32  rep movs	 <es:[edi].LO,ds:[esi].LO> ; Move everything down one character

	or	LC4_FLAG,@LC4_CMDNEW ; Mark as new command

	 jmp	 CMD_CHAR_DISP	; Join common display code


; Move the cursor to the end-of-the-line

CMD_END:
	 mov	 al,CMDHIGH.LO	; Get highest cursor position
	 mov	 CURPOSN.LO,al	; Save as new cursor position

	 jmp	 CMD_CHAR_CUR	; Re-display the cursor


; Move the cursor right

CMD_RHT:
	 movzx	 eax,CURPOSN.LO ; Get cursor column position

	 inc	 eax		; Skip over one position

	 cmp	 eax,CMD_LINE_LEN ; Ensure within limits
	 jae	 near ptr CMD_CHAR_CLC ; Jump if not

	 mov	 CURPOSN.LO,al	; Save back

	 jmp	 CMD_CHAR_CUR	; Re-display the cursor


; Move the cursor left

CMD_LFT:
	 mov	 al,CURPOSN.LO	; Get cursor column position

	 sub	 al,1		; Back off by one
	 jc	 near ptr CMD_CHAR_CLC ; Jump if not valid

	 mov	 CURPOSN.LO,al	; Save back

	 jmp	 CMD_CHAR_CUR	; Join common cursor code


; Process the line

CMD_CR:

; Strip trailing blanks

	mov	ecx,CMD_LINE_LEN ; Get length of command line
@@:
	cmp	CMD_LINE[ecx-1],' ' ; Izit a blank?
	jne	short @F	; Jump if not

	mov	CMD_LINE[ecx-1],0 ; Zero it

	loop	@B		; Jump if more chars to check
@@:
	 lea	 esi,CMD_LINE	; DS:ESI ==> command line
	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 near ptr CMD_CHAR_CLEAR ; Yes, just clear the line

	btr	LC4_FLAG,$LC4_CMDNEW ; Izit a new command?
	jnc	short @F	; Jump if not

	call	CMD_APPEND	; Append new command
@@:

; Check for leading slash (keep command on the line)

	 cmp	 al,'/'         ; Izit present?
	 jne	 short @F	; Jump if not

	 inc	 esi		; Skip over it
	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
@@:

; Check for a valid command

	 call	 GET_TOKN	; Get next token into CMD_TOKN

	 xor	 ebx,ebx	; Zero index register
	 mov	 ecx,NCMDARGS	; # arguments to check
CMD_CR_NEXT:
	 mov	 edi,CMDARG_TAB[ebx*(type CMDARG_TAB)] ; Get location of text

	 REGSAVE <ecx,esi>	; Save for a moment

	 mov	 ecx,CMDARG_LEN[ebx*(type CMDARG_LEN)] ; Get length

	 cmp	 cl,CMD_TOKL	; Izit the same length?
	 jne	 short @F	; Jump if not (note ZF=0)

	 lea	 esi,CMD_TOKN	; DS:ESI ==> token
    repe cmps	 CMD_TOKN[esi],es:[edi] ; Compare 'em
				; Fall through with ZF significant
@@:
	 REGREST <esi,ecx>	; Restore
	je	near ptr CMD_CR_FOUND ; Jump if it's a match

	 inc	 ebx		; Skip to next entry

	 loop	 CMD_CR_NEXT	; Jump if more entries to check

; Command not found

; Check for Win386 commands

	mov	ax,ds:[esi]	; Get the first two bytes of the command

	cmp	ax,'?.'         ; Izit dot query?
	je	near ptr CMD_CR_DOTQUERY ; Jump if so

	cmp	al,'?'          ; Izit query?
	je	short @F	; Jump if so

	cmp	al,'.'          ; Izit dot command?
	jne	near ptr CMD_CR_SYNTERR ; Jump if not (not allowed)

	inc	esi		; Skip over the dot/?
@@:
	lea	edi,[esi+1]	; Skip over command char
	mov	CMD_LINE_OFF,edi ; Save for later use

; Send it to WIN386 if it's active

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Is Windows active?
	jz	near ptr CMD_CR_SYNTERR ; Jump if not (not allowed)

	test	SWATINI.MD_ATTR,@MD_WSVC ; Are Win386 services available?
	jz	near ptr CMD_CR_NOWINERR ; Jump if not (not allowed)

; Convert the string to uppercase as that's what Win386 expects

	call	UPPERCASE_STR	; Convert string at DS:ESI to uppercase

	lea	edi,SaveRegs	; DS:EDI ==> Save register struc
	call	CopyWKDRegs	; Copy WKD registers from FORW_STR to DS:EDI

; Because W expects to use its own stack in this context, we save our
; current ptr and switch to the caller's

	push	CMD_CHAR_FVEC.FSEL.EDD ; Save for re-entrancy
	push	CMD_CHAR_FVEC.FOFF     ; ...

	mov	CMD_CHAR_FVEC.FOFF,esp ; Save to restore later
	mov	CMD_CHAR_FVEC.FSEL,ss  ; ...

	lss	esp,[ebp].FORW_ESP.EDF ; Put into effect
	assume	ss:nothing	; Tell the assembler about it

	call	CheckWKDDot	; See if DS:ESI ==> WKD registered dot command
	jc	short @F	; Jump if so

	mov	eax,Win386_Query ; Function code to exec command in DS:ESI
				; using regs in DS:EDI
	int	Win386_Query_Int ; Request Win386 services
@@:
	lss	esp,CMD_CHAR_FVEC ; Restore
	assume	ss:nothing	; Tell the assembler about it

	pop	CMD_CHAR_FVEC.FOFF ; Restore
	pop	CMD_CHAR_FVEC.FSEL.EDD ; ...
CMD_CR_WKDCOM:

; Set displaying error log state

	call	SetErrorLog	; Set displaying error log state

; Set error log line # to end of buffer

	call	CALC_LOGLINE	; Return with EAX = # lines

	cmp	eax,@NROWS-2	; Izit more than fit on a screen?
	jb	short @F	; Jump if so (use the actual number)

	sub	eax,@NROWS-2	; Back off to end of buffer less a screen's worth
@@:
	mov	ERRLOG_CLINE,eax ; Ensure we display at end of buffer
	or	LCL_FLAG,@LCL_REDI ; Force screen re-display

	jmp	CMD_CHAR_DONE	; Join common done code

CMD_CR_DOTQUERY:

; Ensure W is active

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Is Windows active?
	jz	short CMD_CR_NOWINERR ; Jump if not (not allowed)

; Loop through the registered dot commands (in WKDDOT_TAB)
; displaying the various help texts

	REGSAVE <ebx,ecx,edx,esi,ds> ; Save registers

	movzx	edx,RGRSEG2	; Get low DOS memory segment
	shl	edx,4-0 	; Convert from paras to bytes

	assume	gs:RGROUP	; Tell a white lie

	mov	ecx,@WKDDOT_MAX ; Get maximum # registered dot commands
	xor	ebx,ebx 	; Initialize index into WKDDOT_TAB

	assume	ds:nothing	; Tell the assembler about it
CMD_CR_DQ1:
	cmp	WKDDOT_TAB[ebx+edx].WKDDOT_CHR,0 ; Izit empty?
	je	short CMD_CR_DQ2 ; Jump if so

	lds	esi,WKDDOT_TAB[ebx+edx].WKDDOT_HLP ; Get address of help text
	assume	ds:nothing	; Tell the assembler about it

	call	LDISPASCIIZ	; Display string at DS:ESI to error log
CMD_CR_DQ2:
	add	ebx,type WKDDOT_STR ; Skip to next entry

	loop	CMD_CR_DQ1	; Jump if more strings to display
	assume	gs:AGROUP	; Retract nose

	REGREST <ds,esi,edx,ecx,ebx> ; Restore
	assume	ds:DGROUP	; Tell the assembler about it

	jmp	short CMD_CR_WKDCOM ; Join common done code


CMD_CR_NOWINERR:
	mov	MSGOFF,offset DGROUP:NOWINERR ; Save offset of error message

	jmp	short CMD_CR_ERRCOM ; Join common error code

CMD_CR_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:CMDERR ; Save offset of error message
CMD_CR_ERRCOM:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 jmp	 CMD_CHAR_ERR	; Jump if unknown

CMD_CR_FOUND:
	 add	 esi,CMDARG_LEN[ebx*(type CMDARG_LEN)] ; Skip over the keyword

	 call	 CMDARG_ACT[ebx*(type CMDARG_ACT)] ; Take appropriate action

	 pushfd 		; Save result in CF
	 cmp	 CMD_LINE_TERM,0 ; Was it destroyed?
	 je	 short @F	; Jump if not

	 REGSAVE <eax,esi>	; Save
	 lea	 esi,TERMERR	; 'Terminator clobbered'
	 call	 LDISPASCIIZ	; Display to error log
	 mov	 al,bh		; High byte of index
	 call	 LDISPTXT	; Display it
	 mov	 al,bl		; Low byte
	 call	 LDISPTXT	; Display it
	 mov	 al,'>'         ; Close message
	 call	 LDISPTXT	; Display it
	 REGREST <esi,eax>	; Restore
@@:
	 popfd			; Restore

	 jc	 short CMD_CHAR_ERR ; Jump if in error

; See if we should leave the command on the line

CMD_CHAR_DONE:
	 lea	 esi,CMD_LINE	; DS:ESI ==> command line

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,'/'         ; Izit present?
	 je	 short @F	; Jump if so

	 call	 CLEAR_CMDLINE	; Clear the command line
@@:
	 jmp	 short CMD_CHAR_EXIT ; Join common exit code


; Clear out the command line

CMD_CHAR_CLEAR:
	 lea	 edi,CMD_LINE	; ES:EDI ==> command line
	 mov	 ecx,CMD_LINE_LEN ; Length of ...
	 mov	 al,' '         ; Filler
     rep stos	 CMD_LINE[edi]	; Fill with blanks
	 sub	 al,al		; Terminate with a null
S32	 stos	 CMD_LINE[edi]	; Blast in 0

	 mov	 CMDHIGH,0	; Reset command line high position
	 mov	 CMD_TOKZ,0	; Reassert trailing null

; Move cursor to column 0

CMD_HOM:
	 mov	 CURPOSN.LO,0	; Reset cursor column to zero

; Display the command line

CMD_CHAR_DISP:
	 test	 LC3_FLAG,@LC3_INTERNAL ; Are we executing an internal command?
	 jnz	 short @F	; Jump if so

	 call	 DISP_CMDLINE	; Display the command line

; Move the cursor

CMD_CHAR_CUR:
	 push	 CURPOSN	; Get cursor position
	 call	 SET_CURPOS	; Set it
@@:
	 jmp	 short CMD_CHAR_CLC ; Join common exit code


; Unknown keystroke

CMD_CHAR_ERR:
	 call	 DISP_MSGLINE	; Display the message line
	 call	 ERR_BEEP	; Sound the alarum!
CMD_CHAR_CLC:
CMD_CHAR_EXIT:
	 REGREST <edi,esi,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_CHAR endp			; End CMD_CHAR procedure
	NPPROC	CheckWKDDot -- Check For WKD Registered Dot Commands
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Check for WKD registered dor commands

On entry:

DS:ESI	==>	dot command

On exit:

CF	=	0 if not
	=	1 if so

|

	pushad			; Save registers

	mov	al,ds:[esi]	; Get command char

	movzx	edx,RGRSEG2	; Get low DOS memory segment
	shl	edx,4-0 	; Convert from paras to bytes

	assume	gs:RGROUP	; Tell a white lie

	mov	ecx,@WKDDOT_MAX ; Get maximum # registered dot commands
	xor	ebx,ebx 	; Initialize index into WKDDOT_TAB

	assume	ds:nothing	; Tell the assembler about it
@@:
	cmp	al,WKDDOT_TAB[ebx+edx].WKDDOT_CHR ; Izit the same?
	je	short @F	; Jump if so

	add	ebx,type WKDDOT_STR ; Skip to next entry

	loop	@B		; Jump if more entries to check

	clc			; Mark as no match

	jmp	short CheckWKDDotExit ; Join common code

@@:
	REGSAVE <ds,es> 	; Save for a moment

	mov	ds,WKD_AGRSEL[edx] ; Get all memory selector
	assume	ds:AGROUP	; Tell the assembler about it

	mov	es,WKD_AGRSEL[edx] ; Get all memory selector
	assume	es:AGROUP	; Tell the assembler about it

	call	WKDDOT_TAB[ebx+edx].WKDDOT_ACT ; Call common routine
				; with AL=command, DS=ES=AGROUP
				; Return with AX == 0 if no errors
	REGREST <es,ds> 	; Restore
	assume	ds:DGROUP,es:DGROUP ; Tell the assembler about it

	stc			; Mark as matching
CheckWKDDotExit:
	assume	gs:AGROUP	; Retract nose

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CheckWKDDot endp		; End CheckWKDDot procedure
	 NPPROC  GET_TOKN -- Get Next Token From Command Line in Lowercase
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get next token from the command line and convert to lowercase

On entry:

DS:ESI	 ==>	 next byte on command line

On exit:

CMD_TOKL	 filled in
CMD_TOKN	 filled in

|

	 REGSAVE <ecx>		; Save register

	 mov	 ecx,1		; Mark as to be converted to lowercase
	 call	 GET_TOKNSUB	; Get next token into CMD_TOKN

	 REGREST <ecx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_TOKN endp			; End GET_TOKN procedure
	 NPPROC  GET_CSTOKN -- Get Next Case-sensitive Token From Command Line
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get next case-sensitive token from the command line

On entry:

DS:ESI	 ==>	 next byte on command line

On exit:

CMD_TOKL	 filled in
CMD_TOKN	 filled in

|

	 REGSAVE <ecx>		; Save register

	 xor	 ecx,ecx	; Mark as case-sensitive
	 call	 GET_TOKNSUB	; Get next token into CMD_TOKN

	 REGREST <ecx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_CSTOKN endp 		; End GET_CSTOKN procedure
	 NPPROC  GET_TOKNSUB -- Subroutine to GET_TOKN and GET_CSTOKN
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get next token from the command line

On entry:

DS:ESI	 ==>	 next byte on command line
ECX	 =	 1 if convert to lowercase
	 =	 0 if not

On exit:

CMD_TOKL	 filled in
CMD_TOKN	 filled in

|

	 REGSAVE <eax,esi,edi>	; Save registers

	 lea	 edi,CMD_TOKN	; ES:EDI ==> save area for token
	 mov	 ah,0		; Initialize token length

	 mov	 al,ds:[esi]	; Get next character
	 call	 IZITDIGIT	; Izit a digit?
	 jnc	 short GET_TOKNSUB_EXIT ; Jump if so (can't start a symbol)

	cmp	al,'.'          ; Izit the start of a reserved word?
	je	short GET_TOKNSUB_SAVE ; Jump if so
GET_TOKNSUB_NEXT:
	 mov	 al,ds:[esi]	; Get next character

	 call	 IZITSYMB	; Izit valid in a symbol name?
	 jc	 short GET_TOKNSUB_EXIT ; No, so that's the end of the token

	 jecxz	 GET_TOKNSUB_SAVE ; Jump if no case conversion

	 call	 U32_LOWERCASE	; Convert AL to lowercase
GET_TOKNSUB_SAVE:
S32	 stos	 CMD_TOKN[edi]	; Save in token
	 inc	 esi		; Skip over input variable
	 inc	 ah		; Count into length

	 jmp	 GET_TOKNSUB_NEXT ; Go around again

GET_TOKNSUB_EXIT:
	 mov	 CMD_TOKL,ah	; Save as length of CMD_TOKN

	mov	ax,0		; Get string terminator (double-zero)
S32	stos	CMD_TOKN.ELO[edi] ; Save in token

	 REGREST <edi,esi,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_TOKNSUB endp		; End GET_TOKNSUB procedure
	NPPROC	CHECK_TOKN -- Check For Text In Token
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for text in token

On entry:

ES:EDI	==>	ASCIIZ text to check for

On exit:

ZF	=	1 if it matches
	=	0 if not

|

	REGSAVE <ecx,esi,edi>	; Save registers

	lea	esi,CMD_TOKN	; DS:ESI ==> token
	movzx	ecx,CMD_TOKL	; Get token length
	inc	ecx		; Count in the trailing zero
	cld			; String ops forwardly
   repe cmps	CMD_TOKN[esi],es:[edi].LO ; Izit the same?
				; ZF=1 if so
				;    0 if not
	REGREST <edi,esi,ecx>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_TOKN endp 		; End CHECK_TOKN procedure
	 NPPROC  MEMADD -- Add Two Numbers
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Add two numbers

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 =	 result
CF	 =	 0 if no error
	 =	 1 otherwise

|

MEMARITH_STR struc

MEMARITH_EBP dd  ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
MEMARITH_RHT dd  ?		; Righthand argument
MEMARITH_LFT dd  ?		; Lefthand ...

MEMARITH_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 mov	 eax,[ebp].MEMARITH_LFT ; Get the lefthand value
	 add	 eax,[ebp].MEMARITH_RHT ; Plus the righthand ...

	 clc			; Tell 'em it worked

	 pop	 ebp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMADD	 endp			; End MEMADD procedure
	 NPPROC  MEMAND -- AND Two Numbers
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

AND two numbers

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 =	 result
CF	 =	 0 if no error
	 =	 1 otherwise

|

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 mov	 eax,[ebp].MEMARITH_LFT ; Get the lefthand value
	 and	 eax,[ebp].MEMARITH_RHT ; AND the righthand ...
				; Note CF = 0

	 pop	 ebp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMAND	 endp			; End MEMAND procedure
	 NPPROC  MEMXOR -- XOR Two Numbers
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

XOR two numbers

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 =	 result
CF	 =	 0 if no error
	 =	 1 otherwise

|

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 mov	 eax,[ebp].MEMARITH_LFT ; Get the lefthand value
	 xor	 eax,[ebp].MEMARITH_RHT ; XOR the righthand ...
				; Note CF = 0

	 pop	 ebp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMXOR	 endp			; End MEMXOR procedure
	 NPPROC  MEMSUB -- Subtract Two Numbers
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Subtract two numbers

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 =	 result
CF	 =	 0 if no error
	 =	 1 otherwise

|

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 mov	 eax,[ebp].MEMARITH_LFT ; Get the lefthand value
	 sub	 eax,[ebp].MEMARITH_RHT ; Less the righthand ...

	 clc			; Tell 'em it worked

	 pop	 ebp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMSUB	 endp			; End MEMSUB procedure
	 NPPROC  MEMMUL -- Multiply Two Numbers
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Multiply two numbers

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 =	 result
CF	 =	 0 if no error
	 =	 1 otherwise

|

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 push	 edx		; Save for a moment

	 mov	 eax,[ebp].MEMARITH_LFT ; Get the lefthand value
	 mul	 [ebp].MEMARITH_RHT ; Times the righthand ...
				; Note CF significant

	 pop	 edx		; Restore

	 pop	 ebp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMMUL	 endp			; End MEMMUL procedure
	 NPPROC  MEMDIV -- Divide Two Numbers
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Divide two numbers

Note that we don't handle overflow (INT 00h) as yet.

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 =	 result
CF	 =	 0 if no error
	 =	 1 otherwise

|

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ebx,edx>	; Save for a moment

	 mov	 eax,[ebp].MEMARITH_LFT ; Get the lefthand value
	 mov	 ebx,[ebp].MEMARITH_RHT ; ...	  righthand ...

; Reload EBP with the caller's value so we have addressability
; to FORW_STR from within INST_00

	 mov	 ebp,[ebp].MEMARITH_EBP ; Restore

	 call	 INST_00	; Install INT 00h handler

	 xor	 edx,edx	; Zero the high-order dword
	 div	 ebx		; Divide 'em

	 clc			; Assume it worked
MEMDIV_OVF:
	 call	 REST_00	; Restore INT 00h handler

	 REGREST <edx,ebx>	; Restore

	 pop	 ebp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMDIV	 endp			; End MEMDIV procedure
	 NPPROC  MEMLAND -- Logically AND two numbers
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Logically AND two numbers

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 =	 result

|

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 mov	 eax,[ebp].MEMARITH_LFT ; Get the lefthand value
	 cmp	 eax,1		; CF=1 if EAX=0
	 cmc			; CF=0 ...
	 sbb	 eax,eax	; Smear CF throughout EAX
	 and	 eax,[ebp].MEMARITH_RHT ; Use it to mask off operand & set ZF
	 setnz	 al		; AL = truth value
	 movzx	 eax,al 	; Extend to DWORD

	 clc			; Tell 'em it worked

	 pop	 ebp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMLAND  endp			; End MEMLAND procedure
	 NPPROC  MEMLOR -- Logically OR two numbers
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Logically OR two numbers

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 =	 result

|

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 mov	 eax,[ebp].MEMARITH_LFT ; Get the lefthand value
	 or	 eax,[ebp].MEMARITH_RHT ; Bitwise combine with righthand value
	 setnz	 al		; AL = truth value
	 movzx	 eax,al 	; Extend to DWORD

	 clc			; Tell 'em it worked

	 pop	 ebp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMLOR	 endp			; End MEMLOR procedure
	 NPPROC  MEMEQ -- Compare two numbers
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Compare two numbers and return 1 if equal, 0 if not

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 =	 result

|

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 mov	 eax,[ebp].MEMARITH_LFT ; Get the lefthand value
	 cmp	 eax,[ebp].MEMARITH_RHT ; Bitwise combine with righthand value
	 sete	 al		; AL = truth value
	 movzx	 eax,al 	; Extend to DWORD

	 clc			; Tell 'em it worked

	 pop	 ebp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMEQ	 endp			; End MEMEQ procedure
	 NPPROC  MEMNEQ -- Compare two numbers for inequality
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Compare two numbers and return 1 if different, 0 if equal

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 =	 result

|

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 mov	 eax,[ebp].MEMARITH_LFT ; Get the lefthand value
	 cmp	 eax,[ebp].MEMARITH_RHT ; Bitwise combine with righthand value
	 setne	 al		; AL = truth value
	 movzx	 eax,al 	; Extend to DWORD

	 clc			; Tell 'em it worked

	 pop	 ebp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMNEQ	 endp			; End MEMNEQ procedure
	 NPPROC  MEMLT -- Compare two numbers for A < B (unsigned)
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Compare two numbers and return 1 if A < B, 0 if A >= B

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 =	 result

|

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 mov	 eax,[ebp].MEMARITH_LFT ; Get the lefthand value
	 cmp	 eax,[ebp].MEMARITH_RHT ; Bitwise combine with righthand value
	 setb	 al		; AL = truth value
	 movzx	 eax,al 	; Extend to DWORD

	 clc			; Tell 'em it worked

	 pop	 ebp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMLT	 endp			; End MEMLT procedure
	 NPPROC  MEMLE -- Compare two numbers for A <= B (unsigned)
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Compare two numbers and return 1 if A <= B, 0 if A > B

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 =	 result

|

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 mov	 eax,[ebp].MEMARITH_LFT ; Get the lefthand value
	 cmp	 eax,[ebp].MEMARITH_RHT ; Bitwise combine with righthand value
	 setbe	 al		; AL = truth value
	 movzx	 eax,al 	; Extend to DWORD

	 clc			; Tell 'em it worked

	 pop	 ebp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMLE	 endp			; End MEMLE procedure
	 NPPROC  MEMGT -- Compare two numbers for A gt B (unsigned)
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Compare two numbers and return 1 if A > B, 0 if A <= B

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 =	 result

|

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 mov	 eax,[ebp].MEMARITH_LFT ; Get the lefthand value
	 cmp	 eax,[ebp].MEMARITH_RHT ; Bitwise combine with righthand value
	 seta	 al		; AL = truth value
	 movzx	 eax,al 	; Extend to DWORD

	 clc			; Tell 'em it worked

	 pop	 ebp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMGT	 endp			; End MEMGT procedure
	 NPPROC  MEMGE -- Compare two numbers for A ge B (unsigned)
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Compare two numbers and return 1 if A >= B, 0 if A < B

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 =	 result

|

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 mov	 eax,[ebp].MEMARITH_LFT ; Get the lefthand value
	 cmp	 eax,[ebp].MEMARITH_RHT ; Bitwise combine with righthand value
	 setae	 al		; AL = truth value
	 movzx	 eax,al 	; Extend to DWORD

	 clc			; Tell 'em it worked

	 pop	 ebp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMGE	 endp			; End MEMGE procedure
	 NPPROC  MEMBSR -- Shift a number right a specified number of bits
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Shift X right Y bits, losing bits off the right end

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 =	 result
CF	 =	 0 if no error
	 =	 1 otherwise

|

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ecx>		; Save

	 mov	 eax,[ebp].MEMARITH_LFT ; Get the lefthand value
	 mov	 cl,[ebp].MEMARITH_RHT.LO ; Get number of bits to shift
	 shr	 eax,cl 	; Shift modulo 32

	 REGREST <ecx>		; Restore

	 clc			; Tell 'em it worked

	 pop	 ebp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMBSR	 endp			; End MEMBSR procedure
	 NPPROC  MEMBSL -- Shift a number left a specified number of bits
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Shift X right Y bits, filling bits on the left with 0.

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 =	 result
CF	 =	 0 if no error
	 =	 1 otherwise

|

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ecx>		; Save

	 mov	 eax,[ebp].MEMARITH_LFT ; Get the lefthand value
	 mov	 cl,[ebp].MEMARITH_RHT.LO ; Get number of bits to shift
	 shl	 eax,cl 	; Shift modulo 32

	 REGREST <ecx>		; Restore

	 clc			; Tell 'em it worked

	 pop	 ebp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMBSL	 endp			; End MEMBSL procedure
	 NPPROC  INST_00 -- Install INT 00h Handler
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Install INT 00h handler

On entry:

SS:EBP	 ==>	 FORW_STR

|

	 REGSAVE <eax,ebx>	; Save registers

; Address the IDT

	 mov	 ebx,[ebp-@BPBACK].BACK_IDT.DTR_BASE ; Get IDTR base

	 IDTMAC  00h,00,DIV,OLDDIV,FORCE ; IDT to OLDDIV, DIV to IDT (EAX clobbered)

	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST_00  endp			; End INST_00 procedure
	 NPPROC  REST_00 -- Restore INT 00h Handler
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Restore INT 00h handler

On entry:

CF	 =	 1 if error in command
SS:EBP	 ==>	 FORW_STR

|

	 pushfd 		; Save flags
	 REGSAVE <eax,ebx>	; Save registers

	 mov	 ebx,[ebp-@BPBACK].BACK_IDT.DTR_BASE ; Get IDTR base

	 IDTMAC  00h,00,OLDDIV,,FORCE ; OLDDIV to IDT (EAX clobbered)

	 REGREST <ebx,eax>	; Restore
	 popfd			; Restore flags

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_00  endp			; End REST_00 procedure
	 FPPROC  DIV_INT00 -- Local Division INT 00h Handler
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Local division INT 00h handler

This handler is called if the division overflows

|

IDIV_STR struc

IDIV_EIP dd	 ?		; Caller's EIP
IDIV_CS  dw	 ?,?		; ...	   CS with filler
IDIV_EFL dd	 ?		; ...	   EFL

IDIV_STR ends

	 mov	 [esp].IDIV_EIP,offset PGROUP:MEMDIV_OVF ; Restart here
	 or	 [esp].IDIV_EFL.ELO,mask $CF ; Set carry flag

	 iretd			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DIV_INT00 endp			; End DIV_INT00 procedure
	 NPPROC  PARSE_ATOM -- Parse Command Line For An Atom
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Parse the command line for an atom

// Atoms
atomð con
    ð reg
    ð .LBRFR
    ð .LBRTO
    ð .LEXFR
    ð .LEXTO

On entry:

DS:ESI	 ==>	 command line to parse (zero-terminated)
SS:EBP	 ==>	 FORW_STR

On exit:

DS:ESI	 ==>	 (updated past white space)
EAX	 =	 value
CF	 =	 0 above register is valid
	 =	 1 something went wrong

|

	 push	 edi		; Save for a moment

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
; Check for .LBRFR, .LBRTO, .LEXFR, .LEXTO

	call	GET_TOKN	; Get next token into CMD_TOKN

	cmp	CMD_TOKN[0].ELO,'l.' ; Duzit it start with '.L'?
	jne	short PARSE_ATOM_XL ; Jump if not

	cmp	CMD_TOKN[2].EDD,'rfrb' ; Izit '.LBRFR'?
	mov	eax,LBRFREIP	; Assume so
	je	short PARSE_ATOM_LCOM ; Jump if so

	cmp	CMD_TOKN[2].EDD,'otrb' ; Izit '.LBRTO'?
	mov	eax,LBRTOEIP	; Assume so
	je	short PARSE_ATOM_LCOM ; Jump if so

	cmp	CMD_TOKN[2].EDD,'rfxe' ; Izit '.LEXFR'?
	mov	eax,LEXFREIP	; Assume so
	je	short PARSE_ATOM_LCOM ; Jump if so

	cmp	CMD_TOKN[2].EDD,'otxe' ; Izit '.LEXTO'?
	mov	eax,LEXTOEIP	; Assume so
	jne	short PARSE_ATOM_XL ; Jump if not
PARSE_ATOM_LCOM:
	add	esi,6		; Skip over the command

	clc			; Mark as successful

	jmp	short PARSE_ATOM_EXIT ; Join common exit code

PARSE_ATOM_XL:
	 call	 REG2DD 	; Convert register at DS:ESI to binary EAX
	 jnc	 short PARSE_ATOM_EXIT ; Jump if we succeeded (note CF=0)

; Convert the hex number at DS:ESI to binary

	 mov	 edi,esi	; Save original offset

	 call	 U32_HEX2DD	; Convert DS:ESI from hex to binary EAX
	 jc	 short PARSE_ATOM_OVFERR ; Jump if we failed

; Ensure we processed something (otherwise it's a syntax error)

	 cmp	 esi,edi	; Did we get very far?
	 ja	 short PARSE_ATOM_EXIT ; Jump if we succeeded (note CF=0)

	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	 jmp	 short PARSE_ATOM_ERR ; Join common error code

PARSE_ATOM_OVFERR:
	 mov	 MSGOFF,offset DGROUP:OVFERR ; Save offset of error message
PARSE_ATOM_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Indicate something went wrong
PARSE_ATOM_EXIT:
	 pop	 edi		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PARSE_ATOM endp 		; End PARSE_ATOM procedure
	 NPPROC  PARSE_VAL -- Parse Command Line For A Value
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Parse the command line for a value

// Monadic functions
mfn ð atom
    ð ] ea		extract byte at effective address
    ð [ ea		extract word ...
    ð { ea		extract dword ...
    ð L.ea		extract linear address ...
    ð O.ea		extract offset ...
    ð P.ea		extract physical address ...
    ð S.ea		extract segment/selector ...
    ð + exp		NOP
    ð - exp		negate expression
    ð ~ exp		complement expression

On entry:

DS:ESI	 ==>	 command line to parse (zero-terminated)
SS:EBP	 ==>	 FORW_STR

On exit:

DS:ESI	 ==>	 (updated past white space)
EAX	 =	 value
CF	 =	 0 above register is valid
	 =	 1 something went wrong

|

	 REGSAVE <ebx,ecx,edx>	; Save registers

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,']'         ; Izit byte extraction?
	 je	 short PARSE_VAL_BYTE ; Jump if so

	 cmp	 al,'['         ; Izit word extraction?
	 je	 short PARSE_VAL_WORD ; Jump if so

	 cmp	 al,'{'         ; Izit dword extraction?
	 je	 near ptr PARSE_VAL_DWORD ; Jump if so

; Check for '+ exp' and '- exp'

	 cmp	 al,'-'         ; Izit negative function?
	 je	 short PARSE_VAL_NEG ; Jump if so

	 cmp	 al,'~'         ; Izit complement function?
	 je	 short PARSE_VAL_COMP ; Jum if so

	 cmp	 al,'+'         ; Izit identity function?
	 je	 short PARSE_VAL_IDEN ; Jum if so

	 mov	 ax,DGROUP:[esi] ; Get the next two symbols
	 call	 U32_LOWERCASE	; Convert AL to lowercase

; Check for 'o.', 's.', 'l.', and 'p.'

	 cmp	 ax,'.o'        ; Izit extract offset?
	 je	 near ptr PARSE_VAL_OFF ; Jump if so

	 cmp	 ax,'.s'        ; Izit extract segment/selector?
	 je	 near ptr PARSE_VAL_SEG ; Jump if so

	 cmp	 ax,'.l'        ; Izit extract linear address?
	 je	 short PARSE_VAL_LIN ; Jump if so

	 cmp	 ax,'.p'        ; Izit extract physical address?
	 je	 short PARSE_VAL_PHYS ; Jump if so

	 call	 PARSE_ATOM	; Parse command line for an atom
				; Return with CF significant

	 jmp	 PARSE_VAL_EXIT ; Note CF significant


; Extract the byte at an effective address

PARSE_VAL_BYTE:
	 inc	 esi		; Skip over the extraction symbol

	 call	 PARSE_EA	; Parse command line for an effective address
	 jc	 near ptr PARSE_VAL_EXIT ; Jump if error (note CF=1)
				; BX  = selector/segment (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = 32-bit base address for BX

	 movzx	 eax,AGROUP:[edx+eax].LO ; Extract the byte at the 'ea'

	 jmp	 PARSE_VAL_CLC	; Join common OK code


; Extract the word at an effective address

PARSE_VAL_WORD:
	 inc	 esi		; Skip over the extraction symbol

	 call	 PARSE_EA	; Parse command line for an effective address
	 jc	 short PARSE_VAL_EXIT ; Jump if error (note CF=1)
				; BX  = selector/segment (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = 32-bit base address for BX

	 movzx	 eax,AGROUP:[edx+eax].ELO ; Extract the word at the 'ea'

	 jmp	 short PARSE_VAL_CLC ; Join common OK code


; Parse '~ exp'

PARSE_VAL_COMP:
	 inc	 esi		; Skip over it

	 call	 PARSE_EXPR	; Parse command line for an expression
	 jc	 short PARSE_VAL_EXIT ; Jump if something went wrong (note CF=1)

	 not	 eax		; Complement the value as requested

	 jmp	 short PARSE_VAL_CLC ; Join common OK code


; Parse '- exp'

PARSE_VAL_NEG:
	 inc	 esi		; Skip over it

	 call	 PARSE_EXPR	; Parse command line for an expression
	 jc	 short PARSE_VAL_EXIT ; Jump if something went wrong (note CF=1)

	 neg	 eax		; Negate the value as requested

	 jmp	 short PARSE_VAL_CLC ; Join common OK code


; Parse '+ exp'

PARSE_VAL_IDEN:
	 inc	 esi		; Skip over it

	 call	 PARSE_EXPR	; Parse command line for an expression
	 jc	 short PARSE_VAL_EXIT ; Jump if something went wrong (note CF=1)

	 jmp	 short PARSE_VAL_CLC ; Join common OK code


; Extract the dword at an effective address

PARSE_VAL_DWORD:
	 inc	 esi		; Skip over the extraction symbol

	 call	 PARSE_EA	; Parse command line for an effective address
	 jc	 short PARSE_VAL_EXIT ; Jump if error (note CF=1)

	 mov	 eax,AGROUP:[edx+eax] ; Extract the dword at the 'ea'

	 jmp	 short PARSE_VAL_CLC ; Join common OK code


; Extract the linear address from an effective address

PARSE_VAL_LIN:
	 inc	 esi		; Skip over the extraction symbols
	 inc	 esi		; ...

	 call	 PARSE_EA	; Parse command line for an effective address
	 jc	 short PARSE_VAL_EXIT ; Jump if error (note CF=1)
				; BX  = selector/segment (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = 32-bit base address for BX

	 add	 eax,edx	; Add to get 32-bit linear address

	 jmp	 short PARSE_VAL_CLC ; Join common OK code


; Extract the physical address from an effective address

PARSE_VAL_PHYS:
	 inc	 esi		; Skip over the extraction symbols
	 inc	 esi		; ...

	 call	 PARSE_EA	; Parse command line for an effective address
	 jc	 short PARSE_VAL_EXIT ; Jump if error (note CF=1)
				; BX  = selector/segment (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = 32-bit base address for BX

	 add	 eax,edx	; Add to get 32-bit linear address
	 call	 LIN2PHYS	; Translate linear addr EAX to physical addr EAX

	 jmp	 short PARSE_VAL_CLC ; Join common OK code


; Extract the offset from an effective address

PARSE_VAL_OFF:
	 inc	 esi		; Skip over the extraction symbols
	 inc	 esi		; ...

	 call	 PARSE_EA	; Parse command line for an effective address
	 jc	 short PARSE_VAL_EXIT ; Jump if error (note CF=1)
				; BX  = selector/segment (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = 32-bit base address for BX

	 jmp	 short PARSE_VAL_CLC ; Join common OK code


; Extract the segment/selector from an effective address

PARSE_VAL_SEG:
	 inc	 esi		; Skip over the extraction symbols
	 inc	 esi		; ...

	 call	 PARSE_EA	; Parse command line for an effective address
	 jc	 short PARSE_VAL_EXIT ; Jump if error (note CF=1)
				; BX  = selector/segment (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = 32-bit base address for BX

	 movzx	 eax,bx 	; Copy segment/selector

;;;;;;;; jmp	 short PARSE_VAL_CLC ; Join common OK code


PARSE_VAL_CLC:
	 clc			; Indicate all went well
PARSE_VAL_EXIT:
	 REGREST <edx,ecx,ebx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PARSE_VAL endp			; End PARSE_VAL procedure
	 NPPROC  PARSE_LVAL -- Parse Command Line For A Lefthand Value
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Parse the command line for a lefthand value

// Lefthand values
lvalð atom
    ð ( exp )

On entry:

DS:ESI	 ==>	 command line to parse (zero-terminated)
SS:EBP	 ==>	 FORW_STR

On exit:

DS:ESI	 ==>	 (updated past white space)
EAX	 =	 value
CF	 =	 0 above register is valid
	 =	 1 something went wrong

|

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,'('         ; Izit left parenthesis?
	 je	 short PARSE_LVAL_LPAR ; Jump if so

	 call	 PARSE_ATOM	; Parse command line for an atom
				; Return with CF significant

	 jmp	 short PARSE_LVAL_EXIT ; Note CF significant

PARSE_LVAL_LPAR:
	 inc	 esi		; Skip over the left parenthesis

	 call	 PARSE_EXPR	; Parse command line for an expression
	 jc	 short PARSE_LVAL_EXIT ; Jump if error (note CF=1)

	 push	 eax		; Save for a moment

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,')'         ; Izit matching right parenthesis?
	 pop	 eax		; Restore
	 jne	 short PARSE_LVAL_SYNTERR ; Jump if not

	 inc	 esi		; Skip over the right parenthesis

	 clc			; Mark as all went well

	 jmp	 short PARSE_LVAL_EXIT ; Join common exit code

PARSE_LVAL_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Indicate something went wrong
PARSE_LVAL_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PARSE_LVAL endp 		; End PARSE_LVAL procedure
	 NPPROC  PARSE_EXPR -- Parse Command Line For An Expression
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Parse the command line for an expression

// Expressions on values
exp ð ( exp )
    ð mfn		monadic functions
    ð dfn		dyadic functions

On entry:

DS:ESI	 ==>	 command line to parse (zero-terminated)
SS:EBP	 ==>	 FORW_STR

On exit:

DS:ESI	 ==>	 (updated past white space)
EAX	 =	 value
CF	 =	 0 above register is valid
	 =	 1 something went wrong

|

	 REGSAVE <ebx,ecx>	; Save registers

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,'('         ; Izit start of ( exp )?
	 je	 short PARSE_EXPR_LPAR ; Jump if so

	 call	 PARSE_VAL	; Parse command line for a value
	 jc	 short PARSE_EXPR_EXIT ; Jump if something went wrong (note CF=1)

	 jmp	 short PARSE_EXPR_DFNS ; Join common dyadic function code


; Note we don't skip over the left parenthesis; PARSE_LVAL handles
; both parentheses

PARSE_EXPR_LPAR:
	 call	 PARSE_LVAL	; Parse command line for lefthand value
	 jc	 short PARSE_EXPR_EXIT ; Jump if error (note CF=1)

; Check for dyadic functions

PARSE_EXPR_DFNS:
	 PUSHD	 @MINDFN_PREC	; All function precendences allowed
	 call	 PARSE_DFNS	; Check for dyadic functions
				; Return with CF significant
PARSE_EXPR_EXIT:
	 REGREST <ecx,ebx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PARSE_EXPR endp 		; End PARSE_EXPR procedure
	 NPPROC  SCAN_DFNS -- Scan function table for an operator
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Scans for a single operator in the dyadic function table

On entry:

DS:ESI	 ==>	null-terminated command line containing (possible) operator

On exit:

DS:ESI	 ==>	(updated past white space)
CF = 0		function not found (EDI undefined, ESI points to non-operator)
   = 1		function found (ESI points past operator)
DS:EDI	 ==>	index into OPERATOR_* (dword index)

|

	 REGSAVE <eax,ebx,ecx>	; Save

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	 or	 al,al		; Did we get anything?
	 jz	 short SCAN_DFNS_EXIT ; Jump if not (CF significant)

; Set up AX so string constants compare in 'normal' order, e.g.
; DGROUP:esi ==> '<=', AL='<', AH='=', AX='=<'
	 sub	 eax,eax	; Zero high word
	 lods	 DGROUP:[esi].ELO ; Get both bytes in AX and update ESI

; Find the operator as a word
	 lea	 edi,OPERATOR_TAB ; Address start of table
	 mov	 ecx,NOPERATORS ; How far to look

	 cld			; String ops forwardly

  repne  scas	 OPERATOR_TAB[edi] ; Find word
	 je	 short SCAN_DFNS_FOUND ; Jump if found

	 lea	 edi,OPERATOR_TAB ; Start again
	 sub	 ah,ah		; Search for one-byte operator now
	 dec	 esi		; Back off past one-byte operator
	 mov	 ecx,NOPERATORS ; How far to look

  repne  scas	 OPERATOR_TAB[edi] ; Find byte (extended as word)
	 je	 short SCAN_DFNS_FOUND ; Jump if found

	 dec	 esi		; Back off to start of non-operator

	 clc			; Indicate failure

	 jmp	 short SCAN_DFNS_EXIT ; Join common exit

SCAN_DFNS_FOUND:
	 sub	 edi,offset DGROUP:OPERATOR_TAB[type OPERATOR_TAB] ; Convert EDI to dword offset

	 stc			; Indicate success

SCAN_DFNS_EXIT:
	 REGREST <ecx,ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SCAN_DFNS endp			; End SCAN_DFNS procedure
	 NPPROC  PARSE_DFNS -- Check For Dyadic Functions
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT!

Check for dyadic functions

// Dyadic functions
dfn ð atom
    ð lval + exp	addition
    ð lval - exp	subtraction
    ð lval * exp	multiplication
    ð lval / exp	division (with truncation towards zero)
    ð lval & exp	bitwise AND
    ð lval ^ exp	bitwise XOR

Because we have usurped the | symbol as the selector separator, it is
not available for bitwise OR.  To do bitwise OR between A and B, use
      (A & ~B) ^ B

!
COMMENT^

Boolean dyadic functions (evaluate to 0 or 1)
    ð lval == exp	is equal (eq)
    ð lval != exp	is not equal (ne)
    ð lval <  exp	is less than (lt)
    ð lval <= exp	lt or eq
    ð lval >  exp	is greater than (gt)
    ð lval >= exp	gt or eq
    ð lval && exp	logical AND
    ð lval || exp	logical OR

On entry:

Stack contains:  minimum precedence allowed
EAX	 =	 left-hand value
DS:ESI	 ==>	 command line to parse (zero-terminated)
SS:EBP	 ==>	 FORW_STR

On exit:

EAX	 =	 result
DS:ESI	 ==>	 (updated past white space)

^

PARSE_DFNS_STR struc

PARSE_DFNS_EBP dd  ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
PARSE_DFNS_MINP dd  ?		; Minimum precedence

PARSE_DFNS_STR ends

	 push	 ebp		; Prepare to address stack
	 mov	 ebp,esp	; Hello, stack

	 REGSAVE <ebx,ecx,edx,edi> ; Save registers

	 mov	 ecx,[ebp].PARSE_DFNS_MINP ; Get minimum precedence

	 mov	 ebp,[ebp].PARSE_DFNS_EBP ; Restore EBP ==> FORW_STR
PARSE_DFNS_NEXT:
	 mov	 ebx,eax	; Save as original value

; Check for optional dyadic function

	 mov	 edx,esi	; Save pointer to next token

	 call	 SCAN_DFNS	; Returns DS:ESI updated, EDI indexes OPERATOR_*
	 jnc	 short PARSE_DFNS_EXIT ; Jump if no function found

; Make sure the function has the minimum required precedence
	 xchg	 edx,esi	; Get original value
	 cmp	 ecx,OPERATOR_PREC[edi] ; Is minimum precedence above this one?
	 ja	 short PARSE_DFNS_EXIT ; Jump if so (note CF=0)

	 mov	 esi,edx	; Restore updated pointer

; If the next symbol is a left paren, use PARSE_LVAL;
; otherwise, use PARSE_VAL so we pick up cases such as 3*[40:13

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,'('         ; Izit left paren?
	 je	 short PARSE_DFNS_CALC2 ; Jump if so

	 call	 PARSE_VAL	; Parse command line for a value
	 jc	 short PARSE_DFNS_EXIT ; Jump if error (note CF=1)

	 jmp	 short PARSE_DFNS_CALCCOM ; Join common code

; Note we don't skip over the left parenthesis; PARSE_LVAL handles
; both parentheses

PARSE_DFNS_CALC2:
	 call	 PARSE_LVAL	; Parse command line for a lefthand value
	 jc	 short PARSE_DFNS_EXIT ; Jump if error (note CF=1)
PARSE_DFNS_CALCCOM:
	 mov	 edx,edi	; Save index to first operator
PARSE_DFNS_CALCCOM1:
	 push	 esi		; Save pointer to function
	 call	 SCAN_DFNS	; Get index to next symbol
	 pop	 esi		; Restore

	 jnc	 short PARSE_DFNS_LTOR ; Jump if no more functions

; If precedence of righthand function is below minimum, exit now
	 cmp	 OPERATOR_PREC[edi],ecx ; Is righthand function precedence OK?
	 jb	 short PARSE_DFNS_LTOR ; Jump if not

	 push	 ecx		; Save minimum precedence

	 mov	 ecx,OPERATOR_PREC[edx] ; Get precedence of lefthand function
	 cmp	 ecx,OPERATOR_PREC[edi] ; Izit in order?

	 pop	 ecx		; Restore
	 jnc	 short PARSE_DFNS_LTOR ; No recursion needed

; Functions are out of order with respect to precedence.
; Recurse down one level.
	 push	 ecx		; Minimum precedence
	 call	 PARSE_DFNS	; Return EAX fn VAL(ds:esi)
	 jc	 short PARSE_DFNS_EXIT ; Jump if error

; EDX is the previous lefthand function which has not been evaluated

	 jmp	 short PARSE_DFNS_CALCCOM1 ; Go around again

PARSE_DFNS_LTOR:
	 push	 ebx		; Get lefthand value from command line
	 push	 eax		; ... righthand ...
	 call	 OPERATOR_ACT[edx] ; Call the function
	 jnc	 short PARSE_DFNS_NEXT ; Jump if all went well

	 mov	 MSGOFF,offset DGROUP:OVFERR ; Save offset of error message
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Indicate something went wrong
PARSE_DFNS_EXIT:
	 REGREST <edi,edx,ecx,ebx> ; Restore

	 pop	 ebp		; Restore caller's EBP

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PARSE_DFNS endp 		; End PARSE_DFNS procedure
	 NPPROC  GET_VM -- Get current VM structure offset in BX|EAX
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Return:
CF=1 if not in Windows or VM invalid, with error offset in MSGOFF
otherwise-
BX	 Selector of VM structure (usually 30h)
EAX	 Offset of VM structure
EDX	 Base within AGROUP of BX

|

	 test	 SWATINI.MD_ATTR,@MD_WIN3 ; Are we running under Windows?
	 jz	 short GET_VM_ERR ; Not this time

	 mov	 bx,PCUR_VM_HANDLE.FSEL ; Get selector
	 or	 bx,bx		; Izit valid?
	 jz	 short GET_VM_ERR ; Jump if not

	 push	 bx		; Windows flat segment selector
	 call	 GETBASE	; Return with EAX = selector base
				; Return with CF signifcant
	 jc	 short GET_VM_ERR ; Jump if invalid

	 mov	 edx,eax	; Put in EDX for return

	 add	 eax,PCUR_VM_HANDLE.FOFF ; Add offset

	 mov	 eax,AGROUP:[eax].EDD ; Get VM structure handle (address)

	 clc			; Indicate success

	 jmp	 short GET_VM_EXIT ; Join common exit

GET_VM_ERR:
	 mov	 MSGOFF,offset DGROUP:VMERR ; Save offset of error message

	 stc			; Failed
GET_VM_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_VM endp			; End GET_VM procedure
	NPPROC	GET_VMCRS -- Get VM Client Register Struc
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Get VM Client Register Struc

On exit:

CF=1 if not in Windows or VM invalid, with error offset in MSGOFF

otherwise-

BX	=	Selector of VM control block
EAX	=	Offset of VM Client Register Struc
EDX	=	Base within AGROUP of BX

|

	call	GET_VM		; BX|EAX ==> VM structure, EDX = base of BX
	jc	short GET_VMCRS_EXIT ; Jump if not in Windows or invalid

	mov	eax,AGROUP:[eax+edx].VMcb_Client_Pointer ; Get ptr to Client Register struc

	or	eax,eax 	; Izit valid?
	jz	short GET_VMCRS_ERR ; Jump if so

	clc			; Indicate success

	jmp	short GET_VMCRS_EXIT ; Join common exit code

GET_VMCRS_ERR:
	mov	MSGOFF,offset DGROUP:VMCRSERR ; Save offset of error message

	stc			; Indicate error
GET_VMCRS_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_VMCRS endp			; End GET_VMCRS procedure
	 NPPROC  PARSE_EA -- Parse Command Line for Effective Address
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT!

Parse the command line for an effective address

// Effective address with segment/selector
ea  ð seg : exp
    ð sel | exp
    ð .EA		Effective Address #1 (or the only one)
    ð .EA2		...		  #2
    ð .GDT		GDT base address (using selector zero)
    ð .IDT		IDT ...
    ð .LDT		LDT ...
    ð .TSS		TSS ...
    ð .CMAC		address of next C MAC entry
    ð .CODE		current code display address
    ð .CSIP		address of current cs:[e]ip
    ð .DATA		current data display address
    ð .DMAC		segment of first DOS MAC entry
    ð .MDB		module database
    ð .TDB		task database
    ð .NMAC		segment of next  DOS MAC entry
    ð .PMIxx		Sel|Off of PM interrupt # xx
    ð .RMIxx		Seg:Off of RM interrupt # xx
    ð .VMIxx		Seg:Off of VM interrupt # xx
    ð .IRET		far word:dword return address on stack
			allowing a mode switch from PM to VM
    ð .RETN		near word or dword return address on stack
    ð .RETND		near dword return address on stack
    ð .RETNS		near word return address on stack
    ð .RETF		far word:word or word:dword return address on stack
    ð .RETFD		far word:dword return address on stack
    ð .RETFS		far word:word return address on stack
    ð .VM		Sel|Off of current Windows VM structure
    ð .VMCRS		current Client Register Struc in .VM
    ð .VMRET		return CS|EIP from .VMCRS
    ð .XBDA		Seg:Off of XBDA; same as ([40:0E):0
    ð .XBDA2		Seg:Off of 2ndary XBDA; same as ((S..XBDA)+[.XBDA+B4):0
    ð dotcmd ? exp	dyadic functions on dot commands (.GDT, .IDT, etc.)
			where ? is a dyadic function
    ð :[ ea		extract word:word at effective address
    ð :{ ea		...	word:dword ...
    ð |[ ea		...	word|word ...
    ð |{ ea		...	word|dword ...
    ð |G ea		...	...	   in GDT-format (using selector zero)
    ð |I ea		...	...	   in IDT-format (using IDT selector)
    ð |L ea		...	...	   in LDT-format (same as GDT-format)
    ð |T ea		...	...	   in TSS-format (using CS|EIP)
    ð symbol		Effective address of symbol


// Dyadic functions on dot commands
dotcmd ? exp
    ð S.dotcmd : O.dotcmd ? exp 	for VM addresses
    ð S.dotcmd | O.dotcmd ? exp 	... PM ...
			where ? is a dyadic function

On entry:

DS:ESI	 ==>	 command line to parse (zero-terminated)
SS:EBP	 ==>	 FORW_STR

On exit:

BX	 =	 selector/segment (if @ADDR_SEP)
EAX	 =	 offset
CX	 =	 flags
EDX	 =	 32-bit base address for BX
DS:ESI	 ==>	 (updated past white space)
CF	 =	 0 above registers are valid
	 =	 1 something went wrong

!

	 push	 edi		; Save register

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,'.'         ; Izit special symbol?
	 jne	 near ptr PARSE_EA_XSPEC ; Jump if not

	 inc	 esi		; Skip over it

; Check for a valid command

	 call	 GET_TOKN	; Get next token into CMD_TOKN

	 xor	 ebx,ebx	; Zero index register
	 mov	 ecx,NDOTCMDS	; # arguments to check
PARSE_EA_DOTCMD_NEXT:
	 mov	 edi,DOTCMD_TAB[ebx*(type DOTCMD_TAB)] ; Get location of text

	 REGSAVE <ecx,esi>	; Save for a moment

	 mov	 ecx,DOTCMD_LEN[ebx*(type DOTCMD_LEN)] ; Get length

	 cmp	 cl,CMD_TOKL	; Izit the same length?
	 jne	 short @F	; Jump if not (note ZF=0)

	 lea	 esi,CMD_TOKN	; DS:ESI ==> token
    repe cmps	 CMD_TOKN[esi],es:[edi] ; Compare 'em
				; Fall through with ZF significant
@@:
	 REGREST <esi,ecx>	; Restore
	 je	 short PARSE_EA_DOTCMD_FOUND ; Jump if it's a match

	 inc	 ebx		; Skip to next entry

	 loop	 PARSE_EA_DOTCMD_NEXT ; Jump if more entries to check

; Command not found

	 jmp	 short PARSE_EA_DOTCMD_ERR ; Jump if unknown

PARSE_EA_DOTCMD_FOUND:
	 add	 esi,DOTCMD_LEN[ebx*(type DOTCMD_LEN)] ; Skip over the keyword

	 jmp	 DOTCMD_ACT[ebx*(type DOTCMD_ACT)] ; Take appropriate action

PARSE_EA_DOTCMD_ERR:
	 cmp	 CMD_TOKL,5	; Ensure correct length for 'PMIxx' and 'VMIxx'
	 jne	 short PARSE_EA_XL5 ; Jump if not

	 cmp	 CMD_TOKN.ELO,'mp' ; Izit start of 'PMIxx'?
	 jne	 short @F	; Jump if not

	 cmp	 CMD_TOKN.EHI.LO,'i' ; Izit end of 'PMIxx'?
	 je	 near ptr PARSE_EA_PMI ; Jump if so
@@:
	 cmp	 CMD_TOKN.ELO,'mr' ; Izit start of 'RMIxx'?
	 jne	 short @F	; Jump if not

	 cmp	 CMD_TOKN.EHI.LO,'i' ; Izit end of 'RMIxx'?
	 je	 near ptr PARSE_EA_RMI ; Jump if so
@@:
	 cmp	 CMD_TOKN.ELO,'mv' ; Izit start of 'VMIxx'?
	 jne	 short @F	; Jump if not

	 cmp	 CMD_TOKN.EHI.LO,'i' ; Izit end of 'VMIxx'?
	 je	 near ptr PARSE_EA_VMI ; Jump if so
@@:
PARSE_EA_XL5:
	 jmp	 PARSE_EA_SYNTERR ; Join common syntax error code

PARSE_EA_XSPEC:
	 xor	 cx,cx		; Clear flags

	 mov	 ax,DGROUP:[esi] ; Get next two symbols

	 cmp	 ax,'[:'        ; Izit extract word:word?
	 je	 near ptr PARSE_EA_WRW ; Jump if so

	 cmp	 ax,'{:'        ; Izit extract word:dword?
	 je	 near ptr PARSE_EA_WRD ; Jump if so

	 cmp	 ax,'[|'        ; Izit extract word|word?
	 je	 near ptr PARSE_EA_WPW ; Jump if so

	 cmp	 ax,'{|'        ; Izit extract word|dword?
	 je	 near ptr PARSE_EA_WPD ; Jump if so

	 xchg	 al,ah		; Swap to get AH low
	 call	 U32_LOWERCASE	; Convert AL to lowercase
	 xchg	 al,ah		; Restore

	 cmp	 ax,'i|'        ; Izit extract IDT address?
	 je	 near ptr PARSE_EA_XTRIDT ; Jump if so

	 cmp	 ax,'g|'        ; Izit extract GDT address?
	 je	 near ptr PARSE_EA_XTRGDT ; Jump if so

	 cmp	 ax,'l|'        ; Izit extract LDT address?
	 je	 near ptr PARSE_EA_XTRLDT ; Jump if so

	 cmp	 ax,'t|'        ; Izit extract TSS address?
	 je	 near ptr PARSE_EA_XTRTSS ; Jump if so

	 call	 GET_TOKN	; Get next token into CMD_TOKN

	 push	 esi		; Save for a moment
	 lea	 esi,CMD_TOKL	; DS:ESI ==> length-value format of name
	 add	 esi,SWATDATA	; GS:ESI ==> length-value format of name
	 call	 LCL_SYMSRCH	; Search for name at GS:ESI
	 pop	 esi		; Restore
	 jnc	 short PARSE_EA_SYM ; Jump if found
				; DGROUP:EBX ==> matching entry

	 call	 PARSE_LVAL	; Parse command line for a lefthand value
	 jc	 near ptr PARSE_EA_EXIT ; Jump if too large (note CF=1)

	 push	 eax		; Save for a moment
	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	 pop	 eax		; Restore

	 cmp	 DGROUP:[esi].LO,':' ; Check for real mode separator
	 je	 short PARSE_EA_REAL ; Jump if so

	 cmp	 DGROUP:[esi].LO,'|' ; Check for protected mode separator
	 jne	 near ptr PARSE_EA_SYNTERR ; Jump if none of the above

; Disassemble in protected mode

	 mov	 cx,@ADDR_SEP or @ADDR_PM ; Mark as PM, separator
	 mov	 bx,ax		; Save selector
	 and	 ax,not (mask $PL) ; Clear the PL bits

	 cmp	 eax,0000FFFFh	; Ensure within limits
	 ja	 near ptr PARSE_EA_SELERR ; Jump if too large

; If the selector is zero, we can't afford to use GDT entry zero
; in case it's not all zero.  In particular, entry zero in a
; DOS 16/M GDT is not always zero.

	 and	 eax,eax	; Izit zero?
	 jz	 short @F	; Jump if so

	 push	 ax		; Pass selector as argument
	 call	 GETBASE	; Return with EAX = selector base
	 jc	 near ptr PARSE_EA_SELERR ; Jump if invalid selector
@@:
	 jmp	 short PARSE_EA_COM ; Join common code

PARSE_EA_REAL:
	 cmp	 eax,0000FFFFh	; Ensure within limits
	 ja	 near ptr PARSE_EA_OVFERR ; Jump if too large

	 mov	 cx,@ADDR_SEP	; Mark as VM86, separator
	 mov	 bx,ax		; Save segment number
	 shl	 eax,4-0	; Convert from paras to bytes

; We just processed a segment/selector
; EAX = base address

PARSE_EA_COM:
	 mov	 edx,eax	; Save base address
	 inc	 esi		; Skip over the separator

	 call	 PARSE_EXPR	; Parse command line for an expression
				; Return with CF significant

	 jmp	 PARSE_EA_EXIT	; Join common exit code


; We found a matching symbol in the table
; DGROUP:EBX ==> matching entry

PARSE_EA_SYM:

; Skip over the symbol

	 movzx	 eax,CMD_TOKL	; Get byte length of CMD_TOKN
	 add	 esi,eax	; Skip over the symbol

	 mov	 cx,@ADDR_SEP	; Mark as VM86, separator
	 movzx	 edx,DGROUP:[ebx].SYM_FVEC.FSEL ; Get the selector
	 shl	 edx,4-0	; Convert from paras to bytes

	 test	 DGROUP:[ebx].SYM_FLAG,@SYMFL_VM ; Check the mode
	 jnz	 short @F	; Jump if it's VM86

	 mov	 cx,@ADDR_SEP or @ADDR_PM ; Mark as PM, separator

	 mov	 ax,DGROUP:[ebx].SYM_FVEC.FSEL ; Get the selector
	 sub	 edx,edx	; Assume base 0 for 0 selector
	 or	 ax,ax		; Izit a 0 selector?
	 jz	 short @F	; Jump if so

	push	ax		; Get the selector
	 call	 GETBASE	; Return with EAX = selector base
;;;;;;;  jc	 short ???	; Jump if failed

	 mov	 edx,eax	; Copy as base address
@@:
	 mov	 eax,DGROUP:[ebx].SYM_FVEC.FOFF ; Get the offset
	 mov	 bx,DGROUP:[ebx].SYM_FVEC.FSEL ; Get the selector

	 jmp	 PARSE_EA_ENDCOM ; Join common line ending code


; .PMIxx encountered

PARSE_EA_PMI:
	 push	 esi		; Save for a moment
	 lea	 esi,CMD_TOKN[3] ; DS:ESI ==> interrupt #
	 call	 U32_HEX2DD	; Convert DS:ESI from hex to binary EAX
	 pop	 esi		; Restore
	 jc	 near ptr PARSE_EA_SYNTERR ; Jump if not hex

	 call	 GETPMI 	; Get PM interrupt address for INT AL
				; Return with BX = selector
				; ...	     EAX = offset
				; ...	     EDX = selector base
				; ...	      CX = flags
	 test	 cx,@ADDR_CODE	; Izit a code selector?
	 jz	 near ptr PARSE_EA_SYNTERR ; Jump if not

	 add	 esi,5		; Skip over 'PMIxx' text

	 jmp	 PARSE_EA_ENDCOM ; Join common line ending code


; .RMIxx encountered

; This form is used to display local interrupt handlers within
; our local IDTR.  If the corresponding interrupt handler is
; DEVINTCOM, use the .VMIxx form.

PARSE_EA_RMI:
	 test	 DEVLOAD,@DEVL_LOAD ; Izit device load?
	 jz	 short PARSE_EA_VMI ; Jump if not (treat as .VMIxx)

	 test	 AR2_FLAG,@AR2_NORMLIDT ; Is this feature disabled?
	 jnz	 short PARSE_EA_VMI ; Jump if so (treat as .VMIxx)

	 push	 esi		; Save for a moment
	 lea	 esi,CMD_TOKN[3] ; DS:ESI ==> interrupt #
	 call	 U32_HEX2DD	; Convert DS:ESI from hex to binary EAX
	 pop	 esi		; Restore
	 jc	 near ptr PARSE_EA_SYNTERR ; Jump if not hex

	 mov	 ecx,LaRM_IDT	; Get linear address of RM_IDT

	 assume  gs:INTVEC	; Tell the assembler about it
	 mov	 bx,INT00_VEC[ecx+eax*(type INT00_VEC)].VSEG ; Get segment
	 movzx	 eax,INT00_VEC[ecx+eax*(type INT00_VEC)].VOFF ; Get offset
	 assume  gs:AGROUP	; Tell the assembler about it

	 movzx	 edx,bx 	; Copy and zero to use as dword
	 shl	 edx,4-0	; Convert from paras to bytes
	 add	 edx,eax	; Add to get 32-bit linear address

	 cmp	 edx,LaDEVINTCOM ; Izit DEVINTCOM?
	 jne	 short PARSE_EA_VMI1 ; Jump if not
				; Fall through to .VMIxx code

; .VMIxx encountered

PARSE_EA_VMI:
	 push	 esi		; Save for a moment
	 lea	 esi,CMD_TOKN[3] ; DS:ESI ==> interrupt #
	 call	 U32_HEX2DD	; Convert DS:ESI from hex to binary EAX
	 pop	 esi		; Restore
	 jc	 near ptr PARSE_EA_SYNTERR ; Jump if not hex

	 assume  gs:INTVEC	; Tell the assembler about it
	 mov	 bx,INT00_VEC[eax*(type INT00_VEC)].VSEG ; Get segment
	 movzx	 eax,INT00_VEC[eax*(type INT00_VEC)].VOFF ; Get offset
	 assume  gs:AGROUP	; Tell the assembler about it
PARSE_EA_VMI1:
	 movzx	 edx,bx 	; Copy segment
	 shl	 edx,4-0	; Convert from paras to bytes

	 mov	 cx,@ADDR_SEP	; Mark as VM, separator

	 add	 esi,5		; Skip over 'VMIxx' text

	 jmp	 near ptr PARSE_EA_ENDCOM ; Join common line ending code


; .CODE encountered

PARSE_EA_CODE:
	 mov	 bx,UNASEL	; Get unassemble selector
	 mov	 eax,UNAOFF	; ...		 offset
	 mov	 edx,UNABASE	; ...		 base
	 mov	 di,UNAMODE	; ...		 mode

	 jmp	 short PARSE_EA_CDCOM ; Join common code


; .CSIP encountered

PARSE_EA_CSIP:
	 mov	 bx,[ebp].FORW_CS ; Use CS
	 mov	 cx,@ADDR_SEP	; Mark as separator
	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	 jnz	 short @F	; Jump if so

	 or	 cx,@ADDR_PM	; Mark as PM
@@:
	 mov	 eax,[ebp].FORW_EIP ; Get current EIP
	 mov	 edx,[ebp-@BPBACK].BACK_CS.DTR_BASE ; Get caller's base

	 jmp	 near ptr PARSE_EA_ENDCOM ; Join common line ending code


; .DATA encountered

PARSE_EA_DATA:
	 mov	 bx,MEMSEL	; Get data selector
	 mov	 eax,MEMOFF	; ...	   offset
	 mov	 edx,MEMBASE	; ...	   base
	 mov	 di,MEMMODE	; ...	   mode
PARSE_EA_CDCOM:

; Translate from xxxMODE equates to @ADDR_xxx equates

	 mov	 cx,@ADDR_SEP	; Mark as present

	 test	 di,@MODE_VM	; Izit in VM?
	 jnz	 short @F	; Jump if so

	 or	 cx,@ADDR_PM	; Mark as in PM
@@:
	 jmp	 PARSE_EA_ENDCOM ; Join common line ending code


; .CMAC encountered

PARSE_EA_CMAC:
	 mov	 edx,MEMBASE	; Get current seg/sel base
	 mov	 ebx,MEMOFF	; Get offset
	 movzx	 eax,AGROUP:[ebx+edx].ELO ; Get byte count of entry
	 and	 ax,not @BIT0	; Clear the available bit
	 add	 eax,2		; Include count entry
	 add	 eax,ebx	; Add size of this entry to next entry
	 and	 eax,MEMMASK	; Truncate as appropriate
	 mov	 bx,MEMSEL	; Get surrent segment/selector

; Assume VM86 mode

	 mov	 cx,@ADDR_SEP	; Mark as VM86, separator

	 test	 MEMMODE,@MODE_VM ; Izit in VM86 mode?
	 jnz	 short @F	; Jump if so

	 or	 cx,@ADDR_PM	; Mark as PM, separator
@@:
	 jmp	 PARSE_EA_ENDCOM ; Join common line ending code


; .DMAC encountered

PARSE_EA_DMAC:
	 mov	 eax,LaLSTLST	; Get linear address of list of lists
	 dec	 eax		; Back off to segment # of 1st MAC entry
	 dec	 eax		; ...
	 mov	 bx,AGROUP:[eax] ; Get the segment #
	 mov	 cx,@ADDR_SEP	; Mark as VM86, separator
	 xor	 eax,eax	; Offset is zero
	 movzx	 edx,bx 	; Copy segment #
	 shl	 edx,4-0	; Convert from paras to bytes

	 jmp	 PARSE_EA_ENDCOM ; Join common line ending code


; .EA encountered

PARSE_EA_EA:
	 mov	 bx,EA1SEL	; Get EA1 selector
	 mov	 eax,EA1OFF	; ...	  offset
	 mov	 edx,EA1BASE	; ...	  base
	 mov	 cx,EA1MODE	; ...	  mode

	 jmp	 short PARSE_EA_EACOM ; Join common EA code


; .EA2 encountered

PARSE_EA_EA2:
	 mov	 bx,EA2SEL	; Get EA2 selector
	 mov	 eax,EA2OFF	; ...	  offset
	 mov	 edx,EA2BASE	; ...	  base
	 mov	 cx,EA2MODE	; ...	  mode
PARSE_EA_EACOM:
	 test	 cx,@MODE_NEW	; Izit valid?
	 jnz	 short PARSE_EA_EAERR ; Jump if not

	 test	 cx,@MODE_VM	; Izit in VM86 mode?
	 mov	 cx,@ADDR_SEP	; Mark as VM86, separator
	 jnz	 short @F	; Jump if so

	 or	 cx,@ADDR_PM	; Mark as PM, separator
@@:
	 jmp	 PARSE_EA_ENDCOM ; Join common line ending code


PARSE_EA_EAERR:
	 mov	 MSGOFF,offset DGROUP:NOEADDR ; Save offset of error message

	 jmp	 PARSE_EA_ERR	; Join common error code


; .TDB encountered (Task Database)

PARSE_EA_TDB:
	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	jz	near ptr PARSE_EA_NOWINERR ; Jump if not

	call	GetCurTDBSel	; Get current task selector
	jc	near ptr PARSE_EA_SELERR ; Jump if invalid

	jmp	short PARSE_EA_xDBCOM ; Join common code


; .MDB encountered (Module Database)

PARSE_EA_MDB:
	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	jz	near ptr PARSE_EA_NOWINERR ; Jump if not

	call	GetCurMDBSel	; Get current module selector
	jc	near ptr PARSE_EA_SELERR ; Jump if invalid
PARSE_EA_xDBCOM:
	mov	cx,@ADDR_SEP or @ADDR_PM ; Mark as PM, separator
	mov	bx,ax		; Copy selector

	push	bx	       ; Pass the selector
	call	GETBASE        ; Returns CF significant, EAX = selector base
	jc	short @F       ; Jump if invalid

	mov	edx,eax        ; Get selector base
	xor	eax,eax        ; PM offset is zero

	jmp	PARSE_EA_ENDCOM ; Join common line ending code


; .NMAC encountered (Next MAC entry)

PARSE_EA_NMAC:
	 mov	 ebx,MEMBASE	; Get current seg/sel base
	 add	 ebx,MEMOFF	; Add in offset
	 mov	 ax,AGROUP:[ebx].MAC_NPAR ; Get para count of entry
	 inc	 ax		; Include MAC entry
	 shr	 ebx,(4-0)	; Convert address from bytes to paras
	 add	 bx,ax		; Add size of this entry to current segment

	 movzx	 edx,bx 	; Copy segment #
	 shl	 edx,4-0	; Convert from paras to bytes

; Assume VM86 mode

	 xor	 eax,eax	; Offset is zero
	 mov	 cx,@ADDR_SEP	; Mark as VM86, separator

	 test	 MEMMODE,@MODE_VM ; Izit in VM86 mode?
	 jnz	 short @F	; Jump if so

	 xchg	 eax,edx	; PM sel base is 0, offset is linear addr
	 xor	 bx,bx		; Use selector zero
	 or	 cx,@ADDR_PM	; Mark as PM, separator
@@:
	 jmp	 short PARSE_EA_ENDCOM ; Join common line ending code


; .XBDA encountered

PARSE_EA_XBDA:
	 mov	 bx,AGROUP:[040Eh].ELO ; Get segment of XBDA

	 cmp	 bx,1		; Izit valid?
	 jnb	 short PARSE_EA_XBDACOM ; Join common code for .XBDA if OK
PARSE_EA_XBDAERRCOM:
	 mov	 MSGOFF,offset DGROUP:NOXBDA ; Save offset of error message

	 jmp	 PARSE_EA_ERR  ; Join common error code


; .XBDA2 encountered

PARSE_EA_XBDA2:
	 mov	 bx,AGROUP:[040Eh].ELO ; Get segment of XBDA

	 cmp	 bx,1		; Izit valid?
	 jb	 short PARSE_EA_XBDAERRCOM ; Join common XBDA error code

	 movzx	 edx,bx 	; Copy segment #
	 shl	 edx,4-0	; Convert from paras to bytes
	 add	 bx,AGROUP:[edx+00B4h].ELO ; Add XBDA2 segment
PARSE_EA_XBDACOM:
	 mov	 cx,@ADDR_SEP	; Mark as VM86, separator
	 xor	 eax,eax	; Offset is zero
	 movzx	 edx,bx 	; Copy segment #
	 shl	 edx,4-0	; Convert from paras to bytes

	 jmp	 short PARSE_EA_ENDCOM ; Join common line ending code


; .GDT encountered

PARSE_EA_GDT:
	 mov	 eax,[ebp-@BPBACK].BACK_GDT.DTR_BASE ; Get GDTR base

	 jmp	 short PARSE_EA_xDTCOM ; Join common xDT code


; .IDT encountered

PARSE_EA_IDT:
	 mov	 eax,[ebp-@BPBACK].BACK_IDT.DTR_BASE ; Get IDTR base

	 jmp	 short PARSE_EA_xDTCOM ; Join common xDT code


; .LDT encountered

PARSE_EA_LDT:
	 mov	 eax,[ebp-@BPBACK].BACK_LDT.DTR_BASE ; Get LDTR base

	 jmp	 short PARSE_EA_xDTCOM ; Join common xDT code


; .TSS encountered

PARSE_EA_TSS:
	 mov	 eax,[ebp-@BPBACK].BACK_TR.DTR_BASE ; Get TSS base
PARSE_EA_xDTCOM:
	 xor	 bx,bx		; Use selector zero
	 mov	 cx,@ADDR_SEP or @ADDR_PM ; Mark as PM, separator
	 xor	 edx,edx	; Mark base address for BX as zero
PARSE_EA_ENDCOM:
	 PUSHD	 @ADDRFN_PREC	; Minimum precedence
	 call	 PARSE_DFNS	; Check for dyadic functions
				; Return with CF significant
	 jmp	 PARSE_EA_EXIT	; Join common exit code


; .VM encountered

PARSE_EA_VM:
	 call	 GET_VM 	; BX|EAX ==> VM structure, EDX = base of BX
				; Return with CF significant
	 jmp	 PARSE_EA_VMCOMN ; Join common code


; .VMCRS encountered

PARSE_EA_VMCRS:
	 call	 GET_VMCRS	; BX|EAX ==> VM CRS, EDX = selector base
				; Return with CF significant
	 jmp	 PARSE_EA_VMCOMN ; Join common code


; .VMRET encountered

PARSE_EA_VMRET:
	call	GET_VMCRS      ; BX|EAX ==> VM CRS, EDX = stack selector base
	jc	short PARSE_EA_VMCOMN ; Jump if not in Windows or invalid

	mov	ecx,AGROUP:[eax+edx].Client_EIP ; Get putative return EIP
	mov	bx,AGROUP:[eax+edx].Client_CS ; Get putative return CS

	test	AGROUP:[eax+edx].Client_EFlags.EHI,mask $VM ; Izit in VM86 mode?
	jz	short @F	; Jump if not

	movzx	edx,bx		; Copy segment
	shl	edx,4-0 	; Convert from paras to bytes
	mov	eax,ecx 	; Copy offset (EIP)

	mov	cx,@ADDR_SEP	; Mark as VM, separator

	jmp	PARSE_EA_ENDCOM ; Join common exit code

@@:
	 push	 bx		; Pass stack selector
	 call	 GETBASE	; Returns CF significant, EAX = selector base
	 jc	 short @F	; Jump if invalid

	 mov	 edx,eax	; Get selector base
	 mov	 eax,ecx	; Get return EIP

;;;;;;;  clc			; Indicate success

	 jmp	 short PARSE_EA_VMCOMN ; Join common code

@@:
; Try the other offset (150h for emulated INTs)
	 add	 edx,150h-50h	; Address return CS|EIP (via INT)

	 mov	 bx,AGROUP:[edx].FSEL ; Get return CS
	 mov	 edx,AGROUP:[edx].FOFF ; Get return EIP

	 or	 bx,bx		; Izit valid?
	 jz	 short PARSE_EA_VMRETERR ; Jump if not

	 push	 bx		; Pass stack selector
	 call	 GETBASE	; Returns CF significant, EAX = selector base
	 jc	 short PARSE_EA_VMRETERR ; Jump if invalid

	 xchg	 edx,eax	; Move base into EDX for return, offset in EAX

	 jmp	 short PARSE_EA_VMCOMN ; Join common code (CF significant)

PARSE_EA_VMRETERR:
	 mov	 MSGOFF,offset DGROUP:VMRETERR ; Set error message

	 stc			; Indicate failure

;;;;;;;  jmp	 PARSE_EA_VMCOMN ; Join common code

; CF significant, BX, EAX, and EDX set properly
; If error, MSGOFF already contains the relevant message offset
PARSE_EA_VMCOMN:
	 jc	 near ptr PARSE_EA_ERR ; Jump if not in Windows or invalid

	 mov	 cx,@ADDR_SEP or @ADDR_PM ; Mark as PM, separator

	 jmp	 PARSE_EA_ENDCOM ; Join common exit code


; Extract word:word from effective address

PARSE_EA_WRW:
	 add	 esi,2		; Skip over symbols

	 call	 PARSE_EA	; Parse command line for an effective address
	 jc	 near ptr PARSE_EA_EXIT ; Jump if something went wrong (note CF=1)
				; BX  = selector/segment (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = 32-bit base address for BX

	 mov	 bx,AGROUP:[edx+eax].VSEG ; Get the segment
	 movzx	 eax,AGROUP:[edx+eax].VOFF ; Get the offset

	 jmp	 short PARSE_EA_VMCOM ; Join common PM code


; Extract word:dword from effective address

PARSE_EA_WRD:
	 add	 esi,2		; Skip over symbols

	 call	 PARSE_EA	; Parse command line for an effective address
	 jc	 near ptr PARSE_EA_EXIT ; Jump if something went wrong (note CF=1)
				; BX  = selector/segment (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = 32-bit base address for BX

	 mov	 bx,AGROUP:[edx+eax].FSEL ; Get the segment
	 mov	 eax,AGROUP:[edx+eax].FOFF ; Get the offset
PARSE_EA_VMCOM:
	 mov	 cx,@ADDR_SEP	; Mark as VM86, separator
	 movzx	 edx,bx 	; Copy segment
	 shl	 edx,4-0	; Convert from paras to bytes

	 clc			; Mark as all went well

	 jmp	 PARSE_EA_EXIT ; Join common exit code


; Extract GDT-format PM address from effective address
; Extract LDT-format PM address from effective address

PARSE_EA_XTRGDT:
PARSE_EA_XTRLDT:
	 add	 esi,2		; Skip over symbols

	 call	 PARSE_EA	; Parse command line for an effective address
	 jc	 near ptr PARSE_EA_EXIT ; Jump if something went wrong (note CF=1)
				; BX  = selector/segment (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = 32-bit base address for BX

	 xor	 bx,bx		; Use selector zero
	 mov	 cx,@ADDR_SEP or @ADDR_PM ; Mark as PM, separator

	 push	 AGROUP:[edx+eax].DESC_BASE01 ; Save bytes 0-1
	 mov	 eax,AGROUP:[edx+eax].DESC_BASE2.EDD ; Put bytes 2-3 in 0-3
	 rol	 eax,8		; Put bytes 2-3 in 1-0
	 xchg	 al,ah		; ...		in 0-1
	 shl	 eax,16 	; ...		in 2-3
	 pop	 ax		; Restore as low-order offset

	 jmp	 PARSE_EA_PMCOM ; Join common PM code


; Extract IDT-format PM address from effective address

PARSE_EA_XTRIDT:
	 add	 esi,2		; Skip over symbols

	 call	 PARSE_EA	; Parse command line for an effective address
	 jc	 near ptr PARSE_EA_EXIT ; Jump if something went wrong (note CF=1)
				; BX  = selector/segment (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = 32-bit base address for BX

	 mov	 bx,AGROUP:[edx+eax].IDT_SELECT ; Get the selector
	 mov	 cx,@ADDR_SEP or @ADDR_PM ; Mark as PM, separator

	 push	 AGROUP:[edx+eax].IDT_OFFLO ; Save low-order offset
	 mov	 ax,AGROUP:[edx+eax].IDT_OFFHI ; Get high-order offset
	 shl	 eax,16 	; Shift to high-order word
	 pop	 ax		; Restore as low-order offset

	 jmp	 short PARSE_EA_PMCOM ; Join common PM code


; Extract TSS-format PM address from effective address

PARSE_EA_XTRTSS:
	 add	 esi,2		; Skip over symbols

	 call	 PARSE_EA	; Parse command line for an effective address
	 jc	 near ptr PARSE_EA_EXIT ; Jump if something went wrong (note CF=1)
				; BX  = selector/segment (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = 32-bit base address for BX

; Set return mode depending upon the VM bit in TSS_EFL

	 mov	 cx,@ADDR_SEP	; Mark as VM86, separator

	 test	 AGROUP:[edx+eax].TSS_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jnz	 short @F	; Jump if so

	 mov	 cx,@ADDR_SEP or @ADDR_PM ; Mark as PM, separator
@@:
	 mov	 bx,AGROUP:[edx+eax].TSS_CS ; Get the selector
	 mov	 eax,AGROUP:[edx+eax].TSS_EIP ; Get the offset

	 jmp	 short PARSE_EA_PMCOM ; Join common PM code


; Extract word|word from effective address

PARSE_EA_WPW:
	 add	 esi,2		; Skip over symbols

	 call	 PARSE_EA	; Parse command line for an effective address
	 jc	 near ptr PARSE_EA_EXIT ; Jump if something went wrong (note CF=1)
				; BX  = selector/segment (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = 32-bit base address for BX

	 mov	 bx,AGROUP:[edx+eax].VSEG ; Get the segment
	 movzx	 eax,AGROUP:[edx+eax].VOFF ; Get the offset

	 jmp	 short PARSE_EA_PMCOM ; Join common PM code


; Extract word|dword from effective address

PARSE_EA_WPD:
	 add	 esi,2		; Skip over symbols

	 call	 PARSE_EA	; Parse command line for an effective address
	 jc	 near ptr PARSE_EA_EXIT ; Jump if something went wrong (note CF=1)
				; BX  = selector/segment (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = 32-bit base address for BX

	 mov	 bx,AGROUP:[edx+eax].FSEL ; Get the segment
	 mov	 eax,AGROUP:[edx+eax].FOFF ; Get the offset
PARSE_EA_PMCOM:
	 mov	 cx,@ADDR_SEP or @ADDR_PM ; Mark as PM, separator
	 movzx	 edx,bx 	; Save selector
	 and	 dx,not (mask $PL) ; Clear the PL bits

; If the selector is zero, we can't afford to use GDT entry zero
; in case it's not all zero.  In particular, entry zero in a
; DOS 16/M GDT is not always zero.

	 and	 edx,edx	; Izit zero?
	 jz	 near ptr PARSE_EA_EXIT ; Jump if so (note CF=0)

	 push	 eax		; Save the offset

	 push	 dx		; Pass selector as argument
	 call	 GETBASE	; Return with EAX = selector base
				; Return with CF signifcant
	 mov	 edx,eax	; Save as base address

	 pop	 eax		; Restore
	 jc	 near ptr PARSE_EA_SELERR ; Jump if invalid selector

	 jmp	 PARSE_EA_EXIT	; Join common exit code


; .RETN encountered
; Extract near word or dword (as per D-bit in CS) from bottom of stack
; and VM or PM depending upon the VM bit in EFL

PARSE_EA_RETN:
	 call	 PARSE_RETN	; Parse RETN address from stack
	 jc	 near ptr PARSE_EA_SELERR ; Jump if invalid selector

	 jmp	 PARSE_EA_EXIT	; Join common exit code


; .RETF encountered
; Extract far word:dword or word:word (as per D-bit in CS) from bottom of stack
; and VM or PM depending upon the VM bit in EFL

PARSE_EA_RETF:
	 call	 PARSE_RETF	; Parse RETF address from stack
	 jc	 near ptr PARSE_EA_SELERR ; Jump if invalid selector

	 jmp	 PARSE_EA_EXIT	; Join common exit code


; .RETFD encountered
; Extract far word:dword from bottom of stack
; and VM or PM depending upon the VM bit in EFL

PARSE_EA_RETFD:
	 mov	 edi,STACK_eSP	; Get linear address of the caller's stack
	 mov	 eax,AGROUP:[edi].IRETD_EIP ; Get dword offset
	 mov	 bx,AGROUP:[edi].IRETD_CS ; Get word segment/selector

	 mov	 cx,@ADDR_SEP	; Mark as VM86, separator
	 movzx	 edx,bx 	; Copy, assuming segment
	 shl	 edx,4-0	; Convert from paras to bytes

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Check mode
	 jnz	 short @F	; Jump if VM86

	 mov	 ecx,eax	; Copy offset

	 push	 bx		; Pass selector as argument
	 call	 GETBASE	; Return with EAX = selector base
	 jc	 near ptr PARSE_EA_SELERR ; Jump if invalid selector

	 mov	 edx,eax	; Save base address
	 mov	 eax,ecx	; Restore offset
	 mov	 cx,@ADDR_SEP or @ADDR_PM ; Mark as PM, separator
@@:
	 clc			; Mark as all went well

	 jmp	 PARSE_EA_EXIT	; Join common exit code


; .RETFS encountered
; Extract word:word from bottom of stack
; and VM or PM depending upon the VM bit in EFL

PARSE_EA_RETFS:
	 mov	 edi,STACK_eSP	; Get linear address of the caller's stack
	 movzx	 eax,AGROUP:[edi].IRET_IP ; Get word offset
	 mov	 bx,AGROUP:[edi].IRET_CS ; Get word segment/selector

	 mov	 cx,@ADDR_SEP	; Mark as VM86, separator
	 movzx	 edx,bx 	; Copy, assuming segment
	 shl	 edx,4-0	; Convert from paras to bytes

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Check mode
	 jnz	 short @F	; Jump if VM86

	 mov	 ecx,eax	; Copy offset

	 push	 bx		; Pass selector as argument
	 call	 GETBASE	; Return with EAX = selector base
	 jc	 near ptr PARSE_EA_SELERR ; Jump if invalid selector

	 mov	 edx,eax	; Save base address
	 mov	 eax,ecx	; Restore offset
	 mov	 cx,@ADDR_SEP or @ADDR_PM ; Mark as PM, separator
@@:
	 clc			; Mark as all went well

	 jmp	 PARSE_EA_EXIT	; Join common exit code


; .RETND encountered
; Extract near dword from bottom of stack
; and VM or PM depending upon the VM bit in EFL

PARSE_EA_RETND:
	 mov	 edi,STACK_eSP	; Get linear address of the caller's stack
	 mov	 eax,AGROUP:[edi].IRETD_EIP ; Get dword offset
	 mov	 bx,[ebp].FORW_CS ; Get caller's CS
	 mov	 edx,[ebp-@BPBACK].BACK_CS.DTR_BASE ; Get caller's base
	 mov	 cx,@ADDR_SEP	; Mark as VM86, separator

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Check mode
	 jnz	 short @F	; Jump if VM86

	 mov	 cx,@ADDR_SEP or @ADDR_PM ; Mark as PM, separator
@@:
	 clc			; Mark as all went well

	 jmp	 PARSE_EA_EXIT	; Join common exit code


; .RETNS encountered
; Extract near word from bottom of stack
; and VM or PM depending upon the VM bit in EFL

PARSE_EA_RETNS:
	 mov	 edi,STACK_eSP	; Get linear address of the caller's stack
	 movzx	 eax,AGROUP:[edi].IRET_IP ; Get word offset
	 mov	 bx,[ebp].FORW_CS ; Get caller's CS
	 mov	 edx,[ebp-@BPBACK].BACK_CS.DTR_BASE ; Get caller's base
	 mov	 cx,@ADDR_SEP	; Mark as VM86, separator

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Check mode
	 jnz	 short @F	; Jump if VM86

	 mov	 cx,@ADDR_SEP or @ADDR_PM ; Mark as PM, separator
@@:
	 clc			; Mark as all went well

	 jmp	 short PARSE_EA_EXIT ; Join common exit code


; .IRET/.IRETD encountered
; Extract far word:dword from bottom of stack
; allowing a mode switch from PM to VM
; Note that there is no .IRETS as it's equivalent to .RETF

PARSE_EA_IRET:
PARSE_EA_IRETD:

; If the current mode is VM, treat this as a .RETF as there's no
; mode switch from VM to PM via IRET/D.

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Check mode
	 jnz	 near ptr PARSE_RETF ; Jump if VM86

	 mov	 edi,STACK_eSP	; Get linear address of the caller's stack
	 mov	 eax,AGROUP:[edi].IRETD_EIP ; Get dword offset
	 mov	 bx,AGROUP:[edi].IRETD_CS ; Get word segment/selector

	 mov	 cx,@ADDR_SEP	; Mark as VM86, separator
	 movzx	 edx,bx 	; Copy segment
	 shl	 edx,4-0	; Convert from paras to bytes

	 test	 AGROUP:[edi].IRETD_EFL.EHI,mask $VM ; Check mode
	 jnz	 short @F	; Jump if VM86

	 mov	 ecx,eax	; Copy offset

	 push	 bx		; Pass selector as argument
	 call	 GETBASE	; Return with EAX = selector base
	 jc	 short PARSE_EA_SELERR ; Jump if invalid selector

	 mov	 edx,eax	; Save base address
	 mov	 eax,ecx	; Restore offset
	 mov	 cx,@ADDR_SEP or @ADDR_PM ; Mark as PM, separator
@@:
	 clc			; Mark as all went well

	 jmp	 PARSE_EA_EXIT	; Join common exit code


PARSE_EA_NOWINERR:
	 mov	 MSGOFF,offset DGROUP:NOWINERR ; Save offset of error message

	 jmp	 short PARSE_EA_ERR ; Join common code

PARSE_EA_SELERR:
	 mov	 MSGOFF,offset DGROUP:SELERR ; Save offset of error message

	 jmp	 short PARSE_EA_ERR ; Join common code

PARSE_EA_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	 jmp	 short PARSE_EA_ERR ; Join common code

PARSE_EA_OVFERR:
	 mov	 MSGOFF,offset DGROUP:OVFERR ; Save offset of error message
PARSE_EA_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Indicate something went wrong
PARSE_EA_EXIT:
	 pop	 edi		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PARSE_EA endp			; End PARSE_EA procedure
	 NPPROC  PARSE_RETF -- Parse RETF Address From The Stack
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Parse RETF address from the stack

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

BX	 =	 selector/segment (if @ADDR_SEP)
EAX	 =	 offset
CX	 =	 flags
EDX	 =	 32-bit base address for BX
CF	 =	 0 above registers are valid
	 =	 1 something went wrong

|

	 REGSAVE <edi>		; Save register

	 mov	 edi,STACK_eSP	; Get linear address of the caller's stack
	 mov	 eax,AGROUP:[edi].IRETD_EIP ; Get dword offset
	 mov	 bx,AGROUP:[edi].IRETD_CS ; Get word segment/selector

	 test	 CUR_INSTR_ARW.HI,mask $DTE_B ; Check for USE32
	 jnz	 short @F	; Jump if so

	 movzx	 eax,AGROUP:[edi].IRET_IP ; Get word offset
	 mov	 bx,AGROUP:[edi].IRET_CS ; Get word segment/selector
@@:
	 mov	 cx,@ADDR_SEP	; Mark as VM86, separator
	 movzx	 edx,bx 	; Copy, assuming segment
	 shl	 edx,4-0	; Convert from paras to bytes

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Check mode
	 jnz	 short @F	; Jump if VM86 (note CF=0)

	 mov	 ecx,eax	; Copy offset

	 push	 bx		; Pass selector as argument
	 call	 GETBASE	; Return with EAX = selector base
	 jc	 short @F	; Jump if invalid selector (note CF=1)

	 mov	 edx,eax	; Save base address
	 mov	 eax,ecx	; Restore offset
	 mov	 cx,@ADDR_SEP or @ADDR_PM ; Mark as PM, separator

	 clc			; Mark as all went well
@@:
	 REGREST <edi>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PARSE_RETF endp 		; End PARSE_RETF procedure
	 NPPROC  PARSE_RETN -- Parse RETN Address From The Stack
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Parse RETN address from the stack

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

BX	 =	 selector/segment (if @ADDR_SEP)
EAX	 =	 offset
CX	 =	 flags
EDX	 =	 32-bit base address for BX
CF	 =	 0 above registers are valid
	 =	 1 something went wrong

|

	 REGSAVE <edi>		; Save register

	 mov	 edi,STACK_eSP	; Get linear address of the caller's stack
	 mov	 eax,AGROUP:[edi].IRETD_EIP ; Get dword offset

	 test	 CUR_INSTR_ARW.HI,mask $DTE_B ; Check for USE32
	 jnz	 short @F	; Jump if so

	 movzx	 eax,ax 	; Convert to word offset
@@:
	 mov	 bx,[ebp].FORW_CS ; Get caller's CS
	 mov	 edx,[ebp-@BPBACK].BACK_CS.DTR_BASE ; Get caller's base
	 mov	 cx,@ADDR_SEP	; Mark as VM86, separator

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Check mode
	 jnz	 short @F	; Jump if VM86

	 mov	 cx,@ADDR_SEP or @ADDR_PM ; Mark as PM, separator
@@:
	 clc			; Mark as all went well

	 REGREST <edi>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PARSE_RETN endp 		; End PARSE_RETN procedure
	 NPPROC  PARSE_ADDR -- Parse Command Line For An Address
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT!

Parse the command line for an address

// Addresses
addrð exp		using default segment/selector as per specific command
    ð ea

On entry:

DS:ESI	 ==>	 command line to parse (zero-terminated)
SS:EBP	 ==>	 FORW_STR

On exit:

BX	 =	 selector/segment (if @ADDR_SEP)
EAX	 =	 offset
CX	 =	 flags
EDX	 =	 32-bit base address for BX
DS:ESI	 ==>	 (updated past white space)
CF	 =	 0 above registers are valid
	 =	 1 something went wrong

!

	 push	 edi		; Save register

; Distinguish between EXP and EA
; Assume it's an effective address

	 mov	 edi,esi	; Save offset

	 call	 PARSE_EA	; Parse command line for an effective address
	 jnc	 short PARSE_ADDR_EXIT ; Jump if valid (note CF=0)
				; BX  = selector/segment (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = 32-bit base address for BX

; If we encountered a Syntax Error, try again as an expression

	 cmp	 MSGOFF,offset DGROUP:SYNTERR ; Izit a syntax error?
	 stc			; Assume not
	 jne	 short PARSE_ADDR_EXIT ; Jump if not

	 and	 LC2_FLAG,not @LC2_MSG ; Mark as no message to display
	 mov	 esi,edi	; Restore offset
	 xor	 cx,cx		; Clear flags
	 call	 PARSE_EXPR	; Parse command line for an expression
				; Return with CF significant
PARSE_ADDR_EXIT:
	 pop	 edi		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PARSE_ADDR endp 		; End PARSE_ADDR procedure
	 NPPROC  CLEAR_CMDLINE -- Clear the Command Line
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Clear the command line

|

	 REGSAVE <eax,ecx,edi>	; Save registers

	 lea	 edi,CMD_LINE	; ES:EDI ==> command line
	 mov	 ecx,CMD_LINE_LEN ; Length of ...
	 mov	 al,' '         ; Filler
     rep stos	 CMD_LINE[edi]	; Fill with blanks

	 mov	 CMDHIGH,0	; Reset command line high position

; Move cursor to column 0

	 mov	 CURPOSN.LO,0	; Reset cursor column to zero

	 test	 LC3_FLAG,@LC3_INTERNAL ; Are we executing an internal command?
	 jnz	 short CLEAR_CMDLINE_EXIT ; Jump if so

; Display the command line

	 call	 DISP_CMDLINE	; Display the command line

; Move the cursor

	 push	 CURPOSN	; Get cursor position
	 call	 SET_CURPOS	; Set it

	 push	 CURTYPE	; Get cursor type
	 call	 SET_CURTYP	; Set it
CLEAR_CMDLINE_EXIT:
	 REGREST <edi,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLEAR_CMDLINE endp		; End CLEAR_CMDLINE procedure
	 NPPROC  ENDOF_CMDLINE -- Goto the End of the Command Line
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Goto the end of the command line

On exit:

ES:EDI	 ==>	 end of the command line

|

	 mov	 edi,CMDHIGH	; Get high water mark of command line

; Delete trailing blanks

@@:
	 and	 edi,edi	; Izit the start?
	 jz	 short @F	; Jump if so

	 cmp	 CMD_LINE[edi],' ' ; Izit a blank?
	 jne	 short @F	; Jump if not

	 dec	 edi		; Back off over blank

	 jmp	 short @B	; Go around again

@@:
	 lea	 edi,CMD_LINE[edi+1] ; ES:EDI ==> next byte on command line

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENDOF_CMDLINE endp		; End ENDOF_CMDLINE procedure
	NPPROC	COPYTO_CMDLINE -- Copy ASCIIZ String to Command Line
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Copy an ASCIIZ strint to the command line.

On entry:

DS:ESI	==>	ASCIIZ string to copy

|

	REGSAVE <eax,ecx,esi,edi> ; Save register

	call	ENDOF_CMDLINE	; Return with ES:EDI ==> end of the command line
	mov	ecx,edi 	; Copy to count register
	sub	ecx,offset DGROUP:CMD_LINE ; Less start to get length
	sub	ecx,CMD_LINE_LEN ; Less length
	neg	ecx		; ...to get remaining size
	jecxz	COPYTO_CMDLINE_EXIT ; Jump if no room
@@:
	lods	ds:[esi].LO	; Get next character
	stos	es:[edi].LO	; Save in command line

	and	al,al		; Izit EOL?
	loopne	@B		; Jump if not and still room
COPYTO_CMDLINE_EXIT:
	REGREST <edi,esi,ecx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COPYTO_CMDLINE endp		; End COPYTO_CMDLINE procedure
	 NPPROC  CMD_WHITE -- Skip Over Command Line White Space
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over command line white space

On entry:

DS:ESI	 ==>	 next character on command line

On exit:

DS:ESI	 ==>	 (updated)

|

@@:
	 lods	 ds:[esi].LO	; Get next character

	 cmp	 al,' '         ; Izit a blank?
	 je	 short @B	; Jump if so

	 cmp	 al,TAB 	; Izit a TAB?
	 je	 short @B	; Jump if so

	 dec	 esi		; Back off to non-white space

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_WHITE endp			; End CMD_WHITE procedure
	 NPPROC  CMD_BLACK -- Skip Over Command Line Non-White Space
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over command line until white space or EOL.  We need to handle
parenthetic expressions with embedded white space.

On entry:

DS:ESI	 ==>	 last character of token

On exit:

DS:ESI	 ==>	 (updated)

|

	 REGSAVE <ecx>		; Save

	 sub	 ecx,ecx	; Initialize parenthetic nesting level
CMD_BLACK_NEXT:
	 lods	 ds:[esi].LO	; Get next character

	 cmp	 al,' '         ; Izit a blank?
	 je	 short CMD_BLACK_WS ; Jump if so

	 cmp	 al,TAB 	; Izit a TAB?
	 je	 short CMD_BLACK_WS ; Jump if so

	 or	 al,al		; Izit the end of the line?
	 jz	 short CMD_BLACK_EXIT ; Bail out if so

	 cmp	 al,'('         ; Izit a new level?
	 jne	 short @F	; Jump if not

	 inc	 ecx		; Increment nesting counter
	 jmp	 short CMD_BLACK_NEXT ; Go around again
@@:
	 cmp	 al,')'         ; Izit the end of a level?
	 jne	 short CMD_BLACK_NEXT ; Go around again if not

	 jecxz	 CMD_BLACK_NEXT ; Ignore spurious ending parens
	 dec	 ecx		; End level
	 jmp	 short CMD_BLACK_NEXT ; Go around again

CMD_BLACK_WS:
	 or	 ecx,ecx	; Are we in a parenthetic expression?
	 jnz	 short CMD_BLACK_NEXT ; Jump if not
CMD_BLACK_EXIT:
	 REGREST <ecx>		; Restore

	 sub	 esi,2		; Back off to last character - 1
	 lods	 ds:[esi].LO	; Return last character in AL

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BLACK endp			; End CMD_BLACK procedure

HEX2DD_MAC macro PREF

	 NPPROC  PREF&HEX2DD -- Convert DS:ESI to Binary
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert input from hex to binary

On entry:

DS:ESI	 ==>	 input

On exit:

CF	 =	 0 if all went well
	 =	 1 if overflow occurred

DS:ESI	 ==>	 (updated)
EAX	 =	 converted value

|

	 REGSAVE <ecx>		; Save register

	 mov	 ecx,16 	; Hex conversion
	 call	 PREF&BASE2BIN	; Call common code

	 REGREST <ecx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&HEX2DD endp		; End PREF&HEX2DD procedure

	 endm			; HEX2DD_MAC

	 HEX2DD_MAC U32_	; Define in PGROUP

BASE2BIN_MAC macro PREF,ESGRP

	 NPPROC  PREF&BASE2BIN -- Convert From Specified Base to Binary
	 assume  ds:nothing,es:ESGRP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BASE2BIN -- Convert the number at DS:ESI in base ECX to binary.
The converted # is returned in EAX.

On entry:

ECX	 =	 number base
DS:ESI	 ==>	 input save area

On exit:

CF	 =	 1 if overflow
	 =	 0 if OK
EAX	 =	 converted #

|

	 REGSAVE <ebx,edx,edi>	; Save registers

	 xor	 ebx,ebx	; Zero accumulator
PREF&BASE2BIN_NEXT:
	 lods	 ds:[esi].LO	; Get next digit
	 call	 PREF&LOWERCASE ; Convert to lowercase

	 lea	 edi,PREF&NUMBERS_LO ; Get address of number conversion table
	 push	 ecx		; Save number base (and table length)
   repne scas	 PREF&NUMBERS_LO[edi] ; Look for the character
	 pop	 ecx		; Restore number base
	 jne	 short PREF&BASE2BIN_DONE ; Not one of ours

	 sub	 edi,(type PREF&NUMBERS_LO)+offset es:PREF&NUMBERS_LO ; Convert to origin 0
	 mov	 eax,ebx	; Copy old to multiply by base

	 mul	 ecx		; Shift over accumulated #
	 jc	 short PREF&BASE2BIN_OVF ; Jump if out of range

	 mov	 ebx,eax	; Copy back
	 add	 ebx,edi	; Add in new #
	 jnc	 short PREF&BASE2BIN_NEXT ; Jump if in range
PREF&BASE2BIN_OVF:
	 stc			; Indicate something went wrong

	 jmp	 short PREF&BASE2BIN_EXIT ; Join common exit code

PREF&BASE2BIN_DONE:
	 dec	 esi		; Back off to previous character
	 mov	 eax,ebx	; Place result in accumulator

	 clc			; Indicate all went well
PREF&BASE2BIN_EXIT:
	 REGREST <edi,edx,ebx>	; Restore registers

	 ret			; Return to caller with number in EAX

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&BASE2BIN endp		; End PREF&BASE2BIN procedure

	 endm			; BASE2BIN_MAC

	 BASE2BIN_MAC U32_,DGROUP ; Define in PGROUP

	 NPPROC  REG2DD -- Convert Register to Binary
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert input from register name to binary

On entry:

DS:ESI	 ==>	 input
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if all went well
	 =	 1 if no matching register

DS:ESI	 ==>	 (updated)
EAX	 =	 register value

|

	 REGSAVE <ebx,ecx,edi>	; Save registers

	 call	 GET_TOKN	; Get next token into CMD_TOKN

	 cmp	 CMD_TOKN,0	; Izit end-of-the-line?
	 je	 short REG2DD_REGNF ; Yes, so that's considered not found

	 xor	 ebx,ebx	; Zero index register
	 mov	 ecx,REG_NTAB	; # arguments to check
REG2DD_NEXT:
	 mov	 edi,REG_TAB[ebx*(type REG_TAB)] ; Get location of text

	 REGSAVE <ecx,esi>	; Save for a moment

	 mov	 ecx,REG_LEN[ebx*(type REG_LEN)] ; Get length

	 cmp	 cl,CMD_TOKL	; Izit the same length?
	 jne	 short @F	; Jump if not (note ZF=0)

	 lea	 esi,CMD_TOKN	; DS:ESI ==> token
    repe cmps	 CMD_TOKN[esi],es:[edi] ; Compare 'em
				; Fall through with ZF significant
@@:
	 REGREST <esi,ecx>	; Restore
	 je	 short REG2DD_FOUND ; Jump if it's a match

	 inc	 ebx		; Skip to next entry

	 loop	 REG2DD_NEXT	; Jump if more entries to check

; Register not found

	 jmp	 REG2DD_REGNF	; Jump if not found


REG2DD_FOUND:
	 movsx	 ecx,REG_OFF[ebx*(type REG_OFF)] ; Get appropriate offset

	 call	 REG_ACTGET[ebx*(type REG_ACTGET)] ; Take appropriate action
	 jc	 short REG2DD_ERR ; Join common error code

	 add	 esi,REG_LEN[ebx*(type REG_LEN)] ; Skip over the keyword

	 clc			; Mark as found

	 jmp	 short REG2DD_EXIT ; Join common exit code

REG2DD_ERR:

REG2DD_REGNF:
	 stc			; Mark as not found
REG2DD_EXIT:
	 REGREST <edi,ecx,ebx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REG2DD	 endp			; End REG2DD procedure

LOWERCASE_MAC macro PREF

	 NPPROC  PREF&LOWERCASE -- Convert AL to Lowercase
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AL to lowercase.

On entry:

AL	 =	 value to convert

On exit:

AL	 =	 converted value

|


	 cmp	 al,'A'         ; Check against lower limit
	 jb	 short @F	; Jump if too small

	 cmp	 al,'Z'         ; Check against upper limit
	 ja	 short @F	; Jump if too big

	 add	 al,'a'-'A'     ; Convert to lowercase
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&LOWERCASE endp		; End PREF&LOWERCASE procedure

	 endm			; LOWERCASE_MAC

	 LOWERCASE_MAC U32_	; Define in PGROUP

	 NPPROC  UPPERCASE -- Convert AL to Uppercase
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AL to uppercase.

On entry:

AL	 =	 value to convert

On exit:

AL	 =	 converted value

|


	 cmp	 al,'a'         ; Check against lower limit
	 jb	 short @F	; Jump if too small

	 cmp	 al,'z'         ; Check against upper limit
	 ja	 short @F	; Jump if too big

	 add	 al,'A'-'a'     ; Convert to uppercase
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UPPERCASE endp			; End UPPERCASE procedure
	 NPPROC  IZITEOL -- See If End-Of-The-Line
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if we're at the end-of-the-line

On entry:

DS:ESI	 ==>	 command line

On exit:

DS:ESI	 ==>	 (updated)
ZF	 =	 1 if EOL
	 =	 0 otherwise

|

	 push	 eax		; Save register

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
				; Return with ZF=1 iff EOL
	 pop	 eax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZITEOL  endp			; End IZITEOL procedure
	 NPPROC  GETPMI -- Get PM Interrupt Address
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Get PM interrupt address

On entry:

AL	 =	 interrupt #

On exit:

BX	 =	 selector
EAX	 =	 offset
EDX	 =	 selector base
CX	 =	 flags

|

; If this is an interrupt which we're hooking to provide keyboard
; services, etc., use the one in the old location

	 pushfd 		; Save flags
	 cli			; Disallow interrupts

; Swap back the original interrupts which we've hooked

	 call	 SWAP_OLDINTS	; Swap 'em using SS|EBP and GS

	 sub	 esp,size DTR_STR ; Make room on stack
	 SIDTD	 [esp].EDF	; Save IDTR on stack
	 mov	 ebx,[esp].DTR_BASE ; AGROUP:EBX ==> IDT
	 add	 esp,size DTR_STR ; Strip from stack

	 movzx	 eax,al 	; Zero to use as dword
	 mov	 dx,AGROUP:[ebx+eax*(size IDT_STR)].IDT_OFFHI ; Get high-order word
	 shl	 edx,16 	; Shift to high-order word
	 mov	 dx,AGROUP:[ebx+eax*(size IDT_STR)].IDT_OFFLO ; Get low-order word

	 mov	 bx,AGROUP:[ebx+eax*(size IDT_STR)].IDT_SELECT ; Get selector

; Restore the interrupts which we've hooked

	 call	 REST_OLDINTS	; Restore 'em using SS|EBP and GS

	 popfd			; Restore flags

; Ensure it's a code selector

	 mov	 eax,edx	; Copy for SELOFF2ADDR
	 call	 SELOFF2ADDR	; Convert BX|EAX to address
				; Return with BX = selector
				; ...	     EAX = offset
				; ...	     EDX = selector base
				; ...	      CX = flags
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETPMI	 endp			; End GETPMI procedure
	NPPROC	UPPERCASE_STR -- Convert String To Uppercase
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert string to uppercase

On entry:

DS:ESI	==>	ASCIIZ string to convert

|

	REGSAVE <eax,esi>	; Save registers
@@:
	lods	ds:[esi].LO	; Get next char

	cmp	al,0		; Izit EOL?
	je	short @F	; Jump if so

	cmp	al,' '          ; Izit white space?
	je	short @F	; Jump if so

	call	UPPERCASE	; Convert AL to uppercase
	mov	ds:[esi-1],al	; Save back

	jmp	@B		; Go around again

@@:
	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UPPERCASE_STR endp		; End UPPERCASE_STR procedure
	NPPROC	CopyWKDRegs -- Copy WKD Registers
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy WKD registers from FORW_STR to DS:EDI

On entry:

DS:EDI	==>	SaveRegs_struc struc

|

CopyMAC4 macro	REG

	mov	eax,fs:[esi].FORW_&REG ; Get register
	mov	ds:[edi].Debug_&REG,eax ; Save in struc

	endm			; End CopyMAC

CopyMAC2 macro	REG

	mov	ax,fs:[esi].FORW_&REG ; Get register
	mov	ds:[edi].Debug_&REG,ax ; Save in struc

	endm			; End CopyMAC

	REGSAVE <eax,esi,fs>	; Save registers

	lfs	esi,FORWSTR_FVEC ; FS:ESI ==> last valid FORW_STR

	CopyMAC4 EAX		; Copy register
	CopyMAC4 EBX		; ...
	CopyMAC4 ECX		; ...
	CopyMAC4 EDX		; ...
	CopyMAC4 ESI		; ...
	CopyMAC4 EDI		; ...
	CopyMAC4 EBP		; ...
	CopyMAC4 ESP		; ...
	CopyMAC2 CS		; ...
	CopyMAC2 DS		; ...
	CopyMAC2 ES		; ...
	CopyMAC2 FS		; ...
	CopyMAC2 GS		; ...
	CopyMAC2 SS		; ...
	CopyMAC4 EIP		; ...
	CopyMAC2 LDT		; ...

	mov	eax,fs:[esi].FORW_EFL ; Get flags
	mov	ds:[edi].Debug_EFlags,eax ; Save in struc

	mov	eax,cr0 	; Get current contents
	mov	ds:[edi].Debug_CR0,eax ; Save in struc

	mov	eax,cr2 	; Get current contents
	mov	ds:[edi].Debug_CR2,eax ; Save in struc

	mov	eax,cr3 	; Get current contents
	mov	ds:[edi].Debug_CR3,eax ; Save in struc

	public	WKD_DRnA
WKD_DRnA:
	mov	eax,dr0 	; Get current contents
	mov	ds:[edi].Debug_DR0,eax ; Save in struc

	mov	eax,dr1 	; Get current contents
	mov	ds:[edi].Debug_DR1,eax ; Save in struc

	mov	eax,dr2 	; Get current contents
	mov	ds:[edi].Debug_DR2,eax ; Save in struc

	mov	eax,dr3 	; Get current contents
	mov	ds:[edi].Debug_DR3,eax ; Save in struc

	public	WKD_DRnZ
WKD_DRnZ:
	mov	eax,SAVE_DR6	; Get current contents
	mov	ds:[edi].Debug_DR6,eax ; Save in struc

	mov	eax,SAVE_DR7	; Get current contents
	mov	ds:[edi].Debug_DR7,eax ; Save in struc
	mov	ds:[edi].Debug_DR7_2,eax ; ...

;;;;;;; mov	eax,tr6 	; Get current contents
;;;;;;; mov	ds:[edi].Debug_TR6,eax ; Save in struc
;;;;;;;
;;;;;;; mov	eax,tr7 	; Get current contents
;;;;;;; mov	ds:[edi].Debug_TR7,eax ; Save in struc
;;;;;;;
	mov	eax,ERRCODE	; Get last error code (if any)
	mov	ds:[edi].Debug_ErrorCode,ax ; Save in struc (note word register)

;;;;;;; mov	ds:[edi].Debug_TrapNumber,eax ; Save in struc

	mov	ax,fs:[esi-@BPBACK].BACK_GDT.DTR_LIM ; Get GDTR limit
	mov	ds:[edi].Debug_GDT.DTR_LIM,ax ; Save in struc

	mov	eax,fs:[esi-@BPBACK].BACK_GDT.DTR_BASE ; Get GDTR base
	mov	ds:[edi].Debug_GDT.DTR_BASE,eax ; Save in struc

	mov	ax,fs:[esi-@BPBACK].BACK_IDT.DTR_LIM ; Get IDTR limit
	mov	ds:[edi].Debug_IDT.DTR_LIM,ax ; Save in struc

	mov	eax,fs:[esi-@BPBACK].BACK_IDT.DTR_BASE ; Get IDTR base
	mov	ds:[edi].Debug_IDT.DTR_BASE,eax ; Save in struc

	mov	ax,fs:[esi-@BPBACK].BACK_TR.DTR_LIM ; Get TR
	mov	ds:[edi].Debug_TR,ax ; Save in struc

	REGREST <fs,esi,eax>	; Restore
	assume	fs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CopyWKDRegs	endp		; End CopyWKDRegs procedure
	NPPROC	CMD_UNREAL -- Set/Unset Unreal Mode
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Set/unset Unreal Mode

UNREAL sign register [sign register ...]

where sign is either + or -
and register is one of ALL CS DS ES FS GS or SS

To enable all registers, use +ALL
To disable all registers, use -ALL
To enable or disable selected registers, use +xS or -xS
  where x is C D E F G or S

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax,edx>	; Save registers

	movzx	edx,RGRSEG2	; Get low DOS memory segment
	shl	edx,4-0 	; Convert from paras to bytes

	call	IZITEOL 	; Izit end-of-the-line?
	je	near ptr CMD_UNREAL_SYNTERR ; Yes, so that's an error
CMD_UNREAL_NEXT:
	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	cmp	al,0		; Izit EOL?
	je	near ptr CMD_UNREAL_DONE ; Yes, so that's the end

	cmp	al,'+'          ; Izit enable?
	je	short @F	; Jump if so

	cmp	al,'-'          ; Izit disable?
	jne	near ptr CMD_UNREAL_SYNTERR ; Jump if not
@@:
	mov	ah,al		; Save for later use

	inc	esi		; Skip over the sign

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	call	GET_TOKN	; Get next token into CMD_TOKN

	cmp	CMD_TOKN.EDD,'lla'  ; Izit 'all'?
	je	short CMD_UNREAL_ALL ; Jump if so

	cmp	CMD_TOKN.EDD,'sc' ; Izit 'cs'?
	je	near ptr CMD_UNREAL_CS ; Jump if so

	cmp	CMD_TOKN.EDD,'sd' ; Izit 'ds'?
	je	near ptr CMD_UNREAL_DS ; Jump if so

	cmp	CMD_TOKN.EDD,'se' ; Izit 'es'?
	je	near ptr CMD_UNREAL_ES ; Jump if so

	cmp	CMD_TOKN.EDD,'sf' ; Izit 'fs'?
	je	near ptr CMD_UNREAL_FS ; Jump if so

	cmp	CMD_TOKN.EDD,'sg' ; Izit 'gs'?
	je	near ptr CMD_UNREAL_GS ; Jump if so

	cmp	CMD_TOKN.EDD,'ss' ; Izit 'ss'?
	je	near ptr CMD_UNREAL_SS ; Jump if so

	jmp	CMD_UNREAL_SELERR ; Join common error code


CMD_UNREAL_ALL:
	cmp	ah,'+'          ; Izit enable?
	je	short @F	; Jump if so

	and	UNR_FLAG,not @UNR_ALL ; Turn 'em all off

	assume	gs:RGROUP	; Tell a white lie
	mov	PDTE_CS[edx],DTE_CS ; Save as new selector
	mov	PDTE_DS[edx],DTE_DS ; ...
	mov	PDTE_ES[edx],DTE_DS ; ...
	mov	PDTE_FS[edx],DTE_DS ; ...
	mov	PDTE_GS[edx],DTE_DS ; ...
	mov	PDTE_SS[edx],DTE_SSB0S ; ...
	assume	gs:AGROUP	; Retract nose

	jmp	short CMD_UNREAL_ALLNEXT ; Go around again

@@:
	or	UNR_FLAG,@UNR_ALL ; Turn 'em all on

	assume	gs:RGROUP	; Tell a white lie
	mov	PDTE_CS[edx],DTE_CS4GB ; Save as new selector
	mov	PDTE_DS[edx],DTE_4GB ; ...
	mov	PDTE_ES[edx],DTE_4GB ; ...
	mov	PDTE_FS[edx],DTE_4GB ; ...
	mov	PDTE_GS[edx],DTE_4GB ; ...
	mov	PDTE_SS[edx],DTE_SSB0L ; ...
	assume	gs:AGROUP	; Retract nose
CMD_UNREAL_ALLNEXT:
	add	esi,3		; Skip over the token

	jmp	CMD_UNREAL_NEXT ; Go around again


CMD_UNREAL_CS:
	cmp	ah,'+'          ; Izit enable?
	je	short @F	; Jump if so

	and	UNR_FLAG,not @UNR_CS ; Turn it off

	assume	gs:RGROUP	; Tell a white lie
	mov	PDTE_CS[edx],DTE_CS ; Save as new selector
	assume	gs:AGROUP	; Retract nose

	jmp	CMD_UNREAL_REGNEXT ; Go around again

@@:
	or	UNR_FLAG,@UNR_CS ; Turn it on

	assume	gs:RGROUP	; Tell a white lie
	mov	PDTE_CS[edx],DTE_CS4GB ; Save as new selector
	assume	gs:AGROUP	; Retract nose

	jmp	CMD_UNREAL_REGNEXT ; Go around again

CMD_UNREAL_DS:
	cmp	ah,'+'          ; Izit enable?
	je	short @F	; Jump if so

	and	UNR_FLAG,not @UNR_DS ; Turn it off

	assume	gs:RGROUP	; Tell a white lie
	mov	PDTE_DS[edx],DTE_DS ; Save as new selector
	assume	gs:AGROUP	; Retract nose

	jmp	CMD_UNREAL_REGNEXT ; Go around again

@@:
	or	UNR_FLAG,@UNR_DS ; Turn it on

	assume	gs:RGROUP	; Tell a white lie
	mov	PDTE_DS[edx],DTE_4GB ; Save as new selector
	assume	gs:AGROUP	; Retract nose

	jmp	CMD_UNREAL_REGNEXT ; Go around again

CMD_UNREAL_ES:
	cmp	ah,'+'          ; Izit enable?
	je	short @F	; Jump if so

	and	UNR_FLAG,not @UNR_ES ; Turn it off

	assume	gs:RGROUP	; Tell a white lie
	mov	PDTE_ES[edx],DTE_DS ; Save as new selector
	assume	gs:AGROUP	; Retract nose

	jmp	CMD_UNREAL_REGNEXT ; Go around again

@@:
	or	UNR_FLAG,@UNR_ES ; Turn it on

	assume	gs:RGROUP	; Tell a white lie
	mov	PDTE_ES[edx],DTE_4GB ; Save as new selector
	assume	gs:AGROUP	; Retract nose

	jmp	CMD_UNREAL_REGNEXT ; Go around again

CMD_UNREAL_FS:
	cmp	ah,'+'          ; Izit enable?
	je	short @F	; Jump if so

	and	UNR_FLAG,not @UNR_FS ; Turn it off

	assume	gs:RGROUP	; Tell a white lie
	mov	PDTE_FS[edx],DTE_DS ; Save as new selector
	assume	gs:AGROUP	; Retract nose

	jmp	short CMD_UNREAL_REGNEXT ; Go around again

@@:
	or	UNR_FLAG,@UNR_FS ; Turn it on

	assume	gs:RGROUP	; Tell a white lie
	mov	PDTE_FS[edx],DTE_4GB ; Save as new selector
	assume	gs:AGROUP	; Retract nose

	jmp	short CMD_UNREAL_REGNEXT ; Go around again

CMD_UNREAL_GS:
	cmp	ah,'+'          ; Izit enable?
	je	short @F	; Jump if so

	and	UNR_FLAG,not @UNR_GS ; Turn it off

	assume	gs:RGROUP	; Tell a white lie
	mov	PDTE_GS[edx],DTE_DS ; Save as new selector
	assume	gs:AGROUP	; Retract nose

	jmp	short CMD_UNREAL_REGNEXT ; Go around again

@@:
	or	UNR_FLAG,@UNR_GS ; Turn it on

	assume	gs:RGROUP	; Tell a white lie
	mov	PDTE_GS[edx],DTE_4GB ; Save as new selector
	assume	gs:AGROUP	; Retract nose

	jmp	short CMD_UNREAL_REGNEXT ; Go around again

CMD_UNREAL_SS:
	cmp	ah,'+'          ; Izit enable?
	je	short @F	; Jump if so

	and	UNR_FLAG,not @UNR_SS ; Turn it off

	assume	gs:RGROUP	; Tell a white lie
	mov	PDTE_SS[edx],DTE_SSB0S ; Save as new selector
	assume	gs:AGROUP	; Retract nose

	jmp	short CMD_UNREAL_REGNEXT ; Go around again

@@:
	or	UNR_FLAG,@UNR_SS ; Turn it on

	assume	gs:RGROUP	; Tell a white lie
	mov	PDTE_SS[edx],DTE_SSB0L ; Save as new selector
	assume	gs:AGROUP	; Retract nose

;;;;;;; jmp	short CMD_UNREAL_REGNEXT ; Go around again

CMD_UNREAL_REGNEXT:
	add	esi,2		; Skip over the register

	jmp	CMD_UNREAL_NEXT ; Go around again


CMD_UNREAL_DONE:
	or	LCL_FLAG,@LCL_REDI ; Mark as forced re-display of screen

	clc			; Indicate all went well

	jmp	short CMD_UNREAL_EXIT ; Join common exit code

CMD_UNREAL_SELERR:
	mov	MSGOFF,offset DGROUP:SELERR ; Save offset of error message
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	jmp	short CMD_UNREAL_ERR ; Join common error exit code

CMD_UNREAL_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

;;;;;;; jmp	short CMD_UNREAL_ERR ; Join common error exit code

CMD_UNREAL_ERR:
	stc			; Mark as in error
CMD_UNREAL_EXIT:
	REGREST <edx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_UNREAL endp 		; End CMD_UNREAL procedure

PROG	 ends			; End PROG segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:NGROUP

	public	@SWAT_CMD_NDATA
@SWAT_CMD_NDATA label byte	; Mark module start in .MAP file

	 public  U16_NUMBERS_LO
U16_NUMBERS_LO db '0123456789abcdef' ; Conversion table for HEX2DD

NDATA	 ends			; End NDATA segment


NCODE	 segment use16 para public 'ncode' ; Start NCODE segment
	 assume  cs:NGROUP

	public	@SWAT_CMD_NCODE
@SWAT_CMD_NCODE:		; Mark module start in .MAP file

	 HEX2DD_MAC U16_	; Define in NGROUP
	 BASE2BIN_MAC U16_,NGROUP ; Define in NGROUP
	 LOWERCASE_MAC U16_	; Define in NGROUP

NCODE	 ends			; End NCODE segment

	 MEND			; End SWAT_CMD module
