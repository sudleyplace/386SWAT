VERSION equ	000

;' $Header:   P:/PVCS/386SWAT/VERSBETA.ASV   1.182   10 Aug 1998 11:03:00   BOB  $
;
; (C) Copyright 1987-99 Qualitas, Inc.	All rights reserved.
;
; VERSBETA.ASM
;
; Beta numbering scheme for 386SWAT
;

	public	BETA_H,BETA_T,BETA_U
VER	equ	VERSION mod 1000
BETA_H	equ	'0'+VER/100
BETA_T	equ	'0'+(VER-(BETA_H-'0')*100)/10
BETA_U	equ	'0'+VER-(BETA_H-'0')*100-(BETA_T-'0')*10
	end
