/*' $Header:   P:/pvcs/misc/swttools/swatlog.c_v   1.0   14 Apr 1993 16:19:08   HENRY  $ */
/***
 *
 * SWATLOG.C
 *
 * Pass standard input up to SWAT error log
 *
 * If arguments are specified, they are made into a line which is
 * passed to the SWAT error log. - means read subsequent lines from
 * standard input.  The default (no arguments) is to read from standard
 * input.
 *
***/

#include <stdio.h>
#include <string.h>

char buff[1000];

char far *buffp = buff;

extern int far SWAT_PRESENT();

int main (int argc, char *argv[])
{
 int start=1;
 int readstdin = 1;

 if (!SWAT_PRESENT()) {
	printf ("386SWAT not present\n");
	exit (-1);
 }
 else {
	printf ("SWATLOG v0.10   Copyright (C) 1992 Qualitas Inc.  All rights reserved.\n");
 }

 buff[0] = '\0';
 if (argc > 1) {
	readstdin = 0;
	while (--argc) {
		if (!start) strcat (buff, " ");
		start = 0;
		++argv;
		if (!strcmp (*argv, "-")) {
			readstdin = 1;
			break;
		}
		strcat (buff, *argv);
	}

 }

 do {

    strcat (buff, "\n");
    _asm {

	push	ds		/* Save */

	_emit	0x66		/* Generate OSP */
	sub	si,si		/* Clear high word */
	lds	si,buffp	/* DS:ESI ==> message to put in log */
	mov	ax,0xDEF6	/* VCPI debugger symbol functions */
	mov	bl,6		/* Subfn 6: display string to error log */
	int	0x67		/* Call the debugger */

	pop	ds		/* Restore */

    }

 } while (readstdin && gets (buff));

 return (0);

}

