;' $Header:   P:/PVCS/386SWAT/SWAT_INF.INV   1.8   27 Aug 1998 20:24:46   BOB  $
;
; (C) Copyright 1987-98 Qualitas, Inc.	All rights reserved.
;
; SWAT_INF.INC
;
; Structure definition for 386SWAT VCPI GET Debugger Information
;

@SWATINFO_VER	equ	7	; Define the structure version level

SWATINFO_STR	struc

SWTINF_LEN	dw	?	; Byte count of structure
SWTINF_BASE	dd	?	; Physical base address of SWAT code segment

; The following fields are present only if SWTINF_LEN > 6

SWTINF_VER	dw	?	; Version # of structure

; The following fields are valid for SWTINF_VER >= 2

SWTINF_ARG_FLAG dw	?	; Offset of ARG_FLAG in DGROUP
SWTINF_LCL_FLAG dw	?	; Offset of LCL_FLAG in DGROUP

; The following fields are valid for SWTINF_VER >= 3

SWTINF_INT67	dd	?	; Offset to LCL_INT67

; SWTINF_INT67 services valid for 386SWAT.LOD with SWTINF_VER >= 3
; @VCPI_DBGSYM			; Symbol Table Management with subfunctions
;	@DBGSYM_APPND		; Append ECX names from DS:ESI
;	@DBGSYM_SRCH		; Search for name DS:ESI
;	@DBGSYM_TRANS		; Translate old seg/sel CX, grp DX to ESI/EDI
;	@DBGSYM_FLUSH		; Flush the symbol table

; SWTINF_INT67 services valid for 386SWAT.LOD with SWTINF_VER >= 4
; @VCPI_DBGWINVARS		; WIN386 internal variables
;	@DBGWINVARS_CURVM	; CX:EDX = Address of Cur_VM_Handle
;	@DBGWINVARS_SYSVM	; CX:EDX = Address of Sys_VM_Handle

; The following fields are valid for SWTINF_VER >= 5

SWTINF_PG2BASE	dd	?	; Physical base address of SWAT code segment #2
SWTINF_PG2LEN	dd	?	; Length in bytes of PGROUP2

; The following fields are valid for SWTINF_VER >= 6

SWTINF_LC2_FLAG dw	?	; Offset of LC2_FLAG in DGROUP
SWTINF_LC3_FLAG dw	?	; Offset of LC3_FLAG in DGROUP

; The following fields are valid for SWTINF_VER >= 7

SWTINF_VxD_PMAPI df	?	; CS:EIP of SWAT's VxD entry
SWTINF_EnterVMM df	?	; Entry point for VMM calls
SWTINF_ExitVMM df	?	; Exit ...
SWTINF_PMDBG   df	?	; Callback address to SWAT
SWTINF_LCLINTxx df	?	; Ptr to LCLINTxx table

SWATINFO_STR	ends		; End SWATINFO_STR structure

