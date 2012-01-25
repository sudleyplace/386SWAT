;' $Header:   P:/PVCS/386SWAT/SWAT_DBG.INV   1.3   10 Aug 1998 11:00:56   BOB  $
;
; (C) Copyright 1987-1999 Qualitas, Inc.  All rights reserved.
;
; SWAT_DBG.INC
;
; Equates for DBG_FLAG
;

@DBG_CAPS    equ 8000h		; DEBUG=CAPS
@DBG_INT     equ 4000h		; DEBUG=INT
@DBG_VMS     equ 2000h		; DEBUG=VMS
@DBG_IBV     equ 1000h		; DEBUG=IBV
@DBG_VMI     equ 0800h		; DEBUG=VMI
@DBG_PMI     equ 0400h		; DEBUG=PMI
@DBG_VCNT    equ 0200h		; VMSCOUNT specified
@DBG_TRIP    equ 0100h		; DEBUG=TRIP


; Code breakpoint structures and equates

BC_STR	struc

BC_LIN	dd	?		; 00:  Linear address
BC_OFF	dd	?		; 04:  Code offset
BC_SEL	dw	?		; 08:  ...  segment/selector
BC_FLAG dw	0		; 0A:  Flags (see SWAT_CMD.INC)
BC_VAL	db	?		; 0C:  Original value
	db	3 dup (?)	; 0D:  Filler

BC_STR	ends			; 10

@NBC	equ	8		; # code breakpoints supported


; Page breakpoint structures and equates

BP_STR	struc

BP_LIN	dd	?		; 00:  Linear address
BP_OFF	dd	?		; 04:  Code offset
BP_SEL	dw	?		; 08:  ...  segment/selector
BP_FLAG dw	0		; 0A:  Flags (see SWAT_CMD.INC)

BP_STR	ends			; 0C

@NBP	equ	8		; # page breakpoints supported


; Debug register structure and equates

BD_STR	struc			; Debug register structure

; The following values are dynamic

BD_REG	dd	?		; 00:  32-bit register value
BD_OFF	dd	0		; 04:  32-bit linear offset
BD_BASE dd	0		; 08:  32-bit linear base address
BD_SEL	dw	0		; 0C:  Selector/segment
BD_FLAG dw	0		; 0E:  Flags (see SWAT_CMD.INC)
BD_MON	dd	0		; 10:  Offset in DGROUP to monitor expression (0=none)
BD_LEN	db	?		; 14:  Length (00 = 1, 01 = 2, 10 = undef, 11 = 4)
BD_TYPE db	?		; 15:  Type   (00 = x, 01 = w, 10 = I/O rw, 11 = rw)

; The following values are static

BD_LSHF db	?		; 16:  Length/type shift amount
BD_ESHF db	?		; 17:  Enable	   ...
BD_SET	dd	?		; 18:  Action to set

BD_STR	ends			; 1C


