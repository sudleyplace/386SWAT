static char sccsid[] = "@(#) getopt.c 1.0";

#include <stdio.h>
#include <string.h>

/*
 * get option letter from argument vector
 */
int	optind = 1;		/* index into parent argv vector */

char	*optarg,		/* argument associated with option */
	optopt; 		/* character checked for validity */

#define EMSG	""
#define tell(s) printf("%s%s%c\n", *nargv, s, optopt); return(optopt);

char getopt(nargc, nargv, ostr) // Unix-style getopt() function
int	nargc;
char	**nargv,
	*ostr;
{
	static char	*place = EMSG;	/* option letter processing */
	register char	*oli;		/* option letter list index */

	if (!*place) {			/* update scanning pointer */
		if (optind >= nargc ||
		    (*(place = nargv[optind]) != '-' && *place != '/') ||
		    !*++place) {
			return(EOF);
		}

		if (*place == '-') {    /* found "--" */
			++optind;
			return(EOF);
		}
	}				/* option letter okay? */
	if ((optopt = *place++) == (int)':' ||
			!(oli = strchr(ostr, optopt))) {
		if(!*place) ++optind;
		tell(": illegal option -- ");
	}
	if (*++oli != ':') {            /* don't need argument */
		optarg = NULL;
		if (!*place) ++optind;
	}
	else {				/* need an argument */
		if (*place) optarg = place;	/* no white space */
		else if (nargc <= ++optind) {	/* no arg */
			place = EMSG;
			tell(": option requires an argument -- ");
		}
		else optarg = nargv[optind];	/* white space */
		place = EMSG;
		++optind;
	}
	return(optopt); 		/* dump back option letter */
}



