;'$Header:   P:/PVCS/SWATVXD/SWAT_MSG.ASV   1.21   10 Aug 1998 10:46:26   BOB  $
	 title	 SWAT_MSG -- Message Text for SWATVXD
	 page	 58,122
	 name	 SWAT_MSG

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1990-98 Qualitas, Inc.  All rights reserved.

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
	 include VMM.INC	; Fixed version of file from DDK

	 include ASCII.INC

	 include SWATVER.INC	; Version # extrns
.list

VxD_REAL_INIT_SEG

	 public  MSG_RMI
MSG_RMI  db	 'SWATVXD  -- Version '
	 db	 SWAT_VERS_H, '.', SWAT_VERS_T, SWAT_VERS_U
	 db	 ' -- A Debugger for WIN386', CR, LF
	db	SWATCOPY	; Common copyright message
	 db	 CR, LF, CR, LF, EOS

	 public  MSG_DUP_DEVICE
MSG_DUP_DEVICE	 db	'Duplicate Device Installation Attempted', CR, LF, EOS

	 public  MSG_NOINSTALL
MSG_NOINSTALL	 db	'SWATVXD Not Installing Due to NOSWAT Option', CR, LF, EOS

	 public  MSG_NO_SWAT
MSG_NO_SWAT	 db	'386SWAT.LOD Not Loaded', CR, LF, EOS

	 public  MSG_NO_INFO
MSG_NO_INFO	 db	'SWATINFO Not Available', CR, LF, EOS

	 public  MSG_XMS_VER, MSG_XMS_VER_X1, MSG_XMS_VER_X2, MSG_XMS_VER_X3
MSG_XMS_VER	 db	'XMS Services version '
MSG_XMS_VER_X1	 db	'x.'
MSG_XMS_VER_X2	 db	'xx, revision '
MSG_XMS_VER_X3	 db	'xxxxh', CR, LF, EOS

	 public  MSG_IDTR, MSG_IDTR_BASE, MSG_IDTR_LIM
MSG_IDTR	 db	'IDTR at real mode init = '
MSG_IDTR_BASE	 db	'xxxxxxxx ('
MSG_IDTR_LIM	 db	'xxxx)', CR, LF, EOS

	 public  MSG_MAXVER, MSG_MAXVER_X
MSG_MAXVER	 db	'386MAX.SYS Version '
MSG_MAXVER_X	 db	'x.xx', CR, LF, EOS

	 public  MSG_NOMAX
MSG_NOMAX	 db	'386MAX.SYS Not Installed', CR, LF, EOS

	 public  MSG_MAXOFF
MSG_MAXOFF	 db	'386MAX.SYS is OFF', CR, LF, EOS

	 public  MSG_PAK
MSG_PAK 	 db	'SWATVXD Not Loaded.  Press any key to continue...', CR, LF, EOS

	 public MSG_PAKORESC
MSG_PAKORESC	db	'Press any key to continue (ESC to quit)...', EOS

	 public  MSG_CRLF
MSG_CRLF	 db	CR, LF, EOS

	 public  MSG_IMPORT_OPEN
MSG_IMPORT_OPEN  db	'Can not open EMMXXXX0 for paging import data', CR, LF, EOS

	 public  MSG_IMPORT_NOTCHR
MSG_IMPORT_NOTCHR db	'EMMXXXX0 not a character device', CR, LF, EOS

	 public  MSG_IMPORT_IOCTL1
MSG_IMPORT_IOCTL1 db	'Get device info IOCTL call for EMMXXXX0 failed', CR, LF, EOS

	 public  MSG_IMPORT_IOCTL2
MSG_IMPORT_IOCTL2 db	'Get Paging Import IOCTL call failed', CR, LF, EOS

	 public  MSG_IMPORT_IOCTL3
MSG_IMPORT_IOCTL3 db	'Paging Import IOCTL length is wrong', CR, LF, EOS

	 public  MSG_IMPORT_NULL
MSG_IMPORT_NULL  db	'WIN386 Paging Import data not available', CR, LF, EOS

	 public  MSG_IMPORT_INFO
	 public  MSG_IMPORT_INFO0, MSG_IMPORT_INFO1, MSG_IMPORT_INFO2
MSG_IMPORT_INFO  db	'WIN386 Paging Import version '
MSG_IMPORT_INFO0 db	'd.'            ; Major version #
MSG_IMPORT_INFO1 db	'dd, @ '        ; Minor version #s
MSG_IMPORT_INFO2 db	'xxxxxxxx (Physical)', CR, LF, EOS

	 public  MSG_SYMB_INFO, MSG_SYMB_INFO1, MSG_SYMB_INFO2
MSG_SYMB_INFO	 label	byte
MSG_SYMB_INFO1	 db	'dddddd symbol records read from '
MSG_SYMB_INFO2	 db	80 dup (' ')    ; Space for filename

	 public  MSG_SYMB_NONE
MSG_SYMB_NONE	 db	'No .SSF files processed', CR, LF, EOS

VxD_REAL_INIT_ENDS

VxD_IDATA_SEG			; Begin _IDATA segment

	public	MSG_WKD
MSG_WKD db	'    SWAT is running as Windows Kernel Debugger', CR, LF, 0

	 public  MSG_SCI
MSG_SCI  db	 '--> Sys_Critical_Init'
	 db	 ' -- Version '
	 db	 SWAT_VERS_H, '.', SWAT_VERS_T, SWAT_VERS_U, CR, LF, 0

	 public  MSG_PDI
MSG_PDI  db	 '--> Device_Init', CR, LF, 0

	 public  MSG_PDI_UGH
MSG_PDI_UGH db	 '    SWATVXD  ERROR: Device_Init Error', CR, LF, 0

	 public  MSG_ICP
MSG_ICP  db	 '--> Init_Complete', CR, LF, 0

	 public  MSG_ROM_BREAKPOINTS
MSG_ROM_BREAKPOINTS db	'    SWATVXD: SystemROMBreakPoint != FALSE', CR, LF, 0

	 public  MSG_NOSYMB
MSG_NOSYMB	 db	'    SWATVXD: 386SWAT.LOD is too old to support symbols within WIN386', CR, LF, 0

	 public  MSG_VXDHK_NOFND, MSG_VXDHK_NOFND0
MSG_VXDHK_NOFND db '    SWATVXD: Can''t find device: '
MSG_VXDHK_NOFND0 db 8 dup (?)
	 db	 CR, LF, 0

	 public  MSG_NO_WINA20, MSG_WINA20
MSG_WINA20	 db	'    WINA20.386 (LA20HMA) is loaded', CR, LF, 0
MSG_NO_WINA20	 db	'    WINA20.386 (LA20HMA) is NOT loaded', CR, LF, 0

	 public  MSG_PAGING_OFF, MSG_PAGING_ON
MSG_PAGING_OFF	 db	'    Paging is disabled', CR, LF, 0
MSG_PAGING_ON	 db	'    Paging is enabled', CR, LF, 0

	 public  MSG_WFW
MSG_WFW 	 db	'    Windows for Workgroups devices are present', CR, LF, 0

VxD_IDATA_ENDS			; End _IDATA segment

VxD_DATA_SEG			; Begin _LDATA segment

	 public  MSG_THRUXITWARN
MSG_THRUXITWARN  db	'    Warning! DebugThruExit=ON', CR, LF, 0

;;;	 public  MSG_SMI
;;;MSG_SMI	    db	   'SetMappingInfo', 0
;;;
;;;	 public  MSG_AGVDA
;;;MSG_AGVDA	    db	   'AllocateGlobalV86DataArea', 0
;;;
	 public  MSG_MAPINFO, MSG_MAPINFO0, MSG_MAPINFO1
MSG_MAPINFO	 db	'    V86MMGR_Get_Mapping_Info: Total = '
MSG_MAPINFO0	 db	'xx, Free = '
MSG_MAPINFO1	 db	'xx', CR, LF, 0

	 public  MSG_FATAL_ERROR, MSG_FATAL_ERROR0, MSG_FATAL_ERROR_NULL
MSG_FATAL_ERROR  db	'Fatal_Error: ' ; Sent to SWATMSG
MSG_FATAL_ERROR0 db	'xxxxxxxx', 0   ; Hex field for message text pointer
MSG_FATAL_ERROR_NULL db '(NULL)', 0     ; Used when ESI is 0

	 public  MSG_HOOK_FEH_UGH
MSG_HOOK_FEH_UGH db	'    SWATVXD  ERROR: Cannot Hook Fatal_Error_Handler', CR, LF, 0

	 public  MSG_HOOK_ODS_UGH
MSG_HOOK_ODS_UGH db	'    SWATVXD  ERROR: Cannot Hook Out_Debug_String', CR, LF, 0

	 public  MSG_GSDVME, MSG_GSDVME0
	 public  MSG_GSDVME_EC, MSG_GSDVME_VM, MSG_GSDVME_TEXT
MSG_GSDVME0	 db	'    GetSetDetailedVMError: VM='
MSG_GSDVME_VM	 db	'xxxxxxxx '
		 db	'EC='
MSG_GSDVME	 label	byte
MSG_GSDVME_EC	 db	'xxxxxxxx '
MSG_GSDVME_TEXT  db	80 dup (' ')    ; Space for message text

	 public  MSG_SVI, MSG_SVI_H1
MSG_SVI 	db	'--> Sys_VM_Init.        VM = '
MSG_SVI_H1	db	'xxxxxxxx', CR, LF, 0

	 public  MSG_SVT, MSG_SVT_H1
MSG_SVT 	db	'--> Sys_VM_Terminate.   VM = '
MSG_SVT_H1	db	'xxxxxxxx', CR, LF, 0

	 public  MSG_CVM, MSG_CVM_H1
MSG_CVM 	db	'--> Create_VM.          VM = '
MSG_CVM_H1	db	'xxxxxxxx', CR, LF, 0

	 public  MSG_VMT, MSG_VMT_H1
MSG_VMT 	db	'--> VM_Terminate.       VM = '
MSG_VMT_H1	db	'xxxxxxxx', CR, LF, 0

	 public  MSG_VNE, MSG_VNE_H1, MSG_VNE_X
MSG_VNE 	db	'--> VM_Not_Executable.  VM = '
MSG_VNE_H1	db	'xxxxxxxx, Flags = '
MSG_VNE_X	db	40 dup (?), CR, LF, 0	; Filled in with an MSG_VNE_xxx msg

	 public  MSG_DVM, MSG_DVM_H1
MSG_DVM 	db	'--> Destroy_VM.         VM = '
MSG_DVM_H1	db	'xxxxxxxx', CR, LF, 0

	 public  MSG_SEX
MSG_SEX 	db	'--> System_Exit', CR, LF, 0

	 public  MSG_SCEX
MSG_SCEX	db	'--> Sys_Critical_Exit', CR, LF, 0

	 public  MSG_VM_CRITICAL_INIT, MSGH1_VM_CRITICAL_INIT
MSG_VM_CRITICAL_INIT db '--> VM_Critical_Init.   VM = '
MSGH1_VM_CRITICAL_INIT	db	'xxxxxxxx', CR, LF, 0

	 public  MSG_VM_INIT, MSGH1_VM_INIT
MSG_VM_INIT	db	'--> VM_Init.            VM = '
MSGH1_VM_INIT	db	'xxxxxxxx', CR, LF, 0

	 public  MSG_BEGIN_PM_APP, MSGH1_BEGIN_PM_APP
MSG_BEGIN_PM_APP db	'--> Begin_PM_App.       VM = '
MSGH1_BEGIN_PM_APP db	'xxxxxxxx', CR, LF, 0

	 public  MSG_END_PM_APP, MSGH1_END_PM_APP
MSG_END_PM_APP	db	'--> End_PM_App.         VM = '
MSGH1_END_PM_APP db	'xxxxxxxx', CR, LF, 0

	 public  MSG_VM_SUSPEND, MSGH1_VM_SUSPEND
MSG_VM_SUSPEND	db	'--> VM_Suspend.         VM = '
MSGH1_VM_SUSPEND db	'xxxxxxxx', CR, LF, 0

	 public  MSG_VM_RESUME, MSGH1_VM_RESUME
MSG_VM_RESUME	db	'--> VM_Resume.          VM = '
MSGH1_VM_RESUME db	'xxxxxxxx', CR, LF, 0

	 public  MSG_SDF, MSG_SDF_H1, MSG_SDF_H2, MSG_SDF_H3
MSG_SDF 	 db	'--> Set_Device_Focus.   VM = '
MSG_SDF_H1	 db	'xxxxxxxx, DX = '
MSG_SDF_H2	 db	'xxxx, SI = '
MSG_SDF_H3	 db	'xxxx'
		 db	CR, LF, 0

	 public  MSG_BEGIN_MSG_MODE, MSGH1_BEGIN_MSG_MODE
MSG_BEGIN_MSG_MODE db	'--> Begin_Message_Mode. VM = '
MSGH1_BEGIN_MSG_MODE db 'xxxxxxxx', CR, LF, 0

	 public  MSG_END_MSG_MODE, MSGH1_END_MSG_MODE
MSG_END_MSG_MODE db	'--> End_Message_Mode.   VM = '
MSGH1_END_MSG_MODE db	'xxxxxxxx', CR, LF, 0

	 public  MSG_QUERY_DESTROY, MSGH1_QUERY_DESTROY
MSG_QUERY_DESTROY db	'--> Query_Destroy.      VM = '
MSGH1_QUERY_DESTROY db	'xxxxxxxx', CR, LF, 0

	 public  MSG_DEBUG_QUERY, MSGH1_DEBUG_QUERY
MSG_DEBUG_QUERY db	'--> Debug_Query.        VM = '
MSGH1_DEBUG_QUERY db	'xxxxxxxx', CR, LF, 0

	 public  MSG_REBOOT_PROCESSOR, MSGH1_REBOOT_PROCESSOR
MSG_REBOOT_PROCESSOR db '--> Reboot_Processor.   VM = '
MSGH1_REBOOT_PROCESSOR db	'xxxxxxxx', CR, LF, 0

	 public  MSG_DEVICE_REBOOT_NOTIFY
MSG_DEVICE_REBOOT_NOTIFY db '--> Device_Reboot_Notify.', CR, LF, 0

	 public  MSG_CRIT_REBOOT_NOTIFY
MSG_CRIT_REBOOT_NOTIFY db '--> Crit_Reboot_Notify.', CR, LF, 0

	 public  MSG_CLOSE_VM_NOTIFY, MSGH1_CLOSE_VM_NOTIFY
MSG_CLOSE_VM_NOTIFY db '--> Close_VM_Notify.   VM = '
MSGH1_CLOSE_VM_NOTIFY db	'xxxxxxxx', CR, LF, 0

	 public  MSG_POWER_EVENT
MSG_POWER_EVENT db '--> Power_Event.', CR, LF, 0

	public	MSG_SYS_DYNAMIC_DEVICE_INIT
	public	MSG_SYS_DYNAMIC_DEVICE_EXIT
	public	MSG_CREATE_THREAD,MSG_CREATE_THREAD1
	public	MSG_THREAD_INIT,MSG_THREAD_INIT1
	public	MSG_TERMINATE_THREAD,MSG_TERMINATE_THREAD1
	public	MSG_THREAD_NOT_EXECUTEABLE,MSG_THREAD_NOT_EXECUTEABLE1
	public	MSG_DESTROY_THREAD,MSG_DESTROY_THREAD1
	public	MSG_PNP_NEW_DEVNODE
	public	MSG_W32_DEVICEIOCONTROL
	public	MSG_SYS_VM_TERMINATE2
	public	MSG_SYSTEM_EXIT2
	public	MSG_SYS_CRITICAL_EXIT2
	public	MSG_VM_TERMINATE2
	public	MSG_VM_NOT_EXECUTEABLE2
	public	MSG_DESTROY_VM2
	public	MSG_VM_SUSPEND2
	public	MSG_END_MESSAGE_MODE2
	public	MSG_END_PM_APP2
	public	MSG_DEVICE_REBOOT_NOTIFY2
	public	MSG_CRIT_REBOOT_NOTIFY2
	public	MSG_CLOSE_VM_NOTIFY2
	public	MSG_GET_CONTENTION_HANDLER
	public	MSG_KERNEL32_INITIALIZED
	public	MSG_KERNEL32_SHUTDOWN
MSG_SYS_DYNAMIC_DEVICE_INIT db	'--> Sys_Dynamic_Device_Init.', CR, LF, 0
MSG_SYS_DYNAMIC_DEVICE_EXIT db	'--> Sys_Dynamic_Device_Exit.', CR, LF, 0
MSG_CREATE_THREAD	    db	'--> Create_Thread,         EDI='
MSG_CREATE_THREAD1	    db	'xxxxxxxx.', CR, LF, 0
MSG_THREAD_INIT 	    db	'--> Thread_Init,           EDI='
MSG_THREAD_INIT1	    db	'xxxxxxxx.', CR, LF, 0
MSG_TERMINATE_THREAD	    db	'--> Terminate_Thread,      EDI='
MSG_TERMINATE_THREAD1	    db	'xxxxxxxx.', CR, LF, 0
MSG_THREAD_NOT_EXECUTEABLE  db	'--> Thread_Not_Executeable,EDI='
MSG_THREAD_NOT_EXECUTEABLE1 db 'xxxxxxxx.', CR, LF, 0
MSG_DESTROY_THREAD	    db	'--> Destroy_Thread,        EDI='
MSG_DESTROY_THREAD1	    db	'xxxxxxxx.', CR, LF, 0
MSG_PNP_NEW_DEVNODE	    db	'--> PNP_New_Devnode.', CR, LF, 0
MSG_W32_DEVICEIOCONTROL     db	'--> W32_DeviceIOControl.', CR, LF, 0
MSG_SYS_VM_TERMINATE2	    db	'--> Sys_VM_Terminate2.', CR, LF, 0
MSG_SYSTEM_EXIT2	    db	'--> System_Exit2.', CR, LF, 0
MSG_SYS_CRITICAL_EXIT2	    db	'--> Sys_Critical_Exit2.', CR, LF, 0
MSG_VM_TERMINATE2	    db	'--> Vm_Terminate2.', CR, LF, 0
MSG_VM_NOT_EXECUTEABLE2     db	'--> Vm_Not_Executeable2.', CR, LF, 0
MSG_DESTROY_VM2 	    db	'--> Destroy_VM2.', CR, LF, 0
MSG_VM_SUSPEND2 	    db	'--> VM_Suspend2.', CR, LF, 0
MSG_END_MESSAGE_MODE2	    db	'--> End_Message_Mode2.', CR, LF, 0
MSG_END_PM_APP2 	    db	'--> End_PM_App2.', CR, LF, 0
MSG_DEVICE_REBOOT_NOTIFY2   db	'--> Device_Reboot_Notify2.', CR, LF, 0
MSG_CRIT_REBOOT_NOTIFY2     db	'--> Crit_Reboot_Notify2.', CR, LF, 0
MSG_CLOSE_VM_NOTIFY2	    db	'--> Close_VM_Notify2.', CR, LF, 0
MSG_GET_CONTENTION_HANDLER  db	'--> Get_Contention_Handler.', CR, LF, 0
MSG_KERNEL32_INITIALIZED    db	'--> Kernel32_Initialized.', CR, LF, 0
MSG_KERNEL32_SHUTDOWN	    db	'--> Kernel32_Shutdown.', CR, LF, 0

;;; MSG_REF	    db	    'Reference Data @ '
;;; MSG_REF_HEX8    db	    'xxxxxxxx', 0

;;; MSG_DESC	    db	    '1st Allocated GDT Selector = '
;;; MSG_DESC_HEX4   db	    'xxxx', 0

;;; MSG_DESC2	    db	    '2nd Allocated GDT Selector = '
;;; MSG_DESC2_HEX4  db	    'xxxx', 0

VxD_DATA_ENDS			; End _LDATA segment

	 end			; End SWAT_MSG module

