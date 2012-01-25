;' $Header:   P:/PVCS/386SWAT/SWAT_VCP.INV   1.5   15 Apr 1997 20:29:44   BOB  $
;
; (C) Copyright 1987-97 Qualitas, Inc.	All rights reserved.
;
; SWAT_VCP.INC
;
; SWAT_VCP structures
;

LCLTSS_STR struc

TSS_INTxx    dd  ?		; 00-03:  Offset in code of TSS interrupt handler
PTSS_Ixx     dd  ?		; 04-07:  Offset in data to TSS structure
PSTK_IxxZ    dd  ?		; 08-0B:  Offset in data to TSS PL0 stack ending
PMSG_Ixx     dd  ?		; 0C-0F:  Offset in code to fault message text
OLDINTxx_FWD df  ?		; 10-15:  Old interrupt handler fword address
DDTE_TSSxx   dw  -1		; 16-17:  Base selector for this TSS
				;	  (add CODESEL to get actual)
LCLGATExx_FVEC df ?		; 18-1D:  Sel|Off of local interrupt gate handler
LCLGATExx_ARB db ?		; 1E-1E:  Local interrupt gate handler access rights byte
OLDGATExx_ARB db ?		; 1F-1F:  Old	...
OLDGATExx_FVEC df ?		; 20-25:  Sel|Off of old interrupt gate handler
OLDINTxx_ARB db  ?		; 26-26:  Old interrupt handler access rights byte
INTNOxx      db  ?		; 27-27:  Interrupt #

LCLTSS_STR ends

