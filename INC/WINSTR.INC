;' $Header:   P:/PVCS/MAX/INC/WINSTR.INV   1.3   15 Jun 1998 15:59:52   BOB  $
;
; WINSTR.INC
;
; Windows structures and equates
;


GH32_STR struc			; Global Heap

	dw	?		; Set to non-zero enable heap checking
	dw	?		; Set to non-zero to prevent heap compaction
GH32_GHCNT dw	?		; # entries in the global heap
GH32_OFF1ST dd	?		; Offset of 1st Global Arena

; There's more

GH32_STR ends


GA32_STR struc			; Global heap entry

GA32Next dd	?		; Next Global Arena
GA32Prev dd	?		; Prev ...
GA32Base dd	?		; Base address
GA32Size dd	?		; Block size in bytes
GA32Handle dw	?		; Handle
GA32Owner dw	?		; Owner (see GA32Ownerxxx for special values)

; There's more

GA32_STR ends

@GA32OwnerSentinel equ -1	; First and last owner entry
@GA32OwnerDPMI	   equ -4	; Allocated from DPMI


@MPI_SIG equ	'TP'            ; MakeProcInstance signature
@TDB_SIG equ	'DT'            ; TDB signature

TDB_STR struc			; Task Database

TDB_NEXT dw	?		; 00:  Selector of next task (0=end)
TDB_STKVEC dd	?		; 02:  SS:SP of the task when last switched away from
TDB_NEVENTS dw	?		; 06:  # events waiting for tthe task
TDB_PRIORITY db ?		; 08:  Priority
	db	?		; 09:  Unused???
	dw	?		; 0A:  Unused???
TDB_SEL dw	?		; 0C:  This task's selector
	dw	?		; 0E:  Unused???
	dw	?		; 10:  Unused???
	dw	?		; 12:  Unused???
TDB_FLDCW dw	?		; 14:  80x87 control word
TDB_FLAGS dw	?		; 16:  Flags (See TDBF_xxx below)
TDB_ERRFL dw	?		; 18:  Error flags (See SEM_xxx below)
TDB_MINVER dw	?		; 1A:  Minimum version of Windows to run this task
TDB_DGR dw	?		; 1C:  Instance handle (DGROUP) for this task
TDB_MOD dw	?		; 1E:  Module handle for task
TDB_TMQ dw	?		; 20:  Selector for task message queue
TDB_PARENT dw	?		; 22:  Selector of TDB parent
TDB_ASHFL dw	?		; 24:  Flags for TDB_ASH
TDB_ASH dd	?		; 26:  Application Signal Handler address
TDB_USH dd	?		; 2A:  User Signal handler address
TDB_GDNH dd	?		; 2E:  GlobalDiscard() notification handler
TDB_INT00 dd	?		; 32:  Interrupt 00h address
TDB_INT02 dd	?		; 36:  ...	 02h ...
TDB_INT04 dd	?		; 3A:  ...	 04h ...
TDB_INT06 dd	?		; 3E:  ...	 06h ...
TDB_INT07 dd	?		; 42:  ...	 07h ...
TDB_INT3E dd	?		; 46:  ...	 3Eh ...
TDB_INT75 dd	?		; 4A:  ...	 75h ...
TDB_COMPFL dd	?		; 4E:  Application compatibility flags
TDB_TIBSEL dw	?		; 52:  Thread Information Block selector
TDB_LATDB dd	?		; 54:  Linear address of Thread Database
TDB_HTASK16 dw	?		; 58:  For Win16 tasks, DGROUP handle
	db	6 dup (?)	; 5A:  Unused???
TDB_PSPSEL dw	?		; 60:  Selector of PSP
TDB_DTA dd	?		; 62:  Ptr to DTA
TDB_CURDRV db	?		; 66:  Current drive of task + 80h (origin-80)
TDB_CURDIR db	65 dup (?)	; 67:  Current directory of task
	dw	?		; A8:  Unused???
TDB_HNEXT dw	?		; AA:  hTask to be scheduled next
TDB_DLLCHAIN dd ?		; AC:  Ptr to chain of referenced DLLs
TDB_CSALIAS dw	?		; B0:  Code selector alias
TDB_MPISEL dw	?		; B2:  Selector to additional MakeProcInstance thunks
TDB_MPISIG dw	@MPI_SIG	; B4:  'PT' signature for MakeProcInstance thunks
	dw	?		; B6:  Unused???
TDB_MPINEXT dw	?		; B8:  Next available MakeProcInstance thunk
TDB_MPITHUNKS db (7*8) dup (?)	; BA:  Space for up to seven MakeProcInstance thunks
TDB_MODNAME db	8 dup (?)	; F2:  ASCIIZ Module name for task, no terminating zero if full
TDB_TDBSIG dw	@TDB_SIG	; FA:  TDB signature
	dd	?		; FC:  Unused???
TDB_PSP db	100h dup ()	;100:  PSP

TDB_STR ends

TDBF_WINOLDAP equ	0001h
TDBF_NEWTASK  equ	0008h
TDBF_WIN32    equ	0010h

SEM_FAILCRITICALERRORS		equ 0001h
SEM_NOGPFAULTERRORBOX		equ 0002h
SEM_NOALIGNMENTFAULTEXCEPT	equ 0004h
SEM_NOOPENFILEERRORBOX		equ 8000h


; Task Message Queue

TMQ_STR struc

TMQ_NEXT dw	?		; 00:  Next message queue
TMQ_HTASK dw	?		; 02:  Task handle
TMQ_OHEAD dw	?		; 04:  Offset in DGROUP of head of QUEREMSG
TMQ_OTAIL dw	?		; 06:  ...		   tail ...
TMQ_OMSG  dw	?		; 08:  ...		   a message ???
TMQ_NMSGS dw	?		; 0A:  # messages in queue
	  db	?		; 0C:  Reserved
TMQ_VSIG  db	'MJT'           ; 0D:  Vanity signature
TMQ_OPERQ dw	?		; 10:  Offset in DGROUP of PERQUEUEDATA struc
	  dd	?		; 12:  Reserved
TMQ_OPROC dw	?		; 16:  Offset in DGROUP of QUEUEPROCESSDATA
	  dd	?,?,?		; 18:  Reserved
TMQ_MSGTIME dd	?		; 24:  Message time
TMQ_MSGPOS  dd	?		; 28:  Message position (X-, Y-coordinates)
	  dw	?		; 2C:  Reserved
TMQ_OLAST dw	?		; 2E:  Offset in DGROUP of last message retrieved
TMQ_EXTRA dd	?		; 30:  Data retrieved by call to GetMessageExtraInfo ()
	  dd	?,?		; 34:  Reserved
TMQ_THRID dd	?		; 3C:  Thread ID
	  dw	?		; 40:  Reserved
TMQ_EXPVER dw	?		; 42:  Expected Windows version
	  dd	?		; 44:  Reserved
TMQ_CHGBITS dw	?		; 48:  Change bits:  QS_xxx
TMQ_WAKEBITS dw ?		; 4A:  Wake bits
TMQ_WAKEMASK dw ?		; 4C:  Wake mask
	   dw	?		; 4E:  Reserved
TMQ_HQSEND dw	?		; 50:  Handle of sending thread
	   dd	?		; 52:  Reserved
TMQ_SIG   db	'HQ'            ; 56:  Signature

TMQ_STR ends



@MOD_SIG equ	'EN'            ; Module signature

MOD_STR struc			; Module

MOD_MODSIG dw	@MOD_SIG	; 00:  Module signature
MOD_USECNT dw	?		; 02:  Usage count
MOD_NPENTRY dw	?		; 04:  Near ptr to entry table
MOD_NEXT dw	?		; 06:  Selector of next module (0=end)
MOD_NPSEGDRP dw ?		; 08:  Near ptr to segment table entry for DGROUP
MOD_NPLFI dw	?		; 0A:  Near ptr to load file info (LFIxxSTRUCT)
MOD_FLAGS dw	?		; 0C:  Module flags (based on NE flags)
MOD_LSEG  dw	?		; 0E:  Logical segment # of DGROUP (1-based)
MOD_IHEAP dw	?		; 10:  Initial local heap byte size
MOD_ISTACK dw	?		; 12:  Initial stack byte size
MOD_CSIP  dd	?		; 14:  Starting CS:IP
MOD_SSSP  dd	?		; 18:  Starting SS:SP
MOD_NSEGS dw	?		; 1C:  # segments in segment table
MOD_NMREF dw	?		; 1E:  # entries in module ref table
MOD_SNRNT dw	?		; 20:  Size of non-resident names table on disk
MOD_NPSEG dw	?		; 22:  Near ptr to segment table
MOD_NPRES dw	?		; 24:  Near ptr to resource table
MOD_NPRNAM dw	?		; 26:  Near ptr to resident name table
MOD_NPMREF dw	?		; 28:  Near ptr to module reference table
MOD_NPINAM dw	?		; 2A:  Near ptr to imported names table
MOD_ONRNT dd	?		; 2C:  File offset of non-resident name table
MOD_NMOVE dw	?		; 30:  # moveable entries in entry table
MOD_SHIFT dw	?		; 32:  Alignment shift count
MOD_TTFNT dw	?		; 34:  Set to 2 if True Type font
MOD_OSFLG db	?		; 36:  Operating system flags
MOD_OTHER db	?		; 37:  Other flags
MOD_SAME1 dw	?		; 38:  Same as offset 2Ah
MOD_SAME2 dw	?		; 3A:  Same as offset 2Ah except in KERNEL
MOD_SWAP  dw	?		; 3C:  Minimum swap area size for this module
MOD_EXPWV dw	?		; 3E:  Expected Windows version #
MOD_PE_RVA dd	?		; 40:  PE-only RVA of PE file
MOD_PE_BASE dd	?		; 44:  PE-only LA of PE file base
MOD_PE_RSRC dd	?		; 48:  PE-only LA of PE file resources

MOD_STR ends

MDBF_DLL	equ 8000h	; It's a DLL
MDBF_CALL_WEP	equ 4000h	; Call WEP on unload
MDBF_SELF_LOAD	equ 0800h	; Uses self-loading mechanism
MDBF_TEXTMODE	equ 0200h	; Console app
MDBF_FULLSCREEN equ 0100h	; Writes into video buffer
MDBF_PRELOAD	equ 0040h	; Load when module is loaded rather than when accessed
MDBF_WIN32	equ 0010h	; Win32 PE file
MDBF_AUTODATA	equ 0002h	; Each module gets separate DGROUP
MDBF_SINGLEDATA equ 0001h	; Single DGROUP for all instances


MDBF_DATA     equ 0001h 	; Set = Data segment, Clr = Code segment
MDBF_ITERATED equ 0008h 	; Contains run length encoded data
MDBF_MOVEABLE equ 0010h 	; Set = Moveable in linear memory, Clr = FIXED
MDBF_PRELOAD  equ 0040h 	; Load when module is loaded rather than when accessed
MDBF_RELOC    equ 0100h 	; Contains relocation data
MDBF_DISCARD  equ 1000h 	; Discardable
MDBF_32BIT    equ 2000h 	; 32-bit code segment


LFI32STRUCT struc

LFI32_cBytes	 dw ?		; 00:  Length of data (not counting trailing 0
				;      in path name)
LFI32_fFixedDisk db ?		; 02:  1 iff on fixed media
LFI32_nErrCode	 dw ?		; 03:  Error code
LFI32_FileDate	 dw ?		; 05:  File data in MS-DOS format
LFI32_FileTime	 dw ?		; 07:  File time ...
LFI32_szPathName db 128 dup (?) ; 09:  File name in ASCIIZ format

LFI32STRUCT ends


LFI16STRUCT struc

LFI16_cBytes	 db ?		; 00:  Length of data (not counting trailing 0
				;      in path name)
LFI16_fFixedDisk db ?		; 01:  1 iff on fixed media
LFI16_nErrCode	 dw ?		; 02:  Error code
LFI16_FileDate	 dw ?		; 04:  File data in MS-DOS format
LFI16_FileTime	 dw ?		; 06:  File time ...
LFI16_szPathName db 128 dup (?) ; 08:  File name in ASCIIZ format

LFI16STRUCT ends


; NE File Structure

@NE_SIG equ	'EN'            ; File signature

NE_STR	struc

NE_SIGN dw	@NE_SIG 	; 00:  File signature
NE_LMAJ db	?		; 02:  Linker major version
NE_LMIN db	?		; 03:  ...    minor ...
NE_OffETAB dw	?		; 04:  NEHdr offset of entry table (see NE_ETAB_x_STR)
NE_LenETAB dw	?		; 06:  Length of ...
NE_CRC dd	?		; 08:  ** File load CRC
NE_PFLAG db	?		; 0C:  Program Flags (see NE_PFLAG_REC)
NE_AFLAG db	?		; 0D:  Application Flags (see NR_AFLAG_REC)
NE_AUTO dw	?		; 0E:  Auto data segment index (0 if NOAUTODATA)
NE_IHEAP dw	?		; 10:  Initial local heap size
NE_ISTK dw	?		; 12:  Initial stack size
NE_CSIP dd	?		; 14:  Entry point CS:IP where CS is a seg ndx
NE_SSSP dd	?		; 18:  Initial SS:SP where SS is a seg ndx
				;      If SS=automatic data segment and SP=0000h,
				;      the stack pointer is set to the top of
				;      the automatic data segment, just below
				;      the local heap
NE_SEGCNT dw	?		; 1C:  Segment count
NE_REFCNT dw	?		; 1E:  Module reference count
NE_NRMSIZ dw	?		; 20:  Byte size of nonresident names table
NE_OSEGTAB dw	?		; 22:  NEHdr Offset of segment table (NE_SEGTAB_STR)
NE_ORESTAB dw	?		; 24:  NEHdr Offset of resource table (NE_RESTAB_STR)
NE_ORNMTAB dw	?		; 26:  NEHdr Offset of resident names table
NE_OMODTAB dw	?		; 28:  NEHdr Offset of module reference table (NE_MODTAB_STR)
NE_OIMPTAB dw	?		; 2A:  NEHdr offset of imported names table
NE_ONRMTAB dd	?		; 2C:  File  offset of nonresident names table
NE_MEPCNT dw	?		; 30:  Count of moveable entry points
NE_ALIN dw	?		; 32:  File alignment size shift count (0 -> 9)
NE_RESCNT dw	?		; 34:  Number resource table entries
NE_TGTOS db	?		; 36:  Target OS (see @NE_TGTOS_xxx)
NE_OFLAG db	?		; 37:  Other OS/2 EXE flags (see NE_OFLAG_REC)
NE_ORTHUNK dw	?		; 38:  Offset to return thunks or start of
				;      gangload area
NE_OSTHUNK dw	?		; 3A:  Offset to segment reference thunks or
				;      length of gangload area
NE_MINSWAP dw	?		; 3C:  Minimum code swap area size
NE_EXPVER db	?,?		; 3E:  Expected Windows version
				;      (LO=minor, HI=major)

NE_STR	ends

NE_PFLAG_REC record \
$NE_PFLAG_80x87:1,  \
$NE_PFLAG_80386:1,  \
$NE_PFLAG_80286:1,  \
$NE_PFLAG_8086:1,   \
$NE_PFLAG_PMONLY:1, \
$NE_PFLAG_GINIT:1,  \
$NE_PFLAG_DTYPE:2

@NE_PFLAG_80x87  equ mask $NE_PFLAG_80x87  ; 80:  80x87 instructions
@NE_PFLAG_80386  equ mask $NE_PFLAG_80386  ; 40:  80386 instructions
@NE_PFLAG_80286  equ mask $NE_PFLAG_80286  ; 20:  80286 instructions
@NE_PFLAG_8086	 equ mask $NE_PFLAG_8086   ; 10:  8086 instructions
@NE_PFLAG_PMONLY equ mask $NE_PFLAG_PMONLY ; 08:  Protected mode only
@NE_PFLAG_GINIT  equ mask $NE_PFLAG_GINIT  ; 04:  Global initialization
@NE_PFLAG_DTYPE  equ mask $NE_PFLAG_DTYPE  ; 03:  DGROUP type (see @NE_PFLAG_DTYPE_xxx)

@NE_PFLAG_DTYPE_NONE equ 0	; None (NOAUTODATA)
@NE_PFLAG_DTYPE_SING equ 1	; Single shared (=DLL)
@NE_PFLAG_DTYPE_MULT equ 2	; Multiple (=EXE)
@NE_PFLAG_DTYPE_RSVD equ 3	; (Reserved)

NE_AFLAG_REC record \
$NE_AFLAG_DLL:1,    \
$NE_AFLAG_NONC:1,   \
$NE_AFLAG_ERR:1,    \
$NE_AFLAG_RSVD:1,   \
$NE_AFLAG_OS2:1,    \
$NE_AFLAG_ATYPE:3

@NE_AFLAG_DLL	equ mask $NE_AFLAG_DLL	 ; 80:	DLL or driver
@NE_AFLAG_NONC	equ mask $NE_AFLAG_NONC  ; 40:	Non-comforming program
@NE_AFLAG_ERR	equ mask $NE_AFLAG_ERR	 ; 20:	Errors in executable
@NE_AFLAG_RSVD	equ mask $NE_AFLAG_RSVD  ; 10:	(Reserved)
@NE_AFLAG_OS2	equ mask $NE_AFLAG_OS2	 ; 08:	OS/2 family application
@NE_AFLAG_ATYPE equ mask $NE_AFLAG_ATYPE ; 07:	Application type (see @NE_AFLAG_ATYPE_xxx)

@NE_AFLAG_ATYPE_FSRCN  equ 1	; Full screen (no Windows PM API)
@NE_AFLAG_ATYPE_COMP   equ 2	; Compatible with Windows PM API
@NE_AFLAG_ATYPE_WPMAPI equ 3	; Uses Windows PM API

@NE_TGTOS_UNK  equ	00h	; Unknown
@NE_TGTOS_OS2  equ	01h	; OS/2
@NE_TGTOS_WIN  equ	02h	; Windows
@NE_TGTOS_EURO equ	03h	; European MS-DOS 4.x
@NE_TGTOS_W386 equ	04h	; Windows 386
@NE_TGTOS_BOSS equ	05h	; BOSS (Borland Operating System Services)
@NE_TGTOS_PLOS2 equ	81h	; PharLap 286|DOS-Extender, OS/2
@NE_TGTOS_PLWIN equ	82h	; PharLap 286|DOS-Extender, Windows

NE_OFLAG_REC record \
$NE_OFLAG_GANG:1,   \
$NE_OFLAG_2XPROP:1, \
$NE_OFLAG_2XPM:1,   \
$NE_OFLAG_LFN:1

@NE_OFLAG_GANG	 equ	mask $NE_OFLAG_GANG   ; 08:  Gangload area
@NE_OFLAG_2XPROP equ	mask $NE_OFLAG_2XPROP ; 04:  2.x protected mode
@NE_OFLAG_2XPM	 equ	mask $NE_OFLAG_2XPM   ; 02:  2.x proportional font
@NE_OFLAG_LFN	 equ	mask $NE_OFLAG_LFN    ; 01:  Supports long filenames


NE_SEGTAB_STR struc

NE_SEGTAB_ODATA dw ?		; 00:  File offset in sectors to the segment data
NE_SEGTAB_LEN	dw ?		; 02:  Byte length of the segment (0 = 64KB)
NE_SEGTAB_FLAG	dw ?		; 04:  Flags (see NE_SEGTAB_REC)
NE_SEGTAB_MIN	dw ?		; 06:  Minimum allocation byte size of the segment
				;      (0 = 64KB)

NE_SEGTAB_STR ends

NE_SEGTAB_REC record \
$NE_SEGTAB_RSV15:1,  \
$NE_SEGTAB_HUGE:1,   \
$NE_SEGTAB_32BIT:1,  \
$NE_SEGTAB_DISC:1,   \
$NE_SEGTAB_IOPL:2,   \
$NE_SEGTAB_CONF:1,   \
$NE_SEGTAB_RELO:1,   \
$NE_SEGTAB_ONLY:1,   \
$NE_SEGTAB_PRELOAD:1,\
$NE_SEGTAB_SHARE:1,  \
$NE_SEGTAB_MOVABLE:1,\
$NE_SEGTAB_ITER:1,   \
$NE_SEGTAB_INMEM:1,  \
$NE_SEGTAB_LMEM:1,   \
$NE_SEGTAB_DC:1

@NE_SEGTAB_RSV15   equ mask $NE_SEGTAB_RSV15	; 8000:  (Reserved)
@NE_SEGTAB_HUGE    equ mask $NE_SEGTAB_HUGE	; 4000:  Huge memory segment:  NE_SEGTAB_LEN
						;	 and NE_SEGTAB_MIN are in sector units
@NE_SEGTAB_32BIT   equ mask $NE_SEGTAB_32BIT	; 2000:  32-bit segment
@NE_SEGTAB_DISC    equ mask $NE_SEGTAB_DISC	; 1000:  Discardable
@NE_SEGTAB_IOPL    equ mask $NE_SEGTAB_IOPL	; 0C00:  I/O Privilege Level
@NE_SEGTAB_CONF    equ mask $NE_SEGTAB_CONF	; 0200:  Conforming segment
@NE_SEGTAB_RELO    equ mask $NE_SEGTAB_RELO	; 0100:  Contains relocation data
@NE_SEGTAB_ONLY    equ mask $NE_SEGTAB_ONLY	; 0080:  Data:	READONLY, Code:  EXECUTEONLY
@NE_SEGTAB_PRELOAD equ mask $NE_SEGTAB_PRELOAD	; 0040:  PRELOAD
@NE_SEGTAB_SHARE   equ mask $NE_SEGTAB_SHARE	; 0020:  SHAREABLE
@NE_SEGTAB_MOVABLE equ mask $NE_SEGTAB_MOVABLE	; 0010:  MOVABLE
@NE_SEGTAB_ITER    equ mask $NE_SEGTAB_ITER	; 0008:  Iterated (run-length encoded) segment
@NE_SEGTAB_INMEM   equ mask $NE_SEGTAB_INMEM	; 0004:  Loaded
@NE_SEGTAB_LMEM    equ mask $NE_SEGTAB_LMEM	; 0002:  Loader has allocated memory
@NE_SEGTAB_DC	   equ mask $NE_SEGTAB_DC	; 0001:  1 = Data, 0 = Code segment


COMMENT|

The resource table has the following format

 WORD	  rscAlignShift;
 TYPEINFO rscTypes[];
 WORD	  rscEndTypes = 0;
 BYTE	  rscResourceNames[];
 BYTE	  rscEndNames = 0;

where

 typedef struct _TYPEINFO {
     WORD	 rtTypeID;
     WORD	 rtResourceCount;
     DWORD	 rtReserved;
     NAMEINFO	 rtNameInfo[];
 } TYPEINFO;

rscEndTypes indicates the end of the rscTypes data
rscEndNames indicates the end of the rscResourceNames data

|

NE_RESTAB_STR struc

NE_ALIGNSHIFT dw ?		; Specifies the alignment shift count for resource data.

NE_RESTAB_STR ends


NE_MODTAB_STR struc

NE_MODTAB_OFF dw ?		; Offset into imported names table

NE_MODTAB_STR ends


NE_ETAB_STR struc

NE_ETAB_CNT db	?		; 00:  # entries in this bundle
NE_ETAB_TYP db	?		; 01:  Type (see @NE_ETAB_TYP_xxx)

NE_ETAB_STR ends

@NE_ETAB_TYP_MOVABLE equ  0FFh	; Segment in entry table is movable
@NE_ETAB_TYP_CONST   equ  0FEh	; Constant in entry table ???


@NE_ETAB_INT3F equ 3FCDh	; INT 3Fh instruction

NE_ETAB_M_STR struc

NE_ETAB_M_FLAG db ?		; 00:  Flags (see NE_ETAB_REC)
NE_ETAB_M_INT3F dw @NE_ETAB_INT3F ; 01:  INT 3Fh instruction
NE_ETAB_M_LSEG db ?		; 03:  Logical segment #
NE_ETAB_M_OSEG dw ?		; 04:  Segment offset of symbol

NE_ETAB_M_STR ends


NE_ETAB_F_STR struc

NE_ETAB_F_FLAG db ?		; 00:  Flags (see NE_ETAB_REC)
NE_ETAB_F_OSEG dw ?		; 01:  Segment offset of symbol

NE_ETAB_F_STR ends

NE_ETAB_REC record \
$NE_ETAB_CNT:5,    \
$NE_ETAB_RSV2:1,   \
$NE_ETAB_SHARE:1,  \
$NE_ETAB_EXP:1

@NE_ETAB_CNT   equ mask $NE_ETAB_CNT	; F8:  Parm count
@NE_ETAB_RSV2  equ mask $NE_ETAB_RSV2	; 04:  (Reserved)
@NE_ETAB_SHARE equ mask $NE_ETAB_SHARE	; 02:  Shared data segment
@NE_ETAB_EXP   equ mask $NE_ETAB_EXP	; 01:  Entry is exported


; PE file Structure

@PE_SIG equ	'EP'            ; PE file signature


