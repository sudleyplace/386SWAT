;' $Header:   P:/PVCS/386SWAT/SWAT_FVM.ASV   1.16   21 Aug 1997 15:00:24   BOB  $
	title	SWAT_FVM -- 386SWAT Find Video Mode Routines
	page	58,122
	name	SWAT_FVM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include DOSCALL.INC
	include VIDCALL.INC
	include INTVEC.INC
	include CPUFLAGS.INC
	include BITFLAGS.INC
	include BIOSDATA.INC
	include ALLMEM.INC
	include PTR.INC
	include I11.INC
	include 386.INC
	include MAXDEV.INC

	include SWAT_COM.INC
	include SWAT_FVM.INC
	include SWAT_SEG.INC
	include SWAT_VID.INC
.list

VGROUP	group	VDATA


COMMENT|

DVGA POS[0] bit definitions:

Bit 5		 $DVGA_ESOG2	20:  1 = Enable sync on green (section 2)
				     0 = Disable ...
Bit 4		 $DVGA_ESOG1	10:  1 = Enable sync on green (section 1)
				     0 = Disable ...
Bit 3		 $DVGA_ENA2	08:  1 = Enable section 2
				     0 = Disable ...
Bit 2		 $DVGA_ENA1	04:  1 = Enable section 1
				     0 = Disable ...
Bit 1		 $DVGA_RSV	02:  (reserved)
Bit 0		 $DVGA_AENA	01:  1 = Adapter enable
				     0 = ... disable

|

DVGA_REC record $DVGA_ESOG2:1,$DVGA_ESOG1:1,$DVGA_ENA2:1,$DVGA_ENA1:1,$DVGA_RSV:1,$DVGA_AENA:1
; 0Dh = 08+04+01 = (mask $DVGA_ENA2) or (mask $DVGA_ENA1) or (mask $DVGA_AENA)
; 09h = 08+   01 = (mask $DVGA_ENA2) or 		     (mask $DVGA_AENA)
; 05h =    04+01 =			(mask $DVGA_ENA1) or (mask $DVGA_AENA)
; 00h = 00

@DVGA_ENA12 equ (mask $DVGA_ENA2) or (mask $DVGA_ENA1) or (mask $DVGA_AENA)
@DVGA_ENA2  equ (mask $DVGA_ENA2)			   (mask $DVGA_AENA)
@DVGA_ENA1  equ 		      (mask $DVGA_ENA1) or (mask $DVGA_AENA)
@DVGA_ADIS  equ 00h


VDATA	segment use16 dword at 0 ; Start VDATA segment
	assume	ds:VGROUP

	public	IODATA
IODATA	label	dword

VDATA	ends			; End VDATA segment


DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	extrn	COMMON:tbyte
	include SWAT_FIL.INC

	extrn	ARG_FLAG:word
	include SWAT_ARG.INC

	extrn	CMD_FLAG:word
	include SWAT_CMD.INC

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	LC3_FLAG:dword
	include SWAT_LC3.INC

	extrn	TXTMODE:byte
	extrn	CRTC:word
	extrn	VIDTYPE:dword
	extrn	VIDBASE_FVEC:fword
	extrn	ACTBASE_FVEC:fword

	extrn	CO80TYPE:dword
	extrn	MONOTYPE:dword

	extrn	PLCLMONO:dword
	extrn	PLCLCOLR:dword

	extrn	SWATDATA:dword

	public	FVMBASE
FVMBASE dd	?		; Base of find video modes

	public	OLDCR3
OLDCR3	dd	?		; Previous value of CR3 for video PTE checking

	public	DVGA_SLOT
DVGA_SLOT db	?		; DVGA slot # (origin-0)

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	MSGOFF:dword
	extrn	SYNTERR:byte
	extrn	OVFERR:byte

;;;;;;; extrn	REENTRY:word
;;;;;;;
	extrn	VID_FLIP:dword

	extrn	OffVidPDE:dword
	extrn	PaVidPDE:dword

IO_STR	struc

IO_PORT dw	?		; I/O port # or offset if move
IO_VAL	dw	?		; Output value (if any)
IO_FLAG db	?		; I/O flags (see @IO_ equates below)

IO_STR	ends

@IO_MOVE equ	80h		; Set = move,	  Clr = I/O
@IO_INP equ	40h		; Set = input,	  Clr = output
@IO_WORD equ	20h		; Set = word I/O, Clr = byte I/O


;;;;;;; public	XLATMODE
;;;;MODE label	 byte
;  00  01  02  03  04  05  06  07  08  09  0A  0B  0C  0D  0E  0F  10  11  12  13
;;;00h,00h,03h,03h,04h,04h,06h,07h,08h,09h,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh,10h,11h,12h,13h
;;;;;MODE equ	 $-XLATMODE	; # modes we know about

COMMENT|

Video Modes:
			Alpha	Buffer
Mode	 Type	 # Clr	Format	Start
---------------------------------------
00h	 Text	 16	40x25	B8000
01h	 Text	 16	40x25	B8000
02h	 Text	 16	80x25	B8000
03h	 Text	 16	80x25	B8000
04h	 Graf	  4	40x25	B8000
05h	 Graf	  4	40x25	B8000
06h	 Graf	  2	80x25	B8000
07h	 Text  Mono	80x25	B0000
08h	 Graf	 16	20x25	B0000
09h	 Graf	 16	40x25	B0000
0Ah	 Graf	  4	80x25	B0000
0Bh	 Reserved
0Ch	 Reserved
0Dh	 Graf	 16	40x25	A0000
0Eh	 Graf	 16	80x25	A0000
0Fh	 Graf  Mono	80x25	A0000
10h	 Graf	 16	80x25	A0000
11h	 Graf	  2	80x30	A0000
12h	 Graf	 16	80x30	A0000
13h	 Graf	256	40x25	A0000

|

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP

	extrn	U32_SET_ATTRS:near
	extrn	U32_HEX2DD:near
	extrn	CMD_WHITE:near
	extrn	SET_CURTYP:near
	extrn	U32_DRAINPIQ:near

	extrn	LIN2PPTE:near
	extrn	LIN2PPDIR:near
	extrn	LIN2PPTEZ:near
	extrn	GETLBASE:near

	extrn	SWATINI:tbyte

	NPPROC	CHECK_VMOD -- Check Video Mode
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Check video mode -- if not in text mode, reset to that mode.

Note: The altscrn profile option is handled during initialization,
      not at run-time.

|

	call	SET_VIDPTE	; Setup video PTEs

	push	1		; Pass argument to set mode
	call	SET_VIDVARS	; Setup video mode variables
;;;;;;; jnc	short CHECK_VMOD_EXIT ; Jump if video mode found
CHECK_VMOD_ERR:



CHECK_VMOD_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_VMOD endp 		; End CHECK_VMOD procedure
	NPPROC	SET_VIDPTE -- Setup Video PTEs
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Setup video PTEs

|

	pushad			; Save all EGP registers

	mov	eax,cr0 	; Get control register with $PG bit

	test	eax,mask $PG	; Is paging enabled as yet?
	jnz	short @F	; Jump if so

	mov	ax,COMMON.FILE_4GB ; Address all of memory
	mov	ACTBASE_FVEC.FSEL,ax ; Save as video selector

	jmp	SET_VIDPTE_EXIT ; Join common exit code

@@:

; If this is a new CR3, do it again

	mov	ebx,cr3 	; Get current CR3
	and	bx,mask $PTE_FRM ; Isolate the frame

	cmp	ebx,OLDCR3	; Izit the same as before?
	je	near ptr SET_VIDPTE_EXIT ; Jump if so

	mov	OLDCR3,ebx	; Save for next time

; Save our data linear address for later use

	PUSHW	ds		; Pass selector as argument
	call	GETLBASE	; Return with EAX = selector base
	mov	SWATDATA,eax	; Save for later use

; If the PDE for SWAT's PLCLMONO is a 4MB page, replace it with
; a 4KB page

;;;;;;; mov	eax,SWATDATA	; Get linear address of DGROUP
	add	eax,PLCLMONO	; Plus offset of table in DGROUP

	PUSHD	0		; Make room for original PTE
	PUSHD	1		; # PTEs to follow
	PUSHD	0		; Make room for original PDE
	push	eax		; Pass the linear address
	push	ebx		; Pass the CR3 to use
	call	LIN2PPDIR	; Return with AGROUP:EAX ==> corresponding PDIR

	test	AGROUP:[eax].EDD,mask $PTE_PS ; Izit a 4MB page?
	jz	short SET_VIDPTE1 ; Jump if not

	mov	ecx,PaVidPDE	; Get physical address of Video PDE
	xchg	ecx,AGROUP:[eax] ; Swap 'em
	mov	edx,ecx 	; Copy the PDE
	and	edx,not (@PTE_FRM or (mask $PTE_PS)) ; Isolate the flags
				; except for $PTE_PS
	or	AGROUP:[eax],edx ; Transfer to new PDE

; Setup new PDE as 4KB page

	push	es		; Save for a moment

	mov	eax,ds		; Copy DGROUP data selector
	mov	es,eax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	eax,ecx 	; Get old PDE
	and	eax,mask $LA_DIR ; Isolate the 4MB physical address
	or	eax,edx 	; Include the old flags
	mov	edi,OffVidPDE	; Get offset in DGROUP of Video PDE
	mov	ecx,1024	; Get # PTEs in a PDE
@@:
	stos	DGROUP:[edi].EDD ; Save new PTE
	add	eax,4*1024	; Skip to next PTE

	loop	@B		; Jump if more PTEs

	pop	es		; Restore
	assume	es:nothing	; Tell the assembler about it
SET_VIDPTE1:
	call	LIN2PPTEZ	; Cleanup after LIN2PPDIR
	add	esp,1*4 	; Pop the PTE

; At PLCLMONO in the PDIR, put physical 000B0000h

	mov	eax,SWATDATA	; Get linear address of DGROUP
	add	eax,PLCLMONO	; Plus offset of table in DGROUP

	PUSHD	0		; Make room for original PTE
	PUSHD	1		; # PTEs to follow
	PUSHD	0		; Make room for original PDE
	push	eax		; Pass the linear address
	push	ebx		; Pass the CR3 to use
	call	LIN2PPTE	; Return with AGROUP:EAX ==> corresponding PTE

; Because of a quirk in Win95 (what only one!), we need to
; preserve the AVL bits and set the accessed bit so this PTE
; won't be thought of as one available for allocation.

	and	AGROUP:[eax].EDD,(mask $PTE_AV2) or \
				 (mask $PTE_AV1) or \
				 (mask $PTE_AV0) ; Isolate the AVL bits
	or	AGROUP:[eax].EDD,@VID_MDAPTE or (mask $PTE_A) ; Mark as
				; (accessed) monochrome buffer
	call	LIN2PPTEZ	; Cleanup after LIN2PPTE
	add	esp,1*4 	; Pop the PTE

; At PLCLCOLR in the PDIR, put physical 000B8000h

	mov	eax,SWATDATA	; Get linear address of DGROUP
	add	eax,PLCLCOLR	; Plus offset of table in DGROUP

	PUSHD	0		; Make room for original PTE
	PUSHD	1		; # PTEs to follow
	PUSHD	0		; Make room for original PDE
	push	eax		; Pass the linear address
	push	ebx		; Pass the CR3 to use
	call	LIN2PPTE	; Return with AGROUP:EAX ==> corresponding PTE

; Because of a quirk in Win95 (what only one!), we need to
; preserve the AVL bits and set the accessed bit so this PTE
; won't be thought of as one available for allocation.

	and	AGROUP:[eax].EDD,(mask $PTE_AV2) or \
				 (mask $PTE_AV1) or \
				 (mask $PTE_AV0) ; Isolate the AVL bits
	or	AGROUP:[eax].EDD,@VID_CLRPTE or (mask $PTE_A) ; Mark as
				; (accessed) color buffer
	call	LIN2PPTEZ	; Cleanup after LIN2PPTE
	add	esp,1*4 	; Pop the PTE
SET_VIDPTE_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_VIDPTE endp 		; End SET_VIDPTE procedure
	NPPROC	SET_VIDVARS -- Setup Video Variables
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Setup video variables based upon value in TXTMODE.

On exit:

CF	=	0 if all went OK
	=	1 otherwise

|

SVV_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
SVV_SETMODE dd	?		; 1 = set mode, 0 = don't

SVV_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ebx,ecx,edx> ; Save registers

; If paging has been enabled, use the local buffer for video
; access; if not, use the physical buffer

	mov	ecx,cr0 	; Get control register with $PG bit
	and	ecx,mask $PG	; Isolate the bit

	cmp	TXTMODE,@TXT_CLR ; Izit color?
	je	short SET_VIDVARS_CLR ; Jump if so

	mov	TXTMODE,@TXT_MDA ; ...and text mode
	mov	CRTC,@CRT_MDA	; ... and CRT controller
	mov	VIDTYPE,@CUR_MDA ; ...and cursor type

	mov	eax,@VID_MDA	; Get monochrome base
	mov	bx,gs		; Get matching selector

	jecxz	@F		; Jump if the video PTEs not in place

	mov	eax,PLCLMONO	; Get offset in DGROUP of monochrome buffer
	mov	bx,ds		; Get matching selector
@@:
	jmp	short SET_VIDVARS_COM ; Join common code

SET_VIDVARS_CLR:
;;;;;;; mov	TXTMODE,@TXT_CLR ; ...and text mode
	mov	CRTC,@CRT_CLR	; ... and CRT controller
	mov	VIDTYPE,@CUR_CLR ; ...and cursor type

	mov	eax,@VID_CLR	; Get video base
	mov	bx,gs		; Get matching selector

	jecxz	@F		; Jump if the video PTEs not in place

	mov	eax,PLCLCOLR	; Get offset in DGROUP of color buffer
	mov	bx,ds		; Get matching selector
@@:
SET_VIDVARS_COM:
	mov	ACTBASE_FVEC.FOFF,eax ; Save it
	mov	ACTBASE_FVEC.FSEL,bx  ; Save it

; Set VID_FLIP for the new video base

	mov	eax,@VID_FLIP	; Get video flip bits

	jecxz	@F		; Jump if the video PTEs not in place

	mov	eax,PLCLMONO	; Get offset of monochrome buffer
	xor	eax,PLCLCOLR	; Get logical difference
@@:
	mov	VID_FLIP,eax	; Save for later use

; Copy actual video base to VIDBASE

	mov	eax,ACTBASE_FVEC.FOFF ; Get actual video base
	mov	VIDBASE_FVEC.FOFF,eax ; Set it
	mov	ax,ACTBASE_FVEC.FSEL ; Get video selector
	mov	VIDBASE_FVEC.FSEL,ax ; Set it

	cmp	[ebp].SVV_SETMODE,0 ; Should we not set mode?
	je	short SET_VIDVARS_EXIT ; Jump if so (note CF=0)

	test	LC3_FLAG,@LC3_NOVID ; Is video disabled?
	jnz	short SET_VIDVARS_EXIT ; Jump if so (note CF=0)

	call	U32_SET_ATTRS	; Set screen attributes

	mov	ah,@SETMOD	; Initialize command
	mov	al,TXTMODE	; Get default text mode
	call	REPLAY_VFN	; Replay video function AH/AL/BX/CX
				; Return with CF significant
	mov	ax,VIDTYPE.ELO	; Assume normal cursor type

	test	CMD_FLAG,@CMD_INS ; Izit enabled?
	jz	short @F	; Jump if not

	mov	ax,VIDTYPE.EHI	; Get insert mode cursor type
@@:
	push	ax		; Pass as argument
	call	SET_CURTYP	; Set it

	clc			; Indicate all went well (even if it didn't)
SET_VIDVARS_EXIT:
	REGREST <edx,ecx,ebx,eax> ; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_VIDVARS endp		; End SET_VIDVARS procedure
	NPPROC	REPLAY_VFN -- Replay Video Function
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Replay the video mode in AL.

On entry:

AH	=	command (@SETMOD, @SETTYP, or @GETEGA)
AL	=	video mode
BL	=	subfunction (if AH = @GETEGA)
CX	=	cursor type (if AH = @SETTYP)

|

	REGSAVE <eax,ebx,ecx,edx,esi> ; Save registers

	test	ARG_FLAG,@ARG_FVM or @ARG_DVGA ; Izit present and valid?
	jz	near ptr REPLAY_VFN_ERR ; Jump if not

	mov	esi,FVMBASE	; DS:ESI ==> video tables
REPLAY_VFN1:
	mov	dl,DGROUP:[esi].FVM_CMD ; Get this entry's command

	cmp	dl,@FVM_EOM	; Check for end-of-the-line
	je	near ptr REPLAY_VFN_ERR ; Jump if so

	cmp	dl,ah		; Izit the same command?
	jne	short REPLAY_VFN2 ; Jump if not

	cmp	al,DGROUP:[esi].FVM_MODE ; Izit our mode?
	jne	short REPLAY_VFN2 ; Jump if not

	cmp	ah,@SETMOD	; Izit set mode (no cursor type check)?
	je	short REPLAY_VFN_FOUND ; Jump if so

	cmp	ah,@SETTYP	; Izit set type (cursor type check)?
	je	short REPLAY_VFN_CURCHK ; Jump if so

	cmp	ah,@GETEGA	; Izit get EGA information?
	jne	short REPLAY_VFN_FOUND ; Jump if not

	cmp	bl,DGROUP:[esi].FVM_CUR.LO ; Izit same code type?
	je	short REPLAY_VFN_FOUND ; Jump if so

	jmp	short REPLAY_VFN2 ; Join common loop code

REPLAY_VFN_CURCHK:
	cmp	cx,DGROUP:[esi].FVM_CUR ; Izit same cursor type?
	je	short REPLAY_VFN_FOUND ; Jump if so
REPLAY_VFN2:
	add	esi,DGROUP:[esi].FVM_SIZE ; Skip to next entry

	jmp	short REPLAY_VFN1 ; Go around again

; DS:ESI ==> current video mode/cursor type

REPLAY_VFN_FOUND:
	mov	ax,DGROUP:[esi].FVM_SIZE.ELO ; Get size of this entry
	add	esi,size FVM_STR ; Skip over header

; Convert from size in bytes to # entries

	sub	ax,size FVM_STR ; Less size of header
	xor	dx,dx		; Zero to use as dword
	mov	bx,size IO_STR	; Get size of IODATA structure
	div	bx		; Convert from bytes to # entries
	movzx	ecx,ax		; Copy to count register

	pushfd			; Save flags
	cli			; Disallow interrupts
REPLAY_VFN_NEXT:
	mov	dx,DGROUP:[esi].IO_PORT ; Get the I/O port #
	mov	al,DGROUP:[esi].IO_FLAG ; Get flags

	test	al,@IO_MOVE	; Check for move
	jnz	short REPLAY_VFN_MOVE ; Jump if so

	and	al,@IO_INP or @IO_WORD ; Isolate input/output and word/byte flags

	cmp	al,0		; Izit byte output?
	je	short REPLAY_VFN_OUTB ; Jump if so

	cmp	al,@IO_WORD	; Izit word output?
	je	short REPLAY_VFN_OUTW ; Jump if so

	cmp	al,@IO_INP	; Izit byte input?
	je	short REPLAY_VFN_INB ; Jump if so

	cmp	al,@IO_INP or @IO_WORD ; Izit word input?
	je	short REPLAY_VFN_INW ; Jump if so

	jmp	short REPLAY_VFN_ERR ; Jump if not found

REPLAY_VFN_INW:
	in	ax,dx		; Perform word input
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	jmp	short REPLAY_VFN_LOOP ; Join common loop code

REPLAY_VFN_INB:
	cmp	dx,03B4h	; Izit mono status register?
	je	short REPLAY_VFN_VR ; Yes, wait for vertical retrace

	cmp	dx,03D4h	; Izit color status register?
	je	short REPLAY_VFN_VR ; Yes, wait for vertical retrace

	in	al,dx		; Perform byte input
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	jmp	short REPLAY_VFN_LOOP ; Join common loop code

@DISP_INACT equ 0001b		; Bit to test for 6845 display inactive
@VERT_SYNC  equ 1000b		; Bit to test for 6845 vertical retrace active

REPLAY_VFN_VR:
	in	al,dx		; Perform byte input
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	test	al,@VERT_SYNC	; Izit in vertical retrace?
	jz	short REPLAY_VFN_VR ; No, wait until it is

	jmp	short REPLAY_VFN_LOOP ; Join common loop code


REPLAY_VFN_OUTW:
	mov	ax,DGROUP:[esi].IO_VAL ; Get the output word
	out	dx,ax		; Perform word output
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	jmp	short REPLAY_VFN_LOOP ; Join common loop code

REPLAY_VFN_OUTB:
	mov	al,DGROUP:[esi].IO_VAL.LO ; Get the output byte
	out	dx,al		; Perform byte output
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	jmp	short REPLAY_VFN_LOOP ; Join common loop code

REPLAY_VFN_MOVE:
	movzx	ebx,DGROUP:[esi].IO_PORT ; Get the offset into A000

	test	DGROUP:[esi].IO_FLAG,@IO_WORD ; Izit a word move?
	jnz	short REPLAY_VFN_MOVW ; Jump if so

	mov	al,DGROUP:[esi].IO_VAL.LO ; Get the byte to move
	mov	AGROUP:[ebx+0A0000h],al ; Move it

	jmp	short REPLAY_VFN_LOOP ; Join common loop code

REPLAY_VFN_MOVW:
	mov	ax,DGROUP:[esi].IO_VAL ; Get the word to move
	mov	AGROUP:[ebx+0A0000h],ax ; Move it
REPLAY_VFN_LOOP:
	add	esi,size IO_STR ; Skip to next entry

	loop	REPLAY_VFN_NEXT ; Jump if more I/O operations

	popfd			; Restore flags

	clc			; Indicate we found it

	jmp	short REPLAY_VFN_EXIT ; Join common exit code

REPLAY_VFN_ERR:
	stc			; Indicate we didn't find the mode
REPLAY_VFN_EXIT:
	REGREST <esi,edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REPLAY_VFN endp 		; End REPLAY_VFN procedure
	NPPROC	CMD_MODE -- Video Mode Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Video mode command

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax,esi>	; Save registers

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	short CMD_MODE_SYNTERR ; Yes, treat as error

; Convert the hex number at DS:ESI to binary

	call	U32_HEX2DD	; Convert DS:ESI from hex to binary EAX
	jc	short CMD_MODE_OVFERR ; Jump if too large

; Ensure nothing more on the line

	push	eax		; Save for a moment

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	pop	eax		; Restore
	jne	near ptr CMD_MODE_SYNTERR ; No, so that's an error

	cmp	eax,@TXT_CLR	; Check for a supported video mode
	je	short @F	; Switch to color mode

	cmp	eax,@TXT_MDA	; Check for another supported video mode
	jne	short CMD_MODE_OVFERR ; Jump if not
@@:
	mov	TXTMODE,al	; Save as video mode

	push	1		; Pass argument to set mode
	call	SET_VIDVARS	; Setup video mode variables

	or	LCL_FLAG,@LCL_REDI ; Force screen re-display

	clc			; Indicate all went well

	jmp	short CMD_MODE_EXIT ; Join common exit code

CMD_MODE_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	jmp	short CMD_MODE_ERR ; Join common error exit code

CMD_MODE_OVFERR:
	mov	MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

;;;;;;; jmp	short CMD_MODE_ERR ; Join common error exit code

CMD_MODE_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_MODE_EXIT:
	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_MODE endp			; End CMD_MODE procedure
	NPPROC	CMD_DVGA1 -- DVGA Selection Section 1 Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

DVGA select section 1 command

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	call	DVGASEL0	; Select original VGA screen
	call	DVGASEL1	; Select DVGA section 1

	clc			; Indicate all went well

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_DVGA1 endp			; End CMD_DVGA1 procedure

SETUP_ADAP_MAC macro PREF

	NPPROC	PREF&SETUP_ADAP -- Setup Adapter
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Put adapter in slot BL (origin-0) into setup mode

|

	push	eax		; Save for a moment

	in	al,96h		; Get adapter enable/setup register
	call	PREF&DRAINPIQ	; Drain the Prefetch Instruction Queue

	and	al,not (@BIT0 or @BIT1 or @BIT2) ; Clear previous slot #
	or	al,bl		; Include the slot # (origin-0)
	or	al,@BIT3	; Select channel setup
	out	96h,al		; Put into setup mode
	call	PREF&DRAINPIQ	; Drain the Prefetch Instruction Queue

	in	al,94h		; Get system board enable/setup register
	call	PREF&DRAINPIQ	; Drain the Prefetch Instruction Queue

	or	al,@BIT7 or @BIT5 ; Set to avoid driving a signal to the
				; video subsystem (@BIT5) and
				; system board (@BIT7)
	out	94h,al		; Tell the system board about it
;;;;;;; call	PREF&DRAINPIQ	; Drain the Prefetch Instruction Queue

	pop	eax		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&SETUP_ADAP endp		; End PREF&SETUP_ADAP procedure

	endm			; SETUP_ADAP_MAC

	SETUP_ADAP_MAC U32_	; Define in PGROUP

ENABLE_ADAP_MAC macro PREF

	NPPROC	PREF&ENABLE_ADAP -- Enable Adapter (Disable Setup)
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable adapter setup

|

	push	eax		; Save for a moment

	mov	al,0		; Disable channel setup
	out	96h,al		; No position selected
;;;;;;; call	PREF&DRAINPIQ	     ; Drain the Prefetch Instruction Queue

	pop	eax		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&ENABLE_ADAP endp		; End PREF&ENABLE_ADAP procedure

	endm			; ENABLE_ADAP

	ENABLE_ADAP_MAC U32_	; Define in PGROUP

	NPPROC	SETUP_VGA -- Setup System Board Video
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup system board video subsystem

|


	REGSAVE <eax>		; Save register

	in	al,94h		; Get system board enable/setup register
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	and	al,not @BIT5	; Put video subsystem into setup mode
	out	94h,al		; Tell the system board about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	in	al,96h		; Get adapter enable/setup register
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	and	al,not (@BIT3 or @BIT2 or @BIT1 or @BIT0) ; Clear to avoid
				; driving a setup signal to an adapter
	out	96h,al		; Tell the adapters about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	in	al,94h		; Get system board enable/setup register
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	or	al,@BIT7	; Set to avoid driving a signal to the
				; system board (@BIT7)
	and	al,not @BIT5	; Put video subsystem into setup mode
	out	94h,al		; Tell the system board about it
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_VGA endp			; End SETUP_VGA procedure
	NPPROC	ENABLE_SYS -- Enable System Board (Disable Setup)
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable system board (disable setup)

|


	REGSAVE <eax>		; Save register

	mov	al,0FFh 	; Disable system board setup
	out	94h,al		; Tell the system board about it
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENABLE_SYS endp 		; End ENABLE_SYS procedure
	NPPROC	XDISABLE_SYSVGA -- Disable System Board VGA
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable system board VGA

|

	REGSAVE <eax,edx>	; Save registers

	call	SETUP_VGA	; Setup system board video

	mov	dx,102h 	; Get POS[0] register
	in	al,dx		; Get current POS[0] value
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	and	al,not @BIT0	; Disable system board functions
	out	dx,al		; Tell the POS[0] about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	call	ENABLE_SYS	; Enable system board

	REGREST <edx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XDISABLE_SYSVGA endp		; End XDISABLE_SYSVGA procedure
	NPPROC	XENABLE_SYSVGA -- Enable System Board VGA
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable system board VGA

|

	REGSAVE <eax,edx>	; Save registers

	call	SETUP_VGA	; Setup system board video

	mov	dx,102h 	; Get POS[0] register
	in	al,dx		; Get current POS[0] value
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	or	al,@BIT0	; Enable system board functions
	out	dx,al		; Tell the POS[0] about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	call	ENABLE_SYS	; Enable system board

	REGREST <edx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XENABLE_SYSVGA endp		; End XENABLE_SYSVGA procedure
	NPPROC	DVGASEL0 -- Restore Original VGA Screen
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore original VGA screen

On exit:

CF	=	0 if successful
	=	1 otherwise

|

	REGSAVE <eax,ebx,edx,ds,gs> ; Save registers

; Setup segment registers in case we're called from Ctrl-Alt-Del code

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	mov	gs,COMMON.FILE_4GB ; Get our all data selector
	assume	gs:AGROUP	; Tell the assembler about it

; Put the DVGA adapter into setup mode

	mov	bl,DVGA_SLOT	; Get the slot # (origin-0)
	call	U32_SETUP_ADAP	; Setup the adapter in slot BL
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

; Disable the DVGA adapter

	mov	dx,102h 	; I/O port for POS[0]
	mov	al,@DVGA_ADIS	; POS[0] value to disable DVGA
	out	dx,al		; Tell the DVGA about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	out	dx,al		; Tell the DVGA about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	call	U32_ENABLE_ADAP ; Enable adapter (disable setup)

; Enable the system board VGA

;;;;;;; call	ENABLE_SYSVGA	; Enable it
;;;;;;; mov	ah,@GETEGA	; Video function
;;;;;;; mov	bl,32h		; Function to enable/disable video
;;;;;;; mov	al,0		; Code to enable video
;;;;;;; call	REPLAY_VFN	; Replay video function AH/AL/BX/CX
;;;;;;;;			; Return with CF significant

	call	XENABLE_SYSVGA	; Enable system board VGA

	clc			; Indicate success

	REGREST <gs,ds,edx,ebx,eax> ; Restore
	assume	ds:DGROUP,gs:nothing ; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DVGASEL0 endp			; End DVGASEL0 procedure
	NPPROC	DVGASEL1 -- Enable DVGA Screen
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable DVGA screen

On exit:

CF	=	0 if successful
	=	1 otherwise

|

	REGSAVE <eax,ebx,edx,ds,gs> ; Save registers

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

;;;;;;; cmp	REENTRY,1	; Check re-entry level
;;;;;;; jne	short DVGASEL1_EXIT ; Jump if we're re-entering
;;;;;;;
	mov	gs,COMMON.FILE_4GB ; Get our all data selector
	assume	gs:AGROUP	; Tell the assembler about it

; Switch to DVGA section 1

;;;;;;; call	DISABLE_SYSVGA	; Disable it
;;;;;;; mov	ah,@GETEGA	; Video function
;;;;;;; mov	bl,32h		; Function to enable/disable video
;;;;;;; mov	al,1		; Code to disable video
;;;;;;; call	REPLAY_VFN	; Replay video function AH/AL/BX/CX
;;;;;;;;			; Return with CF significant

	call	XDISABLE_SYSVGA ; Disable system board VGA

; Put the DVGA adapter into setup mode

	mov	bl,DVGA_SLOT	; Get the slot # (origin-0)
	call	U32_SETUP_ADAP	; Setup the adapter in slot BL
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

; Enable section 1 only

	mov	dx,102h 	; I/O port for POS[0]
	mov	al,@DVGA_ENA1	; POS[0] value to enable section 1
	out	dx,al		; Tell the DVGA about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	out	dx,al		; Tell the DVGA about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	call	U32_ENABLE_ADAP ; Enable adapter (disable setup)
DVGASEL1_EXIT:
	clc			; Indicate success

	REGREST <gs,ds,edx,ebx,eax> ; Restore
	assume	ds:DGROUP,gs:nothing ; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DVGASEL1 endp			; End DVGASEL1 procedure

PROG	ends			; End PROG segment


NDATA	segment use16 dword public 'ndata' ; Start NDATA segment
	assume	ds:NGROUP

	extrn	VIDEO_SEG:word
	extrn	VIDEO_CNT:word
	extrn	DVGA_SEG:word
	extrn	DVGA_CNT:word

	public	FVMINT01_VEC,FVMINT10_VEC
FVMINT01_VEC dd ?		; Save area for original INT 01h handler
FVMINT10_VEC dd ?		; ...			     10h

	public	OLDFVMMODE,OLDFVMIVM,VFN_VEC
OLDFVMMODE db	?		; Old video mode
OLDFVMIVM  db	?		; Old initial video mode flags
VFN_VEC dd	0		; Pointer to next available offset into IODATA

	public	MCAID
MCAID	dw	8 dup (?)	; MCA adapter IDs

	public	DVGA_CURPOS,DVGA_CURTYP,DVGA_MODE,DVGA_PAGE
DVGA_CURPOS dw	?		; Original cursor position
DVGA_CURTYP dw	?		; ...		  type
DVGA_MODE db	?		; ...	   video mode
DVGA_PAGE db	?		; ...	   display page #

	public	FVMINT01_ACT
FVMINT01_ACT label word
	dw	NGROUP:FVMINT01_POPF			 ; 9D = POPF
	dw	(1+0A3h-09Eh) dup (NGROUP:FVMINT01_XIO) ; 9E-A3
	dw	NGROUP:FVMINT01_MOVSB			 ; A4 = MOVSB
	dw	NGROUP:FVMINT01_MOVSW			 ; A5 = MOVSW
	dw	(1+0CCh-0A6h) dup (NGROUP:FVMINT01_XIO) ; A6-CC
	dw	NGROUP:FVMINT01_INT			 ; CD = INT
	dw	NGROUP:FVMINT01_XIO			 ; CE
	dw	NGROUP:FVMINT01_IRET			 ; CF = IRET
	dw	(1+0E3h-0D0h) dup (NGROUP:FVMINT01_XIO) ; D0-E3
	dw	NGROUP:FVMINT01_INIB			 ; E4 = IN AL,xx
	dw	NGROUP:FVMINT01_INIW			 ; E5 = IN AX,xx
	dw	NGROUP:FVMINT01_OUTIB			 ; E6 = OUT xx,AL
	dw	NGROUP:FVMINT01_OUTIW			 ; E7 = OUT xx,AX
	dw	(1+0EBh-0E8h) dup (NGROUP:FVMINT01_XIO) ; E8-EB
	dw	NGROUP:FVMINT01_INDB			 ; EC = IN AL,DX
	dw	NGROUP:FVMINT01_INDW			 ; ED = IN AX,DX
	dw	NGROUP:FVMINT01_OUTDB			 ; EE = OUT DX,AL
	dw	NGROUP:FVMINT01_OUTDW			 ; EF = OUT DX,AX
	dw	(1+0F1h-0F0h) dup (NGROUP:FVMINT01_XIO) ; F0-F1
	dw	NGROUP:FVMINT01_REPNE			 ; F2 = REPNE
	dw	NGROUP:FVMINT01_REPE			 ; F3 = REPE

@OPLO	equ	  9Dh		; Lowest opcode value in table
@OPHI	equ	0F3h		; Highest ...

MODE_STR struc

MODE_FM db	?		; Mode # from
MODE_TO db	?		; Mode # to
MODE_CRTC dw	?		; CRT controller address for new mode
MODE_IVMFM db	?		; From initial video mode flags (see I11.INC)
MODE_IVMTO db	?		; To ...
MODE_CMD db	?		; Value to use in AH
MODE_CUR dw	?		; Value to use in CX
MODE_PTR dw	?		; Offset into IODATA
MODE_LEN dw	?		; Length of IODATA values

MODE_STR ends

@CO80	equ	@I11_CO80 shl $I11_IVM
@MONO	equ	@I11_MONO shl $I11_IVM

	public	MODE_DATA
MODE_DATA MODE_STR <10h,03h,03D4h,@CO80,@CO80,@SETMOD,0> ; Hires graf to color text
	MODE_STR  <07h,07h,03B4h,@MONO,@MONO,@SETMOD,0> ; Mono	text to mono  text
	MODE_STR  <10h,10h,03D4h,@CO80,@CO80,@SETMOD,0> ; Hires graf to hires graf
; Cursor commands
CO80_NRMMODE label tbyte
	MODE_STR  <03h,03h,03D4h,@CO80,@CO80,@SETTYP,@CUR_CLR and 0FFFFh> ; Color text to color text
CO80_INSMODE label tbyte
	MODE_STR  <03h,03h,03D4h,@CO80,@CO80,@SETTYP,@CUR_CLR shr 16>	   ; Color text to color text
MONO_NRMMODE label tbyte
	MODE_STR  <07h,07h,03B4h,@MONO,@MONO,@SETTYP,@CUR_MDA and 0FFFFh> ; Mono  text to mono	text
MONO_INSMODE label tbyte
	MODE_STR  <07h,07h,03B4h,@MONO,@MONO,@SETTYP,@CUR_MDA shr 16>	   ; Mono  text to mono  text
NMODES	equ	($-MODE_DATA)/(type MODE_STR) ; # modes to test

	public	FVM_FLAG
FVM_FLAG dw	0		; Local flags
@FVM_I01  equ	8000h		; 1 = INT 01h active
@FVM_VR   equ	4000h		; 1 = last command was IN AL,3B4 or 3D4

NDATA	ends			; End NDATA segment


NCODE	segment use16 para public 'ncode' ; Start NCODE segment
	assume	cs:NGROUP

	extrn	DISP_COPY:near
	extrn	U16_DRAINPIQ:near

	SETUP_ADAP_MAC	U16_	; Define in NGROUP
	ENABLE_ADAP_MAC U16_	; Define in NGROUP

	NPPROC	DVGA_INIT -- Initialize DVGA Adapter
	assume	ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Find and initialize DVGA adapter

On exit:

CF	=	0 if DVGA found
	=	1 otherwise

|

	REGSAVE <ax,bx,cx,dx,ds,es,fs> ; Save registers

	push	seg PGROUP	; Setup DS for resident code references
	pop	ds		; Address it
	assume	ds:PGROUP	; Tell the assembler about it

; Ensure it's an MCA

	test	SWATINI.MD_ATTR,@MD_MCA ; Izit an MCA-compatible?
	stc			; Assume not
	jz	near ptr DVGA_INIT_EXIT ; Jump if something went wrong (note CF=1)

	push	seg DGROUP	; Setup DS for resident data references
	pop	ds		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

; Find slot # of adapter ID 8102

	call	GET_ALLIDS	; Read and save all adapter IDs, check for 8102
	jc	near ptr DVGA_INIT_EXIT ; Jump if not found (note CF=1)

; Save current mode, cursor position and type

	VIDCALL @GETINF 	; Get video information
				; AL = mode
				; AH = # cols
				; BH = display page #
	mov	DVGA_MODE,al	; Save to restore later
	mov	DVGA_PAGE,bh	; ...

	VIDCALL @GETPOS 	; Read cursor position into (DH,DL)
				; and cursor type into (CH,CL)
	mov	DVGA_CURPOS,dx	; Save to restore later
	mov	DVGA_CURTYP,cx	; ...

; Disable the system board VGA

	call	DISABLE_SYSVGA	; Disable it

	cli			; Disallow interrupts

; Put the DVGA adapter into setup mode

	mov	bl,DVGA_SLOT	; Get the slot # (origin-0)
	call	U16_SETUP_ADAP	; Setup the adapter in slot BL

; Enable both sections

	mov	dx,102h 	; I/O port for POS[0]
	mov	al,@DVGA_ENA12	; POS[0] value to enable both sections
	out	dx,al		; Tell the DVGA about it
	call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue

	out	dx,al		; Tell the DVGA about it
	call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue

	call	U16_ENABLE_ADAP ; Enable adapter (disable setup)

; Put the DVGA adapter into setup mode

	mov	bl,DVGA_SLOT	; Get the slot # (origin-0)
	call	U16_SETUP_ADAP	; Setup the adapter in slot BL

; Enable section 1 only

	mov	dx,102h 	; I/O port for POS[0]
	mov	al,@DVGA_ENA1	; POS[0] value to enable section 1
	out	dx,al		; Tell the DVGA about it
	call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue

	out	dx,al		; Tell the DVGA about it
	call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue

	call	U16_ENABLE_ADAP ; Enable adapter (disable setup)

; Clear the DVGA memory for this section

	mov	al,03h		; Mark as mode 03h, clear regen buffer
	VIDCALL @SETMOD 	; Request video service

	call	DISP_COPY	; Display our copyright notice

; Put the DVGA adapter into setup mode

	mov	bl,DVGA_SLOT	; Get the slot # (origin-0)
	call	U16_SETUP_ADAP	; Setup the adapter in slot BL

; Enable section 2 only

	mov	dx,102h 	; I/O port for POS[0]
	mov	al,@DVGA_ENA2	; POS[0] value to enable section 2
	out	dx,al		; Tell the DVGA about it
	call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue

	out	dx,al		; Tell the DVGA about it
	call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue

	call	U16_ENABLE_ADAP ; Enable adapter (disable setup)

; Clear the DVGA memory for this section

	mov	al,03h		; Mark as mode 03h, clear regen buffer
	VIDCALL @SETMOD 	; Request video service

	call	DISP_COPY	; Display our copyright notice

; Put the DVGA adapter into setup mode

	mov	bl,DVGA_SLOT	; Get the slot # (origin-0)
	call	U16_SETUP_ADAP	; Setup the adapter in slot BL

; Disable the DVGA adapter

	mov	dx,102h 	; I/O port for POS[0]
	mov	al,@DVGA_ADIS	; POS[0] value to disable DVGA adapter
	out	dx,al		; Tell the DVGA about it
	call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue

	out	dx,al		; Tell the DVGA about it
	call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue

	call	U16_ENABLE_ADAP ; Enable adapter (disable setup)

; Enable the system board VGA

	call	ENABLE_SYSVGA	; Enable it

; Reset the video mode

	mov	al,DVGA_MODE	; Get original video mode
	or	al,@BIT7	; Mark as clearing regen buffer
	VIDCALL @SETMOD 	; Request video service

; Reset regen buffer save bit

	push	seg BIOSDATA	; Get segment of BIOS data area
	pop	fs		; Address it
	assume	fs:BIOSDATA	; Tell the assembler about it

	and	EGA_INFO,not @BIT7 ; Clear regen save bit

; Restore cursor position

	mov	bh,DVGA_PAGE	; Display page #
	mov	dx,DVGA_CURPOS	; Get original cursor position
	VIDCALL @SETPOS 	; Store cursor position from (DH,DL)

	mov	cx,DVGA_CURTYP	; Get original cursor type
	VIDCALL @SETTYP 	; Store cursor type from (CH,CL)

	sti			; Allow interrupts

	mov	fs,DVGA_SEG	; Get DVGA segment
	assume	fs:VGROUP	; Tell the assembler about it
	mov	VFN_VEC.VSEG,fs ; Save for later use
	mov	VFN_VEC.VOFF,0	; Start at offset zero

; Find I/O references to enable/disable the system board VGA

	mov	ah,@GETEGA	; Video function
	mov	bl,32h		; Function to enable/disable video
	mov	al,1		; Code to disable video
	call	FIND_VFN	; Find the I/O ports for video function

	mov	ah,@GETEGA	; Video function
	mov	bl,32h		; Function to enable/disable video
	mov	al,0		; Code to enable video
	call	FIND_VFN	; Find the I/O ports for video function

; Mark the last entry as @FVM_EOM

	mov	bx,VFN_VEC.VOFF ; Get next offset into IODATA
	mov	IODATA.FVM_CMD[bx],@FVM_EOM ; Mark as end-of-modes
	add	bx,size FVM_STR ; Skip over header
	mov	DVGA_CNT,bx	; Save as total length

	clc			; Indicate DVGA found
DVGA_INIT_EXIT:
	REGREST <fs,es,ds,dx,cx,bx,ax> ; Restore
	assume	ds:nothing,es:NGROUP ; Tell the assembler about it
	assume	fs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DVGA_INIT endp			; End DVGA_INIT procedure
	NPPROC	FIND_VFN -- Find I/O ports for Video Function
	assume	ds:DGROUP,es:NGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

Registers setup for video function

|

	REGSAVE <ax,di,ds,fs>	; Save for a moment

	lfs	di,VFN_VEC	; Get pointer to IODATA
	assume	fs:VGROUP	; Tell the assembler about it
	add	VFN_VEC.VOFF,size FVM_STR ; Skip over header

	mov	IODATA.FVM_MODE[di],al ; Save in structure
	mov	IODATA.FVM_CMD[di],ah ; Save in structure

	cmp	ah,@GETEGA	; Izit get EGA info?
	jne	short @F	; Jump if not

	mov	IODATA.FVM_CUR[di],bx ; Save in structure
@@:
	cmp	ah,@SETTYP	; Izit set cursor type?
	jne	short @F	; Jump if not

	mov	IODATA.FVM_CUR[di],cx ; Save in structure
@@:
	REGSAVE <di,ds> 	; Save for a moment

	push	seg NGROUP	; Setup ES for non-resident data references
	pop	ds		; Address it
	assume	ds:NGROUP	; Tell the assembler about it

	call	FINDIO		; Find the I/O ports for video function

	REGREST <ds,di> 	; Restore
	assume	ds:DGROUP	; Tell the assembler about it

	mov	ax,VFN_VEC.VOFF ; Get next available offset into IODATA
	sub	ax,di		; Less base to get length in bytes
				; (including header)
	mov	IODATA.FVM_SIZE.ELO[di],ax ; Save in structure
	mov	IODATA.FVM_SIZE.EHI[di],0

	REGREST <fs,ds,di,ax>	; Restore
	assume	ds:DGROUP,fs:nothing ; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_VFN endp			; End FIND_VFN procedure
	NPPROC	GET_ALLIDS -- Get All Adapter IDs, Check for DVGA
	assume	ds:DGROUP,es:NGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read and save all adapater iDs, check for DVGA (8102)

On exit:

CF	=	0 if DVGA found
	=	1 otherwise

|

	REGSAVE <ax,bx,cx,di>	; Save registers

	mov	cx,8		; Loop counter
	mov	bl,0		; Start with slot #0
	lea	di,MCAID	; ES:DI ==> adapter ID save area
@@:
	call	GET_POSID	; Return with AX = POS ID for slot BL (origin-0)
S16	stos	MCAID[di]	; Save in MCAID

	inc	bl		; Skip to next slot #

	LOOPS	@B		; Jump if more adapters to check

	mov	ax,8102h	; Look for this one
	mov	cx,8		; Loop counter
	lea	di,MCAID	; ES:DI ==> adapter ID save area
  repne scas	MCAID[di]	; Search for it
	stc			; Assume not found
	jne	short GET_ALLIDS_EXIT ; Jump if not found

	sub	cx,8		; Less # slots
	neg	cx		; Negate to get slot # (origin-1)
	dec	cx		; Convert to origin-0
	mov	DVGA_SLOT,cl	; Save for later use

	clc			; Mark as DVGA found
GET_ALLIDS_EXIT:
	REGREST <di,cx,bx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_ALLIDS endp 		; End GET_ALLIDS procedure
	NPPROC	GET_POSID -- Get POS ID For A Slot
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get the POS ID for a slot.

On entry:

BL	=	slot # (origin-0)

On exit:

AX	=	POS ID

|

	REGSAVE <dx>		; Save register

	pushf			; Save flags
	cli			; Disallow interrupts

	call	U16_SETUP_ADAP	; Setup the adapter in slot BL

	mov	dx,101h 	; Adapter ID MSB register
	in	al,dx		; Get MSB of adapter ID
	call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	ah,al		; Save for later use
	dec	dx		; Skip to adapter LSB register

	in	al,dx		; Get LSB of adapter ID
	call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue

	call	U16_ENABLE_ADAP ; Enable adapter (disable setup)

	popf			; Restore flags

	REGREST <dx>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_POSID endp			; End GET_POSID procedure
	NPPROC	DISABLE_SYSVGA -- Disable System Board VGA
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable system board VGA

|

	REGSAVE <ax,bx> 	; Save registers

	mov	bl,32h		; Function to enable/disable video
	mov	al,1		; Code to disable video
	VIDCALL @GETEGA 	; Request video services

	REGREST <bx,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISABLE_SYSVGA endp		; End DISABLE_SYSVGA procedure
	NPPROC	ENABLE_SYSVGA -- Enable System Board VGA
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable system board VGA

|

	REGSAVE <ax,bx> 	; Save registers

	mov	bl,32h		; Function to enable/disable video
	mov	al,0		; Code to enable video
	VIDCALL @GETEGA 	; Request video services

	REGREST <bx,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENABLE_SYSVGA endp		; End ENABLE_SYSVGA procedure
	NPPROC	SETUP_VID -- Setup For Video Functions
	assume	ds:NGROUP,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Setup for video functions.

|

	REGSAVE <ax,bx,es>	; Save registers

; Save old INT 01h handler to restore later

	mov	al,01h		; Intercept this one
	DOSCALL @GETINT 	; Return with ES:BX ==> old INT 01h handler
	assume	es:nothing	; Tell the assembler about it

	mov	FVMINT01_VEC.VOFF,bx ; Save to restore later
	mov	FVMINT01_VEC.VSEG,es

; Save old INT 10h handler to call later

	mov	al,10h		; Call this one
	DOSCALL @GETINT 	; Return with ES:BX ==> old INT 01h handler
	assume	es:nothing	; Tell the assembler about it

	mov	FVMINT10_VEC.VOFF,bx ; Save to use later
	mov	FVMINT10_VEC.VSEG,es

	REGREST <es,bx,ax>	; Restore
	assume	es:NGROUP	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_VID endp			; End SETUP_VID procedure
	NPPROC	FINDVID -- Find Video Mode I/O Ports
	assume	ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

Find interrupt vectors

|

	REGSAVE <ax,bx,cx,dx,si,ds,es,fs> ; Save registers

	push	seg NGROUP	; Setup DS for data references
	pop	ds		; Address it
	assume	ds:NGROUP	; Tell the assembler about it

	mov	fs,VIDEO_SEG	; Address the video tables
	assume	fs:VGROUP	; Tell the assembler about it
	mov	VFN_VEC.VSEG,fs ; Save for later use
	mov	VFN_VEC.VOFF,0	; Start at offset zero

; Address the BIOS data area

	push	seg BIOSDATA	; Get the segment #
	pop	es		; Address it
	assume	es:BIOSDATA	; Tell the assembler about it

; Save current mode to restore later

	mov	al,CRT_MODE	; Get current CRT mode
	mov	OLDFVMMODE,al	; Save to restore later

	mov	al,EQUIP_FLAG.LO ; Get initial video mode flags
	and	al,mask $I11_IVM ; Isolate the bits
	mov	OLDFVMIVM,al	; Save to restore later

; Loop through video modes

	xor	si,si		; Initialize index into MODE_DATA
	mov	cx,NMODES	; CX = # video modes to test
FINDVID_NEXT:
	and	EQUIP_FLAG.LO,not (mask $I11_IVM) ; Clear the bits
	mov	al,MODE_DATA.MODE_IVMFM[si] ; Get from initial video mode flags
	or	EQUIP_FLAG.LO,al ; Set new initial video mode flags
	mov	al,MODE_DATA.MODE_FM[si] ; Get the mode # from
	VIDCALL @SETMOD 	; Go to that mode

	and	EQUIP_FLAG.LO,not (mask $I11_IVM) ; Clear the bits
	mov	al,MODE_DATA.MODE_IVMTO[si] ; Get to initial video mode flags
	or	EQUIP_FLAG.LO,al ; Set new initial video mode flags

	mov	bx,VFN_VEC.VOFF ; Get next available offset into IODATA
	mov	MODE_DATA.MODE_PTR[si],bx ; Save in structure

	mov	al,MODE_DATA.MODE_TO[si] ; Get the mode # to
	mov	ah,MODE_DATA.MODE_CMD[si] ; Get the command

	push	cx		; Save for a moment

	mov	cx,MODE_DATA.MODE_CUR[si] ; Get the cursor type (if any)

	call	FIND_VFN	; Find the I/O ports for video function

	pop	cx		; Restore

	add	si,size MODE_STR ; Skip to next entry

	LOOPS	FINDVID_NEXT	; Jump if more modes to test

; Mark the last entry as @FVM_EOM

	mov	bx,VFN_VEC.VOFF ; Get next offset into IODATA
	mov	IODATA.FVM_CMD[bx],@FVM_EOM ; Mark as end-of-modes
	add	bx,size FVM_STR ; Skip over header
	mov	VIDEO_CNT,bx	; Save as total length

; Restore original video mode

	call	RESTMODE	; Restore it

; Save cursor type info

	push	seg DGROUP	; Setup DS for data references
	pop	es		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	ax,CO80_NRMMODE.MODE_CUR ; Get cursor type for normal CO80
	mov	CO80TYPE.ELO,ax ; Save for later use
	mov	ax,CO80_INSMODE.MODE_CUR ; Get cursor type for insert CO80
	mov	CO80TYPE.EHI,ax ; Save for later use

	mov	ax,MONO_NRMMODE.MODE_CUR ; Get cursor type for normal MONO
	mov	MONOTYPE.ELO,ax ; Save for later use
	mov	ax,MONO_INSMODE.MODE_CUR ; Get cursor type for insert MONO
	mov	MONOTYPE.EHI,ax ; Save for later use

	REGREST <fs,es,ds,si,dx,cx,bx,ax> ; Restore
	assume	ds:nothing,es:NGROUP,fs:nothing ; Tell the assembler about it

	ret			; Return to DOS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FINDVID endp			; End FINDVID procedure
	NPPROC	FINDIO -- Find I/O Ports For A Video Function
	assume	ds:NGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the I/O ports used to execute a particular video function.

On entry:

Registers setup for video command

|

	REGSAVE <ax,dx> 	; Save registers

; Install our own single-step interrupt handler

	mov	al,01h		; Intercept this one
	DOSCALL @SETINT,FVMINT01 ; Install our own one

	or	FVM_FLAG,@FVM_I01 ; Mark as active

	REGREST <dx,ax> 	; Restore

STK_STR struc

	dw	?		; Caller's BP
STK_ARG1 dw	?		; Argument #1

STK_STR ends

	pusha			; Save all GP registers

	pushf			; Simulate INT calling environment
	cli

	pushf			; Save flags
	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack
	or	[bp].STK_ARG1,mask $TF ; Set trap flag
	pop	bp		; Restore
	popf			; Put into effect

	call	FVMINT10_VEC	; Request hardware interrupt service

	popa			; Restore all GP registers

	and	FVM_FLAG,not @FVM_I01 ; Mark as inactive

	REGSAVE <ax,dx,ds>	; Save registers

	mov	al,01h		; Restore this one
	lds	dx,FVMINT01_VEC ; DS:DX ==> original handler
	assume	ds:nothing	; Tell the assembler about it
	DOSCALL @SETINT 	; Install our own one

	REGREST <ds,dx,ax>	; Restore
	assume	ds:NGROUP	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FINDIO	endp			; End FINDIO procedure
	FPPROC	FVMINT01 -- Single-step Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Single-step interrupt handler

|

INT01_STR struc

INT01_BP dw	?		; Caller's BP
INT01_IP dw	?		; ...	   IP
INT01_CS dw	?		; ...	   CS
INT01_FL dw	?		; ...	   FL
INT01_FL2 dw	?		; ...	   FL if CS:IP ==> POPF

INT01_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	test	FVM_FLAG,@FVM_I01 ; Izit active?
	jnz	short @F	; Jump if so

	and	[bp].INT01_FL,not (mask $TF) ; Clear trap flag

	jmp	FVMINT01_EXIT	; Join common exit code

@@:

COMMENT|

Check for next instruction as one of

OUT xx,AL	 Save I/O port #, and output value
OUT xx,AX
OUT DX,AL
OUT DX,AX

IN  AL,xx	 Save I/O port #
IN  AX,xx
IN  AL,DX
IN  AX,DX

POPF		 Set trap flag
IRET		 Set trap flag
INT		 Simulate instruction

|

FVMINT_STR struc

FVMINT_FS dw	?		; Caller's FS
FVMINT_ES dw	?		; ...	   ES
FVMINT_DS dw	?		; ...	   DS
FVMINT_DI dw	?		; ...	   DI
FVMINT_SI dw	?		; ...	   SI
FVMINT_BP dw	?		; ...	   BP
FVMINT_SP dw	?		; ...	   SP
FVMINT_BX dw	?		; ...	   BX
FVMINT_DX dw	?		; ...	   DX
FVMINT_CX dw	?		; ...	   CX
FVMINT_AX dw	?		; ...	   AX

FVMINT_STR ends

@FVMBACK equ	size FVMINT_STR

	pusha			; Save all GP registers
	REGSAVE <ds,es,fs>	; Save segment registers

	push	seg NGROUP	; Get data segment
	pop	ds		; Address it
	assume	ds:NGROUP	; Tell the assembler about it

	les	si,[bp].INT01_IP.EDD ; Get caller's CS:IP
	assume	es:nothing	; Tell the assembler about it

	lfs	di,VFN_VEC	; Get pointer to IODATA
	assume	fs:VGROUP	; Tell the assembler about it

	mov	IODATA.IO_VAL[di],ax ; Save value (if any)
	mov	IODATA.IO_PORT[di],dx ; Save I/O port # (if any)
FVMINT01_NEXT:
	movzx	bx,es:[si]	; Get first instruction byte

	cmp	bl,@OPHI	; Check against the upper limit
	ja	short FVMINT01_XIO0 ; Jump if too large

	sub	bl,@OPLO	; Check against lower limit
	jb	short FVMINT01_XIO0 ; Jump if too small

	shl	bx,1		; Times two to index table of words

	jmp	FVMINT01_ACT[bx]  ; Take appropriate action


; INT:	Skip over INT xx, push address onto stack to retain control

FVMINT01_INT:
	movzx	bx,es:[si+1]	; Get interrupt # from next instruction byte

	shl	bx,2-0		; Convert from dwords to bytes
	mov	si,sp		; SS:SI ==> source
	sub	sp,3*2		; Make room on the stack

	add	[bp].INT01_IP,2 ; Skip over the INT instruction

	push	ss		; Get stack segment
	pop	es		; Address it
	assume	es:nothing	; Tell the assembler about it

	mov	di,sp		; ES:DI ==> destin
	lea	cx,[bp].INT01_IP ; Get offset of top of local stack
	sub	cx,si		; Less start of source to get length of move
S16 rep movs	<es:[di].LO,ss:[si].LO> ; Move the stack down
	sub	bp,3*2		; Move down as well

	push	seg INTVEC	; Get interrupt vector table segment
	pop	es		; Address it
	assume	es:INTVEC	; Tell the assembler about it

	mov	ax,INT00_VEC.VOFF[bx] ; Get offset
	mov	[bp].INT01_IP,ax ; Save on stack

	mov	ax,INT00_VEC.VSEG[bx] ; Get segment
	mov	[bp].INT01_CS,ax ; Save on stack

	mov	ax,[bp+3*2].INT01_FL ; Get caller's flags
	and	ax,not (mask $IF) ; Ensure interrupts disabled
	or	ax,mask $TF	; Ensure trap flag set
	mov	[bp].INT01_FL,ax ; Save on stack
FVMINT01_XIO0:
	jmp	FVMINT01_XIO	; Join common code

	assume	es:nothing	; Tell the assembler about it


; IN AL,DX

FVMINT01_INDB:

; Check for IN AL,03DA or 03BAh -- assumed to be check for vertical retrace
; Ignore if found

	cmp	dx,03DAh	; Izit color status register?
	je	short FVMINT01_VR ; Jump if so

	cmp	dx,03BAh	; Izit mono ...
	jne	short @F	; Jump if not
FVMINT01_VR:
	test	FVM_FLAG,@FVM_VR ; Last command check for vertical retrace?
	jnz	near ptr FVMINT01_XIO ; Yes, so ignore it

	or	FVM_FLAG,@FVM_VR ; Mark as last command
@@:
	mov	IODATA.IO_FLAG[di],@IO_INP ; Mark as byte input

	jmp	FVMINT01_COM	; Join common code


; IN AX,DX

FVMINT01_INDW:
	mov	IODATA.IO_FLAG[di],@IO_INP or @IO_WORD ; Mark as word input

	jmp	FVMINT01_COM	; Jump common code


; OUT DX,AX

FVMINT01_OUTDW:
	mov	IODATA.IO_FLAG[di],@IO_WORD ; Mark as word output

	jmp	FVMINT01_COM	; Jump common code


; IN AL,xx

FVMINT01_INIB:
	mov	IODATA.IO_FLAG[di],@IO_INP ; Mark as byte input

	jmp	short FVMINT01_IMM ; Jump common code


; IN AX,xx

FVMINT01_INIW:
	mov	IODATA.IO_FLAG[di],@IO_INP or @IO_WORD ; Mark as word input

	jmp	short FVMINT01_IMM ; Jump common code


; OUT xx,AX

FVMINT01_OUTIW:
	mov	IODATA.IO_FLAG[di],@IO_WORD ; Mark as word output

	jmp	short FVMINT01_IMM ; Jump common code


; OUT xx,AL

FVMINT01_OUTIB:
	mov	IODATA.IO_FLAG[di],0 ; Mark as byte output

; The I/O instruction uses an immediate port #

FVMINT01_IMM:
	movzx	ax,es:[si+1]	; Get port # from next instruction byte
	mov	IODATA.IO_PORT[di],ax ; Save I/O port #

	jmp	short FVMINT01_COM1 ; Join common code


; REPNE:  skip over, process next byte
; REPE:  skip over, process next byte

FVMINT01_REPNE:
FVMINT01_REPE:
	cmp	[bp-@FVMBACK].FVMINT_CX,0 ; Izit zero?
	je	short FVMINT01_XIO ; Jump if so

	inc	si		; Skip over it

	jmp	FVMINT01_NEXT	; Go around again


; MOVSB:  if ES = A000, save offset and value,
; then attempt to merge with previous record

FVMINT01_MOVSB:
	cmp	[bp-@FVMBACK].FVMINT_ES,0A000h ; Izit in A000?
	jne	short FVMINT01_XIO ; Jump if not

	mov	IODATA.IO_FLAG[di],@IO_MOVE ; Mark as byte move

	mov	ax,[bp-@FVMBACK].FVMINT_DI ; Get the offset
	mov	IODATA.IO_PORT[di],ax ; Save in IODATA

	push	es		; Save for a moment

	mov	es,[bp-@FVMBACK].FVMINT_DS ; Get source segment
	assume	es:nothing	; Tell the assembler about it

	mov	bx,[bp-@FVMBACK].FVMINT_SI ; ...	 offset
	mov	al,es:[bx]	; Get source byte

	pop	es		; Restore
	assume	es:nothing	; Tell the assembler about it

	mov	IODATA.IO_VAL.LO[di],al ; Save in IODATA

	jmp	short FVMINT01_COM1 ; Join common code


; MOVSW:  if ES = A000, save offset and value,
; then attempt to merge with previous record

FVMINT01_MOVSW:
	cmp	[bp-@FVMBACK].FVMINT_ES,0A000h ; Izit in A000?
	jne	short FVMINT01_XIO ; Jump if not

	mov	IODATA.IO_FLAG[di],@IO_MOVE or @IO_WORD ; Mark as byte move

	mov	ax,[bp-@FVMBACK].FVMINT_DI ; Get the offset
	mov	IODATA.IO_PORT[di],ax ; Save in IODATA

	push	es		; Save for a moment

	mov	es,[bp-@FVMBACK].FVMINT_DS ; Get source segment
	assume	es:nothing	; Tell the assembler about it

	mov	bx,[bp-@FVMBACK].FVMINT_SI ; ...	 offset
	mov	ax,es:[bx]	; Get source word

	pop	es		; Restore
	assume	es:nothing	; Tell the assembler about it

	mov	IODATA.IO_VAL[di],ax ; Save in IODATA

	jmp	short FVMINT01_COM1 ; Join common code


; POPF:  set trap flag in flags to ensure we retain control.

FVMINT01_POPF:
	or	[bp].INT01_FL2,mask $TF ; Ensure trap flag set

	jmp	short FVMINT01_XIO ; Join common code


; IRET:  set trap flag in flags to ensure we retain control.

FVMINT01_IRET:
	or	[bp+4].INT01_FL2,mask $TF ; Ensure trap flag set

	jmp	short FVMINT01_XIO ; Join common code


; OUT DX,AL

FVMINT01_OUTDB:
	mov	IODATA.IO_FLAG[di],0 ; Mark as byte output
FVMINT01_COM:
	cmp	dx,0400h	; Check for out of bounds
	jae	short FVMINT01_XIO ; Jump if too large
FVMINT01_COM1:
	add	VFN_VEC.VOFF,size IO_STR ; Skip to next entry
FVMINT01_XIO:
	REGREST <fs,es,ds>	; Restore segment registers
	assume	ds:nothing,es:nothing,fs:nothing ; Tell the assembler about it
	popa			; Restore all GP registers
FVMINT01_EXIT:
	pop	bp		; Restore

	iret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FVMINT01 endp			; End FVMINT01 procedure
	NPPROC	RESTMODE -- Restore Original Video Mode
	assume	ds:NGROUP,es:nothing,ss:nothing
COMMENT|

Restore original video mode.

|

	REGSAVE <ax,es> 	; Save registers

; Address the BIOS data area

	mov	ax,seg BIOSDATA ; Get the segment #
	mov	es,ax		; Restore
	assume	es:BIOSDATA	; Tell the assembler about it

; Restore original video mode

	and	EQUIP_FLAG.LO,not (mask $I11_IVM) ; Clear the bits
	mov	al,OLDFVMIVM	; Get old initial video mode flags
	or	EQUIP_FLAG.LO,al ; Set new initial video mode flags
	mov	al,OLDFVMMODE	; Get old mode #
	VIDCALL @SETMOD 	; Request video service

	REGREST <es,ax> 	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,ss:nothing

RESTMODE endp			; End RESTMODE procedure

NCODE	ends			; End NCODE segment

	MEND			; End SWAT_FVM module
