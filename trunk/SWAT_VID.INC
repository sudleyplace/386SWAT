;' $Header:   P:/PVCS/386SWAT/SWAT_VID.INV   1.3   23 Jun 1992 15:47:20   DAVID  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; SWAT_VID.INC
;
; 386SWAT's video equates
;

; Equate for VIDBASE

@VID_MDA  equ	 000B0000h	; Monochrome video base address
@VID_CLR  equ	 000B8000h	; Color ...
@VID_FLIP equ	 @VID_CLR xor @VID_MDA ; Bits to flip


; Equates for SET_VIDPTE

@VID_MDAPTE equ  (000B0000h + @PTE_URP)
@VID_CLRPTE equ  (000B8000h + @PTE_URP)


; Equate for CRTC

@CRT_MDA  equ	 03B4h		; Monochrome CRT controller address
@CRT_CLR  equ	 03D4h		; Color ...
@CRT_FLIP equ	 @CRT_CLR xor @CRT_MDA ; Bits to flip in CRTC


; Equates for TXTMODE

@TXT_MDA  equ	 07h		; Monochrome mode
@TXT_CLR  equ	 03h		; Color ...
@TXT_FLIP equ	 @TXT_MDA xor @TXT_CLR ; Bits to flip


; Equates for VIDTYPE

@CUR_MDA  equ	 000B0A0Bh	; Monochrome normal/insert cursor type
@CUR_CLR  equ	 00070607h	; Color ...
@CUR_FLIP equ	 @CUR_MDA xor @CUR_CLR ; Bits to flip


