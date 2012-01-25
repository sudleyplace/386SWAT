;' $Header$
;
; (C) Copyright 2001 Qualitas, Inc.  All rights reserved.
;
; SWAT_OLD.INC
;
; Macro for OLDINTS
;

@OLDINTS equ	<00,01,02,03,05,06,09,0A,0B,B2,0C,C2,0D,0E,67,68>

OLDINT_MAC macro NN

LEN	=	0
%	irp	XX,<@OLDINTS>	; Run through OLDINTS
LEN	=	LEN + 1
	endm			; IRP

CNT	=	0
%	irp	XX,<@OLDINTS>	; Run through OLDINTS
ifidn <NN>,<XX>
	sub	esp,2		; Make room for selector
	push	CNT		; Pass index into @OLDINTS
	call	PushOldInt	; Push old interrupt vectors
	exitm
else
CNT	=	CNT + 1
endif

if CNT eq LEN
%out Missing interrupt NN
.err
endif
	endm			; IRP
	endm			; OLDINT_MAC


