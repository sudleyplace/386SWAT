;' $Header:   P:/PVCS/386SWAT/SWAT_INT.INV   1.4   02 Apr 1993 11:52:58   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; SWAT_INT.INC
;
; Equates for INT_FLAG
;

.xcref INTFL_REC
INTFL_REC record $INT_I08:1,	\
		 $INT_I09:1,	\
		 $INT_Q0:1 ,	\
		 $INT_Q1:1 ,	\
		 $INT_Q2:1 ,	\
		 $INT_Q7:1 ,	\
		 $INT_Q12:1,	\
		 $INT_Q14:1,	\
		 $INT_Q15:1,	\
		 $INT_RSV:7

@INT_I08 equ	 mask $INT_I08	; Reflect INT 08h to VM86 mode
@INT_I09 equ	 mask $INT_I09	; ...	      09h ...
@INT_Q0  equ	 mask $INT_Q0	; IDT too small for IRQ0
@INT_Q1  equ	 mask $INT_Q1	; ...		    IRQ1
@INT_Q2  equ	 mask $INT_Q2	; ...		    IRQ2
@INT_Q7  equ	 mask $INT_Q7	; ...		    IRQ7
@INT_Q12 equ	 mask $INT_Q12	; ...		    IRQ12
@INT_Q14 equ	 mask $INT_Q14	; ...		    IRQ14
@INT_Q15 equ	 mask $INT_Q15	; ...		    IRQ15

