;' $Header$
;
; (C) Copyright 2000 Qualitas, Inc.  All rights reserved.
;
; SMBIOS.INC
;
; SMBIOS and DMI macros, strucs, and equates
; This data is current through SMBIOS Version 2.3.1 - 16 March 1999.


@SMBIOS_SIG equ <'_MS_'>        ; SMBIOS signature

@DMI_SIG  equ	<'_IMD_'>       ; DMI signature
@DMI_SIG1 equ	'IMD_'          ; DMI ...       part 1
@DMI_SIG2 equ	'_'             ; DMI ...       ...  2


DMI_STR struc

DMI_SIG db	@DMI_SIG	; 00:  Signature
DMI_CSUM db	?		; 05:  Checksum
DMI_LEN dw	?		; 06:  Length of DMI Struc Table pointed to by DMI_ADDR
DMI_ADDR dd	?		; 08:  Physical address of Strucs
DMI_CNT dw	?		; 0C:  # Strucs pointed to by DMI_ADDR
DMI_REV db	?		; 0E:  Revision as BCD byte

DMI_STR ends


SMBIOS_STR struc

SMBIOS_SIG db	@SMBIOS_SIG	; 00:  Signature
SMBIOS_CSUM db	?		; 04:  Checksum
SMBIOS_LEN db	?		; 05:  Entry point length
SMBIOS_REVMAJ db ?		; 06:  Major revision #
SMBIOS_REVMIN db ?		; 07:  Minor revision #
SMBIOS_MAXSTR dw ?		; 08:  Maximum Structure Size
SMBIOS_EPREV db ?		; 0A:  Entry Point Revision
SMBIOS_RSVD db	5 dup (?)	; 0B:  Reserved
SMBIOS_DMI db	(type DMI_STR) dup (?) ; 10:  DMI Structure

SMBIOS_STR ends



@SMB_BIOSINFO equ	0	; BIOS Information
@SMB_SYSINFO  equ	1	; System Information
@SMB_BASEINFO equ	2	; Base Board Information
@SMB_SYSENC   equ	3	; System Enclosure or Chassis
@SMB_CPU      equ	4	; Processor Information
@SMB_MEMCTRL  equ	5	; Memory Controller Information
@SMB_MEMMOD   equ	6	; Memory Module Information
@SMB_CACHE    equ	7	; Cache Information
@SMB_PORTCON  equ	8	; Port Connector Information
@SMB_SLOTS    equ	9	; System Slots
@SMB_ONBOARD  equ      10	; On Board Devices Information
@SMB_OEMSTR   equ      11	; OEM Strings
@SMB_SYSCFG   equ      12	; System Configuration Options
@SMB_LANG     equ      13	; BIOS Language Information
@SMB_GRP      equ      14	; Group Associations
@SMB_EVENT    equ      15	; System Event Log
@SMB_PHYSMEM  equ      16	; Physical Memory Array
@SMB_MEMDEV   equ      17	; Memory Device
@SMB_MEMERR32 equ      18	; 32-bit Memory Error Information
@SMB_MEMMAP   equ      19	; Memory Array Mapped Address
@SMB_MEMDEVMAP equ     20	; Memory Device Mapped Address
@SMB_POINTER  equ      21	; Built-in Pointing Device
@SMB_BATTERY  equ      22	; Portable Battery
@SMB_RESET    equ      23	; System Reset
@SMB_SECURITY equ      24	; Hardware Security
@SMB_POWER    equ      25	; System Power Controls
@SMB_VOLTAGE  equ      26	; Voltage Probe
@SMB_COOL     equ      27	; Cooling Device
@SMB_TEMP     equ      28	; Tempature Probe
@SMB_CURRENT  equ      29	; Electrical Current Probe
@SMB_OOBREM   equ      30	; Out-of-Band Remote Access
@SMB_BIS      equ      31	; Boot Integrity Services (BIS) Entry Point
@SMB_SYSBOOT  equ      32	; System Boot Information
@SMB_MEMERR64 equ      33	; 64-bit Memory Error Information
@SMB_MGT      equ      34	; Management Device
@SMB_MGTCMP   equ      35	; Management Device Component
@SMB_MGTTHR   equ      36	; Management Device Threshold Data
@SMB_MEMCHAN  equ      37	; Memory Channel
@SMB_IPMI     equ      38	; IPMI Device Information
@SMB_SPS      equ      39	; System Power Supply
@SMB_INACTIVE equ     126	; Inactive
@SMB_EOT      equ     127	; End-of-Table


SMBHDR_STR struc		; Header structure

SMBHDR_TYPE db	?		; Type
SMBHDR_LEN  db	?		; Length in bytes (including the header
				; but not the string set)
SMBHDR_HNDL dw	?		; Handle

SMBHDR_STR ends


; =========================== Type 0:  BIOS Information ======================

SMB0_STR struc			; Type 0:  BIOS Information

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB0_VENDOR  db ?		; 04:  Vendor string
SMB0_VERSION db ?		; 05:  Version string
SMB0_START   dw ?		; 06:  Starting address segment
SMB0_RELDATE db ?		; 08:  Release date string
SMB0_ROMSIZE db ?		; 09:  ROM Size (n) where 64K*(n+1) is physical size
SMB0_CHAR_EDQLO_ELO dw ?	; 0A:  Characteristics record (see SMB0_CHAR_REC_EDQLO_ELO)
SMB0_CHAR_EDQLO_EHI dw ?	; 0C:  ...		      (see SMB0_CHAR_REC_EDQLO_EHI)
SMB0_CHAR_EDQHI dd ?		; 0E:  ...		      (see SMB0_CHAR_REC_EDQHI)
SMB0_CHAREXT1 db ?		; 12:  Characteristics extension #1 record
SMB0_CHAREXT2 db ?		; 13:  ...			 #2 ...

SMB0_STR ends


; BIOS Characteristics High Dword

SMB0_CHAR_REC_EDQHI record $SMB0_CHAR_SYSVEN:16,$SMB0_CHAR_BIOSVEN:16


; BIOS Characteristics Low Dword, High Word
SMB0_CHAR_REC_EDQLO_EHI record \
$SMB0_CHAR_NEC98:1, \
$SMB0_CHAR_INT10:1, \
$SMB0_CHAR_INT17:1, \
$SMB0_CHAR_INT14:1, \
$SMB0_CHAR_INT09:1, \
$SMB0_CHAR_INT05:1, \
$SMB0_CHAR_INT13_288:1, \
$SMB0_CHAR_INT13_720:1, \
$SMB0_CHAR_INT13_12:1, \
$SMB0_CHAR_INT13_360:1, \
$SMB0_CHAR_INT13_TOSH12:1, \
$SMB0_CHAR_INT13_NEC12:1, \
$SMB0_CHAR_EDD:1, \
$SMB0_CHAR_BOOTCARD:1, \
$SMB0_CHAR_ROMSOCKET:1, \
$SMB0_CHAR_BOOTSEL:1


; BIOS Characteristics Low Dword, Low Word
SMB0_CHAR_REC_EDQLO_ELO record \
$SMB0_CHAR_BOOTCD:1, \
$SMB0_CHAR_ESCD:1, \
$SMB0_CHAR_VESA:1, \
$SMB0_CHAR_SHADOW:1, \
$SMB0_CHAR_FLASH:1, \
$SMB0_CHAR_APM:1, \
$SMB0_CHAR_PNP:1, \
$SMB0_CHAR_PCCARD:1, \
$SMB0_CHAR_PCI:1, \
$SMB0_CHAR_EISA:1, \
$SMB0_CHAR_MCA:1, \
$SMB0_CHAR_ISA:1, \
$SMB0_CHAR_XCHAR:1, \
$SMB0_CHAR_UNK:1, \
$SMB0_CHAR_RSV0:2


; BIOS Characteristics Extension Byte 1

SMB0_CHAREXT1_REC record \
$SMB0_CHAREXT1_SBATT:1, \
$SMB0_CHAREXT1_BOOT1394:1, \
$SMB0_CHAREXT1_BOOTZIP:1, \
$SMB0_CHAREXT1_LS120:1, \
$SMB0_CHAREXT1_I2O:1, \
$SMB0_CHAREXT1_AGP:1, \
$SMB0_CHAREXT1_USBL:1, \
$SMB0_CHAREXT1_ACPI:1


; BIOS Characteristics Extension Byte 2

SMB0_CHAREXT2_REC record \
$SMB0_CHAREXT2_RSV1:6,	  \
$SMB0_CHAREXT2_NETBOOT:1, \
$SMB0_CHAREXT2_BOOTSPEC:1


; =========================== Type 1:  System Information ====================

SMB1_STR struc			; Type 1: System Information

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB1_MFR  db	?		; 04:  Manufacturer string
SMB1_PROD db	?		; 05:  Product Name string
SMB1_VER  db	?		; 06:  Version string
SMB1_SN   db	?		; 07:  Serial # string
SMB1_UUID db	16 dup (?)	; 08:  Universal Unique ID #
SMB1_WAKE db	?		; 18:  Wake-up Type enum (see @SMB1_WAKE_xxx)

SMB1_STR ends


@SMB1_WAKE_RSV0  equ	0	; Reserved 0
@SMB1_WAKE_OTHER equ	1	; Other
@SMB1_WAKE_UNK	 equ	2	; Unknown
@SMB1_WAKE_APM	 equ	3	; APM Timer
@SMB1_WAKE_MODEM equ	4	; Modem Ring
@SMB1_WAKE_LAN	 equ	5	; LAN Remote
@SMB1_WAKE_POWER equ	6	; Power Switch
@SMB1_WAKE_PCI	 equ	7	; PCI PME#
@SMB1_WAKE_ACRES equ	8	; AC Power Restored


; =========================== Type 2:  Base Board Information ================

SMB2_STR struc			; Type 2:  Base Board Information

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB2_MFR  db	?		; 04:  Manufacturer string
SMB2_PROD db	?		; 05:  Product Name string
SMB2_VER  db	?		; 06:  Version string
SMB2_SN   db	?		; 07:  Serial # string

SMB2_STR ends


; =========================== Type 3:  System Enclosure or Chassis ===========

SMB3_STR struc			; Type 3:  System Enclosure or Chassis

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB3_MFR   db	?		; 04:  Manufacturer string
SMB3_TYPE  db	?		; 05:  Type bit field (see SMB3_TYPE_REC)
SMB3_VER   db	?		; 06:  Version string
SMB3_SN    db	?		; 07:  Serial # string
SMB3_ASSET db	?		; 08:  Asset Tag # string
SMB3_BOOT  db	?		; 09:  Bootup state enum (see @SMB3_STATE_xxx)
SMB3_POWER db	?		; 0A:  Power Suppy State enum (see @SMB3_STATE_xxx)
SMB3_THERM db	?		; 0B:  Thermal State enum (see @SMB3_STATE_xxx)
SMB3_SECUR db	?		; 0C:  Security Status enum (see @SMB3_SECUR_xxx)
SMB3_OEM   dd	?		; 0D:  OEM-defined bit field

SMB3_STR ends


SMB3_TYPE_REC record \
$SMB3_TYPE_LOCK:1, \
$SMB3_TYPE:7


@SMB3_TYPE_OTHER	equ	01h	; Other
@SMB3_TYPE_UNK		equ	02h	; Unknown
@SMB3_TYPE_DTOP 	equ	03h	; Desktop
@SMB3_TYPE_LPDTOP	equ	04h	; Low Profile Desktop
@SMB3_TYPE_PBOX 	equ	05h	; Pizza Box
@SMB3_TYPE_MINITWR	equ	06h	; Mini Tower
@SMB3_TYPE_TWR		equ	07h	; Tower
@SMB3_TYPE_PORT 	equ	08h	; Portable
@SMB3_TYPE_LTOP 	equ	09h	; Laptop
@SMB3_TYPE_NOTE 	equ	0Ah	; Notebook
@SMB3_TYPE_HAND 	equ	0Bh	; Hand Held
@SMB3_TYPE_DOCK 	equ	0Ch	; Docking Station
@SMB3_TYPE_ALL		equ	0Dh	; All in One
@SMB3_TYPE_SNOTE	equ	0Eh	; Sub Notebook
@SMB3_TYPE_SPACE	equ	0Fh	; Space-saving
@SMB3_TYPE_LBOX 	equ	10h	; Lunch Box
@SMB3_TYPE_MCHAS	equ	11h	; Main Server Chassis
@SMB3_TYPE_ECHAS	equ	12h	; Expansion Chassis
@SMB3_TYPE_SCHAS	equ	13h	; SubChassis
@SMB3_TYPE_BCHAS	equ	14h	; Bus Expansion Chassis
@SMB3_TYPE_PCHAS	equ	15h	; Peripheral Chassis
@SMB3_TYPE_RAID 	equ	16h	; RAID Chassis
@SMB3_TYPE_RACK 	equ	17h	; Rack Mount Chassis
@SMB3_TYPE_SEAL 	equ	18h	; Sealed Case Chassis


@SMB3_STATE_OTHER	equ	01h	; Other
@SMB3_STATE_UNK 	equ	02h	; Unknown
@SMB3_STATE_SAFE	equ	03h	; Safe
@SMB3_STATE_WARN	equ	04h	; Warning
@SMB3_STATE_CRIT	equ	05h	; Critical
@SMB3_STATE_NONREC	equ	06h	; Non-recoverable


@SMB3_SECUR_OTHER	equ	01h	; Other
@SMB3_SECUR_UNK 	equ	02h	; Unknown
@SMB3_SECUR_NONE	equ	03h	; None
@SMB3_SECUR_EI_LOCK	equ	04h	; External Interface Locked Out
@SMB3_SECUR_EI_ENA	equ	05h	; External Interface Enabled


; =========================== Type 4:  Processor Information =================

SMB4_STR struc			; Type 4:  Processor Information

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB4_SOCK   db	?		; 04:  Socket Designation string
SMB4_PTYP   db	?		; 05:  Processor Type enum (see @SMB4_PTYP_xxx)
SMB4_PFAM   db	?		; 06:  Processor Family enum (see @SMB4_PFAM_xxx)
SMB4_PMFR   db	?		; 07:  Processor Manufacturer string
SMB4_PID    dq	?		; 08:  Processor ID 8 bytes
SMB4_PVER   db	?		; 10:  Processor Version string
SMB4_VOLT   db	?		; 11:  Voltage record (see SMB4_VOLT_REC)
SMB4_CLCK   dw	?		; 12:  External Clock frequency in MHz (0=unk)
SMB4_MAXSP  dw	?		; 14:  Maximum Speed in MHz (0=unk)
SMB4_CURSP  dw	?		; 16:  Current Speed in MHz (0=unk)
SMB4_STAT   db	?		; 18:  Status record (see SMB4_STAT_REC)
SMB4_PUPG   db	?		; 19:  Processor Upgrade enum (see @SMB4_PUPG_xxx)
SMB4_L1HNDL dw	?		; 1A:  L1 Cache Handle (Type 7)
SMB4_L2HNDL dw	?		; 1C:  L2 ...
SMB4_L3HNDL dw	?		; 1E:  L3 ...
SMB4_SERNUM db	?		; 20:  Serial number string
SMB4_ASSET  db	?		; 21:  Asset Tag string
SMB4_PARTNUM db ?		; 22:  Part NUmber string

SMB4_STR ends


@SMB4_PTYP_OTHER equ	01h	; Other
@SMB4_PTYP_UNK	 equ	02h	; Unknown
@SMB4_PTYP_CTRL  equ	03h	; Central Processor
@SMB4_PTYP_MATH  equ	04h	; Math Processor
@SMB4_PTYP_DSP	 equ	05h	; DSP Processor
@SMB4_PTYP_VIDEO equ	06h	; Video Processor


@SMB4_PFAM_OTHER    equ  01h	; Other
@SMB4_PFAM_UNK	    equ  02h	; Unknown
@SMB4_PFAM_8086     equ  03h	; 8086
@SMB4_PFAM_80286    equ  04h	; 80286
@SMB4_PFAM_i386     equ  05h	; Intel386 processor
@SMB4_PFAM_i486     equ  06h	; Intel486 processor
@SMB4_PFAM_8087     equ  07h	; 8087
@SMB4_PFAM_80287    equ  08h	; 80287
@SMB4_PFAM_80387    equ  09h	; 80387
@SMB4_PFAM_80487    equ  0Ah	; 80487
@SMB4_PFAM_PENT     equ  0Bh	; Pentium processor family
@SMB4_PFAM_PENTPRO  equ  0Ch	; Pentium Pro processor
@SMB4_PFAM_PENTII   equ  0Dh	; Pentium II processor
@SMB4_PFAM_PENTMMX  equ  0Eh	; Pentium processor with MMX technology
@SMB4_PFAM_CELERON  equ  0Fh	; Celeron processor
@SMB4_PFAM_PENT2XEON equ 10h	; Pentium II Xeon processor
@SMB4_PFAM_PENTIII  equ  11h	; Pentium III processor
@SMB4_PFAM_M1	    equ  12h	; M1 family
@SMB4_PFAM_M1_13    equ  13h	; M1 family, type 13
@SMB4_PFAM_M1_14    equ  14h	; M1 family, type 14
@SMB4_PFAM_M1_15    equ  15h	; M1 family, type 15
@SMB4_PFAM_M1_16    equ  16h	; M1 family, type 16
@SMB4_PFAM_M1_17    equ  17h	; M1 family, type 17
@SMB4_PFAM_M1_18    equ  18h	; M1 family, type 18
@SMB4_PFAM_K5	    equ  19h	; K5 family
@SMB4_PFAM_K5_1A    equ  1Ah	; K5 family, type 1A
@SMB4_PFAM_K5_1B    equ  1Bh	; K5 family, type 1B
@SMB4_PFAM_K5_1C    equ  1Ch	; K5 family, type 1C
@SMB4_PFAM_K5_1D    equ  1Dh	; K5 family, type 1D
@SMB4_PFAM_K5_1E    equ  1Eh	; K5 family, type 1E
@SMB4_PFAM_K5_1F    equ  1Fh	; K5 family, type 1F
@SMB4_PFAM_PPC	    equ  20h	; Power PC Family
@SMB4_PFAM_PPC_601  equ  21h	; Power PC 601
@SMB4_PFAM_PPC_603  equ  22h	; Power PC 603
@SMB4_PFAM_PPC_603P equ  23h	; Power PC 603+
@SMB4_PFAM_PP3_604  equ  24h	; Power PC 604
@SMB4_PFAM_ALPHA    equ  30h	; Alpha Family
@SMB4_PFAM_MIPS     equ  40h	; MIPS Family
@SMB4_PFAM_SPARC    equ  50h	; SPARC Family
@SMB4_PFAM_68040    equ  60h	; 68040 Family
@SMB4_PFAM_68xxx    equ  61h	; 68xxx
@SMB4_PFAM_68000    equ  62h	; 68000
@SMB4_PFAM_68010    equ  63h	; 68010
@SMB4_PFAM_68020    equ  64h	; 68020
@SMB4_PFAM_68030    equ  65h	; 68030
@SMB4_PFAM_HOBBIT   equ  70h	; Hobbit Family
@SMB4_PFAM_WEITEK   equ  80h	; Weitek
@SMB4_PFAM_PARISC   equ  90h	; PA-RISC Family
@SMB4_PFAM_V30	    equ 0A0h	; V30 Family
@SMB4_PFAM_PENT3XEON equ 0B0h	; Pentium III Xeon processor


SMB4_VOLT_REC record \
$SMB4_VOLT_XLEG:1, \
$SMB4_VOLT_RSV4:3, \
$SMB4_VOLT_RSV3:1, \
$SMB4_VOLT_29V:1,  \
$SMB4_VOLT_33V:1,  \
$SMB4_VOLT_5V:1


SMB4_STAT_REC record \
$SMB4_STAT_RSV7:1, \
$SMB4_STAT_POP:1,  \
$SMB4_STAT_RSV3:3, \
$SMB4_STAT_CPU:3


@SMB4_STAT_POP_OUT   equ 0	; CPU is Unpopulated
@SMB4_STAT_POP_IN    equ 1	; ...	 Populated


@SMB4_STAT_CPU_UNK   equ 0	; Unknown
@SMB4_STAT_CPU_ENA   equ 1	; CPU Enabled
@SMB4_STAT_CPU_DISU  equ 2	; CPU Disabled by User via BIOS Setup
@SMB4_STAT_CPU_DISB  equ 3	; CPU Disabled by BIOS (POST Error)
@SMB4_STAT_CPU_IDLE  equ 4	; CPU is Idle, waiting to be enabled
@SMB4_STAT_CPU_RSV5  equ 5	; Reserved
@SMB4_STAT_CPU_RSV6  equ 6	; ...
@SMB4_STAT_CPU_OTHER equ 7	; Other


@SMB4_PUPG_OTHER  equ	1	; Other
@SMB4_PUPG_UNK	  equ	2	; Unknown
@SMB4_PUPG_DAUGHT equ	3	; Daughter Board
@SMB4_PUPG_ZIF	  equ	4	; ZIF Socket
@SMB4_PUPG_PIGGY  equ	5	; Replaceable Piggy Back
@SMB4_PUPG_NONE   equ	6	; None
@SMB4_PUPG_LIF	  equ	7	; LIF Socket
@SMB4_PUPG_SLOT1  equ	8	; Slot 1
@SMB4_PUPG_SLOT2  equ	9	; Slot 2


; =========================== Type 5:  Memory Controller Information =========

SMB5_STR struc			; Type 5:  Memory Controller Information

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB5_EDM    db	?		; 04:  Error Detecting Method enum (see @SMB5_EDM_xxx)
SMB5_ECC    db	?		; 05:  Error Correcting Capability record (see SMB5_ECC_REC)
SMB5_SINTER db	?		; 06:  Supported Interleave enum (see @SMB5_INTER_xxx)
SMB5_CINTER db	?		; 07:  Current Interleave enum (see @SMB5_INTER_xxx)
SMB5_MAXMOD db	?		; 08:  Maximum Memory Module Size(n) as 2**n MB
SMB5_SPEED  dw	?		; 09:  Supported Speeds record (see SMB5_SPEED_REC)
SMB5_TYPES  dw	?		; 0B:  Supported Memory Types record (see SMB6_TYPES_REC)
SMB5_VOLT   db	?		; 0D:  Memory Module Voltage record (see SMB5_VOLT_REC)
SMB5_CNT    db	?		; 0E:  # Associated Memory Slots
SMB5_MMCH dw	?		; 0F:  Memory Module Configuration Handle (Type 6)
SMB5_EECC db	?		; ??:  Enabled Error Correcting Capabilities (see SMB5_ECC_REC)

SMB5_STR ends


@SMB5_EDM_OTHER   equ	1	; Other
@SMB5_EDM_UNK	  equ	2	; Unknown
@SMB5_EDM_NONE	  equ	3	; None
@SMB5_EDM_PAR8	  equ	4	; 8-bit Parity
@SMB5_EDM_ECC32   equ	5	; 32-bit ECC
@SMB5_EDM_ECC64   equ	6	; 64-bit ECC
@SMB5_EDM_ECC128  equ	7	; 128-bit ECC
@SMB5_EDM_CRC	  equ	8	; CRC


SMB5_ECC_REC record \
$SMB5_ECC_SCRUB:1,  \
$SMB5_ECC_DOUBLE:1, \
$SMB5_ECC_SINGLE:1, \
$SMB5_ECC_NONE:1,   \
$SMB5_ECC_UNK:1,    \
$SMB5_ECC_OTHER:1


@SMB5_INTER_OTHER equ	1	; Other
@SMB5_INTER_UNK   equ	2	; Unknown
@SMB5_INTER_1	  equ	3	; One-way
@SMB5_INTER_2	  equ	4	; Two-way
@SMB5_INTER_4	  equ	5	; Four-way
@SMB5_INTER_8	  equ	6	; Eight-way
@SMB5_INTER_16	  equ	7	; Sixteen-way


SMB5_SPEED_REC record \
$SMB5_SPEED_RSV5:11, \
$SMB5_SPEED_50:1,    \
$SMB5_SPEED_60:1,    \
$SMB5_SPEED_70:1,    \
$SMB5_SPEED_UNK:1,   \
$SMB5_SPEED_OTHER:1


SMB5_VOLT_REC record \
$SMB5_VOLT_RSV3:5,	\
$SMB5_VOLT_29V:1,	\
$SMB5_VOLT_33V:1,	\
$SMB5_VOLT_5V:1


; =========================== Type 6:  Memory Module Information =============

SMB6_STR struc			; Type 6:  Memory Module Information

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB6_SOCK  db	?		; 04:  Socket Designation string
SMB6_BANK  db	?		; 05:  Bank Connections
SMB6_SPEED db	?		; 06:  Current Speed
SMB6_TYPES dw	?		; 07:  Current Memory Type record (see SMB6_TYPES_REC)
SMB6_ISIZE db	?		; 09:  Installed Size record (see SMB6_SIZE_REC)
SMB6_ESIZE db	?		; 0A:  Enabled Size record (see SMB6_SIZE_REC)
SMB6_ERR   db	?		; 0B:  Error Status record (see SMB6_ERR_REC)

SMB6_STR ends


SMB6_TYPES_REC record \
$SMB6_TYPES_RSV11:5,	\
$SMB6_TYPES_SDRAM:1,	\
$SMB6_TYPES_BEDO:1,	\
$SMB6_TYPES_DIMM:1,	\
$SMB6_TYPES_SIMM:1,	\
$SMB6_TYPES_ECC:1,	\
$SMB6_TYPES_PARITY:1,	\
$SMB6_TYPES_EDO:1,	\
$SMB6_TYPES_FPM:1,	\
$SMB6_TYPES_STD:1,	\
$SMB6_TYPES_UNK:1,	\
$SMB6_TYPES_OTHER:1


SMB6_SIZE_REC record \
$SMB6_SIZE_CSIZE:1, \
$SMB6_SIZE_MB:7


@SMB6_CSIZE_SINGLE equ	0	; Connection size is single-bank
@SMB6_CSIZE_DOUBLE equ	1	; ...		     double-...


SMB6_ERR_REC record \
$SMB6_ERR_RSV3:3, \
$SMB6_ERR_ELOG:1, \
$SMB6_ERR_CORR:1, \
$SMB6_ERR_UNCORR:1


; =========================== Type 7:  Cache Information =====================

SMB7_STR struc			; Type 7:  Cache Information

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB7_SOCK db	?		; 04:  Socket Designation string
SMB7_CFG  dw	?		; 05:  Cache configuration record (see SMB7_CFG_REC)
SMB7_MAX  dw	?		; 07:  Maximum Cache Size record (see SMB7_SIZE_REC)
SMB7_INST dw	?		; 09:  Installed Size record (see SMB7_SIZE_REC)
SMB7_STYPE dw	?		; 0B:  Supported SRAM Type record (see SMB7_TYPE_REC)
SMB7_CTYPE dw	?		; 0D:  Current ...
SMB7_SPEED db	?		; 0F:  Cache Speed in ns
SMB7_ECTYP db	?		; 10:  Error Correction Type enum (see @SMB7_ECTYP_xxx)
SMB7_SCTYP db	?		; 11:  System cache Type enum (see @SMB7_SCTYP_xxx)
SMB7_ASSOC db	?		; 12:  Associativity enum (see @SMB7_ASSOC_xxx)

SMB7_STR ends


SMB7_CFG_REC record \
$SMB7_CFG_RSV10:6, \
$SMB7_CFG_MODE:2,  \
$SMB7_CFG_STATE:1, \
$SMB7_CFG_LOC:2,   \
$SMB7_CFG_RSV4:1,  \
$SMB7_CFG_SOCK:1,  \
$SMB7_CFG_LVL:3


@SMB7_CFG_MODE_WT  equ	00b	; Write Through
@SMB7_CFG_MODE_WB  equ	01b	; Write Back
@SMB7_CFG_MODE_MA  equ	10b	; Varies with Memory Access
@SMB7_CFG_MODE_UNK equ	11b	; Unknown


@SMB7_CFG_STATE_DIS equ 0	; Disabled
@SMB7_CFG_STATE_ENA equ 1	; Enabled


@SMB7_CFG_LOC_INT equ	00b	; Internal
@SMB7_CFG_LOC_EXT equ	01b	; External
@SMB7_CFG_LOC_RSV equ	10b	; Reserved
@SMB7_CFG_LOC_UNK equ	11b	; Unknown


@SMB7_CFG_SOCK_OUT equ	0	; Not Socketed
@SMB7_CFG_SOCK_IN  equ	1	; Socketed


@SMB7_CFG_LVL1	equ	000b	; Level 1
@SMB7_CFG_LVL2	equ	001b	; ...	2
@SMB7_CFG_LVL3	equ	010b	; ...	3
@SMB7_CFG_LVL4	equ	011b	; ...	4
@SMB7_CFG_LVL5	equ	100b	; ...	5
@SMB7_CFG_LVL6	equ	101b	; ...	6
@SMB7_CFG_LVL7	equ	110b	; ...	7
@SMB7_CFG_LVL8	equ	111b	; ...	8


SMB7_SIZE_REC record \
$SMB7_SIZE_GRAN:1, \
$SMB7_SIZE_MAX:15


@SMB7_SIZE_GRAN1  equ	0	;  1K granularity
@SMB7_SIZE_GRAN64 equ	1	; 64K ...


SMB7_TYPE_REC record \
$SMB7_TYPE_RSV7:9,	\
$SMB7_TYPE_ASYNC:1,	\
$SMB7_TYPE_SYNC:1,	\
$SMB7_TYPE_PIPE:1,	\
$SMB7_TYPE_BURST:1,	\
$SMB7_TYPE_NBURST:1,	\
$SMB7_TYPE_UNK:1,	\
$SMB7_TYPE_OTHER:1


@SMB7_ECTYP_OTHER  equ	1	; Other
@SMB7_ECTYP_UNK    equ	2	; Unknown
@SMB7_ECTYP_NONE   equ	3	; None
@SMB7_ECTYP_PARITY equ	4	; Parity
@SMB7_ECTYP_SINGLE equ	5	; Single-bit ECC
@SMB7_ECTYP_MULTI  equ	6	; Multi-bit ECC


@SMB7_SCTYP_OTHER  equ	1	; Other
@SMB7_SCTYP_UNK    equ	2	; Unknown
@SMB7_SCTYP_INSTR  equ	3	; Instruction
@SMB7_SCTYP_DATA   equ	4	; Data
@SMB7_SCTYP_UNIF   equ	5	; Unified


@SMB7_ASSOC_OTHER  equ	1	; Other
@SMB7_ASSOC_UNK    equ	2	; Unknown
@SMB7_ASSOC_DMAP   equ	3	; Direct Mapped
@SMB7_ASSOC_2	   equ	4	; 2-way Set Associative
@SMB7_ASSOC_4	   equ	5	; 4-way Set Associative
@SMB7_ASSOC_FULL   equ	6	; Fully Associative


; =========================== Type 8:  Port Connector Information ============

SMB8_STR struc			; Type 8:  Port Connector Information

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB8_IRD db	?		; 04:  Internal Reference Designator string
SMB8_ICT db	?		; 05:  Internal Connector Type enum (see @SMB8_TYPE_xxx)
SMB8_ERD db	?		; 06:  External Reference Designator string
SMB8_ECT db	?		; 07:  External Connector Type enum (see @SMB8_TYPE_xxx)
SMB8_PORT db	?		; 08:  Port Type enum (see @SMB8_PORT_xxx)

SMB8_STR ends


@SMB8_TYPE_NONE     equ  00h	; None
@SMB8_TYPE_CENT     equ  01h	; Centronics
@SMB8_TYPE_MCENT    equ  02h	; Mini Centronics
@SMB8_TYPE_PROP     equ  03h	; Proprietary
@SMB8_TYPE_DB25M    equ  04h	; DB-25 pin male
@SMB8_TYPE_DB25F    equ  05h	; DB-25 pin female
@SMB8_TYPE_DB15M    equ  06h	; DB-15 pin male
@SMB8_TYPE_DB15F    equ  07h	; DB-15 pin female
@SMB8_TYPE_DB9M     equ  08h	; DB-9 pin male
@SMB8_TYPE_DB9F     equ  09h	; DB-9 pin female
@SMB8_TYPE_RJ11     equ  0Ah	; RJ-11
@SMB8_TYPE_RJ45     equ  0Bh	; RJ-45
@SMB8_TYPE_50P	    equ  0Ch	; 50 pin MiniSCSI
@SMB8_TYPE_MINIDIN  equ  0Dh	; Mini-DIN
@SMB8_TYPE_MICRODIN equ  0Eh	; Micro-DIN
@SMB8_TYPE_PS2	    equ  0Fh	; PS/2
@SMB8_TYPE_INFRA    equ  10h	; Infrared
@SMB8_TYPE_HPHIL    equ  11h	; HP-HIL
@SMB8_TYPE_USB	    equ  12h	; Access bus (USB)
@SMB8_TYPE_SSA	    equ  13h	; SSA SCSI
@SMB8_TYPE_CDIN8M   equ  14h	; Circular DIN-8 male
@SMB8_TYPE_CDIN8F   equ  15h	; Circular DIN-8 female
@SMB8_TYPE_OBIDE    equ  16h	; On Board IDE
@SMB8_TYPE_OBFLOP   equ  17h	; On Board Floppy
@SMB8_TYPE_9PDI     equ  18h	; 9 pin Dual Inline (pin 10 cut)
@SMB8_TYPE_25PDI    equ  19h	; 25 pin Dual Inline (pin 26 cut)
@SMB8_TYPE_50PDI    equ  1Ah	; 50 pin Dual Inline
@SMB8_TYPE_68PDI    equ  1Bh	; 68 pin Dual Inline
@SMB8_TYPE_OBSND    equ  1Ch	; On Board Sound Input from CD-ROM
@SMB8_TYPE_MCENT14  equ  1Dh	; Mini-Centronics Type 14
@SMB8_TYPE_MCENT26  equ  1Eh	; Mini-Centronics Type-26
@SMB8_TYPE_MJACK    equ  1Fh	; Mini-jack (headphones)
@SMB8_TYPE_BNC	    equ  20h	; BNC
@SMB8_TYPE_1394     equ  21h	; 1394
@SMB8_TYPE_PC98     equ 0A0h	; PC-98
@SMB8_TYPE_PC98HI   equ 0A1h	; PC-98-Hireso
@SMB8_TYPE_PCH98    equ 0A2h	; PC-H98
@SMB8_TYPE_PC98NOTE equ 0A3h	; PC-98-Note
@SMB8_TYPE_PC98FULL equ 0A4h	; PC-98-Full
@SMB8_TYPE_OTHER    equ 0FFh	; Other (see reference designator strings)


@SMB8_PORT_NONE        equ  00h ; None
@SMB8_PORT_PAR_XTAT    equ  01h ; Parallel Port XT/AT Compatible
@SMB8_PORT_PAR_PS2     equ  02h ; Parallel Port PS/2 Compatible
@SMB8_PORT_PAR_ECP     equ  03h ; Parallel Port ECP Compatible
@SMB8_PORT_PAR_EPP     equ  04h ; Parallel Port EPP Compatible
@SMB8_PORT_PAR_ECP_EPP equ  05h ; Parallel Port ECP/EPP Compatible
@SMB8_PORT_SER_XTAT    equ  06h ; Serial Port XT/AT Compatible
@SMB8_PORT_SER_16450   equ  07h ; Serial Port 16450 Compatible
@SMB8_PORT_SER_16550   equ  08h ; Serial Port 16550 Compatible
@SMB8_PORT_SER_16550A  equ  09h ; Serial Port 16550A Compatible
@SMB8_PORT_SCSI        equ  0Ah ; SCSI Port
@SMB8_PORT_MIDI        equ  0Bh ; MIDI Port
@SMB8_PORT_JOY	       equ  0Ch ; Joy Stick Port
@SMB8_PORT_KEYB        equ  0Dh ; Keyboard Port
@SMB8_PORT_MOUSE       equ  0Eh ; Mouse Port
@SMB8_PORT_SSA	       equ  0Fh ; SSA SCSI
@SMB8_PORT_USB	       equ  10h ; USB
@SMB8_PORT_1394        equ  11h ; FireWire (IEEE P1394)
@SMB8_PORT_PCMCIA1     equ  12h ; PCMCIA Type I
@SMB8_PORT_PCMCIA2     equ  13h ; PCMCIA Type II
@SMB8_PORT_PCMCIA3     equ  14h ; PCMCIA Type III
@SMB8_PORT_CARD        equ  15h ; Cardbus
@SMB8_PORT_ACCESS      equ  16h ; Access Bus Port
@SMB8_PORT_SCSI2       equ  17h ; SCSI II
@SMB8_PORT_SCSIWIDE    equ  18h ; SCSI Wide
@SMB8_PORT_PC98        equ  19h ; PC-98
@SMB8_PORT_PC98HI      equ  1Ah ; PC-98-Hireso
@SMB8_PORT_PCH98       equ  1Bh ; PC-H98
@SMB8_PORT_VIDEO       equ  1Ch ; Video Port
@SMB8_PORT_AUDIO       equ  1Dh ; Audio Port
@SMB8_PORT_MODEM       equ  1Eh ; Modem Port
@SMB8_PORT_NETW        equ  1Fh ; Network Port
@SMB8_PORT_8251        equ 0A0h ; 8251 Compatible
@SMB8_PORT_8251FIFO    equ 0A1h ; 8251 FIFO Compatible
@SMB8_PORT_OTHER       equ 0FFh ; Other


; =========================== Type 9:  System Slots ==========================

SMB9_STR struc			; Type 9:  System Slots

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB9_DES   db	?		; 04:  Slot Designation string
SMB9_TYPE  db	?		; 05:  Slot Type enum (see @SMB9_TYPE_xxx)
SMB9_DBW   db	?		; 06:  Data Bus Width enum (see @SMB9_DBW_xxx)
SMB9_USE   db	?		; 07:  Current Usage enum (see @SMB9_USE_xxx)
SMB9_LEN   db	?		; 08:  Slot Length enum (see @SMB7_LEN_xxx)
SMB9_ID    dw	?		; 09:  Slot ID
SMB9_CHAR1 db	?		; 0B:  Slot Characterstics 1 record (see SMB9_CHAR1_REC)
SMB9_CHAR2 db	?		; 0C:  ...		   2 ...		  2

SMB9_STR ends


@SMB9_TYPE_OTHER    equ  01h	; Other
@SMB9_TYPE_UNK	    equ  02h	; Unknown
@SMB9_TYPE_ISA	    equ  03h	; ISA
@SMB9_TYPE_MCA	    equ  04h	; MCA
@SMB9_TYPE_EISA     equ  05h	; EISA
@SMB9_TYPE_PCI	    equ  06h	; PCI
@SMB9_TYPE_PCMCIA   equ  07h	; PC Card (PCMCIA)
@SMB9_TYPE_VESA     equ  08h	; VL-VESA
@SMB9_TYPE_PROP     equ  09h	; Proprietary
@SMB9_TYPE_CPU	    equ  0Ah	; Processor Card Slot
@SMB9_TYPE_PMEM     equ  0Bh	; Proprietary Memory Card Slot
@SMB9_TYPE_IORISE   equ  0Ch	; I/O Riser Card Slot
@SMB9_TYPE_NUBUS    equ  0Dh	; NuBus
@SMB9_TYPE_PCI66    equ  0Eh	; PCI - 66 MHz Capable
@SMB9_TYPE_AGP	    equ  0Fh	; AGP
@SMB9_TYPE_AGP2X    equ  10h	; AGP 2X
@SMB9_TYPE_AGP4X    equ  11h	; AGP 4X
@SMB9_TYPE_PCIX     equ  12h	; PCI-X
@SMB9_TYPE_PC98C20  equ 0A0h	; PC-98/C20
@SMB9_TYPE_PC98C24  equ 0A1h	; PC-98/C24
@SMB9_TYPE_PC98E    equ 0A2h	; PC-98/E
@SMB9_TYPE_PC98LCL  equ 0A3h	; PC-98/Local Bus
@SMB9_TYPE_PC98CARD equ 0A4h	; PC-98/Card


@SMB9_DBW_OTHER     equ  01h	; Other
@SMB9_DBW_UNK	    equ  02h	; Unknown
@SMB9_DBW_8	    equ  03h	; 8 bit
@SMB9_DBW_16	    equ  04h	; 16 bit
@SMB9_DBW_32	    equ  05h	; 32 bit
@SMB9_DBW_64	    equ  06h	; 64 bit
@SMB9_DBW_128	    equ  07h	; 128 bit


@SMB9_USE_OTHER     equ  01h	; Other
@SMB9_USE_UNK	    equ  02h	; Unknown
@SMB9_USE_AVL	    equ  03h	; Available
@SMB9_USE_INUSE     equ  04h	; In Use


@SMB9_LEN_OTHER     equ  01h	; Other
@SMB9_LEN_UNK	    equ  02h	; Unknown
@SMB9_LEN_SHORT     equ  03h	; Short
@SMB9_LEN_LONG	    equ  04h	; Long


SMB9_CHAR1_REC record \
$SMB9_CHAR1_MODEM:1,	\
$SMB9_CHAR1_ZOOM:1,	\
$SMB9_CHAR1_CARD:1,	\
$SMB9_CHAR1_CARD16:1,	\
$SMB9_CHAR1_SHARE:1,	\
$SMB9_CHAR1_33V:1,	\
$SMB9_CHAR1_50V:1,	\
$SMB9_CHAR1_UNK:1


SMB9_CHAR2_REC record \
$SMB9_CHAR2_RSV3:5,	\
$SMB9_CHAR2_SMBUS:1,	\
$SMB9_CHAR2_HOT:1,	\
$SMB9_CHAR2_PME:1


; =========================== Type 10:	On Board Devices Information =========

SMB10_STR struc 		; Type 10:  On Board Devices Information

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB10_DEV db	?		; 04:  Device Type record (see SMB10_DEV_REC)
SMB10_DES db	?		; 05:  Description string

SMB10_STR ends


SMB10_DEV_REC record \
$SMB10_DEV_STATUS:1, \
$SMB10_DEV_TYPE:7


@SMB10_DEV_STATUS_DIS equ 0	; Disabled
@SMB10_DEV_STATUS_ENA equ 1	; Enabled


@SMB10_DEV_TYPE_OTHER equ 01h	; Other
@SMB10_DEV_TYPE_UNK   equ 02h	; Unknown
@SMB10_DEV_TYPE_VIDEO equ 03h	; Video
@SMB10_DEV_TYPE_SCSI  equ 04h	; SCSI Controller
@SMB10_DEV_TYPE_ETHER equ 05h	; Ethernet
@SMB10_DEV_TYPE_TOKEN equ 06h	; Token Ring
@SMB10_DEV_TYPE_SOUND equ 07h	; Sound


; =========================== Type 11:	OEM Strings ==========================

SMB11_STR struc 		; Type 11:  OEM Strings

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB11_CNT db	?		; Number of strings

SMB11_STR ends


; =========================== Type 12:	System Configuration Options =========

SMB12_STR struc 		; Type 12:  System Configuration Options

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB12_CNT db	?		; Number of strings

SMB12_STR ends


; =========================== Type 13:	BIOS Language Information ============

SMB13_STR struc 		; Type 13:  BIOS Language Information

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB13_CNT  db	?		; 04:  Number of available languages
SMB13_FLAG db	?		; 05:  Flag record (see SMB13_FLAG_REC)
SMB13_RSVD db	15 dup (?)	; 06:  Reserved for future use
SMB13_CUR  db	?		; 15:  Current Language string

SMB13_STR ends


SMB13_FLAG_REC record \
$SMB13_FLAG_RSV1:7,	\
$SMB13_FLAG_FMT:1


@SMB13_FLAG_FMT_LONG  equ 0	; Long format
@SMB13_FLAG_FMT_SHORT equ 1	; Short format


; =========================== Type 14:	Group Associations ===================

SMB14_STR struc 		; Type 14:  Group Associations

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB14_GRPN db	?		; 04:  Group Name string
SMB14_TYPE db	?		; 05:  Item Type enum (see @SMB_xxx)
SMB14_HNDL dw	?		; 06:  Item Handle (Type as above)

; The last two fields repeat for the rest of the structure

SMB14_STR ends


; =========================== Type 15:	System Event Log =====================

SMB15_STR struc 		; Type 15:  System Event Log

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB15_LOGLEN	 dw ?		; 04:  Log Area Length
SMB15_LOGHDROFF  dw ?		; 06:  Log Header Start Offset
SMB15_LOGDATAOFF dw ?		; 08:  Log Data Start Offset
SMB15_ACCMETH	 db ?		; 0A:  Access Method enum (see @SMB15_ACCMETH_xxx)
SMB15_LOGSTAT	 db ?		; 0B:  Log Status record (see SMB15_LOGSTAT_REC)
SMB15_LOGCHG	 dd ?		; 0C:  Log Change Token
SMB15_AMADDR	 dd ?		; 10:  Access Method Address
SMB15_LOGFMT	 db ?		; 14:  Log Header Format enum (see @SMB15_LOGFMT_xxx)
SMB15_NSLTD	 db ?		; 15:  # Supported Log Type Descriptors
SMB15_LENLTD	 db ?		; 16:  Length of each Log Type Descriptor
SMB15_LOGTYPE	 db ?		; 17:  Log Type enum (see @SMB15_LOGTYPE_xxx)
SMB15_FMTTYPE	 db ?		; 18:  Format Type enum (see @SMB15_FMTTYPE_xxx)

; The last two fields repeat for the rest of the structure

SMB15_STR ends


@SMB15_ACCMETH_IIO8_8  equ 00	; Indexed I/O:	one 8-bit index port, one 8-bit data port
@SMB15_ACCMETH_IIO88_8 equ 01	; Indexed I/O:	two 8-bit index ports, one 8-bit data port
@SMB15_ACCMETH_IIO16_8 equ 02	; Indexed I/O:	one 16-bit index port, one 8-bit data port
@SMB15_ACCMETH_MMP32   equ 03	; Memory-mapped physical 32-bit address
@SMB15_ACCMETH_GPNV    equ 04	; Available via General Purpose NonVolatile Data functions


SMB15_LOGSTAT_REC record \
$SMB15_LOGSTAT_RSV2:6,	\
$SMB15_LOGSTAT_FULL:1,	\
$SMB15_LOGSTAT_VALID:1


@SMB15_LOGFMT_NOHDR equ 00h	; No header
@SMB15_LOGFMT_TYPE1 equ 01h	; Type 1 log header


@SMB15_LOGTYPE_RSVD00	equ 00h ; Reserved-00
@SMB15_LOGTYPE_SBECC	equ 01h ; Single-bit ECC memory error
@SMB15_LOGTYPE_MBECC	equ 02h ; Multi-bit ECC memory error
@SMB15_LOGTYPE_PARITY	equ 03h ; Parity memory error
@SMB15_LOGTYPE_BUSTIME	equ 04h ; Bus time-out
@SMB15_LOGTYPE_IOERR	equ 05h ; I/O Channel Check
@SMB15_LOGTYPE_NMI	equ 06h ; Software NMI
@SMB15_LOGTYPE_POSTMR	equ 07h ; POST memory resize
@SMB15_LOGTYPE_POSTERR	equ 08h ; POST error
@SMB15_LOGTYPE_PCIPAR	equ 09h ; PCI Parity Error
@SMB15_LOGTYPE_PCISYS	equ 0Ah ; PCI System Error
@SMB15_LOGTYPE_CPUFAIL	equ 0Bh ; CPU Failure
@SMB15_LOGTYPE_EISATIM	equ 0Ch ; EISA FailSafe Timer time-out
@SMB15_LOGTYPE_CORRMEM	equ 0Dh ; Correctable memory log disabled
@SMB15_LOGTYPE_LOGOFF	equ 0Eh ; Logging event disabled
@SMB15_LOGTYPE_RSVD0F	equ 0Fh ; Reserved-0F
@SMB15_LOGTYPE_SYSLIM	equ 10h ; System Limit Exceeded
@SMB15_LOGTYPE_HWTIMER	equ 11h ; Asynchronous hardware timer expired
@SMB15_LOGTYPE_SCINFO	equ 12h ; System configuration information
@SMB15_LOGTYPE_HDINFO	equ 13h ; Hard-disk information
@SMB15_LOGTYPE_SYSCFG	equ 14h ; System reconfigured
@SMB15_LOGTYPE_BADCPU	equ 15h ; Uncorrectable CPU-complex error
@SMB15_LOGTYPE_LOGRESET equ 16h ; Log Area Reset/Cleared
@SMB15_LOGTYPE_SYSBOOT	equ 17h ; System boot


@SMB15_FMTTYPE_NONE	equ 00h ; None
@SMB15_FMTTYPE_HNDL	equ 01h ; Handle
@SMB15_FMTTYPE_ME	equ 02h ; Multiple-Event
@SMB15_FMTTYPE_MEHNDL	equ 03h ; Multiple-Event Handle
@SMB15_FMTTYPE_POST	equ 04h ; POST Results Bitmap
@SMB15_FMTTYPE_SMT	equ 05h ; System Management Type
@SMB15_FMTTYPE_MESMT	equ 06h ; Multiple-Event System Management Type


; =========================== Type 16:	Physical Memory Array ================

SMB16_STR struc 		; Type 16:  Physical Memory Array

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB16_LOC  db	?		; 04:  Location enum (see @SMB16_LOC_xxx)
SMB16_USE  db	?		; 05:  Use enum (see @SMB16_USE_xxx)
SMB16_COR  db	?		; 06:  Memory Error Correction enum (see @SMB16_COR_xxx)
SMB16_MAX  dd	?		; 07:  Maximum capacity in KB
SMB16_HNDL dw	?		; 08:  Memory Error Information Handle (Types 18 or 33)
SMB16_CNT  dw	?		; 0D:  # Memory Devices (Type 17)

SMB16_STR ends


@SMB16_LOC_OTHER   equ	01h	; Other
@SMB16_LOC_UNK	   equ	02h	; Unknown
@SMB16_LOC_SYSBRD  equ	03h	; System board or motherboard
@SMB16_LOC_ISA	   equ	04h	; ISA add-on card
@SMB16_LOC_EISA    equ	05h	; EISA add-on card
@SMB16_LOC_PCI	   equ	06h	; PCI add-on card
@SMB16_LOC_MCA	   equ	07h	; MCA add-on card
@SMB16_LOC_PCMCIA  equ	08h	; PCMCIA add-on card
@SMB16_LOC_PROP    equ	09h	; Proprietary add-on card
@SMB16_LOC_NUBUS   equ	0Ah	; NuBus
@SMB16_LOC_PC98C20 equ 0A0h	; PC-98/C20 add-on card
@SMB16_LOC_PC98C24 equ 0A1h	; PC-98/C24 add-on card
@SMB16_LOC_PC98E   equ 0A2h	; PC-98/E add-on card
@SMB16_LOC_PC98L   equ 0A3h	; PC-98/Local bus add-on card


@SMB16_USE_OTHER   equ	01h	; Other
@SMB16_USE_UNK	   equ	02h	; Unknown
@SMB16_USE_SYS	   equ	03h	; System memory
@SMB16_USE_VID	   equ	04h	; Video memory
@SMB16_USE_FLASH   equ	05h	; Flash memory
@SMB16_USE_NVRAM   equ	06h	; Non-volatile RAM
@SMB16_USE_CACHE   equ	07h	; Cache memory


@SMB16_COR_OTHER   equ	01h	; Other
@SMB16_COR_UNK	   equ	02h	; Unknown
@SMB16_COR_NONE    equ	03h	; None
@SMB16_COR_PARITY  equ	04h	; Parity
@SMB16_COR_SINGLE  equ	05h	; Single-bit ECC
@SMB16_COR_MULTI   equ	06h	; Multi-bit ECC
@SMB16_COR_CRC	   equ	07h	; CRC


; =========================== Type 17:	Memory Devices =======================

SMB17_STR struc 		; Type 17:  Memory Devices

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB17_MAHNDL  dw ?		; 04:  Memory Array Handle (Type 16)
SMB17_MEIHNDL dw ?		; 06:  Memory Error Information Handle (Type 18 or 33)
SMB17_TOTLWID dw ?		; 08:  Total Width in bits
SMB17_DATAWID dw ?		; 0A:  Data Width i bits
SMB17_SIZE    dw ?		; 0C:  Size record (see SMB17_SIZE_REC)
SMB17_FORM    db ?		; 0E:  Form Factor enum (see @SMB17_FORM_xxx)
SMB17_DEVSET  db ?		; 0F:  Device Set
SMB17_DEVLOC  db ?		; 10:  Device Locator string
SMB17_BNKLOC  db ?		; 11:  Bank Locator string
SMB17_MEMTYPE db ?		; 12:  Memory Type enum (see @SMB17_MEMTYPE_xxx)
SMB17_TYPEDET dw ?		; 13:  Type Detail record (see SMB17_TYPEDET_REC)
SMB17_SPEED   dw ?		; 15:  Speed in MHz
SMB17_MFR     dw ?		; 17:  Manufacturer string
SMB17_SERNUM  dw ?		; 18:  Serial # string
SMB17_ASSET   dw ?		; 19:  Asset Tag string
SMB17_PARTNUM dw ?		; 1A:  Part # string

SMB17_STR ends


SMB17_SIZE_REC record \
$SMB17_SIZE_GRAN:1, \
$SMB17_SIZE_SIZE:15


@SMB17_SIZE_GRAN_MB equ 0	; Megabytes
@SMB17_SIZE_GRAN_KB equ 1	; Kilobytes


@SMB17_FORM_OTHER  equ	01h	; Other
@SMB17_FORM_UNK    equ	02h	; Unknown
@SMB17_FORM_SIMM   equ	03h	; SIMM
@SMB17_FORM_SIP    equ	04h	; SIP
@SMB17_FORM_CHIP   equ	05h	; Chip
@SMB17_FORM_DIP    equ	06h	; DIP
@SMB17_FORM_ZIP    equ	07h	; ZIP
@SMB17_FORM_PROP   equ	08h	; Proprietary
@SMB17_FORM_DIMM   equ	09h	; DIMM
@SMB17_FORM_TSOP   equ	0Ah	; TSOP
@SMB17_FORM_ROW    equ	0Bh	; Row of chips
@SMB17_FORM_RIMM   equ	0Ch	; RIMM
@SMB17_FORM_SODIMM equ	0Dh	; SODIMM
@SMB17_FORM_SRIMM  equ	0Eh	; SRIMM


@SMB17_MEMTYPE_OTHER  equ 01h	; Other
@SMB17_MEMTYPE_UNK    equ 02h	; Unknown
@SMB17_MEMTYPE_DRAM   equ 03h	; DRAM
@SMB17_MEMTYPE_EDRAM  equ 04h	; EDRAM
@SMB17_MEMTYPE_VRAM   equ 05h	; VRAM
@SMB17_MEMTYPE_SRAM   equ 06h	; SRAM
@SMB17_MEMTYPE_RAM    equ 07h	; RAM
@SMB17_MEMTYPE_ROM    equ 08h	; ROM
@SMB17_MEMTYPE_FLASH  equ 09h	; FLASH
@SMB17_MEMTYPE_EEPROM equ 0Ah	; EEPROM
@SMB17_MEMTYPE_FEPROM equ 0Bh	; FEPROM
@SMB17_MEMTYPE_EPROM  equ 0Ch	; EPROM
@SMB17_MEMTYPE_CDRAM  equ 0Dh	; CDRAM
@SMB17_MEMTYPE_3DRAM  equ 0Eh	; 3DRAM
@SMB17_MEMTYPE_SDRAM  equ 0Fh	; SDRAM
@SMB17_MEMTYPE_SGRAM  equ 10h	; SGRAM
@SMB17_MEMTYPE_RDRAM  equ 11h	; RDRAM


SMB17_TYPEDET_REC record \
$SMB17_TYPEDET_RSV13:3, \
$SMB17_TYPEDET_NVRAM:1, \
$SMB17_TYPEDET_CDRAM:1, \
$SMB17_TYPEDET_WDRAM:1, \
$SMB17_TYPEDET_EDO:1,	\
$SMB17_TYPEDET_CMOS:1,	\
$SMB17_TYPEDET_SYNC:1,	\
$SMB17_TYPEDET_RAMBUS:1,\
$SMB17_TYPEDET_PSEUDO:1,\
$SMB17_TYPEDET_STATIC:1,\
$SMB17_TYPEDET_FPM:1,	\
$SMB17_TYPEDET_UNK:1,	\
$SMB17_TYPEDET_OTHER:1, \
$SMB17_TYPEDET_RSV0:1


; =========================== Type 18:	32-bit Memory Error Information ======

SMB18_STR struc 		; Type 18:  32-bit Memory Error Information

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB18_ERRTYPE db ?		; 04:  Error Type enum (see @SMB18_ERRTYPE_xxx)
SMB18_ERRGRAN db ?		; 05:  Error Granularity enum (see @SMB18_ERRGRAN_xxx)
SMB18_ERROPER db ?		; 06:  Error Operation enum (see @SMB18_ERROPER_xxx)
SMB18_VENSYN  dd ?		; 07:  Vendor Syndrome (ECC or CRC)
SMB18_MAEADDR dd ?		; 0B:  Memory Array Error Address
SMB18_DEADDR  dd ?		; 0F:  Device Error Address
SMB18_ERRRES  dd ?		; 13:  Error Resolution

SMB18_STR ends


@SMB18_ERRTYPE_OTHER  equ 01h	; Other
@SMB18_ERRTYPE_UNK    equ 02h	; Unknown
@SMB18_ERRTYPE_OK     equ 03h	; OK
@SMB18_ERRTYPE_READ   equ 04h	; Bad read
@SMB18_ERRTYPE_PERR   equ 05h	; Parity error
@SMB18_ERRTYPE_SBERR  equ 06h	; Single-bit error
@SMB18_ERRTYPE_DBERR  equ 07h	; Double-bit error
@SMB18_ERRTYPE_MBERR  equ 08h	; Multi-bit error
@SMB18_ERRTYPE_NBERR  equ 09h	; Nibble error
@SMB18_ERRTYPE_CSERR  equ 0Ah	; Checksum error
@SMB18_ERRTYPE_CRCERR equ 0Bh	; CRC error
@SMB18_ERRTYPE_CSBERR equ 0Ch	; Corrected single-bit error
@SMB18_ERRTYPE_CERR   equ 0Dh	; Corrected errr
@SMB18_ERRTYPE_UCERR  equ 0Eh	; Uncorrectable error


@SMB18_ERRGRAN_OTHER equ 01h	; Other
@SMB18_ERRGRAN_UNK   equ 02h	; Unknown
@SMB18_ERRGRAN_LEVEL equ 03h	; Device level
@SMB18_ERRGRAN_MPLVL equ 04h	; Memory partition level


@SMB18_ERROPER_OTHER equ 01h	; Other
@SMB18_ERROPER_UNK   equ 02h	; Unknown
@SMB18_ERROPER_READ  equ 03h	; Read
@SMB18_ERROPER_WRITE equ 04h	; Write
@SMB18_ERROPER_PWRIT equ 05h	; Partial write


; =========================== Type 19:	Memory Array Mapped Address ==========

SMB19_STR struc 		; Type 19:  Memory Array Mapped Address

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB19_START dd	?		; 04:  Starting Physical Address in KB
SMB19_END   dd	?		; 08:  Ending Physical Address in KB
SMB19_HNDL  dw	?		; 0C:  Memory Array Handle (Type 16)
SMB19_WIDTH db	?		; 0E:  Partition Width

SMB19_STR ends


; =========================== Type 20:	Memory Device Mapped Address =========

SMB20_STR struc 		; Type 20:  Memory Device Mapped Address

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB20_START    dd ?		; 04:  Starting Physical Address in KB
SMB20_END      dd ?		; 08:  Ending Physical Address in KB
SMB20_MDHNDL   dw ?		; 0C:  Memory Device Handle (Type 17)
SMB20_MAMAHNDL dw ?		; 0E:  Memory Array Mapped Address Handle (Type 19)
SMB20_PRPOS    db ?		; 10:  Partition Row Position
SMB20_IPOS     db ?		; 11:  Interleave Position
SMB20_IDD      db ?		; 12:  Interleave Data Depth

SMB20_STR ends


; =========================== Type 21:	Built-in Pointing Device =============

SMB21_STR struc 		; Type 21:  Built-in Pointing Device

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB21_TYPE db	?		; 04:  Type enum (see @SMB21_TYPE_xxx)
SMB21_INTF db	?		; 05:  Interface enum (see @SMB21_INTF_xxx)
SMB21_NUM  db	?		; 06:  # Buttons

SMB21_STR ends


@SMB21_TYPE_OTHER  equ	01h	; Other
@SMB21_TYPE_UNK    equ	02h	; Unknown
@SMB21_TYPE_MOUSE  equ	03h	; Mouse
@SMB21_TYPE_TBALL  equ	04h	; Track Ball
@SMB21_TYPE_TPOINT equ	05h	; Track Point
@SMB21_TYPE_GPOINT equ	06h	; Glide Point
@SMB21_TYPE_TPAD   equ	07h	; Touch Pad


@SMB21_INTF_OTHER  equ	 01h	; Other
@SMB21_INTF_UNK    equ	 02h	; Unknown
@SMB21_INTF_SERIAL equ	 03h	; Serial
@SMB21_INTF_PS2    equ	 04h	; PS/2
@SMB21_INTF_INFRA  equ	 05h	; Infrared
@SMB21_INTF_HPHIL  equ	 06h	; HP-HIL
@SMB21_INTF_BUS    equ	 07h	; Bus mouse
@SMB21_INTF_ADB    equ	 08h	; ADB (Apple Desktop Bus)
@SMB21_INTF_BUS9   equ	0A0h	; Bus mouse DB-9
@SMB21_INTF_BUSDIN equ	0A1h	; Bus mouse micro-DIN
@SMB21_INTF_USB    equ	0A2h	; USB


; =========================== Type 22:	Portable Battery =====================

SMB22_STR struc 		; Type 22:  Portable Battery

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB22_LOC	db ?		; 04:  Location string
SMB22_MFR	db ?		; 05:  Manufacturer string
SMB22_MFRDATE	db ?		; 06:  Manufacture Date string
SMB22_SERNUM	db ?		; 07:  Serial Number string
SMB22_DEVNAME	db ?		; 08:  Device Name string
SMB22_DEVCHEM	db ?		; 09:  Device Chemistry enum (see @SMB22_DEVCHEM_xxx)
SMB22_DESCAP	dw ?		; 0A:  Design Capacity in mWatt-hours
SMB22_DESVOLT	dw ?		; 0C:  Design Voltage in mVolts
SMB22_SBDSVNUM	db ?		; 0E:  SBDS Version # string
SMB22_MAXERR	db ?		; 0F:  Maximum Error in Battery Data as percentage
SMB22_SBDSSNUM	dw ?		; 10:  SBDS Serial #
SMB22_SBDSMDATE dw ?		; 12:  SBDS manufacture Date record (see SMB22_SBDSMDAT_REC)
SMB22_SBDSDCHEM db ?		; 14:  SBDS Device Chemistry string
SMB22_DESCAPMUL db ?		; 15:  Design Capacity Multiplier
SMB22_OEM	dd ?		; 16:  OEM-specific information

SMB22_STR ends


@SMB22_DEVCHEM_OTHER equ 01h	; Other
@SMB22_DEVCHEM_UNK   equ 02h	; Unknown
@SMB22_DEVCHEM_LEAD  equ 03h	; Lead Acid
@SMB22_DEVCHEM_NCAD  equ 04h	; Nickel Cadmium
@SMB22_DEVCHEM_NMH   equ 05h	; Nickel metal hydride
@SMB22_DEVCHEM_LITH  equ 06h	; Lithium-ion
@SMB22_DEVCHEM_ZINC  equ 07h	; Zinc Air
@SMB22_DEVCHEM_LPOLY equ 08h	; Lithium Polymer


SMB22_SBDSMDATE_REC record \
$SMB22_SBDSMDATE_YEAR:7, \
$SMB22_SBDSMDATE_MON:4,  \
$SMB22_SBDSMDATE_DAY:5


; =========================== Type 23:	System Reset =========================

SMB23_STR struc 		; Type 23:  System Reset

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB23_CAP db	?		; 04:  Capabilities record (see SMB23_CAP_REC)
SMB23_CNT dw	?		; 05:  Reset Count
SMB23_LIM dw	?		; 07:  Reset Limit
SMB23_INT dw	?		; 09:  Timer Interval
SMB23_OUT dw	?		; 0B:  Timeout in minutes

SMB23_STR ends


SMB23_CAP_REC record \
$SMB23_CAP_RSV6:2,  \
$SMB23_CAP_WATCH:1, \
$SMB23_CAP_BOL:2,   \
$SMB23_CAP_BO:2,    \
$SMB23_CAP_STAT:1


@SMB23_CAP_WATCH_FALSE equ 0	; False
@SMB23_CAP_WATCH_TRUE  equ 1	; True


@SMB23_CAP_BO_RSV equ 00b	; Reserved
@SMB23_CAP_BO_OS  equ 01b	; Operating system
@SMB23_CAP_BO_SYS equ 10b	; System utilities
@SMB23_CAP_BO_DNR equ 11b	; Do not reboot


@SMB23_CAP_STAT_DIS equ 0	; Disabled
@SMB23_CAP_STAT_ENA equ 1	; Enabled


; =========================== Type 24:	Hardware Security ====================

SMB24_STR struc 		; Type 24:  Hardware Security

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB24_SET db	?		; 04:  Hardware Secutiry Settings record (see SMB24_SET_REC)

SMB24_STR ends


SMB24_SET_REC record \
$SMB24_SET_POPWD:2, \
$SMB24_SET_KBPWD:2, \
$SMB24_SET_ADPWD:2, \
$SMB24_SET_FPRES:2


@SMB24_SET_STAT_DIS equ 00b	; Disabled
@SMB24_SET_STAT_ENA equ 01b	; Enabled
@SMB24_SET_STAT_NIM equ 10b	; Not Implemented
@SMB24_SET_STAT_UNK equ 11b	; Unknown


; =========================== Type 25:	System Power Controls ================

SMB25_STR struc 		; Type 25:  System Power Controls

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB25_MON db	?		; 04:  Next Scheduled Power-on Month in BCD
SMB25_DAY db	?		; 05:  Next Scheduled Power-on Day in BCD
SMB25_HR  db	?		; 06:  Next Scheduled Power-on Hour in BCD
SMB25_MIN db	?		; 07:  Next Scheduled Power-on Minute in BCD
SMB25_SEC db	?		; 08:  Next Scheduled Power-on Second in BCD

SMB25_STR ends


; =========================== Type 26:	Voltage Probe ========================

SMB26_STR struc 		; Type 26:  Voltage Probe

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB26_DESC db	?		; 04:  Description string
SMB26_LOC  db	?		; 05:  Location and Status record (see SMB26_LOC_REC)
SMB26_MAX  dw	?		; 06:  Maximum value in millivolts
SMB26_MIN  dw	?		; 08:  Minimum value in millivolts
SMB26_RES  dw	?		; 0A:  Resolution in tenths of millivolts
SMB26_TOL  dw	?		; 0C:  Tolerance in plus/minus millivolts
SMB26_ACC  dw	?		; 0E:  Accuracy in plus/minus 1/100th of a percent
SMB26_OEM  dd	?		; 10:  OEM-defined
SMB26_NOM  dw	?		; 14:  Nominal value in millivolts

SMB26_STR ends


SMB26_LOC_REC record \
$SMB26_LOC_STAT:3, \
$SMB26_LOC_LOC:5


@SMB26_LOC_STAT_OTHER equ 01h	; Other
@SMB26_LOC_STAT_UNK   equ 02h	; Unknown
@SMB26_LOC_STAT_OK    equ 03h	; OK
@SMB26_LOC_STAT_NCRIT equ 04h	; Non-critical
@SMB26_LOC_STAT_CRIT  equ 05h	; Critical
@SMB26_LOC_STAT_NREC  equ 06h	; Non-recoverable


@SMB26_LOC_LOC_OTHER  equ 01h	; Other
@SMB26_LOC_LOC_UNK    equ 02h	; Unknown
@SMB26_LOC_LOC_PROC   equ 03h	; Processor
@SMB26_LOC_LOC_DISK   equ 04h	; Disk
@SMB26_LOC_LOC_PERI   equ 05h	; Peripheral Bay
@SMB26_LOC_LOC_SMM    equ 06h	; System Management Module
@SMB26_LOC_LOC_MBRD   equ 07h	; Motherboard
@SMB26_LOC_LOC_MMOD   equ 08h	; Memory Module
@SMB26_LOC_LOC_PMOD   equ 09h	; Processor Module
@SMB26_LOC_LOC_PWR    equ 0Ah	; Power Unit
@SMB26_LOC_LOC_ADD    equ 0Bh	; Add-in card


; =========================== Type 27:	Cooling Device =======================

SMB27_STR struc 		; Type 27:  Cooling Device

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB27_HNDL dw	?		; 04:  Temperature Probe Handle (Type 28)
SMB27_DTYP db	?		; 06:  Device Type and Status record (see SMB27_DEVTYP_REC)
SMB27_COOL db	?		; 07:  Cooling Unit Group
SMB27_OEM  dd	?		; 08:  OEM-defined
SMB27_NOM  dw	?		; 0C:  Nominal Speed in RPM

SMB27_STR ends


SMB27_DTYP_REC record \
$SMB27_DTYP_STAT:3, \
$SMB27_DTYP_TYPE:5


@SMB27_DTYP_STAT_OTHER equ 001b ; Other
@SMB27_DTYP_STAT_UNK   equ 010b ; Unknown
@SMB27_DTYP_STAT_OK    equ 011b ; OK
@SMB27_DTYP_STAT_NCRIT equ 100b ; Non-critical
@SMB27_DTYP_STAT_CRIT  equ 101b ; Critical
@SMB27_DTYP_STAT_NREC  equ 110b ; Non-recoverable


@SMB27_DTYP_TYPE_OTHER equ 00001b ; Other
@SMB27_DTYP_TYPE_UNK   equ 00010b ; Unknown
@SMB27_DTYP_TYPE_FAN   equ 00011b ; Fan
@SMB27_DTYP_TYPE_BLOW  equ 00100b ; Centrifugal Blower
@SMB27_DTYP_TYPE_CHIP  equ 00101b ; Chip Fan
@SMB27_DTYP_TYPE_CAB   equ 00110b ; Cabinet Fan
@SMB27_DTYP_TYPE_PWR   equ 00111b ; Power Supply Fan
@SMB27_DTYP_TYPE_HEAT  equ 01000b ; Heat Pipe
@SMB27_DTYP_TYPE_REFR  equ 01001b ; Integrated Refrigeration
@SMB27_DTYP_TYPE_ACT   equ 10100b ; Active Cooling
@SMB27_DTYP_TYPE_PASS  equ 10101b ; Passive Cooling


; =========================== Type 28:	Temperature Probe ====================

SMB28_STR struc 		; Type 28:  Temperature Probe

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB28_DESC db	?		; 04:  Description string
SMB28_LOC  db	?		; 05:  Location and Status record (see SMB28_LOC_REC)
SMB28_MAX  dw	?		; 06:  Maximum value in millivolts
SMB28_MIN  dw	?		; 08:  Minimum value in millivolts
SMB28_RES  dw	?		; 0A:  Resolution in tenths of millivolts
SMB28_TOL  dw	?		; 0C:  Tolerance in plus/minus millivolts
SMB28_ACC  dw	?		; 0E:  Accuracy in plus/minus 1/100th of a percent
SMB28_OEM  dd	?		; 10:  OEM-defined
SMB28_NOM  dw	?		; 14:  Nominal value in millivolts

SMB28_STR ends


SMB28_LOC_REC record \
$SMB28_LOC_STAT:3, \
$SMB28_LOC_LOC:5


@SMB28_LOC_STAT_OTHER equ 01h	; Other
@SMB28_LOC_STAT_UNK   equ 02h	; Unknown
@SMB28_LOC_STAT_OK    equ 03h	; OK
@SMB28_LOC_STAT_NCRIT equ 04h	; Non-critical
@SMB28_LOC_STAT_CRIT  equ 05h	; Critical
@SMB28_LOC_STAT_NREC  equ 06h	; Non-recoverable


@SMB28_LOC_LOC_OTHER  equ 01h	; Other
@SMB28_LOC_LOC_UNK    equ 02h	; Unknown
@SMB28_LOC_LOC_PROC   equ 03h	; Processor
@SMB28_LOC_LOC_DISK   equ 04h	; Disk
@SMB28_LOC_LOC_PERI   equ 05h	; Peripheral Bay
@SMB28_LOC_LOC_SMM    equ 06h	; System Management Module
@SMB28_LOC_LOC_MBRD   equ 07h	; Motherboard
@SMB28_LOC_LOC_MMOD   equ 08h	; Memory Module
@SMB28_LOC_LOC_PMOD   equ 09h	; Processor Module
@SMB28_LOC_LOC_PWR    equ 0Ah	; Power Unit
@SMB28_LOC_LOC_ADD    equ 0Bh	; Add-in card


; =========================== Type 29:	Electrical Current Probe =============

SMB29_STR struc 		; Type 29:  Electrical Current Probe

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB29_DESC db	?		; 04:  Description string
SMB29_LOC  db	?		; 05:  Location and Status record (see SMB29_LOC_REC)
SMB29_MAX  dw	?		; 06:  Maximum value in millivolts
SMB29_MIN  dw	?		; 08:  Minimum value in millivolts
SMB29_RES  dw	?		; 0A:  Resolution in tenths of millivolts
SMB29_TOL  dw	?		; 0C:  Tolerance in plus/minus millivolts
SMB29_ACC  dw	?		; 0E:  Accuracy in plus/minus 1/100th of a percent
SMB29_OEM  dd	?		; 10:  OEM-defined
SMB29_NOM  dw	?		; 14:  Nominal value in millivolts

SMB29_STR ends


SMB29_LOC_REC record \
$SMB29_LOC_STAT:3, \
$SMB29_LOC_LOC:5


@SMB29_LOC_STAT_OTHER equ 01h	; Other
@SMB29_LOC_STAT_UNK   equ 02h	; Unknown
@SMB29_LOC_STAT_OK    equ 03h	; OK
@SMB29_LOC_STAT_NCRIT equ 04h	; Non-critical
@SMB29_LOC_STAT_CRIT  equ 05h	; Critical
@SMB29_LOC_STAT_NREC  equ 06h	; Non-recoverable


@SMB29_LOC_LOC_OTHER  equ 01h	; Other
@SMB29_LOC_LOC_UNK    equ 02h	; Unknown
@SMB29_LOC_LOC_PROC   equ 03h	; Processor
@SMB29_LOC_LOC_DISK   equ 04h	; Disk
@SMB29_LOC_LOC_PERI   equ 05h	; Peripheral Bay
@SMB29_LOC_LOC_SMM    equ 06h	; System Management Module
@SMB29_LOC_LOC_MBRD   equ 07h	; Motherboard
@SMB29_LOC_LOC_MMOD   equ 08h	; Memory Module
@SMB29_LOC_LOC_PMOD   equ 09h	; Processor Module
@SMB29_LOC_LOC_PWR    equ 0Ah	; Power Unit
@SMB29_LOC_LOC_ADD    equ 0Bh	; Add-in card


; =========================== Type 30:	Out-of-Band Remote Access ============

SMB30_STR struc 		; Type 30:  Out-of-Band Remote Access

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB30_MFR db	?		; 04:  Manufacturer Name string
SMB30_CON db	?		; 05:  Connections record (see SMB30_CON_REC)

SMB30_STR ends


SMB30_CON_REC record \
$SMB30_CON_RSV2:6, \
$SMB30_CON_OCE:1,  \
$SMB30_CON_ICE:1


@SMB30_CON_CE_FALSE equ 0	; False
@SMB30_CON_CE_TRUE  equ 1	; True


; =========================== Type 31:	Boot Integrity Services (BIS) Entry Point

SMB31_STR struc 		; Type 31:  Boot Integrity Services (BIS) Entry Point

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB31_CSUM db	?		; 04:  Checksum
SMB31_RSV1 db	?		; 05:  Reserved
SMB31_RSV2 dw	?		; 06:  Reserved
SMB31_PTR16 dd	?		; 08:  Entry point for 16-bit callers
SMB31_PHYS32 dd ?		; 0C:  Physical address for 32-bit callers
SMB31_RSV3 dq	?		; 10:  Reserved
SMB31_RSV4 dd	?		; 18:  Reserved

SMB31_STR ends


; =========================== Type 32:	System Boot Information ==============

SMB32_STR struc 		; Type 32:  System Boot Information

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB32_RSV  db	6 dup (?)	; 04:  Reserved
SMB32_STAT db	?		; 0A:  Boot Status (see @SMB32_STAT_xxx)
SMB32_DATA db	9 dup (?)	; 0B:  Additional Data

SMB32_STR ends


@SMB32_STAT_NOERR  equ	0	; No errors detected
@SMB32_STAT_NOBOOT equ	1	; No bootable media
@SMB32_STAT_NOLOAD equ	2	; The 'normal' OS failed to load
@SMB32_STAT_HWFAIL equ	3	; Firmware-detected HW failure, including 'unknown' failure types
@SMB32_STAT_OSFAIL equ	4	; OS-detected HW failure
@SMB32_STAT_USER   equ	5	; User-requested boot
@SMB32_STAT_SEC    equ	6	; System security violation
@SMB32_STAT_PREV   equ	7	; Previously requested image
@SMB32_STAT_WATCH  equ	8	; A system watchdog timer expired


; =========================== Type 33:	64-bit Memory Error Information ======

SMB33_STR struc 		; Type 33:  64-bit Memory Error Information

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB33_ERRTYPE db ?		; 04:  Error Type enum (see @SMB18_ERRTYPE_xxx)
SMB33_ERRGRAN db ?		; 05:  Error Granularity enum (see @SMB18_ERRGRAN_xxx)
SMB33_ERROPER db ?		; 06:  Error Operation enum (see @SMB18_ERROPER_xxx)
SMB33_VENSYN  dd ?		; 07:  Vendor Syndrome (ECC or CRC)
SMB33_MAEADDR dq ?		; 0B:  Memory Array Error Address
SMB33_DEADDR  dq ?		; 13:  Device Error Address
SMB33_ERRRES  dd ?		; 1B:  Error Resolution

SMB33_STR ends


; =========================== Type 34:	Management Device ====================

SMB34_STR struc 		; Type 34:  Management Device

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB34_DESC db	?		; 04:  Description string
SMB34_TYPE db	?		; 05:  Type enum (see @SMB34_TYPE_xxx)
SMB34_ADDR dd	?		; 06:  Address
SMB34_ATYP db	?		; 0A:  Address Type enum (see @SMB34_ATYP_xxx)

SMB34_STR ends


@SMB34_TYPE_OTHER   equ 01h	; Other
@SMB34_TYPE_UNK     equ 02h	; Unknown
@SMB34_TYPE_NS_LM75 equ 03h	; National Semiconductor LM75
@SMB34_TYPE_NS_LM78 equ 04h	; National Semiconductor LM78
@SMB34_TYPE_NS_LM79 equ 05h	; National Semiconductor LM79
@SMB34_TYPE_NS_LM80 equ 06h	; National Semiconductor LM80
@SMB34_TYPE_NS_LM81 equ 07h	; National Semiconductor LM81
@SMB34_TYPE_ANADEV  equ 08h	; Analog Devices ADM9240
@SMB34_TYPE_DALLAS  equ 09h	; Dallas Semiconductor DS1780
@SMB34_TYPE_MAXIM   equ 0Ah	; Maxim 1617
@SMB34_TYPE_GENESYS equ 0Bh	; Genesys GL518SM
@SMB34_TYPE_WINBOND equ 0Ch	; Winbond W83871D
@SMB34_TYPE_HOLTEK  equ 0Dh	; Holtek HT82H791


@SMB34_ATYP_OTHER equ	01h	; Other
@SMB34_ATYP_UNK   equ	02h	; Unknown
@SMB34_ATYP_IO	  equ	03h	; I/O Port
@SMB34_ATYP_MEM   equ	04h	; Memory
@SMB34_ATYP_SMB   equ	05h	; SM Bus


; =========================== Type 35:	Management Device Component ==========

SMB35_STR struc 		; Type 35:  Management Device Component

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB35_DESC  db	?		; 04:  Description string
SMB35_MHNDL dw	?		; 05:  Management Device Handle (Type 34)
SMB35_CHNDL dw	?		; 07:  Component Handle (Types 26, 27, 28, or 29)
SMB35_THNDL dw	?		; 09:  Threshold Handle (Type 36)

SMB35_STR ends


; =========================== Type 36:	Management Device Threshold Data =====

SMB36_STR struc 		; Type 36:  Management Device Threshold Data

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB36_LT_NC dw	?		; 04:  Lower Threshold - Non-critical
SMB36_UT_NC dw	?		; 06:  Upper Threshold - Non-critical
SMB36_LT_C  dw	?		; 08:  Lower Threshold - Critical
SMB36_UT_C  dw	?		; 0A:  Upper Threshold - Critical
SMB36_LT_NR dw	?		; 0C:  Lower Threshold - Non-recoverable
SMB36_UT_NR dw	?		; 0E:  Upper Threshold - Non-recoverable

SMB36_STR ends


; =========================== Type 37:	Memory Channel =======================

SMB37_STR struc 		; Type 37:  Memory Channel

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB37_TYPE   db ?		; 04:  Channel Type enum (see @SMB37_TYPE_xxx)
SMB37_MCLOAD db ?		; 05:  Maximum Channel Load
SMB37_CNT    db ?		; 06:  Memory Device Count
SMB37_MDLOAD db ?		; 07:  Memory Device Load
SMB37_MDHNDL dw ?		; 08:  Memory Device Handle (Type 17)

SMB37_STR ends


@SMB37_TYPE_OTHER  equ	01h	; Other
@SMB37_TYPE_UNK    equ	02h	; Unknown
@SMB37_TYPE_RAMBUS equ	03h	; RAMBUS
@SMB37_TYPE_SYNC   equ	04h	; SyncLink


; =========================== Type 38:	IPMI Device Information ==============

SMB38_STR struc 		; Type 37:  IPMI Device Information

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB38_TYPE  db	?		; 04:  Baseboard Management Controller (BMC) Interface Type enum (see @SMB38_TYPE_xxx)
SMB38_REV   db	?		; 05:  IPMI Specification Revision in BCD
SMB38_SLAVE db	?		; 06:  I2C Slave Address
SMB38_DEV   db	?		; 07:  NV Storage Device Address
SMB38_BASE  dq	?		; 08:  Base Address

SMB38_STR ends


@SMB38_TYPE_UNK  equ	00h	; Unknown
@SMB38_TYPE_KCS  equ	01h	; Keyboard Controller Style
@SMB38_TYPE_SMIC equ	02h	; Server Mangement Interface Chip
@SMB38_TYPE_BT	 equ	03h	; Block Transfer


; =========================== Type 39:	System Power Supply ==================

SMB39_STR struc 		; Type 39:  System Power Supply

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB39_GRP  db	?		; 04:  Power Unit Group
SMB39_LOC  db	?		; 05:  Location string
SMB39_DEV  db	?		; 06:  Device Name string
SMB39_MFR  db	?		; 07:  Manufacturer string
SMB39_SER  db	?		; 08:  Serial # string
SMB39_TAG  db	?		; 09:  Asset Tag # string
SMB39_PART db	?		; 0A:  Part # string
SMB39_REV  db	?		; 0B:  Revision Level string
SMB39_CAP  dw	?		; 0C:  Max Power Capacity in Watts
SMB39_CHAR dw	?		; 0E:  Power Supply Characteristics record (see SMB39_CHAR_REC)
SMB39_IVP  dw	?		; 10:  Input Voltage Probe Handle (Type 26)
SMB39_CD   dw	?		; 12:  Cooling Device Handle (Type 27)
SMB39_ICP  dw	?		; 14:  Input Current Probe Handle (Type 29)

SMB39_STR ends


SMB39_CHAR_REC record \
$SMB39_CHAR_RSV14:2,	\
$SMB39_CHAR_TYPE:4,	\
$SMB39_CHAR_STAT:3,	\
$SMB39_CHAR_RANGE:4,	\
$SMB39_CHAR_UNPL:1,	\
$SMB39_CHAR_PRES:1,	\
$SMB39_CHAR_REPL:1


@SMB39_CHAR_TYPE_OTHER	equ	0001b	; Other
@SMB39_CHAR_TYPE_UNK	equ	0010b	; Unknown
@SMB39_CHAR_TYPE_LIN	equ	0011b	; Linear
@SMB39_CHAR_TYPE_SW	equ	0100b	; Switching
@SMB39_CHAR_TYPE_BATT	equ	0101b	; Battery
@SMB39_CHAR_TYPE_UPS	equ	0110b	; UPS
@SMB39_CHAR_TYPE_CONV	equ	0111b	; Converter
@SMB39_CHAR_TYPE_REG	equ	1000b	; Regulator


@SMB39_CHAR_STAT_OTHER	equ	001b	; Other
@SMB39_CHAR_STAT_UNK	equ	010b	; Unknown
@SMB39_CHAR_STAT_OK	equ	011b	; OK
@SMB39_CHAR_STAT_NCRIT	equ	100b	; Non-critical
@SMB39_CHAR_STAT_CRIT	equ	101b	; Critical (off-line)


@SMB39_CHAR_RANGE_OTHER equ	0001b	; Other
@SMB39_CHAR_RANGE_UNK	equ	0010	; Unknown
@SMB39_CHAR_RANGE_MAN	equ	0011	; Manual
@SMB39_CHAR_RANGE_AUTO	equ	0100	; Auto-switch
@SMB39_CHAR_RANGE_WIDE	equ	0101	; Wide range
@SMB39_CHAR_RANGE_NA	equ	0110	; Not applicable


; =========================== Type 126:  Inactive ============================

SMB126_STR struc		; Type 126:  Inactive

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)
SMB126_DATA db	?		; 04:  Data

SMB126_STR ends


; =========================== Type 126:  End-of-Table ========================

SMB127_STR struc		; Type 127:  End-of-Table

	db	(type SMBHDR_STR) dup (?) ; Header (see SMBHDR_STR)

SMB127_STR ends


