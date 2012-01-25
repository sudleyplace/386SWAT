	title	DPCI -- Dual PCI VGA Adapters
	page	58,122
	name	DPCI
COMMENT|

Dual PCI VGA Adapter Routines

While trying to add support to 386SWAT for dual PCI VGA adapters, I
learned a bit about PCI programming which I thought I'd share with
others.

The main file is DPCI.ASM which contains routines to detect dual PCI
VGA adapters and enable and disable them.  The case where there is an
AGP controller in the picture is covered as well.

There are two distinct cases covered by this code.

1.  A monochrome adapter is in the system, but isn't visible because
    it is hidden by an AGP controller.	Use DPCI MONO to test this
    case.

2.  Two (or more) PCI VGA adapters are in the system, one is the
    primary, one is the secondary.  Use DPCI DVGA to test this case.

Some code was taken from Ralf Brown's INITDUAL.ASM.
Note that we support access mechanism #1 only.

|

.386
	include MASM.INC
	include DOSCALL.INC
	include PTR.INC
	include PCI.INC
	include BIOSDATA.INC
	include ASCII.INC
	include INTVEC.INC
	include VIDCALL.INC
	include VIDATTR.INC
	include 386.INC
	include 6845.INC
	include DPCI.INC

PGROUP	group	STACK,CODE,DATA,DATA2,TEXT,DATAZ

; The following segment both positions class 'code' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	segment use16 byte stack 'code' ; Start STACK segment
STACK	ends			; End STACK segment


CODE	segment use16 byte public 'code' ; Start CODE segment
CODE	ends			; End CODE segment


DATA	segment use16 dword public 'data' ; Start DATA segment
DATA	ends			; End DATA segment


DATA2	segment use16 word public 'data' ; Start DATA2 segment
DATA2	ends			; End DATA2 segment


TEXT	segment use16 byte public 'data' ; Start TEXT segment
TEXT	ends			; End TEXT segment


DATAZ	segment use16 para public 'data' ; Start DATAZ segment
	assume	ds:PGROUP

	public	LCLSTK
LCLSTK	label	word
	org	LCLSTK + 1024 * (type LCLSTK)
LCLSTKZ label	word

	public	ZTAIL
ZTAIL	label	dword		; Allocate memory from here

DATAZ	ends			; End DATAZ segment


VIDEO_BIOS segment use16 at 0C000h
	assume	cs:VIDEO_BIOS

VIDEO_SIG dw	0AA55h		; ROM signature
VIDEO_SIZE db	?		; Initialization size in units of 512 bytes
VIDEO_INIT label far		; INIT code

VIDEO_BIOS ends


VBDIND	macro	REG,DISP

	imul	REG,DISP,type VIDEO_BIOS_DATA ; Times size of struc for index

	endm			; VBDIND


DATA	segment use16 dword public 'data' ; Start DATA segment
	assume	ds:PGROUP

	public	LaData
LaData	dd	?		; Linear address of data segment

	public	LCLIVT,LCLBDA
LCLIVT	dd	256 dup (?)	; Copy of local IVT
LCLBDA	db	256 dup (?)	; ...		BDA

VIDEO_BIOS_DATA struc

; The following three fields are accessed as a dword,
; so don't change their order.  For Mech #2 mappings, see PCICFGADDRREC.
VBD_ADDR     dw ?		; Mech #2 I/O port address
VBD_BUSNUM   db ?		; Mech #2 bus #
VBD_ACCESS   db ?		; Pad to allow DWORD for mech #1 access key

VBD_CURSOR   dw ?		; Cursor position just prior to disabling
VBD_DEVFN    db ?		; 7-3=device #, 2-0=function #
VBD_BUSNO    db ?		; Bus #
VBD_CMD      dw ?		; Command register
VBD_CTL      dw ?		; Control register (bridge only)
VBD_EROM     dd ?		; Expansion ROM base address & flags
VBD_ESIG     dd ?		; Expansion ROM signature
VBD_ESIZE    dd ?		; Expansion ROM size in bytes
VBD_EBASE    dd ?		; Expansion ROM base address in low memory
VBD_EINIT    dd ?		; EROM initialization address
VBD_DISCNT   dd ?		; Disable count used to handle recursion

VIDEO_BIOS_DATA ends

	public	VBDSTR,VBDAGP
VBDSTR	VIDEO_BIOS_DATA <>	; First display adapter
	VIDEO_BIOS_DATA <>	; Second ...
	VIDEO_BIOS_DATA <>	; Third ...
VBDAGP	VIDEO_BIOS_DATA <>	; AGP controller (if present)

	public	LCL_FLAG
LCL_FLAG dw	0		; Local flags

@LCL_PCI  equ	8000h		; PCI BIOS present
@LCL_PCIMDA equ 4000h		; PCI MDA present
@LCL_DPCI equ	2000h		; Dual PCI VGA adapters present
@LCL_MDA  equ	1000h		; Monochrome adapter present
@LCL_AGP  equ	0800h		; AGP controller present (VBDAGP filled in)
@LCL_MONO equ	0400h		; MONO on command line
@LCL_DVGA equ	0200h		; DVGA on command line

; The following four variables describe the display adapters
; in which we're interested.  The first two are static values;
; the second two are dynamic.  The primary adapter is the one
; which is active when we boot up.  The secondary adapter is
; the one on which SWAT displays its data.

	public	PriDisp,SecDisp
PriDisp dd	-1		; Primary display adapter # (origin-0) (-1=none)
SecDisp dd	-1		; Secondary ...

	public	ActDisp,InaDisp
ActDisp dd	-1		; Active display # (origin-0) (-1=none)
InaDisp dd	-1		; Inactive ...

	public	PCI_Version,PCI_HW_Char,PCI_HW_Acc
PCI_Version dw	?		; PCI version #
PCI_HW_Char db	?		; PCI HW characteristics
PCI_HW_Acc db	?		; PCI HW access method (1 or 2)

@PCI_HW_ACC1 equ 1		; Access method #1
@PCI_HW_ACC2 equ 2		; ...		 2

	public	MonoTextData
			;				   Valid values
			;				MONO CO40 CO80 GRPH
MonoTextData db 61h	; 00:  Horiz total		 61   38   71	38
	db	50h	; 01:  Horiz display chars/line  50   28   50	28
	db	52h	; 02:  Horiz sync position	 52   2D   5A	2D
	db	0Fh	; 03:  Horiz sync width 	 0F   0A   0A	0A
	db	19h	; 04:  Vertical total		 19   1F   1F	7F
	db	06h	; 05:  Vertical total adjust	 06   06   06	06
	db	19h	; 06:  Vertical displayed	 19   19   19	64
	db	19h	; 07:  Vertical sync position	 19   1C   1C	70
	db	02h	; 08:  Interface mode/skew	 02   02   02	02
	db	0Dh	; 09:  Maximum scan line address 0D   07   07	01
	db	0Bh	; 0A:  Cursor start		 0B   06   06	06
	db	0Ch	; 0B:  ...    end		 0C   07   07	07
	db	00h	; 0C:  Start address (high byte) 00   00   00	00
	db	00h	; 0D:  ...	     (low ...)	 00   00   00	00
	db	00h	; 0E:  Cursor loc (high byte)	 00   --   --	--
	db	00h	; 0F:  ...	  (low ...)	 00   --   --	--
MonoTextDataLen equ $-MonoTextData ; Length of ...


	public	@DIRPCI_BIOS,@DIRPCI_REGS
@DIRPCI_BIOS equ 0		; Use BIOS calls to talk to PCI
@DIRPCI_REGS equ 1		; ... registers  ...

	public	DirectPCI
DirectPCI db	@DIRPCI_BIOS	; 1 if writing to PCI registers directly
				; 0 if using BIOS calls
	public	MSG_COPY
MSG_COPY db	'DPCI   -- Version 1.01 -- Dual PCI VGA Adapters',CR,LF
	db	'  (C) Copyright 1999-2002 Qualitas, Inc.  All rights reserved.',CR,LF,EOS

	public	MSG_MDAF,MSG_PCIMDAF,MSG_USEMDA,MSG_USEDPCI
	public	MSG_DPCI1,MSG_DPCI2,MSG_MDASET
	public	MSG_DPCIROM,MSG_DPCISET,MSG_DPCIXROM
MSG_MDAF db	'  Monochrome adapter found.',CR,LF,EOS
MSG_PCIMDAF db	'  Monochrome adapter hidden by AGP controller found.',CR,LF,EOS
MSG_USEMDA db	'  Using monochrome adapter.',CR,LF,EOS
MSG_USEDPCI db	'  Using secondary PCI VGA adapter.',CR,LF,EOS
MSG_DPCI1 db	'  Primary PCI VGA adapter found.',CR,LF,EOS
MSG_DPCI2 db	'  Secondary PCI VGA adapter found.',CR,LF,EOS
MSG_MDASET db	'  Hidden monochrome adapter setup.',CR,LF,EOS
MSG_DPCIROM db	'  Secondary PCI VGA adapter ROM read in.',CR,LF,EOS
MSG_DPCISET db	'  Secondary PCI VGA adapter setup.',CR,LF,EOS
MSG_DPCIXROM db '  *** Secondary PCI VGA adapter ROM invalid.',CR,LF,EOS

	public	MSG_DVGA
MSG_DVGA db	'DVGA Adapter found on Bus '
MSG_DVGA_B db	'__, Device '
MSG_DVGA_D db	'__, Function '
MSG_DVGA_F db	'__, Command '
MSG_DVGA_C db	'____.',CR,LF,EOS

	public	MSG_HELP
MSG_HELP db	CR,LF
	db	'Syntax:   DPCI [mono|dvga|dvga=BIOS|dvga=REGS]',CR,LF
	db	CR,LF
	db	'If dvga is specified alone, it defaults to dvga=BIOS',CR,LF
	db	EOS

DATA	ends			; End DATA segment


CODE	segment use16 byte public 'code' ; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP,es:PGROUP

	extrn	CHECK_ARGS:near
	extrn	CHK_CREG:near
	extrn	DRAINPIQ:near
	extrn	SET_CURPOS:near
	extrn	GET_CURPOS:near
	extrn	DB2HEX:near
	extrn	DW2HEX:near
.xlist
	include PSP.INC
.list
	NPPROC	DPCI -- Dual PCI VGA Adapters
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Dual PCI VGA adapters

|

	lea	sp,LCLSTKZ	; Switch to local stack

	DOSCALL @STROUT,MSG_COPY ; Display the flag

	xor	eax,eax 	; Zero to use as dword
	mov	ax,ds		; Get data segment
	shl	eax,4-0 	; Convert from paras to bytes
	mov	LaData,eax	; Save for later use

	call	IzitMono	; See if there's a mono adapter present
	jc	short @F	; Jump if not

	or	LCL_FLAG,@LCL_MDA ; Mark as present
	DOSCALL @STROUT,MSG_MDAF ; Tell 'em what we found
@@:
	call	CHECK_ARGS	; Parse the command line
	jc	short DPCI_HELP ; Jump if something went wrong

	test	LCL_FLAG,@LCL_MONO or @LCL_DVGA ; Is there an argument?
	jz	short DPCI_HELP ; Jump if not

	call	CHECK_PCI_BIOS	; Check on PCI BIOS

	call	VideoCheck	; Sort out video possibilities

	test	LCL_FLAG,@LCL_PCIMDA ; Do we have a hidden mono adapater?
	jz	short @F	; Jump if not

	call	SetupMDA	; Setup MDA if present
@@:
	test	LCL_FLAG,@LCL_DPCI ; Do we have dual PCI adapaters?
	jz	short @F	; Jump if not

	call	SetupDPCI	; Setup alternate adapter
@@:
	jmp	short DPCI_EXIT ; Join common exit code


DPCI_HELP:
	DOSCALL @STROUT,MSG_HELP ; Give 'em a hand
DPCI_EXIT:
	DOSCALL @EXITRC 	; Return to DOS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPCI	endp			; End DPCI procedure
	NPPROC	IzitMono -- Is There A Mono Adapter Present
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Is there a monochrome adpter present?

On exit:

CF	=	0 if successful
	=	1 if not

|

	REGSAVE <dx>		; Save register

	mov	dx,@CRT_MDA	; Address register of monochrome 6845

	call	CHK_CREG	; Check cursor register
;;;;;;; jc	short @F	; Return with CF significant

	REGREST <dx>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IzitMono endp			; End IzitMono procedure
	NPPROC	CHECK_PCI_BIOS -- Check On PCI BIOS
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
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

	cmp	PriDisp,-1	; Izit invalid?
	je	short CHECK_PCI_BIOS_EXIT ; Jump if so

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
	NPPROC	DispBDF -- Display Bus, Device, and Function
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:
BH	=	bus #
BL[7:3] =	device #
BL[2:0] =	function #
CX	=	command register value

|

	REGSAVE <ax,dx,di>	; Save registers

	mov	al,bh		; Copy bus #
	lea	di,MSG_DVGA_B	; ES:DI ==> output save area
	call	DB2HEX		; Convert AL to hex at ES:DI

	mov	al,bl		; Copy device/function #
	and	al,11111000b	; Isolate the device #
	shr	al,3		; Shift to low-order
	lea	di,MSG_DVGA_D	; ES:DI ==> output save area
	call	DB2HEX		; Convert AL to hex at ES:DI

	mov	al,bl		; Copy device/function #
	and	al,00000111b	; Isolate the device #
;;;;;;; shr	al,0		; Shift to low-order
	lea	di,MSG_DVGA_F	; ES:DI ==> output save area
	call	DB2HEX		; Convert AL to hex at ES:DI

	mov	ax,cx		; Copy command register value
	lea	di,MSG_DVGA_C	; ES:DI ==> output save area
	call	DW2HEX		; Convert AX to hex at ES:DI

	DOSCALL @STROUT,MSG_DVGA ; Display the message

	REGREST <di,dx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DispBDF endp			; End DispBDF procedure
	NPPROC	CHECK_DPCI -- Check On Dual PCI VGA Adapters
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
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
	jc	near ptr CHECK_DPCI_DONE ; Jump if that's all

	call	DispBDF 	; Display Bus, Device, and Function

	VBDIND	edx,esi 	; Get index into VBDSTR
	call	ConvertDeviceAddress ; Convert to direct addressing format
				; Return in EAX
	mov	VBDSTR[edx].VBD_ADDR.EDD,eax ; Save for later use
	mov	VBDSTR[edx].VBD_BUSNO,bh ; Save for later use
	mov	VBDSTR[edx].VBD_DEVFN,bl ; ...
	mov	VBDSTR[edx].VBD_CMD,cx ; ...

	test	cx,@PCICMD_IO or @PCICMD_MEM ; Is I/O or memory enabled?
	jz	short @F	; Jump if not

	mov	ActDisp,esi	; Save as active display adpater (origin-0)
	mov	PriDisp,esi	; ...	  primary ...
	mov	VBDSTR[edx].VBD_DISCNT,0 ; Mark as enabled

	push	dx		; Save for a moment
	DOSCALL @STROUT,MSG_DPCI1 ; Tell 'em what we found
	pop	dx		; Restore
@@:

; Read in the Expansion ROM register and save it

	cmp	DirectPCI,@DIRPCI_REGS ; Writing to PCI registers directly?
	jne	short DirPCI1	; Jump if not

	PUSHD	PCIREG00_EROM	; Pass register # (Expansion ROM) (dword-aligned)
	push	VBDSTR[edx].VBD_ADDR.EDD ; ... the bus/device/function #
	call	PCI_RDDWORD	; Read PCI configuration dword
				; Return with ECX = dword register value
	jmp	short DirPCI1Com ; Join common code


DirPCI1:
;;;;;;; mov	bl,VBDSTR[edx].VBD_DEVFN ; Get device/function #
;;;;;;; mov	bh,VBDSTR[edx].VBD_BUSNO ; ... bus #
	mov	di,PCIREG00_EROM ; Register # (Expansion ROM)
	PCICALL @PCI_RDDWORD	; Read PCI configuration dword: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; Return with ECX = dword register value
DirPCI1Com:
	mov	VBDSTR[edx].VBD_EROM,ecx ; Save for later use

	push	ecx		; Pass the source physical address

	lea	eax,VBDSTR[edx].VBD_ESIG ; Get the destin address
	add	eax,LaData	; Plus linear address of data segment
	push	eax		; Pass the destin linear address

	PUSHD	2		; ...  the length in bytes (dword-aligned)
	call	CopyPhysMem	; Copy the byte value to local memory

	cmp	VBDSTR[edx].VBD_ESIG.ELO,0AA55h ; Izit a valid signature?
;;;;;;; jne	short ???	; Jump if not

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

	VBDIND	edx,esi 	; Get index into VBDSTR
	mov	VBDSTR[edx].VBD_DISCNT,1 ; Mark as disabled

	DOSCALL @STROUT,MSG_DPCI2 ; Tell 'em what we found

	or	LCL_FLAG,@LCL_DPCI ; Mark as dual PCI VGA adapters present
CHECK_DPCI_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DPCI endp 		; End CHECK_DPCI procedure
	NPPROC	FindAGP -- Find AGP Controller
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
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
	je	near ptr FindAGPExit ; Jump if so

; In case this is the AGP controller, save data now as we'll need it shortly

	call	ConvertDeviceAddress ; Convert to direct addressing format
				; Return in EAX
	mov	VBDAGP.VBD_ADDR.EDD,eax ; Save for later use
	mov	VBDAGP.VBD_DEVFN,bl ; ...
	mov	VBDAGP.VBD_BUSNO,bh ; ...

	cmp	DirectPCI,@DIRPCI_REGS ; Writing to PCI registers directly?
	jne	short DirPCI2	; Jump if not

	PUSHD	PCIREG00_HDRTYPE ; Pass register # (Header Type) (dword-aligned)
	push	VBDAGP.VBD_ADDR.EDD ; ... the bus/device/function #
	call	PCI_RDBYTE	; Read PCI configuration byte
				; Return with CL = byte register
	jmp	short DirPCI2Com ; Join common code


DirPCI2:
;;;;;;; mov	bl,VBDAGP.VBD_DEVFN ; Get device/function #
;;;;;;; mov	bh,VBDAGP.VBD_BUSNO ; ... bus #
	mov	di,PCIREG00_HDRTYPE ; Register # (Header Type)
	PCICALL @PCI_RDBYTE	; Read PCI configuration byte: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; Return with CL = byte register
DirPCI2Com:
	cmp	cl,@PCIHDRTYPE_BRIDGE ; Izit a bridge header?
	jne	short FindAGPLoop ; Jump if not

; See if this controller has the VGA_EN bit set

	cmp	DirectPCI,@DIRPCI_REGS ; Writing to PCI registers directly?
	jne	short DirPCI3	; Jump if not

	PUSHD	PCIREG01_CTL	; Pass register # (Bridge Control) (dword-aligned)
	push	VBDAGP.VBD_ADDR.EDD ; ... the bus/device/function #
	call	PCI_RDWORD	; Read PCI configuration word
				; Return with CX = word register value
	jmp	short DirPCI3Com ; Join common code


DirPCI3:
;;;;;;; mov	bl,VBDAGP.VBD_DEVFN ; Get device/function #
;;;;;;; mov	bh,VBDAGP.VBD_BUSNO ; ... bus #
	mov	di,PCIREG01_CTL ; Register # (Bridge Control)
	PCICALL @PCI_RDWORD	; Read PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; Return with CX = word register value
DirPCI3Com:
	test	cx,@PCI_BRIDGECTL_VGA_EN ; Izit set?
	jnz	short FindAGPDone ; Jump if so
FindAGPLoop:
	inc	esi		; Skip to next device

	jmp	FindAGPNext	; Go around again

FindAGPDone:
	mov	VBDAGP.VBD_CTL,cx ; Save for later use

; Read command register value

	cmp	DirectPCI,@DIRPCI_REGS ; Writing to PCI registers directly?
	jne	short DirPCI4	; Jump if not

	PUSHD	PCIREG01_CMD	; Pass register # (Command) (dword-aligned)
	push	VBDAGP.VBD_ADDR.EDD ; ... the bus/device/function #
	call	PCI_RDWORD	; Read PCI configuration word
				; Return with CX = word register value
	jmp	short DirPCI4Com ; Join common code


DirPCI4:
;;;;;;; mov	bl,VBDAGP.VBD_DEVFN ; Get device/function #
;;;;;;; mov	bh,VBDAGP.VBD_BUSNO ; ... bus #
	mov	di,PCIREG01_CMD ; Register # (Command)
	PCICALL @PCI_RDWORD	; Read PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; Return with CX = word register value
DirPCI4Com:
	mov	VBDAGP.VBD_CMD,cx ; Save for later use

	or	LCL_FLAG,@LCL_AGP ; Mark as present
FindAGPExit:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FindAGP endp			; End FindAGP procedure
	NPPROC	VideoCheck -- Check Out Video Adapter Possibilities
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check out video adapter possibilities

|

	pushad			; Save all EGP registers
COMMENT|

If the user said MONO, but we didn't detect a mono adapter, and we're
in a PCI system, and there's an AGP controller, disable the AGP
controller and check for a mono adapter hidden by the PCI adapter.

|

	test	LCL_FLAG,@LCL_MONO ; Did the user say the magic word?
	jz	short VideoCheckNoPCIMDA ; Jump if not

	test	LCL_FLAG,@LCL_MDA ; Did we already detect a mono adapter?
	jnz	short VideoCheckNoPCIMDA ; Jump if so

	test	LCL_FLAG,@LCL_PCI ; Is PCI BIOS present?
	jz	short VideoCheckNoPCIMDA ; Jump if not

	call	DisableAGP	; Disable the AGP controller
	call	DisableDisps	; Disable the primary & secondary displays

	call	IzitMono	; See if there's a mono adapter present
	jc	short @F	; Jump if not

	or	LCL_FLAG,@LCL_MDA or @LCL_PCIMDA ; Mark as present
	and	LCL_FLAG,not @LCL_DPCI ; Mark as no longer to be used
@@:
	call	EnableDisps	; Enable the primary & secondary displays
	call	EnableAGP	; Enable the AGP controller

	test	LCL_FLAG,@LCL_MDA ; Izit now present?
	jz	short @F	; Jump if not

	DOSCALL @STROUT,MSG_PCIMDAF ; Tell 'em what we found
	DOSCALL @STROUT,MSG_USEMDA ; Tell 'em what we found
@@:
VideoCheckNoPCIMDA:
	test	LCL_FLAG,@LCL_DVGA ; Did the user say the magic word?
	jz	short VideoCheckNoDPCI ; Jump if not

	test	LCL_FLAG,@LCL_DPCI ; Did we detect dual PCI VGA adapters?
	jz	short VideoCheckNoDPCI ; Jump if not

	DOSCALL @STROUT,MSG_USEDPCI ; Tell 'em what we're doing
VideoCheckNoDPCI:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VideoCheck endp 		; End VideoCheck procedure
	NPPROC	SetupMDA -- Setup MDA
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup MDA if present

|

	test	LCL_FLAG,@LCL_PCIMDA ; Izit present?
	jz	short SetupMDAExit ; Jump if not

	call	DisableAGP	; Disable the AGP controller
	call	DisableDisps	; Disable the primary & secondary displays

	call	SetupMonoTextMode ; Setup monochrome text mode
	call	EnableMonoText	; Enable mono text mode

; DO NOT call Set Video Mode here!!

	push	0B000h		; Pass segment #
	call	ClearScrn	; Clear the screen

	push	0B000h		; Pass segment #
	call	DISP_COPY_SCR	; Display our copyright notice on specified screen

;;;;;;; call	DisableMonoText ; Disable mono text mode
	call	EnableDisps	; Enable the primary & secondary displays
	call	EnableAGP	; Enable the AGP controller

	DOSCALL @STROUT,MSG_MDASET ; Tell 'em what happened
SetupMDAExit:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SetupMDA endp			; End SetupMDA procedure
	NPPROC	SetupMonoTextMode -- Setup Monochrome Text Mode
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup monochrome text mode

|

	REGSAVE <ax,cx,dx,si>	; Save registers

	cld			; String ops forwardly

	lea	si,MonoTextData ; DS:SI ==> mono text data values
	mov	cx,MonoTextDataLen ; Get # data values
	mov	ah,0		; Initialize register index
SetupMonoTextModeNext:
	mov	al,ah		; Copy register index value
	mov	dx,@CRT_MDA	; Get index register
	out	dx,al		; Output index value
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	lods	MonoTextData[si] ; Get next data byte
	inc	dx		; Skip to data register
	out	dx,al		; Output data value
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	inc	ah		; Skip to next register index

	loop	SetupMonoTextModeNext ; Jump if more data values

	REGREST <si,dx,cx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SetupMonoTextMode endp		; End SetupMonoTextMode procedure
	NPPROC	ClearScrn -- Clear The Screen
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear the screen

|

CLS_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
CLS_SEG dw	?		; Segment #

CLS_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ax,cx,di,es>	; Save for a moment

	cld			; String ops forwardly

	mov	es,[bp].CLS_SEG ; ES:0 ==> video buffer
	assume	es:nothing	; Tell the assembler about it

; Initialize the video memory to all blanks

	mov	cx,@NROWS * @NCOLS ; Write this many times
	xor	di,di		; ES:DI ==> start of mono buffer
	mov	ax,(@ATMnorm shl 8) or ' ' ; Write this
    rep stos	es:[di].ELO	; Smear values to the screen

	REGREST <es,di,cx,ax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ClearScrn endp			; End ClearScrn procedure
	NPPROC	DISP_COPY_SCR -- Display Our Copyright Notice on the Specified Screen
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display our copyright notice on the specified screen

|

DCS_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
DCS_SEG dw	?		; Video buffer

DCS_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ax,dx,si,di,es> ; Save registers

	mov	es,[bp].DCS_SEG ; ES:0 ==> video buffer
	assume	es:nothing	; Tell the assembler about it

	lea	si,MSG_COPY	; DS:SI ==> copyright notice
	xor	di,di		; ES:DI ==> monoscreen
DISP_COPY_SCR_NEXT0:
	mov	ah,@ATMnorm	; Get normal attribute
DISP_COPY_SCR_NEXT:
	lods	MSG_COPY[si]	; Get next char

	cmp	al,EOS		; Izit EOS?
	je	short DISP_COPY_SCR_EXIT ; Jump if so

	cmp	al,CR		; Izit CR?
	jne	short @F	; Jump if not

	xor	dx,dx		; Zereo to use DX:AX as dword
	mov	ax,di		; Copy dividend
	mov	di,@NCOLS * 2	; Get # columns of (char,attr)
	div	di		; Divide to get AX = row #, DX = col #
	imul	di,ax,2 	; Convert from (char,attr) to bytes

	jmp	DISP_COPY_SCR_NEXT0 ; Go around again

@@:
	cmp	al,LF		; Izit LF?
	jne	short @F	; Jump if not

	add	di,@NCOLS * 2	; Skip to new line

	jmp	DISP_COPY_SCR_NEXT ; Go around again

@@:
	stos	es:[di].ELO	; Store on screen

	jmp	DISP_COPY_SCR_NEXT ; Go around again

DISP_COPY_SCR_EXIT:
	REGREST <es,di,si,dx,ax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_COPY_SCR endp		; End DISP_COPY_SCR procedure
	NPPROC	FindPCI_VGA -- Find The Next PCI VGA Adapter
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
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

	REGSAVE <eax,di>	; Save registers

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

	cmp	DirectPCI,@DIRPCI_REGS ; Writing to PCI registers directly?
	jne	short DirPCI5	; Jump if not

	call	ConvertDeviceAddress ; Convert to direct addressing format
				; Return in EAX
	PUSHD	PCIREG00_CMD	; Pass register # (Command) (dword-aligned)
	push	eax		; ... the bus/device/function #
	call	PCI_RDWORD	; Read PCI configuration word
				; Return with CX = word register value
	jmp	short DirPCI5Com ; Join common code


DirPCI5:
	mov	di,PCIREG00_CMD ; Register # (Command)
	PCICALL @PCI_RDWORD	; Read PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; Return with CX = word register value
DirPCI5Com:
	clc			; Mark as successful
FindPCI_VGA_EXIT:
	REGREST <di,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FindPCI_VGA endp		; End FindPCI_VGA procedure
	NPPROC	EnableEROM -- Enable Expansion ROM
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable expansion ROM

|

ENAEROM_STR struc

	db	(type PUSHAD_STR) dup (?) ; Caller's EGP registers
	dw	?		; ...	   IP
ENAEROM_NUM dd	?		; Adapter #

ENAEROM_STR ends

	pushad			; Save all EGP registers
	mov	bp,sp		; Hello, Mr. Stack

	VBDIND	esi,[bp].ENAEROM_NUM ; Get index into VBDSTR of adapter

; Enable the Expansion ROM in extended memory

	mov	ecx,VBDSTR[esi].VBD_EROM ; Get base address

	and	ecx,@PCI_EROM_BASE ; Isolate the base address
	jz	short @F	; Jump if none

	or	ecx,@PCI_EROM_ENA ; Enable the ROM

	cmp	DirectPCI,@DIRPCI_REGS ; Writing to PCI registers directly?
	jne	short DirPCI6	; Jump if not

	push	ecx		; Pass the dword to write
	PUSHD	PCIREG00_EROM	; ... register # (dword-aligned) (dword-aligned)
	push	VBDSTR[esi].VBD_ADDR.EDD ; ... the bus/device/function #
	call	PCI_WRDWORD	; Write PCI configuration dword

	jmp	short DirPCI6Com ; Join common code


DirPCI6:
	mov	bl,VBDSTR[esi].VBD_DEVFN ; Get device/function #
	mov	bh,VBDSTR[esi].VBD_BUSNO ; ... bus #
	mov	di,PCIREG00_EROM ; Register # (Expansion ROM)
	PCICALL @PCI_WRDWORD	; Write PCI configuration dword: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; ECX = dword register value
DirPCI6Com:
@@:
	popad			; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EnableEROM endp 		; End EnableEROM procedure
	NPPROC	ConvertDeviceAddress -- Convert Device Address
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert device address to configuration address dword
to be used with direct I/O to the configuration address space.

From Ralf Brown's example code.

On entry:

BH	=	bus #
BL	=	device/func #

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
;;;;;;; mov	al,??		; EAX[7..0] = register #

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
	NPPROC	SaveVideoData -- Save The VideoData
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save the video data

|

	REGSAVE <cx,si,di,ds>	; Save registers

; Save the IVT

	mov	si,seg INTVEC	; Get segment of IVT
	mov	ds,si		; Address it
	assume	ds:INTVEC	; Tell the assembler about it

	xor	si,si		; DS:SI ==> IVT
	lea	di,LCLIVT	; ES:DI ==> local IVT
	mov	cx,length LCLIVT ; CX = # entries
    rep movs	LCLIVT[di],INT00_VEC[si] ; Copy the IVT

; Save the BDA

	mov	si,seg BIOSDATA ; Get segment of BIOS data area
	mov	ds,si		; Address it
	assume	ds:BIOSDATA	; Tell the assembler about it

	xor	si,si		; DS:SI ==> BDA
	lea	di,LCLBDA	; ES:DI ==> local BDA
	mov	cx,length LCLBDA ; CX = # entries
    rep movs	LCLBDA[di],ds:[si].LO ; Copy the BDA

	REGREST <ds,di,si,cx>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SaveVideoData endp		; End SaveVideoData procedure
	NPPROC	RestVideoData -- Restore The Video Data
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore the video data

|

	REGSAVE <cx,si,di,es>	; Save registers

; Restore the IVT

	mov	di,seg INTVEC	; Get segment of IVT
	mov	es,di		; Address it
	assume	es:INTVEC	; Tell the assembler about it

	xor	di,di		; ES:DI ==> IVT
	lea	si,LCLIVT	; DS:SI ==> local IVT
	mov	cx,length LCLIVT ; CX = # entries
    rep movs	INT00_VEC[di],LCLIVT[si] ; Copy the IVT

; Restore the BDA

	mov	di,seg BIOSDATA ; Get segment of BIOS data area
	mov	es,di		; Address it
	assume	es:BIOSDATA	; Tell the assembler about it

	xor	di,di		; ES:DI ==> BDA
	lea	si,LCLBDA	; DS:SI ==> local BDA
	mov	cx,length LCLBDA ; CX = # entries
    rep movs	es:[di].LO,LCLBDA[si] ; Copy the BDA

	REGREST <es,di,si,cx>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RestVideoData endp		; End RestVideoData procedure
	NPPROC	SetupDPCI -- Setup Dual PCI VGA Adapters
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup dual PCI VGA adapters

|

	test	LCL_FLAG,@LCL_DVGA ; Did the user say the magic word?
	jz	near ptr SetupDPCI_EXIT ; Jump if not

	test	LCL_FLAG,@LCL_PCI ; Is PCI BIOS present?
	jz	near ptr SetupDPCI_EXIT ; Jump if not

	test	LCL_FLAG,@LCL_DPCI ; Izit present?
	jz	near ptr SetupDPCI_EXIT ; Jump if not

	pushad			; Save all EGP registers

	lea	eax,ZTAIL[16-1] ; Get offset to end of program
	and	eax,not (16-1)	; Round down to para boundary
	add	eax,LaData	; Plus linear address of data segment
	add	eax,4*1024-1	; Round up to 4KB
	and	eax,not (4*1024-1) ; ... boundary
	VBDIND	esi,SecDisp	; Get index into VBDSTR of secondary adapter
	mov	VBDSTR[esi].VBD_EBASE,eax ; Save for later use
	shr	eax,4-0 	; Convert from bytes to paras
	mov	VBDSTR[esi].VBD_EINIT.VSEG,ax ; Save for later use
	lea	ax,VIDEO_INIT	; Get initialization offset
	mov	VBDSTR[esi].VBD_EINIT.VOFF,ax ; Save for later use

	mov	VBDSTR[esi].VBD_CURSOR,0000h ; Set to row 0, col 0

; Read the secondary adapter's ROM length

	call	DisableAGP	; Disable the AGP controller
	call	SwapDPCI	; Swap DPCI adapters

	push	SecDisp 	; Pass adapter #
	call	EnableEROM	; Enable it

	mov	eax,VBDSTR[esi].VBD_EROM ; Get expansion ROM
	and	eax,@PCI_EROM_BASE ; Isolate the high-order 21 bits
	lea	eax,VIDEO_SIZE[eax] ; Plus offset to size byte

	push	eax		; Pass the source physical address

	lea	eax,VBDSTR[esi].VBD_ESIZE ; Get the destin address
	add	eax,LaData	; Plus linear address of data segment
	push	eax		; Pass the destin linear address

	PUSHD	1		; ...  the length in bytes (dword-aligned)
	call	CopyPhysMem	; Copy the byte value to local memory

	movzx	eax,VBDSTR[esi].VBD_ESIZE.LO ; Zero to use as dword
	shl	eax,9-0 	; Convert from 512 bytes to bytes
	mov	VBDSTR[esi].VBD_ESIZE,eax ; Save for later use

; Copy the ROM to low memory

	mov	eax,VBDSTR[esi].VBD_EROM ; Get expansion ROM
	and	eax,@PCI_EROM_BASE ; Isolate the high-order 21 bits
	push	eax		; Pass source address

	push	VBDSTR[esi].VBD_EBASE ; Pass destin address
	push	VBDSTR[esi].VBD_ESIZE ; ...  length in bytes
	call	CopyPhysMem	; Copy the byte value to local memory

	call	SwapDPCI	; Swap DPCI adapters
	call	EnableAGP	; Enable the AGP controller

	DOSCALL @STROUT,MSG_DPCIROM ; Tell 'em what happened

; Check for valid ROM

	push	es		; Save for a moment

	VBDIND	esi,SecDisp	; Get index into VBDSTR of secondary adapter
	les	di,VBDSTR[esi].VBD_EINIT ; ES:DI ==> video display ROM
	assume	es:nothing	; Tell the assembler about it

	cmp	es:[di].EDD,0	; Izit all 0s?
	je	short @F	; Jump if so (note CF=0)

	cmp	es:[di].EDD,-1	; Izit all FFs?
				; Fall through with CF significant
@@:
	pop	es		; Restore
	assume	es:PGROUP	; Tell the assembler about it
	je	short SetupDPCI_XROM ; Jump if so

	call	SaveVideoData	; Save the video data

	call	DisableAGP	; Disable the AGP controller
	call	SwapDPCI	; Swap DPCI adapters

	REGSAVE <ds,es,fs,gs>	; Save for a moment

; Save startup value in reset flag word
; Some video ROMs take a different path depending upon this value.

	mov	ax,seg BIOSDATA ; Get BIOS data area segment
	mov	gs,ax		; Address it
	assume	gs:BIOSDATA	; Tell the assembler about it

	push	RESET_FLAG	; Save old value
	mov	RESET_FLAG,1234h ; Mark as just starting up

	VBDIND	esi,SecDisp	; Get index into VBDSTR of secondary adapter
	mov	al,VBDSTR[esi].VBD_DEVFN ; Get device/function #
	mov	ah,VBDSTR[esi].VBD_BUSNO ; ... bus #
	call	VBDSTR[esi].VBD_EINIT ; Initialize the video display

	pop	RESET_FLAG	; Restore

	REGREST <gs,fs,es,ds>	; Restore
	assume	ds:PGROUP,es:PGROUP ; Tell the assembler about it
	assume	fs:nothing,gs:nothing ; ...

	push	0B800h		; Pass segment #
	call	ClearScrn	; Clear the screen

	push	0B800h		; Pass segment #
	call	DISP_COPY_SCR	; Display our copyright notice on specified screen

	call	SwapDPCI	; Swap DPCI adapters
	call	EnableAGP	; Enable the AGP controller
	call	RestVideoData	; Restore the video data

	DOSCALL @STROUT,MSG_DPCISET ; Tell 'em what happened

	jmp	short SetupDPCI_DONE ; Join common code


SetupDPCI_XROM:
	DOSCALL @STROUT,MSG_DPCIXROM ; Tell 'em what happened
SetupDPCI_DONE:
	popad			; Restore
SetupDPCI_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SetupDPCI endp			; End SetupDPCI procedure
	NPPROC	CopyPhysMem -- Copy Physical Memory
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy physical memory

|

CPM_STR struc

CPM_MDTE db	(type MDTE_STR) dup (?) ; Move Extended memory struc
CPM_EGP db	(type PUSHAD_STR) dup (?) ; Caller's EGP registers
	dw	?		; ...	   IP
CPM_LEN dd	?		; Move length in bytes
CPM_DST dd	?		; Destination address
CPM_SRC dd	?		; Source address

CPM_STR ends

	pushad			; Save all EGP registers
	sub	sp,type MDTE_STR ; Make room for Move Extended Memory struc
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <es>		; Save register

	xor	eax,eax 	; A convenient zero
	mov	[bp].CPM_MDTE.MDTE_DUMMY.EDQLO,eax ; Set to zero
	mov	[bp].CPM_MDTE.MDTE_DUMMY.EDQHI,eax ; ...
	mov	[bp].CPM_MDTE.MDTE_GDT.EDQLO,eax ; ...
	mov	[bp].CPM_MDTE.MDTE_GDT.EDQHI,eax ; ...
	mov	[bp].CPM_MDTE.MDTE_BIOS.EDQLO,eax ; ...
	mov	[bp].CPM_MDTE.MDTE_BIOS.EDQHI,eax ; ...
	mov	[bp].CPM_MDTE.MDTE_SS.EDQLO,eax ; ...
	mov	[bp].CPM_MDTE.MDTE_SS.EDQHI,eax ; ...

	mov	eax,[bp].CPM_LEN ; Get the move length in bytes
	add	eax,2-1 	; Round up to word boundary
	and	eax,not (2-1)	; ...
	mov	[bp].CPM_LEN,eax ; Save for later use
	dec	eax		; Convert from length to limit

	mov	[bp].CPM_MDTE.MDTE_DS.DESC_SEGLM0,ax ; Save move segment limit, bits 0-15
	mov	[bp].CPM_MDTE.MDTE_DS.DESC_SEGLM1,0  ; ...			     16-19

	mov	[bp].CPM_MDTE.MDTE_ES.DESC_SEGLM0,ax ; Save move segment limit, bits 0-15
	mov	[bp].CPM_MDTE.MDTE_ES.DESC_SEGLM1,0  ; ...			     16-19

	mov	eax,[bp].CPM_SRC ; Get the source address
	mov	[bp].CPM_MDTE.MDTE_DS.DESC_BASE01,ax ; Save bits 0-15
	shr	eax,16		; Shift down high-order word
	mov	[bp].CPM_MDTE.MDTE_DS.DESC_BASE2,al ; Save bits 16-23
	mov	[bp].CPM_MDTE.MDTE_DS.DESC_BASE3,ah ; Save bits 24-31
	mov	[bp].CPM_MDTE.MDTE_DS.DESC_ACCESS,CPL0_DATA ; Save A/R byte

	mov	eax,[bp].CPM_DST ; Get the destin address
	mov	[bp].CPM_MDTE.MDTE_ES.DESC_BASE01,ax ; Save bits 0-15
	shr	eax,16		; Shift down high-order word
	mov	[bp].CPM_MDTE.MDTE_ES.DESC_BASE2,al ; Save bits 16-23
	mov	[bp].CPM_MDTE.MDTE_ES.DESC_BASE3,ah ; Save bits 24-31
	mov	[bp].CPM_MDTE.MDTE_ES.DESC_ACCESS,CPL0_DATA ; Save A/R byte

	mov	ax,ss		; Get stack segment
	mov	es,ax		; Address it
	lea	si,[bp].CPM_MDTE ; ES:SI ==> GDT

	mov	ecx,[bp].CPM_LEN ; Get the move length in bytes
	shr	ecx,1-0 	; Convert from bytes to words
	mov	ah,87h		; Function code to read extended memory
	int	15h		; Request BIOS service

	REGREST <es>		; Restore

	add	sp,type MDTE_STR ; Strip from the stack
	popad			; Restore

	ret	4+4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CopyPhysMem endp		; End CopyPhysMem procedure
	NPPROC	PCI_RDBYTE -- PCI Read Configuration Byte
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PCI read configuration byte

On exit:

CL	=	configuration byte value

|

PRB_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
PRB_ADDR dd	?		; Bus/device/function #
PRB_REG db	?,?,?,? 	; Register # (dword-aligned)

PRB_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <eax,edx>	; Save registers

	mov	eax,[bp].PRB_ADDR ; Get the bus/device/function #
	mov	al,[bp].PRB_REG ; Get register #
	and	al,not @PCICFGADDR_00 ; Ensure on dword boundary
	mov	dx,PCI_MECH1_ADDR ; Get mechanism #1 index port address
	out	dx,eax		; Tell the PCI controller
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	dl,[bp].PRB_REG ; Get register #
	and	dx,@PCICFGADDR_00 ; Isolate the low-order bits,
				; clear high-order byte
	add	dx,PCI_MECH1_DATA ; Plus mechanism #1 data port address

	in	al,dx		; Read the configuration byte
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	cl,al		; Copy to return register

	call	ClosePCICfg	; Close the PCI configuration address space

	REGREST <edx,eax>	; Restore

	pop	bp		; Restore

	ret	4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PCI_RDBYTE endp 		; End PCI_RDBYTE procedure
	NPPROC	PCI_RDWORD -- PCI Read Configuration Word
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PCI read configuration word

Note that the register # must be on a word boundary.

On exit:

CX	=	configuration word value

|

PRW_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
PRW_ADDR dd	?		; Bus/device/function #
PRW_REG db	?,?,?,? 	; Register #

PRW_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <eax,edx>	; Save registers

	mov	eax,[bp].PRW_ADDR ; Get the bus/device/function #
	mov	al,[bp].PRW_REG ; Get register #
	and	al,not @PCICFGADDR_00 ; Ensure on dword boundary
	mov	dx,PCI_MECH1_ADDR ; Get mechanism #1 index port address
	out	dx,eax		; Tell the PCI controller
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	dl,[bp].PRW_REG ; Get register #
	and	dx,@PCICFGADDR_00 ; Isolate the low-order bits,
				; clear high-order byte
	add	dx,PCI_MECH1_DATA ; Plus mechanism #1 data port address

	in	ax,dx		; Read the configuration word
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	cx,ax		; Copy to return register

	call	ClosePCICfg	; Close the PCI configuration address space

	REGREST <edx,eax>	; Restore

	pop	bp		; Restore

	ret	4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PCI_RDWORD endp 		; End PCI_RDWORD procedure
	NPPROC	PCI_RDDWORD -- PCI Read Configuration Dword
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PCI read configuration dword

Note that the register # must be on a dword boundary.

On exit:

ECX	=	configuration dword value

|

PRD_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
PRD_ADDR dd	?		; Bus/device/function #
PRD_REG db	?,?,?,? 	; Register #

PRD_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <eax,edx>	; Save registers

	mov	eax,[bp].PRD_ADDR ; Get the bus/device/function #
	mov	al,[bp].PRD_REG ; Get register #
	and	al,not @PCICFGADDR_00 ; Ensure on dword boundary
	mov	dx,PCI_MECH1_ADDR ; Get mechanism #1 index port address
	out	dx,eax		; Tell the PCI controller
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	dx,PCI_MECH1_DATA ; Get mechanism #1 data port address
	in	eax,dx		; Read the configuration dword
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	ecx,eax 	; Copy to return register

	call	ClosePCICfg	; Close the PCI configuration address space

	REGREST <edx,eax>	; Restore

	pop	bp		; Restore

	ret	4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PCI_RDDWORD endp		; End PCI_RDDWORD procedure
	NPPROC	PCI_WRBYTE -- PCI Write Configuration Byte
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PCI write configuration byte

|

PWB_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
PWB_ADDR dd	?		; Bus/device/function #
PWB_REG db	?,?,?,? 	; Register # (dword-aligned)
PWB_VAL db	?,?,?,? 	; Value to write (dword-aligned)

PWB_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <eax,edx>	; Save registers

	mov	eax,[bp].PWB_ADDR ; Get the bus/device/function #
	mov	al,[bp].PWB_REG ; Get register #
	and	al,not @PCICFGADDR_00 ; Ensure on dword boundary
	mov	dx,PCI_MECH1_ADDR ; Get mechanism #1 index port address
	out	dx,eax		; Tell the PCI controller
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	dl,[bp].PWB_REG ; Get register #
	and	dx,@PCICFGADDR_00 ; Isolate the low-order bits,
				; clear high-order byte
	add	dx,PCI_MECH1_DATA ; Plus mechanism #1 data port address

	mov	al,[bp].PWB_VAL ; Get word register value
	out	dx,al		; Tell the PCI controller about it
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	call	ClosePCICfg	; Close the PCI configuration address space

	REGREST <edx,eax>	; Restore

	pop	bp		; Restore

	ret	4+4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PCI_WRBYTE endp 		; End PCI_WRBYTE procedure
	NPPROC	PCI_WRWORD -- PCI Write Configuration Word
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PCI write configuration word

Note that the register # must be on a word boundary.

|

PWW_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
PWW_ADDR dd	?		; Bus/device/function #
PWW_REG db	?,?,?,? 	; Register # (dword-aligned)
PWW_VAL dw	?,?		; Value to write (dword-aligned)

PWW_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <eax,edx>	; Save registers

	mov	eax,[bp].PWW_ADDR ; Get the bus/device/function #
	mov	al,[bp].PWW_REG ; Get register #
	and	al,not @PCICFGADDR_00 ; Ensure on dword boundary
	mov	dx,PCI_MECH1_ADDR ; Get mechanism #1 index port address
	out	dx,eax		; Tell the PCI controller
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	dl,[bp].PWW_REG ; Get register #
	and	dx,@PCICFGADDR_00 ; Isolate the low-order bits,
				; clear high-order byte
	add	dx,PCI_MECH1_DATA ; Plus mechanism #1 data port address

	mov	ax,[bp].PWW_VAL ; Get word register value
	out	dx,ax		; Tell the PCI controller about it
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	call	ClosePCICfg	; Close the PCI configuration address space

	REGREST <edx,eax>	; Restore

	pop	bp		; Restore

	ret	4+4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PCI_WRWORD endp 		; End PCI_WRWORD procedure
	NPPROC	PCI_WRDWORD -- PCI Write Configuration Dword
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PCI write configuration dword

Note that the register # must be on a dword boundary.

|

PWD_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
PWD_ADDR dd	?		; Bus/device/function #
PWD_REG db	?,?,?,? 	; Register # (dword-aligned)
PWD_VAL dd	?		; Value to write

PWD_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <eax,edx>	; Save registers

	mov	eax,[bp].PWD_ADDR ; Get the bus/device/function #
	mov	al,[bp].PWD_REG ; Get register #
	and	al,not @PCICFGADDR_00 ; Ensure on dword boundary
	mov	dx,PCI_MECH1_ADDR ; Get mechanism #1 index port address
	out	dx,eax		; Tell the PCI controller
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	dx,PCI_MECH1_DATA ; Get mechanism #1 data port address
	mov	eax,[bp].PWD_VAL ; Get dword register value
	out	dx,eax		; Tell the PCI controller about it
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	call	ClosePCICfg	; Close the PCI configuration address space

	REGREST <edx,eax>	; Restore

	pop	bp		; Restore

	ret	4+4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PCI_WRDWORD endp		; End PCI_WRDWORD procedure
	NPPROC	ClosePCICfg -- Close PCI Configuration Address Space
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Close PCI configuration address space

|

	REGSAVE <eax,edx>	; Save registers

	xor	eax,eax 	; Close configuration space again
	mov	dx,PCI_MECH1_ADDR ; Get machanism #1 index port address
	out	dx,eax		; Tell the PCI controller about it
;;;;;;; call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	REGREST <edx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ClosePCICfg endp		; End ClosePCICfg procedure
	NPPROC	EnableMonoText -- Enable Monochrome Text Mode
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable monochrome text mode

|

	REGSAVE <ax,dx> 	; Save registers

	mov	dx,@MOD_MDA	; Get mode register
	mov	al,@P3B8_BLINK or @P3B8_VIDEN or @P3B8_TEXT80
	out	dx,al		; Tell the 6845 about the mode
;;;;;;; call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	REGREST <dx,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EnableMonoText endp		; End EnableMonoText procedure
	NPPROC	DisableMonoText -- Disable Monochrome Text Mode
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable monochrome text mode

|

	REGSAVE <ax,dx> 	; Save registers

	mov	dx,@MOD_MDA	; Get mode register
	mov	al,0		; Disable
	out	dx,al		; Tell the 6845 about the mode
;;;;;;; call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	REGREST <dx,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DisableMonoText endp		; End DisableMonoText procedure
	NPPROC	DisableAGP -- Disable AGP Controller
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable AGP controller if present

|

	pushad			; Save registers

	cmp	VBDAGP.VBD_DISCNT,0 ; Izit disable for real?
	jne	short DisableAGPExit ; Jump if not

; If there's an AGP controller, disable the VGA Enable bit

	test	LCL_FLAG,@LCL_AGP ; Izit present?
	jz	short @F	; Jump if not

	mov	cx,VBDAGP.VBD_CTL ; Get initial control register value
	and	cx,not @PCI_BRIDGECTL_VGA_EN ; Disable the VGA Enable bit

	cmp	DirectPCI,@DIRPCI_REGS ; Writing to PCI registers directly?
	jne	short DirPCI7	; Jump if not

	push	ecx		; Pass the word to write (dword-aligned)
	PUSHD	PCIREG01_CTL	; ... register # (Bridge Control) (dword-aligned)
	push	VBDAGP.VBD_ADDR.EDD ; ... the bus/device/function #
	call	PCI_WRWORD	; Write PCI configuration word

	jmp	short DirPCI7Com ; Join common code


DirPCI7:
	mov	bl,VBDAGP.VBD_DEVFN ; Get device/function #
	mov	bh,VBDAGP.VBD_BUSNO ; ... bus #
	mov	di,PCIREG01_CTL ; Register # (Bridge Control)
	PCICALL @PCI_WRWORD	; Write PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; CX = word register value
DirPCI7Com:
@@:
DisableAGPExit:
	inc	VBDAGP.VBD_DISCNT ; Count in another disable

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DisableAGP endp 		; End DisableAGP procedure
	NPPROC	DisableDisps -- Disable Primary & Secondary Displays
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable primary and secondary displays

|

	pushad			; Save registers

; Disable the primary VGA adapter

	cmp	PriDisp,-1	; Izit invalid?
	je	short DisableDisps1B ; Jump if so

	VBDIND	esi,PriDisp	; Get index into VBDSTR of adapter

	cmp	VBDSTR[esi].VBD_DISCNT,0 ; Izit disable for real?
	jne	short DisableDisps1A ; Jump if not

	mov	cx,VBDSTR[esi].VBD_CMD ; Get initial command register value
	and	cx,not (@PCICMD_IO or @PCICMD_MEM) ; Disable the I/O and
				; memory space
	cmp	DirectPCI,@DIRPCI_REGS ; Writing to PCI registers directly?
	jne	short DirPCI8	; Jump if not

	push	ecx		; Pass the word to write (dword-aligned)
	PUSHD	PCIREG00_CMD	; ... register # (Command) (dword-aligned)
	push	VBDSTR[esi].VBD_ADDR.EDD ; ... the bus/device/function #
	call	PCI_WRWORD	; Write PCI configuration word

	jmp	short DirPCI8Com ; Join common code


DirPCI8:
	mov	bl,VBDSTR[esi].VBD_DEVFN ; Get device/function #
	mov	bh,VBDSTR[esi].VBD_BUSNO ; ... bus #
	mov	di,PCIREG00_CMD ; Register # (Command)
	PCICALL @PCI_WRWORD	; Write PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; CX = word register value
DirPCI8Com:
DisableDisps1A:
	inc	VBDSTR[esi].VBD_DISCNT ; Count in another disable
DisableDisps1B:

; Disable the secondary VGA adapter, if present

	test	LCL_FLAG,@LCL_DPCI ; Are there dual PCI VGA adapters?
	jz	short DisableDisps2B ; Jump if not

	VBDIND	esi,SecDisp	; Get index into VBDSTR of adapter

	cmp	VBDSTR[esi].VBD_DISCNT,0 ; Izit disable for real?
	jne	short DisableDisps2A ; Jump if not

	mov	cx,VBDSTR[esi].VBD_CMD ; Get initial command register value
	and	cx,not (@PCICMD_IO or @PCICMD_MEM) ; Disable the I/O and
				; memory space
	cmp	DirectPCI,@DIRPCI_REGS ; Writing to PCI registers directly?
	jne	short DirPCI9	; Jump if not

	push	ecx		; Pass the word to write (dword-aligned)
	PUSHD	PCIREG00_CMD	; ... register # (Command) (dword-aligned)
	push	VBDSTR[esi].VBD_ADDR.EDD ; ... the bus/device/function #
	call	PCI_WRWORD	; Write PCI configuration word

	jmp	short DirPCI9Com ; Join common code


DirPCI9:
	mov	bl,VBDSTR[esi].VBD_DEVFN ; Get device/function #
	mov	bh,VBDSTR[esi].VBD_BUSNO ; ... bus #
	mov	di,PCIREG00_CMD ; Register # (Command)
	PCICALL @PCI_WRWORD	; Write PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; CX = word register value
DirPCI9Com:
DisableDisps2A:
	inc	VBDSTR[esi].VBD_DISCNT ; Count in another disable
DisableDisps2B:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DisableDisps endp		; End DisableDisps procedure
	NPPROC	EnableAGP -- Enable AGP Controller
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable AGP controller, if present

|

	pushad			; Save registers

	cmp	VBDAGP.VBD_DISCNT,1 ; Izit enable for real?
	jne	short EnableAGPExit ; Jump if not

; If there's an AGP controller, enable the VGA Enable bit

	test	LCL_FLAG,@LCL_AGP ; Izit present?
	jz	short @F	; Jump if not

	mov	cx,VBDAGP.VBD_CTL ; Get initial control register value

	cmp	DirectPCI,@DIRPCI_REGS ; Writing to PCI registers directly?
	jne	short DirPCI10	; Jump if not

	push	ecx		; Pass the word to write (dword-aligned)
	PUSHD	PCIREG01_CTL	; ... register # (Bridge Control) (dword-aligned)
	push	VBDAGP.VBD_ADDR.EDD ; ... the bus/device/function #
	call	PCI_WRWORD	; Write PCI configuration word

	jmp	short DirPCI10Com ; Join common code


DirPCI10:
	mov	bl,VBDAGP.VBD_DEVFN ; Get device/function #
	mov	bh,VBDAGP.VBD_BUSNO ; ... bus #
	mov	di,PCIREG01_CTL ; Register # (Bridge Control)
	PCICALL @PCI_WRWORD	; Write PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; CX = word register value
DirPCI10Com:
@@:
EnableAGPExit:
	dec	VBDAGP.VBD_DISCNT ; Count in another enable

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EnableAGP endp			; End EnableAGP procedure
	NPPROC	EnableDisps -- Enable Primary & Secondary Displays
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable primary and secondary displays

|

	pushad			; Save registers

; Re-enable the secondary VGA adapter, if present

	test	LCL_FLAG,@LCL_DPCI ; Are there dual PCI VGA adapters?
	jz	short EnableDisps1B ; Jump if not

	VBDIND	esi,SecDisp	; Get index into VBDSTR of adapter

	cmp	VBDSTR[esi].VBD_DISCNT,1 ; Izit enable for real?
	jne	short EnableDisps1A ; Jump if not

	mov	cx,VBDSTR[esi].VBD_CMD ; Get initial command register value

	cmp	DirectPCI,@DIRPCI_REGS ; Writing to PCI registers directly?
	jne	short DirPCI11	; Jump if not

	push	ecx		; Pass the word to write (dword-aligned)
	PUSHD	PCIREG00_CMD	; ... register # (Command) (dword-aligned)
	push	VBDSTR[esi].VBD_ADDR.EDD ; ... the bus/device/function #
	call	PCI_WRWORD	; Write PCI configuration word

	jmp	short DirPCI11Com ; Join common code


DirPCI11:
	mov	bl,VBDSTR[esi].VBD_DEVFN ; Get device/function #
	mov	bh,VBDSTR[esi].VBD_BUSNO ; ... bus #
	mov	di,PCIREG00_CMD ; Register # (Command)
	PCICALL @PCI_WRWORD	; Write PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; CX = word register value
DirPCI11Com:
EnableDisps1A:
	dec	VBDSTR[esi].VBD_DISCNT ; Count in another enable
EnableDisps1B:

; Re-enable the primary VGA adapter

	cmp	PriDisp,-1	; Izit invalid?
	je	short EnableDisps2B ; Jump if so

	VBDIND	esi,PriDisp	; Get index into VBDSTR of adapter

	cmp	VBDSTR[esi].VBD_DISCNT,1 ; Izit enable for real?
	jne	short EnableDisps2A ; Jump if not

	mov	cx,VBDSTR[esi].VBD_CMD ; Get initial command register value

	cmp	DirectPCI,@DIRPCI_REGS ; Writing to PCI registers directly?
	jne	short DirPCI12	; Jump if not

	push	ecx		; Pass the word to write (dword-aligned)
	PUSHD	PCIREG00_CMD	; ... register # (Command) (dword-aligned)
	push	VBDSTR[esi].VBD_ADDR.EDD ; ... the bus/device/function #
	call	PCI_WRWORD	; Write PCI configuration word

	jmp	short DirPCI12Com ; Join common code


DirPCI12:
	mov	bl,VBDSTR[esi].VBD_DEVFN ; Get device/function #
	mov	bh,VBDSTR[esi].VBD_BUSNO ; ... bus #
	mov	di,PCIREG00_CMD ; Register # (Command)
	PCICALL @PCI_WRWORD	; Write PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; CX = word register value
DirPCI12Com:
EnableDisps2A:
	dec	VBDSTR[esi].VBD_DISCNT ; Count in another enable
EnableDisps2B:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EnableDisps endp		; End EnableDisps procedure
	NPPROC	SwapDPCI -- Swap Active And Inactive Adapters
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Swap active and inactive adapters.

|

	REGSAVE <eax>		; Save register

	mov	eax,ActDisp	; Get index of active display

	push	eax		; Pass index of active display
	call	DisableDPCI	; Disable this adapter

	xchg	eax,InaDisp	; Swap with index of inactive display

	push	eax		; Pass index of inactive display
	call	EnableDPCI	; Enable this adapter

	mov	ActDisp,eax	; Save as active display

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SwapDPCI endp			; End SwapDPCI procedure
	NPPROC	EnableDPCI -- Enable Adapter
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable adapter

|

EDPCI_STR struc

	db	(type PUSHAD_STR) dup (?) ; Caller's EGP registers
	dw	?		; ...	   IP
EDPCI_NUM dd	?		; Adapter #

EDPCI_STR ends

	pushad			; Save all EGP registers
	mov	bp,sp		; Hello, Mr. Stack

	VBDIND	esi,[bp].EDPCI_NUM ; Get index into VBDSTR of adapter

	cmp	VBDSTR[esi].VBD_DISCNT,1 ; Izit enable for real?
	jne	short EnableDPCIExit ; Jump if not

; Read in the command register and enable Memory and I/O Space

	cmp	DirectPCI,@DIRPCI_REGS ; Writing to PCI registers directly?
	jne	short DirPCI13	; Jump if not

	PUSHD	PCIREG00_CMD	; Pass register # (Command) (dword-aligned)
	push	VBDSTR[esi].VBD_ADDR.EDD ; ... the bus/device/function #
	call	PCI_RDWORD	; Read PCI configuration word
				; Return with CX = word register value
	jmp	short DirPCI13Com ; Join common code


DirPCI13:
	mov	bl,VBDSTR[esi].VBD_DEVFN ; Get device/function #
	mov	bh,VBDSTR[esi].VBD_BUSNO ; ... bus #
	mov	di,PCIREG00_CMD ; Register # (Command)
	PCICALL @PCI_RDWORD	; Read PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; Return with CX = word register value
DirPCI13Com:
	or	cx,@PCICMD_MEM or @PCICMD_IO ; Enable the I/O and memory space

	cmp	DirectPCI,@DIRPCI_REGS ; Writing to PCI registers directly?
	jne	short DirPCI14	; Jump if not

	push	ecx		; Pass the word to write (dword-aligned)
	PUSHD	PCIREG00_CMD	; ... register # (Command) (dword-aligned)
	push	VBDSTR[esi].VBD_ADDR.EDD ; ... the bus/device/function #
	call	PCI_WRWORD	; Write PCI configuration word

	jmp	short DirPCI14Com ; Join common code


DirPCI14:
;;;;;;; mov	bl,VBDSTR[esi].VBD_DEVFN ; Get device/function #
;;;;;;; mov	bh,VBDSTR[esi].VBD_BUSNO ; ... bus #
;;;;;;; mov	di,PCIREG00_CMD ; Register # (Command)
	PCICALL @PCI_WRWORD	; Write PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; CX = word register value
DirPCI14Com:

; Update cursor position on screen

	cmp	DirectPCI,@DIRPCI_REGS ; Writing to PCI registers directly?
	jne	short DirPCI15	; Jump if not

	push	VBDSTR[esi].VBD_CURSOR ; Pass the old cursor
	call	SET_CURPOS	; Set it

	jmp	short DirPCI15Com ; Join common code


DirPCI15:
	mov	dx,VBDSTR[esi].VBD_CURSOR ; Get the old cursor
	mov	bh,0		; Display page #
	VIDCALL @SETPOS 	; Set cursor position for page BH
DirPCI15Com:
EnableDPCIExit:
	dec	VBDSTR[esi].VBD_DISCNT ; Count in another enable

	popad			; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EnableDPCI endp 		; End EnableDPCI procedure
	NPPROC	DisableDPCI -- Disable Adapter
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable adapter

|

DDPCI_STR struc

	db	(type PUSHAD_STR) dup (?) ; Caller's EGP registers
	dw	?		; ...	   IP
DDPCI_NUM dd	?		; Adapter #

DDPCI_STR ends

	pushad			; Save all EGP registers
	mov	bp,sp		; Hello, Mr. Stack

	VBDIND	esi,[bp].DDPCI_NUM ; Get index into VBDSTR of adapter

	cmp	VBDSTR[esi].VBD_DISCNT,0 ; Izit disable for real?
	jne	short DisableDPCIExit ; Jump if not

; Remember current cursor position

	cmp	DirectPCI,@DIRPCI_REGS ; Writing to PCI registers directly?
	jne	short DirPCI16	; Jump if not

	call	GET_CURPOS	; Get cursor position as (Row,Col) = (CH,CL)
	mov	dx,cx		; Copy to common register

	jmp	short DirPCI16Com ; Join common code


DirPCI16:
	mov	bh,0		; Display page #
	VIDCALL @GETPOS 	; Return with current cursor position
				; (CH,CL) = (Start, Stop) scan line
				; (DH,DL) = (Row, Col)
DirPCI16Com:
	mov	VBDSTR[esi].VBD_CURSOR,dx ; Save to restore later

; Read in the command register and disable Memory and I/O Space

	cmp	DirectPCI,@DIRPCI_REGS ; Writing to PCI registers directly?
	jne	short DirPCI17	; Jump if not

	PUSHD	PCIREG00_CMD	; Pass register # (Command) (dword-aligned)
	push	VBDSTR[esi].VBD_ADDR.EDD ; ... the bus/device/function #
	call	PCI_RDWORD	; Read PCI configuration word
				; Return with CX = word register value
	jmp	short DirPCI17Com ; Join common code


DirPCI17:
	mov	bl,VBDSTR[esi].VBD_DEVFN ; Get device/function #
	mov	bh,VBDSTR[esi].VBD_BUSNO ; ... bus #
	mov	di,PCIREG00_CMD ; Register # (Command)
	PCICALL @PCI_RDWORD	; Read PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; Return with CX = word register value
DirPCI17Com:
	and	cx,not (@PCICMD_MEM or @PCICMD_IO) ; Disable the I/O and
				; memory space
	cmp	DirectPCI,@DIRPCI_REGS ; Writing to PCI registers directly?
	jne	short DirPCI18	; Jump if not

	push	ecx		; Pass the word to write (dword-aligned)
	PUSHD	PCIREG00_CMD	; ... register # (Command) (dword-aligned)
	push	VBDSTR[esi].VBD_ADDR.EDD ; ... the bus/device/function #
	call	PCI_WRWORD	; Write PCI configuration word

	jmp	short DirPCI18Com ; Join common code


DirPCI18:
;;;;;;; mov	bl,VBDSTR[esi].VBD_DEVFN ; Get device/function #
;;;;;;; mov	bh,VBDSTR[esi].VBD_BUSNO ; ... bus #
;;;;;;; mov	di,PCIREG00_CMD ; Register # (Command)
	PCICALL @PCI_WRWORD	; Write PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; CX = word register value
DirPCI18Com:
DisableDPCIExit:
	inc	VBDSTR[esi].VBD_DISCNT ; Count in another disable

	popad			; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DisableDPCI endp		; End DisableDPCI procedure

CODE	ends			; End CODE segment

	MEND	DPCI		; End DPCI module
