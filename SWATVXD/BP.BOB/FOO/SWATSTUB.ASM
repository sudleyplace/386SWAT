;'$Header:   P:/PVCS/SWATVXD/SWATSTUB.ASV   1.18   10 Aug 1998 10:46:20   BOB  $
	 title	 SWATSTUB -- TSR Stub for SWATVXD
	 page	 78,130
	 name	 SWATSTUB

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1990-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment RDATA,	para-aligned,	use16,	public, 'PROG'
	       Program segment CODE,	para-aligned,	use16,	public, 'PROG'
	       Data    segment DATA,	byte-aligned,	use16,	public, 'PROG'
	       Group PSPGRP:
	       Data    segment PSPSEG,	dword-aligned,	use16,	public, at 0

Link requirements:  Final routine should have extension .EXE to be loaded
		    via the LINKer .DEF STUB statement.

Program derived from:  None.

Original code by:  William R. Lewis, July, 1990.

Modifications by:  None.

|

.386p
.xlist
.xcref
	 include INT2FAPI.INC	; From the DDK

	 include MASM.INC
	 include 386.INC
	 include CPUFLAGS.INC
	 include PTR.INC
	 include ASCII.INC
	 include DOSCALL.INC
	 include IOCTL.INC
	 include VIDCALL.INC
	 include DEVDRV.INC
	 include BIOSDATA.INC
	 include VCPI.INC
	 include OPCODES.INC
	include INTVEC.INC
	include OPEN.INC
.cref
	 include SWATVER.INC
.list

IOCTLRWREQUEST	 struc			; Structure for device call (3)

IOCTLREQ_SRH	 db (type SRH_STR) dup (?)	; Request header
IOCTLREQ_DATA	 db	 ?		; Reserved
IOCTLREQ_lpData  dd	 ?		; ==> buffer
IOCTLREQ_cbData  dw	 ?		; Count of bytes

IOCTLRWREQUEST	 ends			; End IOCTLRWREQUEST structure

;*******************************************************************************

PGROUP	 group	 RDATA,CODE,NDATA
PSPGRP	 group	 PSPSEG
BGROUP	 group	 BIOSDATA

PSPSEG	 segment use16 dword at 0	; Start PSPSEG segment
	 assume  cs:PSPGRP, es:PSPGRP

	 include PSP.INC		; Define equates for PSP fields

PSPSEG	 ends				; End PSPSEG segment

;*******************************************************************************

RDATA	 segment use16 public para 'PROG' ; Start RDATA segment
RDATA	 ends				; End RDATA segment

CODE	 segment use16 public para 'PROG' ; Start CODE segment
CODE	 ends				; End CODE segment

NDATA	 segment use16 public byte 'PROG' ; Start NDATA segment
NDATA	 ends				; End NDATA segment

;*******************************************************************************

RDATA	 segment use16 public para 'PROG' ; Start RDATA segment
	 assume  ds:PGROUP		; Tell the assembler

@ATTR	 equ	(DRV_ATTR_CHAR or DRV_ATTR_IOCTL or DRV_ATTR_OCREM)
	 public  DEVHDR
DEVHDR	 DD_STR <-1,@ATTR,PGROUP:DEV_STRA,PGROUP:DEV_INTR,'SWATVXD$'>

	 public DEVREQ
DEVREQ	 dd	?			; Request header save area

	 public OLD_INT_2F,SWATINFO
OLD_INT_2F	 dd	?		; Previous INT 2F vector
SWATINFO	 dd	?		; Physical address of SWATINFO

SIS		 Win386_Startup_Info_Struc <>

VXDNAME 	 db	128 dup (?)	; Output buffer for DOS function 60h

RDATA	 ends				; End RDATA segment

;*******************************************************************************

CODE	 segment			; Start CODE segment
	 assume  cs:PGROUP		; Tell the assembler

	 public  CMDTAB
CMDTAB	 label	word			; Function entry points
	 dw	PGROUP:DEV_INIT 	; 0: Initialize
	 dw	PGROUP:DEV_RETF 	; 1: Media check
	 dw	PGROUP:DEV_RETF 	; 2: Build BPB
	 dw	PGROUP:DEV_IOCTL_READ	; 3: IOCTL read 4402
	 dw	PGROUP:DEV_RETF 	; 4: Read
	 dw	PGROUP:DEV_RETF 	; 5: Non-destructive read
	 dw	PGROUP:DEV_RETF 	; 6: Input status
	 dw	PGROUP:DEV_RETF 	; 7: Input flush
	 dw	PGROUP:DEV_RETF 	; 8: Write
	 dw	PGROUP:DEV_RETF 	; 9: Non-destructive write
	 dw	PGROUP:DEV_RETF 	; A: Output status
	 dw	PGROUP:DEV_RETF 	; B: Output flush
	 dw	PGROUP:DEV_RETF 	; C: IOCTL write
	 dw	PGROUP:DEV_OPEN 	; D: Open device
	 dw	PGROUP:DEV_CLOSE	; E: Close device
	 dw	PGROUP:DEV_RETF 	; F: Reserved
	 dw	PGROUP:DEV_RETF 	; 10: Output unit busy
@NCMDTAB equ	($-CMDTAB)/2		; # of commands we support

CODE	 ends				; End CODE segment

;*******************************************************************************

NDATA	 segment			; Start NDATA segment
	 assume  ds:PGROUP		; Tell the assembler

	 public  PSP_SEG
PSP_SEG  dw	 ?			; Original PSP segment

	 public  SEPS
SEPS	 db	 ' ',TAB,'/=',0 ; Command separators (including NULL)
@NSEPS	 equ	 $-SEPS 	; Number to scan for

	 public  szSWATVXD$
szSWATVXD$	 db	'SWATVXD$', 0   ; Name for device open

MSG_SWAT_STUB	 db	'SWATVXD  -- Version '
	 db	 SWAT_VERS_H, '.', SWAT_VERS_T, SWAT_VERS_U
	 db	 ' -- A Debugger for WIN386', CR, LF
	db	SWATCOPY	; Common copyright message
	 db	 CR, LF, EOS

MSG_ABORT db	 BEL,'ออ> Caps Lock pressed, SWATVXD not installed.',CR,LF,EOS

MSG_386 	 db	'SWATVXD requires a 386 or better CPU', CR, LF, EOS
MSG_NO_INFO	 db	'SWATINFO Not Available', CR, LF, EOS
MSG_CMDLINE	 db	'Type SWATVXD /? for help', CR, LF, EOS

MSG_TWICE_DRV	 db	'SWATVXD is already installed as a device driver.'
		 db	CR, LF, EOS

MSG_TWICE	 db	'SWATVXD is already installed.  '
		 db	'You''ll only need one copy.', CR, LF, EOS

MSG_DIFFVER	 db	'The resident SWATVXD is of a different version'
		 db	CR, LF, EOS

MSG_CRLF	 db	CR, LF, EOS

MSG_NOWINK	db	'   Windows Kernel Debugger services are DISABLED in 386SWAT.'
		db	CR,LF,EOS

	public	SWTNAME,MAXNAME
SWTNAME db	'386SWAT$',0    ; 386SWAT device name
MAXNAME db	'386MAX$$',0    ; 386MAX ...

MSG_NOSWAT	db	'386SWAT not present -- not installed.',CR,LF,EOS
MSG_DUPSWAT	db	'386SWAT loads this VxD itself -- not installed.',CR,LF,EOS

MSG_VXDINFO label byte			; Help text

db 'Using the command "WIN NOSWAT" will prevent the VxD from loading', CR, LF
db 'Possible switches for the [386SWAT] section of SYSTEM.INI:', CR, LF, CR, LF
db 'SSF=d:\path\name.SSF        - Specify the WIN.SSF file', CR, LF
db 'SSFPrefix=name              - Specify device name and DDB prefix', CR, LF
db 'SWATDualDisplay             - Squirt cool info to the mono display', CR, LF

db CR, LF
db 'SWATSysCriticalInit         - 00h, Hit an INT 1 in Sys_Critical_Init', CR, LF
db 'SWATDeviceInit              - 01h, Hit an INT 1 in Device_Init', CR, LF
db 'SWATInitComplete            - 02h, Hit an INT 1 in Init_Complete', CR, LF
db 'SWATSysVMInit               - 03h, Hit an INT 1 in Sys_VM_Init', CR, LF
db 'SWATSysVMTerminate          - 04h, Hit an INT 1 in Sys_VM_Terminate', CR, LF
db 'SWATSystemExit              - 05h, Hit an INT 1 in System_Exit', CR, LF
db 'SWATSysCriticalExit         - 06h, Hit an INT 1 in Sys_Critical_Exit', CR, LF
db 'SWATCreateVM                - 07h, Hit an INT 1 in Create_VM', CR, LF
db 'SWATVMCriticalInit          - 08h, Hit an INT 1 in VM_Critical_Init', CR, LF
db 'SWATVMInit                  - 09h, Hit an INT 1 in VM_Init', CR, LF
db 'SWATVMTerminate             - 0Ah, Hit an INT 1 in VM_Terminate', CR, LF
db 'SWATVMNotExecuteable        - 0Bh, Hit an INT 1 in VM_Not_Executeable', CR, LF
db 'SWATDestroyVM               - 0Ch, Hit an INT 1 in VM_DestroyVM', CR, LF
db 'SWATVMSuspend               - 0Dh, Hit an INT 1 in VM_Suspend', CR, LF
db 'SWATVMResume                - 0Eh, Hit an INT 1 in VM_Resume', CR, LF
db 'SWATSetDeviceFocus          - 0Fh, Hit an INT 1 in Set_Device_Focus', CR, LF
db 'SWATBeginMessageMode        - 10h, Hit an INT 1 in Begin_Message_Mode', CR, LF
db 'SWATEndMessageMode          - 11h, Hit an INT 1 in End_Message_Mode', CR, LF
db 'SWATRebootProcessor         - 12h, Hit an INT 1 in Reboot_Processor', CR, LF
db 'SWATQueryDestroy            - 13h, Hit an INT 1 in Query_Destroy', CR, LF
db 'SWATDebugQuery              - 14h, Hit an INT 1 in Debug_Query', CR, LF
db 'SWATBeginPMApp              - 15h, Hit an INT 1 in Begin_PM_App', CR, LF
db 'SWATEndPMApp                - 16h, Hit an INT 1 in End_PM_App', CR, LF

db 'SWATDeviceRebootNotify      - 17h, Hit an INT 1 in Device_Reboot_Notify', CR, LF
db 'SWATCritRebootNotify        - 18h, Hit an INT 1 in Crit_Reboot_Notify', CR, LF
db 'SWATCloseVMNotify           - 19h, Hit an INT 1 in Close_VM_Notify', CR, LF
db 'SWATPowerEvent              - 1Ah, Hit an INT 1 in Power_Event', CR, LF

db 'SWATSysDynamicDeviceInit    - 1Bh, Hit an INT 1 in Sys_Dynamic_Device_Init', CR, LF
db 'SWATSysDynamicDeviceExit    - 1Ch, Hit an INT 1 in Sys_Dynamic_Device_Exit', CR, LF
db 'SWATCreateThread            - 1Dh, Hit an INT 1 in Create_Thread          ', CR, LF
db 'SWATThreadInit              - 1Eh, Hit an INT 1 in Thread_Init            ', CR, LF
db 'SWATTerminateThread         - 1Fh, Hit an INT 1 in Terminate_Thread       ', CR, LF
db 'SWATThreadNotExecuteable    - 20h, Hit an INT 1 in Thread_Not_Executeable ', CR, LF
db 'SWATDestroyThread           - 21h, Hit an INT 1 in Destroy_Thread         ', CR, LF
db 'SWATPNPNewDevnode           - 22h, Hit an INT 1 in PNP_New_Devnode        ', CR, LF
db 'SWATW32DeviceIOControl      - 23h, Hit an INT 1 in W32_DeviceIOControl    ', CR, LF
db 'SWATSysVMTerminate2         - 24h, Hit an INT 1 in Sys_VM_Terminate2      ', CR, LF
db 'SWATSystemExit2             - 25h, Hit an INT 1 in System_Exit2           ', CR, LF
db 'SWATSysCriticalExit2        - 26h, Hit an INT 1 in Sys_Critical_Exit2     ', CR, LF
db 'SWATVMTerminate2            - 27h, Hit an INT 1 in VM_Terminate2          ', CR, LF
db 'SWATVMNotExecuteable2       - 28h, Hit an INT 1 in VM_Not_Executeable2    ', CR, LF
db 'SWATDestroyVM2              - 29h, Hit an INT 1 in Destroy_VM2            ', CR, LF
db 'SWATVMSuspend2              - 2Ah, Hit an INT 1 in VM_Suspend2            ', CR, LF
db 'SWATEndMessageMode2         - 2Bh, Hit an INT 1 in End_Message_Mode2      ', CR, LF
db 'SWATEndPMApp2               - 2Ch, Hit an INT 1 in End_PM_App2            ', CR, LF
db 'SWATDeviceRebootNotify2     - 2Dh, Hit an INT 1 in Device_Reboot_Notify2  ', CR, LF
db 'SWATCritRebootNotify2       - 2Eh, Hit an INT 1 in Crit_Reboot_Notify2    ', CR, LF
db 'SWATCloseVMNotify2          - 2Fh, Hit an INT 1 in Close_VM_Notify2       ', CR, LF
db 'SWATGetContentionHandler    - 30h, Hit an INT 1 in Get_Contention_Handler ', CR, LF
db 'SWATKernel32Initialized     - 31h, Hit an INT 1 in Kernel32_Initialized   ', CR, LF
db 'SWATKernel32Shutdown        - 32h, Hit an INT 1 in Kernel32_Shutdown      ', CR, LF

db CR, LF
db 'SWATVxDIPF                  - In Sys_Critical_Init, hook the Invalid Page ', CR, LF
db '                              Fault handler', CR, LF
db 'SWATVxDROM                  - In Sys_Critical_Init, mark the Page Table', CR, LF
db '                              Entries of all VxD code segments as read-only', CR, LF
db 'SWATPL0WP                   - In Sys_Critical_Init, set the WP bit in CR0 so',CR , LF
db '                              we can trap writes into Read-Only pages at PL0.',CR , LF
db 'SWATDebugThruExit           - Call SWAT''s INIT_PROT during Critical_Exit', CR, LF
db '                              This allows debugging on the way out', CR, LF
db 'RealModeBreak=ON/OFF        - Hit an INT 1 early in RealModeInit', CR, LF
db 'Rehook123=ON/OFF            - Blast INTs 1, 2, and 3 into the IDT', CR, LF
db '                              To avoid trouble with WDEB386', CR, LF
db 'HookIRQ                     - Hook IRQ0-7 locally if SWAT hooks them', CR, LF
db 'HookVxD=DDB_Name[,#s]       - Trap at a particular VxD by name', CR, LF
db '                              <DDB_Name> is case sensitive', CR, LF
db '                              <#> specifies message numbers (optional)', CR, LF
db 'HookPM=DDB_Name,reg,#       - Trap at a particular VxD''s PM API entry', CR, LF
db '                              <reg> specifies a 16-bit register used', CR, LF
db '                              by the VxD for the function code', CR, LF
db '                              <#> specifies the functions to trap', CR, LF
db '                              HookPM=SHELL,DX,3 traps at the WINOLDAP hook', CR, LF
db CR, LF

db 'VxD filenames, DDB names, Device_ID, and their switches:', CR, LF
db 'WINA20.386   ''LA20HMA '' xxxxh',     CR, LF
db '                    NOLOW64KPAGING', CR, LF
db '                    NOLOW64KPAGINGPORT', CR, LF
db 'Debug        ''        '' 0002h',     CR, LF
db '*VPICD       ''VPICD   '' 0003h',     CR, LF
db '*VDMAD       ''VDMAD   '' 0004h',     CR, LF
db '*VTD         ''VTD     '' 0005h',     CR, LF
db '*V86MMGR     ''V86MMGR '' 0006h',     CR, LF
db '*PAGESWAP    ''PageSwap'' 0007h',     CR, LF
db '*VKD         ''VKD     '' 000Dh',     CR, LF
db '                    INITPS2MOUSEATEXIT=ON/OFF', CR, LF
db '*DOSMGR      ''DOSMGR  '' 0015h',     CR, LF
db '*WSHELL      ''SHELL   '' 0017h',     CR, LF
db '*PAGEFILE    ''PageFile'' 0021h',     CR, LF
db '386MAX.VXD   ''LoadHi  '' 001Ch',     CR, LF
db 'SWATVXD.EXE  ''SWATVXD '' 2400h',     CR, LF
db 'VDDVGA.386   ''VDD     '' 000Ah',     CR, LF
db 'VNETWARE.386 ''DOSNET  '' 001Ah',     CR, LF
db 'PM_BIOS.386  ''PMVDD   '' 2250h',     CR, LF
db CR, LF

db 'VxD Events:', CR, LF
; Events 0000h - 0016h are Windows 3.0 and up
; Events 0017h - 001Ah are Windows 3.1x and up
; Events 001Bh - 0032h are Windows 4.x and up
db '0000h  Sys_Critical_Init         ', '001Bh Sys_Dynamic_Device_Init', CR, LF
db '0001h  Device_Init               ', '001Ch Sys_Dynamic_Device_Exit', CR, LF
db '0002h  Init_Complete             ', '001Dh Create_Thread          ', CR, LF
db '0003h  Sys_VM_Init               ', '001Eh Thread_Init            ', CR, LF
db '0004h  Sys_VM_Terminate          ', '001Fh Terminate_Thread       ', CR, LF
db '0005h  System_Exit               ', '0020h Thread_Not_Executeable ', CR, LF
db '0006h  Sys_Critical_Exit         ', '0021h Destroy_Thread         ', CR, LF
db '0007h  Create_VM                 ', '0022h PNP_New_Devnode        ', CR, LF
db '0008h  VM_Critical_Init          ', '0023h W32_DeviceIOControl    ', CR, LF
db '0009h  VM_Init                   ', '0024h Sys_VM_Terminate2      ', CR, LF
db '000Ah  VM_Terminate              ', '0025h System_Exit2           ', CR, LF
db '000Bh  VM_Not_Executeable        ', '0026h Sys_Critical_Exit2     ', CR, LF
db '000Ch  Destroy_VM                ', '0027h Vm_Terminate2          ', CR, LF
db '000Dh  VM_Suspend                ', '0028h Vm_Not_Executeable2    ', CR, LF
db '000Eh  VM_Resume                 ', '0029h Destroy_VM2            ', CR, LF
db '000Fh  Set_Device_Focus          ', '002Ah VM_Suspend2            ', CR, LF
db '0010h  Begin_Message_Mode        ', '002Bh End_Message_Mode2      ', CR, LF
db '0011h  End_Message_Mode          ', '002Ch End_PM_App2            ', CR, LF
db '0012h  Reboot_Processor          ', '002Dh Device_Reboot_Notify2  ', CR, LF
db '0013h  Query_Destroy             ', '002Eh Crit_Reboot_Notify2    ', CR, LF
db '0014h  Debug_Query               ', '002Fh Close_VM_Notify2       ', CR, LF
db '0015h  Begin_PM_App              ', '0030h Get_Contention_Handler ', CR, LF
db '0016h  End_PM_App                ', '0031h Kernel32_Initialized   ', CR, LF
db '0017h  Device_Reboot_Notify      ', '0032h Kernel32_Shutdown      ', CR, LF
db '0018h  Crit_Reboot_Notify        ', CR, LF
db '0019h  Close_VM_Notify           ', CR, LF
db '001Ah  Power_Event               ', CR, LF

db EOS

NDATA	 ends				; End NDATA segment

;*******************************************************************************

STACK	 segment byte stack 'STACK'     ; Start STACK segment

	 db	 512 dup (?)		; Local stack

STACK	 ends				; End STACK segment

;*******************************************************************************

CODE	 segment			; Start CODE segment
	 assume  cs:PGROUP

DEV_STRA proc	 far			; Strategy entry point
	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

	 assume  ds:PGROUP		; Tell a white lie
CSOVR	 mov	 <DEVREQ.VSEG,es>	; Save ==> to request header
CSOVR	 mov	 <DEVREQ.VOFF,bx>	; ...
	 assume  ds:nothing		; Retract nose

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
DEV_STRA endp				; End DEV_STRA procedure

DEV_INTR proc	 far			; Interrupt entry point
	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

	 REGSAVE <ax,bx,cx,dx,si,di,ds,es> ; Save registers

	 mov	 ax,cs			; Get PGROUP segment
	 mov	 ds,ax			; Address it
	 assume  ds:PGROUP		; Tell the assembler

	 sub	 ah,ah			; Clear high order byte
	 mov	 al,es:[bx].SRH_CCD	; Get command
	 cmp	 ax,@NCMDTAB		; Higher than we support?
	 ja	 short INT_ERR		; Return error

	 REGSAVE  <ax,bx,es>		; Save RH pointer
	 shl	 ax,1			; Index table of words
	 mov	 si,ax			; Address table entry
	 call	 CMDTAB[si]		; Call selected command
	 REGREST  <es,bx,ax>		; Restore RH pointer
	 jc	 short INT_ERR		; Return error

	 STATUS  DONE,NOERROR		; Set status word (done, no error)
	 jmp	 short INT_EXIT 	; Rejoin common exit code

INT_ERR:
	 cmp	 ax,0			; Is it INIT?
	 jne	 short INT_ERR1 	; Skip if not

	 mov	 DEVHDR.DD_ATTR,0 ; Bug in DOS doesn't allow char devices to
				; fail initialization -- convert to block device
	 mov	 es:[bx].INIT_UNITS,0 ; No units defined
	 mov	 es:[bx].INIT_END_VEC.VOFF,0 ; End offset of 0
	 mov	 es:[bx].INIT_END_VEC.VSEG,cs ; Mark as ending address
INT_ERR1:
	 STATUS  DONE,ERROR,ERR_UNK_CMD ; Return error

INT_EXIT:
	 REGREST <es,ds,di,si,dx,cx,bx,ax> ; Restore registers
	 assume  ds:nothing,es:nothing

	 ret				; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing, gs:nothing, ss:nothing
DEV_INTR endp				; End DEV_INTR procedure

DEV_RETF proc	 near			; Interrupt entry point
	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

	 clc				; Normal return indicator
	 ret				; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing, gs:nothing, ss:nothing
DEV_RETF endp				; End DEV_RETF procedure
	 page
DEV_IOCTL_READ proc near		; IOCTL read (4402h style)
	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

On entry:
ES:BX ==> request header

|

	 REGSAVE <ax,cx,di,es>		; Save registers

	 mov	 cx,es:[bx].IOCTLREQ_cbData ; Size of caller's buffer
	 les	 di,es:[bx].IOCTLREQ_lpData ; ES:DI ==> caller's buffer

	 cmp	 es:[di].LO,1		; Function 1 -- return SWATINFO PTR
	 jne	 short IOCTL_4402_ERROR ; Error if not

	 cmp	 cx,4			; Size of DWORD (physical address)?
	 jne	 short IOCTL_4402_ERROR ; Error if not

	 cld				; Autoincrement
	 mov	 ax,SWATINFO.ELO	; Transfer SWATINFO to caller's buffer
	 stosw				; ...
	 mov	 ax,SWATINFO.EHI	; ...
	 stosw				; ...

	 clc				; Normal return indicator
	 jmp	 short IOCTL_4402_EXIT	; Rejoin common code

IOCTL_4402_ERROR:
	 stc				; Error return indicator

IOCTL_4402_EXIT:
	 REGREST <es,di,cx,ax>		; Restore registers
	 assume  es:nothing		; Tell the assembler

	 ret				; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing, gs:nothing, ss:nothing
DEV_IOCTL_READ endp			; End DEV_IOCTL_READ procedure
	 page
DEV_OPEN proc	 near			; Open device
	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

On entry:
ES:BX ==> request header

|

	 clc				; Normal return indicator

	 ret				; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing, gs:nothing, ss:nothing
DEV_OPEN endp				; End DEV_OPEN procedure

DEV_CLOSE proc	 near			; Close device
	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

On entry:
ES:BX ==> request header

|

	 clc				; Normal return indicator

	 ret				; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing, gs:nothing, ss:nothing
DEV_CLOSE endp				; End DEV_CLOSE procedure

INT_2F	 proc	 far			; Local INT_2F handler
	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

	 cmp	 ax,0B405h		; Installation check?
	 jne	 short @F		; Nope, skip

	 cmp	 bx,504Bh		; Double check?
	 jne	 short @F		; Nope, skip

	 mov	 ax,4BB4h		; Indicate we're here

	 mov	 bx,SWAT_VER		; Return version # in BX

	 iret				; Return to caller
@@:
	 cmp	 ax,1605h		; Enhanced Windows startup?
	 je	 short @F		; Yup, skip chain to previous handler

	 jmp	 OLD_INT_2F		; Chain to previous handler

@@:
	 pushf				; Setup for fake interrupt
	 cli				; ...
	 call	 OLD_INT_2F		; Chain to previous handler

	 assume  ds:PGROUP		; Tell a white lie
CSOVR	 mov	 <SIS.SIS_Next_Ptr.VOFF,bx> ; Chained INT 2F BX
CSOVR	 mov	 <SIS.SIS_Next_Ptr.VSEG,es> ; ...	   ES

CSOVR	 mov	 <SIS.SIS_Reference_Data.VSEG,cs> ; Segment of INT_67
CSOVR	 mov	 <SIS.SIS_Reference_Data.VOFF,offset PGROUP:INT_67> ; Offset ...

CSOVR	 mov	 <SIS.SIS_Instance_Data_Ptr.VOFF,0> ; ... and offset
CSOVR	 mov	 <SIS.SIS_Instance_Data_Ptr.VSEG,0> ; Segment of inst list
	 assume  ds:nothing		; Retract nose

	 push	 cs			; MOV ES,CS
	 pop	 es			; ...
	 assume  es:PGROUP		; Tell the assembler

	 lea	 bx,PGROUP:SIS		; ES:BX ==> our Win3SIS

	 public  INT_2F_IRET
INT_2F_IRET:
	 assume  es:nothing		; Tell the assembler
	 iret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
INT_2F	 endp			; End INT_2F procedure

INT_67	 proc	 far			; Local INT_67 handler
	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Windows allows VxDs to hook V86 interrupts (like Int 67h) via
Hook_V86_Int_chain.  However, the VxD's hook procedure will never
get called unless the interrupt points to a valid address.  Here
we check for VCPI debugger calls, and pass everything else to the
previous handler if one was installed.

This is not needed outside of Windows, where we can rely on
SWAT hooking the services out of the IDT.

|

	 db		 @OPCOD_JMPF ; Far jump immediate
	 dd		 PGROUP:INT_2F_IRET

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
INT_67	 endp			; End INT_67 procedure

CTAIL	 label	 byte		; Last byte in resident PGROUP

IZITWS	 proc	 far			; Is AL a command separator?
	 assume  ds:nothing,es:PGROUP,fs:nothing, gs:nothing, ss:nothing
COMMENT|

If AL is a command separator (' ', TAB, /, =, CR) return ZF=1.

|

	 REGSAVE <cx,di>	; Save

	 lea	 di,SEPS	; PGROUP:DI ==> separator list
	 mov	 cx,@NSEPS	; Number of separators to scan for
  repne  scas	 SEPS[di]	; Search for AL

	 REGREST <di,cx>	; Restore

	 ret			; Return to caller with ZF significant

	 assume  ds:nothing,es:nothing,fs:nothing, gs:nothing, ss:nothing
IZITWS	 endp				; End IZITWS procedure

SKIP_WHITE proc  near			; Skip whitespace characters
	 assume  ds:nothing,es:nothing,fs:nothing, gs:nothing, ss:nothing
COMMENT|

On entry:
DS:SI ==> command line

On exit:
AL =	 First non-whitespace character found
DS:SI ==> first non-whitespace character on line

|

	 REGSAVE <es>		; Save

	 mov	 ax,seg PGROUP	; Prepare to address PGROUP
	 mov	 es,ax		; Address for IZITWS
	 assume  es:PGROUP	; Tell the assembler

@@:
	 lods	 ds:[si].LO	; Get next character
	 call	 IZITWS 	; Is it a command separator?
	 je	 short @B	; Go around again if so

	 dec	 si		; Back off to character in AL

	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing, gs:nothing, ss:nothing
SKIP_WHITE endp 			; End SKIP_WHITE procedure

FIND_WHITE proc  near			; Skip non-whitespace characters
	 assume  ds:nothing,es:nothing,fs:nothing, gs:nothing, ss:nothing
COMMENT|

On entry:
DS:SI ==> command line

On exit:
AL =	 First command separator found
DS:SI ==> first whitespace character on line

|

	 REGSAVE <es>		; Save

	 mov	 ax,seg PGROUP	; Prepare to address PGROUP
	 mov	 es,ax		; Address for IZITWS
	 assume  es:PGROUP	; Tell the assembler

@@:
	 lods	 ds:[si].LO	; Get next character
	 call	 IZITWS 	; Is it a command separator?
	 jne	 short @B	; Go around again if not

	 dec	 si		; Back off to character in AL

	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing, gs:nothing, ss:nothing
FIND_WHITE endp 			; End FIND_WHITE procedure

CHECK_CAPS proc  near			; Check Caps Lock
	 assume ds:PGROUP,es:nothing,fs:nothing, gs:nothing, ss:nothing
COMMENT|

If Caps lock is on, assume user wants to abort installation.
Display error message and return with CF set.

On entry:
Nothing.

On exit:
CF=1 if Caps Lock was pressed.

|

	 REGSAVE <ax,dx>		; Save

	 mov	 ax,seg BIOSDATA	; Get BIOS data area

	 push	 ds			; Save DS
	 mov	 ds,ax			; Use DS for BIOS data area
	 assume  ds:BGROUP		; Tell the assembler
	 mov	 al,KB_FLAG		; Get keyboard flags
	 pop	 ds			; Restore
	 assume ds:PGROUP		; Tell the assembler

	 test	 al,mask $KB_CAPL	; Is CAPS LOCK on?
	 jz	 short @F		; No, so don't break

	 DOSCALL @STROUT,MSG_SWAT_STUB	; Display greeting
	 int	 1			; Call SWAT (if present)
					; (or lock if DBLSPACE present)
	 DOSCALL @STROUT,MSG_ABORT	; Display "Caps Lock pressed..."

	 stc				; Indicate abort requested
@@:

	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume ds:nothing,es:nothing,fs:nothing, gs:nothing, ss:nothing
CHECK_CAPS endp 			; End CHECK_CAPS procedure

DEV_INIT proc	 near			; Driver initialization
	 assume  ds:PGROUP,es:nothing,fs:nothing, gs:nothing, ss:nothing
COMMENT|

On entry:
ES:BX ==> request header

|

	 cld				; Set forward direction
	 REGSAVE  <ax,dx,si,ds> 	; Save

	 call	 CHECK_CAPS		; Check for caps lock pressed
	 jc	 short INIT_DRV_EXIT	; Return with CF set if so

	 lds	 si,es:[bx].INIT_CMD_VEC ; Address command line
	 assume  ds:nothing		; Tell the assembler

	 call	 SKIP_WHITE		; Skip any leading whitespace
	 mov	 cx,si			; ==> start of filespec
	 call	 FIND_WHITE		; Advance SI to end of string
	 xchg	 cx,si			; Length of filespec
	 sub	 cx,si			; ... into CX

	 REGSAVE <es>			; Save registers

	 push	 cs			; MOV ES,CS
	 pop	 es			; ...
	 assume  es:PGROUP		; Tell the assembler

	 lea	 di,VXDNAME		; Pointer to path buffer
     rep movsb				; Copy filespec to resident buffer

	 REGREST <es>			; Restore registers
	 assume  es:nothing		; Tell the assembler

	 push	 cs			; MOV DS,CS
	 pop	 ds			; ...
	 assume  ds:PGROUP		; Tell the assembler

	 DOSCALL @STROUT,MSG_SWAT_STUB	; Display greeting

	call	CHECK_PSWAT		; See if SWAT is present
	jc	short INIT_DRV_ERR	; Jump if not

	 call	 GET_SWATINFO		; Get ==> SWATINFO
	 call	 SETUP_1605		; Prepare VXD path for the INT 2Fh 1605

	 mov	 es:[bx].INIT_END_VEC.VOFF,offset cs:CTAIL
	 mov	 es:[bx].INIT_END_VEC.VSEG,cs
	 clc				; Normal return indicator

	jmp	short INIT_DRV_EXIT	; Join common code

INIT_DRV_ERR:
	mov	DEVHDR.DD_ATTR,0 ; Bug in DOS doesn't allow char devices to
				; fail initialization -- convert to block device
	mov	es:[bx].INIT_UNITS,0 ; No units defined
	mov	es:[bx].INIT_END_VEC.VSEG,cs ; Mark as ending address
	mov	es:[bx].INIT_END_VEC.VOFF,0 ; ...

	stc			; Mark as in error
INIT_DRV_EXIT:
	 REGREST  <ds,si,dx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler

	 ret				; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing, gs:nothing, ss:nothing
DEV_INIT endp				; End DEV_INIT procedure

	 public  TsrStart
TsrStart proc	 near			; Entry point if loaded as an EXE
	 assume  ds:nothing, es:PSPSEG, fs:nothing, gs:nothing, ss:nothing

	 mov	 ax,PGROUP		; Establish addressibility to PGROUP
	 mov	 ds,ax			; ... via DS
	 assume  ds:PGROUP		; Tell the assembler

	 mov	 PSP_SEG,es		; Save PSP segment

	 DOSCALL @STROUT,MSG_SWAT_STUB	; Display greeting

	 call	 Check386		; Set carry if not a 386 or better
	 jnc	 short @F		; Skip error

	 DOSCALL @STROUT,MSG_386	; Tell 'em we'll need a 386 or better
SS_XIT:
	 mov	 al,3			; Return code
	 DOSCALL @EXITRC		; Terminate process w/ error code in AL
@@:
	 call	 SETUP_OPTIONS		; Setup options
	 jc	 SS_XIT 		; Exit w/o going resident

	call	CHECK_PSWAT		; See if SWAT is present
	jc	SS_XIT			; Jump if not

; Check for SWATVXD$ device already installed
	 mov	 al,00h 		; Readonly
	 DOSCALL @OPENF2,szSWATVXD$	; Open SWATVXD$
	 jc	 short XDEVICE		; Jump if not installed

	 mov	 bx,ax			; Copy handle to proper register
	 mov	 al,00h 		; Get device info into DX
	 DOSCALL @IOCTL2		; I/O Control for devices, handle in BX
	 jc	 short XDEVICE0 	; Jump if not installed

	 test	 dx,@IOCTL_DEV		; Is it a device driver?
	 jz	 short XDEVICE0 	; Jump if not installed

	 DOSCALL @STROUT,MSG_TWICE_DRV	; Device driver already installed
	 mov	 al,3			; Return code
	 DOSCALL @EXITRC		; Return to the DOS
XDEVICE0:
	 DOSCALL @CLOSF2		; Close file, handle in BX
XDEVICE:

; Check for SWATVXD TSR already installed
	 mov	 ax,0B405h	; Recognized by SWATVXD for installation check
	 mov	 bx,504Bh		; Double check subcode
	 int	 2Fh			; DOS multiplexor services

	 cmp	 ax,4BB4h		; Is the SWATVXD stub repsonding?
	 jne	 short XTSR		; No, skip the complaining

	 cmp	 bx,SWAT_VER		; Is it the same version?
	 je	 short @F		; Yes, skip extra complaint

	 DOSCALL @STROUT,MSG_DIFFVER	; Tell 'em we're not the same version
@@:
	 DOSCALL @STROUT,MSG_TWICE	; Tell 'em we're already installed
	 DOSCALL @STROUT,MSG_CMDLINE	; Complain and show 'em the right way

	 mov	 al,3			; Return code
	 DOSCALL @EXITRC		; Return to the DOS
XTSR:

; Setup ES:DI pointing to environment strings
	 REGSAVE <ds,es>		; Save

	 mov	 es,PSP_ENVIR_PTR	; Get segment of environment strings
	 assume  es:nothing		; Tell the assembler

; Zoom through environment strings to find program name
	 cld				; Forward
	 sub	 al,al			; Byte for which to search
	 sub	 di,di			; Starting offset
FEP_EVN:
	 mov	 cx,8000h		; Maximum size of environment
   repnz scasb				; Find terminating NUL

	 cmp	 es:[di].LO,0		; Last string?
	 jne	 short FEP_EVN		; Loop back if more strings to skip

	 add	 di,1+2 		; Advance source pointer past extra NULL
					; ... and string count

	 lea	 si,VXDNAME		; Pointer to path buffer

	 mov	 ax,es			; AX is PSP segment
	 mov	 ds,ax			; DS:DI ==> relative path and filename
	 assume  ds:nothing		; Tell the assembler

	 mov	 ax,cs			; AX is code segment
	 mov	 es,ax			; ES:SI ==> output buffer
	 assume  es:nothing		; Tell the assembler

	 xchg	 si,di		; DS:SI ==> ASCIZ relative path and filename
					; ES:DI ==> Output buffer

	 DOSCALL @FIXPTH		; Resolve path to canonical path
	 jnc	 short @F		; Jump if worked

	 int	 1			; Call the debugger
@@:
	 REGREST <es,ds>		; Restore
	 assume  ds:PGROUP, es:PSPGRP	; Tell the assembler

	 call	 SETUP_1605	; Prepare the VXD path for the INT 2Fh 1605

; Free the environment
	 mov	 es,PSP_SEG		; Save original PSP address
	 assume  es:PSPGRP		; Tell the assembler

	 mov	 es,PSP_ENVIR_PTR	; Segment of environment strings
	 assume  es:nothing		; Tell the assembler

	 DOSCALL @RELMEM		; Free the environment

	 mov	 es,PSP_SEG		; Save original PSP address
	 assume  es:PSPGRP		; Tell the assembler

	 sub	 ax,ax			; A handy NULL
	 mov	 PSP_ENVIR_PTR,ax	; Zero the segment

; If SWAT has NOWINK set, tell 'em so

	mov	ax,seg INTVEC		; Get segment of IVT
	mov	es,ax			; Address it
	assume	es:INTVEC		; Tell the assembler about it

	cmp	INT00_VEC[68h*(type INT00_VEC)],0 ; Izit invalid?
	je	short @F		; Jump if not

	mov	ah,43h			; Get function code for debugger presence
	int	68h			; Request WKD services

	cmp	ax,0F386h		; Izit present?
	je	short @F		; Jump if so

	DOSCALL @STROUT,MSG_NOWINK	; Tell 'em no WKD today
@@:

; Terminate and stay resident
	 lea	 dx,CTAIL+15		; Get last address in program rounded up
	 shr	 dx,4			; Convert from bytes to paras
	 add	 dx,10h 		; Plus 256 bytes for PSP

	 sub	 al,al			; Normal return code
	 DOSCALL @KEEPRC		; Terminate process and remain resident

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
TsrStart endp				; End of TsrStart program

	 public  SETUP_1605
SETUP_1605 proc  near		; Prepare the VXD path for the INT 2Fh 1605
	 assume  ds:PGROUP, es:nothing, fs:nothing, gs:nothing, ss:nothing

	 REGSAVE <ax,bx,dx,ds,es>	; Save caller's register

	 lea	 bx,VXDNAME		; Get pointer to name of VxD
	 mov	 SIS.SIS_Virt_Dev_File_Ptr.VOFF,bx ; Save offset
	 mov	 SIS.SIS_Virt_Dev_File_Ptr.VSEG,cs ; Save segment

; Get and save original INT 2Fh vector
	 mov	 al,2Fh 		; Windows API interrupt #
	 DOSCALL @GETINT		; Get interrupt vector in AL to ES:BX
	 assume  es:nothing		; Tell the assembler about it

	 mov	 OLD_INT_2F.VOFF,bx	; Save the offset
	 mov	 OLD_INT_2F.VSEG,es	; ... and the segment

; Set new INT 2Fh vector
	 push	 cs			; MOV DS,CS
	 pop	 ds			; ...
	 assume  ds:PGROUP		; Tell the assembler

	 lea	 dx,PGROUP:INT_2F	; Offset of our INT 2F handler
	 mov	 al,2Fh 		; Windows API interrupt #
	 DOSCALL @SETINT		; Set interrupt vector in AL to DS:DX

	 REGREST <es,ds,dx,bx,ax>	; Restore
	 assume  ds:PGROUP, es:nothing	; Tell the assembler

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
SETUP_1605 endp 		; End SETUP_1605 procedure

	 public  SETUP_OPTIONS
SETUP_OPTIONS proc near 	; Parse command line options
	 assume  ds:PGROUP, es:PSPGRP, fs:nothing, gs:nothing, ss:nothing

	 REGSAVE <ax,bx,cx,si,di>	; Save caller's registers

	 mov	 cl,PSP_PARM_COUNT	; Get length of arguments
	 sub	 ch,ch			; Convert length to word
	 lea	 si,PSP_PARM_STRING	; Get pointer to arguments

	 jcxz	 SETUP_OPTIONS_XITOK	; Done with options
SETUP_OPTIONS_NXT:
	 mov	 al,PSPGRP:[si] 	; Get next character
	 inc	 si			; Advance past that char

	 cmp	 al,' '                 ; Is it a space?
	 je	 short SETUP_OPTIONS_SKP ; Skip over it if so
	 cmp	 al,TAB 		; Is it a TAB?
	 je	 short SETUP_OPTIONS_SKP ; Skip over it if so

	 cmp	 al,'/'                 ; Is it the switch char?
	 je	 short @F		; Yes, check the option character

	 cmp	 al,'-'                 ; Is it the alternate switch char?
	 jne	 short SETUP_OPTIONS_ERR ; Show 'em the error and return
@@:
	 dec	 cl			; Account for character consumed
	 jcxz	 short SETUP_OPTIONS_ERR ; Error if all used

	 mov	 al,PSPGRP:[si] 	; Get next cmdline character
	 inc	 si			; Advance past cmdline character

; Inspect the option
	 cmp	 al,'?'                 ; Is it the option query?
	 jne	 short @F		; Nope

	 call	 SHOW_INFO		; Show 'em switches for various VxDs

	 stc				; Force termination
	 jmp	 short SETUP_OPTIONS_XIT ; Join error exit code

@@:
	 jmp	 short SETUP_OPTIONS_ERR ; Bad option

SETUP_OPTIONS_SKP:
	 loop	 SETUP_OPTIONS_NXT	; Go get next options

	 jmp	 short SETUP_OPTIONS_XITOK ; Join normal exit code

SETUP_OPTIONS_ERR:
	 DOSCALL @STROUT,MSG_CMDLINE	; Complain and show 'em the right way

	 stc				; Error indicator
	 jmp	 short SETUP_OPTIONS_XIT ; Join common exit code

SETUP_OPTIONS_XITOK:
	 clc				; Indicate all went well
SETUP_OPTIONS_XIT:
	 REGREST <di,si,cx,bx,ax>	; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
SETUP_OPTIONS endp		; End SETUP_OPTIONS procedure

SHOW_INFO proc near			; Tell 'em useful info about VxDs
	 assume  ds:PGROUP, es:nothing, fs:nothing, gs:nothing, ss:nothing

	 REGSAVE <ax,dx>		; Save caller's registers

	 DOSCALL @STROUT,MSG_VXDINFO	; Show 'em the switches

	 REGREST <dx,ax>		; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
SHOW_INFO endp				; End SHOW_INFO procedure
	 page
Check386 proc near			; Ensure we're on a 386 or better
	 assume  ds:PGROUP, es:nothing, fs:nothing, gs:nothing, ss:nothing

	 REGSAVE <ax>			; Save caller's registers

	 push	 sp			; Test for 386
	 pop	 ax			; ...
	 cmp	 ax,sp			; ...
	 jne	 short EXIT_ERROR	; Isn't a 286 or 386

	 pushf				; Save original flags

	 push	 (mask $IOPL)		; Get IOPL bits in flags
	 popf				; Pop 'em into the flags
	 pushf				; Push flags onto stack
	 pop	 ax			; Pop 'em into a register

	 popf				; Restore original flags

	 test	 ax,(mask $IOPL)	; Any bits stick?
	 jnz	 short EXIT		; It's a 386 if so (note carry clear)

EXIT_ERROR:
	 stc
EXIT:
	 REGREST <ax>			; Restore caller's registers
	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
Check386 endp				; End Check386 procedure
	 page
GET_SWATINFO proc near		; Get address of SWATINFO into EDX for ref data
	 assume  ds:PGROUP, es:nothing, fs:nothing, gs:nothing, ss:nothing

; Do special extended VCPI call to get SWATINFO

	 REGSAVE <ax,edx>		; Save caller's registers

	 sub	 edx,edx		; Assume SWAT isn't loaded

	 VCPICALL @VCPI_DBGINF		; Get Debugger Information address
					; EDX is returned as reference data

	 mov	 SWATINFO,edx		; Save for INT 2Fh API later

	 or	 edx,edx		; Did VCPI_DBGINF return an address?
	 jnz	 short @F		; Skip error stuff if so

	 DOSCALL @STROUT,MSG_NO_INFO	; Tell 'em SWATINFO isn't available

	 stc				; Error indicator

	 jmp	 short GET_SWATINFO_XIT ; Rejoin common exit code
@@:
	 clc				; Normal return indicator
GET_SWATINFO_XIT:
	 REGREST <edx,ax>		; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
GET_SWATINFO endp			; End GET_SWATINFO procedure
	 NPPROC  CHECK_PSWAT -- Check On Preceding Device SWAT
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on preceding device SWAT.

On exit:

CF	=	0 if SWAT is present
	=	1 if not

|

	REGSAVE <ax,bx,cx,dx>	; Save registers

; Attempt to open the device '386SWAT$'

	mov	cx,1		; Assume device SWAT
	mov	al,@OPEN_R	; Code for read-only access
	DOSCALL @OPENF2,SWTNAME ; Attempt to open the device
	jnc	short CHECK_PSWAT1 ; Jump if present

; Attempt to open the device '386MAX$$'

	mov	al,@OPEN_R	; Code for read-only access
	DOSCALL @OPENF2,MAXNAME ; Attempt to open the device
	jc	near ptr CHECK_PSWAT_ERR ; Jump if not present

	xor	cx,cx		; Mark as load SWAT
CHECK_PSWAT1:
	mov	bx,ax		; Copy to handle register

	mov	al,0		; Code to get device info
	DOSCALL @IOCTL2 	; Return with DX = device info
	pushf			; Save CF from DOSCALL
	DOSCALL @CLOSF2 	; Close the file
	popf			; Restore
	jc	near ptr CHECK_PSWAT_ERR ; Jump if IOCTL failed

	test	dx,@IOCTL_DEV  ; Izit a device?
	jz	near ptr CHECK_PSWAT_ERR ; Jump if not

; See if there's a debugging host present

	VCPICALL @VCPI_DPRES	; Check on VCPI debugging host
				; Return with AH = 0 if present
				;	 (BH,BL) = version #
	cmp	ah,0		; Izit present?
	jne	short CHECK_PSWAT_ERR ; Jump if not

; If the version # of SWAT is >= 6 and it's device SWAT,
; don't install as SWAT loads this VxD automatically

	jcxz	CHECK_PSWAT_EXIT ; Jump if load SWAT (note CF=0)

	cmp	bh,6		; Izit version 6 or later?
	cmc			; Complement so (CF == 0) ==> (ver < 6)
	ja	short CHECK_PSWAT_EXIT ; Jump if not (note CF=0)

	DOSCALL @STROUT,MSG_DUPSWAT ; Tell 'em SWAT'll load us

	jmp	short CHECK_PSWAT_ERRCOM ; Join common error code

CHECK_PSWAT_ERR:
	DOSCALL @STROUT,MSG_NOSWAT ; Tell 'em we're lonely
CHECK_PSWAT_ERRCOM:
	stc			; Mark as not present
CHECK_PSWAT_EXIT:
	REGREST <dx,cx,bx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PSWAT endp		; End CHECK_PSWAT procedure

CODE	 ends				; End CODE segment

	 end	 TsrStart		; End module, defining start address
