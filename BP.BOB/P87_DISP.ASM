;' $Header:   P:/PVCS/386SWAT/P87_DISP.ASV   1.6   01 Jul 1997 17:46:18   BOB  $
	title	P87_DISP -- POP87 Display Routines
	page	58,122
	name	P87_DISP

COMMENT |		 Module Specifications

Copyright:  (C) Copyright 1985-97 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May 1985.

Modifications by:  None.

|
.386
.xlist
	include DOS.INC
	include MASM.INC
	include 386.INC
	include PTR.INC
	include BITFLAGS.INC

	include POP87.INC
	include SWAT_FMT.INC
	include SWAT_SEG.INC
.list

DATA	segment use32 dword public 'data' ; Start DATA segment
	assume  ds:DGROUP

	extrn	DISP_STATUS:byte
	extrn	HEXTAB:byte
	extrn	SCRN:byte
	extrn	TGW2:word
	extrn	OCW2:word
	extrn	OCW3:word
	extrn	INSTROUT:byte
	extrn	@OFFBYTE:abs
	extrn	S_DCLEN:abs
	extrn	HEXTABLE:byte

FP_STR	struc

FP_MAN0 db	?		; Low-order bytes of a TBYTE-format number
FP_MAN1 db	?
FP_MAN2 db	?
FP_MAN3 db	?
FP_MAN4 db	?
FP_MAN5 db	?
FP_MAN6 db	?
FP_MAN7 db	?
FP_EXP	dw	?		; Exponent and sign

FP_STR	ends


ENV_STR struc

CTL_WD	dw	?,0
STA_WD	dw	?,0
TAG_WD	dw	?,0
	dw	?,0
	dw	?,0
	dw	?,0
	dw	?,0

ENV_STR ends


ENV	ENV_STR <>

	public  BCD
BCD	dt	?		; Save area for BCD format

	public  MANTISSA,EXP2,EXP10
MANTISSA dt	?		; Fractional part of number
EXP2	dw	?		; Binary exponent ...
EXP10	dw	?		; Decimal exponent ...

	public	CON10
CON10	dd	10		; Constant 10

	public  ASCII,MSIGN,MDIGITS,ESIGN,EDIGITS
ASCII	label	byte		; Signed ASCII numeric conversion
MSIGN	db	?		; The mantissa sign
MDEC	db	?		; The decimal point
MDIGITS db	18 dup (?)	; The mantissa digits
	db	'nnn'           ; Additional digits
	db	'E'             ; The exponent symbol
ESIGN	db	?		; The exponent sign
EDIGITS db	5 dup (?)	; The exponent digits
EDIGITZ label	byte		; End of exponent digits
	db	' '             ; Separator
NTYPE	db	?		; Terminator
ASCIIZ	label	byte		; End of the line

	public  TEN17,TEN18
TEN17	dq	1E17
TEN18	dq	1E18

DENORM_CNT dw	?

FINDEF	dt	0FFFFC000000000000000h ; The indefinite
FPZERO	dt	0FFFE0000000000000000h ; A pseudo-zero

	align	4
TX_RC	dd	offset DGROUP:TXT_RC00
	dd	offset DGROUP:TXT_RC01
	dd	offset DGROUP:TXT_RC10
	dd	offset DGROUP:TXT_RC11

TXT_RC00 db	'Near',0
TXT_RC01 db	'Down',0
TXT_RC10 db	'Up  ',0
TXT_RC11 db	'Chop',0

	align	4
TX_PC	dd	offset DGROUP:TXT_PC00
	dd	offset DGROUP:TXT_PC01
	dd	offset DGROUP:TXT_PC10
	dd	offset DGROUP:TXT_PC11

TXT_PC00 db	'24',0
TXT_PC01 db	'--',0
TXT_PC10 db	'53',0
TXT_PC11 db	'64',0

	align	4
TX_IC	dd	offset DGROUP:TXT_IC0
	dd	offset DGROUP:TXT_IC1

TXT_IC0 db	'Proj',0
TXT_IC1 db	'Affn',0

	align	4
TX_TST	dd	offset DGROUP:TXT_TST00
	dd	offset DGROUP:TXT_TST01
	dd	offset DGROUP:TXT_TST10
	dd	offset DGROUP:TXT_TST11

TXT_TST00 db	'>',0
TXT_TST01 db	'<',0
TXT_TST10 db	'=',0
TXT_TST11 db	'?',0

	align	4
TX_REM	dd	offset DGROUP:TXT_REM0000
	dd	offset DGROUP:TXT_REM0001
	dd	offset DGROUP:TXT_REM0010
	dd	offset DGROUP:TXT_REM0011
	dd	offset DGROUP:TXT_REM0100
	dd	offset DGROUP:TXT_REM0101
	dd	offset DGROUP:TXT_REM0110
	dd	offset DGROUP:TXT_REM0111
	dd	offset DGROUP:TXT_REM1000
	dd	offset DGROUP:TXT_REM1001
	dd	offset DGROUP:TXT_REM1010
	dd	offset DGROUP:TXT_REM1011
	dd	offset DGROUP:TXT_REM1100
	dd	offset DGROUP:TXT_REM1101
	dd	offset DGROUP:TXT_REM1110
	dd	offset DGROUP:TXT_REM1111

TXT_REM0000 db	'Q=000',0
TXT_REM0001 db	'Q=001',0
TXT_REM0010 db	'Q=010',0
TXT_REM0011 db	'Q=011',0
TXT_REM0100 db	'Q=100',0
TXT_REM0101 db	'Q=101',0
TXT_REM0110 db	'Q=110',0
TXT_REM0111 db	'Q=111',0
TXT_REM1000 label byte
TXT_REM1001 label byte
TXT_REM1010 label byte
TXT_REM1011 label byte
TXT_REM1100 label byte
TXT_REM1101 label byte
TXT_REM1110 label byte
TXT_REM1111 label byte
	    db	'Inc  ',0

	align	4
TX_XAM	dd	offset DGROUP:TXT_XAM0000
	dd	offset DGROUP:TXT_XAM0001
	dd	offset DGROUP:TXT_XAM0010
	dd	offset DGROUP:TXT_XAM0011
	dd	offset DGROUP:TXT_XAM0100
	dd	offset DGROUP:TXT_XAM0101
	dd	offset DGROUP:TXT_XAM0110
	dd	offset DGROUP:TXT_XAM0111
	dd	offset DGROUP:TXT_XAM1000
	dd	offset DGROUP:TXT_XAM1001
	dd	offset DGROUP:TXT_XAM1010
	dd	offset DGROUP:TXT_XAM1011
	dd	offset DGROUP:TXT_XAM1100
	dd	offset DGROUP:TXT_XAM1101
	dd	offset DGROUP:TXT_XAM1110
	dd	offset DGROUP:TXT_XAM1111

TXT_XAM0000 db	'+Unnorm  ',0
TXT_XAM0001 db	'+NaN     ',0
TXT_XAM0010 db	'-Unnorm  ',0
TXT_XAM0011 db	'-NaN     ',0
TXT_XAM0100 db	'+Normal  ',0
TXT_XAM0101 db	'+Infinity',0
TXT_XAM0110 db	'-Normal  ',0
TXT_XAM0111 db	'-Infinity',0
TXT_XAM1000 db	'+Zero    ',0
TXT_XAM1001 db	' Empty   ',0
TXT_XAM1010 db	'-Zero    ',0
TXT_XAM1011 db	' Empty   ',0
TXT_XAM1100 db	'+Denormal',0
TXT_XAM1101 db	' Empty   ',0
TXT_XAM1110 db	'-Denormal',0
TXT_XAM1111 db	' Empty   ',0

	align	4
TX_XAM2_PZERO label dword
TX_XAM2 dd	offset DGROUP:TXT_XAM20000
TX_XAM2_PSNAN label dword
	dd	offset DGROUP:TXT_XAM20001
TX_XAM2_NZERO label dword
	dd	offset DGROUP:TXT_XAM20010
TX_XAM2_INDEF label dword
TX_XAM2_NSNAN label dword
	dd	offset DGROUP:TXT_XAM20011
	dd	offset DGROUP:TXT_XAM20100
	dd	offset DGROUP:TXT_XAM20101
	dd	offset DGROUP:TXT_XAM20110
	dd	offset DGROUP:TXT_XAM20111
	dd	offset DGROUP:TXT_XAM21000
	dd	offset DGROUP:TXT_XAM21001
	dd	offset DGROUP:TXT_XAM21010
	dd	offset DGROUP:TXT_XAM21011
	dd	offset DGROUP:TXT_XAM21100
	dd	offset DGROUP:TXT_XAM21101
	dd	offset DGROUP:TXT_XAM21110
	dd	offset DGROUP:TXT_XAM21111

TXT_XAMPZERO db '+Pseudo zero                    ',0
TXT_XAM20000 db '+n.nnnnnnnnnnnnnnnnnnnnE-nnnn  U',0
TXT_XAMPSNAN db '+SNaN                           ',0
TXT_XAM20001 db '+QNaN                           ',0
TXT_XAMNZERO db '-Pseudo zero                    ',0
TXT_XAM20010 db '-n.nnnnnnnnnnnnnnnnnnnnE-nnnn  U',0
TXT_XAMINDEF db ' Indefinite                     ',0
TXT_XAMNSNAN db '-SNaN                           ',0
TXT_XAM20011 db '-QNaN                           ',0
TXT_XAM20100 db '+n.nnnnnnnnnnnnnnnnnnnnE-nnnn   ',0
TXT_XAM20101 db '+Infinity                       ',0
TXT_XAM20110 db '-n.nnnnnnnnnnnnnnnnnnnnE-nnnn   ',0
TXT_XAM20111 db '-Infinity                       ',0
TXT_XAM21000 db '+Zero                           ',0
TXT_XAM21001 db ' Empty                          ',0
TXT_XAM21010 db '-Zero                           ',0
TXT_XAM21011 db ' Empty                          ',0
TXT_XAM21100 db '+n.nnnnnnnnnnnnnnnnnnnnE-nnnn  D',0
TXT_XAM21101 db ' Empty                          ',0
TXT_XAM21110 db '-n.nnnnnnnnnnnnnnnnnnnnE-nnnn  D',0
TXT_XAM21111 db ' Empty                          ',0

	align	4
D_XAMACT dd	offset PGROUP:XAMACT0000 ; +Unnormal
	dd	offset PGROUP:XAMACT0001 ; +NaN
	dd	offset PGROUP:XAMACT0010 ; -Unnormal
	dd	offset PGROUP:XAMACT0011 ; -NaN
	dd	offset PGROUP:XAMACT0100 ; +Normal
	dd	offset PGROUP:XAMACT0101 ; +Infinity
	dd	offset PGROUP:XAMACT0110 ; -Normal
	dd	offset PGROUP:XAMACT0111 ; -Infinity
	dd	offset PGROUP:XAMACT1000 ; +Zero
	dd	offset PGROUP:XAMACT1001 ;  Empty
	dd	offset PGROUP:XAMACT1010 ; -Zero
	dd	offset PGROUP:XAMACT1011 ;  Empty
	dd	offset PGROUP:XAMACT1100 ; +Denormal
	dd	offset PGROUP:XAMACT1101 ;  Empty
	dd	offset PGROUP:XAMACT1110 ; -Denormal
	dd	offset PGROUP:XAMACT1111 ;  Empty

	align	4
TX_TAG	dd	offset DGROUP:TXT_TG00
	dd	offset DGROUP:TXT_TG01
	dd	offset DGROUP:TXT_TG10
	dd	offset DGROUP:TXT_TG11

TXT_TG00 db	'Valid  ',0
TXT_TG01 db	'Zero   ',0
TXT_TG10 db	'Special',0
TXT_TG11 db	'Empty  ',0

FW	macro	NAM,D

	irp	X,<NAM>
	public  PR_&&X
PR_&&X	label	dword
	endm			; IRP

	irp	X,<D>
	extrn	F_&&X:tbyte
	dd	offset DGROUP:F_&&X
	endm			; IRP

	dw	0

	endm			; FW

; Pointers to display & change action pointers

	align	4
	FW	<CW0,CW1,CW2,CW3>,<>		; Dummy entry
;;;;;;; FW	<CW0>,<IC,@IC>
;;;;;;; FW	<CW1>,<RC0,RC1,@RC,PC0,PC1,@PC>
;;;;;;; FW	<CW2>,<IEM,PM,UM>
;;;;;;; FW	<CW3>,<OM,ZM,DM,IM>
	FW	<IC>,<@IC,CW0>
	FW	<@IC,@RC,@PC>,<>		; Dummy entry
	FW	<RC0,RC1>,<@RC,CW1>
	FW	<PC0,PC1>,<@PC,CW1>
	FW	<IEM,PM,UM>,<CW2>
	FW	<OM,ZM,DM,IM>,<CW1>
	FW	<SW0,SW1,SW2,SW3>,<>		; Dummy entry
;;;;;;; FW	<SW0>,<BUSY,CC3,TOP0,TOP1,FTST,FREM,FXAM>
;;;;;;; FW	<SW1>,<TOP2,CC2,CC1,CC0,FTST,FREM,FXAM>
;;;;;;; FW	<SW2>,<IR,PE,UE>
;;;;;;; FW	<SW3>,<OE,ZE,DE,IE>
	FW	<BUSY>,<SW0>
	FW	<CC3>,<FTST,FREM,FXAM,SW0>
	FW	<TOP0,TOP1,TOP2>,<>		; Dummy entry
;;;;;;; FW	<TOP0,TOP1>,<SW0,SP>
;;;;;;; FW	<TOP2>,<SW1,SP>
	FW	<CC2,CC1,CC0>,<FTST,FREM,FXAM,SW1>
	FW	<FTST,FREM,FXAM>,<>		; Dummy entry
	FW	<IR,PE,UE>,<SW2>
	FW	<OE,ZE,DE,IE>,<SW3>
	FW	<TAG0>,<@TG0>
	FW	<TAG1>,<@TG1>
	FW	<TAG2>,<@TG2>
	FW	<TAG3>,<@TG3>
	FW	<TAG4>,<@TG4>
	FW	<TAG5>,<@TG5>
	FW	<TAG6>,<@TG6>
	FW	<TAG7>,<@TG7>
	FW	<@TG0,@TG1,@TG2,@TG3,@TG4,@TG5,@TG6,@TG7>,<>
	FW	<CS0,CS1,CS2,CS3>,<>		; Dummy entry
	FW	<IPT0,IPT1,IPT2,IPT3>,<>	; Dummy entry
	FW	<DS0,DS1,DS2,DS3>,<>		; Dummy entry
	FW	<OPT0,OPT1,OPT2,OPT3>,<>	; Dummy entry
	FW	<OPC0>,<>			; Dummy entry
	FW	<OPC1,OPC2,OPC3>,<DC>
;;;;;;; FW	<DC,SP>,<>			; Dummy entry
	FW	<DC>,<> 			; Dummy entry
	irpc	X,01234567
	FW	<NM&X>,<>			; Dummy entry
	FW	<ST&X&A,ST&X&B,ST&X&C,ST&X&D,ST&X&E,ST&X&F,ST&X&G,ST&X&H,ST&X&I,ST&X&J>,<NM&X,TAG&X,@TG&X>
	FW	<ST&X&K,ST&X&L,ST&X&M,ST&X&N,ST&X&O,ST&X&P,ST&X&Q,ST&X&R,ST&X&S,ST&X&T>,<NM&X,TAG&X,@TG&X>
	endm			; IRPC

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP

	extrn	NCOLS:abs
	extrn	INSTRDEC:near
	extrn	CLEAR_OUT:near
	extrn	DD2DEC:near

	NPPROC	GET_SCR_OFF -- Get Screen Offset Into ES:EDI
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get screen offset

On entry:

DS:ESI	==>	FSTR structure for current entry

On exit:

ES:EDI	==>	screen offset for text display

|

	push	eax		; Save register

	movzx	eax,DGROUP:[esi].F_ROW ; Get row #
	mov	ah,NCOLS	; # window columns
	mul	ah		; AX = byte offset to row
	add	al,DGROUP:[esi].F_COL	; Plus byte offset to column
	adc	ah,0		; In case it carried
	lea	edi,SCRN[eax]	; ES:EDI ==> window position

	pop	eax		; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_SCR_OFF endp		; End GET_SCR_OFF procedure
	NPPROC  D_BIT -- Display One Bit
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display one bit

On entry:

DS:ESI	==>	FSTR structure for current entry

|

	REGSAVE <eax,ebx,ecx,edi> ; Save registers

	call	GET_SCR_OFF	; Get screen offset into ES:EDI

	mov	ebx,DGROUP:[esi].F_PVAL ; DS:EBX ==> value
	mov	ax,DGROUP:[ebx] ; DX = value
	mov	cl,DGROUP:[esi].F_SHFT ; Get shift amount
	shr	ax,cl		; Shift to low-order position
	and	al,1		; Isolate the bit
	add	al,'0'          ; Convert to ASCII
S32	stos	es:[edi].LO	; Store in output area

	mov	DISP_STATUS,1	; Mark as needing display

	REGREST <edi,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

D_BIT	endp			; End D_BIT procedure
	NPPROC  D_2BIT -- Display Two Bits
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display two bits

On entry:

DS:ESI	==>	FSTR structure for current entry

|

	REGSAVE <eax,ebx,ecx,edi> ; Save registers

	call	GET_SCR_OFF	; Get screen offset into ES:EDI

	mov	ebx,DGROUP:[esi].F_PVAL ; DS:EBX ==> value
	mov	ax,DGROUP:[ebx] ; AX = value
	and	ax,DGROUP:[esi].F_MSK	; Isolate the bits
	mov	cl,DGROUP:[esi].F_SHFT ; Get shift amount
	shr	ax,cl		; Shift to low-order position

	mov	cl,2
	div	cl		; Shift bits into AH & AL
	add	ax,'00'         ; Convert to ASCII
S32	stos	es:[edi].ELO	; Store in output area

	mov	DISP_STATUS,1	; Mark as needing display

	REGREST <edi,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

D_2BIT	endp			; End D_2BIT procedure
	NPPROC  D_NIB -- Display A Nibble
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display a nibble

On entry:

DS:ESI	==>	FSTR structure for current entry

|

	REGSAVE <eax,ebx,ecx,edi> ; Save registers

	call	GET_SCR_OFF	; Get screen offset into ES:EDI

	mov	ebx,DGROUP:[esi].F_PVAL ; DS:EBX ==> value
	mov	ax,DGROUP:[ebx] ; AX = value
	mov	cl,DGROUP:[esi].F_SHFT ; Get shift amount
	shr	ax,cl		; Shift to low-order position
	and	al,0Fh  	; Isolate nibble

	lea	ebx,HEXTAB	; DS:EBX ==> translate table
	xlat	HEXTAB[ebx]	; Translate to hex
S32	stos	es:[edi].LO	; Store in output area

	mov	DISP_STATUS,1	; Mark as needing display

	REGREST <edi,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

D_NIB	endp			; End D_NIB procedure
	NPPROC  T_TXT_SUB -- Display Text Subroutine
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display text subroutine

On entry:

EBX	=	index # into table of dwords
DS:EDX	==>	text table to display
DS:ESI	==>	FSTR structure for current entry

|

	REGSAVE <eax,ebx,esi,edi> ; Save registers

	call	GET_SCR_OFF	; Get screen offset into ES:EDI

	mov	esi,DGROUP:[edx+ebx*4] ; DS:ESI ==> source text
T_TXT_NEXT:
	lods	ds:[esi].LO	; Get next byte

	and	al,al		; End of the line?
	jz	short T_TXT_EXIT ; No more

S32	stos	es:[edi].LO	; Store in output area

	jmp	short T_TXT_NEXT ; Go around again

T_TXT_EXIT:
	REGREST <edi,esi,ebx,eax> ; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

T_TXT_SUB endp			; End T_TXT_SUB procedure
	NPPROC  T_TXT -- Display Text
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display text

On entry:

DS:EDX	==>	text table to display
DS:ESI	==>	FSTR structure for current entry

|

	REGSAVE <ebx,ecx>	; Save registers

	mov	cl,DGROUP:[esi].F_SHFT ; Get shift amount
	mov	ebx,DGROUP:[esi].F_PVAL ; DS:EBX ==> value
	movzx	ebx,DGROUP:[ebx] ; EBX = value
	and	bx,DGROUP:[esi].F_MSK	; Isolate bits
	shr	ebx,cl  	; Shift to low-order

	call	T_TXT_SUB	; Use subroutine

	REGREST <ecx,ebx>	; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

T_TXT	endp			; End T_TXT procedure
	NPPROC  D_IC -- Display IC Text
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display IC text

On entry:

DS:ESI	==>	FSTR structure for current entry

|

	push	edx		; Save register

	lea	edx,TX_IC	; EDX ==> text pointers
	call	T_TXT		; Call common code

	pop	edx		; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

D_IC	endp			; End D_IC procedure
	NPPROC  D_RC -- Display RC Text
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display RC text

On entry:

DS:ESI	==>	FSTR structure for current entry

|

	push	edx		; Save register

	lea	edx,TX_RC	; EDX ==> text pointers
	call	T_TXT		; Call common code

	pop	edx		; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

D_RC	endp			; End D_RC procedure
	NPPROC  D_PC -- Display PC Text
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display PC text

On entry:

DS:ESI	==>	FSTR structure for current entry

|

	push	edx		; Save register

	lea	edx,TX_PC	; EDX ==> text pointers
	call	T_TXT		; Call common code

	pop	edx		; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

D_PC	endp			; End D_PC procedure
	NPPROC  D_TST -- Display TST Text
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display TST text

On entry:

DS:ESI	==>	FSTR structure for current entry

|

	REGSAVE <eax,ebx,edx>	; Save registers

	mov	ebx,DGROUP:[esi].F_PVAL ; DS:EBX ==> value
	mov	ax,DGROUP:[ebx] ; AX = value
	xor	ebx,ebx 	; Zero accumulator

	irp	XX,<C3,C0>

	shl	ebx,1		; Make room

	test	ax,mask $&XX	; Check for presence
	jz	short D_TST_&XX ; Not set

	or	ebx,1		; Set bit
D_TST_&XX:
	endm			; IRP

	lea	edx,TX_TST	; EDX ==> text pointers
	call	T_TXT_SUB	; Call common code

	REGREST <edx,ebx,eax>	; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

D_TST	endp			; End D_TST procedure
	NPPROC  D_REM -- Display REM Text
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display REM text

On entry:

DS:ESI	==>	FSTR structure for current entry

|

	REGSAVE <eax,ebx,edx>	; Save registers

	mov	ebx,DGROUP:[esi].F_PVAL ; DS:EBX ==> value
	mov	ax,DGROUP:[ebx] ; AX = value
	xor	ebx,ebx 	; Zero accumulator

	irp	XX,<C2,C0,C3,C1>

	shl	ebx,1		; Make room

	test	ax,mask $&XX	; Check for presence
	jz	short D_REM_&XX ; Not set

	or	ebx,1		; Set bit
D_REM_&XX:
	endm			; IRP

	lea	edx,TX_REM	; EDX ==> text pointers
	call	T_TXT_SUB	; Call common code

	REGREST <edx,ebx,eax>	; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

D_REM	endp			; End D_REM procedure
	NPPROC  D_TAG -- Display TAG Text
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display tag text

On entry:

DS:ESI	==>	FSTR structure for current entry

|

	push	edx		; Save register

	lea	edx,TX_TAG	; EDX ==> text pointers
	call	T_TXT		; Call common code

	pop	edx		; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

D_TAG	endp			; End D_TAG procedure
	NPPROC  D_DEC -- Instruction Decode
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display instruction decode

On entry:

DS:ESI	==>	FSTR structure for current entry

|

	REGSAVE <ecx,esi,edi,fs> ; Save registers

	push	ds		; Get our data selector
	pop	fs		; Address it
	assume  fs:DGROUP	; Tell the assembler about it

	lea	edi,INSTROUT	; ES:EDI ==> output line
	call	CLEAR_OUT	; Clear the output buffer

; FS:ESI   ==>	   instruction to disassemble
; ES:EDI   ==>	   output save area

	push	esi		; Save FSTR offset

	mov	ax,OCW2 	; Get opcodes
	xchg	al,ah		; Convert from display to Intel order
	mov	OCW3,ax 	; Save for disassembly
	lea	esi,OCW3	; FS:ESI ==> Secondary opcode word
	xor	cx,cx		; Assume USE16 disassembly
	call	INSTRDEC	; Disassemble the next instruction
				; returning FS:ESI ==> next instruction
				; ...	    ES:EDI ==> next output byte
	pop	esi		; Restore

	call	GET_SCR_OFF	; Get screen offset into ES:EDI

	lea	esi,INSTROUT	; DS:ESI ==> output save area
	add	esi,@OFFBYTE	; Skip over byte display area

; If the instruction begings with 'FN', omit the 'N'

	cmp	ds:[esi].ELO,'NF' ; Check for 'FN'
	jne	short @F	; Jump if not

	inc	esi		; Skip over the 'F'
	mov	ds:[esi].LO,'F' ; Store on top of the 'N'
@@:
	mov	ecx,S_DCLEN	; Get length of screen area
S32 rep movs	<es:[edi].LO,ds:[esi].LO> ; Copy to screen area

	mov	DISP_STATUS,1	; Mark as needing display

	REGREST <fs,edi,esi,ecx> ; Restore
	assume  fs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

D_DEC	endp			; End D_DEC procedure
	NPPROC  D_XAMSUB -- Display XAM Text Subroutine
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display XAM text subroutine

On entry:

ECX	=	0 if no related actions, non-zero otherwise
DS:EDX	==>	table entries of text
DS:ESI	==>	current item's structure

|

	REGSAVE <eax,ebx>	; Save registers

	mov	ebx,DGROUP:[esi].F_PVAL ; DS:EBX ==> value
	mov	ax,DGROUP:[ebx] ; AX = value
	xor	ebx,ebx 	; Zero accumulator

	irp	XX,<C3,C2,C1,C0>

	bt	ax,$&XX 	; Check the corresponding bit
	rcl	ebx,1		; Transfer bit to BX

	endm			; IRP

	jecxz	D_XAMSUB1	; No related actions

	pushad  		; Save all EGP registers

	call	D_XAMACT[ebx*(type D_XAMACT)] ; Call related action routine

	popad			; Restore all EGP registers

	jmp	short D_XAMSUB_EXIT ; Join common exit code

D_XAMSUB1:
	call	T_TXT_SUB	; Call common code
D_XAMSUB_EXIT:
	REGREST <ebx,eax>	; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

D_XAMSUB endp			; End D_XAMSUB procedure
	NPPROC  D_XAM -- Display XAM Text
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display XAM text

On entry:

DS:ESI	==>	FSTR structure for current entry

|

	REGSAVE <ecx,edx>	; Save registers

	lea	edx,TX_XAM	; EDX ==> text pointers
	xor	ecx,ecx 	; No related action table
	call	D_XAMSUB	; Let subroutine handle

	REGREST <edx,ecx>	; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

D_XAM	endp			; End D_XAM procedure
	NPPROC  D_NUMSUB -- Subroutine To D_NUM
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate the class of the stack element from STA_WD

On entry:

ECX	=	0 if no related actions, non-zero otherwise
DS:ESI	==>	FSTR structure for current entry

|

	REGSAVE <ebx,edx>	; Save registers

	lea	ebx,ENV.STA_WD  ; Get address of status word

	xchg	ebx,DGROUP:[esi].F_PVAL ; Swap with pointer to stack element
	lea	edx,TX_XAM2	; EDX ==> text pointers
	call	D_XAMSUB	; Let subroutine handle
	xchg	ebx,DGROUP:[esi].F_PVAL ; Restore

	REGREST <edx,ebx>	; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

D_NUMSUB endp			; End D_NUMSUB procedure
	NPPROC  D_NUM -- Binary to Decimal Conversion
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Binary to decimal conversion

On entry:

DS:ESI	==>	FSTR structure for current entry

|

	REGSAVE <eax,ebx,ecx,edx,edi> ; Save registers

; First, set the appropriate tag bits

	mov	dx,DGROUP:[esi].F_MSK ; Get mask
	mov	ax,TGW2 	; Get current tag word
	and	ax,dx		; Isolate bits

	mov	ebx,DGROUP:[esi].F_PVAL ; EBX ==> stack element
	fld	tbyte ptr DGROUP:[ebx] ; Get the value
	fxam			; Set examine bits
	fwait			; Wait for the NDP to become quiescent
if @WordSize eq 2
	db	66h		; Use 32-bit format *FIXME*
endif				; IF @WordSize EQ 2
	fnstenv ENV		; Save the environment
	fstp	st(0)		; Pop off result

	cmp	ax,dx		; Check for empty = 11b
	je	short D_NUM_MT  ; It's empty

; The stack element is non-empty -- get correct bits from TAG_WD
; Note that the TOP element may be different between ENV and STATE

	mov	cx,ENV.STA_WD	; Get status word
	and	cx,mask $TOP	; Isolate the top stack index
	shr	cx,$TOP 	; Shift to low-order
	shl	cx,1		; Convert from 2-bits to bits

	mov	ax,ENV.TAG_WD	; Get tag word
	shr	ax,cl		; Shift to low-order
	and	ax,11b  	; Isolate tag bits

	mov	cl,DGROUP:[esi].F_SHFT ; Get shift amount
	shl	ax,cl		; Shift into position
	not	dx		; Prepare to zero bits

	and	TGW2,dx 	; Zero 'em
	or	TGW2,ax 	; Set new bits
D_NUM_MT:

; Handle indefinites separately

	push	esi		; Save for a moment
	mov	esi,ebx 	; DS:ESI ==> stack element
	lea	edi,FINDEF	; ES:EDI ==> the indefinite
	mov	ecx,10/2	; # words in DT value
   repe cmps	ds:[esi].ELO,es:[edi].ELO
	pop	esi
	jne	short D_NUM_PNAN ; Must be definite, check for NaNs

	lea	eax,TXT_XAMINDEF
	xchg	eax,TX_XAM2_INDEF
	xor	ecx,ecx 	; No related action table
	call	D_NUMSUB	; Let subroutine handle it
	xchg	eax,TX_XAM2_INDEF

	jmp	D_NUM_EXIT	; Join common exit code

D_NUM_PNAN:

; Handle NaNs separately as quiet or signalling

	mov	ax,DGROUP:[ebx].FP_EXP ; Get exponent and sign
	and	ax,not @BIT15	; Clear the sign bit

	cmp	ax,7FFFh	; Check for maximum exponent
	jne	short D_NUM_PZERO ; Must be a number, check for pseudo-zeros

	test	DGROUP:[ebx].FP_MAN7,@BIT6 ; Check for quiet vs. signalling NaN
	jnz	short D_NUM_PZERO ; Jump if it's quiet, check for pseudo-zeros

	lea	eax,TXT_XAMPSNAN
	xchg	eax,TX_XAM2_PSNAN
	lea	edx,TXT_XAMNSNAN
	xchg	edx,TX_XAM2_NSNAN
	xor	ecx,ecx 	; No related action table
	call	D_NUMSUB	; Let subroutine handle it
	xchg	edx,TX_XAM2_NSNAN
	xchg	eax,TX_XAM2_PSNAN

	jmp	short D_NUM_EXIT ; Join common exit code

D_NUM_PZERO:

; Handle pseudo-zeros separately

	push	esi		; Save for a moment
	mov	esi,ebx 	; DS:ESI ==> stack element
	lea	edi,FPZERO	; ES:EDI ==> a pseudo-zero
	mov	ecx,8/2 	; # words in DT value
   repe cmps	ds:[esi].ELO,es:[edi].ELO
	pop	esi
	jne	short D_NUM_VAL ; Not a pseudo-zero

	mov	ax,DGROUP:[ebx].FP_EXP ; Get exponent & sign
	and	ax,not 8000h	; Isolate exponent bits

	cmp	ax,0		; Check exponent for denormals
	je	short D_NUM_VAL ; It's zero, can't be a pseudo-zero

	cmp	ax,07FFFh	; Check exponent for specials
	je	short D_NUM_VAL ; It's all ones, can't be a pseudo-zero

	lea	eax,TXT_XAMPZERO ; Get positive pseudo-zero text
	xchg	eax,TX_XAM2_PZERO ; Swap 'em
	lea	edx,TXT_XAMNZERO ; Get negative pseudo-zero text
	xchg	edx,TX_XAM2_NZERO ; Swap 'em
	xor	ecx,ecx 	; No related action table
	call	D_NUMSUB	; Let subroutine handle it
	xchg	edx,TX_XAM2_NZERO ; Restore
	xchg	eax,TX_XAM2_PZERO

	jmp	short D_NUM_EXIT ; Join common exit code

D_NUM_VAL:

; Format and display the number

	fld	tbyte ptr DGROUP:[ebx] ; Get the value
	mov	ecx,1		; Use related actions
	call	D_NUMSUB	; Let subroutine handle it
D_NUM_EXIT:
	REGREST <edi,edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

D_NUM	endp			; End D_NUM procedure
	NPPROC  TXTDISP -- Text Display Actions
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Text display actions

|

XAMACT0001:			; +NaN
XAMACT0011:			; -NaN
XAMACT0101:			; +Infinity
XAMACT0111:			; -Infinity
XAMACT1000:			; +Zero
XAMACT1001:			;  Empty
XAMACT1010:			; -Zero
XAMACT1011:			;  Empty
XAMACT1101:			;  Empty
XAMACT1111:			;  Empty
	fstp	st(0)		; Pop off value

	call	T_TXT_SUB	; Call common code

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TXTDISP endp			; End TXTDISP procedure
	NPPROC  BIN2DEC -- Binary to Decimal Conversion
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Binary to decimal conversion

On entry:

DS:ESI	==>	FSTR structure for current entry

On exit:

All GP registers may be destroyed.

|
XAMACT1100:			; +Denormal
	mov	MSIGN,'+'       ; Mark as positive

	jmp	short @F	; Join common code

XAMACT1110:			; -Denormal
	mov	MSIGN,'-'       ; Mark as negative
@@:
	mov	NTYPE,'D'       ; Mark as denormal

	fabs			; ST0=N
	fld1			; ST0=1 	ST1=N
	fxch			; ST0=N 	ST0=1
	fprem			; ST0=1|N	ST1=1
	fxtract 		; ST0=log2(1|N) ST1=Fraction	ST2=1
	fxam			; Examine it

	fstsw	ax		; Get status word
	fxch			; ST0=Fraction	ST1=log2(1|N)	ST2=1
	fxch	st(2)		; ST0=1 	ST1=log2(1|N)	ST2=Fraction

; Check for ...

	test	ax,(mask $C3) or (mask $C2) ; 4400h
	jz	short NORMALIZE_FRACTION

	fstp	st(0)		; Remove 1.0 from stack

	jmp	short NORMAL_VALUE ; Join common code

XAMACT0000:			; +Unnormal
	mov	MSIGN,'+'       ; Mark as positive

	jmp	short @F	; Join common code

XAMACT0010:			; -Unnormal
	mov	MSIGN,'-'       ; Mark as negative
@@:
	mov	NTYPE,'U'       ; Mark as unnormal

	fabs			; ST0=N
	fld1			; ST0=1 	ST1=N
NORMALIZE_FRACTION:
	fadd	st(1),st	; ST0=1 	ST1=N+1
	fsubp	st(1),st	; ST0=N
	fxtract 		; ST0=mantissa	ST1=exponent
	fxch			; ST0=exponent	ST1=mantissa
	fist	DENORM_CNT	; Save for later use
	faddp	st(2),st

	neg	DENORM_CNT
	jnz	short NORMAL_VALUE

;;;;;;; fxch
;;;;;;; fistp	DENORM_CNT


	jmp	short NORMAL_VALUE ; Join common code

XAMACT0100:			; +Normal
	mov	MSIGN,'+'       ; Mark as positive

	jmp	short @F	; Join common code

XAMACT0110:			; -Normal
	mov	MSIGN,'-'       ; Mark as negative
@@:
	mov	NTYPE,' '       ; Mark as normal

	fabs			; ST0=N

; Split apart the exponent and mantissa

	fxtract 		; ST0=M=MANTISSA	ST1=EXP2
NORMAL_VALUE:
	fstp	MANTISSA	; ST0=exponent
	fist	EXP2		; Save for later use

; Calculate and store the decimal exponent

	fldlg2  		; ST0=log10(2)		ST1=EXP2
	fmulp	st(1),st	; ST0=EXP2*log10(2)
	fistp	EXP10		; ST0=empty
	fwait			; Wait for EXP10 to be valid

; Get appropriate power of ten for scaling into range 10**17 <= X < 10**18

	mov	ax,17		; Get # digits to format
	sub	ax,EXP10	; Subtract for power of ten
	call	GET_POWER10	; ST0=2**(X-I)		ST1=I
				; where X = AX * log2(10)
				;	I = floor(X)
	fld	MANTISSA	; ST0=M 		ST1=2**(X-I)	ST2=I
	fmulp	st(1),st	; ST0=M*2**(X-I)	ST1=I
	fild	EXP2		; ST0=EXP2		ST1=M*2**(X-I)	ST2=I
	faddp	st(2),st	; ST0=M*2**(X-I)	ST1=EXP2+I
	fscale  		; ST0=M*2**(X+EXP2)	ST1=EXP2+I
	fstp	st(1)		; ST0=M*2**(X+EXP2)

	frndint 		; Round to integer

; Ensure power is representable in BCD format

	fcom	TEN18		; Check against 1E18
	fstsw	ax		; Copy status word
	sahf			; Copy to flags
	jc	short FMTBCD1	; Jump if smaller

	fidiv	CON10.ELO	; Scale down by 10
	inc	EXP10		; Account for it

	jmp	short FMTBCD2	; Join common code

FMTBCD1:
	fcom	TEN17		; Check against 1E17
	fstsw	ax		; Copy status word
	sahf			; Copy to flags
	jnc	short FMTBCD2	; Jump if not smaller

	fimul	CON10.ELO	; Scale up by 10
	dec	EXP10		; Account for it
FMTBCD2:
	frndint 		; Round to integer
	fbstp	BCD		; Save in BCD format
	fwait			; Wait for result to be stored

	call	GET_SCR_OFF	; Get screen offset into ES:EDI
	call	FMTSUB  	; Format and display the number

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2DEC endp			; End BIN2DEC procedure
	NPPROC  GET_POWER10 -- Get Power of Ten
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get power of ten

On entry:

AX	=	exponent to use on 10

On exit:

ST(0)	=	2**(X-I)
ST(1)	=	I
where
X	=	AX * log2(10)
I	=	floor(X)

|

	REGSAVE <eax>		; Save register

	fldl2t  		; ST(0)=log2(10)
	push	ax		; Put exponent onto stack for FIMUL and FSTCW
	fimul	[esp].ELO	; ST(0)=X=Exp*log2(10)

; Set rounding to negative infinity

	fstcw	[esp].ELO	; Save current control word there
	mov	ax,[esp].ELO	; Copy to set rounding to -inf (no wait needed)
	and	ax,not (mask $@RC) ; Clear rounding control bits
	or	ax,01b shl $@RC ; Set rounding control to 01b (-inf)
	push	ax		; Save control word onto stack
	fldcw	[esp].ELO	; FLDCW  AX
	pop	ax		; Remove from stack

	fld1			; ST(0)=1	ST(1)=X
	fchs			; ST(0)=-1	ST(1)=X
	fld	st(1)		; ST(0)=X	ST(1)=-1	ST(2)=X

; Form floor of X where -Inf < I <= X

	frndint 		; ST(0)=I=floor(X) ST(1)=-1	ST(2)=X
	fldcw	[esp].ELO	; Restore original control word
	pop	ax		; Remove from stack
	fxch	st(2)		; ST(0)=X	ST(1)=-1	ST(2)=I

; Form fraction F=X-I where 0 <= X-I < 1

	fsub	st,st(2)	; ST(0)=F	ST(1)=-1	ST(2)=I

; Form scale with -1 (divide by 2)

	fscale  		; ST(0)=     F/2     ST(1)=-1	ST(2)=I
	f2xm1			; ST(0)= 2**(F/2)-1  ST(1)=-1	ST(2)=I
	fsubrp  st(1),st	; ST(0)=-2**(F/2)    ST(1)=I
	fmul	st,st(0)	; ST(0)= 2**F	     ST(1)=I

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_POWER10 endp		; End GET_POWER10 procedure
	NPPROC  FMTSUB -- Format Subroutine to FMTBCD
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display a number in BCD format.

On entry:

BCD	=	integer number to format and display
		 already scaled
ES:EDI	==>	output save area

|

	pushad  		; Save all EGP registers

	push	edi		; Save offset

	lea	esi,BCD 	; DS:ESI ==> number in BCD format
	lea	edi,MDIGITS[(size MDIGITS)-1] ; ES:EDI ==> low-order digit
	lea	ebx,HEXTABLE	; DS:EBX ==> binary to ASCII hex translate table
	mov	ecx,(size MDIGITS)/2 ; # bytes in 18 BCD digits
FMTBCD_NEXT:
	call	FMTDIG  	; Format the next two digits

	loop	FMTBCD_NEXT	; Jump if more digits to display

	pushfd  		; Save flags
	std			; Store backwards

	mov	al,'.'          ; Get decimal point
	xchg	al,es:[edi+1]	; Swap with units digit
S32	stos	MDEC[edi]	; Store in output save area

	popfd			; Restore DF

; Format the decimal exponent

	lea	edi,ESIGN	; ES:EDI ==> save area
	mov	al,'+'          ; Assume positive

	test	EXP10,@BIT7	; Test high-order bit
	jz	short @F	; Jump if non-negative

	mov	al,'-'          ; Mark as negative
	neg	EXP10		; Negate the exponent as well
@@:
S32	stos	ESIGN[edi]	; Store in output save area

	movzx	eax,EXP10	; Get power of ten
	push	@DEC_LEFT	; Mark as left-justified
	call	DD2DEC  	; Convert EAX to decimal at ES:EDI

; Blank the trailing digits

	lea	ecx,EDIGITZ	; Get offset of end of digits
	sub	ecx,edi 	; Less current offset
	mov	al,' '          ; Fill with this
    rep stos	es:[edi].LO	; Blank the digits

	pop	edi		; Restore offset

	lea	esi,ASCII	; DS:ESI ==> formatted number
	mov	ecx,ASCIIZ-ASCII ; Get # bytes in formatted #
S32 rep movs	<es:[edi].LO,ds:[esi].LO> ; Copy to screen area

	popad			; Restore all EGP registers

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMTSUB	endp			; End FMTSUB procedure
	NPPROC  FMTDIG -- Format Two BCD Digits
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format a pair of BCD digits

On entry:

DS:ESI	==>	next two BCD digits
DS:EBX	==>	ASCII translate table
ES:EDI	==>	output save area

On exit:

DS:ESI	==>	(incremented)
ES:EDI	==>	(decremented)

|

	REGSAVE <eax>		; Save register

	lods	ds:[esi].LO	; Get next two digits
	xor	ah,ah		; Zero high-order word for shift
	shl	ax,4		; Shift out high-order digit
	shr	al,4		; Shift low-order digit back

	pushfd  		; Save flags
	std			; Store backwards

	xlat	HEXTABLE[ebx]	; Translate the digit
S32	stos	es:[edi].LO	; Store in output save area

	mov	al,ah		; Copy next digit
	xlat	HEXTABLE[ebx]	; Translate the digit
S32	stos	es:[edi].LO	; Store in output save area

	popfd			; Restore DF

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMTDIG	endp			; End FMTDIG procedure

PROG	ends			; End PROG segment

	MEND			; End P87_DISP module
