;' $Header:   P:/PVCS/386SWAT/SWAT_I41.ASV   1.0   10 Aug 1998 11:01:06   BOB  $
	title	SWAT_I41 -- 386SWAT Windows Kernel Debugging, INT 41h
	page	58,122
	name	SWAT_I41

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-1999 Qualitas, Inc.  All rights reserved.

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
	include ALLMEM.INC
	include ASCII.INC
	include SWATVXD.INC
	include WINSTR.INC
	include OPCODES.INC
	include EXE.INC
	include WKD.INC
	include DEBUGSYS.INC

	include SWAT_CMD.INC
	include SWAT_COM.INC
	include SWAT_FMT.INC
	include SWAT_SEG.INC
	include SWAT_SYM.INC
	include QMAX_FIL.INC
.list


DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	public	@SWAT_I41_DATA16
@SWAT_I41_DATA16 label byte	; Mark module start in .MAP file

	extrn	COMMON:tbyte
;;;;;;; include QMAX_FIL.INC

	extrn	LC3_FLAG:dword
	include SWAT_LC3.INC

	extrn	LC4_FLAG:dword
	include SWAT_LC4.INC

	extrn	SWATINFO:byte
	include SWAT_INF.INC

	extrn	SWATDATA:dword

	extrn	PWKDLS:dword

	extrn	SYMBASE:dword
	extrn	SYMNEXT:dword

	extrn	CMD_LINE_OFF:dword

	public	@I41STK_SIZE
@I41STK_UNIT equ 512		; INT 41h stack unit
@I41STK_SIZE equ 4 * @I41STK_UNIT ; INT 41h stack size

	public	I41STK_FVEC,OLDI41STK_FVEC
I41STK_FVEC df	?		; INT 41h Param Err stack
	dw	?		; For alignment
OLDI41STK_FVEC df ?		; Original ...
	dw	?		; For alignment

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	@SWAT_I41_DATA
@SWAT_I41_DATA label byte	; Mark module start in .MAP file

	extrn	WKD_FLAG:word
	include SWAT_WKD.INC

	extrn	WINBASE:dword
	extrn	BREAKPT_PTR:dword
	extrn	BREAKPT_VAL:byte
	extrn	BREAKPT_SEL:word
	extrn	BREAKPT_OFF:dword
	extrn	BREAKPT_FLAG:word
	extrn	SaveRegs:tbyte
	extrn	REENTRY:word
	extrn	WKDLS_NEXT:dword
	extrn	KVARS_VEC:dword
	extrn	UVARS:tbyte
	extrn	MSG_KVS:byte
	extrn	MSG_KVO:byte
	extrn	MSG_UVS:byte
	extrn	MSG_UVO:byte
	extrn	IPFTAB:dword
	extrn	WKD_WINDBG:byte

	public	BreakStr
BreakStr BreakStruc <>		; Ctrl-C struc

	public	RETVEC,CURBP
RETVEC	dd	?		; Return address for Parameter errors
CURBP	dw	?		; Current BP for ...

MSGTAB_STR struc

MSGTAB_INTNO dw ?		; Interrupt #
MSGTAB_PMSG  dd ?		; Offset in PGROUP of the message

MSGTAB_STR ends


MSGTAB_MAC macro NN,TXT

	MSGTAB_STR <NN,offset PGROUP:TXT>

	endm			; MSGTAB_MAC


	public	LCLMSGTAB
LCLMSGTAB label tbyte
	MSGTAB_MAC 00h,INT00_MSG1
;;;;;;; MSGTAB_MAC 01h,INT01_MSG1
	MSGTAB_MAC 02h,INT02_MSG1
;;;;;;; MSGTAB_MAC 03h,INT03_MSG1
	MSGTAB_MAC 05h,INT05_MSG1
	MSGTAB_MAC 06h,INT06_MSG1
;;;;;;; MSGTAB_MAC 08h,INT08_MSG1
	MSGTAB_MAC 0Ah,INT0A_MSG1
	MSGTAB_MAC 0Bh,INT0B_MSG1
	MSGTAB_MAC 0Ch,INT0C_MSG1
	MSGTAB_MAC 0Dh,INT0D_MSG1
	MSGTAB_MAC 0Eh,INT0E_MSG1
LCLMSG_LEN equ	($-LCLMSGTAB)/(type MSGTAB_STR) ; # entries
	MSGTAB_MAC ?  ,INTXX_MSG1

	align	4

	public	LOGTAB_ACT
LOGTAB_ACT dd	offset PGROUP:LCL_INT41_LOGERROR_NONE  ; 00
	   dd	offset PGROUP:LCL_INT41_LOGERROR_BYTE  ; 01
	   dd	offset PGROUP:LCL_INT41_LOGERROR_WORD  ; 10
	   dd	offset PGROUP:LCL_INT41_LOGERROR_DWORD ; 11

	public	ERRLOG_KEY
ERRLOG_KEY dw	?		; Keystroke from error log display
	dw	?		; For alignment

ERR_WARNING	     = 8000h
$ERR_WARNING	     = 15

ERR_PARAM	     = 4000h

ERR_SIZE_MASK	     = 3000h
$ERR_SIZE_MASK	     = 12
ERR_BYTE	     = 1000h
ERR_WORD	     = 2000h
ERR_DWORD	     = 3000h

;****** LogParamError() values

;* Generic parameter values
ERR_BAD_VALUE	     = 6001h
ERR_BAD_FLAGS	     = 6002h
ERR_BAD_INDEX	     = 6003h
ERR_BAD_DVALUE	     = 7004h
ERR_BAD_DFLAGS	     = 7005h
ERR_BAD_DINDEX	     = 7006h
ERR_BAD_PTR	     = 7007h
ERR_BAD_FUNC_PTR     = 7008h
ERR_BAD_SELECTOR     = 6009h
ERR_BAD_STRING_PTR   = 700Ah
ERR_BAD_HANDLE	     = 600Bh

;* KERNEL errors
ERR_GALLOC	     = 0001h
ERR_GREALLOC	     = 0002h
ERR_GLOCK	     = 0003h
ERR_LALLOC	     = 0004h
ERR_LREALLOC	     = 0005h
ERR_LLOCK	     = 0006h
ERR_ALLOCRES	     = 0007h
ERR_LOCKRES	     = 0008h
ERR_LOADMODULE	     = 0009h
ERR_BAD_HINSTANCE    = 6020h
ERR_BAD_HMODULE      = 6021h
ERR_BAD_GLOBAL_HANDLE= 6022h
ERR_BAD_LOCAL_HANDLE = 6023h
ERR_BAD_ATOM	     = 6024h
ERR_BAD_HFILE	     = 6025h

;* USER errors
ERR_CREATEDLG	     = 0040h
ERR_CREATEDLG2	     = 0041h
ERR_REGISTERCLASS    = 0042h
ERR_DCBUSY	     = 0043h
ERR_CREATEWND	     = 0044h
ERR_STRUCEXTRA	     = 0045h
ERR_LOADSTR	     = 0046h
ERR_LOADMENU	     = 0047h
ERR_NESTEDBEGINPAINT = 0048h
ERR_BADINDEX	     = 0049h
ERR_CREATEMENU	     = 004Ah
ERR_BAD_HWND	     = 6040h
ERR_BAD_HMENU	     = 6041h
ERR_BAD_HCURSOR      = 6042h
ERR_BAD_HICON	     = 6043h
ERR_BAD_HDWP	     = 6044h
ERR_BAD_CID	     = 6045h
ERR_BAD_HDRVR	     = 6046h

;* GDI errors
ERR_CREATEDC	     = 0080h
ERR_CREATEMETA	     = 0081h
ERR_DELOBJSELECTED   = 0082h
ERR_SELBITMAP	     = 0083h
ERR_BAD_COORDS	     = 7060h
ERR_BAD_GDI_OBJECT   = 6061h
ERR_BAD_HDC	     = 6062h
ERR_BAD_HPEN	     = 6063h
ERR_BAD_HFONT	     = 6064h
ERR_BAD_HBRUSH	     = 6065h
ERR_BAD_HBITMAP      = 6066h
ERR_BAD_HRGN	     = 6067h
ERR_BAD_HPALETTE     = 6068h
ERR_BAD_HMETAFILE    = 6069h


LOGTAB_STR struc

LOGTAB_ERR dd	?	; Error code
LOGTAB_TXT dd	?	; Offset in WGROUP of error text

LOGTAB_STR ends

LOGTAB_MAC macro ERR,TXT
	local	L1

	LOGTAB_STR <ERR,offset WGROUP:L1>

WTXT	segment use32 byte public 'wdata' ; Start WTXT segment
;;;;;;; assume	ds:WGROUP

L1	db	TXT,0

WTXT	ends			; End WTXT segment

	endm			; LOGTAB_MAC

	public	LOGTAB
LOGTAB	label	tbyte
LOGTAB_MAC ERR_BYTE		, <"Invalid 8-bit parameter = ">
LOGTAB_MAC ERR_WORD		, <"Invalid 16-bit parameter = ">
LOGTAB_MAC ERR_DWORD		, <"Invalid 32-bit parameter = ">
LOGTAB_MAC ERR_PARAM		, <"A parameter error occurred.">
LOGTAB_MAC ERR_BAD_VALUE	, <"Invalid value = ">
LOGTAB_MAC ERR_BAD_FLAGS	, <"Invalid flags = ">
LOGTAB_MAC ERR_BAD_INDEX	, <"Invalid index to Get/Set Class/Window Word/Long() = ">
LOGTAB_MAC ERR_BAD_DVALUE	, <"Invalid dword = ">
LOGTAB_MAC ERR_BAD_DFLAGS	, <"Invalid flags = ">
LOGTAB_MAC ERR_BAD_DINDEX	, <"Invalid index = ">
LOGTAB_MAC ERR_BAD_PTR		, <"Invalid ptr = ">
LOGTAB_MAC ERR_BAD_FUNC_PTR	, <"Invalid function ptr = ">
LOGTAB_MAC ERR_BAD_SELECTOR	, <"Invalid selector = ">
LOGTAB_MAC ERR_BAD_STRING_PTR	, <"Invalid string ptr = ">
LOGTAB_MAC ERR_BAD_HANDLE	, <"Invalid handle = ">
LOGTAB_MAC ERR_GALLOC		, <"GlobalAlloc() failed.">
LOGTAB_MAC ERR_GREALLOC 	, <"GlobalRealloc() Failed.">
LOGTAB_MAC ERR_GLOCK		, <"GlobalLock() failed.">
LOGTAB_MAC ERR_LALLOC		, <"LocalAlloc() failed.">
LOGTAB_MAC ERR_LREALLOC 	, <"LocalRealloc() failed.">
LOGTAB_MAC ERR_LLOCK		, <"LocalLock() failed.">
LOGTAB_MAC ERR_ALLOCRES 	, <"AllocResource() failed.">
LOGTAB_MAC ERR_LOCKRES		, <"LockResource () failed.">
LOGTAB_MAC ERR_LOADMODULE	, <"LoadModule() failed.">
LOGTAB_MAC ERR_BAD_HINSTANCE	, <"Invalid HINSTANCE = ">
LOGTAB_MAC ERR_BAD_HMODULE	, <"Invalid HMODULE = ">
LOGTAB_MAC ERR_BAD_GLOBAL_HANDLE, <"Invalid HGLOBAL = ">
LOGTAB_MAC ERR_BAD_LOCAL_HANDLE , <"Invalid HLOCAL = ">
LOGTAB_MAC ERR_BAD_ATOM 	, <"Invalid atom = ">
LOGTAB_MAC ERR_BAD_HFILE	, <"Invalid HFILE = ">
LOGTAB_MAC ERR_CREATEDLG	, <"CreateDialog() failed in LoadMenu().">
LOGTAB_MAC ERR_CREATEDLG2	, <"CreateDialog() failed in CreateWindow().">
LOGTAB_MAC ERR_REGISTERCLASS	, <"RegisterClass() failed -- already registered.">
LOGTAB_MAC ERR_DCBUSY		, <"Device context cache is full.">
LOGTAB_MAC ERR_CREATEWND	, <"CreateWindow() failed -- class not found.">
LOGTAB_MAC ERR_STRUCEXTRA	, <"Program is using unallocated space.">
LOGTAB_MAC ERR_LOADSTR		, <"LoadString() failed.">
LOGTAB_MAC ERR_LOADMENU 	, <"LoadMenu() failed.">
LOGTAB_MAC ERR_NESTEDBEGINPAINT , <"Program contains nested BeginPaint() calls.">
LOGTAB_MAC ERR_BADINDEX 	, <"Invalid index.">
LOGTAB_MAC ERR_CREATEMENU	, <"Could not create menu.">
LOGTAB_MAC ERR_BAD_HWND 	, <"Invalid HWND = ">
LOGTAB_MAC ERR_BAD_HMENU	, <"Invalid HMENU = ">
LOGTAB_MAC ERR_BAD_HCURSOR	, <"Invalid HCURSOR = ">
LOGTAB_MAC ERR_BAD_HICON	, <"Invalid HICON = ">
LOGTAB_MAC ERR_BAD_HDWP 	, <"Invalid HDWP = ">
LOGTAB_MAC ERR_BAD_CID		, <"Invalid CID = ">
LOGTAB_MAC ERR_BAD_HDRVR	, <"Invalid HDRVR = ">
LOGTAB_MAC ERR_CREATEDC 	, <"CreateCompatibleDC(), CreateDC() or CreateIC() failed.">
LOGTAB_MAC ERR_CREATEMETA	, <"CreateMetaFile() failed.">
LOGTAB_MAC ERR_DELOBJSELECTED	, <"Program is trying to delete a bitmap selected into a DC.">
LOGTAB_MAC ERR_SELBITMAP	, <"Program is trying to select a bitmap that is already selected.">
LOGTAB_MAC ERR_BAD_COORDS	, <"Invalid coordinates = ">
LOGTAB_MAC ERR_BAD_GDI_OBJECT	, <"Invalid HGDIOBJ = ">
LOGTAB_MAC ERR_BAD_HDC		, <"Invalid HDC = ">
LOGTAB_MAC ERR_BAD_HPEN 	, <"Invalid HPEN = ">
LOGTAB_MAC ERR_BAD_HFONT	, <"Invalid HFONT = ">
LOGTAB_MAC ERR_BAD_HBRUSH	, <"Invalid HBRUSH = ">
LOGTAB_MAC ERR_BAD_HBITMAP	, <"Invalid HBITMAP = ">
LOGTAB_MAC ERR_BAD_HRGN 	, <"Invalid HRGN = ">
LOGTAB_MAC ERR_BAD_HPALETTE	, <"Invalid HPALLETTE = ">
LOGTAB_MAC ERR_BAD_HMETAFILE	, <"Invalid HMETAFILE = ">
LOGTAB_LEN equ	($-LOGTAB)/(type LOGTAB_STR) ; # entries

; The following entry catches unknown error codes

LOGTAB_MAC ERR_WORD		, <"Unknown Logerror() code = ">

	public	LOGTAB_HDR
LOGTAB_HDR db	'様> Logerror() says:  ',0

	public	LOGTAB_WARN
LOGTAB_WARN db	'Warning:  ',0  ; Warning header

	public	LOGTAB_DATA
LOGTAB_DATA db	'____:____',CR,LF,0,0,0

	public	MSG_CRLF32
MSG_CRLF32 db	CR,LF,0

	public	PARAMMSG1,PARAMMSG2A,PARAMMSG2B
;;;;;;; db	'様> Parameter Error = xxxx, ret = xxxx:xxxx',CR,LF,0
;;;;;;; db	'    API = aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa+xxxx, Module = aaaaaaaa.aaa',CR,LF,0
;;;;;;; db	'12345678901234567890123456789012345678901234567890123456789012345678901234567890'


;;;;;;; db	'12345678901234567890123456789012345678901234567890123456789012345678901234567890'
;;;;;;; db	'様> Parameter Error = xxxx, Task = ????????',CR,LF,0
;;;;;;; db	'    aaaaaaaa.aaa @ xxxx:xxxx (aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa+xxxx)',CR,LF,0

PARAMMSG1 db	'様> Parameter Error = '
PARAMMSG1_ERR  db 'xxxx, Task = '
PARAMMSG1_TASK db '????????',0

PARAMMSG2A     db '    '
PARAMMSG2_MOD  db 'aaaaaaaa.aaa',0
PARAMMSG2B     db ' @ '
PARAMMSG2_RETS db 'xxxx:'
PARAMMSG2_RETO db 'xxxx',0

PARAMMSG2_SYM  db ' ('
PARAMMSG2_SYM1 db 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',0
PARAMMSG2_SYMLEN equ ($-PARAMMSG2_SYM)
PARAMMSG2_OFF  db '+'
PARAMMSG2_OFF1 db 'xxxxxxxx)',0

@PARAMERR_MAXOFF equ 1024	; Maximum offset allowed when displaying
				; parameter symbol name
	public	PARAMMSG_PRE
PARAMMSG_PRE db '    ',0        ; Prefix to param error display of error code

	public	LOADDLL_MSG
LOADDLL_MSG   db '様> Loading DLL at '
LOADDLL_CS    db 'xxxx:'
LOADDLL_IP    db 'xxxx, '
LOADDLL_TYPE  db 'xx header at '
LOADDLL_MOD   db 'xxxx:0, DGROUP = '
LOADDLL_DGR   db 'xxxx, named...',CR,LF,0

	public	MODNAME_PRE
MODNAME_PRE   db '    ',0
MODNAME_TAIL  db CR,LF,0

	public	FREESEG16_MSG
FREESEG16_MSG  db '様> Freeing 16-bit segment '
FREESEG16_MSG1 db 'xxxx',CR,LF,0

	public	FREESEG32_MSG
FREESEG32_MSG  db '様> Freeing 32-bit segment '
FREESEG32_MSG1 db 'xxxx - '
FREESEG32_MSG2 db '________',CR,LF,0,0 ; Note extra zero so we can use STOSD

	public	FREEMOD_MSG
FREEMOD_MSG  db '様> Freeing module at '
FREEMOD_MSG1 db 'xxxx:0, named...',CR,LF,0
FREEMOD_TAIL  db CR,LF,0

	public	EXITCALL_MSG
EXITCALL_MSG  db '様> Exit call code = '
EXITCALL_CODE db 'xx, module selector = '
EXITCALL_ADDR db 'xxxx, module name = '
EXITCALL_NAME db '????????',0
EXITCALL_TAIL db CR,LF,0

	public	VxDNAME_PRE
VxDNAME_PRE   db '様> Loaded VxD ',0
VxDNAME_MID   db ' module ',0

	public	VxDBASE_MSG
VxDBASE_MSG  db ' at '
VxDBASE_MSG1 db 'xxxx|'
VxDBASE_MSG2 db 'xxxxxxxx'
	     db ' len '
VxDBASE_MSG3 db 'xxxxxxxx'
	     db CR,LF,0

	public	DISPCHAR
DISPCHAR db	?,0		; Save area for DISPCHAR

	public	VxD_SYMC,VxD_SYMB
VxD_SYMC SYMC_STR <>
VxD_SYMB db	'xxxxxxxx_Codennnn'

	public	VxD_CODE,VxD_DATA
VxD_CODE db	'_Code'         ; Code prefix
VxD_DATA db	'_Data'         ; Data prefix
VxD_CDLEN equ	$-VxD_DATA	; Length of ...

	public	MSG_BIQ
MSG_BIQ db	'Break, Ignore, or Quiet [B/I/Q]?  ',BEL,CR,LF,0

	public	MSG_PRINTF
MSG_PRINTF db	10 dup (?)	; Output for "nnnnnnn"

	align	4		; Ensure dword-aligned

	public	PrintEGPHeader,PrintEGP
PrintEGPHeader db \
		'  EAX      EBX      ECX      EDX      ESI      EDI      EBP',CR,LF,0
PrintEGP db	'12345678 12345678 12345678 12345678 12345678 12345678 12345678',CR,LF,0
;;;;;;;;;;;;;;;;	  1	    2	      3 	4	  5	    6	      7
;;;;;;;;;;;;;;;; 1234567890123456789012345678901234567890123456789012345678901234567890123456789
	public	PrintSelHeader,PrintSel
PrintSelHeader	db \
		'  CS:EIP        SS:ESP       DS   ES   FS   GS    EFL   ',CR,LF,0
PrintSel db	'xxxx:xxxxxxxx xxxx:xxxxxxxx xxxx xxxx xxxx xxxx xxxxxxxx',CR,LF,0
	public	PrintXRnHeader,PrintXRn
PrintXRnHeader	db \
		'  CR0      CR2      CR3    Err  LDT   TR     GDT           IDT',CR,LF,0
PrintXRn db	'xxxxxxxx xxxxxxxx xxxxxxxx xxxx xxxx xxxx xxxx-xxxxxxxx xxxx-xxxxxxxx',CR,LF,0

	align	2

	public	WINVER
WINVER	dw	?		; Windows version #

	public	PF_XLATLO,PF_XLATHI
PF_XLATLO db	'0123456789abcdef'
PF_XLATHI db	'0123456789ABCDEF'

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP,ds:PGROUP

	public	@SWAT_I41_PROG
@SWAT_I41_PROG: 		; Mark module start in .MAP file

	extrn	SEL2BASE:near

	extrn	LDISPTXT:near
	extrn	SAVEMSG:far
	extrn	SWATTER:far
	extrn	BIN2BYTE:near
	extrn	BIN2WORD:near
	extrn	BIN2DWORD:near
	extrn	U32_BASE2BIN:near
	extrn	U32_LOWERCASE:near
	extrn	DD2DEC:near
	extrn	SYMAPPND_COM:near

	extrn	INT00_MSG1:byte
	extrn	INT02_MSG1:byte
	extrn	INT05_MSG1:byte
	extrn	INT06_MSG1:byte
	extrn	INT0A_MSG1:byte
	extrn	INT0B_MSG1:byte
	extrn	INT0C_MSG1:byte
	extrn	INT0D_MSG1:byte
	extrn	INT0E_MSG1:byte

	extrn	COPY_WGHOWNR:near

	extrn	StrLen:near
	extrn	SYMFILTER:near
	extrn	LCL_SYMSRCH:near

	extrn	READ_CR3:near
	extrn	LIN2PPDIR:near
	extrn	LIN2PPTE:near
	extrn	LIN2PPTEZ:near

	extrn	CopyWKDRegs:near

	extrn	U32_DisableDispAGP:near
	extrn	U32_EnableDispAGP:near

	public	Phys2LinBias
Phys2LinBias dd ?		; Windows' physical-to-linear bias

	public	INTXX_MSG1
INTXX_MSG1 db	'Unknown Fault',0

	public	GOTO_MSG
GOTO_MSG db	'INT 41h Goto',0

	NPPROC	INT41_GOTO -- Common Goto Routine
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common Goto routine to display fault error message and
set breakpoint at the faulting address.

|

INT41_GOTO_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
INT41_MSG_FVEC df ?		; Ptr to error message
	dw	?		; Filler
INT41_ERRCODE dd ?		; Error code
INT41_CSEIP_FVEC df ?		; Ptr to target CS:EIP
	dw	?		; Filler

INT41_GOTO_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	pushad			; Save registers
	REGSAVE <ds,gs> 	; ...

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	ds,eax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	push	[ebp].INT41_ERRCODE ; ... error code
	push	[ebp].INT41_MSG_FVEC.FSEL.EDD ; Pass segment of error message
	push	[ebp].INT41_MSG_FVEC.FOFF     ; ...  offset ...
	FCALLD	SAVEMSG 	; Call message save routine

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

	mov	cx,[ebp].INT41_CSEIP_FVEC.FSEL ; Get the selector we're interested in
	mov	ebx,[ebp].INT41_CSEIP_FVEC.FOFF ; ...	 offset ...

	push	ecx		; Pass the selector (as dword)
	call	SEL2BASE	; Return with EAX == selector base address

	mov	edx,eax 	; Copy base address
	add	edx,ebx 	; Add to get linear address

	mov	al,@OPCOD_INT3	; Breakpoint interrupt
	xchg	al,AGROUP:[edx] ; Swap with the 1st instruction byte

; In case we're dealing with a cached ROM on a 486, invalidate
; the cache before comparing the values.
;;;;;;;
;;;;;;; test	LC2_FLAG,@LC2_486 ; Izit a 486 or later?
;;;;;;; jz	short @F	; Jump if not
;;;;;;;
;;;;;;; WBINVD			; Write back and invalidate the cache
@@:
;;;;;;; cmp	AGROUP:[edx].LO,@OPCOD_INT3 ; Did it take?
;;;;;;; jne	short ???	; Jump if not
;;;;;;;
	mov	BREAKPT_SEL,cx	; Save the segment/selector
	mov	BREAKPT_OFF,ebx ; Save the offset
	mov	BREAKPT_PTR,edx ; Save the base address
	mov	BREAKPT_VAL,al	; Save to restore the next time
	mov	BREAKPT_FLAG,@ADDR_PM or @ADDR_INUSE or @ADDR_ENA ; Mark as PM, enabled, and in use
INT41_GOTO_EXIT:
	REGREST <gs,ds> 	; Restore
	assume	ds:nothing	; Tell the assembler about it
	assume	gs:nothing	; ...
	popad			; Restore

	pop	ebp		; Restore

	ret	8+4+8		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT41_GOTO endp 		; End INT41_GOTO procedure
	NPPROC	DISP_NAME -- Display A Name
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display an up to @PADLIM-character name
and pad it out to @PADLIM with blanks

On entry:

DS:ESI	==>	name to display

On exit:

|

	REGSAVE <eax,ecx,edx,esi> ; Save registers

@PADLIM equ	8		; Pad limit

	mov	ecx,@PADLIM	; Maximum # chars in name
@@:
	lods	DGROUP:[esi].LO ; Get next char

	and	al,al		; Izit EOL?
	jz	short @F	; Jump if so

	mov	dl,al		; Copy to output register
	mov	ax,@I41_OUT_CHAR ; Get function code to display char in DL
	int	41h		; Request WKD service

	loop	@B		; Jump if more chars
@@:
	jecxz	DISP_NAME_EXIT	; Jump if nothing remains

	mov	dl,' '          ; Get char to display
@@:
	mov	ax,@I41_OUT_CHAR ; Get function code to display char in DL
	int	41h		; Request WKD service

	loop	@B		; Jump if more blanks to display
DISP_NAME_EXIT:
	REGREST <esi,edx,ecx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_NAME endp			; End DISP_NAME procedure
	NPPROC	APPEND_VxDSYMB -- Append A VxD Symbol
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Append a VxD symbol

On entry:

DGROUP:EBX ==>	WKDLS_STR entry

|

	pushad			; Save all EGP registers

; Copy the VxD name to a local buffer

	lea	edi,VxD_SYMB	; ES:EDI ==> local buffer
	lea	esi,DGROUP:[ebx].WKDLS_DNAME ; DS:ESI ==> name to copy
	mov	ecx,8		; Maximum # chars in name
@@:
	lods	DGROUP:[esi].LO ; Get next char

	and	al,al		; Izit EOL?
	jz	short @F	; Jump if so

	stos	DGROUP:[edi].LO ; Save in local buffer

	loop	@B		; Jump if more chars
@@:

; Append 'Code' or 'Data' as appropriate

	test	DGROUP:[ebx].WKDLS_FLAG,@WKDLS_CODE ; Izit a code segment?
	lea	esi,VxD_CODE	; DS:ESI ==> source
	jnz	short @F	; Jump if so

	lea	esi,VxD_DATA	; DS:ESI ==> source
@@:
	mov	ecx,VxD_CDLEN	; Get length of name to copy
    rep movs	DGROUP:[edi].LO,DGROUP:[esi].LO ; Append to local buffer

; Append the logical segment number (in decimal)

	mov	eax,'0000'      ; Get filler
	stos	DGROUP:[edi].EDD ; Initialize the buffer

	mov	eax,edi 	; Copy to byte register
	sub	eax,offset DGROUP:VxD_SYMB ; Subtract to get length
	mov	VxD_SYMC.SYMC_NAMLEN,al ; Save as name length

	dec	edi		; Back off to units digit
	movzx	eax,DGROUP:[ebx].WKDLS_LSEG ; Get the logical segment #
	push	@DEC_RIGHT	; Mark as right-justified
	call	DD2DEC		; Convert EAX to decimal at ES:EDI

; Fill in the SYMC_STR data

	mov	ax,DGROUP:[ebx].WKDLS_SEL ; Get the selector
	mov	VxD_SYMC.SYMC_FVEC.FSEL,ax ; Save in SYMC_STR

	mov	eax,DGROUP:[ebx].WKDLS_BASE ; Get the base address
	mov	VxD_SYMC.SYMC_FVEC.FOFF,eax ; Save in SYMC_STR

	mov	VxD_SYMC.SYMC_FLAG,@SYMTYP_DAT shl $SYMFL_TYP ; Save in SYMC_STR
	mov	VxD_SYMC.SYMC_GRP,0 ; ...

; Tell SWAT about the new symbol

	mov	ecx,1		; # symbols to append
	lea	esi,VxD_SYMC	; DS:ESI ==> SYMC_STR
	add	esi,SWATDATA	; AGROUP:ESI ==> ...

	sub	esp,size FORW_STR ; Allocate stack space
	mov	ebp,esp 	; Set up temporary FORW_STR at SS:EBP

; Save EGP registers in FORW_STR

	mov	[ebp].FORW_EDI,edi
	mov	[ebp].FORW_ESI,esi
	mov	[ebp].FORW_EBP,ebp
;;;;;;; mov	[ebp].FORW_ESP0,esp ; This one never gets used
	mov	[ebp].FORW_EBX,ebx
	mov	[ebp].FORW_EDX,edx
	mov	[ebp].FORW_ECX,ecx
	mov	[ebp].FORW_EAX,eax

; Caller return address is probably not needed

;;;;;;; mov	[ebp].FORW_RET.EDQLO,eip
;;;;;;; mov	[ebp].FORW_RET.EDQHI.ELO,cs
;;;;;;; mov	[ebp].FORW_EIP,?
	mov	[ebp].FORW_CS,cs

	sldt	[ebp].FORW_LDT	; Save LDT

	pushfd			; Get our flags
	pop	[ebp].FORW_EFL	; Put in structure

	mov	[ebp].FORW_ESP,esp ; Save ESP
	mov	[ebp].FORW_SS,ss ; Save SS

	mov	[ebp].FORW_ES,es ; ...	ES
	mov	[ebp].FORW_DS,ds ; ...	DS
	mov	[ebp].FORW_FS,fs ; ...	FS
	mov	[ebp].FORW_GS,gs ; ...	GS

; SS:EBP ==>	 valid FORW_STR

	call	SYMAPPND_COM	; Add to symbol table

	lea	esp,[esp+(size FORW_STR)] ; Clear temporary FORW_STR
				; from stack (CF unaffected)
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

APPEND_VxDSYMB	endp		; End APPEND_VxDSYMB procedure
	NPPROC	DISP_MODNAME -- Display Module Name
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display moule name

On entry:

FS:0	==>	NE/PE header

|

	REGSAVE <eax,ebx,esi>	; Save registers

	cmp	fs:[0].MOD_MODSIG,@MOD_SIG ; Izit NE-format?
	jne	short DISP_MODNAME_EXIT ; Jump if not

	lea	esi,MODNAME_PRE ; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

	push	ds		; Save for a moment

	mov	bx,fs:[0].MOD_NPLFI ; Get near ptr to load fileinfo struct
	lea	esi,fs:[bx].LFI32_szPathName ; DS:ESI ==> file name

	cmp	WINVER,0400h	; Izit Windows version 4.00 (Win95) or later?
	jae	short @F	; Jump if so

	lea	esi,fs:[bx].LFI16_szPathName ; DS:ESI ==> file name
@@:
	mov	ax,fs		; Get segment of module table
	mov	ds,ax		; Address it for INT 41h call
	assume	ds:nothing	; Tell the assembler about it

	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

	pop	ds		; Restore
	assume	ds:DGROUP	; Tell the assembler about it

	lea	esi,MODNAME_TAIL ; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service
DISP_MODNAME_EXIT:
	REGREST <esi,ebx,eax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_MODNAME endp		; End DISP_MODNAME procedure
	NPPROC	ValidMem -- Validate Memory
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Validate memory

On exit:

CF	=	0 if memory is valid
	=	1 if not

|

VM_STR	struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
VM_FVEC df	?		; Ptr to memory to validate
	dw	?		; Filler
VM_LEN	dd	?		; Length in bytes

VM_STR	ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ecx,esi>	; Save registers

; Ensure the offset is within the selector limit

	mov	ax,[ebp].VM_FVEC.FSEL ; Get the selector
	mov	ecx,[ebp].VM_FVEC.FOFF ; Get the offset
	add	ecx,[ebp].VM_LEN ; Plus the length

	lsl	esi,eax 	; Get the selector limit

	cmp	esi,ecx 	; Izit within range?
	jb	short ValidMemExit ; Jump if not (note CF=1)

	push	eax		; Pass the selector (as dword)
	call	SEL2BASE	; Return with EAX == selector base address
	add	eax,[ebp].VM_FVEC.FOFF ; Plus offset
	mov	esi,eax 	; Copy to input register

	mov	ecx,[ebp].VM_LEN ; # bytes we need
	mov	eax,Win386_AddrValid ; Function code to check validity of
				; linear address in ESI for CX bytes
	int	Win386_Query_Int ; Request Win386 services
				; Return with AX = 1 if OK, 0 if not
	cmp	ax,1		; Izit valid?
				; CF=0 if valid, CF=1 if not
ValidMemExit:
	REGREST <esi,ecx,eax>	; Restore

	pop	ebp		; Restore

	ret	4+4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ValidMem endp			; End ValidMem procedure
	FPPROC	LCL_INT41 -- Local Windows Kernel PM Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local windows kernel PM handler

This interrupt is called from PM under control of Windows only if we
responded to the appropriate INT 68h inquiry function.

On entry:

AX	=	0000h	Display the char in DL
	=     * 0001h	Read a char into AL
	=	0002h	Display the ASCIIZ string at DS:ESI
	=	0003h	Non-blocking In_Chr ???
	=	000Bh	New task ???
	=	000Ch	Flush task ???
	=	000Dh	Switch out (DS is task handle)???
	=	000Eh	Switch in (DS is task handle)???
	=	000Fh	Display symbol nearest to CX:EBX as name + nnnn
	=	0010h	Disassemble instruction at DS:ESI
	=     * 0012h	Display the ASCIIZ string at DS:SI
	=     * 0020h	If BX = 0, hook PL0 interrupts only, else all PLs
	=	0021h	Include segments for INTs
	=     * 0040h	Go to breakpoint at CX:BX (presumably a PM address?)
	=	0045h	Link map at DX:eDI + 10h
	=	0046h	Unlink map at DX:eDI + 10h
	=	0047h	Check map for module name at DX:eDI, return AX != 0 iff found
	=	0048h	Is autoload symbols (returns AX != 0 if autoloading)
	=     * 004Fh	Debugger identification (returns AX=@DEB_PRESENT if so)
	=     * 0050h	Define 16-bit segment
	=	0051h	Segment BX has been moved to CX
	=     * 0052h	Segment BX has been freed
	=	0056h	Register "dump global heap" handler at BX:CX
	=	0057h	Register "dump free list" handler at BX:CX
	=	0058h	Register "dump LRU list" handler at BX:CX
	=	0059h	Start task w/handle BX, registers on stack
	=     * 005Ah	Set Kernel vars for Winver BX, at DX:CX
	=    ** 005Bh	VCPI Windows 286 (Windows SETUP uses this)
	=     * 005Ch	Segment BX has been freed; free BPs, too
	=     * 005Dh	Set User vars for Winver BX, at DS:SI for CX words
	=	0060h	Post load ???
	=     * 0062h	Exit call, exit code in AL
	=	0063h	INT 2 ???
	=     * 0064h	Load DLL
	=     * 0065h	Free module
	=     * 0066h	Logerror
	=     * 0067h	Parameter Error
	=    ** 0070h	Register a 32-bit dot command
	=	0071h	Register a 16-bit dot command
	=	0072h	Unregister a dot command
	=     @ 0073h	Printf 32-bit
	=	0074h	Printf 16-bit
	=     @ 0075h	Get register set
	=     @ 0076h	Set alternate register set
	=     @ 0077h	Get command line char
	=	0078h	Evaluate expression
	=     @ 0079h	Verify memory
	=     @ 007Ah	Print registers
	=	007Bh	Print stack dump
	=	007Ch	Set thread ID
	=	007Dh	Execute debugger command
	=	007Eh	Get debugger info
	=     * 007Fh	Check fault
	=     * 0080h	Set break
	=	0081h	Redirect execution ???
	=	0082h	Pass on debugger command
	=     * 0083h	Trap fault
	=	0084h	Set stack trace callback
	=	0085h	Remove segments
	=	0086h	Define debugger's symbols
	=	0087h	Set baud rate
	=	0088h	Set COM port
	=	0089h	Change task number
	=	008Ah	Exit cleanup
	=	008Bh	Install VGA handler
	=     * 008Ch	Get COM base
	=     * 008Dh	Get symbol
	=	008Eh	Copy memory
	=     * 0150h	Define 32-bit segment
	=     * 0152h	Segment BX has been freed for module DX:EDI
	=    * 0E000h	Display load segment table (local definition)
	=    * 0E001h	Return address of ...
	=    * 0E002h	Return address of IPF struc table
	=   ** 0F001h	Conditional breakpoint
	=      0F002h	Permanent breakpoint
	=      0F003h	Goto CX:EBX
	=      0F004h	Is INT 01h hooked for all rings?

*	=	actually seen in high memory
**	=	actually seen in low memory
@	=	called by Win386 from INT 22h functions

On exit:

Depends upon the function.

|

INT41_STR struc

	  dw	?,?		; Caller's DS w/filler
INT41_EIP dd	?		; ...	   EAX (return EIP)
INT41_CS  dw	?,?		; ...	   EAX (return CS w/filler)
INT41_EFL dd	?		; ...	   EBX (return EFL)
INT41_STK3 df	?		; ...	   SS|ESP at PL3

INT41_STR ends

	cld			; String ops forwardly

; When SWAT VxD registers INT 41h with W as the default interrupt
; for all VMs, W calls it assuming that it's a PL3 selector.  This
; means that it IRETDs to us assuming that a ring transition will
; occur.  Because we're at PL0 instead, the PL3 SS|ESP is still
; on the stack.  This case can be detected by checking the return
; CS to see if it's writable.

	push	ebp		; Prepare to address the stack

; If the caller's SS does not have the B-bit set, clear
; the high-order word of EBP so we can use it as a base register.

	mov	ebp,ss		; Copy the selector
	lar	ebp,ebp 	; Get the A/R word

	test	ebp,(mask $DTE_B) shl 16 ; Izit a 32-bit selector?
	lea	ebp,[esp+4]	; Hello, Mr. Stack
	jnz	short @F	; Jump if so

	movzx	ebp,bp		; Clear to use as dword
	movzx	esp,sp		; ...
@@:
	verw	[ebp].IRETD_CS	; Izit writable?
	pop	ebp		; Restore
	jnz	short LCL_INT41_IRETD1	; Jump if not (must be code selector)

	push	ebx		; Make room for return EFL
	push	eax		; ...		       CS w/filler
	push	eax		; ...		       EIP

	push	ds		; Save for a moment

	lds	ebx,[esp].INT41_STK3 ; DS:EBX ==> PL3 stack
	assume	ds:nothing	; Tell the assembler about it

	mov	ax,ds:[ebx].IRETD_CS ; Get the return CS
	mov	[esp].INT41_CS,ax ; Save onto PL0 stack

	mov	eax,ds:[ebx].IRETD_EIP ; Get the return EIP
	xchg	eax,[esp].INT41_EIP ; Swap with original EAX

	mov	ebx,ds:[ebx].IRETD_EFL ; Get the return EFL
	xchg	ebx,[esp].INT41_EFL ; Swap with original EBX

	add	[esp].INT41_STK3.FOFF,size IRETD_STR ; Strip off the struct we used

	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it
LCL_INT41_IRETD1:
	cmp	ax,@I41_OUT_CHAR ; Izit display a character?
	je	near ptr LCL_INT41_DISPCHAR ; Jump if so

	cmp	ax,@I41_IN_CHAR ; Izit get a character?
	je	near ptr LCL_INT41_GETCHAR ; Jump if so

	cmp	ax,@I41_OUT_STR ; Izit display an ASCIIZ string?
	je	near ptr LCL_INT41_DISP32 ; Jump if so

;;;;;;; cmp	ax,@I41_SCAN_CHAR ; Izit scan for a character?
;;;;;;; je	near ptr LCL_INT41_SCAN_CHAR ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_NEWTASK ; Izit "Used by RegisterPTrace"?
;;;;;;; je	near ptr LCL_INT41_NEWTASK ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_FLUSHTASK ; Izit "Used by RegisterPTrace"?
;;;;;;; je	near ptr LCL_INT41_FLUSHTASK ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_SWITCHOUT ; Izit "Used by RegisterPTrace"?
;;;;;;; je	near ptr LCL_INT41_SWITCHOUT ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_SWITCHIN ; Izit "Used by RegisterPTrace"?
;;;;;;; je	near ptr LCL_INT41_SWITCHIN ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_OUT_SYMB ; Izit find nearest symbol?
;;;;;;; je	near ptr LCL_INT41_OUT_SYMB ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_DISASM	; Izit disassemble an instruction?
;;;;;;; je	near ptr LCL_INT41_DISASM ; Jump if so

	cmp	ax,@I41_OUT_STR16 ; Izit display an ASCIIZ string?
	je	near ptr LCL_INT41_OUT_STR16 ; Jump if so

	cmp	ax,@I41_INTRINGS ; Izit set which interrupt PLs to trap?
	je	near ptr LCL_INT41_INTRINGS ; Jump if so

;;;;;;; cmp	ax,@I41_INCLUDESEG ; Izit handle BPs in this segment?
;;;;;;; je	near ptr LCL_INT41_INCLUDESEG ; Jump if so
;;;;;;;
	cmp	ax,@I41_GO16	; Izit goto specified address?
	je	near ptr LCL_INT41_GOTO ; Jump if so

;;;;;;; cmp	ax,@I41_LINKMAP ; Izit link a map?
;;;;;;; je	near ptr LCL_INT41_LINKMAP ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_UNLINKMAP ; Izit unlink a map?
;;;;;;; je	near ptr LCL_INT41_UNLINKMAP ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_CHECKMAP ; Izit check a map?
;;;;;;; je	near ptr LCL_INT41_CHECKMAP ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_ISAUTOLOAD ; Izit query autoload symbols?
;;;;;;; je	near ptr LCL_INT41_ISAUTOLOAD ; Jump if so

	cmp	ax,@I41_DEBLOADED ; Izit debugger identification?
	je	near ptr LCL_INT41_DEBLOADED ; Jump if so

	cmp	ax,@I41_LOADSEG16 ; Izit load 16-bit segment?
	je	near ptr LCL_INT41_LOADSEG16 ; Jump if so

;;;;;;; cmp	ax,@I41_MOVESEG ; Izit move a segment?
;;;;;;; je	near ptr LCL_INT41_MOVESEG ; Jump if so
;;;;;;;
	cmp	ax,@I41_FREESEG16 ; Izit free 16-bit segment?
	je	near ptr LCL_INT41_FREESEG16 ; Jump if so

;;;;;;; cmp	ax,@I41_DGH	; Izit dump global heap?
;;;;;;; je	short LCL_INT41_DGH ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_DFL	; Izit dump free list?
;;;;;;; je	short LCL_INT41_DFL ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_DLL	; Izit dump LRU list?
;;;;;;; je	short LCL_INT41_DLL ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_STARTTASK ; Izit start a task?
;;;;;;; je	short LCL_INT41_STARTTASK ; Jump if so
;;;;;;;
	cmp	ax,@I41_KERNEL_VAR ; Izit set kernel vars?
	je	near ptr LCL_INT41_KERNEL_VAR ; Jump if so

;;;;;;; cmp	ax,@I41_VCPI_NOTE ; Izit Windows 286?
;;;;;;; je	short LCL_INT41_VCPI ; Jump if so
;;;;;;;
	cmp	ax,@I41_RELSEG	; Izit free segment and breakpoints?
	je	near ptr LCL_INT41_RELSEG ; Jump if so

	cmp	ax,@I41_USER_VARS ; Izit set user vars?
	je	near ptr LCL_INT41_SETUVARS ; Jump if so

;;;;;;; cmp	ax,@I41_POSTLOAD ; Izit "Used by RegisterPTrace"?
;;;;;;; je	near ptr LCL_INT41_POSTLOAD ; Jump if so
;;;;;;;
	cmp	ax,@I41_EXITCALL ; Izit exit call?
	je	near ptr LCL_INT41_EXITCALL ; Jump if so

;;;;;;; cmp	ax,@I41_INT2	; Izit ??? ?
;;;;;;; je	near ptr LCL_INT41_INT2 ; Jump if so
;;;;;;;
	cmp	ax,@I41_LOADDLL ; Izit load DLL?
	je	near ptr LCL_INT41_LOADDLL ; Jump if so

	cmp	ax,@I41_DELMOD	; Izit free module?
	je	near ptr LCL_INT41_DELMOD ; Jump if so

	cmp	ax,@I41_LOGERROR ; Izit log error?
	je	near ptr LCL_INT41_LOGERROR ; Jump if so

	cmp	ax,@I41_PARAMERR ; Izit parameter error?
	je	near ptr LCL_INT41_PARAMERR ; Jump if so

;;;;;;; cmp	ax,@I41_REG_DOT32 ; Izit register a 32-bit dot command?
;;;;;;; je	near ptr LCL_INT41_REG_DOT32 ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_REG_DOT16 ; Izit register a 16-bit dot command?
;;;;;;; je	near ptr LCL_INT41_REG_DOT16 ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_UNREG_DOT ; Izit unregister a dot command?
;;;;;;; je	near ptr LCL_INT41_UNREG_DOT ; Jump if so
;;;;;;;
	cmp	ax,@I41_PRINTF32 ; Izit printf for 32-bit apps?
	je	near ptr LCL_INT41_PRINTF32 ; Jump if so

;;;;;;; cmp	ax,@I41_PRINTF16 ; Izit printf for 16-bit apps?
;;;;;;; je	near ptr LCL_INT41_PRINTF16 ; Jump if so
;;;;;;;
	cmp	ax,@I41_GET_REGS ; Izit get a register set?
	je	near ptr LCL_INT41_GET_REGS ; Jump if so

	cmp	ax,@I41_SET_ALTREG ; Izit get a register set?
	je	near ptr LCL_INT41_SET_ALTREG ; Jump if so

	cmp	ax,@I41_GETCMDCHAR ; Izit Get a character from command line?
	je	near ptr LCL_INT41_GETCMDCHAR ; Jump if so

;;;;;;; cmp	ax,@I41_EVAL_EXPR ; Izit Evaluate an expression?
;;;;;;; je	near ptr LCL_INT41_EVAL_EXPR  ; Jump if so
;;;;;;;
	cmp	ax,@I41_VER_MEM ; Izit Verify memory?
	je	near ptr LCL_INT41_VER_MEM    ; Jump if so

	cmp	ax,@I41_PRINT_REG ; Izit Print registers?
	je	near ptr LCL_INT41_PRINT_REG  ; Jump if so

;;;;;;; cmp	ax,@I41_PRINT_STK ; Izit Print stack dump?
;;;;;;; je	near ptr LCL_INT41_PRINT_STK  ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_SET_THREAD ; Izit Set a thread ID?
;;;;;;; je	near ptr LCL_INT41_SET_THREAD ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_EXEC_CMD ; Izit Execute a debug command?
;;;;;;; je	near ptr LCL_INT41_EXEC_CMD   ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_GET_DBGINF ; Izit Get debugger info?
;;;;;;; je	near ptr LCL_INT41_GET_DBGINF ; Jump if so
;;;;;;;
	cmp	ax,@I41_CHECKFAULT ; Izit check fault?
	je	near ptr LCL_INT41_CHECKFAULT ; Jump if so

	cmp	ax,@I41_SET_BREAK ; Izit Set Ctrl-C handler?
	je	near ptr LCL_INT41_SET_BREAK  ; Jump if so

;;;;;;; cmp	ax,@I41_REDIRECT ; Izit Redirect I/O to buffers?
;;;;;;; je	near ptr LCL_INT41_REDIRECT   ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_PASS_DOT ; Izit Pass on this dot command?
;;;;;;; je	near ptr LCL_INT41_PASS_DOT   ; Jump if so
;;;;;;;
	cmp	ax,@I41_TRAPFAULT ; Izit trap fault?
	je	near ptr LCL_INT41_TRAPFAULT ; Jump if so

;;;;;;; cmp	ax,@I41_SET_STK_CB ; Izit Set stack trace callback?
;;;;;;; je	near ptr LCL_INT41_SET_STK_CB ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_REM_SEGS ; Izit Remnove undefined groups from a map file?
;;;;;;; je	near ptr LCL_INT41_REM_SEGS   ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_DEF_DSEGS ; Izit Define debugger segments?
;;;;;;; je	near ptr LCL_INT41_DEF_DSEGS  ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_SET_BAUD ; Izit Set COM port baud rate?
;;;;;;; je	near ptr LCL_INT41_SET_BAUD   ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_SET_PORT ; Izit Set COM port number?
;;;;;;; je	near ptr LCL_INT41_SET_PORT ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_CHG_TASK ; Izit Change task numbers?
;;;;;;; je	near ptr LCL_INT41_CHG_TASK ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_WIN_EXIT ; Izit Windows is exiting?
;;;;;;; je	near ptr LCL_INT41_WIN_EXIT ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_INST_VGA ; Izit Install new VGA handler?
;;;;;;; je	near ptr LCL_INT41_INST_VGA ; Jump if so
;;;;;;;
	cmp	ax,@I41_GET_BASE ; Izit Get COM port base address?
	je	near ptr LCL_INT41_GET_BASE ; Jump if so

	cmp	ax,@I41_GET_SYMB ; Izit get symbol?
	je	near ptr LCL_INT41_GETSYMBOL ; Jump if so

;;;;;;; cmp	ax,@I41_COPY_MEM ; Izit Copy memory?
;;;;;;; je	near ptr LCL_INT41_COPY_MEM ; Jump if so
;;;;;;;
	cmp	ax,@I41_LOADSEG32 ; Izit load 32-bit segment?
	je	near ptr LCL_INT41_LOADSEG32 ; Jump if so

	cmp	ax,@I41_FREESEG32 ; Izit free 32-bit segment?
	je	near ptr LCL_INT41_FREESEG32 ; Jump if so

	cmp	ax,@I41_DISPLS	; Izit display load segment table?
	je	near ptr LCL_INT41_DISPLS ; Jump if so

	cmp	ax,@I41_GETLS	; Izit return address of load segment table?
	je	near ptr LCL_INT41_GETLS ; Jump if so

	cmp	ax,@I41_GETIPF	; Izit return address of IPF struc table?
	je	near ptr LCL_INT41_GETIPF ; Jump if so

;;;;;;; cmp	ax,@I41_COND_BP ; Izit Conditional breakpoint?
;;;;;;; je	near ptr LCL_INT41_COND_BP ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_FORCE_BP ; Izit Forced breakpoint?
;;;;;;; je	near ptr LCL_INT41_FORCE_BP ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_FORCE_GO ; Izit Goto specified address?
;;;;;;; je	near ptr LCL_INT41_FORCE_GO ; Jump if so
;;;;;;;
;;;;;;; cmp	ax,@I41_HARD_INT1 ; Izit Query INT 01h hook for all rings?
;;;;;;; je	near ptr LCL_INT41_HARD_INT1 ; Jump if so
;;;;;;;
	int	03h		; Not handled as yet *FIXME*
LCL_INT41_IRETD_BP:
	int	01h		; Call ourselves
LCL_INT41_IRETD:
	iretd			; Return to caller


COMMENT|

Display a character

On entry:

AX	=	0000h
DL	=	character to display

On exit:

Nothing

|

LCL_INT41_DISPCHAR:
	REGSAVE <eax,esi,ds>	; Save for a moment

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	ds,eax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	xchg	dl,DISPCHAR	; Save in local buffer
	lea	esi,DISPCHAR	; DS:ESI ==> display buffer
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

	xchg	dl,DISPCHAR	; Restore original char

	REGREST <ds,esi,eax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Get a character

On entry:

AX	=	0001h

On exit:

AL	=	char

|

LCL_INT41_GETCHAR:
	REGSAVE <ds>		; Save register

	push	eax		; Save the entire dword

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	ds,eax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

; Tell SWAT to display the error log screen
; and wait for a character

@LC3_CMD equ	@LC3_INTERNAL
@LC4_CMD equ	@LC4_ERRLOG

	mov	eax,LC3_FLAG	; Get flags
	and	eax,@LC3_CMD	; Isolate bits to preserve
	push	eax		; Save

	mov	eax,LC4_FLAG	; Get flags
	and	eax,@LC4_CMD	; Isolate bits to preserve
	push	eax		; Save

	or	LC3_FLAG,@LC3_CMD ; Tell SWATTER to call CMD_CHAR then exit
	or	LC4_FLAG,@LC4_CMD ; Mark as displaying error log

; Simulate call to SWATTER from an interrupt handler at PL0

	pushfd			; EFLAGS
	PUSHD	cs		; Return CS with filler
	lea	eax,PGROUP:@F	; Return EIP
	push	eax		; Put it on stack
	FCALLD	SWATTER 	; Call our debugger with IRETD frame on stack
	add	esp,3*4 	; Strip bogus IRETD frame
@@:
	pop	eax		; Restore
	and	LC4_FLAG,not @LC4_CMD ; Turn off bits we turned on
	or	LC4_FLAG,eax	; Restore previous value

	pop	eax		; Restore
	and	LC3_FLAG,not @LC3_CMD ; Turn off bits we turned on
	or	LC3_FLAG,eax	; Restore previous value

	pop	eax		; Restore the entire dword

	mov	al,ERRLOG_KEY.LO ; Return the keystroke in AL

	REGREST <ds>		; Restore
	assume	ds:nothing	; Tell the assembler about it

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Display an ASCIIZ string

On entry:

AX	=	0002h
DS:ESI	==>	ASCIIZ string to display

On exit:

Nothing

|

; The following label is called below in the Parameter Error routine
; and in the Disp 16 routine

LCL_INT41_DISP32:
	pushad			; Save all registers

	push	esi		; Save for a moment
@@:
	lods	ds:[esi].LO	; Get next character

	or	al,al		; Izit the end?
	jz	short @F	; Jump if so

	call	LDISPTXT	; Dump to error log

	jmp	short @B	; Go around again

@@:
	pop	esi		; Restore

; If our VxD is present, tell 'em to display this on the mono screen

	REGSAVE <ds,es,gs>	; Save segment registers

; Convert DS:ESI into a flat address
; Note that we're assuming that SS is big (SEL2BASE addresses the stack w/EBP)

	PUSHD	ds		; Selector we're interested in
	call	SEL2BASE	; Return with EAX == selector base address
	add	esi,eax 	; Add to get linear address

; Setup segment registers to call the VxD

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	gs,eax		; Address it
	assume	gs:DGROUP	; Tell the assembler about it

	cmp	SWATINFO.SWTINF_VER,7 ; Duzit support PM API entry?
	jb	short LCL_INT41_DISP32_EXIT ; Jump if not

	cmp	SWATINFO.SWTINF_VxD_PMAPI.FOFF,0 ; Izit undefined?
	je	short LCL_INT41_DISP32_EXIT ; Jump if so

	mov	ds,ax		; Address it for U32_DisableDispAGP
	assume	ds:DGROUP	; Tell the assembler about it

	call	U32_DisableDispAGP ; Disable the primary display and AGP

	mov	ax,COMMON.FILE_4GB ; Get all memory selector

	mov	ds,ax		; Address it
	assume	ds:AGROUP	; Tell the assembler about it

	mov	es,ax		; Address it
	assume	ds:AGROUP	; Tell the assembler about it

	push	SWAT_Out_Mono_String ; Pass parameter
	call	SWATINFO.SWTINF_VxD_PMAPI ; Request VxD service

	mov	ax,gs		; Get DGROUP data selector
	mov	ds,ax		; Address it for U32_EnableDispAGP
	assume	ds:DGROUP	; Tell the assembler about it

	call	U32_EnableDispAGP ; Enable the primary display and AGP
LCL_INT41_DISP32_EXIT:
	REGREST <gs,es,ds>	; Restore
	assume	ds:nothing	; Tell the assembler about it
	assume	es:nothing	; ...
	assume	gs:nothing	; ...

	popad			; Restore

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Display an ASCIIZ string

On entry:

AX	=	0012h
DS:SI	==>	ASCIIZ string to display

On exit:

Nothing

|

LCL_INT41_OUT_STR16:
	REGSAVE <eax,esi>	; Save registers

	movzx	esi,si		; Zero to use as dword
				; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

	REGREST <esi,eax>	; Restore

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Set which rings to trap

On entry:

AX	=	0020h
BX	=	0 to tell debugger to trap PL0 INTs 01h & 03h only
	!=	0 ...			   all PL INTs 01h & 03h

On exit:

Nothing

|

LCL_INT41_INTRINGS:
	REGSAVE <eax,ds>	; Save registers

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	ds,eax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	xor	eax,eax 	; Zero to use as word
	test	bx,bx		; Check the flag
	setz	al		; AL = 1 iff trapping INTs 01h & 03h in PL0 only
	shl	eax,$LC4_INTPL0  ; Shift into place
	and	LC4_FLAG,not (mask $LC4_INTPL0) ; Clear the flag
	or	LC4_FLAG,eax	; Set as appropriate

	REGREST <ds,eax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Goto specified address

Enter the debugger and perform the equivalent
of a GO command to force a stop at the
specified CS:IP
CX is the desired CS
BX is the desired IP

On entry:

AX	=	0040h
CX:BX	=	target CS:IP

|

LCL_INT41_GOTO:
	push	eax		; Save register

; Setup for call to common routine
; to set breakpoint at the faulting address.
; Presuably, W will retry the instruction and we'll
; trap the fault.

	movzx	eax,bx		; Zero to use as dword

	push	ecx		; Pass CS
	push	eax		; ...  EIP
	PUSHD	0		; ...  fault error code
	PUSHD	cs		; ...  segment of error message
	lea	eax,GOTO_MSG	; Get offset of error message
	push	eax		; Pass offset of error message
	call	INT41_GOTO	; Set msg and goto

	pop	eax		; Restore

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Debugger identification

On entry:

AX	=	004Fh

On exit:

AX	=	@DEB_PRESENT

|

LCL_INT41_DEBLOADED:
	mov	ax,@DEB_PRESENT ; Mark as present

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Define a 16-bit segment

On entry:

AX	=	0050h
SI	=	00h - code selector
	=	01h - data selector
	=	80h - code segment
	=	81h - data segment
BX	=	segment # (presumably for 80h/81h)
CX	=	actual segment/selector
DX	=	data instance ???
ES:eDI	==>	module name

On exit:

Nothing

|

LCL_INT41_LOADSEG16:
;;;;;;; int	03h		; Not handled as yet *FIXME*

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Free a 16-bit segment

On entry:

AX	=	0052h
BX	=	segment #

On exit:

Nothing

|

LCL_INT41_FREESEG16:
	jmp	LCL_INT41_IRETD ; Return to caller

	pushad			; Save all EGP registers
	REGSAVE <ds,es> 	; Save registers

; Setup segment registers for local use

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	ds,eax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it
	mov	es,eax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	ax,bx		; Copy segment being freed
	lea	edi,FREESEG16_MSG1 ; ES:EDI ==> output save area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	lea	esi,FREESEG16_MSG ; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

	REGREST <es,ds> 	; Restore
	assume	ds:nothing	; Tell the assembler about it
	assume	es:nothing	; ...
	popad			; Restore

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Set kernel vars

On entry:

AX	=	005Ah
BX	=	Windows version #
DX:CX	==>	struct {
		    WORD hGlobalHeap;	 ****
		    WORD pGlobalHeap;	 ****
		    WORD hExeHead;	 ****
		    WORD hExeSweep;
		    WORD topPDB;
		    WORD headPDB;
		    WORD topsizePDB;
		    WORD headTDB;	 ****
		    WORD curTDB;	 ****
		    WORD loadTDB;
		    WORD LockTDB;
		    WORD SelTableLen;	 ****
		    DWORD SelTableStart; ****
		};
		**** = used by heap dump commands internal to WDEB386

Notes:

SelTableStart = Offset in hGlobalHeap of selector table.
		This table is indexed by (selector/8)*4.
		The dword pointed to by this index is the offset in
		the Global Heap of the entry (assuming it's non-zero).
SelTableLen   = 8000h

On exit:

Nothing

|

LCL_INT41_KERNEL_VAR:
	REGSAVE <eax,edi,es>	; Save registers

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	es,eax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	KVARS_VEC.VOFF,cx ; Save for later use
	mov	KVARS_VEC.VSEG,dx ; ...

	mov	ax,KVARS_VEC.VSEG ; Copy selector
	lea	edi,MSG_KVS	; ES:EDI ==> output save area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,KVARS_VEC.VOFF ; Copy offset
	lea	edi,MSG_KVO	; ES:EDI ==> output save area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	REGREST <es,edi,eax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Free a segment and breakpoints

On entry:

AX	=	005Ch
BX	=	segment #

On exit:

Nothing

|

LCL_INT41_RELSEG:
;;;;;;; int	03h		; Not handled as yet *FIXME*

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Set user vars

On entry:

AX	=	005Dh
BX	=	Windows version #
CX	=	# words in struc
DX:SI	==>	struc {
		    WORD fDebugUser;	// 1 = DEBUG, 0 = RETAIL
		    WORD nphHmenuSel;	// 16-bit ptr to hHmenuSel
		    WORD nphHwndSel;	// ...		 hHwndSel
		    WORD nppclsList;	// ...		 pclsList
		    WORD nppcdeFirst;	// ...		 pcdeFirst
		    WORD nphwndDesktop; // ...		 hwndDesktop
		};

On exit:

Nothing

|

LCL_INT41_SETUVARS:
	REGSAVE <eax,edi,es>	; Save registers

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	es,eax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

; Copy the array as it disappears after this call

	mov	ax,ds		; Copy segment register of near ptrs
	mov	UVARS.UV_lphHmenuSel.VSEG,ax   ; Save in array
	mov	UVARS.UV_lphHwndSel.VSEG,ax    ; ...
	mov	UVARS.UV_lppclsList.VSEG,ax    ; ...
	mov	UVARS.UV_lppdceFirst.VSEG,ax   ; ...
	mov	UVARS.UV_lphwndDesktop.VSEG,ax ; ...

	mov	ax,ds:[si].UV_fDebugUser1 ; Get debug flag
	mov	UVARS.UV_fDebugUser2.ELO,ax ; Save in array

	mov	ax,ds:[si].UV_nphHmenuSel ; Get hHmenuSel
	mov	UVARS.UV_lphHwndSel.VOFF,ax ; Save in array

	mov	ax,ds:[si].UV_nphHwndSel ; get hHwndSel
	mov	UVARS.UV_lphHwndSel.VOFF,ax ; Save in array

	mov	ax,ds:[si].UV_nppclsList ; Get pclsList
	mov	UVARS.UV_lppclsList.VOFF,ax ; Save in array

	mov	ax,ds:[si].UV_nppdceFirst ; Get pdceFirst
	mov	UVARS.UV_lppdceFirst.VOFF,ax ; Save in array

	mov	ax,ds:[si].UV_nphwndDesktop ; Get hwndDesktop
	mov	UVARS.UV_lphwndDesktop.VOFF,ax ; Save in array

	mov	ax,es		; Copy selector
	lea	edi,MSG_UVS	; ES:EDI ==> output save area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	lea	eax,UVARS	; Copy offset
	lea	edi,MSG_UVO	; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	REGREST <es,edi,eax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Exit call

On entry:

AX	=	0062h
BL	=	code ???
CX	=	TD handle

On exit:

Nothing

|

LCL_INT41_EXITCALL:
	pushad			; Save all EGP registers
	REGSAVE <ds,es> 	; Save registers

; Setup segment registers for local use

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	ds,eax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it
	mov	es,eax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

; Format the incoming code

	mov	al,bl		; Get the code
	lea	edi,EXITCALL_CODE ; ES:EDI ==> output save area
	call	BIN2BYTE	; Convert AL to hex at ES:EDI

; Format the incoming TD selector

	mov	ax,cx		; Get the selector
	lea	edi,EXITCALL_ADDR ; ES:EDI ==> output save area
	call	BIN2WORD	; Convert AL to hex at ES:EDI

; If this is really a Task Database, display the module name

	mov	EXITCALL_NAME.EDQLO,'????' ; Assume not
	mov	EXITCALL_NAME.EDQHI,'????' ; ...

; Validate CX as a selector

	verr	cx		; Izit valid for reading?
	jnz	short @F	; Jump if not

	mov	es,cx		; Address it
	assume	es:nothing	; Tell the assembler about it

	cmp	es:[0].TDB_TDBSIG,@TDB_SIG ; Izit a TDB?
	jne	short @F	; Jump if not

	mov	eax,es:[0].TDB_MODNAME.EDQLO ; Get the low-order 4 bytes
	mov	EXITCALL_NAME.EDQLO,eax ; Save in data area
	mov	eax,es:[0].TDB_MODNAME.EDQHI ; Get the high-order 4 bytes
	mov	EXITCALL_NAME.EDQHI,eax ; Save in data area
@@:
	lea	esi,EXITCALL_MSG ; DS:ESI ==> module name
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

	lea	esi,EXITCALL_TAIL ; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

	REGREST <es,ds> 	; Restore
	assume	ds:nothing	; Tell the assembler about it
	assume	es:nothing	; ...
	popad			; Restore

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Load a DLL, called by StartLibrary()

On entry:

AX	=	0064h
CX:BX	==>	CS:IP of DLL
DX	=	module handle (= ES-1)
ES:0	==>	NE/PE header
DI	=	if DI & 11b
		then DI == handle of DGROUP
		else DI == MOD_FLAGS
On exit:

Nothing

|

LCL_INT41_LOADDLL:
	pushad			; Save all EGP registers
	REGSAVE <ds,es,fs>	; Save registers

; Copy incoming ES to FS so we can use ES locally

	mov	eax,es		; Get incoming ES
	mov	fs,eax		; Address it
	assume	fs:nothing	; Tell the assembler about it

; Setup segment registers for local use

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	ds,eax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it
	mov	es,eax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	ax,fs:[0].MOD_MODSIG ; Get module signature
	mov	LOADDLL_TYPE.ELO,ax ; Save in message

	mov	ax,di		; Copy handle of DGROUP
	lea	edi,LOADDLL_DGR ; ES:EDI ==> output save area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,cx		; Copy load CS
	lea	edi,LOADDLL_CS	; ES:EDI ==> output save area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,bx		; Copy load IP
	lea	edi,LOADDLL_IP	; ES:EDI ==> output save area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,fs		; Copy module segment
	lea	edi,LOADDLL_MOD ; ES:EDI ==> output save area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	lea	esi,LOADDLL_MSG ; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

; Display the module name

	call	DISP_MODNAME	; Display the name of the module at FS:0

	REGREST <fs,es,ds>	; Restore
	assume	ds:nothing	; Tell the assembler about it
	assume	es:nothing	; ...
	assume	fs:nothing	; ...
	popad			; Restore

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Free a module

On entry:

AX	=	0065h
ES:0	==>	NE/PE header

On exit:

Nothing

|

LCL_INT41_DELMOD:
	pushad			; Save registers
	REGSAVE <ds,es,fs>	; ...

; Copy incoming ES to FS so we can use ES locally

	mov	eax,es		; Copy selector
	mov	fs,eax		; Address it
	assume	fs:nothing	; Tell the assembler about it

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	ds,eax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it
	mov	es,eax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	ax,fs		; Get the NE/PE segment
	lea	edi,FREEMOD_MSG1 ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	lea	esi,FREEMOD_MSG ; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

; Display the module name

	call	DISP_MODNAME	; Display the name of the module at FS:0

	REGREST <fs,es,ds>	; Restore
	assume	ds:nothing	; Tell the assembler about it
	assume	es:nothing	; ...
	assume	fs:nothing	; ...
	popad			; Restore

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Log error

On entry:

AX	=	0066h
BX	=	LOWORD or BYTE
CX	=	error code
DX	=	HIWORD of DWORD (DX:BX)

On exit:

Nothing

|

LCL_INT41_LOGERROR:
	REGSAVE <eax,esi,ds>	; Save registers

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	ds,eax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	lea	esi,LOGTAB_HDR	; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

	REGREST <ds,esi,eax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

; The following label is called below in the Parameter Error routine

LCL_INT41_LOGERROR1:
	REGSAVE <eax,ecx,esi,edi,ds,es> ; Save registers

; Setup segment registers

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	ds,eax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it
	mov	es,eax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

; Strip off warning bit

	btr	cx,$ERR_WARNING ; Izit a warning?
	jnc	short @F	; Jump if not

	lea	esi,LOGTAB_WARN ; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service
@@:

; Find the matching error code

	mov	ax,cx		; Copy the error code
	mov	ecx,LOGTAB_LEN	; Get # entries in LOGTAB
	xor	esi,esi 	; Zero index into LOGTAB
@@:
	cmp	ax,LOGTAB[esi*(type LOGTAB_STR)].LOGTAB_ERR.ELO ; Duzit match?
	je	short @F	; Jump if so

	inc	esi		; Skip to next entry

	loop	@B		; Jump if more entries

	mov	bx,ax		; Copy as word value to display
	mov	ax,LOGTAB[esi*(type LOGTAB_STR)].LOGTAB_ERR.ELO ; Use fall through
@@:

; Display the error message

	mov	esi,LOGTAB[esi*(type LOGTAB_STR)].LOGTAB_TXT ; WGROUP:ESI ==> string to display
	add	esi,WINBASE	; Plus offset in DGROUP of WGROUP
				; DS:ESI ==> string to display
	push	eax		; Save for a moment
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service
	pop	eax		; Restore

; Display the trailing data (if any)

	and	eax,ERR_SIZE_MASK ; Isolate the error width
	shr	eax,$ERR_SIZE_MASK ; Shift to low-order bits
	lea	edi,LOGTAB_DATA ; ES:EDI ==> output format area

	jmp	LOGTAB_ACT[eax*(type LOGTAB_ACT)] ; Take appropriate action


; Format the byte data

LCL_INT41_LOGERROR_BYTE:
	mov	al,bl		; Get the byte value
	call	BIN2BYTE	; Convert AL to hex at ES:EDI

	jmp	short LCL_INT41_LOGERROR_COM ; Join common code


; Format the word data

LCL_INT41_LOGERROR_WORD:
	mov	ax,bx		; Get the word value
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	jmp	short LCL_INT41_LOGERROR_COM ; Join common code


; Format the dword data

LCL_INT41_LOGERROR_DWORD:
	mov	ax,dx		; Get the high-order word
	shl	eax,16		; Shift to high-order word
	mov	ax,bx		; Get the low-order word
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

;;;;;;; jmp	short LCL_INT41_LOGERROR_COM ; Join common code


LCL_INT41_LOGERROR_NONE:
LCL_INT41_LOGERROR_COM:
	mov	eax,00000A0Dh	; Trailing CR,LF,0
	stos	DGROUP:[edi].EDD ; Save in data

; Display the trailing data (if any)

	lea	esi,LOGTAB_DATA ; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

	REGREST <es,ds,edi,esi,ecx,eax> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

; If we were called as @I41_LOGERROR, signal an INT 01h
; as this is an unusual event

	cmp	ax,@I41_LOGERROR ; Izit logerror?
	jne	short @F	; Jump if not

	REGSAVE <eax,ds>	; Save for a moment

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	ds,eax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	test	WKD_FLAG,@WKD_LOGERR ; Should we trap this?
	REGREST <ds,eax>	; Restore
	assume	ds:nothing	; Tell the assembler about it
	jnz	near ptr LCL_INT41_IRETD_BP ; Jump if we're breakpointing
@@:
	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Parameter Error

On entry:

AX	=	0067h
ES:BX	==>	PARAM_STR
SS:ESP	==>	PARAMSTK_EIP

On exit:

Nothing

|

PARAM_STR struc

PARAM_ERR    dw ?		; Error code
PARAM_RETVEC dd ?		; Return address
PARAM_BADVEC dd ?		; Bad pointer
PARAM_PUSHAD db (size PUSHAD_STR) dup (?) ; PUSHAD struc
PARAM_GS     dw ?		; Segment register
PARAM_FS     dw ?		; ...
PARAM_ES     dw ?		; ...
PARAM_DS     dw ?		; ...

PARAM_STR ends


PARAMSTK_STR struc

PARAMSTK_GS	dw ?,?		; Caller's GS w/filler
PARAMSTK_FS	dw ?,?		; ...	   FS ...
PARAMSTK_ES	dw ?,?		; ...	   ES ...
PARAMSTK_DS	dw ?,?		; ...	   DS ...
PARAMSTK_PUSHAD db (size PUSHAD_STR) dup (?) ; PUSHAD
PARAMSTK_OLDSTK df ?		; Old stack pointer
		dw ?		; For alignment
PARAMSTK_EIP	dd ?		; Return EIP
PARAMSTK_CS	dw ?,?		; ...	 CS w/filler
PARAMSTK_EFL	dd ?		; ...	 EFL
PARAMSTK_ESP	dd ?		; ...	 ESP
PARAMSTK_SS	dw ?,?		; ...	 SS w/filler

PARAMSTK_STR ends


LCL_INT41_PARAMERR:

; Switch stacks if not local as we can step on W's stack space
; particularly after we call ValidMem which calls INT 22h which
; calls @I41_VER_MEM, etc.

	PUSHW	ds		; Save for a moment as a word

@I41STK_PUSH equ 2		; Amount just PUSHed

	push	cs		; Get code selector
	add	[esp].ELO,type DESC_STR ; Skip to data selector
	pop	ds		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	mov	I41STK_FVEC.FSEL,ds ; Save for later use

	mov	OLDI41STK_FVEC.FSEL,ss ; Save old stack
	mov	OLDI41STK_FVEC.FOFF,esp ; ...pointer
	add	OLDI41STK_FVEC.FOFF,@I41STK_PUSH ; Strip off PUSHed values

	push	I41STK_FVEC.FSEL ; Save selector as word
	push	I41STK_FVEC.FOFF ; ...	offset

I41PERR_STR struc

I41PERR_FVEC df ?		; New stack pointer
I41PERR_DS dw	?		; Original DS

I41PERR_STR ends

; Now SS:ESP ==> I41PERR_STR

	mov	ds,[esp].I41PERR_DS ; Restore original DS
	assume	ds:nothing	; Tell the assembler about it

	lss	esp,[esp].I41PERR_FVEC ; Switch to new stack
	assume	ss:DGROUP	; Tell the assembler about it

	sub	I41STK_FVEC.FOFF,@I41STK_UNIT ; Prepare for next stack

; Make room for original stack contents

	sub	esp,(size PARAMSTK_STR) - PARAMSTK_EIP

	push	OLDI41STK_FVEC.FSEL.EDD ; Save to restore later
	push	OLDI41STK_FVEC.FOFF ; ...

	assume	ss:nothing	; Tell the assembler about it

	pushad			; Save registers
	REGSAVE <ds,es,fs,gs>	; ...
	mov	ebp,esp 	; Hello, Mr. Stack

; Copy original stack contents to local stack

	lfs	esi,[ebp].PARAMSTK_OLDSTK ; Address old stack
	assume	fs:nothing	; Tell the assembler about it

	mov	eax,fs:[esi - PARAMSTK_EIP].PARAMSTK_EIP ; Get original EIP
	mov	[ebp].PARAMSTK_EIP,eax ; Save in new stack

	mov	ax,fs:[esi - PARAMSTK_EIP].PARAMSTK_CS ; Get original CS
	mov	[ebp].PARAMSTK_CS,ax ; Save in new stack

	mov	eax,fs:[esi - PARAMSTK_EIP].PARAMSTK_EFL ; Get original EFL
	mov	[ebp].PARAMSTK_EFL,eax ; Save in new stack

	mov	eax,fs:[esi - PARAMSTK_EIP].PARAMSTK_ESP ; Get original ESP
	mov	[ebp].PARAMSTK_ESP,eax ; Save in new stack

	mov	ax,fs:[esi - PARAMSTK_EIP].PARAMSTK_SS ; Get original SS
	mov	[ebp].PARAMSTK_SS,ax ; Save in new stack

; Use FS to address the incoming data as we need ES to point to DGROUP

	mov	eax,es		; Copy selector
	mov	fs,eax		; Address it
	assume	fs:nothing	; Tell the assembler about it

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	es,eax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

;;;;;;; mov	eax,cs		; Get code selector
;;;;;;; add	eax,type DESC_STR ; Skip to data selector
	mov	ds,eax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

; Determine the stack selector depending upon the return CS's RPL

	test	[ebp].PARAMSTK_CS,mask $PL ; Izit at PL0?
	mov	ax,ss		; Assume so
	jz	short @F	; Jump if so

	mov	ax,[ebp].PARAMSTK_SS ; Get caller's SS
@@:
	mov	gs,ax		; Address it
	assume	gs:nothing	; Tell the assembler about it

; Save the return address

	mov	eax,fs:[bx].PARAM_RETVEC ; Get the return address
	mov	RETVEC,eax	; Save for later use

; Loop through the stack looking for the return address

	mov	si,[ebp].PARAMSTK_PUSHAD.PUSHAD_EBP.ELO ; Get caller's BP
@@:
	mov	si,gs:[si]	; Get next BP

	cmp	eax,gs:[si+2]	; Izit the same?
	jne	short @B	; Jump if not

	mov	si,gs:[si]	; Get next BP
	mov	CURBP,si	; Save for later use

; Format a line with the relevant data

	mov	ax,fs:[bx].PARAM_ERR ; Get the error code
	lea	edi,PARAMMSG1_ERR ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display the name of the current task

	mov	PARAMMSG1_TASK.EDQLO,'????' ; In case not found
	mov	PARAMMSG1_TASK.EDQHI,'????' ; ...

	call	GetCurTDB	; Get current task database selector into AX
	jc	short @F	; Jump if not valid

	push	fs		; Save for a moment

	mov	fs,ax		; Address it
	assume	fs:nothing	; Tell the assembler about it

	mov	eax,fs:[0].TDB_MODNAME.EDQLO ; Get the low-order 4 bytes
	mov	PARAMMSG1_TASK.EDQLO,eax ; Save in data area
	mov	eax,fs:[0].TDB_MODNAME.EDQHI ; Get the high-order 4 bytes
	mov	PARAMMSG1_TASK.EDQHI,eax ; Save in data area

	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler about it
@@:

; Display the parameter error lines

	lea	esi,PARAMMSG1	; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

	lea	esi,MSG_CRLF32	; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

; Trundle through the stack displaying info about each level

LCL_INT41_PARAMERR_NEXTBP:

; Search through the Global Heap for the module which owns
; the return address.

	push	offset DGROUP:PARAMMSG2_MOD ; Pass the buffer offset in DGROUP
	push	RETVEC.VSEG.EDD ; ... the return segment
	call	COPY_WGHOWNR	; Copy the owner name
	jc	short LCL_INT41_PARAMERR_INITERR ; Jump if not initialized

	cmp	PARAMMSG2_MOD[0],0 ; Izit unknown?
	jne	short @F	; Jump if not

	mov	PARAMMSG2_MOD[0].EDD,'????' ; Assume not valid
	mov	PARAMMSG2_MOD[4].EDD,'????' ; ...
	mov	PARAMMSG2_MOD[8].EDD,'???.' ; ...
@@:

; Padd the module name with blanks to length 8.3

	lea	edi,PARAMMSG2_MOD ; ES:EDI ==> module name
	mov	ecx,8+1+3	; Get maximum length
	mov	al,0		; Terminator
  repne scas	PARAMMSG2_MOD[edi] ; Search for terminator
	jne	short @F	; Jump if not found

	mov	al,' '          ; Filler
	dec	edi		; Backup to terminator
	inc	ecx		; ...
    rep stos	PARAMMSG2_MOD[edi] ; Fill with trailing blanks
@@:
	lea	esi,PARAMMSG2A	; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service
LCL_INT41_PARAMERR_INITERR:

; Format the return address

	mov	ax,RETVEC.VSEG	; Get the return segment
	lea	edi,PARAMMSG2_RETS ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	ax,RETVEC.VOFF	; Get the return offset
	lea	edi,PARAMMSG2_RETO ; ES:EDI ==> output format area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	lea	esi,PARAMMSG2B	; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

; Display the nearest symbol name to the address in RETVEC

	movzx	eax,RETVEC.VOFF ; Get offset as dword

	push	RETVEC.VSEG.EDD ; Pass selector as dword
	push	eax		; ...  offset
	push	@PARAMERR_MAXOFF ; ... maximum offset to symbol
	push	offset DGROUP:PARAMMSG2_OFF1 ; Pass offset to symbol offset
	push	offset DGROUP:PARAMMSG2_SYM1 ; Pass offset to symbol save area
	push	PARAMMSG2_SYMLEN ; Pass maximum length of ...
	call	FindAddr	; Find the address
				; Return with EAX = length copied
	jc	short @F	; Jump if not found

; Display the symbol name

	lea	esi,PARAMMSG2_SYM ; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

; Display the formatted offset

	lea	esi,PARAMMSG2_OFF ; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service
@@:
	lea	esi,MSG_CRLF32	; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

; If the return address points to a far jump immediate dword, it's
; a thunk back to a 32-bit app

	push	fs		; Save for a moment

	xor	edi,edi 	; Zero to use as dword
	lfs	di,RETVEC	; Get return addres
	assume	fs:nothing	; Tell the assembler about it

	push	2		; Length in bytes
	push	fs		; Pass selector
	push	edi		; Pass offset
	call	ValidMem	; Validate the memory
	jc	short @F	; Jump if not valid

	cmp	fs:[edi].ELO,@OPCOD_JMPFD ; Izit far jump immediate dword?
	clc			; So we don't take the first jump
@@:
	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler about it
	jc	short @F	; Jump if not
	je	near ptr LCL_INT41_PARAMERR_DONE ; Jump if we're done
@@:
	movzx	esi,CURBP	; Get current BP

; Ensure that GS:SI is valid

	push	2		; Length in bytes
	push	gs		; Pass selector
	push	esi		; Pass offset
	call	ValidMem	; Validate the memory
	jc	near ptr LCL_INT41_PARAMERR_DONE2 ; Jump if not valid

	mov	ax,gs:[esi]	; Get next BP

	cmp	si,ax		; Izit in sequence?
	jae	near ptr LCL_INT41_PARAMERR_DONE2 ; Jump if not

	btr	ax,0		; Izit near return?
	mov	CURBP,ax	; Save for later use
	jnc	short @F	; Jump if not

	mov	eax,RETVEC	; Get current return address
	mov	ax,gs:[si+2]	; Get next offset

	jmp	short LCL_INT41_PARAMERR_LOOPBP ; Join common code

@@:
	mov	eax,gs:[si+2]	; Get next address
LCL_INT41_PARAMERR_LOOPBP:
	mov	RETVEC.VOFF,ax	; Save the offset
	shr	eax,16		; Shift down the selector

; Ensure that the selector is code,
; otherwise we're done

	lar	esi,eax 	; Get the A/R word
	jnz	near ptr LCL_INT41_PARAMERR_DONE2 ; Jump if invalid

	test	esi,mask $DT_DC ; Izit code/data?
	jz	near ptr LCL_INT41_PARAMERR_DONE2 ; Jump if not

	test	esi,mask $DC_COD ; Izit code?
	jz	short LCL_INT41_PARAMERR_DONE2 ; Jump if not

; Ensure that the selector is valid,
; otherwise assume the address is near.

	verr	ax		; Izit valid for reading?
	jnz	short @F	; Jump if not

; Ensure the offset is within the selector limit,
; otherwise assume the address is near.

	lsl	esi,eax 	; Get the selector limit
	movzx	edi,RETVEC.VOFF ; Get the offset

	cmp	edi,esi 	; Izit within limits?
	jae	short @F	; Jump if not

	mov	RETVEC.VSEG,ax	; Save for later use
@@:
	jmp	LCL_INT41_PARAMERR_NEXTBP ; Go around again

; We've reached a thunk to a 32-bit app

LCL_INT41_PARAMERR_DONE:
	push	fs		; Save for a moment

; Get base address of the PE file's module

	call	GetCurTDB	; Get current task database selector into AX
	jc	short LCL_INT41_PARAMERR_DONE1 ; Jump if not valid

; Get the module handle for the task

	mov	fs,ax		; Address it
	assume	fs:nothing	; Tell the assembler about it

	mov	ax,fs:[0].TDB_MOD ; Get the module handle for the task

; Validate the selector

	verr	ax		; Izit valid for reading?
	jnz	short LCL_INT41_PARAMERR_DONE1 ; Jump if not

	mov	fs,ax		; Address it
	assume	fs:nothing	; Tell the assembler about it

; Get the PE file base address in memory

	test	fs:[0].MOD_FLAGS,MDBF_WIN32 ; Izit a PE module?
	jz	short LCL_INT41_PARAMERR_DONE1 ; Jump if not

	mov	esi,fs:[0].MOD_PE_BASE ; Get PE-only base address

	mov	fs,COMMON.FILE_4GB ; Get all memory selector
	assume	fs:AGROUP	; Tell the assembler about it

; In case the linear address ESI isn't mapped in, we'd better check it

	mov	ecx,4096	; # bytes we need
	mov	eax,Win386_AddrValid ; Function code to check validity of
				; linear address in ESI for CX bytes
	int	Win386_Query_Int ; Request Win386 services
				; Return with AX = 1 if OK, 0 if not
	cmp	ax,1		; Izit valid?
	jb	short LCL_INT41_PARAMERR_DONE1 ; Jump if not

	cmp	AGROUP:[esi].EXE_SIGN,@EXE_SIGN ; Izit a valid signature?
	jne	short LCL_INT41_PARAMERR_DONE1 ; Jump if not

	mov	eax,AGROUP:[esi].DOSHDR_LFANEW ; Get offset to PE header

	cmp	AGROUP:[esi+eax].EDD,@PE_SIG ; Izit a valid signature?
	jne	short LCL_INT41_PARAMERR_DONE1 ; Jump if not










LCL_INT41_PARAMERR_DONE1:
	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler about it
LCL_INT41_PARAMERR_DONE2:

; Display a prefix to the log error format display

	lea	esi,PARAMMSG_PRE ; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service


COMMENT|

Display the error code in log error format

BX	=	LOWORD or BYTE
CX	=	error code
DX	=	HIWORD of DWORD (DX:BX)

|

	mov	cx,fs:[bx].PARAM_ERR ; Get the error code
	mov	dx,fs:[bx].PARAM_BADVEC.EHI ; Get the high-order word
	mov	bx,fs:[bx].PARAM_BADVEC.ELO ; Get the low-order word

	pushfd			; Simulate IRETD frame
	FCALLD	LCL_INT41_LOGERROR1 ; Log the error (note AX != @I41_LOGERROR)

	cmp	WKD_WINDBG,1	; Izit the debugging version of Windows?
	je	short LCL_INT41_PARAMERR_EXIT ; Jump if so (note CF=0)
				; (shortly, we'll see a message asking
				;  "Abort, Break, Exit, Ignore?")
	test	WKD_FLAG,@WKD_QUIET ; Should we be seen but not heard?
	jnz	short LCL_INT41_PARAMERR_EXIT ; Jump if so (note CF=0)

; Display the Break/Ignore/Quiet message

LCL_INT41_PARAMERR_BIQ:
	lea	esi,MSG_BIQ	; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

; Request input from the user

	mov	ax,@I41_IN_CHAR ; Get function code for GetChar
	int	41h		; Request WKD service
				; Return with AL = response
	call	U32_LOWERCASE	; Convert AL to lowercase

	cmp	al,'i'          ; Izit Ignore?
	je	short LCL_INT41_PARAMERR_EXIT ; Jump if so (note CF=0)

	cmp	al,'q'          ; Izit Quiet?
	je	short LCL_INT41_PARAMERR_QUIET ; Jump if so

	cmp	al,'b'          ; Izit Break?
	jne	short LCL_INT41_PARAMERR_BIQ ; Jump if not

	stc			; Mark as breakpointing

	jmp	short LCL_INT41_PARAMERR_EXIT ; Join common code

LCL_INT41_PARAMERR_QUIET:
	or	WKD_FLAG,@WKD_QUIET ; Mark as being quiet (note CF=0)
LCL_INT41_PARAMERR_EXIT:
	pushfd			; Save flags (CF is significant)
	add	I41STK_FVEC.FOFF,@I41STK_UNIT ; Strip off old stack
	popfd			; Restore

	REGREST <gs,fs,es,ds>	; Restore
	assume	ds:nothing	; Tell the assembler about it
	assume	es:nothing	; ...
	assume	fs:nothing	; ...
	assume	gs:nothing	; ...
	popad			; Restore
				; Note CF is significant
	lss	esp,[esp].EDF	; Switch back to original stack
	assume	ss:nothing	; Tell the assembler about it

	jc	near ptr LCL_INT41_IRETD_BP ; Jump if we're breakpointing

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Printf 32-bit

This function formats output according to standard "C"
printf syntax.

On entry:

AX	=	0073h
DS:ESI	==>	format string
ES:EDI	==>	start of dword arguments

On exit:

EAX	=	# characters printed

|

PF_STR	struc

PF_CNT	 dd	?		; # chars printed
PF_FLAG  dd	?		; Flags (see @PF_xxx below)
PF_WIDTH dd	?		; Width (0=default)
PF_PREC  dd	?		; Precision (1=default)
PF_TYPE  db	?,?,?,? 	; Type
PF_T1	 dd	?		; Temporary value #1
PF_T2	 dd	?		; ...		  #2

PF_STR	ends

PF_REC	record	\
		$PF_XADDR:1,\
		$PF_OFF:1,  \
		$PF_OFF32:1,\
		$PF_OFF16:1,\
		$PF_PMSEG:1,\
		$PF_RMSEG:1,\
		$PF_VEC:1,  \
		$PF_ADDRS:1,\
		$PF_WORD:1, \
		$PF_ZPAD:1, \
		$PF_PLUS:1, \
		$PF_LEFT:1, \
		$PF_0X	:1, \
		$PF_BLNK:1, \
		$PF_WARG:1, \
		$PF_PARG:1, \
		$PF_PREV:1, \
		$PF_NEXT:1, \
		$PF_SDEC:1, \
		$PF_LHEX:1

@PF_XADDR equ	(mask $PF_XADDR); Address is no address
@PF_OFF   equ	(mask $PF_OFF)	; Address is offset only
@PF_OFF32 equ	(mask $PF_OFF32); Address is 32-bit offset
@PF_OFF16 equ	(mask $PF_OFF16); Address is 16-bit offset
@PF_PMSEG equ	(mask $PF_PMSEG); Argument is PM selector
@PF_RMSEG equ	(mask $PF_RMSEG); Argument is RM segment
@PF_VEC  equ	(mask $PF_VEC)	; Argument is vector format
@PF_ADDRS equ	(mask $PF_ADDRS); Points to AddrS struc
@PF_WORD equ	(mask $PF_WORD) ; Use word argument size
@PF_ZPAD equ	(mask $PF_ZPAD) ; Zero-pad the output
@PF_PLUS equ	(mask $PF_PLUS) ; Prefix with plus sign if positive
@PF_LEFT equ	(mask $PF_LEFT) ; Left-justify output
@PF_0X	 equ	(mask $PF_0X  ) ; Prefix with 0, 0x, or 0X for o, x, and X
@PF_BLNK equ	(mask $PF_BLNK) ; Prefix with blank if positive
@PF_WARG equ	(mask $PF_WARG) ; Get width from next argument
@PF_PARG equ	(mask $PF_PARG) ; Get precision from next argument
@PF_PREV equ	(mask $PF_PREV) ; Use preceding symbol address/offset
@PF_NEXT equ	(mask $PF_NEXT) ; Use next symbol address/offset
@PF_SDEC equ	(mask $PF_SDEC) ; Display as signed decimal
@PF_LHEX equ	(mask $PF_LHEX) ; Display as lowercase hex

LCL_INT41_PRINTF32:
	push	ebp		; Prepare to address the stack
	sub	esp,type PF_STR ; Make room for local variables
	mov	ebp,esp 	; Hello, Mr. Stack

	mov	[ebp].PF_CNT,0	; Initialize # chars printed

	REGSAVE <edx,esi,es,fs,gs>

	mov	eax,es		; Get argument selector
	mov	fs,eax		; Address it
	assume	fs:nothing	; Tell the assembler about it

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	es,eax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it
LCL_INT41_PRINTF32_NEXTTYPE:
	mov	[ebp].PF_FLAG,0 ; Initialize flags
	mov	[ebp].PF_WIDTH,0 ; ...
	mov	[ebp].PF_PREC,1 ; ...

	lods	ds:[esi].LO	; Get next char

	and	al,al		; Izit EOL?
	je	near ptr LCL_INT41_PRINTF32_EXIT ; Jump if so

	cmp	al,'%'          ; Izit format marker?
	je	short LCL_INT41_PRINTF32_NEXT ; Jump if so
LCL_INT41_PRINTF32_OUT:
	mov	dl,al		; Copy to output register
	mov	ax,@I41_OUT_CHAR ; Get function code to display char in DL
	int	41h		; Request WKD service

	inc	[ebp].PF_CNT	; Count in another char printed

	jmp	short LCL_INT41_PRINTF32_NEXTTYPE ; Go around again

LCL_INT41_PRINTF32_NEXT:
	lods	ds:[esi].LO	; Get next char

	cmp	al,'%'          ; Izit format marker?
	je	short LCL_INT41_PRINTF32_OUT ; Jump if so

; Check for flags

	cmp	al,'0'          ; Izit zero-pad modifier?
	jne	short @F	; Jump if not

	or	[ebp].PF_FLAG,@PF_ZPAD ; Mark as zero-padding

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:
	cmp	al,'+'          ; Izit include plus sign if positive?
	jne	short @F	; Jump if not

	or	[ebp].PF_FLAG,@PF_PLUS ; Mark as plus sign prefixing

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:
	cmp	al,'-'          ; Izit left-justify output?
	jne	short @F	; Jump if not

	or	[ebp].PF_FLAG,@PF_LEFT ; Mark as left-justifying output

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:
	cmp	al,'#'          ; Izit 0x prefix?
	jne	short @F	; Jump if not

	or	[ebp].PF_FLAG,@PF_0X ; Mark as 0x prefixing

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:
	cmp	al,' '          ; Izit blank prefix?
	jne	short @F	; Jump if not

	or	[ebp].PF_FLAG,@PF_BLNK ; Mark as blank-prefixing

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:

; Check for width

	cmp	al,'*'          ; Izit get width from next arg?
	jne	short @F	; Jump if not

	or	[ebp].PF_FLAG,@PF_WARG ; Mark as width from argument

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:
	cmp	al,'1'          ; Izit width #?
	jb	short @F	; Jump if not

	cmp	al,'9'          ; Izit width #?
	ja	short @F	; Jump if not

	dec	esi		; Back off to first digit

	mov	ecx,10	       ; Convert as decimal
	call	U32_BASE2BIN   ; Return value in EAX, CF significant
;;;;;;; jc	short LCL_INT41_PRINTF32_ERR ; Jump if error

	mov	[ebp].PF_WIDTH,eax ; Save for later use

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:

; Check for precision

	cmp	al,'.'          ; Izit precision marker?
	jne	short @F	; Jump if not

	mov	ecx,10	       ; Convert as decimal
	call	U32_BASE2BIN   ; Return value in EAX, CF significant
;;;;;;; jc	short LCL_INT41_PRINTF32_ERR ; Jump if error

	mov	[ebp].PF_PREC,eax ; Save for later use

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:

; Check for address argument size

	cmp	al,'l'          ; Izit dword argument size modifier?
	jne	short @F	; Jump if not

	and	[ebp].PF_FLAG,not @PF_WORD ; Remove word size

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:
	cmp	al,'h'          ; Izit word argument size modifier?
	jne	short @F	; Jump if not

	or	[ebp].PF_FLAG,@PF_WORD ; Include word size

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:
	cmp	al,'a'          ; Izit AddrS modifier?
	jne	short @F	; Jump if not

	or	[ebp].PF_FLAG,@PF_ADDRS ; Include AddrS

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:
	cmp	al,'p'          ; Izit preceding symbol?
	jne	short @F	; Jump if not

	or	[ebp].PF_FLAG,@PF_PREV ; Mark as preceding symbol

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:
	cmp	al,'n'          ; Izit next symbol?
	jne	short @F	; Jump if not

	or	[ebp].PF_FLAG,@PF_NEXT ; Mark as next symbol

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:
	cmp	al,'F'          ; Izit vector format?
	jne	short @F	; Jump if not

	or	[ebp].PF_FLAG,@PF_VEC ; Mark as vector format

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:
	cmp	al,'R'          ; Izit RM segment?
	jne	short @F	; Jump if not

	or	[ebp].PF_FLAG,@PF_RMSEG ; Mark as RM segment

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:
	cmp	al,'P'          ; Izit PM segment?
	jne	short @F	; Jump if not

	or	[ebp].PF_FLAG,@PF_PMSEG ; Mark as PM selector

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:

; Check for address display size or format

	cmp	al,'H'          ; Izit 16-bit offset?
	jne	short @F	; Jump if not

	or	[ebp].PF_FLAG,@PF_OFF16 ; Mark as 16-bit offset

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:
	cmp	al,'L'          ; Izit 32-bit offset?
	jne	short @F	; Jump if not

	or	[ebp].PF_FLAG,@PF_OFF32 ; Mark as 32-bit offset

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:
	cmp	al,'N'          ; Izit offset only?
	jne	short @F	; Jump if not

	or	[ebp].PF_FLAG,@PF_OFF ; Mark as offset only

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:
	cmp	al,'Z'          ; Izit no address?
	jne	short @F	; Jump if not

	or	[ebp].PF_FLAG,@PF_XADDR ; Mark as no address

	jmp	LCL_INT41_PRINTF32_NEXT ; Join common code

@@:

; Check for type

	mov	[ebp].PF_TYPE,al ; Save for later use

	cmp	al,'c'          ; Izit char?
	je	short LCL_INT41_PRINTF32_CHAR ; Jump if so

	cmp	al,'d'          ; Izit (signed) decimal?
	je	short LCL_INT41_PRINTF32_SDEC ; Jump if so

	cmp	al,'u'          ; Izit unsigned decimal?
	je	short LCL_INT41_PRINTF32_UDEC ; Jump if so

	cmp	al,'x'          ; Izit lowercase hex?
	je	near ptr LCL_INT41_PRINTF32_LHEX ; Jump if so

	cmp	al,'X'          ; Izit uppercase hex?
	je	near ptr LCL_INT41_PRINTF32_UHEX ; Jump if so

	cmp	al,'o'          ; Izit octal?
	je	short LCL_INT41_PRINTF32_OCT ; Jump if so

	cmp	al,'b'          ; Izit binary?
	je	short LCL_INT41_PRINTF32_BIN ; Jump if so

	cmp	al,'s'          ; Izit string?
	je	near ptr LCL_INT41_PRINTF32_STR ; Jump if so

	int	03h		; Call ourselves


; Character

LCL_INT41_PRINTF32_CHAR:
	call	PF_GETVAL	; Get next argument value into EAX
	mov	dl,al		; Copy to ouput register

	jmp	LCL_INT41_PRINTF32_OUT ; Jump if so


; Signed and unsigned decimal

LCL_INT41_PRINTF32_SDEC:
	or	[ebp].PF_FLAG,@PF_SDEC ; Mark as signed decimal
LCL_INT41_PRINTF32_UDEC:
	int	03h		; Call ourselves

	call	PF_INDIRECT	; Fill in indirect width/precision

	call	PF_GETVAL	; Get next argument value into EAX
	jns	short @F	; Jump if non-negative

	test	[ebp].PF_FLAG,@PF_SDEC ; Izit signed decimal?
	jz	short @F	; Jump if not

	push	eax		; Save for a moment

	mov	dl,'-'          ; Copy to output register
	mov	ax,@I41_OUT_CHAR ; Get function code to display char in DL
	int	41h		; Request WKD service

	pop	eax		; Restore

	inc	[ebp].PF_CNT	; Count in another char printed
@@:
	xor	edx,edx 	; Zssume not left-justified

	test	[ebp].PF_FLAG,@PF_LEFT ; Izit left-justified?
	jz	short @F	; Jump if not

	mov	edx,@DEC_LEFT	; Assume left-justified
@@:
	REGSAVE <esi,edi,ds>	; Save for a moment

	lea	edi,MSG_PRINTF	; ES:EDI ==> output save area
	mov	esi,edi 	; Copy for output string

	push	edx		; Pass flags
	call	DD2DEC		; Convert EAX to decimal at ES:EDI

	mov	eax,es		; Get DGROUP selector
	mov	ds,eax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

	REGREST <ds,edi,esi>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	jmp	LCL_INT41_PRINTF32_NEXTTYPE ; Go around again

; Octal

LCL_INT41_PRINTF32_OCT:
	mov	[ebp].PF_T1,3	; Rotate amount
	mov	[ebp].PF_T2,07h ; Mask value

	jmp	short LCL_INT41_PRINTF32_HEXCOM ; Join common code

; Binary

LCL_INT41_PRINTF32_BIN:
	mov	[ebp].PF_T1,1	; Rotate amount
	mov	[ebp].PF_T2,01h ; Mask value

	jmp	short LCL_INT41_PRINTF32_HEXCOM ; Join common code

; Lower and uppercase hex

LCL_INT41_PRINTF32_LHEX:
	or	[ebp].PF_FLAG,@PF_LHEX ; Mark as signed decimal
LCL_INT41_PRINTF32_UHEX:
	mov	[ebp].PF_T1,4	; Rotate amount
	mov	[ebp].PF_T2,0Fh ; Mask value
LCL_INT41_PRINTF32_HEXCOM:
	call	PF_INDIRECT	; Fill in indirect width/precision

	call	PF_GETVAL	; Get next argument value into EAX
	mov	edx,eax 	; Copy to safe register

	btr	[ebp].PF_FLAG,$PF_LHEX ; Izit lowercase hex?
	lea	ebx,PF_XLATLO	; Assume it's lowercase
	jc	short @F	; Jump if so

	lea	ebx,PF_XLATHI	; Assume it's uppercase
@@:
	mov	ecx,[ebp].PF_PREC ; Get precision

	cmp	ecx,[ebp].PF_WIDTH ; Use larger of precision and width
	jae	short @F	; Jump if larger

	mov	ecx,[ebp].PF_WIDTH ; Get width
@@:
LCL_INT41_PRINTF32_HEX_NEXT:
	push	ecx		; Save for a moment

	mov	ecx,[ebp].PF_T1 ; Get rotate amount
	rol	edx,cl		; Shift out next digit

	pop	ecx		; Restore

	mov	al,dl		; Copy to temp register
	and	al,[ebp].PF_T2.LO ; Isolate the digit
	xlat	PF_XLATLO[ebx] ; Translate it

	push	edx		; Save for a moment

	mov	dl,al		; Copy to output register
	mov	ax,@I41_OUT_CHAR ; Get function code to display char in DL
	int	41h		; Request WKD service

	inc	[ebp].PF_CNT	; Count in another char printed

	pop	edx		; Restore

	loop	LCL_INT41_PRINTF32_HEX_NEXT ; Jump if more width/precision

	jmp	LCL_INT41_PRINTF32_NEXTTYPE ; Go around again


; String

LCL_INT41_PRINTF32_STR:
	call	PF_INDIRECT	; Fill in indirect width/precision
	call	PF_GETADDR	; Get next argument into EAX as address

	mov	esi,eax 	; AGROUP:ESI ==> string
@@:
	lods	AGROUP:[esi].LO ; Get next character

	cmp	al,0		; Izit EOS?
	je	short @F	; Jump if so

	mov	dl,al		; Copy to output register
	mov	ax,@I41_OUT_CHAR ; Get function code to display char in DL
	int	41h		; Request WKD service

	inc	[ebp].PF_CNT	; Count in another char printed

	jmp	@B		; Go around again

@@:
	jmp	LCL_INT41_PRINTF32_NEXTTYPE ; Go around again


LCL_INT41_PRINTF32_EXIT:
	REGREST <gs,fs,es,esi,edx> ; Restore
	assume	es:nothing,fs:nothing ; Tell the assembler about it
	assume	gs:nothing	; Tell the assembler about it

	mov	eax,[ebp].PF_CNT ; Get # chars printed

	add	esp,type PF_STR ; Strip from the stack
	pop	ebp		; Restore

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Get register set

This function copies the current register set.

On entry:

AX	=	0075h
DS:ESI	==>	SaveRegs_struc

|

LCL_INT41_GET_REGS:
	REGSAVE <eax,edi,es>	; Save registers

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	es,eax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	cmp	REENTRY,1	; Check re-entry level
	jae	short @F	; Jump if SWAT is already active

	int	03h		; Call our debugger
@@:
	mov	edi,esi 	; DS:EDI ==> Save register struc
	call	CopyWKDRegs	; Copy WKD registers from FORW_STR to DS:EDI

	REGREST <es,edi,eax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Set alternate register set

This function temporary sets the debugger's registers to values passed
in the structure.  If an "r" command is executed or the debugged code
is returned to (via the "g", "t" or "p" commands), the register set
reverts to the debugged code's registers.

On entry:

AX	=	0076h
CX	=	thread ID, 0 use current thread ID
DS:ESI	==>	address of SaveRegs_Struc structure

|

LCL_INT41_SET_ALTREG:
	REGSAVE <eax,ecx,esi,edi,es> ; Save registers

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	es,eax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	cld			; String ops forwardly

	lea	edi,SaveRegs	; ES:EDI ==> Save register struc
	mov	ecx,size SaveRegs_Struc ; Get size of struc in bytes
    rep movs	SaveRegs[edi].LO,ds:[esi].LO ; Copy to local storage

	REGREST <es,edi,esi,ecx,eax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Get command line char

On entry:

AX	=	0077h
BL	=	0 peek at the char, don't increment text pointer,
		  leading white space isn't skipped
	=	1 get the character, increment text pointer,
		  leading white space is skipped
	=	2 peek at the char, don't increment text pointer,
		  leading white space is skipped

On exit:

AL	=	command line char
AH	=	0 if no more characters (EOL)

|

LCL_INT41_GETCMDCHAR:
	REGSAVE <esi,ds>	; Save registers

	mov	esi,cs		; Get code selector
	add	esi,type DESC_STR ; Skip to data selector
	mov	ds,esi		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	mov	esi,CMD_LINE_OFF ; DS:ESI ==> command line

; Skip over leading white space if requested to

	cmp	bl,0		; Skip leading white space?
	je	short LCL_INT41_GETCMDCHAR_XSKIP ; Jump if not
@@:
	lods	ds:[esi].LO	; Get next char

	cmp	al,' '          ; Izit white space?
	je	short @B	; Jump if so

	cmp	al,TAB		; Izit white space?
	je	short @B	; Jump if so

	dec	esi		; Back off to last non-white space char
LCL_INT41_GETCMDCHAR_XSKIP:
	lods	ds:[esi].LO	; Get next char
	mov	ah,al		; Save as EOL marker

	cmp	bl,1		; Izit get and increment?
	jne	short LCL_INT41_GETCMDCHAR_EXIT ; Jump if not

	cmp	al,0		; Izit EOL?
	je	short LCL_INT41_GETCMDCHAR_EXIT ; Jump if so

	mov	CMD_LINE_OFF,esi ; Save for later use
LCL_INT41_GETCMDCHAR_EXIT:
	REGREST <ds,esi>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Verify memory

On entry:

AX	=	0079h
ECX	=	length of memory in bytes
DS:ESI	==>	memory to verify

On exit:

AX	=	0 if memory valid
	!=	0 if memory invalid

|

LCL_INT41_VER_MEM:
	REGSAVE <ecx,esi,edi,ds,gs> ; Save for a moment

	mov	edi,ds		; Copy incoming selector

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	ds,eax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

; Convert DS:ESI to linear address

	push	edi		; Pass selector
	call	SEL2BASE	; Return with EAX == selector base address

	add	esi,eax 	; Add to get linear address

	call	READ_CR3	; Get the value into EAX
	and	ax,mask $PTE_FRM ; Isolate 4KB frame
	mov	edi,eax 	; Copy for later use

; Ensure that the PDE is present

	PUSHD	0		; Make room for original PTE
	PUSHD	1		; # PTEs to follow
	PUSHD	0		; Make room for original PDE
	push	esi		; Pass the linear address
	push	edi		; Pass the CR3 to use
	call	LIN2PPDIR	; Return with AGROUP:EAX ==> corresponding PDIR

	mov	eax,AGROUP:[eax] ; Get the corresponding PDIR

	call	LIN2PPTEZ	; Cleanup after LIN2PPDIR
	add	esp,1*4 	; Pop the PTE

	test	eax,mask $PTE_P ; Izit present?
	jz	short LCL_INT41_VER_MEM_INV ; Jump if not

	add	ecx,esi 	; Add to get ending address
	add	ecx,(4*1024)-1	; Round up to
	and	ecx,not ((4*1024)-1) ; ...page boundary

	mov	eax,esi 	; Copy linear address
	and	eax,not ((4*1024)-1) ; Round down to page boundary

	sub	ecx,eax 	; Subtract to get page rounded length (/4KB)
	shr	ecx,(12-2)-0	; Convert from bytes to 4KB in dwords

	sub	esp,ecx 	; Make room for original PTE

	shr	ecx,12-(12-2)	; Convert from 4KB in dwords to 4KB
	push	ecx		; # PTEs to follow
	PUSHD	0		; Make room for original PDE
	push	esi		; Pass the linear address
	push	edi		; Pass the CR3 to use
	call	LIN2PPTE	; Return with AGROUP:EAX ==> corresponding PTE

	mov	eax,AGROUP:[eax] ; Get the corresponding PTE

	call	LIN2PPTEZ	; Cleanup after LIN2PPTE
	lea	esp,[esp+ecx*4] ; Pop the PTEs

	test	eax,mask $PTE_P ; Izit present?
	jz	short LCL_INT41_VER_MEM_INV ; Jump if not

	xor	eax,eax 	; Mark as valid

	jmp	short LCL_INT41_VER_MEM_EXIT ; Join common exit code

LCL_INT41_VER_MEM_INV:
	mov	eax,1		; Ensure non-zero
LCL_INT41_VER_MEM_EXIT:
	REGREST <gs,ds,edi,esi,ecx> ; Restore
	assume	ds:nothing,gs:nothing ; Tell the assembler about it

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Print register set

This function prints (just like the "r" command) the either the
debugged code's registers or the alternate register set, set with
DS_SetAlternateRegisterSet function.

On entry:

AX	=	007Ah

|

LCL_INT41_PRINT_REG:
	REGSAVE <eax,esi,edi,ds,es> ; Save registers

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	ds,eax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it
	mov	es,eax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	cld			; String ops forwardly

PRINTREG_MAC4 macro REG

	mov	eax,SaveRegs.Debug_&REG ; Get value
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	endm			; PRINTREG_MAC4

PRINTREG_MAC2 macro REG

	mov	ax,SaveRegs.Debug_&REG ; Get value
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	endm			; PRINTREG_MAC4

; Display the EGP registers

	lea	esi,PrintEGPHeader ; DS:ESI ==> ASCIIZ string
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

	lea	edi,PrintEGP	; ES:EDI ==> output save area
	PRINTREG_MAC4 EAX	; Display register
	inc	edi		; ...
	PRINTREG_MAC4 EBX	; ...
	inc	edi		; ...
	PRINTREG_MAC4 ECX	; ...
	inc	edi		; ...
	PRINTREG_MAC4 EDX	; ...
	inc	edi		; ...
	PRINTREG_MAC4 ESI	; ...
	inc	edi		; ...
	PRINTREG_MAC4 EDI	; ...
	inc	edi		; ...
	PRINTREG_MAC4 EBP	; ...

	lea	esi,PrintEGP	; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

	lea	esi,PrintSelHeader ; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

	lea	edi,PrintSel	; ES:EDI ==> output save area
	PRINTREG_MAC2 CS	; Display register
	inc	edi		; ...
	PRINTREG_MAC4 EIP	; ...
	inc	edi		; ...
	PRINTREG_MAC2 SS	; ...
	inc	edi		; ...
	PRINTREG_MAC4 ESP	; ...
	inc	edi		; ...
	PRINTREG_MAC2 DS	; ...
	inc	edi		; ...
	PRINTREG_MAC2 ES	; ...
	inc	edi		; ...
	PRINTREG_MAC2 FS	; ...
	inc	edi		; ...
	PRINTREG_MAC2 GS	; ...
	inc	edi		; ...
	PRINTREG_MAC4 EFlags	; ...

	lea	esi,PrintSel	; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

	lea	esi,PrintXRnHeader ; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

	lea	edi,PrintXRn	; ES:EDI ==> output save area
	PRINTREG_MAC4 CR0	; Display register
	inc	edi		; ...
	PRINTREG_MAC4 CR2	; ...
	inc	edi		; ...
	PRINTREG_MAC4 CR3	; ...
	inc	edi		; ...
	PRINTREG_MAC2 ErrorCode ; ...
	inc	edi		; ...
	PRINTREG_MAC2 LDT	; ...
	inc	edi		; ...
	PRINTREG_MAC2 TR	; ...
	inc	edi		; ...
	PRINTREG_MAC2 GDT.DTR_LIM ; ...
	inc	edi		; ...
	PRINTREG_MAC4 GDT.DTR_BASE ; ...
	inc	edi		; ...
	PRINTREG_MAC2 IDT.DTR_LIM ; ...
	inc	edi		; ...
	PRINTREG_MAC4 IDT.DTR_BASE ; ...

	lea	esi,PrintXRn	; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

	REGREST <es,ds,edi,esi,eax> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Check a fault

On entry:

AX	=	007Fh
BX	=	fault #
CX	=	fault type mask
		DEBUG_FAULT_TYPE_V86
		DEBUG_FAULT_TYPE_PM
		DEBUG_FAULT_TYPE_RING0
		DEBUG_FAULT_TYPE_FIRST
		DEBUG_FAULT_TYPE_LAST

On exit:

AX	=	0 to tell W to handle the fault itself
	!=	0 to handle it ourselves (soon to be called
		  with AX=0083h)
|

LCL_INT41_CHECKFAULT:
	REGSAVE <ebx,ds>	; Save for a moment

	mov	ebx,cs		; Get code selector
	add	ebx,type DESC_STR ; Skip to data selector
	mov	ds,ebx		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	test	WKD_FLAG,@WKD_FLTON ; Should we trap this?
	jz	short LCL_INT41_CHECKFAULT_OFF2 ; Jump if not

	bts	WKD_FLAG,$WKD_FLTSET ; Mark as having happened
	jc	short LCL_INT41_CHECKFAULT_OFF1 ; Jump if second time

	btr	WKD_FLAG,$WKD_FLTSK ; Should we skip it this once?
	jnc	short LCL_INT41_CHECKFAULT_OFF3 ; Jump if not
LCL_INT41_CHECKFAULT_OFF1:
	and	WKD_FLAG,not @WKD_FLTSET ; Clear for the next time
LCL_INT41_CHECKFAULT_OFF2:
	xor	ax,ax		; Tell W to handle the fault itself
LCL_INT41_CHECKFAULT_OFF3:
	REGREST <ds,ebx>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Set break

On entry:

AX	=	0080h
DS:ESI	==>	BreakStruc

On exit:

AX	=	0 no error
	!=	0 error on BreakStruc address
|

LCL_INT41_SET_BREAK:
	REGSAVE <eax,es>	; Save for a moment

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	es,eax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	ax,ds:[esi].BS_BreakCS ; Get incoming CS
	xchg	ax,BreakStr.BS_BreakCS ; Swap 'em
	mov	ds:[esi].BS_BreakCS,ax ; Return old value

	mov	eax,ds:[esi].BS_BreakEIP ; Get incoming EIP
	xchg	eax,BreakStr.BS_BreakEIP ; Swap 'em
	mov	ds:[esi].BS_BreakEIP,eax ; Return old value

	mov	ax,ds:[esi].BS_BreakSS ; Get incoming SS
	xchg	ax,BreakStr.BS_BreakSS ; Swap 'em
	mov	ds:[esi].BS_BreakSS,ax ; Return old value

	mov	eax,ds:[esi].BS_BreakESP ; Get incoming ESP
	xchg	eax,BreakStr.BS_BreakESP ; Swap 'em
	mov	ds:[esi].BS_BreakESP,eax ; Return old value

	REGREST <es,eax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Trap a fault

On entry:

AX	=	0083h
BX	=	fault #
CX	=	faulting CS
EDX	=	...	 EIP
ESI	=	fault error code
EDI	=	faulting flags

On exit:

CX	=	Replacement CS
EDX	=	...	    EIP

|

INT41_F83_STR struc

INT41_F83_EBP dd ?		; Caller's EBP
INT41_F83_EIP dd ?		; ...	   EIP
INT41_F83_CS  dw ?,?		; ...	   CS with filler
INT41_F83_EFL dd ?		; ...	   EFLAGS

INT41_F83_STR ends


LCL_INT41_TRAPFAULT:
	push	ebx		; Save for a moment

; Search through the message strucs for this fault #
; and get the error message offset

	REGSAVE <ecx,edi,ds>	; Save for a moment

	mov	ecx,cs		; Get code selector
	add	ecx,type DESC_STR ; Skip to data selector
	mov	ds,ecx		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	mov	ecx,LCLMSG_LEN	; Get # message structures
	xor	edi,edi 	; Initialize index into LCLMSGTAB
@@:
	cmp	bx,LCLMSGTAB[edi].MSGTAB_INTNO ; Check the interrupt #
	je	short @F	; Jump if it's a match

	add	edi,size MSGTAB_STR ; Skip to next entry

	loop	@B		; Jump if more entries
@@:
	mov	ebx,LCLMSGTAB[edi].MSGTAB_PMSG ; PGROUP:EBX ==> fault message text

	REGREST <ds,edi,ecx>	; Restore
	assume	ds:nothing	; Tell the assembler about it

; Setup for call to common routine
; to set breakpoint at the faulting address.
; This is the only way we can get all the registers correct
; as this call isn't given enough information (such as EGPs)
; to display a SWAT screen immediately.

	push	ecx		; Pass CS
	push	edx		; ...  EIP
	push	esi		; ...  fault error code
	PUSHD	cs		; ...  segment of error message
	push	ebx		; ...  offset of ...
	call	INT41_GOTO	; Set msg and goto

	pop	ebx		; Restore

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Get COM base

On entry:

AX	=	008Ch

On exit:

AX	=	base of COM port

|

LCL_INT41_GET_BASE:
	xor	ax,ax		; Use base of zero

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Get a symbol

On entry:

AX	=	008Dh
DS:ESI	==>	ASCIIZ symbol name

On exit:

AX	=	0, no error
	=	1, symbol not found
	=	2, memory not loaded
ECX	=	linear address of symbol (if AX == 0)
EDX	=	Sel:Off of symbol	 (if AX == 0)

|

LCL_INT41_GETSYMBOL:
	REGSAVE <ds,es,gs>	; Save registers
	pushad			; Save all EGP registers
;;;;;;; mov	ebp,esp 	; SS:EBP ==> POPAD_STR

	cld			; String ops forwardly

; Find the length of the symbol to search for

	push	ds		; Pass the selector
	push	esi		; ...	   offset
	call	StrLen		; Return with length in EAX

	lea	edx,[eax+1]	; Copy to safer register, including
				; length byte

; Setup the symbol as length-name

	sub	esp,edx 	; Make room

	mov	[esp].LO,al	; Save length byte

	mov	eax,ss		; Get segment of destination
	mov	es,eax		; Address it
	assume	es:nothing	; Tell the assembler about it

	lea	edi,[esp+1]	; ES:EDI ==> destination
@@:
	lods	ds:[esi].LO	; Get next byte

	cmp	al,0		; Izit EOS?
	je	short @F	; Jump if so

	stos	es:[edi].LO	; Save on stack

	jmp	@B		; Go around again

@@:
	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	ds,eax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it
	mov	es,eax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

	push	ss		; Pass selector
	call	SEL2BASE	; Return with EAX == selector base address
	lea	esi,[esp+eax]	; GS:ESI ==> length-value format of name

; Setup FORW_STR

	sub	esp,size FORW_STR ; Allocate stack space
	mov	ebp,esp 	; Set up temporary FORW_STR at SS:EBP

; Save EGP registers in FORW_STR

	mov	[ebp].FORW_EDI,edi
	mov	[ebp].FORW_ESI,esi
	mov	[ebp].FORW_EBP,ebp
;;;;;;; mov	[ebp].FORW_ESP0,esp ; This one never gets used
	mov	[ebp].FORW_EBX,ebx
	mov	[ebp].FORW_EDX,edx
	mov	[ebp].FORW_ECX,ecx
	mov	[ebp].FORW_EAX,eax

; Caller return address is probably not needed

;;;;;;; mov	[ebp].FORW_RET.EDQLO,eip
;;;;;;; mov	[ebp].FORW_RET.EDQHI.ELO,cs
;;;;;;; mov	[ebp].FORW_EIP,?
	mov	[ebp].FORW_CS,cs

	sldt	[ebp].FORW_LDT	; Save LDT

	pushfd			; Get our flags
	pop	[ebp].FORW_EFL	; Put in structure

	mov	[ebp].FORW_ESP,esp ; Save ESP
	mov	[ebp].FORW_SS,ss ; Save SS

	mov	[ebp].FORW_ES,es ; ...	ES
	mov	[ebp].FORW_DS,ds ; ...	DS
	mov	[ebp].FORW_FS,fs ; ...	FS
	mov	[ebp].FORW_GS,gs ; ...	GS

; SS:EBP ==> valid FORW_STR

	call	SYMFILTER	; Return with ESI ==> new length-name
				; ...	      AL  =   old value at new length-name
	call	LCL_SYMSRCH	; Search for name at GS:ESI
				; DGROUP:EBX ==> matching entry if CF=0
	lea	esp,[esp+(size FORW_STR)] ; Clear temporary FORW_STR
				; from stack (CF unaffected)
	lea	esp,[esp+edx]	; Strip symbol from stack
	mov	ebp,esp 	; SS:EBP ==> POPAD_STR
	jc	short LCL_INT41_GETSYMBOL_NF ; Jump if not found

; Save linear address and selector:offset in ECX and EDX

	mov	eax,DGROUP:[ebx].SYM_ADDR ; Get the linear address
	mov	[ebp].PUSHAD_ECX,eax ; Save in ECX

	mov	ax,DGROUP:[ebx].SYM_FVEC.FSEL ; Get the selector
	mov	[ebp].PUSHAD_EDX.EHI,ax ; Save in high-order word of EDX

; Note that this interface doesn't handle 32-bit offsets

	mov	eax,DGROUP:[ebx].SYM_FVEC.FOFF ; Get the offset
	mov	[ebp].PUSHAD_EDX.ELO,ax ; Save in low-order word of EDX

	mov	[ebp].PUSHAD_EAX.ELO,0 ; Mark as no error

	jmp	short LCL_INT41_GETSYMBOL_EXIT ; Join common exit code

LCL_INT41_GETSYMBOL_NF:
	mov	[ebp].PUSHAD_EAX.ELO,1 ; Mark as not found
LCL_INT41_GETSYMBOL_EXIT:
	popad			; Restore
	REGREST <gs,es,ds>	; ...
	assume	ds:nothing,es:nothing ; Tell the assembler about it
	assume	gs:nothing	; ...

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Define a 32-bit segment

On entry:

AX	=	0150h
SI	=	00h - code selector
	=	01h - data selector
DX:EBX	==>	D386_Device_Params struc

On exit:

Nothing

|

LCL_INT41_LOADSEG32:
;;;;;;; int	03h		; Not handled as yet *FIXME*

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Free a 32-bit segment

On entry:

AX	=	0152h
BX	=	segment #
DX:EDI	==>	module name

On exit:

Nothing

|

LCL_INT41_FREESEG32:
	jmp	LCL_INT41_IRETD ; Return to caller

	pushad			; Save all EGP registers
	REGSAVE <ds,es,fs>	; Save registers

	mov	esi,edi 	; Copy module name offset
	mov	fs,edx		; Address the module name
	assume	fs:nothing	; Tell the assembler about it
				; FS:ESI ==> module name

; Setup segment registers for local use

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	ds,eax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it
	mov	es,eax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	ax,bx		; Copy segment being freed
	lea	edi,FREESEG32_MSG1 ; ES:EDI ==> output save area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Copy the module name to the message

	lea	edi,FREESEG32_MSG2 ; ES:EDI ==> output save area
	mov	ecx,8		; Maximum # chars in module name
@@:
	lods	fs:[esi].LO	; Get next character
	stos	es:[edi].LO	; Save it

	cmp	al,0		; Izit EOL?
	loopne	@B		; Jump if not
	jne	short @F	; Jump if we didn't end with a trailing zero

	dec	edi		; Back off to trailing zero
@@:
	mov	eax,(LF shl 8) or CR ; Get CR,LF,0,0
	stos	es:[edi].EDD	; Save trailing chars

	lea	esi,FREESEG32_MSG ; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

	REGREST <fs,es,ds>	; Restore
	assume	ds:nothing	; Tell the assembler about it
	assume	es:nothing	; ...
	assume	fs:nothing	; ...
	popad			; Restore

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Display load segment table

On entry:

AX	=	0E000h

On exit:

Nothing

|

LCL_INT41_DISPLS:
	pushad			; Save all EGP registers
	REGSAVE <ds,es,gs>	; Save to address DGROUP and AGROUP

	mov	eax,cs		; Get code selector
	add	eax,type DESC_STR ; Skip to data selector
	mov	ds,eax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it
	mov	es,eax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	gs,COMMON.FILE_4GB ; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

	mov	ecx,WKDLS_NEXT	; Get next index

	and	ecx,ecx 	; Anything to do?
	jz	near ptr LCL_INT41_DISPLS_EXIT ; Jump if nothing to do

	mov	ebx,PWKDLS	; Get offset in DGROUP of WKDLS entries

; Display the names

LCL_INT41_DISPLS_NEXT:
;;;;;;; test	DGROUP:[ebx].WKDLS_FLAG,@WKDLS_CODE ; Izit a code segment?
;;;;;;; jz	near ptr LCL_INT41_DISPLS_LOOP ; Jump if not
;;;;;;;
	test	DGROUP:[ebx].WKDLS_FLAG,@WKDLS_RM ; Izit a RM segment?
	jnz	near ptr LCL_INT41_DISPLS_LOOP ; Jump if so

; Display the prefix

	lea	esi,VxDNAME_PRE ; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

; Display the device name

	lea	esi,DGROUP:[ebx].WKDLS_DNAME ; DS:ESI ==> name to display
	call	DISP_NAME	; Display the name

; Display the middle prefix

	lea	esi,VxDNAME_MID ; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

; Display the module name

	lea	esi,DGROUP:[ebx].WKDLS_SNAME ; DS:ESI ==> name to display
	call	DISP_NAME	; Display the name

; Display the load address and length

	mov	ax,DGROUP:[ebx].WKDLS_SEL ; Get the selector
	lea	edi,VxDBASE_MSG1 ; ES:EDI ==> output save area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

	mov	eax,DGROUP:[ebx].WKDLS_BASE ; Get the base address
	lea	edi,VxDBASE_MSG2 ; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	mov	eax,DGROUP:[ebx].WKDLS_LEN ; Get the length
	lea	edi,VxDBASE_MSG3 ; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	lea	esi,VxDBASE_MSG ; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	int	41h		; Request WKD service

; Append a symbol table entry for this symbol
; The symbol name consists of the VxD name followed by 'Code'
; or 'Data', followed by the logical segment number

	call	APPEND_VxDSYMB	; Append it
LCL_INT41_DISPLS_LOOP:
	add	ebx,type WKDLS_STR ; Skip to next entry

	LOOPD	LCL_INT41_DISPLS_NEXT ; Jump if more entries to check
LCL_INT41_DISPLS_EXIT:
	REGREST <gs,es,ds>	; Restore
	assume	ds:nothing	; Tell the assembler about it
	assume	es:nothing	; Tell the assembler about it
	assume	gs:nothing	; Tell the assembler about it
	popad			; ...

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Return address of load segment table

On entry:

AX	=	0E001h

On exit:

ECX	=	# entries
ESI	==>	load segment table

|

LCL_INT41_GETLS:
	push	ds		; Save for a moment

	mov	ecx,cs		; Get code selector
	add	ecx,type DESC_STR ; Skip to data selector
	mov	ds,ecx		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	mov	ecx,WKDLS_NEXT	; Get next index
	mov	esi,PWKDLS	; DGROUP:ESI ==> WKDLS entries
	add	esi,SWATDATA	; AGROUP:ESI ==> ...

	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	jmp	LCL_INT41_IRETD ; Return to caller


COMMENT|

Return address of IPF struc table

On entry:

AX	=	0E002h

On exit:

ESI	==>	IPF struc table

|

LCL_INT41_GETIPF:
	push	ds		; Save for a moment

	mov	ecx,cs		; Get code selector
	add	ecx,type DESC_STR ; Skip to data selector
	mov	ds,ecx		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	lea	esi,IPFTAB	; DGROUP:ESI ==> IPF struc table
	add	esi,SWATDATA	; AGROUP:ESI ==> ...

	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	jmp	LCL_INT41_IRETD ; Return to caller


	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT41 endp			; End LCL_INT41 procedure
	NPPROC	GetCurTDB -- Get Current Task Database Selector
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get current task database selector

On exit:

AX	=	current task database selector
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <esi,fs>	; Save registers

	lfs	si,KVARS_VEC	; FS:SI ==> KVARS_STR
	assume	fs:nothing	; Tell the assembler about it

	mov	ax,fs:[si].KV_curTDB ; Get the selector

; Validate the TDB selector

	verr	ax		; Izit valid for reading?
	jnz	short GetCurTDBErr ; Jump if not

	mov	fs,ax		; Address it
	assume	fs:nothing	; Tell the assembler about it

	cmp	fs:[0].TDB_TDBSIG,@TDB_SIG ; Izit a TDB?
	je	short GetCurTDBExit ; Jump if so (note CF=0)
GetCurTDBErr:
	stc			; Mark as in error
GetCurTDBExit:
	REGREST <fs,esi>	; Restore
	assume	fs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GetCurTDB endp			; End GetCurTDB procedure
	NPPROC	FindAddr -- Find Symbol Nearest Address
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find symbol nearest address

On exit:

EAX	=	length of symbol copied (if CF=0)

CF	=	0 if successful
	=	1 if not (symbol too far)

|

FA_STR	struc

	dd	?		; Caller's EIP
	dd	?		; ...	   EBP
FA_SYMLEN dd	?		; Maximum symbol length
FA_SYM	dd	?		; Offset in DGROUP to symbol save area
FA_OFF	dd	?		; Offset in DGROUP to offset save area
FA_MAXOFF dd	?		; Maximum offset to symbol
FA_ADDR df	?		; Address to find
	dw	?		; Filler

FA_STR	ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ecx,edx,esi,edi> ; Save registers

; Search through the symbol names for the one with the same selector
; and the nearest offset

	mov	edi,SYMBASE	; Get offset in DGROUP of symbol table
	mov	edx,-1		; Set nearest offset (i.e., none)
FindAddrNextSymb:
	cmp	edi,SYMNEXT	; Izit the end-of-the-line?
	jae	short FindAddrEOL ; Jump if so

	mov	ax,DGROUP:[edi].SYM_FLAG ; Get the flags

	test	ax,@SYMFL_VM	; Izit a RM/VM symbol?
	jnz	short FindAddrLoopSymb ; Jump if so

	and	ax,mask $SYMFL_TYP ; Isolate the type field

	cmp	ax,@SYMTYP_DAT shl $SYMFL_TYP ; Izit code/data?
	jne	short FindAddrLoopSymb ; Jump if not

	mov	ax,[ebp].FA_ADDR.FSEL ; Get the return selector

	cmp	ax,DGROUP:[edi].SYM_FVEC.FSEL ; Izit the same?
	jne	short FindAddrLoopSymb ; Jump if not

	mov	eax,[ebp].FA_ADDR.FOFF ; Get the return offset

	sub	eax,DGROUP:[edi].SYM_FVEC.FOFF ; Izit below us?
	jb	short FindAddrLoopSymb ; Jump if not

	cmp	eax,edx 	; Izit nearer than the last one?
	ja	short FindAddrLoopSymb ; Jump if not

	mov	esi,edi 	; Save as nearest offset so far
	mov	edx,eax 	; ...
FindAddrLoopSymb:
	movzx	eax,DGROUP:[edi].SYM_NAMLEN ; Get name-length byte
	lea	edi,DGROUP:[edi].SYM_NAMLEN[1] ; Skip to name
	add	edi,eax 	; Skip over it

	jmp	FindAddrNextSymb ; Go around again

FindAddrEOL:

COMMENT|

We've reached the end-of-the-line.
If the offset to the nearest preceding symbol is not too far, display it.

|

	cmp	edx,[ebp].FA_MAXOFF ; Anything found?
	cmc
	jb	short FindAddrExit ; Jump if not (note CF=1)

; Format the offset to display later

	mov	eax,edx 	; Get the offset
	mov	edi,[ebp].FA_OFF ; ES:EDI ==> output format area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	movzx	ecx,DGROUP:[esi].SYM_NAMLEN ; Get name-length byte
	lea	esi,DGROUP:[esi].SYM_NAMLEN[1] ; Skip to name
	mov	edi,[ebp].FA_SYM ; DGROUP:EDI ==> output save area

	cmp	ecx,[ebp].FA_SYMLEN ; Izit too big?
	jbe	short @F	; Jump if not

	mov	ecx,[ebp].FA_SYMLEN ; Use maximum length
@@:
	mov	edx,ecx 	; Copy length as return value
@@:
	lods	DGROUP:[esi].LO ; Get the next byte
	stos	DGROUP:[edi].LO ; Save in message area

	and	al,al		; Izit EOL?
	loopnz	short @B	; Jump if not
	jz	short @F	; Jump if EOL

	mov	al,0		; Ensure properly terminated
	stos	DGROUP:[edi].LO ; Save in message area
@@:
	mov	eax,edx 	; Copy to return register

	clc			; Mark as found
FindAddrExit:
	REGREST <edi,esi,edx,ecx> ; Restore

	pop	ebp		; Restore

	ret	6*4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FindAddr endp			; End FindAddr procedure
	NPPROC	PF_GETADDR -- Printf Get Argument As Address
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Printf get argument as address

Types		Modifiers
-------------------------
s		l h a F R P
A S G M g m	l h a p n F L R P H N Z

On entry:

SS:EBP	==>	PF_STR
FS:EDI	==>	argument list

On exit:

EAX	=	argument
FS:EDI	==>	(updated)

|

	push	edx		; Save register

	cmp	[ebp].PF_TYPE,'s' ; Izit type s?
	je	short PF_GETADDR_STR ; Jump if so

	int	03h		; Call ourselves

	jmp	short PF_GETADDR_EXIT ; Join common exit code

PF_GETADDR_STR:
	test	[ebp].PF_FLAG,@PF_ADDRS ; Izit AddrS format?
	jz	short @F	; Jump if not

	int	03h		; Call ourselves
@@:
	test	[ebp].PF_FLAG,@PF_VEC ; Izit vector format?
	jz	short PF_GETADDR_STR_OFF ; Jump if not

	test	[ebp].PF_FLAG,@PF_WORD ; Izit 16:16?
	jz	short PF_GETADDR_STR_VEC32 ; Jump if not

	movzx	eax,fs:[edi].VOFF ; Get the offset
	movzx	edx,fs:[edi].VSEG ; ...     segment/selector
	add	edi,2+2 	; Skip over it

	jmp	short PF_GETADDR_STR_VEC_COM ; Join common code

PF_GETADDR_STR_VEC32:
	mov	eax,fs:[edi].FOFF ; Get the offset
	movzx	edx,fs:[edi].FSEL ; ...     segment/selector
	add	edi,4+2 	; Skip over it
PF_GETADDR_STR_VEC_COM:
	test	[ebp].PF_FLAG,@PF_RMSEG ; Izit a RM segment?
	jz	short PF_GETADDR_STR_VEC_PMSEG ; Jump if not

	shl	edx,4-0 	; Convert from paras to bytes

	jmp	short @F	; Join common code

PF_GETADDR_STR_VEC_PMSEG:
	xchg	eax,edx 	; Swap offset and segment
	push	eax		; Pass the selector
	call	SEL2BASE	; Return with EAX == selector base address
@@:
	add	eax,edx 	; Add to get linear address

	jmp	short PF_GETADDR_EXIT ; Join common exit code


PF_GETADDR_STR_OFF:
	mov	eax,fs:[edi]	; Get argument
	add	edi,4		; Assume dword argument size

	test	[ebp].PF_FLAG,@PF_WORD ; Izit word argument size?
	jz	short PF_GETADDR_EXIT ; Jump if not

	sub	edi,2		; It's word argument size
	movzx	eax,ax		; Clear high-order word
PF_GETADDR_EXIT:
	pop	edx		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PF_GETADDR endp 		; End PF_GETADDR procedure
	NPPROC	PF_GETVAL -- Printf Get Argument Value
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Printf get argument value.

Types		Modifiers
-------------------------
c		l h
d u x X o b	l h p n

On entry:

SS:EBP	==>	PF_STR
FS:EDI	==>	argument list

On exit:

EAX	=	argument
FS:EDI	==>	(updated)
SF	=	1 if negative
	=	0 if non-negative

|

	push	edx		; Save register

	mov	eax,fs:[edi]	; Get argument
	add	edi,4		; Assume dword argument size
	mov	edx,eax 	; Copy for sign test

	test	[ebp].PF_FLAG,@PF_WORD ; Izit word argument size?
	jz	short PF_GETVAL_DWORD ; Jump if not

	sub	edi,2		; It's word argument size

	test	[ebp].PF_FLAG,@PF_SDEC ; Izit signed extended?
	jz	short @F	; Jump if not

	movsx	eax,ax		; Sign-extend high-order word
	shl	edx,16		; Shift sign to high-order word

	jmp	short PF_GETVAL_COM ; Join common code

@@:
	movzx	eax,ax		; Clear high-order word
PF_GETVAL_DWORD:
PF_GETVAL_COM:
	cmp	[ebp].PF_TYPE,'c' ; Izit type c?
	je	short PF_GETVAL_EXIT ; Jump if so

	test	[ebp].PF_FLAG,@PF_NEXT or @PF_PREV ; Is prev or next present?
	jz	short PF_GETVAL_EXIT ; Jump if not

; *FIXME*:  Handle modifiers:  p n

	int	03h		; Call ourselves
PF_GETVAL_EXIT:
	test	edx,edx 	; Check the sign

	pop	edx		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PF_GETVAL endp			; End PF_GETVAL procedure
	NPPROC	PF_GETVALZX -- Printf Get Argument Value, Zero-extended
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Printf get argument value, zero-extended.

On entry:

SS:EBP	==>	PF_STR
FS:EDI	==>	argument list

On exit:

EAX	=	argument
FS:EDI	==>	(updated)

|

	mov	eax,fs:[edi]	; Get argument
	add	edi,4		; Assume dword argument size

	test	[ebp].PF_FLAG,@PF_WORD ; Izit word argument size?
	jz	short @F	; Jump if not

	sub	edi,2		; It's word argument size
	movzx	eax,ax		; Clear high-order word
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PF_GETVALZX endp		; End PF_GETVALZX procedure
	NPPROC	PF_INDIRECT -- Printf Indirect Width/Precision
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for printf indirect width/precision

On entry:

SS:EBP	==>	PF_STR

|

	REGSAVE <eax>		; Save register

	btr	[ebp].PF_FLAG,$PF_WARG ; Izit indirect width?
	jnc	short @F	; Jump if not

	call	PF_GETVALZX	; Get next argument value into EAX
	mov	[ebp].PF_WIDTH,eax ; Save for later use
@@:
	btr	[ebp].PF_FLAG,$PF_PARG ; Izit indirect precision?
	jnc	short @F	; Jump if not

	call	PF_GETVALZX	; Get next argument value into EAX
	mov	[ebp].PF_PREC,eax ; Save for later use
@@:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PF_INDIRECT endp		; End PF_INDIRECT procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_I41 module
