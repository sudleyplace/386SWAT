;' $Header:   P:/PVCS/386SWAT/SWAT_WGH.ASV   1.0   10 Aug 1998 11:02:48   BOB  $
	title	SWAT_WGH-- 386SWAT WGH Display Functions
	page	58,122
	name	SWAT_WGH

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-2003 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, August, 1995.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include WINSTR.INC
	include ALLMEM.INC
	include MAXDEV.INC
	include WINDOWS.INC
	include WKD.INC

	include SWAT_CMD.INC
	include SWAT_COM.INC
	include SWAT_MOD.INC
	include SWAT_SEG.INC
.list

DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	extrn	COMMON:tbyte
	include SWAT_FIL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	TTLATTR:byte
	extrn	DEFATTR:byte

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	@SWAT_WGH_DATA
@SWAT_WGH_DATA label byte	; Mark module start in .MAP file

	extrn	MSGOFF:dword
	extrn	SYNTERR:byte
	extrn	INITERR:byte
	extrn	SELERR:byte
	extrn	NOWINERR:byte
	extrn	VNFERR:byte
	extrn	SCROFF:dword

	extrn	MEMMASK:dword
	extrn	MEMMODE:word
	extrn	MEMBASE:dword
	extrn	MEMOFF:dword

	extrn	WGHNDX:dword
	extrn	KVARS_VEC:dword
;;;;;;; extrn	REENTRY:word

	public	WGHBASE
WGHBASE dd	?		; WGH base

	public	SGH_VAL
SGH_VAL dd	?		; Search WGH value

	public	TDBSEL,MDBSEL
TDBSEL	dw	?		; TDB selector
MDBSEL	dw	?		; Module selector

	public	MSG_WGH
MSG_WGH db	'WGH='
MSG_WGH1 db	    'xxxx³   Base      Size    Hndl  Ownr  Name',0
;;;;;;; db	'xxxxxxxx³ xxxxxxxx  xxxxxxxx  xxxx  xxxx  ________',0

	public	MSG_WGHFREE,MSG_WGHUNKOWNR
MSG_WGHFREE db	'----  <Free>',0 ; Owner display for free WGH entries
MSG_WGHUNKOWNR db '        ',0  ; ...               unknown owner entries

	public	MSG_WGHTASK,MSG_WGHMODULE,MSG_WGHPSPTASK,MSG_WGHPSPENV
	public	MSG_WGHSENTINEL,MSG_WGHDPMI
MSG_WGHTASK db	   '  Task:      ',0
MSG_WGHMODULE db   '  File:      ',0
MSG_WGHPSPTASK db  '  PSP Task:  ',0
MSG_WGHPSPENV  db  '  PSP Env:   ',0
MSG_WGHSENTINEL db '  <Sentinel>',0
MSG_WGHDPMI db	   '  <DPMI>',0

	public	MSG_WGHOWNR
MSG_WGHOWNR db	80 dup (?)	; Local buffer for WGH owner name

COMMENT|

TDB=xxxx ModName=cccccccc NextTDB=xxxx hInst=xxxx hModule=xxxx ParentTDB=xxxx
PDB=xxxx TDBSig=cc MinVer=xxxx Flag=WIN32 ...
SS:SP=xxxx:xxxx NumEvents=xxxx Priority=xx MsgQueue=xxxx
ErrMode=xxxx (...)
UserSignal=xxxx:xxxx GlobalNotify=xxxx:xxxx
INT00=xxxx:xxxx INT02=xxxx:xxxx INT04=xxxx:xxxx INT06=xxxx:xxxx
INT07=xxxx:xxxx INT3E=xxxx:xxxx INT75=xxxx:xxxx
CompatFlag=xxxxxxxx
TIB=xxxx LaTIB=xxxxxxxx
hTask16=xxxx CodeAlias=xxxx InitDLL=xxxx:xxxx
DTA=xxxx:xxxx CurDrv=xx (c)
CurDir16=..............
CurDir32=...............
........................

|

	public	MSGTDB1
MSGTDB1 db	'TDB='
MSGTDB_TDB db	'xxxx ModName='
MSGTDB_MODNAME db 'cccccccc NextTDB='
MSGTDB_NEXT db	'xxxx hInst='
MSGTDB_DGR db	'xxxx hModule='
MSGTDB_MOD db	'xxxx ParentTDB='
MSGTDB_PARENT db 'xxxx',0
MSGTDB2 db	'PDB='
MSGTDB_PSPSEL db 'xxxx TDBSig='
MSGTDB_SIG db	'cc MinVer='
MSGTDB_MINVER db 'xxxx Flags='
MSGTDB_FLAGS db 'xxxx (',0
MSGTDB3 db	'SS|SP='
MSGTDB_STKVEC db 'xxxx:xxxx NumEvents='
MSGTDB_NEVENTS db 'xxxx Priority='
MSGTDB_PRIORITY db 'xx MsgQueue='
MSGTDB_TMQ db	'xxxx',0
MSGTDB4 db	'ErrMode='
MSGTDB_ERRFL db 'xxxx (',0
MSGTDB5 db	'UserSignal='
MSGTDB_USH db	'xxxx:xxxx GlobalNotify='
MSGTDB_GDNH db	'xxxx:xxxx',0
MSGTDB6 db	'INT00='
MSGTDB_INT00 db 'xxxx:xxxx INT02='
MSGTDB_INT02 db 'xxxx:xxxx INT04='
MSGTDB_INT04 db 'xxxx:xxxx INT06='
MSGTDB_INT06 db 'xxxx:xxxx',0
MSGTDB7 db	'INT07='
MSGTDB_INT07 db 'xxxx:xxxx INT3E='
MSGTDB_INT3E db 'xxxx:xxxx INT75='
MSGTDB_INT75 db 'xxxx:xxxx',0
MSGTDB8 db	'CompatFlag='
MSGTDB_COMPFL db 'xxxxxxxx',0
MSGTDB9 db	'TIB='
MSGTDB_TIBSEL db 'xxxx LaTIB='
MSGTDB_LATDB db 'xxxxxxxx',0
MSGTDB10 db	'hTask16='
MSGTDB_HTASK16 db 'xxxx CodeAlias='
MSGTDB_CSALIAS db 'xxxx InitDLL='
MSGTDB_DLLCHAIN db 'xxxx:xxxx',0
MSGTDB11 db	'DTA='
MSGTDB_DTA db	'xxxx:xxxx CurDrv='
MSGTDB_CURDRV db 'xx ('
MSGTDB_CURDRV2 db 'c)',0
MSGTDB12 db	'CurDir=',0

	public	MSG_FAILCRITICALERRORS,MSG_NOGPFAULTERRORBOX
	public	MSG_NOALIGNMENTFAULTEXCEPT,MSG_NOOPENFILEERRORBOX
MSG_FAILCRITICALERRORS	   db 'FAILCRITICALERRORS ',0
MSG_NOGPFAULTERRORBOX	   db 'NOGPFAULTERRORBOX ',0
MSG_NOALIGNMENTFAULTEXCEPT db 'NOALIGNMENTFAULTEXCEPT ',0
MSG_NOOPENFILEERRORBOX	   db 'NOOPENFILEERRORBOX ',0

	public	MSGTDB_WINOLDAP,MSGTDB_NEWTASK,MSGTDB_WIN32
MSGTDB_WINOLDAP db 'WINOLDAP ',0
MSGTDB_NEWTASK	db 'NEWTASK ',0
MSGTDB_WIN32	db 'WIN32 ',0


COMMENT|

ModSig=NE RefCnt=xxxx npEntry=xxxx NextMod=xxxx npDGRSeg=xxxx npLFI=xxxx
Flags=xxxx ()
LogSegDGROUP=xxxx Init Heap Size=xxxx Init Stack Size=xxxx
Init CS:IP=xxxx:xxxx Init SS:SP=xxxx:xxxx
# Segs=xxxx # ModRefTab=xxxx Size Non-res Names=xxxx npSegTab=xxxx
npRsrcTab=xxxx npResNam=xxxx npModRefTab=xxxx npImpNamTab=xxxx
FileOffset NR Tab=xxxxxxxx
# Moveable entries=xxxx Shift=xxxx TTF=xxxx OSFlags=xx OtherFlags=xx
Unk1=xxxx Unk2=xxxx Unk3=xxxx ExpWinVer=xxxx
RVA PE=xxxxxxxx Base Addr PE=xxxxxxxx Base Addr PE Rsrc=xxxxxxxx

|

	public	MSGMOD
MSGMOD	db	'MODSig=%2s  RefCnt=%04X  npEntry=%04X  NextMod=%04X'
;;;	db	''
;;;	db	''
;;;	db	''
	db	0

	public	MSGMOD1
MSGMOD1 	db 'MODSig='
MSGMOD1_SIG	db 'xx RefCnt='
MSGMOD1_USECNT	db 'xxxx npEntry='
MSGMOD1_NPENTRY db 'xxxx NextMod='
MSGMOD1_NEXT	db 'xxxx npDGRSeg='
MSGMOD1_NPSEGDRP db 'xxxx npLFI='
MSGMOD1_NPLFI	db 'xxxx',0

	public	MSGMOD2
MSGMOD2 	db 'Flags='
MSGMOD2_FLAGS	db 'xxxx (',0

	public	MSGMOD3
MSGMOD3 	db 'LogSegDGROUP='
MSGMOD3_LSEG	db 'xxxx Init Heap Size='
MSGMOD3_IHEAP	db 'xxxx Init Stack Size='
MSGMOD3_ISTACK	db 'xxxx',0

	public	MSGMOD4
MSGMOD4 	db  'Init CS:IP='
MSGMOD4_CSIP	db 'xxxx:xxxx Init SS:IP='
MSGMOD4_SSSP	db 'xxxx:xxxx',0

	public	MSGMOD5
MSGMOD5 	db '# Segs='
MSGMOD5_NSEGS	db 'xxxx # ModRefTab='
MSGMOD5_NMREF	db 'xxxx Size Non-res Names='
MSGMOD5_SNRNT	db 'xxxx npSegTab='
MSGMOD5_NPSEG	db 'xxxx',0

	public	MSGMOD6
MSGMOD6 	db 'npRsrcTab='
MSGMOD6_NPRES	db 'xxxx npResNam='
MSGMOD6_NPRNAM	db 'xxxx npModRefTab='
MSGMOD6_NPMREF	db 'xxxx npImpNamTab='
MSGMOD6_NPINAM	db 'xxxx',0

	public	MSGMOD7
MSGMOD7 	db 'FileOffset NR Tab='
MSGMOD7_ONRNT	db 'xxxxxxxx',0

	public	MSGMOD8
MSGMOD8 	db '# Moveable entries='
MSGMOD8_NMOVE	db 'xxxx Shift='
MSGMOD8_SHIFT	db 'xxxx TTF='
MSGMOD8_TTFNT	db 'xxxx OSFlags='
MSGMOD8_OSFLG	db 'xx OtherFlags='
MSGMOD8_OTHER	db 'xx',0

	public	MSGMOD9
MSGMOD9 	db 'Unk1='
MSGMOD9_SAME1	db 'xxxx Unk2='
MSGMOD9_SAME2	db 'xxxx Unk3='
MSGMOD9_SWAP	db 'xxxx ExpWinVer='
MSGMOD9_EXPWV	db 'xxxx',0

	public	MSGMOD10
MSGMOD10	db 'RVA PE='
MSGMOD10_PE_RVA db 'xxxxxxxx Base Addr PE='
MSGMOD10_PE_BASE db 'xxxxxxxx Base Addr PE Rsrc='
MSGMOD10_PE_RSRC db 'xxxxxxxx',0

	public	MSGMDB_DLL,	MSGMDB_CALL_WEP,	MSGMDB_SELF_LOAD
	public	MSGMDB_TEXTMODE,MSGMDB_FULLSCREEN,	MSGMDB_PRELOAD
	public	MSGMDB_WIN32,	MSGMDB_AUTODATA,	MSGMDB_SINGLEDATA
MSGMDB_DLL	  db 'DLL ',0
MSGMDB_CALL_WEP   db 'CALL_WEP ',0
MSGMDB_SELF_LOAD  db 'SELF_LOAD ',0
MSGMDB_TEXTMODE   db 'TEXTMODE ',0
MSGMDB_FULLSCREEN db 'FULLSCREEN ',0
MSGMDB_PRELOAD	  db 'PRELOAD ',0
MSGMDB_WIN32	  db 'WIN32 ',0
MSGMDB_AUTODATA   db 'AUTODATA ',0
MSGMDB_SINGLEDATA db 'SINGLEDATA ',0

	public	MSGMDB_DATA,MSGMDB_ITERATED,MSGMDB_MOVEABLE
	public	MSGMDB_RELOC,MSGMDB_DISCARD,MSGMDB_32BIT
MSGMDB_DATA	db 'DATA ',0
MSGMDB_ITERATED db 'ITERATED ',0
MSGMDB_MOVEABLE db 'MOVEABLE ',0
MSGMDB_RELOC	db 'RELOC ',0
MSGMDB_DISCARD	db 'DISCARDABLE ',0
MSGMDB_32BIT	db '32BIT ',0

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP,ds:PGROUP

	public	@SWAT_WGH_PROG
@SWAT_WGH_PROG: 		; Mark module start in .MAP file

	extrn	SWATINI:tbyte

	extrn	CMD_WHITE:near

	extrn	INST_OPR0E:near
	extrn	REST_OPR0E:near

	extrn	DISPASCIIZ:near
	extrn	DISPASCLEN:near
	extrn	SEL2BASE:near
	extrn	GETBASE:near
;;;;;;; extrn	GETLBASE:near
	extrn	GETWORD:near
	extrn	GETDWORD:near
	extrn	DISPTXT:near
	extrn	CLEAR_EOL:near
	extrn	CLEAR_EOP:near
	extrn	NEXTLINE:near
;;;;;;; extrn	HDR_PHYS:near
	extrn	HDR_SYMBOL:near

	extrn	DISPHEX4:near

	extrn	BIN2BYTE:near
	extrn	BIN2WORD:near
	extrn	BIN2DWORD:near

	extrn	PARSE_EXPR:near
	extrn	SET_STATE:near

	NPPROC	GetCurMDBSel -- Get Current Module Selector
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get currrent module selector

On exit:

AX	=	current module selector
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <ebx,fs>	; Save registers

	verr	KVARS_VEC.VSEG	; Izit valid?
	jnz	short GetCurMDBSelErr ; Jump if not

	lfs	bx,KVARS_VEC	; FS:BX ==> KVARS_STR
	assume	fs:nothing	; Tell the assembler about it

	mov	ax,fs:[bx].KV_headTDB ; Get head TDB selector

	and	ax,ax		; Izit invalid?
	jz	short GetCurMDBSelErr ; Jump if so

	mov	fs,ax		; Address it
	assume	fs:nothing	; Tell the assembler about it

	mov	ax,fs:[0].TDB_MOD ; Get the module selector

	and	ax,ax		; Izit invalid?
	jnz	short GetCurMDBSelExit ; Jump if not (note CF=0)
GetCurMDBSelErr:
	stc			; Mark as invalid
GetCurMDBSelExit:
	REGREST <fs,ebx>	; Restore
	assume	fs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GetCurMDBSel endp		; End GetCurMDBSel procedure
	NPPROC	CMD_MDB -- Display A Module Database
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display a module database

MDB expr

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	pushad			; Save all EGP registers

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	jz	short CMD_MDB_ERR_NOWIN ; Jump if not

	verr	KVARS_VEC.VSEG	; Izit valid?
	jnz	short CMD_MDB_INITERR ; Jump if not

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	or	al,al		; Izit the end of the line?
	jnz	short CMD_MDB_EXPR ; Jump if not

; Use current module

	call	GetCurMDBSel	; Get current module selector
	jc	short CMD_MDB_ERR_INVSEL ; Jump if invalid

	jmp	short CMD_MDB_COM ; Join common code

CMD_MDB_EXPR:
	call	PARSE_EXPR	; Parse command line for expression
	jc	short CMD_MDB_SYNTERR ; Jump if something went wrong
CMD_MDB_COM:
	mov	MDBSEL,ax	; Save for later use

	mov	al,@DSP_MDB	; Screen state is MDB
	call	SET_STATE	; Set new state

	clc			; Mark as successful

	jmp	short CMD_MDB_EXIT ; Join common exit code


CMD_MDB_ERR_INVSEL:
	mov	MSGOFF,offset DGROUP:SELERR ; Save offset of error message

	jmp    short CMD_MDB_ERRCOM ; Join common code

CMD_MDB_ERR_NOWIN:
	mov	MSGOFF,offset DGROUP:NOWINERR ; Save offset of error message

	jmp    short CMD_MDB_ERRCOM ; Join common code

CMD_MDB_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	jmp	short CMD_MDB_ERRCOM ; Join common error exit code

CMD_MDB_INITERR:
	mov	MSGOFF,offset DGROUP:INITERR ; Save offset of error message

;;;;;;; jmp	short CMD_MDB_ERRCOM ; Join common error exit code

CMD_MDB_ERRCOM:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_MDB_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_MDB endp			; End CMD_MDB procedure
	NPPROC	DISP_MDB -- Display A Module Database
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display a module database

On entry:

MDBSEL	=	selector of module database to display

|

	pushad			; Save all EGP registers

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	jz	near ptr DISP_MDBERR_NOWIN ; Jump if not

	push	MDBSEL		; Pass the selector
	call	GETBASE 	; Return with EAX = selector base
	jc	near ptr DISP_MDBERR_INVSEL ; Jump if invalid selector

	mov	ebx,eax 	; AGROUP:EBX ==> module database

	mov	SCROFF,0	; Start at top of screen

; Display the signature

	mov	ax,AGROUP:[ebx].MOD_MODSIG ; Get the signature
	mov	MSGMOD1_SIG.ELO,ax ; Save to display

; Display the usage count

	mov	ax,AGROUP:[ebx].MOD_USECNT ; Get usage count
	lea	edi,MSGMOD1_USECNT ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display the near ptr to entry table

	mov	ax,AGROUP:[ebx].MOD_NPENTRY ; Get near ptr to entry table
	lea	edi,MSGMOD1_NPENTRY ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display the next module selector

	mov	ax,AGROUP:[ebx].MOD_NEXT ; Get next module selector
	lea	edi,MSGMOD1_NEXT ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display the near ptr to DGROUP segment entry

	mov	ax,AGROUP:[ebx].MOD_NPSEGDRP ; Get near ptr to DGROUP segment entry
	lea	edi,MSGMOD1_NPSEGDRP ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display the near ptr to load file info struc

	mov	ax,AGROUP:[ebx].MOD_NPLFI ; Get near ptr to load file info struc
	lea	edi,MSGMOD1_NPLFI ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display line 1

	lea	esi,MSGMOD1	; Display line 1
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Display flag meanings (line 2)

	xor	ecx,ecx 	; Initialize count of entries displayed
	mov	ax,AGROUP:[ebx].MOD_FLAGS ; Get the flags
	lea	edi,MSGMOD2_FLAGS ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display line 2

	lea	esi,MSGMOD2	; Display line 2
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

MDBF_MAC macro	SUF

	test	ax,MDBF_&SUF	; Izit?
	jz	short @F	; Jump if not

	lea	esi,MSGMDB_&SUF ; DS:ESI ==> ASCIIZ text to display
	call	DISPASCIIZ	; Display ASCIIZ string from ESI
	inc	ecx		; Count in another one
@@:
	endm			; MDBF_MAC

	MDBF_MAC DLL
	MDBF_MAC CALL_WEP
	MDBF_MAC SELF_LOAD
	MDBF_MAC TEXTMODE
	MDBF_MAC FULLSCREEN
	MDBF_MAC PRELOAD
	MDBF_MAC WIN32
	MDBF_MAC AUTODATA
	MDBF_MAC SINGLEDATA

	jecxz	@F		; Jump if no flags active

	sub	SCROFF,2*1	; Back off over last blank
@@:
	mov	al,')'          ; Get right separator
	call	DISPTXT 	; Display byte on screen as text

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Display logical segment # of DGROUP (origin-1)

	mov	ax,AGROUP:[ebx].MOD_LSEG ; Get logical segment # of DGROUP (origin-1)
	lea	edi,MSGMOD3_LSEG ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display initial local heap size

	mov	ax,AGROUP:[ebx].MOD_IHEAP ; Get initial local heap size
	lea	edi,MSGMOD3_IHEAP ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display initial stack size

	mov	ax,AGROUP:[ebx].MOD_ISTACK ; Get initial stack size
	lea	edi,MSGMOD3_ISTACK ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display line 3

	lea	esi,MSGMOD3	; Display line 3
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Display initial CS:IP

	mov	ax,AGROUP:[ebx].MOD_CSIP.VSEG ; Get initial CS
	lea	edi,MSGMOD4_CSIP[0] ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].MOD_CSIP.VOFF ; Get initial IP
	lea	edi,MSGMOD4_CSIP[5] ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display initial SS:SP

	mov	ax,AGROUP:[ebx].MOD_SSSP.VSEG ; Get initial SS
	lea	edi,MSGMOD4_SSSP[0] ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].MOD_SSSP.VOFF ; Get initial SP
	lea	edi,MSGMOD4_SSSP[5] ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display line 4

	lea	esi,MSGMOD4	; Display line 4
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Display # segments in segment table

	mov	ax,AGROUP:[ebx].MOD_NSEGS ; Get # segments in segment table
	lea	edi,MSGMOD5_NSEGS ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display # module reference table entries

	mov	ax,AGROUP:[ebx].MOD_NMREF ; Get # module reference table entries
	lea	edi,MSGMOD5_NMREF ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display size of non-resident names table

	mov	ax,AGROUP:[ebx].MOD_SNRNT ; Get size of non-resident names table
	lea	edi,MSGMOD5_SNRNT ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display near ptr to segment table

	mov	ax,AGROUP:[ebx].MOD_NPSEG ; Get near ptr to segment table
	lea	edi,MSGMOD5_NPSEG ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display line 5

	lea	esi,MSGMOD5	; Display line 5
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Display near ptr to resource table

	mov	ax,AGROUP:[ebx].MOD_NPRES ; Get near ptr to resource table
	lea	edi,MSGMOD6_NPRES ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display near ptr to resident names table

	mov	ax,AGROUP:[ebx].MOD_NPRNAM ; Get near ptr to resident names table
	lea	edi,MSGMOD6_NPRNAM ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display near ptr to module reference table

	mov	ax,AGROUP:[ebx].MOD_NPMREF ; Get near ptr to module reference table
	lea	edi,MSGMOD6_NPMREF ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display near ptr to imported names table

	mov	ax,AGROUP:[ebx].MOD_NPINAM ; Get near ptr to imported names table
	lea	edi,MSGMOD6_NPINAM ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display line 6

	lea	esi,MSGMOD6	; Display line 6
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Display file offset to non-resident names table

	mov	eax,AGROUP:[ebx].MOD_ONRNT ; Get file offset to non-resident names table
	lea	edi,MSGMOD7_ONRNT ; ES:EDI ==> output format area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

; Display line 7

	lea	esi,MSGMOD7	; Display line 7
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Display # moveable entries

	mov	ax,AGROUP:[ebx].MOD_NMOVE ; Get # moveable entries
	lea	edi,MSGMOD8_NMOVE ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display alignment shift count

	mov	ax,AGROUP:[ebx].MOD_SHIFT ; Get alignment shift count
	lea	edi,MSGMOD8_SHIFT ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display TTF flag

	mov	ax,AGROUP:[ebx].MOD_TTFNT ; Get TTF flag
	lea	edi,MSGMOD8_TTFNT ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display OS Flags

	mov	al,AGROUP:[ebx].MOD_OSFLG ; Get OS Flags
	lea	edi,MSGMOD8_OSFLG ; ES:EDI ==> output format area
	call	BIN2BYTE	; Convert AL to hex at ES:EDI

; Display other flags

	mov	al,AGROUP:[ebx].MOD_OTHER ; Get other flags
	lea	edi,MSGMOD8_OTHER ; ES:EDI ==> output format area
	call	BIN2BYTE	; Convert AL to hex at ES:EDI

; Display line 8

	lea	esi,MSGMOD8	; Display line 8
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Display unknown #1

	mov	ax,AGROUP:[ebx].MOD_SAME1 ; Get unknown #1
	lea	edi,MSGMOD9_SAME1 ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display unknown #2

	mov	ax,AGROUP:[ebx].MOD_SAME2 ; Get unknown #2
	lea	edi,MSGMOD9_SAME2 ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display unknown #3

	mov	ax,AGROUP:[ebx].MOD_SWAP ; Get unknown #3
	lea	edi,MSGMOD9_SWAP ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display expected Windows version

	mov	ax,AGROUP:[ebx].MOD_EXPWV ; Get expected Windows version
	lea	edi,MSGMOD9_EXPWV ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display line 9

	lea	esi,MSGMOD9	; Display line 9
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; If this is a NE database for a PE module, display additional information

	test	AGROUP:[ebx].MOD_FLAGS,MDBF_WIN32 ; Izit a PE module?
	jz	short DISP_MDB_NOTPE ; Jump if not

; Diaplay PE-only RVA

	mov	eax,AGROUP:[ebx].MOD_PE_RVA ; Get PE-only RVA
	lea	edi,MSGMOD10_PE_RVA ; ES:EDI ==> output format area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

; Diaplay PE-only base address

	mov	eax,AGROUP:[ebx].MOD_PE_BASE ; Get PE-only base address
	lea	edi,MSGMOD10_PE_BASE ; ES:EDI ==> output format area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

; Diaplay PE-only resource address

	mov	eax,AGROUP:[ebx].MOD_PE_RSRC ; Get PE-only resource address
	lea	edi,MSGMOD10_PE_RSRC ; ES:EDI ==> output format area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

; Display line 10

	lea	esi,MSGMOD10	; Display line 10
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column
DISP_MDB_NOTPE:

; Clear to the end of the page

	call	CLEAR_EOP	; Clear to the end-of-the-page

	jmp	short DISP_MDBEXIT ; Join common exit code


DISP_MDBERR_NOWIN:
	mov	MSGOFF,offset DGROUP:NOWINERR ; Save offset of error message

	jmp    short DISP_MDBERR_COM ; Join common code


DISP_MDBERR_INVSEL:
	mov	MSGOFF,offset DGROUP:SELERR ; Save offset of error message
DISP_MDBERR_COM:
	or	LC2_FLAG,mask $LC2_MSG ; Mark as message to display
DISP_MDBEXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_MDB endp			; End DISP_MDB procedure
	NPPROC	GetCurTDBSel -- Get Current Task Selector
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get currrent module selector

On exit:

AX	=	current module selector
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <ebx,fs>	; Save registers

	verr	KVARS_VEC.VSEG	; Izit valid?
	jnz	short GetCurTDBSelErr ; Jump if not

	lfs	bx,KVARS_VEC	; FS:BX ==> KVARS_STR
	assume	fs:nothing	; Tell the assembler about it

	mov	ax,fs:[bx].KV_headTDB ; Get head TDB selector

	and	ax,ax		; Izit invalid?
	jnz	short GetCurTDBSelExit ; Jump if not (note CF=0)
GetCurTDBSelErr:
	stc			; Mark as invalid
GetCurTDBSelExit:
	REGREST <fs,ebx>	; Restore
	assume	fs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GetCurTDBSel endp		; End GetCurTDBSel procedure
	NPPROC	CMD_TDB -- Display A Task Database
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display a task database

TDB expr

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	pushad			; Save all EGP registers

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	jz	short CMD_TDB_ERR_NOWIN ; Jump if not

	verr	KVARS_VEC.VSEG	; Izit valid?
	jnz	short CMD_TDB_INITERR ; Jump if not

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	or	al,al		; Izit the end of the line?
	jnz	short CMD_TDB_EXPR ; Jump if not

; Use current task

	call	GetCurTDBSel	; Get current task selector
	jc	short CMD_TDB_ERR_INVSEL ; Jump if invalid

	jmp	short CMD_TDB_COM ; Join common code


CMD_TDB_EXPR:
	call	PARSE_EXPR	; Parse command line for expression
	jc	short CMD_TDB_SYNTERR ; Jump if something went wrong (note CF=1)
CMD_TDB_COM:
	mov	TDBSEL,ax	; Save for later use

	mov	al,@DSP_TDB	; Screen state is TDB
	call	SET_STATE	; Set new state

	clc			; Mark as successful

	jmp	short CMD_TDB_EXIT ; Join common exit code


CMD_TDB_ERR_INVSEL:
	mov	MSGOFF,offset DGROUP:SELERR ; Save offset of error message

	jmp    short CMD_TDB_ERRCOM ; Join common code


CMD_TDB_ERR_NOWIN:
	mov	MSGOFF,offset DGROUP:NOWINERR ; Save offset of error message

	jmp    short CMD_TDB_ERRCOM ; Join common code


CMD_TDB_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	jmp	short CMD_TDB_ERRCOM ; Join common error exit code


CMD_TDB_INITERR:
	mov	MSGOFF,offset DGROUP:INITERR ; Save offset of error message

;;;;;;; jmp	short CMD_TDB_ERRCOM ; Join common error exit code


CMD_TDB_ERRCOM:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_TDB_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_TDB endp			; End CMD_TDB procedure
	NPPROC	DISP_TDB -- Display A TDB
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display a Task DataBase

On entry:

TDBSEL	=	selector of TDB to display

|

	pushad			; Save all EGP registers

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	jz	near ptr DISP_TDBERR_NOWIN ; Jump if not

	push	TDBSEL		; Pass the selector
	call	GETBASE 	; Return with EAX = selector base
	jc	near ptr DISP_TDBERR_INVSEL ; Jump if invalid selector

	mov	ebx,eax 	; AGROUP:EBX ==> TDB

	mov	SCROFF,0	; Start at top of screen

	mov	ax,TDBSEL	; Get TDB selector
	lea	edi,MSGTDB_TDB	; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_NEXT ; Get next TDB selector
	lea	edi,MSGTDB_NEXT ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_STKVEC.VSEG ; Get stack ptr selector
	lea	edi,MSGTDB_STKVEC ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_STKVEC.VOFF ; Get stack ptr offset
	lea	edi,MSGTDB_STKVEC[5] ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_NEVENTS ; Get # events
	lea	edi,MSGTDB_NEVENTS ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	al,AGROUP:[ebx].TDB_PRIORITY ; Get priority
	lea	edi,MSGTDB_PRIORITY ; ES:EDI ==> output format area
	call	BIN2BYTE	; Convert AL to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_FLAGS ; Get FLAGS
	lea	edi,MSGTDB_FLAGS ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_ERRFL ; Get error flags
	lea	edi,MSGTDB_ERRFL ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_MINVER ; Get minimum Windows version #
	lea	edi,MSGTDB_MINVER ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_DGR ; Get DGROUP selector
	lea	edi,MSGTDB_DGR	; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_MOD ; Get module selector
	lea	edi,MSGTDB_MOD	; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_TMQ ; Get task message queue selector
	lea	edi,MSGTDB_TMQ	; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_PARENT ; Get parent task
	lea	edi,MSGTDB_PARENT ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_USH.VSEG ; Get user signal handler selector
	lea	edi,MSGTDB_USH	; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_USH.VOFF ; Get user signal handler offset
	lea	edi,MSGTDB_USH[5] ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_GDNH.VSEG ; Get GlobalDiscard notify handler selector
	lea	edi,MSGTDB_GDNH ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_GDNH.VOFF ; Get GlobalDiscard notify handler offset
	lea	edi,MSGTDB_GDNH[5] ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_INT00.VSEG ; Get INT 00h handler selector
	lea	edi,MSGTDB_INT00 ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_INT00.VOFF ; Get INT 00h handler offset
	lea	edi,MSGTDB_INT00[5] ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_INT02.VSEG ; Get INT 02h handler selector
	lea	edi,MSGTDB_INT02 ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_INT02.VOFF ; Get INT 02h handler offset
	lea	edi,MSGTDB_INT02[5] ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_INT04.VSEG ; Get INT 04h handler selector
	lea	edi,MSGTDB_INT04 ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_INT04.VOFF ; Get INT 04h handler offset
	lea	edi,MSGTDB_INT04[5] ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_INT06.VSEG ; Get INT 06h handler selector
	lea	edi,MSGTDB_INT06 ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_INT06.VOFF ; Get INT 06h handler offset
	lea	edi,MSGTDB_INT06[5] ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_INT07.VSEG ; Get INT 07h handler selector
	lea	edi,MSGTDB_INT07 ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_INT07.VOFF ; Get INT 07h handler offset
	lea	edi,MSGTDB_INT07[5] ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_INT3E.VSEG ; Get INT 3Eh handler selector
	lea	edi,MSGTDB_INT3E ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_INT3E.VOFF ; Get INT 3Eh handler offset
	lea	edi,MSGTDB_INT3E[5] ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_INT75.VSEG ; Get INT 75h handler selector
	lea	edi,MSGTDB_INT75 ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_INT75.VOFF ; Get INT 75h handler offset
	lea	edi,MSGTDB_INT75[5] ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	eax,AGROUP:[ebx].TDB_COMPFL ; Get compatibility flags
	lea	edi,MSGTDB_COMPFL ; ES:EDI ==> output format area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_TIBSEL ; Get Thread Information Block selector
	lea	edi,MSGTDB_TIBSEL ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	eax,AGROUP:[ebx].TDB_LATDB ; Get linear addr of Thread Database
	lea	edi,MSGTDB_LATDB ; ES:EDI ==> output format area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_HTASK16 ; Get Win16 task handle
	lea	edi,MSGTDB_HTASK16 ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_PSPSEL ; Get PSP selector
	lea	edi,MSGTDB_PSPSEL ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_DTA.VSEG ; Get DTA selector
	lea	edi,MSGTDB_DTA	; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_DTA.VOFF ; Get DTA offset
	lea	edi,MSGTDB_DTA[5] ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	al,AGROUP:[ebx].TDB_CURDRV ; Get current drive
	lea	edi,MSGTDB_CURDRV ; ES:EDI ==> output format area
	call	BIN2BYTE	; Convert AL to hex at ES:EDI

;;;;;;; mov	al,AGROUP:[ebx].TDB_CURDRV ; Get current drive
	and	al,not 80h	; Remove Hard Disk bit?
	add	al,'A'          ; Convert to ASCII
	mov	MSGTDB_CURDRV2,al ; Save in message

	mov	ax,AGROUP:[ebx].TDB_DLLCHAIN.VSEG ; Get DLL chain selector
	lea	edi,MSGTDB_DLLCHAIN ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_DLLCHAIN.VOFF ; Get DLL chain offset
	lea	edi,MSGTDB_DLLCHAIN[5] ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_CSALIAS ; Get code alias
	lea	edi,MSGTDB_CSALIAS ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,AGROUP:[ebx].TDB_TDBSIG ; Get TDB signature
	mov	MSGTDB_SIG.ELO,ax ; Save in message

	mov	eax,AGROUP:[ebx].TDB_MODNAME.EDQLO ; Get module name
	mov	MSGTDB_MODNAME.EDQLO,eax ; Save in message

	mov	eax,AGROUP:[ebx].TDB_MODNAME.EDQHI ; Get module name
	mov	MSGTDB_MODNAME.EDQHI,eax ; Save in message

; Pad short names with trailing blanks

	mov	ecx,8		; Length of module name
	lea	edi,MSGTDB_MODNAME[-1] ; DS:ESI ==> module name - 1
@@:
	inc	edi		; Skip to next char

	cmp	DGROUP:[edi].LO,0 ; Izit end-of-name?
	loopne	@B		; Jump if not
	jne	short @F	; Jump if it's full

	mov	al,' '          ; Pad with this
	inc	ecx		; Count in another
    rep stos	es:[edi].LO	; Pad it
@@:

; Display line 1

	lea	esi,MSGTDB1	; Display line 1
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Display line 2

	lea	esi,MSGTDB2	; Display line 2
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

; Display flag meanings

	xor	ecx,ecx 	; Initialize count of entries displayed
	mov	ax,AGROUP:[ebx].TDB_FLAGS ; Get the flags

TDBF_MAC macro	SUF

	test	ax,TDBF_&SUF	; Izit?
	jz	short @F	; Jump if not

	lea	esi,MSGTDB_&SUF ; DS:ESI ==> ASCIIZ text to display
	call	DISPASCIIZ	; Display ASCIIZ string from ESI
	inc	ecx		; Count in another one
@@:
	endm			; TDBF_MAC

	TDBF_MAC WINOLDAP
	TDBF_MAC NEWTASK
	TDBF_MAC WIN32

	jecxz	@F		; Jump if no flags active

	sub	SCROFF,2*1	; Back off over last blank
@@:
	mov	al,')'          ; Get right separator
	call	DISPTXT 	; Display byte on screen as text

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Display line 3

	lea	esi,MSGTDB3	; Display line 3
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Display line 4

	lea	esi,MSGTDB4	; Display line 4
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

; Display ErrorMode flag meanings

	xor	ecx,ecx 	; Initialize count of entries displayed
	mov	ax,AGROUP:[ebx].TDB_ERRFL ; Get the error mode flags

ERRM_MAC macro	SUF

	test	ax,SEM_&SUF	; Izit?
	jz	short @F	; Jump if not

	lea	esi,MSG_&SUF	; DS:ESI ==> ASCIIZ text to display
	call	DISPASCIIZ	; Display ASCIIZ string from ESI
	inc	ecx		; Count in another one
@@:
	endm			; ERRM_MAC

	ERRM_MAC FAILCRITICALERRORS
	ERRM_MAC NOGPFAULTERRORBOX
	ERRM_MAC NOALIGNMENTFAULTEXCEPT
	ERRM_MAC NOOPENFILEERRORBOX

	jecxz	@F		; Jump if no flags active

	sub	SCROFF,2*1	; Back off over last blank
@@:
	mov	al,')'          ; Get right separator
	call	DISPTXT 	; Display byte on screen as text

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Display line 5

	lea	esi,MSGTDB5	; Display line 5
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Display line 6

	lea	esi,MSGTDB6	; Display line 6
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Display line 7

	lea	esi,MSGTDB7	; Display line 7
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Display line 8

	lea	esi,MSGTDB8	; Display line 8
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Display line 9

	lea	esi,MSGTDB9	; Display line 9
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Display line 10

	lea	esi,MSGTDB10	; Display line 10
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Display line 11

	lea	esi,MSGTDB11	; Display line 11
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Display line 12

	lea	esi,MSGTDB12	; Display line 12
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

; Display the current directory

	lea	esi,AGROUP:[ebx].TDB_CURDIR ; Assume it's Win16

	test	AGROUP:[ebx].TDB_FLAGS,TDBF_WIN32 ; Izit a Win32 task?
	jz	short @F	; Jump if not

	lea	esi,AGROUP:[ebx].TDB_PSP ; Assume it's Win32
@@:
	lods	AGROUP:[esi].LO ; Get next char

	and	al,al		; Izit EOL?
	jz	short @F	; Jump if so

	call	DISPTXT 	; Display byte on screen as text

	jmp	@B		; Go around again

@@:
	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

	call	CLEAR_EOP	; Clear to the end-of-the-page

	jmp	short DISP_TDBEXIT ; Join common exit code


DISP_TDBERR_NOWIN:
	mov	MSGOFF,offset DGROUP:NOWINERR ; Save offset of error message

	jmp    short DISP_TDBERR_COM ; Join common code


DISP_TDBERR_INVSEL:
	mov	MSGOFF,offset DGROUP:SELERR ; Save offset of error message
DISP_TDBERR_COM:
	or	LC2_FLAG,mask $LC2_MSG ; Mark as message to display
DISP_TDBEXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_TDB endp			; End DISP_TDB procedure
	NPPROC	DISP_WGH -- Display WGH Memory
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display the WGH entries

On entry:

WGHNDX	=	index # of current MAC entry

|

	pushad			; Save all EGP registers
	REGSAVE <fs>		; Save register

;;;;;;; cmp	REENTRY,1	; Check re-entry level
;;;;;;; jne	short @F	; Jump if we're re-entering
;;;;;;;
;;;;;;; int	03h
;;;@@:
	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	jz	near ptr DISP_WGHERR_NOWIN ; Jump if not

	verr	KVARS_VEC.VSEG	; Izit valid?
	jnz	near ptr DISP_WGHERR_INITERR ; Jump if not

	lfs	bx,KVARS_VEC	; FS:BX ==> KVARS_STR
	assume	fs:nothing	; Tell the assembler about it

WGHSEL	equ	fs:[bx].KV_pGlobalHeap

	push	WGHSEL		; Pass the selector
	call	GETBASE 	; Return with EAX = selector base
	jc	near ptr DISP_WGHERR_INVSEL ; Jump if invalid selector

	mov	WGHBASE,eax	; Save for later use

	mov	SCROFF,0	; Start at top of screen

	call	INST_OPR0E	; Install our local Page Fault handler

	REGSAVE <MEMBASE,MEMOFF,MEMMODE,MEMMASK> ; Save the current base and offset

; Display the header

	lea	edi,MSG_WGH1	; ES:EDI ==> format save area
	mov	ax,WGHSEL	; Get the selector
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	al,TTLATTR	; Get title attribute
	xchg	al,DEFATTR	; Swap with default attribute

	lea	esi,MSG_WGH	; Line 1 of WGH header
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

;;;;;;; call	HDR_PHYS	; Display physical message (if any)

	call	HDR_SYMBOL	; Check for symbol at starting offset

	call	CLEAR_EOL	; Clear to the end-of-the-line
	xchg	al,DEFATTR	; Restore default attribute

; Find the current WGH index

	mov	edx,WGHBASE	; Get the base linear address
	add	edx,AGROUP:[edx].GH32_OFF1ST ; Get offset to first entry

	xor	ecx,ecx 	; Initialize to this value
	xchg	ecx,WGHNDX	; Get current index
	jecxz	DISP_WGH1	; Jump if we're at the top
@@:
	mov	eax,edx 	; Copy current linear address
	mov	edx,AGROUP:[edx].GA32Next ; Get pointer to next entry
	add	edx,WGHBASE	; Convert from offset to linear address

	cmp	eax,edx 	; Izit the same?
	je	short @F	; Jump if so

	inc	WGHNDX		; Count in another

	loop	@B		; Jump if more MAC entries
@@:
DISP_WGH1:

; Display the WGH entries

	mov	ecx,@NROWS-2	; Get # rows to display
	mov	MEMMODE,0	; Save for use by GETBYTE, etc.
	mov	MEMMASK,-1	; ...
DISP_WGH_NEXT:
	mov	MEMBASE,edx	; Save for use by GETBYTE, etc.
	mov	MEMOFF,0	; ...

; Display the offset from WGHSEL:0

	mov	eax,edx 	; Get current base
	sub	eax,WGHBASE	; Convert from linear address to offset
	call	DISPHEX4	; Display the nibble

	mov	al,'³'          ; Separator
	call	DISPTXT 	; Display byte on screen as text

; Display the Base Address

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

	mov	MEMOFF,GA32Base ; Save offset
	PUSHD	0		; Pass offset as argument
	call	GETDWORD	; Get, format, and display dword from MEMBASE+MEMOFF

; Display the Size

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	MEMOFF,GA32Size ; Save offset
	PUSHD	0		; Pass offset as argument
	call	GETDWORD	; Get, format, and display dword from MEMBASE+MEMOFF

; Display the Handle

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

;;;;;;; mov	MEMOFF,GA32Handle ; Save offset
	PUSHD	0		; Pass offset as argument
	call	GETWORD 	; Get, format, and display word from MEMBASE+MEMOFF

; Display the Owner

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

	cmp	AGROUP:[edx].GA32Owner,0 ; Izit free?
	je	short DISP_WGH_FREE ; Jump if so

;;;;;;; mov	MEMOFF,GA32Owner ; Save offset
	PUSHD	0		; Pass offset as argument
	call	GETWORD 	; Get, format, and display word from MEMBASE+MEMOFF

	push	AGROUP:[edx].GA32Owner.EDD ; Pass the owner (as dword for alignment)
	call	DISP_WGHOWNR	; Display the owner's name

	jmp	short DISP_WGH_COM1 ; Join common code


DISP_WGH_FREE:
	lea	esi,MSG_WGHFREE ; Free WGH message
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

;;;;;;; add	MEMOFF,2	; Skip over the owner entry
DISP_WGH_COM1:
	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

; Skip to next WGH entry

	mov	eax,edx 	; Copy current linear address
	mov	edx,AGROUP:[edx].GA32Next ; Get pointer to next entry
	add	edx,WGHBASE	; Convert from offset to linear address

	cmp	eax,edx 	; Izit the same?
	je	short @F	; Jump if so

;;;;;;; loop	DISP_WGH_NEXT	; Jump if more rows to display
	dec	ecx		; Count out another row
	jnz	DISP_WGH_NEXT	; Jump if more rows to display
@@:
	call	CLEAR_EOP	; Clear to the end-of-the-page

	REGREST <MEMMASK,MEMMODE,MEMOFF,MEMBASE> ; Restore

	call	REST_OPR0E	; Restore previous Page Fault handler

	jmp	short DISP_WGHEXIT ; Join common exit code


DISP_WGHERR_NOWIN:
	mov	MSGOFF,offset DGROUP:NOWINERR ; Save offset of error message

	jmp	short DISP_WGHERR_COM ; Join common code


DISP_WGHERR_INITERR:
	mov	MSGOFF,offset DGROUP:INITERR ; Save offset of error message

	jmp	short DISP_WGHERR_COM ; Join common code


DISP_WGHERR_INVSEL:
	mov	MSGOFF,offset DGROUP:SELERR ; Save offset of error message
DISP_WGHERR_COM:
	or	LC2_FLAG,mask $LC2_MSG ; Mark as message to display
DISP_WGHEXIT:
	REGREST <fs>		; Restore
	assume	fs:nothing	; Tell the assembler about it
	popad			; ...

	clc			; Indicate we should continue with next row

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_WGH endp			; End DISP_WGH procedure
	NPPROC	APP_ASCIIZ -- Append ASCIIZ Name At DS:ESI To Buffer
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Append the ASCIIZ string at DS:ESI to the MSG_WGHOWNR buffer.

|

;;;	    REGSAVE <eax,esi,edi>   ; Save for a moment
;;;
;;; ; Search to the end of MSG_WGHOWNR
;;;
;;;	    lea     edi,MSG_WGHOWNR-1 ; ES:EDI ==> local buffer
;;; @@:
;;;	    inc     edi 	    ; Skip to next entry
;;;
;;;	    cmp     DGROUP:[edi].LO,0 ; Izit EOL?
;;;	    jne     short @B	    ; Jump if not
;;;
;;; ; Copy the ASCIIZ string at DS:ESI to the local buffer
;;;
;;; @@:
;;;	    lods    ds:[esi].LO     ; Get next byte
;;;	    stos    MSG_WGHOWNR[edi] ; Save in buffer
;;;
;;;	    and     al,al	    ; Izit EOL?
;;;	    jnz     short @B	    ; Jump if not
;;;
;;;	    REGREST <edi,esi,eax>   ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

APP_ASCIIZ endp 		; End APP_ASCIIZ procedure
	NPPROC	APP_ASCLEN -- Append ASCIIZ Name To Buffer
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Append the ASCIIZ name to MSG_WGHOWNR buffer.

|

AASCLEN_STR struc

	dd	?		; Caller's EIP
	dd	?		; ..	   EBP
AASCLEN_LEN dd	?		; String length in bytes
AASCLEN_FVEC df ?		; Ptr to string to display
	dw	?		; Alignment

AASCLEN_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ecx,esi,edi,ds> ; Save registers

	mov	ecx,[ebp].AASCLEN_LEN ; Get the string length
	jecxz	APP_ASCLEN_EXIT ; Jump if string is empty

; Search to the end of MSG_WGHOWNR

	lea	edi,MSG_WGHOWNR-1 ; ES:EDI ==> local buffer
@@:
	inc	edi		; Skip to next entry

	cmp	DGROUP:[edi].LO,0 ; Izit EOL?
	jne	short @B	; Jump if not

	lds	esi,[ebp].AASCLEN_FVEC ; DS:ESI ==> string to display
	assume	ds:nothing	; Tell the assembler about it
APP_ASCLEN_NEXT:
	lods	ds:[esi].LO	; Get next character
S32	stos	MSG_WGHOWNR[edi] ; Save in local buffer

	and	al,al		; End of the message?
	loopnz	APP_ASCLEN_NEXT ; Jump if more bytes to display
	jz	short APP_ASCLEN_EXIT ; Yes

	mov	al,0		; String terminator
S32	stos	MSG_WGHOWNR[edi] ; Save in local buffer
APP_ASCLEN_EXIT:
	REGREST <ds,edi,esi,ecx,eax> ; Restore
	assume	ds:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	4+4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

APP_ASCLEN endp 		; End APP_ASCLEN procedure
	NPPROC	COPY_WGHOWNR -- Copy Name Of The Owner Of A WGH Entry
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy the name of the owner of a WGH entry

On entry:

SS:ESP	==>	DWGHO_STR (before PUSH BP)

On exit:

CF	=	0 if successful
	=	1 if not

|

CWGHO_STR struc

	dd	?		; Caller's EIP
	dd	?		; ..	   EBP
CWGHO_HNDL dd	?		; The handle's selector
CWGHO_BUF  dd	?		; Offset in DGROUP of buffer

CWGHO_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ebx,edx,esi,edi,fs,gs> ; Save registers

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

	verr	KVARS_VEC.VSEG	; Izit valid?
	stc			; Assume not
	jnz	short COPY_WGHOWNR_INITERR ; Jump if not (note CF=1)

	lfs	bx,KVARS_VEC	; FS:BX ==> KVARS_STR
	assume	fs:nothing	; Tell the assembler about it

WGHSEL	equ	fs:[bx].KV_pGlobalHeap

; Using the selector table, lookup this selector

	mov	edx,fs:[bx].KV_SelTableStart ; Copy offset in WGH of table
	mov	fs,WGHSEL	; FS:EDX ==> selector table
	assume	fs:nothing	; Tell the assembler about it

	movzx	esi,[ebp].CWGHO_HNDL.ELO ; Get the handle
	and	si,not ((mask $TI) or (mask $PL)) ; Clear the TI and PL bits
	shr	si,1-0		; Divide by two to index table of words
	mov	edx,fs:[edx+esi] ; Get the index

	and	edx,edx 	; Izit invalid?
	jnz	short @F	; Jump if not

	mov	edx,fs:[0].GH32_OFF1ST ; Get offset to first entry
@@:
	mov	si,fs:[edx].GA32Owner ; Get the owner

;;; ; Search through the Global Heap for an entry's owner
;;;
;;;	    push    WGHSEL	    ; Pass the selector
;;;	    call    GETLBASE	    ; Return with EAX = selector base
;;; ;;;;;;; jc	    near ptr COPY_WGHERR_INVSEL ; Jump if invalid selector
;;;
;;;	    mov     WGHBASE,eax     ; Save for later use
;;;	    mov     edx,eax	    ; Copy as seed
;;;	    add     edx,AGROUP:[edx].GH32_OFF1ST ; Get offset to first entry
;;;	    movzx   esi,[ebp].CWGHO_HNDL.ELO ; Get the handle
;;;	    and     si,not (mask $PL) ; Clear the PL bits
;;; @@:
;;;	    mov     di,AGROUP:[edx].GA32Handle ; Get the handle
;;;	    and     di,not (mask $PL) ; Clear the PL bits
;;;
;;;	    cmp     si,di	    ; Izit the same?
;;;	    je	    short COPY_WGHOWNR_DISP ; Jump if so
;;;
;;;	    mov     eax,edx	    ; Copy current linear address
;;;	    mov     edx,AGROUP:[edx].GA32Next ; Get pointer to next entry
;;;	    add     edx,WGHBASE     ; Convert from offset to linear address
;;;
;;;	    cmp     eax,edx	    ; Izit the same?
;;;	    jne     short @B	    ; Jump if not
;;;
;;;	    jmp     short @F	    ; Join common code
;;;
;;; COPY_WGHOWNR_DISP:
;;;	    mov     si,AGROUP:[edx].GA32Owner ; Get the owner
;;; @@:
	mov	MSG_WGHOWNR[0],0 ; Ensure empty

	push	offset PGROUP:APP_ASCIIZ ; Offset in PGROUP of ASCIIZ routine
	push	offset PGROUP:APP_ASCLEN ; ...		       ASCLEN ...
	push	esi		; Pass the handle's selector
	call	GET_WGHOWNR	; Get the WGH owner value

; Copy the contents of MSG_WGHOWNR to the caller's buffer

	lea	esi,MSG_WGHOWNR ; DS:ESI ==> local buffer
	mov	edi,[ebp].CWGHO_BUF ; ES:EDI ==> caller's buffer
@@:
	lods	MSG_WGHOWNR[esi] ; Get next character
S32	stos	DGROUP:[edi].LO ; Save in local buffer

	and	al,al		; End of the message?
	jnz	short @B	; Jump if not
				; Fall through with CF=0
COPY_WGHOWNR_INITERR:
	REGREST <gs,fs,edi,esi,edx,ebx,eax> ; Restore
	assume	fs:nothing,gs:nothing ; Tell the assembler about it

	pop	ebp		; Restore

	ret	4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COPY_WGHOWNR endp		; End COPY_WGHOWNR procedure
	NPPROC	DISP_WGHOWNR -- Display Name Of The Owner Of A WGH Entry
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display the name of the owner of a WGH entry

On entry:

SS:ESP	==>	DWGHO_STR (before PUSH BP)

|

DWGHO_STR struc

	dd	?		; Caller's EIP
	dd	?		; ..	   EBP
DWGHO_OWNR dd	?		; The owner's selector

DWGHO_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	push	offset PGROUP:DISPASCIIZ ; Offset in PGROUP of ASCIIZ routine
	push	offset PGROUP:DISPASCLEN ; ...		       ASCLEN ...
	push	[ebp].DWGHO_OWNR ; Pass the owner's selector
	call	GET_WGHOWNR	; Get the WGH owner value

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_WGHOWNR endp		; End DISP_WGHOWNR procedure
	NPPROC	GET_WGHOWNR -- Get The Name Of The The Owner Of A WGH Entry
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Get the name of the owner of a WGH entry

On entry:

SS:ESP	==>	GWGHO_STR (before PUSH BP)

|

GWGHO_STR struc

	dd	?		; Caller's EIP
	dd	?		; ..	   EBP
GWGHO_OWNR dd	?		; The owner's selector
GWGHO_ASCLEN dd ?		; Offset in PGROUP of ASCIIZ routine
GWGHO_ASCIIZ dd ?		; ...		      ASCLEN ...

GWGHO_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ebx,esi>	; Save registers

; Pick off special owner values

	cmp	[ebp].GWGHO_OWNR.ELO,@GA32OwnerSentinel ; Izit first/last?
	jne	short @F	; Jump if not

	lea	esi,MSG_WGHSENTINEL ; Leading text
	call	[ebp].GWGHO_ASCIIZ ; Display ASCIIZ string from ESI

	jmp	GET_WGHOWNR_EXIT ; Join common exit code


@@:
	cmp	[ebp].GWGHO_OWNR.ELO,@GA32OwnerDPMI ; Izit allocated viia DPMI?
	jne	short @F	; Jump if not

	lea	esi,MSG_WGHDPMI ; Leading text
	call	[ebp].GWGHO_ASCIIZ ; Display ASCIIZ string from ESI

	jmp	GET_WGHOWNR_EXIT ; Join common exit code


@@:

; If the owner is a task, we can display the task name

	push	[ebp].GWGHO_OWNR ; Pass the owner's selector
	call	ISTASK		; Izit a task?
	jc	short GET_WGHOWNR1 ; Jump if not

; Display the TDB name

	lea	esi,MSG_WGHTASK ; Leading text
	call	[ebp].GWGHO_ASCIIZ ; Display ASCIIZ string from ESI

	push	[ebp].GWGHO_OWNR ; Pass selector of string
	push	TDB_MODNAME	; ...  offset of string
	push	length TDB_MODNAME ; ...  length of string
	call	[ebp].GWGHO_ASCLEN ; Display ASCIIZ string

	jmp	GET_WGHOWNR_EXIT ; Join common exit code


GET_WGHOWNR1:

; If the owner is a module, we can display the module name

	push	[ebp].GWGHO_OWNR ; Pass the owner's selector
	call	ISMODULE	; Izit a module?
	jc	short GET_WGHOWNR2 ; Jump if not

; Display the module name

	lea	esi,MSG_WGHMODULE ; Leading text
	call	[ebp].GWGHO_ASCIIZ ; Display ASCIIZ string from ESI

	push	es		; Save for a moment

	mov	es,[ebp].GWGHO_OWNR ; Address the module entry
	assume	es:nothing	; Tell the assembler about it

	mov	si,es:[0].MOD_NPLFI ; Get near ptr to load file info (OPENSTRUC)

	lea	esi,es:[si].opexFile ; Skip to d:\path\filename.ext

; Skip to the filename.ext part

	mov	ebx,esi 	; Save offset
@@:
	lods	es:[esi].LO	; Get the next char

	cmp	al,0		; Izit a terminator?
	je	short @F	; Jump if so

	cmp	al,'\'          ; Izit a path separator?
	jne	short @B	; Jump if not

	mov	ebx,esi 	; Save offset of next char

	jmp	@B		; Go around again

@@:
	pop	es		; Restore
	assume	es:DGROUP	; Tell the assembler about it

	push	[ebp].GWGHO_OWNR ; Pass the module entry selector
	push	ebx		; ...  offset of string
	push	8+1+3		; ...  length of string
	call	[ebp].GWGHO_ASCLEN ; Display ASCIIZ string

	jmp	short GET_WGHOWNR_EXIT ; Join common exit code


GET_WGHOWNR2:

; If the owner is a PSP, we can display the module name

	push	[ebp].GWGHO_OWNR ; Pass the owner's selector
	call	ISPSP		; Izit a PSP?
	jc	short GET_WGHOWNR4 ; Jump if not

; If the PSP is preceded by a TDB, display the module name

	push	[ebp].GWGHO_OWNR ; Pass the owner's selector
	call	SEL2BASE	; Return with EAX == selector base address

	sub	eax,(size TDB_STR) - TDB_PSP ; Less remainder of TDB
	jc	short GET_WGHOWNR3 ; Jump if too small

	cmp	AGROUP:[eax].TDB_TDBSIG,@TDB_SIG ; Duzit have the right signature?
	jne	short GET_WGHOWNR3 ; Jump if not

	lea	eax,AGROUP:[eax].TDB_MODNAME ; Skip to the module name

; Display the module name

	lea	esi,MSG_WGHPSPTASK ; Leading text
	call	[ebp].GWGHO_ASCIIZ ; Display ASCIIZ string from ESI

	push	gs		; Pass selector of string
	push	eax		; ...  offset of string
	push	length TDB_MODNAME ; ...  length of string
	call	[ebp].GWGHO_ASCLEN ; Display ASCIIZ string

	jmp	short GET_WGHOWNR_EXIT ; Join common exit code


; The handle is that of a PSP, but it's not preceded by a TDB

GET_WGHOWNR3:










GET_WGHOWNR4:


GET_WGHOWNR_EXIT:
	REGREST <esi,ebx,eax>	; Restore

	pop	ebp		; Restore

	ret	4+4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_WGHOWNR endp		; End GET_WGHOWNR procedure
	NPPROC	ISTASK -- Is This A Windows Task?
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Is this a Windows task?

On entry:

SS:ESP	==>	ISTASK_STR (before PUSH EBP)

On exit:

CF	=	0 if it's a task
	=	1 if not

|

ISTASK_STR struc

	dd	?		; Caller's EIP
	dd	?		; ...	   EBP
ISTASK_HNDL dd	?		; Handle to check

ISTASK_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ds>	; Save registers

	movzx	eax,[ebp].ISTASK_HNDL.ELO ; Get the handle

	and	eax,eax 	; Izit obviously invalid?
	jz	short ISTASK_ERR ; Jump if not

	lsl	eax,eax 	; Get the segment limit
	jnz	short ISTASK_ERR ; Jump if invalid

	cmp	eax,TDB_TDBSIG+2 ; Izit big enough?
	jb	short ISTASK_ERR ; Jump if not

	mov	ds,[ebp].ISTASK_HNDL ; Get the handle
	assume	ds:nothing	; Tell the assembler about it

	cmp	ds:[0].TDB_TDBSIG,@TDB_SIG ; Duzit have the right signature?
	je	short ISTASK_EXIT ; Jump if so (note CF=0)
ISTASK_ERR:
	stc			; Mark as not a task
ISTASK_EXIT:
	REGREST <ds,eax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ISTASK	endp			; End ISTASK procedure
	NPPROC	ISMODULE -- Is This A Windows Module?
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Is this a Windows module?

On entry:

SS:ESP	==>	ISMODULE_STR (before PUSH EBP)

On exit:

CF	=	0 if it's a task
	=	1 if not

|

ISMODULE_STR struc

	dd	?		; Caller's EIP
	dd	?		; ...	   EBP
ISMODULE_HNDL dd  ?		; Handle to check

ISMODULE_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ds>	; Save registers

	movzx	eax,[ebp].ISMODULE_HNDL.ELO ; Get the handle

	and	eax,eax 	; Izit obviously invalid?
	jz	short ISMODULE_ERR ; Jump if not

	lsl	eax,eax 	; Get the segment limit
	jnz	short ISMODULE_ERR ; Jump if invalid

	cmp	eax,MOD_NPLFI+2 ; Izit big enough?
	jb	short ISMODULE_ERR ; Jump if not

	mov	ds,[ebp].ISMODULE_HNDL ; Get the handle
	assume	ds:nothing	; Tell the assembler about it

	cmp	ds:[0].MOD_MODSIG,@MOD_SIG ; Duzit have the right signature?
	je	short ISMODULE_EXIT ; Jump if so (note CF=0)
ISMODULE_ERR:
	stc			; Mark as not a module
ISMODULE_EXIT:
	REGREST <ds,eax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ISMODULE endp			; End ISMODULE procedure
	NPPROC	ISPSP -- Is This A Windows PSP?
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Is this a Windows PSP?

On entry:

SS:ESP	==>	ISPSP_STR (before PUSH EBP)

On exit:

CF	=	0 if it's a task
	=	1 if not

|

ISPSP_STR struc

	dd	?		; Caller's EIP
	dd	?		; ...	   EBP
ISPSP_HNDL dd	?		; Handle to check

ISPSP_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ds>	; Save registers

	movzx	eax,[ebp].ISPSP_HNDL.ELO ; Get the handle

	and	eax,eax 	; Izit obviously invalid?
	jz	short ISPSP_ERR ; Jump if not

	lsl	eax,eax 	; Get the segment limit
	jnz	short ISPSP_ERR ; Jump if invalid

	cmp	eax,100h	; Izit big enough?
	jb	short ISPSP_ERR ; Jump if not

	mov	ds,[ebp].ISPSP_HNDL ; Get the handle
	assume	ds:nothing	; Tell the assembler about it

	cmp	ds:[0].ELO,20CDh ; Duzit have the right signature?
	je	short ISPSP_EXIT ; Jump if so (note CF=0)
ISPSP_ERR:
	stc			; Mark as not a PSP
ISPSP_EXIT:
	REGREST <ds,eax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ISPSP	endp			; End ISPSP procedure
	NPPROC	CMD_SGH -- Search Windows Global Heap
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT!

Search Windows Global Heap

SGH [/b|/s|/h|/o|/n] [/c] expr

where /b = base address
      /s = size
      /h = handle
      /o = owner
;;;;;;/n = name
      /c = continue

Note that the switches must come first so as to avoid
confusing them with the divide symbol in the expression.

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

!

	pushad			; Save all EGP registers
	REGSAVE <fs>		; Save register

SGH_REC record	\
$SGH_EXPR:1,	\
$SGH_NOPL:1,	\
$SGH_CONT:1,	\
$SGH_TYPE:3

@SGH_BASE equ	1		; Base address
@SGH_SIZE equ	2		; Size
@SGH_HNDL equ	3		; Handle
@SGH_OWNR equ	4		; Owner
;;;;_NAME equ	5		; Name
@SGH_TYPE equ	(mask $SGH_TYPE) ; Type (see @SGH_xxx above for type field vals)
@SGH_CONT equ	(mask $SGH_CONT) ; Continue
@SGH_NOPL equ	(mask $SGH_NOPL) ; Clear PL bits before comparing
@SGH_EXPR equ	(mask $SGH_EXPR) ; Expression

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	jz	near ptr CMD_SGH_ERR_NOWIN ; Jump if not

	verr	KVARS_VEC.VSEG	; Izit valid?
	jnz	near ptr CMD_SGH_INITERR ; Jump if not

	lfs	bx,KVARS_VEC	; FS:BX ==> KVARS_STR
	assume	fs:nothing	; Tell the assembler about it

WGHSEL	equ	fs:[bx].KV_pGlobalHeap

	push	WGHSEL		; Pass the selector
	call	GETBASE 	; Return with EAX = selector base
	jc	near ptr CMD_SGH_ERR_INVSEL ; Jump if invalid selector

	mov	WGHBASE,eax	; Save for later use

	xor	edi,edi 	; Initialize switch flags
CMD_SGH_NEXT:
	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	or	al,al		; Izit the end of the line?
	jz	near ptr CMD_SGH_DONE ; Jump if so

	cmp	al,'/'          ; Izit a switch?
	je	short CMD_SGH_SWITCH ; Jump if so

	cmp	al,'!'          ; Izit a switch?
	je	short CMD_SGH_SWITCH ; Jump if so

	call	PARSE_EXPR	; Parse command line for expression
	jc	near ptr CMD_SGH_SYNTERR ; Jump if something went wrong (note CF=1)

	mov	SGH_VAL,eax	; Save for later use

	bts	edi,$SGH_EXPR	; Mark as expression found
	jc	near ptr CMD_SGH_SYNTERR ; Jump if already set

	jmp	CMD_SGH_NEXT	; Go around again


CMD_SGH_SWITCH:
	inc	esi		; Skip over the switch char

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	inc	esi		; Skip over it

	cmp	al,'b'          ; Izit base address?
	je	short CMD_SGH_BASE ; Jump if so

	cmp	al,'s'          ; Izit size?
	je	short CMD_SGH_SIZE ; Jump if so

	cmp	al,'h'          ; Izit handle?
	je	short CMD_SGH_HNDL ; Jump if so

	cmp	al,'o'          ; Izit owner?
	je	short CMD_SGH_OWNR ; Jump if so

;;;;;;; cmp	al,'n'          ; Izit name?
;;;;;;; je	short CMD_SGH_NAME ; Jump if so
;;;;;;;
	cmp	al,'c'          ; Izit continue?
	je	short CMD_SGH_CONT ; Jump if so

	jmp	CMD_SGH_SYNTERR ; Join common error code


CMD_SGH_BASE:
	test	edi,@SGH_TYPE	; Any previous type fields?
	jnz	near ptr CMD_SGH_SYNTERR ; Jump if so

	or	edi,@SGH_BASE shl $SGH_TYPE ; Mark as searching for base address
	lea	ebx,SGH_BASE	; CS:EBX ==> compare routine

	jmp	CMD_SGH_NEXT	; Go around again


CMD_SGH_SIZE:
	test	edi,@SGH_TYPE	; Any previous type fields?
	jnz	near ptr CMD_SGH_SYNTERR ; Jump if so

	or	edi,@SGH_SIZE shl $SGH_TYPE ; Mark as searching for size
	lea	ebx,SGH_SIZE	; CS:EBX ==> compare routine

	jmp	CMD_SGH_NEXT	; Go around again


CMD_SGH_HNDL:
	test	edi,@SGH_TYPE	; Any previous type fields?
	jnz	near ptr CMD_SGH_SYNTERR ; Jump if so

	or	edi,@SGH_NOPL or @SGH_HNDL shl $SGH_TYPE ; Mark as searching for handle
	lea	ebx,SGH_HNDL	; CS:EBX ==> compare routine

	jmp	CMD_SGH_NEXT	; Go around again


CMD_SGH_OWNR:
	test	edi,@SGH_TYPE	; Any previous type fields?
	jnz	near ptr CMD_SGH_SYNTERR ; Jump if so

	or	edi,@SGH_NOPL or @SGH_OWNR shl $SGH_TYPE ; Mark as searching for owner
	lea	ebx,SGH_OWNR	; CS:EBX ==> compare routine

	jmp	CMD_SGH_NEXT	; Go around again


;;;_SGH_NAME:
;;;;;;; test	edi,@SGH_TYPE	; Any previous type fields?
;;;;;;; jnz	near ptr CMD_SGH_SYNTERR ; Jump if so
;;;;;;;
;;;;;;; or	edi,@SGH_NAME shl $SGH_TYPE ; Mark as searching for name
;;;;;;; lea	ebx,SGH_NAME	; CS:EBX ==> compare routine
;;;;;;;
;;;;;;; jmp	CMD_SGH_NEXT	; Go around again
;;;;;;;
;;;;;;;
CMD_SGH_CONT:
	or	edi,@SGH_CONT	; Mark as continuing searching from current index

	jmp	CMD_SGH_NEXT	; Go around again


CMD_SGH_DONE:
	test	edi,@SGH_EXPR	; Is there an expression?
	jz	near ptr CMD_SGH_SYNTERR ; Jump if not

	test	edi,@SGH_TYPE	; Is there a type?
	jz	near ptr CMD_SGH_SYNTERR ; Jump if not

; Search the WGH for the value in SGH_VAL using compare routine EBX

	test	edi,@SGH_NOPL	; Should we clear PL bits before comparing?
	jz	short @F	; Jump if not

	and	SGH_VAL,not (mask $PL) ; Clear the PL bits
@@:

; Find the current WGH index if we're continuing

	mov	edx,WGHBASE	; Get the base linear address
	add	edx,AGROUP:[edx].GH32_OFF1ST ; Get offset to first entry

	xor	ecx,ecx 	; Initialize to this value
	xor	esi,esi 	; ...
	xchg	ecx,WGHNDX	; Get current index
	jecxz	CMD_SGH1	; Jump if we're at the top

	test	edi,@SGH_CONT	; Are we continuing?
	jz	short CMD_SGH1	; Jump if not (start at top)
@@:
	mov	eax,edx 	; Copy current linear address
	mov	edx,AGROUP:[edx].GA32Next ; Get pointer to next entry
	add	edx,WGHBASE	; Convert from offset to linear address

	cmp	eax,edx 	; Izit the same?
	je	short @F	; Jump if so

	inc	WGHNDX		; Count in another
	inc	esi		; Count in another

	loop	@B		; Jump if more MAC entries

; Skip over the current entry so we don't find it again

	mov	eax,edx 	; Copy current linear address
	mov	edx,AGROUP:[edx].GA32Next ; Get pointer to next entry
	add	edx,WGHBASE	; Convert from offset to linear address

	inc	esi		; Count in another
@@:
CMD_SGH1:
	mov	ecx,SGH_VAL	; Get the comparison value
CMD_SGH2:

; Trundle through the WGH entries comparing SGH_VAL using
; the compare routine in EBX

	call	ebx		; Compare ECX with [edx].GA32xxxx
	je	short CMD_SGH_FOUND ; Jump if it's a match

	mov	eax,edx 	; Copy current linear address
	mov	edx,AGROUP:[edx].GA32Next ; Get pointer to next entry
	add	edx,WGHBASE	; Convert from offset to linear address

	inc	esi		; Count in another

	cmp	eax,edx 	; Izit the same?
	jne	short CMD_SGH2	; Jump if not

; Value not found

	jmp    short CMD_SGH_ERR_VNF ; Join common error code


COMMENT|

Compare base address

On entry:

EDX	==>	GA32_STR
ECX	=	comparison value

On exit:

ZF	=	1 if it's a match
	=	0 if not

|

SGH_BASE:
	cmp	ecx,AGROUP:[edx].GA32Base ; Compare against the base address

	ret			; Return to caller


COMMENT|

Compare size

On entry:

EDX	==>	GA32_STR
ECX	=	comparison value

On exit:

ZF	=	1 if it's a match
	=	0 if not

|

SGH_SIZE:
	cmp	ecx,AGROUP:[edx].GA32Size ; Compare against the size

	ret			; Return to caller


COMMENT|

Compare handle

On entry:

EDX	==>	GA32_STR
ECX	=	comparison value

On exit:

ZF	=	1 if it's a match
	=	0 if not

|

SGH_HNDL:
	push	eax		; Save for a moment

	mov	ax,AGROUP:[edx].GA32Handle ; Get the handle
	and	ax,not (mask $PL) ; Clear the PL bits

	cmp	cx,ax		; Compare against the handle

	pop	eax		; Restore

	ret			; Return to caller


COMMENT|

Compare owner

On entry:

EDX	==>	GA32_STR
ECX	=	comparison value

On exit:

ZF	=	1 if it's a match
	=	0 if not

|

SGH_OWNR:
	push	eax		; Save for a moment

	mov	ax,AGROUP:[edx].GA32Owner ; Get the owner
	and	ax,not (mask $PL) ; Clear the PL bits

	cmp	cx,ax		; Compare against the owner

	pop	eax		; Restore

	ret			; Return to caller


COMMENT|

Compare owner

On entry:

EDX	==>	GA32_STR
ECX	=	comparison value

On exit:

ZF	=	1 if it's a match
	=	0 if not

|

;;;_NAME:
;;;;;;; ret			; Return to caller


CMD_SGH_FOUND:
	mov	WGHNDX,esi	; Save as current index

	call	DISP_WGH	; Display WGH entries

	clc			; Mark as successful

	jmp	short CMD_SGH_EXIT ; Join common exit code


CMD_SGH_ERR_VNF:
	mov	MSGOFF,offset DGROUP:VNFERR ; Save offset of error message

	jmp    short CMD_SGH_ERRCOM ; Join common code


CMD_SGH_ERR_INVSEL:
	mov	MSGOFF,offset DGROUP:SELERR ; Save offset of error message

	jmp    short CMD_SGH_ERRCOM ; Join common code


CMD_SGH_ERR_NOWIN:
	mov	MSGOFF,offset DGROUP:NOWINERR ; Save offset of error message

	jmp    short CMD_SGH_ERRCOM ; Join common code


CMD_SGH_INITERR:
	mov	MSGOFF,offset DGROUP:INITERR ; Save offset of error message

	jmp	short CMD_SGH_ERRCOM ; Join common error exit code


CMD_SGH_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

;;;;;;; jmp	short CMD_SGH_ERRCOM ; Join common error exit code


CMD_SGH_ERRCOM:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_SGH_EXIT:
	REGREST <fs>		; ...
	assume	fs:nothing	; Tell the assembler about it
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_SGH endp			; End CMD_SGH procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_WGH module
