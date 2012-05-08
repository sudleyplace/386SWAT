;' $Header:   P:/PVCS/SWATVXD/SWATSINI.INV   1.6   10 Aug 1998 10:46:18   BOB  $
;
; (C) Copyright 1990-98 Qualitas, Inc.	All rights reserved.
;
; SWATSINI.INC
;
; This include file is used to automatically keep the help screen up-to-date
;

SYSINI_STRINGS macro	VXDNAME, OPTION

ifidni <OPTION>, <DEFINE>
SYSINI_HOOKPF		db	'&VXDNAME', 'HOOKPF', 0
SYSINI_VxDIPF		db	'&VXDNAME', 'VxDIPF', 0
SYSINI_VxDROM		db	'&VXDNAME', 'VxDROM', 0
SYSINI_PL0WP		db	'&VXDNAME', 'PL0WP', 0
SYSINI_DUALDISPLAY	db	'&VXDNAME', 'DualDisplay', 0
SYSINI_THRUXIT		db	'&VXDNAME', 'DebugThruExit', 0
SYSINI_HOOKIRQ		db	'&VXDNAME', 'HookIRQ', 0

SYSINI_SYSCRITICALINIT	    db	'&VXDNAME', 'SysCriticalInit', 0        ; 0000
SYSINI_DEVICEINIT	    db	'&VXDNAME', 'DeviceInit', 0             ; 0001
SYSINI_INITCOMPLETE	    db	'&VXDNAME', 'InitComplete', 0           ; 0002
SYSINI_SYSVMINIT	    db	'&VXDNAME', 'SysVMInit', 0              ; 0003
SYSINI_SYSVMTERMINATE	    db	'&VXDNAME', 'SysVMTerminate', 0         ; 0004
SYSINI_SYSTEMEXIT	    db	'&VXDNAME', 'SystemExit', 0             ; 0005
SYSINI_SYSCRITICALEXIT	    db	'&VXDNAME', 'SysCriticalExit', 0        ; 0006
SYSINI_CREATEVM 	    db	'&VXDNAME', 'CreateVM', 0               ; 0007
SYSINI_VMCRITICALINIT	    db	'&VXDNAME', 'VMCriticalInit', 0         ; 0008
SYSINI_VMINIT		    db	'&VXDNAME', 'VMInit', 0                 ; 0009
SYSINI_VMTERMINATE	    db	'&VXDNAME', 'VMTerminate', 0            ; 000A
SYSINI_VMNOTEXECUTEABLE     db	'&VXDNAME', 'VMNotExecuteable', 0       ; 000B
SYSINI_DESTROYVM	    db	'&VXDNAME', 'DestroyVM', 0              ; 000C
SYSINI_VMSUSPEND	    db	'&VXDNAME', 'VMSuspend', 0              ; 000D
SYSINI_VMRESUME 	    db	'&VXDNAME', 'VMResume', 0               ; 000E
SYSINI_SETDEVICEFOCUS	    db	'&VXDNAME', 'SetDeviceFocus', 0         ; 000F
SYSINI_BEGINMESSAGEMODE     db	'&VXDNAME', 'BeginMessageMode', 0       ; 0010
SYSINI_ENDMESSAGEMODE	    db	'&VXDNAME', 'EndMessageMode', 0         ; 0011
SYSINI_REBOOTPROCESSOR	    db	'&VXDNAME', 'RebootProcessor', 0        ; 0012
SYSINI_QUERYDESTROY	    db	'&VXDNAME', 'QueryDestroy', 0           ; 0013
SYSINI_DEBUGQUERY	    db	'&VXDNAME', 'DebugQuery', 0             ; 0014
SYSINI_BEGINPMAPP	    db	'&VXDNAME', 'BeginPMApp', 0             ; 0015
SYSINI_ENDPMAPP 	    db	'&VXDNAME', 'EndPMApp', 0               ; 0016

SYSINI_DEVICEREBOOTNOTIFY   db	'&VXDNAME', 'DeviceRebootNotify', 0     ; 0017
SYSINI_CRITREBOOTNOTIFY     db	'&VXDNAME', 'CritRebootNotify', 0       ; 0018
SYSINI_CLOSEVMNOTIFY	    db	'&VXDNAME', 'CloseVMNotify', 0          ; 0019
SYSINI_POWEREVENT	    db	'&VXDNAME', 'PowerEvent', 0             ; 001A

SYSINI_SYSDYNAMICDEVICEINIT db	'&VXDNAME', 'SysDynamicDeviceInit', 0   ; 001B
SYSINI_SYSDYNAMICDEVICEEXIT db	'&VXDNAME', 'SysDynamicDeviceExit', 0   ; 001C
SYSINI_CREATETHREAD	    db	'&VXDNAME', 'CreateThread',         0   ; 001D
SYSINI_THREADINIT	    db	'&VXDNAME', 'ThreadInit',           0   ; 001E
SYSINI_TERMINATETHREAD	    db	'&VXDNAME', 'TerminateThread',      0   ; 001F
SYSINI_THREADNOTEXECUTEABLE db	'&VXDNAME', 'ThreadNotExecuteable', 0   ; 0020
SYSINI_DESTROYTHREAD	    db	'&VXDNAME', 'DestroyThread',        0   ; 0021
SYSINI_PNPNEWDEVNODE	    db	'&VXDNAME', 'PNPNewDevNode',        0   ; 0022
SYSINI_W32DEVICEIOCONTROL   db	'&VXDNAME', 'W32DeviceIOControl',   0   ; 0023
SYSINI_SYSVMTERMINATE2	    db	'&VXDNAME', 'SysVMTerminate2',      0   ; 0024
SYSINI_SYSTEMEXIT2	    db	'&VXDNAME', 'SystemExit2',          0   ; 0025
SYSINI_SYSCRITICALEXIT2     db	'&VXDNAME', 'SysCriticalExit2',     0   ; 0026
SYSINI_VMTERMINATE2	    db	'&VXDNAME', 'VMTerminate2',         0   ; 0027
SYSINI_VMNOTEXECUTEABLE2    db	'&VXDNAME', 'VMNotExecuteable2',    0   ; 0028
SYSINI_DESTROYVM2	    db	'&VXDNAME', 'DestroyVM2',           0   ; 0029
SYSINI_VMSUSPEND2	    db	'&VXDNAME', 'VMSuspend2',           0   ; 002A
SYSINI_ENDMESSAGEMODE2	    db	'&VXDNAME', 'EndMessageMode2',      0   ; 002B
SYSINI_ENDPMAPP2	    db	'&VXDNAME', 'EndPMApp2',            0   ; 002C
SYSINI_DEVICEREBOOTNOTIFY2  db	'&VXDNAME', 'DeviceRebootNotify2',  0   ; 002D
SYSINI_CRITREBOOTNOTIFY2    db	'&VXDNAME', 'CritRebootNotify2',    0   ; 002E
SYSINI_CLOSEVMNOTIFY2	    db	'&VXDNAME', 'CloseVMNotify2',       0   ; 002F
SYSINI_GETCONTENTIONHANDLER db	'&VXDNAME', 'GetContentionHandler', 0   ; 0030
SYSINI_KERNEL32INITIALIZED  db	'&VXDNAME', 'Kernel32Initialized',  0   ; 0031
SYSINI_KERNEL32SHUTDOWN     db	'&VXDNAME', 'Kernel32Shutdown',     0   ; 0032

else
.ERR
%OUT Incorrect use of SYSINI_STRINGS macro
endif
	 endm			; End of SYSINI_STRINGS macro
