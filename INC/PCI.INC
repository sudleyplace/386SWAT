;' $Header:   P:/PVCS/MAX/INC/PCI.INV   1.0   05 Sep 1995 13:27:44   HENRY  $
;
; (C) Copyright 1994-2001 Qualitas, Inc.     All rights reserved.
;
; PCI.INC
;
; Equates for PCI local bus machines
;
; We may need a first-level scheme to check for machines that can't
; handle an unknown Int 1Ah function.  For now, we'll assume it's
; OK to call the installation check function.

; Function codes are loaded in AX.
; Return from all functions is CF=0 and AH=0 if success; if CF=1,
; AH=error code.
; EAX, EBX, ECX, and EDX may be trashed by calls where their return
; values are not defined.

@PCIERR_OK	equ	00h	; Success
@PCIERR_BADFN	equ	81h	; Invalid function
@PCIERR_BADVID	equ	83h	; Invalid vendor ID
@PCIERR_BADDEV	equ	86h	; Invalid device ID
@PCIERR_BADREG	equ	87h	; Invalid configuration register
@PCIERR_BADSET	equ	88h	; Set failed
@PCIERR_BADBUF	equ	89h	; Buffer too small

PCICALL  macro	 FN
ifnb <FN>
	 mov	 ax,FN		; Get PCI function code
endif
	 int	 1Ah		; Call PCI function dispatch
	 endm			; PCICALL

; PCI v2.1 functions ----------------------------------------------

@PCISIG 	 equ	 ' ICP'

@PCI_INST	 equ	 0B101h ; PCI support query
; AL=hardware flags, BH,BL=BCD interface version, CL=highest bus #,
; EDX=@PCISIG.

@PCI_FINDDEV	 equ	 0B102h ; Find PCI device: CX=Device ID, DX=vendor ID,
				; SI=device index (origin:0)
; Returns BH=bus #, BL:7-3=device #, BL:2-0=function #

@PCI_FINDCLASS	 equ	 0B103h ; Find PCI class: 24-bit class code in ECX,
				; SI=device index (origin:0)
; Returns BH=bus #, BL:7-3=device #, BL:2-0=function #

@PCI_BUSOPS	 equ	 0B106h ; PCI bus-specific operations: BH=bus #,
				; EDX=special cycle data.

@PCI_RDBYTE	 equ	 0B108h ; Read PCI configuration byte: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
; Returns byte in CL.

@PCI_RDWORD	 equ	 0B109h ; Read PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
; Returns word in CX.

@PCI_RDDWORD	 equ	 0B10Ah ; Read PCI configuration dword: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; DI=register # (00h-FFh)
; Returns dword in ECX.

@PCI_WRBYTE	 equ	 0B10Bh ; Write PCI configuration byte: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; CL=value, DI=register # (00h-FFh)

@PCI_WRWORD	 equ	 0B10Ch ; Write PCI configuration word: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; CX=value, DI=register # (00h-FFh)

@PCI_WRDWORD	 equ	 0B10Dh ; Write PCI configuration dword: BH=bus #,
				; BL:7-3=device #, BL:2-0=function #,
				; ECX=value, DI=register # (00h-FFh)

@PCI_GETIRQ	 equ	 0B10Eh ; Get IRQ routing information
				; BX = 0000h
				; DS = segment/selector for F000:0
				; ES:eDI ==> RouteBuffer
; Returns BX = IRQ bitmap

@PCI_SETIRQ	 equ	 0B10Fh ; Set HW Interrupt
				; CH = IRQNum, CL = IntPin, BH = bus #
				; BL:7-3=device #, BL:2-0=function #,
				; DS = segment/selector for F000:0

PCI_RB_STR struc		; PCI Route Buffer

PCI_RB_SIZE dw	?		; Data buffer size
				; (filled in by callee of @PCI_SETIRQ)
PCI_RB_DATA dd	?		; Far ptr to data buffer
				; (filled in by caller of @PCI_SETIRQ)
PCI_RB_IRQ  dw	?		; Bitmap of IRQs dedicated to PCI devices
				; (filled in by caller of @PCI_SETIRQ from result)
PCI_RB_STR ends


PCI_DB_STR struc

PCI_DB_BUSNO db ?		; 00:  Bus #
PCI_DB_DEVNO db ?		; 01:  Device #
PCI_DB_LV_A  db ?		; 02:  Link value for INTA#
PCI_DB_BM_A  dw ?		; 03:  IRQ bitmap for INTA#
PCI_DB_LV_B  db ?		; 05:  Link value for INTB#
PCI_DB_BM_B  dw ?		; 06:  IRQ bitmap for INTB#
PCI_DB_LV_C  db ?		; 08:  Link value for INTC#
PCI_DB_BM_C  dw ?		; 09:  IRQ bitmap for INTC#
PCI_DB_LV_D  db ?		; 0B:  Link value for INTD#
PCI_DB_BM_D  dw ?		; 0C:  IRQ bitmap for INTD#
PCI_DB_SLOT  db ?		; 0E:  Slot #
PCI_DB_RSV15 db ?		; 0F:  Reserved

PCI_DB_STR ends


; PCI hardware characteristics records and equates
; (returned in AL from @PCI_INST)

PCIHWREC record \
 $PCIHW_RSV1:2, \
 $PCIHW_SCG2:1, \
 $PCIHW_SCG1:1, \
 $PCIHW_RSV0:2, \
 $PCIHW_CSA2:1, \
 $PCIHW_CSA1:1

@PCIHW_SCG2 equ (mask $PCIHW_SCG2) ; Special cycle generation mechanism #2 supported
@PCIHW_SCG1 equ (mask $PCIHW_SCG1) ; ...				 1 ...
@PCIHW_CSA2 equ (mask $PCIHW_CSA2) ; Configuration space access mechanism #2 supported
@PCIHW_CSA1 equ (mask $PCIHW_CSA1) ; ...				   1 ...

PCI_MECH1_ADDR	equ 0CF8h
PCI_MECH1_DATA	equ 0CFCh

PCI_MECH2_CFGSP equ 0CF8h
PCI_MECH2_BUSNO equ 0CFAh


; PCI Type 0 Configuration Transaction Record

PCICFG1REC record \
 $PCICFG0_RSV1:21,\
 $PCICFG0_FCN:3,  \
 $PCICFG0_REG:6,  \
 $PCICFG0_RSV0:2	; = 00b


; PCI Type 1 Configuration Transaction Record

PCICFG1REC record \
 $PCICFG1_RSV1:8, \
 $PCICFG1_BUS:8,  \
 $PCICFG1_DEV:5,  \
 $PCICFG1_FCN:3,  \
 $PCICFG1_REG:6,  \
 $PCICFG1_RSV0:2	; = 01b

					; FF000000:  Reserved
@PCICFG1_BUS equ (mask $PCICFG1_BUS)	; 00FF0000:  Bus #
@PCICFG1_DEV equ (mask $PCICFG1_DEV)	; 0000F800:  Device #
@PCICFG1_FCN equ (mask $PCICFG1_FCN)	; 00000700:  Function #
@PCICFG1_REG equ (mask $PCICFG1_REG)	; 000000FC:  Register #
					; 00000003:  = 01


; PCI Configuration Address register

PCICFGADDRREC record \
 $PCICFGADDR_ENA:1,  \
 $PCICFGADDR_RSV1:7, \
 $PCICFGADDR_BUS:8,  \
 $PCICFGADDR_DEV:5,  \
 $PCICFGADDR_FCN:3,  \
 $PCICFGADDR_REG:6,  \
 $PCICFGADDR_00:2	   ; = 00b

@PCICFGADDR_ENA equ (mask $PCICFGADDR_ENA)    ; 80000000:  1 = Enable
					      ; 7F000000:  Reserved
@PCICFGADDR_BUS equ (mask $PCICFGADDR_BUS)    ; 00FF0000:  Bus #
@PCICFGADDR_DEV equ (mask $PCICFGADDR_DEV)    ; 0000F800:  Device #
@PCICFGADDR_FCN equ (mask $PCICFGADDR_FCN)    ; 00000700:  Function #
@PCICFGADDR_REG equ (mask $PCICFGADDR_REG)    ; 000000FC:  Register #
@PCICFGADDR_00	equ (mask $PCICFGADDR_00)     ; 00000003:  = 00


; PCI Find Class Record (@PCI_FINDCLASS)

PCIFCREC record \
 $PCIFC_CLS:8,	\
 $PCIFC_SUB:8,	\
 $PCIFC_IF:8

@PCIFC_CLS equ	(mask $PCIFC_CLS)	; 00FF0000:  Class code
@PCIFC_SUB equ	(mask $PCIFC_SUB)	; 0000FF00:  Subclass code
@PCIFC_IF  equ	(mask $PCIFC_IF)	; 000000FF:  Interface


; PCI Class Names for $PCIFC_CLS above

@PCICLS_ORIG	equ	00h	; Original devices
@PCICLS_DISK	equ	01h	; Disk
@PCICLS_NETW	equ	02h	; Network
@PCICLS_DISP	equ	03h	; Display
@PCICLS_MEDIA	equ	04h	; Multimedia
@PCICLS_MEM	equ	05h	; Memory
@PCICLS_BRIDGE	equ	06h	; Bridge
@PCICLS_COMM	equ	07h	; Communication
@PCICLS_PERI	equ	08h	; System Peripheral
@PCICLS_INP	equ	09h	; Input
@PCICLS_DOCK	equ	0Ah	; Docking Station
@PCICLS_CPU	equ	0Bh	; CPU
@PCICLS_SER	equ	0Ch	; Serial Bus
@PCICLS_WIREL	equ	0Dh	; Wireless
@PCICLS_INTIO	equ	0Eh	; Intelligent I/O controllers
@PCICLS_SATCOM	equ	0Fh	; Satelite communication controllers
@PCICLS_CRYPTO	equ	10h	; Encryption and decryption controllers
@PCICLS_SIG	equ	11h	; Data acquisition & signal processing


; PCI Original (00) subclass names

@PCI_ORIG_ALL	    equ    00h	; All except VGA
@PCI_ORIG_VGA	    equ    01h	; VGA-compatible device


; PCI Disk (01) subclass names

@PCISUB_DISK_SCSI   equ    00h	; SCSI
@PCISUB_DISK_IDE    equ    01h	; IDE
@PCISUB_DISK_FLOPPY equ    02h	; Floppy
@PCISUB_DISK_IPI    equ    03h	; IPI
@PCISUB_DISK_RAID   equ    04h	; RAID
@PCISUB_DISK_OTH    equ    80h	; Other


; PCI Network (02) subclass names

@PCISUB_NETW_ETH  equ	   00h	; Ethernet
@PCISUB_NETW_TOK  equ	   01h	; Token Ring
@PCISUB_NETW_FDDI equ	   02h	; FDDI
@PCISUB_NETW_ATM  equ	   03h	; ATM
@PCISUB_NETW_ISDN equ	   04h	; ISDN
@PCISUB_NETW_OTH  equ	   80h	; Other


; PCI Display (03) subclass names

@PCISUB_DISP_VGA equ	   00h	; VGA
@PCISUB_DISP_XGA equ	   01h	; XGA
@PCISUB_DISP_3D  equ	   02h	; 3D
@PCISUB_DISP_OTH equ	   80h	; Other


; PCI Multimedia (04) subclass names

@PCISUB_MEDIA_VIDEO equ    00h	; Video
@PCISUB_MEDIA_AUDIO equ    01h	; Audio
@PCISUB_MEDIA_TELEP equ    02h	; Computer telephony device
@PCISUB_MEDIA_OTH   equ    80h	; Other


; PCI Memory (05) subclass names

@PCISUB_MEM_RAM   equ	   00h	; RAM
@PCISUB_MEM_FLASH equ	   01h	; Flash
@PCISUB_MEM_OTH   equ	   80h	; Other


; PCI Bridge (06) subclass names

@PCISUB_BRIDGE_CPU     equ 00h	; Host bridge
@PCISUB_BRIDGE_ISA     equ 01h	; ISA bridge
@PCISUB_BRIDGE_EISA    equ 02h	; EISA bridge
@PCISUB_BRIDGE_MCA     equ 03h	; MCA bridge
@PCISUB_BRIDGE_PCI     equ 04h	; PCI/PCI bridge
@PCISUB_BRIDGE_PCMCIA  equ 05h	; PCI/PCMCIA
@PCISUB_BRIDGE_NUBUS   equ 06h	; PCI/NuBus
@PCISUB_BRIDGE_CARDBUS equ 07h	; PCI/CardBus
@PCISUB_BRIDGE_RACEWAY equ 08h	; Raceway
@PCISUB_BRIDGE_OTH     equ 80h	; Other


; PCI Communication (07) subclass names

@PCISUB_COMM_SER equ	   00h	; Serial
@PCISUB_COMM_PAR equ	   01h	; Parallel
@PCISUB_COMM_MUL equ	   02h	; Multiport
@PCISUB_COMM_MOD equ	   03h	; Modem
@PCISUB_COMM_OTH equ	   80h	; Other


; PCI System Peripheral (08) subclass names

@PCISUB_PERI_PIC   equ	   00h	; PIC
@PCISUB_PERI_DMAC  equ	   01h	; DMAC
@PCISUB_PERI_TIMER equ	   02h	; Timer
@PCISUB_PERI_RTC   equ	   03h	; RTC
@PCISUB_PERI_HOT   equ	   04h	; Generic PCI Hot-Plug controller
@PCISUB_PERI_OTH   equ	   80h	; Other


; PCI Input (09) subclass names

@PCISUB_INP_KBD  equ	   00h	; Keyboard
@PCISUB_INP_DIG  equ	   01h	; Digitizer
@PCISUB_INP_MOU  equ	   02h	; Mouse
@PCISUB_INP_SCAN equ	   03h	; Scanner
@PCISUB_INP_GAME equ	   04h	; Gameport
@PCISUB_INP_OTH  equ	   80h	; Other


; PCI Docking Station (0A) subclass names

@PCISUB_DOCK_GEN equ	   00h	; Generic
@PCISUB_DOCK_OTH equ	   80h	; Other


; PCI CPU (0B) subclass names

@PCISUB_CPU_386   equ	   00h	; 386
@PCISUB_CPU_486   equ	   01h	; 486
@PCISUB_CPU_P5	  equ	   02h	; Pentium
@PCISUB_CPU_P6	  equ	   03h	; P6
@PCISUB_CPU_ALPHA equ	   10h	; Alpha
@PCISUB_CPU_POWER equ	   20h	; Power PC
@PCISUB_CPU_MIPS  equ	   30h	; MIPS
@PCISUB_CPU_COPR  equ	   40h	; Coprocessor
@PCISUB_CPU_OTH   equ	   80h	; Other


; PCI Serial Bus (0C) subclass names

@PCISUB_SER_FIRE   equ	   00h	; Firewire
@PCISUB_SER_ACCESS equ	   01h	; ACCESS Bus
@PCISUB_SER_SSA    equ	   02h	; SSA
@PCISUB_SER_USB    equ	   03h	; USB
@PCISUB_SER_FIBER  equ	   04h	; Fiber channel
@PCISUB_SER_OTH    equ	   80h	; Other


; PCI Wireless (0D) subclass names

@PCISUB_WIREL_IRDA equ	   00h	; iRDA
@PCISUB_WIREL_CIR  equ	   01h	; Consumer IR controller
@PCISUB_WIREL_RF   equ	   02h	; RF controller
@PCISUB_WIREL_OTH  equ	   80h	; Other


; PCI Intelligent I/O (0E) subclass names

@PCISUB_INTIO_IIO equ	   00h	; Intelligent I/O (I2O) Architecture


; PCI Satellite Communications (0F) subclass names

@PCISUB_SATCOM_TV     equ  01h	; TV
@PCISUB_SATCOM_AUDIO  equ  02h	; Audio
@PCISUB_SATCOM_VOICE  equ  03h	; Voice
@PCISUB_SATCOM_DATA   equ  04h	; Data


; PCI Crypto (10) subclass names

@PCISUB_CRYPTO_NET equ	   00h	; Network and computing
@PCISUB_CRYPTO_ENT equ	   01h	; Entertainment
@PCISUB_CRYPTO_OTH equ	   80h	; Other


; PCI Data Acquisition (11) subclass names

@PCISUB_SIG_DPIO equ	   00h	; DPIO modules
@PCISUB_SIG_OTH  equ	   80h	; Other


@PCIHDRTYPE_NORM    equ 00h	; Normal header (PCIREG00_REC)
@PCIHDRTYPE_BRIDGE  equ 01h	; Bridge ...	(PCIREG01_REC)
@PCIHDRTYPE_CARDBUS equ 02h	; CardBus ...	(PCIREG02_REC)


; Type 00h (normal) header

PCIREG00_REC struc

PCIREG00_VID dw ?		; 00:  Vendor ID
PCIREG00_DID dw ?		; 02:  Device ID
PCIREG00_CMD dw ?		; 04:  Command (see
PCIREG00_STATUS dw ?		; 06:  Status
PCIREG00_RID db ?		; 08:  Revision ID
PCIREG00_CLS db 3 dup (?)	; 09:  Class code
PCIREG00_CACHELS db ?		; 0C:  Cache Line Size
PCIREG00_LATTIME db ?		; 0D:  Latency Timer
PCIREG00_HDRTYPE db ?		; 0E:  Header type (see @PCIHDRTYPE_xxx)
PCIREG00_BIST db ?		; 0F:  BIST
PCIREG00_BASEADDR dd 6 dup (?)	; 10:  Base address registers (see PCI_BASEADDR_REC)
PCIREG00_CIS dd ?		; 28:  Cardbus CIS pointer
PCIREG00_SVID dw ?		; 2C:  Subsystem vendor ID
PCIREG00_SID dw ?		; 2E:  Susbsytem ID
PCIREG00_EROM dd ?		; 30:  Expansion ROM address (see PCI_EROM_REC)
PCIREG00_CAP db ?		; 34:  Capabilities pointer
PCIREG00_RSV0 db 7 dup (?)	; 35:  Reserved
PCIREG00_ILIN db ?		; 3C:  Interrupt line
PCIREG00_IPIN db ?		; 3D:  Interrupt pin
PCIREG00_MIN_GNT db ?		; 3E:  Minimum Grant
PCIREG00_MAX_LST db ?		; 3F:  Maxiumu Latency

PCIREG00_REC ends


; PCI Configuration Command Register record (PCIREG0x_CMD)

PCICMDREC record \
 $PCICMD_RSV:6,  \
 $PCICMD_B2B:1,  \
 $PCICMD_SERR:1, \
 $PCICMD_WAIT:1, \
 $PCICMD_PAR:1,  \
 $PCICMD_SNOOP:1,\
 $PCICMD_MINV:1, \
 $PCICMD_CYCL:1, \
 $PCICMD_BUSM:1, \
 $PCICMD_MEM:1,  \
 $PCICMD_IO:1

@PCICMD_B2B	equ	(mask $PCICMD_B2B)	; 0200:  Fast back-to-back transactions enabled
@PCICMD_SERR	equ	(mask $PCICMD_SERR)	; 0100:  System error (SERR# line) enabled
@PCICMD_WAIT	equ	(mask $PCICMD_WAIT)	; 0080:  Wait cycles enabled
@PCICMD_PAR	equ	(mask $PCICMD_PAR)	; 0040:  Parity error response enabled
@PCICMD_SNOOP	equ	(mask $PCICMD_SNOOP)	; 0020:  VGA palette snoop enabled
@PCICMD_MINV	equ	(mask $PCICMD_MINV)	; 0010:  Memory write and invalidate enabled
@PCICMD_CYCL	equ	(mask $PCICMD_CYCL)	; 0008:  Special cycle recognition enabled
@PCICMD_BUSM	equ	(mask $PCICMD_BUSM)	; 0004:  Bus master enable
@PCICMD_MEM	equ	(mask $PCICMD_MEM)	; 0002:  Memory access enabled
@PCICMD_IO	equ	(mask $PCICMD_IO)	; 0001:  I/O access enabled

;;PCI_CMDREG_BITS equ @PCICMD_WAIT or @PCICMD_SNOOP or @PCICMD_BUSM or @PCICMD_MEM or @PCICMD_IO


; Record for Expansion ROM base address (PCIREG00_EROM)

PCI_EROM_REC record \
 $PCI_EROM_BASE:21, \
 $PCI_EROM_RSVD:10, \
 $PCI_EROM_ENA:1

@PCI_EROM_BASE equ (mask $PCI_EROM_BASE) ; FFFFF800:  High-order 21 bits
					 ;		of the base address
@PCI_EROM_RSVD equ (mask $PCI_EROM_RSVD) ; 000007FE:  Reserved
@PCI_EROM_ENA  equ (mask $PCI_EROM_ENA)  ; 00000001:  Enabled


; Record for Base Addresses (PCIREG00_BASEADDR)

PCI_BASEADDR_REC record \
 $PCI_BASEADDR_ADDR:28, \
 $PCI_BASEADDR_PRE:1,	\
 $PCI_BASEADDR_TYP:2,	\
 $PCI_BASEADDR_IO:1

@PCI_BASEADDR_ADDR equ (mask $PCI_BASEADDR_ADDR) ; High-order 28 bits of base address
@PCI_BASEADDR_PRE  equ (mask $PCI_BASEADDR_PRE)  ; Mem:  1 = Prefetchable
@PCI_BASEADDR_TYP  equ (mask $PCI_BASEADDR_TYP)  ; Mem:  type (see @PCI_BASEADDR_TYP_xxx below)
@PCI_BASEADDR_IO   equ (mask $PCI_BASEADDR_IO)	 ; 1 = I/O; 0 = memory

@PCI_BASEADDR_TYP32 equ 00b	; Locate anywhere in 32-bit address space
;;;;_BASEADDR_TYP?? equ 01b	; Reserved
@PCI_BASEADDR_TYP64 equ 10b	; Loclate anywhere in 64-bit address space
;;;;_BASEADDR_TYP?? equ 11b	; Reserved


; Type 01h (PCI-to-PCI Bridge) header

PCIREG01_REC struc

PCIREG01_VID dw ?		; 00:  Vendor ID
PCIREG01_DID dw ?		; 02:  Device ID
PCIREG01_CMD dw ?		; 04:  Command
PCIREG01_STATUS dw ?		; 06:  Status
PCIREG01_RID db ?		; 08:  Revision ID
PCIREG01_CLS db 3 dup (?)	; 09:  Class code
PCIREG01_CACHELS db ?		; 0C:  Cache Line Size
PCIREG01_LATTIME db ?		; 0D:  Latency Timer
PCIREG01_HDRTYPE db ?		; 0E:  Header type
PCIREG01_BIST db ?		; 0F:  BIST
PCIREG01_BASEADDR dd 2 dup (?)	; 10:  Base address registers (see PCI_BASEADDR_REC)
PCIREG01_BUS1 db ?		; 18:  Primary bus #
PCIREG01_BUS2 db ?		; 19:  Secondary ...
PCIREG01_BUSS db ?		; 1A:  Subordinate Bus #
PCIREG01_SLT  db ?		; 1B:  Secondary Latency Timer
PCIREG01_IOBASE0 db ?		; 1C:  I/O Base, byte 0
PCIREG01_IOLIM0 db ?		; 1D:  I/O Limit, ...
PCIREG01_STAT2 dw ?		; 1E:  Secondary Status
PCIREG01_MEMBASE dw ?		; 20:  Memory Base
PCIREG01_MEMLIM dw ?		; 22:  Memory Limit
PCIREG01_PMEMBASE01 dw ?	; 24:  Prefetchable Memory Base, bytes 0-1
PCIREG01_PMEMLIM01 dw ? 	; 26:  ...		   Limit, ...
PCIREG01_PMEMBASE234 dd ?	; 28:  ...		   Base, bytes 2-4
PCIREG01_PMEMLIM234 dd ?	; 2C:  ...		   Limit, ...
PCIREG01_IOBASE12 dw ?		; 30:  I/O Base, bytes 1-2
PCIREG01_IOLIM12 dw ?		; 32:  ... Limit, ...
PCIREG01_CAP db ?		; 34:  Capabilities pointer
PCIREG01_RSV0 db 3 dup (?)	; 35:  Reserved
PCIREG01_EROM dd ?		; 38:  Expansion ROM address (see PCI_EROM_REC)
PCIREG01_ILIN db ?		; 3C:  Interrupt line
PCIREG01_IPIN db ?		; 3D:  Interrupt pin
PCIREG01_CTL dw ?		; 3E:  Bridge control (see PCI_BRIDGECTL_REC)

PCIREG01_REC ends


PCI_BRIDGECTL_REC record  \
 $PCI_BRIDGECTL_RSV1:4,   \
 $PCI_BRIDGECTL_DTSERR:1, \
 $PCI_BRIDGECTL_DTS   :1, \
 $PCI_BRIDGECTL_SDT:1,	  \
 $PCI_BRIDGECTL_PDT:1,	  \
 $PCI_BRIDGECTL_B2B:1,	  \
 $PCI_BRIDGECTL_SBR:1,	  \
 $PCI_BRIDGECTL_MAM:1,	  \
 $PCI_BRIDGECTL_RSV0:1,   \
 $PCI_BRIDGECTL_VGA_EN:1, \
 $PCI_BRIDGECTL_ISA_EN:1, \
 $PCI_BRIDGECTL_SERR_EN:1,\
 $PCI_BRIDGECTL_PERR_EN:1

@PCI_BRIDGECTL_RSV1    equ (mask $PCI_BRIDGECTL_RSV1)	 ; F000:  Reserved
@PCI_BRIDGECTL_DTSERR  equ (mask $PCI_BRIDGECTL_DTSERR)  ; 0800:  Discard Timer SERR# Enable
@PCI_BRIDGECTL_DTS     equ (mask $PCI_BRIDGECTL_DTS)	 ; 0400:  Discard Timer Status
@PCI_BRIDGECTL_SDT     equ (mask $PCI_BRIDGECTL_SDT)	 ; 0200:  Secondary Discard Timer
@PCI_BRIDGECTL_PDT     equ (mask $PCI_BRIDGECTL_PDT)	 ; 0100:  Primary Discard Timer
@PCI_BRIDGECTL_B2B     equ (mask $PCI_BRIDGECTL_B2B)	 ; 0080:  Fast Back-to-Back Enable
@PCI_BRIDGECTL_SBR     equ (mask $PCI_BRIDGECTL_SBR)	 ; 0040:  Secondary Bus Reset
@PCI_BRIDGECTL_MAM     equ (mask $PCI_BRIDGECTL_MAM)	 ; 0020:  Master Abort Mode
@PCI_BRIDGECTL_RSV0    equ (mask $PCI_BRIDGECTL_RSV0)	 ; 0010:  Reserved
@PCI_BRIDGECTL_VGA_EN  equ (mask $PCI_BRIDGECTL_VGA_EN)  ; 0008:  VGA Enable
@PCI_BRIDGECTL_ISA_EN  equ (mask $PCI_BRIDGECTL_ISA_EN)  ; 0004:  ISA Enable
@PCI_BRIDGECTL_SERR_EN equ (mask $PCI_BRIDGECTL_SERR_EN) ; 0002:  SERR# Enable
@PCI_BRIDGECTL_PERR_EN equ (mask $PCI_BRIDGECTL_PERR_EN) ; 0001:  Parity Error Response Enable


