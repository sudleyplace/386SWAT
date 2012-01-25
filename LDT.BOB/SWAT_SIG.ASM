;' $Header:   P:/PVCS/386SWAT/SWAT_SIG.ASV   1.9   10 Jul 1997 14:47:48   BOB  $
	title	SWAT_SIG -- 386SWAT SIGINT Command Functions
	page	58,122
	name	SWAT_SIG

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-1999 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, March, 1993.

Modifications by:  None.

|
.386
.xlist
	include MASM.INC
	include PTR.INC
	include 386.INC
	include OPCODES.INC
	include CPUFLAGS.INC
	include INTVEC.INC
	include ALLMEM.INC
	include DOSCALL.INC

	include SWAT_CMD.INC
	include SWAT_COM.INC
	include SWAT_DRV.INC
	include SWAT_SEG.INC
.list

DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	LC3_FLAG:dword
	include SWAT_LC3.INC

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	CUR_INSTR:dword

	extrn	STACK_eSP:dword

	extrn	MSGOFF:dword
	extrn	SYNTERR:byte
	extrn	OVFERR:byte
	extrn	ROMERR:byte
	extrn	SELERR:byte
	extrn	SIGERR:byte

	extrn	DSP_STATE:byte
	extrn	DSP_STAT2:byte

	extrn	SAVE_DR6:dword

	public	LaSIGINT_BP,LaSIGINT_OLD,SIGINT_OLD
	public	SIGINT_SEL,SIGINT_OFF,SIGINT_FLAG
LaSIGINT_BP dd	?		; Linear address of SIGINT breakpoint
LaSIGINT_OLD dd ?		; Linear address of old SIGINT value
SIGINT_OLD dw	?		; Old SIGINT value to be restored
SIGINT_SEL dw	?		; Segment/selector
SIGINT_OFF dd	?		; Offset
SIGINT_FLAG dw	?		; Flags for SIGINT

	public	SIGINT21
SIGINT21 db	'21',0          ; Command line for SIGINT in EXIT

DATA	ends		        ; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP,ds:PGROUP

	extrn	IZITEOL:near
	extrn	PARSE_LVAL:near
	extrn	GETPMI:near
	extrn	SET_CURINSTR:near
	extrn	CMD_WHITE:near

	NPPROC	CMD_SIGINT -- Signal Interrupt Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Signal interrupt command

SIGINT lval

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax,ebx,ecx,edx,esi> ; Save registers

	call	IZITEOL 	; Izit end-of-the-line?
	je	near ptr CMD_SIGINT_SYNTERR ; Yes, so that's an error

	call	PARSE_LVAL	; Parse DS:ESI for lefthand value
	jc	near ptr CMD_SIGINT_ERR ; Jump if error
				; EAX = value
	cmp	eax,0FFh	; Check against maximum INT #
	ja	near ptr CMD_SIGINT_OVFERR ; Jump if it's too big

; Ensure nothing more on the line

	call	IZITEOL 	; Izit end-of-the-line?
	jne	near ptr CMD_SIGINT_SYNTERR ; No, so that's an error

; If this is device SWAT, we must fix up the RM stack ourselves
; and restart at the INT xx location.
; We also need to take this path if we're signalling INT 01h/03h
; as we're the holder of those interrupts.  This SIGINT is necessary
; to debug programs which hook the RM INT 01h/03h vectors themselves
; in order to fool a RM debugger.  Little do they know...
; Moreover, if it's INT 01h via a single-step we're signalling, ensure
; TF is set in the return flags.

	mov	ebx,mask $TF	; Get TF in case it's INT 01h single-step

	test	SAVE_DR6,mask $BS ; Did we enter here from a single-step?
	jnz	short @F	; Jump if so

	xor	ebx,ebx 	; It's not INT 01h single-step
@@:
	cmp	eax,01h 	; Izit INT 01h?
	je	short @F	; Jump if so

	xor	ebx,ebx 	; It's not INT 01h single-step

	cmp	eax,03h 	; Izit INT 03h?
	je	short @F	; Jump if so

	test	[ebp].FORW_EFL,mask $R2 ; Izit from RM?
	jz	short CMD_SIGINT_LOD ; Jump if not
@@:
	mov	esi,STACK_eSP	; Get linear address of the caller's stack
	sub	esi,size IRET_STR ; Make room for IRET frame
	mov	STACK_eSP,esi	; Save for later use

	sub	[ebp].FORW_ESP,size IRET_STR ; Make room for IRET frame

	assume	gs:INTVEC	; Address the RM IDT (not the redirected IDT)
	mov	eax,INT00_VEC[eax*(type INT00_VEC)] ; Get the INT's Seg:Off
	assume	gs:AGROUP	; Restore the truth

	xchg	ax,[ebp].FORW_EIP.ELO ; Swap with current IP
	mov	AGROUP:[esi].IRET_IP,ax ; Save on the stack

	shr	eax,16		; Shift down the high-order word (segment)
	mov	[ebp-@BPBACK].BACK_CS.DTR_LIM,ax ; Save for later use
	shl	eax,4-0 	; Convert from paras to bytes
	mov	[ebp-@BPBACK].BACK_CS.DTR_BASE,eax ; Save for later use
	shr	eax,4-0 	; Convert from bytes to paras
	xchg	ax,[ebp].FORW_CS ; Swap with current CS
	mov	AGROUP:[esi].IRET_CS,ax ; Save on the stack

	mov	ax,[ebp].FORW_EFL.ELO ; Get the current flags
	and	ax,not ((mask $IF) or (mask $TF)) ; IF=TF=0
	xchg	ax,[ebp].FORW_EFL.ELO ; Swap with current FL
	and	ax,not (mask $TF) ; TF=0 in case we ESC on exit
	or	eax,ebx 	; Include TF if it's INT 01h we're signalling
	mov	AGROUP:[esi].IRET_FL,ax ; Save on the stack

	call	SET_CURINSTR	; Set current instruction disassembly values

; If the current screen shows instruction disassembly,
; redisplay the disassembly screen.

	cmp	DSP_STATE,@DSP_IREGS ; Izit instruction state?
	je	short @F	; Jump if so

	cmp	DSP_STAT2,@DSP_IREGS ; Izit secondary ... ?
	jne	short CMD_SIGINT_CLC ; Jump if not
@@:
	or	LCL_FLAG,@LCL_REDI ; Mark as forced re-display of screen

	jmp	short CMD_SIGINT_CLC ; Join common exit code

CMD_SIGINT_LOD:

; Patch the current CS:eIP with an INT instruction

	cmp	[ebp].FORW_EIP,2 ; Izit too small?
	jb	short CMD_SIGINT_SIGERR ; Jump if so

	sub	[ebp].FORW_EIP,2 ; Back off for INT xx instruction

	mov	esi,CUR_INSTR	; Get linear address of cur instr
	sub	esi,2		; Less size of INT xx instruction
	mov	CUR_INSTR,esi	; Save for later use
	mov	LaSIGINT_OLD,esi ; Save for later use

	mov	ah,@OPCOD_INT	; Get INT opcode (AL has the INT #)
	xchg	al,ah		; Swap to store order
	mov	SIGINT_OLD,ax	; Save to restore later
	xchg	ax,AGROUP:[esi] ; Swap with the existing bytes
	xchg	ax,SIGINT_OLD	; Swap with saved value

	cmp	ax,AGROUP:[esi] ; Did it stick?
	jne	short CMD_SIGINT_ROMERR ; Jump if not

; Get the .PMIxx address of the interrupt we're signalling
; and set a breakpoint there.

	mov	al,ah		; Copy INT #
	call	GETPMI		; Get PM interrupt address for INT AL
				; Return with BX = selector
				; ...	     EAX = offset
				; ...	     EDX = selector base
				; ...	      CX = flags
	test	cx,@ADDR_CODE	; Izit a code selector?
	jz	short CMD_SIGINT_SELERR ; Jump if not

	mov	SIGINT_FLAG,cx	; Save for later use
	mov	SIGINT_SEL,bx	; ...
	mov	SIGINT_OFF,eax	; ...

	add	eax,edx 	; Add to get linear address
	mov	LaSIGINT_BP,eax ; Save for later use

	or	LC3_FLAG,@LC3_SIGINT ; Mark as SIGINT in effect
CMD_SIGINT_CLC:
	clc			; Indicate all went well

	jmp	short CMD_SIGINT_EXIT ; Join common exit code

CMD_SIGINT_SIGERR:
	mov	MSGOFF,offset DGROUP:SIGERR ; Save offset of error message

	jmp	short CMD_SIGINT_ERR ; Join common error code

CMD_SIGINT_SELERR:
	mov	MSGOFF,offset DGROUP:SELERR ; Save offset of error message

	jmp	short CMD_SIGINT_ERR ; Join common error code

CMD_SIGINT_ROMERR:
	mov	MSGOFF,offset DGROUP:ROMERR ; Save offset of error message

	jmp	short CMD_SIGINT_ERR ; Join common error code

CMD_SIGINT_OVFERR:
	mov	MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

	jmp	short CMD_SIGINT_ERR ; Join common error code

CMD_SIGINT_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
CMD_SIGINT_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_SIGINT_EXIT:
	REGREST <esi,edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_SIGINT endp 		; End CMD_SIGINT procedure
	NPPROC  CMD_EXIT -- Exit Command
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Exit command

Set AH to 4Ch
SIGINT 21
ESC

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax,esi>	; Save registers

; Ensure nothing more on the line

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	jne	short CMD_EXIT_SYNTERR ; No, so that's an error

	lea	esi,SIGINT21	; DS:ESI ==> '21' for SIGINT

	call	CMD_SIGINT	; Execute the command
	jc	short CMD_EXIT_EXIT ; Jump if something went wrong

	mov	[ebp].FORW_EAX.ELO.HI,@EXITRC ; Save function code

	or	LC2_FLAG,@LC2_ESC ; Treat as ESC

	clc			; Indicate all went well

	jmp	short CMD_EXIT_EXIT ; Join common exit code

CMD_EXIT_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

;;;;;;; jmp	short CMD_EXIT_ERR ; Join common error exit code

CMD_EXIT_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_EXIT_EXIT:
	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_EXIT endp			; End CMD_EXIT procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_SIG module
