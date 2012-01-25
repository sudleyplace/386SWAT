;' $Header:   P:/PVCS/386SWAT/SWAT_MSR.ASV   1.1   10 Jul 1997 14:47:42   BOB  $
	title	SWAT_MSR -- 386SWAT Model Specific Register Routines
	page	58,122
	name	SWAT_MSR

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-2002 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, February, 1996.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include MSR.INC
	include ALLMEM.INC

	include SWAT_COM.INC
	include SWAT_LBR.INC
	include SWAT_SEG.INC
.list

DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	public	@SWAT_MSR_DATA16
@SWAT_MSR_DATA16 label byte	; Mark module start in .MAP file

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	LC4_FLAG:dword
	include SWAT_LC4.INC

	extrn	CMD_LINE:byte
	extrn	LBRATTR:byte

	public	LBR_NROW
LBR_NROW dd	@LBR_P6_NROW	; # rows in LBR window

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	@SWAT_MSR_DATA
@SWAT_MSR_DATA	label byte	; Mark module start in .MAP file

	extrn	CMD_TOKL:byte
	extrn	CMD_TOKN:byte
	extrn	MSGOFF:dword
	extrn	SYNTERR:byte
	extrn	XAVLERR:byte
	extrn	CPUFAM:byte

	public	LBRFREIP,LBRTOEIP
	public	LEXFREIP,LEXTOEIP
LBRFREIP dd	4 dup (?)	; Last Branch From EIP
LBRTOEIP dd	4 dup (?)	; ...	      To   ...
LEXFREIP dd	?		; Last Exception From EIP
LEXTOEIP dd	?		; ...		 To   ...

	 public  W_LBR_P4,W_LBR_P6,W_LBR_EX
W_LBR_P4 W_STR	 <@LBR_P4_SROW,@LBR_SCOL,@LBR_P4_NROW,@LBR_NCOL> ; LBR P4 window struc
W_LBR_P6 W_STR	 <@LBR_P6_SROW,@LBR_SCOL,@LBR_P6_NROW,@LBR_NCOL> ; ... P6 ...
W_LBR_EX W_STR	 <@LBR_EX_SROW,@LBR_SCOL,@LBR_EX_NROW,@LBR_NCOL> ; ... Exception ...

	public	LBRWIN_BRFR_ARR
LBRWIN_BRFR_ARR label dword
	dd	offset DGROUP:LBRWIN_BRFR0
	dd	offset DGROUP:LBRWIN_BRFR1
	dd	offset DGROUP:LBRWIN_BRFR2
	dd	offset DGROUP:LBRWIN_BRFR3

	public	LBRWIN_BRTO_ARR
LBRWIN_BRTO_ARR label dword
	dd	offset DGROUP:LBRWIN_BRTO0
	dd	offset DGROUP:LBRWIN_BRTO1
	dd	offset DGROUP:LBRWIN_BRTO2
	dd	offset DGROUP:LBRWIN_BRTO3

	public	LBRWIN_P6
LBRWIN_P6 db	'ÃÄLBR/LEXÄ'
;;;;;;; db	'³xxxxxxxx '
	db	'³'
LBRWIN_BRFR db	'xxxxxxxx '
	db	'³ '
LBRWIN_BRTO db	'xxxxxxxx'

	public	LBRWIN_P4
LBRWIN_P4 db	'ÃÄLBR/LEXÄ'
;;;;;;; db	'³xxxxxxxx '
	db	'³'
LBRWIN_BRFR0 db 'xxxxxxxx '
	db	'³ '
LBRWIN_BRTO0 db 'xxxxxxxx'
	db	'³'
LBRWIN_BRFR1 db 'xxxxxxxx '
	db	'³ '
LBRWIN_BRTO1 db 'xxxxxxxx'
	db	'³'
LBRWIN_BRFR2 db 'xxxxxxxx '
	db	'³ '
LBRWIN_BRTO2 db 'xxxxxxxx'
	db	'³'
LBRWIN_BRFR3 db 'xxxxxxxx '
	db	'³ '
LBRWIN_BRTO3 db 'xxxxxxxx'

	public	LBRWIN_EX
LBRWIN_EX db	'³'
LBRWIN_EXFR db	'xxxxxxxx '
	db	'³ '
LBRWIN_EXTO db	'xxxxxxxx'

	public	MSG_LBR
MSG_LBR db	'LBR from/to EIP = '
MSG_LBR_FREIP db '________/'
MSG_LBR_TOEIP db '________, LEX from/to EIP = '
MSG_LEX_FREIP db '________/'
MSG_LEX_TOEIP db '________',0
MSG_LBR_LEN equ $-MSG_LBR	; Length of ...

	public	MSG_BTF_ON
MSG_BTF_ON  db	'BTF ON',0      ; Message to display if enabled
MSG_BTF_ON_LEN equ $-MSG_BTF_ON ; Length of ...

	public	MSG_BTF_OFF
MSG_BTF_OFF db	'BTF OFF',0     ; Message to display if disabled
MSG_BTF_OFF_LEN equ $-MSG_BTF_OFF ; Length of ...

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP

	extrn	CMD_WHITE:near
	extrn	GET_TOKN:near
	extrn	CLEAR_CMDLINE:near
	extrn	DISP_CMDLINE:near
	extrn	PURGE_KBUFF:near
	extrn	GETNDKEY:near
	extrn	BIN2DWORD:near
	extrn	WPUT_CSA:near

	NPPROC	SET_BTF -- Set The Branch Trace Facility Bit
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set the Branch Trace Facility bit if BTF is ON (which can happen only
if this CPU supports it).

|

	test	LC4_FLAG,@LC4_BTF ; Izit enabled?
	jz	short SET_BTF_EXIT ; Jump if not

	REGSAVE <eax,ecx,edx>	; Save registers

	mov	ecx,@MSR6_DBGCTL ; Get Debug Control register
	RDMSR			; Read MSR into EDX:EAX
	or	eax,@MSR6_DBGCTL_BTF ; Enable the BTF
	WRMSR			; Tell the CPU about it

	REGREST <edx,ecx,eax>	; Restore
SET_BTF_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_BTF endp			; End SET_BTF procedure
	NPPROC	CLR_BTF -- Clear The Branch Trace Facility Bit
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear the Branch Trace Facility bit if BTF is ON (which can happen
only if this CPU supports it).

|

	test	LC4_FLAG,@LC4_BTF ; Izit enabled?
	jz	short CLR_BTF_EXIT ; Jump if not

	REGSAVE <eax,ecx,edx>	; Save registers

	mov	ecx,@MSR6_DBGCTL ; Get Debug Control register
	RDMSR			; Read MSR into EDX:EAX
	and	eax,not @MSR6_DBGCTL_BTF ; Disable the BTF
	WRMSR			; Tell the CPU about it

	REGREST <edx,ecx,eax>	; Restore
CLR_BTF_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLR_BTF endp			; End CLR_BTF procedure
	NPPROC	CMD_BTF -- Set/Clear BTF
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Set/clear the Branch Trace Facility

BTF
BTF ON
BTF OFF

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	pushad			; Save registers

; Ensure this is a P6

	test	LC4_FLAG,@LC4_LBRBTF ; Izit supported?
	jz	near ptr CMD_BTF_XAVL ; Jump if not

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	or	al,al		; Izit the end of the line?
	jz	short CMD_BTF_DISP ; Jump if so (display the current state)

	call	GET_TOKN       ; Get next token into CMD_TOKN

	cmp	CMD_TOKN.ELO,'no' ; Izit 'ON'?
	je	short CMD_BTF_ON ; Jump if so

	cmp	CMD_TOKN.EDD,'ffo' ; Izit 'OFF',0?
	jne	near ptr CMD_BTF_SYNTERR ; Jump if not

	or	LC4_FLAG,@LC4_BTF ; Indicate BTF is enabled to ensure
				; we write to the CPU's MSRs
	call	CLR_BTF 	; Disable it in the CPU
	and	LC4_FLAG,not @LC4_BTF ; Indicate BTF is disabled

	jmp	short CMD_BTF_DONE ; Join common done code


CMD_BTF_ON:
	cmp	CMD_TOKL,2	; Izit a two-letter command?
	jne	short CMD_BTF_SYNTERR ; Jump if not

	or	LC4_FLAG,@LC4_BTF ; Indicate BTF is enabled
CMD_BTF_DONE:
	or	LCL_FLAG,@LCL_REDI ; Force screen re-display

	clc		       ; Mark as successful

	jmp	short CMD_BTF_EXIT ; Join common exit code


CMD_BTF_DISP:
	call	CLEAR_CMDLINE	; Clear the command line

; Format the new command line

	lea	edi,CMD_LINE	; ES:EDI ==> command line

	lea	esi,MSG_BTF_ON	; Assume it's enabled
	mov	ecx,MSG_BTF_ON_LEN ; ...

	test	LC4_FLAG,@LC4_BTF ; Izit enabled?
	jnz	short @F	; Jump if so

	lea	esi,MSG_BTF_OFF ; Assume it's disabled
	mov	ecx,MSG_BTF_OFF_LEN ; ...
@@:
S32 rep movs	<CMD_LINE[edi],MSG_BTF_ON[esi]> ; Copy to command line

	call	DISP_CMDLINE	; Display the command line
	call	PURGE_KBUFF	; First purge the keyboard buffer
	call	GETNDKEY	; Get non-destructive key

	jmp	short CMD_BTF_DONE ; Join common done code


CMD_BTF_XAVL:
	mov	MSGOFF,offset DGROUP:XAVLERR ; Save offset of error message

	jmp	short CMD_BTF_ERR ; Join common error exit code


CMD_BTF_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

;;;;;;; jmp	short CMD_BTF_ERR ; Join common error exit code


CMD_BTF_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_BTF_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BTF endp			; End CMD_BTF procedure
	NPPROC	SET_LBR -- Set The Last Branch Reporting Bit
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set the Last Branch Reporting bit if LBR is ON (which can happen only
if this CPU supports it).

|

	test	LC4_FLAG,@LC4_LBR ; Izit enabled?
	jz	short SET_LBR_EXIT ; Jump if not

	REGSAVE <eax,ecx,edx>	; Save registers

	mov	ecx,@MSR6_DBGCTL ; Get Debug Control register
	RDMSR			; Read MSR into EDX:EAX
	or	eax,@MSR6_DBGCTL_LBR ; Enable the LBR
	WRMSR			; Tell the CPU about it

	REGREST <edx,ecx,eax>	; Restore
SET_LBR_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_LBR endp			; End SET_LBR procedure
	NPPROC	READ_LBR -- Read The Last Branch Reporting Registers
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read the Last Branch Reporting registers if LBR is ON (which can
happen only if this CPU supports it).

|

	test	LC4_FLAG,@LC4_LBR ; Izit enabled?
	jz	near ptr READ_LBR_EXIT ; Jump if not

	REGSAVE <eax,ecx,edx,esi> ; Save registers

	cmp	CPUFAM,0Fh	; Izit a Pentium 4?
	je	short READ_LBR_P4 ; Jump if so

	mov	ecx,@MSR6_LBRFREIP ; Get Last Branch From EIP
	RDMSR			; Read MSR into EDX:EAX
	mov	LBRFREIP,eax	; Save for later use

	mov	ecx,@MSR6_LBRTOEIP ; Get last Branch To EIP
	RDMSR			; Read MSR into EDX:EAX
	mov	LBRTOEIP,eax	; Save for later use

	mov	ecx,@MSR6_LEXFREIP ; Get Last Exception From EIP
	RDMSR			; Read MSR into EDX:EAX
	mov	LEXFREIP,eax	; Save for later use

	mov	ecx,@MSR6_LEXTOEIP ; Get last Exception To EIP
	RDMSR			; Read MSR into EDX:EAX
	mov	LEXTOEIP,eax	; Save for later use

	jmp	short READ_LBR_DONE ; Join common done code


READ_LBR_P4:
	mov	ecx,@MSRP4_LBR_TOS ; Get Last Branch From EIP
	RDMSR			; Read MSR into EDX:EAX

	and	eax,@MSRP4_LBR_TOS_MASK ; Isolate the LBR TOS index bits
	add	eax,@MSRP4_LBR0 ; Plus LBR base register
	mov	ecx,eax 	; Copy to RDMSR input register
	xor	esi,esi 	; Initialize index into LBRxxEIP
READ_LBR_P4_NEXT:
	RDMSR			; Read MSR into EDX:EAX
	mov	LBRFREIP[esi * (type LBRFREIP)],eax ; Save for later use
	mov	LBRTOEIP[esi * (type LBRTOEIP)],edx ; ...

	inc	ecx		; Skip to next LBR MSR

	cmp	ecx,@MSRP4_LBR3 ; Izit at last LBR MSR?
	jbe	short @F	; Jump if not

	mov	ecx,@MSRP4_LBR0 ; Restart at first LBR MSR
@@:
	inc	esi		; Skip to next pair

	cmp	esi,4		; Izit at the end?
	jb	short READ_LBR_P4_NEXT ; Jump if not

	mov	ecx,@MSRP4_LEXFREIP ; Get Last Exception From EIP
	RDMSR			; Read MSR into EDX:EAX
	mov	LEXFREIP,eax	; Save for later use

	mov	ecx,@MSRP4_LEXTOEIP ; Get last Exception To EIP
	RDMSR			; Read MSR into EDX:EAX
	mov	LEXTOEIP,eax	; Save for later use
READ_LBR_DONE:
	REGREST <esi,edx,ecx,eax> ; Restore
READ_LBR_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

READ_LBR endp			; End READ_LBR procedure
	NPPROC	CMD_LBR -- Display LBR
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display the Last Branch Reporting registers

LBR
LBR ON
LBR OFF

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	pushad			; Save registers

; Ensure this is a P6

	test	LC4_FLAG,@LC4_LBRBTF ; Izit supported?
	jz	near ptr CMD_LBR_XAVL ; Jump if not

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	or	al,al		; Izit the end of the line?
	jz	short CMD_LBR_DISP ; Jump if so (display the current state)

	call	GET_TOKN       ; Get next token into CMD_TOKN

	cmp	CMD_TOKN.ELO,'no' ; Izit 'ON'?
	je	short CMD_LBR_ON ; Jump if so

	cmp	CMD_TOKN.EDD,'ffo' ; Izit 'OFF',0?
	jne	near ptr CMD_LBR_SYNTERR ; Jump if not

	and	LC4_FLAG,not @LC4_LBRWIN ; Indicate LBR window is disabled

	jmp	short CMD_LBR_DONE ; Join common done code


CMD_LBR_ON:
	cmp	CMD_TOKL,2	; Izit a two-letter command?
	jne	near ptr CMD_LBR_SYNTERR ; Jump if not

	or	LC4_FLAG,@LC4_LBRWIN ; Indicate LBR window is enabled
CMD_LBR_DONE:
	or	LCL_FLAG,@LCL_REDI ; Force screen re-display

	clc		       ; Mark as successful

	jmp	CMD_LBR_EXIT	; Join common exit code


CMD_LBR_DISP:
	call	CLEAR_CMDLINE	; Clear the command line

; Format the new command line

	mov	eax,LBRFREIP	; Get Last Branch From EIP
	lea	edi,MSG_LBR_FREIP ; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	mov	eax,LBRTOEIP	; Get Last Branch To EIP
	lea	edi,MSG_LBR_TOEIP ; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	mov	eax,LEXFREIP	; Get Last Exception From EIP
	lea	edi,MSG_LEX_FREIP ; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	mov	eax,LEXTOEIP	; Get Last Exception To EIP
	lea	edi,MSG_LEX_TOEIP ; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

; Copy to command line

	lea	edi,CMD_LINE	; ES:EDI ==> command line
	lea	esi,MSG_LBR	; DS:ESI ==> LBR line
	mov	ecx,MSG_LBR_LEN ; ECX = length of ...
S32 rep movs	<CMD_LINE[edi],MSG_LBR[esi]> ; Copy to command line

	call	DISP_CMDLINE	; Display the command line
	call	PURGE_KBUFF	; First purge the keyboard buffer
	call	GETNDKEY	; Get non-destructive key

	clc		       ; Mark as successful

	jmp	short CMD_LBR_EXIT ; Join common exit code


CMD_LBR_XAVL:
	mov	MSGOFF,offset DGROUP:XAVLERR ; Save offset of error message

	jmp	short CMD_LBR_ERR ; Join common error exit code


CMD_LBR_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

;;;;;;; jmp	short CMD_LBR_ERR ; Join common error exit code


CMD_LBR_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_LBR_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_LBR endp			; End CMD_LBR procedure
	NPPROC	DISP_LBRWIN -- Display LBR Window
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display LBR window

|

	REGSAVE <eax,esi,edi>	; Save registers

	cmp	CPUFAM,0Fh	; Izit a Pentium 4?
	je	short DISP_LBRWIN_P4 ; Jump if so

; Format the numbers

	mov	eax,LBRFREIP	; Get Last Branch From EIP
	lea	edi,LBRWIN_BRFR ; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	mov	eax,LBRTOEIP	; Get Last Branch To EIP
	lea	edi,LBRWIN_BRTO ; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	mov	al,LBRATTR	; Get LBR window attribute
	push	ax		; Pass as attribute to smear
	push	offset ds:LBRWIN_P6 ; Pass address of LBR window
	push	offset ds:W_LBR_P6 ; Pass address of window descriptor
	call	WPUT_CSA	; Output the characters, smear attribute

	jmp	short DISP_LBRWIN_COM ; Join common code


DISP_LBRWIN_P4:
	xor	esi,esi 	; Initialize index into LBRxxEIP

; Format the numbers

DISP_LBRWIN_P4_NEXT:
	mov	eax,LBRFREIP[esi * (type LBRFREIP)] ; Get Last Branch From EIP
	mov	edi,LBRWIN_BRFR_ARR[esi * (type LBRWIN_BRFR_ARR)] ; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	mov	eax,LBRTOEIP[esi * (type LBRTOEIP)] ; Get Last Branch To EIP
	mov	edi,LBRWIN_BRTO_ARR[esi * (type LBRWIN_BRFR_ARR)] ; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	inc	esi		; Skip to next pair

	cmp	esi,4		; Izit at the end?
	jb	short DISP_LBRWIN_P4_NEXT ; Jump if not

	mov	al,LBRATTR	; Get LBR window attribute
	push	ax		; Pass as attribute to smear
	push	offset ds:LBRWIN_P4 ; Pass address of LBR window
	push	offset ds:W_LBR_P4 ; Pass address of window descriptor
	call	WPUT_CSA	; Output the characters, smear attribute
DISP_LBRWIN_COM:
	mov	eax,LEXFREIP	; Get Last Exception From EIP
	lea	edi,LBRWIN_EXFR ; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	mov	eax,LEXTOEIP	; Get Last Exception To EIP
	lea	edi,LBRWIN_EXTO ; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	mov	al,LBRATTR	; Get LBR window attribute
	push	ax		; Pass as attribute to smear
	push	offset ds:LBRWIN_EX ; Pass address of LBR EX window
	push	offset ds:W_LBR_EX ; Pass address of window descriptor
	call	WPUT_CSA	; Output the characters, smear attribute

	REGREST <edi,esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_LBRWIN endp		; End DISP_LBRWIN procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_MSR module
