/****
 *' $Header:   P:/pvcs/misc/swttools/loadmap.c_v   1.7   28 Mar 1996 12:14:08   HENRY  $
 *
 * loadmap.c
 *
 * .MAP format read functions
 * Compiler assumptions: /J /AC (default char type is unsigned,
 *				 use compact model)
 *
 ****/

#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <io.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>

#include "mapssf.h"
#include "loadmap.h"

#ifndef PROTO
#include "loadmap.pro"
#endif

extern int offwrap;
extern int win32;

char szSegName[ _MAX_FNAME + 10 ]; // MODNAME + "#selNNN"
int cbSegName; // End of "modname#sel" part of szSegName

char	tok1[33],	// usually seg:off
	tok2[65],	// sometimes symbol name
	tok3[65],	// sometimes symbol name
	tok4[161],	// sometimes 2 path names
	 mdrive[ _MAX_DRIVE ],	// drive letter for _splitpath
	 mdir[ _MAX_DIR ],	// directory name for _splitpath
	 mname[ _MAX_FNAME ], // File basename for _splitpath
	 mext[ _MAX_EXT ],	// extension for _splitpath
	tok5[33],
	tok6[33],
	tok7[33],
	tok8[33];
char	*ltok[][2] = { // array to loop through tokens for line numbers
	{tok1, tok2},
	{tok3, tok4},
	{tok5, tok6},
	{tok7, tok8}
};
#define LTOK_SIZE	(sizeof (ltok) / sizeof (ltok[0]))

char	modname[15];	// .OBJ file basename
char	linesym[65];	// used for constructing line number pseudo-symbols
static char szSegs[ 256 ];	// Segments we've added modname#selN for
DWORD	dwSelBase[ 256 ];	// Win32 selector bases

/**************************** SEGOFF2DD (char *tok) **************************/
long segoff2dd (char *tok)
// convert segment:offset value to 32-bit value
{
 WORD	loval, hival;		// hi & lo order words of value dword

	 sscanf (tok, "%x:%x", &hival, &loval);

	 return (((long) hival << 16) | loval);

} // segoff2dd ()

/**************************** SEGOFF2SEG (char *tok) *************************/
WORD segoff2seg (char *tok)
// return segment only from segment:offset value
{
 WORD segval;

 sscanf (tok, "%x:", &segval);

 return (segval);

} // segoff2seg ()

/**************************** SEGOFF2OFF (char *tok) *************************/
DWORD segoff2off (char *tok)
// return offset only from segment:offset value
{
 DWORD offset;

 sscanf (tok, "%*x:%lx", &offset);

 return (offset);

} // segoff2off ()

/*************************** SPLITSEGOFF (char *tok, ) ************************/
void splitsegoff (char *tok, SSF *symdata)
// Split out Seg:Off from the token, handling offset wrap
{
 static WORD  lastseg;		// Last segment value
 static DWORD lastoff;		// ...	offset ...
 static DWORD wrapval;		// Offset wrap value (0, 64K, 128K, ...)

 symdata->offset = segoff2off (tok); // Split the values
 symdata->segsel = segoff2seg (tok); // ...

 if (offwrap)			// If we're checking for offset wrap
 {
     if (lastseg == symdata->segsel) // If it's the same segment as last time,
	{
	 if (lastoff > symdata->offset) // ...but the offset wrapped,
	     wrapval += 64L*1024L; // ...add in another 64K
	}
     else			// If the segments are different,
	wrapval = 0;		// ...start the offset wrap at zero

     lastseg = symdata->segsel; // Save for next time
     lastoff = symdata->offset; // ...

     // Note we wait until we've saved the last offset before adding
     // in the offset wrap value.
     symdata->offset += wrapval; // Add in the offset wrap value
 }
} // splitsegoff ()

//************************** CHECKSEL() *****************************
// Add to symbol table as modname#selNNN
// This is how we save the .EXE or .DLL segment ordinal number for
// translation via WinSwat.EXE (which catches the NFY_LOADSEG notification
// via RegisterNotification).
void CheckSel( SSF *pData ) {

	if (pData->segsel < 1 || pData->segsel > 255) {
		return;
	} // Not one we're interested in

	if (szSegs[ pData->segsel ] != ' ') {
		return;
	} // We've already added this one

	szSegs[ pData->segsel ] = '*'; // Mark it as added

	// Create name
	sprintf( &szSegName[ cbSegName ], "%u", pData->segsel );

	// Add it
	add_ssf( 0L,			// Offset is irrelevant
		 pData->segsel,
		 pData->flags,
		 pData->group,
		 szSegName );

} // CheckSel()

/*************************** UpdateSelBase() ********************************/
// Update selector base table for Win32.  pszSegSel is in the form "sel:offset"
void UpdateSelBase( char *pszSegSel, DWORD dwLinAddr ) {

	WORD wSel;
	DWORD dwOff;

	if (sscanf( pszSegSel, "%x:%lx", &wSel, &dwOff ) < 2) return;

	if (wSel < 1 || wSel > 256) return;

	dwSelBase[ wSel - 1 ] = dwLinAddr - dwOff;

	//fprintf( stderr, "SelB[%d] (%s) = %lx - %lx = %lx\n", wSel - 1, pszSegSel, dwLinAddr, dwOff, dwLinAddr - dwOff );

} // UpdateSelBase()

/*************************** LOAD_MAP (char *path) **************************/
// Process the .MAP format file indicated by path argument
void load_map (char *path)
{
 FILE *f;
 char *err = NULL;
 int	state = ST_UNDEF,	// state machine switch
	lstate = ST_UNDEF;	// last state
 int	i,j;			// loop counters
 char *s,			// temporary char *
	*symname;		// symbol name
 char	*openparen, *closeparen;
 char	*semicol;
 SSF	symdata;		// Symbol record
 char	*frbuff;		// For buffering reads
 size_t frbuff_size;		// Size of frbuff
 DWORD	sv1,sv2;		// Values from segment section
 WORD	gseg;			// Group segment

 clear_wsg ();	// Clear segment data in WSG structure

 if ((f = fopen (path, "r")) != NULL) {

  // Set up name for modname#selNNN symbols
  memset( szSegs, ' ', sizeof( szSegs ) );
  _splitpath( path, mdrive, mdir, mname, mext );
  sprintf( szSegName, "%s#sel", mname );
  cbSegName = strlen( szSegName );

  frbuff_size = _memmax ();	// See how much near memory is available
  if (frbuff_size >= 0x8000)
	frbuff_size = 0x7fff;	// 32K-1 is maximum size
  setvbuf (f, frbuff = malloc (frbuff_size), _IOFBF, frbuff_size);
				// Set buffer

  // .map file opened successfully -- read until EOF
  while (fgets (buffer, BUFSIZE, f) != NULL && err == NULL) {

   // ensure it's null terminated
   buffer [BUFSIZE] = '\0';
   if (s = strchr (buffer, '\n'))
	*s = '\0';
   if (s = strchr (buffer, '\r'))
	*s = '\0';
   DBG (8, " < \"%s\"\n", buffer, 0);

   symname = NULL;
   symdata.flags = defaultmode; // assume whatever the specified default is
   symdata.segsel = defsegsel;	// default segment/selector value
   symdata.offset = 0L; 	// default offset value
   symdata.group = 0;		// assume group is 0 unless we have .WSG data

   if ((semicol = strchr (buffer, ';')) != NULL)
	*semicol = '\0';        // lop off comments

   // get tokens to determine if we have a state switch or data
   *tok1 = *tok2 = *tok3 = *tok4 = *tok5 = *tok6 = *tok7 = *tok8 = '\0';
   sscanf (buffer, "%s %s %s %s %s %s %s %s",
	tok1,	tok2,	tok3,	tok4,	tok5,	tok6,	tok7,	tok8);
   if ( !stricmp (tok1, SEGT1_Start) &&
		!stricmp (tok3, SEGT3_Length) &&
		!stricmp (tok4, SEGT4_Name) &&
		!stricmp (tok5, SEGT5_Class)) {
	 state = ST_SEG;
	 map32 = 0;
   }
   else
   if ( !stricmp (tok1, SEGT1_Start) &&
	!stricmp (tok2, SEGT3_Length) &&
	!stricmp (tok3, SEGT4_Name)) {
	 state = ST_SEG;
	 map32 = 1;
   }
   else
   if ( !stricmp (tok1, GROUPT1_Origin) &&
		!stricmp (tok2, GROUPT2_Group))
	 state = ST_GROUP;
   else
   if ( !stricmp (tok1, PUBNAMET1_Address) &&
		!stricmp (tok2, PUBNAMET2_Publics) &&
		!stricmp (tok3, PUBNAMET3_by) &&
		!stricmp (tok4, PUBNAMET4_Name))
	 state = ST_PUBNAME;
   else
   if ( !stricmp (tok1, PUBVALT1_Address) &&
		!stricmp (tok2, PUBVALT2_Publics) &&
		!stricmp (tok3, PUBVALT3_by) &&
		!stricmp (tok4, PUBVALT4_Value))
	 state = ST_PUBVAL;
   else
   if ( !stricmp (tok1, LINET1_Line) &&
		!stricmp (tok2, LINET2_numbers) &&
		!stricmp (tok3, LINET3_for)) {
	 state = ST_LINE;
	 // extract module basename and source path
	 if (closeparen = strchr (tok4, ')'))
		*closeparen = '\0';     // kill )
	 if (openparen = strchr (tok4, '('))
		*(openparen++) = '\0';  // kill ( and get pointer to source path
	 _splitpath (tok4, mdrive, mdir, modname, mext);
	 if (openparen) {  // get source path
		_splitpath (openparen, mdrive, mdir, modname, mext);
		sprintf (linesym, "%s#src=%s", modname, openparen);
		if (!ignlines) {
		 symname = linesym;
		 symdata.flags = (symdata.flags & SSF0_MSK) | SSF1_SWT;
						// identify as SWAT internal
		} // !ignlines
	 } // got source path
   } // Line numbers for xxxx
   else
   if ( !stricmp (tok1, ENTRYT1_Program) &&
		!stricmp (tok2, ENTRYT2_entry) &&
		!stricmp (tok3, ENTRYT3_point) &&
		!stricmp (tok4, ENTRYT4_at)) {
	 state = ST_ENTRY;
	 // extract program entry point
   } // program entry point
   else if (!stricmp( tok1, "entry" ) &&
   			!stricmp( tok2, "point" ) &&
			!stricmp( tok3, "at" ) &&
			win32) {
	 // tok4=sel:offset
	 symdata.flags = SSF0_PM;
	 splitsegoff (tok4, &symdata);	// Split out Seg:Off
	 fprintf( stderr, "Entry point %x:%lx", symdata.segsel, symdata.offset );
	 // Add selector base
	 if (symdata.segsel > 0 && symdata.segsel <= 256) {
			symdata.offset += dwSelBase[ symdata.segsel - 1 ];
	 }
	 fprintf( stderr, " (%lx)\n", symdata.offset );
	 symdata.segsel = 0;
	 symdata.group = 0;
	 symname = "SWAT_Win32_entry";
	 state = ST_ENTRY;
   } // Win32 program entry point

   if (state != lstate) {
     if (debuglvl)
	switch (state) {
	 case ST_SEG:	fprintf (stderr, "Begin segment section%s\n",
				map32 ? "(LINK32 map file format)" : "");
		break;
	 case ST_GROUP: fprintf (stderr, "Begin group section\n");
		break;
	 case ST_PUBNAME: fprintf (stderr, "Begin publics by name\n");
		if (wsgcount) {
			int i2;
			fprintf (stderr,  " # Grp# M Sel  Group name        Start     Segment name      Start    End\n");
			for (i2=0; i2 < wsgcount; i2++)
			 fprintf (stderr, "%2d %04x %c %04x %-17s %08lxH %-17s %08lx-%08lxH\n",
				i2,
				wsg[i2].groupnum,
				wsg[i2].modeid,
				wsg[i2].selector,
				wsg[i2].groupname,
				wsg[i2].gbegin,
				wsg[i2].segname,
				wsg[i2].segbegin,
				wsg[i2].segend);
		}
		break;
	 case ST_PUBVAL: fprintf (stderr, "Begin publics by value (ignored)\n");
		break;
	 case ST_LINE:	fprintf (stderr, "Begin lines section for %s\n",
				modname);
		break;
	 case ST_ENTRY: fprintf (stderr, "Read program entry point\n");
		break;
	 case ST_UNDEF: fprintf (stderr, "Undefined state transition\n");
		break;
	} // if (debuglvl) switch ()
   } // change of state occurred

   else
   if (strlen (tok1))	// process data - not a state transition

    switch (state) {
	case ST_PUBVAL: // process Publics by Value section
	case ST_PUBNAME: // process Publics by Name section
	 if ((state == ST_PUBVAL && byname) ||
	     (state == ST_PUBNAME && !byname))
		break;
	 splitsegoff (tok1, &symdata);	// Split out Seg:Off,
					// handling offset wrap
	 // Handle Win32 as a special case.
	 // sel:offset name linaddr [f] [libname:]objname.obj
	 if (win32) {
	 	if (!tok3) break;
	 	symdata.segsel = 0;
		symname = tok2;
		sscanf( tok3, "%lx", &symdata.offset );
		symdata.flags = SSF0_PM;
		symdata.group = 0;
		// Update table of selector bases
		UpdateSelBase( tok1, symdata.offset );
	 	break;
	 } // win32 map file

	 if (!stricmp( tok2, "abs" )) {
	  // flag it as an abs
	  symdata.flags = (symdata.flags & SSF0_MSK) | SSF1_ABS;
	  // point symname to tok3
	  symname = tok3;
	 } // Abs
	 else if (!stricmp( tok2, "imp" ) || !stricmp( tok2, "unr" )) {
	  // Do nothing - ignore it
	 } // Imp or Unr
	 else {
	  symname = tok3[0] ? tok3 : tok2;
	  check_wsg (&symdata); // match groups with .WSG entries
	  if (defsegsel != -1)
		symdata.segsel = (segmentmode == SEG_SET ? 0 : symdata.segsel)
			 + defsegsel;
	  // Add to symbol table as modname#selNNN
	  CheckSel( &symdata );
	 } // not an ABS or IMP
	 break;

	case ST_LINE:	// process line numbers
	 if (!ignlines)
	  for (i=0; i<LTOK_SIZE; i++)
	   if (j = atoi (ltok [i][0])) {
		// get symbol value & segment
		splitsegoff (ltok [i][1], &symdata); // Split out Seg:Off,
						     // handling offset wrap
		if (defsegsel != -1)
		 symdata.segsel = (segmentmode == SEG_SET ? 0 : symdata.segsel)
			 + defsegsel;
		// construct fake symbol using modname
		sprintf (linesym, "%s#%u", modname, j);
		check_wsg (&symdata);	 // match groups with .WSG entries
		if (!(symdata.flags & SSF2_DEL)) {
		 // add symbol to swat table
		 DBG (2, "\t%s = %04x:", linesym, symdata.segsel);
		 DBG (2, "%08lx\n", symdata.offset, 0);
		 add_ssf (symdata.offset,
			 symdata.segsel,
			 SSF1_LIN | (symdata.flags & ~SSF1_MSK),
			 symdata.group,
			 linesym);
		} // Not a line number we should skip
	    // Add to symbol table as modname#selNNN
	    CheckSel( &symdata );
	   } // got a line number
	 break;
	case ST_GROUP:	// process group data (seg:offs groupname)
	 sscanf (tok1, "%x:%*x", &gseg);
	 DBG (1, "Group %s seg = %x\n", tok2, gseg);
	 // If it's a LINK32 map file, we can expect each group to
	 // have a unique segment number and we therefore skip 20-bit
	 // range matching of groups - group segments must match exactly.
	 resolve_wsg (1, tok2, ((DWORD) gseg) << (map32 ? 0 : 4), 0);
	 break;
	case ST_SEG:	// process segment data table
	 sscanf (tok1, "%08lx", &sv1);                  // Start
	 sscanf (map32 ? tok2 : tok3, "%08lx", &sv2);   // Length
	 if (sv2) sv2 = sv1 + sv2 - 1;			// Calculate end
	 resolve_wsg (0, map32 ? tok3 : tok4, sv1, sv2);
	 break;
	case ST_ENTRY:	// process Program entry point
	default:	// ignore
	 break;
    }		// switch (state) to process data

    lstate = state;	// save last state for comparison

    if (symname && !(symdata.flags & SSF2_DEL)) {
	// add to Swat table
	DBG (2, "\t%s = %04x:", symname, symdata.segsel);
	DBG (2, "%08lx\n", symdata.offset, 0);
	add_ssf (symdata.offset,
		 symdata.segsel,
		 symdata.flags,
		 symdata.group,
		 symname);
    } // symname != NULL

  } // EOF

  // check for error when not at end of file
  if (!feof (f)) {
	if (err == NULL)
	 err = "Error reading";
	fprintf (stderr, "%s\n", strerror (errno));
  }

  // display error message
  if (err)
	fprintf (stderr, "%s %s\n", err, path);

  // close .map file
  fclose (f);

  free (frbuff);	// Free file buffer

 }
 else
	fprintf (stderr, "Unable to open \"%s\"\n", path);

 return;

} // load_map ()

