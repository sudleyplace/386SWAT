;' $Header:   P:/PVCS/386SWAT/SWAT_UNR.INV   1.0   20 Aug 1998 23:06:00   BOB  $
;
; (C) Copyright 1998 Qualitas, Inc.  All rights reserved.
;
; SWAT_UNR.INC
;
; Common equates for Unreal mode
;

UNR_REC record	\
		$UNR_CS:1,	\
		$UNR_DS:1,	\
		$UNR_ES:1,	\
		$UNR_FS:1,	\
		$UNR_GS:1,	\
		$UNR_SS:1

@UNR_CS  equ	(mask $UNR_CS)	; Put CS into Unreal mode
@UNR_DS  equ	(mask $UNR_DS)	; ... DS ...
@UNR_ES  equ	(mask $UNR_ES)	; ... ES ...
@UNR_FS  equ	(mask $UNR_FS)	; ... FS ...
@UNR_GS  equ	(mask $UNR_GS)	; ... GS ...
@UNR_SS  equ	(mask $UNR_SS)	; ... SS ...

@UNR_ALL equ	@UNR_CS or @UNR_DS or @UNR_ES or @UNR_FS or @UNR_GS or @UNR_SS

