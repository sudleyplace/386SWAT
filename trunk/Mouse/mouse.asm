		xor 	ax,ax
		int 	33h
		cmp 	ax,0ffffh
;		 jne	 not_loaded
		jmp 	not_loaded

		mov 	ah,9
		mov 	dx,offset already_loaded
		int 	21h

		mov 	ax,4c01h
		int 	21h

not_loaded:

		mov 	ah,9
		mov 	dx,offset intro_string
		int 	21h

		mov 	ax,2574h
		mov 	dx,offset new_isr
		int 	21h

		mov 	ax,2533h
		mov 	dx,offset new_33
		int 	21h

		cli

		mov 	bl,0a8h
		call	keyboard_cmd

		mov 	bl,20h
		call	keyboard_cmd
		call	keyboard_read
		or		al,2
		mov 	bl,60h
		push	ax
		call	keyboard_cmd
		pop 	ax
		call	keyboard_write

		mov 	bl,0d4h
		call	keyboard_cmd
		mov 	al,0f4h
		call	keyboard_write

		sti

		mov 	dx,offset end_of_tsr
		int 	27h

intro_string	db 0dh,0ah,'DPSMouseDRV (c) 1998 by David Sicilia Software.',0dh,0ah,'$'
already_loaded	db 0dh,0ah,'Mouse driver already loaded!',0dh,0ah,'$'

call_user_isr:
		db		60h
		mov 	cx,cs:[pos_x]
		mov 	dx,cs:[pos_y]
		mov 	di,0 ;cs:[x_move]
		mov 	si,0 ;cs:[y_move]
		mov 	w[cs:x_move],0
		mov 	w[cs:y_move],0
		mov 	bl,cs:[buttons]
		xor 	bh,bh
		call	dword ptr cs:[user_subroutine]
		db		61h
		ret

new_isr:
		pushf
		cli
		push	ax
		push	bx
		push	cx
		push	dx
		push	di
		push	si
		push	es
		push	ds

		push	cs
		pop 	ds

		mov 	bl,0adh
		call	keyboard_cmd

		cmp 	b[first_time],0
		je		not_first_time

		mov 	b[first_time],0
		call	keyboard_read
		call	keyboard_read
		call	keyboard_read
		jmp 	no_show

not_first_time:
		mov 	w[temp_mask],0

		mov 	cx,word ptr [offset pos_x]
		mov 	dx,word ptr [offset pos_y]

		call	keyboard_read
		and 	al,7 ;3
		mov 	ah,[buttons]
		mov 	[buttons],al
		cmp 	al,ah
		je		no_button_change
		and 	al,3
		and 	ah,3
		xor 	al,ah
		xor 	bx,bx

		push	ax
		test	al,2
		jz		no_right_button_change
		and 	ah,2
		jz		right_button_pressed
		or		bx,16
		jmp 	no_right_button_change
right_button_pressed:
		or		bx,8
no_right_button_change:

		pop 	ax

		test	al,1
		jz		no_left_button_change
		and 	ah,1
		jz		left_button_pressed
		or		bx,4
		jmp 	no_left_button_change
left_button_pressed:
		or		bx,2
no_left_button_change:

		mov 	[temp_mask],bx

no_button_change:
		call	keyboard_read
		cbw
		add 	word ptr [pos_x],ax
		add 	word ptr [x_move],ax
		mov 	ax,[x_min]
		cmp 	word ptr [pos_x],ax
		jg		good_hor1
		mov 	word ptr [pos_x],ax
good_hor1:
		mov 	ax,[x_max]
		cmp 	word ptr [pos_x],ax
		jle 	good_hor2
		mov 	word ptr [pos_x],ax
good_hor2:

		call	keyboard_read
		neg 	al
		cbw
		add 	word ptr [pos_y],ax
		add 	word ptr [y_move],ax
		mov 	ax,[y_min]
		cmp 	word ptr [pos_y],ax
		jg		good_ver1
		mov 	word ptr [pos_y],ax
good_ver1:
		mov 	ax,[y_max]
		cmp 	word ptr [pos_y],ax
		jle 	good_ver2
		mov 	word ptr [pos_y],ax
good_ver2:

		mov 	ax,[x_move]
		or		ax,[y_move]
		or		ax,ax
		jz		no_change_position
		or		w[temp_mask],1
no_change_position:

		mov 	ax,[temp_mask]
		and 	ax,[user_mask]
		jz		no_call_user
		call	call_user_isr
no_call_user:

		cmp 	byte ptr [sm_flag],1
		jne 	no_show

		shr 	cx,3
		shr 	dx,3
		mov 	ax,80
		mul 	dl
		add 	ax,cx
		shl 	ax,1
		mov 	di,ax
		mov 	ax,0b800h
		mov 	es,ax
		mov 	ax,word ptr [offset save_char]
		stosw

		mov 	cx,word ptr [offset pos_x]
		mov 	dx,word ptr [offset pos_y]
		shr 	cx,3
		shr 	dx,3
		mov 	ax,80
		mul 	dl
		add 	ax,cx
		shl 	ax,1
		mov 	di,ax
		mov 	ax,0b800h
		mov 	es,ax
		mov 	ax,word ptr es:[di]
		mov 	word ptr [offset save_char],ax
		not 	ah
		and 	ah,7fh
		stosw
no_show:
		mov 	bl,0aeh
		call	keyboard_cmd

		mov 	al,20h
		out 	0a0h,al
		out 	20h,al

		pop 	ds
		pop 	es
		pop 	si
		pop 	di
		pop 	dx
		pop 	cx
		pop 	bx
		pop 	ax
		popf
		iret

first_time		db		1
buttons 		db		0
pos_x			dw		0
pos_y			dw		0
sm_flag 		dw		0
save_char		dw		0
x_move			dw		0
y_move			dw		0
x_max			dw		639
x_min			dw		0
y_max			dw		199
y_min			dw		0
user_subroutine dw		0,0
user_mask		dw		0
temp_mask		dw		0

keyboard_read:
		push	cx
		push	dx
		xor 	cx,cx
key_read_loop:
		in		al,64h
		jmp 	$+2
		jmp 	$+2
		test	al,1
		jnz 	key_read_ready
		loop	key_read_loop
		mov 	ah,1
		jmp 	key_read_exit
key_read_ready:
		push	cx
		mov 	cx,32
key_read_delay:
		jmp 	$+2
		jmp 	$+2
		loop	key_read_delay

		pop 	cx

		in		al,60h
		jmp 	$+2
		jmp 	$+2
		xor 	ah,ah
key_read_exit:
		pop 	dx
		pop 	cx
		ret

keyboard_write:
		push	cx
		push	dx
		mov 	dl,al
		xor 	cx,cx
kbd_wrt_loop1:
		in		al,64h
		jmp 	$+2
		jmp 	$+2
		test	al,20h
		jz		kbd_wrt_ok1

		loop	kbd_wrt_loop1

		mov 	ah,1
		jmp 	kbd_wrt_exit

kbd_wrt_ok1:
		in		al,60h

		xor 	cx,cx
kbd_wrt_loop:
		in		al,64h
		jmp 	$+2
		jmp 	$+2
		test	al,2
		jz		kbd_wrt_ok

		loop	kbd_wrt_loop

		mov 	ah,1
		jmp 	kbd_wrt_exit

kbd_wrt_ok:
		mov 	al,dl
		out 	60h,al
		jmp 	$+2
		jmp 	$+2

		xor 	cx,cx
kbd_wrt_loop3:
		in		al,64h
		jmp 	$+2
		jmp 	$+2
		test	al,2
		jz		kbd_wrt_ok3

		loop	kbd_wrt_loop3

		mov 	ah,1
		jmp 	kbd_wrt_exit

kbd_wrt_ok3:
		mov 	ah,8
kbd_wrt_loop4:
		xor 	cx,cx
kbd_wrt_loop5:
		in		al,64h
		jmp 	$+2
		jmp 	$+2
		test	al,1
		jnz 	kbd_wrt_ok4

		loop	kbd_wrt_loop5

		dec 	ah
		jnz 	kbd_wrt_loop4

kbd_wrt_ok4:
		xor 	ah,ah
kbd_wrt_exit:
		pop 	dx
		pop 	cx
		ret
		
keyboard_cmd:
		xor 	cx,cx
cmd_wait:
		in		al,64h
		jmp 	$+2
		jmp 	$+2
		test	al,2
		jz		cmd_send
		loop	cmd_wait

		jmp 	cmd_error

cmd_send:
		mov 	al,bl
		out 	64h,al
		jmp 	$+2
		jmp 	$+2

		xor 	cx,cx
cmd_accept:
		in		al,64h
		jmp 	$+2
		jmp 	$+2
		test	al,2
		jz		cmd_ok
		loop	cmd_accept

cmd_error:
		mov 	ah,1
		jmp 	cmd_exit
cmd_ok:
		xor 	ah,ah
cmd_exit:
		ret

new_33:
		cli
		cmp 	al,0
		je		reset_mouse
		cmp 	al,1
		je		show_mouse
		cmp 	al,2
		je		hide_mouse
		cmp 	al,3
		je		get_pos
		cmp 	al,4
		je		set_pos
		cmp 	al,7
		je		set_hor_pos
		cmp 	al,8
		je		set_ver_pos
		cmp 	al,0bh
		je		get_mouse_movement

		cmp 	al,0ch
		je		set_subroutines
		cmp 	al,14h
		je		swap_subroutines
		iret

reset_mouse:
		jmp 	_reset_mouse
show_mouse:
		jmp 	_show_mouse
hide_mouse:
		jmp 	_hide_mouse
get_pos:
		jmp 	_get_pos
set_pos:
		jmp 	_set_pos
set_hor_pos:
		jmp 	_set_hor_pos
set_ver_pos:
		jmp 	_set_ver_pos
get_mouse_movement:
		jmp 	_get_mouse_movement
set_subroutines:
		jmp 	_set_subroutines
swap_subroutines:
		jmp 	_swap_subroutines

_reset_mouse:
		mov 	b[cs:offset buttons],0
		mov 	w[cs:offset pos_x],0
		mov 	w[cs:offset pos_y],0
		mov 	w[cs:offset x_move],0
		mov 	w[cs:offset y_move],0
		mov 	w[cs:offset x_max],639
		mov 	w[cs:offset x_min],0
		mov 	w[cs:offset y_max],199
		mov 	w[cs:offset y_min],0
		mov 	w[cs:offset user_mask],0
		mov 	w[cs:offset user_subroutine],0
		mov 	w[cs:offset user_subroutine+2],0
		mov 	ax,0ffffh
		mov 	bx,3
		iret

_get_pos:
		mov 	cx,word ptr cs:[offset pos_x]
		mov 	dx,word ptr cs:[offset pos_y]
		mov 	bx,word ptr cs:[offset buttons]
		xor 	bh,bh
		iret

_get_mouse_movement:
		mov 	cx,word ptr cs:[offset x_move]
		mov 	dx,word ptr cs:[offset y_move]
		mov 	word ptr cs:[offset x_move],0
		mov 	word ptr cs:[offset y_move],0
		iret

_show_mouse:
		push	ax
		push	bx
		push	di
		push	es
		mov 	byte ptr cs:[offset sm_flag],1
		mov 	ax,word ptr cs:[offset pos_y]
		shr 	ax,3
		mov 	bl,80
		mul 	bl
		mov 	bx,word ptr cs:[offset pos_x]
		shr 	bx,3
		add 	ax,bx
		shl 	ax,1
		mov 	di,ax
		mov 	ax,0b800h
		mov 	es,ax
		mov 	ax,word ptr es:[di]
		mov 	cs:[offset save_char],ax
		not 	ah
		and 	ah,7fh
		mov 	es:[di],ax
		pop 	es
		pop 	di
		pop 	bx
		pop 	ax
		iret

_hide_mouse:
		push	ax
		push	bx
		push	di
		push	es
		mov 	byte ptr cs:[offset sm_flag],0
		mov 	ax,word ptr cs:[offset pos_y]
		shr 	ax,3
		mov 	bl,80
		mul 	bl
		mov 	bx,word ptr cs:[offset pos_x]
		shr 	bx,3
		add 	ax,bx
		shl 	ax,1
		mov 	di,ax
		mov 	ax,0b800h
		mov 	es,ax
		mov 	ax,word ptr cs:[offset save_char]
		mov 	word ptr es:[di],ax
		pop 	es
		pop 	di
		pop 	bx
		pop 	ax
		iret

_set_pos:
		mov 	cx,cs:[pos_x]
		mov 	dx,cs:[pos_y]
		mov 	w[cs:x_move],0
		mov 	w[cs:y_move],0
		iret

_set_hor_pos:
		call	max_min
		mov 	cs:[x_min],cx
		mov 	cs:[x_max],dx
		cmp 	cs:[pos_x],cx
		jge 	good_hor_min
		mov 	cs:[pos_x],cx
good_hor_min:
		cmp 	cs:[pos_x],dx
		jle 	good_hor_max
		mov 	cs:[pos_x],dx
good_hor_max:
		iret

_set_ver_pos:
		call	max_min
		mov 	cs:[y_min],cx
		mov 	cs:[y_max],dx
		cmp 	cs:[pos_y],cx
		jge 	good_ver_min
		mov 	cs:[pos_y],cx
good_ver_min:
		cmp 	cs:[pos_y],dx
		jle 	good_ver_max
		mov 	cs:[pos_y],dx
good_ver_max:
		iret

max_min:
		cmp 	cx,dx
		jle 	no_swap
		xchg	cx,dx
no_swap:
		ret

_set_subroutines:
		mov 	cs:[user_subroutine],dx
		mov 	cs:[user_subroutine+2],es
		mov 	cs:[user_mask],cx
		iret

_swap_subroutines:
		push	w[cs:user_mask]
		push	w[cs:user_subroutine+2]
		push	w[cs:user_subroutine]
		mov 	cs:[user_subroutine],dx
		mov 	cs:[user_subroutine+2],es
		mov 	cs:[user_mask],cx
		pop 	dx
		pop 	es
		pop 	cx
		iret

end_of_tsr:
end

