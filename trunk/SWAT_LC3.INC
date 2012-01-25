;' $Header:   P:/PVCS/386SWAT/SWAT_LC3.INV   1.5   30 Jul 1994 11:23:32   BOB  $
;
; (C) Copyright 1987-94 Qualitas, Inc.	All rights reserved.
;
; SWAT_LC3.INC
;
; Record and Equates for LC3_FLAG
;

LC3_REC  record  $LC3_INV:1,\
		 $LC3_SKIP:1,\
		 $LC3_STEP:1,\
		 $LC3_REM:1,\
		 $LC3_SLAVE:1,\
		 $LC3_SERINT:1,\
		 $LC3_RSUSPEND:1,\
		 $LC3_PORTINIT:1,\
		 $LC3_SERINIT:1,\
		 $LC3_EXITSWAT:1,\
		 $LC3_NOVID:1,\
		 $LC3_COMMAND:1,\
		 $LC3_INTERNAL:1,\
		 $LC3_SIGINT:1,\
		 $LC3_STK:1,\
		 $LC3_TSS:1

@LC3_INV      equ mask $LC3_INV      ; 8000:  Set = Intercept INT 06h
				     ;	      Clr = Don't
@LC3_SKIP     equ mask $LC3_SKIP     ; 4000:  Set = Intercept INT 03h
				     ;	      Clr = Don't
@LC3_STEP     equ mask $LC3_STEP     ; 2000:  Set = Intercept INT 01h
				     ;	      Clr = Don't
@LC3_REM      equ mask $LC3_REM      ; 1000:  Set = Serial port active
				     ;	      Clr = Ignore serial port activity
@LC3_SLAVE    equ mask $LC3_SLAVE    ; 0800:  Set = Acting as slave in remote debugging
				     ;	      Clr = Not
@LC3_SERINT   equ mask $LC3_SERINT   ; 0400:  Set = Interrupt-driven serial I/O active
				     ;	      Clr = Not
@LC3_RSUSPEND equ mask $LC3_RSUSPEND ; 0200:  Set = Remote session suspended by master
				     ;	      Clr = Not
@LC3_PORTINIT equ mask $LC3_PORTINIT ; 0100:  Set = Invoke CMD_REMDBG on next interrupt
				     ;	      Clr = Not
@LC3_SERINIT  equ mask $LC3_SERINIT  ; 0080:  Set = Call SER_INIT from SWATTER & exit
				     ;	      Clr = Not
@LC3_EXITSWAT equ mask $LC3_EXITSWAT ; 0040:  Set = Return Esc on all GETKEY calls
				     ;	      Clr = Normal GETKEY processing
@LC3_NOVID    equ mask $LC3_NOVID    ; 0020:  Set = Do not reprogram video controller
				     ;	      Clr = Normal video processing
@LC3_COMMAND  equ mask $LC3_COMMAND  ; 0010:  Set = Execute CMD_LINE and exit
				     ;	      Clr = Normal processing within SWATTER
@LC3_INTERNAL equ mask $LC3_INTERNAL ; 0008:  Set = Executing an internal command in SWATTER
				     ;	      Clr = Normal processing
@LC3_SIGINT   equ mask $LC3_SIGINT   ; 0004:  SIGINT in effect
@LC3_STK      equ mask $LC3_STK      ; 0002:  Set = Intercept INT 0Ch
				     ;	      Clr = Don't
@LC3_TSS      equ mask $LC3_TSS      ; 0001:  Set = Intercept INT 0Ah
				     ;	      Clr = Don't

