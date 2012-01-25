;' $Header:   P:/PVCS/386SWAT/SWAT_IOP.ASV   1.2   10 Jul 1997 14:47:00   BOB  $
	 title	 SWAT_IOP -- 386SWAT I/O Port Command Functions
	 page	 58,122
	 name	 SWAT_IOP

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
	 include 8259.INC
	 include ALLMEM.INC

	 include SWAT_SEG.INC
.list

DATA16	 segment use32 dword public 'data' ; Start DATA16 segment
	 assume  ds:DGROUP

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	 extrn	 CMD_LINE:byte

DATA16	 ends			; End DATA16 segment


DATA	 segment use32 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 MSGOFF:dword
	 extrn	 SYNTERR:byte
	 extrn	 OVFERR:byte

	 extrn	 OLDIMR1:byte
	 extrn	 OLDIMR2:byte

	 public  MSG_INPRES
MSG_INPRES db	 'I/O port '
MSG_INPRES1 db	 '____ result = ' ; Input port message text
MSG_INPRES_LEN equ $-MSG_INPRES ; Length of ...

DATA	 ends			; End DATA segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 extrn	 BIN2BYTE:near
	 extrn	 BIN2WORD:near
	 extrn	 BIN2DWORD:near

	 extrn	 CMD_WHITE:near
	 extrn	 PARSE_LVAL:near

	 extrn	 CLEAR_CMDLINE:near
	 extrn	 DISP_CMDLINE:near
	 extrn	 PURGE_KBUFF:near
	 extrn	 GETNDKEY:near
	 extrn	 U32_DRAINPIQ:near

	 NPPROC  INPUT_ACTIMR -- Input IMR Action Routine
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Input IMR action routine

On exit:

AL	 =	 master IMR
AH	 =	 slave ...

|

	 mov	 al,OLDIMR1	; Get the master PIC
	 mov	 ah,OLDIMR2	; ...	  slave  ...

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INPUT_ACTIMR endp		; End INPUT_ACTIMR procedure
	 NPPROC  INPUT_ACTIRR -- Input IRR Action Routine
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Input IRR action routine

On exit:

AL	 =	 master IRR
AH	 =	 slave ...

|

	 mov	 al,@GETIRR	; Code to request IRR from ICR
	 out	 @ICR2,al	; Tell the slave ICR about it
	 call	 U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	 in	 al,@ICR2	; Return with byte result
	 call	 U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
	 mov	 ah,al		; ...in AH

	 mov	 al,@GETIRR	; Code to request IRR from ICR
	 out	 @ICR,al	; Tell the master ICR about it
	 call	 U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	 in	 al,@ICR	; Return with byte result in AL
;;;;;;;; call	 U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INPUT_ACTIRR endp		; End INPUT_ACTIRR procedure
	 NPPROC  INPUT_ACTISR -- Input ISR Action Routine
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Input ISR action routine

On exit:

AL	 =	 master ISR
AH	 =	 slave ...

|

	 mov	 al,@GETISR	; Code to request ISR from ICR
	 out	 @ICR2,al	; Tell the slave ICR about it
	 call	 U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	 in	 al,@ICR2	; Return with byte result
	 call	 U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
	 mov	 ah,al		; ...in AH

	 mov	 al,@GETISR	; Code to request ISR from ICR
	 out	 @ICR,al	; Tell the master ICR about it
	 call	 U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	 in	 al,@ICR	; Return with byte result in AL
;;;;;;;; call	 U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INPUT_ACTISR endp		; End INPUT_ACTISR procedure
	 NPPROC  CMD_IMR -- Input IMR Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Input IMR command common routine

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax>		; Save register

	 call	 INPUT_ACTIMR	; Return with AL = master IMR byte
				; ...	      AH = slave ...
	 mov	 MSG_INPRES[1],'M' ; Mark as IMR
	 mov	 MSG_INPRES1[3],'1' ; From I/O port 21h/A1h
	 call	 IRRISRCOM	; Call common routine
				; Return with CF significant

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_IMR  endp			; End CMD_IMR procedure
	 NPPROC  CMD_IRR -- Input IRR Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Input IRR command common routine

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax>		; Save register

	 call	 INPUT_ACTIRR	; Return with AL = master IRR byte
				; ...	      AH = slave ...
	 mov	 MSG_INPRES[1],'R' ; Mark as IRR
	 mov	 MSG_INPRES1[3],'0' ; From I/O port 20h/A0h
	 call	 IRRISRCOM	; Call common routine
				; Return with CF significant

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_IRR  endp			; End CMD_IRR procedure
	 NPPROC  CMD_ISR -- Input ISR Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Input ISR command common routine

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax>		; Save register

	 call	 INPUT_ACTISR	; Return with AL = master ISR byte
				; ...	      AH = slave ...
	 mov	 MSG_INPRES[1],'S' ; Mark as ISR
	 mov	 MSG_INPRES1[3],'0' ; From I/O port 20h/A0h
	 call	 IRRISRCOM	; Call common routine
				; Return with CF significant

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_ISR  endp			; End CMD_ISR procedure
	 NPPROC  IRRISRCOM -- Input IRR/ISR Command Common Routine
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Input IMR/IRR/ISR command common routine

On entry:

AL	 =	 master IMR/IRR/ISR result
AH	 =	 slave ...
DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax,ecx,esi,edi>  ; Save registers

	 mov	 MSG_INPRES[0],'I'  ; Mark as IMR/IRR/ISR
	 mov	 MSG_INPRES[2],'R'  ; ...
	 mov	 MSG_INPRES1[0],'0' ; from I/O port 2xh
	 mov	 MSG_INPRES1[1],'0' ; ...
	 mov	 MSG_INPRES1[2],'2' ; ...

	 call	 CLEAR_CMDLINE	; Clear the command line

	 lea	 esi,MSG_INPRES  ; DS:ESI ==> message to display
	 lea	 edi,CMD_LINE	 ; ES:EDI ==> command line
	 mov	 ecx,MSG_INPRES_LEN ; ECX = # bytes in message
S32  rep movs	 <CMD_LINE[edi],MSG_INPRES[esi]> ; Copy to command line

	 call	 BIN2BYTE	; Convert AL to hex at ES:EDI

	 mov	 al,' '         ; Separator
S32	 stos	 es:[edi].LO	; Save in command line

	 mov	 al,ah		; Copy slave value
	 call	 BIN2BYTE	; Convert AL to hex at ES:EDI

	 call	 DISP_CMDLINE	; Display the command line
	 call	 PURGE_KBUFF	; First purge the keyboard buffer
	 call	 GETNDKEY	; Get non-destructive key

	 clc			; Indicate all went well

	 REGREST <edi,esi,ecx,eax>  ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IRRISRCOM endp			; End IRRISRCOM procedure
	 NPPROC  INPUT_ACTB -- Input Byte Action Routine
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Input byte action routine

On entry:

DX	 =	 I/O port

On exit:

AL	 =	 byte result

|

	 mov	 al,OLDIMR1	; Assume it's the master IMR

	 cmp	 dx,@IMR	; Izit the master IMR?
	 je	 short @F	; Yes, use value in AL

	 mov	 al,OLDIMR2	; Assume it's the slave IMR

	 cmp	 dx,@IMR2	; Izit the slave IMR?
	 je	 short @F	; Yes, use value in AL

	 in	 al,dx		; Return with byte result
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INPUT_ACTB endp 		; End INPUT_ACTB procedure
	 NPPROC  INPUT_ACTW -- Input Word Action Routine
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Input word action routine

On entry:

DX	 =	 I/O port

On exit:

AX	 =	 word result

|

	 in	 ax,dx		; Return with word result

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INPUT_ACTW endp 		; End INPUT_ACTW procedure
	 NPPROC  INPUT_ACTD -- Input Dword Action Routine
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Input dword action routine

On entry:

DX	 =	 I/O port

On exit:

EAX	 =	 dword result

|

	 in	 eax,dx 	; Return with dword result

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INPUT_ACTD endp 		; End INPUT_ACTD procedure
	 NPPROC  CMD_INPUTB -- Input Byte I/O Port Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Input byte to I/O port command common routine

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <ebx,ecx>	; Save registers

	 lea	 ecx,INPUT_ACTB ; CS:ECX ==> byte input action routine
	 lea	 ebx,BIN2BYTE	; CS:EBX ==> byte display routine
	 call	 INPUTCOM	; Call common routine
				; Return with CF significant

	 REGREST <ecx,ebx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_INPUTB endp 		; End CMD_INPUTB procedure
	 NPPROC  CMD_INPUTW -- Input Word I/O Port Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Input word to I/O port command common routine

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <ebx,ecx>	; Save registers

	 lea	 ecx,INPUT_ACTW ; CS:ECX ==> word input action routine
	 lea	 ebx,BIN2WORD	; CS:EBX ==> word display routine
	 call	 INPUTCOM	; Call common routine
				; Return with CF significant

	 REGREST <ecx,ebx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_INPUTW endp 		; End CMD_INPUTW procedure
	 NPPROC  CMD_INPUTD -- Input Dword I/O Port Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Input dword to I/O port command common routine

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <ebx,ecx>	; Save registers

	 lea	 ecx,INPUT_ACTD ; CS:ECX ==> dword input action routine
	 lea	 ebx,BIN2DWORD	; CS:EBX ==> dword display routine
	 call	 INPUTCOM	; Call common routine
				; Return with CF significant

	 REGREST <ecx,ebx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_INPUTD endp 		; End CMD_INPUTD procedure
	 NPPROC  INPUTCOM -- Input I/O Port Command Common Routine
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Input byte/word/dword to I/O port command common routine

On entry:

ECX	 =	 address of action routine
EBX	 =	 address of display routine
DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax,ecx,edx,esi,edi> ; Save registers

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 short INPUTCOM_SYNTERR ; Yes, treat as error

; Parse I/O port number
; Convert the con/reg at DS:ESI to binary

	 call	 PARSE_LVAL	; Parse command line for lefthand value
	 jc	 short INPUTCOM_OVFERR ; Jump if too large

	 cmp	 eax,0FFFFh	; Ensure within range of I/O ports
	 ja	 short INPUTCOM_OVFERR ; Jump if too large

	 mov	 MSG_INPRES[0],'I'  ; Mark as I/O
	 mov	 MSG_INPRES[1],'/'  ; ...
	 mov	 MSG_INPRES[2],'O'  ; ...

; Format I/O port # in output message

	 lea	 edi,MSG_INPRES1 ; ES:EDI ==> output save area
	 call	 BIN2WORD	; Convert AX to hex at ES:EDI

	 mov	 dx,ax		; Copy to I/O port register
	 call	 ecx		; Call action routine

	 call	 CLEAR_CMDLINE	; Clear the command line

	 lea	 esi,MSG_INPRES  ; DS:ESI ==> message to display
	 lea	 edi,CMD_LINE	 ; ES:EDI ==> command line
	 mov	 ecx,MSG_INPRES_LEN ; ECX = # bytes in message
S32  rep movs	 <CMD_LINE[edi],MSG_INPRES[esi]> ; Copy to command line

	 call	 ebx		; Call display routine

	 call	 DISP_CMDLINE	; Display the command line
	 call	 PURGE_KBUFF	; First purge the keyboard buffer
	 call	 GETNDKEY	; Get non-destructive key

	 clc			; Indicate all went well

	 jmp	 short INPUTCOM_EXIT ; Join common exit code

INPUTCOM_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	 jmp	 short INPUTCOM_ERR ; Join common error exit code

INPUTCOM_OVFERR:
	 mov	 MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

;;;;;;;; jmp	 short INPUTCOM_ERR ; Join common error exit code

INPUTCOM_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Mark as in error
INPUTCOM_EXIT:
	 REGREST <edi,esi,edx,ecx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INPUTCOM endp			; End INPUTCOM procedure
	 NPPROC  OUTPUT_ACTB -- Output Byte Action Routine
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Output byte action routine

On entry:

AL	 =	 output byte
DX	 =	 I/O port

|

	 cmp	 dx,@IMR	; Izit the master IMR?
	 je	 short OUTPUT_ACTB1 ; Yes, handle specially

	 cmp	 dx,@IMR2	; Izit the slave IMR?
	 je	 short OUTPUT_ACTB2 ; Yes, handle specially

	 out	 dx,al		; Output the byte

	 jmp	 short OUTPUT_ACTB_EXIT ; Join common exit code

OUTPUT_ACTB1:
	 mov	 OLDIMR1,al	; Save to restore later

	 jmp	 short OUTPUT_ACTB_EXIT ; Join common exit code

OUTPUT_ACTB2:
	 mov	 OLDIMR2,al	; Save to restore later
OUTPUT_ACTB_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OUTPUT_ACTB endp		; End OUTPUT_ACTB procedure
	 NPPROC  OUTPUT_ACTW -- Output Word Action Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Output word action routine

On entry:

AX	 =	 output word
DX	 =	 I/O port

|

	 out	 dx,ax		; Output the word

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OUTPUT_ACTW endp		; End OUTPUT_ACTW procedure
	 NPPROC  OUTPUT_ACTD -- Output Dword Action Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Output dword action routine

On entry:

EAX	 =	 output dword
DX	 =	 I/O port

|

	 out	 dx,eax 	; Output the dword

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OUTPUT_ACTD endp		; End OUTPUT_ACTD procedure
	 NPPROC  CMD_OUTPUTB -- Output Byte I/O Port Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Output byte to I/O port command common routine

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <ebx,ecx>	; Save registers

	 lea	 ecx,OUTPUT_ACTB ; CS:ECX ==> byte output action routine
	 mov	 ebx,0FFh	; EBX = maximum output value
	 call	 OUTPUTCOM	; Call common routine
				; Return with CF significant

	 REGREST <ecx,ebx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_OUTPUTB endp		; End CMD_OUTPUTB procedure
	 NPPROC  CMD_OUTPUTW -- Output Word I/O Port Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Output word to I/O port command common routine

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <ebx,ecx>	; Save registers

	 lea	 ecx,OUTPUT_ACTW ; CS:ECX ==> word output action routine
	 mov	 ebx,0FFFFh	; EBX = maximum output value
	 call	 OUTPUTCOM	; Call common routine
				; Return with CF significant

	 REGREST <ecx,ebx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_OUTPUTW endp		; End CMD_OUTPUTW procedure
	 NPPROC  CMD_OUTPUTD -- Output Dword I/O Port Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Output dword to I/O port command common routine

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <ebx,ecx>	; Save registers

	 lea	 ecx,OUTPUT_ACTD ; CS:ECX ==> dword output action routine
	 mov	 ebx,0FFFFFFFFh ; EBX = maximum output value
	 call	 OUTPUTCOM	; Call common routine
				; Return with CF significant

	 REGREST <ecx,ebx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_OUTPUTD endp		; End CMD_OUTPUTD procedure
	 NPPROC  OUTPUTCOM -- Output I/O Port Command Common Routine
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Output byte/word/dword to I/O port command common routine

On entry:

EBX	 =	 maximum output value
ECX	 =	 address of action routine
DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax,edx,esi>	; Save registers

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 short OUTPUTCOM_SYNTERR ; Yes, treat as error

; Parse I/O port number
; Convert the con/reg at DS:ESI to binary

	 call	 PARSE_LVAL	; Parse command line for lefthand value
	 jc	 short OUTPUTCOM_OVFERR ; Jump if too large

	 cmp	 eax,0FFFFh	; Ensure within range of I/O ports
	 ja	 short OUTPUTCOM_OVFERR ; Jump if too large

	 mov	 dx,ax		; Copy to I/O port register

; Parse output value

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 short OUTPUTCOM_SYNTERR ; Yes, treat as error

; Convert the con/reg at DS:ESI to binary

	 call	 PARSE_LVAL	; Parse command line for lefthand value
	 jc	 short OUTPUTCOM_OVFERR ; Jump if too large

	 cmp	 eax,ebx	; Ensure within range of I/O port values
	 ja	 short OUTPUTCOM_OVFERR ; Jump if too large

	 call	 ecx		; Call action routine

	 clc			; Indicate all went well

	 jmp	 short OUTPUTCOM_EXIT ; Join common exit code

OUTPUTCOM_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	 jmp	 short OUTPUTCOM_ERR ; Join common error exit code

OUTPUTCOM_OVFERR:
	 mov	 MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

;;;;;;;; jmp	 short OUTPUTCOM_ERR ; Join common error exit code

OUTPUTCOM_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Mark as in error
OUTPUTCOM_EXIT:
	 REGREST <esi,edx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OUTPUTCOM endp			; End OUTPUTCOM procedure

PROG	 ends			; End PROG segment

	 MEND			; End SWAT_IOP module
