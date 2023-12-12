;'$Header:   P:/PVCS/SWATVXD/SWAT_FLT.ASV   1.0   10 Aug 1998 10:46:26   BOB  $
	title	SWAT_IPF -- SWATVXD Fault Handlers
	page	78,130
	name	SWAT_IPF

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1990-98 Qualitas, Inc.  All rights reserved.

Program derived from:  None.

Original code by:  Bob Smith, June 1997.

|

.386p
.xlist
	include VMM.INC 	; Fixed version of file from DDK
	include MASM.INC
	include 386.INC
	include PTR.INC
	include ASCII.INC
	include WKD.INC 	; Windows kernel debugger equates/strucs
	include DEBUGSYS.INC	; ...

	include SWAT_DBG.INC	; DBG_FLAG and DB2_FLAG masks
	include SWAT_FLT.INC
.list

;******************************************************************************

VxD_LOCKED_DATA_SEG		; Begin _LDATA segment

	extrn	DB2_FLAG:dword
	extrn	SWATMSG_FVEC:fword
	extrn	SWATTER_FVEC:fword

	public	LCL_IPF_FLAGS
LCL_IPF_FLAGS dd ?		; IPF flags

	public	SWAT_IPF_STR_FOFF
SWAT_IPF_STR_FOFF dd ?		; Ptr to SWAT_IPF_STR

	public	OLDINT06_FOFF,LCL_INT06_EBP
	public	OLDINT0D_FOFF,LCL_INT0D_EBP
	public	OLDINT0E_FOFF,LCL_INT0E_EBP
OLDINT06_FOFF dd 0		; Offset of old INT 06h handler
OLDINT0D_FOFF dd 0		; ...		    0Dh ...
OLDINT0E_FOFF dd 0		; ...		    0Eh ...
LCL_INT06_EBP dd 0		; Incoming EBP (address of client register frame)
LCL_INT0D_EBP dd 0		; ...
LCL_INT0E_EBP dd 0		; ...

	public	IDTR
IDTR	df	?

	public	OLDINT0D_FVEC
OLDINT0D_FVEC df ?		; Old INT 0Dh handler
OLDINT0D_ARB  db ?,?		; ...	      A/R byte

	public	OLDINT0E_FVEC
OLDINT0E_FVEC df ?		; Old INT 0Eh handler
OLDINT0E_ARB  db ?,?		; ...	      A/R byte

MSG_I0D_HDR db	'GP at '
MSG_I0D_CS  db	'____:'
MSG_I0D_EIP db	'________ '
MSG_I0D_EFL db	'________',CR,LF,0

MSG_I0E_HDR db	'Page Fault at '
MSG_I0E_CS  db	'____:'
MSG_I0E_EIP db	'________ '
MSG_I0E_EFL db	'________ '
MSG_I0E_CR2 db	'________ '
MSG_I0E_CR3 db	'________ ',CR,LF
	    db	'EAX      '
	    db	'EBX      '
	    db	'ECX      '
	    db	'EDX      '
	    db	'ESI      '
	    db	'EDI      '
	    db	'EBP      ',CR,LF
MSG_I0E_EAX db	'________ '
MSG_I0E_EBX db	'________ '
MSG_I0E_ECX db	'________ '
MSG_I0E_EDX db	'________ '
MSG_I0E_ESI db	'________ '
MSG_I0E_EDI db	'________ '
MSG_I0E_EBP db	'________ ',CR,LF
	    db	' DS  '
	    db	' ES  '
	    db	' FS  '
	    db	' GS  '
	    db	' SS  ',CR,LF
MSG_I0E_DS  db	'____ '
MSG_I0E_ES  db	'____ '
MSG_I0E_FS  db	'____ '
MSG_I0E_GS  db	'____ '
MSG_I0E_SS  db	'____ '
	    db	CR,LF,0

MSG_I0E_STK db	'________ '
	    db	'________ '
	    db	'________ '
	    db	'________ '
	    db	'________ '
	    db	'________ '
	    db	'________ '
	    db	'________ '
	    db	CR,LF,0

MSG_INVOP_FAULT 	db	'Invalid Opcode',0
MSG_GP_FAULT		db	'GP fault', 0
MSG_PAGE_FAULT		db	'Page fault', 0

	public	MSG_IPF_HDR
MSG_IPF_HDR	   db	'ออ> Invalid Page Fault at '
MSG_IPF_LinAddr    db	'xxxxxxxx'
		   db	', PTE '
MSG_IPF_PTEEntry   db	'xxxxxxxx'
		   db	CR,LF
		   db	'    Page # '
MSG_IPF_MapPageNum db	'xxxxxxxx'
		   db	', VM '
MSG_IPF_VM	   db	'xxxxxxxx'
		   db	', Faulting VM '
MSG_IPF_FaultingVM db	'xxxxxxxx',CR,LF,0


IPF_FlagStr struc

IPF_FlagTxt dd	?		; Offset of text to display
IPF_FlagVal dd	?		; ...if this value is set

IPF_FlagStr ends

	public	IPF_FlagTab
IPF_FlagTab label byte
	IPF_FlagStr <OFFSET32 IPF_TxtPgDir,  IPF_PgDir>
	IPF_FlagStr <OFFSET32 IPF_TxtV86Pg,  IPF_V86Pg>
	IPF_FlagStr <OFFSET32 IPF_TxtV86PgH, IPF_V86PgH>
	IPF_FlagStr <OFFSET32 IPF_TxtInvTyp, IPF_InvTyp>
	IPF_FlagStr <OFFSET32 IPF_TxtPgErr,  IPF_PgErr>
	IPF_FlagStr <OFFSET32 IPF_TxtReFlt,  IPF_ReFlt>
	IPF_FlagStr <OFFSET32 IPF_TxtVMM,    IPF_VMM>
	IPF_FlagStr <OFFSET32 IPF_TxtPM,     IPF_PM>
	IPF_FlagStr <OFFSET32 IPF_TxtV86,    IPF_V86>
@IPF_FlagCnt equ ($-IPF_FlagTab)/(type IPF_FlagStr) ; # entries

IPF_TxtPgDir  db '    Page directory entry not-present (not pres page table)',CR,LF,0
IPF_TxtV86Pg  db '    Unexpected not present Page in V86',CR,LF,0
IPF_TxtV86PgH db '    Unexpected not present Page in V86 at high linear',CR,LF,0
IPF_TxtInvTyp db '    Page has invalid not present type',CR,LF,0
IPF_TxtPgErr  db '    Pageswap device couldn''t page for some reason',CR,LF,0
IPF_TxtReFlt  db '    Re-entrant page fault',CR,LF,0
IPF_TxtVMM    db '    Page fault caused by a VxD',CR,LF,0
IPF_TxtPM     db '    Page fault caused by VM running in Prot Mode',CR,LF,0
IPF_TxtV86    db '    Page fault caused by VM running in V86 Mode',CR,LF,0

VxD_LOCKED_DATA_ENDS			; End _LDATA segment


VxD_CODE_SEG				; Begin _LCODE segment

	extrn	DISPLAY:near
	extrn	TOHEX:near

VxD_CODE_ENDS				; End _LCODE segment


VxD_LOCKED_CODE_SEG			; Begin _LCODE segment


LOADSR	macro	SREG,MEMLOC
	local	L1,L2

	test	MEMLOC,not (mask $PL) ; Izit zero (except for PL bits)?
	jz	short L1	; Jump if so

	verr	MEMLOC		; Izit valid?
	jnz	short L2	; Jump if not
L1:
	mov	SREG,MEMLOC	; Load it
	assume	SREG:nothing	; Tell the assembler about it
L2:
	endm			; LOADSR



;; BeginProc LCL_INT06		   ; Local Invalid Opcode Fault Handler
;;
;; COMMENT|
;;
;; Invalid Opcode Fault handler
;;
;; On entry:
;;
;; EBX	   =	   Current VM handle
;; EBP	   ==>	   Client register frame
;;
;; |
;;
;; ; If this comes from VM, and it's an ARPL, let Windows handle it
;;
;;	   test    [ebp].Client_EFlags.EHI,mask $VM ; Izit VM86 mode?
;;	   jz	   short LCL_INT06_PM ; Jump if not
;;
;;	   push    eax		   ; Save for a moment
;;
;;	   movzx   eax,[ebp].Client_CS ; Get caller's CS
;;	   shl	   eax,4-0	   ; Convert from paras to bytes
;;	   add	   eax,[ebp].Client_EIP ; DS:EAX ==> caller's next instruction
;;
;;	   cmp	   ds:[eax].ELO.LO,@OPCOD_ARPL ; Izit an ARPL?
;;	   pop	   eax		   ; Restore
;;	   jne	   short LCL_INT06_ERR ; Jump if not
;;
;;	   jmp	   LCL_INT06_ORIG  ; Continue with original handler
;;
;; LCL_INT06_PM:
;;
;; ; If this comes from PM, and it's a 0F FF, let Windows handle it
;;
;;	   REGSAVE <eax,ds>	   ; Save for a moment
;;
;;	   lds	   eax,[ebp].Client_EIP.EDF ; DS:EAX ==> faulting instruction
;;	   assume  ds:nothing	   ; Tell the assembler about it
;;
;;	   cmp	   ds:[eax].ELO,@OPCOD_WIN06 ; Izit WIN06?
;;	   REGREST <ds,eax>	   ; Restore
;;	   assume  ds:FLAT	   ; Tell the assembler about it
;;	   je	   near ptr LCL_INT06_ORIG ; Jump if it is
;; LCL_INT06_ERR:
;;	   PUSHD   0		   ; Pass pseudo-error code
;;	   push    ds		   ; Selector of message text
;;	   push    OFFSET32 MSG_INVOP_FAULT ; Offset of ...
;;	   call    SWATMSG_FVEC    ; Call SWATMSG
;;
;;	   pushad		   ; Save all registers
;;	   push    LCL_INT06_EBP   ; Save to be re-entrant
;;
;;	   mov	   LCL_INT06_EBP,ebp ; Save to restore later
;;
;; ; Setup the stack for SWATTER
;;
;;	   test    [ebp].Client_EFlags.EHI,mask $VM ; Izit from V86 mode?
;;	   jz	   short LCL_INT06_PM1 ; Jump if not
;;
;;	   push    [ebp].Client_GS.EDD ; Push VM segment registers
;;	   push    [ebp].Client_FS.EDD ; ...
;;	   push    [ebp].Client_DS.EDD ; ...
;;	   push    [ebp].Client_ES.EDD ; ...
;;	   push    [ebp].Client_SS.EDD ; Push VM stack pointer
;;	   push    [ebp].Client_ESP    ; ...
;;
;;	   jmp	   short LCL_INT06_COM1 ; Join common code
;;
;; LCL_INT06_PM1:
;;	   REGSAVE <ds,es,fs,gs>   ; Save all segment registers
;;
;;	   test    [ebp].Client_CS,mask $PL ; Izit > PL0?
;;	   jz	   short @F	   ; Jump if not (no ring transition)
;;
;;	   push    [ebp].Client_SS.EDD ; Push ring transition registers
;;	   push    [ebp].Client_ESP    ; ...
;; @@:
;;
;; ; Put PM segment registers into effect
;;
;;	   LOADSR  ds,[ebp].Client_DS  ; Put into effect
;;	   LOADSR  es,[ebp].Client_ES  ; ...
;;	   LOADSR  fs,[ebp].Client_FS  ; ...
;;	   LOADSR  gs,[ebp].Client_GS  ; ...
;; LCL_INT06_COM1:
;;	   push    [ebp].Client_EFlags ; Pass faulting flags/address
;;	   push    [ebp].Client_CS.EDD ; ...
;;	   push    [ebp].Client_EIP    ; ...
;;
;; ; Put EGP registers into effect
;;
;;	   mov	   eax,[ebp].Client_EAX ; Load value from client register frame
;;	   mov	   ebx,[ebp].Client_EBX ; ...
;;	   mov	   ecx,[ebp].Client_ECX ; ...
;;	   mov	   edx,[ebp].Client_EDX ; ...
;;	   mov	   esi,[ebp].Client_ESI ; ...
;;	   mov	   edi,[ebp].Client_EDI ; ...
;;	   mov	   ebp,[ebp].Client_EBP ; ... (do this one last)
;;
;;	   call    SWATTER_FVEC    ; Call SWATTER
;;
;; ; Save EGP registers
;;
;;	   push    ebp		   ; Save return value
;;	   mov	   ebp,LCL_INT06_EBP ; Get address of client register frame
;;
;;	   mov	   [ebp].Client_EAX,eax ; Restore
;;	   mov	   [ebp].Client_EBX,ebx ; ...
;;	   mov	   [ebp].Client_ECX,ecx ; ...
;;	   mov	   [ebp].Client_EDX,edx ; ...
;;	   mov	   [ebp].Client_ESI,esi ; ...
;;	   mov	   [ebp].Client_EDI,edi ; ...
;;	   pop	   [ebp].Client_EBP	; Do this one last
;;
;;	   pop	   [ebp].Client_EIP    ; Save back in client register frame
;;	   pop	   [ebp].Client_CS.EDD ; ...
;;	   pop	   [ebp].Client_EFlags ; ...
;;
;; ; Save segment registers
;;
;;	   test    [ebp].Client_EFlags.EHI,mask $VM ; Izit from V86 mode?
;;	   jz	   short LCL_INT06_PM2 ; Jump if not
;;
;;	   pop	   [ebp].Client_ESP    ; Save back into client register frame
;;	   pop	   [ebp].Client_SS.EDD ; ...
;;	   pop	   [ebp].Client_ES.EDD ; ...
;;	   pop	   [ebp].Client_DS.EDD ; ...
;;	   pop	   [ebp].Client_FS.EDD ; ...
;;	   pop	   [ebp].Client_GS.EDD ; ...
;;
;;	   jmp	   short LCL_INT06_COM2 ; Join common code
;;
;; LCL_INT06_PM2:
;;	   mov	   [ebp].Client_DS,ds ; Restore
;;	   mov	   [ebp].Client_ES,es ; ...
;;	   mov	   [ebp].Client_FS,fs ; ...
;;	   mov	   [ebp].Client_GS,gs ; ...
;;
;;	   test    [ebp].Client_CS,mask $PL ; Izit > PL0?
;;	   jz	   short @F	      ; Jump if not
;;
;;	   pop	   [ebp].Client_ESP    ; Save back into client register frame
;;	   pop	   [ebp].Client_SS.EDD ; ...
;; @@:
;;	   REGREST <gs,fs,es,ds>   ; Restore all segment registers
;;	   assume  ds:FLAT,es:FLAT,ss:FLAT ; Restore assumption
;;	   assume  fs:nothing,gs:nothing ; ...
;; LCL_INT06_COM2:
;;	   pop	   LCL_INT06_EBP   ; Restore
;;	   popad		   ; Restore all registers
;;
;;	   int	   01h		   ; Call ourselves
;;
;;	   ret			   ; Return to caller
;;
;; LCL_INT06_ORIG:
;;	   assume  ds:nothing,es:nothing,ss:nothing ; Force CS override
;;	   jmp	   OLDINT06_FOFF   ; Continue with next handler
;;	   assume  ds:FLAT,es:FLAT,ss:FLAT ; Restore assumption
;;
;; EndProc LCL_INT06		   ; End LCL_INT06 procedure
;;
;; BeginProc LCL_INT0D		   ; Local GP Fault Handler
;;
;; COMMENT|
;;
;; GP Fault handler
;;
;; On entry:
;;
;; EBX	   =	   Current VM handle
;; EBP	   ==>	   Client register frame
;;
;; |
;;
;;	   push    [ebp].Client_Error ; Pass error code
;;	   push    ds		   ; Selector of message text
;;	   push    OFFSET32 MSG_GP_FAULT ; Offset of ...
;;	   call    SWATMSG_FVEC    ; Call SWATMSG
;;
;;	   pushad		   ; Save all registers
;;	   push    LCL_INT0D_EBP   ; Save to be re-entrant
;;
;;	   mov	   LCL_INT0D_EBP,ebp ; Save to restore later
;;
;; COMMENT|
;;
;; Make a local copy of the client register frame.  After giving SWATTER
;; a crack at it, if it changes, we'll continue execution (RETD);
;; otherwise, we'll let W take a crack at it.
;;
;; |
;;
;;	   sub	   esp,type Client_Reg_Struc ; Make room
;;
;;	   mov	   edi,esp	   ; ES:EDI ==> local copy
;;	   mov	   esi,ebp	   ; DS:ESI ==> original copy
;;	   mov	   ecx,(type Client_Reg_Struc)/4 ; # dwords in struc
;;     rep movs    es:[edi].EDD,ds:[esi].EDD ; Make local copy of the original
;;
;; ; Setup the stack for SWATTER
;;
;;	   test    [ebp].Client_EFlags.EHI,mask $VM ; Izit from V86 mode?
;;	   jz	   short LCL_INT0D_PM1 ; Jump if not
;;
;;	   push    [ebp].Client_GS.EDD ; Push VM segment registers
;;	   push    [ebp].Client_FS.EDD ; ...
;;	   push    [ebp].Client_DS.EDD ; ...
;;	   push    [ebp].Client_ES.EDD ; ...
;;	   push    [ebp].Client_SS.EDD ; Push VM stack pointer
;;	   push    [ebp].Client_ESP    ; ...
;;
;;	   jmp	   short LCL_INT0D_COM1 ; Join common code
;;
;; LCL_INT0D_PM1:
;;	   REGSAVE <ds,es,fs,gs>   ; Save all segment registers
;;
;;	   test    [ebp].Client_CS,mask $PL ; Izit > PL0?
;;	   jz	   short @F	   ; Jump if not (no ring transition)
;;
;;	   push    [ebp].Client_SS.EDD ; Push ring transition registers
;;	   push    [ebp].Client_ESP    ; ...
;; @@:
;;
;; ; Put PM segment registers into effect
;;
;;	   LOADSR  ds,[ebp].Client_DS  ; Put into effect
;;	   LOADSR  es,[ebp].Client_ES  ; ...
;;	   LOADSR  fs,[ebp].Client_FS  ; ...
;;	   LOADSR  gs,[ebp].Client_GS  ; ...
;; LCL_INT0D_COM1:
;;	   push    [ebp].Client_EFlags ; Pass faulting flags/address
;;	   push    [ebp].Client_CS.EDD ; ...
;;	   push    [ebp].Client_EIP    ; ...
;;
;; ; Put EGP registers into effect
;;
;;	   mov	   eax,[ebp].Client_EAX ; Load value from client register frame
;;	   mov	   ebx,[ebp].Client_EBX ; ...
;;	   mov	   ecx,[ebp].Client_ECX ; ...
;;	   mov	   edx,[ebp].Client_EDX ; ...
;;	   mov	   esi,[ebp].Client_ESI ; ...
;;	   mov	   edi,[ebp].Client_EDI ; ...
;;	   mov	   ebp,[ebp].Client_EBP ; ... (do this one last)
;;
;;	   call    SWATTER_FVEC    ; Call SWATTER
;;
;; ; Save EGP registers
;;
;;	   push    ebp		   ; Save return value
;;	   mov	   ebp,LCL_INT0D_EBP ; Get address of client register frame
;;
;;	   mov	   [ebp].Client_EAX,eax ; Restore
;;	   mov	   [ebp].Client_EBX,ebx ; ...
;;	   mov	   [ebp].Client_ECX,ecx ; ...
;;	   mov	   [ebp].Client_EDX,edx ; ...
;;	   mov	   [ebp].Client_ESI,esi ; ...
;;	   mov	   [ebp].Client_EDI,edi ; ...
;;	   pop	   [ebp].Client_EBP	; Do this one last
;;
;;	   pop	   [ebp].Client_EIP    ; Save back in client register frame
;;	   pop	   [ebp].Client_CS.EDD ; ...
;;	   pop	   [ebp].Client_EFlags ; ...
;;
;; ; Save segment registers
;;
;;	   test    [ebp].Client_EFlags.EHI,mask $VM ; Izit from V86 mode?
;;	   jz	   short LCL_INT0D_PM2 ; Jump if not
;;
;;	   pop	   [ebp].Client_ESP    ; Save back into client register frame
;;	   pop	   [ebp].Client_SS.EDD ; ...
;;	   pop	   [ebp].Client_ES.EDD ; ...
;;	   pop	   [ebp].Client_DS.EDD ; ...
;;	   pop	   [ebp].Client_FS.EDD ; ...
;;	   pop	   [ebp].Client_GS.EDD ; ...
;;
;;	   jmp	   short LCL_INT0D_COM2 ; Join common code
;;
;; LCL_INT0D_PM2:
;;	   mov	   [ebp].Client_DS,ds ; Restore
;;	   mov	   [ebp].Client_ES,es ; ...
;;	   mov	   [ebp].Client_FS,fs ; ...
;;	   mov	   [ebp].Client_GS,gs ; ...
;;
;;	   test    [ebp].Client_CS,mask $PL ; Izit > PL0?
;;	   jz	   short @F	      ; Jump if not
;;
;;	   pop	   [ebp].Client_ESP    ; Save back into client register frame
;;	   pop	   [ebp].Client_SS.EDD ; ...
;; @@:
;;	   REGREST <gs,fs,es,ds>   ; Restore all segment registers
;;	   assume  ds:FLAT,es:FLAT,ss:FLAT ; Restore assumption
;;	   assume  fs:nothing,gs:nothing ; ...
;; LCL_INT0D_COM2:
;;
;; COMMENT|
;;
;; If SWATTER made a change in the client register struc, re-execute the
;; faulting instruction.  If not, let W handle it.
;;
;; |
;;
;; ; SWATTER uses the field above CS to store the LDT, so it might
;; ; have changed.  Copy the original value back so we don't trip
;; ; over that.
;;
;;	   mov	   ax,[ebp].Client_CS[2] ; Get the original value
;;	   mov	   [esp].Client_CS[2],ax ; Save back into local copy
;;
;;	   mov	   edi,esp	   ; ES:EDI ==> local copy
;;	   mov	   esi,ebp	   ; DS:ESI ==> original copy
;;	   mov	   ecx,(type Client_Reg_Struc)/4 ; # dwords in struc
;;    repe cmps    ds:[esi].EDD,es:[edi].EDD ; Izit the same?
;;
;;	   lea	   esp,[esp+(type Client_Reg_Struc)] ; Strip from the stack
;;
;;	   pop	   LCL_INT0D_EBP   ; Restore
;;	   popad		   ; Restore all registers
;;	   je	   short LCL_INT0D_ORIG ; Jump if no change (let W handle it)
;;
;;	   ret			   ; Return to caller
;;
;; LCL_INT0D_ORIG:
;;	   assume  ds:nothing,es:nothing,ss:nothing ; Force CS override
;;	   jmp	   OLDINT0D_FOFF   ; Continue with next handler
;;	   assume  ds:FLAT,es:FLAT,ss:FLAT ; Restore assumption
;;
;; EndProc LCL_INT0D		   ; End LCL_INT0D procedure

BeginProc LCL_INT0E		; Local Page Fault Handler

COMMENT|

Page Fault handler

On entry:

EBX	=	Current VM handle
EBP	==>	Client register frame

|

; If this is a write into a read-only page, trap it
; otherwise, give the next handler a crack at it

	test	[ebp].Client_Error,mask $PF_P  ; Wuzit caused by Present page?
	jz	near ptr LCL_INT0E_ORIG ; Jump if not

	test	[ebp].Client_Error,mask $PF_RW ; Wuzit caused by a Write?
	jz	near ptr LCL_INT0E_ORIG ; Jump if not

	test	[ebp].Client_Error,mask $PF_RSV ; Wuzit caused by Reserved bit?
	jnz	near ptr LCL_INT0E_ORIG ; Jump if so

	int	01h		; Call our debugger

; Get the PTE to see if it's a read-only page

	test	DB2_FLAG,@DB2_WSVC ; Are Win386 services present?
	jz	short LCL_INT0E_SWAT ; Jump if not, let SWAT sort it out

	REGSAVE <eax,ebx,ecx,edx,esi> ; Save for a moment

	mov	eax,Win386_GetThreadID; Function code to get current thread ID
	int	Win386_Query_Int ; Request Win386 service
				; Return with AX = current thread ID
	mov	bx,ax		; Copy to thread ID register

	mov	eax,Win386_GetPDE ; Function code to get PDE
	mov	edx,cr2 	; Get the page fault linear address
	int	Win386_Query_Int ; Request Win386 service
				; Return with EAX != 0 if valid
				;	      ECX = PDE
	and	eax,eax 	; Izit valid?
	jz	short @F	; Jump if not (note ZF=1)

	mov	eax,Win386_GetFrame ; Function code to get PTE
;;;;;;; mov	edx,cr2 	; Get the page fault linear address
	xor	esi,esi 	; Tell 'em ECX has PDE
	int	Win386_Query_Int ; Request Win386 service
				; Return with EAX != 0 if valid
				;	      EDX = PTE
	and	eax,eax 	; Izit valid?
	jz	short @F	; Jump if not (note ZF=1)

	test	edx,mask $PTE_RW ; Izit read-write?
				; Fall through with ZF=0 if read-write
@@:
	REGREST <esi,edx,ecx,ebx,eax> ; Restore
	jnz	near ptr LCL_INT0E_ORIG ; Jump if it's read-write
LCL_INT0E_SWAT:
	push	[ebp].Client_Error ; Pass error code
	push	ds		; Selector of message text
	push	OFFSET32 MSG_PAGE_FAULT ; Offset of ...
	call	SWATMSG_FVEC	; Call SWATMSG

	pushad			; Save all registers
	push	LCL_INT0E_EBP	; Save to be re-entrant

	mov	LCL_INT0E_EBP,ebp ; Save to restore later

COMMENT|

Make a local copy of the client register frame.  After giving SWATTER
a crack at it, if it changes, we'll continue execution (RETD);
otherwise, we'll let W take a crack at it.

|

	sub	esp,type Client_Reg_Struc ; Make room

	mov	edi,esp 	; ES:EDI ==> local copy
	mov	esi,ebp 	; DS:ESI ==> original copy
	mov	ecx,(type Client_Reg_Struc)/4 ; # dwords in struc
    rep movs	es:[edi].EDD,ds:[esi].EDD ; Make local copy of the original

; Setup the stack for SWATTER

	test	[ebp].Client_EFlags.EHI,mask $VM ; Izit from V86 mode?
	jz	short LCL_INT0E_PM1 ; Jump if not

	push	[ebp].Client_GS.EDD ; Push VM segment registers
	push	[ebp].Client_FS.EDD ; ...
	push	[ebp].Client_DS.EDD ; ...
	push	[ebp].Client_ES.EDD ; ...
	push	[ebp].Client_SS.EDD ; Push VM stack pointer
	push	[ebp].Client_ESP    ; ...

	jmp	short LCL_INT0E_COM1 ; Join common code

LCL_INT0E_PM1:
	REGSAVE <ds,es,fs,gs>	; Save all segment registers

	test	[ebp].Client_CS,mask $PL ; Izit > PL0?
	jz	short @F	; Jump if not (no ring transition)

	push	[ebp].Client_SS.EDD ; Push ring transition registers
	push	[ebp].Client_ESP    ; ...
@@:

; Put PM segment registers into effect

	LOADSR	ds,[ebp].Client_DS  ; Put into effect
	LOADSR	es,[ebp].Client_ES  ; ...
	LOADSR	fs,[ebp].Client_FS  ; ...
	LOADSR	gs,[ebp].Client_GS  ; ...
LCL_INT0E_COM1:
	push	[ebp].Client_EFlags ; Pass faulting flags/address
	push	[ebp].Client_CS.EDD ; ...
	push	[ebp].Client_EIP    ; ...

; Put EGP registers into effect

	mov	eax,[ebp].Client_EAX ; Load value from client register frame
	mov	ebx,[ebp].Client_EBX ; ...
	mov	ecx,[ebp].Client_ECX ; ...
	mov	edx,[ebp].Client_EDX ; ...
	mov	esi,[ebp].Client_ESI ; ...
	mov	edi,[ebp].Client_EDI ; ...
	mov	ebp,[ebp].Client_EBP ; ... (do this one last)

	call	SWATTER_FVEC	; Call SWATTER

; Save EGP registers

	push	ebp		; Save return value
	mov	ebp,LCL_INT0E_EBP ; Get address of client register frame

	mov	[ebp].Client_EAX,eax ; Restore
	mov	[ebp].Client_EBX,ebx ; ...
	mov	[ebp].Client_ECX,ecx ; ...
	mov	[ebp].Client_EDX,edx ; ...
	mov	[ebp].Client_ESI,esi ; ...
	mov	[ebp].Client_EDI,edi ; ...
	pop	[ebp].Client_EBP     ; Do this one last

	pop	[ebp].Client_EIP    ; Save back in client register frame
	pop	[ebp].Client_CS.EDD ; ...
	pop	[ebp].Client_EFlags ; ...

; Save segment registers

	test	[ebp].Client_EFlags.EHI,mask $VM ; Izit from V86 mode?
	jz	short LCL_INT0E_PM2 ; Jump if not

	pop	[ebp].Client_ESP    ; Save back into client register frame
	pop	[ebp].Client_SS.EDD ; ...
	pop	[ebp].Client_ES.EDD ; ...
	pop	[ebp].Client_DS.EDD ; ...
	pop	[ebp].Client_FS.EDD ; ...
	pop	[ebp].Client_GS.EDD ; ...

	jmp	short LCL_INT0E_COM2 ; Join common code

LCL_INT0E_PM2:
	mov	[ebp].Client_DS,ds ; Restore
	mov	[ebp].Client_ES,es ; ...
	mov	[ebp].Client_FS,fs ; ...
	mov	[ebp].Client_GS,gs ; ...

	test	[ebp].Client_CS,mask $PL ; Izit > PL0?
	jz	short @F	   ; Jump if not

	pop	[ebp].Client_ESP    ; Save back into client register frame
	pop	[ebp].Client_SS.EDD ; ...
@@:
	REGREST <gs,fs,es,ds>	; Restore all segment registers
	assume	ds:FLAT,es:FLAT,ss:FLAT ; Restore assumption
	assume	fs:nothing,gs:nothing ; ...
LCL_INT0E_COM2:

COMMENT|

If SWATTER made a change in the client register struc, re-execute the
faulting instruction.  If not, let W handle it.

|

; SWATTER uses the field above CS to store the LDT, so it might
; have changed.  Copy the original value back so we don't trip
; over that.

	mov	ax,[ebp].Client_CS[2] ; Get the original value
	mov	[esp].Client_CS[2],ax ; Save back into local copy

	mov	edi,esp 	; ES:EDI ==> local copy
	mov	esi,ebp 	; DS:ESI ==> original copy
	mov	ecx,(type Client_Reg_Struc)/4 ; # dwords in struc
   repe cmps	ds:[esi].EDD,es:[edi].EDD ; Izit the same?

	lea	esp,[esp+(type Client_Reg_Struc)] ; Strip from the stack

	pop	LCL_INT0E_EBP	; Restore
	popad			; Restore all registers
	je	short LCL_INT0E_ORIG ; Jump if no change (let W handle it)

	ret			; Return to caller

LCL_INT0E_ORIG:
	assume	ds:nothing,es:nothing,ss:nothing ; Force CS override
	jmp	OLDINT0E_FOFF	; Continue with next handler
	assume	ds:FLAT,es:FLAT,ss:FLAT ; Restore assumption

EndProc LCL_INT0E		; End LCL_INT0E procedure

BeginProc OutString		; Display an ASCIIZ string
COMMENT|

Display the ASCIIZ string at ESI to the debugging
screen one way or another.

On entry:

ESI	==>	ASCIIZ string to display

|

	pushad			; Save all registers

	VMMcall Test_Debug_Installed ; Zero flag = debugger not installed
	jz	short @F	; Skip if no debugger

	VMMcall Out_Debug_String ; Send it to the debugging monitor

	jmp	short OutStringExit ; Join common exit code

@@:
	call	DISPLAY 	; Put text up on debugging screen
OutStringExit:
	popad			; Restore

	ret			; Return to caller

EndProc OutString		; End OutString procedure

BeginProc SetRWBit		; Set Read-Write Bit In PTE
COMMENT|

Set the RW Bit in a PTE.
If the corresponding PDE or PTE is not present, we fail.
If the RW bit is already set, we fail.

On exit:

CF	=	0 if successful
	=	1 if not (page not present)

|

SRWB_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
SRWB_LIN dd	?		; Linear address of Page Fault

SRWB_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	pushad			; Save all registers

; Get linear address of PTEs

	mov	eax,cr3 	; Get physical base of page directory
	and	eax,@PTE_FRM	; Isolate the 4KB frame

	VMMcall _MapPhysToLinear <eax, 4096, 0> ; Get linear address

@PDELOC equ	(2*1024)-(3*4)	; Location for new PDE
@PDELIN equ	@PDELOC shl (22-2) ; Linear address of @PDELOC

	mov	ebx,eax 	; Copy for later use
	lea	edi,[ebx+@PDELOC] ; Add in offset to temp PDE

	push	[edi].EDD	; Save the old PDE

	mov	eax,cr3 	; Get physical base of page directory
	and	eax,@PTE_FRM	; Isolate the 4KB frame
	or	eax,@PTE_URP	; Mark as User/Read-Write/Present
	mov	[edi],eax	; Set CR3 as new PDE
	mov	edx,@PDELIN	; Get linear address of CR3

; Ensure that the PDE is present

	mov	eax,[ebp].SRWB_LIN ; Get the linear address
	shr	eax,$LA_DIR-0	; Convert from bytes to 4MB

	test	[ebx+eax*4].EDD,mask $PTE_P ; Is the PDE present?
	stc			; Assume not (CF=1 if not successful)
	jz	short @F	; Jump if not

; Ensure that the PTE is present

	mov	eax,[ebp].SRWB_LIN ; Get the linear address
	shr	eax,$LA_PAGE-0	; Convert from bytes to 4KB

	test	[edx+eax*4].EDD,mask $PTE_P ; Is the PTE present?
	stc			; Assume not (CF=1 if not successful)
	jz	short @F	; Jump if not (note CF=0)

; Set the RW bit:  fail if already set

	bts	[edx+eax*4].EDD,$PTE_RW ; Set the RW bit
				; CF=0 if not already set (successful)
				;   =1 if already set (not successful
@@:
	pop	[edi].EDD	; Restore the old PDE

	popad			; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

EndProc SetRWBit		; End SetRWBit procedure

BeginProc LCL_IPF		; Local Invalid Page Fault handler
COMMENT|

Invalid Page Fault handler

On entry:

EBX	=	Current VM handle
EDI	==>	IPF_Data structure

On exit:

CF	=	0 if fault handled
	=	1 if not (system calls next handler in chain)

|

	pushad			; Save all registers

; Check the flags in SWAT's IPF table to see what we should do with this one

	mov	LCL_IPF_FLAGS,0 ; Initialize flags

	cmp	SWAT_IPF_STR_FOFF,0 ; Izit invalid?
	je	short LCL_IPF1	; Jump if so

	mov	edx,SWAT_IPF_STR_FOFF ; EDX ==> IPF struc

	mov	ecx,[edx]	; Get # entries
	add	edx,4		; Skip over it
	jecxz	LCL_IPF1	; Jump if no entries
	mov	eax,[edi].IPF_LinAddr ; Get the linear address (CR2)
LCL_IPF_NEXT:
	cmp	eax,[edx].SWAT_IPF_LinAddr ; Izit the same?
	je	short @F	; Jump if so

	add	edx,type SWAT_IPF_STR ; Skip to next entry

	loop	LCL_IPF_NEXT	; Jump if more entries to check

	jmp	short LCL_IPF1	; Mark as not found

@@:
	mov	eax,[edx].SWAT_IPF_Flags ; Get flags
	mov	LCL_IPF_FLAGS,eax ; Save for later use
LCL_IPF1:
	test	LCL_IPF_FLAGS,mask $SWAT_IPF_XDISP ; Should we not display?
	jnz	near ptr LCL_IPF_XDISP ; Jump if so

	mov	eax,ebx 	; Copy the current VM handle
	mov	ebx,edi 	; Save offset of IPF_Data struc

; Format the various pieces of data

	lea	edi,MSG_IPF_VM	; Offset to display text
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	eax,[ebx].IPF_LinAddr ; Get the linear address (CR2)
	lea	edi,MSG_IPF_LinAddr ; Offset to display text
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	eax,[ebx].IPF_MapPageNum ; Get possible converted page # of fault
	lea	edi,MSG_IPF_MapPageNum ; Offset to display text
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	eax,[ebx].IPF_PTEEntry ; Get contents of PTE that faulted
	lea	edi,MSG_IPF_PTEEntry ; Offset to display text
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	eax,[ebx].IPF_FaultingVM ; Get handle of faulting VM
	lea	edi,MSG_IPF_FaultingVM ; Offset to display text
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text

; Display info about the fault to the monochrome screen

	mov	esi,OFFSET32 MSG_IPF_HDR ; Display the header info
	call	OutString	; Display the ASCIIZ string

; Display the flags

	mov	eax,[ebx].IPF_Flags ; Get flags
	mov	ecx,@IPF_FlagCnt ; Get # flags
	lea	edi,IPF_FlagTab ; Get offset of IPF flags table
LCL_IPF_FLAGNEXT:
	test	eax,[edi].IPF_FlagVal ; Izit set?
	jz	short @F	; Jump if not

	mov	esi,[edi].IPF_FlagTxt ; Get offset of text
	call	OutString	; Display the ASCIIZ string
@@:
	add	edi,type IPF_FlagStr ; Skip to next entry

	loop	LCL_IPF_FLAGNEXT ; Jump if more flags to check
LCL_IPF_XDISP:
	popad			; Restore

	test	LCL_IPF_FLAGS,mask $SWAT_IPF_XSTOP ; Should we not stop?
	stc			; Assume so (CF=1 ==> not handled)
	jnz	short @F	; Jump if so (note CF=1)

	int	01h		; Call our debugger

	push	[edi].IPF_LinAddr ; Pass the linear address (CR2)
	call	SetRWBit	; Mark as read-write
				; Return with CF=0 if successful
				;		=1 if not
@@:
	ret			; Return to caller

	clc			; This line is skipped to from within SWAT
				; when debugging IPFs
	ret			; Return to caller

EndProc LCL_IPF 		; End LCL_IPF procedure

BeginProc INT0D

INT0D_STR struc

	db	(type PUSHAD_STR) dup (?); Caller's EGP registers
INT0D_RET dq	?		; ...	   return address
INT0D_ERR dd	?		; ...	   error code
INT0D_EIP dd	?		; ...	   EIP
INT0D_CS  dw	?,?		; ...	   CS w/filler
INT0D_EFL dd	?		; ...	   EFL

INT0D_STR ends

	sub	esp,2*4 	; Make room for next handler

	pushad			; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ds,es> 	; Save registers

	mov	ax,cs		; Get code selector
	add	ax,8		; Skip to data selector
	mov	ds,ax		; Address it
	mov	es,ax		; Address it

	mov	eax,[ebp].INT0D_EIP ; Get the offset
	lea	edi,MSG_I0D_EIP ; Offset to display text
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	ax,[ebp].INT0D_CS ; Get the selector
	lea	edi,MSG_I0D_CS	; Offset to display text
	mov	ecx,4		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	eax,[ebp].INT0D_EFL ; Get the flags
	lea	edi,MSG_I0D_EFL ; Offset to display text
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	esi,OFFSET32 MSG_I0D_HDR ; Display the header info
	call	OutString	; Display the ASCIIZ string

	mov	eax,OLDINT0D_FVEC.FOFF ; Get offset of next handler
	mov	[ebp].INT0D_RET.FOFF,eax ; Save to return to

	mov	ax,OLDINT0D_FVEC.FSEL ; Get selector of next handler
	mov	[ebp].INT0D_RET.FSEL,ax ; Save to return to

	REGREST <es,ds> 	; Restore

	popad			; Restore

	cli
	hlt

	retf			; Continue with next handler

EndProc INT0D

BeginProc INT0E

INT0E_STR struc

INT0E_EGP db	(type PUSHAD_STR) dup (?); Caller's EGP registers
INT0E_ES  dw	?,?		; ...	   ES
INT0E_DS  dw	?,?		; ...	   DS
INT0E_RET dq	?		; ...	   return address
INT0E_ERR dd	?		; ...	   error code
INT0E_EIP dd	?		; ...	   EIP
INT0E_CS  dw	?,?		; ...	   CS w/filler
INT0E_EFL dd	?		; ...	   EFL
INT0E_STK dd	?		; ...	   stack

INT0E_STR ends

	sub	esp,2*4 	; Make room for next handler

	REGSAVE <ds,es> 	; Save registers

	pushad			; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	mov	ax,cs		; Get code selector
	add	ax,8		; Skip to data selector
	mov	ds,ax		; Address it
	mov	es,ax		; Address it

	mov	eax,[ebp].INT0E_EGP.PUSHAD_EAX ; Get the register
	lea	edi,MSG_I0E_EAX ; Offset to display text
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	eax,[ebp].INT0E_EGP.PUSHAD_EBX ; Get the register
	lea	edi,MSG_I0E_EBX ; Offset to display text
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	eax,[ebp].INT0E_EGP.PUSHAD_ECX ; Get the register
	lea	edi,MSG_I0E_ECX ; Offset to display text
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	eax,[ebp].INT0E_EGP.PUSHAD_EDX ; Get the register
	lea	edi,MSG_I0E_EDX ; Offset to display text
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	eax,[ebp].INT0E_EGP.PUSHAD_ESI ; Get the register
	lea	edi,MSG_I0E_ESI ; Offset to display text
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	eax,[ebp].INT0E_EGP.PUSHAD_EDI ; Get the register
	lea	edi,MSG_I0E_EDI ; Offset to display text
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	eax,[ebp].INT0E_EGP.PUSHAD_EBP ; Get the register
	lea	edi,MSG_I0E_EBP ; Offset to display text
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	ax,[ebp].INT0E_DS ; Get the register
	lea	edi,MSG_I0E_DS	; Offset to display text
	mov	ecx,4		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	ax,[ebp].INT0E_ES ; Get the register
	lea	edi,MSG_I0E_ES	; Offset to display text
	mov	ecx,4		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	ax,fs		; Get the register
	lea	edi,MSG_I0E_FS	; Offset to display text
	mov	ecx,4		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	ax,gs		; Get the register
	lea	edi,MSG_I0E_GS	; Offset to display text
	mov	ecx,4		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	ax,ss		; Get the register
	lea	edi,MSG_I0E_SS	; Offset to display text
	mov	ecx,4		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	eax,cr2 	; Get the offset
	lea	edi,MSG_I0E_CR2 ; Offset to display text
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	eax,cr3 	; Get the offset
	lea	edi,MSG_I0E_CR3 ; Offset to display text
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	eax,[ebp].INT0E_EIP ; Get the offset
	lea	edi,MSG_I0E_EIP ; Offset to display text
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	ax,[ebp].INT0E_CS ; Get the selector
	lea	edi,MSG_I0E_CS	; Offset to display text
	mov	ecx,4		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	eax,[ebp].INT0E_EFL ; Get the flags
	lea	edi,MSG_I0E_EFL ; Offset to display text
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text

	mov	esi,OFFSET32 MSG_I0E_HDR ; Display the header info
	call	OutString	; Display the ASCIIZ string

; Display the stack

	lea	esi,[ebp].INT0E_STK ; SS:ESI ==> stack
	cld			; String ops forwards
	mov	ecx,8		; # rows to display
INT0E_NEXT1:
	push	ecx		; Save # rows

	mov	ecx,8		; # cols to display
	lea	edi,MSG_I0E_STK ; Offset to display text
INT0E_NEXT2:
	lods	ss:[esi].EDD	; Get next dword

	push	ecx		; Save for a moment
	mov	ecx,8		; Number of digits
	call	TOHEX		; Format ==> to message text
	pop	ecx		; Restore

	inc	edi		; Skip to next entry

	loop	INT0E_NEXT2	; Jump if more cols

	push	esi		; Save for a moment
	mov	esi,OFFSET32 MSG_I0E_STK ; Display the header info
	call	OutString	; Display the ASCIIZ string
	pop	esi		; Restore

	pop	ecx		; ...

	loop	INT0E_NEXT1	; Jump if more stack entries to display

	mov	eax,OLDINT0E_FVEC.FOFF ; Get offset of next handler
	mov	[ebp].INT0E_RET.FOFF,eax ; Save to return to

	mov	ax,OLDINT0E_FVEC.FSEL ; Get selector of next handler
	mov	[ebp].INT0E_RET.FSEL,ax ; Save to return to

	popad			; Restore

	REGREST <es,ds> 	; Restore

	cli
	hlt

	retf			; Continue with next handler

EndProc INT0E

BeginProc HookPF

	REGSAVE <eax,ebx>	; Save registers

IDT	equ	<[ebx+0Eh*(type IDT_STR)]>

	SIDTD	IDTR		; Save IDTR on stack
	mov	ebx,IDTR.DTR_BASE ; ES:EBX ==> IDT

	mov	eax,OFFSET32 INT0E ; Get offset of PF handler
	xchg	ax,IDT.IDT_OFFLO ; Swap with IDT
	ror	eax,16		; Swap high- and low-order
	xchg	ax,IDT.IDT_OFFHI ; Swap with IDT
	ror	eax,16		; Swap high- and low-order
	mov	OLDINT0E_FVEC.FOFF,eax ; Save to restore later

	mov	ax,cs		; Get our code selector
	xchg	ax,IDT.IDT_SELECT ; Swap with IDT
	mov	OLDINT0E_FVEC.FSEL,ax ; Save to restore later

	mov	al,CPL0_INTR3 or CPL3 ; Get our access rights byte
	xchg	al,IDT.IDT_ACCESS ; Swap with IDT
	mov	OLDINT0E_ARB,al ; Save to restore later

	REGREST <ebx,eax>	; Restore

	ret			; Return to caller

EndProc HookPF

BeginProc HookGP

	REGSAVE <eax,ebx>	; Save registers

IDT	equ	<[ebx+0Dh*(type IDT_STR)]>

	SIDTD	IDTR		; Save IDTR on stack
	mov	ebx,IDTR.DTR_BASE ; ES:EBX ==> IDT

	mov	eax,OFFSET32 INT0D ; Get offset of GP handler
	xchg	ax,IDT.IDT_OFFLO ; Swap with IDT
	ror	eax,16		; Swap high- and low-order
	xchg	ax,IDT.IDT_OFFHI ; Swap with IDT
	ror	eax,16		; Swap high- and low-order
	mov	OLDINT0D_FVEC.FOFF,eax ; Save to restore later

	mov	ax,cs		; Get our code selector
	xchg	ax,IDT.IDT_SELECT ; Swap with IDT
	mov	OLDINT0D_FVEC.FSEL,ax ; Save to restore later

	mov	al,CPL0_INTR3 or CPL3 ; Get our access rights byte
	xchg	al,IDT.IDT_ACCESS ; Swap with IDT
	mov	OLDINT0D_ARB,al ; Save to restore later

	REGREST <ebx,eax>	; Restore

	ret			; Return to caller

EndProc HookGP

BeginProc SEL2BASE		; Get Base Address Of A Selector
COMMENT|

Convert selector to base address

On exit:

EAX	 =	 linear address of selector base

|

SEL2BASE_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
SEL2BASE_SEL dw ?,0		; The selector

SEL2BASE_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	push	ebx		; Save for a moment

	sub	esp,size DTR_STR ; Make room for GDTR

	sgdt	[esp].EDF	; Save address of current GDT

	movzx	ebx,[ebp].SEL2BASE_SEL ; Get the selector
	and	bx,not (mask $PL) ; Clear the PL bits

	btr	ebx,$TI 	; Izit in the LDT?
	jnc	short @F	; Jump if not

	mov	[esp].DTR_BASE,eax ; Save for a moment

	sldt	ax		; Get current LDT selector

	push	eax		; Pass the selector
	call	SEL2BASE	; Return with EAX == selector base address

	xchg	eax,[esp].DTR_BASE ; Swap 'em leaving LDT base address on stack
@@:
	add	ebx,[esp].DTR_BASE ; Plus the GDT/LDT's base address
				; EBX ==> GDT/LDT entry
	add	esp,size DTR_STR ; Strip off GDTR

	mov	eax,[ebx].DESC_BASE01.EDD ; Get bytes 0-2
	shl	eax,8		; Make room for byte 3
	mov	al,[ebx].DESC_BASE3 ; Get byte 3
	ror	eax,8		; Rotate back to normal order

	pop	ebx		; Restore
	pop	ebp		; ...

	ret	4		; Return to caller, popping argument

EndProc SEL2BASE		; End SEL2BASE procedure

VxD_LOCKED_CODE_ENDS		; End LOCKED_CODE segment


VxD_ICODE_SEG			; Begin _ICODE segment

BeginProc TrapCodeWrites	; Setup Trap For Writing Into VxD Code segments
COMMENT|

Setup trap for writing into VxD code segments

|

	pushad			; Save all registers

	xor	ecx,ecx 	; Zero in case the function fails

	mov	ax,@I41_GETLS	; Get function code to return address of
				; load segment table
	int	41h		; Request WKD service
				; Return with ESI ==> load segment table
				; ...	      ECX = # entries
	jecxz	TrapCodeWritesExit ; Jump if nothing to do

; Get linear address of PTEs

	mov	eax,cr3 	; Get physical base of page directory
	and	eax,@PTE_FRM	; Isolate the 4KB frame

	REGSAVE <ecx,esi>	; Avid W clobbering

	VMMcall _MapPhysToLinear <eax, 4096, 0> ; Get linear address

	REGREST <esi,ecx>	; Restore

@PDELOC equ	(2*1024)-(3*4)	; Location for new PDE
@PDELIN equ	@PDELOC shl (22-2) ; Linear address of @PDELOC

	mov	edi,eax 	; Copy for later use
	add	edi,@PDELOC	; Add to get offset of PDE

	push	[edi].EDD	; Save the PDE

	mov	eax,cr3 	; Get physical base of page directory
	and	eax,@PTE_FRM	; Isolate the 4KB frame
	or	eax,@PTE_URP	; Mark as User/Read-Write/Present
	mov	[edi],eax	; Set CR3 as new PDE
	mov	edx,@PDELIN	; Get linear address of CR3
TrapCodeWritesNext:

; For each PM code segment entry,
; find the corresponding PTE(s) and clear the $PTE_RW bit

	test	[esi].WKDLS_FLAG,@WKDLS_RM ; Izit in RM?
	jnz	short TrapCodeWritesLoop ; Jump if so

	test	[esi].WKDLS_FLAG,@WKDLS_CODE ; Izit a code segment?
	jz	short TrapCodeWritesLoop ; Jump if not

	REGSAVE <ecx>		; Save register

	push	[esi].WKDLS_SEL.EDD ; Get selector
	call	SEL2BASE	; Return with ERAX = base address

	add	eax,[esi].WKDLS_BASE ; Plus offset
	mov	ecx,[esi].WKDLS_LEN ; Get length in bytes
	jecxz	TrapCodeWrites1 ; Jump if it's empty

; EAX = start
; ECX = length

; Round down to 4KB boundary and calculate the # PTEs is spans

	add	ecx,eax 	; Add to get next byte
	and	eax,not (4*1024-1) ; Round down to 4KB boundary
	sub	ecx,eax 	; Subtract to get length from ...
	add	ecx,4*1024-1	; Round up to 4KB boundary
	shr	ecx,12-0	; Convert from bytes to 4KB
	shr	eax,12-0	; Convert from bytes to 4KB

; EAX = index into PTEs
; ECX = # PTEs

; Clear the Dirty and Read-Write bits
; Note we must clear the Dirty bit as well so as to avoid
; problems with the LRU sweep.

@@:
	and	[edx+eax*4].EDD,not ((mask $PTE_D) or (mask $PTE_RW)) ; Clear the bits

	inc	eax		; Skip to next entry

	loop	@B		; Jump if more PTEs to check
TrapCodeWrites1:
	REGREST <ecx>		; Restore
TrapCodeWritesLoop:
	add	esi,type WKDLS_STR ; Skip to next entry

	loop	TrapCodeWritesNext ; Jump if more entries

	pop	[edi].EDD	; Restore the PDE
TrapCodeWritesExit:
	popad			; Restore

	ret			; Return to caller

EndProc TrapCodeWrites		; End TrapCodeWrites procedure

VxD_ICODE_ENDS			; End _ICODE segment

	end			; End SWATVXD module
