/*
 *       ______             ____  ______     _____  ______ 
 *      |  ____|           |  _ \|  ____|   / / _ \|  ____|
 *      | |__ _ __ ___  ___| |_) | |__     / / |_| | |__ 
 *      |  __| '__/ _ \/ _ \  _ <|  __|   / /|  _  |  __|
 *      | |  | | |  __/  __/ |_) | |____ / / | | | | |
 *      |_|  |_|  \___|\___|____/|______/_/  |_| |_|_|
 *
 *
 *      Assorted helper routines for use by the /AF drivers.
 *
 *      The code in this file makes heavy use of DPMI and VESA functions,
 *      so any drivers that use these helpers will not be portable to
 *      Linux. For maximum portability, a driver should use direct hardware
 *      access for all features, and not touch any of these routines.
 *
 *      See freebe.txt for copyright information.
 */


#include <stdarg.h>
#include <sys/farptr.h>

#include "vbeaf.h"



/* trace_putc:
 *  Debugging trace function 
 */
void trace_putc(char c)
{
   asm (
      " int $0x21 "

   : 

   : "a" (0x200),
     "d" (c)

   : "%eax", 
     "%ebx", 
     "%ecx", 
     "%edx", 
     "%esi", 
     "%edi"
   );
}



/* trace_printf:
 *  Debugging trace function: supports %c, %s, %d, and %x 
 */
void trace_printf(char *msg, ...)
{
   static char hex_digit[] = 
   { 
      '0', '1', '2', '3', '4', '5', '6', '7', 
      '8', '9', 'A', 'B', 'C', 'D', 'E', 'F' 
   };

   unsigned long l;
   char *s;
   int c, i;

   va_list ap;
   va_start(ap, msg);

   while (*msg) {
      if (*msg == '%') {
	 /* handle escape token */
	 msg++;

	 switch (*msg) {

	    case '%':
	       trace_putc('%');
	       break;

	    case 'c':
	       c = va_arg(ap, char);
	       trace_putc(c);
	       break;

	    case 's':
	       s = va_arg(ap, char *);
	       while (*s) {
		  if (*s == '\n')
		     trace_putc('\r');
		  trace_putc(*s);
		  s++;
	       }
	       break;

	    case 'd':
	       c = va_arg(ap, int);
	       if (c < 0) {
		  trace_putc('-');
		  c = -c;
	       }
	       i = 1;
	       while (i*10 <= c)
		  i *= 10;
	       while (i) {
		  trace_putc('0'+c/i);
		  c %= i;
		  i /= 10;
	       }
	       break;

	    case 'x':
	       l = va_arg(ap, unsigned long);
	       for (i=7; i>=0; i--)
		  trace_putc(hex_digit[(l>>(i*4))&0xF]);
	       break;
	 }

	 if (*msg)
	    msg++;
      }
      else {
	 /* output normal character */
	 if (*msg == '\n')
	    trace_putc('\r');
	 trace_putc(*msg);
	 msg++;
      }
   }

   va_end(ap);
}



/* rm_int:
 *  Calls a real mode interrupt: basically the same thing as __dpmi_int().
 */
void rm_int(int num, RM_REGS *regs)
{
   regs->x.flags = 0;
   regs->x.sp = 0;
   regs->x.ss = 0;

   asm (
      " int $0x31 "
   :

   : "a" (0x300),
     "b" (num),
     "c" (0),
     "D" (regs)

   : "%eax", 
     "%ebx", 
     "%ecx", 
     "%edx", 
     "%esi", 
     "%edi"
   );
}



/* allocate_dos_memory:
 *  Allocates a block of conventional memory, returning a real mode segment
 *  address, and filling in the protected mode selector for accessing it.
 *  Returns -1 on error. 
 */
int allocate_dos_memory(int size, int *sel)
{
   int rm_seg;
   int pm_sel;
   int ok;

   asm (
      "  int $0x31 ; "
      "  jc 0f ; "
      "  movl $1, %2 ; "
      "  jmp 1f ; "
      " 0: "
      "  movl $0, %2 ; "
      " 1: "

   : "=a" (rm_seg),
     "=d" (pm_sel),
     "=m" (ok)

   : "a" (0x100),
     "b" ((size+15)/16)

   : "%eax", 
     "%ebx", 
     "%ecx", 
     "%edx", 
     "%esi", 
     "%edi"
   );

   if (!ok)
      return -1;

   *sel = pm_sel;
   return rm_seg;
}



/* free_dos_memory:
 *  Frees a block of conventional memory, given a selector previously 
 *  returned by a call allocate_dos_memory(). 
 */
void free_dos_memory(int sel)
{
   asm (
      " int $0x31 "
   :

   : "a" (0x101),
     "d" (sel)

   : "%eax", 
     "%ebx", 
     "%ecx", 
     "%edx", 
     "%esi", 
     "%edi"
   );
}



/* allocate_selector:
 *  Creates a selector for accessing the specified linear memory region,
 *  returning a selector value or -1 on error.
 */
int allocate_selector(int addr, int size)
{
   int sel;
   int ok;

   asm (
      "  int $0x31 ; "
      "  jc 0f ; "

      "  movl %%eax, %%ebx ; "
      "  movl $7, %%eax ; "
      "  movl %4, %%ecx ; "
      "  movl %5, %%edx ; "
      "  int $0x31 ; "
      "  jc 0f ; "

      "  movl $8, %%eax ; "
      "  movl %6, %%ecx ; "
      "  movl %7, %%edx ; "
      "  int $0x31 ; "
      "  jc 0f ; "

      "  movl $1, %1 ; "
      "  jmp 1f ; "

      " 0: "
      "  movl $1, %1 ; "
      " 1: "

   : "=b" (sel),
     "=D" (ok)

   : "a" (0),
     "c" (1),
     "m" (addr>>16),
     "m" (addr&0xFFFF),
     "m" ((size-1)>>16),
     "m" ((size-1)&0xFFFF)

   : "%eax", 
     "%ebx", 
     "%ecx", 
     "%edx", 
     "%esi", 
     "%edi"
   );

   if (!ok)
      return -1;

   return sel;
}



/* free_selector:
 *  Destroys a selector that was previously created with the 
 *  allocate_selector() function.
 */
void free_selector(int sel) 
{
   asm (
      " int $0x31 "
   :

   : "a" (1),
     "b" (sel)

   : "%eax", 
     "%ebx", 
     "%ecx", 
     "%edx", 
     "%esi", 
     "%edi"
   );
}



/* Helper routines for accessing the underlying VESA interface.
 */


#define MASK_LINEAR(addr)     (addr & 0x000FFFFF)
#define RM_TO_LINEAR(addr)    (((addr & 0xFFFF0000) >> 12) + (addr & 0xFFFF))
#define RM_OFFSET(addr)       (addr & 0xF)
#define RM_SEGMENT(addr)      ((addr >> 4) & 0xFFFF)



typedef struct VESA_INFO         /* VESA information block structure */
{ 
   unsigned char  VESASignature[4]     __attribute__ ((packed));
   unsigned short VESAVersion          __attribute__ ((packed));
   unsigned long  OEMStringPtr         __attribute__ ((packed));
   unsigned char  Capabilities[4]      __attribute__ ((packed));
   unsigned long  VideoModePtr         __attribute__ ((packed)); 
   unsigned short TotalMemory          __attribute__ ((packed)); 
   unsigned short OemSoftwareRev       __attribute__ ((packed)); 
   unsigned long  OemVendorNamePtr     __attribute__ ((packed)); 
   unsigned long  OemProductNamePtr    __attribute__ ((packed)); 
   unsigned long  OemProductRevPtr     __attribute__ ((packed)); 
   unsigned char  Reserved[222]        __attribute__ ((packed)); 
   unsigned char  OemData[256]         __attribute__ ((packed)); 
} VESA_INFO;



typedef struct VESA_MODE_INFO       /* VESA information for a specific mode */
{
   unsigned short ModeAttributes       __attribute__ ((packed)); 
   unsigned char  WinAAttributes       __attribute__ ((packed)); 
   unsigned char  WinBAttributes       __attribute__ ((packed)); 
   unsigned short WinGranularity       __attribute__ ((packed)); 
   unsigned short WinSize              __attribute__ ((packed)); 
   unsigned short WinASegment          __attribute__ ((packed)); 
   unsigned short WinBSegment          __attribute__ ((packed)); 
   unsigned long  WinFuncPtr           __attribute__ ((packed)); 
   unsigned short BytesPerScanLine     __attribute__ ((packed)); 
   unsigned short XResolution          __attribute__ ((packed)); 
   unsigned short YResolution          __attribute__ ((packed)); 
   unsigned char  XCharSize            __attribute__ ((packed)); 
   unsigned char  YCharSize            __attribute__ ((packed)); 
   unsigned char  NumberOfPlanes       __attribute__ ((packed)); 
   unsigned char  BitsPerPixel         __attribute__ ((packed)); 
   unsigned char  NumberOfBanks        __attribute__ ((packed)); 
   unsigned char  MemoryModel          __attribute__ ((packed)); 
   unsigned char  BankSize             __attribute__ ((packed)); 
   unsigned char  NumberOfImagePages   __attribute__ ((packed));
   unsigned char  Reserved_page        __attribute__ ((packed)); 
   unsigned char  RedMaskSize          __attribute__ ((packed)); 
   unsigned char  RedMaskPos           __attribute__ ((packed)); 
   unsigned char  GreenMaskSize        __attribute__ ((packed)); 
   unsigned char  GreenMaskPos         __attribute__ ((packed));
   unsigned char  BlueMaskSize         __attribute__ ((packed)); 
   unsigned char  BlueMaskPos          __attribute__ ((packed)); 
   unsigned char  ReservedMaskSize     __attribute__ ((packed)); 
   unsigned char  ReservedMaskPos      __attribute__ ((packed)); 
   unsigned char  DirectColorModeInfo  __attribute__ ((packed));

   /* VBE 2.0 extensions */
   unsigned long  PhysBasePtr          __attribute__ ((packed)); 
   unsigned long  OffScreenMemOffset   __attribute__ ((packed)); 
   unsigned short OffScreenMemSize     __attribute__ ((packed)); 

   /* VBE 3.0 extensions */
   unsigned short LinBytesPerScanLine  __attribute__ ((packed));
   unsigned char  BnkNumberOfPages     __attribute__ ((packed));
   unsigned char  LinNumberOfPages     __attribute__ ((packed));
   unsigned char  LinRedMaskSize       __attribute__ ((packed));
   unsigned char  LinRedFieldPos       __attribute__ ((packed));
   unsigned char  LinGreenMaskSize     __attribute__ ((packed));
   unsigned char  LinGreenFieldPos     __attribute__ ((packed));
   unsigned char  LinBlueMaskSize      __attribute__ ((packed));
   unsigned char  LinBlueFieldPos      __attribute__ ((packed));
   unsigned char  LinRsvdMaskSize      __attribute__ ((packed));
   unsigned char  LinRsvdFieldPos      __attribute__ ((packed));
   unsigned long  MaxPixelClock        __attribute__ ((packed));

   unsigned char  Reserved[190]        __attribute__ ((packed)); 
} VESA_MODE_INFO;



#define MAX_VESA_MODES  256



#define SAFETY_BUFFER   4096



/* get_vesa_info:
 *  Retrieves data from the VESA info block structure and mode list, 
 *  returning 0 for success.
 */
int get_vesa_info(int *vram_size, unsigned long *linear_addr, void (*callback)(int vesa_num, int linear, int w, int h, int bpp, int bytes_per_scanline, int redsize, int redpos, int greensize, int greenpos, int bluesize, int bluepos, int rsvdsize, int rsvdpos))
{
   VESA_INFO vesa_info;
   VESA_MODE_INFO mode_info;
   RM_REGS r;
   int mode_list[MAX_VESA_MODES];
   long mode_ptr;
   int num_modes;
   int seg, sel;
   int c, i;

   /* fetch the VESA info block */
   seg = allocate_dos_memory(sizeof(VESA_INFO)+SAFETY_BUFFER, &sel);
   if (seg < 0)
      return -1;

   for (c=0; c<(int)sizeof(VESA_INFO); c++)
      _farpokeb(sel, c, 0);

   _farpokeb(sel, 0, 'V');
   _farpokeb(sel, 1, 'B');
   _farpokeb(sel, 2, 'E');
   _farpokeb(sel, 3, '2');

   r.x.ax = 0x4F00;
   r.x.di = 0;
   r.x.es = seg;
   rm_int(0x10, &r);
   if (r.h.ah) {
      free_dos_memory(sel);
      return -1;
   }

   for (c=0; c<(int)sizeof(VESA_INFO); c++)
      ((char *)&vesa_info)[c] = _farpeekb(sel, c);

   free_dos_memory(sel);

   if ((vesa_info.VESASignature[0] != 'V') ||
       (vesa_info.VESASignature[1] != 'E') ||
       (vesa_info.VESASignature[2] != 'S') ||
       (vesa_info.VESASignature[3] != 'A'))
      return -1;

   *vram_size = vesa_info.TotalMemory << 16;

   if (linear_addr)
      *linear_addr = 0;

   sel = allocate_selector(0, 1024*1024);
   if (sel < 0)
      return -1;

   /* read the mode list */
   mode_ptr = RM_TO_LINEAR(vesa_info.VideoModePtr);
   num_modes = 0;

   while ((mode_list[num_modes] = _farpeekw(sel, mode_ptr)) != 0xFFFF) {
      num_modes++;
      mode_ptr += 2;
      if (num_modes >= MAX_VESA_MODES)
	 break;
   }

   free_selector(sel);

   seg = allocate_dos_memory(sizeof(VESA_MODE_INFO)+SAFETY_BUFFER, &sel);
   if (seg < 0)
      return -1;

   /* fetch info about each supported mode */
   for (c=0; c<num_modes; c++) {
      for (i=0; i<(int)sizeof(VESA_MODE_INFO); i++)
	 _farpokeb(sel, i, 0);

      r.x.ax = 0x4F01;
      r.x.di = 0;
      r.x.es = seg;
      r.x.cx = mode_list[c];
      rm_int(0x10, &r);

      if (r.h.ah == 0) {
	 for (i=0; i<(int)sizeof(VESA_MODE_INFO); i++)
	    ((char *)&mode_info)[i] = _farpeekb(sel, i);

	 if ((mode_info.ModeAttributes & 25) == 25) {
	    /* bodge for VESA drivers that report wrong values */
	    if ((mode_info.BitsPerPixel == 16) && (mode_info.ReservedMaskSize == 1))
	       mode_info.BitsPerPixel = 15;

	    if (mode_info.ModeAttributes & 128) {
	       /* linear framebuffer mode */
	       if (linear_addr)
		  *linear_addr = mode_info.PhysBasePtr;

	       if (vesa_info.VESAVersion >= 0x300) {
		  if (callback) {
		     callback(mode_list[c], TRUE,
			      mode_info.XResolution, mode_info.YResolution,
			      mode_info.BitsPerPixel, mode_info.LinBytesPerScanLine,
			      mode_info.LinRedMaskSize, mode_info.LinRedFieldPos,
			      mode_info.LinGreenMaskSize, mode_info.LinGreenFieldPos,
			      mode_info.LinBlueMaskSize, mode_info.LinBlueFieldPos,
			      mode_info.LinRsvdMaskSize, mode_info.LinRsvdFieldPos);
		  }
	       }
	       else {
		  if (callback) {
		     callback(mode_list[c], TRUE,
			      mode_info.XResolution, mode_info.YResolution,
			      mode_info.BitsPerPixel, mode_info.BytesPerScanLine,
			      mode_info.RedMaskSize, mode_info.RedMaskPos,
			      mode_info.GreenMaskSize, mode_info.GreenMaskPos,
			      mode_info.BlueMaskSize, mode_info.BlueMaskPos,
			      mode_info.ReservedMaskSize, mode_info.ReservedMaskPos);
		  }
	       }
	    }
	    else {
	       /* banked mode */
	       if (callback) {
		  callback(mode_list[c], FALSE,
			   mode_info.XResolution, mode_info.YResolution,
			   mode_info.BitsPerPixel, mode_info.BytesPerScanLine,
			   mode_info.RedMaskSize, mode_info.RedMaskPos,
			   mode_info.GreenMaskSize, mode_info.GreenMaskPos,
			   mode_info.BlueMaskSize, mode_info.BlueMaskPos,
			   mode_info.ReservedMaskSize, mode_info.ReservedMaskPos);
	       }
	    }
	 }
      }
   }

   free_dos_memory(sel);

   return 0;
}



/* FindPCIDevice:
 *  Replacement for the INT 1A - PCI BIOS v2.0c+ - FIND PCI DEVICE, AX = B102h
 *
 *  Note: deviceIndex is because a card can hold more than one PCI chip.
 * 
 *  Searches the board of the vendor supplied in vendorID with 
 *  identification number deviceID and index deviceIndex (normally 0). 
 *  The value returned in handle can be used to access the PCI registers 
 *  of this board.
 *
 *  Return: 1 if found 0 if not found.
 */
int FindPCIDevice(int deviceID, int vendorID, int deviceIndex, int *handle)
{
   int model, vendor, card, device;
   unsigned value, full_id, bus, busMax;

   deviceIndex <<= 8;

   for (bus=0, busMax=0x10000; bus<busMax; bus+=0x10000) {
      for (device=0, card=0; card<32; card++, device+=0x800) {
	 value = PCIEnable | deviceIndex | device;
	 outportl(PCIConfigurationAddress, value);
	 full_id = inportl(PCIConfigurationData);
	 vendor = full_id & 0xFFFF;
	 model = full_id>>16;
	 if (vendor!=0xFFFF) {
	    if (full_id==0x00011011) { 
	       /* According to the Xfree86 people Digital have a bridge
		* (pci-pci) with this ID
		*/
	       busMax += 0x10000;
	    }
	    if ((deviceID==model) && (vendorID==vendor)) {
	       *handle = value;
	       return 1;
	    }
	 }
      }
   }

   return 0;
}



/* fixup_feature_list:
 *  Helper for the FAF_CFG_FEATURES extension, for blanking out any
 *  accelerated drawing routines that the install program has disabled.
 */
void fixup_feature_list(AF_DRIVER *af, unsigned long flags)
{
   if (!(flags & fafHWCursor)) {
      af->Attributes &= ~afHaveHWCursor;

      af->SetCursor = NULL;
      af->SetCursorPos = NULL;
      af->SetCursorColor = NULL;
      af->ShowCursor = NULL;
   }

   if (!(flags & fafDrawScan))               af->DrawScan = NULL;
   if (!(flags & fafDrawPattScan))           af->DrawPattScan = NULL;
   if (!(flags & fafDrawColorPattScan))      af->DrawColorPattScan = NULL;
   if (!(flags & fafDrawScanList))           af->DrawScanList = NULL;
   if (!(flags & fafDrawPattScanList))       af->DrawPattScanList = NULL;
   if (!(flags & fafDrawColorPattScanList))  af->DrawColorPattScanList = NULL;
   if (!(flags & fafDrawRect))               af->DrawRect = NULL;
   if (!(flags & fafDrawPattRect))           af->DrawPattRect = NULL;
   if (!(flags & fafDrawColorPattRect))      af->DrawColorPattRect = NULL;
   if (!(flags & fafDrawLine))               af->DrawLine = NULL;
   if (!(flags & fafDrawStippleLine))        af->DrawStippleLine = NULL;
   if (!(flags & fafDrawTrap))               af->DrawTrap = NULL;
   if (!(flags & fafDrawTri))                af->DrawTri = NULL;
   if (!(flags & fafDrawQuad))               af->DrawQuad = NULL;
   if (!(flags & fafPutMonoImage))           af->PutMonoImage = NULL;
   if (!(flags & fafPutMonoImageLin))        af->PutMonoImageLin = NULL;
   if (!(flags & fafPutMonoImageBM))         af->PutMonoImageBM = NULL;
   if (!(flags & fafBitBlt))                 af->BitBlt = NULL;
   if (!(flags & fafBitBltSys))              af->BitBltSys = NULL;
   if (!(flags & fafBitBltLin))              af->BitBltLin = NULL;
   if (!(flags & fafBitBltBM))               af->BitBltBM = NULL;
   if (!(flags & fafSrcTransBlt))            af->SrcTransBlt = NULL;
   if (!(flags & fafSrcTransBltSys))         af->SrcTransBltSys = NULL;
   if (!(flags & fafSrcTransBltLin))         af->SrcTransBltLin = NULL;
   if (!(flags & fafSrcTransBltBM))          af->SrcTransBltBM = NULL;
}


