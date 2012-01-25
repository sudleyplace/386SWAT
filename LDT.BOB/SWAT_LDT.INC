;' $Header$
;
; (C) Copyright 2003 Qualitas, Inc.  All rights reserved.
;
; SWAT_LDT.INC
;
; Common LDT structures, macros, and equates for 386SWAT
;

DLDT_STR struc

DLDT_CS    dq	?		; 00:  Low DOS memory Code Selector
DLDT_DS    dq	?		; 08:  ...	      Data ...
DLDT_4GB   dq	?		; 10:  All memory selector
DLDT_SSB0S dq	?		; 18:  LDTE_SS with Big bit clear, 64KB length
DLDT_SSB0L dq	?		; 20:  LDTE_SS with Big bit clear, 4GB length
DLDT_CS4GB dq	?		; 28:  LDTE_CS, 4GB length

DLDT_STR ends

LDTE_CS    equ	DLDT_CS    or (mask $TI)
LDTE_DS    equ	DLDT_DS    or (mask $TI)
LDTE_4GB   equ	DLDT_4GB   or (mask $TI)
LDTE_SSB0S equ	DLDT_SSB0S or (mask $TI)
LDTE_SSB0L equ	DLDT_SSB0L or (mask $TI)
LDTE_CS4GB equ	DLDT_CS4GB or (mask $TI)


SETLDTX macro	FL
	local	L1

ifnb <FL>
	pushf			; Save flags
endif				; IFNB <FL>
	push	ax		; Save for a moment
	mov	ax,cs		; Get code selector

	test	al,mask $TI	; Izit already in LDT?
	jnz	short L1	; Jump if so

	add	ax,2*(size DESC_STR) ; Skip to LDT selector
	lldt	ax		; Address it
L1:
	pop	ax		; Restore
ifnb <FL>
	popf			; Restore flags
endif				; IFNB <FL>
	endm			; SETLDT


