/*****
 *' $Header:   P:/pvcs/misc/swttools/mapssf.c_v   1.14   28 Mar 1996 12:14:04   HENRY  $
 *
 *	MAPSSF.C - Create SWAT Symbol Format table from .MAP file or Windows .SYM
 *	file.
 *
 *	Copyright (C) 1991-96 Qualitas, Inc.  All rights reserved.
 *
 * Compiler assumptions: /J /AC (default char type is unsigned,
 *				 use compact model)
 *
 *****/

#include <stdio.h>
#include <fcntl.h>
#include <dos.h>
#include <ctype.h>
#include <string.h>
#include <memory.h>
#include <malloc.h>
#include <stdlib.h>
#include <io.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "getopt.h"
extern char *optarg;
extern int optind;
#define MAPSSF	1	// skip externs in header file
#include "mapssf.h"
#include "swat_api.pro"

#include "loadsym.pro"
#include "loadmap.pro"
#ifndef PROTO
#include "mapssf.pro"
#endif

// global constants & macros
#define PROGNAME	"MapSSF"
#define COPYRIGHT	PROGNAME " Version 1.17 -- MAP/SYM to SSF Converter\n\
Copyright (C) 1991-96 Qualitas, Inc.  All rights reserved.\n"
#define MAXTABLE	0xffe0

// globals -- flags, etc.
int debuglvl = 0;
WORD	groupfilt = 0xffff; // group to allow
int append = 1; 	// append or overwrite SWAT table
int rawappend = 0;		// Use raw append function (allow duplicates)
int defsegsel = -1; 	// default segment/selector
int forcesym = 0;		// consider all files with extension
				// other than .MAP to be .SYM
int ignlines = 0;		// ignore line number info in .MAP file
int defaultmode = SSF0_VM;	// default mode if no selector/mode or .wsg
				// file specified
int segmentmode = SEG_SET;	// if defsegsel is defined, set segments to
				// specified value
int byname = 1; 	// Set to 1 if symbols should be passed
				// to SWAT sorted by name (default is
				// by value)
int offwrap = 0;		// Set to 1 if by value (byname==0)
				// and offset wrap enabled
int map32 = 0;		// Set to 1 if a LINK32 map file (VXD)
int win32 = 0;		// Set to 1 if Win32 linker output
WORD	tablesize = MAXTABLE;	// size for temporary symbol tables
WORD	tableleft = MAXTABLE;	// amount remaining in table
SSFp	ssf = NULL; 	// SSF base pointer
SSFp	SSFtail = NULL; 	// SSF pointer used for appends
int SSFx = 0;		// file handle used for diagnostic writes
WORD	SSFcnt = 0; 	// used to keep track of # of unflushed entries
WSGp	wsg = NULL; 	// pointer to array of WSG *records.
WORD	wsgcount;		// number of WSG *records in *wsg
WORD	wDefGroup;		// Default group (for records not covered in WSG)
char	buffer[BUFSIZE+1];	// a VERY temporary string buffer
long	ssftotal = 0;		// running total of ssf file records
long	ssfrecadded = 0;	// total number of records added
long	ssfadded = 0;		// total number of bytes added
long	ssfdeficit = 0; 	// number of bytes to increase SYMSIZE by
char	path[81],		// shared by get_wsg and expand_fspec()
	drive[4],		// for breaking up filenames with
	dir[66],		// _splitpath()
	name[9],
	ext[5];

char	*defext[] = {		// default extensions to try when none specified
	".sym",
	".map"
	};
#define MAXDEFEXT	(sizeof(defext)/sizeof(char *))

char	*binext[] = {		// extensions to try for matching binaries
	".exe",
	".com",
	".sys",
	".lod"
	};
#define MAXBINEXT	(sizeof(binext)/sizeof(char *))

// data for creation of .ssf file
typedef struct Ssff_str {
	BYTE	ssff_sig[4];	// Signature
	WORD	ssff_ver;	// File version
	DWORD	ssff_count; // Number of records within file
	WORD	ssff_flags; // Processing flags
	DWORD	ssff_data;	// File pointer to start of symbol data
} SSF_STR, *SSF_PTR;

#define SSFF_SIG	{'S','S','f','$'} // signature to identify SSF file
#define SSFF_VER	0x0011	// packed BCD file format version
				// (*NOT* in synch with program version #)

#define SSFFL_FLUSH 0x8000	// Flush table before adding
#define SSFFL_RAW	0x4000	// Allow dupes

SSF_STR ssf_hdr = {SSFF_SIG,SSFF_VER,0,0,sizeof(SSF_STR)};

// error codes
#define WSG_OPENFAIL	-1	// returned by get_wsg() if open() fails
#define WSG_MALLOCFAIL	-2	//		"            if malloc() fails
#define WSG_EMPTY	-3	//		"            if file empty

#define MAXTDIFF	6	// maximum difference in seconds*2

// option string passed to getopt ()
#define VALOPTS 	"3de:g:h?lops:t:v:w:x:y"

/*************************** ERR (char *msg, int showsynt) ******************/
// display msg & syntax (if showsynt != 0), then exit(-1)
void err (char *msg, int showsynt)
{
 if (showsynt) {
	fprintf (stderr, "%s\n", msg);
	fprintf (stderr, "Syntax-\n\
" PROGNAME " [options] fspec1 [fspec2 [...]]\n\
All options are preceded with - or /:\n\
  -3\t\tRecognize Win32 linker .MAP file\n\
  -d\t\tAllow duplicate symbols\n\
  -e#\t\tDefault group for symbols not covered by .WSG file\n\
  -g#[,#]\tRestrict symbol group types to specified #'s\n\
  -h\t\tDisplay this message\n\
  -l\t\tIgnore line number information in .MAP file\n\
  -o\t\tOverwrite existing symbol table (default is append)\n\
  -p\t\tDefault to PM for segments not covered by .WSG file\n\
  -sxxxxm\tSet selector to xxxx hex, where m is\n\
\t\tv for V86/real mode\n\
\t\tv+ for V86/real mode, add value to segment,\n\
\t\tp for protected mode\n\
  -tfname\tEcho SWAT tables to file fname\n\
  -v\t\tSort symbols by value (default is by name)\n\
  -v+\t\tSort symbols by value, enable offset wrap\n\
  -wfname[.wsg]\tRead Windows Symbol Group file fname.wsg\n\
  -x#\t\tSet debugging level to # (default is 0 -- no messages)\n\
  -y\t\tDefault to recognizing files as SYM32 format\n\
");
 } // showsynt
 else
	fprintf (stderr, PROGNAME ": %s\n", msg);
 if (wsg != NULL)
	free (wsg);
 exit (-1);
} // err ()

///////////////////// PUBLIC functions //////////////////////////////

/************************ ADD_SSF (offset, segsel, flags, group, symname) ***/
// add an entry to SSFtail & if necessary, flush contents up to SWAT
void add_ssf (	DWORD offset,		// symbol's offset value
		WORD segsel,		// symbol's segment/selector value
		WORD flags, 	// symbol flags
		WORD group, 	// symbol's group ID number
		char *symname		// name of symbol
		)
{
 WORD oursize, symsize;

 // calculate size needed - SSF includes 1 byte for string name because
 // C won't allow allow a field in a structure with zero length (see SSF_struct)
 oursize = sizeof (SSF) + (symsize = strlen (symname)) - 1;

 // if remaining space in our internal buffer is not sufficient,
 // call API to send it to SWAT and reset to the beginning of the buffer
 if (oursize > tableleft)
	reset_ssf ();

 // always room for wierdness
 if (oursize > tableleft) {
	strcpy (buffer, "Invalid symbol record ");
	strncat (buffer, symname, BUFSIZE-strlen(buffer));
	buffer [BUFSIZE] = '\0';
	err (buffer, 0);
 }

 // add entry to table
 SSFtail->offset = offset;
 SSFtail->segsel = segsel;
 SSFtail->flags = flags;
 SSFtail->group = group;
 SSFtail->symlen = (BYTE) symsize;
 memcpy (SSFtail->symname, symname, symsize);

 // update write pointer & bytes remaining
 SSFtail = (SSFp) (((char *) SSFtail) + oursize);
 tableleft -= oursize;
 SSFcnt++;

} // add_ssf ()

/************************ REC2BYTES (WORD rcount, SSFp ssflcl) ***************/
// determine number of bytes occupied by SSFcnt records in list ssf
long rec2bytes (WORD rcount, SSFp ssflcl)
{
 WORD	recsize;
 long	total;

 for (total = 0L; rcount; rcount--) {
  // SSF already includes 1 byte of symname
  total += (recsize = sizeof(SSF) - sizeof(BYTE) + ssflcl->symlen);
  ssflcl = (SSFp) ((char *) ssflcl + recsize);	// point to next record
 } // for ()

 return (total);

} // rec2bytes ()

/************************ RESET_SSF () **************************************/
// send contents of ssf up to SWAT & reset SSFtail, tableleft
void reset_ssf ()
{
 long numtoadd, numadded;
 WORD res, SSFbefore;

 numtoadd = tablesize - tableleft;
				// number of bytes we're trying to add

 if (tableleft < tablesize) {
  // if diagnostic file is open, echo it out
  if (SSFx) {
	DBG (1, "Adding %d symbols to file\n", SSFcnt, 0);
	ssftotal += SSFcnt;
	write (SSFx, ssf, tablesize - tableleft);
  } // writing to file
  else {

   // hand it off to SWAT
   if (debuglvl == 0) fprintf (stderr, "\x0f\x08");
   DBG (1, "Adding %d symbols (%u bytes) to SWAT\n",
	SSFcnt, numtoadd + SSFcnt * SIZEDIFF);
   SSFbefore = SSFcnt;
   res = SWAT_ADDSYM (&SSFcnt, ssf, rawappend); // add symbols
   if (debuglvl == 0) fputc ('.', stderr);
   numadded = rec2bytes (SSFcnt, ssf);		// bytes added - SSFcnt is recs
   ssfrecadded += SSFcnt;			// tally number added
   ssfadded += numadded;			// tally bytes added
   DBG (1, "\t%d symbols (%lu bytes) added\n", SSFcnt, numadded + SSFcnt * SIZEDIFF);

   switch (res) {
	case 0x88:		// keep track of the number of bytes NOT
				// added to the symbol table and keep on truckin
		if (debuglvl >= ssfdeficit ? 1 : 0)
		 fprintf (stderr,
			"SWAT table overflow: %lu records (%lu bytes) added\n",
			ssfrecadded, ssfadded + ssfrecadded * SIZEDIFF);
		ssfdeficit += (numtoadd - numadded +
				(SSFbefore - SSFcnt) * SIZEDIFF);
	case 0:
		break;
	case 0x8f: err ("SWAT not present or version loaded does not support symbols", 0);
		break;
	default: err ("Unknown SWAT API error", 0);
		break;
   } // switch ()

  } // not writing to diagnostic file

  SSFcnt = 0;

 } // there was something to send

 // reset SSFtail for subsequent writes
 SSFtail = ssf;
 tableleft = tablesize;

}

/********************** RSTRUCT_INIT (rstructptr rbp) ***********************/
// initialize read structure - must already be allocated
void rstruct_init (rstructptr rbp)
{
 rbp->buff = NULL;
 rbp->buffsize = 0;
} // rstruct_init ()

/********************** RSTRUCT_ALLOC (rstructptr rbp) *********************/
// initial allocation for read structure - structure itself must already
// be allocated
int rstruct_alloc (rstructptr rbp)
{
 if ((rbp->buff = malloc (RSTRUCT_INITSIZE)) == NULL)
	return (-1);
 rbp->buffsize = RSTRUCT_INITSIZE;
 rbp->head = rbp->buff;
 return (0);
} // rstruct_alloc ()

/********************** RSTRUCT_FREE (rstructptr rbp) **********************/
// free allocation within read structure
void rstruct_free (rstructptr rbp)
{
 if (rbp->buffsize && rbp->buff)
	free (rbp->buff);
 rbp->buffsize = 0;
} // rstruct_free ()

/********************** CHECK_WSG (data) ****************/
// Checks in wsg[] for matching group/segment; if found, makes
// appropriate changes to *data.  Return 1 if found, 0 otherwise.
int check_wsg (SSFp data)
{
 int i,j;
 DWORD addr20;

 // Set default group
 data->group = wDefGroup;

 // Clear VM & PM bits and set default mode
 data->flags &= ~SSF0_MSK;
 data->flags |= defaultmode; // SSF0_PM or SSF0_VM

 // If Win32, use selector 0 as we already have the linear address
 //if (win32) data->segsel = 0;

 if (!wsgcount)
	return (0);

 // Create a normalized form of the address.  This is ignored
 // for flat model map files.
 addr20 = ((DWORD) data->segsel << 4) + (DWORD) data->offset;

#define PASS1 (j==0)
#define PASS2 (j==1)

 // Run through looking for specific segments first
 // On the second pass, we stop at the first group that we could
 // belong to (they are already sorted descendingly) unless it's
 // a LINK32 map file, in which case we must have an exact segment
 // value match.
 for (j=0; j<2; j++)

  for (i=0; i<wsgcount; i++)

   if ( (PASS2 &&
	 !wsg[i].segname &&
	 ((map32 && data->segsel == wsg[i].gbegin) ||
	  (!map32 && addr20 >= wsg[i].gbegin) ||
	  (data->segsel == wsg[i].groupnum && !strcmp (wsg[i].groupname,"*"))
	 )
	) ||
	(PASS1 &&
	 wsg[i].segname &&
	 wsg[i].segbegin <= addr20 &&
	 addr20 <= wsg[i].segend
	)
	   ) {

	DBG (2, "Group match \"%s\" in wsg[%d]\n", wsg[i].groupname, i);
	if (wsg[i].segname)
	 DBG (2, "Segment match \"%s\" %lu\n", wsg[i].segname, addr20);

	// blast groupnum in
	data->group = wsg[i].groupnum;

	// Set appropriate mode bit; VM & PM bits have already been cleared.

	switch (wsg[i].modeid) {

	 case 'P':      // Protected mode
		data->flags &= ~SSF0_MSK;	// Clear PM & VM bits
		data->flags |= SSF0_PM;
		break;

	 case 'V':      // Virtual mode
		data->flags &= ~SSF0_MSK;	// Clear PM & VM bits
		data->flags |= SSF0_VM;
		break;

	 case 'D':      // Delete altogether
		data->flags |= SSF2_DEL;
		break;

	} // End switch ()

	// Set the offset to addr20 - segment/group start in bytes
	// and blast segment/selector in if keepseg == 0
	DBG (2, "Before: %04x:%08lx\t", data->segsel, data->offset);
	if (!wsg[i].keepseg)	data->segsel = wsg[i].selector;
	if (data->flags & SSF2_DEL) {
		DBG (2, "Deleted.\n", 0, 0);
	}
	else
		DBG (2, "After: %04x:%08lx\n", data->segsel, data->offset);

	// return and indicate a hit
	return (1);

  } // found groupname

 return (0);

} // check_wsg ()

//****************** RESOLVE_WSG () **************************************
// Resolves segment or group references in WSG data structure.
// If group, segend is ignored.
// Note that for groups, segbegin may be a 16-bit zero-extended value
// if we are processing a LINK32 map file.
void resolve_wsg (int group, char *segname, DWORD segbegin, DWORD segend)
{
 int i;

 for (i = 0; i < wsgcount; i++)

  if (group) {

   if (!strnicmp (wsg[i].groupname, segname, S386_GNMAX)) {
	wsg[i].gbegin = segbegin;
	// Keep going... there may be multiple group!segment sets
   } // group matched

  } // group

  else {

   if (wsg[i].segname && !strnicmp (wsg[i].segname, segname, S386_GNMAX)) {
	wsg[i].segbegin = segbegin;
	wsg[i].segend = segend;
	return;
   } // found a match

  } // segment

  sort_wsg ();	// Keep all origins sorted descendingly

} // resolve_wsg ()

//********************** CLEAR_WSG () ***********************************
// Clears all segment and group references in WSG data structure
void clear_wsg (void)
{
 int i;

 for (i=0; i < wsgcount; i++)

  if (wsg[i].segname) {

	wsg[i].gbegin = 0L;
	wsg[i].segbegin = 0L;
	wsg[i].segend = 0L;

  } // Segment name exists

} // clear_wsg ()

/////////////////// PRIVATE functions /////////////////////////////

/****************************** SORT_WSG () ***************************/
// Sort wsg structure group origins descendingly using bubble sort
void sort_wsg (void)
{
 int i,done;
 WSG temp;

 for (done=0; !done; ) {

	done = 1;

	for (i=1; i < wsgcount; i++) {

		if (wsg[i-1].gbegin < wsg[i].gbegin) { // Out of order - swap 'em

		temp = wsg[i-1];
		wsg[i-1] = wsg[i];
		wsg[i] = temp;
		done = 0;

		} // Element pair was out of order

	 } // for (i...)

 } // for (!done)

} // sort_wsg ()

/************************* GET_WSG (char *fname) ***************************/
// read Windows Symbol Group file into memory, determine allocation for
// wsg global array pointer & malloc() it, then parse
int get_wsg (char *fname)
{
 int	fh, rval, numlines, ifsize, linelen;
 long	fsize;
 char	*tbuff, 	// temporary buffer for reading file into memory
	*line, *nline;
 WORD	grpnum; 	// group number
 char	grpmode;	// modeid for group (V for VM/RM, P for PM)
 WORD	grpsel; 	// group selector
 char	grpstr[20]; // string containing segment/selector
 char	*grpname;	// group name
 char	*segment_name;	// Segment name (if specified)

 // if there is no '.', tack on .wsg
 _splitpath (fname, drive, dir, name, ext);
 strcpy (buffer, fname);
 if (strchr (ext, '.') == NULL)
  strcat (buffer, ".wsg");

 if ((fh = open (buffer, O_RDONLY|O_BINARY)) == -1)
	return (WSG_OPENFAIL);

 // get file size and read whole mess into memory
 rval = WSG_OPENFAIL;
 if (	(fsize = lseek (fh, 0L, SEEK_END)) == -1 ||
	lseek (fh, 0L, SEEK_SET) == -1)
	goto get_wsg_exit;
 if (fsize >= _HEAP_MAXREQ)
	goto get_wsg_exit;
 rval = WSG_MALLOCFAIL;
 if ((tbuff = malloc ((ifsize = (int) fsize) + 1)) == NULL)
	goto get_wsg_exit;
 rval = WSG_OPENFAIL;
 if (read (fh, tbuff, ifsize) == -1)
	goto get_wsg_mexit;

 // determine number of records in file
 tbuff [ifsize] = '\0';
 for (	numlines = fsize ? 1 : 0, line = tbuff;
	(line = strchr (line, '\n')) != NULL;
	numlines++) {
	while (strchr ("\n\r\t; ", *line) != NULL)
	 if (*line == ';')
	  line = strchr (line, '\n');   // skip comments
	 else
	  line++;			// skip CR, LF, tab, space
 } // for (lines in file )

 // If there is an existing WSG structure, release it
 if (wsg) {
	free (wsg);
	wsg = NULL;
 }

 // allocate wsg
 rval = WSG_MALLOCFAIL;
 if ((wsg = calloc (sizeof (WSG), numlines)) == NULL)
	goto get_wsg_mexit;

 // make grpname point into buffer after maximum line length + 1 for \0
 grpname = buffer + WSG_LINEMAX + 1;

 // now we're set to parse file.  numlines is the limit, and we must
 // set wsgcount to the number of records added.
 for (	line = tbuff, wsgcount = 0;
	wsgcount < numlines &&
		line != NULL &&
		(int) (line - tbuff) < ifsize;
	line = strchr (line, '\n')) {

	// skip CR, LF, tab, space
	while (*line && strchr ("\r\n\t ", *line))
	 line++;

	// get line into buffer
	if ((nline = strchr (line, '\n')) != NULL)
	 linelen = (int) (nline - line);
	else
	 linelen = WSG_LINEMAX;
	if (linelen > WSG_LINEMAX)
	 linelen = WSG_LINEMAX;
	strncpy (buffer, line, linelen);
	buffer [linelen] = '\0';

	// parse elements
	grpnum = grpsel = 0;
	grpmode = ' ';
	*grpname = '\0';
	sscanf (buffer, "%x %c %19s %s", &grpnum, &grpmode, grpstr, grpname);
	grpstr[19] = '\0';

	if (strchr (";#\r\n\x1a", *line) == NULL)   // not a comment or blank
	 // determine if it's valid
	 if (	strchr ("VPD", grpmode = toupper (grpmode)) != NULL &&
		*grpname) {

	  sscanf (grpstr, "%x", &grpsel);
	  wsg [wsgcount].groupnum = grpnum;
	  wsg [wsgcount].modeid = grpmode;
	  wsg [wsgcount].selector = grpsel;
	  if (grpmode == 'V' && !strcmp (grpstr, "*")) {
		wsg [wsgcount].keepseg = 1;
	  }
	  else	wsg [wsgcount].keepseg = 0;

	  segment_name = strchr (grpname, '!'); // Search for segment name delim
	  if (segment_name) {			// Process segment name
		*segment_name++ = '\0';         // Terminate group name
		segment_name[S386_GNMAX] = '\0'; // Truncate
		wsg [wsgcount] . segname = strdup (segment_name);
	  } // segment specified
	  else					// No segment name specified
		wsg [wsgcount] . segname = segment_name;

	  // note that since the groupname CAN be S386_GNMAX characters
	  // long, we must always use strncmp () when comparing it
	  strncpy (wsg [wsgcount] . groupname, grpname, S386_GNMAX);
	  // bump wsgcount
	  wsgcount++;

	 } // add record
	 else {
	  DBG (0, "Invalid wsg record \"%s\" ignored while reading %s.\n",
		buffer, fname);
	 } // invalid wsg record
	else
		;	// ignore it, it's a comment
  } // for () / if line not empty

 // indicate success
 if (wsgcount) {
  rval = 0;
  DBG (1, "Added %d wsg records from file %s.\n", wsgcount, fname);
 }
 else
  rval = WSG_EMPTY;

get_wsg_mexit:
 free (tbuff);

get_wsg_exit:
 close (fh);
 return (rval);

} // get_wsg()

/****************************** TIME_STR (long ltime) *************************/
// Display a time value in seconds as days, hours, minutes, and seconds
static char time_strbuff[50];
char *time_str (long ltime)
{
 long days,hours,minutes,seconds;
 char *idstr, *begin;

 days = ltime / (24 * 60 * 60);
 ltime -= days * (24 * 60 * 60);

 hours = ltime / (60 * 60);
 ltime -= hours * (60 * 60);

 minutes = ltime / 60;

 seconds = ltime % 60;

 begin = time_strbuff;
 sprintf (begin, "%03lu days, %02lu:%02lu:%02lu ",
		days, hours, minutes, seconds);

 idstr = begin + strlen (begin);
 strcpy (idstr, "hours");

 if (days == 0L) {
  begin = begin + 10;
  if (hours == 0L) {
   begin = begin + 3;
   strcpy (idstr, "minutes");
   if (minutes == 0L) {
	begin = begin + 3;
	strcpy (idstr, "seconds");
   } // no minutes
  } // no hours
 } // no days

 return (begin);

} // time_str ()

/****************************** EXPAND_FSPEC (char *fname) ******************/
// expand fname and process all specified files
void expand_fspec (char *fname)
{
 int	dosret, symfmt = 0, mapfmt = 0, thisid;
 int	i;
 int	timediff;
 struct find_t	find, bfind;
 char	*_path, *_ext;

 // if fname contains no '.' and is not a wildcard (no ? or *)
 // and does not exist, try tacking on extensions until we get a hit
 _splitpath (fname, drive, dir, name, ext);
 strcpy (buffer, fname);
 if (strpbrk (ext, ".?*") == NULL && strpbrk (name, "?*") == NULL) {
  for (i=0; i<MAXDEFEXT && access (buffer, 0); i++)
	sprintf (buffer, "%s%s", fname, defext[i]);
  if (access (buffer, 0))
	strcpy (buffer, fname); // if after all that we failed, at least
				// let's not say that we didn't find what
				// the user asked for.
 } // not a wildcard

 // get drive:\directory\ component of name
 _splitpath (buffer, drive, dir, name, ext);
 sprintf (path, "%s%s", drive, dir);

 // assume SYM32 format if extension is .SYM
 if (!stricmp (ext, ".sym"))
	symfmt++;

 // if extension is .map, don't recognize any files as sym format
 if (!stricmp (ext, ".map"))
	mapfmt++;

 // get pointer to last character of path
 _path = path + strlen (path);

 // if no dir specified, we don't need a trailing backslash;
 // otherwise, ensure last character's a backslash
 if (strlen (dir) && *(_path-1) != '\\') {
	*(_path++) = '\\';
	*_path = '\0';
 }

 if (dosret = _dos_findfirst (buffer, 0x3f^(_A_SUBDIR|_A_VOLID), &find)) {
	DBG (0, "No files match \"%s\"\n", buffer, 0);
	return;
 }

 i = 0; 			// necessary because of MSC 6.0A bug

 do {

  strcpy (_path, find.name);	// tack fname portion onto drive:dirname
  strlwr (path);		// make it all lower case

  thisid = 0;			// default to .MAP format
  if (symfmt)			// .SYM file
	thisid++;
  else
  if (	(!mapfmt && !strstr (_path, ".map")) &&
	(!strstr (_path, ".sym") || forcesym))  // is this one a .SYM?
	thisid++;

  DBG (1, "Processing \"%s\" (%s format)\n", path, thisid ? "SYM32" : "MAP");
  // look for an .exe, .com, .sys, or .lod file with the same path/name

  strcpy (buffer, path);	// copy drive:\path\basename
				// get a location we can blast .ext into
  _ext = strrchr (buffer, '.'); // Try to find start of extension
  if (	_ext == NULL || 			// No extension, or
	_ext < strrchr (buffer, '\\') ||        // . is part of directory name
	_ext < strrchr (buffer, '/'))
		_ext = buffer + strlen (buffer);
  i = 0;
  do {
   strcpy (_ext, binext [i]);
   DBG (1, "access (%s, 0) = %d\n", buffer, access (buffer, 0));
  } while (++i < MAXBINEXT && access (buffer, 0));

  if (!access (buffer, 0)) {
	// compare time/date stamps - if binary is newer, complain
	if (_dos_findfirst (buffer, ~(_A_SUBDIR|_A_VOLID), &bfind)) {
	 DBG (0, "Warning: unable to open binary %s matching %s\n",
		buffer, path);
	} // _dos_findfirst() failed
	else {
	 DBG (1, "Time date for %-20s Time date for %-20s\n", buffer, path);
	 DBG (1, "%04x %04x                          ", bfind.wr_time,
				bfind.wr_date);
	 DBG (1, "%04x %04x\n", find.wr_time, find.wr_date);
	 if (	bfind.wr_date > find.wr_date ||
		(bfind.wr_date == find.wr_date &&
		 (timediff = bfind.wr_time - find.wr_time) > MAXTDIFF)	) {
	  DBG (0, "\x7Warning: binary %s is newer than %s",
		buffer, path);
	  DBG (0, bfind.wr_date == find.wr_date ? " by %s.\n" : "\n",
		time_str (timediff*2L), 0);
	 } // dates differ or time difference > MAXTDIFF
	} // got time/date stamps
  } // binary exists
  else
	DBG (1, "Unable to find matching binary for %s\n", path, 0);

  if (thisid)
	load_sym (path);
  else
	load_map (path);

 } while (!_dos_findnext (&find));

} // expand_fspec ()

/*************************** MAIN (argc, argv) *******************************/
int main (int argc, char *argv[])
{
 int i, gf1, gf2;
 char modetmp, modetm2;

 fprintf (stderr, COPYRIGHT);

 // allocate memory for symbol table
 if ((ssf = SSFtail = (SSFp) malloc (tableleft = tablesize)) == NULL)
	err ("Unable to allocate low memory for symbol table", 0);

 while ((i = getopt (argc, argv, VALOPTS)) != EOF)
REPARSE_ARGS:
  switch (i) {

   case '3':
	// Recognize Win32 map file
	win32 = 1;
	defaultmode = SSF0_PM;
	byname = 0;
	break;

   case 'd':
	// Allow duplicates -- use raw symbol append
	rawappend++;
	ssf_hdr.ssff_flags |= SSFFL_RAW;
	break;

   case 'e':
	// Specify default group
	wDefGroup = atoi( optarg );
	break;

   case 'g':
	// handle comma-separated args
	gf1 = gf2 = 0xff;

	if (!strchr (optarg, ','))
	 gf1 = atoi (optarg);
	else
	 sscanf (optarg, "%d,%d", &gf1, &gf2);

	if (groupfilt & 0x00ff == 0x00ff)
	 groupfilt = (gf2 << 8) | gf1;
	else
	 groupfilt |= (gf1 << 8);

	break;


   case 'h':
   case '?':
	// Display help
	err ("", 1);
	break;


   case 'l':
	ignlines++;
	break;


   case 'o':
	append = 0;
	ssf_hdr.ssff_flags |= SSFFL_FLUSH;
	break;


   case 'p':
	defaultmode = SSF0_PM;
	break;


   case 's':
	// get selector value and default mode
	modetm2 = ' ';
	sscanf (optarg, "%x%c%c", &defsegsel, &modetmp, &modetm2);
	modetmp = tolower (modetmp);

	if (!strchr ("vp", modetmp))
	 err ("Invalid mode specifier", 1);
	else
	 if (modetm2 != ' ' && modetm2 != '+')
	  err ("Invalid segment mode modifier", 1);
	else {
	 defaultmode = modetmp == 'p' ? SSF0_PM : SSF0_VM;
	 if (modetm2 == '+')
		segmentmode = SEG_ADD;
	 else
		segmentmode = SEG_SET;
	} // valid mode specifier

	break;


   case 't':
	strcpy (path, optarg);
	_splitpath (path, drive, dir, name, ext);

	if (!strlen (ext))		// If no extension specified...
		strcat (path, ".SSF");

	if ((SSFx = open (path, O_RDWR|O_CREAT|O_BINARY|O_TRUNC, S_IREAD|S_IWRITE)) == -1)
	 err ("Unable to create output file", 0);
	else {	// create header to position write pointer properly
	 if (	write (SSFx, &ssf_hdr, sizeof (ssf_hdr)) == -1)
	  err ("Unable to write header to output file", 0);
	} // opened SSFx
	break;


   case 'v':
	byname = 0;
	if (optarg && !strcmp (optarg, "+")) // Check for offset wrap enable
		offwrap = 1;
	else if (strchr ("/-", optarg[0]) && (i=optarg[1])) {
		// UGH - major kluge.  -v -wfname.wsg creates a small
		// problem; getopt has eaten "-wfname.wsg" as an argument
		// to -v.  We want to throw it back...
		strcpy (optarg, optarg+2);
		goto REPARSE_ARGS;
	}
	break;


   case 'w':
	DBG (0, "Loading WSG file %s\n", optarg, 0);

	switch (get_wsg (optarg)) {

	 case 0:
		break;

	 case WSG_MALLOCFAIL:
		err ("Unable to allocate memory for wsg table", 0);

	 case WSG_OPENFAIL:
		err ("Unable to open wsg file", 0);

	 case WSG_EMPTY:
		err ("Specified wsg file was empty", 0);

	 default:
		err ("Undefined error reading wsg file", 0);

	} // switch (get_wsg ())
	break;


   case 'x':
	debuglvl = atoi (optarg);
	break;


   case 'y':
	forcesym++;
	break;


   default:
	fprintf (stderr, "Unknown option -%c\n", i);
	break;


  } // switch (i)

 DBG (1, "Debug level is %d\n", debuglvl, 0);
 DBG (1, "Group filters are %u,%u (255=unspecified)\n",
	groupfilt & 0x00ff, (groupfilt & 0xff00) >> 8);
 DBG (1, "Selector value is %04x%s\n", defsegsel,
	defsegsel == -1 ? " (unspecified)" : "h");
 DBG (1, "Default selector mode is %s\n", defaultmode & SSF0_VM ? "VM" : "PM",
		0);
 DBG (1, "Symbol values will %s existing SWAT symbol tables\n",
	append ? "be appended to" : "overwrite", 0);
 DBG (1, "Line number info will %sbe included if found in .MAP files\n",
	ignlines ? "NOT " : "", 0);

 if (optind >= argc)
	err ("No file(s) specified.", 1);

 if (!SSFx && !SWAT_PRESENT ())
	err ("Cannot load symbols without 386SWAT present", 0);

 // If -o was specified and we're not writing to a file, make sure we
 // start at the beginning of SWAT's symbol space, overwriting
 // whatever's there.
 if (!append && !SSFx) {
	DBG (1, "Calling SWAT_FLUSHTAB; table will be overwritten\n", 0, 0);
	if (SWAT_FLUSHTAB ())
	 err ("Flush SWAT table failed", 0);     // overwrite existing table
 } // overwrite mode

 // expand and process arguments
 for (i = optind; i < argc; i++)

	if (strchr ("-/", argv[i][0]) && tolower (argv[i][1]) == 'w') {

	char *temp;

	temp = (char *) (argv[i] + 2);	// Skip past '-w'

	if (!(*temp)) { 	// Intervening space

		if (++i < argc) {

		temp = argv[i];

		 } else {

		err ("No argument for additional -w", 1);

		 }

	 } // -w and wsg filename separated by space

	DBG (0, "Loading WSG file %s\n", temp, 0);
	if (get_wsg (temp))
		err ("Unable to read additional WSG file", 1);

	} else {

	DBG (0, "Processing %s\n", argv[i], 0);
	expand_fspec (argv [i]);

	} // Argument was not a switch

 // if we have any remaining symbols buffered, send 'em to SWAT
 reset_ssf ();

 // release wsg
 free (wsg);

 // release ssf
 free (ssf);

 // close SSFx if open
 if (SSFx) {
  if (lseek (SSFx, 0L, SEEK_SET) == -1L)
	err ("Unable to seek on output file", 0);
  ssf_hdr.ssff_count = ssftotal;
  if (write (SSFx, &ssf_hdr, sizeof(ssf_hdr)) == -1)
	err ("Unable to write to output file", 0);
  close (SSFx);
 }
 else {
  DBG (0, "\n%lu symbol records (%lu bytes) passed to SWAT.\n",
	ssfrecadded, ssfadded + ssfrecadded * SIZEDIFF);
 } // not writing to file

 // if we could not load all the symbols, tell'em how much to increase SYMSIZE
 if (ssfdeficit) {
  DBG (0, "Not all symbols were loaded - increase SYMSIZE by %ld bytes.\n",
	ssfdeficit, 0);
 }

 return (0);

} // main ()

