/*
 *       ______             ____  ______     _____  ______ 
 *      |  ____|           |  _ \|  ____|   / / _ \|  ____|
 *      | |__ _ __ ___  ___| |_) | |__     / / |_| | |__ 
 *      |  __| '__/ _ \/ _ \  _ <|  __|   / /|  _  |  __|
 *      | |  | | |  __/  __/ |_) | |____ / / | | | | |
 *      |_|  |_|  \___|\___|____/|______/_/  |_| |_|_|
 *
 *
 *      Cirrus54xx (not 546x) driver
 *
 *      See freebe.txt for copyright information.
 */

#include <pc.h>

#include "vbeaf.h"
#include "cirdefs.h"

/******************************************************************************/
/* If you are having trouble getting this driver to work, try uncommenting    */
/* the line below to disable memory-mapped IO. Also, read NOTES.TXT.          */
/******************************************************************************/
//#define DISABLE_MMIO

//#define NO_CACHE //the values in registers BitBLT doesn't changed won't be cached

/* driver function prototypes */
void SetBank32();
void SetBank32End();
int  ExtStub();
long GetVideoModeInfo(AF_DRIVER *af, short mode, AF_MODE_INFO *modeInfo);
long SetVideoMode(AF_DRIVER *af, short mode, long virtualX, long virtualY, long *bytesPerLine, int numBuffers, AF_CRTCInfo *crtc);
void RestoreTextMode(AF_DRIVER *af);
long GetClosestPixelClock(AF_DRIVER *af, short mode, unsigned long pixelClock);
void SaveRestoreState(AF_DRIVER *af, int subfunc, void *saveBuf);
void SetDisplayStart(AF_DRIVER *af, long x, long y, long waitVRT);
void SetActiveBuffer(AF_DRIVER *af, long index);
void SetVisibleBuffer(AF_DRIVER *af, long index, long waitVRT);
int  GetDisplayStartStatus(AF_DRIVER *af);
void SetPaletteData(AF_DRIVER *af, AF_PALETTE *pal, long num, long index, long waitVRT);
void SetBank(AF_DRIVER *af, long bank);
void SetMix(AF_DRIVER *af, long foreMix, long backMix);
void Set8x8MonoPattern(AF_DRIVER *af, unsigned char *pattern);
void Set8x8ColorPattern(AF_DRIVER *af, int index, unsigned long *pattern);
void Use8x8ColorPattern(AF_DRIVER *af, int index);

/* if you need some video memory for internal use by the accelerator
 * code (for example storing pattern data), you can define this value to 
 * reserve room for yourself at the very end of the memory space, that
 * the application will not be allowed to use.
 */
#define RESERVED_VRAM 2048

//last 256 bytes can be used by MMIO on 5429, so I reserve them for sure

#define MONOPATTSTART 1024
#define SOLIDPATTSTART 768
#define COLPATTSTART 512
#define CURSORSTART 2048
#define DISPLACEMENT 0x10000
#define CIRRUS_PCI_VENDOR_ID 0x1013

CIRRUS_DETECT detect_info[]={
{ CLGD5426, 0x15, 0, "CLGD-5426", 0 },
{ CLGD5428, 0x18, 0, "CLGD-5428", 0 },
{ CLGD5429, 0x19, 0, "CLGD-5429", 1 },
{ CLGD5430, 0x32, 0xa0, "CLGD-5430", 2 },
{ CLGD5434, 0x31, 0xa4, "CLGD-5434", 3 },
{ CLGD5434E, 0x33, 0xa8, "CLGD-5434 rev E",4 },
{ CLGD5436, 0x36, 0xac, "CLGD-5436",5 },
{ CLGD5440, 0x32, 0xa0, "CLGD-5440",2 },//find by reading chip id register 0xb0
{ CLGD5446, 0x39, 0xb8, "CLGD-5446",5 },
{ CLGD5480, 0x3a, 0xbc, "CLGD-5480",6 },
{ CLGD7541, 0x41, 0x1204, "CLGD-7541",7 },
{ CLGD7542, 0x43, 0x1200, "CLGD-7542",-1 },
{ CLGD7543, 0x42, 0x1202, "CLGD-7543",7 },
{ CLGD7548, 0x44, 0x38, "CLGD-7548",-1 },
{ CLGD7555, 0x46, 0, "CLGD-7555",-1 },
{ CLGD7556,  0x47, 0, "CLGD-7556",-1 }
};

/* list which ports we are going to access (only needed under Linux) */
unsigned short ports_table[] = { 0x3c0,0x3c4,0x3ce,0x3d4,0x3da,0xFFFF };

typedef struct _GFX_MODE_INFO
{
   int w, h;
   int bpp;
   int bpl;
   int num;
//   int tweak; //index to height modifiing table (substract 1 to get real index)
} _GFX_MODE_INFO;

#define MAX_MODES 25

_GFX_MODE_INFO mode_list[] =
{
   {  640,  400,  8,    640,   0x5E},
   {  640,  480,  8,    640,   0x5F},
   {  800,  600,  8,    800,   0x5C},
   { 1024,  768,  8,    1024,  0x60},
   { 1280, 1024,  8,    1280,  0x6D},
   { 1600, 1200,  8,    1600,  0x78},
   {  640,  480, 15,    1280,  0x66},
   {  800,  600, 15,    1600,  0x67},
   { 1024,  768, 15,    2048,  0x68},
   { 1280, 1024, 15,    2560,  0x69},
   {  320,  200, 16,    640,   0x6F},
   {  640,  480, 16,    1280,  0x64},
   {  800,  600, 16,    1600,  0x65},
   { 1024,  768, 16,    2048,  0x74},
   { 1280, 1024, 16,    2560,  0x75},
   {  320,  200, 24,    960,   0x70},
   {  640,  480, 24,    2048,  0x71},
   { 1280, 1024, 24,    3840,  0x77},
   {  640,  480, 32,    2560,  0x76},
   {  800,  600, 32,    3200,  0x72},
   { 1024,  768, 32,    4096,  0x73},
   { 1152,  870, 32,    4608,  0x79},
   {  0,    0,    0,    0,     0}
};

int cir_maxpitch = 0;
int cir_useblt24 = 0;
int cir_useblt32 = 0;
int cir_offmono = 0;  //linear address in VRAM where mono pattern starts
int cir_offscreen = 0;//linear address in VRAM where full pattern starts (solid fills)
int cir_offcolor = 0; //linear address in VRAM where color pattern starts
int cir_bpp = 0;
int cir_bltmode = 0;
int cir_bltrop = 0;
int cir_pixmode = 0;
int cir_maxheight = 0;
int cir_maxwidth = 0;
int mouse_fg = 0;
int cir_cursor_visible = 0;

/* old values (used for caching) */
int cir_fg = -1;
int cir_bg = -1;
int cir_trans = -1;
int cir_oldbltmode = -1;
int cir_oldbltrop = -1;
int cir_height = -1;
int cir_card = -1;
int need_wait = 0;
unsigned long linear_addr = 0;

short available_modes[MAX_MODES+1] = { -1 };
short num_modes=-1;

/* internal driver state variables */
int af_bpp;
int af_bank;
int af_width;
int af_height;
int af_linear;
unsigned long af_mmio=0;
int af_visible_page;
int af_active_page;
int af_last_bank;
int af_fore_mix;
int af_back_mix;
int af_memory;


/* RestoreTextMode:
 *  Returns to text mode, shutting down the accelerator hardware.
 */
void RestoreTextMode(AF_DRIVER *af)
{
   RM_REGS r;

   r.x.ax = 3;
   rm_int(0x10, &r);
}



/* GetClosestPixelClock:
 *  I don't have a clue what this should return: it is used for the
 *  refresh rate control.
 */
long GetClosestPixelClock(AF_DRIVER *af, short mode, unsigned long pixelClock)
{
   /* ??? */
   return 135000000;
}



/* SaveRestoreState:
 *  Stores the current driver status: not presently implemented.
 */
void SaveRestoreState(AF_DRIVER *af, int subfunc, void *saveBuf)
{
   /* not implemented (not used by Allegro) */
}



/* SetDisplayStart:
 *  Hardware scrolling function.
 */
void SetDisplayStart(AF_DRIVER *af, long x, long y, long waitVRT)
{
   long b = x * cir_bpp + (y+af_visible_page*af_height) * af_width;
   long a=b>>2;
   long t;


   af->WaitTillIdle(af);

   DISABLE();
   if (waitVRT) {
     _vsync_out_h();
   }
   /* write high bits to Cirrus 54xx registers */
   t = (a >> 16)&1;    //bit 16
   t +=(a >> 15)&12;    /* funny format, uses bits 0, 2, and 3 */
   alter_vga_register(_crtc, 0x1B, 0xD, t);
   alter_vga_register(_crtc,0x1D,0x80,(a>>11)&0x80);
   /* write to normal VGA address registers */
   write_vga_register(_crtc, 0x0D, (a) & 0xFF);
   write_vga_register(_crtc, 0x0C, (a>>8) & 0xFF);

   ENABLE();
   /* write low 2 bits to VGA horizontal pan register */
   _write_hpp(b&3);

   if (waitVRT) {
     _vsync_in();
   }
}

/* SetActiveBuffer:
 *  Sets which buffer is being drawn onto, for use in multi buffering
 *  systems (not used by Allegro).
 */
void SetActiveBuffer(AF_DRIVER *af, long index)
{
   if (af->OffscreenOffset) {
      af->OffscreenStartY += af_active_page*af_height;
      af->OffscreenEndY += af_active_page*af_height;
   }

   af_active_page = index;

   af->OriginOffset = af_width*af_height*index;

   if (af->OffscreenOffset) {
      af->OffscreenStartY -= af_active_page*af_height;
      af->OffscreenEndY -= af_active_page*af_height;
   }
}



/* SetVisibleBuffer:
 *  Sets which buffer is displayed on the screen, for use in multi buffering
 *  systems (not used by Allegro).
 */
void SetVisibleBuffer(AF_DRIVER *af, long index, long waitVRT)
{
   af_visible_page = index;

   SetDisplayStart(af, 0, 0, waitVRT);
}



/* GetDisplayStartStatus:
 *  Status poll for triple buffering. Not possible on the majority of
 *  present cards: this function is just a placeholder.
 */
int GetDisplayStartStatus(AF_DRIVER *af)
{
   return 1;
}

AF_PALETTE af_pal[256];

/* SetPaletteData:
 *  Palette setting routine.
 */
void SetPaletteData(AF_DRIVER *af, AF_PALETTE *pal, long num, long index, long waitVRT)
{
   int i;

   if (waitVRT) {
      do {
      } while (inportb(0x3DA) & 8);

      do {
      } while (!(inportb(0x3DA) & 8));
   }

   outportb(0x3c8,index);
   for (i=index; i<num+index; i++) {
      af_pal[i]=pal[i];
      outportb(0x3C9, pal[i].red/4);
      outportb(0x3C9, pal[i].green/4);
      outportb(0x3C9, pal[i].blue/4);
   }
   if ((index>=mouse_fg&&index+num<mouse_fg)||(index>=0)) {
     alter_vga_register(0x3c4,0x12,3,2);//index 12 - enable access to extended DAC palette entries
     outportb(0x3c8,0xf);//cursor foreground
     outportb(0x3c9,af_pal[mouse_fg].red);
     outportb(0x3c9,af_pal[mouse_fg].green);
     outportb(0x3c9,af_pal[mouse_fg].blue);
     outportb(0x3c8,0);//cursor background
     outportb(0x3c9,af_pal[0].red);
     outportb(0x3c9,af_pal[0].green);
     outportb(0x3c9,af_pal[0].blue);
     alter_vga_register(0x3c4,0x12,3,0);//index 12 - enable access to extended DAC palette entries
   }
}

/* SetBank32:
 *  Relocatable bank switch function. This is called with a bank number in
 *  %edx. I'm not sure what registers it is allowed to clobber, so it is 
 *  probably a good idea to save them all.
 *
 *  This function may be copied anywhere within the address space of the
 *  calling program, so it must be 100% relocatable. That means that you 
 *  must not refer to any internal variables of the /AF driver, because 
 *  you know nothing about where in memory it will be located. Your only
 *  input is the bank number in %edx, and your only output should be
 *  changing the relevant hardware registers.
 *
 *  If you are unable to provide a relocatable bank switcher of this type,
 *  remove this function (clear the SetBank32 pointer to NULL during the 
 *  header init), and fill in the SetBank() routine below instead. Allegro 
 *  only ever uses SetBank(), so there will be no problem with leaving this 
 *  function out, but you may have problems running other VBE/AF 
 *  applications if you don't provide it.
 *
 */
asm ("

   .globl _SetBank32, _SetBank32End

      .align 4
   _SetBank32:
     pushl %edx          /* I have 16K bank gran, but driver probably */
     movb %dl,%ah        /* don't know about that, so I must multiply by 4 */
     shlb $2,%ah
     movl $0x3CE, %edx
     movb $9, %al
     outw %ax, %dx
     popl %edx
     ret
   _SetBank32End:

");

/* SetBank:
 *  C-callable bank switch function. This version simply chains to the
 *  relocatable SetBank32() above. If you can't provide a relocatable
 *  function (because you need access to global variables or some part
 *  of the /AF driver structure), you should put the bank switch code
 *  here instead.
 */
void SetBank(AF_DRIVER *af, long bank)
{
  asm("
     movb %%al,%%ah
     shlb $2,%%ah
     movl $0x3CE, %%edx
     movb $9, %%al
     outw %%ax, %%dx"
     ::"a" (bank):"%dx");
   af_bank = bank;
}

#ifdef NO_CACHE
#define SET_ROP_MODE(bltrop,bltmode) { CIR_BLTROP(bltrop);     \
	CIR_BLTMODE(bltmode);}

#define SET_ROP_MODEMMIO(bltrop,bltmode) CIR_ROP_MODEMMIO(bltrop,bltmode);

#define SET_TRANS(color) CIR_TRANS(color)

#define SET_TRANSMMIO(color) CIR_TRANSMMIO(color)

#define SET_WIDTH_HEIGHT(width,height) {CIR_WIDTH(width);      \
	CIR_HEIGHT(height);}

#define SET_FG8(fg) CIR_FORG8(fg)
#define SET_FG16(fg) CIR_FORG16(fg)
#define SET_FG24(fg) CIR_FORG24(fg)
#define SET_FG32(fg) CIR_FORG32(fg)

#define SET_BG8(bg) CIR_BACKG8(bg)
#define SET_BG16(bg) CIR_BACKG16(bg)
#define SET_BG24(bg) CIR_BACKG24(bg)
#define SET_BG32(bg) CIR_BACKG32(bg)

#define SET_FG8MMIO(fg) CIR_FORG8MMIO(fg)
#define SET_FG16MMIO(fg) CIR_FORG16MMIO(fg)
#define SET_FG24MMIO(fg) CIR_FORG24MMIO(fg)
#define SET_FG32MMIO(fg) CIR_FORG32MMIO(fg)

#define SET_BG8MMIO(bg) CIR_BACKG8MMIO(bg)
#define SET_BG16MMIO(bg) CIR_BACKG16MMIO(bg)
#define SET_BG24MMIO(bg) CIR_BACKG24MMIO(bg)
#define SET_BG32MMIO(bg) CIR_BACKG32MMIO(bg)

#else

#define SET_ROP_MODE(bltrop,bltmode)                        \
	if (cir_oldbltrop!=bltrop) {                              \
	  cir_oldbltrop=bltrop;                                   \
	  CIR_BLTROP(cir_oldbltrop);                              \
	}                                                         \
	if (cir_oldbltmode!=bltmode) {                            \
	  cir_oldbltmode=bltmode;                                 \
	  CIR_BLTMODE(cir_oldbltmode);                            \
	}

#define SET_ROP_MODEMMIO(bltrop,bltmode)                          \
	if (cir_oldbltrop!=bltrop) {                              \
	  if (cir_oldbltmode!=bltmode) {                          \
	    cir_oldbltmode=bltmode;                               \
	    cir_oldbltrop=bltrop;                                 \
	    CIR_ROP_MODEMMIO(bltrop,bltmode);                     \
	  } else {                                                \
	    cir_oldbltrop=bltrop;                                 \
	    CIR_BLTROPMMIO(bltrop);                               \
	  }                                                       \
	} else if (cir_oldbltmode!=bltmode) {                     \
	  cir_oldbltmode=bltmode;                                 \
	  CIR_BLTMODEMMIO(bltmode);                               \
	}


#define SET_FG8(color) if (cir_fg!=color) {                 \
	cir_fg=color;                                             \
	CIR_FORG8(cir_fg);                                        \
      }

#define SET_FG16(color) if (cir_fg!=color) {                \
	cir_fg=color;                                             \
	CIR_FORG16(cir_fg);                                       \
      }

#define SET_FG24(color) if (cir_fg!=color) {                \
	cir_fg=color;                                             \
	CIR_FORG24(cir_fg);                                       \
	}

#define SET_FG32(color) if (cir_fg!=color) {                \
	cir_fg=color;                                             \
	CIR_FORG32(cir_fg);                                       \
      }

#define SET_BG8(color) if (cir_bg!=color) {                 \
	cir_bg=color;                                             \
	CIR_BACKG8(cir_bg);                                       \
      }

#define SET_BG16(color) if (cir_bg!=color) {                \
	cir_bg=color;                                             \
	CIR_BACKG16(cir_bg);                                      \
      }

#define SET_BG24(color) if (cir_bg!=color) {                \
	cir_bg=color;                                             \
	CIR_BACKG24(cir_bg);                                      \
      }

#define SET_BG32(color) if (cir_bg!=color) {                \
	cir_bg=color;                                             \
	CIR_BACKG32(cir_bg);                                      \
      }

#define SET_FG8MMIO(color) if (cir_fg!=color) {                 \
	cir_fg=color;                                             \
	CIR_FORG8(cir_fg);                                        \
      }

#define SET_FG16MMIO(color) if (cir_fg!=color) {                \
	cir_fg=color;                                             \
	CIR_FORG16(cir_fg);                                       \
      }

#define SET_FG24MMIO(color) if (cir_fg!=color) {                \
	cir_fg=color;                                             \
	CIR_FORG24(cir_fg);                                       \
	}

#define SET_FG32MMIO(color) if (cir_fg!=color) {                \
	cir_fg=color;                                             \
	CIR_FORG32(cir_fg);                                       \
      }

#define SET_BG8MMIO(color) if (cir_bg!=color) {                 \
	cir_bg=color;                                             \
	CIR_BACKG8(cir_bg);                                       \
      }

#define SET_BG16MMIO(color) if (cir_bg!=color) {                  \
	cir_bg=color;                                             \
	CIR_BACKG16(cir_bg);                                      \
      }

#define SET_BG24MMIO(color) if (cir_bg!=color) {                  \
	cir_bg=color;                                             \
	CIR_BACKG24(cir_bg);                                      \
      }

#define SET_BG32MMIO(color) if (cir_bg!=color) {                  \
	cir_bg=color;                                             \
	CIR_BACKG32(cir_bg);                                      \
      }

#define SET_TRANS(color) if (cir_trans!=(color)) {                \
	cir_trans=color;                                          \
	CIR_TRANS(cir_trans);                                     \
      }

#define SET_TRANSMMIO(color) if (cir_trans!=(color)) {            \
	cir_trans=color;                                          \
	CIR_TRANSMMIO(cir_trans);                                 \
      }

#define SET_WIDTH_HEIGHT(width,height) {CIR_HEIGHT(height);  \
	 CIR_WIDTH(width);}

/*
//doesn't work on 7543 but should on 5426-9
#define SET_HEIGHT(height) if (cir_height!=height){         \
	cir_height=height;                                        \
	CIR_HEIGHT(height);                                       \
      }
*/

#endif

inline void waitidle()
{
  if (need_wait) {
    outportb(GRX,0x31);
    while (inportb(GRX+1)&1);
    need_wait=0;
  }
}

inline void waitidleMMIO()
{
  if (need_wait) {
    while (inmb(0x40)&1);
    need_wait=0;
  }
}

/* WaitTillIdle:
 *  Delay until the hardware controller has finished drawing.
 */

#define WaitMacro(bpp) \
void WaitTillIdle##bpp##(AF_DRIVER *af)           \
{                                                 \
  if (need_wait) {                                \
    outportb(GRX,0x31);                           \
    while (inportb(GRX+1)&1);                     \
    need_wait=0;                                  \
  }                                               \
  SET_FG##bpp##(0);                               \
}

WaitMacro(8)
WaitMacro(16)
WaitMacro(24)
WaitMacro(32)

#define WaitMacroMMIO(bpp)           \
void WaitTillIdle##bpp##MMIO(AF_DRIVER *af)       \
{                                                 \
  if (need_wait) {                                \
    while (inmb(0x40)&1);                         \
    need_wait=0;                                  \
  }                                               \
  SET_FG##bpp##MMIO(0);                           \
}

WaitMacroMMIO(8)
WaitMacroMMIO(16)
WaitMacroMMIO(24)
WaitMacroMMIO(32)


int af_mix_fore(int mix)
{
   switch (mix) {
     case AF_REPLACE_MIX:
       return CIR_ROP_COPY;
     case AF_AND_MIX:
       return CIR_ROP_AND;
     case AF_XOR_MIX:
       return CIR_ROP_XOR;
     case AF_OR_MIX:
       return CIR_ROP_OR;
     case AF_NOP_MIX:
       return CIR_ROP_NOP;
     default:
       return CIR_ROP_NOP;
   }
}

/* SetMix:
 *  Specifies the pixel mix mode to be used for hardware drawing functions
 *  (not the blit routines: they take an explicit mix parameter). Both
 *  parameters should both be one of the AF_mixModes enum defined in vbeaf.h.
 *
 *  VBE/AF requires all drivers to support the REPLACE, AND, OR, XOR,
 *  and NOP mix types. This file implements all the required types, but
 *  Allegro only actually uses the REPLACE and XOR modes for scanline and 
 *  rectangle fills, REPLACE mode for blitting and color pattern drawing,
 *  and either REPLACE or foreground REPLACE and background NOP for mono
 *  pattern drawing.
 *
 *  If you want, you can set the afHaveROP2 bit in the mode attributes
 *  field and then implement all the AF_R2_* modes as well, but that isn't
 *  required by the spec, and Allegro never uses them.
 */
void SetMix(AF_DRIVER *af, long foreMix, long backMix)
{
   af_fore_mix = foreMix;
   cir_bltrop=af_mix_fore(foreMix);
   if (backMix == AF_FORE_MIX)
      af_back_mix = foreMix;
   else
      af_back_mix = backMix;
   if (backMix == AF_NOP_MIX) //transparent
     cir_bltmode=CIR_BLT_TRANS|CIR_BLT_PATT|CIR_BLT_COLEXP|cir_pixmode;
   else
     cir_bltmode=CIR_BLT_PATT|CIR_BLT_COLEXP|cir_pixmode;
}


inline unsigned char rolb(unsigned char x, unsigned char count)
{
   asm volatile ("rolb %%cl,%b2":"=a" (x):"c" (count),"r" (x));
   return x;
}

unsigned char mono_pattern[16];
/* stored color pattern data */
unsigned long color_pattern[8][64];
unsigned long *current_color_pattern = color_pattern[0];

int last_mono_x,last_mono_y;
int last_color_x,last_color_y;


#define copymonomacro(mmio,bpp)        \
void copymonopattern##bpp####mmio##(AF_DRIVER *af,int x,int y)\
{                                                                       \
   int i;                                                               \
   unsigned char *p;                                                    \
									\
   SET_FG##bpp####mmio##(0);                                            \
   if ((last_mono_y!=(y&7))||(last_mono_x!=(x&7))) {                    \
     last_mono_y=y&7;                                                   \
     last_mono_x=x&7;                                                   \
   if (af_linear) {                                                     \
     p=af->LinearMem+af_memory-MONOPATTSTART;                           \
     for (i=0;i<8;i++)                                                  \
       p[i]=rolb(mono_pattern[i+last_mono_y],last_mono_x);              \
   } else {                                                             \
     p=af->BankedMem+DISPLACEMENT-MONOPATTSTART;                        \
     SetBank(af,af_last_bank);                                          \
     for (i=0;i<8;i++)                                                  \
       p[i]=rolb(mono_pattern[i+last_mono_y],last_mono_x);              \
     cir_bltmode|=CIR_BLT_COLEXP;                                       \
   }                                                                    \
   }                                                                    \
}

copymonomacro(,8)
copymonomacro(,16)
copymonomacro(,24)
copymonomacro(,32)

copymonomacro(MMIO,8)
copymonomacro(MMIO,16)
copymonomacro(MMIO,24)
copymonomacro(MMIO,32)

#define copycolormacro(mmio,bpp)       \
void copycolorpattern##bpp####mmio##(AF_DRIVER *af,int x,int y)        \
{                                                                      \
  int i,j;                                                             \
								       \
  SET_FG##bpp####mmio##(0);                                      \
  if ((last_color_y!=(y&7))||(last_color_x!=(x&7))) {                  \
    last_color_y=y&7;                                                  \
    last_color_x=x&7;                                                  \
    switch (bpp) {                                                     \
      case 8:                                                          \
	if (af_linear) {                                               \
	  unsigned char *p=af->LinearMem+af_memory-COLPATTSTART;       \
								       \
	  for (i=0;i<8;i++)                                            \
	    for (j=0;j<8;j++)                                          \
	      p[i*8+j]=current_color_pattern[((i+last_color_y)&7)*8+((j+last_color_x)&7)];\
	  break;                                                       \
	} else {                                                       \
	  unsigned char *p=af->BankedMem+DISPLACEMENT-COLPATTSTART;    \
								       \
	  SetBank(af,af_last_bank);                                    \
	  for (i=0;i<8;i++)                                            \
	    for (j=0;j<8;j++)                                          \
	      p[i*8+j]=current_color_pattern[((i+last_color_y)&7)*8+((j+last_color_x)&7)];\
	  break;                                                       \
	}                                                              \
      case 15:                                                         \
      case 16:                                                         \
	if (af_linear) {                                               \
	  unsigned short *p=af->LinearMem+af_memory-COLPATTSTART;      \
								       \
	  for (i=0;i<8;i++)                                            \
	    for (j=0;j<8;j++)                                          \
	      p[i*8+j]=current_color_pattern[((i+last_color_y)&7)*8+((j+last_color_x)&7)];\
	  break;                                                       \
	} else {                                                       \
	  unsigned short *p=af->BankedMem+DISPLACEMENT-COLPATTSTART;   \
								       \
	  SetBank(af,af_last_bank);                                    \
	  for (i=0;i<8;i++)                                            \
	    for (j=0;j<8;j++)                                          \
	      p[i*8+j]=current_color_pattern[((i+last_color_y)&7)*8+((j+last_color_x)&7)];\
	  break;                                                       \
       }                                                               \
      case 24:                                                         \
	if (af_linear) {                                               \
	  unsigned char *p=af->LinearMem+af_memory-COLPATTSTART;       \
								       \
	  for (i=0;i<8;i++)                                            \
	    for (j=0;j<8;j++)                                          \
	      *((unsigned long *)(((unsigned char *)p)+(i*8+j)*3))=current_color_pattern[((i+last_color_y)&7)*8+((j+last_color_x)&7)];\
	  break;                                                       \
	} else {                                                       \
	  unsigned char *p=af->BankedMem+DISPLACEMENT-COLPATTSTART;    \
								       \
	  SetBank(af,af_last_bank);                                    \
	  for (i=0;i<8;i++)                                            \
	    for (j=0;j<8;j++)                                          \
	      *((unsigned long *)(((unsigned char *)p)+(i*8+j)*3))=current_color_pattern[((i+last_color_y)&7)*8+((j+last_color_x)&7)];\
	  break;                                                       \
	}                                                              \
      case 32:                                                         \
	if (af_linear) {                                               \
	  unsigned long *p=af->LinearMem+af_memory-COLPATTSTART;       \
								       \
	  for (i=0;i<8;i++)                                            \
	    for (j=0;j<8;j++)                                          \
	      p[i*8+j]=current_color_pattern[((i+last_color_y)&7)*8+((j+last_color_x)&7)];\
	  break;                                                       \
	} else {                                                       \
	  unsigned long *p=af->BankedMem+DISPLACEMENT-COLPATTSTART;    \
								       \
	  SetBank(af,af_last_bank);                                    \
	  for (i=0;i<8;i++)                                            \
	    for (j=0;j<8;j++)                                          \
	      p[i*8+j]=current_color_pattern[((i+last_color_y)&7)*8+((j+last_color_x)&7)];\
	  break;                                                       \
	}                                                              \
      }                                                                \
    cir_bltmode&=~CIR_BLT_COLEXP;                                      \
  }                                                                    \
}

copycolormacro(,8)
copycolormacro(,16)
copycolormacro(,24)
copycolormacro(,32)

copycolormacro(MMIO,8)
copycolormacro(MMIO,16)
copycolormacro(MMIO,24)
copycolormacro(MMIO,32)

/* Set8x8MonoPattern:
 *  Downloads a monochrome (packed bit) pattern, for use by the 
 *  DrawPattScan() and DrawPattRect() functions. This is always sized
 *  8x8, and aligned with the top left corner of video memory: if other
 *  alignments are desired, the pattern will be prerotated before it 
 *  is passed to this routine.
 */
void Set8x8MonoPattern(AF_DRIVER *af, unsigned char *pattern)
{
   int i;

   last_mono_x=last_mono_y=-1;
   for (i=0;i<16;i++)
     mono_pattern[i]=pattern[i&7];
}

/* Set8x8ColorPattern:
 *  Downloads a color pattern, for use by the DrawColorPattScan() and
 *  DrawColorPattRect() functions. This is always sized 8x8, and aligned
 *  with the top left corner of video memory: if other alignments are
 *  desired, the pattern will be prerotated before it is passed to this
 *  routine. The color values are presented in the native format for
 *  the current video mode, but padded to 32 bits (so the pattern is
 *  always an 8x8 array of longs).
 *
 *  VBE/AF supports 8 different color patterns, which may be downloaded
 *  individually and then selected for use with the Use8x8ColorPattern()
 *  function. If the card is not able to cache these patterns in hardware,
 *  the driver is responsible for storing them internally and downloading
 *  the appropriate data when Use8x8ColorPattern() is called.
 *
 *  Allegro only actually ever uses the first of these patterns, so
 *  you only need to bother about this if you want your code to work
 *  with other programs as well.
 */
void Set8x8ColorPattern(AF_DRIVER *af, int index, unsigned long *pattern)
{
   int i;

   for (i=0; i<64; i++)
      color_pattern[index][i] = pattern[i];
}



/* Use8x8ColorPattern:
 *  Selects one of the patterns previously downloaded by Set8x8ColorPattern().
 */
void Use8x8ColorPattern(AF_DRIVER *af, int index)
{
  last_color_x=last_color_y=-1;
  current_color_pattern=color_pattern[index];
}

/* DrawScan:
 *  Fills a scanline in the current foreground mix mode. Draws up to but
 *  not including the second x coordinate. If the second coord is less
 *  than the first, they are swapped. If they are equal, nothing is drawn.
 */
#define DrawScanMacro(mmio,bpp)\
void DrawScan##bpp####mmio##(AF_DRIVER *af, long color, long y, long x1, long x2)\
{                                             \
   if (x2 < x1) {                             \
      int tmp = x1;                           \
      x1 = x2;                                \
      x2 = tmp;                               \
   }                                          \
					      \
   y += af_active_page*af_height;             \
   waitidle##mmio##();                                \
   need_wait=1;                               \
   SET_ROP_MODE(cir_bltrop,cir_bltmode);      \
   SET_FG##bpp####mmio##(color);              \
   SET_WIDTH_HEIGHT##mmio##((x2-x1)*(bpp/8)-1,0);\
   SET_DSTADDR##mmio##(y*af_width+x1*(bpp/8));\
   SET_SRCADDR##mmio##(cir_offscreen);        \
   CIR_CMD(CIR_CMD_RUN);                      \
}

DrawScanMacro(,8)
DrawScanMacro(,16)
DrawScanMacro(,24)
DrawScanMacro(,32)

DrawScanMacro(MMIO,8)
DrawScanMacro(MMIO,16)
DrawScanMacro(MMIO,24)
DrawScanMacro(MMIO,32)

/* DrawPattScan:
 *  Fills a scanline using the current mono pattern. Set pattern bits are
 *  drawn using the specified foreground color and the foreground mix
 *  mode, and clear bits use the background color and background mix mode.
 */
#define DrawPattScanMacro(mmio,bpp)\
void DrawPattScan##bpp####mmio##(AF_DRIVER *af, long foreColor, long backColor, long y, long x1, long x2)\
{                                            \
   if (x2 < x1) {                            \
      int tmp = x1;                          \
      x1 = x2;                               \
      x2 = tmp;                              \
   }                                         \
					     \
   y += af_active_page*af_height;            \
   waitidle##mmio##();                       \
   copymonopattern##bpp####mmio##(af,x1,y);  \
   need_wait=1;                              \
   SET_ROP_MODE(cir_bltrop,cir_bltmode);     \
   SET_FG##bpp####mmio##(foreColor);         \
   SET_BG##bpp####mmio##(backColor);         \
   SET_WIDTH_HEIGHT##mmio##((x2-x1)*(bpp/8)-1,0);\
   SET_DSTADDR##mmio##(y*af_width+x1*(bpp/8));\
   SET_SRCADDR##mmio##(cir_offmono);         \
   CIR_CMD(CIR_CMD_RUN);                     \
}

DrawPattScanMacro(,8)
DrawPattScanMacro(,16)
DrawPattScanMacro(,24)
DrawPattScanMacro(,32)

DrawPattScanMacro(MMIO,8)
DrawPattScanMacro(MMIO,16)
DrawPattScanMacro(MMIO,24)
DrawPattScanMacro(MMIO,32)

/* DrawColorPattScan:
 *  Fills a scanline using the current color pattern and mix mode.
 */
#define DrawColorPattScanMacro(mmio,bpp)\
void DrawColorPattScan##bpp####mmio##(AF_DRIVER *af, long y, long x1, long x2)\
{                                            \
   if (x2 < x1) {                            \
      int tmp = x1;                          \
      x1 = x2;                               \
      x2 = tmp;                              \
   }                                         \
					     \
   y += af_active_page*af_height;            \
   waitidle##mmio##();                               \
   copycolorpattern##bpp####mmio##(af,x1,y); \
   need_wait=1;                              \
   SET_ROP_MODE##mmio##(cir_bltrop,cir_bltmode);\
   SET_WIDTH_HEIGHT##mmio##((x2-x1)*(bpp/8)-1,0);\
   SET_DSTADDR##mmio##(y*af_width+x1*(bpp/8));\
   SET_SRCADDR##mmio##(cir_offcolor);        \
   CIR_CMD(CIR_CMD_RUN);                     \
}

DrawColorPattScanMacro(,8)
DrawColorPattScanMacro(,16)
DrawColorPattScanMacro(,24)
DrawColorPattScanMacro(,32)

DrawColorPattScanMacro(MMIO,8)
DrawColorPattScanMacro(MMIO,16)
DrawColorPattScanMacro(MMIO,24)
DrawColorPattScanMacro(MMIO,32)

/* DrawRect:
 *  Fills a rectangle in the current foreground mix mode.
 */
#define DrawRectMacro(mmio,bpp)\
void DrawRect##bpp####mmio##(AF_DRIVER *af, unsigned long color, long left, long top, long width, long height)\
{                                            \
   top += af_active_page*af_height;          \
   waitidle##mmio##();                               \
   need_wait=1;                              \
   SET_ROP_MODE##mmio##(cir_bltrop,cir_bltmode);\
   SET_FG##bpp####mmio##((int)color);             \
   SET_WIDTH_HEIGHT##mmio##(width*(bpp/8)-1,height-1);\
   SET_DSTADDR##mmio##(top*af_width+left*(bpp/8));\
   SET_SRCADDR##mmio##(cir_offscreen);       \
   CIR_CMD(CIR_CMD_RUN);                     \
}

DrawRectMacro(,8)
DrawRectMacro(,16)
DrawRectMacro(,24)
DrawRectMacro(,32)

DrawRectMacro(MMIO,8)
DrawRectMacro(MMIO,16)
DrawRectMacro(MMIO,24)
DrawRectMacro(MMIO,32)

/* DrawPattRect:
 *  Fills a rectangle using the current mono pattern. Set pattern bits are
 *  drawn using the specified foreground color and the foreground mix
 *  mode, and clear bits use the background color and background mix mode.
 */
#define DrawPattRectMacro(mmio,bpp)\
void DrawPattRect##bpp####mmio##(AF_DRIVER *af, unsigned long foreColor, unsigned long backColor, long left, long top, long width, long height)\
{                                            \
   top += af_active_page*af_height;          \
   waitidle##mmio##();                               \
   copymonopattern##bpp####mmio##(af,left,top);\
   need_wait=1;                              \
   SET_ROP_MODE##mmio##(cir_bltrop,cir_bltmode);\
   SET_FG##bpp####mmio##((int)foreColor);     \
   SET_BG##bpp####mmio##((int)backColor);     \
   SET_WIDTH_HEIGHT##mmio##(width*(bpp/8)-1,height-1);\
   SET_DSTADDR##mmio##(top*af_width+left*(bpp/8));\
   SET_SRCADDR##mmio##(cir_offmono);         \
   CIR_CMD(CIR_CMD_RUN);                     \
}

DrawPattRectMacro(,8)
DrawPattRectMacro(,16)
DrawPattRectMacro(,24)
DrawPattRectMacro(,32)

DrawPattRectMacro(MMIO,8)
DrawPattRectMacro(MMIO,16)
DrawPattRectMacro(MMIO,24)
DrawPattRectMacro(MMIO,32)

/* DrawColorPattRect:
 *  Fills a rectangle using the current color pattern and mix mode.
 */
#define DrawColorPattRectMacro(mmio,bpp)\
void DrawColorPattRect##bpp####mmio##(AF_DRIVER *af, long left, long top, long width, long height)\
{                                            \
   top += af_active_page*af_height;          \
   waitidle##mmio##();                               \
   copycolorpattern##bpp####mmio##(af,left,top);\
   need_wait=1;                              \
   SET_ROP_MODE##mmio##(cir_bltrop,cir_bltmode);\
   SET_WIDTH_HEIGHT##mmio##(width*(bpp/8)-1,height-1);\
   SET_DSTADDR##mmio##(top*af_width+left*(bpp/8));\
   SET_SRCADDR##mmio##(cir_offcolor);        \
   CIR_CMD(CIR_CMD_RUN);                     \
}

DrawColorPattRectMacro(,8)
DrawColorPattRectMacro(,16)
DrawColorPattRectMacro(,24)
DrawColorPattRectMacro(,32)

DrawColorPattRectMacro(MMIO,8)
DrawColorPattRectMacro(MMIO,16)
DrawColorPattRectMacro(MMIO,24)
DrawColorPattRectMacro(MMIO,32)

/* BitBlt:
 *  Blits from one part of video memory to another, using the specified
 *  mix operation. This must correctly handle the case where the two
 *  regions overlap.
 */
#define BitBltMacro(mmio,bpp,pixmode)\
void BitBlt##bpp####mmio##(AF_DRIVER *af, long left, long top, long width, long height, long dstLeft, long dstTop, long op)\
{                                            \
  unsigned long pdst,psrc;                   \
  int bltmode=pixmode,bltrop;                \
					     \
  top += af_active_page*af_height;           \
  dstTop += af_active_page*af_height;        \
  waitidle##mmio##();                                \
  width*=(bpp/8);width--;height--;           \
  left*=(bpp/8);dstLeft*=(bpp/8);            \
  need_wait=1;                               \
  if ((dstTop>top)||((top==dstTop)&&(dstLeft>left))) {\
    psrc = (((top + height) * af_width) + left + width);\
    pdst = (((dstTop + height) * af_width) + dstLeft + width);\
    bltmode|=CIR_BLT_BACK;                   \
  } else {                                   \
    psrc = ((top * af_width) + left);        \
    pdst = ((dstTop * af_width) + dstLeft);  \
  }                                          \
  SET_WIDTH_HEIGHT##mmio##(width,height);    \
  SET_SRCADDR##mmio##(psrc);                 \
  SET_DSTADDR##mmio##(pdst);                 \
  bltrop=af_mix_fore(op);                    \
  SET_ROP_MODE##mmio##(bltrop,bltmode);      \
  CIR_CMD(CIR_CMD_RUN);                      \
}

BitBltMacro(,8,CIR_BLT_PIX8)
BitBltMacro(,16,CIR_BLT_PIX16)
BitBltMacro(,24,CIR_BLT_PIX24)
BitBltMacro(,32,CIR_BLT_PIX32)

BitBltMacro(MMIO,8,CIR_BLT_PIX8)
BitBltMacro(MMIO,16,CIR_BLT_PIX16)
BitBltMacro(MMIO,24,CIR_BLT_PIX24)
BitBltMacro(MMIO,32,CIR_BLT_PIX32)

/* SrcTransBlt:
 *  Blits from one part of video memory to another, using the specified
 *  mix operation and skipping any source pixels which match the specified
 *  transparent color. Results are undefined if the two regions overlap.
 */
#define SrcTransBltMacro(mmio,bpp,pixmode)\
void SrcTransBlt##bpp####mmio##(AF_DRIVER *af, long left, long top, long width, long height, long dstLeft, long dstTop, long op, unsigned long transparent)\
{                                            \
  unsigned long pdst,psrc;                   \
  int bltmode=pixmode|CIR_BLT_TRANS,bltrop;  \
					     \
  top += af_active_page*af_height;           \
  dstTop += af_active_page*af_height;        \
  waitidle##mmio##();                                \
  width*=(bpp/8);width--;height--;           \
  left*=(bpp/8);dstLeft*=(bpp/8);            \
  need_wait=1;                               \
  if ((dstTop>top)||((top==dstTop)&&(dstLeft>left))) {\
    psrc = (((top + height) * af_width) + left + width);\
    pdst = (((dstTop + height) * af_width) + dstLeft + width);\
    bltmode|=CIR_BLT_BACK;                   \
  } else {                                   \
    psrc = ((top * af_width) + left);        \
    pdst = ((dstTop * af_width) + dstLeft);  \
  }                                          \
  SET_TRANS##mmio##((int)transparent);                \
  SET_WIDTH_HEIGHT##mmio##(width,height);    \
  SET_SRCADDR##mmio##(psrc);                 \
  SET_DSTADDR##mmio##(pdst);                 \
  bltrop=af_mix_fore(op);                    \
  SET_ROP_MODE##mmio##(bltrop,bltmode);      \
  CIR_CMD(CIR_CMD_RUN);                      \
}

SrcTransBltMacro(,8,CIR_BLT_PIX8)
SrcTransBltMacro(,16,CIR_BLT_PIX16)
SrcTransBltMacro(,24,CIR_BLT_PIX24)
SrcTransBltMacro(,32,CIR_BLT_PIX32)

SrcTransBltMacro(MMIO,8,CIR_BLT_PIX8)
SrcTransBltMacro(MMIO,16,CIR_BLT_PIX16)
SrcTransBltMacro(MMIO,24,CIR_BLT_PIX24)
SrcTransBltMacro(MMIO,32,CIR_BLT_PIX32)

int hw_cur_x=0,hw_cur_y=0;

void SetCursor(AF_DRIVER *af, AF_CURSOR *cursor)
{
  int i,j;
  unsigned long *p,andMask,xorMask;

  af->WaitTillIdle(af);
  alter_vga_register(0x3c4,0x12,3,0);
  write_vga_register(0x3d4,11,0x24);
  if (af_linear)
    p=af->LinearMem+af_memory-CURSORSTART;
  else {
    p=af->BankedMem+DISPLACEMENT-CURSORSTART;
    SetBank(af,af_last_bank);
  }
  for (i=0;i<32;i++) {
    andMask=xorMask=0;
    for (j=0;j<32;j++) {
      if (cursor->andMask[i]&(1<<j)) {
	if (cursor->xorMask[i]&(1<<j)) {
	  andMask|=(1<<j);//foreground
	  xorMask|=(1<<j);
	}else {
	  xorMask|=(1<<j);//background
	}
      } else
	if (cursor->xorMask[i]&(1<<j))
	  andMask|=(1<<j);//inverted
    }
    *p=andMask;
    p[32]=xorMask;
    p++;
  }
  hw_cur_x=cursor->hotx;
  hw_cur_y=cursor->hoty;
  write_vga_register(0x3c4,0x13,0x38);
  if (cir_cursor_visible)
    alter_vga_register(0x3c4,0x12,1,1);
}

void SetCursorPos(AF_DRIVER *af, long x, long y)
{
  x-=hw_cur_x;
  if (x<0) x=0;
  y-=hw_cur_y;
  if (y<0) y=0;
  __asm__ (
  "movw $0x3c4,%%dx
   outw %%ax,%%dx
   movw %%bx,%%ax
   outw %%ax,%%dx"
  :
  :"a" ((x<<5)+0x10),"b" ((y<<5)+0x11)
  :"%dx");
}

void SetCursorColor(AF_DRIVER *af, unsigned char red, unsigned char green, unsigned char blue)
{
  alter_vga_register(0x3c4,0x12,2,2);//index 12 - enable access to extended DAC palette entries
  if (af_bpp==8) {
    mouse_fg=red;
    outportb(0x3c8,0xf);//cursor foreground
    outportb(0x3c9,af_pal[mouse_fg].red);
    outportb(0x3c9,af_pal[mouse_fg].green);
    outportb(0x3c9,af_pal[mouse_fg].blue); 
    outportb(0x3c8,0);//cursor background
    outportb(0x3c9,af_pal[0].red);
    outportb(0x3c9,af_pal[0].green);
    outportb(0x3c9,af_pal[0].blue);
  } else {
    outportb(0x3c8,0xf);//cursor foreground
    outportb(0x3c9,red);
    outportb(0x3c9,green);
    outportb(0x3c9,blue); 
    outportb(0x3c8,0);//cursor background
    outportb(0x3c9,0);
    outportb(0x3c9,0);
    outportb(0x3c9,0);
  }
  alter_vga_register(0x3c4,0x12,2,0);//index 12 - disable access to extended DAC palette entries
}

void ShowCursor(AF_DRIVER *af, long visible)
{
  if (visible) {
    alter_vga_register(0x3c4,0x12,5,1);
    cir_cursor_visible=1;
  } else {
    alter_vga_register(0x3c4,0x12,5,0);
    cir_cursor_visible=0;
  }
}

#define BitBltSysMacro(mmio,bpp,pixmode) \
void BitBltSys##bpp####mmio##(AF_DRIVER *af, void *srcAddr, long srcPitch, long srcLeft, long srcTop, long width, long height, long dstLeft, long dstTop, long op)\
{                                                                  \
  unsigned long pdst;                                              \
  int bltmode=pixmode,bltrop;                                      \
								   \
  width*=(bpp/8);width--;height--;                                 \
  srcLeft*=(bpp/8);dstLeft*=(bpp/8);                               \
  waitidle##mmio##();                                                      \
  need_wait=1;                                                     \
  dstTop += af_active_page*af_height;                              \
  pdst = dstTop * af_width + dstLeft;                              \
  SET_WIDTH_HEIGHT##mmio##(width,height);                          \
  SET_SRCADDR##mmio##(0);                                          \
  SET_DSTADDR##mmio##(pdst);                                       \
  bltrop=af_mix_fore(op);                                          \
  bltmode|=CIR_BLT_MEM;                                            \
  SET_ROP_MODE##mmio##(bltrop,bltmode);                            \
  CIR_CMD(CIR_CMD_RUN);                                            \
  width++;height++;                                                \
  __asm__ __volatile__ ("\
      cld;\
  1:;\
      pushl %%edi;\
      pushl %%ecx;\
      rep; movsl;\
      movsw;\
      movsw;\
      popl  %%ecx;\
      addl  %%ebx,%%esi;\
      popl  %%edi;\
      decl  %%edx;\
      jnz   1b\
      "\
      ::"S" (srcAddr+srcTop*srcPitch+srcLeft), "D" (af_linear?af->LinearMem:af->BankedMem),  "b" (srcPitch-((width-1)&0xfffffffc)-4), "c" ((width-1)>>2), "d" (height)\
      :"eax","ebx","ecx","edx","esi","edi","cc"\
      );\
}

BitBltSysMacro(,8,CIR_BLT_PIX8)
BitBltSysMacro(,16,CIR_BLT_PIX16)
BitBltSysMacro(,24,CIR_BLT_PIX24)
BitBltSysMacro(,32,CIR_BLT_PIX32)

BitBltSysMacro(MMIO,8,CIR_BLT_PIX8)
BitBltSysMacro(MMIO,16,CIR_BLT_PIX16)
BitBltSysMacro(MMIO,24,CIR_BLT_PIX24)
BitBltSysMacro(MMIO,32,CIR_BLT_PIX32)

#define SrcTransBltSysMacro(mmio,bpp,pixmode)\
void SrcTransBltSys##bpp####mmio##(AF_DRIVER *af, void *srcAddr, long srcPitch, long srcLeft, long srcTop, long width, long height, long dstLeft, long dstTop, long op, unsigned long transparent)\
{                                         \
  unsigned long pdst;                     \
  int bltmode,bltrop;                     \
					  \
  width*=(bpp/8);width--;height--;        \
  srcLeft*=(bpp/8);dstLeft*=(bpp/8);      \
  waitidle##mmio##();                             \
  need_wait=1;                            \
  dstTop += af_active_page*af_height;     \
  pdst = dstTop * af_width + dstLeft;     \
  bltrop=af_mix_fore(op);                 \
  bltmode=CIR_BLT_MEM|CIR_BLT_TRANS|pixmode;\
  SET_ROP_MODE##mmio##(bltrop,bltmode);   \
  SET_WIDTH_HEIGHT##mmio##(width,height); \
  SET_TRANS##mmio##((int)transparent);     \
  SET_SRCADDR##mmio##(0);                 \
  SET_DSTADDR##mmio##(pdst);              \
  CIR_CMD(CIR_CMD_RUN);                   \
  width++;height++;                       \
  __asm__ __volatile__ ("                 \
      cld;                                \
  1:;                                     \
      pushl %%edi;                        \
      pushl %%ecx;                        \
      rep; movsl;                         \
      movsw;                              \
      movsw;                              \
      popl  %%ecx;                        \
      addl  %%ebx,%%esi;                  \
      popl  %%edi;                        \
      decl  %%edx;                        \
      jnz   1b;                           \
      "                                   \
      :                                   \
      :"S" (srcAddr+srcTop*srcPitch+srcLeft), "D" (af_linear?af->LinearMem:af->BankedMem),  "b" (srcPitch-((width-1)&0xfffffffc)-4), "c" ((width-1)>>2), "d" (height)\
      :"eax","ebx","ecx","edx","esi","edi","cc"\
      );                                  \
}

SrcTransBltSysMacro(,8,CIR_BLT_PIX8)
SrcTransBltSysMacro(,16,CIR_BLT_PIX16)
SrcTransBltSysMacro(,24,CIR_BLT_PIX24)
SrcTransBltSysMacro(,32,CIR_BLT_PIX32)

SrcTransBltSysMacro(MMIO,8,CIR_BLT_PIX8)
SrcTransBltSysMacro(MMIO,16,CIR_BLT_PIX16)
SrcTransBltSysMacro(MMIO,24,CIR_BLT_PIX24)
SrcTransBltSysMacro(MMIO,32,CIR_BLT_PIX32)

inline void shiftleft(unsigned char *line,int bytes,unsigned char bits)
{
  asm("
	movb  $8,%%ch
	addb  %%cl,%%ch
	movb  %%dl,%%al
1:
	movb  (%%esi),%%ah
	andl  $0xffff,%%eax
	shll  %%cl,%%eax
	movb  %%ah,(%%esi)
	xchgb %%ch,%%cl
	shrl  %%cl,%%eax
	decl  %%esi
	xchgb %%ch,%%cl
	decl  %%ebx
	jnz 1b"
	::"S" (line+bytes-1), "c" ((bits&31)|((32-(bits&31))<<8)), "d" (0), "b" (bytes));
}

unsigned char lines[1024];

#define PutMonoImageMacro(mmio,bpp,pixmode)\
void PutMonoImage##bpp####mmio##(AF_DRIVER *af, long foreColor, long backColor, long dstX, long dstY, long byteWidth, long srcX, long srcY, long width, long height, unsigned char *image)\
{                                              \
  unsigned long pdst;                          \
  int i,j,bytelen=(width+7)/8;                 \
  int bltmode=CIR_BLT_MEM|CIR_BLT_COLEXP|pixmode;\
					       \
					       \
  if (width*8==byteWidth) {                    \
    for (i=0;i<byteWidth*height;i++) lines[i]=image[i];\
  } else {                                     \
    for (i=0;i<height;i++) {                   \
      for (j=0;j<bytelen;j++)                  \
	lines[i*bytelen+j]=image[(i+srcY)*byteWidth+j+(srcX/8)];\
      if (srcX&7)                              \
	shiftleft(lines+i*bytelen,bytelen,srcX&7);\
    }                                          \
  }                                            \
					       \
  width*=(bpp/8);width--;                      \
  dstX*=(bpp/8);                               \
  waitidle##mmio##();                          \
  need_wait=1;                                 \
  dstY += af_active_page*af_height;            \
  pdst = dstY * af_width + dstX;               \
  if (cir_bltmode&CIR_BLT_TRANS) {             \
    if (backColor==foreColor)                  \
      backColor=!backColor;                    \
    bltmode |= CIR_BLT_TRANS;                  \
    if ((bpp/8)==1) {                          \
      backColor|=backColor<<8;                 \
      SET_TRANS##mmio##(backColor);            \
      backColor&=0xff;                         \
    } else                                     \
      SET_TRANS(backColor);                    \
  }                                            \
  SET_BG##bpp####mmio##(backColor);            \
  SET_ROP_MODE##mmio##(cir_bltrop,bltmode);    \
  SET_FG##bpp####mmio##(foreColor);            \
  SET_WIDTH_HEIGHT##mmio##(width,height-1);    \
  SET_SRCADDR##mmio##(0);                      \
  SET_DSTADDR##mmio##(pdst);                   \
  CIR_CMD(CIR_CMD_RUN);                        \
  __asm__ __volatile__ ("                      \
      cld;                                     \
      rep; movsl;                              \
      "                                        \
      :                                        \
      :"S" (lines), "D" (af_linear?af->LinearMem:af->BankedMem), "c" ((height*bytelen+3)/4), "d" (height)\
      :"eax","ecx","edx","esi","edi","cc"      \
      );                                       \
}

PutMonoImageMacro(,8,CIR_BLT_PIX8)
PutMonoImageMacro(,16,CIR_BLT_PIX16)
PutMonoImageMacro(,24,CIR_BLT_PIX24)
PutMonoImageMacro(,32,CIR_BLT_PIX32)

PutMonoImageMacro(MMIO,8,CIR_BLT_PIX8)
PutMonoImageMacro(MMIO,16,CIR_BLT_PIX16)
PutMonoImageMacro(MMIO,24,CIR_BLT_PIX24)
PutMonoImageMacro(MMIO,32,CIR_BLT_PIX32)

/* SetupDriver:
 *  The first thing ever to be called after our code has been relocated.
 *  This is in charge of filling in the driver header with all the required
 *  information and function pointers. We do not yet have access to the
 *  video memory, so we can't talk directly to the card.
 */

#define SetupMacro(mmio,bpp)\
void SetupFuncPtr##bpp####mmio##(AF_DRIVER *af)\
{\
   af->DrawScan = DrawScan##bpp####mmio##;\
   af->DrawPattScan = DrawPattScan##bpp####mmio##;\
   af->DrawColorPattScan = DrawColorPattScan##bpp####mmio##;\
   af->DrawRect = DrawRect##bpp####mmio##;\
   af->DrawPattRect = DrawPattRect##bpp####mmio##;\
   af->DrawColorPattRect = DrawColorPattRect##bpp####mmio##;\
   af->BitBlt = BitBlt##bpp####mmio##;\
   af->BitBltSys = BitBltSys##bpp####mmio##;\
   af->SrcTransBlt = SrcTransBlt##bpp####mmio##;\
   af->SrcTransBltSys = SrcTransBltSys##bpp####mmio##;\
   af->WaitTillIdle = WaitTillIdle##bpp####mmio##;\
   af->PutMonoImage = PutMonoImage##bpp####mmio##;\
}


SetupMacro(,8);
SetupMacro(,16);
SetupMacro(,24);
SetupMacro(,32);

SetupMacro(MMIO,8);
SetupMacro(MMIO,16);
SetupMacro(MMIO,24);
SetupMacro(MMIO,32);

int SetupDriver(AF_DRIVER *af)
{
   RM_REGS regs;
   int i,j,card,bus_type=0;

   regs.x.ax=0x1200;  //cirrus extended bios
   regs.x.bx=0x80;    //get chip version
   rm_int(0x10,&regs);
   card=regs.h.al;
   for (i=0;i<KNOWN_CARDS;i++)
     if (card==detect_info[i].biosnum) {
       cir_card=i;
       break;
     }
   if (cir_card==-1)
     return -1;
   regs.x.ax=0x1200;  //cirrus extended bios
   regs.x.bx=0x85;    //get available memory
   rm_int(0x10, &regs);
   af_memory=(regs.h.al<<6)*1024;
   af->TotalMemory=(af_memory-RESERVED_VRAM)/1024;
   if (!detect_info[cir_card].pcinum)
     goto pcinotfound;
   regs.x.ax = 0xB101;
   rm_int(0x1A, &regs);
   if (regs.h.ah)
     goto pcinotfound;
   regs.x.ax = 0xB102;
   regs.x.cx = detect_info[cir_card].pcinum;
   regs.x.dx = CIRRUS_PCI_VENDOR_ID;
   regs.x.si = 0;
   rm_int(0x1A, &regs);
   if (regs.h.ah)
     goto pcinotfound;
   bus_type=regs.x.bx;
   af->PCIVendorID=CIRRUS_PCI_VENDOR_ID;
   af->PCIDeviceID=detect_info[cir_card].pcinum;
   regs.x.bx = bus_type;
   regs.x.ax = 0xB10A;
   regs.x.di = 16;
   rm_int(0x1A, &regs);
   linear_addr = regs.d.ecx & 0xff000000;
pcinotfound:

   i=j=0;
   while (mode_list[i].w!=0) {
     regs.h.ah=0x12;/*cirrus bios extensions*/
     regs.h.al=mode_list[i].num;
     regs.d.ebx=0xA0;/*get availability of video mode*/
     rm_int(0x10,&regs);
     if ((regs.h.ah&1)&&(mode_list[i].bpp<24||(mode_list[i].bpp==24
	 &&cir_useblt24)||(mode_list[i].bpp==32&&cir_useblt32))) {
       available_modes[j++]=i+1;
     }
     i++;
   }
   num_modes=i;
   available_modes[j]=-1;

   /* pointer to a list of the available mode numbers, ended by -1.
    * Our mode numbers just count up from 1, so the mode numbers can
    * be used as indexes into the mode_list[] table (zero is an
    * invalid mode number, so this indexing must be offset by 1).
    */
   af->AvailableModes = available_modes;

   /* driver attributes (see definitions in vbeaf.h) */
   af->Attributes = (afHaveMultiBuffer | 
		     afHaveVirtualScroll | 
		     afHaveBankedBuffer | 
		     afHaveAccel2D);
   af->Attributes |= afHaveHWCursor;

   if (linear_addr)
      af->Attributes |= afHaveLinearBuffer;

   /* banked memory size and location: zero if not supported */
   af->BankSize = 64;
   af->BankedBasePtr = 0xA0000;

   /* linear framebuffer size and location: zero if not supported */
   if (linear_addr) {
      af->LinearSize = af_memory/1024;
      af->LinearBasePtr = linear_addr;
   }
   else  {
      af->LinearSize = 0;
      af->LinearBasePtr = 0;
   }

   /* list which ports we are going to access (only needed under Linux) */
   af->IOPortsTable = ports_table;

   /* list physical memory regions that we need to access (zero for none) */
   for (i=0; i<4; i++) {
      af->IOMemoryBase[i] = 0;
      af->IOMemoryLen[i] = 0;
   }

#ifndef DISABLE_MMIO
   switch (detect_info[cir_card].family) {
     case 0:
       /* 5426, 5428 do not support MMIO */
       break;
     case 1:
       /* MMIO for 5429 -- could we support this card's linear framebuffer?? */
       af->IOMemoryBase[0] = 0xb8000;
       af->IOMemoryLen[0]  = 256;
       break;
     case 2:
     case 5:
       /* 5430,5436,5440,5446 */
	 if (linear_addr)
	     af->IOMemoryBase[0] = linear_addr+4*1024*1024-256;
	 else
	     af->IOMemoryBase[0] = 0xb8000;
	 af->IOMemoryLen[0] = 256;
       break;
     case 3:
     case 4:
       /* 5434 only allows MMIO at 0xb8000*/
       af->IOMemoryBase[0] = 0xb8000;
       af->IOMemoryLen[0]  = 256;
       break;
     case 6:
       /* 5480 */
     /* if (linear_addr&&bus_type) {
	 regs.x.ax = 0xB102;
	 regs.x.bx=bus_type;
	 if (regs.h.ah)
	   goto pcinotfound;
	 regs.x.ax = 0xB102;
	 regs.x.cx = detect_info[cir_card].pcinum;
	 regs.x.dx = CIRRUS_PCI_VENDOR_ID;
	 regs.x.di = 32;
	 rm_int(0x1A, &regs);
	 if (regs.h.al) //should never occur
	   af->IOMemoryBase[0] = 0xb8000;
	 else
	   af->IOMemoryBase[0] = regs.d.ecx;
       } else*/
	 af->IOMemoryBase[0] = 0xb8000;
       af->IOMemoryLen[0] = 256;
       break;
   }
#endif

   /* driver state variables (initialised later during the mode set) */
   af->BufferEndX = 0;
   af->BufferEndY = 0;
   af->OriginOffset = 0;
   af->OffscreenOffset = 0;
   af->OffscreenStartY = 0;
   af->OffscreenEndY = 0;

   /* relocatable bank switcher (not required by Allgero) */
   af->SetBank32 = SetBank32;
   af->SetBank32Len = (long)SetBank32End - (long)SetBank32;

   /* extension functions */
   af->SupplementalExt = ExtStub;

   /* device driver functions */
   af->GetVideoModeInfo = GetVideoModeInfo;
   af->SetVideoMode = SetVideoMode;
   af->RestoreTextMode = RestoreTextMode;
   af->GetClosestPixelClock = GetClosestPixelClock;
   af->SaveRestoreState = SaveRestoreState;
   af->SetDisplayStart = SetDisplayStart;
   af->SetActiveBuffer = SetActiveBuffer;
   af->SetVisibleBuffer = SetVisibleBuffer;
   af->GetDisplayStartStatus = GetDisplayStartStatus;
   af->EnableStereoMode = NULL;
   af->SetPaletteData = SetPaletteData;
   af->SetGammaCorrectData = NULL;
   af->SetBank = SetBank;

   /* hardware cursor functions (not supported: not used by Allegro) */
   af->SetCursor = SetCursor;
   af->SetCursorPos = SetCursorPos;
   af->SetCursorColor = SetCursorColor;
   af->ShowCursor = ShowCursor;
   /* on some cards the CPU cannot access the framebuffer while it is in
    * hardware drawing mode. If this is the case, you should fill in these 
    * functions with routines to switch in and out of the accelerator mode. 
    * The application will call EnableDirectAccess() whenever it is about
    * to write to the framebuffer directly, and DisableDirectAccess() 
    * before it calls any hardware drawing routines. If this arbitration is 
    * not required, leave these routines as NULL.
    */
   af->EnableDirectAccess = NULL;
   af->DisableDirectAccess = NULL;

   /* sets the hardware drawing mode (solid, XOR, etc). Required. */
   af->SetMix = SetMix;

   /* pattern download functions. May be NULL if patterns not supported */
   af->Set8x8MonoPattern = Set8x8MonoPattern;
   af->Set8x8ColorPattern = Set8x8ColorPattern;
   af->Use8x8ColorPattern = Use8x8ColorPattern;

   /* not supported: not used by Allegro */
   af->DrawScanList = NULL;
   af->DrawPattScanList = NULL;
   af->DrawColorPattScanList = NULL;

   /* not supported: not used by Allegro */
   af->DrawLine = NULL;
   af->DrawStippleLine = NULL;
   af->DrawTrap = NULL;
   af->DrawTri = NULL;
   af->DrawQuad = NULL;

   af->BitBltLin = NULL;
   af->BitBltBM = NULL;

   af->PutMonoImageLin = NULL;
   af->PutMonoImageBM = NULL;

   /* not supported: not used by Allegro */
   af->SetLineStipple = NULL;
   af->SetLineStippleCount = NULL;

   /* not supported. There really isn't much point in this function because
    * a lot of hardware can't do clipping at all, and even when it can there
    * are usually problems with very large or negative coordinates. This
    * means that a software clip is still required, so you may as well
    * ignore this routine.
    */
   af->SetClipRect = NULL;

   af->SrcTransBltLin = NULL;
   af->SrcTransBltBM = NULL;
   af->DstTransBlt = NULL;
   af->DstTransBltSys = NULL;
   af->DstTransBltLin = NULL;
   af->DstTransBltBM = NULL;
   af->StretchBlt = NULL;
   af->StretchBltSys = NULL;
   af->StretchBltLin = NULL;
   af->StretchBltBM = NULL;
   af->SrcTransStretchBlt = NULL;
   af->SrcTransStretchBltSys = NULL;
   af->SrcTransStretchBltLin = NULL;
   af->SrcTransStretchBltBM = NULL;
   af->DstTransStretchBlt = NULL;
   af->DstTransStretchBltSys = NULL;
   af->DstTransStretchBltLin = NULL;
   af->DstTransStretchBltBM = NULL;
   af->SetVideoInput = NULL;
   af->SetVideoOutput = NULL;
   af->StartVideoFrame = NULL;
   af->EndVideoFrame = NULL;

   SetupFuncPtr8(af);
   return 0;
}



/* InitDriver:
 *  The second thing to be called during the init process, after the 
 *  application has mapped all the memory and I/O resources we need.
 *  This is in charge of finding the card, returning 0 on success or
 *  -1 to abort.
 */
int InitDriver(AF_DRIVER *af)
{
   if (cir_card==-1)
     return -1;
   else
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



/* ExtStub:
 *  Vendor-specific extension hook: we don't provide any.
 */
int ExtStub()
{
   return 0;
}

/* GetVideoModeInfo:
 *  Retrieves information about this video mode, returning zero on success
 *  or -1 if the mode is invalid.
 */
long GetVideoModeInfo(AF_DRIVER *af, short mode, AF_MODE_INFO *modeInfo)
{
   _GFX_MODE_INFO *info;
   int i;

   if ((mode <= 0) || (mode > num_modes))
      return -1;

   for (i=0; i<(int)sizeof(AF_MODE_INFO); i++)
      ((char *)modeInfo)[i] = 0;

   info=&mode_list[mode-1];
   /* copy data across from our stored list of mode attributes */
   modeInfo->Attributes = (afHaveMultiBuffer | 
			   afHaveVirtualScroll | 
			   afHaveBankedBuffer | 
			   afHaveAccel2D);
   modeInfo->Attributes |= afHaveHWCursor;

   if (linear_addr)
      modeInfo->Attributes |= afHaveLinearBuffer;

   modeInfo->XResolution = info->w;
   modeInfo->YResolution = info->h;
   modeInfo->BitsPerPixel = info->bpp;

   /* available pages of video memory */
   modeInfo->MaxBuffers = (af->TotalMemory*1024) /
			  (info->bpl * info->h);

   /* maximum virtual scanline length in both bytes and pixels. How wide
    * this can go will very much depend on the card: 1024 is pretty safe
    * on anything, but you will want to allow larger limits if the card
    * is capable of them.
    */
   modeInfo->MaxBytesPerScanLine = 1024*BYTES_PER_PIXEL(info->bpp);
   modeInfo->MaxScanLineWidth = 1024;

   /* for banked video modes, fill in these variables: */
   modeInfo->BytesPerScanLine = info->bpl;
   modeInfo->BnkMaxBuffers = modeInfo->MaxBuffers;
   switch (info->bpp) {
     case 8:
       break;
     case 15:
       modeInfo->RedMaskSize = 5;
       modeInfo->RedFieldPosition = 10;
       modeInfo->GreenMaskSize = 5;
       modeInfo->GreenFieldPosition = 5;
       modeInfo->BlueMaskSize = 5;
       modeInfo->RsvdMaskSize = 1;
       modeInfo->RsvdFieldPosition = 15;
       break;
     case 16:
       modeInfo->RedMaskSize = 5;
       modeInfo->RedFieldPosition = 11;
       modeInfo->GreenMaskSize = 6;
       modeInfo->GreenFieldPosition = 5;
       modeInfo->BlueMaskSize = 5;
       break;
     case 24:
       modeInfo->RedMaskSize = 8;
       modeInfo->RedFieldPosition = 16;
       modeInfo->GreenMaskSize = 8;
       modeInfo->GreenFieldPosition = 8;
       modeInfo->BlueMaskSize = 8;
       break;
     case 32:
       modeInfo->RedMaskSize = 8;
       modeInfo->RedFieldPosition = 16;
       modeInfo->GreenMaskSize = 8;
       modeInfo->GreenFieldPosition = 8;
       modeInfo->BlueMaskSize = 8;
       modeInfo->RsvdMaskSize = 8;
       modeInfo->RsvdFieldPosition = 24;
       break;
   }

   /* for linear video modes, fill in these variables: */
   modeInfo->LinBytesPerScanLine = modeInfo->BytesPerScanLine;
   modeInfo->LinMaxBuffers = modeInfo->MaxBuffers;
   modeInfo->LinRedMaskSize = modeInfo->RedMaskSize;
   modeInfo->LinRedFieldPosition = modeInfo->RedFieldPosition;
   modeInfo->LinGreenMaskSize = modeInfo->GreenMaskSize;
   modeInfo->LinGreenFieldPosition = modeInfo->GreenFieldPosition;
   modeInfo->LinBlueMaskSize = modeInfo->BlueMaskSize;
   modeInfo->LinBlueFieldPosition = modeInfo->BlueFieldPosition;
   modeInfo->LinRsvdMaskSize = modeInfo->RsvdMaskSize;
   modeInfo->LinRsvdFieldPosition = modeInfo->RsvdFieldPosition;

   /* I'm not sure exactly what these should be: Allegro doesn't use them */
   modeInfo->MaxPixelClock = 135000000;
   modeInfo->VideoCapabilities = 0;
   modeInfo->VideoMinXScale = 0;
   modeInfo->VideoMinYScale = 0;
   modeInfo->VideoMaxXScale = 0;
   modeInfo->VideoMaxYScale = 0;

   return 0;
}

int set_width(int width)
{
   width>>=3;
   if (width<512) {
     write_vga_register(_crtc, 0x13, width & 0xFF);
     alter_vga_register(_crtc, 0x1B, 16, (width >> 4)&16);
     return width<<3;
   } else 
     return af_width;
}

/* SetVideoMode:
 *  Sets the specified video mode, returning zero on success.
 *
 *  Possible flag bits that may be or'ed with the mode number:
 *
 *    0x8000 = don't clear video memory
 *    0x4000 = enable linear framebuffer
 *    0x2000 = enable multi buffering
 *    0x1000 = enable virtual scrolling
 *    0x0800 = use refresh rate control
 *    0x0400 = use hardware stereo
 */
long SetVideoMode(AF_DRIVER *af, short mode, long virtualX, long virtualY, long *bytesPerLine, int numBuffers, AF_CRTCInfo *crtc)
{
   int linear = ((mode & 0x4000) != 0);
   int noclear = ((mode & 0x8000) != 0);
   int i;
   long available_vram;
   long used_vram;
   unsigned char *p;
   _GFX_MODE_INFO *info;
   RM_REGS r;

   /* reject anything with hardware stereo */
   if (mode & 0x400)
      return -1;

   /* mask off the other flag bits */
   mode &= 0x3FF;

   if ((mode <= 0) || (mode > num_modes))
      return -1;

   info = &mode_list[mode-1];

   r.x.ax=info->num;/*set the mode through bios function 0*/
   if (noclear) r.x.ax|=0x80;
   rm_int(0x10,&r);
   if (info->bpp==15) {
     inportb(0x3c6);     //to access hidden dac register on cirruses 4
     inportb(0x3c6);     // consecutive reads must be perforamed
     inportb(0x3c6);
     inportb(0x3c6);
     mode=inportb(0x3c6);
     mode&=0xef;         // mask out bit 4 which enables extended 15 bit modes
     // (bit 15 of color data determines if data is regular 15bit color or
     // palette index)
     inportb(0x3c6);     //to access hidden dac register on cirruses 4
     inportb(0x3c6);     // consecutive reads must be perforamed
     inportb(0x3c6);
     inportb(0x3c6);
     outportb(0x3c6,mode);
   }
   /* 16k banks, single page, disable extensions */
   alter_vga_register(0x3CE, 0xB, 0x21, 0x20);
   /* reject the linear flag if the mode doesn't support it */
   if (linear && linear_addr) {
     alter_vga_register(0x3c4,0x7,0xf0,0xf0);
   } else
     linear = 0;

   /* adjust the virtual width for widescreen modes */
   if (virtualX*BYTES_PER_PIXEL(info->bpp) > info->bpl) {
      *bytesPerLine = set_width(virtualX*BYTES_PER_PIXEL(info->bpp));
   }
   else
      *bytesPerLine = info->bpl;

   /* store info about the current mode */
   af_bpp = info->bpp;
   af_width = *bytesPerLine;
   af_height = MAX(info->h, virtualY);
   af_linear = linear;
   af_visible_page = 0;
   af_active_page = 0;
   af_bank = -1;

   /* return framebuffer dimensions to the application */
   af->BufferEndX = af_width/BYTES_PER_PIXEL(af_bpp)-1;
   af->BufferEndY = af_height-1;
   af->OriginOffset = 0;

   used_vram = af_width * af_height * numBuffers;
   available_vram = af->TotalMemory*1024;

   if (used_vram > available_vram)
      return -1;

   if (available_vram-used_vram >= af_width) {
      af->OffscreenOffset = used_vram;
      af->OffscreenStartY = af_height*numBuffers;
      af->OffscreenEndY = available_vram/af_width-1;
   }
   else {
      af->OffscreenOffset = 0;
      af->OffscreenStartY = 0;
      af->OffscreenEndY = 0;
   }

   af_fore_mix = AF_REPLACE_MIX;
   af_back_mix = AF_FORE_MIX;

   cir_bpp=BYTES_PER_PIXEL(af_bpp);

   CIR_SRCPITCH(af_width);
   CIR_DSTPITCH(af_width);
   if (af->IOMemoryBase[0]) {
   // setup MMIO
       if (af_linear)
	   alter_vga_register(0x3c4,0x17,0x44,0x44);
       else
	   alter_vga_register(0x3c4,0x17,0x44,0x04);
       af_mmio=(unsigned long)af->IOMemMaps[0];
     switch (af_bpp) {
       case 8:
	 cir_pixmode=CIR_BLT_PIX8;
	 SetupFuncPtr8MMIO(af);
	 break;
       case 15:
       case 16:
	 cir_pixmode=CIR_BLT_PIX16;
	 SetupFuncPtr16MMIO(af);
	 break;
       case 24:
	 cir_pixmode=CIR_BLT_PIX24;
	 SetupFuncPtr24MMIO(af);
	 break;
       case 32:
	 cir_pixmode=CIR_BLT_PIX32;
	 SetupFuncPtr32MMIO(af);
	 break;
     }

   } else {
     switch (af_bpp) {
       case 8:
	 cir_pixmode=CIR_BLT_PIX8;
	 SetupFuncPtr8(af);
	 break;
       case 15:
       case 16:
	 cir_pixmode=CIR_BLT_PIX16;
	 SetupFuncPtr16(af);
	 break;
       case 24:
	 cir_pixmode=CIR_BLT_PIX24;
	 SetupFuncPtr24(af);
	 break;
       case 32:
	 cir_pixmode=CIR_BLT_PIX32;
	 SetupFuncPtr32(af);
	 break;
     }
   }
   cir_offmono=af_memory-MONOPATTSTART;
   cir_offscreen=af_memory-SOLIDPATTSTART;
   cir_offcolor=af_memory-COLPATTSTART;
   cir_bltmode=CIR_BLT_PATT|CIR_BLT_COLEXP|cir_pixmode;
   cir_bltrop=CIR_ROP_COPY;
   af_last_bank=(af_memory)/64/1024-1;
   if (af_linear) {
     p=af->LinearMem+af_memory-SOLIDPATTSTART;
     for (i=0;i<8;i++)
       p[i]=0xff;
   } else {
     p=af->BankedMem+DISPLACEMENT-SOLIDPATTSTART;
     SetBank(af,af_last_bank);
     for (i=0;i<8;i++)
       p[i]=0xff;
   }
   return 0;
}

