/*' $Header$ */
/* Dump contents of SSF file */

#include <stdio.h>
#include <fcntl.h>
#include <io.h>
#include <malloc.h>
#include <sys\types.h>
#include <sys\stat.h>

typedef unsigned char		BYTE;
typedef unsigned int		WORD;
typedef unsigned long		DWORD;

#pragma pack(1)

// data for creation of .ssf file
typedef struct Ssff_str {
	BYTE	ssff_sig[4];	// Signature
	WORD	ssff_ver;	// File version
	DWORD	ssff_count;	// Number of records within file
	WORD	ssff_flags;	// Processing flags
	DWORD	ssff_data;	// File pointer to start of symbol data
} SSF_STR, *SSF_PTR;

#define SSFF_SIG	{'S','S','f','$'} // signature to identify SSF file
#define SSFF_VER	0x0011	// packed BCD file format version
				// (*NOT* in synch with program version #)

#define SSFFL_FLUSH	0x8000	// Flush table before adding
#define	SSFFL_RAW	0x4000	// Allow dupes

BYTE	SSF_SIG[] = SSFF_SIG;
SSF_PTR ssf_buf;

void error (char *msg)
{
 fprintf (stderr, "%s\n", msg);
 exit (-1);
} // error ()

char *buff;
#define BUFFSIZE	((WORD) 56000)

char symname[80];
char *symptr, *symptr0;

// SSF record definition
// Note that we declare this as a pointer, since the actual length is unknown
// until we get the symbol name length - we will always cast another
// pointer type as SSFp.  The SSF type definition is used only for getting
// default values from check_wsg ().
typedef struct SSF_struct {
	DWORD	offset; 	// 0: 32-bit offset
	WORD	segsel; 	// 4: segment/selector value
	WORD	flags;		// 6: flags
	WORD	group;		// 8: group number for selector changes
	BYTE	symlen; 	// 10: length of pascal string following
	BYTE	symname[1];	// 11: length is unknown
} SSF, *SSFp;

int main (int argc, char *argv[])
{

 int fh;
 int i, namelen;
 WORD flen;
 signed long rcnt, rtotal;

 fprintf (stderr, "SSFDump v0.10\n");
 if (argc < 2) {
	error ("No file specified.");
 }

 if (!(buff = malloc (BUFFSIZE))) error ("Unable to allocate buffer");

 if ((fh = open (argv[1],O_BINARY|O_RDONLY)) == -1) {
	error ("Unable to open file.");
 }

 if (read (fh, buff, sizeof (SSF_STR)) == -1) {
	error ("Unable to read header.");
 }

 ssf_buf = (SSF_PTR) (&(buff[0]));
 if (memcmp (SSF_SIG, ssf_buf->ssff_sig, 4) || ssf_buf->ssff_ver < 0x0010) {
	error ("Invalid header.");
 }

 if (ssf_buf->ssff_ver < 0x0011) {
	ssf_buf->ssff_data = 10L;
 }

 printf ("File version is %04x, flags are %04x, %lu records at offset %lu\n",
	ssf_buf->ssff_ver, ssf_buf->ssff_flags, rtotal = ssf_buf->ssff_count,
	ssf_buf->ssff_data);

 if (lseek (fh, ssf_buf->ssff_data, SEEK_SET) == -1) {
	error ("Unable to seek to data start.");
 }

 if ((flen = read (fh, buff, BUFFSIZE)) == -1) {
	error ("Unable to read data from file");
 }

 symptr = symptr0 = (char *) buff;
 printf ("  #    Seg Offset   Flag Grp  Name\n");
 for (rcnt = 0L; (WORD) (symptr - symptr0) < flen /* rcnt < rtotal */; rcnt++) {

	strncpy (symname, symptr+11, namelen = *((BYTE *) symptr+10));
	symname [namelen] = '\0';
	printf ("%06lu %04x:%08lx %04x %04x %s\n",
		rcnt,
		*((WORD *) (symptr+4)),
		*((DWORD *) (symptr+0)),
		*((WORD *) (symptr+6)),
		*((WORD *) (symptr+8)),
		symname);
	symptr += (11 + namelen);
	if (namelen == 0) error ("Got a name length of 0");

 } // for ...

 printf ("%lu records in file, %lu listed in header.\n", rcnt, rtotal);
 if (rcnt > rtotal) {
	printf ("%lu spurious records - you need a fixed MAPSSF.EXE\n",
		rcnt - rtotal);
 }
 close (fh);

 free (buff);

} // main ()

