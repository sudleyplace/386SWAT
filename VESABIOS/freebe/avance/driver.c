/*
 *       ______             ____  ______     _____  ______ 
 *      |  ____|           |  _ \|  ____|   / / _ \|  ____|
 *      | |__ _ __ ___  ___| |_) | |__     / / |_| | |__ 
 *      |  __| '__/ _ \/ _ \  _ <|  __|   / /|  _  |  __|
 *      | |  | | |  __/  __/ |_) | |____ / / | | | | |
 *      |_|  |_|  \___|\___|____/|______/_/  |_| |_|_|
 *
 *
 *      Avance Logic driver file.
 *
 *      See freebe.txt for copyright information.
 */


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


/* if you need some video memory for internal use by the accelerator
 * code (for example storing pattern data), you can define this value to 
 * reserve room for yourself at the very end of the memory space, that
 * the application will not be allowed to use.
 */
#define RESERVED_VRAM   0



/* list which ports we are going to access (only needed under Linux) */
unsigned short ports_table[] = { 0xFFFF };


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
int af_lines_per_bank;


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



#define ALG_NONE    0
#define ALG_2101    1
#define ALG_2201    2
#define ALG_2228    3
#define ALG_2301    4
#define ALG_UNKNOWN 5

int port_crtc = 0x3d4;
int port_attr = 0x3c0;
int port_seq  = 0x3c4;
int port_grc  = 0x3ce;

int alg_version = ALG_NONE, alg_vidmem = 0;

char *alg_name[6] = {
	"none", "ALG-2101", "ALG-2201", "ALG-2228", "ALG-2301", "unknown"
};

int alg_caps[6] = {
	0,
	afHaveMultiBuffer | afHaveBankedBuffer | afHaveVirtualScroll /*| afHaveDualBuffers */,
	afHaveMultiBuffer | afHaveBankedBuffer | afHaveVirtualScroll /*| afHaveDualBuffers */,
	afHaveMultiBuffer | afHaveBankedBuffer | afHaveVirtualScroll /*| afHaveDualBuffers */,
	afHaveMultiBuffer | afHaveBankedBuffer | afHaveVirtualScroll /*| afHaveDualBuffers */,
	0
};

struct mode_t {
	int mode;
	int w,h;
	int bpp;
};

#define MAX_MODES 20

struct mode_t mode_list[] = {
	/*  mode   width   height  bpp */
	{   0x28,    512,    512,   8   },
	{   0x29,    640,    400,   8   },
	{   0x2a,    640,    480,   8   },
	{   0x2c,    800,    600,   8   },
	{   0x2e,    768,   1024,   8   },
	{   0x31,   1024,    768,   8   },
	{   0x33,   1024,   1024,   8   },
	{   0x37,   1280,   1024,   8   },

	{   0x40,    320,    200,  16   },
	{   0x41,    512,    512,  16   },
	{   0x42,    640,    400,  16   },
	{   0x43,    640,    480,  16   },
	{   0x44,    800,    600,  16   },
	{   0x45,   1024,    768,  16   },

	{   0x48,    640,    480,  24   },
	{   0x49,    800,    600,  24   },

	{      0,      0,      0,   0   }
};

short available_modes[MAX_MODES] = { -1 };


static inline void clrinx (int pt, int inx, int val)
{
	write_vga_register (pt, inx, read_vga_register (pt, inx) & ~val);
}

static inline void setinx (int pt, int inx, int val)
{
	write_vga_register (pt, inx, read_vga_register (pt, inx) | val);
}

static inline void modinx (int pt, int inx, int mask, int nwv)
{
	write_vga_register (pt, inx, (read_vga_register (pt, inx) & ~mask) | (nwv & mask));
}


/* detect_alg:
 *  Sees whether or not an Avance Logic graphics card is present,
 *  and if one is it attempts to identify it.
 */
int detect_alg()
{
	int old;

	alg_version = ALG_NONE;
	alg_vidmem = 0;

	old = read_vga_register (port_crtc, 0x1a);
	clrinx (port_crtc, 0x1a, 0x10);
	if (!test_vga_register (port_crtc, 0x19, 0xcf)) {
		setinx (port_crtc, 0x1a, 0x10);
		if (test_vga_register (port_crtc, 0x19, 0xcf) && test_vga_register (port_crtc, 0x1a, 0x3f)) {
			int tmp = read_vga_register (port_crtc, 0x1a) >> 6;
			switch (tmp) {
				case 3:
					alg_version = ALG_2101;
					break;
				case 2:
					if (read_vga_register (port_crtc, 0x1b) & 4)
						alg_version = ALG_2228;
					else
						alg_version = ALG_2301;
					break;
				case 1:
					alg_version = ALG_2201;
				default:
					alg_version = ALG_UNKNOWN;
			}
			alg_vidmem = 256 << (read_vga_register (port_crtc, 0x1e) & 3);
		}
	}
	write_vga_register (port_crtc, 0x1a, old);
	return alg_version;
}


/* create_available_mode_list:
 *  Scans the mode list checking memory requirements.  Modes
 *  which pass the test go into the available_modes list.
 */
void create_available_mode_list()
{
	struct mode_t *mode;
	short *current_mode_in_list = available_modes;

	for (mode = mode_list; mode->mode; mode++)
		if (mode->w * mode->h * BYTES_PER_PIXEL (mode->bpp) < alg_vidmem * 1024)
			*current_mode_in_list++ = mode->mode;

	*current_mode_in_list = -1;
}


/* SetupDriver:
 *  The first thing ever to be called after our code has been relocated.
 *  This is in charge of filling in the driver header with all the required
 *  information and function pointers. We do not yet have access to the
 *  video memory, so we can't talk directly to the card.
 */
int SetupDriver(AF_DRIVER *af)
{
	int i;

	if (!detect_alg()) return -1;

	create_available_mode_list();

	/* pointer to a list of the available mode numbers, ended by -1 */
	af->AvailableModes = available_modes;

	/* amount of video memory in K */
	af->TotalMemory = alg_vidmem;

	/* driver attributes (see definitions in vbeaf.h) */
	af->Attributes = alg_caps[alg_version];

	#if 0
		if (linear_addr)
			af->Attributes |= afHaveLinearBuffer;
	#endif

	/* banked memory size and location: zero if not supported */
	af->BankSize = 64;
	af->BankedBasePtr = 0xA0000;

	/* linear framebuffer size and location: zero if not supported */
	af->LinearSize = 0;
	af->LinearBasePtr = 0;

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

	/* hardware cursor functions */
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
	af->Set8x8MonoPattern = NULL;
	af->Set8x8ColorPattern = NULL;
	af->Use8x8ColorPattern = NULL;

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
	af->DrawScan = NULL;
	af->DrawPattScan = NULL;
	af->DrawColorPattScan = NULL;

	/* not supported: not used by Allegro */
	af->DrawScanList = NULL;
	af->DrawPattScanList = NULL;
	af->DrawColorPattScanList = NULL;

	/* rectangle filling: may be NULL */
	af->DrawRect = NULL;
	af->DrawPattRect = NULL;
	af->DrawColorPattRect = NULL;

	/* line drawing: may be NULL */
	af->DrawLine = NULL;

	/* not supported: not used by Allegro */
	af->DrawStippleLine = NULL;

	/* trapezoid filling: may be NULL */
	af->DrawTrap = NULL;

	/* not supported: not used by Allegro */
	af->DrawTri = NULL;
	af->DrawQuad = NULL;

	/* monochrome character expansion: may be NULL */
	af->PutMonoImage = NULL;

	/* not supported: not used by Allegro */
	af->PutMonoImageLin = NULL;
	af->PutMonoImageBM = NULL;

	/* opaque blitting: may be NULL */
	af->BitBlt = NULL;
	af->BitBltSys = NULL;

	/* not supported: not used by Allegro */
	af->BitBltLin = NULL;
	af->BitBltBM = NULL;

	/* masked blitting: may be NULL */
	af->SrcTransBlt = NULL;
	af->SrcTransBltSys = NULL;

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


/* findmode:
 *  Finds the given mode's entry in the mode list.
 */
struct mode_t *findmode (int mode)
{
	struct mode_t *ret;
	for (ret = mode_list; ret->mode; ret++)
		if (ret->mode == mode) return ret;
	return NULL;
}


/* get_field_data:
 *  Fills in the mask size and position of each part of a pixel
 *  for the given colour depth.
 */
void get_field_data (int bpp, char *rm, char *rp, char *gm, char *gp, char *bm, char *bp, char *xm, char *xp)
{
	int pos = 0;

	#define FIELD(xxx,size) *xxx##p = pos; pos += (*xxx##m = size)

	switch (bpp) {
		case 15:
			FIELD (b, 5);
			FIELD (g, 5);
			FIELD (r, 5);
			FIELD (x, 1);
			break;
		case 16:
			FIELD (b, 5);
			FIELD (g, 6);
			FIELD (r, 5);
			FIELD (x, 0);
			break;
		case 24:
			FIELD (b, 8);
			FIELD (g, 8);
			FIELD (r, 8);
			FIELD (x, 0);
			break;
		case 32:
			FIELD (b, 8);
			FIELD (g, 8);
			FIELD (r, 8);
			FIELD (x, 8);
			break;
		default:
			FIELD (b, 0);
			FIELD (g, 0);
			FIELD (r, 0);
			FIELD (x, 0);
	}

	#undef FIELD
}


/* GetVideoModeInfo:
 *  Retrieves information about this video mode, returning zero on success
 *  or -1 if the mode is invalid.
 */
long GetVideoModeInfo(AF_DRIVER *af, short mode, AF_MODE_INFO *modeInfo)
{
	int i;
	int bytes_per_scanline;
	struct mode_t *info = findmode (mode);

	if (!info) return -1;

	/* clear the structure to zero */
	for (i = 0; i < (int)sizeof(AF_MODE_INFO); i++)
		((char *)modeInfo)[i] = 0;

	/* copy data across from our stored list of mode attributes */
	modeInfo->Attributes = alg_caps[alg_version];

	modeInfo->XResolution = info->w;
	modeInfo->YResolution = info->h;
	modeInfo->BitsPerPixel = info->bpp;

	bytes_per_scanline = info->w * BYTES_PER_PIXEL(info->bpp);

	/* available pages of video memory */
	modeInfo->MaxBuffers = (alg_vidmem * 1024 - RESERVED_VRAM) / 
			  (bytes_per_scanline * info->h);

	/* maximum virtual scanline length in both bytes and pixels. How wide
	 * this can go will very much depend on the card: 1024 is pretty safe
	 * on anything, but you will want to allow larger limits if the card
	 * is capable of them.
	 */
	modeInfo->MaxScanLineWidth = 1024;
	modeInfo->MaxBytesPerScanLine = modeInfo->MaxScanLineWidth*BYTES_PER_PIXEL(info->bpp);

	/* for banked video modes, fill in these variables: */
	modeInfo->BytesPerScanLine = bytes_per_scanline;
	modeInfo->BnkMaxBuffers = modeInfo->MaxBuffers;

	get_field_data (
		info->bpp,
		&modeInfo->RedMaskSize, &modeInfo->RedFieldPosition,
		&modeInfo->GreenMaskSize, &modeInfo->GreenFieldPosition,
		&modeInfo->BlueMaskSize, &modeInfo->BlueFieldPosition,
		&modeInfo->RsvdMaskSize, &modeInfo->RsvdFieldPosition
	);

	/* for linear video modes, fill in these variables: */
	modeInfo->LinBytesPerScanLine = bytes_per_scanline;
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


/* setvstart:
 *  Sets the display start address.
 */
void setvstart (int x, int y)
{
	int addr = af_width * y + x * BYTES_PER_PIXEL (af_bpp);
	int display, pixels;

	if (read_vga_register (port_grc, 0x0c) & 0x10) {
		display = addr >> 3;
		pixels = addr & 7;
	} else {
		display = addr >> 2;
		pixels = addr & 3;
	}

	write_vga_register (port_crtc, 0x20, (display >> 16) & 0x07);
	write_vga_register (port_crtc, 0x0c, (display >> 8) & 0xff);
	write_vga_register (port_crtc, 0x0d, display & 0xff);
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
	long available_vram;
	long used_vram;
	struct mode_t *info;
	RM_REGS r;
	int interlaced, word_mode, double_word_mode, _8maps, shift;

	/* reject anything with hardware stereo */
	if (mode & 0x400)
		return -1;

	/* mask off the other flag bits */
	mode &= 0x3FF;

	info = findmode (mode);
	if (!info) return -1;

	/* reject the linear flag if the mode doesn't support it */
	if (linear) return -1;

	/* set the mode */
	r.x.ax = info->mode;
	rm_int (0x10, &r);
	if (r.h.ah) return -1;

	setinx (port_crtc, 0x1A, 0x10);  /* enable extensions */
	setinx (port_crtc, 0x19, 0x02);  /* enable >256k */
	setinx (port_grc,  0x0F, 0x04);  /* enable separate R/W banks */

	af_bpp = info->bpp;

	/* get some information about the mode */
	interlaced = read_vga_register (port_crtc, 0x19) & 1;
	double_word_mode = !!(read_vga_register (port_crtc, 0x14) & 0x40);
	word_mode = !(read_vga_register (port_crtc, 0x17) & 0x40);
	_8maps = !!(read_vga_register (0x3ce, 0x0c) & 0x10);

	/* calculate the shift factor for the scanline byte width */
	shift = 0;
	if (_8maps) shift++;
	if (double_word_mode)
		shift += 3;
	else if (word_mode)
		shift += 2;
	else
		shift++;
	if (interlaced) shift--;

	/* sort out the virtaul screen size */
	af_width = MAX (info->w, virtualX) * BYTES_PER_PIXEL (af_bpp);
	af_width = (((af_width - 1) >> shift) + 1) << shift;

	/* test: force it to be power of two */
	{
		int i = 1;
		while (i < af_width) i <<= 1;
		af_width = i;
	}

	/* Set scanline width */
	write_vga_register (port_crtc, 0x13, af_width >> shift);
	/* could also write bit 8 to port_crtc:0x28 bit 8 */

	af_height = MAX (info->h, virtualY);

	af_linear = linear;
	af_lines_per_bank = af->BankSize * 1024 / af_width;
	af_visible_page = 0;
	af_active_page = 0;

	af_scroll_x = 0;
	af_scroll_y = 0;
	setvstart (af_scroll_x, af_scroll_y);

	af_bank = 0;

	/* return framebuffer dimensions to the application */
	af->BufferEndX = af_width/BYTES_PER_PIXEL(af_bpp)-1;
	af->BufferEndY = af_height-1;
	af->OriginOffset = 0;

	used_vram = af_width * af_height * numBuffers;
	available_vram = af->TotalMemory * 1024 - RESERVED_VRAM;

	if (used_vram > available_vram) return -1;

	if (available_vram-used_vram >= af_width) {
		af->OffscreenOffset = used_vram;
		af->OffscreenStartY = af_height*numBuffers;
		af->OffscreenEndY = available_vram/af_width-1;
	} else {
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
	af_scroll_x = x;
	af_scroll_y = y;
	if (waitVRT >= 0) setvstart (x, y);
	if (waitVRT == 1) {
		while (inportb (0x3da) & 8);
		while (!(inportb (0x3da) & 8));
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
 */
asm ("
	#
	.globl _SetBank32, _SetBank32End

		.align 4
	_SetBank32:

		pushal

		andl $0x1F, %edx                    # Bank numbers are 5-bit
		movl %edx, %eax

		movl $0x3d6, %edx                   # 0x3d6 = read bank select port
		outb %al, %dx

		movl $0x3d7, %edx                   # 0x3d7 = r/w bank select port
		outb %al, %dx

		popal
		ret

	_SetBank32End:
	#
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
	#ifndef USE_ALTERNATIVE_IDLE_CHECK
		while (inportb (0x82aa) & 0x0f);
	#else
		while (inportb (0x82ba) & 0x80);
	#endif
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

