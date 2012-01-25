;-----------------------------------------------------------------------
; Alternate Multiplex Interrupt Specification Library
; AMISPSP.ASM	Public Domain 1997 Ralf Brown
;		You may do with this software whatever you want, but
;		common courtesy dictates that you not remove my name
;		from it.
;
; Version 0.94
; LastEdit: 1/04/97
;-----------------------------------------------------------------------

	INCLUDE AMIS.MAC

TSRcode@
EXTRN $AMIS$resident_PSP
TSRcodeEnd@

;-----------------------------------------------------------------------

_TEXT SEGMENT PUBLIC BYTE 'CODE'
	ASSUME	CS:_TEXT

IFDEF __TINY__
EXTRN TGROUP@:word
ENDIF

;-----------------------------------------------------------------------
; entry:
; exit:
;
public $AMIS$copy_PSP
$AMIS$copy_PSP proc DIST
	mov	ax,TGROUP@
	push	si
	push	di
	push	es
	mov	es,ax
	ASSUME	ES:TGROUP
	mov	di,offset TGROUP:$AMIS$resident_PSP
	mov	ah,51h			; ask DOS for current PSP
	int	21h
	mov	ax,bx
	push	ds
	mov	ds,ax
	xor	si,si
	mov	cx,TSRpsp_size
	rep	movsb			; copy the PSP data area
 ;
 ; copy the JFT into the PSP if it has been relocated
 ;
	cmp	ax,ds:[0036h]		; check JFT segment
	je	JFT_copied
	push	ds
	lds	si,ds:[0034h]		; get JFT pointer
	mov	cx,ds:[0032h]		; get JFT length
	mov	di,0018h		; point at JFT in copied PSP
	cmp	cx,20
	jb	small_JFT
	mov	cx,20
small_JFT:
	cld
	rep	movsb			; copy the JFT
	pop	ds
JFT_copied:
	mov	es:[36h],es		; adjust JFT pointer in copied PSP
	mov	word ptr es:[34h],0018h
 ;
 ; "close" all user files in the original PSP
 ;
	les	di,ds:[0034h]		; get JFT pointer
	mov	cx,ds:[0032h]		; get JFT length
	add	di,5
	sub	cx,5
	mov	al,0FFh
	rep	stosb			; "close" all user files
 ;
 ; dup the standard handles
 ;

	pop	ds
	ASSUME	DS:NOTHING
	pop	es
	ASSUME	ES:NOTHING
	pop	di
	pop	si
	ret
$AMIS$copy_PSP endp

;-----------------------------------------------------------------------

_TEXT ENDS
	END

