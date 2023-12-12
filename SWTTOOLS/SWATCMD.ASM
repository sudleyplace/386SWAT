;' $Header:   P:/pvcs/misc/swttools/swatcmd.asv   1.2   06 Oct 1993 11:35:30   HENRY  $

	TITLE	SWATCMD -- Pass commands to 386SWAT via VCPI interface
	Name	SWATCmd
	PAGE	60,132

COMMENT &

**************************** QUALITAS *******************************
*************************** CONFIDENTIAL ****************************

Copyright (C) 1993 Qualitas, Inc.
All rights reserved.

Original code by: Henry Groover, February 1993

This program may be loaded as a device (DEVICE=SWATCMD.EXE), through
INSTALL= or in AUTOEXEC.BAT.  The program itself does not go resident.

The command line is sent to SWAT's log via API, then is passed to
SWAT for execution.  No checking of any sort is done, although
double quotes (") are stripped.  If the stile (|) needs to be sent
to SWAT, it'll need to be enclosed in double quotes somewhere so
DOS doesn't try to redirect the command line.  To embed a double
quote, put two together.

&

.386
.xlist
Include MASM.INC
Include DOSCALL.INC
Include ASCII.INC
Include PTR.INC
Include DEVDRV.INC
Include BIOSDATA.INC
Include XMS.INC
Include 386.INC
Include VCPI.INC
.8086
.list

CGROUP	group	BIOSDATA
PGROUP	group	DATA,CODE,ZCODE,NCODE,NDATA,STACK
PSPGROUP group	PSPSEG

DATA segment byte public 'PROG'
DATA ends

CODE segment byte public 'PROG'
CODE ends

ZCODE segment byte public 'PROG'
End_resident	label	byte	; End of resident code/data
ZCODE ends

NCODE segment byte public 'PROG'
NCODE ends

NDATA segment byte public 'PROG'
NDATA ends

STACK segment byte stack 'PROG'
STACK ends

PSPSEG segment at 0
assume cs:PSPGROUP,ds:PSPGROUP

	Public	PSP_ENVIR_PTR
Include PSP.INC

PSPSEG ends

DATA	segment
	assume DS:PGROUP,ES:nothing

; Device header
	Public	 HDR
HDR	DD_STR	<-1,DRV_ATTR_CHAR,PGROUP:STRATEGY,PGROUP:INTERRUPT,'SWATCmd$'>

	Public	Req,CMDTAB
Req	dd	?		; Request header save area
CMDTAB	label	word		; Function entry points
	dw	PGROUP:INIT_DRV ; 0: initialize

DATA	ends			; End DATA segment

NDATA	segment
	assume DS:PGROUP,ES:nothing

	Public	 Init_msg,No386_msg,NoSWAT_msg,NoCmd_msg,CmdOvf_msg
;;;;;;; Public	 CmdFail_msg
Init_msg db	 'SWATCMD ver 0.21  (C) Copyright 1992-93 Qualitas, Inc.  All rights reserved.',CR,LF,EOS
No386_msg db	 BEL,'様> CPU must be 386 or higher.',CR,LF,EOS
NoSWAT_msg db	 BEL,'様> No VCPI debugger interface present.',CR,LF,EOS
NoCmd_msg db	 BEL,'様> No command line specified.',CR,LF,EOS
CmdOvf_msg db	 BEL,'様> Maximum command line length (80) exceeded.',CR,LF,EOS
;;;;;;;CmdFail_msg db	 BEL,'様> Interface call to SWAT failed - do you have the right version?',CR,LF,EOS

	 public  SEPS
SEPS	 db	 ' ',TAB,'/=',0 ; Command separators (including NULL)
@NSEPS	 equ	 $-SEPS 	; Number to scan for

	 public  CMDMSG,CMDBUFF,CMDBUFF_END,PBCMDTAIL
CMDMSG	 db	 'SWATCMD:'     ; Leading part of message for SWAT log
CMDBUFF  db	 80 dup (0)	; Maximum command line
CMDBUFF_END db	 0,0		; Trailing NULL for command line & space for LF
PBCMDTAIL dw	 PGROUP:CMDBUFF ; Tail of command buffer

NDATA	ends			; End NDATA segment

CODE	segment
	assume CS:PGROUP,DS:nothing, ES:nothing

	FPPROC	 STRATEGY -- Strategy entry point
	assume	 ds:nothing,es:nothing,ss:nothing

	mov	 Req.VSEG,es	; Get segment of caller's request header
	mov	 Req.VOFF,bx	; Get offset

	ret			; Return to caller

	assume	 ds:nothing,es:nothing,ss:nothing

STRATEGY	endp		; End STRATEGY procedure

	FPPROC	 INTERRUPT -- Interrupt entry point
	assume	 ds:nothing,es:nothing,ss:nothing

	REGSAVE <ax,bx,cx,dx,si,di,ds,es> ; Save registers

	mov	 ax,cs		; Get PGROUP segment
	mov	 ds,ax		; Address it
	assume	 ds:PGROUP	; Tell the assembler

	sub	 ah,ah		; Clear high order byte
	mov	 al,es:[bx].SRH_CCD ; Get command
	or	 ax,ax		; Izit Init?
	jnz	 short INT_ERR	; Return error

	REGSAVE  <bx,es>	; Save RH pointer
	shl	 ax,1		; Index table of words
	mov	 si,ax		; Address table entry
	call	 CMDTAB[si]	; Call selected command
	REGREST  <es,bx>	; Restore RH pointer
;;;;;;	jc	 short INT_ERR	; Return error
;;;;;;
;;;;;;	STATUS	 DONE,0,0	; Everything's OK
;;;;;;	jmp	 short INT_EXIT ; Join common exit code
;;;;;;
INT_ERR:
	 mov	 HDR.DD_ATTR,0	; Bug in DOS doesn't allow char devices to
				; fail initialization -- convert to block device
	 STATUS  DONE,ERROR,ERR_UNK_CMD ; Return error
	 mov	 es:[bx].INIT_UNITS,0 ; No units defined
	 mov	 es:[bx].INIT_END_VEC.VOFF,0 ; End offset of 0
	 mov	 es:[bx].INIT_END_VEC.VSEG,cs ; Mark as ending address

INT_EXIT:
	REGREST <es,ds,di,si,dx,cx,bx,ax> ; Restore registers
	assume	 ds:nothing,es:nothing

	ret			; return to caller

	assume	 ds:nothing,es:nothing,ss:nothing

INTERRUPT	endp		; End INTERRUPT procedure

CODE	 ends			; End CODE segment

NCODE	 segment
	 assume  DS:PGROUP,es:nothing

	 extrn	 _SWAT_PRESENT:far
	 extrn	 CPUTYPE:near

Start:
	NPPROC	 INIT_TSR -- TSR initialization
	assume	 ds:nothing,es:nothing,ss:nothing
COMMENT|

Initialization entry point if program is loaded as a TSR.

On entry:
Registers at start of program

On exit:
Exit via @EXITRC

|

	 cld			; Set forward direction
	 mov	 bx,ds		; Save PSP segment

	 mov	 ax,seg PGROUP	; Get segment
	 mov	 ds,ax		; Address PGROUP
	 assume  ds:PGROUP	; Tell the assembler

; Set up DS:SI to point to command line
	 mov	 ds,bx		; Address PSP
	 assume  ds:PSPGROUP	; Tell the assembler

	 lea	 si,PSP_PARM_COUNT ; Get count in bytes
	 sub	 bx,bx		; Clear high byte
	 lods	 PSPGROUP:[si].LO ; Get count- DS:SI ==> arguments
	 mov	 bl,al		; Copy to base register
	 mov	 PSPGROUP:[si+bx].LO,CR ; Make sure it ends with CR

	 call	 INIT_COM	; Common initialization
	 mov	 al,0		; Assume success
	 jnc	 INIT_TSR_EXIT	; Jump if OK

INIT_TSR_ERR:
	 mov	 al,0ffh	; Nonzero return
INIT_TSR_EXIT:
	 DOSCALL  @EXITRC	; Return without staying resident
	 assume  ds:nothing,es:nothing,ss:nothing

INIT_TSR	 endp		; End INIT_TSR procedure

	NPPROC	 IZITWS -- Is AL a command separator?
	assume	 ds:nothing,es:PGROUP,ss:nothing
COMMENT|

If AL is a command separator (' ', TAB, /, =, CR) return ZF=1.

|

	 REGSAVE <cx,di>	; Save

	 lea	 di,SEPS	; PGROUP:DI ==> separator list
	 mov	 cx,@NSEPS	; Number of separators to scan for
  repne  scas	 SEPS[di]	; Search for AL

	 REGREST <di,cx>	; Restore

	 ret			; Return to caller with ZF significant

	 assume  ds:nothing,es:nothing,ss:nothing

IZITWS	 endp			; End IZITWS procedure
	NPPROC	 SKIP_WHITE -- Skip whitespace characters
	assume	 ds:nothing,es:nothing,ss:nothing
COMMENT|

On entry:
DS:SI ==> command line

On exit:
AL =	 First non-whitespace character found
DS:SI ==> first non-whitespace character on line

|

	 REGSAVE <es>		; Save

	 mov	 ax,seg PGROUP	; Prepare to address PGROUP
	 mov	 es,ax		; Address for IZITWS
	 assume  es:PGROUP	; Tell the assembler

@@:
	 lods	 ds:[si].LO	; Get next character
	 call	 IZITWS 	; Izit a command separator?
	 je	 short @B	; Go around again if so

	 dec	 si		; Back off to character in AL

	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SKIP_WHITE endp 		; End SKIP_WHITE procedure
	NPPROC	 FIND_WHITE -- Skip non-whitespace characters
	assume	 ds:nothing,es:nothing,ss:nothing
COMMENT|

On entry:
DS:SI ==> command line

On exit:
AL =	 First command separator found
DS:SI ==> first whitespace character on line

|

	 REGSAVE <es>		; Save

	 mov	 ax,seg PGROUP	; Prepare to address PGROUP
	 mov	 es,ax		; Address for IZITWS
	 assume  es:PGROUP	; Tell the assembler

@@:
	 lods	 ds:[si].LO	; Get next character
	 call	 IZITWS 	; Izit a command separator?
	 jne	 short @B	; Go around again if not

	 dec	 si		; Back off to character in AL

	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FIND_WHITE endp 		; End FIND_WHITE procedure
	NPPROC	 INIT_DRV -- Driver initialization
	assume	 ds:PGROUP,es:nothing,ss:nothing
COMMENT|

On entry:
ES:BX ==> request header

|

	cld			; Set forward direction
	REGSAVE  <ax,dx,si,ds>	; Save

	lds	 si,es:[bx].INIT_CMD_VEC ; Address command line
	assume	 ds:nothing	; Tell the assembler

	call	 SKIP_WHITE	; Skip any leading whitespace
	call	 FIND_WHITE	; Skip to end of program name
				; DS:SI ==> start of arguments

	call	 INIT_COM	; Call common initialization code

INIT_DRV_EXIT:
	REGREST  <ds,si,dx,ax>	; Restore
	assume	 ds:nothing	; Tell the assembler

	ret			; Return to caller

	assume	 ds:nothing,es:nothing,ss:nothing

INIT_DRV endp			; End INIT_DRV procedure

	 NPPROC  LOWERCASE -- Convert AL to Lowercase
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Convert AL to lowercase.

On entry:

AL	 =	 value to convert

On exit:

AL	 =	 converted value

|


	 cmp	 al,'A'         ; Check against lower limit
	 jb	 short @F	; Jump if too small

	 cmp	 al,'Z'         ; Check against upper limit
	 ja	 short @F	; Jump if too big

	 add	 al,'a'-'A'     ; Convert to lowercase
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LOWERCASE endp			; End LOWERCASE procedure
	NPPROC INIT_COM -- Initialization common to driver and TSR code
	assume ds:nothing,es:nothing,ss:nothing
COMMENT|

Parse command line, log it, and pass it to SWAT for execution.

On entry:
DS:SI ==> command line

On exit:
CF=1	 Failure
CF=0	 Success

|

	 REGSAVE <ax,bx,cx,dx,di,es> ; Save

	 push	 ds		; Save

	 mov	 ax,seg PGROUP	; Get PGROUP segment
	 mov	 ds,ax		; Address it
	 assume  ds:PGROUP	; Tell the assembler

	 mov	 es,ax		; Set up addressability to PGROUP for DEC2BIN
	 assume  es:PGROUP	; Tell the assembler

	 DOSCALL @STROUT,Init_msg ; Blow our horn

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler

	 call	 SKIP_WHITE	; Skip leading whitespace

; Since separators may get passed to SWAT, we need to find the trailing CR.
; Note that it's not possible to pass SWAT a leading '/'.
	 lea	 di,CMDBUFF	; Command line buffer
	 sub	 ah,ah		; Clear last character
IC_NEXTCHAR:
	 lods	 ds:[si].LO	; Get next character
	 cmp	 al,CR		; Izit the end?
	 je	 short IC_EOL	; Jump if so (note CF=0)

	 cmp	 al,LF		; Izit the end of a CONFIG.SYS line?
	 je	 short IC_EOL	; Jump if so (note CF=0)

	 cmp	 di,offset PGROUP:CMDBUFF_END ; Are we past the end?
	 cmc			; Set CF=1 if so
	 jc	 short IC_EOL	; Jump if so

	 cmp	 al,'"'         ; Izit a double quote?
	 jne	 short @F	; Jump if not

	 cmp	 ah,al		; Was the last one also a double quote?
	 jne	 short IC_LOOP	; Jump if not

@@:
S16	 stos	 CMDBUFF[di]	; Save in buffer
IC_LOOP:
	 mov	 ah,al		; Save last character
	 jmp	 short IC_NEXTCHAR ; Go around again

IC_EOL:
	 mov	 PBCMDTAIL,di	; Save pointer to trailing NULL

	 push	 es		; Move PGROUP...
	 pop	 ds		; into DS
	 assume  ds:PGROUP	; Tell the assembler

	 jc	 short INIT_COM_ERROVF ; Jump if overflow occurred

; Check for an empty command line
	 cmp	 CMDBUFF[0],0	; Was there anything?
	 je	 short INIT_COM_ERRNOCMD ; Jump if not

	 call	 CPUTYPE	; Izit a 386 or higher?
	 jc	 short INIT_COM_ERRNO386 ; Jump if not

DOT386 p
; Check for SWAT installed
	 call	 _SWAT_PRESENT	; Is 386SWAT present (DEVICE= or LOAD=) ?
	 jnc	 short INIT_COM_ERRNOSWAT ; Jump if not

	 push	 esi		; Save

	 mov	 di,PBCMDTAIL	; Address trailing NULL
	 mov	 PGROUP:[di].LO,LF ; End log line with LF

	 lea	 esi,CMDMSG	; 'SWATCMD:..."
	 mov	 bl,@DBGSYM_LDISP ; Display to log subfunction
	 VCPICALL @VCPI_DBGSYM	; Invoke VCPI debugger services

	 mov	 PGROUP:[di].LO,0 ; Clobber LF

	 lea	 esi,CMDBUFF	; Actual command
	 mov	 bl,@DBGSYM_COMMAND ; Execute command line subfunction
	 VCPICALL @VCPI_DBGSYM	; Invoke VCPI debugger services

	 pop	 esi		; Restore
;;;;;;;  jc	 short INIT_COM_ERRCMDFAIL ; Jump if API call failed
.8086
	 clc			; Indicate success
	 jmp	 short INIT_COM_EXIT ; Join common exit

INIT_COM_ERROVF:
	 lea	 dx,PGROUP:CmdOvf_msg ; Command line too long
	 jmp	 short INIT_COM_ERR ; Join common error code

INIT_COM_ERRNOCMD:
	 DOSCALL @GETPS0	; AX = current PSP
	 int	 3		; Call SWAT
	 lea	 dx,PGROUP:NoCmd_msg ; No command line specified
	 jmp	 short INIT_COM_ERR ; Join common error code

INIT_COM_ERRNO386:
	 lea	 dx,PGROUP:No386_msg ; Not a 386
	 jmp	 short INIT_COM_ERR ; Join common error code

INIT_COM_ERRNOSWAT:
	 lea	 dx,PGROUP:NoSWAT_msg ; 386SWAT not present
;;;;;;;  jmp	 short INIT_COM_ERR ; Join common error code
;;;;;;;
;;;;;;;INIT_COM_ERRCMDFAIL:
;;;;;;;  lea	 dx,PGROUP:CmdFail_msg ; API call failed
;;;;;;	 jmp	 short INIT_COM_ERR ; Join common error code

INIT_COM_ERR:
	 DOSCALL @STROUT	; Display error message at DS:DX
	 stc			; Indicate failure

INIT_COM_EXIT:
	 REGREST <es,di,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return

	 assume  ds:nothing,es:nothing,ss:nothing

INIT_COM	endp		; End procedure INIT_COM

NCODE	ends			; End NCODE segment

	end	Start

