;' $Header:   P:/PVCS/386SWAT/SWAT_LOG.INV   1.0   16 Oct 1992 17:53:42   HENRY  $
;
; (C) Copyright 1992 Qualitas, Inc.  All rights reserved.
;
; SWAT_LOG.INC
;
; Common macros for sending messages to error log
;

	 LOGDISP macro	MSG
	 local L1

DATA	 segment

L1 db	 MSG,0

DATA	 ends

	 push	 offset DGROUP:L1 ; Pass offset of message on stack
	 call	 LDISPMSG	; Display to error log

	 endm			; End LOGDISP macro

	 F2LOGDISP macro MSG
	 local L1

DATA	 segment

L1 db	 MSG,0

DATA	 ends

	 push	 offset DGROUP:L1 ; Pass offset of message on stack
	 CALLP	 FPLDISPMSG	; Display to error log

	 endm			; End F2LOGDISP macro

