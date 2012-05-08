// $Header:   P:/pvcs/misc/swttools/ssf.h_v   1.0   07 May 1996 02:42:52   HENRY  $
//
// SSF.H - Swat symbol declaration for C / C++
//
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved.
//

#ifndef _SSF_INCLUDED
#define	_SSF_INCLUDED

#ifndef DWORD

typedef unsigned char BYTE;
typedef unsigned short WORD;
typedef unsigned long DWORD;

#endif

#ifndef FAR
#define FAR __far
#endif

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

#endif

