;' $Header:   P:/PVCS/386SWAT/SWAT_LCL.INV   1.4   09 Aug 1995 11:47:18   BOB  $
;
; (C) Copyright 1987-2004 Qualitas, Inc.  All rights reserved.
;
; SWAT_LCL.INC
;
; Equates for LCL_FLAG
;

LCL_REC record \
 $LCL_CR4:1,	\
 $LCL_I41:1,	\
 $LCL_NOWPCI:1, \
 $LCL_VENDOR:4, \
 $LCL_FSONLY:1, \
 $LCL_CPUID:1,	\
 $LCL_DUAL:1,	\
 $LCL_PCIMDS:1, \
 $LCL_PCIMDA:1, \
 $LCL_AGP:1,	\
 $LCL_SPCI:1,	\
 $LCL_DPCI:1,	\
 $LCL_PCI:1,	\
 $LCL_INIT:1,	\
 $LCL_CLR:1,	\
 $LCL_MDA:1,	\
 $LCL_BOTH:1,	\
 $LCL_IRET:1,	\
 $LCL_MSG:1,	\
 $LCL_SCRN:1,	\
 $LCL_STKD:1,	\
 $LCL_MONO:1,	\
 $LCL_NMI:1,	\
 $LCL_GENP:1,	\
 $LCL_PAGE:1,	\
 $LCL_IDX:1,	\
 $LCL_EDIT:1,	\
 $LCL_REDI:1,	\
 $LCL_WINTAB:1

@LCL_CR4    equ (mask $LCL_CR4)   ;80000000:  CR4 supported
@LCL_I41    equ (mask $LCL_I41)   ;40000000:  INT 41h hooked
@LCL_NOWPCI equ (mask $LCL_NOWPCI);20000000:  Disable Windows Dual PCI switching
@LCL_VENDOR equ (mask $LCL_VENDOR);1E000000:  Vendor from CPUID (see @VENDOR_xxx below)
@LCL_FSONLY equ (mask $LCL_FSONLY);01000000:  Fullscreen only in Windows (overrides no DVGA/MONO)
@LCL_CPUID equ	(mask $LCL_CPUID); 00800000:  CPUID instruction supported
@LCL_DUAL equ	(mask $LCL_DUAL) ; 00400000:  Use dual PCI VGA adapter for debugging
@LCL_PCIMDS equ (mask $LCL_PCIMDS);00200000:  Static version of @LCL_PCIMDA
@LCL_PCIMDA equ (mask $LCL_PCIMDA);00100000:  MDA hidden by PCI system (dynamic)
@LCL_AGP  equ	(mask $LCL_AGP)  ; 00080000:  PCI AGP controller present (VBDAGP filled in)
@LCL_SPCI equ	(mask $LCL_SPCI) ; 00040000:  Static version of @LCL_DPCI
@LCL_DPCI equ	(mask $LCL_DPCI) ; 00020000:  Dual PCI VGA adapters (dynamic)
@LCL_PCI  equ	(mask $LCL_PCI)  ; 00010000:  PCI BIOS present
@LCL_INIT equ	(mask $LCL_INIT) ; 00008000:  Initialization code run
@LCL_CLR  equ	(mask $LCL_CLR)  ; 00004000:  Color/graphics adapter
@LCL_MDA  equ	(mask $LCL_MDA)  ; 00002000:  Monochrome ...
@LCL_BOTH equ	(mask $LCL_BOTH) ; 00001000:  Both adapters present
@LCL_IRET equ	(mask $LCL_IRET) ; 00000800:  IRET_VEC calculated
@LCL_MSG  equ	(mask $LCL_MSG)  ; 00000400:  Error message received
@LCL_SCRN equ	(mask $LCL_SCRN) ; 00000200:  Clr = Screen restore enabled
				  ;	       Set = ...	    disabled
@LCL_STKD equ	(mask $LCL_STKD) ; 00000100:  Set = Display stack as dwords
				  ;	       Clr = ...	      words
@LCL_MONO equ	(mask $LCL_MONO) ; 00000080:  Set = Use monochrome adapter for debugging
				  ;	       Clr = Don't
@LCL_NMI  equ	(mask $LCL_NMI)  ; 00000040:  Set = Intercept INT 02h
				  ;	       Clr = Don't
@LCL_GENP equ	(mask $LCL_GENP) ; 00000020:  Set = Intercept INT 0Dh
				  ;	       Clr = Don't
@LCL_PAGE equ	(mask $LCL_PAGE) ; 00000010:  Set = Intercept INT 0Eh
				  ;	       Clr = Don't
@LCL_IDX  equ	(mask $LCL_IDX)  ; 00000008:  Set = Display DTE index
				  ;	       Clr = Don't
@LCL_EDIT equ	(mask $LCL_EDIT) ; 00000004:  Set = In edit mode
				  ;	       Clr = Not
@LCL_REDI equ	(mask $LCL_REDI) ; 00000002:  Set = Force re-display of screen
				  ;	       Clr = Don't
@LCL_WINTAB equ (mask $LCL_WINTAB);00000001:  Set = WINTAB initialized
				  ;	       Clr = Not

; Equates for @LCL_VENDOR
; Be sure to expand the size of the LCL_VENDOR field
; if more vendors are added

@VENDOR_UNK	equ 0		; Vendor is Unknown
@VENDOR_INTEL	equ 1		; ...	    "GenuineIntel"
@VENDOR_AMD	equ 2		; ...	    "AuthenticAMD"
@VENDOR_CYRIX	equ 3		; ...	    "CyrixInstead"
@VENDOR_CENTAUR equ 4		; ...	    "CentaurHauls"
@VENDOR_NEXGEN	equ 5		; ...	    "NexGenDriven"
@VENDOR_RISE	equ 6		; ...	    "RiseRiseRise"
@VENDOR_TMx86	equ 7		; ...	    "GenuineTMx86"
@VENDOR_UMC	equ 8		; ...	    "UMC UMC UMC "


