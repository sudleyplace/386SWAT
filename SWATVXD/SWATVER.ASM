VERSION  equ	 302

;'$Header:   P:/PVCS/SWATVXD/SWATVER.ASV   1.31   10 Aug 1998 10:46:20   BOB  $
;
; (C) Copyright 1990-98 Qualitas, Inc.	All rights reserved.
;
; SWATVER.INC
;
; SWATVXD version number
;

	 public  SWAT_VER, SWAT_VERH, SWAT_VERL
SWAT_VER	 equ	 VERSION mod 1000
SWAT_VERH	 equ	 SWAT_VER / 100
SWAT_VERL	 equ	 SWAT_VER mod 100

	 public  SWAT_VERS_H, SWAT_VERS_T, SWAT_VERS_U
SWAT_VERS_H	 equ	 '0'+SWAT_VER/100
SWAT_VERS_T	 equ	 '0'+(SWAT_VER-(SWAT_VERS_H-'0')*100)/10
SWAT_VERS_U	 equ	 '0'+SWAT_VER-(SWAT_VERS_H-'0')*100-(SWAT_VERS_T-'0')*10

	 end			; End SWATVER module
