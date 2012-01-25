;' $Header:   P:/PVCS/386SWAT/SWAT_CMD.INV   1.5   20 Sep 1994 16:48:30   BOB  $
;
; (C) Copyright 1987-94 Qualitas, Inc.	All rights reserved.
;
; SWAT_CMD.INC
;
; CMDARG_MAC macro and address and command flags
;

@ADDR_SEP equ	 8000h		; 1 = Separator specified
				; 0 = not
@ADDR_PM  equ	 4000h		; 1 = Protected mode (if @ADDR_SEP)
				; 0 = VM 8086 mode   (if @ADDR_SEP)
@ADDR_ENA equ	 2000h		; 1 = Enabled
				; 0 = Disabled
@ADDR_INUSE equ  1000h		; 1 = In use
				; 0 = available
@ADDR_USE32 equ  0800h		; 1 = USE32 (if @ADDR_SEP)
				; 0 = USE16 ...
@ADDR_CODE  equ  0400h		; 1 = Code selector (if @ADDR_SEP)
				; 0 = not ...

; Equates for CMD_FLAG

@CMD_INS equ	 8000h		; Insert state


; Macro for command arguments

CMDARG_MAC macro TXT,ACT,LCL
	 local	 LCL_TXT,LCL_LEN

DATA	 segment use32 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

LCL_TXT  db	 TXT
LCL_LEN  equ	 $-LCL_TXT

DATA	 ends			; End DATA segment


SEG_LEN  segment use32 dword public 'data' ; Start SEG_LEN segment
	 assume  ds:DGROUP

	 dd	 LCL_LEN

SEG_LEN  ends			; End SEG_LEN segment


SEG_TAB  segment use32 dword public 'data' ; Start SEG_TAB segment
	 assume  ds:DGROUP

	 dd	 offset DGROUP:LCL_TXT

SEG_TAB  ends			; End SEG_TAB segment


SEG_ACT  segment use32 dword public 'data' ; Start SEG_ACT segment
	 assume  ds:DGROUP

	 dd	 offset PGROUP:ACT

SEG_ACT  ends			; End SEG_ACT segment


ifb <LCL>
PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 extrn	 ACT:near

PROG	 ends			; End PROG segment
endif				; IFB <LCL>

	 endm			; CMDARG_MAC

