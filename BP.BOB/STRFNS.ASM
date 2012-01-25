;' $Header:   P:/PVCS/386SWAT/STRFNS.ASV   1.0   25 Jun 1997 12:16:06   BOB  $
; ASM version of common string functions
.386
	include MASM.INC
	include PTR.INC
	include SWAT_SEG.INC

PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP

	extrn	UPPERCASE:near

	NPPROC	StrNCpy -- String Copy With Specific Length
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String copy with specific length

On exit:

EAX	=	actual length copied

|

StrNCpy_str struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
StrNCpyLen dd	?		; Maximum copy length
StrNCpySrc df	?		; Ptr to source
	dw	?		; For alignment
StrNCpyDst df	?		; ...	 destin
	dw	?		; For alignment

StrNCpy_str ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ecx,esi,edi,ds,es> ; Save registers

	mov	ecx,[ebp].StrNCpyLen ; Get length to copy
	jecxz	StrNCpyExit	; Jump if string empty

	lds	esi,[ebp].StrNCpySrc ; Get source ptr
	assume	ds:nothing	; Tell the assembler about it

	les	edi,[ebp].StrNCpyDst ; Get destin ptr
	assume	es:nothing	; Tell the assembler about it

	cld			; String ops forwards
@@:
	lods	ds:[esi].LO	; Get next char
	stos	es:[edi].LO	; Save it back

	cmp	al,0		; Izit EOS?
	loopne	@B		; Jump if not and more chars
StrNCpyExit:
	mov	eax,[ebp].StrNCpyLen ; Get length to copy
	sub	eax,ecx 	; Less length remaining

	REGREST <es,ds,edi,esi,ecx> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	pop	ebp		; Restore

	ret	4+6+2+6+2	; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrNCpy endp			; End StrNCpy procedure
	NPPROC	StrCpy -- String Copy
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String copy

|

StrCpy_str struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
StrCpySrc df	?		; Ptr to source
	dw	?		; For alignment
StrCpyDst df	?		; ...	 destin
	dw	?		; For alignment

StrCpy_str ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,esi,edi,ds,es> ; Save registers

	lds	esi,[ebp].StrCpySrc ; Get source ptr
	assume	ds:nothing	; Tell the assembler about it

	les	edi,[ebp].StrCpyDst ; Get destin ptr
	assume	es:nothing	; Tell the assembler about it

	cld			; String ops forwards
@@:
	lods	ds:[esi].LO	; Get next char
	stos	es:[edi].LO	; Save it back

	cmp	al,0		; Izit EOS?
	jne	short @B	; Jump if not

	REGREST <es,ds,edi,esi,eax> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	pop	ebp		; Restore

	ret	6+2+6+2 	; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrCpy	endp			; End StrCpy procedure
	NPPROC	StrICmp -- String Compare, Case Insensitive
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String compare, case insensitive

On exit:

AX	=	0 if equal
	>	0 if Arg1 > Arg2 at point of difference
	<	0 if Arg1 < Arg2 ...

|

StrICmp_str struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
StrICmpArg2 df	?		; Ptr to Arg #2
	dw	?		; For alignment
StrICmpArg1 df	?		; ...	     #1
	dw	?		; For alignment

StrICmp_str ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <esi,edi,ds,es> ; Save registers

	lds	esi,[ebp].StrICmpArg2 ; Get Arg #2 ptr
	assume	ds:nothing	; Tell the assembler about it

	les	edi,[ebp].StrICmpArg1 ; Get Arg #1 ptr
	assume	es:nothing	; Tell the assembler about it
StrICmpNext:
	mov	ah,ds:[esi]	; Get next Arg #2 char
	mov	al,es:[edi]	; ...	       #1 ...
	inc	esi		; Skip over it
	inc	edi		; ...

	and	ax,ax		; Izit EOS?
	jz	short StrICmpExit ; Jump if so with AX=0

; Check for case-sensitivity

	xchg	al,ah		; Put Arg #2 char in AL for UpperCase
	call	UPPERCASE	; Convert AL to uppercase
	xchg	al,ah		; Put Arg #1 char in AL for UpperCase
	call	UPPERCASE	; Convert AL to uppercase

	sub	al,ah		; Compute Arg1 - Arg2
	cbw			; Extend sign into AH (note flags unchanged)
	jz	short StrICmpNext ; Jump if same
StrICmpExit:
	REGREST <es,ds,edi,esi> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	pop	ebp		; Restore

	ret	6+2+6+2 	; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrICmp endp			; End StrICmp procedure
	NPPROC	StrNICmp -- String Compare, Length Sensitive, Case Insensitive
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String compare, length sensitive, case insensitive

On exit:

AX	=	0 if equal
	>	0 if Arg1 > Arg2 at point of difference
	<	0 if Arg1 < Arg2 ...

|

StrNICmp_str struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
StrNICmpLen dd	?		; Maximum compare length
StrNICmpArg2 df ?		; Ptr to Arg #2
	dw	?		; For alignment
StrNICmpArg1 df ?		; ...	     #1
	dw	?		; For alignment

StrNICmp_str ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ecx,esi,edi,ds,es> ; Save registers

	lds	esi,[ebp].StrNICmpArg2 ; Get Arg #2 ptr
	assume	ds:nothing	; Tell the assembler about it

	les	edi,[ebp].StrNICmpArg1 ; Get Arg #1 ptr
	assume	es:nothing	; Tell the assembler about it

	mov	ecx,[ebp].StrNICmpLen ; Get maximum compare length
	mov	eax,ecx 	; Copy as result in case empty
	jecxz	StrNICmpExit	; Jump if so with AX=0
StrNICmpNext:
	mov	ah,ds:[esi]	; Get next Arg #2 char
	mov	al,es:[edi]	; ...	       #1 ...
	inc	esi		; Skip over it
	inc	edi		; ...

	and	ax,ax		; Izit EOS?
	jz	short StrNICmpExit ; Jump if so with AX=0

; Check for case-sensitivity

	xchg	al,ah		; Put Arg #2 char in AL for UpperCase
	call	UPPERCASE	; Convert AL to uppercase
	xchg	al,ah		; Put Arg #1 char in AL for UpperCase
	call	UPPERCASE	; Convert AL to uppercase

	sub	al,ah		; Compute Arg1 - Arg2
	cbw			; Extend sign into AH (note flags unchanged)
	loopz	short StrNICmpNext ; Jump if same and more chars to compare
StrNICmpExit:
	REGREST <es,ds,edi,esi,ecx> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	pop	ebp		; Restore

	ret	4+6+2+6+2	; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrNICmp endp			; End StrNICmp procedure
	NPPROC	StrLen -- String Length
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String length

On exit:

EAX	=	length

|

StrLen_str struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
StrLenSrc df	?		; Ptr to source
	dw	?		; For alignment

StrLen_str ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ecx,edi,es>	; Save registers

	les	edi,[ebp].StrLenSrc ; Get source ptr
	assume	es:nothing	; Tell the assembler about it

	cld			; String ops forwards
	mov	al,0		; Search for this
	mov	ecx,-1		; We know (or hope) it's there
  repne scas	es:[edi].LO	; Search for it

	mov	eax,-(1+1)	; One for starting -1, one for trailing zero
	sub	eax,ecx 	; Subtract to get length

	REGREST <es,edi,ecx>	; Restore
	assume	es:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	6+2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrLen	endp			; End StrLen procedure
	NPPROC	StrLenW -- String Length, Wide
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String length, wide

On exit:

EAX	=	length

|

StrLenW_str struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
StrLenWSrc df	?		; Ptr to source
	dw	?		; For alignment

StrLenW_str ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ecx,edi,es>	; Save registers

	les	edi,[ebp].StrLenWSrc ; Get source ptr
	assume	es:nothing	; Tell the assembler about it

	cld			; String ops forwards
	mov	ax,0		; Search for this
	mov	ecx,-1		; We know (or hope) it's there
  repne scas	es:[edi].ELO	; Search for it

	mov	eax,-(1+1)	; One for starting -1, one for trailing zero
	sub	eax,ecx 	; Subtract to get length

	REGREST <es,edi,ecx>	; Restore
	assume	es:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	6+2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrLenW endp			; End StrLenW procedure
	NPPROC	StrChr -- String Character Search
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String character search

On exit:

EDX:EAX ==>	matching character
	=	0:0 if none

|

StrChr_str struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
StrChrChr db	?		; Character to search for
	db	?,?,?		; For alignment
StrChrSrc df	?		; Ptr to source
	dw	?		; For alignment

StrChr_str ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <esi,ds>	; Save registers

	lds	esi,[ebp].StrChrSrc ; Get source ptr
	assume	ds:nothing	; Tell the assembler about it

	mov	ah,[ebp].StrChrChr ; Get character

	cld			; String ops forwards
@@:
	lods	ds:[esi].LO	; Get next char

	cmp	al,ah		; Izit a match?
	je	short StrChrFound ; Jump if so

	cmp	al,0		; Izit EOS?
	jne	short @B	; Jump if not

	xor	eax,eax 	; Mark as not found
	xor	edx,edx 	; ...

	jmp	short StrChrExit ; Join common exit code

StrChrFound:
	lea	eax,[esi-1]	; Back off to matching char
	mov	edx,ds		; EDX:EAX ==> matching char
StrChrExit:
	REGREST <ds,esi>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	4+6+2		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

StrChr	endp			; End StrChr procedure

PROG	ends			; End PROG segment

	end			; End STRFNS Module
