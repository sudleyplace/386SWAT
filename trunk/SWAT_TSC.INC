;' $Header:   P:/PVCS/386SWAT/SWAT_TSC.INV   1.0   24 Jul 1997 15:43:38   BOB  $
;
; (C) Copyright 1987-97 Qualitas, Inc.	All rights reserved.
;
; SWAT_TSC.INC
;
; Records, equates, and macros for Time Stamp Counting
;

GET_TSC macro	T		; Get Time Stamp Counter
	local	L1

	test	CPUFET_FLAG,@CPUFET_TSCNT ; Duzit support Time Stamp Counter?
	jz	short L1	; Jump if not

	REGSAVE <eax,edx>	; Save for a moment

	RDTSC			; Get current Time Stamp Counter
	mov	T&_TSC.EDQLO,eax ; Save for later use
	mov	T&_TSC.EDQHI,edx ; ...

	REGREST <edx,eax>	; Restore
L1:
	endm			; End GET_TSC macro

