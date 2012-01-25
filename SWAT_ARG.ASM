;' $Header:   P:/PVCS/386SWAT/SWAT_ARG.ASV   1.35   10 Aug 1998 11:00:50   BOB  $
	 title	 SWAT_ARG -- 386SWAT Argument Processing Routines
	 page	 58,122
	 name	 SWAT_ARG

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include 386.INC
	 include PTR.INC
	 include INTVEC.INC

	 include SWAT_SEG.INC
.list

LINARG_MAC macro TXT,ACT
	 local	 LCL_TXT,LCL_LEN

NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:NGROUP

LCL_TXT  db	 TXT
LCL_LEN  equ	 $-LCL_TXT

NDATA	 ends			; End NDATA segment


ASEGLEN  segment use16 word public 'ndata' ; Start ASEGLEN segment
	 assume  ds:NGROUP

	 dw	 LCL_LEN

ASEGLEN  ends			; End ASEGLEN segment


ASEGTAB  segment use16 word public 'ndata' ; Start ASEGTAB segment
	 assume  ds:NGROUP

	 dw	 NGROUP:LCL_TXT

ASEGTAB  ends			; End ASEGTAB segment


ASEGACT  segment use16 word public 'ndata' ; Start ASEGACT segment
	 assume  ds:NGROUP

	 dw	 NGROUP:ACT

ASEGACT  ends			; End ASEGACT segment


NCODE	 segment use16 para public 'ncode' ; Start NCODE segment
	 assume  cs:NGROUP

	 extrn	 ACT:near

NCODE	 ends			; End NCODE segment

	 endm			; LINARG_MAC


DATA16	 segment use32 dword public 'data' ; Start DATA16 segment
	 assume  ds:DGROUP

	extrn	LC3_FLAG:dword
	include SWAT_LC3.INC

DATA16	 ends			; End DATA16 segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:NGROUP

	public	@SWAT_ARG_NDATA
@SWAT_ARG_NDATA label byte	; Mark module start in .MAP file

	 extrn	 ARGPTR:dword
	 extrn	 PROF_CNT:word
	 extrn	 PROF_SEG:word
	 extrn	 SHF_FLAG:byte

	 public  OLDINT24_VEC
OLDINT24_VEC dd  ?		; Save area for old INT 24h handler

	 public  LASTKEY
LASTKEY  dw	 ?		; Offset of last keyword

	 public  MSG_SEP,MSG_UNK,MSG_UNKLST,MSG_UNKPRO,MSG_EOLERR,MSG_OVF
MSG_SEP  db	 BEL,'様> Missing separator.',CR,LF,EOS
MSG_UNK  db	 BEL,'様> Unknown keyword:  ',EOS
MSG_UNKLST db	 BEL,'様> Unknown list elment:  ',EOS
MSG_UNKPRO db	 BEL,'様> Unknown keyword in profile:  ',EOS
MSG_EOLERR db	 BEL,'様> Invalid line ending in profile.',CR,LF,EOS
MSG_OVF  db	 BEL,'様> Value too large:  ',EOS

	 public  MSG_SCONF
MSG_SCONF db	 BEL,'様> PORTINIT specified without SETCOM.',CR,LF,EOS

	 public  MSG_PROC,MSG_CRLF
MSG_PROC db	 '....Processing keyword:  ',EOS
MSG_CRLF db	 CR,LF,EOS

NDATA	 ends			; End NDATA segment


ASEGTAB  segment use16 word public 'ndata' ; Start ASEGTAB segment
	 assume  ds:NGROUP

	public	@SWAT_ARG_ASEGTAB
@SWAT_ARG_ASEGTAB label byte	; Mark module start in .MAP file

	 public  LINARG_TAB
LINARG_TAB label word

ASEGTAB  ends			; End ASEGTAB segment


ASEGLEN  segment use16 word public 'ndata' ; Start ASEGLEN segment
	 assume  ds:NGROUP

	public	@SWAT_ARG_ASEGLEN
@SWAT_ARG_ASEGLEN label byte	; Mark module start in .MAP file

	 public  LINARG_LEN
LINARG_LEN label word

ASEGLEN  ends			; End ASEGLEN segment


ASEGACT  segment use16 word public 'ndata' ; Start ASEGACT segment
	 assume  ds:NGROUP

	public	@SWAT_ARG_ASEGACT
@SWAT_ARG_ASEGACT label byte	; Mark module start in .MAP file

	 public  LINARG_ACT
LINARG_ACT label word

ASEGACT  ends			; End ASEGACT segment


; All keywords in this table *MUST* be in uppercase

	 LINARG_MAC 'ADDRHBITS',        FCN_ADDRHBITS
	 LINARG_MAC 'ALTSCR',           FCN_ALTSCR
	 LINARG_MAC '/A',               FCN_ALTSCR
	 LINARG_MAC 'BUCKETS',          FCN_BUCKETS
	 LINARG_MAC 'CMDHIST',          FCN_CMDHIST
	 LINARG_MAC 'COLDBOOT',         FCN_COLDBOOT
	 LINARG_MAC 'DVGA',             FCN_DVGA
	 LINARG_MAC 'GPSKIP',           FCN_GPSKIP
	 LINARG_MAC 'INTRUDE',          FCN_INTRUDE
	 LINARG_MAC 'KEYB',             FCN_KEYB
	 LINARG_MAC 'LCD',              FCN_LCD
	 LINARG_MAC 'LOADHI',           FCN_LOADHIGH
	 LINARG_MAC 'LOADHIGH',         FCN_LOADHIGH
	 LINARG_MAC 'LOADLO',           FCN_LOADLOW
	 LINARG_MAC 'LOADLOW',          FCN_LOADLOW
	 LINARG_MAC 'LOADSYM',          FCN_LOADSYM
	 LINARG_MAC 'LOGSIZE',          FCN_LOGSIZE
	 LINARG_MAC 'MONO',             FCN_MONO
	 LINARG_MAC 'NOGD',             FCN_NOGD
	 LINARG_MAC 'NORMLIDT',         FCN_NORMLIDT
	 LINARG_MAC 'NOSWAP',           FCN_NOSWAP
	 LINARG_MAC 'NOWINK',           FCN_NOWINK
	 LINARG_MAC 'PASSTHROUGH',      FCN_PASSTHROUGH
	 LINARG_MAC 'PATH',             FCN_PATH
	 LINARG_MAC 'PORTINIT',         FCN_PORTINIT
	 LINARG_MAC 'PRO',              FCN_PRO
	 LINARG_MAC 'PROF',             FCN_PRO
	 LINARG_MAC 'PROXSRCH',         FCN_PROXSRCH
	 LINARG_MAC 'PS4',              FCN_PS4
	 LINARG_MAC 'RMLIDT',           FCN_RMLIDT
	 LINARG_MAC 'SAVESCREEN',       FCN_SAVESCREEN
	 LINARG_MAC 'SETCOM',           FCN_SETCOM
	 LINARG_MAC 'SYMFILTER',        FCN_SYMFILTER
	 LINARG_MAC 'SYMLOAD',          FCN_LOADSYM
	 LINARG_MAC 'SYMSIZE',          FCN_SYMSIZE
	 LINARG_MAC 'TRAPBOUND',        FCN_TRAPBOUND
	 LINARG_MAC 'TRAPDEBUG',        FCN_TRAPDEBUG
	 LINARG_MAC 'TRAPDIV',          FCN_TRAPDIV
	 LINARG_MAC 'TRAPGENP',         FCN_TRAPGENP
	 LINARG_MAC 'TRAPINV',          FCN_TRAPINV
	 LINARG_MAC 'TRAPNMI',          FCN_TRAPNMI
	 LINARG_MAC 'TRAPPAGE',         FCN_TRAPPAGE
	 LINARG_MAC 'TRAPSEGNP',        FCN_TRAPSEGNP
	 LINARG_MAC 'TRAPSKIP',         FCN_TRAPSKIP
	 LINARG_MAC 'TRAPSTACK',        FCN_TRAPSTACK
	 LINARG_MAC 'TRAPSTEP',         FCN_TRAPSTEP
	 LINARG_MAC 'TRAPTSS',          FCN_TRAPTSS
	 LINARG_MAC 'VCPISWAT',         FCN_VCPISWAT
	 LINARG_MAC 'VIDEO',            FCN_VIDEO
	 LINARG_MAC 'VMSCOUNT',         FCN_VMSCOUNT
	 LINARG_MAC 'VMSINT',           FCN_VMSINT
	 LINARG_MAC 'WATCHDOG',         FCN_WATCHDOG
	 LINARG_MAC 'WKDLS',            FCN_WKDLS

	 LINARG_MAC 'DEBUG=CAPS',       FCN_DBGCAPS
	 LINARG_MAC 'DEBUG=IBV',        FCN_DBGIBV
	 LINARG_MAC 'DEBUG=INT',        FCN_DBGINT
	 LINARG_MAC 'DEBUG=PMI',        FCN_DBGPMI
	 LINARG_MAC 'DEBUG=TRIP',       FCN_DBGTRIP
	 LINARG_MAC 'DEBUG=VMI',        FCN_DBGVMI


ASEGTAB  segment use16 word public 'ndata' ; Start ASEGTAB segment
	 assume  ds:NGROUP

	 public  NLINARGS
NLINARGS equ	 ($-LINARG_TAB)/(type LINARG_TAB) ; Its length

ASEGTAB  ends			; End ASEGTAB segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 extrn	 INIT_MBOOT:far
	 extrn	 CHECK_MBOOT:far

XCODE	 ends			; End XCODE segment


NCODE	 segment use16 para public 'ncode' ; Start NCODE segment
	 assume  cs:NGROUP

	public	@SWAT_ARG_NCODE
@SWAT_ARG_NCODE:		; Mark module start in .MAP file

	 extrn	 SETUP_VID:near

	 NPPROC  DISP_KEY -- Display The Current Keyword
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the current keyword

On entry:

BX	 =	 index into LINARG_xxx tables

|

	 cmp	 SHF_FLAG,1	; Izit enabled?
	 jne	 short DISP_KEY_EXIT ; Jump if not

	 REGSAVE <ax,bx,cx,dx,ds> ; Save for a moment

	 mov	 ax,es		; Get segment of NGROUP
	 mov	 ds,ax		; Address it
	 assume  ds:NGROUP	; Tell the assembler about it

	 DOSCALL @STROUT,MSG_PROC ; Tell 'em what we're doing

	 mov	 dx,LINARG_TAB[bx] ; Get location of text
	 mov	 cx,LINARG_LEN[bx] ; Get the length
	 mov	 bx,@STD_OUT	; Get standard output file handle
	 DOSCALL @WRITF2	; Write it out

	 DOSCALL @STROUT,MSG_CRLF ; Go to a newline

	 REGREST <ds,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it
DISP_KEY_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_KEY endp			; End DISP_KEY procedure
	 NPPROC  CHECK_ARGS -- Check for Arguments
	 assume  ds:NGROUP,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Check for arguments

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 pushad 		; Save all EGP registers
	 REGSAVE <ds>		; Save segment register

	 call	 SETUP_VID	; Setup for video functions

; Start with a few default settings

	 call	 FCN_TRAPSTEP	; Hook INT 01h
	 call	 FCN_TRAPSKIP	; ...	   03h
	 call	 FCN_INTRUDE	; Intrude into MM's PL0 context
	 call	 FCN_NORMLIDT	; Disable RM LIDT

	 xor	 esi,esi	; Zero to use as dword
	 lds	 si,ARGPTR	; DS:ESI ==> command line
	 assume  ds:nothing	; Tell the assembler about it

	 call	 STR_UPPER	; Convert the string to upper case
CHECK_ARGS_SRCH:		; Search for arguments
	 call	 SKIP_WHITE	; Skip over white space

	 and	 al,al		; Check for terminator
	 jz	 near ptr CHECK_ARGS_CLC ; That's all folks

	 cmp	 al,';'         ; Check for terminator
	 je	 near ptr CHECK_ARGS_CLC ; That's all folks

; Search for the argument text

	 xor	 bx,bx		; Zero index register
	 mov	 cx,NLINARGS	; # arguments to check
CHECK_ARGS_NEXT:
	 mov	 di,LINARG_TAB[bx] ; Get location of text

	 REGSAVE <cx,si>	; Save for a moment
	 mov	 cx,LINARG_LEN[bx] ; Get length
    repe cmps	 ds:[si].LO,es:[di].LO ; Compare 'em
	 REGREST <si,cx>	; Restore
	 jne	 short CHECK_ARGS_NEXT1 ; Not this one

; Mark as found only if the next character is a valid separator

	 mov	 di,LINARG_LEN[bx] ; Get length of matching command
	 add	 di,si		; Add into starting offset
	 mov	 al,ds:[di]	; Get the next character

	 cmp	 al,'='         ; Check for valid separator
	 je	 short CHECK_ARGS_FOUND ; Jump if valid

	 cmp	 al,'/'         ; Check for valid separator
	 je	 short CHECK_ARGS_FOUND ; Jump if valid

	 cmp	 al,';'         ; Check for valid separator
	 je	 short CHECK_ARGS_FOUND ; Jump if valid

	 cmp	 al,' '         ; Check for blank or below
	 jbe	 short CHECK_ARGS_FOUND ; A match
CHECK_ARGS_NEXT1:
	 add	 bx,type LINARG_TAB ; Skip to next entry

	 LOOPS	 CHECK_ARGS_NEXT ; Jump if more entries to check

; Keyword not found

	 lea	 di,MSG_UNK	; ES:DI ==> error message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 stc			; Indicate an error occurred

	 jmp	 CHECK_ARGS_EXIT ; Join common exit code


CHECK_ARGS_FOUND:
	 call	 DISP_KEY	; Display the current keyword

	 mov	 LASTKEY,si	; Save starting offset
	 add	 si,LINARG_LEN[bx] ; Skip over the keyword

	 call	 LINARG_ACT[bx] ; Take appropriate action
	 jc	 short CHECK_ARGS_ERR ; Join common error code

	 jmp	 CHECK_ARGS_SRCH ; Join common tail code

CHECK_ARGS_CLC:
; Check for conflicting settings
	 test	 LC3_FLAG,@LC3_REM ; Have we specified SETCOM?
	 jnz	 short @F	; Jump if so

	 test	 LC3_FLAG,@LC3_PORTINIT ; Was PORTINIT specified without SETCOM?
	 jz	 short @F	; Jump if not

	 push	 offset NGROUP:MSG_SCONF ; Serial port settings conflict
	 call	 DISP_MSG	; Display it

	 jmp	 short CHECK_ARGS_ERR ; Join common error code
@@:

CHECK_ARGS_CLC2:
	 clc			; Indicate all went well

	 jmp	 short CHECK_ARGS_EXIT ; Join common exit code

CHECK_ARGS_ERR:
	 stc			; Indicate something went wrong
CHECK_ARGS_EXIT:
	 REGREST <ds>		; Restore
	 assume  ds:NGROUP	; Tell the assembler about it
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ARGS endp 		; End CHECK_ARGS procedure
	 NPPROC  DISP_UNK -- Display Message and Unknown Keyword
	 assume  ds:nothing,es:NGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display error message and unknown keyword.

On entry:

ES:DI	 ==>	 error message to display
DS:SI	 ==>	 unknown keyword

|

	 push	 di		; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we couldn't decipher their handwriting

; Copy unmatched text to local buffer

	 REGSAVE <ax,cx,si,di>	; Save registers

	 mov	 cx,30		; Maximum message length
@@:
	 lods	 ds:[si].LO	; Get next character
S16	 stos	 es:[di].LO	; Save in local buffer

	 cmp	 al,' '         ; Check for terminator
	 jbe	 short @F	; Jump if that's all folks

	 LOOPS	 @B		; Jump if more characters
@@:
	 mov	 ax,LF*256+CR	; Line terminators
S16	 stos	 es:[di].ELO	; Save in message

	 mov	 al,EOS 	; String terminator
S16	 stos	 es:[di].ELO	; Save in message

	 REGREST <di,si,cx,ax>	; Restore

	 push	 di		; Pass address of unknown keyword
	 call	 DISP_MSG	; Tell 'em we couldn't decipher their handwriting

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_UNK endp			; End DISP_UNK procedure
	 NPPROC  DISP_MSG -- Display Message
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_MSG_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's return address
DISP_MSG_OFF dw  ?		; Offset in CS of message

DISP_MSG_STR ends

	 push	 bp		; Prepare to address stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,dx,ds>	; Save registers

	 push	 cs		; Setup DS for @STROUT
	 pop	 ds
	 assume  ds:NGROUP	; Tell the assembler about it

	 mov	 dx,[bp].DISP_MSG_OFF ; DS:DX ==> message

	 DOSCALL @STROUT	; Display the message

	 REGREST <ds,dx,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_MSG endp			; End DISP_MSG procedure
	 NPPROC  SKIP_WHITE -- Skip Over White Space
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over white space

On entry:

DS:SI	 ==>	 command line

On exit:

AL	 =	 non-white space character
DS:SI	 ==>	 (updated)

|

@@:
	 lods	 ds:[si].LO	; Get next character

	 cmp	 al,' '         ; Izit white space?
	 je	 short @B	; Yes, go around again

	 cmp	 al,TAB 	; Izit white space?
	 je	 short @B	; Yes, go around again

	 dec	 si		; Back off to previous character

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SKIP_WHITE endp 		; End SKIP_WHITE procedure
	 NPPROC  STR_UPPER -- Copnvert String to Uppercase
	 assume  ds:nothing,es:NGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert ASCIIZ string at DS:SI to uppercase

|

	 REGSAVE <ax,si>	; Save registers
STR_UPPER_NEXT:
	 lods	 ds:[si].LO	; Get next character

	 and	 al,al		; Check for end-of-the-line
	 jz	 short STR_UPPER_EXIT ; Good guess

	 cmp	 al,EOF 	; Check for end-of-the-file
	 je	 short STR_UPPER_EXIT ; Good guess

	 cmp	 al,'a'         ; Check against lower limit
	 jb	 short STR_UPPER_NEXT ; Jump if too small

	 cmp	 al,'z'         ; Check against upper limit
	 ja	 short STR_UPPER_NEXT ; Jump if too large

	 add	 al,'A'-'a'     ; Convert to uppercase

	 mov	 ds:[si-1],al	; Save back in text

	 jmp	 short STR_UPPER_NEXT ; Go around again

STR_UPPER_EXIT:
	 REGREST <si,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

STR_UPPER endp			; End STR_UPPER procedure
	 NPPROC  PROC_PROFILE -- Process Profile Entries
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing

	 pushad 		; Save all EGP registers
	 REGSAVE <ds,es>	; Save segment registers

; We may be loaded as a load module.  We'll need to get the CONFIG.SYS
; processor's segment PSP, add 10H for its CS/DS, and use that...

	 DOSCALL @GETPS0	; Return current PSP in BX
	 add	 bx,10h 	; Skip to start of code
	 mov	 ds,bx		; Address code for search
	 assume  ds:nothing	; Tell the assembler

	 sub	 si,si		; Start of segment

	 call	 INIT_MBOOT	; Find current CONFIG= setting

	 mov	 ds,PROF_SEG	; Get the segment
	 assume  ds:nothing	; Tell the assembler about it

; Convert everything to common case

	 xor	 esi,esi	; DS:ESI ==> start of profile

	 mov	 cx,PROF_CNT	; Get # bytes in profile
	 or	 cx,cx		; Izit empty?
	 jz	 near ptr PROC_PROF_EOF ; Jump if so

	 call	 STR_UPPER	; Convert the string to upper case
; Loop through the file contents

PROC_PROF_LINE:
	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,EOF 	; Check for end of the file
	 je	 near ptr PROC_PROF_EOF ; Skip over it

	 call	 CHECK_MBOOT	; Check to see if line belongs to us
	 jc	 short @F	; Jump if so

	 call	 SKIP_EOL_COMMENT ; Skip entire line, return next char in AL
	 jmp	 PROC_PROF_EOL2 ; Join common code

@@:
	 cmp	 al,';'         ; Check for end of the line
	 je	 short PROC_PROF_EOL ; Skip over it

	 cmp	 al,CR		; Check for end of the line
	 je	 short PROC_PROF_EOL ; Skip over it

	 cmp	 al,LF		; Check for end of the line
	 je	 short PROC_PROF_EOL ; Skip over it

; Search for the argument text

	 xor	 bx,bx		; Zero index register
	 mov	 cx,NLINARGS	; # arguments to check
PROCHK_ARGS_NEXT:
	 mov	 di,LINARG_TAB[bx] ; Get location of text

	 REGSAVE <cx,si>	; Save for a moment
	 mov	 cx,LINARG_LEN[bx] ; Get length
    repe cmps	 ds:[si].LO,es:[di].LO ; Compare 'em
	 REGREST <si,cx>	; Restore
	 jne	 short PROCHK_ARGS_NEXT1 ; Not this one

; Mark as found only if the next character is a valid separator

	 mov	 di,LINARG_LEN[bx] ; Get length of matching command
	 add	 di,si		; Add into starting offset
	 mov	 al,ds:[di]	; Get the next character

	 cmp	 al,'='         ; Check for valid separator
	 je	 short PROCHK_ARGS_FOUND ; Jump if valid

	 cmp	 al,'/'         ; Check for valid separator
	 je	 short PROCHK_ARGS_FOUND ; Jump if valid

	 cmp	 al,';'         ; Check for valid separator
	 je	 short PROCHK_ARGS_FOUND ; Jump if valid

	 cmp	 al,' '         ; Check for blank or below
	 jbe	 short PROCHK_ARGS_FOUND ; A match
PROCHK_ARGS_NEXT1:
	 add	 bx,type LINARG_TAB ; Skip to next entry

	 LOOPS	 PROCHK_ARGS_NEXT ; Jump if more entries to check

; Keyword not found

	 lea	 di,MSG_UNKPRO	; Pass address of error message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 jmp	 short PROC_PROF_ERR ; Call it an error

PROCHK_ARGS_FOUND:
	 call	 DISP_KEY	; Display the current keyword

	 mov	 LASTKEY,si	; Save starting offset
	 add	 si,LINARG_LEN[bx] ; Skip over the keyword

	 call	 LINARG_ACT[bx] ; Take appropriate action
	 jc	 short PROC_PROF_ERR ; Jump if something went wrong
PROC_PROF_EOL:
	 call	 SKIP_EOL	; Skip to end of line, allowing white space
	 lea	 dx,MSG_EOLERR	; In case something goes wrong
	 jc	 short PROC_PROF_ERRMSG ; Jump if error

PROC_PROF_EOL2:
	 cmp	 al,EOF 	; Check for EOF
	 je	 short PROC_PROF_EOF ; Jump if EOF found

	 cmp	 si,PROF_CNT	; Check against current position
	 jb	 near ptr PROC_PROF_LINE ; Continue on
PROC_PROF_EOF:
	 clc			; Indicate all went well

	 jmp	 short PROC_PROF_EXIT ; Join common exit code

PROC_PROF_ERRMSG:
	 push	 dx		; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we couldn't decipher their handwriting
PROC_PROF_ERR:
	 stc			; Indicate something went wrong
PROC_PROF_EXIT:
	 REGREST <es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_PROFILE endp		; End PROC_PROFILE procedure
	 NPPROC  SKIP_EOL -- Skip to End-of-line
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip to the end of the current line ensuring that there's at
most white space or comment text in the trailing portion.

An alternate entry point at SKIP_EOL_COMMENT unconditionally
skips to the end of the line.

|

	 call	 SKIP_WHITE	; Skip over white space
	 inc	 si		; Skip to next character

	 cmp	 al,EOF 	; Check for EOF
	 je	 short SKIP_EOL_EXIT  ; Jump if so (note CF=0)

	 cmp	 al,';'         ; Check for comment marker
	 je	 short SKIP_EOL_COMMENT ; Jump if so

	 cmp	 al,CR		; Check for CR
	 je	 short SKIP_EOL_CRLF  ; Jump if so

	 cmp	 al,LF		; Check for LF
	 je	 short SKIP_EOL_CRLF  ; Jump if so

	 stc			; Indicate something went wrong

	 jmp	 short SKIP_EOL_EXIT ; Join common exit code

	 public  SKIP_EOL_COMMENT
SKIP_EOL_COMMENT:
	 lods	 ds:[si].LO	; Get next byte

	 cmp	 al,CR		; Izit end of the line?
	 je	 short SKIP_EOL_CRLF  ; Yes

	 cmp	 al,LF		; Izit end of the line?
	 je	 short SKIP_EOL_CRLF  ; Yes

	 cmp	 al,EOF 	; Izit end of the file?
	 je	 short SKIP_EOL_EXIT  ; Yes (note CF=0)

	 jmp	 short SKIP_EOL_COMMENT ; Go around again

SKIP_EOL_CRLF:
	 call	 SKIP_WHITE	; Skip over white space
	 inc	 si		; Skip to next character

	 cmp	 al,EOF 	; Check for EOF
	 je	 short SKIP_EOL_EXIT  ; Jump if so (note CF=0)

	 cmp	 al,CR		; Check for CR
	 je	 short SKIP_EOL_CRLF  ; Jump if so

	 cmp	 al,LF		; Check for LF
	 je	 short SKIP_EOL_CRLF  ; Jump if so

	 clc			; Indicate all went OK
SKIP_EOL_EXIT:
	 dec	 si		; Back up to last byte

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SKIP_EOL endp			; End SKIP_EOL procedure
	 FPPROC  INT24 -- Critical Error Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Critical error interrupt handler.

Cut back the stack to the INT 21h caller,
set CF, and RETF 2.

|

ARG_STR  struc

	 dw	 ?		; Caller's BP
ARG_CSIP dd	 ?		; Caller's return address
ARG_FLG  dw	 ?		; Caller's flags

ARG_STR  ends

	 add	 sp,3*2 	; Strip off IP, CS, FL from INT 24h caller

	 REGREST <ax,bx,cx,dx,si,di,bp,ds,es> ; Restore INT 21h caller's regs
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

; Set caller's flags (IF is the only significant one)

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack
	 push	 [bp].ARG_FLG	; Put flags onto stack
	 popf			; Restore caller's IF
	 pop	 bp		; Restore

	 stc			; Ensure set to indicate error

	 ret	 2		; Return to INT 21h caller, popping flags

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT24	 endp			; End INT24 procedure
	 NPPROC  INST24 -- Install INT 24h Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <ax,ds,es>	; Save registers

	 push	 seg NGROUP	; Setup DS for data references
	 pop	 ds
	 assume  ds:NGROUP	; Tell the assembler about it

	 push	 seg INTVEC	; Prepare to address segment zero
	 pop	 es		; Hello, segment zero
	 assume  es:INTVEC	; Tell the assembler about it

	 cli			; Nobody move

	 lea	 ax,INT24	; Get & set offset
	 xchg	 ax,INT00_VEC.VOFF[24h*type INT00_VEC]
	 mov	 OLDINT24_VEC.VOFF,ax ; Save to restore later

	 mov	 ax,cs		; Get & set segment
	 xchg	 ax,INT00_VEC.VSEG[24h*type INT00_VEC]
	 mov	 OLDINT24_VEC.VSEG,ax ; Save to restore later

	 sti			; Allow interrupts

	 REGREST <es,ds,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST24	 endp			; End INST24 procedure
	 NPPROC  REST24 -- Restore INT 24h Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <ax,ds,es>	; Save registers

	 push	 seg NGROUP	; Setup DS for data references
	 pop	 ds
	 assume  ds:NGROUP	; Tell the assembler about it

	 push	 seg INTVEC	; Prepare to address segment zero
	 pop	 es		; Hello, segment zero
	 assume  es:INTVEC	; Tell the assembler about it

	 lds	 ax,OLDINT24_VEC ; DS:AX ==> old interrupt handler
	 assume  ds:nothing	; Tell the assembler about it

	 cli			; Nobody move
	 mov	 INT00_VEC.VOFF[24h*type INT00_VEC],ax ; Restore offset
	 mov	 INT00_VEC.VSEG[24h*type INT00_VEC],ds ; ...	segment
	 sti			; Allow interrupts

	 REGREST <es,ds,ax>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST24	 endp			; End REST24 procedure

NCODE	 ends			; End NCODE segment

	 MEND			; End SWAT_ARG module
