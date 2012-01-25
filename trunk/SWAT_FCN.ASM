;' $Header:   P:/PVCS/386SWAT/SWAT_FCN.ASV   1.47   10 Aug 1998 11:01:02   BOB  $
	 title	 SWAT_FCN -- 386SWAT Argument Function Routines
	 page	 58,122
	 name	 SWAT_FCN

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.

|
.386
.xlist
	 include MASM.INC
	 include 386.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include PTR.INC
	 include DIR.INC
	 include XMS.INC
	 include BIOSDATA.INC

	 include SWAT_DRV.INC
	 include SWAT_SEG.INC
	 include SWAT_VID.INC
	 include SWAT_SYM.INC
	 include SWAT_SSF.INC
	 include SWAT_SER.INC
.list

PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  ds:PGROUP

	 extrn	 DEVLOAD:byte

PROG	 ends			; End PROG segment


DATA16	 segment use32 dword public 'data' ; Start DATA16 segment
	 assume  ds:DGROUP

	public	@SWAT_FCN_DATA16
@SWAT_FCN_DATA16 label byte	; Mark module start in .MAP file

	 extrn	 ARG_FLAG:word
	 include SWAT_ARG.INC

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

	extrn	WKD_FLAG:word
	include SWAT_WKD.INC

	 extrn	 PS4IO:word
	 extrn	 SYMSIZE:dword
	 extrn	 ADDRHBITS:byte
	 extrn	 ADDRMASK:dword
	 extrn	 BUCKETS:byte
	 extrn	 HASHPRIME:word
	 extrn	 WATCHDOG:byte

	 extrn	 PROXSRCH:word

	 extrn	 VMSINT_TAB:byte
	 extrn	 VMSINT_LEN:byte

	 extrn	 NLSTBUF:dword

	 extrn	 EXTSYM_OFF:dword
	 extrn	 EXTSYM_LEN:dword
	 extrn	 EXTSYM_CHKSUM:dword
	 extrn	 EXTSYM_COUNT:dword

	 extrn	 SYMAPPND_MODE:byte
	 extrn	 SYM_READBUF:byte

	 extrn	 FBROWS_PATH:byte
	 extrn	 @FBROWS_PMAX:abs

	 extrn	 VMSCOUNT:word

	 extrn	 COMPORT:word
	 extrn	 PORTBAUD:dword
	 extrn	 PORTDLATCH:word
	 extrn	 PORTBASE:word
	 extrn	 PORTIRQ:byte
	 extrn	 PORTINIT:byte
	 extrn	 @PORTINIT_LEN:abs

	 extrn	 LOGLEN:dword

	 extrn	 PASSTHROUGH1:byte
	 extrn	 PASSTHROUGH2:byte

	extrn	SYMFILTER_NXT:dword
	extrn	SYMFILTER_END:dword
	extrn	SYMFILTER_TAB:byte

	extrn	WKDLS_CNT:dword
	extrn	CMDHIST_LEN:dword
	extrn	@CMDHIST_MIN:abs

	 public  DBG_FLAG
	 include SWAT_DBG.INC
DBG_FLAG dw	 0		; Debugging flags (defined in SWAT_DBG.INC)

	 public  GPS_FLAG
	 include SWAT_GPS.INC
GPS_FLAG dw	 0		; GP Skip flags

DATA16	 ends			; End DATA16 segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:NGROUP

	public	@SWAT_FCN_NDATA
@SWAT_FCN_NDATA label byte	; Mark module start in .MAP file

	 extrn	 OLDINT24_VEC:dword
	 extrn	 MSG_OVF:byte
	 extrn	 MSG_UNK:byte
	 extrn	 MSG_UNKLST:byte
	 extrn	 MSG_SEP:byte
	 extrn	 LASTKEY:word
	 extrn	 MAPSEG_NXT:word
	 extrn	 XMSDRV_VEC:dword

	 extrn	 MEMERR_DVGA:byte
	 extrn	 MEMERR_PRO:byte
	 extrn	 MEMERR_VIDEO:byte

	extrn	MSG_NOWINK:byte

	 public  SYM_XMSHNDL
SYM_XMSHNDL dw	 0		; XMS handle for symbols with VCPI (0=none)

	 public  NRD_FLAG
NRD_FLAG dw	 0		; Non-resident flags
@NRD_PRO   equ	 8000h		; PRO= being processed

	 public  PROF_CNT,PROF_SEG
PROF_CNT dw	 ?		; # bytes in the profile
PROF_SEG dw	 ?		; Segment of the profile

	 public  VIDEO_CNT,VIDEO_SEG
VIDEO_CNT dw	 ?		; # bytes in the video tables
VIDEO_SEG dw	 ?		; Segment of the video tables

	 public  DVGA_CNT,DVGA_SEG
DVGA_CNT dw	 ?		; # bytes in the DVGA tables
DVGA_SEG dw	 ?		; Segment of the DVGA tables

	 public  MSG_POPEN,MSG_PREAD,MSG_VOPEN,MSG_VREAD,MSG_VWRIT
MSG_POPEN label  byte
MSG_PREAD db	 BEL,'様> Unable to access profile.',CR,LF,EOS
MSG_VOPEN label  byte
MSG_VREAD db	 BEL,'様> Unable to access video table file.',CR,LF,EOS
MSG_VWRIT db	 BEL,'様> Unable to write video table file.',CR,LF,EOS

	 public  MSG_SYMOPEN,MSG_SYMFMT,MSG_SYMEXT,MSG_SYMSW,MSG_COM,MSG_BADBASE
	 public  MSG_SYMXMS,MSG_SYMVDS,MSG_SYMXMSMOV
MSG_SYMOPEN db	 BEL,'様> Unable to open symbol table.',CR,LF,EOS
MSG_SYMFMT db	 BEL,'様> File is not a symbol table (SSF format).',CR,LF,EOS
MSG_SYMEXT db	 BEL,'様> Insufficient extended memory for symbols.',CR,LF,EOS
MSG_SYMSW  db	 BEL,'様> Invalid switch.',CR,LF,EOS
MSG_COM  db	 BEL,'様> Invalid communications parameters.',CR,LF,EOS
MSG_BADBASE db	 BEL,'様> Default port base invalid.',CR,LF,EOS
MSG_SYMXMS db	 BEL,'様> LOADSYM with VCPI requires XMS memory.',CR,LF,EOS
MSG_SYMVDS db	 BEL,'様> LOADSYM unable to lock VDS memory.',CR,LF,EOS
MSG_SYMXMSMOV db BEL,'様> LOADSYM unable to move XMS memory.',CR,LF,EOS

	 public  MSG_BADHINT
MSG_BADHINT db	 BEL,'様> Specified interrupt is not a valid hardware interrupt.',CR,LF,EOS

; Prime numbers close to multiples of 256 for translating BUCKETS
; parameter into hash lengths.
	 public  PRIMES
	 even
PRIMES	dw	   257,  509,  769, 1021, 1279, 1531	; Buckets 1..6
	dw	  1789, 2053, 2309, 2557, 2819, 3067	; Buckets 7..12
	dw	  3329, 3583, 3833, 4093, 4349, 4603	; Buckets 13..18
	dw	  4861, 5119, 5381, 5639, 5881, 6143	; Buckets 19..24
	dw	  6397, 6653, 6911, 7159, 7417, 7681	; Buckets 25..30
	dw	  7937, 8191, 8447, 8707, 8963, 9221	; Buckets 31..36
	dw	  9473, 9733, 9973,10243,10499,10753	; Buckets 37..42
	dw	 11003,11261,11519,11777,12037,12289	; Buckets 43..48
	dw	 12541,12799,13049,13313,13567,13829	; Buckets 49..54
	dw	 14081,14341,14591,14851,15101,15359	; Buckets 55..60
	dw	 15619,15877,16127,16381,16633,16901	; Buckets 61..66
	dw	 17159,17401,17659,17921,18181,18433	; Buckets 67..72
	dw	 18691,18947,19207,19457,19709,19963	; Buckets 73..78
	dw	 20219,20479,20731,20983,21247,21503	; Buckets 79..84
	dw	 21757,22013,22271,22531,22783,23039	; Buckets 85..90
	dw	 23297,23549,23813,24061,24317,24571	; Buckets 91..96
	dw	 24841,25087,25343,25601,25849,26111	; Buckets 97..102
	dw	 26371,26627,26879,27143,27397,27647	; Buckets 103..108
	dw	 27901,28163,28411,28669,28927,29179	; Buckets 109..114
	dw	 29437,29683,29947,30211,30467,30713	; Buckets 115..120
	dw	 30977,31231,31489,31741,32003,32257	; Buckets 121..126
	dw	 32507,32771,33023,33287,33533,33791	; Buckets 127..132
	dw	 34039,34303,34549,34819,35069,35327	; Buckets 133..138
	dw	 35591,35839,36097,36353,36607,36857	; Buckets 139..144
	dw	 37117,37379,37633,37889,38149,38393	; Buckets 145..150
	dw	 38653,38917,39163,39419,39679,39937	; Buckets 151..156
	dw	 40193,40459,40699,40961,41213,41467	; Buckets 157..162
	dw	 41729,41983,42239,42499,42751,43003	; Buckets 163..168
	dw	 43261,43517,43777,44029,44293,44543	; Buckets 169..174
	dw	 44797,45053,45307,45569,45823,46073	; Buckets 175..180
	dw	 46337,46591,46853,47111,47363,47609	; Buckets 181..186
	dw	 47869,48131,48383,48647,48889,49157	; Buckets 187..192
	dw	 49409,49663,49919,50177,50423,50683	; Buckets 193..198
	dw	 50951,51199,51461,51713,51971,52223	; Buckets 199..204
	dw	 52489,52733,52999,53239,53503,53759	; Buckets 205..210
	dw	 54013,54269,54521,54787,55049,55291	; Buckets 211..216
	dw	 55547,55807,56053,56311,56569,56827	; Buckets 217..222
	dw	 57089,57347,57601,57853,58111,58367	; Buckets 223..228
	dw	 58631,58889,59141,59393,59651,59887	; Buckets 229..234
	dw	 60161,60413,60679,60923,61169,61441	; Buckets 235..240
	dw	 61703,61949,62207,62467,62723,62971	; Buckets 241..246
	dw	 63241,63487,63743,63997,64271,64513	; Buckets 247..252
	dw	 64763,65027,65287			; Buckets 253..255

GPSKIP_STR struc

GPSKIP_OFF dw	 ?		; Offset of keyword
GPSKIP_LEN dw	 ?		; Length ...
GPSKIP_FLG dw	 ?		; Flag bits ...

GPSKIP_STR ends


	 public  GPSKIPTAB
GPSKIPTAB label  tbyte
	 GPSKIP_STR <NGROUP:GPSKIP@ALL, GPSKIP@ALL_LEN, -1>
	 GPSKIP_STR <NGROUP:GPSKIP@INT, GPSKIP@INT_LEN, @GPSKIP_INT>
	 GPSKIP_STR <NGROUP:GPSKIP@HLT, GPSKIP@HLT_LEN, @GPSKIP_HLT>
	 GPSKIP_STR <NGROUP:GPSKIP@OUTD,GPSKIP@OUTD_LEN,@GPSKIP_OUTD>
	 GPSKIP_STR <NGROUP:GPSKIP@OUTI,GPSKIP@OUTI_LEN,@GPSKIP_OUTI>
	 GPSKIP_STR <NGROUP:GPSKIP@IND, GPSKIP@IND_LEN, @GPSKIP_IND>
	 GPSKIP_STR <NGROUP:GPSKIP@INI, GPSKIP@INI_LEN, @GPSKIP_INI>
	 GPSKIP_STR <NGROUP:GPSKIP@CLI, GPSKIP@CLI_LEN, @GPSKIP_CLI>
	 GPSKIP_STR <NGROUP:GPSKIP@STI, GPSKIP@STI_LEN, @GPSKIP_STI>
	 GPSKIP_STR <NGROUP:GPSKIP@IRET,GPSKIP@IRET_LEN,@GPSKIP_IRET>
	 GPSKIP_STR <NGROUP:GPSKIP@PPF, GPSKIP@PPF_LEN, @GPSKIP_PPF>
	 GPSKIP_STR <NGROUP:GPSKIP@CRn, GPSKIP@CRn_LEN, @GPSKIP_CRn>
GPSKIPTAB_LEN equ ($-GPSKIPTAB)/(type GPSKIP_STR) ; # entries in table

	 public  GPSKIP@ALL, GPSKIP@INT, GPSKIP@HLT
	 public  GPSKIP@OUTD,GPSKIP@OUTI
	 public  GPSKIP@IND, GPSKIP@INI
	 public  GPSKIP@CLI, GPSKIP@STI
	 public  GPSKIP@IRET,GPSKIP@PPF
	 public  GPSKIP@CRn
GPSKIP@ALL db	 'ALL'          ; Keyword
GPSKIP@ALL_LEN equ $-GPSKIP@ALL ; Length of ...

GPSKIP@INT db	 'INT'          ; Keyword
GPSKIP@INT_LEN equ $-GPSKIP@INT ; Length of ...

GPSKIP@HLT db	 'HLT'          ; Keyword
GPSKIP@HLT_LEN equ $-GPSKIP@HLT ; Length of ...

GPSKIP@OUTD db	 'OUTD'         ; Keyword
GPSKIP@OUTD_LEN equ $-GPSKIP@OUTD ; Length of ...

GPSKIP@OUTI db	 'OUTI'         ; Keyword
GPSKIP@OUTI_LEN equ $-GPSKIP@OUTI ; Length of ...

GPSKIP@IND db	 'IND'          ; Keyword
GPSKIP@IND_LEN equ $-GPSKIP@IND ; Length of ...

GPSKIP@INI db	 'INI'          ; Keyword
GPSKIP@INI_LEN equ $-GPSKIP@INI ; Length of ...

GPSKIP@CLI db	 'CLI'          ; Keyword
GPSKIP@CLI_LEN equ $-GPSKIP@CLI ; Length of ...

GPSKIP@STI db	 'STI'          ; Keyword
GPSKIP@STI_LEN equ $-GPSKIP@STI ; Length of ...

GPSKIP@IRET db	 'IRET'         ; Keyword
GPSKIP@IRET_LEN equ $-GPSKIP@IRET ; Length of ...

GPSKIP@PPF db	 'PPF'          ; Keyword
GPSKIP@PPF_LEN equ $-GPSKIP@PPF ; Length of ...

GPSKIP@CRn db	 'CRN'          ; Keyword
GPSKIP@CRn_LEN equ $-GPSKIP@CRn ; Length of ...

NDATA	 ends			; End NDATA segment


KEYBTAB_STR struc

KEYBTAB_TAB dw	 ?		; Offset in NGROUP of KEY_TAB_xxx
KEYBTAB_TOG dw	 ?		; ...		      KEY_TOG_xxx

KEYBTAB_STR ends


KEYBTAB_MAC macro TXT,ACT
	 local	 L1,L2

NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:NGROUP

L1	 db	 TXT		; Keyb country name
L2	 equ	 $-L1		; Length of ...

NDATA	 ends			; End NDATA segment


ASEGTAB  segment use16 word public 'ndata' ; Start ASEGTAB segment
	 assume  ds:NGROUP

	 extrn	 KEY_TAB_&ACT:word

	 dw	 offset NGROUP:L1 ; Ptr to text

ASEGTAB  ends			; End ASEGTAB segment


ASEGTOG  segment use16 byte public 'ndata' ; Start ASEGTOG segment
	 assume  ds:NGROUP

	 extrn	 KEY_TOG_&ACT:byte

ASEGTOG  ends			; End ASEGTOG segment


ASEGACT  segment use16 word public 'ndata' ; Start ASEGACT segment
	 assume  ds:NGROUP

	 KEYBTAB_STR <offset NGROUP:KEY_TAB_&ACT, offset NGROUP:KEY_TOG_&ACT>

ASEGACT  ends			; End ASEGACT segment


ASEGLEN  segment use16 word public 'ndata' ; Start ASEGLEN segment
	 assume  ds:NGROUP

	 dw	 L2		; Length of keyb text

ASEGLEN  ends			; End ASEGLEN segment

	 endm			; KEYBTAB_MAC


KSEGTAB  segment use32 word public 'data' ; Start KSEGTAB segment
	 assume  ds:DGROUP

	 extrn	 KEY_TABLEN:abs
	 extrn	 KEY_TAB:tbyte
	 extrn	 @KEY_TAB_SIZ:abs

KSEGTAB  ends			; End KSEGTAB segment


KSEGTOG  segment use32 byte public 'data' ; Start KSEGTOG segment
	 assume  ds:DGROUP

	 extrn	 KEY_TOG:byte

KSEGTOG  ends			; End KSEGTOG segment


ASEGTAB  segment use16 word public 'ndata' ; Start ASEGTAB segment
	 assume  ds:NGROUP

	public	@SWAT_FCN_ASEGTAB
@SWAT_FCN_ASEGTAB label byte	; Mark module start in .MAP file

	 public  KEYBTAB_PTR
KEYBTAB_PTR label word

ASEGTAB  ends			; End ASEGTAB segment


ASEGACT  segment use16 word public 'ndata' ; Start ASEGACT segment
	 assume  ds:NGROUP

	public	@SWAT_FCN_ASEGACT
@SWAT_FCN_ASEGACT label byte	; Mark module start in .MAP file

	 public  KEYBTAB_ACT
KEYBTAB_ACT label word

ASEGACT  ends			; End ASEGACT segment


ASEGLEN  segment use16 word public 'ndata' ; Start ASEGLEN segment
	 assume  ds:NGROUP

	public	@SWAT_FCN_ASEGLEN
@SWAT_FCN_ASEGLEN label byte	; Mark module start in .MAP file

	 public  KEYBTAB_LEN
KEYBTAB_LEN label word

ASEGLEN  ends			; End ASEGLEN segment


	 public  KEYBTAB
KEYBTAB  label	 tbyte
;;;;;;;; KEYBTAB_MAC 'BE120',   BE120
;;;;;;;; KEYBTAB_MAC 'CF058',   CF058
;;;;;;;; KEYBTAB_MAC 'DK159',   DK159
;;;;;;;; KEYBTAB_MAC 'SU153',   SU153
;;;;;;;; KEYBTAB_MAC 'FR120',   FR120
;;;;;;;; KEYBTAB_MAC 'FR189',   FR189
	 KEYBTAB_MAC 'GR129',   GR129
;;;;;;;; KEYBTAB_MAC 'IT142',   IT142
;;;;;;;; KEYBTAB_MAC 'LA171',   LA171
;;;;;;;; KEYBTAB_MAC 'NL143',   NL143
;;;;;;;; KEYBTAB_MAC 'NO155',   NO155
;;;;;;;; KEYBTAB_MAC 'PO163',   PO163
	 KEYBTAB_MAC 'SP172',   SP172
;;;;;;;; KEYBTAB_MAC 'SF150',   SF150
;;;;;;;; KEYBTAB_MAC 'SG150',   SG150
;;;;;;;; KEYBTAB_MAC 'UK166',   UK166
;;;;;;;; KEYBTAB_MAC 'US   ',   US
;;;;;;;; KEYBTAB_MAC 'YU234',   YU234
;;;;;;;; KEYBTAB_MAC 'IS197',   IS197
;;;;;;;; KEYBTAB_MAC 'TR179',   TR179


ASEGACT  segment use16 word public 'ndata' ; Start ASEGACT segment
	 assume  ds:NGROUP

	 public  KEYBTAB_CNT
KEYBTAB_CNT equ ($-KEYBTAB_ACT)/(type KEYBTAB_ACT) ; # entries

ASEGACT  ends			; End ASEGACT segment


RCODE	 segment use16 para public 'rcode' ; Start RCODE segment
	 assume  ds:RGROUP

	 extrn	 DEV_FLAG:word
	 extrn	 TRP_FLAG:dword

RCODE	 ends			; End RCODE segment


NCODE	 segment use16 para public 'ncode' ; Start NCODE segment
	 assume  cs:NGROUP

	public	@SWAT_FCN_NCODE
@SWAT_FCN_NCODE:		; Mark module start in .MAP file

	 extrn	 SKIP_WHITE:near
	 extrn	 PROC_PROFILE:near
	 extrn	 DISP_MSG:near
	 extrn	 DISP_UNK:near
	 extrn	 INST24:near
	 extrn	 REST24:near
	 extrn	 FINDVID:near
	 extrn	 DVGA_INIT:near

	 extrn	 U16_HEX2DD:near
	 extrn	 U16_BASE2BIN:near
	 extrn	 U16_PATH_COM:near
	 extrn	 ALLOC_XMS:near
	 extrn	 CHECK_NXTSEG:near

	 NPPROC  FCN_ADDRHBITS -- ADDRHBITS Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

ADDRHBITS function - user specifies a number of bits from 8 to 12 for
the address hashing table.  This translates from 1K to 16K bytes.
16K is the default.

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 REGSAVE <eax,ecx,edi>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_ADDRHBITS_EQ ; Too bad

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 mov	 ecx,10 	; Use base 10 to convert
	 call	 U16_BASE2BIN	; Convert the number at DS:ESI to binary in EAX
	 jc	 short FCN_ADDRHBITS_OVF ; Jump if too large

	 cmp	 eax,@ADDRHBITSMAX ; Ensure not too large
	 ja	 short FCN_ADDRHBITS_OVF ; Jump if too large

	 cmp	 ax,@ADDRHBITSMIN ; Izit too small?
	 jb	 short @F	; Jump if so (ignore it)

	 movzx	 cx,al		; Clear high byte
	 xchg	 cl,ADDRHBITS	; Save for later use (and get default of 12)
	 sub	 cx,ax		; CX contains difference in bits

	 shr	 ADDRMASK,cl	; Adjust hash mask
@@:
	 clc			; Indicate all went well

	 jmp	 short FCN_ADDRHBITS_EXIT ; Join common exit code

FCN_ADDRHBITS_OVF:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 lea	 di,MSG_OVF	; Pass address of error message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 jmp	 short FCN_ADDRHBITS_ERR ; Join common error code

FCN_ADDRHBITS_EQ:
	 push	 offset cs:MSG_SEP ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we allow no mistakes
FCN_ADDRHBITS_ERR:
	 stc			; Indicate there was a problem
FCN_ADDRHBITS_EXIT:
	 REGREST <edi,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_ADDRHBITS endp		; End FCN_ADDRHBITS procedure
	 NPPROC  FCN_ALTSCR -- ALTSCR Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

ALTSCR function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 test	 LCL_FLAG,@LCL_BOTH ; Both adapters present?
	 jz	 short @F	; No, so ignore this argument

	 test	 ARG_FLAG,@ARG_DVGA ; Izit present?
	 jnz	 short @F	; Yes, so ignore this argument

	 or	 ARG_FLAG,@ARG_ALTSCR ; Mark as using alternate screen
@@:
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_ALTSCR endp 		; End FCN_ALTSCR procedure
	 NPPROC  FCN_BUCKETS -- BUCKETS Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

BUCKETS function - user specifies a number of bucket blocks from
1 to 255, which we translate into a prime number for the hash table
divisor.  Values over 255 are truncated, under 1 ignored.

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 REGSAVE <eax,ecx,edi>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_BUCKETS_EQ ; Too bad

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 mov	 ecx,10 	; Use base 10 to convert
	 call	 U16_BASE2BIN	; Convert the number at DS:ESI to binary in EAX
	 jc	 short FCN_BUCKETS_OVF ; Jump if too large

	 cmp	 eax,255	; Ensure not too large
	 ja	 short FCN_BUCKETS_OVF ; Jump if too large

	 and	 ax,ax		; Izit zero (invalid)?
	 jz	 short @F	; Jump if so (ignore it)

	 mov	 BUCKETS,al	; Save for later use
	 dec	 ax		; Make it 0-based.  Note that our ceiling of
				; 255 means there are only 255 values from
				; 1-255, not 256 from 0-255.  This limit is
				; imposed by the maximum divisor to obtain
				; a 16-bit hash value.
	 shl	 ax,1		; Index word table
	 mov	 di,ax		; Load index register
	 mov	 ax,PRIMES[di]	; Get prime number for specified buckets
	 mov	 HASHPRIME,ax	; Save for later use
@@:
	 clc			; Indicate all went well

	 jmp	 short FCN_BUCKETS_EXIT ; Join common exit code

FCN_BUCKETS_OVF:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 lea	 di,MSG_OVF	; Pass address of error message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 jmp	 short FCN_BUCKETS_ERR ; Join common error code

FCN_BUCKETS_EQ:
	 push	 offset cs:MSG_SEP ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we allow no mistakes
FCN_BUCKETS_ERR:
	 stc			; Indicate there was a problem
FCN_BUCKETS_EXIT:
	 REGREST <edi,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_BUCKETS endp		; End FCN_BUCKETS procedure
	NPPROC	FCN_CMDHIST -- CMDHIST Function
	assume	ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

CMDHIST function -- set size of command history buffer

On entry:

DS:ESI	==>	command line following keyword

On exit:

DS:ESI	==>	next character to scan

|

	REGSAVE <eax,ecx>	; Save registers

	call	SKIP_WHITE	; Skip over more white space

	cmp	al,'='          ; Must be
	jne	short FCN_CMDHIST_EQ ; Too bad

	inc	si		; Skip over the character

	call	SKIP_WHITE	; Skip over more white space

	mov	ecx,10		; Use base 10 to convert
	call	U16_BASE2BIN	; Convert the number at DS:ESI to binary in EAX
	jc	short FCN_CMDHIST_OVF ; Jump if too large

	cmp	eax,@CMDHIST_MIN ; Ensure not too small
	jae	short @F	; Jump if OK

	mov	eax,@CMDHIST_MIN ; Use minimum
@@:
	mov	CMDHIST_LEN,eax ; Save for later use

	clc			; Indicate all went well

	jmp	short FCN_CMDHIST_EXIT ; Join common exit code

FCN_CMDHIST_OVF:
	mov	si,LASTKEY	; Get offset of last keyword
	lea	di,MSG_OVF	; Pass address of error message
	call	DISP_UNK	; Display it along with unknown keyword at DS:SI

	jmp	short FCN_CMDHIST_ERR ; Join common error code

FCN_CMDHIST_EQ:
	push	offset cs:MSG_SEP ; Pass address of error message
	call	DISP_MSG	; Tell 'em we allow no mistakes
FCN_CMDHIST_ERR:
	stc			; Indicate there was a problem
FCN_CMDHIST_EXIT:
	REGREST <ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_CMDHIST endp		; End FCN_CMDHIST procedure
	 NPPROC  FCN_COLDBOOT -- COLDBOOT Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

COLDBOOT

When SWAT reboots the system via Ctrl-Alt-Del, this option tells us to
blast 3412h instead of 1234h into the warm boot flag location to force
a cold boot.

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 call	 SKIP_WHITE	; Skip over more white space

	 or	 LC2_FLAG,@LC2_COLDBOOT ; Mark as cold booting

	 clc			; Mark as successful

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_COLDBOOT endp		; End FCN_COLDBOOT procedure
	 NPPROC  FCN_DBGCAPS -- DEBUG=CAPS Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

DEBUG=CAPS function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 DBG_FLAG,@DBG_CAPS ; Mark as signalling INT 02h
				; during initialization if CapsLock pressed

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGCAPS endp		; End FCN_DBGCAPS procedure
	 NPPROC  FCN_DBGINT -- DEBUG=INT Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

DEBUG=INT function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 DBG_FLAG,@DBG_INT ; Mark as signalling INT 03h during initialization

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGINT endp 		; End FCN_DBGINT procedure
	 NPPROC  FCN_DBGIBV -- DEBUG=IBV Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

DEBUG=IBV function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 DBG_FLAG,@DBG_IBV ; Mark as setting Ctrl-Alt-PAD5 IRQ1
				; to IBV value

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGIBV endp 		; End FCN_DBGIBV procedure
	 NPPROC  FCN_DBGPMI -- DEBUG=PMI Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

DEBUG=PMI function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 DBG_FLAG,@DBG_PMI ; Trigger Int 03 at INIT_PROT

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGPMI endp 		; End FCN_DBGPMI procedure
	NPPROC	FCN_DBGTRIP -- DEBUG=TRIP Function
	assume	ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

DEBUG=TRIP function

On entry:

DS:ESI	==>	command line following keyword

On exit:

DS:ESI	==>	next character to scan

|

	or	DBG_FLAG,@DBG_TRIP ; Reboot using triple fault method

	clc			; Indicate all went well

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGTRIP endp		; End FCN_DBGTRIP procedure
	 NPPROC  FCN_DBGVMI -- DEBUG=VMI Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

DEBUG=VMI function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 DBG_FLAG,@DBG_VMI ; Trigger Int 03 at INIT_VIRT

	 or	 ARG_FLAG,@ARG_DBGVMI ; Save flag where we can get it
				; at INIT_VIRT time

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGVMI endp 		; End FCN_DBGVMI procedure
	 NPPROC  FCN_DVGA -- DVGA Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

DVGA function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 push	 ax		; Save for a moment

	 mov	 ax,MAPSEG_NXT	; Get next available segment
	 mov	 DVGA_SEG,ax	; Save for later use

	 call	 DVGA_INIT	; Intialize DVGA adapter
	 jc	 short FCN_DVGA_EXIT ; Jump if not found

	 mov	 ax,DVGA_CNT	; Get DVGA table byte count
	 add	 ax,16-1	; Round up to para boundary
	 shr	 ax,4-0 	; Convert from bytes to paras
	 add	 MAPSEG_NXT,ax	; Skip over it

	 push	 offset NGROUP:MEMERR_DVGA ; Pass offset of error message
	 call	 CHECK_NXTSEG	; Ensure we've enough room

	 or	 ARG_FLAG,@ARG_DVGA ; Mark as present
	 call	 FCN_NOSWAP	; Mark as screen restore disabled

; We no longer have both adapters present

	 and	 LCL_FLAG,not (@LCL_BOTH or @LCL_MDA or @LCL_CLR) ;
	 or	 LCL_FLAG,@LCL_CLR ; Just a color adapter
	 and	 ARG_FLAG,not @ARG_ALTSCR ; No longer have alternate screen
FCN_DVGA_EXIT:
	 pop	 ax		; Restore

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DVGA endp			; End FCN_DVGA procedure
	 NPPROC  FCN_GPSKIP -- GPSKIP Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

GPSKIP function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 REGSAVE <ax,bx,cx,di>	; Save registers

; Parse the text following the command to pick off instructions
; which our GP Fault handler should skip (pass on to the next handler
; in sequence).

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_GPSKIP_EQ ; Too bad

	 inc	 si		; Skip over the separator
FCN_GPSKIP_START:
	 call	 SKIP_WHITE	; Skip over more white space

	 mov	 cx,GPSKIPTAB_LEN ; Get # keywords we support
	 xor	 bx,bx		; Initialize index into GPSKIP_TAB
FCN_GPSKIP_NEXT:
	 REGSAVE <cx,si>	; Save for a moment

	 mov	 di,GPSKIPTAB.GPSKIP_OFF[bx] ; Get offset of keyword text in NGROUP
	 mov	 cx,GPSKIPTAB.GPSKIP_LEN[bx] ; Get # bytes in ...
    repe cmps	 ds:[si].LO,GPSKIPTAB.LO[di] ; Compare 'em

	 mov	 al,ds:[si]	; Get next byte after input string

	 REGREST <si,cx>	; Restore
	 jne	 short FCN_GPSKIP_LOOP ; Jump if no match

	 cmp	 al,','         ; Izit valid separator?
	 je	 short FCN_GPSKIP_MATCH ; Jump if so

	 cmp	 al,';'         ; Izit valid terminator?
	 je	 short FCN_GPSKIP_MATCH ; Jump if so

	 cmp	 al,' '         ; Izit valid terminator?
	 je	 short FCN_GPSKIP_MATCH ; Jump if so

	 cmp	 al,TAB 	; Izit valid terminator?
	 je	 short FCN_GPSKIP_MATCH ; Jump if so

	 cmp	 al,CR		; Izit valid terminator?
	 jne	 short FCN_GPSKIP_LOOP ; Jump if not
FCN_GPSKIP_MATCH:
	 mov	 ax,GPSKIPTAB.GPSKIP_FLG[bx] ; Get associated flags
	 or	 GPS_FLAG,ax	; Include it

	 add	 si,GPSKIPTAB.GPSKIP_LEN[bx] ; Skip to next keyword in the
				; input stream
	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,','         ; Izit valid separator?
	 jne	 short @F	; Jump if not

	 inc	 si		; Skip over it

	 jmp	 short FCN_GPSKIP_START ; Go around again
@@:
	 clc			; Indicate all went well

	 jmp	 short FCN_GPSKIP_EXIT ; Join common exit

FCN_GPSKIP_LOOP:
	 add	 bx,type GPSKIP_STR ; Skip to next internal keyword entry

	 LOOPS	 FCN_GPSKIP_NEXT ; Jump if more internal entries to check

	 mov	 si,LASTKEY	; Get offset of start of last keyword
	 lea	 di,MSG_UNKLST	; Pass address of error message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 jmp	 short FCN_GPSKIP_ERR ; Join common error code

FCN_GPSKIP_EQ:
	 push	 offset cs:MSG_SEP ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we allow no mistakes
FCN_GPSKIP_ERR:
	 stc			; Indicate there was a problem
FCN_GPSKIP_EXIT:
	 REGREST <di,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_GPSKIP endp 		; End FCN_GPSKIP procedure
% ifidni <OEM>,<BET>
	 NPPROC  FCN_INTRUDE -- INTRUDE Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

INTRUDE function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 push	 ds		; Save for a moment

	 push	 seg RGROUP	; Get segment of DEV_FLAG
	 pop	 ds		; Address it
	 assume  ds:RGROUP	; Tell the assembler about it

	 test	 DEV_FLAG,@DEV_VCPI ; Are we using VCPI services?
	 jz	 short FCN_INTRUDE_EXIT ; Jump if not

	 or	 DEV_FLAG,@DEV_INTRUDE ; Mark as INTRUDE present

	 push	 seg PGROUP	; Get segment of DEVLOAD
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 or	 DEVLOAD,@DEVL_INTRUDE ; Mark as INTRUDE present

	 or	 DBG_FLAG,@DBG_IBV ; Mark as setting Ctrl-Alt-PAD5 IRQ1
				; to IBV value
FCN_INTRUDE_EXIT:
	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_INTRUDE endp		; End FCN_INTRUDE procedure
endif				; IFIDNI <OEM>,<BET>
	 NPPROC  FCN_KEYB -- KEYB Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

KEYB=code function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 REGSAVE <eax,ebx,ecx,edi> ; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 near ptr FCN_KEYB_EQ ; Too bad

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

; Search for the following text in our keyb table

FCN_KEYB_START:
	 call	 SKIP_WHITE	; Skip over more white space

	 mov	 cx,KEYBTAB_CNT ; Get # keywords we support
	 xor	 ebx,ebx	; Initialize index into KEYBTAB_xxx
FCN_KEYB_NEXT:
	 REGSAVE <cx,si>	; Save for a moment

	 mov	 di,KEYBTAB_PTR[ebx*(type KEYBTAB_PTR)] ; Get offset of keyword text in NGROUP
	 mov	 cx,KEYBTAB_LEN[ebx*(type KEYBTAB_LEN)] ; Get # bytes in ...
    repe cmps	 ds:[si].LO,KEYBTAB_PTR.LO[di] ; Compare 'em

	 mov	 al,ds:[si]	; Get next byte after input string

	 REGREST <si,cx>	; Restore
	 jne	 short FCN_KEYB_LOOP ; Jump if no match

	 cmp	 al,';'         ; Izit valid terminator?
	 je	 short FCN_KEYB_MATCH ; Jump if so

	 cmp	 al,' '         ; Izit valid terminator?
	 je	 short FCN_KEYB_MATCH ; Jump if so

	 cmp	 al,TAB 	; Izit valid terminator?
	 je	 short FCN_KEYB_MATCH ; Jump if so

	 cmp	 al,CR		; Izit valid terminator?
	 je	 short FCN_KEYB_MATCH ; Jump if so
FCN_KEYB_LOOP:
	 inc	 ebx		; Skip to next index

	 LOOPS	 FCN_KEYB_NEXT	; Jump if more internal entries to check

	 mov	 si,LASTKEY	; Get offset of start of last keyword
	 lea	 di,MSG_UNKLST	; Pass address of error message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 jmp	 short FCN_KEYB_ERR ; Join common error code

FCN_KEYB_MATCH:
	 add	 si,KEYBTAB_LEN[ebx*(type KEYBTAB_LEN)] ; Skip to next keyword in the
				; input stream
; Copy the KEY_TAB and KEY_TOG table contents to the active locations

	 REGSAVE <esi,es>	; Save for a moment

	 mov	 ax,seg DGROUP	; Get segment of KEY_TAB & KEY_TOG
	 mov	 es,ax		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 lea	 edi,KEY_TAB	; DGROUP:EDI ==> keyboard translation table
	 movzx	 esi,KEYBTAB_ACT[ebx*(type KEYBTAB_STR)].KEYBTAB_TAB ; Get offset in NGROUP of KEY_TAB table
	 mov	 ecx,KEY_TABLEN ; Get # entries
	 imul	 ecx,@KEY_TAB_SIZ ; Times # bytes per entry
	 shr	 ecx,1-0	; Convert from bytes to words

     rep movs	 KEY_TAB.ELO[edi],KEY_TAB_GR129[esi] ; Copy to save area

	 lea	 edi,KEY_TOG	; DGROUP:EDI ==> keyboard toggle table
	 movzx	 esi,KEYBTAB_ACT[ebx*(type KEYBTAB_STR)].KEYBTAB_TOG ; Get offset in NGROUP of KEY_TOG table
	 mov	 ecx,KEY_TABLEN ; Get # entries

     rep movs	 KEY_TOG[edi],KEY_TOG_GR129[esi] ; Copy to save area

	 REGREST <es,esi>	; Restore
	 assume  es:NGROUP	; Tell the assembler about it

	 clc			; Indicate all went well

	 jmp	 short FCN_KEYB_EXIT ; Join common exit code

FCN_KEYB_EQ:
	 push	 offset cs:MSG_SEP ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we allow no mistakes
FCN_KEYB_ERR:
	 stc			; Indicate there was a problem
FCN_KEYB_EXIT:
	 REGREST <edi,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_KEYB endp			; End FCN_KEYB procedure
	 NPPROC  FCN_LCD -- LCD Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

LCD function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 ARG_FLAG,@ARG_LCD ; Mark as LCD present

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_LCD  endp			; End FCN_LCD procedure
	 NPPROC  FCN_LOADHIGH -- LOADHIGH Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

LOADHIGH function (is now the default)

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 ARG_FLAG,@ARG_LOADHI ; Mark as LOADHIGH present

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_LOADHIGH endp		; End FCN_LOADHIGH procedure
	 NPPROC  FCN_LOADLOW -- LOADLOW Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

LOADLOW function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 and	 ARG_FLAG,not @ARG_LOADHI ; Mark as no longer LOADHIGHing

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_LOADLOW endp		; End FCN_LOADLOW procedure
	 NPPROC  FCN_LOGSIZE -- LOGSIZE Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

LOGSIZE function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 REGSAVE <eax,ecx,edx,edi> ; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_LOGSIZE_EQ ; Too bad

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 mov	 ecx,10 	; Use base 10 to convert
	 call	 U16_BASE2BIN	; Convert the number at DS:ESI to binary in EAX
	 jc	 short FCN_LOGSIZE_OVF ; Jump if too large

; Make sure the buffer length is a multiple of 80.
	 mov	 ecx,80 	; Buffer size
	 add	 eax,ecx	; Round up
	 dec	 eax		; Less 1
	 sub	 edx,edx	; Clear high dword of divisor
	 div	 ecx		; EAX = number of records; discard remainder
	 mul	 ecx		; Convert records to bytes
	 mov	 LOGLEN,eax	; Save for later use

	 clc			; Indicate all went well

	 jmp	 short FCN_LOGSIZE_EXIT ; Join common exit code

FCN_LOGSIZE_OVF:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 lea	 di,MSG_OVF	; Pass address of error message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 jmp	 short FCN_LOGSIZE_ERR ; Join common error code

FCN_LOGSIZE_EQ:
	 push	 offset cs:MSG_SEP ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we allow no mistakes
FCN_LOGSIZE_ERR:
	 stc			; Indicate there was a problem
FCN_LOGSIZE_EXIT:
	 REGREST <edi,edx,ecx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_LOGSIZE endp		; End FCN_LOGSIZE procedure
	 NPPROC  FCN_MONO -- MONO Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

MONO function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 LCL_FLAG,@LCL_MONO ; Mark as using monochrome adapter

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_MONO endp			; End FCN_MONO procedure
	NPPROC	FCN_NOGD -- NOGD Function
	assume	ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

NOGD function

On entry:

DS:ESI	==>	command line following keyword

On exit:

DS:ESI	==>	next character to scan

|

	or	LC4_FLAG,@LC4_NOGD ; Mark as not automatically
				; setting GD bit in DR7
	clc			; Indicate all went well

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOGD endp			; End FCN_NOGD procedure
	 NPPROC  FCN_NORMLIDT -- NORMLIDT Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

NORMLIDT function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 push	 ds		; Save for a moment

	 push	 seg RGROUP	; Get segment of DEV_FLAG
	 pop	 ds		; Address it
	 assume  ds:RGROUP	; Tell the assembler about it

	 or	 AR2_FLAG,@AR2_NORMLIDT ; Mark as disabling RM LIDT
	 or	 DEV_FLAG,@DEV_NORMLIDT ; ...

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NORMLIDT endp		; End FCN_NORMLIDT procedure
	 NPPROC  FCN_NOSWAP -- NOSWAP Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

NOSWAP function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 LCL_FLAG,@LCL_SCRN ; Mark as disabling screen swap

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOSWAP endp 		; End FCN_NOSWAP procedure
	NPPROC	FCN_NOWINK -- NOWINK Function
	assume	ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

NOWINK function

On entry:

DS:ESI	==>	command line following keyword

On exit:

DS:ESI	==>	next character to scan

|


	REGSAVE <ax,dx,ds>	; Save for a moment

	test	WKD_FLAG,@WKD_ENABLE ; Izit enabled?
	jz	short @F	; Jump if not to avoid displaying message twice

	mov	ax,seg RGROUP	; Get segment of TRP_FLAG
	mov	ds,ax		; Address it
	assume	ds:RGROUP	; Tell the assembler about it

	and	WKD_FLAG,not @WKD_ENABLE ; Disable Windows Kernel Debugger Services
	and	TRP_FLAG,not (@TRP_I68 or @TRP_WCB) ; Disable trapping for
				; Windows Kernel Debugger services in RM
	mov	ax,seg NGROUP	; Get segment of MSG_NOWINK
	mov	ds,ax		; Address it
	assume	ds:NGROUP	; Tell the assembler about it

	DOSCALL @STROUT,MSG_NOWINK ; Tell 'em what we're doing
@@:
	REGREST <ds,dx,ax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	clc			; Indicate all went well

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOWINK endp 		; End FCN_NOWINK procedure
	 NPPROC  FCN_PATH -- PATH=d:\dir[,d:\dir2[...]] Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

PATH=d:\dir[,d:\dir2[...]] function

One or more directories may be specified for source code.  It is
highly recommended that the drive letter be specified, since the
current directory depends on the current client settings.

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 REGSAVE <ecx,edi,es>	; Save

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_PATH_EQ ; Too bad

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 push	 seg DGROUP	; Group to address
	 pop	 es		; Prepare to address DGROUP
	 assume  es:DGROUP	; Tell the assembler

	 lea	 edi,FBROWS_PATH ; Destination
	 mov	 ecx,@FBROWS_PMAX ; Maximum characters

	 call	 U16_PATH_COM	; Process path
	 clc			; Indicate success

	 jmp	 short FCN_PATH_EXIT ; Join common exit

FCN_PATH_EQ:
	 push	 offset cs:MSG_SEP ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we allow no mistakes

	 stc			; Indicate there was a problem
FCN_PATH_EXIT:
	 REGREST <es,edi,ecx>	; Restore
	 assume  es:NGROUP	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_PATH endp			; End FCN_PATH procedure
	 NPPROC  FCN_PASSTHROUGH -- PASSTHROUGH=nn,nn,... Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

PASSTHROUGH=nn,nn,... function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 REGSAVE <eax,cx,di>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Izit present?
	 jne	 short FCN_PT_EQ ; Jump if not

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,CR		; Izit EOL?
	 je	 short FCN_PT_CLC ; Jump if so
FCN_PT_NEXT:
	 call	 U16_HEX2DD	; Convert DS:ESI from hex to binary EAX
	 jc	 short FCN_PT_OVF ; Jump if too large

	 cmp	 eax,0FFh	; Check for within 8-bit range
	 ja	 short FCN_PT_OVF ; Jump if too large

; Check for interrupt 8-F
	 sub	 al,08h 	; Convert to 0-7
	 jc	 short FCN_PT_HINT ; Jump if invalid

	 cmp	 al,08h 	; Izit in PIC1?
	 jnb	 short @F	; Jump if not

	 mov	 cl,al		; Get number of bits to shift
	 mov	 al,not 1	; Get mask for PIC1 with IRQ0 enabled
	 rol	 al,cl		; Move into position
	 and	 PASSTHROUGH1,al ; Combine with saved values
	 jmp	 short FCN_PT_LOOP ; Go around again

@@:
; Check for interrupt 70-77
	 sub	 al,70h-08h	; Convert to 0-7
	 jc	 short FCN_PT_HINT ; Jump if invalid

	 cmp	 al,08h 	; Izit in PIC2?
	 jnb	 short FCN_PT_HINT ; Jump if not

	 mov	 cl,al		; Get number of bits to shift
	 mov	 al,not 1	; Get mask for PIC2 with IRQ8 enabled
	 rol	 al,cl		; Move into position
	 and	 PASSTHROUGH2,al ; Combine with saved values
FCN_PT_LOOP:
	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,','         ; Izit entry separator?
	 jne	 short FCN_PT_CLC ; Jump if not

	 inc	 si		; Skip over the separator

	 call	 SKIP_WHITE	; Skip over more white space

	 jmp	 short FCN_PT_NEXT ; Go around again

FCN_PT_CLC:
	 or	 PASSTHROUGH1,11100000b ; Disable ones we don't yet support
	 or	 PASSTHROUGH2,00101111b ; Disable ones we don't yet support

	 clc			; Mark as successful

	 jmp	 short FCN_PT_EXIT ; Join common exit code

FCN_PT_EQ:
	 push	 offset cs:MSG_SEP ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we allow no mistakes
	 jmp	 short FCN_PT_ERRCOM2 ; Join common error code

FCN_PT_OVF:
	 lea	 di,MSG_OVF	; Pass address of error message
	 jmp	 short FCN_PT_ERRCOM ; Join common error code

FCN_PT_HINT:
	 lea	 di,MSG_BADHINT ; Pass address of error message
;;;;;;;  jmp	 short FCN_PT_ERRCOM ; Join common error code

FCN_PT_ERRCOM:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI
FCN_PT_ERRCOM2:
	 stc			; Indicate there was a problem
FCN_PT_EXIT:
	 REGREST <di,cx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_PASSTHROUGH endp		; End FCN_PASSTHROUGH procedure
	 NPPROC  FCN_PORTINIT -- PORTINIT=string Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

PORTINIT=string function

The string saved to PORTINIT is sent out to the serial port when
the SETCOM parameters are initialized at INIT_VIRT time.  The system
will then be in a state where a BREAK signal received will trigger
a call to SWATTER.  SWATTER will automatically call CMD_REMDBG the
first time.

Let's say a customer receives SWAT for a problem.  They would put
SETCOM=1,2400
(assuming those are the correct settings) in the profile, as well as
PORTINIT=\rAT\rATE1Q0\rATS0=1\r
then reboot.

On our end, we would bring up SWAT, Ctrl-F8 to talk to our modem,
ATDT 9,,number
to dial the customer, then we would get connected.  Ctrl-6 sends
a break, which triggers a breakpoint on the customer's end.  As
soon as SWT packets start coming in on the chat screen, we exit
chat and Ctrl-F9 to start a session.

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 REGSAVE <ecx,edi,es>	; Save

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_PORTINIT_EQ ; Too bad

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 push	 seg DGROUP	; Group to address
	 pop	 es		; Prepare to address DGROUP
	 assume  es:DGROUP	; Tell the assembler

	 lea	 edi,PORTINIT	; Destination
	 mov	 cx,@PORTINIT_LEN ; Maximum characters
@@:
	 lods	 ds:[si].LO	; Get next character
	 cmp	 al,';'         ; Izit a comment?
	 je	 short @F	; Jump if so

	 cmp	 al,CR		; Izit the end of the line?
	 jbe	 short @F	; Jump if so

S32	 stos	 PORTINIT[edi]	; Save character
	 LOOPS	 @B		; Go around again
@@:
	 dec	 si		; Back off to comment or CR
	 sub	 al,al		; Terminate with a null
	 sub	 cx,@PORTINIT_LEN ; Get -(characters remaining)
	 neg	 cx		; Make it positive
	 std			; Set backward direction
@@:
S32	 stos	 PORTINIT[edi]	; Save character
	 cmp	 PORTINIT[edi],' ' ; Izit trailing space?
	 je	 short FCN_PORTINIT_SPACE ; Jump if so

	 cmp	 PORTINIT[edi],TAB ; Izit a trailing tab?
	 jne	 short @F	; Jump if not
FCN_PORTINIT_SPACE:
	 LOOPS	 @B		; Go around again
@@:
	 cld			; Restore normal direction

	 or	 LC3_FLAG,@LC3_PORTINIT ; Set flag for later processing

	 clc			; Indicate success

	 jmp	 short FCN_PORTINIT_EXIT ; Join common exit

FCN_PORTINIT_EQ:
	 push	 offset cs:MSG_SEP ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we allow no mistakes

	 stc			; Indicate there was a problem
FCN_PORTINIT_EXIT:
	 REGREST <es,edi,ecx>	; Restore
	 assume  es:NGROUP	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_PORTINIT endp		; End FCN_PORTINIT procedure
	 NPPROC  FCN_PRO -- PRO=d:\path\filename.ext Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

PRO=d:\path\filename.ext function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 push	 OLDINT24_VEC	; Save old value so we're recursive
	 call	 INST24 	; Install local INT 24h handler

; Ensure we're not already processing a profile

	 test	 NRD_FLAG,@NRD_PRO ; Already in process?
	 jnz	 short FCN_PRO_UNK ; Yes, so that's an error

	 or	 NRD_FLAG,@NRD_PRO ; Mark as being processed

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_PRO_EQ ; Too bad

	 inc	 si		; Skip over the character
	 mov	 dx,si		; Save as start of profile fid

; Search for end of filename

@@:
	 lods	 ds:[si].LO	; Get next character

	 cmp	 al,' '         ; Too small for filename?
	 ja	 short @B	; No, go around again

	 dec	 si		; Back off to terminator

; Attempt to open the file

	 mov	 cl,0		; String terminator
	 xchg	 cl,[si]	; Terminate filename.ext
	 mov	 al,0		; Access code for read-only
	 stc			; Assume error
	 DOSCALL @OPENF2	; Open it
	 xchg	 cl,[si]	; Restore filename.ext
	 jc	 short FCN_PRO_OPENERR ; Something went wrong

	 mov	 bx,ax		; Copy to file handle register

	 REGSAVE <ds>		; Save for a moment

	 mov	 ds,MAPSEG_NXT	; Setup DS for OPENF2
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 PROF_SEG,ds	; Save for later use

	 xor	 dx,dx		; DS:DX ==> profile segment
	 mov	 cx,0FFFFh	; Read in all of it

	 stc			; Assume error
	 DOSCALL @READF2	; Read it in

	 mov	 PROF_CNT,ax	; Save # bytes read

	 push	 bx		; Save for a moment

	 mov	 bx,ax		; Copy to index register
	 mov	 ds:[bx].LO,EOF ; Terminate with EOF

	 pop	 bx		; Restore

	 REGREST <ds>		; Restore
	 assume  ds:nothing	; Tell the assembler about it
	 jc	 short FCN_PRO_READERR ; Something went wrong

	 add	 ax,(16-1)+1	; Round up to para boundary (count in EOF, too)
	 shr	 ax,4-0 	; Convert from bytes to paras
	 add	 MAPSEG_NXT,ax	; Skip over profile segment

	 push	 offset NGROUP:MEMERR_PRO ; Pass offset of error message
	 call	 CHECK_NXTSEG	; Ensure we've enough room

;;;;;;;; stc			; Assume error
	 DOSCALL @CLOSF2	; Close it up
				; Ignore error return

	 call	 PROC_PROFILE	; Process the profile entries
				; Return with CF significant
	 jmp	 short FCN_PRO_EXIT ; Join common tail code

FCN_PRO_OPENERR:
	 push	 offset cs:MSG_POPEN ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we couldn't open the file

	 jmp	 short FCN_PRO_ERR ; Join common tail code

FCN_PRO_READERR:
	 push	 offset cs:MSG_PREAD ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we couldn't read the file

	 jmp	 short FCN_PRO_ERR ; Join common tail code

FCN_PRO_UNK:
	 push	 offset cs:MSG_UNK ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we couldn't decipher their handwriting

	 jmp	 short FCN_PRO_ERR ; Join common tail code

FCN_PRO_EQ:
	 push	 offset cs:MSG_SEP ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we allow no mistakes
FCN_PRO_ERR:
	 stc			; Indicate there was a problem
FCN_PRO_EXIT:
	 pushf			; Save flags
	 call	 REST24 	; Restore INT 24h handler
	 and	 NRD_FLAG,not @NRD_PRO ; Mark as not being processed
	 popf			; Restore
	 pop	 OLDINT24_VEC	; Restore

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

FCN_PRO  endp			; End FCN_PRO procedure
	 NPPROC  FCN_PS4 -- PS4 Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

PS4 function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 REGSAVE <eax,di>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_PS4_EQ ; Too bad

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 call	 U16_HEX2DD	; Convert DS:ESI from hex to binary EAX
	 jc	 short FCN_PS4_OVF ; Jump if too large

	 cmp	 eax,0FFFFh	; Check for within 16-bit range
	 ja	 short FCN_PS4_OVF ; Jump if too large

	 mov	 PS4IO,ax	; Save for later use

	 or	 LC2_FLAG,@LC2_PS4 ; Mark as Periscope 4 board present

	 clc			; Indicate all went well

	 jmp	 short FCN_PS4_EXIT ; Join common exit code

FCN_PS4_OVF:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 lea	 di,MSG_OVF	; Pass address of error message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 jmp	 short FCN_PS4_ERR ; Join common error code

FCN_PS4_EQ:
	 push	 offset cs:MSG_SEP ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we allow no mistakes
FCN_PS4_ERR:
	 stc			; Indicate there was a problem
FCN_PS4_EXIT:
	 REGREST <di,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_PS4  endp			; End FCN_PS4 procedure
	 NPPROC  FCN_PROXSRCH -- PROXSRCH=r[,g] Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

PROXSRCH=r[,g] function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 REGSAVE <eax,bx,di>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Izit present?
	 jne	 short FCN_PROXSRCH_OVF ; Jump if not (argument required)

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,CR		; Izit EOL?
	 je	 short FCN_PROXSRCH_OVF ; Jump if so (required argument missing)

	 call	 U16_HEX2DD	; Convert DS:ESI from hex to binary EAX
	 jc	 short FCN_PROXSRCH_OVF ; Jump if too large

	 cmp	 eax,0FFh	; Check for within 8-bit range
	 ja	 short FCN_PROXSRCH_OVF ; Jump if too large

	 mov	 bh,al		; Save range
	 mov	 bl,PROXSRCH.LO ; Get default granularity

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,','         ; Izit entry separator?
	 jne	 short FCN_PROXSRCH_EOL ; Jump if not

	 inc	 si		; Skip over the separator

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,CR		; Izit EOL?
	 je	 short FCN_PROXSRCH_OVF ; Jump if so (required argument missing)

	 call	 U16_HEX2DD	; Convert DS:ESI from hex to binary EAX
	 jc	 short FCN_PROXSRCH_OVF ; Jump if too large

	 cmp	 eax,0FFh	; Check for within 8-bit range
	 ja	 short FCN_PROXSRCH_OVF ; Jump if too large

	 mov	 bl,al		; Save granularity
FCN_PROXSRCH_EOL:
	 mov	 al,bh		; Put range in AX
	 mul	 bl		; Product of range*gran should not exceed 255
	 cmp	 ax,0ffh	; Did we overflow?
	 ja	 short FCN_PROXSRCH_OVF ; Jump if too large

	 or	 ax,ax		; Is either granularity or range 0?
	 jz	 short @F	; Jump if so

	 mov	 ax,bx		; Get range & granularity
@@:
	 mov	 PROXSRCH,ax	; Save proximity search parameters

	 clc			; Mark as successful

	 jmp	 short FCN_PROXSRCH_EXIT ; Join common exit code

FCN_PROXSRCH_OVF:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 lea	 di,MSG_OVF	; Pass address of error message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 stc			; Indicate there was a problem
FCN_PROXSRCH_EXIT:
	 REGREST <di,bx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_PROXSRCH endp		; End FCN_PROXSRCH procedure
	 NPPROC  FCN_RMLIDT -- RMLIDT Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

RMLIDT function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 push	 ds		; Save for a moment

	 push	 seg RGROUP	; Get segment of DEV_FLAG
	 pop	 ds		; Address it
	 assume  ds:RGROUP	; Tell the assembler about it

	 and	 AR2_FLAG,not @AR2_NORMLIDT ; Mark as enabling RM LIDT
	 and	 DEV_FLAG,not @DEV_NORMLIDT ; ...

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_RMLIDT endp 		; End FCN_RMLIDT procedure
	 NPPROC  FCN_SAVESCREEN -- SAVESCREEN Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

SAVESCREEN function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 REGSAVE <eax,ecx,edi>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_SAVESCREEN_EQ ; Too bad

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 mov	 ecx,10 	; Use base 10 to convert
	 call	 U16_BASE2BIN	; Convert the number at DS:ESI to binary in EAX
	 jc	 short FCN_SAVESCREEN_OVF ; Jump if too large

	 cmp	 eax,0000FFFFh	; Ensure not too large
	 ja	 short FCN_SAVESCREEN_OVF ; Jump if too large

	 and	 eax,eax	; Izit zero (invalid)?
	 jz	 short @F	; Jump if so (ignore it)

	 mov	 NLSTBUF,eax	; Save for later use
@@:
	 clc			; Indicate all went well

	 jmp	 short FCN_SAVESCREEN_EXIT ; Join common exit code

FCN_SAVESCREEN_OVF:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 lea	 di,MSG_OVF	; Pass address of error message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 jmp	 short FCN_SAVESCREEN_ERR ; Join common error code

FCN_SAVESCREEN_EQ:
	 push	 offset cs:MSG_SEP ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we allow no mistakes
FCN_SAVESCREEN_ERR:
	 stc			; Indicate there was a problem
FCN_SAVESCREEN_EXIT:
	 REGREST <edi,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_SAVESCREEN endp		; End FCN_SAVESCREEN procedure
	 NPPROC  FCN_SETCOM -- SETCOM=port,baud[,{IRQ|*|p}[,portbase]]
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT!

SETCOM=port,baud[,{IRQ|*|p}[,portbase]] function.

port is a serial port index from 1-4 (COM1-COM4)
baud is the decimal baud rate from 1-115200
The IRQ may be specified, * for the default, or p for polled (no
interrupt driven communications)
portbase is the I/O base address for the specified port

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

!

	 REGSAVE <eax,ebx,ecx,edx,edi,gs> ; Save

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Izit present?
	 jne	 near ptr FCN_SETCOM_ERR ; Jump if not (argument required)

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,CR		; Izit EOL?
	 je	 near ptr FCN_SETCOM_ERR ; Jump if so (required argument missing)

	 mov	 ecx,10 	; Use base 10 to convert
	 call	 U16_BASE2BIN	; Convert the number at DS:ESI to binary in EAX
	 jc	 near ptr FCN_SETCOM_ERR ; Jump if too large

	 cmp	 eax,4		; Izit within limits?
	 ja	 near ptr FCN_SETCOM_ERR ; Jump if too large

	 mov	 COMPORT,ax	; Save for later

	 sub	 ax,1		; Make it 0 based
	 jc	 near ptr FCN_SETCOM_ERR ; Jump if already 0 (invalid)

; If the port base in the BIOS data area is bogus, that's OK if the user
; specifies a port base...  We'll check for that later, when we're setting
; up the parameters.

	 push	 seg BIOSDATA	; Get segment of BIOS data area at 40:0
	 pop	 gs		; Address it
	 assume  gs:BIOSDATA	; Tell the assembler

	 mov	 bx,RS232_BASE[eax*2] ; Get port base from BIOS
	 mov	 cl,$COM13	; Assume IRQ4
	 shr	 al,1		; If COM2/COM4, set CF=1
	 sbb	 cl,($COM13-$COM24)-1 ; Use IRQ3 for COM2/COM4

	 mov	 PORTBASE,bx	; Set default port base
	 mov	 PORTIRQ,cl	; Set default IRQ level

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,','         ; Izit entry separator?
	 jne	 near ptr FCN_SETCOM_ERR ; Jump if not

	 inc	 si		; Skip over the separator

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,CR		; Izit EOL?
	 je	 near ptr FCN_SETCOM_ERR ; Jump if so (required argument missing)

	 mov	 ecx,10 	; Use base 10 to convert
	 call	 U16_BASE2BIN	; Convert the number at DS:ESI to binary in EAX
	 jc	 near ptr FCN_SETCOM_ERR ; Jump if too large

	 mov	 ebx,eax	; Use baud rate as divisor
	 mov	 eax,@BAUD_DIVISOR ; Get dividend
	 cmp	 ebx,eax	; Izit within limits?
	 ja	 near ptr FCN_SETCOM_ERR ; Jump if too large

	 or	 ebx,ebx	; Izit non-zero?
	 jz	 near ptr FCN_SETCOM_ERR ; Jump if not

	 push	 eax		; Save dividend

	 cdq			; Clear high 32 bits
	 div	 ebx		; (E)AX = divisor latch value

	 mov	 PORTDLATCH,ax	; Save divisor latch

	 movzx	 ebx,ax 	; Use divisor latch as divisor

	 pop	 eax		; Restore dividend

	 cdq			; Clear high 32 bits
	 div	 ebx		; (E)AX = normalized baud rate

	 mov	 PORTBAUD,eax	; Save for display

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,CR		; Izit EOL?
	 je	 short FCN_SETCOM_EOL ; Jump if so (we're done)

	 cmp	 al,';'         ; Izit EOL?
	 je	 short FCN_SETCOM_EOL ; Jump if so (we're done)

	 cmp	 al,','         ; Izit entry separator?
	jne	near ptr FCN_SETCOM_ERR ; Jump if not

	 inc	 si		; Skip over the separator

	 call	 SKIP_WHITE	; Skip over more white space

; Get IRQ # or p for polled.  If '*' specified, go with the default
	 cmp	 al,'*'         ; Should we go with the default?
	 je	 short FCN_SETCOM_SKIPIRQ ; Jump if so

	 cmp	 al,'P'         ; Izit polled?
	 jne	 short @F	; Jump if not

	 mov	 PORTIRQ,0ffh	; No IRQ; use polled operation
FCN_SETCOM_SKIPIRQ:
	 inc	 si		; Skip '*'
	 jmp	 short FCN_SETCOM_XIRQ ; Jump if so

@@:
	 mov	 ecx,10 	; Use base 10 to convert
	 call	 U16_BASE2BIN	; Convert the number at DS:ESI to binary in EAX
	 jc	 short FCN_SETCOM_ERR ; Jump if too large

	 cmp	 eax,0000FFFFh	; Izit within limits?
	 ja	 short FCN_SETCOM_ERR ; Jump if too large

	 cmp	 ax,$COM13	; Izit IRQ4?
	 je	 short @F	; Jump if so

	 cmp	 ax,$COM24	; Izit IRQ3?
	 jne	 short FCN_SETCOM_ERR ; Jump if not
@@:
	 mov	 PORTIRQ,al	; Save new IRQ level
FCN_SETCOM_XIRQ:
	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,CR		; Izit EOL?
	 je	 short FCN_SETCOM_EOL ; Jump if so (we're done)

	 cmp	 al,';'         ; Izit EOL?
	 je	 short FCN_SETCOM_EOL ; Jump if so (we're done)

	 cmp	 al,','         ; Izit entry separator?
	 jne	 short FCN_SETCOM_ERR ; Jump if not

	 inc	 si		; Skip over the separator

	 call	 SKIP_WHITE	; Skip over more white space

	 call	 U16_HEX2DD	; Convert DS:ESI from hex to binary EAX
	 jc	 short FCN_SETCOM_ERR ; Jump if too large

	 cmp	 eax,0000FFFFh	; Izit within limits?
	 ja	 short FCN_SETCOM_ERR ; Jump if too large

	 mov	 PORTBASE,ax	; Save for later
FCN_SETCOM_EOL:
; Check for a valid PORTBASE value
	 cmp	 PORTBASE,0	; Izit totally bogus?
	 lea	 di,MSG_BADBASE ; "Default port base address invalid"
	 je	 short FCN_SETCOM_ERR2 ; Jump if so

	 or	 LC3_FLAG,@LC3_REM ; Set up serial port in INIT_PROT

	 clc			; Mark as successful

	 jmp	 short FCN_SETCOM_EXIT ; Join common exit code

FCN_SETCOM_ERR:
	 lea	 di,MSG_COM	; Pass address of error message
FCN_SETCOM_ERR2:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 stc			; Indicate there was a problem
FCN_SETCOM_EXIT:
	 REGREST <gs,edi,edx,ecx,ebx,eax> ; Restore
	 assume  gs:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_SETCOM endp 		; End FCN_SETCOM procedure
	 NPPROC  FCN_LOADSYM -- LOADSYM[=d:\path\filename.ext] Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

LOADSYM
LOADSYM=d:\path\filename.ext [optional args]
	where optional args are zero or more of
	/b=xxxxxxxx		physical base address in hex
	/h			HPDA flag
	/li-			disable line numbers
	/xl			disable larger comparison w/SYMSIZE

Be sure to use the /H switch to enable PL0 DPMI services needed to
load symbols from within SWAT via the LS command.  The second form
reads the specified SSF file into extended memory at EXTSYM_OFF and
saves its offset, length and checksum.	At protected mode init time,
this data is re-checksumed and processed if the length is non-zero.

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

FCNSYM_LCL	struc		; Local variables
FCNSYM_NEXTLIN	dd	?	; Next linear offset for block move
FCNSYM_FH	dw	?	; File handle
FCNSYM_BSIZE	dw	?	; Actual number of bytes in block
FCNSYM_GDT	db (size MDTE_STR) dup (?) ; GDT for BIOS block move
FCNSYM_XMBMOVE	db (size XMBMOVE_STR) dup (?) ; XMS block move structure
FCNSYM_FLAG	dw	?	; Flags (see @FCNSYM_xxx below)
FCNSYM_LCL	ends

@FCNSYM_XL equ	 8000h		; Don't use larger of EXTSYM_LEN and SYMSIZE

	 REGSAVE <eax,ebx,ecx,edx,ebp,es,gs> ; Save

	 sub	 esp,size FCNSYM_LCL ; Allocate local storage
	 mov	 bp,sp		; Address beginning of local variable block

	 push	 OLDINT24_VEC	; Save old value so we're recursive
	 call	 INST24 	; Install local INT 24h handler

	 mov	 [bp].FCNSYM_FH,-1 ; Set file handle as not used
	 mov	 [bp].FCNSYM_FLAG,0 ; Initialize flags

	 mov	 EXTSYM_LEN,0	; Prepare to calculate total length
	 or	 ARG_FLAG,@ARG_DPMI ; Enable PL0 DPMI host services
	 or	 AR2_FLAG,@AR2_DPMITMP ; Mark as temporary

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Was optional filename specified?
	 jne	 short FCN_LOADSYM_NEXTSW ; Jump if not

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 mov	 dx,si		; Save as start of symbol table fid

; Search for end of filename

@@:
	 lods	 ds:[si].LO	; Get next character

	 cmp	 al,'/'         ; Izit switch character?
	 je	 short @F	; Jump if so

	 cmp	 al,' '         ; Too small for filename?
	 ja	 short @B	; No, go around again
@@:
	 dec	 si		; Back off to terminator

; Attempt to open the file

	 mov	 cl,0		; String terminator
	 xchg	 cl,[si]	; Terminate filename.ext
	 mov	 al,0		; Access code for read-only
	 stc			; Assume error
	 DOSCALL @OPENF2	; Open it
	 xchg	 cl,[si]	; Restore filename.ext
	 jc	 near ptr FCN_LOADSYM_OPENERR ; Something went wrong

	 mov	 bx,ax		; Copy to file handle register
	 mov	 [bp].FCNSYM_FH,ax ; Save in local data area

; Check for optional switches

FCN_LOADSYM_NEXTSW:
	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'/'         ; Izit switch character?
	 jne	 short FCN_LOADSYM_XSW ; Jump if not

	 inc	 si		; Skip over the switch character
	 call	 SKIP_WHITE	; Skip over more white space
	 lods	 ds:[si].LO	; Get and skip over next character

	 cmp	 al,'B'         ; Izit new physical base address?
	 jne	 short FCN_LOADSYM_XB ; Jump if not

	 call	 SKIP_WHITE	; Skip over more white space
	 lods	 ds:[si].LO	; Get next character

	 cmp	 al,'='         ; Izit separator?
	 jne	 near ptr FCN_LOADSYM_SWERR ; Jump if not

	 call	 SKIP_WHITE	; Skip over more white space

	 mov	 ecx,16 	; Use base 16 to convert
	 call	 U16_BASE2BIN	; Convert the number at DS:ESI to binary in EAX

	 mov	 EXTSYM_OFF,eax ; Save as new physical base address

	 jmp	 short FCN_LOADSYM_NEXTSW ; Go around again

FCN_LOADSYM_XB:
	 cmp	 al,'H'         ; Izit HPDA flag?
	 jne	 short FCN_LOADSYM_XH ; Jump if not

	 and	 AR2_FLAG,not @AR2_DPMITMP ; Mark as using full HPDA

	 jmp	 short FCN_LOADSYM_NEXTSW ; Go around again

FCN_LOADSYM_XH:
	 cmp	 al,'L'         ; Izit start of 'LI-'?
	 jne	 short FCN_LOADSYM_XLI ; Jump if not

	 cmp	 ds:[si].ELO,'-I' ; Izit end of 'LI-'?
	 jne	 short FCN_LOADSYM_XLI ; Jump if not

	 add	 si,3-1 	; Skip over the switch keyword
	 or	 LC2_FLAG,@LC2_NOLINE ; Turn on suppress line display bit

	 jmp	 short FCN_LOADSYM_NEXTSW ; Go around again

FCN_LOADSYM_XLI:
	 cmp	 al,'X'         ; Izit start of 'XL'?
	 jne	 short FCN_LOADSYM_XXL ; Jump if not

	 cmp	 ds:[si].LO,'L' ; Izit end of 'XL'?
	 jne	 short FCN_LOADSYM_XXL ; Jump if not

	 add	 si,2-1 	; Skip over the switch keyword
	 or	 [bp].FCNSYM_FLAG,@FCNSYM_XL ; Mark as present

	 jmp	 short FCN_LOADSYM_NEXTSW ; Go around again

FCN_LOADSYM_XXL:

; Unrecognizable switch

	 dec	 si		; Back off to original character

	 jmp	 FCN_LOADSYM_SWERR ; Join common error code

FCN_LOADSYM_XSW:
	 cmp	 [bp].FCNSYM_FH,-1 ; Is there a symbol file name?
	 je	 near ptr FCN_LOADSYM_CLC ; Jump if not

	 REGSAVE <ds>		; Save for a moment

	 push	 seg DGROUP	; Address DGROUP
	 pop	 ds		; Setup DS for READF2
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 cx,size SSF_STR ; Read in SSF file header
	 DOSCALL @READF2,SYM_READBUF ; Read file header into static I/O buffer

	 REGREST <ds>		; Restore
	 assume  ds:nothing	; Tell the assembler about it
	 jc	 near ptr FCN_LOADSYM_READERR ; Something went wrong

	 cmp	 ax,cx		; Did we read in the whole header?
	 jb	 near ptr FCN_LOADSYM_SYMERR ; Can't be an SSF file

	 cmp	 SYM_READBUF.SSF_SIG,@SSF_SIG ; Check for signature
	 jne	 near ptr FCN_LOADSYM_SYMERR ; Jump if not a valid SSF header

	 mov	 eax,SYM_READBUF.SSF_COUNT ; Get number of records in file
	 mov	 EXTSYM_COUNT,eax ; Save for processing later

	 cmp	 SYM_READBUF.SSF_VER,@SSF_CVER ; Izit the minimum version
				; supporting SSF_FLAGS and SSF_DATA?
	 jnb	 short @F	; Jump if so

	 mov	 SYM_READBUF.SSF_FLAGS,0 ; Simulate all flags 0
	 mov	 SYM_READBUF.SSF_DATA,@SSF_OLDDATA ; Pre-0.11 version uses
				; a fixed data offset of 0ah

@@:

; If there's an XMS manager present, use it to allocate memory to hold
; the symbol data.  To this end, we need to know the size of the symbol
; file which we get from the file size less the offset to data portion.

	 mov	 ax,seg RGROUP	; Get segment of RGROUP
	 mov	 gs,ax		; Address it
	 assume  gs:RGROUP	; Tell the assembler about it

	 test	 DEV_FLAG,@DEV_XMS ; Is there an XMS driver present?
	 jz	 near ptr FCN_LOADSYM_NOVCPI1 ; Jump if not

	 xor	 cx,cx		; Set offset in CX:DX to 0:0
	 xor	 dx,dx		; ...
	 mov	 bx,[bp].FCNSYM_FH ; Get file handle
	 mov	 al,2		; Method number for offset from EOF
	 DOSCALL @MOVFP2	; Return new offset in DX:AX
	 jc	 near ptr FCN_LOADSYM_READERR ; Jump if failed

	 sub	 ax,SYM_READBUF.SSF_DATA.ELO ; Less low order word for seek
	 sbb	 dx,SYM_READBUF.SSF_DATA.EHI ; Less high ...

	 shl	 edx,16 	; Shift to high-order word
	 mov	 dx,ax		; Copy low-order word
	 call	 ALLOC_XMS	; Allocate EDX bytes of XMS memory
				; returning EAX = base physical address
				;	    CX = handle
	 jc	 near ptr FCN_LOADSYM_XMSERR ; Jump if something went wrong

	 test	 DEV_FLAG,@DEV_XMS ; Did we fail trying XMS?
	 jz	 near ptr FCN_LOADSYM_XMSERR ; Jump if something went wrong

	 mov	 EXTSYM_OFF,eax ; Save as new physical base address
	 mov	 SYM_XMSHNDL,cx ; Save for later use
	 mov	 [bp].FCNSYM_XMBMOVE.XMBMOVE_DHNDL,cx ; Save as destin handle
	 mov	 [bp].FCNSYM_XMBMOVE.XMBMOVE_DOFF,0 ; Initialize destin offset
	 mov	 [bp].FCNSYM_XMBMOVE.XMBMOVE_SHNDL,0 ; Save as source handle
				; meaning it's in the first megabyte
FCN_LOADSYM_NOVCPI1:
	 mov	 cx,SYM_READBUF.SSF_DATA.EHI ; Get high order word for seek
	 mov	 dx,SYM_READBUF.SSF_DATA.ELO ; Get low order word for seek
	 mov	 bx,[bp].FCNSYM_FH ; Get file handle
	 mov	 al,0		; Seek from start of file
	 DOSCALL @MOVFP2	; Return new offset in DX:AX
	 jc	 near ptr FCN_LOADSYM_READERR ; Jump if failed

; Set SYMAPPND_MODE now; it will be referenced at INIT_PROT time inside
; SYMAPPND_COM.
	 mov	 SYMAPPND_MODE,0 ; Assume normal append mode
	 test	 SYM_READBUF.SSF_FLAGS,@SSFFL_RAW ; Was raw append specified?
	 jz	 short @F	; Jump if not

	 mov	 SYMAPPND_MODE,1 ; Append symbols raw (allow dupes)
@@:
	 mov	 EXTSYM_CHKSUM,0 ; Prepare to calculate checksum

; Set up GDT for BIOS block move

	 mov	 ax,seg DGROUP	; Get real mode segment of SYM_READBUF
	 movzx	 eax,ax 	; Clear high word
	 shl	 eax,4-0	; Convert from paras to bytes
	 add	 eax,offset DGROUP:SYM_READBUF ; Add offset
	 mov	 [bp].FCNSYM_GDT.MDTE_DS.DESC_BASE01,ax ; Low order 16 bits of base
	 shr	 eax,16 	; Get high order 16 bits of base
	 mov	 [bp].FCNSYM_GDT.MDTE_DS.DESC_BASE2,al ; Base 16-23
	 mov	 [bp].FCNSYM_GDT.MDTE_DS.DESC_BASE3,ah ; Base 24-31
	 mov	 [bp].FCNSYM_GDT.MDTE_DS.DESC_ACCESS,CPL0_DATA ; Set ARB
	 mov	 [bp].FCNSYM_GDT.MDTE_DS.DESC_SEGLM0,@SYM_READBUFSIZ-1 ; Size of source in bytes
	 mov	 [bp].FCNSYM_GDT.MDTE_DS.DESC_SEGLM1,0 ; Clear flags and high 4 bits of limit

	 mov	 eax,EXTSYM_OFF ; 1MB + 64K
	 mov	 [bp].FCNSYM_GDT.MDTE_ES.DESC_BASE01,ax ; Low order 16 bits of base
	 shr	 eax,16 	; Get high order 16 bits of base
	 mov	 [bp].FCNSYM_GDT.MDTE_ES.DESC_BASE2,al ; Base 16-23
	 mov	 [bp].FCNSYM_GDT.MDTE_ES.DESC_BASE3,ah ; Base 24-31
	 mov	 [bp].FCNSYM_GDT.MDTE_ES.DESC_ACCESS,CPL0_DATA ; Set ARB
	 mov	 [bp].FCNSYM_GDT.MDTE_ES.DESC_SEGLM0,@SYM_READBUFSIZ-1 ; Size of destination in bytes
	 mov	 [bp].FCNSYM_GDT.MDTE_ES.DESC_SEGLM1,0 ; Clear flags and high 4 bits of limit

; Initialize the BIOS-reserved fields to zero

	 xor	 eax,eax	; A convenient zero
	 mov	 [bp].FCNSYM_GDT.MDTE_GDT.EDQLO,eax ; Set to zero
	 mov	 [bp].FCNSYM_GDT.MDTE_GDT.EDQHI,eax ; ...
	 mov	 [bp].FCNSYM_GDT.MDTE_BIOS.EDQLO,eax ; ...
	 mov	 [bp].FCNSYM_GDT.MDTE_BIOS.EDQHI,eax ; ...
	 mov	 [bp].FCNSYM_GDT.MDTE_SS.EDQLO,eax ; ...
	 mov	 [bp].FCNSYM_GDT.MDTE_SS.EDQHI,eax ; ...
FCNSYM_READBLOCK:
	 lea	 dx,SYM_READBUF ; Address start of buffer
	 mov	 cx,@SYM_READBUFSIZ ; Try to read the whole thing

	 REGSAVE <ds>		; Save
	 push	 seg DGROUP	; Get DATA segment
	 pop	 ds		; Prepare to address DGROUP
	 assume  ds:DGROUP	; Tell the assembler

	 mov	 [bp].FCNSYM_XMBMOVE.XMBMOVE_SOFF.VOFF,dx ; Save as source offset
	 mov	 [bp].FCNSYM_XMBMOVE.XMBMOVE_SOFF.VSEG,ds ; ... 	   segment

	 mov	 bx,[bp].FCNSYM_FH ; Get file handle
	 DOSCALL @READF2	; Read CX bytes into DS:DX

	 REGREST <ds>		; Restore
	 assume  ds:nothing	; Tell the assembler
	 jc	 near ptr FCN_LOADSYM_READERR ; Jump if read failed

	 or	 ax,ax		; Did we read 0 bytes?
	 jz	 near ptr FCN_LOADSYM_CLC ; Jump if so

	 inc	 ax		; Round up
	 and	 ax,not 1	; Ensure it ends on a word boundary

	 movzx	 eax,ax 	; Clear high order word
	 add	 EXTSYM_LEN,eax ; Add to total length in bytes
	 mov	 [bp].FCNSYM_XMBMOVE.XMBMOVE_LEN,eax ; Save as move length

	 mov	 cx,ax		; Number of bytes to checksum
	 mov	 [bp].FCNSYM_BSIZE,ax ; Save size of block

	 push	 si		; Save for a moment

	 lea	 si,SYM_READBUF ; Area to checksum
	 sub	 eax,eax	; Clear high order bytes of dword
@@:
	 lods	 SYM_READBUF[si] ; Get byte
	 add	 EXTSYM_CHKSUM,eax ; Update checksum
	 LOOPS	 @B		; Repeat

	 pop	 si		; Restore

; Use BIOS block move to move it out to extended memory
; unless there's an XMS manager present in which case we use
; XMS block move.

	 test	 DEV_FLAG,@DEV_XMS ; Is there an XMS driver present?
	 jz	 short FCN_LOADSYM_NOVCPI2 ; Jump if not

	 REGSAVE <si,ds>	; Save for a moment

	 push	 ss		; Prepare to address XMS block move in local area
	 pop	 ds		; Use DS
	 assume  ds:nothing	; Tell the assembler
	 lea	 si,[bp].FCNSYM_XMBMOVE ; Address XMS block move struc

	 mov	 ah,@XMS_MOVXMB ; Function code for block move using DS:SI
	 call	 XMSDRV_VEC	; Request XMS service
				; Return with AX = 1 if successful
	 REGREST <ds,si>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 cmp	 ax,1		; Did it work?
	 jne	 short FCN_LOADSYM_XMSMOV ; Jump if not

	 jmp	 short FCN_LOADSYM_COM ; Join common code

FCN_LOADSYM_NOVCPI2:
	 REGSAVE <si,es>	; Save

	 mov	 cx,[bp].FCNSYM_BSIZE ; Bytes in blocks
	 shr	 cx,1		; Convert to words
	 push	 ss		; Prepare to address GDT in local area
	 pop	 es		; Use ES
	 assume  es:nothing	; Tell the assembler
	 lea	 si,[bp].FCNSYM_GDT ; Address GDT

	 REGSAVE <fs,gs>	; Save (destroyed by some PS/2's)

	 mov	 ah,87h 	; BIOS block move
	 int	 15h		; Move CX words from 18|0 to 10|0

	 REGREST <gs,fs>	; Restore

	 REGREST <es,si>	; Restore
	 assume  es:NGROUP	; Tell the assembler

	 jc	 short FCN_LOADSYM_SYMEXT ; Block move failed

; Adjust base in temporary GDT to point to next block

FCN_LOADSYM_COM:
	 movzx	 eax,[bp].FCNSYM_BSIZE ; Get block size in bytes
	 add	 [bp].FCNSYM_GDT.MDTE_ES.DESC_BASE01,ax ; Bump low 16 bits of base
	 adc	 [bp].FCNSYM_GDT.MDTE_ES.DESC_BASE2,0 ; Adjust bits 16-23
	 adc	 [bp].FCNSYM_GDT.MDTE_ES.DESC_BASE3,0 ; Adjust bits 24-31

	 add	 [bp].FCNSYM_XMBMOVE.XMBMOVE_DOFF,eax ; Skip to next destin offset

	 jmp	 FCNSYM_READBLOCK ; Read another 4K block in

FCN_LOADSYM_XMSERR:
	 push	 offset cs:MSG_SYMXMS ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em file was not an SSF file

	 jmp	 short FCN_LOADSYM_ERR ; Join common tail code

FCN_LOADSYM_XMSMOV:
	 push	 offset cs:MSG_SYMXMSMOV ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em file was not an SSF file

	 jmp	 short FCN_LOADSYM_ERR ; Join common tail code

FCN_LOADSYM_VDSERR:
	 push	 offset cs:MSG_SYMVDS ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em file was not an SSF file

	 jmp	 short FCN_LOADSYM_ERR ; Join common tail code

FCN_LOADSYM_SYMERR:
	 push	 offset cs:MSG_SYMFMT ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em file was not an SSF file

	 jmp	 short FCN_LOADSYM_ERR ; Join common tail code

FCN_LOADSYM_OPENERR:
FCN_LOADSYM_READERR:
	 push	 offset cs:MSG_SYMOPEN ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we couldn't read the file

	 jmp	 short FCN_LOADSYM_ERR ; Join common tail code

FCN_LOADSYM_SYMEXT:
	 push	 offset cs:MSG_SYMEXT ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we couldn't move it into
				; extended memory

	 jmp	 short FCN_LOADSYM_ERR ; Join common tail code

FCN_LOADSYM_SWERR:
	 push	 offset cs:MSG_SYMSW ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we couldn't read their handwriting

	 jmp	 short FCN_LOADSYM_ERR ; Join common tail code

FCN_LOADSYM_CLC:

; Unless we're told not to, ensure that SYMSIZE is at least as
; big as EXTSYM_LEN.

	 test	 [bp].FCNSYM_FLAG,@FCNSYM_XL ; Izit present?
	 jnz	 short @F	; Jump if so

; The actual SYMSIZE is EXTSYM_LEN plus the # symbols times the
; difference between the storage and incoming structures

	 imul	 eax,EXTSYM_COUNT,(type SYM_STR) - (type SYMC_STR)
	 add	 eax,EXTSYM_LEN ; Plus symbol size for this file

	 cmp	 eax,SYMSIZE	; Izit bigger?
	 jbe	 short @F	; Jump if not

	 mov	 SYMSIZE,eax	; Save as the larger
@@:
	 clc			; Indicate success

	 jmp	 short FCN_LOADSYM_EXIT ; Join common exit code

FCN_LOADSYM_EQ:
	 push	 offset cs:MSG_SEP ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we allow no mistakes
FCN_LOADSYM_ERR:
	 mov	 EXTSYM_LEN,0	; Indicate there are no symbols loaded
	 stc			; Indicate there was a problem
FCN_LOADSYM_EXIT:
	 pushf			; Save flags

	 mov	 bx,[bp].FCNSYM_FH ; Get file handle
	 cmp	 bx,-1		; Was it ever opened?
	 je	 short @F	; Jump if so

	 DOSCALL @CLOSF2	; Close it up
				; Ignore error return

@@:
	 call	 REST24 	; Restore INT 24h handler

	 popf			; Restore saved flags

	 pop	 OLDINT24_VEC	; Restore

	 lea	 esp,[esp+size FCNSYM_LCL] ; Strip local storage from stack
				; (Flags remain intact)

	 REGREST <gs,es,ebp,edx,ecx,ebx,eax> ; Restore
	 assume  es:nothing,gs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_LOADSYM endp		; End FCN_LOADSYM procedure
	NPPROC	FCN_SYMFILTER -- SYMFILTER Function
	assume	ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

SYMFILTER function.

On entry:

DS:ESI	==>	command line following keyword

On exit:

DS:ESI	==>	next character to scan

|

	REGSAVE <eax,ecx,edi,es> ; Save registers

	mov	ax,fs		; Get segment of SYMFILTER_xxx variables
	mov	es,ax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	call	SKIP_WHITE	; Skip over more white space

	cmp	al,'='          ; Must be
	jne	short FCN_SYMFILTER_EQ ; Too bad

	inc	si		; Skip over the character

	call	SKIP_WHITE	; Skip over more white space

	cmp	al,0		; Izit EOL?
	je	short FCN_SYMFILTER_CLR ; Jump if so (clear the list)
FCN_SYMFILTER_NEXT:
	call	SKIP_WHITE	; Skip over more white space

; Calculate the length of the filter

	push	si		; Save for a moment

	mov	cx,-1		; Intialize counter
@@:
	lods	ds:[si].LO	; Get the next byte
	inc	cx		; Count it in

	cmp	al,' '          ; Izit EOS?
	je	short @F	; Jump if so

	cmp	al,TAB		; Izit EOS?
	je	short @F	; Jump if so

	cmp	al,0		; Izit EOS?
	jne	short @B	; Jump if not
@@:
	pop	si		; Restore

	mov	ax,cx		; Copy the length
	inc	ax		; Count in the length byte

	cmp	ax,SYMFILTER_END.ELO ; Izit too large?
	ja	short FCN_SYMFILTER_ERR ; Jump if so

	mov	di,SYMFILTER_NXT.ELO ; Get the next available offset
	mov	al,cl		; Copy the byte length
	stos	SYMFILTER_TAB[di].LO ; Save in table

S16 rep movs	<SYMFILTER_TAB[di],ds:[si].LO> ; Copy the text

	mov	SYMFILTER_NXT.ELO,di ; Save for next time

	jmp	FCN_SYMFILTER_NEXT ; Go around again


FCN_SYMFILTER_CLC:
	clc			; Indicate all went well

	jmp	short FCN_SYMFILTER_EXIT ; Join common exit code

FCN_SYMFILTER_CLR:
	mov	SYMFILTER_NXT,offset DGROUP:SYMFILTER_TAB ; Start all over again

	jmp	short FCN_SYMFILTER_CLC ; Join common OK code

FCN_SYMFILTER_EQ:
	push	offset cs:MSG_SEP ; Pass address of error message
	call	DISP_MSG	; Tell 'em we allow no mistakes
FCN_SYMFILTER_ERR:
	stc			; Indicate there was a problem
FCN_SYMFILTER_EXIT:
	REGREST <es,edi,ecx,eax> ; Restore
	assume	es:NGROUP	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_SYMFILTER endp		; End FCN_SYMFILTER procedure
	 NPPROC  FCN_SYMSIZE -- SYMSIZE Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

SYMSIZE function.

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 REGSAVE <eax,ecx,edi>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_SYMSIZE_EQ ; Too bad

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 mov	 ecx,10 	; Use base 10 to convert
	 call	 U16_BASE2BIN	; Convert the number at DS:ESI to binary in EAX
	 jc	 short FCN_SYMSIZE_OVF ; Jump if too large

	 cmp	 eax,SYMSIZE	; Izit bigger?
	 jbe	 short @F	; Jump if not

	 mov	 SYMSIZE,eax	; Save for later use
@@:
	 clc			; Indicate all went well

	 jmp	 short FCN_SYMSIZE_EXIT ; Join common exit code

FCN_SYMSIZE_OVF:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 lea	 di,MSG_OVF	; Pass address of error message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 jmp	 short FCN_SYMSIZE_ERR ; Join common error code

FCN_SYMSIZE_EQ:
	 push	 offset cs:MSG_SEP ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we allow no mistakes
FCN_SYMSIZE_ERR:
	 stc			; Indicate there was a problem
FCN_SYMSIZE_EXIT:
	 REGREST <edi,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_SYMSIZE endp		; End FCN_SYMSIZE procedure
	 NPPROC  FCN_TRAPBOUND -- TRAPBOUND Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

TRAPBOUND function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 ARG_FLAG,@ARG_BOUND ; Mark as trapping bound instructions

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_TRAPBOUND endp		; End FCN_TRAPBOUND procedure
	 NPPROC  FCN_TRAPDEBUG -- TRAPDEBUG Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

TRAPDEBUG function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 ARG_FLAG,@ARG_STEP or @ARG_SKIP ; Mark as swapping INT 01h/03h
				; during initialization
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_TRAPDEBUG endp		; End FCN_TRAPDEBUG procedure
	 NPPROC  FCN_TRAPDIV -- TRAPDIV Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

TRAPDIV function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 ARG_FLAG,@ARG_DIVO ; Mark as trapping divide overflow

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_TRAPDIV endp		; End FCN_TRAPDIV procedure
	 NPPROC  FCN_TRAPGENP -- TRAPGENP Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

TRAPGENP function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 ARG_FLAG,@ARG_GENP ; Mark as trapping GP Faults

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_TRAPGENP endp		; End FCN_TRAPGENP procedure
	 NPPROC  FCN_TRAPINV -- TRAPINV Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

TRAPINV function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 ARG_FLAG,@ARG_INV ; Mark as trapping invalid opcodes

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_TRAPINV endp		; End FCN_TRAPINV procedure
	 NPPROC  FCN_TRAPNMI -- TRAPNMI Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

TRAPNMI function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 ARG_FLAG,@ARG_NMI ; Mark as trapping NMIs

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_TRAPNMI endp		; End FCN_TRAPNMI procedure
	 NPPROC  FCN_TRAPPAGE -- TRAPPAGE Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

TRAPGENP function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 ARG_FLAG,@ARG_PAGE ; Mark as trapping Page Faults

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_TRAPPAGE endp		; End FCN_TRAPPAGE procedure
	 NPPROC  FCN_TRAPSEGNP -- TRAPSEGNP Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

TRAPSEGNP function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 ARG_FLAG,@ARG_SEGNP ; Mark as trapping Segment Not Present faules

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_TRAPSEGNP endp		; End FCN_TRAPSEGNP procedure
	 NPPROC  FCN_TRAPSKIP -- TRAPSKIP Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

TRAPSKIP function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 ARG_FLAG,@ARG_SKIP ; Mark as swapping INT 03h during initialization

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_TRAPSKIP endp		; End FCN_TRAPSKIP procedure
	 NPPROC  FCN_TRAPSTACK -- TRAPSTACK Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

TRAPSTACK function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 AR2_FLAG,@AR2_STACK ; Mark as trapping Stack Faults

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_TRAPSTACK endp		; End FCN_TRAPSTACK procedure
	 NPPROC  FCN_TRAPSTEP -- TRAPSTEP Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

TRAPSTEP function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 ARG_FLAG,@ARG_STEP ; Mark as swapping INT 01h during initialization

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_TRAPSTEP endp		; End FCN_TRAPSTEP procedure
	 NPPROC  FCN_TRAPTSS -- TRAPTSS Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

TRAPTSS function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 or	 AR2_FLAG,@AR2_TSS ; Mark as swapping INT 0Ah during initialization

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_TRAPTSS endp		; End FCN_TRAPTSS procedure
% ifidni <OEM>,<BET>
	 NPPROC  FCN_VCPISWAT -- VCPISWAT Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

VCPISWAT function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 push	 ds		; Save for a moment

	 push	 seg RGROUP	; Get segment of DEV_FLAG
	 pop	 ds		; Address it
	 assume  ds:RGROUP	; Tell the assembler about it

	 test	 DEV_FLAG,@DEV_VCPI ; Are we using VCPI services?
	 jz	 short FCN_VCPISWAT_EXIT ; Jump if not

	 and	 DEV_FLAG,not @DEV_INTRUDE ; Mark as INTRUDE not present

	 push	 seg PGROUP	; Get segment of DEVLOAD
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 and	 DEVLOAD,not @DEVL_INTRUDE ; Mark as INTRUDE not present

	 and	 DBG_FLAG,not @DBG_IBV ; Mark as not setting Ctrl-Alt-PAD5 IRQ1
				; to IBV value
FCN_VCPISWAT_EXIT:
	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_VCPISWAT endp		; End FCN_VCPISWAT procedure
endif				; IFIDNI <OEM>,<BET>
	 NPPROC  FCN_VIDEO -- VIDEO=d:\path\filename.ext Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

VIDEO=d:\path\filename.ext function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 push	 OLDINT24_VEC	; Save old value so we're recursive
	 call	 INST24 	; Install local INT 24h handler

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 near ptr FCN_VIDEO_EQ ; Too bad

	 inc	 si		; Skip over the character
	 mov	 dx,si		; Save as start of video table fid

; Search for end of filename

@@:
	 lods	 ds:[si].LO	; Get next character

	 cmp	 al,' '         ; Too small for filename?
	 ja	 short @B	; No, go around again

	 dec	 si		; Back off to terminator

; Attempt to open the file

	 mov	 cl,0		; String terminator
	 xchg	 cl,[si]	; Terminate filename.ext
	 mov	 al,0		; Access code for read-only
	 stc			; Assume error
	 DOSCALL @OPENF2	; Open it
	 xchg	 cl,[si]	; Restore filename.ext
	 jc	 short FCN_VIDEO_OPEN ; Something went wrong

	 mov	 bx,ax		; Copy to file handle register

	 REGSAVE <ds>		; Save for a moment

	 mov	 ds,MAPSEG_NXT	; Setup DS for OPENF2
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 VIDEO_SEG,ds	; Save for later use

	 xor	 dx,dx		; DS:DX ==> video table segment
	 mov	 cx,0FFFFh	; Read in all of it

	 stc			; Assume error
	 DOSCALL @READF2	; Read it in

	 mov	 VIDEO_CNT,ax	; Save # bytes read

	 REGREST <ds>		; Restore
	 assume  ds:nothing	; Tell the assembler about it
	 jc	 short FCN_VIDEO_READERR ; Something went wrong
FCN_VIDEO_CLOSE:
	 add	 ax,16-1	; Round up to para boundary
	 shr	 ax,4-0 	; Convert from bytes to paras
	 add	 MAPSEG_NXT,ax	; Skip over video table segment

	 push	 offset NGROUP:MEMERR_VIDEO ; Pass offset of error message
	 call	 CHECK_NXTSEG	; Ensure we've enough room

	 or	 ARG_FLAG,@ARG_FVM ; Mark as present

;;;;;;;; stc			; Assume error
	 DOSCALL @CLOSF2	; Close it up
				; Ignore error return

	 clc			; Mark as successful

	 jmp	 short FCN_VIDEO_EXIT ; Join common tail code

COMMENT|

Unable to open the video table file
Instead create one in the named file

On entry:

DS:ESI	 ==>	 next byte after d:\path\filename.ext


|

FCN_VIDEO_OPEN:
	 mov	 bl,0		; String terminator
	 xchg	 bl,[si]	; Terminate filename.ext
	 mov	 cx,DIR_ATTR_NORM ; Access code for normal file
	 stc			; Assume error
	 DOSCALL @CREAF2	; Create it
	 xchg	 bl,[si]	; Restore filename.ext
	 jc	 short FCN_VIDEO_OPENERR ; Jump if we failed

	 mov	 bx,ax		; Copy to file handle register

	 mov	 ax,MAPSEG_NXT	; Setup DS for OPENF2
	 mov	 VIDEO_SEG,ax	; Save for later use

	 call	 FINDVID	; Find video modes, fill in VIDEO_CNT

; Write out the new file contents (we're assuming it's < 64KB)

	 push	 ds		; Save for a moment
	 mov	 cx,VIDEO_CNT	; Get # bytes to write
	 mov	 ds,VIDEO_SEG	; Get video table segment
	 assume  ds:nothing	; Tell the assembler about it
	 xor	 dx,dx		; DS:DX ==> write buffer
	 stc			; Assume error
	 DOSCALL @WRITF2	; Write it out
	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it
	 jnc	 short FCN_VIDEO_CLOSE ; Join common code code

; Error writing video table file

	 push	 offset cs:MSG_VWRIT ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we couldn't read the file

	 jmp	 short FCN_VIDEO_ERR ; Join common tail code

FCN_VIDEO_OPENERR:
	 push	 offset cs:MSG_VOPEN ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we couldn't read the file

	 jmp	 short FCN_VIDEO_ERR ; Join common tail code

FCN_VIDEO_READERR:
	 push	 offset cs:MSG_VREAD ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we couldn't read the file

	 jmp	 short FCN_VIDEO_ERR ; Join common tail code

FCN_VIDEO_EQ:
	 push	 offset cs:MSG_SEP ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we allow no mistakes
FCN_VIDEO_ERR:
	 mov	 VIDEO_SEG,0	; Zero the segment

	 stc			; Indicate there was a problem
FCN_VIDEO_EXIT:
	 pushf			; Save flags
	 call	 REST24 	; Restore INT 24h handler
	 popf			; Restore
	 pop	 OLDINT24_VEC	; Restore

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_VIDEO endp			; End FCN_VIDEO procedure
	 NPPROC  FCN_VMSCOUNT -- VMSCOUNT=n Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

VMSCOUNT=n function

n is a non-zero integer specifying the number of times we should
insinuate ourselves into the GDT when VMSINT is specified.  Some
VCPI interrupt handlers call the VCPI DE01 (get PMI) function
continuously, quickly causing the GDT to overflow.

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 REGSAVE <eax,di>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Izit present?
	 jne	 short FCN_VMSCOUNT_ARG ; Jump if not

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,CR		; Izit EOL?
	 je	 short FCN_VMSCOUNT_UNK ; Jump if so

	 call	 U16_HEX2DD	; Convert DS:ESI from hex to binary EAX
	 jc	 short FCN_VMSCOUNT_OVF ; Jump if too large

	 cmp	 eax,0FFFFh	; Check for within 16-bit range
	 ja	 short FCN_VMSCOUNT_OVF ; Jump if too large

	 or	 ax,ax		; Izit 0?
	 jz	 short FCN_VMSCOUNT_UNK ; Jump if so (invalid)

	 mov	 VMSCOUNT,ax	; Initialize count

	 or	 DBG_FLAG,@DBG_VCNT ; Mark as using VMSCOUNT

	 clc			; Mark as successful

	 jmp	 short FCN_VMSCOUNT_EXIT ; Join common exit code

FCN_VMSCOUNT_UNK:
	 lea	 di,MSG_UNK	; Address of error message
	 jmp	 short FCN_VMSCOUNT_ERR ; Join common error code

FCN_VMSCOUNT_ARG:
	 lea	 di,MSG_SEP	; Address of error message
	 jmp	 short FCN_VMSCOUNT_ERR ; Join common error code

FCN_VMSCOUNT_OVF:
	 lea	 di,MSG_OVF	; Pass address of error message

FCN_VMSCOUNT_ERR:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 stc			; Indicate there was a problem
FCN_VMSCOUNT_EXIT:
	 REGREST <di,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_VMSCOUNT endp		; End FCN_VMSCOUNT procedure
	 NPPROC  FCN_VMSINT -- VMSINT=nn,nn,... Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

VMSINT=nn,nn,... function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 REGSAVE <eax,ebx,di>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Izit present?
	 jne	 short FCN_VMSINT_CLC ; Jump if not (use default VMSINT_TAB)

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 xor	 ebx,ebx	; Initialize index into VMSINT_TAB

	 cmp	 al,CR		; Izit EOL?
	 je	 short FCN_VMSINT_EOL ; Jump if so
FCN_VMSINT_NEXT:
	 call	 U16_HEX2DD	; Convert DS:ESI from hex to binary EAX
	 jc	 short FCN_VMSINT_OVF ; Jump if too large

	 cmp	 eax,0FFh	; Check for within 8-bit range
	 ja	 short FCN_VMSINT_OVF ; Jump if too large

	 mov	 VMSINT_TAB[ebx],al ; Save in VMS interrupt table
	 inc	 ebx		; Skip to next entry

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,','         ; Izit entry separator?
	 jne	 short FCN_VMSINT_EOL ; Jump if not

	 inc	 si		; Skip over the separator

	 call	 SKIP_WHITE	; Skip over more white space

	 jmp	 short FCN_VMSINT_NEXT ; Go around again

FCN_VMSINT_EOL:
	 mov	 VMSINT_LEN,bl	; Save as VMS interrupt table length
FCN_VMSINT_CLC:
	 or	 DBG_FLAG,@DBG_VMS ; Mark as debugging VM86 Mode Switches

	 clc			; Mark as successful

	 jmp	 short FCN_VMSINT_EXIT ; Join common exit code

FCN_VMSINT_OVF:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 lea	 di,MSG_OVF	; Pass address of error message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 stc			; Indicate there was a problem
FCN_VMSINT_EXIT:
	 REGREST <di,ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_VMSINT endp 		; End FCN_VMSINT procedure
	 NPPROC  FCN_WATCHDOG -- WATCHDOG=nn Function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

WATCHDOG=nn function

On entry:

DS:ESI	 ==>	 command line following keyword

On exit:

DS:ESI	 ==>	 next character to scan

|

	 REGSAVE <eax,di>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_WATCHDOG_EQ ; Too bad

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 call	 U16_HEX2DD	; Convert DS:ESI from hex to binary EAX
	 jc	 short FCN_WATCHDOG_OVF ; Jump if too large

	 cmp	 eax,000FFh	; Check for within 8-bit range
	 ja	 short FCN_WATCHDOG_OVF ; Jump if too large

	 mov	 WATCHDOG,al	; Save for later use

	 clc			; Indicate all went well

	 jmp	 short FCN_WATCHDOG_EXIT ; Join common exit code

FCN_WATCHDOG_OVF:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 lea	 di,MSG_OVF	; Pass address of error message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 jmp	 short FCN_WATCHDOG_ERR ; Join common error code

FCN_WATCHDOG_EQ:
	 push	 offset cs:MSG_SEP ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we allow no mistakes
FCN_WATCHDOG_ERR:
	 stc			; Indicate there was a problem
FCN_WATCHDOG_EXIT:
	 REGREST <di,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_WATCHDOG endp		; End FCN_WATCHDOG procedure
	NPPROC	FCN_WKDLS -- WKDLS=nn Function
	assume	ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

WKDLS=nn function

On entry:

DS:ESI	==>	command line following keyword

On exit:

DS:ESI	==>	next character to scan

|

	REGSAVE <eax,ecx,di>	; Save registers

	call	SKIP_WHITE	; Skip over more white space

	cmp	al,'='          ; Must be
	jne	short FCN_WKDLS_EQ ; Too bad

	inc	si		; Skip over the character

	call	SKIP_WHITE	; Skip over more white space

	mov	ecx,10		; Use base 10 to convert
	call	U16_BASE2BIN	; Convert the number at DS:ESI to binary in EAX
	jc	short FCN_WKDLS_OVF ; Jump if too large

	mov	WKDLS_CNT,eax	; Save for later use

	clc			; Indicate all went well

	jmp	short FCN_WKDLS_EXIT ; Join common exit code

FCN_WKDLS_OVF:
	mov	si,LASTKEY	; Get offset of last keyword
	lea	di,MSG_OVF	; Pass address of error message
	call	DISP_UNK	; Display it along with unknown keyword at DS:SI

	jmp	short FCN_WKDLS_ERR ; Join common error code

FCN_WKDLS_EQ:
	push	offset cs:MSG_SEP ; Pass address of error message
	call	DISP_MSG	; Tell 'em we allow no mistakes
FCN_WKDLS_ERR:
	stc			; Indicate there was a problem
FCN_WKDLS_EXIT:
	REGREST <di,ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_WKDLS endp			; End FCN_WKDLS procedure

NCODE	ends			; End NCODE segment

	MEND			; End SWAT_FCN module
