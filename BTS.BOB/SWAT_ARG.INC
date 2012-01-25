;' $Header:   P:/PVCS/386SWAT/SWAT_ARG.INV   1.6   23 Jan 1995 11:08:54   BOB  $
;
; (C) Copyright 1987-2002 Qualitas, Inc.  All rights reserved.
;
; SWAT_ARG.INC
;
; Equates for ARG_FLAG
;

@ARG_ALTSCR  equ 8000h		; ALTSCR
@ARG_FVM     equ 4000h		; VIDEO= present and valid
@ARG_NMI     equ 2000h		; TRAPNMI
@ARG_DIVO    equ 1000h		; TRAPDIV
@ARG_SEGNP   equ 0800h		; TRAPSEGNP
@ARG_BOUND   equ 0400h		; TRAPBOUND
@ARG_STEP    equ 0200h		; TRAPSTEP or TRAPDEBUG
@ARG_INV     equ 0100h		; TRAPINV
@ARG_GENP    equ 0080h		; TRAPGENP
@ARG_PAGE    equ 0040h		; TRAPPAGE
@ARG_DVGA    equ 0020h		; DVGA
@ARG_LCD     equ 0010h		; LCD
@ARG_DPMI    equ 0008h		; SYMLOAD or SYMLOAD=
@ARG_DBGVMI  equ 0004h		; DEBUG=VMI
@ARG_LOADHI  equ 0002h		; LOADHIGH present
@ARG_SKIP    equ 0001h		; TRAPSKIP or TRAPDEBUG

