;' $Header:   P:/PVCS/386SWAT/SWAT_MOD.INV   1.3   07 Nov 1995 20:23:08   BOB  $
;
; (C) Copyright 1987-95 Qualitas, Inc.	All rights reserved.
;
; SWAT_MOD.INC
;
; Equates for xxxMODE variables
;

@MODE_VM    equ  8000h		; Mode is VM86
@MODE_USE32 equ  4000h		; Unassemble as USE32 code segment
@MODE_NEW   equ  2000h		; Mode changed from last time
@MODE_INSTR equ  @MODE_NEW	; Searching instructions
@MODE_SEP   equ  1000h		; Separator specified (SEL, BASE, & MSK valid)
@MODE_PHYS  equ  0800h		; Use physical translation
@MODE_PTE   equ  0400h		; Searching PTEs

