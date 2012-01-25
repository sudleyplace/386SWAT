/*
 *       ______             ____  ______     _____  ______ 
 *      |  ____|           |  _ \|  ____|   / / _ \|  ____|
 *      | |__ _ __ ___  ___| |_) | |__     / / |_| | |__ 
 *      |  __| '__/ _ \/ _ \  _ <|  __|   / /|  _  |  __|
 *      | |  | | |  __/  __/ |_) | |____ / / | | | | |
 *      |_|  |_|  \___|\___|____/|______/_/  |_| |_|_|
 *
 *
 *      Tseng driver (based on the Allegro Tseng code).
 *
 *      By Shawn Hargreaves, Marco Campinoti, and Ben Chauveau.
 *
 *      See freebe.txt for copyright information.
 */


// #define NO_HWPTR


#include <pc.h>

#include "vbeaf.h"



/* chipset information */
#define ET_NONE         0
#define ET_3000         1
#define ET_4000         2
#define ET_6000         3

int tseng_type = ET_NONE;



/* driver function prototypes */
void ET3000SetBank32();
void ET3000SetBank32End();
void ET3000SetBank(AF_DRIVER *af, long bank);
void ET4000SetBank32();
void ET4000SetBank32End();
void ET4000SetBank(AF_DRIVER *af, long bank);
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



/* list which ports we are going to access (only needed under Linux) */
unsigned short ports_table[] = { 0xFFFF };



/* internal driver state variables */
int af_bpp;
int af_width;
int af_height;
int af_visible_page;
int af_active_page;
int af_scroll_x;
int af_scroll_y;
int af_bank;



/* FreeBE/AF extension allowing farptr access to video memory */
FAF_HWPTR_DATA hwptr;



/* list of available video modes */
typedef struct VIDEO_MODE
{
   int w, h;
   int bpp;
   int num;
   int bios;
} VIDEO_MODE;


VIDEO_MODE et3000_mode_list[] =
{
   {  640,  350,  8,  0x2D,  0  },
   {  640,  480,  8,  0x2E,  0  },
   {  800,  600,  8,  0x30,  0  }
};


VIDEO_MODE et4000_mode_list[] =
{
   {  640,  350,  8,   0x2D,    0       },
   {  640,  480,  8,   0x2E,    0       },
   {  640,  400,  8,   0x2F,    0       },
   {  800,  600,  8,   0x30,    0       },
   {  1024, 768,  8,   0x38,    0       },
   {  320,  200,  15,  0x13,    0x10F0  },
   {  640,  350,  15,  0x2D,    0x10F0  },
   {  640,  480,  15,  0x2E,    0x10F0  },
   {  640,  400,  15,  0x2F,    0x10F0  },
   {  800,  600,  15,  0x30,    0x10F0  },
   {  1024, 768,  15,  0x38,    0x10F0  },
   {  640,  350,  24,  0x2DFF,  0x10F0  },
   {  640,  480,  24,  0x2EFF,  0x10F0  },
   {  640,  400,  24,  0x2FFF,  0x10F0  },
   {  800,  600,  24,  0x30FF,  0x10F0  }
};


#define NUM_ET3000_MODES   (int)(sizeof(et3000_mode_list)/sizeof(VIDEO_MODE))
#define NUM_ET4000_MODES   (int)(sizeof(et4000_mode_list)/sizeof(VIDEO_MODE))


short available_et3000_modes[NUM_ET3000_MODES+1] = { 1, 2, 3, -1 };
short available_et4000_modes[NUM_ET4000_MODES+1] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, -1 };



/* detect:
 *  Detects the presence of a Tseng card.
 */
int detect()
{
   int old1, old2, subver;

   old1 = inportb(0x3BF);
   old2 = inportb(0x3D4+4);

   outportb(0x3BF, 3);
   outportb(0x3D4+4, 0xA0);

   if (test_register(0x3CD, 0x3F)) {
      if (test_vga_register(0x3D4, 0x33, 0x0F)) {
	 if (test_register(0x3CB, 0x33)) {
	    subver = read_vga_register(0x217A, 0xEC) >> 4;
	    if (subver <= 11)
	       return ET_4000;
	    else if (subver == 15)
	       return ET_6000;
	    /* else unknown Tseng */
	 }
	 else
	    return ET_4000;
      }
      else
	 return ET_3000;
   }

   outportb(0x3BF, old1);
   outportb(0x3D4+4, old2);

   return ET_NONE;
}



/* SetupDriver:
 *  Fills in our driver header block.
 */
int SetupDriver(AF_DRIVER *af)
{
   char *name = NULL;
   int vram_size;
   int i;

   tseng_type = detect();

   switch (tseng_type) {

      case ET_3000:
	 name = "ET3000";
	 break;

      case ET_4000:
	 name = "ET4000";
	 break;

      case ET_6000:
	 name = "ET6000";
	 break;

      default: 
	 return 1;
   }

   i = 0;
   while (af->OemVendorName[i])
      i++;

   af->OemVendorName[i++] = ',';
   af->OemVendorName[i++] = ' ';

   while (*name)
      af->OemVendorName[i++] = *(name++);

   af->OemVendorName[i] = 0;

   if (get_vesa_info(&vram_size, NULL, NULL) != 0) {
      if (tseng_type == ET_3000)
	 af->TotalMemory = 512;
      else
	 af->TotalMemory = 1024;
   }
   else {
      if (tseng_type == ET_3000)
	 af->TotalMemory = MIN(vram_size/1024, 512);
      else
	 af->TotalMemory = MIN(vram_size/1024, 1024);
   }

   if (tseng_type == ET_3000) {
      af->AvailableModes = available_et3000_modes;

      af->SetBank32 = ET3000SetBank32;
      af->SetBank32Len = (long)ET3000SetBank32End - (long)ET3000SetBank32;
      af->SetBank = ET3000SetBank;
   }
   else {
      af->AvailableModes = available_et4000_modes;

      af->SetBank32 = ET4000SetBank32;
      af->SetBank32Len = (long)ET4000SetBank32End - (long)ET4000SetBank32;
      af->SetBank = ET4000SetBank;
   }

   af->Attributes = (afHaveMultiBuffer | 
		     afHaveVirtualScroll | 
		     afHaveBankedBuffer);

   af->BankSize = 64;
   af->BankedBasePtr = 0xA0000;

   af->IOPortsTable = ports_table;

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

   return 0;
}



/* InitDriver:
 *  The second thing to be called during the init process, after the 
 *  application has mapped all the memory and I/O resources we need.
 */
int InitDriver(AF_DRIVER *af)
{
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

   if ((mode <= 0) || (mode > ((tseng_type == ET_3000) ? NUM_ET3000_MODES : NUM_ET4000_MODES)))
      return -1;

   if (tseng_type == ET_3000)
      info = &et3000_mode_list[mode-1];
   else
      info = &et4000_mode_list[mode-1];

   for (i=0; i<(int)sizeof(AF_MODE_INFO); i++)
      ((char *)modeInfo)[i] = 0;

   modeInfo->Attributes = (afHaveMultiBuffer | 
			   afHaveVirtualScroll | 
			   afHaveBankedBuffer);

   modeInfo->XResolution = info->w;
   modeInfo->YResolution = info->h;
   modeInfo->BitsPerPixel = info->bpp;

   modeInfo->MaxBuffers = (af->TotalMemory*1024) / 
			  (info->w*info->h*BYTES_PER_PIXEL(info->bpp));

   if (info->w > 1024) {
      modeInfo->MaxBytesPerScanLine = 2048*BYTES_PER_PIXEL(info->bpp);
      modeInfo->MaxScanLineWidth = 2048;
   }
   else {
      modeInfo->MaxBytesPerScanLine = 1024*BYTES_PER_PIXEL(info->bpp);
      modeInfo->MaxScanLineWidth = 1024;
   }

   modeInfo->BytesPerScanLine = info->w*BYTES_PER_PIXEL(info->bpp);
   modeInfo->BnkMaxBuffers = modeInfo->MaxBuffers;

   modeInfo->MaxPixelClock = 135000000;

   return 0;
}



/* SetVideoMode:
 *  Sets the specified video mode, returning zero on success.
 */
long SetVideoMode(AF_DRIVER *af, short mode, long virtualX, long virtualY, long *bytesPerLine, int numBuffers, AF_CRTCInfo *crtc)
{
   long available_vram;
   long used_vram;
   int width;
   VIDEO_MODE *info;
   RM_REGS r;

   /* reject anything with hardware stereo, linear framebuffer, or noclear */
   if (mode & 0xC400)
      return -1;

   mode &= 0x3FF;

   if ((mode <= 0) || (mode > ((tseng_type == ET_3000) ? NUM_ET3000_MODES : NUM_ET4000_MODES)))
      return -1;

   if (tseng_type == ET_3000)
      info = &et3000_mode_list[mode-1];
   else
      info = &et4000_mode_list[mode-1];

   /* call BIOS to set the mode */
   if (info->bios) { 
      r.x.ax = info->bios;
      r.x.bx = info->num;
   }
   else
      r.x.ax = info->num;

   rm_int(0x10, &r);

   /* adjust the virtual width for widescreen modes */
   if (virtualX > info->w) {
      if (virtualX > 1024)
	 return -1;

      *bytesPerLine = ((virtualX*BYTES_PER_PIXEL(info->bpp))+15)&0xFFF0;

      width = read_vga_register(0x3D4, 0x13);
      write_vga_register(0x3D4, 0x13, (width * (*bytesPerLine)) / (info->w*BYTES_PER_PIXEL(info->bpp)));
   }
   else
      *bytesPerLine = info->w*BYTES_PER_PIXEL(info->bpp);

   /* store info about the current mode */
   af_bpp = info->bpp;
   af_width = *bytesPerLine;
   af_height = MAX(info->h, virtualY);
   af_visible_page = 0;
   af_active_page = 0;
   af_scroll_x = 0;
   af_scroll_y = 0;
   af_bank = -1;

   af->BufferEndX = af_width/BYTES_PER_PIXEL(af_bpp)-1;
   af->BufferEndY = af_height-1;
   af->OriginOffset = 0;

   used_vram = af_width * af_height * numBuffers;
   available_vram = af->TotalMemory*1024 ;

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
   if (waitVRT >= 0) {
      long a = (x * BYTES_PER_PIXEL(af_bpp)) + ((y + af_visible_page*af_height) * af_width);

      asm volatile ("cli");

      if (waitVRT) {
	 do {
	 } while (inportb(0x3DA) & 1);
      }

      /* write high bit(s) to Tseng-specific registers */
      if (tseng_type == ET_3000)
	 alter_vga_register(0x3D4, 0x23, 2, a>>17);
      else if (tseng_type == ET_4000)
	 alter_vga_register(0x3D4, 0x33, 3, a>>18);
      else if (tseng_type == ET_6000)
	 alter_vga_register(0x3D4, 0x33, 3, a>>17);

      /* write to normal VGA address registers */
      write_vga_register(0x3D4, 0x0D, (a>>2) & 0xFF);
      write_vga_register(0x3D4, 0x0C, (a>>10) & 0xFF);

      asm volatile ("sti");

      if (waitVRT) {
	 do {
	 } while (!(inportb(0x3DA) & 8));
      }

      /* write low 2 bits to VGA horizontal pan register */
      if (af_bpp == 8)
	 write_vga_register(0x3C0, 0x33, a&3);
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



/* ET3000SetBank32:
 *  Relocatable bank switch function, called with a bank number in %edx.
 */

asm ("

   .globl _ET3000SetBank32, _ET3000SetBank32End

      .align 4
   _ET3000SetBank32:
      pushl %edx
      pushl %eax

      movb %dl, %al              /* mask read and write banks together */
      shlb $3, %al
      orb %dl, %al 
      orb $0x40, %al             /* select 64k segments */

      movl $0x3CD, %edx
      outb %al, %dx              /* write to the card */

      popl %eax
      popl %edx
      ret

   _ET3000SetBank32End:

");



/* ET3000SetBank:
 *  C-callable bank switch function. This version simply chains to the
 *  relocatable ET3000SetBank32() above.
 */
void ET3000SetBank(AF_DRIVER *af, long bank)
{
   asm (
      " call _ET3000SetBank32 "
   :
   : "d" (bank)
   );

   af_bank = bank;
}



/* ET4000SetBank32:
 *  Relocatable bank switch function, called with a bank number in %edx.
 */

asm ("

   .globl _ET4000SetBank32, _ET4000SetBank32End

      .align 4
   _ET4000SetBank32:
      pushl %edx
      pushl %eax

      movb %dl, %al              /* mask read and write banks together */
      shlb $4, %al
      orb %dl, %al 

      movl $0x3CD, %edx
      outb %al, %dx              /* write to the card */

      popl %eax
      popl %edx
      ret

   _ET4000SetBank32End:

");



/* ET4000SetBank:
 *  C-callable bank switch function. This version simply chains to the
 *  relocatable ET4000SetBank32() above.
 */
void ET4000SetBank(AF_DRIVER *af, long bank)
{
   asm (
      " call _ET4000SetBank32 "
   :
   : "d" (bank)
   );

   af_bank = bank;
}



