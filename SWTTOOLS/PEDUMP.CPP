// $Header:   P:/pvcs/misc/swttools/pedump.cpv   1.0   07 May 1996 02:42:00   HENRY  $
//
// PEDUMP.CPP - Dump Portable Executable (PE) files (COFF)
//
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <io.h>
#include <fcntl.h>
#include <share.h>
#include <memory.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "ssf.h"
#include "swat_api.pro"

#define	PEDUMP_VERJ		1
#define	PEDUMP_VERJ_STR	"1"

#define	PEDUMP_VERM		00
#define	PEDUMP_VERM_STR	"00"

char szInclude[ 128 ] = ""; // hdrs, line numbers, statics, externs, files, unk
char szLoad[ 128 ] = "lse"; // line numbers, statics, externs

int SwatPresent = 0;	// TRUE if SWAT detected and not flat model
DWORD dwRVABase = 0L;	// Preferred load address
DWORD dwStrings = 0L;	// Pointer to string table
DWORD dwStringTabSize = 0L; // Size of string table in bytes
DWORD dwTotalSymbols = 0L;

#pragma pack(2)
typedef struct tagCOFFHdr {
	WORD wMachine;
	WORD wSections;
	DWORD dwTimeDate;
	DWORD dwSymPtr;
	DWORD dwSymbols;
	WORD wOptHdrSize;
	WORD RelocsStripped:1,
		_unused_flags:15;
} COFFHDR, *PCOFFHDR;
#pragma pack()

typedef struct tagNameRec {
	DWORD dwZero;	// 0L if name is longer than 8 bytes
	DWORD dwStrOff;	// Offset into string table
} NAMEREC, *PNAMEREC;

#pragma pack(1)
typedef struct tagSymbol {
	union {
		NAMEREC nr;
		char paName[ 8 ]; // Name if length <= 8
	};
	DWORD dwValue;	// Symbol value
	short int nSection;	// Origin:1 index into section table
	WORD wType;		// Type: 0x20 = function, 0 = non-function
	BYTE StorageClass; // Enum
	BYTE NumberAux;	// Number of auxiliary symbol records to follow
} SYMREC, *PSYMREC;
#pragma pack()

#pragma pack(1)
typedef struct tagStdOptHdr {
	WORD wMagic;	// 0413 (0x10b) for normal exe
	BYTE LMajor;	// Linker major ver
	BYTE LMinor;	// Linker minor ver
	DWORD dwCodeSize; // Size of code section or sum of all code sections
	DWORD dwInitDSize; // Size of initialized data
	DWORD dwUnInitDSize; // Size of uninitialized data
	DWORD dwEntryRVA; // Entry point
	DWORD dwBaseCode; // Start of code section relative to beginning of image
	DWORD dwBaseData; // Start of data section relative to beginning of image
} STDOPTHDR, *PSTDOPTHDR;
#pragma pack()

#pragma pack(2)
typedef struct tagNTOptHdr {
	DWORD dwImageBase;	// Preferred address (/64K)
	DWORD dwSectAlign;	// Section alignment in bytes (4K)
	DWORD dwFileAlign;	// Alignment of pages in image file, expressed in bytes
	WORD wOSMajor;		// Major ver of required OS
	WORD wOSMinor;		// Minor ver of required OS
	WORD wUserMajor;	// Major ver of image
	WORD wUserMinor;	// Minor ver of image
	WORD wSubSysMajor;	// Major ver of subsystem
	WORD wSubSysMinor;	// Minor ver of subsystem
	DWORD dwReserved;
	DWORD dwImageSize;
	DWORD dwHdrSize;
	DWORD dwFileCSum;
	DWORD dwSubSys;
	WORD wDLLFlags;		// Obsolete
	DWORD dwStackReserve;
	DWORD dwStackCommit;
	DWORD dwHeapReserve;
	DWORD dwHeapCommit;
	DWORD dwLoaderFlags; // Obsolete
	DWORD dwNDataDirs;	// Number of data dictionary entries in remainder of
						// Optional header
} NTOPTHDR, *PNTOPTHDR;
#pragma pack()

typedef struct tagDataDir {
	DWORD dwRVA;	// Relative Virtual Address
	DWORD dwSize;	// Size in bytes
} DATADIR, *PDATADIR;

typedef struct tagDataDirOptHdr {
	DATADIR ExportTab;
	DATADIR ImportTab;
	DATADIR ResourceTab;
	DATADIR ExceptionTab;
	DATADIR SecurityTab;
	DATADIR BaseRelocTab;
	DATADIR DebugData;
	DATADIR Copyright;
	DATADIR GlobalPtrReg;
	DATADIR TLSTab;
	DATADIR LoadConfigTab;
	DATADIR reserved[ 5 ];
} DATADIROPTHDR, *PDATADIROPTHDR;

#pragma pack(2)
typedef struct tagSectHdr {
	char paName[ 8 ]; // name (not null-terminated if 8 chars) or /dddd->strtbl
	DWORD dwVirtSize;	// Virtual size (if 0 padded when loaded)
	DWORD dwOffset;		// Offset of first byte relative to image base
	DWORD dwRawDataSize; // Size of raw data (must be rounded up to FileAlign)
	DWORD dwRawDataPtr;	// Pointer within file to start of raw data (this sect)
	DWORD dwRelocPtr;	// Pointer within file to start of relocations
	DWORD dwLNumPtr;	// Pointer to start of line numbers
	WORD wRelocCount;	// Number of relocation entries
	WORD wLNumCount;	// Number of line-number entries
	DWORD dwFlags;		// Section flags
} SECTHDR, *PSECTHDR;
#pragma pack()

// Data used to keep track of section names
typedef struct tagSectData {
	DWORD dwPtr;		// Offset of line number data
	WORD  wCount;		// Number of line number records (total)
	WORD  wCur;			// Current start index
	char  *pszName;		// Section name
} SECTDATA, *PSECTDATA;

#pragma pack(2)
typedef struct tagCOFFLNum {
	DWORD dwRVAIdx;		// If wLine == 0, index into symtab, else RVA
	WORD wLine;			// Origin:1 line number or 0 if dwRVAIdx indexes symtab
} COFFLNUM, *PCOFFLNUM;
#pragma pack()

#pragma pack(1)
typedef struct tagAuxSect {
	DWORD dwLength;		// Length of section data
	WORD  wRelocs;		// Number of reloc records
	WORD  wLNums;		// Number of line numbers
	DWORD dwCheckSum;
	WORD  wIndex;
	BYTE  Selection;
	BYTE  unused[ 3 ];
} AUXSECT, *PAUXSECT;
#pragma pack()

// Display a stream of bytes in hex (and ASCII if we can).
void
ShowHex( char *pszLabel, void *pData, WORD wCount ) {

	char szBuff[ 256 ];
	int nOff;
	BYTE *pbData = (BYTE *)pData;
	BYTE b;

	printf( pszLabel );

	// FIXME handle multiple lines
	if (wCount > sizeof( szBuff ) - 1) {
		wCount = sizeof( szBuff ) - 1;
	} // Set maximum

	for (nOff = 0; nOff < wCount; nOff++) {
		b = pbData[ nOff ];
		printf( "%02x %s", b, ((nOff + 1) % 8) ? "" : "  " );
		if (b < ' ') b = '.';
		szBuff[ nOff ] = b;
	} // while not out of room in the buffer

	szBuff[ nOff ] = '\0';
	printf( "%s\n", szBuff );

} // ShowHex()

// Show ASCII bytes, not necessarily terminated, for specified number of bytes
void
ShowAscii( char *pszData, int nCount, char *pszFmt ) {

	char szName[ 256 ];

	// FIXME do this better
	if (nCount > sizeof( szName ) - 1) {
		nCount = sizeof( szName ) - 1;
	}

	memcpy( szName, pszData, nCount );
	szName[ nCount ] = '\0';
	printf( pszFmt, szName );

} // ShowAscii

// Puts name in a buffer and returns an SSFp pointer to start.
SSFp
BuildSSF( char *pszBuff, char *pszName ) {

	SSFp pRet = (SSFp)pszBuff;

	// Blast in name and length
	strcpy( (char *)pRet->symname, pszName );
	pRet->symlen = strlen( pszName );

	// Zero group (which we're not currently using)
	pRet->group = 0;

	return pRet;

} // BuildSSF()

// Add symbol to SWAT if present
void
AddSym( SSFp pSym ) {

	if (SwatPresent) {

		WORD wCount = 1;

		// No duplicates
		if (!SWAT_ADDSYM( &wCount, pSym, 0 )) {

			// Update grand total
			dwTotalSymbols++;

		} // Add symbol succeeded

	} // Non-Win32 only

} // AddSym()

// Fetch string at specified index in string table.  pszBuff must point to
// at least 256 bytes of storage.
void
GetStringAt( int nFile, DWORD dwIndex, char *pszBuff ) {

	// Save current position
	long lPos = _lseek( nFile, 0L, SEEK_CUR );

	strcpy( pszBuff, "<err!>" );
	if (lPos == -1L || dwIndex >= dwStringTabSize) return;

	int nRead = 255;
	if (nRead + dwIndex > dwStringTabSize) {
		nRead = dwStringTabSize - dwIndex;
	}

	// Strings are supposed to be stored as ASCIIZ strings.
	if (_lseek( nFile, dwIndex + dwStrings, SEEK_SET ) != -1) {
		nRead = _read( nFile, pszBuff, nRead );
		if (nRead >= 0) {
			pszBuff[ nRead ] = '\0';
		} // Terminate it
	} // Seek succeeded

	_lseek( nFile, lPos, SEEK_SET );

} // GetStringAt()

// Dump wNum line numbers for specified section nSect if the name matches.
// The basename from pszFile is used to build a basename#nnn line number
// symbol for SWAT.
void
DumpLines( int nFile, SECTDATA& ln, WORD wNum, int nSect, char *pszName,
	char *pszFile ) {

	int Display = 1, Load = 1;

	if (!strchr( szInclude, 'l' )) {
		Display = 0;
	} // Not showing line numbers

	if (!strchr( szLoad, 'l' ) || !SwatPresent) {
		Load = 0;
	} // Not loading symbols

	if (!Display && !Load) {
		return;
	} // Nothing to do

	char szName[ 64 ];

	memcpy( szName, pszName, 8 );
	szName[ 8 ] = '\0';

	if (stricmp( szName, ln.pszName )) {
		return;
	} // No match

	// See if the remaining records match
	if (ln.wCur >= ln.wCount) {
		return;
	} // Nothing left
	else if (ln.wCur + wNum > ln.wCount) {
		wNum = ln.wCount - ln.wCur;
	} // Number is in excess

	long lPos = _lseek( nFile, 0L, SEEK_CUR );
	COFFLNUM lnum;
	int nLineRec;

	if (lPos == -1L ||
		_lseek( nFile, ln.dwPtr + ln.wCur * sizeof( lnum ), SEEK_SET ) == -1L) {
		return;
	} // Error

	_splitpath( pszFile, NULL, NULL, szName, NULL );
	char *pszEnd = szName + strlen( szName );

	for (nLineRec = 0; nLineRec < wNum; nLineRec++) {

			if (_read( nFile, &lnum, sizeof( lnum ) ) != sizeof( lnum )) {
				break;
			} // read error

			// Count another
			ln.wCur++;

			if (lnum.wLine) {

				char szBuff[ sizeof( SSF ) + 64 ];

				sprintf( pszEnd, "#%u", lnum.wLine );
				if (Display) printf( "  %s line=%u, addr=%08lx\n", szName,
								lnum.wLine, lnum.dwRVAIdx );

				if (Load) {

					// Set up a symbol record pointer
					SSFp pSym = BuildSSF( szBuff, szName );

					// Plug in values
					pSym->offset = lnum.dwRVAIdx + dwRVABase;
					pSym->segsel = 0;
					pSym->flags = SSF0_PM | SSF1_LIN; // PM, line number

					// Pass it up to SWAT.  Doing this one at a time is slow...
					AddSym( pSym );

				} // Loading symbols

			} // Line number
			else {
				if (Display) printf( " sym(%lu)=?\n", lnum.dwRVAIdx );
			} // Index into symbol table

	} // for all line number records

	// Restore previous position
	_lseek( nFile, lPos, SEEK_SET );

} // DumpLines()

// Dump a file.  Returns 1 if PE, 0 if not, -1 if unable to open.
int
DumpFile( char *pszFile ) {

	int nFile = _sopen( pszFile, _O_RDONLY | _O_BINARY, _SH_DENYNO );
	BYTE Buff[ 512 ];
	WORD *pwOff;
	DWORD dwCoffOff;
	int Display;

	if (nFile < 0) {
		return -1;
	} // Unable to open

	if (_read( nFile, Buff, 0x3e ) != 0x3e) {
		_close( nFile );
		return 0;
	} // Not a PE file

	pwOff = (WORD *)&Buff[ 0x3c ];
	if (*pwOff < 0x3e || _lseek( nFile, *pwOff, SEEK_SET ) < 0L) {
		_close( nFile );
		return 0;
	} // Not a PE file

	dwCoffOff = *pwOff;

	if (_read( nFile, Buff, 24 ) != 24 ||
		memcmp( Buff, "PE\0\0", 4 )) {
		_close( nFile );
		return 0;
	} // Not a PE file

	COFFHDR CHdr;
	CHdr = *((PCOFFHDR)&Buff[ 4 ]);
	if (CHdr.wMachine != 0x14c) {
		_close( nFile );
		fprintf( stderr, "Error: Machine type %04x (Intel only supported)\n",
			CHdr.wMachine );
		return 0;
	}

	if (CHdr.wSections == 0) {
		_close( nFile );
		fprintf( stderr, "Warning: file appears to have no sections\n" );
		return 1;
	} // Nothing to do

	Display = strchr( szInclude, 'h' ) ? 1 : 0;
	if (Display) {

		printf( "%d sections\n", CHdr.wSections );
		printf( "Time/date %lx\n", CHdr.dwTimeDate );
		printf( "%lu symbols at offset %lx\n", CHdr.dwSymbols, CHdr.dwSymPtr );
		printf( "Optional header: %d\n", CHdr.wOptHdrSize );
		//printf( "Record size = %d\n", sizeof( SYMREC ) );

		if (CHdr.RelocsStripped) printf( "Relocations stripped\n" );

	} // Displaying headers

	// Calculate string table location
	dwStrings = CHdr.dwSymPtr + CHdr.dwSymbols * sizeof( SYMREC );
	long lPos = _lseek( nFile, 0L, SEEK_CUR );
	if (Display) printf( "String table at %lx\n", dwStrings );
	if (_lseek( nFile, dwStrings, SEEK_SET ) != -1L) {
		if (_read( nFile, &dwStringTabSize, sizeof( dwStringTabSize ) ) != -1) {
			if (Display) {
				printf( "String table len = %lu bytes\n", dwStringTabSize );
			} // Displaying
		} // Read length in bytes
	} // Got start of string table
	// Apparently this is not necessary...
	//dwStrings += sizeof( DWORD ); // Skip over length dword
	_lseek( nFile, lPos, SEEK_SET ); // Restore previous position

	// Display optional header data
	WORD wRemaining = CHdr.wOptHdrSize;
	STDOPTHDR StdOpts;

	if (wRemaining >= sizeof( StdOpts ) &&
		_read( nFile, &StdOpts, sizeof( StdOpts ) ) == sizeof( StdOpts )) {

		wRemaining -= sizeof( StdOpts );

		// Display it
		if (Display) printf( "Entry_point=%08lx\n", StdOpts.dwEntryRVA );

		NTOPTHDR NTOpts;

		if (wRemaining >= sizeof( NTOpts ) &&
			_read( nFile, &NTOpts, sizeof( NTOpts ) ) == sizeof( NTOpts )) {

			wRemaining -= sizeof( NTOpts );

			// Display it
			if (Display) printf( "Preferred_base=%08lx\n", NTOpts.dwImageBase );
			dwRVABase = NTOpts.dwImageBase;

			SSFp pSym = BuildSSF( (char *)Buff, "SWAT_Win32_entry" );
			pSym->segsel = 0;
			pSym->offset = StdOpts.dwEntryRVA + dwRVABase;
			pSym->flags = SSF0_PM;

			AddSym( pSym );

			DATADIROPTHDR DDOpts;

			if (wRemaining >= sizeof( DDOpts ) &&
				_read( nFile, &DDOpts, sizeof( DDOpts ) ) == sizeof( DDOpts )) {

				wRemaining -= sizeof( DDOpts );

				// Display it
				if (Display) printf( "Resource_ptr=%08lx Resource_size=%08lx\n",
					DDOpts.ResourceTab.dwRVA, DDOpts.ResourceTab.dwSize );

			} // Got data directory options

		} // Got NT options

	} // Got standard options

	if (wRemaining) {
		// Skip anything remaining
		_lseek( nFile, wRemaining, SEEK_CUR );
	} // Skip remnant of option header (this shouldn't be necessary)

	// Display section table entries
	int nSection;
#define	MAXLINENUMS 96
	static SECTDATA LineNums[ MAXLINENUMS ];
	int nLineNums = 0;

	for (nSection = 0; nSection < CHdr.wSections; nSection++) {

		SECTHDR sh;
		char szName[ 9 ];

		if (_read( nFile, &sh, sizeof( sh ) ) != sizeof( sh )) {
			break;
		} // Error on read

		if (Display) {
			printf( "Section %d: ", nSection );
			ShowAscii( sh.paName, 8, "%s\n" );
		}

		memcpy( szName, sh.paName, 8 );
		szName[ 8 ] = '\0';

		if (Display) {
			printf( " lnum_ptr=%08lx lnum_count=%04x virt.size=%08lx\n"
					" raw_size=%08lx raw_ptr=%08lx load_start=%08lx flags=%08lx\n",
			sh.dwLNumPtr, sh.wLNumCount, sh.dwVirtSize,
			sh.dwRawDataSize, sh.dwRawDataPtr,
			sh.dwOffset, sh.dwFlags );
		}

		//if (sh.wLNumCount) {
			if (nLineNums >= MAXLINENUMS) {
				fprintf( stderr, "Too many line number sections (max=%d)\n",
					MAXLINENUMS );
				exit( -1 );
			}
			LineNums[ nLineNums ].dwPtr = sh.dwLNumPtr;
			LineNums[ nLineNums ].wCount = sh.wLNumCount;
			LineNums[ nLineNums ].wCur = 0;
			LineNums[ nLineNums ].pszName = strdup( szName );
			nLineNums++;
		//} // More line numbers

	} // for all sections

	// Jump to start of symbol table
	if (_lseek( nFile, CHdr.dwSymPtr, SEEK_SET ) != -1L) {

		SYMREC sr;
		DWORD dwReadCount;
		int nToSkip = 0;
		int nToShow = 0;
		int nGotFile = 0;
		int nLastClass = 0;
		int nAddSym = 0;
		static char szFName[ _MAX_PATH ];
		static char szLastName[ 256 ];

		szFName[ 0 ] = '\0';

		for (dwReadCount = 0; dwReadCount < CHdr.dwSymbols; dwReadCount++) {

			if (_read( nFile, &sr, sizeof( sr ) ) != sizeof( sr )) {
				fprintf( stderr, "Read error on record %ld\n", dwReadCount );
				break;
			} // Read failed

			if (nToSkip > 0) {

				nToSkip--;

				// Always save filenames
				if (nLastClass == 103) {
					// FIXME handle long names beginning /ddd where ddd
					// indexes the string table.
					memcpy( szFName, &sr, 8 );
					szFName[ 8 ] = '\0';
				} // Save filename

				if (nToShow > 0) {

					if (nGotFile && nGotFile < nLineNums && szFName[ 0 ]) {

						AUXSECT as;

						memcpy( &as, &sr, sizeof( as ) );
						DumpLines( nFile, LineNums[ nGotFile - 1 ], as.wLNums,
							nGotFile - 1, szLastName, szFName );

					} // Got section name
					else if (Display) {
						ShowHex( "Au:", &sr, sizeof( sr ) );
					}

				} // Displaying some auxiliary records

				continue;

			} // Skipping auxiliary records

			nToShow = 0;
			nToSkip = sr.NumberAux;
			nGotFile = 0;
			nAddSym = 0;

			// Assume name is short
			memcpy( szLastName, sr.paName, 8 );
			szLastName[ 8 ] = '\0';

			if (!sr.nr.dwZero) {
				GetStringAt( nFile, sr.nr.dwStrOff, szLastName );
			} // Get long name

			Display = 1;

			// See if we're including this type
			switch (nLastClass = sr.StorageClass) {

				case 2:	// Extern
				case 5:	// Defined externally
				case 105: // Weak extern
					Display = strchr( szInclude, 'e' ) ? 1 : 0;
					nAddSym = strchr( szLoad, 'e' ) ? 1 : 0;
					break;

				case 3:	// Static
					Display = strchr( szInclude, 's' ) ? 1 : 0;
					if (nToSkip) {
						nToShow = 1;
						nGotFile = sr.nSection; // If we match a section name
					}
					else {
						nAddSym = strchr( szLoad, 's' ) ? 1 : 0;
					}
					break;

				case 103: // File
					if (!strchr( szInclude, 'f' )) continue;
					break;

				default:
					if (!strchr( szInclude, 'u' )) continue;
					break;

			} // switch

			if (Display) {

				if (sr.nr.dwZero) {
					ShowAscii( sr.paName, 8, "%-8s        " );
				} // Short name
				else {
					printf( " lname@%08lx ", sr.nr.dwStrOff );
				} // Long name

				printf( "val=%08lx sect=%2d type=%2x stclass=%-3d naux=%d\n",
					sr.dwValue, sr.nSection, sr.wType,
					sr.StorageClass, sr.NumberAux );

				if (!sr.nr.dwZero) {
					printf( "%s\n", szLastName );
				} // Display long name

				if (sr.StorageClass == 103) nToShow = 1;

			} // Displaying

			if (nAddSym && szLastName[ 0 ] != '$') {

				SSFp pSym = BuildSSF( (char *)Buff, szLastName );
				pSym->segsel = 0;
				pSym->offset = sr.dwValue + dwRVABase;
				pSym->flags = SSF0_PM;

				AddSym( pSym );

			} // OK to add this symbol

		} // for all symbol records

		if (dwReadCount == CHdr.dwSymbols) {
			fprintf( stderr, "<Finished reading symbol table>\n" );
		} // Completed successfully

	} // Got start of symbol table

	_close( nFile );

	return 1;

} // DumpFile()

int
main( int argc, char **argv ) {

	fprintf( stderr, "PEDump ver %d.%02d  Copyright (C) 1996 Qualitas, Inc.  All rights reserved.\n", PEDUMP_VERJ, PEDUMP_VERM );

	if (sizeof( int ) == sizeof( WORD )) {
		SwatPresent = SWAT_PRESENT();
		if (SwatPresent) {
			fprintf( stderr, "386SWAT detected.\n" );
		}
	} // OK to test for SWAT

	int nFile;
	for (nFile = 1; nFile < argc; nFile++) {

		if (argv[ nFile ][ 0 ] == '-') {

			switch (argv[ nFile ][ 1 ]) {

				case 'i':
					strcpy( szInclude, &argv[ nFile ][ 2 ] );
					break;

				case 'l':
					strcpy( szLoad, &argv[ nFile ][ 2 ] );
					break;

				case 'h':
				case '?':
				default:
					fprintf( stderr, "Syntax:\n"
								"pedump [options] filename.exe [...]\n"
								"where options may be:\n"
								" -ilist   list contains one or more of h, l, e, f, s, u\n"
								"          to include header, line, extern, file, static, unknown\n"
								" -llist   list contains one or more of l, e, s\n"
								"          to load symbols for lines, externs, statics\n"
								);
					return -1;

			} // switch
			continue;

		} // Got an option

		printf( "File: %s\n", argv[ nFile ] );

		int nRes = DumpFile( argv[ nFile ] );

		if (nRes < 0) {
			fprintf( stderr, "Unable to open\n" );
		}
		else if (!nRes) {
			fprintf( stderr, "Not a PE file\n" );
		}
		else continue;

		// Terminate with error
		return -1;

	} // for all args

	if (SwatPresent) {
		fprintf( stderr, "%lu symbols passed to SWAT\n", dwTotalSymbols );
	}

	return 0;

} // main()

