;' $Header:   P:/PVCS/MAX/INC/6845.INV   1.0   05 Sep 1995 13:26:58   HENRY  $
;
; (C) Copyright 1987-1999 Qualitas, Inc.  All rights reserved.
;
; 6845.INC
;
; 6845 equates
;

; 3B0-3BB Monochrome Monitor Adapter
; 3D0-3DC Color Graphics Adapter (mapped similarly)
;
; 3B0/3D0  port address decodes to 3B4/3D4
; 3B1/3D1  port address decodes to 3B5/3D5
; 3B2/3D2  port address decodes to 3B4/3D4
; 3B3/3D3  port address decodes to 3B5/3D5
; 3B4/3D4  6845 index register, selects which register [0-11h]
;	   is to be accessed through port 3B5/3D5
; 3B5/3D5  6845 data register [0-11h] selected by port 3B4/3D4,
;	   registers 0C-0F may be read.  If a read occurs
;	   without the adapter installed, FFh is returned.
; 3B6/3D6  port address decodes to 3B4/3D4
; 3B7/3D7  port address decodes to 3B5/3D5
; 3B8/3D8  6845 mode control register
; 3B9/3D9  color select register on color adapter
; 3BA/3DA  status register (read only)
; 3BB/3DB  light pen strobe reset
;     3DC  preset light pen latch
;     3DF  CRT/CPU page register (PCjr only)
; 3BF	   Hercules graphics control


; Equates for CRTC

@CRT_MDA equ	03B4h		; Mono CRT controller address
@CRT_CLR equ	03D4h		; Color ...
@MOD_MDA equ	03B8h		; Mono mode control register
@MOD_CLR equ	03D8h		; Color ...
;;;;_MDA equ	03B9h		; Mono color select register
@SEL_CLR equ	03D9h		; Color ...
@STA_MDA equ	03BAh		; Mono status register
@STA_CLR equ	03DAh		; Color ...
@CTL_HRC equ	03BFh		; Hercules graphics control register


; Registers: Accessed through ports 3B5 & 3D5		   Valid values
			;				MONO CO40 CO80 GRPH
@VID_HTOT   equ  00h	; 00:  Horiz total		 61   38   71	38
@VID_HDISP  equ  01h	; 01:  Horiz display chars/line  50   28   50	28
@VID_HSYNP  equ  02h	; 02:  Horiz sync position	 52   2D   5A	2D
@VID_HSYNW  equ  03h	; 03:  Horiz sync width 	 0F   0A   0A	0A
@VID_VTOT   equ  04h	; 04:  Vertical total		 19   1F   1F	7F
@VID_VTOTAD equ  05h	; 05:  Vertical total adjust	 06   06   06	06
@VID_VDISP  equ  06h	; 06:  Vertical displayed	 19   19   19	64
@VID_VSYNP  equ  07h	; 07:  Vertical sync position	 19   1C   1C	70
@VID_IFMOD  equ  08h	; 08:  Interface mode/skew	 02   02   02	02
@VID_SCAN   equ  09h	; 09:  Maximum scan line address 0D   07   07	01
@VID_SIZLO  equ  0Ah	; 0A:  Cursor start		 0B   06   06	06
@VID_SIZHI  equ  0Bh	; 0B:  ...    end		 0C   07   07	07
@VID_OFFHI  equ  0Ch	; 0C:  Start address (high byte) 00   00   00	00
@VID_OFFLO  equ  0Dh	; 0D:  ...	     (low ...)	 00   00   00	00
@VID_POSHI  equ  0Eh	; 0E:  Cursor loc (high byte)	 00   --   --	--
@VID_POSLO  equ  0Fh	; 0F:  ...	  (low ...)	 00   --   --	--
@VID_LPENHI equ  10h	; 10:  Light pen (MSB)		 --   --   --	--
@VID_LPENLO equ  11h	; 11:  Light pen (LSB)		 --   --   --	--

; Registers 00-0D are write only, registers 0E-0F are read/write
; and registers 10-11 are read only

; Cursor address is calculated with using the following (row*80)+col

COMMENT!

6845 - Port 3B8 (Monochrome)

	|7|6|5|4|3|2|1|0|  3B8 CRT Control Port
	 | | | | | | | ----- 1 = 80x25 text
	 | | | | | -------- unused
	 | | | | --------- 1 = enable video signal
	 | | | ---------- unused
	 | | ----------- 1 = blinking on
	 | ------------ unused
	 ------------- 1 = Hercules graphics page 1 displayed, 0 otherwise
!

P3B8_REC record \
 $P3B8_HGPAGE:1,\
 $P3B8_RSV2:1,	\
 $P3B8_BLINK:1, \
 $P3B8_RSV1:1,	\
 $P3B8_VIDEN:1, \
 $P3B8_RSV0:1,	\
 $P3B8_HGMODE:1,\
 $P3B8_TEXT80:1

@P3B8_HGPAGE	equ	(mask $P3B8_HGPAGE) ; 80:  Hercules graphics page
					    ;	   If Hercules graphics card
					    ;	     and $P3BF_HGPAGE,
					    ;	   then 1 = display page 1
					    ;		0 = display page 0
@P3B8_RSV2	equ	(mask $P3B8_RSV2)   ; 40:  Reserved
@P3B8_BLINK	equ	(mask $P3B8_BLINK)  ; 20:  Blinking on
@P3B8_RSV1	equ	(mask $P3B8_RSV1)   ; 10:  Reserved
@P3B8_VIDEN	equ	(mask $P3B8_VIDEN)  ; 08:  Video enable
@P3B8_RSV0	equ	(mask $P3B8_RSV0)   ; 04:  Reserved
@P3B8_HGMODE	equ	(mask $P3B8_HGMODE) ; 02:  If Hercules graphics card
					    ;	     and $P3BF_HGMODE,
					    ;	   then 1 = graphics mode
					    ;		0 = text mode
@P3B8_TEXT80	equ	(mask $P3B8_TEXT80) ; 01:  80x25 text mode


COMMENT!

6845 - Port 3D8 (Color)

	|7|6|5|4|3|2|1|0|  3D8 Mode Select Register
	 | | | | | | | ----- 1 = 80x25 text, 0 = 40x25 text
	 | | | | | | ------ 1 = 320x200 graphics, 0 = text
	 | | | | | ------- 1 = B/W, 0 = color
	 | | | | -------- 1 = enable video signal
	 | | | --------- 1 = 640x200 B/W graphics
	 | | ---------- 1 = blink, 0 = no blink
	 ------------- unused
!

P3D8_REC record \
 $P3D8_RSV:2,	\
 $P3D8_BLINK:1, \
 $P3D8_640:1,	\
 $P3D8_VIDEN:1, \
 $P3D8_BW:1,	\
 $P3D8_320:1,	\
 $P3D8_TEXT80:1

@P3D8_RSV	equ	(mask $P3D8_RSV)    ; C0:  Reserved
@P3D8_BLINK	equ	(mask $P3D8_BLINK)  ; 20:  Blinking on
@P3D8_640	equ	(mask $P3D8_640)    ; 10:  640x200 B/W graphics mode
@P3D8_VIDEN	equ	(mask $P3D8_VIDEN)  ; 08:  Video enable
@P3D8_BW	equ	(mask $P3D8_BW)     ; 04:  B/W
@P3D8_320	equ	(mask $P3D8_320)    ; 02:  320x200 graphics mode
@P3D8_TEXT80	equ	(mask $P3D8_TEXT80) ; 01:  80x25 text mode


COMMENT!

6845 - Port 3D9 Color Text Modes

	|7|6|5|4|3|2|1|0|  3D9 Color Select Register (3B9 not used)
	 | | | | | --------- screen/border RGB
	 | | | | ---------- select intensity setting
	 | | | ----------- background intensity
	 ---------------- unused
!

P3D9TXT_REC record \
 $P3D9TXT_RSV:3,   \
 $P3D9TXT_BINT:1,  \
 $P3D9TXT_SINT:1,  \
 $P3D9TXT_RGB:3

@P3D9TXT_RSV	equ	(mask $P3D9TXT_RSV) ; E0:  Reserved
@P3D9TXT_BINT	equ	(mask $P3D9TXT_BINT); 10:  Background intensity
@P3D9TXT_SINT	equ	(mask $P3D9TXT_SINT); 08:  Select intensity setting
@P3D9TXT_RGB	equ	(mask $P3D9TXT_RGB) ; 07:  screen/border RGB


COMMENT!

6845 - Port 3D9 Color Graphics Modes

	|7|6|5|4|3|2|1|0|  3D9 Color Select Register (3B9 not used)
	 | | | | | --------- RGB for background
	 | | | | ---------- intensity
	 | | | ----------- unused
	 | | ------------ 1 = palette 1, 0=palette 0 (see below)
	 --------------- unused

	  Palette 0 = green, red, brown
	  Palette 1 = cyan, magenta, white
!

P3D9GRP_REC record \
 $P3D9GRF_RSV1:2,  \
 $P3D9GRF_PAL1:1,  \
 $P3D9GRF_RSV0:1,  \
 $P3D9GRF_INT:1,   \
 $P3D9GRF_RGB:3

@P3D9GRF_RSV1	equ	(mask $P3D9GRF_RSV1); C0:  Reserved
@P3D9GRF_PAL1	equ	(mask $P3D9GRF_PAL1); 20:  Pallete #
@P3D9GRF_RSV0	equ	(mask $P3D9GRF_RSV0); 10:  Reserved
@P3D9GRF_INT	equ	(mask $P3D9GRF_INT) ; 08:  Intensity
@P3D9GRF_RGB	equ	(mask $P3D9GRF_RGB) ; 07:  RGB


COMMENT!

6845 - Port 3DA Status Register

	|7|6|5|4|3|2|1|0|  3DA Status Register
	 | | | | | | | ----- 1 = display enable, RAM access is OK
	 | | | | | | ------ 1 = light pen trigger set
	 | | | | | ------- 0 = light pen on, 1 = light pen off
	 | | | | -------- 1 = vertical retrace, RAM access OK for next 1.25ms
	 --------------- unused
!

P3DA_REC record \
 $P3DA_RSV:4,	\
 $P3DA_VRT:1,	\
 $P3DA_LPEN:1,	\
 $P3DA_LPSET:1, \
 $P3DA_DISPEN:1

@P3DA_RSV	equ	(mask $P3DA_RSV)    ; F0:  Reserved
@P3DA_VRT	equ	(mask $P3DA_VRT)    ; 08:  Vertical retrace
@P3DA_LPEN	equ	(mask $P3DA_LPEN)   ; 04:  Light pen off
@P3DA_LPSET	equ	(mask $P3DA_LPSET)  ; 02:  Light pen trigger set
@P3DA_DISPEN	equ	(mask $P3DA_DISPEN) ; 01:  Display enable


COMMENT!

6845 - Port 3BF Hercules Graphics Control Register

	|7|6|5|4|3|2|1|0|  3BF
	 | | | | | | | ----- 1 = Setting of graphics mode bit $P3B8_HGMODE enabled
	 | | | | | | ------ 1 = Setting of graphics page bit $P3B8_HGPAGE enabled
	 ----------------- unused
!

P3BF_REC record \
 $P3BF_RSV:6,	\
 $P3BF_HGPAGE:1,\
 $P3BF_HGMODE:1

@P3BF_RSV    equ	(mask $P3BF_RSV)    ; FC:  Reserved
@P3BF_HGPAGE equ	(mask $P3BF_HGPAGE) ; 02:  $P3BF_HGPAGE enabled
@P3BF_HGMODE equ	(mask $P3BF_HGMODE) ; 01:  $P3B8_HGMODE enabled


