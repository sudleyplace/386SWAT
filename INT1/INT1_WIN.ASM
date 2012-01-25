;' $Header:   P:/PVCS/386SWAT/INT1/INT1_WIN.ASV   1.16   10 Aug 1998 11:20:56   BOB  $
	 title	 INT1_WIN -- INT 01h Windows Text Messages
	 page	 58,122
	 name	 INT1_WIN

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, April, 1988.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include WINDEVID.INC	; To define SWAT_Device_ID

	 include INT1_WIN.INC
	 include SWAT_OVL.INC
	 include SWAT_SEG.INC
.list

; Equates for various Windows VxD calls

	 public  INTER,INTER21	; For use in INT1_FNS.ASM
INTER	 equ	 0000h		; Software Interrupts
VMM	 equ	 0001h		; Virtual Machine Manager
Debug	 equ	 0002h		; **NOT FOUND**
VPICD	 equ	 0003h		; Virtual Programmable Interrupt Controller
VDMAD	 equ	 0004h		; Virtual DMA Controller
VTD	 equ	 0005h		; Virtual Timer Device
V86MMGR  equ	 0006h		; Virtual 8086 Mode Device
PageSwap equ	 0007h		; Demand Paging Swap Device
Parity	 equ	 0008h		; **NOT FOUND**
Reboot	 equ	 0009h		; **NOT FOUND**
VDD	 equ	 000Ah		; ???
VSD	 equ	 000Bh		; Virtual Sound Device
VMD	 equ	 000Ch		; Virtual Mouse Device
VKD	 equ	 000Dh		; Virtual Keyboard Device
VCD	 equ	 000Eh		; Virtual Comm Device
VPD	 equ	 000Fh		; **NOT FOUND**
VHD	 equ	 0010h		; Virtual Hard Disk
VMCPD	 equ	 0011h		; **NOT FOUND**
EBIOS	 equ	 0012h		; Virtual Extended BIOS Data Area Device
BIOSXLAT equ	 0013h		; **NOT FOUND**
VNETBIOS equ	 0014h		; Virtual NETBIOS Device
DOSMGR	 equ	 0015h		; Virtual DOS Manager Device
WINLOAD  equ	 0016h		; **NOT FOUND**
SHELL	 equ	 0017h		; SHELL ???
VMPoll	 equ	 0018h		; Virtual Machine Poll ???
VPROD	 equ	 0019h		; **NOT FOUND**
DOSNET	 equ	 001Ah		; DOS Network ???
VFD	 equ	 001Bh		; **NOT FOUND**
VDD2	 equ	 001Ch		; Secondary display adapter
LoadHi	 equ	 001Ch		; Secondary display adapter
WINDEBUG equ	 001Dh		; **NOT FOUND**
TSRLoad  equ	 001Eh		; TSR instance utility ID
BiosHook equ	 001Fh		; Bios interrupt hooker VxD
INT13	 equ	 0020h		; Safe half of FastDisk
PageFile equ	 0021h		; Paging File device
SCSI	 equ	 0022h		; SCSI device
MCA_POS  equ	 0023h		; MCA_POS device
SCSIFD	 equ	 0024h		; SCSI FastDisk device
VPEND	 equ	 0025h		; Pen device
APM	 equ	 0026h		; Power Management device
INTER21  equ	 0027h		; DOS functions (the equate is an arbitrary #)
INTER22  equ	 0028h		; Win386 ...
INTER31  equ	 0029h		; DPMI ...
VWIN32	 equ	 002Ah		; Virtual Win32 device
VCOMM	 equ	 002Bh		; Virtual COMM device

VNB	 equ	 0031h		; Virtual Netbind
SERVER	 equ	 0032h		; Windows for Workgroups network server VM

VCOND	 equ	 0038h		; Virtual Console device

VNetSup  equ	 0480h		; WFW device
VRedir	 equ	 0481h		; WFW device
VBrowse  equ	 0482h		; WFW device
VSHARE	 equ	 0483h		; WFW device

SWATVXD  equ	 SWAT_Device_ID ; 386SWAT

PM_BIOS  equ	 2250h		; Thinkpad PM_BIOS.386 (PMVDD)


; =============================== WINSTART =====================================

WINSTART macro	 NAME,TEXT
	 local	 L1

WTAB	 segment use32 dword public 'wdata' ; Start WTAB segment
	 assume  ds:WGROUP

ifndef WINTAB
	 public  WINTAB
WINTAB	 label	 tbyte
else
	public	WINTAB_&NAME
WINTAB_&NAME label tbyte
endif				; IFNDEF
	 WTAB_STR <NAME,			\
		   NAME&LEN,			\
		   offset WGROUP:L1,		\
		   offset WGROUP:NAME&_START,	\
		   offset WGROUP:NAME&_VALW>

WTAB	 ends			; End WTAB segment


WTXT	 segment use32 byte public 'wdata' ; Start WTXT segment
	 assume  ds:WGROUP

L1	 db	 TEXT,0

WTXT	 ends			; End WTXT segment


WPTR	 segment use32 dword public 'wdata' ; Start WPTR segment
	 assume  ds:WGROUP

	 public  NAME&_START
NAME&_START label dword

WPTR	 ends			; End WPTR segment


WVALW	segment use32 word public 'wdata' ; Start WVALW segment
	assume	ds:WGROUP

	 public  NAME&_VALW
NAME&_VALW label word		; For word values

WVALW	ends			; End WVALW segment

	 endm			; End WINSTART


; =============================== WINMAC =======================================

WINMAC	 macro	 TEXT,VALW
	 local	 L1

WPTR	 segment use32 dword public 'wdata' ; Start WPTR segment
	 assume  ds:WGROUP

	 dd	 offset WGROUP:L1

WPTR	 ends			; End WPTR segment


WTXT	 segment use32 byte public 'wdata' ; Start WTXT segment
	 assume  ds:WGROUP

ifnb <TEXT>
L1	 db	 TEXT,0
else
L1	 equ	 TXT_INTRSVD
endif				; IFNB <TEXT>

WTXT	 ends			; End WTXT segment

ifnb <VALW>
WVALW	segment use32 word public 'wdata' ; Start WVALW segment
	assume	ds:WGROUP

	dw	VALW

WVALW	ends			; End WVALW segment
endif				; IFNB <VALW>

	 endm			; WINMAC


; =============================== WINEND =======================================

WINEND	 macro	 NAME

ifnb <NAME>
WPTR	 segment use32 dword public 'wdata' ; Start WPTR segment
	 assume  ds:WGROUP

	 public  NAME&LEN
NAME&LEN equ	 ($-NAME&_START)/(type NAME&_START)

WPTR	 ends			; End WPTR segment
else
WTAB	 segment use32 dword public 'wdata' ; Start WTAB segment
	 assume  ds:WGROUP

	 public  WINTAB_CNT
WINTAB_CNT equ	 ($-WINTAB)/(type WTAB_STR) ; # entries in WINTAB

WTAB	 ends			; End WTAB segment
endif				; IFNB <NAME>

	 endm			; End WINSTART


WTXT	 segment use32 byte public 'wdata' ; Start WTXT segment
	 assume  ds:WGROUP

	 public  TXT_INTRSVD
TXT_INTRSVD db	 '(reserved)',0

WTXT	 ends			; End WTXT segment


; =============================== WINTAB =======================================

	 WINSTART INTER,'; '    ; Mark start of INTER tables
	 WINMAC  'Divide overflow'              ; 00
	 WINMAC  'Single-step'                  ; 01
	 WINMAC  'Non-maskable'                 ; 02
	 WINMAC  'Breakpoint'                   ; 03
	 WINMAC  'Overflow'                     ; 04
	 WINMAC  'BOUND/PrtSc'                  ; 05
	 WINMAC  'Invalid Opcode'               ; 06
	 WINMAC 				; 07
	 WINMAC  'Hardware timer tick'          ; 08
	 WINMAC  'Hardware keyboard'            ; 09
	 WINMAC  'Hardware IRQ2'                ; 0A
	 WINMAC  'Hardware COM2'                ; 0B
	 WINMAC  'Hardware COM1'                ; 0C
	 WINMAC  'Hardware LPT2'                ; 0D
	 WINMAC  'Hardware diskette'            ; 0E
	 WINMAC  'Hardware LPT1'                ; 0F
	 WINMAC  'Video services'               ; 10
	 WINMAC  'Equipment flags'              ; 11
	 WINMAC  'Memory size'                  ; 12
	 WINMAC  'Diskette/Hard disk'           ; 13
	 WINMAC  'Communications'               ; 14
	 WINMAC  'BIOS services'                ; 15
	 WINMAC  'Keyboard services'            ; 16
	 WINMAC  'Printer services'             ; 17
	 WINMAC  'ROM BASIC'                    ; 18
	 WINMAC  'Boostrap loader'              ; 19
	 WINMAC  'Timer services'               ; 1A
	 WINMAC  'Control break'                ; 1B
	 WINMAC  'Software timer tick'          ; 1C
	 WINMAC 				; 1D
	 WINMAC 				; 1E
	 WINMAC 				; 1F
	 WINMAC  'Program terminate'            ; 20
	 WINMAC  'DOS services'                 ; 21
	 WINMAC  'Win386 services'              ; 22
	 WINMAC  'DOS control break'            ; 23
	 WINMAC  'DOS critical error'           ; 24
	 WINMAC  'Absolute disk read'           ; 25
	 WINMAC  'Absolute disk write'          ; 26
	 WINMAC  'TSR'                          ; 27
	 WINMAC  'DOS wait'                     ; 28
	 WINMAC  'DOS raw output'               ; 29
	 WINMAC  'DOS critical section'         ; 2A
	 WINMAC 				; 2B
	 WINMAC 				; 2C
	 WINMAC 				; 2D
	 WINMAC  'Command services'             ; 2E
	 WINMAC  'DOS multiplex'                ; 2F
	 WINMAC 				; 30
	 WINMAC  'DPMI services'                ; 31
	 WINMAC 				; 32
	 WINMAC  'Mouse services'               ; 33
	 WINMAC  'NDP Emulation - D8'           ; 34
	 WINMAC  'NDP Emulation - D9'           ; 35
	 WINMAC  'NDP Emulation - DA'           ; 36
	 WINMAC  'NDP Emulation - DB'           ; 37
	 WINMAC  'NDP Emulation - DC'           ; 38
	 WINMAC  'NDP Emulation - DD'           ; 39
	 WINMAC  'NDP Emulation - DE'           ; 3A
	 WINMAC  'NDP Emulation - DF'           ; 3B
	 WINMAC  'NDP Emulation - Seg Ovr'      ; 3C
	 WINMAC  'NDP Emulation - FWAIT'        ; 3D
	 WINMAC 				; 3E
	 WINMAC  'DLL/Overlay'                  ; 3F
	 WINMAC  'Original diskette'            ; 40
	 WINMAC  'Windows debugger'             ; 41
	 WINMAC  'Original video'               ; 42
	 WINMAC 				; 43
	 WINMAC 				; 44
	 WINMAC 				; 45
	 WINMAC 				; 46
	 WINMAC 				; 47
	 WINMAC 				; 48
	 WINMAC 				; 49
	 WINMAC  'User alarm handler'           ; 4A
	 WINMAC  'VDS services'                 ; 4B
	 WINMAC 				; 4C
	 WINMAC 				; 4D
	 WINMAC 				; 4E
	 WINMAC 				; 4F
	 WINMAC 				; 50
	 WINMAC 				; 51
	 WINMAC 				; 52
	 WINMAC 				; 53
	 WINMAC 				; 54
	 WINMAC 				; 55
	 WINMAC 				; 56
	 WINMAC 				; 57
	 WINMAC 				; 58
	 WINMAC 				; 59
	 WINMAC 				; 5A
	 WINMAC 				; 5B
	 WINMAC  'NETBIOS'                      ; 5C
	 WINMAC 				; 5D
	 WINMAC 				; 5E
	 WINMAC 				; 5F
	 WINMAC 				; 60
	 WINMAC  'SYMLOAD'                      ; 61
	 WINMAC 				; 62
	 WINMAC 				; 63
	 WINMAC 				; 64
	 WINMAC 				; 65
	 WINMAC 				; 66
	 WINMAC  'EMS Manager'                  ; 67
	 WINMAC  'WDEB386'                      ; 68
	 WINMAC 				; 69
	 WINMAC 				; 6A
	 WINMAC 				; 6B
	 WINMAC 				; 6C
	 WINMAC 				; 6D
	 WINMAC 				; 6E
	 WINMAC 				; 6F
	 WINMAC 				; 70
	 WINMAC 				; 71
	 WINMAC 				; 72
	 WINMAC 				; 73
	 WINMAC 				; 74
	 WINMAC 				; 75
	 WINMAC 				; 76
	 WINMAC 				; 77
	 WINMAC 				; 78
	 WINMAC 				; 79
	 WINMAC 				; 7A
	 WINMAC 				; 7B
	 WINMAC 				; 7C
	 WINMAC 				; 7D
	 WINMAC 				; 7E
	 WINMAC 				; 7F
	 WINMAC 				; 80
	 WINMAC 				; 81
	 WINMAC 				; 82
	 WINMAC 				; 83
	 WINMAC 				; 84
	 WINMAC 				; 85
	 WINMAC 				; 86
	 WINMAC 				; 87
	 WINMAC 				; 88
	 WINMAC 				; 89
	 WINMAC 				; 8A
	 WINMAC 				; 8B
	 WINMAC 				; 8C
	 WINMAC 				; 8D
	 WINMAC 				; 8E
	 WINMAC 				; 8F
	 WINMAC 				; 90
	 WINMAC 				; 91
	 WINMAC 				; 92
	 WINMAC 				; 93
	 WINMAC 				; 94
	 WINMAC 				; 95
	 WINMAC 				; 96
	 WINMAC 				; 97
	 WINMAC 				; 98
	 WINMAC 				; 99
	 WINMAC 				; 9A
	 WINMAC 				; 9B
	 WINMAC 				; 9C
	 WINMAC 				; 9D
	 WINMAC 				; 9E
	 WINMAC 				; 9F
	 WINMAC 				; A0
	 WINMAC 				; A1
	 WINMAC 				; A2
	 WINMAC 				; A3
	 WINMAC 				; A4
	 WINMAC 				; A5
	 WINMAC 				; A6
	 WINMAC 				; A7
	 WINMAC 				; A8
	 WINMAC 				; A9
	 WINMAC 				; AA
	 WINMAC 				; AB
	 WINMAC 				; AC
	 WINMAC 				; AD
	 WINMAC 				; AE
	 WINMAC 				; AF
	 WINMAC 				; B0
	 WINMAC 				; B1
	 WINMAC 				; B2
	 WINMAC 				; B3
	 WINMAC 				; B4
	 WINMAC 				; B5
	 WINMAC 				; B6
	 WINMAC 				; B7
	 WINMAC 				; B8
	 WINMAC 				; B9
	 WINMAC 				; BA
	 WINMAC 				; BB
	 WINMAC 				; BC
	 WINMAC 				; BD
	 WINMAC 				; BE
	 WINMAC 				; BF
	 WINMAC 				; C0
	 WINMAC 				; C1
	 WINMAC 				; C2
	 WINMAC 				; C3
	 WINMAC 				; C4
	 WINMAC 				; C5
	 WINMAC 				; C6
	 WINMAC 				; C7
	 WINMAC 				; C8
	 WINMAC 				; C9
	 WINMAC 				; CA
	 WINMAC 				; CB
	 WINMAC 				; CC
	 WINMAC 				; CD
	 WINMAC 				; CE
	 WINMAC 				; CF
	 WINMAC 				; D0
	 WINMAC 				; D1
	 WINMAC 				; D2
	 WINMAC 				; D3
	 WINMAC 				; D4
	 WINMAC 				; D5
	 WINMAC 				; D6
	 WINMAC 				; D7
	 WINMAC 				; D8
	 WINMAC 				; D9
	 WINMAC 				; DA
	 WINMAC 				; DB
	 WINMAC 				; DC
	 WINMAC 				; DD
	 WINMAC 				; DE
	 WINMAC 				; DF
	 WINMAC 				; E0
	 WINMAC 				; E1
	 WINMAC 				; E2
	 WINMAC 				; E3
	 WINMAC 				; E4
	 WINMAC 				; E5
	 WINMAC 				; E6
	 WINMAC 				; E7
	 WINMAC 				; E8
	 WINMAC 				; E9
	 WINMAC 				; EA
	 WINMAC 				; EB
	 WINMAC 				; EC
	 WINMAC 				; ED
	 WINMAC 				; EE
	 WINMAC 				; EF
	 WINMAC 				; F0
	 WINMAC 				; F1
	 WINMAC 				; F2
	 WINMAC 				; F3
	 WINMAC 				; F4
	 WINMAC 				; F5
	 WINMAC 				; F6
	 WINMAC 				; F7
	 WINMAC 				; F8
	 WINMAC 				; F9
	 WINMAC 				; FA
	 WINMAC 				; FB
	 WINMAC 				; FC
	 WINMAC 				; FD
	 WINMAC 				; FE
	 WINMAC  'HW/SIMVMI Return'             ; FF
	 WINEND  INTER		; Mark end of INTER tables

	 WINSTART VMM,'; VMM: ' ; Mark start of VMM tables
	 WINMAC  'Get_VMM_Version'              ; 00
	 WINMAC  'Get_Cur_VM_Handle'            ; 01
	 WINMAC  'Test_Cur_VM_Handle'           ; 02
	 WINMAC  'Get_Sys_VM_Handle'            ; 03
	 WINMAC  'Test_Sys_VM_Handle'           ; 04
	 WINMAC  'Validate_VM_Handle'           ; 05
	 WINMAC  'Get_VMM_Reenter_Count'        ; 06
	 WINMAC  'Begin_Reentrant_Execution'    ; 07
	 WINMAC  'End_Reentrant_Execution'      ; 08
	 WINMAC  'Install_V86_Break_Point'      ; 09
	 WINMAC  'Remove_V86_Break_Point'       ; 0A
	 WINMAC  'Allocate_V86_Call_Back'       ; 0B
	 WINMAC  'Allocate_PM_Call_Back'        ; 0C
	 WINMAC  'Call_When_VM_Returns'         ; 0D
	 WINMAC  'Schedule_Global_Event'        ; 0E
	 WINMAC  'Schedule_VM_Event'            ; 0F
	 WINMAC  'Call_Global_Event'            ; 10
	 WINMAC  'Call_VM_Event'                ; 11
	 WINMAC  'Cancel_Global_Event'          ; 12
	 WINMAC  'Cancel_VM_Event'              ; 13
	 WINMAC  'Call_Priority_VM_Event'       ; 14
	 WINMAC  'Cancel_Priority_VM_Event'     ; 15
	 WINMAC  'Get_NMI_Handler_Addr'         ; 16
	 WINMAC  'Set_NMI_Handler_Addr'         ; 17
	 WINMAC  'Hook_NMI_Event'               ; 18
	 WINMAC  'Call_When_VM_Ints_Enabled'    ; 19
	 WINMAC  'Enable_VM_Ints'               ; 1A
	 WINMAC  'Disable_VM_Ints'              ; 1B
	 WINMAC  'Map_Flat'                     ; 1C
	 WINMAC  'Map_Lin_To_VM_Addr'           ; 1D
	 WINMAC  'Adjust_Exec_Priority'         ; 1E
	 WINMAC  'Begin_Critical_Section'       ; 1F
	 WINMAC  'End_Critical_Section'         ; 20
	 WINMAC  'End_Crit_And_Suspend'         ; 21
	 WINMAC  'Claim_Critical_Section'       ; 22
	 WINMAC  'Release_Critical_Section'     ; 23
	 WINMAC  'Call_When_Not_Critical'       ; 24
	 WINMAC  'Create_Semaphore'             ; 25
	 WINMAC  'Destroy_Semaphore'            ; 26
	 WINMAC  'Wait_Semaphore'               ; 27
	 WINMAC  'Signal_Semaphore'             ; 28
	 WINMAC  'Get_Crit_Section_Status'      ; 29
	 WINMAC  'Call_When_Task_Switched'      ; 2A
	 WINMAC  'Suspend_VM'                   ; 2B
	 WINMAC  'Resume_VM'                    ; 2C
	 WINMAC  'No_Fail_Resume_VM'            ; 2D
	 WINMAC  'Nuke_VM'                      ; 2E
	 WINMAC  'Crash_Cur_VM'                 ; 2F
	 WINMAC  'Get_Execution_Focus'          ; 30
	 WINMAC  'Set_Execution_Focus'          ; 31
	 WINMAC  'Get_Time_Slice_Priority'      ; 32
	 WINMAC  'Set_Time_Slice_Priority'      ; 33
	 WINMAC  'Get_Time_Slice_Granularity'   ; 34
	 WINMAC  'Set_Time_Slice_Granularity'   ; 35
	 WINMAC  'Get_Time_Slice_Info'          ; 36
	 WINMAC  'Adjust_Execution_Time'        ; 37
	 WINMAC  'Release_Time_Slice'           ; 38
	 WINMAC  'Wake_Up_VM'                   ; 39
	 WINMAC  'Call_When_Idle'               ; 3A
	 WINMAC  'Get_Next_VM_Handle'           ; 3B
	 WINMAC  'Set_Global_Time_Out'          ; 3C
	 WINMAC  'Set_VM_Time_Out'              ; 3D
	 WINMAC  'Cancel_Time_Out'              ; 3E
	 WINMAC  'Get_System_Time'              ; 3F
	 WINMAC  'Get_VM_Exec_Time'             ; 40
	 WINMAC  'Hook_V86_Int_Chain'           ; 41
	 WINMAC  'Get_V86_Int_Vector'           ; 42
	 WINMAC  'Set_V86_Int_Vector'           ; 43
	 WINMAC  'Get_PM_Int_Vector'            ; 44
	 WINMAC  'Set_PM_Int_Vector'            ; 45
	 WINMAC  'Simulate_Int'                 ; 46
	 WINMAC  'Simulate_Iret'                ; 47
	 WINMAC  'Simulate_Far_Call'            ; 48
	 WINMAC  'Simulate_Far_Jmp'             ; 49
	 WINMAC  'Simulate_Far_Ret'             ; 4A
	 WINMAC  'Simulate_Far_Ret_N'           ; 4B
	 WINMAC  'Build_Int_Stack_Frame'        ; 4C
	 WINMAC  'Simulate_Push'                ; 4D
	 WINMAC  'Simulate_Pop'                 ; 4E
	 WINMAC  '_HeapAllocate'                ; 4F
	 WINMAC  '_HeapReAllocate'              ; 50
	 WINMAC  '_HeapFree'                    ; 51
	 WINMAC  '_HeapGetSize'                 ; 52
	 WINMAC  '_PageAllocate'                ; 53
	 WINMAC  '_PageReAllocate'              ; 54
	 WINMAC  '_PageFree'                    ; 55
	 WINMAC  '_PageLock'                    ; 56
	 WINMAC  '_PageUnLock'                  ; 57
	 WINMAC  '_PageGetSizeAddr'             ; 58
	 WINMAC  '_PageGetAllocInfo'            ; 59
	 WINMAC  '_GetFreePageCount'            ; 5A
	 WINMAC  '_GetSysPageCount'             ; 5B
	 WINMAC  '_GetVMPgCount'                ; 5C
	 WINMAC  '_MapIntoV86'                  ; 5D
	 WINMAC  '_PhysIntoV86'                 ; 5E
	 WINMAC  '_TestGlobalV86Mem'            ; 5F
	 WINMAC  '_ModifyPageBits'              ; 60
	 WINMAC  '_CopyPageTable'               ; 61
	 WINMAC  '_LinMapIntoV86'               ; 62
	 WINMAC  '_LinPageLock'                 ; 63
	 WINMAC  '_LinPageUnLock'               ; 64
	 WINMAC  '_SetResetV86Pageable'         ; 65
	 WINMAC  '_GetV86PageableArray'         ; 66
	 WINMAC  '_PageCheckLinRange'           ; 67
	 WINMAC  '_PageOutDirtyPages'           ; 68
	 WINMAC  '_PageDiscardPages'            ; 69
	 WINMAC  '_GetNulPageHandle'            ; 6A
	 WINMAC  '_GetFirstV86Page'             ; 6B
	 WINMAC  '_MapPhysToLinear'             ; 6C
	 WINMAC  '_GetAppFlatDSAlias'           ; 6D
	 WINMAC  '_SelectorMapFlat'             ; 6E
	 WINMAC  '_GetDemandPageInfo'           ; 6F
	 WINMAC  '_GetSetPageOutCount'          ; 70
	 WINMAC  'Hook_V86_Page'                ; 71
	 WINMAC  '_Assign_Device_V86_Pages'     ; 72
	 WINMAC  '_DeAssign_Device_V86_Pages'   ; 73
	 WINMAC  '_Get_Device_V86_Pages_Array'  ; 74
	 WINMAC  'MMGR_SetNULPageAddr'          ; 75
	 WINMAC  '_Allocate_GDT_Selector'       ; 76
	 WINMAC  '_Free_GDT_Selector'           ; 77
	 WINMAC  '_Allocate_LDT_Selector'       ; 78
	 WINMAC  '_Free_LDT_Selector'           ; 79
	 WINMAC  '_BuildDescriptorDWORDs'       ; 7A
	 WINMAC  '_GetDescriptor'               ; 7B
	 WINMAC  '_SetDescriptor'               ; 7C
	 WINMAC  '_MMGR_Toggle_HMA'             ; 7D
	 WINMAC  'Get_Fault_Hook_Addrs'         ; 7E
	 WINMAC  'Hook_V86_Fault'               ; 7F
	 WINMAC  'Hook_PM_Fault'                ; 80
	 WINMAC  'Hook_VMM_Fault'               ; 81
	 WINMAC  'Begin_Nest_V86_Exec'          ; 82
	 WINMAC  'Begin_Nest_Exec'              ; 83
	 WINMAC  'Exec_Int'                     ; 84
	 WINMAC  'Resume_Exec'                  ; 85
	 WINMAC  'End_Nest_Exec'                ; 86
	 WINMAC  'Allocate_PM_App_CB_Area'      ; 87
	 WINMAC  'Get_Cur_PM_App_CB'            ; 88
	 WINMAC  'Set_V86_Exec_Mode'            ; 89
	 WINMAC  'Set_PM_Exec_Mode'             ; 8A
	 WINMAC  'Begin_Use_Locked_PM_Stack'    ; 8B
	 WINMAC  'End_Use_Locked_PM_Stack'      ; 8C
	 WINMAC  'Save_Client_State'            ; 8D
	 WINMAC  'Restore_Client_State'         ; 8E
	 WINMAC  'Exec_VxD_Int'                 ; 8F
	 WINMAC  'Hook_Device_Service'          ; 90
	 WINMAC  'Hook_Device_V86_API'          ; 91
	 WINMAC  'Hook_Device_PM_API'           ; 92
	 WINMAC  'System_Control'               ; 93
	 WINMAC  'Simulate_IO'                  ; 94
	 WINMAC  'Install_Mult_IO_Handlers'     ; 95
	 WINMAC  'Install_IO_Handler'           ; 96
	 WINMAC  'Enable_Global_Trapping'       ; 97
	 WINMAC  'Enable_Local_Trapping'        ; 98
	 WINMAC  'Disable_Global_Trapping'      ; 99
	 WINMAC  'Disable_Local_Trapping'       ; 9A
	 WINMAC  'List_Create'                  ; 9B
	 WINMAC  'List_Destroy'                 ; 9C
	 WINMAC  'List_Allocate'                ; 9D
	 WINMAC  'List_Attach'                  ; 9E
	 WINMAC  'List_Attach_Tail'             ; 9F
	 WINMAC  'List_Insert'                  ; A0
	 WINMAC  'List_Remove'                  ; A1
	 WINMAC  'List_Deallocate'              ; A2
	 WINMAC  'List_Get_First'               ; A3
	 WINMAC  'List_Get_Next'                ; A4
	 WINMAC  'List_Remove_First'            ; A5
	 WINMAC  '_AddInstanceItem'             ; A6
	 WINMAC  '_Allocate_Device_CB_Area'     ; A7
	 WINMAC  '_Allocate_Global_V86_Data_Area' ; A8
	 WINMAC  '_Allocate_Temp_V86_Data_Area' ; A9
	 WINMAC  '_Free_Temp_V86_Data_Area'     ; AA
	 WINMAC  'Get_Profile_Decimal_Int'      ; AB
	 WINMAC  'Convert_Decimal_String'       ; AC
	 WINMAC  'Get_Profile_Fixed_Point'      ; AD
	 WINMAC  'Convert_Fixed_Point_String'   ; AE
	 WINMAC  'Get_Profile_Hex_Int'          ; AF
	 WINMAC  'Convert_Hex_String'           ; B0
	 WINMAC  'Get_Profile_Boolean'          ; B1
	 WINMAC  'Convert_Boolean_String'       ; B2
	 WINMAC  'Get_Profile_String'           ; B3
	 WINMAC  'Get_Next_Profile_String'      ; B4
	 WINMAC  'Get_Environment_String'       ; B5
	 WINMAC  'Get_Exec_Path'                ; B6
	 WINMAC  'Get_Config_Directory'         ; B7
	 WINMAC  'OpenFile'                     ; B8
	 WINMAC  'Get_PSP_Segment'              ; B9
	 WINMAC  'GetDOSVectors'                ; BA
	 WINMAC  'Get_Machine_Info'             ; BB
	 WINMAC  'GetSet_HMA_Info'              ; BC
	 WINMAC  'Set_System_Exit_Code'         ; BD
	 WINMAC  'Fatal_Error_Handler'          ; BE
	 WINMAC  'Fatal_Memory_Error'           ; BF
	 WINMAC  'Update_System_Clock'          ; C0
	 WINMAC  'Test_Debug_Installed'         ; C1
	 WINMAC  'Out_Debug_String'             ; C2
	 WINMAC  'Out_Debug_Chr'                ; C3
	 WINMAC  'In_Debug_Chr'                 ; C4
	 WINMAC  'Debug_Convert_Hex_Binary'     ; C5
	 WINMAC  'Debug_Convert_Hex_Decimal'    ; C6
	 WINMAC  'Debug_Test_Valid_Handle'      ; C7
	 WINMAC  'Validate_Client_Ptr'          ; C8
	 WINMAC  'Test_Reenter'                 ; C9
	 WINMAC  'Queue_Debug_String'           ; CA
	 WINMAC  'Log_Proc_Call'                ; CB
	 WINMAC  'Debug_Test_Cur_VM'            ; CC
	 WINMAC  'Get_PM_Int_Type'              ; CD
	 WINMAC  'Set_PM_Int_Type'              ; CE
	 WINMAC  'Get_Last_Updated_System_Time' ; CF
	 WINMAC  'Get_Last_Updated_VM_Exec_Time' ; D0
	 WINMAC  'Test_DBCS_Lead_Byte'          ; D1
; New to Windows 3.10
	 WINMAC  '_AddFreePhysPage'             ; D2
	 WINMAC  '_PageResetHandlePAddr'        ; D3
	 WINMAC  '_SetLastV86Page'              ; D4
	 WINMAC  '_GetLastV86Page'              ; D5
	 WINMAC  '_MapFreePhysReg'              ; D6
	 WINMAC  '_UnmapFreePhysReg'            ; D7
	 WINMAC  '_XchgFreePhysReg'             ; D8
	 WINMAC  '_SetFreePhysRegCalBk'         ; D9
	 WINMAC  'Get_Next_Arena'               ; DA
	 WINMAC  'Get_Name_Of_Ugly_TSR'         ; DB
	 WINMAC  'Get_Debug_Options'            ; DC

	 WINMAC  'Set_Physical_HMA_Alias'       ; DD
	 WINMAC  '_GetGlblRng0V86IntBase'       ; DE
	 WINMAC  '_Add_Global_V86_Data_Area'    ; DF
	 WINMAC  'GetSetDetailedVMError'        ; E0
	 WINMAC  'Is_Debug_Chr'                 ; E1
	 WINMAC  'Clear_Mono_Screen'            ; E2
	 WINMAC  'Out_Mono_Chr'                 ; E3
	 WINMAC  'Out_Mono_String'              ; E4
	 WINMAC  'Set_Mono_Cur_Pos'             ; E5
	 WINMAC  'Get_Mono_Cur_Pos'             ; E6
	 WINMAC  'Get_Mono_Chr'                 ; E7
	 WINMAC  'Locate_Byte_In_ROM'           ; E8
	 WINMAC  'Hook_Invalid_Page_Fault'      ; E9
	 WINMAC  'Unhook_Invalid_Page_Fault'    ; EA
	 WINMAC  'Set_Delete_On_Exit_File'      ; EB
	 WINMAC  'Close_VM'                     ; EC
	 WINMAC  'Enable_Touch_1st_Meg'         ; ED
	 WINMAC  'Disable_Touch_1st_Meg'        ; EE
	 WINMAC  'Install_Exception_Handler'    ; EF
	 WINMAC  'Remove_Exception_Handler'     ; F0
	 WINMAC  'Get_Crit_Status_No_Block'     ; F1
	 WINMAC  '_GetLastUpdatedThreadExecTime'        ; F2
	 WINMAC  '_Trace_Out_Service'                   ; F3
	 WINMAC  '_Debug_Out_Service'                   ; F4
	 WINMAC  '_Debug_Flags_Service'                 ; F5
	 WINMAC  'VMMAddImportModuleName'               ; F6
	 WINMAC  'VMM_Add_DDB'                          ; F7
	 WINMAC  'VMM_Remove_DDB'                       ; F8
	 WINMAC  'Test_VM_Ints_Enabled'                 ; F9
	 WINMAC  '_BlockOnID'                           ; FA
	 WINMAC  'Schedule_Thread_Event'                ; FB
	 WINMAC  'Cancel_Thread_Event'                  ; FC
	 WINMAC  'Set_Thread_Time_Out'                  ; FD
	 WINMAC  'Set_Async_Time_Out'                   ; FE
	 WINMAC  '_AllocateThreadDataSlot'              ; FF
	 WINMAC  '_FreeThreadDataSlot'                  ; 100
	 WINMAC  '_CreateMutex'                         ; 101
	 WINMAC  '_DestroyMutex'                        ; 102
	 WINMAC  '_GetMutexOwner'                       ; 103
	 WINMAC  'Call_When_Thread_Switched'            ; 104
	 WINMAC  'VMMCreateThread'                      ; 105
	 WINMAC  '_GetThreadExecTime'                   ; 105
	 WINMAC  'VMMTerminateThread'                   ; 106
	 WINMAC  'Get_Cur_Thread_Handle'                ; 107
	 WINMAC  'Test_Cur_Thread_Handle'               ; 108
	 WINMAC  'Get_Sys_Thread_Handle'                ; 109
	 WINMAC  'Test_Sys_Thread_Handle'               ; 10A
	 WINMAC  'Validate_Thread_Handle'               ; 10B
	 WINMAC  'Get_Initial_Thread_Handle'            ; 10C
	 WINMAC  'Test_Initial_Thread_Handle'           ; 10D
	 WINMAC  'Debug_Test_Valid_Thread_Handle'       ; 10E
	 WINMAC  'Debug_Test_Cur_Thread'                ; 10F
	 WINMAC  'VMM_GetSystemInitState'               ; 110
	 WINMAC  'Cancel_Call_When_Thread_Switched'     ; 111
	 WINMAC  'Get_Next_Thread_Handle'               ; 112
	 WINMAC  'Adjust_Thread_Exec_Priority'          ; 113
	 WINMAC  '_Deallocate_Device_CB_Area'           ; 114
	 WINMAC  'Remove_IO_Handler'                    ; 115
	 WINMAC  'Remove_Mult_IO_Handlers'              ; 116
	 WINMAC  'Unhook_V86_Int_Chain'                 ; 117
	 WINMAC  'Unhook_V86_Fault'                     ; 118
	 WINMAC  'Unhook_PM_Fault'                      ; 119
	 WINMAC  'Unhook_VMM_Fault'                     ; 11A
	 WINMAC  'Unhook_Device_Service'                ; 11B
	 WINMAC  '_PageReserve'                         ; 11C
	 WINMAC  '_PageCommit'                          ; 11D
	 WINMAC  '_PageDecommit'                        ; 11E
	 WINMAC  '_PagerRegister'                       ; 11F
	 WINMAC  '_PagerQuery'                          ; 120
	 WINMAC  '_PagerDeregister'                     ; 121
	 WINMAC  '_ContextCreate'                       ; 122
	 WINMAC  '_ContextDestroy'                      ; 123
	 WINMAC  '_PageAttach'                          ; 124
	 WINMAC  '_PageFlush'                           ; 125
	 WINMAC  '_SignalID'                            ; 126
	 WINMAC  '_PageCommitPhys'                      ; 127
	 WINMAC  '_Register_Win32_Services'             ; 128
	 WINMAC  'Cancel_Call_When_Not_Critical'        ; 129
	 WINMAC  'Cancel_Call_When_Idle'                ; 12A
	 WINMAC  'Cancel_Call_When_Task_Switched'       ; 12B
	 WINMAC  '_Debug_Printf_Service'                ; 12C
	 WINMAC  '_EnterMutex'                          ; 12D
	 WINMAC  '_LeaveMutex'                          ; 12E
	 WINMAC  'Simulate_VM_IO'                       ; 12F
	 WINMAC  'Signal_Semaphore_No_Switch'           ; 130
	 WINMAC  '_ContextSwitch'                       ; 131
	 WINMAC  '_PageModifyPermissions'               ; 132
	 WINMAC  '_PageQuery'                           ; 133
	 WINMAC  '_EnterMustComplete'                   ; 134
	 WINMAC  '_LeaveMustComplete'                   ; 135
	 WINMAC  '_ResumeExecMustComplete'              ; 136
	 WINMAC  '_GetThreadTerminationStatus'          ; 138
	 WINMAC  '_GetInstanceInfo'                     ; 139
	 WINMAC  '_ExecIntMustComplete'                 ; 13A
	 WINMAC  '_ExecVxDIntMustComplete'              ; 13B
	 WINMAC  'Begin_V86_Serialization'              ; 13C
	 WINMAC  'Unhook_V86_Page'                      ; 13D
	 WINMAC  'VMM_GetVxDLocationList'               ; 13E
	 WINMAC  'VMM_GetDDBList'                       ; 13F
	 WINMAC  'Unhook_NMI_Event'                     ; 140
	 WINMAC  'Get_Instanced_V86_Int_Vector'         ; 141
	 WINMAC  'Get_Set_Real_DOS_PSP'                 ; 142
	 WINMAC  'Call_Priority_Thread_Event'           ; 143
	 WINMAC  'Get_System_Time_Address'              ; 144
	 WINMAC  'Get_Crit_Status_Thread'               ; 145
	 WINMAC  'Get_DDB'                              ; 146
	 WINMAC  'Directed_Sys_Control'                 ; 147
	 WINMAC  '_RegOpenKey'                          ; 148
	 WINMAC  '_RegCloseKey'                         ; 149
	 WINMAC  '_RegCreateKey'                        ; 14A
	 WINMAC  '_RegDeleteKey'                        ; 14B
	 WINMAC  '_RegEnumKey'                          ; 14C
	 WINMAC  '_RegQueryValue'                       ; 14D
	 WINMAC  '_RegSetValue'                         ; 14E
	 WINMAC  '_RegDeleteValue'                      ; 14F
	 WINMAC  '_RegEnumValue'                        ; 150
	 WINMAC  '_RegQueryValueEx'                     ; 151
	 WINMAC  '_RegSetValueEx'                       ; 152
	 WINMAC  '_CallRing3'                           ; 153
	 WINMAC  'Exec_PM_Int'                          ; 154
	 WINMAC  '_RegFlushKey'                         ; 155
	 WINMAC  '_PageCommitContig'                    ; 156
	 WINMAC  '_GetCurrentContext'                   ; 157
	 WINMAC  '_LocalizeSprintf'                     ; 158
	 WINMAC  '_LocalizeStackSprintf'                ; 159
	 WINMAC  'Call_Restricted_Event'                ; 15A
	 WINMAC  'Cancel_Restricted_Event'              ; 15B
	 WINMAC  'Register_PEF_Provider, VMM_ICODE'     ; 15C
	 WINMAC  '_GetPhysPageInfo'                     ; 15D
	 WINMAC  '_RegQueryInfoKey'                     ; 15E
	 WINMAC  'MemArb_Reserve_Pages'                 ; 15F
	 WINMAC  'Time_Slice_Sys_VM_Idle'               ; 160
	 WINMAC  'Time_Slice_Sleep'                     ; 161
	 WINMAC  'Boost_With_Decay'                     ; 162
	 WINMAC  'Set_Inversion_Pri'                    ; 163
	 WINMAC  'Reset_Inversion_Pri'                  ; 164
	 WINMAC  'Release_Inversion_Pri'                ; 165
	 WINMAC  'Get_Thread_Win32_Pri'                 ; 166
	 WINMAC  'Set_Thread_Win32_Pri'                 ; 167
	 WINMAC  'Set_Thread_Static_Boost'              ; 168
	 WINMAC  'Set_VM_Static_Boost'                  ; 169
	 WINMAC  'Release_Inversion_Pri_ID'             ; 16A
	 WINMAC  'Attach_Thread_To_Group'               ; 16B
	 WINMAC  'Detach_Thread_From_Group'             ; 16C
	 WINMAC  'Set_Group_Static_Boost'               ; 16D
	 WINMAC  '_GetRegistryPath, VMM_ICODE'          ; 16E
	 WINMAC  '_GetRegistryKey'                      ; 16F
	 WINMAC  'Cleanup_Thread_State'                 ; 170
	 WINMAC  '_RegRemapPreDefKey'                   ; 171
	 WINMAC  'End_V86_Serialization'                ; 172
	 WINMAC  '_Assert_Range'                        ; 173
	 WINMAC  '_Sprintf'                             ; 174
	 WINMAC  '_PageChangePager'                     ; 175
	 WINMAC  '_RegCreateDynKey'                     ; 176
	 WINMAC  '_RegQueryMultipleValues'              ; 177
	 WINMAC  'Boost_Thread_With_VM'                 ; 178
	 WINMAC  'Get_Boot_Flags'                       ; 179
	 WINMAC  'Set_Boot_Flags'                       ; 17A
	 WINMAC  '_lstrcpyn'                            ; 17B
	 WINMAC  '_lstrlen'                             ; 17C
	 WINMAC  '_lmemcpy'                             ; 17D
	 WINMAC  '_GetVxDName'                          ; 17E
	 WINMAC  'Force_Mutexes_Free'                   ; 17F
	 WINMAC  'Restore_Forced_Mutexes'               ; 180
	 WINMAC  '_AddReclaimableItem'                  ; 181
	 WINMAC  '_SetReclaimableItem'                  ; 182
	 WINMAC  '_EnumReclaimableItem'                 ; 183
	 WINMAC  'Time_Slice_Wake_Sys_VM'               ; 184
	 WINMAC  'VMM_Replace_Global_Environment'       ; 185
	 WINMAC  'Begin_Non_Serial_Nest_V86_Exec'       ; 186
	 WINMAC  'Get_Nest_Exec_Status'                 ; 187
	 WINMAC  'Open_Boot_Log'                        ; 188
	 WINMAC  'Write_Boot_Log'                       ; 189
	 WINMAC  'Close_Boot_Log'                       ; 18A
	 WINMAC  'EnableDisable_Boot_Log'               ; 18B
	 WINMAC  '_Call_On_My_Stack'                    ; 18C
	 WINMAC  'Get_Inst_V86_Int_Vec_Base'            ; 18D
	 WINMAC  '_lstrcmpi'                            ; 18E
	 WINMAC  '_strupr'                              ; 18F
	 WINMAC  'Log_Fault_Call_Out'                   ; 190
	 WINMAC  '_AtEventTime'                         ; 191
	 WINEND  VMM		; Mark end of VMM tables

	 WINSTART VPICD,'; VPICD_'      ; Mark start of VPICD tables
	 WINMAC  'Get_Version'                  ; 00
	 WINMAC  'Virtualize_IRQ'               ; 01
	 WINMAC  'Set_Int_Request'              ; 02
	 WINMAC  'Clear_Int_Request'            ; 03
	 WINMAC  'Phys_EOI'                     ; 04
	 WINMAC  'Get_Complete_Status'          ; 05
	 WINMAC  'Get_Status'                   ; 06
	 WINMAC  'Test_Phys_Request'            ; 07
	 WINMAC  'Physically_Mask'              ; 08
	 WINMAC  'Physically_Unmask'            ; 09
	 WINMAC  'Set_Auto_Masking'             ; 0A
	 WINMAC  'Get_IRQ_Complete_Status'      ; 0B
	 WINMAC  'Convert_Handle_To_IRQ'        ; 0C
	 WINMAC  'Convert_IRQ_To_Int'           ; 0D
	 WINMAC  'Convert_Int_To_IRQ'           ; 0E
	 WINMAC  'Call_When_Hw_Int'             ; 0F
	 WINMAC  'Force_Default_Owner'          ; 10
	 WINMAC  'Force_Default_Behavior'       ; 11
; New to Windows 3.10
	 WINMAC  'Auto_Mask_At_Inst_Swap'       ; 12
	 WINMAC  'VPICD_Begin_Inst_Page_Swap'   ; 13
	 WINMAC  'VPICD_End_Inst_Page_Swap'     ; 14
	 WINEND  VPICD		; Mark end of VPICD tables

	 WINSTART VDMAD,'; VDMAD_'      ; Mark start of VDMAD tables
	 WINMAC  'Get_Version'                  ; 00
	 WINMAC  'Virtualize_Channel'           ; 01
	 WINMAC  'Get_Region_Info'              ; 02
	 WINMAC  'Set_Region_Info'              ; 03
	 WINMAC  'Get_Virt_State'               ; 04
	 WINMAC  'Set_Virt_State'               ; 05
	 WINMAC  'Set_Phys_State'               ; 06
	 WINMAC  'Mask_Channel'                 ; 07
	 WINMAC  'UnMask_Channel'               ; 08
	 WINMAC  'Lock_DMA_Region'              ; 09
	 WINMAC  'Unlock_DMA_Region'            ; 0A
	 WINMAC  'Scatter_Lock'                 ; 0B
	 WINMAC  'Scatter_Unlock'               ; 0C
	 WINMAC  'Reserve_Buffer_Space'         ; 0D
	 WINMAC  'Request_Buffer'               ; 0E
	 WINMAC  'Release_Buffer'               ; 0F
	 WINMAC  'Copy_To_Buffer'               ; 10
	 WINMAC  'Copy_From_Buffer'             ; 11
	 WINMAC  'Default_Handler'              ; 12
	 WINMAC  'Disable_Translation'          ; 13
	 WINMAC  'Enable_Translation'           ; 14
	 WINMAC  'Get_EISA_Adr_Mode'            ; 15
	 WINMAC  'Set_EISA_Adr_Mode'            ; 16
	 WINMAC  'Unlock_DMA_Region_No_Dirty'   ; 17
	 WINEND  VDMAD		; Mark end of VDMAD tables

	 WINSTART VTD,'; VTD_'  ; Mark start of VTD tables
	 WINMAC  'Get_Version'                  ; 00
	 WINMAC  'Update_System_Clock'          ; 01
	 WINMAC  'Get_Interrupt_Period'         ; 02
	 WINMAC  'Begin_Min_Int_Period'         ; 03
	 WINMAC  'End_Min_Int_Period'           ; 04
	 WINMAC  'Disable_Trapping'             ; 05
	 WINMAC  'Enable_Trapping'              ; 06
	 WINMAC  'Get_Real_Time'                ; 07
	 WINEND  VTD		; Mark end of VTD tables

	 WINSTART V86MMGR,'; V86MMGR_'  ; Mark start of V86MMGR tables
	 WINMAC  'Get_Version'                  ; 00
	 WINMAC  'Allocate_V86_Pages'           ; 01
	 WINMAC  'Set_EMS_XMS_Limits'           ; 02
	 WINMAC  'Get_EMS_XMS_Limits'           ; 03
	 WINMAC  'Set_Mapping_Info'             ; 04
	 WINMAC  'Get_Mapping_Info'             ; 05
	 WINMAC  'Xlat_API'                     ; 06
	 WINMAC  'Load_Client_Ptr'              ; 07
	 WINMAC  'Allocate_Buffer'              ; 08
	 WINMAC  'Free_Buffer'                  ; 09
	 WINMAC  'Get_Xlat_Buff_State'          ; 0A
	 WINMAC  'Set_Xlat_Buff_State'          ; 0B
	 WINMAC  'Get_VM_Flat_Sel'              ; 0C
	 WINMAC  'Map_Pages'                    ; 0D
	 WINMAC  'Free_Page_Map_Region'         ; 0E
; New to Windows 3.10
	 WINMAC  'LocalGlobalReg'               ; 0F
	 WINMAC  'GetPgStatus'                  ; 10
	 WINMAC  'SetLocalA20'                  ; 11
	 WINMAC  'ResetBasePages'               ; 12
	 WINMAC  'SetAvailMapPgs'               ; 13
	 WINMAC  'NoUMBInitCalls'               ; 14
	 WINEND  V86MMGR	; Mark end of V86MMGR tables

	 WINSTART PageSwap,'; PageSwap_' ; Mark start of PageSwap tables
	 WINMAC  'Get_Version'                  ; 00
	 WINMAC  'Test_Create'                  ; 01
	 WINMAC  'Create'                       ; 02
	 WINMAC  'Destroy'                      ; 03
	 WINMAC  'In'                           ; 04
	 WINMAC  'Out'                          ; 05
	 WINMAC  'Test_IO_Valid'                ; 06
	 WINEND  PageSwap	; Mark end of PageSwap tables

	 WINSTART VDD,'; VDD_'  ; Mark start of VDD tables
	 WINMAC  'Get_Version'  ; 00:  Get version number and ID string ptr
	 WINMAC  'PIF_State'    ; 01:  Pass video PIF bits to VDD
	 WINMAC  'Get_GrabRtn'  ; 02:  Get routine addr for video grab
	 WINMAC  'Hide_Cursor'  ; 03:  Hide cursor when display is windowed
	 WINMAC  'Set_VMType'   ; 04:  Set VM type(windowed, bckgrnd, excl)
	 WINMAC  'Get_ModTime'  ; 05:  Return system time of last mod
	 WINMAC  'Set_HCurTrk'  ; 06:  Track horiz cursor movement in window
	 WINMAC  'Msg_ClrScrn'  ; 07:  Clear screen for sysmodal message
	 WINMAC  'Msg_ForColor' ; 08:  Set Msg_TextOut forground color
	 WINMAC  'Msg_BakColor' ; 09:  Set Msg_TextOut background color
	 WINMAC  'Msg_TextOut'  ; 0A:  Output a string
	 WINMAC  'Msg_SetCursPos' ; 0B:  Set cursor position
	 WINMAC  'Query_Access' ; 0C:  Is it OK to access video now?
; New to Windows 3.10
	 WINMAC  'Check_Update_Soon' ; 0D: User action may update screen
	 WINEND  VDD		; Mark end of VDD tables

	 WINSTART VSD,'; VSD_'  ; Mark start of VSD tables
	 WINMAC  'Get_Version'                  ; 00
	 WINMAC  'Bell'                         ; 01
	 WINEND  VSD		; Mark end of VSD tables

	 WINSTART VMD,'; VMD_' ; Mark start of VMD tables
	 WINMAC  'Get_Version'                  ; 00
	 WINMAC  'Set_Mouse_Type'               ; 01
	 WINMAC  'Get_Mouse_Owner'              ; 02
	 WINEND  VMD		; Mark end of VMD tables

	 WINSTART VKD,'; VKD_' ; Mark start of VKD tables
	 WINMAC  'Get_Version'                  ; 00
	 WINMAC  'Define_Hot_Key'               ; 01
	 WINMAC  'Remove_Hot_Key'               ; 02
	 WINMAC  'Local_Enable_Hot_Key'         ; 03
	 WINMAC  'Local_Disable_Hot_Key'        ; 04
	 WINMAC  'Reflect_Hot_Key'              ; 05
	 WINMAC  'Cancel_Hot_Key_State'         ; 06
	 WINMAC  'Force_Keys'                   ; 07
	 WINMAC  'Get_Kbd_Owner'                ; 08
	 WINMAC  'Define_Paste_Mode'            ; 09
	 WINMAC  'Start_Paste'                  ; 0A
	 WINMAC  'Cancel_Paste'                 ; 0B
	 WINMAC  'Get_Msg_Key'                  ; 0C
	 WINMAC  'Peek_Msg_Key'                 ; 0D
	 WINMAC  'Flush_Msg_Key_Queue'          ; 0E
	 WINEND  VKD		; Mark end of VKD tables

	 WINSTART VCD,'; VCD: ' ; Mark start of VCD tables
	 WINMAC  'Get_Version'                  ; 00
	 WINMAC  'Set_Port_Global'              ; 01
	 WINMAC  'Get_Focus'                    ; 02
	 WINMAC  'Virtualize_Port'              ; 03
	 WINEND  VCD		; Mark end of VCD tables

	 WINSTART VHD,'; VHD_' ; Mark start of VHD tables
	 WINMAC  'Get_Version'                  ; 00
	 WINMAC  'Allocate_Handle'              ; 01
	 WINMAC  'Read'                         ; 02
	 WINMAC  'Write'                        ; 03
	 WINMAC  'Get_Status'                   ; 04
	 WINEND  VHD		; Mark end of VHD tables

	 WINSTART EBIOS,'; EBIOS_' ; Mark start of EBIOS tables
	 WINMAC  'Get_Version'                  ; 00
	 WINEND  EBIOS		; Mark end of EBIOS tables

	 WINSTART VNETBIOS,'; VNETBIOS_' ; Mark start of VNETBIOS tables
	 WINMAC  'Get_Version'                  ; 00
	 WINEND  VNETBIOS	; Mark end of VNETBIOS tables

	 WINSTART DOSMGR,'; DOSMGR_' ; Mark start of DOSMGR tables
	 WINMAC  'Get_Version'                  ; 00
	 WINMAC  'Set_Exec_VM_Data'             ; 01
	 WINMAC  'Copy_VM_Drive_State'          ; 02
	 WINMAC  'Exec_VM'                      ; 03
	 WINMAC  'Get_IndosPtr'                 ; 04
	 WINMAC  'Add_Device'                   ; 05
	 WINMAC  'Remove_Device'                ; 06
	 WINMAC  'Instance_Device'              ; 07
	 WINMAC  'Get_DOS_Crit_Status'          ; 08
	 WINMAC  'Enable_Indos_Polling'         ; 09
; New to Windows 3.10
	 WINMAC  'BackFill_Allowed'             ; 0A
	 WINMAC  'LocalGlobalReg'               ; 0B
	 WINEND  DOSMGR 	; Mark end of DOSMGR tables

	 WINSTART SHELL,'; SHELL_' ; Mark start of SHELL tables
	 WINMAC  'Get_Version'                  ; 00
	 WINMAC  'Resolve_Contention'           ; 01
	 WINMAC  'Event'                        ; 02
	 WINMAC  'SYSMODAL_Message'             ; 03
	 WINMAC  'Message'                      ; 04
; New to Windows 3.10
	 WINMAC  'GetVMInfo'                    ; 05
	 WINEND  SHELL		; Mark end of SHELL tables

	 WINSTART VMPoll,'; VMPoll_' ; Mark start of VMPoll tables
	 WINMAC  'Get_Version'                  ; 00
	 WINMAC  'Enable_Disable'               ; 01
	 WINEND  VMPoll 	; Mark end of VMPoll tables

	 WINSTART DOSNET,'; DOSNET_' ; Mark start of DOSNET tables
	 WINMAC  'Get_Version'                  ; 00
	 WINMAC  'Send_FILESYSCHANGE'           ; 01
	 WINMAC  'Do_PSP_Adjust'                ; 02
	 WINEND  DOSNET 	; Mark end of DOSNET tables

	 WINSTART VDD2,'; VDD2_'                ; Mark start of VDD2 tables
	 WINMAC  'Get_Version'                  ; 00
	 WINEND  VDD2				; Mark end of VDD2 tables

	 WINSTART INT13,'; INT13_'              ; Mark start of INT13 tables
	 WINMAC  'Get_Version'                  ; 00
	 WINMAC  'Device_Registered'            ; 01
	 WINEND  INT13				; Mark end of INT13 tables

	 WINSTART PageFile,'; PageFile_'        ; Mark start of PageFile tables
	 WINMAC  'Get_Version'                  ; 00
	 WINMAC  'Init_File'                    ; 01
	 WINMAC  'Clean_Up'                     ; 02
	 WINMAC  'Grow_File'                    ; 03
	 WINMAC  'Read_Or_Write'                ; 04
	 WINMAC  'Cancel'                       ; 05
	 WINMAC  'Test_IO_Valid'                ; 06
	 WINEND  PageFile			; Mark end of PageFile tables

	 WINSTART VNB,'; VNB_'                  ; Mark start of VNB tables
	 WINMAC  'Get_Version'                  ; 00
	 WINEND  VNB				; Mark end of VNB tables

	 WINSTART SERVER,'; SERVER_'            ; Mark start of SERVER tables
	 WINMAC  'Get_Version'                  ; 00
	 WINMAC  '??? 1'                        ; 01
	 WINMAC  'Get_Server_VM_Handle'         ; 02
	 WINMAC  'Test_Server_VM_Handle'        ; 03
	 WINEND  SERVER 			; Mark end of SERVER tables

	 WINSTART VNetSup,'; VNetSup_'          ; Mark start of VNetSup tables
	 WINMAC  'Get_Version'                  ; 00
	 WINEND  VNetSup			; Mark end of VNetSup tables

	 WINSTART VRedir,'; VRedir_'            ; Mark start of VRedir tables
	 WINMAC  'Get_Version'                  ; 00
	 WINEND  VRedir 			; Mark end of VRedir tables

	 WINSTART VBrowse,'; VBrowse_'          ; Mark start of VBrowse tables
	 WINMAC  'Get_Version'                  ; 00
	 WINEND  VBrowse			; Mark end of VBrowse tables

	 WINSTART VSHARE,'; VSHARE_'            ; Mark start of VSHARE tables
	 WINMAC  'Get_Version'                  ; 00
	 WINEND  VSHARE 			; Mark end of VSHARE tables

	 WINSTART SWATVXD,'; SWATVXD_'          ; Mark start of SWATVXD tables
	 WINMAC  'Get_Version'                  ; 00 Get_Version
	 WINMAC  'Out_Mono_String'              ; 01 Out_Mono_String
	 WINMAC  'SWATMSG'                      ; 02 SWATMSG
	 WINMAC  'Clear_Keys'                   ; 03 Clear Ctl- and Alt-keys
	 WINEND  SWATVXD			; Mark end of SWATVXD tables

	 WINSTART PM_BIOS,'; PMVDD_'            ; Mark start of PM_BIOS tables
	 WINMAC  'Get_Version'                  ; 00
	 WINMAC  '??? 1'                        ; 01
	 WINEND  PM_BIOS			; Mark end of PM_BIOS tables

	 WINSTART INTER21,'; DOS: '             ; Mark start of INTER21 tables
;;;;;;;; WINMAC  '0    ù    1    ù    2  '     ; 23 characters MAX
	 WINMAC  'Program Termination'          ; 00
	 WINMAC  'Keyboard input'               ; 01
	 WINMAC  'Display Character'            ; 02
	 WINMAC  'AUX input'                    ; 03
	 WINMAC  'AUX output'                   ; 04
	 WINMAC  'Print character'              ; 05
	 WINMAC  'Direct Console I/O'           ; 06
	 WINMAC  'Direct Console Input'         ; 07
	 WINMAC  'Read Keyboard, no echo'       ; 08
	 WINMAC  'Print String'                 ; 09
	 WINMAC  'Buffered Keyboard input'      ; 0A
	 WINMAC  'Check Keyboard Status'        ; 0B
	 WINMAC  'Flush Keyboard Buffer'        ; 0C
	 WINMAC  'Reset Drive'                  ; 0D
	 WINMAC  'Set Default Drive'            ; 0E
	 WINMAC  'Open disk file (fcb)'         ; 0F
	 WINMAC  'Close disk file (fcb)'        ; 10
	 WINMAC  'Find First File (fcb)'        ; 11
	 WINMAC  'Find Next File (fcb)'         ; 12
	 WINMAC  'Delete File (fcb)'            ; 13
	 WINMAC  'Sequential Read (fcb)'        ; 14
	 WINMAC  'Sequential Write (fcb)'       ; 15
	 WINMAC  'Create File (fcb)'            ; 16
	 WINMAC  'Rename File (fcb)'            ; 17
	 WINMAC 				; 18 (undoc)
	 WINMAC  'Get Default Drive'            ; 19
	 WINMAC  'Set DTA'                      ; 1A
	 WINMAC  'Get Default Drive Data'       ; 1B
	 WINMAC  'Get Drive Data'               ; 1C
	 WINMAC 				; 1D (undoc)
	 WINMAC 				; 1E (undoc)
	 WINMAC  'Get Default DPB'              ; 1F
	 WINMAC 				; 20 (undoc)
	 WINMAC  'Random Read (fcb)'            ; 21
	 WINMAC  'Random Write (fcb)'           ; 22
	 WINMAC  'Get File Size (fcb)'          ; 23
	 WINMAC  'Set Random Record (fcb)'      ; 24
	 WINMAC  'Set Interrupt Vector'         ; 25
	 WINMAC  'Create New PSP'               ; 26
	 WINMAC  'Random Block Read (fcb)'      ; 27
	 WINMAC  'Random Block Write(fcb)'      ; 28
	 WINMAC  'Parse Filenmae (fcb)'         ; 29
	 WINMAC  'Get Date'                     ; 2A
	 WINMAC  'Set Date'                     ; 2B
	 WINMAC  'Get Time'                     ; 2C
	 WINMAC  'Get Time'                     ; 2D
	 WINMAC  'Set/Reset Verify Flag'        ; 2E
	 WINMAC  'Get DTA'                      ; 2F
	 WINMAC  'Get DOS version'              ; 30
	 WINMAC  'Keep Program'                 ; 31
	 WINMAC  'Get DPB'                      ; 32
	 WINMAC  'Ctrl-Break / Misc'            ; 33
	 WINMAC  'Get InDOS Flag Address'       ; 34
	 WINMAC  'Get Interrupt Vector'         ; 35
	 WINMAC  'Get Disk Free Space'          ; 36
	 WINMAC  'Get/Set SWITCHAR'             ; 37 (undoc)
	 WINMAC  'Get/Set Country Info'         ; 38
	 WINMAC  'Create Directory'             ; 39
	 WINMAC  'Remove Directory'             ; 3A
	 WINMAC  'Change Directory'             ; 3B
	 WINMAC  'Create File (handle)'         ; 3C
	 WINMAC  'Open File (handle)'           ; 3D
	 WINMAC  'Close File (handle)'          ; 3E
	 WINMAC  'Read File (handle)'           ; 3F
	 WINMAC  'Write File (handle)'          ; 40
	 WINMAC  'Delete File (handle)'         ; 41
	 WINMAC  'Move File Pointer'            ; 42
	 WINMAC  'Get/Set File Attributes'      ; 43
	 WINMAC  'IOCTL Interface'              ; 44
	 WINMAC  'Duplicate File Handle'        ; 45
	 WINMAC  'Force Duplicate Handle'       ; 46
	 WINMAC  'Get Current Directory'        ; 47
	 WINMAC  'Allocate Memory'              ; 48
	 WINMAC  'Release Memory'               ; 49
	 WINMAC  'Resize Memory'                ; 4A
	 WINMAC  'Load/Execute Program'         ; 4B
	 WINMAC  'End program'                  ; 4C
	 WINMAC  'Get Child Exit Code'          ; 4D
	 WINMAC  'Find First File'              ; 4E
	 WINMAC  'Find Next File'               ; 4F
	 WINMAC  'Set PSP Address'              ; 50
	 WINMAC  'Get PSP Address'              ; 51
	 WINMAC  'Get List of Lists'            ; 52 (undoc)
	 WINMAC  'Translate BPB'                ; 53 (undoc)
	 WINMAC  'Get Verify State'             ; 54
	 WINMAC  'Create PSP'                   ; 55 (undoc)
	 WINMAC  'Rename File'                  ; 56
	 WINMAC  'Get/Set File Date/Time'       ; 57
	 WINMAC  'Get/Set Alloc Strategy'       ; 58
	 WINMAC  'Get Extended Error'           ; 59
	 WINMAC  'Create Temporary File'        ; 5A
	 WINMAC  'Create New File'              ; 5B
	 WINMAC  'Lock/Unlock File'             ; 5C
	 WINMAC  'Misc. DOS Funcs'              ; 5D (mostly undoc)
	 WINMAC  'Network functions'            ; 5E
	 WINMAC  'Network functions'            ; 5F
	 WINMAC  'True Name'                    ; 60 (undoc)
	 WINMAC 				; 61 (undoc)
	 WINMAC  'Get PSP Segment'              ; 62 (undoc)
	 WINMAC  'Two-byte Char Support  '      ; 63 (undoc)
	 WINMAC 				; 64 (undoc)
	 WINMAC  'Country Dependent Funcs'      ; 65
	 WINMAC  'Get/Set Global CodePage'      ; 66
	 WINMAC  'Set Max Handle Count'         ; 67
	 WINMAC  'Commit File'                  ; 68
	 WINMAC  'Get/Set Disk Serial No.'      ; 69 (undoc)
	 WINMAC  'Commit File-6A'               ; 6A (undoc)
	 WINMAC 				; 6B (undoc)
	 WINMAC  'Extended Open/Create'         ; 6C
	 WINMAC  'Find First ROM Program'       ; 6D (undoc)
	 WINMAC  'Find Next ROM Program'        ; 6E (undoc)
	 WINMAC  'DOS in ROM Functions'         ; 6F (undoc)
	 WINMAC 				; 70 (undoc)
	 WINMAC  'Long Filename Functions'      ; 71 (undoc)
	 WINMAC  'Long Filename Functions'      ; 72 (undoc)
	 WINEND  INTER21			; Mark end of INTER21 tables

	WINSTART INTER22,'; W386: ',VALW
;;;;;;; WINMAC	'    ù    1    ù    2 ', xxxx ; 22 characters MAX
	WINMAC	'Query Win386 installed', 0000h
	WINMAC	'Query Win386 state'    , 0001h
	WINMAC	'Physical to linear'    , 0002h
	WINMAC	'Check linear address'  , 0003h
	WINMAC	'Map in low VM memory'  , 0004h
	WINMAC	'Map out low VM memory' , 0005h
	WINMAC	'Get DynaLink address'  , 0006h
	WINMAC	'Get VxD name'          , 0007h
	WINMAC	'Get PDE for context'   , 0008h
	WINMAC	'Get phys address'      , 0009h
	WINMAC	'Get LDT address'       , 000Ah
	WINMAC	'Get thread ID'         , 000Bh
	WINMAC	'Get transfer space add', 000Ch
	WINMAC	'Get ARPL handler'      , 000Dh
	WINEND	 INTER22			; Mark end of INTER22 tables
	

	WINSTART INTER31,'; DPMI: ',VALW        ; Mark start of INTER31 tables
;;;;;;; WINMAC	'    ù    1    ù    2 ', xxxx ; 22 characters MAX
	WINMAC	'Allocate LDT Desc'     , 0000h
	WINMAC	'Free LDT Desc'         , 0001h
	WINMAC	'Segment to Desc'       , 0002h
	WINMAC	'Get Selector Increment', 0003h
	WINMAC	'Lock Segment w/Sel'    , 0004h
	WINMAC	'Unlock Segment w/Sel'  , 0005h
	WINMAC	'Get Selector Base'     , 0006h
	WINMAC	'Set Selector Base'     , 0007h
	WINMAC	'Set Selector Limit '   , 0008h
	WINMAC	'Set Descriptor A/R'    , 0009h
	WINMAC	'Create Alias Desc'     , 000Ah
	WINMAC	'Get Descriptor Entry'  , 000Bh
	WINMAC	'Set Descriptor Entry'  , 000Ch
	WINMAC	'Allocate Specific Desc', 000Dh
	WINMAC	'Get Multiple Descs *'  , 000Eh
	WINMAC	'Set Multiple Descs *'  , 000Fh

	WINMAC	'Allocate DOS Memory'   , 0100h
	WINMAC	'Free DOS Memory'       , 0101h
	WINMAC	'Resize DOS Memory'     , 0101h

	WINMAC	'Get RM Interrupt Vect' , 0200h
	WINMAC	'Set RM Interrupt Vect' , 0201h
	WINMAC	'Get Exception Vect'    , 0202h
	WINMAC	'Set Exception Vect'    , 0203h
	WINMAC	'Get PM Interrupt Vect' , 0204h
	WINMAC	'Set PM Interrupt Vect' , 0205h
	WINMAC	'Get Ext PM Excpt Vect*', 0210h
	WINMAC	'Get Ext RM Excpt Vect*', 0211h
	WINMAC	'Set Ext PM Excpt Vect*', 0212h
	WINMAC	'Set Ext RM Excpt Vect*', 0213h
	WINMAC	'Set Win PM Excpt Vect*', 0283h

	WINMAC	'Simulate RM Interrupt' , 0300h
	WINMAC	'Call RM, Far Return'   , 0301h
	WINMAC	'Call RM, IRET Return'  , 0302h
	WINMAC	'Allocate RM Callback'  , 0303h
	WINMAC	'Free RM Callback'      , 0304h
	WINMAC	'Get Save/Restore Addr' , 0305h
	WINMAC	'Get Raw Mode Swch Addr', 0306h

	WINMAC	'Get Version'           , 0400h
	WINMAC	'Get DPMI Capability *' , 0401h

	WINMAC	'Get Free Memory Info'  , 0500h
	WINMAC	'Allocate Memory'       , 0501h
	WINMAC	'Free Memory'           , 0502h
	WINMAC	'Resize Memory'         , 0503h
	WINMAC	'Allocate Linear Mem *' , 0504h
	WINMAC	'Resize Linear Memory *', 0505h
	WINMAC	'Get Page Attributes *' , 0506h
	WINMAC	'Set Page Attributes *' , 0507h
	WINMAC	'Map Device in Memory *', 0508h
	WINMAC	'Map Conv Mem in Mem *' , 0509h
	WINMAC	'Get Memory Size&Base *', 050Ah
	WINMAC	'Get Memory Info *'     , 050Bh

	WINMAC	'Lock Linear Region'    , 0600h
	WINMAC	'Unlock Linear Region'  , 0601h
	WINMAC	'Mark RM Region Pagable', 0602h
	WINMAC	'Relock RM Region'      , 0603h
	WINMAC	'Get Page Size'         , 0604h

	WINMAC	'Mark Pageable w/Select', 0700h
	WINMAC	'Mark Discard w/Select' , 0701h
	WINMAC	'Mark As Pagable'       , 0702h
	WINMAC	'Mark As Discardable'   , 0703h

	WINMAC	'Physical to Linear'    , 0800h
	WINMAC	'Free Physical to Lin *', 0801h

	WINMAC	'Get & Clear Virt Intr' , 0900h
	WINMAC	'Get & Set Virt Intr'   , 0901h
	WINMAC	'Get Virtual Intr State', 0902h

	WINMAC	'Get VendorSpecific API', 0A00h

	WINMAC	'Set Debug Watchpoint'  , 0B00h
	WINMAC	'Clear Debug Watchpoint', 0B01h
	WINMAC	'Get Debug Watchpoint'  , 0B02h
	WINMAC	'Reset Debug Watchpoint', 0B03h

	WINMAC	'Install TSR Provider *', 0C00h
	WINMAC	'Go Resident *'         , 0C01h

	WINMAC	'Allocate Shared Mem *' , 0D00h
	WINMAC	'Free Shared Memory *'  , 0D01h
	WINMAC	'Serialize Shared Mem *', 0D02h
	WINMAC	'Free Serial Shr Mem *' , 0D03h

	WINMAC	'Get FPU State *'       , 0E00h
	WINMAC	'Set FPU Emulation *'   , 0E01h

	WINEND	INTER31 			; Mark end of INTER31 tables

	WINSTART VWIN32,'; VWIN: ',VALW         ; Mark start of VWIN32 tables
;;;;;;; WINMAC	'    ù    1    ù    2 ', xxxx ; 22 characters MAX
	WINMAC	'Get_Version'           , 0000h
	WINMAC	'DIOCCompletionRoutine' , 0001h
	WINMAC	'QueueUserApc'          , 0002h
	WINMAC	'Get_Thread_Context'    , 0003h
	WINMAC	'Set_Thread_Context'    , 0004h
	WINMAC	'CopyMem'               , 0005h
	WINMAC	'Npx_Exception'         , 0006h
	WINMAC	'Emulate_Npx'           , 0007h
	WINMAC	'CheckDelayedNpxTrap'   , 0008h
	WINMAC	'EnterCrstR0'           , 0009h
	WINMAC	'LeaveCrstR0'           , 000Ah
	WINMAC	'FaultPopup'            , 000Bh
	WINMAC	'GetContextHandle'      , 000Ch
	WINMAC	'GetCurrentProcessHandl', 000Dh
	WINMAC	'SetWin32Event'         , 000Eh
	WINMAC	'PulseWin32Event'       , 000Fh
	WINMAC	'ResetWin32Event'       , 0010h
	WINMAC	'WaitSingleObject'      , 0011h
	WINMAC	'WaitMultipleObjects'   , 0012h
	WINMAC	'CreaterRing0Thread'    , 0013h
	WINMAC	'CloseVxDHandle'        , 0014h
	WINMAC	'ActiveTimeBiasSet'     , 0015h
	WINMAC	'GetCurrentDirectory'   , 0016h
	WINMAC	'BlueScreenPopup'       , 0017h
	WINMAC	'TerminateApp'          , 0018h
	WINMAC	'QueueKernelAPC'        , 0019h
	WINMAC	'SysErrorBox'           , 001Ah
	WINMAC	'IsClientWin32'         , 001Bh
	WINMAC	'IFSRIPWhenLev2Taken'   , 001Ch

	WINEND	VWIN32				; Mark end of VWIN32 tables

	WINEND			; Mark end of WINTAB table

TEXT	 segment use32 byte public 'data' ; Start TEXT segment
	 assume  ds:DGROUP

	 public  TXT_WINUNK,TXT_WINUNK1,TXT_WINUNK2
TXT_WINUNK db	 '; Unknown '
TXT_WINUNK1 db	 '____, '
TXT_WINUNK2 db	 '____',0

TEXT	 ends			; End TEXT segment


WDATAZ	 segment use32 para public 'wdataz' ; Start WDATAZ segment
	 assume  ds:WGROUP

	 public  WTAIL
WTAIL	 OVLD_STR <offset WGROUP:WTAIL,'WINTAB',> ; Define overlay info

WDATAZ	 ends			; End WDATAZ segment

	 MEND			; End INT1_WIN module
