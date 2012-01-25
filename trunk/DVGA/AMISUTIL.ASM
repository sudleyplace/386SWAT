;-----------------------------------------------------------------------
; AMISUTIL.ASM	Public Domain 1993 Ralf Brown
;		You may do with this software whatever you want, but
;		common courtesy dictates that you not remove my name
;		from it.
;
; Utility functions to be called by the TSR's resident code
;
; Version 0.93
; LastEdit: 1/22/96
;-----------------------------------------------------------------------

__DEFAULT_MODEL__ equ __TINY__
	INCLUDE AMIS.MAC

TSRgroup@ byte

;-----------------------------------------------------------------------
; Put the resident code into its own segment so that all the offsets are
; proper for the new location after copying it into a UMB or down into
; the PSP.
;
TSRcode@ byte
	ASSUME	CS:TGROUP,DS:TGROUP,ES:NOTHING

;-----------------------------------------------------------------------
; TSR's initialized data storage
;
TSRdata@

TSRdataEnd@

;-----------------------------------------------------------------------
; TSR's uninitialized data storage
;
TSRbss@
cursor_pos label word
cursor_x	db ?
cursor_y	db ?

interrupted_cursorpos dw ?

display_page_attr label word
display_attr	db ?
display_page	db ?
screen_width	db ?

window_upleft	label word
window_left	db ?
window_top	db ?

window_lowright label word
window_right	db ?
window_bottom	db ?

window_size	label word
window_width	db ?
window_height	db ?

screen_buffer_offset dw ?
window_name_offset   dw ?

TSRbssEnd@

;-----------------------------------------------------------------------
;
public TSR_GETKEY
TSR_GETKEY proc near
	mov	ah,11h			; keystroke available?
	int	16h
	jnz	TSR_getkey_got_one	; if yes, get it, otherwise
	int	28h			; give other TSRs a chance to do work
	jmp	TSR_GETKEY
TSR_getkey_got_one:
	mov	ah,10h			; get the keystroke
	int	16h
	ret
TSR_GETKEY endp

;-----------------------------------------------------------------------
; exit:  AX, BH, DX destroyed
;
public TSR_HOME_CURSOR
TSR_HOME_CURSOR proc near
	xor	dx,dx
	;; fall through to TSR_MOVE_CURSOR ;;
TSR_HOME_CURSOR endp

;-----------------------------------------------------------------------
; entry: DH = row, DL = column
; exit:  AX, BH, DX destroyed
;
public TSR_MOVE_CURSOR
TSR_MOVE_CURSOR proc near
	ASSUME	DS:TGROUP,ES:NOTHING
	mov	cursor_pos,dx
	add	dl,window_left
	inc	dl
	mov	al,window_right
	dec	al
	cmp	dl,al
	jbe	col_OK
	mov	dl,al
col_OK:
	add	dh,window_top
	inc	dh
	mov	al,window_bottom
	dec	al
	cmp	dh,al
	jbe	row_OK
	mov	dh,al
row_OK:
	;; fall through to TSR_MOVE_CURSOR_ABS ;;
TSR_MOVE_CURSOR endp

TSR_MOVE_CURSOR_ABS proc near
	mov	bh,display_page
	mov	ah,2			; BIOS move-cursor function
	int	10h
	ret
TSR_MOVE_CURSOR_ABS endp

;-----------------------------------------------------------------------
; entry: AL = char
; exit: AH,BX,CX,DX destroyed
;
public TSR_PUT_CHAR
TSR_PUT_CHAR proc near
	mov	cx,1
	;; fall through to TSR_PUT_LINE
TSR_PUT_CHAR endp

;-----------------------------------------------------------------------
; entry: AL = char, CX = repeat count
; exit: AX,BX,CX,DX destroyed
;
public TSR_PUT_LINE
TSR_PUT_LINE proc near
	ASSUME	DS:TGROUP,ES:NOTHING
	add	cursor_x,cl
	mov	bx,display_page_attr
	mov	ah,9
	int	10h
	mov	al,cursor_x
	cmp	al,window_width
	jb	TSR_put_line_done
	mov	cursor_x,0
	inc	cursor_y
	cmp	al,window_height
	jb	TSR_put_line_done
	dec	cursor_y
	call	TSR_SCROLL_WINDOW
TSR_put_line_done:
	mov	dx,cursor_pos
	jmp	TSR_MOVE_CURSOR
TSR_PUT_LINE endp

;-----------------------------------------------------------------------
; entry: DS:SI -> string
; exit: DS:SI -> byte after terminating NUL
;
public TSR_PUT_STRING
TSR_PUT_STRING proc near
	lodsb
	or	al,al
	jz	TSR_put_string_done
	call	TSR_PUT_CHAR
	jmp	TSR_PUT_STRING
TSR_put_string_done:
TSR_PUT_STRING endp

;-----------------------------------------------------------------------
; exit: AX,BX,CX destroyed
;
put_char_186 proc near
	mov	al,186			; double vertical line
	;; fall through to put_char_tty ;;
put_char_186 endp

;-----------------------------------------------------------------------
; entry: AL = char
; exit: AX,BX,CX destroyed
;
put_char_tty proc near
	mov	bx,display_page_attr
	mov	ah,0Eh
	int	10h
	ret
put_char_tty endp

;-----------------------------------------------------------------------
;
public TSR_SAVE_SCREEN
TSR_SAVE_SCREEN proc near
	ASSUME	DS:TGROUP,ES:NOTHING
	mov	ah,0Fh
	int	10h			; get video mode and active page
	mov	display_page,bh
	mov	screen_width,ah
	mov	ah,3			; get cursor position on page BH
	int	10h
	mov	interrupted_cursorpos,dx
	push	ds
	pop	es
	ASSUME	ES:TGROUP
	mov	di,screen_buffer_offset
	mov	dh,window_top
save_screen_loop1:
	mov	dl,window_left
save_screen_loop2:
	mov	ah,2			; set cursor position on page BH
	int	10h
	mov	ah,8			; read character&attribute on page BH
	int	10h
	cld
	stosw				; and remember them for later restore
	inc	dl
	cmp	dl,window_right
	jbe	save_screen_loop2
	inc	dh
	cmp	dh,window_bottom
	jbe	save_screen_loop1
	ret
TSR_SAVE_SCREEN endp

;-----------------------------------------------------------------------

framed_window_hline proc near
	push	ax
	call	put_char_tty
	mov	cl,window_width
	mov	ch,0
	dec	cx
	dec	cx
	js	fwh_done
	mov	ax,(256*0Eh)+205
	mov	bx,display_page_attr
fwh_loop:
	int	10h
	loop	fwh_loop
fwh_done:
	pop	ax
	mov	al,ah
	jmp	put_char_tty
framed_window_hline endp

;-----------------------------------------------------------------------

public TSR_FRAMED_WINDOW
TSR_FRAMED_WINDOW proc near
	ASSUME	DS:TGROUP,ES:NOTHING
	mov	dx,window_upleft
	call	TSR_MOVE_CURSOR_ABS
	mov	display_attr,0Fh	; bright white on black
	mov	ax,0BBC9h		; double upper left/right corners
	call	framed_window_hline
	push	si
	mov	dx,window_upleft
	inc	dh
frame_loop:
	mov	si,dx
	call	TSR_MOVE_CURSOR_ABS
	call	put_char_186		; double vertical bar
	mov	dx,si
	mov	dl,window_right
	call	TSR_MOVE_CURSOR_ABS
	call	put_char_186		; double vertical bar
	mov	dx,si
	inc	dh
	cmp	dh,window_bottom
	jb	frame_loop
	pop	si
	mov	dl,window_left		; DH is already window_bottom
	call	TSR_MOVE_CURSOR_ABS
	mov	display_attr,0Fh	; bright white on black
	mov	ax,0BCC8h		; double lower left/right corners
	call	framed_window_hline
	;
	; frame is done, now add the title
	;
	mov	dx,window_upleft
	inc	dx
	inc	dx
	call	TSR_MOVE_CURSOR_ABS
	mov	si,window_name_offset
frame_title:
	lodsb
	or	al,al
	jz	frame_title_done
	call	put_char_tty
	jmp	frame_title
frame_title_done:
	call	TSR_HOME_CURSOR
	mov	display_attr,07h	; dim white on black
	;; fall through to TSR_CLEAR_WINDOW ;;
TSR_FRAMED_WINDOW endp

;-----------------------------------------------------------------------

public TSR_CLEAR_WINDOW
TSR_CLEAR_WINDOW proc near
	mov	ax,0600h		; clear popup window area
scroll:
	mov	bh,display_attr
	mov	cx,window_upleft
	add	cx,0101h
	mov	dx,window_lowright
	sub	dx,0101h
	int	10h
	ret
TSR_CLEAR_WINDOW endp

;-----------------------------------------------------------------------

public TSR_SCROLL_WINDOW
TSR_SCROLL_WINDOW proc near
	mov	ax,0601h
	jmp	scroll
TSR_SCROLL_WINDOW endp

;-----------------------------------------------------------------------

public TSR_RESTORE_SCREEN
TSR_RESTORE_SCREEN proc near
	ASSUME	DS:TGROUP,ES:NOTHING
	mov	si,screen_buffer_offset
	mov	dh,window_top
rest_screen_loop1:
	mov	dl,window_left
rest_screen_loop2:
	push	dx
	mov	ah,2
	mov	bh,display_page
	int	10h			; set cursor position
	cld
	lodsw				; get character and attribute to restore
	mov	bl,ah			; BL <- attribute
	mov	cx,1
	mov	ah,9			; write character&attribute
	int	10h
	pop	dx
	inc	dl
	cmp	dl,window_right
	jbe	rest_screen_loop2
	inc	dh
	cmp	dh,window_bottom
	jbe	rest_screen_loop1
	mov	dx,interrupted_cursorpos
	mov	ah,2			; restore cursor position
	int	10h
	ret
TSR_RESTORE_SCREEN endp

;-----------------------------------------------------------------------

TSRcodeEnd@

_TEXT SEGMENT PUBLIC 'CODE'
	ASSUME cs:_TEXT,ds:NOTHING,es:NOTHING,ss:NOTHING

IFDEF __TINY__
extrn TGROUP@:word
ENDIF

;-----------------------------------------------------------------------
; entry: AX = upleft row,col
;	 BX = height, width
;	 CX = offset of screen buffer in TGROUP
;	 DX = offset of window title in TGROUP
;
public TSR_SET_WINDOW
TSR_SET_WINDOW proc DIST
	ASSUME	CS:_TEXT,DS:NOTHING,ES:NOTHING,SS:NOTHING
	push	ds
	mov	ds,TGROUP@
	ASSUME	DS:TGROUP
	mov	window_upleft,ax
	mov	window_size,bx
	mov	screen_buffer_offset,cx
	mov	window_name_offset,dx
	dec	bl
	dec	bh
	add	ax,bx
	mov	window_lowright,ax
	pop	ds
	ASSUME	DS:NOTHING
	ret
TSR_SET_WINDOW endp

_TEXT ENDS

	END
