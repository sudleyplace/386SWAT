;-----------------------------------------------------------------------
; Alternate Multiplex Interrupt Specification Library
; AMIS.ASM	Public Domain 1992,1995,1997 Ralf Brown
;		You may do with this software whatever you want, but
;		common courtesy dictates that you not remove my name
;		from it.
;
; Version 0.94
; LastEdit: 1/04/97
;-----------------------------------------------------------------------

	INCLUDE AMIS.MAC

TSRcode@
EXTRN $AMIS$HOOKED_INT_LIST:BYTE
EXTRN $AMIS$MULTIPLEX_NUMBER:BYTE
TSRcodeEnd@

EXTRN __psp:WORD

;-----------------------------------------------------------------------

_TEXT SEGMENT PUBLIC BYTE 'CODE'
	ASSUME	CS:_TEXT

;-----------------------------------------------------------------------

alloc_strat	dw 0
installed_low	db 0
link_state	db 0	; are UMBs part of memory chain?
install_flags	db 0	; mpx_number must immediately follow
mpx_number	db 0	; multiplex number to install on/when uninstalling

;-----------------------------------------------------------------------
; Terminate back to DOS.  Depending on where the resident code was moved,
; the program will be terminated either with a normal terminate call or
; with a terminate-and-stay-resident call.
;
public $AMIS$go_TSR
$AMIS$go_TSR proc DIST
	cmp	installed_low,0
	jz	go_TSR_resized
	db	0BBh			; MOV	BX,IMM16
resident_size	dw 0			; number of paras to keep on going TSR
	mov	ah,4Ah			; resize memory block
	mov	dx,__psp		; block to resize is original PSP
	mov	es,dx
	int	21h
	mov	ax,dx
	dec	dx			; point at MCB for PSP block
	mov	es,dx
	mov	es:[1],ax		; make memblock its own owner again
go_TSR_resized:
	db	0B8h			; MOV	AX,4Cxxh
exit_code	db 0
	db	4Ch 
	int	21h			; exit the program
$AMIS$go_TSR endp

;-----------------------------------------------------------------------
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
public check_if_installed
check_if_installed proc DIST
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
	stc				; assume already installed
	jz	chk_installed_done	;   and quit if it is
chk_installed_next:
	inc	ah
	jnz	chk_installed_loop
; not yet installed
	clc
	mov	ah,bh			; AH <- multiplex number to use
	mov	al,bl			; AL <- 'available' flag
chk_installed_done:
	pop	bx
	pop	dx
	pop	di
	pop	es
	pop	si
	pop	ds
	ASSUME	DS:NOTHING,ES:NOTHING
	ret
check_if_installed endp

;-----------------------------------------------------------------------
; Call the XMS driver to allocate an upper memory block
;
; entry: DX = number of paragraphs needed
; exit:	 ZF set if successful
;	     BX = segment address of UMB
;
alloc_UMB proc near
	mov	ah,10h
	;; fall through to XMS ;;
alloc_UMB endp

;-----------------------------------------------------------------------
; Call the XMS driver
;
; entry: all registers as needed for XMS call
; exit:	 registers as returned by XMS driver
;	 ZF set if successful, ZF clear if failure
;
XMS proc near
	db	09Ah	; FAR CALL
xms_entry dd	0	; XMS driver's entry point
	cmp	ax,1
	ret
XMS endp

;-----------------------------------------------------------------------
; Determine entry point of XMS driver and initialize procedure XMS to call
; that entry point
;
; exit: CF set if no XMS driver or other failure
;	CF clear if initialization successful
;	AX,BX destroyed
;
get_XMS_entry proc near
	push	es
	mov	ax,352Fh
	int	21h			; find out whether INT 2F is valid
	mov	ax,es
	or	ax,bx			; don't try XMS if INT 2F is NULL
	jz	no_XMS_driver		; (could be case under DOS 2.x)
	mov	ax,4300h		; see if XMS is installed
	int	2Fh
	cmp	al,80h			; did XMS respond?
	jnz	no_XMS_driver
	mov	ax,4310h		; if XMS present, get its entry point
	int	2Fh
	mov	word ptr xms_entry,bx
	mov	word ptr xms_entry+2,es ; and store entry point for call
	pop	es
	clc
	ret
no_XMS_driver:
	pop	es
	stc
	ret
get_XMS_entry endp

;-----------------------------------------------------------------------
; Get an Upper Memory Block from the XMS driver; depending on the
; installation flags, this block will either be the first one available
; or the one closest in size to the requested amount
;
; entry: AX = number of paragraphs needed
; exit:	 AX = segment of UMB or 0000h if unable to allocate one
;
allocate_UMB proc near
	mov	dx,ax			; remember amount of memory to alloc
	call	get_XMS_entry
	jc	no_XMS_avail
	test	install_flags,BEST_FIT
	jnz	alloc_bestfit_UMB	; DX = amount to request
alloc_XMS:
	call	alloc_UMB		; ask XMS for the memory
	mov	ax,bx			; (BX -> UMB if successful)
	je	allocate_UMB_done	; if we got the mem, return now
no_XMS_avail:
	xor	ax,ax			; return segment 0 if no UMB
allocate_UMB_done:
	ret
allocate_UMB endp

alloc_bestfit_UMB proc near
	push	si
	push	di
 @alloc_size = SI
 @umb_addr = DI
	mov	@alloc_size,dx		; remember how much to request
	mov	dx,0FFFFh		; try 1 meg
	call	alloc_UMB		; ask XMS for the memory
	je	XMM_broken		; if we got it, XMM seriously broken!
	cmp	dx,@alloc_size		; DX = largest available
	jb	UMB_too_small		; not enough high memory left
	call	alloc_UMB		; allocate the largest UMB
	jne	XMM_broken		; if we didn't get it, XMM broken
	mov	@umb_addr,bx		; remember UMB address
	mov	dx,@alloc_size
	call	alloc_bestfit_UMB	; recurse
	or	ax,ax
	jnz	got_block
	mov	ah,11h			; deallocate UMB
	mov	dx,@umb_addr
	call	XMS
	mov	dx,@alloc_size
	call	alloc_UMB		; ask XMS driver for the memory
	jne	UMB_too_small		; did we get it?
	mov	ax,bx			; BX = addr of UMB
	jmp short alloc_best_done

got_block:
	push	ax			; remember address to return
	mov	ah,11h			; deallocate UMB
	mov	dx,@umb_addr
	call	XMS
	pop	ax			; retrieve return value
	jmp short alloc_best_done

XMM_broken:
UMB_too_small:
	xor	ax,ax			; didn't get anything
alloc_best_done:
	pop	di
	pop	si
	ret
alloc_bestfit_UMB endp

;-----------------------------------------------------------------------
; entry: nothing
; exit:	 CF set if not available, clear if available
;	 AX,BX,CX,DX destroyed
;	 if available, DOS5 UMBs have been linked into the memory chain
;
check_if_DOS5_UMBs proc near
	mov	ax,5800h
	int	21h			; get current allocation strategy
	mov	alloc_strat,ax		;   and remember it for later restore
	mov	ax,5802h		; get current state of UMB linkage
	int	21h
	mov	link_state,al
	mov	ax,3000h		; get DOS version
	int	21h
	cmp	al,5			; DOS 5.0 or higher?
	jb	no_DOS5_UMBs
	cmp	al,10			; but make sure not OS/2 penalty box
	jae	no_DOS5_UMBs
	mov	ax,2B01h
	mov	cx,4445h
	mov	dx,5351h
	int	21h			; check if DESQview running
	cmp	al,0FFh			; if yes, no UMB's to be allocated
	jne	no_DOS5_UMBs
	mov	ax,5803h
	mov	bx,1			; try to link in UMBs
	int	21h
	mov	ax,5802h		; get new link state
	int	21h
	cmp	al,1
	jne	no_DOS5_UMBs
	clc				; yes, we have UMBs
	ret

no_DOS5_UMBs:
	stc
	ret
check_if_DOS5_UMBs endp

;-----------------------------------------------------------------------
;
; entry: nothing
; exit:	 CF set on error
;	 CF clear if successful
;		AX = segment of memory block
;

alloc_new_PSP proc near
	mov	ax,5801h		; set allocation strategy
	mov	bx,0002h		;   to low-memory last-fit
	int	21h
	mov	bx,4			; need four paras for needed PSP fields
	jmp short alloc_DOS_memblock
alloc_new_PSP endp

;-----------------------------------------------------------------------
;
; entry: BX = memory allocation strategy
; exit:	 CF set on error
;	 CF clear if successful
;		AX = segment of memory block
;
alloc_DOS_highmem proc near
	mov	ax,5801h		; set allocation strategy
	int	21h
	mov	bx,resident_size	; this is how much memory we need
alloc_DOS_memblock:
	mov	ah,48h			; allocate memory
	int	21h			; try to allocate the UMB
	pushf				; remember whether we succeeded
	jc	no_highmem		; did we succeed?
	push	ax			; yes, so remember where to relocate
	dec	ax			; address the MCB for our new memory
	mov	es,ax			;   block
	inc	ax			; back to relocation segment
	mov	word ptr es:[1],ax	; make the memory block own itself
	mov	ah,51h			; get current PSP
	int	21h
	dec	bx			; back to MCB for main memory block
	push	ds
	mov	ds,bx			; point at MCB
	ASSUME	DS:NOTHING
	push	si
	push	di
	mov	si,8
	mov	di,si
	cld
	movsw				; copy the DOS 4.0+ program name into
	movsw				;   the new memory block's MCB
	movsw
	movsw
	pop	di
	pop	si
	pop	ds
	ASSUME	DS:NOTHING
	pop	ax			; retrieve relocation address
;---------------------------
; Reasons for mucking with the MCB:
;    DOS 5 will release any memory blocks owned by the program when
;    it exits without going TSR, even if the blocks are in high memory
;    and high memory has been disconnected from the memory chain.  So,
;    we need to change the owner field such that DOS thinks it belongs to
;    somebody else and doesn't release it when we exit.
;---------------------------
no_highmem:
	popf				; get back whether we were successful
restore_link_state:
	pushf				; store flags, especially CF
	push	ax
	mov	ax,5801h
	mov	bx,alloc_strat		; restore allocation strategy
	int	21h
	mov	ax,5803h		; and restore UMB link status
	mov	bh,0
	mov	bl,link_state
	int	21h
	pop	ax
	popf				; get back flags
	ret
alloc_DOS_highmem endp

;-----------------------------------------------------------------------
; entry: AL = flags
;		bit 0 = use first-fit alloc, nonzero = use best-fit alloc
;		bit 1 = use UMB only, never conventional memory
;		bit 2 = use low 640K only even if UMB available
;	 AH = multiplex number
;	 BX = segment of resident code
;	 CX = size of resident code in paragraphs
;	 DX = additional paragraphs
; exit:	 CF clear if successful
;	     AX = segment at which TSR was installed
;	 CF set on error
;
public $AMIS$install_TSR
$AMIS$install_TSR proc DIST
	push	es
	push	si
	push	di
	mov	word ptr install_flags,ax ; set both install_flags & mpx_number
	push	bx			; remember segment of resident code
	push	cx			; remember size of resident code
	add	cx,dx
	mov	resident_size,cx
 ;
 ; first, see if we can load into a DOS5 UMB (this is preferred because
 ; 386MAX will give us an XMS UMB even if DOS5 has grabbed them, but at
 ; a cost of an extra 80 bytes of overhead).
 ;
	test	al,LOW_ONLY
	jnz	not_XMS
	call	check_if_DOS5_UMBs	; check if UMBs avail, and link them in
	jc	not_dos5
	mov	bx,40h			; alloc high memory only, first-fit
	test	install_flags,BEST_FIT
	jz	go_allocate_DOS_highmem
	inc	bx			; BX <- 41h = alloc high only, best-fit
go_allocate_DOS_highmem:
	call	alloc_DOS_highmem
	jnc	relocate_TSR_code	; if successful, go install
 ;
 ; if not DOS5, see if we can load into an XMS upper memory block
 ;
not_dos5:
	mov	ax,resident_size
	call	allocate_UMB		; try to get AX paragraphs
	or	ax,ax			; did we get a UMB?
	jnz	relocate_TSR_code	; if yes, go install at segment AX

 ;
 ; if not XMS, see whether we are allowed to load into conventional memory;
 ; if yes, check whether we are supposed to load at the high or low end of
 ; conventional memory
 ;
not_XMS:
	test	install_flags,UMB_ONLY
	jz	install_low
install_failure:
	pop	cx			; clean up stack
	pop	bx
	jmp	install_failed
 ;
 ; as a last resort, use low memory to store the code
 ;
install_low:
	mov	es,__psp
	xor	ax,ax
	xchg	ax,es:[002Ch]		; get and zero environment segment
	mov	es,ax
	ASSUME	ES:NOTHING
	mov	ah,49h			; since we may change the PSP segment,
	int	21h			;   discard our environment manually
 ;
 ; see if there is sufficient memory below our PSP (e.g. from the just-freed
 ; environment) to store the resident portion of the TSR
 ;
	mov	bx,0000h		; allocate first-fit
	call	alloc_DOS_highmem
	jc	use_PSP_for_TSR
	cmp	ax,__psp
	jb	relocate_TSR_code
	ASSUME	ES:NOTHING
	mov	es,ax			; the memory block was above our PSP,
	mov	ah,49h			;   so free it to avoid memory
	int	21h			;   fragmentation
 ;
 ; there wasn't enough memory below ourself, so go ahead and re-use our own
 ; PSP to store the resident code and data
 ;
use_PSP_for_TSR:
	mov	installed_low,1
	call	alloc_new_PSP
	jc	install_failure		; can't install if no mem available
	mov	es,ax			; point at new memory block
	ASSUME	ES:NOTHING
	push	ds
	mov	bx,__psp
	mov	ds,bx
	ASSUME	DS:NOTHING
	xor	si,si
	xor	di,di
	mov	cx,64/2
	rep	movsw			; copy needed part of PSP into new blk
	pop	ds
	cmp	es:[0036h],bx		; is JFT still in the PSP?
	jne	JFT_relocated
	mov	es:[0036h],es		; move JFT into new copy of PSP
JFT_relocated:
	ASSUME	DS:NOTHING
	mov	bx,ax
	mov	ah,50h			; set PSP segment to new PSP
	int	21h
	mov	ax,__psp		; relocate into original PSP
 ;
 ; relocate TSR code into the PSP or UMB
 ; at this point, AX must be the segment at which to relocate
 ;
relocate_TSR_code:
	pop	cx			; get back TSR code size in paragraphs
	pop	bx			; get back TSR code segment
	push	ds
	mov	ds,bx
	ASSUME	DS:NOTHING
	mov	es,ax			; ES -> resident_seg
	ASSUME	ES:NOTHING
	xor	si,si
	xor	di,di
	mov	ax,16			; bytes per paragraph
	mul	cx			; get size in bytes
	or	dx,dx
	jnz	install_failed_pop	; can only handle 64K at this time
	mov	cx,ax			; number of bytes to copy
	cld
	rep	movsb			; copy the TSR's code
	mov	al,mpx_number		; patch the multiplex number in the
	mov	es:[$AMIS$MULTIPLEX_NUMBER],al ;  resident code
	push	es			; remember resident segment
	push	es
	pop	ds			; DS -> resident_seg
	mov	si,offset TGROUP:$AMIS$HOOKED_INT_LIST
hook_interrupts:
	lodsb				; get interrupt number
	mov	ah,35h			; get interrupt vector
	int	21h
	mov	dx,bx			; ES:DX -> prev handler
	mov	bx,[si]			; get offset of interrupt handler
	inc	si
	inc	si
	mov	[bx+2],dx		; set 'previous' pointer in ISP header
	mov	[bx+4],es
	mov	dx,bx			; DS:DX -> our handler
	mov	ah,25h			; AL still interrupt number
	int	21h			; hook the interrupt
	cmp	al,2Dh			; INT 2Dh is last in hook list
	jne	hook_interrupts
	pop	ax			; AX <- resident_seg
	pop	ds
;	clc				; we were successful ;(CF already clear)
install_TSR_done:
	pop	di
	pop	si
	pop	es
	ret

install_failed_pop:
	pop	ds
install_failed:
	stc				; signal installation failure
	jmp	install_TSR_done
$AMIS$install_TSR endp

;-----------------------------------------------------------------------
; entry: DS:SI -> hooked interrupt list
; exit:	 AX, BX, CX, DX destroyed
;	 CF set if unable to unhook all vectors
;	 CF clear if successful
;
public unhook_interrupts
unhook_interrupts proc DIST
	push	es
	push	ds
	push	di
	push	si
	cld
chk_unhook_loop:
	lodsb
	mov	dx,[si]			; get offset of interrupt handler
	inc	si			;   and skip that field in the hook
	inc	si			;   list
	cmp	al,2Dh
	je	all_unhookable
	mov	ah,35h
	int	21h			; get interrupt vector
	mov	ax,es
	mov	cx,ds
	cmp	ax,cx			; check segment agains of vectors
	jne	chk_isp_loop
	cmp	dx,bx			; check offset of vector against ours
	je	chk_unhook_loop		; this int is unhookable if same
chk_isp_loop:
	cmp	word ptr es:[bx],10EBh	; handler starts with JMP SHORT $+12 ?
	jne	not_unhookable
	cmp	word ptr es:[bx+6],424Bh ; valid signature?
	jne	not_unhookable
	cmp	byte ptr es:[bx+9],0EBh ; hardware reset must also be JMP SHORT
	jne	not_unhookable
	cmp	cx,word ptr es:[bx+4]	; check segment of next ptr against ours
	jne	chk_next_isp
	cmp	dx,word ptr es:[bx+2]	; check offset of next ptr against ours
	je	chk_unhook_loop		; this int is unhookable if same
chk_next_isp:
	les	bx,es:[bx+2]		; advance to next ISP header
	jmp	chk_isp_loop		;   and test it

not_unhookable:
	stc
unhook_ints_done:
	pop	si
	pop	di
	pop	ds
	pop	es
	ret

all_unhookable:
	pop	si			; get back start of hook list
	push	si			; and preserve SI for return
unhook_loop:
	lodsb
	mov	dx,[si]
	inc	si
	inc	si
	push	ds
	push	ax
	mov	ah,35h
	int	21h			; get interrupt vector
	mov	ax,es
	mov	cx,ds
	cmp	ax,cx			; check segments of vectors
	jne	isp_loop
	cmp	dx,bx			; check offsets of vectors
	jne	isp_loop
	lds	dx,[bx+2]		; get our old_int?? pointer
	pop	ax
	push	ax
	mov	ah,25h			; set interrupt vector
	int	21h
	jmp short unhooked_interrupt
isp_next:
	les	bx,es:[bx+2]		; advance to next ISP header
isp_loop:
;
; no need to check for a valid ISP header, as we already know all chains reach
; our header before non-ISP code
;
	cmp	cx,es:[bx+4]		; check segment of 'previous' ptr
	jne	isp_next
	cmp	dx,es:[bx+2]		; check offset of 'previous' ptr
	jne	isp_next
	xchg	bx,dx
	lds	bx,[bx+2]
	xchg	bx,dx			; ES:BX -> previous ISP
					; DS:DX -> next ISP
	mov	es:[bx+2],dx		; prev->next = curr->next
	mov	es:[bx+4],ds		;    thus, we are now unhooked
unhooked_interrupt:
	pop	ax
	pop	ds
	cmp	al,2Dh
	jne	unhook_loop
	clc				; indicate success
	jmp	unhook_ints_done
unhook_interrupts endp

;-----------------------------------------------------------------------
; entry: DX:AX -> TSR signature string
; exit:	 CF clear if successful
;	 CF set on error
;	 AX,BX,CX,DX destroyed
;
public $AMIS$uninstall_TSR
$AMIS$uninstall_TSR proc DIST
	push	es
	call	check_if_installed
	jnc	not_installed
	;
	; TSR is installed, AH=multiplex number
	;
	mov	mpx_number,ah
	;
	; first, see whether the TSR can uninstall itself
	;
	mov	al,2
	mov	dx,cs			; load return address for success
	mov	bx,offset _TEXT:uninstall_successful
	int	2Dh
	cmp	al,0FFh			; successful?
	je	uninstall_successful
	cmp	al,02h			; will uninstall itself
	je	uninstall_successful
	cmp	al,01h			; unable to remove at this time?
	je	uninstall_failed
	cmp	al,05h			; unknown return code?
	jae	uninstall_failed
	;
	; TSR said it is safe to uninstall, but not able to do so itself,
	; so now we find out which interrupts it has hooked
	;
	mov	es,bx			; point ES at memory block to be freed
	ASSUME	ES:NOTHING
uninst_chk_int_loop:
	mov	ah,mpx_number
	mov	al,4
	mov	bl,0			; start with INT 00h
	int	2Dh
	cmp	al,1			; function unsupported or can't determine?
	jbe	uninstall_failed
	cmp	al,4
	je	go_uninstall

;	jmp short uninstall_failed	; sorry, can't handle returns 02h/03h yet
uninstall_failed:
not_installed:
	pop	es			; clean up stack
	stc				; indicate error
	ret

go_uninstall:
	push	ds
	push	si
	mov	ds,dx			; DS:SI -> hook list
	mov	si,bx
	call	unhook_interrupts
	pop	si
	pop	ds
	jc	uninstall_failed
	mov	ax,es			; get segment of memory block
	cmp	ax,0B000h		; regular DOS memblk if below video
	jae	uninstall_highmem
	mov	ah,49h			; free memory block
	int	21h
uninstall_successful:
	pop	es			; clean up stack
	clc				; indicate success
	ret

uninstall_highmem:
	call	check_if_DOS5_UMBs	; check if UMBs, and link them in
	jc	uninstall_XMS
	mov	ah,49h			; free the memory block via DOS
	int	21h			;   (ES already points at block)
	call	restore_link_state
	jmp	uninstall_successful

uninstall_XMS:
	call	get_XMS_entry
	jc	uninstall_failed	; no XMS driver!?!?!
	mov	ah,11h			; release UMB
	mov	dx,es			; set DX to UMB segment
	call	XMS
	jne	uninstall_failed	; we deallocation successful?
	jmp	uninstall_successful
$AMIS$uninstall_TSR endp

;-----------------------------------------------------------------------

_TEXT ENDS
	END

