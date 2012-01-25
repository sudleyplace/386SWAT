VERSION  equ	 602

;' $Header:   P:/PVCS/386SWAT/VERSION.ASV   1.11   20 Aug 1998 23:06:00   BOB  $
;
; (C) Copyright 1987-99 Qualitas, Inc.	All rights reserved.
;
; VERSION.ASM
;
; Version number for 386SWAT
;

	public	VER,VERS_H,VERS_T,VERS_U,VERS_HTU
VER	equ	VERSION mod 1000
VERS_H	equ	'0'+VER/100
VERS_T	equ	'0'+(VER-(VERS_H-'0')*100)/10
VERS_U	equ	'0'+VER-(VERS_H-'0')*100-(VERS_T-'0')*10
VERS_HTU equ	((VER/100)*100h)+(VER mod 100)
	end
