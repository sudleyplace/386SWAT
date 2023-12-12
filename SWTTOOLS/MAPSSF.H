/*****
 *' $Header:   P:/pvcs/misc/swttools/mapssf.h_v   1.4   06 Jan 1995 18:03:34   HENRY  $
 *
 * MapSSF.h
 *
 * Swat Symbolic Format typedef's and #define's
 *
 *****/

#ifndef FAR
#define FAR __far
#endif

#define DWORD	unsigned long
#define WORD	unsigned int
#define BYTE	unsigned char

#define BUFSIZE 255		// size of buffer[] less 1 byte for \0
#define WSG_LINEMAX	80	// maximum line length for WSG file
				// (WSG_LINEMAX + group name must never
				//  exceed BUFSIZE)
#define ARGMAX	20		// maximum # of args (besides options)

#define DBG(x,fmt,a1,a2)	if (debuglvl>=x) fprintf (stderr, fmt,a1,a2)

#define SEG_SET 0		// set segment to specified value
#define SEG_ADD 1		// add specified value to segment

// SSF flags
typedef struct SSF_flagstruct {
 unsigned int
	SSF_modeid:1,
	SSF_rectype:5,
	SSF_undef:10;
} SSF_flags;

 // field 0 - 1 bit - mode indicator
#define SSF0_MSK 0x8000 	// bits used for this field
#define SSF0_PM 0x0000		// 0 = protected mode
#define SSF0_VM 0x8000		// 1 = V86/real mode
 // field 1 - 5 bits - record type
#define SSF1_MSK 0x7C00 	// bits used for this field
#define SSF1_DAT 0x0000 	// 0 = code or data
#define SSF1_LIN 0x0400 	// 1 = line number definition record
#define SSF1_ABS 0x0800 	// 2 = abs record
#define SSF1_SWT 0x0C00 	// 3 = symbol for SWAT internal use
 // field 2 - 1 bit - don't pass to SWAT
#define SSF2_DEL 0x0200 	// Delete symbol

// SSF record definition
// Note that we declare this as a pointer, since the actual length is unknown
// until we get the symbol name length - we will always cast another
// pointer type as SSFp.  The SSF type definition is used only for getting
// default values from check_wsg ().
typedef struct SSF_struct {
	DWORD	offset; 	// 32-bit offset
	WORD	segsel; 	// segment/selector value
	WORD	flags;		// flags
	WORD	group;		// group number for selector changes
	BYTE	symlen; 	// length of pascal string following
	BYTE	symname[1];	// length is unknown
} SSF, FAR *SSFp;

// Difference in bytes between SWAT internal representation of symbol record
// and what we pass to SWAT.  SWAT keeps three additional DWORDs: a resolved
// linear address with base 0, and pointers to name and address hash bucket
// chain entries.
#define SIZEDIFF	3*4

// SYM386 records and defines
// These structures and constants are used for parsing Windows Sym386 files.

// Sym386 values
#define S386_FLAT32	0	// flat 32-bit addressing
#define S386_LGROUP	1	// Locked
#define S386_IGROUP	2	// Init code
#define S386_PGROUP	3	// Unlocked
#define S386_MAXGROUP	3	// maximum group type number

#define S386_GRPSIG	0xff000000L // value S386grp.grpsig should contain

#define S386_GNMAX	0x20	// maximum group name length

// Sym386 file header
typedef struct S386hdr_struct {
	// paragraph 1
	DWORD	flen;		// # of paragraphs in file - 1
	WORD	undef1; 	// *undefined*
	WORD	numabs; 	// number of ABS entries following
	WORD	absdir; 	// offset of ABS dir from beginning of record
	WORD	unk1;		// unknown
	WORD	hdrsize;	// header size in paragraphs
	BYTE	unk2;		// 0x1f,0x17 -- may be bit mapped values
	BYTE	modnamelen;	// length of module name (pascal string)
	// paragraph 2
	BYTE	modname[0x10];	// module name (pascal string)
} S386hdr, *S386hdrp;

// Sym386 group header
typedef struct S386grp_struct {
	WORD	nextgrp;	// file offset in paras of next group --
				// last group in file points back to first
	WORD	count;		// number of symbols, including group name
	WORD	grpdir; 	// offset from beg. of record of directory
	WORD	grptype;	// S386_FLAT, S386_LGROUP, etc.
	WORD	undef1[3];	// *undefined*
	WORD	unk1;		// 0x0001 in example
	DWORD	grpsig; 	// always 0xff000000
	BYTE	grpnamelen;	// length of group name
	BYTE	grpname[S386_GNMAX];
				// group name
} S386grp, *S386grpp;

// Sym386 symbol - defined only as a pointer, since we never know the
//	length of the name
typedef struct S386sym_struct {
	DWORD	val;		// 32-bit symbol value
	BYTE	symnamelen;	// length of symbol name
	BYTE	symname[1];	// pascal string containing symbol name
} /* S386sym, */ *S386symp;

// structure used for nibbling at .SYM files
#define RSTRUCT_INITSIZE	0xc000	// initial size for rstruct
#define RSTRUCT_INITREAD	1024	// initial amount to read --
					// should be enough to get group
					// header in, must be smaller than
					// RSTRUCT_INITSIZE, & for the
					// sake of I/O performance should
					// be sector size granular.
typedef struct rstruct_str {
	char	*buff;		// actual buffer
	char	*head;		// pointer into next buffer byte available
	long	startoff;	// offset into file represented by buff
	WORD	buffsize;	// length of buffer
} rstruct, *rstructptr;

// internal structure for Windows Symbol Group files
// file structure is canonical text, one record per line
// groupnum modeid selector groupname[!segname]
// where
// groupnum is the group number (in hex) to be passed to SWAT
//	    modeid is either V (VM/RM) or P (Protected mode)
//		   selector is the PM selector (ignored if modeid==V)
//			    groupname is the name to match
//				segname is an optional segment within groupname
typedef struct WSG_struct {
	WORD	groupnum;
	char	modeid;
	WORD	selector;
	char	groupname[S386_GNMAX];
	DWORD	gbegin; 	// Set in RESOLVE_WSG if group name matches
	char	*segname;
	DWORD	segbegin,segend; // Set in RESOLVE_WSG if segment name matches
	int	keepseg:1,	// 1 to keep VM segment from map file
		reserved:15;
} WSG, *WSGp;

// if MAPSSF is undefined, declare extern's for mapssf.c
#ifndef MAPSSF

 extern int	debuglvl;
 extern WORD	groupfilt;
 extern int	append;
 extern int	defsegsel;
 extern int	defaultmode;
 extern int	segmentmode;
 extern WSGp	wsg;
 extern int	wsgcount;
 extern int	ignlines;
 extern int	byname;
 extern int	map32;
 extern char	buffer[];

#endif

