;' $Header:   P:/PVCS/386SWAT/SWAT_AGR.ASV   1.1   01 Jul 1997 17:46:20   BOB  $
	 title	 SWAT_AGR -- 386SWAT Address Goto/Return Functions
	 page	 58,122
	 name	 SWAT_AGR

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.


|
.386p
.xlist
	 include MASM.INC
	 include PTR.INC
	 include 386.INC
	 include ALLMEM.INC
	 include OPCODES.INC
	 include IOPBITS.INC
	 include INTVEC.INC

	 include SWAT_CMD.INC
	 include SWAT_MOD.INC
	 include SWAT_SEG.INC
.list

DATA	 segment use32 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 UNABASE:dword
	 extrn	 UNAMODE:word
	 extrn	 UNAOFF:dword
	 extrn	 UNACR3:dword

DATA	 ends			; End DATA segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 SWATINI:tbyte
	 include MAXDEV.INC

	 extrn	 GETBASE:near
	 extrn	 GETARW:near
	 extrn	 GETCGSEL:near
	 extrn	 GETCGOFF:near

	 extrn	 DISPPHYS:near
	 extrn	 DISPVIRT:near

	 NPPROC  DECODE_ADDR -- Decode Instruction Target Address
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Decode instruction target address

If the instruction is of the form

CALL rel16	    E8 cw
     rel32	 66 E8 cw
     ptr16:16	    9A cd
     ptr16:32	 66 9A cp
     r/m16	 2E FF /2 Ev	with CS override and immediate displacement
     r/m32    66 2E FF /2 Ev	...
     m16:16	 2E FF /3 Ep	...
     m16:32   66 2E FF /3 Ep	...

JMP  rel8	    EB cb
     rel16	    E9 cw
     rel32	 66 E9 cd
     ptr16:16	    EA cd
     ptr16:32	 66 EA cp
     r/m16	 2E FF /4 Ev	with CS override and immediate displacement
     r/m32    66 2E FF /4 Ev	...
     m16:16	 2E FF /5 Ep	...
     m16:32   66 2E FF /5 Ep	...

LOOP   rel8	    E2 cb	possibly with preceding ASP
LOOPE  rel8	    E1 cb	...
LOOPNE rel8	    E0 cb	...

JCXZ rel8	    E3 cb	Possibly with preceding ASP

Jcc  rel8	    7x cb
     rel16	 0F 8x cw
     rel32    66 0F 8x cd

INT  xx

On entry:

ESI	 =	 linear address of instruction to decode

On exit:

CF	 =	 0 if instruction has a valid address
	 =	 1 if not

If valid,

BX	 =	 segment/selector (if @ADDR_SEP)
EAX	 =	 offset
CX	 =	 flags
EDX	 =	 address base	  (if @ADDR_SEP)

|

	 REGSAVE <esi>		; Save register

@FLAG_CS equ	 0001h		; CS override
@FLAG_OSP equ	 0002h		; OSP ...
@FLAG_USE32 equ  0004h		; USE32 in effect

	 xor	 dx,dx		; Initialize flags

	 test	 UNAMODE,@MODE_USE32 ; Izit USE32 segment?
	 jz	 short @F	; Jum if not

	 or	 dx,@FLAG_USE32 ; Mark as such
@@:

	 test	 UNAMODE,@MODE_PHYS ; Izit a physical translation?
	 jz	 short @F	; Jump if not

	 push	 UNACR3 	; Pass new CR3 to use (if non-zero)
	 push	 UNABASE	; Pass base memory to use
	 push	 UNAOFF 	; Pass memory offset to use
	 call	 DISPPHYS	; Setup for physical memory unassemble
@@:

; Decode the instruction

DECODE_ADDR_NEXT:
	 lods	 AGROUP:[esi].LO ; Get next instruction byte

	 cmp	 al,@OPCOD_ASP	; Izit an ASP?
	 jne	 short @F	; Jump if not

;;;;;;;; xor	 dx,@FLAG_ASP	; Toggle ASP state

	 jmp	 short DECODE_ADDR_NEXT ; Go around again

@@:
	 cmp	 al,@OPCOD_OSP	; Izit an OSP?
	 jne	 short @F	; Jump if not

	 xor	 dx,@FLAG_USE32 ; Toggle USE32 state

	 jmp	 short DECODE_ADDR_NEXT ; Go around again

@@:
	 cmp	 al,@OPCOD_CS	; Izit CS override?
	 jne	 short @F	; Jump if not

	 or	 dx,@FLAG_CS	; Mark as such

	 jmp	 short DECODE_ADDR_NEXT ; Go around again

@@:
	 cmp	 al,@OPCOD_LOOP ; Izit a rel8 jump?
	 je	 near ptr DECODE_ADDR_REL8 ; Jump if so

	 cmp	 al,@OPCOD_LOOPE ; Izit a rel8 jump?
	 je	 near ptr DECODE_ADDR_REL8 ; Jump if so

	 cmp	 al,@OPCOD_LOOPNE ; Izit a rel8 jump?
	 je	 near ptr DECODE_ADDR_REL8 ; Jump if so

	 cmp	 al,@OPCOD_JMPS ; Izit a rel8 jump?
	 je	 near ptr DECODE_ADDR_REL8 ; Jump if so

	 cmp	 al,@OPCOD_JCXZ ; Izit a rel8 jump?
	 je	 near ptr DECODE_ADDR_REL8 ; Jump if so

	 cmp	 al,@OPCOD_CALLN ; Izit a rel16 call?
	 je	 near ptr DECODE_ADDR_REL16 ; Jump if so

	 cmp	 al,@OPCOD_JMPN ; Izit a rel16 jump?
	 je	 near ptr DECODE_ADDR_REL16 ; Jump if so

	 cmp	 al,@OPCOD_JCCLO ; Izit Jcc rel8?
	 jb	 short @F	; Jump if not

	 cmp	 al,@OPCOD_JCCHI ; Check against upper limit?
	 jbe	 near ptr DECODE_ADDR_REL8 ; Jump if within range
@@:
	 test	 dx,@FLAG_USE32 ; Izit a USE32 instruction?
	 jz	 short @F	; Jump if not

	 cmp	 al,@OPCOD_JMPF ; Izit a ptr16:32 jump?
	 je	 near ptr DECODE_ADDR_CP ; Jump if so

	 cmp	 al,@OPCOD_CALLF ; Izit a ptr16:32 call?
	 je	 near ptr DECODE_ADDR_CP ; Jump if so
@@:
	 cmp	 al,@OPCOD_JMPF ; Izit a ptr16:16 jump?
	 je	 near ptr DECODE_ADDR_CD ; Jump if so

	 cmp	 al,@OPCOD_CALLF ; Izit a ptr16:16 call?
	 je	 near ptr DECODE_ADDR_CD ; Jump if so

	 cmp	 al,@OPCOD_2ND	; Izit secondary opcode?
	 je	 near ptr DECODE_ADDR_2ND ; Jump if so

	 cmp	 al,@OPCOD_GRP5 ; Izit Group 5 instruction?
	 je	 short DECODE_ADDR_GRP5 ; Jump if so

	 cmp	 al,@OPCOD_INT	; Izit an INT?
	 je	 short DECODE_ADDR_INT ; Jump if so

	 cmp	 al,@OPCOD_INT3 ; Izit an INT 03h?
	 je	 short DECODE_ADDR_INT3 ; Jump if so

	 cmp	 al,@OPCOD_INTO ; Izit an INTO?
	 je	 short DECODE_ADDR_INTO ; Jump if so

	 jmp	 DECODE_ADDR_ERR ; Join common error code


; Instruction is of the form INT 03h

DECODE_ADDR_INT3:
	 mov	 al,03h 	; Get the interrupt #

	 jmp	 short DECODE_ADDR_INTCOM ; Join common code


; Instruction is of the form INTO

DECODE_ADDR_INTO:
	 mov	 al,04h 	; Get the interrupt #

	 jmp	 short DECODE_ADDR_INTCOM ; Join common code


; Instruction is of the form INT xx

DECODE_ADDR_INT:
	 lods	 AGROUP:[esi].LO ; Get next instruction byte (INT #)
DECODE_ADDR_INTCOM:
	 movzx	 eax,al 	; Zero-extend to use as dword

	 test	 UNAMODE,@MODE_VM ; Izit VM86 mode?
	 jz	 short DECODE_ADDR_INTPM ; Jump if not

	 mov	 bx,AGROUP:[eax*(type INT00_VEC)].VSEG ; Get the VM segment
	 movzx	 eax,AGROUP:[eax*(type INT00_VEC)].VOFF ; ...	     offset

	 jmp	 DECODE_ADDR_CDCP ; Join common code

DECODE_ADDR_INTPM:
	 sub	 esp,size DTR_STR ; Make room on stack
	 SIDTD	 [esp].EDF	; Save IDTR on stack
	 mov	 edx,[esp].DTR_BASE ; AGROUP:EDX ==> IDT
	 add	 esp,size DTR_STR ; Strip from stack
	 lea	 edx,AGROUP:[edx+eax*(type IDT_STR)] ; Skip to INT #

	 mov	 bx,AGROUP:[edx].IDT_SELECT ; Get the IDT selector
	 mov	 ax,AGROUP:[edx].IDT_OFFHI ; Get high-order offset
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,AGROUP:[edx].IDT_OFFLO ; Get low-order offset

	 jmp	 DECODE_ADDR_CDCP ; Join common code


; Instruction is of the form FF ...

DECODE_ADDR_GRP5:

; Check for CS override (the only case we handle)
; unless it's Windows in which case we use a selector
; with base of zero.

	 test	 dx,@FLAG_CS	; Is CS override in effect for the instruction?
	 jnz	 short @F	; Jump if so

	 test	 UNAMODE,@MODE_VM ; Izit VM 8086?
	 jnz	 near ptr DECODE_ADDR_ERR ; Jump if so

	 test	 SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	 jz	 near ptr DECODE_ADDR_ERR ; Jump if not
@@:

; Check for CS USE16 immediate displacement (MOD=00, RM=110),
; or	    CS USE32 ...		    (MOD=00, RM=101),
; and Near Call (REG=010) or Far Call (REG=011)
; or  Near Jmp	(REG=100) or Far Jmp  (REG=101)

	 lods	 AGROUP:[esi].LO ; Get next instruction byte
	 mov	 ah,al		; Copy for destructive testing
	 and	 ah,(mask $MOD) or (mask $RM) ; Isolate MOD and RM bits

	 test	 UNAMODE,@MODE_USE32 ; Is USE32 in effect for CS?
	 jnz	 short @F	; Jump if so

	 cmp	 ah,(00b shl $MOD) or (110b shl $RM) ; Izit MOD=00 and RM=110?
	 je	 short DECODE_ADDR_GRP5COM ; Jump if so

	 jmp	 DECODE_ADDR_ERR ; Join common error code

@@:
	 cmp	 ah,(00b shl $MOD) or (101b shl $RM) ; Izit MOD=00 and RM=101?
	 jne	 near ptr DECODE_ADDR_ERR ; Jump if not

; Split cases of REG=010 (Call Ev),
;		 REG=011 (Call Ep),
;		 REG=100 (Jmp  Ev),
;		 REG=101 (Jmp  Ep)

DECODE_ADDR_GRP5COM:
	 and	 al,mask $REG	; Isolate REG bits

	 cmp	 al,010b shl $REG ; Izit REG=010?
	 je	 short DECODE_ADDR_EV ; Jump if so

	 cmp	 al,011b shl $REG ; Izit REG=011?
	 je	 short DECODE_ADDR_EP ; Jump if so

	 cmp	 al,100b shl $REG ; Izit REG=100?
	 je	 short DECODE_ADDR_EV ; Jump if so

	 cmp	 al,101b shl $REG ; Izit REG=101?
	 je	 short DECODE_ADDR_EP ; Jump if so

	 jmp	 DECODE_ADDR_ERR ; Join common error code


; Instruction is of the form Near Jmp/Call Word/Dword ptr CS:[Disp16/Disp32]

; The state of @FLAG_USE32 controls Word   vs. Dword
; ...	       @MODE_USE32 ...	    Disp16 vs. Disp32

DECODE_ADDR_EV:
	 test	 UNAMODE,@MODE_USE32 ; Is USE32 in effect for CS?
	 jz	 short @F	; Jump if not

	 lods	 AGROUP:[esi].EDD ; Get next instruction dword (offset)

	 jmp	 short DECODE_ADDR_EVCOM ; Join common code

@@:
	 lods	 AGROUP:[esi].ELO ; Get next instruction word (offset)
	 movzx	 eax,ax 	; Zero-extend to use as dword
DECODE_ADDR_EVCOM:

; Get the word/dword from UNABASE+EAX as the new eIP
; Note that UNABASE is the base for the disassembled CS which
; is required to be the segment override

	 add	 eax,UNABASE	; Add to get 32-bit linear address

	 test	 UNAMODE,@MODE_VM ; Izit VM 8086?
	 jnz	 short @F	; Jump if so

	 test	 SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	 jz	 short @F	; Jump if not

	 sub	 eax,UNABASE	; Subtract to use zero-based code selector
@@:
	 xor	 cx,cx		; Clear flags

	 test	 dx,@FLAG_USE32 ; Is USE32 in effect for the instruction?
	 jz	 short @F	; Jump if not

	 mov	 eax,AGROUP:[eax].EDD ; Get dword from code segment

	 jmp	 DECODE_ADDR_CLC ; Join common OK code

@@:
	 movzx	 eax,AGROUP:[eax].ELO ; Get word from code segment

	 jmp	 DECODE_ADDR_CLC ; Join common OK code


; Instruction is of the form Far Jmp/Call Dword/Fword ptr CS:[Disp16/Disp32]

; The state of @FLAG_USE32 controls Dword  vs. Fword
; ...	       @MODE_USE32 ...	    Disp16 vs. Disp32

DECODE_ADDR_EP:
	 test	 UNAMODE,@MODE_USE32 ; Is USE32 in effect for CS?
	 jz	 short @F	; Jump if not

	 lods	 AGROUP:[esi].EDD ; Get next instruction dword (offset)

	 jmp	 short DECODE_ADDR_EPCOM ; Join common code

@@:
	 lods	 AGROUP:[esi].ELO ; Get next instruction word (offset)
	 movzx	 eax,ax 	; Zero-extend to use as dword
DECODE_ADDR_EPCOM:

; Get the Seg:Off from UNABASE+EAX as the new CS:eIP
; Note that UNABASE is the base for the disassembled CS which
; is required to be the segment override

	 add	 eax,UNABASE	; Add to get 32-bit linear address

	 test	 UNAMODE,@MODE_VM ; Izit VM 8086?
	 jnz	 short @F	; Jump if so

	 test	 SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	 jz	 short @F	; Jump if not

	 sub	 eax,UNABASE	; Subtract to use zero-based code selector
@@:
	 test	 dx,@FLAG_USE32 ; Is USE32 in effect for the instruction?
	 jz	 short @F	; Jump if not

	 mov	 bx,AGROUP:[eax].FSEL ; Get word from code segment (segment)
	 mov	 eax,AGROUP:[eax].FOFF ; Get dword from code segment (offset)

	 jmp	 short DECODE_ADDR_EPCOM1 ; Join common OK code

@@:
	 mov	 bx,AGROUP:[eax].VSEG ; Get word from code segment (segment)
	 movzx	 eax,AGROUP:[eax].VOFF ; Get word from code segment (offset)
DECODE_ADDR_EPCOM1:
	 jmp	 short DECODE_ADDR_CDCP ; Join common code


; Instruction is of the form 0F ...

DECODE_ADDR_2ND:
	 mov	 ah,al		; Copy 2ND
	 lods	 AGROUP:[esi].LO ; Get next instruction byte
	 xchg	 al,ah		; Swap to comparison order

	 cmp	 ax,@OPCOD_JCCLO2 ; Check against lower limit
	 jb	 near ptr DECODE_ADDR_ERR ; Jump if too small

	 cmp	 ax,@OPCOD_JCCHI2 ; Check against upper limit
	 ja	 near ptr DECODE_ADDR_ERR ; Jump if too large


; Instruction is of the form Jcc Rel16/Rel32
; depending upon @FLAG_USE32

DECODE_ADDR_REL16:
	 test	 dx,@FLAG_USE32 ; Is USE32 in effect for the instruction?
	 jnz	 short DECODE_ADDR_REL32A ; Jump if so
DECODE_ADDR_REL16A:
	 lods	 AGROUP:[esi].ELO ; Get next instruction word (rel16 value)
	 movsx	 eax,ax 	; Sign-extend to use as dword

	 jmp	 short DECODE_ADDR_RELCOM ; Join common rel code


; Instruction is of the form Jcc Rel32

DECODE_ADDR_REL32A:
	 lods	 AGROUP:[esi].EDD ; Get next instruction dword (rel32 value)

	 jmp	 short DECODE_ADDR_RELCOM ; Join common rel code


; Instruction is of the form Jcc Rel8

DECODE_ADDR_REL8:
	 lods	 AGROUP:[esi].LO ; Get next instruction byte (rel8 value)
	 movsx	 eax,al 	; Sign-extend to use as dword
DECODE_ADDR_RELCOM:
	 add	 eax,esi	; Plus next offset
	 sub	 eax,UNABASE	; Less instruction base to get offset

; If we're in a USE16 segment, simulate 64KB wrap

	 test	 UNAMODE,@MODE_USE32 ; Is USE32 in effect for CS?
	 jnz	 short @F	; Jump if so

	 movzx	 eax,ax 	; Zero high-order word
@@:
	 xor	 cx,cx		; Clear flags

	 jmp	 short DECODE_ADDR_CLC ; Join common OK code


; Instruction is of the form jmp/call ptr16:16

DECODE_ADDR_CD:
	 lods	 AGROUP:[esi].ELO ; Get next instruction word (offset)
	 movzx	 eax,ax 	; Zero-extend to use as dword

	 jmp	 short DECODE_ADDR_CP1 ; Join common code


; Instruction is of the form jmp/call ptr16:32

DECODE_ADDR_CP:
	 lods	 AGROUP:[esi].EDD ; Get next instruction dword (offset)
DECODE_ADDR_CP1:
	 push	 eax		; Save for a moment
	 lods	 AGROUP:[esi].ELO ; Get next instruction word (segment/selector)
	 mov	 bx,ax		; Copy to segment/selector register
	 pop	 eax		; Restore

; Set EDX as instruction base and CX as flags depending upon VM vs. PM mode

DECODE_ADDR_CDCP:
	 mov	 cx,@ADDR_SEP	; Mark as having separator

	 test	 UNAMODE,@MODE_VM ; Izit VM86 mode?
	 jz	 short DECODE_ADDR_CDCP1 ; Jump if not

	 movzx	 edx,bx 	; Copy segment, zero high-order word
	 shl	 edx,4-0	; Convert from paras to byets

	 jmp	 short DECODE_ADDR_CLC ; Join common OK code

DECODE_ADDR_CDCP1:
	 call	 SELOFF2ADDR	; Convert BX|EAX to address
				; Return with BX = selector
				; ...	     EAX = offset
				; ...	     EDX = selector base
				; ...	      CX = flags

	 jmp	 short DECODE_ADDR_CLC ; Join common OK code

DECODE_ADDR_ERR:
	 stc			; Indicate no immediate target

	 jmp	 short DECODE_ADDR_EXIT ; Join common exit code

DECODE_ADDR_CLC:
	 clc			; Indicate all went well
DECODE_ADDR_EXIT:
	 pushfd 		; Save flags (CF in particular)

	 test	 UNAMODE,@MODE_PHYS ; Izit in physical mode?
	 jz	 short @F	; Jump if not

	 call	 DISPVIRT	; Restore virtual mode display
@@:
	 popfd			; Restore

	 REGREST <esi>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DECODE_ADDR endp		; End DECODE_ADDR procedure
	 NPPROC  SELOFF2ADDR -- Convert Selector to Address
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT!

Convert a Sel|Off to an address through call/task gates and TSSs.

On entry:

BX	 =	 selector to convert
EAX	 =	 offset

On exit:

BX	 =	 resulting selector
EAX	 =	 offset
EDX	 =	 selector base
CX	 =	 flags

CF	 =	 0 if successful
	 =	 1 if bad selector

!


	 push	 eax		; Save offset for a moment

	 mov	 cx,@ADDR_SEP or @ADDR_PM ; Mark as PM, with separator
SELOFF2ADDR_NEXT:
	 push	 bx		; Pass selector
	 call	 GETARW 	; Return with AX = access rights word
	 jc	 near ptr SELOFF2ADDR_EXIT ; Jump on error (note CF=1)

	 and	 al,not (mask $DT_DPL) ; Clear DPL bits

; Check for call gate in BX in which case the code selector
; and offset are in the call gate DTE

	 cmp	 al,CPL0_CALL3	; Izit a 386 call gate?
	 je	 short SELOFF2ADDR_CG3 ; Jump if so

	 cmp	 al,CPL0_CALL2	; Izit a 286 call gate?
	 je	 short SELOFF2ADDR_CG2 ; Jump if so

; Check for task gate in BX in which case the code selector
; and offset are in the TSS

	 cmp	 al,CPL0_TASK	; Izit a task gate?
	 je	 short SELOFF2ADDR_TASK ; Jump if so

; Check for TSS in BX in which case the code selector
; and offset are in the TSS

	 cmp	 al,CPL0_BUSY3	; Izit a busy 386 TSS?
	 je	 short SELOFF2ADDR_TSS3 ; Jump if so

	 cmp	 al,CPL0_IDLE3	; Izit an idle 386 TSS?
	 je	 short SELOFF2ADDR_TSS3 ; Jump if so

	 cmp	 al,CPL0_BUSY2	; Izit a busy 286 TSS?
	 je	 short SELOFF2ADDR_TSS2 ; Jump if so

	 cmp	 al,CPL0_IDLE2	; Izit an idle 286 TSS?
	 jne	 short SELOFF2ADDR_DONE ; Jump if not

; It's a 286 TSS

SELOFF2ADDR_TSS2:
	 pop	 eax		; Restore offset (not used for TSSs)

; Get the TSS base

	 push	 bx		; Pass selector as argument
	 call	 GETBASE	; Return with EAX = selector base
	 jc	 near ptr SELOFF2ADDR_EXIT1 ; Jump on error (note CF=1)

	 mov	 bx,AGROUP:[eax].TSS2_CS ; Get code selector
	 movzx	 eax,AGROUP:[eax].TSS2_IP ; Get 16-bit offset

	 push	 eax		; Save offset for a moment

	 jmp	 short SELOFF2ADDR_DONE ; Join common done code


; It's a 386 TSS

SELOFF2ADDR_TSS3:
	 pop	 eax		; Restore offset (not used for TSSs)

; Get the TSS base

	 push	 bx		; Pass selector as argument
	 call	 GETBASE	; Return with EAX = selector base
	 jc	 short SELOFF2ADDR_EXIT1 ; Jump on error (note CF=1)

	 mov	 bx,AGROUP:[eax].TSS_CS ; Get code segment/selector

	 test	 AGROUP:[eax].TSS_EFL.EHI,mask $VM ; Izit in VM?
	 mov	 eax,AGROUP:[eax].TSS_EIP ; Get 32-bit offset
	 jz	 short @F	; Jump if not

	 and	 cx,not @ADDR_PM ; Mark as not in PM
	 or	 cx,@ADDR_CODE	; Mark as code segment
	 movzx	 edx,bx 	; Copy the segment
	 shl	 edx,4-0	; Convert from paras to bytes
@@:
	 push	 eax		; Save offset for a moment

	 jmp	 short SELOFF2ADDR_DONE ; Join common done code


; It's a task gate

SELOFF2ADDR_TASK:
	 push	 bx		; Pass selector
	 call	 GETCGSEL	; Return with AX = task gate TSS selector
	 jc	 short SELOFF2ADDR_EXIT ; Jump on error (note CF=1)

	 mov	 bx,ax		; Copy to selector register

	 jmp	 SELOFF2ADDR_NEXT ; Go around again


; It's a 286/386 call gate

SELOFF2ADDR_CG2:
SELOFF2ADDR_CG3:
	 pop	 eax		; Restore offset (not used for call gates)

; BX has the call gate selector

	 push	 bx		; Pass selector
	 call	 GETCGOFF	; Return with EAX = call gate code offset
	 jc	 short SELOFF2ADDR_EXIT1 ; Jump on error (note CF=1)

	 push	 eax		; Save offset for a moment

	 push	 bx		; Pass selector
	 call	 GETCGSEL	; Return with AX = call gate code selector
	 jc	 short SELOFF2ADDR_EXIT ; Jump on error (note CF=1)

	 mov	 bx,ax		; Copy to return register

;;;;;;;; jmp	 short SELOFF2ADDR_DONE ; Join common done code

SELOFF2ADDR_DONE:
	 test	 cx,@ADDR_PM	; Izit in PM?
	 jz	 short SELOFF2ADDR_EXIT ; Jump if not (note CF=0)

; Check for big and/or code selector in BX

	 push	 bx		; Pass selector
	 call	 GETARW 	; Return with AX = access rights word
	 jc	 short SELOFF2ADDR_EXIT ; Jump on error (note CF=1)

	 test	 ah,mask $DTE_B ; Izit a big selector?
	 jz	 short @F	; Jump if not

	 or	 cx,@ADDR_USE32 ; Mark as big selector
@@:
	 and	 al,(mask $DT_DC) or (mask $DC_COD) ; Isolate bits

	 cmp	 al,(mask $DT_DC) or (mask $DC_COD) ; Izit code?
	 jne	 short @F      ; Jump if not

	 or	 cx,@ADDR_CODE	; Mark as code selector
@@:
	 push	 bx		; Pass selector
	 call	 GETBASE	; Return with EAX = selector base
	 jc	 short SELOFF2ADDR_EXIT ; Jump on error (note CF=1)

	 mov	 edx,eax	; Copy to return register
SELOFF2ADDR_EXIT:
	 pop	 eax		; Restore
SELOFF2ADDR_EXIT1:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SELOFF2ADDR endp		; End SELOFF2ADDR procedure
	 NPPROC  SEL2TSS -- Convert Selector to TSS
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT!

Convert a Sel to a TSS selector through task gates.

On entry:

BX	 =	 selector to convert

On exit:

BX	 =	 resulting TSS selector
EDX	 =	 selector base
CX	 =	 flags

CF	 =	 0 if all went OK
	 =	 1 otherwise

!


	 push	 eax		; Save for a moment

	 mov	 cx,@ADDR_SEP or @ADDR_PM ; Mark as PM, with separator
SEL2TSS_NEXT:
	 push	 bx		; Pass selector
	 call	 GETARW 	; Return with AX = access rights word
	 jc	 short SEL2TSS_EXIT ; Jump if something went wrong (note CF=1)

	 and	 al,not (mask $DT_DPL) ; Clear DPL bits

; Check for TSS in BX in which case the code selector
; and offset are in the TSS

	 cmp	 al,CPL0_BUSY3	; Izit a busy 386 TSS?
	 je	 short SEL2TSS_DONE ; Jump if so

	 cmp	 al,CPL0_IDLE3	; Izit an idle 386 TSS?
	 je	 short SEL2TSS_DONE ; Jump if so

	 cmp	 al,CPL0_BUSY2	; Izit a busy 286 TSS?
	 je	 short SEL2TSS_DONE ; Jump if so

	 cmp	 al,CPL0_IDLE2	; Izit an idle 286 TSS?
	 je	 short SEL2TSS_DONE ; Jump if so

; Check for task gate in BX in which case the TSS selector
; is in the task gate

	 cmp	 al,CPL0_TASK	; Izit a task gate?
	 jne	 short SEL2TSS_ERR ; Jump if not

; It's a task gate

	 push	 bx		; Pass selector
	 call	 GETCGSEL	; Return with AX = task gate TSS selector
	 jc	 short SEL2TSS_ERR ; Jump if something went wrong

	 mov	 bx,ax		; Copy to selector register
SEL2TSS_DONE:

; Check for big and/or code selector in BX

	 push	 bx		; Pass selector
	 call	 GETARW 	; Return with AX = access rights word
	 jc	 short SEL2TSS_ERR ; Jump if something went wrong

	 test	 ah,mask $DTE_B ; Izit a big selector?
	 jz	 short @F	; Jump if not

	 or	 cx,@ADDR_USE32 ; Mark as big selector
@@:
	 and	 al,(mask $DT_DC) or (mask $DC_COD) ; Isolate bits

	 cmp	 al,(mask $DT_DC) or (mask $DC_COD) ; Izit code?
	 jne	 short @F      ; Jump if not

	 or	 cx,@ADDR_CODE	; Mark as code selector
@@:
SEL2TSS_DONE1:
	 push	 bx		; Pass selector
	 call	 GETBASE	; Return with EAX = selector base
;;;;;;;; jc	 short ???	; Ignore error return
	 mov	 edx,eax	; Copy to return register

	 clc			; Mark as successful

	 jmp	 short SEL2TSS_EXIT ; Join common exit code

SEL2TSS_ERR:
	 stc			; Mark as in error
SEL2TSS_EXIT:
	 pop	 eax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SEL2TSS  endp			; End SEL2TSS procedure

PROG	 ends			; End PROG segment

	 MEND			; End SWAT_AGR module
