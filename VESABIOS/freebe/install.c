/*
 *       ______             ____  ______     _____  ______ 
 *      |  ____|           |  _ \|  ____|   / / _ \|  ____|
 *      | |__ _ __ ___  ___| |_) | |__     / / |_| | |__ 
 *      |  __| '__/ _ \/ _ \  _ <|  __|   / /|  _  |  __|
 *      | |  | | |  __/  __/ |_) | |____ / / | | | | |
 *      |_|  |_|  \___|\___|____/|______/_/  |_| |_|_|
 *
 *
 *      Installation utility.
 *
 *      See freebe.txt for copyright information.
 */


#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <strings.h>
#include <ctype.h>
#include <conio.h>
#include <bios.h>
#include <go32.h>
#include <sys/farptr.h>
#include <sys/exceptn.h>
#include <allegro.h>

#include "vbeaf.h"



#define VBEAF_FILENAME     "c:\\vbeaf.drv"


#define ever ;;



/* info about one of the VBE/AF drivers */
typedef struct DRIVER_INFO
{
   char name[80];
   AF_DRIVER *driver;
   int driver_size;
   char *notes;
   int notes_size;
   int present;
   int accel;
   int config;
} DRIVER_INFO;



#define MAX_DRIVERS  256


DRIVER_INFO driver_info[MAX_DRIVERS];

int num_drivers = 0;


char current_driver_name[80];
char current_driver_copyright[80];



/* graphics characters */
#define TL_CHAR         0xDA
#define TOP_CHAR        0xC4
#define TR_CHAR         0xBF
#define SIDE_CHAR       0xB3
#define BL_CHAR         0xC0
#define BR_CHAR         0xD9
#define SHADOW_CHAR     0xDB



/* drawing state variables */
int _text_color = 0;
int _text_x = 0;
int _text_y = 0;

int screen_h;



/* mouse driver state variables */
int m_state;
int m_x = 0;
int m_y = 0;
int m_b = 0;



/* sets up the mouse driver */
void mouse_init()
{
   __dpmi_regs reg;

   reg.x.ax = 0;
   __dpmi_int(0x33, &reg);
   m_state = reg.x.ax;

   if (m_state) {
      reg.x.ax = 10;
      reg.x.bx = 0;
      reg.x.cx = 0xffff;
      reg.x.dx = 0x7700;
      __dpmi_int(0x33, &reg);
   }
}



/* displays the mouse pointer */
void mouse_on()
{
   __dpmi_regs reg;

   if (m_state) {
      reg.x.ax = 1;
      __dpmi_int(0x33, &reg);
   }
}



/* hides the mouse pointer */
void mouse_off()
{
   __dpmi_regs reg;

   if (m_state) {
       reg.x.ax = 2;
       __dpmi_int(0x33, &reg);
   }
}



/* reads the mouse state */
void mouse_read()
{
   __dpmi_regs reg;

   if (m_state) {
      reg.x.ax = 3;
      __dpmi_int(0x33, &reg);

      m_x = reg.x.cx / 8;
      m_y = reg.x.dx / 8;
      m_b = reg.x.bx;
   }
}



/* sets the mouse position */
void mouse_move(int x, int y)
{
   __dpmi_regs reg;

   if (m_state) {
      reg.x.ax = 4;
      reg.x.cx = x*8;
      reg.x.dx = y*8;
      __dpmi_int(0x33, &reg);

      m_x = x;
      m_y = y;
   }
}



/* waits for a keypress or mouse button click */
void input_pause()
{
   mouse_on();

   while (m_b)
      mouse_read();

   for(ever) {
      if (bioskey(1)) {
	 bioskey(0);
	 break;
      }

      mouse_read();
      if (m_b)
	 break;
   }

   mouse_off();
}



/* sets the drawing color */
void text_color(int c)
{
   _text_color = c;
}



/* sets the drawing position */
void text_pos(int x, int y)
{
   _text_x = x-1; 
   _text_y = y-1; 
}



/* prints a character */
void text_c(int c)
{
   if (_text_x < 80)
      _farpokew(_dos_ds, 0xB8000+_text_x*2+_text_y*160, c|(_text_color<<8));

   _text_x++; 
}



/* prints a string */
void text_str(char *s) 
{ 
   while (*s) { 
      text_c((unsigned char)*s); 
      s++; 
   } 
}



/* prints the first part of a string */
void text_clamp(char *s, int max) 
{ 
   int i;

   if ((int)strlen(s) <= max) {
      text_str(s);
   }
   else {
      for (i=0; i<max; i++)
	 text_c((unsigned char)s[i]);

      text_str("..."); 
   }
}



/* clears to the end of the current line */
void text_clear_eol() 
{ 
   while (_text_x < 80)
      text_c(' ');
}



/* helper for drawing a box onto the screen */
void draw_box(int w, int h)
{
   static char url[] = "http://www.talula.demon.co.uk/freebe/";
   int x, y, e;

   /* status text */
   text_color(0x07);

   text_pos(1, 1);
   text_str("FreeBE/AF " FREEBE_VERSION);

   while (_text_x < 80-(int)strlen(url))
      text_c(' ');

   text_str(url);

   text_pos(1, screen_h-2);
   text_str("Currently installed driver:");
   text_clear_eol();

   text_pos(1, screen_h-1);
   text_str(current_driver_name);
   text_clear_eol();

   text_pos(1, screen_h);
   text_str(current_driver_copyright);
   text_clear_eol();

   text_color(0x74);

   /* top border */
   text_pos(40-w/2-1, screen_h/2-h/2-1);
   text_c(TL_CHAR);

   for (x=0; x<w; x++)
      text_c(TOP_CHAR);

   text_c(TR_CHAR);

   /* box body */
   for (y=0; y<h; y++) {
      text_pos(40-w/2-1, screen_h/2-h/2+y);

      text_c(SIDE_CHAR);

      for (x=0; x<w; x++)
	 text_c(' ');

      text_c(SIDE_CHAR);
   }

   /* bottom border */
   text_pos(40-w/2-1, screen_h/2+(h+1)/2);
   text_c(BL_CHAR);

   for (x=0; x<w; x++)
      text_c(TOP_CHAR);

   text_c(BR_CHAR);

   /* shadow */
   text_color(0x08);

   for (y=0; y<=h; y++) {
      text_pos(41+w/2, screen_h/2-h/2+y);
      text_c(SHADOW_CHAR);
   }

   text_pos(40-w/2, screen_h/2+(h+1)/2+1);

   for (x=0; x<=w+1; x++)
      text_c(SHADOW_CHAR);

   /* clear the rest of the screen */
   text_color(0);

   for (y=2; y<screen_h/2-h/2-1; y++) {
      text_pos(1, y);
      for (x=0; x<80; x++)
	 text_c(' ');
   }

   for (y=screen_h/2+(h+1)/2+2; y<screen_h-2; y++) {
      text_pos(1, y);
      for (x=0; x<80; x++)
	 text_c(' ');
   }

   for (y=screen_h/2-h/2-1; y<screen_h/2+(h+1)/2+2; y++) {
      e = (y == screen_h/2+(h+1)/2+1) ? 1 : 0;
      text_pos(1, y);
      for (x=1; x<40-w/2-1+e; x++)
	 text_c(' ');

      e = (y == screen_h/2-h/2-1) ? 1 : 0;
      text_pos(42+w/2-e, y);
      for (x=42+w/2-e; x<=80; x++)
	 text_c(' ');
   }

   text_color(0x71);
}



/* main menu interface function */
int get_selection(char **str, int sel, int num, int y, int samescroll)
{
   static int oldscroll = 0;
   int scroll;
   long start, sstart;
   int redraw;
   int count, len;
   int i, j, c, x;
   int ox, oy;
   int ob = 0;

   count = 0;
   len = 0;

   while (str[count]) {
      if (*str[count] <= '\002')
	 i = 6+strlen(str[count]+1);
      else
	 i = strlen(str[count]);

      if (len < i)
	 len = i;

      count++;
   }

   if (count > num) {
      y++;
      num -= 2;
   }

   if (samescroll)
      scroll = oldscroll;
   else
      scroll = MID(0, sel-num/2, count-num);

   len += 8;
   x = 40-len/2;

   sstart = clock();

   for(ever) {
      /* draw the menu */
      for (i=0; i<num; i++) {
	 if (i+scroll == sel)
	    text_color(0x07);
	 else
	    text_color(0x70);

	 text_pos(x, y+i+1);
	 text_str("    ");

	 if (*str[i+scroll] <= '\002') {
	    if (*str[i+scroll] == '\001') {
	       if (i+scroll == sel)
		  text_color(0x02);
	       else
		  text_color(0x72);

	       text_str("ON -- ");
	    }
	    else {
	       if (i+scroll == sel)
		  text_color(0x04);
	       else
		  text_color(0x74);

	       text_str("OFF - ");
	    }

	    if (i+scroll == sel)
	       text_color(0x07);
	    else
	       text_color(0x70);

	    text_str(str[i+scroll]+1);

	    for (j=strlen(str[i+scroll]+1)+10; j<len; j++)
	       text_c(' ');
	 }
	 else {
	    text_str(str[i+scroll]);

	    for (j=strlen(str[i+scroll])+4; j<len; j++)
	       text_c(' ');
	 }
      }

      if (count > num) {
	 text_color(0x78);

	 text_pos(x+4, y);
	 if (scroll > 0)
	    text_str("--- more ---");
	 else
	    text_str("            ");

	 text_pos(x+4, y+num+1);
	 if (scroll < count-num)
	    text_str("--- more ---");
	 else
	    text_str("            ");
      }

      mouse_on();

      while ((m_b) && (!ob))
	 mouse_read();

      redraw = FALSE;

      while (!redraw) {
	 if (bioskey(1)) {
	    /* deal with keyboard input */
	    c = bioskey(0);

	    switch (c>>8) {

	       case KEY_UP:
		  if (sel > 0) {
		     sel--;
		     if (sel < scroll)
			scroll = sel;
		     redraw = TRUE;
		  }
		  break;

	       case KEY_DOWN:
		  if (sel < count-1) {
		     sel++;
		     if (sel >= scroll+num)
			scroll = sel-num+1;
		     redraw = TRUE;
		  }
		  break;

	       case KEY_PGUP:
		  if (sel > scroll) {
		     sel = scroll;
		  }
		  else {
		     sel = scroll = MAX(sel-num+1, 0);
		  }
		  redraw = TRUE;
		  break;

	       case KEY_PGDN:
		  if (sel < scroll+num-1) {
		     sel = scroll+num-1;
		  }
		  else {
		     sel = MIN(sel+num-1, count-1);
		     scroll = sel-num+1;
		  }
		  redraw = TRUE;
		  break;

	       case KEY_HOME:
		  sel = scroll = 0;
		  redraw = TRUE;
		  break;

	       case KEY_END:
		  sel = count-1;
		  scroll = count-num;
		  redraw = TRUE;
		  break;

	       case KEY_ENTER:
	       case KEY_SPACE:
		  mouse_off();
		  oldscroll = scroll;
		  return sel;

	       case KEY_ESC:
		  mouse_off();
		  oldscroll = scroll;
		  return -1;
	    }
	 }
	 else {
	    /* deal with mouse input */
	    mouse_read();

	    if (m_b & 2) {
	       /* right button cancels */
	       mouse_off();
	       oldscroll = scroll;
	       return -1;
	    }

	    if (m_b & 1) {
	       if ((m_x >= x-1) && (m_x < x+len-1) &&
		   (m_y >= y) && (m_y < y+num)) {
		  if (sel == m_y-y+scroll) {
		     /* double click detection */
		     start = clock();

		     ox = m_x;
		     oy = m_y;

		     /* check for release */
		     while (((clock() - start) < CLOCKS_PER_SEC/4) &&
			    (ox == m_x) && (oy == m_y) && (m_b & 1))
			mouse_read();

		     if (!(m_b & 1)) {
			start = clock();
			ox = m_x;
			oy = m_y;

			/* check for second click */
			while (((clock() - start) < CLOCKS_PER_SEC/4) &&
			       (ox == m_x) && (oy == m_y) && (!(m_b & 1)))
			   mouse_read();

			if (m_b & 1) {
			   /* yeah! dclick... */
			   mouse_off();
			   oldscroll = scroll;
			   return sel;
			}
		     }
		  }
		  else {
		     /* left button selects */
		     sel = m_y-y+scroll;
		     redraw = TRUE;
		  }
	       }
	       else if ((m_x >= x-1) && (m_x < x+len-1) && (m_y < y) && 
			(scroll > 0) && (clock() > sstart+CLOCKS_PER_SEC/24)) {
		  /* upward mouse scrolling */
		  scroll--;
		  sel = scroll;
		  redraw = TRUE;
		  sstart = clock();
	       }
	       else if ((m_x >= x-1) && (m_x < x+len-1) && (m_y >= y+num) && 
			(scroll < count-num) && (clock() > sstart+CLOCKS_PER_SEC/24)) {
		  /* downward mouse scrolling */
		  scroll++;
		  sel = scroll+num-1;
		  redraw = TRUE;
		  sstart = clock();
	       }
	    }

	    ob = m_b;
	 }
      }

      mouse_off();
   }
}



/* helper to remove a string from within another string */
void strip_text(char *str, char *kill)
{
   char *s = strstr(str, kill);

   if (s) {
      if ((s > str) && (s[-1] == ' '))
	 strcpy(s-1, s+strlen(kill));
      else if (s[strlen(kill)] == ' ')
	 strcpy(s, s+strlen(kill)+1);
      else
	 strcpy(s, s+strlen(kill));
   }
}



/* qsort() callback for sorting the driver list */
int driver_cmp(const void *q1, const void *q2)
{
   DRIVER_INFO *d1 = (DRIVER_INFO *)q1;
   DRIVER_INFO *d2 = (DRIVER_INFO *)q2;

   return strcmp(d1->name, d2->name);
}



/* read the appended driver data */
int read_driver_data()
{
   typedef unsigned long (*EXT_INIT_FUNC)(AF_DRIVER *af, unsigned long id);
   EXT_INIT_FUNC ext_init;
   FAF_CONFIG_DATA *cfg;
   AF_DRIVER *af;
   DRIVER_INFO *info;
   PACKFILE *f;
   char name[80];
   unsigned long magic;
   int type, size, ret;

   f = pack_fopen("#", F_READ_PACKED);

   if (!f)
      return 1;

   pack_mgetl(f);
   pack_mgetl(f);

   while (!pack_feof(f)) {
      type = pack_mgetl(f);

      if (type == DAT_FILE) {
	 f = pack_fopen_chunk(f, FALSE);
	 pack_mgetl(f);

	 info = &driver_info[num_drivers];

	 info->driver = NULL;
	 info->notes = NULL;

	 name[0] = 0;

	 while (!pack_feof(f)) {
	    type = pack_mgetl(f);

	    if (type == DAT_PROPERTY) {
	       type = pack_mgetl(f);
	       size = pack_mgetl(f);

	       if (type == DAT_NAME) {
		  pack_fread(name, size, f);
		  name[size] = 0;
	       }
	       else
		  pack_fseek(f, size);
	    }
	    else {
	       f = pack_fopen_chunk(f, FALSE);

	       if (strcmp(name, "VBEAF_DRV") == 0) {
		  info->driver_size = f->todo;
		  info->driver = malloc(info->driver_size);
		  pack_fread(info->driver, info->driver_size, f);
	       }
	       else if (strcmp(name, "NOTES_TXT") == 0) {
		  info->notes_size = f->todo;
		  info->notes = malloc(info->notes_size);
		  pack_fread(info->notes, info->notes_size, f);
	       }

	       f = pack_fclose_chunk(f);
	    }
	 }

	 if ((info->driver) && (info->notes)) {
	    strcpy(info->name, info->driver->OemVendorName);

	    strip_text(info->name, "FreeBE/AF");
	    strip_text(info->name, "driver");
	    strip_text(info->name, FREEBE_VERSION);

	    info->present = FALSE;
	    info->accel = FALSE;
	    info->config = 0;

	    af = malloc(info->driver_size);

	    if (af) {
	       memcpy(af, info->driver, info->driver_size);

	       if (af->OemExt) {
		  ext_init = (EXT_INIT_FUNC)((long)af + (long)af->OemExt);
		  magic = ext_init(af, FAFEXT_INIT);

		  if (((magic&0xFFFF0000) == FAFEXT_MAGIC) && (isdigit((magic>>8)&0xFF)) && (isdigit(magic&0xFF))) {
		     cfg = af->OemExt(af, FAFEXT_CONFIG);

		     if (cfg) {
			while (cfg->id) {
			   if (cfg->id == FAF_CFG_FEATURES) {
			      info->config = (unsigned long)&cfg->value - (unsigned long)af;
			      break;
			   }

			   cfg++;
			}
		     }
		  }
	       }

	       asm (
		  "  call *%2 "

	       : "=&a" (ret)
	       : "b" (af),
		 "rm" (((long)af + (long)af->PlugAndPlayInit))
	       : "memory"
	       );

	       if (ret == 0) {
		  info->present = TRUE;
		  info->accel = ((af->Attributes & afHaveAccel2D) != 0);
	       }

	       free(af);
	    }

	    num_drivers++;
	 }

	 f = pack_fclose_chunk(f);
      }
      else if (type == DAT_PROPERTY) {
	 pack_mgetl(f);
	 size = pack_mgetl(f);
	 pack_fseek(f, size);
      }
      else {
	 size = pack_mgetl(f);
	 pack_fseek(f, size+4);
      }
   }

   pack_fclose(f);

   if (num_drivers > 1)
      qsort(driver_info, num_drivers, sizeof(DRIVER_INFO), driver_cmp);

   return 0;
}



/* detects what VBE/AF driver is currently installed */
int check_current_driver()
{
   static char *options[] =
   {
      "Overwrite existing driver",
      "Backup c:\\vbeaf.drv to c:\\vbeaf.old",
      "Abort installation",
      NULL
   };

   AF_DRIVER driver;
   PACKFILE *f;

   f = pack_fopen(VBEAF_FILENAME, F_READ);

   if (!f) {
      strcpy(current_driver_name, "{none}");
      strcpy(current_driver_copyright, "");
      return 0;
   }

   pack_fread(&driver, sizeof(driver), f);
   pack_fclose(f);

   strcpy(current_driver_name, driver.OemVendorName);
   strcpy(current_driver_copyright, driver.OemCopyright);

   if (strstr(current_driver_name, "FreeBE/AF"))
      return 0;

   draw_box(60, 16);

   text_pos(12, screen_h/2-6);
   text_str("Existing VBE/AF driver detected:");

   text_color(0x74);

   text_pos(16, screen_h/2-4);
   text_clamp(current_driver_name, 48);

   text_pos(16, screen_h/2-3);
   text_clamp(current_driver_copyright, 48);

   text_color(0x71);

   text_pos(12, screen_h/2-1);
   text_str("If this is one of the SciTech Display Doctor drivers,");

   text_pos(12, screen_h/2);
   text_str("it will be regenerated whenever you load UniVBE. You");

   text_pos(12, screen_h/2+1);
   text_str("will need to uninstall SDD before using FreeBE/AF.");

   switch (get_selection(options, 0, 3, screen_h/2+3, FALSE)) {

      case 0:
	 /* overwrite */
	 return 0;

      case 1:
	 /* backup */
	 remove("c:\\vbeaf.old");
	 rename(VBEAF_FILENAME, "c:\\vbeaf.old");
	 strcpy(current_driver_name, "{none}");
	 strcpy(current_driver_copyright, "");
	 return 0;

      default:
	 /* abort */
	 return 1;
   }
}



/* displays the readme information */
void text_viewer(char *text, int len)
{
   char buf[256];
   int redraw;
   int total, pos;
   int line;
   int c, i, l, p;
   int oy;

   total = 1;
   pos = 0;

   /* count number of lines */
   for (i=0; i<len; i++) {
      if ((text[i] == '\r') || (text[i] == '\n')) {
	 total++;

	 if ((i<len-1) && (text[i] == '\r') && (text[i+1] == '\n'))
	    i++;
      }
   }

   mouse_move(40, screen_h/2);

   for(ever) {
      text_color(0x70);

      p = 0;

      /* skip lines that we have scrolled past */
      for (i=0; i<pos; i++) {
	 while ((p < len) && (text[p] != '\r') && (text[p] != '\n'))
	    p++;

	 if ((p < len) && (text[p] == '\r'))
	    p++;

	 if ((p < len) && (text[p] == '\n'))
	    p++;
      }

      /* redraw the screen */
      for (line=1; line<=screen_h; line++) {
	 text_pos(1, line);

	 l = 0;

	 while ((p < len) && (l < 255) && (text[p] != '\r') && (text[p] != '\n')) {
	    buf[l] = text[p];

	    if (buf[l] == '\t') {
	       for (i=0; (i<8) && (i+l<255); i++)
		  buf[l+i] = ' ';
	       l += 7;
	    }

	    l++;
	    p++;
	 }

	 buf[l] = 0;

	 if ((p < len) && (text[p] == '\r'))
	    p++;

	 if ((p < len) && (text[p] == '\n'))
	    p++;

	 text_str(buf);
	 text_clear_eol();
      }

      while (m_b)
	 mouse_read();

      redraw = FALSE;

      while (!redraw) {
	 if (bioskey(1)) {
	    /* process keyboard input */
	    c = bioskey(0);

	    switch (c>>8) {

	       case KEY_UP:
		  if (pos > 0)
		     pos--;
		  redraw = TRUE;
		  break;

	       case KEY_DOWN:
		  if (pos < total-screen_h)
		     pos++;
		  redraw = TRUE;
		  break;

	       case KEY_HOME:
		  pos = 0;
		  redraw = TRUE;
		  break;

	       case KEY_END:
		  pos = total-screen_h;
		  if (pos < 0)
		     pos = 0;
		  redraw = TRUE;
		  break;

	       case KEY_PGUP:
		  pos -= screen_h-1;
		  if (pos < 0)
		     pos = 0;
		  redraw = TRUE;
		  break;

	       case KEY_PGDN:
		  pos += screen_h-1;
		  if (pos > total-screen_h)
		     pos = total-screen_h;
		  if (pos < 0)
		     pos = 0;
		  redraw = TRUE;
		  break;

	       case KEY_ESC:
	       case KEY_ENTER:
	       case KEY_SPACE:
		  return;
	    }
	 }
	 else {
	    /* process mouse input */
	    oy = m_y;

	    mouse_read();

	    if (m_b)
	       return;

	    if (m_y != oy) {
	       pos += m_y-oy;
	       if (pos > total-screen_h)
		  pos = total-screen_h;
	       if (pos < 0)
		  pos = 0;
	       mouse_move(40, screen_h/2);
	       redraw = TRUE;
	    }
	 }
      }
   }
}



/* allows the user to edit the driver configuration */
void edit_config(unsigned long *features, unsigned long orig_features)
{
   static char *flist[] =
   {
      "*Linear Framebuffer",
      "*Banked Framebuffer",
      "*Hardware Cursor",
      "*DrawScan()",
      "*DrawPattScan()",
      "*DrawColorPattScan()",
      "*DrawScanList()",
      "*DrawPattScanList()",
      "*DrawColorPattScanList()",
      "*DrawRect()",
      "*DrawPattRect()",
      "*DrawColorPattRect()",
      "*DrawLine()",
      "*DrawStippleLine()",
      "*DrawTrap()",
      "*DrawTri()",
      "*DrawQuad()",
      "*PutMonoImage()",
      "*PutMonoImageLin()",
      "*PutMonoImageBM()",
      "*BitBlt()",
      "*BitBltSys()",
      "*BitBltLin()",
      "*BitBltBM()",
      "*SrcTransBlt()",
      "*SrcTransBltSys()",
      "*SrcTransBltLin()",
      "*SrcTransBltBM()",
      "Go Back",
      NULL
   };

   static int sel = 0;
   int virgin = TRUE;
   char *list[34];
   int index[32];
   int num_options, n, i;

   num_options = 0;

   for (n=0; n<(int)(sizeof(flist)/sizeof(char *)-2); n++) {
      if (orig_features & (1<<n)) {
	 list[num_options] = flist[n];
	 index[num_options] = n;
	 num_options++;

	 if (*features & (1<<n))
	    *flist[n] = '\001';
	 else
	    *flist[n] = '\002';
      }
   }

   list[num_options++] = flist[n];
   list[num_options] = NULL;

   if (sel >= num_options)
      sel = 0;

   n = MIN(num_options, screen_h*4/7);

   draw_box(40, n+2);

   for(ever) {
      i = get_selection(list, sel, n, screen_h/2-n/2-1, !virgin);
      if (i >= 0)
	 sel = i;

      if ((i >= 0) && (i < num_options-1)) {
	 *features ^= (1<<index[i]);

	 if (*features & (1<<index[i]))
	    *list[i] = '\001';
	 else
	    *list[i] = '\002';
      }
      else
	 return;

      virgin = FALSE;
   }
}



/* writes vbeaf.drv to c:\ */
int install_driver(DRIVER_INFO *info, unsigned long features, unsigned long orig_features)
{
   PACKFILE *f;

   f = pack_fopen(VBEAF_FILENAME, F_WRITE);

   if (!f) {
      draw_box(60, 3);
      text_pos(16, screen_h/2);
      text_str("Error installing driver!");
      input_pause();
      return FALSE;
   }

   if (info->config)
      *((unsigned long *)((unsigned long)info->driver+info->config)) = features;

   pack_fwrite(info->driver, info->driver_size, f);
   pack_fclose(f);

   if (info->config)
      *((unsigned long *)((unsigned long)info->driver+info->config)) = orig_features;

   return TRUE;
}



/* installs a new driver */
int got_card(DRIVER_INFO *info)
{
   static char *options[] =
   {
      "View implementation notes",
      "Configure",
      "Go Back",
      "Quit",
      NULL
   };

   int sel = 0;
   unsigned long features = 0;
   unsigned long orig_features = 0;

   strcpy(current_driver_name, info->driver->OemVendorName);
   strcpy(current_driver_copyright, info->driver->OemCopyright);

   if (info->config) {
      features = *((unsigned long *)((unsigned long)info->driver+info->config));
      orig_features = features;
   }

   if (!install_driver(info, features, orig_features))
      return FALSE;

   for(ever) {
      draw_box(60, 11);

      text_pos(16, screen_h/2-3);
      text_clamp(info->driver->OemVendorName, 48);
      text_pos(16, screen_h/2-2);
      text_str("has been installed onto your system.");

      sel = get_selection(options, sel, 4, screen_h/2, FALSE);

      switch (sel) {

	 case 0:
	    /* view notes */
	    text_viewer(info->notes, info->notes_size);
	    break;

	 case 1:
	    /* configure */
	    if (info->config) {
	       edit_config(&features, orig_features);
	       install_driver(info, features, orig_features);
	    }
	    else {
	       draw_box(60, 4);
	       text_pos(16, screen_h/2-1);
	       text_str("Sorry, this driver does not support the");
	       text_pos(16, screen_h/2);
	       text_str("FreeBE/AF configuration mechanism!");
	       input_pause();
	    }
	    break;

	 case 3:
	    /* quit */
	    return TRUE;

	 default:
	    /* back */
	    return FALSE;
      }
   }
}



/* allows the user to select a driver */
int choose_card()
{
   static int sel = 0;
   char *options[MAX_DRIVERS+1];
   int i, n;

   for (i=0; i<num_drivers; i++)
      options[i] = driver_info[i].name;

   options[i] = NULL;

   n = MIN(num_drivers, screen_h*4/7);

   draw_box(40, n+2);

   i = get_selection(options, sel, n, screen_h/2-n/2-1, FALSE);

   if (i >= 0) {
      sel = i;
      return got_card(&driver_info[sel]);
   }

   return FALSE;
}



/* displays the main selection menu */
void main_menu()
{
   static char *options[] =
   {
      "Autodetect graphics hardware",
      "Manually select a driver",
      "Remove FreeBE/AF",
      "Quit",
      NULL
   };

   char old_name[80];
   int sel = 0;
   int i;

   for(ever) {
      draw_box(40, 8);

      sel = get_selection(options, sel, 4, screen_h/2-3, FALSE);

      switch (sel) {

	 case 0:
	    /* autodetect */
	    for (i=0; i<num_drivers; i++) {
	       if ((!strstr(driver_info[i].name, "stub implementation")) &&
		   (driver_info[i].present) && (driver_info[i].accel)) {
		  if (got_card(&driver_info[i]))
		     return;
		  break;
	       }
	    }

	    if (i >= num_drivers) {
	       for (i=0; i<num_drivers; i++) {
		  if ((!strstr(driver_info[i].name, "stub implementation")) &&
		      (driver_info[i].present) && (!driver_info[i].accel)) {
		     if (got_card(&driver_info[i]))
			return;
		     break;
		  }
	       }

	       if (i >= num_drivers) {
		  draw_box(60, 3);
		  text_pos(16, screen_h/2);
		  text_str("Error: unable to detect any supported hardware.");
		  input_pause();
	       }
	    }
	    break;

	 case 1:
	    /* manual selection */
	    if (choose_card())
	       return;
	    break;

	 case 2:
	    /* uninstall */
	    if (strstr(current_driver_name, "FreeBE/AF")) {
	       remove(VBEAF_FILENAME);
	       strcpy(old_name, current_driver_name);
	       strcpy(current_driver_name, "{none}");
	       strcpy(current_driver_copyright, "");
	       draw_box(60, 4);
	       text_pos(16, screen_h/2-1);
	       text_clamp(old_name, 48);
	       text_pos(16, screen_h/2);
	       text_str("has been removed from your system.");
	       input_pause();
	    }
	    else {
	       draw_box(60, 4);
	       text_pos(16, screen_h/2-1);
	       text_str("Error removing driver:");
	       text_pos(16, screen_h/2);
	       text_str("No FreeBE/AF driver is currently installed!");
	       input_pause();
	    }
	    break;

	 default:
	    /* quit */
	    return;
      }
   }
}



/* main program */
int main()
{
   struct text_info info;

   if (read_driver_data() != 0) {
      printf("Fatal error: driver data not present!\n");
      return 1;
   }

   __djgpp_set_ctrl_c(0);
   setcbrk(0);

   gettextinfo(&info);
   screen_h = info.screenheight;
   _setcursortype(_NOCURSOR);

   mouse_init();

   if (check_current_driver() == 0)
      main_menu();

   clrscr();
   _setcursortype(_NORMALCURSOR);

   if (strcmp(current_driver_name, "{none}") == 0) {
      textattr(0x04);
      cputs("No VBE/AF driver is installed on your machine.");
   }
   else {
      textattr(0x07);
      cputs("Installed driver:\r\n\r\n");
      textattr(0x02);
      cputs(current_driver_name);
      cputs("\r\n");
      cputs(current_driver_copyright);
   }

   textattr(0x07);
   cputs("\r\n\r\n");

   return 0;
}

