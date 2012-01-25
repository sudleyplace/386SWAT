;' $Header:   P:/PVCS/386SWAT/SWAT_OVL.INV   1.1   20 Sep 1994 16:49:34   BOB  $
;
; (C) Copyright 1987-94 Qualitas, Inc.	All rights reserved.
;
; SWAT_OVL.INC
;
; Structures and equates for overlays
;

; Single format

OVL_STR  struc

OVL_LEN  dw	 ?		; # bytes in overlay
OVL_NAME db	 '        '     ; Name
OVL_SIGN db	 'OVRLAY'       ; Signature

OVL_STR  ends

@OVL_NAME_LEN equ 8		; Length of OVL_NAME


; Double format

OVLD_STR struc

OVLD_LEN  dd	 ?		; # bytes in overlay
OVLD_NAME db	 '      '       ; Name
OVLD_SIGN db	 'OVRLAY'       ; Signature

OVLD_STR ends

@OVLD_NAME_LEN equ 6		; Length of OVLD_NAME


@OVLSIGN1 equ	 'LRVO'         ; Overlay signature, part 1
@OVLSIGN2 equ	 'YA'           ; ...                     2


