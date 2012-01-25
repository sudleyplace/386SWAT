;' $Header:   P:/PVCS/386SWAT/SWAT_LC2.INV   1.9   10 Aug 1998 11:01:14   BOB  $
;
; (C) Copyright 1987-98 Qualitas, Inc.	All rights reserved.
;
; SWAT_LC2.INC
;
; Equates for LC2_FLAG
;

LC2_REC  record  $LC2_MSG:1, \
		 $LC2_RS :1, \
		 $LC2_486:1, \
		 $LC2_NDP:1, \
		 $LC2_PS4:1, \
		 $LC2_ESC:1, \
		 $LC2_BCT:1, \
		 $LC2_TDB:1, \
		 $LC2_LSTSCR:1, \
		 $LC2_SRC:1, \
		 $LC2_IGNMOD:1, \
		 $LC2_NOLINE:1, \
		 $LC2_SFND:1, \
		 $LC2_COLDBOOT:1, \
		 $LC2_MONITOR:1;

@LC2_MSG      equ mask $LC2_MSG      ; 4000:  Message to be displayed
@LC2_RS       equ mask $LC2_RS	     ; 2000:  Register save area in use
@LC2_486      equ mask $LC2_486      ; 1000:  Processor is a 486
@LC2_NDP      equ mask $LC2_NDP      ; 0800:  NDP present
@LC2_PS4      equ mask $LC2_PS4      ; 0400:  Periscope 4 board present
@LC2_ESC      equ mask $LC2_ESC      ; 0200:  Escape from instruction sequence
@LC2_BCT      equ mask $LC2_BCT      ; 0100:  BC trace in effect
@LC2_TDB      equ mask $LC2_TDB      ; 0080:  TSS_DBG bit to be cleared next time
@LC2_LSTSCR   equ mask $LC2_LSTSCR   ; 0040:  Last screen buffers initialized
@LC2_SRC      equ mask $LC2_SRC      ; 0020:  In source browse mode
@LC2_IGNMOD   equ mask $LC2_IGNMOD   ; 0010:  Ignore module name in source browse mode
@LC2_NOLINE   equ mask $LC2_NOLINE   ; 0008:  Don't display line numbers in F9 screen
@LC2_SFND     equ mask $LC2_SFND     ; 0004:  Current instruction is a line number
@LC2_COLDBOOT equ mask $LC2_COLDBOOT ; 0002:  Treat Ctrl-Alt-Del as cold boot
@LC2_MONITOR  equ mask $LC2_MONITOR  ; 0001:  Single-stepping in monitor mode

