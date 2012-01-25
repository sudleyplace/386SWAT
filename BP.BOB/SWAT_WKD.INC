;' $Header:   P:/PVCS/386SWAT/SWAT_WKD.INV   1.0   10 Aug 1998 11:02:52   BOB  $
;
; (C) Copyright 1996-1999 Qualitas, Inc.  All rights reserved.
;
; SWAT_WKD.INC
;
; Equates for WKD_FLAG
;

.xcref WKD_REC
WKD_REC record	\
		$WKD_VXDL:1,	\
		$WKD_LEQ:1,	\
		$WKD_PEQ:1,	\
		$WKD_PMINIT:1,	\
		$WKD_FLTSET:1,	\
		$WKD_FLTSK:1,	\
		$WKD_FLTON:1,	\
		$WKD_LOGERR:1,	\
		$WKD_QUIET:1,	\
		$WKD_ENABLE:1

@WKD_VXDL   equ (mask $WKD_VXDL)   ; 0200:  Display VxD load segment table
@WKD_LEQ    equ (mask $WKD_LEQ)    ; 0100:  Be quiet on Log Errors
@WKD_PEQ    equ (mask $WKD_PEQ)    ; 0080:  Be quiet on Parameter Errors
@WKD_PMINIT equ (mask $WKD_PMINIT) ; 0040:  Signal INT 01h at end of PM initialization
@WKD_FLTSET equ (mask $WKD_FLTSET) ; 0020:  Fault trapping occurred once
@WKD_FLTSK  equ (mask $WKD_FLTSK)  ; 0010:  Fault trapping to be skipped once
@WKD_FLTON  equ (mask $WKD_FLTON)  ; 0008:  Fault trapping ON
@WKD_LOGERR equ (mask $WKD_LOGERR) ; 0004:  Trap on LogError () calls
@WKD_QUIET  equ (mask $WKD_QUIET)  ; 0002:  Don't stop and ask on Fatal Exit
@WKD_ENABLE equ (mask $WKD_ENABLE) ; 0001:  WKD services enabled


; Equates and strucs for WKD registered dot commands

@WKDDOT_MAX equ 16		; Maximum # dot commands registerable

WKDDOT_STR struc

WKDDOT_ACT df	?		; Action routine
WKDDOT_CHR db	?,?		; Command char
WKDDOT_HLP df	?		; Help text
	   db	?,?		; For alignment

WKDDOT_STR ends

