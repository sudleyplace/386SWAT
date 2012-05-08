;' $Header:   P:/PVCS/SWATVXD/SWAT_MAC.INV   1.1   01 Jul 1992 14:24:14   DAVID  $
;
; (C) Copyright 1990-92 Qualitas, Inc.	All rights reserved.
;
; SWAT_MAC.INC
;
; SWATVXD macros
;

SWAT	 macro	 FLG,MSK	; Call SWAT
	 local	 L2
ifnb	 <FLG>
	 test	 FLG,MSK	; Test SWAT option bit
	 jz	 short L2	; Skip trap if bit is not set
else
if1
% %OUT FIXME - Unguarded INT 1 in SWAT macro in procedure @CurProc
endif				; if1
endif				; ifnb <FLG>
	 int	 01h		; Trap into SWAT
L2:
	 endm			; SWAT macro

CHKPT	 macro	 NUMBER,FLG,MSK ; Checkpoint location via keyboard lights
	 local	 L2
ifnb	 <FLG>
	 test	 FLG,MSK	; Test SWAT option bit
	 jz	 short L2	; Skip trap if bit is not set
endif				; ifnb <FLG>
	 push	 NUMBER
	 call	 CHECKPOINT
L2:
	 endm			; CHKPT macro

