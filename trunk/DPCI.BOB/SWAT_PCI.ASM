;' $Header$
	title	SWAT_PCI -- 386SWAT PCI Routines
	page	58,122
	name	SWAT_PCI

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1999 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, June, 1999.

Modifications by:  None.


|
.386p
.xlist
	include MASM.INC
	include PTR.INC
	include VIDCALL.INC
	include INTVEC.INC
	include 386.INC
	include PCI.INC
	include BIOSDATA.INC
	include VIDATTR.INC
	include ASCII.INC
	include 6845.INC

	include SWAT_COM.INC
	include SWAT_SEG.INC
	include SWAT_VID.INC
.list

VIDEO_BIOS segment use16 at 0C000h

VIDEO_SIG dw	0AA55h		; ROM signature
VIDEO_SIZE db	?		; Initialization size in units of 512 bytes
VIDEO_INIT label far

VIDEO_BIOS ends


VBDIND	macro	REG,DISP

	imul	REG,DISP,type VIDEO_BIOS_DATA ; Times size of struc for index

	endm			; VBDIND


DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	public	@SWAT_PCI_DATA16
@SWAT_PCI_DATA16 label byte	; Mark module start in .MAP file

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

VIDEO_BIOS_DATA struc

; The following three fields are accessed as a dword,
; so don't change their order.
VBD_ADDR     dw ?		; Mech #2 I/O port address
VBD_BUSNUM   db ?		; Mech #2 bus number
VBD_ACCESS   db ?		; Pad to allow DWORD for mech #1 access key

VBD_CURSOR   dw ?		; Cursor position just prior to disabling
VBD_DEVFN    db ?		; 7-3=device #, 2-0=function #
VBD_BUSNO    db ?		; Bus #
VBD_CMD      dw ?		; Command register
VBD_CTL      dw ?		; Control register (bridge only)
VBD_EROM     dd ?		; Expansion ROM base address

VIDEO_BIOS_DATA ends


DPCI_DIRECT equ 1		; 0 = 1 BIOS, 1 = direct

	public	VBDSTR,VBDAGP
VBDSTR	VIDEO_BIOS_DATA <>	; First display adapter
	VIDEO_BIOS_DATA <>	; Second ...
	VIDEO_BIOS_DATA <>	; Third ...
VBDAGP	VIDEO_BIOS_DATA <>	; AGP controller (if present)

; The following four variables describe the display adapters
; in which we're interested.  The first two are static values;
; the second two are dynamic.  The primary adapter is the one
; which is active when we boot up.  The secondary adapter is
; the one on which SWAT displays its data.

	public	PriDisp,SecDisp
PriDisp dd	?		; Primary display adapter # (origin-0)
SecDisp dd	?		; Secondary ...

	public	ActDisp,InaDisp
ActDisp dd	?		; Active display # (origin-0)
InaDisp dd	?		; Inactive ...

	public	DisableAGPCount
DisableAGPCount dd 0		; Count of active AGP disables (0=none)

	public	PCI_Version,PCI_HW_Char,PCI_HW_Acc
PCI_Version dw	?		; PCI version #
PCI_HW_Char db	?		; PCI HW characteristics
PCI_HW_Acc db	?		; PCI HW access method (1 or 2)

@PCI_HW_ACC1 equ 1		; Access method #1
@PCI_HW_ACC2 equ 2		; ...		 2

DATA16	 ends			; End DATA16 segment


NDATA	segment use16 dword public 'ndata' ; Start NDATA segment
	assume	ds:NGROUP

	public	@SWAT_PCI_NDATA
@SWAT_PCI_NDATA label byte	; Mark module start in .MAP file

	extrn	MSG_COPY:byte

	public	MonoTextData
MonoTextData db 61h,50h,52h,0Fh,19h,06h,19h,19h,02h,0Dh,0Bh,0Ch,00h,00h,00h,00h
MonoTextDataLen equ $-MonoTextData ; Length of ...

NDATA	ends			; End NDATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP

	extrn	U32_DRAINPIQ:near

PROG	ends			; End PROG segment


NCODE	segment use16 para public 'ncode' ; Start NCODE segment
	assume	cs:NGROUP,ds:NGROUP

	extrn	CHK_CREG:near
	extrn	U16_DRAINPIQ:near

	public	@SWAT_PCI_NCODE
@SWAT_PCI_NCODE:		; Mark module start in .MAP file

	NPPROC	CHECK_PCI_BIOS -- Check On PCI BIOS
	assume	ds:NGROUP,es:NGROUP,fs:DGROUP,gs:PGROUP,ss:nothing
COMMENT|

Is there a PCI BIOS installed?

On exit:

Fill in various fields if installed.

|

	pushad			; Save all EGP registers

	PCICALL @PCI_INST	; Is PCI BIOS installed?
				; Return with EDX = ' ICP'
				; ...	      AH = @PCIERR_OK
				; ...	      AL = PCI HW characteristics
				; ...	      BH = PCI interface level, major ver
				; ...	      BL = ...			minor ...
				; ...	      CL = # last PCI bus in system
	cmp	ah,@PCIERR_OK	; Izit installed?
	jne	short CHECK_PCI_BIOS_EXIT ; Jump if not

	cmp	edx,@PCISIG	; Izit PCI BIOS?
	jne	short CHECK_PCI_BIOS_EXIT ; Jump if not

	mov	PCI_HW_Char,al	; Save for later use
	mov	PCI_Version,bx	; ...

	test	al,mask $PCIHW_CSA1 ; Access mechanism #1 supported?
	mov	bl,@PCI_HW_ACC1 ; Assume so
	jnz	short @F	; Jump if so

	test	al,mask $PCIHW_CSA2 ; Access mechanism #2 supported?
	jz	short CHECK_PCI_BIOS_EXIT ; Jump if not

	mov	bl,@PCI_HW_ACC2 ; Assume so
@@:
	mov	PCI_HW_Acc,bl	; Save for later use

	or	LCL_FLAG,@LCL_PCI ; Mark as PCI BIOS present

; Check on dual PCI VGA adapters

	call	CHECK_DPCI	; Check it

; If the primary and secondary VGA adapters are on different busses, find
; the AGP controller so we can enable/disable it when we enable/disable the
; corresponding VGA adapter.

	test	LCL_FLAG,@LCL_DPCI ; Are there dual PCI VGA adapters?
	jz	short CHECK_PCI_BIOS_EXIT ; Jump if not

	VBDIND	esi,PriDisp	; Get index into VBDSTR of primary adapter
	mov	al,VBDSTR[esi].VBD_BUSNO ; Get the bus #

	VBDIND	esi,SecDisp	; Get index into VBDSTR of secondary adapter
	mov	ah,VBDSTR[esi].VBD_BUSNO ; Get the bus #

	cmp	al,ah		; Are they on the same bus?
	je	short CHECK_PCI_BIOS_EXIT ; Jump if so

	call	FindAGP 	; Find the AGP controller
CHECK_PCI_BIOS_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PCI_BIOS endp		; End CHECK_PCI_BIOS procedure
	NPPROC	CHECK_DPCI -- Check On Dual PCI VGA Adapters
	assume	ds:NGROUP,es:NGROUP,fs:DGROUP,gs:PGROUP,ss:nothing
COMMENT|

Check on dual PCI VGA adapters

|

	pushad			; Save all EGP registers

	xor	esi,esi 	; Initialize device index
CHECK_DPCI_NEXT:
	call	FindPCI_VGA	; Find next PCI VGA adapter, SI = device index
				; Return with BH = bus #
				; ...	      BL[7:3] = device #
				; ...	      BL[2:0] = function #
				; ...	      CX = command register value
	jc	short CHECK_DPCI_DONE ; Jump if that's all

	test	cx,@PCICMD_IO or @PCICMD_MEM ; Is I/O or memory enabled?
	jz	short @F	; Jump if not

	mov	ActDisp,esi	; Save as active display adpater (origin-0)
	mov	PriDisp,esi	; ...	  primary ...
@@:
	mov	dl,PCIREG00_CMD ; Command register #
	call	ConvertDeviceAddress ; Convert to direct addressing format

	VBDIND	edx,esi 	; Get index into VBDSTR
	mov	VBDSTR[edx].VBD_ADDR.EDD,eax ; Save for later use
	mov	VBDSTR[edx].VBD_BUSNO,bh ; ...
	mov	VBDSTR[edx].VBD_DEVFN,bl ; ...
	mov	VBDSTR[edx].VBD_CMD,cx ; ...

; Read in the Expansion ROM register and save it

	mov	di,PCIREG00_EROM ; Register # (Expansion ROM)
	PCICALL @PCI_RDDWORD	; Read PCI configuration dword: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; Return with ECX = dword register
	mov	VBDSTR[edx].VBD_EROM,ecx ; Save for later use

	inc	esi		; Mark as found another VGA card

	jmp	CHECK_DPCI_NEXT ; Go around again

CHECK_DPCI_DONE:
	cmp	esi,2		; Did we find two or more PCI VGA cards?
	jb	short CHECK_DPCI_EXIT ; Jump if not

; Save as the secondary display adapter the last display adapter
; which is not the primary display adpater

	dec	esi		; Convert from count to origin-0 index
				; of the last adapter
	cmp	esi,ActDisp	; Is the last display adapter the active one?
	jne	short @F	; Jump if not

	dec	esi		; Back off to the last inactive adapter
@@:
	mov	InaDisp,esi	; Save as inactive display adapter # (origin-0)
	mov	SecDisp,esi	; ...	  secondary ...

	or	LCL_FLAG,@LCL_DPCI ; Mark as dual PCI VGA adapters present
CHECK_DPCI_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DPCI endp 		; End CHECK_DPCI procedure
	NPPROC	FindAGP -- Find AGP Controller
	assume	ds:NGROUP,es:NGROUP,fs:DGROUP,gs:PGROUP,ss:nothing
COMMENT|

Find AGP controller

|

	pushad			; Save registers

	xor	esi,esi 	; Initialize device index
FindAGPNext:
	mov	ecx,(@PCICLS_BRIDGE	shl $PCIFC_CLS) or \
		    (@PCISUB_BRIDGE_PCI shl $PCIFC_SUB) or \
		    (0			shl $PCIFC_IF)
	PCICALL @PCI_FINDCLASS	; Izit installed?
				; Return with AH = 00
				; ...	      BH = bus #
				; ...	      BL = 7-3=device #, 2-0=function #
	cmp	ah,@PCIERR_BADDEV ; Izit a bad device?
	je	short FindAGPExit ; Jump if so

	mov	di,PCIREG00_HDRTYPE ; Register # (Header Type)
	PCICALL @PCI_RDBYTE	; Read PCI configuration byte: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; Return with CL = byte register
	cmp	cl,@PCIHDRTYPE_BRIDGE ; Izit a bridge header?
	jne	short FindAGPLoop ; Jump if not

; Ensure that this controller has the VGA_EN bit set

	mov	di,PCIREG01_CTL ; Register # (Bridge Control)
	PCICALL @PCI_RDWORD	; Read PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; Return with CX = word register
	test	cx,@PCI_BRIDGECTL_VGA_EN ; Izit set?
	jz	short FindAGPLoop ; Jump if not

	mov	VBDAGP.VBD_CTL,cx ; Save for later use

; Read command register

	mov	di,PCIREG01_CMD ; Register # (Command)
	PCICALL @PCI_RDWORD	; Read PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; Return with CX = word register
	mov	dl,PCIREG01_CMD ; Command register #
	call	ConvertDeviceAddress ; Convert to direct addressing format

	mov	VBDAGP.VBD_ADDR.EDD,eax ; Save for later use
	mov	VBDAGP.VBD_DEVFN,bl ; ...
	mov	VBDAGP.VBD_BUSNO,bh ; ...
	mov	VBDAGP.VBD_CMD,cx ; ...

	or	LCL_FLAG,@LCL_AGP ; Mark as present

	jmp	short FindAGPExit ; Join common exit code

FindAGPLoop:
	inc	esi		; Skip to next device

	jmp	FindAGPNext	; Go around again

FindAGPExit:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FindAGP endp			; End FindAGP procedure
	NPPROC	ConvertDeviceAddress -- Convert Device Address
	assume	ds:NGROUP,es:NGROUP,fs:DGROUP,gs:PGROUP,ss:nothing
COMMENT|

Convert device address to configuration address dword
to be used with direct I/O to the configuration address space.

From Ralf Brown's example code.

On entry:

BH	=	bus #
BL	=	device/func #
DL	=	PCI register #

On exit:

EAX	=	device address for use by resident code

|

	mov	eax,(mask $PCICFGADDR_ENA) shr 8
	mov	ax,bx		; EAX[15..8] = bus #
				; EAX[7..3] = device #
				; EAX[2..0] = function #
	shl	eax,8		; EAX[23..16] = bus #
				; EAX[15..11] = device #
				; EAX[10..8] = function #
	mov	al,dl		; EAX[7..0] = register #

	cmp	PCI_HW_Acc,@PCI_HW_ACC1 ; Izit config mech #1?
	je	short CDA_EXIT	; Jump if so (we're done)

	shr	ah,3		; Shift down the device #
	and	ah,00Fh 	; Limit device # to four bits
	or	ah,0C0h 	; Set special bits

	push	ebx		; Save for a moment

	and	bl,07h		; Isolate function #
	shl	ebx,24		; Shift to upper byte
	or	eax,ebx 	; Add function # to access key

	pop	ebx		; Restore
CDA_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ConvertDeviceAddress endp	; End ConvertDeviceAddress procedure
if 0
	NPPROC	SetDisplayState -- Set Display State
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

CX	=	command register bits to set
ES:EDI	==>	VBD struc

|

	REGSAVE <eax,dx>	; Save registers

	cmp	PCI_HW_Acc,2	; Izit configuration mechanism #2
	je	short config_mech_2 ; Jump if so

;-- configuration access mechanism 1

	mov	eax,es:[edi].VBD_ADDR.EDD
	mov	dx,PCI_MECH1_ADDR
	out	dx,eax
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	dx,PCI_MECH1_DATA
	in	ax,dx
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	and	ax,not PCI_CMDREG_BITS
	or	ax,cx
	out	dx,ax
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	xor	eax,eax 	; Close configuration space again
	mov	dx,PCI_MECH1_ADDR
	out	dx,eax
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	jmp	short SetDisplayStateExit

;-- configuration access mechanism 2

config_mech_2:
	mov	al,es:[edi].VBD_ACCESS ; open configuration space
	mov	dx,PCI_MECH2_CFGSP
	out	dx,al
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	al,es:[edi].VBD_BUSNUM ; select proper PCI bus
	mov	dx,PCI_MECH2_BUSNO
	out	dx,al
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	dx,es:[edi].VBD_ADDR
	in	ax,dx
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	and	ax,not PCI_CMDREG_BITS	; flip the 'enable' bits
	or	ax,cx
	out	dx,ax
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	al,00h			; close configuration space
	mov	dx,PCI_MECH2_CFGSP
	out	dx,al
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
SetDisplayStateExit:
	REGREST <dx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SetDisplayState endp		; End SetDisplayState procedure
endif				; IF DPCI_DIRECT
	NPPROC	VideoCheck -- Check Out Video Adapter Possibilities
	assume	ds:NGROUP,es:NGROUP,fs:DGROUP,gs:PGROUP,ss:nothing
COMMENT|

Check out video adapter possibilities

|

	pushad			; Save all EGP registers
COMMENT|

If the user said mono, but we didn't detect a mono adapter, and we're
in a PCI system and there's an AGP controller, disable the AGP
controller and check for a mono adapter hidden by the PCI adapter.

|
	test	LCL_FLAG,@LCL_MONO ; Did the user say the magic word?
	jz	short VideoCheckNoPCI ; Jump if not

	test	LCL_FLAG,@LCL_MDA ; Did we already detect a mono adapter?
	jnz	short VideoCheckNoPCI ; Jump if so

	test	LCL_FLAG,@LCL_PCI ; Is PCI BIOS present?
	jz	short VideoCheckNoPCI ; Jump if not

	test	LCL_FLAG,@LCL_AGP ; Is AGP present?
	jz	short VideoCheckNoPCI ; Jump if not

	call	U16_DisableDispAGP ; Disable the primary display and AGP

	mov	dx,@CRT_MDA	; Address register of monochrome 6845

	call	CHK_CREG	; Check cursor register
	jc	short @F	; It's not present

	or	LCL_FLAG,@LCL_MDA or @LCL_PCIMDA or @LCL_PCIMDS ; Mark as present
	and	LCL_FLAG,not @LCL_DPCI ; Mark as no longer to be used
@@:
	call	U16_EnableDispAGP ; Enable the primary display and AGP
VideoCheckNoPCI:






	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VideoCheck endp 		; End VideoCheck procedure
	NPPROC	SetupMDA -- Setup MDA
	assume	ds:NGROUP,es:NGROUP,fs:DGROUP,gs:PGROUP,ss:nothing
COMMENT|

Setup MDA if present

|

	test	LCL_FLAG,@LCL_MDA ; Izit present?
	jz	short SetupMDAExit ; Jump if not

	test	LCL_FLAG,@LCL_AGP ; Izit present?
	jz	short SetupMDAExit ; Jump if not

	call	U16_DisableDispAGP ; Disable the primary display and AGP

	call	MonoTextMode	; Setup monochrome text mode
	call	U16_EnableMonoText ; Enable mono text mode

; DO NOT call Set Video Mode here!!

	REGSAVE <ax,cx,di,es>	; Save for a moment

	mov	ax,0B000h	; Get monochrome video segment
	mov	es,ax		; Address it
	assume	es:nothing	; Tell the assembler about it

; Initialize the video memory to all blanks

	mov	cx,@NROWS * @NCOLS ; Write this many times
	xor	di,di		; ES:DI ==> start of mono buffer
	mov	ax,(@ATMnorm shl 8) or ' ' ; Write this
    rep stos	es:[di].ELO	; Smear values to the screen

	call	DISP_COPY_MONO	; Display our copyright notice on mono screen

	REGREST <es,di,cx,ax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	call	U16_DisableMonoText ; Disable mono text mode
	call	U16_EnableDispAGP ; Enable the primary display and AGP
SetupMDAExit:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SetupMDA endp			; End SetupMDA procedure
	NPPROC	MonoTextMode -- Setup Monochrome Text Mode
	assume	ds:NGROUP,es:NGROUP,fs:DGROUP,gs:PGROUP,ss:nothing
COMMENT|

Setup monochrome text mode

|

	REGSAVE <ax,cx,dx,si>	; Save registers

	cld

;;;;;;; MOV	DX, 03BFH
;;;;;;; MOV	AL, 0FFH
;;;;;;; OUT	DX, AL
;;;;;;; call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue
;;;;;;;
	lea	si,MonoTextData ; DS:SI ==> mono text data values
	mov	cx,MonoTextDataLen ; Get # data values
	mov	ah,0		; Initialize register index
MonoTextModeNext:
	mov	al,ah		; Copy register index value
	mov	dx,@CRT_MDA	; Get index register
	out	dx,al		; Output index value
	call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue

	lods	MonoTextData[si] ; Get next data byte
	inc	dx		; Skip to data register
	out	dx,al		; Output data value
	call	U16_DRAINPIQ	; Drain the Prefetch Instruction Queue

	inc	ah		; Skip to next register index

	loop	MonoTextModeNext ; Jump if mode data values

	REGREST <si,dx,cx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MonoTextMode endp		; End MonoTextMode procedure
	NPPROC	DISP_COPY_MONO -- Display Our Copyright Notice on the Monochrome Screen
	assume	ds:NGROUP,es:nothing,fs:DGROUP,gs:PGROUP,ss:nothing
COMMENT|

Display our copyright notice on the monochrome screen

On entry:

ES:0	==>	B000:0

|

	REGSAVE <ax,dx,si,di>	; Save registers

	lea	si,MSG_COPY	; DS:SI ==> copyright notice
	xor	di,di		; ES:DI ==> monoscreen
DISP_COPY_MONO_NEXT0:
	mov	ah,@ATMnorm	; Get normal attribute
DISP_COPY_MONO_NEXT:
	lods	MSG_COPY[si]	; Get next char

	cmp	al,EOS		; Izit EOS?
	je	short DISP_COPY_MONO_EXIT ; Jump if so

	cmp	al,CR		; Izit CR?
	jne	short @F	; Jump if not

	xor	dx,dx		; Zereo to use DX:AX as dword
	mov	ax,di		; Copy dividend
	mov	di,@NCOLS * 2	; Get # columns of (char,attr)
	div	di		; Divide to get AX = row #, DX = col #
	imul	di,ax,2 	; Convert from (char,attr) to bytes

	jmp	DISP_COPY_MONO_NEXT0 ; Go around again

@@:
	cmp	al,LF		; Izit LF?
	jne	short @F	; Jump if not

	add	di,@NCOLS * 2	; Skip to new line

	jmp	DISP_COPY_MONO_NEXT ; Go around again

@@:
	stos	es:[di].ELO	; Store on screen

	jmp	DISP_COPY_MONO_NEXT ; Go around again

DISP_COPY_MONO_EXIT:
	REGREST <di,si,dx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_COPY_MONO endp		; End DISP_COPY_MONO procedure
	NPPROC	FindPCI_VGA -- Find The Next PCI VGA Adapter
	assume	ds:NGROUP,es:NGROUP,fs:DGROUP,gs:PGROUP,ss:nothing
COMMENT|

Find the next PCI VGA adapter

On entry:

ESI	=	device index (origin-0)

On exit:

CF	=	0 if found
	=	1 if not

BH	=	bus #
BL[7:3] =	device #
BL[2:0] =	function #
CX	=	command register value

|

	REGSAVE <ax,di> 	; Save registers

	push	ecx		; Save register

	mov	ecx,(@PCICLS_DISP     shl $PCIFC_CLS) or \
		    (@PCISUB_DISP_VGA shl $PCIFC_SUB) or \
		    (0		      shl $PCIFC_IF)
	PCICALL @PCI_FINDCLASS	; Izit installed?
				; Return with AH = 00
				; ...	      BH = bus #
				; ...	      BL = 7-3=device #, 2-0=function #
	pop	ecx		; Restore

	cmp	ah,@PCIERR_BADDEV ; Izit a bad device?
	stc			; Assume so
	je	short FindPCI_VGA_EXIT ; Jump if so

	mov	di,PCIREG00_CMD ; Register # (Command)
	PCICALL @PCI_RDWORD	; Read PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; Return with CX = word register
	clc			; Mark as successful
FindPCI_VGA_EXIT:
	REGREST <di,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FindPCI_VGA endp		; End FindPCI_VGA procedure

NCODE	ends			; End NCODE segment


PCIFNS_MAC macro PREF,W,E

	NPPROC	PREF&PCI_WRWORD -- PCI Write Word Function
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PCI write word

Note that the register # must be on a word boundary.

|

PREF&PWR_STR struc

	W	?		; Caller's eBP
	W	?		; ...	   eIP
PREF&PWR_ADDR dd ?		; Bus/device/function #
PREF&PWR_REG dw ?		; Register #
PREF&PWR_VAL dw ?		; Value to write

PREF&PWR_STR ends

ifidn <PREF>,<U16_>
	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack
else
	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack
endif
	REGSAVE <eax,edx>	; Save registers

	mov	eax,[E&bp].&PREF&PWR_ADDR ; Get the bus/device/function #
	mov	al,[E&bp].&PREF&PWR_REG.LO ; Get register #
	and	al,not @PCICFGADDR_00 ; Ensure on dword boundary
	mov	dx,PCI_MECH1_ADDR ; Get mechanism #1 index port address
	out	dx,eax		; Tell the PCI controller
	call	PREF&DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	dx,PCI_MECH1_DATA ; Get mechanism #1 data port address
	mov	al,[E&bp].&PREF&PWR_REG.LO ; Get register #
	and	ax,@PCICFGADDR_00 ; Isolate the low-order bits, clear high-order byte
	add	dx,ax		; Add to get I/O port #

	mov	ax,[E&bp].&PREF&PWR_VAL ; Get word register value
	out	dx,ax		; Tell the PCI controller about it
;;;;;;; call	PREF&DRAINPIQ	; Drain the Prefetch Instruction Queue

	REGREST <edx,eax>	; Restore

ifidn <PREF>,<U16_>
	pop	bp		; Restore
else
	pop	ebp		; Restore
endif
	ret	4+2+2		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&PCI_WRWORD endp		; End PREF&PCI_WRWORD procedure

	endm			; PCIFNS_MAC


DISPAGP_MAC macro PREF

	NPPROC	PREF&EnableMonoText -- Enable Monochrome Text Mode
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable monochrome text mode

|

	REGSAVE <ax,dx> 	; Save registers

	mov	dx,@MOD_MDA	; Get mode register
	mov	al,@P3B8_BLINK or @P3B8_VIDEN or @P3B8_TEXT80
	out	dx,al		; Tell the 6845 about the mode
;;;;;;; call	PREF&DRAINPIQ	; Drain the Prefetch Instruction Queue

	REGREST <dx,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&EnableMonoText endp	; PREF&End EnableMonoText procedure
	NPPROC	PREF&DisableMonoText -- Disable Monochrome Text Mode
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable monochrome text mode

|

	REGSAVE <ax,dx> 	; Save registers

	mov	dx,@MOD_MDA	; Get mode register
	mov	al,0		; Disable
	out	dx,al		; Tell the 6845 about the mode
;;;;;;; call	PREF&DRAINPIQ	; Drain the Prefetch Instruction Queue

	REGREST <dx,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&DisableMonoText endp	; End PREF&DisableMonoText procedure
	NPPROC	PREF&DisableDispAGP -- Disable Primary Display & AGP
ifidn <PREF>,<U16_>
	assume	ds:NGROUP,es:NGROUP,fs:DGROUP,gs:PGROUP,ss:nothing
else
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
endif
COMMENT|

Disable primary display and AGP controller if present

|

	pushad			; Save registers

	cmp	DisableAGPCount,0 ; Izit disable for real?
	ja	short PREF&DisableDispAGPExit ; Jump if not

;;; ; Disable the primary VGA adapter
;;;
;;;	    VBDIND  esi,PriDisp     ; Get index into VBDSTR of adapter
;;; if DPCI_DIRECT
;;;	    mov     ax,VBDSTR[esi].VBD_CMD ; Get initial command register
;;;	    and     ax,not (@PCICMD_IO or @PCICMD_MEM) ; Disable the I/O and
;;;				    ; memory space
;;;	    push    ax		    ; Pass the word to write
;;;	    PUSHW   PCIREG00_CMD    ; ...  register #
;;;	    push    VBDSTR[esi].VBD_ADDR.EDD ; ... the bus/device/function #
;;;	    call    PREF&PCI_WRWORD ; Write PCI word
;;; else
;;;	    mov     bl,VBDSTR[esi].VBD_DEVFN ; Get device/function #
;;;	    mov     bh,VBDSTR[esi].VBD_BUSNO ; ... bus #
;;;	    mov     cx,VBDSTR[esi].VBD_CMD ; Get initial command register
;;;	    and     cx,not (@PCICMD_IO or @PCICMD_MEM) ; Disable the I/O and
;;;				    ; memory space
;;;	    mov     di,PCIREG00_CMD ; Register # (Command)
;;;	    PCICALL @PCI_WRWORD     ; Write PCI configuration word: BH=bus #,
;;;				    ; BL:7-3=device #, BL:2-0=function #,
;;;				    ; DI=register # (00h-FFh)
;;;				    ; CX = word register
;;; endif
;;;
;;; ; Disable the secondary VGA adapter, if present
;;;
;;;	    test    LCL_FLAG,@LCL_DPCI ; Are there dual PCI VGA adapters?
;;;	    jz	    short @F	    ; Jump if not
;;;
;;;	    VBDIND  esi,SecDisp     ; Get index into VBDSTR of adapter
;;; if DPCI_DIRECT
;;;	    mov     ax,VBDSTR[esi].VBD_CMD ; Get initial command register
;;;	    and     ax,not (@PCICMD_IO or @PCICMD_MEM) ; Disable the I/O and
;;;				    ; memory space
;;;	    push    ax		    ; Pass the word to write
;;;	    PUSHW   PCIREG00_CMD    ; ...  register #
;;;	    push    VBDSTR[esi].VBD_ADDR.EDD ; ... the bus/device/function #
;;;	    call    PREF&PCI_WRWORD ; Write PCI word
;;; else
;;;	    mov     bl,VBDSTR[esi].VBD_DEVFN ; Get device/function #
;;;	    mov     bh,VBDSTR[esi].VBD_BUSNO ; ... bus #
;;;	    mov     cx,VBDSTR[esi].VBD_CMD ; Get initial command register
;;;	    and     cx,not (@PCICMD_IO or @PCICMD_MEM) ; Disable the I/O and
;;;				    ; memory space
;;;	    mov     di,PCIREG00_CMD ; Register # (Command)
;;;	    PCICALL @PCI_WRWORD     ; Write PCI configuration word: BH=bus #,
;;;				    ; BL:7-3=device #, BL:2-0=function #,
;;;				    ; DI=register # (00h-FFh)
;;;				    ; CX = word register
;;; endif
;;; @@:
;;;
; If there's an AGP controller, disable the VGA Enable bit

	test	LCL_FLAG,@LCL_AGP ; Izit present?
	jz	short @F	; Jump if not
if DPCI_DIRECT
	mov	ax,VBDAGP.VBD_CTL ; Get initial control register value
	and	ax,not @PCI_BRIDGECTL_VGA_EN ; Disable the VGA Enable bit

	push	ax		; Pass the word to write
	PUSHW	PCIREG01_CTL	; Pass register #
	push	VBDAGP.VBD_ADDR.EDD ; Pass the bus/device/function #
	call	PREF&PCI_WRWORD ; Write PCI word
else
	mov	bl,VBDAGP.VBD_DEVFN ; Get device/function #
	mov	bh,VBDAGP.VBD_BUSNO ; ... bus #
	mov	cx,VBDAGP.VBD_CTL ; Get initial control register value
	and	cx,not @PCI_BRIDGECTL_VGA_EN ; Disable the VGA Enable bit
	mov	di,PCIREG01_CTL ; Register # (Bridge Control)
	PCICALL @PCI_WRWORD	; Write PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; CX = word register
endif
@@:
	test	LCL_FLAG,@LCL_PCIMDA ; Izit PCI MDA?
	jz	short @F	; Jump if not

	call	PREF&EnableMonoText ; Enable mono text mode
@@:
PREF&DisableDispAGPExit:
	inc	DisableAGPCount ; Count in another disable

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&DisableDispAGP endp	; End PREF&DisableDispAGP procedure
	NPPROC	PREF&EnableDispAGP -- Enable Primary Display & AGP
ifidn <PREF>,<U16_>
	assume	ds:NGROUP,es:NGROUP,fs:DGROUP,gs:PGROUP,ss:nothing
else
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
endif
COMMENT|

Enable primary display and AGP controller if present

|

	pushad			; Save registers

	cmp	DisableAGPCount,1 ; Izit enable for real?
	jne	short PREF&EnableDispAGPExit ; Jump if not

	test	LCL_FLAG,@LCL_PCIMDA ; Izit PCI MDA?
	jz	short @F	; Jump if not

	call	PREF&DisableMonoText ; Disable mono text mode
@@:

; If there's an AGP controller, enable the VGA Enable bit

	test	LCL_FLAG,@LCL_AGP ; Izit present?
	jz	short @F	; Jump if not
if DPCI_DIRECT
	push	VBDAGP.VBD_CTL ; Pass the word to write
	PUSHW	PCIREG01_CTL	; Pass register #
	push	VBDAGP.VBD_ADDR.EDD ; Pass the bus/device/function #
	call	PREF&PCI_WRWORD ; Write PCI word
else
	mov	bl,VBDAGP.VBD_DEVFN ; Get device/function #
	mov	bh,VBDAGP.VBD_BUSNO ; ... bus #
	mov	cx,VBDAGP.VBD_CTL ; Get initial control register
	mov	di,PCIREG01_CTL ; Register # (Bridge Control)
	PCICALL @PCI_WRWORD	; Write PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; CX = word register
endif
@@:

;;; ; Re-enable the secondary VGA adapter, if present
;;;
;;;	    test    LCL_FLAG,@LCL_DPCI ; Are there dual PCI VGA adapters?
;;;	    jz	    short @F	    ; Jump if not
;;;
;;;	    VBDIND  esi,SecDisp     ; Get index into VBDSTR of adapter
;;; if DPCI_DIRECT
;;;	    push    VBDSTR[esi].VBD_CMD ; Pass the word to write
;;;	    PUSHW   PCIREG00_CMD    ; Pass register #
;;;	    push    VBDSTR[esi].VBD_ADDR.EDD ; Pass the bus/device/function #
;;;	    call    PREF&PCI_WRWORD ; Write PCI word
;;; else
;;;	    mov     bl,VBDSTR[esi].VBD_DEVFN ; Get device/function #
;;;	    mov     bh,VBDSTR[esi].VBD_BUSNO ; ... bus #
;;;	    mov     cx,VBDSTR[esi].VBD_CMD ; Get initial command register
;;;	    mov     di,PCIREG00_CMD ; Register # (Command)
;;;	    PCICALL @PCI_WRWORD     ; Write PCI configuration word: BH=bus #,
;;;				    ; BL:7-3=device #, BL:2-0=function #,
;;;				    ; DI=register # (00h-FFh)
;;;				    ; CX = word register
;;; endif
;;; @@:
;;;
;;; ; Re-enable the primary VGA adapter
;;;
;;;	    VBDIND  esi,PriDisp     ; Get index into VBDSTR of adapter
;;; if DPCI_DIRECT
;;;	    push    VBDSTR[esi].VBD_CMD ; Pass the word to write
;;;	    PUSHW   PCIREG00_CMD    ; Pass register #
;;;	    push    VBDSTR[esi].VBD_ADDR.EDD ; Pass the bus/device/function #
;;;	    call    PREF&PCI_WRWORD ; Write PCI word
;;; else
;;;	    mov     bl,VBDSTR[esi].VBD_DEVFN ; Get device/function #
;;;	    mov     bh,VBDSTR[esi].VBD_BUSNO ; ... bus #
;;;	    mov     cx,VBDSTR[esi].VBD_CMD ; Get initial command register
;;;	    mov     di,PCIREG00_CMD ; Register # (Command)
;;;	    PCICALL @PCI_WRWORD     ; Write PCI configuration word: BH=bus #,
;;;				    ; BL:7-3=device #, BL:2-0=function #,
;;;				    ; DI=register # (00h-FFh)
;;;				    ; CX = word register
;;; endif
PREF&EnableDispAGPExit:
	dec	DisableAGPCount ; Count in another enable

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREF&EnableDispAGP endp 	; End PREF&EnableDispAGP procedure

	endm			; DISPAGP_MAC


NCODE	segment use16 para public 'ncode' ; Start NCODE segment
	assume	cs:NGROUP

	DISPAGP_MAC U16_
	PCIFNS_MAC  U16_,dw

NCODE	ends			; End NCODE segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP

	public	@SWAT_PCI_PROG
@SWAT_PCI_PROG: 		; Mark module start in .MAP file

	DISPAGP_MAC U32_
	PCIFNS_MAC  U32_,dd,e

PROG	ends			; End PROG segment

	MEND			; End SWAT_PCI module
