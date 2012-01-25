;' $Header:   P:/PVCS/386SWAT/INT1/INT1_FNS.ASV   1.19   10 Jul 1997 14:48:42   BOB  $
	title	INT1_FNS -- INT 01h Functions
	page	58,122
	name	INT1_FNS

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-2003 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, April, 1988.

Modifications by:  None.

|

.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include BITFLAGS.INC
	include CPUFLAGS.INC
	include IOPBITS.INC
	include OPCODES.INC
	include ALLMEM.INC
	include WKD.INC
	include VCPI.INC
	include ISVBOP.INC

ifndef INT1_DEF
	include SWAT_SYM.INC
endif	; INT1_DEF
	include SWAT_COM.INC
	include SWAT_SEG.INC

	include INT1_FNS.INC
	include INT1_WIN.INC
.list

	public	@OFFBYTE
@OFFBYTE equ	19		; Length of byte display area

WTAB	segment use32 dword public 'wdata' ; Start WTAB segment
	assume	ds:WGROUP

	extrn	INTER:abs
	extrn	INTER10:abs
	extrn	INTER21:abs
	extrn	INTER67:abs
	extrn	INTER67A:abs
	extrn	INTER68:abs
	extrn	WINTAB_CNT:abs
	extrn	WINTAB:tbyte
	extrn	WINTAB_INTER1A:tbyte
	extrn	WINTAB_INTER22:tbyte
	extrn	WINTAB_INTER31:tbyte

WTAB	ends			; End WTAB segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	COMMON:tbyte
	include QMAX_FIL.INC

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	WINBASE:dword
	extrn	CUR_INSTR:dword

	extrn	EA1OFF:dword
	extrn	EA1TSEL:word

	extrn	INSTROUT_LEN:abs
;;;;;;; extrn	REENTRY:word

ifndef INT1_DEF
	extrn	SELFDBG:dword
	extrn	SYMCOUNT:dword
	extrn	PROXSRCH:word
endif	; INT1_DEF

	public	DISINT0E_ESP,DISINT0E_CR2,DISINT0E_FVEC,DISINT0E_ARB
DISINT0E_ESP dd ?		; Save area for old ESP
DISINT0E_CR2 dd ?		; ...		    CR2
DISINT0E_FVEC df ?		; ...		    INT 0Eh address
DISINT0E_ARB db ?,?		; ...		    INT 0Eh A/R byte

DATA	ends			; End DATA segment


BOPFNS_MAC macro FN,TXT
	local	L1

TEXT	segment use32 byte public 'data' ; Start TEXT segment
	assume	ds:DGROUP

L1	db	TXT,0

TEXT	ends			; End TEXT segment


KEYSEG	segment use32 word public 'data' ; Start KEYSEG segment
	assume	ds:DGROUP

	dw	FN		; Function code

KEYSEG	ends			; End KEYSEG segment


ACTSEG	segment use32 dword public 'data' ; Start ACTSEG segment
	assume	ds:DGROUP

	dd	offset DGROUP:L1 ; Offset to text

ACTSEG	ends			; End ACTSEG segment

	endm			; BOPBFNS


KEYSEG	segment use32 word public 'data' ; Start KEYSEG segment
	assume	ds:DGROUP

	public	BOPFNS
BOPFNS	label	word

KEYSEG	ends			; End KEYSEG segment


ACTSEG	segment use32 dword public 'data' ; Start ACTSEG segment
	assume	ds:DGROUP

	public	BOPTXT
BOPTXT	label	dword

ACTSEG	ends			; End ACTSEG segment


BOPFNS_MAC <(0 shl 8) or BOP_3RDPARTY>,  'RegisterModule'
BOPFNS_MAC <(1 shl 8) or BOP_3RDPARTY>,  'UnRegisterModule'
BOPFNS_MAC <(2 shl 8) or BOP_3RDPARTY>,  'DispatchCall'
BOPFNS_MAC <		 BOP_UNSIMULATE>,'UnSimulate16'


KEYSEG	segment use32 word public 'data' ; Start KEYSEG segment
	assume	ds:DGROUP

@BOPFNS equ	($-BOPFNS)/(type BOPFNS) ; # entries

KEYSEG	ends			; End KEYSEG segment


INSTR	segment use32 dword public 'data' ; Start INSTR segment
	assume	ds:DGROUP

	extrn	INSTR_TAB:dword

INSTR	ends			; End INSTR segment


ESCOD	segment use32 dword public 'data' ; Start ESCOD segment
	assume	ds:DGROUP

	extrn	ESCOD_TAB:dword
;;;;;;; extrn	F2COD_TAB:dword
	extrn	F3COD_TAB:dword

ESCOD	ends			; End ESCOD segment


TEXT	segment use32 byte public 'data' ; Start TEXT segment
	assume	ds:DGROUP

	extrn	REG8:byte
	extrn	REG16:byte

	extrn	MODRM16:dword
	extrn	MODRM32:dword

	extrn	SCALE:byte
	extrn	SREG:byte

	extrn	MSG_LOCK:byte
	extrn	MSG_REP:byte
	extrn	MSG_REPE:byte
	extrn	MSG_REPNE:byte

	extrn	MSG_BPTR:byte
	extrn	MSG_WPTR:byte
	extrn	MSG_DPTR:byte

	extrn	TXT_COMSP:byte
	extrn	TXT_UNDEF:byte
	extrn	TXT_WAIT:byte

	extrn	TXT_WINUNK:byte
	extrn	TXT_WINUNK1:byte
	extrn	TXT_WINUNK2:byte

	public	P@UNDEF
P@UNDEF dd	offset PGROUP:@UNDEF

TEXT	ends			; End TEXT segment


PROG0	segment use32 byte public 'prog' ; Start PROG0 segment
	assume	cs:PGROUP,ds:PGROUP

	include MAXDEV.INC
	extrn	SWATINI:tbyte

PROG0	ends			; End PROG0 segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP

	extrn	DB2HEX:near
	extrn	DW2HEX:near
	extrn	DD2HEX:near

	extrn	GET_LBYTE:near
	extrn	GET_IBYTE:near
	extrn	GET_IBYTE_ND:near
	extrn	GET_IWORD:near
	extrn	GET_IDWORD:near

	extrn	GET_MODRM:near
	extrn	COPY_ASCIIZ:near
	extrn	DISP_COMMA:near
	extrn	DISP_PLUS:near
	extrn	DISP_SRO:near
	extrn	DISP_SIGN:near
	extrn	FILL_OPCODE:near

ifndef INT1_DEF
	extrn	SYMHASH_SRCH:near
	extrn	GETBASE:near
endif	; INT1_DEF

	NPPROC	INST_DIS0E -- Install Local INT 0Eh Handler
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Install local INT 0Eh handler.

|

	REGSAVE <eax,ebx,gs>	; Save registers

	mov	gs,COMMON.FILE_4GB ; Address all of memory
	assume	gs:AGROUP	; Tell the assembler about it

	sub	esp,size DTR_STR ; Make room for IDTR
	SIDTD	[esp].EDF	; Store on stack
	mov	ebx,[esp].DTR_BASE ; Get base address of IDT
	add	esp,size DTR_STR ; Remove IDTR from stack

	mov	ax,cs		; Get our selector
	xchg	ax,AGROUP:[ebx+0Eh*(size IDT_STR)].IDT_SELECT ; Swap 'em
	mov	DISINT0E_FVEC.FSEL,ax ; Save to restore later

	lea	eax,DIS_INTFAULT ; Get our 32-bit offset
	xchg	ax,AGROUP:[ebx+0Eh*(size IDT_STR)].IDT_OFFLO ; Swap 'em
	mov	DISINT0E_FVEC.FOFF.ELO,ax ; Save to restore later

	shr	eax,16		; Shift down the high-order word
	xchg	ax,AGROUP:[ebx+0Eh*(size IDT_STR)].IDT_OFFHI ; Swap 'em
	mov	DISINT0E_FVEC.FOFF.EHI,ax ; Save to restore later

	mov	al,CPL0_INTR3 or CPL3 ; Get our access rights byte
	xchg	al,AGROUP:[ebx+0Eh*(size IDT_STR)].IDT_ACCESS ; Swap 'em
	mov	DISINT0E_ARB,al ; Save to restore later

	mov	eax,cr2 	; Get previous Page fault linear address
	mov	DISINT0E_CR2,eax ; Save to restore later

	REGREST <gs,ebx,eax>	; Restore
	assume	gs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST_DIS0E endp 		; End INST_DIS0E procedure
	NPPROC	REST_DIS0E -- Restore Global INT 0Eh Handler
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore global INT 0Eh handler

|

	REGSAVE <eax,ebx,gs>	; Save registers

	mov	gs,COMMON.FILE_4GB ; Address all of memory
	assume	gs:AGROUP	; Tell the assembler about it

	sub	esp,size DTR_STR ; Make room for IDTR
	SIDTD	[esp].EDF	; Store on stack
	mov	ebx,[esp].DTR_BASE ; Get base address of IDT
	add	esp,size DTR_STR ; Remove IDTR from stack

	mov	ax,DISINT0E_FVEC.FSEL ; Get original selector
	mov	AGROUP:[ebx+0Eh*(size IDT_STR)].IDT_SELECT,ax ; Save it back

	mov	eax,DISINT0E_FVEC.FOFF ; Get original offset
	mov	AGROUP:[ebx+0Eh*(size IDT_STR)].IDT_OFFLO,ax ; Save it back

	shr	eax,16		; Shift down the high-order word
	mov	AGROUP:[ebx+0Eh*(size IDT_STR)].IDT_OFFHI,ax ; Save it back

	mov	al,DISINT0E_ARB ; Get original access rights byte
	mov	AGROUP:[ebx+0Eh*(size IDT_STR)].IDT_ACCESS,al ; Save it back

	mov	eax,DISINT0E_CR2 ; Get original Page Fault linear address
	mov	cr2,eax 	; Restore

	REGREST <gs,ebx,eax>	; Restore
	assume	gs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_DIS0E endp 		; End REST_DIS0E procedure
	FPPROC	DIS_INTFAULT -- INSTRDEC Page Fault Handler
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

INSTRDEC Page Fault handler

A page fault occurred while disassembling code.

Cut back the stack to the original, put a ?? in the
output display, and continue execution at a common point.

|

	mov	esp,DISINT0E_ESP ; Cut back the stack

	test	[ebp].ID_FLAG,@FLAG_OPER ; Izit operand analysis?
	jnz	short DIS_INTFAULT_EXIT ; Yes, skip all this

; Display pseudo-opcode byte of ??

	push	edi		; Save for a moment

	mov	edi,[ebp].ID_IOUT ; Restore initial output stream offset
	mov	es:[edi].ELO,'??' ; Save pseudo-byte

; Display pseudo-instruction of ????

;;;;;;; mov	edi,[ebp].ID_IOUT ; Get initial offset of output stream
	add	edi,@OFFBYTE	; Skip over byte display area
	mov	es:[edi].EDD,'????' ; Save pseudo-instruction

	pop	edi		; Restore

	mov	esi,[ebp].ID_IINS ; Get initial instruction stream offset
	inc	esi		; Skip over the pseudo-opcode
DIS_INTFAULT_EXIT:
	jmp	INSTR_OPER_COM_EXIT ; Join common exit code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DIS_INTFAULT endp		; End DIS_INTFAULT procedure
	NPPROC	INSTROPER -- Instruction Operand Analyzer
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Instruction operand analyzer

On entry:

CX	=	Bit 0:	0 for USE16 segment
			 1 for USE32 ...
		 Bit 1:  0 for Real or Virtual 8086 Mode
			 1 for Protected Mode
FS:ESI	==>	instruction stream
ES:EDI	==>	operand data structure
SS:EBP	==>	FORW_STR

On exit:

ES:EDI	==>	operand data structure, updated

|

	push	ebp		; Save FORW_STR pointer as part of ID_FORW_STR
	sub	esp,size ID_STR ; Make room for structure
	mov	ebp,esp 	; Hello, Mr. Stack

; Initialize data area on the stack

	mov	[ebp].ID_FLAG,0 ; Zero initial flags

	test	cx,@BIT0	; Izit a USE32 segment?
	jz	short @F	; Jump if USE16 segment

	or	[ebp].ID_FLAG,@FLAG_USE32 ; Mark as USE32 segment
@@:
	test	cx,@BIT1	; Izit Real or Virtual Mode?
	jz	short @F	; Jump if so

	or	[ebp].ID_FLAG,@FLAG_PM ; Mark as Protected Mode
@@:
	or	[ebp].ID_FLAG,@FLAG_OPER ; Mark as operand analysis
	mov	[ebp].ID_PDEF,0  ; ...	    default prefixes
	mov	[ebp].ID_PRES,0  ; ...	    present prefixes
	mov	[ebp].ID_NCOMP,0 ; No components displayed so far

	mov	[ebp].ID_IINS,esi ; Save offset of initial instruction byte
	mov	[ebp].ID_CINS,esi ; ...     current instruction byte

	mov	es:[edi].OPER1_SEG,@SEG_DS ; Mark as default segment register
	mov	es:[edi].OPER2_SEG,@SEG_DS ; ...

	mov	es:[edi].OPER1_DISP,0 ; Initialize displacement value
	mov	es:[edi].OPER2_DISP,0

	mov	es:[edi].OPER1_FLAG,0 ; Initialize flag values
	mov	es:[edi].OPER2_FLAG,0

	mov	es:[edi].OPER1_DWID,0 ; Initialize data width values
	mov	es:[edi].OPER2_DWID,0

	mov	es:[edi].OPER1_IMM,0 ; Initialize immediate values
	mov	es:[edi].OPER2_IMM,0

	REGSAVE <eax,esi>	; Save for a moment

	call	INSTR_OPER_COM	; Call common routine
				; returning ESI = next instruction
	mov	ax,[ebp].ID_PDEF ; Get default behavior flags

	test	ax,@PREF_ASP	; Check for ASP flag
	jz	short @F	; Not this time

	or	es:[edi].OPER1_FLAG,@OPER_ASP ; Mark as present
	or	es:[edi].OPER2_FLAG,@OPER_ASP ; Mark as present
@@:
	test	ax,@PREF_OSP	; Check for OSP flag
	jz	short @F	; Not this time

	or	es:[edi].OPER1_FLAG,@OPER_OSP ; Mark as present
	or	es:[edi].OPER2_FLAG,@OPER_OSP ; Mark as present
@@:
	REGREST <esi,eax>	; Restore

	add	esp,size ID_STR ; Strip structure from stack
	pop	ebp		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INSTROPER endp			; End INSTROPER procedure
	NPPROC	INSTRDEC -- Instruction Decoder
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Instruction decoder

On entry:

CX	=	Bit 0:	0 for USE16 segment
			 1 for USE32 ...
		 Bit 1:  0 for Real or Virtual 8086 Mode
			 1 for Protected Mode
FS:ESI	==>	instruction stream
EBX	=	offset base
ES:EDI	==>	output stream
SS:EBP	==>	FORW_STR

On exit:

FS:ESI	==>	instruction stream, updated
ES:EDI	==>	output stream, updated

|

ifndef INT1_DEF
	SELFBREAK INSTRDEC,02h	; Allow breakpoint if SELFDBG & 02 != 0
endif	; INT1_DEF

	push	ebp		; Save FORW_STR pointer as part of ID_FORW_STR
	sub	esp,size ID_STR ; Make room for structure
	mov	ebp,esp 	; Hello, Mr. Stack

; Initialize data area on the stack

	mov	[ebp].ID_FLAG,0 ; Zero initial flags

	test	cx,@BIT0	; Izit a USE32 segment?
	jz	short @F	; Jump if USE16 segment

	or	[ebp].ID_FLAG,@FLAG_USE32 ; Mark as USE32 segment
@@:
	test	cx,@BIT1	; Izit Real or Virtual Mode?
	jz	short @F	; Jump if so

	or	[ebp].ID_FLAG,@FLAG_PM ; Mark as Protected Mode
@@:
	mov	[ebp].ID_PDEF,0   ; Initalize default prefixes
	mov	[ebp].ID_PRES,0   ; ...       present prefixes
	mov	[ebp].ID_NCOMP,0  ; No components displayed so far

	mov	[ebp].ID_IINS,esi ; Save offset of initial instruction byte
	mov	[ebp].ID_CINS,esi ; ...     current instruction byte
	mov	[ebp].ID_BASE,ebx ; ...     JMP/CALL segment/selector base
	mov	[ebp].ID_IOUT,edi ; ...     initial output stream

	add	edi,@OFFBYTE	; Skip over byte display area

	call	INSTR_OPER_COM	; Call common routine
				; returning ESI = next instruction
	add	esp,size ID_STR ; Strip structure from stack
	pop	ebp		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INSTRDEC endp			; End INSTRDEC procedure
	NPPROC	INSTR_OPER_COM -- Instruction/Operand Common Routine
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common routine for INSTRDEC and INSTROPER.

On entry:

FS:ESI	==>	instruction stream
ES:EDI	==>	output stream
SS:EBP	==>	ID_STR

|

	REGSAVE <eax,ebx,ecx,edx> ; Save registers

	cld			; String ops forwardly

	push	DISINT0E_ESP	; Save to be re-entrant
	push	DISINT0E_CR2	; ...
	push	DISINT0E_FVEC.FOFF ; ...
	push	DISINT0E_FVEC.FSEL ; ...
	push	DISINT0E_ARB.ELO ; ...

	mov	DISINT0E_ESP,esp ; ...

	call	INST_DIS0E	; Install our Page Fault handler

	test	[ebp].ID_FLAG,@FLAG_USE32 ; Izit USE32?
	jz	short INSTR_OPER_COM_NEXT ; Not this time

	xor	[ebp].ID_PDEF,@PREF_OSP or @PREF_ASP ; Switch OSP and ASP default
INSTR_OPER_COM_NEXT:
	call	GET_IBYTE	; AL = next instruction byte

	movzx	esi,al		; Copy to index register
	mov	esi,INSTR_TAB[esi*(type INSTR_TAB)] ; DS:ESI ==> action stream

	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action


	public	@EXIT
@EXIT:

; Handle LOCK prefix

	test	[ebp].ID_PRES,@PREF_LOCK ; Izit present?
	jz	short @EXIT2	; Jump if not

	test	[ebp].ID_FLAG,@FLAG_REP ; Repeat prefix used?
	jnz	short @EXIT2	; Jump if so (only one such prefix)

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @EXIT1	; Jump if so

	REGSAVE <esi,edi>	; Save for a moment

	mov	edi,[ebp].ID_IOUT ; Get initial offset of output stream
	add	edi,@OFFBYTE	; Skip over byte display area
	dec	edi		; Back up to store point
	dec	edi
	lea	esi,MSG_LOCK	; DS:ESI ==> 'LOCK'

	std			; String ops backwards
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	cld			; String ops forwards

	REGREST <edi,esi>	; Restore
@EXIT1:
	or	[ebp].ID_FLAG,@FLAG_LOCK ; Mark as used
@EXIT2:

; Ensure all prefixes accounted for

	test	[ebp].ID_FLAG,@FLAG_SREG ; Segment register used?
	jz	short @F	; Not this time

	and	[ebp].ID_PRES,not @PREF_SREG ; Clear all SREG flags
@@:
	test	[ebp].ID_FLAG,@FLAG_OSP ; Operand size prefix used?
	jz	short @F	; Not this time

	and	[ebp].ID_PRES,not @PREF_OSP ; Clear the flag
@@:
	test	[ebp].ID_FLAG,@FLAG_ASP ; Address size prefix used?
	jz	short @F	; Not this time

	and	[ebp].ID_PRES,not @PREF_ASP ; Clear the flag
@@:
	test	[ebp].ID_FLAG,@FLAG_REP ; Repeat prefix used?
	jz	short @F	; Not this time

	and	[ebp].ID_PRES,not (@PREF_REPE or @PREF_REPNE) ; Clear the flags
@@:
	test	[ebp].ID_FLAG,@FLAG_LOCK ; Lock prefix used?
	jz	short @F	; Not this time

	and	[ebp].ID_PRES,not @PREF_LOCK ; Clear the flag
@@:
	test	[ebp].ID_FLAG,@FLAG_WAIT ; Wait prefix used?
	jz	short @F	; Not this time

	and	[ebp].ID_PRES,not @PREF_WAIT ; Clear the flag
@@:
	cmp	[ebp].ID_PRES,0 ; Any prefixes remaining?
	jne	@UNDEF		; Yes, handle as undefined opcode

; Display the opcode bytes

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short INSTR_OPER_COM_EXIT ; Yes, skip all this

	push	edi		; Save for a moment

	mov	edi,[ebp].ID_IOUT ; Restore initial output stream offset
	mov	esi,[ebp].ID_IINS ; Get initial instruction stream offset
	mov	ecx,[ebp].ID_CINS ; Get current instruction offset
	sub	ecx,esi 	; Less starting offset
	mov	edx,ecx 	; Save actual length

; Ensure we don't overwrite the allotted space

	cmp	ecx,@OFFBYTE/2	; Ensure enough room
	jbe	short @EXIT_OPCOD ; Jump if it fits

	mov	ecx,@OFFBYTE/2	; Use maximum
@EXIT_OPCOD:
	cmp	es:[edi].ELO,'  ' ; Are both spaces available?
	jne	short @EXIT_OPCODZ ; Jump if not (avoid overwrite)

	lods	fs:[esi].LO	; Get the next instruction stream byte

	call	DB2HEX		; Convert AL to hex at ES:EDI

	dec	edx		; Subtract from actual length

	loop	@EXIT_OPCOD	; Jump if more bytes to display
@EXIT_OPCODZ:
	and	edx,edx 	; Any bytes remaining?
	jz	short @F	; Jump if not

	mov	al,'+'          ; Mark as more to follow
S32	stos	es:[edi].LO	; Save in output area
@@:
	pop	edi		; Restore

	mov	esi,[ebp].ID_CINS ; Return offset of next instruction byte
INSTR_OPER_COM_EXIT:
	call	REST_DIS0E	; Restore old Page Fault handler

	pop	DISINT0E_ARB.ELO ; Restore
	pop	DISINT0E_FVEC.FSEL ; ...
	pop	DISINT0E_FVEC.FOFF ; ...
	pop	DISINT0E_CR2	; ...
	pop	DISINT0E_ESP	; ...

	REGREST <edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INSTR_OPER_COM endp		; End INSTR_OPER_COM procedure
ifndef INT1_DEF
	NPPROC	CHECK_SYM -- Check for symbol at linear address & display it
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for a symbol at the linear address passed in EAX.  If found,
put its name in the output buffer.  Otherwise, return with CF=1.

On entry:

EAX	=	linear address to check
ES:EDI	==>	output stream
SS:EBP	==>	ID_STR

On exit:

ES:EDI	==>	output stream (updated)
CF=0		 symbol was found
CF=1		 symbol not found
All other registers, including EAX, are preserved.

|

	REGSAVE <eax,ebx,ecx,edx,esi> ; Save registers

	cmp	SYMCOUNT,1	; Are there any symbols loaded?
	jc	short CHECK_SYM_EXIT ; Jump if not

	mov	bx,PROXSRCH	; Get proximity search parameters
	movzx	edx,bl		; Convert proximity step to dword
	sub	bl,bl		; Clear proximity total
CHECK_SYM_NEXT:
	call	SYMHASH_SRCH	; Check SYMHASH for match
	jnc	short @F	; Continue if found

	cmp	bh,1		; Continue proximity search?
	jc	short CHECK_SYM_EXIT ; Jump if not (note CF=1)

	dec	bh		; Decrement attempt counter
	sub	eax,edx 	; Try next door
	jc	short CHECK_SYM_EXIT ; Jump if we wrapped (CF=1)

	add	bl,dl		; Adjust proximity total counter

	jmp	short CHECK_SYM_NEXT ; Try again


@@:
	lea	esi,[eax].SYM_NAMLEN ; DGROUP:ESI ==> symbol name length byte
	lods	DGROUP:[esi].LO ; Get length byte
	movzx	ecx,al		; Put it in ECX
	stc			; Set CF in case ECX = 0
	jecxz	short CHECK_SYM_EXIT ; Indicate failure

; Now make sure we're not overrunning the buffer.  Leave room for comma and
; a dword (e.g. cmp [very_long_symbol_name+1C],12345678)
SYMTRAIL_MAX equ '+1C],12345678' ; Maximum possible disassembly after symbol
SYMTRAIL_MAXLEN SIZESTR SYMTRAIL_MAX ; Maximum length after symbol

; Why doesn't MASM properly encode the negative sign on a d32 displacement???
;;;;;;;  lea	 edx,[edi-INSTROUT_LEN] ; Current offset - buffer size =
;;;;;;; 			; start offset - (space remaining)
	mov	edx,edi 	; Get current offset
	sub	edx,INSTROUT_LEN ; Subtract length of buffer
	sub	edx,[ebp].ID_IOUT ; Get -(space remaining)
	neg	edx		; Get space remaining in buffer
	sub	edx,SYMTRAIL_MAXLEN ; Less reserve space
	jc	short CHECK_SYM_EXIT ; Jump if nothing left (note CF=1)

	cmp	edx,ecx 	; Is space remaining adequate?
	jae	short @F	; Jump if so

	mov	ecx,edx 	; Truncate symbol name
@@:
S32 rep movs	<es:[edi].LO,DGROUP:[esi].LO> ; Copy to output buffer

	or	bl,bl		; Was it a proximity hit?
	jz	short @F	; Jump if not

	mov	al,'+'          ; Indicate proximity
S32	stos	es:[edi].LO	; Copy to output buffer

	mov	al,bl		; Get bytes added
	call	DB2HEX		; Convert AL to hex at ES:EDI
@@:
	clc			; Indicate success
CHECK_SYM_EXIT:
	REGREST <esi,edx,ecx,ebx,eax> ; Restore registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SYM endp		; End CHECK_SYM procedure
endif	; ifndef INT1_DEF
ifndef INT1_DEF
	NPPROC	GET_PTRBASE -- Get selector base for AX
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Select the appropriate selector or segment value for AX

On entry:
AX	=	segment or selector value
SS:EBP	==>	ID_STR

On exit:
EAX	=	linear address of selector base or segment << 4
CF=0		 EAX is valid
CF=1		 EAX is not valid

|

	REGSAVE <ebp>		; Save ID_STR ptr

	test	[ebp].ID_FLAG,@FLAG_PM ; Izit protected mode?
	jz	short GET_PTRBASE_VM	; Use segment value

	mov	ebp,[ebp].ID_FORW_EBP ; Get FORW_STR ptr

	push	ax		; Put segment/selector on stack
	call	GETBASE 	; Get selector base using ss:[ebp] ==> FORW_STR

	jmp	short GET_PTRBASE_EXIT ; Return status from GETBASE in CF


GET_PTRBASE_VM:
	movzx	eax,ax		; Clear high word
	shl	eax,(4-0)	; Convert from paragraphs to bytes
				; (Note CF=0)
GET_PTRBASE_EXIT:
	REGREST <ebp>		; Restore ID_STR ptr

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_PTRBASE endp		; End GET_PTRBASE procedure
endif	; INT1_DEF
ifndef INT1_DEF
	NPPROC	GET_OPSELBASE -- Get selector base for current operand
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Select the appropriate selector value according to ID_STR

On entry:
SS:EBP	==>	ID_STR

On exit:
EAX	=	linear address of selector base or segment << 4
CF=0		 EAX is valid
CF=1		 EAX is invalid

|

	REGSAVE <ebx,ecx,ebp>	; Save registers

	mov	cx,[ebp].ID_PRES ; Get flags for current instruction prefix
	and	cx,@PREF_SREG	; Isolate segment register bits

	mov	bx,[ebp].ID_FLAG ; Get flags to check mode for unassembly

	mov	ebp,[ebp].ID_FORW_EBP ; SS:[EBP] ==> FORW_STR

	mov	ax,[ebp-@BPBACK].BACK_GS.DTR_LIM ; Use GS
	cmp	cx,@PREF_GS	; Izit GS?
	je	short GET_OPSEL_GETB ; Join common code

	mov	ax,[ebp-@BPBACK].BACK_FS.DTR_LIM ; Use FS
	cmp	cx,@PREF_FS	; Izit FS?
	je	short GET_OPSEL_GETB ; Join common code

	mov	ax,[ebp-@BPBACK].BACK_ES.DTR_LIM ; Use ES
	cmp	cx,@PREF_ES	; Izit ES?
	je	short GET_OPSEL_GETB ; Join common code

	mov	ax,[ebp-@BPBACK].BACK_SS.DTR_LIM ; Use SS
	cmp	cx,@PREF_SS	; Izit SS?
	je	short GET_OPSEL_GETB ; Join common code

	mov	ax,[ebp-@BPBACK].BACK_CS.DTR_LIM ; Use CS
	cmp	cx,@PREF_CS	; Izit CS?
	je	short GET_OPSEL_GETB ; Join common code

	mov	ax,[ebp-@BPBACK].BACK_DS.DTR_LIM ; Default to DS
GET_OPSEL_GETB:
	test	bx,@FLAG_PM	; Izit protected mode?
	jz	short @F	; Use segment value

	push	ax		; Put segment/selector on stack
	call	GETBASE 	; Get selector base using ss:[ebp] ==> FORW_STR

	jmp	short GET_OPSEL_EXIT ; Return status from GETBASE in CF


@@:
	movzx	eax,ax		; Clear high word
	shl	eax,(4-0)	; Convert from paragraphs to bytes
				; (Note CF=0)
GET_OPSEL_EXIT:
	REGREST <ebp,ecx,ebx>	; Restore registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_OPSELBASE endp		; End GET_OPSELBASE procedure
endif	; INT1_DEF
	NPPROC	@SETREP -- Set Repeat Prefix
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set repeat prefix.

On entry:

DS:ESI	==>	action stream

On exit:

DS:ESI	==>	action stream, updated
EAX	=	destroyed

|

	call	GET_IBYTE_ND	; AL = next instruction byte (non-destructively)

	cmp	al,@OPCOD_2ND	; Izit secondary table opcode?
	jne	short @SETREP1	; Jump if not

;;;;;;; cmp	REENTRY,1	; Check re-entry level
;;;;;;; jne	short @F	; Jump if re-entry
;;;;;;;
;;;;;;; int	03h		; Call our debugger
;;;@@:
	lods	ds:[esi].EDD	; Get (and discard) instruction prefix flag
	call	GET_IBYTE	; AL = next instruction byte (0Fh) (discard)

	xor	eax,eax 	; Zero to use as dword
	call	GET_IBYTE	; AL = next instruction byte

	push	eax		; Save for a moment
	lods	ds:[esi].EDD	; Get table offset (F2COD_TAB or F3COD_TAB)
	pop	esi		; Restore to ESI

	mov	esi,DGROUP:[eax+esi*(type F3COD_TAB)] ; DS:ESI ==> action stream
@SETREP0:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action


@SETREP1:
	cmp	al,@OPCOD_NOP	; Izit NOP?
	jne	short @F	; Jump if not

	cmp	ds:[esi+4].EDD,offset DGROUP:F3COD_TAB ; Izit F3 prefix?
	jne	short @F	; Jump if not

	lods	ds:[esi].EDD	; Get (and discard) instruction prefix flag
	lods	ds:[esi].EDD	; Get (and discard) table offset (F3COD_TAB)

	jmp	@SETREP0	; Join common code


@@:
	lods	ds:[esi].EDD	; Get instruction prefix flag
	xor	[ebp].ID_PDEF,ax ; Toggle the default behavior
	or	[ebp].ID_PRES,ax ; Mark as present

	lods	ds:[esi].EDD	; Get (and discard) table offset (0)

	jmp	INSTR_OPER_COM_NEXT  ; Continue with the next instruction byte

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@SETREP endp			; End @SETREP procedure
	NPPROC	@SETPREF -- Set Instruction Prefix
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set instruction prefix.

On entry:

DS:ESI	==>	action stream

On exit:

DS:ESI	==>	action stream, updated
EAX	=	destroyed

|

	lods	ds:[esi].EDD	; Get instruction prefix flag
	xor	[ebp].ID_PDEF,ax ; Toggle the default behavior
	or	[ebp].ID_PRES,ax ; Mark as present

	jmp	INSTR_OPER_COM_NEXT  ; Continue with the next instruction byte

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@SETPREF endp			; End @SETPREF procedure
	NPPROC	@UNDEF -- Undefined Opcode
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Undefined opcode.

On entry:

ES:EDI	==>	output stream or operand data structure

On exit:

ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

	mov	es:[edi].OPER1_FLAG,0 ; Clear all operand #1 flags
	mov	es:[edi].OPER2_FLAG,0 ; ...		   #2
	mov	[ebp].ID_PRES,0 ; Mark as no prefixes present

	jmp	@EXIT		; That's all folks


@@:
	push	ecx		; Save for a moment

	mov	ecx,[ebp].ID_IOUT ; Get offset of initial output stream
	xchg	ecx,edi 	; Swap with current offset
	sub	ecx,edi 	; Less initial offset to get
				; amount displayed so far
	mov	al,' '          ; Fill with blanks
    rep stos	es:[edi].LO

	pop	ecx		; Restore

	mov	edi,[ebp].ID_IOUT ; Get offset of initial output stream
	add	edi,@OFFBYTE	; Skip over byte display area

	mov	eax,[ebp].ID_IINS ; FS:EAX ==> initial instruction byte
	mov	[ebp].ID_CINS,eax ; Save as current opcode

	mov	[ebp].ID_FLAG,0 ; Start with fresh flags
	mov	[ebp].ID_PRES,0 ; Mark as no prefixes present
	mov	[ebp].ID_NCOMP,0 ; No components displayed so far

	call	GET_IBYTE	; AL = next instruction byte

	cmp	al,9Bh		; Check for WAIT instruction/prefix
	je	short @UNDEF_WAIT ; Good guess

	push	esi		; Save for a moment

	lea	esi,TXT_UNDEF	; DS:ESI ==> undefined opcode text
	mov	ecx,edi 	; Save starting offset
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	call	FILL_OPCODE	; Fill out the opcode text from ECX

	pop	esi		; Restore

	call	DB2HEX		; Convert AL to hex at ES:EDI

	jmp	short @UNDEF_EXIT ; Join common exit code


@UNDEF_WAIT:
	push	esi		; Save for a moment

	lea	esi,TXT_WAIT	; DS:ESI ==> 'WAIT'
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

	pop	esi		; Restore
@UNDEF_EXIT:
	jmp	@EXIT		; That's all folks

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@UNDEF	endp			; End @UNDEF procedure
	NPPROC	@REL8 -- Relative Displacement, Byte-wide
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Relative displacement, byte-wide.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @REL8_OPER ; Jump if so

	call	GET_IBYTE	; AL = next instruction byte

	cbw			; Sign-extend AL to AX
	cwde			; Sign-extend AX to EAX
@REL_COM:
	add	eax,[ebp].ID_CINS ; Plus current instruction offset
	sub	eax,[ebp].ID_BASE ; Less segment/selector base

	test	[ebp].ID_FLAG,@FLAG_USE32 ; Izit USE32?
	jnz	short @REL8_USE32 ; Yes

; It's a USE16 segment

ifndef INT1_DEF
	push	eax		; Save EAX
	movzx	eax,ax		; Clear high word
	add	eax,[ebp].ID_BASE ; Add segment/selector base back in
	call	CHECK_SYM	; See if it's a symbol
	pop	eax		; Restore EAX
	jnc	short @REL8_EXIT ; It is, so skip hex operand display
endif	; INT1_DEF
	test	[ebp].ID_FLAG,@FLAG_OSP ; OSP used?
	jnz	short @REL8_DWORD ; Yes, display as dword
@REL8_WORD:
	call	DW2HEX		; Convert AX to hex at ES:EDI

	jmp	short @REL8_EXIT ; Join common exit code


; It's a USE32 segment

@REL8_USE32:

ifndef INT1_DEF
	push	eax		; Save EAX
	add	eax,[ebp].ID_BASE ; Add segment/selector base back in
	call	CHECK_SYM	; See if it's a symbol
	pop	eax		; Restore EAX
	jnc	short @REL8_EXIT ; It is, so skip hex operand display
endif	; INT1_DEF
	test	[ebp].ID_FLAG,@FLAG_OSP ; OSP used?
	jnz	short @REL8_WORD ; Yes, display as word
@REL8_DWORD:
	call	DD2HEX		; Convert EAX to hex at ES:EDI

	jmp	short @REL8_EXIT ; Join common exit code


@REL8_OPER:
	call	CHECK_JCC	; Check for Jcc instruction
	pushfd			; Save flags (CF from CHECK_JCC)
	call	GET_IBYTE	; AL = next instruction byte
	popfd			; Restore
	jc	short @REL8_EXIT ; Skip direction testing if not a Jcc

	or	al,al		; Determine direction of branch target
	jns	short @REL8_EXIT ; Jump if forward

	or	es:[edi].OPER1_FLAG,@OPER_JCC_BACK ; Mark as jump backwards
@REL8_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@REL8	endp			; End @REL8 procedure
	NPPROC	@REL16 -- Relative Displacement, Word-wide
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Relative displacement, word-wide.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @REL16_OPER ; Yes

	call	GET_IWORD	; AX = next instruction word
	cwde			; Sign-extend AX to EAX

	jmp	@REL_COM	; Join common relative offset code


@REL16_OPER:
	call	CHECK_JCC	; Check for Jcc instruction
	pushfd			; Save flags (CF from CHECK_JCC)
	call	GET_IWORD	; AX = next instruction word
	popfd			; Restore
	jc	short @REL16_EXIT ; Skip direction testing if not a Jcc

	or	ax,ax		; Determine direction of branch target
	jns	short @REL16_EXIT ; Jump if forward

	or	es:[edi].OPER1_FLAG,@OPER_JCC_BACK ; Mark as jump backwards
@REL16_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@REL16	endp			; End @REL16 procedure
	NPPROC	@REL32 -- Relative Displacement, Dword-wide
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Relative displacement, dword-wide.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @REL32_OPER ; Yes

	call	GET_IDWORD	; EAX = next instruction dword

	jmp	@REL_COM	; Join common relative offset code


@REL32_OPER:
	call	CHECK_JCC	; Check for Jcc instruction
	pushfd			; Save flags (CF from CHECK_JCC)
	call	GET_IDWORD	; EAX = next instruction dword
	popfd			; Restore
	jc	short @REL32_EXIT ; Skip direction testing if not a Jcc

	or	eax,eax 	; Determine direction of branch target
	jns	short @REL32_EXIT ; Jump if forward

	or	es:[edi].OPER1_FLAG,@OPER_JCC_BACK ; Mark as jump backwards
@REL32_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@REL32	endp			; End @REL32 procedure
	NPPROC	CHECK_JCC -- Check On Jcc Instructions
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on Jcc instructions such as

Instruction	 Opcode
-----------	 ------
Jcc short	 7x
Jcc near	 8x
LOOPNZ		 E0
LOOPZ		 E1
LOOP		 E2
JeCXZ		 E3

On exit:

AL	=	condition code
CF	=	0 if it's a Jcc instruction
	=	1 if not

|

	call	GET_LBYTE	; AL = last instruction byte

	cmp	al,0E0h 	; Check for LOOPNZ
	jne	short @F	; Not this time

	mov	al,15h		; Use LOOPNZ CC

	jmp	short CHECK_JCC_CLC1 ; Join common CLC code


@@:
	cmp	al,0E1h 	; Check for LOOPZ
	jne	short @F	; Not this time

	mov	al,14h		; Use LOOPZ CC

	jmp	short CHECK_JCC_CLC1 ; Join common CLC code


@@:
	cmp	al,0E2h 	; Check for LOOP
	jne	short @F	; Not this time

	mov	al,12h		; Use LOOP CC

	jmp	short CHECK_JCC_CLC1 ; Join common CLC code


@@:
	cmp	al,0E3h 	; Check for JCXZ
	jne	short @F	; Not this time

	mov	al,10h		; Use CX=0 CC

	jmp	short CHECK_JCC_CLC1 ; Join common CLC code


@@:
	mov	ah,al		; Copy to test
	and	ah,@NIB1	; Isolate nibble #1

	cmp	ah,70h		; Check for short Jcc opcode
	je	short CHECK_JCC_CLC ; It's a Jcc instruction

	cmp	ah,80h		; Check for near Jcc instruction
	stc			; Assume not
	jne	short CHECK_JCC_EXIT ; Not this time
CHECK_JCC_CLC:
	and	al,@NIB0	; Isolate the condition code
CHECK_JCC_CLC1:
	mov	es:[edi].OPER1_CC,al ; Save as condition code
	or	es:[edi].OPER1_FLAG,@OPER_JCC ; Mark as Jcc instruction

	clc			; Indicate it's a Jcc
CHECK_JCC_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_JCC endp			; End CHECK_JCC procedure
	NPPROC	@RPT -- Display Repeat Prefix (If Any)
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display repeat prefix (if any).

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	lods	ds:[esi].EDD	; Get repeat type flag
				; 0 = use REP if specified
				; 1 = use REPE or REPNE if specified

	test	[ebp].ID_PRES,@PREF_REPNE ; Check on REPNE prefix
	jnz	short @RPT_REPNE ; Display it

	test	[ebp].ID_PRES,@PREF_REPE ; Check on REP/REPE prefix
	jz	short @RPT_EXIT ; None this time

	and	ax,ax		; Check type flag
	jz	short @RPT_REP	; Use REP form

	lea	eax,MSG_REPE	; AX = 'REPE'

	jmp	short @RPT_COM	; Join common code


@RPT_REP:
	lea	eax,MSG_REP	; AX = 'REP'

	jmp	short @RPT_COM	; Join common code


@RPT_REPNE:
	lea	eax,MSG_REPNE	; AX = 'REPNE'
@RPT_COM:
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @RPT_EXIT0 ; Yes, skip all this

	REGSAVE <esi,edi>	; Save for a moment

	mov	edi,[ebp].ID_IOUT ; Get initial offset of output stream
	add	edi,@OFFBYTE	; Skip over byte display area
	dec	edi		; Back up to store point
	dec	edi
	mov	esi,eax 	; Copy to source register

	std			; String ops backwards
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	cld			; String ops forwards

	REGREST <edi,esi>	; Restore
@RPT_EXIT0:
	or	[ebp].ID_FLAG,@FLAG_REP ; Mark as used
@RPT_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@RPT	endp			; End @RPT procedure
	NPPROC	@SRO -- Display Segment Register Override (If Any)
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display segment register override (if any).

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	DISP_SRO	; Display any segment register overrides
	jc	@UNDEF		; Handle as undefined opcode

	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@SRO	endp			; End @SRO procedure
	NPPROC	@SREG -- Display Segment Register
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display segment register

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @SREG_EXIT ; Join common exit code

	and	eax,mask $REG	; Isolate register index
	shr	al,$REG 	; Shift to low-order

	push	esi		; Save for a moment

	lea	esi,SREG[eax*2] ; DS:ESI ==> segment register name
S32	movs	<es:[edi].ELO,ds:[esi].ELO> ; Copy it to output stream

	pop	esi		; Restore
@SREG_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@SREG	endp			; End @SREG procedure
	NPPROC	@OPCODE -- Display Opcode Text
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display opcode text.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	lods	ds:[esi].EDD	; Get offset in DS of text

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @OPCODE_EXIT ; Yes, join common exit cdoe

	push	esi		; Save for a moment
	mov	esi,eax 	; Copy to source register
	mov	ecx,edi 	; Save starting offset
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	call	FILL_OPCODE	; Fill out the opcode text from ECX
	pop	esi		; Restore
@OPCODE_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@OPCODE endp			; End @OPCODE procedure
	NPPROC	@OPCODEJCC -- Display Opcode Text For JCC
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display opcode text for JCC and check for Branch Hints.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	lods	ds:[esi].EDD	; Get offset in DS of text

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @OPCODEJCC_EXIT ; Yes, join common exit cdoe

	push	esi		; Save for a moment
	mov	esi,eax 	; Copy to source register
	mov	ecx,edi 	; Save starting offset
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

	test	[ebp].ID_PRES,@PREF_CS ; Izit present?
	jz	short @F	; Jump if not

	mov	al,'-'          ; Mark as branch NOT predicted
	stos	es:[edi].LO	; Save in output stream
@@:
	test	[ebp].ID_PRES,@PREF_DS ; Izit present?
	jz	short @F	; Jump if not

	mov	al,'+'          ; Mark as branch predicted
	stos	es:[edi].LO	; Save in output stream
@@:
	call	FILL_OPCODE	; Fill out the opcode text from ECX
	pop	esi		; Restore
@OPCODEJCC_EXIT:

; Check for Branch Hint prefixes

	test	[ebp].ID_PRES,@PREF_CS ; Izit present?
	jz	short @F	; Jump if not

	or	[ebp].ID_FLAG,@FLAG_SREG ; Mark as used
@@:
	test	[ebp].ID_PRES,@PREF_DS ; Izit present?
	jz	short @F	; Jump if not

	or	[ebp].ID_FLAG,@FLAG_SREG ; Mark as used
@@:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@OPCODEJCC endp 		; End @OPCODEJCC procedure
	NPPROC	@INT03 -- Debugging
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Action for debugging.

On entry:

DS:ESI	==>	action stream

On exit:

DS:ESI	==>	action stream, updated
EAX	=	destroyed

|

	int	03h		; Call our debugger
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@INT03	endp			; End @INT03 procedure
	NPPROC	@IFOSP -- If OSP Present
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Action if OSP is present.

On entry:

DS:ESI	==>	action stream

On exit:

DS:ESI	==>	action stream, updated
EAX	=	destroyed

|

	lods	ds:[esi].EDD	; Get skip amount

	test	[ebp].ID_PRES,@PREF_OSP ; Izit present?
	jz	short @F	; Jump if not

	or	[ebp].ID_FLAG,@FLAG_OSP ; Mark as used
@@:
	test	[ebp].ID_PDEF,@PREF_OSP ; Check on default behavior
	jnz	short @IFOSP_EXIT ; Jump if 32-bit registers

	add	esi,eax 	; Skip over IFOSP action
@IFOSP_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@IFOSP	endp			; End @IFOSP procedure
	NPPROC	@IFOSP2 -- If Secondary OSP Present
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Action if secondary OSP is present.

On entry:

DS:ESI	==>	action stream

On exit:

DS:ESI	==>	action stream, updated
EAX	=	destroyed

|

	lods	ds:[esi].EDD	; Get skip amount

	test	[ebp].ID_PRES,@PREF_OSP ; Izit present?
	jz	short @F	; Jump if not

	or	[ebp].ID_FLAG,@FLAG_OSP ; Mark as used
@@:
	test	[ebp].ID_PDEF,@PREF_OSP2 ; Check on default behavior
	jnz	short @IFOSP2_EXIT ; Jump if 32-bit registers

	add	esi,eax 	; Skip over IFOSP action
@IFOSP2_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@IFOSP2 endp			; End @IFOSP2 procedure
	NPPROC	@ELSEOSP -- If OSP Not Present
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Action if OSP is not present.

On entry:

DS:ESI	==>	action stream

On exit:

DS:ESI	==>	action stream, updated
EAX	=	destroyed

|

	lods	ds:[esi].EDD	; Get skip amount

	test	[ebp].ID_PDEF,@PREF_OSP ; Check on default behavior
	jz	short @ELSEOSP_NO ; Jump if 16-bit registers

	add	esi,eax 	; Skip over ELSEOSP action
@ELSEOSP_NO:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@ELSEOSP endp			; End @ELSEOSP procedure
	NPPROC	@ELSEOSP2 -- If Secondary OSP Not Present
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Action if secondary OSP is not present.

On entry:

DS:ESI	==>	action stream

On exit:

DS:ESI	==>	action stream, updated
EAX	=	destroyed

|

	lods	ds:[esi].EDD	; Get skip amount

	test	[ebp].ID_PDEF,@PREF_OSP2 ; Check on default behavior
	jz	short @ELSEOSP2_NO ; Jump if 16-bit registers

	add	esi,eax 	; Skip over ELSEOSP action
@ELSEOSP2_NO:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@ELSEOSP2 endp			; End @ELSEOSP2 procedure
	NPPROC	@ENDOSP -- End of OSP Action
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

End of OSP actions

On entry:

DS:ESI	==>	action stream

On exit:

DS:ESI	==>	action stream, updated
EAX	=	destroyed

|

	lods	ds:[esi].EDD	; Get and ignore skip amount
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@ENDOSP endp			; End @ENDOSP procedure
	NPPROC	@IGNOREOSP -- Ignore OSP If Present
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ignore OSP if present

On entry:

DS:ESI	==>	action stream

On exit:

DS:ESI	==>	action stream, updated
EAX	=	destroyed

|

	or	[ebp].ID_FLAG,@FLAG_OSP ; Mark as used

	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@IGNOREOSP endp 		; End @IGNOREOSP procedure
	NPPROC	@IFASP -- If ASP Present
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Action if ASP is present.

On entry:

DS:ESI	==>	action stream

On exit:

DS:ESI	==>	action stream, updated
EAX	=	destroyed

|

	lods	ds:[esi].EDD	; Get skip amount

	test	[ebp].ID_PRES,@PREF_ASP ; Izit present?
	jz	short @F	; Jump if not

	or	[ebp].ID_FLAG,@FLAG_ASP ; Mark as used
@@:
	test	[ebp].ID_PDEF,@PREF_ASP ; Check on default behavior
	jnz	short @IFASP_EXIT ; Jump if 32-bit addressing

	add	esi,eax 	; Skip over IFASP action
@IFASP_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@IFASP	endp			; End @IFASP procedure
	NPPROC	@ELSEASP -- If ASP Not Present
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Action if ASP is not present.

On entry:

DS:ESI	==>	action stream

On exit:

DS:ESI	==>	action stream, updated
EAX	=	destroyed

|

	lods	ds:[esi].EDD	; Get skip amount

	test	[ebp].ID_PDEF,@PREF_ASP ; Check on default behavior
	jz	short @ELSEASP_NO ; Jump if 16-bit addressing

	add	esi,eax 	; Skip over ELSEASP action
@ELSEASP_NO:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@ELSEASP endp			; End @ELSEASP procedure
	NPPROC	@ENDASP -- End of ASP Action
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

End of ASP actions.

On entry:

DS:ESI	==>	action stream

On exit:

DS:ESI	==>	action stream, updated
EAX	=	destroyed

|

	lods	ds:[esi].EDD	; Get and ignore skip amount
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@ENDASP endp			; End @ENDASP procedure
	NPPROC	@IFMOD11 -- If MOD=11 True
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Action if MOD=11 is true.

On entry:

DS:ESI	==>	action stream

On exit:

DS:ESI	==>	action stream, updated
EAX	=	destroyed

|

	lods	ds:[esi].EDD	; Get skip amount

	push	eax		; Save for a moment

	call	GET_MODRM	; Return MOD/RM byte in AL

	and	al,mask $MOD	; Isolate MOD value

	cmp	al,11b shl $MOD ; Izit MOD=11?
	pop	eax		; Restore
	je	short @F	; Jump if so

	add	esi,eax 	; Skip over IFMOD11 action
@@:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@IFMOD11 endp			; End @IFMOD11 procedure
	NPPROC	@ELSEMOD11 -- If MOD=11 False
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Action if MOD=11 is false.

On entry:

DS:ESI	==>	action stream

On exit:

DS:ESI	==>	action stream, updated
EAX	=	destroyed

|

	lods	ds:[esi].EDD	; Get skip amount

	push	eax		; Save for a moment

	call	GET_MODRM	; Return MOD/RM byte in AL

	and	al,mask $MOD	; Isolate MOD value

	cmp	al,11b shl $MOD ; Izit MOD=11?
	pop	eax		; Restore
	jne	short @F	; Jump if not

	add	esi,eax 	; Skip over ELSEMOD11 action
@@:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@ELSEMOD11 endp 		; End @ELSEMOD11 procedure
	NPPROC	@ENDMOD11 -- End of MOD=11 Action
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

End of MOD=11 actions.

On entry:

DS:ESI	==>	action stream

On exit:

DS:ESI	==>	action stream, updated
EAX	=	destroyed

|

	lods	ds:[esi].EDD	; Get and ignore skip amount
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@ENDMOD11 endp			; End @ENDMOD11 procedure
	NPPROC	@BOPCALL -- Windows NT/2000/XP BOP Call
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Windows NT/2000/XP BOP call

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	REGSAVE <ebx,ecx,edx>	; Save for a moment

	mov	bl,0C4h 	; Get 1st opcode
	call	GET_MODRM	; Return MOD/RM byte in AL
	mov	bh,al		; Save 2nd opcode

	call	GET_IWORD	; AX = next instruction word
				; AL = 3rd opcode
				; AH = 4th opcode (if any)
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	near ptr @BOPCALL_EXIT ; Yes, join common exit cdoe

	cmp	bh,0C4h 	; Izit 2nd byte of BOP manager call?
	jne	short @BOPCALL_DB  ; Jump if not (display as DBs)

	cmp	al,BOP_UNSIMULATE ; Izit one-byte tail?
	je	short @F	; Jump if so

	cmp	al,BOP_UNK2	; Izit another one-byte tail?
	jne	short @BOPCALL1 ; Jump if not
@@:
	mov	ah,0		; Zero the high-order byte
	dec	[ebp].ID_CINS	; Back up one instruction byte
@BOPCALL1:

; Lookup AX in the table of BOP instructions

	REGSAVE <edi,es>	; Save for a moment

	push	ds		; Get DGROUP data segment
	pop	es		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	lea	edi,BOPFNS	; ES:EDI ==> table of BOP functions
	mov	ecx,@BOPFNS	; Get # BOP functions
  repne scas	BOPFNS[edi]	; Search for it
	mov	edx,edi 	; Copy offset
	REGREST <es,edi>	; Restore
	assume	es:nothing	; Tell the assembler about it
	jne	short @BOPCALL_DB  ; Jump if not found (display as DBs)

; Display the text

	push	esi		; Save for a moment
	sub	edx,offset DGROUP:BOPFNS[type BOPFNS] ; Convert to origin-0
	shr	edx,1-0 	; Convert from bytes to words
	mov	esi,BOPTXT[edx * (type BOPTXT)] ; Get offset in DGROUP of text
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	pop	esi		; Restore

	jmp	short @BOPCALL_EXIT ; Join common exit code


; Display the bytes (BL, BH, AL, and possibly AH) as a DB statement

@BOPCALL_DB:
	push	esi		; Save for a moment
	lea	esi,TXT_UNDEF	; DS:ESI ==> text to display
	mov	ecx,edi 	; Save starting offset
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	call	FILL_OPCODE	; Fill out the opcode text from ECX

	push	eax		; Save for a moment

	mov	al,bl		; Get 1st opcode
	call	DB2HEX		; Convert AL to hex at ES:EDI

	lea	esi,TXT_COMSP	; DS:ESI ==> ', '
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

	mov	al,bh		; Get 2nd opcode
	call	DB2HEX		; Convert AL to hex at ES:EDI

	pop	eax		; Restore

	lea	esi,TXT_COMSP	; DS:ESI ==> ', '
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

;;;;;;; mov	al,al		; Get 3rd opcode
	call	DB2HEX		; Convert AL to hex at ES:EDI

	cmp	al,BOP_UNSIMULATE ; Izit one-byte tail?
	je	short @F	; Jump if so

	cmp	al,BOP_UNK2	; Izit another one-byte tail?
	je	short @F	; Jump if so

	lea	esi,TXT_COMSP	; DS:ESI ==> ', '
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

	mov	al,ah		; Get 4th opcode
	call	DB2HEX		; Convert AL to hex at ES:EDI
@@:
	pop	esi		; Restore
@BOPCALL_EXIT:
	REGREST <edx,ecx,ebx>	; Restore

	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@BOPCALL endp			; End @BOPCALL procedure
	NPPROC	@PTR16@16 -- Display PTR16:16
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display PTR16:16

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	push	ebx		; Save register

	call	GET_IWORD	; AX = next instruction word
	movzx	eax,ax		; Zero to use as dword
	mov	EA1OFF,eax	; Save for later use

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

	call	GET_IWORD	; AX = next instruction word
	mov	EA1TSEL,ax	; Save for later use

	jmp	short @PTR16@16_EXIT ; Join common exit code


@@:
	movzx	eax,ax		; Clear high order word
	push	eax		; Save for a moment

	call	GET_IWORD	; AX = next instruction word
	mov	bx,ax		; Save segment/selector

ifndef INT1_DEF
	call	GET_PTRBASE	; Get selector base for ptr in AX
	jc	short @F	; Skip if invalid selector

	add	eax,[esp].EDD	; Plus offset to get linear address
	call	CHECK_SYM	; Is there a symbol with the same linear addr?
@@:
	pop	eax		; Get eax back from stack
	jnc	short @PTR16@16_EXIT ; Jump if there's a symbol match
else
	pop	eax		; Restore offset
endif	; INT1_DEF
	xchg	ax,bx		; Restore AX = segment/selector
				; ...	  BX = offset
	call	DW2HEX		; Convert AX to hex at ES:EDI

	mov	al,'|'          ; Separator for PM

	test	[ebp].ID_FLAG,@FLAG_PM ; Izit Protected Mode?
	jnz	short @F	; Jump if so

	mov	al,':'          ; Separator for RM
@@:
S32	stos	es:[edi].LO	; Save in output stream

	mov	ax,bx		; Get saved offset
	call	DW2HEX		; Convert AX to hex at ES:EDI
@PTR16@16_EXIT:
	pop	ebx		; Restore

	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@PTR16@16 endp			; End @PTR16@16 procedure
	NPPROC	@PTR16@32 -- Display PTR16:32
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display PTR16:32

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	push	ebx		; Save

	call	GET_IDWORD	; EAX = next instruction dword
	mov	EA1OFF,eax	; Save for later use

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

	call	GET_IWORD	; AX = next instruction word
	mov	EA1TSEL,ax	; Save for later use

	jmp	short @PTR16@32_EXIT ; Join common exit code


@@:
	push	eax		; Save for a moment

	call	GET_IWORD	; AX = next instruction word
	mov	bx,ax		; Save segment/selector

ifndef INT1_DEF
	call	GET_PTRBASE	; Return EAX = base of segment/selector
	jc	short @F	; Skip if invalid selector

	add	eax,[esp].EDD	; Plus offset to get linear address
	call	CHECK_SYM	; Is there a symbol with the same linear addr?
@@:
	pop	eax		; Get eax back from stack
	jnc	short @PTR16@32_EXIT ; Jump if there's a symbol match
else
	pop	eax		; Restore offset
endif	; INT1_DEF
	xchg	eax,ebx 	; Restore AX = segment/selector
				; ...	  EBX = offset
	call	DW2HEX		; Convert AX to hex at ES:EDI

	mov	al,'|'          ; Separator for PM

	test	[ebp].ID_FLAG,@FLAG_PM ; Izit Protected Mode?
	jnz	short @F	; Jump if so

	mov	al,':'          ; Separator for RM
@@:
S32	stos	es:[edi].LO	; Save in output stream

	mov	eax,ebx 	; Get saved offset
	call	DD2HEX		; Convert EAX to hex at ES:EDI
@PTR16@32_EXIT:
	pop	ebx		; Restore

	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@PTR16@32 endp			; End @PTR16@32 procedure
	NPPROC	@R8 -- Display Byte Register Name
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display byte register name.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @R8_EXIT	; Yes, skip all this

	and	eax,mask $REG	; Isolate register operand
	shr	al,$REG 	; Shift to low-order

	push	esi		; Save for a moment

	lea	esi,REG8[eax*2] ; DS:ESI ==> register name
S32	movs	<es:[edi].ELO,ds:[esi].ELO> ; Copy two-byte register name

	pop	esi		; Restore
@R8_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@R8	endp			; End @R8 procedure
	NPPROC	@R16 -- Display Word Register Name
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display word register name.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @R16_EXIT ; Yes, skip all this

	and	eax,mask $REG	; Isolate register operand
	shr	al,$REG 	; Shift to low-order

	push	esi		; Save for a moment

	lea	esi,REG16[eax*2] ; DS:ESI ==> register name
S32	movs	<es:[edi].ELO,ds:[esi].ELO> ; Copy two-byte register name

	pop	esi		; Restore
@R16_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@R16	endp			; End @R16 procedure
	NPPROC	@R32 -- Display Dword Register Name
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display dword register name.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far
	or	[ebp].ID_FLAG,@FLAG_OSP ; Mark as used

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @R32_EXIT ; Yes, skip all this

	and	eax,mask $REG	; Isolate register operand
	shr	al,$REG 	; Shift to low-order

	push	esi		; Save for a moment

	lea	esi,REG16[eax*2] ; DS:ESI ==> register name
	mov	al,'E'          ; Prefix
S32	stos	es:[edi].LO	; Save in output stream
S32	movs	<es:[edi].ELO,DGROUP:[esi].ELO> ; Copy two-byte register name

	pop	esi		; Restore
@R32_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@R32	endp			; End @R32 procedure
	NPPROC	@CR32 -- Display Control Register Name
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display control register name.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @CR32_EXIT ; Yes, skip all this

	and	al,mask $REG	; Isolate register operand
	shr	al,$REG 	; Shift to low-order
	add	al,'0'          ; Convert to ASCII

	push	eax		; Save for a moment

	mov	ax,'RC'         ; Prefix
S32	stos	es:[edi].ELO	; Save in output stream

	pop	eax		; Restore

S32	stos	es:[edi].LO	; Save in output stream
@CR32_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@CR32	endp			; End @CR32 procedure
	NPPROC	@DR32 -- Display Debug Register Name
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display debug register name.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @DR32_EXIT ; Yes, skip all this

	and	al,mask $REG	; Isolate register operand
	shr	al,$REG 	; Shift to low-order
	add	al,'0'          ; Convert to ASCII

	push	eax		; Save for a moment

	mov	ax,'RD'         ; Prefix
S32	stos	es:[edi].ELO	; Save in output stream

	pop	eax		; Restore

S32	stos	es:[edi].LO	; Save in output stream
@DR32_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@DR32	endp			; End @DR32 procedure
	NPPROC	@TR32 -- Display Test Register Name
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display test register name.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @TR32_EXIT ; Yes, skip all this

	and	al,mask $REG	; Isolate register operand
	shr	al,$REG 	; Shift to low-order
	add	al,'0'          ; Convert to ASCII

	push	eax		; Save for a moment

	mov	ax,'RT'         ; Prefix
S32	stos	es:[edi].ELO	; Save in output stream

	pop	eax		; Restore

S32	stos	es:[edi].LO	; Save in output stream
@TR32_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@TR32	endp			; End @TR32 procedure
if 0 ; =========================================================================
	NPPROC	@SR32 -- Display Special Register Name
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display special register name.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far
	or	[ebp].ID_FLAG,@FLAG_OSP ; Mark as used

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @SR32_EXIT ; Yes, skip all this

	and	eax,mask $RM	; Isolate R/M operand
	shr	al,$RM		; Shift to low-order

	push	esi		; Save for a moment

	lea	esi,REG16[eax*2] ; DS:ESI ==> register name
	mov	al,'E'          ; Prefix
S32	stos	es:[edi].LO	; Save in output stream
S32	movs	<es:[edi].ELO,DGROUP:[esi].ELO> ; Copy two-byte register name

	pop	esi		; Restore
@SR32_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@SR32	endp			; End @SR32 procedure
endif ; ========================================================================
	NPPROC	@IMM8 -- Display Byte Immediate
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display byte immediate.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	call	GET_IBYTE	; AL = next instruction byte

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @IMM8_OPER ; Jump if so

	call	DB2HEX		; Convert AL to hex at ES:EDI

	jmp	short @IMM8_EXIT ; Join common exit code


@IMM8_OPER:
	movzx	eax,al		; Zero extend to high-order bytes
	mov	es:[edi].OPER1_IMM,eax ; Save as immediate value
@IMM8_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@IMM8	endp			; End @IMM8 procedure
	NPPROC	@IMM8D -- Display Sign-extended Byte-to-Dword Immediate
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display sign-extended byte-to-dword immediate.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

;;;;;;; call	DISP_COMMA	; Display comma separator if appropriate

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	call	GET_IBYTE	; AL = next instruction byte

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @IMM8D_OPER ; Jump if so

	push	esi		; Save for a moment
	lea	esi,MSG_DPTR	; DS:ESI ==> 'Dword ptr '
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	pop	esi		; Restore

	call	DISP_SIGN	; Display and check for sign extension of AL
	call	DB2HEX		; Convert AL to hex at ES:EDI

	jmp	short @IMM8D_EXIT ; Join common exit code


@IMM8D_OPER:
	movsx	eax,al		; Sign extend to high-order bytes
	mov	es:[edi].OPER1_IMM,eax ; Save as immediate value
@IMM8D_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@IMM8D	endp			; End @IMM8D procedure
	NPPROC	@IMM8W -- Display Sign-extended Byte-to-Word Immediate
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display sign-extended byte-to-word immediate.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	call	GET_IBYTE	; AL = next instruction byte

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @IMM8W_OPER ; Jump if so

	call	DISP_SIGN	; Display and check for sign extension of AL
	call	DB2HEX		; Convert AL to hex at ES:EDI

	jmp	short @IMM8W_EXIT ; Join common exit code


@IMM8W_OPER:
	movsx	eax,ax		; Sign extend to high-order word
	mov	es:[edi].OPER1_IMM,eax ; Save as immediate value
@IMM8W_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@IMM8W	endp			; End @IMM8W procedure
	NPPROC	@IMM16 -- Display Word Immediate
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display word immediate.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	call	GET_IWORD	; AX = next instruction word

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @IMM16_OPER ; Jump if so

	call	DW2HEX		; Convert AX to hex at ES:EDI

	jmp	short @IMM16_EXIT ; Join common exit code


@IMM16_OPER:
	movzx	eax,ax		; Zero extend to high-order word
	mov	es:[edi].OPER1_IMM,eax ; Save as immediate value
@IMM16_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@IMM16	endp			; End @IMM16 procedure
	NPPROC	@IMM32 -- Display Dword Immediate
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display dword immediate.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	call	GET_IDWORD	; EAX = next instruction dword

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @IMM32_OPER ; Jump if so

	call	DD2HEX		; Convert EAX to hex at ES:EDI

	jmp	short @IMM32_EXIT ; Join common exit code


@IMM32_OPER:
	mov	es:[edi].OPER1_IMM,eax ; Save as immediate value
@IMM32_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@IMM32	endp			; End @IMM32 procedure
	NPPROC	@DSP16 -- Display Word Displacement
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display word displacement.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	call	GET_IWORD	; AX = next instruction word

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

	mov	es:[edi].OPER1_DISP.ELO,ax ; Save as displacement
	or	es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_DSP ; Mark as present

	call	DDW_COM 	; Call common displacement data width code

	jmp	short @DSP16_EXIT ; Join common exit code


@@:
ifndef INT1_DEF
	movzx	eax,ax		; Clear high order word
	push	eax		; Save it
	call	GET_OPSELBASE	; Get operand selector base in EAX
				; (Ignore CF=1 indicating error)

	add	eax,[esp].EDD	; Plus offset to get linear address

	call	CHECK_SYM	; Convert to symbol at ES:EDI if in hash table
	pop	eax		; Restore displacement
	jnc	short @F	; Symbol found; don't display in hex
endif	; INT1_DEF

	call	DW2HEX		; Convert AX to hex at ES:EDI
@@:
	lods	ds:[esi].EDD	; Remove data width code
@DSP16_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@DSP16	endp			; End @DSP16 procedure
	NPPROC	@DSP32 -- Display Dword Displacement
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display dword displacement.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	call	GET_IDWORD	; EAX = next instruction dword

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

	mov	es:[edi].OPER1_DISP,eax ; Save as displacement
	or	es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_DSP ; Mark as present

	call	DDW_COM 	; Call common displacement data width code

	jmp	short @DSP32_EXIT ; Join common exit code


@@:
ifndef INT1_DEF
	push	eax		; Save it
	call	GET_OPSELBASE	; Get operand selector base in EAX
				; (Ignore CF=1 indicating error)

	add	eax,[esp].EDD	; Add displacement to get linear address
	call	CHECK_SYM	; Convert to symbol at ES:EDI if in hash table
	pop	eax		; Restore displacement
	jnc	short @F	; Symbol found; don't display in hex
endif	; INT1_DEF
	call	DD2HEX		; Convert EAX to hex at ES:EDI
@@:
	lods	ds:[esi].EDD	; Remove data width code
@DSP32_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@DSP32	endp			; End @DSP32 procedure
	NPPROC	DDW_COM -- Displacement Data Width
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common displacement data width code.

|

	lods	ds:[esi].EDD	; Get data width code (0 = OSP, 1 = byte)

	test	es:[edi].OPER1_FLAG,@OPER_DWID ; Previous data width specified?
	jnz	short DDW_COM_EXIT ; Yes, skip all this

	and	ax,ax		; Check the value
	jz	short @F	; Jump if it's dependent on OSP

	or	es:[edi].OPER1_DWID,@DWIDTH_BYTE ; Mark as one-byte data
	or	es:[edi].OPER1_FLAG,@OPER_DWID ; Mark as specified

	jmp	short DDW_COM_EXIT ; Join common exit code


@@:
	test	[ebp].ID_PDEF,@PREF_OSP ; Check on default behavior
	jnz	short @F	; Jump if four-byte data

	or	es:[edi].OPER1_DWID,@DWIDTH_WORD ; Mark as two-byte data
	or	es:[edi].OPER1_FLAG,@OPER_DWID ; Mark as specified

	jmp	short DDW_COM_EXIT ; Join common exit code


@@:
	or	es:[edi].OPER1_DWID,@DWIDTH_DWORD ; Mark as four-byte data
	or	es:[edi].OPER1_FLAG,@OPER_DWID ; Mark as specified
DDW_COM_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DDW_COM endp			; End DDW_COM procedure
	NPPROC	@RM8 -- Display RM Byte
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display RM byte.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	DISP_SRO	; Display any segment register overrides
	jc	@UNDEF		; Handle as undefined opcode

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	test	al,mask $MOD	; Check MOD bits
	jz	short @RM8_ADDR ; Jump if MOD=00
	jpo	short @RM8_ADDR ; Jump if MOD=01 or 10

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @RM8_EXIT ; Yes, skip all this

	and	eax,mask $RM	; Isolate RM operand
	shr	al,$RM		; Shift to low-order

	push	esi		; Save for a moment

	lea	esi,REG8[eax*2] ; DS:ESI ==> register name
S32	movs	<es:[edi].ELO,ds:[esi].ELO> ; Copy two-byte register name

	pop	esi		; Restore
@RM8_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action


@RM8_ADDR:
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

	test	es:[edi].OPER1_FLAG,@OPER_DWID ; Any previous widths?
	jnz	short @F	; Yes, don't override

; Mark as one-byte memory reference

	or	es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_DWID
	or	es:[edi].OPER1_DWID,@DWIDTH_BYTE
@@:
	jmp	RM_ADDR 	; Jump to common routine w/AL = MOD/RM byte

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@RM8	endp			; End @RM8 procedure
	NPPROC	@RM16 -- Display RM Word
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display RM word.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	DISP_SRO	; Display any segment register overrides
	jc	@UNDEF		; Handle as undefined opcode

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	test	al,mask $MOD	; Check MOD bits
	jz	short @RM16_ADDR ; Jump if MOD=00
	jpo	short @RM16_ADDR ; Jump if MOD=01 or 10

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @RM16_EXIT ; Yes, skip all this

	and	eax,mask $RM	; Isolate RM operand
	shr	al,$RM		; Shift to low-order

	push	esi		; Save for a moment

	lea	esi,REG16[eax*2] ; DS:ESI ==> register name
S32	movs	<es:[edi].ELO,ds:[esi].ELO> ; Copy two-byte register name

	pop	esi		; Restore
@RM16_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action


@RM16_ADDR:
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

	test	es:[edi].OPER1_FLAG,@OPER_DWID ; Any previous widths?
	jnz	short @F	; Yes, don't override

; Mark as two-byte memory reference

	or	es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_DWID
	or	es:[edi].OPER1_DWID,@DWIDTH_WORD
@@:
	jmp	RM_ADDR 	; Jump to common routine w/AL = MOD/RM byte

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@RM16	endp			; End @RM16 procedure
	NPPROC	@RM32 -- Display RM Dword
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display RM dword.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	DISP_SRO	; Display any segment register overrides
	jc	@UNDEF		; Handle as undefined opcode

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	test	al,mask $MOD	; Check MOD bits
	jz	short @RM32_ADDR ; Jump if MOD=00
	jpo	short @RM32_ADDR ; Jump if MOD=01 or 10

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @RM32_EXIT ; Yes, skip all this

	and	eax,mask $RM	; Isolate RM operand
	shr	al,$RM		; Shift to low-order

	push	esi		; Save for a moment

	lea	esi,REG16[eax*2] ; DS:ESI ==> register name
	mov	al,'E'          ; Prefix
S32	stos	es:[edi].LO	; Save in output stream
S32	movs	<es:[edi].ELO,DGROUP:[esi].ELO> ; Copy two-byte register name

	pop	esi		; Restore
@RM32_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action


@RM32_ADDR:
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

	test	es:[edi].OPER1_FLAG,@OPER_DWID ; Any previous widths?
	jnz	short @F	; Yes, don't override

; Mark as four-byte memory reference

	or	es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_DWID
	or	es:[edi].OPER1_DWID,@DWIDTH_DWORD
@@:
	jmp	RM_ADDR 	; Jump to common routine w/AL = MOD/RM byte

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@RM32	endp			; End @RM32 procedure
	NPPROC	@R32M16 -- Display RM Dword/Word
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display RM dword/word.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	DISP_SRO	; Display any segment register overrides
	jc	@UNDEF		; Handle as undefined opcode

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	test	al,mask $MOD	; Check MOD bits
	jz	short @R32M16_ADDR ; Jump if MOD=00
	jpo	short @R32M16_ADDR ; Jump if MOD=01 or 10

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @R32M16_EXIT ; Yes, skip all this

	and	eax,mask $RM	; Isolate RM operand
	shr	al,$RM		; Shift to low-order

	push	esi		; Save for a moment

	lea	esi,REG16[eax*2] ; DS:ESI ==> register name
	mov	al,'E'          ; Prefix
S32	stos	es:[edi].LO	; Save in output stream
S32	movs	<es:[edi].ELO,DGROUP:[esi].ELO> ; Copy two-byte register name

	pop	esi		; Restore
@R32M16_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action


@R32M16_ADDR:
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

	test	es:[edi].OPER1_FLAG,@OPER_DWID ; Any previous widths?
	jnz	short @F	; Yes, don't override

; Mark as two-byte memory reference

	or	es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_DWID
	or	es:[edi].OPER1_DWID,@DWIDTH_WORD
@@:
	jmp	RM_ADDR 	; Jump to common routine w/AL = MOD/RM byte

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@R32M16 endp			; End @R32M16 procedure
	NPPROC	@RM64 -- Display RM Qword
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display RM qword.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	DISP_SRO	; Display any segment register overrides
	jc	@UNDEF		; Handle as undefined opcode

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	test	al,mask $MOD	; Check MOD bits
	jz	short @RM64_ADDR ; Jump if MOD=00
	jpo	short @RM64_ADDR ; Jump if MOD=01 or 10

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @RM64_EXIT ; Yes, skip all this

	and	eax,mask $RM	; Isolate RM operand
	shr	al,$RM		; Shift to low-order

	push	esi		; Save for a moment

	lea	esi,REG16[eax*2] ; DS:ESI ==> register name
	mov	al,'E'          ; Prefix
S32	stos	es:[edi].LO	; Save in output stream
S32	movs	<es:[edi].ELO,DGROUP:[esi].ELO> ; Copy two-byte register name

	pop	esi		; Restore
@RM64_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action


@RM64_ADDR:
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

	test	es:[edi].OPER1_FLAG,@OPER_DWID ; Any previous widths?
	jnz	short @F	; Yes, don't override

; Mark as eight-byte memory reference

	or	es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_DWID
	or	es:[edi].OPER1_DWID,@DWIDTH_QWORD
@@:
	jmp	RM_ADDR 	; Jump to common routine w/AL = MOD/RM byte

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@RM64	endp			; End @RM64 procedure
	NPPROC	@RM8P -- Display RM Byte With Pointer
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display RM byte with pointer.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	test	al,mask $MOD	; Check MOD bits
	jz	short @RM8P_ADDR ; Jump if MOD=00
	jpo	short @RM8P_ADDR ; Jump if MOD=01 or 10

	call	DISP_SRO	; Display any segment register overrides
	jc	@UNDEF		; Handle as undefined opcode

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @RM8P_EXIT ; Yes, skip all this

	and	eax,mask $RM	; Isolate RM operand
	shr	al,$RM		; Shift to low-order

	push	esi		; Save for a moment

	lea	esi,REG8[eax*2] ; DS:ESI ==> register name
S32	movs	<es:[edi].ELO,ds:[esi].ELO> ; Copy two-byte register name

	pop	esi		; Restore
@RM8P_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action


@RM8P_ADDR:
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

	test	es:[edi].OPER1_FLAG,@OPER_DWID ; Any previous widths?
	jnz	short @RM8P_SRO ; Yes, don't override

; Mark as one-byte memory reference

	or	es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_DWID
	or	es:[edi].OPER1_DWID,@DWIDTH_BYTE

	jmp	short @RM8P_SRO ; Join common code


@@:
	test	[ebp].ID_FLAG,@FLAG_PTR ; Already filled in?
	jnz	short @RM8P_SRO ; Yes, no need to do it again

	push	esi		; Save for a moment
	lea	esi,MSG_BPTR	; DS:ESI ==> 'BYTE PTR '
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	pop	esi		; Restore

	or	[ebp].ID_FLAG,@FLAG_PTR ; Mark as filled in
@RM8P_SRO:
	call	DISP_SRO	; Display any segment register overrides
	jc	@UNDEF		; Handle as undefined opcode

	jmp	RM_ADDR 	; Jump to common routine w/AL = MOD/RM byte

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@RM8P	endp			; End @RM8P procedure
	NPPROC	@RM16P -- Display RM Word With Pointer
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display RM word with pointer.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	test	al,mask $MOD	; Check MOD bits
	jz	short @RM16P_ADDR ; Jump if MOD=00
	jpo	short @RM16P_ADDR ; Jump if MOD=01 or 10

	call	DISP_SRO	; Display any segment register overrides
	jc	@UNDEF		; Handle as undefined opcode

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @RM16P_EXIT ; Yes, join common exit code

	and	eax,mask $RM	; Isolate RM operand
	shr	al,$RM		; Shift to low-order

	push	esi		; Save for a moment

	lea	esi,REG16[eax*2] ; DS:ESI ==> register name
S32	movs	<es:[edi].ELO,ds:[esi].ELO> ; Copy two-byte register name

	pop	esi		; Restore
@RM16P_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action


@RM16P_ADDR:
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

	test	es:[edi].OPER1_FLAG,@OPER_DWID ; Any previous widths?
	jnz	short @RM16P_SRO ; Yes, don't override

; Mark as two-byte memory reference

	or	es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_DWID
	or	es:[edi].OPER1_DWID,@DWIDTH_WORD

	jmp	short @RM16P_SRO ; Join common code


@@:
	test	[ebp].ID_FLAG,@FLAG_PTR ; Already filled in?
	jnz	short @RM16P_SRO ; Yes, no need to do it again

	push	esi		; Save for a moment
	lea	esi,MSG_WPTR	; DS:ESI ==> 'WORD PTR '
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	pop	esi		; Restore

	or	[ebp].ID_FLAG,@FLAG_PTR ; Mark as filled in
@RM16P_SRO:
	call	DISP_SRO	; Display any segment register overrides
	jc	@UNDEF		; Handle as undefined opcode

	jmp	RM_ADDR 	; Jump to common routine w/AL = MOD/RM byte

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@RM16P	endp			; End @RM16P procedure
	NPPROC	@RM32P -- Display RM Dword With Pointer
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display RM dword with pointer.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	test	al,mask $MOD	; Check MOD bits
	jz	short @RM32P_ADDR ; Jump if MOD=00
	jpo	short @RM32P_ADDR ; Jump if MOD=01 or 10

	call	DISP_SRO	; Display any segment register overrides
	jc	@UNDEF		; Handle as undefined opcode

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @RM32P_EXIT ; yes, join common exit code

	and	eax,mask $RM	; Isolate RM operand
	shr	al,$RM		; Shift to low-order

	push	esi		; Save for a moment

	lea	esi,REG16[eax*2] ; DS:ESI ==> register name
	mov	al,'E'          ; Prefix
S32	stos	es:[edi].LO	; Save in output stream
S32	movs	<es:[edi].ELO,DGROUP:[esi].ELO> ; Copy two-byte register name

	pop	esi		; Restore
@RM32P_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action


@RM32P_ADDR:
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

	test	es:[edi].OPER1_FLAG,@OPER_DWID ; Any previous widths?
	jnz	short @RM32P_SRO ; Yes, don't override

; Mark as four-byte memory reference

	or	es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_DWID
	or	es:[edi].OPER1_DWID,@DWIDTH_DWORD

	jmp	short @RM32P_SRO ; Join common code


@@:
	test	[ebp].ID_FLAG,@FLAG_PTR ; Already filled in?
	jnz	short @RM32P_SRO ; Yes, no need to do it again

	push	esi		; Save for a moment
	lea	esi,MSG_DPTR	; DS:ESI ==> 'Dword ptr '
	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	pop	esi		; Restore

	or	[ebp].ID_FLAG,@FLAG_PTR ; Mark as filled in
@RM32P_SRO:
	call	DISP_SRO	; Display any segment register overrides
	jc	@UNDEF		; Handle as undefined opcode

	jmp	RM_ADDR 	; Jump to common routine w/AL = MOD/RM byte

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@RM32P	endp			; End @RM32P procedure
	NPPROC	@X64 -- Display MMX Register Name
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display MMX register name.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far
	or	[ebp].ID_FLAG,@FLAG_OSP ; Mark as used

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @X64_EXIT ; Yes, skip all this

	and	al,mask $REG	; Isolate register operand
	shr	al,$REG 	; Shift to low-order

	push	eax		; Save for a moment

	mov	ax,'MM'         ; MMx register prefix
S32	stos	es:[edi].ELO	; Save in output stream

	pop	eax		; Restore

	add	al,'0'          ; Convert to ASCII
S32	stos	es:[edi].LO	; Save in output stream
@X64_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@X64	endp			; End @X64 procedure
	NPPROC	@X128 -- Display SSE Register Name
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display SSE register name.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far
	or	[ebp].ID_FLAG,@FLAG_OSP ; Mark as used

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @X128_EXIT ; Yes, skip all this

	and	eax,mask $REG	; Isolate register operand
	shr	al,$REG 	; Shift to low-order
	add	eax,'MMX0'      ; Convert to ASCII
	ror	eax,8		; Rotate to 'nMMX'
S32	stos	es:[edi].EDD	; Save in output stream
@X128_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@X128	endp			; End @X128 procedure
	NPPROC	@XM32 -- Display XM Dword
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display XM Dword.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	DISP_SRO	; Display any segment register overrides
	jc	@UNDEF		; Handle as undefined opcode

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	test	al,mask $MOD	; Check MOD bits
	jz	short @XM32_ADDR ; Jump if MOD=00
	jpo	short @XM32_ADDR ; Jump if MOD=01 or 10

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @XM32_EXIT ; Yes, skip all this

	and	al,mask $RM	; Isolate RM operand
	shr	al,$RM		; Shift to low-order

	push	eax		; Save for a moment

	mov	ax,'MM'         ; MMx register prefix
S32	stos	es:[edi].ELO	; Save in output stream

	pop	eax		; Restore

	add	al,'0'          ; Convert to ASCII
S32	stos	es:[edi].LO	; Save in output stream
@XM32_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action


@XM32_ADDR:
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

	test	es:[edi].OPER1_FLAG,@OPER_DWID ; Any previous widths?
	jnz	short @F	; Yes, don't override

; Mark as four-byte memory reference

	or	es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_DWID
	or	es:[edi].OPER1_DWID,@DWIDTH_DWORD
@@:
	jmp	RM_ADDR 	; Jump to common routine w/AL = MOD/RM byte

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@XM32	endp			; End @XM32 procedure
	NPPROC	@XM64 -- Display XM Qword
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display XM Qword.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	DISP_SRO	; Display any segment register overrides
	jc	@UNDEF		; Handle as undefined opcode

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	test	al,mask $MOD	; Check MOD bits
	jz	short @XM64_ADDR ; Jump if MOD=00
	jpo	short @XM64_ADDR ; Jump if MOD=01 or 10

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @XM64_EXIT ; Yes, skip all this

	and	al,mask $RM	; Isolate RM operand
	shr	al,$RM		; Shift to low-order

	push	eax		; Save for a moment

	mov	ax,'MM'         ; MMx register prefix
S32	stos	es:[edi].ELO	; Save in output stream

	pop	eax		; Restore

	add	al,'0'          ; Convert to ASCII
S32	stos	es:[edi].LO	; Save in output stream
@XM64_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action


@XM64_ADDR:
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

	test	es:[edi].OPER1_FLAG,@OPER_DWID ; Any previous widths?
	jnz	short @F	; Yes, don't override

; Mark as eight-byte memory reference

	or	es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_DWID
	or	es:[edi].OPER1_DWID,@DWIDTH_QWORD
@@:
	jmp	RM_ADDR 	; Jump to common routine w/AL = MOD/RM byte

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@XM64	endp			; End @XM64 procedure
	NPPROC	@XM128 -- Display XM Qword2
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display XM Qword2.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	DISP_COMMA	; Display comma separator if appropriate

	call	DISP_SRO	; Display any segment register overrides
	jc	@UNDEF		; Handle as undefined opcode

	call	GET_MODRM	; Return MOD/RM byte in AL

	inc	[ebp].ID_NCOMP	; One more component displayed so far

	test	al,mask $MOD	; Check MOD bits
	jz	short @XM128_ADDR ; Jump if MOD=00
	jpo	short @XM128_ADDR ; Jump if MOD=01 or 10

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short @XM128_EXIT ; Yes, skip all this

	and	eax,mask $RM	; Isolate RM operand
	shr	al,$RM		; Shift to low-order
	add	eax,'XMM0'      ; Convert to ASCII
	ror	eax,8		; Rotate to 'nXMM'
S32	stos	es:[edi].EDD	; Save in output stream
@XM128_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action


@XM128_ADDR:
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

	test	es:[edi].OPER1_FLAG,@OPER_DWID ; Any previous widths?
	jnz	short @F	; Yes, don't override

; Mark as sixteen-byte memory reference

	or	es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_DWID
;;;;;;; or	es:[edi].OPER1_DWID,@DWIDTH_QWORD2
	or	es:[edi].OPER1_DWID,@DWIDTH_QWORD ; Show only eight bytes
@@:
	jmp	RM_ADDR 	; Jump to common routine w/AL = MOD/RM byte

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@XM128	endp			; End @XM128 procedure
	NPPROC	@ESC0F -- Display Escape Code Instructions
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display escape code instructions

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	call	GET_IBYTE	; AL = next instruction byte

	movzx	esi,al		; Copy to index register
	mov	esi,ESCOD_TAB[esi*(type ESCOD_TAB)] ; DS:ESI ==> action stream

	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@ESC0F	endp			; End @ESC0F procedure
	NPPROC	RM_ADDR -- Common RM Addressing Routine
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common RM addressing routine

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream
AL	=	MOD/RM byte (MOD .ne. 11)

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	or	[ebp].ID_FLAG,@FLAG_ASP ; Mark as used

	test	[ebp].ID_PDEF,@PREF_ASP ; Check on default behavior
	jnz	near ptr RMASP	; Jump if 32-bit addressing

	test	al,mask $MOD	; Check MOD bits
	jz	near ptr RM00	; Jump if MOD=00

	test	al,1 shl $MOD	; Test low-order bit
	jnz	short RM01	; Jump if MOD=01
				; Fall through if MOD=10
;;;RM10:
	and	eax,mask $RM	; Isolate RM operand
	shr	al,$RM		; Shift to low-order

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short RM10_XOPER ; Not this time

	call	DEFSEG		; Check for default segment register

	call	GET_IWORD	; AX = next instruction word
	mov	es:[edi].OPER1_DISP.ELO,ax ; Save as displacement
	or	es:[edi].OPER1_FLAG,@OPER_DSP ; Mark as present

	jmp	RM_EXIT 	; Join common exit code


RM10_XOPER:
	push	esi		; Save for a moment

	mov	esi,MODRM16[eax*(type MODRM16)] ; DS:ESI ==> text to display

	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

	mov	al,'+'          ; Middle separator
S32	stos	es:[Edi].LO	; Save in output stream

	call	GET_IWORD	; AX = next instruction word
ifndef INT1_DEF
	movzx	eax,ax		; Clear high order word
	push	eax		; Save it
	call	GET_OPSELBASE	; Get operand selector base in EAX
				; (Ignore CF=1 indicating error)

	add	eax,[esp].EDD	; Add offset to get linear address

	call	CHECK_SYM	; Convert to symbol at ES:EDI if in hash table
	pop	eax		; Restore displacement
	jnc	short @F	; Symbol found; don't display in hex
endif	; INT1_DEF
	call	DW2HEX		; Convert AX to hex at ES:EDI
@@:
	mov	al,']'          ; Right separator
S32	stos	es:[edi].LO	; Save in output stream

	pop	esi		; Restore

	jmp	RM_EXIT 	; Join common exit code


RM01:
	and	eax,mask $RM	; Isolate RM operand
	shr	al,$RM		; Shift to low-order

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short RM01_XOPER ; Not this time

	call	DEFSEG		; Check for default segment register

	call	GET_IBYTE	; AL = next instruction byte
	cbw			; Sign-extend AL to AX
	mov	es:[edi].OPER1_DISP.ELO,ax ; Save as displacement
	or	es:[edi].OPER1_FLAG,@OPER_DSP ; Mark as present

	jmp	RM_EXIT 	; Join common exit code


RM01_XOPER:
	push	esi		; Save for a moment

	mov	esi,MODRM16[eax*(type MODRM16)] ; DS:ESI ==> text to display

	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

	call	GET_IBYTE	; AL = next instruction byte
	call	DISP_SIGN	; Display and check for sign extension of AL
	call	DB2HEX		; Convert AL to hex at ES:EDI

	mov	al,']'          ; Right separator
S32	stos	es:[edi].LO	; Save in output stream

	pop	esi		; Restore

	jmp	RM_EXIT 	; Join common exit code


RM00:
	and	eax,mask $RM	; Isolate RM operand
	shr	al,$RM		; Shift to low-order

	cmp	al,110b 	; Check for DISP16
	je	short RM00_DISP16 ; Display it

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short RM00_XOPER ; Not this time

	call	DEFSEG		; Check for default segment register

	jmp	RM_EXIT 	; Join common exit code


RM00_XOPER:
	push	esi		; Save for a moment

	mov	esi,MODRM16[eax*(type MODRM16)] ; DS:ESI ==> text to display

	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

	mov	al,']'          ; Right separator
S32	stos	es:[edi].LO	; Save in output stream

	pop	esi		; Restore

	jmp	RM_EXIT 	; Join common exit code


RM00_DISP16:
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

	call	GET_IWORD	; AX = next instruction word
	mov	es:[edi].OPER1_DISP.ELO,ax ; Save as displacement
	or	es:[edi].OPER1_FLAG,@OPER_DSP ; Mark as present

	jmp	RM_EXIT 	; Join common exit code


@@:
	mov	al,'['          ; Left separator
S32	stos	es:[edi].LO	; Save in output stream

	call	GET_IWORD	; AX = next instruction word
ifndef INT1_DEF
	movzx	eax,ax		; Clear high order word
	push	eax		; Save displacement
	call	GET_OPSELBASE	; Get operand selector base
				; (Ignore CF=1 indicating error)

	add	eax,[esp].EDD	; Add offset to get linear address

	call	CHECK_SYM	; Look for symbol and copy name to ES:EDI
	pop	eax		; Get displacement back
	jnc	short @F	; If found, skip hex display
endif	; INT1_DEF
	call	DW2HEX		; Convert AX to hex at ES:EDI
@@:
	mov	al,']'          ; Right separator
S32	stos	es:[edi].LO	; Save in output stream

	jmp	RM_EXIT 	; Join common exit code


RMASP:
	or	[ebp].ID_FLAG,@FLAG_ASP ; Mark as ASP used

	test	al,mask $MOD	; Check MOD bits
	jz	near ptr RMASP_MOD00 ; Jump if MOD=00

	test	al,@BIT0 shl $MOD ; Test low-order bit
	jnz	near ptr RMASP_MOD01 ; Jump if MOD=01
				; Fall through if MOD=10
;;;RMASP_MOD10:
	and	eax,mask $RM	; Isolate RM operand
	shr	al,$RM		; Shift to low-order

	cmp	al,100b 	; Check for SIB
	jne	short RMASP_MOD10_DISP ; Not this time

	call	DISP_SIB	; Display the SIB

	jmp	short RMASP_MOD10_DISP32 ; Join common code


RMASP_MOD10_DISP:
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

; Check for default SS segment with ASP, MOD=10

; Use SS if RM is EBP

	cmp	al,101b 	; Izit [EBP+disp32] ?
	jne	short @F	; Not this time

	test	es:[edi].OPER1_FLAG,@OPER_SEG ; Any previous segment register?
	jnz	short @F	; Yes, don't use SS

	mov	es:[edi].OPER1_SEG,@SEG_SS ; Mark as SS
@@:
	push	esi		; Save for a moment

	mov	esi,MODRM32[eax*(type MODRM32)] ; DS:ESI ==> text to display

	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

	pop	esi		; Restore
RMASP_MOD10_DISP32:
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	near ptr RMASP_MODx0_DISP32_OPER ; Jump if so

	mov	al,'+'          ; Middle separator
S32	stos	es:[edi].LO	; Save in output stream

	call	GET_IDWORD	; EAX = next instruction dword
ifndef INT1_DEF
	push	eax		; Save displacement
	call	GET_OPSELBASE	; Get operand selector base in EAX
				; (Ignore CF=1 indicating error)

	add	eax,[esp].EDD	; Add offset to get linear address
	call	CHECK_SYM	; If symbol found, put name at ES:EDI
	pop	eax		; Get displacement
	jnc	short @F	; If found, don't display in hex
endif	; INT1_DEF
	call	DD2HEX		; Convert EAX to hex at ES:EDI
@@:
	mov	al,']'          ; Right separator
S32	stos	es:[edi].LO	; Save in output stream

	jmp	RM_EXIT 	; Join common exit code


RMASP_MOD01:
	and	eax,mask $RM	; Isolate RM operand
	shr	al,$RM		; Shift to low-order

	cmp	al,100b 	; Check for SIB
	jne	short RMASP_MOD01_DISP ; Not this time

	call	DISP_SIB	; Display the SIB

	jmp	short RMASP_MOD01_DISP8 ; Join common code


RMASP_MOD01_DISP:
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

; Check for default SS segment with ASP, MOD=01

; Use SS if RM is EBP

	cmp	al,101b 	; Izit [EBP+disp8] ?
	jne	short @F	; Not this time

	test	es:[edi].OPER1_FLAG,@OPER_SEG ; Any previous segment register?
	jnz	short @F	; Yes, don't use SS

	mov	es:[edi].OPER1_SEG,@SEG_SS ; Mark as SS
@@:
	push	esi		; Save for a moment

	mov	esi,MODRM32[eax*(type MODRM32)] ; DS:ESI ==> text to display

	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

	pop	esi		; Restore
RMASP_MOD01_DISP8:
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

	call	GET_IBYTE	; AL = next instruction byte
	movsx	eax,al		; Sign-extend AL to EAX
	mov	es:[edi].OPER1_DISP,eax ; Save as displacement
	or	es:[edi].OPER1_FLAG,@OPER_DSP ; Mark as present

	jmp	RM_EXIT 	; Join common exit code


@@:
	call	GET_IBYTE	; AL = next instruction byte
	call	DISP_SIGN	; Display and check for sign extension of AL
	call	DB2HEX		; Convert AL to hex at ES:EDI

	mov	al,']'          ; Right separator
S32	stos	es:[edi].LO	; Save in output stream

	jmp	short RM_EXIT	; Join common exit code


RMASP_MOD00:
	and	eax,mask $RM	; Isolate RM operand
	shr	al,$RM		; Shift to low-order

	cmp	al,101b 	; Check for DISP32
	je	short RMASP_MOD00_DISP32 ; Display it

	cmp	al,100b 	; Check for SIB
	jne	short RMASP_MOD00_DISP ; Not this time

	call	DISP_SIB	; Display the SIB

	jmp	short RMASP_MOD00_DISPSEP ; Join common code


RMASP_MOD00_DISP:
	push	esi		; Save for a moment

	mov	esi,MODRM32[eax*(type MODRM32)] ; DS:ESI ==> text to display

	call	COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

	pop	esi		; Restore
RMASP_MOD00_DISPSEP:
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	short RM_EXIT	; Yes, skip this

	mov	al,']'          ; Right separator
S32	stos	es:[edi].LO	; Save in output stream

	jmp	short RM_EXIT	; Join common exit code


RMASP_MOD00_DISP32:
	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time
RMASP_MODx0_DISP32_OPER:
	call	GET_IDWORD	; EAX = next instruction dword
	mov	es:[edi].OPER1_DISP,eax ; Save as displacement
	or	es:[edi].OPER1_FLAG,@OPER_DSP ; Mark as present

	jmp	short RM_EXIT	; Join common exit code


@@:
	mov	al,'['          ; Left separator
S32	stos	es:[edi].LO	; Save in output stream

	call	GET_IDWORD	; EAX = next instruction dword
ifndef INT1_DEF
	push	eax		; Save displacement
	call	GET_OPSELBASE	; Get operand selector base in EAX
				; (Ignore CF=1 indicating error)

	add	eax,[esp].EDD	; Add offset to get linear address
	call	CHECK_SYM	; If symbol found, put name at ES:EDI
	pop	eax		; Get back displacement
	jnc	short @F	; If found, don't display in hex
endif	; INT1_DEF
	call	DD2HEX		; Convert EAX to hex at ES:EDI
@@:
	mov	al,']'          ; Right separator
S32	stos	es:[edi].LO	; Save in output stream
RM_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RM_ADDR endp			; End RM_ADDR procedure
	NPPROC	DEFSEG -- Check For Default Segment Register
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for default segment register.

|

; Use SS if RM is BP+SI

	cmp	al,010b 	; Izit [BP+SI ?
	je	short @F	; Yes, use SS

; Use SS if RM is BP+DI

	cmp	al,011b 	; Izit [BP+DI ?
	je	short @F	; Yes, use SS

; Use SS if RM is BP

	cmp	al,110b 	; Izit [BP ?
	jne	short DEFSEG_EXIT ; Join common exit code
@@:
	test	es:[edi].OPER1_FLAG,@OPER_SEG ; Any previous seg register?
	jnz	short DEFSEG_EXIT ; Yes, join common exit code

	mov	es:[edi].OPER1_SEG,@SEG_SS ; Mark as SS
DEFSEG_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEFSEG	endp			; End DEFSEG procedure
	NPPROC	DISP_SIB -- Display SIB
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the SIB in the form of [Base+Index*Scale+Disp]

On entry:

ES:EDI	==>	output stream

On exit:

ES:EDI	==>	output stream, updated

|

	REGSAVE <eax,ebx,ecx,esi> ; Save registers

	call	GET_MODRM	; Return MOD/RM byte in AL
	mov	bh,al		; Copy MOD/RM byte

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short DISP_SIB_XOPER ; Not this time

	call	GET_IBYTE	; AL = next instruction byte
	mov	es:[edi].OPER1_SIB,al ; Save as SIB
	or	es:[edi].OPER1_FLAG,@OPER_SIB ; Mark as present

	mov	ah,al		; Copy SIB
	and	al,mask $IND	; Isolate the index
	shr	al,$IND 	; Shift to low-order

; Check for default SS segment with SIB index

; Use SS if base is EBP with any scale factor

	cmp	al,101b 	; Izit [EBP*?] ?
	je	short DISP_SIB_SS ; Yes, use SS if alone

	mov	al,ah		; Restore SIB
	and	al,mask $BASE	; Isolate the base
	shr	al,$BASE	; Shift to low-order

; Use SS if index is ESP

	cmp	al,100b 	; Izit ESP ?
	je	short DISP_SIB_SS ; Yes, use SS if alone

; Use SS if index is EBP unless MOD=00 in which case there's no base
; (hence no EBP), but there is a disp32.

	cmp	al,101b 	; Izit special?
	jne	short @F	; No, join common displacement code

	test	bh,mask $MOD	; Check for MOD=00
	jz	short DISP_SIB_DISP32 ; Jump if so
DISP_SIB_SS:
	test	es:[edi].OPER1_FLAG,@OPER_SEG ; Any previous segment register?
	jnz	short @F	; Yes, don't use SS

	mov	es:[edi].OPER1_SEG,@SEG_SS ; Mark as SS
@@:

; If MOD=00, none
; If MOD=01, disp8,  but handled elsewhere
; If MOD=10, disp32, but handled elsewhere
; If MOD=11, none

	jmp	short DISP_SIB_EXIT ; Join common exit code


DISP_SIB_DISP32:
	call	GET_IDWORD	; EAX = next instruction dword
	mov	es:[edi].OPER1_DISP,eax ; Save as displacement
	or	es:[edi].OPER1_FLAG,@OPER_DSP ; Mark as present

	jmp	short DISP_SIB_EXIT ; Join common exit code


DISP_SIB_XOPER:
	call	GET_IBYTE	; AL = next instruction byte
	mov	bl,al		; BH = MOD R/M byte
				; BL = SIB

	mov	al,'['          ; Left separator
S32	stos	es:[edi].LO	; Save in output stream

	movzx	esi,bl		; Copy SIB
	and	esi,mask $BASE	; Isolate base
	shr	esi,$BASE	; Shift to low-order

; Check for special case of BASE = 101 and MOD = 00.
; If so, there's no BASE, but there is a disp32.

	cmp	esi,101b	; Check for BASE = 101
	jne	short DISP_SIB_BASE ; Not this time

	test	bh,mask $MOD	; Check for MOD = 00
	jnz	short DISP_SIB_BASE ; Not this time

	call	DISP_INDSCAL	; Display INDEX*SCALE (if any)

	call	DISP_PLUS	; Display a plus sign (if appropriate)

	call	GET_IDWORD	; EAX = next instruction dword
ifndef INT1_DEF
	push	eax		; Save displacement
	call	GET_OPSELBASE	; Get operand selector base in EAX
				; (Ignore CF=1 indicating error)

	add	eax,[esp].EDD	; Add offset to get linear address
	call	CHECK_SYM	; If symbol found, put name at ES:EDI
	pop	eax		; Get displacement
	jnc	short @F	; If found, don't display in hex
endif	; INT1_DEF
	call	DD2HEX		; Convert EAX to hex at ES:EDI
@@:
	jmp	short DISP_SIB_EXIT ; Join common exit code


; Display BASE

DISP_SIB_BASE:
	lea	esi,REG16[esi*2] ; DS:ESI ==> register name
	mov	al,'E'          ; Prefix
S32	stos	es:[edi].LO	; Save in output stream
S32	movs	<es:[edi].ELO,DGROUP:[esi].ELO> ; Copy two-byte register name

	call	DISP_INDSCAL	; Display INDEX*SCALE (if any)
DISP_SIB_EXIT:
	REGREST <esi,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_SIB endp			; End DISP_SIB procedure
	NPPROC	DISP_INDSCAL -- Display INDEX * SCALE
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display INDEX * SCALE (if any)

On entry:

BL	=	SIB
ES:EDI	==>	output stream

On exit:

ES:EDI	==>	output stream, updated

|

	REGSAVE <eax,esi>	; Save registers

; Display INDEX * SCALE (if any)

	movzx	esi,bl		; Copy SIB
	and	esi,mask $IND	; Isolate index
	shr	esi,$IND	; Shift to low-order

	cmp	esi,100b	; Check for special case
	je	short DISP_INDSCAL_EXIT ; Jump if nothing further

	call	DISP_PLUS	; Display a plus sign (if appropriate)

	lea	esi,REG16[esi*2] ; DS:ESI ==> register name
	mov	al,'E'          ; Prefix
S32	stos	es:[edi].LO	; Save in output stream
S32	movs	<es:[edi].ELO,DGROUP:[esi].ELO> ; Copy two-byte register name

; Display SCALE (if any)

	movzx	esi,bl		; Copy SIB

	and	esi,mask $SS	; Isolate scale
	jz	short DISP_INDSCAL_EXIT ; No scale to display

	shr	esi,$SS 	; Shift to low-order
	dec	esi		; Shift to origin-1
	lea	esi,SCALE[esi*2] ; DS:ESI ==> scale
S32	movs	<es:[edi].ELO,ds:[esi].ELO> ; Copy scale to output stream
DISP_INDSCAL_EXIT:
	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_INDSCAL endp		; End DISP_INDSCAL procedure
	NPPROC	@MODRM1 -- Save First Mod R/M Byte
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If operand analysis is in effect, save the following byte (in a dword)
as the first Mod R/M byte.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream or operand data structure

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	lods	ds:[esi].EDD	; Get the following data item

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @MODRM1_EXIT ; Not this time

	mov	es:[edi].OPER1_MODRM,al ; Save as Mod R/M byte

; Determine the default segment from the instruction

	call	GET_LBYTE	; AL = last instruction byte

	and	al,not @BIT0	; Clear the byte vs. word bit

	cmp	al,@OPCOD_INSB	; Check for INSB/W/D
	je	short @MODRM1_ES ; Jump if default is ES

	cmp	al,@OPCOD_STOSB ; Check for STOSB/W/D
	je	short @MODRM1_ES ; Jump if default is ES

	cmp	al,@OPCOD_SCASB ; Check for SCASB/W/D
	jne	short @F	; Jump if default is not ES
@MODRM1_ES:
	mov	es:[edi].OPER1_SEG,@SEG_ES ; Default is ES
@@:

; Determine the data width from the instruction and OSP.
; If the last instruction byte is even, it's byte-wide.
; Otherwise, the width is controlled by the OSP.

	call	GET_LBYTE	; AL = last instruction byte

	test	al,@BIT0	; Check the low-order bit of the instruction
	jz	short @MODRM1_BYTE ; Jump if byte-wide

	test	[ebp].ID_PDEF,@PREF_OSP ; Check on default behavior
	jz	short @MODRM1_WORD ; Jump if two-byte data

; Mark as four-byte data with Mod R/M byte

	or	es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_MRM or @OPER_DWID
	or	es:[edi].OPER1_DWID,@DWIDTH_DWORD

	jmp	short @MODRM1_EXIT ; Join common exit code


@MODRM1_WORD:

; Mark as two-byte data with Mod R/M byte

	or	es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_MRM or @OPER_DWID
	or	es:[edi].OPER1_DWID,@DWIDTH_WORD

	jmp	short @MODRM1_EXIT ; Join common exit code


@MODRM1_BYTE:

; Mark as one-byte data with Mod R/M byte

	or	es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_MRM or @OPER_DWID
	or	es:[edi].OPER1_DWID,@DWIDTH_BYTE
@MODRM1_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@MODRM1 endp			; End @MODRM1 procedure
	NPPROC	@MODRM2 -- Save Second Mod R/M Byte
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If operand analysis is in effect, save the following byte (in a dword)
as the second Mod R/M byte.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream or operand data structure

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	lods	ds:[esi].EDD	; Get the following data item

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @MODRM2_EXIT ; Not this time

	mov	es:[edi].OPER2_MODRM,al ; Save as Mod R/M byte

; Transfer data from OPER1_FLAG to OPER2_FLAG

	mov	ax,es:[edi].OPER1_FLAG ; Get flags
	mov	es:[edi].OPER2_FLAG,ax ; Save here

	mov	es:[edi].OPER2_SEG,@SEG_ES ; Default is always ES

; Determine the data width from the instruction and OSP.
; If the last instruction byte is even, it's byte-wide.
; Otherwise, the width is controlled by the OSP.

	call	GET_LBYTE	; AL = last instruction byte

	test	al,@BIT0	; Check the low-order bit of the instruction
	jz	short @MODRM2_BYTE ; Jump if byte-wide

	test	[ebp].ID_PDEF,@PREF_OSP ; Check on default behavior
	jz	short @MODRM2_WORD ; Jump if two-byte data

; Mark as four-byte data with Mod R/M byte

	or	es:[edi].OPER2_FLAG,@OPER_MEM or @OPER_MRM or @OPER_DWID
	or	es:[edi].OPER2_DWID,@DWIDTH_DWORD

	jmp	short @MODRM2_EXIT ; Join common exit code


@MODRM2_WORD:

; Mark as two-byte data with Mod R/M byte

	or	es:[edi].OPER2_FLAG,@OPER_MEM or @OPER_MRM or @OPER_DWID
	or	es:[edi].OPER2_DWID,@DWIDTH_WORD

	jmp	short @MODRM2_EXIT ; Join common exit code


@MODRM2_BYTE:

; Mark as one-byte data with Mod R/M byte

	or	es:[edi].OPER2_FLAG,@OPER_MEM or @OPER_MRM or @OPER_DWID
	or	es:[edi].OPER2_DWID,@DWIDTH_BYTE
@MODRM2_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@MODRM2 endp			; End @MODRM2 procedure
	NPPROC	@STACK1 -- First Stack Reference
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Handle first stack reference if operand analysis in effect.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream or operand data structure

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	lods	ds:[esi].EDD	; Get data width flag

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

@STACK_ALL equ	@OPER_MEM or @OPER_MRM or @OPER_SEG or @OPER_DWID or @OPER_STK

	mov	es:[edi].OPER1_SEG,@SEG_SS ; Mark as SS segment
	mov	es:[edi].OPER1_MODRM,11b shl $MOD ; Use pseudo-code for [SP]
	or	es:[edi].OPER1_FLAG,@STACK_ALL ; Mark with common flags
	or	es:[edi].OPER1_DWID,eax ; Save data width flag
@@:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@STACK1 endp			; End @STACK1 procedure
	NPPROC	@STACK2 -- Second Stack Reference
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Handle second stack reference if operand analysis in effect.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream or operand data structure

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	lods	ds:[esi].EDD	; Get data width flag

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @F	; Not this time

	mov	es:[edi].OPER2_SEG,@SEG_SS ; Mark as SS segment
	mov	es:[edi].OPER2_MODRM,11b shl $MOD ; Use pseudo-code for [SP]
	or	es:[edi].OPER2_FLAG,@STACK_ALL ; Mark with common flags
	or	es:[edi].OPER2_DWID,eax ; Save data width flag
@@:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@STACK2 endp			; End @STACK2 procedure
	NPPROC	@DWIDTH -- Data Width Override
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Handle data width override if operand analysis in effect.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream or operand data structure

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	lods	ds:[esi].EDD	; Get data width flag

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jz	short @DWIDTH_EXIT ; Not this time

	cmp	eax,@DWIDTH_WORD ; Izit WORD width?
	jne	short @F	; Jump if not

	test	es:[edi].OPER1_FLAG,@OPER_MEM ; Izit memory already?
	jz	short @DWIDTH_EXIT ; Jump if not
@@:
	or	es:[edi].OPER1_FLAG,@OPER_DWID ; Mark as present
	mov	es:[edi].OPER1_DWID,eax ; Save data width flag

	cmp	eax,@DWIDTH_INT ; Izit INT ?
	jne	short @DWIDTH_EXIT ; Not this time

	call	GET_LBYTE	; AL = last instruction byte

	mov	ah,03h		; Assume INT 03h

	cmp	al,0CCh 	; Check for INT 03h
	je	short @F	; Jump if so

	mov	ah,04h		; Assume INT 03h

	cmp	al,0CEh 	; Check for INTO
	je	short @F	; Jump if so

	cmp	al,0CDh 	; Check for INT nn
	jne	short @DWIDTH_EXIT ; Not this time????

; Get next byte from the instruction stream without incrementing.

	push	esi		; Save for a moment

	mov	esi,[ebp].ID_CINS ; Get current instruction offset
	mov	ah,fs:[esi]	; Get next instruction byte

	pop	esi		; Restore
@@:
	mov	es:[edi].OPER1_CC,ah ; Save for later use
	or	es:[edi].OPER1_FLAG,@OPER_MEM ; Mark as present
@DWIDTH_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@DWIDTH endp			; End @DWIDTH procedure
	NPPROC	@INTMSG -- INT Message Text
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Handle interrupt message text.

On entry:

DS:ESI	==>	action stream
ES:EDI	==>	output stream or operand data structure

On exit:

DS:ESI	==>	action stream, updated
ES:EDI	==>	output stream, updated
EAX	=	destroyed

|

	lods	ds:[esi].EDD	; Get the following data item

	test	[ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	jnz	near ptr @INTMSG_EXIT ; Jump if so

	cmp	ax,0		; Izit two-byte opcode?
	jne	short @F	; Jump if not

	xor	ah,ah		; Zero to use as word
	call	GET_LBYTE	; AL = last instruction byte
@@:

; AX = interrupt #

	REGSAVE <ebx,ecx,edx,esi> ; Save for a moment

; Move DI to comment marker point indented by five bytes
; to maximize text area display

	mov	ecx,[ebp].ID_IOUT ; Restore initial output stream offset
	add	ecx,@FILL_COMMENT-5 ; Plus comment offset
	sub	ecx,edi 	 ; Less current offset
	jbe	short @F	; Jump if already past that

	push	eax		; Save for a moment
	mov	al,' '          ; Fill with blanks
    rep stos	es:[edi].LO	; Fill it up
	pop	eax		; Restore
@@:
	mov	edx,WINBASE	; Get offset in DGROUP of WGROUP

; Because Windows uses a dynamic linking convention of INT 20h followed by
; two words of data, we detect that here and handle it specially.

	cmp	ax,20h		; Izit INT 20h?
	jne	short @INTMSG1	; Jump if not

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	jnz	near ptr @INTMSG_WIN ; Jump if so
@INTMSG1:
	cmp	ax,10h		; Izit a Video call?
	je	short @INTMSG_VID ; Jump if so

	cmp	ax,1Ah		; Izit a PCI call?
	je	short @INTMSG_PCI ; Jump if so

	cmp	ax,21h		; Izit a DOS call?
	je	near ptr @INTMSG_DOS ; Jump if so

	cmp	ax,22h		; Izit a Win386 call?
	je	near ptr @INTMSG_WIN386 ; Jump if so

	cmp	ax,31h		; Izit a DPMI call?
	je	near ptr @INTMSG_DPMI ; Jump if so

	cmp	ax,67h		; Izit an EMS call?
	je	near ptr @INTMSG_EMS ; Jump if so

	cmp	ax,68h		; Izit a WDEB call?
	je	near ptr @INTMSG_WDEB ; Jump if so
@INTMSG_COM:
	movzx	ebx,ax		; Copy as minor function #
	mov	ax,INTER	; Set major function #

	jmp	@INTMSG2	; Join common code


; Interrupt is 10h.
; If this is the current instruction, use a comment based upon the
; Video function #.

@INTMSG_VID:
	push	eax		; Save for a moment
	push	ebp		; Save for a moment

	mov	ebp,[ebp].ID_FORW_EBP ; Get FORW_STR ptr

	PUSHW	fs		; Pass selector
	call	GETBASE 	; Get selector base using ss:[ebp] ==> FORW_STR

	pop	ebp		; Restore

	add	eax,[ebp].ID_IINS ; Plus offset of initial instruction byte

	cmp	eax,CUR_INSTR	; Unassembling current instruction?
	pop	eax		; Restore
	jne	short @INTMSG_COM ; Jump if not

	mov	ax,INTER10	; Set major function #

	mov	ebx,[ebp].ID_FORW_EBP ; Address FORW_STR
	movzx	ebx,ss:[ebx].FORW_EAX.ELO.HI ; Get caller's AH (minor #)

	jmp	@INTMSG2	; Join common code


; Interrupt is 1Ah.
; If this is the current instruction, use a comment based upon the
; PCI function #.

@INTMSG_PCI:
	push	eax		; Save for a moment
	push	ebp		; Save for a moment

	mov	ebp,[ebp].ID_FORW_EBP ; Get FORW_STR ptr

	PUSHW	fs		; Pass selector
	call	GETBASE 	; Get selector base using ss:[ebp] ==> FORW_STR

	pop	ebp		; Restore

	add	eax,[ebp].ID_IINS ; Plus offset of initial instruction byte

	cmp	eax,CUR_INSTR	; Unassembling current instruction?
	pop	eax		; Restore
	jne	short @INTMSG_COM ; Jump if not

	mov	eax,[ebp].ID_FORW_EBP ; Address FORW_STR
	mov	ax,ss:[eax].FORW_EAX.ELO ; Get caller's AX

	lea	ebx,WGROUP:WINTAB_INTER1A ; Get offset in WGROUP of WTAB_STR

	jmp	@INTMSG_VALW	; Join common word value lookup/display code


; Interrupt is 21h.
; If this is the current instruction, use a comment based upon the
; DOS function #.

@INTMSG_DOS:
	push	eax		; Save for a moment
	push	ebp		; Save for a moment

	mov	ebp,[ebp].ID_FORW_EBP ; Get FORW_STR ptr

	PUSHW	fs		; Pass selector
	call	GETBASE 	; Get selector base using ss:[ebp] ==> FORW_STR

	pop	ebp		; Restore

	add	eax,[ebp].ID_IINS ; Plus offset of initial instruction byte

	cmp	eax,CUR_INSTR	; Unassembling current instruction?
	pop	eax		; Restore
	jne	short @INTMSG_COM ; Jump if not

	mov	ax,INTER21	; Set major function #

	mov	ebx,[ebp].ID_FORW_EBP ; Address FORW_STR
	movzx	ebx,ss:[ebx].FORW_EAX.ELO.HI ; Get caller's AH (minor #)

	jmp	@INTMSG2	; Join common code


; Interrupt is 22h.
; If this is the current instruction, use a comment based upon the
; Win386 function #.

@INTMSG_WIN386:
	push	eax		; Save for a moment
	push	ebp		; Save for a moment

	mov	ebp,[ebp].ID_FORW_EBP ; Get FORW_STR ptr

	PUSHW	fs		; Pass selector
	call	GETBASE 	; Get selector base using ss:[ebp] ==> FORW_STR

	pop	ebp		; Restore

	add	eax,[ebp].ID_IINS ; Plus offset of initial instruction byte

	cmp	eax,CUR_INSTR	; Unassembling current instruction?
	pop	eax		; Restore
	jne	near ptr @INTMSG_COM ; Jump if not

	mov	eax,[ebp].ID_FORW_EBP ; Address FORW_STR
	mov	ax,ss:[eax].FORW_EAX.ELO ; Get caller's AX

	lea	ebx,WGROUP:WINTAB_INTER22 ; Get offset in WGROUP of WTAB_STR

	jmp	@INTMSG_VALW	; Join common word value lookup/display code


; Interrupt is 31h.
; If this is the current instruction, use a comment based upon the
; DPMI function #.

@INTMSG_DPMI:
	push	eax		; Save for a moment
	push	ebp		; Save for a moment

	mov	ebp,[ebp].ID_FORW_EBP ; Get FORW_STR ptr

	PUSHW	fs		; Pass selector
	call	GETBASE 	; Get selector base using ss:[ebp] ==> FORW_STR

	pop	ebp		; Restore

	add	eax,[ebp].ID_IINS ; Plus offset of initial instruction byte

	cmp	eax,CUR_INSTR	; Unassembling current instruction?
	pop	eax		; Restore
	jne	near ptr @INTMSG_COM ; Jump if not

	mov	eax,[ebp].ID_FORW_EBP ; Address FORW_STR
	mov	ax,ss:[eax].FORW_EAX.ELO ; Get caller's AX

	lea	ebx,WGROUP:WINTAB_INTER31 ; Get offset in WGROUP of WTAB_STR

	jmp	@INTMSG_VALW	; Join common word value lookup/display code


; Interrupt is 67h.
; If this is the current instruction, use a comment based upon the
; EMS function #.

@INTMSG_EMS:
	push	eax		; Save for a moment
	push	ebp		; Save for a moment

	mov	ebp,[ebp].ID_FORW_EBP ; Get FORW_STR ptr

	PUSHW	fs		; Pass selector
	call	GETBASE 	; Get selector base using ss:[ebp] ==> FORW_STR

	pop	ebp		; Restore

	add	eax,[ebp].ID_IINS ; Plus offset of initial instruction byte

	cmp	eax,CUR_INSTR	; Unassembling current instruction?
	pop	eax		; Restore
	jne	near ptr @INTMSG_COM ; Jump if not

	mov	ebx,[ebp].ID_FORW_EBP ; Address FORW_STR

	cmp	ss:[ebx].FORW_EAX.ELO.HI,@VCPI ; Izit EMS function?
	jne	near ptr @INTMSG_COM ; Jump if not

	movzx	ebx,ss:[ebx].FORW_EAX.ELO.LO ; Get caller's AL (minor #)

	mov	ax,INTER67	; Set major function #

	cmp	bl,@VCPI_DPRES	; Izit a Debugger call?
	jb	short @F	; Jump if not

	mov	ax,INTER67A	; Set major function #
	sub	bl,@VCPI_DPRES	; Convert to origin-F0
@@:
	jmp	@INTMSG2	; Join common code


; Interrupt is 68h.
; If this is the current instruction, use a comment based upon the
; WDEB function #.

@INTMSG_WDEB:
	push	eax		; Save for a moment
	push	ebp		; Save for a moment

	mov	ebp,[ebp].ID_FORW_EBP ; Get FORW_STR ptr

	PUSHW	fs		; Pass selector
	call	GETBASE 	; Get selector base using ss:[ebp] ==> FORW_STR

	pop	ebp		; Restore

	add	eax,[ebp].ID_IINS ; Plus offset of initial instruction byte

	cmp	eax,CUR_INSTR	; Unassembling current instruction?
	pop	eax		; Restore
	jne	near ptr @INTMSG_COM ; Jump if not

	mov	ax,INTER68	; Set major function #

	mov	ebx,[ebp].ID_FORW_EBP ; Address FORW_STR
	movzx	ebx,ss:[ebx].FORW_EAX.ELO.HI ; Get caller's AH (minor #)

	sub	ebx,@I68_MIN	; Less minimum function #
	jb	near ptr @INTMSG_COM ; Jump if not valid

	jmp	@INTMSG2	; Join common code


COMMENT|

Word value lookup display code

On entry:

AX	=	word value to lookup
EBX	=	offset in WGROUP of WTAB_STR entry
EDX	=	WINBASE

|

@INTMSG_VALW:
	movzx	ecx,DGROUP:[edx+ebx].WTAB_LEN ; Get the # entries

; Search for the function # in the value table

	mov	esi,DGROUP:[edx+ebx].WTAB_VALW ; Get ptr to start of table
@@:
	cmp	ax,DGROUP:[edx+esi] ; Duzit match?
	je	short @F	; Jump if so

	add	esi,2		; Skip to next word entry

	loop	@B		; Jump if more entries

	mov	bx,ax		; Copy as service #

	jmp	@INTMSG_UNKSVC	; Jump if unknown function


@@:

; Display the prefacing text

	push	esi		; Save for a moment
	mov	esi,DGROUP:[edx+ebx].WTAB_PREF ; DS:ESI ==> Prefacing text
	add	esi,edx 	; Plus WINBASE to get offset within DGROUP
	call	COPY_ASCIIZ	; Copy VxD name from DS:ESI to ES:EDI
	pop	esi		; Restore

; Point to the trailing text

	sub	esi,DGROUP:[edx+ebx].WTAB_VALW ; Less start of table
	shr	esi,1-0 	; Convet from bytes to index
	mov	ebx,DGROUP:[edx+ebx].WTAB_PTAB ; Get ptr to start of text table
	add	ebx,edx 	; Plus WINBASE to get offset within DGROUP
	mov	esi,DGROUP:[ebx+esi*4] ; Get ptr to text
	add	esi,edx 	; Plus WINBASE to get offset within DGROUP

	jmp	@INTMSG3	; Join common code


; Interrupt is 20h in PM (assumed to be Windows).
; Display info based upon the four bytes of data which follows the CD 20.

@INTMSG_WIN:

; Display a comment suitable to the function codes following the INT 20h

	call	GET_IWORD	; AX = next instruction word
	movzx	ebx,ax		; Copy as service #

	call	GET_IWORD	; AX = next instruction word (VxD ID)
@INTMSG2:

; Because we now load WINTAB at INIT_VIRT time, we need to ensure
; that WINBASE points to valid data

	test	LCL_FLAG,@LCL_WINTAB ; Izit initialized?
	jz	short @INTMSG_UNK ; Jump if not

; AX has the VxD ID, EBX the service #

	lea	esi,WGROUP:WINTAB ; Get offset of WINTAB in WGROUP
	mov	ecx,WINTAB_CNT	; ECX = # entries in WINTAB
@@:
	cmp	ax,DGROUP:[edx+esi].WTAB_FCN ; Same VxD ID?
	je	short @INTMSG_MAJOR ; Jump if so

	add	esi,type WTAB_STR ; Skip to next entry

	loop	@B		; Jump if more entries to check
@INTMSG_UNK:
	REGSAVE <edi,es>	; Save for a moment

	push	ds		; Get our data selector
	pop	es		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	lea	edi,TXT_WINUNK2 ; ES:EDI ==> output save area
	call	DW2HEX		; Convert VxD ID to hex at ES:EDI

	mov	ax,bx		; Get the service #
	lea	edi,TXT_WINUNK1 ; ES:EDI ==> output save area
	call	DW2HEX		; Convert service # to hex at ES:EDI

	REGREST <es,edi>	; Restore
	assume	es:nothing	; Tell the assembler

	lea	esi,TXT_WINUNK	; DS:ESI ==> message text to display

	jmp	short @INTMSG3	; Join common code


; DGROUP:[edx+esi] ==> WINTAB entry for this major function
; EBX	 =	 minor function #

@INTMSG_MAJOR:
	and	bx,not 8000h	; Kill the 'JMP/CALL' bit

	push	esi		; Save for a moment
	mov	esi,DGROUP:[edx+esi].WTAB_PREF ; DS:ESI ==> Prefacing text
	add	esi,edx 	; Plus WINBASE to get offset within DGROUP
	call	COPY_ASCIIZ	; Copy VxD name from DS:ESI to ES:EDI
	pop	esi		; Restore

	cmp	bx,DGROUP:[edx+esi].WTAB_LEN ; Is the service # within range?
	jae	short @INTMSG_UNKSVC ; Jump if not

	mov	esi,DGROUP:[edx+esi].WTAB_PTAB ; Get table pointer
	add	esi,edx 	; Plus WINBASE to get offset within DGROUP

	mov	esi,DGROUP:[esi+ebx*4].EDD ; Get entry within table
	add	esi,edx 	; Plus WINBASE to get offset within DGROUP
				; DS:ESI ==> service name
	jmp	short @INTMSG3	; Rejoin common code


@INTMSG_UNKSVC:
	REGSAVE <edi,es>	; Save for a moment

	push	ds		; Get our data selector
	pop	es		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	ax,bx		; Get service #
	lea	edi,TXT_WINUNK2 ; ES:EDI ==> output save area
	call	DW2HEX		; Convert service # to hex at ES:EDI

	REGREST <es,edi>	; Restore
	assume	es:nothing	; Tell the assembler

	lea	esi,TXT_WINUNK2 ; DS:ESI ==> message text to display
				; Fall into common code

@INTMSG3:
	call	COPY_ASCIIZ	; Copy service name (or #) from DS:ESI to ES:EDI

	REGREST <esi,edx,ecx,ebx> ; Restore
@INTMSG_EXIT:
	lods	ds:[esi].EDD	; Get next action

	jmp	eax		; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

@INTMSG endp			; End @INTMSG procedure

PROG	ends			; End PROG segment

	MEND			; End INT1_FNS module
