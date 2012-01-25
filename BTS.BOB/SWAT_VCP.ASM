;' $Header:   P:/PVCS/386SWAT/SWAT_VCP.ASV   1.56   10 Aug 1998 11:02:26   BOB  $
	title	SWAT_VCP -- 386SWAT VCPI Functions
	page	58,122
	name	SWAT_VCP

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-2003 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include 386.INC
	include 8255.INC
	include VCPI.INC
	include PTR.INC
	include BITFLAGS.INC
	include CPUFLAGS.INC
	include OPCODES.INC
	include MAXDEV.INC
NOVER_HTU equ	1
	include VERSION.INC
	include CMOS.INC
	include ALLMEM.INC
	include MASM5.MAC
	include IOPBITS.INC
	include MOVSPR.INC
	include CPUFET.INC

	include SWAT_CMD.INC
	include SWAT_COM.INC
	include SWAT_DRV.INC
	include SWAT_OLD.INC
	include SWAT_SEG.INC
	include SWAT_VCP.INC
	include SWAT_VID.INC
	include PDTGRP.INC
.list


RCODE	segment use16 para public 'rcode' ; Start RCODE segment
	assume	cs:RGROUP,ds:RGROUP

	public	@SWAT_VCP_RCODE
@SWAT_VCP_RCODE label byte	; Mark module start in .MAP file

	extrn	DEV_GPMITAIL:far
	extrn	RMDEV_GPMITAIL:far
	extrn	DEVINT41_FVEC:fword

RCODE	ends			; End RCODE segment


DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	public	@SWAT_VCP_DATA16
@SWAT_VCP_DATA16 label byte	; Mark module start in .MAP file

	extrn	COMMON:tbyte
	include SWAT_FIL.INC

	extrn	SWATINFO:byte
	include SWAT_INF.INC

	extrn	DBG_FLAG:word
	include SWAT_DBG.INC

	extrn	GPS_FLAG:word
	include SWAT_GPS.INC

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	LC3_FLAG:dword
	include SWAT_LC3.INC

	extrn	SYMAPPND_MODE:byte

	extrn	CMD_LINE:byte
	extrn	CMD_LINE_LEN:dword

	extrn	PaLCLPDIR:dword
	extrn	PLCLPDIR:dword

	extrn	OLDCR3:dword

	extrn	WINBASE:dword
	extrn	SWATCODE:dword
	extrn	SWATDATA:dword
	extrn	CPUFET_FLAG:dword
	extrn	RGRSEG2:word
	extrn	MAXINT:dword

	extrn	PLCLMONO:dword
	extrn	PLCLCOLR:dword
	extrn	PLCLCR3:dword

@TSSINTS equ	<00,01,02,03,05,06,0A,0B,0C,0D,0E>

; Local TSS pointer structures
; N.B.:  Remember to initialize these structures in INIT_REAL

%	irp	XX,<@TSSINTS>

	public	LCLTSS&XX	; Local TSS structure for INT &XX&h
LCLTSS&XX LCLTSS_STR <offset PGROUP:TSS_INT&XX,\
offset DGROUP:TSS&XX,\
,\
offset PGROUP:INT&XX&_MSG,\
,\
VCP_TSS&XX&-VCP_CODE,\
offset PGROUP:LCL_INT&XX,\
CPL0_INTR3 or CPL3,\
CPL0_INTR3 or CPL3,\
,\
,\
&XX&h>

	public	OLDTSSINT&XX&_FVEC,OLDTSSINT&XX&_ARB
	public	LCLINT&XX&_FVEC,OLDINT&XX&_FVEC
	public	LCLINT&XX&_ARB, OLDINT&XX&_ARB
OLDTSSINT&XX&_FVEC equ LCLTSS&XX.OLDINTxx_FWD
OLDTSSINT&XX&_ARB  equ LCLTSS&XX.OLDINTxx_ARB
LCLINT&XX&_FVEC    equ LCLTSS&XX.LCLGATExx_FVEC
LCLINT&XX&_ARB	   equ LCLTSS&XX.LCLGATExx_ARB
OLDINT&XX&_FVEC    equ LCLTSS&XX.OLDGATExx_FVEC
OLDINT&XX&_ARB	   equ LCLTSS&XX.OLDGATExx_ARB

	endm			; IRP

	public	NLCLTSS
NLCLTSS equ	($-LCLTSS00)/(type LCLTSS_STR) ; # LCLTSSxx structures

	public	OLDINT09_FVEC,OLDINT09_ARB
	public	OLDINTB2_FVEC,OLDINTB2_ARB
	public	OLDINTC2_FVEC,OLDINTC2_ARB
	public	OLDINT41_FVEC,OLDINT41_ARB
	public	OLDINT67_FVEC,OLDINT67_ARB
	public	OLDINT68_FVEC,OLDINT68_ARB
OLDINT09_FVEC PTR32_STR <>	; Save area for INT 09h handler
OLDINTB2_FVEC PTR32_STR <>	; ...		    0Bh
OLDINTC2_FVEC PTR32_STR <>	; ...		    0Ch
OLDINT41_FVEC PTR32_STR <>	; ...		    41h
OLDINT67_FVEC PTR32_STR <>	; ...		    67h
OLDINT68_FVEC PTR32_STR <>	; ...		    68h

OLDINT09_ARB db CPL0_INTR3 or CPL3 ; Save area for INT 09h access rights byte
OLDINTB2_ARB db CPL0_INTR3 or CPL3 ; ...	       0Bh
OLDINTC2_ARB db CPL0_INTR3 or CPL3 ; ...	       0Ch
OLDINT41_ARB db CPL0_INTR3 or CPL3 ; ...	       41h
OLDINT67_ARB db CPL0_INTR3 or CPL3 ; ...	       67h
OLDINT68_ARB db CPL0_INTR3 or CPL3 ; ...	       68h


; Local PMG pointer structures
; N.B.:  Remember to initialize these structures in INIT_REAL

%	irp	XX,<@OLDINTS>

	public	LCLPMG&XX	; Local PMG structure for INT &XX&h
LCLPMG&XX LCLPMG_STR <offset PGROUP:LCL_PMG&XX,\
CPL0_INTR3 or CPL3,\
CPL0_INTR3 or CPL3>

	public	LCLPMG&XX&_FVEC,OLDPMG&XX&_FVEC
	public	LCLPMG&XX&_ARB, OLDPMG&XX&_ARB
LCLPMG&XX&_FVEC    equ LCLPMG&XX.LCLPMGxx_FVEC
LCLPMG&XX&_ARB	   equ LCLPMG&XX.LCLPMGxx_ARB
OLDPMG&XX&_FVEC    equ LCLPMG&XX.OLDPMGxx_FVEC
OLDPMG&XX&_ARB	   equ LCLPMG&XX.OLDPMGxx_ARB

	endm			; IRP


	public	VCPICODE,VCPICODE_LIM
	public	VCPIDATA,VCPIDATA_LIM
VCPICODE dd	0		; VCPI code base address
VCPIDATA dd	0		; ...  data ...
VCPICODE_LIM dd ?		; VCPI code limit
VCPIDATA_LIM dd ?		; ...  data ...

	public	PaTMPPAGE
PaTMPPAGE dd	?		; Physical address of temp page

	public	GPMICOUNT
GPMICOUNT dw	0		; GPMI counter to work with 386MAX
				; which requires the INT 67h to come
				; from its high DOS segment
	public	VMSCOUNT
VMSCOUNT dw	?		; If DBG_FLAG&@DBG_VCNT and VMSINT, number
				; of times to blast ourselves into VCPI GDT

	public	PCUR_VM_HANDLE, PSYS_VM_HANDLE
PCUR_VM_HANDLE df 0		; FAR PTR to Cur_VM_Handle in WIN386
PSYS_VM_HANDLE df 0		; FAR PTR to Sys_VM_Handle in WIN386

; The following two interrupt tables are organized as the
; byte length followed by the table contents

	public	VMSINT_TAB,VMSINT_LEN
VMSINT_LEN db	@VMSINT_LEN	; Length of VMS interrupt table
VMSINT_TAB label byte
%	irp	XX,<@TSSINTS>
	db	XX&h
	endm			; IRP
@VMSINT_LEN equ $-VMSINT_TAB	; Length of VMS interrupt table

	public	INSINT_TAB,INSINT_LEN
INSINT_LEN db	@INSINT_LEN	; Length of INSERT interrupt table
INSINT_TAB label byte
	db	01h,02h,03h
@INSINT_LEN equ $-INSINT_TAB	; Length of INSERT interrupt table

	align	4		; Ensure dword-aligned

	public	VMSINT_PTR
VMSINT_PTR dd	offset DGROUP:VMSINT_TAB ; Offset to interrupt table

	public	IDT_GDINT01,ORG_GDINT01_OFF
IDT_GDINT01 IDT_STR <>		; GD INT 01h IDT entry when in TSS mode
ORG_GDINT01_OFF dd -1		; Offset in DGROUP of original INT 01h IDT entry

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	@SWAT_VCP_DATA
@SWAT_VCP_DATA label byte	; Mark module start in .MAP file

DATASTART label dword

	extrn	CON4KB:dword
	extrn	CON1MB:dword

	extrn	HOSTFLAGS:word

	extrn	MSGOFF:dword
	extrn	SYNTERR:byte
	extrn	OVFERR:byte

	extrn	CMDHIGH:dword

	extrn	CMD_TOKL:byte
	extrn	CMD_TOKN:byte

	extrn	BREAKPT2:tbyte
	extrn	TSS_CNT:dword
	extrn	INSERT_EPM:tbyte
	extrn	INSERT_TSS:tbyte
	extrn	INSERT_SEL4GB:word

MLDT_STR struc

MLDT_4GB   dq	?		; 00:  All memory selector
MLDT_CR3   dq	?		; 08:  CR3 ...
MLDT_ALIAS dq	?		; 10:  Code alias ...

MLDT_STR ends

LDT_4GB equ	MLDT_4GB or (mask $TI)
LDT_CR3 equ	MLDT_CR3 or (mask $TI)

@SAVCNT equ	2		; # LDT entries (4GB and CR3) saved in SAVSTK

	public	LCLLDT
LCLLDT	MLDT_STR <>		; Local descriptor table

	public	PSEUDO_TSS
PSEUDO_TSS TSS_STR <>		; Pseudo-TSS:  note we use 386 TSS structure
				; for both 286 and 386 TSSs as it is larger
				; than the one for a 286 TSS

	public	INDVCP_GDT,OLDVCP_GDT,OLDVCP_IDT
@LENVCP_GDT equ 8		; # OLDVCP_GDT/CODESEL entries we support
INDVCP_GDT dd	0		; Index into OLDVCP_GDT
OLDVCP_GDT dd	@LENVCP_GDT dup (0) ; Previous GDT linear addresses in our CR3
OLDVCP_IDT dd	0		; ...	   IDT ...

	public	CODESEL
CODESEL dw	@LENVCP_GDT dup (-1) ; Initial code selector (-1=invalid)

	public	NEW_CR3
NEW_CR3 dd	?		; Incoming CR3 for VCPI mode switch

	public	DEBOUNCE_FVEC
DEBOUNCE_FVEC dd ?		; Address of debouncing NMI handler
	      dw ?		; Selector of ...
DEBOUNCE_ARB  db ?		; Access rights byte of ...
	align	2

	public	TSSINT_FLAG
TSSINT_FLAG dd	?		; TSSINTxx_FVEC intercept flag

	public	OLDTSSINT07_FVEC,OLDTSSINT07_ARB
OLDTSSINT07_FVEC df ?		; Save area for old INT 07h handler
OLDTSSINT07_ARB db ?		; Save area for old INT 07h A/R byte
	db	?		; For alignment

; Local TSSs

	DDALIGN DATASTART	; Align on dword boundary
%	irp	XX,<@TSSINTS>
	public	TSS&XX
TSS&XX	TSS_STR <>		; TSS structure for INT &XX&h
	endm			; IRP

%	irp	XX,<@TSSINTS>
	public	TSSINT&XX&_FVEC
TSSINT&XX&_FVEC df -1		; TSS IDT entry for INT &XX&h
	endm			; IRP

%	irp	XX,<@TSSINTS>
	public	TSSINT&XX&_ARB
TSSINT&XX&_ARB db  CPL0_TASK or CPL3 ; ARB for INT &XX&h
	endm			; IRP

	DDALIGN DATASTART	; Align on dword boundary

	public	SAVCNT,SAVNEXT,SAVSTK
SAVCNT	dd	0		; Save counter
SAVNEXT dd	offset DGROUP:SAVSTK ; Pointer to save area for local interrupts
SAVSTK	dw	(32*@SAVCNT) dup (?) ; Save area for ...

	public	VCP_FLAG
VCP_FLAG dw	0		; VCPI flags

	public	GPMI_FVEC,GPMI_EFL,GPMI_START
GPMI_FVEC df	?		; Return Sel|Off for GPMI calls
GPMI_EFL dd	?		; ...	 EFL	 ...
GPMI_START dd	0		; Starting offset

; Record for NMI_FLAG

NMI_REC record	$NMI_SWAP:1,	\
		$NMI_ACT:1

@NMI_SWAP equ	mask $NMI_SWAP	; NMI handler swapped (DEBOUNCE in effect)
@NMI_ACT  equ	mask $NMI_ACT	; NMI handler active

	public	NMI_FLAG
NMI_FLAG db	0		; 1 = NMI handler active, 0 = not

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP,ds:PGROUP

	public	@SWAT_VCP_PROG
@SWAT_VCP_PROG: 		; Mark module start in .MAP file

	extrn	SWATTER:far
	extrn	SAVEMSG:far
	extrn	FLUSH_CACHE:near
	extrn	GETLBASE:near
	extrn	U32_DRAINPIQ:near

	extrn	SWATINI:tbyte
	extrn	DEVLOAD:byte
	extrn	NMIPORT:word
	extrn	NMIENA:byte
	extrn	NMIDIS:byte
	extrn	NMIMASK:byte

	extrn	SYMAPPND:near
	extrn	SYMSRCH:near
	extrn	SYMTRANS:near
	extrn	SYMFLUSH:near
	extrn	CALC_DSESI:near

	extrn	CMD_WHITE:near
	extrn	U32_HEX2DD:near

	extrn	LCL_INTCOM_DEVDONE:near
	extrn	LCL_INTCOM_DEVORIG:near
	extrn	SetRVM:near
	extrn	SetPMG:near
	extrn	SetPMI:near
	extrn	SetPMT:near
	extrn	PushOldInt:near
	extrn	SetSelVars:near
	extrn	MASK_STKREGS:near
	extrn	MASK_STKREG1:near

	extrn	LDISPTXTC:near

	extrn	SETUP:near
	extrn	GET_TOKN:near

%	irp	XX,<@TSSINTS>
	extrn	LCL_INT&XX:near
	endm

%	irp	XX,<@OLDINTS>
ifdif <XX>,<67>
	extrn	LCL_PMG&XX&:near
endif
	endm

	extrn	GETBASE:near
	extrn	REFRESH_DEBUG:near

	extrn	INIT_IDT:near
	extrn	REST_IDT:near
	extrn	CheckTrapCR2:near
	extrn	VxDDisableDispAGP:near
	extrn	VxDEnableDispAGP:near
;;;;;;; extrn	U32_BLINK_LED:near

	public	INT00_MSG,INT01_MSG,INT02_MSG,INT03_MSG,INT05_MSG,INT06_MSG,INT08_MSG
	public	INT0A_MSG,INT0B_MSG,INT0C_MSG,INT0D_MSG,INT0E_MSG
INT00_MSG db	'Divide Overflow',0
INT01_MSG db	0
INT02_MSG db	'NMI Interrupt',0
INT03_MSG db	0
INT05_MSG db	'Bound Interrupt',0
INT06_MSG db	'Invalid Opcode',0
INT08_MSG db	'Double Fault',0
INT0A_MSG db	'Invalid TSS Fault',0
INT0B_MSG db	'Segment Not Present Fault',0
INT0C_MSG db	'Stack Fault',0
INT0D_MSG db	'GP Fault',0
INT0E_MSG db	'Page Fault',0

	NPPROC	INIT_PLCLPMGxx -- Initialize PLCLPMGxx Entry in LCLTSS_STR
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize the PLCLPMGxx entry in LCLTSS_STR

|

%	irp	XX,<@TSSINTS>
	mov	LCLTSS&XX.PLCLPMGxx,offset DGROUP:LCLPMG&XX ; Initialize it
	endm			; IRP

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_PLCLPMGxx endp		; End INIT_PLCLPMGxx procedure
	FPPROC	LCL_RVM67 -- Local EMS Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local INT 67h handler from RM/VCPI mode.

|

	call	SetRVM		; Set RM/VCPI mode

	jmp	short LCL_INT67_COM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_RVM67 endp			; End LCL_RVM67 procedure
	FPPROC	LCL_PMG67 -- Local EMS Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local INT 67h handler from PM Interrupt Gate mode.

|

	call	SetPMG		; Set PM Interrupt Gate mode

	jmp	short LCL_INT67_COM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_PMG67 endp			; End LCL_PMG67 procedure
	FPPROC	LCL_INT67 -- Local EMS Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local EMS interrupt handler.

It is assumed that this call comes from VM86 mode.

Troll for the following calls:

DE01	=	Get Protected Mode Interface
DE0B	=	Set IMR Base Vector
DE0C	=	Enter Protected Mode
DEF0	=	Debugger Presence Detection
DEF1	=	Get Debugger Information
DEF2	=	Debugger GDT Initialization, Interrupt Gates
DEF3	=	Debugger IDT Initialization
DEF4	=	Set debugger linear address and CR3
DEF5	=	Translate physical address to linear address
DEF6	=	Symbol Table Management
DEF7	=	Set host features
DEF8	=	Pass addresses of WIN386 internal variables
DEF9	=	Fill in PTEs
DEFA	=	Transfer data
DEFB	=	Get swat information
DEFC	=	Handle tail of Get Protected Mode Interface call
DEFD	=	Debugger GDT Initialization, Task Gates
DEFE	=	Do nothing

|

	call	SetPMI		; Set PM Intrude mode

	public	LCL_INT67_COM
LCL_INT67_COM:
	sub	esp,size FORW_RET ; Make room for pseudo-return address

	pushad			; Save all EGP registers

	cmp	ah,@VCPI	; Check major function code
	je	short LCL_INT67_VCPI ; Jump if VCPI
LCL_INT67_ORIG:
	popad			; Restore

	add	esp,size FORW_RET ; Strip off pseudo-return address

	pushfd			; Save EFL
	PUSHW	ds		; Save for a moment

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	call	SetSelVars	; Set selector variables
	call	MASK_STKREG1	; Mask off the high-order word of stack
				; register if 16-bit stack
	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	jnz	short @F	; Jump if so

;;;;;;; test	[esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
	test	[esp].LCLINT_NXT.DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVORIG ; Jump if so
@@:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	OLDINT_MAC 67		; Push old interrupt vactors
;;;;;;; push	OLDINT67_FVEC.FSEL ; Save selector in low-order word
;;;;;;; push	OLDINT67_FVEC.FOFF ; ...  offset in next dword

INT67_STR struc

INT67_FOFF dd	?		; Old offset
INT67_FSEL dw	?		; ... selector
INT67_DS   dw	?		; ... DS
INT67_EFL  dd	?		; ... EFL (IF=TF=0)

INT67_STR ends

	mov	ds,[esp].INT67_DS ; Restore caller's DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with original handler

	jmp	short LCL_INT67 ; In case we're returning from a TSS


LCL_INT67_ORIG0:
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	jmp	short LCL_INT67_ORIG ; Join common code


LCL_INT67_VCPI:
	cld			; String ops forwardly

	mov	ebp,esp 	; SS:EBP ==> FORW_STR

	call	MASK_STKREGS	; Mask off the high-order word of stack
				; registers if 16-bit stack
	sldt	[ebp].FORW_LDT	; In case we're called from PM

; If SETUP hasn't been run before, do so now

	push	ds		; Save for a moment

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	call	SetSelVars	; Set selector variables

; SS:ESP ==>	DSF, FORW_STR

	call	SETUP		; Call setup code

; Note DS = DGROUP from here on

	cmp	al,@VCPI_GPMI	; Izit Get Protected Mode Interface?
	je	near ptr LCL_INT67_GPMI ; Jump if so

	cmp	al,@VCPI_SIBV	; Izit Set IMR Base Vector?
	je	near ptr LCL_INT67_SIBV ; Jump if so

	cmp	al,@VCPI_EPM	; Izit Enter Protected Mode?
	je	near ptr LCL_INT67_EPM ; Jump if so

	cmp	al,@VCPI_DPRES	; Izit Debugger Presence detection?
	je	near ptr LCL_INT67_PRES ; Jump if so

	cmp	al,@VCPI_DBGINF ; Izit Get Debugger Information?
	je	near ptr LCL_INT67_INF ; Jump if so

	cmp	al,@VCPI_DBGINI ; Izit Debugger Initialization (Task Gates)?
	je	near ptr LCL_INT67_INI ; Jump if so

	cmp	al,@VCPI_DBGIDT ; Izit Debugger IDT initialization?
	je	near ptr LCL_INT67_IDT ; Jump if so

	cmp	al,@VCPI_DBGLIN ; Izit new debugger linear address?
	je	near ptr LCL_INT67_LIN ; Jump if so

	cmp	al,@VCPI_DBGP2L ; Izit translate physical to linear?
	je	near ptr LCL_INT67_P2L ; Jump if so

	cmp	al,@VCPI_DBGSYM ; Izit Symbol Table Management?
	je	near ptr LCL_INT67_SYM ; Jump if so

	cmp	al,@VCPI_DBGHOST ; Izit Host features flags?
	je	near ptr LCL_INT67_HOST ; Jump if so

	cmp	al,@VCPI_DBGWINVARS ; Izit WIN386 internal variables?
	je	near ptr LCL_INT67_WINVARS ; Jump if so

	cmp	al,@VCPI_FILLPTE ; Izit Fill in PTEs?
	je	near ptr LCL_INT67_FILLPTE ; Jump if so

	cmp	al,@VCPI_XFERDATA ; Izit Transfer Data?
	je	near ptr LCL_INT67_XFERDATA ; Jump if so

	cmp	al,@VCPI_GETINFO ; Izit get SWAT information?
	je	near ptr LCL_INT67_GETINFO ; Jump if so

	cmp	al,@VCPI_GPMITAIL ; Izit GPMI tail cleanup?
	je	near ptr LCL_INT67_GPMITAIL ; Jump if so

	cmp	al,@VCPI_DBGINI2 ; Izit Debugger Initialization (PMG)?
	je	near ptr LCL_INT67_INI2 ; Jump if so

	jmp	LCL_INT67_ORIG0 ; Continue with original handler


COMMENT|

Handle Get Protected Mode Interface call

On entry:

AX	=	DE01
ES:DI	==>	4KB page table buffer
DS:SI	==>	client's three GDT entries for VCPI
DS	=	DGROUP
SS:EBP	==>	FORW_STR

On exit:

Continue with next handler in sequence.

|

LCL_INT67_GPMI:
	cmp	GPMICOUNT,0	; Izit the first one?
	jne	near ptr LCL_INT67_ORIG0 ; Jump if not

	inc	GPMICOUNT	; Count in another call

	mov	TSSINT_FLAG,0	; Initialize TSSINTxx_FVEC intercept flag
	mov	OLDCR3,-1	; Reset previous CR3 value for video PTE checking

	test	DBG_FLAG,@DBG_VCNT ; Are we doing it by count?
	jz	short @F	; Jump if not

	cmp	VMSCOUNT,0	; Any left?
	je	short LCL_INT67_GPMI_CONT ; Jump if not

	dec	VMSCOUNT	; Adjust counter
@@:
	and	VCP_FLAG,not @VCP_EPM ; Mark as not done for next time

; Clear OLDVCP_GDT entries

	mov	ecx,@LENVCP_GDT ; Get # entries we support
	xor	edx,edx 	; Initialize index into table
@@:
	mov	OLDVCP_GDT[edx*(type OLDVCP_GDT)],0 ; Clear the entry

	inc	edx		; Skip to next entry

	loop	@B		; Jump if more entries
LCL_INT67_GPMI_CONT:

; If we need to append our PTEs to the end of the result of this call,
; handle that now.

	test	DEVLOAD,@DEVL_VCPIPTE ; Insert our PTEs?
	jz	near ptr LCL_INT67_ORIG0 ; Jump if not

; SS:EBP ==> FORW_STR

	mov	ax,[ebp].FORW_CS ; Get return CS
	mov	GPMI_FVEC.FSEL,ax ; ...

	mov	eax,[ebp].FORW_EIP ; Get return EIP
	mov	GPMI_FVEC.FOFF,eax ; ...

	mov	eax,[ebp].FORW_EFL ; Get return EFL
	mov	GPMI_EFL,eax	; ...

	mov	GPMI_START.ELO,di ; Save for later use

	mov	[ebp].FORW_CS,seg PGROUP ; Return to here in VM
	mov	[ebp].FORW_EIP,offset RGROUP:RMDEV_GPMITAIL
	and	[ebp].FORW_EFL,not ((mask $NT) or (mask $IF)); NT=IF=0

	test	[ebp].FORW_EFL,mask $R2 ; Izit from RM?
	jnz	short @F	; Jump if so

	mov	[ebp].FORW_EIP,offset RGROUP:DEV_GPMITAIL
@@:
	jmp	LCL_INT67_ORIG0 ; Continue with original handler


COMMENT|

Handle tail of Get Protected Mode Interface call

AX	=	DEFC
ES:DI	==>	end of 4KB page table buffer
DS:SI	==>	client's three GDT entries for VCPI
DS	=	DGROUP
SS:EBP	==>	FORW_STR

On exit:

Return to caller.

|

LCL_INT67_GPMITAIL:
	dec	GPMICOUNT	; Count out another

	REGSAVE <es,gs> 	; Save for a moment

	mov	es,COMMON.FILE_4GB ; Get AGROUP data selector
	assume	es:AGROUP	; Tell the assembler about it

	mov	gs,COMMON.FILE_4GB ; Get AGROUP data selector
	assume	gs:AGROUP	; Tell the assembler about it

	mov	ax,GPMI_FVEC.FSEL ; Restore return CS
	mov	[ebp].FORW_CS,ax ; ...

	mov	eax,GPMI_FVEC.FOFF ; Restore return EIP
	mov	[ebp].FORW_EIP,eax ; ...

	mov	eax,GPMI_EFL	; Restore return EFL
	mov	[ebp].FORW_EFL,eax ; ...

; In case the VCPI host doesn't include the HMA, we include it here
; For some reason, EMM386 fills in 0410h bytes (1MB + 16KB) and the
; 4 PTEs at 1MB are not one-to-one.  Moreover, those PTEs do not
; reflect the mapping it uses when DOS is in effect.  The workaround
; here is to blast in one-to-one PTEs.	Damn the torpedoes!

	movzx	eax,[ebp].FORW_EDI.ELO ; Copy ending address
	sub	eax,GPMI_START	; Less starting value

	cmp	eax,((1024+64)*1024) shr (12-2) ; Izit at or above 1.1MB?
	jae	short INIT_VCPI_HMAOK ; Jump if so

	mov	ecx,64/4	; Get # PTEs to blast in
	mov	edi,(1024*1024) shr (12-2) ; Get offset of 1MB
	mov	eax,edi 	; Copy ending offset

	movzx	edx,[ebp].FORW_ES ; Copy PTE segment #
	shl	edx,4-0 	; Convert from paras to bytes
	add	edi,edx 	; Add to get offset in PDE
	add	edi,GPMI_START	; Plus starting value

	shl	eax,(12-2)-0	; Convert from 4KB in dwords to bytes
	or	eax,@PTE_URP	; Mark as User/Read-Write/Present
@@:
S32	stos	es:[edi].EDD	; Save as address of next PTE
	add	eax,4*1024	; Skip to next PTE

	loop	@B		; Jump if more PDIRs to fill in

	shr	eax,(12-2)-0	; Convert from bytes to 4KB in dwords
	add	eax,GPMI_START	; Plus starting value
	mov	[ebp].FORW_EDI.ELO,ax ; Save ending address
INIT_VCPI_HMAOK:

; Save this DI (as a linear address) as our new linear address

	movzx	eax,[ebp].FORW_EDI.ELO ; Copy ending address
	sub	eax,GPMI_START	; Less starting value
	shl	eax,(12-2)-0	; Convert from 4KB in dwords to bytes
	and	eax,@PTE_FRM	; Isolate the 4KB frame
	mov	ebx,VCPICODE	; Get old linear address
	and	ebx,not @PTE_FRM ; Isolate the offset within 4KB frame
	or	eax,ebx 	; Preserve our offset

	xchg	eax,VCPICODE	; Save for later use
	sub	eax,VCPICODE	; Get difference
	neg	eax		; Negate to get difference of new-old
	add	eax,VCPIDATA	; Plus old data address
	mov	VCPIDATA,eax	; Save for later use

; Setup variables for call to VCPI_FILLPTE

	movzx	edi,[ebp].FORW_EDI.ELO ; Zero-extend caller's DI
	movzx	eax,[ebp].FORW_ES ; Get caller's ES
	shl	eax,4-0 	; Convert from paras to bytes
	add	edi,eax 	; ES:EDI ==> destin

; Copy our PTEs to caller's ES:DI and update DI

	mov	ecx,-1		; Set maximum # PTEs
	call	VCPI_FILLPTE	; Fill 'er up, return with EDI=advanced

	sub	edi,eax 	; Less base to get new value

	mov	[ebp].FORW_EDI.ELO,di ; Return to caller

	REGREST <gs,es> 	; Restore
	assume	es:nothing,gs:nothing ; Tell the assembler about it

	jmp	LCL_INT67_OK	; Return to caller

	assume	ds:DGROUP	; Tell the assembler about it

COMMENT|

Save new IMR base vectors

On entry:

AX	=	DE0B
BL	=	master 8259 base
CL	=	slave ... (if any)
DS	=	DGROUP
SS:EBP	==>	FORW_STR

On exit:

Continue with next handler in sequence.

|

LCL_INT67_SIBV:
	push	gs		; Save for a moment

	mov	gs,COMMON.FILE_4GB ; Get our all memory selector
	assume	gs:PGROUP	; Tell the assembler about it (note lie)

	PUSHW	cs		; Pass selector as argument
	call	GETLBASE	; Return with EAX = selector base

	mov	SWATINI.MD_IBV0[eax],bl ; Save master IMR base
	mov	SWATINI.MD_IBV1[eax],cl ; ...	slave ...

	pop	gs		; Restore
	assume	gs:nothing	; Tell the assembler about it

	jmp	LCL_INT67_ORIG0 ; Continue with original handler


COMMENT|

Handle Enter Protected Mode switch

On entry:

AX	=	DE0C
ESI	=	EPMTAB
DS	=	DGROUP
SS:EBP	==>	FORW_STR

On exit:

Continue with next handler in sequence.

|

LCL_INT67_EPM:
	test	DBG_FLAG,@DBG_VMS ; Trap V86 Mode Switches?
	jz	near ptr LCL_INT67_ORIG0 ; Not this time

; Capture the caller's CR3 and insert into our LCLTSSxx structures

	push	es		; Save for a moment

	mov	es,COMMON.FILE_4GB ; Get our all memory selector
	assume	es:AGROUP	; Tell the assembler about it

	mov	eax,AGROUP:[esi].VCPEPM_CR3 ; Get caller's CR3
	call	SET_TSSCR3	; Set new CR3 in the local TSSs to EAX

	pop	es		; Restore
	assume	es:nothing	; Tell the assembler about it

	call	CHECK_EPM	; See if the GDT/IDT are the same as before

	test	VCP_FLAG,@VCP_EPM ; Already done?
	jnz	short @F	; Yes, skip all this

	call	TRAP_EPM	; Insinuate ourselves into the new GDT/IDT
	jc	near ptr LCL_INT67_ORIG0 ; Jump if not enough GDT entries

	or	VCP_FLAG,@VCP_EPM ; Mark as done for next time
@@:
	mov	eax,INDVCP_GDT	; Get the current index
	movzx	edi,CODESEL[eax*(type CODESEL)] ; Get our code selector
	add	edi,OLDVCP_GDT[eax*(type OLDVCP_GDT)] ; Plus base of GDT
				; AGROUP:EDI ==> available GDT entries
	call	INST_GDT	; Install our GDT entries into AGROUP:EDI

; Ensure that the caller's CR3 and LDTR are set in its TSS

	call	SETTSS_VARS	; Set 'em up using ESI ==> VCPEPM_STR
				; and OLDVCP_GDT
	jmp	LCL_INT67_ORIG0 ; Continue with original handler


COMMENT|

Indicate resident debugger present
Return debugger specification #

On entry:

AX	=	DEF0
DS	=	DGROUP
SS:EBP	==>	FORW_STR

On exit:

AH	=	0
BH	=	Major specification version #
BL	=	Minor ...

|

LCL_INT67_PRES:
	mov	bx,VERS_T-'0'   ; Get tens digit
	imul	bx,10		; Times 10
	add	bl,VERS_U-'0'   ; Plus units digit
	mov	bh,VERS_H-'0'   ; Get major version # for debugger
	mov	[ebp].FORW_EBX.ELO,bx ; Return in caller's BX

; Clear all CODESELs

	mov	ecx,@LENVCP_GDT ; Get # entries we support
	xor	edx,edx 	; Initialize index into table
@@:
	mov	CODESEL[edx*(type CODESEL)],-1 ; Mark as invalid for next time
	inc	edx		; Skip to next index

	loop	@B		; Jump if more entries

	jmp	LCL_INT67_OK	; Return to caller


COMMENT|

Get debugger information structure physical address into EDX

On entry:

AX	=	DEF1
DS	=	DGROUP
SS:EBP	==>	FORW_STR

On exit:

AH	=	0
EDX	=	Physical address of debugger information structure

|

LCL_INT67_INF:

; Fill in SWATINFO

; Get physical address of SWAT's code segment

	PUSHD	cs		; Selector we're interested in
	call	SEL2BASE	; Return with EAX == selector base address

	call	LIN2PHYS	; EAX = physical address of SWAT's code segment

	mov	SWATINFO.SWTINF_BASE,eax ; Save in structure

; Fill in pointer to LCL_INT67 to make VCPI calls from VxDs

	mov	SWATINFO.SWTINF_INT67,offset PGROUP:LCL_INT67 ; Save offset of local int 67 handler

; Get physical address of SWATINFO structure

	PUSHD	ds		; Selector we're interested in
	call	SEL2BASE	; Return with EAX == selector base address

	lea	eax,SWATINFO[eax] ; Linear address of SWATINFO structure
	call	LIN2PHYS	; EAX = physical address of SWATINFO structure
	mov	[ebp].FORW_EDX,eax ; Return physical address in EDX

	jmp	LCL_INT67_OK	; Return to caller


COMMENT|

Initialize debugger GDT entries at ES:DI for Task Gates

On entry:

AX	=	DEF2
BX	=	initial selector
ES:DI	==>	space for initial GDT entry
DS	=	DGROUP
SS:EBP	==>	FORW_STR

On exit:

AH	=	0
BX:EDX	==>	Protected mode entry point

|

LCL_INT67_INI:
	call	FIND_OLDVCP_GDT ; Find the next free entry in OLDVCP_GDT
				; Return index in EDX
;;;;;;; jc	short ???	; Ignore error return

; Save caller's initial selector

	mov	bx,[ebp].FORW_EBX.ELO ; Get the value
	lea	ax,[bx].VCP_CODE ; Skip to code selector
	mov	CODESEL[edx*(type CODESEL)],ax ; Save for later use

; Because we're using TSSs, we need to handle software INT 01hs
; specially.  In particular, for a software INT 01h the GD bit
; is not cleared.  This means that when we reference a DRn register
; inside our INT 01h handler, if we didn't do anything special,
; we would re-enter the INT 01h TSS (GP Fault).  Our solution is
; to install and uninstall an INT 01h interrupt gate around the
; call to SWATTER.

	mov	IDT_GDINT01.IDT_SELECT,ax ; Save for later use

	call	SET_TSSINT	; Save CODESEL into TSSINTxx_FVEC variables

	push	gs		; Save for a moment

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

; Convert caller's ES:DI to AGROUP:EDI
; If ES = 0, use caller's EDI

	movzx	edi,[ebp].FORW_ES ; Get caller's ES
	mov	eax,[ebp].FORW_EDI ; Get caller's EDI

	shl	edi,4-0 	; Convert from paras to bytes
	jz	short @F	; Jump if ES = 0

	movzx	eax,ax		; Convert caller's EDI to DI
@@:
	add	edi,eax 	; Add to get 32-bit linear address
	mov	OLDVCP_GDT[edx*(type OLDVCP_GDT)],edi ; Save for next time

	call	INST_GDT	; Install our GDT entries into AGROUP:EDI
				; and following

	mov	ax,CODESEL[edx*(type CODESEL)] ; Get our code selector
	mov	[ebp].FORW_EBX.ELO,ax ; Return as BX
	mov	[ebp].FORW_EDX,offset cs:PMDBG ; Return offset in EDX

	or	VCP_FLAG,@VCP_EPM ; Mark as done for next time
	and	VCP_FLAG,not @VCP_PMG ; Mark as doing Task Gates

	pop	gs		; Restore
	assume	gs:nothing	; Tell the assembler about it

	jmp	LCL_INT67_OK	; Return to caller


COMMENT|

Initialize debugger IDT entry BX at ES:DI

On entry:

AX	=	DEF3
BX	=	interrupt #
ES:DI	==>	IDT entry for interrupt BX
DS	=	DGROUP
SS:EBP	==>	FORW_STR

|

LCL_INT67_IDT:
	movzx	ebx,bx		; Zero to use as dword

	and	bh,bh		; Ensure not too large
	jnz	short LCL_INT67_IDTERR ; Jump if so

	mov	ecx,NLCLTSS	; Get # LCLTSSxx structures
	lea	edi,LCLTSS00	; DS:EDI ==> LCLTSSxx structure for INT 00h
;;;;;;; lea	esi,LCLPMG00	; DS:ESI ==> LCLPMGxx ...
@@:
	cmp	bl,DGROUP:[edi].INTNOxx ; Check the interrupt #
	je	short LCL_INT67_IDTCOM ; Jump if it's a match

	add	edi,size LCLTSS_STR ; Skip to next LCLTSSxx structure
;;;;;;; add	esi,size LCLPMG_STR ; ...	   LCLPMGxx ...

	loop	@B		; Jump if more LCLTSSxx structures
LCL_INT67_IDTERR:
	test	VCP_FLAG,@VCP_PMG ; Installing Interrupt Gates?
	jz	short @F	; Jump if not

	cmp	ebx,09h 	; Check special cases
	lea	esi,LCLPMG09	; DS:ESI ==> LCLPMGxx structure for INT 09h
	je	short LCL_INT67_IDTCOM1 ; Jump if it's a match
@@:
	mov	ah,83h		; Mark as unsupported

	jmp	LCL_INT67_ERR	; Join common error exit code


COMMENT|

On entry:

EBX	=	interrupt #
DS:EDI	==>	LCLTSSxx structure for this interrupt
;;;DS:ESI  ==>	   LCLPMGxx ...
DS	=	DGROUP
SS:EBP	==>	FORW_STR

|

LCL_INT67_IDTCOM:
	mov	esi,DGROUP:[edi].PLCLPMGxx ; DS:ESI ==> LCLPMGxx
LCL_INT67_IDTCOM1:
	REGSAVE <es,gs> 	; Save registers

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

	push	ds		; Setup ES for data references
	pop	es		; Address it
	assume	es:DGROUP	; Tell the assembler about it

; Check the VMS interrupt table

	xor	edx,edx 	; Zero to use as dword

	push	edi		; Save for a moment

	mov	al,bl		; Get the interrupt #
	mov	edi,VMSINT_PTR	; ES:EDI ==> VMS interrupt table
	movzx	ecx,DGROUP:[edi-1].LO ; ECX = length of ...
  repne scas	VMSINT_TAB[edi] ; Search for it

	pop	edi		; Restore

	sete	dl		; Mark as 1 if found (and thus to be installed)
				; ...0 if not

; Convert caller's ES:DI to AGROUP:EBX
; If ES = 0, use caller's EDI

	push	ebx		; Save the interrupt #

	movzx	ebx,[ebp].FORW_ES ; Get caller's ES
	mov	eax,[ebp].FORW_EDI ; Get caller's EDI

	shl	ebx,4-0 	; Convert from paras to bytes
	jz	short @F	; Jump if ES = 0

	movzx	eax,ax		; Convert caller's EDI to DI
@@:
	add	ebx,eax 	; Add to get 32-bit linear address

	pop	eax		; Restore interrupt # to EAX

	mov	ecx,ebx 	; Copy linear address of this interrupt #
	imul	eax,type IDT_STR ; Times size of a PM interrupt
	sub	ecx,eax 	; Subtract to get start of IDT
	mov	OLDVCP_IDT,ecx	; Save for next time

; See if we're already installed

	mov	ecx,INDVCP_GDT	; Get current index
	mov	cx,CODESEL[ecx*(type CODESEL)] ; Get our VCPI code selector

	test	VCP_FLAG,@VCP_PMG ; Installing Interrupt Gates?
	jnz	short @F	; Jump if so

	add	cx,DGROUP:[edi].DDTE_TSSxx ; Plus our TSS selector
@@:
	cmp	cx,AGROUP:[ebx].IDT_SELECT ; Same selector?
	je	short @F	; Yes, ignore this call

; Save old entry, install new TSS entry

; AGROUP:EBX ==> caller's IDT entry for this interrupt
; DS:EDI ==>	LCLTSSxx for this interrupt
; DS:ESI ==>	LCLPMGxx ...
; EDX	=	1 if we're to install this interrupt
;	=	0 if not (out of range, not in VMSINT_TAB, etc.)

	push	edx		; Pass do/don't install flag (0 = don't)
	call	SETTSS		; Setup the TSS
@@:
	REGREST <gs,es> 	; Restore
	assume	es:nothing,gs:nothing ; Tell the assembler about it

	jmp	LCL_INT67_OK	; Join common code


COMMENT|

Set new debugger linear address

On entry:

AX	=	DEF4
EBX	=	new CR3 (-1 = use current value)
EDX	=	new linear address (-1 = none)
DS	=	DGROUP
SS:EBP	==>	FORW_STR

On exit:

AH	=	0

|

LCL_INT67_LIN:
	push	gs		; Save for a moment

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

	PUSHW	ds		; Pass selector as argument
	call	GETLBASE	; Return with EAX = selector base
	mov	esi,eax 	; Copy for later use

; Set new CR3 in the TSSs

	mov	eax,[ebp].FORW_EBX ; Get caller's EBX (new CR3)

	cmp	eax,-1		; Izit valid?
	jne	short @F	; Jump if not

	mov	eax,cr3 	; Use the current value
@@:
	call	SET_TSSCR3	; Set new CR3 in the local TSSs to EAX

; Re-install our CR3 selector

	mov	ebx,cr0 	; Get register with Paging bit

	test	ebx,mask $PG	; Izit enabled?
	jz	short @F	; Jump if not

	PUSHD	0		; Pass flag in case not found (no hope)
	and	eax,@PTE_FRM	; Isolate the 4KB frame
	push	eax		; Pass physical address to translate
	push	eax		; Pass physical address of CR3 to use
	call	PHYS2LIN	; Translate physical to linear via a CR3
@@:
	lea	esi,LCLLDT[esi].MLDT_CR3 ; GS:ESI ==> CR3 selector entry in LDT
	mov	ecx,4*1024-1	; 4KB length
;;;;;;; sub	ecx,eax 	; Less base address
	call	SET_GDT 	; Set GDT entry GS:ESI to EAX limit ECX

	mov	AGROUP:[esi].DESC_ACCESS,CPL0_DATA ; Set ARB

; Set new linear address

	mov	eax,[ebp].FORW_EDX ; Get caller's EDX (new linear address)

	cmp	eax,-1		; Same as old?
	je	short @F	; Jump if so

	and	eax,@PTE_FRM	; Isolate the 4KB frame
	mov	ebx,VCPICODE	; Get old linear address
	and	ebx,not @PTE_FRM ; Isolate the offset within 4KB frame
	or	eax,ebx 	; Preserve our offset

	xchg	eax,VCPICODE	; Save for later use
	sub	eax,VCPICODE	; Get difference
	neg	eax		; Negate to get difference of new-old
	add	eax,VCPIDATA	; Plus old data address
	mov	VCPIDATA,eax	; Save for later use
@@:
	mov	eax,VCPICODE	; Get new linear address
	mov	[ebp].FORW_EDX,eax ; Return to caller

	pop	gs		; Restore
	assume	gs:nothing	; Tell the assembler about it

	jmp	LCL_INT67_OK	; Join common code


COMMENT|

Translate physical address to linear address

On entry:

AX	=	DEF5
EDX	=	physical address
DS	=	DGROUP
SS:EBP	==>	FORW_STR

On exit:

AH	=	0
EDX	=	linear address

|

LCL_INT67_P2L:
	push	gs		; Save for a moment

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

	mov	eax,cr3 	; Get our CR3

	PUSHD	0		; Pass flag in case not found (no hope)
	push	[ebp].FORW_EDX	; Pass physical address to translate
	push	eax		; Pass physical address of CR3 to use
	call	PHYS2LIN	; Translate physical to linear via a CR3

	mov	[ebp].FORW_EDX,eax ; Save in caller's EDX

	pop	gs		; Restore
	assume	gs:nothing	; Tell the assembler about it

	jmp	LCL_INT67_OK	; Join common code


COMMENT|

Symbol Table Management functions

On entry:

AX	=	DEF6
BL	=	subfunction
DS	=	DGROUP
SS:EBP	==>	FORW_STR

On exit:

AH	=	00 if successful
	=	8F if invalid subfunction

|

LCL_INT67_SYM:
	push	gs		; Save for a moment

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

; Note that the above stack addressability to DS and GS is
; relied upon in the following functions.  If the above changes,
; be sure to reflect that change in the SYMxxxx subfunctions.

; Split cases depending upon subfunction

	cmp	bl,@DBGSYM_APPND ; Izit append?
	je	short LCL_INT67_SYMAPPND ; Jump if so

	cmp	bl,@DBGSYM_SRCH  ; Izit search?
	je	short LCL_INT67_SYMSRCH ; Jump if so

	cmp	bl,@DBGSYM_TRANS ; Izit translate?
	je	short LCL_INT67_SYMTRANS ; Jump if so

	cmp	bl,@DBGSYM_FLUSH ; Izit flush?
	je	short LCL_INT67_SYMFLUSH ; Jump if so

	cmp	bl,@DBGSYM_RAPPND ; Izit raw append?
	je	short LCL_INT67_SYMRAPPND ; Jump if so

	cmp	bl,@DBGSYM_COMMAND ; Izit execute command?
	je	short LCL_INT67_COMMAND ; Jump if so

	cmp	bl,@DBGSYM_LDISP ; Izit display ASCIIZ to log?
	je	near ptr LCL_INT67_LDISP ; Jump if so

	cmp	bl,@DBGSYM_REFRESH ; Izit refresh debug hooks?
	je	near ptr LCL_INT67_REFRESH ; Jump if so

	cmp	bl,@DBGSYM_BREAK ; Izit set a temporary breakpoint?
	je	near ptr LCL_INT67_BREAK ; Jump if so

	mov	ah,8Fh		; Mark as invalid subfunction
LCL_INT67_SYMERR:
	pop	gs		; Restore
	assume	gs:nothing	; Tell the assembler about it

	jmp	LCL_INT67_ERR	; Join common error exit code


	assume	gs:AGROUP	; Tell the assembler about it

LCL_INT67_SYMAPPND:
	mov	SYMAPPND_MODE,0 ; Normal symbol append
	jmp	short LCL_INT67_SYMAPPND_COM ; Join common code

LCL_INT67_SYMRAPPND:
	mov	SYMAPPND_MODE,1 ; Raw symbol append - allow duplicates
;;;;;;;  jmp	 short LCL_INT67_SYMAPPND_COM ; Join common code

LCL_INT67_SYMAPPND_COM:
	call	SYMAPPND	; Append 'em
	jc	short LCL_INT67_SYMERR ; Jump if something went wrong

	jmp	LCL_INT67_SYMOK ; Join common code

LCL_INT67_SYMSRCH:
	call	SYMSRCH 	; Search for 'em
	jc	short LCL_INT67_SYMERR ; Jump if something went wrong

	jmp	LCL_INT67_SYMOK ; Join common code

LCL_INT67_SYMTRANS:
	call	SYMTRANS	; Translate 'em
	jc	short LCL_INT67_SYMERR ; Jump if something went wrong

	jmp	LCL_INT67_SYMOK ; Join common code

LCL_INT67_SYMFLUSH:
	call	SYMFLUSH	; Flush 'em
	jc	short LCL_INT67_SYMERR ; Jump if something went wrong

	jmp	LCL_INT67_SYMOK ; Join common code

LCL_INT67_COMMAND:
	REGSAVE <es>		; Save

	push	ds		; Get DGROUP segment
	pop	es		; Address for STOSB
	assume	es:DGROUP	; Tell the assembler

	call	CALC_DSESI	; Return with EAX = linear address of DS:ESI
	mov	esi,eax 	; Address in AGROUP

	lea	edi,CMD_LINE	; Address start of command line
	sub	ecx,ecx 	; Initialize character count
@@:
	lods	AGROUP:[esi].LO ; Get next character
S32	stos	CMD_LINE[edi]	; Save in command line
	or	al,al		; Izit the end of the line?
	jz	short @F	; Jump if so

	inc	ecx		; Count it in
	cmp	ecx,CMD_LINE_LEN ; Have we exceeded the maximum line length?
	jb	short @B	; Go around again if not

	dec	ecx		; Back off to last character
@@:
	mov	CMDHIGH,ecx	; Save new high water mark

@I67_CMD equ	@LC3_COMMAND or @LC3_INTERNAL or @LC3_NOVID

	mov	eax,LC3_FLAG	; Get flags
	and	eax,@I67_CMD	; Isolate bits to preserve
	push	eax		; Save

	or	LC3_FLAG,@I67_CMD ; Tell SWATTER to call CMD_CHAR then exit

; Simulate call to SWATTER from an interrupt handler at PL0

	pushfd			; EFLAGS
	PUSHD	cs		; Return CS with filler
; Note we can't use lea eax,PGROUP:@F because MASM 5.10b
; doesn't assemble it correctly (word fixup instead of dword)
	mov	eax,offset PGROUP:@F ; Return EIP
	push	eax		; Put it on stack
	FCALLD	SWATTER 	; Call our debugger with IRETD frame on stack
	add	esp,3*4 	; Strip bogus IRETD frame
@@:
	pop	eax		; Restore
	and	LC3_FLAG,not @I67_CMD ; Turn off bits we turned on
	or	LC3_FLAG,eax	; Restore previous value

	REGREST <es>		; Restore
	assume	es:nothing	; Tell the assembler

	jmp	short LCL_INT67_SYMOK ; Join common code


LCL_INT67_LDISP:
	call	CALC_DSESI	; Return with EAX = linear address of DS:ESI
	mov	esi,eax 	; Address in AGROUP

@@:
	lods	AGROUP:[esi].LO ; Get next character
	or	al,al		; Izit the end?
	jz	short @F	; Jump if so

	call	LDISPTXTC	; Dump char AL to error log

	jmp	short @B	; Go around again


@@:
	jmp	short LCL_INT67_SYMOK ; Join common code


LCL_INT67_REFRESH:
	call	REFRESH_DEBUG	; Refresh the debug hooks

	jmp	short LCL_INT67_SYMOK ; Join common code


COMMENT|

Set a temporary breakpoint at SI:EDX, mode CX

|

LCL_INT67_BREAK:
	mov	ah,0B0h 	; Pick arbitrary error code

	test	BREAKPT2.BC_FLAG,@ADDR_INUSE ; Izit in use?
	jnz	near ptr LCL_INT67_SYMERR ; Jump if so

	movzx	eax,[ebp].FORW_ESI.ELO ; Get the segment/selector
	shl	eax,4-0 	; Convert from paras to bytes

	test	[ebp].FORW_ECX.ELO,@ADDR_PM ; Izit in PM?
	jz	short @F	; Jump if not

	push	[ebp].FORW_ESI.ELO ; Pass the selector
	call	GETBASE 	; Return with EAX = selector base
@@:
	mov	edx,[ebp].FORW_EDX ; Get the offset
	add	edx,eax 	; Add to get linear address

	mov	al,@OPCOD_INT3	; Breakpoint interrupt
	xchg	al,AGROUP:[edx] ; Swap with the data

; In case we're dealing with a cached ROM on a 486, invalidate
; the cache before comparing the values.

	test	LC2_FLAG,@LC2_486 ; Izit a 486 or later?
	jz	short @F	; Jump if not

	WBINVD			; Write back and invalidate the cache
@@:
	mov	ah,0B1h 	; Pick arbitrary error code

	cmp	AGROUP:[edx].LO,@OPCOD_INT3 ; Did it take?
	jne	near ptr LCL_INT67_SYMERR ; Jump if not

	mov	BREAKPT2.BC_LIN,edx ; Save the offset
	mov	BREAKPT2.BC_VAL,al  ; Save to restore the next time
	or	BREAKPT2.BC_FLAG,@ADDR_INUSE or @ADDR_ENA ; Mark as enabled and in use

;;;;;;; jmp	short LCL_INT67_SYMOK ; Join common code

LCL_INT67_SYMOK:
	pop	gs		; Restore
	assume	gs:nothing	; Tell the assembler about it

	jmp	LCL_INT67_OK	; Join common exit code


COMMENT|

Handle Set host features call

Since this call can only be made at SWAT's INIT_VIRT, we initialize
the serial port parameters here.  We can't do it in INIT_PROT, since
MAX will blow away the IMR after we return.

Note that we won't enable the IMR until we've set everything else
up, so there will be no chaining via INTxx_ORIG.

We'll also take this opportunity to set SIRB flags for interrupts
we need to hook upstairs if Virtual Mode Extensions are present and
enabled.

We'll also enable debugging extensions if they're supported.

On entry:

AX	=	DEF7
BX	=	Host feature flags
DS	=	DGROUP
SS:EBP	==>	FORW_STR

On exit:

Nothing defined.

|

LCL_INT67_HOST:
	cmp	bx,-1		; Should we ignore this value?
	je	short @F	; Jump if so

	mov	HOSTFLAGS,bx	; Save host features
@@:

@I67_SER equ	@LC3_SERINIT or @LC3_INTERNAL or @LC3_NOVID

	mov	eax,LCL_FLAG	; Get flags
	and	eax,@LCL_SCRN	; Isolate bits we want to save
	push	eax		; Save

	mov	eax,LC3_FLAG	; Get flags
	and	eax,@I67_SER	; Isolate bits to save
	push	eax		; Save

	or	LCL_FLAG,@LCL_SCRN ; Don't save and restore screen
	or	LC3_FLAG,@I67_SER ; Tell SWATTER to call SER_INIT then exit

; Simulate call to SWATTER from an interrupt handler at PL0

	pushfd			; EFLAGS
	PUSHD	cs		; Return CS with filler
; Note we can't use lea eax,PGROUP:@F because MASM 5.10b
; doesn't assemble it correctly (word fixup instead of dword)
	mov	eax,offset PGROUP:@F ; Return EIP
	push	eax		; Put on stack
	FCALLD	SWATTER 	; Call our debugger with IRETD frame on stack
	add	esp,3*4 	; Strip bogus IRETD frame
@@:
	pop	eax		; Get flag bits to restore
	and	LC3_FLAG,not @I67_SER ; Turn 'em off
	or	LC3_FLAG,eax	; Restore previous values

	pop	eax		; Get flag bits to restore
	and	LCL_FLAG,not @LCL_SCRN ; Turn bit off
	or	LCL_FLAG,eax	; Restore previous value

; If VME is present and enabled, set the SIRB bits for software
; interrupts we need to hook:  01h, 02h, 03h, 68h.
; Occasionally, we code software interrupts (CD xx) for 1, 2, 3.
; INT 68h is used for Windows kernel debugging.

	test	CPUFET_FLAG,mask $CPUFET_VME ; Is VME supported?
	jz	short LCL_INT67_HOST2 ; Jump if not

	MOVSPR	eax,cr4 	; Get CPU extensions register

	test	eax,mask $VME	; Izit enabled?
	jz	short LCL_INT67_HOST2 ; Jump if not

	push	gs		; Save for a moment

	mov	gs,COMMON.FILE_4GB ; Get AGROUP data selector
	assume	gs:AGROUP	; Tell the assembler about it

	str	ax		; Get the current TR
	push	ax		; Pass selector
	call	GETBASE 	; Return with EAX = selector base

	movzx	edi,AGROUP:[eax].TSS_IOMAP ; Get I/O map offset

	and	edi,edi 	; Izit valid?
	jz	short LCL_INT67_HOST1 ; Not this time

	sub	edi,256/8	; Less offset to SIRB
	jbe	short LCL_INT67_HOST1 ; Nothing remains

SIRB_MAC macro	NN		; Set bit in SIRB table at AGROUP:EDI

	or	AGROUP:[eax+edi+0&NN&h/8].LO,1 shl (0&NN&h mod 8)

	endm			; SIRB_MAC

	SIRB_MAC 01		; Mark as being trapped
	SIRB_MAC 02		; ...
	SIRB_MAC 03		; ...
	SIRB_MAC 68		; ...
LCL_INT67_HOST1:
	pop	gs		; Restore
	assume	gs:nothing	; Tell the assembler about it
LCL_INT67_HOST2:

; Enable debugging extensions if supported

	test	CPUFET_FLAG,mask $CPUFET_IOBRK ; Are Debugging Extensions supported?
	jz	short LCL_INT67_HOST3 ; Jump if not

	MOVSPR	eax,cr4 	; Get CPU extensions register
	or	eax,mask $DE	; DE=1
	MOVSPR	cr4,eax 	; Tell the CPU about it
LCL_INT67_HOST3:
	jmp	LCL_INT67_DONE	; Join common exit code


COMMENT|

Handle WIN386 internal variable addresses call

On entry:

AX	=	DEF8
BL	=	Internal variable subfunction
CX	=	Selector of variable
EDX	=	Offset of variable
DS	=	DGROUP
SS:EBP	==>	FORW_STR

On exit:

Nothing defined.

|

LCL_INT67_WINVARS:
	cmp	bl,@DBGWINVARS_CURVM	; Izit Cur_VM_Handle?
	jne	short @F	; Not this time

	mov	PCUR_VM_HANDLE.FOFF,edx ; Remember the offset
	mov	PCUR_VM_HANDLE.FSEL,cx ; Remember the selector

	jmp	short LCL_INT67_WINVARS_EXIT ; Rejoin common exit code

@@:
	cmp	bl,@DBGWINVARS_SYSVM	; Izit Sys_VM_Handle?
	jne	short @F	; Not this time

	mov	PSYS_VM_HANDLE.FOFF,edx ; Remember the offset
	mov	PSYS_VM_HANDLE.FSEL,cx ; Remember the selector

;;;;;;; jmp	short LCL_INT67_WINVARS_EXIT ; Rejoin common exit code

@@:
LCL_INT67_WINVARS_EXIT:
	jmp	LCL_INT67_DONE	; Join common exit code


COMMENT|

Fill in at most ECX PTEs

On entry:

AX	=	DEF9
ECX	=	maximum # PTEs to fill in (in units of dwords)
ES:eDI	==>	place to save PTEs
DS	=	DGROUP
SS:EBP	==>	FORW_STR

On exit:

AH	=	0 if ECX on input large enough
	=	8B otherwise
ECX	=	# PTEs not filled in

|

LCL_INT67_FILLPTE:
	REGSAVE <es,gs> 	; Save for a moment

	mov	es,COMMON.FILE_4GB ; Get AGROUP data selector
	assume	es:AGROUP	; Tell the assembler about it

	mov	gs,COMMON.FILE_4GB ; Get AGROUP data selector
	assume	gs:AGROUP	; Tell the assembler about it

; Convert caller's ES:DI to AGROUP:EDI
; If ES = 0, use caller's EDI

	movzx	edi,[ebp].FORW_ES ; Get caller's ES
	mov	eax,[ebp].FORW_EDI ; Get caller's EDI

	shl	edi,4-0 	; Convert from paras to bytes
	jz	short @F	; Jump if ES = 0

	movzx	eax,ax		; Convert caller's EDI to DI
@@:
	add	edi,eax 	; Add to get 32-bit linear address

	mov	[ebp].FORW_EAX.ELO.HI,0 ; Assume no error
	xor	ecx,ecx 	; ...
	xchg	ecx,[ebp].FORW_ECX ; Swap with maximum # PTEs

	call	VCPI_FILLPTE	; Fill 'er up, return with EDI=advanced

	REGREST <gs,es> 	; Restore
	assume	es:nothing,gs:nothing ; Tell the assembler about it

	jmp	LCL_INT67_DONE	; Join common exit code


COMMENT|

Transfer data

On entry:

AX	=	DEFA
BL	=	@XFER_xxx type
ECX	=	amount of data to transfer
DS:DX	==>	source data
DS	=	DGROUP
SS:EBP	==>	FORW_STR

On exit:

AH	=	0 if all went well
	=	8F if invalid subfunction in BL

|

LCL_INT67_XFERDATA:
	REGSAVE <es>		; Save for a moment

	mov	RGRSEG2,seg PGROUP ; As per COPYLOW

	mov	es,COMMON.FILE_4GB ; Get AGROUP data selector
	assume	es:AGROUP	; Tell the assembler about it

	mov	ecx,[ebp].FORW_ECX ; Get caller's ECX

; Convert caller's DS:DX to AGROUP:ESI

	movzx	esi,[ebp].FORW_DS ; Get caller's DS
	movzx	eax,[ebp].FORW_EDX.ELO ; Get caller's DX
	shl	esi,4-0 	; Convert from paras to bytes
	add	esi,eax 	; Add to get 32-bit linear address

	mov	[ebp].FORW_EAX.ELO.HI,8Fh ; Assume invalid subfunction

; Check for WINTAB

	cmp	[ebp].FORW_EBX.ELO.LO,@XFER_WINTAB ; Izit WINTAB data?
	jne	short LCL_INT67_XFERDATA_EXIT ; Jump if not

	mov	edi,WINBASE	; Assume it's WINTAB
	add	edi,SWATDATA	; Plus linear address of DGROUP

	or	LCL_FLAG,@LCL_WINTAB ; Mark as now present

;;;;;;; jmp	short LCL_INT67_XFERDATA_MOVE ; Join common move code

LCL_INT67_XFERDATA_MOVE:
S32 rep movs	<AGROUP:[edi].LO,AGROUP:[esi].LO> ; Copy the data

	mov	[ebp].FORW_EAX.ELO.HI,0 ; Mark as all went OK
LCL_INT67_XFERDATA_EXIT:
	REGREST <es>		; Restore
	assume	es:nothing	; Tell the assembler about it

	jmp	LCL_INT67_DONE	; Join common exit code


COMMENT|

Return SWAT information

On entry:

AX	=	DEFB
BL	=	function code
DS	=	DGROUP
SS:EBP	==>	FORW_STR

On exit:

If BL = @GETINFO_SELS, and we're not VM SWAT, return

AH	=	0
CX	=	SWAT's all memory selector
DX	=	SWAT's CR3 selector

Otherwise,

AH	=	8F if invalid subfunction in BL

|

LCL_INT67_GETINFO:
	cmp	bl,@GETINFO_SELS ; Izit get selectors?
	jne	short @F	; Not this time

	test	[ebp].FORW_EFL,mask $R2 ; Izit from device driver?
	jnz	near ptr LCL_INT67_ERR ; Jump if so (AH has @VCPI)

	mov	ax,COMMON.FILE_4GB ; Get our all memory selector
	mov	[ebp].FORW_ECX.ELO,ax ; Return in caller's CX

	mov	ax,COMMON.FILE_CR3 ; Get our CR3 selector
	mov	[ebp].FORW_EDX.ELO,ax ; Return in caller's DX

	jmp	LCL_INT67_OK	; Join common exit code


@@:
	mov	ah,8Fh		; Mark as invalid subfunction

	jmp	LCL_INT67_ERR	; Join common exit code


COMMENT|

Initialize debugger GDT entries at ES:DI for Interrupt Gates

On entry:

AX	=	DEFD
BX	=	initial selector
ES:DI	==>	space for initial GDT entry
DS	=	DGROUP
SS:EBP	==>	FORW_STR

On exit:

AH	=	0
BX:EDX	==>	Protected mode entry point

|

LCL_INT67_INI2:
	call	FIND_OLDVCP_GDT ; Find the next free entry in OLDVCP_GDT
				; Return index in EDX
;;;;;;; jc	short ???	; Ignore error return

; Save caller's initial selector

	movzx	ebx,[ebp].FORW_EBX.ELO ; Get the value
	mov	CODESEL[edx*(type CODESEL)],bx ; Save for later use

; Save this code selector in the LCL and OLD PMG variables

%	irp	XX,<@OLDINTS>
	mov	LCLPMG&XX&_FVEC.FSEL,bx ; Save selector
	mov	OLDPMG&XX&_FVEC.FSEL,bx ; ...
	endm			; IRP

	push	gs		; Save for a moment

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

; Convert caller's ES:DI to AGROUP:EDI
; If ES = 0, use caller's EDI

	movzx	edi,[ebp].FORW_ES ; Get caller's ES
	mov	eax,[ebp].FORW_EDI ; Get caller's EDI

	shl	edi,4-0 	; Convert from paras to bytes
	jz	short @F	; Jump if ES = 0

	movzx	eax,ax		; Convert caller's EDI to DI
@@:
	add	edi,eax 	; Add to get 32-bit linear address
	mov	OLDVCP_GDT[edx*(type OLDVCP_GDT)],edi ; Save for next time

	call	INST_PMG	; Install our selectors into the GDT
				; AGROUP:EDI ==> GDT
; Return values to caller

	mov	ax,CODESEL[edx*(type CODESEL)] ; Get our code selector
	mov	[ebp].FORW_EBX.ELO,ax ; Return as BX
	mov	[ebp].FORW_EDX,offset cs:PMDBG ; Return offset in EDX

	or	VCP_FLAG,@VCP_EPM ; Mark as done for next time
	or	VCP_FLAG,@VCP_PMG ; Mark as doing Interrupt Gates

	pop	gs		; Restore
	assume	gs:nothing	; Tell the assembler about it

	jmp	LCL_INT67_OK	; Return to caller


LCL_INT67_OK:
	mov	ah,00h		; Return successful code
LCL_INT67_ERR:
	mov	[ebp].FORW_EAX.ELO.HI,ah ; Save error code
LCL_INT67_DONE:
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popad			; Restore all EGP registers

	add	esp,size FORW_RET ; Strip off pseudo-return address

; If we're running under Windows, skip the device driver test
; as we can return to the caller only.

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	jnz	short @F	; Jump if so

	test	[esp].DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVDONE ; Jump if so
@@:
	iretd			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT67 endp			; End LCL_INT67 procedure
	NPPROC	INST_PMG -- Install PMG Selectors Into GDT
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Install PMG selectors into GDT

On entry:

AGROUP:EDI ==>	GDT

|

	REGSAVE <eax,ecx,esi>	; Save registers

; Save our selectors into the caller's GDT at AGROUP:EDI
; as per PMG_STR

; 1:  Install our code selector

	lea	esi,[edi].PMG_CODE ; GS:ESI ==> code selector
	mov	eax,VCPICODE	; Get our base address
	mov	ecx,VCPICODE_LIM ; Get segment limit
	call	SET_GDT 	; Set GDT entry GS:ESI to EAX limit ECX

	mov	AGROUP:[esi].DESC_ACCESS,CPL0_CODE ; Set ARB

; Set D-bit for USE32 and AVL-bit for PMODE

	or	AGROUP:[esi].DESC_SEGLM1,(mask $DTE_B) or (mask $DTE_AVL)

; 2:  Install our data selector

	lea	esi,[edi].PMG_DATA ; GS:ESI ==> data selector
	mov	eax,VCPIDATA	; Get our base address
	mov	ecx,VCPIDATA_LIM ; Get segment limit
	call	SET_GDT 	; Set GDT entry GS:ESI to EAX limit ECX

	mov	AGROUP:[esi].DESC_ACCESS,CPL0_DATA ; Set ARB

; Set B-bit for stack refs and AVL-bit for PMODE

	or	AGROUP:[esi].DESC_SEGLM1,(mask $DTE_B) or (mask $DTE_AVL)

; 3:  Install our CR3 selector

	lea	esi,[edi].PMG_CR3 ; GS:ESI ==> CR3 selector
	push	PaTMPPAGE	; Pass address in case not found
	push	NEW_CR3 	; Pass physical address to translate
	push	NEW_CR3 	; Pass physical address of CR3 to use
	call	PHYS2LIN	; Translate physical to linear via a CR3

	mov	ecx,4*1024-1	; 4KB length
;;;;;;; sub	ecx,eax 	; Less base address
	call	SET_GDT 	; Set GDT entry GS:ESI to EAX limit ECX

	mov	AGROUP:[esi].DESC_ACCESS,CPL0_DATA ; Set ARB

; 4:  Install our all memory selector

	lea	esi,[edi].PMG_4GB ; GS:ESI ==> 4GB selector
	xor	eax,eax 	; Get our base address
	mov	ecx,-1		; 4GB limit
	call	SET_GDT 	; Set GDT entry GS:ESI to EAX limit ECX

	mov	AGROUP:[esi].DESC_ACCESS,CPL0_DATA ; Set ARB

	REGREST <esi,ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST_PMG endp			; End INST_PMG procedure
	NPPROC	VCPI_FILLPTE -- Fill PTEs For VCPI Clients
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Fill in our PTEs for VCPI clients

On entry:

ECX	=	maximum # PTEs to fill in
ES:EDI	==>	destin
SS:EBP	==>	FORW_STR

On exit:

ES:EDI	==>	advanced
[EBP].FORW_EAX	 filled in if more PTEs to copy than specified
[EBP].FORW_ECX	 ...

|

	REGSAVE <eax,ebx,ecx,esi> ; Save registers

	PUSHW	cs		; Pass selector as argument
	call	GETLBASE	; Return with EAX = selector base

	mov	bx,cs		; Copy our code segment
	lsl	ebx,ebx 	; Get our segment limit
	inc	ebx		; Convert from limit to length

; Round down base address to 4KB boundary, round up length to 4KB boundary

	add	ebx,eax 	; Add to get ending address
	and	eax,not (4*1024-1) ; Round down to 4KB boundary
	sub	ebx,eax 	; Subtract to get extended length
	add	ebx,4*1024-1	; Round up to 4KB boundary
	shr	ebx,12-0	; Convert from bytes to 4KB (#PTEs)

	cmp	ecx,ebx 	; Izit within limits?
	jae	short @F	; Jump if so

	sub	ebx,ecx 	; Subtract to get # PTEs not copied
	mov	[ebp].FORW_ECX,ebx ; Return to caller
	mov	ebx,ecx 	; Use the smaller value
	mov	[ebp].FORW_EAX.ELO.HI,8Bh ; Mark as in error
@@:
	mov	ecx,ebx 	; Get # PTEs to copy
	mov	edx,edi 	; Save starting index

; If paging isn't enabled, fill in PTEs as one-to-one

	mov	ebx,cr0 	; Get register with Paging bit

	test	ebx,mask $PG	; Izit enabled?
	jnz	short VCPI_FILLPTE_PG ; Jump if so

	or	eax,@PTE_URP	; Mark as User/Read-write/Present
@@:
S32	stos	AGROUP:[edi].EDD ; Save as the next PTE
	add	eax,CON4KB	; Skip to next PTE

	loop	@B		; Jump if more PTEs to fill in

	jmp	short VCPI_FILLPTE_LCLPTE ; Join common code


VCPI_FILLPTE_PG:
	mov	ebx,cr3 	; Get current CR3
	and	ebx,@PTE_FRM	; Isolate the 4KB frame

	PUSHD	0		; Make room for original 2nd PTE
	PUSHD	0		; ...			 1st PTE
	PUSHD	2		; # PTEs to follow
	PUSHD	0		; Make room for original PDE
	push	eax		; Pass the linear address
	push	ebx		; Pass the CR3 to use
	call	LIN2PPTE	; Return with AGROUP:EAX ==> corresponding PTE

	mov	esi,eax 	; AGROUP:ESI ==> our PTEs
S32 rep movs	<AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy PTEs

	call	LIN2PPTEZ	; Cleanup after LIN2PPTE
	add	esp,2*4 	; Pop the two PTEs
VCPI_FILLPTE_LCLPTE:

; At PLCLMONO in the PDIR, put physical 000B0000h

	mov	ebx,SWATDATA	; Get linear address of DGROUP
	sub	ebx,SWATCODE	; Less linear address of PGROUP

	mov	eax,ebx 	; Copy offset of DGROUP in PGROUP
	add	eax,PLCLMONO	; Plus offset of table in DGROUP
	shr	eax,12-0	; Convert from bytes to 4KB
	lea	eax,AGROUP:[edx+eax*4] ; Add to get index

	cmp	eax,edi 	; Izit within bounds?
	jae	short @F	; Jump if not

	mov	AGROUP:[eax].EDD,@VID_MDAPTE ; Save the PTE
@@:

; At PLCLCOLR in the PDIR, put physical 000B8000h

	mov	eax,ebx 	; Copy offset of DGROUP in PGROUP
	add	eax,PLCLCOLR	; Plus offset of table in DGROUP
	shr	eax,12-0	; Convert from bytes to 4KB
	lea	eax,AGROUP:[edx+eax*4] ; Add to get index

	cmp	eax,edi 	; Izit within bounds?
	jae	short @F	; Jump if not

	mov	AGROUP:[eax].EDD,@VID_CLRPTE ; Save the PTE
@@:

; At PLCLCR3 in the PDIR, put physical NEW_CR3

	mov	eax,ebx 	; Copy offset of DGROUP in PGROUP
	add	eax,PLCLCR3	; Plus offset of table in DGROUP
	shr	eax,12-0	; Convert from bytes to 4KB
	lea	eax,AGROUP:[edx+eax*4] ; Add to get index

	cmp	eax,edi 	; Izit within bounds?
	jae	short @F	; Jump if not

	mov	esi,NEW_CR3	; Get the incoming CR3
	and	esi,@PTE_FRM	; Isolate the 4KB frame
	or	esi,@PTE_URP	; Mark as User/Read-write/Present
	mov	AGROUP:[eax].EDD,esi ; Save the PTE
@@:
	REGREST <esi,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI_FILLPTE endp		; End VCPI_FILLPTE procedure
	NPPROC	SET_TSSCR3 -- Set CR3 in Local TSSs
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set CR3 in local TSSs

On entry:

EAX	=	new CR3

|

	REGSAVE <eax,ebx,ecx,edx,esi> ; Save registers

	mov	ecx,NLCLTSS	; Get # LCLTSSxx structures
	xor	ebx,ebx 	; Initialize index into LCLTSSxx structures
@@:
	mov	esi,LCLTSS00.PTSS_Ixx[ebx] ; DGROUP:ESI ==> TSSxx
	mov	DGROUP:[esi].TSS_CR3,eax ; Save in TSS

	movzx	dx,LCLTSS00.INTNOxx[ebx] ; Get the interrupt #
	mov	DGROUP:[esi].TSS_SS1,dx ; Save in TSS for debugging purposes
				; so we can look in the TSS and see which
				; interrupt # this one handles
	add	ebx,size LCLTSS_STR ; Skip to next structure

	loop	@B		; Jump if more structures to initialize

	and	eax,@PTE_FRM	; Isolate the 4KB frame
	mov	NEW_CR3,eax	; Save for later use

	REGREST <esi,edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_TSSCR3 endp 		; End SET_TSSCR3 procedure
	FPPROC	PMDBG -- Debugger Protected Mode Entry Point
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debugger protected mode entry point.

EAX	=	@SWAT_CHGIDT  or
	=	@SWAT_CHGIDTZ or
	=	@SWAT_TRAPCR2 or
	=	@SWAT_DISAGP  or
	=	@SWAT_ENAAGP  or
	=	@SWAT_SETCR3  or
	=	@SWAT_SETDRn

|

; We must call an interrupt in order to set the 4GB and CR3
; selectors to valid values.

	cmp	eax,@SWAT_CHGIDTZ ; Izit end change IDTs?
	je	short PMDBG0	; Jump if so

;;;;;;; push	2
;;;;;;; call	U32_BLINK_LED
;;;;;;;
	int	01h

;;;;;;; push	3
;;;;;;; call	U32_BLINK_LED
;;;;;;;
	public	PMDBG_INT01
PMDBG_INT01:
PMDBG0:
	cmp	eax,@SWAT_CHGIDT ; Izit change IDTs?
	jne	short PMDBG1	; Jump if not

	REGSAVE <ebx,edx,ds,es> ; Save registers

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

; Establish addressibility to IDT

	sub	esp,size DTR_STR ; Make room on stack
	SIDTD	[esp].EDF	; Save IDTR on stack
	mov	ebx,[esp].DTR_BASE ; AGROUP:EBX ==> IDT
	mov	edx,MAXINT	; Get maximum interrupt # from INIT_PROT
	add	esp,size DTR_STR ; Strip from stack

	mov	es,COMMON.FILE_4GB ; Get all memory selector
	assume	es:AGROUP	; Tell the assembler about it

	call	REST_IDT	; Restore IDT entries

; Restore INT 41h, too

	movzx	edx,RGRSEG2	; Get low DOS memory segment
	shl	edx,4-0 	; Convert from paras to bytes
	assume	es:RGROUP	; Tell a white lie

	mov	eax,DEVINT41_FVEC.FOFF[edx] ; Get original offset
	mov	es:[ebx+41h*(type IDT_STR)].IDT_OFFLO,ax ; Save back
	shr	eax,16		; Shift down high-order word
	mov	es:[ebx+41h*(type IDT_STR)].IDT_OFFHI,ax ; Save back

	mov	ax,DEVINT41_FVEC.FSEL[edx] ; Get original selector
	mov	es:[ebx+41h*(type IDT_STR)].IDT_SELECT,ax ; Save back

	REGREST <es,ds,edx,ebx> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	jmp	PMDBG_E00	; Join common success code


PMDBG1:
	cmp	eax,@SWAT_CHGIDTZ ; Izit end change IDTs?
	jne	short PMDBG2	; Jump if not

	REGSAVE <ebx,edx,ds,es> ; Save registers

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

; Establish addressibility to IDT

	sub	esp,size DTR_STR ; Make room on stack
	SIDTD	[esp].EDF	; Save IDTR on stack
	mov	ebx,[esp].DTR_BASE ; AGROUP:EBX ==> IDT
	mov	edx,MAXINT	; Get maximum interrupt # from INIT_PROT
	add	esp,size DTR_STR ; Strip from stack

	mov	es,COMMON.FILE_4GB ; Get all memory selector
	assume	es:AGROUP	; Tell the assembler about it

	call	INIT_IDT	; Initialize the IDT entries at ES:EBX, lim EDX

	REGREST <es,ds,edx,ebx> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	jmp	PMDBG_E00	; Join common success code


PMDBG2:
	cmp	eax,@SWAT_TRAPCR2 ; Izit check for CR2 traps?
	jne	short PMDBG3	; Jump if not

	call	CheckTrapCR2	; Check on CR2 traps
	jnc	near ptr PMDBG_ERR83 ; Jump if there's no match

	jmp	PMDBG_E00	; Join common exit code


PMDBG3:
	cmp	eax,@SWAT_DISAGP ; Izit disable AGP controller if present?
	jne	short PMDBG4	; Jump if not

;;;;;;; push	4
;;;;;;; call	U32_BLINK_LED
;;;;;;;
	call	VxDDisableDispAGP ; Disable active display and AGP controller

	jmp	PMDBG_E00	; Join common exit code


PMDBG4:
	cmp	eax,@SWAT_ENAAGP ; Izit enable AGP controller if present?
	jne	short PMDBG5	; Jump if not

	call	VxDEnableDispAGP ; Enable active display and AGP controller

	jmp	PMDBG_E00	; Join common exit code


PMDBG5:
	cmp	eax,@SWAT_SETCR3 ; Izit set new CR3?
	jne	near ptr PMDBG6 ; Jump if not
COMMENT|

Set new CR3

On entry:

EDX	=	new CR3 physical
EBX	=	new CR3 linear

|

	pushad			; Save for a moment
	REGSAVE <ds,gs> 	; ...

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

	mov	OLDCR3,-1	; Reset previous CR3 value for video PTE checking

	test	VCP_FLAG,@VCP_PMG ; Doing Interrupt Gates?
	jz	short PMDBG5A	; Jump if not

	sub	esp,size DTR_STR ; Make room for GDTR
	SGDTD	[esp].EDF	; Save address of current GDT
	mov	esi,[esp].DTR_BASE ; AGROUP:ESI ==> GDT
	add	esp,size DTR_STR ; Strip

; Save new CR3 selector for next interrupt

	mov	eax,cs		; Get our code selector
	lea	eax,PMG_CR3[eax] ; Skip to CR3 selector
	mov	COMMON.FINT_BEG[@IMODE_PMG * (type FINT_STR)].FINT_CR3,ax ; ...

	add	esi,eax 	; GS:ESI ==> GDT entry for CR3 selector

	mov	eax,ebx 	; Get new CR3 linear
	and	eax,@PTE_FRM	; Isolate the 4KB frame

;;;	PUSHD	0		; Pass flag in case not found (no hope)
;;;	push	eax		; Pass physical address to translate
;;;	push	eax		; Pass physical address of CR3 to use
;;;	call	PHYS2LIN	; Translate physical to linear via a CR3
;;;
	mov	ecx,4*1024-1	; 4KB limit
	call	SET_GDT 	; Set GDT entry GS:ESI to EAX limit ECX

	mov	AGROUP:[esi].DESC_ACCESS,CPL0_DATA ; Save A/R byte

	jmp	short PMDBG5_EXIT ; Join common exit code


PMDBG5A:

; If FILE_CR3 is zero, then we must be
; in TSS mode, but called outside of it.

	movzx	eax,COMMON.FILE_CR3 ; Get the selector

	push	eax		; Save it to restore later

	and	eax,eax 	; Izit invalid?
	jnz	short @F	; Jump if not

	mov	COMMON.FILE_CR3,LDT_CR3 ; Use the TSS mode CR3 selector
@@:
	sldt	ax		; Get current LDTR

	push	eax		; Save to restore later

; We're presuming that if the FILE_CR3 selector is in the LDT,
; that it's our LDT from TSS mode.

	test	COMMON.FILE_CR3,mask $TI ; Izit in the LDT?
	jz	short @F	; Jump if not

	mov	eax,cs		; Get our code selector
	lea	eax,VCP_LDT[eax] ; Skip to the LDT
	lldt	ax		; Tell the CPU about it
@@:
	PUSHW	ds		; Pass selector as argument
	call	GETLBASE	; Return with EAX = selector base
	mov	esi,eax 	; Copy for later use

	mov	eax,edx 	; Get new CR3
	call	SET_TSSCR3	; Set new CR3 in the local TSSs to EAX

	PUSHD	0		; Pass flag in case not found (no hope)
	and	eax,@PTE_FRM	; Isolate the 4KB frame
	push	eax		; Pass physical address to translate
	push	eax		; Pass physical address of CR3 to use
	call	PHYS2LIN	; Translate physical to linear via a CR3

	lea	esi,LCLLDT[esi].MLDT_CR3 ; GS:ESI ==> CR3 selector entry in LDT
	mov	ecx,0FFFFEFFFh	; Large limit (can't use 4GB as PTEs won't display)
;;;;;;; sub	ecx,eax 	; Less base address
	call	SET_GDT 	; Set GDT entry GS:ESI to EAX limit ECX

	mov	AGROUP:[esi].DESC_ACCESS,CPL0_DATA ; Set ARB

	pop	eax		; Restore original LDTR

	lldt	ax		; Tell the CPU about it

	pop	eax		; Restore original FILE_CR3

	mov	COMMON.FILE_CR3,ax ; Restore
PMDBG5_EXIT:
	REGREST <gs,ds> 	; Restore
	assume	ds:nothing,gs:nothing ; Tell the assembler about it
	popad			; ...

	jmp	short PMDBG_E00 ; Join common exit code


PMDBG6:
	cmp	eax,@SWAT_SETDRn ; Izit set DRn registers?
	jne	near ptr PMDBG7 ; Jump if not

	REGSAVE <ds,gs> 	; Save registers

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

	call	REFRESH_DEBUG	; Refresh the debug hooks

	REGREST <gs,ds> 	; Restore
	assume	ds:nothing,gs:nothing ; Tell the assembler about it

	jmp	short PMDBG_E00 ; Join common exit code


PMDBG7:
PMDBG_ERR8F:
	mov	eax,8Fh 	; Mark as invalid subfunction

	jmp	short PMDBG_EXIT ; Join common exit code


PMDBG_ERR83:
	mov	eax,83h 	; Mark as invalid handle

	jmp	short PMDBG_EXIT ; Join common exit code


PMDBG_E00:
	mov	eax,0		; Mark as a success
;;;;;;;
;;;;;;; jmp	short PMDBG_EXIT ; Join common exit code
;;;;;;;
;;;;;;;
PMDBG_EXIT:
	RETFD			; Return to caller (32-bit)

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PMDBG	endp			; End PMDBG procedure
	NPPROC	SET_TSSINT -- Setup TSSINTxx_FVEC Variables
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup TSSINTxx_FVEC variables.

|

	REGSAVE <eax>		; Save register

	mov	eax,INDVCP_GDT	; Get current index
	mov	ax,CODESEL[eax*(type CODESEL)] ; Get the code selector

%	irp	XX,<@TSSINTS>	; Loop through all interrupts

	mov	TSSINT&XX&_FVEC.FSEL,VCP_TSS&XX-VCP_CODE ; Set base selector
	add	TSSINT&XX&_FVEC.FSEL,ax ; Plus offset to get actual

	endm			; IRP

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_TSSINT endp 		; End SET_TSSINT procedure
	NPPROC	INST_GDT -- Install GDT Entries
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Install our GDT entries

On entry:

GS:EDI	==>	next available GDT entry

|

	REGSAVE <eax,ebx,ecx,esi,edi,gs> ; Save registers

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

; 1:  Install our code selector

	lea	esi,[edi].VCP_CODE ; Skip to code selector
	mov	eax,VCPICODE	; Get our base address
	mov	ecx,VCPICODE_LIM ; Get segment limit
	call	SET_GDT 	; Set GDT entry GS:ESI to EAX limit ECX

	mov	AGROUP:[esi].DESC_ACCESS,CPL0_CODE ; Set ARB

; Set D-bit for USE32 and AVL-bit for PMODE

	or	AGROUP:[esi].DESC_SEGLM1,(mask $DTE_B) or (mask $DTE_AVL)

; 2:  Install our data selector

;;;;;;; lea	esi,[edi].VCP_DATA ; Skip to data selector
	add	esi,size DESC_STR ; Skip to data selector
	mov	eax,VCPIDATA	; Get our base address
	mov	ecx,VCPIDATA_LIM ; Get segment limit
	call	SET_GDT 	; Set GDT entry GS:ESI to EAX limit ECX

	mov	AGROUP:[esi].DESC_ACCESS,CPL0_DATA ; Set ARB

; Set B-bit for stack refs and AVL-bit for PMODE

	or	AGROUP:[esi].DESC_SEGLM1,(mask $DTE_B) or (mask $DTE_AVL)

; 3:  Install our LDT

	lea	esi,[edi].VCP_LDT ; Skip to LDT selector
	lea	eax,LCLLDT	; Get offset in data
	add	eax,VCPIDATA	; Plus our base linear data address
	mov	ecx,(size LCLLDT)-1 ; Get selector limit
	call	SET_GDT 	; Set GDT entry GS:ESI to EAX limit ECX

	mov	AGROUP:[esi].DESC_ACCESS,CPL0_LDT ; Set ARB
	or	AGROUP:[esi].DESC_SEGLM1,mask $DTE_AVL ; Set AVL-bit for PMODE

; 4+:  Install our TSS INT xxh selectors

	mov	ecx,NLCLTSS	; Get # LCLTSSxx structures
	xor	ebx,ebx 	; Initialize index into LCLTSSxx
INST_GDT_NEXT:
	push	ecx		; Save for a moment

	movzx	esi,LCLTSS00.DDTE_TSSxx[ebx] ; Get selector offset from CODESEL
	add	esi,edi 	; Plus GDT base for VCPI code selector
	mov	eax,LCLTSS00.PTSS_Ixx[ebx] ; Get offset of TSSxx in data
	add	eax,VCPIDATA	; Plus our base linear data address
	mov	ecx,(size TSS_STR)-1 ; Get selector limit
	call	SET_GDT 	; Set GDT entry GS:ESI to EAX limit ECX

	mov	AGROUP:[esi].DESC_ACCESS,CPL0_IDLE3 or CPL0 ; Set ARB
	or	AGROUP:[esi].DESC_SEGLM1,mask $DTE_AVL ; Set AVL-bit for PMODE

	pop	ecx		; Restore

	add	ebx,size LCLTSS_STR ; Skip to next LCLTSSxx structure

	loop	INST_GDT_NEXT	; Jump if more LCLTSSxx structures

; 5:  Install our TR selector for INSERT

	lea	esi,[edi].VCP_TR ; Skip to TR selector
	lea	eax,INSERT_TSS	; Get offset in data
	add	eax,VCPIDATA	; Plus our base linear data address
	mov	ecx,(size TSS_STR)-1 ; Get selector limit
	call	SET_GDT 	; Set GDT entry GS:ESI to EAX limit ECX

	mov	AGROUP:[esi].DESC_ACCESS,CPL0_IDLE3 ; Set ARB
	or	AGROUP:[esi].DESC_SEGLM1,mask $DTE_AVL ; Set AVL-bit for PMODE
	mov	eax,INDVCP_GDT	; Get current index
	mov	ax,CODESEL[eax*(type CODESEL)] ; Get the code selector
	add	ax,VCP_TR	; Skip to the TR selector
	mov	INSERT_EPM.VCPEPM_TR,ax ; Save in pseudo-TSS

; 6:  Install our 4GB selector for INSERT

	lea	esi,[edi].VCP_4GB ; Skip to 4GB selector
	xor	eax,eax 	; Get our base address
	mov	ecx,-1		; 4GB limit
	call	SET_GDT 	; Set GDT entry GS:ESI to EAX limit ECX

	mov	AGROUP:[esi].DESC_ACCESS,CPL0_DATA ; Set ARB
	or	AGROUP:[esi].DESC_SEGLM1,mask $DTE_AVL ; Set AVL-bit for PMODE
	mov	eax,INDVCP_GDT	; Get current index
	mov	ax,CODESEL[eax*(type CODESEL)] ; Get the code selector
	add	ax,VCP_4GB	; Skip to the 4GB selector
	mov	INSERT_SEL4GB,ax ; Save for later use

; Install LDT entries

	PUSHW	ds		; Pass selector as argument
	call	GETLBASE	; Return with EAX = selector base
	mov	edi,eax 	; Copy for later use

; 1:  Install our all memory selector

	lea	esi,LCLLDT[edi].MLDT_4GB ; GS:ESI ==> 4GB selector entry in LDT
	xor	eax,eax 	; Get our base address
	mov	ecx,-1		; 4GB limit
	call	SET_GDT 	; Set GDT entry GS:ESI to EAX limit ECX

	mov	AGROUP:[esi].DESC_ACCESS,CPL0_DATA ; Set ARB

; 2:  Install our CR3 selector

	lea	esi,LCLLDT[edi].MLDT_CR3 ; GS:ESI ==> CR3 selector entry in LDT
	push	PaTMPPAGE	; Pass address in case not found
	push	NEW_CR3 	; Pass physical address to translate
	push	NEW_CR3 	; Pass physical address of CR3 to use
	call	PHYS2LIN	; Translate physical to linear via a CR3

	mov	ecx,0FFFFEFFFh	; Large limit (can't use 4GB as PTEs won't display)
;;;;;;; sub	ecx,eax 	; Less base address
	call	SET_GDT 	; Set GDT entry GS:ESI to EAX limit ECX

	mov	AGROUP:[esi].DESC_ACCESS,CPL0_DATA ; Set ARB

; 3:  Install our code alias selector

	lea	esi,LCLLDT[edi].MLDT_ALIAS ; GS:ESI ==> code alias selector entry in LDT
	mov	eax,VCPICODE	; Get our base code address
	mov	ecx,VCPICODE_LIM ; Get selector limit
	call	SET_GDT 	; Set GDT entry GS:ESI to EAX limit ECX

	mov	AGROUP:[esi].DESC_ACCESS,CPL0_DATA ; Set ARB

	REGREST <gs,edi,esi,ecx,ebx,eax> ; Restore
	assume	gs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST_GDT endp			; End INST_GDT procedure
	NPPROC	INST_IDT -- Install IDT Entries
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Install our IDT entries

On entry:

ESI	==>	new VCPEPM_STR

|

	pushad			; Save all EGP registers

	mov	ebx,AGROUP:[esi].VCPEPM_IDTP ; AGROUP:EBX ==> IDTR

; Translate the IDT base address to the corresponding linear address
; according to the caller's CR3

	push	AGROUP:[ebx].DTR_BASE ; AGROUP:EBX ==> IDT
	push	AGROUP:[esi].VCPEPM_CR3 ; Pass caller's CR3 for L2P
	call	LIN2LIN 	; Return with EAX = corresponding linear addr

	mov	OLDVCP_IDT,eax	; Save for next time
	mov	ebp,eax 	; AGROUP:EBP ==> caller's IDT

; AGROUP:EBP ==> caller's IDT

; AGROUP:EBX ==> caller's IDT entry for this interrupt
; DS:EDI ==>	 LCLTSSxx structure

	lea	edi,LCLTSS00	; DS:EDI ==> LCLTSSxx structure
;;;;;;; lea	esi,LCLPMG00	; DS:ESI ==> LCLPMGxx ...
	mov	ecx,NLCLTSS	; Get # LCLTSSxx structures
INST_IDT_NEXTTSS:
	mov	esi,DGROUP:[edi].PLCLPMGxx ; DS:ESI ==> LCLPMGxx

; See if this interrupt # is found in the VMSINT_TAB table

	REGSAVE <ebx,ecx>	; Save for a moment

	mov	al,DGROUP:[edi].INTNOxx ; Get current interrupt #
	mov	ebx,VMSINT_PTR	; Initialize index into VMSINT_TAB
	movzx	ecx,DGROUP:[ebx-1].LO ; ECX = length of ...
	mov	edx,1		; Assume interrupt found
@@:
	cmp	al,DGROUP:[ebx] ; Izit in the table?
	je	short @F	; Jump if so (note DX = -1)

	inc	ebx		; Skip to next entry

	loop	@B		; Jump if more entries to check

	xor	edx,edx 	; Mark as not to install
@@:
	REGREST <ecx,ebx>	; Restore

	mov	eax,size IDT_STR ; Get size of an IDT entry
	mul	DGROUP:[edi].INTNOxx ; Times interrupt #
	lea	ebx,[eax+ebp]	; AGROUP:EBX ==> IDT entry for INT xxh

	push	edx		; Pass do/don't install flag (0 = don't)
	call	SETTSS		; Setup the TSS

	add	edi,size LCLTSS_STR ; Skip to next LCLTSSxx structure
;;;;;;; add	esi,size LCLPMG_STR ; ...	   LCLPMGxx ...

	loop	INST_IDT_NEXTTSS ; Jump if more LCLTSSx structures

; Because we're using TSSs, we must install our own INT 07h handler
; so we can execute CLTS if the TS bit is set in CR0.  Note we can't
; use a TSS for this as the trailing IRETD will set TS again, so we
; must use an interrupt gate.

	lea	ebx,[ebp+07h*(size IDT_STR)]  ; AGROUP:EBX ==> IDT entry for INT 07h
	mov	eax,INDVCP_GDT	; Get current index
	mov	ax,CODESEL[eax*(type CODESEL)] ; Get our VCPI code selector

	cmp	ax,AGROUP:[ebx].IDT_SELECT ; Same as before?
	je	short INST_IDT_EXIT ; Jump if so

	xchg	ax,AGROUP:[ebx].IDT_SELECT ; Swap 'em
	mov	OLDTSSINT07_FVEC.FSEL,ax ; Save to restore later

	lea	eax,LCL_INT07	; Get INT 07h offset in CODESEL
	rol	eax,16		; Swap high- and low-order words
	xchg	ax,AGROUP:[ebx].IDT_OFFHI ; Get old offset
	rol	eax,16		; Shift to high-order
	xchg	ax,AGROUP:[ebx].IDT_OFFLO ; Get old offset
	mov	OLDTSSINT07_FVEC.FOFF,eax ; Save to restore later

	mov	al,CPL0_INTR3 or CPL3 ; Get our access rights byte
	xchg	al,AGROUP:[ebx].IDT_ACCESS ; Swap 'em
	mov	OLDTSSINT07_ARB,al ; Save to restore later
INST_IDT_EXIT:
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST_IDT endp			; End INST_IDT procedure
	NPPROC	CHECK_EPM -- Check Enter Protected Mode Switch
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check enter protected mode switch.
If the GDT and/or IDT has changed from the last time, reset
the trap EPM flag.

On entry:

ESI	==>	new VCPEPM_STR

|

	REGSAVE <eax,ebx,ecx,edx,gs> ; Save registers

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

; Get the address of the caller's GDT

	mov	ebx,AGROUP:[esi].VCPEPM_GDTP ; AGROUP:EBX ==> GDTR

; Translate the GDT base address to the corresponding linear address
; according to the caller's CR3

	push	AGROUP:[ebx].DTR_BASE ; AGROUP:EBX ==> GDT
	push	AGROUP:[esi].VCPEPM_CR3 ; Pass caller's CR3 for L2P
	call	LIN2LIN 	; Return with EAX = corresponding linear addr

; Look for this address in our table of previous addresses

	mov	ecx,@LENVCP_GDT ; Get # entries we support
	xor	edx,edx 	; Initialize index into OLDVCP_GDT
@@:
	mov	INDVCP_GDT,edx	; Save as matching index

	cmp	eax,OLDVCP_GDT[edx*(type OLDVCP_GDT)] ; Same as before?
	je	short CHECK_EPM_IDT ; Jump if so

	inc	edx		; Skip to next index

	loop	@B		; Jump if more to check

; Find first non-zero OLDVCP_GDT index

	call	FIND_OLDVCP_GDT ; Find the next free entry in OLDVCP_GDT
				; Return index in EDX
	jc	short CHECK_EPM_CLR ; Jump if not found

; See if we're still installed there

	movzx	ecx,CODESEL[edx*(type CODESEL)] ; Get our code selector

	cmp	cx,AGROUP:[ebx].DTR_LIM ; Izit invalid?
	jae	short CHECK_EPM_CLR ; Jump if so

; Get the existing base address from the GDT

	mov	dh,AGROUP:[eax+ecx].DESC_BASE3 ; Get byte 3
	mov	dl,AGROUP:[eax+ecx].DESC_BASE2 ; Get byte 2
	shl	edx,16		; Shift to high-order word
	mov	dx,AGROUP:[eax+ecx].DESC_BASE01 ; Get bytes 0-1

	cmp	edx,VCPICODE	; Same as our base address?
	jne	short CHECK_EPM_CLR ; Jump if not

	mov	ecx,INDVCP_GDT	; Get current index
	mov	OLDVCP_GDT[ecx*(type OLDVCP_GDT)],eax ; Save for next time
CHECK_EPM_IDT:

; Get the address of the caller's IDT

	mov	ebx,AGROUP:[esi].VCPEPM_IDTP ; AGROUP:EBX ==> IDTR

; Translate the IDT base address to the corresponding linear address
; according to the caller's CR3

	push	AGROUP:[ebx].DTR_BASE ; AGROUP:EBX ==> IDT
	push	AGROUP:[esi].VCPEPM_CR3 ; Pass caller's CR3 for L2P
	call	LIN2LIN 	; Return with EAX = corresponding linear addr

	cmp	eax,OLDVCP_IDT	; Same as before?
	je	short CHECK_EPM_EXIT ; Jump if so

; Insert our own IDT entries into the IDT

	call	INST_IDT	; Install 'em

	or	VCP_FLAG,@VCP_EPM ; Mark as done for next time

	jmp	short CHECK_EPM_EXIT ; Join common exit code

CHECK_EPM_CLR:
	test	DBG_FLAG,@DBG_VCNT ; Are we doing it by count?
	jz	short @F	; Jump if not

	cmp	VMSCOUNT,0	; Have we reached the end?
	je	short CHECK_EPM_EXIT ; Jump if so

	dec	VMSCOUNT	; Adjust counter
@@:
	and	VCP_FLAG,not @VCP_EPM ; Mark as not done for next time
CHECK_EPM_EXIT:
	REGREST <gs,edx,ecx,ebx,eax> ; Restore
	assume	gs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_EPM endp			; End CHECK_EPM procedure
	NPPROC	FIND_OLDVCP_GDT -- Find Next Free Entry In OLDVCP_GDT
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find next free entry in OLDVCP_GDT

On exit:

EDX	=	index
CF	=	0 if found
	=	1 if not

|

	REGSAVE <ecx>		; Save register

	mov	ecx,@LENVCP_GDT ; Get # entries we support
	xor	edx,edx 	; Initialize index into OLDVCP_GDT
@@:
	cmp	OLDVCP_GDT[edx*(type OLDVCP_GDT)],0 ; Izit available?
	je	short @F	; Jump if so (note CF=0)

	inc	edx		; Skip to next index

	loop	@B		; Jump if more to check

	mov	edx,@LENVCP_GDT-1 ; Use last valid index

	stc			; Indicate not found
@@:
	mov	INDVCP_GDT,edx	; Save as matching index

	REGREST <ecx>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_OLDVCP_GDT endp		; End FIND_OLDVCP_GDT procedure
	NPPROC	TRAP_EPM -- Trap Enter Protected Mode Switch
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Trap enter protected mode switch.
Insinuate ourselves into the new GDT/IDT unless we're already there.

On entry:

ESI	==>	new VCPEPM_STR

On exit:

CF	=	0 if all went well
	=	1 otherwise

|

	pushad			; Save all EGP registers
	REGSAVE <gs>		; Save segment register

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

; Insert our own DTEs into the caller's GDT

	mov	ebx,AGROUP:[esi].VCPEPM_GDTP ; AGROUP:EBX ==> GDTR

	cmp	ebx,-1		; Izit unspecified?
	je	near ptr TRAP_EPM_IDT ; Jump if so

	movzx	edx,AGROUP:[ebx].DTR_LIM ; ECX = GDT limit
	inc	edx		; Convert from limit to length
	and	dx,not ((size DESC_STR)-1) ; Round down to DTE boundary
				; in case someone uses a length instead
				; of a limit
; Translate the GDT base address to the corresponding linear address
; according to the caller's CR3

	push	AGROUP:[ebx].DTR_BASE ; AGROUP:EBX ==> GDT
	push	AGROUP:[esi].VCPEPM_CR3 ; Pass caller's CR3 for L2P
	call	LIN2LIN 	; Return with EAX = corresponding linear addr

	mov	ebx,eax 	; AGROUP:EBX ==> caller's GDT

; Check GDT entry for INT 01h to see if we're still installed.
; If we are, assume that all GDT/IDT entries are the same

	movzx	eax,LCLTSS01.DDTE_TSSxx ; Get our relative GDT selector
	mov	ecx,INDVCP_GDT	; Get current index
	mov	cx,CODESEL[ecx*(type CODESEL)] ; Get our VCPI code selector

	cmp	cx,-1		; Izit invalid?
	je	short TRAP_EPM_NEXTBLK ; Jump if so

	add	ax,cx		; Plus our VCPI code selector
				; to get the actual GDT selector
	cmp	eax,edx 	; Ensure it's within range
	jae	short TRAP_EPM_NEXTBLK ; Jump if not

	mov	ecx,LCLTSS01.PTSS_Ixx ; Get offset to TSS01
	add	ecx,VCPIDATA	; Plus linear address of DGROUP

	cmp	cx,AGROUP:[ebx+eax].DESC_BASE01 ; Check it
	jne	short TRAP_EPM_NEXTBLK ; Jump if different

	shr	ecx,16		; Shift down the high-order word

	cmp	cl,AGROUP:[ebx+eax].DESC_BASE2 ; Check it
	jne	short TRAP_EPM_NEXTBLK ; Jump if different

	cmp	ch,AGROUP:[ebx+eax].DESC_BASE3 ; Check it
	je	near ptr TRAP_EPM_CLC ; Jump if same

; Search through the GDT from top down for consecutive
; all zero GDT entries.

TRAP_EPM_NEXTBLK:
	mov	ecx,(size VCPDTE_STR)/(type DESC_STR) ; Get # entries needed
TRAP_EPM_NEXTDTE:
	cmp	edx,1+size DESC_STR ; Ensure enough room
	jb	near ptr TRAP_EPM_EXIT ; Jump if none (note CF=1)

	call	GDTAVAIL	; Izit available?
	jne	short TRAP_EPM_NEXTBLK ; Not this one

	loop	TRAP_EPM_NEXTDTE ; Jump if more needed

	mov	eax,edx 	; Copy code selector
	call	FIND_OLDVCP_GDT ; Find the next free entry in OLDVCP_GDT
				; Return index in EDX
	jc	near ptr TRAP_EPM_EXIT ; Jump if none (note CF=1)

	mov	OLDVCP_GDT[edx*(type OLDVCP_GDT)],ebx ; Save for next time

; EAX = first of consecutive available selectors

	mov	CODESEL[edx*(type CODESEL)],ax ; Save for later use

	call	SET_TSSINT	; Save CODESEL into TSSINTxx_FVEC variables

	lea	edi,[ebx+eax]	; AGROUP:EDI ==> available GDT entries
	call	INST_GDT	; Install our GDT entries into AGROUP:EDI

; Ensure that the caller's CR3 and LDTR are set in its TSS

	call	SETTSS_VARS	; Set 'em up using GS:ESI ==> VCPEPM_STR
				; and OLDVCP_GDT
TRAP_EPM_IDT:

; Insert our own IDT entries into the IDT

	call	INST_IDT	; Install 'em
TRAP_EPM_CLC:
	clc			; Indicate all went well
TRAP_EPM_EXIT:
	REGREST <gs>		; Restore
	assume	gs:nothing	; Tell the assembler about it
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TRAP_EPM endp			; End TRAP_EPM procedure
	NPPROC	SETTSS_VARS -- Setup TSS Variables
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

GS:ESI	==>	VCPEPM_STR

|

	REGSAVE <eax,ebx,gs>	; Save registers

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

; Get the base address of the caller's TSS (286 or 386)

	movzx	ebx,AGROUP:[esi].VCPEPM_TR ; Get caller's TR
	and	bl,not (mask $PL) ; Clear the PL bits
	mov	eax,INDVCP_GDT	; Get the current index
	add	ebx,OLDVCP_GDT[eax*(type OLDVCP_GDT)] ; Plus base of GDT

	mov	eax,AGROUP:[ebx].DESC_BASE2.EDD ; Get bytes 2-xx-3
	rol	eax,8		; Put byte 2 in AH and byte 3 in AL
	xchg	al,ah		; Swap to normal order
	shl	eax,16		; Shift to high-order word
	mov	ax,AGROUP:[ebx].DESC_BASE01 ; Get bytes 0-1

	and	eax,eax 	; Izit valid?
	jnz	short SETTSS_VARS_VAL ; Jump if so

; The GDT base address is zero, so let's fill it in with the
; address of our own TSS

	lea	eax,PSEUDO_TSS	; Get offset in data of pseudo-TSS
	add	eax,VCPIDATA	; Plus base address of data

	push	eax		; Save for a moment

	mov	AGROUP:[ebx].DESC_BASE01,ax ; Set bytes 0-1
	shr	eax,16		; Shift high-order word down
	mov	AGROUP:[ebx].DESC_BASE2,al ; Set byte 2
	mov	AGROUP:[ebx].DESC_BASE3,ah ; ...      3

	cmp	AGROUP:[ebx].DESC_SEGLM0,0 ; Is the limit also unset?
	jne	short @F	; Jump if not

	mov	AGROUP:[ebx].DESC_SEGLM0,(type TSS_STR)-1 ; Use default size
@@:
	pop	eax		; Restore
SETTSS_VARS_VAL:
	push	eax		; AGROUP:EAX ==> caller's TSS
	push	AGROUP:[esi].VCPEPM_CR3 ; Pass caller's CR3 for L2P
	call	LIN2LIN 	; Return with EAX = corresponding linear addr

; Split cases depending upon 286 or 386 TSS

	mov	bl,AGROUP:[ebx].DESC_ACCESS ; Get the ARB
	and	bl,not (mask $DT_DPL) ; Clear DPL bits

	cmp	bl,CPL0_IDLE2	; Izit an idle 286 TSS?
	je	short SETTSS_VARS2 ; Jump if so

	cmp	bl,CPL0_BUSY2	; Izit a busy 286 TSS?
	je	short SETTSS_VARS2 ; Jump if so

	cmp	bl,CPL0_IDLE3	; Izit an idle 386 TSS?
	je	short SETTSS_VARS3 ; Jump if so

	cmp	bl,CPL0_BUSY3	; Izit a busy 386 TSS?
	jne	short SETTSS_VARS_EXIT ; Jump if not
SETTSS_VARS3:
	mov	ebx,AGROUP:[esi].VCPEPM_CR3 ; Get caller's CR3
	mov	AGROUP:[eax].TSS_CR3,ebx ; Save in caller's 386 TSS

; Ensure that the caller's LDT is set in its 386 TSS

	mov	bx,AGROUP:[esi].VCPEPM_LDTR ; Get caller's LDT
	mov	AGROUP:[eax].TSS_LDT,bx ; Save in caller's 386 TSS

	jmp	short SETTSS_VARS_EXIT ; Join common exit code


; Ensure that the caller's LDT is set in its 286 TSS

SETTSS_VARS2:
	mov	bx,AGROUP:[esi].VCPEPM_LDTR ; Get caller's LDT
	mov	AGROUP:[eax].TSS2_LDT,bx ; Save in caller's 286 TSS
SETTSS_VARS_EXIT:
	REGREST <gs,ebx,eax>	; Restore
	assume	gs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETTSS_VARS endp		; End SETTSS_VARS procedure
	NPPROC	LIN2PPTE -- Translate Linear To PTE Pointer Via Caller's CR3
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Translate a linear address to a pointer to the corresponding PTE
according to a specific CR3.

On exit:

AGROUP:EAX ==>	 PTE which maps this linear address

|

L2P_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
L2P_CR3 dd	?		; ...	   CR3 for physical to linear
L2P_LIN dd	?		; ...	   linear address
L2P_PDE dd	?		; Save area for PDE
L2P_CNT dd	?		; # PTEs to follow
L2P_PTE dd	?		; Save area for 1st PTE (more may follow)

L2P_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ebx,ecx,edx,es> ; Save registers

	mov	eax,cr0 	; Get register with Paging bit

	test	eax,mask $PG	; Izit enabled?
	jnz	short LIN2PPTE_PG ; Jump if so

; Paging isn't enabled.  Parse the incoming address as per the specified CR3.

; Note that this technique doesn't work if the linear address
; (plus an unspecified length) spans a 4MB boundary and the
; corresponding PDEs aren't physically consecutive.

	mov	ebx,[ebp].L2P_CR3 ; Get the specified CR3
	and	ebx,@PTE_FRM	; Isolate the 4KB frame
	jnz	short @F	; Jump if valid

	int	03h		; Call ourselves
@@:
	mov	eax,[ebp].L2P_LIN ; Get the linear address
	and	eax,mask $LA_DIR ; Isolate the directory index
	shr	eax,$LA_DIR	; Shift to low-order

	mov	ebx,AGROUP:[ebx+eax*4] ; Get the PDE
	and	ebx,@PTE_FRM	; Isolate the 4KB frame

	mov	eax,[ebp].L2P_LIN ; Get the linear address
	and	eax,mask $LA_PAGE ; Isolate the page index
	shr	eax,$LA_PAGE	; Shift to low-order

	lea	eax,AGROUP:[ebx+eax*4] ; Point to PTEs

	jmp	LIN2PPTE_EXIT	; Join common exit code

; Establish addressibility to our local PDIR

LIN2PPTE_PG:
	mov	es,COMMON.FILE_CR3 ; Get our CR3 selector
	assume	es:PDTGRP	; Tell the assembler about it

; ES:0 = linear address of 1st level PDIR (CR3)

	mov	eax,PaLCLPDIR	; Get physical address of our local PDIR
	or	eax,@PTE_URP	; Mark as User/Read-write/Present
	xchg	eax,OFFPDT[@PDELOC] ; Swap with the PDE there (if any)
	call	FLUSH_CACHE	; Flush the TLB
	mov	[ebp].L2P_PDE,eax ; Save to restore later

	mov	edx,PLCLPDIR	; Get offset to our local PDIR
	mov	ecx,[ebp].L2P_CNT ; Get # PTEs to follow
	xor	ebx,ebx 	; Initialize index
@@:
	mov	eax,DGROUP:[edx+ebx*4] ; Get 1st PDE in our local PDIR
	mov	[ebp+ebx*4].L2P_PTE,eax ; Save to restore later

	inc	ebx		; Skip to next PTE

	loop	@B		; Jump if more PTEs to copy

; At this point, our local PDIR maps the addresses at AGROUP:@PDELIN

	mov	eax,[ebp].L2P_CR3 ; Get the CR3 to use
	and	eax,@PTE_FRM	; Isolate the 4KB frame
	or	eax,@PTE_URP	; Mark as User/Read-write/Present
	mov	DGROUP:[edx],eax ; Save in local PDIR
	call	FLUSH_CACHE	; Flush the TLB

; The caller's CR3 is now addressible at AGROUP:@PDELIN

	mov	eax,[ebp].L2P_LIN ; Get the linear address
	and	eax,mask $LA_DIR ; Isolate directory index
	shr	eax,($LA_DIR-2)-0 ; Convert from bytes to 4MB in dwords

; N.B.:  We can't use AGROUP:[EAX*4+@PDELIN] as MASM doesn't handle it correctly

	mov	ecx,[ebp].L2P_CNT ; Get # PTEs to follow
@@:
	mov	ebx,AGROUP:[eax+@PDELIN] ; Get the corresponding PDE
	and	ebx,@PTE_FRM	; Isolate the 4KB frame

; EBX = physical address of next 2nd level page table

	or	ebx,@PTE_URP	; Mark as User/Read-write/Present
	mov	DGROUP:[edx],ebx ; Save in local PDIR

	add	eax,4		; Skip to next PTE source
	add	edx,4		; ...		   destin

	loop	@B		; Jump if more PTEs to copy

	call	FLUSH_CACHE	; Flush the TLB

; At this point, the PDE for the original address is addressible at AGROUP:@PDELIN

	mov	eax,[ebp].L2P_LIN ; Get the linear address
	and	eax,mask $LA_PAGE ; Isolate page index
	shr	eax,($LA_PAGE-2)-0 ; Convert from bytes to 4KB in dwords
	add	eax,@PDELIN	; Skip to the corresponding PTE
LIN2PPTE_EXIT:
	REGREST <es,edx,ecx,ebx> ; Restore
	assume	es:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	4+4		; Return to caller, popping arguments
				; Note we don't pop L2P_PDE and L2P_PTEs
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LIN2PPTE endp			; End LIN2PPTE procedure
	NPPROC	LIN2PPDIR -- Translate Linear To PDIR Pointer Via Caller's CR3
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Translate a linear address to a pointer to the corresponding PDIR
according to a specific CR3.

On exit:

AGROUP:EAX ==>	 PDIR which maps this linear address

|

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ebx,ecx,edx,es> ; Save registers

	mov	eax,cr0 	; Get register with Paging bit

	test	eax,mask $PG	; Izit enabled?
	jnz	short LIN2PPDIR_PG ; Jump if so

; Paging isn't enabled.  Parse the incoming address as per the specified CR3.

; Note that this technique doesn't work if the linear address
; (plus an unspecified length) spans a 4MB boundary and the
; corresponding PDEs aren't physically consecutive.

	mov	ebx,[ebp].L2P_CR3 ; Get the specified CR3
	and	ebx,@PTE_FRM	; Isolate the 4KB frame

	mov	eax,[ebp].L2P_LIN ; Get the linear address
	and	eax,mask $LA_DIR ; Isolate the directory index
	shr	eax,$LA_DIR	; Shift to low-order

	lea	eax,AGROUP:[ebx+eax*4] ; Point to PDIRs

	jmp	short LIN2PPDIR_EXIT ; Join common exit code

; Establish addressibility to our local PDIR

LIN2PPDIR_PG:
	mov	es,COMMON.FILE_CR3 ; Get our CR3 selector
	assume	es:PDTGRP	; Tell the assembler about it

; ES:0 = linear address of 1st level PDIR (CR3)

	mov	eax,PaLCLPDIR	; Get physical address of our local PDIR
	or	eax,@PTE_URP	; Mark as User/Read-write/Present
	xchg	eax,OFFPDT[@PDELOC] ; Swap with the PDE there (if any)
	call	FLUSH_CACHE	; Flush the TLB
	mov	[ebp].L2P_PDE,eax ; Save to restore later

	mov	edx,PLCLPDIR	; Get offset to our local PDIR
	mov	ecx,[ebp].L2P_CNT ; Get # PDEs to follow
	xor	ebx,ebx 	; Initialize index
@@:
	mov	eax,DGROUP:[edx+ebx*4] ; Get 1st PDE in our local PDIR
	mov	[ebp+ebx*4].L2P_PTE,eax ; Save to restore later

	inc	ebx		; Skip to next PDE

	loop	@B		; Jump if more PTEs to copy

; At this point, our local PDIR maps the addresses at AGROUP:@PDELIN

	mov	eax,[ebp].L2P_CR3 ; Get the CR3 to use
	and	eax,@PTE_FRM	; Isolate the 4KB frame
	or	eax,@PTE_URP	; Mark as User/Read-write/Present
	mov	DGROUP:[edx],eax ; Save in local PDIR
	call	FLUSH_CACHE	; Flush the TLB

; The caller's CR3 is now addressible at AGROUP:@PDELIN

	mov	eax,[ebp].L2P_LIN ; Get the linear address
	and	eax,mask $LA_DIR ; Isolate directory index
	shr	eax,($LA_DIR-2)-0 ; Convert from bytes to 4MB in dwords
	add	eax,@PDELIN	; Skip to the corresponding PDIR
LIN2PPDIR_EXIT:
	REGREST <es,edx,ecx,ebx> ; Restore
	assume	es:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	4+4		; Return to caller, popping arguments
				; Note we don't pop L2P_PDE and L2P_PTEs
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LIN2PPDIR endp			; End LIN2PPDIR procedure
	NPPROC	LIN2PPTEZ -- Cleanup After LIN2PPTE
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Cleanup after LIN2PPTE

|

L2PZ_STR  struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
L2PZ_PDE dd	?		; Save area for original PDE
L2PZ_CNT dd	?		; # PTEs to follow
L2PZ_PTE dd	?		; Save area for 1st PTE (more may follow)

L2PZ_STR  ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ebx,ecx,edx,es> ; Save registers

	mov	eax,cr0 	; Get register with Paging bit

	test	eax,mask $PG	; Izit enabled?
	jz	short LIN2PPTEZ_EXIT ; Jump if not

	mov	es,COMMON.FILE_CR3 ; Get our CR3 selector
	assume	es:PDTGRP	; Tell the assembler about it

	mov	edx,PLCLPDIR	; Get offset to our local PDIR
	mov	ecx,[ebp].L2PZ_CNT ; Get # PTEs/PDEs to follow
	xor	ebx,ebx 	; Initialize index
@@:
	mov	eax,[ebp+ebx*4].L2PZ_PTE ; Get the original next PTE/PDE
	mov	DGROUP:[edx+ebx*4],eax ; Restore 1st PTE/PDE in our local PDIR

	inc	ebx		; Skip to next PTE/PDE

	loop	@B		; Jump if more PTEs/PDEs to restore

	mov	eax,[ebp].L2PZ_PDE ; Get the original PDE
	mov	OFFPDT[@PDELOC],eax ; Restore the old PDE there (if any)

	call	FLUSH_CACHE	; Flush the TLB
LIN2PPTEZ_EXIT:
	REGREST <es,edx,ecx,ebx,eax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	pop	ebp		; Restore

; It's up to the caller to pop the L2PZ_CNT PTEs

	ret	4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LIN2PPTEZ endp			; End LIN2PPTEZ procedure
	NPPROC	LIN2LIN -- Translate Linear To Linear Via Caller's CR3
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Translate a linear address to a linear address
according to a specific CR3.

On exit:

EAX	=	translated address

|

L2L_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
L2L_CR3 dd	?		; ...	   CR3 for physical to linear
L2L_LIN dd	?		; ...	   linear address

L2L_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ebx>		; Save register

	mov	eax,[ebp].L2L_LIN ; Get the linear address

	cmp	[ebp].L2L_CR3,-1 ; Izit unspecified?
	je	short LIN2LIN_EXIT ; Jump if so

	cmp	[ebp].L2L_CR3,0 ; Izit unspecified?
	je	short LIN2LIN_EXIT ; Jump if so

	PUSHD	0		; Make room for original PTE
	PUSHD	1		; # PTEs to follow
	PUSHD	0		; Make room for original PDE
	push	eax		; Pass the linear address
	push	[ebp].L2L_CR3	; Pass the CR3 to use
	call	LIN2PPTE	; Return with AGROUP:EAX ==> corresponding PTE

	mov	ebx,AGROUP:[eax] ; Get the corresponding PTE
	and	ebx,@PTE_FRM	; Isolate the 4KB frame

	call	LIN2PPTEZ	; Cleanup after LIN2PPTE
	add	esp,1*4 	; Pop the PTE

; Translate this physical address to the corresponding linear address

	PUSHD	0		; Pass flag in case not found (no hope)
	push	ebx		; Pass physical address to translate
	mov	eax,cr3 	; Get our CR3
	push	eax		; Pass CR3 for P2L
	call	PHYS2LIN	; Translate physical to linear via a CR3

; EAX = linear address of the 4KB PTE containing the original linear address

	mov	ebx,[ebp].L2L_LIN ; Get the linear address
	and	ebx,mask $LA_OFF ; Isolate offset portion
	add	eax,ebx 	; Add to get corresponding linear address
LIN2LIN_EXIT:
	REGREST <ebx>		; Restore

	pop	ebp		; Restore

	ret	4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LIN2LIN endp			; End LIN2LIN procedure
	NPPROC	RHYS2LIN -- Translate Physical To Linear Address
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Translate a physical address to a linear address
according to a specific CR3 with paging disabled.

On exit:

EAX	=	linear address

|

R2L_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
R2L_CR3 dd	?		; ...	   CR3
R2L_PHYS dd	?		; ...	   physical address
R2L_TEMP dd	?		; Temp page if not found (0 = don't try)

R2L_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ebx,ecx,edx,esi> ; Save registers

	mov	eax,[ebp].R2L_PHYS ; Get physical address in case CR3=0
	mov	ebx,[ebp].R2L_CR3 ; Get CR3

	and	ebx,@PTE_FRM	; Isolate the 4KB frame
	jz	near ptr RHYS2LIN_EXIT ; Jump if not valid

	mov	[ebp].R2L_CR3,ebx ; Save back as frame address

	mov	ecx,1024	; Get # PDEs
	and	eax,@PTE_FRM	; Isolate the 4KB frame
	mov	edx,eax 	; Copy
RHYS2LIN_NEXTPDE:
	mov	esi,AGROUP:[ebx] ; Get next PDE

	test	esi,mask $PTE_P ; Izit present?
	jz	short RHYS2LIN_LOOPPDE ; Jump if not

; Check for Page Size Extensions (4MB pages)

	test	esi,mask $PTE_PS ; Izit a 4MB page?
	jz	short @F	; Jump if not

	and	esi,@PTE_FRM	; Isolate the 4KB frame

	cmp	edx,esi 	; Izit at or above the address?
	jb	short @F	; Jump if not

	lea	eax,[esi+4*1024*1024] ; Skip to next 4MB page

	cmp	edx,eax 	; Izit below the ending address?
	jb	short RHYS2LIN1 ; Jump if so
@@:
	and	esi,@PTE_FRM	; Isolate the 4KB frame

	push	ecx		; Save for a moment

	mov	ecx,1024	; Get # PTEs in a PDE
RHYS2LIN_NEXTPTE:
	lods	AGROUP:[esi].EDD ; Get next PTE

	test	eax,mask $PTE_P ; Izit present?
	jz	short RHYS2LIN_LOOPPTE ; Jump if not

	and	eax,@PTE_FRM	; Isolate the 4KB frame

	cmp	edx,eax 	; Izit equal?
	je	short @F	; Jump if so (note ZF=1)
RHYS2LIN_LOOPPTE:
	loop	RHYS2LIN_NEXTPTE ; Jump if more PTEs to check
	cmp	ecx,1		; Ensure ZF=0
@@:
	pop	ecx		; Restore
	jne	short RHYS2LIN_LOOPPDE ; Jump if no match

; We have a match
; EBX	==>	PDE
; ESI	==>	next PTE (4 to 1024) /4

	sub	esi,type OFFPDT ; Less last PTE
	mov	eax,AGROUP:[ebx] ; Get PDE
	and	eax,@PTE_FRM	; Isolate the 4KB frame
	sub	esi,eax 	; Less start of PDE to get offset in PDE
	shl	esi,($LA_PAGE-2)-0 ; Convert from 4KB in dwords to bytes

;;;;;;; sub	ebx,[ebp].R2L_CR3 ; Less starting address
;;;;;;; shl	ebx,($LA_DIR-2)-0 ; Convert from 4MB in dwords to bytes
;;;;;;;
;;;;;;; add	esi,ebx 	; Add to get frame address
;;;;;;;
	mov	edx,mask $LA_OFF ; Get mask for offset

	jmp	short RHYS2LIN_DONE ; Join common done code


RHYS2LIN_LOOPPDE:
	add	ebx,type OFFPDT ; Skip to next PDE

	loop	RHYS2LIN_NEXTPDE ; Jump if more PDEs

	int	03h		; Call our debugger
RHYS2LIN1:

; We have a match
; EBX	==>	PDE

	xor	esi,esi 	; Zero base address
	mov	edx,(mask $LA_PAGE) or (mask $LA_OFF) ; Get mask for offset
RHYS2LIN_DONE:
	sub	ebx,[ebp].R2L_CR3 ; Less starting address
	shl	ebx,($LA_DIR-2)-0 ; Convert from 4MB in dwords to bytes

	add	esi,ebx 	; Add to get frame address
;;;RHYS2LIN_DONE:
	mov	eax,[ebp].R2L_PHYS ; Get original physical address
	and	eax,edx 	; Isolate offset in the 4KB or 4MB frame
	add	eax,esi 	; Add to get linear address
RHYS2LIN_EXIT:
	REGREST <esi,edx,ecx,ebx> ; Restore

	pop	ebp		; Restore

	ret	4+4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RHYS2LIN endp			; End RHYS2LIN procedure
	NPPROC	PHYS2LIN -- Translate Physical To Linear Address
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Translate a physical address to a linear address
according to a specific CR3.

On exit:

EAX	=	linear address

|

P2L_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
P2L_CR3 dd	?		; ...	   CR3
P2L_PHYS dd	?		; ...	   physical address
P2L_TEMP dd	?		; Temp page if not found (0 = don't try)

P2L_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ebx,ecx,edx,esi,es> ; Save registers

; If paging isn't enabled, we need to search for the PTEs ourselves

	mov	eax,cr0 	; Get register with Paging bit

	test	eax,mask $PG	; Izit enabled?
	jnz	short @F	; Jump if so

	push	[ebp].P2L_TEMP	; Pass temp page
	push	[ebp].P2L_PHYS	; ...  physical address
	push	[ebp].P2L_CR3	; ...  CR3
	call	RHYS2LIN	; Translate physical to linear via a CR3

	jmp	PHYS2LIN_EXIT	; Join common exit code


@@:

; Establish addressibility to our local PDIR

	mov	es,COMMON.FILE_CR3 ; Get selector of our CR3
	assume	es:PDTGRP	; Tell the assembler about it

; ES:0 = linear address of 1st level PDIR (CR3)

	mov	edx,PLCLPDIR	; Get offset to our local PDIR
	push	OFFPDT[@PDELOC].EDD ; Save the PDE there (if any)
	push	DGROUP:[edx].EDQLO ; Save 1st PDE in our local PDIR
	push	DGROUP:[edx].EDQHI ; ...  2nd ...

	mov	eax,PaLCLPDIR	; Get physical address of our local PDIR
	or	eax,@PTE_URP	; Mark as User/Read-write/Present
	mov	OFFPDT[@PDELOC],eax ; Save as new PDE

; At this point, our local PDIR maps the addresses at AGROUP:@PDELIN

	mov	ebx,[ebp].P2L_CR3 ; Get the CR3 to use
	and	ebx,@PTE_FRM	; Isolate the 4KB frame
	or	ebx,@PTE_URP	; Mark as User/Read-write/Present
	mov	DGROUP:[edx],ebx ; Save in local PDIR
	call	FLUSH_CACHE	; Flush the TLB

; The caller's CR3 is now addressible at AGROUP:@PDELIN

	mov	ebx,[ebp].P2L_PHYS ; Get original physical address
	and	ebx,not (mask $LA_OFF) ; Isolate the 4KB frame

; We loop through the PDEs at AGROUP:@PDELIN, map each own into our local PDIR,
; and examine each one for a matching PTE

	mov	ecx,4*1024/4	; # PDEs in a 4KB PDIR at AGROUP:@PDELIN
	mov	esi,@PDELIN	; Get address of 1st PDE
PHYS2LIN_OUTERNEXT:
	lods	AGROUP:[esi].EDD ; Get next PDE

	test	ax,mask $PTE_P	; Izit present?
	jz	short PHYS2LIN_OUTERLOOP ; Jump if not

	mov	DGROUP:[edx].EDQHI,eax ; Save in our local PDIR
	call	FLUSH_CACHE	; Flush the TLB

; At this point, the next PDE in CR3 is addressible at AGROUP:@PDELIN

; Search for EBX in the 4KB of PTEs at AGROUP:@PDELIN2

	REGSAVE <ecx,esi>	; Save for a moment

	mov	ecx,4*1024/4	; # PTEs in a 4KB PDE at AGROUP:@PDELIN2
	mov	esi,@PDELIN2	; Get address of 1st PTE
PHYS2LIN_INNERNEXT:
	lods	AGROUP:[esi].EDD ; Get next PTE

	test	ax,mask $PTE_P	; Izit present?
	jz	short PHYS2LIN_INNERLOOP ; Jump if not

	and	eax,not (mask $LA_OFF) ; Isolate the 4KB frame

	cmp	eax,ebx 	; Same value?
	jne	short PHYS2LIN_INNERLOOP ; Jump if not

; We found it

	mov	eax,esi 	; Copy offset to next PTE
	sub	eax,@PDELIN2+4	; Convert to origin-0
	shl	eax,($LA_PAGE-2)-0 ; Convert from 4KB in dwords to bytes

	REGREST <esi,ecx>	; Restore

	sub	esi,@PDELIN+4	; Convert to origin-0
	shl	esi,($LA_DIR-2)-0 ; Convert from 4MB in dwords to bytes
	add	esi,eax 	; Add to get linear address of 4KB frame

	jmp	short PHYS2LIN_DONE ; Join common done code


PHYS2LIN_INNERLOOP:
	loop	PHYS2LIN_INNERNEXT ; Jump if more PTEs to search

	REGREST <esi,ecx>	; Restore
PHYS2LIN_OUTERLOOP:
	loop	PHYS2LIN_OUTERNEXT ; Jump if more PDEs to search through

	cmp	[ebp].P2L_TEMP,0 ; Should we try another route?
	je	short PHYS2LIN_ERR ; Jump if not

	int	01h		; Call debugger on no match???

; We didn't find the address we're looking for -- try finding our
; temporary page and return its linear address as the result

	PUSHD	0		; Pass flag in case not found (no hope)
	push	[ebp].P2L_TEMP	; Pass physical address to translate
				; (multiple of 4KB)
	push	[ebp].P2L_CR3	; Pass physical address of CR3 to use
	call	PHYS2LIN	; Translate physical to linear via a CR3

	mov	esi,eax 	; Save as linear address of sought after
				; physical address
	push	eax		; Pass linear address to translate
	mov	eax,cr3 	; Get our CR3
	push	eax		; Pass physical address of CR3 to use
	call	LIN2LIN 	; Return with EAX = corresponding linear addr

	mov	edx,[ebp].P2L_PHYS ; Get the physical address we're looking for
	and	edx,@PTE_FRM	; Isolate the 4KB frame
	mov	AGROUP:[eax],edx ; Save in the other PDE

	jmp	short PHYS2LIN_DONE ; Join common done code


PHYS2LIN_ERR:
	int	01h		; Call debugger on no match???

	cli			; Stop the presses
	hlt
PHYS2LIN_DONE:
	mov	eax,[ebp].P2L_PHYS ; Get original physical address
	and	eax,mask $LA_OFF ; Isolate offset in the 4KB frame
	add	eax,esi 	; Add to get linear address

;;;;;;; mov	edx,PLCLPDIR	; Get offset to our local PDIR
	pop	DGROUP:[edx].EDQHI ; Restore 2nd PDE in our local PDIR
	pop	DGROUP:[edx].EDQLO ; ...     1st ...
	pop	OFFPDT[@PDELOC].EDD ; Restore the PDE there (if any)
	call	FLUSH_CACHE	; Flush the TLB
PHYS2LIN_EXIT:
	REGREST <es,esi,edx,ecx,ebx> ; Restore
	assume	es:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	4+4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PHYS2LIN endp			; End PHYS2LIN procedure
	NPPROC	LIN2PHYS -- Translate Linear To Physical Address
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Translate a linear address to a physical address

On entry:

EAX	=	Linear address

On exit:

EAX	=	Physical address

|

	REGSAVE <ebx,ecx,edx,es,gs> ; Save for a while

; If paging is not enabled, linear = physical

	mov	ebx,cr0 	; Get register with Paging bit

	test	ebx,mask $PG	; Izit enabled?
	jz	short LIN2PHYS_EXIT ; Jump if not with EAX = physical address

; EAX = input linear address

	mov	edx,eax 	; Save a copy of the linear address

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

	mov	es,COMMON.FILE_CR3 ; Get selector of our CR3
	assume	es:PDTGRP	; Tell the assembler about it

; ES:0 = linear address of 1st level PDIR (CR3)

	mov	ecx,PLCLPDIR	; Get offset to our local PDIR
	push	OFFPDT[@PDELOC].EDD ; Save the PDE there (if any)
	push	DGROUP:[ecx].EDD ; Save 1st PDE in our local PDIR

	mov	eax,PaLCLPDIR	; Get physical address of our local PDIR
	or	eax,@PTE_URP	; Mark as User/Read-write/Present
	mov	OFFPDT[@PDELOC],eax ; Save as new PDE

; At this point, our local PDIR maps the addresses at AGROUP:@PDELIN

	mov	eax,edx 	; Copy the original linear address
	and	eax,mask $LA_DIR ; Isolate directory portion
	shr	eax,$LA_DIR-0	; Convert from bytes to 4MB
	mov	ebx,OFFPDT[eax*(type OFFPDT)] ; Get PDE
	and	ebx,@PTE_FRM	; Isolate the 4KB frame

; EBX = physical address of 2nd level PT

	or	ebx,@PTE_URP	; Mark as User/Read-write/Present
	mov	DGROUP:[ecx],ebx ; Save in our local PDIR
	call	FLUSH_CACHE	; Flush the TLB

; At this point, the PDE for the original address is addressible at AGROUP:@PDELIN

	mov	eax,edx 	; Copy the original linear address
	and	eax,mask $LA_PAGE ; Isolate page portion
	shr	eax,($LA_PAGE-2)-0 ; Convert from bytes to 4KB in dwords

; N.B.:  We can't use AGROUP:[EAX*4+@PDELIN] as MASM doesn't handle it correctly

	mov	ebx,AGROUP:[eax+@PDELIN] ; Get the PTE
	and	ebx,@PTE_FRM	; Isolate the 4KB frame

; EBX = physical address which contains the 4KB linear address

	mov	eax,edx 	; Get the original linear address
	and	eax,mask $LA_OFF ; Isolate the offset portion
	add	eax,ebx 	; Add offset to physical address of page

; EAX = physical address corresponding to input linear address

;;;;;;; mov	ecx,PLCLPDIR	; Get offset to our local PDIR
	pop	DGROUP:[ecx].EDD ; Restore 1st PDE in our local PDIR
	pop	OFFPDT[@PDELOC].EDD ; Restore the PDE there (if any)
	call	FLUSH_CACHE	; Flush the TLB
LIN2PHYS_EXIT:
	REGREST <gs,es,edx,ecx,ebx> ; Restore
	assume	es:nothing,gs:nothing ; Tell the assembler about it

	ret			; To caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LIN2PHYS endp			; End LIN2PHYS procedure
	NPPROC	GDTAVAIL -- Check for GDTE Available
	assume	ds:nothing,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Check to see if the previous GDT entry is available.

On entry:

EBX+EDX-8 ==>	 previous GDT entry

On exit:

EDX	=	EDX-8
ZF	=	1 if all zero
	=	0 otherwise

|

@GDTAVL1_LO equ 0		; Most VCPI clients fill the GDT with this
@GDTAVL1_HI equ 0

@GDTAVL2_LO equ 0		; Helix's cloaking VCPI client uses this
@GDTAVL2_HI equ 00D09200h

	sub	edx,size DESC_STR ; Skip back to the previous GDT entry

	cmp	AGROUP:[ebx+edx].EDQLO,@GDTAVL1_LO ; Izit available?
	jne	short @F	; Not this one

	cmp	AGROUP:[ebx+edx].EDQHI,@GDTAVL1_HI ; Izit available?
	je	short GDTAVAIL_EXIT ; Jump if so (note ZF=1)
@@:
	cmp	AGROUP:[ebx+edx].EDQLO,@GDTAVL2_LO ; Izit available?
	jne	short @F	; Not this one

	cmp	AGROUP:[ebx+edx].EDQHI,@GDTAVL2_HI ; Izit available?
;;;;;;; je	short GDTAVAIL_EXIT ; Jump if so (note ZF=1)
@@:
GDTAVAIL_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GDTAVAIL endp			; End GDTAVAIL procedure
	NPPROC	SET_GDT -- Set GDT Entry
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set GDT entry

On entry:

GS:ESI	==>	GDT entry save area
EAX	=	32-bit linear address
ECX	=	limit

|

	REGSAVE <ecx>		; Save register

	cmp	ecx,CON1MB	; Check against limit limit
	jb	short @F	; Jump if within range

	shr	ecx,12-0	; Convert from bytes to 4KB
	or	ecx,(mask $DTE_G) shl 16 ; Set G-bit
@@:
	mov	gs:[esi].DESC_BASE01.EDD,eax
	rol	eax,8		; Rotate out the high-order byte
	mov	gs:[esi].DESC_BASE3,al ; Save as base byte #3
	ror	eax,8		; Rotate back
	mov	gs:[esi].DESC_SEGLM0,cx ; Save as data limit
	rol	ecx,16		; Swap high- and low-order words
	mov	gs:[esi].DESC_SEGLM1,cl ; Save as data limit

	REGREST <ecx>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_GDT endp			; End SET_GDT procedure
	NPPROC	SET_COMMON -- Setup Common Data Area
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup common data area

|

	REGSAVE <eax,edi,es>	; Save for a moment

	cld			; String ops forwardly

	SETDATA es		; Set data selector into ES
	assume	es:DGROUP	; Tell the assembler about it

	inc	TSS_CNT 	; Mark as using TSSs

	call	SetPMT		; Set PM TSS mode

; We can be called other than in a VCPI context in which case
; our local LDT hasn't been setup (so we shouldn't swap selectors)

	mov	di,cs		; Copy current code selector
	add	di,VCP_LDT-VCP_CODE ; Skip to our LDT offset
	sldt	ax		; Get current LDTR

	cmp	ax,di		; Izit the same?
	jne	short SET_COMMON_EXIT ; Jump if not

	inc	SAVCNT		; Count in another one

	mov	edi,SAVNEXT	; ES:EDI ==> next save area

	mov	ax,LDT_4GB	; AX = 4GB selector
	xchg	ax,COMMON.FILE_4GB ; Save in common area
S32	stos	SAVSTK[edi]	; Save to restore later

	mov	ax,LDT_CR3	; AX = CR3 selector
	xchg	ax,COMMON.FILE_CR3 ; Save in common area
S32	stos	SAVSTK[edi]	; Save to restore later

	mov	SAVNEXT,edi	; Save for next time
SET_COMMON_EXIT:
	REGREST <es,edi,eax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_COMMON endp 		; End SET_COMMON procedure
	NPPROC	RESET_COMMON -- Resetup Common Data Area
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup common data area

|

	REGSAVE <eax,esi,es>	; Save for a moment

	cld			; String ops forwardly

	SETDATA es		; Set data selector into DS
	assume	es:DGROUP	; Tell the assembler about it

; We can be called other than in a VCPI context in which case
; our local LDT hasn't been setup (so we shouldn't swap selectors)

	mov	si,cs		; Copy current code selector
	add	si,VCP_LDT-VCP_CODE ; Skip to our LDT offset
	sldt	ax		; Get current LDTR

	cmp	ax,si		; Izit the same?
	jne	short RESET_COMMON_EXIT ; Jump if not

	push	ds		; Save for a moment

	mov	ds,COMMON.FILE_4GB ; Get our all memory selector
	assume	ds:AGROUP	; Tell the assembler about it

	call	SET_NEWCR3	; Set CR3 into back link TSS

	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	dec	SAVCNT		; Count out another one

	mov	esi,SAVNEXT	; DS:ESI ==> next save area
	sub	esi,@SAVCNT*(type SAVSTK) ; Back off to start
	mov	SAVNEXT,esi	; Save for next time

	lods	SAVSTK[esi]	; Get previous value
	mov	COMMON.FILE_4GB,ax ; Save in common area

	lods	SAVSTK[esi]	; Get previous value
	mov	COMMON.FILE_CR3,ax ; Save in common area
RESET_COMMON_EXIT:
	dec	TSS_CNT 	; Mark as no longer using TSSs

	REGREST <es,esi,eax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESET_COMMON endp		; End RESET_COMMON procedure
	NPPROC	SET_NEWCR3 -- Set CR3 Into Back Link TSS
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set CR3 into back link TSS

In case the TSS to which we're returning is new to us
(as is the case with QDPMI.SYS running a DPMI client),
we need to ensure that the client's CR3 is saved into
the back link TSS.

|

	REGSAVE <eax,ebx>	; Save registers

	str	ax		; Get the current Task Register

	push	eax		; Pass TSS selector (as dword for alignment)
	call	SEL2BASE_DS	; Return with EAX == selector base address

	cmp	AGROUP:[eax].TSS_LINK,0 ; Izit invalid?
	je	short @F	; Jump if so

	push	AGROUP:[eax].TSS_LINK.EDD ; Get back link TSS (as dword for alignment)
	call	SEL2BASE_DS	; Return with EAX == selector base address

	test	AGROUP:[eax].TSS_CR3,@PTE_FRM ; Izit valid?
	jnz	short @F	; Jump if so

	mov	ebx,NEW_CR3	; Get incoming CR3
	mov	AGROUP:[eax].TSS_CR3,ebx ; Save it for later use
@@:
	REGREST <ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_NEWCR3 endp 		; End SET_NEWCR3 procedure
	FPPROC	TSS_INT00 -- VCPI TSS Divide Overflow Interrupt Handler
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI Divide Overflow interrupt handler

|

	lea	esi,LCLTSS00	; DGROUP:ESI ==> local TSS structure

	jmp	short TSS_INT00COM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_INT00 endp			; End TSS_INT00 procedure
	FPPROC	TSS_INT00COM -- VCPI TSS Divide Overflow Interrupt Handler
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI Divide Overflow interrupt handler

On entry:

DGROUP:ESI ==>	 LCLTSSxx

|

TSS_INT00_START:
	call	SET_COMMON	; Setup common data area

; Send message to SWAT

	PUSHD	0		; Pass pseudo-error code
	PUSHD	cs		; Segment of error message
	push	DGROUP:[esi].PMSG_Ixx.EDD ; Offset of ...
	FCALLD	SAVEMSG 	; Call message save routine

; Setup stack and registers from caller's TSS

	call	TSS_ENTER	; Setup stack for SWAT
				; Return with registers on stack
	FCALLD	SWATTER 	; Call our debugger
;;;;;;; jnc	short ???	; Continue debugging

; Save registers in caller's TSS

	call	TSS_LEAVE	; Call common TSS return code
				; Return with CF = 0 if 386 TSS,
				; ...		 = 1 if 286 ...
	pushfd			; Save CF over call
	call	RESET_COMMON	; Resetup common data area
	popfd			; Restore
	jc	short TSS_INT00_IRET ; Jump if 286 TSS

	iretd			; Return to caller

	jmp	TSS_INT00_START ; Go around again

TSS_INT00_IRET:
	iret			; Return to caller

	jmp	TSS_INT00_START ; Go around again

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_INT00COM endp		; End TSS_INT00COM procedure
	FPPROC	TSS_INT01 -- VCPI TSS Single-Step Interrupt Handler
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI single-step interrupt handler

|

	lea	esi,LCLTSS01	; DGROUP:ESI ==> local TSS structure

	jmp	short TSS_INT01COM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_INT01 endp			; End TSS_INT01 procedure
	FPPROC	TSS_INT01COM -- VCPI TSS Single-Step Interrupt Handler
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI single-step interrupt handler

On entry:

DGROUP:ESI ==>	 LCLTSSxx

|

TSS_INT01_START:
	call	SET_COMMON	; Setup common data area

; Push current INT 01h handler and install

IDT	equ	<AGROUP:[ebx+01h*(type IDT_STR)]>

	sub	esp,size DTR_STR ; Make room on stack
	SIDTD	[esp].EDF	; Save IDTR on stack
	mov	ebx,[esp].DTR_BASE ; AGROUP:EBX ==> IDT
	add	esp,size DTR_STR ; Strip from the stack

	push	IDT.EDQHI	; Save on stack
	push	IDT.EDQLO	; ...
	mov	ORG_GDINT01_OFF,esp ; Save as offset in DGROUP of orig IDT entry

	mov	eax,IDT_GDINT01.EDQHI ; Get replacement
	mov	IDT.EDQHI,eax	; Save in IDT
	mov	eax,IDT_GDINT01.EDQLO ; Get replacement
	mov	IDT.EDQLO,eax	; Save in IDT

; Setup stack and registers from caller's TSS

	call	TSS_ENTER	; Setup stack for SWAT
				; Return with registers on stack
	FCALLD	SWATTER 	; Call our debugger
;;;;;;; jnc	short ???	; Continue debugging

; Save registers in caller's TSS

	call	TSS_LEAVE	; Call common TSS return code
				; Return with CF = 0 if 386 TSS,
				; ...		 = 1 if 286 ...
	sub	esp,size DTR_STR ; Make room on stack
	SIDTD	[esp].EDF	; Save IDTR on stack
	mov	ebx,[esp].DTR_BASE ; AGROUP:EBX ==> IDT
	add	esp,size DTR_STR ; Strip from the stack

	mov	ORG_GDINT01_OFF,-1 ; Mark as invalid
	pop	IDT.EDQLO	; Restore
	pop	IDT.EDQHI	; ...

	pushfd			; Save CF over call
	call	RESET_COMMON	; Resetup common data area
	popfd			; Restore
	jc	short TSS_INT01_IRET ; Jump if 286 TSS

	iretd			; Return to caller

	jmp	TSS_INT01_START ; Go around again

TSS_INT01_IRET:
	iret			; Return to caller

	jmp	TSS_INT01_START ; Go around again

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_INT01COM endp		; End TSS_INT01COM procedure
	FPPROC	TSS_INT02 -- VCPI TSS NMI Interrupt Handler
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI NMI interrupt handler

|

	lea	esi,LCLTSS02	; DGROUP:ESI ==> local TSS structure

	jmp	short TSS_INT02COM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_INT02 endp			; End TSS_INT02 procedure
	FPPROC	TSS_INT02COM -- VCPI TSS NMI Interrupt Handler
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI NMI interrupt handler

On entry:

DGROUP:ESI ==>	 LCLTSSxx

|

TSS_INT02_START:

; Install our debouncing NMI handler into the IDT

	call	SWAP_NMI	; Swap NMI handlers

	call	DISABLE_NMI	; Disable NMI until the end
;;;;;;; jc	short TSS_INT02_EXIT ; Jump if NMI handler already active

	call	SET_COMMON	; Setup common data area

; Send message to SWAT

	PUSHD	0		; Pass pseudo-error code
	PUSHD	cs		; Segment of error message
	push	DGROUP:[esi].PMSG_Ixx.EDD ; Offset of ...
	FCALLD	SAVEMSG 	; Call message save routine

; Setup stack and registers from caller's TSS

	call	TSS_ENTER	; Setup stack for SWAT
				; Return with registers on stack
	FCALLD	SWATTER 	; Call our debugger
;;;;;;; jnc	short ???	; Continue debugging

; Save registers in caller's TSS

	call	TSS_LEAVE	; Call common TSS return code
				; Return with CF = 0 if 386 TSS,
				; ...		 = 1 if 286 ...
	cli			; Disallow interrupts
;;;;;;; pushfd			; Save CF over call
	call	ENABLE_NMI	; Enable NMI, clear the parity latches
	call	RESET_COMMON	; Resetup common data area
;;;;;;; popfd			; Restore
;;;;;;; jc	short TSS_INT02_IRET ; Jump if 286 TSS

;;;TSS_INT02_EXIT:
	mov	eax,DGROUP:[esi].PTSS_Ixx ; DGROUP:EAX ==> TSSxx

; Get address of caller's TSS

	push	DGROUP:[eax].TSS_LINK ; Pass caller's TSS selector
	call	IZIT286 	; Izit a 286 TSS?
	jc	short TSS_INT02_IRET ; Jump if so

	call	SWAP_NMI	; Swap NMI handlers

	iretd			; Return to caller

	jmp	TSS_INT02_START ; Go around again

TSS_INT02_IRET:
	call	SWAP_NMI	; Swap NMI handlers

	iret			; Return to caller

	jmp	TSS_INT02_START ; Go around again

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_INT02COM endp		; End TSS_INT02COM procedure
	NPPROC	SWAP_NMI -- Swap NMI Handlers
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Swap NMI handlers

|

	REGSAVE <eax,ebx>	; Save registers

; Establish addressibility to IDT

IDT	equ	<AGROUP:[ebx+02h*(type IDT_STR)]>

	sub	esp,size DTR_STR ; Make room on stack
	SIDTD	[esp].EDF	; Save IDTR on stack
	mov	ebx,[esp].DTR_BASE ; AGROUP:EBX ==> IDT
	add	esp,size DTR_STR ; Strip from the stack

; Swap our debouncing INT 02h TSS with the current one

	mov	eax,DEBOUNCE_FVEC.FOFF ; Get our offset
	xchg	ax,IDT.IDT_OFFLO ; Swap with IDT
	mov	DEBOUNCE_FVEC.FOFF.ELO,ax ; Save to restore later
	shr	eax,16		; Shift to low-order
	xchg	ax,IDT.IDT_OFFHI ; Swap with IDT
	mov	DEBOUNCE_FVEC.FOFF.EHI,ax ; Save to restore later

	mov	ax,DEBOUNCE_FVEC.FSEL ; Get our selector
	xchg	ax,IDT.IDT_SELECT ; Swap with IDT
	mov	DEBOUNCE_FVEC.FSEL,ax ; Save to restore later

	mov	al,DEBOUNCE_ARB ; Get our access rights byte
	xchg	al,IDT.IDT_ACCESS ; Swap with IDT
	mov	DEBOUNCE_ARB,al ; Save to restore later

	xor	NMI_FLAG,@NMI_SWAP ; Complement the bit

	REGREST <ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SWAP_NMI endp			; End SWAP_NMI procedure
	NPPROC	SWAP_NMI_FLAG -- Swap NMI Handlers And Complement Flag
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Swap NMI handlers if swapped

|

	REGSAVE <ds,es> 	; Save registers

	SETDATA es		; Set data selector into DS
	assume	es:DGROUP	; Tell the assembler about it

	test	NMI_FLAG,@NMI_SWAP ; Is NMI swapped?
	jz	short SWAP_NMI_FLAG_EXIT ; Jump if not

	mov	ds,COMMON.FILE_4GB ; Address all of memory
	assume	ds:AGROUP	; Tell the assembler about it

	call	SWAP_NMI	; Swap NMI handlers

	or	NMI_FLAG,@NMI_SWAP ; Restore
SWAP_NMI_FLAG_EXIT:
	REGREST <es,ds> 	; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SWAP_NMI_FLAG endp		; End SWAP_NMI_FLAG procedure
	FPPROC	DEBOUNCE -- Debouncing NMI Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debouncing NMI handler

|

	iretd			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEBOUNCE endp			; End DEBOUNCE procedure
	FPPROC	TSS_INT03 -- VCPI TSS Breakpoint Interrupt Handler
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI breakpoint interrupt handler

|

	lea	esi,LCLTSS03	; DGROUP:ESI ==> local TSS structure

	jmp	short TSS_INT03COM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_INT03 endp			; End TSS_INT03 procedure
	FPPROC	TSS_INT03COM -- VCPI TSS Breakpoint Interrupt Handler
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI breakpoint interrupt handler

On entry:

DGROUP:ESI ==>	 LCLTSSxx

|

TSS_INT03_START:
	call	SET_COMMON	; Setup common data area

; Setup stack and registers from caller's TSS

	call	TSS_ENTER	; Setup stack for SWAT
				; Return with registers on stack
	dec	[esp].EDD	; Back off EIP on stack to the INT 03h

	FCALLD	SWATTER 	; Call our debugger
;;;;;;; jnc	short ???	; Continue debugging

; Save registers in caller's TSS

	call	TSS_LEAVE	; Call common TSS return code
				; Return with CF = 0 if 386 TSS,
				; ...		 = 1 if 286 ...
	pushfd			; Save CF over call
	call	RESET_COMMON	; Resetup common data area
	popfd			; Restore
	jc	short TSS_INT03_IRET ; Jump if 286 TSS

	iretd			; Return to caller

	jmp	TSS_INT03_START ; Go around again

TSS_INT03_IRET:
	iret			; Return to caller

	jmp	TSS_INT03_START ; Go around again

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_INT03COM endp		; End TSS_INT03COM procedure
	FPPROC	TSS_INT05 -- VCPI Bound Interrupt Handler
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI bound interrupt handler

|

	lea	esi,LCLTSS05	; DGROUP:ESI ==> local TSS structure

	jmp	short TSS_INT05COM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_INT05 endp			; End TSS_INT05 procedure
	FPPROC	TSS_INT05COM -- VCPI Bound Interrupt Handler
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI bound interrupt handler

On entry:

DGROUP:ESI ==>	 LCLTSSxx

|

TSS_INT05_START:
	call	SET_COMMON	; Setup common data area

; Send message to SWAT

	PUSHD	0		; Pass pseudo-error code
	PUSHD	cs		; Segment of error message
	push	DGROUP:[esi].PMSG_Ixx.EDD ; Offset of ...
	FCALLD	SAVEMSG 	; Call message save routine

; Setup stack and registers from caller's TSS

	call	TSS_ENTER	; Setup stack for SWAT
				; Return with registers on stack
	FCALLD	SWATTER 	; Call our debugger
;;;;;;; jnc	short ???	; Continue debugging

; Save registers in caller's TSS

	call	TSS_LEAVE	; Call common TSS return code
				; Return with CF = 0 if 386 TSS,
				; ...		 = 1 if 286 ...
	pushfd			; Save CF over call
	call	RESET_COMMON	; Resetup common data area
	popfd			; Restore
	jc	short TSS_INT05_IRET ; Jump if 286 TSS

	iretd			; Return to caller

	jmp	TSS_INT05_START ; Go around again

TSS_INT05_IRET:
	iret			; Return to caller

	jmp	TSS_INT05_START ; Go around again

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_INT05COM endp		; End TSS_INT05COM procedure
	FPPROC	TSS_INT06 -- VCPI TSS Invalid Opcode Interrupt Handler
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI Invalid Opcode interrupt handler

|

	lea	esi,LCLTSS06	; DGROUP:ESI ==> local TSS structure

	jmp	short TSS_INT06COM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_INT06 endp			; End TSS_INT06 procedure
	FPPROC	TSS_INT06COM -- VCPI TSS Invalid Opcode Interrupt Handler
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI Invalid Opcode interrupt handler

On entry:

DGROUP:ESI ==>	 LCLTSSxx

|

TSS_INT06_START:
	call	SET_COMMON	; Setup common data area

; Send message to SWAT

	PUSHD	0		; Pass pseudo-error code
	PUSHD	cs		; Segment of error message
	push	DGROUP:[esi].PMSG_Ixx.EDD ; Offset of ...
	FCALLD	SAVEMSG 	; Call message save routine

; Setup stack and registers from caller's TSS

	call	TSS_ENTER	; Setup stack for SWAT
				; Return with registers on stack
	FCALLD	SWATTER 	; Call our debugger
;;;;;;; jnc	short ???	; Continue debugging

; Save registers in caller's TSS

	call	TSS_LEAVE	; Call common TSS return code
				; Return with CF = 0 if 386 TSS,
				; ...		 = 1 if 286 ...
	pushfd			; Save CF over call
	call	RESET_COMMON	; Resetup common data area
	popfd			; Restore
	jc	short TSS_INT06_IRET ; Jump if 286 TSS

	iretd			; Return to caller

	jmp	TSS_INT06_START ; Go around again

TSS_INT06_IRET:
	iret			; Return to caller

	jmp	TSS_INT06_START ; Go around again

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_INT06COM endp		; End TSS_INT06COM procedure
	FPPROC	LCL_INT07 -- Local INT 07h Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local INT 07h handler

|

; Note that in a USE32 segment, the SMSW AX actually stores into EAX
; so we have to save EAX, not AX.

	push	eax		; Save for a moment

	smsw	ax		; Get the machine status word

	test	ax,mask $TS	; Check TS bit
	pop	eax		; Restore
	jz	short @F	; Jump if it was already clear

	clts			; Clear TS bit in MSW

	iretd			; Re-execute the instruction

@@:

I07_STR struc

	dd	?		; Return offset
	dw	?		; ...	 selector
I07_DS	dw	?		; Caller's DS

I07_STR ends

	PUSHW	ds		; Save to address DGROUP

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	push	OLDTSSINT07_FVEC.FSEL ; Save selector in low-order word
	push	OLDTSSINT07_FVEC.FOFF ; ...  offset in next dword

	mov	ds,[esp].I07_DS ; Restore caller's DS
	assume	ds:nothing	; Tell the assembler about it

	RETFD			; Continue with original handler

	jmp	short LCL_INT07 ; Go around again

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT07 endp			; End LCL_INT07 procedure
	FPPROC	TSS_INT0A -- VCPI TSS Invalid TSS Fault Handler
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI invalid TSS fault handler

|

	lea	esi,LCLTSS0A	; DGROUP:ESI ==> local TSS structure

	jmp	short TSS_INTCOM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_INT0A endp			; End TSS_INT0A procedure
	FPPROC	TSS_INT0B -- VCPI TSS Segment Not Present Fault Handler
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI segment not present fault handler

|

	lea	esi,LCLTSS0B	; DGROUP:ESI ==> local TSS structure

	jmp	short TSS_INTCOM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_INT0B endp			; End TSS_INT0B procedure
	FPPROC	TSS_INT0C -- VCPI TSS Stack Fault Handler
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI stack fault handler

|

	lea	esi,LCLTSS0C	; DGROUP:ESI ==> local TSS structure

	jmp	short TSS_INTCOM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_INT0C endp			; End TSS_INT0C procedure
	FPPROC	TSS_INT0D -- VCPI TSS GP Fault Handler
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI GP fault handler

|

	lea	esi,LCLTSS0D	; DGROUP:ESI ==> local TSS structure

	jmp	short TSS_INTCOM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_INT0D endp			; End TSS_INT0D procedure
	FPPROC	TSS_INT0E -- VCPI TSS Page Fault Handler
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI page fault handler

|

	lea	esi,LCLTSS0E	; DGROUP:ESI ==> local TSS structure

	jmp	short TSS_INTCOM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_INT0E endp			; End TSS_INT0E procedure
	NPPROC	TSS_INTCOM -- TSS Fault/Interrupt Common Routine
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI TSS fault/interrupt common routine

On entry:

DGROUP:ESI ==>	 LCLTSSxx

|

; Distinguish Fault from IRQn event

	cmp	esp,DGROUP:[esi].PSTK_IxxZ ; Check for error code
	jne	near ptr TSS_INTCOM_FAULT ; Jump if error code present

; Continue on with next handler in sequence

TSS_INTCOM_NEXT:
	mov	cl,DGROUP:[esi].OLDINTxx_ARB ; Get next handler's ARB
	and	cl,(mask $DT_P) or (mask $DT_TYP) ; Isolate present & type bits

	cmp	cl,CPL0_TASK	; Izit a task gate?
	jne	short TSS_INTCOM_XTASK ; Not this time

	jmp	DGROUP:[esi].OLDINTxx_FWD ; Continue with next handler in sequence

	jmp	TSS_INTCOM	; Go around again in case of task switch


; Continue with non-task gate handler

TSS_INTCOM_XTASK:
	mov	ebx,DGROUP:[esi].PTSS_Ixx ; DGROUP:EBX ==> TSSxx

; Get address of caller's TSS

	push	DGROUP:[ebx].TSS_LINK.EDD ; Pass caller's TSS selector (as dword for alignment)
	call	SEL2BASE_DS	; Return with EAX == selector base address

	lldt	AGROUP:[eax].TSS_LDT ; Install caller's LDT in case
				; the caller's SS is in it

; Note that we are depending upon descriptor caching of DS here
; because it's in our LDT

	mov	edx,eax 	; Save linear address of back link TSS

; If there's a ring transition, use the back link SS0|ESP0
; if not, use the back link SS|ESP.

	mov	ax,AGROUP:[edx].TSS_SS0 ; Get back link TSS PL0 SS
	mov	edi,AGROUP:[edx].TSS_ESP0 ; Get its ESP0

	push	eax		; Pass the selector (as dword)
	call	CheckBbit	; Check on this selector's B-bit
	jc	short @F	; Jump if its B-bit is set

	movzx	edi,di		; Clear the high-order word
@@:
	test	AGROUP:[edx].TSS_EFL.EHI,mask $VM ; Izit from VM?
	jnz	short @F	; Jump if so (mode transition)

	test	AGROUP:[edx].TSS_CS,mask $PL ; Izit PL0?
	jnz	short @F	; Jump if not (ring transition)

	mov	ax,AGROUP:[edx].TSS_SS ; Get back link TSS SS
	mov	edi,AGROUP:[edx].TSS_ESP ; Get its ESP
@@:
	push	eax		; Pass back link TSS SS
	call	SEL2BASE_DS	; Return with EAX == selector base address

	xchg	eax,edx 	; EAX = linear address of back link TSS
				; EDX = linear address of caller's SS

	test	cl,mask $DS_386 ; Izit a 386 interrupt/trap gate?
	jnz	short TSS_INTCOM_XTASK1 ; Yes, use dword PUSHes

; It's a 286 interrupt/trap gate, use word PUSHes

; If there's a ring transition, push the caller's SS|ESP

RING_STR struc

RING_SP dw	?		; SP
RING_SS dw	?		; SS

RING_STR ends

	test	AGROUP:[eax].TSS_CS,mask $PL ; Izit PL0?
	jz	short @F	; Jump if so

	sub	edi,type RING_STR ; Make room for SS|SP

	push	AGROUP:[eax].TSS_SS	  ; Get caller's SS
	pop	AGROUP:[edx+edi].RING_SS ; Save on back link TSS stack

	push	AGROUP:[eax].TSS_ESP.ELO ; ...	 SP
	pop	AGROUP:[edx+edi].RING_SP ; ...
@@:
	sub	edi,type IRET_STR ; Make room for IRET frame

	push	AGROUP:[eax].TSS_EFL.ELO ; Get caller's FL
	pop	AGROUP:[edx+edi].IRET_FL ; Save on back link TSS stack

	push	AGROUP:[eax].TSS_CS	  ; ... 	 CS
	pop	AGROUP:[edx+edi].IRET_CS ; ...

	push	AGROUP:[eax].TSS_EIP.ELO ; ...	 IP
	pop	AGROUP:[edx+edi].IRET_IP ; ...

	cmp	esp,DGROUP:[esi].PSTK_IxxZ ; Check for error code
	je	short @F	; Jump if no error code

	sub	edi,2		; Make room for error code

	push	[esp].ELO	; Get error code
	pop	AGROUP:[edx+edi].ELO ; Save on back link TSS stack
@@:
	jmp	TSS_INTCOM_XTASK2 ; Join common code


; It's a 386 interrupt/trap gate, use dword PUSHes

TSS_INTCOM_XTASK1:

; If there's a ring transition, push the caller's SS|ESP

RINGD_STR struc

RINGD_ESP dd	?		; ESP
RINGD_SS  dw	?,?		; SS w/filler

RINGD_STR ends

	test	AGROUP:[eax].TSS_EFL.EHI,mask $VM ; Izit from VM?
	jz	short TSS_INTCOM_PM1 ; Jump if not

	sub	edi,type VMINT_STR ; Make room for VM interrupt structure

	push	AGROUP:[eax].TSS_DS	    ; Get caller's DS
	pop	AGROUP:[edx+edi].VMINT_DS  ; Save on back link TSS

	push	AGROUP:[eax].TSS_ES	    ; Get caller's ES
	pop	AGROUP:[edx+edi].VMINT_ES  ; ...

	push	AGROUP:[eax].TSS_FS	    ; Get caller's FS
	pop	AGROUP:[edx+edi].VMINT_FS  ; ...

	push	AGROUP:[eax].TSS_GS	    ; Get caller's GS
	pop	AGROUP:[edx+edi].VMINT_GS  ; ...

	push	AGROUP:[eax].TSS_SS	    ; ...	   SS
	pop	AGROUP:[edx+edi].VMINT_SS  ; ...

	push	AGROUP:[eax].TSS_ESP	    ; ...	   ESP
	pop	AGROUP:[edx+edi].VMINT_ESP ; ...

	jmp	short TSS_INTCOM_VM2 ; Join common code

TSS_INTCOM_PM1:
	test	AGROUP:[eax].TSS_CS,mask $PL ; Izit PL0?
	jz	short @F	; Jump if so

	sub	edi,type RINGD_STR ; Make room for SS|ESP

	push	AGROUP:[eax].TSS_SS	    ; Get caller's SS
	pop	AGROUP:[edx+edi].RINGD_SS  ; Save on back link TSS stack

	push	AGROUP:[eax].TSS_ESP	    ; ...	   ESP
	pop	AGROUP:[edx+edi].RINGD_ESP ; ...
@@:
	sub	edi,type IRETD_STR ; Make room for IRETD frame
TSS_INTCOM_VM2:
	push	AGROUP:[eax].TSS_EFL	    ; Get caller's EFL
	pop	AGROUP:[edx+edi].IRETD_EFL ; Save on back link TSS stack

	push	AGROUP:[eax].TSS_CS	    ; ...	   CS
	pop	AGROUP:[edx+edi].IRETD_CS  ; ...

	push	AGROUP:[eax].TSS_EIP	    ; ...	   EIP
	pop	AGROUP:[edx+edi].IRETD_EIP ; ...

	cmp	esp,DGROUP:[esi].PSTK_IxxZ ; Check for error code
	je	short @F	; Jump if no error code

	sub	edi,4		; Make room for error code

	push	[esp].EDD	; Get error code
	pop	AGROUP:[edx+edi].EDD ; Save on back link TSS stack
@@:
TSS_INTCOM_XTASK2:
	lldt	DGROUP:[ebx].TSS_LDT ; Set our LDT into place

	and	AGROUP:[eax].TSS_EFL,not (mask $NT) ; Clear the NT bit in the TSS

	test	cl,mask $DS_TASK ; Izit a 286/386 trap gate?
	jnz	short @F	; Yes, leave IF alone

	and	AGROUP:[eax].TSS_EFL,not (mask $IF) ; Clear the IF bit in the TSS
@@:
	call	SET_NEWCR3	; Set CR3 into back link TSS

; Switch to the back link TSS stack
; if there's a ring transition, use TSS_SS0, otherwise use TSS_SS

	mov	cx,AGROUP:[eax].TSS_SS0 ; Get the selector

	test	AGROUP:[eax].TSS_EFL.EHI,mask $VM ; Izit from VM?
	jnz	short @F	; Jump if so (mode transition)

	test	AGROUP:[eax].TSS_CS,mask $PL ; Izit PL0?
	jnz	short @F	; Jump if not (ring transition)

	mov	cx,AGROUP:[eax].TSS_SS ; Get the selector
@@:
	mov	ss,cx		; Set the selector
	assume	ss:nothing	; Tell the assembler about it
	mov	esp,edi 	; Get the offset

; Save next handler's address

	push	AGROUP:[eax].TSS_EFL		   ; Pass flags
	and	[esp].EDD,not ((mask $VMHI) or (mask $TF)) ; VM=TF=0
	push	DGROUP:[esi].OLDINTxx_FWD.FSEL.EDD ; Pass selector
	push	DGROUP:[esi].OLDINTxx_FWD.FOFF	   ; ...  offset

; Put caller's selectors into effect
; unless we came from VM

	test	AGROUP:[eax].TSS_EFL.EHI,mask $VM ; Izit from VM?
	jz	short @F	; Jump if not

	PUSHD	0		; DS (the default value upon entry)
	PUSHD	0		; ES
	PUSHD	0		; FS
	PUSHD	0		; GS

	jmp	short TSS_INTCOM_VM3 ; Join common code

@@:
	push	AGROUP:[eax].TSS_DS.EDD ; Save DS for last
	push	AGROUP:[eax].TSS_ES.EDD ; ...	ES
	push	AGROUP:[eax].TSS_FS.EDD ; ...	FS
	push	AGROUP:[eax].TSS_GS.EDD ; ...	GS
TSS_INTCOM_VM3:

; Put caller's EGP registers into effect

	push	AGROUP:[eax].TSS_EAX ; Save EAX for last
	push	AGROUP:[eax].TSS_EBX ; ...  EBX

	mov	ebp,AGROUP:[eax].TSS_EBP ; Restore EBP
	mov	edi,AGROUP:[eax].TSS_EDI ; ...	   EDI
	mov	esi,AGROUP:[eax].TSS_ESI ; ...	   ESI
	mov	edx,AGROUP:[eax].TSS_EDX ; ...	   EDX
	mov	ecx,AGROUP:[eax].TSS_ECX ; ...	   ECX

; De-link the current TSS

	push	ebx		; Save for a moment

	movzx	ebx,DGROUP:[ebx].TSS_LINK ; Get caller's TSS selector

	and	ebx,ebx 	; Izit invalid?
	jz	short @F	; Jump if so

	call	SEL2GDT 	; Convert selector in EBX to GDT address in EBX

	and	AGROUP:[ebx].DESC_ACCESS,not (mask $DS_BUSY) ; Clear the busy bit

	xor	ebx,ebx 	; Zero to use as dword
	str	bx		; Get the current Task Register
	call	SEL2GDT 	; Convert selector in EBX to GDT address in EBX

	and	AGROUP:[ebx].DESC_ACCESS,not (mask $DS_BUSY) ; Clear the busy bit
@@:
	pop	ebx		; Restore

	mov	bx,DGROUP:[ebx].TSS_LINK ; Get Task Register

	and	bx,bx		; Izit invalid?
	jz	short @F	; Jump if so

	ltr	bx		; Set Task Register
@@:
	lldt	AGROUP:[eax].TSS_LDT ; Install caller's LDT

	REGREST <ebx,eax>	; Restore

	REGREST <gs,fs,es,ds>	; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it
	assume	fs:nothing,gs:nothing ; Tell the assembler about it

; Clear NT if set

	pushfd			; Get FL
	and	[esp].ELO,not (mask $NT) ; NT=0
	popfd			; Put into effect

	iretd			; Continue with next handler in sequence


; It's a fault

	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
TSS_INTCOM_FAULT:

; If it's a GP Fault, handle it specially

	cmp	esi,offset DGROUP:LCLTSS0D ; Izit GP Fault?
	jne	short @F	; Jump if not

	call	CHECK_GPFAULT	; Check for special GP Fault handling
	jc	near ptr TSS_INTCOM_NEXT ; Jump if continuing on
@@:
	call	SET_COMMON	; Setup common data area

; Send message to SWAT

;;;;;;; push	eax		; Pass error code (already on the stack)
	PUSHD	cs		; Segment of error message
	push	DGROUP:[esi].PMSG_Ixx.EDD ; Offset of ...
	FCALLD	SAVEMSG 	; Call message save routine

; Get address of caller's TSS

	call	TSS_ENTER	; Setup stack for SWAT
				; Return with registers on stack
	FCALLD	SWATTER 	; Call our debugger
;;;;;;; jnc	short ???	; Continue debugging

; Save registers in caller's TSS

	call	TSS_LEAVE	; Call common TSS return code
				; Return with CF = 0 if 386 TSS,
				; ...		 = 1 if 286 ...
	pushfd			; Save CF over call
	call	RESET_COMMON	; Resetup common data area
	popfd			; Restore
	jc	short TSS_INTCOM_IRET ; Jump if 286 TSS
TSS_INTCOM_IRETD:
	iretd			; Return to caller

	jmp	TSS_INTCOM	; Go around again

TSS_INTCOM_IRET:
	iret			; Return to caller

	jmp	TSS_INTCOM	; Go around again

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_INTCOM endp 		; End TSS_INTCOM procedure
	NPPROC	CheckBbit -- Check On Selector B-bit
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on a selector's B-bit

On exit:

CF	=	0 if the B-bit is clear
	=	1 ...		  set

|

CBB_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
CBB_SEL dw	?,?		; Selector (w/filler)

CBB_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ebx>		; Save register

	movzx	ebx,[ebp].CBB_SEL ; Get the selector
	call	SEL2GDT 	; Convert selector in EBX to GDT address in EBX

	test	AGROUP:[ebx].DESC_SEGLM1,mask $DTE_B ; Izit set?
	jz	short @F	; Jump if not (note CF=0)

	stc			; Mark as B-bit set
@@:
	REGREST <ebx>		; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CheckBbit endp			; End CheckBbit procedure
	NPPROC	CHECK_GPFAULT -- Check For Special GP Fault Handling
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on special GP Fault handling

On entry:

DGROUP:ESI ==>	 LCLTSSxx

On exit:

CF	=	0 if nothing special
	=	1 if continuing on to next handler in sequence

Selector registers FS and GS and all EGP registers
except ESP and ESI may be clobbered.

|

; Check for instructions we should skip

	cmp	GPS_FLAG,0	; Anything to do?
	je	short CHECK_GPFAULT_XGPS ; Jump if not

	mov	ebx,DGROUP:[esi].PTSS_Ixx ; DGROUP:EBX ==> TSSxx

; Get address of caller's TSS

	push	DGROUP:[ebx].TSS_LINK.EDD ; Get caller's TSS selector (as dword for alignment)
	call	SEL2BASE_DS	; Return with EAX == selector base address

	sldt	cx		; Save current LDTR

	lldt	AGROUP:[eax].TSS_LDT ; Install caller's LDT in case
				; the caller's SS is in it

; Note that we are depending upon descriptor caching of DS here

	mov	ebx,AGROUP:[eax].TSS_EIP ; Get caller's EIP

	test	AGROUP:[eax].TSS_EFL.EHI,mask $VM ; Izit from VM?
	movzx	eax,AGROUP:[eax].TSS_CS ; Get caller's CS
	jz	short CHECK_GPFAULT_PM ; Jump if not

	shl	eax,4-0 	; Convert from paras to bytes

	jmp	short CHECK_GPFAULT_COM ; Join common code


CHECK_GPFAULT_PM:
	push	eax		; Pass caller's CS (as dword for alignment)
	call	SEL2BASE_DS	; Return with EAX == selector base address
CHECK_GPFAULT_COM:
	lldt	cx		; Set our LDT into place

	add	eax,ebx 	; Add to to get linear address

	call	CHECK_GPS	; Check on GP Skip at EAX
	jc	short CHECK_GPFAULT_EXIT ; Jump if we're to skip it (note CF=1)
CHECK_GPFAULT_XGPS:
	clc			; Indicate nothing special
CHECK_GPFAULT_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_GPFAULT endp		; End CHECK_GPFAULT procedure
	NPPROC	CHECK_GPS -- Check On GP Skips
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on GP Skips

On entry:

EAX	==>	Linear address of the GP Fault instruction

On exit:

CF	=	1 if we're to skip
	=	0 otherwise

|

	REGSAVE <ebx,ecx>	; Save for a moment

	mov	bx,AGROUP:[eax].ELO ; Get bytes 0-1

	test	GPS_FLAG,mask $GPSKIP_HLT ; Skip HLT?
	jz	short CHECK_GPS_XHLT ; Jump if not

	cmp	bl,@OPCOD_HLT	; Izit HLT?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)
CHECK_GPS_XHLT:
	test	GPS_FLAG,mask $GPSKIP_OUTD ; Skip OUT DXs?
	jz	short CHECK_GPS_XOUTD ; Jump if not

	cmp	bl,@OPCOD_OUTDB ; Izit OUT DX,AL?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bl,@OPCOD_OUTDW ; Izit OUT DX,AX?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bx,@OPCOD_OUTDD ; Izit OUT DX,EAX?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)
CHECK_GPS_XOUTD:
	test	GPS_FLAG,mask $GPSKIP_OUTI ; Skip OUT immeds?
	jz	short CHECK_GPS_XOUTI ; Jump if not

	cmp	bl,@OPCOD_OUTIB ; Izit OUT immed,AL?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bl,@OPCOD_OUTIW ; Izit OUT immed,AX?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bx,@OPCOD_OUTID ; Izit OUT immed,EAX?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)
CHECK_GPS_XOUTI:
	test	GPS_FLAG,mask $GPSKIP_OUTS ; Skip OUTS?
	jz	short CHECK_GPS_XOUTS ; Jump if not

	cmp	bl,@OPCOD_OUTSB ; Izit OUTSB?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bl,@OPCOD_OUTSW ; Izit OUTSW?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bx,@OPCOD_OUTSD ; Izit OUTSD?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bl,@OPCOD_REPE	; Izit REPE?
	je	short @F	; Jump if so

	cmp	bl,@OPCOD_REPNE ; Izit REPNE?
	jne	short CHECK_GPS_XOUTS ; Jump if not
@@:
	cmp	bh,@OPCOD_OUTSB ; Izit OUTSB?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bh,@OPCOD_OUTSW ; Izit OUTSW?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)
;;;;;;;
;;;;;;; mov	bx,AGROUP:[eax].HI.ELO ; Get bytes 1-2
;;;;;;;
;;;;;;; cmp	bx,@OPCOD_OUTSD ; Izit OUTSD?
;;;;;;; je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)
;;;;;;;
;;;;;;; mov	bx,AGROUP:[eax].ELO ; Get bytes 0-1
CHECK_GPS_XOUTS:
	test	GPS_FLAG,mask $GPSKIP_IND ; Skip IN DXs?
	jz	short CHECK_GPS_XIND ; Jump if not

	cmp	bl,@OPCOD_INDB ; Izit IN DX,AL?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bl,@OPCOD_INDW ; Izit IN DX,AX?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bx,@OPCOD_INDD ; Izit IN DX,EAX?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)
CHECK_GPS_XIND:
	test	GPS_FLAG,mask $GPSKIP_INI ; Skip IN immeds?
	jz	short CHECK_GPS_XINI ; Jump if not

	cmp	bl,@OPCOD_INIB ; Izit IN immed,AL?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bl,@OPCOD_INIW ; Izit IN immed,AX?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bx,@OPCOD_INID ; Izit IN immed,EAX?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)
CHECK_GPS_XINI:
	test	GPS_FLAG,mask $GPSKIP_INS ; Skip INS?
	jz	short CHECK_GPS_XINS ; Jump if not

	cmp	bl,@OPCOD_INSB ; Izit INSB?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bl,@OPCOD_INSW ; Izit INSW?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bx,@OPCOD_INSD ; Izit INSD?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bl,@OPCOD_REPE	; Izit REPE?
	je	short @F	; Jump if so

	cmp	bl,@OPCOD_REPNE ; Izit REPNE?
	jne	short CHECK_GPS_XINS ; Jump if not
@@:
	cmp	bh,@OPCOD_INSB	; Izit INSB?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bh,@OPCOD_INSW	; Izit INSW?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)
;;;;;;;
;;;;;;; mov	bx,AGROUP:[eax].HI.ELO ; Get bytes 1-2
;;;;;;;
;;;;;;; cmp	bx,@OPCOD_INSD	; Izit INSD?
;;;;;;; je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)
;;;;;;;
;;;;;;; mov	bx,AGROUP:[eax].ELO ; Get bytes 0-1
CHECK_GPS_XINS:
	test	GPS_FLAG,mask $GPSKIP_INT ; Skip INT xxs?
	jz	short CHECK_GPS_XINT ; Jump if not

	cmp	bl,@OPCOD_INT	; Izit INT xx?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bl,@OPCOD_INT3	; Izit INT 03?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bl,@OPCOD_INTO	; Izit INTO?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)
CHECK_GPS_XINT:
	test	GPS_FLAG,mask $GPSKIP_CLI ; Skip CLIs?
	jz	short CHECK_GPS_XCLI ; Jump if not

	cmp	bl,@OPCOD_CLI	; Izit CLI?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)
CHECK_GPS_XCLI:
	test	GPS_FLAG,mask $GPSKIP_STI ; Skip STIs?
	jz	short CHECK_GPS_XSTI ; Jump if not

	cmp	bl,@OPCOD_STI	; Izit STI?
	je	near ptr CHECK_GPS_EXIT ; Jump if so (note CF=0)
CHECK_GPS_XSTI:
	test	GPS_FLAG,mask $GPSKIP_IRET ; Skip IRETs?
	jz	short CHECK_GPS_XIRET ; Jump if not

	cmp	bl,@OPCOD_IRET	; Izit IRET?
	je	short CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bx,@OPCOD_IRETD ; Izit IRETD?
	je	short CHECK_GPS_EXIT ; Jump if so (note CF=0)
CHECK_GPS_XIRET:
	test	GPS_FLAG,mask $GPSKIP_PPF ; Skip PUSHF/POPFs?
	jz	short CHECK_GPS_XPPF ; Jump if not

	cmp	bl,@OPCOD_PUSHF ; Izit PUSHF?
	je	short CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bx,@OPCOD_PUSHFD ; Izit PUSHFD?
	je	short CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bl,@OPCOD_POPF	; Izit POPF?
	je	short CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bx,@OPCOD_POPFD ; Izit POPFD?
	je	short CHECK_GPS_EXIT ; Jump if so (note CF=0)
CHECK_GPS_XPPF:
	test	GPS_FLAG,mask $GPSKIP_FF ; Skip FF instructions?
	jz	short CHECK_GPS_XFF ; Jump if not

	cmp	bl,@OPCOD_RETP	; Izit RET nn?
	je	short CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	bl,@OPCOD_GRP5	; Izit GRP5?
	jne	short CHECK_GPS_XFF ; Jump if not

;;;;;;; mov	cl,bh		; Copy for destructive testing
;;;;;;; and	cl,mask $MOD	; Isolate MOD bits
;;;;;;;
;;;;;;; cmp	cl,11b shl $MOD ; Izit register command?
;;;;;;; je	short CHECK_GPS_XFF ; Jump if so
;;;;;;;
	mov	cl,bh		; Copy Mod R/M bytes
	and	cl,mask $REG	; Isolate REG bits

	cmp	cl,010b shl $REG ; Izit Grp5 CALLN?
	je	short CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	cl,100b shl $REG ; Izit Grp5 JMPN?
	je	short CHECK_GPS_EXIT ; Jump if so (note CF=0)
CHECK_GPS_XFF:
	test	GPS_FLAG,mask $GPSKIP_CRn ; Skip MOV to/from CRn?
	jz	short CHECK_GPS_XCRn ; Jump if not

; The CPU allows (and some assemblers generate) a leading OSP,
; so skip it if it's present.

	xor	ebx,ebx 	; Zero to use as dword

	cmp	AGROUP:[eax].LO,@OPCOD_OSP ; Izit Operand Size Prefix?
	sete	bl		; BL = 1 iff so

	cmp	AGROUP:[eax+ebx].ELO,@OPCOD_MOV_R32_CRn ; Izit MOV r32,CRn?
	je	short CHECK_GPS_EXIT ; Jump if so (note CF=0)

	cmp	AGROUP:[eax+ebx].ELO,@OPCOD_MOV_CRn_R32 ; Izit MOV CRn,r32?
	je	short CHECK_GPS_EXIT ; Jump if so (note CF=0)
CHECK_GPS_XCRn:
	stc			; Mark as not skipping
CHECK_GPS_EXIT:
	cmc			; Complement so CF=1 is skip

	REGREST <ecx,ebx>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_GPS endp			; End CHECK_GPS procedure
	NPPROC	IZIT286 -- Is The Caller A 286 TSS?
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Is the caller a 286 TSS?

On exit:

CF	=	1 if it's a 286 TSS
	=	0	     386

|

IZIT286_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
IZIT286_SEL dw	?		; Selector to check

IZIT286_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ebx>		; Save register

	movzx	ebx,[ebp].IZIT286_SEL ; Get caller's TSS selector
	and	bx,not (mask $PL) ; Clear PL bits in case set

; Get base address of caller's GDT

	call	SEL2GDT 	; Convert selector in EBX to GDT address in EBX

	mov	bl,AGROUP:[ebx].DESC_ACCESS ; Get the access rights byte
	and	bl,mask $DS_386 ; Isolate 286/386 flag
	shr	bl,$DS_386	; Shift to low-order bit
				; BX = 0 if 286 TSS
				;    = 1 if 386

	cmp	bl,1		; Set CF if it's a 286 TSS
				; clear otherwise

	REGREST <ebx>		; Restore

	pop	ebp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT286 endp			; End IZIT286 procedure
	NPPROC	TSS_ENTER -- Setup Stack for SWAT Call
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup stack for SWAT call

On entry:

DGROUP:ESI ==>	 LCLTSSxx

|

	pop	ecx		; Save our return address

	push	esi		; Save offset of LCLTSSxx for TSS_LEAVE

	mov	ebx,DGROUP:[esi].PTSS_Ixx ; DGROUP:EBX ==> TSSxx

	push	DGROUP:[ebx].TSS_LINK.EDD ; Pass caller's TSS selector (as dword for alignment)
	call	SEL2BASE_DS	; Return with EAX == selector base address

	push	DGROUP:[ebx].TSS_LINK ; Pass caller's TSS selector
	call	IZIT286 	; Izit a 286 TSS?
	jc	short TSS_ENTER_286 ; Jump if so

	push	AGROUP:[eax].TSS_GS.EDD ; Put GS onto stack
	push	AGROUP:[eax].TSS_FS.EDD ; ... FS ...
	push	AGROUP:[eax].TSS_DS.EDD ; ... DS ...
	push	AGROUP:[eax].TSS_ES.EDD ; ... ES ...
	push	AGROUP:[eax].TSS_SS.EDD ; ... SS ...
	push	AGROUP:[eax].TSS_ESP	 ; ... ESP ...
	push	AGROUP:[eax].TSS_EFL	 ; ... EFL ...
	push	AGROUP:[eax].TSS_LDT	 ; ... LDT ...
	push	AGROUP:[eax].TSS_CS	 ; ... CS  ...
	push	AGROUP:[eax].TSS_EIP	 ; ... EIP ...

	push	ecx		; Restore our return address

; Restore caller's EGP registers

	call	TSS3_ENTER	; Put caller's EGP registers in place

	jmp	short TSS_ENTER_EXIT ; Join common exit code


; The caller is using a 286 TSS

TSS_ENTER_286:
	PUSHD	0			; Put GS onto stack
	PUSHD	0			; ... FS ...
	PUSHW	0			; ... upper word of pseudo-DS
	push	AGROUP:[eax].TSS2_DS	; ... DS ...
	PUSHW	0			; ... upper word of pseudo-ES
	push	AGROUP:[eax].TSS2_ES	; ... ES ...
	PUSHW	0			; ... upper word of pseudo-SS
	push	AGROUP:[eax].TSS2_SS	; ... SS ...
	PUSHW	0			; ... upper word of ESP
	push	AGROUP:[eax].TSS2_SP	; ... SP ...
	PUSHW	0			; ... upper word of EFL
	push	AGROUP:[eax].TSS2_FL	; ... FL ...
	push	AGROUP:[eax].TSS2_LDT	; ... LDT ...
	push	AGROUP:[eax].TSS2_CS	; ... CS  ...
	PUSHW	0			; ... upper word of EIP
	push	AGROUP:[eax].TSS2_IP	; ... IP ...

	push	ecx		; Restore our return address

; Restore caller's GP registers

	call	TSS2_ENTER	; Put caller's GP registers in place
TSS_ENTER_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_ENTER endp			; End TSS_ENTER procedure
	NPPROC	TSS3_ENTER -- Put Caller's 386 TSS Registers In Place
	assume	ds:AGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Put caller's 386 TSS registers in place.

On entry:

DS:EAX	==>	caller's 386 TSS

|

	push	AGROUP:[eax].TSS_EAX ; Put EAX onto stack
	push	AGROUP:[eax].TSS_ECX ; ... ECX ...
	push	AGROUP:[eax].TSS_EDX ; ... EDX ...
	push	AGROUP:[eax].TSS_EBX ; ... EBX ...
	sub	esp,4		; Skip over ESP
	push	AGROUP:[eax].TSS_EBP ; ... EBP ...
	push	AGROUP:[eax].TSS_ESI ; ... ESI ...
	push	AGROUP:[eax].TSS_EDI ; ... EDI ...

	popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS3_ENTER endp 		; End TSS3_ENTER procedure
	NPPROC	TSS2_ENTER -- Put Caller's 286 TSS Registers In Place
	assume	ds:AGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Put caller's 286 TSS registers in place.

On entry:

DS:EAX	==>	caller's 286 TSS

|

	push	AGROUP:[eax].TSS2_AX ; Put AX onto stack
	push	AGROUP:[eax].TSS2_CX ; ... CX ...
	push	AGROUP:[eax].TSS2_DX ; ... DX ...
	push	AGROUP:[eax].TSS2_BX ; ... BX ...
	sub	esp,2		; Skip over SP
	push	AGROUP:[eax].TSS2_BP ; ... BP ...
	push	AGROUP:[eax].TSS2_SI ; ... SI ...
	push	AGROUP:[eax].TSS2_DI ; ... DI ...

	popa			; Restore all GP registers
				; N.B.:  Do not follow with [EAX+???*?]

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS2_ENTER endp 		; End TSS2_ENTER procedure
	NPPROC	TSS_LEAVE -- Common TSS Return
	assume	ds:AGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common TSS return code

On entry:

TSSL_STR =	on stack

On exit:

EAX	=	destroyed
EBX	=	destroyed
ESI	=	destroyed
DGROUP:ESI ==>	LCLTSSxx
DGROUP:EBX ==>	TSSxx
CF	=	0 if leaving a 386 TSS
	=	1 ...	       286

|

TSSL_STR struc

	dd	?		; Caller's EIP
TSSL_EIP dd	?		; Interrupted EIP register
TSSL_CS dw	?		; ...	      CS
TSSL_LDT dw	?		; ...	      LDT
TSSL_EFL dd	?		; ...	      EFL
TSSL_ESP dd	?		; ...	      ESP
TSSL_SS dw	?,0		; ...	      SS ... with filler
TSSL_ES dw	?,0		; ...	      ES ...
TSSL_DS dw	?,0		; ...	      DS ...
TSSL_FS dw	?,0		; ...	      FS ...
TSSL_GS dw	?,0		; ...	      GS ...
TSSL_LCL dd	?		; Offset to LCLTSSxx

TSSL_STR ends

	pushad			; Save all EGP registers

@TSS_LEAVE equ	size PUSHAD_STR

; Get address of caller's TSS

	mov	esi,[esp+@TSS_LEAVE].TSSL_LCL ; DGROUP:ESI ==> LCLTSSxx
	mov	ebx,DGROUP:[esi].PTSS_Ixx ; DGROUP:EBX ==> TSSxx

	push	DGROUP:[ebx].TSS_LINK.EDD ; Pass caller's TSS selector (as dword for alignment)
	call	SEL2BASE_DS	; Return with EAX == selector base address

	push	DGROUP:[ebx].TSS_LINK ; Pass caller's TSS selector
	call	IZIT286 	; Izit a 286 TSS?
	jc	near ptr TSS_LEAVE286 ; Jump if so

	pop	AGROUP:[eax].TSS_EDI	 ; Put EDI into TSS
	pop	AGROUP:[eax].TSS_ESI	 ; ... ESI ...
	pop	AGROUP:[eax].TSS_EBP	 ; ... EBP ...
	add	esp,4		     ; Skip over ESP
	pop	AGROUP:[eax].TSS_EBX	 ; ... EBX ...
	pop	AGROUP:[eax].TSS_EDX	 ; ... EDX ...
	pop	AGROUP:[eax].TSS_ECX	 ; ... ECX ...
	pop	AGROUP:[eax].TSS_EAX	 ; ... EAX ...

	mov	ebx,[esp].TSSL_EIP
	mov	AGROUP:[eax].TSS_EIP,ebx ; Put EIP into TSS

	mov	bx,[esp].TSSL_CS
	mov	AGROUP:[eax].TSS_CS,bx	 ; ... CS  ...

	mov	bx,[esp].TSSL_LDT
	mov	AGROUP:[eax].TSS_LDT,bx  ; ... LDT ...

	mov	ebx,[esp].TSSL_EFL
	mov	AGROUP:[eax].TSS_EFL,ebx ; ... EFL ...

	mov	ebx,[esp].TSSL_ESP
	mov	AGROUP:[eax].TSS_ESP,ebx ; ... ESP ...

	mov	bx,[esp].TSSL_SS
	mov	AGROUP:[eax].TSS_SS,bx	 ; ... SS  ...

	mov	bx,[esp].TSSL_ES
	mov	AGROUP:[eax].TSS_ES,bx	 ; ... ES  ...

	mov	bx,[esp].TSSL_DS
	mov	AGROUP:[eax].TSS_DS,bx	 ; ... DS  ...

	mov	bx,[esp].TSSL_FS
	mov	AGROUP:[eax].TSS_FS,bx	 ; ... FS  ...

	mov	bx,[esp].TSSL_GS
	mov	AGROUP:[eax].TSS_GS,bx	 ; ... GS  ...

	clc			; Mark as leaving a 386 TSS

	jmp	TSS_LEAVE_EXIT	; Join common exit code


; The caller is using a 286 TSS

TSS_LEAVE286:
	pop	AGROUP:[eax].TSS2_DI	; Put DI into TSS
	add	esp,2			; Skip over unused upper word of EDI
	pop	AGROUP:[eax].TSS2_SI	; ... SI ...
	add	esp,2			; ...				 ESI
	pop	AGROUP:[eax].TSS2_BP	; ... BP ...
	add	esp,2			; ...				 EBP
	add	esp,2			; Skip over SP
	add	esp,2			; ...				 ESP
	pop	AGROUP:[eax].TSS2_BX	; ... BX ...
	add	esp,2			; ...				 EBX
	pop	AGROUP:[eax].TSS2_DX	; ... DX ...
	add	esp,2			; ...				 EDX
	pop	AGROUP:[eax].TSS2_CX	; ... CX ...
	add	esp,2			; ...				 ECX
	pop	AGROUP:[eax].TSS2_AX	; ... AX ...
	add	esp,2			; ...				 EAX

	mov	bx,[esp].TSSL_EIP.ELO
	mov	AGROUP:[eax].TSS2_IP,bx  ; Put IP into 286 TSS

	mov	bx,[esp].TSSL_CS
	mov	AGROUP:[eax].TSS2_CS,bx  ; ... CS  ...

	mov	bx,[esp].TSSL_LDT
	mov	AGROUP:[eax].TSS2_LDT,bx ; ... LDT ...

	mov	bx,[esp].TSSL_EFL.ELO
	mov	AGROUP:[eax].TSS2_FL,bx  ; ... FL ...

	mov	bx,[esp].TSSL_ESP.ELO
	mov	AGROUP:[eax].TSS2_SP,bx  ; ... SP ...

	mov	bx,[esp].TSSL_SS
	mov	AGROUP:[eax].TSS2_SS,bx  ; ... SS  ...

	mov	bx,[esp].TSSL_ES
	mov	AGROUP:[eax].TSS2_ES,bx  ; ... ES  ...

	mov	bx,[esp].TSSL_DS
	mov	AGROUP:[eax].TSS2_DS,bx  ; ... DS  ...

	stc			; Mark as leaving a 286 TSS
TSS_LEAVE_EXIT:
	ret	(size TSSL_STR)-4 ; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSS_LEAVE endp			; End TSS_LEAVE procedure
	NPPROC	SEL2GDT -- Selector to GDT Address
	assume	ds:AGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert selector to GDT address

On entry:

EBX	=	selector

On exit:

EBX	=	linear address of corresponding GDT entry

|

	sub	esp,size DTR_STR ; Make room for GDTR

	SGDTD	[esp].EDF	; Save address of current GDT

	and	bx,not (mask $PL) ; Clear the PL bits

	btr	ebx,$TI 	; Izit in the LDT?
	jnc	short @F	; Jump if not

	mov	[esp].DTR_BASE,eax ; Save for a moment

	sldt	[esp].DTR_LIM	; Get current LDT selector
	lsl	ax,[esp].DTR_LIM ; Get the selector limit
	xchg	ax,[esp].DTR_LIM ; Swap with the selector value

	push	eax		; Pass the selector
	call	SEL2BASE_DS	; Return with EAX == selector base address
				; Return with CF significant
	xchg	eax,[esp].DTR_BASE ; Swap 'em leaving LDT base address on stack
	jc	short SEL2GDT_EXIT ; Jump if invalid
@@:
	cmp	[esp].DTR_LIM,bx ; Izit too big?
	jb	short SEL2GDT_EXIT ; Jump if so (note CF=1)

	add	ebx,[esp].DTR_BASE ; Plus the GDT's base address
				; DS:EBX ==> GDT entry
				; Return with CF=0
SEL2GDT_EXIT:
	lea	esp,[esp+(size DTR_STR)] ; Strip off GDTR

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SEL2GDT endp			; End SEL2GDT procedure
	NPPROC	SEL2BASE -- Convert Selector to Base Address
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert selector to base address.

On exit:

EAX	=	base address
CF	=	0 if valid
	=	1 if not

|

SEL2B_STR struc

SEL2B_EBP dd	?		; Caller's EBP
	  dd	?		; ...	   EIP
SEL2B_SEL dd	?		; ...	   selector (as dword for alignment)

SEL2B_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ds>		; Save register

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	mov	ds,COMMON.FILE_4GB ; Get AGROUP data selector
	assume	ds:AGROUP	; Tell the assembler about it

	push	[ebp].SEL2B_SEL ; Pass the selector
	mov	ebp,[ebp].SEL2B_EBP ; Restore for following call
	call	SEL2BASE_DS	; Return with EAX = selector base address
				; Return with CF significant
	REGREST <ds>		; Restore
	assume	ds:nothing	; Tell the assembler about it

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SEL2BASE endp			; End SEL2BASE procedure
	NPPROC	SEL2BASE_DS -- Convert Selector to Base Address
	assume	ds:AGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert selector to base address.

On exit:

EAX	==	base address
CF	=	0 if valid
	=	1 if not

|

SEL2B_DS_STR struc

SEL2B_DS_EBP dd ?		; Caller's EBP
	     dd ?		; ...	   EIP
SEL2B_DS_SEL dw ?,?		; ...	   selector (as dword for alignment)

SEL2B_DS_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ebx>		; Save register

	movzx	ebx,[ebp].SEL2B_DS_SEL ; Get the selector
	mov	ebp,[ebp].SEL2B_DS_EBP ; Restore for following code

; Get base address of caller's GDT

	call	SEL2GDT 	; Convert selector in EBX to GDT address in EBX
	jc	short @F	; Jump if invalid (note CF=1)

	mov	eax,AGROUP:[ebx].DESC_BASE01.EDD ; Get bytes 0-2
	shl	eax,8		; Make room for byte 3
	mov	al,AGROUP:[ebx].DESC_BASE3 ; Get byte 3
	ror	eax,8		; Rotate back to normal order

	clc			; Mark as valid
@@:
	REGREST <ebx>		; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SEL2BASE_DS endp		; End SEL2BASE_DS procedure
	NPPROC	SETTSS -- Setup The TSS Data Structure
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Setup the TSS data structure, and
save the TSS in the interrupt descriptor table.

On entry:

GS:EBX	==>	caller's IDT entry for this interrupt
DS:EDI	==>	LCLTSSxx data structure
DS:ESI	==>	LCLPMGxx ...

|

SETTSS_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
SETTSS_FLAG dd	?		; Do/don't install flag (0 = don't)

SETTSS_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,edx>	; Save registers

	test	VCP_FLAG,@VCP_PMG ; Installing Interrupt Gates?
	jnz	near ptr SETTSS_PMG1 ; Jump if so

	mov	eax,INDVCP_GDT	; Get current index
	mov	ax,CODESEL[eax*(type CODESEL)] ; Get our VCPI code selector

	cmp	edi,offset ds:LCLTSS02 ; Izit NMI?
	jne	short @F	; Jump if not

	mov	DEBOUNCE_FVEC.FOFF,offset cs:DEBOUNCE ; Save offset
	mov	DEBOUNCE_FVEC.FSEL,ax ; Save selector
	mov	DEBOUNCE_ARB,CPL0_INTR3 or CPL3 ; Save ARB
@@:
	mov	edx,DGROUP:[edi].PTSS_Ixx ; Get offset in data to TSS structure
	mov	DGROUP:[edx].TSS_CS,ax

;;;;;;; mov	eax,INDVCP_GDT	; Get current index
;;;;;;; mov	ax,CODESEL[eax*(type CODESEL)] ; Get our VCPI code selector
	add	ax,VCP_LDT-VCP_CODE ; Plus our LDT offset
	mov	DGROUP:[edx].TSS_LDT,ax ; Save in TSS

	mov	eax,INDVCP_GDT	; Get current index
	mov	ax,CODESEL[eax*(type CODESEL)] ; Get our VCPI code selector
	add	ax,VCP_DATA-VCP_CODE ; Plus our data offset

	mov	DGROUP:[edx].TSS_SS0,ax
	mov	DGROUP:[edx].TSS_SS,ax
	mov	DGROUP:[edx].TSS_ES,ax
	mov	DGROUP:[edx].TSS_DS,LDT_4GB
	mov	DGROUP:[edx].TSS_FS,0
	mov	DGROUP:[edx].TSS_GS,0

	mov	eax,DGROUP:[edi].PSTK_IxxZ ; Get stack ending offset
	mov	DGROUP:[edx].TSS_ESP0,eax
	mov	DGROUP:[edx].TSS_ESP,eax

	mov	eax,DGROUP:[edi].TSS_INTxx ; Get starting IP
	mov	DGROUP:[edx].TSS_EIP,eax
	mov	DGROUP:[edx].TSS_EFL,0

	mov	DGROUP:[edx].TSS_DBG,0
	mov	DGROUP:[edx].TSS_IOMAP,size TSS_STR
SETTSS_PMG1:

; Save the TSS or Interrupt Gate in the interrupt descriptor table.

	mov	eax,INDVCP_GDT	; Get current index
	mov	ax,CODESEL[eax*(type CODESEL)] ; Get our VCPI code selector

	test	VCP_FLAG,@VCP_PMG ; Installing Interrupt Gates?
	jnz	short @F	; Jump if so

	add	ax,DGROUP:[edi].DDTE_TSSxx ; Plus our TSS selector
@@:
	cmp	ax,AGROUP:[ebx].IDT_SELECT ; Same as before?
	je	near ptr SETTSS_EXIT ; Yes, skip swap

	cmp	[ebp].SETTSS_FLAG,0 ; Should we install?
	je	short SETTSS_XINST ; Jump if not

	test	VCP_FLAG,@VCP_PMG ; Doing Interrupt Gates?
	jz	short SETTSS_TSK1 ; Jump if not

	mov	DGROUP:[esi].LCLPMGxx_FVEC.FSEL,ax ; Save for later use
	xchg	ax,AGROUP:[ebx].IDT_SELECT ; Swap 'em
	mov	DGROUP:[esi].OLDPMGxx_FVEC.FSEL,ax ; Save to restore later

	mov	eax,DGROUP:[esi].LCLPMGxx_FVEC.FOFF ; Get offset
	rol	eax,16		; Swap high- and low-order words
	xchg	ax,AGROUP:[ebx].IDT_OFFHI ; Get old offset
	rol	eax,16		; Shift to high-order
	xchg	ax,AGROUP:[ebx].IDT_OFFLO ; Get old offset
	mov	DGROUP:[esi].OLDPMGxx_FVEC.FOFF,eax ; Save to restore later

	mov	al,CPL0_INTR3 or CPL3 ; Get our access rights byte
	xchg	al,AGROUP:[ebx].IDT_ACCESS ; Swap 'em
	mov	DGROUP:[esi].OLDPMGxx_ARB,al ; Save to restore later

;;;;;;; movzx	eax,DGROUP:[edi].INTNOxx ; Get the interrupt #
;;;;;;; bts	TSSINT_FLAG,eax ; Mark as intercepted
;;;;;;;
	jmp	SETTSS_EXIT	; Join common exit code


SETTSS_TSK1:
	xchg	ax,AGROUP:[ebx].IDT_SELECT ; Swap 'em
	mov	DGROUP:[edi].OLDINTxx_FWD.FSEL,ax ; Save to restore later

	mov	eax,-1		; Get invalid offset
	mov	al,DGROUP:[edi].INTNOxx ; Get the interrupt # for debugging
	rol	eax,16		; Swap high- and low-order words
	xchg	ax,AGROUP:[ebx].IDT_OFFHI ; Get old offset
	rol	eax,16		; Shift to high-order
	xchg	ax,AGROUP:[ebx].IDT_OFFLO ; Get old offset
	mov	DGROUP:[edi].OLDINTxx_FWD.FOFF,eax ; Save to restore later

	mov	al,CPL0_TASK or CPL3 ; Get our access rights byte
	xchg	al,AGROUP:[ebx].IDT_ACCESS ; Swap 'em
	mov	DGROUP:[edi].OLDINTxx_ARB,al ; Save to restore later

	movzx	eax,DGROUP:[edi].INTNOxx ; Get the interrupt #
	bts	TSSINT_FLAG,eax ; Mark as intercepted

	jmp	short SETTSS_EXIT ; Join common exit code


SETTSS_XINST:
	test	VCP_FLAG,@VCP_PMG ; Doing Interrupt Gates?
	jz	short SETTSS_TSK2 ; Jump if not

	mov	ax,AGROUP:[ebx].IDT_SELECT ; Get old selector
	mov	DGROUP:[esi].OLDPMGxx_FVEC.FSEL,ax ; Save to restore later

	mov	ax,AGROUP:[ebx].IDT_OFFHI ; Get old offset
	rol	eax,16		; Shift to high-order
	mov	ax,AGROUP:[ebx].IDT_OFFLO ; Get old offset
	mov	DGROUP:[esi].OLDPMGxx_FVEC.FOFF,eax ; Save to restore later

	mov	al,AGROUP:[ebx].IDT_ACCESS ; Get old ARB
	mov	DGROUP:[esi].OLDPMGxx_ARB,al ; Save to restore later

	jmp	short SETTSS_EXIT ; Join common exit code


SETTSS_TSK2:
	mov	ax,AGROUP:[ebx].IDT_SELECT ; Get old selector
	mov	DGROUP:[edi].OLDINTxx_FWD.FSEL,ax ; Save to restore later

	mov	ax,AGROUP:[ebx].IDT_OFFHI ; Get old offset
	rol	eax,16		; Shift to high-order
	mov	ax,AGROUP:[ebx].IDT_OFFLO ; Get old offset
	mov	DGROUP:[edi].OLDINTxx_FWD.FOFF,eax ; Save to restore later

	mov	al,AGROUP:[ebx].IDT_ACCESS ; Get old ARB
	mov	DGROUP:[edi].OLDINTxx_ARB,al ; Save to restore later
SETTSS_EXIT:
	REGREST <edx,eax>	; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETTSS	endp			; End SETTSS procedure
	NPPROC	ENABLE_NMI -- Enable NMI, Clear Parity Latches
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable NMI, clear parity latches.

Note that this routine is bimodal.

|

	pushfd			; Save flags
	cli			; Ensure interrupts disabled

	REGSAVE <eax,edx>	; Save for a moment

; Clear the parity latches

	mov	ah,NMIMASK	; Get parity mask
	in	al,@8255_B	; Get the parity latches
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	or	al,ah		; Toggle parity check latches off
	out	@8255_B,al	; Tell the system about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	xor	al,ah		; Toggle parity check latches on
	out	@8255_B,al	; Tell the system about it
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

; Enable NMI

	mov	dx,NMIPORT	; Get NMI clear I/O port
	mov	al,NMIENA	; ...	  enable value
	out	dx,al		; Clear NMI
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	cmp	dx,@CMOS_CMD	; Izit an AT?
	jne	short @F	; Jump if not

	in	al,@CMOS_DATA	; Ensure OUT is followed by IN
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
@@:
	REGREST <edx,eax>	; Restore
	popfd			; Restore

; Reset NMI handler active flag

	push	ds		; Save for a moment

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	btr	NMI_FLAG,$NMI_ACT ; Reset the bit

; If we're on an MCA, reset arbitration mask bit

	test	SWATINI.MD_ATTR,@MD_MCA ; Izit an MCA?
	jz	short @F	; Jump if not

	push	eax		; Save for a moment

	in	al,90h		; Get arbitration register
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

; Clear the arbitration mask bit (Bit 6) as well as everything else
; except for enable system microprocessor cycles (Bit 7)

	and	al,@BIT7	; Clear everything except Bit 7
	out	90h,al		; Send it back
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	pop	eax		; Restore
@@:
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENABLE_NMI endp 		; End ENABLE_NMI procedure
	NPPROC	DISABLE_NMI -- Disable NMI
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable NMI

Note that this routine is bimodal.

|

; Test and set flag indicating we're in an NMI handler

	push	ds		; Save for a moment
	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it
	bts	NMI_FLAG,$NMI_ACT ; Set and check the bit
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it
	jc	short DISABLE_NMI_EXIT ; Jump if NMI handler already active

	pushfd			; Save flags
	cli			; Ensure interrupts disabled

	REGSAVE <eax,edx>	; Save for a moment

; Disable NMI

	mov	dx,NMIPORT	; Get NMI clear I/O port
	mov	al,NMIDIS	; ...	  disable value
	out	dx,al		; Clear NMI
	call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue

	cmp	dx,@CMOS_CMD	; Izit an AT?
	jne	short @F	; Jump if not

	in	al,@CMOS_DATA	; Ensure OUT is followed by IN
;;;;;;; call	U32_DRAINPIQ	; Drain the Prefetch Instruction Queue
@@:
	REGREST <edx,eax>	; Restore
	popfd			; Restore

	clc			; Indicate NMI handler not already active
DISABLE_NMI_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISABLE_NMI endp		; End DISABLE_NMI procedure
	NPPROC	CMD_VMSCOUNT -- Set VMSCOUNT
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

VMSCOUNT n command

n is a non-zero number specifying the number of times SWAT should
insinuate itself into the GDT/IDT of a VCPI client.

This is only meaningful when VMSINT is used.

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|


	REGSAVE <eax>		; Save register

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	or	al,al		; Izit the end of the line?
	jz	short CMD_VMSCOUNT_SYNTERR ; Jump if so

	call	U32_HEX2DD	; Convert DS:ESI from hex to binary EAX
	jc	short CMD_VMSCOUNT_OVFERR ; Jump if error in conversion

	cmp	eax,0000ffffh	; Izit a valid line number?
	ja	short CMD_VMSCOUNT_OVFERR ; Jump if not

	or	ax,ax		; Izit 0?
	jz	short CMD_VMSCOUNT_SYNTERR ; Jump if so

	mov	VMSCOUNT,ax	; Set new value
	or	DBG_FLAG,@DBG_VCNT ; Indicate VMSCOUNT is valid

	jmp	short CMD_VMSCOUNT_EXIT ; Join common exit

CMD_VMSCOUNT_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	jmp	short CMD_VMSCOUNT_ERR ; Join common error exit code

CMD_VMSCOUNT_OVFERR:
	mov	MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

;;;;;;; jmp	short CMD_VMSCOUNT_ERR ; Join common error exit code

CMD_VMSCOUNT_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error

;;;;;	jmp	short CMD_VMSCOUNT_EXIT ; Join common exit

CMD_VMSCOUNT_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_VMSCOUNT endp		; End CMD_VMSCOUNT procedure
	NPPROC	CMD_VMSINT -- Set VMSINT
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

VMSINT ON
VMSINT OFF
VMSINT = xx,xx,...

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|


	REGSAVE <eax>		; Save register

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	or	al,al		; Izit the end of the line?
	jz	near ptr CMD_VMSINT_SYNTERR ; Jump if so

	cmp	al,'='          ; Izit a list of interrupts?
	je	short CMD_VMSINT_LST ; Jump if so

	call	GET_TOKN	; Get next token into CMD_TOKN

	cmp	CMD_TOKN.ELO,'no' ; Izit 'ON'?
	je	short CMD_VMSINT_ON ; Jump if so

	cmp	CMD_TOKN.EDD,'ffo' ; Izit 'OFF',0?
	jne	short CMD_VMSINT_SYNTERR ; Jump if not

	and	DBG_FLAG,not @DBG_VMS ; Indicate VMSINT is not valid

	jmp	short CMD_VMSINT_DONE ; Join common done code


CMD_VMSINT_ON:
	cmp	CMD_TOKL,2	; Izit a two-letter command?
	jne	short CMD_VMSINT_SYNTERR ; Jump if not

	jmp	short CMD_VMSINT_CLC ; Join common OK code

CMD_VMSINT_LST:
	inc	esi		; Skip over the separator

	call	CMD_WHITE	; Skip over more white space
				; Return with AL = last character
	xor	ebx,ebx 	; Initialize index into VMSINTTAB

	cmp	al,0		; Izit EOL?
	je	short CMD_VMSINT_SYNTERR ; Jump if so
CMD_VMSINT_NEXT:
	call	U32_HEX2DD	; Convert DS:ESI from hex to binary EAX
	jc	short CMD_VMSINT_OVF ; Jump if too large

	cmp	eax,0FFh	; Check for within 8-bit range
	ja	short CMD_VMSINT_OVF ; Jump if too large

	mov	VMSINT_TAB[ebx],al ; Save in VMS interrupt table
	inc	ebx		; Skip to next entry

	call	CMD_WHITE	; Skip over more white space
				; Return with AL = last character
	cmp	al,0		; Izit the end of the line?
	je	short CMD_VMSINT_EOL ; Jump if so

	cmp	al,','          ; Izit entry separator?
	jne	short CMD_VMSINT_SYNTERR ; Jump if not

	inc	esi		; Skip over the separator

	call	CMD_WHITE	; Skip over more white space
				; Return with AL = last character

	jmp	short CMD_VMSINT_NEXT ; Go around again

CMD_VMSINT_EOL:
	mov	VMSINT_LEN,bl	; Save as VMS interrupt table length
CMD_VMSINT_CLC:
	or	DBG_FLAG,@DBG_VMS ; Indicate VMSINT is valid
CMD_VMSINT_DONE:
	clc			; Mark as successful

	jmp	short CMD_VMSINT_EXIT ; Join common exit code


CMD_VMSINT_OVF:
	mov	MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

	jmp	short CMD_VMSINT_ERR ; Join common error exit code

CMD_VMSINT_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

;;;;;;; jmp	short CMD_VMSINT_ERR ; Join common error exit code

CMD_VMSINT_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_VMSINT_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_VMSINT endp 		; End CMD_VMSINT procedure
	NPPROC	SETUP_CR3 -- Setup CR3
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If paging is enabled and we're active via a TSS
save the value of CR3 in the PTE which corresponds to
PLCLCR3, and change the LDT address for CR3 so we can
address it via that address.

|

	REGSAVE <eax,ebx>	; Save registers

	mov	eax,cr0 	; Get register with Paging bit

	test	eax,mask $PG	; Izit enabled?
	jz	short SETUP_CR3_EXIT ; Jump if not

	cmp	TSS_CNT,0	; Izit TSS mode?
	je	short SETUP_CR3_EXIT ; Jump if not

	push	gs		; Save for a moment

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

	mov	ebx,cr3 	; Get current PDBR
	and	ebx,@PTE_FRM	; Isolate the 4KB frame

	mov	eax,PLCLCR3	; Get offset in DGROUP of local CR3
	add	eax,SWATDATA	; Plus linear address of DGROUP

	PUSHD	0		; Make room for original 1st PTE
	PUSHD	1		; # PTEs to follow
	PUSHD	0		; Make room for original PDE
	push	eax		; Pass the linear address
	push	ebx		; Pass the CR3 to use
	call	LIN2PPTE	; Return with AGROUP:EAX ==> corresponding PTE

	or	ebx,@PTE_URP	; Mark as User/Read-write/Present
	mov	AGROUP:[eax],ebx ; Save the PTE

	call	LIN2PPTEZ	; Cleanup after LIN2PPTE
	add	esp,1*4 	; Pop the PTE

; Save the new linear address in the LDT

	mov	eax,PLCLCR3	; Get offset in DGROUP of local CR3
	add	eax,SWATDATA	; Plus linear address of DGROUP
	mov	LCLLDT.MLDT_CR3.DESC_BASE01,ax ; Save bytes 0-1
	shr	eax,16		; Shift down the high-order word
	mov	LCLLDT.MLDT_CR3.DESC_BASE2,al ; Save byte 2
	mov	LCLLDT.MLDT_CR3.DESC_BASE3,ah ; ...	  3

	pop	gs		; Restore
	assume	gs:nothing	; Tell the assembler about it
SETUP_CR3_EXIT:
	REGREST <ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_CR3 endp			; End SETUP_CR3 procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_VCP module
