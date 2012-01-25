;' $Header:   P:/PVCS/386SWAT/SWAT_LBR.INV   1.0   28 Jun 1996 17:54:50   BOB  $
;
; (C) Copyright 1987-2002 Qualitas, Inc.  All rights reserved.
;
; SWAT_LBR.INC
;
; Records, equates, and macros for Last Branch Reporting feature
;

@LBR_P4_NROW equ 1+4*2		; # rows in LBR P4 window
@LBR_P6_NROW equ 1+1*2		; ...		P6 ...
@LBR_EX_NROW equ 2		; ...		EX ...
@LBR_NCOL equ	1+8+1		; # cols ...
@LBR_P4_SROW equ @NROWS-@LBR_P4_NROW-@LBR_EX_NROW-1 ; Starting row of LBR P4 window (skipping cmd line)
@LBR_P6_SROW equ @NROWS-@LBR_P6_NROW-@LBR_EX_NROW-1 ; ...	      LBR P6 ...
@LBR_EX_SROW equ @NROWS-@LBR_EX_NROW-1		    ; ...	      LBR EX ...
@LBR_SCOL equ	@NCOLS-@LBR_NCOL ; Starting col of LBR window


CLR_LBR macro			; Clear The Last Branch Reporting Bit
	local	L1
COMMENT|

Clear the Last Branch Reporting bit if LBR is ON (which can happen only
if this CPU supports it).

Note that if LBR is enabled, we must be careful not to branch
before reading the MSRs so as not to change the MSR values.

|

	test	LC4_FLAG,@LC4_LBR ; Izit enabled?
	jz	short L1	; Jump if not

	REGSAVE <eax,ecx,edx>	; Save registers

	mov	ecx,@MSR6_DBGCTL ; Get Debug Control register
	RDMSR			; Read MSR into EDX:EAX
	and	eax,not @MSR6_DBGCTL_LBR ; Disable the LBR
	WRMSR			; Tell the CPU about it

	REGREST <edx,ecx,eax>	; Restore
L1:
	endm			; End CLR_LBR macro

