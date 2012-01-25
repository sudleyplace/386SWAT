;' $Header:   P:/PVCS/386SWAT/INT1/INT1_GRP.ASV   1.8   01 Jul 1997 17:55:56   BOB  $
	 title	 INT1_GRP -- INT 01h Group 1-8 Functions
	 page	 58,122
	 name	 INT1_GRP

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, April, 1988.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include IOPBITS.INC

	 include INT1_FNS.INC
	 include SWAT_SEG.INC
.list

TEXT	 segment use32 byte public 'data' ; Start TEXT segment
	 assume  ds:DGROUP

	 extrn	 MSG_DPTR:byte
	 extrn	 MSG_FPTR:byte
	 extrn	 MSG_5PTR:byte
	 extrn	 MSG_6PTR:byte

	 extrn	 TXT_UNK:byte

	 extrn	 TXT_ADC:byte
	 extrn	 TXT_ADD:byte
	 extrn	 TXT_AND:byte

	 extrn	 TXT_BT:byte
	 extrn	 TXT_BTC:byte
	 extrn	 TXT_BTR:byte
	 extrn	 TXT_BTS:byte

	 extrn	 TXT_CALLF:byte
	 extrn	 TXT_CALLN:byte
	 extrn	 TXT_CMP:byte

	 extrn	 TXT_DEC:byte
	 extrn	 TXT_DIV:byte

	 extrn	 TXT_IDIV:byte
	 extrn	 TXT_IMUL:byte
	 extrn	 TXT_INC:byte
	 extrn	 TXT_INVLPG:byte

	 extrn	 TXT_JMPF:byte
	 extrn	 TXT_JMPN:byte

	 extrn	 TXT_LGDT:byte
	 extrn	 TXT_LIDT:byte
	 extrn	 TXT_LLDT:byte
	 extrn	 TXT_LMSW:byte
	 extrn	 TXT_LTR:byte

	 extrn	 TXT_MUL:byte

	 extrn	 TXT_NEG:byte
	 extrn	 TXT_NOT:byte

	 extrn	 TXT_OR:byte

	 extrn	 TXT_PUSH:byte

	 extrn	 TXT_RCL:byte
	 extrn	 TXT_RCR:byte
	 extrn	 TXT_ROL:byte
	 extrn	 TXT_ROR:byte

	 extrn	 TXT_SAR:byte
	 extrn	 TXT_SBB:byte
	 extrn	 TXT_SGDT:byte
	 extrn	 TXT_SIDT:byte
	 extrn	 TXT_SHL:byte
	 extrn	 TXT_SHR:byte
	 extrn	 TXT_SLDT:byte
	 extrn	 TXT_SMSW:byte
	 extrn	 TXT_STR:byte
	 extrn	 TXT_SUB:byte

	 extrn	 TXT_TEST:byte

	 extrn	 TXT_VERR:byte
	 extrn	 TXT_VERW:byte

	 extrn	 TXT_XOR:byte

	 public  GRP1
GRP1	 dd	 offset DGROUP:TXT_ADD	       ; 000
	 dd	 offset DGROUP:TXT_OR	       ; 001
	 dd	 offset DGROUP:TXT_ADC	       ; 010
	 dd	 offset DGROUP:TXT_SBB	       ; 011
	 dd	 offset DGROUP:TXT_AND	       ; 100
	 dd	 offset DGROUP:TXT_SUB	       ; 101
	 dd	 offset DGROUP:TXT_XOR	       ; 110
	 dd	 offset DGROUP:TXT_CMP	       ; 111

	 public  GRP2
GRP2	 dd	 offset DGROUP:TXT_ROL	       ; 000
	 dd	 offset DGROUP:TXT_ROR	       ; 001
	 dd	 offset DGROUP:TXT_RCL	       ; 010
	 dd	 offset DGROUP:TXT_RCR	       ; 011
	 dd	 offset DGROUP:TXT_SHL	       ; 100
	 dd	 offset DGROUP:TXT_SHR	       ; 101
	 dd	 offset DGROUP:TXT_SAR	       ; 110
	 dd	 offset DGROUP:TXT_SAR	       ; 111

	 public  GRP3
GRP3	 dd	 offset DGROUP:TXT_TEST        ; 000
	 dd	 offset DGROUP:TXT_TEST        ; 001
	 dd	 offset DGROUP:TXT_NOT	       ; 010
	 dd	 offset DGROUP:TXT_NEG	       ; 011
	 dd	 offset DGROUP:TXT_MUL	       ; 100
	 dd	 offset DGROUP:TXT_IMUL        ; 101
	 dd	 offset DGROUP:TXT_DIV	       ; 110
	 dd	 offset DGROUP:TXT_IDIV        ; 111

	 public  GRP4
GRP4	 dd	 offset DGROUP:TXT_INC	       ; 000
	 dd	 offset DGROUP:TXT_DEC	       ; 001
	 dd	 offset DGROUP:TXT_UNK	       ; 010
	 dd	 offset DGROUP:TXT_UNK	       ; 011
	 dd	 offset DGROUP:TXT_UNK	       ; 100
	 dd	 offset DGROUP:TXT_UNK	       ; 101
	 dd	 offset DGROUP:TXT_UNK	       ; 110
	 dd	 offset DGROUP:TXT_UNK	       ; 111

	 public  GRP5
GRP5	 dd	 offset DGROUP:TXT_INC	       ; 000
	 dd	 offset DGROUP:TXT_DEC	       ; 001
	 dd	 offset DGROUP:TXT_CALLN       ; 010
	 dd	 offset DGROUP:TXT_CALLF       ; 011
	 dd	 offset DGROUP:TXT_JMPN        ; 100
	 dd	 offset DGROUP:TXT_JMPF        ; 101
	 dd	 offset DGROUP:TXT_PUSH        ; 110
	 dd	 offset DGROUP:TXT_UNK	       ; 111

	 public  GRP6
GRP6	 dd	 offset DGROUP:TXT_SLDT        ; 000
	 dd	 offset DGROUP:TXT_STR	       ; 001
	 dd	 offset DGROUP:TXT_LLDT        ; 010
	 dd	 offset DGROUP:TXT_LTR	       ; 011
	 dd	 offset DGROUP:TXT_VERR        ; 100
	 dd	 offset DGROUP:TXT_VERW        ; 101
	 dd	 offset DGROUP:TXT_UNK	       ; 110
	 dd	 offset DGROUP:TXT_UNK	       ; 111

	 public  GRP7
GRP7	 dd	 offset DGROUP:TXT_SGDT        ; 000
	 dd	 offset DGROUP:TXT_SIDT        ; 001
	 dd	 offset DGROUP:TXT_LGDT        ; 010
	 dd	 offset DGROUP:TXT_LIDT        ; 011
	 dd	 offset DGROUP:TXT_SMSW        ; 100
	 dd	 offset DGROUP:TXT_UNK	       ; 101
	 dd	 offset DGROUP:TXT_LMSW        ; 110
	 dd	 offset DGROUP:TXT_INVLPG      ; 111

	 public  GRP8
GRP8	 dd	 offset DGROUP:TXT_UNK	       ; 000
	 dd	 offset DGROUP:TXT_UNK	       ; 001
	 dd	 offset DGROUP:TXT_UNK	       ; 010
	 dd	 offset DGROUP:TXT_UNK	       ; 011
	 dd	 offset DGROUP:TXT_BT	       ; 100
	 dd	 offset DGROUP:TXT_BTS	       ; 101
	 dd	 offset DGROUP:TXT_BTR	       ; 110
	 dd	 offset DGROUP:TXT_BTC	       ; 111

TEXT	 ends			; End TEXT segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 extrn	 GET_MODRM:near
	 extrn	 COPY_ASCIIZ:near
	 extrn	 FILL_OPCODE:near
	 extrn	 DISP_COMMA:near

	 extrn	 GET_IBYTE:near
	 extrn	 GET_IWORD:near
	 extrn	 GET_IDWORD:near

	 extrn	 DB2HEX:near
	 extrn	 DW2HEX:near
	 extrn	 DD2HEX:near

	 NPPROC  @GRP1 -- Display Group 1 Instruction Name
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Display Group 1 instruction name.

On entry:

DS:ESI	 ==>	 action stream
ES:EDI	 ==>	 output stream

On exit:

DS:ESI	 ==>	 action stream, updated
ES:EDI	 ==>	 output stream, updated
EAX	 =	 destroyed

|

	 inc	 [ebp].ID_NCOMP ; One more component displayed so far

	 call	 GET_MODRM	; Return MOD/RM byte in AL

	 and	 al,mask $REG	; Isolate group index
	 shr	 al,$REG	; Shift to low-order

	 push	 esi		; Save for a moment

	 movzx	 esi,al 	; Copy to index register
	 mov	 esi,GRP1[esi*(type GRP1)] ; DS:ESI ==> Group 1 instruction name
	 mov	 ecx,edi	; Save starting offset
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	 call	 FILL_OPCODE	; Fill out the opcode text from ECX

	 pop	 esi		; Restore

	 lods	 ds:[esi].EDD	; Get next action

	 jmp	 eax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

@GRP1	 endp			; End @GRP1 procedure
	 NPPROC  @GRP2 -- Display Group 2 Instruction Name
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Display Group 2 instruction name.

On entry:

DS:ESI	 ==>	 action stream
ES:EDI	 ==>	 output stream

On exit:

DS:ESI	 ==>	 action stream, updated
ES:EDI	 ==>	 output stream, updated
EAX	 =	 destroyed

|

	 inc	 [ebp].ID_NCOMP ; One more component displayed so far

	 call	 GET_MODRM	; Return MOD/RM byte in AL

	 and	 al,mask $REG	; Isolate group index
	 shr	 al,$REG	; Shift to low-order

	 push	 esi		; Save for a moment

	 movzx	 esi,al 	; Copy to index register
	 mov	 esi,GRP2[esi*(type GRP2)] ; DS:ESI ==> Group 2 instruction name
	 mov	 ecx,edi	; Save starting offset
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	 call	 FILL_OPCODE	; Fill out the opcode text from ECX

	 pop	 esi		; Restore

	 lods	 ds:[esi].EDD	; Get next action

	 jmp	 eax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

@GRP2	 endp			; End @GRP2 procedure
	 NPPROC  @GRP3 -- Display Group 3 Instruction Name
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Display Group 3 instruction name.

On entry:

DS:ESI	 ==>	 action stream
ES:EDI	 ==>	 output stream

On exit:

DS:ESI	 ==>	 action stream, updated
ES:EDI	 ==>	 output stream, updated
EAX	 =	 destroyed

|

	 inc	 [ebp].ID_NCOMP ; One more component displayed so far

	 call	 GET_MODRM	; Return MOD/RM byte in AL

	 and	 al,mask $REG	; Isolate group index
	 shr	 al,$REG	; Shift to low-order

	 push	 esi		; Save for a moment

	 movzx	 esi,al 	; Copy to index register
	 mov	 esi,GRP3[esi*(type GRP3)] ; DS:ESI ==> Group 3 instruction name
	 mov	 ecx,edi	; Save starting offset
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	 call	 FILL_OPCODE	; Fill out the opcode text from ECX

	 pop	 esi		; Restore

	 lods	 ds:[esi].EDD	; Get next action

	 jmp	 eax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

@GRP3	 endp			; End @GRP3 procedure
	 NPPROC  @GRP3Z -- Display Group 3 Instruction Ending
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Display Group 3 instruction ending

On entry:

DS:ESI	 ==>	 action stream
ES:EDI	 ==>	 output stream

On exit:

DS:ESI	 ==>	 action stream, updated
ES:EDI	 ==>	 output stream, updated
EAX	 =	 destroyed

|

	 lods	 ds:[esi].EDD	; Get immediate data width if present

	 push	 eax		; Save for a moment

	 call	 GET_MODRM	; Return MOD/RM byte in AL

	 and	 al,mask $REG	; Isolate Group index
	 pop	 eax		; Restore
	 jnz	 short @GRP3Z_EXIT ; Jump if no immediate data

	 inc	 [ebp].ID_NCOMP ; One more component displayed so far

	 call	 DISP_COMMA	; Display comma separator if appropriate

	 cmp	 ax,16		; Check immediate data width
	 jb	 short @GRP3Z_BYTE ; It's byte wide
	 je	 short @GRP3Z_WORD ; It's word wide
				; Fall through if dword wide

	 call	 GET_IDWORD	; EAX = next instruction dword

	 test	 [ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	 jnz	 short @GRP3Z_EXIT ; Yes, skip this

	 call	 DD2HEX 	; Display EAX in hex at ES:EDI

	 jmp	 short @GRP3Z_EXIT ; Join common exit code

@GRP3Z_WORD:
	 call	 GET_IWORD	; AX = next instruction word

	 test	 [ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	 jnz	 short @GRP3Z_EXIT ; Yes, skip this

	 call	 DW2HEX 	; Display AX in hex at ES:EDI

	 jmp	 short @GRP3Z_EXIT ; Join common exit code

@GRP3Z_BYTE:
	 call	 GET_IBYTE	; AL = next instruction byte

	 test	 [ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	 jnz	 short @GRP3Z_EXIT ; Yes, skip this

	 call	 DB2HEX 	; Display AL in hex at ES:EDI
@GRP3Z_EXIT:
	 lods	 ds:[esi].EDD	; Get next action

	 jmp	 eax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

@GRP3Z	 endp			; End @GRP3Z procedure
	 NPPROC  @GRP4 -- Display Group 4 Instruction Name
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Display Group 4 instruction name.

On entry:

DS:ESI	 ==>	 action stream
ES:EDI	 ==>	 output stream

On exit:

DS:ESI	 ==>	 action stream, updated
ES:EDI	 ==>	 output stream, updated
EAX	 =	 destroyed

|

	 inc	 [ebp].ID_NCOMP ; One more component displayed so far

	 call	 GET_MODRM	; Return MOD/RM byte in AL

	 and	 al,mask $REG	; Isolate group index
	 shr	 al,$REG	; Shift to low-order

	 push	 esi		; Save for a moment

	 movzx	 esi,al 	; Copy to index register
	 mov	 esi,GRP4[esi*(type GRP4)] ; DS:ESI ==> Group 4 instruction name
	 mov	 ecx,edi	; Save starting offset
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	 call	 FILL_OPCODE	; Fill out the opcode text from ECX

	 pop	 esi		; Restore

	 lods	 ds:[esi].EDD	; Get next action

	 jmp	 eax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

@GRP4	 endp			; End @GRP4 procedure
	 NPPROC  @GRP5 -- Display Group 5 Instruction Name
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Display Group 5 instruction name.

On entry:

DS:ESI	 ==>	 action stream
ES:EDI	 ==>	 output stream

On exit:

DS:ESI	 ==>	 action stream, updated
ES:EDI	 ==>	 output stream, updated
EAX	 =	 destroyed

|

	 inc	 [ebp].ID_NCOMP ; One more component displayed so far

	 call	 GET_MODRM	; Return MOD/RM byte in AL

; Split off invalid opcodes:  MOD=11, REG=011 (CALLF) or 101 (JMPF)

	 mov	 ah,al		; Copy for destructive testing
	 and	 ah,mask $MOD	; Isolate the MOD bits

	 cmp	 ah,11b shl $MOD ; Izit MOD=11?
	 jne	 short @GRP5_XINVOP ; Jump if not

	 mov	 ah,al		; Copy for destructive testing
	 and	 ah,mask $REG	; Isolate group index

	 cmp	 ah,011b shl $REG ; Izit REG=011 (CALLF)?
	 je	 short @GRP5_INVOP ; Jump if so

	 cmp	 ah,101b shl $REG ; Izit REG=101 (JMPF)?
	 jne	 short @GRP5_XINVOP ; Jump if not
@GRP5_INVOP:
	 mov	 al,111b shl $REG ; Convert to REG=111 (UNK)
@GRP5_XINVOP:
	 and	 al,mask $REG	; Isolate group index
	 shr	 al,$REG	; Shift to low-order

	 push	 esi		; Save for a moment

	 movzx	 esi,al 	; Copy to index register
	 mov	 esi,GRP5[esi*(type GRP5)] ; DS:ESI ==> Group 5 instruction name
	 mov	 ecx,edi	; Save starting offset
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	 call	 FILL_OPCODE	; Fill out the opcode text from ECX

; Pick off CALL m16:16/32 and JMP m16:16/32

	 cmp	 al,011b	; Check for CALL m16:16/32
	 je	 short @GRP5_M16 ; Good guess

	 cmp	 al,101b	; Check for JMP m16:16/32
	 jne	 short @GRP5_EXIT ; Not this time
@GRP5_M16:
	 lea	 esi,MSG_DPTR	; Assume Dword ptr
	 mov	 eax,@DWIDTH_PTR16 ; Get data width flag

	 test	 [ebp].ID_PDEF,@PREF_OSP ; Check on default behavior
	 jz	 short @GRP5_COPY ; Jump if it's four-byte data

	 lea	 esi,MSG_FPTR	; It's Fword ptr
	 mov	 eax,@DWIDTH_PTR32 ; Get data width flag
@GRP5_COPY:
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

	 or	 [ebp].ID_FLAG,@FLAG_PTR ; Mark as present

	 test	 [ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	 jz	 short @GRP5_EXIT ; Not this time

	 or	 es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_DWID ; Mark as present
	 or	 es:[edi].OPER1_DWID,eax ; Set data width flag
@GRP5_EXIT:
	 pop	 esi		; Restore

	 lods	 ds:[esi].EDD	; Get next action

	 jmp	 eax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

@GRP5	 endp			; End @GRP5 procedure
	 NPPROC  @GRP6 -- Display Group 6 Instruction Name
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Display Group 6 instruction name.

On entry:

DS:ESI	 ==>	 action stream
ES:EDI	 ==>	 output stream

On exit:

DS:ESI	 ==>	 action stream, updated
ES:EDI	 ==>	 output stream, updated
EAX	 =	 destroyed

|

	 inc	 [ebp].ID_NCOMP ; One more component displayed so far

	 call	 GET_MODRM	; Return MOD/RM byte in AL

	 and	 al,mask $REG	; Isolate group index
	 shr	 al,$REG	; Shift to low-order

	 push	 esi		; Save for a moment

	 movzx	 esi,al 	; Copy to index register
	 mov	 esi,GRP6[esi*(type GRP6)] ; DS:ESI ==> Group 6 instruction name
	 mov	 ecx,edi	; Save starting offset
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	 call	 FILL_OPCODE	; Fill out the opcode text from ECX

	 pop	 esi		; Restore

; If this instruction is SLDT (000) or STR (001), then the
; operand size prefix has the effect of storing into the 32-bit
; target if it's a register, 16-bit target if memory.

	 cmp	 al,001b	; Izit SLDT or STR?
	 ja	 short @F	; Jump if not

	 call	 GET_MODRM	; Return MOD/RM byte in AL
	 and	 al,mask $MOD	; Isolate MOD bits

	 cmp	 al,11b shl $MOD ; Izit a register operand?
	 jne	 short @F	; Jump if not (must be memory)

	 test	 [ebp].ID_PDEF,@PREF_OSP ; Check on default behavior
	 jz	 short @F	; Jump if 16-bit target

	 or	 [ebp].ID_PDEF,@PREF_OSP2 ; Mark as secondary OSP
@@:
	 lods	 ds:[esi].EDD	; Get next action

	 jmp	 eax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

@GRP6	 endp			; End @GRP6 procedure
	 NPPROC  @GRP7 -- Display Group 7 Instruction Name
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Display Group 7 instruction name.

On entry:

DS:ESI	 ==>	 action stream
ES:EDI	 ==>	 output stream

On exit:

DS:ESI	 ==>	 action stream, updated
ES:EDI	 ==>	 output stream, updated
EAX	 =	 destroyed

|

	 inc	 [ebp].ID_NCOMP ; One more component displayed so far

	 call	 GET_MODRM	; Return MOD/RM byte in AL

; Split off invalid opcodes:  MOD=11, REG=000 (SGDT), 001 (SIDT), 010 (LGDT)
;					  011 (LIDT), 111 (INVLPG)

	 mov	 ah,al		; Copy for destructive testing
	 and	 ah,mask $MOD	; Isolate the MOD bits

	 cmp	 ah,11b shl $MOD ; Izit MOD=11?
	 jne	 short @GRP7_XINVOP ; Jump if not

	 mov	 ah,al		; Copy for destructive testing
	 and	 ah,mask $REG	; Isolate group index

	 cmp	 ah,011b shl $REG ; Izit REG=000-011?
	 jbe	 short @GRP7_INVOP ; Jump if so

	 cmp	 ah,111b shl $REG ; Izit REG=111 (INVLPG)?
	 jne	 short @GRP7_XINVOP ; Jump if not
@GRP7_INVOP:
	 mov	 al,101b shl $REG ; Convert to REG=101 (UNK)
@GRP7_XINVOP:
	 and	 al,mask $REG	; Isolate group index
	 shr	 al,$REG	; Shift to low-order

	 push	 esi		; Save for a moment

	 movzx	 esi,al 	; Copy to index register
	 mov	 esi,GRP7[esi*(type GRP7)] ; DS:ESI ==> Group 7 instruction name
	 mov	 ecx,edi	; Save starting offset
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	 call	 FILL_OPCODE	; Fill out the opcode text from ECX

; Pick off SGDT (000), SIDT (001), LGDT (010), and LIDT (011)

	 cmp	 al,011b	; Check range for 000-011
	 ja	 short @GRP7_EXIT ; Not this time

	 lea	 esi,MSG_5PTR	; DS:ESI ==> '5BYTE PTR '

	 test	 [ebp].ID_PDEF,@PREF_OSP ; Check on default behavior
	 jz	 short @F	; Jump if five-byte data

	 lea	 esi,MSG_6PTR	; DS:ESI ==> '6BYTE PTR '
@@:
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI

	 or	 [ebp].ID_FLAG,@FLAG_PTR ; Mark as filled in

	 test	 [ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	 jz	 short @GRP7_EXIT ; Not this time

	 or	 es:[edi].OPER1_FLAG,@OPER_MEM or @OPER_DWID ; Mark as present
	 or	 es:[edi].OPER1_DWID,@DWIDTH_DTR ; Mark as six-byte data
@GRP7_EXIT:
	 pop	 esi		; Restore

; If this instruction is SMSW (100), then the operand size
; prefix has the effect of storing into the 32-bit target
; if it's a register, 16-bit target if memory.

	 cmp	 al,100b	; Izit SMSW?
	 jne	 short @F	; Jump if not

	 call	 GET_MODRM	; Return MOD/RM byte in AL
	 and	 al,mask $MOD	; Isolate MOD bits

	 cmp	 al,11b shl $MOD ; Izit a register operand?
	 jne	 short @F	; Jump if not (must be memory)

	 test	 [ebp].ID_PDEF,@PREF_OSP ; Check on default behavior
	 jz	 short @F	; Jump if 16-bit target

	 or	 [ebp].ID_PDEF,@PREF_OSP2 ; Mark as secondary OSP
@@:
	 lods	 ds:[esi].EDD	; Get next action

	 jmp	 eax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

@GRP7	 endp			; End @GRP7 procedure
	 NPPROC  @GRP8 -- Display Group 8 Instruction Name
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Display Group 8 instruction name.

On entry:

DS:ESI	 ==>	 action stream
ES:EDI	 ==>	 output stream

On exit:

DS:ESI	 ==>	 action stream, updated
ES:EDI	 ==>	 output stream, updated
EAX	 =	 destroyed

|

	 inc	 [ebp].ID_NCOMP ; One more component displayed so far

	 call	 GET_MODRM	; Return MOD/RM byte in AL
	 mov	 ah,al		; Copy for later use

	 and	 al,mask $REG	; Isolate group index
	 shr	 al,$REG	; Shift to low-order

; If this is a BTx instruction and operand analysis is in effect,
; set DWIDTH BT

	 test	 [ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	 jz	 short @GRP8A	; Not this time

	 cmp	 al,100b	; Izit BTx?
	 jb	 short @GRP8A	; Jump if not

	 or	 es:[edi].OPER1_DWID,@DWIDTH_BTIMM ; Mark as immediate bit data
	 or	 es:[edi].OPER1_FLAG,@OPER_DWID ; Mark as present

; If the lefthand operand is not a register, set @OPER_MEM

	 and	 ah,mask $MOD	; Isolate MOD bits

	 cmp	 ah,11b shl $MOD ; Izit MOD=11 (register)?
	 je	 short @GRP8A	; Jump if so

	 or	 es:[edi].OPER1_FLAG,@OPER_MEM ; Mark as present
@GRP8A:
	 push	 esi		; Save for a moment

	 movzx	 esi,al 	; Copy to index register
	 mov	 esi,GRP8[esi*(type GRP8)] ; DS:ESI ==> Group 8 instruction name
	 mov	 ecx,edi	; Save starting offset
	 call	 COPY_ASCIIZ	; Copy ASCIIZ string at DS:ESI to ES:EDI
	 call	 FILL_OPCODE	; Fill out the opcode text from ECX

	 pop	 esi		; Restore

	 lods	 ds:[esi].EDD	; Get next action

	 jmp	 eax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

@GRP8	 endp			; End @GRP8 procedure

PROG	 ends			; End PROG segment

	 MEND			; End INT1_GRP module
