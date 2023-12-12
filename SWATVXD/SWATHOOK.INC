;'$Header:   P:/PVCS/SWATVXD/SWATHOOK.INV   1.4   12 Mar 1996 10:29:50   BOB  $
;
; (C) Copyright 1990-96 Qualitas, Inc.	All rights reserved.
;
; SWATHOOK.INC
;
; VxD hook structures
;

VXDHOOK_STR	 struc		; Linked list of hooked VxD control procs

; The label VH_FIRST is assumed to be the first one in this struc.

VH_FIRST	 db	3 dup (?) ; For dword alignment
VH_NEWPROC	 db	?	; Opcode for near call
VH_NEWPROC1	 dd	?	; Target of near call

; The label VH_NEXT is assumed to immediately follow VH_NEWPROC1.
; If you insert additional entries into this struc, don't do it here.

VH_NEXT 	 dd	?	; ==> next link in chain (or NULL)
VH_DDB		 dd	?	; ==> VxD's DDB
VH_OLDPROC	 dd	?	; ==> VxD's original Control_Proc
VH_HOOKS0	 dd	?	; Bitmap of hooked dev call msg #s, bits 0-31
VH_HOOKS1	 dd	?	; ...					32-63
VH_NAME 	 db	8 dup (?)	; Name of hooked VxD

VXDHOOK_STR ends		; End of VXDHOOK_STR structure

PMHOOK_STR	 struc		; Linked list of hooked VxD protected mode APIs

; The label PH_FIRST is assumed to be the first one in this struc.

PH_FIRST	 db	3 dup (?) ; For dword alignment
PH_NEWPROC	 db	?	; Opcode for near call
PH_NEWPROC1	 dd	?	; Target of near call

; The label PH_NEXT is assumed to immediately follow PH_NEWPROC1.
; If you insert additional entries into this struc, don't do it here.

PH_NEXT 	 dd	?	; ==> next link in chain (or NULL)
PH_DDB		 dd	?	; ==> VxD's DDB
PH_OLDPROC	 dd	?	; ==> VxD's original PM_API_Proc
PH_HOOKS0	 dd	?	; Bitmap of hooked Client_AX values, bits 0-31
PH_HOOKS1	 dd	?	; ...					 32-63
PH_FNREGOFF	 dd	?	; Offset into Client_Reg_Struc of fn register
PH_NAME 	 db	8 dup (?)	; Name of hooked VxD

PMHOOK_STR	 ends		; End of PMHOOK_STR structure

