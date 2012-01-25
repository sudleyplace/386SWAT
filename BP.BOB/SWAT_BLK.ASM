;' $Header:   P:/PVCS/386SWAT/SWAT_BLK.ASV   1.23   20 Aug 1998 23:05:42   BOB  $
	title	SWAT_BLK -- 386SWAT Block Display Routines
	page	58,122
	name	SWAT_BLK

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-1999 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include BITFLAGS.INC
	include CPUFLAGS.INC
	include CPUFET.INC
	include 386.INC
	include PTR.INC

	include INT1_FNS.INC ; Needed for OPER_STR
	include SWAT_COM.INC
	include SWAT_DRV.INC
	include SWAT_MOD.INC
	include SWAT_SEG.INC
	include SWAT_SYM.INC
.list

DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	ERRATTR:byte
	extrn	CMDATTR:byte
	extrn	DEFATTR:byte
	extrn	BARATTR:byte
	extrn	CURATTR:byte
	extrn	LBLATTR:byte
	extrn	BPTATTR:byte
	extrn	BPCATTR:byte

	extrn	CMD_LINE:byte
	extrn	FBROWS_PATH:byte
;;;;;;; extrn	OLDSTK_FVEC:fword

	extrn	CPUFET_FLAG:dword

	extrn	UNR_FLAG:word
	include SWAT_UNR.INC

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	@SWAT_BLK_DATA
@SWAT_BLK_DATA label byte	; Mark module start in .MAP file

	extrn	MSGOFF:dword
	extrn	DSP_STATE:byte
	extrn	DSP_STAT2:byte

	extrn	STACK_eSP:dword
	extrn	STACK_eBP:dword

;;;;;;; extrn	RETFL:dword
	extrn	REENTRY:word

	extrn	OLDCS:word
	extrn	OLDDS:word
	extrn	OLDES:word
	extrn	OLDFS:word
	extrn	OLDGS:word
	extrn	OLDSS:word
	extrn	OLDEFL:dword
	extrn	OLDCR0:dword
	extrn	OLDCR2:dword

	extrn	UNABASE:dword
	extrn	UNASEL:word
	extrn	UNAOFF:dword
	extrn	UNACR3:dword
	extrn	UNAMODE:word

	extrn	CHECK_DBG_RES:byte

	extrn	FBROWS_NAME:byte
	extrn	ALTLINE:dword

	extrn	FBROWS_BUF:byte
	extrn	FBROWS_CLINE:dword
	extrn	MODBASE:byte

	public	FIRST_INSTR,CUR_INSTR,NEXT_INSTR,LAST_INSTR,PREV_INSTR
	public	CUR_INSTR_ARW,INSTR_DIFF
FIRST_INSTR   dd -1		; Linear address of 1st instruction on screen
CUR_INSTR     dd -1		; ...		    current
NEXT_INSTR    dd  ?		; ...		    next
LAST_INSTR    dd -1		; ...		    last
PREV_INSTR    dd  ?		; ...		    previous (to back off)
INSTR_DIFF    dd  ?		; Additional bytes to add for INSTRPDN
CUR_INSTR_ARW dw  0		; Current instruction's access rights dword

	public	MSGBUF_LEN
MSGBUF_LEN dw	0		; Length of filled in text for MSGBUF

	public	SELFDBG
SELFDBG dd	0		; Used for debugging SWAT

	public	NEW_TSC,OLD_TSC
NEW_TSC dq	0		; New Time Stamp Counter
OLD_TSC dq	0		; Old ...

	public	INSTRNLN,INSTRLEN
	public	INSTRLDN,INSTRPDN
INSTRNLN db	?,3 dup (?)	; # lines in instruction window
INSTRLEN dd	?		; Current instruction's length
INSTRLDN dd	?		; Top instruction's length
INSTRPDN dd	?		; Page instruction's length

;;;;;;; public	CALL_ESP
;;;;_ESP dd	?		; Caller's ESP

	public	SCROFF,MODOFF,OPROFF,JCCOFF,LINOFF,PHYOFF,CMDOFF
SCROFF	dd	0		; Offset in screen buffer of next msg
MODOFF	dd	?		; ...			     mode line
OPROFF	dd	?		; ...			     operand data
JCCOFF	dd	?		; ...			     Jcc note
LINOFF	dd	?		; ...			     first char on line
PHYOFF	dd	?		; ...			     PHYSICAL via CR3 line
CMDOFF	dd	(@NROWS-1)*@NCOLS*2 ; ...		     command line

	public	W_TMP
W_TMP	W_STR	<>		; Temporary window structure

	public	OPERAND
OPERAND OPER_STR <>		; Operand analysis structure

@MAX_INSTR_LEN	equ	35	; Length of longest possible disassembly
if @NCOLS gt @MAX_INSTR_LEN
@INSTROUT_LEN	equ	@NCOLS
else
@INSTROUT_LEN	equ	@MAX_INSTR_LEN
endif

	public	INSTROUT,INSTROUT_LEN
INSTROUT db	@INSTROUT_LEN dup (' '),0 ; Maximum disassembly length + NUL
INSTROUT_LEN equ @INSTROUT_LEN+0 ; Length not counting the trailing zero

	public	SEGSEP
SEGSEP	db	?		; Segment/selector separator

	public	MSG_CS,MSG_DS,MSG_ES
	public	MSG_FS,MSG_GS,MSG_SS
MSG_CS	db	'CS=',0
MSG_DS	db	'DS=',0
MSG_ES	db	'ES=',0
MSG_FS	db	'FS=',0
MSG_GS	db	'GS=',0
MSG_SS	db	'SS=',0

	public	MSG_CR0,MSG_CR2,MSG_EFL
MSG_CR0 db	'CR0=',0
MSG_CR2 db	'  CR2=',0
MSG_EFL db	'  EFL=',0

	public	MSG_TSC
MSG_TSC db	'TSC=',0        ; Time Stamp Counter message
@MSG_TSC equ   $-MSG_TSC-1	; Length of ...

	public	MSGBUF
MSGBUF	db	@NCOLS*2 dup (?) ; Message buffer for underlying text & attribs

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP,ds:PGROUP

	public	@SWAT_BLK_PROG
@SWAT_BLK_PROG: 		; Mark module start in .MAP file

	extrn	INSTROPER:near
	extrn	INSTRDEC:near
	extrn	CLEAR_OUT:near
	extrn	GETARW:near

	extrn	DISPEGP:near
	extrn	DISPASCIIZ:near
	extrn	DISPTXT:near
	extrn	DISPBAR:near
	extrn	DISPBAR1:near
	extrn	DISPBAR2:near
	extrn	DISPERRMSG:near
	extrn	DISPVMHANDLE:near

	extrn	DISP_EREG:near
	extrn	DISP_SREG:near
	extrn	DISP_FLAG:near
	extrn	DISP_MODE:near
	extrn	DISP_OPER:near
	extrn	DISP_STK:near

	extrn	DISPHEX2:near
	extrn	DISPHEX4:near

	extrn	CLEAR_EOL:near
	extrn	NEXTLINE:near

	extrn	REMROW:near

	extrn	WPUT_CSA:near
	extrn	WPUT_CA:near
	extrn	WGET_CA:near
;;;;;;; extrn	BLINK_LED:near

	extrn	SYMHASH_SRCH:near
	extrn	DOS_AVAIL:near

	extrn	CHECK_DBG:near

	extrn	DISPPHYS:near
	extrn	DISPVIRT:near
	extrn	HDR_PHYS_SUB:near

	extrn	U32_BASE2BIN:near
	extrn	U32_LOWERCASE:near
	extrn	UPPERCASE:near

	extrn	ADJUST_SLINE:near
	extrn	CMD_LOADFIL:near

	NPPROC	DISP_IREGS -- Display Instructions and Registers
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display instructions and registers

|

	push	OPERAND[ 0].EDD ; Save for recursion
	push	OPERAND[ 4].EDD ; ...
	push	OPERAND[ 8].EDD ; ...
	push	OPERAND[12].EDD ; ...
	push	OPERAND[16].EDD ; ...
	push	OPERAND[20].EDD ; ...
	push	OPERAND[24].EDD ; ...
	push	OPERAND[28].EDD ; ...
	push	OPERAND[32].EDD ; ...

	mov	SCROFF,0	; Set to zero

	push	edx		; Save for a moment

	mov	dl,1		; Display EGP registers
	call	DISP_BLK1	; Display the 1st block

	pop	edx		; Restore

	push	SCROFF		; Get current screen offset
	pop	PHYOFF		; Save as physical line offset
	call	DISPBAR1	; Display a separator line
	call	DISP_TSC	; Display instruction timing

	call	DISP_BLK2	; Display the 2nd block
	push	SCROFF		; Get current screen offset
	pop	MODOFF		; Save as mode line offset
	call	DISPBAR2	; Display a separator line
	call	DISP_MODE	; Display program modes on previous bar

	call	DISP_BLK3	; Display the 3rd block
	call	DISPBAR 	; Display a separator line
	call	DISPERRMSG	; Display error msg on previous bar
	call	DISPVMHANDLE	; Display VM_Handle on previous bar (if Windows)

	call	DISP_BLK4	; Display the 4th block

	call	DISP_CMDLINE	; Display the command line

; Display the stack

	push	STACK_eSP	; Pass SS:eSP linear address
	push	STACK_eBP	; ...  SS:eBP ...
	call	DISP_STK	; Display it

; Display data about the first instruction's operands

	call	DISP_OPER	; Display it

	mov	DSP_STATE,@DSP_IREGS ; Initial screen state is instructions
	mov	DSP_STAT2,@DSP_IREGS ; Secondary ...

	pop	OPERAND[32].EDD ; Restore for recursion
	pop	OPERAND[28].EDD ; ...
	pop	OPERAND[24].EDD ; ...
	pop	OPERAND[20].EDD ; ...
	pop	OPERAND[16].EDD ; ...
	pop	OPERAND[12].EDD ; ...
	pop	OPERAND[ 8].EDD ; ...
	pop	OPERAND[ 4].EDD ; ...
	pop	OPERAND[ 0].EDD ; ...

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_IREGS endp 		; End DISP_IREGS procedure
	NPPROC	DISP_BLK1 -- Display Block #1
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display block #1 consisting of

EGP registers

and calculate caller stack linear address.

On entry:

SS:EBP	==>	FORW_STR
DL	=	1 if we should display EGP registers
	=	0 if we're only calculating STACK_eSP and STACK_eBP

|

	REGSAVE <eax,ebx,ecx>	; Save registers

; Display all EGP registers and setup
; EAX ==> caller's SS:ESP
; EBX ==> caller's SS:EBP
; ECX ==> stack segment base

	mov	ecx,[ebp-@BPBACK].BACK_SS.DTR_BASE ; Get stack segment base

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	jz	short DISP_BLK1_PM1 ; Not this time

; We're in VM86 mode

	or	dl,dl		; Are we displaying?
	jz	short @F	; Jump if not

	call	DISPEGP 	; Display all EGP registers

@@:
	mov	eax,[ebp].FORW_ESP ; Get stack pointer
	mov	ebx,[ebp].FORW_EBP ; Get base pointer
;;;;;;; mov	CALL_ESP,eax	; Save for later use

	jmp	short DISP_BLK1_CLR ; Join common code

DISP_BLK1_PM1:

; We're in protected mode:  Use OLDSTK_FVEC if we're not re-entering,
; SS:[EBP].FORW_ESP otherwise

	lea	eax,[ebp].FORW_ESP ; Get caller's stack offset

	cmp	REENTRY,1	; Check re-entry level
	jne	short @F	; Jump if re-entry

;;;;;;; mov	eax,OLDSTK_FVEC.FOFF ; Get caller's ESP
;;;;;;;
;;;;;;; test	RETFL,mask $NT	; Are we in NT mode?
;;;;;;; jz	short @F	; Not this time
;;;;;;;
	mov	eax,[ebp].FORW_ESP ; Get from extended stack
@@:
;;;;;;; mov	CALL_ESP,eax	; Save for later use

	or	dl,dl		; Are we displaying?
	jz	short @F	; Jump if not

	xchg	eax,[ebp].FORW_ESP ; Swap with whatever's there
	call	DISPEGP 	; Display all EGP registers
	xchg	eax,[ebp].FORW_ESP ; Restore

@@:
	mov	ebx,[ebp].FORW_EBP ; Get caller's EBP

; If the B-bit is clear in the stack selector,
; clear the high-order word of EAX (eSP) and EBX (eBP)

	push	eax		; Save for a moment

	push	[ebp].FORW_SS	; Get the caller's stack selector
	call	GETARW		; Return with AX = access rights word

	test	ah,mask $DTE_B	; Izit a big stack?
	pop	eax		; Restore
	jnz	short DISP_BLK1_XCLR ; Jump if so
DISP_BLK1_CLR:
	movzx	eax,ax		; Clear the high-order word of ESP
	movzx	ebx,bx		; ...			       EBP
DISP_BLK1_XCLR:
	add	eax,ecx 	; Plus base of SS
	add	ebx,ecx 	; ...

	mov	STACK_eSP,eax	; Save for later use
	mov	STACK_eBP,ebx	; Save for later use

	REGREST <ecx,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_BLK1 endp			; End DISP_BLK1 procedure
	NPPROC	DISP_TSC -- Display Instruction Timing
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display instruction timing

|

	REGSAVE <eax,edx,esi>	; Save registers

	test	CPUFET_FLAG,@CPUFET_TSCNT ; Duzit support Time Stamp Counter?
	jz	short DISP_TSC_EXIT ; Jump if not

	push	SCROFF		; Save current screen offset

	sub	SCROFF,2*(@MSG_TSC+8) ; Back off one row less space for text

	lea	esi,MSG_TSC	; Display prefix text
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	mov	edx,NEW_TSC.EDQHI ; Get current TSC value
	mov	eax,NEW_TSC.EDQLO ; ...

	sub	edx,OLD_TSC.EDQHI ; Less previous value
	sbb	eax,OLD_TSC.EDQLO ; ...
	call	DISPHEX4	; Display the dword

	pop	SCROFF		; Restore
DISP_TSC_EXIT:
	REGREST <esi,edx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_TSC endp			; End DISP_TSC procedure
	NPPROC	DISP_BLK2 -- Display Block #2
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display block #2 consisting of

Segment/selectors CS, DS, ES, FS, GS, SS

On entry:

SS:EBP	==>	FORW_STR

|

	REGSAVE <eax>		; Save register

; Display segment registers

	xor	eax,eax 	; Zero to use as dword

; Display CS, DS, and FS segment registers

	test	UNR_FLAG,@UNR_CS ; Izit enabled?
	setnz	al		; AL = 1 if enabled, 0 if disabled

	push	eax		; Pass Unreal Mode data
	push	offset ds:MSG_CS ; Offset of message to display
	push	OLDCS		; Pass old value
	push	[ebp-@BPBACK].BACK_CS.DTR_LIM ; Pass selector/segment
	call	DISP_SREG	; Display a selector/segment register

	call	DISP_SREGSEP	; Display segment register separator

	test	UNR_FLAG,@UNR_DS ; Izit enabled?
	setnz	al		; AL = 1 if enabled, 0 if disabled

	push	eax		; Pass Unreal Mode data
	push	offset ds:MSG_DS ; Offset of message to display
	push	OLDDS		; Pass old value
	push	[ebp-@BPBACK].BACK_DS.DTR_LIM ; Pass selector/segment
	call	DISP_SREG	; Display a selector/segment register

	call	DISP_SREGSEP	; Display segment register separator

	test	UNR_FLAG,@UNR_FS ; Izit enabled?
	setnz	al		; AL = 1 if enabled, 0 if disabled

	push	eax		; Pass Unreal Mode data
	push	offset ds:MSG_FS ; Offset of message to display
	push	OLDFS		; Pass old value
	push	[ebp-@BPBACK].BACK_FS.DTR_LIM ; Pass selector/segment
	call	DISP_SREG	; Display a selector/segment register

; Display SS, ES, and GS segment registers

	call	NEXTLINE	; Skip to next line, first column

	test	UNR_FLAG,@UNR_SS ; Izit enabled?
	setnz	al		; AL = 1 if enabled, 0 if disabled

	push	eax		; Pass Unreal Mode data
	push	offset ds:MSG_SS ; Offset of message to display
	push	OLDSS		; Pass old value
	push	[ebp-@BPBACK].BACK_SS.DTR_LIM ; Pass selector/segment
	call	DISP_SREG	; Display a selector/segment register

	call	DISP_SREGSEP	; Display segment register separator

	test	UNR_FLAG,@UNR_ES ; Izit enabled?
	setnz	al		; AL = 1 if enabled, 0 if disabled

	push	eax		; Pass Unreal Mode data
	push	offset ds:MSG_ES ; Offset of message to display
	push	OLDES		; Pass old value
	push	[ebp-@BPBACK].BACK_ES.DTR_LIM ; Pass selector/segment
	call	DISP_SREG	; Display a selector/segment register

	call	DISP_SREGSEP	; Display segment register separator

	test	UNR_FLAG,@UNR_GS ; Izit enabled?
	setnz	al		; AL = 1 if enabled, 0 if disabled

	push	eax		; Pass Unreal Mode data
	push	offset ds:MSG_GS ; Offset of message to display
	push	OLDGS		; Pass old value
	push	[ebp-@BPBACK].BACK_GS.DTR_LIM ; Pass selector/segment
	call	DISP_SREG	; Display a selector/segment register

	call	NEXTLINE	; Skip to next line, first column

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_BLK2 endp			; End DISP_BLK2 procedure
	NPPROC	DISP_SREGSEP -- Display Segment Register Separator
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display segment register separator

|

	REGSAVE <eax>		; Save register

	mov	ah,BARATTR	; Get bar attribute
	xchg	ah,DEFATTR	; Swap with default attribute
	mov	al,'³'          ; Separator
	call	DISPTXT 	; Display byte on screen as text
	xchg	ah,DEFATTR	; Swap back

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_SREGSEP endp		; End DISP_SREGSEP procedure
	NPPROC	DISP_BLK3 -- Display Block #3
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display block #3 consisting of

CR0, CR2, and EFL

On entry:

SS:EBP	==>	FORW_STR

|

	REGSAVE <eax,ebx,esi>	; Save registers

; CR0

	lea	esi,MSG_CR0	; Display "CR0=" text
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	push	OLDCR0		; Pass former value
	mov	eax,cr0 	; Get the current value

; If we're loaded from RM, clear the $PE bit
; as we're not really in PM.

	test	[ebp].FORW_EFL,mask $R2 ; Izit from RM?
	jz	short @F	; Jump if not

	and	eax,not (mask $PE) ; PE=0
@@:
	push	eax		; Pass current value
	call	DISP_EREG	; Display it

; CR2

	lea	esi,MSG_CR2	; Display "CR2=" text
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	push	OLDCR2		; Pass former value
	mov	eax,cr2 	; Get the current value
	push	eax		; Pass current value
	call	DISP_EREG	; Display it

; EFL

	lea	esi,MSG_EFL	; Display "EFL=" text
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

; Because we use $R2 to indicate we've come from RM,
; we need to clear it in the current value before displaying it.

	mov	ebx,[ebp].FORW_EFL ; Get current value
	and	ebx,not (mask $R2) ; Clear spurious bit
	mov	esi,ebx 	; Copy to use below

; Ensure TF same in OLDEFL as in FORW_EFL

	mov	eax,OLDEFL	; Get former value
	xor	ebx,eax 	; Get unequal values
	and	ebx,mask $TF	; Isolate unequal Trap Flag
	xor	eax,ebx 	; Restore to former value

	push	eax		; Pass former value
	push	esi		; Pass current value
	call	DISP_EREG	; Display it

; Display flag status

	call	DISP_FLAG	; Display 'em

	call	CLEAR_EOL	; Clear to the end-of-the-line
	call	NEXTLINE	; Skip to next line, first column

	REGREST <esi,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_BLK3 endp			; End DISP_BLK3 procedure
	NPPROC	DISP_BLK4 -- Display Block #4
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display block #4 consisting of

Instructions and operand analysis using UNACR3 if @MODE_PHYS is set.

On entry:

SS:EBP	==>	FORW_STR

|

	REGSAVE <eax,ecx,esi,edi,fs> ; Save registers

; Display the instructions on the remaining lines

	call	REMROW		; Return with ECX = # remaining rows
	dec	ecx		; Back off to allow room for command line

	test	UNAMODE,@MODE_VM ; Izit VM 8086 mode?
	jz	short DISP_BLK4_PM1 ; No, use selector directly

	mov	SEGSEP,':'      ; Save as segment/selector separator

	jmp	short DISP_BLK4_COM ; Join common code

DISP_BLK4_PM1:
	mov	SEGSEP,'|'      ; Save as segment/selector separator
DISP_BLK4_COM:
	mov	INSTRNLN,cl	; Save as # lines in instruction window

	mov	eax,SCROFF	; Get current screen offset
	add	eax,(28-@NCOLS)*2 ; Skip to operand data point on previous line
	mov	OPROFF,eax	; Save for later use

; Analyze the instruction at FS:ESI into ES:EDI

	push	gs		; Get our all memory selector
	pop	fs		; Address it
	assume	fs:nothing	; Tell the assembler about it

	mov	esi,CUR_INSTR	; FS:ESI ==> current instruction

	push	ecx		; Save count

	xor	cx,cx		; Assume USE16 disassembly

	test	CUR_INSTR_ARW.HI,mask $DTE_B ; Check for USE32
	jz	short @F	; Jump if USE16

	or	cx,@BIT0	; Mark as USE32
@@:
	test	UNAMODE,@MODE_VM ; Izit VM 8086 mode?
	jnz	short @F	; Jump if so

	or	cx,@BIT1	; Mark as PM
@@:
	lea	edi,OPERAND	; ES:EDI ==> instruction operand structure
	call	INSTROPER	; Analyze the next instruction's operands

	pop	ecx		; Restore

	REGSAVE <UNAOFF,UNABASE> ; Save offset and base

	test	UNAMODE,@MODE_PHYS ; Izit in physical mode?
	jz	short @F	; Jump if not

	push	UNACR3		; Pass new CR3 to use (if non-zero)
	push	UNABASE 	; Pass base memory to use
	push	UNAOFF		; Pass memory offset to use
	call	DISPPHYS	; Setup for physical memory display

	mov	UNABASE,eax	; Save as new base address
@@:
	push	gs		; Get our all memory selector
	pop	fs		; Address it
	assume	fs:nothing	; Tell the assembler about it

	mov	esi,UNABASE	; Get base of instruction display
	add	esi,UNAOFF	; Begin disassembly from here

	call	DISPINSTR	; Display instructions

	test	UNAMODE,@MODE_PHYS ; Izit in physical mode?
	jz	short @F	; Jump if not

	call	DISPVIRT	; Restore virtual mode display

	push	SCROFF		; Save current screen offset

	mov	eax,PHYOFF	; Get offset of PHYSICAL via CR3 line
	mov	SCROFF,eax	; Save as current screen offset

	mov	eax,UNACR3	; Get translated CR3 (if non-zero)
	call	HDR_PHYS_SUB	; Use common subroutine

	pop	SCROFF		; Restore
@@:
	REGREST <UNABASE,UNAOFF> ; Restore offset and base

	REGREST <fs,edi,esi,ecx,eax> ; Restore
	assume	fs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_BLK4 endp			; End DISP_BLK4 procedure
	NPPROC	DISPINSTR -- Display Instructions
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display instructions

On entry:

ECX	=	# rows to display
FS:ESI	==>	starting instruction
SS:EBP	==>	FORW_STR

CUR_INSTR ==>	 current instruction offset

|

	pushad			; Save all EGP registers

	mov	FIRST_INSTR,esi ; Save as linear address of first instr
	mov	INSTR_DIFF,0	; Clear additional bytes for page down

	mov	ebx,UNABASE	; Get linear address of segment/selector base
DISPINSTR_NEXT:

; Set default attribute depending on whether or not this is the current instr

	mov	dl,DEFATTR	; Assume not

	cmp	esi,CUR_INSTR	; Is this the current offset?
	jne	short @F	; Jump if not

	mov	dl,CURATTR	; Get attribute for current instruction
@@:
	xchg	dl,DEFATTR	; Swap with default attribute
	mov	dh,dl		; Save default attribute

	mov	eax,SCROFF	; Get offset of first char/attr on line
	mov	LINOFF,eax	; Save for later use

	SELFBREAK DISPINSTR,01h ; Allow a breakpoint if SELFDBG & 01

	mov	eax,esi 	; Get current linear address
	call	CHECK_DBG	; See if it has a breakpoint on it
	jc	short DISPINSTR_XBREAKPT ; Jump if not

	mov	dl,BPTATTR	; Attribute for line with breakpoint
	cmp	esi,CUR_INSTR	; Is this the current offset?
	jne	short @F	; Jump if not

	mov	dl,BPCATTR	; Attribute for current line with breakpoint
@@:
	mov	DEFATTR,dl	; Set default attribute
DISPINSTR_XBREAKPT:
	cmp	esi,CUR_INSTR	; Izit the current instruction?
	jne	short @F	; Jump if not

	and	LC2_FLAG,not (mask $LC2_SFND) ; Clear source line found flag
@@:
	call	SYMHASH_SRCH	; Look for EAX in symbol hash table
				; Return with DGROUP:EAX ==> symbol record
	jc	near ptr DISPINSTR_XLABEL ; Not found

	REGSAVE <ecx,esi>	; Save registers

	call	CLEAR_OUT	; Clear INSTROUT to all blanks

	cmp	ecx,1		; Izit the last line?
	ja	short DISPINSTR_XLAST ; Continue if not

	pop	esi		; Get saved ESI
	mov	esi,PREV_INSTR	; Get penultimate instruction
	push	esi		; Put on stack
	sub	esi,LAST_INSTR	; Get inverted difference
	neg	esi		; Make it positive
	mov	INSTR_DIFF,esi	; Save difference
	mov	esi,[esp].EDD	; Restore ESI
	mov	LAST_INSTR,esi	; Back off to previous instruction

	jmp	near ptr DISPINSTR_BLANK ; End of the screen

DISPINSTR_XLAST:
	cmp	esi,CUR_INSTR	; Izit the current instruction?
	lea	esi,DGROUP:[eax].SYM_NAMLEN ; Get address of length byte
	push	esi		; Save it
	jne	near ptr DISPINSTR_XLINE ; No source adjustment if ESI != CUR

	test	LC2_FLAG,@LC2_SRC ; Are we in source browse mode?
	jz	near ptr DISPINSTR_XLINE ; Jump if not

	mov	eax,ALTLINE	; Get offset of line number record
	or	eax,eax 	; Is there one?
	jz	near ptr DISPINSTR_XLINE ; Jump if not

	SELFBREAK DISPINSTR2,04h ; Allow breakpoint if SELFDBG & 04

	lea	esi,DGROUP:[eax].SYM_NAMLEN ; Get address of length byte

	lods	DGROUP:[esi].LO ; Get length byte
	movzx	ecx,al		; Set up for rep scas
	mov	edi,esi 	; Address start of symbol name
	mov	al,'#'          ; Line number delimiter

	test	LC2_FLAG,@LC2_IGNMOD ; Are we ignoring module name?
	jz	short @F	; Jump if not

	cmp	FBROWS_NAME,0	; Is a source file already loaded?
	je	near ptr DISPINSTR_XLINE ; Jump if not

	jmp	short DISPINSTR_FINDLN ; Find first character after '#'

@@:
	cmp	FBROWS_NAME,0	; Is a source file already loaded?
	je	short DISPINSTR_LOADFILE ; Jump if not

; Compare module name (case insensitive)
	lea	esi,MODBASE	; Address module base name
DISPINSTR_COMPNAME:
	lods	MODBASE[esi]	; Get character to compare
	call	UPPERCASE	; Make it uppercase

	cmp	al,DGROUP:[edi].LO ; Does it match?
	je	short @F	; Jump if so

	call	U32_LOWERCASE	; Try lowercase

	cmp	al,DGROUP:[edi].LO ; Any luck?
	je	short @F	; Jump if not

	cmp	DGROUP:[edi].LO,'#' ; Did we mismatch on '#'?
	jne	short DISPINSTR_LOADFILE ; Load new file if so

	or	al,al		; Izit the end of MODBASE?
	jz	short DISPINSTR_FINDLN ; Jump if so

	jmp	short DISPINSTR_LOADFILE ; Load new file

@@:
	inc	edi		; Next character to compare
	LOOPD	DISPINSTR_COMPNAME ; Go around again

; Copy file basename from symbol record to MODBASE.  Attempt to open file
; (add .C and  .ASM extensions, looking in PATH directories).  If file
; open fails, turn off source browse mode.
DISPINSTR_LOADFILE:
	mov	esi,ALTLINE	; Get offset of symbol record
	lea	esi,DGROUP:[esi].SYM_NAMLEN ; Get address of length byte
	lods	DGROUP:[esi].LO ; Get length
	movzx	ecx,al		; Extend to integer
	lea	edi,MODBASE	; Destination for copy
DISPINSTR_LOADFNEXT:
	lods	DGROUP:[esi].LO ; Get character
	cmp	al,'#'          ; Izit the end of the name?
	jne	short @F	; Jump if not

	sub	al,al		; Terminate
@@:
S32	stos	MODBASE[edi]	; Save character
	or	al,al		; Izit the end?
	jz	short @F	; Jump if so

	LOOPD	DISPINSTR_LOADFNEXT ; Go around again
@@:
	call	LOAD_SOURCE	; Load source file in MODBASE
	jnc	short DISPINSTR_FINDLN2 ; Jump if no error

; If we failed to open source file, turn off source browse mode now so
; we don't keep trying to open files that don't exist.
	and	LC2_FLAG,not @LC2_SRC ; Turn off source browse mode
	mov	FBROWS_NAME,0	; Disable browser display
	jmp	short DISPINSTR_XLINE ; Not displaying source anymore

DISPINSTR_FINDLN:
	mov	al,'#'          ; Line number delimiter
  repne scas	DGROUP:[edi].LO ; Find decimal line number
	jne	short DISPINSTR_XLINE ; Didn't find it (something's wrong)

	mov	esi,edi 	; Source for move
DISPINSTR_FINDLN2:
	lea	edi,FBROWS_BUF	; Line buffer for near addressability
S32 rep movs	<DGROUP:[edi].LO,DGROUP:[esi].LO> ; Move it
	sub	al,al		; Get a null terminator
S32	stos	DGROUP:[edi].LO ; Convert to ASCIIZ

	lea	esi,FBROWS_BUF	; String to convert
	mov	ecx,10		; Radix
	call	U32_BASE2BIN	; Return value in EAX, CF significant

	jc	short DISPINSTR_XLINE ; Jump if error

	cmp	eax,0000ffffh	; Izit a valid line number?
	ja	short DISPINSTR_XLINE ; Jump if not

	dec	eax		; Convert to 0-based value
	mov	FBROWS_CLINE,eax ; Set new line number
;;;;;;;  sub	 eax,FBROWS_CLINE ; Get signed offset from current line

;;;;;;;  or	 eax,eax	; Izit 0?
;;;;;;;  jz	 short DISPINSTR_XLINE ; Jump if so (no change)
	sub	eax,eax 	; Ensure we have the current line displayed,
				; but don't change SLINE unless necessary
	or	LC2_FLAG,@LC2_SFND ; Current line is a source line
	call	ADJUST_SLINE	; Set new initial line in browser
DISPINSTR_XLINE:
	pop	esi		; Get address of length byte

	test	LC2_FLAG,@LC2_NOLINE ; Are we displaying line numbers?
	jz	short @F	; Jump if so

	mov	ax,DGROUP:[esi-SYM_NAMLEN].SYM_FLAG ; Get flags
	and	ax,mask $SYMFL_TYP ; Isolate record type bits
	cmp	ax,@SYMTYP_LN shl $SYMFL_TYP ; Izit a line number?
	jne	short @F	; Display as a label if not

; One push, two pops - it's a messy way to do it, BUT-
; this code needs to be reentrant, and we can't use EBP to reference
; local variables without adding restore EBP code around all the calls
; where we expect SS:EBP ==> FORW_STR.	These register values were
; saved after we made the original branch to DISPINSTR_XLABEL.
	REGREST <esi,ecx>	; Restore registers
	jmp	DISPINSTR_XLABEL ; Don't display label

@@:
	lods	DGROUP:[esi].LO ; Get length byte
	cmp	al,@MAX_INSTR_LEN ; Izit > maximum length?
	jna	short @F	; It's OK

	mov	al,@MAX_INSTR_LEN-1 ; Maximum length - 1 for ':'
@@:
	movzx	ecx,al		; Put it in ECX
	lea	edi,INSTROUT	; Get address of label output buffer
S32 rep movs	<DGROUP:[edi].LO,DGROUP:[esi].LO> ; Move it
	mov	al,':'          ; Terminate with ':'
S32	stos	DGROUP:[edi].LO ; Put it in

	mov	esi,SCROFF	; Get current screen offset
	sub	esi,LINOFF	; Less starting offset
	shr	esi,(1-0)	; Account for attributes
	sub	esi,@NCOLS	; Complement in screen width
	neg	esi		; ...

	mov	INSTROUT[esi-10],0 ; Form ASCIIZ less 10 for stack display
	mov	dl,LBLATTR	; Get label attribute
	cmp	CHECK_DBG_RES,0 ; Is this line a breakpoint?
	je	short @F	; Jump if so

	mov	dl,BPTATTR	; Get breakpoint set attribute
@@:
	xchg	DEFATTR,dl	; Set as default attribute

DISPINSTR_BLANK:
	lea	esi,INSTROUT	; Output line
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	call	NEXTLINE	; Skip to next line, first column

	mov	DEFATTR,dl	; Set previous screen attribute

	mov	eax,SCROFF	; Get offset of first char/attr on line
	mov	LINOFF,eax	; Save for later use

	REGREST <esi,ecx>	; Restore registers

; Save this instruction offset if it's the last instruction
; for FIRST_INSTR/LAST_INSTR checking

	cmp	ecx,2		; Check for last instruction
	jne	short @F	; Not this time

	mov	LAST_INSTR,esi	; Save as offset of last instruction
@@:
	dec	ecx		; Decrement count of lines to display
	jnz	short DISPINSTR_XLABEL ; If not 0, display instruction also

	mov	DEFATTR,dh	; Restore default attribute

	jmp	DISPINSTR_XDISP ; Done with display loop

DISPINSTR_XLABEL:
	mov	ax,UNASEL	; Display the selector/segment
	call	DISPHEX2	; Display the word

	mov	al,SEGSEP	; Segment/selector separator
	call	DISPTXT 	; Display byte on screen as text

	mov	eax,esi 	; Get current linear address
	sub	eax,ebx 	; Less linear address of segment/selector base

	test	UNAMODE,@MODE_USE32 ; Izit USE32?
	jz	short DISPINSTR1 ; Not this time

	call	DISPHEX4	; Display the dword

	jmp	short DISPINSTR2 ; Join common code

DISPINSTR1:
	call	DISPHEX2	; Display the word (not the dword)
DISPINSTR2:
	mov	al,' '          ; Separator
	call	DISPTXT 	; Display byte on screen as text

	call	CLEAR_OUT	; Clear the output buffer

; Disassemble the instruction at FS:ESI into ES:EDI using EBX as an offset base

	lea	edi,INSTROUT	; ES:EDI ==> output line

	push	esi		; Save offset
	call	DISASSEMBLE	; Disassemble the next instruction
				; returning FS:ESI ==> next instruction
				; ...	    ES:EDI ==> next output byte
	pop	edi		; Restore into EDI

; Save length of this instruction if it's at the top

	cmp	edi,FIRST_INSTR ; Izit the first instruction?
	jne	short @F	; Not this time

	mov	eax,esi 	; Copy to calculate length
	sub	eax,edi 	; Less start to get length
	mov	INSTRLDN,eax	; Save for later use
@@:

; Save address of the next instruction if this is the current instruction

	cmp	edi,CUR_INSTR ; Is this the current offset?
	jne	short DISPINSTR_XCUR ; Jump if not

	mov	eax,esi 	; Copy to calculate length
	sub	eax,edi 	; Less start to get length
	mov	INSTRLEN,eax	; Save for later use

	mov	eax,LINOFF	; Get current instruction offset
	add	eax,2*(@NCOLS-10-10) ; Last column - stack display - "; No jump"
	mov	JCCOFF,eax	; Save for later use

	mov	NEXT_INSTR,esi	; Save for later use
DISPINSTR_XCUR:
	push	esi		; Save for a moment

	mov	esi,SCROFF	; Get current screen offset
	sub	esi,LINOFF	; Less starting offset
	shr	esi,(1-0)	; Account for attributes
	sub	esi,@NCOLS	; Complement in screen width
	neg	esi		; ...

	mov	INSTROUT[esi-10],0 ; Form ASCIIZ less 10 for stack display

	lea	esi,INSTROUT	; Output line
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	pop	esi		; Restore

	call	NEXTLINE	; Skip to next line, first column

; Save this instruction offset if it's the last instruction
; for FIRST_INSTR/LAST_INSTR checking

	cmp	ecx,2		; Check for last instruction
	jna	short @F	; Jump if last instruction

	mov	PREV_INSTR,esi	; Save penultimate instruction
	jmp	short DISPINSTR_ENDLOOP ; Join common code

@@:
	jne	short DISPINSTR_ENDLOOP ; If 1, don't save
	mov	LAST_INSTR,esi	; Save as offset of last instruction

DISPINSTR_ENDLOOP:
	mov	DEFATTR,dh	; Restore default attribute

;;;;;;; loop	DISPINSTR_NEXT	; Jump if more rows for instruction
	dec	ecx		; Count less instruction
	jnz	near ptr DISPINSTR_NEXT ; Jump if more to display

DISPINSTR_XDISP:
; Calculate length of all instructions on this page

	sub	esi,FIRST_INSTR ; Less offset of first instruction
	mov	eax,INSTR_DIFF	; Get difference
	add	esi,eax 	; Add to page down value
	mov	INSTRPDN,esi	; Save for later use

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPINSTR endp			; End DISPINSTR procedure
	NPPROC	DISASSEMBLE -- Disassemble An Instruction
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disassemble the instruction at FS:ESI into ES:EDI using EBX as an offset base

On entry:

EBX	=	segment/selector offset base (used for relative offsets)
FS:ESI	==>	instruction to disassemble
ES:EDI	==>	output save area
SS:EBP	==>	FORW_STR

On exit:

FS:ESI	==>	next instruction
ES:EDI	==>	next output byte

|

	push	ecx		; Save count

	xor	cx,cx		; Assume USE16 disassembly

	test	UNAMODE,@MODE_USE32 ; Check for USE32
	jz	short @F	; Jump if USE16

	or	cx,@BIT0	; Mark as USE32
@@:
	test	UNAMODE,@MODE_VM ; Izit VM 8086 mode?
	jnz	short @F	; Jump if so

	or	cx,@BIT1	; Mark as PM
@@:
	call	INSTRDEC	; Disassemble the next instruction
				; returning FS:ESI ==> next instruction
				; ...	    ES:EDI ==> next output byte
	pop	ecx		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISASSEMBLE endp		; End DISASSEMBLE procedure
	NPPROC	DISP_MSGLINE -- Display The Message Line
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the message line

|

	REGSAVE <eax,ecx,edi,es> ; Save registers

	test	LC2_FLAG,@LC2_MSG ; Any message to be displayed?
	jz	short DISP_MSGLINE1 ; Not this time

	push	ds		; Get our data selector
	pop	es		; Address if
	assume	es:DGROUP	; Tell the assembler about it

; Search for the end of the message

	mov	edi,MSGOFF	; ES:EDI ==> ASCIIZ message text
	mov	ecx,-1		; We know it's there
	mov	al,0		; Terminator
  repne scas	es:[edi].LO	; Search for it
	sub	edi,MSGOFF	; Convert to origin-1
	dec	edi		; Less the terminator

	mov	W_TMP.SROW,@NROWS-2 ; Start on next-to-last row
	mov	W_TMP.SCOL,0	     ; ...	first col
	mov	W_TMP.NROW,1	     ; # rows on message line
	mov	W_TMP.NCOL,di	     ; # cols ...
	mov	MSGBUF_LEN,di	; Save for later use

; Save underlying text

	push	offset DGROUP:MSGBUF ; Pass address of message buffer
	push	offset DGROUP:W_TMP ; Pass address of window descriptor
	call	WGET_CA 	; Input the characters and attributes

	mov	al,ERRATTR	; Get message line attribute
	push	ax		; Pass as attribute to smear
	push	MSGOFF		; Pass address of message line
	push	offset DGROUP:W_TMP ; Pass address of window descriptor
	call	WPUT_CSA	; Output the characters, smear attribute
DISP_MSGLINE1:
	REGREST <es,edi,ecx,eax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_MSGLINE endp		; End DISP_MSGLINE procedure
	NPPROC	DISP_CMDLINE -- Display The Command Line
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the command line

|

	REGSAVE <eax>		; Save register

	mov	W_TMP.SROW,@NROWS-1 ; Start on last row
	mov	W_TMP.SCOL,0	     ; ...	first col
	mov	W_TMP.NROW,1	     ; # rows on command line
	mov	W_TMP.NCOL,@NCOLS   ; # cols ...

	mov	al,CMDATTR	; Get command line attribute
	push	ax		; Pass as attribute to smear
	push	offset DGROUP:CMD_LINE ; Pass address of command line
	push	offset DGROUP:W_TMP ; Pass address of window descriptor
	call	WPUT_CSA	; Output the characters, smear attribute

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_CMDLINE endp		; End DISP_CMDLINE procedure
	NPPROC	CLEAR_MSG -- Clear Displayed Message text
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear any displayed message text

|

	REGSAVE <eax>		; Save register

	test	LC2_FLAG,@LC2_MSG ; Izit displayed?
	jz	short CLEAR_MSG_EXIT ; Not this time

; Restore underlying text

	mov	W_TMP.SROW,@NROWS-2 ; Start on next-to-last row
	mov	W_TMP.SCOL,0	     ; ...	first col
	mov	W_TMP.NROW,1	     ; # rows on message line
	mov	ax,MSGBUF_LEN	     ; Get # characters in line
	mov	W_TMP.NCOL,ax	     ; # cols ...

	push	offset DGROUP:MSGBUF ; Pass address of message buffer
	push	offset DGROUP:W_TMP ; Pass address of window descriptor
	call	WPUT_CA 	; Output the characters and attributes

	and	LC2_FLAG,not @LC2_MSG ; Clear message flag
CLEAR_MSG_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLEAR_MSG endp			; End CLEAR_MSG procedure
	NPPROC	LOAD_SOURCE -- Load source module
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Attempt to access source module listed in MODBASE.
We may need to add .C or .ASM extensions, as well as searching
in various source directories.

On entry:
MODBASE =	Source file basename

On exit:
CF=0		File exists.
CF=1		File not found or services unavailable.

|

	pushad			; Save

	call	DOS_AVAIL	; Are DOS services available?
	jc	short LOAD_SOURCE_EXIT1 ; Jump if not (CF set)

	SELFBREAK LOAD_SOURCE,20h ; Conditional non-reentrant breakpoint

	lea	esi,FBROWS_PATH ; Search path for source
LOAD_SOURCE_NEXTDIR:
	lea	edi,FBROWS_BUF	; Destination for path
LOAD_SOURCE_NEXTC:
	lods	FBROWS_PATH[esi] ; Get character from path
	cmp	al,','          ; Izit a separator?
	jne	short @F	; Jump if not

	sub	al,al		; Prepare to terminate
@@:
S32	stos	FBROWS_BUF[edi] ; Save character
	or	al,al		; Izit the end?
	jnz	short LOAD_SOURCE_NEXTC ; Jump if not

	dec	edi		; Back off to ending character
	dec	esi		; Back off to null or separator

	call	LOAD_SOURCE_COM ; Copy MODBASE into FBROWS_BUF at EDI and
				; try to open with different extensions
	jnc	short LOAD_SOURCE_EXIT ; Jump if we succeeded

	lods	FBROWS_PATH[esi] ; Get last character
	or	al,al		; Was it the end?
	jnz	short LOAD_SOURCE_NEXTDIR ; Jump if not

LOAD_SOURCE_EXIT:
	and	LC2_FLAG,not @LC2_MSG ; Turn off message display
				; (note CF=0)
LOAD_SOURCE_EXIT1:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOAD_SOURCE endp		; End LOAD_SOURCE procedure
	NPPROC	LOAD_SOURCE_COM -- Attempt to open source module in a given dir
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DGROUP:EDI points into FBROWS_BUF at a location at which we may copy
MODBASE and try (with different extensions) to open a source module.

On entry:
DGROUP:EDI ==>	 Location in FBROWS_BUF for module basename.

On exit:
CF=0		File opened successfully.

|

	pushad			; Save

	lea	esi,MODBASE	; Source
@@:
	lods	MODBASE[esi]	; Get character
	mov	ebx,edi 	; Save offset of end
S32	stos	FBROWS_BUF[edi] ; Save character
	or	al,al		; Izit the end?
	jnz	short @B	; Jump if not

; Try to open file with no extension
	lea	esi,FBROWS_BUF	; File to open
	call	CMD_LOADFIL	; Return with CF significant
	jnc	short LOAD_SOURCE_CEXIT ; Exit if successful

; Try it with .C extension
	mov	DGROUP:[ebx].EDD,'C.' ; Terminate with .C\0\0
	lea	esi,FBROWS_BUF	; Filename
	call	CMD_LOADFIL	; Return with CF significant
	jnc	short LOAD_SOURCE_CEXIT ; Exit if successful

; Try it with .CPP extension
	mov	DGROUP:[ebx].EDD,'PPC.' ; Terminate with .CPP
	mov	DGROUP:[ebx+4].LO,0 ; Null termination
	lea	esi,FBROWS_BUF	; Filename
	call	CMD_LOADFIL	; Return with CF significant
	jnc	short LOAD_SOURCE_CEXIT ; Exit if successful

; Try it with .ASM extension
	mov	DGROUP:[ebx].EDD,'MSA.' ; Terminate with .ASM
	mov	DGROUP:[ebx+4].LO,0 ; Null termination
	lea	esi,FBROWS_BUF	; Filename
	call	CMD_LOADFIL	; Return with CF significant
;;;;;;;  jnc	 short LOAD_SOURCE_CEXIT ; Exit if successful

LOAD_SOURCE_CEXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOAD_SOURCE_COM endp		; End LOAD_SOURCE_COM procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_BLK module
