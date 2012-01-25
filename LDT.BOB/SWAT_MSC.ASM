;' $Header:   P:/PVCS/386SWAT/SWAT_MSC.ASV   1.14   29 Aug 1998 11:25:16   BOB  $
	title	SWAT_MSC -- 386SWAT Miscellaneous Routines
	page	58,122
	name	SWAT_MSC

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-99 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include BITFLAGS.INC
	include ALLMEM.INC

	include SWAT_FMT.INC
	include SWAT_COM.INC
	include SWAT_SEG.INC
.list

DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	extrn	COMMON:tbyte
	include SWAT_FIL.INC

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	CON10:dword

	public	@SWAT_MSC_DATA
@SWAT_MSC_DATA label byte	; Mark module start in .MAP file

	extrn	INSTROUT:byte
	extrn	INSTROUT_LEN:abs

	public	HEXTABLE
HEXTABLE db	'0123456789ABCDEF' ; Translate table

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP

	public	@SWAT_MSC_PROG
@SWAT_MSC_PROG: 		; Mark module start in .MAP file

	NPPROC	GETBASE -- Return Selector Base
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return the selector base.

On entry:

SS:EBP	==>	FORW_STR

On exit:

EAX	=	32-bit linear address of selector
CF	=	0 if all went OK
	=	1 if selector out of range

|

GETARWBASE_STR struc

GETARWBASE_GDTDTR df ?		; GDT limit and base
GETARWBASE_EBP	  dd ?		; Caller's EBP
		  dd ?		; Caller's EIP
GETARWBASE_SEL	  dw ?		; Selector to get base

GETARWBASE_STR ends

	push	ebp		; Prepare to address the stack
	sub	esp,size GETARWBASE_GDTDTR ; Make room for GDT limit and base
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ebx,ecx,ds>	; Save registers

	mov	ecx,1		; Mark as using global LDT
	call	GETARWBASE	; Call common routine
	assume	ds:AGROUP	; Tell the assembler about it
	jc	short @F	; Jump if something went wrong (note CF=1)

	mov	eax,AGROUP:[ebx].DESC_BASE2.EDD ; Get bytes 2-xx-3
	rol	eax,8		; Put byte 2 in AH and byte 3 in AL
	xchg	al,ah		; Swap to normal order
	shl	eax,16		; Shift to high-order word
	mov	ax,AGROUP:[ebx].DESC_BASE01 ; Get bytes 0-1

	clc			; Indicate all went well
@@:
	REGREST <ds,ecx,ebx>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	lea	esp,[esp+(size GETARWBASE_GDTDTR)] ; Strip from stack

	pop	ebp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETBASE endp			; End GETBASE procedure
	NPPROC	GETLIMIT -- Return Selector Limit
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return the selector limit.

On entry:

SS:EBP	==>	FORW_STR

On exit:

EAX	=	32-bit limit (length - 1)
CF	=	0 if all went OK
	=	1 if selector out of range

|

	push	ebp		; Prepare to address the stack
	sub	esp,size GETARWBASE_GDTDTR ; Make room for GDT limit and base
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ebx,ecx,ds>	; Save registers

	mov	ecx,1		; Mark as using global LDT
	call	GETARWBASE	; Call common routine
	assume	ds:AGROUP	; Tell the assembler about it
	jc	short GETLIMIT_EXIT ; Jump if something went wrong (note CF=1)

	mov	al,AGROUP:[ebx].DESC_SEGLM1 ; Get bits 16-19 and flags
	and	ax,mask $SEGLM1 ; Isolate bits 16-19, clear high-order byte
	shl	eax,16		; Shift to high-order word
	mov	ax,AGROUP:[ebx].DESC_SEGLM0 ; Get bits 0-15

	test	AGROUP:[ebx].DESC_SEGLM1,mask $DTE_G ; Izit page granular?
	jz	short @F	; Jump if not

	shl	eax,12-0	; Convert from 4KB to bytes
	or	eax,0FFFh	; Set the low-order bits
@@:
	clc			; Indicate all went well
GETLIMIT_EXIT:
	REGREST <ds,ecx,ebx>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	lea	esp,[esp+(size GETARWBASE_GDTDTR)] ; Strip from stack

	pop	ebp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETLIMIT endp			; End GETLIMIT procedure
	NPPROC	GETLBASE -- Return Local Selector Base
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return the local selector base.
If the selector is in the LDT, use our local LDT instead.

On entry:

SS:EBP	==>	FORW_STR

On exit:

EAX	=	32-bit linear address of selector
CF	=	0 if all went OK
	=	1 if selector out of range

|

	push	ebp		; Prepare to address the stack
	sub	esp,size GETARWBASE_GDTDTR ; Make room for GDT limit and base
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ebx,ecx,ds>	; Save registers

	xor	ecx,ecx 	; Mark as using local LDT
	call	GETARWBASE	; Call common routine
	assume	ds:AGROUP	; Tell the assembler about it
	jc	short @F	; Jump if something went wrong (note CF=1)

	mov	eax,AGROUP:[0].DESC_BASE2.EDD[ebx] ; Get bytes 2-xx-3
	rol	eax,8		; Put byte 2 in AH and byte 3 in AL
	xchg	al,ah		; Swap to normal order
	shl	eax,16		; Shift to high-order word
	mov	ax,AGROUP:[0].DESC_BASE01[ebx] ; Get bytes 0-1

	clc			; Indicate all went well
@@:
	REGREST <ds,ecx,ebx>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	lea	esp,[esp+(size GETARWBASE_GDTDTR)] ; Strip from stack

	pop	ebp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETLBASE endp			; End GETLBASE procedure
	NPPROC	GETCGSEL -- Get Call Gate Code Selector
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return the code selector from the call gate DTE
or the TSS selector from the task gate DTE.

On entry:

SS:EBP	==>	FORW_STR

On exit:

AX	=	code selector from call gate or
		 TSS selector from task gate
CF	=	0 if all went OK
	=	1 if call/task gate selector out of range

|

	push	ebp		; Prepare to address the stack
	sub	esp,size GETARWBASE_GDTDTR ; Make room for GDT limit and base
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ebx,ecx,ds>	; Save registers

	mov	ecx,1		; Mark as using global LDT
	call	GETARWBASE	; Call common routine
	assume	ds:AGROUP	; Tell the assembler about it
	jc	short @F	; Jump if something went wrong (note CF=1)

; The code selector in the call gate is actually in DESC_BASE01

	mov	ax,AGROUP:[ebx].DESC_BASE01 ; Get bytes 0-1
@@:
	REGREST <ds,ecx,ebx>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	lea	esp,[esp+(size GETARWBASE_GDTDTR)] ; Strip from stack

	pop	ebp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETCGSEL endp			; End GETCGSEL procedure
	NPPROC	GETCGOFF -- Get Call Gate Code Offset
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return the code offset from the call gate DTE.

On entry:

SS:EBP	==>	FORW_STR

On exit:

EAX	=	code offset from call gate
CF	=	0 if all went OK
	=	1 if call gate selector out of range

|

	push	ebp		; Prepare to address the stack
	sub	esp,size GETARWBASE_GDTDTR ; Make room for GDT limit and base
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ebx,ecx,ds>	; Save registers

	mov	ecx,1		; Mark as using global LDT
	call	GETARWBASE	; Call common routine
	assume	ds:AGROUP	; Tell the assembler about it
	jc	short @F	; Jump if something went wrong (note CF=1)

; The code offset in the call gate is actually in
; DESC_SEGLM0 ( 0-15),
; DESC_SEGLM1 (16-23),
; DESC_BASE3  (24-31)

	mov	ax,AGROUP:[ebx].DESC_SEGLM1.ELO ; Get bytes 2-3
	shl	eax,16		; Shift to high-order word
	mov	ax,AGROUP:[ebx].DESC_SEGLM0 ; Get bytes 0-1

	clc			; Indicate all went well
@@:
	REGREST <ds,ecx,ebx>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	lea	esp,[esp+(size GETARWBASE_GDTDTR)] ; Strip from stack

	pop	ebp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETCGOFF endp			; End GETCGOFF procedure
	NPPROC	GETARW -- Return Selector Access Rights Word
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return the selector's access rights word.

On entry:

SS:EBP	==>	FORW_STR

On exit:

AL	=	DTYP_REC record
AH	=	DLIM_REC record
CF	=	0 if all went OK
	=	1 if selector out of range

|

	push	ebp		; Prepare to address the stack
	sub	esp,size GETARWBASE_GDTDTR ; Make room for GDT limit and base
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ebx,ecx,ds>	; Save registers

	mov	ecx,1		; Mark as using global LDT
	call	GETARWBASE	; Call common routine
	assume	ds:AGROUP	; Tell the assembler about it
	jc	short @F	; Jump if something went wrong (note CF=1)

	mov	ax,AGROUP:[0].DESC_ACCESS.ELO[ebx] ; Get DTYP_REC and DLIM_REC
@@:
	REGREST <ds,ecx,ebx>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	lea	esp,[esp+(size GETARWBASE_GDTDTR)] ; Strip from stack

	pop	ebp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETARW	endp			; End GETARW procedure
	NPPROC	GETLARW -- Return Local Selector Access Rights Word
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return the local selector's access rights word.

On exit:

AL	=	DTYP_REC record
AH	=	DLIM_REC record
CF	=	0 if all went OK
	=	1 if selector out of range

|

	push	ebp		; Prepare to address the stack
	sub	esp,size GETARWBASE_GDTDTR ; Make room for GDT limit and base
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ebx,ecx,ds>	; Save registers

	xor	ecx,ecx 	; Mark as using local LDT
	call	GETARWBASE	; Call common routine
	assume	ds:AGROUP	; Tell the assembler about it
	jc	short @F	; Jump if something went wrong (note CF=1)

	mov	ax,AGROUP:[0].DESC_ACCESS.ELO[ebx] ; Get DTYP_REC and DLIM_REC
@@:
	REGREST <ds,ecx,ebx>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	lea	esp,[esp+(size GETARWBASE_GDTDTR)] ; Strip from stack

	pop	ebp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETLARW endp			; End GETLARW procedure
	NPPROC	GETARWBASE -- Common Routine to GETBASE, GETLBASE, and GETARW
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common routine to GETBASE, GETLBASE, and GETARW.

On entry:

SS:EBP	==>	GETARWBASE_STR
ECX	=	0 if using local LDT
	=	1 ...	    global ...

On exit:

CF	=	0 if successful
	=	1 if not
DS:EBX	==>	selector entry in GDT or LDT

|

	REGSAVE <eax,ebp>	; Save for a moment

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	mov	ds,COMMON.FILE_4GB ; Use all memory selector
	assume	ds:AGROUP	; Tell the assembler about it

	SGDTD	[ebp].GETARWBASE_GDTDTR ; Save on stack

	movzx	ebx,[ebp].GETARWBASE_SEL ; Copy selector to index register
	and	bx,not (mask $PL) ; Clear the Privilege Level bits
	jz	short GETARWBASE_ERR ; Jump if in error

	btr	bx,$TI		; Test and reset the Table Index bit
	jnc	short GETARWBASE_GDT ; Jump if it's in the GDT

	jecxz	GETARWBASE_LLDT ; Jump if using local LDT

	mov	ebp,[ebp].GETARWBASE_EBP ; Restore EBP for access to FORW_STR
	mov	bp,[ebp].FORW_LDT ; Get global LDT selector

	jmp	short GETARWBASE_LLDT1 ; Join common code


GETARWBASE_LLDT:
	sldt	bp		; Get local LDT selector
GETARWBASE_LLDT1:
	and	bp,bp		; Ensure valid
	jz	short GETARWBASE_ERR ; Jump if not

S16	lsl	<eax,ebp>	; Get LDT selector limit into EAX
	jmp	short $+2	; In case of bad selector

	cmp	ebx,eax 	; Ensure within limits
	ja	short GETARWBASE_ERR ; Jump if not

	push	bp		; Pass selector of LDT in the GDT
	call	GETBASE 	; Return with EAX = selector base
	jc	short GETARWBASE_ERR ; Jump if in error

	add	ebx,eax 	; Plus base address of LDT

	jmp	short GETARWBASE_GLDT_COM ; Join common code


; Ensure selector is within GDT limits

GETARWBASE_GDT:
	cmp	bx,[ebp].GETARWBASE_GDTDTR.DTR_LIM ; Check it
	ja	short GETARWBASE_ERR ; Jump if in error

	add	ebx,[ebp].GETARWBASE_GDTDTR.DTR_BASE ; Plus base address of GDT
GETARWBASE_GLDT_COM:
	bt	AGROUP:[ebx].DESC_ACCESS,$DT_P ; Izit present?
	cmc			; Complement so CF=0 ==> present
				;		CF=1 ==> not present
	jmp	short GETARWBASE_EXIT ; Join common exit code


GETARWBASE_ERR:
	stc			; Indicate something went wrong
GETARWBASE_EXIT:
	REGREST <ebp,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETARWBASE endp 		; End GETARWBASE procedure
	NPPROC	GETLADTE -- Return Linear Address of A DTE
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return the linear address of the DTE in the GDT/LDT.

On entry:

SS:EBP	==>	FORW_STR

On exit:

EAX	=	32-bit linear address of selector
CF	=	0 if all went OK
	=	1 if selector out of range

|

	push	ebp		; Prepare to address the stack
	sub	esp,size GETARWBASE_GDTDTR ; Make room for GDT limit and base
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ebx,ecx,ds>	; Save registers

	mov	ecx,1		; Mark as using global LDT
	call	GETARWBASE	; Call common routine
	assume	ds:AGROUP	; Tell the assembler about it
				; Return with CF significant
	mov	eax,ebx 	; Return address

	REGREST <ds,ecx,ebx>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	lea	esp,[esp+(size GETARWBASE_GDTDTR)] ; Strip from stack

	pop	ebp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETLADTE endp			; End GETLADTE procedure


BIN2DWORD_MAC macro PREF

	NPPROC	PREF&BIN2DWORD -- Convert Binary EAX to Hex at ES:EDI
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

ES:EDI	==>	place to put high-order digit of output

On exit:

ES:EDI	==>	(updated)

|

	rol	eax,16		; Swap order
	call	PREF&BIN2WORD	; Convert AX to hex at ES:EDI

	rol	eax,16		; Swap order
	call	PREF&BIN2WORD	; Convert AX to hex at ES:EDI

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&BIN2DWORD endp		; End PREF&BIN2DWORD procedure

	endm			; BIN2DWORD_MAC


BIN2WORD_MAC macro PREF

	NPPROC	PREF&BIN2WORD -- Convert Binary AX to Hex at ES:EDI
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

ES:EDI	==>	place to put high-order digit of output

On exit:

ES:EDI	==>	(updated)

|

	rol	ax,8		; Swap order
	call	PREF&BIN2BYTE	; Convert AL to hex at ES:EDI

	rol	ax,8		; Swap order
	call	PREF&BIN2BYTE	; Convert AL to hex at ES:EDI

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&BIN2WORD endp		; End PREF&BIN2WORD procedure

	endm			; BIN2WORD_MAC


BIN2BYTE_MAC macro PREF

	NPPROC	PREF&BIN2BYTE -- Convert Binary AL to Hex at ES:EDI
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

ES:EDI	==>	place to put high-order digit of output

On exit:

ES:EDI	==>	(updated)

|

	rol	al,4		; Swap order
	call	PREF&BIN2DIGIT	; Convert low-order digit in AL to hex at ES:EDI

	rol	al,4		; Swap order
	call	PREF&BIN2DIGIT	; Convert low-order digit in AL to hex at ES:EDI

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&BIN2BYTE endp		; End PREF&BIN2BYTE procedure

	endm			; BIN2BYTE_MAC


BIN2DIGIT_MAC macro PREF

	NPPROC	PREF&BIN2DIGIT -- Convert Low-order Binary Digit in AL to Hex at ES:EDI
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

ES:eDI	==>	place to put high-order digit of output

On exit:

ES:eDI	==>	(updated)

|

ifidni <PREF>,<U16_>
	REGSAVE <ax,bx,ds>	; Save registers

	mov	bx,seg DGROUP	; Get DGROUP data selector
	mov	ds,bx		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	lea	bx,PREF&HEXTABLE ; DS:BX ==> translate table
	and	al,@NIB0	; Isolate the digit
	xlat	PREF&HEXTABLE[bx] ; Translate the digit
S16	stos	es:[di].LO	; Save in output

	REGREST <ds,bx,ax>	; Restore
	assume	ds:nothing	; Tell the assembler about it
else
	REGSAVE <eax,ebx,ds>	; Save registers

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	lea	ebx,PREF&HEXTABLE ; DS:EBX ==> translate table
	and	al,@NIB0	; Isolate the digit
	xlat	PREF&HEXTABLE[ebx] ; Translate the digit
S32	stos	es:[edi].LO	; Save in output

	REGREST <ds,ebx,eax>	; Restore
	assume	ds:nothing	; Tell the assembler about it
endif				; IFIDNI <PREF>,<U16_>
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&BIN2DIGIT endp		; End PREF&BIN2DIGIT procedure

	endm			; BIN2DIGIT_MAC



DD2DEC_MAC macro L_PREF

ifidn <L_PREF>,<U16_>
L_DVEC	  equ	<dd>
L_DOFF	  equ	<dw>
L_DOFFSIZ equ	<2>
L_OVEC	  equ	<VOFF>
L_SVEC	  equ	<VSEG>
L_E	  equ	<>
else
L_DVEC	  equ	<df>
L_DOFF	  equ	<dd>
L_DOFFSIZ equ	<4>
L_OVEC	  equ	<FOFF>
L_SVEC	  equ	<FSEL>
L_E	  equ	<e>
endif
	LDD2DEC_MAC L_PREF,L_DVEC,L_DOFF,L_DOFFSIZ,L_OVEC,L_SVEC,L_E

	endm			; DD2DEC_MAC


LDD2DEC_MAC macro PREF,DVEC,DOFF,DOFFSIZ,OVEC,SVEC,E

	NPPROC	PREF&DD2DEC -- Convert EAX To Decimal At ES:eDI
ifidn <PREF>,<U16_>
	assume	ds:NGROUP,es:NGROUP,fs:nothing,gs:nothing,ss:nothing
else
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
endif
COMMENT|

Convert EAX to decimal at ES:eDI.

On entry:

EAX	=	# to convert
ES:eDI	==>	save area

On exit:

ES:eDI	==>	(incremented)

|

PREF&LDD2DEC_STR struc

% PREF&LDD2DEC_FVEC DVEC ?	; Address of caller's buffer
PREF&LDD2DEC_BUF db  14 dup (?)      ; Local buffer big enough to handle
				; 4G with commas (4,xxx,xxx,xxx),0

PREF&LDD2DEC_STR ends


PREF&DD2DEC_STR struc

PREF&DD2DEC_LCL db (type PREF&LDD2DEC_STR) dup (?) ; LDD2DEC_STR
%	DOFF	?		; Caller's eBP
%	DOFF	?		;	   eIP
% PREF&DD2DEC_FLG DOFF ?	; Flags

PREF&DD2DEC_STR ends

@&PREF&LDD2DEC_SIZE equ size PREF&LDD2DEC_STR ; Size of local stack in bytes

%	push	&E&&bp		; Prepare to address the stack
%	sub	&E&&sp,@&PREF&LDD2DEC_SIZE ; Make room on stack
%	mov	&E&&BP,&E&&SP	; Hello, Mr. Stack

	pushf			; Save flags

%	REGSAVE <eax,ebx,ecx,edx,&E&&si,es> ; Save registers

%	test	[&E&&bp].&PREF&DD2DEC_FLG,@DEC_LEFT ; Izit left-justified?
	jz	short @F	; Not this time

%	mov	[&E&&bp].&PREF&DD2DEC_LCL.&PREF&LDD2DEC_FVEC.&OVEC,&E&&di ; Save address of caller's buffer
%	mov	[&E&&bp].&PREF&DD2DEC_LCL.&PREF&LDD2DEC_FVEC.&SVEC,es

	push	ss		; Setup ES for string operations
	pop	es		; ...
	assume	es:nothing	; Tell the assembler about it

%	lea	&E&&di,[&E&&bp].&PREF&DD2DEC_LCL.&PREF&LDD2DEC_BUF[(size PREF&LDD2DEC_BUF)-1] ; ES:eDI ==> buffer end
@@:
	xor	ecx,ecx 	; Initialize byte count
	xor	edx,edx 	; Zero high-order dword
	std			; String ops backwards
PREF&DD2DEC_COMMA:
	xor	ebx,ebx 	; Initialize comma count
PREF&DD2DEC_NEXT:
	div	PREF&CON10	; Split off another decimal digit
				; EAX = quotient
				; EDX = remainder
	xchg	eax,edx 	; Swap to display AL
	add	al,'0'          ; Convert to decimal ASCII
%	stos	es:[&E&&di].LO	; Save in buffer
	inc	ecx		; Account for it
	mov	eax,edx 	; Copy to dividend register
	xor	edx,edx 	; Zero for next time

	and	eax,eax 	; Check the remainder
	jz	short PREF&DD2DEC_END ; Jump if that's all

%	test	[&E&&bp].&PREF&DD2DEC_FLG,@DEC_COMMA ; Comma insertion requested?
	jz	short PREF&DD2DEC_NEXT ; Not this time

	inc	ebx		; Account for it

	cmp	ebx,3		; Izit time to comma-insert?
	jne	short PREF&DD2DEC_NEXT ; Not as yet

	push	eax		; Save for a moment
	mov	al,','          ; Separator
%	stos	es:[&E&&di].LO	; Save in buffer
	pop	eax		; Restore

	inc	ecx		; Account for it

	jmp	PREF&DD2DEC_COMMA ; Go around again

PREF&DD2DEC_END:
%	test	[&E&&bp].&PREF&DD2DEC_FLG,@DEC_LEFT ; Izit left-justified?
	jz	short @F	; Not this time

%	lea	&E&&si,[&E&&di+1] ; SS:eSI ==> start of buffer
%	les	&E&&di,[&E&&bp].&PREF&DD2DEC_LCL.&PREF&LDD2DEC_FVEC ; ES:eDI ==> caller's buffer
	assume	es:nothing	; Tell the assembler about it

	cld			; String ops forwards
%   rep movs	es:[&E&&di].LO,ss:[&E&&si].LO ; Move into caller's data area
@@:
%	REGREST <es,&E&&si,edx,ecx,ebx,eax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	popf			; Restore flags

%	add	&E&&sp,@&PREF&LDD2DEC_SIZE ; Remove room from stack
%	pop	&E&&bp		; Restore

	ret	DOFFSIZ 	; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&DD2DEC endp		; End PREF&DD2DEC procedure

	endm			; LDD2DEC_MAC


	BIN2DWORD_MAC
	BIN2WORD_MAC
	BIN2BYTE_MAC
	BIN2DIGIT_MAC
	DD2DEC_MAC

	NPPROC	FLUSH_CACHE -- Flush Page Translation Cache
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Flush the page translation cache by respecifying the
Page Descriptor Base Register.

|

	push	eax		; Save for a moment

	call	READ_CR3	; Get contents of CR3
	mov	cr3,eax 	; Set it again to flush cache

	pop	eax		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FLUSH_CACHE endp		; End FLUSH_CACHE procedure
	NPPROC	READ_CR3 -- Get Current Value of CR3
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read CR3 into EAX taking care to avoid spurious DRn breakpoints.

|

	push	ebx		; Save for a moment

	mov	ebx,dr7 	; Get debug command register
	push	ebx		; Save on stack

; Clear G0-3 and L0-3

;;;;;;; and	ebx,not ((mask $G3) or (mask $G2) or (mask $G1) or (mask $G0)\
;;;;;;;;	       or (mask $L3) or (mask $L2) or (mask $L1) or (mask $L0))
	mov	bl,0		; Clear 'em this way
	mov	dr7,ebx 	; Restore

	mov	eax,cr3 	; Get current PDE base
	jmp	short $+2	; Drain the PIQ

	pop	ebx		; Get original DR7
	mov	dr7,ebx 	; Restore

	pop	ebx		; Restore

	ret			; Return to caller

	public	READ_CR3Z
READ_CR3Z label near		; Mark end of routine for GD range checking

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

READ_CR3 endp			; End READ_CR3 procedure
	NPPROC	CLEAR_OUT -- Clear the Output Buffer
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear the output buffer to all blanks.

|

	REGSAVE <eax,ecx,edi>	; Save for a moment

	lea	edi,INSTROUT	; ES:EDI ==> output line
	mov	al,' '          ; Fill character
	mov	ecx,INSTROUT_LEN ; ECX = # bytes in output buffer
    rep stos	INSTROUT[edi]	; Fill with blanks

	REGREST <edi,ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLEAR_OUT endp			; End CLEAR_OUT procedure

PROG	ends			; End PROG segment


NCODE	segment use16 para public 'ncode' ; Start NCODE segment
	assume	cs:NGROUP,ds:NGROUP

	public	U16_HEXTABLE
U16_HEXTABLE db '0123456789ABCDEF' ; Translate table

	public	U16_CON10
U16_CON10 dd	10		; Constant 10

	BIN2DWORD_MAC U16_
	BIN2WORD_MAC  U16_
	BIN2BYTE_MAC  U16_
	BIN2DIGIT_MAC U16_
	DD2DEC_MAC    U16_

NCODE	ends			; End NCODE segment

	MEND			; End SWAT_MSC module
