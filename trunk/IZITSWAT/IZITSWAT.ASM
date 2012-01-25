;' $Header$
	title	IZITSWAT -- Is SWAT Loaded
	page	58,122
	name	IZITSWAT

COMMENT|		Module Specifications

Copyright:  (C) Copyright 2001 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, byte-aligned,  stack,  class 'prog'
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Tail    segment DTAIL, byte-aligned,  public, class 'data'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, February, 2001.

Modifications by:  None.

|

.186
.xlist
	include MASM.INC
	include DOSCALL.INC
	include IOCTL.INC
.list

PGROUP	group	STACK,CODE,DATA,DTAIL


; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	segment byte stack 'prog' ; Start STACK segment
STACK	ends			; End STACK segment


DATA	segment dword public 'data' ; Start DATA segment
	assume	ds:PGROUP

	public	ERRCODE
ERRCODE db	0		; Return code (0=not present)

	public	SWATNAME
SWATNAME db	'386SWAT$',0    ; 386SWAT device name

DATA	ends			; End DATA segment


; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

DTAIL	segment byte public 'data' ; Start DTAIL segment
	assume	ds:PGROUP

	public	ZTAIL
ZTAIL	label	byte

DTAIL	ends			; End DTAIL segment


CODE	segment byte public 'prog' ; Start CODE segment
	assume	cs:PGROUP
.xlist
;;;;;;; include PSP.INC 	; Define & skip over PSP area for .COM program
	org	100h
.list
	NPPROC	IZITSWAT -- Is SWAT Present
	assume	ds:PGROUP,es:PGROUP,ss:nothing

; Open the device

	mov	al,0		; Code for read-only
	DOSCALL @OPENF2,SWATNAME ; Open it
	jc	short IZITSWAT_ERR ; Jump if error

	mov	bx,ax		; Copy to handle register

; Ensure it's a device driver

	mov	al,0		; Code to get device info
	DOSCALL @IOCTL2 	; Return with DX = device info
	pushf			; Save CF from DOSCALL
	DOSCALL @CLOSF2 	; Close the file
	popf			; Restore
	jc	short IZITSWAT_ERR ; Jump if IOCTL failed

	test	dx,@IOCTL_DEV	; Izit a device?
	jz	short IZITSWAT_ERR ; Jump if not

	mov	ERRCODE,1	; Mark as present
IZITSWAT_ERR:
	mov	al,ERRCODE	; Get return code
	DOSCALL @EXITRC 	; Return to DOS

	assume	ds:nothing,es:nothing,ss:nothing

IZITSWAT endp			; End IZITSWAT procedure

CODE	ends			; End CODE segment

	MEND	IZITSWAT	; End IZITSWAT module
