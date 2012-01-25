/*
 *       ______             ____  ______     _____  ______ 
 *      |  ____|           |  _ \|  ____|   / / _ \|  ____|
 *      | |__ _ __ ___  ___| |_) | |__     / / |_| | |__ 
 *      |  __| '__/ _ \/ _ \  _ <|  __|   / /|  _  |  __|
 *      | |  | | |  __/  __/ |_) | |____ / / | | | | |
 *      |_|  |_|  \___|\___|____/|______/_/  |_| |_|_|
 *
 *
 *      Paradise driver (based on the Allegro Paradise code).
 *
 *      By Francois Charton and Shawn Hargreaves.
 *
 *      See freebe.txt for copyright information.
 */


// #define NO_HWPTR


#include <pc.h>

#include "vbeaf.h"



/* chipset information */
#define PVGA1  1
#define WD90C  2

int paradise_type = 0;



/* driver function prototypes */
void CirrusSetBank32();
void CirrusSetBank32End();
void CirrusSetBank(AF_DRIVER *af, long bank);
void ParadiseSetBank32();
void ParadiseSetBank32End();
void ParadiseSetBank(AF_DRIVER *af, long bank);
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
} VIDEO_MODE;


VIDEO_MODE mode_list[] =
{
   {  640,  400,  8,  0x5E  },
   {  640,  480,  8,  0x5F  },
   {  800,  600,  8,  0x5C  }
};


#define NUM_MODES    (int)(sizeof(mode_list)/sizeof(VIDEO_MODE))


short available_modes[NUM_MODES+1] = { 1, 2, 3, -1 };



/* detect:
 *  Detects the presence of a Paradise card.
 */
char *detect(unsigned long *vidmem)
{
   char *name = NULL;
   RM_REGS r;
   int old, old2;

   old = read_vga_register(0x3CE, 0xF);
   write_vga_register(0x3CE, 0xF, old | 0x17);  /* lock extended registers */

   if (test_vga_register(0x3CE, 0x9, 0x7F)) {   /* not a Paradise card! */
      write_vga_register(0x3CE, 0xF, old);
      return NULL;
   }

   alter_vga_register(0x3CE, 0xF, 0x17, 5);     /* unlock extended regs */

   if (!test_vga_register(0x3CE, 0x9, 0x7F)) {  /* not a Paradise card! */
      write_vga_register(0x3CE, 0xF, old);
      return NULL;
   }

   old2 = read_vga_register(0x3D4, 0x29);
   alter_vga_register(0x3D4, 0x29, 0x8F, 0x85); 

   if (!test_vga_register(0x3D4, 0x2B, 0xFF)) {
      paradise_type = PVGA1;
      name = "PVGA1";
      goto end;
   }

   write_vga_register(0x3C4, 0x06, 0x48);

   if (!test_vga_register(0x3C4, 0x7, 0xF0)) {
      paradise_type = PVGA1;
      name = "WD90C0x";
      goto end;
   }

   if (!test_vga_register(0x3C4, 0x10, 0xFF)) {
      paradise_type = PVGA1;
      name = "WD90C2x";
      write_vga_register(0x3D4, 0x34, 0xA6);
      if (read_vga_register(0x3D4, 0x32) & 0x20) 
	 write_vga_register(0x3D4, 0x34, 0); 
      goto end;
   }

   paradise_type = WD90C;
   name = "WD90C1x or 24+";

   end:

   write_vga_register(0x3D4, 0x29, old2);
   write_vga_register(0x3CE, 0xF, old);

   r.x.ax = 0x007F; 
   r.h.bh = 0x02;
   rm_int(0x10, &r);
   *vidmem = r.h.ch * 64;

   return name;
}



/* SetupDriver:
 *  Fills in our driver header block.
 */
int SetupDriver(AF_DRIVER *af)
{
   char *name;
   int i;

   name = detect(&af->TotalMemory);

   if (!name)
      return 1;

   i = 0;
   while (af->OemVendorName[i])
      i++;

   af->OemVendorName[i++] = ',';
   af->OemVendorName[i++] = ' ';

   while (*name)
      af->OemVendorName[i++] = *(name++);

   af->OemVendorName[i] = 0;

   af->AvailableModes = available_modes;

   af->Attributes = (afHaveMultiBuffer | 
		     afHaveVirtualScroll | 
		     afHaveBankedBuffer);

   af->BankSize = 64;
   af->BankedBasePtr = 0xA0000;

   af->IOPortsTable = ports_table;

   if (paradise_type == PVGA1) { 
      af->SetBank32 = CirrusSetBank32;
      af->SetBank32Len = (long)CirrusSetBank32End - (long)CirrusSetBank32;
      af->SetBank = CirrusSetBank;
   }
   else {
      af->SetBank32 = ParadiseSetBank32;
      af->SetBank32Len = (long)ParadiseSetBank32End - (long)ParadiseSetBank32;
      af->SetBank = ParadiseSetBank;
   }

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

   if ((mode <= 0) || (mode > NUM_MODES))
      return -1;

   info = &mode_list[mode-1];

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

   if ((mode <= 0) || (mode > NUM_MODES))
      return -1;

   info = &mode_list[mode-1];

   /* call BIOS to set the mode */
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

   /* set up some hardware registers */
   if (paradise_type != PVGA1) { 
      write_vga_register(0x3C4, 0x06, 0x48);

      alter_vga_register(0x3C4, 0x11, 0x80, 0x80);
      alter_vga_register(0x3CE, 0x0B, 0x80, 0x80);

      write_vga_register(0x3C4, 0x06, 0x00); 
   }

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

      /* write high bits to Paradise register 3CE indx 0xD, bits 3-4 */
      alter_vga_register(0x3CE, 0x0D, 0x18, a>>15);

      /* write to normal VGA address registers */
      write_vga_register(0x3D4, 0x0D, (a>>2) & 0xFF);
      write_vga_register(0x3D4, 0x0C, (a>>10) & 0xFF);

      asm volatile ("sti");

      if (waitVRT) {
	 do {
	 } while (!(inportb(0x3DA) & 8));
      }
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



/* CirrusSetBank32:
 *  Relocatable bank switch function, called with a bank number in %edx.
 */

asm ("

   .globl _CirrusSetBank32, _CirrusSetBank32End

      .align 4
   _CirrusSetBank32:
      pushl %edx
      pushl %eax
      pushl %edx

      movl $0x3CE, %edx          /* 3CE index 0x9 */
      movb $0x9, %al
      outb %al, %dx

      popl %eax                  /* write bank number */
      shll $4, %eax
      incl %edx
      outb %al, %dx

      popl %eax
      popl %edx
      ret

   _CirrusSetBank32End:

");



/* CirrusSetBank:
 *  C-callable bank switch function. This version simply chains to the
 *  relocatable CirrusSetBank32() above.
 */
void CirrusSetBank(AF_DRIVER *af, long bank)
{
   asm (
      " call _CirrusSetBank32 "
   :
   : "d" (bank)
   );

   af_bank = bank;
}



/* ParadiseSetBank32:
 *  Relocatable bank switch function, called with a bank number in %edx.
 */

asm ("

   .globl _ParadiseSetBank32, _ParadiseSetBank32End

      .align 4
   _ParadiseSetBank32:
      pushl %eax
      pushl %ecx
      pushl %edx

      movl %edx, %ecx
      shll $4, %ecx

      movl $0x3CE, %edx          /* 3CE index 0x9 */
      movb $0x9, %al
      outb %al, %dx

      movl %ecx, %eax            /* set read bank number */
      incl %edx
      outb %al, %dx

      decl %edx                  /* 3CE index 0xA */
      movb $0xA, %al
      outb %al, %dx

      movl %ecx, %eax            /* set write bank number */
      incl %edx
      outb %al, %dx

      popl %edx
      popl %ecx
      popl %eax
      ret

   _ParadiseSetBank32End:

");



/* ParadiseSetBank:
 *  C-callable bank switch function. This version simply chains to the
 *  relocatable ParadiseSetBank32() above.
 */
void ParadiseSetBank(AF_DRIVER *af, long bank)
{
   asm (
      " call _ParadiseSetBank32 "
   :
   : "d" (bank)
   );

   af_bank = bank;
}



