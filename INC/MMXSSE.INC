;' $Header$
;
; (C) Copyright 2001 Qualitas, Inc.  All rights reserved.
;
; MMXSSE.INC
;
; MMX & SSE macros, strcutures, and equates
;


FXSAVE	macro	MEM
	local	L1,L2,reg,regp

;; Note that this macro doesn't handle memory references
;; other than in DS.

if @WordSize eq 4
reg	equ	<eax>
regp	equ	<dword ptr>
else
reg	equ	<ax>
regp	equ	<word ptr>
endif

	db	0Fh
L1:
	add	regp MEM,reg
L2:
	org	L1
	db	0AEh
	org	L2

	endm			; FXSAVE


MOVD	macro	R32,MM
	local	L1,L2,reg

;; Note that this macro doesn't handle memory references
;; other than in DS.

    ifidni <MM>,<mm0>
reg	equ	<eax>
elseifidni <MM>,<mm1>
reg	equ	<ecx>
elseifidni <MM>,<mm2>
reg	equ	<edx>
elseifidni <MM>,<mm3>
reg	equ	<ebx>
elseifidni <MM>,<mm4>
reg	equ	<esp>
elseifidni <MM>,<mm5>
reg	equ	<ebp>
elseifidni <MM>,<mm6>
reg	equ	<esi>
elseifidni <MM>,<mm7>
reg	equ	<edi>
endif


if @WordSize eq 4
	db	66h
endif
	db	0Fh
L1:
	add	R32,reg
L2:
	org	L1
	db	7Eh
	org	L2

	endm			; MOVD


MOVQ	macro	MEM,MM
	local	L1,L2,reg

;; Note that this macro doesn't handle memory references
;; other than in DS.

    ifidni <MM>,<mm0>
reg	equ	<eax>
elseifidni <MM>,<mm1>
reg	equ	<ecx>
elseifidni <MM>,<mm2>
reg	equ	<edx>
elseifidni <MM>,<mm3>
reg	equ	<ebx>
elseifidni <MM>,<mm4>
reg	equ	<esp>
elseifidni <MM>,<mm5>
reg	equ	<ebp>
elseifidni <MM>,<mm6>
reg	equ	<esi>
elseifidni <MM>,<mm7>
reg	equ	<edi>
endif


if @WordSize eq 4
	db	66h
endif
	db	0Fh
L1:
	add	dword ptr MEM,reg
L2:
	org	L1
	db	7Fh
	org	L2

	endm			; MOVQ


MOVDQU	macro	MEM,MM
	local	L1,L2,reg

;; Note that this macro doesn't handle memory references
;; other than in DS.

    ifidni <MM>,<xmm0>
reg	equ	<eax>
elseifidni <MM>,<xmm1>
reg	equ	<ecx>
elseifidni <MM>,<xmm2>
reg	equ	<edx>
elseifidni <MM>,<xmm3>
reg	equ	<ebx>
elseifidni <MM>,<xmm4>
reg	equ	<esp>
elseifidni <MM>,<xmm5>
reg	equ	<ebp>
elseifidni <MM>,<xmm6>
reg	equ	<esi>
elseifidni <MM>,<xmm7>
reg	equ	<edi>
endif

	db	0F3h,0Fh
L1:
	add	dword ptr MEM,reg
L2:
	org	L1
	db	7Fh
	org	L2

	endm			; MOVDQU


FXSAVE_STR struc

FXSAVE_FCW dw	?		; 00:  FPU Control Word
FXSAVE_FSW dw	?		; 02:  FPU Status Word
	db	?		; 04:  (Reserved)
FXSAVE_FTW db	?		; 05:  FPU Tag Word
FXSAVE_FOP dw	?		; 06:  Opode
FXSAVE_FPUCODE df ?		; 08:  FPU Instruction Pointer
	dw	?		; 0E:  (Reserved)
FXSAVE_FPUDATA df ?		; 10:  FPU Data Pointer
	dw	?		; 16:  (Reserved)
FXSAVE_MXCSR dd ?		; 18:  MMX Control & Status Register
	dd	?		; 1C:  (Reserved)
FXSAVE_ST0MM0 dt ?		; 20:  ST0/MM0
	dw	3 dup (?)	; 2A:  (Reserved)
FXSAVE_ST1MM1 dt ?		; 30:  ST1/MM1
	dw	3 dup (?)	; 3A:  (Reserved)
FXSAVE_ST2MM2 dt ?		; 40:  ST2/MM2
	dw	3 dup (?)	; 4A:  (Reserved)
FXSAVE_ST3MM3 dt ?		; 50:  ST3/MM3
	dw	3 dup (?)	; 5A:  (Reserved)
FXSAVE_ST4MM4 dt ?		; 60:  ST4/MM4
	dw	3 dup (?)	; 6A:  (Reserved)
FXSAVE_ST5MM5 dt ?		; 70:  ST5/MM5
	dw	3 dup (?)	; 7A:  (Reserved)
FXSAVE_ST6MM6 dt ?		; 80:  ST6/MM6
	dw	3 dup (?)	; 8A:  (Reserved)
FXSAVE_ST7MM7 dt ?		; 90:  ST7/MM7
	dw	3 dup (?)	; 9A:  (Reserved)
FXSAVE_XMM0 dq	2 dup (?)	; A0:  XMM0
FXSAVE_XMM1 dq	2 dup (?)	; B0:  XMM1
FXSAVE_XMM2 dq	2 dup (?)	; C0:  XMM2
FXSAVE_XMM3 dq	2 dup (?)	; D0:  XMM3
FXSAVE_XMM4 dq	2 dup (?)	; E0:  XMM4
FXSAVE_XMM5 dq	2 dup (?)	; F0:  XMM5
FXSAVE_XMM6 dq	2 dup (?)	;100:  XMM6
FXSAVE_XMM7 dq	2 dup (?)	;110:  XMM7
	db	(14*16) dup (?) ;120:  (Reserved)

FXSAVE_STR ends


