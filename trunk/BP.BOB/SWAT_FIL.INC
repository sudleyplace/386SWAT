;' $Header$
;
; (C) Copyright 1987-2001 Qualitas, Inc.  All rights reserved.
;
; SWAT_FIL.INC
;
; FILE_STR structure of common variables between 386MAX and SWAT
;

FINT_STR struc

FINT_4GB dw	?		; 00:  4GB selector
FINT_CR3 dw	?		; 02:  CR3 ...

FINT_STR ends


@IMODE_RVM equ	0		; RM/VCPI mode
@IMODE_PMG equ	1		; PM Interrupt Gate mode
@IMODE_PMI equ	2		; PM Intrude mode
@IMODE_CNT equ	3		; # modes
@IMODE_PMT equ	4		; PM TSS mode
;;;@IMODE_PML equ  5		   ; PM Load mode
;;;@IMODE_PMW equ  6		   ; PM Windows mode
@IMODE_NONE equ -1		; Should never occur


FILE_STR struc

FILE_4GB dw	?		; 00:  Descriptor table entry for DTE_D4GB
FILE_VID dw	?		; 02:  ...			  Video Buffer
FILE_CR3 dw	?		; 04:  ...			  Page Directory Base Register
FOLD_4GB dw	?		; 06:  Previous DTE for 4GB selector
FOLD_CR3 dw	?		; 08:  ...		CR3 ...
FINT_BEG db	(@IMODE_CNT * (type FINT_STR)) dup (?) ; 0A:  Selectors for various modes
	 dw	6 dup (?)	; 16:  Reserved

FILE_STR ends


