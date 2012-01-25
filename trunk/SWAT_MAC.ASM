;' $Header:   P:/PVCS/386SWAT/SWAT_MAC.ASV   1.3   21 Aug 1997 15:00:24   BOB  $
	 title	 SWAT_MAC-- 386SWAT MAC Display Functions
	 page	 58,122
	 name	 SWAT_MAC

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1995.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include MAC.INC
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

	 extrn	 TTLATTR:byte
	 extrn	 ERRATTR:byte
	 extrn	 DEFATTR:byte

	 public  MACMODE,MACBASE,MACOFF,MACMASK
MACMODE  dw	 @MODE_VM or @ADDR_SEP ; Memory mode (default = VM)
MACBASE  dd	 ?		; Memory base
MACOFF	 dd	 0		; Memory offset
MACMASK  dd	 0000FFFFh	; Memory mask (32 or 16 bits)

DATA16	 ends			; End DATA16 segment


DATA	 segment use32 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 CON1P1MB:dword

	 extrn	 MSGOFF:dword
	 extrn	 SYNTERR:byte
	 extrn	 SCROFF:dword

	 extrn	 DSP_STATE:byte

	 extrn	 MEMMODE:word
	 extrn	 MEMBASE:dword
	 extrn	 MEMOFF:dword

	 extrn	 MACNDX:dword

@MAC_LEN equ	 (type MAC_STR)

	 public  MSG_MAC,MSG_MACLINE
MSG_MAC  db	 'MAC Entry Type Ownr #Paras ',0
MSG_MACLINE db	 'xxxxxxxx³  ',0
;;;;;;;; db	 '  xxxx:0³  ',0
;;;;;;;; db	 'xxxxxxxx³  xx  xxxx  xxxx  xx xx xx xx xx xx xx xx xx xx xx ³ xxxxxxxxxxx',0

	 public  MSG_MACFREE
MSG_MACFREE db	 '----',0       ; Owner display for free MAC entries

DATA	 ends			; End DATA segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 extrn	 IZITEOL:near
	 extrn	 PARSE_ADDR:near

	 extrn	 INST_OPR0E:near
	 extrn	 REST_OPR0E:near

	 extrn	 DISPASCIIZ:near
	 extrn	 GETBYTE:near
	 extrn	 GETWORD:near
	 extrn	 DISPTXT:near
	 extrn	 DSPBYTE:near
	 extrn	 CLEAR_EOL:near
	 extrn	 NEXTLINE:near
;;;;;;;; extrn	 HDR_PHYS:near
	 extrn	 HDR_SYMBOL:near

	 extrn	 DISPHEX0:near
	 extrn	 DISPHEX2:near
	 extrn	 DISPHEX4:near

	 NPPROC  CMD_MACBASE -- MACBASE Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

MACBASE command

MACBASE addr

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx,ecx,edx> ; Save registers

	 call	 IZITEOL	; Izit end-of-the-line?
	 je	 short CMD_MACBASE_SYNTERR ; Yes, so that's an error

	 call	 PARSE_ADDR	; Parse DS:ESI for address
	 jc	 short CMD_MACBASE_ERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

	 call	 IZITEOL	; Izit end-of-the-line?
	 jne	 short CMD_MACBASE_SYNTERR ; No, so that's an error

	 mov	 MACOFF,eax	; Save for later use

	 test	 cx,@ADDR_SEP	; Separator specified?
	 jz	 short @F	; Not this time

	 mov	 MACBASE,edx	; Save for later use

	 and	 MACMODE,not @MODE_VM ; Mark as protected mode
	 mov	 MACMASK,-1	; Use all 32 bits

	 test	 cx,@ADDR_PM	; Check mode
	 jnz	 short @F	; Jump if PM

	 or	 MACMODE,@MODE_VM ; Mark as VM86 mode
	 mov	 MACMASK,0000FFFFh ; Use low-order 16 bits
@@:
	 cmp	 DSP_STATE,@DSP_MAC ; Are we displaying MACs?
	 jne	 short @F	; Jump if not

	 or	 LCL_FLAG,@LCL_REDI ; Mark as forced re-display of screen
@@:
	 clc			; Indicate all went well

	 jmp	 short CMD_MACBASE_EXIT ; Join common exit code


CMD_MACBASE_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	 jmp	 short CMD_MACBASE_ERR ; Join common error exit code

CMD_MACBASE_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Mark as in error
CMD_MACBASE_EXIT:
	 REGREST <edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_MACBASE endp		; End CMD_MACBASE procedure
	 NPPROC  DISP_MAC -- Display MAC Memory
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display the MAC entries

On entry:

MACBASE  =	 base of memory to display
MACOFF	 =	 offset ...
MACNDX	 =	 index # of current MAC entry

|

	 REGSAVE <eax,ecx,edx>	; Save registers

	 mov	 SCROFF,0	; Start at top of screen

	 call	 INST_OPR0E	; Install our local Page Fault handler

	 REGSAVE <MEMBASE,MEMOFF,MEMMODE> ; Save the current base and offset

; Display the header

	 mov	 al,TTLATTR	; Get title attribute
	 xchg	 al,DEFATTR	; Swap with default attribute

	 lea	 esi,MSG_MAC	; Line 1 of byte header
	 call	 DISPASCIIZ	; Display ASCIIZ string from ESI

;;;;;;;; call	 HDR_PHYS	; Display physical message (if any)

	 call	 HDR_SYMBOL	; Check for symbol at starting offset

	 call	 CLEAR_EOL	; Clear to the end-of-the-line
	 xchg	 al,DEFATTR	; Restore default attribute

; Find the current MAC index

	 mov	 edx,MACBASE	; Get current base
	 add	 edx,MACOFF	; Plus current offset

	 mov	 ecx,MACNDX	; Get current index
	 jecxz	 DISP_MAC1	; Jump if we're at the top
@@:
	 movzx	 eax,AGROUP:[edx].MAC_NPAR ; Get # paras in MAC entry
	 inc	 eax		; Skip over the MAC para
	 shl	 eax,4-0	; Convert from paras to bytes
	 add	 edx,eax	; Skip to next entry

	 loop	 @B		; Jump if more MAC entries
DISP_MAC1:

; Display the MAC entries

	 mov	 ecx,@NROWS-2	; Get # rows to display
DISP_MAC_NEXT:
	 push	 ecx		; Save over inner loops

	 mov	 MEMBASE,edx	; Save for use by GETBYTE, etc.
	 mov	 MEMOFF,0	; ...
	 mov	 MEMMODE,0	; ...

; Display the leading segment/linear address

	 cmp	 edx,CON1P1MB	; Izit too big for a segment?
	 jae	 short DISP_MAC_PM ; Jump if so

	 test	 MACMODE,@MODE_VM ; Izit VM86 mode?
	 jz	 short DISP_MAC_PM ; Jump if not

	 mov	 al,' '         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 mov	 al,' '         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 mov	 eax,edx	; Get current base
	 shr	 eax,4-0	; Convert from bytes to paras
	 call	 DISPHEX2	; Display the word

	 mov	 al,':'         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 mov	 eax,edx	; Get current base
	 call	 DISPHEX0	; Display the nibble

	 jmp	 short DISP_MAC_COM ; Join common code

DISP_MAC_PM:
	 mov	 eax,edx	; Get current base
	 call	 DISPHEX4	; Display the dword
DISP_MAC_COM:
	 mov	 al,'³'         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

; Display the MAC_TYPE

	 mov	 al,' '         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 mov	 al,' '         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 mov	 al,DEFATTR	; Get default attribute

	 mov	 ah,AGROUP:[edx].MAC_TYPE ; Get the MAC type

	 cmp	 ah,@MAC_MID	; Izit a middle entry?
	 je	 short @F	; Jump if so

	 cmp	 ah,@MAC_END	; Izit an ending entry?
	 je	 short @F	; Jump if so

	 mov	 al,ERRATTR	; Get error attribute
@@:
	 xchg	 al,DEFATTR	; Swap with default attribute

	 PUSHD	 0		; Pass offset as argument
	 call	 GETBYTE	; Get, format, and display byte from MEMBASE+MEMOFF

	 xchg	 al,DEFATTR	; Restore default attribute

; Display the MAC_OWNR

	 mov	 al,' '         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 mov	 al,' '         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 cmp	 AGROUP:[edx].MAC_OWNR,@MAC_FREE ; Izit free?
	 je	 short DISP_MAC_FREE ; Jump if so

	 PUSHD	 0		; Pass offset as argument
	 call	 GETWORD	; Get, format, and display word from MEMBASE+MEMOFF

	 jmp	 short DISP_MAC_COM1 ; Join common code

DISP_MAC_FREE:
	 lea	 esi,MSG_MACFREE ; Free MAC message
	 call	 DISPASCIIZ	; Display ASCIIZ string from ESI

	 add	 MEMOFF,2	; Skip over the owner entry
DISP_MAC_COM1:

; Display the MAC_NPAR

	 mov	 al,' '         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 mov	 al,' '         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 PUSHD	 0		; Pass offset as argument
	 call	 GETWORD	; Get, format, and display word from MEMBASE+MEMOFF

; Display the rest of the data

	 mov	 al,' '         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 mov	 ecx,@MAC_LEN-(1+2+2) ; Get # bytes in one line

	 push	 MEMOFF 	; Save over inner loop
@@:
	 mov	 al,' '         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 PUSHD	 0		; Pass offset as argument
	 call	 GETBYTE	; Get, format, and display byte from MEMBASE+MEMOFF

	 loop	 @B		; Jump if more bytes to display

	 pop	 MEMOFF 	; Restore

; Display the trailing data in ASCII

	 mov	 al,' '         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 mov	 al,'³'         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 mov	 al,' '         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 mov	 ecx,@MAC_LEN-(1+2+2) ; Get # bytes in one line
@@:
	 call	 DSPBYTE	; Get and display byte from MEMBASE+MEMOFF

	 loop	 @B		; Jump if more bytes to display

	 pop	 ecx		; Restore outer loop counter

	 call	 CLEAR_EOL	; Clear to the end-of-the-line
	 call	 NEXTLINE	; Skip to next line, first column

; Skip to next MAC entry

	 movzx	 eax,AGROUP:[edx].MAC_NPAR ; Get # paras in MAC entry
	 inc	 eax		; Skip over the MAC para
	 shl	 eax,4-0	; Convert from paras to bytes
	 add	 edx,eax	; Skip to next entry

;;;;;;;; loop	 DISP_MAC_NEXT	; Jump if more rows to display
	 dec	 ecx		; Count out another row
	 jnz	 DISP_MAC_NEXT	; Jump if more rows to display

	 REGREST <MEMMODE,MEMOFF,MEMBASE> ; Restore

	 call	 REST_OPR0E	; Restore previous Page Fault handler

	 REGREST <edx,ecx,eax>	; Restore

	 clc			; Indicate we should continue with next row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_MAC endp			; End DISP_MAC procedure

PROG	 ends			; End PROG segment

	 MEND			; End SWAT_MAC module
