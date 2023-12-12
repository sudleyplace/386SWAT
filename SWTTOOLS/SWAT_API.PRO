/***
 *' $Header:   P:/pvcs/misc/swttools/swat_api.prv   1.2   06 Jan 1995 18:03:50   HENRY  $
 *
 * SWAT_API.PRO
 *
 * C prototypes for functions in SWAT_API.ASM and SWATPRES.ASM
 *
 ***/

#ifndef FAR
#define FAR __far
#endif

#ifdef __cplusplus
extern "C" {
#endif

int FAR SWAT_PRESENT (void);
int FAR SWAT_ADDSYM (WORD FAR *numsymp, SSFp symtab, int allowdupes);
int FAR SWAT_FLUSHTAB (void);

#ifdef __cplusplus
}
#endif

