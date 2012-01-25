;' $Header$
	title	SWAT_SPC -- 386SWAT Space Fillers
	page	58,122
	name	SWAT_SPC

COMMENT|		Module Specifications

Copyright:  (C) Copyright 2002 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, June, 2002.

Modifications by:  None.


|
.386p
.xlist
	include MASM.INC

	include SWAT_SEG.INC
.list


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP

	public	@SWAT_SPC_PROG
@SWAT_SPC_PROG: 		; Mark module start in .MAP file

	public	@CntINSERT
@CntINSERT equ	2		; Maximum # PDEs needed for INSERT command

; Make room for PDEs for INSERT command

	public	INS_SPC
INS_SPC db	((4*1024) * @CntINSERT + (4*1024-1)) dup (?)

PROG	ends			; End PROG segment

	MEND			; End SWAT_SPC module
