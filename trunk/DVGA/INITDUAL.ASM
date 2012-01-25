;-----------------------------------------------------------------------
; INITDUAL.ASM	Copyright 1996 Ralf Brown
;
; Dual-VGA support (PCI bus), ROM initialization
;
; Version 0.90
; LastEdit: 6/2/96
;-----------------------------------------------------------------------


	INCLUDE AMIS.MAC

;-----------------------------------------------------------------------
;
VERSION_NUM equ 005Ah	; v0.90
VERSION_STR equ "0.90"

;-----------------------------------------------------------------------
; Useful definitions
;
PCI_MECH1_ADDR	equ 0CF8h
PCI_MECH1_DATA	equ 0CFCh

PCI_MECH2_CFGSP equ 0CF8h
PCI_MECH2_BUSNO equ 0CFAh

PCIREG_CMDREG	equ 0004h	; address of PCI command register
PCI_CMDREG_BITS equ 00A7h	; IO/memory/master enable, VGA snooping enable

;-----------------------------------------------------------------------
; Declare data structures
;
VIDEO_BIOS_DATA STRUC
 ?vbd_addr	dw ?		; mech#2 I/O port address
 ?vbd_busnum	db ?		; mech#2 bus number
 ?vbd_access	db ?		; pad to allow DWORD for mech#1 access key
 ?vbd_cursor	dw ?		; cursor position just prior to disabling
 ?vbd_vidstate	db 128 dup (?)	; for INT 10h/AH=12h/BL=35h
VIDEO_BIOS_DATA ENDS

;-----------------------------------------------------------------------

VIDEO_BIOS segment at 0C000h
	org 3
video_init label far

VIDEO_BIOS ends

;-----------------------------------------------------------------------

CODE segment public byte 'code'
	ASSUME	CS:CODE,DS:NOTHING,ES:NOTHING,SS:NOTHING

	DEVICE_HEADER ,DEVATTR_CHAR,CODE:strat,CODE:intrpt,'$INITVGA'

;-----------------------------------------------------------------------
;	data for the resident portion
;
devhdr		dd ?
cfg_mech	db 2			; PCI configuration access mechanism #
active_disp	db 0
display_0	VIDEO_BIOS_DATA <>
display_1	VIDEO_BIOS_DATA <>
stackptr	dd ?

IVT		db 1024 dup (?)

banner		   db 'INITDUAL v',VERSION_STR,'  Copyright 1996 Ralf Brown'
		   db 13,10,'$'
no_PCI_msg	   db "No PCI BIOS found!",13,10,"$"
no_PCI_acc_msg	   db "Unable to access PCI configuration registers directly."
		   db 13,10,"$"
need_VGA_msg	   db "This program requires dual PCI-bus VGA displays.",13,10
		   db "$"
extra_VGAs_msg	   db "Warning: more than two VGA adapters.  Only the first and",13,10
		   db " last adapters will be managed.",13,10,"$"

;-----------------------------------------------------------------------
;	in:	AX = command register bits to set
;		BX -> display info
;
set_display_state proc near
	.386
	ASSUME	DS:CODE
	push	eax
	push	dx
	cmp	cfg_mech,2
	je	short config_mech_2
;-- configuration access mechanism 1
config_mech_1:
	mov	eax,dword ptr cs:[bx].?vbd_addr
	mov	dx,PCI_MECH1_ADDR
	out	dx,eax
	mov	dx,PCI_MECH1_DATA
	in	ax,dx
	and	ax,not PCI_CMDREG_BITS
	or	ax,cx
	out	dx,ax
	xor	eax,eax 		; close configuration space again
	mov	dx,PCI_MECH1_ADDR
	out	dx,eax
	jmp	short set_display_state_done
;-- configuration access mechanism 2
config_mech_2:
	mov	al,CODE:[bx].?vbd_access ; open configuration space
	mov	dx,PCI_MECH2_CFGSP
	out	dx,al
	mov	al,CODE:[bx].?vbd_busnum ; select proper PCI bus
	mov	dx,PCI_MECH2_BUSNO
	out	dx,al
	mov	dx,CODE:[bx].?vbd_addr
	in	ax,dx
	and	ax,not PCI_CMDREG_BITS	; flip the 'enable' bits
	or	ax,cx
	out	dx,ax
	mov	al,00h			; close configuration space
	mov	dx,PCI_MECH2_CFGSP
	out	dx,al
set_display_state_done:
	pop	dx
	pop	eax
	ret
set_display_state endp

;-----------------------------------------------------------------------

disable_display proc near
	ASSUME	DS:CODE
	push	cx
	push	eax
	; remember current cursor position
	push	bx
	mov	ah,03h			; get current cursor position
	int	10h
	pop	bx
	mov	[bx].?vbd_cursor,dx
	; disable display via BIOS
IF 0 ;!!!
	push	es
	push	bx
	push	dx
	push	cs
	pop	es
	ASSUME	ES:CODE
	lea	dx,[bx].?vbd_vidstate
	mov	ax,1202h		; disable active adapter
	mov	bl,35h
	int	10h
	pop	dx
	pop	bx
	pop	es
	ASSUME	ES:NOTHING
ENDIF ;0
	pop	eax
	xor	cx,cx
	call	set_display_state
	pop	cx
	ret
disable_display endp

;-----------------------------------------------------------------------

activate_display proc near
	ASSUME	DS:CODE
	; copy BIOS data from save area back into BIOS area
	push	eax
	push	dx
	push	cx
	mov	cx,PCI_CMDREG_BITS
	call	set_display_state
	cmp	active_disp,0
	je	activate_display_1
IF 0 ;!!!
	; enable display via BIOS
	push	bx
	push	es
	lea	dx,[bx].?vbd_vidstate
	mov	ax,1203h		; enable inactive adapter
	mov	bl,35h
	push	cs
	pop	es
	int	10h
	pop	es
	pop	bx
ENDIF ;0
activate_display_1:
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
	ASSUME	DS:CODE
	pushf
	push	bx
	cli
	cmp	active_disp,0
	je	short swap_to_display_1
swap_to_display_0:
	mov	bx,offset CODE:display_1
	call	disable_display
	mov	bx,offset CODE:display_0
	call	activate_display
	jmp short swap_displays_done
swap_to_display_1:
	mov	bx,offset CODE:display_0
	call	disable_display
	mov	bx,offset CODE:display_1
	call	activate_display
swap_displays_done:
	xor	active_disp,1
	pop	bx
	popf
	ret
swap_displays endp

;----------------------------------------------------------------------

clrscr proc near
	push	dx
	push	cx
	push	bx
	push	ax
	mov	bh,7			; attribute
	mov	cx,0			; upper left corner
	mov	dx,184Fh		; lower right corner
	mov	ax,0600h
	push	bp
	int	10h			; clear the screen
	pop	bp
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	ret
clrscr endp

;----------------------------------------------------------------------

print_string proc near
	ASSUME	DS:CODE
	push	bx
	mov	bx,dx
print_string_loop:
	mov	al,[bx]
	inc	bx
	cmp	al,'$'
	je	print_string_done
	push	bx
	mov	ah,0Eh			; TTY output
	mov	bx,7			;   page 0, white on black
	int	10h
	pop	bx
	jmp	print_string_loop
print_string_done:
	pop	bx
	ret
print_string endp

;----------------------------------------------------------------------

get_PCI_BIOS_info proc near
	.386
	ASSUME	DS:CODE,ES:NOTHING
	mov	ax,0B101h		; PCI BIOS installation check
	int	1Ah
	cmp	ah,00h
	je	short have_PCI_BIOS
no_PCI_BIOS:
	mov	dx,offset CODE:no_PCI_msg
fatal_PCI_error:
	call	print_string
	stc
	ret
have_PCI_BIOS:
	cmp	edx,' ICP'              ; is it really a PCI BIOS?
	jne	no_PCI_BIOS
	;
	; check which access mechanisms are supported
	mov	dx,offset CODE:no_PCI_acc_msg
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
	mov	cfg_mech,al
	clc
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
	ASSUME	DS:CODE
	and	dx,00FFh
	mov	eax,00800000h
	mov	ax,bx
	shl	eax,8
	cmp	cfg_mech,2
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
	or	eax,ebx 		; add function number to access key
	pop	ebx
	ret
convert_device_address endp

;----------------------------------------------------------------------

scan_for_VGAs proc near
	.386
	ASSUME	DS:CODE
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
	mov	bx,offset CODE:display_0
	test	si,si
	je	short scan_VGA_2
	mov	bx,offset CODE:display_1
scan_VGA_2:
	mov	dword ptr CODE:[bx].?vbd_addr,eax
	inc	si			; found another VGA card
	jmp	scan_VGA_loop
scan_VGA_done:
	cmp	si,2
	je	short scan_VGA_OK
	mov	dx,offset CODE:extra_VGAs_msg
	ja	short scan_VGA_wrongnum
	mov	dx,offset CODE:need_VGA_msg
scan_VGA_wrongnum:
	call	print_string
scan_VGA_OK:
	test	di,di			; is other than first card active?
	jz	short scan_VGA_exit
	; swap display addresses
	mov	eax,dword ptr CODE:display_0.?vbd_addr
	xchg	eax,dword ptr CODE:display_1.?vbd_addr
	mov	dword ptr CODE:display_0.?vbd_addr,eax
scan_VGA_exit:
	pop	si
	pop	di
	pop	eax
	pop	ebx
	pop	ecx
	pop	edx
	ret
scan_for_VGAs endp

;-----------------------------------------------------------------------

save_IVT proc near
	ASSUME	DS:CODE
	push	ds
	push	es
	push	di
	push	si
	push	cs
	pop	es
	ASSUME	ES:CODE
	mov	di,offset CODE:IVT
	xor	ax,ax
	mov	ds,ax
	ASSUME	DS:NOTHING
	xor	si,si
	mov	cx,size IVT / 2
	cld
	rep	movsw
	pop	si
	pop	di
	pop	es
	ASSUME	ES:NOTHING
	pop	ds
	ASSUME	DS:CODE
	ret
save_IVT endp

;-----------------------------------------------------------------------

restore_IVT proc near
	ASSUME	DS:CODE
	push	es
	push	di
	push	si
	mov	si,offset CODE:IVT
	xor	ax,ax
	mov	es,ax
	ASSUME	ES:NOTHING
	xor	di,di
	mov	cx,size IVT / 2
	cld
	rep	movsw
	pop	si
	pop	di
	pop	es
	ASSUME	ES:NOTHING
	ret
restore_IVT endp

;-----------------------------------------------------------------------

strat proc far
	ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	mov	word ptr devhdr,bx
	mov	word ptr devhdr+2,es
	ret
strat endp

;-----------------------------------------------------------------------

intrpt proc far
	ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	push	es
	push	ds
	push	bx
	push	ax
	push	cs
	pop	ds
	ASSUME	DS:CODE
	les	bx,devhdr
	ASSUME	ES:NOTHING
	cmp	byte ptr es:[bx+2],0	; is this an initialization call?
	mov	ax,8103h		; done, but error: unknown command
	jne	short exit
	mov	dx,offset CODE:banner
	call	print_string
	call	get_PCI_BIOS_info
	mov	ax,8101h		; indicate error: unsupported
	jc	short exit		;   if we couldn't find PCI BIOS
	mov	word ptr stackptr,sp
	mov	word ptr stackptr+2,ss
	mov	ax,cs
	mov	ss,ax
	mov	sp,offset CODE:tempstack_bot
	pushf
	push	gs
	push	fs
	push	es
	push	ds
	pushad
	call	scan_for_VGAs
	call	swap_displays
	call	save_IVT
	call	video_init
	ASSUME	DS:NOTHING,ES:NOTHING,FS:NOTHING,GS:NOTHING,SS:NOTHING
	push	cs
	pop	ds
	ASSUME	DS:CODE
	call	clrscr
	call	restore_IVT
	call	swap_displays
	popad
	pop	ds
	ASSUME	DS:CODE
	pop	es
	pop	fs
	pop	gs
	popf
	lss	sp,stackptr
	les	bx,devhdr
	mov	byte ptr es:[bx+13],0
	mov	word ptr es:[bx+14],0	; indicate zero bytes in length
	mov	es:[bx+16],cs
	mov	ax,0100h		; indicate Done
exit:
	les	bx,devhdr
	mov	es:[bx+3],ax
	pop	ax
	pop	bx
	pop	ds
	ASSUME	DS:NOTHING
	pop	es
	ret
intrpt endp

tempstack label byte
tempstack_bot equ (tempstack+2048)

CODE ends


	end
