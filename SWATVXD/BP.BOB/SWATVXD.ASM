;'$Header:   P:/PVCS/SWATVXD/SWATVXD.ASV   1.28   10 Aug 1998 10:46:22   BOB  $
	title	SWATVXD -- SWATVXD for Windows 3.x
	page	78,130
	name	SWATVXD

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1990-2002 Qualitas, Inc.  All rights reserved.

Segmentation:  Group _IGROUP:
	       Program segment _ITEXT,	dword-aligned,	use32,	public, 'ICODE'
	       Data    segment _IDATA,	dword-aligned,	use32,	public, 'ICODE'
	       Group _LGROUP:
	       Program segment _LTEXT,	dword-aligned,	use32,	public, 'CODE'
	       Data    segment _LDATA,	dword-aligned,	use32,	public, 'CODE'
	       Group _PGROUP:
	       Program segment _TEXT,	dword-aligned,	use32,	public, 'PCODE'
	       Data    segment _DATA,	dword-aligned,	use32,	public, 'PCODE'

	       Segment	       _RCODE,	word-aligned,	use16,	public, 'RCODE'

Program derived from:  None.

Original code by:  William R. Lewis, July, 1990.

Modifications by:  None.

|

.386p
.xlist
	include VMM.INC 	; Fixed version of file from DDK
	include VKD.INC
	include V86MMGR.INC
	include SHELL.INC

	include WFW.INC 	; Homemade include for WFW VxDs

	include MASM.INC	; From Bob's standard includes
	include 386.INC
	include PTR.INC
	include CPUFLAGS.INC
	include OPCODES.INC

	include ASCII.INC
	include VIDATTR.INC
	include DEVMAC.INC
	include DOSCALL.INC
	include IOCTL.INC
	include MAXDEV.INC
	include SCANCODE.INC
	include VCPI.INC
	include WKD.INC 	; Windows kernel debugger equates/strucs

	include QMAX_CTL.INC	; From 386MAX
	include QMAX_FIL.INC
	include QMAX_GLB.INC

	include SWAT_INF.INC	; From 386SWAT
	include SWAT_LC3.INC
	include SWAT_LCL.INC
	include SWAT_SYM.INC

Create_SWAT_Service_Table equ True	; Needed for SWATVXD.INC

	include WINDEVID.INC	; Define SWAT_Device_ID
	include SWATVXD.INC	; Define service table
	include SWAT_DBG.INC	; DBG_FLAG and DB2_FLAG masks
	include SWAT_MAC.INC	; Debugging macros
	include SWATHOOK.INC	; VXDHOOK_STR
	include SWATSINI.INC	; SYSTEM.INI cookies
	include SWATVER.INC	; Version # extrns
	include DEBUGSYS.INC	; Windows kernel debugger equates/strucs
.list

@WINDOWS_IBV0	equ	50h	; Master PIC base (according to Aaron Reynolds)

;******************************************************************************
;		 V I R T U A L	 D E V I C E   D E C L A R A T I O N
;******************************************************************************

SWAT_Init_Order equ	000000000h ; See VMM.INC for deatils
@DEBUGDEVID equ 1		; Set to 0 to use SWAT_Device_ID
				; and to 1 to use Debug_Device_ID
				; and to 2 to use DebugCmd_Device_ID

if @DEBUGDEVID eq 0
@SWATDEVID equ	SWAT_Device_ID
if1
%out Using SWAT_Device_ID
endif
endif				; If @DEBUGDEVID
if @DEBUGDEVID eq 1
@SWATDEVID equ	Debug_Device_ID
if1
%out Using Debug_Device_ID
endif
endif				; If @DEBUGDEVID
if @DEBUGDEVID eq 2
@SWATDEVID equ	DebugCmd_Device_ID
if1
%out Using DebugCmd_Device_ID
endif
endif				; If @DEBUGDEVID

Declare_Virtual_Device SWAT, SWAT_VERS_H, SWAT_VERS_T, SWAT_CONTROL, @SWATDEVID, SWAT_Init_Order, SWAT_VM_API, SWAT_PM_API

COMMENT|

When we use Debug_Device_ID or DebugCmd_Device_ID instead of
SWAT_Device_ID, the following fixup is called early in WIndows
initialization.  This value is overwritten by the VxD processing code
with the reference data from RM.  It is called during initialization
before that happens.

|

if @DEBUGDEVID
VxD_LOCKED_DATA_SEG
L1:
	org	SWAT_DDB.DDB_Reference_Data
	dd	OFFSET32 WKDSWAT
	org	L1
VxD_LOCKED_DATA_ENDS
endif				; If @DEBUGDEVID

;******************************************************************************

VxD_LOCKED_DATA_SEG		; Begin _LDATA segment

	extrn	OLDINT0E_FOFF:dword
	extrn	DBG_FLAG:dword
	extrn	DB2_FLAG:dword
	extrn	DB3_FLAG:dword
	extrn	MONO_VIDBASE:dword
	extrn	MONO_ATTR:byte

	extrn	MSG_THRUXITWARN:byte

	extrn	MSG_FATAL_ERROR:byte
	extrn	MSG_FATAL_ERROR0:byte, MSG_FATAL_ERROR_NULL:byte
	extrn	MSG_HOOK_FEH_UGH:byte
	extrn	MSG_HOOK_ODS_UGH:byte

	extrn	MSG_GSDVME0:byte, MSG_GSDVME_VM:byte
	extrn	MSG_GSDVME:byte, MSG_GSDVME_EC:byte, MSG_GSDVME_TEXT:byte

	extrn	MSG_PAGING_OFF:byte, MSG_PAGING_ON:byte
	extrn	MSG_WFW:byte

	extrn	MSG_MAPINFO:byte, MSG_MAPINFO0:byte, MSG_MAPINFO1:byte

	extrn	MSG_SVI:byte, MSG_SVI_H1:byte
	extrn	MSG_SVT:byte, MSG_SVT_H1:byte
	extrn	MSG_CVM:byte, MSG_CVM_H1:byte
	extrn	MSG_VMT:byte, MSG_VMT_H1:byte
	extrn	MSG_VNE:byte, MSG_VNE_H1:byte, MSG_VNE_X:byte
	extrn	MSG_DVM:byte, MSG_DVM_H1:byte
	extrn	MSG_SEX:byte
	extrn	MSG_SCEX:byte
	extrn	MSG_VM_CRITICAL_INIT:byte, MSGH1_VM_CRITICAL_INIT:byte
	extrn	MSG_VM_INIT:byte, MSGH1_VM_INIT:byte
	extrn	MSG_BEGIN_PM_APP:byte, MSGH1_BEGIN_PM_APP:byte
	extrn	MSG_END_PM_APP:byte, MSGH1_END_PM_APP:byte
	extrn	MSG_VM_SUSPEND:byte, MSGH1_VM_SUSPEND:byte
	extrn	MSG_VM_RESUME:byte, MSGH1_VM_RESUME:byte
	extrn	MSG_SDF:byte, MSG_SDF_H1:byte, MSG_SDF_H2:byte, MSG_SDF_H3:byte
	extrn	MSG_BEGIN_MSG_MODE:byte, MSGH1_BEGIN_MSG_MODE:byte
	extrn	MSG_END_MSG_MODE:byte, MSGH1_END_MSG_MODE:byte
	extrn	MSG_QUERY_DESTROY:byte, MSGH1_QUERY_DESTROY:byte
	extrn	MSG_DEBUG_QUERY:byte, MSGH1_DEBUG_QUERY:byte
	extrn	MSG_REBOOT_PROCESSOR:byte, MSGH1_REBOOT_PROCESSOR:byte
	extrn	MSG_DEVICE_REBOOT_NOTIFY:byte
	extrn	MSG_CRIT_REBOOT_NOTIFY:byte,MSGH1_CLOSE_VM_NOTIFY:byte
	extrn	MSG_CLOSE_VM_NOTIFY:byte
	extrn	MSG_POWER_EVENT:byte

	extrn	MSG_SYS_DYNAMIC_DEVICE_INIT:byte
	extrn	MSG_SYS_DYNAMIC_DEVICE_EXIT:byte
	extrn	MSG_CREATE_THREAD:byte
	extrn	MSG_CREATE_THREAD1:byte
	extrn	MSG_THREAD_INIT:byte
	extrn	MSG_THREAD_INIT1:byte
	extrn	MSG_TERMINATE_THREAD:byte
	extrn	MSG_TERMINATE_THREAD1:byte
	extrn	MSG_THREAD_NOT_EXECUTEABLE:byte
	extrn	MSG_THREAD_NOT_EXECUTEABLE1:byte
	extrn	MSG_DESTROY_THREAD:byte
	extrn	MSG_DESTROY_THREAD1:byte
	extrn	MSG_PNP_NEW_DEVNODE:byte
	extrn	MSG_W32_DEVICEIOCONTROL:byte
	extrn	MSG_SYS_VM_TERMINATE2:byte
	extrn	MSG_SYSTEM_EXIT2:byte
	extrn	MSG_SYS_CRITICAL_EXIT2:byte
	extrn	MSG_VM_TERMINATE2:byte
	extrn	MSG_VM_NOT_EXECUTEABLE2:byte
	extrn	MSG_DESTROY_VM2:byte
	extrn	MSG_VM_SUSPEND2:byte
	extrn	MSG_END_MESSAGE_MODE2:byte
	extrn	MSG_END_PM_APP2:byte
	extrn	MSG_DEVICE_REBOOT_NOTIFY2:byte
	extrn	MSG_CRIT_REBOOT_NOTIFY2:byte
	extrn	MSG_CLOSE_VM_NOTIFY2:byte
	extrn	MSG_GET_CONTENTION_HANDLER:byte
	extrn	MSG_KERNEL32_INITIALIZED:byte
	extrn	MSG_KERNEL32_SHUTDOWN:byte

	extrn	SWAT_IPF_STR_FOFF:dword

	public	PLCLIRQ
PLCLIRQ dd	OFFSET32 LCLIRQ0 ; Ptr to IRQ0 handler
	dd	OFFSET32 LCLIRQ1 ; ...	     1 ...
	dd	OFFSET32 LCLIRQ2 ; ...	     2 ...
	dd	OFFSET32 LCLIRQ3 ; ...	     3 ...
	dd	OFFSET32 LCLIRQ4 ; ...	     4 ...
	dd	OFFSET32 LCLIRQ5 ; ...	     5 ...
	dd	OFFSET32 LCLIRQ6 ; ...	     6 ...
	dd	OFFSET32 LCLIRQ7 ; ...	     7 ...

	public	OLDIRQ0_FVEC,OLDIRQ1_FVEC,OLDIRQ2_FVEC,OLDIRQ3_FVEC
	public	OLDIRQ4_FVEC,OLDIRQ5_FVEC,OLDIRQ6_FVEC,OLDIRQ7_FVEC
OLDIRQ0_FVEC df ?		; Save area for old IRQ0 handler
	dw	?		; Qword alignment for SIB indexing
OLDIRQ1_FVEC df ?		; ...		       1 ...
	dw	?		; ...
OLDIRQ2_FVEC df ?		; ...		       2 ...
	dw	?		; ...
OLDIRQ3_FVEC df ?		; ...		       3 ...
	dw	?		; ...
OLDIRQ4_FVEC df ?		; ...		       4 ...
	dw	?		; ...
OLDIRQ5_FVEC df ?		; ...		       5 ...
	dw	?		; ...
OLDIRQ6_FVEC df ?		; ...		       6 ...
	dw	?		; ...
OLDIRQ7_FVEC df ?		; ...		       7 ...
	dw	?		; ...

DEVICE_CALL_PROCS label dword	; List of handlers for device call messages
	dd	OFFSET32 SYS_CRITICAL_INIT	; 0000h
	dd	OFFSET32 DEVICE_INIT		; 0001h
	dd	OFFSET32 INIT_COMPLETE		; 0002h
	dd	OFFSET32 SYS_VM_INIT		; 0003h
	dd	OFFSET32 SYS_VM_TERMINATE	; 0004h
	dd	OFFSET32 SYSTEM_EXIT		; 0005h
	dd	OFFSET32 SYS_CRITICAL_EXIT	; 0006h
	dd	OFFSET32 CREATE_VM		; 0007h
	dd	OFFSET32 VM_CRITICAL_INIT	; 0008h
	dd	OFFSET32 VM_INIT		; 0009h
	dd	OFFSET32 VM_TERMINATE		; 000Ah
	dd	OFFSET32 VM_NOT_EXECUTEABLE	; 000Bh
	dd	OFFSET32 DESTROY_VM		; 000Ch
	dd	OFFSET32 VM_SUSPEND		; 000Dh
	dd	OFFSET32 VM_RESUME		; 000Eh
	dd	OFFSET32 SET_DEVICE_FOCUS	; 000Fh
	dd	OFFSET32 BEGIN_MESSAGE_MODE	; 0010h
	dd	OFFSET32 END_MESSAGE_MODE	; 0011h
	dd	OFFSET32 REBOOT_PROCESSOR	; 0012h
	dd	OFFSET32 QUERY_DESTROY		; 0013h
	dd	OFFSET32 DEBUG_QUERY		; 0014h
	dd	OFFSET32 BEGIN_PM_APP		; 0015h
	dd	OFFSET32 END_PM_APP		; 0016h
; Start Win 3.1 system calls
	dd	OFFSET32 DEVICE_REBOOT_NOTIFY	; 0017h
	dd	OFFSET32 CRIT_REBOOT_NOTIFY	; 0018h
	dd	OFFSET32 CLOSE_VM_NOTIFY	; 0019h
	dd	OFFSET32 POWER_EVENT		; 001Ah
; Start Win95 system calls
	dd	OFFSET32 SYS_DYNAMIC_DEVICE_INIT ; 001Bh
	dd	OFFSET32 SYS_DYNAMIC_DEVICE_EXIT ; 001Ch
	dd	OFFSET32 CREATE_THREAD		  ; 001Dh
	dd	OFFSET32 THREAD_INIT		  ; 001Eh
	dd	OFFSET32 TERMINATE_THREAD	  ; 001Fh
	dd	OFFSET32 THREAD_NOT_EXECUTEABLE  ; 0020h
	dd	OFFSET32 DESTROY_THREAD 	  ; 0021h
	dd	OFFSET32 PNP_NEW_DEVNODE	  ; 0022h
	dd	OFFSET32 W32_DEVICEIOCONTROL	  ; 0023h
	dd	OFFSET32 SYS_VM_TERMINATE2	  ; 0024h
	dd	OFFSET32 SYSTEM_EXIT2		  ; 0025h
	dd	OFFSET32 SYS_CRITICAL_EXIT2	  ; 0026h
	dd	OFFSET32 VM_TERMINATE2		  ; 0027h
	dd	OFFSET32 VM_NOT_EXECUTEABLE2	  ; 0028h
	dd	OFFSET32 DESTROY_VM2		  ; 0029h
	dd	OFFSET32 VM_SUSPEND2		  ; 002Ah
	dd	OFFSET32 END_MESSAGE_MODE2	  ; 002Bh
	dd	OFFSET32 END_PM_APP2		  ; 002Ch
	dd	OFFSET32 DEVICE_REBOOT_NOTIFY2	 ; 002Dh
	dd	OFFSET32 CRIT_REBOOT_NOTIFY2	  ; 002Eh
	dd	OFFSET32 CLOSE_VM_NOTIFY2	  ; 002Fh
	dd	OFFSET32 GET_CONTENTION_HANDLER  ; 0030h
	dd	OFFSET32 KERNEL32_INITIALIZED	  ; 0031h
	dd	OFFSET32 KERNEL32_SHUTDOWN	  ; 0032h
DEVICE_CALL_LAST equ	($-DEVICE_CALL_PROCS)/4

	public	VXD_FILE_4GB, VXD_FILE_CR3
VXD_FILE_4GB	dw	0	; Save area for SWAT's 4GB selector
VXD_FILE_CR3	dw	0	; Save area for SWAT's CR3 selector

	public	INIT_PROT_VEC, INIT_PROT_VEC, SWATMSG_FVEC, SWATINT67_VEC
INIT_PROT_VEC	df	0	; Selector|Offset --> INIT_PROT
REST_PROT_VEC	df	0	; Selector|Offset --> REST_PROT
SWATMSG_FVEC	df	0	; Selector|Offset --> SWATMSG
SWATINT67_VEC	df	0	; Selector|Offset --> SWAT's LCL_INT67

	public	SWATTER_FVEC
SWATTER_FVEC	df	0	; Selector|Offset --> SWATTER
		dw	?	; For alignment

	public	INT67_SEGOFF,INT67_RMPHYSADDR
INT67_SEGOFF	dd	0	; Segment:offset of INT_67 in TSR
INT67_RMPHYSADDR dd 0	; RM physical address of INT_67 ...

	public	SWATMSG_TEXT
SWATMSG_TEXT	db	16 dup (?) ; Text message sent to SWATMSG

	public	SWATINFO_LIN
SWATINFO_LIN	dd	0	; Linear address of SWATINFO

	public	COMMAND_TAIL
COMMAND_TAIL	dd	0	; Pointer to WIN.COM command tail

	public	SWAT_CS, SWAT_DS
SWAT_CS dw	0		; Code selector for SWAT's PGROUP
SWAT_DS dw	0		; Data selector for SWAT's DGROUP

	public	SWAT_CS_BASE
SWAT_CS_BASE	dd	0	; Base of SWAT's CS

	public	WIN3_VERSION
WIN3_VERSION	dw	0	; Windows VMM version #

INT01_IDTENT IDT_STR	<>	; Save area for INT 01h IDT entry
INT02_IDTENT IDT_STR	<>	; ...		    02h ...
INT03_IDTENT IDT_STR	<>	; ...		    03h ...
INT41_IDTENT IDT_STR	<>	; ...		    41h ...

	public	DEVICE_LIST
DEVICE_LIST dd	0		; Pointer to DEVICE_LIST (ECX upon entry to VxD)

	public	VXDHOOKS_HEAD, PMHOOKS_HEAD
VXDHOOKS_HEAD	dd	0	; Head of chain of VXDHOOK_STR structures
PMHOOKS_HEAD	dd	0	; Head of chain of PMHOOK_STR structures

	public	LCL_VXDHOOK_STR,LCL_PMHOOK_STR
LCL_VXDHOOK_STR dd ?		; Save area for ptr inside VXDHOOK_STR
LCL_PMHOOK_STR dd ?		; ...			   PMHOOK_STR

	public	OLD_Control_Proc, OLD_PM_API_Proc
OLD_Control_Proc dd	0	; ==> target VxD's original Control_Proc
OLD_PM_API_Proc dd	0	; ==> target VxD's original PM_API_Proc

	public	OLD_HANDLER
OLD_HANDLER	dd	0	; Address of generic original handler


; Saved addresses of original hooked VMM services

	public	OLD_OUT_DEBUG_STRING
	public	OLD_OUT_DEBUG_CHR
	public	OLD_OUT_MONO_STRING
	public	OLD_OUT_MONO_CHR
	public	OLD_IN_DEBUG_CHR
	public	OLD_DEBUG_OUT_SERVICE
	public	OLD_TRACE_OUT_SERVICE
OLD_OUT_DEBUG_STRING		dd	0	; Address of original
OLD_OUT_DEBUG_CHR		dd	0	; ...
OLD_OUT_MONO_STRING		dd	0	; ...
OLD_OUT_MONO_CHR		dd	0	; ...
OLD_IN_DEBUG_CHR		dd	0	; ...
OLD_DEBUG_OUT_SERVICE		dd	0	; ...
OLD_TRACE_OUT_SERVICE		dd	0	; ...

	public	OLD_FATAL_ERROR_HANDLER
OLD_FATAL_ERROR_HANDLER 	dd	0	; Address of original

	public	OLD_GetSetDetailedVMError
OLD_GetSetDetailedVMError	dd	0	; Address of original

	public	LCL_CHR
LCL_CHR db	?,0		; Character save area for Out_Debug_Chr

IBV0	db	0		; Save area for SWAT's IBV0
IBV1	db	0		; ...		       IBV1

STR_HOOKVXD	db	'HOOKVXD', 0    ; String for Get_Profile_String
MSG_HOOKVXD	db	'    Hook Device Control Proc: '
MSG_HOOKVXD0	db	80 dup (' ') ; Workspace for HOOKVXD= stuff

STR_HOOKPM	db	'HOOKPM', 0     ; String for Get_Profile_String
MSG_HOOKPM	db	'    Hook Device PM API Entry: '
MSG_HOOKPM0	db	80 dup (' ') ; Workspace for HOOKPM= stuff

BUF_HOOKVXD	db	64 dup (' ') ; Buffer to hold VxD name, etc.
BUF_LASTVXD	db	9 dup (' ') ; Buffer to hold VxD name, etc.

STR_WINA20	db	'LA20HMA '      ; String to search for WINA20.386

MSGBOX_CAP	db	'SWATVXD', 0
MSGBOX_TXT1	db	'386SWAT is too old to support Ctrl+Alt+Pad5', CR, LF, 0
MSGBOX_TXT2	db	'386SWAT is not hooking INT 01h/03h.', CR, LF, 0

; Data related to VM_Not_Executable broadcast

@VNEMASK equ	003Fh			; Isolate VM_Not_Executable reasons

	public	VNE_TAB
VNE_TAB label	dword			; Table of VM_Not_Executable messages
	dd	OFFSET32 MSG_VNE_None		; 0000h - 0
	dd	OFFSET32 MSG_VNE_Crashed	; 0001h - 1
	dd	OFFSET32 MSG_VNE_Nuked		; 0002h - 2
	dd	OFFSET32 MSG_VNE_CreateFail	; 0004h - 3
	dd	OFFSET32 MSG_VNE_CrInitFail	; 0008h - 4
	dd	OFFSET32 MSG_VNE_InitFail	; 0010h - 5
	dd	OFFSET32 MSG_VNE_Closed 	; 0020h - 6

MSG_VNE_None	db	'<<none>>', CR, LF, 0
MSG_VNE_Crashed db	'Crashed', CR, LF, 0
MSG_VNE_Nuked	db	'Nuked', CR, LF, 0
MSG_VNE_CreateFail db	'Create_VM failed', CR, LF, 0
MSG_VNE_CrInitFail db	'VM_Critical_Init failed', CR, LF, 0
MSG_VNE_InitFail db	'VM_Init failed', CR, LF, 0
MSG_VNE_Closed	db	'Closed', CR, LF, 0

; GetSetDetailedVMError stuff

VMError dd	0			; EAX from GetSetDetailedVMError

GSDVME_Codes	label	dword		; List of error codes
	dd	GSDVME_PrivInst
	dd	GSDVME_InvalInst
	dd	GSDVME_InvalPgFlt
	dd	GSDVME_InvalGpFlt
	dd	GSDVME_InvalFlt
	dd	GSDVME_UserNuke
	dd	GSDVME_DevNuke
	dd	GSDVME_DevNukeHdwr
	dd	GSDVME_NukeNoMsg
	dd	GSDVME_InsMemV86
	dd	GSDVME_InsV86Space
	dd	GSDVME_InsMemXMS
	dd	GSDVME_InsMemEMS
	dd	GSDVME_InsMemV86Hi
	dd	GSDVME_InsMemVid
	dd	GSDVME_InsMemVM
	dd	GSDVME_InsMemDev
	dd	GSDVME_CrtNoMsg
@GSDVME_Codes	equ	($-GSDVME_Codes)/4	; # of entries

GSDVME_Texts	label	dword		; List of error text offsets
	dd	OFFSET32 MSG_GSDVME_PrivInst
	dd	OFFSET32 MSG_GSDVME_InvalInst
	dd	OFFSET32 MSG_GSDVME_InvalPgFlt
	dd	OFFSET32 MSG_GSDVME_InvalGpFlt
	dd	OFFSET32 MSG_GSDVME_InvalFlt
	dd	OFFSET32 MSG_GSDVME_UserNuke
	dd	OFFSET32 MSG_GSDVME_DevNuke
	dd	OFFSET32 MSG_GSDVME_DevNukeHdwr
	dd	OFFSET32 MSG_GSDVME_NukeNoMsg
	dd	OFFSET32 MSG_GSDVME_InsMemV86
	dd	OFFSET32 MSG_GSDVME_InsV86Space
	dd	OFFSET32 MSG_GSDVME_InsMemXMS
	dd	OFFSET32 MSG_GSDVME_InsMemEMS
	dd	OFFSET32 MSG_GSDVME_InsMemV86Hi
	dd	OFFSET32 MSG_GSDVME_InsMemVid
	dd	OFFSET32 MSG_GSDVME_InsMemVM
	dd	OFFSET32 MSG_GSDVME_InsMemDev
	dd	OFFSET32 MSG_GSDVME_CrtNoMsg

MSG_GSDVME_PrivInst	db	'Privileged instruction', 0
MSG_GSDVME_InvalInst	db	'Invalid instruction', 0
MSG_GSDVME_InvalPgFlt	db	'Invalid page fault', 0
MSG_GSDVME_InvalGpFlt	db	'Invalid GP fault', 0
MSG_GSDVME_InvalFlt	db	'Invalid fault', 0
MSG_GSDVME_UserNuke	db	'User terminated', 0
MSG_GSDVME_DevNuke	db	'VxD-specific', 0
MSG_GSDVME_DevNukeHdwr	db	'VxD-specific (hdwr)', 0
MSG_GSDVME_NukeNoMsg	db	'Suppress MSG - nuke', 0
MSG_GSDVME_InsMemV86	db	'Not enough V86 memory', 0
MSG_GSDVME_InsV86Space	db	'Not enough V86 address space', 0
MSG_GSDVME_InsMemXMS	db	'Not enough XMS memory', 0
MSG_GSDVME_InsMemEMS	db	'Not enough EMS memory', 0
MSG_GSDVME_InsMemV86Hi	db	'Not enough high DOS', 0
MSG_GSDVME_InsMemVid	db	'Not enough video memory', 0
MSG_GSDVME_InsMemVM	db	'Not enough base memory', 0
MSG_GSDVME_InsMemDev	db	'Not enough base memory for VxD', 0
MSG_GSDVME_CrtNoMsg	db	'Supress MSG', 0

	public	DispBuf
DispBuf db	(80*25) dup (?) ; Display buffer

VxD_LOCKED_DATA_ENDS			; End _LDATA segment
	page
VxD_LOCKED_CODE_SEG			; Begin _LCODE segment

	extrn	WKD_PMAPI:near
;;;;;;; extrn	U32_BLINK_LED:near

IF @DEBUGDEVID
BeginProc WKDSWAT
COMMENT|

This entry point is called early in Windows initialization,
so early that the WKD interrupts haven't been hooked up as yet.

On entry:

AL	=	0 if retail version of Windows
	=      -1 if debugging ...

|

	ret			; Return to caller

EndProc WKDSWAT 		; End WKDSWAT procedure
endif				; If @DEBUGDEVID

BeginProc LCLIRQ0
COMMENT|

Local IRQ0 handler used so that the IDT entry
has its selector that of Windows.

|

	assume	ds:nothing,es:nothing,ss:nothing ; Force CS override
	jmp	OLDIRQ0_FVEC	; Continue with next handler
	assume	ds:FLAT,es:FLAT,ss:FLAT ; Restore assumption

EndProc LCLIRQ0 		; End LCLIRQ0 procedure

BeginProc LCLIRQ1
COMMENT|

Local IRQ1 handler used so that the IDT entry
has its selector that of Windows.

|

	assume	ds:nothing,es:nothing,ss:nothing ; Force CS override
	jmp	OLDIRQ1_FVEC	; Continue with next handler
	assume	ds:FLAT,es:FLAT,ss:FLAT ; Restore assumption

EndProc LCLIRQ1 		; End LCLIRQ1 procedure

BeginProc LCLIRQ2
COMMENT|

Local IRQ2 handler used so that the IDT entry
has its selector that of Windows.

|

	assume	ds:nothing,es:nothing,ss:nothing ; Force CS override
	jmp	OLDIRQ2_FVEC	; Continue with next handler
	assume	ds:FLAT,es:FLAT,ss:FLAT ; Restore assumption

EndProc LCLIRQ2 		; End LCLIRQ2 procedure

BeginProc LCLIRQ3
COMMENT|

Local IRQ3 handler used so that the IDT entry
has its selector that of Windows.

|

	assume	ds:nothing,es:nothing,ss:nothing ; Force CS override
	jmp	OLDIRQ3_FVEC	; Continue with next handler
	assume	ds:FLAT,es:FLAT,ss:FLAT ; Restore assumption

EndProc LCLIRQ3 		; End LCLIRQ3 procedure

BeginProc LCLIRQ4
COMMENT|

Local IRQ4 handler used so that the IDT entry
has its selector that of Windows.

|

	assume	ds:nothing,es:nothing,ss:nothing ; Force CS override
	jmp	OLDIRQ4_FVEC	; Continue with next handler
	assume	ds:FLAT,es:FLAT,ss:FLAT ; Restore assumption

EndProc LCLIRQ4 		; End LCLIRQ4 procedure

BeginProc LCLIRQ5
COMMENT|

Local IRQ5 handler used so that the IDT entry
has its selector that of Windows.

|

	assume	ds:nothing,es:nothing,ss:nothing ; Force CS override
	jmp	OLDIRQ5_FVEC	; Continue with next handler
	assume	ds:FLAT,es:FLAT,ss:FLAT ; Restore assumption

EndProc LCLIRQ5 		; End LCLIRQ5 procedure

BeginProc LCLIRQ6
COMMENT|

Local IRQ0 handler used so that the IDT entry
has its selector that of Windows.

|

	assume	ds:nothing,es:nothing,ss:nothing ; Force CS override
	jmp	OLDIRQ6_FVEC	; Continue with next handler
	assume	ds:FLAT,es:FLAT,ss:FLAT ; Restore assumption

EndProc LCLIRQ6 		; End LCLIRQ6 procedure

BeginProc LCLIRQ7
COMMENT|

Local IRQ7 handler used so that the IDT entry
has its selector that of Windows.

|

	assume	ds:nothing,es:nothing,ss:nothing ; Force CS override
	jmp	OLDIRQ7_FVEC	; Continue with next handler
	assume	ds:FLAT,es:FLAT,ss:FLAT ; Restore assumption

EndProc LCLIRQ7 		; End LCLIRQ7 procedure

BeginProc SWAT_CONTROL			; Control dispatch procedure
COMMENT|

	Dispatch control messages to the correct handlers

ENTRY:
	EAX =	Device call message #

EXIT:
	Carry clear if no error

|

	cmp	eax,DEVICE_CALL_LAST ; Izit above the messages we handle?
	jae	short @F	; Don't handle it if so

	jmp	DEVICE_CALL_PROCS[eax*4] ; Handle the device call message
@@:
	clc			; Normal exit indicator

	ret			; Return to WIN386 VMM

EndProc SWAT_CONTROL		; End SWAT_CONTROL procedure

BeginProc NULL_PROC		; Dummy routine for device calls we don't handle

	clc			; Normal return indicator

	ret			; Return to WIN386

EndProc NULL_PROC		; End NULL_PROC procedure

BeginProc SWAT_PM_API		; PM API procedure
COMMENT|

	Dispatch calls to SWAT's Int 67h handler.   This will be made from
	PL3 protected mode Windows apps (like WinSwat.exe).

ENTRY:
	EBX				Current VM handle
	EBP ==> 		Client register frame

EXIT:
	CF and register returns set from Int 67h.
	NOTE: SWAT does not currently set CF in the return IRETD frame,
	but we'll return it here anyway.

|

	pushad			; Save caller's registers
	push	ds		; Save flat data segment

	cmp	SWATINT67_VEC.FOFF,0 ; Does 386SWAT.LOD support symbols?
	je	short SWAT_PM_STC ; Jump if not

	 ; Load registers for call to SWAT
	mov	ds,[ebp].Client_DS ; Get client's data selector
	assume	ds:nothing,ss:FLAT ; Tell the assembler

	mov	eax,[ebp].Client_EAX ; Load registers for call
	mov	ebx,[ebp].Client_EBX
	mov	ecx,[ebp].Client_ECX
	mov	edx,[ebp].Client_EDX
	mov	esi,[ebp].Client_ESI
	mov	edi,[ebp].Client_EDI

	pushfd			; Simulate interrupt
	cli			; ...
	call	SWATINT67_VEC	; Call SWAT's VCPI handler

	mov	[ebp].Client_EAX,eax ; Save return registers
	mov	[ebp].Client_EBX,ebx
	mov	[ebp].Client_ECX,ecx
	mov	[ebp].Client_EDX,edx
	mov	[ebp].Client_ESI,esi
	mov	[ebp].Client_EDI,edi

	jmp	short SWAT_PM_EXIT ; Join common exit (CF significant)


SWAT_PM_STC:
	stc			; Indicate failure

SWAT_PM_EXIT:
	lahf			; Get return flags
	and	ah,mask $CF ; Isolate one we're interested in returning
	and	[ebp].Client_Flags.LO,not (mask $CF)
	or		 [ebp].Client_Flags.LO,ah

	pop	ds		; Restore flat data segment
	assume	ds:FLAT,ss:nothing ; Tell the assembler

	popad			; Restore caller's registers

	ret			; Return

EndProc SWAT_PM_API			; End PM API

BeginProc V86_INT67_HOOK	; V86 Int 67h hook
COMMENT|

	Check for DEF6h API calls.  Do translation and pass 'em on
	up to SWAT.

	Calls we're interested in (rr = return code, 0 if successful):
		 AX		BX		ECX			DX		DS:ESI					EDI
	Presence check:
	In:	 DEF0	-		-			-		-						-
	Out: rr??	Maj,Min -			-		-						-

	Append/raw append:
	In:	 DEF6	??00/04 # symbols	-		==>symbols				-
	Out: rr??	????	# added 	-		?						-

	Search:
	In:	 DEF6	??01	-			-		==>pascal str			-
	Out: rr??	????	????seg 	flags	????group#				offset

	Translate:
	In:	 DEF6	??02	-			-		==>symtran				-
	Out: rr??	????	-			-		?						-

	Flush:
	In:	 DEF6	??03	-			-		-						-
	Out: rr??	????	-			-		-						-

	Command:
	In:	 DEF6	??05	-			-		==>ASCIIZ command line	-
	Out: 00??	????	-			-		?						-

	Log display:
	In:	 DEF6	??06	-			-		==>ASCIIZ string		-
	Out: 00??	????	-			-		?						-

	Use Client_Ptr_Flat <r32, DS> to get flat address of client DS,
	then add ESI.

ENTRY:
	EAX			Interrupt # (67h)
	EBX				Current VM handle
	EBP ==> 		Client register frame

EXIT:
	If a SWAT call, return CF=0 to indicate we've eaten it,
	otherwise CF=1 to pass it down the V86 chain.
	Return CF and other register returns in client structure.
	NOTE: SWAT does not currently set CF in the return IRETD frame,
	but we'll return it here anyway.

|

	pushad			; Save caller's registers

	cmp	SWATINT67_VEC.FOFF,0 ; Does 386SWAT.LOD support symbols?
	je	short V86_I67_STC ; Jump if not

	 ; Check for VCPI call
	mov	eax,[ebp].Client_EAX ; Get register values
	mov	ebx,[ebp].Client_EBX
	mov	ecx,[ebp].Client_ECX
	mov	edx,[ebp].Client_EDX
	mov	esi,[ebp].Client_ESI
	mov	edi,[ebp].Client_EDI

	cmp	ah,@VCPI ; Izit DE?
	jne	short V86_I67_STC ; Jump if not

	cmp	al,@VCPI_DPRES	; Izit DEF0?
	je		 short V86_I67_CALLSWAT ; Jump if so

	cmp	al,@VCPI_DBGSYM ; Izit DEF6?
	jne	short V86_I67_STC ; Jump if not

	 ; Handle symbol subfunctions.	@DBGSYM_FLUSH needs no translation.
	cmp	bl,@DBGSYM_FLUSH ; Izit 3?
	je		 short V86_I67_CALLSWAT ; Jump if so

	cmp	bl,@DBGSYM_LDISP ; Izit greater than 6?
	ja		 short V86_I67_STC ; Jump if so; don't know how to handle it

	 ; Translate DS:ESI to a flat offset
	Client_Ptr_Flat EAX, DS ; EAX = Client DS base
	add	esi,eax ; DS:ESI ==> linear address of client DS:ESI
	mov	eax,[ebp].Client_EAX ; Reload major service numbers

; Call appears to SWAT as coming from PM using flat selectors.
V86_I67_CALLSWAT:
	pushfd			; Simulate interrupt
	cli			; ...
	call	SWATINT67_VEC	; Call SWAT's VCPI handler

	mov	[ebp].Client_EAX,eax ; Save return EAX

; SWAT doesn't return a significant CF from API calls, but we'll do it
; here anyway in case that changes.

	lahf			; Get return flags
	and	ah,mask $CF ; Isolate one we're interested in returning
	and	[ebp].Client_Flags.LO,not (mask $CF) ; Clear in client flags
	or		 [ebp].Client_Flags.LO,ah ; Set return CF in client flags

; Since we've translated ESI, don't return it unless the API changed it.
	cmp	[ebp].Client_BL,@DBGSYM_SRCH ; Are we returning a value in SI?
	jne	short V86_I67_XSIRET ; Jump if not

	mov	[ebp].Client_SI,si ; Low word only significant on return
V86_I67_XSIRET:
	mov	[ebp].Client_EBX,ebx ; Save return registers
	mov	[ebp].Client_ECX,ecx
	mov	[ebp].Client_EDX,edx
	mov	[ebp].Client_EDI,edi

	clc			; We handled the interrupt

	jmp	short V86_I67_EXIT ; Join common exit (CF significant)


V86_I67_STC:
	stc			; Pass it on
V86_I67_EXIT:
	popad			; Restore caller's registers

	ret			; Return

EndProc V86_INT67_HOOK		; End V86 Int 67h hook

BeginProc SWAT_VM_API		; VM API procedure
COMMENT|

	Dispatch calls to SWAT's VM API handler.

ENTRY:
	EBX =			Current VM handle
	EBP ==> 		Client register frame

EXIT:
	CF and register returns set.

|

	pushad			; Save caller's registers

	and	[ebp].Client_Flags.LO,not (mask $CF) ; Assume success

	cmp	[ebp].Client_EAX.ELO,SWATVM_Get_Version ; Izit get version?
	je	short SWAT_VM_GET_VERSION ; Jump if so

	cmp	[ebp].Client_EAX.ELO,SWATVM_Out_Mono_String ; Izit string display?
	je	short SWAT_VM_OUT_MONO_STRING ; Jump if so

	or	[ebp].Client_Flags.LO,mask $CF ; Mark as failure

	jmp	short SWAT_VM_EXIT ; Join common exit (CF significant)


COMMENT|

Get version #

On entry:

AX	=	SWAT_Get_Version

On exit:

AX	=	SWAT version #
CF	=	0

|

SWAT_VM_GET_VERSION:
	mov	[ebp].Client_EAX.ELO.LO,SWAT_VERL ; Return version #
	mov	[ebp].Client_EAX.ELO.HI,SWAT_VERH ; ...

	jmp	short SWAT_VM_EXIT ; Join common exit code


COMMENT|

Output string to mono display

On entry:

AX	=	SWAT_Out_Mono_String
DS:SI	==>	ASCIIZ string to display

On exit:

CF	=	0

|

SWAT_VM_OUT_MONO_STRING:
	movzx	esi,[ebp].Client_DS ; Get the string's segment
	shl	esi,4-0 	; Convert from paras to bytes

	movzx	eax,[ebp].Client_ESI.ELO ; Get the string's offset
	add	esi,eax 	; DS:ESI ==> string to display

	VMMcall Test_Debug_Installed ; Zero flag = debugger not installed
	jz	short @F	; Skip if no debugger

	VMMcall Out_Debug_String ; Send it to the debugging monitor

	jmp	short SWAT_VM_EXIT ; Join common exit code


@@:
	call	DISPLAY 	; Put text up on debugging screen
SWAT_VM_EXIT:
	popad			; Restore caller's registers

	ret			; Return

EndProc SWAT_VM_API		; End VM API

BeginProc Lcl_Get_Cur_VM_Handle ; Start Lcl_Get_Cur_VM_Handle

	VMMcall Get_Cur_VM_Handle ; EBX = handle of current VM

	ret			; Return to caller

EndProc Lcl_Get_Cur_VM_Handle	; End Lcl_Get_Cur_VM_Handle

BeginProc Lcl_Get_Sys_VM_Handle ; Start Lcl_Get_Sys_VM_Handle

	VMMcall Get_Sys_VM_Handle

	ret			; Return to caller

EndProc Lcl_Get_Sys_VM_Handle	; End Lcl_Get_Sys_VM_Handle

VxD_LOCKED_CODE_ENDS		; End LOCKED_CODE segment


VxD_IDATA_SEG			; Begin _IDATA segment

	extrn	MSG_WKD:byte
	extrn	MSG_SCI:byte
	extrn	MSG_PDI:byte, MSG_PDI_UGH:byte
	extrn	MSG_ICP:byte
	extrn	MSG_VXDHK_NOFND:byte, MSG_VXDHK_NOFND0:byte
	extrn	MSG_NO_WINA20:byte, MSG_WINA20:byte
	extrn	MSG_ROM_BREAKPOINTS:byte
	extrn	MSG_NOSYMB:byte

	public	VH_HOOKBITS0,VH_HOOKBITS1
VH_HOOKBITS0 dd ?		; VxD Hook bitmap, bits 0-31
VH_HOOKBITS1 dd ?		; ...		       32-63

	public	PH_HOOKBITS0,PH_HOOKBITS1
PH_HOOKBITS0 dd ?		; PM Hook bitmap, bits 0-31
PH_HOOKBITS1 dd ?		; ...		      32-63

	public	LAST_EDX
LAST_EDX dd	?		; EDX returned from last GetNextProfileString

	public	STR_386SWAT,STR_PAGING,STR_REHOOK123
STR_386SWAT	db	'386SWAT', 0    ; [386SWAT] section of SYSTEM.INI
STR_PAGING	db	'Paging', 0     ; SYSTEM.INI cookie
STR_REHOOK123	db	'Rehook123', 0  ; SYSTEM.INI cookie

	public	FNREGOFF,REGLIST
FNREGOFF dd	?		; Offset into Client_Reg_Struc
REGLIST dw	'ID', 'IS', 'PB', 'PS', 'XB', 'XD', 'XC', 'XA'

	SYSINI_STRINGS SWAT,DEFINE	; List of options w/ SYSINI_xxx names

PMI_PAGE_MAP	dd	((110h/8)+3)/4 dup (0) ; Space for Get_Device_V86_Pages

	public	OLDINT20_FOFF
OLDINT20_FOFF dd 0		; Offset of old INT 20h handler

VxD_IDATA_ENDS			; End _IDATA segment

VxD_ICODE_SEG			; Begin _ICODE segment

	extrn	SETUP_MONO:near
	extrn	INIT_SYMBOLS:near
	extrn	SYMTRANS:near
	extrn	WINVARS:near
	extrn	TrapCodeWrites:near
	extrn	DeviceInit_HookInts:near

BeginProc HOOK_IRQ		; Hook IRQs If Requested
COMMENT|

Because some programs (RAM Doubler from Connectix comes to mind) in
their SysCriticalInit section check for and fail if the selector of
any of IRQ0-7 is not that of Windows, we hook those IRQs to a local
routine.

|

	test	DB2_FLAG,@DB2_HOOKIRQ ; Hook IRQ0-7 locally?
	jz	short HOOK_IRQ_EXIT ; Jump if not

	REGSAVE <eax,ebx,ecx,edx> ; Save registers

; Disable interrupts around IDT change

	pushf			; Save flags (IF in particular)
	cli			; Nobody move

	sub	esp,type DTR_STR ; Make room for IDTR
	SIDTD	[esp].EDF	; Save for a moment
	mov	ebx,[esp].DTR_BASE ; Get the IDT's base address
	add	esp,type DTR_STR ; Strip from stack

	mov	ecx,8		; # IRQs to check
	xor	edx,edx 	; Initialize table index
	add	ebx,@WINDOWS_IBV0*(type IDT_STR) ; Plus base of IRQ0
HOOK_IRQ_NEXT:
	mov	ax,SWAT_CS	; Get SWAT's CS

	cmp	ax,[ebx+edx*(type IDT_STR)].IDT_SELECT ; Izit hooked by SWAT?
	jne	short HOOK_IRQ_LOOP ; Jump if not

	mov	eax,PLCLIRQ[edx*(type PLCLIRQ)] ; Get offset of local routine
	xchg	ax,[ebx+edx*(type IDT_STR)].IDT_OFFLO ; Swap with IDT offset
	rol	eax,16		; Swap with high-order word
	xchg	ax,[ebx+edx*(type IDT_STR)].IDT_OFFHI ; Swap with IDT offset
	rol	eax,16		; Swap back
	mov	OLDIRQ0_FVEC[edx*8].FOFF,eax ; Save for later use

	mov	ax,cs		; Get selector of local routine
	xchg	ax,[ebx+edx*(type IDT_STR)].IDT_SELECT ; Swap with IDT selector
	mov	OLDIRQ0_FVEC[edx*8].FSEL,ax ; Save for later use
HOOK_IRQ_LOOP:
	inc	edx		; Skip to next IRQ

	loop	HOOK_IRQ_NEXT	; Jump if more IRQs to check

	popf			; Restore

	REGREST <edx,ecx,ebx,eax> ; Restore
HOOK_IRQ_EXIT:
	ret			; Return to caller

EndProc HOOK_IRQ		; End HOOK_IRQ procedure

BeginProc LCL_INT20		; Handler For Local INT 20h call

	call	OLDINT20_FOFF	; Call the original handler
				; Return with ECX = start of device list
	mov	DEVICE_LIST,ecx ; Save for later use

	ret			; Return to caller

EndProc LCL_INT20		; End Lcl_INT20 procedure

BeginProc SYS_CRITICAL_INIT	; Handler for Sys_Critical_Init device call
COMMENT|

Sys_Critical_Init is a device init call.  Devices that have a critical
function that needs initializing before interrupts are enabled should
do it at Sys_Critical_Init.  Devices which REQUIRE a certain range of
V86 pages to operate (such as the VDD video memory) should claim them
at Sys_Critical_Init.  SYS VM Simulate_Int, Exec_Int ACTIVITY IS NOT
ALLOWED.  Returning carry aborts device load only.

ENTRY:
	EBX =	SYS VM handle
	ESI ==> WIN.COM command tail
	EDX =	reference data (physical address of SWATINFO structure)

|

	pushad			; Save caller's registers

	mov	COMMAND_TAIL,esi ; Save pointer to WIN.COM command tail

	VMMcall Get_VMM_Version ; Get Windows VMM version #
	mov	WIN3_VERSION,ax ; Save it for later

	call	SETUP_DBGFLAGS	; Read SYSTEM.INI switches and set DBG_FLAG

	call	SETUP_SWAT	; Setup everything for SWAT and call INIT_PROT
	jc	PM_CRIT_UGH	; There's not much we can do if it failed

; Call the debugger if SYSTEM.INI cookie is set

	SWAT	DBG_FLAG,@DBG_SYSCRITICALINIT ; Call SWAT if SWATSysCriticalInit=TRUE

COMMENT|

Get the start of the device list (VxD_Desc_Block chain) by hooking and
unhooking INT 20h.

The value of ECX returned in our local INT 20h handler (after passing
the call on down) is the starting offset of the device list.  This
allows us to hook into the VxD chain at a point earlier than our own
location, and hence to place HookVxD breakpoints on any VxDs which
precede us (such as VMM) for functions above SysCriticalInit.  I found
this trick while disassembling the RAM Doubler VxD.

|

	mov	eax,20h 	; Interrupt # to hook
	mov	esi,OFFSET32 LCL_INT20 ; Get offset of local handler
	VMMcall Hook_VMM_Fault	; Hook it, return with ESI ==> old handler
	mov	OLDINT20_FOFF,esi ; Save offset of old handler
;;;;;;; mov	eax,20h 	; Interrupt # to unhook
;;;;;;; mov	esi,OLDINT20_FOFF ; Get offset of old handler
	VMMcall Hook_VMM_Fault	; Unhook it

; Trundle through the device list looking for RAM Doubler's VxD
; If we find it, set the HookIRQ flag

	mov	ecx,DEVICE_LIST ; Get ptr to start of VxD_Desc_Block strucs
PM_CRIT_NEXTDEV:
	cmp	[ecx].DDB_Name.EDQLO,'buoD' ; Izit start of "Doubler "?
	jne	short PM_CRIT_LOOPDEV ; Jump if not

	cmp	[ecx].DDB_Name.EDQHI,' rel' ; Izit end of "Doubler "?
	jne	short PM_CRIT_LOOPDEV ; Jump if not

	or	DB2_FLAG,@DB2_HOOKIRQ ; Mark as hooking IRQs

	jmp	short PM_CRIT_ENDDEV ; Join common code


PM_CRIT_LOOPDEV:
	mov	ecx,[ecx].DDB_Next ; Get next link

	and	ecx,ecx 	; Izit the end of the line?
	jnz	short PM_CRIT_NEXTDEV ; Jump if not
PM_CRIT_ENDDEV:
	call	HOOK_IRQ	; Hook IRQs if requested

	call	SETUP_TSS	; Setup TSS.CR3

	call	SETUP_DBG_INTS	; Remember INTs 01h, 02h, 03h, and 41h

	test	DB2_FLAG,@DB2_THRUXIT ; Are we using the special exit stuff?
	jz	short @F	; Skip warning display if not

	lea	esi,MSG_THRUXITWARN	; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386
@@:

; Steal Fatal_Error_Handler

	mov	eax,Fatal_Error_Handler ; Service to steal
	mov	esi,OFFSET32 LCL_FATAL_ERROR_HANDLER ; Address of replacement
	VMMcall Hook_Device_Service ; Steal the service
	mov	OLD_FATAL_ERROR_HANDLER,esi ; Save address of original handler

	jnc	short @F	; Jump around error code if it worked

; Tell 'em Hook_Device_Service of Fatal_Error_Handler failed

	mov	esi,OFFSET32 MSG_HOOK_FEH_UGH ; Offset to error msg text
	call	DISPLAY 	; Put message on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386
@@:

; Steal GetSetDetailedVMError

	mov	eax,GetSetDetailedVMError ; Service to steal
	mov	esi,OFFSET32 LCL_GetSetDetailedVMError ; Address of replacement
	VMMcall Hook_Device_Service ; Steal the service
	mov	OLD_GetSetDetailedVMError,esi ; Save address of original

	call	INIT_SYMBOLS	; Setup symbols for WIN386.EXE itself

	call	SYMTRANS	; Translate the symbols

	call	WINVARS 	; Send addresses of WIN386 internal variable

; Hook V86 Int 67h

	mov	eax,67h 	; Interrupt to steal
	mov	esi,OFFSET32 V86_INT67_HOOK ; Address of our hook procedure
	VMMcall Hook_V86_Int_Chain ; Hook Int 67h

	call	SETUP_VXDHOOKS	; Setup hooks for VxD control procs
	call	SETUP_PMHOOKS	; Setup hooks for VxD PM API entry

; As I understand WINA20.386, it was needed for Windows version 3.00 only
; and not for any later version.

	cmp	WIN3_VERSION,0300h ; Izit later than 3.00?
	ja	short @F	; Jump if so

	call	FIND_WINA20	; Trundle the device list looking for WINA20
@@:
	call	SHOW_PAGING	; Tell 'em if PAGING=FALSE
	call	SHOW_WFW	; Tell 'em if WFW devices are present

	call	CHK_BREAKPOINT	; Test state of SystemROMBreakPoint

	clc			; Normal exit indicator

	jmp	short PM_CRIT_XIT ; Rejoin common code


; Bitch if something went wrong

PM_CRIT_UGH:
	mov	esi,OFFSET32 MSG_PDI_UGH ; Offset to greeting text
	call	DISPLAY 	; Put message on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	stc			; Error return indicator

PM_CRIT_XIT:
	popad			; Restore caller's registers

	ret			; Return to Windows

EndProc SYS_CRITICAL_INIT	; End SYS_CRITICAL_INIT procedure

BeginProc SETUP_DBGFLAGS	; Set DBG_FLAG based upon SYSTEM.INI switches

	REGSAVE <eax,edx,esi,edi> ; Save caller's registers

; See if we want to override WDEB386's grabbing of INT 01h, 02h, and 03h

	sub	eax,eax 	; Assume FALSE

	lea	esi,STR_386SWAT ; ==> [386SWAT] section of SYSTEM.INI
	mov	edi,OFFSET32 STR_REHOOK123 ; ==> key name string

	VMMcall Get_Profile_Boolean ; Get TRUE/FALSE setting of option
				; Carry flag set:
				;	Entry not found or not boolean
				;	EAX = default value
				; Carry flag clear:
				;	Zero flag set:
				;		String was empty
				;	Zero flag clear:
				;		EAX = 0 if FALSE
				;		EAX = -1 if TRUE
	jc	short @F	; Skip if string is missing
	jz	short @F	; Skip if no value

	or	eax,eax 	; Did they specify REHOOK123=FALSE?
	jz	short @F	; Skip setting flag if so

	or	DB2_FLAG,@DB2_REHOOK123 ; Set it
@@:

; SWATDualDisplay - Display debugging information on monochrome screen

	mov	eax,0B0000h	; Default value
	lea	esi,STR_386SWAT ; ==> [386SWAT] section of SYSTEM.INI
	mov	edi,OFFSET32 SYSINI_DUALDISPLAY ; Pointer to option
	VMMcall Get_Profile_Hex_Int ; Return value of SWATDualDisplay= in EAX
	jc	short @F	; Carry set if SWATDualDisplay not found

	or	DB2_FLAG,@DB2_DUAL ; Set flag bit if SYSTEM.INI option is TRUE

	cmp	eax,0A0000h	; Izit lower than we allow?
	jbe	short @F	; Skip setting flag if so

	cmp	eax,0FF000h	; Izit higher than we allow?
	jae	short @F	; Skip setting flag if so

	mov	MONO_VIDBASE,eax ; Save base address for use later
@@:

SETFLAG macro	PRE,SUF

	mov	edi,OFFSET32 SYSINI_&SUF ; Pointer to option
	mov	edx,@&PRE&_&SUF ; Flag bit for option
	call	GET_SYSTEM_OPTION ; Set flag based on SYSTEM.INI option
	or	PRE&_FLAG,edx	; Set flag bit if SYSTEM.INI option is TRUE

	endm			; SETFLAG

; SWATVxDIPF - Trap Invalid Page Faults

	SETFLAG DB2,VxDIPF

; SWATVxDROM - Trap writes into VxD code segments

	SETFLAG DB2,VxDROM

; SWATPL0WP - Trap writes into Read-Only pages at PL0

	SETFLAG DB2,PL0WP

; SWATDebugThruExit - Alter control flow to allow debugging after System_Exit

	SETFLAG DB2,THRUXIT

; HookIRQ - Hook IRQ0-7 locally if SWAT hooks them

	SETFLAG DB2,HOOKIRQ

; SWATSysCriticalInit	    - Trap into SWAT in SYS_CRITICAL_INIT      (0000)

	SETFLAG DBG,SYSCRITICALINIT

; SWATDeviceInit	    - Trap into SWAT in DEVICE_INIT	       (0001)

	SETFLAG DBG,DEVICEINIT

; SWATInitComplete	    - Trap into SWAT in INIT_COMPLETE	       (0002)

	SETFLAG DBG,INITCOMPLETE

; SWATSysVMInit 	    - Trap into SWAT in SYS_VM_INIT	       (0003)

	SETFLAG DBG,SYSVMINIT

; SWATSysVMTerminate	    - Trap into SWAT in SYS_VM_TERMINATE       (0004)

	SETFLAG DBG,SYSVMTERMINATE

; SWATSystemExit	    - Trap into SWAT in SYSTEM_EXIT	       (0005)

	SETFLAG DBG,SYSTEMEXIT

; SWATSysCriticalExit	    - Trap into SWAT in SYS_CRITICAL_EXIT      (0006)

	SETFLAG DBG,SYSCRITICALEXIT

; SWATCreateVM		    - Trap into SWAT in CREATE_VM	       (0007)

	SETFLAG DBG,CREATEVM

; SWATVMCriticalInit	    - Trap into SWAT in VM_CRITICAL_INIT       (0008)

	SETFLAG DBG,VMCRITICALINIT

; SWATVMInit		    - Trap into SWAT in VM_INIT 	       (0009)

	SETFLAG DBG,VMINIT

; SWATVMTerminate	    - Trap into SWAT in VM_TERMINATE	       (000A)

	SETFLAG DBG,VMTERMINATE

; SWATVMNotExecutable	    - Trap into SWAT in VM_NOT_EXECUTEABLE     (000B)

	SETFLAG DBG,VMNOTEXECUTEABLE

; SWATDestroyVM 	    - Trap into SWAT in DESTROY_VM	       (000C)

	SETFLAG DBG,DESTROYVM

; SWATVMSuspend 	    - Trap into SWAT in VM_SUSPEND	       (000D)

	SETFLAG DBG,VMSUSPEND

; SWATVMResume		    - Trap into SWAT in VM_RESUME	       (000E)

	SETFLAG DBG,VMRESUME

; SWATSetDeviceFocus	    - Trap into SWAT in SET_DEVICE_FOCUS       (000F)

	SETFLAG DBG,SETDEVICEFOCUS

; SWATBeginMessageMode	    - Trap into SWAT in BEGIN_MESSAGE_MODE     (0010)

	SETFLAG DBG,BEGINMESSAGEMODE

; SWATEndMessageMode	    - Trap into SWAT in END_MESSAGE_MODE       (0011)

	SETFLAG DBG,ENDMESSAGEMODE

; SWATRebootProcessor	    - Trap into SWAT in REBOOT_PROCESSOR       (0012)

	SETFLAG DBG,REBOOTPROCESSOR

; SWATQueryDestroy	    - Trap into SWAT in QUERY_DESTROY	       (0013)

	SETFLAG DBG,QUERYDESTROY

; SWATDebugQuery	    - Trap into SWAT in DEBUG_QUERY	       (0014)

	SETFLAG DBG,DEBUGQUERY

; SWATBeginPMApp	    - Trap into SWAT in BEGIN_PM_APP	       (0015)

	SETFLAG DBG,BEGINPMAPP

; SWATEndPMApp		    - Trap into SWAT in END_PM_APP	       (0016)

	SETFLAG DBG,ENDPMAPP

; SWATDeviceRebootNotify    - Trap into SWAT in DEVICE_REBOOT_NOTIFY   (0017)

	SETFLAG DBG,DEVICEREBOOTNOTIFY

; SWATCritRebootNotify	    - Trap into SWAT in CRIT_REBOOT_NOTIFY     (0018)

	SETFLAG DBG,CRITREBOOTNOTIFY

; SWATCloseVMNotify	    - Trap into SWAT in CLOSE_VM_NOTIFY        (0019)

	SETFLAG DBG,CLOSEVMNOTIFY

; SWATPowerEvent	    - Trap into SWAT in POWER_EVENT	       (001A)

	SETFLAG DBG,POWEREVENT

; SWATSysDynamicDeviceInit  - Trap into SWAT in SYS_DYNAMIC_DEVICE_INIT (001B)

	SETFLAG DB3,SYSDYNAMICDEVICEINIT

; SWATSysDynamicDeviceExit  - Trap into SWAT in SYS_DYNAMIC_DEVICE_EXIT (001C)

	SETFLAG DB3,SYSDYNAMICDEVICEEXIT

; SWATCreateThread	    - Trap into SWAT in CREATE_THREAD	       (001D)

	SETFLAG DB3,CREATETHREAD

; SWATThreadInit	    - Trap into SWAT in THREAD_INIT	       (001E)

	SETFLAG DB3,THREADINIT

; SWATTerminateThread	    - Trap into SWAT in TERMINATE_THREAD       (001F)

	SETFLAG DB3,TERMINATETHREAD

; SWATThreadNotExecuteable  - Trap into SWAT in THREAD_NOT_EXECUTEABLE (0020)

	SETFLAG DB3,THREADNOTEXECUTEABLE

; SWATDestroyThread	    - Trap into SWAT in DESTROY_THREAD	       (0021)

	SETFLAG DB3,DESTROYTHREAD

; SWATPNPNewDevnode	    - Trap into SWAT in PNP_NEW_DEVNODE        (0022)

	SETFLAG DB3,PNPNEWDEVNODE

; SWATW32DeviceIOControl    - Trap into SWAT in W32_DEVICEIOCONTROL    (0023)

	SETFLAG DB3,W32DEVICEIOCONTROL

; SWATSysVMTerminate2	    - Trap into SWAT in SYS_VM_TERMINATE2      (0024)

	SETFLAG DB3,SYSVMTERMINATE2

; SWATSystemExit2	    - Trap into SWAT in SYSTEM_EXIT2	       (0025)

	SETFLAG DB3,SYSTEMEXIT2

; SWATSysCriticalExit2	    - Trap into SWAT in SYS_CRITICAL_EXIT2     (0026)

	SETFLAG DB3,SYSCRITICALEXIT2

; SWATVmTerminate2	    - Trap into SWAT in VM_TERMINATE2	       (0027)

	SETFLAG DB3,VMTERMINATE2

; SWATVmNotExecuteable2     - Trap into SWAT in VM_NOT_EXECUTEABLE2    (0028)

	SETFLAG DB3,VMNOTEXECUTEABLE2

; SWATDestroyVM2	    - Trap into SWAT in DESTROY_VM2	       (0029)

	SETFLAG DB3,DESTROYVM2

; SWATVMSuspend2	    - Trap into SWAT in VM_SUSPEND2	       (002A)

	SETFLAG DB3,VMSUSPEND2

; SWATEndMessageMode2	    - Trap into SWAT in END_MESSAGE_MODE2      (002B)

	SETFLAG DB3,ENDMESSAGEMODE2

; SWATEndPMApp2 	    - Trap into SWAT in END_PM_APP2	       (002C)

	SETFLAG DB3,ENDPMAPP2

; SWATDeviceRebootNotify2   - Trap into SWAT in DEVICE_REBOOT_NOTIFY2  (002D)

	SETFLAG DB3,DEVICEREBOOTNOTIFY2

; SWATCritRebootNotify2     - Trap into SWAT in CRIT_REBOOT_NOTIFY2    (002E)

	SETFLAG DB3,CRITREBOOTNOTIFY2

; SWATCloseVMNotify2	    - Trap into SWAT in CLOSE_VM_NOTIFY2       (002F)

	SETFLAG DB3,CLOSEVMNOTIFY2

; SWATGetContentionHandler  - Trap into SWAT in GET_CONTENTION_HANDLER (0030)

	SETFLAG DB3,GETCONTENTIONHANDLER

; SWATKernel32Initialized   - Trap into SWAT in KERNEL32_INITIALIZED   (0031)

	SETFLAG DB3,KERNEL32INITIALIZED

; SWATKernel32Shutdown	    - Trap into SWAT in KERNEL32_SHUTDOWN      (0032)

	SETFLAG DB3,KERNEL32SHUTDOWN

; Set co-requisite switches

	test	DB2_FLAG,@DB2_VxDROM ; Trapping these?
	jz	short @F	; Jump if not

	or	DB2_FLAG,@DB2_VxDIPF or @DB2_PL0WP ; Then we're also hooking this
@@:
	REGREST <edi,esi,edx,eax> ; Restore caller's registers

	ret			; Return to caller

EndProc SETUP_DBGFLAGS		; End SETUP_DBGFLAGS procedure


BeginProc STRLEN		; Calculate EAX = STRLEN(@ESI)
COMMENT|

    Get length of string at DS:ESI into EAX

ENTRY:
	DS:ESI ==> string

EXIT:
	EAX = length of input string (not including NUL)

	Assumes DS = ES

|

	REGSAVE <ecx,edi>	; Save caller's register

	mov	edi,esi 	; ES:EDI ==> string
	mov	ecx,-1		; Longest strings possible

	sub	al,al		; Terminating NUL we're looking for
  repne scasb			; Find terminating NUL

	not	ecx		; Length we scanned
	dec	ecx		; Account for NUL

	mov	eax,ecx 	; Copy length to proper register for return

	REGREST <edi,ecx>	; Restore caller's register

	ret			; Return to caller

EndProc STRLEN			; End STRLEN procedure


BeginProc SETUP_VXDHOOKS	; Setup hooks for VxD control procedures
COMMENT|

Hook into VxD control procedures based on SYSTEM.INI HOOKVXD= cookies.

|

	pushad			; Save caller's registers

	sub	eax,eax 	; A handy zero
	mov	VXDHOOKS_HEAD,eax ; Clear the list

	sub	edx,edx 	; NULL default string
	lea	esi,STR_386SWAT ; ==> [386SWAT] section of SYSTEM.INI
	mov	edi,OFFSET32 STR_HOOKVXD ; ==> "HOOKVXD"
	VMMcall Get_Profile_String ; Check SYSTEM.INI for it
				; EDX ==> string from SYSTEM.INI
	mov	LAST_EDX,edx	; Save for next time

	jc	SVH_XIT 	; Nothing to do

	jmp	short SVH_FND	; Enter middle of loop

SVH_NEXT:
	mov	edx,LAST_EDX	; Saved from last time
	sub	esi,esi 	; NULL indicates "[386Enh]"
	mov	edi,OFFSET32 STR_HOOKVXD ; ==> "HOOKVXD"
	VMMcall Get_Next_Profile_String ; Check SYSTEM.INI for it
				; EDX ==> string from SYSTEM.INI
	mov	LAST_EDX,edx	; Save for next time
	jc	SVH_XIT 	; No more entries

SVH_FND:

; Display the raw string

	mov	esi,edx 	; ==> VxD name in profile string
	mov	edi,OFFSET32 MSG_HOOKVXD0 ; ==> output area
@@:
	lodsb			; Get char from profile string
S32	stosb			; Copy to message area
	or	al,al		; Izit the terminating NULL?
	jnz	short @B	; Go back for more if not

	mov	[edi-1].LO,CR	; Replace NUL with a CR
	mov	[edi].LO,LF	; Add a linefeed
	mov	[edi+1].LO,0	; Add the terminating NUL

	mov	esi,OFFSET32 MSG_HOOKVXD ; ==> message text
	call	DISPLAY 	; Tell 'em about it
	call	WDEB_DISPLAY	; Send the message to the WDEB386

; Copy the VxD name into our holding area

	mov	edi,OFFSET32 BUF_HOOKVXD ; ==> output area
	mov	ecx,8		; Length
	mov	al,' '          ; Padding character
    rep stosb			; Fill the area with blanks

	mov	esi,edx 	; ==> VxD name in profile string
	mov	edi,OFFSET32 BUF_HOOKVXD ; ==> output area
@@:
	lodsb			; Get char from profile string

	or	al,al		; Izit the terminating NULL?
	jz	short @F	; Exit loop if so

	cmp	al,','          ; Izit the separator?
	je	short @F	; Exit loop if so

S32	stosb			; Copy to message area
	jmp	short @B	; Go back for more
@@:

; Parse the string for device call message numbers

	mov	VH_HOOKBITS0,-1 ; Set the message bitmap
	mov	VH_HOOKBITS1,-1 ; ...

; Scan the string looking for the separator

@@:
	mov	al,[edx]	; Get next character from profile string
	inc	edx		; Account for it

	or	al,al		; Izit the NULL?
	jz	short SVH_ARG_END ; Exit if so (assumption correct)

	cmp	al,','          ; Izit a separator?
	jne	short @B	; Go back for more if not

	dec	edx		; Back up so EDX ==> separator

; We've encountered arguments

	mov	VH_HOOKBITS0,0	; Clear the message bitmap
	mov	VH_HOOKBITS1,0	; ...
SVH_HOOKS_NEXT:
	mov	al,[edx]	; Get next character from profile string
	inc	edx		; Account for it

	or	al,al		; Izit the NULL?
	jz	short SVH_HOOK_END ; Exit if so

	cmp	al,','          ; Izit a separator?
	jne	short SVH_HOOKS_NEXT ; Go back for more if not

; We've hit a separator

	VMMcall Convert_Hex_String ; Get hex message code into EAX

	cmp	eax,31		; Izit in the first set?
	ja	short SVH_HOOKS1 ; Jump if not

	bts	VH_HOOKBITS0,eax ; Set appropriate bit in message bitmap

	jmp	short SVH_HOOKS_COM ; Join common code

SVH_HOOKS1:
	sub	eax,32		; Convert to origin-32

	cmp	eax,31		; Izit in the second set?
	ja	short SVH_HOOKS_NEXT ; Jump if not

	bts	VH_HOOKBITS1,eax ; Set appropriate bit in message bitmap
SVH_HOOKS_COM:
	jmp	short SVH_HOOKS_NEXT ; Go back for another

SVH_HOOK_END:

SVH_ARG_END:
	lea	esi,BUF_HOOKVXD ; ESI ==> 8-character blank-padded VxD name
	call	FIND_DEVICE	; Trundle the DeviceList for a VxD by name
				; If carry clear, EDX ==> DDB for VxD
	jc	short SVH_LOOP	; Go try another one if not found


; Allocate space for another VXDHOOK_STR structure

	REGSAVE <ecx,edx>	; Save around C call

	VMMcall _HeapAllocate <<size VXDHOOK_STR>, HeapZeroInit>

	REGREST <edx,ecx>	; Restore registers clobbered by C call

;;;;;;	 or	 eax,eax	; Did we get the space?
;;;;;;	 jnz	 FIXME		; Yes, so skip the error code

; Link into chain

	mov	edi,eax 	; Pointer to new VXDHOOKS_STR
	mov	eax,VXDHOOKS_HEAD ; Start of chain
	mov	[edi].VH_NEXT,eax ; Attach to new entry
	mov	VXDHOOKS_HEAD,edi ; New entry becomes start of chain

	mov	[edi].VH_DDB,edx ; Save ==> DDB for search and release
	mov	eax,VH_HOOKBITS0 ; Get first bitmap
	mov	[edi].VH_HOOKS0,eax ; Attach to new entry
	mov	eax,VH_HOOKBITS1 ; Get second bitmap
	mov	[edi].VH_HOOKS1,eax ; Attach to new entry

; Compile CALL LCL_CONTROL_PROC code and link into structure

	mov	[edi].VH_FIRST[0],@OPCOD_NOP	; Save as NOP to avoid
	mov	[edi].VH_FIRST[1],@OPCOD_NOP	; ...problems when
	mov	[edi].VH_FIRST[2],@OPCOD_NOP	; ...disassembling backwards
	mov	[edi].VH_NEWPROC,@OPCOD_CALLN	; Compile the NEAR CALL
	lea	eax,[edi].VH_NEXT		; Offset of next opcode
	sub	eax,OFFSET32 LCL_CONTROL_PROC	; Form relative offset
	neg	eax				; Swap SUB arguments
	mov	[edi].VH_NEWPROC1,eax		; Stuff it into CALL

	lea	eax,[edi].VH_NEWPROC ; Get offset of our Control_Proc
	xchg	eax,[edx].DDB_Control_Proc ; Swap in our Control_Proc
	mov	[edi].VH_OLDPROC,eax ; Save original Control_Proc in structure

; Copy the device name into the structure

	REGSAVE <ecx,esi,edi>	; Save registers

	mov	ecx,8		; Length to move
	mov	esi,OFFSET32 BUF_HOOKVXD ; Name we're hooking
	lea	edi,[edi].VH_NAME ; Place in structure for name

S32 rep movsb			; Copy the name into the structure

	REGREST <edi,esi,ecx>	; Restore registers

; Try for another SYSTEM.INI cookie

SVH_LOOP:
	jmp	SVH_NEXT	; Look for another HOOKVXD= string

SVH_XIT:
	popad			; Restore caller's registers

	ret			; Return to caller

EndProc SETUP_VXDHOOKS		; End SETUP_VXDHOOKS procedure

BeginProc SETUP_PMHOOKS 	; Setup hooks for device PM API entry points
COMMENT|

	Hook into VxD PM API entry points based on SYSTEM.INI HOOKPM= cookies.
	Different devices use different client registers to pass the function
	code.  For example, SHELL uses Client_DX.

	The format of the SYSTEM.INI cookie is:

	HookPM=DeviceName,FnReg,fn,fn,...

	FnReg is an uppercase, 2-character, registers name, such as DX.

|

	pushad			; Save caller's registers

	sub	eax,eax 	; A handy zero
	mov	PMHOOKS_HEAD,eax ; Clear the list

	sub	edx,edx 	; NULL default string
	lea	esi,STR_386SWAT ; ==> [386SWAT] section of SYSTEM.INI
	mov	edi,OFFSET32 STR_HOOKPM ; ==> "HOOKPM"
	VMMcall Get_Profile_String ; Check SYSTEM.INI for it
				; EDX ==> string from SYSTEM.INI
	mov	LAST_EDX,edx	; Save for next time

	jc	SPH_XIT 	; Nothing to do

	jmp	short SPH_FND	; Enter middle of loop

SPH_NEXT:
	mov	edx,LAST_EDX	; Saved from last time
	sub	esi,esi 	; NULL indicates "[386Enh]"
	mov	edi,OFFSET32 STR_HOOKPM ; ==> "HOOKPM"
	VMMcall Get_Next_Profile_String ; Check SYSTEM.INI for it
				; EDX ==> string from SYSTEM.INI
	mov	LAST_EDX,edx	; Save for next time
	jc	SPH_XIT 	; No more entries

SPH_FND:

; Display the raw string

	mov	esi,edx 	; ==> VxD name in profile string
	mov	edi,OFFSET32 MSG_HOOKPM0 ; ==> output area
@@:
	lodsb			; Get char from profile string
S32	stosb			; Copy to message area
	or	al,al		; Izit the terminating NULL?
	jnz	short @B	; Go back for more if not

	mov	[edi-1].LO,CR	; Replace NUL with a CR
	mov	[edi].LO,LF	; Add a linefeed
	mov	[edi+1].LO,0	; Add the terminating NUL

	mov	esi,OFFSET32 MSG_HOOKPM ; ==> message text
	call	DISPLAY 	; Tell 'em about it
	call	WDEB_DISPLAY	; Send the message to the WDEB386

; Copy the VxD name into our holding area

	mov	edi,OFFSET32 BUF_HOOKVXD ; ==> output area
	mov	ecx,8		; Length
	mov	al,' '          ; Padding character
    rep stosb			; Fill the area with blanks

	mov	esi,edx 	; ==> VxD name in profile string
	mov	edi,OFFSET32 BUF_HOOKVXD ; ==> output area
@@:
	lodsb			; Get char from profile string

	or	al,al		; Izit the terminating NULL?
	jz	short @F	; Exit loop if so

	cmp	al,','          ; Izit the separator?
	je	short @F	; Exit loop if so

S32	stosb			; Copy to message area
	jmp	short @B	; Go back for more
@@:

; Parse the string for the function code register name.
; Convert this name into a Client_Reg_Struc offset.

@@:
	mov	al,[edx]	; Get next character from profile string
	inc	edx		; Account for it

	or	al,al		; Izit the NULL?
	jz	near ptr SPH_ARG_END ; Exit if so (assumption correct)

	cmp	al,','          ; Izit a separator?
	jne	short @B	; Go back for more if not

; Two bytes following the comma must be a register name.

	mov	ax,[edx]	; Get two-character register name
	inc	edx		; Account for 'em
	inc	edx		; ...

	lea	edi,REGLIST	; EDI ==> list of two-character register names
	mov	ecx,8		; # of register names
  repne scasw			; Find register name in list
	jne	SPH_LOOP	; Go try another one if register name is bad
				; FIXME Complain if register is bad

	sub	ecx,(8-1)	; Convert to register list index
	neg	ecx		; ...
	shl	ecx,(2-0)	; Convert to Client_Reg_Struc offset
	mov	FNREGOFF,ecx	; Save offset

; If the next character isn't a comma, the line is hosed.

; Parse the string for device call message numbers.

	mov	PH_HOOKBITS0,-1 ; Set the message bitmap
	mov	PH_HOOKBITS1,-1 ; ...

; Scan the string looking for the separator.

@@:
	mov	al,[edx]	; Get next character from profile string
	inc	edx		; Account for it

	or	al,al		; Izit the NULL?
	jz	short SPH_ARG_END ; Exit if so (assumption correct)

	cmp	al,','          ; Izit a separator?
	jne	short @B	; Go back for more if not

	dec	edx		; Back up so EDX ==> separator

; We've encountered arguments

	mov	PH_HOOKBITS0,0	; Clear the message bitmap
	mov	PH_HOOKBITS1,0	; ...
SPH_HOOKS_NEXT:
	mov	al,[edx]	; Get next character from profile string
	inc	edx		; Account for it

	or	al,al		; Izit the NULL?
	jz	short SPH_HOOKS_END ; Exit if so

	cmp	al,','          ; Izit a separator?
	jne	short SPH_HOOKS_NEXT ; Go back for more if not

; We've hit a separator

	VMMcall Convert_Hex_String ; Get hex message code into EAX

	cmp	eax,31		; Izit in the first set?
	ja	short SPH_HOOKS1 ; Jump if not

	bts	PH_HOOKBITS0,eax ; Set appropriate bit in message bitmap

	jmp	short SPH_HOOKS_COM ; Join common code

SPH_HOOKS1:
	sub	eax,32		; Convert to origin-32

	cmp	eax,31		; Izit in the second set?
	ja	short SPH_HOOKS_NEXT ; Jump if not

	bts	PH_HOOKBITS1,eax ; Set appropriate bit in message bitmap
SPH_HOOKS_COM:
	jmp	short SPH_HOOKS_NEXT ; Go back for another

SPH_HOOKS_END:

SPH_ARG_END:
	lea	esi,BUF_HOOKVXD ; ESI ==> 8-character blank-padded VxD name
	call	FIND_DEVICE	; Trundle the DeviceList for a VxD by name
				; If carry clear, EDX ==> DDB for VxD
	jc	short SPH_LOOP	; Go try another one if not found


; Allocate space for another PMHOOK_STR structure

	REGSAVE <ecx,edx>	; Save around C call

	VMMcall _HeapAllocate <<size PMHOOK_STR>, HeapZeroInit>

	REGREST <edx,ecx>	; Restore registers clobbered by C call

;;;;;;	 or	 eax,eax	; Did we get the space?
;;;;;;	 jnz	 FIXME		; Yes, so skip the error code

; Link into chain

	mov	edi,eax 	; Pointer to new PMHOOKS_STR
	mov	eax,PMHOOKS_HEAD ; Start of chain
	mov	[edi].PH_NEXT,eax ; Attach to new entry
	mov	PMHOOKS_HEAD,edi ; New entry becomes start of chain

; Setup info fields

	mov	[edi].PH_DDB,edx	; Save ==> DDB for search and release
	mov	eax,PH_HOOKBITS0	; Get first bitmap
	mov	[edi].PH_HOOKS0,eax	; Save bitmap
	mov	eax,PH_HOOKBITS1	; Get second bitmap
	mov	[edi].PH_HOOKS1,eax	; Save bitmap

	mov	eax,FNREGOFF		; Offset into Client_Reg_Struc
	mov	[edi].PH_FNREGOFF,eax	; Save offset

; Compile CALL LCL_PM_API_PROC code and link into structure

	mov	[edi].PH_FIRST[0],@OPCOD_NOP	; Save as NOP to avoid
	mov	[edi].PH_FIRST[1],@OPCOD_NOP	; ...problems when
	mov	[edi].PH_FIRST[2],@OPCOD_NOP	; ...disassembling backwards
	mov	[edi].PH_NEWPROC,@OPCOD_CALLN	; Compile the NEAR CALL
	lea	eax,[edi].PH_NEXT		; Offset of next opcode
	sub	eax,OFFSET32 LCL_PM_API_PROC	; Form relative offset
	neg	eax				; Swap SUB arguments
	mov	[edi].PH_NEWPROC1,eax		; Stuff it into CALL

	lea	eax,[edi].PH_NEWPROC		; Offset of new PM_API_Proc
	xchg	eax,[edx].DDB_PM_API_Proc	; Swap in new PM_API_Proc
	mov	[edi].PH_OLDPROC,eax		; Save in PMHOOKS_STR

; Copy the device name into the structure

	REGSAVE <ecx,esi,edi>	; Save registers

	mov	ecx,8		; Length to move
	mov	esi,OFFSET32 BUF_HOOKVXD ; Name we're hooking
	lea	edi,[edi].PH_NAME ; Place in structure for name

S32 rep movsb			; Copy the name into the structure

	REGREST <edi,esi,ecx>	; Restore registers

; Try for another SYSTEM.INI cookie

SPH_LOOP:
	jmp	SPH_NEXT	; Look for another HOOKPM= string

SPH_XIT:
	popad			; Restore caller's registers

	ret			; Return to caller

EndProc SETUP_PMHOOKS		; End SETUP_PMHOOKS procedure

BeginProc FIND_DEVICE		; Trundle the DeviceList for a VxD by name
COMMENT|

Trundle through the WIN386 DeviceList looking for the VxD

ENTRY:
	ESI	==>	8-character blank-padded VxD name

EXIT:
	If device found:
		Carry clear
		EDX ==> DDB for VxD

	If device not found:
		Carry set
		EDX destroyed

|

	REGSAVE <eax,ecx,esi,edi> ; Save caller's registers

	mov	edx,DEVICE_LIST ; EDX ==> 1st DDB in WIN386 DeviceList
FD_NEXT_DEVICE:
	lea	edi,[edx].DDB_Name ; ==> VxDs name

	push	esi		; Save pointer to name we're looking for

	mov	ecx,8		; Length to compare

   repe cmpsb			; Compare the names

	pop	esi		; Restore pointer to name we're looking for

	je	short FD_HIT_DEVICE ; We've found the VxD, exit loop

	mov	edx,[edx].DDB_Next ; Bump to next link

	or	edx,edx 	; End of the chain?
	jnz	short FD_NEXT_DEVICE ; Try next device if not

; Couldn't find the device

FD_NOT_FOUND:
	mov	edi,OFFSET32 MSG_VXDHK_NOFND0 ; Space in error msg for name
	mov	ecx,8		; Length to copy

S32 rep movsb			; Copy the name

	mov	esi,OFFSET32 MSG_VXDHK_NOFND ; ==> message text
	call	DISPLAY 	; Tell 'em we couldn't find their VxD
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	stc			; Indicate we didn't find the VxD

	jmp	short FD_XIT	; Rejoin common exit code

; We've found the device.  ECX ==> DDB

FD_HIT_DEVICE:
	clc			; Indicate we found it

FD_XIT:
	REGREST <edi,esi,ecx,eax> ; Restore caller's registers

	ret			; Return to caller

EndProc FIND_DEVICE		; End FIND_DEVICE procedure


BeginProc FIND_WINA20		; Trundle the device list looking for WINA20

	pushad			; Save caller's registers

	mov	ecx,DEVICE_LIST ; Return to 1st DDB
FW_NEXT_DEVICE:
	lea	edi,[ecx].DDB_Name ; ==> VxDs name

	push	ecx		; Save ==> DDB
	push	esi		; Save ==> name we're looking for

	mov	ecx,8		; Length to compare
	mov	esi,OFFSET32 STR_WINA20 ; Name we're looking for

   repe cmpsb			; Compare the names

	pop	esi		; Restore ==> name we're looking for
	pop	ecx		; Restore ==> DDB

	je	short FW_HIT_DEVICE ; We've found the VxD, exit loop

	mov	ecx,[ecx].DDB_Next ; Bump to next link

	jecxz	short FW_NOT_FOUND ; Exit loop if NULL

	jmp	short FW_NEXT_DEVICE ; Go try next device

; Couldn't find the WINA20 device

FW_NOT_FOUND:
	mov	esi,OFFSET32 MSG_NO_WINA20 ; Offset to message text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	jmp	short FW_XIT	; Rejoin common code

FW_HIT_DEVICE:
	mov	esi,OFFSET32 MSG_WINA20 ; Offset to message text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386
FW_XIT:
	popad			; Restore caller's registers

	ret			; Return to caller

EndProc FIND_WINA20		; End FIND_WINA20 procedure

BeginProc SETUP_DUALDISPLAY	; Setup the monochrome debugging display

	REGSAVE <eax,ecx,esi>	; Save caller's registers

; If using the 386SWATDualDisplay=TRUE option, setup the monochrome display area

	test	DB2_FLAG,@DB2_DUAL ; Are we using the monochrome display?
	jz	short CRIT_INIT_NO_DUAL

; Put greeting on debugging screen

	call	SETUP_MONO	; Setup the debugging screen

	mov	esi,OFFSET32 MSG_SCI ; Offset to message text
	call	DISPLAY 	; Put text up on debugging screen
;;;;;;; call	WDEB_DISPLAY	; Send the message to the WDEB386
CRIT_INIT_NO_DUAL:
	REGREST <esi,ecx,eax>	; Restore caller's registers

	clc			; Normal return indicator

	ret			; Return to caller

EndProc SETUP_DUALDISPLAY	; End SETUP_DUALDISPLAY procedure

BeginProc SHOW_PAGING		; Show 'em if PAGING=FALSE
COMMENT|

	Check state of Paging= cookie in SYSTEM.INI

|

	REGSAVE <eax,esi,edi>	; Save caller's registers

	mov	eax,-1		; Assume not present or TRUE
	sub	esi,esi 	; NULL indicates [386Enh] section
	mov	edi,OFFSET32 STR_PAGING ; ==> key name string

	VMMcall Get_Profile_Boolean ; Get TRUE/FALSE setting of option
				; Carry flag set:
				;	Entry not found or not boolean
				;	EAX = default value
				; Carry flag clear:
				;	Zero flag set:
				;		String was empty
				;	Zero flag clear:
				;		EAX = 0 if FALSE
				;		EAX = -1 if TRUE

; If CY or ZR there isn't a valid Paging= cookie in SYSTEM.INI

	mov	esi,OFFSET32 MSG_PAGING_ON ; Assume it's on

	jc	short @F	; Jump if EAX = default value
	jz	short @F	; Jump if string was emtpy

	or	eax,eax 	; Izit FLASE?
	jnz	short @F	; Jump it not

	mov	esi,OFFSET32 MSG_PAGING_OFF ; It's off
@@:
	call	DISPLAY 	; Show 'em the paging on/off state
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	REGREST <edi,esi,eax>	; Restore caller's registers

	ret			; Return to caller

EndProc SHOW_PAGING		; End SHOW_PAGING procedure

BeginProc SHOW_WFW		; Tell 'em if WFW VxDs are present
COMMENT|

	Tell 'em if Windows for Workgroups VxDs are present

|

	REGSAVE <eax,esi,edi>	; Save caller's registers

	VxDcall SERVER_Get_Version	; Get WFW server device version
	or	eax,eax 		; Izit installed?
	jz	short @F		; Skip message if not

	mov	esi,OFFSET32 MSG_WFW	; Message text

	call	DISPLAY 	; Show 'em the paging on/off state
	call	WDEB_DISPLAY	; Send the message to the WDEB386
@@:
	REGREST <edi,esi,eax>	; Restore caller's registers

	ret			; Return to caller

EndProc SHOW_WFW		; End SHOW_WFW procedure

BeginProc CHK_BREAKPOINT	; Show 'em if SystemROMBreakPoint != FALSE
COMMENT|

	Check state of SystemROMBreakPoint

|

	REGSAVE <eax,edx,esi,edi> ; Save caller's registers

	sub	edx,edx 	; Clear the reference data
	mov	esi,OFFSET32 BREAKPOINT ; ==> callback procedure
	VMMcall Allocate_V86_Call_Back ; Setup a magic breakpoint

	mov	edx,eax 	; Copy CS:IP of V86 callback address
	shr	edx,16		; Shift segment to low end
	shl	edx,4		; Convert from paras to bytes
	movzx	eax,ax		; Kill the segment in the original
	add	eax,edx 	; Add to form linear address of magic breakpoint

	cmp	eax,0F0000h	; Izit in the ROM?
	jb	short @F	; Nope

	lea	esi,MSG_ROM_BREAKPOINTS ; ==> warning message text
	call	DISPLAY 	; Show 'em the paging on/off state
	call	WDEB_DISPLAY	; Send the message to the WDEB386
@@:
	REGREST <edi,esi,edx,eax> ; Restore caller's registers

	ret			; Return to caller

EndProc CHK_BREAKPOINT		; End CHK_BREAKPOINT procedure

BeginProc BREAKPOINT		; Local callback for above V86 breakpoint

	int	01h		; Call the debugger FIXME

	ret			; Return to caller

EndProc BREAKPOINT		; End BREAKPOINT procedure

BeginProc SetupDPCI
COMMENT|

Check SWATINF_LCL for @LCL_DPCI.

If found, and MONO_VIDBASE is B000:0, set to B800:0,
and change the default attribute to something pretty.

|

	REGSAVE <edx,fs>	; Save registers

	mov	fs,SWAT_DS	; Get SWAT's data selector
	assume	fs:nothing	; Tell the assembler

	mov	edx,SWATINFO_LIN ; Linear address of SWATINFO

	cmp	[edx].SWTINF_LEN,SWTINF_VER ; Izit long enough to have a ver?
	jbe	short @F	; Jump if not

	cmp	[edx].SWTINF_VER,2 ; Izit new enough to support this?
	jb	short @F	; Jump if not

	movzx	edx,[edx].SWTINF_LCL_FLAG ; ==> LCL_FLAG in SWAT's DGROUP

	test	fs:[edx].EDD,@LCL_DPCI ; Izit dual PCI VGA adapters?
	jz	short @F	; Jump if not

	mov	MONO_ATTR,@ATCFyellow or @ATCBblue or @ATChigh

	cmp	MONO_VIDBASE,0B0000h ; Izit at default value?
	jne	short @F	; Jump if not

	mov	MONO_VIDBASE,0B8000h ; Set to color screen
@@:
	REGREST <fs,edx>	; Restore
	assume	fs:nothing	; Tell the assembler about it

	ret			; Return to caller

EndProc SetupDPCI

BeginProc SETUP_SWAT		; Setup everything for SWAT and call INIT_PROT

	mov	esi,SWAT_DDB.DDB_Reference_Data ; Get address of SWATINFO
				; (Actually, seg:off of INT_67, which contains SWATINFO
				;  physical address at offset 1)

; Save segment:offset
	mov	INT67_SEGOFF,esi ; Segment:offset of our Int 67h handler

; Translate segment:offset into linear address
	ror	esi,16 ; Get segment
	movzx	edx,si ; Extend to DWORD
	shl	edx,4-0 ; Convert segment to linear address
	rol	esi,16 ; Get segment part of address
	movzx	esi,si ; Extend to DWORD
	add	edx,esi ; Linear address (if not == physical, we're screwed)
	mov	INT67_RMPHYSADDR,edx ; Save for later

; Get SWATINFO physical address
	mov	esi,[edx+1].EDD ; SWATINFO address

; Get linear address of SWATINFO (FIXME watch for page boundary crossings)

	VMMcall _MapPhysToLinear <esi, <type SWATINFO_STR>, 0>
				; EAX = linaddr of SWATINFO

	cmp	eax,-1		; Test for error return
	je	SETUP_SWAT_ERRXIT ; General failure exit

	mov	SWATINFO_LIN,eax ; Save linear address of SWATINFO

; Get physical address of SWAT's code segment from SWATINFO

	mov	esi,[eax].SWTINF_BASE ; Physical address of SWAT's PGROUP

; Make sure SWAT's memory is addressible

	VMMcall _MapPhysToLinear <esi, 4096, 0>

	cmp	eax,-1		; Test for error return
	je	SETUP_SWAT_ERRXIT ; General failure exit

	sub	ecx,ecx 	; Assume no unintialized data

; See if there's any uninitialized data

	test	[eax].MD_ATTR,@MD_VER ; Izit present?
	jz	short @F	; Jump if not

	cmp	[eax].MD_APIVER,0001h ; Izit present?
	jb	short @F	; Jump if not

	mov	ecx,[eax].MD_USIZE ; Get byte size of uninitialized data
	add	ecx,16-1	; Round up to para boundary
	and	cx,not (16-1)	; and down again
@@:
	add	ecx,[eax].MD_SIZE ; Get actual length

	push	ecx		; Save around C calls
	VMMcall _MapPhysToLinear <esi, ecx, 0> ; EAX is linear addr of SWAT
	pop	ecx		; Restore

	cmp	eax,-1		; Test for error return
	je	SETUP_SWAT_ERRXIT ; General failure exit

	mov	SWAT_CS_BASE,eax ; Save for patching

	mov	esi,eax 	; Linear address of SWAT

; See if there are valid Win386 services

	test	[esi].MD_ATTR,@MD_WKD ; Is SWAT a Windows Kernel Debugger?
;;;;;;; jz	near ptr SETUP_SWAT_XWKD ; Jump if not
	jz	short SETUP_SWAT_XWKD1 ; Jump if not

	or	DB2_FLAG,@DB2_WKD ; Mark as such

	mov	eax,Win386_Alive ; Function code to check on services
	int	Win386_Query_Int ; Request Win386 service

	cmp	ax,Win386_Q_Ack ; Izit alive?
	jne	short @F	; Jump if not

	or	DB2_FLAG,@DB2_WSVC ; Mark as present
	or	[esi].MD_ATTR,@MD_WSVC ; ...
@@:
	mov	ax,[esi].MD_IPROT.FSEL ; Get the code selector
	mov	SWAT_CS,ax	; Save for later use
	add	ax,size DESC_STR ; Skip to data selector
	mov	SWAT_DS,ax	; Save for later use

	jmp	SETUP_SWAT_WKDCOM1 ; Join common code


SETUP_SWAT_XWKD1:
	push	ecx		; Save length

	sub	edx,edx 	; Assume BYTE granularity

	cmp	ecx,1024*1024	; Izit bigger than 1 MB?
	jbe	short @F	; Skip if so

	or	dl,(mask $DTE_G) ; Convert from BYTE to PAGE granularity

	add	ecx,4096-1	; Round up to next page ...
	shr	ecx,(12-0)	; ... while converting from bytes to pages
@@:
	dec	ecx		; Convert from length to limit

; Setup 1st GDT selector

	test	[esi].MD_ATTR,@MD_USE32 ; Izit a USE32 selector?
	jz	short @F	; Jump if not

	or	dl,(mask $DTE_B) ; Set the default to USE32
@@:
;					   Base address
;					   |	Limit
;					   |	|    Type
;					   |	|    |	      Size, etc.
;					   |	|    |	      |    Flags
;					   |	|    |	      |    |
	VMMcall _BuildDescriptorDWORDs <esi, ecx, CPL0_CODE, edx, 1>
	VMMcall _Allocate_GDT_Selector <edx, eax, 0>
	pop	ecx		; Restore length

	or	eax,eax 	; Test for failure
	jz	SETUP_SWAT_ERRXIT ; Jump to general failure exit

	mov	SWAT_CS,ax	; Save 1st selector

	mov	eax,[esi].MD_DATA ; Offset to data
	sub	ecx,eax 	; Size of data
	add	eax,esi 	; Advance EAX to start of data

	sub	edx,edx 	; Assume BYTE granularity

	cmp	ecx,1024*1024	; Izit bigger than 1 MB?
	jb	short @F	; Skip if not

	or	dl,(mask $DTE_G) ; Convert from BYTE to PAGE granularity

	add	ecx,4096-1	; Round up to next page ...
	shr	ecx,(12-0)	; ... while converting from bytes to pages
@@:
	or	dl,(mask $DTE_B) ; Set the default to USE32

	dec	ecx		; Convert from length to limit

; Setup 2nd GDT selector

	VMMcall _BuildDescriptorDWORDs <eax, ecx, CPL0_DATA, edx, 1>
	VMMcall _Allocate_GDT_Selector <edx, eax, 0>

	or	eax,eax 	; Test for failure
	jz	SETUP_SWAT_ERRXIT ; Jump to general failure exit

	mov	SWAT_DS,ax	; Hold on to return selector

	sub	ax,8		; Test for consecutive selectors
	cmp	ax,SWAT_CS	; ...
	jne	SETUP_SWAT_ERRXIT ; Complain
SETUP_SWAT_WKDCOM1:
	mov	edx,SWATINFO_LIN ; Linear address of SWATINFO

; If this info struct supports it, save our CS and the address of our DDB

	mov	[edx].SWTINF_PMDBG.FSEL,0 ; Assume not valid
	mov	[edx].SWTINF_VxD_PMAPI.FSEL,0 ; ...

	cmp	[edx].SWTINF_VER,7 ; Izit new enough to support this?
	jb	short @F	; Jump if not

	mov	[edx].SWTINF_VxD_PMAPI.FSEL,cs ; Save the selector
	mov	[edx].SWTINF_VxD_PMAPI.FOFF,OFFSET32 WKD_PMAPI ; Save the offset

	mov	ax,SWAT_CS	; Get SWAT's code selector
	mov	[edx].SWTINF_PMDBG.FSEL,ax ; Save for later use
@@:
	mov	eax,[edx].SWTINF_INT67 ; ==> local INT 67h handler in SWAT
	mov	SWATINT67_VEC.FOFF,eax ; Stick in DF for CALLF

	mov	ax,SWAT_CS	; Our selector for SWAT
	mov	SWATINT67_VEC.FSEL,ax ; Stick in DF for CALLF

; Setup for calls to SWATMSG and SWATTER

	push	fs		; Save for a while

	mov	fs,SWAT_CS	; SWAT CS to address MD_STR
	mov	eax,fs:[0].MD_MSG ; Offset to SWATMSG
	mov	SWATMSG_FVEC.FOFF,eax ; Save for later use
	mov	eax,fs:[0].MD_INIT ; Offset to SWATTER
	mov	SWATTER_FVEC.FOFF,eax ; Save for later use

	pop	fs		; Done with it

	mov	ax,SWAT_CS	; Our selector for SWAT
	mov	SWATMSG_FVEC.FSEL,ax ; Stick in DF for CALLF
	mov	SWATTER_FVEC.FSEL,ax ; ...

	call	Setup4GBCR3	; Setup SWAT's 4GB and CR3 selectors
	call	SetupDPCI	; Setup for dual PCI VGA display
	call	SETUP_DUALDISPLAY ; Setup the monochrome debugging display

;;;;;;; push	12		; Pass checkpoint #
;;;;;;; call	U32_BLINK_LED	; Mark the checkpoint

; Hook various debug services

	mov	eax,Out_Debug_String ; Service to steal
	mov	esi,OFFSET32 LCL_OUT_DEBUG_STRING ; Address of replacement
	VMMcall Hook_Device_Service ; Steal the service
	mov	OLD_OUT_DEBUG_STRING,esi ; Save address of original handler
	jnc	short @F	; Jump around error code if it worked

; Tell 'em Hook_Device_Service of Out_Debug_String failed

	mov	esi,OFFSET32 MSG_HOOK_ODS_UGH ; Offset to error msg text
	call	DISPLAY 	; Put message on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386
@@:
	mov	eax,Out_Debug_Chr ; Service to steal
	mov	esi,OFFSET32 LCL_OUT_DEBUG_CHR ; Address of replacement
	VMMcall Hook_Device_Service ; Steal the service
	mov	OLD_OUT_DEBUG_CHR,esi ; Save address of original handler
;;;;;;; jnc	short @F	; Jump around error code if it worked
;;;@@:
	mov	eax,Out_Mono_String ; Service to steal
	mov	esi,OFFSET32 LCL_OUT_DEBUG_STRING ; Address of replacement
	VMMcall Hook_Device_Service ; Steal the service
	mov	OLD_OUT_MONO_STRING,esi ; Save address of original handler
;;;;;;; jnc	short @F	; Jump around error code if it worked
;;;@@:
	mov	eax,Out_Mono_Chr ; Service to steal
	mov	esi,OFFSET32 LCL_OUT_MONO_CHR ; Address of replacement
	VMMcall Hook_Device_Service ; Steal the service
	mov	OLD_OUT_MONO_CHR,esi ; Save address of original handler
;;;;;;; jnc	short @F	; Jump around error code if it worked
;;;@@:
	mov	eax,In_Debug_Chr ; Service to steal
	mov	esi,OFFSET32 LCL_IN_DEBUG_CHR ; Address of replacement
	VMMcall Hook_Device_Service ; Steal the service
	mov	OLD_IN_DEBUG_CHR,esi ; Save address of original handler
;;;;;;; jnc	short @F	; Jump around error code if it worked
;;;@@:

; If this is Win95 or later, hook two additional device services

	cmp	WIN3_VERSION,0400h ; Izit Win95 or later?
	jb	short @F	; Jump if not

	mov	eax,_Debug_Out_Service ; Service to steal
	mov	esi,OFFSET32 LCL_DEBUG_OUT_SERVICE ; Address of replacement
	VMMcall Hook_Device_Service ; Steal the service
	mov	OLD_DEBUG_OUT_SERVICE,esi ; Save address of original handler
;;;;;;; jnc	short @F	; Jump around error code if it worked
;;;@@:
	mov	eax,_Trace_Out_Service ; Service to steal
	mov	esi,OFFSET32 LCL_DEBUG_OUT_SERVICE ; Address of replacement
	VMMcall Hook_Device_Service ; Steal the service
	mov	OLD_TRACE_OUT_SERVICE,esi ; Save address of original handler
;;;;;;; jnc	short @F	; Jump around error code if it worked
@@:
	test	DB2_FLAG,@DB2_WKD ; Are we a WKD?
	jz	short @F	; Jump if not

	mov	esi,OFFSET32 MSG_WKD ; Offset to message text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386
@@:

; Setup for calls to SWAT's LCL_INT67 VCPI handler

	mov	edx,SWATINFO_LIN ; Linear address of SWATINFO

	cmp	[edx].SWTINF_LEN,SWTINF_VER ; Izit long enough to have a ver?
	jbe	short SETUP_SWAT_XSYMB ; No, so there won't be any symbols

	cmp	[edx].SWTINF_VER,3 ; Izit new enough to support symbols?
	jb	short SETUP_SWAT_XSYMB ; No, so there won't be any symbols

	mov	edx,[edx].SWTINF_INT67 ; ==> local INT 67h handler in SWAT
	mov	SWATINT67_VEC.FOFF,edx ; Stick in DF for CALLF

	mov	ax,SWAT_CS	; Our selector for SWAT
	mov	SWATINT67_VEC.FSEL,ax ; Stick in DF for CALLF

	jmp	short SETUP_SWAT_XSYMB ; Rejoin common code


; Tell 'em they won't be using symbols

SETUP_SWAT_NOSYMB:
	mov	esi,OFFSET32 MSG_NOSYMB ; Offset to message text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386
SETUP_SWAT_XSYMB:

; If SWAT is a Windows Kernel Debugger, tell it to display
; its Load Segment Table

	test	DB2_FLAG,@DB2_WKD ; Izit a WKD?
	jz	short @F	; Jump if not

	mov	ax,@I41_DISPLS	; Get function code to display load segment table
	int	41h		; Request WKD service

	xor	esi,esi 	; In case it's not supported
	mov	ax,@I41_GETIPF	; Get function code to return address of
				; IPF struc table
	int	41h		; Request WKD service
				; Return with ESI ==> IPF struc table
	mov	SWAT_IPF_STR_FOFF,esi ; Save for later use

	test	DB2_FLAG,@DB2_VxDROM ; Trap writing into VxD code segments?
	jz	short @F	; Jump if not

	call	TrapCodeWrites	; Handle via subroutine
@@:
	clc			; Normal return indicator

	jmp	short SETUP_SWAT_XIT ; Join common exit code


SETUP_SWAT_ERRXIT:
	stc			; Error indicator

SETUP_SWAT_XIT:
	ret			; Return to caller

EndProc SETUP_SWAT		; End SETUP_SWAT procedure

BeginProc Setup4GBCR3

	push	fs		; Save
	mov	fs,SWAT_DS	; SWAT's DS

	mov	ax,fs:[0].FOLD_4GB ; Get SWAT's previous selector
	mov	VXD_FILE_4GB,ax ; Save original value locally
	mov	ax,fs:[0].FOLD_CR3 ; Get SWAT's previous selector
	mov	VXD_FILE_CR3,ax ; Save original value locally

	pop	fs		; Restore

; We don't need a 3rd selector anymore, but 386MAX expects to allocate
; selectors in pairs, so if we don't allocate a 3rd selector, 386MAX fails.

; Even though WKD has already setup its code, data, and CR3 selectors,
; we still need to allocate a dummy selector so that when 386MAX.VXD
; loads it gets pairs of consecutive selectors.

;					   Base address
;					   |	Limit
;					   |	|    Type
;					   |	|    |	      Size, etc.
;					   |	|    |	      |    Flags
;					   |	|    |	      |    |
	VMMcall _BuildDescriptorDWORDs <  0,	0, CPL0_DATA,	0, 1>
	VMMcall _Allocate_GDT_Selector <edx, eax, 0>

	test	DB2_FLAG,@DB2_WKD ; Are we a Windows Kernel Debugger?
	jnz	near ptr Setup4GBCR3Exit ; Jump if so

; Setup IMR base in SWATINI MD_STR

	mov	esi,SWAT_CS_BASE ; Linear address of SWAT

	mov	al,@WINDOWS_IBV0 ; Update IBV0 in SWAT
	xchg	al,[esi].MD_IBV0 ; Get SWAT's idea of IBV0
	mov	IBV0,al 	; Save it locally

; Tell SWAT it's running under Windows

	or	[esi].MD_ATTR,@MD_WIN3 ; Indicate running under Windows

; Adjust 4GB selector in COMMON

	push	fs		; Save
	mov	fs,SWAT_DS	; SWAT's DS

	mov	ax,es		; Get Windows' all-memory selector
	xchg	ax,fs:[0].FILE_4GB ; Swap with SWAT's current selector
	mov	VXD_FILE_4GB,ax ; Save original value locally

	pop	fs		; Restore

; Adjust CR3 selector in COMMON

	mov	eax,cr3 	; Get physical base of page directory

	VMMcall _MapPhysToLinear <eax, 4096, 0>

	cmp	eax,-1		; Test for error return
	je	SETUP_SWAT_ERRXIT ; General failure exit

	VMMcall _BuildDescriptorDWORDs <eax, 4095, CPL0_DATA, 0, 1>
	VMMcall _Allocate_GDT_Selector <edx, eax, 0>

	or	eax,eax 	; Test for failure
	jz	SETUP_SWAT_ERRXIT ; Jump to general failure exit

	push	fs		; Save
	mov	fs,SWAT_DS	; SWAT's DS

	xchg	ax,fs:[0].FILE_CR3 ; Swap with SWAT's current selector
	mov	VXD_FILE_CR3,ax ; Save original value locally

	pop	fs		; Restore

; Call SWAT's PM initialization procedure

	push	fs		; Save for a while

	mov	fs,SWAT_CS	; SWAT CS to address MD_STR
	mov	eax,fs:[0].MD_IPROT.EDD ; Offset to INIT_PROT

	pop	fs		; Done with it

	mov	INIT_PROT_VEC.FOFF,eax ; Stick in DF for CALLF

	mov	ax,SWAT_CS	; Our selector for SWAT
	mov	INIT_PROT_VEC.FSEL,ax ; Stick in DF for CALLF

	call	INIT_PROT_VEC	; Call 386SWAT's INIT_PROT
Setup4GBCR3Exit:
	ret			; Return to caller

EndProc Setup4GBCR3

BeginProc SETUP_TSS		; Setup TSS.CR3
COMMENT|

	Fill in TSS_CR3

|

	sub	esp,size DTR_STR ; Make room for GDTR
	sgdt	[esp].EDF	; Get GDTR
	mov	eax,[esp].DTR_BASE ; Get GDT base
	add	esp,size DTR_STR ; Strip from stack

	str	bx		; Get task register
	and	bx,not (mask $PL) ; Kill priviledge bits
	movzx	ebx,bx		; Clear high-order half
	add	ebx,eax 	; Index of TSS in GDT

	mov	eax,[ebx].DESC_BASE01.EDD ; Get bytes 0-2
	shl	eax,8		; Make room for byte 3
	mov	al,[ebx].DESC_BASE3 ; Get byte 3
	ror	eax,8		; Rotate back to normal order

	mov	ebx,cr3 	; Get physical base of page directory
	mov	[eax].TSS_CR3,ebx ; Stick current CR3 into TSS

	ret			; Return to caller

EndProc SETUP_TSS		; End SETUP_TSS procedure

BeginProc SETUP_DBG_INTS	; Remember INT 1, 2, and 3

	REGSAVE <eax,ebx,ecx,edx> ; Save caller's registers

; Read interrupt vectors 01h, 02h, 03h, and 41h from the IDT
; Make them the default for Windows

	sub	esp,size DTR_STR ; Make room for IDTR
	sidt	[esp].EDF	; Get IDTR
	mov	ebx,[esp].DTR_BASE ; Get IDT base
	add	esp,size DTR_STR ; Strip from stack

SETINT_MAC macro NN

	mov	cx,[ebx+(NN&h*size IDT_STR)].IDT_SELECT ; Get selector
	mov	dx,[ebx+(NN&h*size IDT_STR)].IDT_OFFHI ; Get high order offset
	shl	edx,16		; Move to proper end of register
	mov	dx,[ebx+(NN&h*size IDT_STR)].IDT_OFFLO ; Get low end

	mov	eax,NN&h	; Interrupt #
	VMMcall Set_PM_Int_Vector ; Make this the default for all VMs

	mov	eax,NN&h	; Interrupt #
	mov	edx,1		; Interrupt gate rather than task gate
	VMMcall Set_PM_Int_Type ; Make this the default type for all VMs

	mov	eax,[ebx+(NN&h*size IDT_STR)].EDQLO ; Copy IDT entry for INT NN&h
	mov	INT&NN&_IDTENT.EDQLO,eax  ; ...
	mov	eax,[ebx+(NN&h*size IDT_STR)].EDQHI ; ...
	mov	INT&NN&_IDTENT.EDQHI,eax  ; ...

	endm			; SETINT_MAC

	SETINT_MAC 01		; Set INT 01h
	SETINT_MAC 02		; ...	  02h
	SETINT_MAC 03		; ...	  03h

	test	DB2_FLAG,@DB2_WKD ; Are we a Windows Kernel Debugger?
	jz	short @F	; Jump if not

	SETINT_MAC 41		; Set INT 41h
@@:
	REGREST <edx,ecx,ebx,eax> ; Restore caller's registers

	clc			; Normal return indicator

	ret			; Return to caller

EndProc SETUP_DBG_INTS		; End SETUP_DBG_INTS procedure

BeginProc DEVICE_INIT		; Handler for Device_Init device call
COMMENT|

Device init is where most devices do the bulk of their initialization.
SYS VM Simulate_Int, Exec_Int activity is allowed.  Returning carry
aborts device load only.

ENTRY:
	EBX	=	SYS VM's handle

EXIT:
	Carry clear if no error

ASSUMES:
	Interrupts have been (and still are) disabled.

|

	pushad			; Don't wreck registers for the next VxD

	call	DeviceInit_HookInts ; Hook interrupts locally to send to SWAT

; Print greeting

	mov	esi,OFFSET32 MSG_PDI ; Offset to greeting text
	call	DISPLAY 	; Put message on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	call	SETUP_PAD5	; Install the Ctrl+Alt+Pad5 hotkey

	SWAT	DBG_FLAG,@DBG_DEVICEINIT ; Call SWAT if SWATDeviceInit=TRUE

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc DEVICE_INIT		; End DEVICE_INIT procedure

BeginProc SETUP_PAD5		; Install the Ctrl+Alt+Pad5 hotkey
COMMENT|

Install the Ctrl+Alt+Pad5 hotkey via the VKD

|

	pushad			; Save caller's registers

	mov	al,@SSC_PAD5	; Scan code for Pad 5 key
	mov	ah,0		; Normal code
	ShiftState <SS_Ctrl+SS_Alt+SS_Toggle_mask>,<SS_LCtrl+SS_LAlt>

	mov	cl,CallOnComplete ; Callback when hot key is complete
	sub	edi,edi 	; 0 delay time

	sub	edx,edx 	; Reference data for callback
	mov	esi,OFFSET32 PAD5_HOTKEY_CB ; Address of our callback routine
	VxDcall VKD_Define_Hot_Key ; Setup the hot key

;;;;;;	 mov	 HOTKEY_HANDLE,eax ; Save handle

	mov	al,@SSC_PAD5	; Scan code for Pad 5 key
	mov	ah,0		; Normal code
	ShiftState <SS_Ctrl+SS_Alt+SS_Toggle_mask>,<SS_RCtrl+SS_RAlt>

	mov	cl,CallOnComplete ; Callback when hot key is complete
	sub	edi,edi 	; 0 delay time

	sub	edx,edx 	; Reference data for callback
	mov	esi,OFFSET32 PAD5_HOTKEY_CB ; Address of our callback routine
	VxDcall VKD_Define_Hot_Key ; Setup the hot key

;;;;;;	 mov	 HOTKEY_HANDLE,eax ; Save handle

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc SETUP_PAD5		; End SETUP_PAD5 procedure

BeginProc INIT_COMPLETE 	; Handler for Init_Complete device call
COMMENT|

Init_Complete is the final phase of device init called just before the
WIN386 INIT pages are released and the Instance snapshot is taken.
Devices which wish to search for a region of V86 pages >= A0h to use
should do it at Init_Complete.
SYS VM Simulate_Int, Exec_Int activity is allowed. Returning carry
aborts device load only.

|

	SWAT	DBG_FLAG,@DBG_INITCOMPLETE ; Call SWAT if SWATInitComplete=TRUE

	pushad			; Don't wreck registers for the next VxD

	mov	esi,OFFSET32 MSG_ICP ; Offset to greeting text
	call	DISPLAY 	; Put message on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

; Get and inspect the Device_V86_Pages_Array
; *FIXME* -- for debugging Win95 crash (failure to allocate 8D & 8E pages)

	mov	eax,OFFSET32 PMI_PAGE_MAP ; Get pointer to bit map buffer
	VMMcall _Get_Device_V86_Pages_Array <0, eax, 0> ; Global

	popad			; Restore caller's registers

	clc			; Clear error return indicator

	ret			; Return to Windows

EndProc INIT_COMPLETE		; End INIT_COMPLETE procedure

VxD_ICODE_ENDS			; End _ICODE segment


VxD_CODE_SEG			; Begin _LCODE segment

	extrn	DISPLAY:near
	extrn	WDEB_DISPLAY:near
	extrn	TOHEX:near

BeginProc LCL_CONTROL_PROC	; Control_Proc for hooked VxDs
COMMENT|

	This Control_Proc gets linked into the WIN386 Device_List DDB entry
	for any VxD that is hooked via the HOOKVXD= SYSTEM.INI cookie.

	Control actually is diverted to the code compiled into the VXDHOOK_STR.
	There we call this routine.

	Save this VxD's name so we can refer to it later as the last VxD
	that we saw called.

	We check the VXDHOOKS chain to see if we've hooked this particular
	VxD.  If we have, we check the device call message bitmap for this
	message.  If we're hooking it, call SWATMSG and then INT 1.

	Otherwise, simply chain on to the original Control_Proc.

Entry:
	EAX =	device call message #
	SS:ESP ==> VXDHOOK_STR.VH_NEXT

|

	pop	LCL_VXDHOOK_STR ; Save return address which points
				; to VXDHOOK_STR.VH_NEXT
	pushad			; Save caller's registers

	mov	edx,LCL_VXDHOOK_STR ; Get offset of the corresponding VXDHOOK_STR
	sub	edx,VH_NEXT - VH_FIRST ; Convert to proper origin

; EDX ==> VXDHOOK_STR

; Copy the name to our holding area

	REGSAVE <eax>		; Save device call message #

	lea	esi,[edx].VH_NAME ; Offset of target VxD's name
	mov	edi,OFFSET32 BUF_LASTVXD ; ==> holding area for name
	mov	ecx,8		; Maximum name length
@@:
	lodsb			; Get character from target VxD's name
	cmp	al,' '          ; Izit a padding blank?
	je	short @F	; Yes, exit loop

S32	stosb			; Store in message

	loop	short @B	; Get 'em all
@@:
	sub	al,al		; Get a NUL
S32	stosb			; Terminate the name

	REGREST <eax>		; Restore message number

; Check bitmap to see if we want to stop in this VxD

	cmp	eax,31		; Izit in the first set?
	ja	short @F	; Jump if not

	bt	[edx].VH_HOOKS0,eax ; Check message # in hook bitmap
	jnc	short LCP_NOT_HOOKED ; Skip if not hooked

	jmp	short LCP_HOOK_COM ; Join common code

@@:
	sub	eax,32		; Convert to origin-32

	cmp	eax,31		; Izit in the second set?
	ja	short LCP_NOT_HOOKED ; Jump if not

	bt	[edx].VH_HOOKS1,eax ; Check message # in hook bitmap
	jnc	short LCP_NOT_HOOKED ; Skip if not hooked

	add	eax,32		; Convert to origin-0
LCP_HOOK_COM:

; We've hooked the target VxD in this device call message

	push	eax		; Save device call message #

	lea	esi,[edx].VH_NAME ; Offset of target VxD's name
	mov	edi,OFFSET32 BUF_HOOKVXD ; ==> message workspace
	mov	ecx,8		; Maximum name length
@@:
	lodsb			; Get character from target VxD's name
	cmp	al,' '          ; Izit a padding blank?
	je	short @F	; Yes, exit loop

S32	stosb			; Store in message

	loop	short @B	; Get 'em all
@@:
	mov	al,' '          ; Get a blank
S32	stosb			; Stick into message

	mov	al,'('          ; Get an opening paren
S32	stosb			; Stick into message

	pop	eax		; Restore device call message #
	mov	ecx,2		; Number of digits
	call	TOHEX		; Format device call message # into message

	mov	al,')'          ; Get the closing paren
S32	stosb			; Stick into message

	sub	al,al		; A handy zero
S32	stosb			; NULL terminate the message

	push	dword ptr 0	; Dummy error code
	push	ds		; Selector of message text
	mov	eax,OFFSET32 BUF_HOOKVXD ; ==> workspace
	push	eax		; Pass to SWATMSG
	call	SWATMSG_FVEC	; Call SWATMSG

	mov	eax,[edx].VH_OLDPROC ; Get target VxD's original Control_Proc
	mov	OLD_Control_Proc,eax	; Save

	popad			; Restore caller's registers

	pushfd			; Get the flags onto the stack
	or	[esp].ELO,mask $TF ; Set trap bit
	popfd			; Cause a debug trap after the CALLN

	jmp	OLD_Control_Proc	; Rejoin VxD's original Control_Proc

LCP_NOT_HOOKED:
	mov	eax,[edx].VH_OLDPROC ; Get target VxD's original Control_Proc
	mov	OLD_Control_Proc,eax	; Save

	popad			; Restore caller's registers

	jmp	OLD_Control_Proc	; Rejoin VxD's original Control_Proc

EndProc LCL_CONTROL_PROC	; End LCL_CONTROL_PROC procedure

BeginProc LCL_PM_API_PROC	; PM_API_Proc for hooked devices
COMMENT|

	This PM_API_Proc gets linked into the WIN386 Device_List DDB entry
	for any VxD that is hooked via the HOOKPM= SYSTEM.INI cookie.

	Control actually is diverted to the code compiled into the PMHOOK_STR.
	There we call this routine.

	Save this VxD's name so we can refer to it later as the last VxD
	that we saw called.

	We check the PMHOOKS chain to see if we've hooked this particular
	VxD.  If we have, we check the device call message bitmap for this
	message.  If we're hooking it, call SWATMSG and then INT 1.

	Otherwise, simply chain on to the original PM_API_Proc.

Entry:
	SS:ESP ==> PMHOOK_STR.PH_NEXT

|

	pop	LCL_PMHOOK_STR	; Save return address which points
				; inside the corresponding VXDHOOK_STR
	pushad			; Save caller's registers

	mov	edx,LCL_PMHOOK_STR ; Get offset of the corresponding PMHOOK_STR
	sub	edx,PH_NEXT - PH_FIRST ; Convert to proper origin

; EDX ==> PMHOOK_STR

; Copy the name to our holding area

	lea	esi,[edx].PH_NAME ; Offset of target VxD's name
	mov	edi,OFFSET32 BUF_LASTVXD ; ==> holding area for name
	mov	ecx,8		; Maximum name length
@@:
	lodsb			; Get character from target VxD's name
	cmp	al,' '          ; Izit a padding blank?
	je	short @F	; Yes, exit loop

S32	stosb			; Store in message

	loop	short @B	; Get 'em all
@@:
	sub	al,al		; Get a NUL
S32	stosb			; Terminate the name

; Check bitmap to see if we want to stop in this VxD

	mov	eax,[edx].PH_FNREGOFF	; Offset into Client_Reg_Struc
	mov	eax,[ebp+eax]		; Function from client registers

	cmp	eax,31			; Izit in the first set?
	ja	short @F		; Jump if not

	bt	[edx].PH_HOOKS0,eax	; Check message # in hook bitmap
	jnc	short LPP_NOT_HOOKED	; Skip if not hooked

	jmp	short LPP_HOOK_COM	; Join common code

@@:
	sub	eax,32		; Convert to origin-32

	cmp	eax,31		; Izit in the second set?
	ja	short LPP_NOT_HOOKED ; Jump if not

	bt	[edx].PH_HOOKS1,eax	; Check message # in hook bitmap
	jnc	short LPP_NOT_HOOKED	; Skip if not hooked
LPP_HOOK_COM:

; We've hooked the target VxD in this device call message

	lea	esi,[edx].PH_NAME ; Offset of target VxD's name
	mov	edi,OFFSET32 BUF_HOOKVXD ; ==> message workspace
	mov	ecx,8		; Maximum name length
@@:
	lodsb			; Get character from target VxD's name
	cmp	al,' '          ; Izit a padding blank?
	je	short @F	; Yes, exit loop

S32	stosb			; Store in message

	loop	short @B	; Get 'em all
@@:
	mov	al,' '          ; Get a blank
S32	stosb			; Stick into message

	mov	al,'['          ; Get an opening bracket indicating PM API
S32	stosb			; Stick into message

	mov	eax,[edx].PH_FNREGOFF	; Offset into Client_Reg_Struc
	movzx	eax,[ebp+eax].ELO	; Function from client registers
	mov	ecx,2		; Number of digits
	call	TOHEX		; Format device call message # into message

	mov	al,']'          ; Get the closing bracket
S32	stosb			; Stick into message

	sub	al,al		; A handy zero
S32	stosb			; NULL terminate the message

	push	dword ptr 0	; Dummy error code
	push	ds		; Selector of message text
	mov	eax,OFFSET32 BUF_HOOKVXD ; ==> workspace
	push	eax		; Pass to SWATMSG
	call	SWATMSG_FVEC	; Call SWATMSG

	mov	eax,[edx].PH_OLDPROC ; Get target VxD's original PM_API_Proc
	mov	OLD_PM_API_Proc,eax	; Save

	popad				; Restore caller's registers

	add	esp,4			; Remove Device_ID from the stack

	pushfd				; Get the flags onto the stack
	or	[esp].ELO,mask $TF	; Set trap bit
	popfd				; Cause a debug trap after the CALLN

	jmp	OLD_PM_API_Proc 	; Rejoin VxD's original PM_API_Proc

LPP_NOT_HOOKED:
	mov	eax,[edx].PH_OLDPROC	 ; Get target VxD's original PM_API_Proc
	mov	OLD_PM_API_Proc,eax	; Save

	popad				; Restore caller's registers

	add	esp,4			; Remove Device_ID from the stack

	jmp	OLD_PM_API_Proc 	; Rejoin VxD's original PM_API_Proc

EndProc LCL_PM_API_PROC 	; End LCL_PM_API_PROC procedure
	page
BeginProc LCL_OUT_DEBUG_STRING		; Local hook for LCL_OUT_DEBUG_STRING
COMMENT|

Output debug string

On entry:

ESI	==>	ASCIIZ string to display

|

	push	esi		; Past ptr to ASCIIZ string
	call	ConvertBuf	; Convert regs from DS:ESI to local buffer

	push	esi		; Save for a moment

	lea	esi,DispBuf	; DS:ESI ==> local buffer
	call	DISPLAY 	; Call the mono display procedure

	pop	esi		; Restore

	cmp	SWATINT67_VEC.FSEL,0 ; Izit invalid?
	jne	short @F	; Jump if not

	jmp	OLD_OUT_DEBUG_STRING ; Continue with original handler

@@:
	pushad			; Save all EGP registers

	lea	esi,DispBuf	; DS:ESI ==> local buffer

	mov	ax,(@VCPI shl 8) or @VCPI_DBGSYM ; Debugger symbol functions
	mov	bl,@DBGSYM_LDISP ; Get function code for error log display

	pushfd			; Simulate interrupt
	cli			; ...
	call	SWATINT67_VEC	; Call SWAT's VCPI handler

	popad			; Restore

	ret			; Return to caller

EndProc LCL_OUT_DEBUG_STRING		; End LCL_OUT_DEBUG_STRING procedure
	page
BeginProc LowerCase			; Convert AL to lowercase
COMMENT|

Convert AL to lowercase

On entry:

AL	=	character to convert to lowercase

On exit:

AL	=	converted character

|

	cmp	al,'A'          ; Izit below lower limit?
	jb	short @F	; Jump if so

	cmp	al,'Z'          ; Izit above upper limit?
	ja	short @F	; Jump if so

	add	al,'a'-'A'      ; Convert to lowercase
@@:
	ret			; Return to caller

EndProc LowerCase			; End LowerCase procedure
	page
BeginProc LowerCaseECX			; Convert ECX to lowercase
COMMENT|

Convert ECX to lowercase

On entry:

ECX	=	contents to convert to lowercase

On exit:

ECX	=	converted contents

|

	push	eax		; Save for a moment

	mov	eax,ecx 	; Copy register

	ror	eax,8		; Rotate in another byte
	call	LowerCase	; Convert AL to lowercase

	ror	eax,8		; Rotate in another byte
	call	LowerCase	; Convert AL to lowercase

	ror	eax,8		; Rotate in another byte
	call	LowerCase	; Convert AL to lowercase

	ror	eax,8		; Rotate in another byte
	call	LowerCase	; Convert AL to lowercase

	mov	ecx,eax 	; Copy to return register

	pop	eax		; Restore

	ret			; Return to caller

EndProc LowerCaseECX		; End LowerCaseECX procedure
	page
BeginProc GetRegister
COMMENT|

Get a register value based upon text in DS:ESI.

On entry:

DS:ESI	==>	text with register name starting with '#', '?', or ':'

On exit:

CF	=	0 if successful
	=	1 if not
EAX	=	register value (zero padded as necessary)
ECX	=	register width (1, 2, 4)
ESI	==>	(updated)

|

	mov	ecx,ds:[esi-1]	; Get text including '#', '?', or ':' symbol
	shr	ecx,8		; Shift out the '#', '?', or ':' symbol
	call	LowerCaseECX	; Convert ECX to lowercase

	cmp	ecx,'xae'       ; Izit EAX?
	je	near ptr GetRegisterEAX ; Jump if so

	cmp	ecx,'xbe'       ; Izit EBX?
	je	near ptr GetRegisterEBX ; Jump if so

	cmp	ecx,'xce'       ; Izit ECX?
	je	near ptr GetRegisterECX ; Jump if so

	cmp	ecx,'xde'       ; Izit EDX?
	je	near ptr GetRegisterEDX ; Jump if so

	cmp	ecx,'ise'       ; Izit ESI?
	je	near ptr GetRegisterESI ; Jump if so

	cmp	ecx,'ide'       ; Izit EDI?
	je	near ptr GetRegisterEDI ; Jump if so

	cmp	ecx,'pbe'       ; Izit EBP?
	je	near ptr GetRegisterEBP ; Jump if so

	cmp	cx,'xa'         ; Izit AX?
	je	near ptr GetRegisterAX ; Jump if so

	cmp	cx,'xb'         ; Izit BX?
	je	near ptr GetRegisterBX ; Jump if so

	cmp	cx,'xc'         ; Izit CX?
	je	near ptr GetRegisterCX ; Jump if so

	cmp	cx,'xd'         ; Izit DX?
	je	near ptr GetRegisterDX ; Jump if so

	cmp	cx,'is'         ; Izit SI?
	je	near ptr GetRegisterSI ; Jump if so

	cmp	cx,'id'         ; Izit DI?
	je	near ptr GetRegisterDI ; Jump if so

	cmp	cx,'pb'         ; Izit BP?
	je	near ptr GetRegisterBP ; Jump if so

	cmp	cx,'la'         ; Izit AL?
	je	near ptr GetRegisterAL ; Jump if so

	cmp	cx,'ha'         ; Izit AH?
	je	near ptr GetRegisterAH ; Jump if so

	cmp	cx,'lb'         ; Izit BL?
	je	near ptr GetRegisterBL ; Jump if so

	cmp	cx,'hb'         ; Izit BH?
	je	near ptr GetRegisterBH ; Jump if so

	cmp	cx,'lc'         ; Izit CL?
	je	near ptr GetRegisterCL ; Jump if so

	cmp	cx,'hc'         ; Izit CH?
	je	near ptr GetRegisterCH ; Jump if so

	cmp	cx,'ld'         ; Izit DL?
	je	near ptr GetRegisterDL ; Jump if so

	cmp	cx,'hd'         ; Izit DH?
	je	near ptr GetRegisterDH ; Jump if so

	stc			; Mark as unsuccessful

	jmp	GetRegisterExit ; Join common exit code

GetRegisterEAX:
	mov	eax,[ebp].CBUF_PA.PUSHAD_EAX ; Get caller's register

	jmp	GetRegisterDword ; Join common code

GetRegisterEBX:
	mov	eax,[ebp].CBUF_PA.PUSHAD_EBX ; Get caller's register

	jmp	GetRegisterDword ; Join common code

GetRegisterECX:
	mov	eax,[ebp].CBUF_PA.PUSHAD_ECX ; Get caller's register

	jmp	GetRegisterDword ; Join common code

GetRegisterEDX:
	mov	eax,[ebp].CBUF_PA.PUSHAD_EDX ; Get caller's register

	jmp	GetRegisterDword ; Join common code

GetRegisterESI:
	mov	eax,[ebp].CBUF_PA.PUSHAD_ESI ; Get caller's register

	jmp	GetRegisterDword ; Join common code

GetRegisterEDI:
	mov	eax,[ebp].CBUF_PA.PUSHAD_EDI ; Get caller's register

	jmp	GetRegisterDword ; Join common code

GetRegisterEBP:
	mov	eax,[ebp].CBUF_PA.PUSHAD_EBP ; Get caller's register

	jmp	GetRegisterDword ; Join common code

GetRegisterAX:
	mov	ax,[ebp].CBUF_PA.PUSHAD_EAX.ELO ; Get caller's register

	jmp	GetRegisterWord ; Join common code

GetRegisterBX:
	mov	ax,[ebp].CBUF_PA.PUSHAD_EBX.ELO ; Get caller's register

	jmp	short GetRegisterWord ; Join common code

GetRegisterCX:
	mov	ax,[ebp].CBUF_PA.PUSHAD_ECX.ELO ; Get caller's register

	jmp	short GetRegisterWord ; Join common code

GetRegisterDX:
	mov	ax,[ebp].CBUF_PA.PUSHAD_EDX.ELO ; Get caller's register

	jmp	short GetRegisterWord ; Join common code

GetRegisterSI:
	mov	ax,[ebp].CBUF_PA.PUSHAD_ESI.ELO ; Get caller's register

	jmp	short GetRegisterWord ; Join common code

GetRegisterDI:
	mov	ax,[ebp].CBUF_PA.PUSHAD_EDI.ELO ; Get caller's register

	jmp	short GetRegisterWord ; Join common code

GetRegisterBP:
	mov	ax,[ebp].CBUF_PA.PUSHAD_EBP.ELO ; Get caller's register

	jmp	short GetRegisterWord ; Join common code

GetRegisterAL:
	mov	al,[ebp].CBUF_PA.PUSHAD_EAX.ELO.LO ; Get caller's register

	jmp	short GetRegisterByte ; Join common code

GetRegisterAH:
	mov	al,[ebp].CBUF_PA.PUSHAD_EAX.ELO.HI ; Get caller's register

	jmp	short GetRegisterByte ; Join common code

GetRegisterBL:
	mov	al,[ebp].CBUF_PA.PUSHAD_EBX.ELO.LO ; Get caller's register

	jmp	short GetRegisterByte ; Join common code

GetRegisterBH:
	mov	al,[ebp].CBUF_PA.PUSHAD_EBX.ELO.HI ; Get caller's register

	jmp	short GetRegisterByte ; Join common code

GetRegisterCL:
	mov	al,[ebp].CBUF_PA.PUSHAD_ECX.ELO.LO ; Get caller's register

	jmp	short GetRegisterByte ; Join common code

GetRegisterCH:
	mov	al,[ebp].CBUF_PA.PUSHAD_ECX.ELO.HI ; Get caller's register

	jmp	short GetRegisterByte ; Join common code

GetRegisterDL:
	mov	al,[ebp].CBUF_PA.PUSHAD_EDX.ELO.LO ; Get caller's register

	jmp	short GetRegisterByte ; Join common code

GetRegisterDH:
	mov	al,[ebp].CBUF_PA.PUSHAD_EDX.ELO.HI ; Get caller's register

	jmp	short GetRegisterByte ; Join common code

GetRegisterDword:
	mov	ecx,4		; Set register width
	add	esi,3		; Skip over Exx

	jmp	short GetRegisterDone ; Join common exit code


GetRegisterWord:
	movzx	eax,ax		; Zero to use as dword
	mov	ecx,2		; Set register width
	add	esi,2		; Skip over xx

	jmp	short GetRegisterDone ; Join common exit code


GetRegisterByte:
	movzx	eax,al		; Zero to use as dword
	mov	ecx,1		; Set register width
	add	esi,2		; Skip over xx
GetRegisterDone:
	clc			; Mark as successful
GetRegisterExit:
	ret			; Return to caller

EndProc GetRegister
	page
BeginProc ConvertBuf			; Convert buffer, substituting registers
COMMENT|

Convert buffer, substituting registers in the process

Register substitution occurs when a # symbol is encountered
followed by a register name.

TBD:

?register	prints name of label nearest the contents of register

?reg:reg	prints name of label nearest reg:reg (e.g. ?AX:EBX)

On entry:

SS:ESP	==>	ptr to string

|

CBUF_STR struc

CBUF_PA db	(type PUSHAD_STR) dup (?) ; All EGP regs
	dd	?		; Caller's EIP
CBUF_PSTR dd	?		; Ptr to ASCIIZ string

CBUF_STR ends

	pushad			; Save all EGP registers
	mov	ebp,esp 	; Address the stack

	lea	edi,DispBuf	; ES:EDI ==> local display buffer
	mov	esi,[ebp].CBUF_PSTR ; DS:ESI ==> ASCIIZ string
	cld			; String ops forwards
ConvertBufNext:
	lods	ds:[esi].LO	; Get next character

	cmp	al,0		; Izit EOL?
	je	short ConvertBufExit ; Jump if so

	cmp	al,'?'          ; Izit nearest symbol?
	je	short @F	; Jump if so

	cmp	al,'#'          ; Izit substitution time?
	jne	short ConvertBufStore ; Jump if not
@@:
	mov	dl,al		; Save symbol type
	call	GetRegister	; Parse text for register
	jc	short ConvertBufStoreDL ; Jump if not a register

	cmp	dl,'?'          ; Izit nearest symbol?
	je	short ConvertBufSym ; Jump if so

	shl	ecx,1		; (1,2,4) -> (2,4,8) = Number of digits
	call	TOHEX		; Format EAX/AX/AL into hex at DS:EDI

	jmp	ConvertBufNext	; Go around again


ConvertBufStoreDL:
	mov	al,dl		; Copy character to store
ConvertBufStore:
	stos	es:[edi].LO	; Save in local buffer

	jmp	ConvertBufNext	; Go around again


COMMENT|

Find nearest symbol to EAX, checking for ":reg" in text

On entry:

EAX	=	address

|

ConvertBufSym:
	xor	ebx,ebx 	; Assume no segment separator
	mov	ecx,eax 	; Copy for later use

	lods	ds:[esi].LO	; Get next character
	mov	dl,al		; Save separator type

	cmp	al,':'          ; Izit segment separator?
	jne	short ConvertBufSym1 ; Jump if not

	call	GetRegister	; Parse text for register
	jc	short ConvertBufSym1 ; Jump if not a register

	mov	ebx,eax 	; Copy offset

	jmp	short ConvertBufSym2 ; Join common code

ConvertBufSym1:
	dec	esi		; Back off to ':' symbol
ConvertBufSym2:

; Find the address nearest ECX:EBX













; Not found

	cmp	dl,':'          ; Wuzit a separator?
	jne	short @F	; Jump if not

	mov	eax,ecx 	; Copy segment
	mov	ecx,4		; Number of digits
	call	TOHEX		; Format AX into hex at DS:EDI

	mov	al,dl		; Copy separator
	stos	es:[edi].LO	; Save in local buffer
@@:
	mov	eax,ebx 	; Copy offset
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format EAX into hex at DS:EDI

	jmp	ConvertBufNext	; Go around again


ConvertBufExit:
	stos	es:[edi].LO	; Save in local buffer

	popad			; Restore

	ret	4		; Return to caller, popping argument

EndProc ConvertBuf			; End ConvertBuf
	page
BeginProc LCL_DEBUG_OUT_SERVICE 	; Local hook for LCL_DEBUG_OUT_SERVICE
COMMENT|

Output debug string with register substitution

On entry:

[ESP+4] ==>	ASCIIZ string to display

|

LDOS	struc

	dd	?		; Caller's EIP
LDOS_STR dd	?		; Ptr to ASCIIZ string

LDOS	ends

	push	[esp].LDOS_STR	; Pass ptr to ASCIIZ string
	call	ConvertBuf	; Convert regs from DS:ESI to local buffer

	push	esi		; Save for a moment

	lea	esi,DispBuf	; DS:ESI ==> local buffer
	call	DISPLAY 	; Call the mono display procedure

	pop	esi		; Restore

	cmp	SWATINT67_VEC.FSEL,0 ; Izit invalid?
	jne	short @F	; Jump if not

	jmp	OLD_DEBUG_OUT_SERVICE ; Continue with original handler

@@:
	pushad			; Save all EGP registers
	lea	esi,DispBuf	; DS:ESI ==> local buffer

	mov	ax,(@VCPI shl 8) or @VCPI_DBGSYM ; Debugger symbol functions
	mov	bl,@DBGSYM_LDISP ; Get function code for error log display

	pushfd			; Simulate interrupt
	cli			; ...
	call	SWATINT67_VEC	; Call SWAT's VCPI handler

	popad			; Restore

	ret	4		; Return to caller, popping argument

EndProc LCL_DEBUG_OUT_SERVICE		; End LCL_DEBUG_OUT_SERVICE procedure
	page
BeginProc LCL_OUT_DEBUG_CHR		; Local hook for LCL_OUT_DEBUG_CHR
COMMENT|

Output debug character

On entry:

AL	=	Character to display

|

	push	esi		; Save for a moment

	mov	LCL_CHR,al	; Save character
	lea	esi,LCL_CHR	; DS:ESI ==> string to display

	call	DISPLAY 	; Call the mono display procedure

	pop	esi		; Restore

	cmp	SWATINT67_VEC.FSEL,0 ; Izit invalid?
	jne	short @F	; Jump if not

	jmp	OLD_OUT_DEBUG_CHR ; Continue with original handler

@@:
	pushad			; Save all EGP registers
	lea	esi,LCL_CHR	; DS:ESI ==> string to display

	mov	ax,(@VCPI shl 8) or @VCPI_DBGSYM ; Debugger symbol functions
	mov	bl,@DBGSYM_LDISP ; Get function code for error log display

	pushfd			; Simulate interrupt
	cli			; ...
	call	SWATINT67_VEC	; Call SWAT's VCPI handler

	popad			; Restore

	ret			; Return to caller

EndProc LCL_OUT_DEBUG_CHR		; End LCL_OUT_DEBUG_CHR procedure
	page
BeginProc LCL_OUT_MONO_CHR		; Local hook for LCL_OUT_MONO_CHR
COMMENT|

Output debug character to mono screen

On entry:

If EAX	= 0,

BL	=	char to display
BH	=	attr to use

Else

AL	=	Character to display

Endif

|

	REGSAVE <ebx,esi>	; Save for a moment

	mov	LCL_CHR,al	; Save character

	and	eax,eax 	; Izit in (BH,BL)?
	jnz	short LCL_OUT_MONO_CHR1 ; Jump if not

	mov	LCL_CHR,bl	; Save character
	xchg	bh,MONO_ATTR	; ... attribute

	jmp	short LCL_OUT_MONO_CHR2

LCL_OUT_MONO_CHR1:
	mov	bh,MONO_ATTR	; Get original attribute
LCL_OUT_MONO_CHR2:
	lea	esi,LCL_CHR	; DS:ESI ==> string to display

	call	DISPLAY 	; Call the mono display procedure
	mov	MONO_ATTR,bh	; Restore

	REGREST <esi,ebx>	; Restore

	cmp	SWATINT67_VEC.FSEL,0 ; Izit invalid?
	jne	short @F	; Jump if not

	jmp	OLD_OUT_MONO_CHR ; Continue with original handler

@@:
	pushad			; Save all EGP registers
	lea	esi,LCL_CHR	; DS:ESI ==> string to display

	mov	ax,(@VCPI shl 8) or @VCPI_DBGSYM ; Debugger symbol functions
	mov	bl,@DBGSYM_LDISP ; Get function code for error log display

	pushfd			; Simulate interrupt
	cli			; ...
	call	SWATINT67_VEC	; Call SWAT's VCPI handler

	popad			; Restore

	ret			; Return to caller

EndProc LCL_OUT_MONO_CHR		; End LCL_OUT_MONO_CHR procedure
	page
BeginProc LCL_IN_DEBUG_CHR		; Local hook for LCL_IN_DEBUG_CHR
COMMENT|

Input debug character

On exit:

AL	=	Character from input
ZF	=	1 iff Esc or Ctrl-C pressed

|

; Request input from the user

	mov	ax,@I41_IN_CHAR ; Get function code for GetChar
	int	41h		; Request WKD service
				; Return with AL = response
	cmp	al,ESCAPE	; Izit an Escape?
	je	short @F	; Jump if so

	cmp	al,03h		; Izit Ctrl-C?
;;;;;;; je	short @F	; Jump if so
@@:
	ret			; Return to caller

EndProc LCL_IN_DEBUG_CHR		; End LCL_IN_DEBUG_CHR procedure
	page
BeginProc LCL_FATAL_ERROR_HANDLER	; Local hook for Fatal_Error_Handler
COMMENT|

	Replacement for WIN386's Fatal_Error_Handler

	Format a message and send it to 386SWAT.LOD.

	Stop with an INT 1.

	Continue to the original Fatal_Error_Handler if they
	continue from the INT 1.

On entry:
	ESI	==>	Message text (often NULL)

|

	pushad				; Save caller's registers

	VMMcall Get_Cur_VM_Handle ; EBX = handle of current VM

	sub	ecx,ecx 		; GET vs. SET flag
	VMMcall GetSetDetailedVMError	; ... into EAX if zero flag clear
	jz	short FATAL_ERROR_NOINFO ; Skip if no error info available

	mov	VMError,eax		; Save error code

FATAL_ERROR_NOINFO:
	mov	eax,esi 		; ==> message text
	or	eax,eax 		; Izit NULL?
	jz	short @F		; Don't format if 0

; Format pointer to message text

	mov	edi,OFFSET32 MSG_FATAL_ERROR0 ; Place to stick ASCII HEX digits
	mov	ecx,8			; Number of digits
	call	TOHEX			; Format ==> to message text

	jmp	short @@1		; Rejoin common code

; Use (NULL) for message pointer

@@:
	mov	ecx,8			; Length for move
	mov	edi,OFFSET32 MSG_FATAL_ERROR0 ; Place to stick ASCII HEX digits
	mov	esi,OFFSET32 MSG_FATAL_ERROR_NULL ; '(NULL)'
S32 rep movsb				; Copy it in

@@1:
	push	dword ptr 0		; Dummy error code
	push	ds			; Selector of message text
	push	OFFSET32 MSG_FATAL_ERROR ; Offset of ...
	call	SWATMSG_FVEC		; Call SWATMSG

	popad				; Restore caller's registers

	int	01h			; Call the debugger to have a look

	sub	eax,eax 		; Ensure EF_Hang_On_Exit flag is clear
	jmp	OLD_FATAL_ERROR_HANDLER ; Rejoin original handler

EndProc LCL_FATAL_ERROR_HANDLER 	; End LCL_FATAL_ERROR_HANDLER procedure
	page
BeginProc LCL_GetSetDetailedVMError	; Local hook for GetSetDetailedVMError
COMMENT|

	Replacement for WIN386's GetSetDetailedVMError

	Format a message and send it to 386SWAT.LOD.

	Stop with an INT 1.

	Continue to the original Fatal_Error_Handler if they
	continue from the INT 1.

On entry:
	EBX	=	VM handle or NULL if for Create_VM
	ECX	=	0 if GET
	EAX	=	Error code if ECX != 0
	EDX	=	Reference data if ECX != 0

|

	or	ecx,ecx 		; Zero indicates a GET call
	jz	LCL_GSDVME_CHAIN	; Chain to the original if a GET

	pushad				; Save caller's registers

; Get the message text for the error code

	push	eax			; Save error code

	mov	eax,ebx 		; VM handle to display register
	mov	edi,OFFSET32 MSG_GSDVME_VM ; Place to stick ASCII HEX digits
	mov	ecx,8			; Number of digits
	call	TOHEX			; Format ==> to message text

	mov	eax,[esp]		; Pick up error code
	mov	edi,OFFSET32 MSG_GSDVME_EC ; Place to stick ASCII HEX digits
	mov	ecx,8			; Number of digits
	call	TOHEX			; Format ==> to message text

	mov	eax,[esp]		; Pick up error code
	and	eax,(not GSDVME_OkNukeMask) ; Kill 'nice nuke' bit

	mov	MSG_GSDVME_TEXT,0	; NUL-terminate the message text

	lea	edi,GSDVME_Codes	; EDI ==> list of error codes
	mov	ecx,@GSDVME_Codes	; # of error codes
	cld				; Autoincrement
  repne scasd				; Find error code in list
	lea	edi,MSG_GSDVME_TEXT	; Destination for reason text
	jne	short LCL_GSDVME_XTEXT ; Skip if not text available

	sub	ecx,(@GSDVME_Codes-1)	; Convert to error code index
	neg	ecx			; ...
	mov	esi,GSDVME_Texts[ecx*4] ; Pick up reason text pointer
@@:
	lodsb				; Pick up next character of text
	stosb				; Store in message

	or	al,al			; Was it the terminating NUL?
	jnz	short @B		; Copy another char if not

	dec	edi			; Back off to terminating zero
LCL_GSDVME_XTEXT:
	mov	[edi+0].LO,CR		; Ensure properly terminated
	mov	[edi+1].LO,LF		; ...
	mov	[edi+2].LO,0		; ...

	pop	eax			; Restore error code

	lea	esi,MSG_GSDVME0 	; Offset to message text
	call	DISPLAY 		; Put text up on debugging screen
	call	WDEB_DISPLAY		; Send the message to the WDEB386

	or	eax,eax 		; Error code = 0?
	jz	short @F		; Skip SWATMSG if so

	push	dword ptr 0		; Dummy error code
	push	ds			; Selector of message text
	push	OFFSET32 MSG_GSDVME	; Offset of ...
	call	SWATMSG_FVEC		; Call SWATMSG
@@:
	popad				; Restore caller's registers

	and	eax,(not GSDVME_OkNukeMask) ; Kill 'nice nuke' bit
	or	eax,eax 		; Error code or clear?
	jz	short @F		; Skip break if clear

	cmp	eax,GSDVME_InsMemVM	; Is it the default?
	je	short @F		; Skip break if so

	cmp	eax,GSDVME_NukeNoMsg	; Is it the default?
	je	short @F		; Skip break if so

	int	1			; Call the debugger to have a look
@@:

LCL_GSDVME_CHAIN:
	jmp	OLD_GetSetDetailedVMError ; Rejoin original handler

EndProc LCL_GetSetDetailedVMError	; End LCL_GetSetDetailedVMError proc
	page
BeginProc PAD5_HOTKEY_CB	; Ctrl+Alt+Pad5 hot key handler

	REGSAVE <ecx,edx,fs>	; Save caller's registers

; Upon entry, EBP ==> client register stucture for the current VM
; This fact isn't documented, but rather determined by experiment.
; The following two lines rooted out the same ptr as EBP.

;;;;;;	 VMMcall Get_Cur_VM_Handle ; EBX = handle of current VM
;;;;;;	 mov	 edx,[ebx].CB_Client_Pointer ; EDX ==> Client register structure

	mov	fs,SWAT_DS	; Get SWAT's data selector
	assume	fs:nothing	; Tell the assembler

	mov	edx,SWATINFO_LIN ; Linear address of SWATINFO

	mov	ecx,OFFSET32 MSGBOX_TXT1 ; Assume 'SWAT is too old'

	cmp	[edx].SWTINF_LEN,SWTINF_VER ; Izit long enough to have a ver?
	jbe	short PAD5_CB_MSGBOX ; No, so show 'em the message box

	mov	ecx,OFFSET32 MSGBOX_TXT2 ; Assume SWAT's hooking INT 01h

	movzx	edx,[edx].SWTINF_LC3_FLAG ; ==> LC3_FLAG in SWAT's DGROUP
	test	fs:[edx].ELO,@LC3_STEP ; Are we trapping INT 01h?
	jnz	short PAD5_CB_POPUP ; Bring up SWAT in the client VM

; SWAT doesn't have INT 01h, hook it up and flip the LCL_FLAG bit

; If the user asks for SWAT, we'll rehook the debug interrupts and pop it up
; regardless of the REHOOK123= setting in SYSTEM.INI.

	call	RDI_SUB 		; Rehook INTs 01h, 02h, and 03h
	or	fs:[edx].ELO,@LC3_STEP ; Turn on indicator bit

	jmp	short PAD5_CB_POPUP ; Bring up SWAT in the client VM

; Tell 'em SWAT isn't hooking INT 01h

PAD5_CB_MSGBOX:
	pushad			; Save caller's registers

	VMMcall Get_Cur_VM_Handle ; EBX = handle of current VM

	mov	eax,MB_OK or MB_ICONEXCLAMATION ; Make 'em click 'OK'
	mov	edi,OFFSET32 MSGBOX_CAP ; ==> caption
	mov	esi,OFFSET32 PAD5_MSGBOX_CB ; ==> callback routine
	sub	edx,edx 	; Reference data for callback
	VxDcall SHELL_Message	; Put up a message box

	popad			; Restore caller's registers

	jmp	short PAD5_CB_XIT ; Rejoin common exit code

; Set EFLAGS.$TF in the client's flags to generate a debug trap on the
; instruction following the hotkey

PAD5_CB_POPUP:
	or	[ebp].Client_EFlags.ELO,mask $TF ; Set trap flag
PAD5_CB_XIT:
	REGREST <fs,edx,ecx>	; Restore caller's registers
	assume	fs:nothing	; Tell the assembler

	ret			; Return to caller

EndProc PAD5_HOTKEY_CB		; End PAD5_HOTKEY_CB procedure

BeginProc PAD5_MSGBOX_CB	; Message box callback for Ctrl+Alt+Pad5
COMMENT|

Callback routine from message box

Entry:
	EDX = reference data
	EAX = return code from message box

|

	ret			; Return to caller

EndProc PAD5_MSGBOX_CB		; End PAD5_MSGBOX_CB procedure

BeginProc SYS_VM_INIT		; Handler for Sys_VM_Init device call
COMMENT|

Same as VM_Init, except for SYS VM.

ENTRY:
	EBX	=	Handle of System Virtual Machine

EXIT:
	Carry clear if no error

|

	SWAT	DBG_FLAG,@DBG_SYSVMINIT ; Call SWAT if SWATSysVMInit=TRUE

	pushad			; Save all EGP registers

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	mov	eax,ebx 	; Get VMHandle into display register

	lea	edi,MSG_SVI_H1	; Place to stick ASCII HEX digits
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format VMHandle

	lea	esi,MSG_SVI	; Offset to greeting text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

; Get and display status of API mapping buffers

	VxDcall V86MMGR_Get_Mapping_Info ; Get mapping buffer info into CH, CL

	push	ecx		; Save mapping buffer numbers

	movzx	eax,ch		; Total # of mapping buffer pages
	lea	edi,MSG_MAPINFO0 ; Place to stick ASCII HEX digits
	mov	ecx,2		; # of digits
	call	TOHEX		; Format the V86 page #

	pop	ecx		; Mapping buffer numbers

	movzx	eax,cl		; Free # of mapping buffer pages
	lea	edi,MSG_MAPINFO1 ; Place to stick ASCII HEX digits
	mov	ecx,2		; # of digits
	call	TOHEX		; Format the V86 page #

	mov	esi,OFFSET32 MSG_MAPINFO ; Offset to message text
	call	DISPLAY 	; Put text up on debugging screen

	popad			; Restore all EGP registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc SYS_VM_INIT

BeginProc SYS_VM_TERMINATE	; Handler for Sys_VM_Terminate device call
COMMENT|

Same as VM_Terminate, except for SYS VM (Normal WIN386 exit ONLY, on a crash
exit this call is not made). SYS VM Simulate_Int, Exec_Int activity is
allowed.

|

	SWAT	DBG_FLAG,@DBG_SYSVMTERMINATE ; Call SWAT if SWATSysVMTerminate=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	mov	eax,ebx 	; Get VMHandle into display register

	lea	edi,MSG_SVT_H1	; Place to stick ASCII HEX digits
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format binary into ASCII HEX

	lea	esi,MSG_SVT	; Pointer to display text
	call	DISPLAY 	; Put up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc SYS_VM_TERMINATE	; End SYS_VM_TERMINATE procedure

BeginProc CREATE_VM		; Handler for Create_VM device call
COMMENT|

Create_VM creates a new VM.
EBX = VM handle of new VM. Returning Carry will fail the Create_VM.

ENTRY:
	EBX	=	Handle of VM being created

EXIT:
	Carry clear if no error

|

	SWAT	DBG_FLAG,@DBG_CREATEVM ; Call SWAT if SWATCreateVM=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	mov	eax,ebx 	; Move VMHandle into EAX for display

	lea	edi,MSG_CVM_H1	; Offset to hex display area
	mov	ecx,8		; Number of digits
	call	TOHEX		; Form ASCII HEX from EAX

	lea	esi,MSG_CVM	; ESI ==> message text
	call	DISPLAY 	; Send it to the debugging monitor
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit return indicator

	ret			; Return to Windows

EndProc CREATE_VM		; End CREATE_VM procedure

BeginProc VM_TERMINATE		; Handler for VM_Terminate device call
COMMENT|

NORMAL (First phase) of Destroy_VM. EBX = VM Handle. This occurs on normal
termination of the VM. Call cannot be failed. VM Simulate_Int, Exec_Int
activity is allowed.

ENTRY:
	EBX	=	Handle of VM being terminated

EXIT:
	Carry clear if no error

|

	SWAT	DBG_FLAG,@DBG_VMTERMINATE ; Call SWAT if SWATVMTerminate=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	mov	eax,ebx 	; Get VM handle into display register

	lea	edi,MSG_VMT_H1	; Place to stick ASCII HEX digits
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format binary into ASCII HEX

	lea	esi,MSG_VMT	; Offset to message text
	call	DISPLAY 	; Get it up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc VM_TERMINATE		; End VM_TERMINATE procedure
	page
BeginProc VM_NOT_EXECUTEABLE		; VM_Not_Executeable broadcast handler
COMMENT|

Second phase of Destroy_VM. EBX = VM Handle, EDX = Flags (see below). Note
that in the case of destroying a running VM, this is the first call made
(VM_Terminate call does not occur). Call cannot be failed. VM Simulate_Int,
Exec_Int activity is NOT allowed.

ENTRY:
	EBX=	Handle of VM being terminated
	EDX =	Flags

EXIT:
	Carry clear if no error

|

	SWAT	DBG_FLAG,@DBG_VMNOTEXECUTEABLE ; Call SWAT if SWATVMNotExecuteable=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	mov	eax,ebx 		; Get VM handle into display register

	lea	edi,MSG_VNE_H1		; Place to stuff ASCII HEX digits
	mov	ecx,8			; 8 digits
	call	TOHEX			; Form ASCII HEX digits

	sub	esi,esi 		; Assume no flags set
	and	edx,@VNEMASK		; Isolate reason flags
	jz	short @F		; Skip bit tests if no flags

	bsf	esi,edx 		; ESI = bit # of reason flag
	inc	esi			; Bump to origin 1
@@:
	mov	esi,VNE_TAB[esi*4]	; ESI ==> reason text

	lea	edi,MSG_VNE_X		; Destination for reason text
@@:
	lodsb				; Pick up next character of text
	stosb				; Store in message

	or	al,al			; Was it the terminating NUL?
	jnz	short @B		; Copy another char if not

	lea	esi,MSG_VNE		; Offset to display text
	call	DISPLAY 		; Send to debugging monitor
	call	WDEB_DISPLAY		; Send the message to WDEB386

	popad			; Restore caller's registers

	clc				; Normal exit indicator

	ret				; Return to caller

EndProc VM_NOT_EXECUTEABLE		; End VM_NOT_EXECUTEABLE procedure

BeginProc DESTROY_VM			; Handler for Destroy_VM device call
COMMENT|

Final phase of Destroy_VM. EBX = VM Handle. Note that considerable time
can elaps between the VM_Not_Executeable call and this call. Call cannot
be failed. VM Simulate_Int, Exec_Int activity is NOT allowed.

|

	SWAT	DBG_FLAG,@DBG_DESTROYVM ; Call SWAT if SWATDestroyVM=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	mov	eax,ebx 	; Copy VM handle into EAX for display

	lea	edi,MSG_DVM_H1	; Offset to hex display area
	mov	ecx,8		; Number of digits
	call	TOHEX		; Form ASCII HEX from EAX

	lea	esi,MSG_DVM	; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc DESTROY_VM		; End DESTROY_VM procedure

BeginProc SYSTEM_EXIT		; Handler for System_Exit device call
COMMENT|

System_Exit call is made when WIN386 is exiting either normally or via
a crash. INTERRUPS ARE ENABLED. Instance snapshot has been restored.
SYS VM Simulate_Int, Exec_Int ACTIVITY IS NOT ALLOWED.

|

; Rehooking the debugging interrupts here works, but causes odd lockups
; later on in Sys_Critical_Exit
;;;;;;; call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	SWAT	DBG_FLAG,@DBG_SYSTEMEXIT ; Call SWAT if SWATSystemExit=TRUE

	pushad			; Don't wreck registers for the next VxD

	lea	esi,MSG_SEX	; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	test	DB2_FLAG,@DB2_THRUXIT ; Are we using the special exit stuff?
	jz	short @F	; Skip warning display if not

	lea	esi,MSG_THRUXITWARN	; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	jmp	SE_XIT		; Rejoin common exit code

@@:
	call	UNDO_PMHOOKS	; Undo hooks for VxD PM API entry
	call	UNDO_VXDHOOKS	; Undo hooks for VxD control procs

; Call SWAT's REST_PROT procedure

	test	DB2_FLAG,@DB2_WKD ; Are we a Windows Kernel Debugger?
	jnz	short SE_XIT	; Jump if so

	push	fs		; Save for a while

	mov	fs,SWAT_CS	; SWAT CS to address MD_STR
	mov	eax,fs:[0].MD_RPROT.EDD ; Offset to REST_PROT

	pop	fs		; Done with it

	mov	REST_PROT_VEC.FOFF,eax ; Stick in DF for CALLF

	mov	ax,SWAT_CS	; Our selector for SWAT
	mov	REST_PROT_VEC.FSEL,ax	; Stick in DF for CALLF

	call	REST_PROT_VEC	; REST_PROT

; Restore IMR base in SWATINI MD_STR

	mov	esi,SWAT_CS_BASE ; Linear address of SWAT

	mov	al,IBV0 	; Get original value
	mov	[esi].MD_IBV0,al ; Update IBV0 in SWAT

; Tell SWAT it's not running under Windows

	and	[esi].MD_ATTR,not @MD_WIN3 ; Indicate not running under Windows

;;;;;;; Test for special DebugThruExit flag in SYSTEM.INI
;;;;;;
;;;;;;	 test	 DB2_FLAG,@DB2_THRUXIT ; Are we using the special exit stuff?
;;;;;;	 jz	 short SE_REST	; No, do the normal REST_PROT type stuff
;;;;;;
;;;;;;; Call SWAT's PM initialization routine with the new IBV0 setting
;;;;;;
;;;;;;	 call	 INIT_PROT_VEC	; Initialize SWAT
;;;;;;
;;;;;;	 jmp	 short SE_XIT	; Rejoin common code
;;;;;;
;;;;;;SE_REST:

; Restore 4GB selector in COMMON

	push	fs		; Save
	mov	fs,SWAT_DS	; SWAT's DS
	assume	fs:nothing	; Tell the assembler

	mov	ax,VXD_FILE_4GB ; Get value originally saved
	mov	fs:[0].FILE_4GB,ax ; Restore selector in COMMON in SWAT

	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler

; Restore CR3 selector in COMMON

	push	fs		; Save
	mov	fs,SWAT_DS	; SWAT's DS
	assume	fs:nothing	; Tell the assembler

	mov	ax,VXD_FILE_CR3 ; Get value originally saved
	mov	fs:[0].FILE_CR3,ax ; Restore selector in COMMON in SWAT

	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler
SE_XIT:
	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc SYSTEM_EXIT		; End SYSTEM_EXIT procedure

BeginProc SYS_CRITICAL_EXIT	; Handler for Sys_Critical_Exit device call
COMMENT|

Sys_Critical_Exit call is made when WIN386 is exiting either normally or via
a crash. INTERRUPS ARE DISABLED. SYS VM Simulate_Int, Exec_Int ACTIVITY
IS NOT ALLOWED.

|

	SWAT	DBG_FLAG,@DBG_SYSCRITICALEXIT ; Call SWAT if SWATSysCriticalExit=TRUE

	pushad			; Don't wreck registers for the next VxD

	mov	eax,SWATINFO_LIN ; Linear address of SWATINFO

; If this info struct supports it, clear the PMAPI address
; so the next time we don't use it before it's valid.

	cmp	[eax].SWTINF_VER,7 ; Izit new enough to support this?
	jb	short @F	; Jump if not

	mov	[eax].SWTINF_VxD_PMAPI.FSEL,0 ; Mark as no longer valid
	mov	[eax].SWTINF_VxD_PMAPI.FOFF,0 ; ...
@@:
	lea	esi,MSG_SCEX		; Offset to display text
	call	DISPLAY 		; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Clear error return indicator

	ret			; Return to Windows

EndProc SYS_CRITICAL_EXIT	; End SYS_CRITICAL_EXIT procedure

BeginProc VM_CRITICAL_INIT	; Handler for VM_Critical_Init device call
COMMENT|

Second phase of Create_VM. EBX = VM handle of new VM. Returning Carry will
cause the VM to go Not_Executeable, then be destroyed. VM Simulate_Int,
Exec_Int activity is NOT allowed.

|

	SWAT	DBG_FLAG,@DBG_VMCRITICALINIT ; Call SWAT if SWATVMCriticalInit=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	mov	eax,ebx 	; Copy VM handle into EAX for display

	lea	edi,MSGH1_VM_CRITICAL_INIT ; Offset to hex display area
	mov	ecx,8		; Number of digits
	call	TOHEX		; Form ASCII HEX from EAX

	lea	esi,MSG_VM_CRITICAL_INIT ; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc VM_CRITICAL_INIT	; End VM_CRITICAL_INIT procedure

BeginProc VM_INIT		; Handler for VM_Init device call
COMMENT|

Third phase of Create_VM. EBX = VM handle of new VM. Returning Carry will
cause the VM to go Not_Executeable, then be destroyed. VM Simulate_Int,
Exec_Int activity is allowed.

|

	SWAT	DBG_FLAG,@DBG_VMINIT ; Call SWAT if SWATVMInit=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	mov	eax,ebx 	; Copy VM handle into EAX for display

	lea	edi,MSGH1_VM_INIT ; Offset to hex display area
	mov	ecx,8		; Number of digits
	call	TOHEX		; Form ASCII HEX from EAX

	lea	esi,MSG_VM_INIT ; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

; To enable translation of Int 67h calls to SWAT, we need to
; provide a valid V86 Int 67h address via our TSR portion.

	Push_Client_State	; Save current VM's registers

	VMMcall Begin_Nest_Exec ; Begin nested execution of VM interrupts

	mov	eax,21h 	; Interrupt to execute
	mov	[ebp].Client_AX,3567h ; Get Int 67h vector
	VMMcall Exec_Int	; Return registers in client structure

; Save previous vector in INT_67 at offset 1
	mov	esi,INT67_RMPHYSADDR ; Get RM physical address
	add	esi,[ebx].CB_High_Linear ; Get a linear address
	mov	dx,[ebp].Client_ES ; Get segment of current vector
	mov	[esi + 1].VSEG,dx ; Save it
	mov	dx,[ebp].Client_BX ; Get offset of current vector
	mov	[esi + 1].VOFF,dx ; Save it

; Install INT_67 as the current Int 67h handler
	mov	eax,21h 	; Interrupt to hook
	mov	[ebp].Client_AX,2567h ; Set Int 67h vector
	mov	dx,INT67_SEGOFF.VSEG ; Get our segment
	mov	[ebp].Client_DS,dx ; Set segment
	mov	dx,INT67_SEGOFF.VOFF ; Get our offset
	mov	[ebp].Client_DX,dx ; Set offset
	VMMcall Exec_Int	; Hook it

	VMMcall End_Nest_Exec ; End nested execution of VM interrupts

	Pop_Client_State	; Restore current VM's registers

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc VM_INIT 		; End VM_INIT procedure

BeginProc DEBUG_QUERY		; Handler for Debug_Query device call
COMMENT|

Special call for device specific DEBUG information display and activity.

|

	SWAT	DBG_FLAG,@DBG_DEBUGQUERY ; Call SWAT if SWATDebugQuery=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	mov	eax,ebx 	; Copy VM handle into EAX for display

	lea	edi,MSGH1_DEBUG_QUERY ; Offset to hex display area
	mov	ecx,8		; Number of digits
	call	TOHEX		; Form ASCII HEX from EAX

	lea	esi,MSG_DEBUG_QUERY ; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc DEBUG_QUERY		; End DEBUG_QUERY procedure

BeginProc REBOOT_PROCESSOR	; Handler for Reboot_Processor device call
COMMENT|

Request for reboot. Call cannot be failed.

|

	SWAT	DBG_FLAG,@DBG_REBOOTPROCESSOR ; Call SWAT if SWATRebootProcessor=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	mov	eax,ebx 	; Copy VM handle into EAX for display

	lea	edi,MSGH1_REBOOT_PROCESSOR ; Offset to hex display area
	mov	ecx,8		; Number of digits
	call	TOHEX		; Form ASCII HEX from EAX

	lea	esi,MSG_REBOOT_PROCESSOR ; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc REBOOT_PROCESSOR	; End REBOOT_PROCESSOR procedure

BeginProc SET_DEVICE_FOCUS	; Handler for Set_Device_Focus device call
COMMENT|

EBX = VM Handle to set device focus to. EDX = Device ID if device specific
setfocus. == 0 if device critical setfocus (all devices). THIS CALL CANNOT
BE FAILED.

NOTE: In case where EDX == 0, ESI is a FLAG word that indicates special
	functions. Currently Bit 0 being set indicates that this Device
	critical set focus is also "VM critical". It means that we do not
	want some other VM to take the focus from this app now. This is
	primarily used when doing a device critical set focus to Windows
	(the SYS VM) it is interpreted by the SHELL to mean "if an old app
	currently has the Windows activation, set the activation to the
	Windows Shell, not back to the old app". ALSO in the case where
	Bit 0 is set, EDI = The VM handle of the VM that is "having trouble".
	Set this to 0 if there is no specific VM associated with the problem.

|

	SWAT	DBG_FLAG,@DBG_SETDEVICEFOCUS ; Call SWAT if SWATSetDeviceFocus=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	mov	eax,ebx 	; Copy VM handle into EAX for display

	lea	edi,MSG_SDF_H1	; Offset to hex display area
	mov	ecx,8		; Number of digits
	call	TOHEX		; Form ASCII HEX from EAX

	mov	eax,edx 	; VxD ID for 'specific' broadcast
	lea	edi,MSG_SDF_H2	; Offset to hex display area
	mov	ecx,4		; Number of digits
	call	TOHEX		; Form ASCII HEX from EAX

	mov	eax,esi 	; Flags
	lea	edi,MSG_SDF_H3	; Offset to hex display area
	mov	ecx,4		; Number of digits
	call	TOHEX		; Form ASCII HEX from EAX

	lea	esi,MSG_SDF	; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc SET_DEVICE_FOCUS	; End SET_DEVICE_FOCUS procedure

BeginProc BEGIN_PM_APP		; Handler for Begin_PM_App device call
COMMENT|

About to run a protected mode application.
EBX = Current VM handle.
EDX = Flags
EDI -> Application Control Block
Returning with carry set fails the call.

|

	SWAT	DBG_FLAG,@DBG_BEGINPMAPP ; Call SWAT if SWATBeginPMApp=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	mov	eax,ebx 	; Copy VM handle into EAX for display

	lea	edi,MSGH1_BEGIN_PM_APP ; Offset to hex display area
	mov	ecx,8		; Number of digits
	call	TOHEX		; Form ASCII HEX from EAX

	lea	esi,MSG_BEGIN_PM_APP ; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc BEGIN_PM_APP		; End BEGIN_PM_APP procedure

BeginProc END_PM_APP		; Handler for End_PM_App device call
COMMENT|

Protected mode application is terminating.
EBX = Current VM handle.  THIS CALL CAN NOT FAIL.
EDI -> Application Control Block

|

	SWAT	DBG_FLAG,@DBG_ENDPMAPP ; Call SWAT if SWATEndPMApp=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	mov	eax,ebx 	; Copy VM handle into EAX for display

	lea	edi,MSGH1_END_PM_APP ; Offset to hex display area
	mov	ecx,8		; Number of digits
	call	TOHEX		; Form ASCII HEX from EAX

	lea	esi,MSG_END_PM_APP ; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc END_PM_APP		; End END_PM_APP procedure

BeginProc VM_SUSPEND		; Handler for VM_Suspend device call
COMMENT|

EBX = VM Handle. Call cannot be failed.

|

	SWAT	DBG_FLAG,@DBG_VMSUSPEND ; Call SWAT if SWATVMSuspend=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	mov	eax,ebx 	; Copy VM handle into EAX for display

	lea	edi,MSGH1_VM_SUSPEND ; Offset to hex display area
	mov	ecx,8		; Number of digits
	call	TOHEX		; Form ASCII HEX from EAX

	lea	esi,MSG_VM_SUSPEND ; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc VM_SUSPEND		; End VM_SUSPEND procedure

BeginProc VM_RESUME		; Handler for VM_Resume device call
COMMENT|

EBX = VM Handle. Returning carry fails and backs out the resume.

|

	SWAT	DBG_FLAG,@DBG_VMRESUME ; Call SWAT if SWATVMResume=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	mov	eax,ebx 	; Copy VM handle into EAX for display

	lea	edi,MSGH1_VM_RESUME ; Offset to hex display area
	mov	ecx,8		; Number of digits
	call	TOHEX		; Form ASCII HEX from EAX

	lea	esi,MSG_VM_RESUME ; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc VM_RESUME		; End VM_RESUME procedure

BeginProc BEGIN_MESSAGE_MODE	; Handler for Begin_Message_Mode device call
COMMENT|

EBX = VM Handle going into message mode. THIS CALL CANNOT BE FAILED.

|

	SWAT	DBG_FLAG,@DBG_BEGINMESSAGEMODE ; Call SWAT if SWATBeginMessageMode=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	mov	eax,ebx 	; Copy VM handle into EAX for display

	lea	edi,MSGH1_BEGIN_MSG_MODE ; Offset to hex display area
	mov	ecx,8		; Number of digits
	call	TOHEX		; Form ASCII HEX from EAX

	lea	esi,MSG_BEGIN_MSG_MODE ; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc BEGIN_MESSAGE_MODE	; End BEGIN_MESSAGE_MODE procedure

BeginProc END_MESSAGE_MODE	; Handler for End_Message_Mode device call
COMMENT|

EBX = VM Handle leaving message mode. THIS CALL CANNOT BE FAILED.

|

	SWAT	DBG_FLAG,@DBG_ENDMESSAGEMODE ; Call SWAT if SWATEndMessageMode=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	mov	eax,ebx 	; Copy VM handle into EAX for display

	lea	edi,MSGH1_END_MSG_MODE ; Offset to hex display area
	mov	ecx,8		; Number of digits
	call	TOHEX		; Form ASCII HEX from EAX

	lea	esi,MSG_END_MSG_MODE ; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc END_MESSAGE_MODE	; End END_MESSAGE_MODE procedure

BeginProc QUERY_DESTROY 	; Handler for Query_Destroy device call
COMMENT|

Query_Destroy is an information call made by the SHELL device before an
attempt is made to initiate a destroy VM sequence on a running VM which
has not exited normally. EBX = VM Handle. Returning carry indicates that
a device "has a problem" with allowing this. THE DESTROY SEQUENCE CANNOT
BE ABORTED HOWEVER, this decision is up to the user. All this does is
indicate that there is a "problem" with allowing the destroy. The device
which returns carry should call the SHELL_Message service to post an
informational dialog about the reason for the problem.

|

	SWAT	DBG_FLAG,@DBG_QUERYDESTROY ; Call SWAT if SWATQueryDestroy=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	mov	eax,ebx 	; Copy VM handle into EAX for display

	lea	edi,MSGH1_QUERY_DESTROY ; Offset to hex display area
	mov	ecx,8		; Number of digits
	call	TOHEX		; Form ASCII HEX from EAX

	lea	esi,MSG_QUERY_DESTROY ; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc QUERY_DESTROY		; End QUERY_DESTROY procedure

BeginProc DEVICE_REBOOT_NOTIFY	; Handler for Device_Reboot_Notify device call
COMMENT|

Called whenever system is about to be rebooted.  Allows VxDs to clean
up in preparation for reboot.

|

	SWAT	DBG_FLAG,@DBG_DEVICEREBOOTNOTIFY ; Call SWAT if SWATDeviceRebootNotify=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	lea	esi,MSG_DEVICE_REBOOT_NOTIFY ; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc DEVICE_REBOOT_NOTIFY	; End DEVICE_REBOOT_NOTIFY procedure

BeginProc CRIT_REBOOT_NOTIFY	; Handler for Crit_Reboot_Notify device call
COMMENT|

Called whenever system is about to be rebooted.  Allows VxDs to clean
up in preparation for reboot.

|

	SWAT	DBG_FLAG,@DBG_CRITREBOOTNOTIFY ; Call SWAT if SWATCritRebootNotify=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	lea	esi,MSG_CRIT_REBOOT_NOTIFY ; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc CRIT_REBOOT_NOTIFY	; End CRIT_REBOOT_NOTIFY procedure

BeginProc CLOSE_VM_NOTIFY	; Handler for Close_VM_Notify device call
COMMENT|

Called when VM is about to be terminated using the Close_VM service
    EBX = Current VM handle (Handle of VM to close)
    EDX = Flags
	  CVNF_Crit_Close = 1 if VM is in critical section while closing

|

	SWAT	DBG_FLAG,@DBG_CLOSEVMNOTIFY ; Call SWAT if SWATCloseVMNotify=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	mov	eax,ebx 	; Copy VM handle into EAX for display

	lea	edi,MSGH1_CLOSE_VM_NOTIFY ; Offset to hex display area
	mov	ecx,8		; Number of digits
	call	TOHEX		; Form ASCII HEX from EAX

	lea	esi,MSG_CLOSE_VM_NOTIFY ; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc CLOSE_VM_NOTIFY 	; End CLOSE_VM_NOTIFY procedure

BeginProc POWER_EVENT		; Handler for Power_Event device call
COMMENT|

Power management event notification.
    EBX = 0
    ESI = event notification message
    EDI -> DWORD return value; VxD's modify the DWORD to return info, not EDI
    EDX is reserved

|

	SWAT	DBG_FLAG,@DBG_POWEREVENT ; Call SWAT if SWATPowerEvent=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

	lea	esi,MSG_POWER_EVENT ; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

EndProc POWER_EVENT		; End POWER_EVENT procedure

EVENTPROC macro FLAG,MSG,THREAD

% BeginProc MSG 		; Handler for MSG device call
COMMENT|

Handle event &MSG.

|

	SWAT	DB3_FLAG,@DB3_&FLAG ; Call SWAT if @DB3_&FLAG=TRUE

	pushad			; Don't wreck registers for the next VxD

	call	REHOOK_DBG_INTS ; Rehook INTs 01h, 02h, and 03h

ifnb <THREAD>
	mov	eax,edi 	; Copy thread #
	lea	edi,MSG_&MSG&1	; Offset to display text
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text
endif
	lea	esi,MSG_&MSG	; Offset to display text
	call	DISPLAY 	; Put text up on debugging screen
	call	WDEB_DISPLAY	; Send the message to the WDEB386

	popad			; Restore caller's registers

	clc			; Normal exit indicator

	ret			; Return to Windows

% EndProc MSG			; End MSG procedure

	endm			; EVENTPROC

	EVENTPROC SYSDYNAMICDEVICEINIT, SYS_DYNAMIC_DEVICE_INIT
	EVENTPROC SYSDYNAMICDEVICEEXIT, SYS_DYNAMIC_DEVICE_EXIT
	EVENTPROC CREATETHREAD	      , CREATE_THREAD,		THREAD
	EVENTPROC THREADINIT	      , THREAD_INIT,		THREAD
	EVENTPROC TERMINATETHREAD     , TERMINATE_THREAD,	THREAD
	EVENTPROC THREADNOTEXECUTEABLE, THREAD_NOT_EXECUTEABLE, THREAD
	EVENTPROC DESTROYTHREAD       , DESTROY_THREAD, 	THREAD
	EVENTPROC PNPNEWDEVNODE       , PNP_NEW_DEVNODE
	EVENTPROC W32DEVICEIOCONTROL  , W32_DEVICEIOCONTROL
	EVENTPROC SYSVMTERMINATE2     , SYS_VM_TERMINATE2
	EVENTPROC SYSTEMEXIT2	      , SYSTEM_EXIT2
	EVENTPROC SYSCRITICALEXIT2    , SYS_CRITICAL_EXIT2
	EVENTPROC VMTERMINATE2	      , VM_TERMINATE2
	EVENTPROC VMNOTEXECUTEABLE2   , VM_NOT_EXECUTEABLE2
	EVENTPROC DESTROYVM2	      , DESTROY_VM2
	EVENTPROC VMSUSPEND2	      , VM_SUSPEND2
	EVENTPROC ENDMESSAGEMODE2     , END_MESSAGE_MODE2
	EVENTPROC ENDPMAPP2	      , END_PM_APP2
	EVENTPROC DEVICEREBOOTNOTIFY2 , DEVICE_REBOOT_NOTIFY2
	EVENTPROC CRITREBOOTNOTIFY2   , CRIT_REBOOT_NOTIFY2
	EVENTPROC CLOSEVMNOTIFY2      , CLOSE_VM_NOTIFY2
	EVENTPROC GETCONTENTIONHANDLER, GET_CONTENTION_HANDLER
	EVENTPROC KERNEL32INITIALIZED , KERNEL32_INITIALIZED
	EVENTPROC KERNEL32SHUTDOWN    , KERNEL32_SHUTDOWN

BeginProc UNDO_VXDHOOKS 	; Undo debug hooks for VxDs
COMMENT|

	Undo the debug hooks for VxDs.

	Trundle the VXDHOOK_STR chain, unhook the Control_Proc and
	release the storage back to WIN386

|

	REGSAVE <eax,ecx,edx>	; Save caller's registers

	mov	edx,VXDHOOKS_HEAD ; ==> 1st link in our hooked VxD chain
@@:
	or	edx,edx 	; Izit the end of the chain?
	jz	short @F	; Yes, exit loop

	mov	ecx,[edx].VH_DDB ; ECX ==> target VxD's DDB

	mov	eax,[edx].VH_OLDPROC ; EAX ==> VxD's original Control_Proc
	mov	[ecx].DDB_Control_Proc,eax ; Restore it

	mov	eax,edx 	; Copt ==> VXDHOOK_STR for _HeapFree
	mov	edx,[edx].VH_NEXT ; Bump to next link in VXDHOOK_STR chain

; Free the space used by the VXDHOOK_STR structure

	REGSAVE <ecx,edx>	; Save registers clobbered by _HeapFree

	VMMcall _HeapFree <eax, 0> ; Free next link in chain

	REGREST <edx,ecx>	; Restore registers clobbered by _HeapFree

; Go on to the next link in the VXDHOOK_STR chain

	jmp	short @B	; Go get 'em all
@@:
	REGREST <edx,ecx,eax>	; Restore caller's registers

	ret			; Return to caller

EndProc UNDO_VXDHOOKS		; End UNDO_VXDHOOKS procedure

BeginProc UNDO_PMHOOKS		; Undo hooks into device PM API entry points
COMMENT|

	Undo the hooks into device PM API entry points

	Trundle the PMHOOK_STR chain, unhook the PM_API_Proc and
	release the storage back to WIN386

|

	REGSAVE <eax,ecx,edx>	; Save caller's registers

	mov	edx,PMHOOKS_HEAD ; ==> 1st link in our hooked VxD chain
@@:
	or	edx,edx 	; Izit the end of the chain?
	jz	short @F	; Yes, exit loop

	mov	ecx,[edx].VH_DDB ; ECX ==> target VxD's DDB

	mov	eax,[edx].VH_OLDPROC ; EAX ==> VxD's original PM_API_Proc
	mov	[ecx].DDB_PM_API_Proc,eax ; Restore it

	mov	eax,edx 	; Copy ==> PMHOOK_STR for _HeapFree
	mov	edx,[edx].VH_NEXT ; Bump to next link in PMHOOK_STR chain

; Free the space used by the PMHOOK_STR structure

	REGSAVE <ecx,edx>	; Save registers clobbered by _HeapFree

	VMMcall _HeapFree <eax, 0> ; Free next link in chain

	REGREST <edx,ecx>	; Restore registers clobbered by _HeapFree

; Go on to the next link in the PMHOOK_STR chain

	jmp	short @B	; Go get 'em all
@@:
	REGREST <edx,ecx,eax>	; Restore caller's registers

	ret			; Return to caller

EndProc UNDO_PMHOOKS		; End UNDO_PMHOOKS procedure

BeginProc GET_SYSTEM_OPTION	; Clear AX if SYSTEM.INI option is NOT set
COMMENT|

Entry:
	EDX	=	Flag bit for option

Exit:
	EDX	=	Input flag bit if string found
			NULL if string not found

|

	REGSAVE <eax,esi>	; Save caller's registers

	push	edx		; Save EDX around call
	sub	edx,edx 	; Assume option not present
	lea	esi,STR_386SWAT ; ==> [386SWAT] section of SYSTEM.INI

	VMMcall Get_Profile_String ; EDX ==> text of option if present

	or	edx,edx 	; Is the string present?
	pop	edx		; Restore
	jnz	short @F	; Jump if option is present

	sub	edx,edx 	; Kill option bit
@@:

	REGREST <esi,eax>	; Restore caller's registers

	ret			; Return to caller

EndProc GET_SYSTEM_OPTION	; End GET_SYSTEM_OPTION procedure

BeginProc REHOOK_DBG_INTS	; Rehook INTs 01h, 02h, and 03h

	test	DB2_FLAG,@DB2_REHOOK123 ; Are we supposed to steal these INTs?
	jz	short @F	; Skip everything if REHOOK123=FALSE

	call	RDI_SUB 	; Do the actual hooking
@@:
	ret			; Return to caller

EndProc REHOOK_DBG_INTS 	; End REHOOK_DBG_INTS procedure

BeginProc RDI_SUB		; Rehook INTs 01h, 02h, and 03h (subroutine)

	REGSAVE <eax,ebx>	; Save caller's registers

	sub	esp,size DTR_STR ; Make room for IDTR
	sidt	[esp].EDF	; Get IDTR
	mov	ebx,[esp].DTR_BASE ; Get IDT base
	add	esp,size DTR_STR ; Strip from stack

RESETINT_MAC macro NN

; Blast in new IDT entry for INT NN&h

	mov	eax,INT&NN&_IDTENT.EDQLO ; Get the low-order word
	mov	[ebx+(NN&h*size IDT_STR)].EDQLO,eax ; Save as new value

	mov	eax,INT&NN&_IDTENT.EDQHI  ; Get the high-order word
	mov	[ebx+(NN&h*size IDT_STR)].EDQHI,eax ; Save as new value

	endm			; RESETINT_MAC

	RESETINT_MAC 01 	; Reset INT 01h
	RESETINT_MAC 02 	; ...	    02h
	RESETINT_MAC 03 	; ...	    03h

; Note that 386MAX hooks INT 41h for its own (and temporary)
; purposes, so we shouldn't just blast in our handler again.

	REGREST <ebx,eax>	; Restore caller's registers

	clc			; Normal return indicator

	ret			; Return to caller

EndProc RDI_SUB 		; End RDI_SUB procedure

	page
NAC_STR struc			; Structure to access arguments

	dd	?		; ...	   EBP
	dd	?		; Caller's EIP
NAC_MSG dd	?		; Offset of message text

NAC_STR ends			; End NAC_STR structure

BeginProc NAME_AND_CALL 	; Send VxD name and service call to SWATMSG
	assume	ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

DESCRIPTION:
	Send name of most recently seen VxD and current service call name
	to SWATMSG

ENTRY:
	Arguments in the stack:
	Address of message text for service call

|

	push	ebp		; Save previous stack frame
	mov	ebp,esp 	; Create local frame

	pushad			; Save 'em

; Copy the name of the last VxD we saw

	mov	esi,OFFSET32 BUF_LASTVXD ; ==> message workspace
	mov	edi,OFFSET32 BUF_HOOKVXD ; ==> message workspace
@@:
	lodsb			; Get character from target VxD's name
	or	al,al		; Izit the NUL terminator?
	jz	short @F	; Yes, exit loop

S32	stosb			; Store in message work area

	jmp	short @B	; Get 'em all
@@:

	mov	al,':'          ; Store a ':' into the work area
S32	stosb			; ...

; Append the service name

	mov	esi,[ebp].NAC_MSG ; Offset of message text
@@:
	lodsb			; Get character from target VxD's name
	or	al,al		; Izit the NUL terminator?
	jz	short @F	; Yes, exit loop

S32	stosb			; Store in message work area

	jmp	short @B	; Get 'em all
@@:
	sub	al,al		; Terminate the string
S32	stosb			; ...


; Send the message off to SWAT

	push	dword ptr 0	; Dummy error code
	push	ds		; Selector of message text
	mov	eax,OFFSET32 BUF_HOOKVXD ; Offset of message text
	push	eax		; Pass to SWATMSG
	call	SWATMSG_FVEC	; Call SWATMSG

	popad			; Restore 'em

	pop	ebp		; Restore previous stack frame

	ret	4		; Return to caller, popping arguments

	assume	ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc NAME_AND_CALL		; End NAME_AND_CALL procedure

VxD_CODE_ENDS			; End _LCODE segment

	end			; End SWATVXD module
