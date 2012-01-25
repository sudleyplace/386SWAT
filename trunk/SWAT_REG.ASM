;' $Header:   P:/PVCS/386SWAT/SWAT_REG.ASV   1.17   10 Aug 1998 11:01:30   BOB  $
	 title	 SWAT_REG -- 386SWAT Register Command Functions
	 page	 58,122
	 name	 SWAT_REG

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC
	 include PTR.INC
	 include 386.INC
	 include IOPBITS.INC
	 include MOVSPR.INC
	 include BITFLAGS.INC
	 include CPUFLAGS.INC
	 include ALLMEM.INC

	 include SWAT_COM.INC
	 include SWAT_CMD.INC
	 include SWAT_SEG.INC
.list


REGMAC	 macro	 RNAM,RMAX,ROFF,RACTGET,RACTSET
	 local	 LCL_TXT,LCL_LEN

TEXT	 segment use32 byte public 'data' ; Start TEXT segment
	 assume  ds:DGROUP

LCL_TXT  db	 RNAM
LCL_LEN  equ	 $-LCL_TXT

TEXT	 ends			; End TEXT segment


SREG_LEN segment use32 dword public 'data' ; Start SREG_LEN segment
	 assume  ds:DGROUP

	 dd	 LCL_LEN

SREG_LEN ends			; End SREG_LEN segment


SREG_TAB segment use32 dword public 'data' ; Start SREG_TAB segment
	 assume  ds:DGROUP

	 dd	 offset DGROUP:LCL_TXT

SREG_TAB ends			; End SREG_TAB segment


SREG_MAX segment use32 dword public 'data' ; Start SREG_MAX segment
	 assume  ds:DGROUP

	 dd	 RMAX

SREG_MAX ends			; End SREG_MAX segment


SREG_OFF segment use32 word public 'data' ; Start SREG_OFF segment
	 assume  ds:DGROUP

	 dw	 ROFF

SREG_OFF ends			; End SREG_OFF segment


SREG_ACTGET segment use32 dword public 'data' ; Start SREG_ACTGET segment
	 assume  ds:DGROUP

	 dd	 offset PGROUP:&RACTGET

SREG_ACTGET ends		; End SREG_ACTGET segment


SREG_ACTSET segment use32 dword public 'data' ; Start SREG_ACTSET segment
	 assume  ds:DGROUP

	 dd	 offset PGROUP:&RACTSET

SREG_ACTSET ends		; End SREG_ACTSET segment

	 endm			; REGMAC


SREG_LEN segment use32 dword public 'data' ; Start SREG_LEN segment
	 assume  ds:DGROUP

	public	@SWAT_REG_SREG_LEN@REG
@SWAT_REG_SREG_LEN@REG label byte ; Mark module start in .MAP file

	 public  REG_LEN
REG_LEN  label	 dword

SREG_LEN ends			; End SREG_LEN segment


SREG_TAB segment use32 dword public 'data' ; Start SREG_TAB segment
	 assume  ds:DGROUP

	public	@SWAT_REG_SREG_TAB@REG
@SWAT_REG_SREG_TAB@REG label byte ; Mark module start in .MAP file

	 public  REG_TAB
REG_TAB  label	 dword

SREG_TAB ends			; End SREG_TAB segment


SREG_MAX segment use32 dword public 'data' ; Start SREG_MAX segment
	 assume  ds:DGROUP

	public	@SWAT_REG_SREG_MAX@REG
@SWAT_REG_SREG_MAX@REG label byte ; Mark module start in .MAP file

	 public  REG_MAX
REG_MAX  label	 dword

SREG_MAX ends			; End SREG_MAX segment


SREG_OFF segment use32 word public 'data' ; Start SREG_OFF segment
	 assume  ds:DGROUP

	public	@SWAT_REG_SREG_OFF@REG
@SWAT_REG_SREG_OFF@REG label byte ; Mark module start in .MAP file

	 public  REG_OFF
REG_OFF  label	 word

SREG_OFF ends			; End SREG_OFF segment


SREG_ACTGET segment use32 dword public 'data' ; Start SREG_ACTGET segment
	 assume  ds:DGROUP

	public	@SWAT_REG_SREG_ACTGET@REG
@SWAT_REG_SREG_ACTGET@REG label byte ; Mark module start in .MAP file

	 public  REG_ACTGET
REG_ACTGET label dword

SREG_ACTGET ends		; End SREG_ACTGET segment


SREG_ACTSET segment use32 dword public 'data' ; Start SREG_ACTSET segment
	 assume  ds:DGROUP

	public	@SWAT_REG_SREG_ACTSET@REG
@SWAT_REG_SREG_ACTSET@REG label byte ; Mark module start in .MAP file

	 public  REG_ACTSET
REG_ACTSET label dword

SREG_ACTSET ends		; End SREG_ACTSET segment


; All keywords in this table *MUST* be in lowercase

REGMAC	 'eax', 0FFFFFFFFh, FORW_EAX               , GETREG_32 , SETREG_32
REGMAC	  'ax', 00000FFFFh, FORW_EAX.ELO           , GETREG_16 , SETREG_16
REGMAC	  'al', 0000000FFh, FORW_EAX.ELO.LO        , GETREG_8  , SETREG_8
REGMAC	  'ah', 0000000FFh, FORW_EAX.ELO.HI        , GETREG_8  , SETREG_8
REGMAC	 'ebx', 0FFFFFFFFh, FORW_EBX               , GETREG_32 , SETREG_32
REGMAC	  'bx', 00000FFFFh, FORW_EBX.ELO           , GETREG_16 , SETREG_16
REGMAC	  'bl', 0000000FFh, FORW_EBX.ELO.LO        , GETREG_8  , SETREG_8
REGMAC	  'bh', 0000000FFh, FORW_EBX.ELO.HI        , GETREG_8  , SETREG_8
REGMAC	 'ecx', 0FFFFFFFFh, FORW_ECX               , GETREG_32 , SETREG_32
REGMAC	  'cx', 00000FFFFh, FORW_ECX.ELO           , GETREG_16 , SETREG_16
REGMAC	  'cl', 0000000FFh, FORW_ECX.ELO.LO        , GETREG_8  , SETREG_8
REGMAC	  'ch', 0000000FFh, FORW_ECX.ELO.HI        , GETREG_8  , SETREG_8
REGMAC	 'edx', 0FFFFFFFFh, FORW_EDX               , GETREG_32 , SETREG_32
REGMAC	  'dx', 00000FFFFh, FORW_EDX.ELO           , GETREG_16 , SETREG_16
REGMAC	  'dl', 0000000FFh, FORW_EDX.ELO.LO        , GETREG_8  , SETREG_8
REGMAC	  'dh', 0000000FFh, FORW_EDX.ELO.HI        , GETREG_8  , SETREG_8
REGMAC	 'esi', 0FFFFFFFFh, FORW_ESI               , GETREG_32 , SETREG_32
REGMAC	  'si', 00000FFFFh, FORW_ESI.ELO           , GETREG_16 , SETREG_16
REGMAC	 'edi', 0FFFFFFFFh, FORW_EDI               , GETREG_32 , SETREG_32
REGMAC	  'di', 00000FFFFh, FORW_EDI.ELO           , GETREG_16 , SETREG_16
REGMAC	 'ebp', 0FFFFFFFFh, FORW_EBP               , GETREG_32 , SETREG_32
REGMAC	  'bp', 00000FFFFh, FORW_EBP.ELO           , GETREG_16 , SETREG_16
REGMAC	 'esp', 0FFFFFFFFh, FORW_ESP               , GETREG_32 , SETREG_32
REGMAC	  'sp', 00000FFFFh, FORW_ESP.ELO           , GETREG_16 , SETREG_16
REGMAC	 'eip', 0FFFFFFFFh, FORW_EIP               , GETREG_32 , SETREG_32
REGMAC	  'ip', 00000FFFFh, FORW_EIP.ELO           , GETREG_16 , SETREG_16
REGMAC	 'efl', 0FFFFFFFFh, FORW_EFL               , GETREG_32 , SETREG_32
REGMAC	  'fl', 00000FFFFh, FORW_EFL.ELO           , GETREG_16 , SETREG_16

REGMAC	'csip', 00000FFFFh, BACK_CS.DTR_LIM-@BPBACK, GETREG_CSIP,SETREG_CSIP
REGMAC 'cseip', 0FFFFFFFFh, BACK_CS.DTR_LIM-@BPBACK, GETREG_CSEIP,SETREG_CSEIP

REGMAC	  'tr', 00000FFFFh, BACK_TR.DTR_LIM-@BPBACK, GETREG_TR,  SETREG_TR
REGMAC	 'ldt', 00000FFFFh, BACK_LDT.DTR_LIM-@BPBACK,GETREG_LDTR,SETREG_LDTR
REGMAC	'ldtr', 00000FFFFh, BACK_LDT.DTR_LIM-@BPBACK,GETREG_LDTR,SETREG_LDTR

REGMAC	  'cs', 00000FFFFh, BACK_CS.DTR_LIM-@BPBACK, GETREG_SEG, SETREG_SEG
REGMAC	  'ds', 00000FFFFh, BACK_DS.DTR_LIM-@BPBACK, GETREG_SEG, SETREG_SEG
REGMAC	  'es', 00000FFFFh, BACK_ES.DTR_LIM-@BPBACK, GETREG_SEG, SETREG_SEG
REGMAC	  'fs', 00000FFFFh, BACK_FS.DTR_LIM-@BPBACK, GETREG_SEG, SETREG_SEG
REGMAC	  'gs', 00000FFFFh, BACK_GS.DTR_LIM-@BPBACK, GETREG_SEG, SETREG_SEG
REGMAC	  'ss', 00000FFFFh, BACK_SS.DTR_LIM-@BPBACK, GETREG_SEG, SETREG_SEG

REGMAC	 'cr0', 0FFFFFFFFh, 0                      , GETREG_CR0, SETREG_CR0
REGMAC	 'cr1', 0FFFFFFFFh, 0                      , GETREG_CR1, SETREG_CR1
REGMAC	 'cr2', 0FFFFFFFFh, 0                      , GETREG_CR2, SETREG_CR2
REGMAC	 'cr3', 0FFFFFFFFh, 0                      , GETREG_CR3, SETREG_CR3
REGMAC	 'cr4', 0FFFFFFFFh, 0                      , GETREG_CR4, SETREG_CR4
REGMAC	 'cr5', 0FFFFFFFFh, 0                      , GETREG_CR5, SETREG_CR5
REGMAC	 'cr6', 0FFFFFFFFh, 0                      , GETREG_CR6, SETREG_CR6
REGMAC	 'cr7', 0FFFFFFFFh, 0                      , GETREG_CR7, SETREG_CR7

REGMAC	 'dr0', 0FFFFFFFFh, 0                      , GETREG_DR0, SETREG_DR0
REGMAC	 'dr1', 0FFFFFFFFh, 0                      , GETREG_DR1, SETREG_DR1
REGMAC	 'dr2', 0FFFFFFFFh, 0                      , GETREG_DR2, SETREG_DR2
REGMAC	 'dr3', 0FFFFFFFFh, 0                      , GETREG_DR3, SETREG_DR3
REGMAC	 'dr4', 0FFFFFFFFh, 0                      , GETREG_DR4, SETREG_DR4
REGMAC	 'dr5', 0FFFFFFFFh, 0                      , GETREG_DR5, SETREG_DR5
REGMAC	 'dr6', 0FFFFFFFFh, 0                      , GETREG_DR6, SETREG_DR6
REGMAC	 'dr7', 0FFFFFFFFh, 0                      , GETREG_DR7, SETREG_DR7

REGMAC	 'tr0', 0FFFFFFFFh, 0                      , GETREG_TR0, SETREG_TR0
REGMAC	 'tr1', 0FFFFFFFFh, 0                      , GETREG_TR1, SETREG_TR1
REGMAC	 'tr2', 0FFFFFFFFh, 0                      , GETREG_TR2, SETREG_TR2
REGMAC	 'tr3', 0FFFFFFFFh, 0                      , GETREG_TR3, SETREG_TR3
REGMAC	 'tr4', 0FFFFFFFFh, 0                      , GETREG_TR4, SETREG_TR4
REGMAC	 'tr5', 0FFFFFFFFh, 0                      , GETREG_TR5, SETREG_TR5
REGMAC	 'tr6', 0FFFFFFFFh, 0                      , GETREG_TR6, SETREG_TR6
REGMAC	 'tr7', 0FFFFFFFFh, 0                      , GETREG_TR7, SETREG_TR7


SREG_TAB segment use32 dword public 'data' ; Start SREG_TAB segment
	 assume  ds:DGROUP

	 public  REG_NTAB
REG_NTAB equ	 ($-REG_TAB)/(type REG_TAB) ; # register names

SREG_TAB ends			; End SREG_TAB segment



STRMAC	 macro	 RNAM,RMAX
	 local	 LCL_TXT,LCL_LEN

TEXT	 segment use32 byte public 'data' ; Start TEXT segment
	 assume  ds:DGROUP

LCL_TXT  db	 RNAM
LCL_LEN  equ	 $-LCL_TXT

TEXT	 ends			; End TEXT segment


SREG_LEN segment use32 dword public 'data' ; Start SREG_LEN segment
	 assume  ds:DGROUP

	 dd	 LCL_LEN

SREG_LEN ends			; End SREG_LEN segment


SREG_TAB segment use32 dword public 'data' ; Start SREG_TAB segment
	 assume  ds:DGROUP

	 dd	 offset DGROUP:LCL_TXT

SREG_TAB ends			; End SREG_TAB segment


SREG_MAX segment use32 dword public 'data' ; Start SREG_MAX segment
	 assume  ds:DGROUP

	 dd	 RMAX

SREG_MAX ends			; End SREG_MAX segment

	 endm			; STRMAC


SREG_LEN segment use32 dword public 'data' ; Start SREG_LEN segment
	 assume  ds:DGROUP

	public	@SWAT_REG_SREG_LEN@STR
@SWAT_REG_SREG_LEN@STR label byte ; Mark module start in .MAP file

	 public  STR_LEN
STR_LEN  label	 dword

SREG_LEN ends			; End SREG_LEN segment


SREG_TAB segment use32 dword public 'data' ; Start SREG_TAB segment
	 assume  ds:DGROUP

	public	@SWAT_REG_SREG_TAB@STR
@SWAT_REG_SREG_TAB@STR label byte ; Mark module start in .MAP file

	 public  STR_TAB
STR_TAB  label	 dword

SREG_TAB ends			; End SREG_TAB segment


SREG_MAX segment use32 dword public 'data' ; Start SREG_MAX segment
	 assume  ds:DGROUP

	public	@SWAT_REG_SREG_MAX@STR
@SWAT_REG_SREG_MAX@STR label byte ; Mark module start in .MAP file

	 public  STR_MSK
STR_MSK  label	 dword

SREG_MAX ends			; End SREG_MAX segment


; All keywords in this table *MUST* be in lowercase
; The masks in this table *MUST* all contain contiguous 1-bits

; CR0 masks

	 STRMAC  'pg',          <mask $PG>
	 STRMAC  'cd',          <mask $CD>
	 STRMAC  'nw',          <mask $NW>
	 STRMAC  'am',          <mask $AM>
	 STRMAC  'wp',          <mask $WP>
	 STRMAC  'ne',          <mask $NE>
	 STRMAC  'et',          <mask $ET>
	 STRMAC  'ts',          <mask $TS>
	 STRMAC  'em',          <mask $EM>
	 STRMAC  'mp',          <mask $MP>
	 STRMAC  'pe',          <mask $PE>

; CR4 masks

	 STRMAC  'mce',         <mask $MCE>
	 STRMAC  'pae',         <mask $PAE>
	 STRMAC  'pse',         <mask $PSE>
	 STRMAC  'de',          <mask $DE>
	 STRMAC  'tsd',         <mask $TSD>
	 STRMAC  'pvi',         <mask $PVI>
	 STRMAC  'vme',         <mask $VME>

; EFL masks

	 STRMAC  'id',          <mask $ID>
	 STRMAC  'vip',         <mask $VIP>
	 STRMAC  'vif',         <mask $VIF>
	 STRMAC  'ac',          <mask $ACHI>
	 STRMAC  'vm',          <mask $VMHI>
	 STRMAC  'rf',          <mask $RFHI>
	 STRMAC  'nt',          <mask $NT>
	 STRMAC  'iopl',        <mask $IOPL>
	 STRMAC  'of',          <mask $OF>
	 STRMAC  'df',          <mask $DF>
	 STRMAC  'if',          <mask $IF>
	 STRMAC  'tf',          <mask $TF>
	 STRMAC  'sf',          <mask $SF>
	 STRMAC  'zf',          <mask $ZF>
	 STRMAC  'af',          <mask $AF>
	 STRMAC  'pf',          <mask $PF>
	 STRMAC  'cf',          <mask $CF>

; Selector masks

	 STRMAC  'sel',         <mask $SEL>
	 STRMAC  'ti',          <mask $TI>
	 STRMAC  'pl',          <mask $PL>

; DR6 masks

	 STRMAC  'bt',          <mask $BT>
	 STRMAC  'bs',          <mask $BS>
	 STRMAC  'bd',          <mask $BD>
	 STRMAC  'b3',          <mask $B3>
	 STRMAC  'b2',          <mask $B2>
	 STRMAC  'b1',          <mask $B1>
	 STRMAC  'b0',          <mask $B0>

; DR7 masks

	 STRMAC  'len3',        <mask $LEN3>
	 STRMAC  'rw3',         <mask $RW3>
	 STRMAC  'len2',        <mask $LEN2>
	 STRMAC  'rw2',         <mask $RW2>
	 STRMAC  'len1',        <mask $LEN1>
	 STRMAC  'rw1',         <mask $RW1>
	 STRMAC  'len0',        <mask $LEN0>
	 STRMAC  'rw0',         <mask $RW0>
	 STRMAC  'gd',          <mask $GD>
	 STRMAC  'ge',          <mask $GE>
	 STRMAC  'le',          <mask $LE>
	 STRMAC  'g3',          <mask $G3>
	 STRMAC  'l3',          <mask $L3>
	 STRMAC  'g2',          <mask $G2>
	 STRMAC  'l2',          <mask $L2>
	 STRMAC  'g1',          <mask $G1>
	 STRMAC  'l1',          <mask $L1>
	 STRMAC  'g0',          <mask $G0>
	 STRMAC  'l0',          <mask $L0>

; TR4 masks

	 STRMAC  'tr4_tag'      <mask $TR4_TAG>
	 STRMAC  'tr4_wval'     <mask $TR4_WVAL>
	 STRMAC  'tr4_lru'      <mask $TR4_LRU>
	 STRMAC  'tr4_rval'     <mask $TR4_RVAL>

; TR5 masks

	 STRMAC  'tr5_ssel'     <mask $TR5_SSEL>
	 STRMAC  'tr5_esel'     <mask $TR5_ESEL>
	 STRMAC  'tr5_ctl'      <mask $TR5_CTL>

; TR6 masks

	 STRMAC  'tr6_v',       <mask $TR6_V>
	 STRMAC  'tr6_d',       <mask $TR6_D>
	 STRMAC  'tr6_dp',      <mask $TR6_DP>
	 STRMAC  'tr6_u',       <mask $TR6_U>
	 STRMAC  'tr6_up',      <mask $TR6_UP>
	 STRMAC  'tr6_w',       <mask $TR6_W>
	 STRMAC  'tr6_wp',      <mask $TR6_WP>
	 STRMAC  'tr6_c',       <mask $TR6_C>

	 STRMAC  'tr7_ht',      <mask $TR7_HT>
	 STRMAC  'tr7_rep',     <mask $TR7_REP>

; PTE masks

	 STRMAC  'frm',         <(mask $PTE_FRMHI) or (mask $PTE_FRM)>
	 STRMAC  'pte_avl',     <(mask $PTE_AV2) or (mask $PTE_AV1) or (mask $PTE_AV0)>
	 STRMAC  'pte_ps',      <mask $PTE_PS>
	 STRMAC  'pte_d',       <mask $PTE_D>
	 STRMAC  'pte_a',       <mask $PTE_A>
	 STRMAC  'pte_cd',      <mask $PTE_CD>
	 STRMAC  'pte_wt',      <mask $PTE_WT>
	 STRMAC  'pte_us',      <mask $PTE_US>
	 STRMAC  'pte_rw',      <mask $PTE_RW>
	 STRMAC  'pte_p',       <mask $PTE_P>

; Arbitrary bit flags

	 STRMAC  'bit0',        @BIT00
	 STRMAC  'bit1',        @BIT01
	 STRMAC  'bit2',        @BIT02
	 STRMAC  'bit3',        @BIT03
	 STRMAC  'bit4',        @BIT04
	 STRMAC  'bit5',        @BIT05
	 STRMAC  'bit6',        @BIT06
	 STRMAC  'bit7',        @BIT07
	 STRMAC  'bit8',        @BIT08
	 STRMAC  'bit9',        @BIT09

	 STRMAC  'bit00',       @BIT00
	 STRMAC  'bit01',       @BIT01
	 STRMAC  'bit02',       @BIT02
	 STRMAC  'bit03',       @BIT03
	 STRMAC  'bit04',       @BIT04
	 STRMAC  'bit05',       @BIT05
	 STRMAC  'bit06',       @BIT06
	 STRMAC  'bit07',       @BIT07
	 STRMAC  'bit08',       @BIT08
	 STRMAC  'bit09',       @BIT09
	 STRMAC  'bit10',       @BIT10
	 STRMAC  'bit11',       @BIT11
	 STRMAC  'bit12',       @BIT12
	 STRMAC  'bit13',       @BIT13
	 STRMAC  'bit14',       @BIT14
	 STRMAC  'bit15',       @BIT15
	 STRMAC  'bit16',       @BIT16
	 STRMAC  'bit17',       @BIT17
	 STRMAC  'bit18',       @BIT18
	 STRMAC  'bit19',       @BIT19
	 STRMAC  'bit20',       @BIT20
	 STRMAC  'bit21',       @BIT21
	 STRMAC  'bit22',       @BIT22
	 STRMAC  'bit23',       @BIT23
	 STRMAC  'bit24',       @BIT24
	 STRMAC  'bit25',       @BIT25
	 STRMAC  'bit26',       @BIT26
	 STRMAC  'bit27',       @BIT27
	 STRMAC  'bit28',       @BIT28
	 STRMAC  'bit29',       @BIT29
	 STRMAC  'bit30',       @BIT30
	 STRMAC  'bit31',       @BIT31


SREG_TAB segment use32 dword public 'data' ; Start SREG_TAB segment
	 assume  ds:DGROUP

STR_NTAB equ	 ($-STR_TAB)/(type STR_TAB) ; # structure names

SREG_TAB ends			; End SREG_TAB segment


DATA16	 segment use32 dword public 'data' ; Start DATA16 segment
	 assume  ds:DGROUP

	public	@SWAT_REG_DATA16
@SWAT_REG_DATA16 label byte	; Mark module start in .MAP file

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	 public  REGINT06_FVEC,REGINT0D_FVEC
REGINT06_FVEC label fword	; Save area for INT 06h handler
	 dd	 offset PGROUP:REG_INT06,?
	 align	 4
REGINT0D_FVEC label fword	; ...		    0Dh handler
	 dd	 offset PGROUP:REG_INT0D,?

DATA16	 ends			; End DATA16 segment


DATA	 segment use32 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	public	@SWAT_REG_DATA
@SWAT_REG_DATA label byte	; Mark module start in .MAP file

	 extrn	 DSP_STATE:byte
	 extrn	 DSP_STAT2:byte

	 extrn	 MSGOFF:dword
	 extrn	 SYNTERR:byte
	 extrn	 OVFERR:byte
	 extrn	 VALERR:byte
	 extrn	 REGERR:byte
	 extrn	 STRERR:byte
	 extrn	 RSERR:byte
	 extrn	 RRERR:byte

	 extrn	 UNASEL:word

	 extrn	 CMD_TOKN:byte
	 extrn	 SAVE_DR7:dword
	 extrn	 FORCE_DR7:dword
	extrn	TSS_CNT:dword

	 public  OLDREGINT06_FVEC,OLDREGINT06_ARB
OLDREGINT06_FVEC df ?		; Save area for old INT 06h handler
OLDREGINT06_ARB db  ?		; ...			06h access rights byte
OLDREGINT0D_ARB db  ?		; ..			0Dh access rights byte

	 public  OLDREGINT0D_FVEC,OLDREGINT0D_ARB
OLDREGINT0D_FVEC df ?		; ...			0Dh handler

	 public  REGINT06_ARB,REGINT0D_ARB
REGINT06_ARB db  CPL0_INTR3 or CPL3 ; ...	    06h access rights byte
REGINT0D_ARB db  CPL0_INTR3 or CPL3 ; ...	    0Dh access rights byte

	 public  RS_EAX,RS_EBX,RS_ECX,RS_EDX
	 public  RS_ESI,RS_EDI,RS_EBP,RS_ESP,RS_EIP,RS_EFL
	 public  RS_DS,RS_ES,RS_FS,RS_GS,RS_SS
	 align	 4
RS_EAX	 dd	 ?		; RS/RR save area for EAX
RS_EBX	 dd	 ?		; ...		      EBX
RS_ECX	 dd	 ?		; ...		      ECX
RS_EDX	 dd	 ?		; ...		      EDX
RS_ESI	 dd	 ?		; ...		      ESI
RS_EDI	 dd	 ?		; ...		      EDI
RS_EBP	 dd	 ?		; ...		      EBP
RS_ESP	 dd	 ?		; ...		      ESP
RS_EIP	 dd	 ?		; ...		      EIP
RS_EFL	 dd	 ?		; ...		      EFL
RS_DS	 dw	 ?		; ...		      DS
RS_ES	 dw	 ?		; ...		      ES
RS_FS	 dw	 ?		; ...		      FS
RS_GS	 dw	 ?		; ...		      GS
RS_SS	 dw	 ?		; ...		      SS

DATA	 ends			; End DATA segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	public	@SWAT_REG_PROG
@SWAT_REG_PROG: 		; Mark module start in .MAP file

	 extrn	 IZITEOL:near
	 extrn	 CMD_WHITE:near
	 extrn	 PARSE_EXPR:near
	 extrn	 PARSE_ADDR:near
	 extrn	 GETBASE:near
	 extrn	 SEL2GDT:near
	 extrn	 SET_CURINSTR:near
	 extrn	 GET_TOKN:near

	 NPPROC  CMD_REG -- Register Change Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Register change command

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 pushad 		; Save all EGP registers

; Process register name

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	 call	 GET_TOKN	; Get next token into CMD_TOKN

	 cmp	 CMD_TOKN,0	; Izit end-of-the-line?
	 je	 near ptr CMD_REG_SYNTERR ; Yes, so that's a syntax error

	 xor	 ebx,ebx	; Zero index register
	 mov	 ecx,REG_NTAB	; # arguments to check
CMD_REG_NEXT:
	 mov	 edi,REG_TAB[ebx*(type REG_TAB)] ; Get location of text

	 REGSAVE <ecx,esi>	; Save for a moment
	 mov	 ecx,REG_LEN[ebx*(type REG_LEN)] ; Get length
	 lea	 esi,CMD_TOKN	; DS:ESI ==> token
    repe cmps	 ds:[esi].LO,es:[edi].LO ; Compare 'em
	 REGREST <esi,ecx>	; Restore
	 jne	 short CMD_REG_NEXT1 ; Not this one

; Mark as found only if the next character is a valid separator

	 mov	 edi,REG_LEN[ebx*(type REG_LEN)] ; Get length of matching command
	 add	 edi,esi	; Add into starting offset
	 mov	 al,ds:[edi]	; Get the next character

	 cmp	 al,' '         ; Check for valid separator
	 je	 short CMD_REG_FOUND ; Jump if valid

	 cmp	 al,'='         ; Check for valid separator
	 je	 short CMD_REG_FOUND ; Jump if valid

	 cmp	 al,'.'         ; Check for valid separator
	 je	 short CMD_REG_FOUND ; Jump if valid
CMD_REG_NEXT1:
	 inc	 ebx		; Skip to next entry

	 loop	 CMD_REG_NEXT	; Jump if more entries to check

; Register not found

	 jmp	 CMD_REG_REGERR ; Jump if unknown

CMD_REG_FOUND:
	 add	 esi,REG_LEN[ebx*(type REG_LEN)] ; Skip over the keyword

; Check for structure operand

	 cmp	 al,'.'         ; Izit a structure separator?
	 jne	 short CMD_REG_XSTR ; Jump if not

; Process structure operand

	 inc	 esi		; Skip over it

	 call	 GET_TOKN	; Get next token into CMD_TOKN

	 cmp	 CMD_TOKN,0	; Izit end-of-the-line?
	 je	 near ptr CMD_REG_SYNTERR ; Yes, so that's a syntax error

	 xor	 edx,edx	; Zero index register
	 mov	 ecx,STR_NTAB	; # arguments to check
CMD_REG_NEXTSTR:
	 mov	 edi,STR_TAB[edx*(type STR_TAB)] ; Get location of text

	 REGSAVE <ecx,esi>	; Save for a moment
	 mov	 ecx,STR_LEN[edx*(type STR_LEN)] ; Get length
	 lea	 esi,CMD_TOKN	; DS:ESI ==> token
    repe cmps	 ds:[esi].LO,es:[edi].LO ; Compare 'em
	 REGREST <esi,ecx>	; Restore
	 jne	 short CMD_REG_NEXTSTR1 ; Not this one

; Mark as found only if the next character is a valid separator

	 mov	 edi,STR_LEN[edx*(type STR_LEN)] ; Get length of matching command
	 add	 edi,esi	; Add into starting offset
	 mov	 al,ds:[edi]	; Get the next character

	 cmp	 al,' '         ; Check for valid separator
	 je	 short CMD_REG_STRFOUND ; Jump if valid

	 cmp	 al,'='         ; Check for valid separator
	 je	 short CMD_REG_STRFOUND ; Jump if valid
CMD_REG_NEXTSTR1:
	 inc	 edx		; Skip to next entry

	 loop	 CMD_REG_NEXTSTR ; Jump if more entries to check

; Structure not found

CMD_REG_STRERR0:
	 jmp	 CMD_REG_STRERR ; Jump if unknown

CMD_REG_STRFOUND:
	 add	 esi,STR_LEN[edx*(type STR_LEN)] ; Skip over the keyword
	 mov	 edx,STR_MSK[edx*(type STR_MSK)] ; Get the data mask

	 cmp	 edx,REG_MAX[ebx*(type REG_MAX)] ; Check against maximum allowed value
	 ja	 short CMD_REG_STRERR0 ; Jump if out of range

	 jmp	 short CMD_REG_XSTR1 ; Join common code


; Process next character as either a blank or an equal sign

CMD_REG_XSTR:
	 mov	 edx,REG_MAX[ebx*(type REG_MAX)] ; Get maximum allowed value
CMD_REG_XSTR1:
	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,'='         ; Izit an optional separator?
	 jne	 short @F	; Jump if not

	 inc	 esi		; Skip over it

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
@@:

; Process following argument

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 near ptr CMD_REG_SYNTERR ; Yes, so that's an error

; If this is the special registers CSIP or CSEIP, parse for an address
; instead of an expression.

	 cmp	 REG_ACTSET[ebx*(type REG_ACTSET)],offset PGROUP:SETREG_CSIP
	 je	 short @F	; Jump if so

	 cmp	 REG_ACTSET[ebx*(type REG_ACTSET)],offset PGROUP:SETREG_CSEIP
	 jne	 short CMD_REG_EXPR ; Jump if not
@@:
	 REGSAVE <ebx,edx>	; Save for a moment

	 call	 PARSE_ADDR	; Parse DS:ESI for address
	 mov	 di,bx		; Save segment/selector
	 REGREST <edx,ebx>	; Restore
	 jc	 near ptr CMD_REG_ERR ; Jump if error
				; DI  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags

	 test	 cx,@ADDR_SEP	; Separator specified?
	 jz	 near ptr CMD_REG_ERR ; Jump if not

	 jmp	 short CMD_REG_COM ; Join common exit code

; Convert the hex number at DS:ESI to binary

CMD_REG_EXPR:
	 call	 PARSE_EXPR	; Parse command line for an expression
	 jc	 near ptr CMD_REG_OVFERR ; Jump if too large
CMD_REG_COM:
	 call	 IZITEOL	; Izit end-of-the-line?
	 jne	 near ptr CMD_REG_SYNTERR ; No, so that's an error

; Check against maximum allowed value

	 bsf	 ecx,edx	; ECX = index of low-order 1-bit
	 shr	 edx,cl 	; Shift all 1-bits down

	 cmp	 eax,edx	; Check against maximum allowed value
	 ja	 near ptr CMD_REG_OVFERR ; Jump if too large

	 shl	 edx,cl 	; Shift back to mask value
	 not	 edx		; Complement to clear bits
	 shl	 eax,cl 	; Shift into position

; Change register values

	 movsx	 ecx,REG_OFF[ebx*(type REG_OFF)] ; Get appropriate offset

COMMENT|

Register usage:

EBX	 =	 register index
ECX	 =	 signed offset from EBP to register location in FORW_STR
EDX	 =	 mask value for bits to change (AND on set)
EAX	 =	 incoming value
DI	 =	 segment/selector (if CSIP or CSEIP)

|

	 call	 REG_ACTSET[ebx*(type REG_ACTSET)] ; Take appropriate action
	 jc	 near ptr CMD_REG_ERR ; Join common error code

; If the current screen shows instruction disassembly,
; redisplay the disassembly screen.

	 cmp	 DSP_STATE,@DSP_IREGS ; Izit instruction state?
	 je	 short @F	; Jump if so

	 cmp	 DSP_STAT2,@DSP_IREGS ; Izit secondary ... ?
	 jne	 short CMD_REG_CLC ; Jump if not
@@:
	 or	 LCL_FLAG,@LCL_REDI ; Mark as forced re-display of screen
CMD_REG_CLC:

; We need the following call only for changes to CS:eIP

	 call	 SET_CURINSTR	; Set current instruction disassembly values

	 clc			; Indicate all went well

	 jmp	 CMD_REG_EXIT	; Join common exit code

GETREG_CSIP:
GETREG_CSEIP:
	 stc			; Indicate we don't support this

	 ret			; Return to caller


SETREG_CSIP:
	 mov	 [ebp].FORW_EIP.ELO,ax ; Save new IP

	 jmp	 short SETREG_CSEIP_COM ; Join common code

SETREG_CSEIP:
	 mov	 [ebp].FORW_EIP,eax ; Save new EIP
SETREG_CSEIP_COM:
	 mov	 [ebp-@BPBACK].BACK_CS.DTR_LIM,di ; Save new CS

	 call	 SET_SEGBASE	; Set segment register bases

	 clc			; Indicate all went well

	 ret			; Return to caller


GETREG_8:
	 movzx	 eax,[ebp+ecx].ELO.LO ; Get 8-bit value

	 clc			; Indicate all went well

	 ret			; Return to caller


SETREG_8:
	 and	 [ebp+ecx],dl	; Clear the bits
	 or	 [ebp+ecx],al	; Save as new 8-bit value

	 clc			; Indicate all went well

	 ret			; Return to caller


GETREG_16:
	 movzx	 eax,[ebp+ecx].ELO ; Get 16-bit value

	 clc			; Indicate all went well

	 ret			; Return to caller


SETREG_16:
	 and	 [ebp+ecx],dx	; Clear the bits
	 or	 [ebp+ecx],ax	; Save as new 16-bit value

	 clc			; Indicate all went well

	 ret			; Return to caller


GETREG_SEG:
	 movzx	 eax,[ebp+ecx].ELO ; Get 16-bit value

	 clc			; Indicate all went well

	 ret			; Return to caller


SETREG_SEG:
	 and	 [ebp+ecx],dx	; Clear the bits
	 or	 [ebp+ecx],ax	; Save as new 16-bit value

	 call	 SET_SEGBASE	; Set segment register bases

	 clc			; Indicate all went well

	 ret			; Return to caller


GETREG_32:
	 mov	 eax,[ebp+ecx]	; Get 32-bit value

	 clc			; Indicate all went well

	 ret			; Return to caller


SETREG_32:
	 and	 [ebp+ecx],edx	; Clear the bits
	 or	 [ebp+ecx],eax	; Save as new 32-bit value

	 clc			; Indicate all went well

	 ret			; Return to caller


GETREG_TR:
	 movzx	 eax,[ebp-@BPBACK].BACK_TR.DTR_LIM ; Get the TR

	 clc			; Indicate all went well

	 ret			; Return to caller


SETREG_TR:
	 and	 eax,not (mask $PL) ; Clear the PL bits
	 jz	 short SETREG_TR_ERR ; Jump if so

	 test	 eax,mask $TI	; Izit an LDT selector?
	 jnz	 short SETREG_TR_ERR ; Jump if so

	 mov	 ebx,eax	; Copy as input to SEL2GDT
	 call	 SEL2GDT	; Convert selector in EBX to GDT address in EBX
				; Note that because this selector can't be in
				; the LDT, we don't require DS=AGROUP for
				; this call.
	 mov	 cl,AGROUP:[ebx].DESC_ACCESS ; Get the A/R byte
	 and	 cl,not ((mask $DT_DPL) or (mask $DS_BUSY)) ; Clear the DPL and busy bits
	 or	 cl,(mask $DT_P) or (mask $DS_386) ; Mark as present and 386

	 cmp	 cl,CPL0_IDLE3	; Izit a 386 TSS?
	 jne	 short SETREG_TR_ERR ; Jump if not

	 mov	 [ebp-@BPBACK].BACK_TR.DTR_LIM,ax ; Set the TR
	 mov	 cx,ax		; Save for later use

	 push	 ax		; Pass the selector
	 call	 GETBASE	; Return with EAX = selector base
	 jc	 short SETREG_TR_ERR ; Jump if in error

	 mov	 [ebp-@BPBACK].BACK_TR.DTR_BASE,eax ; Save the base

	cmp	TSS_CNT,0	; Izit TSS mode?
	je	short @F	; Jump if not

	 str	 ax		; Get current task register

; Get back link from our own TSS

	 push	 ax		; Pass selector as argument
	 call	 GETBASE	; Return with EAX = selector base
	 jc	 short @F	; Jump if invalid

	 mov	 AGROUP:[eax].TSS_LINK,cx ; Save as back link
	 or	 AGROUP:[ebx].DESC_ACCESS,mask $DS_BUSY ; Set the busy bit
@@:
	 clc			; Indicate all went well

	 jmp	 short SETREG_TR_EXIT ; Join common exit code

SETREG_TR_ERR:
	 mov	 MSGOFF,offset DGROUP:VALERR ; Save offset of error message

	 stc			; Mark as in error
SETREG_TR_EXIT:
	 ret			; Return to caller


GETREG_LDTR:
	 movzx	 eax,[ebp-@BPBACK].BACK_LDT.DTR_LIM ; Get the LDTR

	 clc			; Indicate all went well

	 ret			; Return to caller


SETREG_LDTR:
	 and	 eax,not (mask $PL) ; Clear the PL bits
	 jz	 short SETREG_LDTR_ERR ; Jump if so

	 test	 eax,mask $TI	; Izit an LDT selector?
	 jnz	 short SETREG_LDTR_ERR ; Jump if so

	 mov	 ebx,eax	; Copy as input to SEL2GDT
	 call	 SEL2GDT	; Convert selector in EBX to GDT address in EBX
				; Note that because this selector can't be in
				; the LDT, we don't require DS=AGROUP for
				; this call.
	 mov	 bl,AGROUP:[ebx].DESC_ACCESS ; Get the A/R byte
	 and	 bl,not (mask $DT_DPL) ; Clear the DPL bits
	 or	 bl,mask $DT_P	; Mark as present

	 cmp	 bl,CPL0_LDT	; Izit an LDT?
	 jne	 short SETREG_LDTR_ERR ; Jump if not

	 mov	 [ebp-@BPBACK].BACK_LDT.DTR_LIM,ax ; Set the LDTR

	 push	 ax		; Pass the selector
	 call	 GETBASE	; Return with EAX = selector base
	 jc	 short SETREG_LDTR_ERR ; Jump if in error

	 mov	 [ebp-@BPBACK].BACK_LDT.DTR_BASE,eax ; Save the base

	 clc			; Indicate all went well

	 jmp	 short SETREG_LDTR_EXIT ; Join common exit code

SETREG_LDTR_ERR:
	 mov	 MSGOFF,offset DGROUP:VALERR ; Save offset of error message

	 stc			; Mark as in error
SETREG_LDTR_EXIT:
	 ret			; Return to caller

GETREG_CR0:
	 mov	 eax,cr0	; Get current value

	 clc			; Indicate all went well

	 ret			; Return to caller


SETREG_CR0:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 mov	 ecx,cr0	; Get current value

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value
	 or	 eax,(mask $PG) or (mask $PE) ; Ensure still paging and protecting

	 clc			; Assume no error
	 mov	 cr0,eax	; Change the register
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

; If we're to Disable the Write-through and this CPU supports WBINVD,
; also disable the cache(s) via WBINVD.

	 test	 LC2_FLAG,@LC2_486 ; Izit a 486 or later?
	 jz	 short @F	; Jump if not

	 test	 eax,mask $NW	; Izit set?
	 jz	 short @F	; Jump if not

	 WBINVD 		; Write-back and invalidate the external cache
@@:
	 jmp	 CMD_REG_RESTRET ; Join common OK code


GETREG_CR1:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  eax,cr1	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 CMD_REG_RESTRET ; Join common OK code


SETREG_CR1:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  ecx,cr1	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 clc			; Assume no error
	 MOVSPR  cr1,eax	; Change the register
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 CMD_REG_RESTRET ; Join common OK code


GETREG_CR2:
	 mov	 eax,cr2	; Get current value

	 clc			; Indicate all went well

	 ret			; Return to caller


SETREG_CR2:
	 mov	 ecx,cr2	; Get current value

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 mov	 cr2,eax	; Change the register

	 clc			; Indicate all went well

	 ret			; Return to caller


GETREG_CR3:
	 mov	 eax,cr3	; Get current value

	 clc			; Indicate all went well

	 ret			; Return to caller


SETREG_CR3:
	 mov	 ecx,cr3	; Get current value

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 mov	 cr3,eax	; Change the register

	 clc			; Indicate all went well

	 ret			; Return to caller


GETREG_CR4:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  eax,cr4	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 CMD_REG_RESTRET ; Join common OK code


SETREG_CR4:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  ecx,cr4	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 clc			; Assume no error
	 MOVSPR  cr4,eax	; Change the register
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 CMD_REG_RESTRET ; Join common OK code


GETREG_CR5:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  eax,cr5	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 CMD_REG_RESTRET ; Join common OK code


SETREG_CR5:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  ecx,cr5	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 clc			; Assume no error
	 MOVSPR  cr5,eax	; Change the register
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 CMD_REG_RESTRET ; Join common OK code


GETREG_CR6:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  eax,cr6	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 CMD_REG_RESTRET ; Join common OK code


SETREG_CR6:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  ecx,cr6	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 clc			; Assume no error
	 MOVSPR  cr6,eax	; Change the register
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 CMD_REG_RESTRET ; Join common OK code


GETREG_CR7:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  eax,cr7	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 CMD_REG_RESTRET ; Join common OK code


SETREG_CR7:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  ecx,cr7	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 clc			; Assume no error
	 MOVSPR  cr7,eax	; Change the register
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 CMD_REG_RESTRET ; Join common OK code


GETREG_DR0:
	 mov	 eax,dr0	; Get current value

	 clc			; Indicate all went well

	 ret			; Return to caller


SETREG_DR0:
	 mov	 ecx,dr0	; Get current value

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 mov	 dr0,eax	; Change the register

	 clc			; Indicate all went well

	 ret			; Return to caller


GETREG_DR1:
	 mov	 eax,dr1	; Get current value

	 clc			; Indicate all went well

	 ret			; Return to caller


SETREG_DR1:
	 mov	 ecx,dr1	; Get current value

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 mov	 dr1,eax	; Change the register

	 clc			; Indicate all went well

	 ret			; Return to caller


GETREG_DR2:
	 mov	 eax,dr2	; Get current value

	 clc			; Indicate all went well

	 ret			; Return to caller


SETREG_DR2:
	 mov	 ecx,dr2	; Get current value

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 mov	 dr2,eax	; Change the register

	 clc			; Indicate all went well

	 ret			; Return to caller


GETREG_DR3:
	 mov	 eax,dr3	; Get current value

	 clc			; Indicate all went well

	 ret			; Return to caller


SETREG_DR3:
	 mov	 ecx,dr3	; Get current value

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 mov	 dr3,eax	; Change the register

	 clc			; Indicate all went well

	 ret			; Return to caller


GETREG_DR4:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  eax,dr4	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 CMD_REG_RESTRET ; Join common OK code


SETREG_DR4:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  ecx,dr4	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 clc			; Assume no error
	 MOVSPR  dr4,eax	; Change the register
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 CMD_REG_RESTRET ; Join common OK code


GETREG_DR5:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  eax,dr5	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 CMD_REG_RESTRET ; Join common OK code


SETREG_DR5:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  ecx,dr5	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 clc			; Assume no error
	 MOVSPR  dr5,eax	; Change the register
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 CMD_REG_RESTRET ; Join common OK code


GETREG_DR6:
	 mov	 eax,dr6	; Get current value

	 clc			; Indicate all went well

	 ret			; Return to caller


SETREG_DR6:
	 mov	 ecx,dr6	; Get current value

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 mov	 dr6,eax	; Change the register

	 clc			; Indicate all went well

	 ret			; Return to caller


GETREG_DR7:
	 mov	 eax,SAVE_DR7	; Get current value

	 clc			; Indicate all went well

	 ret			; Return to caller


SETREG_DR7:
	 mov	 ecx,SAVE_DR7	; Get current value

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 mov	 SAVE_DR7,eax	; Change the register

	 and	 eax,mask $GD	; Isolate forced bits
	 mov	 FORCE_DR7,eax	; Save for later use

	 clc			; Indicate all went well

	 ret			; Return to caller


GETREG_TR0:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  eax,tr0	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 CMD_REG_RESTRET ; Join common OK code


SETREG_TR0:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  ecx,tr0	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 clc			; Assume no error
	 MOVSPR  tr0,eax	; Change the register
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 CMD_REG_RESTRET ; Join common OK code


GETREG_TR1:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  eax,tr1	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 CMD_REG_RESTRET ; Join common OK code


SETREG_TR1:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  ecx,tr1	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 clc			; Assume no error
	 MOVSPR  tr1,eax	; Change the register
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 CMD_REG_RESTRET ; Join common OK code


GETREG_TR2:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  eax,tr2	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 CMD_REG_RESTRET ; Join common OK code


SETREG_TR2:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  ecx,tr2	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 clc			; Assume no error
	 MOVSPR  tr2,eax	; Change the register
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 short CMD_REG_RESTRET ; Join common OK code


GETREG_TR3:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  eax,tr3	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 short CMD_REG_RESTRET ; Join common OK code


SETREG_TR3:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  ecx,tr3	; Get current value
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 clc			; Assume no error
	 MOVSPR  tr3,eax	; Change the register
	 jc	 near ptr CMD_REG_RESTERR ; Join common error code

	 jmp	 short CMD_REG_RESTRET ; Join common OK code


GETREG_TR4:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  eax,tr4	; Get current value
	 jc	 short CMD_REG_RESTERR ; Join common error code

	 jmp	 short CMD_REG_RESTRET ; Join common OK code


SETREG_TR4:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  ecx,tr4	; Get current value
	 jc	 short CMD_REG_RESTERR ; Join common error code

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 clc			; Assume no error
	 MOVSPR  tr4,eax	; Change the register
	 jc	 short CMD_REG_RESTERR ; Join common error code

	 jmp	 short CMD_REG_RESTRET ; Join common OK code


GETREG_TR5:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  eax,tr5	; Get current value
	 jc	 short CMD_REG_RESTERR ; Join common error code

	 jmp	 short CMD_REG_RESTRET ; Join common OK code


SETREG_TR5:
	 call	 INST_060D	; Install INT 06h/0Dh handler

	 clc			; Assume no error
	 MOVSPR  ecx,tr5	; Get current value
	 jc	 short CMD_REG_RESTERR ; Join common error code

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 clc			; Assume no error
	 MOVSPR  tr5,eax	; Change the register
	 jc	 short CMD_REG_RESTERR ; Join common error code
CMD_REG_RESTRET:
	 call	 REST_060D	; Restore INT 06h/0Dh handler

	 clc			; Indicate all went well

	 ret			; Return to caller


CMD_REG_RESTERR:
	 call	 REST_060D	; Restore INT 06h/0Dh handler

	 stc			; Mark as in error

	 ret			; Return to caller


GETREG_TR6:
	 mov	 eax,tr6	; Get current value

	 clc			; Indicate all went well

	 ret			; Return to caller


SETREG_TR6:
	 mov	 ecx,tr6	; Get current value

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 mov	 tr6,eax	; Change the register

	 clc			; Indicate all went well

	 ret			; Return to caller


GETREG_TR7:
	 mov	 eax,tr7	; Get current value

	 clc			; Indicate all went well

	 ret			; Return to caller


SETREG_TR7:
	 mov	 ecx,tr7	; Get current value

	 and	 ecx,edx	; Clear the bits
	 or	 eax,ecx	; Include the value

	 mov	 tr7,eax	; Change the register

	 clc			; Indicate all went well

	 ret			; Return to caller


CMD_REG_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	 jmp	 short CMD_REG_ERR ; Join common error exit code

CMD_REG_OVFERR:
	 mov	 MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

	 jmp	 short CMD_REG_ERR ; Join common error exit code

CMD_REG_REGERR:
	 mov	 MSGOFF,offset DGROUP:REGERR ; Save offset of error message

	 jmp	 short CMD_REG_ERR ; Join common error exit code

CMD_REG_STRERR:
	 mov	 MSGOFF,offset DGROUP:STRERR ; Save offset of error message
;;;;;;;;
;;;;;;;; jmp	 short CMD_REG_ERR ; Join common error exit code
;;;;;;;;
CMD_REG_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Mark as in error
CMD_REG_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_REG  endp			; End CMD_REG procedure
	 NPPROC  INST_060D -- Install INT 06h/0Dh Handlers
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Install INT 06h/0Dh handlers

On entry:

SS:EBP	 ==>	 FORW_STR

|

	 REGSAVE <eax,ebx>	; Save registers

; Address the IDT

	 mov	 ebx,[ebp-@BPBACK].BACK_IDT.DTR_BASE ; Get IDTR base

	 IDTMAC  06h,06,REG,OLDREG,FORCE ; IDT to OLDREG, REG to IDT (EAX clobbered)
	 IDTMAC  0Dh,0D,REG,OLDREG,FORCE ; ...

	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST_060D endp			; End INST_060D procedure
	 NPPROC  REST_060D -- Restore INT 06h/0Dh Handlers
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Restore INT 06h/0Dh handlers

On entry:

CF	 =	 1 if error in command
SS:EBP	 ==>	 FORW_STR

|

	 pushfd 		; Save flags
	 REGSAVE <eax,ebx>	; Save registers

	 mov	 ebx,[ebp-@BPBACK].BACK_IDT.DTR_BASE ; Get IDTR base

	 IDTMAC  06h,06,OLDREG,,FORCE ; OLDREG to IDT (EAX clobbered)
	 IDTMAC  0Dh,0D,OLDREG,,FORCE ; ...

	 REGREST <ebx,eax>	; Restore
	 popfd			; Restore flags

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_060D endp			; End REST_060D procedure
	 FPPROC  REG_INT06 -- Local Register INT 06h Handler
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Local register INT 06h handler

This handler is called if the register is not valid.

|

IREG_STR struc

IREG_EIP dd	 ?		; Caller's EIP
IREG_CS  dw	 ?,?		; ...	   CS with filler
IREG_EFL dd	 ?		; ...	   EFL

IREG_STR ends

	 mov	 MSGOFF,offset DGROUP:REGERR ; Save offset of error message

	 jmp	 short REG_INTCOM ; Join common register interrupt code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REG_INT06 endp			; End REG_INT06 procedure
	 FPPROC  REG_INT0D -- Local Register INT 0Dh Handler
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Local register INT 0Dh handler

This handler is called if the value to be placed into the register is not valid.

|

	 mov	 MSGOFF,offset DGROUP:VALERR ; Save offset of error message
	 add	 esp,4		; Strip off the error code
REG_INTCOM:
	 add	 [esp].IREG_EIP,3 ; Skip over instruction
	 or	 [esp].IREG_EFL.ELO,mask $CF ; Set carry flag

	 iretd			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REG_INT0D endp			; End REG_INT0D procedure
	 NPPROC  SET_SEGBASE -- Set Segment Register Bases
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set segment register bases

|

	 REGSAVE <eax>		; Save register

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	 jz	 short SET_SEGBASE1 ; Not this time

; Save VM 8086 Mode segment registers from FORW_STR

	 movzx	 eax,[ebp-@BPBACK].BACK_CS.DTR_LIM
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 [ebp-@BPBACK].BACK_CS.DTR_BASE,eax

	 movzx	 eax,[ebp-@BPBACK].BACK_DS.DTR_LIM
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 [ebp-@BPBACK].BACK_DS.DTR_BASE,eax

	 movzx	 eax,[ebp-@BPBACK].BACK_ES.DTR_LIM
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 [ebp-@BPBACK].BACK_ES.DTR_BASE,eax

	 movzx	 eax,[ebp-@BPBACK].BACK_FS.DTR_LIM
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 [ebp-@BPBACK].BACK_FS.DTR_BASE,eax

	 movzx	 eax,[ebp-@BPBACK].BACK_GS.DTR_LIM
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 [ebp-@BPBACK].BACK_GS.DTR_BASE,eax

	 movzx	 eax,[ebp-@BPBACK].BACK_SS.DTR_LIM
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 [ebp-@BPBACK].BACK_SS.DTR_BASE,eax

	 jmp	 short SET_SEGBASE_EXIT ; Join common exit code

; Save protected mode selectors and their 32-bit linear base addresses

SET_SEGBASE1:
	 push	 [ebp-@BPBACK].BACK_CS.DTR_LIM ; Pass selector
	 call	 GETBASE	; Return with EAX = selector base
;;;;;;;; jc	 ???		; Ignore error return
	 mov	 [ebp-@BPBACK].BACK_CS.DTR_BASE,eax

	 push	 [ebp-@BPBACK].BACK_DS.DTR_LIM ; Pass selector
	 call	 GETBASE	; Return with EAX = selector base
;;;;;;;; jc	 ???		; Ignore error return
	 mov	 [ebp-@BPBACK].BACK_DS.DTR_BASE,eax

	 push	 [ebp-@BPBACK].BACK_ES.DTR_LIM ; Pass selector
	 call	 GETBASE	; Return with EAX = selector base
;;;;;;;; jc	 ???		; Ignore error return
	 mov	 [ebp-@BPBACK].BACK_ES.DTR_BASE,eax

	 push	 [ebp-@BPBACK].BACK_FS.DTR_LIM ; Pass selector
	 call	 GETBASE	; Return with EAX = selector base
;;;;;;;; jc	 ???		; Ignore error return
	 mov	 [ebp-@BPBACK].BACK_FS.DTR_BASE,eax

	 push	 [ebp-@BPBACK].BACK_GS.DTR_LIM ; Pass selector
	 call	 GETBASE	; Return with EAX = selector base
;;;;;;;; jc	 ???		; Ignore error return
	 mov	 [ebp-@BPBACK].BACK_GS.DTR_BASE,eax

	 push	 [ebp-@BPBACK].BACK_SS.DTR_LIM ; Pass selector
	 call	 GETBASE	; Return with EAX = selector base
;;;;;;;; jc	 ???		; Ignore error return
	 mov	 [ebp-@BPBACK].BACK_SS.DTR_BASE,eax
SET_SEGBASE_EXIT:

; Keep FORW_xS up-to-date

	 mov	 ax,[ebp-@BPBACK].BACK_CS.DTR_LIM ; Get segment/selector
	 mov	 [ebp].FORW_CS,ax
	 mov	 UNASEL,ax	; Save for display purposes

	 mov	 ax,[ebp-@BPBACK].BACK_DS.DTR_LIM ; Get segment/selector
	 mov	 [ebp].FORW_DS,ax

	 mov	 ax,[ebp-@BPBACK].BACK_ES.DTR_LIM ; Get segment/selector
	 mov	 [ebp].FORW_ES,ax

	 mov	 ax,[ebp-@BPBACK].BACK_FS.DTR_LIM ; Get segment/selector
	 mov	 [ebp].FORW_FS,ax

	 mov	 ax,[ebp-@BPBACK].BACK_GS.DTR_LIM ; Get segment/selector
	 mov	 [ebp].FORW_GS,ax

	 mov	 ax,[ebp-@BPBACK].BACK_SS.DTR_LIM ; Get segment/selector
	 mov	 [ebp].FORW_SS,ax

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_SEGBASE endp		; End SET_SEGBASE procedure
	NPPROC	CMD_REGCLEAR -- Register Clear Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Register clear command

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax>		; Save register

; Ensure nothing more on the line

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	jne	near ptr CMD_REGCLEAR_SYNTERR ; No, so that's a syntax error

	and	LC2_FLAG,not @LC2_RS ; Clear the flag

	clc			; Indicate all went well

	jmp	short CMD_REGCLEAR_EXIT ; Join common exit code

CMD_REGCLEAR_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_REGCLEAR_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_REGCLEAR endp		; End CMD_REGCLEAR procedure
	 NPPROC  CMD_REGSAVE -- Register Save Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Register save command

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax>		; Save register

; Ensure nothing more on the line

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 jne	 near ptr CMD_REGSAVE_SYNTERR ; No, so that's a syntax error

	 test	 LC2_FLAG,@LC2_RS ; Izit in use already?
	 jnz	 near ptr CMD_REGSAVE_RSERR ; Yes, so that's an error

	 or	 LC2_FLAG,@LC2_RS ; Mark as saved

	 mov	 eax,[ebp].FORW_EAX ; Get caller's EAX
	 mov	 RS_EAX,eax
	 mov	 eax,[ebp].FORW_EBX ; ...	   EBX
	 mov	 RS_EBX,eax
	 mov	 eax,[ebp].FORW_ECX ; ...	   ECX
	 mov	 RS_ECX,eax
	 mov	 eax,[ebp].FORW_EDX ; ...	   EDX
	 mov	 RS_EDX,eax
	 mov	 eax,[ebp].FORW_ESI ; ...	   ESI
	 mov	 RS_ESI,eax
	 mov	 eax,[ebp].FORW_EDI ; ...	   EDI
	 mov	 RS_EDI,eax
	 mov	 eax,[ebp].FORW_EBP ; ...	   EBP
	 mov	 RS_EBP,eax
	 mov	 eax,[ebp].FORW_ESP ; ...	   ESP
	 mov	 RS_ESP,eax
	 mov	 eax,[ebp].FORW_EIP ; ...	   EIP
	 mov	 RS_EIP,eax
	 mov	 eax,[ebp].FORW_EFL ; ...	   EFL
	 mov	 RS_EFL,eax
	 mov	 ax,[ebp].FORW_DS   ; ...	   DS
	 mov	 RS_DS,ax
	 mov	 ax,[ebp].FORW_ES   ; ...	   ES
	 mov	 RS_ES,ax
	 mov	 ax,[ebp].FORW_FS   ; ...	   FS
	 mov	 RS_FS,ax
	 mov	 ax,[ebp].FORW_GS   ; ...	   GS
	 mov	 RS_GS,ax
	 mov	 ax,[ebp].FORW_SS   ; ...	   SS
	 mov	 RS_SS,ax

	 mov	 DSP_STATE,@DSP_IREGS ; Mark as instruction state
	 mov	 DSP_STAT2,@DSP_IREGS ; Secondary ...
	 or	 LCL_FLAG,@LCL_REDI ; Mark as forced re-display of screen

; We need the following call only for changes to eIP

	 call	 SET_CURINSTR	; Set current instruction disassembly values

	 clc			; Indicate all went well

	 jmp	 short CMD_REGSAVE_EXIT ; Join common exit code

CMD_REGSAVE_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	 jmp	 short CMD_REGSAVE_ERR ; Join common error exit code

CMD_REGSAVE_RSERR:
	 mov	 MSGOFF,offset DGROUP:RSERR ; Save offset of error message

;;;;;;;; jmp	 short CMD_REGSAVE_ERR ; Join common error exit code

CMD_REGSAVE_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Mark as in error
CMD_REGSAVE_EXIT:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_REGSAVE endp		; End CMD_REGSAVE procedure
	 NPPROC  CMD_REGREST -- Register restotr Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Register restore command

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax>		; Save register

; Ensure nothing more on the line

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 jne	 near ptr CMD_REGREST_SYNTERR ; No, so that's a syntax error

	 test	 LC2_FLAG,@LC2_RS ; Izit in use?
	 jz	 near ptr CMD_REGREST_RRERR ; No, so that's an error

	 and	 LC2_FLAG,not @LC2_RS ; Mark as not saved

	 mov	 eax,RS_EAX	; Get previous EAX
	 mov	 [ebp].FORW_EAX,eax
	 mov	 eax,RS_EBX	; ...	       EBX
	 mov	 [ebp].FORW_EBX,eax
	 mov	 eax,RS_ECX	; ...	       ECX
	 mov	 [ebp].FORW_ECX,eax
	 mov	 eax,RS_EDX	; ...	       EDX
	 mov	 [ebp].FORW_EDX,eax
	 mov	 eax,RS_ESI	; ...	       ESI
	 mov	 [ebp].FORW_ESI,eax
	 mov	 eax,RS_EDI	; ...	       EDI
	 mov	 [ebp].FORW_EDI,eax
	 mov	 eax,RS_EBP	; ...	       EBP
	 mov	 [ebp].FORW_EBP,eax
	 mov	 eax,RS_ESP	; ...	       ESP
	 mov	 [ebp].FORW_ESP,eax
	 mov	 eax,RS_EIP	; ...	       EIP
	 mov	 [ebp].FORW_EIP,eax
	 mov	 eax,RS_EFL	; ...	       EFL
	 mov	 [ebp].FORW_EFL,eax
	 mov	 ax,RS_DS	; ...	       DS
	 mov	 [ebp].FORW_DS,ax
	 mov	 ax,RS_ES	; ...	       ES
	 mov	 [ebp].FORW_ES,ax
	 mov	 ax,RS_FS	; ...	       FS
	 mov	 [ebp].FORW_FS,ax
	 mov	 ax,RS_GS	; ...	       GS
	 mov	 [ebp].FORW_GS,ax
	 mov	 ax,RS_SS	; ...	       SS
	 mov	 [ebp].FORW_SS,ax

	 mov	 DSP_STATE,@DSP_IREGS ; Mark as instruction state
	 mov	 DSP_STAT2,@DSP_IREGS ; Secondary ...
	 or	 LCL_FLAG,@LCL_REDI ; Mark as forced re-display of screen

; We need the following call only for changes to eIP

	 call	 SET_CURINSTR	; Set current instruction disassembly values

	 clc			; Indicate all went well

	 jmp	 short CMD_REGREST_EXIT ; Join common exit code

CMD_REGREST_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	 jmp	 short CMD_REGREST_ERR ; Join common error exit code

CMD_REGREST_RRERR:
	 mov	 MSGOFF,offset DGROUP:RRERR ; Save offset of error message

;;;;;;;; jmp	 short CMD_REGREST_ERR ; Join common error exit code

CMD_REGREST_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Mark as in error
CMD_REGREST_EXIT:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_REGREST endp		; End CMD_REGREST procedure

PROG	 ends			; End PROG segment

	 MEND			; End SWAT_REG module
