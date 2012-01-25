/* Copyright 1998 (c) by Salvador Eduardo Tropea
   This code is part of the FreeBE/AF project you can use it under the
terms and conditions of the FreeBE/AF project. */
/*
  E-mail: salvador@inti.gov.ar, set-soft@usa.net, set@computer.org
*/
/* Note: Currently it means: you can use it for any purpose. But if the
   project changes it could change so check the FreeBE/AF readmes.
   Additionally: if anybody uses part of this code please let me know to add
it to my curriculum. */
/*****************************************************************************

Implemented:

SetMix, Set8x8MonoPattern, Set8x8ColorPattern, Use8x8ColorPattern
DrawLine, SetLineStipple, SetLineStippleCount, DrawStippleLine
DrawRect, DrawScan, DrawPattRect, DrawPattScan, DrawColorPattRect
DrawColorPattScan
BitBlt, SrcTransBlt
SetCursor, SetCursorPos, SetCursorColor (*), ShowCursor
SetBank, SetBank32, SetPaletteData, GetDisplayStartStatus (*2)
SetDisplayStart, SetActiveBuffer, SetVisibleBuffer
GetVideoModeInfo, SetVideoMode, WaitTillIdle, SetupDriver, InitDriver
RestoreTextMode, EnableDirectAccess, DisableDirectAccess,
GetClosestPixelClock
BitBltSys, SrcTransBltSys, PutMonoImage
DrawScanList, DrawPattScanList, DrawColorPattScanList
DrawTrap (*3)

From Inertia: (Old functions conditionally included because seems they won't
be used)

GetConfigInfo,GetCurrentMode,SetVSyncWidth,GetVSyncWidth,GetBank,
GetVisibleBuffer,GetDisplayStart,SetDisplayStartAddr,IsVSync,WaitVSync,
GetActiveBuffer,IsIdle

(*) See implementation notes
(*2) Dummy because looks like TGUI doesn't set the interrupt flag.
(*3) Implemented using scans because isn't supported by the hard.

The following are not supported by 9440:

Implementation notes:

* TGUI9440 doesn't support acelerations in 24 bpp, I must check if the
cursor works.
* TGUI9440 doesn't support Background Mix, as I think the only routine that
needs it is DrawPattRect (and your equivalent Scan) I did a trick:
a) When fore and back mix are the same (most of the time) I ignore back mix.
b) When back mix is "No Operation" (Destination) I use a transparent mode.
c) When both are important I use 2 steps, first makes a transparent blit
with the fore mix, and the second uses an inverted patterned and is done
using the back mix as fore mix.
I hope that is better than soft fills.
* The cursor uses color index 0 for the main color and color index 0xFF for
the xor area. I think it could be very annoying in 8bpp modes perhaps I must
disable the cursor on these modes.
* Supported video modes:
	  8 bpp  15 bpp  16 bpp  24 bpp
 320x200   *       *       *       *
 320x240   *       *       *       *
 400x300   *       *       *       *
 512x384   *       *       *       *
 576x432   *       *       *       *
 640x400   *       *       *       *
 640x480   *       *       *       *
 720x540   *       *       *       *
 800x600   *       *       *       *
 900x675   *       *       *       *
1024x768   *       *       *      (1)

(1) Needs more than 2Mb so is impossible with 9440

*****************************************************************************/

/* Define it if you don't want to call WaitTillIdle, I doubt somebody could
   really want it */
//#define WAITTILLIDLE_NOT_NEEDED

#include <pc.h>
#include "mytypes.h"
#include "vga.h"
#include "vbeaf.h"
#include "tgui.h"
#include "setmode.h"
#define VBE_AF_INCLUDED

#define NULL 0

#define TEST_MODE_INTERNAL
//#define X11Cursor

#ifdef __cplusplus
extern "C" {
#endif
void SetBank32();
void SetBank32End();
#ifdef __cplusplus
}
#endif

void WaitTillIdle(AF_DRIVER *af);

uchar ROPEquiv[32]={
ROP_P,   /* 0x00: AF_REPLACE_MIX => Source */
ROP_PaD, /* 0x01: AF_AND_MIX  => And */
ROP_PoD, /* 0x02: AF_OR_MIX   => Or */
ROP_PxD, /* 0x03: AF_XOR_MIX  => XOr */
ROP_D,   /* 0x04: AF_NOP_MIX  => Destination */
ROP_D,ROP_D,ROP_D,ROP_D,ROP_D,ROP_D,ROP_D,ROP_D,ROP_D,ROP_D,ROP_D,
/* Pattern operation as defined by Windows
   Note: Pat is pen (color) for line drawing */
ROP_0,     /* 0x10: AF_R2_BLACK       => 0 */
ROP_n_PoD, /* 0x11: AF_R2_NOTMERGESRC => NOr Pat */
ROP_nPaD,  /* 0x12: AF_R2_MASKNOTSRC  => !Pat & Dest */
ROP_nP,    /* 0x13: AF_R2_NOTCOPYSRC  => !Pat */
ROP_PanD,  /* 0x14: AF_R2_MASKSRCNOT  => Pat & !Dest */
ROP_nD,    /* 0x15: AF_R2_NOT         => !Dest */
ROP_PxD,   /* 0x16: AF_R2_XORSRC      => XOr Pat*/
ROP_n_PaD, /* 0x17: AF_R2_NOTMASKSRC  => NAnd Pat */
ROP_PaD,   /* 0x18: AF_R2_MASKSRC     => And Pat */
ROP_n_PxD, /* 0x19: AF_R2_NOTXORSRC   => XNOr Pat */
ROP_D,     /* 0x1A: AF_R2_NOP         => Dest */
ROP_nPoD,  /* 0x1B: AF_R2_MERGENOTSRC => !Pat | Dest */
ROP_P,     /* 0x1C: AF_R2_COPYSRC     => Pat */
ROP_PonD,  /* 0x1D: AF_R2_MERGESRCNOT => Pat | !Dest */
ROP_PoD,   /* 0x1E: AF_R2_MERGESRC    => Or Pat */
ROP_1      /* 0x1F: AF_R2_WHITE       => 1 */
};

uchar ROPImageEquiv[32]={
ROP_S,   /* 0x00: AF_REPLACE_MIX => Source */
ROP_SaD, /* 0x01: AF_AND_MIX  => And */
ROP_SoD, /* 0x02: AF_OR_MIX   => Or */
ROP_SxD, /* 0x03: AF_XOR_MIX  => XOr */
ROP_D,   /* 0x04: AF_NOP_MIX  => Destination */
ROP_D,ROP_D,ROP_D,ROP_D,ROP_D,ROP_D,ROP_D,ROP_D,ROP_D,ROP_D,ROP_D,
ROP_0,     /* 0x10: AF_R2_BLACK       => 0 */
ROP_n_SoD, /* 0x11: AF_R2_NOTMERGESRC => NOr Image */
ROP_nSaD,  /* 0x12: AF_R2_MASKNOTSRC  => !Image & Dest */
ROP_nS,    /* 0x13: AF_R2_NOTCOPYSRC  => !Image */
ROP_SanD,  /* 0x14: AF_R2_MASKSRCNOT  => Image & !Dest */
ROP_nS,    /* 0x15: AF_R2_NOT         => !Dest */
ROP_SxD,   /* 0x16: AF_R2_XORSRC      => XOr Image*/
ROP_n_SaD, /* 0x17: AF_R2_NOTMASKSRC  => NAnd Image */
ROP_SaD,   /* 0x18: AF_R2_MASKSRC     => And Image */
ROP_n_SxD, /* 0x19: AF_R2_NOTXORSRC   => XNOr Image */
ROP_D,     /* 0x1A: AF_R2_NOP         => Dest */
ROP_nSoD,  /* 0x1B: AF_R2_MERGENOTSRC => !Image | Dest */
ROP_S,     /* 0x1C: AF_R2_COPYSRC     => Image */
ROP_SonD,  /* 0x1D: AF_R2_MERGESRCNOT => Image | !Dest */
ROP_SoD,   /* 0x1E: AF_R2_MERGESRC    => Or Image */
ROP_1      /* 0x1F: AF_R2_WHITE       => 1 */
};

ushort PortsTable[]={
/* VGA registers */
 0x3C0,0x3C1,0x3C2,0x3C3,0x3C4,0x3C5,0x3C6,0x3C7,0x3C8,0x3C9,0x3CC,0x3CE,
 0x3CF,0x3D4,0x3D5,0x3DA,
 /* TGUI registers */
 0x3D8,0x3D9,0x3DB,0x43C6,0x43C7,0x43C8,0x43C9,0x83C6,0x83C8,
 #ifdef IOMAPPED
 0x2120,0x2121,0x2122,0x2123,0x2124,0x2125,0x2126,0x2127,
 0x2128,0x2129,0x212A,0x212B,0x212C,0x212D,0x212E,0x212F,
 0x2130,0x2131,0x2132,0x2133,0x2134,0x2135,0x2136,0x2137,
 0x2138,0x2139,0x213A,0x213B,0x213C,0x213D,0x213E,0x213F,
 0x2140,0x2141,0x2142,0x2143,0x2144,0x2145,0x2146,0x2147,
 #endif
 0xFFFF
};

static char tBytesPerPixel[]={1,2,2,3};
static char tBitsPerPixel[]={8,15,16,24};

/* Variables to handle the Fore/Back Mixing */
uchar    UsesBackMix=0;
uchar    DontMakeBackMix=0;
uchar    BackMix=ROP_P;
uchar    LineForegroundMix=ROP_P;
uchar    LineForegroundMixToS=ROP_S;
uchar    CurrentForegroundMix=ROP_P;
uchar    HaveDoubleScan=0;
uchar    IsAceleratorOn=0;

unsigned MMIOBASE;
unsigned long linearAddress;
unsigned long bankedAddress;
unsigned AvailableRAM;
unsigned CursorPat;
unsigned pCursorPat;
unsigned ColorPatterns[8];
unsigned pColorPatterns[8];
unsigned MonoPattern,InvMonoPattern;
unsigned pMonoPattern,pInvMonoPattern;
unsigned SelectedColorPattern;
unsigned *TextModeMemory;
int afCurrentMode=0;
int afCurrentBank=0;

unsigned af_y=0;
unsigned af_color_pattern=0;
unsigned af_bpp;
unsigned af_bytespp;
unsigned af_visible_page=0;
unsigned af_active_page=0;
unsigned af_height=480;
unsigned af_width_bytes=1024;
unsigned af_scroll_x;
unsigned af_scroll_y;

/* ToDo: perhaps optimize it */
static inline
void Memcpy(uchar *d, uchar *s, int size)
{
 while (size--)
   *(d++)=*(s++);
}

/*#define BASE_PSEUDO_DMA linearAddress*/
/* Ivan's motherboard have a VERY slow access to the LFB so blits are slower
   if we blit to the LFB */
#define BASE_PSEUDO_DMA bankedAddress

/**[txh]********************************************************************

  Description:
  This function tests the video memory. I use 256Kb steps because I think
less than it is impossible. In fact I think all the 9440 boards have 1Mb
or 2Mb of memory. Some time ago I tried to install 1.5Mb in one board and
the BIOS reported just 1Mb. I also tried removing 0.5Mb and the BIOS
detected it OK. I think Trident's BIOS detects 256, 512, 1024 and 2048.
  The first time I tested this function writing outside the memory didn't
write, but when I tested it in my machine it made a write at the 0 position.
The stranger thing is that it doesn't happend with unoptimized code.
  Oh! if you wander about why such a complex test, beleive me if you don't
check all you could detect any crazy value.

***************************************************************************/
#define M256K (1<<18)
#define M512K (1<<19)
#define M2M   (1<<21)

#if 1
int TestMemory()
{
 /* Brut force: Try read/write to the linear space ;-) */
 int size=1<<18;
 volatile uchar *p=((uchar *)linearAddress);
 uchar temp;
 uchar temp0,temp1,temp2;
 int seq04,crt1e;

 /* Put the chip in a mode where we can address the whole memory */
 seq04=ReadSEQ(4);
 crt1e=ReadCRT(0x1E);
 if ((seq04 & 8)==0)
    WriteSEQ(4,seq04 | 8); /* Chain 4 */
 if ((crt1e & 0x80)==0)
    WriteCRT(0x1E,crt1e | 0x80); /* Enable b16 start address */

 temp0=*p; temp1=p[M256K]; temp2=p[M512K];
 *p=0xF0;  p[M256K]=0xF0;  p[M512K]=0xF0;
 if (*p!=0xF0)
    size=0;
 else
   {
    do
      {
       temp=p[size];
       p[size]=0xAA;
       p[4]=0;
       if (p[size]!=0xAA || *p!=0xF0)
	  break;
       if (size>M256K)
	 {
	  if (p[M256K]!=0xF0)
	     break;
	  if (size>M512K && p[M512K]!=0xF0)
	     break;
	 }
       p[size]=0x55;
       p[4]=0;
       if (p[size]!=0x55 || *p!=0xF0)
	  break;
       if (size>M256K)
	 {
	  if (p[M256K]!=0xF0)
	     break;
	  if (size>M512K && p[M512K]!=0xF0)
	     break;
	 }
       p[size]=temp;
       size+=M256K;
      }
    while (size<M2M);
   }
 *p=temp0; p[M256K]=temp1;  p[M512K]=temp2;
 if ((seq04 & 8)==0)
    WriteSEQ(4,seq04);
 if ((crt1e & 0x80)==0)
    WriteCRT(0x1E,crt1e);
 return size;
}
#else
int TestMemory()
{
 int size=0, temp;
 /* The following is completly undocumented by Trident. Seems that the video
    board's BIOS tests the memory during start up and stores the result here,
    isn't detected by the chip. Formally the register is called Software
    Programming and is reserved */
 temp=ReadCRT(0x1F);

 switch (temp & 7)
   {
    case 0: 
    case 4:
	 AvailableRAM=256*1024;
	 break;
    case 1: 
    case 5:
	 AvailableRAM=512*1024;
	 break;
    case 2:
    case 6:
	 AvailableRAM=768*1024;
	 break;
    case 3:
	 AvailableRAM=1024*1024;
	 break;
    case 7:
	 AvailableRAM=2048*1024;
	 break;
   }
 return size;
}
#endif

#if 0
// Was used during test. ToDo: remove it in the release
void Initialization(void)
{
 int i;

 /* Find the amount of installed memory */
 AvailableRAM=TestMemory();
 AvailableRAM=1024*1024;
 /* Reserve 2Kb of memory for patterns and harware cursor */
 /* Monochromatic pattern */
 /* I use 128 bytes aligment because in 16bpp that required */
 AvailableRAM-=128;
 pMonoPattern=linearAddress+AvailableRAM;
 MonoPattern=AvailableRAM>>6;
 AvailableRAM-=128;
 pInvMonoPattern=linearAddress+AvailableRAM;
 InvMonoPattern=AvailableRAM>>6;
 /* Hardware Cursor */
 /* 32x32 (size) * 2 (planes) / 8 (packed) = 256 but 1K aligned */
 AvailableRAM-=256+512;
 pCursorPat=linearAddress+AvailableRAM;
 CursorPat=AvailableRAM>>10;
 /* 8 patterns of 8x8x2 bytes */
 for (i=0; i<8; i++)
    {
     AvailableRAM-=128;
     pColorPatterns[i]=linearAddress+AvailableRAM;
     ColorPatterns[i]=AvailableRAM>>6;
    }
 SelectedColorPattern=ColorPatterns[0];
}
#endif

/**[txh]********************************************************************

  Description:
  Downloads a monochrome (packed bit) pattern, for use by the DrawPattScan()
and DrawPattRect() functions. This is always sized 8x8, and aligned with the
top left corner of video memory: if other alignments are desired, the pattern
will be prerotated before it is passed to this routine. @x{DrawPattScan}.
@x{DrawPattRect}.

***************************************************************************/

void Set8x8MonoPattern(AF_DRIVER *af, unsigned char *pattern)
{
 #ifndef WAITTILLIDLE_NOT_NEEDED
 WaitGE();
 #endif
 *((unsigned long *)pMonoPattern)        = *((unsigned long *)pattern);
 *((unsigned long *)pInvMonoPattern)     = ~(*((unsigned long *)pattern));
 *((unsigned long *)(pMonoPattern+4))    = *((unsigned long *)&pattern[4]);
 *((unsigned long *)(pInvMonoPattern+4)) = ~(*((unsigned long *)&pattern[4]));
}


/**[txh]********************************************************************

  Description:
  Downloads a color pattern, for use by the DrawColorPattScan() and
DrawColorPattRect() functions. This is always sized 8x8, and aligned with
the top left corner of video memory: if other alignments are desired, the
pattern will be prerotated before it is passed to this routine. The color
values are presented in the native format for the current video mode, but
padded to 32 bits (so the pattern is always an 8x8 array of longs).
@x{DrawColorPattScan}. @x{DrawColorPattRect}.

// ToDo: Make 2 versions

***************************************************************************/

void Set8x8ColorPattern(AF_DRIVER *af, int index, unsigned long *pattern)
{
 int i;
 index&=0x7;
 if (af_bpp==8)
   {
    #ifndef WAITTILLIDLE_NOT_NEEDED
    WaitGE();
    #endif
    for (i=0; i<64; i++)
	*(((uchar *)pColorPatterns[index])+i)=pattern[i];
   }
 else
   {
    #ifndef WAITTILLIDLE_NOT_NEEDED
    WaitGE();
    #endif
    for (i=0; i<64; i++)
	*(((ushort *)pColorPatterns[index])+i)=pattern[i];
   }
}


/**[txh]********************************************************************

  Description:
  Selects one of the patterns previously downloaded by Set8x8ColorPattern().
@x{Set8x8ColorPattern}.

***************************************************************************/

void Use8x8ColorPattern(AF_DRIVER *af, int index)
{
 SelectedColorPattern=ColorPatterns[index & 0x7];
}


/*****************************************************************************

  The TGUI9440 chip supports only Besenham lines, I think they are VERY easy
to implement in chips and that's the reason because old chips use it.
  These lines works with parameters for one octant, the one defined by:

  delta X > delta Y > 0

  To create any line the chip provides 3 bits that selects the octant.

*****************************************************************************/

void DrawLine(AF_DRIVER *af, unsigned long color, fixed x1, fixed y1, fixed x2, fixed y2)
{
 int dX,dY,dir=SolidDrawing | PatFromDisplay | SourceDataDisplay;

 /* round coordinates from fixed point to integer */
 x1=(x1+0x8000)>>16;
 y1=((y1+0x8000)>>16)+af_y;
 x2=(x2+0x8000)>>16;
 y2=((y2+0x8000)>>16)+af_y;

 /* Check if dY is positive */
 if (y1>y2)
   { /* No then reverse Y direction */
    dir|=YDecreasing;
    dY=y1-y2;
   }
 else
    dY=y2-y1;

 /* Check if dX is positive */
 if (x1>x2)
   { /* No then reverse Y direction */
    dir|=XDecreasing;
    dX=x1-x2;
   }
 else
    dX=x2-x1;

 /* Check for dX>dY */
 if (dY>dX)
   { /* No then swap */
    int temp=dX;
    dX=dY;
    dY=temp;
    dir|=YMajor;
   }

 WaitGEfifo();
 if (CurrentForegroundMix!=LineForegroundMix)
   {
    SetForegroundMix(LineForegroundMix);
    CurrentForegroundMix=LineForegroundMix;
   }
 SetForeground(color);

 /* Now dX > dY > 0 and all the flags for the octant are calculated */
 SetXYLocation(x1,y1);
 SetLineSteps(dY,dX);
 SetErrAndLen(dY,dX);
 SetDrawFlags(dir);
 DoBresenhamLine();
}


/**[txh]********************************************************************

  Description:
  Sets the mask used for stipple lines. @x{DrawStippleLine}.@p
  I'm not sure about it so here is my guess: TGUI9440 have a 16 bits
register (GER44,GER45) to set the mask used for patterned lines so I guess
that's this function is to setup this value.@p

***************************************************************************/

void SetLineStipple(AF_DRIVER *af, unsigned short stipple)
{
 WaitGEfifo();
 SetPenStyleMask(stipple);
}


/**[txh]********************************************************************

  Description:
  Sets the repeat counter for the mask used in stipple lines.
@x{DrawStippleLine}.@p
  I'm not sure about it so here is my guess: TGUI9440 have an 8 bits
register (GER47) to set the scale of the pattern for patterned lines. A value
of 0 means that each bit in the pattern is 1 dot, a value of 1 expands
each pixel to 2 dots and so on.@p

***************************************************************************/

void SetLineStippleCount(AF_DRIVER *af, unsigned long count)
{
 WaitGEfifo();
 SetStyleMaskRepeatCount(count);
}


/**[txh]********************************************************************

  Description:
  Draws a stipple line (patterned, dotted). SetLineStipple sets the pattern
used and SetLineStippleCount the scale. @x{SetLineStipple}.
@x{SetLineStippleCount}.@p
  Note: This function doesn't call drawline, it is almost the same code
repeated. That's to increase speed because in this way I can make the
Bresenham parameters calculation in parallel with the GE.

***************************************************************************/

void DrawStippleLine(AF_DRIVER *af, unsigned long foreColor,
		     unsigned long backColor, fixed x1, fixed y1,
		     fixed x2, fixed y2)
{
 int dX,dY,dir=PatternedLines | PatFromDisplay | SourceDataDisplay;

 /* round coordinates from fixed point to integer */
 x1=(x1+0x8000)>>16;
 y1=((y1+0x8000)>>16)+af_y;
 x2=(x2+0x8000)>>16;
 y2=((y2+0x8000)>>16)+af_y;

 /* Check if dY is positive */
 if (y1>y2)
   { /* No then reverse Y direction */
    dir|=YDecreasing;
    dY=y1-y2;
   }
 else
    dY=y2-y1;

 /* Check if dX is positive */
 if (x1>x2)
   { /* No then reverse Y direction */
    dir|=XDecreasing;
    dX=x1-x2;
   }
 else
    dX=x2-x1;

 /* Check for dX>dY */
 if (dY>dX)
   { /* No then swap */
    int temp=dX;
    dX=dY;
    dY=temp;
    dir|=YMajor;
   }

 WaitGEfifo();
 if (CurrentForegroundMix!=LineForegroundMix)
   {
    SetForegroundMix(LineForegroundMix);
    CurrentForegroundMix=LineForegroundMix;
   }
 SetForeground(foreColor);
 SetBackground(backColor);

 /* Now dX > dY > 0 and all the flags for the octant are calculated */
 SetXYLocation(x1,y1);
 SetLineSteps(dY,dX);
 SetErrAndLen(dY,dX);
 SetDrawFlags(dir);
 DoBresenhamLine();
}

void SetMix(AF_DRIVER *af, long foreMix, long backMix)
{
 uchar af_fore_mix=0;
 uchar af_back_mix=0;

 /* Limit the values to my range */
 af_fore_mix=foreMix & 0x1F;

 if (backMix==0)
    af_back_mix=af_fore_mix;
 else
    af_back_mix=backMix & 0x1F;

 /* Foreground mix used by lines and pattern fills */
 LineForegroundMix=ROPEquiv[af_fore_mix];
 LineForegroundMixToS=ROPImageEquiv[af_fore_mix];
 /* 9440 doesn't have Background mixing but I make it in 2 steps */
 UsesBackMix=(af_back_mix!=af_fore_mix);
 BackMix=ROPEquiv[af_back_mix];
 DontMakeBackMix=(BackMix==ROP_D);
}


/**[txh]********************************************************************

  Description:
  Fills a rectangle in the current foreground mix mode.

***************************************************************************/

void DrawRect(AF_DRIVER *af, unsigned long color, long left, long top, long width, long height)
{
 WaitGEfifo();
 if (CurrentForegroundMix!=LineForegroundMix)
   {
    SetForegroundMix(LineForegroundMix);
    CurrentForegroundMix=LineForegroundMix;
   }
 SetForeground(color);
 SetDrawFlags(SolidDrawing | PatMono);
 SetXYLocation(left,top+af_y);
 SetDimensions(width-1,height-1);
 DoBlit();
}

#ifdef __cplusplus
extern "C" void DrawRawRect(unsigned long color, long left, long top, long width, long height);
#endif
// Internally used to clean the screen
void DrawRawRect(unsigned long color, long left, long top, long width, long height)
{
 WaitGEfifo();
 if (CurrentForegroundMix!=LineForegroundMix)
   {
    SetForegroundMix(LineForegroundMix);
    CurrentForegroundMix=LineForegroundMix;
   }
 SetForeground(color);
 SetDrawFlags(SolidDrawing | PatMono);
 SetXYLocation(left,top+af_y);
 SetDimensions(width,height);
 DoBlitDontWait();
}


/**[txh]********************************************************************

  Description:
 Fills a scanline in the current foreground mix mode. Draws up to but
not including the second x coordinate. If the second coord is less than the
first, they are swapped. If they are equal, nothing is drawn.

***************************************************************************/

void DrawScan(AF_DRIVER *af, long color, long y, long x1, long x2)
{
 unsigned mode=SolidDrawing | PatMono;
 int w;

 if (x1<x2)
    w=x2-x1;
 else
   {
    if (x2<x1)
      {
       w=x1-x2;
       mode|=XDecreasing;
       x1--;
       /* In this case x1 is the second coordinate and the VBE/AF 1.0 says
	  that we must draw [1st,2nd) */
      }
    else
       return;
   }

 WaitGEfifo();
 if (CurrentForegroundMix!=LineForegroundMix)
   {
    SetForegroundMix(LineForegroundMix);
    CurrentForegroundMix=LineForegroundMix;
   }
 SetForeground(color);
 SetDrawFlags(mode);
 SetXYLocation(x1,y+af_y);
 SetWidth_1(w);
 DoScan();
}


void DrawScanList(AF_DRIVER *af, unsigned long color, long y, long length,
		  short *scans)
{
 unsigned mode;
 int w,i;
 int x1,x2;

 WaitGEfifo();
 if (CurrentForegroundMix!=LineForegroundMix)
   {
    SetForegroundMix(LineForegroundMix);
    CurrentForegroundMix=LineForegroundMix;
   }
 SetForeground(color);
 SetYLocation(y+af_y);

 for (i=0; i<length; i++)
    {
     x1=scans[i*2];
     x2=scans[i*2+1];

     if (x1<x2)
       {
	w=x2-x1;
	mode=SolidDrawing | PatMono;
       }
     else
       {
	if (x2<x1)
	  {
	   w=x1-x2;
	   mode=SolidDrawing | PatMono | XDecreasing;
	   x1--;
	  }
	else
	   continue;
       }

     WaitGEfifo();
     SetDrawFlags(mode);
     SetXLocation(x1);
     SetWidth_1(w);
     DoScan();
    }
}


/**[txh]********************************************************************

  Description:
 Fills a rectangle using the current mono pattern. Set pattern bits are
drawn using the specified foreground color and the foreground mix mode, and
clear bits use the background color and background mix mode.

***************************************************************************/

void DrawPattRect(AF_DRIVER *af, unsigned long foreColor, unsigned long backColor, long left, long top, long width, long height)
{
 if (UsesBackMix)
   {
    /* First pass we use the FMIX and the normal pattern */
    WaitGEfifo();
    SetPatternLocation(MonoPattern);
    SetForegroundMix(LineForegroundMix);

    SetForeground(foreColor);
    SetBackground(0);
    SetDrawFlags(PatternedDrawing | PatMono | PatFromDisplay | SourceDataDisplay | TransparentEnable);
    SetXYLocation(left,top+af_y);
    SetDimensions(width-1,height-1);
    DoBlitDontWait();

    /* If the back mix is No Operation just skip it */
    if (DontMakeBackMix)
      {
       CurrentForegroundMix=LineForegroundMix;
       return;
      }

    /* Second pass we use the reverse pattern and the background as a
       foreground */
    WaitGEfifo();
    SetPatternLocation(InvMonoPattern);
    SetForegroundMix(BackMix);
    CurrentForegroundMix=BackMix;

    SetForeground(backColor);
    DoBlit();
    return;
   }
 /* That's supported */
 WaitGEfifo();
 SetForeground(foreColor);
 SetBackground(backColor);
 if (CurrentForegroundMix!=LineForegroundMix)
   {
    SetForegroundMix(LineForegroundMix);
    CurrentForegroundMix=LineForegroundMix;
   }
 SetPatternLocation(MonoPattern);
 SetDrawFlags(PatternedDrawing | PatMono | PatFromDisplay | SourceDataDisplay);
 SetXYLocation(left,top+af_y);
 SetDimensions(width-1,height-1);
 DoBlit();
}


/**[txh]********************************************************************

  Description:
 Fills a scanline using the current mono pattern. Set pattern bits are
drawn using the specified foreground color and the foreground mix mode, and
clear bits use the background color and background mix mode.

***************************************************************************/

void DrawPattScan(AF_DRIVER *af, long foreColor, long backColor, long y, long x1, long x2)
{
 unsigned mode=PatternedDrawing | PatMono | PatFromDisplay | SourceDataDisplay;
 int w;

 if (UsesBackMix)
   {
    if (x1<x2)
       /*af->?*/DrawPattRect(af,foreColor,backColor,x1,y,x2-x1,1);
    else if (x2 < x1)
       DrawPattRect(af,foreColor,backColor,x2,y,x1-x2,1);
    return;
   }

 if (x1<x2)
    w=x2-x1;
 else
   {
    if (x2<x1)
      {
       w=x1-x2;
       mode|=XDecreasing;
       x1--;
      }
    else
       return;
   }

 WaitGEfifo();
 SetForeground(foreColor);
 SetBackground(backColor);
 if (CurrentForegroundMix!=LineForegroundMix)
   {
    SetForegroundMix(LineForegroundMix);
    CurrentForegroundMix=LineForegroundMix;
   }
 SetPatternLocation(MonoPattern);
 SetDrawFlags(mode);
 SetXYLocation(x1,y+af_y);
 SetWidth_1(w);
 DoScan();
}

void DrawPattScanList(AF_DRIVER *af, unsigned long foreColor,
		      unsigned long backColor, long y, long length,
		      short *scans)
{
 unsigned mode;
 int w;
 int x1,x2,i;

 if (UsesBackMix)
   {
    for (i=0; i<length; i++)
       {
	x1=scans[i*2];
	x2=scans[i*2+1];
	if (x1<x2)
	   DrawPattRect(af,foreColor,backColor,x1,y,x2-x1,1);
	else if (x2 < x1)
	   DrawPattRect(af,foreColor,backColor,x2,y,x1-x2,1);
       }
    return;
   }

 WaitGEfifo();
 SetForeground(foreColor);
 SetBackground(backColor);
 if (CurrentForegroundMix!=LineForegroundMix)
   {
    SetForegroundMix(LineForegroundMix);
    CurrentForegroundMix=LineForegroundMix;
   }
 SetPatternLocation(MonoPattern);
 SetYLocation(y+af_y);

 for (i=0; i<length; i++)
    {
     x1=scans[i*2];
     x2=scans[i*2+1];

     if (x1<x2)
       {
	w=x2-x1;
	mode=PatternedDrawing | PatMono | PatFromDisplay | SourceDataDisplay;
       }
     else
       {
	if (x2<x1)
	  {
	   w=x1-x2;
	   mode=PatternedDrawing | PatMono | PatFromDisplay |
		SourceDataDisplay | XDecreasing;
	   x1--;
	  }
	else
	   continue;
       }

     WaitGEfifo();
     SetDrawFlags(mode);
     SetXLocation(x1);
     SetWidth_1(w);
     DoScan();
    }
}


/**[txh]********************************************************************

  Description:
  Fills a rectangle using the current color pattern and mix mode.

***************************************************************************/

void DrawColorPattRect(AF_DRIVER *af, long left, long top, long width, long height)
{
 WaitGEfifo();
 if (CurrentForegroundMix!=LineForegroundMix)
   {
    SetForegroundMix(LineForegroundMix);
    CurrentForegroundMix=LineForegroundMix;
   }
 SetPatternLocation(SelectedColorPattern);
 SetDrawFlags(PatternedDrawing | PatFromDisplay | SourceDataDisplay);
 SetXYLocation(left,top+af_y);
 SetDimensions(width-1,height-1);
 DoBlit();
}


/**[txh]********************************************************************

  Description:
  Fills a scanline using the current mono pattern. Set pattern bits are
drawn using the specified foreground color and the foreground mix mode, and
clear bits use the background color and background mix mode.

***************************************************************************/

void DrawColorPattScan(AF_DRIVER *af, long y, long x1, long x2)
{
 unsigned mode=PatternedDrawing | PatFromDisplay | SourceDataDisplay;
 int w;

 if (x1<x2)
    w=x2-x1;
 else
   {
    if (x2<x1)
      {
       w=x1-x2;
       mode|=XDecreasing;
       x1--;
      }
    else
       return;
   }

 WaitGEfifo();
 if (CurrentForegroundMix!=LineForegroundMix)
   {
    SetForegroundMix(LineForegroundMix);
    CurrentForegroundMix=LineForegroundMix;
   }
 SetPatternLocation(SelectedColorPattern);
 SetDrawFlags(mode);
 SetXYLocation(x1,y+af_y);
 SetWidth_1(w);
 DoScan();
}

void DrawColorPattScanList(AF_DRIVER *af, long y, long length, short *scans)
{
 unsigned mode;
 int w,x1,x2,i;

 WaitGEfifo();
 if (CurrentForegroundMix!=LineForegroundMix)
   {
    SetForegroundMix(LineForegroundMix);
    CurrentForegroundMix=LineForegroundMix;
   }
 SetPatternLocation(SelectedColorPattern);
 SetYLocation(y+af_y);

 for (i=0; i<length; i++)
    {
     x1=scans[i*2];
     x2=scans[i*2+1];

     if (x1<x2)
       {
	w=x2-x1;
	mode=PatternedDrawing | PatFromDisplay | SourceDataDisplay;
       }
     else
       {
	if (x2<x1)
	  {
	   w=x1-x2;
	   mode=PatternedDrawing | PatFromDisplay | SourceDataDisplay |
		XDecreasing;
	   x1--;
	  }
	else
	   continue;
       }

     WaitGEfifo();
     SetDrawFlags(mode);
     SetXLocation(x1);
     SetWidth_1(w);
     DoScan();
    }
}


/**[txh]********************************************************************

  Description:
  Blits from one part of video memory to another, using the specified
mix operation. This must correctly handle the case where the two regions
overlap.

***************************************************************************/

void BitBlt(AF_DRIVER *af, long left, long top, long width, long height, long dstLeft, long dstTop, long op)
{
 uchar BlitForegroundMix=ROPImageEquiv[op & 0x1F];
 unsigned direction=PatternedDrawing | SourceDataDisplay;

 /* Check for horizontal overlap */
 if (dstLeft>left && dstLeft<left+width)
   {
    direction|=XDecreasing;
    dstLeft+=width-1;
    left+=width;
   }
 /* Check for vertical overlap */
 if (dstTop>top && dstTop<top+height)
   {
    direction|=YDecreasing;
    dstTop+=height-1;
    top+=height;
   }
 WaitGEfifo();
 if (CurrentForegroundMix!=BlitForegroundMix)
   {
    SetForegroundMix(BlitForegroundMix);
    CurrentForegroundMix=BlitForegroundMix;
   }
 SetDrawFlags(direction);
 SetXYLocation(dstLeft,dstTop+af_y);
 SetXYSource(left,top+af_y);
 SetDimensions(width,height);
 DoBlit();
}


/**[txh]********************************************************************

  Description:
  Blits from one part of video memory to another, using the specified
mix operation and skipping any source pixels which match the specified
transparent color. Results are undefined if the two regions overlap.

***************************************************************************/

void SrcTransBlt(AF_DRIVER *af, long left, long top, long width, long height, long dstLeft, long dstTop, long op, unsigned long transparent)
{
 uchar BlitForegroundMix=ROPImageEquiv[op & 0x1F];
 WaitGEfifo();
 if (CurrentForegroundMix!=BlitForegroundMix)
   {
    SetForegroundMix(BlitForegroundMix);
    CurrentForegroundMix=BlitForegroundMix;
   }
 SetDrawFlags(PatternedDrawing | SourceDataDisplay | TransparentEnable);
 SetBackground(transparent);
 SetXYLocation(dstLeft,dstTop+af_y);
 SetXYSource(left,top+af_y);
 SetDimensions(width,height);
 DoBlit();
}


/**[txh]********************************************************************

  Description:
  Copies from system memory to the screen.

***************************************************************************/

void BitBltSys(AF_DRIVER *af, void *srcAddr, long srcPitch, long srcLeft, long srcTop, long width, long height, long dstLeft, long dstTop, long op)
{
 uchar BlitForegroundMix=ROPImageEquiv[op & 0x1F];
 int n,i;
 unsigned addr;

 /* adjust source bitmap pointers */
 switch (af_bpp)
   {
    case 8:
	 addr=(unsigned)srcAddr+srcLeft+srcTop*srcPitch;
	 n=(width+3)/4;
	 break;

    case 15:
    case 16:
	 addr=(unsigned)srcAddr+srcLeft*2+srcTop*srcPitch;
	 n=(width+1)/2;
	 break;

    default:
	 return;
   }

 WaitGE();
 if (CurrentForegroundMix!=BlitForegroundMix)
   {
    SetForegroundMix(BlitForegroundMix);
    CurrentForegroundMix=BlitForegroundMix;
   }
 SetDrawFlags(PatternedDrawing | PatFromDisplay);
 SetXYLocation(dstLeft,dstTop+af_y);
 /* Source X bits 0-1 are the offset in the double word */
 SetXYSource(0,0);
 SetDimensions(width-1,height-1);

 DoBlit();
 /* copy data to the start of memory */
 for (i=0; i<height; i++)
    {
     asm (
     " rep ; movsl "
       :
       : "c" (n),
	 "S" (addr),
	 "D" (BASE_PSEUDO_DMA)
       : "%ecx", "%esi", "%edi");
     addr+=srcPitch;
    }
}


/**[txh]********************************************************************

  Description:
  Copies from system memory to the screen, skipping any source pixels that
match the specified transparent color.

***************************************************************************/

void SrcTransBltSys(AF_DRIVER *af, void *srcAddr, long srcPitch, long srcLeft, long srcTop, long width, long height, long dstLeft, long dstTop, long op, unsigned long transparent)
{
 uchar BlitForegroundMix=ROPImageEquiv[op & 0x1F];
 int n,i;
 unsigned addr;

 /* adjust source bitmap pointers */
 switch (af_bpp)
   {
    case 8:
	 addr=(unsigned)srcAddr+srcLeft+srcTop*srcPitch;
	 n=(width+3)/4;
	 break;

    case 15:
    case 16:
	 addr=(unsigned)srcAddr+srcLeft*2+srcTop*srcPitch;
	 n=(width+1)/2;
	 break;

    default:
	 return;
   }

 WaitGE();
 if (CurrentForegroundMix!=BlitForegroundMix)
   {
    SetForegroundMix(BlitForegroundMix);
    CurrentForegroundMix=BlitForegroundMix;
   }
 SetDrawFlags(PatternedDrawing | PatFromDisplay | TransparentEnable);
 SetBackground(transparent);
 SetXYLocation(dstLeft,dstTop+af_y);
 /* Source X bits 0-1 are the offset in the double word */
 SetXYSource(0,0);
 SetDimensions(width-1,height-1);

 DoBlit();
 /* copy data to the start of memory */
 for (i=0; i<height; i++)
    {
     asm (
     " rep ; movsl "
       :
       : "c" (n),
	 "S" (addr),
	 "D" (BASE_PSEUDO_DMA)
       : "%ecx", "%esi", "%edi");
     addr+=srcPitch;
    }
}


/**[txh]********************************************************************

  Description:
  Expands a monochrome bitmap from system memory onto the screen.

***************************************************************************/

void PutMonoImage(AF_DRIVER *af, long foreColor, long backColor, long dstX,
		  long dstY, long byteWidth, long srcX, long srcY,
		  long width, long height, unsigned char *image)
{
 int n,off,i,mode;

 /* Move to the byte position in the mono-image */
 image+=srcY*byteWidth+srcX/8;
 /* Calculate how many dwords is a line */
 n=(width+31)/32;
 /* Calculate the offset inside the byte */
 off=(srcX & 7)<<24;

 WaitGE();
 if (CurrentForegroundMix!=LineForegroundMixToS)
   {
    SetForegroundMix(LineForegroundMixToS);
    CurrentForegroundMix=LineForegroundMixToS;
   }
 SetForeground(foreColor);
 mode=PatternedDrawing | SourceDataMono | PatMono | PatFromDisplay |
      SourceDataSystem | off;
 if (UsesBackMix & DontMakeBackMix)
   {
    mode|=TransparentEnable;
    /* For some strange reason (silicon bug?) if we use transparent draw
       with fore=back=0 the result is nothing drawed!!! I spend some time
       before figuring out why the labels in Allegro buttons were invisible */
    SetBackground(1);
   }
 else
   {
    SetBackground(backColor);
   }
 SetDrawFlags(mode);
 SetXYLocation(dstX,dstY+af_y);
 //SetXYSource(0xFF,0);
 SetDimensions(width-1,height-1);
 DoBlit();
 /* copy data to the start of memory */
 for (i=0; i<height; i++)
    {
     asm (
     " rep ; movsl "
       :
       : "c" (n),
	 "S" (image),
	 "D" (BASE_PSEUDO_DMA)
       : "%ecx", "%esi", "%edi");
     image+=byteWidth;
    }
}


/**[txh]********************************************************************

  Description:
  Draws a filled trapezoid, using the current foreground mix mode.@p
  TGUI9440 doesn't have trapezoids, I think it was introduced in 96xx chips.
I implemented it using scan lines, I think that's faster than a software
trapezoid.

***************************************************************************/

void DrawTrap(AF_DRIVER *af, unsigned long color, AF_TRAP *trap)
{
 int ix1,ix2;
 int y;

 WaitGEfifo();
 if (CurrentForegroundMix!=LineForegroundMix)
   {
    SetForegroundMix(LineForegroundMix);
    CurrentForegroundMix=LineForegroundMix;
   }
 SetForeground(color);
 SetDrawFlags(SolidDrawing | PatMono);

 y=trap->y+af_y;
 /* scan-convert the trapezoid */
 while (trap->count--)
   {
    /* Convert X values to ints rounding */
    ix1=(trap->x1+0x8000)>>16;
    ix2=(trap->x2+0x8000)>>16;

    if (ix2<ix1)
      {
       int tmp = ix1;
       ix1 = ix2;
       ix2 = tmp;
      }

    WaitGEfifo();
    SetXYLocation(ix1,y);
    SetWidth(ix2-ix1);
    DoScan();

    trap->x1+=trap->slope1;
    trap->x2+=trap->slope2;
    y++;
   }
 trap->y=y-af_y;
}


unsigned cur_hot_x,cur_hot_y;


/**[txh]********************************************************************

  Description:
  Sets the hardware cursor shape.

// ToDo split it in various

***************************************************************************/

void SetCursor(AF_DRIVER *af, AF_CURSOR *cursor)
{
 int i;
 unsigned long *p=(unsigned long *)pCursorPat;

 #ifndef WAITTILLIDLE_NOT_NEEDED
 if (IsAceleratorOn)
    WaitGE();
 #endif
 if (HaveDoubleScan)
   {
    if (af_bpp==8)
      {
       for (i=0; i<32; i++)
	  {
	   p[i*8+4]=p[i*8+0]=~cursor->andMask[i];
	   p[i*8+5]=p[i*8+1]=cursor->xorMask[i];
	   p[i*8+2]=p[i*8+6]=0xFFFFFFFF;
	   p[i*8+3]=p[i*8+7]=0;
	  }
      }
    else
      {
       for (i=0; i<32; i++)
	  {
	   p[i*8+4]=p[i*8+0]=~cursor->andMask[i];
	   p[i*8+5]=p[i*8+1]=cursor->xorMask[i] ^ cursor->andMask[i];
	   p[i*8+2]=p[i*8+6]=0xFFFFFFFF;
	   p[i*8+3]=p[i*8+7]=0;
	  }
      }
   }
 else
   {
    if (af_bpp==8)
      {
       for (i=0; i<32; i++)
	  {
	   p[i*2]=~cursor->andMask[i];
	   p[i*2+1]=cursor->xorMask[i];
	  }
      }
    else
      {
       for (i=0; i<32; i++)
	  {
	   p[i*2]=~cursor->andMask[i];
	   p[i*2+1]=cursor->xorMask[i] ^ cursor->andMask[i];
	  }
      }
   }
 cur_hot_x=cursor->hotx;
 cur_hot_y=cursor->hoty;
}


/**[txh]********************************************************************

  Description:
  Sets the hardware cursor position.

***************************************************************************/

void SetCursorPos(AF_DRIVER *af, long x, long y)
{
 x-=cur_hot_x;
 y-=cur_hot_y;

 if (HaveDoubleScan)
    y*=2;
 /* Allow small negative coordinates moving inside the cursor, Allegro needs
    it */
 if (y<0)
   {
    WriteCRT(0x47,-y);
    y=0;
   }
 else
   WriteCRT(0x47,0);
 if (x<0)
   {
    WriteCRT(0x46,-x);
    x=0;
   }
 else
   WriteCRT(0x46,0);
 WriteCRT(0x40,x);
 WriteCRT(0x41,x>>8);
 WriteCRT(0x42,y);
 WriteCRT(0x43,y>>8);
}



/**[txh]********************************************************************

  Description:
  Sets the hardware cursor color.@p
  Not supported by TGUI9440, I think 968x adds some registers for it.

***************************************************************************/

void SetCursorColor(AF_DRIVER *af, unsigned char red, unsigned char green,
		    unsigned char blue)
{
 /* I disabled it because it normally mess the things.
 if (af_bpp==8)
   {
    outportb(WriteDataAddress,0);
    outportb(PaletteDataRegister,red/4);
    outportb(PaletteDataRegister,green/4);
    outportb(PaletteDataRegister,blue/4);
   }
 */
}


/**[txh]********************************************************************

  Description:
  Turns the hardware cursor on or off.

***************************************************************************/

void ShowCursor(AF_DRIVER *af, long visible)
{
 unsigned mode=visible ? 0x80 : 0;
 mode|=HaveDoubleScan ? 1 : 0;
 WriteCRT(0x50,mode);
}


/**[txh]********************************************************************

  Description:
  C-callable bank switch function.

***************************************************************************/

void SetBank(AF_DRIVER *af, long bank)
{
 #ifdef INCLUDE_OLD_INERTIA_STUFF
 afCurBank=bank;
 #endif
 /* TGUI supports individual banks for read & write so we must set both */
 outportw(DestinationSegmentAddress,bank | (bank<<8));
}

/* SetBank32:
 *  Relocatable bank switch function. This is called with a bank number in
 *  %edx.
 */

asm ("
.globl _SetBank32, _SetBank32End

   .align 4
_SetBank32:
   pushl %eax
   pushl %edx
   movb %dl, %al
   movb %dl, %ah
   movw $0x03D8, %dx
   outw %ax, %dx
   popl %edx
   popl %eax
   ret

_SetBank32End:
");


/**[txh]********************************************************************

  Description:
  Palette setting routine. Palette values are in 8 bits format because some
boards support 8 bits DAC and not only 6 bits.

***************************************************************************/

void SetPaletteData(AF_DRIVER *af, AF_PALETTE *pal, long num, long index, long waitVRT)
{
 int i;

 if (waitVRT)
    WaitVRT();

 outportb(WriteDataAddress,index);
 for (i=0; i<num; i++)
    {
     outportb(PaletteDataRegister,pal[i].red/4);
     outportb(PaletteDataRegister,pal[i].green/4);
     outportb(PaletteDataRegister,pal[i].blue/4);
    }
}

/* GetDisplayStartStatus:
 */
/**[txh]********************************************************************

  Description:
  Status poll for triple buffering. Not possible on the majority of
present cards: this function is just a placeholder.@p
  This must report if the Vertical Retrace Interval taked effect and the
Display Start were transfered.@p
   Lamentably TGUI9440 doesn't set 3C2.b7, that's a clear violation to the
VGA standard, Trident people must do it, like CHIPS does.

***************************************************************************/

int GetDisplayStartStatus(AF_DRIVER *af)
{
 return 1;
}


/**[txh]********************************************************************

  Description:
  Hardware scrolling function. The waitVRT value may be one of:@p

  -1 = don't set hardware, just store values for next page flip to use@*
   0 = set values and return immediately@*
   1 = set values and wait for retrace@*

***************************************************************************/

void SetDisplayStart(AF_DRIVER *af, long x, long y, long waitVRT)
{
 long addr;
 uchar temp;
 int PEL;

 if (waitVRT>=0)
   {
    addr=(((y+af_visible_page*af_height)*af_width_bytes)+(x*af_bytespp));
    PEL=addr & 3;
    addr/=4;

    /* Wait until we have a retrace (H or V) */
    while (inportb(0x3DA) & 1);

    /* bits 0 to 7 are in 3D5.0D */
    WriteCRT(0x0D,addr);
    /* bits 8 to 15 are in 3D5.0C */
    WriteCRT(0x0C,addr>>8);

    /* bit 16 is in 3D5.1E.b5, b7 must be 1. The last is made by
       SetVideoMode */
    temp=ReadCRT(0x1E);
    if (addr & 0x10000)
       temp|=0x20;
    else
       temp&=0xDF;
    WriteCRT(0x1E,temp);

    /* bits 17 and 18 are bits 0 and 1 of 3D5.27 */
    temp=ReadCRT(0x27) & 0xFC;
    WriteCRT(0x27,temp | (addr>>17));

    /* Wait a vertical retrace */
    if (waitVRT)
       while (!(inportb(0x3DA) & 8));
    /* Set PEL register */
    outportb(0x3C0,0x13 | 0x20);
    outportb(0x3C0,PEL);
   }

 af_scroll_x=x;
 af_scroll_y=y;
}


/**[txh]********************************************************************

  Description:
  Sets which buffer is being drawn onto, for use in multi buffering
systems (not used by Allegro).@p
  I took it from the prototype driver and seems to be totally independent
of the board.

***************************************************************************/

void SetActiveBuffer(AF_DRIVER *af, long index)
{
 if (af->OffscreenOffset)
   {
    af->OffscreenStartY+=af_active_page*af_height;
    af->OffscreenEndY+=af_active_page*af_height;
   }

 af_active_page=index;
 af_y=index*af_height;

 af->OriginOffset=af_width_bytes*af_height*index;

 if (af->OffscreenOffset)
   {
    af->OffscreenStartY-=af_active_page*af_height;
    af->OffscreenEndY-=af_active_page*af_height;
   }
}


/**[txh]********************************************************************

  Description:
  Sets which buffer is displayed on the screen, for use in multi buffering
systems (not used by Allegro).@p
  Copied from the prototype driver.

***************************************************************************/

void SetVisibleBuffer(AF_DRIVER *af, long index, long waitVRT)
{
 af_visible_page=index;

 SetDisplayStart(af, af_scroll_x, af_scroll_y, waitVRT);
}


#define DontBeSillyClearingMoreThanOnes
/**[txh]********************************************************************

  Description:
  Retrieves information about this video mode, returning zero on success
or -1 if the mode is invalid.

***************************************************************************/

long GetVideoModeInfo(AF_DRIVER *af, short Mode, AF_MODE_INFO *modeInfo)
{
 unsigned i;
 int mode=Mode,bpl=1;
 VideoModeStr *info;
 unsigned sX,sY;

 /* Report error if the mode is outside the range */
 if ((mode<=0) || (mode>NumSupportedVideoModes))
    return -1;

 info=SupportedVideoModes[mode-1];

 /* clear the structure to zero */
 for (i=0; i<sizeof(AF_MODE_INFO); i++)
     ((char *)modeInfo)[i]=0;

 /* copy data across from our stored list of mode attributes */
 modeInfo->Attributes=afHaveVirtualScroll |
		      afHaveBankedBuffer | afHaveLinearBuffer
		      /* Not sure if that's VBE compliant */
		      | afHaveHWCursor
		      /* TGUI supports ROP3 */
		      | afHaveROP2
		      /* none of my modes is VGA */
		      | afNonVGAMode;

 sX=info->hDisplay;
 sY=info->vDisplay;
 /* Transfer some bits from my structure */
   /* I doubt the following too are OK because other drivers reports it in
      a different way */
 if (info->flags & DoubleScan)
   {
    modeInfo->Attributes|=afHaveDoubleScan;
    sY>>=1;
   }
 if (info->flags & Interlaced)
   {
    modeInfo->Attributes|=afHaveInterlaced;
    sY<<=1;
   }
 if (info->flags & HaveAccel2D)
    modeInfo->Attributes|=afHaveAccel2D;

 modeInfo->XResolution=sX;
 modeInfo->YResolution=sY;
 switch (ExtractBPP(info->flags))
   {
    case is8BPP:
	 modeInfo->BitsPerPixel=8;
	 modeInfo->MaxScanLineWidth=4096;
	 #ifndef DontBeSillyClearingMoreThanOnes
	 modeInfo->RedMaskSize        = 0;
	 modeInfo->RedFieldPosition   = 0;
	 modeInfo->GreenMaskSize      = 0;
	 modeInfo->GreenFieldPosition = 0;
	 modeInfo->BlueMaskSize       = 0;
	 modeInfo->BlueFieldPosition  = 0;
	 modeInfo->RsvdMaskSize       = 0;
	 modeInfo->RsvdFieldPosition  = 0;
	 #endif
	 bpl=1;
	 break;
    case is15BPP:
	 modeInfo->BitsPerPixel=15;
	 modeInfo->MaxScanLineWidth=2048;
	 modeInfo->RedMaskSize        = 5;
	 modeInfo->RedFieldPosition   = 10;
	 modeInfo->GreenMaskSize      = 5;
	 modeInfo->GreenFieldPosition = 5;
	 modeInfo->BlueMaskSize       = 5;
	 modeInfo->BlueFieldPosition  = 0;
	 modeInfo->RsvdMaskSize       = 1;
	 modeInfo->RsvdFieldPosition  = 15;
	 bpl=2;
	 break;
    case is16BPP:
	 modeInfo->BitsPerPixel=16;
	 modeInfo->MaxScanLineWidth=2048;
	 modeInfo->RedMaskSize        = 5;
	 modeInfo->RedFieldPosition   = 11;
	 modeInfo->GreenMaskSize      = 6;
	 modeInfo->GreenFieldPosition = 5;
	 modeInfo->BlueMaskSize       = 5;
	 modeInfo->BlueFieldPosition  = 0;
	 modeInfo->RsvdMaskSize       = 0;
	 modeInfo->RsvdFieldPosition  = 0;
	 bpl=2;
	 break;
    case is24BPP:
	 modeInfo->BitsPerPixel=24;
	 modeInfo->MaxScanLineWidth=1360;
	 modeInfo->RedMaskSize        = 8;
	 modeInfo->RedFieldPosition   = 16;
	 modeInfo->GreenMaskSize      = 8;
	 modeInfo->GreenFieldPosition = 8;
	 modeInfo->BlueMaskSize       = 8;
	 modeInfo->BlueFieldPosition  = 0;
	 modeInfo->RsvdMaskSize       = 0;
	 modeInfo->RsvdFieldPosition  = 0;
	 bpl=3;
	 break;
   }


 /* available pages of video memory */
 modeInfo->MaxBuffers=AvailableRAM/(info->minBytesPerScan*sY);
 if (modeInfo->MaxBuffers>1)
    modeInfo->Attributes|=afHaveMultiBuffer;

 /* maximum virtual scanline length in both bytes and pixels. How wide
  * this can go will very much depend on the card.
  */
 /* Here I put the maximun of the chip, if the board doesn't have enough
    RAM that isn't true */
 modeInfo->MaxBytesPerScanLine=4096;

 modeInfo->LinBytesPerScanLine=
 modeInfo->BytesPerScanLine   = info->minBytesPerScan;
 modeInfo->LinMaxBuffers      =
 modeInfo->BnkMaxBuffers      = modeInfo->MaxBuffers;

 modeInfo->LinRedMaskSize        = modeInfo->RedMaskSize;
 modeInfo->LinRedFieldPosition   = modeInfo->RedFieldPosition;
 modeInfo->LinGreenMaskSize      = modeInfo->GreenMaskSize;
 modeInfo->LinGreenFieldPosition = modeInfo->GreenFieldPosition;
 modeInfo->LinBlueMaskSize       = modeInfo->BlueMaskSize;
 modeInfo->LinBlueFieldPosition  = modeInfo->BlueFieldPosition;
 modeInfo->LinRsvdMaskSize       = modeInfo->RsvdMaskSize;
 modeInfo->LinRsvdFieldPosition  = modeInfo->RsvdFieldPosition;

 /* Shawn says:
    I'm not sure exactly what these should be: Allegro doesn't use them */
 /* Here I put the maximun clock the board can generate according to the
    specifications. The 15/16 bpp modes uses a "character clock divider" I
    think that's what Trident use to call a pixel (%2) and 24 bpp uses %3.
    The manual have a funny bug because they say the other value can be
    used to make %0 (-> infinite) ;-))) */
 modeInfo->MaxPixelClock     = 140000000/bpl;
 #ifndef DontBeSillyClearingMoreThanOnes
 /* Don't have any idea about it */
 modeInfo->VideoCapabilities = 0;
 /* Some boards support zooming nVidia RIVA 128 can do it and I think some
    old Tseng Labs boards too */
 modeInfo->VideoMinXScale = 0;
 modeInfo->VideoMinYScale = 0;
 modeInfo->VideoMaxXScale = 0;
 modeInfo->VideoMaxYScale = 0;
 #endif

 return 0;
}

/******************** Video Clock calculation algorithm ********************/
/*****************************************************************************

 Some info about 9440:
 VClk (Dot clock)
 Main PLL:

 F=(N+8)/(M+2)*14.31818
 N: 0..121
 M: 0..31
 49.97 < F < 140.03 That means 50..140 MHz

 Then we have the following dividers:
 %1 and %2 in the PLL.
 %1, %1.5, %2 and %4 in the CRTC
 So we have: %1, %1.5, %2, %3, %4 and %8
 Giving a range: 6.25..140 MHz

 PClk is the VClk %1, %2 or %3 according to the pixel width (1, 2 or 3 bytes).

 So as we get the PClk as parameter we must know the video mode to calculate
the VClk.

*****************************************************************************/

/* Reference frecuency %1, %1.5, etc. */
#define NUM_REFS 6
static
unsigned fR[]={14318180,9545453,7159090,4772727,3579545,1789773};
/* Look how fR[3] is the XT clock and fR[4] is the NTSC color sub-carrier */

#define ClkErrVal ((unsigned)-1)

/**[txh]********************************************************************

  Description:
  This routine calculates the closest frecuency to fx that we can achieve
with the 9440 PLL. The values to program the chip are stored in VClkReg and
Divider.

  Return:
  The closest available frecuency or (unsigned)-1 if the value is outside
the range.

***************************************************************************/

static
unsigned FindClosestVClk(unsigned fx, unsigned *VClkReg, unsigned *Divider)
{
 unsigned M,N,bM=0,bN=0,bDiv=0,fr;
 int div,dif,minDif=140000000,i;
 unsigned f,bf=0;

 /* Reject values clearly outside the range */
 if (fx<6200000 || fx>140500000)
    return ClkErrVal;

 /* We will try the 6 dividers and the 32 values of M => 192 values */
 for (div=0; div<NUM_REFS; div++)
    {
     fr=fR[div];
     /* Search the first M we can use to reduce the values */
     M=(8*fr)/fx;
     if (M<2)
	M=2;
     for (; M<34; M++)
	{ /* Solve the equation for N */
	 N=(fx*M)/fr;
	 /* Reject values outside the range */
	 if (N<8)
	    continue;
	 /* If we passed the maximun just pass to the next div */
	 if (N>129)
	    break;
	 /* Now try N and N+1 (384 values), N will give a frequency below
	    fx and N+1 above fx */
	 for (i=0; i<2; i++)
	    {
	     /* Calculate f */
	     f=(N*fr)/M;
	     /* Calculate |delta f| */
	     dif=f-fx;
	     if (dif<0)
		dif=-dif;
	     /* Store the minimun */
	     if (dif<minDif)
	       {
		minDif=dif;
		bM=M;
		bN=N;
		bDiv=div;
		bf=f;
	       }
	     N++;
	    }
	}
    }
 /* Now translate it to register values */
 bM-=2;
 bN-=8;
 *VClkReg=bN | (bM<<7);
 switch (bDiv)
   {
    case 0:
	 *Divider=2;
    /* %3 */
    case 3:
	 *VClkReg|=0x1000;
    /* %1.5 */
    case 1:
	 *Divider=VClockDiv1_5 | 2;
	 break;
    /* %4 */
    case 4:
	 *VClkReg|=0x1000;
    /* %2 */
    case 2:
	 *Divider=VClockDiv2 | 2;
	 break;
    /* %8 */
    case 5:
	 *VClkReg|=0x1000;
	 *Divider=VClockDiv4 | 2;
	 break;
   }
 return bf;
}

/**[txh]********************************************************************

  Description:
  Returns the closest Pixel Clock that we can achieve for a desired video
mode. We must know the mode because the pixel size is determined by the
mode (8 bpp => 1 byte, 16 bpp => 2 bytes, etc.) and we in fact calculate the
video clock ("Dot" clock I guess) so we must multiply by the pixel size
first.@p

  Returns:
  The closest value available for the board or (unsigned)-1 if the value is
outside the range.

***************************************************************************/

long GetClosestPixelClock(AF_DRIVER *af, short mode, unsigned long pixelClock)
{
 VideoModeStr *info;
 unsigned a1,a2,closest;
 int Bpp;

 /* Filter the mode number and reject invalid modes */
 mode&=0x3FF;
 if ((mode<=0) || (mode>NumSupportedVideoModes))
    return ClkErrVal;

 /* Find the number of bytes per pixel */
 info=SupportedVideoModes[mode-1];
 Bpp=tBytesPerPixel[ExtractBPP(info->flags)];

 /* Convert to Video Clock units */
 pixelClock*=Bpp;

 /* Call the 9440 routine */
 closest=FindClosestVClk(pixelClock,&a1,&a2);
 if (closest==ClkErrVal)
    return closest;

 return closest/Bpp;
}

#define afVM_DontPalette 0x80000000
#define afVM_DontClear   0x8000
#define afVM_LFB         0x4000
#define afVM_MultiBuffer 0x2000
#define afVM_VirtualScrl 0x1000
#define afVM_UseRefresh  0x0800
#define afVM_Stereo      0x0400

uchar DefaultVGAPalette[768]={
0x00,0x00,0x00,0x00,0x00,0x2A,0x00,0x2A,0x00,0x00,0x2A,0x2A,0x2A,0x00,0x00,0x2A,
0x00,0x2A,0x2A,0x15,0x00,0x2A,0x2A,0x2A,0x15,0x15,0x15,0x15,0x15,0x3F,0x15,0x3F,
0x15,0x15,0x3F,0x3F,0x3F,0x15,0x15,0x3F,0x15,0x3F,0x3F,0x3F,0x15,0x3F,0x3F,0x3F,
0x00,0x00,0x00,0x05,0x05,0x05,0x08,0x08,0x08,0x0B,0x0B,0x0B,0x0E,0x0E,0x0E,0x11,
0x11,0x11,0x14,0x14,0x14,0x18,0x18,0x18,0x1C,0x1C,0x1C,0x20,0x20,0x20,0x24,0x24,
0x24,0x28,0x28,0x28,0x2D,0x2D,0x2D,0x32,0x32,0x32,0x38,0x38,0x38,0x3F,0x3F,0x3F,
0x00,0x00,0x3F,0x10,0x00,0x3F,0x1F,0x00,0x3F,0x2F,0x00,0x3F,0x3F,0x00,0x3F,0x3F,
0x00,0x2F,0x3F,0x00,0x1F,0x3F,0x00,0x10,0x3F,0x00,0x00,0x3F,0x10,0x00,0x3F,0x1F,
0x00,0x3F,0x2F,0x00,0x3F,0x3F,0x00,0x2F,0x3F,0x00,0x1F,0x3F,0x00,0x10,0x3F,0x00,
0x00,0x3F,0x00,0x00,0x3F,0x10,0x00,0x3F,0x1F,0x00,0x3F,0x2F,0x00,0x3F,0x3F,0x00,
0x2F,0x3F,0x00,0x1F,0x3F,0x00,0x10,0x3F,0x1F,0x1F,0x3F,0x27,0x1F,0x3F,0x2F,0x1F,
0x3F,0x37,0x1F,0x3F,0x3F,0x1F,0x3F,0x3F,0x1F,0x37,0x3F,0x1F,0x2F,0x3F,0x1F,0x27,
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

/**[txh]********************************************************************

  Description:
  Sets the video mode. This function have various features, be careful.@p
  Mode is a 32 bits value, and not 16 bits as the first drafts propposed.
Because a some nasty reasons isn't just a mode number but some sort of flags
plus mode number. The lower 10 bits are the video mode number the rest of
the bits have the following meaning:@p

 0x8000 = don't clear video memory.@*
 0x4000 = enable linear framebuffer.@*
 0x2000 = enable multi buffering.@*
 0x1000 = enable virtual scrolling.@*
 0x0800 = use refresh rate control.@*
 0x0400 = use hardware stereo.@p

Most of them are self-explanatory, and others aren't very clear yet.@p
The virtual screen size is requested by the virtualX/Y pair the driver will
set a screen of at least this size, if isn't posible will return error. Note
that the actual size could be greater. For this reason bytesPerLine is filled
with the actual X virtual size (stride?).@p
You can request more than one buffer indicating it in numBuffers, if the RAM
isn't enough the driver will return error.@p
Perhaps the hardest parameter to understand is crtc. This parameter provides
a mechanism to allow setting the refresh rate and centering the screen. The
mechanism is incomplet and SciTech people complements it with OEM extentions,
I asked to make these extentions official and Kendall said he will consider
it for Nucleus. Anyways, this pointer will be used by the driver if you use
the 0x0800 flag, the members of the structure are:@p

unsigned short HorizontalTotal: Total pixels, visible and not visible.@*
unsigned short HorizontalSyncStart: Pixel where the horizontal sync pulse
starts.@*
unsigned short HorizontalSyncEnd: End of the pulse.@*
unsigned short VerticalTotal: Total lines, visible and not.@*
unsigned short VerticalSyncStart: Vertical sync pulse start.@*
unsigned short VerticalSyncEnd: End of the pulse.@*
unsigned char  Flags: Various flags see below.@*
unsigned int   PixelClock: Desired pixel clock, the driver will use the
closest available so you must check it with GetClosestPixelClock.
@x{GetClosestPixelClock}.@*
unsigned short RefreshRate: Just ignore it is for very old controllers that
have some specific crtc register values for each mode.@*
unsigned short NumBuffers: That's here only for compatibility issues related
to VBE/AF 1.0.@p

The possible flags are:@p

afDoubleScan (0x0001)  Enable double scanned mode.@*
afInterlaced (0x0002)  Enable interlaced mode.@*
afHSyncNeg   (0x0004)  Horizontal sync is negative.@*
afVSyncNeg   (0x0008)  Vertical sync is negative.@p

As you can see only the X/Y resolution is set by the driver and you control
all the rest.@p
To use it you must first find information about the monitor (asking the user
or using DDC?), then calculate the total and sync positions with the VESA
GTF formula and the aid of GetClosestPixelClock and finally pass these values
to the driver.@p

Important:@p
1) I don't care about LFB that's on all the time.@*
2) I expanded the short mode to unsigned mode because MGL 4.05 does it.@*
3) I added a propietary flag: 0x80000000: Don't set the palette. I think it
will be replaced by some OEM extention, avoid using it.@p

***************************************************************************/

long SetVideoMode(AF_DRIVER *af, short mode, long virtualX, long virtualY,
		  long *bytesPerLine, int numBuffers, AF_CRTCInfo *crtc)
{
 int clear     = ((mode & afVM_DontClear)==0);
 int putPal    = ((mode & afVM_DontPalette)==0);
 int CRTCValid = ((mode & afVM_UseRefresh)!=0) && crtc;
 unsigned used_vram,af_width,sX,sY;
 int bpl,nbpp,Bpp;
 VideoModeStr *info,byApp;

 /* reject anything with hardware stereo */
 if (mode & afVM_Stereo)
    return -1;

 afCurrentMode=mode;
 /* mask off the other flag bits */
 mode&=0x3FF;

 if ((mode<=0) || (mode>NumSupportedVideoModes))
    return -1;

 info=SupportedVideoModes[--mode];

 sX=info->hDisplay;
 sY=info->vDisplay;
 if (info->flags & DoubleScan)
    sY>>=1;
 if (info->flags & Interlaced)
    sY<<=1;

 /* Now choose the right virtual width */
 nbpp=ExtractBPP(info->flags);
 Bpp=tBytesPerPixel[nbpp];
 bpl=GetBestPitchFor(MAX(virtualX,(long)sX),Bpp);
 if (bpl<0)
    return -1;
 *bytesPerLine=bpl;

 /* store info about the current mode */
 af_bpp         = tBitsPerPixel[nbpp];
 af_bytespp     = Bpp;
 af_width_bytes = *bytesPerLine;
 af_height      = MAX((long)sY,virtualY);
 af_visible_page= 0;
 af_active_page = 0;
 af_scroll_x    = 0;
 af_scroll_y    = 0;
 af_y           = 0;
 af_width       = bpl/Bpp;
 afCurrentBank  = 0;

 /* return framebuffer dimensions to the application */
 af->BufferEndX   = af_width_bytes/af_bytespp-1;
 af->BufferEndY   = af_height-1;
 af->OriginOffset = 0;

 used_vram=af_width_bytes*af_height*numBuffers;

 if (used_vram>AvailableRAM)
    return -1;

 if (AvailableRAM-used_vram>=af_width_bytes)
   {
    af->OffscreenOffset = used_vram;
    af->OffscreenStartY = af_height*numBuffers;
    af->OffscreenEndY   = AvailableRAM/af_width_bytes-1;
   }
 else
   {
    af->OffscreenOffset = 0;
    af->OffscreenStartY = 0;
    af->OffscreenEndY   = 0;
   }

 /* Set the fore/back mixing to the default values */
 UsesBackMix=DontMakeBackMix=0;
 BackMix=LineForegroundMix=CurrentForegroundMix=ROP_P;
 LineForegroundMixToS=ROP_S;

 /* Look if the application is suggesting the video mode refresh rate */
 if (CRTCValid)
   {
    unsigned closest,VClk,Divider;

    byApp.minBytesPerScan = info->minBytesPerScan;
    /* Copy the values from the CRTC structure */
    byApp.hDisplay   = sX;
    byApp.hTotal     = crtc->HorizontalTotal;
    byApp.hSyncStart = crtc->HorizontalSyncStart;
    byApp.hSyncEnd   = crtc->HorizontalSyncEnd;
    byApp.vDisplay   = sY;
    byApp.vTotal     = crtc->VerticalTotal;
    byApp.vSyncStart = crtc->VerticalSyncStart;
    byApp.vSyncEnd   = crtc->VerticalSyncEnd;
    byApp.flags      = info->flags & InternalMask;
    if (crtc->Flags & afDoubleScan)
      {
       byApp.flags|=DoubleScan;
       byApp.vDisplay<<=1;
      }
    if (crtc->Flags & afInterlaced)
      {
       byApp.flags|=Interlaced;
       byApp.vDisplay>>=1;
      }
    if (crtc->Flags & afHSyncNeg)
       byApp.flags|=NHSync;
    if (crtc->Flags & afVSyncNeg)
       byApp.flags|=NVSync;
    closest=FindClosestVClk(crtc->PixelClock*Bpp,&VClk,&Divider);
    if (closest==ClkErrVal)
       return -1;
    byApp.ClockType   =Divider;
    byApp.ClockValLow =VClk;
    byApp.ClockValHigh=VClk>>8;
    /* The following values are filled by the app. and ignored here
    crtc->RefreshRate=closest*100/byApp.vTotal/byApp.hTotal;
    crtc->NumBuffers=AvailableRAM/(info->minBytesPerScan*sY);*/
    SetVideoModeH(&byApp,af_width,af_bpp);
   }
 else
    SetVideoModeH(info,af_width,af_bpp);

 /* 8 bpp palette */
 if (af_bpp==8 && putPal)
    RPF_SetPalRange(DefaultVGAPalette,0,256);

 /* All the routines sets it only if change so we must start we a known
    state or it could hang */
 SetForegroundMix(CurrentForegroundMix);

 IsAceleratorOn=info->flags & HaveAccel2D ? 1 : 0;
 if (clear)
   {
    if (IsAceleratorOn)
       /* If we have the accelerator clean the screen without the CPU */
       DrawRawRect(0,0,0,af_width-1,af_height-1);
    else
      {
       unsigned i;
       for (i=used_vram/4; i; --i)
	   Screenl[i]=0;
       Screenl[i]=0;
      }
   }

 /* Hardware cursor initialization */
  /* Shape offset in VRAM */
 WriteCRT(0x44,CursorPat);
 WriteCRT(0x45,CursorPat>>8);
  /* Offset inside the shape (X,Y) */
 WriteCRT(0x46,0);
 WriteCRT(0x47,0);
  /* In double scan modes the cursor must be adjusted */
 HaveDoubleScan=info->flags & DoubleScan ? 1 : 0;

 if (IsAceleratorOn)
   {
    af->DrawScan             = DrawScan;
    af->DrawScanList         = DrawScanList;
    af->DrawPattScan         = DrawPattScan;
    af->DrawPattScanList     = DrawPattScanList;
    af->DrawColorPattScan    = DrawColorPattScan;
    af->DrawColorPattScanList= DrawColorPattScanList;
    af->DrawRect             = DrawRect;
    af->DrawPattRect         = DrawPattRect;
    af->DrawColorPattRect    = DrawColorPattRect;
    af->DrawLine             = DrawLine;
    af->DrawTrap             = DrawTrap;
    /* Dotted (Stipple) lines */
      /* I'm not sure about the behavior of these functions, I just implemented
	 the functionallities found in TGUI9440. I guess they are the same
	 needed for the driver, after all Trident was in the VBE/AF desing */
    af->SetLineStipple       = SetLineStipple;
    af->SetLineStippleCount  = SetLineStippleCount;
    af->DrawStippleLine      = DrawStippleLine;
    af->BitBlt               = BitBlt;
    af->BitBltSys            = BitBltSys;
    af->SrcTransBlt          = SrcTransBlt;
    af->SrcTransBltSys       = SrcTransBltSys;
    af->PutMonoImage         = PutMonoImage;

    /* Routines to control the access to the video ram */
    af->WaitTillIdle         = WaitTillIdle;
     /* I'm not sure about these 2, seems that I don't need it by Kendall says
	in an e-mail that normally EnableDirectAccess is the same as
	WaitTillIdle so I implemented it in this way */
     /* I commented it because VBE/AF 1.0 draft says they are optional and
	WaitTillIdle requered, so if I provide WaitTillIdle must be enough.
    af->EnableDirectAccess   = EnableDirectAccess;
    af->DisableDirectAccess  = DisableDirectAccess;*/

  }
 else
   { /* 24 bpp doesn't have it :-( */
    af->DrawScan             = NULL;
    af->DrawScanList         = NULL;
    af->DrawPattScan         = NULL;
    af->DrawPattScanList     = NULL;
    af->DrawRect             = NULL;
    af->DrawPattRect         = NULL;
    af->DrawLine             = NULL;
    af->BitBlt               = NULL;
    af->DrawColorPattScan    = NULL;
    af->DrawColorPattScanList= NULL;
    af->DrawColorPattRect    = NULL;
    af->SetLineStipple       = NULL;
    af->SetLineStippleCount  = NULL;
    af->DrawStippleLine      = NULL;
    af->BitBlt               = NULL;
    af->BitBltSys            = NULL;
    af->SrcTransBlt          = NULL;
    af->SrcTransBltSys       = NULL;
    af->PutMonoImage         = NULL;
    af->DrawTrap             = NULL;
    af->WaitTillIdle         = NULL;
   }

 /* Some GER values */
   /* Patterned lines: Pattern cleared, counters reseted */
 Putl(0x44,0);

 return 0;
}

#ifdef INCLUDE_OLD_INERTIA_STUFF
#include "oldinert.h"
#endif


/**[txh]********************************************************************

  Description:
  Returns to text mode, shutting down the accelerator hardware.

***************************************************************************/

void RestoreTextMode(AF_DRIVER *af)
{
 SetTextModeVGA();
}


/**[txh]********************************************************************

  Description:
  Provides direct access to the video RAM. That's needed for boards where
the accelerator blocks the use of the video RAM.@p
  TGUI9440 does it only during the Blit operations so in my case I simply
do a wait until de Graphics Engine finished your job. Note that this routine
is here just for testing because isn't needed and isn't reported.

  Example:

  EnableDirectAccess(af);
  .... Draw to the screen ....
  DisableDirectAccess(af);

***************************************************************************/

void EnableDirectAccess(AF_DRIVER *af)
{
 WaitGE();
}


/**[txh]********************************************************************

  Description:
  Disables the direct access to the video RAM. That's needed for boards
where the accelerator blocks the use of the video RAM.@p
  TGUI9440 does it only during the Blit operations so in my case this
function does nothing. Note that this routine is here just for testing
because isn't needed and isn't reported.

***************************************************************************/

void DisableDirectAccess(AF_DRIVER *af)
{
}


/**[txh]********************************************************************

  Description:
  Waits until the accelerator finished your job. That's a very important
function. Suppose you want to draw over a rectangle made with DrawRect, how
can you be sure you won't draw under it? Waiting until the accelerator
finished your job.@p
  What I don't fully understand is the need of both:
Enable/DisableDirectAccess and WaitTillIdle. I saw an e-mail by Kendall
tallking about it.@p
  The TGUI9440 waits until the Graphic Engine finished all the jobs.

***************************************************************************/

void WaitTillIdle(AF_DRIVER *af)
{
 WaitGE();
}


/**[txh]********************************************************************

  Description:
  Vendor-specific extension hook: we don't provide any.

***************************************************************************/

int ExtStub()
{
 return 0;
}


/**[txh]********************************************************************

  Description:
  The first thing ever to be called after our code has been relocated.
This is in charge of filling in the driver header with all the required
information and function pointers. We do not yet have access to the
video memory, so we can't talk directly to the card.

***************************************************************************/

int SetupDriver(AF_DRIVER *af)
{
 int bus_id;

 /* It looks silly: I must have access to the PCI registers! */
 if (!FindPCIDevice(af->PCIDeviceID,af->PCIVendorID,0,&bus_id))
    return -1;

 af->AvailableModes=SupportedVideoModesNums;

 af->Attributes = afHaveMultiBuffer  | afHaveVirtualScroll |
		  afHaveBankedBuffer | afHaveLinearBuffer |
		  afHaveAccel2D      | afHaveHWCursor |
		  afHaveROP2;

 af->IOPortsTable=PortsTable;

 /* 64Kb banking area */
 af->BankedBasePtr=0xA0000;
 af->BankSize=64;

 af->LinearBasePtr=PCIReadLong(bus_id,0x10);
 /* TGUI 9440 ever uses a 2Mb aperture */
 af->LinearSize=2048;

 /* 64Kb text mode area, I map the GER here */
 af->IOMemoryBase[0]=0xB0000;
 af->IOMemoryLen[0]=64;
 /* That's the mapping for the GER, but as I need more space to
    restore the text mode I simply map the whole text mode region */
 /*af->IOMemoryBase[0]=0xB7F00;
 af->IOMemoryLen[0]=1;
 af->IOMemoryBase[1]=0xBFF00;
 af->IOMemoryLen[1]=1;*/

 /* set up driver functions */
 af->SetBank32=SetBank32;
 af->SetBank32Len=(long)SetBank32End-(long)SetBank32;

 af->SupplementalExt=ExtStub;

 af->GetVideoModeInfo     = GetVideoModeInfo;
 af->SetVideoMode         = SetVideoMode;
 af->RestoreTextMode      = RestoreTextMode;

 af->SetDisplayStart      = SetDisplayStart;
 af->SetActiveBuffer      = SetActiveBuffer;
 af->SetVisibleBuffer     = SetVisibleBuffer;
 af->GetDisplayStartStatus= GetDisplayStartStatus;
 af->SetBank              = SetBank;

 af->SetPaletteData       = SetPaletteData;

 af->SetMix               = SetMix;
 af->Set8x8MonoPattern    = Set8x8MonoPattern;
 af->Set8x8ColorPattern   = Set8x8ColorPattern;
 af->Use8x8ColorPattern   = Use8x8ColorPattern;

 af->SetCursor            = SetCursor;
 af->SetCursorPos         = SetCursorPos;
 af->SetCursorColor       = SetCursorColor;
 af->ShowCursor           = ShowCursor;

 af->GetClosestPixelClock = GetClosestPixelClock;

 #ifdef INCLUDE_OLD_INERTIA_STUFF
 /* Inertia stuff */
 af->GetConfigInfo        = GetConfigInfo;
 af->GetCurrentMode       = GetCurrentMode;
 af->SetVSyncWidth        = SetVSyncWidth;
 af->GetVSyncWidth        = GetVSyncWidth;
 af->GetBank              = GetBank;
 af->GetVisibleBuffer     = GetVisibleBuffer;
 af->GetDisplayStart      = GetDisplayStart;
 af->SetDisplayStartAddr  = SetDisplayStartAddr;
 af->IsVSync              = IsVSync;
 af->WaitVSync            = WaitVSync;
 af->GetActiveBuffer      = GetActiveBuffer;
 af->IsIdle               = IsIdle;
 #endif

 /* ToDo
 af->SaveRestoreState     = NULL;
 */

 return 0;
}


/**[txh]********************************************************************

  Description:
  The second thing to be called during the init process, after the
application has mapped all the memory and I/O resources we need. This is in
charge of finding the card, returning 0 on success or -1 to abort.

***************************************************************************/

int InitDriver(AF_DRIVER *af)
{
 int i;

 MMIOBASE=(unsigned)(af->IOMemMaps[0])+0x7F00;
 linearAddress=(unsigned long)af->LinearMem;
 bankedAddress=(unsigned long)af->BankedMem;
 TextModeMemory=(unsigned *)((unsigned)(af->IOMemMaps[0])+0x8000);
 /* Now I can access the linear buffer and all the registers */
 CaptureSVGAStart();
 /* Find the amount of installed memory */
 AvailableRAM=TestMemory();

 /* Normalize the memory size, I had problem with intermediate sizes looks
    like is impossible to detect 1.25 Mb. Trident's BIOS only reports 256K,
    512K, 1M or 2Mb it looks like a limitation of what we can detect */
 if (AvailableRAM>=(1<<21))
    AvailableRAM=1<<21;
 else
   if (AvailableRAM>=(1<<20))
      AvailableRAM=1<<20;
   else
     if (AvailableRAM>=(1<<19))
	AvailableRAM=1<<19;
     else
       if (AvailableRAM>=(1<<18))
	  AvailableRAM=1<<18;
       else
	  return -1;

 af->TotalMemory=AvailableRAM/1024; /* In Kb */

 /* Reserve 2Kb of memory for patterns and harware cursor */
 /* Monochromatic pattern */
 /* I use 128 bytes aligment because in 16bpp that's required */
 AvailableRAM-=128;
 pMonoPattern=linearAddress+AvailableRAM;
 MonoPattern=AvailableRAM>>6;
 AvailableRAM-=128;
 pInvMonoPattern=linearAddress+AvailableRAM;
 InvMonoPattern=AvailableRAM>>6;
 /* Hardware Cursor */
 /* 32x32 (size) * 2 (planes) / 8 (packed) = 256 but 1K aligned */
 AvailableRAM-=256+512;
 pCursorPat=linearAddress+AvailableRAM;
 CursorPat=AvailableRAM>>10;
 /* 8 patterns of 8x8x2 bytes */
 for (i=0; i<8; i++)
    {
     AvailableRAM-=128;
     pColorPatterns[i]=linearAddress+AvailableRAM;
     ColorPatterns[i]=AvailableRAM>>6;
    }
 SelectedColorPattern=ColorPatterns[0];

 return 0;
}


/* FreeBEX:
 *  Returns an interface structure for the requested FreeBE/AF extension.
 */
void *FreeBEX(AF_DRIVER *af, unsigned long id)
{
   switch (id) {

      default:
	 return NULL;
   }
}



