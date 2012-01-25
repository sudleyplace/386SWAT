;' $Header:   P:/PVCS/386SWAT/SWAT_LC4.INV   1.9   10 Aug 1998 11:01:14   BOB  $
;
; (C) Copyright 1987-98 Qualitas, Inc.	All rights reserved.
;
; SWAT_LC4.INC
;
; Record and Equates for LC4_FLAG
;

LC4_REC record	 \
		 $LC4_INTPL0:1, \
		 $LC4_ERRLOG:1, \
		 $LC4_CMDNEW:1, \
		 $LC4_NOGD:1,	\
		 $LC4_LBRWIN:1, \
		 $LC4_LBR:1,	\
		 $LC4_BTF:1,	\
		 $LC4_MONCMD:1, \
		 $LC4_SETUP:1,	\
		 $LC4_AFLCHK:1, \
		 $LC4_AFLTBD:1, \
		 $LC4_DIVO:1,	\
		 $LC4_BOUND:1,	\
		 $LC4_SEGNP:1,	\
		 $LC4_CTRACE:1

@LC4_INTPL0 equ  mask $LC4_INTPL0 ; 4000:  Trap INTs 01h & 03h in PL0 only
@LC4_ERRLOG equ  mask $LC4_ERRLOG ; 2000:  Display error log, return keystroke
@LC4_CMDNEW equ  mask $LC4_CMDNEW ; 1000:  The current command is new
@LC4_NOGD   equ  mask $LC4_NOGD   ; 0800:  Set = Don't automatically set GD bit in DR7
@LC4_LBRWIN equ  mask $LC4_LBRWIN ; 0400:  Set = Enable LBR window display
@LC4_LBR    equ  mask $LC4_LBR	  ; 0200:  Set = Enable LBR
@LC4_BTF   equ	 mask $LC4_BTF	  ; 0100:  Set = Enable BTF
@LC4_MONCMD equ  mask $LC4_MONCMD ; 0080:  Set = GM command entered
@LC4_SETUP equ	 mask $LC4_SETUP  ; 0040:  Set = SETUP has been run
@LC4_AFLCHK equ  mask $LC4_AFLCHK ; 0020:  Set = AutoFault already checked
@LC4_AFLTBD equ  mask $LC4_AFLTBD ; 0010:  Set = AutoFault message present and
				  ;		 not displayed as yet
@LC4_DIVO equ	 mask $LC4_DIVO   ; 0008:  Set = Intercept INT 00h
				  ;	   Clr = Don't
@LC4_BOUND equ	 mask $LC4_BOUND  ; 0004:  Set = Intercept INT 05h
				  ;	   Clr = Don't
@LC4_SEGNP equ	 mask $LC4_SEGNP  ; 0002:  Set = Intercept INT 0Bh
				  ;	   Clr = Don't
@LC4_CTRACE equ  mask $LC4_CTRACE ; 0001:  Set = if tracing INT, G .PMIxx
				  ;	   Clr = Don't

