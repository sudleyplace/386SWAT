;'$Header:   P:/PVCS/SWATVXD/SWAT_SVC.ASV   1.11   10 Aug 1998 10:46:28   BOB  $
	 title	 SWAT_SVC -- Service Routines for SWATVXD
	 page	 58,122
	 name	 SWAT_SVC

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

Link requirements:  Final routine should have extension .386, .EXE, or .VXD.

Program derived from:  None.

Original code by:  William R. Lewis, July, 1990.

Modifications by:  None.

|

.386p
.xlist
	 include VMM.INC	; Fixed version of file from DDK
	include VKD.INC

	 include MASM.INC	; From Bob's standard includes
	 include 386.INC
	 include PTR.INC
	 include CPUFLAGS.INC
	 include ASCII.INC
	include SCANCODE.INC

	 include WINDEVID.INC	; Define SWAT_Device_ID
	 include SWATVXD.INC	; Define service table
	 include SWAT_DBG.INC	; DBG_FLAG masks
	 include SWAT_MAC.INC	; Debugging macros
	 include SWATVER.INC	; Version # extrns
.list

VxD_LOCKED_DATA_SEG		; Begin _LDATA segment

	 extrn	 SWATMSG_FVEC:fword
	extrn	SWAT_DDB:tbyte

	 public  DBG_FLAG,DB2_FLAG,DB3_FLAG
DBG_FLAG dd	 0		; Flags to control the operation of the VxD
DB2_FLAG dd	 0		; ...
DB3_FLAG dd	 0		; ...

	 public  MONO_VIDBASE
MONO_VIDBASE	 dd	0B0000h ; Base address of monochrome display

	public	EnterVMM,ExitVMM
EnterVMM df	?		; Enter VMM routine address
	dw	?		; For alignment
ExitVMM df	?		; Exit ...
	dw	?		; For alignment

VERSION_STRING	db	'SWATVXD', 0

HEX	 db	 '0123456789ABCDEF'

MONO_OFF dw	 ?		; Line # for monochrome debugging output
MONO_CHAR dd	0		; Offset within line to character
MONO_LIN dd	 ?		; Linear address of monochrome display page

	db	SWATCOPY	; Common copyright message

	 public  FREQ
FREQ	 dd	 1193182	; Fundamental frequency

MSG_HEX4		db	'xxxx', 0
MSG_HEX8		db	'xxxxxxxx', 0

MSG_DUMP	db	' '
MSG_DUMP_1	db	'xxxx '
MSG_DUMP_2	db	'xxxx '
MSG_DUMP_3	db	'xxxx '
MSG_DUMP_4	db	'xxxx '
		db	0

MSG_IDT 	db	'IDTR = '
MSG_IDT_BASE	db	'xxxxxxxx '
MSG_IDT_LIM	db	'xxxx', 0

; Message text for SHOW_CRS debugging procedure

MSG_SCR_R1	db	'    EAX='
MSG_SCR_EAX	db	'xxxxxxxx  EBX='
MSG_SCR_EBX	db	'xxxxxxxx  ECX='
MSG_SCR_ECX	db	'xxxxxxxx  EDX='
MSG_SCR_EDX	db	'xxxxxxxx', 0

MSG_SCR_R2	db	'    ESI='
MSG_SCR_ESI	db	'xxxxxxxx  EDI='
MSG_SCR_EDI	db	'xxxxxxxx  EBP='
MSG_SCR_EBP	db	'xxxxxxxx', 0

MSG_SCR_R3	db	'    DS='
MSG_SCR_DS	db	'xxxx       ES='
MSG_SCR_ES	db	'xxxx       FS='
MSG_SCR_FS	db	'xxxx       GS='
MSG_SCR_GS	db	'xxxx', 0

MSG_SCR_R4	db	'    CS:EIP='
MSG_SCR_CS	db	'xxxx:'
MSG_SCR_EIP	db	'xxxxxxxx        SS:ESP='
MSG_SCR_SS	db	'xxxx:'
MSG_SCR_ESP	db	'xxxxxxxx',0

	public	Force_Keys
Force_Keys db	@SSC_CTRL + 80h 	 ; Right Ctl-
	db	@SSC_ALT  + 80h 	 ; Right Alt-
	db	@SSC_RSHFT + 80h	 ; Right Shift-
	db	@SSC_E0, @SSC_CTRL + 80h ; Left  Ctl-
	db	@SSC_E0, @SSC_ALT  + 80h ; Left  Alt-
	db	@SSC_LSHFT + 80h	 ; Left  Shift-
@Force_Keys equ $-Force_Keys	; Length of ...

VxD_LOCKED_DATA_ENDS		; End _LDATA segment


VxD_LOCKED_CODE_SEG		; Begin _LCODE segment

BeginProc WKD_PMAPI		; Kernel debugger PM API
COMMENT|

Windows kernel debugger PM API

On entry:

SS:ESP	==>	far return address
		service requested

|

WKD_STR struc

WKD_EBP dd	?		; Caller's EBP
WKD_EAX dd	?		; ...	   EAX
	dq	?		; ...	   CS:EIP
WKD_SERV dd	?		; Service #

WKD_STR ends

	push	eax		; Save as placeholder

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	push	ebx		; Save register

	mov	eax,[ebp].WKD_SERV ; Get the service #

	cmp	eax,@SWAT_MAX_FN ; Izit within range?
	ja	short @F	; Jump if not

	mov	ebx,SWAT_DDB.DDB_Service_Table_Ptr ; Get ptr to service table
	mov	eax,[ebx+eax*4] ; Get the service routine offset
	xchg	eax,[ebp].WKD_EAX ; Swap
@@:
	pop	ebx		; Restore
	ja	short @F	; Jump if not within range

	call	[ebp].WKD_EAX	; Request service
@@:
	pop	ebp		; Restore

	add	esp,size WKD_EAX ; Stip from the stack

	retf	4		; Return to caller, popping argument

EndProc WKD_PMAPI		; End WKD_PMAPI procedure

BeginProc SWAT_Get_Version, SERVICE

	 sub	 eax,eax	; Kill high-order half
	 mov	 ah,SWAT_VERH	; Major #
	 mov	 al,SWAT_VERL	; Minor #

	 mov	 esi,OFFSET32 VERSION_STRING ; ==> ID string

	 ret			; ... to caller

EndProc SWAT_Get_Version	; End SWAT_Get_Version procedure

BeginProc SWAT_Out_Mono_String, SERVICE
COMMENT|

	 Service procedure interface to DISPLAY

|

	 call	 DISPLAY	; Call the mono display procedure

	 call	 WDEB_DISPLAY	; Send it to WDEB386 if it is installed

	 ret			; ... to caller

EndProc  SWAT_Out_Mono_String	; End SWAT_Out_Mono_String procedure

BeginProc SWAT_SWATMSG, SERVICE
COMMENT|

	 Service procedure interface to SWATMSG

Entry:
	EAX =	Error code (or 0 if none)
	DS:ESI ==>	NULL terminated message text

|

	push	eax		; Pass the error code
	push	ds		; ... selector
	push	esi		; ... offset
	call	SWATMSG_FVEC	; Pass along to SWATMSG

	ret			; ... to caller

EndProc  SWAT_SWATMSG		; End SWAT_SWATMSG procedure

BeginProc SWAT_Clear_Keys, SERVICE
COMMENT|

	Service procedure interface to clear Ctl- and Alt-Keys in Windows

|

	pushad			; Save registers

; In case we're called on a non-zero-based stack (like SWAT's),
; we need to convert SS to a zero-based selector

	mov	eax,esp 	; Copy current stack offset

	push	ss		; Save stack ptr
	push	eax		; ...

	VMMcall Get_Cur_VM_Handle ; EBX = handle of current VM
	VMMcall _GetDescriptor <ss,ebx,0> ; Return desc in EDX:EAX

	shrd	eax,edx,8	; Shift low-order byte of EDX into
				; high-order byte of EAX
	shr	edx,24		; Shift down high-order byte to low-order
	shrd	eax,edx,8	; Shift low-order byte of EDX into
				; high-order byte of EAX
	add	eax,esp 	; Plus stack offset

	push	ds		; Push new stack selector
	push	eax		; ...		 offset
	lss	esp,[esp]	; Put into effect

	lea	esi,Force_Keys	; ESI ==> buffer of scan codes
	mov	ecx,@Force_Keys ; ECX = # scan codes in buffer
	VxDcall VKD_Force_Keys	; Send release of Ctl- and Alt-keys

	lss	esp,[esp]	; Restore stack ptr

	popad			; Restore

	ret			; Return to caller

EndProc SWAT_Clear_Keys 	; End SWAT_Clear_Keys procedure

;;; BeginProc SWAT_LinPageLock, SERVICE
;;; COMMENT|
;;;
;;; Service procedure interface to lock a linear page
;;;
;;; On entry:
;;;
;;; ECX     =	    # bytes to lock
;;; ESI     =	    linear address to lock
;;;
;;; |
;;;
;;;	    pushad		    ; Save registers
;;;
;;;	    add     ecx,esi	    ; Get address of ending byte
;;;	    and     esi,not (4*1024-1) ; Round down to page boundary
;;;	    sub     ecx,esi	    ; Less rounded address
;;;	    add     ecx,4*1024-1    ; Round up to 4KB boundary
;;;	    shr     esi,12-0	    ; Convert from bytes to pages
;;;	    shr     ecx,12-0	    ; ...
;;;
;;; ; Check the linear address range
;;;
;;;	    push    esi 	    ; Save for a moment
;;;	    VMMcall _PageCheckLinRange,<esi,ecx,0> ; Request VMM service
;;;	    pop     esi 	    ; Restore
;;;	    VMMcall _LinPageLock,<esi,eax,0> ; Request VMM service
;;;
;;;	    popad		    ; Restore
;;;
;;;	    ret 		    ; Return to caller
;;;
;;; EndProc SWAT_LinPageLock	    ; End SWAT_LinPageLock procedure
;;;
;;; BeginProc SWAT_LinPageUnLock, SERVICE
;;; COMMENT|
;;;
;;; Service procedure interface to unlock a linear page
;;;
;;; On entry:
;;;
;;; ECX     =	    # bytes to unlock
;;; ESI     =	    linear address to unlock
;;;
;;; |
;;;
;;;	    pushad		    ; Save registers
;;;
;;; ; In case we're called on a non-zero-based stack (like SWAT's),
;;; ; we need to convert SS to a zero-based selector
;;;
;;;	    mov     eax,esp	    ; Copy current stack offset
;;;
;;;	    push    ss		    ; Save stack ptr
;;;	    push    eax 	    ; ...
;;;
;;;	    REGSAVE <ecx,esi>	    ; Save for a moment
;;;
;;;	    VMMcall Get_Cur_VM_Handle ; EBX = handle of current VM
;;;	    VMMcall _GetDescriptor <ss,ebx,0> ; Return desc in EDX:EAX
;;;
;;;	    REGREST <esi,ecx>	    ; Restore
;;;
;;;	    shrd    eax,edx,8	    ; Shift low-order byte of EDX into
;;;				    ; high-order byte of EAX
;;;	    shr     edx,24	    ; Shift down high-order byte to low-order
;;;	    shrd    eax,edx,8	    ; Shift low-order byte of EDX into
;;;				    ; high-order byte of EAX
;;;	    add     eax,esp	    ; Plus stack offset
;;;
;;;	    push    ds		    ; Push new stack selector
;;;	    push    eax 	    ; ...	     offset
;;;	    lss     esp,[esp]	    ; Put into effect
;;;
;;;	    add     ecx,esi	    ; Get address of ending byte
;;;	    and     esi,not (4*1024-1) ; Round down to page boundary
;;;	    sub     ecx,esi	    ; Less rounded address
;;;	    add     ecx,4*1024-1    ; Round up to 4KB boundary
;;;	    shr     esi,12-0	    ; Convert from bytes to pages
;;;	    shr     ecx,12-0	    ; ...
;;;
;;;	    VMMcall _LinPageUnLock,<esi,ecx,0> ; Request VMM service
;;;
;;;	    lss     esp,[esp]	    ; Restore stack ptr
;;;
;;;	    popad		    ; Restore
;;;
;;;	    ret 		    ; Return to caller
;;;
;;; EndProc SWAT_LinPageUnLock	    ; End SWAT_LinPageUnLock procedure
;;;
VxD_LOCKED_CODE_ENDS		; End _LCODE segment

VxD_CODE_SEG			; Begin _CODE segment

BeginProc CALC_VIDOFF		; Calculate video screen offset
COMMENT|

	Calculate video screen offset

On exit:

EDI	=	linear address of next byte to write to mono screen

|

	movzx	edi,MONO_OFF	; Get line number within window
	imul	edi,2*80	; Times 2 bytes per position * 80
				; positions per line
	add	edi,MONO_LIN	; Monochrome screen address

	ret

EndProc CALC_VIDOFF		; End CALC_VIDOFF procedure

BeginProc CALC_SCROLL		; Scroll The Screen If Necessary
COMMENT|

	Scroll the screen if necessary

|

	REGSAVE <eax,ecx,esi,edi> ; Save registers

	 mov	 ax,MONO_OFF	; Get line number within window

	 cmp	 ax,25		; End of window?
	 jb	 short DISPLAY_NO_SCROLL ; No

; Scroll window up one line

	 mov	 ecx,24*80	; 24 lines * 80 chars
	 mov	 esi,MONO_LIN	; Linear address of debugging screen
	 mov	 edi,esi	; Destination
	 lea	 esi,[esi+(1*2*80)] ; Source
S32	 rep movsw		; Move character and attribute
	mov	ax,0720h	; Char and attr
	mov	ecx,80		; 1 line
S32 rep stosw			; Blank the last line

; Finally, jam line number for next time

	 mov	 MONO_OFF,24	; Last line within window
DISPLAY_NO_SCROLL:
	REGREST <edi,esi,ecx,eax> ; Restore

	ret			; Return to caller

EndProc CALC_SCROLL		; End CALC_SCROLL procedure

BeginProc DISPLAY		; Display String on Debugging Screen
COMMENT|

	Display string on the mono debugging screen

Input:
	DS:ESI	-->	Null-terminated string to be displayed
			CR and LF characters are not displayed

|

	 test	 DB2_FLAG,@DB2_DUAL ; Should we display anything?
	 jz	 short DISPLAY_XIT ; Jump if not

	 REGSAVE <eax,edi,esi>	; Save during routine

	call	CALC_SCROLL	; Scroll the screen if necessary

; Get screen line number, convert to byte offset and adjust for window

	call	CALC_VIDOFF	; Calculate the video screen offset into EDI
	add	edi,MONO_CHAR	; Plus offset to char

	 push	 ecx		; Save
DISP_NXT0:
	 mov	 ecx,80 	; Length of line
DISP_NXT1:
	 mov	 ah,07h 	; Attribute
DISP_NXT:
	 lodsb			; Get source character

	 cmp	 al,CR		; Izit a CR?
	jne	short DISP_NXT_XCR ; Jump if not

	call	CALC_VIDOFF	; Calculate the video screen offset into EDI
				; to start at beginning of line
	jmp	 short DISP_NXT0 ; Go around again

DISP_NXT_XCR:
	 cmp	 al,LF		; Izit a LF?
	jne	short DISP_NXT_XLF ; Jump if not

	mov	eax,edi 	; Save current screen position
	call	CALC_VIDOFF	; Calculate the video screen offset into EDI
				; to start at beginning of line
	sub	eax,edi 	; Subtract to get offset into current line
	inc	MONO_OFF	; Skip to the next line
	call	CALC_SCROLL	; Scroll the screen if necessary
	call	CALC_VIDOFF	; Calculate the video screen offset into EDI
				; to start at beginning of line
;;;;;;; add	edi,eax 	; Add to get same offset into current line

	jmp	 short DISP_NXT1 ; Go around again

DISP_NXT_XLF:
	 or	 al,al		; Terminating NULL?
	 jz	 short DISP_NON ; Yes, exit loop

S32	 stosw			; Store character and attribute
DISP_SKP:
	 loop	 DISP_NXT	; Keep going
DISP_NON:
	push	edi		; Save for a moment
	mov	eax,edi 	; Save current screen position
	call	CALC_VIDOFF	; Calculate the video screen offset into EDI
				; to start at beginning of line
	sub	eax,edi 	; Subtract to get offset into current line
	mov	MONO_CHAR,eax	; Save for later use
	pop	edi		; Restore

	 mov	 al,' '         ; Blank
	 rep stosw		; Clear rest of line

	 pop	 ecx		; Restore

	 REGREST <esi,edi,eax>	; Restore for caller
DISPLAY_XIT:
	 ret

EndProc  DISPLAY		; End DISPLAY procedure

BeginProc WDEB_DISPLAY		; Send to WDEB386 terminal
COMMENT|

	Print message on WDEB386 terminal

Entry:
	ESI ==> Message text

|

	 pushad 		; Save caller's registers

	test	DB2_FLAG,@DB2_WKD ; Are we a Windows Kernel Debugger?
	jnz	short @F	; Jump if so

	 VMMcall Test_Debug_Installed	; Zero flag = debugger not installed
	 jz	 short @F		; Skip if no debugger

	 VMMcall Out_Debug_String	; Send it to the debugging monitor
@@:
	 popad			; Restore caller's registers

	 ret			; ... to caller

EndProc  WDEB_DISPLAY		; End WDEB_DISPLAY procedure

BeginProc TOHEX 		; Binary to ASCII HEX Conversion
COMMENT|

Format EAX into ASCII hex digits.

On entry:

EAX	 =	  Number to format
ECX	 =	  Number of digits desired
DS:EDI	 =>	  Output area for digits

On exit:

DS:EDI	==>	(updated)

|

	 REGSAVE <eax,ecx,edx,esi> ; Save caller's registers

	 mov	 edx,ecx	; Copy number of digits
	 shl	 ecx,2		; Times 4 to get bits-per-digit
	 ror	 eax,cl 	; Rotate interesting bits around
	 mov	 ecx,edx	; Restore number of digits

@@:
	 rol	 eax,4		; Move next nibble to low end
	 mov	 si,ax		; Copy to SI
	 and	 esi,15 	; Kill everything but lowest nibble
	 mov	 dl,HEX[esi]	; Form ASCII hex digit
	 mov	 [edi],dl	; Store into output stream
	 inc	 edi		; Bump output pointer
	 loop	 @B		; Continue with remainder of digits

	 REGREST <esi,edx,ecx,eax>	; Restore caller's registers

	 ret			; ... to caller

EndProc  TOHEX			; End TOHEX procedure

ifdef @DEBUG
BeginProc SHOW_CRS		; Show the ClientRegisterStructure
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:FLAT
COMMENT|

Entry:
	EBP	==>	ClientRegisterStructure

|

	 REGSAVE <eax,ecx,esi,edi> ; Save caller's registers

	 mov	 ecx,8			; # of digits

	 lea	 edi,MSG_SCR_EAX	; Offset to hex display area
	 mov	 eax,[ebp].Client_EAX	; Get V86 client's EAX
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_EBX	; Offset to hex display area
	 mov	 eax,[ebp].Client_EBX	; Get V86 client's EBX
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_ECX	; Offset to hex display area
	 mov	 eax,[ebp].Client_ECX	; Get V86 client's ECX
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_EDX	; Offset to hex display area
	 mov	 eax,[ebp].Client_EDX	; Get V86 client's EDX
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_ESI	; Offset to hex display area
	 mov	 eax,[ebp].Client_ESI	; Get V86 client's ESI
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_EDI	; Offset to hex display area
	 mov	 eax,[ebp].Client_EDI	; Get V86 client's EDI
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_EBP	; Offset to hex display area
	 mov	 eax,[ebp].Client_EBP	; Get V86 client's EPX
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_ESP	; Offset to hex display area
	 mov	 eax,[ebp].Client_ESP	; Get V86 client's ESP
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_EIP	; Offset to hex display area
	 mov	 eax,[ebp].Client_EIP	; Get V86 client's EIP
	 call	 TOHEX			; Form ASCII HEX from EAX

	 mov	 ecx,4			; # of digits in segments registers

	 lea	 edi,MSG_SCR_CS 	; Offset to hex display area
	 movzx	 eax,[ebp].Client_CS	; Get V86 client's CS
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_DS 	; Offset to hex display area
	 movzx	 eax,[ebp].Client_DS	; Get V86 client's DS
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_ES 	; Offset to hex display area
	 movzx	 eax,[ebp].Client_ES	; Get V86 client's ES
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_FS 	; Offset to hex display area
	 movzx	 eax,[ebp].Client_FS	; Get V86 client's FS
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_GS 	; Offset to hex display area
	 movzx	 eax,[ebp].Client_GS	; Get V86 client's GS
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_SS 	; Offset to hex display area
	 movzx	 eax,[ebp].Client_SS	; Get V86 client's SS
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 esi,MSG_SCR_R1 	; Show EAX, EBX, ECX, and EDX
	 call	 DISPLAY

	 lea	 esi,MSG_SCR_R2 	; Show ESI, EDI, EBP, and ESP
	 call	 DISPLAY

	 lea	 esi,MSG_SCR_R3 	; Show DS, ES, FS, and GS
	 call	 DISPLAY

	 lea	 esi,MSG_SCR_R4 	; Show CS:EIP and SS:ESP
	 call	 DISPLAY

	 REGREST <edi,esi,ecx,eax> ; Save caller's registers

	 ret			; ... to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  SHOW_CRS		; End SHOW_CRS procedure
endif	 ; ifdef @DEBUG

;;;;;;	 NPPROC  SHOWHEX4 -- Display in HEX on Debugging Screen
;;;;;;
;;;;;;	 push	 eax
;;;;;;	 push	 ecx
;;;;;;	 push	 esi
;;;;;;	 push	 edi
;;;;;;
;;;;;;	 mov	 ecx,4
;;;;;;	 lea	 edi,MSG_HEX4
;;;;;;	 call	 TOHEX
;;;;;;
;;;;;;	 lea	 esi,MSG_HEX4
;;;;;;	 call	 DISPLAY
;;;;;;
;;;;;;	 pop	 edi
;;;;;;	 pop	 esi
;;;;;;	 pop	 ecx
;;;;;;	 pop	 eax
;;;;;;
;;;;;;	 ret
;;;;;;
;;;;;;SHOWHEX4 endp
;;;;;;
;;;;;;	 NPPROC  SHOWHEX8 -- Display in HEX on Debugging Screen
;;;;;;
;;;;;;	 push	 eax
;;;;;;	 push	 ecx
;;;;;;	 push	 esi
;;;;;;	 push	 edi
;;;;;;
;;;;;;	 mov	 ecx,8
;;;;;;	 lea	 edi,MSG_HEX8
;;;;;;	 call	 TOHEX
;;;;;;
;;;;;;	 lea	 esi,MSG_HEX8
;;;;;;	 call	 DISPLAY
;;;;;;
;;;;;;	 pop	 edi
;;;;;;	 pop	 esi
;;;;;;	 pop	 ecx
;;;;;;	 pop	 eax
;;;;;;
;;;;;;	 ret
;;;;;;
;;;;;;SHOWHEX8 endp

VxD_CODE_ENDS			; End _LCODE segment

VxD_ICODE_SEG			; Begin _ICODE segment

	 assume  cs:FLAT

BeginProc SETUP_MONO		; Initialize Monochrome Debugging Screen
	 assume  ds:FLAT, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

	Initialize debugging screen

|

	 REGSAVE <eax,ecx,edi>	; Save during routine

	 test	 DB2_FLAG,@DB2_DUAL ; Are we supposed to print this stuff?
	 jz	 short SETUP_MONO_XIT ; Exit if not

	 mov	 MONO_OFF,0	; Start off at the top line

	 mov	 eax,MONO_VIDBASE ; Get base address of monochrome display
	 VMMcall _MapPhysToLinear <eax, 2*25*80, 0>
	 mov	 MONO_LIN,eax	; Save linear address of debugging screen

	 mov	 edi,eax	; EDI = offset to next position on screen

	 mov	 ecx,25*80	; Number of WORDS to clear
	 mov	 ax,0720h	; Attribute and character

	 rep stosw		; Blank out the debugging screen

SETUP_MONO_XIT:
	 REGREST <edi,ecx,eax>	; Restore caller's registers

	 ret			; ... to caller

EndProc  SETUP_MONO		; End SETUP_MONO procedure

VxD_ICODE_ENDS			; End _ICODE segment

	 end			; End SWAT_SVC module
