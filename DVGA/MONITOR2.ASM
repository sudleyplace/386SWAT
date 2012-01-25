	NAME	Monitor2
	TITLE	Run a program on the secondary SVGA display
        PAGE    60,132

;**********************************************************************
; (c) Copyright 1996 Ralf Brown  All Rights Reserved
; This code may be redistributed provided that:
;	1) this copyright notice remains intact and any changes are clearly
;	   marked
;       2) no fee of any kind is charged
;**********************************************************************
;  Monitor2
;	Loader to run a program on the secondary display
;
;  Last Edit: 6/2/96
;
;**********************************************************************

VERSION_NUM equ 005Ah ; v0.90
VERSION_STR equ "0.90"

required_DUALVGA_ver equ 0032h ; need at least v0.50

;----------------------------------------------------------------------

; declare the segments in the required order
cseg segment public 'code' para
cseg ends
dseg segment public 'data' byte
dseg ends

;**********************************************************************

;-----------------------------------------------------------
; describe the parameter block we need to pass to the DOS EXEC function

EXEC_data_block STRUC
   envseg      DW ?
   cmdline     DD ?
   firstfcb    DD ?
   secondfcb   DD ?
EXEC_data_block ENDS

FFBLK struc
 ?ffb_reserved db 21 dup (?)
 ?ffb_attr     db ?
 ?ffb_time     dw ?
 ?ffb_date     dw ?
 ?ffb_size     dd ?
 ?ffb_name     db 13 dup (?)
FFBLK ends

; bit flags for the extensions which were found
COM_EXT equ 1
EXE_EXT equ 2
USER_EXT equ 4

;**********************************************************************

CSEG SEGMENT 'CODE'
	ASSUME	CS:CSEG,DS:CSEG,ES:CSEG,SS:CSEG
	.286

; describe the fields of the PSP we will be using, as well as the
; additional info that will be stuffed into it
	ORG 4Eh
exec_block  EXEC_data_block <>	; 14 bytes long
	ORG 5Ch
label FCB1 byte
	ORG 6Ch
label FCB2 byte
	ORG 80h
CMD_LEN     DB ?
cmd_line    DB 127 dup (?)

;----------------------------------------------------------------------

	ORG 100h

Monitor2:
	jmp	Monitor2_start

exec_error_msg db "Unable to execute program",13,10
	       db "$"

	even

old_ss	    dw ?
old_sp	    dw offset stack_top
OldINT23h   dd ?
orig_INT10  dd ?

ems_handle  dw ?

executable_path db    80 dup (?)   ; size of longest legal path+file+NUL
executable_pad  db    3 dup (?)    ; in case we run over while adding extension

exit_code   db  ?

int23_sp	dw ?

;----------------------------------------------------------------------

check_stdout proc near
	ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	push	es
	push	bx
	push	ax
	mov	ah,51h			; get PSP
	pushf
	call	dword ptr CSEG:orig_INT21
	mov	es,bx
	les	bx,es:[0034h]		; get JFT pointer from PSP
	cmp	byte ptr es:[bx+1],1	; is stdout pointing at CON?
	pop	ax
	pop	bx
	pop	es
	ret
check_stdout endp

;----------------------------------------------------------------------

check_break proc near
	ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	push	ax
	mov	ah,11h
	int	16h			; peek at next character
	jz	check_break_done
	cmp	al,3			; Ctrl-C ?
	je	break_pressed
	test	ax,ax			; Ctrl-Break (puts 0000h in kbd buffer)
	je	break_pressed
check_break_done:
	pop	ax
	clc
	ret
break_pressed:
	pop	ax
	clc
	mov	int23_sp,sp
	int	23h
	mov	sp,int23_sp
	ret
check_break endp

;----------------------------------------------------------------------

output_char proc near
	mov	al,dl
output_char1:
	cmp	al,9			; is it a tab?
	je	short output_tab
output_char2:
	push	bx
	push	ax
	mov	ah,0Eh			; TTY output
	mov	bx,0007h		; page 0, white on black
	int	10h
	pop	ax
	pop	bx
	ret

output_tab:
	push	cx
	push	ax
	push	dx
	mov	ah,3
	int	10h			; get cursor position
	and	dl,7			; DL <- column MOD 8
	mov	cx,8			; compute how many columns we need
	sub	cl,dl			;   by subtracting from next tabstop
	pop	dx
	push	bx
output_tab_loop:
	mov	ax,0E20h		; TTY output a blank
	mov	bx,0007h		; page 0, white on black
	int	10h
	loop	output_tab_loop
	pop	bx
	pop	ax
	pop	cx
	ret
output_char endp

;----------------------------------------------------------------------

int21_handler proc far
	ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	pushf
	cmp	ah,2
	je	int21_02
	cmp	ah,6
	je	int21_06
	cmp	ah,9
	je	int21_09
chain_int21:
	popf
	db	0EAh			; FAR JMP
orig_INT21 dd	?

int21_02:
	call	check_stdout
	jne	chain_int21
	call	check_break
	jc	short int21_return
int21_outchar:
	call	output_char
int21_return:
	popf
	iret

int21_06:
	cmp	dl,0FFh
	je	chain_int21
	call	check_stdout
	jne	chain_int21
	jmp	int21_outchar
	
int21_09:
	call	check_stdout
	jne	chain_int21
	push	bx
	mov	bx,dx
int21_09_loop:
	call	check_break
	jc	int21_09_done
	mov	al,ds:[bx]
	cmp	al,'$'
	je	int21_09_done
	inc	bx
	call	output_char1
	jmp	int21_09_loop
int21_09_done:
	pop	bx
	jmp	int21_return
int21_handler endp

;----------------------------------------------------------------------

restore_monitor proc near
	push	ax
	mov	ax,0311h		; restore active monitor for other tasks
$restore$ equ word ptr ($-2)
	pushf
	db	09Ah			; FAR CALL
orig_INT2D dd	?
	pop	ax
	ret
restore_monitor endp

;----------------------------------------------------------------------

select_monitor proc near
	push	ax
	mov	ax,0310h		; get current monitor
$get$ equ word ptr ($-2)
;	pushf
;	call	dword ptr CSEG:orig_INT2D
;	add	ah,11h			; convert to proper function number
;	mov	byte ptr $restore$,ah	;   and patch the restoration code
	mov	ax,0312h		; select our active monitor
$set$ equ word ptr ($-2)
	pushf
	call	dword ptr CSEG:orig_INT2D
	pop	ax
	ret
select_monitor endp

;----------------------------------------------------------------------

xdi_handler proc far
	cmp	ah,0DEh			; DV XDI call?
multiplex_number equ byte ptr ($-1)
	jne	not_xdi
	cmp	al,9			; XDI_RESTORE_STATE?
	je	restore_state
	cmp	al,8			; XDI_SAVE_STATE?
	je	save_state
	cmp	al,6			; XDI_CREATE_TASK?
	je	restore_state
	cmp	al,7			; XDI_REMOVE_TASK?
	je	kill_process
	cmp	al,5			; XDI_REMOVE_PROCESS?
	jne	not_xdi
kill_process:
	mov	byte ptr CSEG:$restore$,11h ; force back to monitor 1 on exit
save_state:
	call	restore_monitor
not_xdi:
	db	0EAh			; FAR JMP
orig_INT2F dd	?

restore_state:
	push	ax
	pushf
	call	dword ptr CSEG:orig_INT2F
	call	select_monitor
	pop	ax
	iret
xdi_handler_end label byte
xdi_handler endp

;----------------------------------------------------------------------

timer_handler proc far
	ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	call	restore_monitor
	db	09Ah			; FAR CALL
orig_INT08 dd ?
	call	select_monitor
	iret
timer_handler endp

;----------------------------------------------------------------------

Monitor2_load:
	ASSUME	DS:CSEG,ES:CSEG
        int     21h                     ; reduce memory allocation
	mov	ax,4B00h
	mov	bx,offset exec_block
	mov	dx,offset executable_path
	int	21h			; run the program
	ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	cli
	mov	ss,old_ss
	mov	sp,old_sp
	sti
	ASSUME	SS:CSEG
	push	cs
	pop	ds
	ASSUME	DS:CSEG
	jnc	Monitor2_get_exitcode
	mov	dx,offset CSEG:exec_error_msg
	mov	ah,9
	int	21h
	mov	al,0FFh
	jmp short Monitor2_got_exitcode
Monitor2_get_exitcode:
        mov     ah,4Dh                  ; get program's exit code
	int	21h
Monitor2_got_exitcode:
	mov	exit_code,al		; store exit code for later
	call	restore_monitor
	lds	dx,OldINT23h
	ASSUME	DS:NOTHING
	mov	ax,2523h		; restore INT 23, the ^Break handler
	int	21h	
	lds	dx,cs:orig_INT08
	mov	ax,2508h		; restore timer tick vector
$timer$ equ byte ptr ($-2)
	int	21h
	lds	dx,cs:orig_INT10	; restore INT 10h
	mov	ax,2510h
	int	21h
	lds	dx,cs:orig_INT21	; restore INT 21h
	mov	ax,2521h
	int	21h		
	lds	dx,cs:orig_INT2F	; restore INT 2Fh
	mov	ax,252Fh
	int	21h
        mov     al,exit_code            ; retrieve program's exit code
        mov     ah,4Ch                  ; and return it as our own exit code
	int	21h

int23_handler proc far
        mov     ah,0
	stc				; say we want to be terminated by
	ret	2			;  setting CF and discarding saved flags
					;  instead of doing normal IRET
int23_handler endp


; code and data up to here remain resident at all times
;-------------------------------------
; everything after this point is discarded or overwritten by the new stack
; once the EXEC has been set up

stack_top equ $ + 144

hello_msg     db "Monitor2 v",VERSION_STR,9," Copyright 1996 Ralf Brown",13,10
	      db "$"
usage_msg     db "Usage: Monitor2 program [parameters]",13,10
	      db 9,"Run <program> on the secondary monitor, passing it <parameters>.",13,10
              db "$"
keypress_msg  db 13,10,"Press Esc to close window, or space bar to continue...",13,10,"$"
DUALVGA_signature db "Ralf B  DUALVGA ",0
need_DUALVGA_msg  db "DUALVGA is not installed!",13,10,"$"
wrong_DUALVGA_msg db "Wrong version of DUALVGA installed!",13,10,"$"
	
DV_version	dw ?
DUALVGA_multiplex db ?
force_80x50	db 1

;----------------------------------------------------------------------

setup_stream label byte
	db	1Bh,00h
	dw	stream_len
setup_stream_body label byte
	db	0D0h			; allow incomplete frame
	db	0D7h			; frame not displayed
	db	0DBh			; use physical attributes
	db	0C3h,01h,01h		; set window size to one by one
	db	0C2h,00h,4Fh		; set window pos
	db	0D5h			; window is invisible
	db	0E4h			; redraw window
stream_len equ $-setup_stream_body

env		dd ?

name_incl_path  db ?
found_ext	db ?	 ; which extensions have we found?

ffb		ffblk <>

;--------------------------------------------------------------------------
; determine whether an XDI driver is present on multiplex number AH
;
check_XDI:
	push	es
	push	ds
	push	bp
	push	di
	push	si
	push	dx
	push	cx
	push	bx
        push    ax
	mov	al,0
	mov	bx,4456h
	mov	cx,5844h
	mov	dx,4931h
	int	2Fh
	cmp	al,0FFh
	jne	check_XDI_no
	cmp	bx,4845h
	jne	check_XDI_no
	cmp	cx,5245h
	jne	check_XDI_no
	cmp	dx,4456h
check_XDI_no:
        pop     ax
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	bp
	pop	ds
	pop	es
	ret

;----------------------------------------------------------------------

get_int_vectors proc near
	push	es
	mov	ax,3523h
	int	21h			; get Ctrl-Break handler address
	ASSUME	ES:NOTHING
	mov	word ptr OldINT23h,bx
	mov	word ptr OldINT23h+2,es
	; remember current INT 21 handler
	mov	ax,3521h
	int	21h
	mov	di,offset CSEG:orig_INT21
	mov	[di],bx
	mov	[di+2],es
	; remember current INT 2D handler
	mov	ax,352Dh
	int	21h
	mov	di,offset CSEG:orig_INT2D
	mov	[di],bx
	mov	[di+2],es
	; remember current INT 2F handler
	mov	ax,352Fh
	int	21h
	mov	di,offset CSEG:orig_INT2F
	mov	[di],bx
	mov	[di+2],es
	pop	es
	ASSUME	ES:CSEG
	ret
get_int_vectors endp

;----------------------------------------------------------------------

check_DESQview proc near
	mov	ax,2B01h
	xor	bx,bx
	mov	cx,4445h ; 'DE'
	mov	dx,5351h ; 'SQ'
	int	21h
	cmp	al,0FFh
	je	check_DV_done
	mov	DV_version,bx
check_DV_done:
	ret
check_DESQview endp

;----------------------------------------------------------------------

get_XDI_multiplex proc near
find_XDI:
	mov	ah,0DEh
find_XDI_loop:
	call	check_XDI
	jz	found_XDI		; returns ZF set if XDI found
	inc	ah
	cmp	ah,0DEh 		; if we make it back to DEh, there is
	je	no_XDI			;   no prior XDI driver loaded
	or	ah,ah
	jnz	find_XDI_loop
	mov	ah,0C0h
	jmp	find_XDI_loop

no_XDI:
	mov	ah,0DEh 		; if no XDI found, use default
found_XDI:
	mov	multiplex_number,ah
	ret
get_XDI_multiplex endp

;-----------------------------------------------------------------------
; (from AMISLIB v0.92 AMIS.ASM)
; entry: DX:AX -> TSR signature string
; exit:	 CF clear if not installed
;	    AL = 00h if free multiplex number exists
;		    AH = multiplex number to use
;	       = 01h if all multiplex numbers are already in use
;		    AH destroyed
;	    CX destroyed
;	 CF set if already installed
;	    AL = FFh
;	    AH = multiplex number being used
;	    CX = version number of resident TSR
;
get_DUALVGA_multiplex proc near
	mov	ax,offset DUALVGA_signature
	mov	dx,cs
check_if_installed:
	ASSUME	DS:NOTHING,ES:NOTHING
	push	ds
	push	si
	mov	ds,dx
	ASSUME	DS:NOTHING
	mov	si,ax
	push	es
	push	di
	push	dx
	push	bx
	xor	ax,ax			; AH=mpx #00h, AL=func 00h (instlchk)
	mov	bx,0001h		; BH=00h, BL=01h: all mpx numbers in use
chk_installed_loop:
	push	ax
	int	2Dh			; check if INT 2D/AH=xx is in use
	cmp	al,0FFh			; multiplex number in use?
	pop	ax
	je	chk_installed_inuse
	or	bl,bl			; if BL=00h, we've already seen a free mpx
	je	chk_installed_next
	mov	bl,0
	mov	bh,ah
	jmp short chk_installed_next
chk_installed_inuse:
	mov	es,dx
	ASSUME	ES:NOTHING
	push	cx			; remember version number
	mov	cx,16/2			; length of signature string
	cld
	push	si			; remember start of desired signature
	rep	cmpsw			; did we get our signature?
	pop	si			; get back start of desired signature
	pop	cx			; retrieve version
	jz	chk_installed_done	; quit loop if installed
chk_installed_next:
	inc	ah
	jnz	chk_installed_loop
; not yet installed
	mov	dx,offset need_DUALVGA_msg
	jmp	fatal_error
chk_installed_done:
	mov	DUALVGA_multiplex,ah
	cmp	cx,required_DUALVGA_ver
	jae	chk_installed_OK
	mov	dx,offset wrong_DUALVGA_msg
	jmp	fatal_error
chk_installed_OK:
	pop	bx
	pop	dx
	pop	di
	pop	es
	pop	si
	pop	ds
	ASSUME	DS:NOTHING,ES:NOTHING
	ret
get_DUALVGA_multiplex endp

;----------------------------------------------------------------------

rehook_INT10 proc near
	ASSUME	DS:CSEG,ES:NOTHING
	push	es
	mov	ax,3510h		; get current INT 10h to correctly
	int	21h			;   restore it on termination
	mov	word ptr orig_INT10,bx
	mov	word ptr orig_INT10+2,es
	cmp	DV_version,0
	jne	do_rehook_int10
	pop	es
	ret
do_rehook_int10:
	; copy DUALVGA's INT 10h chain addr into current INT 10h to bypass DV
	push	ds
	mov	ah,DUALVGA_multiplex
	mov	al,04h			; get chained interrupts
	int	2Dh
	cmp	al,04h			; proper result returned?
	jne	fallback_int10
	mov	es,dx
hook10_loop:
	mov	al,es:[bx]
	add	bx,3
	cmp	al,2Dh			; end of vector list?
	je	fallback_int10
	cmp	al,10h			; is it the INT 10h handler?
	jne	hook10_loop
	mov	bx,es:[bx-2]		; get offset of ISP header
	lds	dx,es:[bx+2]		; get chain address out of ISP header
	jmp	short rehook_int10_do_it
fallback_int10:				; DUALVGA INT 10h unavail, use INT 6Dh
	mov	ax,356Dh
	int	21h
	ASSUME	ES:NOTHING
	push	es
	pop	ds
	ASSUME	DS:NOTHING
	mov	dx,bx
rehook_int10_do_it:
	mov	ax,2510h
	int	21h
	pop	ds
	ASSUME	DS:CSEG
	pop	es
	ret
rehook_INT10 endp

;----------------------------------------------------------------------

rehook_timer proc near
	ASSUME	DS:CSEG
	cmp	DV_version,0
	jne	do_rehook_timer
	push	es
	mov	ax,3508h		; get current INT 08h to correctly
	int	21h			;   restore it on termination
	mov	word ptr orig_INT08,bx
	mov	word ptr orig_INT08+2,es
	pop	es
	ret
do_rehook_timer:
	; hook the relocated IRQ0 in order to work around DV's cursor emulation
	;  in graphics modes, which would otherwise tend to reset any graphics
	;  modes into the same chain-4 operation used in 16-color graphics
	push	es
	mov	ax,3567h
	int	21h
	mov	ax,es
	or	ax,bx			; is someone on INT 67h?
	jz	no_VCPI
	mov	ax,0DE00h		; VCPI installation check
	int	67h
	test	ah,ah
	jnz	no_VCPI
	mov	ax,0DE0Ah		; get IRQ mappings
	xor	bx,bx
	int	67h
	test	bx,bx
	jz	no_VCPI			; (sanity check)
	mov	$timer$,bl		; patch termination code
	mov	al,bl
	mov	ah,35h			; get relocated IRQ vector
	int	21h
	mov	word ptr orig_INT08,bx
	mov	word ptr orig_INT08+2,es
	push	ds
	push	cs
	pop	ds
	ASSUME	DS:NOTHING
	mov	dx,offset CSEG:timer_handler
	mov	ah,25h
	int	21h
	pop	ds
no_VCPI:
	pop	es
	ret
rehook_timer endp

;----------------------------------------------------------------------

configure_window proc near
	ASSUME	DS:NOTHING
	; configure the window
	push	cs
	push	offset CSEG:setup_stream
	xor	ax,ax
	push	ax
	mov	ax,stream_len+4
	push	ax
	mov	ah,12h
	mov	bx,0501h		; write to default window
	int	15h
	ret
configure_window endp

;----------------------------------------------------------------------

fatal proc near
	ASSUME	DS:NOTHING
fatal_error:
	mov	ah,9
	int	21h
	cmp	DV_version,0
	jz	fatal_exit
        mov     dx,offset keypress_msg
	mov	ah,9
	int	21h
await_key:
	mov	ah,0
	int	16h
	cmp	al,' '
	je	fatal_exit
	cmp	al,27
	jne	await_key
	cmp	DV_version,0
	je	fatal_exit
	mov	ah,12h
	mov	bx,0201h
	int	15h
fatal_exit:
	mov	ax,4CFFh
	int	21h
fatal endp

;---------------------------------------------------------------

Monitor2_start proc near
	ASSUME  DS:CSEG,ES:CSEG,SS:CSEG
	mov	dx,offset hello_msg
	mov	ah,9
	int	21h
	call	check_DESQview
	call	get_XDI_multiplex
	call	get_DUALVGA_multiplex
	call	get_int_vectors
	call	configure_window
	mov	si,81h
	mov	cl,cmd_len
	xor	ch,ch
	mov	dx,offset usage_msg
	jcxz	fatal_error
	; skip leading whitespace
	cld
strip_loop:
	lodsb
	dec	cx
	or	al,al
	je	fatal_error		; error to hit end of line
	cmp	al,13
	je	fatal_error
	cmp	al,9
	je	strip_loop
	cmp	al,' '
	je	strip_loop
; add NUL terminator at end of program name
	mov	bx,si			; SI -> second char of program name
	dec	bx			; BX -> start of program name
	inc	cx
scan_loop:
        lodsb
	cmp	al,13
	je	found_end
	cmp	al,' '
	je	found_end
	cmp	al,9
	je	found_end
	loop	scan_loop
found_end:
	dec	si			; point SI at new cmd_len
	mov	byte ptr [si],0
	mov	word ptr exec_block.cmdline,si
	push	bx			; BX -> start of program's name
	call	__spawn_search		; look for program in PATH
	or	ax,ax			; did we find it?
	mov	dx,offset CSEG:exec_error_msg
	jnz	spawn_search_found
	jmp	fatal_error
spawn_search_found:
	mov	ax,si			; SI -> program's cmdline
	sub	ax,offset cmd_len
	mov	bl,cmd_len
	sub	bl,al
	jb	dont_have_cmdline
        mov     [si],bl                 ; set length of program's cmdline
	jmp short have_cmdline
dont_have_cmdline:
        mov     byte ptr [si+1],13      ; no params for program, so put in CR
have_cmdline:
	inc	si			; move to first char of program's parms
	mov	di,offset FCB1
	mov	ax,2901h
	int	21h			; parse string into first FCB
	cmp	al,0FFh			; successful?
	je	FCBs_parsed
	mov	di,offset FCB2
	mov	ax,2901h		; parse string into second FCB
	int	21h
FCBs_parsed:
        mov     exec_block.envseg,0
	mov	word ptr exec_block.cmdline+2,cs
	mov	word ptr exec_block.firstfcb,offset FCB1
	mov	word ptr exec_block.firstfcb+2,cs
	mov	word ptr exec_block.secondfcb,offset FCB2
	mov	word ptr exec_block.secondfcb+2,cs
; if successful, double-check the file's existence (in case it was
; fully-specified on the commandline)
if 0
        mov     ah,1Ah
	mov	dx,offset ffb
	int	21h		 	; set DTA
	mov	ah,4Eh
	mov	cx,0027h		; find anything but dirs and volume label
	mov	dx,offset executable_path
	int	21h
	mov	dx,offset exec_error_msg
	jnc	file_found
	jmp	fatal_error
file_found:
endif
	mov	es,cs:[002Ch]		; get environment segment
	mov	ah,49h			; and free it
	int	21h
	push	cs
	pop	ds
	ASSUME	DS:CSEG
	mov	al,DUALVGA_multiplex
	mov	byte ptr $restore$+1,al
	mov	byte ptr $get$+1,al
	mov	byte ptr $set$+1,al
	mov	ax,2523h          	; grab Ctrl-Break vector
	mov	dx,offset int23_handler
	int	21h
	call	rehook_INT10
	call	rehook_timer
	push	bx
	push	ax
	mov	ah,DUALVGA_multiplex
	mov	al,12h			; select secondary monitor
	int	2Dh
	; set video mode to ensure 80x50 text is active
	mov	ax,0003h		; set 80x25 text
	int	10h
	cmp	force_80x50,0
	je	vidmode_set
	mov	ax,1112h		; set ROM 8x8 font
	mov	bl,0			; block specifier
	int	10h
vidmode_set:
	mov	ax,0500h		; set page 0 active
	int	10h
	pop	ax
	pop	bx
	pop	ds
	ASSUME	DS:NOTHING
	pop	es
	ASSUME	ES:NOTHING
	push	cs
	pop	ds
	ASSUME	DS:CSEG
	; hook ourself into INT 2F chain
	mov	dx,offset xdi_handler
	mov	ax,252Fh
	int	21h
	; hook ourself into INT 21 chain
	mov	dx,offset int21_handler
	mov	ax,2521h
	int	21h
	mov	old_ss,ss
        mov     ah,4Ah                  ; prepare for shrinking memory block
	mov	bx,(offset stack_top + 15)
	mov	cl,4
	shr	bx,cl			; BX = new size in paragraphs
	push	cs
	pop	es			; point ES back at main memory block
	ASSUME	ES:CSEG
        mov     sp,offset stack_top     ; move stack lower in memory
	jmp	Monitor2_load
Monitor2_start endp

;----------------------------------------------------------------
; static int pascal check_dir(void) ;
;	 check a single directory for both .COM and .EXE
;----------------------------------------------------------------
check_dir proc near
	push	es
	push	di
	push	ds
	pop	es
	assume	es:CSEG
	mov	found_ext,0	   ; haven't found anything yet
	mov	di,offset executable_path
	mov	cx,size executable_path
	mov	al,0
	cld
	repne	scasb
	dec	di
; now that we have the end of the name, scan backward to check extension
	mov	bx,di
	mov	dl,0
ext_scan_loop:
	dec	di
	cmp	di,offset executable_path
	je	had_no_ext
        mov     al,[di]
	cmp	al,'.'
	jne	not_dot
	or	dl,dl		   ; have we seen a wildcard?
	jne	got_dot
	or	found_ext,USER_EXT ; yes, user specified a particular extension
        jmp short got_extension
not_dot:
        cmp     al,'/'
	je	had_no_ext
	cmp	al,'\'
	je	had_no_ext
	cmp	al,':'
	je	had_no_ext
	cmp	al,'*'
	je	got_wildcard
	cmp	al,'?'
	jne	ext_scan_loop
got_wildcard:
	mov	dl,1
	jmp	ext_scan_loop
had_no_ext:
	mov	di,bx		   ; back to end of name
	mov	byte ptr [di],'.'  ; append a period
got_dot:
	inc	di
        mov     word ptr [di],'*'  ; append an asterisk wildcard and NUL
got_extension:
	mov	ah,2Fh		   ; get DTA
	int	21h
	assume	es:NOTHING
	push	es		   ; and store address for later
	push	bx
	mov	dx,offset ffb
        mov     ah,1Ah             ; set DTA to findfirst block
	int	21h
        mov     ah,4Eh
        mov     cx,23h             ; search for archive,hidden,and read-only
check_dir_loop:
	mov	dx,offset executable_path
	int	21h
	jc	check_no_more
	test	found_ext,USER_EXT
	jnz	check_OK
	mov	bx,offset ffb.?ffb_name
check_found_ext_loop:
	mov	al,[bx]
	inc	bx
	cmp	al,0
	je	checked_ext
	cmp	al,'.'
	jne	check_found_ext_loop
	cmp	word ptr [bx],'OC'
	jne	not_com_ext
	cmp	byte ptr [bx+2],'M'
	jne	not_com_ext
	or	found_ext,COM_EXT
	jmp short check_successful
not_com_ext:
	cmp	word ptr [bx],'XE'
	jne	checked_ext
	cmp	byte ptr [bx+2],'E'
	jne	checked_ext
	or	found_ext,EXE_EXT
checked_ext:
	mov	ah,4Fh
	jmp	check_dir_loop
check_no_more:
	test	found_ext,COM_EXT or EXE_EXT
	je	check_failed	   ; neither .COM nor .EXE found
check_successful:
	mov	word ptr [di],'OC'
	mov	ax,'M'
	test	found_ext,COM_EXT
	jne	check_succeeded
	mov	word ptr [di],'XE'
	mov	ax,'E'
check_succeeded:
        mov     word ptr [di+2],ax
check_OK:
	mov	bx,dx
	jmp short check_dir_done
check_failed:
	xor	bx,bx
check_dir_done:
	pop	dx		   ; get back original DTA
	pop	ax
	push	ds
	mov	ds,ax
	mov	ah,1Ah
	int	21h		   ; restore DTA
	pop	ds
	pop	di
	pop	es
	or	bx,bx		   ; set ZF if failed
        ret
check_dir endp

;----------------------------------------------------------------
; char * pascal __spawn_search(const char *name) ;
;    given a program name, search the PATH for it, returning the full pathname
;    or NULL if not found
;----------------------------------------------------------------
__SPAWN_SEARCH proc near
; parameters
 @name = word ptr [bp+4]
; start of subroutine
	push	bp
	mov	bp,sp
	push	es
	push	di
	push	si
; set up pointer to environment
	mov	es,ds:[002Ch]
	xor	di,di
	jmp short find_path
find_path_loop:
	cmp	byte ptr es:[di],0
	je	found_path
find_path_loop2:
        inc     di
	cmp	byte ptr es:[di-1],0
	jne	find_path_loop2
find_path:
	cmp	word ptr es:[di],'AP'
	jne	find_path_loop
	cmp	word ptr es:[di+2],'HT'
	jne	find_path_loop
	cmp	byte ptr es:[di+4],'='
	jne	find_path_loop
	add	di,5
found_path:
	mov	word ptr env+2,es
	mov	word ptr env,di
	mov	di,offset executable_path
        cld
search_loop:
	mov	name_incl_path,0
        push    ds
        pop     es
	assume	es:CSEG
	; append @name to executable_path
	mov	si,@name
copy_cur_loop:
	cmp	di,offset executable_pad
	jae	copy_cur_done
        lodsb
	stosb
	cmp	al,'/'
	je	name_has_path
	cmp	al,'\'
	jne	name_no_path
name_has_path:
	mov	name_incl_path,1
name_no_path:
	or	al,al
	jnz	copy_cur_loop
copy_cur_done:
	call	check_dir
	jnz	search_successful
	cmp	name_incl_path,0
	jne	search_failed	   ; don't look at PATH unless simple filename
	les	bx,env
	cmp	byte ptr es:[bx],0
	je	search_failed
	mov	di,offset executable_path
dir_copy_loop:
        mov     al,es:[bx]
	or	al,al
	je	dir_copy_done
	inc	bx
	cmp	al,';'             ; separator for path entries
	je	dir_copy_done
	mov	[di],al
	inc	di
	cmp	di,offset executable_pad   ; make sure we don't overrun buf
	jb	dir_copy_loop
dir_copy_done:
	mov	al,[di-1]
        cmp     al,'/'             ; was last char a slash or backslash?
	je	dir_has_slash
	cmp	al,'\'
	je	dir_has_slash
	cmp	al,':'             ; no slash if only drive letter
	je	dir_has_slash
	mov	byte ptr [di],'/'
	inc	di
dir_has_slash:
	mov	word ptr env,bx
	jmp	search_loop

search_successful:
	mov	ax,bx
	jmp short search_done
search_failed:
        xor     ax,ax
search_done:
	pop	si
	pop	di
	pop	es
        pop     bp
	ret	2
__SPAWN_SEARCH endp

CSEG ENDS
	END Monitor2

