;' $Header:   P:/PVCS/386SWAT/SWAT_VID.ASV   1.12   21 Aug 1997 15:00:28   BOB  $
	title	SWAT_VID -- 386SWAT Video Display Functions
	page	58,122
	name	SWAT_VID

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-1999 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include VIDCALL.INC
	include BIOSDATA.INC
	include BITFLAGS.INC
	include ALLMEM.INC
	include 6845.INC

	include SWAT_COM.INC
	include SWAT_SEG.INC
	include SWAT_VID.INC
.list

DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	public	@SWAT_VID_DATA16
@SWAT_VID_DATA16 label byte	; Mark module start in .MAP file

	extrn	CMD_FLAG:word
	include SWAT_CMD.INC

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC3_FLAG:dword
	include SWAT_LC3.INC

	extrn	DEFATTR:byte
	extrn	VIDTYPE:dword

	public	VIDBASE_FVEC,ACTBASE_FVEC
VIDBASE_FVEC df ?		; Ptr to video buffer
ACTBASE_FVEC df ?		; Ptr to actual video buffer

	public	CRTC,OLDPOSN,OLDTYPE,OLD6845,CURPOSN,CURTYPE
	public	OLDINFO,OLDINF3,OLDNPNTS
	public	OLDROWS,OLDCRT_MODE,TXTMODE
CRTC	dw	?		; CRT controller port
OLDPOSN dw	?		; Old cursor position
OLDTYPE dw	?		; Old cursor type
OLD6845 dw	?		; Old cursor type
CURPOSN dw	((@NROWS-1) shl 8) or 0 ; Current cursor position
CURTYPE dw	?		; Current cursor type
OLDINFO db	?		; Old INFO byte
OLDINF3 db	?		; Old INFO byte #3
OLDNPNTS dw	?		; Old NPOINTS word
OLDROWS db	?		; Old NROWS byte
OLDCRT_MODE db	?		; Old CRT_MODE
TXTMODE db	?		; Default text mode

	public	MODETAB
;		00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12 13
MODETAB db	00,00,00,00,01,01,01,00,03,01,01,01,01,01,01,02,02,03,03,01

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	@SWAT_VID_DATA
@SWAT_VID_DATA	label byte	; Mark module start in .MAP file

	extrn	SCROFF:dword

	public	VID_FLIP
VID_FLIP dd	@VID_FLIP	; Bits to flip VIDBASE_FVEC.FOFF

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP,ds:PGROUP

	public	@SWAT_VID_PROG
@SWAT_VID_PROG: 		; Mark module start in .MAP file

	extrn	SWATINI:tbyte
	include MAXDEV.INC

	extrn	REPLAY_VFN:near
	extrn	U32_SET_ATTRS:near
	extrn	U32_DRAINPIQ:near
	extrn	SET_VIDVARS:near

	extrn	U32_DisableAGP:near
	extrn	U32_EnableAGP:near
	extrn	U32_SwapDPCI:near

	NPPROC	REMROW -- Calculate Remaining Rows
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate the # remaining rows on the screen

On exit:

ECX	=	# remaining rows

|

	REGSAVE <eax,edx,ds>	; Save registers

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	mov	eax,SCROFF	; Get current screen offset
	xor	edx,edx 	; Zero to use as qword EDX:EAX
	mov	ecx,@NCOLS*2	; # chars per screen row
	div	ecx		; Return with EAX = row, EDX = column*2

	cmp	edx,1		; Check for in column zero
	cmc
	adc	eax,0		; Skip to the next line

	mov	ecx,@NROWS	; Get maximum # rows
	sub	ecx,eax 	; Less next row to get # remaining rows

	REGREST <ds,edx,eax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REMROW	endp			; End REMROW procedure
	NPPROC	REMCOL -- Calculate Remaining Columns
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate the # remaining entries in the current row of size SIZ.

On exit:

ECX	=	# remaining entries

|

REMCOL_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
REMCOL_SIZ dd	?		; Entry size

REMCOL_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,edx,ds>	; Save registers

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	mov	eax,SCROFF	; Get current screen offset
	xor	edx,edx 	; Zero to use as dword DX:AX
	mov	ecx,@NCOLS*2	; # chars per screen row
	div	ecx		; Return with EAX = row, EDX = column*2
	shr	edx,1-0 	; Convert from bytes to words
	mov	eax,@NCOLS	; Get maximum # columns
	sub	eax,edx 	; Less next column # to get # remaining cols
	xor	edx,edx 	; Zero to use as qword EDX:EAX
	div	[ebp].REMCOL_SIZ ; Divided by entry size
	mov	ecx,eax 	; Copy to count register

	REGREST <ds,edx,eax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REMCOL	endp			; End REMCOL procedure
	NPPROC	SAVE_SCR -- Save All Screen text
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Save all screen text in buffer.

|

SCR_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
SCR_ACT dd	?		; 1 for actual screen (ACTBASE), 0 for VIDBASE
SCR_OFF dd	?		; Offset of screen buffer

SCR_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ecx,esi,edi,ds> ; Save registers

;;;;;;; test	LCL_FLAG,@LCL_BOTH ; Both video adapters present?
;;;;;;; jnz	short SAVE_SCR_EXIT ; Yes, avoid flicker

	push	CURPOSN 	; Get new cursor position
	call	SET_CURPOS	; Set it

	push	CURTYPE 	; Get new cursor type
	call	SET_CURTYP	; Set it

	cmp	[ebp].SCR_ACT,1 ; Use actual screen?
	jne	short @F	; Jump if not

	lds	esi,ACTBASE_FVEC ; DS:ESI ==> actual video buffer
	assume	ds:nothing	; Tell the assembler

	jmp	short SAVE_SCR_COM ; Join common code

@@:
	lds	esi,VIDBASE_FVEC ; DS:ESI ==> video buffer
	assume	ds:nothing	; Tell the assembler about it
SAVE_SCR_COM:
	mov	edi,[ebp].SCR_OFF ; ES:EDI ==> save area
	mov	ecx,@SCRSIZE/4	; ECX = # dwords to save
S32 rep movs	<DGROUP:[edi].EDD,ds:[esi].EDD> ; Save 'em
SAVE_SCR_EXIT:
	REGREST <ds,edi,esi,ecx> ; Restore
	assume	ds:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_SCR endp			; End SAVE_SCR procedure
	NPPROC	REST_SCR -- Restore All Screen text
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Restore all screen text from buffer.

|

RSCR_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
RSCR_OFF dd	?		; Offset of screen buffer

RSCR_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ecx,esi,edi,es> ; Save registers

;;;;;;; test	LC3_FLAG,@LC3_NOVID ; Is display disabled?
;;;;;;; jnz	short REST_SCR_EXIT ; Jump if so

;;;;;;; test	LCL_FLAG,@LCL_BOTH ; Both video adapters present?
;;;;;;; jnz	short REST_SCR_EXIT ; Yes, avoid flicker

	push	OLDPOSN 	; Get old cursor position
	call	SET_CURPOS	; Set it

	mov	cx,OLDTYPE	; Get old cursor type
	mov	ah,@VID_SIZLO	; Cursor row start register
	call	SET6845 	; Set 6845 registers from CX

	les	edi,VIDBASE_FVEC ; ES:EDI ==> video buffer
	assume	es:nothing	; Tell the assembler about it

	mov	esi,[ebp].RSCR_OFF ; DS:ESI ==> save area
	mov	ecx,@SCRSIZE/4	; ECX = # dwords to save
S32 rep movs	<es:[edi].EDD,DGROUP:[esi].EDD> ; Save 'em
REST_SCR_EXIT:
	REGREST <es,edi,esi,ecx,eax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_SCR endp			; End REST_SCR procedure
	NPPROC	CLS -- Clear Screen
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear the screen (assumed to be in text mode).

|

	REGSAVE <eax,ecx,edi,ds,es> ; Save registers

	cld			; String ops forwardly

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	mov	SCROFF,0	; Initialize screen offset

	les	edi,VIDBASE_FVEC ; ES:EDI ==> video base
	assume	es:nothing	; Tell the assembler about it

	add	edi,SCROFF	; Plus current offset
	mov	ecx,@SCRSIZE/2	; # char/attr pairs on the screen to clear
	mov	ah,DEFATTR	; Get default attribute
	mov	al,' '          ; Blank, intense white on black
    rep stos	es:[edi].ELO	; Clear the screen

	REGREST <es,ds,edi,ecx,eax> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLS	endp			; End CLS procedure
	NPPROC	CLEAR_EOL -- Clear to End-Of-the-Line
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear to the end of the line.

|

	REGSAVE <eax,ecx>	; Save registers

	PUSHD	0+1		; Pass the divisor as argument
	call	REMCOL		; Return with ECX = # entries remaining

	cmp	ecx,@NCOLS	; Is the line already clear?
	je	short CLEAR_EOL_EXIT ; Yes

	jecxz	CLEAR_EOL_EXIT	; Jump if none remain

	mov	al,' '          ; Text to display
@@:
	call	DISPTXT 	; Display space on screen as text

	loop	@B		; Jump if more space to fill
CLEAR_EOL_EXIT:
	REGREST <ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLEAR_EOL endp			; End CLEAR_EOL procedure
	NPPROC	CLEAR_EOP -- Clear to End-Of-the-Page
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear to the end of the page except for the command line.

|

	REGSAVE <eax,ecx>	; Save registers

	call	REMROW		; Return with ECX = # remaining rows

	sub	ecx,1		; Less one for the command line
	jbe	CLEAR_EOP_EXIT	; Jump if none remain

	cmp	ecx,@NROWS	; Jump if entire screen remains
	je	short CLEAR_EOP_EXIT ; That's all folks
CLEAR_EOP_NROW:
	push	ecx		; Save for a moment

	mov	ecx,@NCOLS	; Get # columns on the screen
	mov	al,' '          ; Text to display
@@:
	call	DISPTXT 	; Display space on screen as text

	loop	@B		; Jump if more space to fill

	pop	ecx		; Restore

	loop	CLEAR_EOP_NROW	; Jump if more rows to clear
CLEAR_EOP_EXIT:
	REGREST <ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLEAR_EOP endp			; End CLEAR_EOP procedure
	NPPROC	DISPTXT -- Display Byte in AL As Text
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	REGSAVE <eax,edi,ds,es> ; Save registers

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	les	edi,VIDBASE_FVEC ; ES:EDI ==> video base
	assume	es:nothing	; Tell the assembler about it

	add	edi,SCROFF	; Plus current offset

	mov	ah,DEFATTR	; Get default attribute
S32	stos	es:[edi].ELO	; Save char/attr on screen
	sub	edi,VIDBASE_FVEC.FOFF ; Less video base offset

	mov	SCROFF,edi	; Save for next time

	REGREST <es,ds,edi,eax> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPTXT endp			; End DISPTXT procedure
	NPPROC	SAVE_SCRDATA -- Save Screen Data
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Save screen data

|

	REGSAVE <eax,ebx,ecx>	; Save registers

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows 3?
	jnz	short SAVE_SCRDATA_EXIT ; Jump if so

	test	LC3_FLAG,@LC3_NOVID ; Is display disabled?
	jnz	short SAVE_SCRDATA_EXIT ; Jump if so

	xor	ebx,ebx 	; Zero to use as dword
	mov	bx,seg BIOSDATA ; Get segment of BIOS data area
	shl	ebx,4-0 	; Convert from paras to bytes
	assume  gs:BIOSDATA	; Tell the assembler about it

	mov	ax,ADDR_6845[ebx] ; Get current 6845 address
	mov	OLD6845,ax	; Save for later use

	mov	ah,@VID_SIZLO	; Cursor row start register
	call	GET6845 	; Get 6845 registers into CX
	mov	OLDTYPE,cx	; Save as old cursor type

	mov	al,CRT_MODE[ebx] ; Get current CRT mode byte
	mov	OLDCRT_MODE,al  ; Save for later use

	mov	ax,CURSOR_POSN[ebx][0] ; Get current cursor position
	mov	OLDPOSN,ax	; Save to restore later

	mov	al,EGA_ROWS[ebx] ; Get EGA # screen rows byte
	mov	OLDROWS,al	; Save for later use

	mov	ax,EGA_PNTS[ebx] ; Get EGA # bytes per character word
	mov	OLDNPNTS,ax	; Save for later use

	mov	al,EGA_INFO[ebx] ; Get EGA information byte
	mov	OLDINFO,al	; Save for later use

	mov	al,EGA_INF3[ebx] ; Get EGA information byte #3
	mov	OLDINF3,al	; Save for later use
SAVE_SCRDATA_EXIT:
	REGREST <ecx,ebx,eax>	; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_SCRDATA endp		; End SAVE_SCRDATA procedure
	NPPROC	GET_CURPOS -- Get Cursor Position
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get cursor position as (Row,Col) = (CH,CL)

|

	test	LC3_FLAG,@LC3_NOVID ; Is display disabled?
	jnz	short @F	; Jump if so

	push	eax		; Save for a moment

	mov	ah,@VID_POSHI	; Cursor high location register
	call	GET6845 	; Get 6845 registers into CX

	pop	eax		; Restore
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_CURPOS endp 		; End GET_CURPOS procedure
	NPPROC	SET_CURPOS -- Set Cursor Position
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set cursor position to (Row,Col) = (CH,CL)

|

SETCUR_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
SETCUR_VAL dw	?		; New cursor position/type value

SETCUR_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ecx>	; Save registers

	test	LC3_FLAG,@LC3_NOVID ; Is display disabled?
	jnz	short SETCUR_EXIT ; Jump if so

	mov	cx,[ebp].SETCUR_VAL ; Get new cursor position value
	mov	al,@NCOLS	; Get # screen columns
	mul	ch		; Times row #
	xor	ch,ch		; Cursor row zero
	add	cx,ax		; Add together to get linear offset

	mov	ah,@VID_POSHI	; Cursor high location register
	call	SET6845 	; Set 6845 registers from CX
SETCUR_EXIT:
	REGREST <ecx,eax>	; Restore

	pop	ebp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_CURPOS endp 		; End SET_CURPOS procedure
	NPPROC  SET_CURTYP -- Set Cursor Type
	assume  ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Set cursor type to (CH,CL)

|

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ecx>	; Save registers

	test	LC3_FLAG,@LC3_NOVID ; Is display disabled?
	jnz	short SET_CURTYP_EXIT ; Jump if so

	mov	cx,[ebp].SETCUR_VAL ; Get new cursor type value
	mov	CURTYPE,cx	; Save as new current type

	mov	ah,@SETTYP	; Get the command
	mov	al,TXTMODE	; Get default text mode
	call	REPLAY_VFN	; Replay video command AH, type CX
	jnc	short SET_CURTYP_EXIT ; Jump if video command/mode/type found

; If color EGA and cursor eumlation mode, modify the cursor start and stop

	cmp	al,@TXT_MDA	; Izit monochrore mode?
	je	short SET_CURTYP1 ; Jump if so

	test	OLDINFO,00000001b ; Test cursor emulate bit
				; 0 = emulate, 1 = as-is
	jnz	short SET_CURTYP1 ; Jump if no emulation

; Adjust the cursor start/end register

	dec	cl		; Less one in cursor end
	shl	cl,1		; Times two

	cmp	ch,0		; Izit at top?
	je	short SET_CURTYP1 ; Jump if so

	mov	ch,cl		; Copy cursor end
	dec	ch		; Less one to get two-line cursor
	dec	ch
SET_CURTYP1:
	mov	ah,@VID_SIZLO	; Cursor row start register
	call	SET6845 	; Set 6845 registers from CX
SET_CURTYP_EXIT:
	REGREST <ecx,eax>	; Restore

	pop	ebp		; Restore

	ret	2		; Return to caller, popping argument

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_CURTYP endp 		; End SET_CURTYP procedure
	NPPROC  SET6845 -- Set 6845 Registers
	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set 6845 registers indexed by AH+0 1 to (CH,CL)

On entry:

(CH,CL)  =	 CRTC register values

|

	REGSAVE <eax,edx,ds>	; Save registers

	SETDATA ds		; Set data selector into DS
	assume  ds:DGROUP	; Tell the assembler about it

	mov	al,ah		; Cursor low location register
	mov	dx,CRTC 	; Get CRT controller I/O port address

	out	dx,al		; Tell the CRTC about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	al,ch		; Get high-order bits
	inc	dx		; Skip to data port

	out	dx,al		; Tell the CRTC about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	al,ah		; Cursor high location register
	inc	al		; Skip to next index register
	dec	dx		; Back to command port

	out	dx,al		; Tell the CRTC about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	al,cl		; Get low-order bits
	inc	dx		; Skip to data port
	out	dx,al		; Tell the CRTC about it
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	REGREST <ds,edx,eax>	; Restore
	assume  ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET6845 endp			; End SET6845 procedure
	NPPROC  GET6845 -- Get 6845 Registers
	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get 6845 registers indexed by AH+0 1 into (CH,CL)

On exit:

(CH,CL)  =	 CRTC register values

|

	REGSAVE <eax,edx,ds>	; Save registers

	SETDATA ds		; Set data selector into DS
	assume  ds:DGROUP	; Tell the assembler about it

	mov	al,ah		; Cursor low location register
	mov	dx,CRTC 	; Get CRT controller I/O port address

	out	dx,al		; Tell the CRTC about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	inc	dx		; Skip to data port

	in	al,dx		; Ask the CRTC about it
	mov	ch,al		; Set high-order bits
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	al,ah		; Cursor high location register
	inc	al		; Skip to next index register
	dec	dx		; Back to command port

	out	dx,al		; Tell the CRTC about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	inc	dx		; Skip to data port
	in	al,dx		; Ask the CRTC about it
	mov	cl,al		; Set low-order bits
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	REGREST <ds,edx,eax>	; Restore
	assume  ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET6845 endp			; End GET6845 procedure
	NPPROC	FLIPVBASE -- Switch to Other Video Base
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Switch to other video base.

If there's a mono adapter hidden by a PCI VGA adapter (or AGP
controller), switch between the primary and mono adapters.

If there are dual PCI VGA dapaters, switch between the primary and
secondary adapters.

|

	REGSAVE <eax>		; Save register

	test	LC3_FLAG,@LC3_NOVID ; Is display disabled?
	jnz	near ptr FLIPVBASE_EXIT ; Jump if so

	test	LCL_FLAG,@LCL_SPCI ; Are there dual PCI VGA adapters?
	jnz	short FLIPVBASE_DPCI ; Jump if so

	xor	TXTMODE,@TXT_FLIP ; Flip the text mode
	xor	OLDTYPE,(@CUR_FLIP and 0FFFFh) ; ...and old cursor type

	push	0		; Pass argument NOT to set mode
	call	SET_VIDVARS	; Setup video mode variables

	mov	ax,VIDTYPE.ELO	; Assume normal cursor type

	test	CMD_FLAG,@CMD_INS ; Izit enabled?
	jz	short @F	; Jump if not

	mov	ax,VIDTYPE.EHI	; Get insert mode cursor type
@@:
	mov	CURTYPE,ax	; Set as cursor type

	push	ax		; Pass as argument
	call	SET_CURTYP	; Set it

	test	LCL_FLAG,@LCL_PCIMDS ; MDA hidden by PCI VGA/AGP?
	jz	short FLIPVBASE_COM ; Jump if not

	btc	LCL_FLAG,$LCL_PCIMDA ; Toggle current state
	jc	short @F	; Jump if currently active

	call	U32_DisableAGP	; Disable the AGP controller

	jmp	short FLIPVBASE_COM ; Join common code

@@:
	call	U32_EnableAGP	; Enable the AGP controller

	jmp	short FLIPVBASE_COM ; Join common code

FLIPVBASE_DPCI:
	btc	LCL_FLAG,$LCL_DPCI ; Toggle current state
	jc	short @F	; Jump if currently active

	call	U32_DisableAGP	; Disable the AGP controller
	call	U32_SwapDPCI	; Swap DPCI adapters

	jmp	short FLIPVBASE_COM ; Join common code

@@:
	call	U32_SwapDPCI	; Swap DPCI adapters
	call	U32_EnableAGP	; Enable the AGP controller
FLIPVBASE_COM:
	call	U32_SET_ATTRS	; Set the screen attributes
FLIPVBASE_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FLIPVBASE endp			; End FLIPVBASE procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_VID module
