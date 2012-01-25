;' $Header:   P:/PVCS/386SWAT/SWAT_UNA.ASV   1.14   10 Jul 1997 14:47:52   BOB  $
	 title	 SWAT_UNA -- 386SWAT Unassemble Command Functions
	 page	 58,122
	 name	 SWAT_UNA

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

	 include SWAT_CMD.INC
	 include SWAT_COM.INC
	 include SWAT_MOD.INC
	 include SWAT_SEG.INC
.list

DATA16	 segment use32 dword public 'data' ; Start DATA16 segment
	 assume  ds:DGROUP

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

DATA16	 ends			; End DATA16 segment


DATA	 segment use32 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 MSGOFF:dword
	 extrn	 SYNTERR:byte
	 extrn	 OVFERR:byte

	 extrn	 DSP_STATE:byte
	 extrn	 DSP_STAT2:byte

	 extrn	 INSTRPDN:dword

	 public  UNAMASK,UNABASE,UNAOFF,UNACR3,UNAMODE,UNASEL ; See SWAT_MOD.INC for equates
UNAMASK  dd	 0000FFFFh	; Upper limit for VM
UNABASE  dd	 ?		; Linear address of segment/selector base
UNAOFF	 dd	 ?		; Offset of displayed instruction
UNACR3	 dd	 ?		; CR3 to use in physical memory translation
UNAMODE  dw	 @MODE_VM	; Unassembly mode
UNASEL	 dw	 ?		; Selector ...

DATA	 ends			; End DATA segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 extrn	 CMD_WHITE:near
	 extrn	 PARSE_ADDR:near
	 extrn	 PARSE_EXPR:near
	 extrn	 GET_LASTPLEN:near
	 extrn	 GETARW:near
	 extrn	 SELOFF2ADDR:near

	 NPPROC  CMD_UNASM16 -- Unassemble USE16 Code Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Unassemble USE16 code command

U16 opt_addr
U16 addr P
U16 addr P exp

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 and	 UNAMODE,not @MODE_USE32 ; Mark as USE16 segment

	 jmp	 short CMD_UNASM32A ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_UNASM16 endp		; End CMD_UNASM16 procedure
	 NPPROC  CMD_UNASM32 -- Unassemble USE32 Code Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Unassemble USE32 code command

U32 opt_addr
U32 addr P
U32 addr P exp

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 or	 UNAMODE,@MODE_USE32 ; Mark as USE32 segment
CMD_UNASM32A:
	 or	 UNAMODE,@MODE_NEW ; Mark as new mode

	 jmp	 short CMD_UNASM0 ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_UNASM32 endp		; End CMD_UNASM32 procedure
	 NPPROC  CMD_UNASM -- Unassemble Code Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Unassemble code command

Ux-
Ux opt_addr
Ux addr P
Ux addr P exp

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 and	 UNAMODE,not @MODE_NEW ; Mark as not new mode
CMD_UNASM0:

; Split off backwards disassembly case

	 cmp	 DGROUP:[esi].LO,'-' ; Izit backwards?
	 je	 near ptr CMD_UNASMBACK ; Jump if so

	 REGSAVE <eax,ebx,ecx,edx> ; Save registers

	 REGSAVE <UNAMODE,UNAOFF,UNASEL,UNABASE,UNAMASK> ; Save values

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 near ptr CMD_UNASM_PGDN ; Yes, treat as page down

	 call	 PARSE_ADDR	; Parse DS:ESI for address
	 jc	 near ptr CMD_UNASM_ERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

	 test	 cx,@ADDR_SEP	; Separator specified?
	 jz	 short @F	; Not this time

	 test	 cx,@ADDR_PM	; Izit in PM?
	 jz	 short @F	; Not this time

	 call	 SELOFF2ADDR	; Convert BX|EAX to address
				; Return with BX = selector
				; ...	     EAX = offset
				; ...	     EDX = selector base
				; ...	      CX = flags
@@:
	 mov	 UNAOFF,eax	; Save for display purposes

	 and	 UNAMODE,not @MODE_PHYS ; Mark as no physical translation

; Check for optional physical marker

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 or	 al,20h 	; Convert to lowercase

	 cmp	 al,'p'         ; Izit physical marker?
	 jne	 short CMD_UNASM1A ; Jump if not

	 inc	 esi		; Skip over it
	 or	 UNAMODE,@MODE_PHYS ; Mark as physical translation
	 mov	 UNACR3,0	; Assume one-to-one translation

; Check for optional CR3

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 short CMD_UNASM2A ; Jump if so

; Parse CR3 value for translation

	 call	 PARSE_EXPR	; Parse command line for an expression
	 jc	 near ptr CMD_UNASM_ERR ; Jump if too large

	 and	 ax,mask $PTE_FRM ; Isolate 4KB frame
	 mov	 UNACR3,eax	; Save as CR3 for translation
CMD_UNASM1A:

; Ensure nothing more on the line

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 jne	 near ptr CMD_UNASM_SYNTERR ; No, so that's an error
CMD_UNASM2A:
	 test	 cx,@ADDR_SEP	; Separator specified?
	 jz	 near ptr CMD_UNASM2 ; Not this time

	 mov	 UNABASE,edx	; Save as linear address of segment/selector base
	 xchg	 bx,UNASEL	; Save for display purposes

	 and	 UNAMODE,not @MODE_VM ; Mark as protected mode
	 mov	 UNAMASK,0FFFFFFFFh ; Use all 32 bits

	 test	 cx,@ADDR_PM	; Check mode
	 jnz	 short CMD_UNASM1 ; Jump if PM

	 or	 UNAMODE,@MODE_VM ; Mark as VM86 mode
	 mov	 UNAMASK,0000FFFFh ; Use low-order 16 bits

	 test	 UNAMODE,@MODE_NEW ; Izit a new mode?
	 jnz	 short CMD_UNASM2 ; Jump if so

	 and	 UNAMODE,not @MODE_USE32 ; Mark as USE16 segment

	 jmp	 short CMD_UNASM2 ; Join common code

CMD_UNASM1:
	 test	 UNAMODE,@MODE_NEW ; Izit a new mode?
	 jnz	 short CMD_UNASM2 ; Jump if so

	 cmp	 bx,UNASEL	; Same selector as last time?
	 je	 short CMD_UNASM2 ; Jump if so

	 and	 UNAMODE,not @MODE_USE32 ; Assume it's a USE16 segment

	 push	 UNASEL 	; Pass new selector
	 call	 GETARW 	; Return with AX = access rights word

	 test	 ah,mask $DTE_B ; Izit big?
	 jz	 short CMD_UNASM2 ; Jump if not

	 or	 UNAMODE,@MODE_USE32 ; Mark as USE32 segment
CMD_UNASM2:
	 jmp	 short CMD_UNASM_CLC ; Join common OK code

CMD_UNASM_PGDN:
	 mov	 eax,INSTRPDN	; Get page of instruction's length
	 add	 eax,UNAOFF	; Plus current offset
	 and	 eax,UNAMASK	; Ensure within mask limits
	 mov	 UNAOFF,eax	; Save as offset of first instruction
CMD_UNASM_CLC:
	 mov	 eax,UNAOFF	; Get specified offset

	 cmp	 eax,UNAMASK	; Ensure within mask limits
	 ja	 short CMD_UNASM_OVFERR ; Jump if not

	 mov	 DSP_STATE,@DSP_IREGS ; Mark as instruction state
	 mov	 DSP_STAT2,@DSP_IREGS ; Secondary ...
	 or	 LCL_FLAG,@LCL_REDI ; Mark as forced re-display of screen

; Use TYPE instead of SIZE in case any of the items is defined by EQU

	 add	 esp,(type UNAMODE) + (type UNAOFF) + \
		     (type UNASEL)  + (type UNABASE) + (type UNAMASK)

	 clc			; Indicate all went well

	 jmp	 short CMD_UNASM_EXIT ; Join common exit code

CMD_UNASM_OVFERR:
	 mov	 MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

	 jmp	 short CMD_UNASM_ERR ; Join common error code

CMD_UNASM_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
CMD_UNASM_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 REGREST <UNAMASK,UNABASE,UNASEL,UNAOFF,UNAMODE> ; Restore values

	 stc			; Mark as in error
CMD_UNASM_EXIT:
	 REGREST <edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_UNASM endp			; End CMD_UNASM procedure
	 NPPROC  CMD_UNASMBACK -- Unassemble Code Backwards Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Unassemble code backwards command

Ux-

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax>		; Save register

	 inc	 esi		; Skip over the '-'

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 jne	 short CMD_UNASMBACK_SYNTERR ; No, so that's an error

	 call	 GET_LASTPLEN	; Return with EAX=length of previous page
	 sub	 UNAOFF,eax	; Decrement offset of first instruction

	 mov	 eax,UNAMASK	; Get current offset mask
	 and	 UNAOFF,eax	; Mask off if out of bounds

	 mov	 DSP_STATE,@DSP_IREGS ; Mark as instruction state
	 mov	 DSP_STAT2,@DSP_IREGS ; Secondary ...
	 or	 LCL_FLAG,@LCL_REDI ; Mark as forced re-display of screen

	 clc			; Indicate all went well

	 jmp	 short CMD_UNASMBACK_EXIT ; Join common exit code

CMD_UNASMBACK_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
CMD_UNASMBACK_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Mark as in error
CMD_UNASMBACK_EXIT:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_UNASMBACK endp		; End CMD_UNASMBACK procedure

PROG	 ends			; End PROG segment

	 MEND			; End SWAT_UNA module
