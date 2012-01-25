/*
 *       ______             ____  ______     _____  ______ 
 *      |  ____|           |  _ \|  ____|   / / _ \|  ____|
 *      | |__ _ __ ___  ___| |_) | |__     / / |_| | |__ 
 *      |  __| '__/ _ \/ _ \  _ <|  __|   / /|  _  |  __|
 *      | |  | | |  __/  __/ |_) | |____ / / | | | | |
 *      |_|  |_|  \___|\___|____/|______/_/  |_| |_|_|
 *
 *
 *      Stub driver implementation file.
 *
 *      Note: this driver implements all the hardware accelerated 
 *      functions that are used by Allegro, but does them in software. 
 *      This is intended to give you an example of how they are 
 *      supposed to work: in a real driver you would either implement
 *      them in hardware or leave them out altogether.
 *
 *      See freebe.txt for copyright information.
 */


/* Define this symbol to include emulated versions of the hardware 
 * accelerator drawing routines. Without it, the driver will only 
 * provide the minimum of functions needed for dumb framebuffer access.
 */

#define USE_ACCEL



/* Define this symbol to give the install program an option of disabling
 * some of our drawing routines.
 */

#define USE_FEATURES



/* Define this symbol to disable farptr access to video memory. Without
 * it, the FreeBE/AF hardware pointer extension will be used, avoiding
 * reliance on the fat-DS nearptr hack.
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



/* if you need some video memory for internal use by the accelerator
 * code (for example storing pattern data), you can define this value to 
 * reserve room for yourself at the very end of the memory space, that
 * the application will not be allowed to use.
 */
#define RESERVED_VRAM   0



/* list which ports we are going to access (only needed under Linux) */
unsigned short ports_table[] = { 0xFFFF };



/* list of features, so the install program can disable some of them */
#ifdef USE_FEATURES

FAF_CONFIG_DATA config_data[] = 
{
   {
      FAF_CFG_FEATURES,

      (fafLinear | fafBanked |
       fafDrawScan | fafDrawPattScan | fafDrawColorPattScan |
       fafDrawRect | fafDrawPattRect | fafDrawColorPattRect |
       fafDrawLine | fafDrawTrap | fafPutMonoImage |
       fafBitBlt | fafBitBltSys |
       fafSrcTransBlt | fafSrcTransBltSys)
   },

   { 0, 0 }
};

#define CFG_FEATURES    config_data[0].value

#endif



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



/* FreeBE/AF extension allowing farptr access to video memory */
FAF_HWPTR_DATA hwptr;



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



/* mode_callback:
 *  Callback for the get_vesa_info() function to add a new resolution to
 *  the table of available modes.
 */
void mode_callback(int vesa_num, int linear, int w, int h, int bpp, int bytes_per_scanline, int redsize, int redpos, int greensize, int greenpos, int bluesize, int bluepos, int rsvdsize, int rsvdpos)
{
   if (num_modes >= MAX_MODES)
      return;

   if ((bpp != 8) && (bpp != 15) && (bpp != 16) && (bpp != 24) && (bpp != 32))
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
   unsigned long linear_addr;
   int vram_size;
   int i;

   /* find out what VESA has to say for itself */
   if (get_vesa_info(&vram_size, &linear_addr, mode_callback) != 0)
      return -1;

   /* pointer to a list of the available mode numbers, ended by -1.
    * Our mode numbers just count up from 1, so the mode numbers can
    * be used as indexes into the mode_list[] table (zero is an
    * invalid mode number, so this indexing must be offset by 1).
    */
   af->AvailableModes = available_modes;

   /* amount of video memory in K */
   af->TotalMemory = vram_size/1024;

   /* driver attributes (see definitions in vbeaf.h) */
   af->Attributes = (afHaveMultiBuffer | 
		     afHaveVirtualScroll | 
		     afHaveBankedBuffer);

   #ifdef USE_ACCEL
      af->Attributes |= afHaveAccel2D;
   #endif

   if (linear_addr)
      af->Attributes |= afHaveLinearBuffer;

   #ifdef USE_FEATURES
      if (!(CFG_FEATURES & fafLinear))
	 af->Attributes &= ~afHaveLinearBuffer;

      if (!(CFG_FEATURES & fafBanked))
	 af->Attributes &= ~afHaveBankedBuffer;
   #endif

   /* banked memory size and location: zero if not supported */
   af->BankSize = 64;
   af->BankedBasePtr = 0xA0000;

   /* linear framebuffer size and location: zero if not supported */
   if (linear_addr) {
      af->LinearSize = vram_size/1024;
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

   /* hardware cursor functions (impossible to emulate in software!) */
   af->SetCursor = NULL;
   af->SetCursorPos = NULL;
   af->SetCursorColor = NULL;
   af->ShowCursor = NULL;

   /* wait until the accelerator hardware has finished drawing */
   #ifdef USE_ACCEL
      af->WaitTillIdle = WaitTillIdle;
   #endif

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

   /* sets the hardware drawing mode (solid, XOR, etc) */
   #ifdef USE_ACCEL
      af->SetMix = SetMix;
   #endif

   /* pattern download functions. May be NULL if patterns not supported */
   #ifdef USE_ACCEL
      af->Set8x8MonoPattern = Set8x8MonoPattern;
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

   /* acclerated drivers must support DrawScan(), but patterns may be NULL */
   #ifdef USE_ACCEL
      af->DrawScan = DrawScan;
      af->DrawPattScan = DrawPattScan;
      af->DrawColorPattScan = DrawColorPattScan;
   #endif

   /* not supported: not used by Allegro */
   af->DrawScanList = NULL;
   af->DrawPattScanList = NULL;
   af->DrawColorPattScanList = NULL;

   /* rectangle filling: may be NULL */
   #ifdef USE_ACCEL
      af->DrawRect = DrawRect;
      af->DrawPattRect = DrawPattRect;
      af->DrawColorPattRect = DrawColorPattRect;
   #endif

   /* line drawing: may be NULL */
   #ifdef USE_ACCEL
      af->DrawLine = DrawLine;
   #endif

   /* not supported: not used by Allegro */
   af->DrawStippleLine = NULL;

   /* trapezoid filling: may be NULL */
   #ifdef USE_ACCEL
      af->DrawTrap = DrawTrap;
   #endif

   /* not supported: not used by Allegro */
   af->DrawTri = NULL;
   af->DrawQuad = NULL;

   /* monochrome character expansion: may be NULL */
   #ifdef USE_ACCEL
      af->PutMonoImage = PutMonoImage;
   #endif

   /* not supported: not used by Allegro */
   af->PutMonoImageLin = NULL;
   af->PutMonoImageBM = NULL;

   /* opaque blitting: may be NULL */
   #ifdef USE_ACCEL
      af->BitBlt = BitBlt;
      af->BitBltSys = BitBltSys;
   #endif

   /* not supported: not used by Allegro */
   af->BitBltLin = NULL;
   af->BitBltBM = NULL;

   /* masked blitting: may be NULL */
   #ifdef USE_ACCEL
      af->SrcTransBlt = SrcTransBlt;
      af->SrcTransBltSys = SrcTransBltSys;
   #endif

   /* not supported: not used by Allegro */
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

   /* allow the install program to disable some features */
   #ifdef USE_FEATURES
      fixup_feature_list(af, CFG_FEATURES);
   #endif

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

   #ifdef USE_FEATURES

      case FAFEXT_CONFIG:
	 /* allow the install program to configure our driver */
	 return config_data;

   #endif

      default:
	 return NULL;
   }
}



/* ExtStub:
 *  Supplemental extension hook: we don't provide any.
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
			   afHaveBankedBuffer);

   #ifdef USE_ACCEL
      modeInfo->Attributes |= afHaveAccel2D;
   #endif

   if (info->linear)
      modeInfo->Attributes |= afHaveLinearBuffer;

   #ifdef USE_FEATURES
      if (!(CFG_FEATURES & fafLinear))
	 modeInfo->Attributes &= ~afHaveLinearBuffer;

      if (!(CFG_FEATURES & fafBanked))
	 modeInfo->Attributes &= ~afHaveBankedBuffer;
   #endif

   modeInfo->XResolution = info->w;
   modeInfo->YResolution = info->h;
   modeInfo->BitsPerPixel = info->bpp;

   /* available pages of video memory */
   modeInfo->MaxBuffers = (af->TotalMemory*1024 - RESERVED_VRAM) / 
			  (info->bytes_per_scanline * info->h);

   /* maximum virtual scanline length in both bytes and pixels. How wide
    * this can go will very much depend on the card: 1024 is pretty safe
    * on anything, but you will want to allow larger limits if the card
    * is capable of them.
    */
   modeInfo->MaxBytesPerScanLine = 1024*BYTES_PER_PIXEL(info->bpp);
   modeInfo->MaxScanLineWidth = 1024;

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
   int linear = ((mode & 0x4000) != 0);
   int noclear = ((mode & 0x8000) != 0);
   long available_vram;
   long used_vram;
   VIDEO_MODE *info;
   RM_REGS r;

   /* reject anything with hardware stereo */
   if (mode & 0x400)
      return -1;

   /* reject linear/banked modes if the install program has disabled them */
   #ifdef USE_FEATURES
      if (linear) {
	 if (!(CFG_FEATURES & fafLinear))
	    return -1;
      }
      else {
	 if (!(CFG_FEATURES & fafBanked))
	    return -1;
      }
   #endif

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

   /* adjust the virtual width for widescreen modes */
   if (virtualX*BYTES_PER_PIXEL(info->bpp) > info->bytes_per_scanline) {
      r.x.ax = 0x4F06;
      r.x.bx = 0;
      r.x.cx = virtualX;
      rm_int(0x10, &r);
      if (r.h.ah)
	 return -1;
      *bytesPerLine = r.x.bx;
   }
   else
      *bytesPerLine = info->bytes_per_scanline;

   /* store info about the current mode */
   af_bpp = info->bpp;
   af_width = *bytesPerLine;
   af_height = MAX(info->h, virtualY);
   af_linear = linear;
   af_visible_page = 0;
   af_active_page = 0;
   af_scroll_x = 0;
   af_scroll_y = 0;
   af_bank = -1;

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

   af_fore_mix = AF_REPLACE_MIX;
   af_back_mix = AF_FORE_MIX;

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
 *  Hardware scrolling function. The waitVRT value may be one of:
 *
 *    -1 = don't set hardware, just store values for next page flip to use
 *     0 = set values and return immediately
 *     1 = set values and wait for retrace
 */
void SetDisplayStart(AF_DRIVER *af, long x, long y, long waitVRT)
{
   RM_REGS r;

   if (waitVRT >= 0) {
      r.x.ax = 0x4F07;
      r.x.bx = (waitVRT) ? 0x80 : 0;
      r.x.cx = x;
      r.x.dx = y + af_visible_page*af_height;

      rm_int(0x10, &r);
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
      } while (inportb(0x3DA) & 8);

      do {
      } while (!(inportb(0x3DA) & 8));
   }

   for (i=0; i<num; i++) {
      outportb(0x3C8, index+i);
      outportb(0x3C9, pal[i].red/4);
      outportb(0x3C9, pal[i].green/4);
      outportb(0x3C9, pal[i].blue/4);
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
 *  The code below uses the DPMI "simulate real mode interrupt" routine
 *  (int 0x31, function 0x300) to call the VESA bank switcher (0x4F05).
 *  It is equivalent to the C version:
 *
 *    RM_REGS r;
 *
 *    r.x.ax = 0x4F05;
 *    r.x.bx = 0;
 *    r.x.dx = bank;
 *    rm_int(0x10, &r);
 */

asm ("

   .globl _SetBank32, _SetBank32End

      .align 4
   _SetBank32:
      pushal
      subl $56, %esp                   # RM_REGS structure on the stack
      movw $0x4F05, 32(%esp)           # r.x.ax = 0x4F05
      movw $0, 20(%esp)                # r.x.bx = 0
      movw %dx, 24(%esp)               # r.x.dx = bank number
      movw $0, 36(%esp)                # r.x.flags = 0
      movw $0, 50(%esp)                # r.x.sp = 0
      movw $0, 52(%esp)                # r.x.ss = 0
      movl $0x300, %eax                # %eax = 0x300
      movl $0x10, %ebx                 # %ebx = 0x10
      movl $0, %ecx                    # %ecx = 0
      leal 4(%esp), %edi               # %edi = RM_REGS structure
      int $0x31                        # real mode VESA call
      addl $56, %esp 
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



/* WaitTillIdle:
 *  Delay until the hardware controller has finished drawing.
 */
void WaitTillIdle(AF_DRIVER *af)
{
   /* fill in with whatever your hardware requires */
}



/* SetMix:
 *  Specifies the pixel mix mode to be used for hardware drawing functions
 *  (not the blit routines: they take an explicit mix parameter). Both
 *  parameters should be one of the AF_mixModes enum defined in vbeaf.h.
 *
 *  VBE/AF requires all drivers to support the REPLACE, AND, OR, XOR,
 *  and NOP foreground mix types, and a background mix of zero (same as
 *  the foreground) or NOP. This file implements all the required types, 
 *  but Allegro only actually uses the REPLACE and XOR modes for scanline 
 *  and rectangle fills, REPLACE mode for blitting and color pattern 
 *  drawing, and either REPLACE or foreground REPLACE and background NOP 
 *  for mono pattern drawing.
 *
 *  If you want, you can set the afHaveROP2 bit in the mode attributes
 *  field and then implement all the AF_R2_* modes as well, but that isn't
 *  required by the spec, and Allegro never uses them.
 */
void SetMix(AF_DRIVER *af, long foreMix, long backMix)
{
   af_fore_mix = foreMix;

   if (backMix == AF_FORE_MIX)
      af_back_mix = foreMix;
   else
      af_back_mix = backMix;
}



/* af_putpixel:
 *  Writes a pixel to the screen with the specified mix mode. This function
 *  is _not_ intended to be useful: it is grossly inefficient! It is just
 *  a helper for the example drawing routines below: these should of course
 *  be replaced by hardware specific code.
 */
void af_putpixel(AF_DRIVER *af, int x, int y, int c, int mix)
{
   FAF_HWPTR *p;
   long offset;
   int bank;
   int c2 = 0;

   y += af_active_page*af_height;
   offset = y*af_width + x*BYTES_PER_PIXEL(af_bpp);

   /* quit if this is a noop */
   if (mix == AF_NOP_MIX)
      return;

   /* get pointer to vram */
   if (af_linear) {
      p = &hwptr.LinearMem;
   }
   else {
      bank = offset>>16;
      if (bank != af_bank) {
	 af->SetBank(af, bank);
	 af_bank = bank;
      }
      p = &hwptr.BankedMem;
      offset &= 0xFFFF;
   }

   if (mix != AF_REPLACE_MIX) {
      /* read destination pixel for mixing */
      switch (af_bpp) {

	 case 8:
	    c2 = hwptr_peekb(*p, offset);
	    break;

	 case 15:
	 case 16:
	    c2 = hwptr_peekw(*p, offset);
	    break;

	 case 24:
	    c2 = hwptr_peekl(*p, offset) & 0xFFFFFF;
	    break;

	 case 32:
	    c2 = hwptr_peekl(*p, offset);
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
	 hwptr_pokeb(*p, offset, c);
	 break;

      case 15:
      case 16:
	 hwptr_pokew(*p, offset, c);
	 break;

      case 24:
	 hwptr_pokew(*p, offset, c&0xFFFF);
	 hwptr_pokeb(*p, offset+2, c>>16);
	 break;

      case 32:
	 hwptr_pokel(*p, offset, c&0xFFFF);
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
   FAF_HWPTR *p;
   long offset;
   int bank;

   y += af_active_page*af_height;
   offset = y*af_width + x*BYTES_PER_PIXEL(af_bpp);

   /* get pointer to vram */
   if (af_linear) {
      p = &hwptr.LinearMem;
   }
   else {
      bank = offset>>16;
      if (bank != af_bank) {
	 af->SetBank(af, bank);
	 af_bank = bank;
      }
      p = &hwptr.BankedMem;
      offset &= 0xFFFF;
   }

   /* read the pixel */
   switch (af_bpp) {

      case 8:
	 return hwptr_peekb(*p, offset);

      case 15:
      case 16:
	 return hwptr_peekw(*p, offset);

      case 24:
	 return hwptr_peekl(*p, offset) & 0xFFFFFF;

      case 32:
	 return hwptr_peekl(*p, offset);
   }

   return 0;
}



/* mem_getpixel:
 *  Reads a pixel from an image stored in system memory. This function is 
 *  _not_ intended to be useful: it is grossly inefficient! It is just a 
 *  helper for the example drawing routines below.
 */
int mem_getpixel(void *addr, int pitch, int x, int y)
{
   addr += y*pitch + x*BYTES_PER_PIXEL(af_bpp);

   switch (af_bpp) {

      case 8:
	 return *((unsigned char *)addr);

      case 15:
      case 16:
	 return *((unsigned short *)addr);

      case 24:
	 return *((unsigned long *)addr) & 0xFFFFFF;

      case 32:
	 return *((unsigned long *)addr);
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
}



/* stored color pattern data */
unsigned long color_pattern[8][64];
unsigned long *current_color_pattern = color_pattern[0];



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
   int orig_bank = af_bank;

   if (x2 < x1) {
      int tmp = x1;
      x1 = x2;
      x2 = tmp;
   }

   while (x1 < x2) {
      af_putpixel(af, x1, y, color, af_fore_mix);
      x1++;
   }

   if (af_bank != orig_bank)
      af->SetBank(af, orig_bank);
}



/* DrawPattScan:
 *  Fills a scanline using the current mono pattern. Set pattern bits are
 *  drawn using the specified foreground color and the foreground mix
 *  mode, and clear bits use the background color and background mix mode.
 */
void DrawPattScan(AF_DRIVER *af, long foreColor, long backColor, long y, long x1, long x2)
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

      if (mono_pattern[paty] & (0x80>>patx))
	 af_putpixel(af, x1, y, foreColor, af_fore_mix);
      else
	 af_putpixel(af, x1, y, backColor, af_back_mix);

      x1++;
   }

   if (af_bank != orig_bank)
      af->SetBank(af, orig_bank);
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
   int orig_bank = af_bank;
   int x, y;

   for (y=0; y<height; y++)
      for (x=0; x<width; x++)
	 af_putpixel(af, left+x, top+y, color, af_fore_mix);

   if (af_bank != orig_bank)
      af->SetBank(af, orig_bank);
}



/* DrawPattRect:
 *  Fills a rectangle using the current mono pattern. Set pattern bits are
 *  drawn using the specified foreground color and the foreground mix
 *  mode, and clear bits use the background color and background mix mode.
 */
void DrawPattRect(AF_DRIVER *af, unsigned long foreColor, unsigned long backColor, long left, long top, long width, long height)
{
   int orig_bank = af_bank;
   int patx, paty;
   int x, y;

   for (y=0; y<height; y++) {
      for (x=0; x<width; x++) {
	 patx = (left+x)&7;
	 paty = (top+y)&7;

	 if (mono_pattern[paty] & (0x80>>patx))
	    af_putpixel(af, left+x, top+y, foreColor, af_fore_mix);
	 else
	    af_putpixel(af, left+x, top+y, backColor, af_back_mix);
      }
   }

   if (af_bank != orig_bank)
      af->SetBank(af, orig_bank);
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



/* DrawLine:
 *  Draws a line between the two specified points (inclusive of both), 
 *  which are specified in 16.16 fixed point format, using the current
 *  foreground mix mode.
 */
void DrawLine(AF_DRIVER *af, unsigned long color, fixed x1, fixed y1, fixed x2, fixed y2)
{
   int orig_bank = af_bank;
   int start, end, dir, p;
   fixed delta;

   if (ABS(x1-x2) > ABS(y1-y2)) {
      /* x-driven drawer */
      start = (x1 >> 16) + ((x1 & 0x8000) >> 15);
      end = (x2 >> 16) + ((x2 & 0x8000) >> 15);
      dir = (start < end) ? 1 : -1;

      if (start != end)
	 delta = (y2-y1) / ABS(start-end);
      else
	 delta = 0;

      while (start != end+dir) {
	 p = (y1 >> 16) + ((y1 & 0x8000) >> 15);
	 af_putpixel(af, start, p, color, af_fore_mix);
	 start += dir;
	 y1 += delta;
      }
   }
   else {
      /* y-driven drawer */
      start = (y1 >> 16) + ((y1 & 0x8000) >> 15);
      end = (y2 >> 16) + ((y2 & 0x8000) >> 15);
      dir = (start < end) ? 1 : -1;

      if (start != end)
	 delta = (x2-x1) / ABS(start-end);
      else
	 delta = 0;

      while (start != end+dir) {
	 p = (x1 >> 16) + ((x1 & 0x8000) >> 15);
	 af_putpixel(af, p, start, color, af_fore_mix);
	 start += dir;
	 x1 += delta;
      }
   }

   if (af_bank != orig_bank)
      af->SetBank(af, orig_bank);
}



/* DrawTrap:
 *  Fills a trapezoid, using the current foreground mix mode. This is a
 *  workhorse routine used for polygon filling. The x coordinates and slope 
 *  values in the AF_TRAP structure specify position and deltas for both 
 *  sides of the shape in 16.16 fixed point format. The two edges are 
 *  allowed to cross, and the fill should be inclusive of the left edge but
 *  exclusive of the right. At the end of the routine, the x coordinates
 *  in the AF_TRAP structure should be updated to reflect their modified 
 *  positions after the edge has been traced.
 */
void DrawTrap(AF_DRIVER *af, unsigned long color, AF_TRAP *trap)
{
   int ix1, ix2;

   while (trap->count--) {
      ix1 = (trap->x1 >> 16) + ((trap->x1 & 0x8000) >> 15);
      ix2 = (trap->x2 >> 16) + ((trap->x2 & 0x8000) >> 15);

      if (ix2 < ix1) {
	 int tmp = ix1;
	 ix1 = ix2;
	 ix2 = tmp;
      }

      if (ix1 < ix2)
	 DrawScan(af, color, trap->y, ix1, ix2);

      trap->x1 += trap->slope1;
      trap->x2 += trap->slope2;
      trap->y++;
   }
}



/* PutMonoImage:
 *  Expands a monochrome image from system memory onto the screen. Set bits 
 *  are drawn using the specified foreground color and the foreground mix
 *  mode, and clear bits use the background color and background mix mode.
 */
void PutMonoImage(AF_DRIVER *af, long foreColor, long backColor, long dstX, long dstY, long byteWidth, long srcX, long srcY, long width, long height, unsigned char *image)
{
   int orig_bank = af_bank;
   unsigned char c;
   int x, y;

   for (y=0; y<height; y++) {
      for (x=0; x<width; x++) {
	 c = image[(srcY+y)*byteWidth + (srcX+x)/8];

	 if (c & (0x80>>((srcX+x)&7)))
	    af_putpixel(af, dstX+x, dstY+y, foreColor, af_fore_mix);
	 else
	    af_putpixel(af, dstX+x, dstY+y, backColor, af_back_mix);
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
   int orig_bank = af_bank;
   int x, y, c;

   if ((left+width > dstLeft) && (top+height > dstTop) &&
       (dstLeft+width > left) && (dstTop+height > top) &&
       ((dstTop > top) || ((dstTop == top) && (dstLeft > left)))) {
      /* have to do the copy backward */
      for (y=height-1; y>=0; y--) {
	 for (x=width-1; x>=0; x--) {
	    c = af_getpixel(af, left+x, top+y);
	    af_putpixel(af, dstLeft+x, dstTop+y, c, op);
	 }
      }
   }
   else {
      /* copy in the normal forwards direction */
      for (y=0; y<height; y++) {
	 for (x=0; x<width; x++) {
	    c = af_getpixel(af, left+x, top+y);
	    af_putpixel(af, dstLeft+x, dstTop+y, c, op);
	 }
      }
   }

   if (af_bank != orig_bank)
      af->SetBank(af, orig_bank);
}



/* BitBltSys:
 *  Copies an image from system memory onto the screen.
 */
void BitBltSys(AF_DRIVER *af, void *srcAddr, long srcPitch, long srcLeft, long srcTop, long width, long height, long dstLeft, long dstTop, long op)
{
   int orig_bank = af_bank;
   int x, y, c;

   for (y=0; y<height; y++) {
      for (x=0; x<width; x++) {
	 c = mem_getpixel(srcAddr, srcPitch, srcLeft+x, srcTop+y);
	 af_putpixel(af, dstLeft+x, dstTop+y, c, op);
      }
   }

   if (af_bank != orig_bank)
      af->SetBank(af, orig_bank);
}



/* SrcTransBlt:
 *  Blits from one part of video memory to another, using the specified
 *  mix operation and skipping any source pixels which match the specified
 *  transparent color. Results are undefined if the two regions overlap.
 */
void SrcTransBlt(AF_DRIVER *af, long left, long top, long width, long height, long dstLeft, long dstTop, long op, unsigned long transparent)
{
   int orig_bank = af_bank;
   int x, y, c;

   for (y=0; y<height; y++) {
      for (x=0; x<width; x++) {
	 c = af_getpixel(af, left+x, top+y);
	 if (c != (int)transparent)
	    af_putpixel(af, dstLeft+x, dstTop+y, c, op);
      }
   }

   if (af_bank != orig_bank)
      af->SetBank(af, orig_bank);
}



/* SrcTransBltSys:
 *  Copies an image from system memory onto the screen, skipping any source 
 *  pixels which match the specified transparent color.
 */
void SrcTransBltSys(AF_DRIVER *af, void *srcAddr, long srcPitch, long srcLeft, long srcTop, long width, long height, long dstLeft, long dstTop, long op, unsigned long transparent)
{
   int orig_bank = af_bank;
   int x, y, c;

   for (y=0; y<height; y++) {
      for (x=0; x<width; x++) {
	 c = mem_getpixel(srcAddr, srcPitch, srcLeft+x, srcTop+y);
	 if (c != (int)transparent)
	    af_putpixel(af, dstLeft+x, dstTop+y, c, op);
      }
   }

   if (af_bank != orig_bank)
      af->SetBank(af, orig_bank);
}

