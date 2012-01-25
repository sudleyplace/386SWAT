;' $Header:   P:/PVCS/386SWAT/INT1/INT1_MSC.ASV   1.5   10 Aug 1998 11:20:54   BOB  $
	 title	 INT1_MSC -- INT 01h Miscellaneous Functions
	 page	 58,122
	 name	 INT1_MSC

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.  All rights reserved.

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

	 include INT1_FNS.INC
	 include SWAT_SEG.INC
.list

TEXT	 segment use32 byte public 'data' ; Start TEXT segment
	 assume  ds:DGROUP

	 public  REG8
REG8	 db	 'AL'           ; 000
	 db	 'CL'           ; 001
	 db	 'DL'           ; 010
	 db	 'BL'           ; 011
	 db	 'AH'           ; 100
	 db	 'CH'           ; 101
	 db	 'DH'           ; 110
	 db	 'BH'           ; 111

	 public  REG16
REG16	 db	 'AX'           ; 000
	 db	 'CX'           ; 001
	 db	 'DX'           ; 010
	 db	 'BX'           ; 011
	 db	 'SP'           ; 100
	 db	 'BP'           ; 101
	 db	 'SI'           ; 110
	 db	 'DI'           ; 111

	 public  SREG
SREG	 db	 'ES'           ; 000
	 db	 'CS'           ; 001
	 db	 'SS'           ; 010
	 db	 'DS'           ; 011
	 db	 'FS'           ; 100
	 db	 'GS'           ; 101
	 db	 '?S'           ; 110
	 db	 '?S'           ; 111

	 public  SCALE
SCALE	 db	 '*2'           ; 01
	 db	 '*4'           ; 10
	 db	 '*8'           ; 11

	 public  MSG_LOCK,MSG_REP,MSG_REPE,MSG_REPNE
	 db	 0,'LOCK'
MSG_LOCK equ	 $-1
	 db	 0,'REP'
MSG_REP  equ	 $-1
	 db	 0,'REPE'
MSG_REPE equ	 $-1
	 db	 0,'REPNE'
MSG_REPNE equ	 $-1

	 public  MSG_BPTR,MSG_WPTR,MSG_DPTR,MSG_5PTR,MSG_6PTR
	 public  MSG_FPTR,MSG_QPTR,MSG_TPTR
	 public  MSG_14PTR,MSG_28PTR,MSG_94PTR,MSG_108PTR
MSG_BPTR db	 'Bptr ',0              ;  1
MSG_WPTR db	 'Wptr ',0              ;  2
MSG_DPTR db	 'Dptr ',0              ;  4
MSG_5PTR db	 '5byte ptr ',0         ;  5
MSG_6PTR db	 '6byte ptr ',0         ;  6
MSG_FPTR db	 'Fword ptr ',0         ;  6
MSG_QPTR db	 'Qword ptr ',0         ;  8
MSG_TPTR db	 'Tbyte ptr ',0         ; 10
MSG_14PTR db	 '14byte ptr ',0        ; 14
MSG_28PTR db	 '28byte ptr ',0        ; 28
MSG_94PTR db	 '94byte ptr ',0        ; 94
MSG_108PTR db	 '108byte ptr ',0       ;108

MODRM16_000 db	 '[BX+SI',0
MODRM16_001 db	 '[BX+DI',0
MODRM16_010 db	 '[BP+SI',0
MODRM16_011 db	 '[BP+DI',0
MODRM16_100 db	 '[SI',0
MODRM16_101 db	 '[DI',0
MODRM16_110 db	 '[BP',0
MODRM16_111 db	 '[BX',0

MODRM32_000 db	 '[EAX',0
MODRM32_001 db	 '[ECX',0
MODRM32_010 db	 '[EDX',0
MODRM32_011 db	 '[EBX',0

MODRM32_101 db	 '[EBP',0
MODRM32_110 db	 '[ESI',0
MODRM32_111 db	 '[EDI',0

	 public  NUMBERS_HI
NUMBERS_HI db	 '0123456789ABCDEF'

TEXT	 ends			; End TEXT segment


INSTR	 segment use32 dword public 'data' ; Start INSTR segment
	 assume  ds:DGROUP

	 public  MODRM16
MODRM16  dd	 offset DGROUP:MODRM16_000
	 dd	 offset DGROUP:MODRM16_001
	 dd	 offset DGROUP:MODRM16_010
	 dd	 offset DGROUP:MODRM16_011
	 dd	 offset DGROUP:MODRM16_100
	 dd	 offset DGROUP:MODRM16_101
	 dd	 offset DGROUP:MODRM16_110
	 dd	 offset DGROUP:MODRM16_111

	 public  MODRM32
MODRM32  dd	 offset DGROUP:MODRM32_000
	 dd	 offset DGROUP:MODRM32_001
	 dd	 offset DGROUP:MODRM32_010
	 dd	 offset DGROUP:MODRM32_011
	 dd	 ?
	 dd	 offset DGROUP:MODRM32_101
	 dd	 offset DGROUP:MODRM32_110
	 dd	 offset DGROUP:MODRM32_111

INSTR	 ends			; End INSTR segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 NPPROC  GET_LBYTE -- Get Last Byte From Instruction Stream
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get last byte from the instruction stream.

On exit:

AL	 =	 last byte

|

	 push	 esi		; Save for a moment

	 mov	 esi,[ebp].ID_CINS ; Get current instruction offset
	 dec	 esi		; Back off one byte
	 lods	 fs:[esi].LO	; Get next instruction byte

	 pop	 esi		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_LBYTE endp			; End GET_LBYTE procedure
	 NPPROC  GET_IBYTE -- Get Next Byte From Instruction Stream
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get next byte from the instruction stream.

On exit:

AL	 =	 next byte
ID_CINS  =	 updated

|

	 push	 esi		; Save for a moment

	 mov	 esi,[ebp].ID_CINS ; Get current instruction offset
	 lods	 fs:[esi].LO	; Get next instruction byte
	 mov	 [ebp].ID_CINS,esi ; Save for next time

	 pop	 esi		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_IBYTE endp			; End GET_IBYTE procedure
	 NPPROC  GET_IWORD -- Get Next Word From Instruction Stream
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get next word from the instruction stream.

On exit:

AX	 =	 next word
ID_CINS  =	 updated

|

	 push	 esi		; Save for a moment

	 mov	 esi,[ebp].ID_CINS ; Get current instruction offset
	 lods	 fs:[esi].ELO	; Get next instruction word
	 mov	 [ebp].ID_CINS,esi ; Save for next time

	 pop	 esi		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_IWORD endp			; End GET_IWORD procedure
	 NPPROC  GET_IDWORD -- Get Next Dword From Instruction Stream
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get next dword from the instruction stream.

On exit:

EAX	 =	 next dword
ID_CINS  =	 updated

|

	 push	 esi		; Save for a moment

	 mov	 esi,[ebp].ID_CINS ; Get current instruction offset
	 lods	 fs:[esi].EDD	; Get next instruction dword
	 mov	 [ebp].ID_CINS,esi ; Save for next time

	 pop	 esi		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_IDWORD endp 		; End GET_IDWORD procedure
	 NPPROC  GET_MODRM -- Get MOD/RM Byte
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return MOD/RM byte in AL.

On entry:

ES:EDI	 ==>	 output stream

On exit:

AL	 =	 MOD R/M byte

|

	 mov	 al,[ebp].ID_MODRM ; Assume MOD/RM byte found

	 test	 [ebp].ID_FLAG,@FLAG_MODRM ; MOD/RM byte found as yet?
	 jnz	 short GET_MODRM_EXIT ; Yes

	 call	 GET_IBYTE	; AL = next byte from instruction stream

	 mov	 [ebp].ID_MODRM,al ; Save for next time
	 or	 [ebp].ID_FLAG,@FLAG_MODRM ; Mark as found

	 test	 [ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	 jz	 short GET_MODRM_EXIT ; Not this time

	 mov	 es:[edi].OPER1_MODRM,al ; Save in data structure
	 or	 es:[edi].OPER1_FLAG,@OPER_MRM ; Mark as present
GET_MODRM_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_MODRM endp			; End GET_MODRM procedure
	 NPPROC  FILL_OPCODE -- Fill Out Opcode Text
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill out opcode text with blanks.

On entry:

ECX	 =	 starting offset
ES:EDI	 ==>	 output stream

On exit:

ES:EDI	 ==>	 output stream, updated

|

	 REGSAVE <eax,ecx>	; Save registers

; Already filled out or operand analysis in effect?

	 test	 [ebp].ID_FLAG,@FLAG_FILL or @FLAG_OPER ; Check 'em
	 jnz	 short FILL_OPCODE_EXIT ; Yes, no need to fill again

	 cmp	 es:[edi-1].LO,',' ; End with a comma?
	 je	 short FILL_OPCODE_DONE ; Yes, no need to fill out

	 sub	 ecx,edi	; Less current offset
	 add	 ecx,@FILL_OPCODE ; Plus pad amount
	 jnc	 short FILL_OPCODE_EXIT ; Jump if already longer

	 mov	 al,' '         ; Fill with blanks
     rep stos	 es:[edi].LO	; Fill it up
FILL_OPCODE_DONE:
	 or	 [ebp].ID_FLAG,@FLAG_FILL ; Mark as filled out
FILL_OPCODE_EXIT:
	 REGREST <ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_OPCODE endp		; End FILL_OPCODE procedure
	 NPPROC  DISP_COMMA -- Display Comma Separator If Appropriate
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display comma separator if appropriate

On entry:

ES:EDI	 ==>	 output stream

On exit:

ES:EDI	 ==>	 output stream, updated

|

; See if we should display a comma

	 cmp	 es:[edi-1].LO,',' ; Last character a comma?
	 je	 short DISP_COMMA_EXIT ; Yes, no need for two of them

	 cmp	 es:[edi-1].LO,'[' ; Last character a left bracket?
	 je	 short DISP_COMMA_EXIT ; Yes, no need for a comma

	 cmp	 [ebp].ID_NCOMP,1 ; Displayed components beyond opcode?
	 jbe	 short DISP_COMMA_EXIT ; No, so this is the first component

	 test	 [ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	 jnz	 short DISP_COMMA_EXIT ; Yes, skip this

	 push	 eax		; Save for a moment

	 mov	 al,','         ; Separator
S32	 stos	 es:[edi].LO	; Save in output stream

	 pop	 eax		; Restore
DISP_COMMA_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_COMMA endp 		; End DISP_COMMA procedure
	 NPPROC  DISP_PLUS -- Display Plus Sign IF Appropriate
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display plus sign if appropriate.

On entry:

ES:EDI	 ==>	 output stream

On exit:

ES:EDI	 ==>	 output stream, updated

|

	 test	 [ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	 jnz	 short DISP_PLUS_EXIT ; Yes, skip this

	 cmp	 es:[edi-1].LO,'[' ; Still at the start?
	 je	 short DISP_PLUS_EXIT ; Yes, no need for a separator

	 push	 eax		; Save for a moment

	 mov	 al,'+'         ; Separator
S32	 stos	 es:[edi].LO	; Save in output stream

	 pop	 eax		; Restore
DISP_PLUS_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_PLUS endp			; End DISP_PLUS procedure
	 NPPROC  DISP_SRO -- Display Any Segment Register Overrides
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display any segment register overrides

On entry:

ES:EDI	 ==>	 output stream

On exit:

ES:EDI	 ==>	 output stream, updated

CF	 =	 0 All went OK
	 =	 1 multiple segment register overrides

|

	 REGSAVE <eax,esi>	; Save registers

	 mov	 ax,[ebp].ID_PDEF ; Get prefix flags

	 and	 eax,@PREF_SREG ; Isolate segment register prefixes
	 jz	 short DISP_SRO_EXIT ; None this time

; Ensure only one bit set

	 mov	 esi,eax	; Copy for destructive testing
	 dec	 esi		; Less one to get trailing 1's
	 and	 esi,eax	; If only bit set, should be zero
	 stc			; In case it's not
	 jnz	 short DISP_SRO_EXIT ; Jump if multiple overrides

	 or	 [ebp].ID_FLAG,@FLAG_SREG ; Segment register used

	 test	 [ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	 jz	 short @F	; Not this time

	 bsf	 eax,eax	; Translate into bit index
	 mov	 es:[edi].OPER1_SEG,al ; Save as segment register #
	 or	 es:[edi].OPER1_FLAG,@OPER_SEG ; Mark as present

	 jmp	 short DISP_SRO_CLC ; Join common exit code

@@:
	 bsf	 esi,eax	; Put index of low-order 1-bit from AX into SI
	 lea	 esi,SREG[esi*2] ; DS:ESI ==> segment register name
S32	 movs	 <es:[edi].ELO,ds:[esi].ELO> ; Copy it to output stream

	 mov	 al,':'         ; Separator
S32	 stos	 es:[edi].LO	; Save in output stream
DISP_SRO_CLC:
	 clc			; Indicate all went well
DISP_SRO_EXIT:
	 REGREST <esi,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_SRO endp			; End DISP_SRO procedure
	 NPPROC  DISP_SIGN -- Display Sign Extension
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display and check for sign extension of AL.

On entry:

AL	 =	 value to sign-extend
ES:EDI	 ==>	 output stream

On exit:

AL	 =	 value negated if sign bit set
AH	 =	 destroyed
ES:EDI	 ==>	 output stream

|

	 mov	 ah,'+'         ; Separator if positive

	 cmp	 al,80h 	; Check for negative
	 jb	 short DISP_SIGN_EXIT ; It's positive

	 mov	 ah,'-'         ; Separator for negative
	 neg	 al		; Negate to subtract
DISP_SIGN_EXIT:
	 mov	 es:[edi],ah	; Save in output stream
	 inc	 edi		; Skip to next character

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_SIGN endp			; End DISP_SIGN procedure
	 NPPROC  COPY_ASCIIZ -- Copy ASCIIZ String
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy the ASCIIZ string at DS:ESI to ES:EDI

On entry:

DF	 =	 as set by caller
DS:ESI	 ==>	 ASCIIZ string
ES:EDI	 ==>	 output stream

On exit:

DS:ESI	 ==>	 ASCIIZ string, updated
ES:EDI	 ==>	 output stream, updated

|

	 push	 eax		; Save for a moment

	 test	 [ebp].ID_FLAG,@FLAG_OPER ; Operand analysis in effect?
	 jnz	 short COPY_ASCIIZ_EXIT ; Yes, skip this
COPY_ASCIIZ_NEXT:
	 lods	 ds:[esi].LO	; Get next character

	 and	 al,al		; Izit the end?
	 jz	 short COPY_ASCIIZ_EXIT ; Yes

S32	 stos	 es:[edi].LO	; Save in output stream

	 jmp	 short COPY_ASCIIZ_NEXT ; Go around again

COPY_ASCIIZ_EXIT:
	 pop	 eax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COPY_ASCIIZ endp		; End COPY_ASCIIZ procedure
	 NPPROC  DG2HEX -- Convert Low-order Digit in AL to Hex At ES:EDI
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 push	 ecx		; Save for a moment
	 mov	 ecx,1		; # hex digits
	 call	 BIN2HEX_SUB	; Handle by subroutine
	 pop	 ecx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DG2HEX	 endp			; End DG2HEX procedure
	 NPPROC  DB2HEX -- Convert AL to Hex At ES:EDI
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 push	 ecx		; Save for a moment
	 mov	 ecx,2		; # hex digits
	 call	 BIN2HEX_SUB	; Handle by subroutine
	 pop	 ecx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DB2HEX	 endp			; End DB2HEX procedure
	 NPPROC  DW2HEX -- Convert AX to Hex At ES:EDI
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 push	 ecx		; Save for a moment
	 mov	 ecx,4		; # hex digits
	 call	 BIN2HEX_SUB	; Handle by subroutine
	 pop	 ecx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DW2HEX	 endp			; End DW2HEX procedure
	 NPPROC  DD2HEX -- Convert EAX to Hex At ES:EDI
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 push	 ecx		; Save for a moment
	 mov	 ecx,8		; # hex digits
	 call	 BIN2HEX_SUB	; Handle by subroutine
	 pop	 ecx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DD2HEX	 endp			; End DD2HEX procedure
	 NPPROC  BIN2HEX_SUB
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <eax,ebx,edx>	; Save registers

	 pushfd 		; Save flags
	 std			; Store backwards

	 mov	 edx,eax	; Copy to secondary register
	 lea	 ebx,NUMBERS_HI ; XLAT table
	 add	 edi,ecx	; Skip to the end+1

	 push	 edi		; Save to return

	 dec	 edi		; Now the last digit
BIN2HEX_MORE:
	 mov	 al,dl		; Copy to XLAT register
	 and	 al,0Fh 	; Isolate low-order digit
	 xlat	 NUMBERS_HI[ebx] ; Convert to ASCII hex
S32	 stos	 es:[edi].LO	; Save in output stream

	 shr	 edx,4		; Shift next digit down to low-order

	 loop	 BIN2HEX_MORE	; Jump if more digits to format

	 pop	 edi		; Restore

	 popfd			; Restore flags

	 REGREST <edx,ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2HEX_SUB endp		; End BIN2HEX_SUB procedure

PROG	 ends			; End PROG segment

	 MEND			; End INT1_MSC module
