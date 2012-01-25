/* Copyright 1998 (c) by Salvador Eduardo Tropea
   This code is part of the FreeBE/AF project you can use it under the
terms and conditions of the FreeBE/AF project. */
/*****************************************************************************

  ROUTINES to modify the VGA and TGUI registers to set a video mode

*****************************************************************************/

#include <pc.h>
#include "mytypes.h"
#include "regs.h"
#include "vga.h"
#include "setmode.h"
#include "tgui.h"

#include "font.h"

/*
  This structure holds all VGA the registers captured from 320x200x8bpp. Some
of them where cleared for better defaults or when setting some bits.
*/
uchar DefaultVGARegs[VGARegsCant]={
/* CRT Controller Registers */
0x5F, 0x4F, 0x50, 0x82, 0x54, 0x80, 0xBF, 0x1F, /*  0 -  7 */
0x00, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /*  8 -  F */
0x9C, 0x8E, 0x8F, 0x28, 0x40, 0x96, 0xB9, 0xA3, /* 10 - 17 */
0xFF, 
/* Attribute Controller Registers */
0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 
0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 
0x41, 0x00, 0x0F, 0x00, 0x00, 
/* Graphics Controller Registers */
0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x05, 0x0F, 
0xFF, 
/* Sequence Registers */
0x03, 0x01, 0x0F, 0x00, 0x0E, 
/* Miscellaneous Output Register */
0x23
};

/* VGA Text mode 80x25 (mode 3) */
uchar TextModeVGARegs[VGARegsCant]={
/* CRT Controller Registers */
0x5F, 0x4F, 0x50, 0x82, 0x55, 0x81, 0xBF, 0x1F, 
0x00, 0x4F, 0x0D, 0x0E, 0x00, 0x00, 0x00, 0x00, 
0x9C, 0x8E, 0x8F, 0x28, 0x1F, 0x96, 0xB9, 0xA3, 
0xFF, 
/* Attribute Controller Registers */
0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x14, 0x07,
0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F, 
0x0C, 0x00, 0x0F, 0x08, 0x00, 
/* Graphics Controller Registers */
0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x0E, 0x00, 
0xFF, 
/* Sequence Registers */
0x03, 0x00, 0x03, 0x00, 0x02, 
/* Miscellaneous Output Register */
0x67
};

uchar TextModeFont[256*16];

/* The working copies are used to create a video mode */
uchar WorkingVGARegs[VGARegsCant];
uchar WorkingSVGARegs[SVGARegsCant];
/* That's the state of the TGUI at start. I must use it because some bits
   controls harware specific things so I can't use a set of values taked
   from my board */
uchar CapturedSVGARegs[SVGARegsCant];

/*
 I created 320x240, 400x300, 512x384, 576x432, 720x540 and 900x675

 Notes:
 * Changing CRT4 you can center horizontally.
 * Changing Vtotal you can reduce the vertical size.

*/

VideoModeStr g320x200x8=
{
 NHSync | PVSync | BPP8 | DoubleScan | HaveAccel2D,
 320,336,376,400,
 400,412,414,449,
 /* minimal bytes per scan needed for this mode */
 512,
 /* Clock: Programmed to 25.175/2 MHz fh=31.47 KHz fv=70.09 Hz OK! +V -H */
 0 | VClockDiv2,0x19,0xC2
 //2 | VClockDiv2,0x1E,0xE5 12.586142 MHz fh=31.47 KHz fv=70.08 Hz
};

VideoModeStr g320x200x15=
{
 NHSync | PVSync | BPP15 | DoubleScan | HaveAccel2D,
 320,336,376,400,
 400,412,414,449,
 /* minimal bytes per scan needed for this mode */
 640,
 /* Clock: Programmed to 25.18 MHz fh=31.475 KHz fv=70.1 Hz OK! +V -H */
 0,0x19,0xC2
};

VideoModeStr g320x200x16=
{
 NHSync | PVSync | BPP16 | DoubleScan | HaveAccel2D,
 320,336,376,400,
 400,412,414,449,
 /* minimal bytes per scan needed for this mode */
 640,
 /* Clock: Programmed to 25.18 MHz fh=31.475 KHz fv=70.1 Hz OK! +V -H */
 0,0x19,0xC2
};

VideoModeStr g320x200x24=
{
 NHSync | PVSync | BPP24 | DoubleScan,
 320,336,376,400,
 400,412,414,449,
 /* minimal bytes per scan needed for this mode */
 960,
 /* Clock: Programmed to 37.75 MHz fh=31.46 KHz fv=70.1 Hz OK! +V -H */
 2,0x14,0xB2
};

VideoModeStr g320x240x8=
{
 NHSync | NVSync | BPP8 | DoubleScan | HaveAccel2D,
 320,336,384,408,
 480,490,508,527,
 /* minimal bytes per scan needed for this mode */
 512,
 /* Clock: Programmed to 25.65/2 MHz fh=31.43 KHz fv=59.7 Hz OK! -V -H */
 /* That's almost IBM's VGA3/60Hz mode */
 2 | VClockDiv2,0x15,0x23
};

VideoModeStr g320x240x15=
{
 NHSync | NVSync | BPP15 | DoubleScan | HaveAccel2D,
 320,336,384,408,
 480,490,508,527,
 /* minimal bytes per scan needed for this mode */
 640,
 /* Clock: Programmed to 25.65 MHz fh=31.43 KHz fv=59.7 Hz OK! -V -H */
 /* That's almost IBM's VGA3/60Hz mode */
 2,0x15,0x23
};

VideoModeStr g320x240x16=
{
 NHSync | NVSync | BPP16 | DoubleScan | HaveAccel2D,
 320,336,384,408,
 480,490,508,527,
 /* minimal bytes per scan needed for this mode */
 640,
 /* Clock: Programmed to 25.65 MHz fh=31.43 KHz fv=59.7 Hz OK! -V -H */
 /* That's almost IBM's VGA3/60Hz mode */
 2,0x15,0x23
};

VideoModeStr g320x240x24=
{
 NHSync | NVSync | BPP24 | DoubleScan,
 320,344,384,424,
 480,490,492,525,
 /* minimal bytes per scan needed for this mode */
 960,
 /* Clock: Programmed to 40.09 MHz fh=31.52 KHz fv=60.15 Hz OK! -V -H */
 /* That's almost IBM's VGA3/60Hz mode */
 2,0x14,0x30
};

VideoModeStr g400x300x8=
{
 PHSync | PVSync | BPP8 | DoubleScan | HaveAccel2D,
 400,428,492,528,
 600,601,604,628,
 /* minimal bytes per scan needed for this mode */
 512,
 /* Clock: Programmed to 37.14/2 MHz fh=35.17 KHz fv=56 Hz OK! +V +H */
 /* These are the syncs for 800/56Hz VESA standard mode */
 2 | VClockDiv2,0x17,0x4B
};

VideoModeStr g400x300x15=
{
 PHSync | PVSync | BPP15 | DoubleScan | HaveAccel2D,
 400,428,492,528,
 600,601,604,628,
 /* minimal bytes per scan needed for this mode */
 800,
 /* Clock: Programmed to 37.14 MHz fh=35.17 KHz fv=56 Hz OK! +V +H */
 /* These are the syncs for 800/56Hz VESA standard mode */
 2,0x17,0x4B
};

VideoModeStr g400x300x16=
{
 PHSync | PVSync | BPP16 | DoubleScan | HaveAccel2D,
 400,428,492,528,
 600,601,604,628,
 /* minimal bytes per scan needed for this mode */
 800,
 /* Clock: Programmed to 37.14 MHz fh=35.17 KHz fv=56 Hz OK! +V +H */
 /* These are the syncs for 800/56Hz VESA standard mode */
 2,0x17,0x4B
};

VideoModeStr g400x300x24=
{
 PHSync | PVSync | BPP24 | DoubleScan,
 400,428,492,528,
 600,601,604,628,
 /* minimal bytes per scan needed for this mode */
 1200,
 /* Clock: Programmed to 55.74 MHz fh=35.19 KHz ~fv=56 Hz OK! +V +H */
 /* These are the syncs for 800/56Hz VESA standard mode */
 2,0x16,0x65
};

VideoModeStr g512x384x8=
{
 NHSync | PVSync | BPP8 | HaveAccel2D,
 512,528,576,640,
 384,400,414,442,
 /* minimal bytes per scan needed for this mode */
 512,
 /* Clock: Programmed to 39.97/2 MHz fh=31.23 KHz fv=70.6 Hz OK! +V -H */
 /* Very close to IBM's VGA2/70 */
 2 | VClockDiv2,0x15,0x3B
};
/* Another option could be:
"512x384"   20.401   512 536 560 648   384 404 406 449   -Hsync +Vsync
 31.483kHz/70.12Hz
*/

VideoModeStr g512x384x15=
{
 NHSync | PVSync | BPP15 | HaveAccel2D,
 512,528,576,640,
 384,400,414,442,
 /* minimal bytes per scan needed for this mode */
 1024,
 /* Clock: Programmed to 39.97 MHz fh=31.23 KHz fv=70.6 Hz OK! +V -H */
 /* Very close to IBM's VGA2/70 */
 2,0x15,0x3B
};

VideoModeStr g512x384x16=
{
 NHSync | PVSync | BPP16 | HaveAccel2D,
 512,528,576,640,
 384,400,414,442,
 /* minimal bytes per scan needed for this mode */
 1024,
 /* Clock: Programmed to 39.97 MHz fh=31.23 KHz fv=70.6 Hz OK! +V -H */
 /* Very close to IBM's VGA2/70 */
 2,0x15,0x3B
};

VideoModeStr g512x384x24=
{
 NHSync | PVSync | BPP24,
 512,528,576,640,
 384,400,414,442,
 /* minimal bytes per scan needed for this mode */
 1024,
 /* Clock: Programmed to 60.03 MHz fh=31.26 KHz fv=70.7 Hz OK! +V -H */
 /* Very close to IBM's VGA2/70 */
 2,0x15,0xE5
};

VideoModeStr g576x432x8=
{
 //NHSync | PVSync | BPP8,
 NHSync | NVSync | BPP8 | HaveAccel2D,
 576,604,692,720,
 432,442,444,473,
 /* minimal bytes per scan needed for this mode */
 640,
 /* Clock: Programmed to 45.34/2 MHz fh=31.49 KHz fv=66.6 Hz OK! -V -H */
 /* That's a little messy standard verticals are 60 and 70 Hz */
 2 | VClockDiv2,0x10,0x8B
};

VideoModeStr g576x432x15=
{
 NHSync | NVSync | BPP15 | HaveAccel2D,
 576,604,692,720,
 432,442,444,473,
 /* minimal bytes per scan needed for this mode */
 1280,
 /* Clock: Programmed to 45.34 MHz fh=31.49 KHz fv=66.6 Hz OK! -V -H */
 /* That's a little messy standard verticals are 60 and 70 Hz */
 2,0x10,0x8B
};

VideoModeStr g576x432x16=
{
 NHSync | NVSync | BPP16 | HaveAccel2D,
 576,604,692,720,
 432,442,444,473,
 /* minimal bytes per scan needed for this mode */
 1280,
 /* Clock: Programmed to 45.34 MHz fh=31.49 KHz fv=66.6 Hz OK! -V -H */
 /* That's a little messy standard verticals are 60 and 70 Hz */
 2,0x10,0x8B
};

VideoModeStr g576x432x24=
{
 NHSync | NVSync | BPP24,
 576,604,692,720,
 432,442,444,473,
 /* minimal bytes per scan needed for this mode */
 1728,
 /* Clock: Programmed to 67.41 MHz fh=31.21 KHz fv=66 Hz OK! -V -H */
 /* That's a little messy standard verticals are 60 and 70 Hz */
 2,0x15,0x69
};

#if 0
VideoModeStr g512x384x8=
{
 NHSync | NVSync | BPP8 | HaveAccel2D,
 512,384,
 /* minimal bytes per scan needed for this mode */
 512,
 /* Horizontal CRT timing (CRT0-5) 640 */
 0x4B, 0x3F, 0x40, 0x8E, 0x42, 0x08,
 /* Vertical CRT timing (CRT6,7,9,10,11,12,15,16) 409 */
 0x98, 0x1F, 0x00, 0x81, 0x86, 0x7F, 0x83, 0x95,
 /* SVGA Overflows */
 0x00,
 /* Clock: Programmed to 39.7 MHz fh=31 KHz fv=75 Hz */
 0x42,0x14,0xB5
};
#endif

VideoModeStr g640x400x8=
{
 NHSync | PVSync | BPP8 | HaveAccel2D,
 640,664,768,800,
 400,412,414,449,
 /* minimal bytes per scan needed for this mode */
 640,
 /* Clock: Programmed to 25.18 MHz fh=31.48 KHz fv=70.1 Hz */
 /* IBM's VGA2/70 */
 0,0x19,0xC2
};

VideoModeStr g640x400x15=
{
 NHSync | PVSync | BPP15 | HaveAccel2D,
 640,664,768,800,
 400,412,414,449,
 /* minimal bytes per scan needed for this mode */
 1280,
 /* Clock: Programmed to 50.11 MHz fh=31.32 KHz fv=69.8 Hz */
 /* IBM's VGA2/70 */
 2,0x01,0x06
};

VideoModeStr g640x400x16=
{
 NHSync | PVSync | BPP16 | HaveAccel2D,
 640,664,768,800,
 400,412,414,449,
 /* minimal bytes per scan needed for this mode */
 1280,
 /* Clock: Programmed to 50.11 MHz fh=31.32 KHz fv=69.8 Hz */
 /* IBM's VGA2/70 */
 2,0x01,0x06
};

VideoModeStr g640x400x24=
{
 NHSync | PVSync | BPP24,
 640,664,768,800,
 400,412,414,449,
 /* minimal bytes per scan needed for this mode */
 1920,
 /* Clock: Programmed to 75.50 MHz fh=31.46 KHz fv=70.1 Hz */
 /* IBM's VGA2/70 */
 2,0x04,0xB2
};

VideoModeStr g640x480x8=
{
 NHSync | NVSync | BPP8 | HaveAccel2D,
 640,664,768,800,
 480,490,492,525,
 /* minimal bytes per scan needed for this mode */
 640,
 /* Clock: Programmed to 25.23 MHz fh=31.53 KHz fv=60 Hz */
 /* IBM's VGA3/60 */
 0,0x19,0xC2
};

VideoModeStr g640x480x15=
{
 NHSync | NVSync | BPP15 | HaveAccel2D,
 640,664,768,800,
 480,490,492,525,
 /* minimal bytes per scan needed for this mode */
 1280,
 /* Clock: Programmed to 50.56 MHz ~fh=31.54 KHz ~fv=60 Hz */
 /* IBM's VGA3/60 */
 2,0x17,0x69
};

VideoModeStr g640x480x16=
{
 NHSync | NVSync | BPP16 | HaveAccel2D,
 640,664,768,800,
 480,490,492,525,
 /* minimal bytes per scan needed for this mode */
 1280,
 /* Clock: Programmed to 50.56 MHz ~fh=31.54 KHz ~fv=60 Hz */
 /* IBM's VGA3/60 */
 2,0x17,0x69
};

VideoModeStr g640x480x24=
{
 NHSync | NVSync | BPP24,
 640,664,768,800,
 480,490,492,525,
 /* minimal bytes per scan needed for this mode */
 1920,
 /* Clock: Programmed to 75.89 MHz fh=31.62 KHz fv=60.23 Hz */
 /* IBM's VGA3/60 */
 2,0x04,0x2D
};

VideoModeStr g720x540x8=
{
 NHSync | NVSync | BPP8 | HaveAccel2D,
 720,770,886,950,
 540,552,554,590,
 /* minimal bytes per scan needed for this mode */
 800,
 /* Clock: Programmed to 31.94 MHz fh=35.49 KHz fv=60.2 Hz OK! -V -H */
 /* A little messy too, both standard but not from the same mode */
 2,0x15,0xB2 // 31.94
};

VideoModeStr g720x540x15=
{
 NHSync | NVSync | BPP15 | HaveAccel2D,
 720,770,886,950,
 540,552,554,590,
 /* minimal bytes per scan needed for this mode */
 1600,
 /* Clock: Programmed to 63.88 MHz fh=35.49 KHz fv=60.2 Hz OK! -V -H */
 /* A little messy too, both standard but not from the same mode */
 2,0x05,0xB2 // 63.88
};

VideoModeStr g720x540x16=
{
 NHSync | NVSync | BPP16 | HaveAccel2D,
 720,770,886,950,
 540,552,554,590,
 /* minimal bytes per scan needed for this mode */
 1600,
 /* Clock: Programmed to 63.88 MHz fh=35.49 KHz fv=60.2 Hz OK! -V -H */
 /* A little messy too, both standard but not from the same mode */
 2,0x05,0xB2 // 63.88
};

VideoModeStr g720x540x24=
{
 NHSync | NVSync | BPP24,
 720,770,886,950,
 540,552,554,590,
 /* minimal bytes per scan needed for this mode */
 2160,
 /* Clock: Programmed to 95.82 MHz fh=35.49 KHz fv=60.15 Hz OK! -V -H */
 /* A little messy too, both standard but not from the same mode */
 2,0x05,0xCF // 95.82
};

VideoModeStr g800x600x8=
{
 NHSync | NVSync | BPP8 | HaveAccel2D,
 800,856,984,1056,
 600,600,604,628,
 /* minimal bytes per scan needed for this mode */
 800,
 /* Clock: Programmed to 37.14 MHz => fh=35.17 KHz fv=56 Hz */
 /* VESA 800/56Hz */
 2,0x17,0x4B
};

VideoModeStr g800x600x15=
{
 NHSync | NVSync | BPP15 | HaveAccel2D,
 800,856,984,1056,
 600,600,604,628,
 /* minimal bytes per scan needed for this mode */
 1600,
 /* Clock: Programmed to 74.28 MHz => fh=35.17 KHz fv=56 Hz */
 /* VESA 800/56Hz */
 2,0x07,0x4B
};

VideoModeStr g800x600x16=
{
 NHSync | NVSync | BPP16 | HaveAccel2D,
 800,856,984,1056,
 600,600,604,628,
 /* minimal bytes per scan needed for this mode */
 1600,
 /* Clock: Programmed to 74.28 MHz => fh=35.17 KHz fv=56 Hz */
 /* VESA 800/56Hz */
 2,0x07,0x4B
};

VideoModeStr g800x600x24=
{
 NHSync | NVSync | BPP24,
 800,856,984,1056,
 600,600,604,628,
 /* minimal bytes per scan needed for this mode */
 2400,
 /* Clock: Programmed to 111.48 MHz => fh=35.19 KHz fv=56.03 Hz */
 /* VESA 800/56Hz */
 2,0x06,0x65
};

VideoModeStr g900x675x8=
{
 NHSync | PVSync | BPP8 | HaveAccel2D,
 900,904,1076,1110,
 675,675,680,719,
 /* minimal bytes per scan needed for this mode */
 1024,
 /* Clock: Programmed to 39.77 MHz fh=35.83 KHz fv=49.76 Hz OK! +V -H */
 /* Really messy, 50 Hz isn't standard at all */
 2,0x13,0xAA
};

VideoModeStr g900x675x15=
{
 NHSync | PVSync | BPP15 | HaveAccel2D,
 900,904,1076,1110,
 675,675,680,719,
 /* minimal bytes per scan needed for this mode */
 2048,
 /* Clock: Programmed to 79.55 MHz fh=35.83 KHz fv=49.76 Hz OK! +V -H */
 /* Really messy, 50 Hz isn't standard at all */
 2,0x03,0xAA
};

VideoModeStr g900x675x16=
{
 NHSync | PVSync | BPP16 | HaveAccel2D,
 900,904,1076,1110,
 675,675,680,719,
 /* minimal bytes per scan needed for this mode */
 2048,
 /* Clock: Programmed to 79.55 MHz fh=35.83 KHz fv=49.76 Hz OK! +V -H */
 /* Really messy, 50 Hz isn't standard at all */
 2,0x03,0xAA
};

VideoModeStr g900x675x24=
{
 NHSync | PVSync | BPP24,
 900,904,1076,1110,
 675,675,680,719,
 /* minimal bytes per scan needed for this mode */
 2700,
 /* Clock: Programmed to 119.32 MHz fh=35.83 KHz fv=49.76 Hz OK! +V -H */
 /* Really messy, 50 Hz isn't standard at all */
 2,0x00,0x91
};

VideoModeStr g1024x768x8=
{
 PHSync | PVSync | Interlaced | BPP8 | HaveAccel2D,
 1024,1040,1224,1264,
 384,385,390,410,
 /* minimal bytes per scan needed for this mode */
 1024,
 /* Clock: Programmed to 44.91 MHz => fh=35.53 KHz fv=43.43 Hz (*2) */
 /* Standard XGA/87iHz */
 2,0x14,0xBD
};

VideoModeStr g1024x768x15=
{
 PHSync | PVSync | Interlaced | BPP15 | HaveAccel2D,
 1024,1040,1224,1264,
 384,385,390,410,
 /* minimal bytes per scan needed for this mode */
 2048,
 /* Clock: Programmed to 89.81 MHz => fh=35.53 KHz fv=43.43 Hz (*2) */
 /* Standard XGA/87iHz */
 2,0x04,0xBD
};

VideoModeStr g1024x768x16=
{
 PHSync | PVSync | Interlaced | BPP16 | HaveAccel2D,
 1024,1040,1224,1264,
 384,385,390,410,
 /* minimal bytes per scan needed for this mode */
 2048,
 /* Clock: Programmed to 89.81 MHz => fh=35.53 KHz fv=43.43 Hz (*2) */
 /* Standard XGA/87iHz */
 2,0x04,0xBD
};

#if 0
VideoModeStr g1152x900x8=
{
 PHSync | PVSync | Interlaced | BPP8 | HaveAccel2D,
 1152,900,
 /* minimal bytes per scan needed for this mode */
 1280,
 /* Horizontal CRT timing (CRT0-5) ~1152 1424 */
 0xAD,0x8F,0x90,0x8F,0x93,0x8C,
 /* Vertical CRT timing (CRT6,7,9,10,11,12,15,16) 450 458 */
 0xD3,0x1F,0x40,0xC2,0x87,0xC1,0xC2,0xD3, // Ok
 //0xC8,0x1F,0x40,0xC2,0x87,0xC1,0xC2,0xC8,
 /* SVGA Overflows CRT27 */
 0x00,
 /* Clock: Programmed to 44.91 MHz => fh=35.50 KHz fv=77.5i Hz  */
 /* A real mess, better let it outside the list */
 2,0x17,0x69 // 50.56
 //2,0x14,0xCB // 54.02
};
#endif

VideoModeStr *SupportedVideoModes[]={
 &g320x200x8, &g320x240x8, &g400x300x8, &g512x384x8, &g576x432x8, &g640x400x8,
 &g640x480x8, &g720x540x8, &g800x600x8, &g900x675x8,&g1024x768x8,
&g320x200x15,&g320x240x15,&g400x300x15,&g512x384x15,&g576x432x15,&g640x400x15,
&g640x480x15,&g720x540x15,&g800x600x15,&g900x675x15,&g1024x768x15,
&g320x200x16,&g320x240x16,&g400x300x16,&g512x384x16,&g576x432x16,&g640x400x16,
&g640x480x16,&g720x540x16,&g800x600x16,&g900x675x16,&g1024x768x16,
&g320x200x24,&g320x240x24,&g400x300x24,&g512x384x24,&g576x432x24,&g640x400x24,
&g640x480x24,&g720x540x24,&g800x600x24,&g900x675x24
};

short SupportedVideoModesNums[]={
 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11, /* 8 bpp */
12,13,14,15,16,17,18,19,20,21,22, /* 15 bpp */
23,24,25,26,27,28,29,30,31,32,33, /* 16 bpp */
34,35,36,37,38,39,40,41,42,43,    /* 24 bpp */
-1
};

int NumSupportedVideoModes=sizeof(SupportedVideoModes)/sizeof(VideoModeStr *);

static int GERCanBeUsed;
static int Pitchs[]={/*320,400,*/512,640,800,1024,1280,1600,2048,2560,3200,4096,-1};
static uchar GER23v[]={/*1,3,*/0,1,3,0,1,3,0,1,3,0};
static uchar GER22v[]={/*0,0,*/0,4,4,4,8,8,8,12,12,12};

int GetBestPitchFor(int Width, int BytesPerPixel)
{
 int i;
 int BytesPerScan=Width*BytesPerPixel;

 if (BytesPerPixel==3)
   { /* 24 bpp modes aren't supported by the accelerator */
    if (Width>1360)
       return -1;
    /* Round to the next multiple of 8 */
    if (BytesPerScan & 7)
       BytesPerScan+=8-(BytesPerScan & 7);
    return BytesPerScan;
   }
 /* Choose a supported pitch */
 for (i=0; Pitchs[i]>0; i++)
    {
     if (Pitchs[i]>=BytesPerScan)
	return Pitchs[i];
    }
 return -1;
}

/*
 This function modifies the SVGA registers for the specified mode. Is called
from the VGA counterpart.
*/
void SetForSVGAMode(VideoModeStr *mode,int VirtualWidth, uchar *r, uchar *rs,
		    unsigned vDisplay, unsigned vBlankStart, unsigned vSyncStart,
		    unsigned vTotal)
{
 //rs[ECRT_25]|=0x80;
 /* b8 of Logical Width */
 rs[ECRT_29]&=0xEC; /* b0-1 maps the DAC in the right place */
 rs[ECRT_29]|=(((VirtualWidth/8) & 0x100)>>(8-4));
 /* Clock */
 rs[ALT_CLK]=mode->ClockType | 0xF;
 rs[VCLKLOW]=mode->ClockValLow;
 rs[VCLKHIG]=mode->ClockValHigh;
   /* Copy the same values to the MOR */
 r[MORbase]&=0xF3;
 r[MORbase]|=(mode->ClockType & 0x3)<<2;
  /* The original place for the divider NOT needed */
 //rs[ESEQ_0D_new]&=0xF9;
 //rs[ESEQ_0D_new]|=mode->ClockType>>5;
 /* Enable bit 16 of Start Address */
 /* Set No/Interlaced mode */
 /* Protect Misc. Output Reg. */
 rs[ECRT_1E]=0x80;
 if (mode->flags & Interlaced)
    rs[ECRT_1E]|=4;
 /* Enable 32 bits internal Bus */
 rs[ECRT_2A]|=0x40;
 /* Enable alternative bank and clock */
 /* Compressed chain 4 mode addressing */
 rs[EGRA_0F]|=2 | 4;
 /* Disable skew control */
 rs[EGRA_2F]|=0x20;
 if (mode->flags & Interlaced)
    rs[EGRA_2F]|=4;
 /* Set the pixel size */
 GERCanBeUsed=1;
 switch (ExtractBPP(mode->flags))
   {
    /* 8 bpp */
    case 0:
	 rs[ECRT_38]&=0xF3; /* clear b2 and b3 */
	 rs[DAC_3C6_4th]=0;   /* Pseudo color mode */
	 rs[EGRA_0F]&=0xB7; /* clear b3 and b6 */
	 rs[GER_22]=0;
	 break;
    /* 15 bpp */
    case 1:
	 rs[ECRT_38]&=0xF7;  /* clear b3 */
	 rs[ECRT_38]|=4;     /* set b2 */
	 rs[DAC_3C6_4th]=0x10; /* Hi Color mode */
	 rs[EGRA_0F]&=0xBF;  /* clear b6 */
	 rs[EGRA_0F]|=8;     /* set b3 */
	 rs[GER_22]=1;
	 break;
    /* 16 bpp */
    case 2:
	 rs[ECRT_38]&=0xF7;  /* clear b3 */
	 rs[ECRT_38]|=4;     /* set b2 */
	 rs[DAC_3C6_4th]=0x30; /* XGA mode */
	 rs[EGRA_0F]&=0xBF;  /* clear b6 */
	 rs[EGRA_0F]|=8;     /* set b3 */
	 rs[GER_22]=1;
	 break;
    /* 24 bpp */
    case 3:
	 rs[ECRT_38]&=0xFB;  /* clear b2 */
	 rs[ECRT_38]|=8;     /* set b3 */
	 rs[DAC_3C6_4th]=0xD0; /* True Color mode */
	 rs[EGRA_0F]&=0xF7;  /* clear b3 */
	 rs[EGRA_0F]|=0x40;  /* set b6 */
	 rs[GER_22]=2; /* Just for testing the effect */
	 GERCanBeUsed=0;
	 break;
   }
 /* SVGA overflows */
 rs[ECRT_27]=0x8 | ((vDisplay    & 0x400)>>6) |
		   ((vSyncStart  & 0x400)>>5) |
		   ((vBlankStart & 0x400)>>4) |
		   ((vTotal      & 0x400)>>3);

 if (GERCanBeUsed)
   { /* See if the width is compatible with the GER and what values to use */
    int i=0;
    while (Pitchs[i]>0)
      {
       if (Pitchs[i]==VirtualWidth)
	 {
	  rs[GER_23]=GER23v[i];
	  rs[GER_22]|=GER22v[i];
	  //break;
	 }
       i++;
      }
    if (Pitchs[i]>0)
       GERCanBeUsed=0;
   }

 /* Now set some initialization values */
 /* Bank 0 for Write, we use 2 because bit 1 is inverted in the ESEQ_0E
    I can't use the ALT_BNK_WRITE here because I write to ESEQ_0E at the
    end of the loading so ESEQ_0E will overwrite ALT_BNK_WRITE.
    Yes, is a complex issue. */
 rs[ESEQ_0E_new]|=2;
 /* Bank 0 for reading */
 rs[ALT_BNK_READ]=0;
 /* No mask any DAC bit, just in case */
 rs[DAC_3C6]=0xFF;
 /* Graphic Engine mapped in B7FXX and enabled */
 rs[ECRT_36]=GERCanBeUsed ? 0x81 : 0;
 rs[ECRT_21]=0xD6;
}

/*
 This function modifies the VGA registers for the specified mode. Then calls
to the SVGA counterpart.
*/
void SetForVGAMode(VideoModeStr *mode,int VirtualWidth,uchar *r, uchar *rs)
{
 unsigned Display,SyncStart,SyncEnd,Total,BlankEnd,BlankStart;

 switch (ExtractBPP(mode->flags))
   {
    /* 8 bpp */
    case 0:
	 break;
    /* 15 bpp */
    case 1:
	 VirtualWidth*=2;
	 break;
    /* 16 bpp */
    case 2:
	 VirtualWidth*=2;
	 break;
    /* 24 bpp */
    case 3:
	 VirtualWidth*=3;
	 break;
   } 
 /* +/- H and V Sync */
 r[MORbase]|=(mode->flags & 3)<<6;

 /* Horizontal timing */
 Display    = mode->hDisplay/8;
 SyncStart  = mode->hSyncStart/8;
 SyncEnd    = mode->hSyncEnd/8;
 Total      = mode->hTotal/8;
 BlankEnd   = Total-2; /* Left 2 for borders */
 BlankStart = Display;

 r[CRTbase+0x00]=Total-5;
 r[CRTbase+0x01]=Display-1;
 r[CRTbase+0x02]=BlankStart; // Blank Start
 r[CRTbase+0x03]=0x80 | (BlankEnd & 0x1F);
 r[CRTbase+0x04]=SyncStart;
 r[CRTbase+0x05]=(SyncEnd & 0x1F) | ((BlankEnd & 0x20)<<2);
 /* Logical Width (Offset) */
 r[CRTbase+0x13]=VirtualWidth/8;

 /* Vertical timing */
 Display    = mode->vDisplay;
 SyncStart  = mode->vSyncStart;
 SyncEnd    = mode->vSyncEnd;
 Total      = mode->vTotal;
 BlankEnd   = Total-2; /* Left 2 for borders */
 BlankStart = Display;

 r[CRTbase+0x06]=Total;
 r[CRTbase+0x07]=((Total & 0x100)>>8) | ((Display & 0x100)>>7) |
		 ((SyncStart & 0x100)>>6) | ((BlankStart & 0x100)>>5) |
		 0x10 | ((Total & 0x200)>>4) | ((Display & 0x200)>>3) |
		 ((SyncStart & 0x200)>>2);
  /* Number of scans before next line, VBS bit 9 and Line Compare bit 9 */
 r[CRTbase+0x09]|=((mode->flags & 0xC)>>2) | ((BlankStart & 0x200)>>4) | 0x40;
 r[CRTbase+0x10]=SyncStart;
 r[CRTbase+0x11]=0x80 | (SyncEnd & 0x0F);
 r[CRTbase+0x12]=Display-1;
 r[CRTbase+0x15]=BlankStart;
 r[CRTbase+0x16]=BlankEnd;

 /* Line compare 0x3FF to avoid display split */
 r[CRTbase+0x18]=0xFF;

 SetForSVGAMode(mode,VirtualWidth,r,rs,Display,BlankStart,SyncStart,Total);
}

void CaptureSVGAStart(void)
{
 TGUI9440SaveRegs(CapturedSVGARegs);
}

uchar DefaultTXTPalette[768]={
0x00,0x00,0x00,0x00,0x00,0x2A,0x00,0x2A,0x00,0x00,0x2A,0x2A,0x2A,0x00,0x00,0x2A,
0x00,0x2A,0x2A,0x2A,0x00,0x2A,0x2A,0x2A,0x00,0x00,0x15,0x00,0x00,0x3F,0x00,0x2A,
0x15,0x00,0x2A,0x3F,0x2A,0x00,0x15,0x2A,0x00,0x3F,0x2A,0x2A,0x15,0x2A,0x2A,0x3F,
0x00,0x15,0x00,0x00,0x15,0x2A,0x00,0x3F,0x00,0x00,0x3F,0x2A,0x2A,0x15,0x00,0x2A,
0x15,0x2A,0x2A,0x3F,0x00,0x2A,0x3F,0x2A,0x00,0x15,0x15,0x00,0x15,0x3F,0x00,0x3F,
0x15,0x00,0x3F,0x3F,0x2A,0x15,0x15,0x2A,0x15,0x3F,0x2A,0x3F,0x15,0x2A,0x3F,0x3F,
0x15,0x00,0x00,0x15,0x00,0x2A,0x15,0x2A,0x00,0x15,0x2A,0x2A,0x3F,0x00,0x00,0x3F,
0x00,0x2A,0x3F,0x2A,0x00,0x3F,0x2A,0x2A,0x15,0x00,0x15,0x15,0x00,0x3F,0x15,0x2A,
0x15,0x15,0x2A,0x3F,0x3F,0x00,0x15,0x3F,0x00,0x3F,0x3F,0x2A,0x15,0x3F,0x2A,0x3F,
0x15,0x15,0x00,0x15,0x15,0x2A,0x15,0x3F,0x00,0x15,0x3F,0x2A,0x3F,0x15,0x00,0x3F,
0x15,0x2A,0x3F,0x3F,0x00,0x3F,0x3F,0x2A,0x15,0x15,0x15,0x15,0x15,0x3F,0x15,0x3F,
0x15,0x15,0x3F,0x3F,0x3F,0x15,0x15,0x3F,0x15,0x3F,0x3F,0x3F,0x15,0x3F,0x3F,0x3F,
0x3F,0x1F,0x1F,0x3F,0x27,0x1F,0x3F,0x2F,0x1F,0x3F,0x37,0x1F,0x3F,0x3F,0x1F,0x37,
0x3F,0x1F,0x2F,0x3F,0x1F,0x27,0x3F,0x1F,0x1F,0x3F,0x1F,0x1F,0x3F,0x27,0x1F,0x3F,
0x2F,0x1F,0x3F,0x37,0x1F,0x3F,0x3F,0x1F,0x37,0x3F,0x1F,0x2F,0x3F,0x1F,0x27,0x3F,
0x2D,0x2D,0x3F,0x31,0x2D,0x3F,0x36,0x2D,0x3F,0x3A,0x2D,0x3F,0x3F,0x2D,0x3F,0x3F,
0x2D,0x3A,0x3F,0x2D,0x36,0x3F,0x2D,0x31,0x3F,0x2D,0x2D,0x3F,0x31,0x2D,0x3F,0x36,
0x2D,0x3F,0x3A,0x2D,0x3F,0x3F,0x2D,0x3A,0x3F,0x2D,0x36,0x3F,0x2D,0x31,0x3F,0x2D,
0x2D,0x3F,0x2D,0x2D,0x3F,0x31,0x2D,0x3F,0x36,0x2D,0x3F,0x3A,0x2D,0x3F,0x3F,0x2D,
0x3A,0x3F,0x2D,0x36,0x3F,0x2D,0x31,0x3F,0x00,0x00,0x1C,0x07,0x00,0x1C,0x0E,0x00,
0x1C,0x15,0x00,0x1C,0x1C,0x00,0x1C,0x1C,0x00,0x15,0x1C,0x00,0x0E,0x1C,0x00,0x07,
0x1C,0x00,0x00,0x1C,0x07,0x00,0x1C,0x0E,0x00,0x1C,0x15,0x00,0x1C,0x1C,0x00,0x15,
0x1C,0x00,0x0E,0x1C,0x00,0x07,0x1C,0x00,0x00,0x1C,0x00,0x00,0x1C,0x07,0x00,0x1C,
0x0E,0x00,0x1C,0x15,0x00,0x1C,0x1C,0x00,0x15,0x1C,0x00,0x0E,0x1C,0x00,0x07,0x1C,
0x0E,0x0E,0x1C,0x11,0x0E,0x1C,0x15,0x0E,0x1C,0x18,0x0E,0x1C,0x1C,0x0E,0x1C,0x1C,
0x0E,0x18,0x1C,0x0E,0x15,0x1C,0x0E,0x11,0x1C,0x0E,0x0E,0x1C,0x11,0x0E,0x1C,0x15,
0x0E,0x1C,0x18,0x0E,0x1C,0x1C,0x0E,0x18,0x1C,0x0E,0x15,0x1C,0x0E,0x11,0x1C,0x0E,
0x0E,0x1C,0x0E,0x0E,0x1C,0x11,0x0E,0x1C,0x15,0x0E,0x1C,0x18,0x0E,0x1C,0x1C,0x0E,
0x18,0x1C,0x0E,0x15,0x1C,0x0E,0x11,0x1C,0x14,0x14,0x1C,0x16,0x14,0x1C,0x18,0x14,
0x1C,0x1A,0x14,0x1C,0x1C,0x14,0x1C,0x1C,0x14,0x1A,0x1C,0x14,0x18,0x1C,0x14,0x16,
0x1C,0x14,0x14,0x1C,0x16,0x14,0x1C,0x18,0x14,0x1C,0x1A,0x14,0x1C,0x1C,0x14,0x1A,
0x1C,0x14,0x18,0x1C,0x14,0x16,0x1C,0x14,0x14,0x1C,0x14,0x14,0x1C,0x16,0x14,0x1C,
0x18,0x14,0x1C,0x1A,0x14,0x1C,0x1C,0x14,0x1A,0x1C,0x14,0x18,0x1C,0x14,0x16,0x1C,
0x00,0x00,0x10,0x04,0x00,0x10,0x08,0x00,0x10,0x0C,0x00,0x10,0x10,0x00,0x10,0x10,
0x00,0x0C,0x10,0x00,0x08,0x10,0x00,0x04,0x10,0x00,0x00,0x10,0x04,0x00,0x10,0x08,
0x00,0x10,0x0C,0x00,0x10,0x10,0x00,0x0C,0x10,0x00,0x08,0x10,0x00,0x04,0x10,0x00,
0x00,0x10,0x00,0x00,0x10,0x04,0x00,0x10,0x08,0x00,0x10,0x0C,0x00,0x10,0x10,0x00,
0x0C,0x10,0x00,0x08,0x10,0x00,0x04,0x10,0x08,0x08,0x10,0x0A,0x08,0x10,0x0C,0x08,
0x10,0x0E,0x08,0x10,0x10,0x08,0x10,0x10,0x08,0x0E,0x10,0x08,0x0C,0x10,0x08,0x0A,
0x10,0x08,0x08,0x10,0x0A,0x08,0x10,0x0C,0x08,0x10,0x0E,0x08,0x10,0x10,0x08,0x0E,
0x10,0x08,0x0C,0x10,0x08,0x0A,0x10,0x08,0x08,0x10,0x08,0x08,0x10,0x0A,0x08,0x10,
0x0C,0x08,0x10,0x0E,0x08,0x10,0x10,0x08,0x0E,0x10,0x08,0x0C,0x10,0x08,0x0A,0x10,
0x0B,0x0B,0x10,0x0C,0x0B,0x10,0x0D,0x0B,0x10,0x0F,0x0B,0x10,0x10,0x0B,0x10,0x10,
0x0B,0x0F,0x10,0x0B,0x0D,0x10,0x0B,0x0C,0x10,0x0B,0x0B,0x10,0x0C,0x0B,0x10,0x0D,
0x0B,0x10,0x0F,0x0B,0x10,0x10,0x0B,0x0F,0x10,0x0B,0x0D,0x10,0x0B,0x0C,0x10,0x0B,
0x0B,0x10,0x0B,0x0B,0x10,0x0C,0x0B,0x10,0x0D,0x0B,0x10,0x0F,0x0B,0x10,0x10,0x0B,
0x0F,0x10,0x0B,0x0D,0x10,0x0B,0x0C,0x10,0x03,0x00,0x0F,0x02,0x00,0x0C,0x02,0x00,
0x09,0x01,0x00,0x07,0x01,0x00,0x04,0x00,0x00,0x02,0x00,0x00,0x00,0x3F,0x3F,0x3F};

void Memcpy(uchar *d, uchar *s, int size)
{
 while (size--)
   *(d++)=*(s++);
}

void VGADumpRegs(uchar *regs, uchar *Sregs);

/*
 Todo: enhance the memcpy
*/
void SetVideoModeH(VideoModeStr *modeInfo, int width, int bpp)
{
 Memcpy(WorkingVGARegs,DefaultVGARegs,VGARegsCant);
 Memcpy(WorkingSVGARegs,CapturedSVGARegs,VGARegsCant);
 SetForVGAMode(modeInfo,width,WorkingVGARegs,WorkingSVGARegs);
 /* Testing functions to compare registers
 VGADumpRegs(WorkingVGARegs,WorkingSVGARegs);*/
 VGALoadRegs(WorkingVGARegs,WorkingSVGARegs);
 /* Testing functions to compare registers
 VGASaveRegs(WorkingVGARegs,WorkingSVGARegs);
 VGADumpRegs(WorkingVGARegs,WorkingSVGARegs);*/
}


extern unsigned *TextModeMemory;

void SetTextModeVGA(void)
{
 int i,j;
 unsigned *p=(unsigned *)(&VGA8x16Font[0]);

 /* Testing functions to compare registers
 VGADumpRegs(TextModeVGARegs,CapturedSVGARegs);*/

 /* Set all the registers for the text mode */
 VGALoadRegs(TextModeVGARegs,CapturedSVGARegs);

 /******** Restore the fonts. It wasn't that easy to make, I had big
	   troubles to find how exactly the fonts are stored *******/
 /* Planar mode */
 WriteSEQ(4,6);
 /* Plane 2 */
 WriteSEQ(2,4);
 /* Linear inside the plane */
 WriteGRA(5,0);

 for (i=0,j=0; i<1024; i+=4, j+=8)
    {
     TextModeMemory[j+0]=p[i+0];
     TextModeMemory[j+1]=p[i+1];
     TextModeMemory[j+2]=p[i+2];
     TextModeMemory[j+3]=p[i+3];
     TextModeMemory[j+4]=0;
     TextModeMemory[j+5]=0;
     TextModeMemory[j+6]=0;
     TextModeMemory[j+7]=0;
    }

 /* A0 selects the bank (odd/even) */
 WriteSEQ(4,2);
 /* Plane 0-1 */
 WriteSEQ(2,3);
 /* Interlaced in the plane */
 WriteGRA(5,0x10);
 /************ End of font stuff ***********/

 /* Clear the screen (Attribute 7 and spaces) */
 for (i=0; i<1000; i++)
     TextModeMemory[i]=0x07200720;

 /* Restore the text mode palette (Is different to the one used for
    graphics!!), if you use the one used in graphics mode some programs
    look like a girl's bedroom (lot of pinks and violets ;-) */
 RPF_SetPalRange(DefaultTXTPalette,0,256);

 /* Testing functions to compare registers
 VGASaveRegs(WorkingVGARegs,WorkingSVGARegs);
 VGADumpRegs(WorkingVGARegs,WorkingSVGARegs);*/
}

/*****************************************************************************

  Just for testing.

*****************************************************************************/


#if 0
void VGADumpRegs(uchar *regs, uchar *Sregs);

void Set640x480x8bpp(void)
{
 int i;
 Memcpy(WorkingVGARegs,DefaultVGARegs,VGARegsCant);
 Memcpy(WorkingSVGARegs,CapturedSVGARegs,VGARegsCant);
 //SetForVGAMode(&g576x432x8,1024,WorkingVGARegs,WorkingSVGARegs);
 SetForVGAMode(&g640x480x8,1024,WorkingVGARegs,WorkingSVGARegs);
 //SetForVGAMode(&g800x600x8,1024,WorkingVGARegs,WorkingSVGARegs);
 //SetForVGAMode(&g1024x768x8,1024,WorkingVGARegs,WorkingSVGARegs);
 //SetForVGAMode(&g320x240x8,1024,WorkingVGARegs,WorkingSVGARegs);
 //SetForVGAMode(&g400x300x8,1024,WorkingVGARegs,WorkingSVGARegs);
 //SetForVGAMode(&g1152x900x8,1024,WorkingVGARegs,WorkingSVGARegs);
 VGALoadRegs(WorkingVGARegs,WorkingSVGARegs);
 //VGASaveRegs(WorkingVGARegs,WorkingSVGARegs);
 //VGADumpRegs(WorkingVGARegs,WorkingSVGARegs);
 RPF_SetPalRange(DefaultVGAPalette,0,256);
 for (i=0; i<122880; i++)
     Screenl[i]=0;
}
#endif
