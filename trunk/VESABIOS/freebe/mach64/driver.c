/*
 *       ______             ____  ______     _____  ______ 
 *      |  ____|           |  _ \|  ____|   / / _ \|  ____|
 *      | |__ _ __ ___  ___| |_) | |__     / / |_| | |__ 
 *      |  __| '__/ _ \/ _ \  _ <|  __|   / /|  _  |  __|
 *      | |  | | |  __/  __/ |_) | |____ / / | | | | |
 *      |_|  |_|  \___|\___|____/|______/_/  |_| |_|_|
 *
 *
 *      ATI mach64 accelerated driver.
 *
 *      Written by Ove Kaaven <ovek@arcticnet.no>
 *
 *      See freebe.txt for copyright information.
 */


#include <pc.h>

#include "vbeaf.h"

/* [OK] if you don't like VESA and like accessing the mach64 BIOS directly
	better, define this, kill the bugs, and report to me... */
#undef REFUSE_VESA



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
void WaitForFifo(AF_DRIVER *af, int entries);
void WaitTillIdle(AF_DRIVER *af);
void ResetEngine(AF_DRIVER *af);
void InitEngine(AF_DRIVER *af, int width, int height, int bpp);
void SetMix(AF_DRIVER *af, long foreMix, long backMix);
void Set8x8MonoPattern(AF_DRIVER *af, unsigned char *pattern);
void Set8x8ColorPattern(AF_DRIVER *af, int index, unsigned long *pattern);
void Use8x8ColorPattern(AF_DRIVER *af, int index);
void DrawScan(AF_DRIVER *af, long color, long y, long x1, long x2);
void DrawPattScan(AF_DRIVER *af, long foreColor, long backColor, long y, long x1, long x2);
void DrawColorPattScan(AF_DRIVER *af, long y, long x1, long x2);
void DrawRect(AF_DRIVER *af, unsigned long color, long left, long top, long width, long height);
void DrawPattRect(AF_DRIVER *af, unsigned long foreColor, unsigned long backColor, long left, long top, long width, long height);
void DrawColorPattRect(AF_DRIVER *af, long left, long top, long width, long height);
void BitBlt(AF_DRIVER *af, long left, long top, long width, long height, long dstLeft, long dstTop, long op);
void SrcTransBlt(AF_DRIVER *af, long left, long top, long width, long height, long dstLeft, long dstTop, long op, unsigned long transparent);
void DrawLine(AF_DRIVER *af, unsigned long color, fixed x1, fixed y1, fixed x2, fixed y2);



/* if you need some video memory for internal use by the accelerator
 * code (for example storing pattern data), you can define this value to 
 * reserve room for yourself at the very end of the memory space, that
 * the application will not be allowed to use.
 */
#define RESERVED_VRAM   0



/* list which ports we are going to access (only needed under Linux) */
unsigned short ports_table[] = { 0xFFFF };



/* at startup we use the get_vesa_info() helper function to find out
 * what resolutions the VESA driver provides for this card, storing them
 * in a table for future use. In a real driver you would replace this
 * VESA code with a static list of modes and their attributes, because 
 * you would know right from the start what modes are possible on your
 * card.
 */

typedef struct VIDEO_MODE
{
   int vesa_num;
   int bios_num;
   int w;
   int h;
   int bpp;
   int redsize;
   int redpos;
   int greensize;
   int greenpos;
   int bluesize;
   int bluepos;
   int rsvdsize;
   int rsvdpos;
} VIDEO_MODE;


#define MAX_MODES    128

/* [OK] we'll ignore the 4-bit (16-color) modes */

/* [OK] the idea of a mode list *and* VESA mode inquiry is that
   certain modes seems to be available only through VESA (320x200, 640x400),
   and some only through the mach64 BIOS (1600x1200, 32bpp modes) */

VIDEO_MODE mode_list[MAX_MODES]={
 {0x100,     0, 640, 400, 8},
 {0x101,0x12C2, 640, 480, 8},
 {0x103,0x6AC2, 800, 600, 8},
 {0x105,0x55C2,1024, 768, 8},
 {0x107,0x83C2,1280,1024, 8},
 {0x110,0x12C3, 640, 480,15,5,10,5,5,5,0,0,0},
 {0x111,0x12C4, 640, 480,16,5,11,6,5,5,0,0,0},
 {0x112,0x12C5, 640, 480,24,8,16,8,8,8,0,0,0},
 {0x113,0x6AC3, 800, 600,15,5,10,5,5,5,0,0,0},
 {0x114,0x6AC4, 800, 600,16,5,11,6,5,5,0,0,0},
/* [OK] Tim Riemann reported these >1MB modes (and the 0x107 above) */
 {0x115,0x6AC5, 800, 600,24,8,16,8,8,8,0,0,0},
 {0x116,0x55C3,1024, 768,15,5,10,5,5,5,0,0,0},
 {0x117,0x55C4,1024, 768,16,5,11,6,5,5,0,0,0},
 {0x118,0x55C5,1024, 768,24,8,16,8,8,8,0,0,0},
 {0x119,0x83C3,1280,1024,15,5,10,5,5,5,0,0,0},
 {0x11A,0x83C4,1280,1024,16,5,11,6,5,5,0,0,0},
 {0x11B,0x83C5,1280,1024,24,8,16,8,8,8,0,0,0},
/* [OK] nobody has reported VESA mode numbers for the following yet */
/* [OK] ...are there any at all? anyone want to report on these? */
/* [OK] 1600x1200 modes */
 {    0,0x84C2,1600,1200, 8},
 {    0,0x84C3,1600,1200,15,5,10,5,5,5,0,0,0},
 {    0,0x84C4,1600,1200,16,5,11,6,5,5,0,0,0},
 {    0,0x84C5,1600,1200,24,8,16,8,8,8,0,0,0},
/* [OK] 32 bpp modes (mostly guesswork) */
 {    0,0x12C6, 640, 480,32,8,16,8,8,8,0,0,0},
 {    0,0x6AC6, 800, 600,32,8,16,8,8,8,0,0,0},
 {    0,0x55C6,1024, 768,32,8,16,8,8,8,0,0,0},
 {    0,0x83C6,1280,1024,32,8,16,8,8,8,0,0,0},
 {    0,0x84C6,1600,1200,32,8,16,8,8,8,0,0,0}
/* [OK] if VESA mode numbers do not exist, I may have to use bios_num */
};

short available_modes[MAX_MODES+1] = {
 1,2,3,4,5,6,7,8,9,10,
 11,12,13,14,15,16,17,
/* 18,19,20,21,22,23,24,25,26, */
 -1};

int num_modes = 17;



/* internal driver state variables */
int af_bpp;
int af_width;
int af_height;
int af_linear;
int af_visible_page;
int af_active_page;
int af_scroll_x;
int af_scroll_y;
int af_bank;
int af_fore_mix;
int af_back_mix;

unsigned mach64_dpmix, mach64_dpsrc;
unsigned mach64_dcntl, mach64_scntl;

/* register addresses */
int mach64_floating, mach64_iobase;
int mach64_wpsel, mach64_rpsel, mach64_offpitch;
int mach64_dacrg, mach64_intr;

#define ioOFFPITCH 0x05
#define ioINTCNTL  0x06
#define ioGENCNTL  0x07
#define ioSCRATCH0 0x10
#define ioSCRATCH1 0x11
#define ioBUSCNTL  0x13
#define ioWPSEL    0x15
#define ioRPSEL    0x16
#define ioDACREGS  0x17
#define ioDACCNTL  0x18
#define ioGTCNTL   0x19

#define mmOFFPITCH 0x05
#define mmINTCNTL  0x06
#define mmGENCNTL  0x07
#define mmSCRATCH0 0x20
#define mmSCRATCH1 0x21
#define mmBUSCNTL  0x28
#define mmWPSEL    0x2D
#define mmRPSEL    0x2E
#define mmDACREGS  0x30
#define mmDACCNTL  0x31
#define mmGTCNTL   0x34
#define HWCURSOR_ENABLE 0x80
#define ENGINE_ENABLE  0x100

#define mmDOFFPTCH 0x40
#define mmDX       0x41
#define mmDY       0x42
#define mmDYX      0x43
#define mmDWDTH    0x44
#define mmDHT      0x45
#define mmDHTWDTH  0x46
#define mmDXWDTH   0x47
#define mmDBRSLEN  0x48
#define mmDBRSERR  0x49
#define mmDBRSINC  0x4A
#define mmDBRSDEC  0x4B
#define mmDCNTL    0x4C
#define DC_X_R2L  0x00
#define DC_X_L2R  0x01
#define DC_Y_B2T  0x00
#define DC_Y_T2B  0x02
#define DC_X_MAJ  0x00
#define DC_Y_MAJ  0x04
#define DC_X_TILE 0x08
#define DC_Y_TILE 0x10
#define DC_LAST_P 0x20
#define DC_POLY   0x40
#define DC_R_24   0x80

#define mmSOFFPTCH 0x60
#define mmSX       0x61
#define mmSY       0x62
#define mmSYX      0x63
#define mmSWDTH1   0x64
#define mmSHT1     0x65
#define mmSHTWDTH1 0x66
#define mmSXSTRT   0x67
#define mmSYSTRT   0x68
#define mmSYXSTRT  0x69
#define mmSWDTH2   0x6A
#define mmSHT2     0x6B
#define mmSHTWDTH2 0x6C
#define mmSCNTL    0x6D
#define SC_PATT   0x01
#define SC_ROT    0x02
#define SC_LIN    0x04
#define SC_BYTE_A 0x08
#define SC_LX_R2L 0x00
#define SC_LX_L2R 0x10

#define mmHOSTCNTL 0x90

#define mmPATREG0  0xA0
#define mmPATREG1  0xA1
#define mmPATCNTL  0xA2
#define PC_MONO 0x01
#define PC_C4x2 0x02
#define PC_C8x1 0x04

#define mmSCLEFT   0xA8
#define mmSCRIGHT  0xA9
#define mmSCLTRT   0xAA
#define mmSCTOP    0xAB
#define mmSCBOTTOM 0xAC
#define mmSCTPBT   0xAD

#define mmDPBGCOL  0xB0
#define mmDPFGCOL  0xB1
#define mmDPWRMSK  0xB2
#define mmDPCHNMSK 0xB3
#define mmPIXWDTH  0xB4
#define PW_1  0
#define PW_4  1
#define PW_8  2
#define PW_15 3
#define PW_16 4
#define PW_32 6
#define PW_MSB 0x00000000
#define PW_LSB 0x01000000
#define mmDPMIX    0xB5
#define mmDPSRC    0xB6
#define DS_BGCOL 0x00
#define DS_FGCOL 0x01
#define DS_HOST  0x02
#define DS_BLIT  0x03
#define DS_PATT  0x04
#define DSM_TRUE 0x00000
#define DSM_PATT 0x10000
#define DSM_HOST 0x20000
#define DSM_BLIT 0x30000

#define mmCCMPCLR  0xC0
#define mmCCMPMSK  0xC1
#define mmCCMPCNTL 0xC2
#define CC_FALSE 0x00
#define CC_TRUE  0x01
#define CC_NOTEQ 0x04
#define CC_EQUAL 0x05
#define CC_DST   0x00000000
#define CC_SRC   0x01000000

#define mmFIFOSTAT 0xC4
#define FIFO_ERR 0x80000000
#define mmGUISTAT  0xCE
#define ENGINE_BUSY 1
#define mmCNTXMASK 0xC8
#define mmCNTXLDCT 0xCB
#define mmTRAJCNTL 0xCC
#define mmGUISTAT  0xCE


/* [OK] don't forget "volatile" if you need to do any loops,
   like in WaitForFifo and WaitTillIdle (had some trouble with that) */
#define mm_port(x) (((volatile unsigned long*)(af->IOMemMaps[0]))[x])

/* [OK] this routine is adapted from Allegro's ati.c: */
/* get_mach64_port:
 *  Calculates the port address for accessing a specific mach64 register.
 */
static int get_mach64_port(int io_sel, int mm_sel)
{
   if (mach64_floating) {
      return (mm_sel << 2) + mach64_iobase;
   }
   else {
      return (io_sel << 10) + mach64_iobase;
   }
}

/*

taken from mach64 example code, I don't understand what this macro
really does, but I interpret it in this way

#define GET24BPPROTATION(x)  (unsigned long)(((x * 3) / 4) % 6)

r g b r g b r g b r g b r g b r g b r g b r g b
0     1     2     3     4     5     6     7
---0--- ---1--- ---2--- ---3--- ---4--- ---5---

though it doesn't seem very logical to have a "rotation" value do this
*/

#define m64_rot24(x) (DC_R_24|((((x)/4)%6)<<8))


/* note about VBE/AF multiple page modes: the API supports any number of
 * video memory pages, one of which is "active" (being drawn onto), while
 * the other is visible on your monitor. Allegro doesn't actually use
 * this functionality, so you may safely leave it out and just reject
 * any mode set requests with a numBuffers value greater than one, but
 * that might upset other VBE/AF applications if they depend on this 
 * functionality. To support multiple pages, you must offset all the
 * hardware drawing operations so their coordinate system is relative
 * to the active page. You must also maintain an offset from the start
 * of vram to the start of the active page in the OriginOffset of the
 * driver structure, and adjust the OffscreenStartY and OffscreenEndY 
 * values so they will refer to the same offscreen memory region regardless 
 * of the current accelerator coordinate system. This is all handled by the 
 * SetActiveBuffer() function below, so in practice you can simply add 
 * af_active_page*af_height onto the input Y coordinate of any accelerator
 * drawing funcs, and multiple page modes should work correctly.
 */



#ifndef REFUSE_VESA
/* mode_callback:
 *  Callback for the get_vesa_info() function to add a new resolution to
 *  the table of available modes.
 */
void mode_callback(int vesa_num, int linear, int w, int h, int bpp, int bytes_per_scanline, int redsize, int redpos, int greensize, int greenpos, int bluesize, int bluepos, int rsvdsize, int rsvdpos)
{
   int chk;

   if (num_modes >= MAX_MODES)
      return;

   if ((bpp != 8) && (bpp != 15) && (bpp != 16) && (bpp != 24) && (bpp != 32))
      return;

   /* [OK] make sure mode is not already in list */
   for (chk=0; chk<num_modes; chk++)
      if (mode_list[chk].vesa_num == vesa_num) return;
   for (chk=0; chk<num_modes; chk++)
      if ((mode_list[chk].w == w)&&
	  (mode_list[chk].h == h)&&
	  (mode_list[chk].bpp == bpp)) {
	 mode_list[chk].vesa_num = vesa_num;
	 return;
      }

   mode_list[num_modes].vesa_num = vesa_num;
   mode_list[num_modes].w = w;
   mode_list[num_modes].h = h;
   mode_list[num_modes].bpp = bpp;
   mode_list[num_modes].redsize = redsize;
   mode_list[num_modes].redpos = redpos;
   mode_list[num_modes].greensize = greensize;
   mode_list[num_modes].greenpos = greenpos;
   mode_list[num_modes].bluesize = bluesize;
   mode_list[num_modes].bluepos = bluepos;
   mode_list[num_modes].rsvdsize = rsvdsize;
   mode_list[num_modes].rsvdpos = rsvdpos;

   available_modes[num_modes] = num_modes+1;
   available_modes[num_modes+1] = -1;

   num_modes++;
}
#endif



/* [OK] the mach64 BIOS reports these VRAM amounts */
int vram_sizes[]={512,1024,2048,4096,6144,8192,12288,8192};



/* SetupDriver:
 *  The first thing ever to be called after our code has been relocated.
 *  This is in charge of filling in the driver header with all the required
 *  information and function pointers. We do not yet have access to the
 *  video memory, so we can't talk directly to the card.
 */
int SetupDriver(AF_DRIVER *af)
{
   RM_REGS r;
   int scratch_reg;
   unsigned long old;
   unsigned long aperture_addr, aperture_size;
   int vram_size;
   int i;

#ifndef REFUSE_VESA
   /* find out what VESA has to say for itself */
   if (get_vesa_info(&vram_size, NULL, mode_callback) != 0)
      return -1;
#endif

   /* [OK] call upon the mach64 BIOS to get its I/O base address */
   r.x.ax = 0xA012; 
   r.x.cx = 0;
   rm_int(0x10, &r);

   if (r.h.ah)
      return -1; /* [OK] there's no mach64 here */

   mach64_floating = r.x.cx;
   mach64_iobase = r.x.dx;
   if (!mach64_iobase) mach64_iobase = 0x2EC;

   /* [OK] this test is mostly copied from Allegro's ati.c: */
   /* test scratch register to confirm we have a mach64 */
   scratch_reg = get_mach64_port(ioSCRATCH1, mmSCRATCH1);
   old = inportl(scratch_reg);

   outportl(scratch_reg, 0x55555555);
   if (inportl(scratch_reg) != 0x55555555) {
      outportl(scratch_reg, old);
      return -1;
   }

   outportl(scratch_reg, 0xAAAAAAAA);
   if (inportl(scratch_reg) != 0xAAAAAAAA) {
      outportl(scratch_reg, old);
      return -1;
   }

   outportl(scratch_reg, old);
   /* [OK] we have confirmed the presence of a mach64 */

   mach64_wpsel = get_mach64_port(ioWPSEL, mmWPSEL);
   mach64_rpsel = get_mach64_port(ioRPSEL, mmRPSEL);
   mach64_offpitch = get_mach64_port(ioOFFPITCH, mmOFFPITCH);
   mach64_dacrg = get_mach64_port(ioDACREGS, mmDACREGS);
   mach64_intr = get_mach64_port(ioINTCNTL, mmINTCNTL);

   /* [OK] now we need to query the BIOS about our VRAM configuration */
   r.x.ax = 0xA006;
   rm_int(0x10, &r);

   vram_size = vram_sizes[r.h.cl];
   aperture_addr = r.x.bx * 1024 * 1024;
   if (r.h.al&2) aperture_size = 8 * 1024 * 1024; else
   if (r.h.al&1) aperture_size = 4 * 1024 * 1024; else
      { aperture_size = 0; aperture_addr = 0; }
   /* [OK] there we go */

   /* pointer to a list of the available mode numbers, ended by -1.
    * Our mode numbers just count up from 1, so the mode numbers can
    * be used as indexes into the mode_list[] table (zero is an
    * invalid mode number, so this indexing must be offset by 1).
    */
   af->AvailableModes = available_modes;

   /* amount of video memory in K */
   af->TotalMemory = vram_size;

   /* driver attributes (see definitions in vbeaf.h) */
   af->Attributes = (afHaveMultiBuffer | 
		     afHaveVirtualScroll | 
		     afHaveBankedBuffer | 
		     afHaveAccel2D |
		     afHaveROP2);

   if (aperture_addr)
      af->Attributes |= afHaveLinearBuffer;

   /* banked memory size and location: zero if not supported */
   af->BankSize = 32;
   af->BankedBasePtr = 0xA0000;

   /* linear framebuffer size and location: zero if not supported */
   if (aperture_addr) {
      af->LinearSize = MIN(vram_size, (int)aperture_size - 0x400);
      af->LinearBasePtr = aperture_addr;
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
   /* [OK] the mach64 MMIO registers are at end of aperture */
   if (aperture_addr)
      af->IOMemoryBase[0] = aperture_addr + aperture_size - 0x400;
   else
      af->IOMemoryBase[0] = 0xC0000 - 0x400;
   af->IOMemoryLen[0] = 0x400;

   /* driver state variables (initialised later during the mode set) */
   af->BufferEndX = 0;
   af->BufferEndY = 0;
   af->OriginOffset = 0;
   af->OffscreenOffset = 0;
   af->OffscreenStartY = 0;
   af->OffscreenEndY = 0;

   /* relocatable bank switcher (not required by Allegro) */
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
   af->SetCursor = NULL;
   af->SetCursorPos = NULL;
   af->SetCursorColor = NULL;
   af->ShowCursor = NULL;

   /* wait until the accelerator hardware has finished drawing */
   af->WaitTillIdle = WaitTillIdle;

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
#if 0
   af->Set8x8ColorPattern = Set8x8ColorPattern;
   af->Use8x8ColorPattern = Use8x8ColorPattern;
#endif

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

   /* DrawScan() is required: patterned versions may be NULL */
   af->DrawScan = DrawScan;
   af->DrawPattScan = DrawPattScan;
#if 0
   af->DrawColorPattScan = DrawColorPattScan;
#endif

   /* not supported: not used by Allegro */
   af->DrawScanList = NULL;
   af->DrawPattScanList = NULL;
   af->DrawColorPattScanList = NULL;

   /* rectangle filling: may be NULL */
   af->DrawRect = DrawRect;
   af->DrawPattRect = DrawPattRect;
#if 0
   af->DrawColorPattRect = DrawColorPattRect;
#endif

   /* not supported: not used by Allegro */
   af->DrawLine = NULL;
   af->DrawStippleLine = NULL;
   af->DrawTrap = NULL;
   af->DrawTri = NULL;
   af->DrawQuad = NULL;
   af->PutMonoImage = NULL;
   af->PutMonoImageLin = NULL;
   af->PutMonoImageBM = NULL;

   /* blitting within the video memory (may be NULL) */
   af->BitBlt = BitBlt;

   /* not supported: not used by Allegro */
   af->BitBltSys = NULL;
   af->BitBltLin = NULL;
   af->BitBltBM = NULL;

   /* masked blitting within the video memory (may be NULL) */
   af->SrcTransBlt = NULL;

   /* not supported: not used by Allegro */
   af->SrcTransBltSys = NULL;
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
   VIDEO_MODE *info;
   int i, bytes_per_scanline;

   if ((mode <= 0) || (mode > num_modes))
      return -1;

   info = &mode_list[mode-1];

   /* clear the structure to zero */
   for (i=0; i<(int)sizeof(AF_MODE_INFO); i++)
      ((char *)modeInfo)[i] = 0;

#ifdef REFUSE_VESA
   if (!info->bios_num) return -1;
#endif

   /* copy data across from our stored list of mode attributes */
   modeInfo->Attributes = af->Attributes;

   modeInfo->XResolution = info->w;
   modeInfo->YResolution = info->h;
   modeInfo->BitsPerPixel = info->bpp;

   bytes_per_scanline = info->w * BYTES_PER_PIXEL(info->bpp);

   /* available pages of video memory */
   modeInfo->MaxBuffers = (af->TotalMemory*1024 - RESERVED_VRAM) / 
			  (bytes_per_scanline * info->h);

   /* maximum virtual scanline length in both bytes and pixels. How wide
    * this can go will very much depend on the card: 1024 is pretty safe
    * on anything, but you will want to allow larger limits if the card
    * is capable of them.
    */
   modeInfo->MaxBytesPerScanLine = 1024*BYTES_PER_PIXEL(info->bpp);
   modeInfo->MaxScanLineWidth = 1024;

   /* for banked video modes, fill in these variables: */
   modeInfo->BytesPerScanLine = bytes_per_scanline;
   modeInfo->BnkMaxBuffers = modeInfo->MaxBuffers;
   modeInfo->RedMaskSize = info->redsize;
   modeInfo->RedFieldPosition = info->redpos;
   modeInfo->GreenMaskSize = info->greensize;
   modeInfo->GreenFieldPosition = info->greenpos;
   modeInfo->BlueMaskSize = info->bluesize;
   modeInfo->BlueFieldPosition = info->bluepos;
   modeInfo->RsvdMaskSize = info->rsvdsize;
   modeInfo->RsvdFieldPosition = info->rsvdpos;

   /* for linear video modes, fill in these variables: */
   modeInfo->LinBytesPerScanLine = bytes_per_scanline;
   modeInfo->LinMaxBuffers = modeInfo->MaxBuffers;
   modeInfo->LinRedMaskSize = info->redsize;
   modeInfo->LinRedFieldPosition = info->redpos;
   modeInfo->LinGreenMaskSize = info->greensize;
   modeInfo->LinGreenFieldPosition = info->greenpos;
   modeInfo->LinBlueMaskSize = info->bluesize;
   modeInfo->LinBlueFieldPosition = info->bluepos;
   modeInfo->LinRsvdMaskSize = info->rsvdsize;
   modeInfo->LinRsvdFieldPosition = info->rsvdpos;

   /* I'm not sure exactly what these should be: Allegro doesn't use them */
   modeInfo->MaxPixelClock = 135000000;
   modeInfo->VideoCapabilities = 0;
   modeInfo->VideoMinXScale = 0;
   modeInfo->VideoMinYScale = 0;
   modeInfo->VideoMaxXScale = 0;
   modeInfo->VideoMaxYScale = 0;

   return 0;
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
   long available_vram;
   long used_vram;
   VIDEO_MODE *info;
   RM_REGS r;

   /* reject anything with hardware stereo */
   if (mode & 0x400)
      return -1;

   /* mask off the other flag bits */
   mode &= 0x3FF;

   if ((mode <= 0) || (mode > num_modes))
      return -1;

   info = &mode_list[mode-1];

   /* reject the linear flag if the mode doesn't support it */
   if ((linear) && (!af->Attributes&afHaveLinearBuffer))
      return -1;

#ifndef REFUSE_VESA
   if (info->vesa_num) {
      /* call VESA to set the mode */
      r.x.ax = 0x4F02;
      r.x.bx = info->vesa_num;
#if 0
      /* [OK] the mach64 BIOS is VESA 1.2 which can't handle LFB itself */
      if (linear)
	 r.x.bx |= 0x4000;
#endif
      if (noclear)
	 r.x.bx |= 0x8000;
      rm_int(0x10, &r);
      if (r.h.ah)
	 return -1;
   } else {
#endif
      /* [OK] call mach64 BIOS to set the mode */
      r.x.ax = 0xA002;
      r.x.cx = info->bios_num;
      rm_int(0x10, &r);
      if (r.h.ah)
	 return -1;
#ifndef REFUSE_VESA
   }
#endif

   /* adjust the virtual width for widescreen modes */
   if (virtualX < info->w)
      virtualX = info->w;
   /* [OK] enforce necessary alignment */
   virtualX=virtualX&~7;

   outportl(mach64_offpitch,
	    (inportl(mach64_offpitch) & 0xFFFFF) | (virtualX << 19));

   *bytesPerLine = virtualX*BYTES_PER_PIXEL(info->bpp);

   /* [OK] enable the mach64 linear aperture */
   if (linear) {
      r.x.ax = 0xA005;
      r.x.cx = 1;
      rm_int(0x10, &r);
   }

   /* store info about the current mode */
   af_bpp = info->bpp;
   af_width = *bytesPerLine;
   af_height = MAX(info->h, virtualY);
   af_linear = linear;
   af_visible_page = 0;
   af_active_page = 0;
   af_bank = -1;

   af_fore_mix = AF_REPLACE_MIX;
   af_back_mix = AF_FORE_MIX;

   /* [OK] provide acceleration where possible */
   switch (af_bpp) {
    case 8:
    case 15:
    case 16:
    case 32:
     af->SrcTransBlt = SrcTransBlt;
     af->DrawLine = DrawLine;
     break;
    default: /* 24bpp */
     af->SrcTransBlt = NULL; /* haven't figured how to do this in 24bpp */
     af->DrawLine = NULL; /* would have to be done pixel-by-pixel */
     break;
   }

   /* return framebuffer dimensions to the application */
   af->BufferEndX = af_width/BYTES_PER_PIXEL(af_bpp)-1;
   af->BufferEndY = af_height-1;
   af->OriginOffset = 0;

   used_vram = af_width * af_height * numBuffers;
   available_vram = af->TotalMemory*1024 - RESERVED_VRAM;

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

   /* [OK] load mode parameters into the graphics coprocessor */
   InitEngine(af, virtualX, af_height, info->bpp);

#ifndef REFUSE_VESA
   if (!info->vesa_num)
#endif
   if (!noclear) {
      DrawRect(af, 0, 0, 0, info->w, af_height);
      WaitTillIdle(af);
   }

   return 0;
}



/* RestoreTextMode:
 *  Returns to text mode, shutting down the accelerator hardware.
 */
void RestoreTextMode(AF_DRIVER *af)
{
   RM_REGS r;

   /* [OK] disable aperture, just in case */
   r.x.ax = 0xA005;
   r.x.cx = 0;
   rm_int(0x10, &r);

   /* [OK] back to where it all began */
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
   if (waitVRT != -1) {
      long a = x + ((y + af_visible_page*af_height) * af_width);

      a *= BYTES_PER_PIXEL(af_bpp);

      if (waitVRT) {
	 do {
	 } while (inportb(mach64_intr) & 1);

	 do {
	 } while (!(inportb(mach64_intr) & 1));
      }

      outportl(mach64_offpitch,
	    (inportl(mach64_offpitch) & 0xFFF00000) | (a >> 3));
   }

   af_scroll_x = x;
   af_scroll_y = y;
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

   SetDisplayStart(af, af_scroll_x, af_scroll_y, waitVRT);
}



/* GetDisplayStartStatus:
 *  Status poll for triple buffering. Not possible on the majority of
 *  present cards: this function is just a placeholder.
 */
int GetDisplayStartStatus(AF_DRIVER *af)
{
   return 1;
}



/* SetPaletteData:
 *  Palette setting routine.
 */
void SetPaletteData(AF_DRIVER *af, AF_PALETTE *pal, long num, long index, long waitVRT)
{
   int i;

   if (waitVRT) {
      do {
      } while (inportb(mach64_intr) & 1);

      do {
      } while (!(inportb(mach64_intr) & 1));
   }

   for (i=0; i<num; i++) {
      outportb(mach64_dacrg, index+i);
      outportb(mach64_dacrg+1, pal[i].red/4);
      outportb(mach64_dacrg+1, pal[i].green/4);
      outportb(mach64_dacrg+1, pal[i].blue/4);
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
 */

asm ("

   .globl _SetBank32, _SetBank32End

      .align 4
   _SetBank32:
      pushal
# [OK] mostly copied from Allegro's bank.s
      movl %edx,%eax
      # two 32K apertures, bank and bank+1
      movb %al,%ah
      incb %ah
      shll $8,%eax
      shrw $8,%ax

# [OK] hey, I'm violating Shawn's rules for SetBank32...
# [OK] oh well, I might make it 100% relocatable later
# [OK] (how? I can think of at least 3 ways, so don't worry)
# [OK] or just use LFB meanwhile (or preferably always)
      movl _mach64_wpsel,%edx
      outl %eax,%dx
      movl _mach64_rpsel,%edx
      outl %eax,%dx

      popal
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
   asm (
      " call _SetBank32 "
   :
   : "d" (bank)
   );

   af_bank = bank;
}



/* WaitForFifo:
 *  [OK] Delay until there's room for more data.
 */
void WaitForFifo(AF_DRIVER *af, int entries)
{
   unsigned ent = 0x8000 >> entries;
#ifdef TEST
   alarm(5);
#endif
   while ((mm_port(mmFIFOSTAT)&0xFFFF) > ent);
#ifdef TEST
   alarm(0);
#endif
}



/* WaitTillIdle:
 *  Delay until the hardware controller has finished drawing.
 */
void WaitTillIdle(AF_DRIVER *af)
{
   WaitForFifo(af, 16);
#ifdef TEST
   alarm(5);
#endif
   while (mm_port(mmGUISTAT) & ENGINE_BUSY);
#ifdef TEST
   alarm(0);
#endif
}



/* ResetEngine:
 *  [OK] Reset the GUI engine and clear any errors.
 */
void ResetEngine(AF_DRIVER *af)
{
   int cntl_reg;

   /* reset engine */
   cntl_reg = get_mach64_port(ioGTCNTL, mmGTCNTL);
   outportl(cntl_reg, inportl(cntl_reg) & 0xFFFFFEFF);
   /* enable engine */
   outportl(cntl_reg, inportl(cntl_reg) | ENGINE_ENABLE);
   /* clear any errors */
   cntl_reg = get_mach64_port(ioBUSCNTL, mmBUSCNTL);
   outportl(cntl_reg, (inportl(cntl_reg) & 0xFF00FFFF) | 0x00AE0000);
}



unsigned mach64_mix[]={
 7,  /* REPLACE_MIX */
 12, /* AND_MIX */
 11, /* OR_MIX */
 5,  /* XOR_MIX */
 3,  /* NOP_MIX */

 7,7,7,7,7,7,7,7,7,7,7, /* padding */

 /* ROP2 conversion */
     /* S:1100 */
     /* D:1010 */
     /*   ---- */
 1,  /*   0000 BLACK       aka ZERO            */
 15, /*   0001 NOTMERGESRC aka NOT_D_AND_NOT_S */
 14, /*   0010 MASKNOTSRC  aka D_AND_NOT_S     */
 4,  /*   0011 NOTCOPYSRC  aka NOT_S           */
 13, /*   0100 MASKSRCNOT  aka NOT_D_AND_S     */
 0,  /*   0101 NOT         aka NOT_D           */
 5,  /*   0110 XORSRC      aka D_XOR_S         */
 8,  /*   0111 NOTMASKSRC  aka NOT_D_OR_NOT_S  */
 12, /*   1000 MASKSRC     aka D_AND_S         */
 6,  /*   1001 NOTXORSRC   aka NOT_D_XOR_S     */
 3,  /*   1010 NOP         aka D               */
 9,  /*   1011 MERGENOTSRC aka D_OR_NOT_S      */
 7,  /*   1100 COPYSRC     aka S               */
 10, /*   1101 MERGESRCNOT aka NOT_D_OR_S      */
 11, /*   1110 MERGESRC    aka D_OR_S          */
 2   /*   1111 WHITE       aka ONE             */

/* the mach64 also supports a (S+D)/2 mix mode (hardware-accelerated
   blending, cool) 0x17, but I don't think VBE/AF supports that... */
};

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
 */
void SetMix(AF_DRIVER *af, long foreMix, long backMix)
{
   af_fore_mix = foreMix;

   if (backMix == AF_FORE_MIX)
      af_back_mix = foreMix;
   else
      af_back_mix = backMix;

   mach64_dpmix = (mach64_mix[af_fore_mix]<<16) | mach64_mix[af_back_mix];

   WaitForFifo(af, 1);
   mm_port(mmDPMIX) = mach64_dpmix;
}



/* InitEngine:
 *  [OK] Loads the current mode parameters into the graphics coprocessor.
 */
void InitEngine(AF_DRIVER *af, int width, int height, int bpp)
{
   /* reset engine */
   ResetEngine(af);

   if (bpp == 24) {
      /* [OK] the mach64 graphics coprocessor doesn't support 24bpp,
	      so it must be set to 8bpp, which means the width must be
	      adjusted accordingly */
      width *= 3;
   }

   /* make sure the FIFO has room for our next 14 register loads */
   WaitForFifo(af, 14);
   /* full context mask */
   mm_port(mmCNTXMASK) = 0xFFFFFFFF;
   /* destination parameters */
   mm_port(mmDOFFPTCH) = width << 19;
   mm_port(mmDYX) = 0;
   mm_port(mmDHT) = 0;
   mm_port(mmDBRSERR) = 0;
   mm_port(mmDBRSINC) = 0;
   mm_port(mmDBRSDEC) = 0;
   mach64_dcntl = DC_LAST_P|DC_Y_T2B|DC_X_L2R;
   mm_port(mmDCNTL) = mach64_dcntl;
   /* source parameters */
   mm_port(mmSOFFPTCH) = width << 19;
   mm_port(mmSYX) = 0;
   mm_port(mmSHTWDTH1) = 0;
   mm_port(mmSYXSTRT) = 0;
   mm_port(mmSHTWDTH2) = 0;
   mach64_scntl = SC_LX_L2R;
   mm_port(mmSCNTL) = mach64_scntl;

   /* 13 more register loads on their way */
   WaitForFifo(af, 13);
   /* host control */
   mm_port(mmHOSTCNTL) = 0;
   /* pattern */
   mm_port(mmPATREG0) = 0;
   mm_port(mmPATREG1) = 0;
   mm_port(mmPATCNTL) = 0;
   /* clipping */
   mm_port(mmSCLEFT) = 0;
   mm_port(mmSCTOP) = 0;
   mm_port(mmSCBOTTOM) = height-1;
   mm_port(mmSCRIGHT) = width-1;
   /* colors */
   mm_port(mmDPBGCOL) = 0;
   mm_port(mmDPFGCOL) = 0xFFFFFFFF;
   /* write mask */
   mm_port(mmDPWRMSK) = 0xFFFFFFFF;
   /* mix mode = replace */
   mach64_dpmix = 7<<16 | 7;
   mm_port(mmDPMIX) = mach64_dpmix;
   /* foreground source */
   mach64_dpsrc = DS_FGCOL<<8 | DS_BGCOL;
   mm_port(mmDPSRC) = mach64_dpsrc;

   /* 5 register loads left */
   WaitForFifo(af, 5);
   /* pixel masking */
   mm_port(mmCCMPCLR) = 0;
   mm_port(mmCCMPMSK) = 0xFFFFFFFF;
   mm_port(mmCCMPCNTL) = 0;

   /* bpp mode */
   switch (bpp) {
    case 4: /* just for completeness */
     mm_port(mmPIXWDTH) = PW_4 << 16 | PW_4 << 8 | PW_4 | PW_LSB;
     mm_port(mmDPCHNMSK) = 0x8888;
     break;
    case 15:
     mm_port(mmPIXWDTH) = PW_15 << 16 | PW_15 << 8 | PW_15 | PW_LSB;
     mm_port(mmDPCHNMSK) = 0x4210;
     break;
    case 16:
     mm_port(mmPIXWDTH) = PW_16 << 16 | PW_16 << 8 | PW_16 | PW_LSB;
     mm_port(mmDPCHNMSK) = 0x8410;
     break;
    case 32:
     mm_port(mmPIXWDTH) = PW_32 << 16 | PW_32 << 8 | PW_32 | PW_LSB;
     mm_port(mmDPCHNMSK) = 0x8080;
     break;
    default: /* 8bpp and 24bpp */
     mm_port(mmPIXWDTH) = PW_8 << 16 | PW_8 << 8 | PW_8 | PW_LSB;
     mm_port(mmDPCHNMSK) = 0x8080;
     break;
   }

   /* wait for graphics coprocessor to swallow it all */
   WaitTillIdle(af);
}



/* af_putpixel:
 *  Writes a pixel to the screen with the specified mix mode. This function
 *  is _not_ intended to be useful: it is grossly inefficient! It is just
 *  a helper for the example drawing routines below: these should of course
 *  be replaced by hardware specific code.
 */
void af_putpixel(AF_DRIVER *af, int x, int y, int c, int mix)
{
   long offset;
   int bank;
   int c2 = 0;
   void *p;

   y += af_active_page*af_height;
   offset = y*af_width + x*BYTES_PER_PIXEL(af_bpp);

   /* quit if this is a noop */
   if (mix == AF_NOP_MIX)
      return;

   /* get pointer to vram */
   if (af_linear) {
      p = af->LinearMem + offset;
   }
   else {
      p = af->BankedMem + (offset&0x7FFF);
      bank = offset>>15; /* 32K granularity */
      if (bank != af_bank) {
	 af->SetBank(af, bank);
	 af_bank = bank;
      }
   }

   if (mix != AF_REPLACE_MIX) {
      /* read destination pixel for mixing */
      switch (af_bpp) {

	 case 8:
	    c2 = *((unsigned char *)p);
	    break;

	 case 15:
	 case 16:
	    c2 = *((unsigned short *)p);
	    break;

	 case 24:
	    c2 = *((unsigned long *)p) & 0xFFFFFF;
	    break;

	 case 32:
	    c2 = *((unsigned long *)p);
	    break;
      }

      /* apply logical mix modes */
      switch (mix) {

	 case AF_AND_MIX:
	    c &= c2;
	    break;

	 case AF_OR_MIX:
	    c |= c2;
	    break;

	 case AF_XOR_MIX:
	    c ^= c2;
	    break;
      } 
   }

   /* write the pixel */
   switch (af_bpp) {

      case 8:
	 *((unsigned char *)p) = c;
	 break;

      case 15:
      case 16:
	 *((unsigned short *)p) = c;
	 break;

      case 24:
	 *((unsigned short *)p) = c&0xFFFF;
	 *((unsigned char *)(p+2)) = c>>16;
	 break;

      case 32:
	 *((unsigned long *)p) = c;
	 break;
   }
}



/* af_getpixel:
 *  Reads a pixel from the screen. This function is _not_ intended to 
 *  be useful: it is grossly inefficient! It is just a helper for the 
 *  example drawing routines below: these should of course be replaced 
 *  by hardware specific code.
 */
int af_getpixel(AF_DRIVER *af, int x, int y)
{
   long offset;
   int bank;
   void *p;

   y += af_active_page*af_height;
   offset = y*af_width + x*BYTES_PER_PIXEL(af_bpp);

   /* get pointer to vram */
   if (af_linear) {
      p = af->LinearMem + offset;
   }
   else {
      p = af->BankedMem + (offset&0x7FFF);
      bank = offset>>15; /* 32K granularity */
      if (bank != af_bank) {
	 af->SetBank(af, bank);
	 af_bank = bank;
      }
   }

   /* read the pixel */
   switch (af_bpp) {

      case 8:
	 return *((unsigned char *)p);

      case 15:
      case 16:
	 return *((unsigned short *)p);

      case 24:
	 return *((unsigned long *)p) & 0xFFFFFF;

      case 32:
	 return *((unsigned long *)p);
   }

   return 0;
}



/* stored mono pattern data */
unsigned char mono_pattern[8];



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

   for (i=0; i<8; i++)
      mono_pattern[i] = pattern[i];

   WaitForFifo(af, 3);
   mm_port(mmPATREG0) = ((unsigned long*)(&mono_pattern))[0];
   mm_port(mmPATREG1) = ((unsigned long*)(&mono_pattern))[1];
   mm_port(mmPATCNTL) = PC_MONO;
}



/* stored color pattern data */
unsigned long color_pattern[8][64];
unsigned long *current_color_pattern = color_pattern[0];

/* [OK] I've disabled color patterns for now */

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
   current_color_pattern = color_pattern[index];
}



/* DrawScan:
 *  Fills a scanline in the current foreground mix mode. Draws up to but
 *  not including the second x coordinate. If the second coord is less
 *  than the first, they are swapped. If they are equal, nothing is drawn.
 */
void DrawScan(AF_DRIVER *af, long color, long y, long x1, long x2)
{
   if (x2 < x1)
      DrawRect(af, color, x2, y, x1-x2, 1);
   else
      DrawRect(af, color, x1, y, x2-x1, 1);
}



/* DrawPattScan:
 *  Fills a scanline using the current mono pattern. Set pattern bits are
 *  drawn using the specified foreground color and the foreground mix
 *  mode, and clear bits use the background color and background mix mode.
 */
void DrawPattScan(AF_DRIVER *af, long foreColor, long backColor, long y, long x1, long x2)
{
   if (x2 < x1)
      DrawPattRect(af, foreColor, backColor, x2, y, x1-x2, 1);
   else
      DrawPattRect(af, foreColor, backColor, x1, y, x2-x1, 1);
}



/* DrawColorPattScan:
 *  Fills a scanline using the current color pattern and mix mode.
 */
void DrawColorPattScan(AF_DRIVER *af, long y, long x1, long x2)
{
   int orig_bank = af_bank;
   int patx, paty;

   if (x2 < x1) {
      int tmp = x1;
      x1 = x2;
      x2 = tmp;
   }

   while (x1 < x2) {
      patx = x1&7;
      paty = y&7;

      af_putpixel(af, x1, y, current_color_pattern[paty*8+patx], af_fore_mix);

      x1++;
   }

   if (af_bank != orig_bank)
      af->SetBank(af, orig_bank);
}



/* DrawRect:
 *  Fills a rectangle in the current foreground mix mode.
 */
void DrawRect(AF_DRIVER *af, unsigned long color, long left, long top, long width, long height)
{
   if (af_bpp == 24) {
      left *= 3;
      width *= 3;

      WaitForFifo(af, 1);
      mm_port(mmDCNTL) = mach64_dcntl | m64_rot24(left);
   }

   WaitForFifo(af, 5);
   /* [OK] set color */
   mm_port(mmDPFGCOL) = color;
   /* [OK] draw rectangle */
   mm_port(mmDX) = left;
   mm_port(mmDY) = top + af_active_page*af_height;
   mm_port(mmDHT) = height;
   mm_port(mmDWDTH) = width;

   if (af_bpp == 24) {
      WaitForFifo(af, 1);
      mm_port(mmDCNTL) = mach64_dcntl;
   }
}



/* DrawPattRect:
 *  Fills a rectangle using the current mono pattern. Set pattern bits are
 *  drawn using the specified foreground color and the foreground mix
 *  mode, and clear bits use the background color and background mix mode.
 */
void DrawPattRect(AF_DRIVER *af, unsigned long foreColor, unsigned long backColor, long left, long top, long width, long height)
{
   WaitForFifo(af, 2);
   /* [OK] set background color and source */
   mm_port(mmDPBGCOL) = backColor;
   /* [OK] I'm not quite sure about this...
	   I don't think it works, but I don't have a test program
	   anyone to test it for me? */
   mm_port(mmDPSRC) = DSM_PATT | (DS_FGCOL<<8) | DS_BGCOL;

   DrawRect(af, foreColor, left, top, width, height);

   /* [OK] restore defaults */
   WaitForFifo(af, 1);
   mm_port(mmDPSRC) = mach64_dpsrc;
}



/* DrawColorPattRect:
 *  Fills a rectangle using the current color pattern and mix mode.
 */
void DrawColorPattRect(AF_DRIVER *af, long left, long top, long width, long height)
{
   int orig_bank = af_bank;
   int patx, paty;
   int x, y;

   for (y=0; y<height; y++) {
      for (x=0; x<width; x++) {
	 patx = (left+x)&7;
	 paty = (top+y)&7;

	 af_putpixel(af, left+x, top+y, current_color_pattern[paty*8+patx], af_fore_mix);
      }
   }

   if (af_bank != orig_bank)
      af->SetBank(af, orig_bank);
}



/* BitBlt:
 *  Blits from one part of video memory to another, using the specified
 *  mix operation. This must correctly handle the case where the two
 *  regions overlap.
 */
void BitBlt(AF_DRIVER *af, long left, long top, long width, long height, long dstLeft, long dstTop, long op)
{
   if (af_bpp == 24) {
      left *= 3;
      width *= 3;
      dstLeft *= 3;

      WaitForFifo(af, 1);
      mm_port(mmDCNTL) = mach64_dcntl | m64_rot24(dstLeft);
   }

   WaitForFifo(af, 2);

   /* [OK] set blt source and mix mode */
   mm_port(mmDPSRC) = (DS_BLIT<<8) | DS_BGCOL;
   mm_port(mmDPMIX) = (mach64_mix[op]<<16) | mach64_mix[op];

#if 0
   if ((left+width > dstLeft) && (top+height > dstTop) &&
       (dstLeft+width > left) && (dstTop+height > top) &&
       ((dstTop > top) || ((dstTop == top) && (dstLeft > left)))) {
#else
   /* [OK] looks like the mach64 only needs to reverse the Y direction */
   if ((top+height > dstTop) && (dstTop > top)) {
#endif
      /* have to do the copy backward */
      WaitForFifo(af, 9);
      mm_port(mmDCNTL) = (mach64_dcntl&~DC_Y_T2B)|DC_Y_B2T;

      /* [OK] do the blit */
      mm_port(mmSX) = left;
      mm_port(mmSY) = top + height + af_active_page*af_height;
      mm_port(mmSHT1) = height;
      mm_port(mmSWDTH1) = width;

      mm_port(mmDX) = dstLeft;
      mm_port(mmDY) = dstTop + height + af_active_page*af_height;
      mm_port(mmDHT) = height;
      mm_port(mmDWDTH) = width;

      /* [OK] restore defaults */
      WaitForFifo(af, 1);
      mm_port(mmDCNTL) = mach64_dcntl;
   } else {
      WaitForFifo(af, 8);

      /* [OK] do the blit */
      mm_port(mmSX) = left;
      mm_port(mmSY) = top + af_active_page*af_height;
      mm_port(mmSHT1) = height;
      mm_port(mmSWDTH1) = width;

      mm_port(mmDX) = dstLeft;
      mm_port(mmDY) = dstTop + af_active_page*af_height;
      mm_port(mmDHT) = height;
      mm_port(mmDWDTH) = width;

      if (af_bpp == 24) {
	 WaitForFifo(af, 1);
	 mm_port(mmDCNTL) = mach64_dcntl;
      }
   }

   /* [OK] restore defaults */
   WaitForFifo(af, 2);
   mm_port(mmDPMIX) = mach64_dpmix;
   mm_port(mmDPSRC) = mach64_dpsrc;
}



/* SrcTransBlt:
 *  Blits from one part of video memory to another, using the specified
 *  mix operation and skipping any source pixels which match the specified
 *  transparent color. Results are undefined if the two regions overlap.
 */
void SrcTransBlt(AF_DRIVER *af, long left, long top, long width, long height, long dstLeft, long dstTop, long op, unsigned long transparent)
{
 /* [OK] note: this routine doesn't work in 24bpp for some reason,
	 so it is disabled at mode set */
#if 0
   if (af_bpp == 24) {
      left *= 3;
      width *= 3;
      dstLeft *= 3;

      WaitForFifo(af, 1);
      mm_port(mmDCNTL) = mach64_dcntl | m64_rot24(dstLeft);
   }
#endif

   WaitForFifo(af, 4);
   /* [OK] set transparency color */
   mm_port(mmCCMPCLR) = transparent;
   mm_port(mmCCMPCNTL) = CC_EQUAL | CC_SRC;

   /* [OK] set blt source and mix mode */
   mm_port(mmDPSRC) = (DS_BLIT<<8) | DS_BLIT;
   mm_port(mmDPMIX) = (mach64_mix[op]<<16) | mach64_mix[op];

   WaitForFifo(af, 8);

   /* [OK] do the blit */
   mm_port(mmSX) = left;
   mm_port(mmSY) = top + af_active_page*af_height;
   mm_port(mmSHT1) = height;
   mm_port(mmSWDTH1) = width;

   mm_port(mmDX) = dstLeft;
   mm_port(mmDY) = dstTop + af_active_page*af_height;
   mm_port(mmDHT) = height;
   mm_port(mmDWDTH) = width;

   /* [OK] restore defaults */
   WaitForFifo(af, 3);
   mm_port(mmDPMIX) = mach64_dpmix;
   mm_port(mmDPSRC) = mach64_dpsrc;
   mm_port(mmCCMPCNTL) = 0;

#if 0
   if (af_bpp == 24) {
      WaitForFifo(af, 1);
      mm_port(mmDCNTL) = mach64_dcntl;
   }
#endif
}

void DrawLine(AF_DRIVER *af, unsigned long color, fixed x1, fixed y1, fixed x2, fixed y2)
{
 /* [OK] note: this routine won't work in 24bpp, so it is disabled at mode set */

 int dx, dy, dir=0, v1, v2, err, inc, dec;

 /* [OK] I'm not quite sure yet how to do fractional coordinates */
 /* [OK] just round them to integers for now */
 x1 = (x1+0x8000) >> 16;
 y1 = (y1+0x8000) >> 16;
 x2 = (x2+0x8000) >> 16;
 y2 = (y2+0x8000) >> 16;

 /* [OK] calculate Bresenham parameters */
 if (x1 < x2) {
  dx = x2 - x1; dir |= 1;
 } else
  dx = x1 - x2;

 if (y1 < y2) {
  dy = y2 - y1; dir |= 2;
 } else
  dy = y1 - y2;

 if (dx < dy) {
  v1 = dx; v2 = dy; dir |= 4;
 } else {
  v1 = dy; v2 = dx;
 }

 inc = 2*v1;
 err = inc - v2;
 /* [OK] I don't know what this 0x3FFFF is for, it was just part
	 of the mach64 source code I had access to... */
 dec = 0x3FFFF - 2*(v2-v1);

 /* [OK] do the line */
 WaitForFifo(af, 8);
 mm_port(mmDPFGCOL) = color;
 mm_port(mmDX) = x1;
 mm_port(mmDY) = y1 + af_active_page*af_height;
 mm_port(mmDCNTL) = (mach64_dcntl&(DC_LAST_P|DC_POLY)) | dir;
 mm_port(mmDBRSERR) = err;
 mm_port(mmDBRSINC) = inc;
 mm_port(mmDBRSDEC) = dec;
 mm_port(mmDBRSLEN) = (v2 + 1);

 WaitForFifo(af, 1);
 mm_port(mmDCNTL) = mach64_dcntl;
}

