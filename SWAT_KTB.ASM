;' $Header:   P:/PVCS/386SWAT/SWAT_KTB.ASV   1.3   17 Jul 1997 13:06:20   BOB  $
	 title	 SWAT_KTB -- 386MAX Debugger Keyboard Tables
	 page	 58,122
	 name	 SWAT_KTB

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.

|
.386p
.xlist
	 include 8255.INC
	 include MASM.INC
	 include BIOSDATA.INC
	 include SCANCODE.INC
	 include KEYCODE.INC

	 include SWAT_SEG.INC
.list

	 public  @KEY_CTL_ESC
@KEY_CTL_ESC equ 0E01Bh

KEYMAC	 macro	 COD,ACT,TAB,TOG

KSEGCOD  segment use32 byte public 'data' ; Start KSEGCOD segment
	 assume  ds:DGROUP

	 db	 COD

KSEGCOD  ends			; End KSEGCOD segment


KSEGACT  segment use32 dword public 'data' ; Start KSEGACT segment
	 assume  ds:DGROUP

	 dd	 offset PGROUP:KEY_INT09_&ACT

KSEGACT  ends			; End KSEGACT segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 extrn	 KEY_INT09_&ACT:near

PROG	 ends			; End PROG segment


ifnb <TOG>
	 TABMAC  <TAB>,TOG
else
KSEGTOG  segment use32 byte public 'data' ; Start KSEGTOG segment
	 assume  ds:DGROUP

	 db	 0		; Ensure toggle flag is zero

KSEGTOG  ends			; End KSEGTOG segment
endif				; IFNB <TOG>

	 endm			; KEYMAC


TABMAC	 macro	 BUFCOD,TOG

KSEGTAB  segment use32 word public 'data' ; Start KSEGTAB segment
	 assume  ds:DGROUP

	 dw	 BUFCOD

KSEGTAB  ends			; End KSEGTAB segment


KSEGTOG  segment use32 byte public 'data' ; Start KSEGTOG segment
	 assume  ds:DGROUP

ifidn <TOG>,<CAPL>
	 db	 mask $KB_CAPL
elseifidn <TOG>,<NUML>
	 db	 mask $KB_NUML
else
	 db	 TOG
				; IFIDN <TOG>,<NUML>
endif				; IFIDN <TOG>,<CAPL>

KSEGTOG  ends			; End KSEGTOG segment

	 endm			; TABMAC


KSEGCOD  segment use32 byte public 'data' ; Start KSEGCOD segment
	 assume  ds:DGROUP

	 public  KEYSP_COD
KEYSP_COD label  byte

KSEGCOD  ends			; End KSEGCOD segment


KSEGACT  segment use32 dword public 'data' ; Start KSEGACT segment
	 assume  ds:DGROUP

	 public  KEYSP_ACT
KEYSP_ACT label  dword

KSEGACT  ends			; End KSEGACT segment


KEYMAC	 @K2S_RESEND	, RESEND	; Resend
KEYMAC	 @K2S_ACK	, ACK		; Acknowledge
KEYMAC	 @K2S_OVER1	, OVER		; Key overrun
KEYMAC	 @SSC_E0	, E0		; General marker
KEYMAC	 @SSC_E1	, E1		; General marker


KSEGCOD  segment use32 byte public 'data' ; Start KSEGCOD segment
	 assume  ds:DGROUP

	 public  KEYSP_CODLEN
KEYSP_CODLEN equ $-KEYSP_COD	; # entries in table

KSEGCOD  ends			; End KSEGCOD segment


KSEGCOD  segment use32 byte public 'data' ; Start KSEGCOD segment
	 assume  ds:DGROUP

	 public  KEYE0_COD
KEYE0_COD label  byte

KSEGCOD  ends			; End KSEGCOD segment


KSEGACT  segment use32 dword public 'data' ; Start KSEGACT segment
	 assume  ds:DGROUP

	 public  KEYE0_ACT
KEYE0_ACT label  dword

KSEGACT  ends			; End KSEGACT segment


KSEGTAB  segment use32 word public 'data' ; Start KSEGTAB segment
	 assume  ds:DGROUP

	 public  KEYE0_TAB
KEYE0_TAB label  word

KSEGTAB  ends			; End KSEGTAB segment


;				Unshift Shift Control	R-Alt	L-Alt Toggle
KEYMAC	 @SSC_INS     , XINS0, < 52E0h, 52E0h,	92E0h, 0A200h, 0A200h>, 0  ; 82 52 X-Ins
KEYMAC	 @SSC_DEL     , XDEL,  < 53E0h, 53E0h,	93E0h, 0A300h, 0A300h>, 0  ; 83 53 X-Del
KEYMAC	 @SSC_LEFT    , E0COM, < 4BE0h, 4BE0h,	73E0h,	9B00h,	9B00h>, 0  ; 75 4B X-Left
KEYMAC	 @SSC_HOME    , E0COM, < 47E0h, 47E0h,	77E0h,	9700h,	9700h>, 0  ; 71 47 X-Home
KEYMAC	 @SSC_END     , E0COM, < 4FE0h, 4FE0h,	75E0h,	9F00h,	9F00h>, 0  ; 79 4F X-End
KEYMAC	 @SSC_UP      , E0COM, < 48E0h, 48E0h,	8DE0h,	9800h,	9800h>, 0  ; 72 48 X-Up
KEYMAC	 @SSC_DN      , E0COM, < 50E0h, 50E0h,	91E0h, 0A000h, 0A000h>, 0  ; 80 50 X-Down
KEYMAC	 @SSC_PGUP    , E0COM, < 49E0h, 49E0h,	84E0h,	9900h,	9900h>, 0  ; 73 49 X-Page Up
KEYMAC	 @SSC_PGDN    , E0COM, < 51E0h, 51E0h,	76E0h, 0A100h, 0A100h>, 0  ; 81 51 X-Page Down
KEYMAC	 @SSC_RIGHT   , E0COM, < 4DE0h, 4DE0h,	74E0h,	9D00h,	9D00h>, 0  ; 77 4D X-Right
KEYMAC	 @SSC_SLASH   , E0COM, <0E02Fh,0E02Fh,	9500h, 0A400h, 0A400h>, 0  ; 53 35 Padslash
KEYMAC	 @SSC_ENTER   , E0COM, <0E00Dh,0E00Dh, 0E00Ah, 0A600h, 0A600h>, 0  ; 28 1C Padenter
KEYMAC	 @SSC_PADSTAR , PRTSC						   ; Padstar
KEYMAC	 @SSC_ALT     , RALT0						   ; R-Alt Press
KEYMAC	 @SSC_ALT+80h , RALT1						   ; R-Alt Release
KEYMAC	 @SSC_CTRL    , RCTL0						   ; R-Ctl Press
KEYMAC	 @SSC_CTRL+80h, RCTL1						   ; R-Ctl Release
KEYMAC	 @SSC_LSHFT   , LSHFT0						   ; L-Shift Press
KEYMAC	 @SSC_LSHFT+80h,LSHFT1						   ; L-Shift Release
KEYMAC	 @SSC_RSHFT   , RSHFT0						   ; R-Shift Press
KEYMAC	 @SSC_RSHFT+80h,RSHFT1						   ; R-Shift Release
KEYMAC	 @SSC_INS+80h , XINS1						   ; X-Ins Release
KEYMAC	 @SSC_LWIN    , LWIN0						   ; Left Windows Press
KEYMAC	 @SSC_LWIN+80h, LWIN1						   ; ...	  Release
KEYMAC	 @SSC_RWIN    , RWIN0						   ; Right Windows Press
KEYMAC	 @SSC_RWIN+80h, RWIN1						   ; ...	   Release


KSEGCOD  segment use32 byte public 'data' ; Start KSEGCOD segment
	 assume  ds:DGROUP

	 public  KEYE0_CODLEN
KEYE0_CODLEN equ $-KEYE0_COD	; # entries in table

KSEGCOD  ends			; End KSEGCOD segment


KSEGCOD  segment use32 byte public 'data' ; Start KSEGCOD segment
	 assume  ds:DGROUP

	 public  KEYSF_COD
KEYSF_COD label  byte

KSEGCOD  ends			; End KSEGCOD segment


KSEGACT  segment use32 dword public 'data' ; Start KSEGACT segment
	 assume  ds:DGROUP

	 public  KEYSF_ACT
KEYSF_ACT label  dword

KSEGACT  ends			; End KSEGACT segment


KEYMAC	 @SSC_CAPS	, CAPL		; Caps Lock
KEYMAC	 @SSC_NUMLOCK	, NUML		; Num Lock
KEYMAC	 @SSC_SCROLL	, SCRL		; Scroll Lock
KEYMAC	 @SSC_CTRL	, LCTL0 	; Left Ctl	Press
KEYMAC	 @SSC_CTRL+80h	, LCTL1 	; Left Ctl	Release
KEYMAC	 @SSC_LSHFT	, LSHFT0	; Left Shift	Press
KEYMAC	 @SSC_LSHFT+80h , LSHFT1	; Left Shift	Release
KEYMAC	 @SSC_RSHFT	, RSHFT0	; Right Shift	Press
KEYMAC	 @SSC_RSHFT+80h , RSHFT1	; Right Shift	Release
KEYMAC	 @SSC_ALT	, LALT0 	; Left Alt	Press
KEYMAC	 @SSC_ALT+80h	, LALT1 	; Left Alt	Release
KEYMAC	 @SSC_INS	, INS0		; Insert	Press
KEYMAC	 @SSC_INS+80h	, INS1		; Insert	Release
KEYMAC	 @SSC_DEL	, DEL		; Delete
KEYMAC	 @SSC_PAD5	, PAD5		; Pad5
KEYMAC	 @SSC_PADSTAR	, PRTSC 	; Padstar


KSEGCOD  segment use32 byte public 'data' ; Start KSEGCOD segment
	 assume  ds:DGROUP

	 public  KEYSF_CODLEN
KEYSF_CODLEN equ $-KEYSF_COD	; # entries in table

KSEGCOD  ends			; End KSEGCOD segment


KSEGTAB  segment use32 word public 'data' ; Start KSEGTAB segment
	 assume  ds:DGROUP

	 public  KEY_TAB
KEY_TAB  label	 word

KSEGTAB  ends			; End KSEGTAB segment


KSEGTOG  segment use32 byte public 'data' ; Start KSEGTOG segment
	 assume  ds:DGROUP

	 public  KEY_TOG
KEY_TOG  label	 byte

KSEGTOG  ends			; End KSEGTOG segment


;      Unshift Shift Control   R-Alt   L-Alt  Toggle
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;   0  00
TABMAC <011Bh, 011Bh, 0E01Bh,  01F0h,  01F0h> , 0      ;   1  01   Esc
TABMAC <0231h, 0221h,	  -1,  7800h,  7800h> , 0      ;   2  02   1 !
TABMAC <0332h, 0340h,  0300h,  7900h,  7900h> , 0      ;   3  03   2 @
TABMAC <0433h, 0423h,	  -1,  7A00h,  7A00h> , 0      ;   4  04   3 #
TABMAC <0534h, 0524h,	  -1,  7B00h,  7B00h> , 0      ;   5  05   4 $
TABMAC <0635h, 0625h,	  -1,  7C00h,  7C00h> , 0      ;   6  06   5 %
TABMAC <0736h, 075Eh,  071Eh,  7D00h,  7D00h> , 0      ;   7  07   6 ^
TABMAC <0837h, 0826h,	  -1,  7E00h,  7E00h> , 0      ;   8  08   7 &
TABMAC <0938h, 092Ah,	  -1,  7F00h,  7F00h> , 0      ;   9  09   8 *
TABMAC <0A39h, 0A28h,	  -1,  8000h,  8000h> , 0      ;  10  0A   9 (
TABMAC <0B30h, 0B29h,	  -1,  8100h,  8100h> , 0      ;  11  0B   0 )
TABMAC <0C2Dh, 0C5Fh,  0C1Fh,  8200h,  8200h> , 0      ;  12  0C   - _
TABMAC <0D3Dh, 0D2Bh,	  -1,  8300h,  8300h> , 0      ;  13  0D   = +
TABMAC <0E08h, 0E08h,  0E7Fh,  0EF0h,  0EF0h> , 0      ;  14  0E   BS
TABMAC <0F09h, 0F00h,  9400h, 0A500h, 0A500h> , 0      ;  15  0F   TAB
TABMAC <1071h, 1051h,  1011h,  1000h,  1000h> , CAPL   ;  16  10   q Q
TABMAC <1177h, 1157h,  1117h,  1100h,  1100h> , CAPL   ;  17  11   w W
TABMAC <1265h, 1245h,  1205h,  1200h,  1200h> , CAPL   ;  18  12   e E
TABMAC <1372h, 1352h,  1312h,  1300h,  1300h> , CAPL   ;  19  13   r R
TABMAC <1474h, 1454h,  1414h,  1400h,  1400h> , CAPL   ;  20  14   t T
TABMAC <1579h, 1559h,  1519h,  1500h,  1500h> , CAPL   ;  21  15   y Y
TABMAC <1675h, 1655h,  1615h,  1600h,  1600h> , CAPL   ;  22  16   u U
TABMAC <1769h, 1749h,  1709h,  1700h,  1700h> , CAPL   ;  23  17   i I
TABMAC <186Fh, 184Fh,  180Fh,  1800h,  1800h> , CAPL   ;  24  18   o O
TABMAC <1970h, 1950h,  1910h,  1900h,  1900h> , CAPL   ;  25  19   p P
TABMAC <1A5Bh, 1A7Bh,  1A1Bh,  1AF0h,  1AF0h> , 0      ;  26  1A   [ {
TABMAC <1B5Dh, 1B7Dh,  1B1Dh,  1BF0h,  1BF0h> , 0      ;  27  1B   ] }
TABMAC <1C0Dh, 1C0Dh,  1C0Ah,  1CF0h,  1CF0h> , 0      ;  28  1C   CR
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  29  1D   Ctl
TABMAC <1E61h, 1E41h,  1E01h,  1E00h,  1E00h> , CAPL   ;  30  1E   a A
TABMAC <1F73h, 1F53h,  1F13h,  1F00h,  1F00h> , CAPL   ;  31  1F   s S
TABMAC <2064h, 2044h,  2004h,  2000h,  2000h> , CAPL   ;  32  20   d D
TABMAC <2166h, 2146h,  2106h,  2100h,  2100h> , CAPL   ;  33  21   f F
TABMAC <2267h, 2247h,  2207h,  2200h,  2200h> , CAPL   ;  34  22   g G
TABMAC <2368h, 2348h,  2308h,  2300h,  2300h> , CAPL   ;  35  23   h H
TABMAC <246Ah, 244Ah,  240Ah,  2400h,  2400h> , CAPL   ;  36  24   j J
TABMAC <256Bh, 254Bh,  250Bh,  2500h,  2500h> , CAPL   ;  37  25   k K
TABMAC <266Ch, 264Ch,  260Ch,  2600h,  2600h> , CAPL   ;  38  26   l L
TABMAC <273Bh, 273Ah,	  -1,  27F0h,  27F0h> , 0      ;  39  27   ; :
TABMAC <2827h, 2822h,	  -1,  28F0h,  28F0h> , 0      ;  40  28   ' "
TABMAC <2960h, 297Eh,	  -1,  29F0h,  29F0h> , 0      ;  41  29   ` ~
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  42  2A   Left Shift
TABMAC <2B5Ch, 2B7Ch,  2B1Ch,  2BF0h,  2BF0h> , 0      ;  43  2B   \ |
TABMAC <2C7Ah, 2C5Ah,  2C1Ah,  2C00h,  2C00h> , CAPL   ;  44  2C   z Z
TABMAC <2D78h, 2D58h,  2D18h,  2D00h,  2D00h> , CAPL   ;  45  2D   x X
TABMAC <2E63h, 2E43h,  2E03h,  2E00h,  2E00h> , CAPL   ;  46  2E   c C
TABMAC <2F76h, 2F56h,  2F16h,  2F00h,  2F00h> , CAPL   ;  47  2F   v V
TABMAC <3062h, 3042h,  3002h,  3000h,  3000h> , CAPL   ;  48  30   b B
TABMAC <316Eh, 314Eh,  310Eh,  3100h,  3100h> , CAPL   ;  49  31   n N
TABMAC <326Dh, 324Dh,  320Dh,  3200h,  3200h> , CAPL   ;  50  32   m M
TABMAC <332Ch, 333Ch,	  -1,  33F0h,  33F0h> , 0      ;  51  33   , <
TABMAC <342Eh, 343Eh,	  -1,  34F0h,  34F0h> , 0      ;  52  34   . >
TABMAC <352Fh, 353Fh,	  -1,  35F0h,  35F0h> , 0      ;  53  35   / ?
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  54  36   Right Shift
TABMAC <372Ah, 372Ah,  9600h,  37F0h,  37F0h> , 0      ;  55  37   Padstar
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  56  38   Alt
TABMAC <3920h, 3920h,  3920h,  3920h,  3920h> , 0      ;  57  39   Blank
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  58  3A   Caps Lock
TABMAC <3B00h, 5400h,  5E00h,  6800h,  6800h> , 0      ;  59  3B   F1
TABMAC <3C00h, 5500h,  5F00h,  6900h,  6900h> , 0      ;  60  3C   F2
TABMAC <3D00h, 5600h,  6000h,  6A00h,  6A00h> , 0      ;  61  3D   F3
TABMAC <3E00h, 5700h,  6100h,  6B00h,  6B00h> , 0      ;  62  3E   F4
TABMAC <3F00h, 5800h,  6200h,  6C00h,  6C00h> , 0      ;  63  3F   F5
TABMAC <4000h, 5900h,  6300h,  6D00h,  6D00h> , 0      ;  64  40   F6
TABMAC <4100h, 5A00h,  6400h,  6E00h,  6E00h> , 0      ;  65  41   F7
TABMAC <4200h, 5B00h,  6500h,  6F00h,  6F00h> , 0      ;  66  42   F8
TABMAC <4300h, 5C00h,  6600h,  7000h,  7000h> , 0      ;  67  43   F9
TABMAC <4400h, 5D00h,  6700h,  7100h,  7100h> , 0      ;  68  44   F10
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  69  45   Num Lock
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  70  46   Scroll Lock
TABMAC <4700h, 4737h,  7700h,	  -1,	  -1> , NUML   ;  71  47   Home
TABMAC <4800h, 4838h,  8D00h,	  -1,	  -1> , NUML   ;  72  48   Up
TABMAC <4900h, 4939h,  8400h,	  -1,	  -1> , NUML   ;  73  49   Page Up
TABMAC <4A2Dh, 4A2Dh,  8E00h,  4AF0h,  4AF0h> , 0      ;  74  4A   Padminus
TABMAC <4B00h, 4B34h,  7300h,	  -1,	  -1> , NUML   ;  75  4B   Left
TABMAC <4CF0h, 4C35h,  8F00h,	  -1,	  -1> , NUML   ;  76  4C   Pad5
TABMAC <4D00h, 4D36h,  7400h,	  -1,	  -1> , NUML   ;  77  4D   Right
TABMAC <4E2Bh, 4E2Bh,  9000h,  4EF0h,  4EF0h> , 0      ;  78  4E   Padplus
TABMAC <4F00h, 4F31h,  7500h,	  -1,	  -1> , NUML   ;  79  4F   End
TABMAC <5000h, 5032h,  9100h,	  -1,	  -1> , NUML   ;  80  50   Down
TABMAC <5100h, 5133h,  7600h,	  -1,	  -1> , NUML   ;  81  51   Page Down
TABMAC <5200h, 5230h,  9200h,	  -1,	  -1> , NUML   ;  82  52   Insert
TABMAC <5300h, 532Eh,  9300h,	  -1,	  -1> , NUML   ;  83  53   Delete
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  84  54   Sys Request
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  85  55   ???
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  86  56   ???
TABMAC <8500h, 8700h,  8900h,  8B00h,  8B00h> , 0      ;  87  57   F11
TABMAC <8600h, 8800h,  8A00h,  8C00h,  8C00h> , 0      ;  88  58   F12
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  89  59   ???
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  90  5A   ???
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  91  5B   LWIN
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  92  5C   RWIN
TABMAC <9A00h, 9C00h,  9E00h, 0A700h, 0A700h> , 0      ;  93  5D   AWIN


KSEGTAB  segment use32 word public 'data' ; Start KSEGTAB segment
	 assume  ds:DGROUP

	 public  @KEY_TAB_SIZ
@KEY_TAB_SIZ equ 5*(type KEY_TAB) ; # bytes in each KEY_TAB entry

	 public  KEY_TABLEN
KEY_TABLEN equ	 ($-KEY_TAB)/@KEY_TAB_SIZ ; # entries in table

KSEGTAB  ends			; End KSEGTAB segment

	 MEND			; End SWAT_KTB module
