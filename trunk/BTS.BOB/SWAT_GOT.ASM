;' $Header:   P:/PVCS/386SWAT/SWAT_GOT.ASV   1.2   10 Jul 1997 14:46:44   BOB  $
	title	SWAT_GOT -- 386SWAT Goto Command Functions
	page	58,122
	name	SWAT_GOT

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-1999 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

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

DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	LC4_FLAG:dword
	include SWAT_LC4.INC

	extrn	MSGOFF:dword
	extrn	SYNTERR:byte
	extrn	ROMERR:byte
	extrn	OVFERR:byte

	extrn	BREAKPT4:tbyte

	public	GOTMODE,GOTSEL,GOTOFF,GOTBASE,GOTMASK
GOTMODE dw	@MODE_VM	; Goto mode
GOTSEL	dw	0		; Goto selector/segment
GOTOFF	dd	?		; Goto offset
GOTBASE dd	?		; Goto base
GOTMASK dd	0000FFFFh	; Goto mask (32 or 16 bits)

	public	MONEXPR
MONEXPR db	80 dup (0)	; Monitor expression
	db	0

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume  cs:PGROUP

	extrn	CMD_WHITE:near
	extrn	PARSE_ADDR:near
	extrn	PARSE_EXPR:near

	extrn	LDISPMSG:near

	NPPROC  CMD_GOTO -- Goto Command
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Goto command

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax,ebx,ecx,edx> ; Save registers

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_GOTO_CLC ; Yes, treat as ESC

	call	PARSE_ADDR	; Parse DS:ESI for address
	jc	near ptr CMD_GOTO_ERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

; Ensure nothing more on the line

	push	eax		; Save for a moment

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	pop	eax		; Restore
	jne	near ptr CMD_GOTO_SYNTERR ; No, so that's an error

	mov	GOTOFF,eax	; Save for display purposes

	test	cx,@ADDR_SEP	; Separator specified?
	jnz	short CMD_GOTO_SEP ; Yes

; No separator specified -- use current mode and CS

	mov	bx,[ebp].FORW_CS ; Get caller's CS
	mov	edx,[ebp-@BPBACK].BACK_CS.DTR_BASE ; Get caller's base
	mov	cx,[ebp].FORW_EFL.EHI ; Get caller's flags

	test	cx,mask $VM	; Check mode
	mov	cx,@ADDR_PM	; Assume PM
	jz	short CMD_GOTO_SEP ; Join common code

	xor	cx,cx		; Mode is VM86
CMD_GOTO_SEP:
	mov	GOTSEL,bx	; Save for display purposes
	mov	GOTBASE,edx	; Save for later use

	and	GOTMODE,not @MODE_VM ; Mark as protected mode
	mov	GOTMASK,-1	; Use all 32 bits

	test	cx,@ADDR_PM	; Check mode
	jnz	short @F	; Jump if PM

	or	GOTMODE,@MODE_VM ; Mark as VM86 mode
	mov	GOTMASK,0000FFFFh ; Use low-order 16 bits
@@:
	mov	eax,GOTOFF	; Get specified offset

	cmp	eax,GOTMASK	; Ensure within mask limits
	ja	short CMD_GOTO_OVFERR ; Jump if not

; Mark the address with a breakpoint interrupt

	mov	edx,GOTBASE	; Get base address
	add	edx,eax 	; Plus offset to get linear address
	mov	al,@OPCOD_INT3  ; Breakpoint interrupt
	xchg	al,gs:[edx]	; Swap with the data

	cmp	gs:[edx].LO,@OPCOD_INT3 ; Did it take?
	jne	short CMD_GOTO_ROMERR ; Jump if not

	mov	BREAKPT4.BC_LIN,edx ; Save the offset
	mov	BREAKPT4.BC_VAL,al ; Save to restore the next time
	or	BREAKPT4.BC_FLAG,@ADDR_INUSE or @ADDR_ENA ; Mark as enabled and in use
CMD_GOTO_CLC:
	or	LC2_FLAG,@LC2_ESC ; Treat as ESC

	clc			; Indicate all went well

	jmp	short CMD_GOTO_EXIT ; Join common exit code

CMD_GOTO_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	jmp	short CMD_GOTO_ERR ; Join common error exit code

CMD_GOTO_ROMERR:
	mov	MSGOFF,offset DGROUP:ROMERR ; Save offset of error message

	jmp	short CMD_GOTO_ERR ; Join common error exit code

CMD_GOTO_OVFERR:
	mov	MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

;;;;;;; jmp	short CMD_GOTO_ERR ; Join common error exit code

CMD_GOTO_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_GOTO_EXIT:
	REGREST <edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_GOTO endp			; End CMD_GOTO procedure
	NPPROC  CMD_GOMONITOR -- Go w/monitor Command
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Go w/monitor command.  Effectively auto single-steps, evaluating specified
expression.

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax,ebx,ecx,edx,edi> ; Save registers

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_GOMON_CLC ; Yes, treat as ESC

	mov	edi,esi 	; Save for a moment

	call	PARSE_EXPR	; Parse DS:ESI for expression
	jc	short CMD_GOMON_SYNTERR ; Jump if error

; Ensure nothing more on the line

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	jne	short CMD_GOMON_SYNTERR ; No, so that's an error

	mov	cx,79		; Maximum command line length

	lea	esi,MONEXPR	; Where to save it
	xchg	esi,edi 	; DGROUP:ESI ==> start of args, DGROUP:EDI ==> MONEXPR

	cld			; String ops forwardly

@@:
	lods	DGROUP:[esi].LO ; Get a byte
	stos	MONEXPR[edi]	; Save it locally
	or	al,al		; Izit the end?
	loopnz  @B		; Keep going

	sub	al,al		; Make sure it's terminated
	stos	MONEXPR[edi]	; Write terminator

; FIXME Handle target address for breakpoint to turn off monitor mode
; Also take an optional count.

CMD_GOMON_CLC:
	LOGDISP 'Start mon'

	or	LC4_FLAG,@LC4_MONCMD ; Monitor command entered

	clc			; Indicate all went well

	jmp	short CMD_GOMON_EXIT ; Join common exit code

CMD_GOMON_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

;;;;;;;  jmp	 short CMD_GOMON_ERR ; Join common error exit code

CMD_GOMON_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_GOMON_EXIT:
	REGREST <edi,edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_GOMONITOR endp		; End CMD_GOMONITOR procedure
	NPPROC  IS_MONITOR -- Check for breakpoint condition
	assume  ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Evaluate monitor expression (set by gm command).  If TRUE, stop
tracing.

On entry:
AGROUP:EAX ==> Current instruction
SS:EBP ==> FORW_STR

On exit:
CF=1	 Keep tracing in monitor mode
CF=0	 Stop tracing and bring up SWAT

|

	REGSAVE <esi,edi,es>	; Save

	mov	ax,ds		; Get DGROUP address
	mov	es,ax		; Address it
	assume  es:DGROUP	; Tell the assembler

	cmp	MONEXPR[0],0	; Izit empty?
	je	short ISMON_EXIT ; Stop if so (CF=0)

	lea	esi,MONEXPR	; DGROUP:ESI ==> monitor expression
	call	PARSE_EXPR	; Return EAX with truth value

	cmc			; CF=0 if an error occurred in parsing
	jnc	short ISMON_EXIT ; Stop if monitor expression invalid

	cmp	eax,1		; CF=0 if we should stop

ISMON_EXIT:
	REGREST <es,edi,esi>	; Restore
	assume  es:nothing	; Tell the assembler

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IS_MONITOR endp 		; End IS_MONITOR procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_GOT module
