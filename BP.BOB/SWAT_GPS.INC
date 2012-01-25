;' $Header:   P:/PVCS/386SWAT/SWAT_GPS.INV   1.4   10 Apr 1995 14:11:14   BOB  $
;
; (C) Copyright 1992-5 Qualitas, Inc.  All rights reserved.
;
; SWAT_GPS.INC
;
; GP Skip records and equates
;

.xcref GPSKIP_REC
GPSKIP_REC record \
$GPSKIP_HLT:1, $GPSKIP_OUTD:1,$GPSKIP_OUTI:1, \
$GPSKIP_CRn:1, $GPSKIP_IND:1, $GPSKIP_INI:1,  \
$GPSKIP_INT:1, $GPSKIP_CLI:1, $GPSKIP_STI:1,  \
$GPSKIP_IRET:1,$GPSKIP_PPF:1, $GPSKIP_INS:1,  \
$GPSKIP_OUTS:1,$GPSKIP_FF:1

.xcref @GPSKIP_HLT, @GPSKIP_OUTD,@GPSKIP_OUTI,@GPSKIP_OUTS
.xcref		    @GPSKIP_IND, @GPSKIP_INI, @GPSKIP_INS
.xcref @GPSKIP_INT, @GPSKIP_CLI, @GPSKIP_STI
.xcref @GPSKIP_IRET,@GPSKIP_PPF, @GPSKIP_FF
@GPSKIP_HLT   equ mask $GPSKIP_HLT  ; Skip HLT instructions
@GPSKIP_OUTD  equ mask $GPSKIP_OUTD ; ...  OUT DX,A? ...
@GPSKIP_OUTI  equ mask $GPSKIP_OUTI ; ...  OUT immed,A? ...
@GPSKIP_OUTS  equ mask $GPSKIP_OUTS ; ...  OUTS ...
@GPSKIP_CRn   equ mask $GPSKIP_CRn  ; ...  MOV E??,CRn/MOV CRn,E??
@GPSKIP_IND   equ mask $GPSKIP_IND  ; ...  IN  DX,A? ...
@GPSKIP_INI   equ mask $GPSKIP_INI  ; ...  IN  immed,A? ...
@GPSKIP_INS   equ mask $GPSKIP_INS  ; ...  INS ...
@GPSKIP_INT   equ mask $GPSKIP_INT  ; ...  INT xx ...
@GPSKIP_CLI   equ mask $GPSKIP_CLI  ; ...  CLI
@GPSKIP_STI   equ mask $GPSKIP_STI  ; ...  STI
@GPSKIP_IRET  equ mask $GPSKIP_IRET ; ...  IRET
@GPSKIP_PPF   equ mask $GPSKIP_PPF  ; ...  PUSHF/POPF
@GPSKIP_FF    equ mask $GPSKIP_FF   ; ...  FF

