;' $Header:   P:/PVCS/MAX/INC/SWATVXD.INV   1.2   15 Jun 1998 16:06:06   BOB  $
;
; Copyright (C) 1990-8 Qualitas, Inc.  All rights reserved.
;
; SWATVXD.INC
;
; SWAT protected mode services for other devices and VMM
;

ifdef Begin_Service_Table

Begin_Service_Table SWAT

; Note: Get_Version must always be first

SWAT_Service	 SWAT_Get_Version	; Get version # and ID string pointer
SWAT_Service	 SWAT_Out_Mono_String	; Send string (==> ESI) to monochrome
SWAT_Service	 SWAT_SWATMSG		; Send string (ESI) and error (EAX)
SWAT_Service	 SWAT_Clear_Keys	; Clear Ctl- and Alt-keys in Windows
SWAT_Service	 SWAT_PrintOpen 	; Open the printer
;;;;_Service	 SWAT_LinPageLock	; Lock a linear page
;;;;_Service	 SWAT_LinPageUnLock	; Unlock a linear page

End_Service_Table SWAT

else

SWAT_Get_Version	equ	0
SWAT_Out_Mono_String	equ	1
SWAT_SWATMSG		equ	2
SWAT_Clear_Keys 	equ	3
SWAT_PrintOpen		equ	4
;;;;_LinPageLock	equ	5
;;;;_LinPageUnLock	equ	6

endif

@SWAT_MAX_FN		equ	4	; Maximum function #

; Equates for SWAT VxD's VM API

SWATVM_Get_Version	equ	0
SWATVM_Out_Mono_String	equ	1


