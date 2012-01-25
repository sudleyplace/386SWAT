;' $Header:   P:/PVCS/386SWAT/SWAT_REM.INV   1.2   20 Sep 1994 16:49:48   BOB  $
;
; (C) Copyright 1992-4 Qualitas, Inc.	  All rights reserved.
;
; SWAT_REM.INC
;
; Equates and structures for remote debugging control packets
;

COMMENT|

Here's how the remote debugging session typically works:
1. User on machine #1 uses SETCOM to set up parameters.
2. User on machine #2  "
3. User on machine #2 uses Ctrl-F8 to get into CHAT screen, and sets
up modem to auto-answer (ATZ<CR> ATE1Q0<CR> ATS0=1<CR>)
4. User on machine #1 gets into CHAT screen, and uses modem to dial
machine #2 (ATZ<CR> ATE1Q0<CR> ATDT number<CR>)
5. Machines are connected.  Both users exit CHAT (Ctrl-F8) and start
remote session via Ctrl-F9.
6. Each machine sends an ENQ packet to the other, and waits to get
a VERSION.  Each remote session screen waits for user to press 'M' to
become master.
7. User on machine #1 presses 'M' to become master.
8. Machine #1 sends MASTER packet to machine #2 and waits for response.
9. Machine #2 responds to MASTER packet by sending SLAVE packet, and
waits for ACK in response.
10. Machine #1 responds to SLAVE packet by sending ACK.
11. Machine #2 begins sending screen in blocks (registers, segregs,
settings and flags, and instructions.  For each block:
12. Machine #2 sends a GOTO for the start of the block and waits
for ACK or SENDKEY.  If SENDKEY, go to step 15.
13. Machine #2 sends a SCRDATA for the entire block and waits for
ACK or SENDKEY.  The screen comparison buffer is updated.  If packet
received is SENDKEY, go to step 15.
14. If not the last block (instructions) go to step 12.
15. Machine #2 processes (or waits for) keystroke.  Keystrokes may
be entered locally as well.
16. For any keystroke entered on machine #1, send a SENDKEY packet
to machine #2.	Note that this may be done before a screen of data
has been transmitted completely.  SENDKEY is not processed by the
slave while sending a packet, but a screen is usually sent in multiple
packets.
17. For any keystroke entered or received on machine #2, process it
normally.  If any changes are made to the screen (including command
line editing) the entire screen is compared against the screen
comparison buffer.  For any changes, GOTO/SCRDATA is used to update
the master screen, and the screen comparison buffer is updated.
If multiple keystrokes are received, they are processed at a higher
priority than updating the master screen.  This allows fairly rapid
operation.  To summarize the priorities of the slave:
Highest: get and process local keystrokes
Middle: receive keystrokes from master and process them
Lowest: compare current screen against last and send changed portions
18. Either user hits Ctrl-F9 to end the session.  This causes an
ENDSES packet to be sent, with ACK expected in return.	The user
on the master machine may use Ctrl-F9 S to temporarily suspend the
remote session.  A second Ctrl-F9 resumes.

|

RCMD_STR struc

RCMD_SIG db	'SWT'           ; Signature
RCMD_TYP db	?		; Command type
RCMD_CSUM dw	0		; Checksum of everything except itself
RCMD_DLEN dd	0		; Number of data bytes to follow

RCMD_STR ends

; RCMD_TYP values
@RCMD_ENQ equ	 1		; Are you there?
@RCMD_ACK equ	 2		; Yes/command completed/OK
@RCMD_NAK equ	 3		; No/command failed/invalid command packet
@RCMD_MASTER equ 4		; I want to be the master
@RCMD_SLAVE equ  5		; I'll be the slave
@RCMD_ENDSES equ 6		; End session
@RCMD_SENDKEY equ 7		; Send keycode to slave
@RCMD_GOTO equ	 8		; Set cursor position and type
@RCMD_SCROUT equ 9		; Send data (chars/attribs) to screen
@RCMD_ENDSESGO equ 10		; End session and resume (Esc)
@RCMD_REF equ	 11		; Redisplay entire screen
@RCMD_ENDRESGO equ 12		; End session, reset, and resume (Esc)
@RCMD_REBOOT equ 13		; Reboot slave
@RCMD_CSCREEN equ 14		; Send screen with packbytes encoding
@RCMD_VERSION equ 15		; Send remote interface version
@RCMD_VTOGGLE equ 16		; Toggle slave display on/off
@RCMD_BUSYSTAT equ 17		; Can you open files?
@RCMD_AMBUSY equ 18		; Unable to open files
@RCMD_FSEND equ  19		; Prepare to send file ...
@RCMD_FRECV equ  20		; Prepare to receive file ...
@RCMD_FPACKET equ 21		; File transfer packet
@RCMD_FACK equ	 22		; Acknowledge file packet (by number)
@RCMD_FNAK equ	 23		; Error on file packet
@RCMD_FEND equ	 24		; End of file
@RCMD_FCAN equ	 25		; Cancel file transfer

@RCMD_TYPMAX equ @RCMD_FCAN	; Highest command supported

; Data structure extensions
; @RCMD_ENQ - no data, VERSION expected
; @RCMD_ACK - no data
; @RCMD_NAK - no data (bad packet received - resend)
; @RCMD_MASTER - no data, SLAVE expected
; @RCMD_SLAVE - no data, ACK expected
; @RCMD_ENDSES - no data, ACK expected

; @RCMD_SENDKEY - ACK expected.  Master --> slave only.
RCMD_SKSTR struc
	 db	 (type RCMD_STR) dup (?)

RCMD_KEYCODE dw  ?		; Keyboard scan code a la GETKEY/Int 16h

RCMD_SKSTR ends

; @RCMD_GOTO - ACK or SENDKEY expected.  Slave --> master only.
RCMD_GSTR struc
	 db	 (type RCMD_STR) dup (?)

RCMD_NEWCPOS dw  ?		; New cursor position
RCMD_NEWCTYP dw  ?		; New cursor type

RCMD_GSTR ends

; @RCMD_SCROUT - ACK or SENDKEY expected.  If SENDKEY received, process
; it immediately.  Slave --> master only.
RCMD_SCRSTR struc
	 db	 (type RCMD_STR) dup (?)

RCMD_SCROFF dd	 ?		; SCROFF value for data
RCMD_SCRDATA dw  (@SCRSIZE/2) dup (?) ; Char/attribute pairs for screen

RCMD_SCRSTR ends

; @RCMD_ENDSESGO - no data, ACK expected.
; Master --> slave only.

; @RCMD_REF - no data, ACK expected.  Master --> slave only.

; @RCMD_ENDRESGO - no data, ACK expected.
; Master --> slave only.

; @RCMD_REBOOT - no data, no response expected.
; Master --> slave only.

; @RCMD_CSCREEN - Same as RCMD_SCROUT, but actual data is encoded using
; packbytes scheme.  To facilitate encoding of byte runs, display data
; is split into 2 planes.  First the actual display bytes are processed,
; then the attribute bytes.  Decoding rules are simple (nextchar() returns
; the next byte available from the screen plane being processed):
;
; character = nextchar()
; IF character == A5
;   IF nextchar() == A5
;	DISPLAY A5
;   ELSE
;	repeatcount = nextchar() + 1
;	character = nextchar()
;	DISPLAY character FOR repeatcount REPETITIONS
;   ENDIF
; ELSE
;   DISPLAY character
; ENDIF
;
; Encoding rules (nextdchar() returns next character from current plane):
; character = nextdchar()
; reps = ADDITIONAL OCCURRENCES OF (character)
; IF reps > (character == A5 ? 1 : 3)
;   IF reps == A5
;	SEND A5 + A5
;	DECREMENT reps
;   ENDIF
;   SEND A5
;   SEND reps
;   SEND character
;   SKIP reps BYTES FROM INPUT STREAM
; ELSE
;   IF character == A5
;	SEND A5
;   ENDIF
;   SEND character
; ENDIF
;
; @RCMD_CSCREEN - ACK or SENDKEY expected.  If SENDKEY received, process
; it immediately.  Slave --> master only.
RCMD_CSCREEN struc
	 db	 (type RCMD_STR) dup (?)

RCMD_CSCROFF dd  ?		; SCROFF value for data
RCMD_CSDLEN dd	 ?		; Number of data bytes (preceding attributes)
RCMD_CSDATA db	(@SCRSIZE) dup (?) ; CSDLEN compressed bytes of character
				; plane data followed by attribute plane data

RCMD_CSCREEN ends

@THIS_RVER equ	0010h		; Current version of remote interface

; @RCMD_VERSION - ACK expected.  Sent in response to ENQ.
RCMD_VERSTR struc
	 db	 (type RCMD_STR) dup (?)

RCMD_VERSION dw  ?		; Remote interface version in BCD

RCMD_VERSTR ends

; @RCMD_VTOGGLE - no data, ACK expected

; @RCMD_BUSYSTAT - FACK with a packet # of -1 or AMBUSY expected.  No data.
; @RCMD_AMBUSY - Sent in response to BUSYSTAT.	No data.

; @RCMD_FSEND - Master->slave only.  Prepare to send file.
; @RCMD_FRECV - Master->slave only.  Prepare to receive file.
RCMD_FXFERSTR struc
	 db	 (type RCMD_STR) dup (?)

RCMD_FXFERNAM db 128 dup (?)	; Filename (including trailing NULs)

RCMD_FXFERSTR ends

; @RCMD_FPACKET - Actual file data.
RCMD_FPACKSTR struc
	 db	 (type RCMD_STR) dup (?)

RCMD_FPACKNUM dw ?		; Packet # (0-FFFE) or FFFF for general ACK
RCMD_FPACKDAT db (@SCRSIZE) dup (?) ; Actual data

RCMD_FPACKSTR ends

; @RCMD_FACK - Acknowledge receipt of packet #, or FFFF for general ACK.
; @RCMD_FNAK - Error in packet #; resend.  FFFF for general NAK.
RCMD_FACKSTR struc
	 db	 (type RCMD_STR) dup (?)

RCMD_FACKNUM dw ?		; Packet # (0-FFFE) or FFFF for general use.

RCMD_FACKSTR ends

; @RCMD_FEND - End of file transmission.  FACK(-1) expected.  No data.
; @RCMD_FCAN - Cancel file transmission immediately.  No response expected.

@RCMD_MAXDATA equ (type RCMD_CSCREEN - type RCMD_STR) ; Maximum data bytes

@RESEND_MAX equ 6		; Maximum attempts when sending file data
@RECVERR_MAX equ 10		; Maximum timeouts when receiving file data

@RECVBUF_LEN equ 1 shl 14	; Length of ring buffer (2^14=16K)

if ((type RCMD_CSCREEN)*2) GE (@RECVBUF_LEN)
.err @RECVBUF_LEN needs to be at least twice as big as max packet
endif				; @RECVBUF_LEN not big enough

