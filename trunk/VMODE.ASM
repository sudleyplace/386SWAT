;' $Header:   P:/PVCS/386SWAT/VMODE.ASV   1.1   23 Jun 1992 14:54:32   DAVID  $
	 title	 VMODE -- Video Mode Set
	 page	 58,122
	 name	 VMODE
	 include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1989-92 Qualitas, Inc.  All rights reserved.

Environment:  IBM PC, tested under DOS 3.30.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, byte-aligned, stack,  class 'prog'
	       Program segment CODE,  byte-aligned, public, class 'prog'
	       Data    segment DATA,  byte-aligned, public, class 'data'
	       Tail    segment DTAIL, byte-aligned, public, class 'data'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, April, 1989.

Modifications by:  None.

|

.186
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include KEYCALL.INC
	 include VIDCALL.INC
	 include ASCII.INC
	 include PTR.INC
.list

PGROUP	 group	 STACK,CODE,DATA,DTAIL


; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	 segment byte stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment


FVM_STR  struc

FVM_SIZE dd	 ?		; Size of this entry in bytes
FVM_MODE db	 ?		; This video mode
FVM_CMD  db	 ?		; Command:  @SETMOD = mode,
				;	    @SETTYP = cursor type
FVM_CUR  dw	 ?		; Cursor type if @SETTYP

FVM_STR  ends

@FVM_EOM equ	 -1		; End of video modes marker


IO_STR	 struc

IO_PORT  dw	 ?		; I/O port #
IO_VAL	 dw	 ?		; Output value (if any)
IO_FLAG  db	 ?		; I/O flags (see @IO_ equates below)

IO_STR	 ends

@IO_INP  equ	 80h		; Set = input,	  Clr = output
@IO_WORD equ	 40h		; Set = word I/O, Clr = byte I/O


DATA	 segment byte public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 public  FILENAME
FILENAME db	 '386SWAT.VID',0

	 public  LCLSTK,LCLSTKZ
LCLSTK	 db	 100h dup (?)	; Local stack
LCLSTKZ  dw	 0		; Top of stack

DATA	 ends			; End DATA segment


; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

DTAIL	 segment byte public 'data' ; Start DTAIL segment
	 assume  ds:PGROUP

	 public  ZTAIL
ZTAIL	 label	 byte

DTAIL	 ends			; End DTAIL segment


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP
.xlist
	 include PSP.INC	; Define & skip over PSP area for .COM program
.list
	 NPPROC  VMODE -- Video Mode Set
	 assume  ds:PGROUP,es:PGROUP,ss:nothing

	 lea	 sp,LCLSTKZ	; Switch to local stack

; Open and read in the file

	 mov	 al,0		; Code for read-only
	 DOSCALL @OPENF2,FILENAME ; Open it
	 jc	 short VMODE_ERR ; Jump if error

	 mov	 bx,ax		; Copy to handle register
	 mov	 cx,-1		; Read it all in
	 DOSCALL @READF2,ZTAIL	; Read it
	 pushf			; Save flags
	 DOSCALL @CLOSF2	; Close it up
	 popf			; Restore flags
	 jc	 short VMODE_ERR ; Jump if error

;;;;;;;; mov	 al,10h 	; Hires video mode
;;;;;;;; VIDCALL @SETMOD	; Set video mode

	 mov	 ah,@SETMOD	; Set display mode command
	 mov	 al,03h 	; Color mode
	 call	 REPLAY_VMOD	; Play it back again

	 mov	 ax,0B800h	; Get screen segment base
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,1E30h	; Smear this character/attribute
	 xor	 di,di		; ES:DI ==> display base
	 mov	 cx,80*2*10	; For 10 lines worth
     rep stosw			; Smear it

	 KEYCALL @GETKEY	; Pause for a keystroke
VMODE_ERR:
	 ret			; Return to DOS

	 assume  ds:nothing,es:nothing,ss:nothing

VMODE	 endp			; End VMODE procedure
	 NPPROC  REPLAY_VMOD -- Replay Video Mode
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Replay the video mode in AL.

On entry:

AH	 =	 command (@SETMOD or @SETTYP)
AL	 =	 video mode
CX	 =	 cursor type (if AH = @SETTYP)

|

	 REGSAVE <ax,bx,cx,dx,si> ; Save registers

	 lea	 si,ZTAIL	; DS:SI ==> video tables
REPLAY_VMOD1:
	 mov	 bl,PGROUP:[si].FVM_CMD ; Get this entry's command

	 cmp	 bl,@FVM_EOM	; Check for end-of-the-line
	 je	 short REPLAY_VMOD_ERR ; Jump if so

	 cmp	 bl,ah		; Izit the same command?
	 jne	 short REPLAY_VMOD2 ; Jump if not

	 cmp	 al,PGROUP:[si].FVM_MODE ; Izit our mode?
	 jne	 short REPLAY_VMOD2 ; Jump if not

	 cmp	 ah,@SETMOD	; Izit set mode (no cursor type check)?
	 je	 short REPLAY_VMOD_FOUND ; Jump if so

	 cmp	 cx,PGROUP:[si].FVM_CUR ; Izit same cursor type?
	 je	 short REPLAY_VMOD_FOUND ; Jump if so
REPLAY_VMOD2:
	 add	 si,PGROUP:[si].FVM_SIZE.ELO ; Skip to next entry

	 jmp	 short REPLAY_VMOD1 ; Go around again

; DS:SI ==> current video mode/cursor type

REPLAY_VMOD_FOUND:
	 mov	 ax,PGROUP:[si].FVM_SIZE.ELO ; Get size of this entry
	 add	 si,size FVM_STR ; Skip over header

; Convert from size in bytes to # entries

	 sub	 ax,size FVM_STR ; Less size of header
	 xor	 dx,dx		; Zero to use as dword
	 mov	 bx,size IO_STR ; Get size of IODATA structure
	 div	 bx		; Convert from bytes to # entries
	 mov	 cx,ax		; Copy to count register

	 pushf			; Save flags
	 cli			; Disallow interrupts
REPLAY_VMOD_NEXT:
	 mov	 dx,PGROUP:[si].IO_PORT ; Get the I/O port #
	 mov	 al,PGROUP:[si].IO_FLAG ; Get flags
	 and	 al,@IO_INP or @IO_WORD ; Isolate input/output and word/byte flags

	 cmp	 al,0			; Izit byte output?
	 je	 short REPLAY_VMOD_OUTB ; Jump if so

	 cmp	 al,	       @IO_WORD ; Izit word output?
	 je	 short REPLAY_VMOD_OUTW ; Jump if so

	 cmp	 al,@IO_INP		; Izit byte input?
	 je	 short REPLAY_VMOD_INB ; Jump if so

	 cmp	 al,@IO_INP or @IO_WORD ; Izit word input?
	 je	 short REPLAY_VMOD_INW ; Jump if so

	 jmp	 short REPLAY_VMOD_ERR ; Jump if not found

REPLAY_VMOD_INW:
	 in	 ax,dx		; Perform word input

	 jmp	 short REPLAY_VMOD_LOOP ; Join common loop code

REPLAY_VMOD_INB:
	 cmp	 dx,03B4h	; Izit mono status register?
	 je	 short REPLAY_VMOD_VR ; Yes, wait for vertical retrace

	 cmp	 dx,03D4h	; Izit color status register?
	 je	 short REPLAY_VMOD_VR ; Yes, wait for vertical retrace

	 in	 al,dx		; Perform byte input

	 jmp	 short REPLAY_VMOD_LOOP ; Join common loop code

@DISP_INACT equ  0001b		; Bit to test for 6845 display inactive
@VERT_SYNC  equ  1000b		; Bit to test for 6845 vertical retrace active

REPLAY_VMOD_VR:
	 in	 al,dx		; Perform byte input

	 test	 al,@VERT_SYNC	; Izit in vertical retrace?
	 jz	 short REPLAY_VMOD_VR ; No, wait until it is

	 jmp	 short REPLAY_VMOD_LOOP ; Join common loop code


REPLAY_VMOD_OUTW:
	 mov	 ax,PGROUP:[si].IO_VAL ; Get the output word
	 out	 dx,ax		; Perform word output

	 jmp	 short REPLAY_VMOD_LOOP ; Join common loop code

REPLAY_VMOD_OUTB:
	 mov	 al,PGROUP:[si].IO_VAL.LO ; Get the output byte
	 out	 dx,al		; Perform byte output

	 jmp	 short REPLAY_VMOD_LOOP ; Join common loop code

REPLAY_VMOD_LOOP:
	 add	 si,size IO_STR ; Skip to next entry

	 loop	 REPLAY_VMOD_NEXT ; Jump if more I/O operations

	 popf			; Restore flags

	 clc			; Indicate we found it

	 jmp	 short REPLAY_VMOD_EXIT ; Join common exit code

REPLAY_VMOD_ERR:
	 stc			; Indicate we didn't find the mode
REPLAY_VMOD_EXIT:
	 REGREST <si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

REPLAY_VMOD endp		; End REPLAY_VMOD procedure

CODE	 ends			; End CODE segment

	 MEND	 VMODE		; End VMODE module
