//' $Header:   P:/pvcs/misc/swttools/libsym.c_v   1.0   06 Jan 1995 18:02:44   HENRY  $
//
// LIBSYM.C - Process EXEHDR output and load as SWAT symbols
//
// Copyright (C) 1994 Qualitas, Inc.  All rights reserved.
//
// This program operates on standard input.  It processes
// EXEHDR output directly into SWAT symbols.  Each DLL's
// segments are assigned a single group number for later
// translation.

#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <string.h>

#include "mapssf.h"
#include "swat_api.pro"

char szBuff[ 1024 ];
char szSeps[] = " \t\r\n\x1a";
int Verbose = 0;
int Flush = 0;
WORD wgrp = 0;
char cSep = '#'; // Library?modulename separator [_$#@?] OK, [!%^&+-*:.,] not

// Print syntax error message and quit
void
SyntErr( void ) {

	fprintf( stderr, "Syntax: LIBSYM [-v] [-o] [-gnum] <input\n"
					 "  where input is the output from EXEHDR.\n"
					 "  Other options:\n"
					 "  -v Verbose\n"
					 "  -o Clear existing symbols first\n"
					 "  -g Start with group num\n"
					 );
	exit( -1 );

} // SyntErr()

// Main entry point
int
main( int argc, char **argv ) {

	enum {
		NOWHERE,
		FOUNDLIB,
		INEXPORT
	} CurState = NOWHERE;
	char *Tok1, *Tok2, *Tok3, *Tok4;
	char szLibName[ 80 ];
	char szSymName[ 256 ];
	SSFp ssf;
	WORD wAdded;
	DWORD dwCount = 0;

	fprintf( stderr,
		"LIBSYM v0.10 Copyright (C) 1994 Qualitas, Inc.  All rights reserved.\n"
		"Reading from stdin...\n" );

	// Skip argv[ 0 ]
	while (--argc) {

		argv++;

		if (!stricmp( *argv, "-v" )) {
			Verbose = 1;
		}
		else if (!stricmp( *argv, "-o" )) {
			Flush = 1;
		}
		else if (!strnicmp( *argv,"-g", 2 )) {

			char *psz = (*argv) + 2;

			if (!*psz) {
				argv++;
				argc--;
				if (!argc) {
					SyntErr();
				}
				psz = *argv;
				if (!psz) {
					SyntErr();
				}
			} // Space separates -g and num

			wgrp = atoi( psz );
			if (wgrp) {
				wgrp--;
			}

		} // Starting group number specified
		else SyntErr();

	} // Parse options

	ssf = (SSFp) malloc( sizeof( SSF ) + 256 );
	if (!ssf) {
		fprintf( stderr, "Malloc() failed\n" );
		return -1;
	} // Couldn't malloc

	if (!SWAT_PRESENT()) {
		fprintf( stderr, "386SWAT not present\n" );
		return -1;
	} // SWAT not present

	if (Flush) {
		SWAT_FLUSHTAB();
	} // Clear existing symbols

	while (gets( szBuff )) {

		Tok1 = strtok( szBuff, szSeps );
		Tok2 = strtok( NULL, szSeps );
		Tok3 = strtok( NULL, szSeps );
		Tok4 = strtok( NULL, szSeps );

		if (CurState == NOWHERE) {

			if (!Tok1) continue;

			if ((!stricmp( Tok1, "Library:" ) ||
				 !stricmp( Tok1, "Module:" ))
					&& Tok2) {
				CurState = FOUNDLIB;
				strcpy( szLibName, Tok2 );
				wgrp++;
				fprintf( stderr, "Library: %s   Group: %d\n", Tok2, wgrp );
			} // Got library name

		} // Look for Library name
		else if (CurState == FOUNDLIB) {

			if (!Tok1) continue;

			if (!stricmp( Tok1, "Exports:" )) {
				CurState = INEXPORT;
			} // Got start of exports section

		} // Look for Exports:
		else if (CurState == INEXPORT) {

			if (!Tok1) {
				CurState = NOWHERE;
				continue;
			} // End of exports

			if (!Tok2 || !Tok3 || !Tok4) {
				fprintf( stderr, "Error: truncated line\n" );
				return -1;
			} // Not all tokens present

			if (!stricmp( Tok1, "no." ) && !stricmp( Tok2, "type" )) {
				continue;
			} // Skip this (FIXME - validate)

			// Tok1 == ordinal
			// Tok2 == decimal seg or 254
			// Tok3 == hex offset
			// Tok4 == name
			if (!atoi( Tok2 ) || atoi( Tok2 ) == 254) {
				continue;
			} // Skip segment 254 (abs records)

			sprintf( szSymName, "%s%c%s", szLibName, cSep, Tok4 );
			ssf->segsel = atoi( Tok2 );
			sscanf( Tok3, "%lx", &(ssf->offset) );
			ssf->flags = SSF0_PM;
			ssf->group = wgrp;
			ssf->symlen = strlen( szSymName );
			strcpy( ssf->symname, szSymName );

			if (Verbose) {
				fprintf( stderr, "Adding %s (%s), grp %d, %x:%x\n",
						szSymName,
						Tok1,
						wgrp,
						ssf->segsel,
						(WORD) ssf->offset );
			}

			wAdded = 1;
			SWAT_ADDSYM( &wAdded, ssf, 0 );

			if (!wAdded) {
				fprintf( stderr, "Out of symbol space\n" );
				return -1;
			} // Didn't get added

			dwCount++;

		} // Process exports, look for blank line
		else {
			fprintf( stderr, "Invalid state\n" );
			return -1;
		} // Invalid state

	} // not EOF

	free( ssf );

	fprintf( stderr, "Done.  %lu symbols passed to SWAT\n", dwCount );

} // main()

