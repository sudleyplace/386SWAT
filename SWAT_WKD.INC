;' $Header:   P:/PVCS/386SWAT/SWAT_WKD.INV   1.0   10 Aug 1998 11:02:52   BOB  $
;
; (C) Copyright 1996-8 Qualitas, Inc.  All rights reserved.
;
; SWAT_WKD.INC
;
; Equates for WKD_FLAG
;

.xcref WKD_REC
WKD_REC record	\
		$WKD_PMINIT:1,	\
		$WKD_FLTSET:1,	\
		$WKD_FLTSK:1,	\
		$WKD_FLTON:1,	\
		$WKD_LOGERR:1,	\
		$WKD_QUIET:1,	\
		$WKD_ENABLE:1

@WKD_PMINIT equ (mask $WKD_PMINIT) ; Signal INT 01h at end of PM initialization
@WKD_FLTSET equ (mask $WKD_FLTSET) ; Fault trapping occurred once
@WKD_FLTSK  equ (mask $WKD_FLTSK)  ; Fault trapping to be skipped once
@WKD_FLTON  equ (mask $WKD_FLTON)  ; Fault trapping ON
@WKD_LOGERR equ (mask $WKD_LOGERR) ; Trap on LogError () calls
@WKD_QUIET  equ (mask $WKD_QUIET)  ; Don't stop and ask on Fatal Exit
@WKD_ENABLE equ (mask $WKD_ENABLE) ; WKD services enabled


; Equates and strucs for WKD registered dot commands

@WKDDOT_MAX equ 16		; Maximum # dot commands registerable

WKDDOT_STR struc

WKDDOT_ACT df	?		; Action routine
WKDDOT_CHR db	?,?		; Command char
WKDDOT_HLP df	?		; Help text
	   db	?,?		; For alignment

WKDDOT_STR ends

