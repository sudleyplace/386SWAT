;-----------------------------------------------------------------------
; AMIPOPUP.ASM	Public Domain 1993 Ralf Brown
;		You may do with this software whatever you want, but
;		common courtesy dictates that you not remove my name
;		from it.
;
; code to handle a TSRs popup hotkey
;
; Version 0.93
; LastEdit: 1/22/96
;-----------------------------------------------------------------------

__DEFAULT_MODEL__ equ __TINY__
	INCLUDE AMIS.MAC

;-----------------------------------------------------------------------

LOCAL_STACK_SIZE equ 128	; size of local stack in bytes

;-----------------------------------------------------------------------

TSRgroup@ byte

;-----------------------------------------------------------------------
; Put the resident code into its own segment so that all the offsets are
; proper for the new location after copying it into a UMB or down into
; the PSP.
;
TSRcode@ byte

extrn TSR_MAIN:near,TSR_SHUTDOWN:near
extrn TSR_SAVE_SCREEN:near,TSR_FRAMED_WINDOW:near,TSR_RESTORE_SCREEN:near
extrn TSR_INT1B_HANDLER:far,TSR_INT23_HANDLER:far,TSR_INT24_HANDLER:far

;-----------------------------------------------------------------------
; TSR's initialized data storage
;
TSRdata@
disk_TSR_busy label word	; allow both to be tested in one operation
public $AMIS$DISK_BUSY
$AMIS$DISK_BUSY		db 0
TSR_activated		db 0
public $AMIS$WANT_POPUP
$AMIS$WANT_POPUP	db 0
public $AMIS$WANT_SHUTDOWN
$AMIS$WANT_SHUTDOWN	db 0
public $AMIS$POPUP_INT28
$AMIS$POPUP_INT28	db 0

errorinfo	DPL <>


TSRdataEnd@

;-----------------------------------------------------------------------
; TSR's uninitialized data storage
;
TSRbss@
INDOS_PTR	dd ?
CRITERR_PTR	dd ?

interrupted_DTA	dd ?
interrupted_PSP dw ?
interrupted_SP	dw ?
interrupted_SS	dw ?

local_stack 	db LOCAL_STACK_SIZE dup (?)
local_stack_bottom label byte

TSRbssEnd@

;-----------------------------------------------------------------------
; requires DS = TGROUP and interrupts enabled on entry; may destroy BX
;
public $AMIS$POPUP
$AMIS$POPUP proc near
	mov	TSR_activated,1		; yes, we are now active
	mov	$AMIS$WANT_POPUP,0	; and we are finally popping up
	;
	; switch to a local stack so that we are assured of enough stack space
	;
	push	ax
	mov	interrupted_SS,ss
	mov	interrupted_SP,sp
	mov	ax,cs
	cli
	mov	ss,ax			; switch stack
	ASSUME	SS:TGROUP
	mov	sp,offset TGROUP:local_stack_bottom
	sti
	push	es
	push	di
	push	si
	push	bp
	push	dx
	push	cx
	push	bx
	;
	; switch to our own PSP and store current DTA and extended error info
	;
	mov	ah,51h
	int	21h			; get PSP of interrupted program
	mov	interrupted_PSP,bx
	mov	errorinfo.dpl_pid,bx
	mov	bx,cs
	mov	ah,50h			; set PSP to our own
	int	21h
	mov	ah,2Fh			; get DTA
	int	21h
	ASSUME	ES:NOTHING
	mov	word ptr interrupted_DTA,bx
	mov	word ptr interrupted_DTA+2,es
	mov	ah,59h
	xor	bx,bx
	int	21h
	ASSUME	ES:NOTHING
	mov	errorinfo.dpl_ax,ax
	mov	errorinfo.dpl_bx,bx
	mov	errorinfo.dpl_cx,cx
	mov	errorinfo.dpl_di,di
	mov	errorinfo.dpl_es,es
	GRAB_INTERRUPT 1Bh,TSR_INT1B_HANDLER
	GRAB_INTERRUPT 23h,TSR_INT23_HANDLER
	GRAB_INTERRUPT 24h,TSR_INT24_HANDLER
	mov	al,0
	xchg	al,$AMIS$WANT_SHUTDOWN	; get and clear shutdown flag
	or	al,al			; was it set?
	jz	do_popup		; if not, regular popup
	call	TSR_SHUTDOWN
	jmp short popup_done
do_popup:
	call	TSR_SAVE_SCREEN
	call	TSR_FRAMED_WINDOW
	call	TSR_MAIN		; the actual guts of the TSR
	call	TSR_RESTORE_SCREEN
popup_done:
	RESTORE_INTERRUPT 1Bh
	RESTORE_INTERRUPT 23h
	RESTORE_INTERRUPT 24h
	;
	; restore the original PSP, DTA, and extended error info
	;
	mov	bx,interrupted_PSP
	mov	ah,50h			; set PSP back to stored value
	int	21h
	push	ds
	lds	dx,interrupted_DTA
	ASSUME	DS:NOTHING
	mov	ah,1Ah			; set DTA back to stored value
	int	21h
	pop	ds			; restore DS
	ASSUME	DS:TGROUP
	mov	dx,offset TGROUP:errorinfo
	mov	ax,5D0Ah		; set extended error information
	int	21h
	pop	bx
	pop	cx
	pop	dx
	pop	bp
	pop	si
	pop	di
	pop	es
	;
	; finally, switch back to original stack
	;
	cli
	mov	ss,interrupted_SS
	ASSUME	SS:NOTHING
	mov	sp,interrupted_SP
	sti
	pop	ax
	mov	TSR_activated,0		; no longer popped up, so OK to pop again
	ret
$AMIS$POPUP endp

;-----------------------------------------------------------------------

public $AMIS$ATTEMPT_POPUP
$AMIS$ATTEMPT_POPUP proc near
	ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	mov	$AMIS$WANT_POPUP,1		; remember that a popup was requested
	;; fall through to $AMIS$TRY_POPUP ;;
$AMIS$ATTEMPT_POPUP endp

public $AMIS$TRY_POPUP
$AMIS$TRY_POPUP proc near
	ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	pushf				; remember current flags
	sti				; OK to interrupt
	cmp	$AMIS$WANT_POPUP,0
	je	try_popup_done
	cmp	disk_TSR_busy,0		; check whether disk busy or popped up
	jnz	try_popup_done		; can't popup if either flag set
	push	ds
	push	bx
	lds	bx,INDOS_ptr		; check InDOS flag
	ASSUME	DS:NOTHING
	cmp	byte ptr [bx],1
	jb	try_popup_1		; if zero, DOS is probably idle
	ja	try_popup_2		; if not 0 or 1, DOS is definitely busy
	cmp	$AMIS$POPUP_INT28,0	; if activated via INT 28, INDOS flag is
	jz	try_popup_2		; allowed to be 1 rather than 0
try_popup_1:
	lds	bx,CRITERR_ptr		; InDOS says DOS is idle, but it might
	ASSUME	DS:NOTHING		;   be in the critical error handler
	cmp	byte ptr [bx],0		;   so check the CritErr flag
	jne	try_popup_2		; can't popup if in critical error
	push	cs
	pop	ds			; restore DS
	ASSUME	DS:TGROUP
	call	$AMIS$POPUP		; whew, we made it... we can pop up now
try_popup_2:
	ASSUME	DS:NOTHING
	pop	bx			; restore registers
	pop	ds
	ASSUME	DS:NOTHING
try_popup_done:
	popf				; restore flags
	ret
$AMIS$TRY_POPUP endp

;-----------------------------------------------------------------------


TSRcodeEnd@


_TEXT SEGMENT PUBLIC 'CODE'
	ASSUME cs:_TEXT,ds:NOTHING,es:NOTHING,ss:NOTHING

IFDEF __TINY__
extrn TGROUP@:word
ENDIF

;-----------------------------------------------------------------------
; get and store pointers to DOS busy flags
;
public $AMIS$GET_DOS_PTRS
$AMIS$GET_DOS_PTRS proc DIST
	mov	ah,34h			; get address of InDOS flag
	int	21h
	ASSUME	ES:NOTHING
	mov	ds,TGROUP@
	ASSUME	DS:TGROUP
	mov	word ptr TGROUP:INDOS_ptr,bx
	mov	word ptr TGROUP:INDOS_ptr+2,es
	push	ds
	mov	ax,5D06h		; get address of CriticalError flag
	int	21h
	ASSUME	DS:NOTHING
	mov	dx,ds
	pop	ds
	ASSUME	DS:TGROUP
	mov	word ptr TGROUP:CRITERR_ptr+2,dx
        mov     word ptr TGROUP:CRITERR_ptr,si
	ret
$AMIS$GET_DOS_PTRS endp

;-----------------------------------------------------------------------

_TEXT ENDS

	END
