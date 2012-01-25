;' $Header$
	title	COMSHELL -- Shell to Create a .COM File
	page	58,122
	name	COMSHELL

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1999 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, byte-aligned, stack,  class 'prog'
	       Program segment CODE,  byte-aligned, public, class 'prog'
	       Tail    segment NCODE, byte-aligned, public, class 'prog'

Program derived from:  None.

Original code by:  Bob Smith, ????, ????.

Modifications by:  None.

|
.386
.xlist
	include MASM.INC
	include ASCII.INC
	include DOS.INC
	include PTR.INC
	include 386.INC
	include CPUFLAGS.INC
.list

PGROUP	group	STACK,CODE,NCODE,NDATA


; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	segment use16 byte stack 'prog' ; Start STACK segment
STACK	ends			; End STACK segment


CODE	segment use16 byte public 'prog' ; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP
.xlist
	include PSP.INC 	; Define & skip over PSP area for .COM program
.list

INITIAL:
	jmp	COMSHELL	; Join initialization code

CODE	ends			; End CODE segment


NDATA	segment use16 dword public 'prog' ; Start NDATA segment
	assume	ds:PGROUP

	public	MSG_CPUID,MSG_CPUID0,MSG_CPUID1,MSG_CPUIDZ
MSG_CPUID db	'Starting check for CPUID bit in EFL',CR,LF,EOS
MSG_CPUID0 db	'Starting call to CPUID, EAX=0',CR,LF,EOS
MSG_CPUID1 db	'Starting call to CPUID, EAX=1',CR,LF,EOS
MSG_CPUIDZ db	'Ending call to CPUID',CR,LF,EOS

NDATA	ends			; End NDATA segment


NCODE	segment use16 byte public 'prog' ; Start NCODE segment
	assume	cs:PGROUP

	NPPROC	COMSHELL -- Shell to Create a .COM File
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

	DOSCALL @STROUT,MSG_CPUID

	call	IZIT_CPUID	; Duzit support the CPUID instruction?
	jnc	short @F	; Jump if not

	DOSCALL @STROUT,MSG_CPUID0
	mov	eax,0		; Function code to retrieve vendor info
	CPUID			; Return with EAX = highest function
				; ...	      ECX:EDX:EBX = vendor ID

	DOSCALL @STROUT,MSG_CPUID1
	mov	eax,1		; Function code to retrieve feature bits
	CPUID			; Return with EAX = stepping info
				;	      EBX, ECX reserved
				;	      EDX = feature bits
@@:
	DOSCALL @STROUT,MSG_CPUIDZ

	ret			; Return to DOS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMSHELL endp			; End COMSHELL procedure
	NPPROC	IZIT_CPUID -- Determine Support of CPUID Instruction
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

The test for the CPUID instruction is done by attempting to set the ID
bit in the high-order word of the extended flag dword.	If that's
successful, the CPUID instruction is supported; otherwise, it's not.

On exit:

CF	=	1 if it's supported
	=	0 otherwise

|

	push	bp		; Save to address the stack
	clc			; Assume it's not supported
	pushfd			; Save original flags
	pushfd			; Save temporary flags

IZIT_CPUID_STR struc

IZIT_CPUID_TMPEFL dd ?		; Temporary EFL
IZIT_CPUID_RETEFL dd ?		; Return EFL
	dw	?		; Caller's BP

IZIT_CPUID_STR ends

	mov	bp,sp		; Address the stack
	or	[bp].IZIT_CPUID_TMPEFL,mask $ID ; Set ID bit
	popfd			; Put into effect

	pushfd			; Put back onto the stack to test

	test	[bp].IZIT_CPUID_TMPEFL,mask $ID ; Izit still set?
	jz	short @F	; No, so it's not supported

	or	[bp].IZIT_CPUID_RETEFL,mask $CF ; Indicate it's supported
@@:
	popfd			; Restore temporary flags
	popfd			; Restore original flags
	pop	bp		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_CPUID endp 		; End IZIT_CPUID procedure

NCODE	ends			; End NCODE segment

	MEND	INITIAL 	; End COMSHELL module
