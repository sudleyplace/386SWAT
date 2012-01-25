;' $Header:   P:/PVCS/386SWAT/SWAT_REM.ASV   1.4   10 Aug 1998 11:01:34   BOB  $
	title	SWAT_REM -- 386SWAT Remote Debugging Functions
	page	58,122
	name	SWAT_REM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1992-2002 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Henry Groover, September 1992.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include ALLMEM.INC
	include MAXDEV.INC
	include ASCII.INC
	include 8259.INC
	include CPUFLAGS.INC
	include KEYCODE.INC
	include BIOSDATA.INC
	include DOSCALL.INC

	include SWAT_COM.INC
	include SWAT_DRV.INC
	include SWAT_LOG.INC
	include SWAT_OLD.INC
	include SWAT_REM.INC
	include SWAT_SEG.INC
	include SWAT_SER.INC
.list


DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	public @SWAT_REM_DATA16
@SWAT_REM_DATA16 label byte	; Mark module start in .MAP file

	extrn	COMMON:tbyte
	include SWAT_FIL.INC

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	LC3_FLAG:dword
	include SWAT_LC3.INC

	extrn	VIDBASE_FVEC:fword
	extrn	ACTBASE_FVEC:fword
	extrn	CMDATTR:byte
	extrn	DEFATTR:byte
	extrn	TTLATTR:byte
	extrn	REGATTR:byte

	extrn	CURPOSN:word
	extrn	CURTYPE:word

	extrn	PSCRBUF:dword

	extrn	LOGBASE:dword
	extrn	LOGLEN:dword
	extrn	LOGOFF:dword
	extrn	LOGHEAD:dword

;;;;;;; extrn	OLDINTB2_FVEC:dword
;;;;;;; extrn	OLDINTC2_FVEC:dword

	extrn	OLDSTK_FVEC:fword

	public	ALTBASE_FVEC,PLASTXMSCR
ALTBASE_FVEC df ?		; Alternate VIDBASE_FVEC (points to RAM)
PLASTXMSCR dd	?		; Pointer to last screen transmitted

	public	PRECVBUF
PRECVBUF dd	?		; Pointer to receive ring buffer in DGROUP

	public	COMPORT,PORTBAUD,PORTDLATCH,PORTBASE,PORTIRQ,PORTINT
COMPORT dw	1		; Default: COM1
PORTDLATCH dw	1		; PORTBAUD / @BAUD_DIVISOR
PORTBAUD dd	@BAUD_DIVISOR	; Default: 115K baud
PORTBASE dw	@COM1BASE	; I/O port base address
PORTIRQ db	$COM13		; IRQ for port or FF for polled
PORTINT db	08h + $COM13	; Interrupt to use

;;;	    public  OLDPMGB2_FVEC,OLDPMGB2_ARB
;;;	    public  OLDPMGC2_FVEC,OLDPMGC2_ARB
;;; OLDPMGB2_FVEC PTR32_STR <>	    ; Save area for INT 0Bh handler
;;; OLDPMGC2_FVEC PTR32_STR <>	    ; ...		0Ch
;;; OLDPMGB2_ARB db CPL0_INTR3 or CPL3 ; Save area for INT 0Bh A/R byte
;;; OLDPMGC2_ARB db CPL0_INTR3 or CPL3 ; ...		   0Ch
;;;
DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public @SWAT_REM_DATA
@SWAT_REM_DATA label byte	; Mark module start in .MAP file

	extrn	MSGOFF:dword
	extrn	SCROFF:dword
	extrn	SYNTERR:byte
	extrn	SELFDBG:dword
	extrn	LBUF_HEAD:dword
	extrn	LBUF_TAIL:dword

	extrn	OLDIMR1:byte
	extrn	U32_NUMBERS_HI:byte

	public	MAXPACKET
MAXPACKET dd	1024		; Maximum packet length in bytes

	public	RECVBUF_HEAD,RECVBUF_TAIL
	align	4
RECVBUF_HEAD dd 0		; Where to write to in PRECVBUF[]
RECVBUF_TAIL dd 0		; Where to read from

	public	CHATMSG,MASTMSG,RETRYMSG,SLAVEMSG,SLAVEFAILMSG
CHATMSG db \
'-------------- Chatting with remote SWAT session -- Ctrl-F8 to end -------------',0
MASTMSG db 'Remote connection established- press M to become master, Esc to abort:',0
RETRYMSG db 'Attempting to connect with remote system - hit any key to abort',0
SLAVEMSG db 'Assuming slave role',0
SLAVEFAILMSG db 'Remote system did not respond to slave request',0

	public	MASTMSG2,NAKINMSG,NOCHARMSG,XMTERRMSG
MASTMSG2 db	'Connected to remote as master; Ctrl-F8 to suspend, Ctrl-F9 to end, Ctrl-6 to    interrupt remote system',0
NAKINMSG db	'<NAK received in response to screen packet>',0
NOCHARMSG db	'<Timeout waiting for input; CX=',0
XMTERRMSG db	'<THR not empty; AL=',0

	public	CHATBRKMSG,NULMSG,FFMSG
CHATBRKMSG db	'<BREAK>',0
NULMSG	db	'<00h>',0
FFMSG	db	'<FFh>',0

	public	PORTERR,COMERR,XMTERR
PORTERR db	'Default port base invalid',0
COMERR	db	'Use SETCOM to set up remote connection',0
XMTERR	db	'Attempt to connect aborted',0

	public	PARM_MSG,PARM_PORT,PARM_MSG2,PARM_MSG3,PARM_POLLED
PARM_MSG db	'Off COM'
PARM_PORT db	'1 ',0
PARM_MSG2 db	' bps  port ',0
PARM_MSG3 db	'h  IRQ',0
PARM_POLLED db	' (polled)',0

@MCR_HANDSHAKE	equ	 (mask $MCR_RTSHIGH) or (mask $MCR_DTRHIGH) ; Positive handshake
	public	MCR_SET
MCR_SET db	@MCR_EI or @MCR_HANDSHAKE ; Enable all signals and interrupts

	public	PACKET_IN
PACKET_IN RCMD_STR <>		; Incoming packet buffer
	db	@RCMD_MAXDATA dup (?) ; Enough space for an entire screen

	public	RACT_JMP
	align	4
RACT_JMP dd	offset PGROUP:RACT_SENDACK ; 1: ENQ
	dd	offset PGROUP:RACT_RECV ; 2: ACK
	dd	offset PGROUP:RACT_RECV ; 3: NAK (ignore)
	dd	offset PGROUP:RACT_RECV ; 4: MASTER (ignore)
	dd	offset PGROUP:RACT_RECV ; 5: SLAVE (role reversal not yet supported)
	dd	offset PGROUP:RACT_QUIT ; 6: ENDSES
	dd	offset PGROUP:RACT_KEY	 ; 7: SENDKEY
	dd	offset PGROUP:RACT_RECV ; 8: GOTO (shouldn't be received by slave)
	dd	offset PGROUP:RACT_RECV ; 9: SCROUT (")
	dd	offset PGROUP:RACT_QUITGO ; 10: ENDSESGO
	dd	offset PGROUP:RACT_REFRESH ; 11: REFresh screen
	dd	offset PGROUP:RACT_QUITRGO ; 12: ENDRESGO
	dd	offset PGROUP:RACT_REBOOT ; 13: REBOOT
	dd	offset PGROUP:RACT_RECV ; 14: CSCREEN (not received by slave)
	dd	offset PGROUP:RACT_RECV ; 15: VERSION (ignore)
	dd	offset PGROUP:RACT_VTOGGLE ; 16: VTOGGLE
	dd	offset PGROUP:RACT_BUSYSTAT ; 17: BUSYSTAT
	dd	offset PGROUP:RACT_RECV ; 18: AMBUSY (shouldn't be received)
	dd	offset PGROUP:RACT_FSEND ; 19: FSEND
	dd	offset PGROUP:RACT_FRECV ; 20: FRECV
	dd	offset PGROUP:RACT_FPACKET ; 21: FPACKET
	dd	offset PGROUP:RACT_FACK ; 22: FACK
	dd	offset PGROUP:RACT_FNAK ; 23: FNAK
	dd	offset PGROUP:RACT_FEND ; 24: FEND
	dd	offset PGROUP:RACT_FCAN ; 25: FCAN
@RACT_MAX equ	($-RACT_JMP)/(type RACT_JMP)

	public	RCDEBUG,RPINMSG,RPOUTMSG,RPERRMSG
RCDEBUG dw	0		; If != 0, display all characters received
RPINMSG db	'<RP$',0        ; Message to display on entry to RECV_PACKET
RPOUTMSG db	'$RP>',0        ; Message to display on exit if OK
RPERRMSG db	'$ERR>',0       ; Message to display on exit if error

	align	4
	public	LOGSAVEBASE,LOGSAVEOFF,PLASTXMSCR,PLASTOFF
LOGSAVEBASE df	?		; Saved VIDBASE_FVEC
LOGSAVEOFF dd	?		; Saved SCROFF
PLASTOFF dd	?		; Offset of save area within PLASTXMSCR (temp)

	public	PORTINIT,@PORTINIT_LEN
@PORTINIT_LEN equ 255		; Maximum length for PORTINIT
PORTINIT db	@PORTINIT_LEN dup (0) ; String to send out serial port
	db	0

	public	SER_TIMEOUT,LCURPOSN,LCURTYPE
	align	2
SER_TIMEOUT dw	-1		; Countdown timer for serial I/O
LCURPOSN dw	-1		; Last cursor position transmitted
LCURTYPE dw	-1		; Last cursor type transmitted

	public	APPKEYMSG,CKEYBLANK5,CKEYCURRENT,CKEYEMPTY,CKEYTEXT,CKEYCLEAR
APPKEYMSG db 'Edit application keystroke buffer -- ',25,', ',26,', Ins, Del, Esc and Alt-Esc must be    prefixed by Esc.  Alt-Esc to end.',0
CKEYBLANK5 db '     ',0         ; Leading spaces for non-selected keystroke
CKEYCURRENT db ' --> ',0        ; Leader for selected one
CKEYEMPTY db '____  ',0         ; Display for empty space at tail of buffer
CKEYTEXT db '         ',0       ; Default text for keystroke
CKEYCLEAR db '           ',0    ; Display to clear keystroke space and leader

	public	EXITMSG,RBUSYMSG,BUSYMSG,ENTERMSG,DLMSG1,DLMSG2,ULMSG1,ULMSG2
EXITMSG db	'Ctrl-F9 pressed.  (T)erminate connection immediately, terminate and have remote '
	db	'system (G)o, terminate and have remote system prepare to (R)espond again,       '
	db	're(B)oot the remote system, (S)uspend session temporarily, (U)pload to remote,  '
	db	'(D)ownload from remote, or Esc to continue:',0
RBUSYMSG db	'DOS busy or no DPMI services on remote system',0
BUSYMSG db	'DOS busy or no DPMI services on this system',0
ENTERMSG db	'Use BKSP to edit, ENTER to accept, Esc to abort',0
DLMSG1	db	'Name of file on remote system to download:',0
DLMSG2	db	'Save file locally as:',0
ULMSG1	db	'Name of file to upload to remote system:',0
ULMSG2	db	'Save file on remote system as:',0

	public	NORESPMSG,OPENFAILMSG,ROPENFAILMSG,XFERMSG,ESCMSG,CANMSG
	public	PROGRESSMSG,FILERRMSG,FXEOFMSG
NORESPMSG db	'Remote did not respond.',0
OPENFAILMSG db	'Could not create/open file.',0
ROPENFAILMSG db 'Remote could not create/open file.',0
XFERMSG db	'File transfer in progress, Esc to cancel',0
ESCMSG	db	'Cancel requested.  Press Esc again to confirm:',0
CANMSG	db	'File transfer cancelled by remote.',0
PROGRESSMSG db	'Current packet #: ',0
FILERRMSG db	'Error reading/writing file',0
FXEOFMSG db	'End of file',0

	public	XFERHNDL,READPACKET,ACKPACKET,RETRYCNT
	align	2
XFERHNDL dw	-1		; Handle for file being transferred
READPACKET dw	?		; Last packet read
ACKPACKET dw	?		; Last packet sent
RETRYCNT dw	?		; Retry count

	public	ERRLOG_TTL,ERRLOG_END
ERRLOG_TTL db	'SWAT error log- logsize=',0 ; Title for error log browser
ERRLOG_END db	'<End of error log>',0 ; End of error log

	public	ERRLOG_CLINE,TIMEOUT_DLY
	align	4
ERRLOG_CLINE dd 0		; Current starting line for ERRLOG
TIMEOUT_DLY dw	?		; Delay for packet receive timeout

; Define timeout delay values for mostly sending (slave) and mostly
; receiving (master).
@RECV_TIMEOUT equ 22		; Packet receive delay for master (1155-1210 ms)
@SEND_TIMEOUT equ 4		; Packet receive delay for slave (165-220 ms)

WIN_STR struc

WIN_SCROFF dd	?		; Current SCROFF for window
WIN_SCRBEG dd	?		; Starting SCROFF for window
WIN_SCREND dd	?		; Ending SCROFF for window

WIN_STR ends

	public	CHAT_INW,CHAT_OUTW
	align	4
CHAT_INW WIN_STR <?,0,(@NROWS/2)*@NCOLS*2> ; Display window for incoming CHAT
CHAT_OUTW WIN_STR <?,((@NROWS/2)+1)*@NCOLS*2,(@NROWS-1)*@NCOLS*2> ; Outgoing

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP,ds:PGROUP

	public @SWAT_REM_PROG
@SWAT_REM_PROG: 		; Mark module start in .MAP file

	extrn	SWATINI:tbyte

	extrn	U32_BASE2BIN:near
	extrn	CLS:near
	extrn	CLEAR_EOL:near
	extrn	CLEAR_EOP:near
	extrn	DISPASCIIZ:near
	extrn	DISPHEX0:near
	extrn	DISPHEX1:near
	extrn	DISPHEX2:near
	extrn	DISPTXT:near
	extrn	DISPDEC:near
	extrn	U32_LOWERCASE:near
	extrn	NEXTLINE:near

	extrn	CMD_WHITE:near
	extrn	PARSE_ATOM:near

	extrn	U32_DRAINPIQ:near
	extrn	LCL_INTCOM_DEVORIG:near
	extrn	LCL_INTCOM_DEVDONE:near

	extrn	CMD_REBOOT:near
	extrn	GETKEY:near

	extrn	SWATTER:far

	extrn	SAVE_SCR:near
	extrn	REST_SCR:near
	extrn	CHECK_VMOD:near

	extrn	SAVE_SCRDATA:near
	extrn	SET_CURPOS:near
	extrn	SET_CURTYP:near

	extrn	DOS_AVAIL:near
	extrn	PL0_INT21:near
	extrn	IZIT_IRQ3:near
	extrn	IZIT_IRQ4:near

	extrn	ERR_BEEP:near

	extrn	SetRVM:near
	extrn	SetPMG:near
	extrn	SetPMI:near
	extrn	PushOldInt:near
	extrn	SetSelVars:near
	extrn	MASK_STKREG1:near

	NPPROC	WDISPTXT -- Display AL to window
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display AL with default attribute to a specified window, scrolling
if necessary.

On entry:
AL	=	Character to display
DGROUP:EBX ==>	 WIN_STR

|

	REGSAVE <eax,ecx,edx,esi,edi,es,gs> ; Save

	les	edi,VIDBASE_FVEC ; Address video buffer
	assume	es:nothing	; Tell the assembler

	push	es		; Get video buffer selector
	pop	gs		; Address for move
	assume	gs:nothing	; Tell the assembler

	mov	ah,DEFATTR	; Default attribute
	mov	edx,DGROUP:[ebx].WIN_SCROFF ; Get current offset within screen

	cmp	al,CR		; Izit CR?
	jne	short @F	; Jump if not

	mov	eax,edx 	; Get offset within screen
	cdq			; Prepare to divide
	mov	ecx,@NCOLS*2	; Characters & attributes per screen row
	div	ecx		; EAX = Current row
	mul	ecx		; EAX = offset of start of row
	mov	DGROUP:[ebx].WIN_SCROFF,eax ; Save as new offset

	jmp	short WDT_EXIT	; Join common exit


@@:
	cmp	al,LF		; Izit LF?
	jne	short @F	; Jump if not

	add	edx,@NCOLS*2	; Skip to next line
@@:
	cmp	edx,DGROUP:[ebx].WIN_SCREND ; Izit within bounds?
	jb	short WDISPTXT_COM ; Jump if so
WDT_SCRUP:

; We need to scroll the window up one row

	REGSAVE <eax,edi>	; Save character to display

	mov	ecx,@NCOLS*2	; Characters & attributes in one row
	sub	edx,ecx 	; Back off offset by one line
	mov	esi,DGROUP:[ebx].WIN_SCRBEG ; Address beginning of window
	add	esi,VIDBASE_FVEC.FOFF ; Add to screen base
	mov	edi,esi 	; Save destination of move
	add	esi,ecx 	; Skip to source
	mov	ecx,DGROUP:[ebx].WIN_SCREND ; Get end of window
	sub	ecx,DGROUP:[ebx].WIN_SCRBEG ; ECX = bytes in window
	sub	ecx,@NCOLS*2	; Minus line being deleted
	shr	ecx,2		; Convert to dwords
S32 rep movs	<es:[edi].EDD,gs:[esi].EDD> ; Scroll up
	mov	ecx,@NCOLS	; Words in one row
	mov	al,' '          ; Clear screen
    rep stos	es:[edi].ELO	; Clear new line at bottom

	REGREST <edi,eax>	; Restore
WDISPTXT_COM:
	add	edi,edx 	; Get offset for this character

	cmp	al,LF		; Izit LF?
	je	short @F	; Jump if so

S32	stos	es:[edi].ELO	; Put character and attribute in screen
@@:
	sub	edi,VIDBASE_FVEC.FOFF ; Get updated screen offset
	mov	DGROUP:[ebx].WIN_SCROFF,edi ; Save it
WDT_EXIT:
	REGREST <gs,es,edi,esi,edx,ecx,eax> ; Restore
	assume	es:nothing,gs:nothing ; Tell the assembler

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WDISPTXT endp			; End WDISPTXT procedure
	NPPROC	WDISPASCIIZ -- Display string to window
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display string at DGROUP:ESI with default attribute to a specified
window, scrolling if necessary.

On entry:
DGROUP:ESI ==>	 ASCIIZ string to display
DGROUP:EBX ==>	 WIN_STR

|

	REGSAVE <eax,esi>	; Save
WDA_NEXT:
	lods	DGROUP:[esi].LO ; Get next character to display
	or	al,al		; Izit the end?
	jz	short WDA_EXIT	; Jump if so

	call	WDISPTXT	; Display AL to window EBX

	jmp	short WDA_NEXT	; Go around again


WDA_EXIT:
	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WDISPASCIIZ endp		; End WDISPASCIIZ procedure
	NPPROC	F2REMOTE_ACT -- Processing for REMOTE_ACT
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Processing for REMOTE_ACT.

|

RACT_RETSTR struc

	dw	?,?		; Saved GS
	dw	?,?		; Saved DS
RACT_LC3 dw	?		; Saved LC3_FLAG
	dd	?		; Saved EDI
	dd	?		; Saved ESI
	dd	?		; Saved EDX
	dd	?		; Saved ECX
	dd	?		; Saved EBX
RACT_RETEAX dd	?		; Saved EAX

RACT_RETSTR ends

	REGSAVE <eax,ebx,ecx,edx,esi,edi,LC3_FLAG,ds,gs> ; Save

	and	LC3_FLAG,not @LC3_SLAVE ; Enable debugging of this code
RACT_RECV:
	call	RECV_PACKET	; Check for valid incoming packet
	jnc	short RACT_NOPKT ; Jump if none
RACT_RECV2:
;;;;;;; LOGDISP MSG_GOTPACKET	; 'Packet received'

	movzx	ebx,PACKET_IN.RCMD_TYP ; Get command type
	dec	ebx		; Table starts with 1

	cmp	ebx,@RACT_MAX	; Izit within range?
	jnb	short RACT_RECV ; Jump if not

; If file transfer is in progress, bump retry in case we lost the FCAN or EOF
	cmp	XFERHNDL,-1	; Is file open?
	je	short @F	; Jump if not

	inc	RETRYCNT	; Bump it - we'll check it if no packet received
@@:
	jmp	RACT_JMP[ebx*(type RACT_JMP)] ; Process command


RACT_SENDACK:
;;;;;;; LOGDISP MSG_SENDACK	; 'Sending ACK to remote'

	mov	al,@RCMD_ACK	; Command to send
	sub	ecx,ecx 	; Length of data trailer
	call	SEND_PACKET	; Send it

	jmp	short RACT_RECV ; Go around again


RACT_NOPKT:
; Check for file transfer in progress (slave -> master)
	cmp	XFERHNDL,-1	; Is file open?
	je	short RACT_CHECKCSR ; Jump if not

	cmp	ACKPACKET,-1	; Are we sending packets to master?
	jne	near ptr RACT_SENDPACKET ; Jump if so

	cmp	RETRYCNT,@RECVERR_MAX ; Have we exceeded maximum receive error?
	cmc			; Clear CF if OK
	jnc	near ptr RACT_EXIT ; Jump if we're OK (note CF=0)

	jmp	near ptr RACT_CANCEL ; Cancel file transfer


RACT_CHECKCSR:
; Check for cursor position/type changes
	mov	ax,CURPOSN	; Get current position
	mov	bx,CURTYPE	; Get current cursor type
	cmp	ax,LCURPOSN	; Has it changed?
	jne	short RACT_SENDCUR ; Jump if so

	cmp	bx,LCURTYPE	; Has it changed?
	je	short RACT_CHECKSCR ; Jump if not

RACT_SENDCUR:
;;;;;;;  LOGDISP MSG_SENDCUR	; 'Sending cursor size/type'

	mov	PACKET_IN.RCMD_NEWCPOS,ax ; New position to send
	mov	PACKET_IN.RCMD_NEWCTYP,bx ; New type to send
	mov	al,@RCMD_GOTO	; Send cursor position/type to remote
	mov	ecx,4		; Bytes to send
	lea	esi,PACKET_IN.RCMD_NEWCPOS ; Address of data
	call	SEND_PACKET	; Send it

	call	WRECV_PACKET	; Wait to get a packet
	jnc	near ptr RACT_RECV ; Jump if none

	cmp	PACKET_IN.RCMD_TYP,@RCMD_NAK ; Was it a NAK?
	je	near ptr RACT_RECV ; Jump if so

	mov	ax,CURPOSN	; Get current position
	mov	LCURPOSN,ax	; Save for comparison
	mov	ax,CURTYPE	; Get current cursor type
	mov	LCURTYPE,ax	; Save for comparison

	cmp	PACKET_IN.RCMD_TYP,@RCMD_ACK ; Was it an ACK?
	jne	near ptr RACT_RECV2 ; Jump if not; might be another keystroke

	jmp	near ptr RACT_RECV ; Go around again


RACT_CHECKSCR:
; Note that in comparing screen data, we use word compares to keep
; screen offsets on word boundaries.
	mov	edi,PLASTXMSCR	; Last screen transmitted
	lgs	esi,VIDBASE_FVEC ; Address screen buffer
	assume	gs:nothing	; Tell the assembler

	mov	ecx,@SCRSIZE/2	; Number of char/attr pairs in screen

; Find first mismatch
	cld			; Set direction forward
   repe cmps	gs:[esi].ELO,DGROUP:[edi].ELO ; Compare
	lea	ebx,[esi-2]	; Save start of mismatch
	je	near ptr RACT_EXIT ; Jump if no mismatch (note CF=0)

; Remaining words in ECX may be more than we can send
	shl	ecx,1		; Convert words to bytes
	cmp	ecx,MAXPACKET	; Izit potentially more than maximum packet size?
	jna	short @F	; Jump if not

	mov	ecx,MAXPACKET	; Transmit in small pieces
@@:
	shr	ecx,1		; Convert bytes to words
RACT_FINDSCRMATCH:
; Now find next match
  repne cmps	gs:[esi].ELO,DGROUP:[edi].ELO ; Compare
	mov	edx,esi 	; Assume we went all the way
	jne	short RACT_XMT	; Jump if mismatch goes to end of screen

	lea	edx,[esi-2]	; Save start of match area

; Find end of matching area
   repe cmps	gs:[esi].ELO,DGROUP:[edi].ELO ; Compare

	jecxz	RACT_XMT	; Jump if trailing match goes to end of screen

	mov	eax,esi 	; Point past last matching character
	sub	eax,edx 	; (E)AX = length of matched area
	cmp	eax,20		; Does it exceed minimum overhead (GOTO
				; packet + SCROUT packet)?
	jb	short RACT_FINDSCRMATCH ; Go around again if not

RACT_XMT:
; VIDBASE_FVEC.FSEL:EBX ==> Start of area to save/transmit
; VIDBASE_FVEC.FSEL:EDX ==> End of area
	mov	esi,ebx 	; Save start of area
	sub	ebx,VIDBASE_FVEC.FOFF ; Get offset from beginning of screen
	mov	PACKET_IN.RCMD_SCROFF,ebx ; Save screen offset
	mov	ecx,edx 	; Get end
	sub	ecx,esi 	; ECX = length of screen data
	or	ecx,ecx 	; Is it a non-zero length?
	jz	near ptr RACT_EXIT ; Jump if so (note CF=0)

	call	XMT_SCREEN	; Determine optimal method and send screen
	jc	near ptr RACT_RECV2 ; Non-ACK packet received

	jmp	near ptr RACT_EXIT ; Join common exit code (note CF=0)


RACT_REBOOT:
	call	CMD_REBOOT	; We don't return from this call...
RACT_QUITRGO:
;;;;;;; LOGDISP 'Quit and reset' ; Send to error log
	or	[esp].RACT_LC3,@LC3_PORTINIT ; Call CMD_REMDBG on next SWATTER call
RACT_QUITGO:
;;;;;;; LOGDISP 'Quit and go'   ; Send to error log
	or	[esp].RACT_LC3,@LC3_EXITSWAT ; Return Esc on all GETKEY requests
RACT_QUIT:
;;;;;;; LOGDISP 'Quit remote session' ; Send to error log

	mov	bx,XFERHNDL	; Get file handle
	cmp	bx,-1		; Izit valid?
	je	short @F	; Jump if so

	mov	ah,@CLOSF2	; Close file handle in BX
	FINTD	PL0_INT21	; Simulate an Int 21h at PL0
	mov	XFERHNDL,-1	; Mark as closed
@@:
	mov	al,@RCMD_ACK	; Command to send
	sub	ecx,ecx 	; Length of data trailer
	call	SEND_PACKET	; Send it
	and	[esp].RACT_LC3,not @LC3_SLAVE ; Turn off slave mode

	test	[esp].RACT_LC3,@LC3_NOVID ; Is video off?
	jz	near ptr RACT_EXIT ; Jump if not (note CF=0)
RACT_VTOGGLE:
	lea	ebx,[esp].RACT_LC3 ; Address copy of LC3_FLAG
	call	ALT_VTOGGLE	; Toggle video with alternate

	clc			; Indicate no keystroke

	jmp	near ptr RACT_EXIT ; Join common exit code


RACT_REFRESH:
;;;;;;; LOGDISP 'Screen refresh' ; Send to error log
	mov	al,@RCMD_ACK	; Command to send
	sub	ecx,ecx 	; Length of data trailer
	call	SEND_PACKET	; Send to remote

	call	REFRESH_DISPLAY ; Blow away delta buffer

	call	RECV_PACKET	; Is anything new there?
	jc	near ptr RACT_RECV2 ; Jump if so; might be another keystroke

	jmp	near ptr RACT_NOPKT ; Send screen


RACT_KEY:
;;;;;;; LOGDISP 'Got remote key' ; Send to error log
	mov	ax,PACKET_IN.RCMD_KEYCODE ; Get keycode to return
	mov	[esp].RACT_RETEAX.ELO,ax ; Put in return stack
	mov	al,@RCMD_ACK	; Command to send
	sub	ecx,ecx 	; Length of data trailer
	call	SEND_PACKET	; Send it
	stc			; Indicate valid return

	jmp	near ptr RACT_EXIT ; Return to caller


; Entry points for file transfer.  Note that we assume that every time
; we call REMOTE_ACT, DOS will be in the same state as when the file
; was opened/created, and that PSP's haven't changed.  This will be
; true as long as the remote user keeps his hands off the keyboard...
; We could ignore all KEY_READY values while the transfer is going
; on.
RACT_SENDPACKET:
	call	DOS_AVAIL	; Are we in DOS?
	jc	near ptr RACT_CANCEL ; Jump if so

	LOGDISP 'Reading data to send'

	lea	edx,PACKET_IN.RCMD_FPACKDAT ; Address packet data field
	mov	ecx,@SCRSIZE	; Maximum bytes to read
	mov	bx,XFERHNDL	; Get file handle
	xor	eax,eax 	; Zero to use as dword
	mov	ah,@READF2	; Read ECX bytes from BX into DS:EDX
	FINTD	PL0_INT21	; Simulate an Int 21h at PL0
	jc	near ptr RACT_CANCEL ; Jump if read failed

; (E)AX contains bytes read.  If 0, it's time to send a FEND...
	LOGDISP 'Read OK'

	mov	ecx,eax 	; Copy to count register
	jecxz	RACT_SENDEOF	; Jump if end of file

	LOGDISP 'Read nonzero'

	add	ecx,type RCMD_FPACKNUM ; Add size of packet number field
	mov	dx,READPACKET	; Get last packet read
	inc	dx		; Bump it
	mov	READPACKET,dx	; Save
	sub	bx,bx		; Initialize retry counter

; Send packet and wait for a corresponding FACK.

RACT_SENDRETRY:
	REGSAVE <ecx>		; Save
	mov	al,@RCMD_FPACKET ; Send file data packet to remote
	lea	esi,PACKET_IN.RCMD_FPACKNUM ; Address start of data
	mov	PACKET_IN.RCMD_FPACKNUM,dx ; Set sequence number
	call	SEND_PACKET	; Transmit
	REGREST <ecx>		; Restore
	jc	short RACT_CANCEL ; Jump if send failed

RACT_SENDWAIT:
	call	WRECV_PACKET	; Wait for response
	jnc	short RACT_SENDTIMEOUT ; Jump if none

; We've received a packet.  If it's a matching FACK, we're OK.  If it's a
; matching FNAK, send the packet again.
	mov	al,PACKET_IN.RCMD_TYP ; Get command type

	cmp	al,@RCMD_FACK	; Izit a FACK?
	jne	short @F	; Jump if not

	cmp	PACKET_IN.RCMD_FACKNUM,dx ; Does it match?
	jne	short @F	; Jump if not (throw it away)

	jmp	near ptr RACT_NOPKT ; Go around again


@@:
	cmp	al,@RCMD_FNAK	; Izit a resend request?
	jne	short @F	; Jump if not

	cmp	PACKET_IN.RCMD_FACKNUM,dx ; Does it match?
	jne	short RACT_SENDWAIT ; Jump if not

RACT_SENDTIMEOUT:
	inc	bx		; Bump retry counter

	cmp	bx,@RESEND_MAX	; Izit below the maximum send retry count?
	jb	short RACT_SENDRETRY ; Jump if so

	jmp	short RACT_CANCEL ; No response - maximum retry exceeded


RACT_SENDEOF:
	mov	al,@RCMD_FEND	; End of file
	call	SEND_PACKET	; Send to remote
	call	WRECV_PACKET	; Wait for response
				; Ignore response; should be FACK(-1)
	jmp	near ptr RACT_FCAN ; Close file and quit


RACT_CANCEL:
	mov	al,@RCMD_FCAN	; Cancel file transfer
	sub	ecx,ecx 	; No data
	call	SEND_PACKET	; Send to remote
	call	SEND_PACKET	; Send to remote
	call	SEND_PACKET	; Send to remote

	jmp	near ptr RACT_FCAN ; Join common code to close file handle


RACT_BUSYSTAT:
; Send FACK(-1) if we can make DOS calls, or AMBUSY if not
	LOGDISP 'Busystat recvd;'

	call	DOS_AVAIL	; Are DOS services available to us?
	jc	short @F	; Jump if not

	LOGDISP 'response avail'

	mov	al,@RCMD_FACK	; Acknowledge file request
	mov	ecx,type RCMD_FACKNUM ; Bytes to send
	mov	PACKET_IN.RCMD_FACKNUM,-1 ; Send a general acknowledgement
	lea	esi,PACKET_IN.RCMD_FACKNUM ; Address of data

	jmp	short RACT_BUSYSTAT2 ; Join common code

@@:
	mov	al,@RCMD_AMBUSY ; Tell 'em we're busy
	sub	ecx,ecx 	; No data to send
RACT_BUSYSTAT2:
	call	SEND_PACKET	; Send to remote

	jmp	near ptr RACT_NOPKT ; Go around again


RACT_FSEND:

; Try to open the file specified.  If successful, send FACK(-1), otherwise FNAK

	call	DOS_AVAIL	; Are DOS services available?
	jc	short RACT_FSENDERR ; Jump if not

	mov	ah,@OPENF2	; Open file we're sending
	sub	al,al		; Set mode to R/O
	mov	ACKPACKET,0	; No packets ACKed

RACT_FOPENCOM:
;;;;;;; inc	RCDEBUG 	; Turn on debugging
	lea	edx,PACKET_IN.RCMD_FXFERNAM ; Address file to open on this end
	push	edx		; Pass offset of message
	call	LDISPMSG	; DIsplay to error log
	LOGDISP '=file to open'
	FINTD	PL0_INT21	; Simulate an Int 21h at PL0
	jc	short RACT_FSENDERR ; Jump if open failed

	mov	XFERHNDL,ax	; Save handle
	LOGDISP 'OK, handle='
	xchg	ah,al		; Swap bytes
	call	LDISPTXTB	; Dump binary AL
	mov	al,ah		; Get AL
	call	LDISPTXTB	; Dump binary AL
	mov	READPACKET,0	; No packets read
	mov	al,@RCMD_FACK	; Open succeeded

	jmp	short @F	; Join common code


RACT_FSENDERR:
	mov	al,@RCMD_FNAK	; Attempt failed
@@:
	mov	ecx,type RCMD_FACKNUM ; Bytes to send
	mov	PACKET_IN.RCMD_FACKNUM,-1 ; Send a general denial/ack
	lea	esi,PACKET_IN.RCMD_FACKNUM ; Address of data
	call	SEND_PACKET	; Send to remote

	jmp	near ptr RACT_NOPKT ; Go around again


RACT_FRECV:
; Try to create the file specified. If successful, send FACK(-1), otherwise FNAK
	call	DOS_AVAIL	; Are DOS services available?
	jc	short RACT_FSENDERR ; Jump if not

	mov	RETRYCNT,0	; Clear error retry count
	mov	ah,@CREAF2	; Create file we're downloading
	sub	ecx,ecx 	; Clear all attributes
	mov	ACKPACKET,-1	; We're receiving, not sending

	jmp	near ptr RACT_FOPENCOM ; Join common code to open file


RACT_FPACKET:
; Check packet to see if it's out of sequence
	mov	ax,READPACKET	; Get old packet #
	inc	ax		; Bump it

	cmp	ax,PACKET_IN.RCMD_FPACKNUM ; Does it match?
	je	short @F	; Jump if so

; Packet out of sequence.  Send FNAK for the one we expected.
	LOGDISP 'Packet recvd out of sequence'

	mov	PACKET_IN.RCMD_FACKNUM,ax ; Save it somewhere
	lea	esi,PACKET_IN.RCMD_FACKNUM ; Address of data
	mov	ecx,type RCMD_FACKNUM ; Length of data
	mov	al,@RCMD_FNAK	; Tell 'em we failed on this one
	call	SEND_PACKET	; Send to remote

	jmp	RACT_PTIMEOUT	; Adjust error count

@@:
	mov	READPACKET,ax	; Save packet #
	mov	RETRYCNT,0	; Clear error retry count

	push	PACKET_IN.RCMD_DLEN ; Save length of packet data

	lea	esi,PACKET_IN.RCMD_FPACKNUM ; Packet number for FACK
	mov	ecx,type RCMD_FPACKNUM ; Length of field
	mov	al,@RCMD_FACK	; Acknowledge receipt
	call	SEND_PACKET	; Send to remote

	sub	ecx,ecx 	; Clear high order word

	pop	ecx		; Get length of packet

	LOGDISP 'Packet recvd and ACKed'

	sub	ecx,(type RCMD_FPACKNUM) ; Subtract length of packet number
	jc	near ptr RACT_CANCEL ; Jump if send failed

	movzx	eax,READPACKET	; Clear high order word
	push	SCROFF		; Save offset
	call	DISPDEC 	; Display in decimal
	pop	SCROFF		; Restore

	lea	edx,PACKET_IN.RCMD_FPACKDAT ; DS:EDX ==> data to write to file
	mov	bx,XFERHNDL	; Get file handle
	mov	ah,@WRITF2	; Write to file handle
	FINTD	PL0_INT21	; Simulate an Int 21h at PL0
	jc	near ptr RACT_CANCEL ; Jump if read failed

	LOGDISP 'Write successful'

	jmp	near ptr RACT_NOPKT ; Go around again


RACT_PTIMEOUT:
	mov	ax,RETRYCNT	; Get retry count
	inc	ax		; Bump it
	mov	RETRYCNT,ax	; Save it

	cmp	ax,@RECVERR_MAX ; Have we exceeded the maximum?
	jnb	near ptr RACT_CANCEL ; Jump if so

	jmp	near ptr RACT_NOPKT ; Go around again


RACT_FACK:
	mov	ax,PACKET_IN.RCMD_FACKNUM ; Get packet number

	cmp	ax,-1		; Izit a general ACK?
	je	short @F	; Jump if so

	cmp	ax,READPACKET	; Izit a packet we haven't read?
	ja	short @F	; Ignore it if so

	cmp	ax,ACKPACKET	; Izit a packet we've already gotten an ACK for?
	jbe	short @F	; Jump if so

	mov	ACKPACKET,ax	; Note last packet acknowledged
@@:
;;;;;;; jmp	near ptr RACT_NOPKT ; Go around again


RACT_FNAK:
	jmp	near ptr RACT_NOPKT ; Go around again


RACT_FEND:
	mov	al,@RCMD_FACK	; Acknowledge end of transmission
	mov	ecx,type RCMD_FACKNUM ; Bytes to send
	mov	PACKET_IN.RCMD_FACKNUM,-1 ; Send a general ack
	lea	esi,PACKET_IN.RCMD_FACKNUM ; Address of data
	call	SEND_PACKET	; Send to remote

;;;;;;; jmp	short RACT_FCAN ; Join common code to close file handle


RACT_FCAN:
;;;;;;; dec	RCDEBUG 	; Restore debugging state
	LOGDISP 'Closing transfer'
	mov	bx,XFERHNDL	; Get file handle
	cmp	bx,-1		; Izit valid?
	je	short @F	; Jump if so

	mov	ah,@CLOSF2	; Close file handle in BX
	FINTD	PL0_INT21	; Simulate an Int 21h at PL0
	mov	XFERHNDL,-1	; Mark as closed
@@:
	jmp	near ptr RACT_NOPKT ; Go around again


RACT_EXIT:
;;;;;;; LOGDISP MSG_RACTOUT	; 'Exiting remote_act'
	REGREST <gs,ds,LC3_FLAG,edi,esi,edx,ecx,ebx,eax> ; Restore
	assume	ds:nothing,gs:nothing ; Tell the assembler

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

F2REMOTE_ACT endp		; End F2REMOTE_ACT procedure
	NPPROC	XMTS_SUB -- Put AL in output stream
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If AL == A5, prefix it with A5.  Otherwise, send it to output stream.

On entry:
AL		Character to send
DGROUP:EDI ==>	Output stream

On exit:
EDI		Updated

|

	cmp	al,0A5h 	; Izit our escape character?
	jne	short @F	; Jump if not

S32	stos	PACKET_IN.RCMD_CSDATA[edi] ; Save lead-in
@@:
S32	stos	PACKET_IN.RCMD_CSDATA[edi] ; Save it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XMTS_SUB endp			; End XMTS_SUB procedure
	NPPROC	XMT_SCREEN -- Transmit screen data to remote
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Determine best method (compressed vs. raw) and transmit screen data
to remote.

On entry:
DGROUP:EBX ==>	 Start of changed area in LASTXMSCR
GS:ESI ==>	 Screen data to transmit
(E)CX		 Number of bytes to transmit (high word always 0)

On exit:
CF=1	 Packet received in response other than ACK
CF=0	 ACK received

|

	REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save

	mov	PLASTOFF,ebx	; Save offset in PLASTXMSCR

	mov	edx,esi 	; Save source offset
	cmp	ecx,6		; Izit the minimum for compression?
	jna	near ptr XMTS_RAW ; Jump if not

; Compress the screen, then see if we save anything

	sub	ebx,ebx 	; Initialize plane counter
	lea	edi,PACKET_IN.RCMD_CSDATA ; Address compressed storage
XMTS_CPLANE:
	REGSAVE <ebx,ecx,edx>	; Save

	shr	ecx,1		; Convert to bytes per plane
	lea	esi,[edx+ebx]	; Address starting byte
XMTS_NEXTC:
	lods	gs:[esi].LO	; Get next byte
	inc	esi		; Skip other plane

	mov	ebx,ecx 	; Initialize count of additional repetitions
	mov	edx,esi 	; Temporary pointer
@@:
	cmp	gs:[edx].LO,al	; Izit the same?
	jne	short @F	; Jump if not

	add	edx,2		; Skip to next byte
	dec	ebx		; Adjust counter
	jnz	short @B	; Go around again

@@:
	sub	ebx,ecx 	; Get -(additional reps)
	neg	ebx		; Normalize it

	cmp	ebx,4		; Izit greater than the minimum?
	ja	short @F	; Jump if so

	cmp	ebx,2		; Izit greater than minimum for AL==A5?
	jna	short XMTS_EMIT ; Jump if not

	cmp	al,0A5h 	; Can we use the smaller minimum?
	jne	short XMTS_EMIT ; Jump if not

@@:
	mov	ah,al		; Save character
	mov	esi,edx 	; Update input stream
	sub	ecx,ebx 	; Update input counter

	cmp	bl,0A5h 	; Does reps.LO == A5?
	jne	short @F	; Jump if not

	mov	al,bl		; Character to send
	call	XMTS_SUB	; Send it prefixed by A5
	dec	bl		; Remove it from count
@@:
	mov	al,0A5h 	; Lead-in for compressed byte count
S32	stos	PACKET_IN.RCMD_CSDATA[edi] ; Save it
	mov	al,bl		; Low byte of repetition count
S32	stos	PACKET_IN.RCMD_CSDATA[edi] ; Save it
	mov	al,bh		; High byte of repetition count
S32	stos	PACKET_IN.RCMD_CSDATA[edi] ; Save it
	mov	al,ah		; Character to send
S32	stos	PACKET_IN.RCMD_CSDATA[edi] ; Save it

	jmp	short @F	; Join common code


XMTS_EMIT:
	call	XMTS_SUB	; Put AL in output stream
@@:
	jecxz	@F		; Jump if done
	loop	XMTS_NEXTC	; Go around again
@@:
	REGREST <edx,ecx,ebx>	; Restore

	or	ebx,ebx 	; Are we on the first plane?
	jnz	short @F	; Jump if not

	mov	eax,edi 	; Get end + 1 of storage
	sub	eax,offset DGROUP:PACKET_IN.RCMD_CSDATA ; Get length of plane 0
	mov	PACKET_IN.RCMD_CSDLEN,eax ; Save length of compressed data
@@:
	inc	ebx		; Bump plane counter
	cmp	ebx,2		; Are we done?
	jb	near ptr XMTS_CPLANE ; Jump if not

	sub	edi,offset DGROUP:PACKET_IN.RCMD_CSDATA ; Get total compressed bytes
	cmp	ecx,edi 	; Did we save anything?
	jna	short XMTS_RAW	; Jump if not

	add	edi,(type RCMD_CSCROFF) + (type RCMD_CSDLEN) ; Add other fields
	mov	PACKET_IN.RCMD_DLEN,edi ; Save total length of data
	mov	bl,@RCMD_CSCREEN ; Compressed screen transmit

	jmp	short XMTS_SENDSCR0 ; Join common code


XMTS_RAW:
	mov	PACKET_IN.RCMD_DLEN,ecx ; Save number of bytes in screen
	add	PACKET_IN.RCMD_DLEN,type RCMD_SCROFF ; Add RCMD_SCROFF value
	lea	edi,PACKET_IN.RCMD_SCRDATA ; Destination for screen data

	push	ecx		; Save count

	mov	esi,edx 	; Get source offset
S32 rep movs	<PACKET_IN.RCMD_SCRDATA[edi].LO,gs:[esi].LO> ; Move it

	pop	ecx		; Restore count

	mov	bl,@RCMD_SCROUT ; Raw screen transmit

XMTS_SENDSCR0:
	mov	ah,3		; Maximum attempts to send screen
XMTS_SENDSCR:
;;;;;;; mov	al,ah		; Get attempt number
;;;;;;; call	LDISPTXTB	; Dump binary to error log
;;;;;;; LOGDISP MSG_SENDSCR	; ' retry count to send screen'

	lea	esi,PACKET_IN.RCMD_SCROFF ; Offset of data to send
	mov	al,bl		; Get function type (raw or compressed)

	push	ecx		; Save count

	mov	ecx,PACKET_IN.RCMD_DLEN ; Bytes to send
	call	SEND_PACKET	; Send to remote system

	pop	ecx		; Restore count

	call	WRECV_PACKET	; Get ACK from remote system

	jnc	near ptr XMTS_EXIT ; Jump if nothing received (note CF=0)

	cmp	PACKET_IN.RCMD_TYP,@RCMD_NAK ; Was there an error in transmission?
	jne	short @F	; Jump if not

;;;;;;;  LOGDISP 'NAK received in response to screen' ; Send to error log

	dec	ah		; Adjust retry counter
	jnz	short XMTS_SENDSCR ; Try again

	jmp	short XMTS_EXIT ; Join common exit (note CF=0)


@@:
	mov	edi,PLASTXMSCR	; Get start of LASTXMSCR
	add	edi,PLASTOFF	; Address beginning save offset
	mov	esi,edx 	; Address start of changed data
S32 rep movs	<DGROUP:[edi],gs:[esi].LO> ; Save changes

	cmp	PACKET_IN.RCMD_TYP,@RCMD_ACK ; Was it an ACK?
	je	short XMTS_EXIT ; Jump if so (note CF=0)

	stc			; Indicate we have a packet to process
				; (might be a keystroke)
XMTS_EXIT:
	REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XMT_SCREEN endp 		; End XMT_SCREEN procedure
	NPPROC	REFRESH_DISPLAY -- Force entire display to be retransmitted
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Invalidate contents of screen delta buffer so that next SCROUT packet
will send the whole thing.

|
	REGSAVE <eax,ecx,edi,es> ; Save

	push	ds		; Get DGROUP
	pop	es		; Address it
	assume	es:DGROUP	; Tell the assembler

	mov	edi,PLASTXMSCR	; Address comparison buffer
	mov	ecx,@SCRSIZE/4	; Size of screen in dwords
	mov	eax,-1		; Filler value
	cld			; Set forward direction
    rep stos	DGROUP:[edi].EDD ; Blast away

	REGREST <es,edi,ecx,eax> ; Restore
	assume	es:nothing	; Tell the assembler

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REFRESH_DISPLAY endp		; End REFRESH_DISPLAY procedure
	NPPROC	F2SER_INIT -- Initialize serial port
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Action routine for SER_INIT.

On entry:
COMPORT 	COM port (1-4)
PORTDLATCH	Baud rate / @BAUD_DIVISOR
PORTBASE	I/O port base address
PORTIRQ 	IRQ for port or ff for polled

On exit:
@LC3_SERINT	Set if interrupt-driven I/O requested
MCR_SET 	Respecified (with RTS and DTR preserved)
PORTINT 	Set based on PORTIRQ
MAXPACKET	Set based on transmission rate

|

	REGSAVE <eax,ebx,ecx,edx,esi> ; Save

	test	LC3_FLAG,@LC3_REM ; Was SETCOM present in profile or command line?
	jz	near ptr SINIT_EXIT ; Jump if not

; We need this magic incantation in case the UART has gotten into an error
; condition.
	mov	dx,PORTBASE	; Get port base
	sub	al,al		; Zero to blast into all registers

	add	dx,@IER 	; Address IER
	out	dx,al		; Initialize IER
	call	U32_DRAINPIQ	; Drain instruction prefetch queue

	add	dx,@MCR-@IER	; Address MCR
	out	dx,al		; Initialize MCR
	call	U32_DRAINPIQ	; Drain instruction prefetch queue

	add	dx,@LSR-@MCR	; Address LSR
	out	dx,al		; Initialize LSR
	call	U32_DRAINPIQ	; Drain instruction prefetch queue

	add	dx,@MSR-@LSR	; Address MSR
	out	dx,al		; Initialize MSR
	call	U32_DRAINPIQ	; Drain instruction prefetch queue

;;;;;;; PUSHD	3		; Wait this many timer ticks
;;;;;;; call	SER_WAIT	; Wait for a while

	mov	dx,PORTBASE	; Get port base
	add	dx,@LCR 	; Address Line Control Register
	in	al,dx		; Get current value
	call	U32_DRAINPIQ	; Drain instruction prefetch queue
;;;;;;;  mov	 bx,ax		; Save old LCR value

	or	al,mask $LCR_DLATCH ; Enable divisor latch write
	out	dx,al		; Enable DLL and DLH
	call	U32_DRAINPIQ	; Drain instruction prefetch queue

	sub	dx,@LCR-@DLL	; Index Divisor Latch Low
	mov	ax,PORTDLATCH	; Get divisor latch value for baud rate
	out	dx,al		; Send low byte
	call	U32_DRAINPIQ	; Drain instruction prefetch queue

	mov	al,ah		; Get high byte
	add	dx,@DLH-@DLL	; Index Divisor Latch High
	out	dx,al		; Send high byte
	call	U32_DRAINPIQ	; Drain instruction prefetch queue

	add	dx,@LCR-@DLH	; Index Line Control Register
;;;;;;;  mov	 al,bl		; Get previous value
;;;;;;;  and	 al,mask $LCR_PSTICK ; Save meaningful bits (not)
;;;;;;;  or	 al,@LCR_P8N1	; Add parity/stop bits settings
	mov	al,@LCR_P8N1	; No parity, 8 bits, 1 stop bit
	out	dx,al		; Restore LCR and turn off DLAB
	call	U32_DRAINPIQ	; Drain instruction prefetch queue

; Now we need to enable interrupts from the UART, then reprogram the PIC
	sub	dx,@LCR-@IER	; Address Interrupt Enable Register
	sub	al,al		; Disable all interrupts
	out	dx,al		; Disable interrupts from UART
	call	U32_DRAINPIQ	; Drain instruction prefetch queue

	and	LC3_FLAG,not @LC3_SERINT ; Assume interrupts are off

	mov	al,PORTIRQ	; Get IRQ level
	and	MCR_SET,not @MCR_EI ; Turn off Enable Interrupts in MCR
	cmp	al,0ffh 	; Izit polled?
	je	short SINIT_POLLED ; Jump if so

	or	MCR_SET,@MCR_EI ; Turn on Enable Interrupts in MCR

;;;;;;; add	al,SWATINI.MD_IBV0 ; Convert to interrupt number
	add	al,08h		; Convert to interrupt number
	mov	PORTINT,al	; Save for later

;;;;;;; add	dx,@IER-@IER	; Address Interrupt Enable Register
	mov	al,(mask $IER_RX) or (mask $IER_ERR) ; Enable interrupts on byte received and BREAK
	out	dx,al		; Enable interrupts
	call	U32_DRAINPIQ	; Drain instruction prefetch queue

	mov	cl,PORTIRQ	; Get IRQ level
	mov	ax,mask $IRQ0	; Initial bit position
	shl	ax,cl		; AL = mask of bits to turn off
	not	ax		; Invert it
	mov	ah,al		; Save mask

	in	al,@IMR 	; Get current Interrupt Mask Register
	call	U32_DRAINPIQ	; Drain instruction prefetch queue

	or	LC3_FLAG,@LC3_SERINT ; Serial port interrupts active

	and	al,ah		; Turn off bit for IRQ
	and	OLDIMR1,ah	; Turn it off in IMR outside of SWAT
	out	@IMR,al 	; Enable interrupts

SINIT_POLLED:
; Assert handshaking signals high, and turn on @MCR_EI if previously set
	add	dx,@MCR-@IER	; Address Modem Control Register
	in	al,dx		; Get current setting
	call	U32_DRAINPIQ	; Drain instruction prefetch queue

	and	al,(mask $MCR_RSVD) ; Bits to preserve
	or	al,MCR_SET	; Combine with MCR settings
	out	dx,al		; Enable interrupts and assert data lines

; Determine a maximum packet length:
; BPS		 Divisor latch		Packet size (bytes)
; 76.8K - 115.2K 2 - 1			1K
; 19.2K - 76.7K  8 - 3			512 bytes
; 4800 - 19.1K	 32 - 9 		256 bytes
; 1200 - 4799	 64 - 33		128
	mov	eax,1024	; Assume maximum packet size
	cmp	PORTDLATCH,2	; Izit 76.8 or higher?
	jbe	short @F	; Jump if so

	mov	eax,512 	; Next smaller size
	cmp	PORTDLATCH,8	; Izit 19.2 or higher?
	jbe	short @F	; Jump if so

	mov	eax,256 	; Next smaller size
	cmp	PORTDLATCH,32	; Izit 4800 or higher?
	jbe	short @F	; Jump if so

	mov	eax,128 	; Smallest packet size
@@:
	mov	MAXPACKET,eax	; Save for later

	test	LC3_FLAG,@LC3_PORTINIT ; Was PORTINIT specified?
	jz	short SINIT_EXIT ; Jump if so

	sub	ah,ah		; Initialize last character
	lea	esi,PORTINIT	; Modem initialization string
SINIT_PNEXT:
	lods	PORTINIT[esi]	; Get character
	or	al,al		; Izit the end?
	jz	short SINIT_EXIT ; Jump if so

	cmp	ah,'\'          ; Are we in an escape sequence?
	jne	short SINIT_PNESC ; Jump if not

	call	U32_LOWERCASE	; Convert AL to lowercase

	cmp	al,'\'          ; \\ - Send a backslash
	je	short SINIT_XMT ; Jump if so

	cmp	al,'b'          ; \b - Send a break signal
	jne	short @F	; Jump if not

	call	SEND_BREAK	; Give 'em a break

	jmp	short SINIT_LOOP ; Process next


@@:
	cmp	al,'r'          ; \r - Send a CR
	jne	short @F	; Jump if not

	mov	al,CR		; Character to send

	jmp	short SINIT_XMT ; Send character to remote


@@:
	cmp	al,'p'          ; \p - Pause for 250 ms
	jne	short @F	; Jump if not

	mov	ax,5		; 4-5 timer ticks

	jmp	short SINIT_DELAY ; Join common wait code


@@:
	cmp	al,'0'          ; \1 - \0 - Wait for 1 to 10 seconds
	jb	short SINIT_XDELAY ; Jump if out of range

	cmp	al,'9'          ; Izit too high?
	ja	short SINIT_XDELAY ; Jump if so

	sub	al,'0'          ; Convert to binary
	jnz	short @F	; Jump if not 10

	mov	al,10		; Convert 0 to 10
@@:
	mov	bl,18		; Approximate timer ticks per second
	mul	bl		; AX = timer ticks
SINIT_DELAY:
	sub	ax,SER_TIMEOUT	; AX = -(target value)
	neg	ax		; Normalize countdown
@@:
	cmp	SER_TIMEOUT,ax	; Is countdown finished?
	jne	short @B	; Jump if not
;;;;;;; On a 50-Mhz 486, one clock is (1us / 50) or 20 ns.
;;;;;;; On a 33-Mhz 386, one clock is (1us / 33) or 30 ns.
;;;;;;; Each timer tick is 54,915 us.
;;;;;;;  mov	 ecx,7844983/16 ; Clocks per timer tick for 486 (7 clocks/loop)
;;;;;;;  test	 LC2_FLAG,@LC2_486 ; Izit a 486?
;;;;;;;  jnz	 short SINIT_BOGUS ; Jump if so
;;;;;;;
;;;;;;;  mov	 ecx,4576250/16 ; Clocks per timer tick for 386 (12 clocks/loop)
;;;;;;;SINIT_BOGUS:
;;;;;;;  push	 ecx		; Save loop value
;;;;;;;@@:
;;;;;;;  LOOPD	 @B		; Spin
;;;;;;;  nop			; On 386, loopd is 11+m clocks; m=1 for nop
;;;;;;;
;;;;;;;  pop	 ecx		; Restore
;;;;;;;
;;;;;;;  dec	 ax		; Decrement timer tick counter
;;;;;;;
;;;;;;;  jnz	 short SINIT_BOGUS ; Go around again
;;;;;;;
	sub	al,al		; Reset last character

	jmp	short SINIT_LOOP ; Join common code


SINIT_XDELAY:
SINIT_PNESC:
	cmp	al,'\'          ; Is it an escape sequence?
	je	short SINIT_LOOP ; Jump if so
SINIT_XMT:
	call	XMT_CHAR	; Send it out
SINIT_LOOP:
	mov	ah,al		; Save last character

	jmp	short SINIT_PNEXT ; Go around again


SINIT_EXIT:
	REGREST <esi,edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

F2SER_INIT endp 		; End F2SER_INIT procedure
	NPPROC	KEY_READY -- Check for key available
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If a key is available (for GETKEY or GETNDKEY) return with ZF=0, else
ZF=1.

|
	REGSAVE <eax>		; Save

	mov	eax,LBUF_HEAD	; Get head of keyboard buffer
	cmp	eax,LBUF_TAIL	; Compare with tail
				; Set ZF if empty

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

KEY_READY endp			; End KEY_READY procedure
	NPPROC	NC_READY -- Return number of characters ready
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return number of characters in input buffer in EAX.  Set ZF if none.

|

	mov	eax,1		; Default answer

	cmp	PORTIRQ,0ffh	; Are we in polled mode?
	je	short NCR_EXIT	; Jump if so

	mov	eax,RECVBUF_HEAD ; Address head of buffer
	sub	eax,RECVBUF_TAIL ; Subtract tail
	jnc	short NCR_EXIT	; Jump if no wrap

	add	eax,@RECVBUF_LEN ; Normalize value
NCR_EXIT:
	or	eax,eax 	; Set ZF if nothing

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

NC_READY endp			; End NC_READY procedure
	NPPROC	RCV_CHAR -- Check for character received
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If an incoming character is available, return with it in AL and ZF=0.
Otherwise, return with ZF=1.

|

	REGSAVE <ebx,ecx,edx,esi> ; Save

	mov	ebx,PRECVBUF	; Get pointer to ring buffer

	cmp	PORTIRQ,0ffh	; Are we in polled mode?
	je	short RCV_CHAR_POLLED ; Jump if so

	mov	esi,RECVBUF_TAIL ; Get tail of serial port buffer
	cmp	esi,RECVBUF_HEAD ; Izit the same as head?
	je	short RCV_CHAR_EXIT ; Jump if so (note ZF=1)

	mov	al,DGROUP:[ebx+esi].LO ; Get character
	inc	esi		; Bump pointer
	and	esi,@RECVBUF_LEN-1 ; Wrap it
	mov	RECVBUF_TAIL,esi ; Save updated read pointer

	cmp	RCDEBUG,0	; Are we dumping?
	je	short @F	; Jump if not

	call	LDISPTXTC	; Display char AL to error log
@@:
	cmp	esi,-1		; Clear ZF

	jmp	short RCV_CHAR_EXIT ; Join common exit


RCV_CHAR_POLLED:
	mov	dx,PORTBASE	; Get port base address
	add	dx,@MCR 	; Point to Modem Control Register
	mov	al,MCR_SET	; Assert handshaking signals
	out	dx,al		; Pull lines high
	call	U32_DRAINPIQ	; Drain instruction prefetch queue

	add	dl,@LSR-@MCR	; Address Line Status Register
	mov	ecx,0100h	; Number of times to try
@@:
	in	al,dx		; Get contents of LST
	test	al,mask $LSR_RCVREADY ; Is there anything in the buffer?
	loopz	@B		; Try again if not

	jz	short RCV_CHAR_EXIT ; If we timed out, exit w/ lines enabled
				; (Note ZF=1)

	sub	dl,@LSR-@MCR	; Back off to Modem Control Register
	mov	al,MCR_SET	; Get current settings
	and	al,not @MCR_HANDSHAKE ; Turn off handshaking lines
	out	dx,al		; Close the door
	call	U32_DRAINPIQ	; Drain instruction prefetch queue

	sub	dl,@MCR-@RXR	; Back off to receive buffer register
	in	al,dx		; Get character received
	or	dx,dx		; Clear ZF

RCV_CHAR_EXIT:
	REGREST <esi,edx,ecx,ebx> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RCV_CHAR endp			; End RCV_CHAR procedure
	NPPROC	UNRCV_CHAR -- Return AL to input queue
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Unget character in AL.

|
	REGSAVE <ebx,esi>	; Save

	mov	ebx,PRECVBUF	; Get pointer to ring buffer

	cmp	PORTIRQ,0ffh	; Are we in polled mode?
	je	short UNRCV_CHAR_EXIT ; Jump if so

	mov	esi,RECVBUF_TAIL ; Get tail of serial port buffer
	lea	esi,[esi+@RECVBUF_LEN-1] ; Get previous byte (wrapped)
	and	esi,@RECVBUF_LEN-1 ; Wrap it
	mov	DGROUP:[ebx+esi].LO,al ; Put it back
	mov	RECVBUF_TAIL,esi ; Save updated read pointer
UNRCV_CHAR_EXIT:
	REGREST <esi,ebx>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UNRCV_CHAR endp 		; End UNRCV_CHAR procedure
	NPPROC	WRCV_CHAR -- Wait to receive a character
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Call RCV_CHAR until we get something or a timeout occurs (250 ms).

On entry:
nothing

On exit:
If an incoming character is available, return with it in AL and ZF=0.
Otherwise, return with ZF=1.

|

	REGSAVE <ebx,ecx>	; Save

	mov	cx,SER_TIMEOUT	; Save previous value
	push	cx		; Save it

	mov	SER_TIMEOUT,5	; 55 ms per timer tic
@@:
	call	RCV_CHAR	; Is anything there?
	jnz	short @F	; Jump if so

	cmp	SER_TIMEOUT,0	; Have we timed out?
	jne	short @B	; Jump if not (note ZF=0)
@@:
	pop	bx		; Restore old SER_TIMEOUT value

	pushfd			; Save ZF
	sub	cx,SER_TIMEOUT	; Get clock ticks elapsed
	sub	bx,cx		; Subtract from old value
	mov	SER_TIMEOUT,bx	; Restore
	popfd			; Restore

	REGREST <ecx,ebx>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WRCV_CHAR endp			; End WRCV_CHAR procedure
	NPPROC	XMT_CHAR -- Send a character out
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Send character in AL out to serial port.  If the THR never clears,
return with CF=1.

|
	REGSAVE <ebx,ecx,edx,esi> ; Save

	mov	dx,PORTBASE	; Get port base address
	add	dx,@LSR 	; Address Line Status register

	mov	cx,SER_TIMEOUT	; Get previous setting
	push	cx		; Save it on stack

	mov	SER_TIMEOUT,4	; 55 ms * 4
@@:
	push	eax		; Save character to transmit
	in	al,dx		; Get LSR
	test	al,mask $LSR_XMTREADY ; Is Transmit Holding Buffer ready?
	pop	eax		; Restore

	jnz	short @F	; Jump if so

	cmp	SER_TIMEOUT,1	; Set CF if timeout occurred
	jnb	short @B	; Jump if not

	lea	esi,XMTERRMSG	; 'Timeout on transmit'
	call	LDISPASCIIZ	; Display it
	call	LDISPTXTB	; Display binary AL
	mov	al,'>'          ; Close message
	call	LDISPTXTC	; Display it

	stc			; Indicate failure

	jmp	short XMT_CHAR_EXIT ; Join common exit


@@:
	mov	dx,PORTBASE	; Get port base address
if @TXR
	add	dx,@TXR 	; Address transmit register
endif				; IF @TXR
	call	U32_DRAINPIQ	; Drain instruction prefetch queue

	out	dx,al		; Transmit character

	clc			; Indicate success
XMT_CHAR_EXIT:
	pop	bx		; Restore previous SER_TIMEOUT

	pushfd			; Save flags
	sub	cx,SER_TIMEOUT	; Get ticks elapsed
	sub	bx,cx		; Adjust old value
	mov	SER_TIMEOUT,bx	; Restore
	popfd			; Restore

	REGREST <esi,edx,ecx,ebx> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XMT_CHAR endp			; End XMT_CHAR procedure
	NPPROC	SEND_BREAK -- Send a break signal
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Send BREAK over serial port.  Note that BREAK is not an actual character;
the UART simply holds the transmit line high for about 250 ms.

|

	REGSAVE <eax,edx>	; Save

	mov	dx,PORTBASE	; Get port base address
	add	dx,@LCR 	; Address Line Control register

	in	al,dx		; Get LCR
	call	U32_DRAINPIQ	; Drain instruction prefetch queue
	or	al,mask $LCR_BREAK ; Give 'em a break
	out	dx,al		; Send to remote

	PUSHD	5		; Wait this long
	call	SER_WAIT	; Wait for a while

	and	al,not (mask $LCR_BREAK) ; Turn it off
	out	dx,al		; Do it to it

	REGREST <edx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SEND_BREAK endp 		; End SEND_BREAK procedure
	NPPROC	SEND_IBSUB -- Subroutine to SEND_IBREAK
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Send character then wait 1-2 timer tics for interrupt to complete,
since remote system may have to do a mode switch into protected
mode to field the characters we're sending it.

|

	call	XMT_CHAR	; Send AL to remote

	PUSHD	2		; Wait this long
	call	SER_WAIT	; Wait for a while

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SEND_IBSUB endp 		; End SEND_IBSUB procedure
	NPPROC	SEND_IBREAK -- Send interrupt code and break signal
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Send 'SWT!', wait to ensure that all four characters are received,
then send a BREAK signal to trigger a remote interrupt.

|
	REGSAVE <eax>		; Save

	mov	al,'S'          ; First character
	call	SEND_IBSUB	; Send to remote

	mov	al,'W'          ; Second
	call	SEND_IBSUB	; Send to remote

	mov	al,'T'          ; Third
	call	SEND_IBSUB	; Send to remote

	mov	al,'!'          ; Fourth and last
	call	SEND_IBSUB	; Send to remote

	PUSHD	4		; Wait a bit to ensure the remote system
				; doesn't get the BREAK in the same interrupt
				; as the last character.
	call	SER_WAIT	; Wait for a while

	call	SEND_BREAK	; Send BREAK signal

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SEND_IBREAK endp		; End SEND_IBREAK procedure
	NPPROC	F2CMD_CHAT -- Chat with remote SWAT user
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Action routine for CMD_CHAT.

|

	pushad			; Save

	mov	SCROFF,0	; Start from beginning
	call	CLEAR_EOP	; Clear screen
	mov	eax,CHAT_INW.WIN_SCRBEG ; Get start of window
	mov	CHAT_INW.WIN_SCROFF,eax ; Save as current offset within VIDBASE
	mov	eax,CHAT_OUTW.WIN_SCRBEG ; Get outgoing window
	mov	CHAT_OUTW.WIN_SCROFF,eax ; Save offset

	call	DISP_COMM	; Display current parameters

	mov	SCROFF,(@NROWS/2)*@NCOLS*2 ; Position for dividing message
	lea	esi,CHATMSG	; Dividing message
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI

CHAT_INCHAR:
	call	RCV_CHAR	; Is anything in the buffer?
	jz	short CHAT_KEY	; Jump if not

	lea	ebx,CHAT_INW	; Address window for incoming characters

	or	al,al		; Izit 0?
	jnz	short @F	; Jump if not

	lea	si,NULMSG	; '<NUL>'
	call	WDISPASCIIZ	; Display it

	jmp	short CHAT_KEY	; Join common code


@@:
	cmp	al,-1		; Izit FF?
	jnz	short @F	; Jump if not

	lea	esi,FFMSG	; '<FF>'
	call	WDISPASCIIZ	; Display it

	jmp	short CHAT_KEY	; Join common code


@@:
	call	WDISPTXT	; Display AL to window EBX

CHAT_KEY:
	call	KEY_READY	; Is a keystroke available?
	jz	short CHAT_INCHAR ; Jump if not

	call	GETKEY		; Get keystroke

	lea	ebx,CHAT_OUTW	; Address outgoing text window

	cmp	ax,@KEY_CTL_F8	; Izit our boy?
	je	short CHAT_EXIT ; Jump if so

	cmp	ax,@KEY_CTL_F9	; Establish remote connection?
	je	near ptr CMD_REMDBG2 ; Jump if so (note PUSHAD on stack)

	cmp	ax,@KEY_CTL_6	; Izit send BREAK?
	jne	short @F	; Jump if not

	lea	esi,CHATBRKMSG	; "<BREAK>"
	call	WDISPASCIIZ	; Display DGROUP:ESI to window EBX

	call	SEND_IBREAK	; Send 'SWT!' and break signal

	jmp	short CHAT_INCHAR ; Check for incoming character


@@:
	or	al,al		; Izit printable?
	jz	short CHAT_INCHAR ; Ignore if so

	call	XMT_CHAR	; Transmit character in AL
	jc	short CHAT_INCHAR ; Don't display if it didn't go

	call	WDISPTXT	; Display AL to window EBX

	jmp	CHAT_INCHAR	; Go around again


CHAT_EXIT:
	or	LCL_FLAG,@LCL_REDI ; Force redisplay

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

F2CMD_CHAT endp 		; End F2CMD_CHAT procedure
	NPPROC	RECV_PACKET -- Get command packet from remote system
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If any characters are incoming, attempt to parse a command packet.
If a complete packet's checksum is bad, send a NAK, otherwise return
with CF=1.  Received command packet is saved in PACKET_IN.

On entry:
nothing

On exit:
PACKET_IN Contains packet if successful; previous contents always lost
CF=1	 Packet was received and it was OK
CF=0	 No valid packet received

|

	pushad			; Save

	call	NC_READY	; Return number of characters in buffer
	cmp	eax,size RCMD_STR ; Izit the minimum packet size?
	cmc			; Set CF if OK
	jnc	near ptr RECVP_EXIT2 ; Jump if nothing or insufficient

	cmp	RCDEBUG,0	; Are we debugging input?
	je	short @F	; Jump if not

	lea	esi,RPINMSG	; '<RP$'
	call	LDISPASCIIZ	; DIsplay string to error log
@@:
	sub	eax,eax 	; Initialize signature + command
	lea	edi,DGROUP:PACKET_IN ; Address input buffer
	mov	esi,edi 	; Save address for later
	cld			; Set normal direction

; In case we're receiving spurious input, flush until there's nothing
; available or we get a signature.
RECVP_FLUSH:
	call	RCV_CHAR	; Get next character
	jz	near ptr RECVP_EXIT ; Jump if not available (note CF=0)

; To ensure that we don't throw away an SW at the end of the stream,
; check the number of characters available whenever we get an 'S'
	cmp	al,'S'          ; Izit possibly the beginning of a signature?
	jne	short @F	; Jump if so

	push	eax		; Save
	call	NC_READY	; EAX = number of characters available
	cmp	eax,3		; Do we have the other 2 bytes and command byte?
	pop	eax		; Restore
	jnb	short @F	; Jump if OK

	call	UNRCV_CHAR	; Return AL to queue

	jmp	RECVP_ERR2	; Join common error code


@@:
	movzx	ebx,al		; Save command
	ror	eax,8		; Move last character to high byte of EAX
	push	eax		; Save
	and	eax,00FFFFFFh	; Mask off command in high byte
	cmp	eax,'TWS'       ; Does signature match?
	pop	eax		; Restore
	jne	short RECVP_FLUSH ; Jump if not

S32	stos	PACKET_IN[edi].EDD ; Save signature and command byte
	mov	dx,'S'+'W'+'T'  ; Initialize checksum
	add	dx,bx		; Add command byte to checksum
RECVP_ALIGNSIG:
	cmp	bl,@RCMD_TYPMAX ; Izit within range?
	ja	near ptr RECVP_ERR ; Jump if too large

	or	bl,bl		; Izit 0?
	jz	near ptr RECVP_ERR ; Jump if so

	mov	ecx,4		; Get checksum and data length
	call	NC_READY	; Izit there?

	cmp	eax,ecx 	; Do we have enough to continue?
	jnb	short RECVP_NEXT ; Jump if so
RECVP_UNGETSIG:
; DGROUP:EDI ==> Next character to write to
	lea	esi,[edi-1]	; Address last character written

	pushfd			; Save direction flag
	std			; Move backwards
@@:
	lods	PACKET_IN[esi].LO ; Get next byte
	call	UNRCV_CHAR	; Return AL to queue
	cmp	esi,offset DGROUP:PACKET_IN ; Have we reached the start?
	jnb	short @B	; Jump if not

	popfd			; Restore direction flag

	jmp	near ptr RECVP_ERR ; Join common error code


RECVP_NEXT:
	call	RCV_CHAR	; Check for next character
	jz	near ptr RECVP_EXIT ; Jump if not there (note CF=0)

S32	stos	PACKET_IN[edi].LO ; Save character
	sub	ah,ah		; Clear high byte

	cmp	ecx,2		; Izit checksum?
	ja	short @F	; Jump if so (don't include it in checksum)

	add	dx,ax		; Add into checksum
@@:
	loop	RECVP_NEXT	; Get next character

	mov	ecx,PACKET_IN.RCMD_DLEN ; Get number of data bytes

	cmp	ecx,@RCMD_MAXDATA ; Izit above the maximum?
	ja	short RECVP_ERR ; Jump if so

	jecxz	short RECVP_CSUM ; Check checksum

; Check to see if the rest of the data are available.
	call	NC_READY	; EAX = number of characters ready

	cmp	eax,ecx 	; Do we have enough?
	jb	short RECVP_UNGETSIG ; Jump if not
RECVP_DATA:
	call	WRCV_CHAR	; Check for next character
	jnz	short @F	; Jump if received

	lea	esi,NOCHARMSG	; 'Timeout waiting for character'
	call	LDISPASCIIZ	; DIsplay to error log
	mov	al,ch		; High byte of count
	call	LDISPTXTB	; Display binary
	mov	al,cl		; Low byte of count
	call	LDISPTXTB	; Display binary
	mov	al,'>'          ; End of message
	call	LDISPTXTC	; Display char

	call	NC_READY	; Return ZF=0 if there's anything available
	jz	near ptr RECVP_UNGETSIG ; Jump if not there

	jmp	short RECVP_DATA ; Try again


@@:
S32	stos	PACKET_IN[edi].LO ; Save character
	sub	ah,ah		; Clear high byte
	add	dx,ax		; Add into checksum

	loop	RECVP_DATA	; Get next data byte
RECVP_CSUM:
	cmp	dx,PACKET_IN.RCMD_CSUM ; Izit correct?
	jne	short @F	; Jump if not

	stc			; Indicate success

	jmp	short RECVP_EXIT ; Join common exit


@@:
;;;;;;; LOGDISP '<Checksum error>' ; Display to error log

	mov	al,@RCMD_NAK	; Packet to send
	sub	ecx,ecx 	; No data
	call	SEND_PACKET	; Send command packet

	jmp	short RECVP_ERR2 ; Join common error code


RECVP_ERR:
;;;;;;;  LOGDISP '{Short pkt}'  ; Incomplete packet or bad signature

RECVP_ERR2:
	clc			; Indicate no packet received

	lea	esi,RPERRMSG	; Error output message

	jmp	short @F	; Join common exit display code


RECVP_EXIT:
	lea	esi,RPOUTMSG	; Normal output message
@@:
	pushfd			; Save flags

	cmp	RCDEBUG,0	; Are we dumping?
	je	short @F	; Jump if not

	call	LDISPASCIIZ	; Display string at DGROUP:ESI to error log
@@:
	popfd			; Restore
RECVP_EXIT2:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RECV_PACKET endp		; End RECV_PACKET procedure
	NPPROC	WRECV_PACKET -- Wait to receive packet from remote
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Wait to receive packet from remote.

|

	REGSAVE <ecx>		; Save

	mov	cx,-1		; Get default value
	mov	SER_TIMEOUT,cx	; Save as current timeout
	sub	cx,TIMEOUT_DLY	; CX = target value for timeout
@@:
	call	RECV_PACKET	; Return with CF=1 if received
	jc	short WRP_EXIT	; Jump if received (note CF=1)

	cmp	cx,SER_TIMEOUT	; Has count expired?
	jl	short @B	; Go around again if not

	LOGDISP 'Receive packet timeout'

; We need to explicitly clear CF, as the above signed comparison operates
; on SF<>OF.

	clc			; Indicate no packet available
WRP_EXIT:
	REGREST <ecx>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WRECV_PACKET endp		; End procedure WRECV_PACKET
	NPPROC	SEND_PACKET -- Send command packet to remote system
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Send packet AL to remote system with ECX bytes of data at DGROUP:ESI.

On entry:
AL	 Command type to send
ECX	 Number of bytes in data
DGROUP:ESI ==> Data to send

On exit:
nothing.  Caller is expected to call RECV_PACKET for the response.

|

	pushad			; Save

	sub	ah,ah		; Clear high byte
	mov	dx,ax		; Initialize checksum

	mov	al,'S'          ; Byte 1
	call	XMT_CHAR	; Send to remote

	mov	al,'W'          ; Byte 2
	call	XMT_CHAR	; Send to remote

	mov	al,'T'          ; Byte 3
	call	XMT_CHAR	; Send to remote

	mov	al,dl		; Get command byte
	call	XMT_CHAR	; Send AL to remote (ignore return CF)

	add	dx,'S'+'W'+'T'  ; Update checksum
	mov	al,cl		; Get low byte of data length
	add	dx,ax		; Update checksum

	mov	al,ch		; Get high byte of data length
	add	dx,ax		; Update checksum

	jecxz	short SENDP_CSUM ; Send checksum and length if no data

	cld			; Set normal direction
	REGSAVE <ecx,esi>	; Save
@@:
	lods	ds:[esi].LO	; Get next byte of data
	add	dx,ax		; Add into checksum
	loop	@B		; Go around again

	REGREST <esi,ecx>	; Restore
SENDP_CSUM:
	mov	al,dl		; Send low byte of checksum
	call	XMT_CHAR	; Send to remote
	mov	al,dh		; Send high byte of checksum
	call	XMT_CHAR	; Send to remote
	mov	al,cl		; Get low byte of data length
	call	XMT_CHAR	; Send to remote
	mov	al,ch		; Get high byte of data length
	call	XMT_CHAR	; Send to remote
	jecxz	short SENDP_EXIT ; Jump if no data

SENDP_NEXT:
	lods	ds:[esi].LO	; Get next byte of data
	call	XMT_CHAR	; Send to remote

	loop	SENDP_NEXT	; Go around until done
SENDP_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SEND_PACKET endp		; End SEND_PACKET procedure
	NPPROC	SCREEN_DECOMP -- Decompress data to screen
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Decompress ECX bytes of plane EBX to screen at DS:EDI using packbytes
encoding described in comments for RCMD_CSCREEN in SWAT_REM.INC.

On entry:
EBX		Plane: 0 for data, 1 for attributes
ECX		Number of compressed bytes to grab from input stream
DGROUP:ESI ==>	Input stream of compressed bytes
ES:EDI ==>	Base of starting video address (SCROFF already added)

On exit:
EBX		Destroyed
ECX		0
ESI		Updated
CF=1		Unexpected end of input
CF=0		OK

|

	REGSAVE <edx>		; Save
SDC_NEXT:
	mov	edx,1		; Default repetition count
	lods	PACKET_IN.RCMD_CSDATA[esi] ; Get next byte
	cmp	al,0A5h 	; Izit our lead-in byte?
	jne	short @F	; Jump if not

	dec	ecx		; Adjust counter
	jz	short SDC_ERR	; Something's wrong - bail out

	lods	PACKET_IN.RCMD_CSDATA[esi] ; Get low byte of rep count
	cmp	al,0A5h 	; Izit an escaped escape character?
	je	short @F	; Jump if so (display it)

	mov	dl,al		; Update repetition counter

	dec	ecx		; Adjust counter
	jz	short SDC_ERR	; Something's wrong - bail out

	lods	PACKET_IN.RCMD_CSDATA[esi] ; Get high byte
	dec	ecx		; Adjust counter
	jz	short SDC_ERR	; Something's wrong - bail out

	mov	dh,al		; Save high byte
	inc	edx		; Make it 1-based

	lods	PACKET_IN.RCMD_CSDATA[esi] ; Get next byte (actual char/attr)
@@:
	mov	es:[edi+ebx].LO,al ; Put in video buffer
	add	ebx,2		; Skip to next character/attribute
	dec	edx		; Bump repetition counter
	jnz	short @B	; Go around again if more repetitions

	loop	SDC_NEXT	; Go around again

	jmp	short SDC_EXIT	; Join common exit (note CF=0)


SDC_ERR:
	stc			; Indicate something went wrong
SDC_EXIT:
	REGREST <edx>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SCREEN_DECOMP endp		; End SCREEN_DECOMP procedure
	NPPROC	GET_FNAME -- Read file name
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read file name, echoing output to screen, at SCROFF.

ENTER terminates entry, Bksp is used to edit, Esc aborts.

On entry:
DGROUP:EDI ==>	Storage for filename

On exit:
ECX		Length of text entered (not including null)
CF=0		Entry completed OK
CF=1		User pressed Esc or ECX=0

|

	REGSAVE <eax,ebx,esi>	; Save

	push	SCROFF		; Save

	mov	bl,TTLATTR	; Get title attribute
	xchg	bl,DEFATTR	; Make it the default
	lea	esi,ENTERMSG	; "Enter to accept, ..."
	mov	SCROFF,16*@NCOLS*2 ; Line 17
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI
	mov	DEFATTR,bl	; Restore default

	pop	SCROFF		; Restore

	mov	bl,CMDATTR	; Get command attribute
	xchg	bl,DEFATTR	; Make it the default
	call	CLEAR_EOL	; Clear workspace

	sub	ecx,ecx 	; Set initial position
GFN_GETKEY:
	call	GETKEY		; Return keystroke in AX
	cmp	ax,@KEY_ESC	; Are we quitting?
	jne	short @F	; Jump if not

	stc			; Indicate failure

	jmp	short GFN_EXIT	; Go home


@@:
	cmp	ax,@KEY_CR	; Did user hit ENTER?
	je	short GFN_ENTER ; Jump if so

	cmp	ax,@KEY_PADENTER ; Was it ENTER on the number pad?
	je	short GFN_ENTER ; Jump if so

	cmp	ax,@KEY_BS	; Izit Backspace?
	jne	short @F	; Jump if not

	jecxz	GFN_GETKEY	; Jump if we're already at position 0

	dec	ecx		; Decrement position counter
	dec	edi		; Back off one character
	sub	SCROFF,2	; Move display position back
	mov	al,' '          ; Value to clear screen
	call	DISPTXT 	; Display it
	sub	SCROFF,2	; Prepare to display next character

	jmp	short GFN_GETKEY ; Go around again


@@:
	or	al,al		; Izit printable?
	jz	short GFN_GETKEY ; Jump if not

	cmp	ecx,128 	; Are we still in range?
	jnb	short GFN_GETKEY ; Jump if not

S32	stos	DGROUP:[edi].LO ; Save it
	call	DISPTXT 	; Display character
	inc	ecx		; Bump position counter

	jmp	short GFN_GETKEY ; Go around again


GFN_ENTER:
	sub	al,al		; Terminate with a null
S32	stos	DGROUP:[edi].LO ; Save

	cmp	ecx,1		; Were any characters entered?
GFN_EXIT:
	mov	DEFATTR,bl	; Restore

	REGREST <esi,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_FNAME endp			; End GET_FNAME procedure
	NPPROC	FILE_XFER -- Attempt file transfer to/from remote
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Attempt to transfer file to/from remote system.

Prompt the user for the name of a file to send/receive as well as a
name for the file on the destination end.

Note that the entire transfer takes place here, although it could
take place in the background at a lower priority than sending screens
and keystrokes back and forth.

If we're sending, the FX_PACK variable only gets updated as we
receive a FACK with the same number.  If receiving, it is updated
as we successfully receive each packet.  A key assumption is that
any numbered FACK implies valid receipt of all lower numbered
packets.

Note that in any transfer, the sender (the one who is primarily sending
data) has responsibility to resend packets if the expected response is
not received in the allotted time frame.  Superfluous packets will be
ignored by the receiver.  The receiver will always ACK packets immediately
upon receipt, so excessive delays will usually be caused by packet
corruption or shortening, and not by disk hardware delays on the
receiving end.

On entry:
AH='d'   Download file from remote to local system
AH='u'   Upload file from local to remote system

|

FX_STR	struc

FX_TYP	db	?,?		; (d)ownload or (u)pload
FX_FH	dw	?		; File handle
FX_LNAME db 128 dup (?) 	; Local file name
FX_RNAME db 128 dup (?) 	; Remote file name
FX_PACK dw	?		; Packet # ACKed
FX_PREAD dw	?		; Packet read and sitting in PACKET_IN
FX_RETRY dw	?		; Error retry count

FX_STR	ends

	push	ebp		; Save
	sub	esp,size FX_STR ; Allocate local storage
	mov	ebp,esp 	; Address it

	REGSAVE <es,TIMEOUT_DLY> ; Save

	pushad			; Save

	push	ds		; Get DGROUP
	pop	es		; Address for STOS
	assume	es:DGROUP	; Tell the assembler

	mov	[ebp].FX_TYP,ah ; Save action type
	mov	[ebp].FX_FH,-1	; Initialize file handle to unopened value

	mov	al,ah		; Display transfer type
	call	LDISPTXTB	; Dump binary to error log
	LOGDISP '=type; FX entry'

	lea	esi,BUSYMSG	; "DOS busy or unavailable"
	call	DOS_AVAIL	; Are DOS services available to us?
	jc	near ptr FX_ERR ; Jump if not

	LOGDISP 'FX 1: avail'

;;;;;;; inc	RCDEBUG 	; Turn on logging of characters received

	mov	al,@RCMD_BUSYSTAT ; Ask remote for busy status
	sub	ecx,ecx 	; No data
	call	SEND_PACKET	; Send packet to remote
	call	WRECV_PACKET	; Expect a response
	lea	esi,NORESPMSG	; "Remote did not respond"
	jnc	near ptr FX_ERR ; Jump if no response

	LOGDISP 'FX 2: resp to bstat'

	cmp	PACKET_IN.RCMD_TYP,@RCMD_FACK ; Izit the response we expected?
	jne	short @F	; Jump if not

	cmp	PACKET_IN.RCMD_FACKNUM,-1 ; Izit a general ACK?
	jne	near ptr FX_ERR ; Jump if not

@@:
	cmp	PACKET_IN.RCMD_TYP,@RCMD_AMBUSY ; Is remote system busy?
	lea	esi,RBUSYMSG	; "Remote busy"
	je	near ptr FX_ERR ; Jump if so

	LOGDISP 'FX 3: remote not busy'

; Get source and destination filenames
	lea	esi,DLMSG1	; "File to download"
	lea	edi,[ebp].FX_RNAME ; Destination for filename
	lea	ebx,DLMSG2	; "Save locally as"
	lea	edx,[ebp].FX_LNAME ; Other filename
	mov	al,[ebp].FX_TYP ; Get type

	cmp	al,'d'          ; Izit a download?
	je	short @F	; Good guess

	lea	esi,ULMSG1	; "File to upload to remote system"
	lea	ebx,ULMSG2	; "Save on remote as"
	xchg	edx,edi 	; Get local name first
@@:
	mov	SCROFF,19*@NCOLS*2 ; Position to display
	push	SCROFF		; Save

	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI
	mov	SCROFF,20*@NCOLS*2 ; Position to read from
	call	GET_FNAME	; Read string at DGROUP:EDI
	jc	near ptr FX_EXIT ; Jump if user pressed Esc

	mov	esi,ebx 	; Get other name
	mov	edi,edx 	; ...

	mov	SCROFF,22*@NCOLS*2 ; Position to display
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI
	mov	SCROFF,23*@NCOLS*2 ; Position to read from
	call	GET_FNAME	; Read string at DGROUP:EDI

	pop	SCROFF		; Restore screen position
	jc	near ptr FX_EXIT ; Jump if user pressed Esc

	call	CLEAR_EOP	; Clear to end of screen

; Now we have the filenames, open file locally
	lea	edx,[ebp].FX_LNAME ; Address local name
	mov	ah,@CREAF2	; Create file we're downloading
	sub	cx,cx		; Clear all attributes
	cmp	[ebp].FX_TYP,'d' ; Izit a download?
	je	short @F	; Good guess

	mov	ah,@OPENF2	; Open file we're uploading
	sub	al,al		; Set mode to R/O
@@:
	FINTD	PL0_INT21	; Simulate an Int 21h at PL0
	lea	esi,OPENFAILMSG ; "Couldn't open..."
	jc	near ptr FX_ERR ; Jump if open/create failed

	mov	[ebp].FX_FH,ax	; Save file handle

	LOGDISP 'FX 4: Opened files'

	mov	[ebp].FX_RETRY,0 ; Initialize error retry count
FX_RETRYROPEN:
	mov	al,@RCMD_FSEND	; Send file to me
	mov	TIMEOUT_DLY,@RECV_TIMEOUT ; Use timeout for mostly receiving
	cmp	[ebp].FX_TYP,'d' ; Izit a download?
	je	short @F	; Good guess

	mov	al,@RCMD_FRECV	; Prepare to receive
	mov	TIMEOUT_DLY,@SEND_TIMEOUT ; Use timeout for mostly sending
@@:
	mov	ecx,128 	; Characters to send
	lea	esi,[ebp].FX_RNAME ; Data to send
	call	SEND_PACKET	; Send to remote

	mov	SER_TIMEOUT,18	; Wait a sec...
FX_WAITROPEN:
	call	RECV_PACKET	; Wait for FACK(-1)
	lea	esi,ROPENFAILMSG ; "Remote could not open/create file"
	jc	short @F	; Jump if packet received

	cmp	SER_TIMEOUT,0	; Have we timed out?
	jg	short FX_WAITROPEN ; Jump if not

	mov	ax,[ebp].FX_RETRY ; Get retry counter
	inc	ax		; Bump it
	mov	[ebp].FX_RETRY,ax ; Save updated value

	cmp	ax,@RESEND_MAX	; Have we exceeded resend limit?
	jb	short FX_RETRYROPEN ; Try sending again if not

	jmp	near ptr FX_ERR ; Tough luck


@@:
; We have received a packet.  Reset the timer in case we need to flush.
	mov	SER_TIMEOUT,18	; Wait a sec...
	cmp	PACKET_IN.RCMD_TYP,@RCMD_FNAK ; Did the open fail?
	je	near ptr FX_ERR ; Jump if so

	cmp	PACKET_IN.RCMD_TYP,@RCMD_FACK ; Izit the response we expected?
	jne	short FX_WAITROPEN ; Jump if not

	cmp	PACKET_IN.RCMD_FACKNUM,-1 ; Izit a general ACK?
	jne	near ptr FX_ERR ; Jump if not

	LOGDISP 'FX 5: Remote open'

; File should be open on both ends.  If we're receiving, get packets till
; we get a FEND.  If we're sending, transmit until we reach EOF then send
; FEND.
	mov	[ebp].FX_PACK,0 ; Initialize packet ACK count
	mov	[ebp].FX_RETRY,0 ; Initialize retry count
	mov	[ebp].FX_PREAD,0 ; Initialize packet read count
FX_REDISP:
	call	CLS		; Clear screen
	mov	SCROFF,2*@NCOLS*2 ; Move to line 3
	lea	esi,XFERMSG	; "Transfer in progress"
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI
	call	NEXTLINE	; Move to next line
	lea	esi,PROGRESSMSG ; "Packets received"
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI
FX_NEXT:
	call	KEY_READY	; Did user press a key?
	jz	short @F	; Jump if not

	call	GETKEY		; Flush it out
	cmp	ax,@KEY_ESC	; Izit Esc?
	jne	short @F	; Jump if not

	mov	SCROFF,16*@NCOLS*2 ; Move to line 17
	lea	esi,ESCMSG	; "Press Esc again to quit"
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI
	call	GETKEY		; Get key in AX

	cmp	ax,@KEY_ESC	; Does the user REALLY want to cancel?
	jne	short FX_REDISP ; Jump if not

	mov	al,@RCMD_FCAN	; Cancel file transfer
	sub	ecx,ecx 	; No data
	call	SEND_PACKET	; Send to remote
	call	SEND_PACKET	; Send to remote
	call	SEND_PACKET	; Send to remote

	jmp	near ptr FX_ERR2 ; Join common error code


@@:
	cmp	[ebp].FX_TYP,'d' ; Are we receiving?
	jne	near ptr FX_UPLOAD ; Jump if not

	call	WRECV_PACKET	; Wait for a packet
	jnc	near ptr FX_TIMEOUT ; Jump if none available

	cmp	PACKET_IN.RCMD_TYP,@RCMD_FEND ; Izit the end of the file?
	je	near ptr FX_END ; Jump if so

	cmp	PACKET_IN.RCMD_TYP,@RCMD_FCAN ; Izit being cancelled?
	je	near ptr FX_CANCEL2 ; Jump if so

	cmp	PACKET_IN.RCMD_TYP,@RCMD_FPACKET ; Izit data?
	jne	near ptr FX_TIMEOUT ; No, so treat it as an error

; Check packet to see if it's out of sequence
	mov	ax,[ebp].FX_PACK ; Get old packet #
	inc	ax		; Bump it
	cmp	ax,PACKET_IN.RCMD_FPACKNUM ; Does it match?
	je	short @F	; Jump if so

; Packet out of sequence.  Send FNAK for the one we expected.
	mov	PACKET_IN.RCMD_FACKNUM,ax ; Save it somewhere
	lea	esi,PACKET_IN.RCMD_FACKNUM ; Address of data
	mov	ecx,type RCMD_FACKNUM ; Length of data
	mov	al,@RCMD_FNAK	; Tell 'em we failed on this one
	call	SEND_PACKET	; Send to remote

	jmp	near ptr FX_TIMEOUT ; Adjust error count


@@:
	mov	[ebp].FX_PACK,ax ; Save packet #
	mov	[ebp].FX_RETRY,0 ; Reset retry count

	push	PACKET_IN.RCMD_DLEN ; Save length of packet data

	lea	esi,PACKET_IN.RCMD_FPACKNUM ; Packet number for FACK
	mov	ecx,type RCMD_FPACKNUM ; Length of field
	mov	al,@RCMD_FACK	; Acknowledge receipt
	call	SEND_PACKET	; Send to remote

	pop	ecx		; Get length of packet
	sub	ecx,type RCMD_FPACKNUM ; Subtract length of packet number
	jc	near ptr FX_LOOP ; Jump if nothing (?)

	movzx	eax,[ebp].FX_PACK ; Clear high order word
	push	SCROFF		; Save offset
	call	DISPDEC 	; Display in decimal
	pop	SCROFF		; Restore

	lea	edx,PACKET_IN.RCMD_FPACKDAT ; DS:EDX ==> data to write to file
	mov	bx,[ebp].FX_FH	; File handle to write to
	mov	ah,@WRITF2	; Write to file handle
	FINTD	PL0_INT21	; Simulate an Int 21h at PL0
	jnc	near ptr FX_LOOP ; Jump if call succeeded

	jmp	near ptr FX_CANCEL ; Stop the presses


FX_UPLOAD:
; Read the next packet in from disk
	lea	edx,PACKET_IN.RCMD_FPACKDAT ; Address packet data field
	mov	ecx,@SCRSIZE	; Maximum bytes to read
	mov	bx,[ebp].FX_FH	; Get file handle
	xor	eax,eax 	; Zero to use as dword
	mov	ah,@READF2	; Read ECX bytes from BX into DS:EDX
	FINTD	PL0_INT21	; Simulate an Int 21h at PL0
	jc	near ptr FX_CANCEL ; Jump if read failed

	LOGDISP 'FX 6: Got packet from disk'

; (E)AX contains bytes read.  If 0, it's time to send a FEND...
	mov	ecx,eax 	; Copy to count register
	or	ecx,ecx 	; Was anything read?
	jz	near ptr FX_EOF ; Jump if not (end of file)

	add	ecx,type RCMD_FPACKNUM ; Add size of packet number field
	mov	dx,[ebp].FX_PREAD ; Get last packet read
	inc	dx		; Bump it
	mov	[ebp].FX_PREAD,dx ; Save
	sub	bx,bx		; Initialize retry counter

	movzx	eax,dx		; Clear high order word
	push	SCROFF		; Save offset
	call	DISPDEC 	; Display in decimal
	pop	SCROFF		; Restore

; Send packet and wait for a corresponding FACK.
FX_SENDRETRY:
	REGSAVE <ecx>		; Save
	mov	al,@RCMD_FPACKET ; Send file data packet to remote
	lea	esi,PACKET_IN.RCMD_FPACKNUM ; Address start of data
	mov	PACKET_IN.RCMD_FPACKNUM,dx ; Set sequence number
	call	SEND_PACKET	; Transmit
	REGREST <ecx>		; Restore
	jc	short FX_CANCEL ; Jump if send failed

FX_SENDWAIT:
	call	WRECV_PACKET	; Wait for response
	jnc	short FX_SENDTIMEOUT ; Jump if we timed out

	LOGDISP 'FX 7: Got response'

; We've received a packet.  If it's a matching FACK, we're OK.  If it's a
; matching FNAK, send the packet again.
	mov	al,PACKET_IN.RCMD_TYP ; Get command type
	cmp	al,@RCMD_FACK	; Izit a FACK?
	jne	short @F	; Jump if not

	cmp	PACKET_IN.RCMD_FACKNUM,dx ; Does it match?
	jne	short @F	; Jump if not (throw it away)

	jmp	near ptr FX_NEXT ; Go around again


@@:
	cmp	al,@RCMD_FNAK	; Izit a resend request?
	jne	short FX_SENDTIMEOUT ; Jump if not

	cmp	PACKET_IN.RCMD_FACKNUM,dx ; Does it match?
	jne	short FX_SENDWAIT ; Jump if not

FX_SENDTIMEOUT:
	inc	bx		; Bump retry counter
	cmp	bx,@RESEND_MAX	; Izit below the maximum send retry count?
	jb	short FX_SENDRETRY ; Jump if so

;;;;;;; jmp	short FX_CANCEL ; No response - maximum retry exceeded


FX_CANCEL:
	mov	al,@RCMD_FCAN	; Cancel file transmission
	sub	ecx,ecx 	; No data
	call	SEND_PACKET	; Send to remote

	lea	esi,FILERRMSG	; "Error reading/writing file"

	jmp	short FX_ERR	; Join common error code


FX_TIMEOUT:
	mov	ax,[ebp].FX_RETRY ; Get error retry count
	inc	ax		; Bump it
	mov	[ebp].FX_RETRY,ax ; Save adjusted count
	cmp	ax,@RECVERR_MAX ; Did we exceed maximum receive error count?
	lea	esi,NORESPMSG	; "No response"
	ja	short FX_ERR	; Join common error code

FX_LOOP:
	jmp	near ptr FX_NEXT ; Go around again


FX_EOF:
	lea	esi,FXEOFMSG	; "End of file"
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI

	mov	al,@RCMD_FEND	; End of file
	call	SEND_PACKET	; Send to remote
	call	WRECV_PACKET	; Wait for response
				; Ignore response; should be FACK(-1)
FX_END:
	clc			; Indicate success

	jmp	short FX_EXIT	; Join common exit code


FX_CANCEL2:
	lea	esi,CANMSG	; "Transfer cancelled by remote"
FX_ERR:
	mov	SCROFF,20*@NCOLS*2 ; Position to display
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI
	call	GETKEY		; Wait for user to press a key
FX_ERR2:
	stc			; Indicate failure

FX_EXIT:
	pushfd			; Save flags
	mov	bx,[ebp].FX_FH	; Get file handle
	cmp	bx,-1		; Izit open?
	jne	short @F	; Jump if not

	mov	ah,@CLOSF2	; Close file handle in BX
	FINTD	PL0_INT21	; Simulate an Int 21h at PL0
@@:
;;;;;;;  dec	 RCDEBUG	; Restore previous setting

	popfd			; Restore

	popad			; Restore

	REGREST <TIMEOUT_DLY,es> ; Restore
	assume	es:nothing	; Tell the assembler

	lea	esp,[esp+(size FX_STR)] ; Free local storage
	pop	ebp		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILE_XFER endp			; End FILE_XFER procedure
	NPPROC	F2CMD_REMDBG -- Connect to remote debugging session
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Action routine for CMD_REMDBG

|

	pushad			; Save

	public	CMD_REMDBG2
CMD_REMDBG2:
	REGSAVE <CURPOSN,CURTYPE> ; Save

	test	LC3_FLAG,@LC3_REM ; Has the user run SETCOM?
	jz	near ptr CREM_ERR ; Jump if not

	test	LC3_FLAG,@LC3_RSUSPEND ; Is the user resuming a suspended session?
	jnz	near ptr CREM_RESUME ; Jump if so

	test	LC3_FLAG,@LC3_SLAVE ; Is the user trying to escape bondage?
	jz	short CREM_XSLAVE ; Jump if not

;;;;;;;  LOGDISP 'Slave exiting remote session' ; Send to error log

	mov	bx,XFERHNDL	; Get file handle
	cmp	bx,-1		; Izit valid?
	je	short @F	; Jump if so

	mov	ah,@CLOSF2	; Close file handle in BX
	FINTD	PL0_INT21	; Simulate an Int 21h at PL0
	mov	XFERHNDL,-1	; Mark as closed

@@:
	and	LC3_FLAG,not @LC3_SLAVE ; End slave role
	mov	al,@RCMD_ENDSES ; Tell master it's the end

	jmp	near ptr CREM_QUIT ; Send ENDSES packet to remote


CREM_XSLAVE:
	mov	SCROFF,0	; Move to start of screen
	call	CLEAR_EOP	; Clear to end
	mov	SCROFF,0	; Move to start of screen again

	call	DISP_COMM	; Display current parameters

	mov	SCROFF,0	; Move to start of screen
	lea	esi,RETRYMSG	; "Attempting to connect"
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI
	call	NEXTLINE	; Move down a line

	sub	bx,bx		; Clear local flags

CREM_LFLAGS record $RSVD:11,$ENQRECVD:1,$VERSACK:1,$VERSRECVD:1,\
	$MASTKEY:1,$MASTER:1

; Send ENQ or SLAVE packet
CREM_SENDPKT:
	mov	al,@RCMD_ENQ	; Are you there?
	test	bx,mask $MASTER ; Are we trying to become master?
	jz	short @F	; Jump if not

	mov	al,@RCMD_SLAVE	; Ask 'em to let us do the driving
@@:
	sub	ecx,ecx 	; No data
	call	SEND_PACKET	; Send to remote user

; Respond to ENQ and wait for VERSION
CREM_WAITPKT0:
	mov	SER_TIMEOUT,3*18 ; Wait 3 seconds
CREM_WAITPKT:
	call	RECV_PACKET	; CF=1 if packet received
	jnc	near ptr CREM_NOPKT ; Jump if nothing

	mov	al,PACKET_IN.RCMD_TYP ; Get command type
	cmp	al,@RCMD_ENQ	; Izit an ENQ?
	jne	short @F	; Jump if not

CREM_RECVENQ:
	or	bx,mask $ENQRECVD ; Note current state
	mov	al,@RCMD_VERSION ; Acknowledge enquiry
	mov	ecx,type RCMD_VERSION ; Length of version field
	mov	PACKET_IN.RCMD_VERSION,@THIS_RVER ; Tell 'em the version we have
	lea	esi,PACKET_IN.RCMD_VERSION ; Pass data address
	call	SEND_PACKET	; Send to remote

	jmp	short CREM_CHECKTIMEOUT ; Join common code


@@:
	cmp	al,@RCMD_ACK	; Izit what we're waiting for?
	jne	short @F	; Jump if not

	test	bx,mask $ENQRECVD ; Did we send a VERSION packet?
	jz	short CREM_CHECKTIMEOUT ; Jump if not (ignore ACK)

	or	bx,mask $VERSACK ; Note receipt of ACK

	test	bx,mask $MASTER ; Is ACK from MASTER packet?
	jz	short CREM_CHECKTIMEOUT ; Jump if not

	jmp	CREM_RESUME	; Assume master role


@@:
	cmp	al,@RCMD_VERSION ; Is the other end sending us their version?
	jne	short @F	; Jump if not

	mov	al,@RCMD_ACK	; Acknowledge it
	call	SEND_PACKET	; Send to remote

	or	bx,mask $VERSRECVD ; Note that we received it

	jmp	short CREM_CHECKTIMEOUT ; Join common code


@@:
	cmp	al,@RCMD_NAK	; Was there a transmission error?
	je	short CREM_SENDPKT ; Jump if so

	cmp	al,@RCMD_SLAVE	; Is it the question we're waiting for?
	jne	short CREM_NOPKT ; Jump if not

	mov	al,@RCMD_ACK	; Whatever you say, boss...
	sub	ecx,ecx 	; No data
	call	SEND_PACKET	; Send to remote

	or	LC3_FLAG,@LC3_SLAVE ; Set flag for GETKEY processing

	mov	ALTBASE_FVEC.FSEL,ds ; Set selector for alternate video
	mov	TIMEOUT_DLY,@SEND_TIMEOUT ; Delay for mostly sending

	call	NEXTLINE	; Move down a line
	lea	esi,SLAVEMSG	; "Assuming slave role"
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI

	push	esi		; Offset of message
	call	LDISPMSG	; DIsplay to error log

	clc			; Indicate success

	jmp	near ptr CREM_EXIT ; Join common exit


CREM_NOPKT:
	call	KEY_READY	; Did user press a key?
	jnz	short CREM_GETKEY ; Jump if so
CREM_CHECKTIMEOUT:
	cmp	bx,(mask $ENQRECVD) or (mask $VERSACK) or (mask $VERSRECVD) ; Have we started checking for M key yet?
	jne	short @F	; Jump if so or if not ready

	or	bx,mask $MASTKEY ; We're ready for M key
	lea	esi,MASTMSG	; "Press M to become master"
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI

	jmp	near ptr CREM_WAITPKT0 ; Wait for a keystroke


@@:
	cmp	SER_TIMEOUT,0	; Did we time out?
	jg	near ptr CREM_WAITPKT ; Jump if greater (signed) than 0

	test	bx,mask $MASTER ; Are we waiting for MASTER response?
	jz	short @F	; Jump if not

	call	NEXTLINE	; Move down a line
	lea	esi,SLAVEFAILMSG ; Slave failed to respond
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI

	jmp	near ptr CREM_SENDPKT ; Send MASTER packet again


@@:
	test	bx,mask $VERSRECVD ; Are we waiting for a keystroke?
	jz	near ptr CREM_SENDPKT ; Jump if not; it's a timeout

	jmp	CREM_WAITPKT0	; Wait for a keystroke


CREM_GETKEY:
	call	GETKEY		; Flush keyboard buffer
	cmp	ax,@KEY_CTL_6	; Izit a remote interrupt request?
	jne	short @F	; Jump if not

	call	SEND_IBREAK	; Send 'SWT!' and break signal

	jmp	CREM_WAITPKT0	; Go around again


@@:
	test	bx,mask $MASTKEY ; Are we waiting for a keystroke?
	jz	short CREM_XMTERR ; Jump if not

	cmp	ax,@KEY_ESC	; Izit Esc?
	je	near ptr CREM_EXIT ; Join common exit (note CF=0)

	call	U32_LOWERCASE	; Convert AL to lowercase
	cmp	al,'m'          ; So you wanna be the master, huh?
	jne	near ptr CREM_WAITPKT ; Jump if not - ignore it

	or	bx,mask $MASTER ; Ask remote to become slave

	jmp	near ptr CREM_SENDPKT ; Send packet


CREM_XMTERR:
	mov	MSGOFF,offset DGROUP:XMTERR ; Save offset of error message

	jmp	near ptr CREM_ERR2 ; Join common error code


CREM_RESUME:
	mov	SCROFF,0	; Move to start of screen
	call	CLEAR_EOP	; Clear to end
	mov	SCROFF,0	; Move to start of screen again

	lea	esi,MASTMSG2	; "Ctrl-F9 to quit"
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI

	mov	TIMEOUT_DLY,@RECV_TIMEOUT ; Delay for mostly receiving
	and	LC3_FLAG,not @LC3_RSUSPEND ; Mark as no longer suspended
CREM_REFRESH:
	mov	al,@RCMD_REF	; Refresh remote screen
	sub	ecx,ecx 	; No data trailer
	call	SEND_PACKET	; Send to remote

	call	WRECV_PACKET	; Wait for a response
CREM_MLOOP:
	call	KEY_READY	; Do we have any keystrokes?
	jz	near ptr CREM_NOKEY ; Jump if not

	call	GETKEY		; Get a local keystroke
	cmp	ax,@KEY_CTL_F9	; Izit an exit request?
	jne	near ptr CREM_XF9 ; Jump if not

	call	CLS		; Clear screen
	mov	SCROFF,4*80*2	; Move to line 5
	lea	esi,EXITMSG	; Display message
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI
CREM_CONFIRM:
	call	GETKEY		; Get keystroke in AX

	cmp	ax,@KEY_ESC	; Does the user want to continue?
	je	short CREM_REFRESH ; Jump if so (resend screen)

	call	U32_LOWERCASE	; Convert AL to lowercase
	mov	ah,al		; Save for comparison

	mov	al,@RCMD_ENDSES ; Assume immediate termination
	cmp	ah,'t'          ; Izit immediate termination?
	je	near ptr CREM_QUIT ; Jump if so

	mov	al,@RCMD_ENDSESGO ; End session and resume
	cmp	ah,'g'          ; Izit and go?
	je	near ptr CREM_QUIT ; Jump if so

	mov	al,@RCMD_ENDRESGO ; End session, reset, and resume
	cmp	ah,'r'          ; Izit reset and go?
	je	near ptr CREM_QUIT ; Jump if so

	mov	al,@RCMD_REBOOT ; Remote boot request
	cmp	ah,'b'          ; Izit boot remote system?
	je	near ptr CREM_QUIT ; Send packet and exit

	cmp	ah,'s'          ; Izit suspend session?
	jne	short @F	; Jump if not

	or	LC3_FLAG,@LC3_RSUSPEND ; Mark as suspended

	jmp	near ptr CREM_EXIT ; Join common exit (note CF=0)


@@:
	cmp	ah,'d'          ; Izit download?
	je	short @F	; Jump if so

	cmp	ah,'u'          ; Izit upload?
	jne	near ptr CREM_GETKEY ; Jump if not

@@:
	call	FILE_XFER	; Attempt file transfer

	jmp	near ptr CREM_REFRESH ; Redisplay screen


CREM_XF9:
	cmp	ax,@KEY_CTL_6	; Izit a remote interrupt request?
	jne	short @F	; Jump if not

	call	SEND_IBREAK	; Send 'SWT!' and break signal

	jmp	near ptr CREM_MLOOP ; Go around again


@@:
	cmp	ax,@KEY_ALT_F7	; Izit toggle video base?
	jne	short @F	; Jump if not

	mov	al,@RCMD_VTOGGLE ; Tell remote to toggle video base
	call	SEND_PACKET	; Send to remote

	call	WRECV_PACKET	; Expect an ACK

	jmp	near ptr CREM_MLOOP ; Go around again (ignore error code)


@@:
	mov	PACKET_IN.RCMD_KEYCODE,ax ; Save outgoing key code
;;;;;;;@@:
	mov	ecx,2		; Bytes of data
	lea	esi,DGROUP:PACKET_IN.RCMD_KEYCODE ; Address of data
	mov	al,@RCMD_SENDKEY ; Send key to remote
	call	SEND_PACKET	; Transmit packet to remote

	call	WRECV_PACKET	; Expect an ACK
	jnc	near ptr CREM_MLOOP ; Jump if nothing

;;;;;;;  cmp	 PACKET_IN.RCMD_TYP,@RCMD_NAK ; Was there an error in transmission?
;;;;;;;  je	 short @B	; Send it again if so
;;;;;;;
	cmp	PACKET_IN.RCMD_TYP,@RCMD_ACK ; Is it what we expected?
	jne	short CREM_PACKET ; Jump if not

	jmp	near ptr CREM_MLOOP ; See if we have any other keystrokes to send


CREM_NOKEY:
	call	RECV_PACKET	; Do we have any incoming packets?
	jnc	near ptr CREM_MLOOP ; Jump if not

CREM_PACKET:
	mov	al,PACKET_IN.RCMD_TYP ; Get command type
	cmp	al,@RCMD_ENDSES ; Did slave request end of session?
	jne	short CREM_XEND ; Jump if not

	mov	al,@RCMD_ACK	; Acknowledge request
	sub	ecx,ecx 	; No data
	call	SEND_PACKET	; Send to remote

	jmp	near ptr CREM_EXIT ; Exit with CF significant


CREM_XEND:
	cmp	al,@RCMD_GOTO	; Did slave send us a cursor position?
	jne	short CREM_XGOTO ; Jump if not

	mov	al,@RCMD_ACK	; Acknowledge transmission
	sub	ecx,ecx 	; No data trailer
	call	SEND_PACKET	; Send to remote system

	mov	ax,PACKET_IN.RCMD_NEWCPOS ; Get new cursor position
	cmp	ax,CURPOSN	; Is there any change?
	je	short @F	; Jump if not

	mov	CURPOSN,ax	; Save it
	push	ax		; Get new cursor position
	call	SET_CURPOS	; Set it
@@:
	mov	ax,PACKET_IN.RCMD_NEWCTYP ; Get new cursor type
	cmp	ax,CURTYPE	; Is there any change?
	je	short @F	; Jump if not

	mov	CURTYPE,ax	; Save it
	push	ax		; New cursor type
	call	SET_CURTYP	; Set it
@@:
	jmp	near ptr CREM_MLOOP ; Go around again


CREM_XGOTO:
	cmp	al,@RCMD_SCROUT ; Did slave send us screen data?
	jne	short CREM_XSCROUT ; Jump if not

	push	es		; Save

	les	edi,VIDBASE_FVEC ; Address video buffer
	assume	es:nothing	; Tell the assembler

	mov	ecx,PACKET_IN.RCMD_SCROFF ; Get offset within screen
	add	edi,ecx 	; Add to start of screen

	mov	ecx,PACKET_IN.RCMD_DLEN ; Number of bytes to move
	sub	ecx,type RCMD_SCROFF ; Less position bytes
	jc	short @F	; Jump if empty

	mov	al,@RCMD_ACK	; Acknowledge transmission
	push	ecx		; Save
	sub	ecx,ecx 	; No data trailer
	call	SEND_PACKET	; Send to remote system
	pop	ecx		; Restore

	lea	esi,PACKET_IN.RCMD_SCRDATA ; Start of data received

S32 rep movs	<es:[edi].LO,PACKET_IN[esi].LO> ; Move it
@@:
	pop	es		; Restore
	assume	es:DGROUP	; Tell the assembler

	jmp	near ptr CREM_MLOOP ; Go around again


CREM_XSCROUT:
	cmp	al,@RCMD_CSCREEN ; Izit a compressed screen?
	jne	short CREM_XCSCREEN ; Jump if not

	push	es		; Save

	les	edi,VIDBASE_FVEC ; Address video buffer
	assume	es:nothing	; Tell the assembler

	mov	ecx,PACKET_IN.RCMD_CSCROFF ; Get offset within screen
	add	edi,ecx 	; Add to start of screen

	mov	ecx,PACKET_IN.RCMD_DLEN ; Number of bytes received
	sub	ecx,(type RCMD_CSCROFF) + (type RCMD_CSDLEN) ; Less position bytes & data length
	jbe	short CREM_CSEXIT ; Jump if empty or worse

	mov	al,@RCMD_ACK	; Acknowledge transmission
	push	ecx		; Save
	sub	ecx,ecx 	; No data trailer
	call	SEND_PACKET	; Send to remote system
	pop	ecx		; Restore

	lea	esi,PACKET_IN.RCMD_CSDATA ; Start of data received
	sub	ecx,PACKET_IN.RCMD_CSDLEN ; Get bytes remaining when plane 0 done
	jc	short CREM_CSEXIT ; Jump if in error

	xchg	ecx,PACKET_IN.RCMD_CSDLEN ; Get count of compressed bytes in plane 0
	cmp	ecx,0		; Are there any?
	je	short @F	; Jump if none

	jl	CREM_CSEXIT	; Jump if in error

	sub	ebx,ebx 	; Initialize offset pointer for plane 0
	call	SCREEN_DECOMP	; Decompress data bytes
	jc	short CREM_CSEXIT ; Jump if we ran out of input

@@:
	mov	ecx,PACKET_IN.RCMD_CSDLEN ; Get length of attribute plane
	mov	ebx,1		; Initialize offset pointer for plane 1
	call	SCREEN_DECOMP	; Decompress attribute bytes
CREM_CSEXIT:
	pop	es		; Restore
	assume	es:DGROUP	; Tell the assembler

;;;;;;; jmp	near ptr CREM_MLOOP ; Go around again


CREM_XCSCREEN:
	jmp	near ptr CREM_MLOOP ; Go around again


CREM_QUIT:
	sub	ecx,ecx 	; No data
	call	SEND_PACKET	; Send to remote

	test	LC3_FLAG,@LC3_NOVID ; Is display disabled?
	jz	short @F	; Jump if not

	lea	ebx,LC3_FLAG	; Address copy of LC3_FLAG
	call	ALT_VTOGGLE	; Switch video buffers
@@:
	mov	SER_TIMEOUT,2*18 ; About 2 seconds
CREM_QUIT2:
	call	RECV_PACKET	; Check for incoming packet
	jnc	short @F	; Jump if none

	cmp	PACKET_IN.RCMD_TYP,@RCMD_ACK ; Izit the one we're waiting for?
	je	short CREM_EXIT ; Jump if so (note CF=0)
@@:
	cmp	SER_TIMEOUT,0	; Izit greater (signed) than 0?
	jg	short CREM_QUIT2 ; Try again if so

CREM_ERR:
	mov	MSGOFF,offset DGROUP:COMERR ; Save offset of error message
CREM_ERR2:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Indicate failure
CREM_EXIT:
	pushfd			; Save
	or	LCL_FLAG,@LCL_REDI ; Force redisplay
	popfd			; Restore

	REGREST <CURTYPE,CURPOSN> ; Restore

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

F2CMD_REMDBG endp		; End F2CMD_REMDBG procedure
	NPPROC	SER_WAIT -- Wait Fixed Time For Serial Port
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Wait a fixed amount of time for a serial port delay

|

SERW_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
SERW_TIME dd	?		; Amount to wait

SERW_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,SER_TIMEOUT> ; Save registers

	mov	ax,[ebp].SERW_TIME.ELO ; Get the delay amount
	mov	SER_TIMEOUT,ax	; Wait this long
@@:
	cmp	SER_TIMEOUT,0	; Is countdown finished?
	jne	short @B	; Jump if not

	REGREST <SER_TIMEOUT,eax> ; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SER_WAIT endp			; End SER_WAIT procedure
	NPPROC	LDISPTXTC -- Put A Character In The Error Log
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Blast AL into the error log.  If AL is a line feed, insert as many
spaces as are required to pad the line to @ERRLOG_ROWLEN characters.  The buffer
itself is aligned on an @ERRLOG_ROWLEN-character boundary.

|

	public	@ERRLOG_ROWLEN
@ERRLOG_ROWLEN equ 80		; Row length of error log buffer

	REGSAVE <eax,ebx,ecx,edx,ds> ; Save

	SETDATA ds		; Address DGROUP
	assume	ds:DGROUP	; Tell the assembler

	cmp	al,CR		; Izit EOL?
	je	near ptr LDISPTXTC_EXIT ; Jump if so (just ignore it)

	cmp	al,BEL		; Izit BEL?
	jne	short @F	; Jump if not

	call	ERR_BEEP	; Beep the speaker

	jmp	short LDISPTXTC_EXIT ; Just ignore it


@@:
	cmp	al,BRK		; Izit conditional LF?
	jne	short @F	; Jump if not

	mov	ebx,@ERRLOG_ROWLEN ; Maximum characters per record
	mov	eax,LOGOFF	; Dividend
	sub	edx,edx 	; Clear high dword
	div	ebx		; (E)DX = LOGOFF mod @ERRLOG_ROWLEN

	and	edx,edx 	; Izit at the left edge?
	jz	short LDISPTXTC_EXIT ; Jump if so (ignore this char)

	mov	al,LF		; Force a new line
@@:
	mov	ecx,1		; Assume 1 iteration

	cmp	al,LF		; Izit end of line?
	jne	short @F	; Jump if not

; Pad the line with 79 - (LOGOFF mod @ERRLOG_ROWLEN) spaces.

	mov	ecx,@ERRLOG_ROWLEN ; Maximum characters per record
	mov	ebx,ecx 	; Divisor
	mov	eax,LOGOFF	; Dividend
	sub	edx,edx 	; Clear high dword
	div	ebx		; (E)DX = LOGOFF mod @ERRLOG_ROWLEN
	sub	ecx,edx 	; Spaces to pad plus 1 for original LF
	mov	al,LF		; Restore character to display
@@:
	mov	ebx,LOGBASE	; Get base offset of log
	mov	edx,LOGOFF	; Get current log display offset
LDISPTXTC_NEXT:
	mov	DGROUP:[ebx+edx].LO,' ' ; Assume we're padding a line
	cmp	ecx,1		; Izit the final character?
	ja	short @F	; Jump if not

	mov	DGROUP:[ebx+edx].LO,al ; Save it
@@:
	inc	edx		; Update pointer
	cmp	edx,LOGLEN	; Izit below the limit?
	jb	short @F	; Jump if so

	sub	edx,edx 	; Start at the beginning
@@:
	mov	LOGOFF,edx	; Save

	cmp	edx,LOGHEAD	; Are we swallowing our tail?
	jne	short LDISPTXTC_LOOP ; Jump if not

	add	edx,@ERRLOG_ROWLEN ; Bump head pointer by 1 record
	cmp	edx,LOGLEN	; Izit below the limit?
	jb	short @F	; Jump if so

	sub	edx,edx 	; Start at beginning
@@:
	mov	LOGHEAD,edx	; Save
LDISPTXTC_LOOP:
	loop	LDISPTXTC_NEXT	 ; Display next iteration
LDISPTXTC_EXIT:
	REGREST <ds,edx,ecx,ebx,eax> ; Restore
	assume	ds:nothing	; Tell the assembler

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LDISPTXTC endp			; End LDISPTXTC procedure
	NPPROC	LDISPTXTB -- Put A Byte In The Error Log
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Blast AL (formatted into a two-byte ASCII value) into the error log.

|

	REGSAVE <eax,ebx,ds>	; Save for a moment

	SETDATA ds		; Address DGROUP
	assume	ds:DGROUP	; Tell the assembler

	mov	ah,0		; Zero to use as word
	shl	ax,4		; Shift high-order nibble of AL into AH
	shr	al,4		; low-order nibble of AL unchanged
	lea	ebx,U32_NUMBERS_HI ; DS:EBX ==> hex translate table
	xlat	U32_NUMBERS_HI[ebx] ; Translate the low-order nibble
	xchg	al,ah		; Swap 'em
	xlat	U32_NUMBERS_HI[ebx] ; Translate the high-order nibble

	call	LDISPTXTC	; Blast it into log

	xchg	al,ah		; Swap 'em

	call	LDISPTXTC	; Blast it into log

	REGREST <ds,ebx,eax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LDISPTXTB endp			; End LDISPTXTB procedure
	NPPROC	LDISPASCIIZ -- Display string to error log
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Blast string at DS:ESI into the error log.

|

	REGSAVE <eax,esi>	; Save
@@:
	lods	ds:[esi].LO	; Get next character

	or	al,al		; Izit the end?
	jz	short @F	; Jump if so

	call	LDISPTXTC	; Blast it into log

	jmp	short @B	; Go around again


@@:
	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LDISPASCIIZ endp		; End LDISPASCIIZ procedure
	NPPROC	LDISPMSG -- Display message to error log
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display string pointed to by dword on stack to error log,
with LF appended.  *** To be added: %register and ^register
(for registers and SWAT-internal registers). ***

|

LDISPMSG_STR struc
LDISPMSG_DS dw	?,?		; Saved caller's DS
LDISPMSG_ESI dd ?		; Saved caller's ESI
LDISPMSG_EAX dd ?		; Saved caller's EAX
LDISPMSG_FLAGS dd ?		; Saved caller's flags
LDISPMSG_EIP dd ?		; Saved caller's EIP
LDISPMSG_OFFSET dd ?		; Offset in DGROUP of error message
LDISPMSG_STR ends

	pushfd			; Save flags

	REGSAVE <eax,esi,ds>	; Save

	mov	esi,[esp].LDISPMSG_OFFSET ; Get offset to display
	SETDATA ds		; Address DGROUP
	assume	ds:DGROUP	; Tell the assembler

@@:
	lods	DGROUP:[esi].LO ; Get next character
	or	al,al		; Izit the end?
	jz	short @F	; Jump if so

	call	LDISPTXTC	; Blast it into log

	jmp	short @B	; Go around again


@@:
	mov	al,LF		; End of line
	call	LDISPTXTC	; Blast it into log

	REGREST <ds,esi,eax>	; Restore
	assume	ds:nothing	; Tell the assembler

	popfd			; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LDISPMSG endp			; End LDISPMSG procedure
	FPPROC	LCL_RVMB2 -- IRQ3 handler (COM2/COM4)
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local IRQ3 handler from RM/VCPI mode.

|

	call	SetRVM		; Set RM/VCPI mode

	jmp	short LCL_INTB2_COM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_RVMB2 endp			; End LCL_RVMB2 procedure
	FPPROC	LCL_PMGB2 -- IRQ3 handler (COM2/COM4)
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local IRQ3 handler from PM Interrupt gate mode.

|

	call	SetPMG		; Set PM Interrupt Gate mode

	jmp	short LCL_INTB2_COM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_PMGB2 endp			; End LCL_PMGB2 procedure
	FPPROC	LCL_INTB2 -- IRQ3 handler (COM2/COM4)
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Process serial port interrupts for COM2 or COM4.

|

INTxx_STR struc

INTxx_GDTDR df	?		; GDTD selector/base
INTxx_ECX  dd	?		; Old ECX
INTxx_EBX  dd	?		; ... EBX
INTxx_EAX  dd	?		; ... EAX
;----- Second IRETD frame ------------------------
INTxx_FVEC df	?		; Old handler selector|offset
INTxx_DS   dw	?		; ... DS
INTxx_EFL2 dd	?		; ... EFLAGS from our handler
;----- Original IRETD frame ----------------------
INTxx_EIP  dd	?		; Interrupted EIP
INTxx_CS   dw	?		; ... CS
INTxx_CSFILL dw ?		; ... CS filler
INTxx_EFL  dd	?		; ... EFL (IF=TF=0)

INTxx_STR ends

@INTxx_IRET2 equ (INTxx_FVEC)	; Starting offset within structure before
				; EAX, EBX, etc. are saved/allocated

@INTxx_IRET3 equ (INTxx_EIP)	; Original IRETD frame


	call	SetPMI		; Set PM Intrude mode

	public	LCL_INTB2_COM
LCL_INTB2_COM:
	pushfd			; Save EFLAGS

	PUSHW	ds		; Save incoming DS

	SETDATA ds		; Get addressability to DGROUP
	assume	ds:DGROUP	; Tell the assembler

	call	SetSelVars	; Set selector variables
	call	MASK_STKREG1	; Mask off the high-order word of stack
				; register if 16-bit stack
	call	IZIT_IRQ3	; Izit IRQ3?
	jz	near ptr INT0B_ORIG_POP ; Jump if not

	test	LC3_FLAG,@LC3_SERINT ; Is the serial port interrupt active?
	jz	near ptr INT0B_ORIG ; Jump if not

	cmp	PORTIRQ,$COM24	; Are we active?
	jne	near ptr INT0B_ORIG ; Jump if not

	SELFBREAK INT0B,200h	; Call SWAT if SELFDBG&200h

	REGSAVE <eax,ebx,ecx,edx,edi> ; Save

	mov	ebx,PRECVBUF	; Get pointer to ring buffer

	sub	ah,ah		; Clear SWATTER flag
	mov	ecx,4		; Maximum number of events
INT0B_GETIID:
	mov	dx,PORTBASE	; Get I/O port base address
	add	dx,@IIR 	; Index Interrupt Identification Register
	in	al,dx		; Get IIR value
	and	al,(mask $IIR_ID) or (mask $IIR_PENDING) ; Isolate ID bits

; Note that if multiple bits in IER are enabled, we may need to
; read IIR multiple times to determine if this interrupt covers
; multiple events.  The only ones we're interested in are Break/error
; and character received.
	test	al,mask $IIR_PENDING ; Are we done?
	jnz	short INT0B_EXIT ; Jump if so

	cmp	al,@IIR_ERR shl $IIR_ID ; Izit Break?
	je	short INT0B_BREAK ; Jump if so

	cmp	al,@IIR_RX shl $IIR_ID ; Izit data received?
	je	short INT0B_RX	; Jump if so

	cmp	al,@IIR_THR_EMPTY shl $IIR_ID ; Izit ready to transmit?
	je	short INT0B_THR_EMPTY ; Jump if so

	jmp	short INT0B_DELTA ; MSR delta


INT0B_RX:
	mov	dx,PORTBASE	; Get port base
if @RXR
	add	dx,@RXR 	; Index data received register
endif				; IF @RXR
	in	al,dx		; Get character received
	mov	edi,RECVBUF_HEAD ; Get next write location
	mov	DGROUP:[ebx+edi].LO,al ; Save in ring buffer

	inc	edi		; Increment pointer
	and	edi,@RECVBUF_LEN-1 ; Wrap it
	mov	RECVBUF_HEAD,edi ; Save for next write

	cmp	edi,RECVBUF_TAIL ; Have we swallowed our tail?
	jne	short @F	; Jump if not

	inc	edi		; Bump it
	and	edi,@RECVBUF_LEN-1 ; Wrap it
	mov	RECVBUF_TAIL,edi ; Save new value
@@:
;;;;;;; sti			; Enable interrupts

	jmp	short INT0B_NEXT_IIR ; Process next IIR value


INT0B_BREAK:
	call	CHECK_BREAK	; Check for BREAK following 'SWT!'

	jmp	short INT0B_NEXT_IIR ; Process pending interrupts


INT0B_DELTA:
	mov	dx,PORTBASE	; Get port base
	add	dx,@MSR 	; Index Modem Status Register
	in	al,dx		; Get status to reset IER

;;;;;;; jmp	short INT0B_NEXT_IIR ; Join common code


INT0B_THR_EMPTY:
INT0B_NEXT_IIR:
	loop	INT0B_GETIID	; Go around again
INT0B_EXIT:
	mov	al,@EOI 	; Non-specific EOI
	out	@ICR,al 	; Tell the PIC about it

	or	ah,ah		; Are we supposed to call SWATTER?
	REGREST <edi,edx,ecx,ebx,eax> ; Restore

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler

	lea	esp,[esp+(type INTxx_EFL2)] ; Discard saved flags, preserving ZF
	jnz	near ptr INTxx_SWATTER ; Jump if so
INTxx_DONE:
;;;;;;; test	[esp].DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].DEVSTK_EFL,mask $R2 ; Izit from RM?
	jz	short @F	; Jump if not

;;;;;;; xchg	eax,[esp].DEVSTK_EIP ; Get return address
;;;;;;; mov	[esp].DEVSTK_ORIG,eax ; Set as previous handler address
;;;;;;; xchg	eax,[esp].DEVSTK_EIP ; Restore EAX

	jmp	LCL_INTCOM_DEVDONE ; Return to device driver code


@@:
	iretd			; Return to caller

	assume	ds:DGROUP	; Tell the assembler
INT0B_ORIG_POP:
	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

	lea	esp,[esp+4]	; Strip the error code

	pushfd			; Save EFLAGS

	PUSHW	ds		; Save incoming DS

	SETDATA ds		; Get addressability to DGROUP
	assume	ds:DGROUP	; Tell the assembler
INT0B_ORIG:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	OLDINT_MAC B2		; Push old interrupt vactors
;;;;;;; push	OLDINTB2_FVEC.FSEL ; Pass old selector
;;;;;;; push	OLDINTB2_FVEC.FOFF ; Pass old offset

	public	INTxx_ORIG
INTxx_ORIG:

; If the interrupt occurred within SWAT, we need to simulate the
; interrupt.  Otherwise, we can simply pass control to MAX.
; Since MAX expects SS to point to PGROUP, we need to simulate the ring
; transition that won't take place.

	SELFBREAK INTxx,800h	; Break if SELFDBG&800h

; If interrupt came from RM,
; strip bogus IDT caller from second IRETD frame on stack and join
; code at LCL_INTCOM_DEVORIG.

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short @F	; Jump if so

;;;;;;; test	[esp-@INTxx_IRET2].INTxx_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp-@INTxx_IRET2].INTxx_EFL,mask $R2 ; Izit from RM?
	jz	short @F	; Jump if not

	add	esp,(type INTxx_FVEC) ; Strip bogus selector|offset from stack

	jmp	LCL_INTCOM_DEVORIG ; Join code to return to original handler
				; in device driver

@@:
	REGSAVE <eax,ebx,ecx>	; Save

	sub	esp,type INTxx_GDTDR ; Allocate space for GDT selector/base

; To simulate the SS:eSP MAX assumes it should have as a result of
; the PMI21 call gate task switch, we need to snatch the expected
; SS:eSP from the TSS.
; Note we need not have SS:EBP ==> FORW_STR.

	mov	ds,COMMON.FILE_4GB ; Address AGROUP
	assume	ds:AGROUP	; Tell the assembler

	SGDTD	[esp].INTxx_GDTDR ; Get GDT base

	sub	eax,eax 	; Clear high word of index
	str	ax		; Get current TSS selector
	and	ax,not (mask $PL) ; Clear the Privilege Level bits
	add	eax,[esp].INTxx_GDTDR.DTR_BASE ; Get address of TR descriptor

	push	ebx		; Save for a moment

	mov	ebx,eax 	; Address descriptor
	mov	eax,AGROUP:[ebx].DESC_BASE2.EDD ; Get bytes 2-xx-3
	rol	eax,8		; Put byte 2 in AH and byte 3 in AL
	xchg	al,ah		; Swap to normal order
	shl	eax,16		; Shift to high-order word
	mov	ax,AGROUP:[ebx].DESC_BASE01 ; Get bytes 0-1

	pop	ebx		; Restore

; If interrupt occurred outside of SWAT and we're already on MAX's stack,
; we don't need to switch.  Regardless of origin, we can't count on
; SS:EBP ==> FORW_STR.

	mov	cx,ss		; Get current stack selector

	cmp	cx,AGROUP:[eax].TSS_SS0 ; Are we already on MAX's stack?
	jne	short INTxx_SWAT ; Jump if not

;;;;;;; LOGDISP 'INTxx_ORIG: On PL0 stack' ; Display to error log

	mov	ds,[esp].INTxx_DS ; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	add	esp,type INTxx_GDTDR ; Free GDT selector/base

;;;;;;; mov	ax,ss		; Get stack selector
;;;;;;; shl	eax,16		; Move into high word
;;;;;;; mov	ax,386Fh	; Code for low word
;;;;;;; mov	CR2,eax 	; Save for debugging

	REGREST <ecx,ebx,eax>	; Restore from MAX's stack

;;;;;;; mov	CR2,esp 	; Save in CR2 for debugging

	iretd			; Continue with next handler

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

; Get PL0 SS:eSP from TSS
; CX = SS
; AGROUP:EAX ==> TSS
INTxx_SWAT:
	SETDATA ds		; Address DGROUP
	assume	ds:DGROUP	; Tell the assembler about it

	mov	ebx,esp 	; Save SWAT's stack pointer

;;;;;;; LOGDISP 'INTxx_ORIG: On SWAT stack' ; Display to error log
;;;;;;;
;;;;;;; mov	CR2,esp 	; Save in CR2 for debugging

; Save previous contents of OLDSTK_FVEC in case we're reentrant

	push	OLDSTK_FVEC.FSEL ; Save stack selector
	push	OLDSTK_FVEC.FOFF ;   "     "  offset

; Save our current stack pointers

	mov	OLDSTK_FVEC.FSEL,ss ; Save current stack
	mov	OLDSTK_FVEC.FOFF,esp ;	     "

	mov	ds,COMMON.FILE_4GB ; Address AGROUP
	assume	ds:AGROUP	; Tell the assembler

; This interrupt occurred inside SWATTER, which itself was called from
; one of SWAT's IDT handlers with a return stack.  We need to back off
; by the maximum allocation used by a SWATTER caller.  It is currently
; LCL_INT67_HOST, where we not only call SWATTER with a V86 mode IRETD
; frame and local flags on the stack, but we do so to initialize the
; serial port.	It's not only possible but likely that this code will
; execute in that case, so we need to make sure the V86 mode IRETD frame
; doesn't get clobbered, since the last task switch was the one that
; occurred when the Int 67h was executed.
;;;;;;; cli			; Don't allow interrupts until we've backed off

	lss	esp,AGROUP:[eax].TSS_ESP0.EDF ; Get PL0 stack ptr from TSS
	assume	ss:nothing	; Tell the assembler

	sub	esp,(type FORW_STR) + 2 ; FORW_STR happens to be at least the
				; size of a V86 mode IRETD frame.  Also allow
				; a word for local flags saved in LCL_INT67

;;;;;;; mov	eax,esp 	; Get new stack pointer
;;;;;;; rol	eax,12		; Get 3 high nybbles
;;;;;;; or	ax,0BADh	; Fold in magic value
;;;;;;; ror	eax,12		; Put in high position
;;;;;;; mov	CR2,eax 	; Save for debugging

;;;;;;; cli			; Keep interrupts disabled

	mov	ds,cx		; Get former stack selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	push	DGROUP:[ebx].INTxx_EFL ; Put saved flags on MAX's stack

	int	01h

	call	DGROUP:[ebx].INTxx_FVEC ; Call previous handler

	lss	esp,OLDSTK_FVEC ; Restore stack
	assume	ss:nothing	; Tell the assembler

	pop	OLDSTK_FVEC.FOFF ; Restore previous OLDSTK_FVEC offset
	pop	OLDSTK_FVEC.FSEL ; Restore previous OLDSTK_FVEC selector

	add	esp,type INTxx_GDTDR ; Free GDT selector/base

;;;;;;; sub	eax,eax 	; Magic value for CR2
;;;;;;; mov	cr2,eax 	; Save for debugging

	REGREST <ecx,ebx,eax>	; Restore from our stack
	add	esp,size PTR32_STR ; Strip old handler

	POPW	ds		; Restore interrupted DS
	assume	ds:nothing	; Tell the assembler

	lea	esp,[esp+(type INTxx_EFL2)] ; Discard saved flags, preserving ZF
	iretd			; Return to interrupted SWAT code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	public	INTxx_SWATTER
INTxx_SWATTER:
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	FCALLD	SWATTER 	; Call our debugger with IRETD frame on stack

	iretd			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INTB2 endp			; End LCL_INTB2 procedure
	FPPROC	LCL_RVMC2 -- IRQ4 handler (COM1/COM3)
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local IRQ4 handler from RM/VCPI mode.

|

	call	SetRVM		; Set RM/VCPI mode

	jmp	short LCL_INTC2_COM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_RVMC2 endp			; End LCL_RVMC2 procedure
	FPPROC	LCL_PMGC2 -- IRQ4 handler (COM1/COM3)
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local IRQ4 handler from PM Interrupt gate mode.

|

	call	SetPMG		; Set PM Interrupt Gate mode

	jmp	short LCL_INTC2_COM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_PMGC2 endp			; End LCL_PMGC2 procedure
	FPPROC	LCL_INTC2 -- IRQ4 handler (COM1/COM3)
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Process serial port interrupts for COM1 or COM3.
Note that LCL_INT0C is the stack fault handler in SWAT_INT.ASM,
but is not active unless TRAPSTACK is specified.

|

	call	SetPMI		; Set PM Intrude mode

	public	LCL_INTC2_COM
LCL_INTC2_COM:
	pushfd			; Save EFLAGS

	PUSHW	ds		; Save incoming DS

	SETDATA ds		; Get addressability to DGROUP
	assume	ds:DGROUP	; Tell the assembler

	call	SetSelVars	; Set selector variables
	call	MASK_STKREG1	; Mask off the high-order word of stack
				; register if 16-bit stack
	call	IZIT_IRQ4	; Izit IRQ4?
	jz	near ptr INT0C_ORIG_POP ; Jump if not

	test	LC3_FLAG,@LC3_SERINT ; Is the serial port interrupt active?
	jz	near ptr INT0C_ORIG ; Jump if not

	cmp	PORTIRQ,$COM13	; Are we active?
	jne	near ptr INT0C_ORIG ; Jump if not

	SELFBREAK INT0C,400h	; Call SWAT if SELFDBG&400h

	REGSAVE <eax,ebx,ecx,edx,edi> ; Save

	mov	ebx,PRECVBUF	; Get pointer to ring buffer

	sub	ah,ah		; Clear SWATTER flag
	mov	ecx,4		; Maximum number of events
INT0C_GETIID:
	mov	dx,PORTBASE	; Get I/O port base address
	add	dx,@IIR 	; Index Interrupt Identification Register
	in	al,dx		; Get IIR value
	and	al,(mask $IIR_ID) or (mask $IIR_PENDING) ; Isolate ID bits

; Note that if multiple bits in IER are enabled, we may need to
; read IIR multiple times to determine if this interrupt covers
; multiple events.  The only ones we're interested in are Break/error
; and character received.

	test	al,mask $IIR_PENDING ; Are we done?
	jnz	short INT0C_EXIT ; Jump if not

	cmp	al,@IIR_ERR shl $IIR_ID ; Izit Break?
	je	short INT0C_BREAK ; Jump if so

	cmp	al,@IIR_RX shl $IIR_ID ; Izit data received?
	je	short INT0C_RX	; Jump if so

	cmp	al,@IIR_THR_EMPTY shl $IIR_ID ; Izit ready to transmit?
	je	short INT0C_THR_EMPTY ; Jump if so

	jmp	short INT0C_DELTA ; MSR delta


INT0C_RX:
	mov	dx,PORTBASE	; Get port base
if @RXR
	add	dx,@RXR 	; Index data received register
endif				; IF @RXR
	in	al,dx		; Get character received
	mov	edi,RECVBUF_HEAD ; Get next write location
	mov	DGROUP:[ebx+edi].LO,al ; Save in ring buffer

	inc	edi		; Increment pointer
	and	edi,@RECVBUF_LEN-1 ; Wrap it
	mov	RECVBUF_HEAD,edi ; Save for next write

	cmp	edi,RECVBUF_TAIL ; Have we swallowed our tail?
	jne	short @F	; Jump if not

	inc	edi		; Bump it
	and	edi,@RECVBUF_LEN-1 ; Wrap it
	mov	RECVBUF_TAIL,edi ; Save new value
@@:
;;;;;;; sti			; Enable interrupts

	jmp	short INT0C_NEXT_IIR ; Process next IIR value


INT0C_BREAK:
	call	CHECK_BREAK	; Check for BREAK following 'SWT!'

	jmp	short INT0C_NEXT_IIR ; Process pending interrupts


INT0C_DELTA:
	mov	dx,PORTBASE	; Get port base
	add	dx,@MSR 	; Index Modem Status Register
	in	al,dx		; Get status to reset IER

;;;;;;; jmp	short INT0C_NEXT_IIR ; Join common code


INT0C_THR_EMPTY:
INT0C_NEXT_IIR:
	loop	INT0C_GETIID	; Go around again
INT0C_EXIT:
	mov	al,@EOI 	; Non-specific EOI
	out	@ICR,al 	; Tell the PIC about it

	or	ah,ah		; Are we supposed to call SWATTER?
	REGREST <edi,edx,ecx,ebx,eax> ; Restore

	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler

	lea	esp,[esp+(type INTxx_EFL2)] ; Discard saved flags, preserving ZF
	jnz	near ptr INTxx_SWATTER ; Jump if so

	jmp	INTxx_DONE	; Join common IRETD code
;;;;;;; iretd			; Return to caller


	assume	ds:DGROUP	; Tell the assembler
INT0C_ORIG_POP:
	POPW	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popfd			; Restore

	lea	esp,[esp+4]	; Strip the error code

	pushfd			; Save EFLAGS

	PUSHW	ds		; Save incoming DS

	SETDATA ds		; Get addressability to DGROUP
	assume	ds:DGROUP	; Tell the assembler
INT0C_ORIG:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	OLDINT_MAC C2		; Push old interrupt vactors
;;;;;;; push	OLDINTC2_FVEC.FSEL ; Pass old selector
;;;;;;; push	OLDINTC2_FVEC.FOFF ; Pass old offset

	jmp	near ptr INTxx_ORIG ; Join common code to simulate ring transition

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INTC2 endp			; End LCL_INTC2 procedure
	NPPROC	CHECK_BREAK -- Check BREAK for interrupt conditions
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BREAK received (or error; we can't tell 'em apart).  If conditions are
right, set AH to FF to signal a call to SWATTER.

It would be simple, on one hand, to interrupt the remote system on
BREAK.	Unfortunately, it's not possible to tell BREAK from an error,
such as might occur when a modem answers, or when a system on the other
end of a hardwired connection tries to send at the wrong speed.

On the other hand, we don't want to keep checking the input stream
for a command packet.  We check the last 4 characters received whenever
a BREAK occurs.  If they are 'SWT!' it's a valid interrupt request.

On entry:

AH	 SWATTER flag

On exit:

AH	=	FF    Call SWATTER on exit
AH	=	0     Don't call SWATTER
AL	=	LSR value

|

	REGSAVE <ebx,ecx,edx,esi,LC3_FLAG> ; Save

	and	LC3_FLAG,not @LC3_PORTINIT ; Mask off temporarily

	mov	dx,PORTBASE	; Get port base
	add	dx,@LSR 	; Index Line Status Register
	in	al,dx		; Get status

	test	al,mask $LSR_BREAK ; Was it a break?
	jz	short CB_EXIT	; Jump if not

	SELFBREAK CHECK_BREAK,1000h ; Break if SELFDBG&1000h

;;;;;;; LOGDISP 'CHECK_BREAK'   ; Display to error log

; This code doesn't work; BREAKs and errors look exactly the same, at least
; with some UARTs
;;;;;;; test	al,(mask $LSR_FRAMERR) or (mask $LSR_PERR) or (mask $LSR_OVRERR) ; Was it an error?
;;;;;;; jnz	short CB_EXIT	; Jump if so
;;;;;;;
	or	ah,ah		; Are we already supposed to call SWATTER?
	jnz	short CB_EXIT	; Jump if so

;;;;;;; test	[esp].ELO,@LC3_SLAVE or @LC3_PORTINIT ; Are we the slave or
;;;;;;; 			; was PORTINIT specified?
;;;;;;; jz	short CB_EXIT	; Jump if not
;;;;;;;
; If SS = DGROUP, we're already in SWAT and don't need to do anything
	push	eax		; Save
	mov	ax,ds		; Get current DS (DGROUP)
	mov	dx,ss		; Get stack selector
	cmp	ax,dx		; Did we get here via TSS?
	pop	eax		; Restore
	je	short CB_EXIT	; Jump if not - ignore signal

; Check the LAST 4 characters received - not the 4 at the head of the buffer

	mov	ebx,PRECVBUF	; Get pointer to ring buffer

	REGSAVE <eax>		; Save

	sub	eax,eax 	; Initialize to 0
	mov	ecx,4		; Number of characters to grab
	mov	esi,RECVBUF_HEAD ; Next location to write to
CB_GETNEXT:
	cmp	esi,RECVBUF_TAIL ; Is there anything unread?
	je	short CB_COMPARE ; Jump if not

	lea	esi,[esi+@RECVBUF_LEN-1] ; Back off to last character written
	and	esi,@RECVBUF_LEN-1 ; Wrap it
	mov	al,DGROUP:[ebx+esi].LO ; Get last character
;;;;;;; call	LDISPTXTB	; Dump to error log
	ror	eax,8		; Move into high byte

	loop	CB_GETNEXT	; Do it again

CB_COMPARE:
;;;;;;; LOGDISP '=last 4'       ; Display to error log
	cmp	eax,'SWT!'      ; Does it compare (note that we got the
				; characters in reverse order)?
	REGREST <eax>		; Restore
	jne	short CB_EXIT	; Jump if not

;;;;;;; LOGDISP 'Remote interrupt detected' ; Display to error log

	mov	ah,-1		; Signal call to SWATTER
CB_EXIT:
	REGREST <LC3_FLAG,esi,edx,ecx,ebx> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_BREAK endp		; End CHECK_BREAK procedure
	NPPROC	REMOTE_ACT -- Check for remote debugging action
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for any action required for remote debugging.

This is the central dispatch routine for remote debugging, and should
be called from within GETKEY on the slave machine only when no keystroke
is detected locally.

We check for an incoming packet.  If it's a SENDKEY packet, we ACK it
and return immediately with the keycode in AX and CF=1.

If there's no incoming packet, we compare the current display against
LASTXMSCR.  Any differences are transmitted with SCROUT or CSCREEN, and
LASTXMSCR is updated.

On entry:
nothing

On exit:
CF=1	 Incoming SENDKEY packet detected; AX = keycode.
AX	 Keycode from incoming SENDKEY

CF=0	 No incoming SENDKEY packet
AX	 Unchanged

|

	test	LC3_FLAG,@LC3_EXITSWAT ; Are we trying to escape?
	jz	short @F	; Jump if not

	mov	ax,@KEY_ESC	; Return Esc
	stc			; Indicate we've got a keystroke

	jmp	short RACT_EXIT2 ; Join common exit


@@:
	test	LC3_FLAG,@LC3_SLAVE ; Are we acting as slave?
	jz	short RACT_EXIT2 ; Jump if not (note CF=0)

;;;;;;;  LOGDISP MSG_RACTIN	; 'Entering Remote_act'
	call	F2REMOTE_ACT	; Call code in PGROUP

;;;;;;;  LOGDISP MSG_RACTOUT	; 'Exiting remote_act'

RACT_EXIT2:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REMOTE_ACT endp 		; End REMOTE_ACT procedure
	NPPROC	ALT_VTOGGLE -- Toggle alternate video buffer
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Switch the current and alternate video buffers.

On entry:
DGROUP:EBX ==>	 Copy of LC3_FLAG to change

|

	REGSAVE <eax,ecx,esi,edi,es,gs> ; Save

	btc	DGROUP:[ebx].ELO,$LC3_NOVID ; Set in LC3_FLAG to restore
	jnc	short VTOGGLE_OFF ; Jump if we just turned it off

; Setup GS=AGROUP for CHECK_VMOD

	mov	gs,COMMON.FILE_4GB ; Address AGROUP
	assume	gs:AGROUP	; Tell the assembler

; The screen just got turned back on.  We need to save the user screen
; now so we can restore on exit.

; Restore the old video selector and base
	mov	ax,ACTBASE_FVEC.FSEL ; Get selector for original screen
	mov	VIDBASE_FVEC.FSEL,ax ; Save as video base
	mov	eax,ACTBASE_FVEC.FOFF ; Get offset for alternate screen
	mov	VIDBASE_FVEC.FOFF,eax ; Save as video offset

; Save the screen data values

	and	LC3_FLAG,not @LC3_NOVID ; Enable screen functions

	call	SAVE_SCRDATA	; Save screen data

; Set video mode if not in text mode

	call	CHECK_VMOD	; Check it out

	test	LCL_FLAG,@LCL_SCRN ; Screen restore disabled?
	jnz	short @F	; Yes, so don't save it

	push	PSCRBUF 	; Pass address of screen buffer
	PUSHD	1		; Use actual screen base
	call	SAVE_SCR	; Save all screen text
@@:

; Set new cursor position and type

	push	CURPOSN 	; Get new cursor position
	call	SET_CURPOS	; Set it

	push	CURTYPE 	; Get new cursor type
	call	SET_CURTYP	; Set it

	lgs	esi,ALTBASE_FVEC ; Source to copy from
	assume	gs:nothing	; Tell the assembler

	jmp	short VTOGGLE_COM ; Join common code


VTOGGLE_OFF:
; The screen just got turned off.  We need to restore the user screen now,
; since it won't happen on exit.

; Restore the screen unless asked not to

	test	LCL_FLAG,@LCL_SCRN ; Screen restore disabled?
	jnz	short @F	; Yes, don't restore it

	push	PSCRBUF 	; Pass address of screen buffer
	call	REST_SCR	; Restore all screen text
@@:
	or	DGROUP:[ebx].ELO,@LC3_NOVID ; Leave VIDBASE_FVEC alone

	or	LC3_FLAG,@LC3_NOVID ; Disable video starting now

; Set alternate video selector and base
	mov	ax,ALTBASE_FVEC.FSEL ; Get selector for alternate screen
	mov	VIDBASE_FVEC.FSEL,ax ; Save as video base
	mov	eax,ALTBASE_FVEC.FOFF ; Get offset for alternate screen
	mov	VIDBASE_FVEC.FOFF,eax ; Save as video offset

	lgs	esi,ACTBASE_FVEC ; Source to copy from
	assume	gs:nothing	; Tell the assembler

VTOGGLE_COM:
; Copy screen at GS:ESI to current screen
	les	edi,VIDBASE_FVEC ; Destination
	assume	es:nothing	; Tell the assembler

	mov	ecx,@NROWS*@NCOLS/2 ; Number of dwords to move
S32 rep movs	<es:[edi].EDD,gs:[esi].EDD> ; Copy previous buffer to current

	REGREST <gs,es,edi,esi,ecx,eax> ; Restore
	assume	es:nothing,gs:nothing ; Tell the assembler

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ALT_VTOGGLE endp		; End ALT_VTOGGLE procedure
	NPPROC	SER_INIT -- Initialize serial port
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize serial port for remote debugging if SETCOM specified.

On entry:
COMPORT 	COM port (1-4)
PORTDLATCH	Baud rate / @BAUD_DIVISOR
PORTBASE	I/O port base address
PORTIRQ 	IRQ for port or ff for polled

On exit:
@LC3_SERINT	Set if interrupt-driven I/O requested
MCR_SET 	Respecified (with RTS and DTR preserved)
PORTINT 	Set based on PORTIRQ
MAXPACKET	Set based on transmission rate

|

	call	F2SER_INIT	; Call code in PGROUP

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SER_INIT endp			; End SER_INIT procedure
	NPPROC	CMD_SETCOM -- Set communications parameters
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT!

Set various communications parameters

SETCOM port speed [ {IRQ|*|p} [portbase] ]
SETCOM -
SETCOM RTS{+|-}
SETCOM DTR{+|-}
SETCOM

port is the port index (1-4)
speed is the desired baud rate (1-115200) in decimal
IRQ is the IRQ number in the master PIC for the UART (also set by
default according to port).  Only 3 and 4 are supported.
portbase is the I/O base in hex for the selected UART (if not specified,
it's set based on port)

SETCOM -
turns off trapping of serial port interrupts

SETCOM RTS{+|-}
SETCOM DTR{+|-}
causes RTS (Request To Send) or DTR (Data Terminal Ready) to be pulled
high or dropped.  By default, RTS and DTR are asserted high, since many
serial ports won't work without at least RTS.  Dropping RTS is also the
preferred method for hanging up a modem when +++ isn't activated.  Note
that these settings remain in effect until changed; SETCOM doesn't change
them.

SETCOM
reprograms the UART and IMR registers with the default (last specified)
settings.

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0

!

SETCOM_STR struc
SETCOM_PORT dw	?		; New port (1-4)
SETCOM_BAUD dd	?		; New baud rate (1-115200)
SETCOM_DLATCH dw ?		; New baud rate divisor latch
SETCOM_IRQ db	?,?		; New IRQ level (3, 4 or FF for polled)
SETCOM_PORTBASE dw ?		; New port base
SETCOM_STR ends

	push	ebp		; Save
	sub	esp,size SETCOM_STR ; Allocate space for local data
	mov	ebp,esp 	; Address local data structure

	pushad			; Save

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	or	al,al		; Izit the end of the line?
	jz	near ptr SETCOM_DEFAULT ; Jump if so

	cmp	al,'-'          ; Are we disabling interrupts?
	jne	short @F	; Jump if not

	and	LC3_FLAG,not (@LC3_REM or @LC3_SERINT) ; Ignore all interrupts

	jmp	near ptr SETCOM_EXIT ; Join common exit (note CF=0)


@@:
; Check for RTS or DTR
	mov	ecx,3		; Number of characters to rotate
	mov	eax,DGROUP:[esi].EDD ; Get all four ('-STR', '+RTD', etc.)
@@:
	call	U32_LOWERCASE	; Convert AL to lowercase
	ror	eax,8		; Get next character
	loop	@B		; Go around again

	mov	bx,((not (mask $MCR_RTSHIGH)) shl 8) or (mask $MCR_RTSHIGH) ; BH = AND value, BL = OR
	cmp	eax,'str+'      ; Izit pull RTS high?
	je	short @F	; Jump if so

	sub	bl,bl		; Clear OR value
	cmp	eax,'str-'      ; Izit drop RTS?
	je	short @F	; Jump if so

	mov	bx,((not (mask $MCR_DTRHIGH)) shl 8) or (mask $MCR_DTRHIGH) ; BH = AND value, BL = OR
	cmp	eax,'rtd+'      ; Izit pull DTR high?
	je	short @F	; Jump if so

	cmp	eax,'rtd-'      ; Izit drop DTR?
	jne	short SETCOM_XTOKN ; Jump if not

@@:
	and	MCR_SET,bh	; Mask off target bit
	or	MCR_SET,bl	; Put it back in if '+'

	jmp	near ptr SETCOM_DEFAULT ; Reinitialize the port


SETCOM_XTOKN:
; Get port index (1-4)
	call	PARSE_ATOM	; Parse command line for an atom
	jc	near ptr SETCOM_ERR ; Jump if too large

	cmp	eax,4		; Izit within limits?
	ja	near ptr SETCOM_ERR ; Jump if too large

	mov	[ebp].SETCOM_PORT,ax ; Save new port value

	sub	al,1		; Make it 0 based
	jc	near ptr SETCOM_ERR ; Jump if already 0 (invalid)

; If the port base in the BIOS data area is bogus, that's OK if the user
; specifies a port base...  We'll check for that later, when we're setting
; up the parameters.

	sub	ebx,ebx 	; Clear high word
	mov	bx,seg BIOSDATA ; Get segment of BIOS data area
	shl	ebx,4-0 	; Convert from paras to bytes
	assume	gs:BIOSDATA	; Tell the assembler about it

	mov	dx,RS232_BASE[ebx+eax*2] ; Get port base from BIOS
	assume	gs:AGROUP	; Retract nose

	mov	cl,$COM13	; Assume IRQ4
	shr	al,1		; If COM2/COM4, set CF=1
	sbb	cl,($COM13-$COM24)-1 ; Use IRQ3 for COM2/COM4

	mov	[ebp].SETCOM_PORTBASE,dx ; Set default port base
	mov	[ebp].SETCOM_IRQ,cl ; Set default IRQ level

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

; Get baud rate (1-115200)
	mov	ecx,10		; Use base 10
	call	U32_BASE2BIN	; Convert decimal value to hex
	jc	near ptr SETCOM_ERR ; Jump if too large or conversion error

	mov	ebx,eax 	; Use baud rate as divisor
	mov	eax,@BAUD_DIVISOR ; Get dividend
	cmp	ebx,eax 	; Izit within limits?
	ja	near ptr SETCOM_ERR ; Jump if too large

	or	ebx,ebx 	; Izit non-zero?
	jz	near ptr SETCOM_ERR ; Jump if not

	push	eax		; Save dividend

	cdq			; Clear high 32 bits
	div	ebx		; (E)AX = divisor latch value

	mov	[ebp].SETCOM_DLATCH,ax ; Save divisor latch

	movzx	ebx,ax		; Use divisor latch as divisor

	pop	eax		; Restore dividend

	cdq			; Clear high 32 bits
	div	ebx		; (E)AX = normalized baud rate

	mov	[ebp].SETCOM_BAUD,eax ; Save baud rate for display

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	or	al,al		; Izit the end of the line?
	jz	short SETCOM_SETUP ; Jump if so

; Get IRQ # or p for polled.  If '*' specified, go with the default
	cmp	al,'*'          ; Should we go with the default?
	je	short SETCOM_SKIPIRQ ; Jump if so

	call	U32_LOWERCASE	; Convert AL to lowercase
	cmp	al,'p'          ; Izit polled?
	jne	short @F	; Jump if not

	mov	[ebp].SETCOM_IRQ,0ffh ; No IRQ; use polled operation
SETCOM_SKIPIRQ:
	inc	esi		; Skip '*'

	jmp	short SETCOM_XIRQ ; Jump if so


@@:
	call	PARSE_ATOM	; Parse command line for an atom
	jc	near ptr SETCOM_ERR ; Jump if too large

	cmp	eax,0000FFFFh	; Izit within limits?
	ja	near ptr SETCOM_ERR ; Jump if too large

	cmp	ax,$COM13	; Izit IRQ4?
	je	short @F	; Jump if so

	cmp	ax,$COM24	; Izit IRQ3?
	jne	near ptr SETCOM_ERR ; Jump if not
@@:
	mov	[ebp].SETCOM_IRQ,al ; Save new IRQ level

SETCOM_XIRQ:
	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	or	al,al		; Izit the end of the line?
	jz	short SETCOM_SETUP ; Jump if so

; Get port base
	call	PARSE_ATOM	; Parse command line for an atom
	jc	near ptr SETCOM_ERR ; Jump if too large

	cmp	eax,0000FFFFh	; Izit within limits?
	ja	near ptr SETCOM_ERR ; Jump if too large

	or	ax,ax		; Izit non-zero?
	jz	near ptr SETCOM_ERR ; Jump if not

	mov	[ebp].SETCOM_PORTBASE,ax ; Save new port base value

SETCOM_SETUP:
; Check to ensure we have a valid port base.  If the value in the BIOS data
; area at 40:0 is invalid, the user needs to specify it.
	mov	dx,[ebp].SETCOM_PORTBASE ; Get port base
	or	dx,dx		; Izit valid?
	jz	near ptr SETCOM_PORTERR ; Jump if not

	mov	PORTBASE,dx	; Save for later

	mov	ax,[ebp].SETCOM_PORT ; Get port
	mov	COMPORT,ax	; Save it (for display only)

	mov	eax,[ebp].SETCOM_BAUD ; Get baud rate
	mov	PORTBAUD,eax	; Save (for display only)

	mov	ax,[ebp].SETCOM_DLATCH ; Get divisor latch value for baud rate
	mov	PORTDLATCH,ax	; Save for later

	mov	al,[ebp].SETCOM_IRQ ; Get IRQ level
	mov	PORTIRQ,al	; Save for later

SETCOM_DEFAULT:
	or	LC3_FLAG,@LC3_REM ; Serial port is now open for business

	call	SER_INIT	; Reprogram UART and IMR

	clc			; Indicate success

	jmp	short SETCOM_EXIT ; Join common exit code


SETCOM_PORTERR:
	mov	MSGOFF,offset DGROUP:PORTERR ; "Invalid port base address"

	jmp	short SETCOM_ERR2 ; Join common error code


SETCOM_ERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
SETCOM_ERR2:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Indicate failure
SETCOM_EXIT:
	pushfd			; Save
	or	LCL_FLAG,@LCL_REDI ; Force redisplay
	popfd			; Restore

	popad			; Restore

	lea	esp,[esp + (size SETCOM_STR)] ; Free local data (preserve CF)
	pop	ebp		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_SETCOM endp 		; End CMD_SETCOM procedure
	NPPROC	DISP_COMM -- Display current communications settings
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display current communications settings (port, speed, etc) on last
line of screen.

|

	REGSAVE <eax,esi,edi,SCROFF> ; Save

	mov	SCROFF,24*80*2	; Last line of screen

	mov	eax,' ffO'      ; Assume we're inactive
	test	LC3_FLAG,@LC3_REM ; Is serial port active?
	jz	short @F	; Jump if so

	mov	eax,'  nO'      ; We're active
@@:
	mov	PARM_MSG.EDD,eax ; Blast into beginning of message

	mov	ax,COMPORT	; Get current port
	or	al,'0'          ; Convert nybble to decimal
	mov	PARM_PORT,al	; Save in message

	lea	esi,PARM_MSG	; Display first part of parameters
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI

	mov	eax,PORTBAUD	; Get baud rate
	call	DISPDEC 	; Display in decimal

	lea	esi,PARM_MSG2	; Display second part of parameters
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI

	mov	ax,PORTBASE	; Get port I/O base
	call	DISPHEX2	; Display as hex word

	lea	esi,PARM_MSG3	; Display third part of parameters
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI

	mov	al,PORTIRQ	; Get port IRQ value
	cmp	al,0ffh 	; Izit polled?
	jne	short @F	; Jump if not

	lea	esi,PARM_POLLED ; " (polled)"
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI

	jmp	short DISP_COMM_EXIT0 ; Join common exit


@@:
	call	DISPHEX0	; Display low order nybble of AL
DISP_COMM_EXIT0:
	call	CLEAR_EOL	; Clear to end of line
DISP_COMM_EXIT:
	REGREST <SCROFF,edi,esi,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_COMM endp			; End DISP_COMM procedure
	NPPROC	CMD_CHAT -- Chat with remote SWAT user
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Put up the CHAT message in the middle of the screen.  Display incoming
traffic on the top, echo keys typed on the bottom.  Ctrl-F8 to exit or
Ctrl-F9 to start a remote debugging session.

|

	call	F2CMD_CHAT	; Call code in PGROUP

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_CHAT endp			; End CMD_CHAT procedure
	NPPROC	CMD_REMDBG -- Connect to remote debugging session
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Connect to remote system for debugging.

The complete dialog is outlined in SWAT_REM.INC.

|

	call	F2CMD_REMDBG	; Call code in PGROUP

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_REMDBG endp 		; End CMD_REMDBG procedure
	NPPROC	ADJUST_KBPTR -- Adjust keyboard buffer pointer
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Normalize pointer into keyboard buffer in case it wraps past the
end or back to the beginning.

On entry:
EBX	 Base linear address of BIOS data area
EDX	 Pointer to normalize

On exit:
EDX	 Normalized pointer

|

	assume	gs:BIOSDATA	; Tell the assembler

	cmp	dx,BUFFER_END[ebx] ; Did we wrap?
	jb	short @F	; Jump if not

	mov	dx,BUFFER_START[ebx] ; Start at beginning
@@:
	cmp	dx,BUFFER_START[ebx] ; Did we go below the start?
	jnb	short @F	; Jump if not

	mov	dx,BUFFER_END[ebx] ; Start at end
	sub	dx,2		; Back off to last available location
@@:
	assume	gs:nothing	; Retract nose

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ADJUST_KBPTR endp		; End ADJUST_KBPTR procedure
	NPPROC	CMD_APPKEY -- Edit application keystrokes
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Allow keystrokes to be inserted anywhere within the keyboard buffer.
This is primarily useful for remote debugging.

|

	pushad			; Save

	call	CLS		; Clear screen

	mov	SCROFF,0	; Go to top
	lea	esi,APPKEYMSG	; Display header
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI

	xor	ebx,ebx 	; Zero to use as word
	mov	bx,seg BIOSDATA ; Get BIOSDATA segment
	shl	ebx,4-0 	; Convert from paras to bytes
	assume	gs:BIOSDATA	; Tell the assembler

	movzx	edx,BUFFER_HEAD[ebx] ; Start with next one to be used
CKEY_REDISP:
	movzx	edi,BUFFER_HEAD[ebx] ; Start at top of stack
	sub	esi,esi 	; Initialize column offset
CKEY_REDISP2:
	mov	SCROFF,3*80*2	; Starting display line
	add	SCROFF,esi	; Add column offset
	mov	ecx,20		; Maximum lines to display
CKEY_REDISPLN:
	REGSAVE <esi,SCROFF>	; Save starting address

	lea	esi,CKEYBLANK5	; Assume it's not the current one
	cmp	dx,di		; Izit the highlighted one?
	jne	short @F	; Jump if not

	lea	esi,CKEYCURRENT ; Indicate it's the current one
@@:
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI

	cmp	di,BUFFER_TAIL[ebx] ; Izit empty?
	jne	short CKEY_DISPHEX ; Jump if not

	lea	esi,CKEYEMPTY	; Indicate it's empty
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI

	jmp	short @F	; Join common code


CKEY_DISPHEX:
	mov	ax,gs:[ebx+edi].ELO ; Get keystroke
	call	DISPHEX2	; Display AX in hex
	add	SCROFF,2	; Skip a character and attribute
	call	DISPTXT 	; Dump character in AL
@@:
	lea	esi,CKEYTEXT	; Trailing text for key
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI

	REGREST <SCROFF,esi>	; Restore
	add	SCROFF,80*2	; Advance to next line

	cmp	di,BUFFER_TAIL[ebx] ; Are we at the end already?
	je	short CKEY_CLEAREND ; Jump if so

	add	edi,2		; Skip to next
	cmp	di,BUFFER_END[ebx] ; Did we wrap?
	jb	short @F	; Jump if not

	movzx	edi,BUFFER_START[ebx] ; Wrap to beginning
@@:
;;;;;;; loop	CKEY_REDISPLN	; Display next line
	dec	ecx		; One fewer line
	jnz	CKEY_REDISPLN	; Jump if more to display

	add	esi,20*2	; Skip to next column
	cmp	esi,80*2	; Have we reached the end?
	jnb	short CKEY_GETKEY ; Jump if so

	jmp	CKEY_REDISP2	; Display next column


CKEY_CLEAREND:
; We may have deleted a key, so clear the last position.
	loop	@F		; Jump if not at the end

	add	esi,20*2	; Skip to next column
	cmp	esi,80*2	; Have we reached the end?
	jnb	short CKEY_GETKEY ; Jump if so

	mov	SCROFF,3*80*2	; Starting display line
	add	SCROFF,esi	; Add column offset
@@:
	lea	esi,CKEYCLEAR	; Clear this position
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI
CKEY_GETKEY:
	call	GETKEY		; Get a local keystroke in AX
	cmp	ax,@KEY_ESC	; Izit ESC?
	jne	short @F	; Jump if not

	call	GETKEY		; Get a local keystroke in AX

	jmp	short CKEY_PUTKEY ; Dump it in buffer


@@:
	cmp	ax,@KEY_ALT_ESC ; Izit time to bail out?
	je	near ptr CKEY_EXIT ; Jump if so

	cmp	ax,@KEY_DN	; Izit down arrow?
	je	short CKEY_DOWN ; Jump if so

	cmp	ax,@KEY_XDN	; Izit other down arrow?
	je	short CKEY_DOWN ; Jump if so

	cmp	ax,@KEY_UP	; Izit up arrow?
	je	short CKEY_UP	; Jump if so

	cmp	ax,@KEY_XUP	; Izit other up arrow?
	je	short CKEY_UP	; Jump if so

	cmp	ax,@KEY_INS	; Izit Ins?
	je	short CKEY_INS	; Jump if so

	cmp	ax,@KEY_XINS	; Izit other Ins?
	je	short CKEY_INS	; Jump if so

	cmp	ax,@KEY_DEL	; Izit Del?
	je	short CKEY_DEL	; Jump if so

	cmp	ax,@KEY_XDEL	; Izit other Del?
	je	short CKEY_DEL	; Jump if so
CKEY_PUTKEY:
	mov	edi,edx 	; Address current keystroke
	mov	gs:[ebx+edi].ELO,ax ; Put in buffer

	cmp	dx,BUFFER_TAIL[ebx] ; Did we just dump to an empty spot?
	jne	short CKEY_DOWN ; Jump if not

; Note that although the buffer (by default) contains 16 words, the maximum
; capacity is 15 words (keystrokes) because the test for an empty buffer is
; HEAD == TAIL.  We therefore need to ensure we don't fill up that last space,
; although it's quite all right to dump AX there as long as we don't update
; the tail pointer.
	add	edx,2		; Skip to next
	call	ADJUST_KBPTR	; Normalize EDX within ring buffer

	cmp	dx,BUFFER_HEAD[ebx] ; Is the buffer already full?
	je	short CKEY_GETKEY ; Jump if so

	mov	BUFFER_TAIL[ebx],dx ; Bump tail pointer

	jmp	near ptr CKEY_REDISP ; Redisplay


CKEY_DOWN:
	cmp	dx,BUFFER_TAIL[ebx] ; Are we already at the end?
	je	near ptr CKEY_GETKEY ;	Jump if so

	add	edx,2		; Skip to next
	call	ADJUST_KBPTR	; Normalize EDX within ring buffer

	jmp	near ptr CKEY_REDISP ; Redisplay


CKEY_UP:
	cmp	dx,BUFFER_HEAD[ebx] ; Are we already at the beginning?
	je	near ptr CKEY_GETKEY ; Jump if so

	sub	edx,2		; Back off to previous
	call	ADJUST_KBPTR	; Normalize EDX within ring buffer

	jmp	near ptr CKEY_REDISP ; Redisplay


CKEY_INS:
; Not yet implemented
	jmp	near ptr CKEY_REDISP ; Redisplay


CKEY_DEL:
; Delete keystroke at current position from buffer.
; If this is the last keystroke, we need only update the tail pointer.
; Otherwise, we need to move the rest of the (linear) buffer down.

	mov	ecx,edx 	; Save current position
CKEY_DELNEXT:
	cmp	dx,BUFFER_TAIL[ebx] ; Is this the last one?
	jne	short CKEY_DELXLAST ; Jump if not

	cmp	ecx,edx 	; Should we update current position?
	pushfd			; Save results of test

	sub	edx,2		; Back off to previous tail position
	call	ADJUST_KBPTR	; Normalize EDX within ring buffer

	mov	BUFFER_TAIL[ebx],dx ; Save new tail pointer

	popfd			; ZF=1 if we should ignore ECX
	jz	short @F	; Jump if position is OK

	mov	edx,ecx 	; Restore old position
@@:
	jmp	near ptr CKEY_REDISP ; Redisplay


CKEY_DELXLAST:
; Copy next one down.
	mov	edi,edx 	; Save destination (current position)
	add	edx,2		; Skip to new position
	call	ADJUST_KBPTR	; Normalize EDX within ring buffer

	mov	esi,edx 	; Copy new position
	mov	ax,gs:[ebx+esi].ELO ; Get key to move down
	mov	gs:[ebx+edi].ELO,ax ; Save in its new position

	jmp	short CKEY_DELNEXT ; Go around again


CKEY_EXIT:
	or	LCL_FLAG,@LCL_REDI ; Force redisplay (note CF=0)

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_APPKEY endp 		; End CMD_APPKEY procedure
	NPPROC	CALC_LOGLINE -- Calculate Number of Error Log Lines
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate the number of lines in error log

Display the error log

LOGBASE is the offset within DGROUP of the start of the
error log circular buffer.

LOGHEAD is the start of the buffer to be displayed, and LOGOFF
is the end.  LOGHEAD == LOGOFF indicates the end.

LOGLEN is the buffer length in bytes, and is used to wrap.

On exit:

EAX	=	# lines in error log

|

	REGSAVE <ebx,edx>	; Save registers

	mov	eax,LOGOFF	; Get end of buffer
	sub	eax,LOGHEAD	; Less start ...
	jnc	short @F	; Jump if within range

	add	eax,LOGLEN	; Plus length of buffer to normalize
@@:
	mov	ebx,@ERRLOG_ROWLEN ; Record length for error log
	xor	edx,edx 	; Zero to use as qword
	div	ebx		; Divide to get # lines

	REGREST <edx,ebx>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_LOGLINE endp		; End CALC_LOGLINE procedure
	NPPROC	DISP_ERRLOG -- Display error log screen
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display the error log

LOGBASE is the offset within DGROUP of the start of the
error log circular buffer.
LOGHEAD is the start of the buffer to be displayed, and LOGOFF
is the end.  LOGHEAD == LOGOFF indicates the end.

LOGLEN is the buffer length in bytes, and is used to wrap.
ERRLOG_CLINE is the starting line (origin:0) to display in the buffer.
If ERRLOG_CLINE is outside the practical range of buffer display,
it will be truncated to the last line - 1.

All lines are padded to @ERRLOG_ROWLEN characters to simplify display.

|

	pushad			; Save all EGP registers

	mov	bl,TTLATTR	; Get title attribute
	xchg	bl,DEFATTR	; Swap with default attribute

	mov	SCROFF,0	; Start at top of screen

	lea	esi,ERRLOG_TTL	; Prepare to display header
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI
	mov	eax,LOGLEN	; Get length of error log in bytes
	call	DISPDEC 	; Display in decimal
	call	CLEAR_EOL	; Clear to the end-of-the-line
	xchg	bl,DEFATTR	; Restore default attribute

	call	CLEAR_EOP	; Clear the rest of the page
	mov	SCROFF,@NCOLS*2 ; Skip to beginning of second row

	mov	eax,@ERRLOG_ROWLEN ; Record length for error log
	mov	ebx,ERRLOG_CLINE ; Starting line to display
	mul	ebx		; EAX = starting offset from LOGHEAD
	add	eax,LOGHEAD	; Get starting offset from LOGBASE
	cmp	eax,LOGLEN	; Did we wrap?
	jb	short @F	; Jump if not

	sub	eax,LOGLEN	; Wrap within circular buffer
	mov	ebx,LOGOFF	; Get end value
	cmp	ebx,LOGHEAD	; Izit wrapped?
	jnb	short @F	; No, so we don't need to normalize it

	cmp	eax,ebx 	; Compare normalized values
	jb	short @F	; Jump if in range

	mov	eax,ebx 	; Copy LOGOFF
	add	eax,LOGLEN	; Normalize it

	jmp	short DISPLOG_BADCLINE ; Calculate new ERRLOG_CLINE value


@@:
	mov	esi,eax 	; Starting offset from LOGBASE
	mov	eax,LOGOFF	; Get offset of end from LOGBASE
	mov	ebx,esi 	; Get pointer we're comparing

	cmp	eax,LOGHEAD	; Is the buffer empty?
	je	near ptr DISPLOG_END ; Jump if so

	jnb	short @F	; Jump if no wrapping

	add	eax,LOGLEN	; Normalize for comparison

	cmp	ebx,LOGHEAD	; Izit in range?
	jnb	short @F	; Jump if so

	add	ebx,LOGLEN	; Normalize for comparison
@@:
; Check for EBX >= LOGHEAD and EBX < EAX
	cmp	ebx,LOGHEAD	; Are we out of range (negative)?
	jb	short DISPLOG_BADCLINE ; Jump if so

	cmp	ebx,eax 	; Are we at or past the end?
	jb	short DISPLOG_NOTLAST ; Jump if not

DISPLOG_BADCLINE:
; Calculate new ERRLOG_CLINE by subtracting LOGHEAD from normalized LOGOFF
; EAX = normalized LOGOFF (guaranteed EAX > LOGHEAD)
	sub	eax,LOGHEAD	; Get bytes from start of buffer
	cdq			; Zero high dword of dividend
	mov	ebx,@ERRLOG_ROWLEN ; Record length
	sub	eax,ebx 	; Back off to line before end
	div	ebx		; EAX = new ERRLOG_CLINE value
	mov	ERRLOG_CLINE,eax ; Save

	mov	esi,LOGOFF	; Get first line after end
	sub	esi,ebx 	; Back off to start of last line
	jnc	short DISPLOG_NOTLAST ; Jump if we didn't wrap

	add	esi,LOGLEN	; Wrap back to end
DISPLOG_NOTLAST:
	mov	ebx,LOGBASE	; Get base of error log in DGROUP
	sub	dx,dx		; Initialize line start flag and column counter
	sub	di,di		; Initialize current line counter
DISPLOG_NEXT:
	cmp	di,@NROWS-2	; Have we reached the end yet?
	jae	near ptr DISPLOG_EXIT ; Jump if so

	cmp	esi,LOGOFF	; Are we at the end?
	jz	near ptr DISPLOG_END ; Jump if so

	mov	al,DGROUP:[ebx+esi].LO ; Get a byte
	inc	esi		; Skip to next
	cmp	esi,LOGLEN	; Did we wrap?
	jb	short @F	; Jump if not

	sub	esi,esi 	; Start at the beginning
@@:
	cmp	al,CR		; Izit CR?
	je	short DISPLOG_NEWLN1 ; Jump if so

	cmp	al,LF		; Izit LF?
	je	short DISPLOG_NEWLN ; Jump if so

	cmp	al,TAB		; Izit TAB?
	je	short DISPLOG_TAB ; Jump if so

	cmp	al,' '          ; Izit printable?
	jnb	short DISPLOG_CHAR ; Jump if so

	mov	cl,REGATTR	; Get register changed attribute
	xchg	cl,DEFATTR	; Swap with default attribute
	call	DISPHEX1	; Display byte in hex
	xchg	cl,DEFATTR	; Restore default attribute
	inc	dl		; Add an extra column

	jmp	short DISPLOG_BUMPCOL ; Join common code to increment column


DISPLOG_TAB:
	test	dl,111b 	; Izit a multiple of eight?
	jz	short DISPLOG_BUMPCOL ; Jump if so

	movzx	ecx,dl		; Copy col count
	and	ecx,111b	; Modulo 8
	sub	ecx,8		; Subtract from 8
	neg	ecx		; ...
	dec	ecx		; Less one for fall through
	mov	al,' '          ; Display a blank
	jecxz	DISPLOG_CHAR	; Jump if only one
@@:
	call	DISPTXT 	; Display character in AL
	inc	dl		; Increment display column

	loop	@B		; Jump if more to display
DISPLOG_CHAR:
	call	DISPTXT 	; Display character in AL
DISPLOG_BUMPCOL:
	sub	dh,dh		; Clear start of line flag
; Check for wrap
	inc	dl		; Increment display column
	cmp	dl,@NCOLS	; Have we reached EOL?
	jb	short DISPLOG_NEXT ; Jump if not

	ja	short @F	; Jump if past EOL

; If the next character will produce a newline, skip it
	inc	dh		; Set flag to skip next newline

	jmp	short DISPLOG_NEWLN1 ; Join common code for new line


@@:
	sub	dl,@NCOLS	; Wrap column counter

	jmp	short DISPLOG_NEWLN2 ; Join common code for new line


DISPLOG_NEWLN:
	or	dh,dh		; Should we skip this one?
	jnz	near ptr DISPLOG_NEXT ; Jump if so

	call	NEXTLINE	; Move down a line
	sub	dh,dh		; Clear start of line flag
DISPLOG_NEWLN1:
	sub	dl,dl		; Initialize line column counter
DISPLOG_NEWLN2:
	inc	di		; Bump line counter

	jmp	DISPLOG_NEXT	; Get next character


DISPLOG_END:
	lea	esi,ERRLOG_END	; End of the line
	mov	cl,TTLATTR	; Get title attribute
	xchg	cl,DEFATTR	; Set default attribute
	call	DISPASCIIZ	; Display ASCIIZ string at DS:ESI
	xchg	cl,DEFATTR	; Restore default attribute
DISPLOG_EXIT:
	call	CLEAR_EOP	; Clear to the end-of-the-page

	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_ERRLOG endp		; End DISP_ERRLOG procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_REM module
