;' $Header:   P:/PVCS/386SWAT/SWAT_HST.ASV   1.3   10 Aug 1998 11:01:04   BOB  $
	title	SWAT_HST -- 386SWAT Command History Routines
	page	58,122
	name	SWAT_HST

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, June, 1997.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include ASCII.INC
	include 386.INC
	include PTR.INC
	include ALLMEM.INC
	include KEYCODE.INC

	include SWAT_COM.INC
	include SWAT_SEG.INC
.list

DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	public	@SWAT_HST_DATA16
@SWAT_HST_DATA16 label byte	; Mark module start in .MAP file

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	CMD_LINE:byte
	extrn	HSTAATTR:byte
	extrn	HSTBATTR:byte

	public	@CMDHIST_MIN,@CMDHIST_DEF
@CMDHIST_MIN equ 81
@CMDHIST_DEF equ 1024

	public	CMDHIST_LEN,CMDHIST_OFF,CMDHIST_END
CMDHIST_LEN dd	@CMDHIST_DEF	; Length of command history buffer
CMDHIST_OFF dd	?		; Offset in DGROUP of command history buffer
CMDHIST_END dd	?		; Offset in DGROUP of end of command hist buffer
				; = CMDHIST_OFF + CMDHIST_LEN

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	@SWAT_HST_DATA
@SWAT_HST_DATA label byte	; Mark module start in .MAP file

;;;;;;; extrn	REENTRY:word
	extrn	CMDHIGH:dword

	public	CMDHIST_NXT,CMDHIST_CUR
CMDHIST_NXT dd	?		; Offset in DGROUP of next command
CMDHIST_CUR dd	?		; ...		      cursor

COMMENT|

Commands are stored end-to-end as ASCIIZ strings in a ring buffer
whose starting address is CMDHIST_OFF and whose length is CMDHIST_LEN.

Commands do not span the boundaries -- that is, the end of the command
(terminating zero) is always to the right of its start.

The first command is stored at the start of the buffer, the second
command is stored to its right, etc.  Thus, to retrieve the previous
command, look to the left.  To retrieve the next command, look to the
right.

The buffer is initially all zero, and at all times consists of, from
left to right, zero or more ASCIIZ commands followed by zeros filling
out the tail of the buffer to CMDHIST_END.

When a command is placed into the buffer, it overwrites the (old)
command at CMDHIST_NXT.  If the new command does not exactly fit, the
next older command is deleted as well.	A command is deleted by moving
down (to the left) the commands to its right.  In any case,
CMDHIST_NXT is updated to point to the end of the new command.

If an incoming command does not fit into the buffer, the (shorter)
command at the end of the buffer is deleted, and the new command is
placed at the start of the buffer.

When the command line is changed (typed on), the line becomes a new
command, and when complete (CR typed) it is appended to the end of the
buffer, and CMDHIST_NXT is updated to point past the (new) command.
If a command is retrieved and executed as is (unchanged), the command
is not appended to the buffer and CMDHIST_NXT is not updated, however
CMDHIST_CUR is updated.

|

	public	HSTIND,HSTLIN_NROW
HSTIND	dd	?	; Starting index (origin-0, where 0 = top)
HSTLIN_NROW dd	?	; Total # rows

@HST_SCOL equ	0	; Starting column #
@HST_NROW equ	1	; # rows
@HST_NCOL equ	20	; # cols

	public	W_HST
W_HST	W_STR	<?, @HST_SCOL, @HST_NROW, @HST_NCOL>

	public	HSTLIN_SROW
HSTLIN_SROW dd	?	; Starting row #

@HSTLIN_SCOL equ @HST_SCOL
@HSTLIN_NROW equ 1
@HSTLIN_NCOL equ @HST_NCOL

	public	W_HSTLIN
W_HSTLIN W_STR	<?, @HSTLIN_SCOL, @HSTLIN_NROW, @HSTLIN_NCOL>

	public	LCLHST0,LCLHST
LCLHST0 db	?,' '           ; Selection letter
LCLHST	db	@HST_NCOL dup (0) ; Local buffer

DATA	ends			; End DATA segment


KEYSEG	segment use32 word public 'data' ; Start KEYSEG segment
	assume	ds:DGROUP

	public	@SWAT_HST_KEYSEG
@SWAT_HST_KEYSEG label byte	; Mark module start in .MAP file

	public	HSTVAL
HSTVAL	label	word		; First word in the table

KEYSEG	ends			; End KEYSEG segment


ACTSEG	segment use32 dword public 'data' ; Start ACTSEG segment
	assume	ds:DGROUP

	public	@SWAT_HST_ACTSEG
@SWAT_HST_ACTSEG label byte	; Mark module start in .MAP file

	public	HSTACT
HSTACT	label	dword		; First action in the table

ACTSEG	ends			; End ACTSEG segment


	KSTMAC	ESC	 , HST_ESC
	KSTMAC	UP	 , HST_UP
	KSTMAC	XUP	 , HST_UP
	KSTMAC	SHF_UP	 , HST_UP
	KSTMAC	ALT_COMMA, HST_UP
	KSTMAC	DN	 , HST_DN
	KSTMAC	XDN	 , HST_DN
	KSTMAC	SHF_DN	 , HST_DN
	KSTMAC	ALT_PERIOD,HST_DN
	KSTMAC	DEL	 , HST_DEL
	KSTMAC	CR	 , HST_CR
	KSTMAC	PADENTER , HST_CR


KEYSEG	segment use32 word public 'data' ; Start KEYSEG segment
	assume	ds:DGROUP

NHSTVAL equ	($-HSTVAL)/(type HSTVAL)

KEYSEG	ends			; End KEYSEG segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP

	public	@SWAT_HST_PROG
@SWAT_HST_PROG: 		; Mark module start in .MAP file

	extrn	StrLen:near
	extrn	StrNCpy:near
	extrn	CLEAR_CMDLINE:near
	extrn	DISP_CMDLINE:near
	extrn	WPUT_CSA:near
	extrn	WPUT_SA:near
	extrn	GETKEY:near
	extrn	U32_LOWERCASE:near
	extrn	SWATTER_DISP:near

	NPPROC	CMD_DELETE -- Delete A Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Delete a command

|

CMDDEL_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
CMDDEL_OFF dd	?		; Offset in DGROUP of command to delete

CMDDEL_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	pushad			; Save registers

	mov	edi,[ebp].CMDDEL_OFF ; Get offset in DGROUP of command to delete
	mov	al,0		; Terminating zero

	cmp	al,DGROUP:[edi] ; Izit deleted already?
	je	short CMD_DELETE_EXIT ; Jump if so

; Calculate length of command we're deleting so we
; can adjust pointers

	push	eax		; Save for a moment

	push	ds		; Pass segment
	push	edi		; ...  offset
	call	StrLen		; Get length of command line (excluding
				; terminating zero)
	inc	eax		; Include terminating zero
	mov	ecx,eax 	; Copy to unused register

	pop	eax		; Restore

; If the cursor is above the current point, move it down by the
; length of the command we're deleting

	cmp	CMDHIST_CUR,edi ; Izit above current point?
	jbe	short @F	; Jump if not

	sub	CMDHIST_CUR,ecx ; Move it down
@@:

; If the next command point is above the current point, move it down by the
; length of the command we're deleting

	cmp	CMDHIST_NXT,edi ; Izit above current point?
	jbe	short @F	; Jump if not

	sub	CMDHIST_NXT,ecx ; Move it down
@@:
	mov	ecx,CMDHIST_END ; Get end of buffer
	sub	ecx,edi 	; Less current position
  repne scas	DGROUP:[edi].LO ; Search for next terminating zero

	mov	esi,[ebp].CMDDEL_OFF ; Get offset in DGROUP of command to delete
	xchg	esi,edi 	; Swap for MOVS
    rep movs	DGROUP:[edi].LO,DGROUP:[esi].LO ; Move commands down to delete

; Zero the end of the buffer

	mov	ecx,CMDHIST_END ; Get end of buffer
	sub	ecx,edi 	; Less current position
    rep stos	DGROUP:[edi].LO ; Zero it
CMD_DELETE_EXIT:
	popad			; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_DELETE endp 		; End CMD_DELETE procedure
	NPPROC	CMD_APPEND -- Append A New Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Append a new command to the buffer

|

	pushad			; Save registers

;;;;;;; cmp	REENTRY,1	; Check re-entry level
;;;;;;; jne	short CMD_APPEND_EXIT ; Jump if we're re-entering
;;;;;;;
	mov	edi,CMDHIST_NXT ; Get offset in DGROUP of next command
	lea	esi,CMD_LINE	; DS:ESI ==> command line

	push	ds		; Pass segment
	push	esi		; ...  offset
	call	StrLen		; Get length of command line (excluding
				; terminating zero)
	mov	ecx,eax 	; Copy to count register
	jecxz	CMD_APPEND_EXIT ; Jump if it's empty
	lea	eax,[eax+edi+1] ; Add to get next byte

	cmp	eax,CMDHIST_END ; Duzit fit?
	jbe	short @F	; Jump if so

	push	edi		; Pass offset
	call	CMD_DELETE	; Delete a command

	mov	edi,CMDHIST_OFF ; Get start of buffer
@@:
    rep movs	DGROUP:[edi].LO,CMD_LINE[esi] ; Copy to ring buffer

	mov	al,0		; Terminating zero

	cmp	al,DGROUP:[edi] ; Duzit fit exactly?
	stos	DGROUP:[edi].LO ; Save in buffer
	je	short @F	; Jump if so

	push	edi		; Pass offset
	call	CMD_DELETE	; Delete a command
@@:
	mov	CMDHIST_NXT,edi ; Point to next command
	mov	CMDHIST_CUR,edi ; ...	   cursor
CMD_APPEND_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_APPEND endp 		; End CMD_APPEND procedure
	NPPROC	CMD_GET_PREV -- Get Address of Previous Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Get address of previous command

On exit:

EAX	==>	previous command
ZF	=	0 if found
	=	1 if not

|

CMDGETP_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
CMDGETP_OFF dd	?		; Offset in DGROUP of cursor

CMDGETP_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ecx,edi>	; Save registers

	mov	edi,[ebp].CMDGETP_OFF ; Get offset in DGROUP of cursor
	dec	edi		; Backup to preceding terminating zero

	cmp	edi,CMDHIST_OFF ; Did it wrap?
	jae	short @F	; Jump if not

	mov	edi,CMDHIST_END ; Point to the end
	dec	edi		; Back up to within the buffer
@@:
	mov	ecx,edi 	; Copy current position
	sub	ecx,CMDHIST_OFF ; Less starting position
	inc	ecx		; Plus one to scan current position
	mov	al,0		; Terminating zero

; Skip over terminating zero(s)

	std			; String ops backwards
   repe scas	DGROUP:[edi].LO ; Skip over terminating zero(s)
	cld			; String ops forwards
	je	short CMD_GET_PREV_EXIT ; Jump if only zeros (note ZF=1)

; Backup to the previous command

	std			; String ops backwards
  repne scas	DGROUP:[edi].LO ; Skip to the next terminating zero
	cld			; String ops forwards
	jne	short @F	; Jump if only non-zeros

	inc	edi		; Skip back to terminating zero
@@:
	inc	edi		; Skip to start of command
				; Note ZF=0
	mov	eax,edi 	; Copy to output register
CMD_GET_PREV_EXIT:
	REGREST <edi,ecx>	; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_GET_PREV endp		; End CMD_GET_PREV procedure
	NPPROC	CMD_RETR_PREV -- Retrieve Previous Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Retrieve previous command

|

	pushad			; Save registers

;;;;;;; cmp	REENTRY,1	; Check re-entry level
;;;;;;; jne	short @F	; Jump if we're re-entering
;;;;;;;
;;;;;;; int	01h		; Call ourselves
@@:
	push	CMDHIST_CUR	; Starting point
	call	CMD_GET_PREV	; Return with EAX ==> previous command
	je	short CMD_RETR_PREV_EXIT ; Jump if not found

	mov	esi,eax 	; Copy to source register

	push	ds		; Pass segment
	push	esi		; ...  offset
	call	StrLen		; Get length of command line (excluding
				; terminating zero)
; If the command is empty, this must be the start of the buffer
; because we don't allow empty commands to be appended.

	and	eax,eax 	; Izit empty?
	jz	short CMD_RETR_PREV_EXIT ; Jump if so

	call	CLEAR_CMDLINE	; Clear the command line

	mov	CMDHIGH,eax	; Save as highwater mark length
	inc	eax		; Count in the terminating zero
	mov	ecx,eax 	; Copy to count register

	lea	edi,CMD_LINE	; DS:EDI ==> command line

; Update the cursor

	mov	CMDHIST_CUR,esi ; Save as new cursor
    rep movs	CMD_LINE[edi],DGROUP:[esi].LO ; Copy to command line

; Display the command line

	call	DISP_CMDLINE	; Display the command line
CMD_RETR_PREV_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_RETR_PREV endp		; End CMD_RETR_PREV procedure
	NPPROC	CMD_GET_NEXT -- Get Address of Next Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Get address of next command

On exit:

EAX	==>	next command
ZF	=	0 if found
	=	1 if not

|

CMDGETN_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
CMDGETN_OFF dd	?		; Offset in DGROUP of cursor

CMDGETN_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	mov	eax,[ebp].CMDGETN_OFF ; Get offset in DGROUP of cursor

	cmp	DGROUP:[eax].LO,0 ; Izit empty?
	jne	short @F	; Jump if not (note ZF=0)

	mov	eax,CMDHIST_OFF ; Start at the beginning

	cmp	DGROUP:[eax].LO,0 ; Izit empty?
				; Return with ZF significant
@@:
	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_GET_NEXT endp		; End CMD_GET_NEXT procedure
	NPPROC	CMD_RETR_NEXT -- Retrieve Next Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Retrieve next command

|

	pushad			; Save registers

	push	CMDHIST_CUR	; Starting point
	call	CMD_GET_NEXT	; Return with EAX ==> next command
	je	short CMD_RETR_NEXT_EXIT ; Jump if not found

	mov	esi,eax 	; Copy to source register

	push	ds		; Pass segment
	push	esi		; ...  offset
	call	StrLen		; Get length of command line (excluding
				; terminating zero)
	call	CLEAR_CMDLINE	; Clear the command line

	mov	CMDHIGH,eax	; Save as highwater mark length
	inc	eax		; Count in the terminating zero
	mov	ecx,eax 	; Copy to count register

	lea	edi,CMD_LINE	; DS:EDI ==> command line
    rep movs	CMD_LINE[edi],DGROUP:[esi].LO ; Copy to command line

; Display the command line

	call	DISP_CMDLINE	; Display the command line

; Update the cursor

	cmp	esi,CMDHIST_END ; Izit at the end?
	jb	short @F	; Jump if not

	mov	esi,CMDHIST_OFF ; Point back to the start
@@:
	mov	CMDHIST_CUR,esi ; Save as new cursor
CMD_RETR_NEXT_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_RETR_NEXT endp		; End CMD_RETR_NEXT procedure
	NPPROC	CMD_DISP_HIST -- Display Command History
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display command history

|

HSTREC	record	$HST_IND:1,$HST_OVF:1

	pushad			; Save registers

;;;;;;; cmp	REENTRY,1	; Check re-entry level
;;;;;;; jne	short @F	; Jump if we're re-entering
;;;;;;;
;;;;;;; int	01h		; Call ourselves
@@:
	mov	dh,0		; Mark as starting anew
CMD_DISP_AGAIN:
	mov	edi,CMDHIST_CUR ; Get offset in DGROUP of cursor

	push	edi		; Pass cursor
	call	CMD_GET_NEXT	; Return with EAX ==> next command
	je	near ptr CMD_DISP_HIST_EXIT ; Jump if not found

	mov	ebx,eax 	; Save for later use
	mov	dl,'A'          ; Initialize selection letter

	mov	ecx,@NROWS-1	; Maximum # rows on which commands displayed
	mov	W_HST.SROW,cx	; Save as starting row #
CMD_DISP_HIST1:
	dec	W_HST.SROW	; Backup one row

	push	edi		; Pass cursor
	call	CMD_GET_PREV	; Return with EAX ==> previous command
;;;;;;; je	short CMD_DISP_HIST_EXIT ; Jump if not found

	mov	edi,eax 	; Copy for later use

; Save selection letter in local buffer

	mov	LCLHST0,dl	; Save it
	inc	dl		; Skip to the next letter

; Copy the command to local buffer

	push	ds		; Pass selector of local buffer
	push	offset ds:LCLHST ; ... offset ...
	push	ds		; ...  selector of command
	push	edi		; ...  offset ...
	push	size LCLHST	; ...  size of local buffer
	call	StrNCpy 	; Copy it, return actual copy length in EAX

; Blank to the end of the local buffer

	REGSAVE <ecx,edi>	; Save for a moment

	mov	ecx,size LCLHST ; Get size of local buffer
	sub	ecx,eax 	; Less amount copied
	lea	edi,LCLHST[eax] ; ES:EDI ==> local buffer
	mov	al,' '          ; Filler
    rep stos	DGROUP:[edi].LO ; Fill it

	REGREST <edi,ecx>	; Restore

	mov	al,HSTAATTR	; Get command history window attr
	push	ax		; Pass as attribute to smear
	push	offset ds:LCLHST0 ; Pass address of local buffer
	push	offset ds:W_HST ; Pass address of window descriptor
	call	WPUT_CSA	; Output the characters, smear attribute

	cmp	edi,ebx 	; Are we back at the cursor?
	loopne	CMD_DISP_HIST1	; Jump if so and more rows to display
	je	short @F	; Jump if no overflow

	or	dh,mask $HST_OVF ; Mark as overflowing
@@:
	mov	HSTLIN_SROW,ecx ; Save as starting row #
	sub	ecx,@NROWS - 1	; Less maximum # rows
	neg	ecx		; Negate to get positive value
	mov	HSTLIN_NROW,ecx ; Save as total # rows

	test	dh,mask $HST_IND ; Are we saving HSTIND?
	jnz	short HST_COM	; Jump if so

	dec	ecx		; Convert from length to index
	mov	HSTIND,ecx	; Save as starting index #
HST_COM:
	mov	eax,HSTLIN_SROW ; Wrap to the start
	add	eax,HSTIND	; Plus current index
	mov	W_HSTLIN.SROW,ax ; Save as new starting row

; Accept keystrokes to select or scroll through the history

HST_NEXT:
	mov	al,HSTBATTR	; Get command history window bar attr
	push	ax		; Pass attribute to smear
	push	offset ds:W_HSTLIN ; Pass address of window descriptor
	call	WPUT_SA 	; Smear attribute

	call	GETKEY		; Wait for keystroke, return in AX

; Check for alphabetic

	push	eax		; Save for a moment
	call	U32_LOWERCASE	; Convert AL to lowercase
	movzx	ebx,al		; Copy to test
	pop	eax		; Restore

	cmp	ebx,'a'         ; Check against lower limit
	jb	short @F	; Jump if too small

	cmp	ebx,'z'         ; Check against upper limit
	jbe	near ptr HST_ALPHA ; Jump if it's alphabetic
@@:

; Check for special keystrokes

	lea	edi,HSTVAL	; ES:EDI ==> valid keys
	mov	ecx,NHSTVAL	; # valid keys
  repne scas	HSTVAL[edi]	; Search for it
	jne	short HST_NEXT	; Jump if not found

	mov	al,HSTAATTR	; Get command history window attr
	push	ax		; Pass attribute to smear
	push	offset ds:W_HSTLIN ; Pass address of window descriptor
	call	WPUT_SA 	; Smear attribute

	sub	edi,(type HSTVAL) + offset es:HSTVAL ; Convert to origin-0
LOG2 LOG2@HSTVAL,<type HSTVAL>
	shr	edi,LOG2@HSTVAL ; Convert to item count

	jmp	HSTACT[edi*(type HSTACT)] ; Take appropriate action


HST_UP:
	dec	HSTIND		; Skip to previous row
	jns	short @F	; Jump if no wrap

	mov	eax,HSTLIN_NROW ; Get total # rows
	dec	eax		; Less one to get last row #
	mov	HSTIND,eax	; Wrap to the end
@@:
	jmp	HST_COM 	; Join common code


HST_DN:
	inc	HSTIND		; Skip to next row

	mov	eax,HSTLIN_NROW ; Get total # rows
	dec	eax		; Less one to get last row #

	cmp	HSTIND,eax	; Izit above the end?
	jbe	short @F	; Jump if no wrap

	mov	HSTIND,0	; Wrap to the start
@@:
	jmp	HST_COM 	; Join common code


HST_DEL:
	mov	ecx,HSTLIN_NROW ; Get total # rows
	sub	ecx,HSTIND	; Subtract to get index # from bottom

	push	CMDHIST_CUR	; Pass offset in DGROUP of cursor
	call	CMD_GET_NEXT	; Return with EAX ==> next command
;;;;;;; je	short CMD_DISP_HIST_EXIT ; Jump if not found
@@:
	push	eax		; Pass cursor
	call	CMD_GET_PREV	; Return with EAX ==> previous command
;;;;;;; je	short CMD_DISP_HIST_EXIT ; Jump if not found

	loop	@B		; Jump if more indices

	push	eax		; Pass offset
	call	CMD_DELETE	; Delete a command

	call	SWATTER_DISP	; Display the screen

; Adjust HSTIND so it's in the same place.
; If there are more commands than we can display (overflow),
; then leave HSTIND along.  Otherwise, decrement HSTIND.

	btr	dx,$HST_OVF+8	; Mark as not overflowing
	jc	short @F	; Jump if it was overflowing

	dec	HSTIND		; Back off by the deleted one
	jns	short @F	; Jump if still valid

	mov	HSTIND,0	; Stay at the top
@@:
	or	dh,mask $HST_IND ; Mark as saving HSTIND

	jmp	CMD_DISP_AGAIN	; Go around again


HST_ALPHA:
	sub	ebx,'a'         ; Convert to origin-0
	mov	eax,HSTLIN_NROW ; Get total # rows
	dec	eax		; Less one to get last row #
	sub	eax,ebx 	; Subtract to get index #
	mov	HSTIND,eax	; Save as new index #
HST_CR:
	mov	ecx,HSTLIN_NROW ; Get total # rows
	sub	ecx,HSTIND	; Subtract to get index # from bottom

	push	CMDHIST_CUR	; Pass offset in DGROUP of cursor
	call	CMD_GET_NEXT	; Return with EAX ==> next command
;;;;;;; je	short CMD_DISP_HIST_EXIT ; Jump if not found
@@:
	push	eax		; Pass cursor
	call	CMD_GET_PREV	; Return with EAX ==> previous command
;;;;;;; je	short CMD_DISP_HIST_EXIT ; Jump if not found

	loop	@B		; Jump if more indices

	mov	CMDHIST_CUR,eax ; Save as cursor position

	call	CMD_RETR_NEXT	; Display it
HST_ESC:
	or	LCL_FLAG,@LCL_REDI ; Force screen re-display
CMD_DISP_HIST_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_DISP_HIST endp		; End CMD_DISP_HIST procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_HST module
