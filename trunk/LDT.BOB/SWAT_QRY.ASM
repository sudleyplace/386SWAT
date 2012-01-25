;' $Header:   P:/PVCS/386SWAT/SWAT_GOT.ASV   1.2   10 Jul 1997 14:46:44   BOB  $
	title	SWAT_QRY -- 386SWAT Query Command Functions
	page	58,122
	name	SWAT_QRY

COMMENT|		Module Specifications

Copyright:  (C) Copyright 2002 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, June, 2002.

Modifications by:  None.

|
.386
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include OPCODES.INC
	include ALLMEM.INC

	include SWAT_CMD.INC
	include SWAT_COM.INC
	include SWAT_DBG.INC
	include SWAT_MOD.INC
	include SWAT_SEG.INC
	include SWAT_LOG.INC
.list

DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	extrn	CMD_LINE_TERM:byte

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	MSGOFF:dword
	extrn	SYNTERR:byte
	extrn	PTE_BITS:word,PTE_BITS_LEN:abs
	extrn	PDE_BITS:word,PDE_BITS_LEN:abs

	public	CR0_BITS
CR0_BITS dw	'GP'            ; 80000000:  Page Enable
	dw	'DC'            ; 40000000:  Cache Disable
	dw	'WN'            ; 20000000:  No Write Through
	dw	'??'            ; 10000000:  Reserved
	dw	'??'            ; 08000000:  ...
	dw	'??'            ; 04000000:  ...
	dw	'??'            ; 02000000:  ...
	dw	'??'            ; 01000000:  ...
	dw	'??'            ; 00800000:  ...
	dw	'??'            ; 00400000:  ...
	dw	'??'            ; 00200000:  ...
	dw	'??'            ; 00100000:  ...
	dw	'??'            ; 00080000:  ...
	dw	'MA'            ; 00040000:  Alignment Mask
	dw	'??'            ; 00020000:  Reserved
	dw	'PW'            ; 00010000:  Write Protect
	dw	'??'            ; 00008000:  Reserved
	dw	'??'            ; 00004000:  ...
	dw	'??'            ; 00002000:  ...
	dw	'??'            ; 00001000:  ...
	dw	'??'            ; 00000800:  ...
	dw	'??'            ; 00000400:  ...
	dw	'??'            ; 00000200:  ...
	dw	'??'            ; 00000100:  ...
	dw	'??'            ; 00000080:  ...
	dw	'??'            ; 00000040:  ...
	dw	'EN'            ; 00000020:  Numeric Error
	dw	'TE'            ; 00000010:  Extension Type
	dw	'ST'            ; 00000008:  Task Switched
	dw	'ME'            ; 00000004:  Emulation
	dw	'PM'            ; 00000002:  Monitor Coprocessor
	dw	'EP'            ; 00000001:  Protect Enable
CR0_BITS_LEN equ ($-CR0_BITS)/(type CR0_BITS) ; # entries

	public	CR3_BITS
CR3_BITS dw	'DC'            ; Cache-disable
	dw	'TW'            ; Write-through
	dw	'??'            ; Reserved
	dw	'??'            ; ...
	dw	'??'            ; ...
CR3_BITS_LEN equ ($-CR3_BITS)/(type CR3_BITS) ; # entries

	public	CR4_BITS
CR4_BITS dw	'XE'            ; OS Support for Unmasked SIMD FP Exceptions
	dw	'RS'            ; OS Support for FXSAVE/FRSTOR
	dw	'CP'            ; Performance-Monitoring Count Enable
	dw	'GP'            ; Page Global Enable
	dw	'CM'            ; Machine Check Enable
	dw	'AP'            ; Physical Address Extension
	dw	'SP'            ; Page Size Extensions
	dw	'ED'            ; Debug Extensions
	dw	'ST'            ; Time Stamp Disable
	dw	'VP'            ; PM Virtual Interrupts
	dw	'MV'            ; Virtual Mode Extensions
CR4_BITS_LEN equ ($-CR4_BITS)/(type CR4_BITS) ; # entries

	public	MSG_QCRn
MSG_QCRn db	' = '
MSG_QCRn1 db	(80-($-MSG_QCRn)) dup (' ')

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP

	extrn	CMD_WHITE:near
	extrn	PARSE_EXPR:near
	extrn	BIN2DWORD:near
	extrn	DispBits:near
	extrn	ENDOF_CMDLINE:near
	extrn	DISP_CMDLINE:near
	extrn	PURGE_KBUFF:near
	extrn	GETNDKEY:near

	NPPROC	QueryBits -- Query Bits
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Query bits

Note we can't use EBP because PARSE_EXPR
depends upon it pointing to FORW_STR.

On entry:

EBX	=	Table offset in DGROUP
EDX	=	Table length

|

	REGSAVE <eax,ecx,esi,edi> ; Save registers

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	short QueryBitsSyntErr ; Yes, treat as error

	call	PARSE_EXPR	; Parse DS:ESI for expression
	jc	short QueryBitsSyntErr ; Jump if error

; Ensure nothing more on the line

	push	eax		; Save for a moment

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	pop	eax		; Restore
	jne	near ptr QueryBitsSyntErr ; No, so that's an error

	lea	edi,MSG_QCRn1	; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	mov	es:[edi].LO,' ' ; Save separator
	inc	edi		; Skip over it

	push	eax		; Pass the value
	push	ebx		; ...	   table offset in DGROUP
	push	edx		; ...	   table length
	call	DispBits	; Dispay the page bits,
				; return with ES:EDI ==> next byte
	lea	esi,MSG_QCRn	; DS:ESI ==> message to display
	mov	ecx,edi 	; Copy address of next available byte
	sub	ecx,esi 	; ECX = # bytes in message

	call	ENDOF_CMDLINE	; Return with ES:EDI ==> end of the command line

	add	ecx,edi 	; Get end of line after copy
	lea	eax,CMD_LINE_TERM ; Use maximum

	cmp	ecx,eax 	; Izit too long?
	jbe	short @F	; Jump if not

	mov	ecx,eax 	; Use maximum
@@:
	sub	ecx,edi 	; Less end of the line
S32 rep movs	<MSG_QCRn[edi],MSG_QCRn[esi]> ; Copy to command line

	call	DISP_CMDLINE	; Display the command line
	call	PURGE_KBUFF	; First purge the keyboard buffer
	call	GETNDKEY	; Get non-destructive key

	clc			; Indicate all went well

	jmp	short QueryBitsExit ; Join common exit code


QueryBitsSyntErr:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

;;;;;;; jmp	short QueryBitsErr ; Join common error exit code


QueryBitsErr:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
QueryBitsExit:
	REGREST <edi,esi,ecx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

QueryBits endp			; End QueryBits procedure
	NPPROC	CMD_QCR0 -- QCR0 Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

QCR0 command

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <ebx,edx>	; Save registers

	lea	ebx,CR0_BITS	; Get the table offset in DGROUP
	mov	edx,CR0_BITS_LEN ; Get the table length
	call	QueryBits	; Call common routine

	REGREST <edx,ebx>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_QCR0 endp			; End CMD_QCR0 procedure
	NPPROC	CMD_QCR3 -- QCR3 Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

QCR3 command

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <ebx,edx>	; Save registers

	lea	ebx,CR3_BITS	; Get the table offset in DGROUP
	mov	edx,CR3_BITS_LEN ; Get the table length
	call	QueryBits	; Call common routine

	REGREST <edx,ebx>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_QCR3 endp			; End CMD_QCR3 procedure
	NPPROC	CMD_QCR4 -- QCR4 Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

QCR4 command

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <ebx,edx>	; Save registers

	lea	ebx,CR4_BITS	; Get the table offset in DGROUP
	mov	edx,CR4_BITS_LEN ; Get the table length
	call	QueryBits	; Call common routine

	REGREST <edx,ebx>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_QCR4 endp			; End CMD_QCR4 procedure
	NPPROC	CMD_QPTE -- QPTE Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

QPTE command

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <ebx,edx>	; Save registers

	lea	ebx,PTE_BITS	; Get the table offset in DGROUP
	mov	edx,PTE_BITS_LEN ; Get the table length
	call	QueryBits	; Call common routine

	REGREST <edx,ebx>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_QPTE endp			; End CMD_QPTE procedure
	NPPROC	CMD_QPDE -- QPDE Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

QPDE command

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <ebx,edx>	; Save registers

	lea	ebx,PDE_BITS	; Get the table offset in DGROUP
	mov	edx,PDE_BITS_LEN ; Get the table length
	call	QueryBits	; Call common routine

	REGREST <edx,ebx>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_QPDE endp			; End CMD_QPDE procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_QRY module
