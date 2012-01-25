;' $Header:   P:/PVCS/386SWAT/SWAT_LBR.INV   1.0   28 Jun 1996 17:54:50   BOB  $
;
; (C) Copyright 1987-96 Qualitas, Inc.	All rights reserved.
;
; SWAT_LBR.INC
;
; Records, equates, and macros for Last Branch Reporting feature
;

@LBR_NROW equ	1+4		; # rows in LBR window
@LBR_NCOL equ	1+1+8		; # cols ...
@LBR_SROW equ	@NROWS-@LBR_NROW-1 ; Starting row of LBR window (skipping cmd line)
@LBR_SCOL equ	@NCOLS-@LBR_NCOL ; ...	    col ...


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
	and	eax,not @DBGCTL_LBR ; Disable the LBR
	WRMSR			; Tell the CPU about it

	REGREST <edx,ecx,eax>	; Restore
L1:
	endm			; End CLR_LBR macro

