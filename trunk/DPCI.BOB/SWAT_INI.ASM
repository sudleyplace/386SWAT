;' $Header:   P:/PVCS/386SWAT/SWAT_INI.ASV   1.58   20 Aug 1998 23:05:56   BOB  $
	 title	 SWAT_INI -- 386SWAT Initialization Routines
	 page	 58,122
	 name	 SWAT_INI

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
	 include DOSCALL.INC
	 include KEYCALL.INC
	 include ASCII.INC
	 include 386.INC
	 include PTR.INC
	 include VIDATTR.INC
	 include DEVDRV.INC
	 include MAXDEV.INC
	 include INTVEC.INC
	 include I11.INC
	 include BIOSDATA.INC
	 include 8255.INC
	 include CMOS.INC
	 include ALLMEM.INC
	 include BITFLAGS.INC
	 include DPMI.INC
	 include VCPI.INC
	 include CPUFLAGS.INC
	 include CPUSIG.INC
	 include CPUFET.INC
	 include OPEN.INC
	 include EXE.INC
	include WKD.INC

	 include SWAT_COM.INC
	 include SWAT_DRV.INC
	 include SWAT_VCP.INC
	 include SWAT_VID.INC
	 include SWAT_AGR.INC
	 include SWAT_FVM.INC
	 include SWAT_REM.INC
	 include SWAT_SEG.INC
	 include SWAT_SER.INC
	 include SWAT_SYM.INC
	include SWAT_TSC.INC
NOVER_HTU equ	1
	 include VERSION.INC
.list

@IRQCODE equ	1	; Include stuff needed for remote debugging

DATA16	 segment use32 dword public 'data' ; Start DATA16 segment
	 assume  ds:DGROUP

	public	@SWAT_INI_DATA16
@SWAT_INI_DATA16 label byte	; Mark module start in .MAP file

	 extrn	 COMMON:tbyte
	 include QMAX_FIL.INC

	 extrn	 ARG_FLAG:word
	 include SWAT_ARG.INC

	 extrn	 AR2_FLAG:word
	 include SWAT_AR2.INC

	 extrn	 DBG_FLAG:word
	 include SWAT_DBG.INC

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	LC3_FLAG:dword
	include SWAT_LC3.INC

	extrn	LC4_FLAG:dword
	include SWAT_LC4.INC

	 extrn	 CMD_LINE:byte
	 extrn	 CMD_LINE_LEN:dword

	 extrn	 LCLSTK_FVEC:fword

	 extrn	 OLDINT41_FVEC:fword,OLDINT41_ARB:byte
	 extrn	 OLDINT67_FVEC:fword,OLDINT67_ARB:byte
	 extrn	 OLDINT68_FVEC:fword,OLDINT68_ARB:byte

	 extrn	 LCLINT00_FVEC:fword,LCLINT00_ARB:byte
	 extrn	 LCLINT01_FVEC:fword,LCLINT01_ARB:byte
	 extrn	 LCLINT02_FVEC:fword,LCLINT02_ARB:byte
	 extrn	 LCLINT03_FVEC:fword,LCLINT03_ARB:byte
	 extrn	 LCLINT05_FVEC:fword,LCLINT05_ARB:byte
	 extrn	 LCLINT06_FVEC:fword,LCLINT06_ARB:byte
	 extrn	 LCLINT09_FVEC:fword,LCLINT09_ARB:byte
	 extrn	 LCLINT0A_FVEC:fword,LCLINT0A_ARB:byte
	 extrn	 LCLINT0B_FVEC:fword
	 extrn	 LCLREMINT0B_FVEC:fword,LCLREMINT0B_ARB:byte
	 extrn	 LCLINT0C_FVEC:fword,LCLINT0C_ARB:byte
	 extrn	 LCLREMINT0C_FVEC:fword,LCLREMINT0C_ARB:byte
	 extrn	 LCLINT0D_FVEC:fword,LCLINT0D_ARB:byte
	 extrn	 LCLINT0E_FVEC:fword,LCLINT0E_ARB:byte
	 extrn	 LCLINT41_FVEC:fword,LCLINT41_ARB:byte
	 extrn	 LCLINT67_FVEC:fword,LCLINT67_ARB:byte
	 extrn	 LCLINT68_FVEC:fword,LCLINT68_ARB:byte

	 extrn	 OLDINT00_FVEC:fword,OLDINT00_ARB:byte
	 extrn	 OLDINT01_FVEC:fword,OLDINT01_ARB:byte
	 extrn	 OLDINT02_FVEC:fword,OLDINT02_ARB:byte
	 extrn	 OLDINT03_FVEC:fword,OLDINT03_ARB:byte
	 extrn	 OLDINT05_FVEC:fword,OLDINT05_ARB:byte
	 extrn	 OLDINT06_FVEC:fword,OLDINT06_ARB:byte
	 extrn	 OLDINT09_FVEC:fword,OLDINT09_ARB:byte
	 extrn	 OLDINT0A_FVEC:fword,OLDINT0A_ARB:byte
	 extrn	 OLDREMINT0B_FVEC:fword,OLDREMINT0B_ARB:byte
	 extrn	 OLDINT0C_FVEC:fword,OLDINT0C_ARB:byte
	 extrn	 OLDREMINT0C_FVEC:fword,OLDREMINT0C_ARB:byte
	 extrn	 OLDINT0D_FVEC:fword,OLDINT0D_ARB:byte
	 extrn	 OLDINT0E_FVEC:fword,OLDINT0E_ARB:byte

	 extrn	 DIVINT00_FVEC:fword
	 extrn	 REGINT06_FVEC:fword
	 extrn	 REGINT0D_FVEC:fword

	 extrn	 TXTMODE:byte
	 extrn	 CRTC:word
	 extrn	 CURTYPE:word

	 extrn	 VCPICODE:dword,VCPICODE_LIM:dword
	 extrn	 VCPIDATA:dword,VCPIDATA_LIM:dword
	 extrn	 VIDBASE_FVEC:fword
	 extrn	 FVMBASE:dword
	 extrn	 ARETBASE:dword
	 extrn	 PLCLPDIR:dword
	 extrn	 BLCLPDIR:dword
	 extrn	 PaLCLPDIR:dword
	 extrn	 PaTMPPAGE:dword
	 extrn	 OLDIBV0:byte
	extrn	CntINSERT:dword
	extrn	PINSERT:dword
	extrn	PaINSERT:dword

	 extrn	 LCLTSS00:tbyte
	 extrn	 NLCLTSS:abs

	 extrn	 SYMSIZE:dword
	 extrn	 SYMBASE:dword
	 extrn	 SYMNEXT:dword
	 extrn	 SYMLAST:dword
	 extrn	 SYMHASH:dword
	 extrn	 SYMNHASH:dword

	 extrn	 ADDRHBITS:byte
	 extrn	 HASHPRIME:word
	 extrn	 BUCKETS:byte

	 extrn	 SYM_READBUF:byte

	 extrn	 OLDCR3:dword

	 extrn	 ALTBASE_FVEC:fword
	 extrn	 PLASTXMSCR:dword
	 extrn	 PRECVBUF:dword

	 extrn	 PCUR_VM_HANDLE:fword

	 extrn	 OLDSTK_FVEC:fword

	 extrn	 RUD_IDTR:fword
	 extrn	 MMCODESEL:word

	 extrn	 MACBASE:dword

	extrn	CMDHIST_LEN:dword
	extrn	CMDHIST_OFF:dword
	extrn	CMDHIST_END:dword

	extrn	I41STK_FVEC:fword
	extrn	@I41STK_SIZE:abs

	 public  PWTAIL
PWTAIL	 dd	 offset WGROUP:WTAIL ; Because MASM 5.10b generates a word
				; offset record instead of a dword offset

	 public  CPUFET_FLAG
CPUFET_FLAG dd	 ?		; CPU feature bits (see CPUFET.INC for masks)

	 public  PLCLMONO,PLCLCOLR,PLCLCR3
PLCLMONO dd	 ?		; Offset in DGROUP of mono video buffer
PLCLCOLR dd	 ?		; ...		      color ...
PLCLCR3  dd	 ?		; ...		      local CR3

	 public  WINBASE,SWATCODE,SWATDATA
WINBASE  dd	 ?		; Offset in DGROUP of WGROUP
SWATCODE dd	 ?		; Linear address of PGROUP
SWATDATA dd	 ?		; ...		    DGROUP

	 public  PLSTBUF_IND,NLSTBUF,PLSTBUF_INI,PPLSTBUF_TAB,PSCRBUF
PLSTBUF_IND dd	 0		; Index into PLSTBUF_TAB
NLSTBUF  dd	 16		; # last screen buffers
PLSTBUF_INI dd	 ?		; Offset in DGROUP of initial last screen buffer
PPLSTBUF_TAB dd  ?		; Ptr to DGROUP table of last screen buffer ptrs
PSCRBUF  dd	 ?		;  ...			     screen buffer

	public	WKDLS_CNT,PWKDLS
WKDLS_CNT dd	0		; # WKD Load Segment entries
PWKDLS	dd	?		; Offset in DGROUP of WKD LS table

	 public  LaLSTLST
LaLSTLST dd	 ?		; Linear address of list of lists

	public	CPUSIG
CPUSIG	dd	?		; CPU signature bits (Member, Family, Model, Step)
				; see CPUSIG.INC for details
	 public  INISTK_FVEC
INISTK_FVEC df	 ?		; Stack for INIT_PROT

	public	INIT_COUNT
INIT_COUNT dw	0		; # times INIT_PROT called less the
				; # times REST_PROT called
	public	CPUFAM
CPUFAM	db	03h		; CPU family (3=386, 4=486, etc.)

	 public  WATCHDOG
WATCHDOG db	 18*0		; Default is 0 seconds

	 public  @NHLPCLRS
@NHLPCLRS equ	 1		; Maximum # additional help line colors supported

	 public  DEFATTR,BARATTR,STKATTR,CURATTR,CMDATTR,ERRATTR,TTLATTR
	 public  DBGATTR,NDPATTR,HLPATTR,REGATTR,WRKATTR,LBLATTR,BPTATTR
	 public  BPCATTR,HLPAATTR,HLPBATTR,HTTLATTR,HKEYATTR,LBRATTR
	public	HSTAATTR,HSTBATTR
DEFATTR  db	 ?		; Attr for Default
BARATTR  db	 ?		; Attr for Bar
STKATTR  db	 ?		; Attr for Stack
CURATTR  db	 ?		; Attr for Cur Instr
CMDATTR  db	 ?		; Attr for Command Line
ERRATTR  db	 ?		; Attr for Error Msg
TTLATTR  db	 ?		; Attr for Titles
DBGATTR  db	 ?		; Attr for Debug Register Window
NDPATTR  db	 ?		; Attr for NDP Register Window
HLPATTR  db	 (@NHLPCLRS+1) dup (?) ; Attributes for help color numbers
HLPAATTR db	 ?		; Attr for Help active lines
HLPBATTR db	 ?		; Attr for Help background lines
HTTLATTR db	 ?		; Attr for Help titles
HKEYATTR db	 ?		; Attr for Help keys
REGATTR  db	 ?		; Attr for Register Changed
WRKATTR  db	 ?		; Attr for Working Window
LBLATTR  db	 ?		; Attr for symbol labels
BPTATTR  db	 ?		; Attr for line with breakpoint set
BPCATTR  db	 ?		; Attr for current line with breakpoint set
LBRATTR  db	 ?		; Attr for LBR window
HSTAATTR db	 ?		; Attr for command history window
HSTBATTR db	 ?		; Attr for command history window bar

	 public  ADEF,ABAR,ASTK,ACUR,ACMD,AERR,ATTL,ADBG,ANDP,AHLP,AREG,AWRK
	 public  ALBL,ABPT,ABPC,ALBR
	 public  AHLPA,AHLPB
	public	AHSTA,AHSTB
;		 Mono		ForeColor	  BackColor		    LCD
ADEF	 db	 @ATMnorm    ,	@ATCFyellow	+ @ATCBblue	+ @ATChigh , @ATMnorm
ABAR	 db	 @ATMhigh    ,	@ATCFwhite	+ @ATCBblue	+ @ATChigh , @ATMhigh
ASTK	 db	 @ATMnorm    ,	@ATCFgreen	+ @ATCBblue	+ @ATChigh , @ATMnorm
ACUR	 db	 @ATMrev     ,	@ATCFblue	+ @ATCByellow		   , @ATMrev
ACMD	 db	 @ATMrev     ,	@ATCFyellow	+ @ATCBred	+ @ATChigh , @ATMrev
AERR	 db	 @ATMrev     ,	@ATCFred	+ @ATCBwhite		   , @ATMrev
ATTL	 db	 @ATMhigh    ,	@ATCFwhite	+ @ATCBblue	+ @ATChigh , @ATMhigh
ADBG	 db	 @ATMhigh    ,	@ATCFwhite	+ @ATCBred	+ @ATChigh , @ATMhigh
ANDP	 db	 @ATMhigh    ,	@ATCFwhite	+ @ATCBred	+ @ATChigh , @ATMhigh
AHLP	 db	 @ATMrev     ,	@ATCFblue	+ @ATCBwhite		   , @ATMrev
	 db	 @ATMrev     ,	@ATCFmagenta	+ @ATCBwhite		   , @ATMrev
; Define additional rows for each additional help color attribute @NHLPCLRS
AHLPA	 db	 @ATMnorm    ,	@ATCFwhite	+ @ATCBblack		   , @ATMnorm
AHLPB	 db	 @ATMrev     ,	@ATCFblack	+ @ATCBwhite		   , @ATMrev
AHTTL	 db	 @ATMrev     ,	@ATCFred	+ @ATCBwhite		   , @ATMrev
AHKEY	 db	 @ATMnorm    ,	@ATCFblue	+ @ATCBwhite		   , @ATMnorm
AREG	 db	 @ATMrev     ,	@ATCFyellow	+ @ATCBblack	+ @ATChigh , @ATMrev
AWRK	 db	 @ATMrevblink,	@ATCFwhite	+ @ATCBred	+ @ATCblink, @ATMrevblink
ALBL	 db	 @ATMhigh    ,	@ATCFred	+ @ATCBblue	+ @ATChigh , @ATMhigh
ABPT	 db	 @ATMrev     ,	@ATCFwhite	+ @ATCBred		   , @ATMrev
ABPC	 db	 @ATMrevblink,	@ATCFwhite	+ @ATCByellow	+ @ATChigh , @ATMrevblink
ALBR	 db	 @ATMrev     ,	@ATCFwhite	+ @ATCByellow	+ @ATChigh , @ATMrev
AHSTA	 db	 @ATMhigh    ,	@ATCFblue	+ @ATCBcyan		   , @ATMnorm
AHSTB	 db	 @ATMrev     ,	@ATCFblue	+ @ATCBcyan	+ @ATChigh , @ATMrev

	 public  VIDTYPE
	 align	 4
VIDTYPE  dd	 ?		; Current normal/insert cursor type

; Note that the order of MONOTYPE and CO80TYPE is important

	 public  MONOTYPE,CO80TYPE
MONOTYPE dd	 @CUR_MDA	; Normal/insert MONO cursor type
CO80TYPE dd	 @CUR_CLR	; ...		CO80 ...

	 public  LaINDOS
LaINDOS  dd	 ?		; Offset within AGROUP of DOS reentrancy flag

	 public  EXTSYM_OFF,EXTSYM_LEN,EXTSYM_CHKSUM,EXTSYM_COUNT
EXTSYM_OFF dd	 00110000h	; Linear offset of SYMLOAD data
EXTSYM_LEN dd	 ?		; Length in bytes of SYMLOAD data
EXTSYM_CHKSUM dd ?		; 32-bit checksum of SYMLOAD data
EXTSYM_COUNT dd  ?		; Number of symbol records at EXTSYM_OFF

	 public  LOGLEN,LOGBASE,LOGOFF,LOGHEAD
LOGLEN dd	 80*50		; Default error log is 50 lines
LOGBASE dd	 ?		; Base address of error log
LOGOFF dd	 0		; Current log output pointer
LOGHEAD dd	 0		; Beginning of log display data

	 public  MAXINT
MAXINT	 dd	 ?		; Maximum interrupt #

DATA16	 ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	WKD_FLAG:word
	include SWAT_WKD.INC

	extrn	FORCE_DR7:dword
	extrn	CMDHIST_NXT:dword
	extrn	CMDHIST_CUR:dword

	extrn	OLD_TSC:qword

DATA	ends			; End DATA segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:NGROUP

	 extrn	 VIDEO_SEG:word
	 extrn	 VIDEO_CNT:word
	 extrn	 DVGA_SEG:word
	 extrn	 DVGA_CNT:word
	 extrn	 PRIMES:word
	 extrn	 MSG_LOADSWAT:byte

;;;;;;;  public  GROUPMSG
;;;;;;;GROUPMSG db	 'PGROUP='
;;;;;;;GMSG_PGROUP db	 'xxxx',CR,LF,EOS
;;;;;;;
NDATA	 ends			; End NDATA segment


WDATAZ	 segment use32 para public 'wdataz' ; Start WDATAZ segment
	 assume  ds:WGROUP

	 extrn	 WTAIL:tbyte

WDATAZ	 ends			; End WDATAZ segment


RCODE	segment use16 para public 'rcode' ; Start RCODE segment
	assume	ds:RGROUP

	extrn	ROLDINT67_VEC:dword

RCODE	ends			; End RCODE segment


CODEZ	 segment use16 para public 'codez' ; Start CODEZ segment
	 assume  cs:PCODEZ

	public	@SWAT_INI_CODEZ
@SWAT_INI_CODEZ:		; Mark module start in .MAP file

	 FPPROC  INIT_COPY -- Initialize Routine to Copy Tables
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy tables from initialization.

|

	 REGSAVE <eax,cx,si,di,ds,es,fs,gs> ; Save registers

	 push	 seg NGROUP	; Get data segment
	 pop	 fs		; Address it
	 assume  fs:NGROUP	; Tell the assembler about it

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,seg DGROUP	; Get data segment
	 mov	 gs,ax		; Address it
	 assume  gs:DGROUP	; Tell the assembler about it

	 shl	 eax,4-0	; Convert from paras to bytes
	 add	 eax,FVMBASE	; Plus offset of save area
	 mov	 di,ax		; Copy low-order 16 bits of 20-bit address
	 and	 di,@NIB0	; Isolate low-order 4 bits
	 shr	 eax,4-0	; Shift down high-order 16 bits of 20-bit address
	 mov	 es,ax		; ES:DI ==> destination of video tables
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ds,VIDEO_SEG	; Get source segment
	 assume  ds:nothing	; Tell the assembler about it
	 mov	 cx,VIDEO_CNT	; Get # bytes in tables

	 xor	 si,si		; DS:SI ==> video tables
S16  rep movs	 <es:[di].LO,ds:[si].LO> ; Copy to destination

; If there was something in VIDEO_SEG, skip back over its EOM

	 cmp	 VIDEO_CNT,0	; Anybody home?
	 je	 short @F	; Jump if not

	 sub	 di,size FVM_STR ; Skip back over header
@@:
	 mov	 ds,DVGA_SEG	; Get source segment
	 assume  ds:nothing	; Tell the assembler about it
	 mov	 cx,DVGA_CNT	; Get # bytes in tables

	 xor	 si,si		; DS:SI ==> DVGA tables
S16  rep movs	 <es:[di].LO,ds:[si].LO> ; Copy to destination








	 REGREST <gs,fs,es,ds,di,si,cx,eax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_COPY endp			; End INIT_COPY procedure

	 DPALIGN INIT_COPY	; Ensure on para-boundary for DGROUP calculations

	 public  ZTAIL
ZTAIL	 label	 byte		; Note the PARA-alignment of this segment

CODEZ	 ends			; End CODEZ segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP,ds:PGROUP

	public	@SWAT_INI_PROG
@SWAT_INI_PROG: 		; Mark module start in .MAP file

	 extrn	 SETUP_CR3:near
	extrn	SET_LBR:near
	 extrn	 GETLBASE:near
	 extrn	 SWATINI:tbyte
	 extrn	 U32_DRAINPIQ:near
	 extrn	 SYMAPPND_COM:near
	 extrn	 SEL2GDT:near
	 extrn	 DEVLOAD:byte

	 public  NMIPORT,NMIENA,NMIDIS,NMIMASK
NMIPORT  dw	 @CMOS_CMD	; NMI clear I/O port
NMIENA	 db	 @CMOS_ENANMI	; ... enable value
NMIDIS	 db	 @CMOS_DISNMI	; ... disable value
NMIMASK  db	 mask $ATPAR	; ... clear mask

;;;;;;;  FPPROC  FDW2HEX -- Far call to DW2HEX
;;;;;;;  assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;;;;;
;;;;;;;  call	 DW2HEX
;;;;;;;
;;;;;;;  ret
;;;;;;;
;;;;;;;  assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;;;;;
;;;;;;;FDW2HEX	 endp			; End FDW2HEX procedure
	NPPROC	INIT_IDT -- Initialize The IDT Entries
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize the IDT entries.

On entry:

ES:EBX	==>	IDT
EDX	=	IDT limit

|

	REGSAVE <eax,ecx>	; Save registers

; Should we initialize INT 00h?

	 test	 ARG_FLAG,@ARG_DIVO ; Initialize INT 00h?
	 jz	 short @F	; Not this time

	 IDTMAC  00h,00,LCL,OLD ; IDT to OLD, LCL to IDT (EAX clobbered)

	 or	 LC4_FLAG,@LC4_DIVO ; Mark as intercepted
@@:

; Should we initialize INT 01h?

	 test	 ARG_FLAG,@ARG_STEP ; Initialize INT 01h?
	 jz	 short @F	; Not this time

	 IDTMAC  01h,01,LCL,OLD ; IDT to OLD, LCL to IDT (EAX clobbered)

	 or	 LC3_FLAG,@LC3_STEP ; Mark as intercepted
@@:

; Should we initialize INT 02h?

	 test	 ARG_FLAG,@ARG_NMI ; Initialize INT 02h?
	 jz	 short @F	; Not this time

	 IDTMAC  02h,02,LCL,OLD ; IDT to OLD, LCL to IDT (EAX clobbered)

	 or	 LCL_FLAG,@LCL_NMI ; Mark as intercepted
@@:

; Should we initialize INT 03h?

	 test	 ARG_FLAG,@ARG_SKIP ; Initialize INT 03h?
	 jz	 short @F	; Not this time

	 IDTMAC  03h,03,LCL,OLD ; IDT to OLD, LCL to IDT (EAX clobbered)

	 or	 LC3_FLAG,@LC3_SKIP ; Mark as intercepted
@@:

; Should we initialize INT 05h?

	 test	 ARG_FLAG,@ARG_BOUND ; Initialize INT 05h?
	 jz	 short @F	; Not this time

	 IDTMAC  05h,05,LCL,OLD ; IDT to OLD, LCL to IDT (EAX clobbered)

	 or	 LC4_FLAG,@LC4_BOUND ; Mark as intercepted
@@:

; Should we initialize INT 06h?

	 test	 ARG_FLAG,@ARG_INV ; Initialize INT 06h?
	 jz	 short @F	; Not this time

	 IDTMAC  06h,06,LCL,OLD ; IDT to OLD, LCL to IDT (EAX clobbered)

	 or	 LC3_FLAG,@LC3_INV ; Mark as intercepted
@@:

; Initialize INT 09h for Clt-Alt-Pad5

	 mov	 ecx,09h	; Get typical IRQ1 holder

	 test	 DBG_FLAG,@DBG_IBV ; Use IBV value?
	 jz	 short @F	; Jump if not

	 movzx	 ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	 inc	 ecx		; Skip to keyboard interrupt (IRQ1)
@@:
	 cmp	 edx,ecx	; Check against maximum interrupt #
	 jbe	 short @F	; Jump if out of range

	 IDTMAC  ecx,09,LCL,OLD ; IDT to OLD, LCL to IDT (EAX clobbered)
@@:

; Should we initialize INT 0Ah?

	 test	 AR2_FLAG,@AR2_TSS ; Initialize INT 0Ah?
	 jz	 short @F	; Not this time

	 IDTMAC  0Ah,0A,LCL,OLD ; IDT to OLD, LCL to IDT (EAX clobbered)

	 or	 LC3_FLAG,@LC3_TSS ; Mark as intercepted
@@:

if @IRQCODE
; Initialize INT 0Bh for COM2/COM4

	 mov	 ecx,0Bh	; Get typical IRQ3 holder

	 test	 DBG_FLAG,@DBG_IBV ; Use IBV value?
	 jz	 short @F	; Jump if not

	 movzx	 ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	 add	 ecx,$COM24	; Skip to COM2/COM4 interrupt (IRQ3)
@@:
	 cmp	 edx,ecx	; Check against maximum interrupt #
	 jbe	 short @F	; Jump if out of range

	 IDTMAC  ecx,0B,LCLREM,OLDREM ; IDT to OLDREM, LCLREM to IDT (EAX clobbered)
@@:

; Initialize INT 0Ch for COM1/COM3

	 mov	 ecx,0Ch	; Get typical IRQ4 holder

	 test	 DBG_FLAG,@DBG_IBV ; Use IBV value?
	 jz	 short @F	; Jump if not

	 movzx	 ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	 add	 ecx,$COM13	; Skip to COM1/COM3 interrupt (IRQ4)
@@:
	 cmp	 edx,ecx	; Check against maximum interrupt #
	 jbe	 short @F	; Jump if out of range

	 IDTMAC  ecx,0C,LCLREM,OLDREM ; IDT to OLDREM, LCLREM to IDT (EAX clobbered)
@@:
endif				; IF @IRQCODE

; Should we initialize INT 0Ch?

	 test	 AR2_FLAG,@AR2_STACK ; Check state
	 jz	 short @F	; Not this time

	 IDTMAC  0Ch,0C,LCL,OLD ; IDT to OLD, LCL to IDT (EAX clobbered)

	 or	 LC3_FLAG,@LC3_STK ; Mark as intercepted
@@:

; Should we initialize INT 0Dh?

	 test	 ARG_FLAG,@ARG_GENP ; Check state
	 jz	 short @F	; Not this time

	 IDTMAC  0Dh,0D,LCL,OLD ; IDT to OLD, LCL to IDT (EAX clobbered)

	 or	 LCL_FLAG,@LCL_GENP ; Mark as intercepted
@@:

; Should we initialize INT 0Eh?

	 test	 ARG_FLAG,@ARG_PAGE ; Check state
	 jz	 short @F	; Not this time

	 IDTMAC  0Eh,0E,LCL,OLD ; IDT to OLD, LCL to IDT (EAX clobbered)

	 or	 LCL_FLAG,@LCL_PAGE ; Mark as intercepted
@@:

; Should we intercept INT 41h for Windows kernel debugging?
; This interrupt is called from PM under control of Windows
; only if we responded to the appropriate INT 68h inquiry function.

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Are we in W?
	jz	short @F	; Jump if not

	test	WKD_FLAG,@WKD_ENABLE ; Izit enabled?
	jz	short @F	; Jump if not

	cmp	edx,41h 	; Check against maximum interrupt #
	jbe	short @F	; Jump if out of range

	IDTMAC	41h,41,LCL,OLD	; IDT to OLD, LCL to IDT (EAX clobbered)
@@:

; Intercept INT 67h for VCPI code

	 cmp	 edx,67h	; Check against maximum interrupt #
	 jbe	 short @F	; Jump if out of range

	 IDTMAC  67h,67,LCL,OLD ; IDT to OLD, LCL to IDT (EAX clobbered)
@@:

; Should we intercept INT 68h for Windows kernel debugging?

	test	WKD_FLAG,@WKD_ENABLE ; Izit enabled?
	jz	short @F	; Jump if not

	cmp	edx,68h 	; Check against maximum interrupt #
	jbe	short @F	; Jump if out of range

	IDTMAC	68h,68,LCL,OLD	; IDT to OLD, LCL to IDT (EAX clobbered)
@@:
	REGREST <ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_IDT endp			; End INIT_IDT procedure
	 FPPROC  INIT_PROT -- Protected Mode Initialization Code
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Protected mode initialization code.

|

	 push	 ds		; Save register

	 SETDATA ds		; Set data selector into DS
	 assume  ds:DGROUP	; Tell the assembler about it
COMMENT|

If the old (pre-WKD) VxD is active, it calls INIT_PROT and REST_PROT
for us.  With our new support for WKD, we also call those functions
during Windows startup and termination (INT 2Fh/AX=1605h), hence we
need to avoid duplication.  The variable INIT_COUNT is incremented and
decremented in INIT_PROT and REST_PROT, respectively to be backwards
compatible.

|

	inc	INIT_COUNT	; Count in another call

	cmp	INIT_COUNT,1	; Is the count normal?
	ja	near ptr INIT_PROT_EXIT1 ; Jump if not

; Ensure that the B-bit is set in our data selector

	 REGSAVE <ebx,ds>	; Save for a moment

	 xor	 ebx,ebx	; Zero to use as dword
	 mov	 bx,ds		; Copy our data selector

	 mov	 ds,COMMON.FILE_4GB ; Get all memory selector
	 assume  ds:AGROUP	; Tell the assembler about it

	 call	 SEL2GDT	; Convert selector in EBX to GDT address in EBX

	 or	 AGROUP:[ebx].DESC_SEGLM1,mask $DTE_B ; Ensure set

	 REGREST <ds,ebx>	; Restore
	 assume  ds:DGROUP	; Tell the assembler about it

; Switch to a new stack so we don't impinge on the caller's stack

	 mov	 OLDSTK_FVEC.FOFF,esp ; Save to restore later
	 mov	 OLDSTK_FVEC.FSEL,ss ; ...

	 mov	 INISTK_FVEC.FSEL,ds ; Save as LCL stack selector

	 lss	 esp,INISTK_FVEC ; Switch to our own stack
	 assume  ss:nothing	; Tell the assembler about it

	 REGSAVE <eax,ebx,ecx,edx,esi,es,gs> ; Save registers

	 mov	 es,COMMON.FILE_4GB ; Get all memory selector
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 OLDCR3,0	; Reset previous CR3 value for video PTE checking

	 call	 SETUP		; Ensure setup code executed first

	GET_TSC OLD		; Get current Time Stamp Counter
	call	SET_LBR 	; Enable the LBR registers

; If we're device loaded (RM or VM-VCPI) and are now initializing for
; Windows, we need to remember that state, but clear our @DEVL_LOAD bit
; so we return to the caller (Windows) instead of try to return to the
; device loaded state.

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Are we in Windows?
	jz	short INIT_PROT_XWIN ; Jump if not

	test	DEVLOAD,@DEVL_LOAD ; Are we loading as device driver?
	jz	short INIT_PROT_XWIN ; Jump if not

	mov	eax,SWATCODE	; Get base address of PGROUP
	assume	es:PGROUP	; Tell a white lie
	and	DEVLOAD[eax],not @DEVL_LOAD ; Clear so we return properly
	or	DEVLOAD[eax],@DEVL_WIN3 ; Mark as having been device loaded
	assume	es:AGROUP	; Retract nose
INIT_PROT_XWIN:

; Initialize various buffers if the first time

	 bts	 LC2_FLAG,$LC2_LSTSCR ; Izit already initialized?
	 jc	 short INIT_PROT1 ; Jump if so

	 mov	 edx,PPLSTBUF_TAB ; Get ptr to last screen buffer table
	 mov	 edi,PLSTBUF_INI ; Get offset in DGROUP of initial last screen buffer
	 mov	 ecx,NLSTBUF	; Get # last screen buffers
	 xor	 ebx,ebx	; Index into PLSTBUF_TAB
	 xor	 eax,eax	; Initialize to all zeros

	 push	 es		; Save for a moment

	 SETDATA es		; Set data selector into DS
	 assume  es:DGROUP	; Tell the assembler about it
INIT_PROT_NEXTSCR:
	 mov	 DGROUP:[edx+ebx*(type PLSTBUF_STR)].PLSTBUF,edi ; Save offset
				; in PLSTBUF_TAB
	 push	 ecx		; Save loop counter

	 mov	 ecx,@SCRSIZE shr (2-0) ; Get screen size in dwords
     rep stos	 DGROUP:[edi].EDD ; Initialize it

	 pop	 ecx		; Restore

	 inc	 ebx		; Skip to next entry

	 loop	 INIT_PROT_NEXTSCR ; Jump if more

; Initialize the WKD Load Segment buffers

	test	WKD_FLAG,@WKD_ENABLE ; Izit enabled?
	jz	short @F	; Jump if not (no LS buffers)

	mov	edi,PWKDLS	; Get offset in DGROUP
	imul	ecx,WKDLS_CNT,type WKDLS_STR ; Get size of buffers
	mov	al,0		; Set to this value
    rep stos	DGROUP:[edi].LO ; Initialize it
@@:

; Initialize the command history buffer

	mov	edi,CMDHIST_OFF ; Get offset in DGROUP
	mov	ecx,CMDHIST_LEN ; Get size of buffers
	mov	al,0		; Set to this value
    rep stos	DGROUP:[edi].LO ; Initialize it

	 pop	 es		; Restore
	 assume  es:AGROUP	; Tell the assembler about it
INIT_PROT1:

; Establish addressibility to IDT

	 sub	 esp,size DTR_STR ; Make room on stack
	 SIDTD	 [esp].EDF	; Save IDTR on stack
	 mov	 ebx,[esp].DTR_BASE ; ES:EBX ==> IDT
	 movzx	 edx,[esp].DTR_LIM ; EDX = IDT limit
	 add	 esp,size DTR_STR ; Strip from stack

	 test	 DEVLOAD,@DEVL_INTRUDE ; Are we INTRUDEing today?
	 jz	 short @F	; Jump if not

	 mov	 ebx,RUD_IDTR.DTR_BASE ; Get base address
	 movzx	 edx,RUD_IDTR.DTR_LIM  ; Get limit
@@:
	 inc	 edx		; Convert from limit to length
	 shr	 edx,3-0	; Convert from bytes to qwords (and INTs)
	 mov	 MAXINT,edx	; Save for REST_PROT

	call	INIT_IDT	; Initialize the IDT entries at ES:EBX, lim EDX

; Ensure that the GD bit is set in DR7 as otherwise,
; some programs (OK, it's Windows) can (and will) clobber
; our debug registers.

	test	LC4_FLAG,@LC4_NOGD ; Should we skip this?
	jnz	short @F	; Jump if so

	bts	FORCE_DR7,$GD	; Set unless already set
	jc	short @F	; Jump if already set

	public	INIT_PROT_DR7R
INIT_PROT_DR7R:
	mov	eax,dr7 	; Get the debug control register
	or	eax,FORCE_DR7	; Include forced bits
	public	INIT_PROT_DR7W
INIT_PROT_DR7W:
	mov	dr7,eax 	; Tell the CPU about it
@@:

; Calculate the physical address and offset in DGROUP of our local PDIR

	 mov	 eax,BLCLPDIR	; Get its base address in DGROUP
	 add	 eax,SWATINI.MD_DATA ; Get offset32 to data segment
	 add	 eax,SWATINI.MD_PHYS ; Plus physical address of code segment
	 add	 eax,4*1024-1	; Round up to 4KB boundary
	 and	 eax,not (4*1024-1) ; ...
	 mov	 PaLCLPDIR,eax	; Save as physical address of local PDIR
	 sub	 eax,SWATINI.MD_DATA ; Less offset 32 to data segment
	 sub	 eax,SWATINI.MD_PHYS ; Less physical address of code segment
	 mov	 PLCLPDIR,eax	; Save as offset in DGROUP

	 add	 eax,4*1024	; Skip over local PDIR
;;;;;;; mov	PTMPPAGE,eax	; Save as offset of temp page
	 add	 eax,4*1024	; Skip over temp page

; Use the next two pages as video buffers for monochrome
; and color -- save their offsets in DGROUP.
; Note we use one page for each so we don't have to
; switch PTEs in midstream.

	 mov	 PLCLMONO,eax	; Save as offset in DGROUP
	 add	 eax,4*1024	; Skip over mono buffer

	 mov	 PLCLCOLR,eax	; Save as offset in DGROUP
	 add	 eax,4*1024	; Skip over color buffer

; The next page after that is used to map CR3 -- save its offset in DGROUP

	 mov	 PLCLCR3,eax	; Save as offset in DGROUP
	 add	 eax,4*1024	; Skip over CR3-mapping page

; The next CntINSERT pages are used for the INSERT command

	mov	PINSERT,eax	; Save as offset in DGROUP
	mov	ebx,eax 	; Copy to get phys addr
	add	ebx,SWATINI.MD_DATA ; Get offset32 to data segment
	add	ebx,SWATINI.MD_PHYS ; Plus physical address of code segment
	mov	PaINSERT,ebx	; Save as physical address of 1st INSERT page
	imul	ebx,CntINSERT,4*1024 ; Calc byte size
	add	eax,ebx 	; Skip over the INSERT pages

; The first page after local PDIR is used as a temporary page
; in case PHYS2LIN fails -- save its physical address

	 mov	 eax,PaLCLPDIR	; Get physical address of local PDIR
	 add	 eax,4*1024	; Skip over local PDIR to temp page
	 mov	 PaTMPPAGE,eax	; Save as physical address of temp page

; Clear PCUR_VM_HANDLE in case there's an old value lurking around

	 xor	 eax,eax	; A convenient zero
	 mov	 PCUR_VM_HANDLE.FOFF,eax ; Zero the offset
	 mov	 PCUR_VM_HANDLE.FSEL,ax ; ...	    selector

; If symbols were loaded at real mode init time via SYMLOAD=,
; grab them out of extended memory at EXTSYM_OFF, check to ensure
; they're still intact, and add them to our symbol table.
; Since INIT_PROT may be called several times (e.g. during
; Windows entry/exit) we must ensure we won't try to get them
; out of extended memory a second time.
	 test	 DBG_FLAG,@DBG_PMI ; Was DEBUG=PMI specified?
	 jz	 short INIT_PROT_XPMI ; Jump if not

	test	DEVLOAD,@DEVL_PSWAT ; Izit present?
	jnz	short @F	; Jump if so

	test	DEVLOAD,@DEVL_LOAD ; Are we loading as device driver?
	jnz	short INIT_PROT_XPMI ; Jump if so (active IDT not setup as yet)
@@:
	 int	 1		; Trigger breakpoint
INIT_PROT_XPMI:
	 test	 ARG_FLAG,@ARG_DPMI ; Was SYMLOAD specified?
	 jz	 near ptr INIT_PROT_EXIT ; Jump if not

	 sub	 ecx,ecx	; Prepare to reset count of records at 1.1MB
	 xchg	 ecx,EXTSYM_LEN ; Get number of bytes & reset
	 or	 ecx,ecx	; Are any there?
	 jz	 near ptr INIT_PROT_EXIT ; Jump if none

; Calculate checksum
	 mov	 ebx,EXTSYM_CHKSUM ; Get checksum to compare
	 mov	 esi,EXTSYM_OFF ; Get starting offset in extended memory
	 push	 es		; Get AGROUP selector
	 pop	 gs		; Use GS (assumed by SYMAPPND_COM)
	 assume  gs:AGROUP	; Tell the assembler
	 push	 ds		; Get DGROUP selector
	 pop	 es		; Put it in ES (assumed by SYMAPPND_COM)
	 assume  es:DGROUP	; Tell the assembler
@@:
	 lods	 AGROUP:[esi].LO ; Get byte
	 movzx	 eax,al 	; Convert to dword
	 sub	 ebx,eax	; Subtract from checksum
	 LOOPD	 @B		; Repeat

	 or	 ebx,ebx	; Did the checksum match?
	 jnz	 near ptr INIT_PROT_EXIT ; Jump if not

	 mov	 esi,EXTSYM_OFF ; Get offset within AGROUP
	 mov	 ecx,EXTSYM_COUNT ; Get number of records to add

; Since MAX may not be providing a deep enough stack for all the levels
; we need to go through for adding symbols, we need to set up our own
; stack temporarily using our static file I/O buffer...
	 mov	 SYM_READBUF.FOFF,esp ; Save ESP
	 mov	 SYM_READBUF.FSEL,ss ; Save SS

	 lea	 eax,SYM_READBUF[@SYM_READBUFSIZ] ; Point to end of buffer
	 and	 eax,(not 3)	; Make it dword-aligned
	 mov	 bx,ds		; Get DGROUP selector

	 mov	 ss,bx		; Setup new stack selector
	 assume  ss:nothing	; Tell the assembler
	 mov	 esp,eax	; New top of stack

	 push	 ebp		; Save

	 sub	 esp,size FORW_STR ; Allocate stack space
	 mov	 ebp,esp	; Set up temporary FORW_STR at SS:EBP

	 ; Save EGP registers in FORW_STR
	 mov	 [ebp].FORW_EDI,edi
	 mov	 [ebp].FORW_ESI,esi
	 mov	 [ebp].FORW_EBP,ebp
;;;;;	 mov	 [ebp].FORW_ESP0,esp ; This one never gets used
	 mov	 [ebp].FORW_EBX,ebx
	 mov	 [ebp].FORW_EDX,edx
	 mov	 [ebp].FORW_ECX,ecx
	 mov	 [ebp].FORW_EAX,eax

	 ; Caller return address is probably not needed
;;;;;	 mov	 [ebp].FORW_RET.EDQLO,eip
;;;;;	 mov	 [ebp].FORW_RET.EDQHI.ELO,cs
;;;;;	 mov	 [ebp].FORW_EIP,?
	 mov	 [ebp].FORW_CS,cs

	 sldt	 [ebp].FORW_LDT ; Save LDT

	 pushfd 		; Get our flags
	 pop	 [ebp].FORW_EFL ; Put in structure

	 mov	 [ebp].FORW_ESP,esp ; Save ESP
	 mov	 [ebp].FORW_SS,ss ; Save SS

	 mov	 [ebp].FORW_ES,es ; ...  ES
	 mov	 [ebp].FORW_DS,ds ; ...  DS
	 mov	 [ebp].FORW_FS,fs ; ...  FS
	 mov	 [ebp].FORW_GS,gs ; ...  GS

; SS:EBP ==>	 valid FORW_STR

	 call	 SYMAPPND_COM	; Add to symbol table

	 lea	 esp,[esp+(size FORW_STR)] ; Clear temporary FORW_STR
				; from stack (CF unaffected)

	 pop	 ebp		; Restore

	 lss	 esp,SYM_READBUF.EDF ; Restore saved SS|ESP
	 assume  ss:nothing	; Tell the assembler

	 jnc	 short INIT_PROT_EXIT ; Jump if OK

	test	DEVLOAD,@DEVL_LOAD ; Are we loading as device driver?
	jnz	short INIT_PROT_EXIT ; Jump if so (active IDT not setup as yet)

	 int	 3		; Call the debugger
INIT_PROT_EXIT:
	 REGREST <gs,es,esi,edx,ecx,ebx,eax> ; Restore
	 assume  es:nothing,gs:nothing ; Tell the assembler about it

	 lss	 esp,OLDSTK_FVEC ; Switch back to caller's stack
	 assume  ss:nothing	; Tell the assembler about it
INIT_PROT_EXIT1:
	btr	WKD_FLAG,$WKD_PMINIT ; Stop on PMINIT?
	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it
	jnc	short @F	; Jump if not

	int	01h		; Call ourselves
@@:
	 RETFD			; Return to caller (32-bit)

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_PROT endp			; End INIT_PROT procedure
	 FPPROC  REST_PROT -- Restore Protected Mode Initialization
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore previous protected mode initializations

|

	pushad			; Save registers
	REGSAVE <ds,es> 	; ...

	 SETDATA ds		; Set data selector into DS
	 assume  ds:DGROUP	; Tell the assembler about it

	dec	INIT_COUNT	; Count out another call

	cmp	INIT_COUNT,0	; Is the count normal?
	ja	near ptr REST_PROT_EXIT ; Jump if not

	 mov	 es,COMMON.FILE_4GB ; Get all memory selector
	 assume  es:AGROUP	; Tell the assembler about it

; If we loaded as a device driver and are coming back from Windows,
; restore the bit settings

	test	DEVLOAD,@DEVL_WIN3 ; Were we device loaded?
	jz	short @F	; Jump if not

	mov	eax,SWATCODE	; Get base address of PGROUP
	assume	es:PGROUP	; Tell a white lie
	or	DEVLOAD[eax],@DEVL_LOAD ; Mark as such
	and	DEVLOAD[eax],not @DEVL_WIN3 ; Clear for next time
	assume	es:AGROUP	; Retract nose
@@:
	 mov	 OLDCR3,0	; Reset previous CR3 value for video PTE checking

; Establish addressibility to IDT

	 sub	 esp,size DTR_STR ; Make room on stack
	 SIDTD	 [esp].EDF	; Save IDTR on stack
	 mov	 ebx,[esp].DTR_BASE ; ES:EBX ==> IDT
	 mov	 edx,MAXINT	; Get maximum interrupt # from INIT_PROT
	 add	 esp,size DTR_STR ; Strip from stack

; Should we uninitialize INT 00h?

	 test	 ARG_FLAG,@ARG_DIVO ; Uninitialize INT 00h?
	 jz	 short @F	; Not this time

	 IDTMAC  00h,00,OLD	; OLD to IDT (EAX clobbered)
@@:

; Should we uninitialize INT 01h?

	 test	 LC3_FLAG,@LC3_STEP ; Uninitialize INT 01h?
	 jz	 short @F	; Not this time

	 IDTMAC  01h,01,OLD	; OLD to IDT (EAX clobbered)

	 and	 LC3_FLAG,not @LC3_STEP ; Mark as not intercepted
@@:

; Should we uninitialize INT 02h?

	 test	 LCL_FLAG,@LCL_NMI ; Uninitialize INT 02h?
	 jz	 short @F	; Not this time

	 IDTMAC  02h,02,OLD	; OLD to IDT (EAX clobbered)

	 and	 LCL_FLAG,not @LCL_NMI ; Mark as not intercepted
@@:

; Should we uninitialize INT 03h?

	 test	 LC3_FLAG,@LC3_SKIP ; Uninitialize INT 03h?
	 jz	 short @F	; Not this time

	 IDTMAC  03h,03,OLD	; OLD to IDT (EAX clobbered)

	 and	 LC3_FLAG,not @LC3_SKIP ; Mark as not intercepted
@@:

; Should we uninitialize INT 05h?

	 test	 ARG_FLAG,@ARG_BOUND ; Uninitialize INT 05h?
	 jz	 short @F	; Not this time

	 IDTMAC  05h,05,OLD	; OLD to IDT (EAX clobbered)
@@:

; Should we uninitialize INT 06h?

	 test	 LC3_FLAG,@LC3_INV ; Uninitialize INT 06h?
	 jz	 short @F	; Not this time

	 IDTMAC  06h,06,OLD	; OLD to IDT (EAX clobbered)

	 and	 LC3_FLAG,not @LC3_INV ; Mark as not intercepted
@@:

; Uninitialize INT 09h for Clt-Alt-Pad5

	 mov	 ecx,09h	; Get typical IRQ1 holder

	 test	 DBG_FLAG,@DBG_IBV ; Use IBV value?
	 jz	 short @F	; Jump if not

	 movzx	 ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	 inc	 ecx		; Skip to keyboard interrupt (IRQ1)
@@:
	 cmp	 edx,ecx	; Check against maximum interrupt #
	 jbe	 short @F	; Jump if out of range

	 IDTMAC  ecx,09,OLD	; OLD to IDT (EAX clobbered)
@@:

; Should we uninitialize INT 0Ah?

	 test	 LC3_FLAG,@LC3_TSS ; Uninitialize INT 0Ah?
	 jz	 short @F	; Not this time

	 IDTMAC  0Ah,0A,OLD	; OLD to IDT (EAX clobbered)

	 and	 LC3_FLAG,not @LC3_TSS ; Mark as not intercepted
@@:

if @IRQCODE
; Uninitialize INT 0Bh for COM2/COM4

	 mov	 ecx,0Bh	; Get typical IRQ3 holder

	 test	 DBG_FLAG,@DBG_IBV ; Use IBV value?
	 jz	 short @F	; Jump if not

	 movzx	 ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	 add	 ecx,$COM24	; Skip to IRQ3
@@:
	 cmp	 edx,ecx	; Check against maximum interrupt #
	 jbe	 short @F	; Jump if out of range

	 IDTMAC  ecx,0B,OLDREM	; OLDREM to IDT (EAX clobbered)
@@:

; Should we uninitialize INT 0Ch?

	 test	 LC3_FLAG,@LC3_STK ; Uninitialize INT 0Ch?
	 jz	 short @F	; Not this time

	 IDTMAC  0Ch,0C,OLD	; OLD to IDT (EAX clobbered)

	 and	 LC3_FLAG,not @LC3_STK ; Mark as not intercepted
@@:

; Uninitialize INT 0Ch for COM1/COM3

	 mov	 ecx,0Ch	; Get typical IRQ4 holder

	 test	 DBG_FLAG,@DBG_IBV ; Use IBV value?
	 jz	 short @F	; Jump if not

	 movzx	 ecx,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	 add	 ecx,$COM13	; Skip to IRQ4
@@:
	 cmp	 edx,ecx	; Check against maximum interrupt #
	 jbe	 short @F	; Jump if out of range

	 IDTMAC  ecx,0C,OLDREM	; OLDREM to IDT (EAX clobbered)
@@:
endif				; IF @IRQCODE

; Should we uninitialize INT 0Dh?

	 test	 LCL_FLAG,@LCL_GENP ; Uninitialize INT 0Dh?
	 jz	 short @F	; Not this time

	 IDTMAC  0Dh,0D,OLD	; OLD to IDT (EAX clobbered)

	 and	 LCL_FLAG,not @LCL_GENP ; Mark as not intercepted
@@:

; Should we uninitialize INT 0Eh?

	 test	 LCL_FLAG,@LCL_PAGE ; Uninitialize INT 0Eh?
	 jz	 short @F	; Not this time

	 IDTMAC  0Eh,0E,OLD	; OLD to IDT (EAX clobbered)

	 and	 LCL_FLAG,not @LCL_PAGE ; Mark as not intercepted
@@:

; Unintercept INT 41h for Windows kernel debugging
; This interrupt is called from PM under control of Windows
; only if we responded to the appropriate INT 68h inquiry function.

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Are we in W?
	jz	short @F	; Jump if not

	test	WKD_FLAG,@WKD_ENABLE ; Izit enabled?
	jz	short @F	; Jump if not

	cmp	edx,41h 	; Check against maximum interrupt #
	jbe	short @F	; Jump if out of range

	IDTMAC	41h,41,OLD	; OLD to IDT (EAX clobbered)
@@:

; Unintercept INT 67h for VCPI code

	 cmp	 edx,67h	; Check against maximum interrupt #
	 jbe	 short @F	; Jump if out of range

	 IDTMAC  67h,67,OLD	; OLD to IDT (EAX clobbered)
@@:

; Unintercept INT 68h for Windows kernel debugging

	test	WKD_FLAG,@WKD_ENABLE ; Izit enabled?
	jz	short @F	; Jump if not

	cmp	edx,68h 	; Check against maximum interrupt #
	jbe	short @F	; Jump if out of range

	IDTMAC	68h,68,OLD	; OLD to IDT (EAX clobbered)
@@:

; Reset OLDIBV0

	 mov	 al,SWATINI.MD_IBV0 ; Get master IMR base vector (IRQ0)
	 mov	 OLDIBV0,al	; Reset it

	 and	 LC4_FLAG,not @LC4_SETUP ; Mark as SETUP needs to be run
REST_PROT_EXIT:
	REGREST <es,ds> 	; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it
	popad			; ...

	 RETFD			; Return to caller (32-bit)

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_PROT endp			; End REST_PROT procedure
	 NPPROC  SETUP -- Setup Code
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup code for each time 386SWAT is called.

On entry:

SS:EBP	 ==>	 FORW_STR (for GETLBASE)

|

	 REGSAVE <eax,ebx,ecx,esi,gs> ; Save registers

; Initialize our INT 00h, 01h, 02h, 03h, 05h, 06h, 09h,
;		     0Ah, 0Bh, 0Ch, 0Dh, 0Eh, 41h, 67h, and 68h.
; handler selectors

	 mov	 ax,cs		; Assume we're not INTRUDEing

% ifidni <OEM>,<BET>
	 test	 DEVLOAD,@DEVL_INTRUDE ; Are we INTRUDEing today?
	 jz	 short @F	; Jump if not

	 mov	 ax,MMCODESEL	; Get our future code selector
@@:
endif				; IFIDNI <OEM>,<BET>
	 mov	 LCLINT00_FVEC.FSEL,ax ; Save our selector
	 mov	 LCLINT01_FVEC.FSEL,ax ; ...
	 mov	 LCLINT02_FVEC.FSEL,ax ; ...
	 mov	 LCLINT03_FVEC.FSEL,ax ; ...
	 mov	 LCLINT05_FVEC.FSEL,ax ; ...
	 mov	 LCLINT06_FVEC.FSEL,ax ; ...
	 mov	 LCLINT09_FVEC.FSEL,ax ; ...
	 mov	 LCLINT0A_FVEC.FSEL,ax ; ...
	 mov	 LCLINT0B_FVEC.FSEL,ax ; ...
	 mov	 LCLREMINT0B_FVEC.FSEL,ax ; ...
	 mov	 LCLINT0C_FVEC.FSEL,ax ; ...
	 mov	 LCLREMINT0C_FVEC.FSEL,ax ; ...
	 mov	 LCLINT0D_FVEC.FSEL,ax ; ...
	 mov	 LCLINT0E_FVEC.FSEL,ax ; ...
	 mov	 LCLINT41_FVEC.FSEL,ax ; ...
	 mov	 LCLINT67_FVEC.FSEL,ax ; ...
	 mov	 LCLINT68_FVEC.FSEL,ax ; ...

	 mov	 DIVINT00_FVEC.FSEL,cs ; ...
	 mov	 REGINT06_FVEC.FSEL,cs ; ...
	 mov	 REGINT0D_FVEC.FSEL,cs ; ...

; Save our code/data linear addresses for later use

	 PUSHW	 cs		; Pass selector as argument
	 call	 GETLBASE	; Return with EAX = selector base
	 mov	 SWATCODE,eax	; Save for later use

	 PUSHW	 ds		; Pass selector as argument
	 call	 GETLBASE	; Return with EAX = selector base
	 mov	 SWATDATA,eax	; Save for later use

; Save CR3 in Page Tables to we can address it via PLCLCR3

	call	SETUP_CR3	; Set it up

; Save VCPI code and data base addresses for later use on first entry only

% ifidni <OEM>,<BET>
	 test	 DEVLOAD,@DEVL_INTRUDE ; Are we INTRUDEing today?
	 jnz	 short SETUP_XVCPI ; Jump if so
endif				; IFIDNI <OEM>,<BET>

	 cmp	 VCPIDATA,0	; Has it already been saved?
	 jne	 short SETUP_XVCPI ; Jump if so

	 mov	 eax,SWATCODE	; Get base address of PGROUP
	 mov	 VCPICODE,eax	; Save for later use

	 mov	 eax,SWATDATA	; Get base address of DGROUP
	 mov	 VCPIDATA,eax	; Save for later use

	test	DEVLOAD,@DEVL_XDTE2 ; Is there a spare DTE?
	jnz	short SETUP_XDTE2 ; Jump if not

	 mov	 ax,cs		; Get code selector
	 add	 ax,2*(size DESC_STR) ; Skip to spare entry

	 push	 ax		; Pass selector as argument
	 call	 GETLBASE	; Return with EAX = selector base
	 jc	 short SETUP_XDTE2 ; Jump if we're conserving selectors

	 mov	 VCPICODE,eax	; Save for later use
	 add	 VCPIDATA,eax	; Plus code base to get to data base

	 PUSHW	 cs		; Pass selector as argument
	 call	 GETLBASE	; Return with EAX = selector base
;;;;;;;; jc	 ???		; Ignore error return

	 sub	 VCPIDATA,eax	; Less code base to get differential
SETUP_XDTE2:
	 mov	 eax,cs 	; Get our code selector
S16	 lsl	 <eax,eax>	; Get segment limit
	 mov	 VCPICODE_LIM,eax ; Save for later use

	 mov	 eax,ds 	; Get our data selector
S16	 lsl	 <eax,eax>	; Get segment limit
	 mov	 VCPIDATA_LIM,eax ; Save for later use
SETUP_XVCPI:

; Ensure I/O ports 70h/71h are in sync

	 test	 SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
	 jnz	 short SETUP_XT ; Jump if so

	 mov	 al,@CMOS_SHUT	; Register to access shutdown byte
	 out	 @CMOS_CMD,al	; Tell the CMOS about it
	 call	 U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	 in	 al,@CMOS_DATA	; Get the data and ignore it
;;;;;;;; call	 U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
SETUP_XT:
	 or	 LC4_FLAG,@LC4_SETUP ; Mark as having been run

	 REGREST <gs,esi,ecx,ebx,eax> ; Restore
	 assume  gs:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP	 endp			; End SETUP procedure

SET_ATTRS_MAC macro PREF

	 NPPROC  PREF&SET_ATTRS -- Set Screen Attributes
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set screen attributes based upon the value in TXTMODE.

This routine can be called in both real and protected modes.

|

	 REGSAVE <eax,ebx,edx,esi> ; Save registers

	 mov	 ebx,0		; Assume monochrome

	 cmp	 TXTMODE,@TXT_MDA ; Izit monochrome video base?
	 je	 short @F	; Jump if it's monochrome

	 mov	 ebx,1		; It's color
@@:
	 test	 ARG_FLAG,@ARG_LCD ; Izit an LCD?
	 jz	 short @F	; Jump if not

	 mov	 ebx,2		; It's an LCD
@@:
	 mov	 al,ADEF[ebx]	; Get default attr
	 mov	 DEFATTR,al	; Save as the real thing

	 mov	 al,ABAR[ebx]	; Get bar attr
	 mov	 BARATTR,al	; Save as the real thing

	 mov	 al,ASTK[ebx]	; Get stack attr
	 mov	 STKATTR,al	; Save as the real thing

	 mov	 al,ACUR[ebx]	; Get current instruction attr
	 mov	 CURATTR,al	; Save as the real thing

	 mov	 al,ACMD[ebx]	; Get command line attr
	 mov	 CMDATTR,al	; Save as the real thing

	 mov	 al,AERR[ebx]	; Get error message attr
	 mov	 ERRATTR,al	; Save as the real thing

	 mov	 al,ATTL[ebx]	; Get title attr
	 mov	 TTLATTR,al	; Save as the real thing

	 mov	 al,ADBG[ebx]	; Get debug window attr
	 mov	 DBGATTR,al	; Save as the real thing

	 mov	 al,ANDP[ebx]	; Get NDP window attr
	 mov	 NDPATTR,al	; Save as the real thing

	 mov	 ecx,@NHLPCLRS+1 ; Get # help colors supported
	 xor	 esi,esi	; Zero index into HLPATTR
@@:
	 imul	 edx,esi,3	; Skip to the next row
	 mov	 al,AHLP[ebx+edx] ; Get help color attr
	 mov	 HLPATTR[esi],al ; Save as the real thing

	 inc	 esi		; Skip to the next attribute

	 LOOPD	 @B		; Jump if more help colors

	 mov	 al,AHLPA[ebx]	; Get help active attr
	 mov	 HLPAATTR,al	; Save as the real thing

	 mov	 al,AHLPB[ebx]	; Get help background attr
	 mov	 HLPBATTR,al	; Save as the real thing

	 mov	 al,AHTTL[ebx]	; Get help title attr
	 mov	 HTTLATTR,al	; Save as the real thing

	 mov	 al,AHKEY[ebx]	; Get help key attr
	 mov	 HKEYATTR,al	; Save as the real thing

	 mov	 al,AREG[ebx]	; Get register changed attr
	 mov	 REGATTR,al	; Save as the real thing

	 mov	 al,AWRK[ebx]	; Get working window attr
	 mov	 WRKATTR,al	; Save as the real thing

	 mov	 al,ALBL[ebx]	; Get label attr
	 mov	 LBLATTR,al	; Save as the real thing

	 mov	 al,ABPT[ebx]	; Get breakpoint attr
	 mov	 BPTATTR,al	; Save as the real thing

	 mov	 al,ABPC[ebx]	; Get breakpoint on current line attr
	 mov	 BPCATTR,al	; Save as the real thing

	 mov	 al,ALBR[ebx]	; Get LBR window attr
	 mov	 LBRATTR,al	; Save as the real thing

	mov	al,AHSTA[ebx]	; Get command history window attr
	mov	HSTAATTR,al	; Save as the real thing

	mov	al,AHSTB[ebx]	; Get command history window bar attr
	mov	HSTBATTR,al	; Save as the real thing

	 REGREST <esi,edx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&SET_ATTRS endp		; End PREF&SET_ATTRS procedure

	 endm			; SET_ATTRS_MAC

	 SET_ATTRS_MAC U32_	; Define in PGROUP

PROG	 ends			; End PROG segment


XDATA	 segment use16 dword public 'xdata' ; Start XDATA segment
	 assume  ds:XGROUP

	public	@SWAT_INI_XDATA
@SWAT_INI_XDATA label byte	; Mark module start in .MAP file

	 public  XPWTAIL
XPWTAIL  dd	 ?		; Offset to WTAIL

	 public  XOLDINT67_VEC
XOLDINT67_VEC dd ?		; Old INT 67h handler

	 public  XSWATINI
XSWATINI MD_STR  <>		; SWAT initialization structure
				; (copied from SWATINI)
	 public  XARG_FLAG
XARG_FLAG dw	 ?		; Argument flags (copied from ARG_FLAG)

	 public  XFILPTR
XFILPTR  dd	 ?		; Pointer to filename.ext and command line args

	 public  XEXEHDR
XEXEHDR  EXE_STR <>		; SWAT's EXE header

XDATA	 ends			; End XDATA segment


XDATAZ	 segment use16 para public 'xdataz' ; Start XDATAZ segment
	 assume  ds:XGROUP

	 public  XTAIL
XTAIL	 label	 byte

XDATAZ	 ends			; End XDATAZ segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	public	@SWAT_INI_XCODE
@SWAT_INI_XCODE:		; Mark module start in .MAP file

	 FPPROC  INIT_VIRT -- Virtual Mode Initialization Code
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Virtual mode initialization code

Check to see if DPMI services are active (NODPMI not specified)
and pass the host flags up to SWAT.

|

	 pushad 		; Save EGP regs
	 REGSAVE <ds,es>	; Save registers

	 test	 XARG_FLAG,@ARG_DBGVMI ; Was DEBUG=VMI specified?
	 jz	 short @F	; Jump if not

	 int	 1		; Call SWAT
@@:

; Open our file to read in the WGROUP info

	 lds	 dx,XFILPTR	; DS:DX ==> filename
	 assume  ds:nothing	; Tell the assembler about it

; Find end of filename and set next byte to zero to make ASCIIZ string

	 mov	 si,dx		; DS:SI ==> filename.ext
@@:
	 lods	 ds:[si].LO	; Get next byte

	 cmp	 al,' '         ; Izit end-of-name?
	 ja	 short @B	; Jump if not

	 dec	 si		; Back off to terminator
	 mov	 al,@OPEN_R	; Function code for read-only
	 mov	 cl,0		; Get ASCIIZ string marker
	 xchg	 cl,ds:[si]	; Swap 'em
	 DOSCALL @OPENF2	; Open our file
	 xchg	 cl,ds:[si]	; Restore
	 jc	 near ptr INIT_VIRT_ERR ; Jump if something went wrong

	 mov	 bx,ax		; Copy to handle register

; To handle the overlay structure, read in the .EXE file header

	 mov	 ax,cs		; Copy current segment (note we can't use
				; seg XGROUP as it might have moved down)
	 mov	 ds,ax		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

	 mov	 cx,size EXE_STR ; Get # bytes to read
	 DOSCALL @READF2,XEXEHDR ; Read in the EXE header
	 jc	 near ptr INIT_VIRT_ERRCLOSE ; Jump if something went wrong

; Move the file pointer to the WINTAB data

	 xor	 eax,eax	; Zero to use as dword
	 mov	 ax,seg WGROUP	; Get segment of WGROUP (were it loaded in memory)
	 sub	 ax,seg PGROUP	; Less starting segment
	 add	 ax,XEXEHDR.EXE_HSIZ ; Plus size of EXE header in paras
	 shl	 eax,4-0	; Convert from paras to bytes

	 mov	 dx,ax		; Copy low-order wqord
	 shr	 eax,16 	; Shift down high-order word
	 mov	 cx,ax		; CX:DX = # bytes to move file pointer
	 mov	 al,0		; Function code relative to start of file
	 DOSCALL @MOVFP2	; Move the file pointer
	 jc	 short INIT_VIRT_ERRCLOSE ; Jump if something went wrong

; Load up the WINTAB stuff from the overlay portion

; Because the size of the overlay might exceed 64KB, we read it in
; in chunks.

@READCHUNK equ	 64*1024-16	; Maximum read chunk (must be /16 and < 64K)

	 mov	 edi,XPWTAIL	; Get # bytes to read
	 lea	 dx,XTAIL	; DS:DX ==> start of buffer
INIT_VIRT_AGAIN:
	 mov	 ecx,edi	; Copy # bytes remaining

	 cmp	 ecx,@READCHUNK ; Izit too big?
	 jbe	 short @F	; Jump if not

	 mov	 ecx,@READCHUNK ; Use maximum
@@:
	 DOSCALL @READF2	; Read in WINTAB
	 jc	 short INIT_VIRT_ERRCLOSE ; Jump if something went wrong

	 cmp	 ax,cx		; Did we get it all?
	 jne	 short INIT_VIRT_ERRCLOSE ; Jump if something went wrong

; Move DS to next read chunk.  Note that DX doesn't change.

	 mov	 ax,ds		; Get current segment
	 add	 ax,@READCHUNK/16 ; Skip to the next chunk
	 mov	 ds,ax		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 sub	 edi,ecx	; Less amount actually read
	 ja	 short INIT_VIRT_AGAIN ; Jump if there's more to read

	 DOSCALL @CLOSF2	; Close the file

; Reset DS and ECX as we clobbered them above

	 mov	 ax,cs		; Copy current segment (note we can't use
				; seg XGROUP as it might have moved down)
	 mov	 ds,ax		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

;;;;;;;; lea	 dx,XTAIL	; DS:DX ==> start of buffer
	 mov	 ecx,XPWTAIL	; Get # bytes to read

; Tell SWAT about it

COMMENT|

Register usage:

BL	 =	 @XFER_WINTAB
ECX	 =	 amount of data to transfer
DS:DX	 ==>	 source data

|

	 mov	 bl,@XFER_WINTAB ; Tell 'em what we're doing
	 XVCPICALL @VCPI_XFERDATA,X ; Request data transfer

	 jmp	 short INIT_VIRT_NEXT ; Join common code

INIT_VIRT_ERRCLOSE:
	 DOSCALL @CLOSF2	; Close the file
INIT_VIRT_ERR:
	 int	 03h		; Call our debugger
INIT_VIRT_NEXT:
	 test	 XSWATINI.MD_ATTR,@MD_WIN3 ; Are we in Windows?
	 jnz	 short INIT_VIRT_EXIT ; Cut out if so

	 test	 XARG_FLAG,@ARG_DPMI ; Are DPMI PL0 services enabled via SYMLOAD?
	 jz	 short INIT_VIRT_NODPMI ; Jump if not

	 mov	 ax,@DPMI_GPME	; Get protected mode entry point
	 int	 2fh		; ES:DI ==> pmode entry
	 assume  es:nothing	; Tell the assembler
	 or	 ax,ax		; Did we succeed?
	 jz	 short @F	; Jump if so

INIT_VIRT_NODPMI:
	 sub	 ax,ax		; Clear host features

	 jmp	 short INIT_VIRT_CALLSWAT ; Join common code

@@:
	 mov	 ax,@HOSTFLAGS_DPMI ; Host supports DPMI
	 test	 bx,1		; Are 32-bit apps supported?
	 jz	 short INIT_VIRT_CALLSWAT ; Jump if not

	 or	 ax,@HOSTFLAGS_DPMI32 ; Host supports 32-bit DPMI clients

INIT_VIRT_CALLSWAT:
	 mov	 bx,ax		; Host features in BX
	 XVCPICALL @VCPI_DBGHOST,X ; Set host feature flags
INIT_VIRT_EXIT:
	 REGREST <es,ds>	; Restore
	 assume  es:nothing	; Tell the assembler
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_VIRT endp			; End INIT_VIRT procedure

XCODE	 ends			; End XCODE segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:NGROUP

	public	@SWAT_INI_NDATA
@SWAT_INI_NDATA  label byte	; Mark module start in .MAP file

	 extrn	 OLDINT67_VEC:dword
	 extrn	 MEMERR_IREAL:byte
	 extrn	 MSG_CHECK_CPUID:byte
	 extrn	 MSG_CHECK_P5:byte
	 extrn	 MSG_CHECK_NDP:byte
	 extrn	 MSG_CHECK_VID:byte
	 extrn	 MSG_CHECK_ARGS:byte
	 extrn	 MSG_CHECK_BPI:byte
	 extrn	 MSG_SET_MONO:byte
	 extrn	 MSG_SET_CO80:byte
	 extrn	 MSG_U16_SET_ATTRS:byte

	 public  ARGPTR,FILPTR
ARGPTR	 dd	 ?		; Pointer to command line arguments
FILPTR	 dd	 ?		; ...	     filename.ext and command line args

	 public  MAPSEG_NXT,MAPSEG_LST
MAPSEG_NXT dw	 ?		; Next available paragraph
MAPSEG_LST dw	 ?		; Last ...

	 public  MSG_COPY
MSG_COPY db	 '386SWAT  -- Version '
	 db	 VERS_H,'.',VERS_T,VERS_U
	 db	 ' -- A Debugger for All Modes',CR,LF
	 db	 '   (C) Copyright 1988-98 Qualitas, Inc.  All rights reserved.',CR,LF,EOS

	 public  INISTK
INISTK	 dw	 256 dup ('ST') ; Local initialization stack
INISTKZ  label	 word

NDATA	 ends			; End NDATA segment


NDATAZ	 segment use16 para public 'ndataz' ; Start NDATAZ segment
	 assume  ds:NGROUP

	 public  NTAIL
NTAIL	 label	 byte

NDATAZ	 ends			; End NDATAZ segment


RDATAZ	 segment use16 para public 'rdataz' ; Start RDATAZ segment
	 assume  ds:RGROUP

	 extrn	 RTAIL_NR:byte

RDATAZ	 ends			; End RDATAZ segment


NCODE	 segment use16 para public 'ncode' ; Start NCODE segment
	 assume  cs:NGROUP,ds:NGROUP

	public	@SWAT_INI_NCODE
@SWAT_INI_NCODE:		; Mark module start in .MAP file

	extrn	CHECK_SHIFT:near
	extrn	CHECK_NXTSEG:near
	extrn	CHECK_ARGS:near
	extrn	U16_DRAINPIQ:near
	extrn	U16_SWATINI:tbyte
	extrn	DISP_PROGMSG:near
	extrn	FCN_NOWINK:near
	extrn	CHECK_PCI_BIOS:near
	extrn	VideoCheck:near
	extrn	SetupMDA:near

	 public  OLDSTK_VEC,INISTK_VEC
OLDSTK_VEC dd	 ?		; Save area for old stack pointer
INISTK_VEC dd	 NGROUP:INISTKZ ; Pointer to local stack

	 SET_ATTRS_MAC U16_	; Define in NGROUP

	 NPPROC  DISP_COPY -- Display Our Copyright Notice
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display our copyright notice.

|

	 REGSAVE <ax,dx,ds>	; Save registers

	 push	 seg NGROUP	; Get our data segment
	 pop	 ds		; Address it
	 assume  ds:NGROUP	; Tell the assembler about it

	 DOSCALL @STROUT,MSG_COPY ; Display the flag

	 REGREST <ds,dx,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_COPY endp			; End DISP_COPY procedure
	 FPPROC  INIT_REAL -- Real Mode Initialization Code
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Real mode initialization code.

On entry:

DS:DX	 ==>	 "d:\path\filename.ext [arguments]",0
DS:SI	 ==>	 "[arguments]",0

On exit:

@MD_RMIE =	 0 if all went OK
	 =	 1 otherwise

|

.8086
	 mov	 OLDSTK_VEC.VOFF,sp ; Save old stack pointer
	 mov	 OLDSTK_VEC.VSEG,ss ; ...
DOT386 p
	 lss	 sp,INISTK_VEC	; Install our local stack
	 assume  ss:nothing	; Tell the assembler about it

	 pushad 		; Save all EGP registers
	 REGSAVE <ds,es,fs,gs>	; Save segment registers

; Establish addressibility to our data

	 push	 seg NGROUP	; Get our data segment
	 pop	 es		; Address it
	 assume  es:NGROUP	; Tell the assembler about it

	 push	 seg DGROUP	; Get our data segment
	 pop	 fs		; Address it
	 assume  fs:DGROUP	; Tell the assembler about it

	 push	 seg PGROUP	; Get our data segment
	 pop	 gs		; Address it
	 assume  gs:PGROUP	; Tell the assembler about it

	 mov	 ARGPTR.VSEG,ds ; Save as segment of arguments
	 mov	 ARGPTR.VOFF,si ; ...	  offset ...

	 mov	 FILPTR.VSEG,ds ; Save as segment of filename.ext arguments
	 mov	 FILPTR.VOFF,dx ; ...	  offset ...

	 push	 seg XGROUP	; Get our data segment
	 pop	 ds		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

	 mov	 eax,FILPTR	; Get Seg:Off of device driver
	 mov	 XFILPTR,eax	; Save for later use

	 push	 seg NGROUP	; Get our data segment
	 pop	 ds		; Address it
	 assume  ds:NGROUP	; Tell the assembler about it

	 test	 DEVLOAD,@DEVL_LOAD ; Are we loading as device driver?
	 jnz	 short @F	; Jump if so (already displayed)

	 call	 DISP_COPY	; Display our copyright notice
	 DOSCALL @STROUT,MSG_LOADSWAT ; Tell 'em what we're doing
	call	FCN_NOWINK	; Disallow Windows Kernel Debugger services

	 call	 CHECK_SHIFT	; Check on shift key state

; Set MAPSEG_LST for later use

	 int	 12h		; Get top of DOS memory
	 shl	 ax,10-4	; Convert from 1KB to paras
	 mov	 MAPSEG_LST,ax	; Save for later use
@@:

; Transfer incoming attributes to U16_SWATINI in NGROUP
; Notice that we don't pick up any attributes set by us

	 mov	 eax,SWATINI.MD_ATTR ; Get incoming attributes
	 mov	 U16_SWATINI.MD_ATTR,eax ; Save for later use

;;;;;;;  push	 ds		; Save
;;;;;;;
;;;;;;;  push	 seg DGROUP	; Address for DW2HEX
;;;;;;;  pop	 ds		; Address it
;;;;;;;  assume  ds:DGROUP	; Tell the assembler
;;;;;;;
;;;;;;;  mov	 ax,seg PGROUP	; Segment to display
;;;;;;;  lea	 di,NGROUP:GMSG_PGROUP ; Destination of HEX string
;;;;;;;  call	 FDW2HEX	; Convert AX to HEX at ES:DI
;;;;;;;
;;;;;;;  pop	 ds		; Restore
;;;;;;;  assume  ds:NGROUP	; Tell the assembler
;;;;;;;
;;;;;;;  DOSCALL @STROUT,GROUPMSG ; DIsplay group segment
;;;;;;;
; Check on CPU id

	 STROUT  CHECK_CPUID
	 call	 CHECK_CPUID	; Determine type
	 jnc	 short @F	; Jump if it's a 386

	 or	 LC2_FLAG,@LC2_486 ; Indicate it's a 486
	mov	CPUFAM,04h	; ...

	 STROUT  CHECK_P5
	 call	 CHECK_P5	; Set CPUFET_FLAG
@@:

; Check on 287/387 presence

	 STROUT  CHECK_NDP
	 call	 CHECK_NDP	; Check it

; Check on video adapter presence

	 STROUT  CHECK_VID
	 call	 CHECK_VID	; Check it

; Check on PCI BIOS

	call	CHECK_PCI_BIOS	; Check it

; Set para of end of data

	 lea	 ax,NGROUP:NTAIL[16-1] ; Get offset of end of NGROUP

	 test	 DEVLOAD,@DEVL_LOAD ; Are we loading as device driver?
	 jz	 short @F	; Jump if not

	 lea	 ax,RGROUP:RTAIL_NR[16-1] ; Get offset of end of RGROUP
@@:
	 shr	 ax,4-0 	; Convert from bytes to paras
	 add	 ax,seg RGROUP	; Plus its starting paragraph
	 mov	 MAPSEG_NXT,ax	; Save for later use

	 push	 offset NGROUP:MEMERR_IREAL ; Pass offset of error message
	 call	 CHECK_NXTSEG	; Ensure we've enough room

; Get DOS busy flag pointer and convert it to an offset within AGROUP

	 REGSAVE <es>		; Save

	 DOSCALL @DOSPTR	; ES:BX ==> InDOS flag
	 assume  es:nothing	; Tell the assembler

	 mov	 ax,es		; Segment portion
	 movzx	 eax,ax 	; Clear high order word
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 ebx,bx 	; Clear high order word
	 add	 eax,ebx	; Add offset to segment
	 mov	 LaINDOS,eax	; Save normalized linear address

	 REGREST <es>		; Restore
	 assume  es:NGROUP	; Tell the assembler

; Normalize SWATINI.MD_SIZE and SWATINI.MD_DATA to 32-bit linear addresses

	 movzx	 eax,SWATINI.MD_SIZE.VSEG ; Get the segment
	 sub	 ax,seg PGROUP	; Less starting segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 ebx,SWATINI.MD_SIZE.VOFF ; Get the offset
	 add	 eax,ebx	; Add to get 32-bit linear address
	 mov	 SWATINI.MD_SIZE,eax ; Save back

	 movzx	 eax,SWATINI.MD_DATA.VSEG ; Get the segment
	 sub	 ax,seg PGROUP	; Less starting segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 ebx,SWATINI.MD_DATA.VOFF ; Get the offset
	 add	 eax,ebx	; Add to get 32-bit linear address
	 mov	 SWATINI.MD_DATA,eax ; Save back

; Normalize SWATINI.MD_VSIZE to a 32-bit length

	 movzx	 eax,SWATINI.MD_VSIZE.VSEG ; Get the segment
	 sub	 ax,seg XGROUP	; Less starting segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 ebx,SWATINI.MD_VSIZE.VOFF ; Get the offset
	 add	 eax,ebx	; Add to get 32-bit linear address
	 mov	 SWATINI.MD_VSIZE,eax ; Save back

; Zero segment fields of MD_IPROT and MD_RPROT

; The MS linker fixes up a DF (Ptr 16:32) field as if it were a Ptr 16:16
; field.  Thus, they put the segment fixup in FOFF.VSEG instead of FSEL.
; Wherever it is, we need to subtract it out.

	mov	ebx,FSEL	; Assume it's done correctly

	cmp	SWATINI.MD_IPROT.FSEL,0 ; Izit unfixed?
	jne	short @F	; Jump if not

	mov	ebx,FOFF.VSEG	; It's MS link up to its old tricks
@@:
	mov	ax,seg PGROUP	; Get the fixup value put in by the LINKer
	sub	SWATINI.MD_IPROT.ELO[ebx],ax ; Zero the field
	sub	SWATINI.MD_RPROT.ELO[ebx],ax ; ...

	or	ARG_FLAG,@ARG_LOADHI ; Mark LOADHIGH as the default

; Parse the command line

	STROUT	CHECK_ARGS
	call	CHECK_ARGS	; Check for arguments
	jc	near ptr INIT_REAL_ERR ; Jump if something went wrong

	STROUT	CHECK_BPI
	call	CHECK_BPI	; Check on breakpoint interrupts

; Flesh out the video adapter possibilities

	call	VideoCheck	; Check it out

	call	SetupMDA	; Setup MDA if present

; If there are no monochrome or dual PCI VGA adapters present,
; disable Windows Kernel Debugger services

	test	LCL_FLAG,@LCL_MDA or @LCL_DPCI ; Mono or dual PCI VGA adapters present?
	jnz	short @F	; Jump if so

	call	FCN_NOWINK	; Disable WKD services
@@:

; If the user specified LOADLOW, zero the MD_VSIZE field
; so the caller will not attempt to load us into extended memory
; after INIT_REAL nor relocate our INIT_VIRT code.

	test	ARG_FLAG,@ARG_LOADHI ; Izit present?
	jnz	short @F	; Jump if so

	mov	SWATINI.MD_VSIZE,0 ; Clear it
@@:

; If we're running with a DPMI host active and SYMLOAD was present
; in SWAT profile, enable PL0 DPMI services.
; In INIT_VIRT, we can find out if services are available.

	test	ARG_FLAG,@ARG_DPMI ; Were DPMI PL0 services requested?
	jz	short @F	; Jump if not

	test	AR2_FLAG,@AR2_DPMITMP ; Are they temporary?
	jnz	short @F	; Jump if so

	or	SWATINI.MD_ATTR,@MD_DPMI ; Enable PL0 calls to DPMI services
				; This will cause MAX to add a HPDA contiguous
				; to MAX's high DOS allocation.
@@:
; Find start of DOS memory allocation chain

	 push	 es		; Save for a moment

	 DOSCALL @GETLST	; Get DOS variables
	 assume  es:nothing	; Tell the assembler about it

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,es		; Copy segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 ebx,bx 	; Zero to use as dword
	 add	 eax,ebx	; Add to get linear address
	 mov	 LaLSTLST,eax	; Save for later use

	 movzx	 eax,es:[bx-2].ELO  ; Get the DOS MAC segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 MACBASE,eax	; Save for later use
;;;;;;;; mov	 MACMODE,@ADDR_SEP ; Mark as VM86, separator
;;;;;;;; mov	 MACOFF,0	; Offset is zero

	 pop	 es		; Restore
	 assume  es:NGROUP	; Tell the assembler about it

COMMENT|

Set screen attributes for Monochrome or Color adapters.

If only one is present, use it.
If alternate screen is specified, use monochrome.
Otherwise, use color.

|

	 mov	 TXTMODE,@TXT_MDA ; Use monochrome

	 test	 LCL_FLAG,@LCL_BOTH ; Both adapters present?
	 jz	 short INIT_REAL1 ; Not this time

	 test	 LCL_FLAG,@LCL_MONO ; Use monochrome adapter?
	 jnz	 short INIT_REAL1 ; Jump if so

	 push	 ds		; Save for a moment

	 push	 seg BIOSDATA	; Get segment of BIOS data area
	 pop	 ds		; Address it
	 assume  ds:BIOSDATA	; Tell the assembler about it

	 cmp	 CRT_MODE,@TXT_MDA ; Currently mono mode?
	 pop	 ds		; Restore
	 assume  ds:NGROUP	; Tell the assembler about it
	 je	 short @F	; Yes

	 mov	 TXTMODE,@TXT_CLR ; Use color
@@:
	 test	 ARG_FLAG,@ARG_ALTSCR ; Alternate screen specified?
	 jz	 short INIT_REAL2 ; No, use current mode

	 xor	 TXTMODE,@TXT_FLIP ; Toggle the text mode

	 jmp	 short INIT_REAL2 ; Join common code

INIT_REAL1:
	 test	 LCL_FLAG,@LCL_MDA ; Mono adapter present?
	 jnz	 short INIT_REAL2 ; Yes, use it

	 mov	 TXTMODE,@TXT_CLR ; use color
INIT_REAL2:

; Assume monochrome type

	 STROUT  SET_MONO
	 call	 SET_MONO	; Mark as Mono video

	 cmp	 TXTMODE,@TXT_MDA ; Izit true?
	 je	 short @F	; Jump if so

	 STROUT  SET_CO80
	 call	 SET_CO80	; Mark as CO80 video
@@:

; Initialize default attributes

	 push	 ds		; Save for a moment

	 push	 seg DGROUP	; Get our data segment
	 pop	 ds		; Address it
	 assume  ds:DGROUP	; Tell the assembler about it

	 STROUT  U16_SET_ATTRS
	 call	 U16_SET_ATTRS	; Set 'em up

	 pop	 ds		; Restore
	 assume  ds:NGROUP	; Tell the assembler about it

; Initialize the command line

	 push	 es		; Save for a moment

	 push	 seg DGROUP	; Get our data segment
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 lea	 edi,CMD_LINE	; ES:EDI ==> commnand line
	 mov	 ecx,CMD_LINE_LEN ; ECX = Length of ...
	 mov	 al,' '         ; Fill character
     rep stos	 CMD_LINE[edi]	; Clear it to blanks

	 pop	 es		; Restore
	 assume  es:NGROUP	; Tell the assembler about it

; Set starting linear address of our dynamic data
; which is immediately following XGROUP

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,seg XGROUP	; Get segment of XGROUP
	 sub	 ax,seg DGROUP	; Less ...	 DGROUP
	 shl	 eax,4-0	; Convert from paras to bytes
	 add	 eax,offset XGROUP:XTAIL ; Plus offset of next available
				; byte in XGROUP

; Because we want to work with past versions of MAX which don't
; include support for uninitialized data, point DI to the bucket
; into which we need to accumulate our code size.

	 lea	 di,SWATINI.MD_SIZE ; Assume it's not supported

	 cmp	 SWATINI.MD_MAXVER,01h ; Izit supported?
	 jb	 short @F	; Jump if not

	 lea	 di,SWATINI.MD_USIZE ; It's supported
@@:

; อออออออออออออออออออออออออออ INITIALIZED DATA อออออออออออออออออออออออออออออออออ

; Count in size of video tables

	 mov	 FVMBASE,eax	; Save offset in DGROUP
	 movzx	 ebx,VIDEO_CNT	; Get size of tables
	 add	 SWATINI.MD_SIZE,ebx ; Add into total program size
	 add	 eax,ebx	; Skip over them

; Count in size of DVGA tables

	 movzx	 ebx,DVGA_CNT	; Get size of tables
	 add	 SWATINI.MD_SIZE,ebx ; Add into total program size
	 add	 eax,ebx	; Skip over them

; ออออออออออออออออออออออออออ UNINITIALIZED DATA ออออออออออออออออออออออออออออออออ

; Count in size of WINTAB

	 mov	 WINBASE,eax	; Save offset in DGROUP
	 mov	 ebx,PWTAIL	; Get size of table
	 add	 PGROUP:[di].EDD,ebx ; Add into uninitialized data
	 add	 eax,ebx	; Skip over it

; Initialize LCLTSSxx structures

@TSSSTK  equ	 512		; Size of TSS stack in bytes

	 mov	 cx,NLCLTSS	; Get # LCLTSSxx structures
	 xor	 ebx,ebx	; Initialize index into LCLTSSxx structures
INIT_REAL_TSS:
	 add	 eax,@TSSSTK	; Skip to end of the stack
	 mov	 LCLTSS00[ebx].PSTK_IxxZ,eax ; Save in the LCLTSSxx structure
	 add	 PGROUP:[di].EDD,@TSSSTK ; Add into uninitialized data

	 add	 ebx,size LCLTSS_STR ; Skip to next LCLTSSxx structure

	 LOOPS	 INIT_REAL_TSS	; Jump if more LCLTSSxx structures to initialize

; Count in size of table of ptrs to last screen buffers

	 mov	 PPLSTBUF_TAB,eax ; Save offset in DGROUP
	 imul	 ebx,NLSTBUF,type PLSTBUF_STR ; Get size of last scr buf table
	 add	 PGROUP:[di].EDD,ebx ; Add into uninitialized data
	 add	 eax,ebx	; Skip over it

; Count in size of last screen buffers

	 mov	 PLSTBUF_INI,eax ; Save offset in DGROUP
	 imul	 ebx,NLSTBUF,@SCRSIZE ; Get size of last screen buffers
	 add	 PGROUP:[di].EDD,ebx ; Add into uninitialized data
	 add	 eax,ebx	; Skip over it

; Count in size of current screen buffer

	 mov	 PSCRBUF,eax	; Save offset in DGROUP
	 mov	 ebx,@SCRSIZE	; Get screen size
	 add	 PGROUP:[di].EDD,ebx ; Add into uninitialized data
	 add	 eax,ebx	; Skip over it

; Count in size of ARET table

	 mov	 ARETBASE,eax	; Save offset in DGROUP
	 mov	 ebx,@ARET_CNT*size ARET_STR ; Get size of table
	 add	 PGROUP:[di].EDD,ebx ; Add into uninitialized data
	 add	 eax,ebx	; Skip over them

; If BUCKETS not specified, we calculate a default value based on
; max (min (SYMSIZE / 4096, 255), 1) and look up the corresponding
; HASHPRIME value.

	 cmp	 BUCKETS,0	; Were BUCKETS specified?
	 jne	 short INIT_REAL_BUCKETS ; Jump if so

;;;	 mov	 BUCKETS,2
;;;	 mov	 HASHPRIME,509
;;;	 jmp	 short INIT_REAL_BUCKETS

	 REGSAVE <eax,di>	; Save registers

	 mov	 eax,SYMSIZE	; Get SYMSIZE
	 shr	 eax,12 	; AX contains KBytes in SYMSIZE / 4
	 cmp	 ax,254 	; Izit above our 0-based limit?
	 jna	 short @F	; Jump if not

	 mov	 ax,254 	; Use largest possible value

@@:
	 or	 ax,ax		; Izit 0?
	 jnz	 short @F	; Jump if not

	 mov	 al,1		; 1 is minimum
@@:
	 mov	 BUCKETS,al	; Save value
	 shl	 ax,1		; Convert to word pointer
	 mov	 di,ax		; Load index register
	 mov	 ax,PRIMES[di]	; Get HASHPRIME value
	 mov	 HASHPRIME,ax	; Save for later use

	 REGREST <di,eax>	; Restore registers
INIT_REAL_BUCKETS:

; Count in size of symbol table

	 mov	 SYMBASE,eax	; Save offset in DGROUP
	 mov	 SYMNEXT,eax	; Save offset in DGROUP
	 mov	 ebx,SYMSIZE	; Get size of table
	 add	 PGROUP:[di].EDD,ebx ; Add into uninitialized data
	 add	 eax,ebx	; Skip over them
	 mov	 SYMLAST,eax	; Save offset in DGROUP of end+1

; Count in size of symbol address hash table

	 mov	 SYMHASH,eax	; Save offset in DGROUP
	 push	 cx		; Save
	 mov	 cl,ADDRHBITS	; Get number of bits to use
	 mov	 ebx,4		; DWORD size
	 shl	 ebx,cl 	; Convert to size in bytes
	 pop	 cx		; Restore
	 add	 PGROUP:[di].EDD,ebx ; Add into uninitialized data
	 add	 eax,ebx	; Skip over hash table

; Count in size of symbol names hash table

	 mov	 SYMNHASH,eax	; Save offset in DGROUP
	 movzx	 ebx,HASHPRIME	; Get number of entries
	 shl	 ebx,2-0	; Convert to dword index
	 add	 PGROUP:[di].EDD,ebx ; Add to uninitialized data
	 add	 eax,ebx	; Skip over name hash table

; Count in size of error log.  Note that the log size must be a multiple
; of 80, but the log base need not be aligned, since LOGOFF is used to
; index characters in combination with LOGBASE.

	 mov	 LOGBASE,eax	; Save offset in DGROUP
	 mov	 ebx,LOGLEN	; Get length in bytes
	 add	 PGROUP:[di].EDD,ebx ; Add to uninitialized data
	 add	 eax,ebx	; Skip over error log

; Count in size of alternate display buffer.  Screen output is sent here
; when debugging remotely in graphics mode.

	mov	ALTBASE_FVEC.FOFF,eax ; Save offset in DGROUP
	mov	ebx,@SCRSIZE	; Get length in bytes
	add	PGROUP:[di].EDD,ebx ; Add to uninitialized data
	add	eax,ebx 	; Skip over video buffer

; Count in size of last screen transmitted delta buffer.  This is used
; to compare the current screen against the last screen transmitted
; when debugging remotely.

	mov	PLASTXMSCR,eax	; Save offset in DGROUP
;;;;;;; mov	ebx,@SCRSIZE	; Get length in bytes
	add	PGROUP:[di].EDD,ebx ; Add to uninitialized data
	add	eax,ebx 	; Skip over transmit delta buffer

; Count in size of communications ring buffer.	Default size is 16K.
; This value is defined in SWAT_REM.INC, and must be a power of 2.

	mov	PRECVBUF,eax	; Save offset in DGROUP
	mov	ebx,@RECVBUF_LEN ; Get length in bytes
	add	PGROUP:[di].EDD,ebx ; Add to uninitialized data
	add	eax,ebx 	; Skip over communications ring buffer

; Count in size of local PDIR table, a temporary page
; which is used in case PHYS2LIN fails, and two video pages,
; and a page to map CR3
; and CntINSERT pages for INSERT command (assuming the size of SWAT
; isn't any larger than that)

@NPAGES equ	1+1+2+1 	; PDIR (1), temp (1), video (2), CR3 (1)

	mov	ebx,CntINSERT	; Get # INSERT pages
	add	ebx,@NPAGES	; Plus # other pages
	imul	ebx,4*1024	; Convert from 4KB to bytes
	add	ebx,4*1024-1	; Round up to next 4KB page
	mov	BLCLPDIR,eax	; Save its base address in DGROUP
	add	PGROUP:[di].EDD,ebx ; Add into uninitialized data
	add	eax,ebx 	; Skip over it

; Count in size of the local stack
; Take into account the rounding up in the size of uninitialized data

	 mov	 ebx,eax	; Copy original offset
	 add	 eax,16-1	; Round up to para boundary
	 and	 eax,not (16-1) ; ...
	 sub	 ebx,eax	; Less original offset
	 neg	 ebx		; Negate to get positive value

@LCLSTK  equ	 2048		; Size of local stack in bytes

	 add	 ebx,@LCLSTK	; Plus its size in bytes
	 add	 PGROUP:[di].EDD,ebx ; Add into uninitialized data
	 add	 eax,@LCLSTK/2	; Skip over the first half
	 mov	 INISTK_FVEC.FOFF,eax ; Save as offset for INIT_PROT stack
	 add	 eax,@LCLSTK/2	; Skip over the second half
	 mov	 LCLSTK_FVEC.FOFF,eax ; Save as offset for all other stack usage

; Count in size of WKD Load Segments

	test	WKD_FLAG,@WKD_ENABLE ; Izit enabled?
	jz	short @F	; Jump if not

	imul	ebx,WKDLS_CNT,type WKDLS_STR ; Get size in bytes
	add	PGROUP:[di].EDD,ebx ; Add into uninitialized data
	mov	PWKDLS,eax	; Save linear address
	add	eax,ebx 	; Skip over it
@@:

; Count in the size of the command history buffer

	mov	ebx,CMDHIST_LEN ; Get length of buffer
	add	ebx,16-1	; Round up to para boundary
	and	ebx,not (16-1)	; ...
	mov	CMDHIST_LEN,ebx ; Save back
	add	PGROUP:[di].EDD,ebx ; Add into uninitialized data
	mov	CMDHIST_OFF,eax ; Save linear address
	mov	CMDHIST_NXT,eax ; ...
	mov	CMDHIST_CUR,eax ; ...
	add	eax,ebx 	; Skip over it
	mov	CMDHIST_END,eax ; Save linear address

; Count in the size of INT 41h Param Error stack

	mov	ebx,@I41STK_SIZE ; Get length in bytes
	add	PGROUP:[di].EDD,ebx ; Add to uninitialized data
	add	eax,ebx 	; Skip over INT 41h stack
	mov	I41STK_FVEC.FOFF,eax ; Save offset in DGROUP of top of stack

; อออออออออออออออออออ END OF UNINITIALIZED DATA ออออออออออออออออออออออออออออออออ

; Setup NMI values based upon system type

	 test	 SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
	 jz	 short @F	; Jump if not

	 mov	 NMIPORT,0A0h	; NMI clear I/O port
	 mov	 NMIENA,80h	; ... enable value
	 mov	 NMIDIS,00h	; ... disable value
	 mov	 NMIMASK,mask $XTPAR ; ... clear mask
@@:

; Setup watchdog timer if we're on an MCA

	 test	 SWATINI.MD_ATTR,@MD_MCA ; Izit MCA-compatible?
	 jz	 short INIT_REAL_XMCA ; Jump if not

	 movzx	 bx,WATCHDOG	; Get current watchdog value
	 mov	 ax,0C300h	; Function code to disable value

	 cmp	 bl,0		; Izit disable?
	 je	 short @F	; Jump if so

	 mov	 ax,0C301h	; Function code to enable value
@@:
	 int	 15h		; Request BIOS service
INIT_REAL_XMCA:

; Copy PGROUP/DGROUP data items to XGROUP

	 mov	 ax,seg XGROUP	; Get segment of XGROUP
	 mov	 es,ax		; Address it
	 assume  es:XGROUP	; Tell the assembler about it

	 lea	 si,ARG_FLAG	; DGROUP:SI ==> ARG_FLAG
	 lea	 di,XARG_FLAG	; ES:DI ==> XGROUP copy of ...
	 mov	 cx,size ARG_FLAG ; CX = # bytes in ...
S16  rep movs	 <XARG_FLAG.LO[di],ARG_FLAG.LO[si]> ; Copy to XGROUP

	 lea	 si,SWATINI	; PGROUP:SI ==> SWATINI
	 lea	 di,XSWATINI	; ES:DI ==> XGROUP copy of ...
	 mov	 cx,size SWATINI ; CX = # bytes in ...
S16  rep movs	 <XSWATINI.LO[di],SWATINI.LO[si]> ; Copy to XGROUP

	mov	ax,seg RGROUP	; Get segment of RGROUP
	mov	ds,ax		; Address it
	assume	ds:RGROUP	; Tell the assembler about it

	 mov	 eax,OLDINT67_VEC ; Get old INT 67h handler
	 mov	 XOLDINT67_VEC,eax ; Save in XGROUP
	 mov	 ROLDINT67_VEC,eax ; ...     RGROUP

	 mov	 eax,PWTAIL	; Get offset to WTAIL
	 mov	 XPWTAIL,eax	; Save in XGROUP

	 jmp	 short INIT_REAL_EXIT ; Join common exit code

INIT_REAL_ERR:
	 or	 SWATINI.MD_ATTR,@MD_RMIE ; Indicate something went wrong
INIT_REAL_EXIT:
	 REGREST <gs,fs,es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it
	 popad			; Restore all EGP registers

	 lss	 sp,OLDSTK_VEC	; Restore original stack
	 assume  ss:nothing	; Tell the assembler about it

	 jmp	 INIT_COPY	; Join common copy code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_REAL endp			; End INIT_REAL procedure
	 NPPROC  SET_CO80 -- Mark as Color 80-column Video
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Mark as color 80-column video

|

	 REGSAVE <eax,ds>	; Save registers

	 push	 seg DGROUP	; Get our data segment
	 pop	 ds		; Address it
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 eax,CO80TYPE	; Get CO80 cursor type
	 mov	 VIDTYPE,eax	; Save as current cursor type
	 mov	 CURTYPE,ax	; Save here, too
	 mov	 VIDBASE_FVEC.FOFF,@VID_CLR ; Save as video base address
	 mov	 CRTC,@CRT_CLR	; Save as CRT controller address

	 REGREST <ds,eax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_CO80 endp			; End SET_CO80 procedure
	 NPPROC  SET_MONO -- Set Monochrome Video
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Mark as monochome video

|

	 REGSAVE <eax,ds>	; Save registers

	 push	 seg DGROUP	; Get our data segment
	 pop	 ds		; Address it
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 eax,MONOTYPE	; Get MONO cursor type
	 mov	 VIDTYPE,eax	; Save as current cursor type
	 mov	 CURTYPE,ax	; Save here, too
	 mov	 VIDBASE_FVEC.FOFF,@VID_MDA ; Save as video base address
	 mov	 CRTC,@CRT_MDA	; Save as CRT controller address

	 REGREST <ds,eax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_MONO endp			; End SET_MONO procedure
	NPPROC	CHECK_VID -- Check on Video Adapter Presence
	assume	ds:NGROUP,es:NGROUP,fs:DGROUP,gs:PGROUP,ss:nothing
COMMENT|

Check on video adapter presence.

|

	REGSAVE <eax,dx>	; Save registers

	xor	eax,eax 	; Initialize accumulator

	mov	dx,@CRT_CLR	; Address register of color/graphics 6845

	call	CHK_CREG	; Check cursor register
	jc	short @F	; It's not present

	or	eax,@LCL_CLR	; Mark as present
@@:
	mov	dx,@CRT_MDA	; Address register of monochrome 6845

	call	CHK_CREG	; Check cursor register
	jc	short @F	; It's not present

	or	eax,@LCL_MDA	; Mark as present
@@:
	cmp	eax,@LCL_MDA or @LCL_CLR ; Both present?
	jne	short @F	; Not this time

	or	eax,@LCL_BOTH	; Mark as such
@@:
	or	LCL_FLAG,eax	; Save for later use

	REGREST <dx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_VID endp			; End CHECK_VID procedure
	NPPROC	CHK_CREG -- Check Cursor Register DX For Adapter Presence
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	REGSAVE <ax,dx> 	; Save registers

	mov	al,0Fh		; Set CRTC to address cursor register
	out	dx,al		; Tell CRTC about it
	call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue
	inc	dx		; Point to data register

	in	al,dx		; Save original value
	call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue

	push	ax		; on the stack
	mov	al,5Ah		; Test value for cursor position
	out	dx,al		; Tell CRTC about it
	call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue

	in	al,dx		; Read it back in
	call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue

; Note the long scope of the following comparison

	cmp	al,5Ah		; Check against test value
	pop	ax		; Restore original cursor value

	out	dx,al		; Restore original value in CRTC
;;;;;;; call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue
	jne	short CHK_CREG_NO ; Not present

	clc			; Indicate it's present

	jmp	short CHK_CREG_EXIT ; Join common exit code

CHK_CREG_NO:
	stc			; Indicate it's not present
CHK_CREG_EXIT:
	REGREST <dx,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHK_CREG endp			; End CHK_CREG procedure
	 NPPROC  CHECK_BPI -- Check on Breakpoint Interrupt
	 assume  ds:NGROUP,es:NGROUP,fs:DGROUP,gs:PGROUP,ss:nothing
COMMENT|

See if we should generate a breakpoint interrupt

|

	 test	 DBG_FLAG,@DBG_CAPS ; Breakpoint if CapsLock on?
	 jz	 short CHECK_BPI_NOCAPS ; Not this time

	 push	 ax		; Save for a moment

	 KEYCALL @GETSHF	; Get the shift state into AL

	 test	 al,mask $CP	; CapsLock on?
	 pop	 ax		; Restore
	 jnz	 short CHECK_BPI_SIG ; Yes, signal interrupt
CHECK_BPI_NOCAPS:
	 test	 DBG_FLAG,@DBG_INT ; Generate breakpoint interrupt?
	 jz	 short @F	; Not this time

	 int	 03h		; Call the resident debugger
@@:
	 ret			; Return to caller

CHECK_BPI_SIG:
	 sub	 sp,4		; Make room for CS and FL
	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 push	 [bp+6].ELO	; Get offset
	 pop	 [bp+2].ELO	; Put offset into place

	 mov	 [bp+4],cs	; Put segment into place

	 pushf			; Put flags onto the stack
	 pop	 [bp+6].ELO	; Put flags into place

	 pop	 bp		; Restore

	 push	 seg INTVEC	; Prepare to address interrupt vectors
	 pop	 ds		; Address it
	 assume  ds:INTVEC	; Tell the assembler about it

	 pushf
	 push	 INT00_VEC.VSEG[02h*type INT00_VEC] ; Put segment onto stack
	 push	 INT00_VEC.VOFF[02h*type INT00_VEC] ;	  offset

	 push	 seg NGROUP	; Get our data segment
	 pop	 ds		; Address it
	 assume  ds:NGROUP	; Tell the assembler about it

	 iret			; Call debugger

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_BPI endp			; End CHECK_BPI procedure
	 NPPROC  CHECK_CPUID -- Check CPU Identifier
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

The test for 386 vs. 486 is done by attempting to set the Alignment Check
bit in the high-order word of the extended flag word.  If that's successful,
it's a 486; otherwise, it's a 386.

On exit:

CF	 =	 0 if it's a 386
	 =	 1 if it's a 486

|

	 push	 bx		; Save register

	 push	 bp		; Save to align stack
	 mov	 bp,sp		; Save original stack pointer

	 and	 sp,not (4-1)	; Align on a dword boundary in case we're
				; in V86 mode and $AM is set in CR0

	 push	 eax		; Save to use as scratch
	 pushfd 		; Save original flags

	 pushfd 		; Save original flags
	 mov	 bx,sp		; Address via index register
	 or	 ss:[bx].EHI,mask $AC ; Set Alignment Check bit
	 popfd			; Put into effect

	 pushfd 		; Put onto the stack
	 pop	 eax		; Copy to register

	 test	 eax,(mask $AC) shl 16 ; Izit still set?
	 jnz	 short @F	; Yes, so it's a 486

	 popfd			; Restore original flags

	 clc			; Indicate it's a 386

	 jmp	 short CHECK_CPUID_EXIT ; Join common code

@@:
	 popfd			; Restore original flags

	 stc			; Indicate it's a 486
CHECK_CPUID_EXIT:
	 pop	 eax		; Restore

	 mov	 sp,bp		; Restore original pointer
	 pop	 bp		; Restore

	 pop	 bx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CPUID endp		; End CHECK_CPUID procedure
	 NPPROC  IZIT_CPUID -- Determine Support of CPUID Instruction
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

The test for the CPUID instruction is done by attempting to set the ID
bit in the high-order word of the extended flag dword.	If that's
successful, the CPUID instruction is supported; otherwise, it's not.

On exit:

CF	 =	 1 if it's supported
	 =	 0 otherwise

|

	 push	 bp		; Save to address the stack
	 clc			; Assume it's not supported
	 pushfd 		; Save original flags
	 pushfd 		; Save temporary flags

IZIT_CPUID_STR struc

IZIT_CPUID_TMPEFL dd ?		; Temporary EFL
IZIT_CPUID_RETEFL dd ?		; Return EFL
	 dw	 ?		; Caller's BP

IZIT_CPUID_STR ends

	 mov	 bp,sp		; Address the stack
	 or	 [bp].IZIT_CPUID_TMPEFL,mask $ID ; Set ID bit
	 popfd			; Put into effect

	 pushfd 		; Put back onto the stack to test

	 test	 [bp].IZIT_CPUID_TMPEFL,mask $ID ; Izit still set?
	 jz	 short @F	; No, so it's not supported

	 or	 [bp].IZIT_CPUID_RETEFL,mask $CF ; Indicate it's supported
@@:
	 popfd			; Restore temporary flags
	 popfd			; Restore original flags
	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_CPUID endp 		; End IZIT_CPUID procedure
	NPPROC	CHECK_P5 -- Check On CPU Features
	assume	ds:nothing,es:nothing,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Get CPU feature bits (especially VME and IOBRK).

On exit:

CPUFET		 Laundered feature bits from CPUID instruction

|

	call	IZIT_CPUID	; Duzit support the CPUID instruction?
	jnc	short CHECK_P5_EXIT ; Jump if not

	REGSAVE <eax,ebx,ecx,edx> ; Save for a moment

	mov	eax,1		; Function code to retrieve feature bits
	CPUID			; Return with EAX = stepping info
				;	      EBX, ECX reserved
				;	      EDX = feature bits

	mov	CPUSIG,eax	; Save signature info for later use
	and	eax,@CPUSIG_FAM ; Isolate the family #
	shr	eax,$CPUSIG_FAM ; Shift to low-order
	mov	CPUFAM,al	; Save for later use

	cmp	CPUFAM,06h	; Izit a P6?
	jne	short @F	; Jump if not

	or	LC4_FLAG,@LC4_LBR or @LC4_LBRWIN ; Enable Last Branch/Exception
				; reporting and window display
@@:

;*********************** INTEL CONFIDENTIAL **************************
; Check for A1 step SL Enhanced 486 CPUs with feature bits.  Note that
; the stepping information in the following comments is under Intel NDA.

	test	edx,@CPUFET_VME ; Any Virtual Mode Extensions supported?
	jz	short CHECK_P5_VMEOK ; Jump if not

; The A1 step says it supports VME, but has some serious bugs which may
; cause misdirection of some interrupts.  Later steppings also have this
; bug, but correctly say they don't support VME.

	mov	ebx,eax 	; Copy stepping info
	and	ebx,@CPUSIG_FAM or @CPUSIG_MOD or @CPUSIG_REV ; Isolate family,
				; model, and stepping in BX
	cmp	bx,0414h	; Izit S series 486DX, A1 step?
	je	short @F	; Jump if so

	cmp	bx,0424h	; Izit S series 486SX, A1 step?
	je	short @F	; Jump if so

	cmp	bx,0434h	; Izit S series 486DX-2, A1 step?
	jne	short CHECK_P5_VMEOK ; Jump if not
@@:
	and	edx,not @CPUFET_VME ; Don't enable Virtual Mode Extensions
CHECK_P5_VMEOK:
;************************ END INTEL CONFIDENTIAL **********************

	mov	CPUFET_FLAG,edx ; Save feature bits for later use

	REGREST <edx,ecx,ebx,eax> ; Restore
CHECK_P5_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_P5 endp			; End CHECK_P5 procedure
	NPPROC	CHECK_NDP -- Check for Presence of NDP
	assume	ds:NGROUP,es:NGROUP,fs:DGROUP,gs:PGROUP,ss:nothing
COMMENT|

Test for a Numeric Data Processor -- Intel 8087, 80287, or 80387.

|

	REGSAVE <eax>		; Save registers

	int	11h		; Get equipment flags into eAX

	test	ax,mask $I11_NDP ; Check NDP-installed bit
	jz	short @F	; Jump if not installed

	or	LC2_FLAG,@LC2_NDP ; Mark as installed
@@:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_NDP endp			; End CHECK_NDP procedure

NCODE	ends			; End NCODE segment

	MEND			; End SWAT_INI module
