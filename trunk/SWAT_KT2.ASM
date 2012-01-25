;' $Header:   P:/PVCS/386SWAT/SWAT_KT2.ASV   1.2   17 Jul 1997 13:06:20   BOB  $
	 title	 SWAT_KT2 -- International Keyboard Tables
	 page	 58,122
	 name	 SWAT_KT2

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC
	 include BIOSDATA.INC
	 include KEYCODE.INC

	 include SWAT_SEG.INC
.list

TABMAC	 macro	 BUFCOD,TOG

ASEGTAB  segment use16 word public 'ndata' ; Start ASEGTAB segment
	 assume  ds:NGROUP

	 dw	 BUFCOD

ASEGTAB  ends			; End ASEGTAB segment


ASEGTOG  segment use16 byte public 'ndata' ; Start ASEGTOG segment
	 assume  ds:NGROUP

ifidn <TOG>,<CAPL>
	 db	 mask $KB_CAPL
elseifidn <TOG>,<NUML>
	 db	 mask $KB_NUML
else
	 db	 TOG
				; IFIDN <TOG>,<NUML>
endif				; IFIDN <TOG>,<CAPL>

ASEGTOG  ends			; End ASEGTOG segment

	 endm			; TABMAC


ASEGTAB  segment use16 word public 'ndata' ; Start ASEGTAB segment
	 assume  ds:NGROUP

	 public  KEY_TAB_GR129
KEY_TAB_GR129 label word

ASEGTAB  ends			; End ASEGTAB segment


ASEGTOG  segment use16 byte public 'ndata' ; Start ASEGTOG segment
	 assume  ds:NGROUP

	 public  KEY_TOG_GR129
KEY_TOG_GR129 label byte

ASEGTOG  ends			; End ASEGTOG segment


;      Unshift Shift Control   R-Alt   L-Alt  Toggle
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;   0  00
TABMAC <011Bh, 011Bh, 0E01Bh,  01F0h,  01F0h> , 0      ;   1  01   Esc
TABMAC <0231h, 0221h,	  -1,  7800h,  7800h> , 0      ;   2  02   1 !
TABMAC <0332h, 0322h,  0300h,  03FDh,  7900h> , 0      ;   3  03   2 "   ˝
TABMAC <0433h, 0415h,	  -1,  03FCh,  7A00h> , 0      ;   4  04   3 	 ¸
TABMAC <0534h, 0524h,	  -1,  7B00h,  7B00h> , 0      ;   5  05   4 $
TABMAC <0635h, 0625h,	  -1,  7C00h,  7C00h> , 0      ;   6  06   5 %
TABMAC <0736h, 0726h,  071Eh,  7D00h,  7D00h> , 0      ;   7  07   6 ^
TABMAC <0837h, 082Fh,	  -1,  087Bh,  7E00h> , 0      ;   8  08   7 /	 {
TABMAC <0938h, 0928h,	  -1,  095Bh,  7F00h> , 0      ;   9  09   8 (	 [
TABMAC <0A39h, 0A29h,	  -1,  0A5Dh,  8000h> , 0      ;  10  0A   9 )	 ]
TABMAC <0B30h, 0B3Dh,	  -1,  0B7Dh,  8100h> , 0      ;  11  0B   0 =	 }
TABMAC <0CE1h, 0C3Fh,  0C1Fh,  0C5Ch,  8200h> , 0      ;  12  0C   · ?	 \
TABMAC <0D27h, 0D60h,	  -1,  8300h,  8300h> , 0      ;  13  0D   ' `
TABMAC <0E08h, 0E08h,  0E7Fh,  0EF0h,  0EF0h> , 0      ;  14  0E   BS
TABMAC <0F09h, 0F00h,  9400h, 0A500h, 0A500h> , 0      ;  15  0F   TAB
TABMAC <1071h, 1051h,  1011h,  1040h,  1000h> , CAPL   ;  16  10   q Q	 @
TABMAC <1177h, 1157h,  1117h,  1100h,  1100h> , CAPL   ;  17  11   w W
TABMAC <1265h, 1245h,  1205h,  1200h,  1200h> , CAPL   ;  18  12   e E
TABMAC <1372h, 1352h,  1312h,  1300h,  1300h> , CAPL   ;  19  13   r R
TABMAC <1474h, 1454h,  1414h,  1400h,  1400h> , CAPL   ;  20  14   t T
TABMAC <157Ah, 155Ah,  151Ah,  1500h,  1500h> , CAPL   ;  21  15   z Z
TABMAC <1675h, 1655h,  1615h,  1600h,  1600h> , CAPL   ;  22  16   u U
TABMAC <1769h, 1749h,  1709h,  1700h,  1700h> , CAPL   ;  23  17   i I
TABMAC <186Fh, 184Fh,  180Fh,  1800h,  1800h> , CAPL   ;  24  18   o O
TABMAC <1970h, 1950h,  1910h,  1900h,  1900h> , CAPL   ;  25  19   p P
TABMAC <1A81h, 1A9Ah,  1A1Bh,  1AF0h,  1AF0h> , 0      ;  26  1A   Å ö
TABMAC <1B2Bh, 1B2Ah,  1B1Dh,  1B7Eh,  1BF0h> , 0      ;  27  1B   + *	 ~
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
TABMAC <2794h, 2799h,	  -1,  27F0h,  27F0h> , 0      ;  39  27   î ô
TABMAC <2884h, 288Eh,	  -1,  28F0h,  28F0h> , 0      ;  40  28   Ñ é
TABMAC <295Eh, 29F8h,	  -1,  29F0h,  29F0h> , 0      ;  41  29   ^ ¯
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  42  2A   Left Shift
TABMAC <2B23h, 2B27h,  2B1Ch,  2BF0h,  2BF0h> , 0      ;  43  2B   # '
TABMAC <2C79h, 2C59h,  2C19h,  2C00h,  2C00h> , CAPL   ;  44  2C   z Z
TABMAC <2D78h, 2D58h,  2D18h,  2D00h,  2D00h> , CAPL   ;  45  2D   x X
TABMAC <2E63h, 2E43h,  2E03h,  2E00h,  2E00h> , CAPL   ;  46  2E   c C
TABMAC <2F76h, 2F56h,  2F16h,  2F00h,  2F00h> , CAPL   ;  47  2F   v V
TABMAC <3062h, 3042h,  3002h,  3000h,  3000h> , CAPL   ;  48  30   b B
TABMAC <316Eh, 314Eh,  310Eh,  3100h,  3100h> , CAPL   ;  49  31   n N
TABMAC <326Dh, 324Dh,  320Dh,  32E6h,  3200h> , CAPL   ;  50  32   m M	 Ê
TABMAC <332Ch, 333Bh,	  -1,  33F0h,  33F0h> , 0      ;  51  33   , ;
TABMAC <342Eh, 343Ah,	  -1,  34F0h,  34F0h> , 0      ;  52  34   . :
TABMAC <352Dh, 355Fh,	  -1,  35F0h,  35F0h> , 0      ;  53  35   - _
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
TABMAC <563Ch, 563Eh,	  -1,  567Ch,	  -1> , 0      ;  86  56   < >	 |
TABMAC <8500h, 8700h,  8900h,  8B00h,  8B00h> , 0      ;  87  57   F11
TABMAC <8600h, 8800h,  8A00h,  8C00h,  8C00h> , 0      ;  88  58   F12
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  89  59   ???
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  90  5A   ???
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  91  5B   LWIN
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  92  5C   RWIN
TABMAC <9A00h, 9C00h,  9E00h, 0A700h, 0A700h> , 0      ;  93  5D   AWIN


ASEGTAB  segment use16 word public 'ndata' ; Start ASEGTAB segment
	 assume  ds:NGROUP

	 public  KEY_TAB_SP172
KEY_TAB_SP172 label word

ASEGTAB  ends			; End ASEGTAB segment


ASEGTOG  segment use16 byte public 'ndata' ; Start ASEGTOG segment
	 assume  ds:NGROUP

	 public  KEY_TOG_SP172
KEY_TOG_SP172 label byte

ASEGTOG  ends			; End ASEGTOG segment


;      Unshift Shift Control   R-Alt   L-Alt  Toggle
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;   0  00
TABMAC <011Bh, 011Bh, 0E01Bh,  01F0h,  01F0h> , 0      ;   1  01   Esc
TABMAC <0231h, 0221h,	  -1,  027Ch,  7800h> , 0      ;   2  02   1 !	 |
TABMAC <0332h, 0322h,  0300h,  0340h,  7900h> , 0      ;   3  03   2 "   @
TABMAC <0433h, 04FAh,	  -1,  0423h,  7A00h> , 0      ;   4  04   3 ˙	 #
TABMAC <0534h, 0524h,	  -1,  7B00h,  7B00h> , 0      ;   5  05   4 $
TABMAC <0635h, 0625h,	  -1,  7C00h,  7C00h> , 0      ;   6  06   5 %
TABMAC <0736h, 0726h,  071Eh,  07AAh,  7D00h> , 0      ;   7  07   6 &	 ™
TABMAC <0837h, 082Fh,	  -1,  7E00h,  7E00h> , 0      ;   8  08   7 /
TABMAC <0938h, 0928h,	  -1,  7F00h,  7F00h> , 0      ;   9  09   8 (
TABMAC <0A39h, 0A29h,	  -1,  8000h,  8000h> , 0      ;  10  0A   9 )
TABMAC <0B30h, 0B3Dh,	  -1,  8100h,  8100h> , 0      ;  11  0B   0 =
TABMAC <0C27h, 0C3Fh,  0C1Fh,  8200h,  8200h> , 0      ;  12  0C   ' ?
TABMAC <0DADh, 0DA8h,	  -1,  8300h,  8300h> , 0      ;  13  0D   ≠ ®
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
TABMAC <0085h, 0083h,  1A1Bh,  1A5Bh,  1AF0h> , 0      ;  26  1A   Ö É	 [
TABMAC <1B2Bh, 1B2Ah,  1B1Dh,  1B5Dh,  1BF0h> , 0      ;  27  1B   + *	 ]
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
TABMAC <27A4h, 27A5h,	  -1,  27F0h,  27F0h> , 0      ;  39  27   ; :
TABMAC <00A0h, 0084h,	  -1,  287Bh,  28F0h> , 0      ;  40  28   † Ñ	 {
TABMAC <29A7h, 29A6h,	  -1,  295Ch,  291Ch> , 0      ;  41  29   ß ¶	 \
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  42  2A   Left Shift
TABMAC <2B87h, 2B80h,  2B1Ch,  2B7Dh,  2BF0h> , 0      ;  43  2B   á Ä	 }
TABMAC <2C7Ah, 2C5Ah,  2C1Ah,  2C00h,  2C00h> , CAPL   ;  44  2C   z Z
TABMAC <2D78h, 2D58h,  2D18h,  2D00h,  2D00h> , CAPL   ;  45  2D   x X
TABMAC <2E63h, 2E43h,  2E03h,  2E00h,  2E00h> , CAPL   ;  46  2E   c C
TABMAC <2F76h, 2F56h,  2F16h,  2F00h,  2F00h> , CAPL   ;  47  2F   v V
TABMAC <3062h, 3042h,  3002h,  3000h,  3000h> , CAPL   ;  48  30   b B
TABMAC <316Eh, 314Eh,  310Eh,  3100h,  3100h> , CAPL   ;  49  31   n N
TABMAC <326Dh, 324Dh,  320Dh,  3200h,  3200h> , CAPL   ;  50  32   m M
TABMAC <332Ch, 333Bh,	  -1,  33F0h,  33F0h> , 0      ;  51  33   , ;
TABMAC <342Eh, 343Ah,	  -1,  34F0h,  34F0h> , 0      ;  52  34   . :
TABMAC <352Dh, 355Fh,	  -1,  35F0h,  35F0h> , 0      ;  53  35   - _
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
TABMAC <563Ch, 563Eh,	  -1,	  -1,	  -1> , 0      ;  86  56   < >
TABMAC <8500h, 8700h,  8900h,  8B00h,  8B00h> , 0      ;  87  57   F11
TABMAC <8600h, 8800h,  8A00h,  8C00h,  8C00h> , 0      ;  88  58   F12
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  89  59   ???
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  90  5A   ???
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  91  5B   LWIN
TABMAC <   -1,	  -1,	  -1,	  -1,	  -1> , 0      ;  92  5C   RWIN
TABMAC <9A00h, 9C00h,  9E00h, 0A700h, 0A700h> , 0      ;  93  5D   AWIN

	 MEND			; End SWAT_KT2 module
