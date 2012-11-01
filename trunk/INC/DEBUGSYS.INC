;****************************************************************************
;                                                                           *
; THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY     *
; KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE       *
; IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR     *
; PURPOSE.                                                                  *
;                                                                           *
; Copyright (C) 1993-95  Microsoft Corporation.  All Rights Reserved.       *
;                                                                           *
;****************************************************************************

;******************************************************************************
;
;   Title:	DEBUGSYS.INC - VMM debugging include file
;
;   Version:	1.00
;
;==============================================================================

;******************************************************************************
;
;  Real mode Debugger services:
;
;

D386_RM_Int		equ 68h	; hooked by the debugger in real mode.

D386_Id			equ 0F386h ; debugger identification code

D386_MIN		equ 43h	; minimum INT 68 function code

D386_Identify		equ 43h	; returns debugger identification, if debugger
				; loaded

D386_Prepare_PMode	equ 44h	; partially prepare for protected mode operation
				; a pointer to a procedure is returned so that
				; the IDT can also be set in protected mode
				; INPUT:
				;   AL	0  - retail version of Win386
				;	1  - debugging version
				;   BX	a valid selector that gives access
				;	to all of memory
				;   CX	first of 2 selectors reserved for
				;	WDeb386 to use
				;   DX	is GDT selector
				;   DS:SI pointer to working copy of GDT
				;   ES:DI pointer to working copy of IDT
				;
				; RETURN:
				;   ES:EDI points to a protected mode procedure
				;   (selector:offset32) that can be called
				;   to set the IDT when it has been created.
				;   Takes a function number in AL. See the 
				;   PMINIT equates.

D386_Real_Mode_Init	equ 45h	; re-init fro real mode after entering pmode

D386_Set_Switches	equ 46h	; set debugging switches
				;  BL = verbose switch
				;	- 00b - no segment display
				;	- 01b - display win386 segments only
				;	- 10b - display ring 1 segments only
				;	- 11b - display win386 & ring 1 segs
				;  BH = conditional brkpts
				;	0 - off
				;	1 - on
				; -1 for BX means no change (default)

D386_Execute_Cond	equ 47h	; execute conditional BP (/B option)
				; ES:SI points to NUL terminated string
				; to print if conditional flag set.

D386_Free_Segment	equ 48h	; undefine the real mode segment's symbols
				; BX = real mode segment to undefined

D386_Set_Baudrate	equ 49h	; set com port baud rate
				; BX = baud rate

D386_Reinit		equ 4ah	; reinitialize debugger for protected mode
				;  AL  0  - retail version of Win386
				;	  1  - debugging version of Win386
				;	  2  - 286 DOS extender (3.0)
				;	  3  - 286 DOS extender under VCPI (3.1)
				;	  4  - 286 DOS extender (3.1)
				;  BX  a valid selector that gives access
				;      to all of memory
				;  CX  first of 2 selectors reserved for
				;      wdeb386 to use
				;  DX  is GDT selector
				;
				;  This function can after a function 45h only
				;  if function	44 was executed in the past on
				;  the IDT/GDT.

D386_Def_Deb_Segs	equ 4bh	; define debugger's segments

D386_Set_Com_Port	equ 4ch	; set com port number
				; BX = com port number
				; returns AX != 0, error bad com port

D386_Link_Sym		equ 4dh	; link sym file map
				; ES:DI pointer to AddrS struc in front of
				; sym file map.
				; BX = loader ID (used to unlink sym file maps)
				; A loader ID of 0 is used for all the maps
				; wdeb386 loads via /S is ran as a program and
				; -1 is used by the device driver version.  All
				; loader IDs of 0 are automaticly unlinked when
				; wdeb386 exits.

D386_Unlink_Sym		equ 4eh	; unlink sym file maps
				; BX = loader ID - this routine looks at all
				; of the maps that are currently linked and
				; removes the ones that were loaded with this
				; ID.

D386_Remove_Segs	equ 4fh	; remove any undefined segments from the
				;  name module's symbols
				; ES:DI pointer to module name

D386_Load_Segment	equ 50h	; defines the actual segment/selector for a
				; loaded segment to allow for symbol processing
				; INPUT:
				;  AL segment type   0	- code selector
				;		     1	- data selector
				;		    10h - code segment
				;		    11h - data segment
				;		    20h - real-mode EXE
				;		    40h - code segment & sel
				;		    41h - data segment & sel
				;		    80h - device driver code seg
				;		    81h - device driver data seg
				;  If AL = 20h then
				;    CX = paragraph number
				;    ES:DI pointer to module name
				;  Else If AL < 80h then
				;    BX segment #
				;    CX actual segment/selector
				;    DX actual selector	 (if 40h or 41h)
				;    ES:DI pointer to module name
				;  Else
				;    ES:DI points to D386_Device_Params struc
				;
				; RETURN:
				;    AL = 1, if successful, else 0

D386_Display_Char	equ 51h	; display a character to the debugging terminal
				; AL = char to display

D386_Display_Str	equ 52h	; display a string to the debugging terminal
				; ES:SI points to NUL terminated string

D386_IsVxDInstalled	equ 53h	; returns if debug VxD has been installed
				; AL == 0 if not install, AL != 0 if installed

D386_VxDInstall		equ 54h	; sets that the debug VxD installed/uninstalled
				; BL == 0 if uninstall, BL != 0 if installed

D386_RegisterDotCmd	equ 55h	; registers dot command
				; BL = command letter
				; CX:SI = address of dot command routine
				; DX:DI = address of help text
				; returns AX == 0, no errors
				;	  AX != 0, dot command already used
				;		   or out of dot commands
				; Dot command routine:
				;   AL = command character
				;   DS:SI = linear address of command line
				;	    terminated by a NULL or ";".
				;   DS,ES = debugger's data selector
				;   returns AX == 0, no errors
				;	    AX !=0, command line or option error

D386_DeRegisterDotCmd	equ 56h	; de-registers dot command
				; BL = command letter

D386_Printf		equ 57h	; Printf
				; (DS:SI) = address of format string
				; (ES:DI) = address of the start of parameters
				; set DS_Printf for format char information
				; returns (AX) = number of characters printed

D386_Link_Sym_Phys	equ 58h	; link symbol file with physical address
				; (DX:CX) = physical address of one extra 
	 			;  paragraph front of map file image.
				; (SI) = XMS handle (0 if just physical)
				; (BX) = load id

D386_CheckMap		equ 59h	; DX:DI = pointer to module name
				; returns AX != 0, map found
				;	  AX == 0, map not found

D386_SetAutoLoadSym	equ 5ah	; (BL) != 0, auto load symbols
				; (BL) == 0, don't auto load symbols

D386_SetTeftiPort	equ 5bh	; (BX) = TEFTI port address

D386_ExecDebugCommand	equ 5ch	; execute debugger command script
				; (DS:SI) = ptr to debugger command script str
				; (CX) = size of script

D386_LoadCodeDataHigh	equ 5dh	; makes the debugger copy its code/data high
				; (DX:BX) = physical address to put debugger

D386_SetWinVersion	equ 5eh	; sets Windows version number
				; (DI) = Version number (default if this
				; api not called is 0300h).

D386_ScanChar		equ 5fh ; scan for character
				; returns AL == 0, no char. AL != 0, char

D386_UnGetChar		equ 60h ; ungetchar scaned character, AL = char

D386_Stop		equ 61h	; stop at the CS:IP specified
				; TOS + 0 = AX
				; TOS + 2 = IP
				; TOS + 4 = CS

D386_MAX		equ 61h	; maximum INT 68 function code

; D386_Load_Segment type equates:

ST_code_sel	equ 0		; code selector
ST_data_sel	equ 1		; data selector
ST_code_seg	equ 10h		; code segment
ST_data_seg	equ 11h		; data segment
ST_dual_code	equ 40h		; code segment and selector
ST_dual_data	equ 41h		; data segment and selector
ST_device_code	equ 80h		; device driver code segment
ST_device_data	equ 81h		; device driver data segment

; D386_Load_Segment device load parameters structure

D386_Device_Params STRUC
DD_logical_seg	dw  ?	; logical segment # from map
DD_actual_sel	dw  ?	; actual selector value
DD_base		dd  ?	; linear address offset for start of segment
DD_length	dd  ?	; actual length of segment
DD_name		df  ?	; 16:32 ptr to null terminated device name
DD_sym_name	df  ?	; 16:32 ptr to null terminated symbolic
			; module name  (i.e. Win386)
DD_alias_sel	dw  ?	; alias selector value (0 = none)
D386_Device_Params ENDS

; WDEB int 2f subfunctions (AH = W386_INT_MULTIPLEX, AL = W386_WDEB)
; Entry: BX = subfunction number

WDEB_INT2F_STARTING		equ	0	; first time starting
WDEB_INT2F_ENDING		equ	1	; first time ending
WDEB_INT2F_NESTED_STARTING	equ	2	; start on level of nesting
WDEB_INT2F_NESTED_ENDING	equ	3	; end one level of nesting

; PMINIT routine functions

PMINIT_INIT_IDT			equ	0	; (ES:EDI) = pointer to PM IDT

PMINIT_INIT_PAGING		equ	1	; (BX) = phys-linear selector 
						; (ECX) = phys-linear bias

PMINIT_ENABLE_DEBUG_QUERYS	equ	2	; enables dot commands, etc.

PMINIT_INIT_SPARE_PTE		equ	3	; (EBX) = lin addr of spare PTE
						; (EDX) = lin addr the PTE is

PMINIT_SET_ENTER_EXIT_VMM	equ	4	; (EBX) = Enter VMM routine addr
						; (ECX) = Exit VMM routine addr
						; This routines must return 
						; with a retfd.

PMINIT_GET_SIZE_PHYS		equ	5	; get debugger size/phys addr
						; returns:
						;     AL = 0 (don't call AL=1)
						;     ECX = size in bytes
						;     ESI = starting phys addr
						; if this call is ignored
						; (AL = 5) then function 1 is
						; called with a phys-linear
						; region

PMINIT_SET_BASE_SPARE_PTE	equ	6	; set debugger base/spare PTE
						; EBX = laddr of spare PTE
						; EDX = laddr the PTE represents
						; ESI = starting linear address

PMINIT_ENABLE_MEMORY_CONTEXT	equ	7	; enables mem context functions

PMINIT_MAX			equ	7

;
; VCPI information, passed to debugger when client is DOS Extender
; running as a VCPI client.  This information is used to get into
; and out of protected mode when running under a VCPI server.
;
;
; This structure is also used by the DOS Extender.
;
WdebVCPIInfo	  STRUC
;
; Enter protected mode information.
;
	fnVCPI	df	?	; VCPI protect mode server entry point
	rdsVCPI	dw	?	; Selector for VCPI server
;
; Enter v86 mode information.
;
	laVTP	dd	?	; linear address of data structure containing
				; values for system registers.
	Port67	dw	?	; Qualitas magic port for emulating INT 67h
WdebVCPIInfo	  ENDS
;
; The following structure contains the system register contents for the
; VCPI server to use when switching to protected mode.  It is taken
; from dxvcpi.inc in the DOSX project, and is part of the VCPI spec.
;
VTP	struc
	zaCr3VTP	dd	0	; physical addr of page directory
	laGdtrVTP	dd	0	; linear addr in first meg of gdtr
	laIdtrVTP	dd	0	; linear addr in first meg of idtr
	selLdtVTP	dw	0	; selector of ldt
	selTrVTP	dw	0	; selector of tr
	ipVTP		dw	0	; 48-bit address of protect
	unusedVTP	dw	0	;   mode entry point to xfer to
	csVTP		dw	0	;
VTP	ends

VCPI_RM_CALLOUT_INT	equ	67h	; v86 mode call to VCPI server
;
; Send this value in AX to the VCPI server to request V86 to protected
; mode switch or protected to V86 mode switch.
;
VCPI_PROT_ENTRY		equ	0DE0CH


;******************************************************************************
;
;  Protected mode Debugger services:
;
;


Debug_Serv_Int	     equ 41h	; Interrupt that calls Deb386 to perform
				; debugging I/O, AX selects the function as
				; described by the following equates

DS_Out_Char	equ	0	; function to display the char in DL

DS_In_Char	equ	1	; function to read a char into AL

DS_Out_Str	equ	2	; function to display a NUL terminated string
				; pointed to by DS:ESI

DS_Is_Char	equ	3	; Non blocking In_Chr

DS_Out_Str16	equ    12h	; function to display a NUL terminated string
				; pointed to by DS:SI
				; (same as function 2, but for 16 bit callers)

DS_ForcedGO16	equ    40h	; enter the debugger and perform the equivalent
				; of a GO command to force a stop at the
				; specified CS:IP
				; CX is the desired CS
				; BX is the desired IP

DS_LinkMap	equ    45h	; DX:(E)DI = ptr to paragraph in front of map

DS_UnlinkMap	equ    46h	; DX:(E)DI = ptr to paragraph in front of map

DS_CheckMap	equ    47h	; DX:(E)DI = pointer to module name
				; returns AX != 0, map found
				;	  AX == 0, map not found

DS_IsAutoLoadSym equ   48h	; returns AX != 0, auto load symbols
				; 	  AX == 0, don't auto load symbols

DS_DebLoaded	equ    4Fh	; check to see if the debugger is installed and
				; knows how to deal with protected mode programs
				; return AX = F386h, if true
DS_DebPresent	equ   0F386h

DS_LoadSeg	equ    50h	; define a segment value for the
				; debugger's symbol handling
				; SI type   0  - code selector
				;	    1  - data selector
				;	   80h - code segment
				;	   81h - data segment
				; BX segment #
				; CX actual segment/selector
				; DX data instance
				; ES:(E)DI pointer to module name

DS_LoadSeg_32	equ  0150h	; Define a 32-bit segment for Windows 32
				; SI type   0  - code selector
				;	    1  - data selector
				; DX:EBX points to a D386_Device_Params STRUC
				; with all the necessaries in it

DS_MoveSeg	equ    51h	; notify the debugger that a segment has moved
				; BX old segment value
				; CX new segment value

DS_FreeSeg	equ    52h	; notify the debugger that a segment has been
				; freed
				; BX segment value

DS_FreeSeg_32	equ  0152h	; notify the debugger that a segment has been
				; freed
				; BX segment number
				; DX:EDI pointer to module name

DS_DGH		equ    56h	; register "dump global heap" handler
				; BX is code offset
				; CX is code segment

DS_DFL		equ    57h	; register "dump free list" handler
				; BX is code offset
				; CX is code segment

DS_DLL		equ    58h	; register "dump LRU list" handler
				; BX is code offset
				; CX is code segment

DS_StartTask	equ    59h	; notify debugger that a new task is starting
				; BX is task handle
				; task's initial registers are stored on the
				; stack:
				;	push	cs
				;	push	ip
				;	pusha
				;	push	ds
				;	push	es
				;	push	ss
				;	push	sp

DS_Kernel_Vars	equ    5ah	; Used by the Windows kernel to tell the
				; debugger the location of kernel variables
				; used in the heap dump commands.
				; BX = version number of this data (03a0h)
				; DX:CX points to:
				;	WORD	 hGlobalHeap	****
				;	WORD	 pGlobalHeap	****
				;	WORD	 hExeHead	****
				;	WORD	 hExeSweep
				;	WORD	 topPDB
				;	WORD	 headPDB
				;	WORD	 topsizePDB
				;	WORD	 headTDB	****
				;	WORD	 curTDB		****
				;	WORD	 loadTDB
				;	WORD	 LockTDB
				;	WORD	 SelTableLen	****
				;	DWORD	 SelTableStart	****
				;
				; The starred fields are used by the
				; heap dump commands which are internal
				; to WDEB386.


DS_VCPI_Notify	equ    5bh	; notify debugger that DOS extender is
				; running under a VCPI implementation,
				; and register VCPI protect mode interface
				; ES:DI points to a data structure used to
				; get from V86 mode to Pmode under VCPI.
				; This is defined in the VCPI version
				; 1.0 spec.

DS_ReleaseSeg	equ    5ch	; This does the same as a DS_FreeSeg, but
				; it restores any breakpoints first.

DS_User_Vars    equ    5dh	; DS:SI = pointer to an array of offsets:
				; BX = windows version		
				; CX = number of words in array
                                ;       WORD = fDebugUser (1 = DEBUG, 0 = RETAIL)
				;       WORD = 16 bit offset to hHmenuSel
				;       WORD = 16 bit offset to hHwndSel
				;       WORD = 16 bit offset to pclsList
				;       WORD = 16 bit offset to pdceFirst
                                ;       WORD = 16 bit offset to hwndDesktop
				; This array MUST BE COPIED it goes away
				; when we return from this service.

DS_POSTLOAD	=	60h	; Used by the RegisterPTrace interface
DS_EXITCALL	=	62h	; Somebody will fill these in if we ever
DS_INT2		=	63h	; figure out what they are supposed to do.
DS_LOADDLL	=	64h
DS_DELMODULE	=	65h

DS_NEWTASK	=	0BH
DS_FLUSHTASK	=	0CH
DS_SWITCHOUT	=	0DH
DS_SWITCHIN	=	0EH

DS_IntRings	equ    20h	; function to tell debugger which INT 1's & 3's
				; to grab
				; BX = 0, grab only ring 0 ints
				; BX != 0, grab all ints

DS_IncludeSegs	equ    21h	; function to tell debugger to go ahead and
				; process INT 1's & 3's which occur in this
				; DX:DI points to list of selectors
				;   (1 word per entry)
				; CX = # of selectors (maximum of 20)
				;   CX = 0, to remove the list of segs
MaxDebugSegs = 20

DS_CondBP	equ 0F001h	; conditional break pt, if the command line
				; switch /B is given when the debugger is run
				; or the conditional flag is later set, then
				; this int should cause the program to break
				; into the debugger, else this int should be
				; ignored!
				; ESI points to a nul terminated string to
				; display if break is to happen.

DS_ForcedBP	equ 0F002h	; break pt, which accomplishes the same thing
				; as an INT 1 or an INT 3, but is a break point
				; that should be permanently left in the code,
				; so that a random search of source code would
				; not result in the accidental removal of this
				; necessary break_pt

DS_ForcedGO	equ 0F003h	; enter the debugger and perform the equivalent
				; of a GO command to force a stop at the
				; specified CS:EIP
				; CX is the desired CS
				; EBX is the desired EIP

DS_HardINT1	equ 0F004h	; check to see if INT 1 hooked for all rings
				; ENTER: nothing
				; EXIT: AX = 0, if no, 1, if yes

DS_Out_Symbol	equ    0Fh	; find the symbol nearest to the address in
				; CX:EBX and display the result in the format
				; symbol name <+offset>
				; the offset is only included if needed, and
				; no CR&LF is displayed

DS_Disasm_Ins	equ    10h	; function to disassemble the instruction
				; pointed to by DS:ESI

DS_JumpTableStart      equ 70h

;**	DS_RegisterDotCommand
;
;	This interface is used to register wdeb386 dot commands by FLAT 32
;	bit code.  The following conditions apply:
;
;	* The code will be run at ring 0
;	* Interrupts may be enabled
;	* Must not access any invalid pages or load invalid selectors
;	* Must stay on the stack called with when calling INT 41 services
;	* Must not change DS or ES from the FLAT selector
;
;	The help text is printed when .? is executed in the order of
;	registration.  The text must include CR/LF at the end; nothing
;	is added to the help text.
;
;	ENTRY:	(AX) = 0070h
;		(BL) = dot command to register
;		(ESI) = linear address of dot command routine
;		    Dot command routine:
;			ENTRY:	(AL) = command character
;				(DS, ES) = flat data selector
;
;			EXIT:	(AX) == 0, no errors
;				(AX) != 0, command line or option error
;
;			NOTE:	MUST return with a 32 bit FAR return (retfd)
;		(EDI) = linear address of help text
;
;	EXIT:	(AX) == 0, no errors
;		(AX) != 0, dot command already used or out of dot commands

DS_RegisterDotCommand  equ 70h

;**	DS_RegisterDotCommand16
;
;	This interface is used to register wdeb386 dot commands by 16 bit
;	code.  The following conditions apply:
;
;	* The code will be run at ring 0 or in real mode
;	* Interrupts may not be enabled
;	* Must not access any not present pages or load invalid selectors
;	* Must stay on the stack called with when calling INT 41 services
;
;	The help text is printed when .? is executed in the order of
;	registration.  The text must include CR/LF at the end; nothing
;	is added to the help text.
;
;	ENTRY:	(AX) = 0071h
;		(BL) = dot command to register
;		(CX:SI) = address of dot command routine
;		    Dot command routine:
;			ENTRY:	(AL) = command character
;				(DS, ES) = debugger's data selector
;
;			EXIT:	(AX) == 0, no errors
;				(AX) != 0, command line or option error
;
;			NOTE:	MUST return with a 16 bit FAR return (retf)
;		(DX:DI) = address of help text
;
;	EXIT:	(AX) == 0, no errors
;		(AX) != 0, dot command already used or out of dot commands

DS_RegisterDotCommand16 equ 71h

;**	DS_DeRegisterDotCommand
;
;	This interface is used to de-register wdeb386 dot commands registered
;	by the above 16 or 32 bit services.  Care should be used not to
;	de-register dot commands that weren't registered by your code.
;
;	ENTRY:	(AX) = 0072h
;		(BL) = dot command to de-register
;
;	EXIT:	NONE

DS_DeRegisterDotCommand equ 72h

;**	DS_Printf
;
;	This function allows formatted output with the standard "C"
;	printf syntax.
;
;	ENTRY:	(AX) = 0073h
;		(DS:ESI) = address of format string
;		(ES:EDI) = address of the start of the dword arguments
;
;	EXIT:	(EAX) = number of characters printed
;
;	Supported types are:
;
;	%%							%
;	%[l][h]c						character
;	%[-][+][ ][0][width][.precision][l|h|p|n]d		decimal
;	%[-][0][width][.precision][l|h|p|n]u			unsigned decimal
;	%[-][#][0][width][.precision][l|h|p|n]x			hex
;	%[-][#][0][width][.precision][l|h|p|n]X			hex
;	%[-][0][width][.precision][l|h|p|n]o			octal
;	%[-][0][width][.precision][l|h|p|n]b			binary
;	%[-][width][.precision][l|h|a|F|R|P]s			string
;	%[-][width][.precision][l|h|a|p|n|F|L|R|L|H|N|Z]A	address
;	%[-][width][.precision][l|h|a|p|n|F|L|R|L|H|N|Z]S	symbol
;	%[-][width][.precision][l|h|a|p|n|F|L|R|L|H|N|Z]G	group:symbol
;	%[-][width][.precision][l|h|a|p|n|F|L|R|L|H|N|Z]M	map:group:symbol
;	%[-][width][.precision][l|h|a|p|n|F|L|R|L|H|N|Z]g	group
;	%[-][width][.precision][l|h|a|p|n|F|L|R|L|H|N|Z]m	map
;
;	Where "width" or "precision" is a decimal number or the '*' 
;	character; '*' causes the field width or precision to be picked
;	up from the next parameter. []'ed parameters are optional.
;
;
;	"\r", "\t", "\n", "\a", "\b", are supported directly.
;
;	Prefixes
;	--------
;
;	Used with c,d,u,x,X,o,b:
;
;	Parameter Argument Size
;	-----------------------
;	word					h
;	dword					l
;
;	Used with s,A,S,G,M,g,m:
;
;	Address Argument Size
;	---------------------
;	16 bit DS relative			h
;	16:16 segment:offset			hF or Fh
;	32 bit flat relative			l
;	16:32 segment:offset (2 dwords)		lF or Fl
;	pointer to AddrS structure		a
;	segment is a real mode segment		R
;	segment is a protected mode selector	P
;
;	Default segment type is the current code type.
;
;	Used with A,S,G,M,g,m:
;
;	Address Display Size or Format
;	------------------------------
;	16 bit offset				H
;	32 bit offset				L
;	offset only				N
;	no address				Z
;
;	Default display size depends on the "386env" flag setting.
;
;	Used with S,G,M,g,m:
;
;	gets the previous symbol		p
;	gets the next symbol			n
;
;	Used with A:
;
;	gets the previous symbol address	p
;	gets the next symbol address		n
;
;	Used with d,u,x,X,o,b:
;
;	gets the previous symbol offset		p
;	gets the next symbol offset		n
;

DS_Printf	equ	73h

;**	DS_Printf16
;
;	This function allows formatted output with the standard "C"
;	printf syntax.
;
;	ENTRY:	(AX) = 0074h
;		(DS:SI) = address of format string
;		(ES:DI) = address of the start of the word or dword arguments
;
;	EXIT:	(AX) = number of characters printed
;
;	The format options and parameters are the same as DS_Printf except
;	the default parameter size is a word (the h option is implicit).
;

DS_Printf16 equ 74h

;**	DS_GetRegisterSet
;
;	This function copies the current register set.
;
;	ENTRY:	(AX) = 0075h
;		(DS:ESI) = address of SaveRegs_Struc structure
;
;	EXIT:	NONE
;

DS_GetRegisterSet equ 75h

;**	DS_SetAlternateRegisterSet
;
;	This function temporary sets the debugger's registers to values
;	passed in the structure.  If an "r" command is executed or the
;	debugged code is returned to (via the "g", "t" or "p" commands),
;	the register set reverts to the debugged code's registers.
;
;	ENTRY:	(AX) = 0076h
;		(CX) = thread ID, 0 use current thread ID
;		(DS:ESI) = address of SaveRegs_Struc structure
;
;	EXIT:	NONE
;

DS_SetAlternateRegisterSet equ 76h

;**	DS_GetCommandLineChar
;
;	This services gets the next character off the command line.
;
;	ENTRY:	(AX) = 0077h
;		(BL) = 0 just peek the character, don't increment text pointer
;		         leading white space isn't ignored
;		(BL) = 1 get the character, increment text pointer
;			 leading white space is skipped
;		(BL) = 2 peek the character, don't increment text pointer
;			 leading white space is skipped
;
;	EXIT:	(AL) = command line character
;		(AH) == 0 if no more characters (EOL)
;		(AH) != 0 if more characters
;

DS_GetCommandLineChar equ 77h

;**	DS_EvaluateExpression
;
;	Expressions can be numbers of various radices, symbols, addresses
;	or an combination of the above hooked together with various
;	operators.  Expressions are separated by blanks or commas.  This
;	function is passed a pointer to the beginning of the text of the
;	expression (i.e. "%80003444+4232").  The expression is either
;	evaluated down into a dword value if there are no addresses or 
;	into a linear address.
;
;	ENTRY:	(AX) = 0078h
;
;	EXIT:	(AX) == 0, returning a data value
;		(AX) != 0, returning a linear address
;		(CX) = thread id
;		(EBX) = return value
;
;	NOTE:	If the expression is invalid, this service will not
;		return.  A message is printed and control returns to
;		the command loop.
;

DS_EvaluateExpression equ 78h

;**	DS_VerifyMemory
;
;	ENTRY:	(AX) = 0079h
;		(ECX) = length of memory region
;		(DS:ESI) = address of memory to verify
;
;	EXIT:	(AX) == 0, no errors
;		(AX) != 0, invalid memory

DS_VerifyMemory	equ 79h

;**	DS_PrintRegisters
;
;	This function prints (just like the "r" command) the either the
;	debugged code's registers or the alternate register set, set with
;	DS_SetAlternateRegisterSet function.
;
;	ENTRY:	(AX) = 007ah
;
;	EXIT:	NONE
;
;	NOTE:	If the CS:EIP is invalid, this service will not return
;		because of an error when the code is disassembled.  A 
;		message is printed and control returns to the command loop.
;

DS_PrintRegisters equ 7ah

;**	DS_PrintStackDump
;
;	This function prints (just like the "k" command) the stack dump
;	based on the current register set that may have been set with 
;	DS_SetAlternateRegisterSet function.
;
;	ENTRY:	(AX) = 007bh
;		(BX) = flags
;			01h - verbose stack dump
;			02h - 16 bit stack dump
;			04h - 32 bit stack dump
;
;	EXIT:	NONE
;
;	NOTE:	If the CS:EIP or SS:EBP are invalid, this service will not
;		return because of an error when accessing the stack.  A 
;		message is printed and control returns to the command loop.
;

DS_PrintStackDump equ 7bh

;**	DS_SetThreadID
;
;	This function sets what the debugger thinks the thread ID is
;	for memory address in other address contexts.  It stays set
;	until the debugged code is returned to (via "g", "t" or "p")
;	or set back to 0.
;
;	ENTRY:	(AX) = 007ch
;		(CX) = thread ID or 0 for currently executed thread
;
;	EXIT:	NONE

DS_SetThreadID	equ  7ch

;**	DS_ExecDebugCommand
;
;	This service allows any debugger command to be executed.  In can
;	be a multi-lined script with the lines separated by CR, LF.  MUST
;	have a "g" command at the end of script so the debugger doesn't
;	stop while in the INT 41.
;
;	ENTRY:	(AX) = 007dh
;		(DS:ESI) = pointer to debugger command script string
;		(CX) = size of script
;
;	EXIT:	NONE
;
;	NOTE:	If the any kind of error happens, this service will not
;		return.  A message is printed and control returns to the
;		command loop.
;

DS_ExecDebugCommand equ  7dh

;**	DS_GetDebuggerInfo
;
;	This service returns various debugger info and routines.
;
;	ENTRY:	(AX) = 007eh
;		(DS:ESI) = pointer to DebInfoBuf structure
;		(ECX) = size of the above buffer.  Only this many bytes are
;			copied to the buffer; this allows more info to be
;			passed in future versions without breaking anything.
;
;	EXIT:	(AX) == 0, no errors
;		(AX) != 0, error:   (AX) == 007eh, function not implemented
;				    (AX) == anything else, invalid buffer

DS_GetDebuggerInfo equ 7eh

;**	DS_CheckFault
;
;	This service checks if the debugger wants control on the fault.
;
;	ENTRY:	(AX) = 007fh
;		(BX) = fault number
;		(CX) = fault type mask
;			DEBUG_FAULT_TYPE_V86
;			DEBUG_FAULT_TYPE_PM
;			DEBUG_FAULT_TYPE_RING0
;			DEBUG_FAULT_TYPE_FIRST
;			DEBUG_FAULT_TYPE_LAST
;
;	EXIT:	(AX) == 0, handle fault normally
;		(AX) != 0, handled by debugger

DS_CheckFault equ 7fh	

;**	DS_SetBreak
;
;	This service allows an error break or ctrl-c handler to be
;	set.  The old value that is returned must be save and set
;	back to remove the break handler.
;
;	ENTRY:	(AX) = 0080h
;		(DS:ESI) = pointer to BreakStruc with the CS:EIP and
;		SS:ESP values to be used when a error break or ctrl-c
;		happens.  The old value is copied into this buffer.
;
;	EXIT:	(AX) == 0, no error
;		(AX) != 0, error on BreakStruc address

DS_SetBreak equ 80h	

;**	DS_RedirectExec
;
;	This service redirects the input and output streams to the
;	specified buffers for the debugger command line passed.
;
;	ENTRY:	(AX) = 0081h
;		(DS:ESI) = pointer to RedirectExecStruc
;
;	EXIT:	(ECX) = number of bytes written
;		(AX) == 0, no error
;		(AX) != 0, error
;		   	1 to 10 = memory access error
;			-1      = buffer overflow
;			-2      = invalid parameter, not on a 386, or reentered

DS_RedirectExec equ 81h	

;**	DS_PassOnDebugCommand
;
;	Used to tell the debugger to pass this dot command on to the
;	next handler.
;
;	ENTRY:	(AX) = 0082h
;
;	EXIT:	NONE
;

DS_PassOnDebugCommand equ 82h	

;**	DS_TrapFault
;
;	Allows ring 3 code to send a fault to the debugger
;
;	ENTRY:	(AX) = 0083h
;		(BX) = fault number
;		(CX) = faulting CS
;		(EDX) = faulting EIP
;		(ESI) = fault error code
;		(EDI) = faulting flags
;
;	EXIT:	(CX) = replacement CS
;		(EDX) = replacement EIP

DS_TrapFault equ 83h	

;**	DS_SetStackTraceCallBack
;
;	Sets the "k" command callback filter used to back trace
;	thru thunks.
;
;	ENTRY:	(AX) = 0084h
;		(EBX) = linear address of call back routine, zero to uninstall
;		(ECX) = linear address of the end of the call back routine
;		(EDX) = EIP to use for for faults in call back routine
;
;	EXIT:	NONE
;
;	CALLBACK:
;		ENTRY:	(EAX) = linear base of SS
;			(EBX) = linear address of SS:EBP
;			(DS, ES) = flat ds
;			(SS) = NOT flat ds !!!!!!!!!
;
;		EXIT:	(EAX) = FALSE, no thunk
;				TRUE, is a thunk
;					(CX:ESI) = new SS:EBP
;					(DX:EDI) = new CS:EIP
;

DS_SetStackTraceCallBack equ 84h

;**	DS_RemoveSegs
;
;	Removes all the undefined groups from a map file.
;
;	ENTRY:	(AX) = 0085h
;		(ES:EDI) pointer to module name
;
;	EXIT:	NONE
;

DS_RemoveSegs equ 85h	

;**	DS_DefineDebugSegs
;
;	Defines the debugger's code and data symbols.
;
;	ENTRY:	(AX) = 0086h
;
;	EXIT:	NONE
;

DS_DefineDebugSegs equ 86h	

;**	DS_SetBaudRate
;
;	Sets the com port's baud rate
;
;	ENTRY:	(AX) = 0087h
;		(BX) = baud rate
;
;	EXIT:	NONE
;

DS_SetBaudRate equ 87h

;**	DS_SetComPort
;
;	Sets the com port's baud rate
;
;	ENTRY:	(AX) = 0088h
;		(BX) = com port number
;
;	EXIT:	(AX) == 0, ok
;		(AX) != 0, error bad com port
;

DS_SetComPort equ 88h	

;**	DS_ChangeTaskNum
;
;	Changes a task number to another task number or
;	indicates that the task has gone away.
;
;	ENTRY:	(AX) = 0089h
;		(CX) = old task number
;		(DX) = new task number or -1 if process terminated.
;
;	EXIT:	NONE
;

DS_ChangeTaskNum equ 89h	

;**	DS_ExitCleanup
;
;	Called when Windows exits.
;
;	ENTRY:	(AX) = 008ah
;
;	EXIT:	NONE
;

DS_ExitCleanup equ 8ah	

;**     DS_InstallVGAHandler
;
;       Called when the Debug VxD is initializing (during Device Init),
;       to specify an alternate I/O handler for VGA.  The handler accepts the
;       following inputs:
;
;           BX == subfunction #:
;                   0 == save screen state (switch to debugger context)
;                        No inputs/outputs
;                   1 == restore screen state (switch to windows context)
;                        No inputs/outputs
;                   2 == display output character (ie, OEMOutputCharCOM)
;                        on input, AL == character
;                   3 == check for input character (ie, OEMScanCharCOM)
;                        on output, ZR if no chars, else NZ and AL == char
;
;       ENTRY:  (AX) = 008bh
;               (DX:EDI) == 16:32 address to call, with BX == subfunction above
;
;	EXIT:	NONE
;

DS_InstallVGAHandler equ 8bh

;**	DS_GetComBase
;
;	Called when Debug VxD is initializing (during Device Init),
;	to get the base of the com port being used by wdeb386.
;
;	Entry:
;		(AX) == 008ch
;
;	Exit:
;		(AX) = base of COM port.
;

DS_GetComBase	equ	8ch

;**	DS_GetSymbol
;
;	Looks up a symbol and returns the linear address and segment/offset.
;
;	ENTRY:	(AX) == 008dh
;               (DS:ESI) = ptr to null-terminated symbol
;
;	EXIT:	(AX) == 0, no error
;               (AX) == 1, symbol not found
;               (AX) == 2, memory not loaded yet
;               (ECX) = linear address of variable  (if AX == 0)
;               (EDX) = seg:offset of variable      (if AX == 0)    
;

DS_GetSymbol equ 8dh	

;**	DS_CopyMem
;
;	Copys memory from one AddrS to another AddrS
;
;	ENTRY:	(AX) == 008eh
;               (DS:ESI) = pointer to source AddrS block
;               (ES:EDI) = pointer to destination AddrS block
;		(CX) = number of bytes
;
;	EXIT:	(AX) == 0, no error
;               (AX) != 0, invalid address
;

DS_CopyMem equ 8eh	

DS_JumpTableEnd equ 8eh

SaveRegs_Struc	struc
	Debug_EAX		dd	?
	Debug_EBX		dd	?
	Debug_ECX		dd	?
	Debug_EDX		dd	?
	Debug_ESP		dd	?
	Debug_EBP		dd	?
	Debug_ESI		dd	?
	Debug_EDI		dd	?
	Debug_ES		dw	?
	Debug_SS		dw	?
	Debug_DS		dw	?
	Debug_FS		dw	?
	Debug_GS		dw	?
	Debug_EIP		dd	?
	Debug_CS		dw	?
				dd	?
	Debug_EFlags		dd	?
	Debug_CR0		dd	?
	Debug_GDT		dq	?
	Debug_IDT		dq	?
	Debug_LDT		dw	?
	Debug_TR		dw	?
	Debug_CR2		dd	?
	Debug_CR3		dd	?
	Debug_DR0		dd	?
	Debug_DR1		dd	?
	Debug_DR2		dd	?
	Debug_DR3		dd	?
	Debug_DR6		dd	?
	Debug_DR7		dd	?
	Debug_DR7_2		dd	?
	Debug_TR6		dd	?
	Debug_TR7		dd	?
	Debug_TrapNumber	dw	-1	; -1 means no trap number
	Debug_ErrorCode		dw	0	; 0 means no error code
SaveRegs_Struc ends

DebInfoBuf	struc
	DIB_MajorVersion	db	0
	DIB_MinorVersion	db	0
	DIB_Revision		db	0
				db	0	; reserved
	DIB_DebugTrap16		dd	0	; send 16 bit trap to debugger
	DIB_DebugTrap32		df	0	; send 32 bit trap to debugger
	DIB_DebugBreak16	dd	0	; 16 bit break in debugger
	DIB_DebugBreak32	df	0	; 32 bit break in debugger
	DIB_DebugCtrlC16	dd	0	; 16 bit check for ctrl C
	DIB_DebugCtrlC32	df	0	; 32 bit check for ctrl C
DebInfoBuf	ends

BreakStruc	struc
	BS_BreakEIP		dd	0	; CS:EIP, SS:ESP to go to
	BS_BreakCS		dw	0	;  on a error or ctrlc break
	BS_BreakESP		dd	0
	BS_BreakSS		dw	0
BreakStruc	ends

RedirectExecStruc	struc
	RDE_fpbufDebugCommand	df	0	; debugger command script
	RDE_cbDebugCommand	dw	0	; debugger command script len
	RDE_fpszInput		df	0	; input stream pointer
	RDE_usFlags		dw	0	; reserved (must be 0)
	RDE_cbOutput		dd	0	; size of output buffer
	RDE_fpbufOutput		df	0	; output buffer pointer
RedirectExecStruc	ends

REPEAT_FOREVER_CHAR	equ	0feh		; send next character until
						;  end of debugger command

AddrS	struc					; for printf service
	AddrOff		dd	0
	AddrSeg		dw	0
	AddrType	db	0
	AddrSize	db	0
	AddrTask	dw	0
AddrS	ends

AddrTypeSize	equ	word ptr AddrType

EXPR_TYPE_SEG		equ	00000001b	; address type segment:offset
EXPR_TYPE_SEL		equ	00001001b	; address type selector:offset
EXPR_TYPE_LIN		equ	00000010b	; address type linear
EXPR_TYPE_PHY		equ	00001010b	; address type physical
EXPR_TYPE_LOG		equ	00001000b	; logical address (no sel yet)

DEBUG_FAULT_TYPE_V86		equ	00000001b
DEBUG_FAULT_TYPE_PM		equ	00000010b
DEBUG_FAULT_TYPE_RING0		equ	00000100b
DEBUG_FAULT_TYPE_FIRST		equ	00001000b
DEBUG_FAULT_TYPE_LAST		equ	00010000b

;
;   Interrupt and services that Win386 provides to the debugger
;

Win386_Query_Int    equ 22h	; interrupt for Win386 protected mode
				; interface requests

Win386_Alive	    equ 0	; function 0, query Win386 installation
Win386_Q_Ack	    equ 0F386h	;	good response from func 43h, of
				;	INT 68h & func 4fh of INT 41h

Win386_Query	    equ 1	; function 1, query Win386 state
				;	ds:esi points to command string
				;	that Win386 needs to process
				;	ds:edi points to the SaveRegs_Struc
				;	that the debugger has stored all the
				;	client register state into.
				;	(Win386 just writes the query
				;	answers directly to the output
				;	device, so no response is
				;	returned)

Win386_PhysToLinr   equ 2	; function 2, have Win386 convert a
				;	physical address into a valid
				;	linear address that Deb386 can
				;	use.  esi is physicaladdress
				;	cx is # of bytes required
				;	returns esi as linear address
				;	returns ax = 1, if okay, else
				;	0, if request couldn't be
				;	completed

Win386_AddrValid    equ 3	; function 3, have Win386 check the
				;	validity of a linear address
				;	esi is linear address to check
				;	cx is # of bytes required
				;	returns ax = 1, if address okay
				;	else ax = 0

Win386_MapVM	    equ 4	; function 4, make sure that the VM's
				;	low memory is mapped in, in case
				; 	it is touched (a count is maintained)

Win386_UnmapVM	    equ 5	; function 5, map out the VM's low
				; 	memory (dec the count)

Win386_GetDLAddr    equ 6	; function 6, return offset of dyna-link
				; 	service.  EBX = Device ID << 10h +
				; 	Service #.  Returns EAX = Offset.

Win386_GetVXDName   equ 7       ; function 7, determines whether an address
                                ;       is within a VXD object.
				;   DS:ESI -> buffer to receive object name
				;      BX  =  thread number
				;     EDX  = linear address to query
				;   If EAX == 0, EDX = base address of object
				;   If EAX != 0, error

Win386_GetPDE       equ 8       ; function 8, get pde for a context
				;	BX = thread number
				;	EDX = linear address
				;       if EAX == 0, ECX = PDE
				;       if EAX != 0, error

Win386_GetFrame     equ 9       ; function 9, get phys addr for not pres ptes
				;	BX = thread number
				;	EDX = linear address
				;       ECX = PDE or PTE
				;	ESI = 0 if PDE, !0 if PTE
				;       if EAX == 0, EDX = physical address
				;       if EAX != 0, error

Win386_GetLDTAddress  equ 10    ; function 10,
				;       BX = thread number
				;       if EAX == 0,
				;		EDI = pointer to LDT
				;		ECX = ldt limit
				;       if EAX != 0, error

Win386_GetThreadID  equ 11      ; function 11, AX = Current Thread ID

Win386_GetTSHandler    equ 12	; function 12, return offset of transfer-space
				; 	fault handler.  EBX = 16:16 addr of
				; 	int 30h.  Returns EAX = Offset or 0.

Win386_GetArplHandler    equ 13	; function 12, return offset of ARPL fault
				; 	fault handler.  EBX = 16:16 addr of
				; 	ARPL.  Returns EAX = Offset or 0.

Max_Win386_Services equ 13
