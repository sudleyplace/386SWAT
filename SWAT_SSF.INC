;' $Header:   P:/PVCS/386SWAT/SWAT_SSF.INV   1.2   23 Jun 1992 14:54:52   DAVID  $
;
; (C) Copyright 1992 Qualitas, Inc.  All rights reserved.
;
; SWAT_SSF.INC
;
; SWAT Symbol File structure
;

COMMENT|

Swat Symbol File definitions

|

@SSF_SIG equ	 '$fSS'         ; Dword representation of 'SSf$'
@SSF_CVER equ	 0011h		; Minimum file version supporting SSF_FLAGS
				; and SSF_DATA - previous versions assume
				; data starts at offset 0Ah
@SSF_OLDDATA equ 0ah		; Offset to seek to for data for pre-@SSF_CVER
				; files

SSF_STR  struc			; Structure for getting SSF file signature
SSF_SIG  dd	 ?		; 'SSf$'
SSF_VER  dw	 ?		; 0011h -- version 0.11
SSF_COUNT dd	 ?		; Number of records in file
;--------- end of record for 0.10 version ------------
SSF_FLAGS dw	 ?		; Flags for processing symbols (see @SSFFL_xxx)
SSF_DATA dd	 ?		; Pointer within file to start of symbol data
SSF_STR  ends

@SSFFL_FLUSH	 equ	08000h	; Flush table before adding
@SSFFL_RAW	 equ	04000h	; Allow dupes

ISYM_STR  struc 		; Symbol record structure for import

ISYM_FVEC df	 ?		; Symbol segment/selector and offset
ISYM_FLAG dw	 ?		; Flags
ISYM_GROUP dw	 ?		; Group number (if WSG used)
ISYM_SYMLEN db	 ?		; Length byte for name

ISYM_STR  ends

ISYM_NAME equ ISYM_SYMLEN[size ISYM_SYMLEN].LO ; First byte of name
