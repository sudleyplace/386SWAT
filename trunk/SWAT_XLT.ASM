;' $Header:   P:/PVCS/386SWAT/SWAT_XLT.ASV   1.4   01 Jul 1997 17:46:38   BOB  $
	 title	 SWAT_XLT -- 386SWAT Character Translate Table
	 page	 58,122
	 name	 SWAT_XLT

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC

	 include SWAT_SEG.INC
.list

DATA	 segment use32 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

; Equates for CHARXLAT

@CX_ALPHA equ	 80h		; Alphabetic
@CX_UPPER equ	 40h		; Uppercase
@CX_DIGIT equ	 20h		; Numeric
@CX_SYMB  equ	 10h		; Symbol name

	 public  CHARXLAT
CHARXLAT db	 256 dup (0)					; 00-FF

	 org	 CHARXLAT+'#'
	 db	 @CX_SYMB					; 23

	 org	 CHARXLAT+'$'
	 db	 @CX_SYMB					; 24

	 org	 CHARXLAT+'0'
	 db	 10 dup (@CX_DIGIT or @CX_SYMB) 		; 30-39

	 org	 CHARXLAT+'?'
	 db	 @CX_SYMB					; 3F

	 org	 CHARXLAT+'@'
	 db	 @CX_SYMB					; 40

	 org	 CHARXLAT+'A'
	 db	 26 dup (@CX_ALPHA or @CX_UPPER or @CX_SYMB)	; 41-5A

	 org	 CHARXLAT+'_'
	 db	 @CX_SYMB					; 5F

	 org	 CHARXLAT+'a'
	 db	 26 dup (@CX_SYMB)				; 61-7A

	 org	 CHARXLAT+(size CHARXLAT) ; Skip to the end

DATA	 ends			; End DATA segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 NPPROC  IZITDIGIT -- Is AL A Digit?
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Determine whether or not AL is a digit

On entry:

AL	 =	 character to check

On exit:

CF	 =	 0 if a digit
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx>	; Save for a moment

	 lea	 ebx,CHARXLAT	; DS:EBX ==> translate table
	 xlat	 CHARXLAT[ebx]	; Translate character to type bits

	 test	 al,@CX_DIGIT	; Izit a digit?
	 setnz	 al		; AL = 1 if a digit
				;    = 0 if not
	 cmp	 al,1		; Izit a digit?
				; CF = 0 if so
				;    = 1 if not
	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZITDIGIT endp			; End IZITDIGIT procedure
	 NPPROC  IZITSYMB -- Is AL Valid In A Symbol Name?
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Determine whether or not AL is valid in a symbol name

On entry:

AL	 =	 character to check

On exit:

CF	 =	 0 if valid in a symbol name
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx>	; Save for a moment

	 lea	 ebx,CHARXLAT	; DS:EBX ==> translate table
	 xlat	 CHARXLAT[ebx]	; Translate character to type bits

	 test	 al,@CX_SYMB	; Izit valid in a symbol name?
	 setnz	 al		; AL = 1 if valid
				;    = 0 if not
	 cmp	 al,1		; Izit valid?
				; CF = 0 if so
				;    = 1 if not
	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZITSYMB endp			; End IZITSYMB procedure

PROG	 ends			; End PROG segment

	 MEND			; End SWAT_XLT module
