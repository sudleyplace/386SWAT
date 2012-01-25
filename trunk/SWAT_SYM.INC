;' $Header:   P:/PVCS/386SWAT/SWAT_SYM.INV   1.4   10 Aug 1998 11:01:42   BOB  $
;
; (C) Copyright 1987-98 Qualitas, Inc.	All rights reserved.
;
; SWAT_SYM.INC
;
; Equates and structures for Symbol Table Management
;

@ADDRHBITSMAX	equ	12	; Maximum bits for address hash table (16K)
@ADDRHBITSMIN	equ	8	; Minimum bits for address hash table (1K)
@ADDRHBITS	equ	@ADDRHBITSMAX ; Default bits for address hash table

@SYM_READBUFSIZ  equ	4096	; Size in bytes of static file read buffer

SYM_STR  struc			; Internal structure of symbol table

SYM_FVEC df	 ?		; 32-bit offset and segment/selector
SYM_FLAG dw	 ?		; Flags (see SYMFL_REC below)
SYM_GRP  dw	 ?		; Group # for translation
SYM_ADDR dd	 ?		; Effective linear address
SYM_NEXTAH dd	 ?		; Offset from symbol base of next entry
				; in address hash bucket (-1 if end)
SYM_NEXTNH dd	 ?		; Offset of next name hash bucket entry or -1
SYM_NAMLEN db	 ?		; Length in bytes of the symbol name

; The symbol's name appears next (case-sensitive)

SYM_STR  ends

SYM_NAME equ	 SYM_NAMLEN.LO[type SYM_NAMLEN] ; Offset of symbol name

SYMC_STR struc

SYMC_FVEC df	?		; SYM_FVEC
SYMC_FLAG dw	?		; SYM_FLAG
SYMC_GRP  dw	?		; SYM_GRP
SYMC_NAMLEN db	?		; Length byte when called externally

SYMC_STR ends

SYMC_NAME equ	 SYMC_NAMLEN.LO[type SYMC_NAMLEN] ; Offset of caller's symbol name

; Flags used for SYM_FLAGS and ISYM_FLAGS
SYMFL_REC record $SYMFL_VM:1,$SYMFL_TYP:5,$SYMFL_DEL:1,$SYMFL_RSV:9

@SYMFL_VM equ	 mask $SYMFL_VM ; 1 = symbol is for VM
				; 0 = ...	    PM
				; The above flag is meaningful for _DAT and _LN
				; types only.
@SYMTYP_DAT equ  0		; Code or data
@SYMTYP_LN  equ  1		; Line number record constructed by MAPSSF
@SYMTYP_ABS equ  2		; ABS record
@SYMTYP_SWT equ  3		; Symbol is for SWAT internal use


; Symbol translation structure

SYMTRAN_STR struc

SYMTRAN_OSEL dw  ?		; Old segment/selector
SYMTRAN_OGRP dw  ?		; Old group #
SYMTRAN_NFLAG dw ?		; New flags
SYMTRAN_NSEL dw  ?		; New segment/selector
SYMTRAN_NBASE dd ?		; New base (to be added to all offsets)
;---- New to 1.02; currently used only by SWATVXD -----------
SYMTRAN_FLAGS dw ?		; Flags for match significance

SYMTRAN_STR ends

; Flags used in SYMTRAN_FLAGS to indicate which elements in SYMTRAN_STR
; are to be ignored.
; $SYMFL_ADDVMSEG indicates that the new segment value is to be added
; to all V86 mode segments.
SYMTFL_REC record $SYMTFL_IGOSEL:1,$SYMTFL_IGOGRP:1,$SYMTFL_IGNFLAG:1,\
	$SYMTFL_IGNSEL:1,$SYMTFL_ADDVMSEG:1,$SYMTFL_RSVD:11

; Define the sum of all ignorance
@SYMTFL_IGNORE	equ	((mask $SYMTFL_IGOSEL) or (mask $SYMTFL_IGOGRP) or (mask $SYMTFL_IGNFLAG) or (mask $SYMTFL_IGNSEL))

