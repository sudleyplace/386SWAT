;' $Header:   P:/PVCS/386SWAT/SWAT_SYM.ASV   1.20   10 Aug 1998 11:01:40   BOB  $
	title	SWAT_SYM -- 386SWAT Symbol Table Management Functions
	page	58,122
	name	SWAT_SYM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-2003 Qualitas, Inc.  All rights reserved.

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
	include ALLMEM.INC
	include VCPI.INC
	include BITFLAGS.INC
	include DPMI.INC
	include DOSCALL.INC
	include MAXDEV.INC
	include ASCII.INC
	include 8259.INC
	include CPUFLAGS.INC

	include SWAT_COM.INC
	include SWAT_SEG.INC
	include SWAT_SSF.INC
	include SWAT_SYM.INC
.list

DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	public	@SWAT_SYM_DATA16
@SWAT_SYM_DATA16 label byte	; Mark module start in .MAP file

	extrn	COMMON:tbyte
	include QMAX_FIL.INC

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	ARG_FLAG:word
	include SWAT_ARG.INC

	extrn	DEFATTR:byte
	extrn	TTLATTR:byte

	extrn	SWATDATA:dword
	extrn	LaINDOS:dword

	extrn	CMD_LINE:byte
	extrn	CMD_LINE_LEN:dword

	public	SYMSIZE
SYMSIZE dd	4096		; Symbol table size (with default)

	public	SYMBASE,SYMNEXT,SYMLAST,SYMCOUNT,SYMHASH
SYMBASE dd	?		; Offset in DGROUP of symbol table
SYMNEXT dd	?		; Next available entry
SYMLAST dd	?		; End+1 of symbol table
SYMCOUNT dd	0		; # symbols in the table
	; When a symbol is added or translated for a segment value,
	; its effective linear address is stored in the symbol table.
	; The last ADDRHBITS bits of the low order word of the
	; effective linear address is a hash value into the SYMHASH
	; table of DWORD pointers.  These pointers are offsets relative
	; to SYMBASE.  The symbol records themselves are linked into
	; unsorted chains both for symbol name hashing and address hashing.
SYMHASH dd	?		; Offset in DGROUP of symbol hash table

	public	SYMNHASH
SYMNHASH dd	?		; Hashed string values for symbol name search

	public	BUCKETS,ADDRHBITS,HASHPRIME,ADDRMASK,PROXSRCH
ADDRMASK dd	(1 shl @ADDRHBITS)-1 ; Bit mask applied to 32-bit address
BUCKETS db	0		; 1K blocks for SYMNHASH (default is unset)
ADDRHBITS db	@ADDRHBITS	; Bits of address to use for address hash
HASHPRIME dw	257		; Prime value for hash remainder (default for
				; BUCKETS=1)
PROXSRCH dw	0104h		; Default to 1 attempt, 4 bytes back for
				; label proximity searching

	public	OLDSTK_FVEC
OLDSTK_FVEC df	?

	public	SYMAPPND_MODE
SYMAPPND_MODE db ?		; Symbol append mode; 0=normal, !0=raw

	public	SYM_READBUF
SYM_READBUF db	@SYM_READBUFSIZ dup (0) ; File read buffer (must be <64K)
				; Used for loading symbols via LS and for
				; reading pieces of files into *FBROWS_BUFP.

	public	SYMFILTER_NXT,SYMFILTER_TAB,SYMFILTER_END
SYMFILTER_NXT dd offset DGROUP:L2 ; Offset to next available filter
SYMFILTER_TAB db 128 dup (0)	; Symbol filter table
L1	label	byte		; Remember where we are
	org	SYMFILTER_TAB	; Back to the start of the table
	db	7,'__imp__'     ; Default filter
	db	1,'_'           ; ...
L2	label	byte		; Remember the next available offset
	org	L1		; Back to previous origin
SYMFILTER_END dd offset DGROUP:SYMFILTER_TAB[L1-SYMFILTER_TAB] ; End of table

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	@SWAT_SYM_DATA
@SWAT_SYM_DATA label byte	; Mark module start in .MAP file

	extrn	SYMTAB_START:dword ; starting record in symbol table to display

	extrn	SCROFF:dword

	extrn	MSGOFF:dword
	extrn	SYMBERR:byte
	extrn	SYNTERR:byte
	extrn	OVFERR:byte
	extrn	SYMERR:byte

	extrn	SELFDBG:dword

	public	LSYM_cnt,LSYM_symcnt,LSYM_symsub
LSYM_cnt dd	?		; Bytes read from ssf file into SYM_READBUF
LSYM_symcnt dd	?		; Number of records according to file header
LSYM_symsub dd	?		; Subtotal for number of records

	align	4
	public	OLD_EAX,OLD_BX,OLD_DS
OLD_EAX dd	?
OLD_BX	dw	?
OLD_DS	dw	?

	public	HOSTFLAGS
HOSTFLAGS dw	0		; Flags passed up from INIT_VIRT

	public	ALTLINE
ALTLINE dd	?		; Offset in DGROUP of additional SYMHASH_SRCH
				; hit with line number attribute

	public	SYMTRAN_CMD
SYMTRAN_CMD SYMTRAN_STR <>	; Symbol translation structure for CMD_TRANSYM

	public	VMSEG_FIXUP
VMSEG_FIXUP dw	?		; Fixup added to VM segments by CMD_LOADSYM

	public	@NSYMROWS
@NSYMROWS equ	@NROWS-3	; # screen rows on which symbols can be displayed

@SYMBOL_MAXLEN	equ	 256	; Maximum symbol name + length byte

	public	STR_WORKSPC
STR_WORKSPC db	@SYMBOL_MAXLEN dup (?) ; Work area for comparing
				; symbol names

	public	SYMTAB_MSG, SYMTAB_MSG2, SYMTAB_FMT
; Symbol table: xxxx|xxxxxxxx to xxxxxxxx, next avail xxxxxxxx, size xxxxxxxx
SYMTAB_MSG	db	 ' Symbol table: '
SYMTAB_MSG_SEL	db	 '____|'
SYMTAB_MSG_OFF	db	 '________ to '
SYMTAB_MSG_LAST db	 '________, next avail '
SYMTAB_MSG_NEXT db	 '________; size '
SYMTAB_MSG_SIZE db	 '________', 0

;  #   Sg/Sl Offset  Flags    Grp# Name
SYMTAB_MSG2 db	'  #   '
	db	'Sg/Sl Offset  '
	db	'Flags    '
	db	'Grp# '
	db	'Name', 0

;xxxx³ xxxx|xxxxxxxx SW LN AB xxxx symbol_name...
SYMTAB_FMT	db	 '____³ '
SYMTAB_FMT_SEL	db	 '____'
SYMTAB_FMT_SEP	db	 ':'
SYMTAB_FMT_OFF	db	 '________ '
SYMTAB_FMT_FLAGS db	 '__ __ __ '
SYMTAB_FMT_GROUP db	 '____ '
@MAX_SYMNAME_DISP equ 43
SYMTAB_FMT_NAME db	 @MAX_SYMNAME_DISP dup (0)
				db	 0

	public	NODPMI_ERR,NOTSYM_ERR,DOSBUSY_ERR
NODPMI_ERR db	'DPMI services or interface to SWAT not enabled',0
NOTSYM_ERR db	'File is not a SWAT symbol file',0
DOSBUSY_ERR db	'DOS reentrancy conflict',0

	public	FILERR,SYM_FNAME,SYM_FH
FILERR	db	'Unable to open file ' ; Must be adjacent to filename
SYM_FNAME db	80 dup (0)	; File argument passed to LS
SYM_FH	dw	?		; File handle for CMD_LOADSYM and CMD_LOADFIL

	public	MSG_FNS
MSG_FNS db	' = '
MSG_FNS_HDRLEN equ $-MSG_FNS	; Length of header
MSG_FNS1 db	80 dup ('_'),0
MSG_FNS2 db	'+nnnnnnnn'

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP,ds:PGROUP

	public	@SWAT_SYM_PROG
@SWAT_SYM_PROG: 		; Mark module start in .MAP file

	extrn	SWATINI:tbyte

	extrn	BIN2DWORD:near
	extrn	BIN2WORD:near
	extrn	CLEAR_EOL:near
	extrn	CLEAR_EOP:near
	extrn	DISPASCIIZ:near
	extrn	GETBASE:near
	extrn	U32_LOWERCASE:near
	extrn	NEXTLINE:near

	extrn	CMD_WHITE:near
	extrn	CMD_BLACK:near
	extrn	PARSE_LVAL:near

	extrn	U32_DRAINPIQ:near
	extrn	REST_IMR:near
	extrn	SAVE_IRQS:near
	extrn	REST_IRQS:near

	extrn	PARSE_ADDR:near
	extrn	IZITEOL:near
	extrn	ENDOF_CMDLINE:near
	extrn	FindAddr:near
	extrn	DISP_CMDLINE:near
	extrn	PURGE_KBUFF:near
	extrn	GETNDKEY:near

; The following structure defines the stack as setup by our caller
; in SWAT_VCP.ASM

SYMSTK_STR struc

SYMSTK_GS dw	?,?		; Caller's GS
SYMSTK_DS dw	?,?		; ...	   DS

SYMSTK_STR ends

@SYMBACK equ	(type SYMSTK_STR) ; Amount to subtract to get to
				; base of the structure

DOSCALL0 macro	FNCODE		; DOSCALL from PL0

ifnb	<FNCODE>
	mov	ah,FNCODE	; Get subfunction
endif				; IFNB <FNCODE>
	PUSHD	ss		; Simulate PL3 ring transition
	push	esp		; ...by saving SS|ESP
	add	[esp].EDD,4	; Add so that SS:ESP on stack points to the
				; PL0 stack before this call
	int	21h		; Request DOS service
	lea	esp,[esp+2*4]	; Strip from the stack w/o modifying flags

	endm			; DOSCALL0

	NPPROC	SYMFILTER -- Filter Out Undesirable Symbol Prefixes
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Filter out undesirable symbol prefixes

On entry:

GS:ESI	==>	length-name of symbol

On exit:

GS:ESI	==>	new length-name of symbol
AL	=	old value at new GS:ESI

|

	REGSAVE <ecx,edi,es>	; Save registers

	SETDATA es		; Set data selector into ES
	assume	es:DGROUP	; Tell the assembler about it

	lea	edi,SYMFILTER_TAB ; ES:EDI ==> symbol filter table
	mov	al,AGROUP:[esi].LO ; Get original length
SYMFILTER_NEXT:
	cmp	edi,SYMFILTER_NXT ; Izit outside the table limit?
	jae	short SYMFILTER_EXIT ; Jump if so

	movzx	ecx,DGROUP:[edi].LO ; Get the symbol filter length
	inc	edi		; Skip over the length byte

	cmp	cl,AGROUP:[esi].LO ; Izit long enough?
	jae	short @F	; Jump if not

	REGSAVE <ecx,esi,edi>	; Save for a moment
	inc	esi		; Skip over the length byte
   repe cmps	AGROUP:[esi].LO,SYMFILTER_TAB[edi] ; Duzit match?
	REGREST <edi,esi,ecx>	; Restore
	je	short SYMFILTER_STRIP ; Jump if so
@@:
	add	edi,ecx 	; Skip to next entry

	jmp	SYMFILTER_NEXT	; Go around again


SYMFILTER_STRIP:
;;;;;;; mov	al,AGROUP:[esi].LO ; Get original length
	add	esi,ecx 	; Skip over filter to length byte
	sub	al,cl		; Less filter length
	xchg	al,AGROUP:[esi].LO ; Save as new length byte, return old value
SYMFILTER_EXIT:
	REGREST <es,edi,ecx>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SYMFILTER endp			; End SYMFILTER procedure
	NPPROC	SYMAPPND -- Symbol Table Append
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Symbol Table Append

On entry:

SYMAPPND_MODE =  0 if normal append (existing symbol names are updated)
	      =  1 if raw append (duplicate symbol names are allowed)
ECX	=	# names to append
DS:ESI	==>	table of names to append
SS:EBP	==>	FORW_STR (nothing above FORW_EFL is valid
			   unless we're called from VM)

On exit:

CF	=	0 if successful
	=	1 if not
AH	=	error code if CF=1 (EAX otherwise clobbered)
ECX	=	# records appended (even if CF=1)

|

	REGSAVE <ecx,esi,es>	; Save registers

	SETDATA es		; Set data selector into ES
	assume	es:DGROUP	; Tell the assembler about it

; Calculate the incoming table's linear address depending upon the mode

	call	CALC_DSESI	; Return with EAX = linear address of DS:ESI
	mov	esi,eax 	; AGROUP:ESI ==> caller's table

	call	SYMAPPND_COM	; Call common symbol append code
				; Return with CF significant
	pushfd			; CF contains status

	sub	[ebp].FORW_ECX,ecx ; Subtract out how many we still have
				; to process so as to return the # we have done
	popfd			; Restore status

	REGREST <es,esi,ecx>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SYMAPPND endp			; End SYMAPPND procedure
	NPPROC	SYMAPPND_COM -- Symbol Table Append common subroutine
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Symbol Table Append subroutine

This code is called from SYMAPPND as well as from CMD_LOADSYM.
When called from CMD_LOADSYM, the FORW_STR has nothing to do with
the call, but can be used wherever needed.

On entry:

SYMAPPND_MODE =  0 if normal append (existing symbol names are updated)
	      =  1 if raw append (duplicate symbol names are allowed)
ECX	=	# names to append
AGROUP:ESI ==>	 table of names to append
SS:EBP	==>	FORW_STR (nothing above FORW_EFL is valid
			   unless we're called from VM)

On exit:

CF	=	0 if successful
	=	1 if not
AH	=	error code if CF=1 (EAX otherwise clobbered)
ECX	=	# records left to process (even if CF=1)

|

	REGSAVE <ebx,esi,edi,es> ; Save registers

	and	ecx,ecx 	; Any entries to append?
	jz	near ptr SYMAPPND_CLC ; Jump if not

; If we're adding symbols and SYMCOUNT is 0, we need to re-initialize the
; hash tables.

	cmp	SYMCOUNT,0	; Are there any symbols?
	jne	short SYMAPPND_NEXT ; Jump if so

	call	HASH_INIT	; Initialize address and symbol name hash
SYMAPPND_NEXT:
	cmp	SYMAPPND_MODE,0 ; Are we doing a raw append?
	jnz	short SYMAPPND_NEXT1 ; Jump if so (always append, never update)

; See if this entry already exists in the table

	push	esi		; Save for a moment
	lea	esi,AGROUP:[esi].SYMC_NAMLEN ; GS:ESI ==> length-name
	call	SYMFILTER	; Return with ESI ==> new length-name
				; ...	      AL  =   old value at new length-name
	call	LCL_SYMSRCH	; Search for length-name at GS:ESI
	mov	AGROUP:[esi],al ; Restore old value
	pop	esi		; Restore
	jc	short SYMAPPND_NEXT1 ; Jump if not already in the table
				; DGROUP:EBX ==> matching entry

	mov	eax,AGROUP:[esi].ISYM_FVEC.FOFF ; Get offset
	mov	DGROUP:[ebx].SYM_FVEC.FOFF,eax ; Save in table

	mov	ax,AGROUP:[esi].ISYM_FVEC.FSEL ; Get segment/selector
	mov	DGROUP:[ebx].SYM_FVEC.FSEL,ax ; Save in table

	mov	ax,AGROUP:[esi].ISYM_FLAG ; Get flags
	mov	DGROUP:[ebx].SYM_FLAG,ax ; Save in table

	mov	ax,AGROUP:[esi].ISYM_GROUP ; Get group ID
	mov	DGROUP:[ebx].SYM_GRP,ax ; Save in table

; Update address hash entry and address field in symbol record
	mov	eax,ebx 	; Pointer to symbol record in DGROUP
	call	UPDATE_ADDRHASH ; Update address hash entry

; Skip to the next table entry

	movzx	eax,AGROUP:[esi].SYMC_NAMLEN ; Get the symbol name byte length
	lea	esi,AGROUP:[esi+eax].SYMC_NAME ; Skip to the next entry

	jmp	short SYMAPPND_LOOP ; Join common code


SYMAPPND_NEXT1:

; For each name, find its length and ensure there's enough room
; for the whole structure

	mov	edi,SYMNEXT	; ES:EDI ==> next available entry in table
	movzx	eax,AGROUP:[esi].SYMC_NAMLEN ; Get the symbol name byte length
	lea	edi,AGROUP:[edi+eax].SYM_NAME ; Skip to what would be
				; the next entry

	cmp	edi,SYMLAST	; Check against table end+1
	jae	short SYMAPPND_ERR_NOROOM ; Jump if there's no room

	mov	edi,SYMNEXT	; ES:EDI ==> next available entry in table

	push	ecx		; Save for a moment

	lea	ecx,AGROUP:SYMC_NAMLEN ; Get part common to both
S32 rep movs	<DGROUP:[edi].LO,AGROUP:[esi].LO> ; Copy to our table

	call	SYMFILTER	; Return with ESI ==> new length-name
				; ...	      AL  =   old value at new length-name
	mov	ebx,esi 	; Save original offset to restore old value
	movzx	ecx,AGROUP:[esi].LO ; Get the symbol name byte length
	inc	ecx		; Copy length byte and string
	add	edi,(SYM_NAMLEN - SYMC_NAMLEN) ; Skip over difference
S32 rep movs	<DGROUP:[edi].LO,AGROUP:[esi].LO> ; Copy to our table
	mov	AGROUP:[ebx].LO,al ; Restore old value

	xchg	SYMNEXT,edi	; Save as offset of next available byte

	mov	eax,edi 	; Get record offset within DGROUP
	mov	DGROUP:[edi].SYM_ADDR,-1 ; Initialize to free
	call	UPDATE_ADDRHASH ; Update symbol hash entry using
				; record at DGROUP:EAX; also update SYM_ADDR
	call	UPDATE_SYMNHASH ; Update name hash entry

	mov	edi,SYMNEXT	; Get back SYMNEXT in edi
	inc	SYMCOUNT	; Count in another symbol

	pop	ecx		; Restore
SYMAPPND_LOOP:
	dec	ecx		; Decrement count
	jnz	near ptr SYMAPPND_NEXT ; Jump if more entries to append
SYMAPPND_CLC:
	clc			; Mark as successful

	jmp	short SYMAPPND_EXIT ; Join common exit code


SYMAPPND_ERR_NOROOM:
	mov	ah,88h		; Mark as no room

	stc			; Indicate something went wrong
SYMAPPND_EXIT:
	REGREST <es,edi,esi,ebx> ; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SYMAPPND_COM endp		; End SYMAPPND_COM procedure
	NPPROC	SYMSRCH -- Symbol Table Search
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Symbol Table Search

On entry:

DS:ESI	==>	length byte and following symbol name to search for
SS:EBP	==>	FORW_STR (nothing above FORW_EFL is valid
			   unless we're called from VM)

On exit:

CF	=	0 if successful
	=	1 if not
AH	=	error code if CF=1 (EAX otherwise clobbered)

If CF = 0, values returned in FORW_STR

CX	=	seg/sel
EDI	=	offset
DX	=	flags
SI	=	group #

|

	REGSAVE <ebx,esi,es>	; Save registers

	SETDATA es		; Set data selector into ES
	assume	es:DGROUP	; Tell the assembler about it

; Calculate the incoming table's linear address depending upon the mode

	call	CALC_DSESI	; Return with EAX = linear address of DS:ESI
	mov	esi,eax 	; AGROUP:ESI ==> caller's table

	call	LCL_SYMSRCH	; Search for length-name at GS:ESI
	jc	short SYMSRCH_EXIT ; Jump if not found
				; (note CF=1, AH=error code)
				; DS:EBX ==> matching symbol table entry
	mov	eax,DGROUP:[ebx].SYM_FVEC.FOFF ; Get the offset
	mov	[ebp].FORW_EDI,eax ; Return in caller's EDI

	mov	ax,DGROUP:[ebx].SYM_FVEC.FSEL ; Get the segment/selector
	mov	[ebp].FORW_ECX.ELO,ax ; Return in caller's CX

	mov	ax,DGROUP:[ebx].SYM_GRP ; Get the group #
	mov	[ebp].FORW_ESI.ELO,ax ; Return in caller's SI

	mov	ax,DGROUP:[ebx].SYM_FLAG ; Get the flags
	mov	[ebp].FORW_EDX.ELO,ax ; Return in caller's DX

	clc			; Mark as found
SYMSRCH_EXIT:
	REGREST <es,esi,ebx>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SYMSRCH endp			; End SYMSRCH procedure
	NPPROC	LCL_SYMSRCH -- Local Form of Symbol Table Search
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Local form of Symbol Table Search

On entry:

GS:ESI	==>	length byte and following symbol name to search for
SS:EBP	==>	FORW_STR (nothing above FORW_EFL is valid
			   unless we're called from VM)

On exit:

CF	=	0 if successful
	=	1 if not
if CF=1, AH =	 error code;
otherwise,
EBX	=	offset in DGROUP of matching entry

|

	REGSAVE <eax,ecx,esi,edi,es> ; Save registers

	SELFBREAK SYMSRCH,08h	; Enable reentrant breakpoint if selfdbg&8

	cld			; Ensure string ops forwardly

	mov	ecx,SYMCOUNT	; Get # entries in the table
	jecxz	LCL_SYMSRCH_ERR ; Jump if the table is empty (not found)

	lods	AGROUP:[esi].LO ; Get length byte
	lea	edi,STR_WORKSPC ; String workspace in DGROUP
S32	stos	DGROUP:[edi].LO ; Save length in workspace
	movzx	ecx,al		; Bytes to copy
S32 rep movs	<DGROUP:[edi].LO,AGROUP:[esi].LO> ; Move it

	lea	eax,STR_WORKSPC ; Address beginning of string in DGROUP
	mov	ebx,eax 	; Save in EBX
	inc	ebx		; Skip length byte
	call	HASH_STR	; Get hash index in EAX

	mov	edi,SYMNHASH	; DS:EDI ==> symbol name hash table
	mov	esi,DGROUP:[edi+eax*4].EDD ; Get bucket pointer
	movzx	ecx,STR_WORKSPC.LO ; Get length of string to compare

LCL_SYMSRCH_NEXTTAB:

; If bucket is empty, fail

	cmp	esi,-1		; Izit an empty bucket?
	je	short LCL_SYMSRCH_ERR ; Jump if so

; Compare this entry

	REGSAVE <ecx,esi>	; Save for a moment

	cmp	cl,DGROUP:[esi].SYM_NAMLEN ; Does the length match?
	jne	short LCL_SYMSRCH_LOOPTAB ; Jump if not (note ZF=0)

	lea	esi,DGROUP:[esi].SYM_NAME ; Point to name
	mov	edi,ebx 	; DS:EDI ==> name after length byte
LCL_SYMSRCH_NEXTCHAR:
	cmp	ax,ax		; Ensure ZF=1 in case CX=0 because
				; REPE CMPS doesn't set ZF if CX=0
   repe cmps	DGROUP:[esi].LO,DGROUP:[edi].LO ; Same name?
	je	short LCL_SYMSRCH_LOOPTAB ; Jump if so (note ZF=1)

; Handle differences in case

	mov	al,DGROUP:[esi-1] ; Get source character
	call	U32_LOWERCASE	; Convert AL to lowercase
	mov	ah,al		; Save for a moment
	mov	al,DGROUP:[edi-1] ; Get local table character
	call	U32_LOWERCASE	; Convert AL to lowercase

	cmp	al,ah		; Same character?
	je	short LCL_SYMSRCH_NEXTCHAR ; Jump if so
				; Fall through if not (note ZF=0)
LCL_SYMSRCH_LOOPTAB:
	REGREST <esi,ecx>	; Restore
	je	short LCL_SYMSRCH_DONE ; Jump if so

; Skip over this entry

	mov	esi,DGROUP:[esi].SYM_NEXTNH ; Get next name hash record

	jmp	short LCL_SYMSRCH_NEXTTAB ; Check next entry


LCL_SYMSRCH_ERR:
	stc			; Mark as not found

	jmp	short LCL_SYMSRCH_EXIT ; Join common exit code


LCL_SYMSRCH_DONE:

; DS:ESI ==> matching symbol table entry

	mov	ebx,esi 	; Put record offset in EBX

	clc			; Mark as found
LCL_SYMSRCH_EXIT:
	REGREST <es,edi,esi,ecx,eax> ; Restore
	assume	es:nothing	; Tell the assembler about it
	jnc	short @F	; Jump if successful

	mov	ah,0A0h 	; Mark as name not found
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_SYMSRCH endp		; End LCL_SYMSRCH procedure
	NPPROC	SYMTRANS -- Symbol Table Translation
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Symbol Table Translation

On entry:

DS:ESI	==>	SYMTRAN_STR
SS:EBP	==>	FORW_STR (nothing above FORW_EFL is valid
			   unless we're called from VM)

On exit:

CF	=	0 if successful
	=	1 if not
AH	=	error code if CF=1 (EAX otherwise clobbered)

|

	REGSAVE <ebx,ecx,edx,esi,edi,es> ; Save registers

	SETDATA es		; Set data selector into ES
	assume	es:DGROUP	; Tell the assembler about it

; Calculate the incoming table's linear address depending upon the mode

	call	CALC_DSESI	; Return with EAX = linear address of DS:ESI
	mov	esi,eax 	; AGROUP:ESI ==> caller's table

	mov	edi,SYMBASE	; DS:EDI ==> symbol table
	mov	ecx,SYMCOUNT	; Get # entries in the table
	xor	edx,edx 	; Initialize translated entry count
	sub	ebx,ebx 	; Initialize record index
;;;;;;	jecxz	SYMTRANS_ERR	; Jump if the table is empty (not found)

	or	ecx,ecx 	; Is the table empty?
	jz	near ptr SYMTRANS_ERR ; Jump if so
SYMTRANS_NEXTTAB:

; Ensure the symbol is code/data or line #

	mov	ax,DGROUP:[edi].SYM_FLAG ; Get the flags
	and	ax,mask $SYMFL_TYP ; Isolate the type field

	cmp	ax,@SYMTYP_DAT shl $SYMFL_TYP ; Izit code/data?
	je	short @F	; Jump if so

	cmp	ax,@SYMTYP_LN	shl $SYMFL_TYP ; Izit line #?
	jne	near ptr SYMTRANS_LOOPTAB ; Jump if not
@@:

; Ensure same group # or group to be ignored

	test	AGROUP:[esi].SYMTRAN_FLAGS,mask $SYMTFL_IGOGRP ; Should we ignore group criterion?
	jnz	short SYMTRANS_GRPOK ; Jump if so

	mov	ax,AGROUP:[esi].SYMTRAN_OGRP ; Get old group #

	cmp	ax,DGROUP:[edi].SYM_GRP ; Izit the same group?
	jne	near ptr SYMTRANS_LOOPTAB ; Jump if not
SYMTRANS_GRPOK:

; Ensure same segment/selector or ignore

	test	AGROUP:[esi].SYMTRAN_FLAGS,mask $SYMTFL_IGOSEL ; Should we ignore this criterion?
	jnz	short SYMTRANS_SELOK ; Jump if so

	mov	ax,AGROUP:[esi].SYMTRAN_OSEL ; Get old segment/selector

	cmp	ax,DGROUP:[edi].SYM_FVEC.FSEL ; Izit the same?
	jne	short SYMTRANS_LOOPTAB ; Jump if not
SYMTRANS_SELOK:

; Change to new segment/selector if not verboten by flags

	test	AGROUP:[esi].SYMTRAN_FLAGS,mask $SYMTFL_IGNSEL ; Should we not replace selector?
	jnz	short SYMTRANS_XNSEL ; Jump if so

	mov	ax,AGROUP:[esi].SYMTRAN_NSEL ; Get new segment/selector
	test	AGROUP:[esi].SYMTRAN_FLAGS,mask $SYMTFL_ADDVMSEG ; Are we adding the new value?
	jz	short SYMTRANS_XADD ; Jump if not

	test	DGROUP:[edi].SYM_FLAG,@SYMFL_VM ; Is old symbol VM?
	jz	short SYMTRANS_XADD ; Jump if not

	test	AGROUP:[esi].SYMTRAN_FLAGS,mask $SYMTFL_IGNFLAG ; Are we ignoring new flags?
	jnz	short @F	; Jump if so

	test	AGROUP:[esi].SYMTRAN_NFLAG,@SYMFL_VM ; Is new selector also VM?
	jz	short SYMTRANS_XADD ; Jump if not
@@:
	add	ax,DGROUP:[edi].SYM_FVEC.FSEL ; Get new value
SYMTRANS_XADD:
	mov	DGROUP:[edi].SYM_FVEC.FSEL,ax ; Save in table
SYMTRANS_XNSEL:

; Change selector type if not forbidden by flags

	test	AGROUP:[esi].SYMTRAN_FLAGS,mask $SYMTFL_IGNFLAG ; Should we not change flags?
	jnz	short SYMTRANS_XNFLAG ; Jump if so

	mov	ax,AGROUP:[esi].SYMTRAN_NFLAG ; Get new flags
	and	ax,@SYMFL_VM	; Isolate VM/PM bit
	and	DGROUP:[edi].SYM_FLAG,not @SYMFL_VM ; Clear VM/PM bit in table
	or	DGROUP:[edi].SYM_FLAG,ax ; Save new VM/PM bit in table
SYMTRANS_XNFLAG:

; Add in new base (0 for no change)

	mov	eax,AGROUP:[esi].SYMTRAN_NBASE ; Get new base
	add	DGROUP:[edi].SYM_FVEC.FOFF,eax ; Add into table

; Update symbol hash table

	mov	eax,edi 	; Put record offset in EAX
	call	UPDATE_ADDRHASH ; Update address hash table for DGROUP:EAX

	inc	edx		; Count in another entry
SYMTRANS_LOOPTAB:

; Skip to the next table entry

	inc	ebx		; Increment record number

	movzx	eax,DGROUP:[edi].SYM_NAMLEN ; Get the symbol name byte length
	lea	edi,DGROUP:[edi+eax].SYM_NAME ; Skip to the next entry

;;;;;;; loopd	SYMTRANS_NEXTTAB ; Jump if more entries to check
	dec	ecx		; Decrement count
	jnz	near ptr SYMTRANS_NEXTTAB ; Jump if more entries to check

	and	edx,edx 	; Any entries found?
	jnz	short SYMTRANS_EXIT ; Jump if so (note CF=0)
SYMTRANS_ERR:
	mov	ah,0A0h 	; Mark as no matching entries

	stc			; Mark as not found
SYMTRANS_EXIT:
	REGREST <es,edi,esi,edx,ecx,ebx> ; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SYMTRANS endp			; End SYMTRANS procedure
	NPPROC	SYMFLUSH -- Symbol Table Flush
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Symbol Table Flush

On entry:

SS:EBP	==>	FORW_STR (nothing above FORW_EFL is valid
			   unless we're called from VM)

On exit:

CF	=	0

|

	REGSAVE <eax>		; Save register

	mov	eax,SYMBASE	; Get start of symbol table
	mov	SYMNEXT,eax	; Save as next entry

	sub	eax,eax 	; Get 0 value
	mov	SYMCOUNT,eax	; Mark as no entries
	mov	SYMTAB_START,eax ; Reset symbol table display to beginning

	clc			; Mark as successful

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SYMFLUSH endp			; End SYMFLUSH procedure
	NPPROC	CALC_DSESI -- Calculate Linear Address of DS:ESI
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate linear address of DS:ESI

On entry:

SS:EBP	==>	FORW_STR (nothing above FORW_EFL is valid
			   unless we're called from VM)

On exit:

EAX	=	linear address of DS:ESI

|

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit in VM 86 mode?
	jnz	short @F	; Jump if so

	push	[ebp-@SYMBACK].SYMSTK_DS ; Get caller's DS
	call	GETBASE 	; Return with EAX = selector base
				; Ignore error condition in CF
	jmp	short CALC_DSESI_COM ; Join common code



@@:
	movzx	eax,[ebp].FORW_DS ; Get caller's DS
	shl	eax,4-0 	; Convert from paras to bytes
CALC_DSESI_COM:
	add	eax,[ebp].FORW_ESI ; Plus the offset

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_DSESI endp 		; End CALC_DSESI procedure
	NPPROC	DISP_SYMTAB -- Display symbol table entries
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display the first few symbol table records starting with record SYMTAB_START

|

	pushad			; Save all EGP registers

	mov	bl,TTLATTR	; Get title attribute
	xchg	bl,DEFATTR	; Swap with default attribute

	mov	SCROFF,0	; Start at top of screen

	lea	edi,SYMTAB_MSG_SEL ; Line 1 of SYMTAB header - selector field
	mov	ax,ds		; Get SWAT's current data selector
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	lea	edi,SYMTAB_MSG_OFF ; Line 1 of header - offset field
	mov	eax,SYMBASE	; Get the value
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	lea	edi,SYMTAB_MSG_LAST ; Line 1 of header - end of symtab field
	mov	eax,SYMLAST	; Get end of table
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	lea	edi,SYMTAB_MSG_NEXT ; Line 1 of header - next available field
	mov	eax,SYMNEXT	; Next available entry
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	lea	edi,SYMTAB_MSG_SIZE ; Line 1 of header - size of table field
	mov	eax,SYMLAST	; Get end of table +1
	sub	eax,SYMBASE	; Subtract beginning of table
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	lea	esi,SYMTAB_MSG	; Prepare to display header line 1
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

	lea	esi,SYMTAB_MSG2 ; Line 2 of header
	call	DISPASCIIZ	; Display ASCIIZ string from ESI
	xchg	bl,DEFATTR	; Restore default attribute
	call	CLEAR_EOL	; Clear to the end of the line
	call	NEXTLINE	; Skip to next line, first column

	mov	esi,SYMBASE	; DS|ESI ==> symbol table
	mov	edi,SYMNEXT	; EDI points past end of valid entries
	xor	ecx,ecx 	; ECX is the current record number
DISP_SYMTAB_TEST:
	cmp	esi,edi 	; Are we in range?
	jnb	near ptr DISP_SYMTAB_EXIT ; Quit if we hit the end

	cmp	ecx,SYMTAB_START ; Is this one we should display?
	jb	near ptr DISP_SYMTAB_NEXT ; No, so keep on truckin'

	REGSAVE <ecx,edi,esi>	; Save registers

	lea	edi,SYMTAB_FMT	; Record # field
	mov	ax,cx		; Get current record number
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	lea	edi,SYMTAB_FMT_SEL ; Segment/selector field
	mov	ax,DGROUP:[esi].SYM_FVEC.FSEL ; Get segment/selector
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	dx,DGROUP:[esi].SYM_FLAG ; Get flag value

	lea	edi,SYMTAB_FMT_SEP ; Separator field
	mov	al,':'        ; VM separator

	test	dx,@SYMFL_VM	; Izit a VM segment?
	jnz	short @F	; If so, AL is OK

	mov	al,'|'          ; PM selector separator
@@:
S32	stos	es:[edi].LO	; Save separator

	lea	edi,SYMTAB_FMT_OFF ; Offset field
	mov	eax,DGROUP:[esi].SYM_FVEC.FOFF ; Get offset
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	and	dx,mask $SYMFL_TYP ; Isolate type field

	lea	edi,SYMTAB_FMT_FLAGS ; Flags field
	mov	ax,'  '         ; Assume it's blank

	cmp	dx,@SYMTYP_SWT shl $SYMFL_TYP ; Izit internal to SWAT?
	jne	short @F	; If not, AX is cool

	mov	ax,'WS'         ; Display SW
@@:
S32	stos	es:[edi].ELO	; Save switch

	inc	edi		; Skip space
	mov	ax,'  '         ; Assume it's blank

	cmp	dx,@SYMTYP_LN shl $SYMFL_TYP  ; Izit a line number record?
	jne	short @F	; If not, AX is cool

	mov	ax,'NL'         ; Display 'LN'
@@:
S32	stos	es:[edi].ELO	; Save switch

	inc	edi		; Skip space
	mov	ax,'  '         ; Assume it's blank

	cmp	dx,@SYMTYP_ABS shl $SYMFL_TYP ; Izit an ABS value?
	jne	short @F	; If not, AX is cool

	mov	ax,'BA'         ; Display 'AB'
@@:
S32	stos	es:[edi].ELO	; Save switch

	lea	edi,SYMTAB_FMT_GROUP ; Group field
	mov	ax,DGROUP:[esi].SYM_GRP ; Get group number
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	movzx	ecx,DGROUP:[esi].SYM_NAMLEN ; Get the symbol name byte length
	lea	esi,DGROUP:[esi].SYM_NAME ; DS:ESI ==> symbol name
	lea	edi,SYMTAB_FMT_NAME ; ES:EDI ==> name field

	cmp	cl,@MAX_SYMNAME_DISP ; Izit more than we can show?
	jbe	short @F	; Jump if not

	mov	cl,@MAX_SYMNAME_DISP ; Truncate
@@:
S32 rep movs	<SYMTAB_FMT_NAME[edi],DGROUP:[esi].LO> ; Copy symbol name to message field

	xor	al,al		; Create a null
S32	stos	es:[edi].LO	; Make it a null-terminated string

	lea	esi,SYMTAB_FMT	; Display line
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	CLEAR_EOL	; Clear to end of line
	call	NEXTLINE	; Skip to first column of next line

	REGREST <esi,edi,ecx>	; Restore registers

	mov	eax,ecx 	; Copy to test for end of the screen
	sub	eax,SYMTAB_START ; Get # of leading lines skipped

	cmp	eax,@NSYMROWS-1 ; Izit >= maximum?
	jae	short DISP_SYMTAB_EXIT ; Yes, so we're done
DISP_SYMTAB_NEXT:
	movzx	eax,DGROUP:[esi].SYM_NAMLEN ; Get the symbol name byte length
	lea	esi,DGROUP:[esi+eax].SYM_NAME ; Skip to the next entry
	inc	ecx		; Increment record number

	jmp	DISP_SYMTAB_TEST ; Do the next symbol


DISP_SYMTAB_EXIT:
	call	CLEAR_EOP	; Clear to the end-of-the-page

	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_SYMTAB endp		; End DISP_SYMTAB procedure
	NPPROC	CMD_TRANSYM -- Translate Symbols Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT!

Translate symbols command

TS osel ogrp nflag nsel[{+|-}] [nbase]
TS osel ogrp
TS

If only osel and ogrp are specified, matching symbols are retranslated
according to the current GDT and LDT.  If no arguments are specified,
all symbols are retranslated.  This is useful when debugging DPMI
applications where selectors are allocated and set dynamically.

Any argument may be specified as '*', meaning 'ignore this.'

The new flags "nflag" are of the form

P for PM symbols
V for VM symbols

The optional postfix sign on the new segment/selector value indicates
that it should be added(+) to or subtracted(-) from the existing
segment/selector value.  This is normally useful only for V86 mode
segment values.

The only symbols which may be translated are code/data and line
numbers.  This holds true for all forms of the command.

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

!

	pushad			; Save all EGP registers

	mov	SYMTRAN_CMD.SYMTRAN_FLAGS,@SYMTFL_IGNORE ; Ignore 'em all
	mov	SYMTRAN_CMD.SYMTRAN_NBASE,0 ; In case it's not present

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_TRANSYM_TRANS ; Yes, go with defaults

	cmp	al,'*'          ; Should we ignore this one?
	jne	short @F	; Jump if not

	inc	esi		; Skip character

	jmp	short CMD_TRANSYM_IGOSEL ; Jump if so


@@:

; Parse old segment/selector
; Convert the con/reg at DS:ESI to binary

	call	PARSE_LVAL	; Parse command line for lefthand value
	jc	near ptr CMD_TRANSYM_OVFERR ; Jump if too large

	cmp	eax,0000FFFFh	; Izit within limits?
	ja	near ptr CMD_TRANSYM_OVFERR ; Jump if too large

	mov	SYMTRAN_CMD.SYMTRAN_OSEL,ax ; Save for later use
	and	SYMTRAN_CMD.SYMTRAN_FLAGS,not (mask $SYMTFL_IGOSEL) ; Selector criterion is valid
CMD_TRANSYM_IGOSEL:
	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_TRANSYM_TRANS ; Yes, go with defaults

	cmp	al,'*'          ; Should we ignore this one?
	jne	short @F	; Jump if not

	inc	esi		; Skip character

	jmp	short CMD_TRANSYM_IGOGRP ; Jump if so


@@:

; Parse old group #
; Convert the con/reg at DS:ESI to binary

	call	PARSE_LVAL	; Parse command line for lefthand value
	jc	near ptr CMD_TRANSYM_OVFERR ; Jump if too large

	cmp	eax,0000FFFFh	; Izit within limits?
	ja	near ptr CMD_TRANSYM_OVFERR ; Jump if too large

	mov	SYMTRAN_CMD.SYMTRAN_OGRP,ax ; Save for later use
	and	SYMTRAN_CMD.SYMTRAN_FLAGS,not (mask $SYMTFL_IGOGRP) ; Group criterion is valid
CMD_TRANSYM_IGOGRP:
	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_TRANSYM_TRANS ; Yes, go with defaults

	cmp	al,'*'          ; Should we ignore this one?
	je	short CMD_TRANSYM_IGNFLAG ; Jump if so
@@:

; Parse new flags

	call	U32_LOWERCASE	; Convert AL to lowercase

	mov	bx,@SYMFL_VM	; Assume it's VM

	cmp	al,'v'          ; Izit VM?
	je	short @F	; Jump if so

	xor	bx,bx		; Assume it's PM

	cmp	al,'p'          ; Izit PM?
	jne	near ptr CMD_TRANSYM_SYNTERR ; Jump if not
@@:
	mov	SYMTRAN_CMD.SYMTRAN_NFLAG,bx ; Save for later use
	and	SYMTRAN_CMD.SYMTRAN_FLAGS,not (mask $SYMTFL_IGNFLAG) ; New flags are valid
CMD_TRANSYM_IGNFLAG:
	inc	esi		; Skip over the flag (or '*')

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_TRANSYM_TRANS ; Yes, go with defaults

	cmp	al,'*'          ; Should we ignore this one?
	jne	short @F	; Jump if not

	inc	esi		; Skip character

	jmp	short CMD_TRANSYM_IGNSEL ; Jump if so


@@:

; Parse new segment/selector
; Search for postfix sign indicator
	push	esi		; Save command line pointer

	call	CMD_WHITE	; Skip leading whitespace
	call	CMD_BLACK	; Skip expression
	mov	bl,al		; Save last character

	cmp	bl,'+'          ; Izit valid?
	je	short @F	; Jump if so

	cmp	bl,'-'          ; Izit other valid postfix?
	je	short @F	; Jump if so

	sub	bl,bl		; Indicate we don't have a postfix

	jmp	short XPOSTFIX	; Join common code


@@:
	mov	al,DGROUP:[esi+1].LO ; Get next character (WS or EOL)
	mov	DGROUP:[esi].LO,al ; Clobber postfix operator
XPOSTFIX:
	pop	esi		; Restore command line pointer

; Convert the con/reg at DS:ESI to binary

	call	PARSE_LVAL	; Parse command line for lefthand value
	jc	near ptr CMD_TRANSYM_OVFERR ; Jump if too large

	cmp	eax,0000FFFFh	; Izit within limits?
	ja	near ptr CMD_TRANSYM_OVFERR ; Jump if too large

	mov	SYMTRAN_CMD.SYMTRAN_NSEL,ax ; Save for later use
	and	SYMTRAN_CMD.SYMTRAN_FLAGS,not (mask $SYMTFL_IGNSEL) ; New selector is valid

	mov	al,bl		; Get saved postfix operator
	or	al,al		; Izit valid?
	jnz	short @F	; Jump if so

	call	CMD_WHITE	; Skip over white space
				; Return with AL = last character
@@:
	cmp	al,'+'          ; Are we adding?
	je	short CMD_TRANSYM_ADDSEG ; Jump if so

	cmp	al,'-'          ; Are we subtracting?
	jne	short CMD_TRANSYM_IGNSEL ; Jump if not

	neg	SYMTRAN_CMD.SYMTRAN_NSEL ; Negate selector offset value
CMD_TRANSYM_ADDSEG:
	or	SYMTRAN_CMD.SYMTRAN_FLAGS,mask $SYMTFL_ADDVMSEG ; Add instead of replacing
	inc	esi		; Skip it
CMD_TRANSYM_IGNSEL:

; Allow the trailing base to be optional

;;;;;	mov	SYMTRAN_CMD.SYMTRAN_NBASE,0 ; In case it's not present

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	cmp	al,0		; Izit end-of-the-line?
	je	short CMD_TRANSYM_TRANS ; Yes, it was optional

	cmp	al,'*'          ; Izit '*'?
	je	short CMD_TRANSYM_TRANS ; Yes, don't try to parse value

; Parse new base
; Convert the con/reg at DS:ESI to binary

	call	PARSE_LVAL	; Parse command line for lefthand value
	jc	near ptr CMD_TRANSYM_OVFERR ; Jump if too large

	mov	SYMTRAN_CMD.SYMTRAN_NBASE,eax ; Save for later use

; Ensure nothing more on the line

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	cmp	al,0		; Izit end-of-the-line?
	jne	near ptr CMD_TRANSYM_SYNTERR ; No, so that's an error
CMD_TRANSYM_TRANS:
	or	LCL_FLAG,@LCL_REDI ; Force redisplay

; Translate the symbols

	lea	esi,SYMTRAN_CMD ; DS:ESI ==> symbol translation structure

; Simulate a call to SYMTRANS from Int 67 VCPI handler
; To ensure that the stack retains the correct alignment, and that
; we use the correct sequence, allocate space on the stack and fill
; in structure members.

	push	ebp		; Save caller's FORW_STR

	sub	esp,size FORW_STR ; Allocate stack space
	mov	ebp,esp 	; Set up temporary FORW_STR at SS:EBP

; Save EGP registers in FORW_STR

	mov	[ebp].FORW_EDI,edi
	mov	[ebp].FORW_ESI,esi
	mov	[ebp].FORW_EBP,ebp
;;;;;	mov	[ebp].FORW_ESP0,esp ; This one never gets used
	mov	[ebp].FORW_EBX,ebx
	mov	[ebp].FORW_EDX,edx
	mov	[ebp].FORW_ECX,ecx
	mov	[ebp].FORW_EAX,eax

; Caller return address is probably not needed
;;;;;	mov	[ebp].FORW_RET.EDQLO,eip
;;;;;	mov	[ebp].FORW_RET.EDQHI.ELO,cs
;;;;;	mov	[ebp].FORW_EIP,?
	mov	[ebp].FORW_CS,cs

	sldt	[ebp].FORW_LDT	; Save LDT

	pushfd			; Get our flags
	pop	[ebp].FORW_EFL	; Put in structure

	mov	[ebp].FORW_ESP,esp ; Save ESP
	mov	[ebp].FORW_SS,ss ; Save SS

	mov	[ebp].FORW_ES,es ; ...	ES
	mov	[ebp].FORW_DS,ds ; ...	DS
	mov	[ebp].FORW_FS,fs ; ...	FS
	mov	[ebp].FORW_GS,gs ; ...	GS

; SS:EBP ==>	 valid FORW_STR

	sub	esp,@SYMBACK	; Allocate SYMSTK_STR
;;;;	mov	[esp].SYMSTK_GS,gs ; Save GS
	mov	[esp].SYMSTK_DS,ds ; Save DS for CALC_DSESI

	call	SYMTRANS	; Translate symbols
				; Return with CF significant
	lea	esp,[esp+(size FORW_STR)+@SYMBACK] ; Clear temporary FORW_STR
				; and SYMSTK_STR from stack (CF unaffected)

	pop	ebp		; Restore caller's FORW_STR
	jnc	short CMD_TRANSYM_EXIT ; Join common exit code

	mov	MSGOFF,offset DGROUP:SYMBERR ; Save offset of error message

	jmp	short CMD_TRANSYM_ERR ; Join common error exit code


CMD_TRANSYM_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	jmp	short CMD_TRANSYM_ERR ; Join common error exit code


CMD_TRANSYM_OVFERR:
	mov	MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

;;;;;;; jmp	short CMD_TRANSYM_ERR ; Join common error exit code


CMD_TRANSYM_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_TRANSYM_EXIT:
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_TRANSYM endp		; End CMD_TRANSYM procedure
	NPPROC	UPDATE_ADDRHASH -- Update symbol address hash entry
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Update symbol hash table entry # EAX with linear address for
segment/selector, offset, and SYM_FLAG word on stack.

Unlike UPDATE_SYMNHASH, we must de-link an existing address if it
is not already set to -1.

Only line number and regular symbols are hashed; ABS records must
be handled differently, and internal (pathname) records are currently
ignored.

On entry:

DGROUP:EAX ==>	 symbol record to process/update
SS:EBP	   ==>	 FORW_STR

On exit:

nothing.

|

	REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save registers

	mov	ebx,eax 	; Address symbol record

	mov	ax,DGROUP:[ebx].SYM_FLAG ; Get flags
	and	ax,mask $SYMFL_TYP ; Isolate type bits
	cmp	ax,@SYMTYP_DAT shl $SYMFL_TYP ; Izit a normal code/data symbol?
	je	short @F	; Jump if so

	cmp	ax,@SYMTYP_LN shl $SYMFL_TYP ; Izit a line number?
	jne	near ptr UPDATE_ADDRHASH_EXIT ; Jump if not
@@:
	mov	eax,DGROUP:[ebx].SYM_ADDR ; Get old address
	cmp	eax,-1		; Izit free?
	je	short UPDATE_ADDRHASH_DELINKED ; Jump if so

; De-link existing address

	and	eax,ADDRMASK	; Get index into address hash table
	mov	edi,SYMHASH	; Get pointer to hash table
	lea	edi,DGROUP:[edi+eax*4] ; Address entry with EDI
	mov	esi,DGROUP:[edi] ; Get pointer to bucket

	cmp	esi,-1		; Izit free?
	je	short UPDATE_ADDRHASH_DELINKED ; Jump if so

; If it points to us, swap with our SYM_NEXTAH pointer (which
; should be -1 if we don't have anyone after us)

	mov	edx,DGROUP:[ebx].SYM_NEXTAH ; Get our pointer to next address

	cmp	esi,ebx 	; Are we the root?
	jne	short UPDATE_ADDRHASH_DELINKLOOP ; Jump if not

	mov	DGROUP:[edi].EDD,edx ; Blast in to hash table

	jmp	short UPDATE_ADDRHASH_DELINKED ; We're delinked


UPDATE_ADDRHASH_DELINKLOOP:

; ESI points to a symbol record at the beginning of our bucket.
; Walk through the chain until we find ourselves or the end.

	cmp	DGROUP:[esi].SYM_NEXTAH,ebx ; Are we in the chain here?
	jne	short @F	; Jump if not

	mov	DGROUP:[esi].SYM_NEXTAH,edx ; De-link ourselves

	jmp	short UPDATE_ADDRHASH_DELINKED ; We're delinked


@@:
	mov	esi,DGROUP:[esi].SYM_NEXTAH ; Get the next one in the chain

	cmp	esi,-1		; Izit the end?
	jne	short UPDATE_ADDRHASH_DELINKLOOP ; Continue if not
UPDATE_ADDRHASH_DELINKED:
	test	DGROUP:[ebx].SYM_FLAG,@SYMFL_VM ; Izit in VM 86 mode?
	jnz	short @F	; Jump if so

	push	DGROUP:[ebx].SYM_FVEC.FSEL ; Get symbol selector
	call	GETBASE 	; Return with EAX = selector base
	jnc	short UPDATE_ADDRHASH_OFF ; Jump if valid

	xor	eax,eax 	; Use valid address (GETBASE returns -1 = invalid)

	jmp	short UPDATE_ADDRHASH_OFF ; Join common code


@@:
	movzx	eax,DGROUP:[ebx].SYM_FVEC.FSEL ; Get symbol segment
	shl	eax,4-0 	; Convert from paras to bytes
UPDATE_ADDRHASH_OFF:
	add	eax,DGROUP:[ebx].SYM_FVEC.FOFF ; Plus the offset

	mov	DGROUP:[ebx].SYM_NEXTAH,-1 ; Assume we're at the end of the list
	mov	DGROUP:[ebx].SYM_ADDR,eax ; Save resolved address
	and	eax,ADDRMASK	; Mask off bits to index hash entry
	mov	edi,SYMHASH	; Get pointer to hash table
	lea	edi,DGROUP:[edi+eax*4] ; Resolve pointer to hash entry
	mov	esi,DGROUP:[edi].EDD ; Get current root entry

	cmp	esi,-1		; Izit free?
	jne	short @F	; No, we need to walk the chain

	mov	DGROUP:[edi].EDD,ebx ; Root ourselves in the hash table

	jmp	short UPDATE_ADDRHASH_EXIT ; We're done


@@:
	mov	edx,DGROUP:[esi].SYM_NEXTAH ; Get next pointer

	cmp	edx,-1		; Izit the end?
	je	short @F	; Jump if so

	mov	esi,edx 	; Point to next

	jmp	short @B	; Go around again


@@:
	mov	DGROUP:[esi].SYM_NEXTAH,ebx ; Link ourselves in the bucket chain
UPDATE_ADDRHASH_EXIT:
	REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UPDATE_ADDRHASH endp		; End UPDATE_ADDRHASH procedure
	NPPROC	UPDATE_SYMNHASH -- Process/update symbol name hash table
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Hash name string for symbol and link it into name hash table.  We don't
need to de-link, since this is only done when a new symbol is added and
we don't (currently) support deletion of individual symbols.

On entry:
DGROUP:EAX ==>	Symbol record to process

On exit:
Nothing.

|

	REGSAVE <eax,ebx,edx,esi,edi> ; Save registers

	mov	ebx,eax 	; Save symbol record offset
	mov	DGROUP:[ebx].SYM_NEXTNH,-1 ; We always go at the end
	lea	eax,DGROUP:[ebx].SYM_NAMLEN ; Address length byte of string
	call	HASH_STR	; Hash string & return 16-bit hash in AX

	shl	eax,2-0 	; Index DWORD table
	add	eax,SYMNHASH	; Add base of name hash table
	mov	edi,eax 	; Load index register
	mov	esi,DGROUP:[edi].EDD ; Get bucket pointer

	cmp	esi,-1		; Izit empty?
	jnz	short @F	; Jump if not

	mov	DGROUP:[edi].EDD,ebx ; Put us at the head of the chain

	jmp	short UPDATE_SYMNHASH_EXIT ; We're done


@@:

; DGROUP:ESI ==> Next record in bucket

	mov	edx,DGROUP:[esi].SYM_NEXTNH ; Get pointer to next record

	cmp	edx,-1		; Izit the end?
	je	short @F	; Jump if so

	mov	esi,edx 	; Point to next

	jmp	short @B	; Go around again


@@:
	mov	DGROUP:[esi].SYM_NEXTNH,ebx ; Append symbol record ptr to chain
UPDATE_SYMNHASH_EXIT:
	REGREST <edi,esi,edx,ebx,eax> ; Restore registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UPDATE_SYMNHASH endp		; End UPDATE_SYMNHASH procedure
	NPPROC	HASH_STR -- Convert string at DGROUP:EAX to 16-bit hash
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert length-prefixed string to a 16-bit hash value using the hashpjw
algorithm shown below.	HASHPRIME is determined at initialization time from
buckets parameter or from symsize, and may range from 257 to 65287.

extern unsigned int HASHPRIME;

int hashpjw(char *s)
{
 char *p;
 unsigned long h=0, g;

 for (p=s; *p; p++) {
	h = (h << 4) + (unsigned) tolower (*p);
	if (g = (h & 0xf0000000)) {
	  h = h ^ (g >> 24);
	  h = h ^ g;
	}
 }

 return ((int) (h % HASHPRIME));

}

On entry:

DGROUP:EAX ==>	length-prefixed string to hash

On exit:

EAX	=	16-bit hash value (modulo HASHPRIME)

|

	REGSAVE <ebx,ecx,edx,esi> ; Save registers

	cld			; String ops forwards

	mov	esi,eax 	; Address string
	xor	eax,eax 	; Zero to use as dword
	lods	DGROUP:[esi].LO ; Get and skip over length byte
	mov	ecx,eax 	; Copy to count register
	xor	ebx,ebx 	; Initialize hash value to 0

	jecxz	HASH_STR_EXIT	; Bail out if string is empty
HASH_STR_NEXT:
	lods	DGROUP:[esi].LO ; Get and skip over byte value
	call	U32_LOWERCASE	; Convert AL to lowercase
	shl	ebx,4		; Shift over hash value
	add	ebx,eax 	; Add in character
	mov	edx,ebx 	; Save a copy

	and	edx,@NIB7	; Isolate high nybble
	jz	short @F	; Jump if zero

	rol	edx,4		; Move high nybble into low nybble
	xor	ebx,edx 	; Toggle bits
	ror	edx,4		; Restore EDX
	xor	ebx,edx 	; Toggle bits again
@@:
	loop	HASH_STR_NEXT	; Repeat till end
HASH_STR_EXIT:
	xor	edx,edx 	; Prepare to divide EAX
	mov	eax,ebx 	; Get dividend in EAX
	movzx	ebx,HASHPRIME	; Convert to 32-bit divisor
	div	ebx		; EDX contains hash value (remainder)
	movzx	eax,dx		; Return value in AX with high word clear

	REGREST <esi,edx,ecx,ebx> ; Restore registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HASH_STR endp			; End HASH_STR procedure
	NPPROC	SYMHASH_SRCH -- Search symbol address hash table for EAX
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Search address hash table for EAX.  If found, CF=0 and DGROUP:EAX ==> record.

Give preference to non-line number records (e.g. function names) over
line numbers.

On entry:
EAX		Linear address to look for

On exit:
CF=1		Not found

CF=0		Successful; EAX and ALTLINE valid (if @LC2_SRC)
DGROUP:EAX	If CF=0, ==> first matching symbol record (where
		non-line number records are searched first)
ALTLINE 	If CF=0 and @LC2_SRC (source browse mode) set in LC2_FLAG,
		first matching symbol record with line attribute
		(may be the same as returned EAX)
		Not set otherwise

|

	REGSAVE <ebx,ecx,edx>	; Save registers

	cmp	SYMCOUNT,0	; Are there any symbols?
	je	near ptr SYMHASH_SRCH_ERR ; Jump if none

	SELFBREAK SYMHASH_SRCH,10h ; Allow breakpoint if SELFDBG & 10h

	mov	ebx,eax 	; Get linear address
	mov	ecx,eax 	; Save search address
	and	ebx,ADDRMASK	; Mask off hash bits

	shl	ebx,2		; Convert to DWORD index
	add	ebx,SYMHASH	; Add to base of address hash table
	mov	ebx,DGROUP:[ebx].EDD ; Get bucket pointer
SYMHASH_SRCH_NEXT:
	cmp	ebx,-1		; Izit empty?
	je	near ptr SYMHASH_SRCH_ERR ; Jump if so

	cmp	DGROUP:[ebx].SYM_ADDR,ecx ; Izit the one we're looking for?
	je	short SYMHASH_SRCH_DONE ; Jump if so
SYMHASH_SRCH_AGAIN:
	mov	ebx,DGROUP:[ebx].SYM_NEXTAH ; Get pointer to next address hash

	jmp	short SYMHASH_SRCH_NEXT ; Try again


SYMHASH_SRCH_DONE:

; If the symbol found is a line number and we're not to display 'em,
; keep on truckin'.

	test	LC2_FLAG,@LC2_NOLINE ; Not displaying line numbers?
	jz	short @F	; Jump if not

	mov	ax,DGROUP:[ebx].SYM_FLAG ; Get symbol flags
	and	ax,mask $SYMFL_TYP ; Isolate the type

	cmp	ax,@SYMTYP_LN shl $SYMFL_TYP ; Izit a line number?
	je	short SYMHASH_SRCH_AGAIN ; Jump if so
@@:

; If the current symbol name starts with '@' (typically used for an equate)
; and another symbol has the same linear address, use it instead.

	mov	eax,ebx 	; Copy address of matching address
SYMHASH_SRCH_DONE1:
	cmp	eax,-1		; Izit empty?
	je	short SYMHASH_SRCH_DONE2 ; Jump if so

	mov	edx,eax 	; Copy as next address
	mov	eax,DGROUP:[eax].SYM_NEXTAH ; Get pointer to next address hash

	cmp	DGROUP:[edx].SYM_ADDR,ecx ; Duzit it have the same linear addr?
	jne	short SYMHASH_SRCH_DONE1 ; Jump if not

	cmp	DGROUP:[edx].SYM_NAMLEN,0 ; Izit at least one byte long?
	je	short SYMHASH_SRCH_DONE1 ; Jump if not

	cmp	DGROUP:[edx].SYM_NAME.LO[0],'@' ; Izit an equate?
	je	short SYMHASH_SRCH_DONE1 ; Jump if so

	mov	ebx,edx 	; Copy as new pointer
SYMHASH_SRCH_DONE2:
	mov	eax,ebx 	; Return pointer in EAX

; The code at SYMHASH_SRCH_FINDLINE actually searches for a
; line number record _following_ a non-line number so ALTLINE
; can be set correctly in a source browser context.  We really
; need to skip line number records by default, but first we'll
; save ALTLINE.

	test	LC2_FLAG,@LC2_SRC ; Are we in source browse mode?
	jz	short SYMHASH_SRCH_FINDXLINE ; Jump if not

	push	eax		; Save return pointer
SYMHASH_SRCH_FINDLINE:
	mov	ax,DGROUP:[ebx].SYM_FLAG ; Get flags
	and	ax,mask $SYMFL_TYP ; Isolate type bits

	cmp	ax,@SYMTYP_LN shl $SYMFL_TYP ; Izit a line number?
	jne	short @F	; Jump if not

	mov	eax,ebx 	; Assume it is

	cmp	DGROUP:[ebx].SYM_ADDR,ecx ; Izit the right address?
	je	short SYMHASH_SRCH_GOTLINE ; Jump if so
@@:
	sub	eax,eax 	; Assume failure
	mov	ebx,DGROUP:[ebx].SYM_NEXTAH ; Get pointer to next address

	cmp	ebx,-1		; Izit the end?
	jne	short SYMHASH_SRCH_FINDLINE ; Try again
SYMHASH_SRCH_GOTLINE:
	mov	ALTLINE,eax	; Save line record offset (or 0)
	pop	eax		; Restore return pointer
SYMHASH_SRCH_FINDXLINE:

; Find a non-line number symbol

	mov	edx,eax 	; Start with current symbol
	mov	ebx,eax 	; Save valid pointer
SYMHASH_SRCH_NEXTSYM:
	cmp	DGROUP:[edx].SYM_ADDR,ecx ; Izit the right address?
	jne	short SYMHASH_SRCH_XLINE ; Jump if not - we're done

	mov	ax,DGROUP:[edx].SYM_FLAG ; Get flags
	and	ax,mask $SYMFL_TYP ; Isolate type bits

	cmp	ax,@SYMTYP_LN shl $SYMFL_TYP ; Izit a line number?
	je	short @F	; Jump if so (we're skipping it)

	mov	ebx,edx 	; Save pointer

; Uncommenting this will cause us to return the _first_ non-source line symbol.
; As it stands with the jmp short commented out, we'll return the _last_ one.

;;;;;;; jmp	short SYMHASH_SRCH_XLINE ; Join common exit

@@:
	mov	edx,DGROUP:[edx].SYM_NEXTAH ; Get pointer to next symbol

	cmp	edx,-1		; Izit the end?
	jne	short SYMHASH_SRCH_NEXTSYM ; Go around again if not
SYMHASH_SRCH_XLINE:
	mov	eax,ebx 	; Set return value

	clc			; Indicate success

	jmp	short SYMHASH_SRCH_EXIT ; Join common exit code (note CF=0)


SYMHASH_SRCH_ERR:
	stc			; Indicate failure
SYMHASH_SRCH_EXIT:
	REGREST <edx,ecx,ebx>	; Restore registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SYMHASH_SRCH endp		; End SYMHASH_SRCH procedure
	NPPROC HASH_INIT -- Initialize symbol address and name hash tables
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Mark all hash table entries as unused.	Must be done before adding the
first symbol when SYMCOUNT = 0.  This covers both the initial state
after startup as well as reset condition (after flush function is called).

|

	REGSAVE <eax,ecx,edi,es> ; Save

	push	ds		; Get DGROUP
	pop	es		; Use ES: for stos operations
	assume	es:DGROUP	; Tell the assembler

	mov	edi,SYMHASH	; Start of symbol address hash table
	mov	ecx,ADDRMASK	; Get mask (number of dwords - 1)
	inc	ecx		; Increment to get number of dwords
	mov	eax,-1		; Mark buckets as empty

    rep stos	DGROUP:[edi].EDD ; Initialize table

	mov	edi,SYMNHASH	; Start of name hash table
	movzx	ecx,HASHPRIME	; Get number of dword elements in table

    rep stos	DGROUP:[edi].EDD ; Initialize name table

	REGREST <es,edi,ecx,eax> ; Restore
	assume	es:nothing	; Tell the assembler

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HASH_INIT endp			; End HASH_INIT procedure
	NPPROC	CMD_PROXSRCH -- Change proximity search parameters
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Proximity search command

PS range [gran]

gran is a byte value specifying the new granularity for PROXSRCH.
range is a byte value expressing the new range in units of gran.

The product of gran * range may not exceed 255.
If either gran or range is 0, proximity searching for symbols is
disabled.

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	pushad			; Save all EGP registers

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_PROXSRCH_SYNTERR ; Yes, treat as error

; Parse new range
; Convert the con/reg at DS:ESI to binary

	call	PARSE_LVAL	; Parse command line for lefthand value
	jc	near ptr CMD_PROXSRCH_OVFERR ; Jump if too large

	cmp	eax,000000FFh	; Izit within limits?
	ja	near ptr CMD_PROXSRCH_OVFERR ; Jump if too large

	mov	bh,al		; Save range value
	mov	bl,PROXSRCH.LO	; Get existing granularity

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_PROXSRCH_TEST ; Yes, check product

; Parse new granularity (optional)
; Convert the con/reg at DS:ESI to binary

	call	PARSE_LVAL	; Parse command line for lefthand value
	jc	near ptr CMD_PROXSRCH_OVFERR ; Jump if too large

	cmp	eax,000000FFh	; Izit within limits?
	ja	near ptr CMD_PROXSRCH_OVFERR ; Jump if too large

	mov	bl,al		; Save granularity value

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	cmp	al,0		; Izit end-of-the-line?
	jne	short CMD_PROXSRCH_SYNTERR ; Treat excess on command line as error
CMD_PROXSRCH_TEST:
	mov	al,bh		; Get range
	mul	bl		; AX = range * granularity

	or	ah,ah		; Izit > 255?
	jnz	short CMD_PROXSRCH_OVFERR ; Jump if too large

	or	ax,ax		; Is either granularity or range 0?
	jz	short @F	; Jump if so

	mov	ax,bx		; Get range & granularity
@@:
	mov	PROXSRCH,ax	; Set range and granularity
	or	LCL_FLAG,@LCL_REDI ; Force redisplay

	jmp	short CMD_PROXSRCH_EXIT ; Join common exit code


CMD_PROXSRCH_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	jmp	short CMD_PROXSRCH_ERR ; Join common error exit code


CMD_PROXSRCH_OVFERR:
	mov	MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

;;;;;;; jmp	short CMD_PROXSRCH_ERR ; Join common error exit code


CMD_PROXSRCH_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_PROXSRCH_EXIT:
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_PROXSRCH endp		; End CMD_PROXSRCH procedure
	NPPROC	CMD_LOADSYM -- Load symbol table (SSF format)
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Load symbols command

LS filename [fixup]

If PL0 DPMI services exist and DOS isn't busy, load the specified
symbol file from disk using DOS services via DPMI translation.

If a fixup is specified, add to all VM segment values.

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	pushad			; Save all EGP registers

	mov	SYM_FH,-1	; Initialize file hande (not opened)

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_LOADSYM_SYNTERR ; Yes, treat as error

; Parse file pathname
; Copy string at DS:ESI to SYM_FNAME

	lea	edi,SYM_FNAME	; Offset for filename
CMD_LOADSYM_NEXTC:
	lods	DGROUP:[esi].LO ; Get byte

	cmp	al,' '          ; Izit whitespace?
	je	short @F	; Jump if so

	cmp	al,TAB		; Izit a tab?
	jne	short CMD_LOADSYM_PUTC ; Jump if not
@@:
	sub	al,al		; Force end of string
CMD_LOADSYM_PUTC:
S32	stos	SYM_FNAME[edi]	; Save byte

	or	al,al		; Izit the end?
	jnz	short CMD_LOADSYM_NEXTC ; Jump if not

	mov	VMSEG_FIXUP,0	; Initialize VM segment fixup to 0

	dec	esi		; Back off to last character

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit the end?
	je	short CMD_LOADSYM_PROCESS ; Jump if so

	call	PARSE_LVAL	; Parse command line for lefthand value
	jc	near ptr CMD_LOADSYM_OVFERR ; Jump if too large

	cmp	eax,0000ffffh	; Izit within limits for a VM segment?
	ja	near ptr CMD_LOADSYM_OVFERR ; Jump if too large

	mov	VMSEG_FIXUP,ax	; Save fixup value
CMD_LOADSYM_PROCESS:
	call	DOS_AVAIL	; Are DOS services under DPMI available?
	jc	near ptr CMD_LOADSYM_ERR ; Jump if not (message text set)

	lea	edx,SYM_FNAME	; Get filename
	sub	al,al		; Set file sharing/access mode to compatible/RO
	mov	ah,@OPENF2	; Open file at DS:DX
	FINTD	PL0_INT21	; Return file handle in AX
	jc	near ptr CMD_LOADSYM_FILERR ; Jump if open failed

	mov	SYM_FH,ax	; Save file handle
	mov	bx,ax		; Prepare to read
	xor	eax,eax 	; Zero to use as dword
	mov	ecx,size SSF_STR ; Bytes to read
	lea	edx,SYM_READBUF ; Buffer to read into
	mov	ah,@READF2	; Read into buffer at DS:eDX
	FINTD	PL0_INT21	; Return bytes read in eAX
	jc	near ptr CMD_LOADSYM_FILERR ; Error occurred; close handle

; Check file header data

	cmp	SYM_READBUF.SSF_SIG,@SSF_SIG ; Izit an SSF file?
	jne	near ptr CMD_LOADSYM_NOTSYMERR ; Jump if not

	mov	eax,SYM_READBUF.SSF_COUNT ; Get number of records
	or	eax,eax 	; Izit non-zero?
	jz	near ptr CMD_LOADSYM_EXIT ; Jump if empty

	mov	LSYM_symcnt,eax ; Save total record count
	mov	LSYM_cnt,0	; Initialize count of bytes remaining

	cmp	SYM_READBUF.SSF_VER,@SSF_CVER ; Izit minimum version supporting
				; flags and data pointer?
	jnb	short @F	; Jump if so

	mov	SYM_READBUF.SSF_FLAGS,0 ; Assume defaults
	mov	SYM_READBUF.SSF_DATA,@SSF_OLDDATA ; Use hard-coded offset 0Ah
@@:
	movzx	edx,SYM_READBUF.SSF_DATA.ELO ; Low word of seek offset
	movzx	ecx,SYM_READBUF.SSF_DATA.EHI ; High word of seek offset
	mov	bx,SYM_FH	; File handle
	mov	al,0		; Seek from beginning of file
	mov	ah,@MOVFP2	; Move file pointer for BX to CX:DX
	FINTD	PL0_INT21	; Return with new file pointer in DX:AX
	jc	near ptr CMD_LOADSYM_FILERR ; Error occurred

	test	SYM_READBUF.SSF_FLAGS,@SSFFL_FLUSH ; Is a flush requested?
	jz	short @F	; Jump if not

	call	SYMFLUSH	; Reset symbol table
@@:
	mov	SYMAPPND_MODE,0 ; Assume normal append
	test	SYM_READBUF.SSF_FLAGS,@SSFFL_RAW ; Are raw appends requested?
	jz	short @F	; Jump if not

	mov	SYMAPPND_MODE,1 ; Raw appends
@@:
	mov	ecx,@SYM_READBUFSIZ ; Bytes to read
	lea	edx,SYM_READBUF ; Address start of buffer
CMD_LOADSYM_GETBLOCK:
	xor	eax,eax 	; Zero to use as dword
	mov	bx,SYM_FH	; File handle
	mov	ah,@READF2	; Read from file BX into DS|(E)DX
	FINTD	PL0_INT21	; Return with bytes read in AX
	jc	near ptr CMD_LOADSYM_FILERR ; File read error

	or	eax,eax 	; Izit end of file?
	jz	near ptr CMD_LOADSYM_EXIT ; Then we're done

	add	LSYM_cnt,eax	; Add bytes read to bytes remaining
	mov	ecx,LSYM_cnt	; Keep bytes remaining in CX
	mov	LSYM_symsub,0	; Clear record subtotal

	lea	esi,SYM_READBUF ; Address start of buffer
	mov	ax,VMSEG_FIXUP	; Fixup value for VM segments

; Trundle through the records, fixing up VM segments.
; Keep track of the number of records for the SWAT API call.

CMD_LOADSYM_FIXNEXT:
	mov	bx,DGROUP:[esi].ISYM_FLAG ; Grab flags
	test	bx,mask $SYMFL_VM ; Izit a real mode segment?
	jz	short CMD_LOADSYM_SKIP ; Jump if not

	and	bx,mask $SYMFL_TYP ; Mask off record type field
	cmp	bx,@SYMTYP_ABS shl $SYMFL_TYP ; Izit an ABS record?
	je	short CMD_LOADSYM_SKIP ; Jump if so

	add	DGROUP:[esi].ISYM_FVEC.FSEL,ax ; Fixup VM segment
CMD_LOADSYM_SKIP:
	inc	LSYM_symsub	; Bump record count
	movzx	ebx,DGROUP:[esi].ISYM_SYMLEN ; Get length of name
	add	ebx,size ISYM_STR ; Add length of structure
	add	esi,ebx 	; Skip to next record
	sub	ecx,ebx 	; Keep track of remaining bytes

	cmp	ecx,(size ISYM_STR) + 1 ; Izit the minimum size?
	jb	short @F	; Jump if not

	dec	LSYM_symcnt	; Adjust total counter
	jz	short @F	; Jump if end

	movzx	ebx,DGROUP:[esi].ISYM_SYMLEN ; Get length of next name
	add	ebx,size ISYM_STR ; Add structure length

	cmp	ecx,ebx 	; Izit all there?
	jnc	short CMD_LOADSYM_FIXNEXT ; Jump if not
@@:

; Add LSYM_symsub records via SYMAPPND_COM

	REGSAVE <ecx,esi>	; Save

	mov	ecx,LSYM_symsub ; Get number of records
	jecxz	short @F	; Jump if none
	mov	esi,SWATDATA	; Get base for DGROUP
	add	esi,offset DGROUP:SYM_READBUF ; Get starting offset
	call	SYMAPPND_COM	; Add to symbol table; ECX = # not added
				; Error code in AH if CF set
	or	LCL_FLAG,@LCL_REDI ; Force redisplay
@@:
	REGREST <esi,ecx>	; Restore

	cmp	LSYM_symcnt,0	; Do we have any left?
	jz	short CMD_LOADSYM_EXIT ; Jump if not

; We may have part of a record.  We need to move it to the beginning of the
; buffer and reset the read pointer so that the data read in will be appended.
; This convoluted scheme ensures that we always have a record-granular
; buffer without doing time-consuming disk seeks.

	lea	edi,SYM_READBUF ; Assume start of buffer
	mov	ebx,ecx 	; Save number of bytes
	mov	LSYM_cnt,ecx	; Reinitialize bytes remaining
	jecxz	short CMD_LOADSYM_CALCBUF ; Jump if nothing left

; Move ECX bytes from DS:ESI to beginning of buffer, leaving
; DS:EDI ==> location in buffer for next file read.

S32 rep movs	<DGROUP:[edi].LO,DGROUP:[esi].LO> ; Move it

CMD_LOADSYM_CALCBUF:

; DS:EDI ==> at or past buffer start.  Move it into DS:eDX for file read.
; Put @SYM_READBUFSIZ-EBX in ECX for bytes to read.
	mov	edx,edi 	; Load EDX for read
	mov	ecx,@SYM_READBUFSIZ ; Attempt to fill buffer
	sub	ecx,ebx 	; Subtract bytes already in buffer

	jmp	near ptr CMD_LOADSYM_GETBLOCK ; Get next chunk of file


CMD_LOADSYM_NOTSYMERR:
	mov	MSGOFF,offset DGROUP:NOTSYM_ERR ; Save offset of error message

	jmp	short CMD_LOADSYM_ERR ; Join common close and exit error


CMD_LOADSYM_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	jmp	short CMD_LOADSYM_ERR ; Join common error exit code


CMD_LOADSYM_FILERR:
	mov	MSGOFF,offset DGROUP:FILERR ; Save offset of error message

	jmp	short CMD_LOADSYM_ERR ; Join common error exit code


CMD_LOADSYM_OVFERR:
	mov	MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

;;;;;;; jmp	short CMD_LOADSYM_ERR ; Join common error exit code


CMD_LOADSYM_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_LOADSYM_EXIT:
	pushfd			; Save for a moment

; Close file if opened
	mov	bx,SYM_FH	; Get file handle to close
	cmp	bx,-1		; Is file handle unused?
	je	short @F	; Jump if so

	mov	ah,@CLOSF2	; Close handle
	FINTD	PL0_INT21	; Ignore result
@@:
	popfd			; Restore

	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_LOADSYM endp		; End CMD_LOADSYM procedure
	NPPROC	DOS_AVAIL -- Test for DPMI/DOS services available
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Test for DOS services via DPMI

If DPMI services exist and we requested a PL0 HPDA from the DPMI
server, and if the current value of the InDOS flag is 0, return
with CF=0 to indicate that it is safe to make DOS calls using
PL0_INT21.

On entry:
Nothing.

On exit:

CF	=	0 if OK to use PL0_INT21
	=	1 otherwise
MSGOFF	=	offset of error message if CF=1

|

	REGSAVE <ebx>		; Save

	test	ARG_FLAG,@ARG_DPMI ; Was SYMLOAD specified in profile?
	jz	short ERR_NODPMI ; Jump if not

	test	SWATINI.MD_ATTR,@MD_DPMI ; Did we request a PL0 HPDA?
	jz	short ERR_NODPMI ; Jump if not

	test	HOSTFLAGS,@HOSTFLAGS_DPMI or @HOSTFLAGS_DPMI32 ; Does host provide 32-bit DPMI services?
	jz	short ERR_NODPMI ; Jump if not

	mov	ebx,LaINDOS	; Get offset within AGROUP of DOS busy flag

	push	gs		; Save for a moment

	mov	gs,COMMON.FILE_4GB ; Get all data selector
	assume	gs:AGROUP	; Tell the assembler

	cmp	AGROUP:[ebx].LO,0 ; Is DOS busy?

	pop	gs		; Restore
	assume	gs:nothing	; Tell the assembler

	jne	short ERR_DOSBUSY ; Jump if DOS busy

	jmp	short DOS_AVAIL_EXIT ; Join common exit code (note CF=0)


ERR_NODPMI:
	mov	MSGOFF,offset DGROUP:NODPMI_ERR ; Save offset of error message

	jmp	short DOS_AVAIL_ERR ; Join common error exit code


ERR_DOSBUSY:
	mov	MSGOFF,offset DGROUP:DOSBUSY_ERR ; Save offset of error message

;;;;;;; jmp	short DOS_AVAIL_ERR ; Join common error exit code


DOS_AVAIL_ERR:
	stc			; Indicate failure, message in MSGOFF
DOS_AVAIL_EXIT:
	REGREST <ebx>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOS_AVAIL endp			; End DOS_AVAIL procedure
	NPPROC	CMD_FLUSHTAB -- Flush symbol table
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Flush symbols command

FS

Clear the symbol table.

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0

|

	call	SYMFLUSH	; Flush symbol table

	or	LCL_FLAG,@LCL_REDI ; Force redisplay

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_FLUSHTAB endp		; End CMD_FLUSHTAB procedure
	FPPROC PL0_INT21 -- Call Int 21 from PL0
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:DGROUP
COMMENT|

Because we're currently running at PL0, calling DPMI services within
MAX will not generate a ring transition, hence MAX's stack will not
become active.

Since there is no way to force a SS:eSP reload on a task switch,
we take the law into our own hands here by getting the task register's
base address, finding the PL0 SS:eSP, and loading our stack
registers before calling Int 21.

We have to do a bit of hocus-pocus on return to restore our own
stack.

On entry:
Registers as in Int 21 call
IF=0	(use FINT PL0_INT21)
SS:EBP ==> FORW_STR

On exit:
Registers as in exit from Int 21 call

|

	REGSAVE <OLD_EAX,OLD_BX,OLD_DS> ; Save for recursion

	mov	OLD_DS,ds	; Save DS on entry
	mov	OLD_BX,bx	; Save BX
	mov	OLD_EAX,eax	; Save EAX

; If we are to call a DOS function which requires interaction with
; any hardware interrupt-driven device (like a disk read), we need
; to enable the IRQ service routines we masked off on entry to SWATTER.
; Here we get the current state of the PICs and stash it away...

	in	al,@IMR 	; Get current master interrupt mask register
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	ah,al		; Save to restore later

	test	SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
	jnz	short SAVE_IMR_NOXT1 ; Yes, so there's no slave controller

	in	al,@IMR2	; Get current slave IMR
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
SAVE_IMR_NOXT1:
	push	eax		; Save IMRS to restore later

; To simulate the SS:eSP MAX assumes it should have as a result of
; the PMI21 call gate task switch, we need to snatch the expected
; SS:eSP from the TSS.

	str	ax		; Get current TSS selector
	push	ax		; Pass selector to GETBASE
	call	GETBASE 	; Return with EAX = selector base
				; Ignore error condition in CF
; Now we must swap back the original IRQ handlers in the IDT.

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	call	REST_IRQS	; Set up IDT for hardware interrupts

; Save previous contents of OLDSTK_FVEC in case we're reentrant

	push	OLDSTK_FVEC.FSEL ; Save stack selector
	push	OLDSTK_FVEC.FOFF ;   "     "  offset

; Save our current stack pointers after skipping the DS:EAX that will be
; returned from the Int 21h call and immediately saved on the stack.

	sub	esp,size PTR32_STR ; Allocate space to restore DS:EAX on return
	mov	OLDSTK_FVEC.FSEL,ss ; Save current stack
	mov	OLDSTK_FVEC.FOFF,esp ;	     "

	call	REST_IMR	; Re-enable hardware interrupts

; Special case: if we're using SWAT to debug MAX, and the interrupted
; code was ALREADY using MAX's SS, we DON'T want to reset the stack.

	mov	ds,COMMON.FILE_4GB ; Address AGROUP
	assume	ds:AGROUP	; Tell the assembler

	mov	bx,AGROUP:[eax].TSS_SS0 ; Get SS from TSS
	cmp	bx,[ebp].FORW_SS ; Were we (perhaps) invoked from within MAX?
	jne	short @F	; Jump if not

; Since a task switch will not occur, we have to blast in the PL0
; SS:ESP before making the INT 21 call.  MAX was active, so we
; use the SS:eSP which were active when SWAT interrupted.

	lss	esp,[ebp].FORW_ESP.EDF ; Get MAX's stack ptr
	assume	ss:nothing

	jmp	short PL0_INT21_STACKOK ; Join common code


; Get PL0 SS:eSP from TSS
@@:
	lss	esp,AGROUP:[eax].TSS_ESP0.EDF ; Get PL0 stack ptr from TSS
	assume	ss:nothing	; Tell the assembler
PL0_INT21_STACKOK:
	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	mov	eax,OLD_EAX	; Restore EAX on entry
	mov	bx,OLD_BX	;    "    BX
	mov	ds,OLD_DS	;    "    DS
	assume	ds:nothing	; Tell the assembler

	DOSCALL0		; Call Int 21
				; Return with CF significant

	push	eax		; Save
	PUSHW	ds		; Save

	pushfd			; Preserve flags
	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it
	popfd			; Restore flags

; We have saved EAX and DS on the stack.  Before we can pop them
; we must copy them from the MAX stack to the SWAT stack, then
; restore our old SS:eSP.

	lds	eax,OLDSTK_FVEC ; Get old SS:ESP
	assume	ds:DGROUP	; Tell the assembler

	pop	ds:[eax].ELO	; Move selector to SWAT's stack
	pop	ds:[eax+2].EDD	; Move offset to SWAT's stack

	lss	esp,OLDSTK_FVEC ; Restore SWAT stack
	assume	ss:DGROUP	; Tell the assembler

; Swap IRQ handlers back out

	pushfd			; Save flags
	call	SAVE_IRQS	; Save IDT hardware int handlers
	popfd			; Restore

	POPW	ds		; Restore DS returned by Int 21
	assume	ds:nothing	; Tell the assembler

	pop	eax		; Restore EAX returned by Int 21

	pop	OLDSTK_FVEC.FOFF ; Restore previous OLDSTK_FVEC offset
	pop	OLDSTK_FVEC.FSEL ; Restore previous OLDSTK_FVEC selector

; We saved the IMR values on the stack way back there.	Get them
; while preserving the contents of AX (return value from Int 21).

	xchg	eax,[esp]	; Restore old IMRs & save AX

	pushfd			; Save flags

	xchg	ah,al		; Put master PIC value in AL
	out	@IMR,al 	; Tell the PIC about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	test	SWATINI.MD_ATTR,@MD_XT ; Running on an XT?
	jnz	short REST_IMR_EXIT ; Yes, no second controller

	mov	al,ah		; Copy original slave IMR value
	out	@IMR2,al	; Tell the PIC about it
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
REST_IMR_EXIT:

	popfd			; Restore

	pop	eax		; Restore EAX on return

	REGREST <OLD_DS,OLD_BX,OLD_EAX> ; Restore previous contents

; Now we must stash the contents of the flags register on the stack
; so that when we return to the caller via IRET, the return flags
; from the Int 21 call will be restored.  Note that this procedure
; is a far procedure.  The interrupt flag state needs to be cleared,
; as it was set on entry.  The NT bit is also cleared so the IRET
; does not generate a task switch.

PL0_INT21_STR	struc
		dw	 ?	; Caller's AX
		dq	 ?	; Return address
PL0_INT21_EFL	dd	 ?	; Return flags
PL0_INT21_STR	ends

	push	ax		; Save return value

	pushf			; Save flags to return
	pop	ax		; Get flags in AX
	and	ax,not ((mask $NT) or (mask $IF)) ; IF=0, NT=0

	and	[esp].PL0_INT21_EFL.ELO,mask $IF ; Isolate caller's IF
	or	[esp].PL0_INT21_EFL.ELO,ax ; Include return flags

	pop	ax		; Restore AX

	iretd			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PL0_INT21	endp		; End PL0_INT21 procedure
	NPPROC	CMD_QUERYSYMB -- Find Nearest Symbol
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Find nearest symbol

qs addr

|

	pushad			; Save all EGP registers

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	cmp	al,0		; Izit end-of-the-line?
	je	short CMD_QUERYSYMB_SYNTERR ; Jump if so

	call	PARSE_ADDR	; Parse DS:ESI for address
	jc	near ptr CMD_QUERYSYMB_ERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)
	call	IZITEOL 	; Izit end-of-the-line?
	jne	short CMD_QUERYSYMB_SYNTERR ; Jump if not

; Find the end of the command line so we can append the symbol to it

	call	ENDOF_CMDLINE	; Return with ES:EDI ==> end of the command line

@QUERYSYMB_MAXOFF equ 1000000h	; Maximum offset to nearest symbol
@QUERYSYMB_OFFLEN equ 1+8	; Length of '+nnnnnnnn'

	lea	esi,CMD_LINE	; Get offset to command line
	add	esi,CMD_LINE_LEN ; Plus the total length
	sub	esi,edi 	; Less the last char to get remaining length
	sub	esi,@QUERYSYMB_OFFLEN ; Make room for '+nnnnnnnn'

; Use linear address

	add	eax,edx 	; Add to get linear address

; Find the nearest symbol name to the address

	PUSHD	0		; Pass selector as dword
	push	eax		; ...  offset (linear address)
	push	@QUERYSYMB_MAXOFF ; ... maximum offset to symbol
	push	offset DGROUP:MSG_FNS2[1] ; Pass offset to symbol offset
	push	offset DGROUP:MSG_FNS1 ; ...		       save area
	push	ecx		; Pass maximum length of ...
	call	FindAddr	; Find the address
				; Return with EAX = length copied
	jc	short CMD_QUERYSYMB_SYMERR ; Jump if not found

; Append the offset to the symbol

	lea	esi,MSG_FNS2	; Get offset of '+nnnnnnnn'
	lea	edi,MSG_FNS1[eax] ; Get offset of end of symbol

	mov	ecx,@QUERYSYMB_OFFLEN ; Get length of '+nnnnnnnn'
S32 rep movs	<MSG_FNS1[edi],MSG_FNS2[esi]> ; Copy to command line

; Copy the symbol+nnnnnnnn to the command line

	lea	esi,MSG_FNS	; Get offset of source
	lea	ecx,[eax+@QUERYSYMB_OFFLEN+MSG_FNS_HDRLEN] ; Get length of data

; Find the end of the command line so we can append the symbol to it

	call	ENDOF_CMDLINE	; Return with ES:EDI ==> end of the command line

S32 rep movs	<CMD_LINE[edi],MSG_FNS[esi]> ; Copy to command line

	call	DISP_CMDLINE	; Display the command line
	call	PURGE_KBUFF	; First purge the keyboard buffer
	call	GETNDKEY	; Get non-destructive key

	clc			; Indicate all went well

	jmp	short CMD_QUERYSYMB_EXIT ; Join common exit code


CMD_QUERYSYMB_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	jmp	short CMD_QUERYSYMB_ERR ; Join common error exit code


CMD_QUERYSYMB_SYMERR:
	mov	MSGOFF,offset DGROUP:SYMERR ; Save offset of error message

;;;;;;; jmp	short CMD_QUERYSYMB_ERR ; Join common error exit code


CMD_QUERYSYMB_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_QUERYSYMB_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_QUERYSYMB endp		; End CMD_QUERYSYMB procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_SYM module
