/* Copyright 1998 (c) by Salvador Eduardo Tropea
   This code is part of the FreeBE/AF project you can use it under the
terms and conditions of the FreeBE/AF project. */
/* TGUI Alternative bank selector */
/* It select the bank when we use a 32Kb or 64Kb window */
#define DestinationSegmentAddress 0x3D8
#define SourceSegmentAddress      0x3D9


#define INLINE extern inline

//#define IOMAPPED
//#define UNDERTEST

#ifdef UNDERTEST
#include <sys/farptr.h>
#endif

#ifdef IOMAPPED
#define MODEINIT 0x80
INLINE void Putb(unsigned pos, uchar val)    { outportb(0x2100+pos,val); }
INLINE void Putw(unsigned pos, ushort val)   { outportw(0x2100+pos,val); }
INLINE void Putl(unsigned pos, unsigned val) { outportl(0x2100+pos,val); }
INLINE uchar    Getb(unsigned pos) { return inportb(0x2100+pos); }
INLINE ushort   Getw(unsigned pos) { return inportw(0x2100+pos); }
INLINE unsigned Getl(unsigned pos) { return inportl(0x2100+pos); }
#else
// Memory mapped
#define MODEINIT 0x81
#ifdef UNDERTEST
#define MMIOBASE 0xB7F00
//#define MMIOBASE 0xBFF00
//#define MODEINIT 0x82
INLINE void Putb(unsigned pos, uchar val)    { _farnspokeb(MMIOBASE+pos,val); }
INLINE void Putw(unsigned pos, ushort val)   { _farnspokew(MMIOBASE+pos,val); }
INLINE void Putl(unsigned pos, unsigned val) { _farnspokel(MMIOBASE+pos,val); }
INLINE uchar    Getb(unsigned pos) { return _farnspeekb(MMIOBASE+pos); }
INLINE ushort   Getw(unsigned pos) { return _farnspeekw(MMIOBASE+pos); }
INLINE unsigned Getl(unsigned pos) { return _farnspeekl(MMIOBASE+pos); }
#else
extern unsigned MMIOBASE;
/*
  If I don't use volatile the stupid gcc does funny things like that:
  movl _MMIOBASE,%eax
  movl 0x32(%eax),%al
Lxxx:
  testb %al,$0x40
  jne   Lxxx

  :-)))) the silly compiler is specting some gost will change AL by magic.
  Using volatile generates good code. Some idiot reloads are performed but
that's normal in the "unoptimizer" module of gcc ;-)
  Memory mapped I/O generates much compact code and I guess faster too, I
must test it.
*/
INLINE void Putb(unsigned pos, uchar val)    { *((volatile uchar *)(MMIOBASE+pos))=val; }
INLINE void Putw(unsigned pos, ushort val)   { *((volatile ushort *)(MMIOBASE+pos))=val; }
INLINE void Putl(unsigned pos, unsigned val) { *((volatile unsigned *)(MMIOBASE+pos))=val; }
INLINE uchar    Getb(unsigned pos) { return *((volatile uchar *)(MMIOBASE+pos)); }
INLINE ushort   Getw(unsigned pos) { return *((volatile ushort *)(MMIOBASE+pos)); }
INLINE unsigned Getl(unsigned pos) { return *((volatile unsigned *)(MMIOBASE+pos)); }
#endif
#endif

// Register index
#define GECR 0x36
#define CLAR 0x21

// ****************************** GER values ********************************
// Status
#define GESR 0x20
// Operation Mode 0
#define GOMR0 0x22
// Operation Mode 1 (Not implemented in 9440)
#define GOMR1 0x23
// Command
#define GECoR 0x24
// Foreground Mix
#define FMR 0x27
// Drawing Flag 0,1,2 (Not implemented in 9440) and 3
#define GEDFR0 0x28
#define GEDFR1 0x29
#define GEDFR2 0x2A
#define GEDFR3 0x2B
/* All joined in one 32 bits: */
#define PatFromDisplay        0x00000002
#define PatFromSystem         0
#define SourceDataDisplay     0x00000004
#define SourceDataSystem      0
#define PatMono               0x00000020
#define PatColor              0
#define SourceDataMono        0x00000040
#define SourceDataColor       0
#define YDecreasing           0x00000100
#define XDecreasing           0x00000200
#define YMajor                0x00000400
#define TransparentEnable     0x00001000
#define TransparentReverse    0x00002000
#define SolidDrawing          0x00004000
#define PatternedDrawing      0
#define PatternedLines        0x00008000
// Foreground Color 0 (Low 8 bits) and 1
#define FCR0 0x2C
#define FCR1 0x2D
// Background Color 0 (Low 8 bits) and 1
#define BCR0 0x30
#define BCR1 0x31
// Pattern Location 0 (Low) and 1
// Data must be 64 bytes aligned in VRAM, in 16 bits mode the lower bit must
// be 0
#define PLR0 0x34
#define PLR1 0x35
// Destination X Location 0 (Low) and 1
#define DXL0 0x38
#define DXL1 0x39
// Destination Y Location 0 (Low) and 1
// Only 11 bits used
#define DYL0 0x3A
#define DYL1 0x3B
// Source X Location 0 (Low) and 1
// Or diagonal step for line operations (detaY-deltaX) only 12 bits signed
#define SXL0 0x3C
#define SXL1 0x3D
// Source Y Location 0 (Low) and 1
// Or axial step for line operations (detaY) only 11 bits signed
#define SYL0 0x3E
#define SYL1 0x3F
// Operation Dimension X Location 0 (Low) and 1
// Or initial error for line operations (2*detaY-deltaX) only 12 bits signed
#define ODXL0 0x40
#define ODXL1 0x41
// Operation Dimension Y Location 0 (Low) and 1
// Or length for line operations (deltaX) only 12 bits unsigned
// Various bits for short vector operations.
#define ODYL0 0x42
#define ODYL1 0x43
// Pen Style Mask 0 and 1 for lines
#define PSMR0 0x44
#define PSMR1 0x45
// Style Mask First Pixel Repeat Count for lines
#define SMFPRC 0x46
// Style Mask Repeat Count for lines
#define SMRC 0x47
// Registers 0x80 to 0xFF are for the pattern
// ************************* End of  GER values *****************************
// ****** Commands for GECoR ******
#define NOP      0
#define BitBLT   1
#define ScanLine 3
// Bresenham Line
#define BLine    4
// Short vector
#define SVector  5

extern unsigned long linearAddress;
#define Screenb ((uchar *)linearAddress)
#define Screenw ((ushort *)linearAddress)
#define Screenl ((unsigned *)linearAddress)

#define SetXLocation(a) Putw(DXL0,a)
#define SetYLocation(a) Putw(DYL0,a)
#define SetXYLocation(a,b) Putl(DXL0,(a) | ((b)<<16))
#define SetXYSource(a,b) Putl(SXL0,(a) | ((b)<<16))
#define SetForeground(a) Putw(FCR0,a)
#define SetBackground(a) Putw(BCR0,a)
#define SetForegroundMix(a) Putb(FMR,a)
#define SetPenStyleMask(a) Putw(PSMR0,a)
#define SetStyleMaskRepeatCount(a) Putb(SMRC,a)

//#define SAFE_IO

INLINE
void SetLineSteps(int deltaY, int deltaX)
{
 // Diagonal step is dY-dX, Axial step is dY both 16 bits signed
 Putl(SXL0,((deltaY-deltaX) & 0xFFFF) | (deltaY<<16));
}

INLINE
void SetErrAndLen(int deltaY, int deltaX)
{
 // Initial error is 2*dY-dX (signed), Length is ABS(dX) (unsigned)
 Putl(ODXL0,((2*deltaY-deltaX) & 0xFFFF) | (deltaX<<16));
}


INLINE
void SetDimensions(int width, int height)
{
 Putl(ODXL0,width | (height<<16));
}

INLINE
void SetWidth_1(int width)
{
 Putw(ODXL0,width-1);
}

INLINE
void SetWidth(int width)
{
 Putw(ODXL0,width);
}

INLINE
void SetDrawFlags(int dir)
{
 Putl(GEDFR0,dir);
}

INLINE
void SetPatternLocation(unsigned offset)
{
 Putw(PLR0,offset);
}

/*
  Wait until the GER is idle. That's needed for the BitBlt operation because
we can't write to the screen. If I return the control to the application
and it tries to draw directly to the screen it will fail.
  In OS drivers, line Windows drivers, that's not needed because the
application NEVER will draw directly to the screen.
  An additional feature not exploited is that the GER can generate interrupts
so we can have a queue of command in memory and transfer it to the TGUI
when the GER is ready.
*/
INLINE
void WaitGE(void)
{
 while (Getb(GESR) & 0x80);
}

/*
  Wait until the FIFO of the GER is empty, if we don't do it the cached
command will use the new settings ;-)
*/
INLINE
void WaitGEfifo(void)
{
 while (Getb(GESR) & 0x20);
}

/*
 That's a very bad thing, I must put a full wait after the blit because
during the Blit the CPU can't access the VRAM.
 It could be avoided only if ALL the drawing is made by the driver, but
that's not the FreeBE/AF case.
*/
INLINE
void DoBlit(void)
{
 Putb(GECoR,BitBLT);
 #ifdef WAITTILLIDLE_NOT_NEEDED
 WaitGE();
 #endif
}

INLINE
void DoBlitDontWait(void)
{
 Putb(GECoR,BitBLT);
}

INLINE
void DoBresenhamLine(void)
{
 Putb(GECoR,BLine);
}

INLINE
void DoScan(void)
{
 Putb(GECoR,ScanLine);
}

INLINE
void SetNewMode(void)
{
 ReadSEQ(0xB);
}

INLINE
void SetOldMode(void)
{
 WriteSEQ(0xB,0);
}

/**************************** RASTER OPERATIONS ****************************/
/* Most of them are for solid colors or patterns only */
#define ROP_0     0x00
#define ROP_n_PoD 0x05
#define ROP_nPaD  0x0A
#define ROP_nP    0x0F
#define ROP_PanD  0x50
#define ROP_nD    0x55
#define ROP_PxD   0x5A
#define ROP_n_PaD 0x5F
#define ROP_PaD   0xA0
#define ROP_n_PxD 0xA5
#define ROP_D     0xAA
#define ROP_nPoD  0xAF
#define ROP_P     0xF0
#define ROP_PonD  0xF5
#define ROP_PoD   0xFA
#define ROP_1     0xFF

/* These are for image blits only */
/* 0x00 is ROP_0 */
#define ROP_n_SoD 0x11
#define ROP_nSaD  0x22
#define ROP_nS    0x33
#define ROP_SanD  0x44
/* 0x55 is ROP_nD */
#define ROP_SxD   0x66
#define ROP_n_SaD 0x77
#define ROP_SaD   0x88
#define ROP_n_SxD 0x99
/* 0xAA is ROP_D */
#define ROP_nSoD  0xBB
#define ROP_S     0xCC
#define ROP_SonD  0xDD
#define ROP_SoD   0xEE
/* 0xFF is ROP_1 */

#define VClockDiv2   0x20
#define VClockDiv4   0x40
#define VClockDiv1_5 0x60
#define DClockDiv2   0x80


