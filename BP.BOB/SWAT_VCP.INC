;' $Header:   P:/PVCS/386SWAT/SWAT_VCP.INV   1.5   15 Apr 1997 20:29:44   BOB  $
;
; (C) Copyright 1987-2001 Qualitas, Inc.  All rights reserved.
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


LCLPMG_STR struc

LCLPMGxx_FVEC df ?		; 00-05:  Sel|Off of local PMG handler
LCLPMGxx_ARB db ?		; 06-06:  Local PMG handler access rights byte
OLDPMGxx_ARB db ?		; 07-07:  Old	...
OLDPMGxx_FVEC df ?		; 08-0D:  Sel|Off of old PMG handler
	dw	?		; 0E-0F:  (Reserved)

LCLPMG_STR ends


VCPDTE_STR struc

; Note that the CODE and DATA selectors must be contiguous
; The rest may be in any order

VCP_CODE dq	?		; 00:  Code selector
VCP_DATA dq	?		; 08:  Data ...
VCP_LDT dq	?		; 10:  LDT ...
VCP_TSS00 dq	?		; 18:  TSS INT 00h ...
VCP_TSS01 dq	?		; 20:  TSS INT 01h ...
VCP_TSS02 dq	?		; 28:  TSS INT 02h ...
VCP_TSS03 dq	?		; 30:  TSS INT 03h ...
VCP_TSS05 dq	?		; 38:  TSS INT 05h ...
VCP_TSS06 dq	?		; 40:  TSS INT 06h ...
VCP_TSS08 dq	?		; 48:  TSS INT 08h ...
VCP_TSS0A dq	?		; 50:  TSS INT 0Ah ...
VCP_TSS0B dq	?		; 58:  TSS INT 0Bh ...
VCP_TSS0C dq	?		; 60:  TSS INT 0Ch ...
VCP_TSS0D dq	?		; 68:  TSS INT 0Dh ...
VCP_TSS0E dq	?		; 70:  TSS INT 0Eh ...
VCP_TR	  dq	?		; 78:  TR for INSERT
VCP_4GB   dq	?		; 80:  4GB ...

VCPDTE_STR ends


; Equates for VCP_FLAG

@VCP_EPM equ	8000h		; EPM GDT/IDT done
@VCP_PMG equ	4000h		; DBGINI for Interrupt Gates


; Selector structure to PM Interrupt Gates

PMG_STR struc

PMG_CODE dq	?		; 00:  Code selector
PMG_DATA dq	?		; 08:  Data ...
PMG_CR3  dq	?		; 10:  CR3 ...
PMG_4GB  dq	?		; 18:  4GB ...

PMG_STR ends


