;-----------------------------------------------------------------------
; Alternate Multiplex Interrupt Specification Library
; AMISHOTK.ASM	Public Domain 1992,1995 Ralf Brown
;		You may do with this software whatever you want, but
;		common courtesy dictates that you not remove my name
;		from it.
;
; Version 0.92
; LastEdit: 9/24/95
;-----------------------------------------------------------------------

	INCLUDE AMIS.MAC

_TEXT SEGMENT PUBLIC BYTE 'CODE'
	ASSUME	CS:_TEXT

;-----------------------------------------------------------------------
; entry: AX,CX = required shift states for two TSRs
; exit:	 AX,CX adjusted
;
fix_multishifts proc near
	xchg	cx,ax
	call	fix_multishifts_0
	xchg	cx,ax
	;; fall through
fix_multishifts_0:
	test	ax,HK_ANYSHIFT
	jz	fms_1
	test	cx,HK_LSHIFT or HK_RSHIFT
	jz	fms_1
	and	ax,not HK_ANYSHIFT
fms_1:
	test	ax,HK_ANYCTRL
	jz	fms_2
	test	cx,HK_LCTRL or HK_RCTRL
	jz	fms_2
	and	ax,not HK_ANYCTRL
fms_2:
	test	ax,HK_ANYALT
	jz	fms_3
	test	cx,HK_LALT or HK_RALT
	jz	fms_3
	and	ax,not HK_ANYALT
fms_3:
	ret
fix_multishifts endp

;-----------------------------------------------------------------------
; entry: DS:SI -> hotkey list of already-installed TSR
;	 ES:DI -> hotkey list of current TSR
; exit:	 AX = conflict flags (see below)
;
check_hotkey_conflict proc near
	push	bp
	push	si
	xor	bp,bp			; no conflicts yet
	cld				; string operations move up in memory
	inc	si
	mov	cl,[si]			; number of hotkeys to check
	or	cl,cl			; any hotkeys?
	jz	chc_done
	inc	si			; skip list header
chc_loop:
	push	di
	inc	di
	mov	ch,es:[di]		; number of hotkeys in list
					; we already know this number is nonzero
	inc	di			; skip list header
chc_inner_loop:
	push	cx
	cmpsb				; check if scan codes the same
	jne	chc_inner_next		; skip if scan codes different
	mov	ax,[si]
	mov	bx,[si+2]
	mov	cx,es:[di]		; get required shift states
	mov	dx,es:[di+2]		; get disallowed shift states
	;
	; first, check for an exact match
	;
	cmp	cx,ax
	jne	chc_maybe_superset
	cmp	dx,bx
	jne	chc_maybe_superset
	mov	ax,HC_EXACT
	jmp short chc_set_conflict_flag
chc_maybe_superset:
	; superset if we require more shift states than the other one does
	; or if the other one has more disallowed shift states
	;
	; need special cases for either-shift vs one-shift, same for Ctrl,Alt
	;
	call	fix_multishifts
	;
	; after the preceding adjustments, check the bits
	;
	push	ax			; preserve AX
	not	ax
	test	ax,cx			; states not present in other?
	pop	ax			; restore AX
	jz	chc_maybe_superset_2
	push	dx			; preserve DX
	not	dx
	test	dx,bx			; states not present in ours?
	pop	dx			; restore DX
	jz	chc_maybe_subset
	;
	; now make sure it is a superset by doing the test the other way around
	;
chc_maybe_superset_2:
	not	cx
	test	cx,ax			; states not present in ours?
	jnz	chc_inner_next		; if yes, not a superset
	not	bx
	test	bx,dx			; states not present in other?
	jnz	chc_inner_next		; if yes, not a superset
	mov	ax,HC_SUPERSET
	jmp short chc_set_conflict_flag
chc_maybe_subset:
	; subset if we require fewer shift states than the other one does
	; or if we have more disallowed shift states
	;
	not	cx
	test	cx,ax			; states not present in ours?
	jz	chc_is_subset
	not	bx
	test	bx,dx			; states not present in other?
	jz	chc_inner_next
chc_is_subset:
	mov	ax,HC_SUBSET
chc_set_conflict_flag:
	test	byte ptr [si+4],HK_MONITOR
	jz	chc_set_flag
	test	byte ptr es:[di+4],HK_CHAINBEFORE or HK_CHAINAFTER
	jz	chc_set_flag
	mov	ax,HC_MONITOR		; no actual conflict, but let caller know
chc_set_flag:
	or	bp,ax
chc_inner_next:
	pop	cx
	add	di,5			; move to next hotkey record
	dec	ch
	jnz	chc_inner_loop
	pop	di
	add	si,5			; move to next hotkey record
	dec	cl
	jnz	chc_loop
chc_done:
	mov	ax,bp			; AX <- conflict flags
	pop	si
	pop	bp
	ret
check_hotkey_conflict endp

;-----------------------------------------------------------------------
; entry: DX:AX -> hotkey list
; exit:  ZF set if no hotkey conflicts
;	 ZF clear if hotkey conflict
;	 AX = type of conflicts
;		bit 0: one or more exact keys already in use
;		bit 1: one or more superset keys already in use
;		bit 2: one or more subset keys already in use
;		bit 7: some other TSR is monitors one of our passed-thru keys
;
public check_if_hotkeys_used
check_if_hotkeys_used proc DIST
	push	bp
	xor	bp,bp			; conflict flags; no conflicts yet
	push	es
	push	di
	mov	es,dx
	mov	di,ax
	cmp	byte ptr es:[di+1],0	; does this TSR have any hotkeys?
	je	cihu_done		; if not, no conflicts
	push	ds
	push	si
	mov	ah,0
check_hotkeys_loop:
	push	ax			; save multiplex number
	mov	al,0
	push	di
	int	2Dh
	pop	di
	cmp	al,AMIS_SUCCESSFUL
	jne	cihu_next
	pop	ax
	push	ax
	mov	al,5			; function "get hotkeys"
	int	2Dh
	cmp	al,AMIS_SUCCESSFUL
	jne	cihu_next
	mov	ds,dx
	mov	si,bx
	call	check_hotkey_conflict
	or	bp,ax			; add any conflicts to conflict flags
cihu_next:
	pop	ax			; get back multiplex number
	inc	ah
	jne	check_hotkeys_loop
	pop	si
	pop	ds
cihu_done:
	pop	di
	pop	es
	mov	ax,bp			; AX <- conflict flags
	pop	bp
	test	ax,HC_IS_CONFLICT	; set ZF if no conflicts
	ret
check_if_hotkeys_used endp


_TEXT ENDS
	END
