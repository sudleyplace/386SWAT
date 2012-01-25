;-----------------------------------------------------------------------
; DUALVGA.ASM	Copyright 1996 Ralf Brown
;
; Dual-VGA support (PCI bus)
;
; Version 0.93
; LastEdit: 11/26/96
;-----------------------------------------------------------------------

	INCLUDE AMIS.MAC

	@Startup 2,00         		; need DOS 2.00                     
					; this macro also takes care of declaring
					; all the segments in the required order

;-----------------------------------------------------------------------
;	configuration options
;

CHECK_WINDOWS     equ   0               ; nonzero to disable 2nd under Windows

IF 0
SWAPPING_HOTKEY	  equ	SCAN_F21	; scan code for swapping monitors
SWAPPING_SHIFTON  equ	0		; required shift states
SWAPPING_SHIFTOFF equ	0		; disallowed shift states
ELSE
SWAPPING_HOTKEY	  equ	SCAN_F12	; scan code for swapping monitors
SWAPPING_SHIFTON  equ	HK_RSHIFT or HK_RCTRL ; required shift states
SWAPPING_SHIFTOFF equ	HK_LSHIFT or HK_LCTRL ; disallowed shift states
ENDIF ;0/1

BLANKING_HOTKEY	  equ   SCAN_F11
BLANKING_SHIFTON  equ   HK_RSHIFT or HK_RCTRL ; required shift states
BLANKING_SHIFTOFF equ	HK_LSHIFT or HK_LCTRL ; disallowed shift states

;-----------------------------------------------------------------------
;
VERSION_NUM equ 005Dh	; v0.93
VERSION_STR equ "0.93"

;-----------------------------------------------------------------------
;
; useful macros
;
LODSB_ES MACRO
	DB 26h,0ACh	; LODSB ES:
	ENDM

;-----------------------------------------------------------------------
; Declare the additional segments we will use
;

BIOS_SEG SEGMENT AT 40h
	ORG 49h
video_data1_start label byte
	ORG 63h
video_base dw ?
	ORG 66h
video_data1_end	  label byte
video_data1_len equ $-video_data1_start+1

	ORG 84h
video_data2_start label byte
	ORG 8Ah
video_data2_end   label byte
video_data2_len equ $-video_data2_start+1

	ORG 0A8h
video_save_tbl_ptr dd ?

BIOS_SEG ENDS

;-----------------------------------------------------------------------
; Useful definitions
;
VIDEO_DISABLE_BIT equ 20h
VGA_REG 	  equ 3C4h
TICKS_PER_MINUTE equ 0444h

PCI_MECH1_ADDR	equ 0CF8h
PCI_MECH1_DATA	equ 0CFCh

PCI_MECH2_CFGSP	equ 0CF8h
PCI_MECH2_BUSNO equ 0CFAh

PCIREG_CMDREG	equ 0004h	; address of PCI command register
PCI_CMDREG_BITS	equ 00A7h	; IO/memory/master enable, VGA snooping enable

DPMS_STANDBY	equ 1
DPMS_SUSPEND	equ 2
DPMS_OFF	equ 4

;-----------------------------------------------------------------------
; Declare data structures
;
VIDEO_BIOS_DATA STRUC
 ?vbd_addr	dw ?		; mech#2 I/O port address
 ?vbd_busnum	db ?		; mech#2 bus number
 ?vbd_access	db ?		; pad to allow DWORD for mech#1 access key
 ?vbd_cursor	dw ?		; cursor position just prior to disabling
 ?vbd_int10	dd ?		; INT 10h handler to pass requests to
 ?vbd_vidstate	db 128 dup (?)	; for INT 10h/AH=12h/BL=35h
VIDEO_BIOS_DATA ENDS

;-----------------------------------------------------------------------
; Put the resident code into its own segment so that all the offsets are
; proper for the new location after copying it into a UMB or down into
; the PSP.
;
TSRcode@
start_TSRcode label byte
	.386

;-----------------------------------------------------------------------
;	data for the resident portion
;
blank_time	dw 0			; patched to actual timeout tick count
standby_time	dw 0
suspend_time	dw 0
off_time	dw 0
blanked		db 0
fastblank	db 0			; fast-blank in progress?
IF CHECK_WINDOWS
Windows_active	db 0
ENDIF ;CHECK_WINDOWS

active_disp	db 0
display_0	VIDEO_BIOS_DATA <>
display_1	VIDEO_BIOS_DATA <>

;-----------------------------------------------------------------------
;	in:	AX = command register bits to set
;		BX -> display info
;
set_display_state proc near
;-- default is configuration access mechanism 2 -- mech #1 is smaller, so it
;-- gets copied over this code if that is the active access mechanism
	ASSUME	DS:TGROUP
	push	eax
	push	dx
	mov	al,cs:[bx].?vbd_access	; open configuration space
	mov	dx,PCI_MECH2_CFGSP
	out	dx,al
	mov	al,cs:[bx].?vbd_busnum	; select proper PCI bus
	mov	dx,PCI_MECH2_BUSNO
	out	dx,al
	mov	dx,cs:[bx].?vbd_addr
	in	ax,dx
	and	ax,not PCI_CMDREG_BITS	; flip the 'enable' bits
	or	ax,cx
	out	dx,ax
	mov	al,00h			; close configuration space
	mov	dx,PCI_MECH2_CFGSP
	out	dx,al
	pop	dx
	pop	eax
	ret
set_display_state endp

;-----------------------------------------------------------------------

disable_display proc near
	ASSUME	DS:TGROUP
	push	cx
	push	eax
	; remember current cursor position
	mov	ah,03h			; get current cursor position
	int	10h
	mov	[bx].?vbd_cursor,dx
IF 0
	; rehook INT 10h
	mov	eax,dword ptr RESIDENT_CODE:ORIG_INT10h
	mov	[bx].?vbd_int10,eax
ENDIF ;0
	; disable display via BIOS
	push	es
	push	di
	mov	di,bx
	mov	ax,1202h		; disable active adapter
	mov	bl,35h
	push	cs
	pop	es
	push	dx
	lea	dx,[di].?vbd_vidstate
	pushf
	call	[di].?vbd_int10
	mov	bx,di
	pop	dx
	pop	di
	pop	es
	pop	eax
	xor	cx,cx
	call	set_display_state
	pop	cx
	ret
disable_display endp

;-----------------------------------------------------------------------

activate_display proc near
	ASSUME	DS:TGROUP
	; copy BIOS data from save area back into BIOS area
	push	eax
	push	dx
	push	cx
	mov	cx,PCI_CMDREG_BITS
	call	set_display_state
IF 0
	; rehook INT 10h
	mov	eax,[bx].?vbd_int10
	mov	dword ptr RESIDENT_CODE:ORIG_INT10h,eax
ENDIF ;0
	; enable display via BIOS
	push	bx
	push	es
	lea	dx,[bx].?vbd_vidstate
	mov	ax,1203h		; enable inactive adapter
	mov	bl,35h
	push	cs
	pop	es
	pushf
	call	dword ptr RESIDENT_CODE:ORIG_INT10h
	pop	es
	pop	bx
	; finally, update cursor position on screen
	mov	dx,[bx].?vbd_cursor
	mov	ah,2			; set cursor position
	int	10h
	pop	cx
	pop	dx
	pop	eax
	ret
activate_display endp

;-----------------------------------------------------------------------

swap_displays proc near
	ASSUME	DS:NOTHING
	push	ds
	push	cs
	pop	ds
	ASSUME	DS:TGROUP
	pushf
	push	bx
	cli
	cmp	active_disp,0
	je	short swap_to_display_1
swap_to_display_0:
	mov	bx,offset RESIDENT_CODE:display_1
	call	disable_display
	mov	bx,offset RESIDENT_CODE:display_0
	jmp short swap_displays_done
swap_to_display_1:
	mov	bx,offset RESIDENT_CODE:display_0
	call	disable_display
	mov	bx,offset RESIDENT_CODE:display_1
swap_displays_done:
	call	activate_display
	xor	active_disp,1
	pop	bx
	popf
	pop	ds
	ASSUME	DS:NOTHING
	ret
swap_displays endp

;-----------------------------------------------------------------------

set_video_state proc near
	ASSUME	DS:NOTHING
	call	swap_displays		; set the state of both displays
	call	set_video_state_1	;   by swapping and doing the call
	call	swap_displays		;   a second time
IF CHECK_WINDOWS
	cmp	Windows_active,0	; if Windows is running, only do the
	jne	short set_video_state_done ;   secondary display
	; fall through to set_video_state_1
ENDIF ;CHECK_WINDOWS
set_video_state_1:
	push	dx
	push	ax
	mov	dx,VGA_REG		; get index register location
	mov	al,1			; we want access to indexed reg #1
	out	dx,al
	inc	dx
	in	al,dx			; get current value of register #1
	dec	dx
	and	al,not VIDEO_DISABLE_BIT
	or	ah,al
	mov	al,1
	out	dx,al			; update register #1
	inc	dx
	mov	al,ah
	out	dx,al
	pop	ax
	pop	dx
set_video_state_done:
        ret
set_video_state endp

;-----------------------------------------------------------------------

set_power_state proc near
	ASSUME	DS:NOTHING
        call    swap_displays           ; set the state of both displays
	call	set_power_state_1	;   by swapping and doing the call
	call	swap_displays		;   a second time
IF CHECK_WINDOWS
	cmp	Windows_active,0	; if Windows is running, only do the
	jne	short set_power_state_done ;   secondary display
ENDIF ;CHECK_WINDOWS
set_power_state_1:
	push	ax
	push	bx
	mov	bh,ah
	mov	bl,01h
	mov	ax,4F10h
	int	10h
	pop	bx
	pop	ax
set_power_state_done:
	ret
set_power_state endp

;-----------------------------------------------------------------------

private proc near
	ASSUME	DS:NOTHING
	cmp	al,10h
	je	short func_10h
IF CHECK_WINDOWS
	cmp	Windows_active,0	; disable display swapping while
	jne	short unsupported_func	;   MS Windows is running
ENDIF ;CHECK_WINDOWS
	cmp	al,11h
	je	short func_11h
	cmp	al,12h
	je	short func_12h
	cmp	al,13h
	je	short func_13h
unsupported_func:
	mov	al,0			; unsupported function
	iret

func_10h:				; get active display
	mov	ah,active_disp
private_func_done:
	mov	al,0FFh			; (function supported)
	iret

func_11h:				; select display #0
        cmp     active_disp,0
	je	short private_func_done
private_swap:
	call	swap_displays
	jmp	short private_func_done

func_12h:				; select display #1
	cmp	active_disp,1
	je	short private_func_done
	jmp	private_swap

func_13h:				; hook secondary INT 10h

	jmp	private_func_done
private endp

;-----------------------------------------------------------------------

remove proc near
	ASSUME	DS:NOTHING
	cmp	active_disp,0
	je	short remove_done
	call	swap_displays
remove_done:
	mov	al,AMIS_UNINST_SAFE_OFF
	mov	bx,cs
	ret
remove endp

;-----------------------------------------------------------------------

get_shift_states proc near
	xor	ax,ax
	push	ds
	mov	ds,ax
	ASSUME	DS:NOTHING
	mov	ax,ds:[0417h]
	push	bx
	mov	bl,ds:[0496h]
	and	bl,0Ch			; mask all but RCtrl/RAlt flags
	and	ah,0F3h 		; mask out what will become RCtrl/RAlt
	or	ah,bl
	pop	bx
	pop	ds
	ASSUME	DS:NOTHING
	ret
get_shift_states endp

;-----------------------------------------------------------------------
; Declare the interrupt vectors hooked by the program, then set up the
; Alternate Multiplex Interrupt Spec handler
;
IF CHECK_WINDOWS
	HOOKED_INTS 10h,15h,1Ch,2Fh
ELSE
	HOOKED_INTS 10h,15h,1Ch
ENDIF ;CHECK_WINDOWS
	HOTKEYS	HK_INT15ENTRY
	HOTKEY	SWAPPING_HOTKEY,<SWAPPING_SHIFTON>,<SWAPPING_SHIFTOFF>,HK_NOCHAIN
	HOTKEY	BLANKING_HOTKEY,<BLANKING_SHIFTON>,<BLANKING_SHIFTOFF>,HK_NOCHAIN
	HOTKEYS_DONE
	ALTMPX	'Ralf B','DUALVGA',VERSION_NUM,'Dual-VGA Support',private,,,remove

;-----------------------------------------------------------------------
; Now the meat of the resident portion, the keyboard and timer tick
; interrupt handlers.
;
ISP_HEADER 1Ch,hw_reset_2Dh
	sti				; allow interrupts
	push	ax
	cmp	fastblank,0
	jz	short not_in_fastblank
	dec	fastblank
not_in_fastblank:
	cmp	word ptr RESIDENT_CODE:MAX_BLANK,0
	je	short no_blank
	dec	blank_time		; count down, and each time we hit
	jnz	short no_blank		; zero, force the video off
	mov	ah,VIDEO_DISABLE_BIT
	call	set_video_state
	jmp	short int1C_blanked
no_blank:
	cmp	standby_time,0
	je	short no_standby
	mov	ah,DPMS_STANDBY
	dec	standby_time
	jz	short int1C_setpower
no_standby:
	cmp	suspend_time,0
	je	short no_suspend
	mov	ah,DPMS_SUSPEND
	dec	suspend_time
	jz	short int1C_setpower
no_suspend:
	cmp	off_time,0
	je	short no_off
	dec	off_time
	jnz	short no_off
	mov	ah,DPMS_OFF
int1C_setpower:
	call	set_power_state
int1C_blanked:
	mov	blanked,1
no_off:
int1C_done:
	pop	ax
	jmp	ORIG_INT1Ch

;-----------------------------------------------------------------------
;

IF CHECK_WINDOWS
handle_Windows_init:
	pushf
	call	dword ptr TGROUP:ORIG_INT2Fh
	cmp	cx,0
	jne	short Windows_init_done
	mov	Windows_active,1
Windows_init_done:
	iret
ENDIF ;CHECK_WINDOWS

IF CHECK_WINDOWS
ISP_HEADER 2Fh,hw_reset_15h
	cmp	ax,1605h		; Windows init
	je	short handle_Windows_init
        cmp     ax,1606h                ; Windows shutdown
	jne	short INT2F_done
handle_Windows_exit:
	mov	Windows_active,0
INT2F_done:
	jmp	ORIG_INT2Fh
ENDIF ;CHECK_WINDOWS

;-----------------------------------------------------------------------

ISP_HEADER 15h
	cmp	ah,4Fh
	jne	short not_keystroke
	sti				; allow interrupts
					; keystroke, so unblank display
	cmp	fastblank,0		; skip unblanking if in fast-blank
	jnz	short in_fastblank
	cmp	blanked,0		; don't unblank unless currently blanked
	je	short no_unblank	; because of sparkles on some displays
	mov	ah,0
        call    set_video_state
	mov	blanked,0
	call	set_power_state
no_unblank:
	mov	blank_time,0		; patched with actual timeout count
MAX_BLANK equ word ptr ($-2)
	mov	standby_time,0		; patched with actual timeout count
MAX_STANDBY equ word ptr ($-2)
	mov	suspend_time,0		; patched with actual timeout count
MAX_SUSPEND equ word ptr ($-2)
	mov	off_time,0		; patched with actual timeout count
MAX_OFF equ word ptr ($-2)
in_fastblank:
	mov	ah,4Fh			; restore AH
	push	ax
	cmp	al,BLANKING_HOTKEY
	je	short maybe_fastblank
	cmp	al,SWAPPING_HOTKEY
	je	short maybe_swap
not_hotkey:
	pop	ax
	stc
not_keystroke:
int15_done:
	jmp	ORIG_INT15h

maybe_fastblank:
	ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	call	get_shift_states
	test	ax,BLANKING_SHIFTOFF
	jnz	short not_hotkey
	and	ax,BLANKING_SHIFTON
	cmp	ax,BLANKING_SHIFTON
	jne	short not_hotkey
	mov	fastblank,(3*91)/5	; disable unblanking for 3 seconds
	mov	blank_time,4		; blank in a quarter second, then
	mov	off_time,2*18		;   go to "off" in two seconds
	xor	ax,ax
	mov	standby_time,ax 	; skip standby mode, as well as
	mov	suspend_time,ax 	;   suspend mode
	jmp	short handled_hotkey

maybe_swap:
	ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	call	get_shift_states
	test	ax,SWAPPING_SHIFTOFF
	jnz	short not_hotkey
	and	ax,SWAPPING_SHIFTON
	cmp	ax,SWAPPING_SHIFTON
	jne	short not_hotkey
	call	swap_displays
handled_hotkey:
	pop	ax
	clc				; swallow hotkey
	retf	2

;-----------------------------------------------------------------------
;  hook into INT 10h in order to direct BIOS requests at the proper BIOS
;  when two different video adapters are used
;

ISP_HEADER 10h
	cmp	ah,12h
	jne	short int10_done
	cmp	bl,35h
	jne	short int10_done
	cmp	al,02h
	jb	short int10_done
	cmp	al,03h
	push	bx
	je	short enable_inactive_video
	ja	short int10_35_done
disable_active_video:
	cmp	active_disp,0
	mov	bx,offset RESIDENT_CODE:display_0
	je	short disable_active
	mov	bx,offset RESIDENT_CODE:display_1
disable_active:
	call	disable_display
	jmp	short int10_35_done
enable_inactive_video:
	cmp	active_disp,0
	mov	bx,offset RESIDENT_CODE:display_1
	je	short enable_inactive
	mov	bx,offset RESIDENT_CODE:display_0
enable_inactive:
	call	activate_display
int10_35_done:
	pop	bx
int10_done:
	jmp	ORIG_INT10h

;-----------------------------------------------------------------------

TSRcodeEnd@

;-----------------------------------------------------------------------

_TEXT SEGMENT 'CODE'
	ASSUME cs:_TEXT,ds:NOTHING,es:NOTHING,ss:NOTHING
		.8086

banner	   db 'DUALVGA v',VERSION_STR,'  Copyright 1996 Ralf Brown',13,10,'$'
usage_msg  db 'Usage:',9,'DUALVGA I <b> <s> <u> <o>',13,10
	   db 9,9,9,"install to blank after 'b' minutes, go to standby after",13,10
	   db 9,9,9,"'s' minutes, suspend after 'u', and Off mode after 'o'",13,10
	   db 9,9,9,"(default 2,12,15,20; any value set to 0 disables that",13,10
	   db 9,9,9,"setting)",13,10
	   db 9,'DUALVGA Dn',9,'select active display (n=0,1)',13,10
	   db 9,'DUALVGA R',9,'remove from memory',13,10
	   db "$"
no_PCI_msg         db "No PCI BIOS found!",13,10,"$"
no_PCI_acc_msg	   db "Unable to access PCI configuration registers directly."
		   db 13,10,"$"
need_VGA_msg	   db "This program requires dual PCI-bus VGA displays.",13,10
		   db "$"
extra_VGAs_msg	   db "Warning: more than two VGA adapters.  Only the first and",13,10
		   db " last adapters will be managed.",13,10,"$"
installed_msg      db "Installed.",13,10,"$"
already_inst_msg   db "Different version already installed.",13,10,"$"
timeout_changed_msg db "Blanking time changed.",13,10,"$"
cant_remove_msg    db "Can't remove from memory.",13,10,"$"
not_installed_msg  db "DUALVGA is not installed.",13,10,"$"
bad_display_msg	   db "Invalid display number.",13,10,"$"
display_selected_msg db "Display selected.",13,10,"$"
uninstalled_msg    db "Removed.",13,10,"$"

timeout		dw 2*444h		; two minutes by default
standby		dw 12*444h		; twelve minutes by default
suspend		dw 15*444h		; fifteen minutes by default
off		dw 20*444h		; twenty minutes by default

access_mech	db 2
num_buses	db 0

;----------------------------------------------------------------------

;-- configuration access mechanism 1 -- will be copied over config_mech_2 if
;-- needed
config_mech_1 proc near
	.386
	ASSUME	DS:TGROUP
 	mov	eax,dword ptr cs:[bx].?vbd_addr
	mov	dx,PCI_MECH1_ADDR
	out	dx,eax
 	mov	dx,PCI_MECH1_DATA
	in	ax,dx
	and	ax,not PCI_CMDREG_BITS
	or	ax,cx
	out	dx,ax
	pop	dx
	pop	eax
	ret
config_mech_1 endp

config_mech_1_len equ $-config_mech_1

;----------------------------------------------------------------------

get_PCI_BIOS_info proc near
	.386
	ASSUME	DS:_TEXT,ES:_INIT
	mov	ax,0B101h		; PCI BIOS installation check
	int	1Ah
	cmp	ah,00h
	je	short have_PCI_BIOS
no_PCI_BIOS:
	mov	dx,offset _TEXT:no_PCI_msg
fatal_PCI_error:
	mov	ah,9
	int	21h			; display error message
	mov	ax,4C01h		; terminate immediately
	int	21h
have_PCI_BIOS:
	cmp	edx,' ICP'		; is it really a PCI BIOS?
	jne	short no_PCI_BIOS
	mov	num_buses,cl
	;
	; check which access mechanisms are supported
	mov	dx,offset _TEXT:no_PCI_acc_msg
	test	al,1			; access mechanism #1 supported?
	jnz	short acc_mech_1
	test	al,2
	jz	short fatal_PCI_error
acc_mech_2:
	mov	al,2
	jmp	short set_acc_mech
acc_mech_1:
	mov	al,1
set_acc_mech:
	mov	access_mech,al
	cmp	al,1
	jne	short acc_mech_set
	push	si
	push	di
	mov	si,offset _TEXT:config_mech_1
	mov	di,offset _INIT:set_display_state
	mov	cx,config_mech_1_len
	; ES happens to point at resident code already
	rep	movsb
	pop	di
	pop	si
acc_mech_set:
	ret
get_PCI_BIOS_info endp

;----------------------------------------------------------------------
;	in: BH = bus number
;	    BL = device/func number
;	    DX = PCI register number
;	out: EAX = device address for use by resident code
;
convert_device_address proc near
	.386
	and	dx,00FFh
	mov	eax,00800000h
	mov	ax,bx
	shl	eax,8
	cmp	access_mech,2
	je	short convert_device_addr_2
	mov	al,dl
	ret
convert_device_addr_2:
	shr	ah,3
	and	ax,0F00h
	or	ax,0C000h
	mov	al,dl
	push	ebx
	and	bl,07h			; get function number
	shl	ebx,24
	or	eax,ebx			; add function number to access key
	pop	ebx
	ret
convert_device_address endp

;----------------------------------------------------------------------

scan_for_VGAs proc near
	.386
	push	edx
	push	ecx
	push	ebx
	push	eax
	push	di
	xor	di,di			; which display was active?
	push	si
	xor	si,si			; step through from index 0 to N
scan_VGA_loop:
	mov	ax,0B103h		; find PCI class code
	mov	ecx,00030000h		; scan for display/VGA
	int	1Ah
	cmp	ah,86h			; no more matching devices?
	je	short scan_VGA_done
	; BH = bus number, BL = device/func number
	push	bx
	push	di
	mov	ax,0B109h		; get PCI config register word
	mov	di,0004h
	int	1Ah
	pop	di
	test	cx,0003h		; is I/O or memory enabled?
	jz	short VGA_disabled
	mov	di,si
VGA_disabled:
	pop	bx
	mov	dx,PCIREG_CMDREG
	call	convert_device_address
	mov	bx,offset _INIT:display_0
	cmp	si,0
	je	short scan_VGA_2
	mov	bx,offset _INIT:display_1
scan_VGA_2:
	mov	dword ptr _INIT:[bx].?vbd_addr,eax
	inc	si			; found another VGA card
	jmp	scan_VGA_loop
scan_VGA_done:
	cmp	si,2
	je	short scan_VGA_OK
	mov	dx,offset _TEXT:extra_VGAs_msg
	ja	short scan_VGA_wrongnum
	mov	dx,offset _TEXT:need_VGA_msg
scan_VGA_wrongnum:
	mov	ah,9
	int	21h
scan_VGA_OK:
	test	di,di			; is other than first card active?
	jz	short scan_VGA_exit
	; swap display addresses
	mov	eax,dword ptr _INIT:display_0.?vbd_addr
	xchg	eax,dword ptr _INIT:display_1.?vbd_addr
	mov	dword ptr _INIT:display_0.?vbd_addr,eax
scan_VGA_exit:
	pop	si
	pop	di
	pop	eax
	pop	ebx
	pop	ecx
	pop	edx
	ret
scan_for_VGAs endp

;----------------------------------------------------------------------

cmdline_atoi proc near
	.8086
	lodsb_es
	cmp	al,0
	je	short atoi_abort
	cmp	al,' '
	jbe	short cmdline_atoi
	sub	al,'0'
	jb	short atoi_abort
	cmp	al,9
	ja	short atoi_abort
	mov	ah,0
	push	dx
	push	cx
	push	bx
	mov	cx,ax
atoi_loop:
	lodsb_es
	sub	al,'0'
	jb	short atoi_done
	cmp	al,9
	ja	short atoi_done
	xchg	ax,cx
	mov	bx,10
	mul	bx
	add	cx,ax
	jmp	short atoi_loop
atoi_done:
	mov	ax,cx
	pop	bx
	pop	cx
	pop	dx
	clc
	ret
atoi_abort:
	dec	si			; unget the last character
	xor	ax,ax
	stc
	ret
cmdline_atoi endp

;----------------------------------------------------------------------
;	in:	ES:BX
;		ES:DI
;		DS:DX -> WORDs to be updated with new timeout count
;
get_timeout proc near
	ASSUME	DS:_TEXT,ES:_INIT
	call	cmdline_atoi
	jc	short get_timeout_done
	push	dx
        mov     cx,TICKS_PER_MINUTE     ; convert number of minutes into ticks
	mul	cx
	mov	_INIT:[bx],ax		; and remember for later, both in
	mov	_INIT:[di],ax		;   what will become the resident part
        pop     bx
	mov	_TEXT:[bx],ax		; and in the transient portion
get_timeout_done:
	ret
get_timeout endp

;----------------------------------------------------------------------

	@Startup2	Y
	push	ds
	pop	es
	ASSUME	ES:_INIT
	push	cs
	pop	ds
	ASSUME	DS:_TEXT
	;
	; say hello 
	;
	DISPLAY_STRING banner
	mov	bx,1000h		; set memory block to 64K
	mov	ah,4Ah
	int	21h
	mov	si,81h			; SI -> command line
	cld				; ensure proper direction for string ops
cmdline_loop:
	lodsb_es
	cmp	al,' '			; skip blanks and tabs on commandline
	je	short cmdline_loop
	cmp	al,9
	je	short cmdline_loop
	and	al,0DFh			; force to uppercase
	cmp	al,'I'
	je	short installing
	cmp	al,'R'
	je	short removing
	cmp	al,'D'
	jne	short usage
	jmp	select_display
usage:
	mov	dx,offset _TEXT:usage_msg
	jmp     exit_with_error

removing:
	UNINSTALL cant_uninstall
	;
	; force video back on in case we are called from a batch file while
	; the screen is blanked
	;
	mov	dx,VGA_REG
	mov	al,1
	out	dx,al
	inc	dx
	in	al,dx
	dec	dx
	and	al,not VIDEO_DISABLE_BIT
	mov	ah,al
	mov	al,1
	out	dx,al
	inc	dx
	mov	al,ah
	out	dx,al
	;
	; finally, announce that the resident part has been removed
	;
	push	cs
	pop	ds
	ASSUME	DS:_TEXT
	DISPLAY_STRING uninstalled_msg
successful_exit:
        mov     ax,4C00h
	int	21h

installing:
	mov	bx,offset _INIT:blank_time
	mov	di,offset _INIT:MAX_BLANK
	mov	dx,offset _TEXT:timeout
	call	get_timeout
	mov	bx,offset _INIT:standby_time
	mov	di,offset _INIT:MAX_STANDBY
	mov	dx,offset _TEXT:standby
	call	get_timeout
	mov	bx,offset _INIT:suspend_time
	mov	di,offset _INIT:MAX_SUSPEND
	mov	dx,offset _TEXT:suspend
	call	get_timeout
	mov	bx,offset _INIT:off_time
	mov	di,offset _INIT:MAX_OFF
	mov	dx,offset _TEXT:off
	call	get_timeout
	call	get_PCI_BIOS_info
	mov	ax,1A00h		; get display combination code
	int	10h
	cmp	al,1Ah			; supported? (i.e. VGA present?)
	mov	dx,offset _TEXT:need_VGA_msg
	jne	short exit_with_error
	call	scan_for_VGAs
	;
	; place any necessary pre-initialization here
	;
	push	ds
	xor	ax,ax
	mov	ds,ax
	ASSUME	DS:NOTHING
	mov	ax,word ptr ds:[0040h]	; get INT 10h and store in TSR
	mov	_INIT:word ptr display_0.?vbd_int10,ax
	mov	_INIT:word ptr display_1.?vbd_int10,ax
	mov	ax,word ptr ds:[0042h]	; get INT 10h and store in TSR
	mov	_INIT:word ptr display_0.?vbd_int10+2,ax
	mov	_INIT:word ptr display_1.?vbd_int10+2,ax
	pop	ds
	ASSUME	DS:_TEXT
	;
	;
	INSTALL_TSR ,BEST,,inst_patch,already_installed

cant_uninstall:
	mov	dx,offset _TEXT:cant_remove_msg
exit_with_error:
	mov	ah,9
	int	21h
	mov	ax,4C01h
	int	21h

already_installed:
	cmp	cx,VERSION_NUM		; same version installed?
	jne	short wrong_version
	mov	al,0			; request signature string
	int	2Dh
	mov	es,dx			; ES -> resident code
	ASSUME	ES:TGROUP
	mov	ax,timeout
	mov	blank_time,ax
	mov	RESIDENT_CODE:MAX_BLANK,ax
	mov	ax,standby
	mov	standby_time,ax
	mov	RESIDENT_CODE:MAX_STANDBY,ax
	mov	ax,suspend
	mov	suspend_time,ax
	mov	RESIDENT_CODE:MAX_SUSPEND,ax
	mov	ax,off
	mov	off_time,ax
	mov	MAX_OFF,ax
	DISPLAY_STRING timeout_changed_msg
	jmp	successful_exit

wrong_version:
	ASSUME	ES:NOTHING
	mov	dx,offset _TEXT:already_inst_msg
	jmp 	exit_with_error

inst_patch:
	DISPLAY_STRING installed_msg
	ret

;----------------------------------------------------------------------

select_display proc near
	IF_INSTALLED select_display_1
	mov	dx,offset _TEXT:not_installed_msg
select_display_error:
	jmp	exit_with_error

select_display_1:
	; AH=multiplex number
	lodsb_es			; get desired display number
	mov	dx,offset _TEXT:bad_display_msg
	sub	al,'0'
	jb	short select_display_error
	cmp	al,1
	ja	short select_display_error
	add	al,11h
	int	2Dh
	DISPLAY_STRING display_selected_msg
	jmp	successful_exit
select_display endp

_TEXT ENDS

     end INIT

