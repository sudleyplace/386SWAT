;' $Header:   P:/PVCS/386SWAT/SWAT_FLT.INV   1.0   10 Aug 1998 11:01:04   BOB  $

; (C) Copyright 1990-98 Qualitas, Inc.	All rights reserved.
;
; SWAT_FLT.INC
;
; Bit definitions for SWAT fault flags
;

SWAT_IPF_STR struc

SWAT_IPF_LinAddr dd ?		; Linear address
SWAT_IPF_Flags	 dd ?		; Flags (see SWAT_IPFREC below)

SWAT_IPF_STR ends


; Bit flags for SWAT_IPF_Flags

SWAT_IPF_REC record \
	$SWAT_IPF_EXPR:1,  \
	$SWAT_IPF_DELE:1,  \
	$SWAT_IPF_XDISP:1, \
	$SWAT_IPF_XSTOP:1

@SWAT_IPF_XDISP equ (mask $SWAT_IPF_XDISP) ; Don't display IPF message
@SWAT_IPF_XSTOP equ (mask $SWAT_IPF_XSTOP) ; Don't stop on INT 01h

; The following flags are not stored in SWAT_IPF_Flags -- they
; are for the convenience of the code in CMD_IPF.

@SWAT_IPF_EXPR	equ (mask $SWAT_IPF_EXPR)  ; Expression encountered
@SWAT_IPF_DELE	equ (mask $SWAT_IPF_DELE)  ; Delete this entry


; Default flags

@SWAT_IPF_DEFFLAGS equ 0

