;'$Header:   P:/PVCS/SWATVXD/SWAT_RMI.ASV   1.14   10 Aug 1998 10:46:28   BOB  $
	 title	 SWAT_RMI -- Real Mode Init for SWATVXD
	 page	 58,122
	 name	 SWAT_RMI

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

	 include MASM.INC	; From Bob's standard includes
	 include 386.INC
	 include PTR.INC
	 include CPUFLAGS.INC
	 include ASCII.INC
	 include DEVMAC.INC
	 include DOSCALL.INC
	 include OPCODES.INC
	 include IOCTL.INC
	 include MAXDEV.INC
	 include VCPI.INC
	 include XMS.INC

	 include WIN3PAGE.INC

	 include QMAX_CTL.INC	; From 386MAX
	 include QMAX_GLB.INC
	 include SWAT_SSF.INC

	 include SWAT_MAC.INC
	 include SWATVER.INC	; Version # extrns
	 include SWAT_RMI.INC	; Bit definitions for RMI_FLAG
.list

PSPGRP	 group	 PSPSEG

PSPSEG	 segment dword use16 at 0	; Begin PSPSEG segment
	 assume  cs:PSPGRP, es:PSPGRP	; Tell the assembler

	 include PSP.INC		; Define and skip over PSP fields

	 assume  nothing		; Tell the assembler
PSPSEG	 ends				; End PSPSEG segment

VxD_REAL_INIT_SEG

	 assume  es:nothing

	 extrn	 MSG_RMI:byte
	 extrn	 MSG_DUP_DEVICE:byte
	 extrn	 MSG_NOINSTALL:byte

	 extrn	 MSG_NO_SWAT:byte
	 extrn	 MSG_NO_INFO:byte

	 extrn	 MSG_XMS_VER:byte
	 extrn	 MSG_XMS_VER_X1:byte, MSG_XMS_VER_X2:byte, MSG_XMS_VER_X3:byte

	 extrn	 MSG_IDTR:byte, MSG_IDTR_BASE:byte, MSG_IDTR_LIM:byte

	 extrn	 MSG_MAXVER:byte, MSG_MAXVER_X:byte
	 extrn	 MSG_NOMAX:byte
	 extrn	 MSG_MAXOFF:byte

	 extrn	 MSG_PAK:byte
	 extrn	 MSG_PAKORESC:byte
	 extrn	 MSG_CRLF:byte

	 extrn	 MSG_IMPORT_OPEN:byte
	 extrn	 MSG_IMPORT_IOCTL1:byte
	 extrn	 MSG_IMPORT_IOCTL2:byte
	 extrn	 MSG_IMPORT_IOCTL3:byte
	 extrn	 MSG_IMPORT_NOTCHR:byte

	 extrn	 MSG_IMPORT_NULL:byte
	 extrn	 MSG_IMPORT_INFO:byte
	 extrn	 MSG_IMPORT_INFO0:byte
	 extrn	 MSG_IMPORT_INFO1:byte
	 extrn	 MSG_IMPORT_INFO2:byte

	 extrn	 MSG_SYMB_INFO:byte
	 extrn	 MSG_SYMB_INFO1:byte
	 extrn	 MSG_SYMB_INFO2:byte
	 extrn	 MSG_SYMB_NONE:byte

	 public  RMI_FLAG
RMI_FLAG	 dw	0	; Real mode init flags

	 public  LOADER_FLAGS
LOADER_FLAGS	 dw	?	; BX upon entry to real mode init

	 public  LOADER_SVC
LOADER_SVC	 dd	?	; FAR CALL to loader service

	 public  RMI_REFDATA
RMI_REFDATA	 dd	?	; Reference data from our loader

	 public  VMM_VERSION
VMM_VERSION	 dw	?	; WIN386 version #

	 public  ENVIR_SEG
ENVIR_SEG	 dw	?	; Segment of WIN386 environment

STR_386SWAT	 db	'386SWAT', 0            ; SYSTEM.INI section
STR_RMBRK	 db	'REALMODEBREAK', 0      ; SYSTEM.INI keyname
STR_SSF 	 db	'SSF', 0                ; SYSTEM.INI keyname

@OEM_IOCTL equ	 <'386MAX'>     ; IOCTL name for 386MAX.SYS

	 public  DEVNAME
	 DEVMAC  @OEM_IOCTL
DEVNAME  db	 @DEVNAME, 0	; Name for OPEN and IOCTL

	 public  EMMNAME
EMMNAME  db	 'EMMXXXX0', 0  ; Name to open EMS device

	 public  szSWATVXD$
szSWATVXD$	 db	'SWATVXD$', 0   ; Name for device open

	 public  DEV_HNDL
DEV_HNDL dw	 0		; Handle to above device

	 public  SWATINFO
SWATINFO	 dd	0		; Physical address of SWATINFO

	 public  XMS
XMS	 dd	 0		; XMS entry point FAR PTR

	 public  RM_IDTR
RM_IDTR  DTR_STR <0,0>		; Copy of IDTR

	 public  INFO_CTL, INFO, INFOSIZE
	 include QMAXINFO.INC
INFO_CTL db	 ?		; IOCTL type
INFO	 INFO_STR <>
INFOSIZE equ	 size INFO_STR

@PAGING_IMPORT_INFO	equ	1 ; Return import information

	 public  PAGING_IMPORT, PAGING_IMPORT_LEN
PAGING_IMPORT	 EMM_Import_IOCTL_Data <>
PAGING_IMPORT_LEN equ $-PAGING_IMPORT ; Length of above structure

RMI_HEX  db	 '0123456789ABCDEF' ; Conversion table for RMI_TOHEX

PATH_BUF	 db	128 dup (?)	; Space for filenames

; Data used by LOAD_SSF

	 public  LSSF_BUF, LSSF_BUFP
@LSSF_BUFSIZ	 equ	4096	; Size of .SSF read buffer
LSSF_BUF	 db	(@LSSF_BUFSIZ+15) dup (?) ; .SSF read buffer
LSSF_BUFP	 dw	?	; Pointer to above buffer

	 public  LSSF_FH, LSSF_CNT, LSSF_SYMCNT, LSSF_SYMSUB, LSSF_XLAT
LSSF_FH 	 dw	?	; File handle used by LOAD_SSF
LSSF_FLAG	 dw	0	; Flags (see @LSSF_xxx below)
LSSF_CNT	 dw	?	; Bytes read from .SSF file into LSSF_BUF
LSSF_SYMCNT	 dd	?	; Number of records according to file header
LSSF_SYMTOT	 dd	?	; Number of records according to file header
LSSF_SYMSUB	 dw	?	; Subtotal for number of records
LSSF_XLAT	 dw	?	; Fixup for V86 mode symbols

@LSSF_FLUSH equ 8000h		; Flush the symbol table

SYM_STR  struc			; Symbol record structure

SYM_OFFSET dd	 ?		; Symbol offset
SYM_SEGSEL dw	 ?		; Segment/selector
SYM_FLAGS dw	 ?		; Flags
SYM_GROUP dw	 ?		; Group number (if WSG used)
SYM_SYMLEN db	 ?		; Length byte for name

SYM_STR  ends			; End SYM_STR structure

SYM_SYMNAME equ SYM_SYMLEN[1].LO ; First byte of name

; Flags used for SYM_FLAGS

SYMFL	record	 $SYMFL_VM:1,$SYMFL_TYP:5,$SYMFL_DEL:1,$SYMFL_RES:9
@SYMFL1_DAT	 equ	(0 shl $SYMFL_TYP)	; Field 1: Code or data
@SYMFL1_LIN	 equ	(1 shl $SYMFL_TYP)	; Field 1: Line number
@SYMFL1_ABS	 equ	(2 shl $SYMFL_TYP)	; Field 1: ABS record
@SYMFL1_SWT	 equ	(3 shl $SYMFL_TYP)	; Field 1: Swat internal


BeginProc SWAT_RMI		; Real mode init for SWATVXD
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	SWATVXD real mode initialization

ENTRY:
	AX  = VMM version (AH=Major #, AL=Minor #)
	BX  = Flags:
		Duplicate_Device_ID	; duplicate device ID already loaded
		Duplicate_From_INT2F	; duplicate device ID already loaded
		Loading_From_INT2F	; this device was loaded via 1605
	EDX = Reference data specified by INT 2Fh load
		(V86 far pointer ==> our INT_67)
	SI  = Segment of WIN386 environment strings
	ECX = Segment:offset of assistance API (3.10 only)

EXIT:
	BX  = pointer to excluded pages list (0 if none)
	SI  = pointer to instance data list (0 if none)
	EDX = Reference data to pass to protected mode portion of VxD
	AX  = Real mode return value, one of:
		Device_Load_Ok		real mode init was successful
		Abort_Device_Load	real mode init failed, do not load VxD
		Abort_Win386_Load	real mode init failed, fail Windows
		No_Fail_Message 	indicates no message should be displayed

|

	 mov	 VMM_VERSION,ax 	; Save WIN386 version #
	 mov	 LOADER_FLAGS,bx	; Save real mode init flags from loader
	 mov	 LOADER_SVC,ecx 	; Save ptr to loader service entry point
	 mov	 RMI_REFDATA,edx	; Save reference data from our loader
								; FIXME Convert to physical address now
	 mov	 ENVIR_SEG,si		; Save segment of WIN386 environment

	 DOSCALL @STROUT,MSG_RMI	; Show 'em we're here

	 call	 RMI_CHK_DUPVXD 	; Check for duplicate VxD installation
	 jc	 RMI_ERRX		; Fail Windows startup

	 cmp	 VMM_VERSION,030Ah	; Izit Windows 3.1 or better?
	 jb	 short @F		; Skip if not

	 mov	 ax,0003h		; Get_Profile_Boolean
	 sub	 ecx,ecx		; Default value
	 lea	 si,STR_386SWAT 	; DS:SI ==> '386SWAT', 0
	 lea	 di,STR_RMBRK		; DS:DI ==> 'RealModeBreak', 0
	 call	 LOADER_SVC		; WIN386 loader services

	 or	 ecx,ecx		; RealModeBreak=ON?
	 jz	 short @F		; Skip if not

	 SWAT				; Call a debugger
@@:

; Check command line switches that we might be interested in

	 DOSCALL @GETPSP		; Get current PSP into BX
	 mov	 es,bx			; Get addressibility to PSP
	 assume  es:PSPGRP		; Tell the assembler

	 cmp	 PSP_PARM_COUNT,0	; Is there a command line?
	 lea	 di,PSP_PARM_STRING	; PSPGRP:DI ==> command line

; Skip blanks and those pesky TABs that people are forever using on
; the DOS command line.

	 call	 SkipWhiteESDI		; Advance ES:DI over whitespace

	 mov	 eax,es:[di]		; Pick up first 4 characters
	 and	 eax,(not 20202020h)	; Force 'em to uppercase
	 cmp	 eax,'WSON'             ; Izit the front of 'NOSWAT'?
	 jne	 short @F		; Rejoin common code if not

	 mov	 ax,es:[di+4]		; Pick up next 2 characters
	 and	 ax,(not 2020h) 	; Force 'em to uppercase
	 cmp	 ax,'TA'                ; Izit the end of 'NOSWAT'?
	 jne	 short @F		; Rejoin common code if not

	 mov	 es:[di].EDD,'    '     ; Blank 'em out to avoid PROGMAN error
	 mov	 es:[di+4].ELO,'  '     ; ...
	 jmp	 short RMI_NOINSTALL	; Exit without installing if so

@@:

	 call	 XMSINFO		; Report XMS info
	 call	 MAXINFO		; Open 386MAX device and print version
	 call	 GET_PAGING_IMPORT	; Report on the paging import data
	 call	 IDTINFO		; Report real mode IDT location

;;;;;;	 call	 SWAT_PRESENT		; Complain if 386SWAT isn't installed
;;;;;;	 jc	 short RMI_ERRX 	; Bug out if 386SWAT isn't installed

	 call	 GET_SWATINFO		; EDX = SWATINFO for reference data
	 jc	 short RMI_ERRX 	; Bug out if error

	 call	 LOAD_SSF		; Load WIN.SSF and pass to 386SWAT.LOD
	 jc	 short RMI_ERRX 	; Bug out if fatal error

; Test for errors in the preceding tests.  Warnings have already been displayed.

	 test	 RMI_FLAG,@RMI_FAIL	; Should we fail the Windows startup?
	 jnz	 short RMI_ERRX 	; Yes, so return with error

	 mov	 ax, Device_Load_Ok	; Normal return

	 jmp	 short RMI_XIT		; Rejoin common exit code

RMI_NOINSTALL:
	 DOSCALL @STROUT,MSG_NOINSTALL	; Tell 'em we aren't installing

	 jmp	 short RMI_ERRX2	; Rejoin common code

RMI_ERRX:
	 call	 RMI_PAUSE	; Display 'press any key' and wait for key press
				; Carry indicates they hit ESCape
				; The set carry flag is returned to our caller
	 jmp	 short RMI_XIT	; Rejoin common exit code (CF significant)

RMI_ERRX2:
	 mov	 ax,Abort_Device_Load or No_Fail_Message ; Fail device load

RMI_XIT:
	 mov	 edx,SWATINFO		; Physical address of SWATINFO

; We want to pass SWATINFO and RMI_REFDATA on up.  We'll pass RMI_REFDATA
; as a physical address with SWATINFO saved at INT_67[1].  Note that this
; won't work if SWATVXD is loaded high or into other memory which is not
; mapped 1:1 physical to linear.
	 REGSAVE <es,bx>		; Save

	 mov	 es,RMI_REFDATA.VSEG ; Get segment of INT_67
	 assume  es:nothing		; Tell the assembler

	 mov	 bx,RMI_REFDATA.VOFF ; Get offset

	 mov	 es:[bx + 1].EDD,edx ; Save SWATINFO

	 mov	 edx,RMI_REFDATA ; Get segment:offset of INT_67

	 REGREST <bx,es>		; Restore
	 assume  es:nothing		; Tell the assembler

	 sub	 bx,bx			; No pages to exclude
	 sub	 si,si			; No instance data items

	 ret				; Return to WIN386 loader

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc SWAT_RMI			; End SWAT_RMI procedure
	 page
BeginProc RMI_PAUSE,PUBLIC	; Display 'press any key' and wait for key press
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_PAUSE

DESCRIPTION:
	Display a 'press any key' message and wait for the user to do so.
	If they hit escape, set the flag bit to fail the Windows startup.

|

	 REGSAVE <ax,dx>	; Save caller's registers

	 DOSCALL @STROUT,MSG_PAKORESC ; Display 'press any key or ESC' message

	 mov	 al,@KEYIN	; Wait for a key w/o echo
	 DOSCALL @CKEYIN	; Clear keyboard input buffer and wait for a key

	 cmp	 al,ESCAPE	; Izit it an ESC?
	 clc			; Assume not

	 jne	 short @F	; Skip if not

	 or	 RMI_FLAG,@RMI_FAIL ; Prevent Windows from starting

	 stc			; Indicate ESC pressed
@@:
	 pushf			; Save ESC flag

	 DOSCALL @STROUT,MSG_CRLF ; Print CR and LF
	 DOSCALL @STROUT,MSG_CRLF ; Print CR and LF

	 popf			; Restore ESC flag

	 REGREST <dx,ax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_PAUSE		; End RMI_PAUSE procedure
	 page
BeginProc RMI_CHK_DUPVXD		; Check for duplicate VxD installation
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	RMI_CHK_DUPVXD

DESCRIPTION:
	Check for duplicate VxD installation via either SYSTEM.INI or
	another link in the 1605 startup chain.

	If we're a duplicate, complain about it and fail the
	Windows startup.

EXIT:
	Carry set if duplicate VxD installation is attempted.

|

	 REGSAVE <ax,dx>	; Save caller's registers

	 test	 LOADER_FLAGS,Duplicate_Device_ID ; Check for duplicates
	 jz	 short @F	; Jump if assumption was correct
				; Note, CF cleared by TEST

	 DOSCALL @STROUT,MSG_DUP_DEVICE ; Print error message

	 stc			; Return error indicator
@@:
	 REGREST <dx,ax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  RMI_CHK_DUPVXD 		; End RMI_CHK_DUPVXD procedure
	 page
BeginProc XMSINFO			; Display XMS info
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing

	 REGSAVE <ax,bx,cx,di,es>	; Save caller's registers

	 mov	 ax,4310h		; Get XMS entry point
	 int	 2Fh			; DOS multiplex services
	 assume  es:nothing		; Tell the assembler

	 mov	 XMS.VOFF,bx		; Save the offset
	 mov	 XMS.VSEG,es		; ... and segment

	 mov	 ah,@XMS_VERS		; Get the XMS version
	 call	 XMS			; AH = major version number
					; AL = minor version number
					; BX = debugging version
					; DX = 1 if HMA exists, 0 otherwise

	 lea	 di,MSG_XMS_VER_X2	; Place to store minor version #
	 mov	 cx,2			; # of digits
	 call	 RMI_TOHEX		; Format into message text

	 mov	 al,ah			; Move major version number into AX
	 lea	 di,MSG_XMS_VER_X1	; Place to store major version #
	 mov	 cx,1			; # of digits
	 call	 RMI_TOHEX		; Format into message text

	 mov	 ax,bx			; Move debugging version # into AX
	 lea	 di,MSG_XMS_VER_X3	; Place to store digits
	 mov	 cx,4			; # of digits
	 call	 RMI_TOHEX		; Format into message text

	 DOSCALL @STROUT,MSG_XMS_VER	; Print message

	 REGREST <es,di,cx,bx,ax>	; Restore caller's registers
	 assume  es:nothing		; Tell the assembler

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  XMSINFO			; End XMSINFO procedure
	 page
BeginProc IDTINFO			; Display real mode IDT location
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing

	 REGSAVE <ax,bx,cx,di>		; Save caller's registers

	 SIDTD	 RM_IDTR		; Copy IDTR

	 mov	 eax,RM_IDTR.DTR_BASE	; Linear base address
	 lea	 di,MSG_IDTR_BASE	; Place to store digits
	 mov	 cx,8			; # of digits
	 call	 RMI_TOHEX		; Format into message text

	 mov	 ax,RM_IDTR.DTR_LIM	; Limit
	 lea	 di,MSG_IDTR_LIM		; Place to store digits
	 mov	 cx,4			; # of digits
	 call	 RMI_TOHEX		; Format into message text

	 DOSCALL @STROUT,MSG_IDTR	; Print message

	 REGREST <di,cx,bx,ax>		; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  IDTINFO			; End IDTINFO procedure
	 page
BeginProc MAXINFO			; Check for presence of 386MAX
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Check for presence of 386MAX.SYS.
	If 386MAX is found, ensure it's ON.

|

	 REGSAVE <ax,bx,cx,dx>		; Save caller's registers

	 mov	 al,02h 		; R/W access
	 DOSCALL @OPENF2,DEVNAME	; Attempt to open 386MAX device driver
	 jc	 short MP_NOMAX 	; Jump if not

	 mov	 DEV_HNDL,ax		; Save for later use
	 mov	 bx,ax			; Move handle to proper register

	 mov	 al,00h 		; Get device information
	 DOSCALL @IOCTL2		; Return in DX
	 jc	 short MP_NOMAX 	; Something went wrong

	 test	 dx,@IOCTL_DEV		; Izit a device?
	 jz	 short MP_NOMAX 	; No -- that's odd

; Get QMAXINFO structure

	 mov	 al,02h 		; Read from device
	 mov	 bx,DEV_HNDL		; Get device handle
	 mov	 cx,INFOSIZE		; CX = # bytes in INFO structure
	 mov	 INFO_CTL,@CTL_XFER	; Mark as INFO transfer
	 DOSCALL @IOCTL2,INFO_CTL	; Get IOCTL info into INFO

; Make sure it's really 386MAX

	 cmp	 INFO.INFO_SIGN.ELO[0],'83' ; Our signature?
	 jne	 short MP_NOMAX 	; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[2],'M6' ; Our signature?
	 jne	 short MP_NOMAX 	; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[4],'XA' ; Our signature?
	 jne	 short MP_NOMAX  ; Not this time

; Get the QMAX.SYS version # into a more convenient form

	 mov	 ax,INFO.INFO_VER[2].ELO ; Copy minor version digits
	 mov	 MSG_MAXVER_X[2].ELO,ax ; ...

	 mov	 al,INFO.INFO_VER[0]	; Copy major version #
	 mov	 MSG_MAXVER_X,al	; ...

	 DOSCALL @STROUT,MSG_MAXVER	; Tell 'em the 386MAX.SYS version number

; Make sure 386MAX is on

	 test	 INFO.INFO_GLB,@GLB_ON	; Izit ON or AUTO active?
	 jz	 short MP_MAXOFF	; Jump if not
	 jmp	 short MP_EXIT		; Rejoin common exit code

MP_NOMAX:
	 DOSCALL @STROUT,MSG_NOMAX	; Tell 'em 386MAX.SYS is not present
	 jmp	 short MP_EXIT		; Rejoin common exit code

MP_MAXOFF:
	 DOSCALL @STROUT,MSG_MAXOFF	; Tell 'em 386MAX.SYS is OFF
;;;;;;	 jmp	 short MP_EXIT		; Rejoin common exit code

MP_EXIT:
	 mov	 bx,DEV_HNDL		; Get the device driver handle
	 or	 bx,bx			; Did we ever open it?
	 jz	 short @F		; Skip close if not

	 DOSCALL @CLOSF2		; Close the device
@@:
	 REGREST <dx,cx,bx,ax>		; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc MAXINFO 			; End MAXINFO procedure


BeginProc SWAT_PRESENT		; Complain if 386SWAT isn't installed
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing

; Check for 386SWAT presence via extended VCPI call
; Check for proper code at the INT 67h vector, taking the real mode IDTR

	 pusha				; Save caller's registers
	 push	 es			; ...

	 mov	 al,67h 		; EMS interrupt #
	 DOSCALL @GETINT		; Get interrupt vector in AL to ES:BX
	 assume  es:nothing		; Tell the assembler

	 smsw	 ax			; Get low end of CR0
	 test	 ax,(mask $PE)		; Are we in V86 mode?
	 jnz	 short SP_V86		; Jump if so

	 mov	 eax,RM_IDTR.DTR_BASE	; Linear base address of real mode IDT
	 cmp	 eax,0FFF00h		; Near 1 meg?
	 ja	 short SP_NOSWAT	; No SWAT if so

	 shr	 eax,4			; Get the segment
	 mov	 es,ax			; Address it
	 assume  es:nothing		; Tell the assembler

	 mov	 di,RM_IDTR.DTR_BASE.ELO ; Offset of real mode IDT
	 and	 di,0Fh 		; Isolate the offset
	 les	 bx,es:[di+4*67h]	; ES:BX is actual INT 67h vector
	 assume  es:nothing		; Tell the assembler

SP_V86:
	 mov	 di,10+1		; Offset to EMS id string
	 lea	 si,EMMNAME+1		; String to look for
	 mov	 cx,8-1 		; Length of id string
    repe cmpsb				; Compare strings
	 je	 short SP_INT67 	; Jump if EMS is present

	 cmp	 es:[bx].ELO,0FC80h	; Does it look like CMP AH,0DEh
	 jne	 short SP_NOSWAT	; Jump if not

	 cmp	 es:[bx+2].LO,0DEh	; ...
	 jne	 short SP_NOSWAT	; Jump if not

SP_INT67:
	 VCPICALL @VCPI_DPRES		; Is debugger installed?
	 cmp	 ah,0			; AH cleared if so
	 je	 short SP_SWAT		; Skip error code if installed

SP_NOSWAT:
	 DOSCALL @STROUT,MSG_NO_SWAT	; Tell 'em SWAT isn't loaded

	 stc				; Error indicator

	 jmp	 short SWAT_PRESENT_XIT ; Rejoin common exit code
SP_SWAT:
	 clc				; Normal return indicator

SWAT_PRESENT_XIT:
	 pop	 es			; Restore caller's registers
	 popa				; ...
	 assume  es:nothing		; Tell the assembler


	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  SWAT_PRESENT			; End SWAT_PRESENT procedure


BeginProc GET_SWATINFO		; Get address of SWATINFO into EDX for ref data
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing

	 REGSAVE <ax,bx,cx,edx> 	; Save caller's registers

	 sub	 edx,edx		; Assume SWAT isn't loaded

; Try the VCPI interface
	 VCPICALL @VCPI_DBGINF		; Get Debugger Information address
					; EDX is returned as reference data
	 mov	 SWATINFO,edx		; Save reference data
	 or	 edx,edx		; Did VCPI_DBGINF return an address?
	 jnz	 short GOT_SWATINFO	; Skip error stuff if so

; Try the SWATVXD$ interface
	 mov	 al,00h 		; Readonly
	 DOSCALL @OPENF2,szSWATVXD$	; Open SWATVXD$
	 jc	 short NO_SWATINFO	; Jump if error

	 mov	 bx,ax			; Copy handle to proper register
	 mov	 al,00h 		; Get device info into DX
	 DOSCALL @IOCTL2		; I/O Control for devices, handle in BX
	 jc	 short XDEVICE		; Jump if error

	 test	 dx,@IOCTL_DEV		; Is it a device driver?
	 jz	 short XDEVICE		; Jump if error

	 mov	 cx,(type SWATINFO)	; # of byte to read
	 lea	 dx,SWATINFO		; DS:DX ==> buffer
	 mov	 SWATINFO.LO,1		; Function code to get SWATINFO (FIXME)
	 mov	 al,02h 		; Read from device
	 DOSCALL @IOCTL2		; I/O Control for devices, handle in BX
	 jc	 short XDEVICE		; Jump if error

XDEVICE:
	 DOSCALL @CLOSF2		; Close file, handle in BX

	 cmp	 SWATINFO,0		; Did we get it?
	 jne	 short GOT_SWATINFO	; Exit normally if so

NO_SWATINFO:
	 DOSCALL @STROUT,MSG_NO_INFO	; Tell 'em SWATINFO isn't available

	 stc				; Error indicator

	 jmp	 short GET_SWATINFO_XIT ; Rejoin common exit code
GOT_SWATINFO:
	 clc				; Normal return indicator
GET_SWATINFO_XIT:
	 REGREST <edx,cx,bx,ax> 	; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  GET_SWATINFO		; End GET_SWATINFO procedure
	 page
BeginProc GET_PAGING_IMPORT		; Get paging import spec data
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing

	 REGSAVE <ax,bx,cx,dx>		; Save caller's registers

	 mov	 DEV_HNDL,0		; Prime file handle

	 mov	 al,02h 		; R/W access
	 DOSCALL @OPENF2,EMMNAME	; Attempt to open EMS device
	 jnc	 short @F		; Skip error if it worked

	 DOSCALL @STROUT,MSG_IMPORT_OPEN ; Tell 'em the open failed

	 jmp	 GPI_XIT		; Rejoin common exit code

@@:

; Ensure it's a device

	 mov	 DEV_HNDL,ax		; Save for later use
	 mov	 bx,ax			; Move handle to proper register

	 mov	 al,00h 		; Get device information subfunction
	 DOSCALL @IOCTL2		; Return in DX
	 jnc	 short @F		; Skip error if it worked

	 DOSCALL @STROUT,MSG_IMPORT_IOCTL1 ; Tell 'em the IOCTL failed

	 jmp	 short GPI_XITNUL	; Rejoin common exit code

@@:
	 test	 dx,@IOCTL_DEV		; Izit a device?
	 jnz	 short @F		; Skip error if so

	 DOSCALL @STROUT,MSG_IMPORT_NOTCHR ; Tell 'em the device is wrong

	 jmp	 short GPI_XITNUL	; Rejoin common exit code

@@:

; Get WIN386 Paging Import structure

	 mov	 al,02h 		; Read from device
	 mov	 bx,DEV_HNDL		; Get device handle
	 mov	 cx,PAGING_IMPORT_LEN	; CX = # bytes in INFO structure
	 mov	 PAGING_IMPORT.LO,@PAGING_IMPORT_INFO ; Mark as INFO transfer
	 DOSCALL @IOCTL2,PAGING_IMPORT	; Get IOCTL info into PAGING_IMPORT
	 jnc	 short @F		; Skip error if it worked

	 DOSCALL @STROUT,MSG_IMPORT_IOCTL2 ; Tell 'em the IOCTL failed

	 jmp	 short GPI_XITNUL	; Rejoin common exit code

@@:
	 cmp	 ax,PAGING_IMPORT_LEN	; Did we get all 6 bytes?
	 je	 short @F		; Yup

	 DOSCALL @STROUT,MSG_IMPORT_IOCTL3 ; Tell 'em the IOCTL failed

	 jmp	 short GPI_XITNUL	; Rejoin common exit code

@@:
	 mov	 al,PAGING_IMPORT.EMM_Import_API_Version_Maj ; Major version #
	 add	 al,'0'                 ; Form ASCII digit
	 mov	 MSG_IMPORT_INFO0,al	; Save in message text

	 mov	 al,PAGING_IMPORT.EMM_Import_API_Version_Min ; Minor version #
	 sub	 ah,ah			; Convert version # to a word
	 mov	 cx,-2			; Number of digits (with leading zeroes)
	 lea	 di,MSG_IMPORT_INFO1	; ==> message text
	 call	 RMI_TODEC

	 mov	 eax,PAGING_IMPORT.EMM_Import_Data_Phys_Ptr ; ==> import data
	 mov	 cx,8			; Number of digits in physical address
	 lea	 di,MSG_IMPORT_INFO2	; ==> message text
	 call	 RMI_TOHEX		; Format into message text

	 DOSCALL @STROUT,MSG_IMPORT_INFO ; Tell 'em about the paging import data

	 jmp	 short GPI_XIT		; Rejoin common code

GPI_XITNUL:
	 DOSCALL @STROUT,MSG_IMPORT_NULL ; Tell 'em the bad news
GPI_XIT:
	 mov	 bx,DEV_HNDL		; Get device handle
	 or	 bx,bx			; Izit open?
	 jz	 short @F		; Nope

	 DOSCALL @CLOSF2		; Close the device
@@:
	 REGREST <dx,cx,bx,ax>		; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  GET_PAGING_IMPORT		; End GET_PAGING_IMPORT procedure
	 page
BeginProc GETENV			; Search environment for string
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

ENTRY:
	DS:SI ==> string for which to search

EXIT:
	ES:DI ==> text of string, if found

|

	 REGSAVE <ax,cx,si>	; Save caller's registers

; Find end of search string

	 mov	 di,si		; Copy start of string to proper register
	 mov	 cx,8000h	; Look forever
	 sub	 al,al		; Scan for a terminating NUL
	 repnz scasb		; Look for end of string
	 mov	 cx,di		; Offset to last byte
	 sub	 cx,si		; Less start offset is length to compare
	 dec	 cx		; Less the NUL

	 DOSCALL @GETPSP	; Get current PSP into BX
	 mov	 es,bx		; Get addressibility to PSP
	 assume  es:PSPGRP	; Tell the assembler

	 mov	 es,PSP_ENVIR_PTR	; Get segment of environment strings
	 assume  es:nothing	; Tell the assembler

	 sub	 di,di		; Address of 1st string

GETENV_NXT:
	 cmp	 es:[di].LO,0	; Last string?
	 jz	 short GETENV_NOF ; Jump if never found

	 push	 cx		; Save search length
	 push	 si		; Save start of search string
	 repe cmpsb		; Compare strings
	 pop	 si		; Restore start of search string
	 pop	 cx
	 jz	 short GETENV_OK ; Jump if we've found it

; This string didn't match.  Scan ahead to start of next string

	 push	 cx		; Save search length

	 mov	 cx,8000h	; Scan to start of next string
	 repnz scasb		; Find terminating NUL

	 pop	 cx		; Restore search length
	 jmp	 short GETENV_NXT	; On to next string

; Never found the search string in the environment

GETENV_NOF:
	 stc			; Indicate failure to find search string

	 jmp	 short GETENV_XIT ; Join common exit code

; Found the search string.  DI points to contents of string

GETENV_OK:
	 clc			; Indicate we've found it

	 inc	 di		; Bump past the '=', ptr returned in ES:DI
GETENV_XIT:
	 REGREST <si,cx,ax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  GETENV 		; End GETENV procedure


BeginProc SkipWhiteESDI 		; Advance ES:DI over whitespace
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

ENTRY:
	ES:DI ==> text string

EXIT:
	ES:DI advanced over whitespace

|

	 REGSAVE <ax>			; Save caller's registers

SKESDI_LOOP:
	 mov	 al,es:[di]		; Pick up next character

	 cmp	 al,' '                 ; Izit white?
	 je	 short SKESDI_SKIP	; Advance over it if so

	 cmp	 al,TAB 		; Izit white?
	 jne	 short SKESDI_EXIT	; Exit if not

SKESDI_SKIP:
	 inc	 di			; Advance over it

	 jmp	 short SKESDI_LOOP	; Test the next character

SKESDI_EXIT:
	 REGREST <ax>			; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  SkipWhiteESDI			; End SkipWhiteESDI procedure
	 page
BeginProc RMI_STRLEN		; Calculate AX = strlen(DS:SI)
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

    Get length of string at DS:SI into AX

ENTRY:
	DS:SI ==> string

EXIT:
	AX = length of input string (not including NUL)

	Assumes DS = ES

|

	 REGSAVE <cx,di>	; Save caller's register

	 mov	 di,si		; ES:DI ==> string
	 mov	 cx,-1		; Longest strings possible

	 sub	 al,al		; Terminating NUL we're looking for
   repne scasb			; Find terminating NUL

	 not	 cx		; Length we scanned
	 dec	 cx		; Account for NUL

	 mov	 ax,cx		; Copy length to proper register for return

	 REGREST <di,cx>	; Restore caller's register

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  RMI_STRLEN		; End RMI_STRLEN procedure

	 page
BeginProc RMI_TOHEX		; Binary to ASCII HEX Conversion
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Format EAX into ASCII hex digits.

On entry:

	EAX =	  Number to format
	CX =	  Number of digits desired
	DS:DI ==> Output area for digits

|

	 REGSAVE <eax,cx,dx,si> ; Save caller's registers

	 mov	 dx,cx		; Copy number of digits
	 shl	 cx,2		; Times 4 to get bits-per-digit
	 ror	 eax,cl 	; Rotate interesting bits around
	 mov	 cx,dx		; Restore number of digits
@@:
	 rol	 eax,4		; Move next nibble to low end
	 mov	 si,ax		; Copy to SI
	 and	 si,15		; Kill everything but lowest nibble
	 mov	 dl,RMI_HEX[si] ; Form ASCII hex digit
	 mov	 [di],dl	; Store into output stream
	 inc	 edi		; Bump output pointer
	 loop	 @B		; Continue with remainder of digits

	 REGREST <si,dx,cx,eax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  RMI_TOHEX		; End RMI_TOHEX procedure

BeginProc RMI_TODEC		; Format AX into ASCII decimal
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Format AX into ASCII decimal digits.

On entry:

	AX =	Number to format
	DS:DI ==> Output area for digits
	CX =	Number of digits desired
		Negative CX indicates do NOT remove leading zeros

|

	 REGSAVE <ax,bx,dx>	; Save caller's registers

	 push	 cx		; Save number of digits (including negative)

	 or	 cx,cx		; Is CX negative?
	 jns	 short @F	; Skip NEG if CX is positive

	 neg	 cx		; Form ABS(CX)
@@:

	 add	 di,cx		; Bump to last digit position + 1
	 dec	 di		; DI ==> last digit

	 mov	 bx,10		; Base for conversion
@@:
	 sub	 dx,dx		; Clear for divide
	 div	 bx		; Divide by base
	 add	 dl,'0'         ; Form ASCII digit from remainder

	 mov	 [di],dl	; Store into output area
	 dec	 di		; Bump to next position (backwards)

	 loop	 @B		; Do the next digit

; Take care of leading zeroes

	 pop	 cx		; Restore number of digits (including negative)

	 or	 cx,cx		; Is it negative?
	 js	 short RMI_TODEC_X0 ; Skip leading zero removal if so

	 dec	 cx		; Leave at least one zero
@@:
	 inc	 di		; Advance to last digit stored
	 cmp	 [di].LO,'0'    ; Izit a zero?
	 jne	 short RMI_TODEC_X0 ; No, exit loop

	 mov	 [di].LO,' '    ; Blank out leading zero

	 loop	 @B		; Continue

RMI_TODEC_X0:
	 REGREST <dx,bx,ax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  RMI_TODEC		; End RMI_TODEC procedure

BeginProc LOAD_SSF		; Load and fixup .SSF symbol file
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Symbol support works only for Windows 3.1 or later.

	Read in WIN.SSF.
	Apply fixup in LSSF_XLAT to all VM non-ABS symbol records.
	Pass modified records to SWAT.

|

	 REGSAVE <eax,bx,cx,dx,si,di,ds,es> ; Save caller's registers

	 mov	 LSSF_FH,0		; Initialize file handle (not opened)

	 cmp	 VMM_VERSION,030Ah	; Izit Windows 3.1 or better?
	 jb	 LOAD_SSF_XIT		; Skip if not

	 mov	 bx,ds		; Save addressiblity to _RCODE

; Open the .SSF file

	 mov	 ax,0000h	; Get_Profile_String
	 lea	 si,STR_386SWAT ; DS:SI ==> '386SWAT', 0
	 lea	 di,STR_SSF	; DS:DI ==> 'SSF=', 0
	 sub	 dx,dx		; ES:DX ==> default string
	 call	 LOADER_SVC	; WIN386 loader services
	 assume  es:nothing	; ES:DX ==> string from SYSTEM.INI
	 jc	 LOAD_SSF_XIT	; No SSF= in [386SWAT], skip symbols entirely

	 push	 es		; MOV DS,ES
	 pop	 ds		; ...
	 assume  es:nothing	; Tell the assembler

	 mov	 si,dx		; DS:SI ==> string from SYSTEM.INI
	 call	 RMI_STRLEN	; AX = strlen(DS:SI)
	 inc	 ax		; Bump to include trailing NUL
	 mov	 cx,ax		; Copy length to REP register

; Check for /F switch to flush the existing symbols

	push	cx		; Save for a moment

	mov	al,'/'          ; Check for switch char
	mov	di,si		; ES:DI ==> string
  repne scas	es:[di].LO	; Search for it
	jne	short LOAD_SSF1 ; Jump if not found

	mov	al,es:[di]	; Get next character
	or	al,20h		; Convert to lowercase

	cmp	al,'f'          ; Izit flush?
	jne	short @F	; Jump if not

	or	LSSF_FLAG,@LSSF_FLUSH ; Mark as flushing
@@:

; Strip off trailing blanks

	mov	al,0		; Terminator
	dec	di		; Back off to switch char
	std			; String ops backwards
@@:
	stos	es:[di].LO	; Zap it

	cmp	es:[di].LO,' '  ; Izit white space?
	je	short @B	; Jump if so

	cmp	es:[di].LO,TAB	; Izit white space?
	je	short @B	; Jump if so

	cld			; String ops forwards
LOAD_SSF1:
	pop	cx		; Restore length

	 mov	 es,bx		; Get addressibility to _RCODE
	 assume  es:_RCODE	; Tell the assembler

	 lea	 di,PATH_BUF	; ES:DI ==> buffer to assemble filename
     rep movsb			; Copy name to buffer

	 mov	 ds,bx		; Get addressibility to _RCODE
	 assume  ds:_RCODE	; Tell the assembler

	 lea	 dx,PATH_BUF	; Name of .SSF file
	 mov	 al,0		; Read-only, sharing compatibility mode
	 DOSCALL @OPENF2	; Open file
	 jc	 LOAD_SSF_ERR ; Jump if failed

	 mov	 LSSF_FH,ax	; Save file handle

; Establish addressibility to the read buffer

	 lea	 ax,LSSF_BUF+15 ; Offset of read buffer, rounded up
	 shr	 ax,4		; Convert from byte offset to paras
	 mov	 dx,ds		; Get base segment of buffer
	 add	 ax,dx		; Add to get segment of read buffer
	 mov	 LSSF_BUFP,ax	; Save buffer segment pointer

	 mov	 ds,ax		; Address the read buffer
	 assume  ds:nothing	; Tell the assembler

; Read the .SSF header

	 mov	 bx,LSSF_FH	; File handle for read
	 sub	 dx,dx		; Offset within buffer segment
	 mov	 cx,size SSF_STR ; # of bytes to read
	 DOSCALL @READF2	; Read data from handle BX into DS:DX
	 jc	 LOAD_SSF_ERR ; Jump if failed

; Check file header data

	 cmp	 ds:[0].SSF_SIG,@SSF_SIG	; Izit an .SSF file?
	 jne	 LOAD_SSF_ERR			; Jump if not

; Check the version of the file format
; For versions less than 0.11, use a LSEEK offset of 0Ah
; For versions 0.11 and above, use the DWORD at SSF_DATA as the LSEEK offset

	 cmp	 ds:[0].SSF_VER,0010h	; Izit at least version 0.10?
	 jb	 LOAD_SSF_ERR		; We'll only handle 0.10 and above

	 mov	 dx,ds:[0].SSF_DATA.ELO ; Low-order word of offset
	 mov	 cx,ds:[0].SSF_DATA.EHI ; high-order word

	 cmp	 ds:[0].SSF_VER,0010h	; Izit version 0.10?
	 ja	 short @F		; Use DWORD in CX:DX

	 sub	 cx,cx			; CX:DX <== 0000:000A
	 mov	 dx,0Ah
@@:
	 mov	 bx,LSSF_FH		; File handle for .SSF file
	 mov	 al,0			; SEEK_ABS
	 DOSCALL @MOVFP2		; LSEEK to CX:DX, style in AL
	 jc	 LOAD_SSF_ERR		; Something went wrong

	 mov	 eax,ds:[0].SSF_COUNT ; Get number of records
	 or	 eax,eax	; Izit non-zero?
	 jz	 LOAD_SSF_ERR	; Jump if empty

	 mov	 LSSF_SYMCNT,eax ; Save total record count for loop
	 mov	 LSSF_SYMTOT,eax ; Save total record count for message

; Ask SWAT to flush its symbol table

	test	LSSF_FLAG,@LSSF_FLUSH ; Should we flush?
	jz	short @F	; Jump if not

	 mov	 bl,@DBGSYM_FLUSH ; Symbol table flush subservice
	 VCPICALL @VCPI_DBGSYM	; Call debugger API
@@:
	 sub	 dx,dx		; Address start of buffer
	 mov	 cx,@LSSF_BUFSIZ ; Attempt to fill buffer
	 mov	 LSSF_CNT,0	; Initialize bytes remaining

LOAD_SSF_GETBLOCK:
	 mov	 bx,LSSF_FH	; Get file handle
	 DOSCALL @READF2	; Read data from BX into DS:DX
	 jc	 LOAD_SSF_ERR	; Jump if read failed

	 or	 ax,ax		; Izit EOF?
	 jz	 LOAD_SSF_DONE	; Jump if so

	 add	 LSSF_CNT,ax	; Add bytes read to bytes remaining
	 mov	 cx,LSSF_CNT	; Keep bytes remaining in CX
	 mov	 LSSF_SYMSUB,0	; Clear record subtotal

	 sub	 si,si		; Address start of buffer
	 mov	 ax,LSSF_XLAT	; Fixup value for VM segments

; Trundle through the records, fixing up VM segments.
; Keep track of the number of records for the SWAT API call.

LOAD_SSF_FIXNEXT:
	 mov	 bx,ds:[si].SYM_FLAGS	; Grab flags
	 test	 bx,mask $SYMFL_VM	; Izit a real mode segment?
	 jz	 short LOAD_SSF_SKIP	; Jump if not

	 and	 bx,mask $SYMFL_TYP	; Mask off record type field
	 cmp	 bx,@SYMFL1_ABS 	; Izit an ABS record?
	 je	 short LOAD_SSF_SKIP	; Jump if so

	 add	 ds:[si].SYM_SEGSEL,ax	; Fixup segment

LOAD_SSF_SKIP:
	 inc	 LSSF_SYMSUB		; Bump record count
	 movzx	 bx,ds:[si].SYM_SYMLEN	; Get length of name
	 add	 bx,size SYM_STR	; Add length of structure
	 add	 si,bx			; Skip to next record
	 sub	 cx,bx			; Keep track of remaining bytes
	 cmp	 cx,(size SYM_STR) + 1	; Izit the minimum size?
	 jb	 short @F		; Jump if not

	 movzx	 bx,ds:[si].SYM_SYMLEN	; Get length of next name
	 add	 bx,size SYM_STR	; Add structure length
	 cmp	 cx,bx			; Izit all there?
	 jnc	 short LOAD_SSF_FIXNEXT ; Jump if not

@@:

; Add LSSF_SYMSUB to LSSF_SYMCNT, and send contents of buffer up to SWAT

	 REGSAVE <ecx,esi>		; Save registers temporarily

	 movzx	 ecx,LSSF_SYMSUB	; Get number of records
	 sub	 LSSF_SYMCNT,ecx	; Subtract from total
	 sub	 esi,esi		; Address start of buffer
	 mov	 bl,@DBGSYM_APPND	; Append entries subservice
	 VCPICALL @VCPI_DBGSYM		; Call SWAT API
					; Result in AH

	 REGREST <esi,ecx>		; Restore registers

; We may have part of a record.  We need to move it to the beginning of the
; buffer and reset the read pointer so that the data read in will be appended.
; This convoluted scheme ensures that we always have a record-granular
; buffer without doing time-consuming disk seeks.

	 sub	 di,di			; Assume start of buffer
	 mov	 bx,cx			; Save number of bytes
	 mov	 LSSF_CNT,cx		; Reinitialize bytes remaining
	 or	 cx,cx			; Is there anything left?
	 jz	 short LOAD_SSF_CALCBUF ; Jump if not

; Move CX bytes from DS:SI to beginning of buffer, leaving
; DS:DI ==> location in buffer for next file read.

	 push	 es		; Save for a moment

	 mov	 es,LSSF_BUFP	; Address buffer segment
	 assume  es:nothing	; Tell the assembler

     rep movsb			; Move it

	 pop	 es		; Restore
	 assume  es:_RCODE	; Tell the assembler

; DS:DI ==> at or past buffer start.  Move it into DX for file read.
; Put 32K-BX in CX for bytes to read.

LOAD_SSF_CALCBUF:
	 mov	 dx,di		; Load DX for read
	 mov	 cx,@LSSF_BUFSIZ  ; Attempt to fill buffer
	 sub	 cx,bx		; Subtract bytes already in buffer
	 jmp	 LOAD_SSF_GETBLOCK ; Get next chunk of file

; Done processing symbols.  Display some statistics

LOAD_SSF_DONE:
	 mov	 ax,es		; Get addressibility to _RCODE
	 mov	 ds,ax		; ... via DS
	 assume  ds:_RCODE	; Tell the assembler

	 mov	 eax,LSSF_SYMTOT ; Get total record count
	 mov	 cx,6		; Maximum # of digits
	 lea	 di,MSG_SYMB_INFO1 ; ==> message text
	 call	 RMI_TODEC	; Format into message text

; Copy .SSF filename into message buffer

	 lea	 si,PATH_BUF	; DS:SI ==> filename buffer
	 lea	 di,MSG_SYMB_INFO2 ; ES:DI ==> hole in message text
@@:
	 lodsb			; Get next byte of message

	 or	 al,al		; Izit the terminating NUL?
	 jz	 short @F	; Exit loop if so

	 stosb			; Save character into message

	 jmp	 short @B	; Get 'em all

@@:
	 mov	 al,CR		; Carriage return
	 stosb			; Stuff it

	 mov	 al,LF		; Linefeed
	 stosb			; Stuff it

	 mov	 al,EOS 	; Terminating character for DOS function 9
	 stosb			; Stuff it

	 DOSCALL @STROUT,MSG_SYMB_INFO ; Tell 'em about the symbols

	 jmp	 short LOAD_SSF_XIT ; Rejoin common exit code

; We encountered an error

LOAD_SSF_ERR:
	 mov	 ax,es		; Get addressibility to _RCODE
	 mov	 ds,ax		; ... via DS
	 assume  ds:_RCODE	; Tell the assembler

	 DOSCALL @STROUT,MSG_SYMB_NONE ; No .SSF files processed

LOAD_SSF_XIT:
	 mov	 bx,LSSF_FH	; Get file handle
	 or	 bx,bx		; Izit valid?
	 jz	 short @F	; Jump if not

	 DOSCALL @CLOSF2	; Close file handle in BX
@@:
	 clc			; Normal return indicator

	 REGREST <es,ds,di,si,dx,cx,bx,eax> ; Restore caller's registers
	 assume  ds:_RCODE, es:nothing ; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing
EndProc  LOAD_SSF			; End LOAD_SSF procedure

VxD_REAL_INIT_ENDS			; End _RCODE segment

	end	SWAT_RMI		; End module, defining start address
