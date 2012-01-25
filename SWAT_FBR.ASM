;' $Header:   P:/PVCS/386SWAT/SWAT_FBR.ASV   1.13   21 Aug 1997 15:00:22   BOB  $
	 title	 SWAT_FBR -- 386SWAT File Browser Functions
	 page	 58,122
	 name	 SWAT_FBR

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1992-7 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Henry Groover, February 1992.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include ALLMEM.INC
	 include VCPI.INC
	 include BITFLAGS.INC
	 include DPMI.INC
	 include DOSCALL.INC
	 include MAXDEV.INC
	 include ASCII.INC
	 include 8259.INC
	 include CPUFLAGS.INC

	 include SWAT_COM.INC
	 include SWAT_LOG.INC
	 include SWAT_SEG.INC
	 include SWAT_SYM.INC
.list

DATA16	 segment use32 dword public 'data' ; Start DATA16 segment
	 assume  ds:DGROUP

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	 extrn	 DEFATTR:byte
	 extrn	 CURATTR:byte
	 extrn	 TTLATTR:byte

	 extrn	 CMD_LINE:byte
	 extrn	 CMD_LINE_LEN:dword

	 extrn	 SYM_READBUF:byte

	 public  FBROWS_BUFP,FBROWS_BUFLEN
FBROWS_BUFP dd	 offset DGROUP:SYM_READBUF ; Offset within DGROUP of buffer
FBROWS_BUFLEN dd @SYM_READBUFSIZ ; Length in bytes of buffer

	 public  FBROWS_PATH,@FBROWS_PMAX
@FBROWS_PMAX equ 511		; Maximum characters in source search path
FBROWS_PATH db	 @FBROWS_PMAX dup (?) ; Directories to search for source files
	 db	 0		; ASCIIZ terminator

DATA16	 ends			; End DATA16 segment


DATA	 segment use32 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 SCROFF:dword

	 extrn	 MSGOFF:dword
	 extrn	 SYNTERR:byte
	 extrn	 OVFERR:byte
	 extrn	 NOFBROWS:byte

	 extrn	 SELFDBG:dword

	 extrn	 SYM_FH:word
	 extrn	 FILERR:byte

	 extrn	 DSP_STATE:byte
	 extrn	 DSP_STAT2:byte
	 extrn	 DSP_STAT3:byte

	 public  FBROWS_FPTR,FBROWS_FLEN
FBROWS_FPTR dd	 ?		; Offset within file of data in buffer
FBROWS_FLEN dd	 ?		; Length of valid data in buffer

	 public  FBROWS_NUMLINES
FBROWS_NUMLINES dd @FBROWS_NROWS ; Number of lines on browser screen

	 public  FBROWS_SOFF,FBROWS_SLINE,FBROWS_COFF,FBROWS_CLINE,FBROWS_ELINE
FBROWS_SOFF dd	 ?		; Offset within file of screen start
FBROWS_SLINE dd  ?		; Line number within file of screen start
FBROWS_COFF dd	 ?		; Offset within file of highlighted line
FBROWS_CLINE dd  ?		; Line number within file of highlighted line
FBROWS_ELINE dd  ?		; Line number of last line in screen

	 public  FBROWS_MSG2,FBROWS_MSG3,FBROWS_MSG4,FBROWS_MSG4_SRC
	 public  FBROWS_BUF
FBROWS_MSG2	 db	 'Line ',0
FBROWS_MSG3	 db	 ' - ',0
;FBROWS_MSG2_LN  db	 'xxxxx - '
;FBROWS_MSG2_ELN  db	 'xxxxx; source mode '
FBROWS_MSG4	 db	 '; source mode '
FBROWS_MSG4_SRC  db	 'off '
FBROWS_MSG4_MOD  db	 ' (module name ignored)',0
FBROWS_BUF	 db	 81 dup (?) ; Also used in SWAT_BLK.ASM

	 public  FBROWS_NOFILE,BADDIR,GETCWDERR,GETDCWDERR
FBROWS_NOFILE db 'No file loaded into browser',0
BADDIR	 db	 'Invalid drive / directory',0
GETCWDERR db	 'Unable to get current directory',0
GETDCWDERR db	 'Unable to get current directory on specified drive',0

@MAXBASE equ	 15		; Maximum file basename
	 public  MODPATH,MODBASE
MODPATH  db	 66 dup (?)	; d:\dir\ portion of last module path
MODBASE  db	 @MAXBASE dup (?) ; Basename of last file loaded into browser
	 db	 0		; ASCIIZ terminator

	 public  FBROWS_NAME
FBROWS_NAME db	 80 dup (0)	; Pathname of file loaded into browser

	 public  CWDIR
CWDIR	 db	 128 dup (0)	; Current working directory

DATA	 ends			; End DATA segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 extrn	 CLEAR_EOL:near
	 extrn	 CLEAR_EOP:near
	 extrn	 DISPASCIIZ:near
	 extrn	 DISPDEC:near
	 extrn	 UPPERCASE:near
	 extrn	 NEXTLINE:near

	 extrn	 DISP_CMDLINE:near
	 extrn	 PURGE_KBUFF:near
	 extrn	 GETNDKEY:near

	 extrn	 CMD_WHITE:near
	 extrn	 U32_BASE2BIN:near

	 extrn	 DOS_AVAIL:near
	 extrn	 PL0_INT21:near

	 extrn	 LDISPMSG:near

	 NPPROC  CMD_GOLINE -- Go to specified line in current file
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT&

Go to line (in file being viewed)
Turn line number display on/off

LI dddd[+|-]
LI+
LI-
LINE ...

Argument is a decimal number.  If optional + or - is present,
value is relative to current position in file.	Otherwise,
(value - FBROWS_SLINE) is passed to ADJUST_SLINE as a signed
offset.

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

&

	 REGSAVE <eax,ebx,ecx>	; Save

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 or	 al,al		; Izit the end of the line?
	 jz	 short CMD_GOLINE_SYNTERR ; Jump if so

	 cmp	 al,'-'         ; Izit turn line display off?
	 jne	 short @F	; Jump if not

	 or	 LC2_FLAG,@LC2_NOLINE ; Turn on suppress line display bit
	 jmp	 short CMD_GOLINE_EXIT0 ; Join common exit

@@:
	 cmp	 al,'+'         ; Izit turn line display on?
	 jne	 short @F	; Jump if not

	 and	 LC2_FLAG,not @LC2_NOLINE ; Turn off suppress line display bit
	 jmp	 short CMD_GOLINE_EXIT0 ; Join common exit

@@:
	 cmp	 FBROWS_NAME,0	; Do we have a file loaded?
	 je	 short CMD_GOLINE_NOFILERR ; Jump if not

	 mov	 ecx,10 	; Use base 10
	 call	 U32_BASE2BIN	; Convert decimal value to hex
	 jc	 short CMD_GOLINE_OVFERR ; Jump if error in conversion

	 cmp	 eax,0000ffffh	; Izit a valid line number?
	 ja	 short CMD_GOLINE_OVFERR ; Jump if not

	 mov	 ebx,eax	; Save line number or offset

	 call	 CMD_WHITE	; Skip trailing white space
	 cmp	 al,'+'         ; Izit forward from current line?
	 je	 short CMD_GOLINE_ADJUST ; Jump if so

	 neg	 ebx		; Assume it's negative
	 cmp	 al,'-'         ; Izit backward from current line?
	 je	 short CMD_GOLINE_ADJUST ; Jump if so

	 neg	 ebx		; Restore sign

	 or	 al,al		; Izit the end of the line?
	 jnz	 short CMD_GOLINE_SYNTERR ; Jump if not

	 dec	 ebx		; Make line number 0-based
	 sub	 ebx,FBROWS_SLINE ; Convert to relative offset
CMD_GOLINE_ADJUST:
	 mov	 eax,ebx	; Get offset from current line
	 call	 ADJUST_SLINE	; Move current line within browser
CMD_GOLINE_EXIT0:
	 or	 LCL_FLAG,@LCL_REDI ; Force redisplay

	 jmp	 short CMD_GOLINE_EXIT ; Join common exit

CMD_GOLINE_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	 jmp	 short CMD_GOLINE_ERR ; Join common error exit code

CMD_GOLINE_NOFILERR:
	 mov	 MSGOFF,offset DGROUP:NOFBROWS ; Save offset of error message

	 jmp	 short CMD_GOLINE_ERR ; Join common error exit code

CMD_GOLINE_OVFERR:
	 mov	 MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

;;;;;;;; jmp	 short CMD_GOLINE_ERR ; Join common error exit code

CMD_GOLINE_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Mark as in error
;;;;;	 jmp	 short CMD_GOLINE_EXIT ; Join common exit

CMD_GOLINE_EXIT:
	 REGREST <ecx,ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_GOLINE endp 		; End procedure CMD_GOLINE
	 NPPROC  CMD_SBMODE -- Set/clear source browser mode
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Set source browse mode command

SB [*]+  Enables source browse mode
SB [*]-  Disables source browse mode

Enables/disables source browse mode (off by default).  The optional
'*' indicates that the ignore module name attribute of source browse
mode is to be enabled/disabled as well.

When source browse mode is enabled and a file has been loaded
into the browser via the LF command, the current line number
matches a line number type symbol, and (the module basename of
the current line matches the basename of the file currently
loaded in the browser or the ignore module name attribute is
set), the source line is automatically passed to ADJUST_SLINE.

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx>	; Save

	 or	 LCL_FLAG,@LCL_REDI ; Force redisplay

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 near ptr CMD_SBMODE_SYNTERR ; Yes, treat as error

	sub	ebx,ebx 	; Clear additional attributes

	 cmp	 al,'*'         ; Izit the ignore module name modifier?
	 jne	 short @F	; Jump if not

	 lods	 DGROUP:[esi].LO ; Get next character
	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	or	ebx,@LC2_IGNMOD ; Ignore module name
@@:
	 cmp	 al,'+'         ; Izit enable?
	 jne	 short @F	; Jump if not

	or	ebx,@LC2_SRC	; Enable source browse mode
	or	LC2_FLAG,ebx	; Add in source browse and ignore bits

	 mov	 al,@DSP_IREGS	; New display mode
	 mov	 DSP_STATE,al	; Primary display mode
	 mov	 DSP_STAT2,al	; Secondary display mode
	 mov	 DSP_STAT3,@DSP_FBROWS ; Return to file browser when line found

	 jmp	 short CMD_SBMODE_CLC ; Join common exit

@@:
	 cmp	 al,'-'         ; Izit disable?
	 jne	 short CMD_SBMODE_SYNTERR ; Jump if not (invalid)

	or	ebx,@LC2_SRC	; Create inverse of mask
	not	ebx		; Get mask for bits to turn off
	and	LC2_FLAG,ebx	; Turn off source browse mode and ignore module
CMD_SBMODE_CLC:
	 clc			; Indicate success

	 jmp	 short CMD_SBMODE_EXIT ; Join common exit

CMD_SBMODE_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
	 stc			; Indicate failure
;;;;;;	 jmp	 short CMD_SBMODE_EXIT ; Join common exit code

CMD_SBMODE_EXIT:
	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_SBMODE endp 		; End procedure CMD_SBMODE
	 NPPROC  CMD_LOADFIL -- Load file into browser
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Load file command

LF filename

If PL0 DPMI services exist and DOS isn't busy, load the specified
file from disk using DOS services via DPMI translation.
The file will be available for viewing via the file browser
screen (Ctrl-F7).

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 pushad 		; Save all EGP registers

	 mov	 SYM_FH,-1	; Mark file handle as unused

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 near ptr CMD_LOADFIL_SYNTERR ; Yes, treat as error

; Parse file pathname
; Copy string at DS:ESI to FBROWS_NAME

	 lea	 edi,FBROWS_NAME ; Offset for filename
CMD_LOADFIL_NEXTC:
	 lods	 FBROWS_NAME[esi] ; Get byte

	 cmp	 al,' '         ; Izit whitespace?
	 je	 short @F	; Jump if so

	 cmp	 al,TAB 	; Izit a tab?
	 jne	 short CMD_LOADFIL_PUTC ; Jump if not
@@:
	 sub	 al,al		; Force end of string
CMD_LOADFIL_PUTC:
S32	 stos	 FBROWS_NAME[edi] ; Save byte
	 or	 al,al		; Izit the end?
	 jnz	 short CMD_LOADFIL_NEXTC ; Jump if not

	 dec	 esi		; Back off to last character

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit the end?
	 jne	 near ptr CMD_LOADFIL_SYNTERR ; Treat excess as syntax error
CMD_LOADFIL_PROCESS:
	 call	 DOS_AVAIL	; Are DOS services under DPMI available?
	 jc	 near ptr CMD_LOADFIL_ERR ; Jump if not (message text set)

	 lea	 edx,FBROWS_NAME ; Get filename
	 sub	 al,al		; Set file sharing/access mode to compatible/RO
	 mov	 ah,@OPENF2	; Open file at DS:eDX
	 FINTD	 PL0_INT21	; Return handle in AX
	 jc	 near ptr CMD_LOADFIL_FILERR ; Jump if open failed

	 mov	 SYM_FH,ax	; Save file handle
	 mov	 bx,ax		; Prepare to read
	 mov	 ecx,@SYM_READBUFSIZ ; Bytes to read
	 lea	 edx,SYM_READBUF ; Buffer to read into
	 xor	 eax,eax	; Zero to use as dword
	 mov	 ah,@READF2	; Read into buffer at DS:eDX
	 FINTD	 PL0_INT21	; Return with bytes read in eAX
	 jc	 near ptr CMD_LOADFIL_FILERR ; File I/O error

	 mov	 FBROWS_FLEN,eax ; Save length of valid data in SYMLOAD_BUF
	 sub	 eax,eax	; Get a convenient 0
	 mov	 FBROWS_SLINE,eax ; Reset starting line
	 mov	 FBROWS_CLINE,eax ; Reset current line value
	 mov	 FBROWS_SOFF,eax ; Reset screen start
	 mov	 FBROWS_COFF,eax ; Reset current line offset
	 mov	 FBROWS_FPTR,eax ; Reset file offset

; Extract basename of module for comparison with line number records
	 lea	 edi,FBROWS_NAME ; Address complete path
	 mov	 ecx,79 	; Maximum path length
	 sub	 al,al		; Search for trailing null
	 cld			; Move forward
   repne scas	 DGROUP:[edi].LO ; Find end
	 dec	 edi		; Back off to trailing null
	 mov	 esi,edi	; Save end in case there's no extension
	 mov	 al,'.'         ; Find extension
	 std			; Move backwards
	 mov	 ecx,5		; '.' + ext + \0
   repne scas	 DGROUP:[edi].LO ; Find extension
	 je	 short @F	; Jump if we found it

	 lea	 edi,[esi-1]	; Go back to last character
@@:
; DGROUP:EDI ==> last character in basename
	 mov	 ecx,@MAXBASE	; Maximum characters in basename
	 lea	 ebx,FBROWS_NAME ; Furthest back we can go
	 mov	 esi,edi	; Prepare for lodsb
CMD_LOADFIL_MNEXT:
	 mov	 edx,esi	; Save offset for case conversion
	 lods	 DGROUP:[esi].LO ; Get byte

	 call	 UPPERCASE	; Convert AL to uppercase
	 mov	 DGROUP:[edx].LO,al ; Save it

	 cmp	 esi,ebx	; Are we at the beginning?
	 jb	 short CMD_LOADFIL_MCOPY ; Jump if so

	 inc	 esi		; Assume we hit end of drive:\dir\

	 cmp	 al,'\'         ; Izit end of directory?
	 je	 short CMD_LOADFIL_MCOPY ; Jump if so

	 cmp	 al,'/'         ; Izit alternate end of directory?
	 je	 short CMD_LOADFIL_MCOPY ; Jump if so

	 cmp	 al,':'         ; Izit end of drive:?
	 je	 short CMD_LOADFIL_MCOPY ; Jump if so

	 dec	 esi		; Restore previous value

	 loop	 CMD_LOADFIL_MNEXT ; Try next

; DGROUP:EDI ==> character before beginning of module basename
CMD_LOADFIL_MCOPY:
	 mov	 ecx,edi	; Offset of last character
	 sub	 ecx,esi	; Characters in module name
	 inc	 esi		; Point to next character (beginning of module)
	 cld			; String ops forwardly
	 lea	 edi,MODBASE	; Where to save it
S32  rep movs	 <DGROUP:[edi].LO,DGROUP:[esi].LO> ; Copy basename to MODBASE
	 mov	 DGROUP:[edi].LO,0 ; Terminate in case length is 0
	 mov	 FBROWS_ELINE,0 ; Initialize ending line for browser display
	 jmp	 short CMD_LOADFIL_EXIT ; Yes, we're done

CMD_LOADFIL_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	 jmp	 short CMD_LOADFIL_ERR ; Join common error exit code

CMD_LOADFIL_FILERR:
	 mov	 MSGOFF,offset DGROUP:FILERR ; Save offset of error message

	 jmp	 short CMD_LOADFIL_ERR ; Join common error exit code

CMD_LOADFIL_OVFERR:
	 mov	 MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

;;;;;;;; jmp	 short CMD_LOADFIL_ERR ; Join common error exit code

CMD_LOADFIL_ERR:
	 mov	 FBROWS_NAME[0],0 ; Clear filename

	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Mark as in error
CMD_LOADFIL_EXIT:
	 pushfd 		; Save for a moment

	 mov	 bx,SYM_FH	; Get file handle to close
	 cmp	 bx,-1		; Izit invalid?
	 je	 short @F	; Jump if so

	 mov	 ah,@CLOSF2	; Close handle in BX
	 FINTD	 PL0_INT21	; Ignore error
@@:
	 or	 LCL_FLAG,@LCL_REDI ; Force redisplay

	 popfd			; Restore

	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_LOADFIL endp		; End CMD_LOADFIL procedure

	 NPPROC  CMD_CHDIR -- Change or display current directory
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Change directory command

1. CD			Returns current working directory on default drive
2. CD drive:		Returns CWD on specified drive
3. CD drive:directory	Sets CWD for specified drive
4. CD directory 	Sets CWD for default drive

Cases 3 & 4 are handled by DOS fn 3Bh (@CHDIR).

If PL0 DPMI services exist and DOS isn't busy, get the current
directory (on the specified drive).  If a directory is specified,
make it the current directory.

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 pushad 		; Save all EGP registers

	 call	 DOS_AVAIL	; Are DOS services under DPMI available?
	 jc	 near ptr CMD_CHDIR_ERR ; Jump if not (message text set)

	 SELFBREAK CMD_CHDIR,8000h ; Break if SELFDBG & 8000h

; Copy arguments to CWDIR as an ASCIIZ string.
	 lea	 edi,CWDIR	; ES:EDI ==> workspace for new directory
	 cld			; String ops forwardly

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	 or	 al,al		; Izit the end?
	 jz	 short CMD_CHDIR_EOL ; Jump if so

@@:
	 lods	 DGROUP:[esi].LO ; Get next character
	 cmp	 al,' '         ; Izit whitespace?
	 jbe	 short @F	; Jump if so

S32	 stos	 CWDIR[edi]	; Save in buffer
	 jmp	 short @B	; Go around again

@@:
	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 or	 al,al		; Izit the end of the line?
	 jnz	 near ptr CMD_CHDIR_SYNTERR ; Jump if so - it's a syntax error

CMD_CHDIR_EOL:
S32	 stos	 CWDIR[edi]	; Save in buffer to terminate CWDIR

	 lea	 esi,CWDIR	; Address start of args
	 lods	 CWDIR[esi]	; Get first character

	 or	 al,al		; Izit end of line?
	 jz	 short CMD_CHDIR_CWD ; Jump if so

	 call	 UPPERCASE	; Convert AL to uppercase
	 mov	 dl,al		; Drive to get directory for
	 sub	 dl,'A'-1       ; A=1, B=2, etc.

	 cmp	 DGROUP:[esi].ELO,':' ; Izit a drive letter only?
	 je	 short CMD_CHDIR_DRV ; Jump if so (AL = first character)
CMD_CHDIR_CHDIR:
	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
@@:
	 lods	 DGROUP:[esi].LO ; Get next character
	 cmp	 al,' '         ; Izit whitespace?
	 jbe	 short @F	; Jump if so

S32	 stos	 CWDIR[edi]	; Save in buffer
	 jmp	 short @B	; Go around again

@@:
	 mov	 DGROUP:[edi].LO,0 ; Terminate CWDIR
CMD_CHDIR_DOSCALL:
	 mov	 ah,@CHDIR	; Change current working directory
	 lea	 edx,CWDIR	; DS:EDX ==> new directory
	 FINTD	 PL0_INT21	; Change directory to DS:EDX
	 jc	 short CMD_CHDIR_BADDIR ; Jump if invalid directory

	 jmp	 short CMD_CHDIR_CLC ; Join common exit

CMD_CHDIR_CWD:
	 sub	 dl,dl		; Assume get current directory for default drive

	 mov	 ah,@GETDSK	; Get default drive
	 FINTD	 PL0_INT21	; AL = current drive (origin:0)
	 jc	 short CMD_CHDIR_GETCWD ; Jump if failed

;;;;;;;  mov	 dl,al		; DL=0 (CWD for current drive)
	 add	 al,'A'         ; Convert to drive letter
CMD_CHDIR_DRV:
	 lea	 edi,CWDIR	; Address buffer for drive:\directory name
S32	 stos	 CWDIR[edi]	; Save in buffer
	 mov	 ax,'\:'        ; Add ':\'
S32	 stos	 CWDIR[edi].ELO ; Save

; Get and display current working directory for drive DL.
	 mov	 esi,edi	; Get start of current directory
	 mov	 ah,@GETDIR	; Get ASCIIZ current dir for drive DL in DS:ESI
	 FINTD	 PL0_INT21	; Return CF=0 if copied to DS:ESI
	 jc	 short CMD_CHDIR_GETCWD ; Jump if failed

	 lea	 edi,CMD_LINE	; Address command line
	 mov	 ecx,CMD_LINE_LEN ; Maximum length
	 lea	 esi,CWDIR	; Address drive:\directory
@@:
	 lods	 CWDIR[esi]	; Get next byte
S32	 stos	 CMD_LINE[edi]	; Save in command line

	 or	 al,al		; Izit the end?
	 loopnz  short @B	; Jump if not

     rep stos	 CMD_LINE[edi]	; Clear remainder of line

	 call	 DISP_CMDLINE	; Display the command line
	 call	 PURGE_KBUFF	; First purge the keyboard buffer
	 call	 GETNDKEY	; Get non-destructive key
CMD_CHDIR_CLC:
	 clc			; Indicate success

	 jmp	 short CMD_CHDIR_EXIT ; Join common exit

CMD_CHDIR_BADDIR:
	 mov	 MSGOFF,offset DGROUP:BADDIR ; Save offset of error message

	 jmp	 short CMD_CHDIR_ERR ; Join common error code

CMD_CHDIR_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	 jmp	 short CMD_CHDIR_ERR ; Join common error code

CMD_CHDIR_GETCWD:
	 mov	 MSGOFF,offset DGROUP:GETCWDERR ; Save offset of error message

	 or	 dl,dl		; Was a drive specified?
	 jz	 short CMD_CHDIR_ERR ; Jump if not

CMD_CHDIR_GETDCWD:
	 mov	 MSGOFF,offset DGROUP:GETDCWDERR ; Save offset of error message

;;;;;;;  jmp	 short CMD_CHDIR_ERR ; Join common error code

CMD_CHDIR_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc
CMD_CHDIR_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_CHDIR endp			; End CMD_CHDIR procedure

PATH_COM_MAC macro PREF

	 NPPROC  PREF&PATH_COM -- Common code for processing source file path
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

For each drive:\dir specified in list separated with ',' ensure that
it ends with a \ and that we don't exceed the maximum path length.
Also convert forward slashes to backslashes.

On entry:
DS:ESI	 ==>	 Path list to process
ES:EDI	 ==>	 Storage for processed path
ECX	 =	 Maximum characters to copy to ES:EDI

On exit:
DS:ESI	 ==>	 Character after end of input list
ES:EDI	 ==>	 Character after end of output (may have been truncated)
ECX	 =	 Number of characters not processed

|

	 REGSAVE <eax,ebx>	; Save

	 sub	 bl,bl		; Initialize last character
PREF&PATH_COM_NEXT:
	 lods	 ds:[esi].LO	; Get character

	 cmp	 al,' '         ; Izit a space?
	 je	 short PREF&PATH_COM_NEXT ; Skip it if so

	 cmp	 al,TAB 	; Izit a tab?
	 je	 short PREF&PATH_COM_NEXT ; Skip it also

	 cmp	 al,'/'         ; Izit a regular slash?
	 jne	 short @F	; Jump if not

	 mov	 al,'\'         ; Convert to backslash
@@:
	 cmp	 al,';'         ; Izit a comment delimiter?
	 jne	 short PREF&PATH_COM_XEOL ; Jump if not

PREF&PATH_COM_EOL:
	 cmp	 bl,'\'         ; Was a trailing backslash specified?
	 je	 short @F	; Jump if so

	 cmp	 ecx,1		; Do we have room for it?
	 jb	 short @F	; Jump if not

	 mov	 al,'\'         ; Add backslash
S32	 stos	 DGROUP:[edi].LO ; Blast it in
@@:
	 sub	 al,al		; End of line
	 dec	 esi		; Back off on input
	 jmp	 short PREF&PATH_COM_XSEP ; Join common code

PREF&PATH_COM_XEOL:
	 cmp	 al,LF		; Izit the end of the line?
	 je	 short PREF&PATH_COM_EOL ; Jump if so

	 cmp	 al,EOF 	; Izit the end of file?
	 je	 short PREF&PATH_COM_EOL ; Jump if so

	 or	 al,al		; Izit a null?
	 je	 short PREF&PATH_COM_EOL ; Jump if so

	 cmp	 al,','         ; Izit a separator?
	 jne	 short PREF&PATH_COM_XSEP ; Jump if not

	 or	 bl,bl		; Are we at the beginning?
	 jz	 short PREF&PATH_COM_NEXT ; Ignore if so

	 cmp	 bl,','         ; Izit an empty element?
	 je	 short PREF&PATH_COM_NEXT ; Ignore it

	 cmp	 bl,'\'         ; Did it end with '\'?
	 je	 short PREF&PATH_COM_XSEP ; Jump if so

	 mov	 al,'\'         ; Make it end with '\'
S32	 stos	 DGROUP:[edi].LO ; Blast it in
	 dec	 ecx		; Adjust destination count
	 mov	 al,','         ; Restore path separator

	 jecxz	 short PREF&PATH_COM_EXIT ; Bug out if we walked off the end
PREF&PATH_COM_XSEP:
S32	 stos	 DGROUP:[edi].LO ; Save character

	 or	 al,al		; Izit the end?
	 jz	 short PREF&PATH_COM_EXIT ; Jump if so

	 mov	 bl,al		; Save last character

	 loop	 PREF&PATH_COM_NEXT  ; Adjust count and continue
PREF&PATH_COM_EXIT:
	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&PATH_COM endp		; End PREF&PATH_COM procedure

	 endm			; PATH_COM_MAC

	 PATH_COM_MAC U32_	; Define for PGROUP

	 NPPROC  CMD_PATH -- Set path for source file search
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

PATH d:\dir[,d:\dir2[...]]
PATH+ d:\dir[...]

Set path for source file search, or add to path.

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax,ecx,edi>	; Save

	 lea	 edi,FBROWS_PATH ; Search path for source files
	 mov	 ecx,@FBROWS_PMAX ; Maximum length

	 cmp	 DGROUP:[esi].LO,'+' ; Was PATH+ specified?
	 jne	 short @F	; Jump if not

	 cmp	 FBROWS_PATH,0	; Izit empty?
	 je	 short @F	; Jump if so (same as setting it)

	 lods	 DGROUP:[esi].LO ; Skip +
	 sub	 al,al		; Search for end
   repne scas	 FBROWS_PATH[edi] ; ES:EDI ==> character after end of path
	 jecxz	 short CMD_PATH_EXIT ; If end, bug out

	 dec	 edi		; Back off to trailing null
	 mov	 al,','         ; Add separator
S32	 stos	 FBROWS_PATH[edi] ; Blast it in
	 mov	 DGROUP:[edi].LO,0 ; Ensure it's null terminated
@@:
	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 call	 U32_PATH_COM	; Process path

	 or	 LCL_FLAG,@LCL_REDI ; Force redisplay
CMD_PATH_EXIT:
	 clc			; Indicate success

	 REGREST <edi,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_PATH endp			; End CMD_PATH procedure
	 NPPROC  DISP_FBROWS -- Display file browser screen
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display the file browser buffer contents

When displaying file contents, we check first for the validity of the
buffer.  If FBROWS_NAME[0] != 0, it's valid; display the name,
FBROWS_SLINE to FBROWS_ELINE, and continue.

Starting at FBROWS_SOFF, we display lines, continuing until
1. <current location> - FBROWS_BUFP > FBROWS_FLEN (EOF/truncated)
2. FBROWS_NUMLINES (22) lines have been displayed

We count line numbers within the file starting from FBROWS_SLINE.  If we
match FBROWS_CLINE and LC2_SFND is set, display line highlighted.

|

	 pushad 		; Save all EGP registers

	 mov	 bl,TTLATTR	; Get title attribute
	 xchg	 bl,DEFATTR	; Swap with default attribute

	 mov	 SCROFF,0	; Start at top of screen

	 mov	 eax,' ffo'     ; Assume source mode is off
	 test	 LC2_FLAG,@LC2_SRC ; Is source mode on?
	 jz	 short @F	; Jump if not

	 mov	 eax,'  no'     ; Source mode is on
@@:
	 mov	 FBROWS_MSG4_SRC.EDD,eax ; Blast into message

	 sub	 al,al		; Assume module names significant
	 test	 LC2_FLAG,@LC2_IGNMOD ; Are we ignoring module names?
	 jz	 short @F	; Jump if not

	 mov	 al,' '         ; Join with preceding message
@@:
	 mov	 FBROWS_MSG4_MOD,al ; Modify message to include/not include this

	 lea	 esi,FBROWS_NAME ; Prepare to display header line 1
	 cmp	 FBROWS_NAME[0],0 ; Was buffer overwritten by ls?
	 jne	 short @F	; Jump if not

	 lea	 esi,FBROWS_NOFILE ; Display "No file loaded"
	 call	 DISPASCIIZ	; Display ASCIIZ string from ESI
	 call	 CLEAR_EOL	; Clear to the end-of-the-line
	 xchg	 bl,DEFATTR	; Restore default attribute
	 jmp	 near ptr DISP_FBROWS_EXIT ; Join common exit code

@@:
	 call	 DISPASCIIZ	; Display ASCIIZ string from ESI

	 call	 CLEAR_EOL	; Clear to the end-of-the-line
	 call	 NEXTLINE	; Skip to next line, first column

	 call	 CLEAR_EOL	; Clear to the end of the line

	 mov	 DEFATTR,bl	; Restore default attribute

	 mov	 edx,FBROWS_SLINE ; Get line number for beginning of screen
	 mov	 ecx,FBROWS_NUMLINES ; Maximum lines to display
	 mov	 esi,FBROWS_BUFP ; Get offset of buffer
	 add	 esi,FBROWS_SOFF ; Address start of current screen
	 sub	 esi,FBROWS_FPTR ; Subtract file seek offset
	 jnc	 short @F	; Jump if OK

	 LOGDISP 'Caught browser underflow'
	 add	 esi,FBROWS_BUFP ; Re-address start of buffer
	 mov	 FBROWS_FPTR,0	; Zero it
	 mov	 FBROWS_SOFF,0	; ...
@@:
	 mov	 SCROFF,2*@NCOLS*2 ; Skip to beginning of 3rd line
DISP_FBROWS_NEXT:
	 cmp	 edx,FBROWS_ELINE ; Izit greater than the ending line?
	 jbe	 short @F	; Jump if not

	 mov	 FBROWS_ELINE,edx ; Update ending line number
@@:
; Get one line into buffer.  Skip CR, expand tabs, and stop at LF or edge
	 mov	 ebx,ecx	; Save line count

	 mov	 ecx,80 	; Maximum characters
	 lea	 edi,FBROWS_BUF ; Address line buffer

;;;;;;;  cmp	 edx,FBROWS_CLINE ; Izit the current line?
;;;;;;;  jne	 short DISP_FBROWS_GETLN ; Jump if not
;;;;;;;
DISP_FBROWS_GETLN:
	 lods	 DGROUP:[esi].LO ; Get character

	 cmp	 al,CR		; Izit one we should skip?
	 je	 short DISP_FBROWS_GETLN ; Jump if so

	 cmp	 al,0		; Izit null?
	 je	 short DISP_FBROWS_DISPLN ; Jump if so

	 cmp	 al,LF		; Izit end of line?
	 je	 short DISP_FBROWS_DISPLN ; Jump if so

	 cmp	 al,TAB 	; Izit a tab?
	 jne	 short DISP_FBROWS_XTAB ; Jump if not

; Expand tab to 8 spaces
	 mov	 al,' '         ; Fill character
S32	 stos	 FBROWS_BUF[edi] ; Blast away
	 dec	 ecx		; Adjust count
	 jz	 short DISP_FBROWS_DISPLN ; Go to bottom of loop
DISP_FBROWS_TABFILL:
	 test	 ecx,(8-1)	; Are we on a tab boundary?
	 jz	 short DISP_FBROWS_GETLN ; Jump if so

S32	 stos	 FBROWS_BUF[edi] ; Fill tab space

	 loop	 DISP_FBROWS_TABFILL ; Continue filling

	 jmp	 short DISP_FBROWS_DISPLN ; End of loop

DISP_FBROWS_XTAB:
S32	 stos	 FBROWS_BUF[edi] ; Save character
DISP_FBROWS_LOOP:
	 loop	 DISP_FBROWS_GETLN ; Continue till LF or overrun
DISP_FBROWS_DISPLN:
	 cmp	 ecx,80 	; Do we have an empty line?
	 jne	 short @F	; Jump if not

	 mov	 al,' '         ; Put at least one space in line
S32	 stos	 FBROWS_BUF[edi] ; Blast it in
@@:
	 or	 ecx,ecx	; Did we go all the way to the end?
	 jnz	 short @F	; Jump if not

	 cmp	 DGROUP:[esi].LO,LF ; Is the next one the end?
	 je	 short @F	; Jump if so

	 cmp	 DGROUP:[esi].LO,CR ; Is the next one the end?
	 je	 short @F	; Jump if so

	 cmp	 DGROUP:[esi].LO,0 ; Is the next one null?
	 je	 short @F	; Jump if so

	 mov	 DGROUP:[edi-1].LO,10h ; Blast in arrowhead
	 mov	 al,LF		; Look for line termination
	 mov	 ecx,255-80	; Maximum line length
	 xchg	 esi,edi	; Swap registers for scan
   repne scas	 DGROUP:[edi].LO ; Look for end of line
	 xchg	 esi,edi	; Update ESI & restore DI
@@:
	 sub	 al,al		; Prepare to blast in null
S32	 stos	 DGROUP:[edi].LO ; Terminate line buffer

	 mov	 ecx,ebx	; Restore line count

	 push	 esi		; Save pointer into file buffer

	 lea	 esi,FBROWS_BUF ; Display line
	 mov	 bl,DEFATTR	; Get default attribute

	 test	 LC2_FLAG,@LC2_SFND ; Is the current F9 line a line record?
	 jz	 short @F	; Jump if not

	 cmp	 edx,FBROWS_CLINE ; Is this the current line?
	 jne	 short @F	; Jump if not

	 mov	 bl,CURATTR	; Use attribute for current line
@@:
	 xchg	 bl,DEFATTR	; Set attribute for display
	 call	 DISPASCIIZ	; Display ASCIIZ string at DS:ESI
	 call	 CLEAR_EOL	; Clear to end of line
	 xchg	 bl,DEFATTR	; Restore previous attribute

	 pop	 esi		; Restore file buffer pointer
DISP_FBROWS_EOL:
	 call	 NEXTLINE	; Skip to first column of next line

	 mov	 eax,esi	; Get current offset
	 sub	 eax,FBROWS_BUFP ; Subtract start of buffer
	 cmp	 eax,FBROWS_FLEN ; Izit the end of file?
	 jnb	 short DISP_FBROWS_EOSCN ; Jump if so

	 inc	 edx		; Bump line number

;;;;;;;; loop	 DISP_FBROWS_NEXT ; Display till end of screen
	 dec	 ecx		; Adjust loop counter
	 jnz	 near ptr DISP_FBROWS_NEXT ; Display next if not end
DISP_FBROWS_EOSCN:
	 mov	 bl,TTLATTR	; Get title attribute
	 xchg	 bl,DEFATTR	; Make it the default

	 push	 SCROFF 	; Save current position

	 mov	 SCROFF,@NCOLS*2 ; Skip to second line of display

	 lea	 esi,FBROWS_MSG2 ; Line 2 of header
	 call	 DISPASCIIZ	; Display ASCIIZ string from ESI

	 mov	 eax,FBROWS_SLINE ; Get line number 1
	 inc	 eax		; Make it 1-based
	 call	 DISPDEC	; Display it as a decimal value

	 lea	 esi,FBROWS_MSG3 ; Line number range separator
	 call	 DISPASCIIZ	; Display ASCIIZ string from ESI

	 mov	 eax,FBROWS_ELINE ; Get line number for end of screen
	 inc	 eax		; Make it 1-based
	 call	 DISPDEC	; Display in decimal

	 lea	 esi,FBROWS_MSG4 ; End of line 2 messages
	 call	 DISPASCIIZ	; Display ASCIIZ string from ESI

	 call	 CLEAR_EOL	; Clear remainder of line

	 pop	 SCROFF 	; Restore current position to clear screen

	 mov	 DEFATTR,bl	; Restore default attribute
DISP_FBROWS_EXIT:
	 call	 CLEAR_EOP	; Clear to the end-of-the-page

	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_FBROWS endp		; End DISP_FBROWS procedure
	 NPPROC  ADJUST_SLINE -- Adjust start of file browser screen
	 assume  ds:DGROUP,es:nothing,ss:nothing,fs:nothing,gs:nothing
COMMENT|

Adjust starting line for file browser.	Fix all references to the display
window.  Load parts of file if necessary and possible.	Ensure that
buffer contains enough data to display to end of screen (if not already
end of file).

If @LC2_SFND is set and offset is 0,

On entry:
EAX	 Signed offset for FBROWS_SLINE

On exit:
Nothing.

|

	 pushad 		; Save EGP regs
	 push	 es		; Save ES

	 push	 ds		; Get addressability to DGROUP
	 pop	 es		; Needed for SCAS
	 assume  es:DGROUP	; Tell the assembler

	 mov	 edi,FBROWS_BUFP ; Get offset of buffer start
	 sub	 edi,FBROWS_FPTR ; Subtract start of buffer within file
ADJUST_SLINE_RETRY:
	 mov	 ebx,eax	; Save difference

	 mov	 ecx,FBROWS_SLINE ; Get current SLINE
	 add	 eax,ecx	; Get new SLINE in EAX
	 jns	 short @F	; Jump if direction is forward

	 neg	 eax		; Get |difference|
	 add	 ebx,eax	; Adjust EBX
	 sub	 eax,eax	; Use 0
@@:
; We may want to force a change to ensure the current line is contained
; within SLINE - ELINE.
	 cmp	 eax,ecx	; Is there any change?
	 jne	 short ADJUST_SLINE_CHANGED ; Jump if so

	 test	 LC2_FLAG,@LC2_SFND ; Are we checking the framing of CLINE?
	 jz	 near ptr ADJUST_CLINE_EXIT ; Jump if not

; Calculate delta for SLINE based on CLINE.  If CLINE is outside of the
; current range, set SLINE to max (1,CLINE-1).
	 mov	 eax,FBROWS_CLINE ; Line to be highlighted
	 sub	 eax,FBROWS_SLINE ; Get distance from top of screen

	 cmp	 eax,FBROWS_NUMLINES ; Do an unsigned compare
	 jb	 near ptr ADJUST_CLINE_EXIT ; Jump if in range - no change

	 mov	 eax,FBROWS_CLINE ; Current line position
	 or	 eax,eax	; Are we already at the beginning?
	 jz	 short @F	; Jump if so

	 dec	 eax		; Start screen one line above current line
@@:
	 sub	 eax,FBROWS_SLINE ; Get signed offset for starting line

	 jmp	 short ADJUST_SLINE_RETRY ; Go around again

ADJUST_SLINE_CHANGED:
;;;;;;	 sub	 eax,FBROWS_SLINE ; Subtract starting line
;;;;;;	 cmp	 eax,FBROWS_NUMLINES ; Are we within range?
;;;;;;	 jb	 short ADJUST_CLINE_INSCRN ; Jump if so

; Location selected is not on the current screen
	 add	 edi,FBROWS_SOFF ; Add offset of screen start within file
				; (DI is now a 16-bit pointer within DGROUP)
	 sub	 ecx,FBROWS_SLINE ; Get offset of CLINE from SLINE
	 add	 FBROWS_SLINE,ebx ; Adjust screen start line value
	 call	 ADJUST_CLINE_COM ; Call common display recalculate routine

	 add	 edi,FBROWS_FPTR ; Add offset of buffer start
	 sub	 edi,FBROWS_BUFP ; Subtract offset within DGROUP
	 mov	 FBROWS_SOFF,edi ; Save new SOFF value

	 neg	 esi		; Invert subtrahend
	 or	 edx,edx	; Are we going forward?
	 jnz	 short @F	; Jump if not

	 neg	 esi		; Normalize subtrahend
@@:
	 sub	 FBROWS_SLINE,esi ; Subtract/add unprocessed lines

; If there were leftover lines, adjust ECX

	 add	 ecx,esi	; Move relative position within screen
	 jns	 short @F	; Jump if we didn't pass the beginning of the screen

	 sub	 ecx,ecx	; Minimum value
	 jmp	 short ADJUST_CLINE_REPOS ; Join common code for repositioning

@@:
	 cmp	 ecx,FBROWS_NUMLINES ; Are we within range?
	 jb	 short ADJUST_CLINE_REPOS ; Jump if so

	 mov	 ecx,FBROWS_NUMLINES ; Get ceiling
	 dec	 ecx		; Convert to maximum
ADJUST_CLINE_REPOS:
; Ensure we can read to the bottom of the screen
	 mov	 eax,FBROWS_SLINE ; Get starting line
	 mov	 ebx,FBROWS_NUMLINES ; Number of lines in screen
	 dec	 ebx		; Minus top line
	 add	 eax,ebx	; Add to assumed end line
	 mov	 FBROWS_ELINE,eax ; Save putative end line
	 add	 edi,FBROWS_BUFP ; Get offset within DGROUP + file offset
	 sub	 edi,FBROWS_FPTR ; Subtract offset within file
	 call	 ADJUST_CLINE_COM ; Call common line move code
	 sub	 FBROWS_ELINE,esi ; Subtract unprocessed lines from end

; Our FBROWS_SOFF pointer may be invalid.  Renormalize to make sure
; FBROWS_FPTR didn't change.
	 mov	 edi,FBROWS_SOFF ; Get offset within file
	 mov	 FBROWS_COFF,edi ; Save as new current offset
	 sub	 edi,FBROWS_FPTR ; Get offset within new buffer
	 add	 edi,FBROWS_BUFP ; Get offset within DGROUP

; Recalculate COFF
	 mov	 ebx,FBROWS_SLINE ; Get adjusted SLINE
;;;;;;	 mov	 FBROWS_CLINE,ebx ; Save as initial CLINE
	 or	 ecx,ecx	; Is CLINE == SLINE?
	 jz	 short ADJUST_CLINE_EXIT ; Exit if so

; Add signed ECX to CLINE
	 mov	 ebx,ecx	; Use signed difference between SLINE & CLINE
;;;;;;	 jmp	 short ADJUST_CLINE_INSCRN2 ; Join common code to move CLINE

;;;;;;; Location selected is within current screen
;;;;;;ADJUST_CLINE_INSCRN:
;;;;;;	 add	 edi,FBROWS_COFF ; Add offset of current line within file
;;;;;;				; (DI is now a 16-bit pointer within DGROUP)
;;;;;;ADJUST_CLINE_INSCRN2:
	 add	 FBROWS_CLINE,ebx ; Adjust current line value
	 call	 ADJUST_CLINE_COM ; Call common display recalculate routine

	 add	 edi,FBROWS_FPTR ; Add offset of buffer start
	 sub	 edi,FBROWS_BUFP ; Subtract offset within DGROUP
	 mov	 FBROWS_COFF,edi ; Save new COFF value
	 or	 edx,edx	; Are we going forward?
	 jz	 short @F	; Jump if so

	 neg	 esi		; Invert subtrahend
@@:
	 sub	 FBROWS_CLINE,esi ; Subtract/add unprocessed lines
ADJUST_CLINE_EXIT:
	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler

	 popad			; Restore GP regs

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ADJUST_SLINE	endp		; End ADJUST_SLINE procedure
	 NPPROC  ADJUST_CLINE_COM -- Common subroutine for ADJUST_CLINE
	 assume  ds:DGROUP,es:DGROUP,ss:nothing,fs:nothing,gs:nothing
COMMENT|

Given a direction and a number of lines to move in that direction,
move DI to the beginning of the new current line.  Move offset of
buffer within file if necessary.

On entry:
EBX	 =	Signed line offset
DGROUP:EDI ==>	Start of line
SS:EBP	 ==>	FORW_STR

On exit:
EDX == 0	Direction is forward
EDX != 0	Direction is backward
ESI		Lines requested which were NOT processed
DGROUP:EDI	New FBROWS_?OFF start of line

|

	 pushfd 		; Save flags (DF may be changed)

	 REGSAVE <eax,ebx,ecx>	; Save

	 cld			; Assume direction is forward
	 sub	 edx,edx	; Final increment
	 or	 ebx,ebx	; Did we move back?
	 jns	 short @F	; Jump if not

	 std			; Do it backwards
	 mov	 edx,2		; Value to add after scasb
	 neg	 ebx		; Convert to loop counter value
@@:
	 mov	 esi,ebx	; Save loop counter
ADJUST_CLINE_COM_NEXT:
	 or	 esi,esi	; Is the loop count 0?
	 jz	 near ptr ADJUST_CLINE_COM_EXIT ; Jump if so

	 dec	 esi		; Adjust loop counter
ADJUST_CLINE_COM_NEXT2:
	 mov	 ebx,FBROWS_BUFP ; Get start of buffer

	 sub	 edi,edx	; Subtract 2 if going backwards
	 cmp	 edi,ebx	; Did we underflow or go as far as we can?
	 ja	 short @F	; Jump if not

	 jb	 short ADJUST_CLINE_COM_READFILE ; Jump if underflow

	 or	 edx,edx	; Are we going forward?
	 jz	 short @F	; Jump if so (OK to keep going)

	 cmp	 FBROWS_FPTR,0	; Are we already at the beginning of file?
	 je	 near ptr ADJUST_CLINE_COM_EXIT ; Exit if so (DI is OK)

	 jmp	 short ADJUST_CLINE_COM_READFILE ; Read more into buffer

@@:
	 add	 ebx,FBROWS_FLEN ; Get byte past end of valid buffer contents

	 cmp	 edi,ebx	; Are we within bounds?
	 jb	 near ptr ADJUST_CLINE_COM_XEOB ; Jump if so
ADJUST_CLINE_COM_READFILE:
	 mov	 ebx,edi	; Get a sane value for EBX
	 add	 ebx,edx	; Add 2 back in if going backwards
; See if we can read more of the file in
	 call	 ADJUST_CLINE_READFILE ; Return with CF=1 if EOF
	 jnc	 short ADJUST_CLINE_COM_XEOB ; Join common code if no failure

	 mov	 edi,ebx	; Truncate

	 or	 edx,edx	; Are we moving backward?
	 jz	 short @F	; Jump if not

	 cmp	 FBROWS_FPTR,0	; Are we already at the beginning of file?
	 je	 near ptr ADJUST_CLINE_COM_EXIT ; Exit if so
@@:
	 inc	 esi		; Add line back in
	 jmp	 near ptr ADJUST_CLINE_COM_EXIT ; Join common exit code

ADJUST_CLINE_COM_XEOB:
	 mov	 ecx,edi	; Get offset within DGROUP
	 sub	 ecx,FBROWS_BUFP ; Convert to offset within *FBROWS_BUFP
	 sub	 ecx,FBROWS_FLEN ; Get -difference to end of buffer
	 neg	 ecx		; Get |difference|
	 or	 edx,edx	; Are we going forward?
	 jz	 short @F	; Jump if so

	 sub	 ecx,FBROWS_FLEN ; Get -difference to beginning of buffer
	 neg	 ecx		; Get |difference|
@@:
	 mov	 ebx,edi	; Save start of line in case we must back off
	 mov	 al,LF		; Character to look for
	 cmp	 ecx,0ffh	; Are we in range for breakpoint?
	 ja	 short @F	; Jump if not

	 SELFBREAK ADJUST_CLINE_COM,80h ; Break if SELFDBG&0x80
@@:
   repne scas	 DGROUP:[edi].LO ; Look for end of previous/end of current line

	 jecxz	 short ADJUST_CLINE_COM_EOF ; End of buffer data
;;;;;;;  jne	 short ADJUST_CLINE_COM_EOF ; End of buffer data

	 add	 edi,edx	; If scanning forward, EDX=0 because EDI already
				; points to the character after LF.  Otherwise,
				; EDI==>character before LF preceding new COFF.
	 or	 esi,esi	; Have we processed all lines?
	 jz	 short ADJUST_CLINE_COM_EXIT ; Jump if so

	 jmp	 near ptr ADJUST_CLINE_COM_NEXT ; Process next

ADJUST_CLINE_COM_EOF:
	 jne	 short @F	; Jump if end of buffer

; If ZF=1 and DX!=0 (scanning backwards), we hit the beginning of the buffer
; with the first two characters CR LF (a blank line).	If DX==0 (scanning
; forwards) the very last character in the buffer was LF.  In either case,
; we need to count the extra line by adjusting SI.
;;;;;;;  or	 edx,edx	; Are we moving backwards?
;;;;;;;  jz	 short ADJUST_CLINE_COM_EOF_FORW ; Jump if not
;;;;;;;
	 dec	 esi		; Count an extra line
	 jz	 ADJUST_CLINE_COM_EXIT ; Exit if we're done
@@:
	 or	 edx,edx	; Are we moving backwards?
	 jz	 short ADJUST_CLINE_COM_EOF_FORW ; Jump if not

	 cmp	 FBROWS_FPTR,0	; Are we already at the beginning of file?
	 je	 short ADJUST_CLINE_COM_EXIT ; Jump if so

ADJUST_CLINE_COM_EOF_FORW:
	 call	 ADJUST_CLINE_READFILE ; Try to read more
	 jc	 short @F	; Jump if we failed

	 or	 edx,edx	; Are we moving backwards?
	 jnz	 near ptr ADJUST_CLINE_COM_NEXT ; Jump if so (we were already
				; on a line boundary)

	 or	 esi,esi	; Is it the last line?
	 jz	 short ADJUST_CLINE_COM_EXIT ; If so, we're done

	 jmp	 near ptr ADJUST_CLINE_COM_NEXT2 ; Keep going if we succeeded

@@:
	 inc	 esi		; Discard line we just counted in
	 mov	 edi,ebx	; Back off COFF to beginning of line (or
				; next line if moving backward)
ADJUST_CLINE_COM_EXIT:
	 REGREST <ecx,ebx,eax>	; Restore

	 popfd			; Restore DF

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ADJUST_CLINE_COM endp		; End ADJUST_CLINE_COM procedure
	 NPPROC  ADJUST_CLINE_READFILE -- Read from file being browsed
	 assume  ds:DGROUP,es:nothing,ss:nothing,fs:nothing,gs:nothing
COMMENT|

Called from ADJUST_CLINE_COM.

On entry:
DGROUP:EBX =	Start of beginning of current line
EDX	  =	0 for forward direction, !0 for backward
DGROUP:EDI =	Current offset
SS:EBP	  ==>	FORW_STR
SP == ESP
FBROWS_SOFF =	Offset of beginning of current screen.	Note that this
		value will be used as the base of the read if DGROUP:EBX
		(converted to a file offset) - FBROWS_SOFF > FBROWS_BUFLEN/2.
		This allows us to handle the case where an SLINE adjustment
		with a potentially long difference is made; in such a case,
		we would chase our tail if we continually read starting
		from SOFF.  We want to use SOFF where we have calculated
		SLINE and SOFF, but are trying to ensure that we have
		valid data (if possible) all the way to the end of the
		screen.

On exit:
DGROUP:EBX =	New start of line (if operation succeeded)
DGROUP:EDI =	New location		   "
CF=0		Operation OK
  =1		Failed (caller should reset DI; original BX,DI preserved)
FBROWS_FPTR	Updated to reflect new file offset

|

READFILE_STR	 struc
READFILE_FPTR	 dd	?	; New file pointer
READFILE_FH	 dw	?	; File handle if opened successfully
READFILE_NEWEDI  dd	?	; New EDI value
READFILE_NEWEBX  dd	?	; New EBX value
READFILE_OLDEDI  dd	?	; Old EDI value
READFILE_OLDEBX  dd	?	; Old EBX value
READFILE_DIR	 dw	?	; Direction; !0 for backward direction
READFILE_FLEN	 dd	?	; New FBROWS_FLEN value
READFILE_STR	 ends

READFILE_EBP	 equ	[size READFILE_STR].EDD ; Saved EBP for FORW_STR

READFILE_DOSCALL macro	@FNUM
	 mov	 ah,@FNUM	; DOS function number
	 push	 ebp		; Save local variable pointer
	 mov	 ebp,[ebp].READFILE_EBP ; Restore FORW_STR pointer
	 mov	 ah,@FNUM	; DOS function number
	 FINTD	 PL0_INT21	; Call PL0 DPMI services
	 pop	 ebp		; Restore local variable pointer
	 endm

	 REGSAVE <eax,ecx,edx,es> ; Save

	 push	 ds		; Get DGROUP selector
	 pop	 es		; Address DGROUP
	 assume  es:DGROUP	; Tell the assembler

	 push	 ebp		; Save
	 lea	 esp,[esp-(size READFILE_STR)] ; Allocate local storage
	 mov	 ebp,esp	; Address stack

	 mov	 [ebp].READFILE_FH,-1 ; Initialize file handle (unopened)
	 mov	 [ebp].READFILE_DIR,dx ; Save direction flag
	 mov	 [ebp].READFILE_OLDEBX,ebx ; Save EBX on entry
	 mov	 [ebp].READFILE_OLDEDI,edi ; Save EDI on entry
	 mov	 eax,FBROWS_FLEN ; Get original FLEN
	 mov	 [ebp].READFILE_FLEN,eax ; Save working copy

	 mov	 eax,ebx	; Get DGROUP offset of start of line
	 sub	 eax,FBROWS_BUFP ; Subtract offset within DGROUP
	 add	 eax,FBROWS_FPTR ; Add file offset

	 mov	 [ebp].READFILE_NEWEBX,ebx ; Save EBX
	 mov	 [ebp].READFILE_NEWEDI,edi ; Save EDI

	 mov	 ebx,FBROWS_BUFLEN ; Get buffer length for comparison
	 shr	 ebx,1		; For comparison with FBROWS_BUFLEN/2

	 push	 eax		; Save result
	 sub	 eax,FBROWS_SOFF ; Get difference between BOL and BOS
	 jns	 short @F	; Jump if positive

	 neg	 eax		; Get absolute value
@@:
	 cmp	 eax,ebx	; Is difference greater (UNSIGNED) than buffer
				; length / 2?  If result was negative, we
				; want to use beginning of line.
	 pop	 eax		; Restore result

	 ja	 short @F	; Jump if so (use beginning of line)

	 mov	 eax,FBROWS_SOFF ; Use start of screen
@@:
	 or	 dx,dx		; Are we moving forward?
	 jz	 short READFILE_SETFPTR ; Jump if so

	 mov	 eax,FBROWS_FPTR ; Get current start of buffer
	 or	 eax,eax	; Izit already 0?
	 jz	 near ptr READFILE_ERR ; Jump if not

	 sub	 eax,ebx	; Subtract FBROWS_BUFLEN/2
	 jns	 short READFILE_SETFPTR ; If not negative, continue

	 sub	 eax,eax	; Truncate to 0

; EAX contains new FPTR value
READFILE_SETFPTR:
	 mov	 [ebp].READFILE_FPTR,eax ; Save as new file offset

	 call	 DOS_AVAIL	; Are DOS services via DPMI PL0 available?
	 jc	 near ptr READFILE_ERR ; Jump if not

	 lea	 edx,FBROWS_NAME ; Name of file to open
	 mov	 al,0		; Read-only, sharing compatibility mode
	 READFILE_DOSCALL @OPENF2 ; Open file at DS:DX
	 jc	 near ptr READFILE_ERR ; Jump if open failed

	 mov	 [ebp].READFILE_FH,ax ; Save file handle
	 mov	 bx,ax		; Handle for seek operation
	 movzx	 ecx,[ebp].READFILE_FPTR.EHI ; Get high word of seek offset
	 movzx	 edx,[ebp].READFILE_FPTR.ELO ; Get low word for seek
	 mov	 al,0		; Seek from beginning of file
	 READFILE_DOSCALL @MOVFP2 ; Seek on file BX to CX:DX
	 jc	 near ptr READFILE_ERR ; Jump if seek failed

; Now we are ready to re-read the buffer, starting at the new
; file pointer location.  There may be a small amount of overlap.
	 mov	 edx,FBROWS_BUFP ; Get start of buffer
	 mov	 ecx,FBROWS_BUFLEN ; Get length of buffer
	 mov	 bx,[ebp].READFILE_FH ; Get file handle
	 xor	 eax,eax	; Zero to sue as dword
	 READFILE_DOSCALL @READF2 ; Read from file BX into DS|eDX for eCX bytes
	 jc	 near ptr READFILE_ERR ; Jump if read failed

	 or	 eax,eax	; If at EOF, cut out
	 jz	 near ptr READFILE_ERR ; Tell'em we can't read any more

	 mov	 [ebp].READFILE_FLEN.ELO,ax ; Bytes read

	 mov	 ebx,FBROWS_FPTR ; Get old file offset
	 mov	 eax,FBROWS_BUFP ; Get buffer base

	 push	 eax		; Save

	 sub	 eax,[ebp].READFILE_NEWEBX ; Get -(beginning of line)
	 neg	 eax		; Beginning of line from start of buffer
	 add	 eax,ebx	; Convert to offset within file
	 sub	 eax,[ebp].READFILE_FPTR ; Get new offset from start of buffer
	 add	 eax,[esp].EDD	; Get offset within buffer
	 mov	 [ebp].READFILE_NEWEBX,eax ; Save new re-normalized EBX

	 mov	 eax,[ebp].READFILE_NEWEDI ; Get old DI
	 sub	 eax,[esp].EDD	; Get offset within buffer
	 add	 eax,ebx	; Convert to offset within file
	 sub	 eax,[ebp].READFILE_FPTR ; Get new offset from start of buffer

	 pop	 [ebp].READFILE_NEWEDI ; Get old buffer start
	 add	 [ebp].READFILE_NEWEDI,eax ; New renormalized DI (after read)

	 cmp	 [ebp].READFILE_DIR,0 ; Are we moving forward?
	 je	 short READFILE_FORWARD ; Jump if so

; When we go back, we need to look ahead for the beginning of a line
; if not already at the BOF.  This value is saved as the new FPTR,
; and the difference is subtracted from READFILE_FLEN.
	 cmp	 [ebp].READFILE_FPTR,0 ; Are we already at the beginning of file?
	 je	 short READFILE_FORWARD ; Jump if so (no adjustment needed)

	 mov	 edi,FBROWS_BUFP ; Start from beginning
	 mov	 ebx,edi	; Save start offset
	 mov	 al,LF		; What to look for
	 mov	 ecx,[ebp].READFILE_FLEN ; Maximum bytes to scan

	 pushfd 		; Save old DF (should be set)
	 cld			; Scan forward
   repne scas	 DGROUP:[edi].LO ; DGROUP:EDI ==> beginning of next line
	 popfd			; Restore old DF
	 jecxz	 READFILE_FORWARD ; If not found, don't try to adjust anything

; Now we must move the remainder of the buffer (count in CX)
	 sub	 ebx,edi	; Get -(new offset - old offset)
	 neg	 ebx		; Difference in bytes
	 sub	 [ebp].READFILE_FLEN,ebx ; Adjust bytes read

	 push	 esi		; Save for a moment

	 mov	 esi,edi	; Source
	 mov	 ebx,FBROWS_BUFP ; Destination
	 sub	 edi,ebx	; Get offset from FPTR
	 add	 [ebp].READFILE_FPTR,edi ; Adjust FPTR
	 sub	 [ebp].READFILE_NEWEBX,edi ; Adjust BOL pointer
	 sub	 [ebp].READFILE_NEWEDI,edi ; Adjust COFF pointer
	 mov	 edi,ebx	; Restore destination pointer

	 pushfd 		; Save DF
	 cld			; Move forward
S32  rep movs	 <DGROUP:[edi].LO,DGROUP:[esi].LO> ; Move buffer down
	 popfd			; Restore DF

	 pop	 esi		; Restore
READFILE_FORWARD:
	 mov	 eax,[ebp].READFILE_FPTR ; Get new (adjusted) file pointer
	 cmp	 eax,FBROWS_FPTR ; If no change, we can't go further
	 je	 short READFILE_ERR ; Return failure

	 mov	 FBROWS_FPTR,eax ; Save it for real
	 mov	 eax,[ebp].READFILE_FLEN ; Get new FLEN
	 mov	 FBROWS_FLEN,eax ; Save as new buffer length

	 clc			; Indicate success
	 jmp	 short READFILE_EXIT ; Join common exit

READFILE_ERR:
	 mov	 ebx,[ebp].READFILE_OLDEBX ; Get old EBX
	 mov	 [ebp].READFILE_NEWEBX,ebx ; Overwrite new value
	 mov	 edi,[ebp].READFILE_OLDEDI ; Get old EDI
	 mov	 [ebp].READFILE_NEWEDI,edi ; Overwrite new value

	 stc			; Indicate failure, EOF or BOF
READFILE_EXIT:
	 pushfd 		; Save result flags

	 mov	 bx,[ebp].READFILE_FH ; Get file handle
	 cmp	 bx,-1		; Izit valid?
	 je	 short @F	; Jump if not

	 READFILE_DOSCALL @CLOSF2 ; Close file handle in BX
				; (ignore result)
@@:
	 popfd			; Get flags (CF significant)

	 mov	 ebx,[ebp].READFILE_NEWEBX ; Get old (new) BX (high word clear)
	 mov	 edi,[ebp].READFILE_NEWEDI ; Get old (new) DI

	 lea	 esp,[esp+(size READFILE_STR)] ; Remove from stack

	 pop	 ebp		; Restore BP

	 REGREST <es,edx,ecx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ADJUST_CLINE_READFILE endp	; End ADJUST_CLINE_READFILE procedure

PROG	 ends			; End PROG segment


NCODE	 segment use16 para public 'ncode' ; Start NCODE segment
	 assume  cs:NGROUP

	 PATH_COM_MAC U16_	; Define for NGROUP

NCODE	 ends			; End NCODE segment

	 MEND			; End SWAT_FBR module
