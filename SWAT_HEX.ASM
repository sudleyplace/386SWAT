;' $Header:   P:/PVCS/386SWAT/SWAT_HEX.ASV   1.8   10 Jul 1997 14:46:44   BOB  $
	 title	 SWAT_HEX -- 386SWAT Hex Command Functions
	 page	 58,122
	 name	 SWAT_HEX

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.

|
.386
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include ALLMEM.INC

	 include SWAT_CMD.INC
	 include SWAT_SEG.INC
.list

DATA	 segment use32 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	 extrn	 MSGOFF:dword
	 extrn	 SYNTERR:byte

	 public  MSG_HEX
MSG_HEX  db	 ' = '
MSG_HEX0 db	 '____'
MSG_HEX_SEP db	 '?'
MSG_HEX1 db	 '________'

DATA	 ends			; End DATA segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 extrn	 CMD_WHITE:near
	 extrn	 PARSE_ADDR:near
	 extrn	 BIN2WORD:near
	 extrn	 BIN2DWORD:near

	 extrn	 ENDOF_CMDLINE:near
	 extrn	 DISP_CMDLINE:near
	 extrn	 PURGE_KBUFF:near
	 extrn	 GETNDKEY:near

	 NPPROC  CMD_HEX -- Hex Arithmetic Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Hex arithmetic command

H addr

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save registers

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 short CMD_HEX_SYNTERR ; Yes, so that's an error

	 call	 PARSE_ADDR	; Parse command line for an address
	 jc	 near ptr CMD_HEX_ERR ; Jump if error

; Ensure nothing more on the line

	 push	 eax		; Save for a moment

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,'='         ; Izit start of result?
	 je	 short @F	; Jump if so

	 cmp	 al,0		; Izit end-of-the-line?
@@:
	 pop	 eax		; Restore
	 jne	 short CMD_HEX_SYNTERR ; No, so that's an error

	 mov	 ds:[esi].LO,0	 ; Mark as EOL in case result leftover from /H

; If there was a segment/selector specified, display it
; ES:EDI ==> next output save area byte

	 lea	 edi,MSG_HEX0	; ES:EDI ==> output save area

	 test	 cx,@ADDR_SEP	; Izit specified?
	 jz	 short CMD_HEX_EXPR ; Jump if not

	 push	 eax		; Save for a moment

	 mov	 ax,bx		; Copy segment/selector
	 call	 BIN2WORD	; Convert AX to hex at ES:EDI

	 mov	 al,'|'         ; Assume PM

	 test	 cx,@ADDR_PM	; Izit PM?
	 jnz	 short @F	; Jump if so

	 mov	 al,':'         ; It's VM86
@@:
	 mov	 MSG_HEX_SEP,al ; Save in message

	 pop	 eax		; Restore

	 inc	 edi		; Skip over separator
CMD_HEX_EXPR:
	 call	 BIN2DWORD	; Convert EAX to hex at ES:EDI

	 lea	 esi,MSG_HEX	; DS:ESI ==> message to display
	 mov	 ecx,edi	; Copy address of next available byte
	 sub	 ecx,esi	; ECX = # bytes in message

	 call	 ENDOF_CMDLINE	; Return with ES:EDI ==> end of the command line

S32  rep movs	 <es:[edi].LO,ds:[esi].LO> ; Copy to command line

	 call	 DISP_CMDLINE	; Display the command line
	 call	 PURGE_KBUFF	; First purge the keyboard buffer
	 call	 GETNDKEY	; Get non-destructive key

	 clc			; Indicate all went well

	 jmp	 short CMD_HEX_EXIT ; Join common exit code

CMD_HEX_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

;;;;;;;; jmp	 short CMD_HEX_ERR ; Join common error exit code

CMD_HEX_ERR:
	 stc			; Mark as in error
CMD_HEX_EXIT:
	 REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_HEX  endp			; End CMD_HEX procedure

PROG	 ends			; End PROG segment

	 MEND			; End SWAT_HEX module
