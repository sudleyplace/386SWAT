/*' $Header:   P:/pvcs/misc/swttools/swatcmd.c_v   1.1   14 Apr 1993 16:18:56   HENRY  $ */
/***
 *
 * SWATCMD.C
 *
 * Execute SWAT commands from the DOS prompt
 *
***/

#include <stdio.h>
#include <string.h>

char buff[1000];
char cmdbuff[256];

char far *buffp = buff;
char far *cmdbuffp = cmdbuff;

extern int far SWAT_PRESENT();

int main (int argc, char *argv[])
{
 int start=1;

 if (!SWAT_PRESENT()) {
	printf ("386SWAT not present\n");
	exit (-1);
 }
 else {
	printf ("SWATCMD v0.11   Copyright (C) 1992 Qualitas Inc.  All rights reserved.\n");
 }

 if (argc > 1) {
	cmdbuff[0] = '\0';
	while (--argc) {
		if (!start) strcat (cmdbuff, " ");
		start = 0;
		++argv;
		if (strlen (cmdbuff) + strlen (*argv) > 80) {
		  printf ("ERROR: Maximum command line length (80) exceeded.\n");
		  return (-1);
		}
		strcat (cmdbuff, *argv);
	}
	sprintf (buff, "Int 67 cmd:%s\n", cmdbuff);
 }

 _asm {

  push	ds		/* Save */

  _emit 0x66		/* Generate OSP */
  sub	si,si		/* Clear high word */
  lds	si,buffp	/* DS:ESI ==> message to put in log */
  mov	ax,0xDEF6	/* VCPI debugger symbol functions */
  mov	bl,6		/* Subfn 6: display ASCIIZ string to error log */
  int	0x67		/* Call the debugger */

  pop	 ds

  push	 ds

  _emit 0x66		/* Generate OSP */
  sub	si,si		/* Clear high word */
  lds	si,cmdbuffp	/* DS:ESI ==> SWAT command line */
  mov	ax,0xDEF6	/* VCPI debugger symbol functions */
  mov	bl,5		/* Subfn 5: pass ASCIIZ string as SWAT command line */
  int	0x67		/* Call the debugger */

  pop	ds

 }

 return (0);

}

