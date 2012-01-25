;' $Header:   P:/PVCS/386SWAT/SWAT_AGR.INV   1.3   14 Aug 1992 11:32:46   BOB  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; SWAT_AGR.INC
;
; Equates and structure for AGOTO amd ARET
;

ARET_STR struc

ARET_FVEC df	 ?		; Segment/selector:offset
ARET_MODE dw	 ?		; Mode
ARET_MASK dd	 ?		; Mask
ARET_BASE dd	 ?		; Instruction base

ARET_STR ends

@ARET_CNT equ	 128		; # entries

