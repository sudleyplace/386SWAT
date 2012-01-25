;' $Header:   P:/PVCS/386SWAT/SWAT_I68.ASV   1.0   10 Aug 1998 11:01:08   BOB  $
	title	SWAT_I68 -- 386SWAT Windows Kernel Debugging, INT 68h
	page	58,122
	name	SWAT_I68

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-2002 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, July, 1994.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include CPUFLAGS.INC
	include ALLMEM.INC
	include ASCII.INC
Not_VxD = 1		; Define to get equates and strucs only from VMM.INC
	include VMM.INC
	include WINDEVID.INC
	include SWATVXD.INC
	include WINSTR.INC
	include OPCODES.INC
	include WKD.INC
	include DEBUGSYS.INC
	include KEYCODE.INC

	include SWAT_CMD.INC
	include SWAT_COM.INC
	include SWAT_DRV.INC
	include SWAT_FLT.INC
	include SWAT_FMT.INC
	include SWAT_OLD.INC
	include SWAT_SEG.INC
	include SWAT_SYM.INC
	include SWAT_FIL.INC
.list


DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	extrn	COMMON:tbyte

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	SWATCODE:dword
	extrn	SWATDATA:dword

	extrn	RGRSEG2:word

	extrn	WKDLS_CNT:dword
	extrn	PWKDLS:dword

	extrn	HLPATTR:byte
	extrn	HLPAATTR:byte
	extrn	HLPBATTR:byte

DATA16	ends			; End DATA16 segment


RCODE	segment use16 para public 'rcode' ; Start RCODE segment
	assume	cs:RGROUP,ds:RGROUP

	extrn	RSWAT_WKDCB:far
	extrn	RSWAT_INT41:far

	extrn	DEVINT41_FVEC:fword
	extrn	DEVINT41_ARB:byte
	extrn	WKD_AGRSEL:word
	extrn	WKD_SWATPHYS_CS:dword
	extrn	WKD_SWATPHYS_DS:dword
	extrn	TRP_FLAG:dword
	extrn	DEV_WINVER:word

RCODE	ends			; End RCODE segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	@SWAT_I68_DATA
@SWAT_I68_DATA label byte	; Mark module start in .MAP file

	extrn	MSGOFF:dword
	extrn	SYNTERR:byte
	extrn	NOWINERR:byte
	extrn	WINERR:byte
	extrn	VNFERR:byte
	extrn	FULLERR:byte
	extrn	TDBSEL:word
	extrn	MDBSEL:word
;;;;;;; extrn	REENTRY:word
	extrn	OLDINT41_FVEC:fword
	extrn	OLDINT41_ARB:byte

@SWAT_IPF_LEN equ 32		; Maximum # entries allowed

	public	IPF_VAL
IPF_VAL dd	?		; Value for IPF command

	public	IPFTAB
IPFTAB	dd	0		; # valid entries in the IPF struc table
	SWAT_IPF_STR @SWAT_IPF_LEN dup (<>) ; The table itself

	public	LaSparePTE,LaPtrSparePTE
LaSparePTE dd	?		; Linear address of spare PTE
LaPtrSparePTE dd ?		; ...		    ptr to spare PTE

	public	EnterVMM,ExitVMM
	public	_Trace_Out_Service
	public	_Debug_Out_Service
EnterVMM dd	?		; Enter VMM routine address
ExitVMM dd	?		; Exit ...
_Trace_Out_Service dd ? 	; Trace Out Service
_Debug_Out_Service dd ? 	; Debug Out Service

	public	WKDLS_NEXT
WKDLS_NEXT dd	0		; Index of next WKDLS entry

	public	WKD_FLAG
	include SWAT_WKD.INC
WKD_FLAG dw	@WKD_ENABLE or @WKD_FLTON or @WKD_QUIET ; Windows Kernel Debugger flags

	public	WKD_WINDBG
WKD_WINDBG db	0		; = 1 iff debugging version of Windows

	align	4		; Ensure dword-aligned

	public	KVARS_VEC
KVARS_VEC dd	?		; Ptr to Kernel vars struc (KVARS_STR)

	public	UVARS
UVARS	UVARS_STR2 <>		; User vars (lp form)

	public	WKDIND
WKDIND	dd	0		; Index into WKD menu

	public	WKDTOP_ACT
WKDTOP_ACT dd	offset PGROUP:DISP_WKD_WGH
	dd	offset PGROUP:DISP_WKD_EXE
	dd	offset PGROUP:DISP_WKD_TOPPDB
	dd	offset PGROUP:DISP_WKD_HEADPDB
	dd	offset PGROUP:DISP_WKD_HEADTDB
	dd	offset PGROUP:DISP_WKD_CURTDB
	dd	offset PGROUP:DISP_WKD_ZORD
	dd	offset PGROUP:DISP_WKD_MENUSEL
	dd	offset PGROUP:DISP_WKD_WNDSEL
	dd	offset PGROUP:DISP_WKD_CLS
	dd	offset PGROUP:DISP_WKD_DCE
; NEW TOPIC GOES HERE

	public	W_WKD
W_WKD	W_STR	<@WKD_SROW, @WKD_SCOL, @WKD_NROW, @WKD_NCOL>

	public	MSG_WKD
MSG_WKD db	'ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿'
@WKD_NCOL equ	$-MSG_WKD
	db	'³                        ³'
@KLIN_SROW equ	@WKD_SROW + ($-MSG_WKD)/@WKD_NCOL
MSG_KLIN db	'³  Global Heap           ³'
	db	'³  EXE Head              ³'
	db	'³  Top  Process Database ³'
	db	'³  Head Process Database ³'
	db	'³  Head Task Database    ³'
	db	'³  Cur  Task Database    ³'
	db	'³  Window Z-order        ³'
	db	'³  hMenu Selector        ³'
	db	'³  hWnd Selector         ³'
	db	'³  Class list            ³'
	db	'³  DCE First             ³'
; NEW TOPIC GOES HERE
	public	@KLIN_LEN
@KLIN_LEN equ	($-MSG_KLIN)/@WKD_NCOL
	db	'³                        ³'
	db	'³ KVARS @ '
	public	MSG_KVS,MSG_KVO
MSG_KVS db	'xxxx|'
MSG_KVO db	'xxxx      ³'
	db	'³ UVARS @ '
	public	MSG_UVS,MSG_UVO
MSG_UVS db	'xxxx|'
MSG_UVO db	'xxxxxxxx  ³'
	db	'³                        ³'
	db	'³   Press CR to select,  ³'
	db	'³     ESC to cancel      ³'
	db	'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ'
@WKD_NROW equ	($-MSG_WKD)/@WKD_NCOL

@WKD_SROW equ	(@NROWS - 1 - @WKD_NROW)/2 ; Center the box
@WKD_SCOL equ	(@NCOLS - 1 - @WKD_NCOL)/2 ; ...

	public	W_KLIN
	align	2
W_KLIN	W_STR	<@KLIN_SROW, @KLIN_SCOL, @KLIN_NROW, @KLIN_NCOL>

@KLIN_SCOL equ	@WKD_SCOL + 1 + 1
@KLIN_NROW equ	1
@KLIN_NCOL equ	@WKD_NCOL - 2 - 2

@KASK_NROW equ	@KLIN_LEN
@KASK_NCOL equ	@KLIN_NCOL
@KASK_SCOL equ	@KLIN_SCOL
@KASK_SROW equ	@KLIN_SROW

	public	W_KASK
W_KASK	W_STR	<@KASK_SROW, @KASK_SCOL, @KASK_NROW, @KASK_NCOL>

	public	KCMD
KCMD	db	'KVARS_VEC = '
KCMD1	db	'xxxx|'
KCMD2	db	'xxxx' ; Command line
KCMD_LEN equ	$-KCMD		; Length of ...
	db	0		; End of ...

	public	TXT_LOGERROR,TXT_PARAMERROR,TXT_VXDLOAD,TXT_PMINIT,TXT_FAULT
	public	TXT_QUIET,TXT_NOISY
	public	TXT_ON,TXT_OFF,TXT_SKIP
	public	TXT_TRAPON,TXT_TRAPOFF
TXT_LOGERROR db 'logerror',0    ; WKD command
@TXT_LOGERROR equ $-TXT_LOGERROR-1 ; Length of ...
TXT_PARAMERROR db 'paramerror',0 ; WKD command
@TXT_PARAMERROR equ $-TXT_PARAMERROR-1 ; Length of ...
TXT_VXDLOAD  db 'vxdload'       ; WKD command
@TXT_VXDLOAD  equ $-TXT_VXDLOAD-1 ; Length of ...
TXT_PMINIT   db 'pminit',0      ; WKD command
@TXT_PMINIT   equ $-TXT_PMINIT-1 ; Length of ...
TXT_FAULT    db 'fault',0       ; WKD command
@TXT_FAULT    equ $-TXT_FAULT-1 ; Length of ...
TXT_QUIET    db 'quiet',0       ; WKD command
@TXT_QUIET    equ $-TXT_QUIET-1 ; Length of ...
TXT_NOISY    db 'noisy',0       ; WKD command
@TXT_NOISY    equ $-TXT_NOISY-1 ; Length of ...
TXT_ON	     db 'on',0          ; WKD command
@TXT_ON       equ $-TXT_ON-1	; Length of ...
TXT_OFF      db 'off',0         ; WKD command
@TXT_OFF      equ $-TXT_OFF-1	; Length of ...
TXT_SKIP     db 'skip',0        ; WKD command
@TXT_SKIP     equ $-TXT_SKIP-1	; Length of ...
TXT_TRAPON   db 'trapon',0      ; WKD command
@TXT_TRAPON   equ $-TXT_TRAPON-1 ; Length of ...
TXT_TRAPOFF  db 'trapoff',0     ; WKD command
@TXT_TRAPOFF  equ $-TXT_TRAPOFF-1 ; Length of ...

DATA	ends			; End DATA segment


KEYSEG	segment use32 word public 'data' ; Start KEYSEG segment
	assume	ds:DGROUP

	public	@SWAT_I68_KEYSEG
@SWAT_I68_KEYSEG label byte	; Mark module start in .MAP file

	public	WKDVAL
WKDVAL	label	word

KEYSEG	ends			; End KEYSEG segment


ACTSEG	segment use32 dword public 'data' ; Start ACTSEG segment
	assume	ds:DGROUP

	public	@SWAT_I68_ACTSEG
@SWAT_I68_ACTSEG label byte	; Mark module start in .MAP file

	public	WKDACT
WKDACT	label	dword

ACTSEG	ends			; End ACTSEG segment


	KSTMAC	ESC	 , DISP_WKD_ESC
	KSTMAC	UP	 , DISP_WKD_UP
	KSTMAC	XUP	 , DISP_WKD_UP
	KSTMAC	SHF_UP	 , DISP_WKD_UP
	KSTMAC	DN	 , DISP_WKD_DN
	KSTMAC	XDN	 , DISP_WKD_DN
	KSTMAC	SHF_DN	 , DISP_WKD_DN
	KSTMAC	CR	 , DISP_WKD_CR
	KSTMAC	PADENTER , DISP_WKD_CR


KEYSEG	segment use32 word public 'data' ; Start KEYSEG segment
	assume	ds:DGROUP

	public	NWKDVAL
NWKDVAL equ	($-WKDVAL)/(type WKDVAL) ; # valid keystrokes

KEYSEG	ends			; End KEYSEG segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP,ds:PGROUP

	public	@SWAT_I68_PROG
@SWAT_I68_PROG: 		; Mark module start in .MAP file

	extrn	SWATINI:tbyte
	include MAXDEV.INC

	extrn	SET_GDT:near
	extrn	SEL2BASE:near
	extrn	LIN2PHYS:near
	extrn	GET_TOKN:near
	extrn	CHECK_TOKN:near
	extrn	CMD_WHITE:near

	extrn	LCL_INTCOM_DEVDONE:near
	extrn	LCL_INTCOM_DEVORIG:near

	extrn	BIN2WORD:near
	extrn	BIN2DWORD:near

	extrn	WPUT_SA:near
	extrn	WPUT_CSA:near
	extrn	WPUT_SHD1:near
	extrn	GETKEY:near
	extrn	SET_STATE:near
	extrn	DISP_CMDLINE:near
	extrn	CLEAR_CMDLINE:near
	extrn	ENDOF_CMDLINE:near
	extrn	PARSE_EXPR:near

	extrn	SetRVM:near
	extrn	SetPMG:near
	extrn	SetPMI:near
	extrn	PushOldInt:near
	extrn	SetSelVars:near
	extrn	MASK_STKREGS:near

	FPPROC	PM_WKDCB -- PM Windows Kernel Callback
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Windows kernel debugger callback
This routine is called in PM only.

This is the extended memory version of PMINIT (as the WDEB386 docs
call it).

The initial calls to PMINIT are made with AL = (0, 2, 5, 6, 4, 7) or
(0, 2, 5, 1, 3, 4, 7).	Calls 0, 1, 2, 5, 6 are made in low DOS and
are handled by DEV_WKDCB.  After function 1 is called, the base of
the code selector is changed to be in extended memory, so the rest
of the calls are handled by PM_WKDCB in extended memory.

On entry:

AL	=	3:  Set spare PTE
  EBX	=	linear address of spare PTE contents
  EDX	=	linear address of spare PTE

AL	=	4:  Set VMM routine address
  EBX	=	Enter VMM routine address
  ECX	=	Exit ...
  EDX	=	_Trace_Out_Service
  ESI	=	_Debug_Out_Service

AL	=	7:  Enable memory context functions

|

	cmp	al,@PMINIT_INIT_SPARE_PTE ; Izit Set Spare PTE?
	je	short PM_WKDCB_SETPTE ; Jump if so

	cmp	al,@PMINIT_SET_ENTER_EXIT_VMM ; Izit Set VMM enter/exit routines?
	je	short PM_WKDCB_SETVMM ; Jump if so

	cmp	al,@PMINIT_ENABLE_MEMORY_CONTEXT ; Izit Enable memory context functions?
	je	near ptr PM_WKDCB_MEMCNTXT ; Jump if so

	int	03h		; Not handled as yet *FIXME*

	jmp	short PM_WKDCB_EXIT ; Join common exit code


COMMENT|

Set spare PTE

On entry:

AL	=	3
EBX	=	linear address of spare PTE contents
EDX	=	linear address of spare PTE

|

PM_WKDCB_SETPTE:
	REGSAVE <eax,edx,ds,es> ; Save for a moment

	mov	ax,cs		; Get code selector
	add	ax,size DESC_STR ; Skip to data selector
	mov	ds,ax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	mov	LaSparePTE,edx	; Save for later use
	mov	LaPtrSparePTE,ebx ; ...

; Copy DEVINT41_FVEC to OLDINT41_FVEC for TOGINT 41

	mov	es,COMMON.FILE_4GB ; Get all memory selector
	assume	es:RGROUP	; Tell a white lie

	movzx	edx,RGRSEG2	; Get low DOS memory segment
	shl	edx,4-0 	; Convert from paras to bytes

	mov	eax,DEVINT41_FVEC.FOFF[edx] ; Get the offset
	mov	OLDINT41_FVEC.FOFF,eax ; Save for later use
	mov	ax,DEVINT41_FVEC.FSEL[edx] ; Get the selector
	mov	OLDINT41_FVEC.FSEL,ax ; Save for later use
	mov	al,DEVINT41_ARB[edx] ; Get A/R byte
	mov	OLDINT41_ARB,al ; Save for later use

	assume	es:nothing	; Retract nose

	REGREST <es,ds,edx,eax> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	jmp	short PM_WKDCB_EXIT ; Join common exit code


COMMENT|

Set VMM enter/exit routines

On entry:

AL	=	4
EBX	=	Enter VMM routine address
ECX	=	Exit ...
EDX	=	_Trace_Out_Service
ESI	=	_Debug_Out_Service

|

PM_WKDCB_SETVMM:
	REGSAVE <eax,ds>	; Save for a moment

	mov	ax,cs		; Get code selector
	add	ax,size DESC_STR ; Skip to data selector
	mov	ds,ax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	mov	EnterVMM,ebx	; Save for later use
	mov	ExitVMM,ecx	; ...
	mov	_Trace_Out_Service,edx ; ...
	mov	_Debug_Out_Service,esi ; ...

	REGREST <ds,eax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	jmp	short PM_WKDCB_EXIT ; Join common exit code


COMMENT|

Enable memory context functions

On entry:

AL	=	7

|

PM_WKDCB_MEMCNTXT:
;;;;;;; jmp	short PM_WKDCB_EXIT ; Join common exit code
;;;;;;;
PM_WKDCB_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PM_WKDCB endp			; End PM_WKDCB procedure
	FPPROC	LCL_RVM68 -- Local Windows Kernel RM Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local INT 68h handler from RM/VCPI mode.

|

	call	SetRVM		; Set RM/VCPI mode

	jmp	short LCL_INT68_COM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_RVM68 endp			; End LCL_RVM68 procedure
	FPPROC	LCL_PMG68 -- Local Windows Kernel RM Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local INT 68h handler from PM Interrupt Gate mode.

|

	call	SetPMG		; Set PM Interrupt gate mode

	jmp	short LCL_INT68_COM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_PMG68 endp			; End LCL_PMG68 procedure
	FPPROC	LCL_INT68 -- Local Windows Kernel RM Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local Windows Kernel RM Handler

This routine may be called from RM or PM.

Troll for the following calls:

AH	=     * 43 Debugger identification
	=     * 44 Prepare for PM operation
	=     * 45 Re-init for RM as Windows is about to exit
	=	46 Set debugging switches
	=	47 Conditional break
	=     * 48 Undefine RM segment's symbols
	=	49 Set COM port baud rate
	=	4A Re-initialize debugger for PM
	=	4B Define debugger's segments
	=	4C Define COM port #
	=	4D Link SYM file map
	=	4E Unlink SYM file maps
	=     * 4F Remove any undefined segments from the module's symbols
	=     * 50 Define a segment/selector for symbol processing
	=	51 Display a character to debugging window
	=	52 Display an ASCIIZ string to the debugging window
	=	53 Is debug vXD installed?
	=	54 Set debug VxD installed
	=	55 Registers dot command
	=	56 De-registers dot command
	=	57 Printf
	=	58 Link symbol file with physical address
	=	59 Pointer to module name
	=	5A Autoload symbols on/off
	=	5B TEFTI port address
	=	5C Execute debugger command script
	=	5D Copy debugger code/data high
	=	5E Sets Windows version #
	=	5F Scan for character
	=	60 Ungetchar
	=	61 Stop at CS:IP

*	=	actually seen

|

I68ARG_STR struc

	dd	?		; ...	   EIP
	dw	?		; ...	   CS
I68ARG_LDT dw	?		; ...	   LDT

I68ARG_STR ends

	call	SetPMI		; Set PM Intrude mode

	public	LCL_INT68_COM
LCL_INT68_COM:
	sldt	[esp].I68ARG_LDT ; In case we're called from PM

	sub	esp,size FORW_RET ; Make room for pseudo-return CS:EIP

	pushad			; Save all EGP registers
	mov	ebp,esp 	; Address the stack

; SS:EBP ==>	FORW_STR

	cld			; String ops forwardly

	push	ds		; Save register

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	call	SetSelVars	; Set selector variables
	call	MASK_STKREGS	; Mask off the high-order word of stack
				; registers if 16-bit stack
; See if we're still active

	test	WKD_FLAG,@WKD_ENABLE ; Izit enabled?
	jz	near ptr LCL_INT68_ORIG  ; Jump if not (Continue with the original handler)

	cmp	ah,@I68_IDENTIFY ; Izit debugger identification?
	je	short LCL_INT68_IDENTIFY ; Jump if so

	cmp	ah,@I68_PREPARE_PM ; Izit prepare for PM operation?
	je	short LCL_INT68_IPROT ; Jump if so

	cmp	ah,@I68_RM_INIT ; Izit prepare for PM termination?
	je	near ptr LCL_INT68_RPROT ; Jump if so

;;;;;;; cmp	ah,@I68_SET_SW	; Izit set debugging switches?
;;;;;;; je	near ptr LCL_INT68_ORIG ; Jump if so
;;;;;;;
;;;;;;; cmp	ah,@I68_EXEC_COND ; Izit conditional break?
;;;;;;; je	near ptr LCL_INT68_CBRK ; Jump if so
;;;;;;;
	cmp	ah,@I68_FREE_SEG ; Izit undefine RM segment's symbols?
	je	near ptr LCL_INT68_FREESEG ; Jump if so

;;;;;;; cmp	ah,@I68_SET_BAUD ; Izit set COM port baud rate?
;;;;;;; je	near ptr LCL_INT68_ORIG ; Jump if so
;;;;;;;
;;;;;;; cmp	ah,@I68_REINIT	; Izit re-initialize debugger for PM?
;;;;;;; je	near ptr LCL_INT68_ORIG ; Jump if so
;;;;;;;
;;;;;;; cmp	ah,@I68_DEFDSEGS ; Izit define debugger's segments?
;;;;;;; je	near ptr LCL_INT68_ORIG ; Jump if so
;;;;;;;
;;;;;;; cmp	ah,@I68_SET_PORT ; Izit define COM port #?
;;;;;;; je	near ptr LCL_INT68_ORIG ; Jump if so
;;;;;;;
;;;;;;; cmp	ah,@I68_LINK_SYM ; Izit link SYM file map?
;;;;;;; je	near ptr LCL_INT68_ORIG ; Jump if so
;;;;;;;
;;;;;;; cmp	ah,@I68_UNLINK_SYM ; Izit unlink SYM file maps?
;;;;;;; je	near ptr LCL_INT68_ORIG ; Jump if so
;;;;;;;
	cmp	ah,@I68_REM_SEGS ; Izit remove any undefined segments from the module's symbols?
	je	near ptr LCL_INT68_REMOVESEG ; Jump if so

	cmp	ah,@I68_LOAD_SEG ; Izit define a segment/selector for symbol processing?
	je	near ptr LCL_INT68_DSYM ; Jump if so

;;;;;;; cmp	ah,@I68_DISP_CHAR ; Izit display a character to debugging window?
;;;;;;; je	near ptr LCL_INT68_DCHR ; Jump if so
;;;;;;;
;;;;;;; cmp	ah,@I68_DISP_STR ; Izit Display an ASCIIZ string to the debugging window?
;;;;;;; je	near ptr LCL_INT68_DSTR ; Jump if so
;;;;;;;
	int	03h		; Not handled as yet *FIXME*

	jmp	LCL_INT68_ORIG	; Continue with the original handler


COMMENT|

Debugger identification (called from RM/VM/PM)

On entry:

AH	=	43h

On exit:

AX	=	@DEB_PRESENT (if present)

|

LCL_INT68_IDENTIFY:
	mov	[ebp].FORW_EAX.ELO,@DEB_PRESENT ; Mark as present

	jmp	LCL_INT68_DONE	; Join common exit code


COMMENT|

Prepare for PM operation (called from RM/VM)

On entry:

AH	=	44h
AL	=	0 (retail version of Windows)
	=	1 (debugging version of Windows)
	=	2 (286 DOS extender, Windows 3.0)
	=	3 (286 DOS extender, Windows 3.1 under VCPI)
	=	4 (286 DOS extender, Windows 3.1)
BX	=	all memory selector (when in PM)
CX	=	first of three selectors reserved for our use
DX	=	GDT selector (when in PM)
DS:SI	==>	GDT
if AL > 1
ES:DI	==>	IDT
endif

On exit:

if AL < 2
ES:EDI	==>	PM callback
endif

|

LCL_INT68_IPROT:

; Return our PM callback address if AL = 0 or 1

	mov	WKD_WINDBG,al	; Save as debugging (1) or retail (0) version

	cmp	al,2		; Izit non-VCPI mode?
	jae	short @F	; Jump if not

	mov	[ebp].FORW_ES,cx ; Return as callback selector
	mov	[ebp].FORW_EDI,offset RGROUP:RSWAT_WKDCB ; ... offset
@@:
	push	gs		; Save for a moment

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

; If this is VCPI mode, setup INT 41h in the IDT

	cmp	al,2		; Izit VCPI mode?
	jb	short LCL_INT68_IPROT1 ; Jump if not

	movzx	eax,[ebp].FORW_ES ; Get caller's ES
	shl	eax,4-0 	; Convert from paras to bytes
	movzx	edi,[ebp].FORW_EDI.ELO ; Get caller's DI
	add	edi,eax 	; Add to get IDT linear address

; Fill in INT 41h to catch messages
; save the old address in DEVINT41_FVEC

	push	ecx		; Save for a moment

	lea	eax,RSWAT_INT41 ; Get the offset
	xchg	AGROUP:[edi+41h*(type IDT_STR)].IDT_OFFLO,ax ; Save low-order word
	ror	eax,16		; Rotate down the high-order word
	xchg	AGROUP:[edi+41h*(type IDT_STR)].IDT_OFFHI,ax ; Save high-order word
	rol	eax,16		; Rotate back
	xchg	AGROUP:[edi+41h*(type IDT_STR)].IDT_SELECT,cx ; Save selector

	assume	gs:RGROUP	; Tell a white lie
	mov	DEVINT41_FVEC[edx].FOFF,eax ; Save to restore later
	mov	DEVINT41_FVEC[edx].FSEL,cx ; ...
	assume	gs:AGROUP	; Retract nose

	mov	al,CPL0_INTR3 or DPL3 ; Set A/R byte
	xchg	AGROUP:[edi+41h*(type IDT_STR)].IDT_ACCESS,al ; Set A/R byte

	assume	gs:RGROUP	; Tell a white lie
	mov	DEVINT41_ARB[edx],al ; ...
	assume	gs:AGROUP	; Retract nose

	pop	ecx		; Restore
LCL_INT68_IPROT1:
	movzx	edx,RGRSEG2	; Get low DOS memory segment
	shl	edx,4-0 	; Convert from paras to bytes

	PUSHD	ds		; Selector we're interested in
	call	SEL2BASE	; Return with EAX == selector base address
	mov	SWATDATA,eax	; Save for later use
	call	LIN2PHYS	; EAX = physical address of SWAT's data segment

	assume	gs:RGROUP	; Tell a white lie
	mov	WKD_SWATPHYS_DS[edx],eax ; Save for later use
	assume	gs:AGROUP	; Retract nose

	PUSHD	cs		; Selector we're interested in
	call	SEL2BASE	; Return with EAX == selector base address
	mov	SWATCODE,eax	; Save for later use
	call	LIN2PHYS	; EAX = physical address of SWAT's code segment

	assume	gs:RGROUP	; Tell a white lie
	mov	WKD_SWATPHYS_CS[edx],eax ; Save for later use
	assume	gs:AGROUP	; Retract nose

	assume	gs:RGROUP	; Tell a white lie
	mov	WKD_AGRSEL[edx],bx ; Save the incoming 4GB selector
	assume	gs:AGROUP	; Retract nose

	movzx	eax,[ebp].FORW_DS ; Get caller's DS
	shl	eax,4-0 	; Convert from paras to bytes
	movzx	esi,[ebp].FORW_ESI.ELO ; Get caller's SI
	add	esi,eax 	; Add to get 32-bit linear address of GDT
	movzx	ecx,cx		; Zero to use as dword
	add	esi,ecx 	; Add to get location of our GDT entries

; 1:  Install our code selector
;     Note that we use the base of RGROUP and the limit of CS as we'll
;	change to the correct base after W's PTEs are setup.

	movzx	eax,RGRSEG2	; Get low DOS memory segment
	shl	eax,4-0 	; Convert from paras to bytes
	mov	ecx,cs		; Get our code selector
	lsl	ecx,ecx 	; Get segment limit
	call	SET_GDT 	; Set GDT entry GS:ESI to EAX limit ECX

	mov	AGROUP:[esi].DESC_ACCESS,CPL0_CODE ; Set ARB

; 2:  Install our data selector

;;;;;;; movzx	eax,RGRSEG2	; Get low DOS memory segment
;;;;;;; shl	eax,4-0 	; Convert from paras to bytes
	add	esi,size DESC_STR ; Skip to data selector
	mov	ecx,ds		; Get our data selector
	lsl	ecx,ecx 	; Get segment limit
	call	SET_GDT 	; Set GDT entry GS:ESI to EAX limit ECX

	mov	AGROUP:[esi].DESC_ACCESS,CPL0_DATA ; Set ARB
	or	AGROUP:[esi].DESC_SEGLM1,mask $DTE_B ; Set B-bit for stack refs

; 3:  Install our CR3 selector

	add	esi,size DESC_STR ; Skip to CR3 selector
	xor	eax,eax 	; We don't know the address as yet
	mov	ecx,0FFFFEFFFh	; Large limit (can't use 4GB as PTEs won't display)
	call	SET_GDT 	; Set GDT entry GS:ESI to EAX limit ECX

	mov	AGROUP:[esi].DESC_ACCESS,CPL0_DATA ; Set ARB

	pop	gs		; Restore
	assume	gs:nothing	; Tell the assembler about it

	jmp	LCL_INT68_DONE	; Join common exit code


COMMENT|

Prepare for PM termination

This function is handled by the Win CB Enable (AX=1).

On entry:

AH	=	45h

|

LCL_INT68_RPROT:
	jmp	LCL_INT68_DONE	; Join common exit code


COMMENT|

Conditional break

On entry:

AH	=	47h
ES:SI	==>	ASCIIZ string to display

On exit:

Nothing

|

LCL_INT68_CBRK:
;;;;;;; int	03h		; Not handled as yet *FIXME*

	jmp	LCL_INT68_DONE	; Join common exit code


COMMENT|

Undefine RM segment's symbols

On entry:

AH	=	48h
BX	=	RM segment to undefine

On exit:

Nothing

|

LCL_INT68_FREESEG:
	mov	ecx,WKDLS_NEXT	; Get next index
	jecxz	LCL_INT68_FREESEG_EXIT ; Jump if nothing to do
	mov	ebx,PWKDLS	; Get offset in DGROUP of WKDLS entries
	mov	ax,[ebp].FORW_EBX.ELO ; Get the segment to undefine
LCL_INT68_FREESEG_NEXT:
	test	DGROUP:[ebx].WKDLS_FLAG,@WKDLS_RM ; Izit RM?
	jz	short LCL_INT68_FREESEG_LOOP ; Jump if not

	cmp	ax,DGROUP:[ebx].WKDLS_SEL ; Duzit match?
	jne	short LCL_INT68_FREESEG_LOOP ; Jump if not

; Move down the next entries

	REGSAVE <eax,ecx,es>	; Save for a moment

	SETDATA es		; Set data selector into ES
	assume	es:DGROUP	; Tell the assembler about it

	mov	edi,ebx 	; DGROUP:EDI ==> destin
	lea	esi,[edi+(type WKDLS_STR)] ; DGROUP:ESI ==> source
	dec	ecx		; Less one entry
	imul	ecx,type WKDLS_STR ; Get # bytes to move
    rep movs	DGROUP:[edi].LO,DGROUP:[esi].LO ; Copy downwards

; Clear out the last entry moved down

	mov	al,0		; Clear to this value
	mov	ecx,type WKDLS_STR ; Get # bytes to clear
    rep stos	DGROUP:[edi].LO ; Clear it

	dec	WKDLS_NEXT	; Count it out

	REGREST <es,ecx,eax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	sub	ebx,type WKDLS_STR ; Obviate next instruction
LCL_INT68_FREESEG_LOOP:
	add	ebx,type WKDLS_STR ; Skip to next entry

	loopd	LCL_INT68_FREESEG_NEXT ; Jump if more entries to check
LCL_INT68_FREESEG_EXIT:
	jmp	LCL_INT68_DONE	; Join common exit code


COMMENT|

Remove any undefined segments from the module's symbols

This routine looks at all of the maps that are
currently linked and removes the ones that were
loaded with this ID.

On entry:

AH	=	4Fh
BX	=	Loader ID

On exit:

Nothing

|

LCL_INT68_REMOVESEG:
;;;;;;; int	03h		; Not handled as yet *FIXME*

	jmp	LCL_INT68_DONE	; Join common exit code


COMMENT|

Define segment/selector for symbol processing

On entry:

AH	=	50h
AL	=	type
	=	00h = code selector
	=	01h = data ...
	=	10h = code segment
	=	11h = data ...
	=	40h = code segment & selector
	=	41h = data ...
	=	80h = device driver code segment
	=	81h = ...	    data ...
	=	90h = ...	    real mode segment

Note that for Win95, the values for 80h and 81h
are inexplicably reversed.

if AL < 80h
BX	=	logical segment # from EXE file
CX	=	actual segment/selector
DX	=	actual selector (if AL=40h or 41h)
ES:DI	==>	pointer to module name
else
ES:DI	==>	device load parameters
endif

On exit:

AL	=	1 if successful
	=	0 if not

|

LCL_INT68_DSYM:
	push	gs		; Save for a moment

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

	mov	ebx,WKDLS_NEXT	; Get next index

	cmp	ebx,WKDLS_CNT	; Room for one more?
	jae	short LCL_INT68_DSYM_ERR ; Jump if not

	imul	ebx,type WKDLS_STR ; Get offset into table
	add	ebx,PWKDLS	; Plus offset of start of table

	mov	al,[ebp].FORW_EAX.ELO.LO ; Get segment type

	cmp	al,@ST_code_sel ; Izit code selector (00h)?
	mov	ah,@WKDLS_CODE	; Assume so
	je	short LCL_INT68_DSYM_STORE ; Jump if so

	cmp	al,@ST_data_sel ; Izit data selector (01h)?
	mov	ah,@WKDLS_DATA	; Assume so
	je	short LCL_INT68_DSYM_STORE ; Jump if so

	cmp	al,@ST_code_seg ; Izit code segment (10h)?
	mov	ah,@WKDLS_RM or @WKDLS_CODE ; Assume so
	je	short LCL_INT68_DSYM_STORE ; Jump if so

	cmp	al,@ST_data_seg ; Izit data segment (11h)?
	mov	ah,@WKDLS_RM or @WKDLS_DATA ; Assume so
	je	short LCL_INT68_DSYM_STORE ; Jump if so

	cmp	al,@ST_dual_code ; Izit code segment & selector (40h)?
	mov	ah,@WKDLS_CODE	; Assume so
	je	short LCL_INT68_DSYM_STORE ; Jump if so

	cmp	al,@ST_dual_data ; Izit data segment & selector (41h)?
	mov	ah,@WKDLS_DATA	; Assume so
	je	short LCL_INT68_DSYM_STORE ; Jump if so

	cmp	al,@ST_device_code ; Izit device driver code selector (80h)?
	mov	ah,@WKDLS_CODE	; Assume so
	je	short LCL_INT68_DSYM_DPSTORE ; Jump if so

	cmp	al,@ST_device_data ; Izit device driver data selector (81h)?
	mov	ah,@WKDLS_DATA	; Assume so
	je	short LCL_INT68_DSYM_DPSTORE ; Jump if so

	cmp	al,@ST_VxD_RM_seg ; Izit device driver real mode segment (90h)?
	mov	ah,@WKDLS_RM	; Assume so
	je	short LCL_INT68_DSYM_DPSTORE1 ; Jump if so

	int	03h		; Not handled as yet *FIXME*
LCL_INT68_DSYM_ERR:
	mov	[ebp].FORW_EAX.ELO.LO,0 ; Mark as unsuccessful

	jmp	LCL_INT68_DSYM_EXIT ; Join common exit code

COMMENT|

AL	<	80h
BX	=	segment #
CX	=	actual segment/selector
DX	=	actual selector (if AL = 40h or 41h)
ES:DI	==>	module name

|

LCL_INT68_DSYM_STORE:
	xchg	al,ah		; Swap to WKDLS_REC order
	mov	DGROUP:[ebx].WKDLS_FLAG,ax ; Save as flag

	movzx	eax,[ebp].FORW_ECX.ELO ; Get the actual segment/selector
	mov	DGROUP:[ebx].WKDLS_SEL,ax ; Save for later use

	test	DGROUP:[ebx].WKDLS_FLAG,@WKDLS_RM ; Izit RM?
	jnz	short @F	; Jump if so

	movzx	eax,[ebp].FORW_EBX.ELO ; Get the segment #
@@:
	shl	eax,4-0 	; Convert from paras to bytes
	mov	DGROUP:[ebx].WKDLS_BASE,eax ; Save as base address
	mov	DGROUP:[ebx].WKDLS_LEN,0FFFFh ; Set to maximum length

	mov	al,[ebp].FORW_EAX.ELO.LO ; Get segment type

	cmp	al,@ST_dual_code ; Izit dual segment & sel?
	jb	short @F	; Jump if not

	cmp	al,@ST_dual_data ; Izit dual segment & sel?
	ja	short @F	; Jump if not

	mov	ax,[ebp].FORW_EDX.ELO ; Get the actual selector
	mov	DGROUP:[ebx].WKDLS_SEL,ax ; Save for later use
@@:

; Calculate incoming module name linear address

	movzx	edx,[ebp].FORW_ES ; Get the RM/VM segment
	shl	edx,4-0 	; Convert from paras to bytes
	movzx	eax,[ebp].FORW_EDI.ELO ; Get the offset
	add	edx,eax 	; Add to get linear address

	mov	eax,AGROUP:[edx].EDQLO ; Get low-order dword
	mov	DGROUP:[ebx].WKDLS_SNAME.EDQLO,eax ; Save for later use

	mov	eax,AGROUP:[edx].EDQHI ; Get high-order dword
	mov	DGROUP:[ebx].WKDLS_SNAME.EDQHI,eax ; Save for later use

	jmp	LCL_INT68_DSYM_OK ; Join common OK code


COMMENT|

AL	>=	80h
ES:DI	==>	D386_Device_Params struc

|

LCL_INT68_DSYM_DPSTORE:
	movzx	edx,RGRSEG2	; Get low DOS memory segment
	shl	edx,4-0 	; Convert from paras to bytes

	assume	gs:RGROUP	; Tell a white lie
	cmp	DEV_WINVER[edx],0400h ; Izit Windows version 4.00 (Win95) or later?
	assume	gs:AGROUP	; Retract nose
	jb	short @F	; Jump if not

	xor	ah,@WKDLS_CODE	; Switch code and data
@@:
LCL_INT68_DSYM_DPSTORE1:
	xchg	al,ah		; Swap to WKDLS_REC order
	mov	DGROUP:[ebx].WKDLS_FLAG,ax ; Save as flag

; Calculate incoming D386_Device_Params struc linear address

	movzx	edx,[ebp].FORW_ES ; Get the RM/VM segment
	shl	edx,4-0 	; Convert from paras to bytes
	movzx	eax,[ebp].FORW_EDI.ELO ; Get the offset
	add	edx,eax 	; Add to get linear address

; Save incoming data in local table

	mov	ax,AGROUP:[edx].DD_logical_seg ; Get logical segment # from map
	mov	DGROUP:[ebx].WKDLS_LSEG,ax ; Save for later use

	mov	ax,AGROUP:[edx].DD_actual_sel ; Get actual selector value
	mov	DGROUP:[ebx].WKDLS_SEL,ax ; Save for later use

	mov	eax,AGROUP:[edx].DD_base ; Get linear address for start of segment

	test	DGROUP:[ebx].WKDLS_FLAG,@WKDLS_RM ; Izit RM?
	jz	short @F	; Jump if not

	movzx	eax,DGROUP:[ebx].WKDLS_SEL ; Get the actual segment value
	shl	eax,4-0 	; Convert from paras to bytes
@@:
	mov	DGROUP:[ebx].WKDLS_BASE,eax ; Save for later use

	mov	eax,AGROUP:[edx].DD_length ; Get actual length of segment
	mov	DGROUP:[ebx].WKDLS_LEN,eax ; Save for later use

	mov	ax,AGROUP:[edx].DD_alias_sel ; Get alias selector value (0 = none)
	mov	DGROUP:[ebx].WKDLS_ALIAS,ax ; Save for later use

; Save the device name

	movzx	ecx,AGROUP:[edx].DD_name.FSEL ; Get segment
	shl	ecx,4-0 	; Convert from paras to bytes
	mov	eax,AGROUP:[edx].DD_name.FOFF ; Get offset
	add	ecx,eax 	; Add to get linear address

	mov	eax,AGROUP:[ecx].EDQLO ; Get low-order dword
	mov	DGROUP:[ebx].WKDLS_DNAME.EDQLO,eax ; Save for later use

	mov	eax,AGROUP:[ecx].EDQHI ; Get high-order dword
	mov	DGROUP:[ebx].WKDLS_DNAME.EDQHI,eax ; Save for later use

; Save the module name

	movzx	ecx,AGROUP:[edx].DD_sym_name.FSEL ; Get segment
	shl	ecx,4-0 	; Convert from paras to bytes
	mov	eax,AGROUP:[edx].DD_sym_name.FOFF ; Get offset
	add	ecx,eax 	; Add to get linear address

	mov	eax,AGROUP:[ecx].EDQLO ; Get low-order dword
	mov	DGROUP:[ebx].WKDLS_SNAME.EDQLO,eax ; Save for later use

	mov	eax,AGROUP:[ecx].EDQHI ; Get high-order dword
	mov	DGROUP:[ebx].WKDLS_SNAME.EDQHI,eax ; Save for later use
LCL_INT68_DSYM_OK:
	mov	[ebp].FORW_EAX.ELO.LO,1 ; Mark as successful
	inc	WKDLS_NEXT	; Skip to next entry
LCL_INT68_DSYM_EXIT:
	pop	gs		; Restore
	assume	gs:nothing	; Tell the assembler about it

	jmp	short LCL_INT68_DONE ; Join common exit code


COMMENT|

Display a character in debug window

On entry:

AH	=	51h
AL	=	character to display

|

LCL_INT68_DCHR:
	int	03h		; Not handled as yet *FIXME*

	jmp	short LCL_INT68_DONE ; Join common exit code


COMMENT|

Display an ASCIIZ string in debug window

On entry:

AH	=	52h
ES:SI	==>	ASCIIZ string to display

|

LCL_INT68_DSTR:
	int	03h		; Not handled as yet *FIXME*

	jmp	short LCL_INT68_DONE ; Join common exit code


LCL_INT68_DONE:
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it
	popad			; ...

	add	esp,size FORW_RET ; Strip off pseudo-return address

	test	[esp].DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVDONE ; Jump if so

	iretd			; Return to caller


; Continue with the original handler

LCL_INT68_ORIG:
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it
	popad			; ...

	add	esp,size FORW_RET ; Strip off pseudo-return address

	pushfd			; Save EFL
	PUSHW	ds		; Save for a moment

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	test	[esp].LCLINT_NXT.DEVSTK_EFL.EHI,mask $VM ; Izit from VM86?
	jz	short @F	; Jump if not

	test	[esp].LCLINT_NXT.DEVSTK_EFL,mask $R2 ; Izit from RM?
	jnz	near ptr LCL_INTCOM_DEVORIG ; Jump if so
@@:

; At this point, only EFL and DS are extra on the stack
; DS serves as the high-order filler of the selector

	OLDINT_MAC 68		; Push old interrupt vactors
;;;;;;; push	OLDINT68_FVEC.FSEL ; Save selector in low-order word
;;;;;;; push	OLDINT68_FVEC.FOFF ; ...  offset in next dword

INT68_STR struc

INT68_FOFF dd	?		; Old offset
INT68_FSEL dw	?		; ... selector
INT68_DS   dw	?		; ... DS
INT68_EFL  dd	?		; ... EFL (IF=TF=0)

INT68_STR ends

	mov	ds,[esp].INT68_DS ; Restore caller's DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Continue with original handler

	jmp	near ptr LCL_INT68 ; In case we're returning from a TSS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT68 endp			; End LCL_INT68 procedure
	NPPROC	CMD_WKD -- Set WKD State
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT!

Set Windows Kernel Debugger state.

WKD [ON|OFF]
WKD [QUIET|NOISY]
WKD LOGERROR [QUIET|NOISY|TRAPON|TRAPOFF]
WKD PARAMERROR [QUIET|NOISY]
WKD VXDLOAD [QUIET|NOISY]
WKD FAULT [ON|OFF|SKIP]
WKD WCB [ON|OFF}
WKD PMINIT

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

!

	REGSAVE <eax,ebx,edi>	; Save registers

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	or	al,al		; Izit the end of the line?
	jz	near ptr CMD_WKD_SYNTERR ; Jump if so

	movzx	ebx,RGRSEG2	; Get low DOS memory segment
	shl	ebx,4-0 	; Convert from paras to bytes

	call	GET_TOKN	; Get next token into CMD_TOKN

	lea	edi,TXT_PMINIT	; Check for 'pminit'
	call	CHECK_TOKN	; Check for ES:EDI in token
	je	near ptr CMD_WKD_PMINIT ; Jump if so

	lea	edi,TXT_FAULT	; Check for 'fault'
	call	CHECK_TOKN	; Check for ES:EDI in token
	je	near ptr CMD_WKD_FAULT ; Jump if so

	lea	edi,TXT_LOGERROR ; Check for 'logerror'
	call	CHECK_TOKN	; Check for ES:EDI in token
	je	near ptr CMD_WKD_LOGERR ; Jump if so

	lea	edi,TXT_PARAMERROR ; Check for 'paramerror'
	call	CHECK_TOKN	; Check for ES:EDI in token
	je	near ptr CMD_WKD_PARAMERR ; Jump if so

	lea	edi,TXT_VXDLOAD ; Check for 'vxdload'
	call	CHECK_TOKN	; Check for ES:EDI in token
	je	near ptr CMD_WKD_VXDLOAD ; Jump if so

	lea	edi,TXT_QUIET	; Check for 'quiet'
	call	CHECK_TOKN	; Check for ES:EDI in token
	je	near ptr CMD_WKD_QUIET ; Jump if so

	lea	edi,TXT_NOISY	; Check for 'noisy'
	call	CHECK_TOKN	; Check for ES:EDI in token
	je	near ptr CMD_WKD_NOISY ; Jump if so

	lea	edi,TXT_ON	; Check for 'on'
	call	CHECK_TOKN	; Check for ES:EDI in token
	je	near ptr CMD_WKD_ON ; Jump if so

	lea	edi,TXT_OFF	; Check for 'off'
	call	CHECK_TOKN	; Check for ES:EDI in token
	jne	near ptr CMD_WKD_SYNTERR ; Jump if not (not allowed)
;;;_WKD_OFF:
;;;;;;; add	esi,@TXT_OFF	; Skip over 'off'

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Is Windows active?
	jnz	near ptr CMD_WKD_NOWINERR ; Jump if so (not allowed)

	and	WKD_FLAG,not @WKD_ENABLE ; Indicate WKD is disabled
	assume	gs:RGROUP	; Tell a white lie
	and	TRP_FLAG[ebx],not (@TRP_I68 or @TRP_WCB) ; Disable trapping for
				; Windows Kernel Debugger services in RM
	assume	gs:AGROUP	; Retract nose

	jmp	CMD_WKD_DONE	; Join common done code


CMD_WKD_ON:
;;;;;;; add	esi,@TXT_ON	; Skip over 'on'

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Is Windows active?
	jnz	near ptr CMD_WKD_NOWINERR ; Jump if so (not allowed)

	or	WKD_FLAG,@WKD_ENABLE ; Indicate WKD is enabled
	assume	gs:RGROUP	; Tell a white lie
	or	TRP_FLAG[ebx],@TRP_I68 or @TRP_WCB ; Enable trapping for
				; Windows Kernel Debugger services in RM
	assume	gs:AGROUP	; Retract nose
CMD_WKD_DONE:
	clc			; Mark as successful

	jmp	CMD_WKD_EXIT	; Join common exit code


CMD_WKD_VXDLOAD:
	add	esi,@TXT_VXDLOAD ; Skip over 'vxdload'

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	or	al,al		; Izit the end of the line?
	jz	near ptr CMD_WKD_SYNTERR ; Jump if so

	call	GET_TOKN	; Get next token into CMD_TOKN

	lea	edi,TXT_QUIET	; Check for 'quiet'
	call	CHECK_TOKN	; Check for ES:EDI in token
	je	near ptr CMD_WKD_VXDLOAD_QUIET ; Jump if so

	lea	edi,TXT_NOISY	; Check for 'noisy'
	call	CHECK_TOKN	; Check for ES:EDI in token
	jne	near ptr CMD_WKD_SYNTERR ; Jump if not

;;;;;;; add	esi,@TXT_NOISY	; Skip over 'noisy'

	and	WKD_FLAG,not @WKD_VXDL ; Turn it off

	jmp	CMD_WKD_DONE	; Join common done code


CMD_WKD_VXDLOAD_QUIET:
;;;;;;; add	esi,@TXT_QUIET	; Skip over 'quiet'

	or	WKD_FLAG,@WKD_VXDL ; Turn it on

	jmp	CMD_WKD_DONE	; Join common done code


CMD_WKD_PARAMERR:
	add	esi,@TXT_PARAMERROR ; Skip over 'paramerror'

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	or	al,al		; Izit the end of the line?
	jz	near ptr CMD_WKD_SYNTERR ; Jump if so

	call	GET_TOKN	; Get next token into CMD_TOKN

	lea	edi,TXT_QUIET	; Check for 'quiet'
	call	CHECK_TOKN	; Check for ES:EDI in token
	je	near ptr CMD_WKD_PARAMERR_QUIET ; Jump if so

	lea	edi,TXT_NOISY	; Check for 'noisy'
	call	CHECK_TOKN	; Check for ES:EDI in token
	jne	near ptr CMD_WKD_SYNTERR ; Jump if not

;;;;;;; add	esi,@TXT_NOISY	; Skip over 'noisy'

	and	WKD_FLAG,not @WKD_PEQ ; Turn it off

	jmp	CMD_WKD_DONE	; Join common done code


CMD_WKD_PARAMERR_QUIET:
;;;;;;; add	esi,@TXT_QUIET	; Skip over 'quiet'

	or	WKD_FLAG,@WKD_PEQ ; Turn it on

	jmp	CMD_WKD_DONE	; Join common done code


CMD_WKD_LOGERR:
	add	esi,@TXT_LOGERROR ; Skip over 'logerror'

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	or	al,al		; Izit the end of the line?
	jz	near ptr CMD_WKD_SYNTERR ; Jump if so

	call	GET_TOKN	; Get next token into CMD_TOKN

	lea	edi,TXT_QUIET	; Check for 'quiet'
	call	CHECK_TOKN	; Check for ES:EDI in token
	je	near ptr CMD_WKD_LOGERR_QUIET ; Jump if so

	lea	edi,TXT_NOISY	; Check for 'noisy'
	call	CHECK_TOKN	; Check for ES:EDI in token
	je	near ptr CMD_WKD_LOGERR_NOISY ; Jump if so

	lea	edi,TXT_TRAPON	; Check for 'trapon'
	call	CHECK_TOKN	; Check for ES:EDI in token
	je	short CMD_WKD_LOGERR_TRAPON ; Jump if so

	lea	edi,TXT_TRAPOFF ; Check for 'trapoff'
	call	CHECK_TOKN	; Check for ES:EDI in token
	jne	near ptr CMD_WKD_SYNTERR ; Jump if not

;;;;;;; add	esi,@TXT_TRAPOFF ; Skip over 'trapoff'

	and	WKD_FLAG,not @WKD_LOGERR ; Turn it off

	jmp	CMD_WKD_DONE	; Join common done code


CMD_WKD_LOGERR_TRAPON:
;;;;;;; add	esi,@TXT_TRAPON ; Skip over 'trapon'

	or	WKD_FLAG,@WKD_LOGERR ; Turn it on

	jmp	CMD_WKD_DONE	; Join common done code


CMD_WKD_LOGERR_QUIET:
;;;;;;; add	esi,@TXT_QUIET	; Skip over 'quiet'

	or	WKD_FLAG,@WKD_LEQ ; Turn it on

	jmp	CMD_WKD_DONE	; Join common done code


CMD_WKD_LOGERR_NOISY:
;;;;;;; add	esi,@TXT_NOISY	; Skip over 'noisy'

	and	WKD_FLAG,not @WKD_LEQ ; Turn it off

	jmp	CMD_WKD_DONE	; Join common done code


CMD_WKD_PMINIT:
	add	esi,@TXT_PMINIT ; Skip over 'pminit'

	or	WKD_FLAG,@WKD_PMINIT ; Turn it on

	jmp	CMD_WKD_DONE	; Join common done code


CMD_WKD_FAULT:
	add	esi,@TXT_FAULT	; Skip over 'fault'

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	or	al,al		; Izit the end of the line?
	jz	near ptr CMD_WKD_SYNTERR ; Jump if so

	call	GET_TOKN	; Get next token into CMD_TOKN

	lea	edi,TXT_SKIP	; Check for 'skip'
	call	CHECK_TOKN	; Check for ES:EDI in token
	je	short CMD_WKD_FAULT_SKIP ; Jump if so

	lea	edi,TXT_ON	; Check for 'on'
	call	CHECK_TOKN	; Check for ES:EDI in token
	je	short CMD_WKD_FAULT_ON ; Jump if so

	lea	edi,TXT_OFF	; Check for 'off'
	call	CHECK_TOKN	; Check for ES:EDI in token
	jne	near ptr CMD_WKD_SYNTERR ; Jump if not

	and	WKD_FLAG,not (@WKD_FLTON or @WKD_FLTSK) ; Turn it off

	jmp	CMD_WKD_DONE	; Join common done code


CMD_WKD_FAULT_SKIP:
	or	WKD_FLAG,@WKD_FLTSK ; Tell 'em to ship the next one
CMD_WKD_FAULT_ON:
	or	WKD_FLAG,@WKD_FLTON ; Turn it on

	jmp	CMD_WKD_DONE	; Join common done code


CMD_WKD_QUIET:
;;;;;;; add	esi,@TXT_QUIET	; Skip over 'quiet'

	or	WKD_FLAG,@WKD_QUIET ; Tell 'em to shut up

	jmp	CMD_WKD_DONE	; Join common done code


CMD_WKD_NOISY:
;;;;;;; add	esi,@TXT_NOISY	; Skip over 'noisy'

	and	WKD_FLAG,not @WKD_QUIET ; Tell 'em to speak up

	jmp	CMD_WKD_DONE	; Join common done code


CMD_WKD_NOWINERR:
	mov	MSGOFF,offset DGROUP:NOWINERR ; Save offset of error message

	jmp	short CMD_WKD_ERR ; Join common error exit code


CMD_WKD_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

;;;;;;; jmp	short CMD_WKD_ERR ; Join common error exit code


CMD_WKD_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_WKD_EXIT:
	REGREST <edi,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_WKD endp			; End CMD_WKD procedure
	NPPROC	DISP_WKD -- Display WKD Menu
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display WKD menu

|

	pushad			; Save registers

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	jz	near ptr DISP_WKD_WINERR ; Jump if not

	test	WKD_FLAG,@WKD_ENABLE ; Is WKD enabled?
	jz	near ptr DISP_WKD_WINERR ; Jump if not

; Display the menu choices

	mov	al,HLPATTR	; Get help attribute
	push	ax		; Pass as attribute to smear
	push	offset ds:MSG_WKD ; Pass address of local buffer
	push	offset ds:W_WKD ; Pass address of window descriptor
	call	WPUT_CSA	; Output the characters, smear attribute

; Display a shadow below and to the right of the help screen

	push	offset ds:W_WKD ; Pass address of window descriptor
	call	WPUT_SHD1	; Display a type 1 shadow

; Display the menu choices in a separate color

	mov	al,HLPBATTR	; Get background help line attribute
	push	ax		; Pass attribute to smear
	push	offset ds:W_KASK ; Pass address of window descriptor
	call	WPUT_SA 	; Smear attribute
DISP_WKD_NEXT:
	mov	al,HLPAATTR	; Get active help line attribute
	push	ax		; Pass attribute to smear
	push	offset ds:W_KLIN ; Pass address of window descriptor
	call	WPUT_SA 	; Smear attribute

	call	GETKEY		; Wait for keystroke, return in AX

	lea	edi,WKDVAL	; ES:EDI ==> valid keystrokes
	mov	ecx,NWKDVAL	; ECX = # valid keystrokes
  repne scas	WKDVAL[edi]	; Search for it
	jne	short DISP_WKD_NEXT ; Jump if invalid

	mov	al,HLPBATTR	; Get background help line attribute
	push	ax		; Pass attribute to smear
	push	offset ds:W_KLIN ; Pass address of window descriptor
	call	WPUT_SA 	; Smear attribute

	sub	edi,(type WKDVAL)+offset DGROUP:WKDVAL ; Convert to origin-0 in units of words
LOG2 LOG2@WKDVAL,<type WKDVAL>
	shr	edi,LOG2@WKDVAL ; Divide by two to index table of bytes

	jmp	WKDACT[edi*(type WKDACT)]  ; Take appropriate action


DISP_WKD_UP:
	dec	WKDIND		; Skip to previous row
	jns	short @F	; Jump if no wrap

	mov	WKDIND,@KLIN_LEN - 1 ; Wrap to the end
@@:
	jmp	short DISP_WKD_COM ; Join common code


DISP_WKD_DN:
	inc	WKDIND		; Skip to next row

	cmp	WKDIND,@KLIN_LEN - 1 ; Izit above the end?
	jbe	short @F	; Jump if no wrap

	mov	WKDIND,0	; Wrap to the start
@@:
DISP_WKD_COM:
	mov	eax,@KLIN_SROW	; Get starting row #
	add	eax,WKDIND	; Plus current index
	mov	W_KLIN.SROW,ax	; Save as new starting row

	jmp	DISP_WKD_NEXT	; Go around again


DISP_WKD_CR:
	mov	esi,WKDIND	; Get the current topic index

	jmp	WKDTOP_ACT[esi*(type WKDTOP_ACT)] ; Take appropriate action


; Display Windows Global Heap entries

DISP_WKD_WGH:
	mov	al,@DSP_WGH	; Screen state is WGH
	call	SET_STATE	; Set new state

	jmp	DISP_WKD_EXIT	; Join common exit code


; Display the Windows EXE Head

DISP_WKD_EXE:
	push	fs		; Save for a moment

	verr	KVARS_VEC.VSEG	; Izit valid?
	jnz	short @F	; Jump if not

	lfs	si,KVARS_VEC	; FS:SI ==> KVARS_STR
	assume	fs:nothing	; Tell the assembler about it

	mov	ax,fs:[si].KV_hExeHead ; Get the selector
	mov	MDBSEL,ax	; Save as MDB selector

	mov	al,@DSP_MDB	; Screen state is MDB
	call	SET_STATE	; Set new state
@@:
	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler about it

	jmp	DISP_WKD_EXIT	; Join common exit code


; Display the Windows Top Process Database

DISP_WKD_TOPPDB:
	call	CLEAR_CMDLINE	; Clear the command line
	call	ENDOF_CMDLINE	; Return with ES:EDI ==> end of the command line
	assume	es:DGROUP	; Tell the assembler about it

	mov	ax,' d'         ; Get display command
	stos	es:[edi].ELO	; Save in command line

	push	fs		; Save for a moment

	verr	KVARS_VEC.VSEG	; Izit valid?
	jnz	short @F	; Jump if not

	lfs	si,KVARS_VEC	; FS:SI ==> KVARS_STR
	assume	fs:nothing	; Tell the assembler about it

	mov	ax,fs:[si].KV_topPDB ; Get the selector
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	jmp	short DISP_WKD_TOPPDB1 ; Join common code


@@:
	mov	eax,'????'      ; No selector
	stos	es:[edi].EDD	; Save in command line
DISP_WKD_TOPPDB1:
	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler about it

	mov	ax,'0|'         ; Get |0
	stos	es:[edi].ELO	; Save in command line

;;;;;;; jmp	DISP_WKD_CMD	; Join common code


DISP_WKD_CMD:
	mov	al,0		; Get EOL
	stos	es:[edi].LO	; Save in command line

	call	DISP_CMDLINE	; Re-display the command line

	jmp	DISP_WKD_EXIT	; Join common exit code


; Display the Windows Head Process Database

DISP_WKD_HEADPDB:
	call	CLEAR_CMDLINE	; Clear the command line
	call	ENDOF_CMDLINE	; Return with ES:EDI ==> end of the command line
	assume	es:DGROUP	; Tell the assembler about it

	mov	ax,' d'         ; Get display command
	stos	es:[edi].ELO	; Save in command line

	push	fs		; Save for a moment

	verr	KVARS_VEC.VSEG	; Izit valid?
	jnz	short @F	; Jump if not

	lfs	si,KVARS_VEC	; FS:SI ==> KVARS_STR
	assume	fs:nothing	; Tell the assembler about it

	mov	ax,fs:[si].KV_headPDB ; Get the selector
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	jmp	short DISP_WKD_HEADPDB1 ; Join common code


@@:
	mov	eax,'????'      ; No selector
	stos	es:[edi].EDD	; Save in command line
DISP_WKD_HEADPDB1:
	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler about it

	mov	ax,'0|'         ; Get |0
	stos	es:[edi].ELO	; Save in command line

	jmp	DISP_WKD_CMD	; Join common code


; Display the Windows Head Task Database

DISP_WKD_HEADTDB:
	push	fs		; Save for a moment

	verr	KVARS_VEC.VSEG	; Izit valid?
	jnz	short DISP_WKD_TDB_ERR ; Jump if not

	lfs	si,KVARS_VEC	; FS:SI ==> KVARS_STR
	assume	fs:nothing	; Tell the assembler about it

	mov	ax,fs:[si].KV_headTDB ; Get the selector

	jmp	short DISP_WKD_TDBCOM ; Join common code


; Display the Windows Current Task Database

DISP_WKD_CURTDB:
	push	fs		; Save for a moment

	verr	KVARS_VEC.VSEG	; Izit valid?
	jnz	short DISP_WKD_TDB_ERR ; Jump if not

	lfs	si,KVARS_VEC	; FS:SI ==> KVARS_STR
	assume	fs:nothing	; Tell the assembler about it

	mov	ax,fs:[si].KV_curTDB ; Get the selector
DISP_WKD_TDBCOM:
	mov	TDBSEL,ax	; Save as TDB selector

	mov	al,@DSP_TDB	; Screen state is TDB
	call	SET_STATE	; Set new state
DISP_WKD_TDB_ERR:
	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler about it

	jmp	DISP_WKD_EXIT	; Join common exit code


; Display the Windows Z-order

DISP_WKD_ZORD:
	call	CLEAR_CMDLINE	; Clear the command line
	call	ENDOF_CMDLINE	; Return with ES:EDI ==> end of the command line
	assume	es:DGROUP	; Tell the assembler about it

	mov	ax,' d'         ; Get display command
	stos	es:[edi].ELO	; Save in command line

	push	fs		; Save for a moment

	verr	KVARS_VEC.VSEG	; Izit valid?
	jnz	short DISP_WKD_ZORD_ERR ; Jump if not

	lfs	si,KVARS_VEC	; FS:SI ==> KVARS_STR
	assume	fs:nothing	; Tell the assembler about it

	mov	ax,fs:[si].KV_pGlobalHeap ; Get selector of Global Heap
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	al,'|'          ; Get separator
	stos	es:[edi].LO	; Save in command line

	lfs	si,UVARS.UV_lphwndDesktop ; FS:SI ==> offset in Global Heap
	assume	fs:nothing	; Tell the assembler about it

	mov	eax,fs:[si]	; Get offset in Global Heap
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	jmp	short DISP_WKD_ZORD1 ; Join common code


DISP_WKD_ZORD_ERR:
	mov	eax,'????'      ; No selector
	stos	es:[edi].EDD	; Save in command line

	mov	al,'|'          ; Get separator
	stos	es:[edi].LO	; Save in command line

	mov	eax,'????'      ; No offset
	stos	es:[edi].EDD	; Save in command line
DISP_WKD_ZORD1:
	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler about it

	jmp	DISP_WKD_CMD	; Join common code


; Display the memory pointed to by the hHmenu Selector

DISP_WKD_MENUSEL:
	call	CLEAR_CMDLINE	; Clear the command line
	call	ENDOF_CMDLINE	; Return with ES:EDI ==> end of the command line
	assume	es:DGROUP	; Tell the assembler about it

	mov	ax,' d'         ; Get display command
	stos	es:[edi].ELO	; Save in command line

	push	fs		; Save for a moment

	lfs	si,UVARS.UV_lphHmenuSel ; FS:SI ==> hHmenuSel
	assume	fs:nothing	; Tell the assembler about it

	mov	ax,fs:[si]	; Get the selector
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,'0|'         ; Get separator and zero
	stos	es:[edi].LO	; Save in command line

	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler about it

	jmp	DISP_WKD_CMD	; Join common code


; Display the memory pointed to by the hHwnd Selector

DISP_WKD_WNDSEL:
	call	CLEAR_CMDLINE	; Clear the command line
	call	ENDOF_CMDLINE	; Return with ES:EDI ==> end of the command line
	assume	es:DGROUP	; Tell the assembler about it

	mov	ax,' d'         ; Get display command
	stos	es:[edi].ELO	; Save in command line

	push	fs		; Save for a moment

	lfs	si,UVARS.UV_lphHwndSel ; FS:SI ==> hHwndSel
	assume	fs:nothing	; Tell the assembler about it

	mov	ax,fs:[si]	; Get the selector
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,'0|'         ; Get separator and zero
	stos	es:[edi].LO	; Save in command line

	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler about it

	jmp	DISP_WKD_CMD	; Join common code


; Display the Windows Class List

DISP_WKD_CLS:
	call	CLEAR_CMDLINE	; Clear the command line
	call	ENDOF_CMDLINE	; Return with ES:EDI ==> end of the command line
	assume	es:DGROUP	; Tell the assembler about it

	mov	ax,' d'         ; Get display command
	stos	es:[edi].ELO	; Save in command line

	mov	ax,UVARS.UV_lppclsList.VSEG
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	al,'|'          ; Get separator
	stos	es:[edi].LO	; Save in command line

	mov	ax,UVARS.UV_lppclsList.VOFF
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	jmp	DISP_WKD_CMD	; Join common code


; Display the Windows DCE First (Device Context Entry)

DISP_WKD_DCE:
	call	CLEAR_CMDLINE	; Clear the command line
	call	ENDOF_CMDLINE	; Return with ES:EDI ==> end of the command line
	assume	es:DGROUP	; Tell the assembler about it

	mov	ax,' d'         ; Get display command
	stos	es:[edi].ELO	; Save in command line

	mov	ax,UVARS.UV_lppdceFirst.VSEG
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	al,'|'          ; Get separator
	stos	es:[edi].LO	; Save in command line

	mov	ax,UVARS.UV_lppdceFirst.VOFF
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	jmp	DISP_WKD_CMD	; Join common code


DISP_WKD_WINERR:
	mov	MSGOFF,offset DGROUP:WINERR ; Save offset of error message

;;;;;;; jmp    short DISP_WKDERR_COM ; Join common code


DISP_WKDERR_COM:
	or	LC2_FLAG,mask $LC2_MSG ; Mark as message to display
DISP_WKD_ESC:
DISP_WKD_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_WKD endp			; End DISP_WKD procedure
	NPPROC	IPF_FIND -- Find IPF Entry
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Find an IPF entry

On entry:

IPF_VAL =	value to find

On exit:

CF	=	0 if found (ESI ==> matching entry)
	=	1 if not found (ESI ==> next available entry)
ESI	==>	offset in DGROUP of matching/next entry

|

	REGSAVE <eax,ecx>	; Save registers

	lea	esi,IPFTAB[4]	; DS:ESI ==> start of table
	mov	ecx,IPFTAB	; Get # available entries
	jecxz	IPF_FIND_VNF	; Jump if no entries

	mov	eax,IPF_VAL	; Get the linear address
IPF_FIND_NEXT:
	cmp	eax,DGROUP:[esi].SWAT_IPF_LinAddr ; Duzit match?
	je	short IPF_FIND_EXIT ; Jump if so (note CF=0)

	add	esi,type SWAT_IPF_STR ; Skip to next entry

	loop	IPF_FIND_NEXT	; Jump if more entries to check

; Value not found

IPF_FIND_VNF:
	stc			; Mark as not found
IPF_FIND_EXIT:
	REGREST <ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IPF_FIND endp			; End IPF_FIND procedure
	NPPROC	CMD_IPF -- Set IPF Table
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Set IPF table entries.

IPF [/d] [/s] [/r] expr Add/remove entry to/from table
IPF			Display the table's entries

where /d = Do not display message when this entry is encountered
      /s = Do not stop when this entry is encountered
      /r = Remove this entry

Note that the switches must come first so as to avoid
confusing them with the divide symbol in the expression.

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	pushad			; Save all EGP registers

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	jz	near ptr CMD_IPF_ERR_NOWIN ; Jump if not

	xor	edi,edi 	; Initialize switch flags
CMD_IPF_NEXT1:
	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	or	al,al		; Izit the end of the line?
	jz	near ptr CMD_IPF_DONE ; Jump if so

	cmp	al,'/'          ; Izit a switch?
	je	short CMD_IPF_SWITCH ; Jump if so

	cmp	al,'!'          ; Izit a switch?
	je	short CMD_IPF_SWITCH ; Jump if so

	call	PARSE_EXPR	; Parse command line for expression
	jc	near ptr CMD_IPF_SYNTERR ; Jump if something went wrong (note CF=1)

	mov	IPF_VAL,eax	; Save for later use

	bts	edi,$SWAT_IPF_EXPR ; Mark as expression found
	jc	near ptr CMD_IPF_SYNTERR ; Jump if already set

	jmp	CMD_IPF_NEXT1	; Go around again


CMD_IPF_SWITCH:
	inc	esi		; Skip over the switch char

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	inc	esi		; Skip over it

	cmp	al,'d'          ; Izit don't display?
	je	short CMD_IPF_DISP ; Jump if so

	cmp	al,'s'          ; Izit don't stop?
	je	short CMD_IPF_STOP ; Jump if so

	cmp	al,'r'          ; Izit a removal?
	je	short CMD_IPF_DELE ; Jump if so

	jmp	CMD_IPF_SYNTERR ; Join common error code


CMD_IPF_DELE:
	or	edi,@SWAT_IPF_DELE ; Mark as delete this entry

	jmp	CMD_IPF_NEXT1	; Go around again


CMD_IPF_DISP:
	or	edi,@SWAT_IPF_XDISP ; Mark as don't display

	jmp	CMD_IPF_NEXT1	; Go around again


CMD_IPF_STOP:
	or	edi,@SWAT_IPF_XSTOP ; Mark as don't stop

	jmp	CMD_IPF_NEXT1	; Go around again


CMD_IPF_DONE:
	and	edi,edi 	; Any flags set?
	jz	short CMD_IPF_SHOW ; Jump if not

	btr	edi,$SWAT_IPF_EXPR ; Is there an expression?
	jnc	short CMD_IPF_SYNTERR ; Jump if not

	btr	edi,$SWAT_IPF_DELE ; Izit a deletion?
	jnc	short CMD_IPF_ADD ; Jump if not

; Search for this entry and delete it

	call	IPF_FIND	; Search for IPF_VAL
				; Return with ESI ==> offset in DGROUP of
				; matching/next entry
	jc	short CMD_IPF_ERR_VNF ; Jump if not found

	mov	edi,esi 	; ES:EDI ==> entry to delete
	lea	esi,[edi+(type SWAT_IPF_STR)] ; DS:ESI ==> next valid entry
	imul	ecx,IPFTAB,type SWAT_IPF_STR ; Get size of table
	lea	ecx,IPFTAB[ecx+4] ; ECX ==> end of table
	sub	ecx,esi 	; Less source to get # bytes to move
    rep movs	DGROUP:[edi].LO,DGROUP:[esi].LO ; Move entries down

	dec	IPFTAB		; Count out this entry

	jmp	short CMD_IPF_CLC ; Join common code


; Search for this entry and change flags if found

CMD_IPF_ADD:
	call	IPF_FIND	; Search for IPF_VAL
				; Return with ESI ==> offset in DGROUP of
				; matching/next entry
	jnc	short CMD_IPF_SETFLAGS ; Jump if found

	cmp	IPFTAB,@SWAT_IPF_LEN ; Izit full?
	je	short CMD_IPF_ERR_FULL ; Jump if so

	mov	eax,IPF_VAL	; Get the linear address
	mov	DGROUP:[esi].SWAT_IPF_LinAddr,eax ; Save in table
	inc	IPFTAB		; Count in this entry
CMD_IPF_SETFLAGS:
	mov	DGROUP:[esi].SWAT_IPF_Flags,edi ; Save as new flags

	jmp	short CMD_IPF_CLC ; Join common code


CMD_IPF_SHOW:			; *FIXME*





CMD_IPF_CLC:
	clc			; Mark as successful

	jmp	short CMD_IPF_EXIT ; Join common exit code

CMD_IPF_ERR_FULL:
	mov	MSGOFF,offset DGROUP:FULLERR ; Save offset of error message

	jmp    short CMD_IPF_ERRCOM ; Join common code

CMD_IPF_ERR_VNF:
	mov	MSGOFF,offset DGROUP:VNFERR ; Save offset of error message

	jmp    short CMD_IPF_ERRCOM ; Join common code

CMD_IPF_ERR_NOWIN:
	mov	MSGOFF,offset DGROUP:NOWINERR ; Save offset of error message

	jmp    short CMD_IPF_ERRCOM ; Join common code

CMD_IPF_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

;;;;;;; jmp	short CMD_IPF_ERRCOM ; Join common error exit code

CMD_IPF_ERRCOM:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_IPF_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_IPF endp			; End CMD_IPF procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_I68 module
