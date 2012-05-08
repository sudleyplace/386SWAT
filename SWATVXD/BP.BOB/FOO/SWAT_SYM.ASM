;'$Header:   P:/PVCS/SWATVXD/SWAT_SYM.ASV   1.5   10 Aug 1998 10:46:30   BOB  $
	 title	 SWAT_SYM -- Symbol Support Stuff for SWATVXD
	 page	 58,122
	 name	 SWAT_SYM

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1992-98 Qualitas, Inc.

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

Original code by:  William R. Lewis, April, 1992.

Modifications by:  None.

|

.386p
.xlist
	 include VMM.INC	; Fixed version of file from DDK

	 include MASM.INC	; From Bob's standard includes
	 include 386.INC
	 include PTR.INC
	 include OPCODES.INC
	 include VCPI.INC

	 include WFW.INC		; Homemade include for WFW VxDs
	 include PM_BIOS.INC		; Homemade include for Thinkpad PM_BIOS

	 include SWAT_INF.INC	; From 386SWAT
	 include SWAT_SYM.INC

	 include SWATVER.INC	; Version # extrns
.list

DEVSVC_STR	 struc			; Structure defining device ID's, etc.

DS_DEVICE_ID	 dw	?		; Device ID
DS_GROUPNAME	 dd	?		; ==> device's segment name prefix
					; i.e. "VMM" for VMM_LGROUP
DS_1STNAME	 dd	?		; ==> 1st documented name

DEVSVC_STR	 ends			; End DEVSVC_STR structure

VxD_LOCKED_DATA_SEG			; Begin _LDATA segment

	 extrn	 SWATINT67_VEC:fword
	 extrn	 SWATINFO_LIN:dword
	 extrn	WIN3_VERSION:word

VxD_LOCKED_DATA_ENDS			; End _LDATA segment

VxD_LOCKED_CODE_SEG			; Begin _LCODE segment

	extrn	Lcl_Get_Cur_VM_Handle:near
	extrn	Lcl_Get_Sys_VM_Handle:near

VxD_LOCKED_CODE_ENDS		; End LOCKED_CODE segment

VxD_IDATA_SEG				; Begin _IDATA segment

	 extrn	 STR_386SWAT:near

SYMTRANSTR SYMTRAN_STR	<>	; Instance of SYMTRAN_STR for symbol translation

STR_SSFPREFIX	 db	'SSFPREFIX', 0  ; SYSTEM.INI key
STR_LOADHI	 db	'LoadHi', 0     ; Default for SSFPrefix=

STR_GUEST	 db	'12345678', 0   ; Buffer for SSFPrefix= name
SRCH_GUESTDDB	 db	0, '12345678_DDB' ; PASCAL string
SRCH_GUESTCONTROL db	0, '12345678_Control' ; PASCAL string

SYMBOL_OFF	 dd	?		; Offset of generic symbol

SRCH_SGL	 db	@SRCH_SGL_L		; Length of following string
		 db	'SWATVXD_GET_LGROUP'    ; Symbol in SWATVXD_LGROUP
@SRCH_SGL_L	 equ	($-SRCH_SGL)-1

SRCH_SGI	 db	@SRCH_SGI_L		; Length of following string
		 db	'SWATVXD_GET_IGROUP'    ; Symbol in SWATVXD_IGROUP
@SRCH_SGI_L	 equ	($-SRCH_SGI)-1

SRCH_SCI	 db	@SRCH_SCI_L		; Length of following string
		 db	'SYS_CRITICAL_INIT'     ; Symbol in _IGROUP
@SRCH_SCI_L	 equ	($-SRCH_SCI)-1

ORDINAL  dw	 ?		; Ordinal of dynalink

SYMCSTR  SYMC_STR <>		; Structure for @DBGSYM_APPND
	 db	 64 dup (?)	; Workarea for symbols

VxD_IDATA_ENDS			; End _IDATA segment

VxD_ICODE_SEG			; Begin _ICODE segment

	 extrn	STRLEN:near
	 extrn	FIND_DEVICE:near

BeginProc INIT_SYMBOLS		; Setup symbols for WIN386.EXE itself
COMMENT|

    Setup symbols for WIN386.EXE.

    This procedure establishes symbols for WIN386.EXE.
    It does not use a .MAP or .SYM file.
    It is insensitive to WIN386 version.

    For each VxD built into WIN386.EXE (including and starting with VMM)
    we perform the scheme in a loop.  Compile and execute a dynalink for
    the current Device_ID for the Get_Version service.

    The following instruction bytes would be used for Get_VMM_Version:
	CD 20		INT	20h	; Dynalink
	00 00		DW	0000h	; Get_VMM_Version service ordinal
	01 00		DW	0001h	; VMM_Device_ID

    After execution, WIN386 alters the dynalink to be a near indirect call:
	FF 15 xxxxxxxx	CALLN	[xxxxxxxx] ; $Get_VMM_Version

    We pick up the offset from the call instruction.  This is used to install
    a symbol in SWAT, $Get_VMM_Version.  The contents of the offset are used
    to install @Get_VMM_Version.

    Note all the OFFSET32 and indirect crap below is
    due to bugs in MASM 5.10B.

|

	 pushad 		; Save caller's registers

	 cmp	 SWATINT67_VEC.FOFF,0 ; Does 386SWAT.LOD support symbols?
	 je	 IS_STC 	; Skip the whole thing if not

	 lea	 edx,DEVICE_SERVICE_TAB ; EDX ==> DEVSVC_STR list

IS_NEXT_DEVICE:
	 mov	 ax,[edx].DS_DEVICE_ID	; Pick up VxD ID

	 or	 ax,ax		; Izit the sentinel?
	 jz	 IS_XDEVICE	; Exit loop if no more devices

	 mov	 SYMCSTR.SYM_GRP,ax	; Use the device ID as the group

	 mov	 ebx,OFFSET32 IS_VMMCALL_DEVICE_ID ; Offset of device ID
	 mov	 [ebx].ELO,ax	; Blast into dynalink

	 mov	 ebx,OFFSET32 IS_VMMCALL_ORDINAL ; Offset of ordinal
	 mov	 [ebx].ELO,0	; Blast into dynalink

	 mov	 ax,@OPCOD_INT or (20h shl 8) ; INT 20h instruction
	 mov	 ebx,OFFSET32 IS_VMMCALL_INT20	; Offset of INT 20h in dynalink
	 mov	 [ebx].ELO,ax	; Blast into dynalink

	 jmp	 short @F	; Flush prefetch queue
@@:

	 pushad 			; Save 'em all

IS_VMMCALL_INT20:
	 int	 20h			; Dynalink
IS_VMMCALL_ORDINAL label word
IS_VMMCALL_OFFSET label dword
	 dw	 ?			; Ordinal
IS_VMMCALL_DEVICE_ID label word
	 dw	 ?			; Device_ID

	 xchg	 eax,[esp].PUSHAD_EAX	; Don't restore this one

	 popad				; Restore 'em all

	 or	 eax,eax		; Is this VxD installed?
	 jz	 IS_LOOP_DEVICE 	; Nope

	 mov	 ebx,OFFSET32 IS_VMMCALL_OFFSET ; Pick up offset of $... name
	 mov	 ebx,[ebx]		; ...

	 mov	 esi,[edx].DS_1STNAME	; ==> 1st symbol name

IS_NEXT_SYM:

; ESI ==> an ASCIZ string containing the base name
; Form the indirect call name by tacking a '$' on the front.

	 push	 ebx		; Save pointer into dynalink table

	 lea	 edi,SYMCSTR.SYMC_NAME	; EDI ==> workarea
	 mov	 [edi].LO,'$'   ; Store the leading '$'
	 inc	 edi		; Bump past it
@@:
	 lodsb			; Get character of symbol
	 stosb			; Copy to work area
	 or	 al,al		; Izit the terminating NULL?
	 jnz	 short @B	; Go back for more if not

	 REGSAVE <ebx,edx,esi>	; Save

	 lea	 esi,SYMCSTR.SYMC_NAME	; ESI ==> symbol
	 call	 STRLEN 	; Get length of string at DS:ESI into EAX
	 mov	 SYMCSTR.SYMC_NAMLEN,al 	; Length of name

	 mov	 SYMCSTR.SYM_FVEC.FSEL,ds	; Segment
	 mov	 SYMCSTR.SYM_FVEC.FOFF,ebx	; Offset

	 lea	 esi,SYMCSTR	; DS:ESI ==> SYMC_STR
	 mov	 ecx,1		; Add one symbol
	 mov	 ax,(@VCPI shl 8) or @VCPI_DBGSYM ; Debugger symbol functions
	 mov	 bl,@DBGSYM_APPND ; Append symbols
	 pushfd 		; Simulate interrupt
	 cli			; ...
	 call	 SWATINT67_VEC	; Call SWAT's VCPI handler

	 REGREST <esi,edx,ebx>	; Restore

; ESI ==> an ASCIZ string containing the base name
; Form the indirect call name by tacking an '@' on the front.

	 lea	 edi,SYMCSTR.SYMC_NAME	; EDI ==> symbol
	 mov	 [edi].LO,'@'           ; Store the leading '@'

	 mov	 ebx,[ebx]		; Pick up offset of @... form of symbol

	 REGSAVE <ebx,edx,esi>		; Save

	 lea	 esi,SYMCSTR.SYMC_NAME	; ESI ==> symbol
	 call	 STRLEN 		; EAX = length of string at DS:ESI
	 mov	 SYMCSTR.SYMC_NAMLEN,al ; Length of name

	 mov	 SYMCSTR.SYM_FVEC.FSEL,cs ; Segment
	 mov	 SYMCSTR.SYM_FVEC.FOFF,ebx ; Offset

	 lea	 esi,SYMCSTR		; DS:ESI ==> SYMC_STR
	 mov	 ecx,1			; Add one symbol
	 mov	 ax,(@VCPI shl 8) or @VCPI_DBGSYM ; Debugger symbol functions
	 mov	 bl,@DBGSYM_APPND	; Append symbols
	 pushfd 			; Simulate interrupt
	 cli				; ...
	 call	 SWATINT67_VEC		; Call SWAT's VCPI handler

	 REGREST <esi,edx,ebx>		; Restore

	 pop	 ebx			; Restore pointer into dynalink table

; Advance to next symbol

	 lea	 ebx,[ebx+4]		; Bump to next entry

	 cmp	 [esi].ELO,0		; Izit the sentinel?
	 jnz	 IS_NEXT_SYM		; Get next dynalink address

; Advance to next VxD

IS_LOOP_DEVICE:
	 add	 edx,(type DEVSVC_STR)	; Bump to next entry

	 jmp	 IS_NEXT_DEVICE 	; Process next VxD

IS_XDEVICE:
	 clc				; Normal return indicator

	 jmp	 short IS_XIT		; Rejoin common exit code

IS_STC:
	 stc				; Error indicator

IS_XIT:
	 popad			; Restore caller's registers

	 ret			; Return to caller

EndProc  INIT_SYMBOLS		; End INIT_SYMBOLS procedure


BeginProc SYMTRANS		; Translate the symbols
COMMENT|

	Translate the symbols

|

	 pushad 		; Save caller's registers

	 cmp	 SWATINT67_VEC.FOFF,0 ; Does 386SWAT.LOD support symbols?
	 je	 SYMTRANS_STC	; Skip the whole thing if not

; Search for a public symbol in SWATVXD_IGROUP

	 lea	 esi,SRCH_SGI	; DS:ESI ==> len, search string
	 mov	 ax,(@VCPI shl 8) or @VCPI_DBGSYM ; Debugger symbol functions
	 mov	 bl,@DBGSYM_SRCH ; Search for symbol
	 pushfd 		; Simulate interrupt
	 cli			; ...
	 call	 SWATINT67_VEC	; Call SWAT's VCPI handler
				; AH =	0 if OK
				; SI =	group
				; CX =	segment/selector
				; EDI = offset
				; DX =	flags
	 or	 ah,ah		; Did we find the symbol?
	 jnz	 SYMTRANS_STC	; We can't translate symbols we don't have

	 mov	 dx,si		; Save the group #

; Translate the SWATVXD_IGROUP symbols

	 call	 SWATVXD_GET_IGROUP ; Get address of SWATVXD_GET_IGROUP in EAX
	 lea	 esi,SWATVXD_GET_IGROUP ; Offset of label within _IGROUP
	 sub	 eax,esi	; Form linear address of base of _IGROUP

	 lea	 esi,SYMTRANSTR ; DS:ESI ==> SYMTRAN_STR
	 mov	 [esi].SYMTRAN_OSEL,cx	; Selector
	 mov	 [esi].SYMTRAN_OGRP,dx	; SWAT_IGROUP
	 mov	 [esi].SYMTRAN_NFLAG,0
	 mov	 [esi].SYMTRAN_NSEL,cx	; Selector
	 mov	 [esi].SYMTRAN_NBASE,eax ; Base of segment

	 mov	 ax,(@VCPI shl 8) or @VCPI_DBGSYM ; Debugger symbol functions
	 mov	 bl,@DBGSYM_TRANS ; Translate symbols
	 pushfd 		; Simulate interrupt
	 cli			; ...
	 call	 SWATINT67_VEC	; Call SWAT's VCPI handler

; Search for a public symbol in SWATVXD_LGROUP

	 lea	 esi,SRCH_SGL	; DS:ESI ==> len, search string
	 mov	 ax,(@VCPI shl 8) or @VCPI_DBGSYM ; Debugger symbol functions
	 mov	 bl,@DBGSYM_SRCH ; Search for symbol
	 pushfd 		; Simulate interrupt
	 cli			; ...
	 call	 SWATINT67_VEC	; Call SWAT's VCPI handler
				; AH =	0 if OK
				; SI =	group
				; CX =	segment/selector
				; EDI = offset
				; DX =	flags
	 or	 ah,ah		; Did we find the symbol?
	 jnz	 SYMTRANS_XIT	; Don't translate symbols we don't have

	 mov	 dx,si		; Save the group #

; Translate the SWATVXD_LGROUP symbols

	 call	 SWATVXD_GET_LGROUP ; Get address of SWATVXD_GET_LGROUP in EAX
	 lea	 esi,SWATVXD_GET_LGROUP ; Offset of label within _LGROUP
	 sub	 eax,esi	; Form linear address of base of _LGROUP

	 lea	 esi,SYMTRANSTR ; DS:ESI ==> SYMTRAN_STR
	 mov	 [esi].SYMTRAN_OSEL,cx	; Selector
	 mov	 [esi].SYMTRAN_OGRP,dx	; SWATVXD_LGROUP
	 mov	 [esi].SYMTRAN_NFLAG,0
	 mov	 [esi].SYMTRAN_NSEL,cx	; Selector
	 mov	 [esi].SYMTRAN_NBASE,eax ; Base of segment

	 mov	 ax,(@VCPI shl 8) or @VCPI_DBGSYM ; Debugger symbol functions
	 mov	 bl,@DBGSYM_TRANS ; Translate symbols
	 pushfd 		; Simulate interrupt
	 cli			; ...
	 call	 SWATINT67_VEC	; Call SWAT's VCPI handler

; Process guest symbols in SSF file
	 lea	 edx,STR_LOADHI 	; EDX ==> default string 'LoadHi',0
	 lea	 esi,STR_386SWAT	; ==> [386SWAT] section of SYSTEM.INI
	 mov	 edi,OFFSET32 STR_SSFPREFIX ; ==> "SSFPrefix"
	 VMMcall Get_Profile_String	; EDX ==> string from SYSTEM.INI

; Fill in STR_GUEST
	 mov	 esi,edx		; ESI ==> SYSTEM.INI string
	 lea	 edi,STR_GUEST		; ESI ==> buffer
	 mov	 ecx,8			; Maximum name length
@@:
	 lodsb				; Get next character
	 or	 al,al			; Izit the terminating NULL?
	 jz	 short @F		; Exit loop if so
	 stosb				; Copy to device name buffer
	 loopnz  @B			; Go back for more if not
@@:
	 mov	 al,' '                 ; Blank for padding
     rep stosb				; Fill the remaining spaces

	 sub	 al,al			; Ensure it's terminated
	 stosb				; ...

; Fill in STR_GUESTDDB
	 mov	 esi,edx		; ESI ==> SYSTEM.INI string
	 lea	 edi,SRCH_GUESTDDB+1	; ESI ==> DDB name buffer
@@:
	 lodsb				; Get next character
	 stosb				; Copy to buffer
	 or	 al,al			; Izit the terminating NULL?
	 loopnz  @B			; Go back for more if not

	 mov	 [edi-1].EDD,'BDD_'     ; Tack on "_DDB"
	 mov	 [edi-1+4].LO,0 	; Tack on terminating NUL

	 sub	 edi,OFFSET32 SRCH_GUESTDDB+1+1-4 ; Calculate length
	 mov	 eax,edi		; Copy length to byte-addressible reg
	 mov	 SRCH_GUESTDDB,al	; Save length in PASCAL string

; Fill in STR_GUESTCONTROL
	 mov	 esi,edx		; ESI ==> SYSTEM.INI string
	 lea	 edi,SRCH_GUESTCONTROL+1 ; ESI ==> DDB name buffer
@@:
	 lodsb				; Get next character
	 stosb				; Copy to buffer
	 or	 al,al			; Izit the terminating NULL?
	 loopnz  @B			; Go back for more if not

	 mov	 [edi-1].EDD,'noC_'     ; Tack on "_Con"
	 mov	 [edi-1+4].EDD,'lort'   ; Tack on "trol"
	 mov	 [edi-1+4+4].LO,0	; Tack on terminating NUL

	 sub	 edi,OFFSET32 SRCH_GUESTCONTROL+1+1-8 ; Calculate length
	 mov	 eax,edi		; Copy length to byte-addressible reg
	 mov	 SRCH_GUESTCONTROL,al	; Save length in PASCAL string

; Search for a public symbol in _LGROUP
	 lea	 esi,STR_GUEST		; ESI ==> 8-char blank-padded VxD name
	 call	 FIND_DEVICE		; Find VxD
					; If carry clear, EDX ==> DDB for VxD
	 jc	 SYMTRANS_XIT		; Don't translate symbols we don't have

	 mov	 SYMBOL_OFF,edx 	; Save untranslated offset

	 lea	 esi,SRCH_GUESTDDB	; DS:ESI ==> len, search string
	 mov	 ax,(@VCPI shl 8) or @VCPI_DBGSYM ; Debugger symbol functions
	 mov	 bl,@DBGSYM_SRCH ; Search for symbol
	 pushfd 		; Simulate interrupt
	 cli			; ...
	 call	 SWATINT67_VEC	; Call SWAT's VCPI handler
				; AH =	0 if OK
				; SI =	group
				; CX =	segment/selector
				; EDI = offset
				; DX =	flags
	 or	 ah,ah		; Did we find the symbol?
	 jnz	 SYMTRANS_XIT	; Don't translate symbols we don't have

	 mov	 dx,si		; Save the group #

; Translate the _LGROUP symbols
	 mov	 eax,SYMBOL_OFF 	; EAX ==> _DDB
	 sub	 eax,edi		; Less the untranslated base
					; EAX is base of _LGROUP

	 lea	 esi,SYMTRANSTR 	; DS:ESI ==> SYMTRAN_STR
	 mov	 [esi].SYMTRAN_OSEL,cx	; Selector
	 mov	 [esi].SYMTRAN_OGRP,dx	; _LGROUP
	 mov	 [esi].SYMTRAN_NFLAG,0
	 mov	 [esi].SYMTRAN_NSEL,cx	; Selector
	 mov	 [esi].SYMTRAN_NBASE,eax ; Base of segment

	 mov	 ax,(@VCPI shl 8) or @VCPI_DBGSYM ; Debugger symbol functions
	 mov	 bl,@DBGSYM_TRANS	; Translate symbols
	 pushfd 			; Simulate interrupt
	 cli				; ...
	 call	 SWATINT67_VEC		; Call SWAT's VCPI handler

; Find address of SYS_CRITICAL_INIT by examining the code in _LGROUP
; Search for a public symbol in _IGROUP

	 lea	 esi,SRCH_GUESTCONTROL	; DS:ESI ==> len, search string
	 mov	 ax,(@VCPI shl 8) or @VCPI_DBGSYM ; Debugger symbol functions
	 mov	 bl,@DBGSYM_SRCH ; Search for symbol
	 pushfd 		; Simulate interrupt
	 cli			; ...
	 call	 SWATINT67_VEC	; Call SWAT's VCPI handler
				; AH =	0 if OK
				; SI =	group
				; CX =	segment/selector
				; EDI = offset
				; DX =	flags
	 or	 ah,ah		; Did we find the symbol?
	 jnz	 short SYMTRANS_STC ; We can't translate symbols we don't have

; EDI ==> _Control
; Do a quick and dirty check on the expected code

	 cmp	 [edi].ELO,0E860h	; Izit PUSHAD / CALL Control_Call_Hook
	 jne	 short SYMTRANS_STC	; Don't translate if it doesn't match

	 mov	 eax,[edi+2]	; Pick up offset in CALL Control_Call_hook
	 lea	 eax,[eax+edi+6] ; Plus the EIP after the CALL

COMMENT|

    EAX ==> Control_Call_Hook

    Do a quick and dirty check on the expected code
    The Control_Call_Hook code check EAX against a known upper limit and then
    JMPs via a list of pointers.

		cmp	eax,VMAX_CALL_LAST
		jae	short @F

		jmp	VMAX_CALL_PROCS[eax*4]
	@@:

|

	 cmp	 [eax].EDD,730DF883h	; Izit CMP EAX,+0D / JNC ...
	 jne	 short SYMTRANS_STC	; Don't translate if it doesn't match

	 mov	 eax,[eax+8]		; Pick up offset of jump table
	 mov	 eax,[eax]		; Sys_Critical_Init is first in the list

	 mov	 SYMBOL_OFF,eax 	; Save offset of VMAX_SYS_CRITICAL_INIT

; Search for a public symbol in LoadHi_LGROUP

	 lea	 esi,SRCH_SCI	; DS:ESI ==> len, search string
	 mov	 ax,(@VCPI shl 8) or @VCPI_DBGSYM ; Debugger symbol functions
	 mov	 bl,@DBGSYM_SRCH ; Search for symbol
	 pushfd 		; Simulate interrupt
	 cli			; ...
	 call	 SWATINT67_VEC	; Call SWAT's VCPI handler
				; AH =	0 if OK
				; SI =	group
				; CX =	segment/selector
				; EDI = offset
				; DX =	flags
	 or	 ah,ah		; Did we find the symbol?
	 jnz	 short SYMTRANS_STC ; We can't translate symbols we don't have

	 mov	 dx,si		; Save the group #

; Translate the LoadHi_IGROUP symbols

	 mov	 eax,SYMBOL_OFF ; EAX ==> SYS_CRITICAL_INIT

	 lea	 esi,SYMTRANSTR ; DS:ESI ==> SYMTRAN_STR
	 mov	 [esi].SYMTRAN_OSEL,cx	; Selector
	 mov	 [esi].SYMTRAN_OGRP,dx	; LoadHi_IGROUP
	 mov	 [esi].SYMTRAN_NFLAG,0
	 mov	 [esi].SYMTRAN_NSEL,cx	; Selector
	 mov	 [esi].SYMTRAN_NBASE,eax ; Base of segment

	 mov	 ax,(@VCPI shl 8) or @VCPI_DBGSYM ; Debugger symbol functions
	 mov	 bl,@DBGSYM_TRANS ; Translate symbols
	 pushfd 		; Simulate interrupt
	 cli			; ...
	 call	 SWATINT67_VEC	; Call SWAT's VCPI handler

	 clc			; Normal return indicator

	 jmp	 short SYMTRANS_XIT ; Rejoin common code

SYMTRANS_STC:
	 stc			; Error indicator

SYMTRANS_XIT:
	 popad			; Restore caller's registers

	 ret			; Return to caller

EndProc  SYMTRANS		; End SYMTRANS procedure

BeginProc SWATVXD_GET_IGROUP	; Returns its own address in EAX
COMMENT|

	Returns its own linear address in EAX.

|

	 call	 SWATVXD_GET_IGROUP_L ; Call next instruction to push EIP

	 public  SWATVXD_GET_IGROUP_L
SWATVXD_GET_IGROUP_L:
	 pop	 eax		; Get linear address into EAX
	 sub	 eax,SWATVXD_GET_IGROUP_L-SWATVXD_GET_IGROUP

	 ret			; Return to caller

EndProc  SWATVXD_GET_IGROUP	; End SWATVXD_GET_IGROUP procedure

BeginProc WINVARS			; Send address of VMM variables to SWAT
COMMENT|

	Send addresses of WIN386 internal variables to 386SWAT.LOD

|

	cmp	SWATINT67_VEC.FSEL,0	; Does 386SWAT support symbols?
	je	WINVARS_EXIT		; Skip the whole thing if not

	mov	edx,SWATINFO_LIN	; Linear address of SWATINFO
	cmp	[edx].SWTINF_VER,4	; Support @VCPI_DBGWINVARS?
	jb	WINVARS_EXIT		; Skip the whole thing if not

	cmp	WIN3_VERSION,0400h	; Izit 4.00 or later?
	jb	short WINVARS_XCUR_0400 ; Jump if not

	call	Lcl_Get_Cur_VM_Handle	; Fill in INT 20h
	lea	edx,Lcl_Get_Cur_VM_Handle ; Get offset of code

	jmp	short WINVARS_CUR1	; Join common code

WINVARS_XCUR_0400:

; Get address of the Get_Cur_VM_Handle VMM service

	 mov	 eax,Get_Cur_VM_Handle	; Service to steal
	 mov	 esi,OFFSET32 HOOKPROC	; Address of replacement
	 VMMcall Hook_Device_Service	; Steal the service
	 jc	 short WINVARS_XCUR	; Jump if not

	 mov	 edx,esi		; Save address of service

	 mov	 eax,Get_Cur_VM_Handle	; Service to replace
	 VMMcall Hook_Device_Service	; Replace the service
;;;;;;;; jc	 short WINVARS_XCUR	; Jump if not

; Sanity check the code

WINVARS_CUR1:
	 cmp	 [edx].ELO,1D8Bh	; Is it 'MOV EBX,[Cur_VM_Handle]'?
	 jne	 short WINVARS_XCUR	; Jump if not

; Pick up the address and send it up to 386SWAT.LOD

	 mov	 edx,[edx+2]		; Offset of Cur_VM_Handle
	 mov	 cx,ds			; Selector of Cur_VM_Handle

	 mov	 ax,(@VCPI shl 8) or @VCPI_DBGWINVARS ; Send variable addresses
	 mov	 bl,@DBGWINVARS_CURVM	; Pass address of Cur_VM_Handle

	 pushfd 			; Simulate interrupt
	 cli				; ...
	 call	 SWATINT67_VEC		; Call SWAT's VCPI handler
WINVARS_XCUR:
	cmp	WIN3_VERSION,0400h	; Izit 4.00 or later?
	jb	short WINVARS_XSYS_0400 ; Jump if not

	call	Lcl_Get_Sys_VM_Handle	; Fill in INT 20h
	lea	edx,Lcl_Get_Sys_VM_Handle ; Get offset of code

	jmp	short WINVARS_SYS1	; Join common code

WINVARS_XSYS_0400:

; Get address of the Get_Sys_VM_Handle VMM service

	 mov	 eax,Get_Sys_VM_Handle	; Service to steal
	 mov	 esi,OFFSET32 HOOKPROC	; Address of replacement
	 VMMcall Hook_Device_Service	; Steal the service
	 jc	 short WINVARS_XSYS	; Jump if not

	 mov	 edx,esi		; Save address of service

	 mov	 eax,Get_Sys_VM_Handle	; Service to replace
	 VMMcall Hook_Device_Service	; Replace the service
;;;;;;;; jc	 short WINVARS_XSYS	; Jump if not

; Sanity check the code

WINVARS_SYS1:
	 cmp	 [edx].ELO,1D8Bh	; Is it 'MOV EBX,[Sys_VM_Handle]'?
	 jne	 short WINVARS_XSYS	; Jump if not

; Pick up the address and send it up to 386SWAT.LOD

	 mov	 edx,[edx+2]		; Offset of Sys_VM_Handle
	 mov	 cx,ds			; Selector of Sys_VM_Handle

	 mov	 ax,(@VCPI shl 8) or @VCPI_DBGWINVARS ; Send variable addresses
	 mov	 bl,@DBGWINVARS_SYSVM	; Pass address of Sys_VM_Handle

	 pushfd 			; Simulate interrupt
	 cli				; ...
	 call	 SWATINT67_VEC		; Call SWAT's VCPI handler
WINVARS_XSYS:
;;;;;;;; jmp	 short WINVARS_EXIT	; Rejoin common code

WINVARS_EXIT:
	 ret				; Return to caller

EndProc  WINVARS			; End WINVARS procedure

BeginProc HOOKPROC			; Dummy procedure for double hook trick
COMMENT|

	Dummy procedure for double hook trick.
	This procedure is never called.

|

	 int	 3			; Call the debugger

	 ret				; Return to caller

EndProc  HOOKPROC			; End HOOKPROC procedure

VxD_ICODE_ENDS			; End _ICODE segment

VxD_CODE_SEG			; Begin _CODE segment

BeginProc SWATVXD_GET_LGROUP	; Returns its own address in EAX
COMMENT|

	Returns its own linear address in EAX.

|

	 call	 SWATVXD_GET_LGROUP_L ; Call next instruction to push EIP

	 public  SWATVXD_GET_LGROUP_L
SWATVXD_GET_LGROUP_L:
	 pop	 eax		; Get linear address into EAX
	 sub	 eax,SWATVXD_GET_LGROUP_L-SWATVXD_GET_LGROUP

	 ret			; Return to caller

EndProc  SWATVXD_GET_LGROUP	; End SWATVXD_GET_LGROUP procedure

VxD_CODE_ENDS			; End _CODE segment

VxD_IDATA_SEG			; Begin _IDATA segment

	 public  DEVICE_SERVICE_TAB
DEVICE_SERVICE_TAB label tbyte
     DEVSVC_STR <VMM_Device_ID, OFFSET32 VMM_NAME, OFFSET32 VMM_SYMS>
     DEVSVC_STR <VPICD_Device_ID, 0, OFFSET32 VPICD_SYMS>
     DEVSVC_STR <VDMAD_Device_ID, 0, OFFSET32 VDMAD_SYMS>
     DEVSVC_STR <VTD_Device_ID, 0, OFFSET32 VTD_SYMS>
     DEVSVC_STR <V86MMGR_Device_ID, 0, OFFSET32 V86MMGR_SYMS>
     DEVSVC_STR <PageSwap_Device_ID, 0, OFFSET32 PAGESWAP_SYMS>
     DEVSVC_STR <VDD_Device_ID, 0, OFFSET32 VDD_SYMS>
     DEVSVC_STR <VSD_Device_ID, 0, OFFSET32 VSD_SYMS>
     DEVSVC_STR <VMD_Device_ID, 0, OFFSET32 VMD_SYMS>
     DEVSVC_STR <VKD_Device_ID, 0, OFFSET32 VKD_SYMS>
     DEVSVC_STR <VCD_Device_ID, 0, OFFSET32 VCD_SYMS>
     DEVSVC_STR <BlockDev_Device_ID, 0, OFFSET32 BLOCKDEV_SYMS>
     DEVSVC_STR <EBIOS_Device_ID, 0, OFFSET32 EBIOS_SYMS>
     DEVSVC_STR <VNETBIOS_Device_ID, 0, OFFSET32 VNETBIOS_SYMS>
     DEVSVC_STR <DOSMGR_Device_ID, 0, OFFSET32 DOSMGR_SYMS>
     DEVSVC_STR <SHELL_Device_ID, 0, OFFSET32 SHELL_SYMS>
     DEVSVC_STR <VMPoll_Device_ID, 0, OFFSET32 VMPOLL_SYMS>
     DEVSVC_STR <DOSNET_Device_ID, 0, OFFSET32 DOSNET_SYMS>
     DEVSVC_STR <VDD2_Device_ID, 0, OFFSET32 VDD2_SYMS>
     DEVSVC_STR <WINDEBUG_Device_ID, 0, OFFSET32 WINDEBUG_SYMS>
     DEVSVC_STR <TSRLoad_Device_ID, 0, OFFSET32 TSRLOAD_SYMS>
     DEVSVC_STR <BiosHook_Device_ID, 0, OFFSET32 BIOSHOOK_SYMS>
     DEVSVC_STR <Int13_Device_ID, 0, OFFSET32 INT13_SYMS>
     DEVSVC_STR <PageFile_Device_ID, 0, OFFSET32 PAGEFILE_SYMS>
     DEVSVC_STR <SCSI_Device_ID, 0, OFFSET32 SCSI_SYMS>
     DEVSVC_STR <MCA_POS_Device_ID, 0, OFFSET32 MCA_POS_SYMS>
     DEVSVC_STR <SCSIFD_Device_ID, 0, OFFSET32 SCSIFD_SYMS>
     DEVSVC_STR <VPEND_Device_ID, 0, OFFSET32 VPEND_SYMS>
     DEVSVC_STR <APM_Device_ID, 0, OFFSET32 APM_SYMS>

     DEVSVC_STR <SERVER_Device_ID, 0, OFFSET32 SERVER_SYMS>

     DEVSVC_STR <PM_BIOS_Device_ID, 0, OFFSET32 PM_BIOS_SYMS>

     DEVSVC_STR <Undefined_Device_ID, 0, 0> ; Sentinel

	 public  VMM_NAME
VMM_NAME	 db	 'VMM', 0       ; Segment name prefix

	 public  VMM_SYMS
VMM_SYMS	 label	byte		; Start of VMM services
	 db	 'Get_VMM_Version', 0
	 db	 'Get_Cur_VM_Handle', 0
	 db	 'Test_Cur_VM_Handle', 0
	 db	 'Get_Sys_VM_Handle', 0
	 db	 'Test_Sys_VM_Handle', 0
	 db	 'Validate_VM_Handle', 0
	 db	 'Get_VMM_Reenter_Count', 0
	 db	 'Begin_Reentrant_Execution', 0
	 db	 'End_Reentrant_Execution', 0
	 db	 'Install_V86_Break_Point', 0
	 db	 'Remove_V86_Break_Point', 0
	 db	 'Allocate_V86_Call_Back', 0
	 db	 'Allocate_PM_Call_Back', 0
	 db	 'Call_When_VM_Returns', 0
	 db	 'Schedule_Global_Event', 0
	 db	 'Schedule_VM_Event', 0
	 db	 'Call_Global_Event', 0
	 db	 'Call_VM_Event', 0
	 db	 'Cancel_Global_Event', 0
	 db	 'Cancel_VM_Event', 0
	 db	 'Call_Priority_VM_Event', 0
	 db	 'Cancel_Priority_VM_Event', 0
	 db	 'Get_NMI_Handler_Addr', 0
	 db	 'Set_NMI_Handler_Addr', 0
	 db	 'Hook_NMI_Event', 0
	 db	 'Call_When_VM_Ints_Enabled', 0
	 db	 'Enable_VM_Ints', 0
	 db	 'Disable_VM_Ints', 0
	 db	 'Map_Flat', 0
	 db	 'Map_Lin_To_VM_Addr', 0
	 db	 'Adjust_Exec_Priority', 0
	 db	 'Begin_Critical_Section', 0
	 db	 'End_Critical_Section', 0
	 db	 'End_Crit_And_Suspend', 0
	 db	 'Claim_Critical_Section', 0
	 db	 'Release_Critical_Section', 0
	 db	 'Call_When_Not_Critical', 0
	 db	 'Create_Semaphore', 0
	 db	 'Destroy_Semaphore', 0
	 db	 'Wait_Semaphore', 0
	 db	 'Signal_Semaphore', 0
	 db	 'Get_Crit_Section_Status', 0
	 db	 'Call_When_Task_Switched', 0
	 db	 'Suspend_VM', 0
	 db	 'Resume_VM', 0
	 db	 'No_Fail_Resume_VM', 0
	 db	 'Nuke_VM', 0
	 db	 'Crash_Cur_VM', 0
	 db	 'Get_Execution_Focus', 0
	 db	 'Set_Execution_Focus', 0
	 db	 'Get_Time_Slice_Priority', 0
	 db	 'Set_Time_Slice_Priority', 0
	 db	 'Get_Time_Slice_Granularity', 0
	 db	 'Set_Time_Slice_Granularity', 0
	 db	 'Get_Time_Slice_Info', 0
	 db	 'Adjust_Execution_Time', 0
	 db	 'Release_Time_Slice', 0
	 db	 'Wake_Up_VM', 0
	 db	 'Call_When_Idle', 0
	 db	 'Get_Next_VM_Handle', 0
	 db	 'Set_Global_Time_Out', 0
	 db	 'Set_VM_Time_Out', 0
	 db	 'Cancel_Time_Out', 0
	 db	 'Get_System_Time', 0
	 db	 'Get_VM_Exec_Time', 0
	 db	 'Hook_V86_Int_Chain', 0
	 db	 'Get_V86_Int_Vector', 0
	 db	 'Set_V86_Int_Vector', 0
	 db	 'Get_PM_Int_Vector', 0
	 db	 'Set_PM_Int_Vector', 0
	 db	 'Simulate_Int', 0
	 db	 'Simulate_Iret', 0
	 db	 'Simulate_Far_Call', 0
	 db	 'Simulate_Far_Jmp', 0
	 db	 'Simulate_Far_Ret', 0
	 db	 'Simulate_Far_Ret_N', 0
	 db	 'Build_Int_Stack_Frame', 0
	 db	 'Simulate_Push', 0
	 db	 'Simulate_Pop', 0
	 db	 '_HeapAllocate', 0
	 db	 '_HeapReAllocate', 0
	 db	 '_HeapFree', 0
	 db	 '_HeapGetSize', 0
	 db	 '_PageAllocate', 0
	 db	 '_PageReAllocate', 0
	 db	 '_PageFree', 0
	 db	 '_PageLock', 0
	 db	 '_PageUnLock', 0
	 db	 '_PageGetSizeAddr', 0
	 db	 '_PageGetAllocInfo', 0
	 db	 '_GetFreePageCount', 0
	 db	 '_GetSysPageCount', 0
	 db	 '_GetVMPgCount', 0
	 db	 '_MapIntoV86', 0
	 db	 '_PhysIntoV86', 0
	 db	 '_TestGlobalV86Mem', 0
	 db	 '_ModifyPageBits', 0
	 db	 '_CopyPageTable', 0
	 db	 '_LinMapIntoV86', 0
	 db	 '_LinPageLock', 0
	 db	 '_LinPageUnLock', 0
	 db	 '_SetResetV86Pageable', 0
	 db	 '_GetV86PageableArray', 0
	 db	 '_PageCheckLinRange', 0
	 db	 '_PageOutDirtyPages', 0
	 db	 '_PageDiscardPages', 0
	 db	 '_GetNulPageHandle', 0
	 db	 '_GetFirstV86Page', 0
	 db	 '_MapPhysToLinear', 0
	 db	 '_GetAppFlatDSAlias', 0
	 db	 '_SelectorMapFlat', 0
	 db	 '_GetDemandPageInfo', 0
	 db	 '_GetSetPageOutCount', 0
	 db	 'Hook_V86_Page', 0
	 db	 '_Assign_Device_V86_Pages', 0
	 db	 '_DeAssign_Device_V86_Pages', 0
	 db	 '_Get_Device_V86_Pages_Array', 0
	 db	 'MMGR_SetNULPageAddr', 0
	 db	 '_Allocate_GDT_Selector', 0
	 db	 '_Free_GDT_Selector', 0
	 db	 '_Allocate_LDT_Selector', 0
	 db	 '_Free_LDT_Selector', 0
	 db	 '_BuildDescriptorDWORDs', 0
	 db	 '_GetDescriptor', 0
	 db	 '_SetDescriptor', 0
	 db	 '_MMGR_Toggle_HMA', 0
	 db	 'Get_Fault_Hook_Addrs', 0
	 db	 'Hook_V86_Fault', 0
	 db	 'Hook_PM_Fault', 0
	 db	 'Hook_VMM_Fault', 0
	 db	 'Begin_Nest_V86_Exec', 0
	 db	 'Begin_Nest_Exec', 0
	 db	 'Exec_Int', 0
	 db	 'Resume_Exec', 0
	 db	 'End_Nest_Exec', 0
	 db	 'Allocate_PM_App_CB_Area', 0
	 db	 'Get_Cur_PM_App_CB', 0
	 db	 'Set_V86_Exec_Mode', 0
	 db	 'Set_PM_Exec_Mode', 0
	 db	 'Begin_Use_Locked_PM_Stack', 0
	 db	 'End_Use_Locked_PM_Stack', 0
	 db	 'Save_Client_State', 0
	 db	 'Restore_Client_State', 0
	 db	 'Exec_VxD_Int', 0
	 db	 'Hook_Device_Service', 0
	 db	 'Hook_Device_V86_API', 0
	 db	 'Hook_Device_PM_API', 0
	 db	 'System_Control', 0
	 db	 'Simulate_IO', 0
	 db	 'Install_Mult_IO_Handlers', 0
	 db	 'Install_IO_Handler', 0
	 db	 'Enable_Global_Trapping', 0
	 db	 'Enable_Local_Trapping', 0
	 db	 'Disable_Global_Trapping', 0
	 db	 'Disable_Local_Trapping', 0
	 db	 'List_Create', 0
	 db	 'List_Destroy', 0
	 db	 'List_Allocate', 0
	 db	 'List_Attach', 0
	 db	 'List_Attach_Tail', 0
	 db	 'List_Insert', 0
	 db	 'List_Remove', 0
	 db	 'List_Deallocate', 0
	 db	 'List_Get_First', 0
	 db	 'List_Get_Next', 0
	 db	 'List_Remove_First', 0
	 db	 '_AddInstanceItem', 0
	 db	 '_Allocate_Device_CB_Area', 0
	 db	 '_Allocate_Global_V86_Data_Area', 0
	 db	 '_Allocate_Temp_V86_Data_Area', 0
	 db	 '_Free_Temp_V86_Data_Area', 0
	 db	 'Get_Profile_Decimal_Int', 0
	 db	 'Convert_Decimal_String', 0
	 db	 'Get_Profile_Fixed_Point', 0
	 db	 'Convert_Fixed_Point_String', 0
	 db	 'Get_Profile_Hex_Int', 0
	 db	 'Convert_Hex_String', 0
	 db	 'Get_Profile_Boolean', 0
	 db	 'Convert_Boolean_String', 0
	 db	 'Get_Profile_String', 0
	 db	 'Get_Next_Profile_String', 0
	 db	 'Get_Environment_String', 0
	 db	 'Get_Exec_Path', 0
	 db	 'Get_Config_Directory', 0
	 db	 'OpenFile', 0
	 db	 'Get_PSP_Segment', 0
	 db	 'GetDOSVectors', 0
	 db	 'Get_Machine_Info', 0
	 db	 'GetSet_HMA_Info', 0
	 db	 'Set_System_Exit_Code', 0
	 db	 'Fatal_Error_Handler', 0
	 db	 'Fatal_Memory_Error', 0
	 db	 'Update_System_Clock', 0
	 db	 'Test_Debug_Installed', 0
	 db	 'Out_Debug_String', 0
	 db	 'Out_Debug_Chr', 0
	 db	 'In_Debug_Chr', 0
	 db	 'Debug_Convert_Hex_Binary', 0
	 db	 'Debug_Convert_Hex_Decimal', 0
	 db	 'Debug_Test_Valid_Handle', 0
	 db	 'Validate_Client_Ptr', 0
	 db	 'Test_Reenter', 0
	 db	 'Queue_Debug_String', 0
	 db	 'Log_Proc_Call', 0
	 db	 'Debug_Test_Cur_VM', 0
	 db	 'Get_PM_Int_Type', 0
	 db	 'Set_PM_Int_Type', 0
	 db	 'Get_Last_Updated_System_Time', 0
	 db	 'Get_Last_Updated_VM_Exec_Time', 0
	 db	 'Test_DBCS_Lead_Byte', 0
; End of 3.0 VMM services
	 db	 '_AddFreePhysPage', 0
	 db	 '_PageResetHandlePAddr', 0
	 db	 '_SetLastV86Page', 0
	 db	 '_GetLastV86Page', 0
	 db	 '_MapFreePhysReg', 0
	 db	 '_UnmapFreePhysReg', 0
	 db	 '_XchgFreePhysReg', 0
	 db	 '_SetFreePhysRegCalBk', 0
	 db	 'Get_Next_Arena', 0
	 db	 'Get_Name_Of_Ugly_TSR', 0
	 db	 'Get_Debug_Options', 0
	 db	 'Set_Physical_HMA_Alias', 0
	 db	 '_GetGlblRng0V86IntBase', 0
	 db	 '_Add_Global_V86_Data_Area', 0
	 db	 'GetSetDetailedVMError', 0
	 db	 'Is_Debug_Chr', 0
	 db	 'Clear_Mono_Screen', 0
	 db	 'Out_Mono_Chr', 0
	 db	 'Out_Mono_String', 0
	 db	 'Set_Mono_Cur_Pos', 0
	 db	 'Get_Mono_Cur_Pos', 0
	 db	 'Get_Mono_Chr', 0
	 db	 'Locate_Byte_In_ROM', 0
	 db	 'Hook_Invalid_Page_Fault', 0
	 db	 'Unhook_Invalid_Page_Fault', 0
	 db	 'Set_Delete_On_Exit_File', 0
	 db	 'Close_VM', 0
	 db	 'Enable_Touch_1st_Meg', 0
	 db	 'Disable_Touch_1st_Meg', 0
	 db	 'Install_Exception_Handler', 0
	 db	 'Remove_Exception_Handler', 0
	 db	 'Get_Crit_Status_No_Block', 0
; End of 3.10 VMM services
	 db	'_GetLastUpdatedThreadExecTime'   ,0
	 db	'_Trace_Out_Service'              ,0
	 db	'_Debug_Out_Service'              ,0
	 db	'_Debug_Flags_Service'            ,0
	 db	'VMMAddImportModuleName'          ,0
	 db	'VMM_Add_DDB'                     ,0
	 db	'VMM_Remove_DDB'                  ,0
	 db	'Test_VM_Ints_Enabled'            ,0
	 db	'_BlockOnID'                      ,0
	 db	'Schedule_Thread_Event'           ,0
	 db	'Cancel_Thread_Event'             ,0
	 db	'Set_Thread_Time_Out'             ,0
	 db	'Set_Async_Time_Out'              ,0
	 db	'_AllocateThreadDataSlot'         ,0
	 db	'_FreeThreadDataSlot'             ,0
	 db	'_CreateMutex'                    ,0
	 db	'_DestroyMutex'                   ,0
	 db	'_GetMutexOwner'                  ,0
	 db	'Call_When_Thread_Switched'       ,0
	 db	'VMMCreateThread'                 ,0
	 db	'_GetThreadExecTime'              ,0
	 db	'VMMTerminateThread'              ,0
	 db	'Get_Cur_Thread_Handle'           ,0
	 db	'Test_Cur_Thread_Handle'          ,0
	 db	'Get_Sys_Thread_Handle'           ,0
	 db	'Test_Sys_Thread_Handle'          ,0
	 db	'Validate_Thread_Handle'          ,0
	 db	'Get_Initial_Thread_Handle'       ,0
	 db	'Test_Initial_Thread_Handle'      ,0
	 db	'Debug_Test_Valid_Thread_Handle'  ,0
	 db	'Debug_Test_Cur_Thread'           ,0
	 db	'VMM_GetSystemInitState'          ,0
	 db	'Cancel_Call_When_Thread_Switched',0
	 db	'Get_Next_Thread_Handle'          ,0
	 db	'Adjust_Thread_Exec_Priority'     ,0
	 db	'_Deallocate_Device_CB_Area'      ,0
	 db	'Remove_IO_Handler'               ,0
	 db	'Remove_Mult_IO_Handlers'         ,0
	 db	'Unhook_V86_Int_Chain'            ,0
	 db	'Unhook_V86_Fault'                ,0
	 db	'Unhook_PM_Fault'                 ,0
	 db	'Unhook_VMM_Fault'                ,0
	 db	'Unhook_Device_Service'           ,0
	 db	'_PageReserve'                    ,0
	 db	'_PageCommit'                     ,0
	 db	'_PageDecommit'                   ,0
	 db	'_PagerRegister'                  ,0
	 db	'_PagerQuery'                     ,0
	 db	'_PagerDeregister'                ,0
	 db	'_ContextCreate'                  ,0
	 db	'_ContextDestroy'                 ,0
	 db	'_PageAttach'                     ,0
	 db	'_PageFlush'                      ,0
	 db	'_SignalID'                       ,0
	 db	'_PageCommitPhys'                 ,0
	 db	'_Register_Win32_Services'        ,0
	 db	'Cancel_Call_When_Not_Critical'   ,0
	 db	'Cancel_Call_When_Idle'           ,0
	 db	'Cancel_Call_When_Task_Switched'  ,0
	 db	'_Debug_Printf_Service'           ,0
	 db	'_EnterMutex'                     ,0
	 db	'_LeaveMutex'                     ,0
	 db	'Simulate_VM_IO'                  ,0
	 db	'Signal_Semaphore_No_Switch'      ,0
	 db	'_ContextSwitch'                  ,0
	 db	'_PageModifyPermissions'          ,0
	 db	'_PageQuery'                      ,0
	 db	'_EnterMustComplete'              ,0
	 db	'_LeaveMustComplete'              ,0
	 db	'_ResumeExecMustComplete'         ,0
	 db	'_GetThreadTerminationStatus'     ,0
	 db	'_GetInstanceInfo'                ,0
	 db	'_ExecIntMustComplete'            ,0
	 db	'_ExecVxDIntMustComplete'         ,0
	 db	'Begin_V86_Serialization'         ,0
	 db	'Unhook_V86_Page'                 ,0
	 db	'VMM_GetVxDLocationList'          ,0
	 db	'VMM_GetDDBList'                  ,0
	 db	'Unhook_NMI_Event'                ,0
	 db	'Get_Instanced_V86_Int_Vector'    ,0
	 db	'Get_Set_Real_DOS_PSP'            ,0
	 db	'Call_Priority_Thread_Event'      ,0
	 db	'Get_System_Time_Address'         ,0
	 db	'Get_Crit_Status_Thread'          ,0
	 db	'Get_DDB'                         ,0
	 db	'Directed_Sys_Control'            ,0
	 db	'_RegOpenKey'                     ,0
	 db	'_RegCloseKey'                    ,0
	 db	'_RegCreateKey'                   ,0
	 db	'_RegDeleteKey'                   ,0
	 db	'_RegEnumKey'                     ,0
	 db	'_RegQueryValue'                  ,0
	 db	'_RegSetValue'                    ,0
	 db	'_RegDeleteValue'                 ,0
	 db	'_RegEnumValue'                   ,0
	 db	'_RegQueryValueEx'                ,0
	 db	'_RegSetValueEx'                  ,0
	 db	'_CallRing3'                      ,0
	 db	'Exec_PM_Int'                     ,0
	 db	'_RegFlushKey'                    ,0
	 db	'_PageCommitContig'               ,0
	 db	'_GetCurrentContext'              ,0
	 db	'_LocalizeSprintf'                ,0
	 db	'_LocalizeStackSprintf'           ,0
	 db	'Call_Restricted_Event'           ,0
	 db	'Cancel_Restricted_Event'         ,0
	 db	'Register_PEF_Provider, VMM_ICODE',0
	 db	'_GetPhysPageInfo'                ,0
	 db	'_RegQueryInfoKey'                ,0
	 db	'MemArb_Reserve_Pages'            ,0
	 db	'Time_Slice_Sys_VM_Idle'          ,0
	 db	'Time_Slice_Sleep'                ,0
	 db	'Boost_With_Decay'                ,0
	 db	'Set_Inversion_Pri'               ,0
	 db	'Reset_Inversion_Pri'             ,0
	 db	'Release_Inversion_Pri'           ,0
	 db	'Get_Thread_Win32_Pri'            ,0
	 db	'Set_Thread_Win32_Pri'            ,0
	 db	'Set_Thread_Static_Boost'         ,0
	 db	'Set_VM_Static_Boost'             ,0
	 db	'Release_Inversion_Pri_ID'        ,0
	 db	'Attach_Thread_To_Group'          ,0
	 db	'Detach_Thread_From_Group'        ,0
	 db	'Set_Group_Static_Boost'          ,0
	 db	'_GetRegistryPath, VMM_ICODE'     ,0
	 db	'_GetRegistryKey'                 ,0
	 db	'Cleanup_Thread_State'            ,0
	 db	'_RegRemapPreDefKey'              ,0
	 db	'End_V86_Serialization'           ,0
	 db	'_Assert_Range'                   ,0
	 db	'_Sprintf'                        ,0
	 db	'_PageChangePager'                ,0
	 db	'_RegCreateDynKey'                ,0
	 db	'_RegQueryMultipleValues'         ,0
	 db	'Boost_Thread_With_VM'            ,0
	 db	'Get_Boot_Flags'                  ,0
	 db	'Set_Boot_Flags'                  ,0
	 db	'_lstrcpyn'                       ,0
	 db	'_lstrlen'                        ,0
	 db	'_lmemcpy'                        ,0
	 db	'_GetVxDName'                     ,0
	 db	'Force_Mutexes_Free'              ,0
	 db	'Restore_Forced_Mutexes'          ,0
	 db	'_AddReclaimableItem'             ,0
	 db	'_SetReclaimableItem'             ,0
	 db	'_EnumReclaimableItem'            ,0
	 db	'Time_Slice_Wake_Sys_VM'          ,0
	 db	'VMM_Replace_Global_Environment'  ,0
	 db	'Begin_Non_Serial_Nest_V86_Exec'  ,0
	 db	'Get_Nest_Exec_Status'            ,0
	 db	'Open_Boot_Log'                   ,0
	 db	'Write_Boot_Log'                  ,0
	 db	'Close_Boot_Log'                  ,0
	 db	'EnableDisable_Boot_Log'          ,0
	 db	'_Call_On_My_Stack'               ,0
	 db	'Get_Inst_V86_Int_Vec_Base'       ,0
	 db	'_lstrcmpi'                       ,0
	 db	'_strupr'                         ,0
	 db	'Log_Fault_Call_Out'              ,0
	 db	'_AtEventTime'                    ,0
; End of 4.00 VMM services
	 dw	 0		; Sentinel

VPICD_SYMS	 label	byte	; Start of VPICD services
	 db	 'VPICD_Get_Version', 0
	 db	 'VPICD_Virtualize_IRQ', 0
	 db	 'VPICD_Set_Int_Request', 0
	 db	 'VPICD_Clear_Int_Request', 0
	 db	 'VPICD_Phys_EOI', 0
	 db	 'VPICD_Get_Complete_Status', 0
	 db	 'VPICD_Get_Status', 0
	 db	 'VPICD_Test_Phys_Request', 0
	 db	 'VPICD_Physically_Mask', 0
	 db	 'VPICD_Physically_Unmask', 0
	 db	 'VPICD_Set_Auto_Masking', 0
	 db	 'VPICD_Get_IRQ_Complete_Status', 0
	 db	 'VPICD_Convert_Handle_To_IRQ', 0
	 db	 'VPICD_Convert_IRQ_To_Int', 0
	 db	 'VPICD_Convert_Int_To_IRQ', 0
	 db	 'VPICD_Call_When_Hw_Int', 0
	 db	 'VPICD_Force_Default_Owner', 0
	 db	 'VPICD_Force_Default_Behavior', 0
	 db	 'VPICD_Auto_Mask_At_Inst_Swap', 0
	 db	 'VPICD_Begin_Inst_Page_Swap', 0
	 db	 'VPICD_End_Inst_Page_Swap', 0
	 dw	 0		; Sentinel

VDMAD_SYMS	 label	byte	; Start of VDMAD services
	 db	 'VDMAD_Get_Version', 0
	 db	 'VDMAD_Virtualize_Channel', 0
	 db	 'VDMAD_Get_Region_Info', 0
	 db	 'VDMAD_Set_Region_Info', 0
	 db	 'VDMAD_Get_Virt_State', 0
	 db	 'VDMAD_Set_Virt_State', 0
	 db	 'VDMAD_Set_Phys_State', 0
	 db	 'VDMAD_Mask_Channel', 0
	 db	 'VDMAD_UnMask_Channel', 0
	 db	 'VDMAD_Lock_DMA_Region', 0
	 db	 'VDMAD_Unlock_DMA_Region', 0
	 db	 'VDMAD_Scatter_Lock', 0
	 db	 'VDMAD_Scatter_Unlock', 0
	 db	 'VDMAD_Reserve_Buffer_Space', 0
	 db	 'VDMAD_Request_Buffer', 0
	 db	 'VDMAD_Release_Buffer', 0
	 db	 'VDMAD_Copy_To_Buffer', 0
	 db	 'VDMAD_Copy_From_Buffer', 0
	 db	 'VDMAD_Default_Handler', 0
	 db	 'VDMAD_Disable_Translation', 0
	 db	 'VDMAD_Enable_Translation', 0
	 db	 'VDMAD_Get_EISA_Adr_Mode', 0
	 db	 'VDMAD_Set_EISA_Adr_Mode', 0
	 db	 'VDMAD_Unlock_DMA_Region_No_Dirty', 0
	 dw	 0		; Sentinel

VTD_SYMS	 label	byte	; Start of VTD services
	 db	 'VTD_Get_Version', 0
	 db	 'VTD_Update_System_Clock', 0
	 db	 'VTD_Get_Interrupt_Period', 0
	 db	 'VTD_Begin_Min_Int_Period', 0
	 db	 'VTD_End_Min_Int_Period', 0
	 db	 'VTD_Disable_Trapping', 0
	 db	 'VTD_Enable_Trapping', 0
	 db	 'VTD_Get_Real_Time', 0
	 dw	 0		; Sentinel

V86MMGR_SYMS	 label	byte	; Start of V86MMGR services
	 db	 'V86MMGR_Get_Version', 0
	 db	 'V86MMGR_Allocate_V86_Pages', 0
	 db	 'V86MMGR_Set_EMS_XMS_Limits', 0
	 db	 'V86MMGR_Get_EMS_XMS_Limits', 0
	 db	 'V86MMGR_Set_Mapping_Info', 0
	 db	 'V86MMGR_Get_Mapping_Info', 0
	 db	 'V86MMGR_Xlat_API', 0
	 db	 'V86MMGR_Load_Client_Ptr', 0
	 db	 'V86MMGR_Allocate_Buffer', 0
	 db	 'V86MMGR_Free_Buffer', 0
	 db	 'V86MMGR_Get_Xlat_Buff_State', 0
	 db	 'V86MMGR_Set_Xlat_Buff_State', 0
	 db	 'V86MMGR_Get_VM_Flat_Sel', 0
	 db	 'V86MMGR_Map_Pages', 0
	 db	 'V86MMGR_Free_Page_Map_Region', 0
; End of 3.0 V86MMGR services
	 db	 'V86MMGR_LocalGlobalReg', 0
	 db	 'V86MMGR_GetPgStatus', 0
	 db	 'V86MMGR_SetLocalA20', 0
	 db	 'V86MMGR_ResetBasePages', 0
	 db	 'V86MMGR_SetAvailMapPgs', 0
	 db	 'V86MMGR_NoUMBInitCalls', 0
	 dw	 0		; Sentinel

PAGESWAP_SYMS	 label	byte	; Start of PAGESWAP services
	 db	 'PageSwap_Get_Version', 0
	 db	 'PageSwap_Test_Create', 0
	 db	 'PageSwap_Create', 0
	 db	 'PageSwap_Destroy', 0
	 db	 'PageSwap_In', 0
	 db	 'PageSwap_Out', 0
	 db	 'PageSwap_Test_IO_Valid', 0
	 dw	 0		; Sentinel

VDD_SYMS	 label	byte	; Start of VDD services
	 db	 'VDD_Get_Version', 0
	 db	 'VDD_PIF_State', 0
	 db	 'VDD_Get_GrabRtn', 0
	 db	 'VDD_Hide_Cursor', 0
	 db	 'VDD_Set_VMType', 0
	 db	 'VDD_Get_ModTime', 0
	 db	 'VDD_Set_HCurTrk', 0
	 db	 'VDD_Msg_ClrScrn', 0
	 db	 'VDD_Msg_ForColor', 0
	 db	 'VDD_Msg_BakColor', 0
	 db	 'VDD_Msg_TextOut', 0
	 db	 'VDD_Msg_SetCursPos', 0
	 db	 'VDD_Query_Access', 0
; End of 3.0 VDD services
	 db	 'VDD_Check_Update_Soon', 0
	 dw	 0		; Sentinel

VSD_SYMS	 label	byte	; Start of VSD services
	 db	 'VSD_Get_Version', 0
	 db	 'VSD_Bell', 0
	 dw	 0		; Sentinel

VMD_SYMS	 label	byte	; Start of VMD services
	 db	 'VMD_Get_Version', 0
	 db	 'VMD_Set_Mouse_Type', 0
	 db	 'VMD_Get_Mouse_Owner', 0
	 dw	 0		; Sentinel

VKD_SYMS	 label	byte	; Start of VKD services
	 db	 'VKD_Get_Version', 0
	 db	 'VKD_Define_Hot_Key', 0
	 db	 'VKD_Remove_Hot_Key', 0
	 db	 'VKD_Local_Enable_Hot_Key', 0
	 db	 'VKD_Local_Disable_Hot_Key', 0
	 db	 'VKD_Reflect_Hot_Key', 0
	 db	 'VKD_Cancel_Hot_Key_State', 0
	 db	 'VKD_Force_Keys', 0
	 db	 'VKD_Get_Kbd_Owner', 0
	 db	 'VKD_Define_Paste_Mode', 0
	 db	 'VKD_Start_Paste', 0
	 db	 'VKD_Cancel_Paste', 0
	 db	 'VKD_Get_Msg_Key', 0
	 db	 'VKD_Peek_Msg_Key', 0
	 db	 'VKD_Flush_Msg_Key_Queue', 0
	 dw	 0		; Sentinel

VCD_SYMS	 label	byte	; Start of VCD services
	 db	 'VCD_Get_Version', 0
	 db	 'VCD_Set_Port_Global', 0
	 db	 'VCD_Get_Focus', 0
	 db	 'VCD_Virtualize_Port', 0
	 dw	 0		; Sentinel

BLOCKDEV_SYMS	 label	byte	; Start of BLOCKDEV services
	 db	 'BlockDev_Get_Version', 0
	 db	 'BlockDev_Register_Device', 0
	 db	 'BlockDev_Find_Int13_Drive', 0
	 db	 'BlockDev_Get_Device_List', 0
	 db	 'BlockDev_Send_Command', 0
	 db	 'BlockDev_Command_Complete', 0
	 db	 'BlockDev_Synchronous_Command', 0
	 dw	 0		; Sentinel

EBIOS_SYMS	 label	byte	; Start of EBIOS services
	 db	 'EBIOS_Get_Version', 0
	 db	 'EBIOS_Get_Unused_Mem', 0
	 dw	 0		; Sentinel

VNETBIOS_SYMS	 label	byte	; Start of VNETBIOS services
	 db	 'VNETBIOS_Get_Version', 0
	 dw	 0		; Sentinel

DOSMGR_SYMS	 label	byte	; Start of DOSMGR services
	 db	 'DOSMGR_Get_Version', 0
	 db	 '_DOSMGR_Set_Exec_VM_Data', 0
	 db	 'DOSMGR_Copy_VM_Drive_State', 0
	 db	 '_DOSMGR_Exec_VM', 0
	 db	 'DOSMGR_Get_IndosPtr', 0
	 db	 'DOSMGR_Add_Device', 0
	 db	 'DOSMGR_Remove_Device', 0
	 db	 'DOSMGR_Instance_Device', 0
	 db	 'DOSMGR_Get_DOS_Crit_Status', 0
	 db	 'DOSMGR_Enable_Indos_Polling', 0
; End of 3.0 DOSMGR services
	 db	 'DOSMGR_BackFill_Allowed', 0
	 db	 'DOSMGR_LocalGlobalReg', 0
	 dw	 0		; Sentinel

SHELL_SYMS	 label	byte	; Start of SHELL services
	 db	 'SHELL_Get_Version', 0
	 db	 'SHELL_Resolve_Contention', 0
	 db	 'SHELL_Event', 0
	 db	 'SHELL_SYSMODAL_Message', 0
	 db	 'SHELL_Message', 0
; End of 3.0 SHELL services
	 db	 'SHELL_GetVMInfo', 0
	 dw	 0		; Sentinel

VMPOLL_SYMS	 label	byte	; Start of VMPOLL services
	 db	 'VMPoll_Get_Version', 0
	 db	 'VMPoll_Enable_Disable', 0
; End of 3.0 VMPOLL services
	 db	 'VMPoll_Reset_Detection', 0
	 dw	 0		; Sentinel

DOSNET_SYMS	 label	byte	; Start of DOSNET services
	 db	 'DOSNET_Get_Version', 0
	 db	 'DOSNET_Send_FILESYSCHANGE', 0
	 db	 'DOSNET_Do_PSP_Adjust', 0
	 dw	 0		; Sentinel

VDD2_SYMS	 label	byte	; Start of VDD2 services
	 db	 'VDD2_Get_Version', 0
	 dw	 0		; Sentinel

WINDEBUG_SYMS	 label	byte	; Start of WINDEBUG services
	 db	 'WINDEBUG_Get_Version', 0
	 dw	 0		; Sentinel

TSRLOAD_SYMS	 label	byte	; Start of TSRLOAD services
	 db	 'TSRLOAD_Get_Version', 0
	 dw	 0		; Sentinel

BIOSHOOK_SYMS	 label	byte	; Start of BIOSHOOK services
	 db	 'BIOSHOOK_Get_Version', 0
	 dw	 0		; Sentinel

INT13_SYMS	 label	byte	; Start of INT13 services
	 db	 'Int13_Get_Version', 0
	 db	 'Int13_Device_Registered', 0
	 db	 'Int13_Translate_VM_Int', 0
	 db	 'Int13_Hooking_BIOS_Int', 0
	 db	 'Int13_Unhooking_BIOS_Int', 0
	 dw	 0		; Sentinel

PAGEFILE_SYMS	 label	byte	; Start of PAGEFILE services
	 db	 'PageFile_Get_Version', 0
	 db	 'PageFile_Init_File', 0
	 db	 'PageFile_Clean_Up', 0
	 db	 'PageFile_Grow_File', 0
	 db	 'PageFile_Read_Or_Write', 0
	 db	 'PageFile_Cancel', 0
	 db	 'PageFile_Test_IO_Valid', 0
	 dw	 0		; Sentinel

SCSI_SYMS	 label	byte	; Start of SCSI services
	 db	 'SCSI_Get_Version', 0
	 dw	 0		; Sentinel

MCA_POS_SYMS	 label	byte	; Start of MCA_POS services
	 db	 'MCA_POS_Get_Version', 0
	 dw	 0		; Sentinel

SCSIFD_SYMS	 label	byte	; Start of SCSIFD services
	 db	 'SCSIFD_Get_Version', 0
	 dw	 0		; Sentinel

VPEND_SYMS	 label	byte	; Start of VPEND services
	 db	 'VPEND_Get_Version', 0
	 dw	 0		; Sentinel

APM_SYMS	 label	byte	; Start of APM services
	 db	 'APM_Get_Version', 0
	 dw	 0		; Sentinel

SERVER_SYMS	 label	byte	; Start of SERVER services
	 db	 'SERVER_Get_Version', 0
	 db	 'SERVER_Unk1', 0
	 db	 'SERVER_Get_Machine_ID', 0
	 db	 'SERVER_Test_Machine_ID', 0
	 dw	 0		; Sentinel

PM_BIOS_SYMS	 label	byte	; Start of PM_BIOS services
	 db	 'PMVDD_Get_Version', 0
	 dw	 0		; Sentinel

VxD_IDATA_ENDS			; End _IDATA segment

	end			; End SWAT_SYM module
