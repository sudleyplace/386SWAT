;' $Header:   P:/PVCS/386SWAT/INT1/INT1_WIN.INV   1.3   17 Oct 1995 12:20:14   BOB  $
;
; (C) Copyright 1987-94 Qualitas, Inc.	All rights reserved.
;
; INT1_WIN.INC
;
; Structure for WINTAB
;

WTAB_STR struc

WTAB_FCN dw	 ?		; Major function #
WTAB_LEN dw	 ?		; # entries in table
WTAB_PREF dd	 ?		; Pointer to prefacing text
WTAB_PTAB dd	 ?		; Pointer to first table entry of dwords
WTAB_VALW dd	 ?		; Pointer to first table entry of word values

WTAB_STR ends


