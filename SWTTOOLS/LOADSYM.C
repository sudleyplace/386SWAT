/****
 *' $Header:   P:/misc/swttools/loadsym.c_v   1.1   25 Nov 1991 10:18:34   HENRY  $
 *
 * loadsym.c
 *
 * sym32 format read functions
 *
 * Compiler assumptions: /J /AC (default char type is unsigned,
 *				 use compact model)
 *
 ****/

#include <stdio.h>
#include <malloc.h>
#include <io.h>
#include <fcntl.h>

#include "mapssf.h"

/************************* LOAD_SYM (char *path) *****************************/
void load_sym (char *path)
// Load specified SYM32 format file
{
 int fh;
 char *lserr;
 S386hdr hdr;
 S386grpp grpp;
 S386symp symp;
 rstruct rb;
 WORD firstgrp; 	// used to keep track of first group in file
 WORD gf1, gf2;
 WORD grpsize;		// size of group in bytes
 WORD *dirptr;		// directory offsets
 WORD count;		// count of symbols in group
 WORD readgrp;		// should we read this group?
 long fsize;		// use file size to calculate size of last group
 SSF  deflt;		// default values for group
 int done;		// are we done?
 long fdiff;		// difference between current offset and next group

 // get possible groupfilt values in gf1 and gf2
 gf1 = (groupfilt & 0xff00) >> 8;
 gf2 = (groupfilt & 0x00ff);

 if ((fh = open (path, O_RDONLY | O_BINARY)) != -1) {

	rstruct_init (&rb);

	lserr = "Unable to get size of";
	if ((fsize = lseek (fh, 0L, SEEK_END)) == -1)
	 goto load_symErr;
	if (lseek (fh, 0L, SEEK_SET) == -1)
	 goto load_symErr;

	lserr = "Unable to read header of";
	if (read (fh, &hdr, (int) (rb.startoff = (long) sizeof (hdr))) == -1)
	 goto load_symErr;

	lserr = "Bad header in";
	if (	hdr.modnamelen > 0x10 ||
		!hdr.modname[0])
	 goto load_symErr;

	strncpy (buffer, hdr.modname, hdr.modnamelen);
	buffer [hdr.modnamelen] = '\0';
	DBG (0, "Module %s contains %04x paragraphs\n", buffer, hdr.flen);

	lserr = "Out of heap reading";
	if (rstruct_alloc (&rb))
	 goto load_symErr;

	lserr = "Error reading ABS section of";
	if (	hdr.hdrsize != 2 ||
		hdr.numabs) {

	 if (hdr.numabs) {
		DBG (1, "%d ABS records found; first group at %04x0\n",
		 hdr.numabs, hdr.hdrsize);
		// reset file pointer
		if (lseek (fh, 0L, SEEK_SET) == -1)
		 goto load_symErr;
		// read from beginning of buffer
		rb.head = rb.buff;
		// get that bad boy into memory
		grpsize = (int) (hdr.hdrsize << 4);
		DBG (3, "ABS section is %u bytes\n", grpsize, 0);
		lserr = "Null ABS section in";
		if (!grpsize)
		 goto load_symErr;
		lserr = "ABS section too large in";
		if (grpsize > RSTRUCT_INITSIZE)
		 goto load_symErr;
		lserr = "Unable to read ABS section in";
		if ( read (fh, rb.head, grpsize - RSTRUCT_INITREAD) == -1)
		 goto load_symErr;
		rb.head = rb.buff + grpsize;

		// initialize directory pointer & loop through until we're done
		lserr = "Bad ABS symbol record in";
		count = hdr.numabs;
		for (dirptr = (WORD *) (rb.buff + hdr.absdir);
			count;
			count--, dirptr++) {
		 symp = (S386symp) (rb.buff + *dirptr);
		 strncpy (buffer, symp->symname, symp->symnamelen);
		 buffer [symp->symnamelen] = '\0';
		 DBG (3, "ABS %s = 0000|%08x\n", buffer, symp->val);

		 // pass to SWAT
		 add_ssf (symp->val,
			0,		// null selector
			SSF0_PM|SSF1_ABS,	// flag it as ABS
			0,		// no group #
			buffer);

		} // end of directory entries

	 } // hdr.numabs > 0

	 // go to the beginning of the first group
	 if (lseek (fh, ((long) hdr.hdrsize) << 4, SEEK_SET) == -1)
		goto load_symErr;
	} // header was more than 2 paragraphs or there were ABS records

	// get first group
	rb.startoff = ((long) (firstgrp = hdr.hdrsize)) << 4;
	rb.head = rb.buff;

	done = 0;
	do {

	 lserr = "Error reading group header in";
	 if (read (fh, rb.buff, RSTRUCT_INITREAD) == -1)
	  goto load_symErr;
	 rb.head = rb.buff + RSTRUCT_INITREAD;

	 // check for consistency of group header
	 lserr = "Bad group header in";
	 grpp = (S386grpp) rb.buff;
	 if (grpp->grpsig != S386_GRPSIG ||
		grpp->grpdir < 0x20	||
		grpp->grpdir > 0x7fff	||
		grpp->grptype > S386_MAXGROUP ||
		!grpp->count)
	  goto load_symErr;

	 // decide whether we want to read this group
	 readgrp = (gf1 == 0xff || gf1 == grpp->grptype) ||
		(gf2 == grpp->grptype) ? 1 : 0;

	 strncpy (buffer, grpp->grpname, grpp->grpnamelen);
	 buffer [grpp->grpnamelen] = '\0';
	 DBG (2-readgrp, "Group %s is type %d\n", buffer, grpp->grptype);

	 if (readgrp) {

	  // initialize defaults
	  deflt.segsel = defsegsel;
	  deflt.flags = SSF0_PM;		// default to protected mode
	  deflt.group = 0;

	  // change defaults if wsg record exists
	  if (!wsgcount || check_wsg (buffer, &deflt)) {

	   DBG (2, "Reading %04x symbols at offset %06lx\n",
		grpp->count, rb.startoff);

	   // read symbols -- start by getting entire group into memory
	   grpsize = (int) ((fdiff = (long) grpp->nextgrp << 4) - rb.startoff);
	   if (fdiff < rb.startoff) {
		done = 1;	// last group
		grpsize = (int) (fsize - rb.startoff);
	   } // fdiff < rb.startoff
	   DBG (3, "Group size is %u bytes; next group is at %x0 bytes\n",
		grpsize, grpp->nextgrp);
	   lserr = "Null group in";
	   if (!grpsize)
		goto load_symErr;
	   lserr = "Group too large in";
	   if (grpsize > RSTRUCT_INITSIZE)
		goto load_symErr;
	   lserr = "Unable to read symbols in";
	   if ( grpsize > RSTRUCT_INITREAD &&
		read (fh, rb.head, grpsize - RSTRUCT_INITREAD) == -1)
		goto load_symErr;
	   rb.head = rb.buff + grpsize;

	   // initialize directory pointer & loop through until we're done
	   lserr = "Bad symbol record in";
	   count = grpp->count;
	   for (dirptr = (WORD *) (rb.buff + grpp->grpdir);
		count;
		count--, dirptr++) {
	    symp = (S386symp) (rb.buff + *dirptr);
	    strncpy (buffer, symp->symname, symp->symnamelen);
	    buffer [symp->symnamelen] = '\0';
	    DBG (3, "\t%s = %04x", buffer, deflt.segsel);
	    DBG (3, "%c%08lx\n", deflt.flags & SSF0_VM ? ':' : '|', symp->val);

	    // pass to SWAT
	    add_ssf (symp->val,
		deflt.segsel,
		deflt.flags,
		deflt.group,
		buffer);

	   } // end of directory entries

	  } // no .wsg file specified or group name found in file

	 } // groupfilt unspecified or matching group type

	 // if nextgrp is > current seek offset, read in the next
	 if (!done && (fdiff = ((long) grpp->nextgrp) << 4) > rb.startoff) {
	  rb.head = rb.buff;		// start over from beginning;
					// we're done with this group
	  rb.startoff = fdiff;		// get new offset in bytes
	  lserr = "Unable to seek on";
	  if (lseek (fh, rb.startoff, SEEK_SET) == -1)
		goto load_symErr;
	 } // nextgrp > current lseek offset
	 else
		done = 1;	// if !done, no harm done; if fdiff < next,
				// get out.

	} while (!done);

	// done
	DBG (2, "End of groups -- offset is %lu, next is %lu\n",
		rb.startoff, ((long) grpp->nextgrp) << 4);
	goto load_symOK;

 load_symErr:
	fprintf (stderr, "%s %s\n", lserr, path);

 load_symOK:
	rstruct_free (&rb);
	close (fh);

 } // opened OK
 else
	fprintf (stderr, "Unable to open %s\n", path);

 return;

} // load_sym ()

