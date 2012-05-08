#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dos.h>

int main ()
{
 char	 buff[_MAX_PATH],
	 drive[_MAX_DRIVE],
	 dir[_MAX_DIR],
	 fname[_MAX_FNAME],
	 ext[_MAX_EXT];

 do {
	printf ("Pathname to split: ");
	gets (buff);
	if (!buff[0])
		return (0);
	_splitpath (buff, drive, dir, fname, ext);
	printf ("Path =\"%s\"\n"
		"Drive=\"%s\"\n"
		"Dir  =\"%s\"\n"
		"Name =\"%s\"\n"
		"Ext  =\"%s\"\n",	buff, drive, dir, fname, ext);
 } while (1);

 return (0);

}

