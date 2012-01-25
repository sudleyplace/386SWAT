;' $Header:   P:/PVCS/386SWAT/POP87.INV   1.3   20 Sep 1994 16:48:06   BOB  $
;
; (C) Copyright 1987-94 Qualitas, Inc.	All rights reserved.
;
; POP87.INC
;
; 8087 State structure and records
;

FSTR	 struc			; Field structure

F_TYPE	 db	 ?		; 0=display only, 1=binary input, 2=hex input
F_ROW	 db	 ?		; Row offset from upper left corner of SCRN
F_COL	 db	 ?		; Col offset from upper left corner of SCRN
F_LFT	 db	 ?		; Next field to the left
F_RHT	 db	 ?		; Next field to the right
F_UP	 db	 ?		; Next field above
F_DN	 db	 ?		; Next field below
F_TAB	 db	 ?		; Next tab field
F_STAB	 db	 ?		; Prev tab field
F_PDSP	 dd	 ?		; Ptr to display function
F_PVAL	 dd	 ?		; Ptr to value
F_MSK	 dw	 ?		; Mask on value
F_SHFT	 db	 ?		; Shift amount for mask
F_PREL	 dd	 ?		; Ptr to related fields (terminated by -1)

FSTR	 ends

; Records for 8087 state

CTL	 record  $RSV0:3,$INF:1,$RND0:1,$RND1:1,$PRC0:1,$PRC1:1,$IEM:1,\
		 $RSV1:1,$XMPRC:1,$XMUNF:1,$XMOVF:1,$XMZDV:1,$XMDOP:1,$XMIOP:1
@CW	 record  $@RSV0:3,$@IC:1,$@RC:2,$@PC:2,$@RSV1:8
SWD	 record  $BUSY:1,$C3:1,$ST0:1,$ST1:1,$ST2:1,$C2:1,$C1:1,$C0:1,$IR:1, \
		 $RSV2:1,$XFPRC:1,$XFUNF:1,$XFOVF:1,$XFZDV:1,$XFDOP:1,$XFIOP:1
@SW	 record  $@RSV2:2,$TOP:3,@RSV2:11
TWD	 record  $T7:2,$T6:2,$T5:2,$T4:2,$T3:2,$T2:2,$T1:2,$T0:2
OPC_WD	 record  $OPCODE:11
NIB	 record  $NB0:4,$NB1:4,$NB2:4,$NB3:4

