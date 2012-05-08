;' $Header:   P:/pvcs/misc/swttools/swat_api.asv   1.6   06 Jan 1995 18:03:42   HENRY  $

	 title	 SWAT_API -- 386SWAT API interface routines
	 page	 58,122
	 name	 SWAT_API

COMMENT |		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1991 Qualitas, Inc.

Environment:  IBM PC, tested under DOS 4.00.

Segmentation:  MASM 5.1 simplified segmentation

Link requirements:  Meant to be called from MSC 6.0

Program derived from:  None.

Original code by:  Henry Groover, May, 1991.

Modifications by:  None.

|

.model	large, c

.386p

.xlist
	Include MASM.INC
	Include 386.INC
	Include VCPI.INC
.list

.code

ARG_STR struc
	ourbp	dw	?	; BP saved locally on stack
if @codesize
	callret dd	?	; caller's far return address
else
	callret dw	?	; near return address
endif
if @datasize
	numsymp dd	?	; far ptr to number of symbols
	symtab	dd	?	; far symbol table address
else
	numsymp dw	?	; near ptr to number of symbols
	symtab	dw	?	; near symbol table address
endif
	allowdupes dw	?	; If != 0, no duplicate checking
ARG_STR ends

PPROC	swat_addsym	-- Add a specified number of symbols to SWAT
assume ds:nothing, es:nothing, ss:nothing, fs:nothing, gs:nothing
COMMENT|

Add numsym symbol table entries to SWAT from symtab & return status
C prototype:	int swat_addsym (WORD *numsymp, char *symtab, int allowdupes)

On entry:
	Stack contains	return address
			ptr to number of symbols
			symbol table address
			non-zero if SYMAPPND_RAW is to be used

On exit:
	AX = SWAT status code:
		00h - success
		88h - symbol table full
		all other values undefined
	contents of *numsymp are set to actual number of records added
	Caller must pop arguments from stack

|

	 push	 bp			; save bp
	 mov	 bp, sp 		; get stack frame

	 REGSAVE <bx,ecx,esi,ds>	; save registers

if @datasize
	 lds	 si, [bp].numsymp	; get pointer to numsym
	 assume  ds:nothing		; tell the assembler about it
else
	 mov	 si, [bp].numsymp	; get near ptr to numsym
endif
	 movzx	 ecx, word ptr [si]	; get number of table entries

	 sub	 esi, esi		; zero high order word of ESI
if @datasize
	 lds	 si, [bp].symtab	; get far pointer to table
	 assume  ds:nothing
else
	 mov	 si, [bp].symtab	; get near pointer (DS is cool)
endif

	 mov	 bl,@DBGSYM_RAPPND	; Append entries, allowing duplicates
	 cmp	 [bp].allowdupes,0	; Are we using raw append?
	 jne	 short @F		; Jump if so

	 mov	 bl,@DBGSYM_APPND	; Append entries to symbol table
@@:
	 VCPICALL @VCPI_DBGSYM		; SWAT API entry

	 movzx	 ax, ah 		; get return code in AX

if @datasize
	 lds	 si, [bp].numsymp	; get pointer to numsym
	 assume  ds:nothing		; tell the assembler about it
else
	 mov	 si, [bp].numsymp	; get near ptr to numsym
endif
	 mov	 [si], cx		; number of table entries added

swat_addsym_exit:

	 REGREST <ds,esi,ecx,bx>	; restore caller's registers

	 pop	 bp			; restore bp

	 ret			; return to caller (caller pops arguments)
assume ds:nothing, es:nothing, ss:nothing, fs:nothing, gs:nothing

swat_addsym	ENDP

PPROC	swat_flushtab	-- Prepare to overwrite existing SWAT symbols
assume ds:nothing, es:nothing, ss:nothing, fs:nothing, gs:nothing
COMMENT|

Restart at beginning of symbol table - next swat_addsym call will overwrite
C prototype:	int swat_addsym (WORD numsym, char *symtab)
PUBLIC	swat_flushtab		; int swat_flushtab (void)

On entry:
	nothing

On exit:
	AX = SWAT status code:
		00h - success
		all other values undefined

|

	 REGSAVE <bx>		; save register

	 mov	 bl, @DBGSYM_FLUSH ; symbol table flush
	 VCPICALL @VCPI_DBGSYM	; call API

	 movzx	 ax, ah 	; get status in AX

	 REGREST <bx>		; restore register

	 ret			; return to caller
assume ds:nothing, es:nothing, ss:nothing, fs:nothing, gs:nothing

swat_flushtab	ENDP

	END		; SWAT_API.ASM
