	title	PCIROM -- Set PCI Expansion ROM
	page	58,122
	name	PCIROM
COMMENT|

Set PCI expansion ROM

This program enables a PCI expansion ROM at a given
location.

Some code was taken from Ralf Brown's INITDUAL.ASM.
Note that we support access mechanism #1 only.

|

.386
	include MASM.INC
	include DOSCALL.INC
	include PTR.INC
	include PCI.INC
;;;;;;; include BIOSDATA.INC
	include ASCII.INC
;;;;;;; include INTVEC.INC
;;;;;;; include VIDCALL.INC
;;;;;;; include VIDATTR.INC
	include 386.INC
;;;;;;; include 6845.INC
;;;;;;; include DPCI.INC

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


DPCI_DIRECT equ 0		; 0 = BIOS, 1 = direct

DATA	segment use16 dword public 'data' ; Start DATA segment
	assume	ds:PGROUP

	public	LaData
LaData	dd	?		; Linear address of data segment

	public	NUMBERS_LO,NUMBERS_HI
NUMBERS_LO db	'0123456789abcdef' ; Conversion table for BIN2BASE
NUMBERS_HI db	'0123456789ABCDEF' ; ...                  BIN2HEX_SUB


; The following three fields are accessed as a dword,
; so don't change their order.  For Mech #2 mappings, see PCICFGADDRREC.

	public	EROM_ADDR,EROM_BUSNUM,EROM_ACCESS
	public	EROM_DEVFN,EROM_BUSNO,EROM_DEVNO,EROM_FCNNO
	public	EROM_EROM,EROM_BASE,EROM_DATA
EROM_ADDR   dw	?		; Mech #2 I/O port address
EROM_BUSNUM db	?		; Mech #2 bus #
EROM_ACCESS db	?		; Pad to allow DWORD for mech #1 access key

EROM_DEVFN  db	?		; 7-3=device #, 2-0=function #
EROM_BUSNO  db	?		; Bus #
EROM_DEVNO  db	?		; Device #
EROM_FCNNO  db	?		; Function #
EROM_EROM   dd	?		; Exp ROM base address & flags
EROM_BASE   dd	?		; Exp ROM base address
EROM_DATA   db	16 dup (?)	; Exp ROM data

	public	LCL_FLAG
LCL_FLAG dw	0		; Local flags

@LCL_PCI  equ	8000h		; PCI BIOS present
@LCL_ENA  equ	4000h		; Enable PCI ROM
@LCL_DIS  equ	2000h		; Disable ...
@LCL_SET  equ	1000h		; Set	 PCI ROM base address
@LCL_ADDR equ	0800h		; Base address present


	public	PCI_Version,PCI_HW_Char,PCI_HW_Acc
PCI_Version dw	?		; PCI version #
PCI_HW_Char db	?		; PCI HW characteristics
PCI_HW_Acc db	?		; PCI HW access method (1 or 2)

@PCI_HW_ACC1 equ 1		; Access method #1
@PCI_HW_ACC2 equ 2		; ...		 2

	public	MSG_COPY,MSG_BASE,MSG_NBASE,MSG_ENA,MSG_DIS,MSG_DATA
MSG_COPY db	'PCIROM   -- Version 1.00 -- Set PCI Expansion ROM',CR,LF
	db	'  (C) Copyright 2001 Qualitas, Inc.  All rights reserved.',CR,LF,EOS
MSG_BASE db	'Base address & flags are '
MSG_BASE1 db	'________h.',CR,LF
	db	EOS
MSG_NBASE db	'Set base addr & flags to '
MSG_NBASE1 db	'________h.',CR,LF
	db	EOS
MSG_ENA db	'Expansion ROM is enabled.',CR,LF
	db	EOS
MSG_DIS db	'Expansion ROM is disabled.',CR,LF
	db	EOS
MSG_DATA db	16 dup ('__ '),CR,LF
	db	EOS

	public	MSG_HELP
MSG_HELP db	CR,LF
	db	'Syntax:   PCIROM bus dev fn         to display the Expansion ROM info',CR,LF
	db	'          PCIROM bus dev fn [@addr] to set a new base address',CR,LF
	db	'          PCIROM bus dev fn [+addr] to set & enable ...',CR,LF
	db	'          PCIROM bus dev fn [-addr] to set & disable ...',CR,LF
	db	'          PCIROM bus dev fn [+|-]   to enable or disable w/o set.',CR,LF
	db	EOS

DATA	ends			; End DATA segment


CODE	segment use16 byte public 'code' ; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP,es:PGROUP
.xlist
	include PSP.INC
.list
	NPPROC	PCIROM -- Set PCI Expansion ROM
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set PCI expansion ROM

|

	lea	sp,LCLSTKZ	; Switch to local stack

	DOSCALL @STROUT,MSG_COPY ; Display the flag

	xor	eax,eax 	; Zero to use as dword
	mov	ax,ds		; Get data segment
	shl	eax,4-0 	; Convert from paras to bytes
	mov	LaData,eax	; Save for later use

	call	CHECK_ARGS	; Parse the command line
	jc	short PCIROM_HELP ; Jump if something went wrong

	call	CHECK_PCI_BIOS	; Check on PCI BIOS

	test	LCL_FLAG,@LCL_PCI ; Izit present?
	jz	short PCIROM_EXIT ; Jump if not *FIXME*

	call	ReadEROM	; Read in the expansion ROM info

	test	LCL_FLAG,@LCL_SET ; Set new base address?
	jz	short @F	; Jump if not

	call	SetEROM 	; Set new base address
@@:
	test	LCL_FLAG,@LCL_ENA or @LCL_DIS ; Enable or disable exp ROM?
	jz	short @F	; Jump if not

	call	EnaDisEROM	; Enable or disable EROM
@@:

; If the ROM is enabled, read in its data

	test	EROM_EROM,@PCI_EROM_ENA ; Izit enabled?
	jz	short @F	; Jump if not

	call	ReadData	; Read & format the ROM data
@@:
	jmp	short PCIROM_EXIT ; Join common exit code


PCIROM_HELP:
	DOSCALL @STROUT,MSG_HELP ; Give 'em a hand
PCIROM_EXIT:
	DOSCALL @EXITRC 	; Return to DOS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PCIROM	endp			; End PCIROM procedure
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
CHECK_PCI_BIOS_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PCI_BIOS endp		; End CHECK_PCI_BIOS procedure
	NPPROC	ReadEROM -- Read In The Expansion ROM Info
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read in the expansion ROM info

|

	pushad			; Save all EGP registers

; Read in the Expansion ROM register and save it

if DPCI_DIRECT
	PUSHD	PCIREG00_EROM	; Pass register # (Expansion ROM) (dword-aligned)
	push	EROM_ADDR.EDD	; ... the bus/device/function #
	call	PCI_RDDWORD	; Read PCI configuration dword
				; Return with ECX = dword register value
else
	mov	bl,EROM_DEVFN	; Get device/function #
	mov	bh,EROM_BUSNO	; ... bus #
	mov	di,PCIREG00_EROM ; Register # (Expansion ROM)
	PCICALL @PCI_RDDWORD	; Read PCI configuration dword: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; Return with ECX = dword register value
	cmp	ah,@PCIERR_OK	; Izit OK?
	jne	short @F	; Jump if not
endif
	mov	EROM_EROM,ecx	; Save for later use

; Display the base address & flags

	call	DispBase	; Display it
@@:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ReadEROM endp			; End ReadEROM procedure
	NPPROC	DispBase -- Display base Address And Flags
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display base address & flags

|

	pushad			; Save registers

	mov	eax,EROM_EROM	; Get base address & flags
	lea	di,MSG_BASE1	; ES:DI ==> output save area
	call	DD2HEX		; Convert EAX to ASCII hex at ES:DI

	DOSCALL @STROUT,MSG_BASE ; Display the base address

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DispBase endp			; End DispBase procedure
	NPPROC	SetEROM -- Set Expansion ROM Base Address
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set expansion ROM base address

|

	pushad			; Save all EGP registers

; Set the Expansion ROM base address

	mov	ecx,EROM_BASE	; Get new base address
	mov	eax,EROM_EROM	; Get base address
	and	eax,@PCI_EROM_ENA ; Isolate the enable bit
	or	ecx,eax 	; Include in base address
	mov	EROM_EROM,ecx	; Save as new base address
if DPCI_DIRECT
	push	ecx		; Pass the dword to write
	PUSHD	PCIREG00_EROM	; ... register # (dword-aligned) (dword-aligned)
	push	EROM_ADDR.EDD	; ... the bus/device/function #
	call	PCI_WRDWORD	; Write PCI configuration dword
else
	mov	bl,EROM_DEVFN	; Get device/function #
	mov	bh,EROM_BUSNO	; ... bus #
	mov	di,PCIREG00_EROM ; Register # (Expansion ROM)
	PCICALL @PCI_WRDWORD	; Write PCI configuration dword: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; ECX = dword register value
	cmp	ah,@PCIERR_OK	; Izit OK?
	jne	short @F	; Jump if not
endif

; Tell 'em what we did

	mov	eax,EROM_EROM	; Get base address & flags
	lea	di,MSG_NBASE1	; ES:DI ==> output save area
	call	DD2HEX		; Convert EAX to ASCII hex at ES:DI

	DOSCALL @STROUT,MSG_NBASE ; Display the base address

	call	ReadEROM	; Read in the expansion ROM info
@@:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SetEROM endp			; End SetEROM procedure
	NPPROC	EnaDisEROM -- Enable Or Disable Expansion ROM
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable or disable expansion ROM

|

	pushad			; Save all EGP registers

; Enable or disable the Expansion ROM in extended memory

	mov	ecx,EROM_EROM	; Get base address
	and	ecx,not @PCI_EROM_ENA ; Clear the enable bit

	test	LCL_FLAG,@LCL_ENA ; Enable the exp ROM?
	jz	short @F	; Jump if not

	or	ecx,@PCI_EROM_ENA ; Enable the ROM
@@:
if DPCI_DIRECT
	push	ecx		; Pass the dword to write
	PUSHD	PCIREG00_EROM	; ... register # (dword-aligned) (dword-aligned)
	push	EROM_ADDR.EDD	; ... the bus/device/function #
	call	PCI_WRDWORD	; Write PCI configuration dword
else
	mov	bl,EROM_DEVFN	; Get device/function #
	mov	bh,EROM_BUSNO	; ... bus #
	mov	di,PCIREG00_EROM ; Register # (Expansion ROM)
	PCICALL @PCI_WRDWORD	; Write PCI configuration dword: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
				; ECX = dword register value
	cmp	ah,@PCIERR_OK	; Izit OK?
	jne	short EnaDisEROMExit ; Jump if not
endif

; Tell 'em what we did

	test	LCL_FLAG,@LCL_ENA ; Izit enabled?
	lea	dx,MSG_ENA	; Assume so
	jnz	short @F	; Jump if so

	lea	dx,MSG_DIS	; It's disabled
@@:
	DOSCALL @STROUT 	; Tell 'em what we did

	call	ReadEROM	; Read in the expansion ROM info
EnaDisEROMExit:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EnaDisEROM endp 		; End EnaDisEROM procedure
	NPPROC	ReadData -- Read And Format EROM Data
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read and format expansion ROM data

|

	pushad			; Save registers

	mov	eax,EROM_EROM	; Get base address
;;;;;;; and	eax,@PCI_EROM_BASE ; Isolate the base address
	and	eax,not @PCI_EROM_ENA ; Clear the enable bit

	push	eax		; Pass the source physical address

	lea	eax,EROM_DATA	; Get the destin address
	add	eax,LaData	; Plus linear address of data segment
	push	eax		; Pass the destin linear address

	PUSHD	<size EROM_DATA> ; ...	the length in bytes (dword-aligned)
	call	CopyPhysMem	; Copy the byte value to local memory

; Display the bytes

	mov	cx,size EROM_DATA ; Get # bytes
	lea	si,EROM_DATA	; DS:SI ==> EROM data
	lea	di,MSG_DATA	; ES:DI => output save area
@@:
	lods	ds:[si].LO	; Get next data byte

	call	DB2HEX		; Convert AL to ASCII hex at ES:DI
	inc	di		; Skip over space

	loop	@B		; Jump if more bytes to format

	DOSCALL @STROUT,MSG_DATA ; Display the data

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ReadData endp			; End ReadData procedure
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
	NPPROC	DRAINPIQ -- Drain The Prefetch Instruction Queue
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Drain the Prefetch Instruction Queue.

If we're on a Micro Channel system, write to I/O port 4Fh.
Otherwise, just jump a few times.

Flags are saved and restored over this routine to allow it
to be used with impunity.

|

	pushfd			; Save flags

;;;;;;; test	SWATINI.MD_ATTR,@MD_MCA ; Izit an MCA-compatible?
;;;;;;; jz	short @F	; Not this time
;;;;;;;
;;;;;;; out	@8253_XCIO,al	; Write to (presumably uncached) port
@@:
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay

	popfd			; Restore flags

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DRAINPIQ endp			; End DRAINPIQ procedure
	NPPROC	CHECK_ARGS -- Parse The Command Line
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT!

Parse the command line

Syntax:

PCIROM bus dev fn [@addr]	Set EROM base address
       bus dev fn [+addr]	Set & enable ...
       bus dev fn [-addr]	Set & disable ...
       bus dev fn [+|-] 	Enable or Disable

On exit:

CF	=	0 if successful
	=	1 if not

!

	pushad			; Save registers

	lea	si,PSP_PARM_STRING ; DS:SI ==> command line

	movzx	bx,PSP_PARM_COUNT ; Get the string count
	mov	PGROUP:[bx+si].LO,0 ; Terminate it
CHECK_ARGS_NEXT1:

; Pick off bus #

	call	SKIP_WHITE	; Skip over white space
				; Return current char in AL
	cmp	al,0		; Izit EOL?
	je	near ptr CHECK_ARGS_ERR ; Jump if so

	cmp	al,CR		; Izit EOL?
	je	near ptr CHECK_ARGS_ERR ; Jump if so

	mov	cx,10		; Use base 10
	call	BASE2BIN	; Convert base 10 ASCII @ DS:SI to binary in EAX
;;;;;;; jc	short ???	; Jump if something went wrong

	mov	EROM_BUSNO,al	; Save as bus #

; Pick off dev #

	call	SKIP_WHITE	; Skip over white space
				; Return current char in AL
	cmp	al,0		; Izit EOL?
	je	near ptr CHECK_ARGS_ERR ; Jump if so

	cmp	al,CR		; Izit EOL?
	je	near ptr CHECK_ARGS_ERR ; Jump if so

	mov	cx,10		; Use base 10
	call	BASE2BIN	; Convert base 10 ASCII @ DS:SI to binary in EAX
;;;;;;; jc	short ???	; Jump if something went wrong

	mov	EROM_DEVNO,al	; Save as bus #

; Pick off fcn #

	call	SKIP_WHITE	; Skip over white space
				; Return current char in AL
	cmp	al,0		; Izit EOL?
	je	near ptr CHECK_ARGS_ERR ; Jump if so

	cmp	al,CR		; Izit EOL?
	je	near ptr CHECK_ARGS_ERR ; Jump if so

	mov	cx,10		; Use base 10
	call	BASE2BIN	; Convert base 10 ASCII @ DS:SI to binary in EAX
;;;;;;; jc	short ???	; Jump if something went wrong

	mov	EROM_FCNNO,al	; Save as bus #

; Pack the values together

	mov	al,EROM_DEVNO	; Get device #
	shl	al,3		; 7-3=device #
	or	al,EROM_FCNNO	; 7-3=device #, 2-0=function #
	mov	EROM_DEVFN,al	; Save for later use

	mov	bh,EROM_BUSNO	; Get bus #
	mov	bl,EROM_DEVFN	; Get device/function #
	call	ConvertDeviceAddress ; Convert to direct addressing format
				; Return in EAX
	mov	EROM_ADDR.EDD,eax ; Save for later use

; Check for optional flags & base address

	call	SKIP_WHITE	; Skip over white space
				; Return current char in AL
	cmp	al,0		; Izit EOL?
	je	short CHECK_ARGS_DONE ; Jump if so

	cmp	al,CR		; Izit EOL?
	je	short CHECK_ARGS_DONE ; Jump if so

	cmp	al,'+'          ; Izit enable?
	jne	short @F	; Jump if not

	or	LCL_FLAG,@LCL_ENA ; Mark as enabling
	inc	si		; Skip over separator
@@:
	cmp	al,'-'          ; Izit disable?
	jne	short @F	; Jump if not

	or	LCL_FLAG,@LCL_DIS ; Mark as disabling
	inc	si		; Skip over separator
@@:
	cmp	al,'@'          ; Izit base address marker?
	jne	short @F	; Jump if not

	or	LCL_FLAG,@LCL_SET ; Mark as to be set
	inc	si		; Skip over separator
@@:
	test	LCL_FLAG,@LCL_ENA or @LCL_DIS or @LCL_SET ; Flags present?
	jz	short CHECK_ARGS_ERR ; Jump if not

	call	SKIP_WHITE	; Skip over white space
				; Return current char in AL
	cmp	al,0		; Izit EOL?
	je	short CHECK_ARGS_DONE ; Jump if so

	cmp	al,CR		; Izit EOL?
	je	short CHECK_ARGS_DONE ; Jump if so

	mov	cx,16		; Use base 16
	call	BASE2BIN	; Convert base 16 ASCII @ DS:SI to binary in EAX
;;;;;;; jc	short ???	; Jump if something went wrong

	mov	EROM_BASE,eax	; Save for later use

	or	LCL_FLAG,@LCL_ADDR or @LCL_SET ; Mark as address present & to be set
CHECK_ARGS_DONE:

; Catch the case where '@' has no following address

	test	LCL_FLAG,@LCL_SET ; Izit to be set?
	jz	short @F	; Jump if not

	test	LCL_FLAG,@LCL_ADDR ; Izit present?
	jz	short CHECK_ARGS_ERR ; Jump if not
@@:
	clc			; Mark as successful

	jmp	short CHECK_ARGS_EXIT ; Join common exit code


CHECK_ARGS_ERR:

	stc			; Mark as in error
CHECK_ARGS_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ARGS endp 		; End CHECK_ARGS procedure
	NPPROC	SKIP_WHITE -- Skip Over White Space
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over white space

On entry:

DS:SI	==>	command line

On exit:

AL	=	non-white space character
DS:SI	==>	(updated)

|

@@:
	lods	ds:[si].LO	; Get next character

	cmp	al,' '          ; Izit white space?
	je	short @B	; Yes, go around again

	cmp	al,TAB		; Izit white space?
	je	short @B	; Yes, go around again

	dec	si		; Back off to previous character

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SKIP_WHITE endp 		; End SKIP_WHITE procedure
	NPPROC	BASE2BIN -- Convert From Specified Base to Binary
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BASE2BIN -- Convert the number at DS:SI in base CX to binary.
The converted # is returned in EAX.

On entry:

CX	=	number base
DS:SI	==>	input save area

On exit:

CF	=	1 if overflow
	=	0 if OK
EAX	=	converted #

|

	REGSAVE <ebx,ecx,edx,edi> ; Save registers

	xor	ebx,ebx 	; Zero accumulator
	movzx	ecx,cx		; Zero to use as dword
BASE2BIN_NEXT:
	lods	ds:[si].LO	; Get next digit
	call	LOWERCASE	; Convert to lowercase

	lea	edi,NUMBERS_LO	; Get address of number conversion table
	push	cx		; Save number base (and table length)
  repne scas	NUMBERS_LO[di]	; Look for the character
	pop	cx		; Restore number base
	jne	short BASE2BIN_DONE ; Not one of ours

	sub	di,(type NUMBERS_LO) + offset es:NUMBERS_LO ; Convert to origin 0
	mov	eax,ebx 	; Copy old to multiply by base

	mul	ecx		; Shift over accumulated #
	jc	short BASE2BIN_OVF ; Jump if out of range

	mov	ebx,eax 	; Copy back
	add	ebx,edi 	; Add in new #
	jnc	short BASE2BIN_NEXT ; Jump if in range
BASE2BIN_OVF:
	stc			; Indicate something went wrong

	jmp	short BASE2BIN_EXIT ; Join common exit code

BASE2BIN_DONE:
	dec	si		; Back off to previous character
	mov	eax,ebx 	; Place result in accumulator

	clc			; Indicate all went well
BASE2BIN_EXIT:
	REGREST <edi,edx,ecx,ebx> ; Restore registers

	ret			; Return to caller with number in EAX

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BASE2BIN endp			; End BASE2BIN procedure
	NPPROC	LOWERCASE -- Convert AL to Lowercase
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AL to lowercase.

On entry:

AL	=	value to convert

On exit:

AL	=	converted value

|

	cmp	al,'A'          ; Check against lower limit
	jb	short @F	; Jump if too small

	cmp	al,'Z'          ; Check against upper limit
	ja	short @F	; Jump if too big

	add	al,'a'-'A'      ; Convert to lowercase
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOWERCASE endp			; End LOWERCASE procedure
	NPPROC	DB2HEX -- Convert AL to Hex At ES:DI
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	push	ecx		; Save for a moment
	mov	ecx,2		; # hex digits
	call	BIN2HEX_SUB	; Handle by subroutine
	pop	ecx		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DB2HEX	endp			; End DB2HEX procedure
	NPPROC	DD2HEX -- Convert EAX to Hex At ES:DI
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	push	ecx		; Save for a moment
	mov	ecx,8		; # hex digits
	call	BIN2HEX_SUB	; Handle by subroutine
	pop	ecx		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DD2HEX	endp			; End DD2HEX procedure
	NPPROC	BIN2HEX_SUB
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	REGSAVE <eax,ebx,edx>	; Save registers

	pushfd			; Save flags
	std			; Store backwards

	mov	edx,eax 	; Copy to secondary register
	lea	bx,NUMBERS_HI	; XLAT table
	add	di,cx		; Skip to the end+1

	push	di		; Save to return

	dec	di		; Now the last digit
BIN2HEX_MORE:
	mov	al,dl		; Copy to XLAT register
	and	al,0Fh		; Isolate low-order digit
	xlat	NUMBERS_HI[bx]	; Convert to ASCII hex
	stos	es:[di].LO	; Save in output stream

	shr	edx,4		; Shift next digit down to low-order

	loop	BIN2HEX_MORE	; Jump if more digits to format

	pop	di		; Restore

	popfd			; Restore flags

	REGREST <edx,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2HEX_SUB endp		; End BIN2HEX_SUB procedure

CODE	ends			; End CODE segment

	MEND	PCIROM		; End PCIROM module
