;' $Header:   P:/PVCS/MAX/INC/LIB.INV   1.0   05 Sep 1995 13:27:46   HENRY  $
; (C) Copyright 1995-2000 Qualitas, Inc.  All rights reserved.
;
; LIB.INC
;
; Library File structures, records, and equates
;

LIBHDR_STR struc		; Library header struc

LIBHDR_TYPE db	 ?		; 00:  Type byte (F0h)
LIBHDR_RLEN dw	 ?		; 01:  Record length
LIBHDR_DOFF dd	 ?		; 03:  Dictionary offset
LIBHDR_DSIZ dw	 ?		; 07:  Dictionary size in blocks
LIBHDR_FLAG db	 ?		; 09:  Flags:  see LIBHDR_REC below

LIBHDR_STR ends

LIBHDR_REC record $LIBHDR_CASE:1

@LIBHDR_CASE equ (mask $LIBHDR_CASE) ; 01:  Name comparisons are case-sensitive


LIBXHDR_STR struc		; Library ext dict header struc

LIBXHDR_TYPE db  ?		; 00:  Type byte (F2h)
LIBXHDR_RLEN dw  ?		; 01:  Record length
LIBXHDR_NMOD dw  ?		; 03:  # modules in library

LIBXHDR_STR ends


LIBXMOD_STR struc		; Library ext dict module table

LIBXMOD_PGNO dw  ?		; 00:  Page #
LIBXMOD_PMOD dw  ?		; 02:  Offset from start of extended dictionary
				; to list of dependent modules (null-terminated)
LIBXMOD_STR ends


LIBDEP_STR struc		; Library dependency table in extended dictionary

LIBDEP_MOD dw	 ?		; 00:  Dependent module #

LIBDEP_STR ends


; Archive (Library) File Format (COFF)

@ARCHLIB_SIG equ '!<arch>',0Ah  ; Signature


ARCHHDR_STR struc

ARCHHDR_NAME db 16 dup (?)	; 00:  Name appended with a slash
ARCHHDR_DATE db 12 dup (?)	; 10:  Date and time of creation in seconds
				;      since 1/1/1970 UCT
ARCHHDR_USRID db 6 dup (?)	; 1C:  ASCII decimal representation of the User ID
ARCHHDR_GRPID db 6 dup (?)	; 22:  ...				   Group ID
ARCHHDR_MODE  db 8 dup (?)	; 28:  ASCII octal representation of the member's file mode
ARCHHDR_SIZE  db 10 dup (?)	; 30:  ASCII decimal representation of the
				;      total size of the archive member
				;      excluding the header
ARCHHDR_EOH   db '`',0Ah        ; 3A:  End of header

ARCHHDR_STR ends



COFFHDR_STR struc

COFFHDR_MACH dw ?		; 00:  Machine type (see @IMAGE_FILE_MACHINE_xxx)
COFFHDR_NSECT dw ?		; 02:  # sections
COFFHDR_STAMP dd ?		; 04:  Time & date stamp
COFFHDR_PSYMTAB dd ?		; 08:  File offset of symbol table (0=none)
COFFHDR_NSYMB dd ?		; 0C:  # symbols -- string table immediately
				;      follows the symbol table
COFFHDR_OPTSIZE dw ?		; 10:  Size of optional header
COFFHDR_FLAG dw ?		; 12:  Flags (characteristics) (see COFFHDR_FLAG_REC)

COFFHDR_STR ends


@IMAGE_FILE_MACHINE_I386 equ 14Ch ; Intel 386 or later, and compatible CPUs


; COFFHDR_FLAG_REC record \
; $COFFHDR_FLAG_BYTES_REVERSED_HI:1,	  \
; $COFFHDR_FLAG_UP_SYSTEM_ONLY:1,	  \
; $COFFHDR_FLAG_DLL:1,			  \
; $COFFHDR_FLAG_SYSTEM:1,		  \
; $COFFHDR_FLAG_RSVD11:1,		  \
; $COFFHDR_FLAG_REMOVABLE_RUN_FROM_SWAP:1,\
; $COFFHDR_FLAG_DEBUG_STRIPPED:1,	  \
; $COFFHDR_FLAG_32BIT_MACHINE:1,	  \
; $COFFHDR_FLAG_BYTES_REVERSED_LO:1,	  \
; $COFFHDR_FLAG_16BIT_MACHINE:1,	  \
; $COFFHDR_FLAG_LARGE_ADDRESS_AWARE:1,	  \
; $COFFHDR_FLAG_AGGRESSIVE_WS_TRIM:1,	  \
; $COFFHDR_FLAG_LOCAL_SYMS_STRIPPED:1,	  \
; $COFFHDR_FLAG_LINE_NUMS_STRIPPED:1,	  \
; $COFFHDR_FLAG_EXECUTABLE_IMAGE:1,	  \
; $COFFHDR_FLAG_RELOCS_STRIPPED:1
;
;@COFFHDR_FLAG_BYTES_REVERSED_HI       equ (mask $COFFHDR_FLAG_BYTES_REVERSED_HI)	; 8000:  Bid-endian
;@COFFHDR_FLAG_UP_SYSTEM_ONLY	       equ (mask $COFFHDR_FLAG_UP_SYSTEM_ONLY)		; 4000:  Run on UP machine only???
;@COFFHDR_FLAG_DLL		       equ (mask $COFFHDR_FLAG_DLL)			; 2000:  Image is DLL
;@COFFHDR_FLAG_SYSTEM		       equ (mask $COFFHDR_FLAG_SYSTEM)			; 1000:  System file, not user prog
;@COFFHDR_FLAG_RSVD11		       equ (mask $COFFHDR_FLAG_RSVD11)			; 0800:  Resrved
;@COFFHDR_FLAG_REMOVABLE_RUN_FROM_SWAP equ (mask $COFFHDR_FLAG_REMOVABLE_RUN_FROM_SWAP) ; 0400:  If on removable, copy to swap file
;@COFFHDR_FLAG_DEBUG_STRIPPED	       equ (mask $COFFHDR_FLAG_DEBUG_STRIPPED)		; 0200:  Stripped
;@COFFHDR_FLAG_32BIT_MACHINE	       equ (mask $COFFHDR_FLAG_32BIT_MACHINE)		; 0100:  Normal
;@COFFHDR_FLAG_BYTES_REVERSED_LO       equ (mask $COFFHDR_FLAG_BYTES_REVERSED_LO)	; 0080:  Little-endian
;@COFFHDR_FLAG_16BIT_MACHINE	       equ (mask $COFFHDR_FLAG_16BIT_MACHINE)		; 0040:  Reserved
;@COFFHDR_FLAG_LARGE_ADDRESS_AWARE     equ (mask $COFFHDR_FLAG_LARGE_ADDRESS_AWARE)	; 0020:  App can handle > 2GB addrs
;@COFFHDR_FLAG_AGGRESSIVE_WS_TRIM      equ (mask $COFFHDR_FLAG_AGGRESSIVE_WS_TRIM)	; 0010:  Aggressively trim working set
;@COFFHDR_FLAG_LOCAL_SYMS_STRIPPED     equ (mask $COFFHDR_FLAG_LOCAL_SYMS_STRIPPED)	; 0008:  COFF symbol table removed
;@COFFHDR_FLAG_LINE_NUMS_STRIPPED      equ (mask $COFFHDR_FLAG_LINE_NUMS_STRIPPED)	; 0004:  COFF line numbers removed
;@COFFHDR_FLAG_EXECUTABLE_IMAGE        equ (mask $COFFHDR_FLAG_EXECUTABLE_IMAGE)	; 0002:  Image is normal
;@COFFHDR_FLAG_RELOCS_STRIPPED	       equ (mask $COFFHDR_FLAG_RELOCS_STRIPPED) 	; 0001:  Must be loaded at its preferred base addr

@COFFHDR_FLAG_BYTES_REVERSED_HI       equ  8000h ;  Big-endian
@COFFHDR_FLAG_UP_SYSTEM_ONLY	      equ  4000h ;  Run on UP machine only???
@COFFHDR_FLAG_DLL		      equ  2000h ;  Image is DLL
@COFFHDR_FLAG_SYSTEM		      equ  1000h ;  System file, not user prog
@COFFHDR_FLAG_RSVD11		      equ  0800h ;  Resrved
@COFFHDR_FLAG_REMOVABLE_RUN_FROM_SWAP equ  0400h ;  If on removable, copy to swap file
@COFFHDR_FLAG_DEBUG_STRIPPED	      equ  0200h ;  Stripped
@COFFHDR_FLAG_32BIT_MACHINE	      equ  0100h ;  32-bit machine
@COFFHDR_FLAG_BYTES_REVERSED_LO       equ  0080h ;  Little-endian
@COFFHDR_FLAG_16BIT_MACHINE	      equ  0040h ;  16-bit machine
@COFFHDR_FLAG_LARGE_ADDRESS_AWARE     equ  0020h ;  App can handle > 2GB addrs
@COFFHDR_FLAG_AGGRESSIVE_WS_TRIM      equ  0010h ;  Aggressively trim working set
@COFFHDR_FLAG_LOCAL_SYMS_STRIPPED     equ  0008h ;  COFF symbol table removed
@COFFHDR_FLAG_LINE_NUMS_STRIPPED      equ  0004h ;  COFF line numbers removed
@COFFHDR_FLAG_EXECUTABLE_IMAGE	      equ  0002h ;  Executable image
@COFFHDR_FLAG_RELOCS_STRIPPED	      equ  0001h ;  Must be loaded at its preferred base addr


COFFOBJSYM_STR struc

COFFOBJSYM_NAME db 8 dup (?)	; 00:  Name as %.8s
				; (if name[0] is 0, two unknown DDs)
COFFOBJSYM_CHAR dd ?		; 08:  Characteristics???
COFFOBJSYM_DD	dd ?		; 0C:  Unknown DD
COFFOBJSYM_DW	dw ?		; 0E:  Unknown DW

COFFOBJSYM_STR ends


@COFFOPTSTD_MAGIC  equ	010Bh	; Magic number for PE32
@COFFOPTSTD2_MAGIC equ	020Bh	; ...		   PE32+


COFFOPTSTD_STR struc

COFFOPTSTD_MAGIC dw ?		; 00:  Magic #
COFFOPTSTD_MAJLNKVER db ?	; 02:  Major linker version #
COFFOPTSTD_MINLNKVER db ?	; 03:  Minor ...
COFFOPTSTD_CODESIZE  dd ?	; 04:  Size of code
COFFOPTSTD_INITDATA  dd ?	; 08:  ...     initialized data
COFFOPTSTD_UNITDATA  dd ?	; 0C:  ...     uninitialized data
COFFOPTSTD_ENTRYPT   dd ?	; 10:  Address of entry point
COFFOPTSTD_CODEBASE  dd ?	; 14:  Base of code
COFFOPTSTD_DATABASE  dd ?	; 18:  ...     data

COFFOPTSTD_STR ends


COFFOPTSTD2_STR struc

COFFOPTSTD2_MAGIC dw ?		; 00:  Magic #
COFFOPTSTD2_MAJLNKVER db ?	; 02:  Major linker version #
COFFOPTSTD2_MINLNKVER db ?	; 03:  Minor ...
COFFOPTSTD2_CODESIZE  dd ?	; 04:  Size of code
COFFOPTSTD2_INITDATA  dd ?	; 08:  ...     initialized data
COFFOPTSTD2_UNITDATA  dd ?	; 0C:  ...     uninitialized data
COFFOPTSTD2_ENTRYPT   dd ?	; 10:  Address of entry point
COFFOPTSTD2_CODEBASE  dd ?	; 14:  Base of code

COFFOPTSTD2_STR ends


COFFOPTWNT_STR struc

COFFOPTWNT_IMAGEBASE dd ?	; 00:  Image base
COFFOPTWNT_SECTALIGN dd ?	; 04:  Section alignment
COFFOPTWNT_FILEALIGN dd ?	; 08:  File alignment
COFFOPTWNT_MAJOSVER  dw ?	; 0A:  Major O/S version #
COFFOPTWNT_MINOSVER  dw ?	; 0C:  Minor ...
COFFOPTWNT_MAJIMVER  dw ?	; 0E:  Major image version #
COFFOPTWNT_MINIMVER  dw ?	; 10:  Minor ...
COFFOPTWNT_MAJSSVER  dw ?	; 12:  Major subsystem version #
COFFOPTWNT_MINSSVER  dw ?	; 14:  Minor ...
COFFOPTWNT_RSVD      dd ?	; 18:  Reserved
COFFOPTWNT_IMGSIZE   dd ?	; 1C:  Size of image
COFFOPTWNT_HDRSIZE   dd ?	; 20:  Size of headers
COFFOPTWNT_CSUM      dd ?	; 24:  Checksum
COFFOPTWNT_SUBSYSTEM dw ?	; 28:  Subsystem
COFFOPTWNT_DLLCHAR   dw ?	; 2A:  DLL Characteristics
COFFOPTWNT_STKRSVSIZE dd ?	; 2C:  Size of stack reserve
COFFOPTWNT_STKCOMSIZE dd ?	; 30:  ...     stack commit
COFFOPTWNT_HEPRSVSIZE dd ?	; 34:  ...     heap reserve
COFFOPTWNT_HEPCOMSIZE dd ?	; 38:  ...     heap commit
COFFOPTWNT_LFLAGS    dd ?	; 3C:  Loader flags
COFFOPTWNT_NDATADICT dd ?	; 40:  # data dictionary entries

COFFOPTWNT_STR ends


COFFOPTWNT2_STR struc

COFFOPTWNT2_IMAGEBASE dq ?	; 00:  Image base
COFFOPTWNT2_SECTALIGN dd ?	; 08:  Section alignment
COFFOPTWNT2_FILEALIGN dd ?	; 0C:  File alignment
COFFOPTWNT2_MAJOSVER  dw ?	; 0E:  Major O/S version #
COFFOPTWNT2_MINOSVER  dw ?	; 10:  Minor ...
COFFOPTWNT2_MAJIMVER  dw ?	; 12:  Major image version #
COFFOPTWNT2_MINIMVER  dw ?	; 14:  Minor ...
COFFOPTWNT2_MAJSSVER  dw ?	; 16:  Major subsystem version #
COFFOPTWNT2_MINSSVER  dw ?	; 18:  Minor ...
COFFOPTWNT2_RSVD      dd ?	; 1C:  Reserved
COFFOPTWNT2_IMGSIZE   dd ?	; 20:  Size of image
COFFOPTWNT2_HDRSIZE   dd ?	; 24:  Size of headers
COFFOPTWNT2_CSUM      dd ?	; 28:  Checksum
COFFOPTWNT2_SUBSYSTEM dw ?	; 2C:  Subsystem
COFFOPTWNT2_DLLCHAR   dw ?	; 2E:  DLL Characteristics
COFFOPTWNT2_STKRSVSIZE dq ?	; 30:  Size of stack reserve
COFFOPTWNT2_STKCOMSIZE dq ?	; 38:  ...     stack commit
COFFOPTWNT2_HEPRSVSIZE dq ?	; 40:  ...     heap reserve
COFFOPTWNT2_HEPCOMSIZE dq ?	; 48:  ...     heap commit
COFFOPTWNT2_LFLAGS    dd ?	; 50:  Loader flags
COFFOPTWNT2_NDATADICT dd ?	; 54:  # data dictionary entries

COFFOPTWNT2_STR ends


COFFOPTDATADIR_STR struc

COFFOPTDATADIR_RVA dd ? 	; 00:  Relative Virtual Address
COFFOPTDATADIR_SIZE dd ?	; 04:  Size

COFFOPTDATADIR_STR ends


COFFSECT_STR struc

COFFSECT_NAME db 8 dup (?)	; 00:  Name
COFFSECT_VIRTSIZE dd ?		; 08:  Virtual Size
COFFSECT_VIRTADDR dd ?		; 0C:  Virtual Address
COFFSECT_RAWSIZE  dd ?		; 10:  Size of raw data
COFFSECT_RAWPTR   dd ?		; 14:  Ptr to raw data
COFFSECT_RELOPTR  dd ?		; 18:  Ptr to relocations
COFFSECT_LINEPTR  dd ?		; 1C:  Ptr to line numbers
COFFSECT_NRELO	  dw ?		; 20:  Number of relocations
COFFSECT_NLINE	  dw ?		; 22:  Number of line numbers
COFFSECT_CHAR	  dd ?		; 24:  Characteristics (see IMAGE_REC below)

COFFSECT_STR ends


COFFRELO_STR struc

COFFRELO_DD1 dd ?		; 00:  First dword  *FIXME*
COFFRELO_DD2 dd ?		; 04:  Second dword *FIXME*
COFFRELO_DW  dw ?		; 08:  Word	    *FIXME*

COFFRELO_STR ends


;; IMAGE_REC record			   \
;; $IMAGE_SCN_MEM_WRITE:1,		   \
;; $IMAGE_SCN_MEM_READ:1,		   \
;; $IMAGE_SCN_MEM_EXECUTE:1,		   \
;; $IMAGE_SCN_MEM_SHARED:1,		   \
;; $IMAGE_SCN_MEM_NOT_PAGED:1,		   \
;; $IMAGE_SCN_MEM_NOT_CACHED:1, 	   \
;; $IMAGE_SCN_MEM_DISCARDABLE:1,	   \
;; $IMAGE_SCN_LNK_NRELOC_OVFL:1,	   \
;; $IMAGE_SCN_ALIGN_MASK:4,		   \
;; $IMAGE_SCN_MEM_PRELOAD:1,		   \
;; $IMAGE_SCN_MEM_LOCKED:1,		   \
;; $IMAGE_SCN_MEM_16BIT:1,		   \
;; $IMAGE_SCN_MEM_SYSHEAP:1,		   \
;; $IMAGE_SCN_MEM_FARDATA:1,		   \
;; $IMAGE_SCN_MEM_NO_DEFER_SPEC_EXC:1,	   \
;; $IMAGE_SCN_RSVDxx:1, 		   \
;; $IMAGE_SCN_LNK_COMDAT:1,		   \
;; $IMAGE_SCN_LNK_REMOVE:1,		   \
;; $IMAGE_SCN_TYPE_OVER:1,		   \
;; $IMAGE_SCN_LNK_INFO:1,		   \
;; $IMAGE_SCN_LNK_OTHER:1,		   \
;; $IMAGE_SCN_CNT_UNINITIALIZED_DATA:1,    \
;; $IMAGE_SCN_CNT_INITIALIZED_DATA:1,	   \
;; $IMAGE_SCN_CNT_CODE:1,		   \
;; $IMAGE_SCN_TYPE_COPY:1,		   \
;; $IMAGE_SCN_TYPE_NO_PAD:1,		   \
;; $IMAGE_SCN_TYPE_GROUP:1,		   \
;; $IMAGE_SCN_TYPE_NOLOAD:1,		   \
;; $IMAGE_SCN_TYPE_DSECT:1
;;
;; @IMAGE_SCN_MEM_WRITE 	     equ   (mask $IMAGE_SCN_MEM_WRITE		  ) ; 80000000:  
;; @IMAGE_SCN_MEM_READ		     equ   (mask $IMAGE_SCN_MEM_READ		  ) ; 40000000:
;; @IMAGE_SCN_MEM_EXECUTE	     equ   (mask $IMAGE_SCN_MEM_EXECUTE 	  ) ; 20000000:
;; @IMAGE_SCN_MEM_SHARED	     equ   (mask $IMAGE_SCN_MEM_SHARED		  ) ; 10000000:
;; @IMAGE_SCN_MEM_NOT_PAGED	     equ   (mask $IMAGE_SCN_MEM_NOT_PAGED	  ) ; 08000000:
;; @IMAGE_SCN_MEM_NOT_CACHED	     equ   (mask $IMAGE_SCN_MEM_NOT_CACHED	  ) ; 04000000:
;; @IMAGE_SCN_MEM_DISCARDABLE	     equ   (mask $IMAGE_SCN_MEM_DISCARDABLE	  ) ; 02000000:
;; @IMAGE_SCN_LNK_NRELOC_OVFL	     equ   (mask $IMAGE_SCN_LNK_NRELOC_OVFL	  ) ; 01000000:
;; @IMAGE_SCN_ALIGN_MASK	     equ   (mask $IMAGE_SCN_ALIGN_MASK		  ) ; 00F00000:
;; @IMAGE_SCN_MEM_PRELOAD	     equ   (mask $IMAGE_SCN_MEM_PRELOAD 	  ) ; 00080000:
;; @IMAGE_SCN_MEM_LOCKED	     equ   (mask $IMAGE_SCN_MEM_LOCKED		  ) ; 00040000:
;; @IMAGE_SCN_MEM_16BIT 	     equ   (mask $IMAGE_SCN_MEM_16BIT		  ) ; 00020000:
;; @IMAGE_SCN_MEM_SYSHEAP	     equ   (mask $IMAGE_SCN_MEM_SYSHEAP 	  ) ; 00010000:
;; @IMAGE_SCN_MEM_FARDATA	     equ   (mask $IMAGE_SCN_MEM_FARDATA 	  ) ; 00008000:
;; @IMAGE_SCN_MEM_NO_DEFER_SPEC_EXC  equ   (mask $IMAGE_SCN_MEM_NO_DEFER_SPEC_EXC ) ; 00004000:
;; @IMAGE_SCN_RSVDxx		     equ   (mask $IMAGE_SCN_RSVDxx		  ) ; 00002000:
;; @IMAGE_SCN_LNK_COMDAT	     equ   (mask $IMAGE_SCN_LNK_COMDAT		  ) ; 00001000:
;; @IMAGE_SCN_LNK_REMOVE	     equ   (mask $IMAGE_SCN_LNK_REMOVE		  ) ; 00000800:
;; @IMAGE_SCN_TYPE_OVER 	     equ   (mask $IMAGE_SCN_TYPE_OVER		  ) ; 00000400:
;; @IMAGE_SCN_LNK_INFO		     equ   (mask $IMAGE_SCN_LNK_INFO		  ) ; 00000200:
;; @IMAGE_SCN_LNK_OTHER 	     equ   (mask $IMAGE_SCN_LNK_OTHER		  ) ; 00000100:
;; @IMAGE_SCN_CNT_UNINITIALIZED_DATA equ   (mask $IMAGE_SCN_CNT_UNINITIALIZED_DATA) ; 00000080:
;; @IMAGE_SCN_CNT_INITIALIZED_DATA   equ   (mask $IMAGE_SCN_CNT_INITIALIZED_DATA  ) ; 00000040:
;; @IMAGE_SCN_CNT_CODE		     equ   (mask $IMAGE_SCN_CNT_CODE		  ) ; 00000020:
;; @IMAGE_SCN_TYPE_COPY 	     equ   (mask $IMAGE_SCN_TYPE_COPY		  ) ; 00000010:
;; @IMAGE_SCN_TYPE_NO_PAD	     equ   (mask $IMAGE_SCN_TYPE_NO_PAD 	  ) ; 00000008:
;; @IMAGE_SCN_TYPE_GROUP	     equ   (mask $IMAGE_SCN_TYPE_GROUP		  ) ; 00000004:
;; @IMAGE_SCN_TYPE_NOLOAD	     equ   (mask $IMAGE_SCN_TYPE_NOLOAD 	  ) ; 00000002:
;; @IMAGE_SCN_TYPE_DSECT	     equ   (mask $IMAGE_SCN_TYPE_DSECT		  ) ; 00000001:


@IMAGE_SCN_MEM_WRITE		  equ	80000000h  
@IMAGE_SCN_MEM_READ		  equ	40000000h
@IMAGE_SCN_MEM_EXECUTE		  equ	20000000h
@IMAGE_SCN_MEM_SHARED		  equ	10000000h
@IMAGE_SCN_MEM_NOT_PAGED	  equ	08000000h
@IMAGE_SCN_MEM_NOT_CACHED	  equ	04000000h
@IMAGE_SCN_MEM_DISCARDABLE	  equ	02000000h
@IMAGE_SCN_LNK_NRELOC_OVFL	  equ	01000000h
@IMAGE_SCN_ALIGN_MASK		  equ	00F00000h
@IMAGE_SCN_MEM_PRELOAD		  equ	00080000h
@IMAGE_SCN_MEM_LOCKED		  equ	00040000h
@IMAGE_SCN_MEM_16BIT		  equ	00020000h
@IMAGE_SCN_MEM_SYSHEAP		  equ	00010000h
@IMAGE_SCN_MEM_FARDATA		  equ	00008000h
@IMAGE_SCN_MEM_NO_DEFER_SPEC_EXC  equ	00004000h
@IMAGE_SCN_RSVDxx		  equ	00002000h
@IMAGE_SCN_LNK_COMDAT		  equ	00001000h
@IMAGE_SCN_LNK_REMOVE		  equ	00000800h
@IMAGE_SCN_TYPE_OVER		  equ	00000400h
@IMAGE_SCN_LNK_INFO		  equ	00000200h
@IMAGE_SCN_LNK_OTHER		  equ	00000100h
@IMAGE_SCN_CNT_UNINITIALIZED_DATA equ	00000080h
@IMAGE_SCN_CNT_INITIALIZED_DATA   equ	00000040h
@IMAGE_SCN_CNT_CODE		  equ	00000020h
@IMAGE_SCN_TYPE_COPY		  equ	00000010h
@IMAGE_SCN_TYPE_NO_PAD		  equ	00000008h
@IMAGE_SCN_TYPE_GROUP		  equ	00000004h
@IMAGE_SCN_TYPE_NOLOAD		  equ	00000002h
@IMAGE_SCN_TYPE_DSECT		  equ	00000001h


@IMAGE_SCN_ALIGN_1BYTES    equ	1	; Alignment to 1 byte
@IMAGE_SCN_ALIGN_2BYTES    equ	2	; ...	       2
@IMAGE_SCN_ALIGN_4BYTES    equ	3	; ...	       4
@IMAGE_SCN_ALIGN_8BYTES    equ	4	; ...	       8
@IMAGE_SCN_ALIGN_16BYTES   equ	5	; ...	      16
@IMAGE_SCN_ALIGN_32BYTES   equ	6	; ...	      32
@IMAGE_SCN_ALIGN_64BYTES   equ	7	; ...	      64
@IMAGE_SCN_ALIGN_128BYTES  equ	8	; ...	     128
@IMAGE_SCN_ALIGN_256BYTES  equ	9	; ...	     256
@IMAGE_SCN_ALIGN_512BYTES  equ 10	; ...	     512
@IMAGE_SCN_ALIGN_1024BYTES equ 11	; ...	    1024
@IMAGE_SCN_ALIGN_2048BYTES equ 12	; ...	    2048
@IMAGE_SCN_ALIGN_4096BYTES equ 13	; ...	    4096
@IMAGE_SCN_ALIGN_8192BYTES equ 14	; ...	    8192

