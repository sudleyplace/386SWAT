/*
 *       ______             ____  ______     _____  ______ 
 *      |  ____|           |  _ \|  ____|   / / _ \|  ____|
 *      | |__ _ __ ___  ___| |_) | |__     / / |_| | |__ 
 *      |  __| '__/ _ \/ _ \  _ <|  __|   / /|  _  |  __|
 *      | |  | | |  __/  __/ |_) | |____ / / | | | | |
 *      |_|  |_|  \___|\___|____/|______/_/  |_| |_|_|
 *
 *
 *      S3 driver (based on the Allegro S3 code).
 *
 *      By Shawn Hargreaves and Michael Bukin.
 *
 *      Hardware acceleration by Michal Stencl.
 *
 *      See freebe.txt for copyright information.
 */


// #define NO_HWPTR


#include <pc.h>

#include "../vbeaf.h"



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
void BitBlt(AF_DRIVER *af, long left, long top, long width, long height, long dstLeft, long dstTop, long op);
void BitBltSys(AF_DRIVER *af, void *srcAddr, long srcPitch, long srcLeft, long srcTop, long width, long height, long dstLeft, long dstTop, long op);
void WaitTillIdle(AF_DRIVER *af);



#define S86c911A  0x82


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
int af_chipid;


/* FreeBE/AF extension allowing farptr access to video memory */
FAF_HWPTR_DATA hwptr;



/* list of available video modes */
typedef struct VIDEO_MODE
{
   int w, h;
   int bpp;
   int num;
   int bpl;
   int redsize;
   int redpos;
   int greensize;
   int greenpos;
   int bluesize;
   int bluepos;
   int rsvdsize;
   int rsvdpos;
} VIDEO_MODE;


VIDEO_MODE mode_list[] =
{
   {  640,  400,  8,  0x100, 640  },
   {  640,  480,  8,  0x101, 640  },
   {  800,  600,  8,  0x103, 800  },
   {  1024, 768,  8,  0x105, 1024  },
   {  1280, 1024, 8,  0x107, 1280  },
   {  640,  480,  15, 0x110, 1280,5,10,5,5,5,0,0,0},
   {  800,  600,  15, 0x113, 1600,5,10,5,5,5,0,0,0},
   {  1024, 768,  15, 0x116, 2048,5,10,5,5,5,0,0,0},
   {  1280, 1024, 15, 0x119, 2560,5,10,5,5,5,0,0,0},
   {  640,  480,  16, 0x111, 1024,5,11,6,5,5,0,0,0},
   {  800,  600,  16, 0x114, 1600,5,11,6,5,5,0,0,0},
   {  1024, 768,  16, 0x117, 2048,5,11,6,5,5,0,0,0},
   {  1280, 1024, 16, 0x11A, 2560,5,11,6,5,5,0,0,0},
   {  640,  480,  32, 0x112, 2048,8,16,8,8,8,0,0,0},
   {  800,  600,  32, 0x115, 3200,8,16,8,8,8,0,0,0},
   {  1024, 768,  32, 0x118, 4096,8,16,8,8,8,0,0,0}
};


#define NUM_MODES    (int)(sizeof(mode_list)/sizeof(VIDEO_MODE))


short available_modes[NUM_MODES+1] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
				       13, 14, 15, 16, -1 };



void  mod_vga_register_bits ( int reg, int m, int mask, int nwv )
{
  int temp = (read_vga_register(reg,m) & (!mask))+(nwv & mask);
  write_vga_register(reg, m, temp);
};

void set_vga_register_bits ( int reg, int m, int b )
{
  int x = read_vga_register(reg,m);
  write_vga_register(reg, m, x | b);
};

void clear_vga_register_bits ( int reg, int m, int b )
{
  int x = read_vga_register(reg,m);
  write_vga_register(reg, m, x & (!b));
};

void  accelIT ( void )
{
    write_vga_register(0x3D4, 0x38, 0x48);
    write_vga_register(0x3D4, 0x39, 0xA5);
    clear_vga_register_bits(0x3D4, 0x58, 0x14);
    mod_vga_register_bits(0x3D4, 0x40, 9, 1);
    clear_vga_register_bits(0x3D4, 0x53, 0xF);
    write_vga_register(0x3D4, 0x54, 0xA0);
    outportw(0xBEE8, 0xE000);
    outportw(0xAAE8, 0xFFFF);
    outportw(0xAEE8, 0xFFFF);
    if ( af_bpp >= 24 ) {
      outportw(0xBEE8, 0xE010);
      outportw(0xAAE8, 0xFFFF);
      outportw(0xAEE8, 0xFFFF);
    };
};


void  unaccelIT ( void )
{
    write_vga_register(0x3D4, 0x38, 0x48); /* unlock cr38 */
    write_vga_register(0x3D4, 0x39, 0xA5); /* unlock cr39 */
    if ( read_vga_register(0x3D4, 0x40) )
      do ; while ( inportw(0x9AE8) & 0x200 ); /* if graph. procesor is busy (9bit)*/
    clear_vga_register_bits(0x3D4, 0x40, 1); /* not enhanced reg access */
    set_vga_register_bits(0x3D4, 0x40, 8); /* enable fast write buffer (3bit) */
};

int  readchipid ( void )
{
  return read_vga_register(0x3d4, 0x30);
};

/* detect:
 *  Detects the presence of a S3 card.
 */
int detect()
{
   int old;
   int result = FALSE;

   old = read_vga_register(0x3D4, 0x38);
   write_vga_register(0x3D4, 0x38, 0);                   /* disable ext. */
   if (!test_vga_register(0x3D4, 0x35, 0xF)) {           /* test */
      write_vga_register(0x3D4, 0x38, 0x48);             /* enable ext. */
      if (test_vga_register(0x3D4, 0x35, 0xF))           /* test again */
	     result = TRUE;                                  /* found it */
      af_chipid = readchipid();
   }

   write_vga_register(0x3D4, 0x38, old);

   return result;
}



/* SetupDriver:
 *  Fills in our driver header block.
 */
int SetupDriver(AF_DRIVER *af)
{
   int vram_size;

   if (!detect())
      return 1;

   if (get_vesa_info(&vram_size, NULL, NULL) != 0)
      return -1;

   af->AvailableModes = available_modes;

   af->TotalMemory = vram_size/1024;

   af->Attributes = (afHaveMultiBuffer | 
		     afHaveVirtualScroll | 
		     afHaveAccel2D |
		     afHaveBankedBuffer);

   af->BankSize = 64;
   af->BankedBasePtr = 0xA0000;

   af->IOPortsTable = ports_table;

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

//   af->WaitTillIdle = WaitTillIdle;
   af->Set8x8MonoPattern = NULL;
   af->DrawScan = NULL;
   af->DrawPattScan = NULL;
   af->DrawRect = NULL;
   af->DrawPattRect = NULL;
   af->DrawLine = NULL;
   af->DrawTrap = NULL;
   af->PutMonoImage = NULL;
   af->BitBlt = BitBlt;
   af->BitBltSys = NULL;

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

   modeInfo->RedMaskSize = info->redsize;
   modeInfo->RedFieldPosition = info->redpos;
   modeInfo->GreenMaskSize = info->greensize;
   modeInfo->GreenFieldPosition = info->greenpos;
   modeInfo->BlueMaskSize = info->bluesize;
   modeInfo->BlueFieldPosition = info->bluepos;
   modeInfo->RsvdMaskSize = info->rsvdsize;
   modeInfo->RsvdFieldPosition = info->rsvdpos;

   /* for linear video modes, fill in these variables: */
   modeInfo->LinBytesPerScanLine = modeInfo->BytesPerScanLine;
   modeInfo->LinMaxBuffers = modeInfo->MaxBuffers;
   modeInfo->LinRedMaskSize = info->redsize;
   modeInfo->LinRedFieldPosition = info->redpos;
   modeInfo->LinGreenMaskSize = info->greensize;
   modeInfo->LinGreenFieldPosition = info->greenpos;
   modeInfo->LinBlueMaskSize = info->bluesize;
   modeInfo->LinBlueFieldPosition = info->bluepos;
   modeInfo->LinRsvdMaskSize = info->rsvdsize;
   modeInfo->LinRsvdFieldPosition = info->rsvdpos;

   modeInfo->MaxPixelClock = 135000000;

   return 0;
}



/* SetVideoMode:
 *  Sets the specified video mode, returning zero on success.
 */
long SetVideoMode(AF_DRIVER *af, short mode, long virtualX, long virtualY, long *bytesPerLine, int numBuffers, AF_CRTCInfo *crtc)
{
   int noclear = ((mode & 0x8000) != 0);
   long available_vram;
   long used_vram;
   int pitch;
   VIDEO_MODE *info;
   RM_REGS r;

   /* reject anything with hardware stereo or linear framebuffer */
   if (mode & 0x4400)
      return -1;

   mode &= 0x3FF;

   if ((mode <= 0) || (mode > NUM_MODES))
      return -1;

   info = &mode_list[mode-1];

   /* call VESA to set the mode */
   r.x.ax = 0x4F02;
   r.x.bx = info->num;
   if (noclear)
      r.x.bx |= 0x8000;
   rm_int(0x10, &r);
   if (r.h.ah)
      return -1;


   if (virtualX*BYTES_PER_PIXEL(info->bpp) > info->bpl) {
      r.x.ax = 0x4F06;
      r.x.bx = 0;
      r.x.cx = virtualX;
      rm_int(0x10, &r);
      if (r.h.ah)
	 return -1;
      *bytesPerLine = r.x.bx;
   }
   else
      *bytesPerLine = info->bpl;

   pitch = ((*bytesPerLine)*8)/info->bpp;
/*   write_vga_register(0x3D4, 0x13, pitch);*/
   clear_vga_register_bits(0x3D4, 0x50, 193);
   clear_vga_register_bits(0x3d4, 0x50, 48);

   switch ( info->bpp ) {
     case 16 : set_vga_register_bits(0x3D4, 0x50, 16); break;
     case 24 : set_vga_register_bits(0x3D4, 0x50, 32); break;
     case 32 : set_vga_register_bits(0x3D4, 0x50, 48); break;
   };

   switch ( pitch ) {
     case 640  : set_vga_register_bits(0x3D4, 0x50, 64); break;
     case 800  : set_vga_register_bits(0x3D4, 0x50, 128); break;
     case 1152 : set_vga_register_bits(0x3D4, 0x50, 1); break;
     case 1280 : set_vga_register_bits(0x3D4, 0x50, 129); break;
     case 1600 : set_vga_register_bits(0x3D4, 0x50, 192); break;
   };

   /* adjust the virtual width for widescreen modes */

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

      /* write high bits to S3-specific registers */
      write_vga_register(0x3D4, 0x38, 0x48);
      alter_vga_register(0x3D4, 0x31, 0x30, a>>14);
      alter_vga_register(0x3D4, 0x51, 0x03, a>>20);
      write_vga_register(0x3D4, 0x38, 0);

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



/* SetBank32:
 *  Relocatable bank switch function, called with a bank number in %edx.
 */

asm ("

   .globl _SetBank32, _SetBank32End

      .align 4
   _SetBank32:
      pushl %ecx
      pushl %edx
      movl %edx, %ecx
      movl $0x3D4, %edx

      movb $0x38, %al            /* enable extensions */
      outb %al, %dx
      incl %edx
      movb $0x48, %al
      outb %al, %dx
      decl %edx

      movb $0x31, %al            /* read register 0x31 */
      outb %al, %dx 
      incl %edx
      inb %dx, %al
      decl %edx

      movb %al, %ah              /* set bank write and vid mem > 256K flags */
      movb $0x31, %al
      outb %al, %dx
      movb %ah, %al
      orb $9, %al 
      incl %edx
      outb %al, %dx
      decl %edx

      movb $0x35, %al            /* read register 0x35 */
      outb %al, %dx
      incl %edx
      inb %dx, %al
      decl %edx

      andb $0xF0, %al            /* mix bits 0-3 of bank number */
      movb %cl, %ch
      andb $0x0F, %ch
      orb %al, %ch

      movb $0x35, %al            /* write the bits 0-3 of bank number */
      outb %al, %dx
      incl %edx
      movb %ch, %al
      outb %al, %dx 
      decl %edx

      movb $0x51, %al            /* read register 0x51 */
      outb %al, %dx
      incl %edx
      inb %dx, %al
      decl %edx

      andb $0xF3, %al            /* mix bits 4-5 of bank number */
      shrb $2, %cl
      andb $0x0C, %cl
      orb %al, %cl

      movb $0x51, %al            /* write the bits 4-5 of bank number */
      outb %al, %dx
      incl %edx
      movb %cl, %al
      outb %al, %dx
      decl %edx

      movb $0x38, %al            /* disable extensions */
      outb %al, %dx
      incl %edx
      xorb %al, %al
      outb %al, %dx
      decl %edx

      popl %edx
      popl %ecx
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

   af_bank = bank;
}

void WaitTillIdle(AF_DRIVER *af) {
  unaccelIT();
};


/* BitBlt:
 *  Blits from one part of video memory to another, using the specified
 *  mix operation. This must correctly handle the case where the two
 *  regions overlap.
 */
void blitvram ( int srcx, int srcy, int dstx, int dsty, int dx, int dy, int dir )
{
  do ; while ( inportb(0x9AE8) & 0xFF );
  outportw(0xBAE8, 0x67);
  outportw(0xBEE8, 0xA000);
  outportw(0x86E8, srcx);
  outportw(0x82E8, srcy);
  outportw(0x8EE8, dstx);
  outportw(0x8AE8, dsty);

  outportw(0x96E8, dx-1);
  outportw(0xBEE8, dy-1);
  do ; while ( inportb(0x9AE8) & 0xFF ); /* 0xc013 = 14,15,7,0,2 bits set */
  if ( dir ) outportw(0x9AE8, 0xC013); else outportw(0x9AE8, 0xC0F3);
					 /* 0xc0f3 = 14,15,8,5,1,0 bits set */
};

void copyvram ( int srcx, int srcy, int dstx, int dsty, int dx, int dy )
{
  int dir = 0;
  if ( dsty < srcy || ( srcy == dsty && dstx < srcx )) dir = 0;
  else {
    dir = 1;
    srcx += dx-1;
    srcy += dy-1;
    dstx += dx-1;
    dsty += dy-1;
  };
  accelIT();
  blitvram(srcx, srcy, dstx, dsty, dx, dy, dir);
  if ( af_bpp > 8 && af_chipid <= S86c911A )
    blitvram(srcx+1024, srcy, dstx+1024, dsty, dx, dy, dir);
  unaccelIT();
};

void BitBlt(AF_DRIVER *af, long left, long top, long width, long height, long dstLeft, long dstTop, long op)
{
  copyvram(left, top, dstLeft, dstTop, width, height);
};



