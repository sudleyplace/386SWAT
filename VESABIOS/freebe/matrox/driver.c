/*
 *       ______             ____  ______     _____  ______ 
 *      |  ____|           |  _ \|  ____|   / / _ \|  ____|
 *      | |__ _ __ ___  ___| |_) | |__     / / |_| | |__ 
 *      |  __| '__/ _ \/ _ \  _ <|  __|   / /|  _  |  __|
 *      | |  | | |  __/  __/ |_) | |____ / / | | | | |
 *      |_|  |_|  \___|\___|____/|______/_/  |_| |_|_|
 *
 *
 *      Accelerated Matrox driver, by Shawn Hargreaves.
 *
 *      See freebe.txt for copyright information.
 */


// #define NO_HWPTR


#include <pc.h>

#include "vbeaf.h"



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
void SetCursor(AF_DRIVER *af, AF_CURSOR *cursor);
void SetCursorPos(AF_DRIVER *af, long x, long y);
void SetCursorColor(AF_DRIVER *af, unsigned char red, unsigned char green, unsigned char blue);
void ShowCursor(AF_DRIVER *af, long visible);
void WaitTillIdle(AF_DRIVER *af);
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
void DrawLine(AF_DRIVER *af, unsigned long color, fixed x1, fixed y1, fixed x2, fixed y2);
void DrawTrap(AF_DRIVER *af, unsigned long color, AF_TRAP *trap);
void PutMonoImage(AF_DRIVER *af, long foreColor, long backColor, long dstX, long dstY, long byteWidth, long srcX, long srcY, long width, long height, unsigned char *image);
void BitBlt(AF_DRIVER *af, long left, long top, long width, long height, long dstLeft, long dstTop, long op);
void BitBltSys(AF_DRIVER *af, void *srcAddr, long srcPitch, long srcLeft, long srcTop, long width, long height, long dstLeft, long dstTop, long op);
void SrcTransBlt(AF_DRIVER *af, long left, long top, long width, long height, long dstLeft, long dstTop, long op, unsigned long transparent);
void SrcTransBltSys(AF_DRIVER *af, void *srcAddr, long srcPitch, long srcLeft, long srcTop, long width, long height, long dstLeft, long dstTop, long op, unsigned long transparent);



/* FreeBE/AF extension allowing farptr access to video memory */
FAF_HWPTR_DATA hwptr;



/* mode information from the underlying VESA driver */
typedef struct VIDEO_MODE
{
   int vesa_num;
   int linear;
   int w;
   int h;
   int bpp;
   int bytes_per_scanline;
   int redsize;
   int redpos;
   int greensize;
   int greenpos;
   int bluesize;
   int bluepos;
   int rsvdsize;
   int rsvdpos;
} VIDEO_MODE;


#define MAX_MODES    64

VIDEO_MODE mode_list[MAX_MODES];

short available_modes[MAX_MODES+1] = { -1 };

int num_modes = 0;


unsigned short ports_table[] = { 0xFFFF };


/* list of features, so the install program can disable some of them */
FAF_CONFIG_DATA config_data[] = 
{
   {
      FAF_CFG_FEATURES,

      (fafLinear | fafBanked | fafHWCursor |
       fafDrawScan | fafDrawPattScan | fafDrawColorPattScan |
       fafDrawRect | fafDrawPattRect | fafDrawColorPattRect |
       fafDrawLine | fafDrawTrap | fafPutMonoImage |
       fafBitBlt | fafBitBltSys |
       fafSrcTransBlt | fafSrcTransBltSys)
   },

   { 0, 0 }
};

#define CFG_FEATURES    config_data[0].value


/* cache eight 8x8 color patterns at the end of vram */
int pat_off_bytes[8];
int pat_off_pixels[8];

#define PATTERN_VRAM(bpp)  ((bpp == 8) ? 512 : ((bpp == 32) ? 3072 : 1536))


/* hardware cursors are only supported on the Mystique */
#define HAS_HW_CURSOR      (matrox_id == MATROX_MYST_ID)

#define HW_CURSOR_VRAM     ((HAS_HW_CURSOR) ? 1024 : 0)

int cur_color;

int cur_doublemode;

int cur_hot_x;
int cur_hot_y;


/* prevent applications from using our reserved video memory */
#define RESERVED_VRAM(bpp)    (PATTERN_VRAM(bpp) + HW_CURSOR_VRAM)


/* video mode and driver state information */
int af_bpp;
int af_width_bytes;
int af_width_pixels;
int af_height;
int af_visible_page;
int af_active_page;
int af_scroll_x;
int af_scroll_y;
int af_y;
int af_fore_mix;
int af_back_mix;
int af_color_pattern;

AF_PALETTE af_palette[256];


/* cached drawing engine state */
#define OP_NONE                  0
#define OP_DRAWRECT              1
#define OP_DRAWPATTRECT          2
#define OP_DRAWCOLORPATTRECT     3
#define OP_DRAWLINE              4
#define OP_DRAWTRAP              5
#define OP_DRAWSLOWTRAP          6
#define OP_PUTMONOIMAGE_LINEAR   7
#define OP_PUTMONOIMAGE_SLOW     8
#define OP_BITBLT_FORWARD        9
#define OP_BITBLT_BACKWARD       10
#define OP_BITBLTSYS             11
#define OP_SRCTRANSBLT           12
#define OP_SRCTRANSBLTSYS        13


int af_operation;



/* PCI device identifiers */
#define MATROX_VENDOR_ID         0x102B

#define MATROX_MILL_ID           0x0519
#define MATROX_MYST_ID           0x051A
#define MATROX_MII_PCI_ID        0x051B
#define MATROX_MII_AGP_ID        0x051F


int matrox_id_list[] = {
   MATROX_MILL_ID,
   MATROX_MYST_ID,
   MATROX_MII_PCI_ID,
   MATROX_MII_AGP_ID,
   0
};


int matrox_id;
int matrox_rev;



/* Matrox hardware registers: */

#define M_DWGCTL              0x1C00
#define M_MACCESS             0x1C04

#define M_PAT0                0x1C10
#define M_PAT1                0x1C14
#define M_PLNWT               0x1C1C

#define M_BCOL                0x1C20
#define M_FCOL                0x1C24

#define M_SRC0                0x1C30
#define M_SRC1                0x1C34
#define M_SRC2                0x1C38
#define M_SRC3                0x1C3C

#define M_XYSTRT              0x1C40
#define M_XYEND               0x1C44

#define M_SHIFT               0x1C50

#define M_SGN                 0x1C58

#define M_SDXL                0x02
#define M_SDXR                0x20

#define M_LEN                 0x1C5C

#define M_AR0                 0x1C60
#define M_AR1                 0x1C64
#define M_AR2                 0x1C68
#define M_AR3                 0x1C6C
#define M_AR4                 0x1C70
#define M_AR5                 0x1C74
#define M_AR6                 0x1C78

#define M_CXBNDRY             0x1C80
#define M_FXBNDRY             0x1C84
#define M_YDSTLEN             0x1C88
#define M_PITCH               0x1C8C

#define M_YDST                0x1C90
#define M_YDSTORG             0x1C94
#define M_YTOP                0x1C98
#define M_YBOT                0x1C9C

#define M_CXLEFT              0x1CA0
#define M_CXRIGHT             0x1CA4
#define M_FXLEFT              0x1CA8
#define M_FXRIGHT             0x1CAC

#define M_XDST                0x1CB0

#define M_EXEC                0x0100

#define M_FIFOSTATUS          0x1E10
#define M_STATUS              0x1E14
#define M_ICLEAR              0x1E18
#define M_IEN                 0x1E1C

#define M_VCOUNT              0x1E20

#define M_RESET               0x1E40

#define M_OPMODE              0x1E54

#define M_DMA_GENERAL         0x00
#define M_DMA_BLIT            0x04
#define M_DMA_VECTOR          0x40

#define M_DWG_LINE_OPEN       0x00
#define M_DWG_AUTOLINE_OPEN   0x01
#define M_DWG_LINE_CLOSE      0x02
#define M_DWG_AUTOLINE_CLOSE  0x03

#define M_DWG_TRAP            0x04
#define M_DWG_TEXTURE_TRAP    0x05

#define M_DWG_BITBLT          0x08
#define M_DWG_FBITBLT         0x0C
#define M_DWG_ILOAD           0x09
#define M_DWG_ILOAD_SCALE     0x0D
#define M_DWG_ILOAD_FILTER    0x0F
#define M_DWG_IDUMP           0x0A

#define M_DWG_LINEAR          0x0080
#define M_DWG_SOLID           0x0800
#define M_DWG_ARZERO          0x1000
#define M_DWG_SGNZERO         0x2000
#define M_DWG_SHIFTZERO       0x4000

#define M_DWG_BPLAN           0x02000000
#define M_DWG_BFCOL           0x04000000
#define M_DWG_BMONOWF         0x08000000

#define M_DWG_PATTERN         0x20000000
#define M_DWG_TRANSC          0x40000000

#define M_CRTC_INDEX          0x1FD4
#define M_CRTC_DATA           0x1FD5

#define M_CRTC_EXT_INDEX      0x1FDE
#define M_CRTC_EXT_DATA       0x1FDF



/* Mystique-only registers: */

#define M_PALWTADD            0x3C00
#define M_X_DATAREG           0x3C0A

#define M_CURPOS              0x3C0C

#define M_XCURADDL            0x04
#define M_XCURADDH            0x05 

#define M_XCURCTRL            0x06

#define M_XCURCOL0RED         0x08
#define M_XCURCOL0GREEN       0x09
#define M_XCURCOL0BLUE        0x0A
#define M_XCURCOL1RED         0x0C
#define M_XCURCOL1GREEN       0x0D
#define M_XCURCOL1BLUE        0x0E
#define M_XCURCOL2RED         0x10
#define M_XCURCOL2GREEN       0x11
#define M_XCURCOL2BLUE        0x12

#define M_CURCTRL_OFF         0
#define M_CURCTRL_3COLOR      1
#define M_CURCTRL_XGA         2
#define M_CURCTRL_XWINDOWS    3



/* helpers for accessing the Matrox registers */
#define mga_select()          hwptr_select(hwptr.IOMemMaps[0])
#define mga_inb(addr)         hwptr_nspeekb(hwptr.IOMemMaps[0], addr)
#define mga_inw(addr)         hwptr_nspeekw(hwptr.IOMemMaps[0], addr)
#define mga_inl(addr)         hwptr_nspeekl(hwptr.IOMemMaps[0], addr)
#define mga_outb(addr, val)   hwptr_nspokeb(hwptr.IOMemMaps[0], addr, val)
#define mga_outw(addr, val)   hwptr_nspokew(hwptr.IOMemMaps[0], addr, val)
#define mga_outl(addr, val)   hwptr_nspokel(hwptr.IOMemMaps[0], addr, val)



/* mga_xdata:
 *  Writes to one of the Mystique cursor control registers.
 */
#define mga_xdata(reg, val)                        \
{                                                  \
   mga_outb(M_PALWTADD, reg);                      \
   mga_outb(M_X_DATAREG, val);                     \
}



/* mga_fifo:
 *  Waits until there are at least <n> free slots in the FIFO buffer.
 */
#define mga_fifo(n)                                \
{                                                  \
   do {                                            \
   } while (mga_inb(M_FIFOSTATUS) < (n));          \
}



/* bswap:
 *  Toggles the endianess of a 32 bit integer.
 */
unsigned long bswap(unsigned long n)
{
   unsigned long a = n&0xFF;
   unsigned long b = (n>>8)&0xFF;
   unsigned long c = (n>>16)&0xFF;
   unsigned long d = (n>>24)&0xFF;

   return (a<<24) | (b<<16) | (c<<8) | d;
}



/* mga_wait_retrace:
 *  Waits for the next vertical sync period.
 */
void mga_wait_retrace(AF_DRIVER *af)
{
   int t1 = 0;
   int t2 = 0;

   do {
      t1 = t2;
      t2 = mga_inl(M_VCOUNT);
   } while (t2 >= t1);
}



/* mode_callback:
 *  Callback for the get_vesa_info() function to add a new resolution to
 *  the table of available modes.
 */
void mode_callback(int vesa_num, int linear, int w, int h, int bpp, int bytes_per_scanline, int redsize, int redpos, int greensize, int greenpos, int bluesize, int bluepos, int rsvdsize, int rsvdpos)
{
   if (num_modes >= MAX_MODES)
      return;

   if ((bpp != 8) && (bpp != 15) && (bpp != 16) && (bpp != 32))
      return;

   mode_list[num_modes].vesa_num = vesa_num;
   mode_list[num_modes].linear = linear;
   mode_list[num_modes].w = w;
   mode_list[num_modes].h = h;
   mode_list[num_modes].bpp = bpp;
   mode_list[num_modes].bytes_per_scanline = bytes_per_scanline;
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



/* SetupDriver:
 *  The first thing ever to be called after our code has been relocated.
 *  This is in charge of filling in the driver header with all the required
 *  information and function pointers. We do not yet have access to the
 *  video memory, so we can't talk directly to the card.
 */
int SetupDriver(AF_DRIVER *af)
{
   unsigned long pci_base[2];
   int vram_size;
   int bus_id;
   char *name;
   int i;

   /* find PCI device */
   matrox_id = 0;
   bus_id = 0;

   for (i=0; matrox_id_list[i]; i++) {
      if (FindPCIDevice(matrox_id_list[i], MATROX_VENDOR_ID, 0, &bus_id)) {
	 matrox_id = matrox_id_list[i];
	 break;
      }
   }

   if (!matrox_id)
      return -1;

   /* read hardware configuration data */
   matrox_rev = PCIReadLong(bus_id, 8) & 0xFF;

   for (i=0; i<2; i++)
      pci_base[i] = PCIReadLong(bus_id, 16+i*4);

   /* fetch mode list from the VESA driver */
   if (get_vesa_info(&vram_size, NULL, mode_callback) != 0)
      return -1;

   af->AvailableModes = available_modes;

   af->TotalMemory = vram_size/1024;

   af->Attributes = (afHaveMultiBuffer | 
		     afHaveVirtualScroll | 
		     afHaveBankedBuffer | 
		     afHaveLinearBuffer |
		     afHaveAccel2D);

   if (!(CFG_FEATURES & fafLinear))
      af->Attributes &= ~afHaveLinearBuffer;

   if (!(CFG_FEATURES & fafBanked))
      af->Attributes &= ~afHaveBankedBuffer;

   if (HAS_HW_CURSOR)
      af->Attributes |= afHaveHWCursor;

   af->BankSize = 64;
   af->BankedBasePtr = 0xA0000;

   af->IOPortsTable = ports_table;

   /* work out the linear framebuffer and MMIO addresses */
   if (((matrox_id == MATROX_MYST_ID) && (matrox_rev >= 3)) ||
       (matrox_id == MATROX_MII_PCI_ID) ||
       (matrox_id == MATROX_MII_AGP_ID)) {
      if (pci_base[0])
	 af->LinearBasePtr = pci_base[0] & 0xFF800000;

      if (pci_base[1])
	 af->IOMemoryBase[0] = pci_base[1] & 0xFFFFC000;
   }
   else {
      if (pci_base[0])
	 af->IOMemoryBase[0] = pci_base[0] & 0xFFFFC000;

      if (pci_base[1])
	 af->LinearBasePtr = pci_base[1] & 0xFF800000;
   }

   if ((!af->LinearBasePtr) || (!af->IOMemoryBase[0]))
      return -1;

   af->LinearSize = vram_size/1024;
   af->IOMemoryLen[0] = 0x4000;

   /* set up the driver name */
   switch (matrox_id) {

      case MATROX_MILL_ID:
	 name = "Millenium";
	 break;

      case MATROX_MYST_ID:
	 name = "Mystique";
	 break;

      case MATROX_MII_PCI_ID:
	 name = "Millenium II PCI";
	 break;

      case MATROX_MII_AGP_ID:
	 name = "Millenium II AGP";
	 break;

      default:
	 name = "Unknown Matrox";
	 break;
   } 

   i = 0;
   while (af->OemVendorName[i])
      i++;

   af->OemVendorName[i++] = ',';
   af->OemVendorName[i++] = ' ';

   while (*name)
      af->OemVendorName[i++] = *(name++);

   af->OemVendorName[i] = 0;

   /* set up driver functions */
   af->SetBank32 = SetBank32;
   af->SetBank32Len = (long)SetBank32End - (long)SetBank32;

   af->SupplementalExt = ExtStub;
   af->GetVideoModeInfo = GetVideoModeInfo;
   af->SetVideoMode = SetVideoMode;
   af->RestoreTextMode = RestoreTextMode;
   af->GetClosestPixelClock = GetClosestPixelClock;
   af->SaveRestoreState = SaveRestoreState;
   af->SetDisplayStart = SetDisplayStart;
   af->SetActiveBuffer = SetActiveBuffer;
   af->SetVisibleBuffer = SetVisibleBuffer;
   af->GetDisplayStartStatus = GetDisplayStartStatus;
   af->SetPaletteData = SetPaletteData;
   af->SetBank = SetBank;
   af->WaitTillIdle = WaitTillIdle;
   af->SetMix = SetMix;
   af->Set8x8MonoPattern = Set8x8MonoPattern;
   af->DrawScan = DrawScan;
   af->DrawPattScan = DrawPattScan;
   af->DrawRect = DrawRect;
   af->DrawPattRect = DrawPattRect;
   af->DrawLine = DrawLine;
   af->DrawTrap = DrawTrap;
   af->PutMonoImage = PutMonoImage;
   af->BitBlt = BitBlt;
   af->BitBltSys = BitBltSys;

   fixup_feature_list(af, CFG_FEATURES);

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
   /* initialise farptr video memory access */
   hwptr_init(hwptr.IOMemMaps[0], af->IOMemMaps[0]);
   hwptr_init(hwptr.IOMemMaps[1], af->IOMemMaps[1]);
   hwptr_init(hwptr.IOMemMaps[2], af->IOMemMaps[2]);
   hwptr_init(hwptr.IOMemMaps[3], af->IOMemMaps[3]);
   hwptr_init(hwptr.BankedMem, af->BankedMem);
   hwptr_init(hwptr.LinearMem, af->LinearMem);

   return 0;
}



/* FreeBEX:
 *  Returns an interface structure for the requested FreeBE/AF extension.
 */
void *FreeBEX(AF_DRIVER *af, unsigned long id)
{
   switch (id) {

   #ifndef NO_HWPTR

      case FAFEXT_HWPTR:
	 /* allow farptr access to video memory */
	 return &hwptr;

   #endif 

      case FAFEXT_CONFIG:
	 /* allow the install program to configure our driver */
	 return config_data;

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
   int i;

   if ((mode <= 0) || (mode > num_modes))
      return -1;

   info = &mode_list[mode-1];

   /* clear the structure to zero */
   for (i=0; i<(int)sizeof(AF_MODE_INFO); i++)
      ((char *)modeInfo)[i] = 0;

   /* copy data across from our stored list of mode attributes */
   modeInfo->Attributes = (afHaveMultiBuffer | 
			   afHaveVirtualScroll | 
			   afHaveBankedBuffer | 
			   afHaveAccel2D);

   if (info->linear) {
      modeInfo->Attributes |= afHaveLinearBuffer;

      if (HAS_HW_CURSOR)
	 modeInfo->Attributes |= afHaveHWCursor;
   }

   if (!(CFG_FEATURES & fafLinear))
      modeInfo->Attributes &= ~afHaveLinearBuffer;

   if (!(CFG_FEATURES & fafBanked))
      modeInfo->Attributes &= ~afHaveBankedBuffer;

   modeInfo->XResolution = info->w;
   modeInfo->YResolution = info->h;
   modeInfo->BitsPerPixel = info->bpp;

   /* available pages of video memory */
   modeInfo->MaxBuffers = (af->TotalMemory*1024 - RESERVED_VRAM(info->bpp)) / 
			  (info->bytes_per_scanline * info->h);

   /* maximum virtual scanline length in both bytes and pixels */
   modeInfo->MaxBytesPerScanLine = 2048*BYTES_PER_PIXEL(info->bpp);
   modeInfo->MaxScanLineWidth = 2048;

   /* for banked video modes, fill in these variables: */
   modeInfo->BytesPerScanLine = info->bytes_per_scanline;
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
   modeInfo->LinBytesPerScanLine = info->bytes_per_scanline;
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
   static int millenium_strides[] = 
   {
      640, 768, 800, 960, 1024, 1152, 1280, 1600, 1920, 2048, 0
   };

   /* for some reason, 800 pixel wide screens seem to upset the drawing
    * engine on my Mystique. I fixed this by leaving them out of this table,
    * so the virtual width will be rounded up to 832: this seems to correct
    * the problem, but I've no idea why! According to the specs, 800 should
    * be a valid pitch.
    */
   static int mystique_strides[] =
   {
      512, 640, 768, 832, 960, 1024, 1152, 1280, 1600, 1664, 1920, 2048, 0
   };

   int linear = ((mode & 0x4000) != 0);
   int noclear = ((mode & 0x8000) != 0);
   long available_vram;
   long used_vram;
   int *strides;
   VIDEO_MODE *info;
   RM_REGS r;
   int i;

   /* reject anything with hardware stereo */
   if (mode & 0x400)
      return -1;

   /* reject linear/banked modes if the install program has disabled them */
   if (linear) {
      if (!(CFG_FEATURES & fafLinear))
	 return -1;
   }
   else {
      if (!(CFG_FEATURES & fafBanked))
	 return -1;
   }

   /* mask off the other flag bits */
   mode &= 0x3FF;

   if ((mode <= 0) || (mode > num_modes))
      return -1;

   info = &mode_list[mode-1];

   /* reject the linear flag if the mode doesn't support it */
   if ((linear) && (!info->linear))
      return -1;

   /* call VESA to set the mode */
   r.x.ax = 0x4F02;
   r.x.bx = info->vesa_num;
   if (linear)
      r.x.bx |= 0x4000;
   if (noclear)
      r.x.bx |= 0x8000;
   rm_int(0x10, &r);
   if (r.h.ah)
      return -1;

   /* round the virtual width up to a suitable value */
   *bytesPerLine = MAX(info->bytes_per_scanline, virtualX*BYTES_PER_PIXEL(info->bpp));

   if (matrox_id == MATROX_MYST_ID)
      strides = mystique_strides;
   else
      strides = millenium_strides;

   for (i=0; strides[i]; i++) {
      if (*bytesPerLine <= strides[i]*BYTES_PER_PIXEL(info->bpp)) {
	 *bytesPerLine = strides[i]*BYTES_PER_PIXEL(info->bpp);
	 break;
      }
   }

   /* wider than this would overflow the 7k window used by BitBltSys() */
   if (*bytesPerLine > 4096)
      return -1;

   /* adjust the virtual screen width */
   if (matrox_id != MATROX_MILL_ID) {
      write_vga_register(0x3D4, 0x13, (*bytesPerLine/16)&0xFF);
      alter_vga_register(0x3DE, 0, 0x30, ((*bytesPerLine/16)>>4)&0x30);
   }
   else {
      write_vga_register(0x3D4, 0x13, (*bytesPerLine/8)&0xFF);
      alter_vga_register(0x3DE, 0, 0x30, ((*bytesPerLine/8)>>4)&0x30);
   }

   /* store info about the current mode */
   af_bpp = info->bpp;
   af_width_bytes = *bytesPerLine;
   af_width_pixels = *bytesPerLine/BYTES_PER_PIXEL(af_bpp);
   af_height = MAX(info->h, virtualY);
   af_visible_page = 0;
   af_active_page = 0;
   af_scroll_x = 0;
   af_scroll_y = 0;
   af_y = 0;

   /* return framebuffer dimensions to the application */
   af->BufferEndX = af_width_pixels-1;
   af->BufferEndY = af_height-1;
   af->OriginOffset = 0;

   used_vram = af_width_bytes * af_height * numBuffers;
   available_vram = af->TotalMemory*1024 - RESERVED_VRAM(af_bpp);

   if (used_vram > available_vram)
      return -1;

   if (available_vram-used_vram >= af_width_bytes) {
      af->OffscreenOffset = used_vram;
      af->OffscreenStartY = af_height*numBuffers;
      af->OffscreenEndY = available_vram/af_width_bytes-1;
   }
   else {
      af->OffscreenOffset = 0;
      af->OffscreenStartY = 0;
      af->OffscreenEndY = 0;
   }

   af_fore_mix = AF_REPLACE_MIX;
   af_back_mix = AF_FORE_MIX;

   af_color_pattern = 0;

   af_operation = OP_NONE;

   /* set up the accelerator engine */
   mga_select();

   mga_fifo(8);
   mga_outl(M_PITCH, af_width_pixels);
   mga_outl(M_YDSTORG, 0);
   mga_outl(M_PLNWT, 0xFFFFFFFF);
   mga_outl(M_OPMODE, M_DMA_BLIT);
   mga_outl(M_CXBNDRY, 0xFFFF0000);
   mga_outl(M_YTOP, 0x00000000);
   mga_outl(M_YBOT, 0x007FFFFF);

   switch (af_bpp) {

      case 8:
	 mga_outl(M_MACCESS, 0);
	 break;

      case 15:
	 mga_outl(M_MACCESS, 0xC0000001);
	 break;

      case 16:
	 mga_outl(M_MACCESS, 0x40000001);
	 break;

      case 32:
	 mga_outl(M_MACCESS, 2);
	 break;
   }

   /* only enable colored patterns and hardware cursors in linear modes */
   if (linear) {
      af->Set8x8ColorPattern = Set8x8ColorPattern;
      af->Use8x8ColorPattern = Use8x8ColorPattern;
      af->DrawColorPattScan = DrawColorPattScan;
      af->DrawColorPattRect = DrawColorPattRect;

      if (HAS_HW_CURSOR) {
	 af->SetCursor = SetCursor;
	 af->SetCursorPos = SetCursorPos;
	 af->SetCursorColor = SetCursorColor;
	 af->ShowCursor = ShowCursor;

	 cur_doublemode = (info->h < 400);
	 cur_color = -1;
      }
      else {
	 af->SetCursor = NULL;
	 af->SetCursorPos = NULL;
	 af->SetCursorColor = NULL;
	 af->ShowCursor = NULL;
      }
   }
   else {
      af->Set8x8ColorPattern = NULL;
      af->Use8x8ColorPattern = NULL;
      af->DrawColorPattScan = NULL;
      af->DrawColorPattRect = NULL;

      af->SetCursor = NULL;
      af->SetCursorPos = NULL;
      af->SetCursorColor = NULL;
      af->ShowCursor = NULL;
   }

   /* masked blitting is only possible on the Mystique */
   if (matrox_id != MATROX_MILL_ID) {
      af->SrcTransBlt = SrcTransBlt;

      /* in truecolor modes, this is faster without using the hardware! */
      if (af_bpp == 8)
	 af->SrcTransBltSys = SrcTransBltSys;
      else
	 af->SrcTransBltSys = NULL;
   }

   /* deal with odd alignment/interleaving rules for color pattern data */
   i = (af->TotalMemory*1024 - HW_CURSOR_VRAM) / BYTES_PER_PIXEL(af_bpp);

   if (af_bpp == 8) { 
      pat_off_pixels[0] = i-512;
      pat_off_pixels[1] = i-512+8;
      pat_off_pixels[2] = i-512+16;
      pat_off_pixels[3] = i-512+24;
      pat_off_pixels[4] = i-256;
      pat_off_pixels[5] = i-256+8;
      pat_off_pixels[6] = i-256+16;
      pat_off_pixels[7] = i-256+24;
   }
   else {
      pat_off_pixels[0] = i-768;
      pat_off_pixels[1] = i-768+8;
      pat_off_pixels[2] = i-768+16;
      pat_off_pixels[3] = i-512;
      pat_off_pixels[4] = i-512+8;
      pat_off_pixels[5] = i-512+16;
      pat_off_pixels[6] = i-256;
      pat_off_pixels[7] = i-256+8;
   }

   for (i=0; i<8; i++)
      pat_off_bytes[i] = pat_off_pixels[i] * BYTES_PER_PIXEL(af_bpp);

   fixup_feature_list(af, CFG_FEATURES);

   return 0;
}



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
   long addr;

   mga_select();

   if (waitVRT >= 0) {

      if ((waitVRT) && (matrox_id == MATROX_MYST_ID))
	 mga_wait_retrace(af);

      addr = (((y + af_visible_page*af_height) * af_width_bytes) + 
	      (x*BYTES_PER_PIXEL(af_bpp)));

      if (matrox_id != MATROX_MILL_ID)
	 addr /= 8;
      else
	 addr /= 4;

      write_vga_register(0x3D4, 0x0D, (addr)&0xFF);
      write_vga_register(0x3D4, 0x0C, (addr>>8)&0xFF);
      alter_vga_register(0x3DE, 0, 0x0F, (addr>>16)&0x0F);

      if ((waitVRT) && (matrox_id != MATROX_MYST_ID))
	 mga_wait_retrace(af);
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
   af_y = index*af_height;

   af_operation = OP_NONE;

   af->OriginOffset = af_width_bytes*af_height*index;

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

   mga_select();

   if (waitVRT)
      mga_wait_retrace(af);

   for (i=0; i<num; i++) {
      outportb(0x3C8, index+i);
      outportb(0x3C9, pal[i].red/4);
      outportb(0x3C9, pal[i].green/4);
      outportb(0x3C9, pal[i].blue/4);

      af_palette[index+i] = pal[i];
   }

   if ((af_bpp == 8) && (cur_color >= 0) && 
       (((cur_color >= index) && (cur_color < index+num)) || (index == 0)))
      SetCursorColor(af, cur_color, 0, 0);
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
      movb %dl, %ah
      movb $4, %al
      movw $0x03DE, %dx
      outw %ax, %dx
      popl %edx
      popl %eax
      ret

   _SetBank32End:

");



/* SetBank:
 *  C-callable bank switch function. This version simply chains to the
 *  relocatable SetBank32() above.
 */
void SetBank(AF_DRIVER *af, long bank)
{
   asm (
      " call _SetBank32 "
   :
   : "d" (bank)
   );
}



/* SetCursor:
 *  Sets the hardware cursor shape.
 */
void SetCursor(AF_DRIVER *af, AF_CURSOR *cursor)
{
   int addr = af->TotalMemory*1024 - HW_CURSOR_VRAM;
   int p = addr;
   int i;

   hwptr_select(hwptr.LinearMem);

   if (cur_doublemode) {
      for (i=0; i<32; i++) {
	 hwptr_nspokel(hwptr.LinearMem, p, 0);
	 p += 4;
	 hwptr_nspokel(hwptr.LinearMem, p, bswap(cursor->xorMask[i]));
	 p += 4;
	 hwptr_nspokel(hwptr.LinearMem, p, 0xFFFFFFFF);
	 p += 4;
	 hwptr_nspokel(hwptr.LinearMem, p, bswap(~cursor->andMask[i]));
	 p += 4;
	 hwptr_nspokel(hwptr.LinearMem, p, 0);
	 p += 4;
	 hwptr_nspokel(hwptr.LinearMem, p, bswap(cursor->xorMask[i]));
	 p += 4;
	 hwptr_nspokel(hwptr.LinearMem, p, 0xFFFFFFFF);
	 p += 4;
	 hwptr_nspokel(hwptr.LinearMem, p, bswap(~cursor->andMask[i]));
	 p += 4;
      }
   }
   else {
      for (i=0; i<32; i++) {
	 hwptr_nspokel(hwptr.LinearMem, p, 0);
	 p += 4;
	 hwptr_nspokel(hwptr.LinearMem, p, bswap(cursor->xorMask[i]));
	 p += 4;
	 hwptr_nspokel(hwptr.LinearMem, p, 0xFFFFFFFF);
	 p += 4;
	 hwptr_nspokel(hwptr.LinearMem, p, bswap(~cursor->andMask[i]));
	 p += 4;
      }

      for (i=0; i<32; i++) {
	 hwptr_nspokel(hwptr.LinearMem, p, 0);
	 p += 4;
	 hwptr_nspokel(hwptr.LinearMem, p, 0);
	 p += 4;
	 hwptr_nspokel(hwptr.LinearMem, p, 0xFFFFFFFF);
	 p += 4;
	 hwptr_nspokel(hwptr.LinearMem, p, 0xFFFFFFFF);
	 p += 4;
      }
   }

   mga_select();

   mga_xdata(M_XCURADDL, (addr/1024)&0xFF);
   mga_xdata(M_XCURADDH, (addr/1024)>>8);

   cur_hot_x = cursor->hotx;
   cur_hot_y = cursor->hoty;
}



/* SetCursorPos:
 *  Sets the hardware cursor position.
 */
void SetCursorPos(AF_DRIVER *af, long x, long y)
{
   x -= cur_hot_x;
   y -= cur_hot_y;

   mga_select();

   if (cur_doublemode)
      y *= 2;

   mga_outl(M_CURPOS, ((y+64)<<16) | (x+64));
}



/* SetCursorColor:
 *  Sets the hardware cursor color.
 */
void SetCursorColor(AF_DRIVER *af, unsigned char red, unsigned char green, unsigned char blue)
{
   int r2, g2, b2;

   mga_select();

   if (af_bpp == 8) {
      cur_color = red;

      red = af_palette[cur_color].red;
      green = af_palette[cur_color].green;
      blue = af_palette[cur_color].blue;

      r2 = af_palette[0].red;
      g2 = af_palette[0].green;
      b2 = af_palette[0].blue;
   }
   else {
      cur_color = -1;

      r2 = ~red;
      g2 = ~green;
      b2 = ~blue;
   }

   mga_xdata(M_XCURCOL0RED,   r2);
   mga_xdata(M_XCURCOL0GREEN, b2);
   mga_xdata(M_XCURCOL0BLUE,  b2);
   mga_xdata(M_XCURCOL1RED,   red);
   mga_xdata(M_XCURCOL1GREEN, green);
   mga_xdata(M_XCURCOL1BLUE,  blue);
}



/* ShowCursor:
 *  Turns the hardware cursor on or off.
 */
void ShowCursor(AF_DRIVER *af, long visible)
{
   mga_select();

   mga_xdata(M_XCURCTRL, (visible) ? M_CURCTRL_XGA : M_CURCTRL_OFF);
}



/* WaitTillIdle:
 *  Delay until the hardware controller has finished drawing.
 */
void WaitTillIdle(AF_DRIVER *af)
{
   FAF_HWPTR oldptr;
   int tries = 2;

   hwptr_unselect(oldptr);

   mga_select();

   while (tries--) {

      do {
      } while (!(mga_inl(M_FIFOSTATUS) & 0x200));

      do {
      } while (mga_inl(M_STATUS) & 0x10000);

      mga_outb(M_CRTC_INDEX, 0); 
   }

   hwptr_select(oldptr);
}



/* mga_mix:
 *  Returns drawing engine control flags for the specified VBE/AF mix mode.
 */
long mga_mix(int mix)
{
   switch (mix) {

      case AF_REPLACE_MIX: 
	 return 0x000C0040;

      case AF_AND_MIX: 
	 return 0x00080010;

      case AF_OR_MIX: 
	 return 0x000E0010;

      case AF_XOR_MIX: 
	 return 0x00060010;

      default: 
	 return 0x000A0010; 
   }
}



/* mga_mix_noblk:
 *  Returns drawing engine control flags for the specified VBE/AF mix mode.
 */
long mga_mix_noblk(int mix)
{
   switch (mix) {

      case AF_REPLACE_MIX: 
	 return 0x000C0000;

      case AF_AND_MIX: 
	 return 0x00080010;

      case AF_OR_MIX: 
	 return 0x000E0010;

      case AF_XOR_MIX: 
	 return 0x00060010;

      default: 
	 return 0x000A0010; 
   }
}



/* SetMix:
 *  Specifies the pixel mix mode to be used for hardware drawing functions.
 */
void SetMix(AF_DRIVER *af, long foreMix, long backMix)
{
   af_fore_mix = foreMix;
   af_back_mix = backMix;

   af_operation = OP_NONE;
}



/* Set8x8MonoPattern:
 *  Downloads a monochrome (packed bit) pattern, for use by the 
 *  DrawPattScan() and DrawPattRect() functions. This is always sized
 *  8x8, and aligned with the top left corner of video memory: if other
 *  alignments are desired, the pattern will be prerotated before it 
 *  is passed to this routine.
 */
void Set8x8MonoPattern(AF_DRIVER *af, unsigned char *pattern)
{
   unsigned long d1, d2;

   d1 = pattern[0] | (pattern[1]<<8) | (pattern[2]<<16) | (pattern[3]<<24);
   d2 = pattern[4] | (pattern[5]<<8) | (pattern[6]<<16) | (pattern[7]<<24);

   mga_select();

   mga_fifo(2);
   mga_outl(M_PAT0, d1);
   mga_outl(M_PAT1, d2);
}



/* Set8x8ColorPattern:
 *  Downloads a color pattern, for use by the DrawColorPattScan() and
 *  DrawColorPattRect() functions. This is always sized 8x8, and aligned
 *  with the top left corner of video memory: if other alignments are
 *  desired, the pattern will be prerotated before it is passed to this
 *  routine. The color values are presented in the native format for
 *  the current video mode, but padded to 32 bits (so the pattern is
 *  always an 8x8 array of longs).
 */
void Set8x8ColorPattern(AF_DRIVER *af, int index, unsigned long *pattern)
{
   int p = pat_off_bytes[index];
   int x, y;

   hwptr_select(hwptr.LinearMem);

   switch (af_bpp) {

      case 8:
	 for (y=0; y<8; y++)
	    for (x=0; x<8; x++)
	       hwptr_nspokeb(hwptr.LinearMem, p+(y*32+x), pattern[y*8+x]);
	 break;

      case 15:
      case 16:
	 for (y=0; y<8; y++)
	    for (x=0; x<8; x++)
	       hwptr_nspokew(hwptr.LinearMem, p+(y*32+x)*2, pattern[y*8+x]);
	 break;

      case 32:
	 for (y=0; y<8; y++)
	    for (x=0; x<8; x++)
	       hwptr_nspokel(hwptr.LinearMem, p+(y*32+x)*4, pattern[y*8+x]);
	 break;
   }
}



/* Use8x8ColorPattern:
 *  Selects one of the patterns previously downloaded by Set8x8ColorPattern().
 */
void Use8x8ColorPattern(AF_DRIVER *af, int index)
{
   af_color_pattern = index;
}



/* DrawScan:
 *  Fills a scanline in the current foreground mix mode. Draws up to but
 *  not including the second x coordinate. If the second coord is less
 *  than the first, they are swapped. If they are equal, nothing is drawn.
 */
void DrawScan(AF_DRIVER *af, long color, long y, long x1, long x2)
{
   if (x1 < x2)
      DrawRect(af, color, x1, y, x2-x1, 1);
   else if (x2 < x1)
      DrawRect(af, color, x2, y, x1-x2, 1);
}



/* DrawPattScan:
 *  Fills a scanline using the current mono pattern. Set pattern bits are
 *  drawn using the specified foreground color and the foreground mix
 *  mode, and clear bits use the background color and background mix mode.
 */
void DrawPattScan(AF_DRIVER *af, long foreColor, long backColor, long y, long x1, long x2)
{
   if (x1 < x2)
      DrawPattRect(af, foreColor, backColor, x1, y, x2-x1, 1);
   else if (x2 < x1)
      DrawPattRect(af, foreColor, backColor, x2, y, x1-x2, 1);
}



/* DrawColorPattScan:
 *  Fills a scanline using the current color pattern and mix mode.
 */
void DrawColorPattScan(AF_DRIVER *af, long y, long x1, long x2)
{
   if (x1 < x2)
      DrawColorPattRect(af, x1, y, x2-x1, 1);
   else if (x2 < x1)
      DrawColorPattRect(af, x2, y, x1-x2, 1);
}



/* DrawRect:
 *  Fills a rectangle in the current foreground mix mode.
 */
void DrawRect(AF_DRIVER *af, unsigned long color, long left, long top, long width, long height)
{
   long cmd;

   mga_select();

   /* set engine state */
   if (af_operation != OP_DRAWRECT) {

      cmd = M_DWG_TRAP | M_DWG_SOLID | M_DWG_ARZERO | 
	    M_DWG_SGNZERO | M_DWG_SHIFTZERO;

      if ((matrox_id == MATROX_MII_PCI_ID) || 
	  (matrox_id == MATROX_MII_AGP_ID))
	 cmd |= M_DWG_TRANSC;

      mga_fifo(1);
      mga_outl(M_DWGCTL, cmd | mga_mix(af_fore_mix));

      af_operation = OP_DRAWRECT;
   }

   /* make the color a dword */
   if (af_bpp == 8) {
      color |= color<<8;
      color |= color<<16;
   }
   else if (af_bpp < 32) {
      color |= color<<16;
   }

   /* draw the rectangle */
   mga_fifo(3);
   mga_outl(M_FCOL, color);
   mga_outl(M_FXBNDRY, ((left+width)<<16) | left);
   mga_outl(M_YDSTLEN | M_EXEC, ((top+af_y)<<16) | height);
}



/* DrawPattRect:
 *  Fills a rectangle using the current mono pattern. Set pattern bits are
 *  drawn using the specified foreground color and the foreground mix
 *  mode, and clear bits use the background color and background mix mode.
 */
void DrawPattRect(AF_DRIVER *af, unsigned long foreColor, unsigned long backColor, long left, long top, long width, long height)
{
   long cmd;

   mga_select();

   /* set engine state */
   if (af_operation != OP_DRAWPATTRECT) {

      cmd = M_DWG_TRAP | M_DWG_ARZERO | M_DWG_SGNZERO | M_DWG_SHIFTZERO;

      if (af_back_mix == AF_NOP_MIX)
	 cmd |= mga_mix(af_fore_mix) | M_DWG_TRANSC;
      else
	 cmd |= mga_mix_noblk(af_fore_mix);

      mga_fifo(1);
      mga_outl(M_DWGCTL, cmd);

      af_operation = OP_DRAWPATTRECT;
   }

   /* make the color a dword */
   if (af_bpp == 8) {
      foreColor |= foreColor<<8;
      foreColor |= foreColor<<16;
   }
   else if (af_bpp < 32) {
      foreColor |= foreColor<<16;
   }

   /* sort out the background color */
   if (af_back_mix == AF_NOP_MIX) {
      backColor = 0;
   }
   else {
      if (af_bpp == 8) {
	 backColor |= backColor<<8;
	 backColor |= backColor<<16;
      }
      else if (af_bpp < 32) {
	 backColor |= backColor<<16;
      }
   }

   /* draw the rectangle */
   mga_fifo(4);
   mga_outl(M_FCOL, foreColor);
   mga_outl(M_BCOL, backColor);
   mga_outl(M_FXBNDRY, ((left+width)<<16) | left);
   mga_outl(M_YDSTLEN | M_EXEC, ((top+af_y)<<16) | height);
}



/* DrawColorPattRect:
 *  Fills a rectangle using the current color pattern and mix mode.
 */
void DrawColorPattRect(AF_DRIVER *af, long left, long top, long width, long height)
{
   int addr, addr2, offs;

   mga_select();

   /* set engine state */
   if (af_operation != OP_DRAWCOLORPATTRECT) {
      mga_fifo(1);
      mga_outl(M_DWGCTL, M_DWG_BITBLT | M_DWG_SGNZERO | 
			 M_DWG_SHIFTZERO | M_DWG_BFCOL | 
			 M_DWG_PATTERN | mga_mix_noblk(af_fore_mix));

      af_operation = OP_DRAWCOLORPATTRECT;
   }

   /* calculate pattern address */
   addr = pat_off_pixels[af_color_pattern] + (left&7) + ((top+af_y)&7)*32;
   offs = (af_bpp == 8) ? 2 : ((af_bpp == 32) ? 6 : 4);
   addr2 = ((addr+offs)&7) | (addr&0xFFFFFFF8);

   /* draw the rectangle */
   mga_fifo(5);
   mga_outl(M_AR0, addr2);
   mga_outl(M_AR3, addr);
   mga_outl(M_AR5, 32);
   mga_outl(M_FXBNDRY, ((left+width-1)<<16) | left);
   mga_outl(M_YDSTLEN | M_EXEC, ((top+af_y)<<16) | height);
}



/* DrawLine:
 *  Draws a line, using the current foreground mix mode.
 */
void DrawLine(AF_DRIVER *af, unsigned long color, fixed x1, fixed y1, fixed x2, fixed y2)
{
   mga_select();

   /* set engine state */
   if (af_operation != OP_DRAWLINE) {
      mga_fifo(1);
      mga_outl(M_DWGCTL, M_DWG_AUTOLINE_CLOSE | M_DWG_SOLID | 
			 M_DWG_SHIFTZERO | mga_mix_noblk(af_fore_mix));

      af_operation = OP_DRAWLINE;
   }

   /* make the color a dword */
   if (af_bpp == 8) {
      color |= color<<8;
      color |= color<<16;
   }
   else if (af_bpp < 32) {
      color |= color<<16;
   }

   /* round coordinates from fixed point to integer */
   x1 = (x1+0x8000) >> 16;
   y1 = (y1+0x8000) >> 16;
   x2 = (x2+0x8000) >> 16;
   y2 = (y2+0x8000) >> 16;

   /* draw the line */
   mga_fifo(3);
   mga_outl(M_FCOL, color);
   mga_outl(M_XYSTRT, ((y1+af_y)<<16) | x1);
   mga_outl(M_XYEND | M_EXEC, ((y2+af_y)<<16) | x2);
}



/* DrawSlowTrap:
 *  Special case trapezoid filler, for handling cases where the two edges
 *  cross. I'm not sure if this is allowed to happen, but I'd rather support
 *  it just in case :-)
 */
static void DrawSlowTrap(AF_DRIVER *af, AF_TRAP *trap)
{
   int ix1, ix2;
   long cmd;

   /* set engine state */
   if (af_operation != OP_DRAWSLOWTRAP) {

      cmd = M_DWG_TRAP | M_DWG_SOLID | M_DWG_ARZERO | 
	    M_DWG_SGNZERO | M_DWG_SHIFTZERO;

      if ((matrox_id == MATROX_MII_PCI_ID) || 
	  (matrox_id == MATROX_MII_AGP_ID))
	 cmd |= M_DWG_TRANSC;

      mga_fifo(1);
      mga_outl(M_DWGCTL, cmd | mga_mix(af_fore_mix));

      af_operation = OP_DRAWSLOWTRAP;
   }

   /* scan-convert the trapezoid */
   while (trap->count--) {
      ix1 = (trap->x1+0x8000) >> 16;
      ix2 = (trap->x2+0x8000) >> 16;

      if (ix2 < ix1) {
	 int tmp = ix1;
	 ix1 = ix2;
	 ix2 = tmp;
      }

      if (ix1 < ix2) {
	 mga_fifo(2);
	 mga_outl(M_FXBNDRY, (ix2<<16) | ix1);
	 mga_outl(M_YDSTLEN | M_EXEC, ((trap->y+af_y)<<16) | 1);
      }

      trap->x1 += trap->slope1;
      trap->x2 += trap->slope2;
      trap->y++;
   }
}



/* DrawTrap:
 *  Draws a filled trapezoid, using the current foreground mix mode.
 */
void DrawTrap(AF_DRIVER *af, unsigned long color, AF_TRAP *trap)
{
   fixed startx1, startx2;
   fixed endx1, endx2;
   fixed tmp;
   int dx1, dx2;
   int sgn = 0;

   mga_select();

   /* make the color a dword */
   if (af_bpp == 8) {
      color |= color<<8;
      color |= color<<16;
   }
   else if (af_bpp < 32) {
      color |= color<<16;
   }

   mga_fifo(1);
   mga_outl(M_FCOL, color);

   /* read the edge coordinates */
   startx1 = trap->x1;
   startx2 = trap->x2;

   endx1 = trap->x1+trap->slope1*trap->count;
   endx2 = trap->x2+trap->slope2*trap->count;

   if (startx1 > startx2) {
      /* special case for when the edges cross */
      if (endx1 < endx2) {
	 DrawSlowTrap(af, trap);
	 return;
      }

      /* make sure the left edge comes first */ 
      tmp = startx1;
      startx1 = startx2;
      startx2 = tmp;

      tmp = endx1;
      endx1 = endx2;
      endx2 = tmp;

      trap->x1 = endx2;
      trap->x2 = endx1;
   }
   else {
      trap->x1 = endx1;
      trap->x2 = endx2;
   }

   /* calculate deltas */
   dx1 = (endx1-startx1) >> 16;
   dx2 = (endx2-startx2) >> 16;

   startx1 = (startx1+0x8000) >> 16;
   startx2 = (startx2+0x8000) >> 16;

   if (dx1 < 0)
      sgn |= M_SDXL;

   if (dx2 < 0)
      sgn |= M_SDXR;

   /* set engine state */
   if (af_operation != OP_DRAWTRAP) {
      mga_fifo(1);
      mga_outl(M_DWGCTL, M_DWG_TRAP | M_DWG_SOLID | 
			 M_DWG_SHIFTZERO | mga_mix(af_fore_mix));

      af_operation = OP_DRAWTRAP;
   }

   /* draw the trapezoid */
   mga_fifo(9);
   mga_outl(M_AR0, trap->count);
   mga_outl(M_AR1, (dx1 < 0) ? dx1+trap->count-1 : -dx1);
   mga_outl(M_AR2, -ABS(dx1));
   mga_outl(M_AR4, (dx2 < 0) ? dx2+trap->count-1 : -dx2);
   mga_outl(M_AR5, -ABS(dx2));
   mga_outl(M_AR6, trap->count);
   mga_outl(M_SGN, sgn);
   mga_outl(M_FXBNDRY, (startx2<<16) | startx1);
   mga_outl(M_YDSTLEN | M_EXEC, ((trap->y+af_y)<<16) | trap->count);

   trap->y += trap->count;
   trap->count = 0;
}



/* PutMonoImage:
 *  Expands a monochrome bitmap from system memory onto the screen.
 */
void PutMonoImage(AF_DRIVER *af, long foreColor, long backColor, long dstX, long dstY, long byteWidth, long srcX, long srcY, long width, long height, unsigned char *image)
{
   unsigned long val;
   int i, n, x, y;
   long cmd;
   int op;

   mga_select();

   /* is the source data in linear format? */
   if ((srcX > 0) || (width != byteWidth*8))
      op = OP_PUTMONOIMAGE_SLOW;
   else
      op = OP_PUTMONOIMAGE_LINEAR;

   /* set engine state */
   if (af_operation != op) {

      cmd = M_DWG_ILOAD | M_DWG_SGNZERO | M_DWG_SHIFTZERO | M_DWG_BMONOWF;

      if (op == OP_PUTMONOIMAGE_LINEAR)
	 cmd |= M_DWG_LINEAR;

      if (af_back_mix == AF_NOP_MIX)
	 cmd |= mga_mix(af_fore_mix) | M_DWG_TRANSC;
      else
	 cmd |= mga_mix_noblk(af_fore_mix);

      mga_fifo(1);
      mga_outl(M_DWGCTL, cmd);

      af_operation = op;
   }

   /* make the color a dword */
   if (af_bpp == 8) {
      foreColor |= foreColor<<8;
      foreColor |= foreColor<<16;
   }
   else if (af_bpp < 32) {
      foreColor |= foreColor<<16;
   }

   /* sort out the background color */
   if (af_back_mix == AF_NOP_MIX) {
      backColor = 0;
   }
   else {
      if (af_bpp == 8) {
	 backColor |= backColor<<8;
	 backColor |= backColor<<16;
      }
      else if (af_bpp < 32) {
	 backColor |= backColor<<16;
      }
   }

   /* skip leading image data */
   image += srcY*byteWidth;

   /* start the hardware engine */
   mga_fifo(6);
   mga_outl(M_FCOL, foreColor);
   mga_outl(M_BCOL, backColor);
   mga_outl(M_AR0, (op == OP_PUTMONOIMAGE_LINEAR) ? width*height-1 : width-1);
   mga_outl(M_AR3, 0);
   mga_outl(M_FXBNDRY, ((dstX+width-1)<<16) | dstX);
   mga_outl(M_YDSTLEN | M_EXEC, ((dstY+af_y)<<16) | height);

   if (op == OP_PUTMONOIMAGE_LINEAR) { 
      /* block copy to the psuedo-dma window */
      n = (width*height+31)/32;

      while (n > 0) {
	 i = MIN(n, 1792);
	 n -= i;

	 #ifdef NO_HWPTR

	    asm (
	       " rep ; movsl "
	    :
	    : "c" (i),
	      "S" (image),
	      "D" (af->IOMemMaps[0])

	    : "%ecx", "%esi", "%edi"
	    );

	 #else

	    asm (
	       " movw %%es, %%dx ; "
	       " movw %%ax, %%es ; "
	       " rep ; movsl ; "
	       " movw %%dx, %%es "
	    :
	    : "c" (i),
	      "S" (image),
	      "D" (hwptr.IOMemMaps[0].offset),
	      "a" (hwptr.IOMemMaps[0].sel)

	    : "%ecx", "%edx", "%esi", "%edi"
	    );

	 #endif
      }
   }
   else {
      /* special munging is required when the source isn't linear */
      for (y=0; y<height; y++) {
	 val = 0;
	 i = 0;

	 for (x=0; x<width; x++) {
	    val <<= 1;
	    if (image[(srcX+x)/8] & (0x80>>((srcX+x)&7)))
	       val |= 1;

	    if (i == 31) {
	       mga_outl(0, bswap(val));
	       val = 0;
	       i = 0;
	    }
	    else
	       i++;
	 }

	 if (i)
	    mga_outl(0, bswap(val<<(32-i)));

	 image += byteWidth;
      }
   }
}



/* BitBlt:
 *  Blits from one part of video memory to another, using the specified
 *  mix operation. This must correctly handle the case where the two
 *  regions overlap.
 */
void BitBlt(AF_DRIVER *af, long left, long top, long width, long height, long dstLeft, long dstTop, long op)
{
   int start, end;
   int operation;

   mga_select();

   /* which direction to copy? */
   if ((left+width > dstLeft) && (top+height > dstTop) &&
       (dstLeft+width > left) && (dstTop+height > top) &&
       ((dstTop > top) || ((dstTop == top) && (dstLeft > left))))
      operation = OP_BITBLT_BACKWARD;
   else
      operation = OP_BITBLT_FORWARD;

   /* set engine state */
   if (af_operation != operation) {
      if (operation == OP_BITBLT_FORWARD) {
	 mga_fifo(2);
	 mga_outl(M_AR5, af_width_pixels);
	 mga_outl(M_DWGCTL, M_DWG_BITBLT | M_DWG_SHIFTZERO |
			    M_DWG_SGNZERO | M_DWG_BFCOL | 
			    mga_mix_noblk(op));
      } 
      else {
	 mga_fifo(3);
	 mga_outl(M_SGN, 5);
	 mga_outl(M_AR5, -af_width_pixels);
	 mga_outl(M_DWGCTL, M_DWG_BITBLT | M_DWG_SHIFTZERO | 
			    M_DWG_BFCOL | mga_mix_noblk(op));
      }

      af_operation = operation;
   }

   /* adjust parameters */
   if (operation == OP_BITBLT_BACKWARD) {
      width--;
      end = (top+af_y+height-1)*af_width_pixels + left;
      start = end+width;
      dstTop += height-1;
   }
   else {
      width--;
      start = (top+af_y)*af_width_pixels + left;
      end = start+width; 
   }

   /* do the blit */
   mga_fifo(4);
   mga_outl(M_AR0, end);
   mga_outl(M_AR3, start);
   mga_outl(M_FXBNDRY, ((dstLeft+width)<<16) | dstLeft);
   mga_outl(M_YDSTLEN | M_EXEC, ((dstTop+af_y)<<16) | height);
}



/* BitBltSys:
 *  Copies from system memory to the screen.
 */
void BitBltSys(AF_DRIVER *af, void *srcAddr, long srcPitch, long srcLeft, long srcTop, long width, long height, long dstLeft, long dstTop, long op)
{
   int i, n;
   void *addr;

   mga_select();

   /* set engine state */
   if (af_operation != OP_BITBLTSYS) {
      mga_fifo(2);
      mga_outl(M_AR5, 0);
      mga_outl(M_DWGCTL, M_DWG_ILOAD | M_DWG_SHIFTZERO | 
			 M_DWG_SGNZERO | M_DWG_BFCOL | 
			 mga_mix_noblk(op));

      af_operation = OP_BITBLTSYS;
   }

   /* adjust source bitmap pointers */
   switch (af_bpp) {

      case 8:
	 addr = srcAddr + srcLeft + srcTop*srcPitch;
	 n = (width+3)/4;
	 break;

      case 15:
      case 16:
	 addr = srcAddr + srcLeft*2 + srcTop*srcPitch;
	 n = (width+1)/2;
	 break;

      case 32:
	 addr = srcAddr + srcLeft*4 + srcTop*srcPitch;
	 n = width;
	 break;

      default:
	 return;
   }

   /* wake up the hardware engine */
   mga_fifo(4);
   mga_outl(M_AR0, width-1);
   mga_outl(M_AR3, 0);
   mga_outl(M_FXBNDRY, ((dstLeft+width-1)<<16) | dstLeft);
   mga_outl(M_YDSTLEN | M_EXEC, ((dstTop+af_y)<<16) | height);

   /* copy data to the psuedo-dma window */
   for (i=0; i<height; i++) {

      #ifdef NO_HWPTR

	 asm (
	    " rep ; movsl "
	 :
	 : "c" (n),
	   "S" (addr),
	   "D" (af->IOMemMaps[0])

	 : "%ecx", "%esi", "%edi"
	 );

      #else

	 asm (
	    " movw %%es, %%dx ; "
	    " movw %%ax, %%es ; "
	    " rep ; movsl ; "
	    " movw %%dx, %%es "
	 :
	 : "c" (n),
	   "S" (addr),
	   "D" (hwptr.IOMemMaps[0].offset),
	   "a" (hwptr.IOMemMaps[0].sel)

	 : "%ecx", "%edx", "%esi", "%edi"
	 );

      #endif

      addr += srcPitch;
   }
}



/* SrcTransBlt:
 *  Blits from one part of video memory to another, using the specified
 *  mix operation and skipping any source pixels which match the specified
 *  transparent color. Results are undefined if the two regions overlap.
 */
void SrcTransBlt(AF_DRIVER *af, long left, long top, long width, long height, long dstLeft, long dstTop, long op, unsigned long transparent)
{
   int start, end;

   mga_select();

   /* set engine state */
   if (af_operation != OP_SRCTRANSBLT) {

      if (af_bpp == 8) {
	 transparent |= transparent<<8;
	 transparent |= transparent<<16;
      }
      else if (af_bpp < 32) {
	 transparent |= transparent<<16;
      }

      mga_fifo(4);
      mga_outl(M_FCOL, transparent);
      mga_outl(M_BCOL, 0xFFFFFFFF);
      mga_outl(M_AR5, af_width_pixels);
      mga_outl(M_DWGCTL, M_DWG_BITBLT | M_DWG_SHIFTZERO | 
			 M_DWG_SGNZERO | M_DWG_BFCOL | 
			 M_DWG_TRANSC | mga_mix_noblk(op));

      af_operation = OP_SRCTRANSBLT;
   }

   /* adjust parameters */
   width--;
   start = (top+af_y)*af_width_pixels + left;
   end = start+width; 

   /* do the blit */
   mga_fifo(4);
   mga_outl(M_AR0, end);
   mga_outl(M_AR3, start);
   mga_outl(M_FXBNDRY, ((dstLeft+width)<<16) | dstLeft);
   mga_outl(M_YDSTLEN | M_EXEC, ((dstTop+af_y)<<16) | height);
}



/* SrcTransBltSys:
 *  Copies from system memory to the screen, skipping any source pixels that
 *  match the specified transparent color.
 */
void SrcTransBltSys(AF_DRIVER *af, void *srcAddr, long srcPitch, long srcLeft, long srcTop, long width, long height, long dstLeft, long dstTop, long op, unsigned long transparent)
{
   int i, n;
   void *addr;

   mga_select();

   /* set engine state */
   if (af_operation != OP_SRCTRANSBLTSYS) {

      if (af_bpp == 8) {
	 transparent |= transparent<<8;
	 transparent |= transparent<<16;
      }
      else if (af_bpp < 32) {
	 transparent |= transparent<<16;
      }

      mga_fifo(4);
      mga_outl(M_FCOL, transparent);
      mga_outl(M_BCOL, 0xFFFFFFFF);
      mga_outl(M_AR5, 0);
      mga_outl(M_DWGCTL, M_DWG_ILOAD | M_DWG_SHIFTZERO | 
			 M_DWG_SGNZERO | M_DWG_BFCOL | 
			 M_DWG_TRANSC | mga_mix_noblk(op));

      af_operation = OP_SRCTRANSBLTSYS;
   }

   /* adjust source bitmap pointers */
   switch (af_bpp) {

      case 8:
	 addr = srcAddr + srcLeft + srcTop*srcPitch;
	 n = (width+3)/4;
	 break;

      case 15:
      case 16:
	 addr = srcAddr + srcLeft*2 + srcTop*srcPitch;
	 n = (width+1)/2;
	 break;

      case 32:
	 addr = srcAddr + srcLeft*4 + srcTop*srcPitch;
	 n = width;
	 break;

      default:
	 return;
   }

   /* wake up the hardware engine */
   mga_fifo(4);
   mga_outl(M_AR0, width-1);
   mga_outl(M_AR3, 0);
   mga_outl(M_FXBNDRY, ((dstLeft+width-1)<<16) | dstLeft);
   mga_outl(M_YDSTLEN | M_EXEC, ((dstTop+af_y)<<16) | height);

   /* copy data to the psuedo-dma window */
   for (i=0; i<height; i++) {

      #ifdef NO_HWPTR

	 asm (
	    " rep ; movsl "
	 :
	 : "c" (n),
	   "S" (addr),
	   "D" (af->IOMemMaps[0])

	 : "%ecx", "%esi", "%edi"
	 );

      #else

	 asm (
	    " movw %%es, %%dx ; "
	    " movw %%ax, %%es ; "
	    " rep ; movsl ; "
	    " movw %%dx, %%es "
	 :
	 : "c" (n),
	   "S" (addr),
	   "D" (hwptr.IOMemMaps[0].offset),
	   "a" (hwptr.IOMemMaps[0].sel)

	 : "%ecx", "%edx", "%esi", "%edi"
	 );

      #endif

      addr += srcPitch;
   }
}

