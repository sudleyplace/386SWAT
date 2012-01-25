/*
 *       ______             ____  ______     _____  ______ 
 *      |  ____|           |  _ \|  ____|   / / _ \|  ____|
 *      | |__ _ __ ___  ___| |_) | |__     / / |_| | |__ 
 *      |  __| '__/ _ \/ _ \  _ <|  __|   / /|  _  |  __|
 *      | |  | | |  __/  __/ |_) | |____ / / | | | | |
 *      |_|  |_|  \___|\___|____/|______/_/  |_| |_|_|
 *
 *
 *      Trident driver (based on the Allegro Trident code).
 *
 *      By Shawn Hargreaves and Mark Habersack.
 *
 *      See freebe.txt for copyright information.
 */


// #define NO_HWPTR


#include <pc.h>

#include "vbeaf.h"



/* chipset information */
int chip_id = 0;


char *descriptions[] =
{
   "TVGA 8900CL/D", "TVGA 9000i", "TVGA 9200CXr",
   "TVGA LCD9100B", "TVGA GUI9420", "TVGA LX8200", "TVGA 9400CXi",
   "TVGA LCD9320", "Unknown", "TVGA GUI9420", "TVGA GUI9660",
   "TVGA GUI9440", "TVGA GUI9430", "TVGA 9000C"
};


#define TV_LAST   13



/* driver function prototypes */
void DualSetBank32();
void DualSetBank32End();
void DualSetBank(AF_DRIVER *af, long bank);
void SingleSetBank32();
void SingleSetBank32End();
void SingleSetBank(AF_DRIVER *af, long bank);
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
   {  640,  400,  8,  0x5C  },
   {  640,  480,  8,  0x5D  },
   {  800,  600,  8,  0x5E  },
   {  1024, 768,  8,  0x62  }
};


#define NUM_MODES    (int)(sizeof(mode_list)/sizeof(VIDEO_MODE))


short available_modes[NUM_MODES+1] = { 1, 2, 3, 4, -1 };



/* detect:
 *  Detects the presence of a Trident card.
 */
char *detect(unsigned long *vidmem)
{
   int old1, old2, val;
   char *name = NULL;

   old1 = read_vga_register(0x3C4, 0x0B);
   write_vga_register(0x3C4, 0x0B, 0);       /* force old mode registers */
   chip_id = inportb(0x3C5);                 /* now we have the ID */

   old2 = read_vga_register(0x3C4, 0x0E);
   outportb(0x3C4+1, old2^0x55);
   val = inportb(0x3C5);
   outportb(0x3C5, old2);

   if (((val^old2) & 0x0F) == 7) {           /* if bit 2 is inverted... */
      outportb(0x3C5, old2^2);               /* we're dealing with Trident */

      if (chip_id <= 2)                      /* don't like 8800 chips */
	 return FALSE;

      val = read_vga_register(0x3D4, 0x1F);  /* determine the memory size */
      switch (val & 3) {
	 case 0: *vidmem = 256; break;
	 case 1: *vidmem = 512; break;
	 case 2: *vidmem = 768; break;
	 case 3: if ((chip_id >= 0x33) && (val & 4))
		    *vidmem = 2048;
		 else
		    *vidmem = 1024;
		 break;
      }

      /* provide user with a description of the chip s/he has */
      if ((chip_id == 0x33) && (read_vga_register(0x3D4, 0x28) & 0x80))
	 /* is it TVGA 9000C */
	 name = descriptions[TV_LAST]; 
      else if (chip_id >= 0x33)
	 name = descriptions[((chip_id & 0xF0) >> 4) - 3];
      else {
	 switch (chip_id) {
	    case 3:     name = "TR 8900B";      break;
	    case 4:     name = "TVGA 8900C";    break;
	    case 0x13:  name = "TVGA 8900C";    break;
	    case 0x23:  name = "TR 9000";       break;
	    default:    name = "Unknown";       break;
	 }
      } 

      return name;
   }

   write_vga_register(0x3C4, 0x0B, old1);
   return NULL;
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

   if (chip_id >= 0x33) {
      af->SetBank = DualSetBank;
      af->SetBank32 = DualSetBank32;
      af->SetBank32Len = (long)DualSetBank32End - (long)DualSetBank32;
   }
   else {
      af->SetBank = SingleSetBank;
      af->SetBank32 = SingleSetBank32;
      af->SetBank32Len = (long)SingleSetBank32End - (long)SingleSetBank32;
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
   if (chip_id >= 0x33)
      write_vga_register(0x3CE, 0x0F, 5);          /* read/write banks */
   else
      read_vga_register(0x3C4, 0x0B);              /* switch to new mode */

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
      long a = ((x * BYTES_PER_PIXEL(af_bpp)) + ((y + af_visible_page*af_height) * af_width)) >> 2;

      asm volatile ("cli");

      if (waitVRT) {
	 do {
	 } while (inportb(0x3DA) & 1);
      }

      /* first set the standard CRT Start registers */
      outportw(0x3D4, (a & 0xFF00) | 0x0C);
      outportw(0x3D4, ((a & 0x00FF) << 8) | 0x0D);

      /* set bit 16 of the screen start address */
      outportb(0x3D4, 0x1E);
      outportb(0x3D5, (inportb(0x3D5) & 0xDF) | ((a & 0x10000) >> 11) );

      /* bits 17-19 of the start address: uses the 8900CL/D+ register */
      outportb(0x3D4, 0x27);
      outportb(0x3D5, (inportb(0x3D5) & 0xF8) | ((a & 0xE0000) >> 17) );

      /* set pel register */
      if (waitVRT) {
	 do {
	 } while (!(inportb(0x3DA) & 8));
      }

      write_vga_register(0x3C0, 0x33, x&3);

      asm volatile ("sti");
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



/* DualSetBank32:
 *  Relocatable bank switch function, called with a bank number in %edx.
 */

asm ("

   .globl _DualSetBank32, _DualSetBank32End

      .align 4
   _DualSetBank32:
      pushl %edx
      pushl %eax
      movl %edx, %eax

      movl $0x3D8, %edx
      outb %al, %dx

      incl %edx
      outb %al, %dx

      popl %eax
      popl %edx
      ret

   _DualSetBank32End:

");



/* DualSetBank:
 *  C-callable bank switch function. This version simply chains to the
 *  relocatable DualSetBank32() above.
 */
void DualSetBank(AF_DRIVER *af, long bank)
{
   asm (
      " call _DualSetBank32 "
   :
   : "d" (bank)
   );

   af_bank = bank;
}



/* SingleSetBank32:
 *  Relocatable bank switch function, called with a bank number in %edx.
 */

asm ("

   .globl _SingleSetBank32, _SingleSetBank32End

      .align 4
   _SingleSetBank32:
      pushl %edx
      pushl %eax
      movb %dl, %ah              /* save bank into ah */

      movl $0x3C4, %edx          /* read port 3C4 register 0xE */
      movb $0xE, %al
      outb %al, %dx 
      incl %edx
      inb %dx, %al
      decl %edx

      andb $0xF0, %al            /* mask low four bits */
      xorb $2, %ah               /* xor bank number with 2 */
      orb %al, %ah

      movb $0xE, %al             /* write to port 3C4 register 0xE */
      outb %al, %dx
      incl %edx
      movb %ah, %al
      outb %al, %dx

      popl %eax
      popl %edx
      ret

   _SingleSetBank32End:

");



/* SingleSetBank:
 *  C-callable bank switch function. This version simply chains to the
 *  relocatable SingleSetBank32() above.
 */
void SingleSetBank(AF_DRIVER *af, long bank)
{
   asm (
      " call _SingleSetBank32 "
   :
   : "d" (bank)
   );

   af_bank = bank;
}



