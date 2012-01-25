/* This is a modified DXEGEN.C. Here are the original DXEGEN.C's
   copyright notices:

   Copyright (C) 1995 Charles Sandmann (sandmann@clio.rice.edu)
   This software may be freely distributed with above copyright, no warranty.
   Based on code by DJ Delorie, it's really his, enhanced, bugs fixed. */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <coff.h>
#include "vbeaf.h"

extern AF_DRIVER drvhdr;

void exit_cleanup(void)
{
  remove("drv__tmp.o");
}

int main(int argc, char **argv)
{
  int errors = 0;
  unsigned bss_start = 0;
  FILHDR fh;
  FILE *input_f, *output_f;
  SCNHDR sc;
  char *data, *strings;
  SYMENT *sym;
  RELOC *relocs;
  int strsz, i;
  long init1_offset,init2_offset,init3_offset,element_size,nrelocs,vbe_size;

  if (argc < 6)
  {
    printf("Usage: drvgen output.drv oemext pnpinit initdrv input.o [input2.o ... -lgcc -lc]\n");
    return 1;
  }

  input_f = fopen(argv[5], "rb");
  if (!input_f)
  {
    perror(argv[5]);
    return 1;
  }

  fread(&fh, 1, FILHSZ, input_f);
  if (fh.f_nscns != 1 || argc > 5)
  {
    char command[1024];
    fclose(input_f);

    strcpy(command,"ld -X -S -r -o drv__tmp.o -L");
    strcat(command,getenv("DJDIR"));
    strcat(command,"/lib ");
    for(i=5;argv[i];i++) {
      strcat(command,argv[i]);
      strcat(command," ");
    }
    strcat(command,"-T ../drv.ld");

    printf("%s\n",command);
    i = system(command);
    if(i)
      return i;

    input_f = fopen("drv__tmp.o", "rb");
    if (!input_f)
    {
      perror(argv[5]);
      return 1;
    } else
      atexit(exit_cleanup);

    fread(&fh, 1, FILHSZ, input_f);
    if (fh.f_nscns != 1) {
      printf("Error: input file has more than one section; use -M for map\n");
      return 1;
    }
  }

  fseek(input_f, fh.f_opthdr, 1);
  fread(&sc, 1, SCNHSZ, input_f);

  init1_offset = -1;
  init2_offset = -1;
  init3_offset = -1;
  element_size = sc.s_size;
  nrelocs = sc.s_nreloc;

  data = malloc(sc.s_size);
  fseek(input_f, sc.s_scnptr, 0);
  fread(data, 1, sc.s_size, input_f);

  sym = malloc(sizeof(SYMENT)*fh.f_nsyms);
  fseek(input_f, fh.f_symptr, 0);
  fread(sym, fh.f_nsyms, SYMESZ, input_f);
  fread(&strsz, 1, 4, input_f);
  strings = malloc(strsz);
  fread(strings+4, 1, strsz-4, input_f);
  strings[0] = 0;
  for (i=0; i<(int)fh.f_nsyms; i++)
  {
    char tmp[9], *name;
    if (sym[i].e.e.e_zeroes)
    {
      memcpy(tmp, sym[i].e.e_name, 8);
      tmp[8] = 0;
      name = tmp;
    }
    else
      name = strings + sym[i].e.e.e_offset;
#if 0
    printf("[%3d] 0x%08x 0x%04x 0x%04x %d %s\n",
	   i,
	   sym[i].e_value,
	   sym[i].e_scnum & 0xffff,
	   sym[i].e_sclass,
	   sym[i].e_numaux,
	   name
	   );
#endif
    if (sym[i].e_scnum == 0)
    {
      printf("Error: object contains unresolved external symbols (%s)\n", name);
      errors ++;
    }
    if (strncmp(name, argv[2], strlen(argv[2])) == 0)
    {
      if (init1_offset != -1)
      {
	printf("Error: multiple symbols that start with %s (%s)!\n", argv[2], name);
	errors++;
      }
      init1_offset = sym[i].e_value;
    } else if (strncmp(name, argv[3], strlen(argv[3])) == 0)
    {
      if (init2_offset != -1)
      {
	printf("Error: multiple symbols that start with %s (%s)!\n", argv[3], name);
	errors++;
      }
      init2_offset = sym[i].e_value;
    } else if (strncmp(name, argv[4], strlen(argv[4])) == 0)
    {
      if (init3_offset != -1)
      {
	printf("Error: multiple symbols that start with %s (%s)!\n", argv[4], name);
	errors++;
      }
      init3_offset = sym[i].e_value;
    } else if (strcmp(name, ".bss") == 0 && !bss_start) {
      bss_start = sym[i].e_value;
/*      printf("bss_start 0x%x\n",bss_start); */
      memset(data+bss_start, 0, sc.s_size - bss_start);
    }
    i += sym[i].e_numaux;
  }

  if (init1_offset == -1)
  {
    printf("Error: symbol %s not found!\n", argv[2]);
    errors++;
  }

  if (init2_offset == -1)
  {
    printf("Error: symbol %s not found!\n", argv[3]);
    errors++;
  }

  if (init3_offset == -1)
  {
    printf("Error: symbol %s not found!\n", argv[4]);
    errors++;
  }

  relocs = malloc(sizeof(RELOC)*sc.s_nreloc);
  fseek(input_f, sc.s_relptr, 0);
  fread(relocs, sc.s_nreloc, RELSZ, input_f);
#if 0
  for (i=0; i<sc.s_nreloc; i++)
    printf("0x%08x %3d 0x%04x - 0x%08x\n",
	   relocs[i].r_vaddr,
	   relocs[i].r_symndx,
	   relocs[i].r_type,
	   *(long *)(data + relocs[i].r_vaddr)
	   );
#endif

  fclose(input_f);
  if (errors)
    return errors;

  output_f = fopen(argv[1], "wb");
  if (!output_f)
  {
    perror(argv[1]);
    return 1;
  }

  for (i=0; i<sc.s_nreloc; i++)
    if(relocs[i].r_type == 0x14)        /* Don't do these, they are relative */
      nrelocs--;

  vbe_size=sizeof(drvhdr) + (1+nrelocs)*sizeof(long);
  drvhdr.OemExt=(void*)(vbe_size+init1_offset);
  drvhdr.PlugAndPlayInit=(void*)(vbe_size+init2_offset);
  drvhdr.InitDriver=(void*)(vbe_size+init3_offset);

  fwrite(&drvhdr, 1, sizeof(drvhdr), output_f);
  fwrite(&nrelocs, 1, sizeof(nrelocs), output_f);
  for (i=0; i<sc.s_nreloc; i++)
    if(relocs[i].r_type != 0x14)        /* Don't do these, they are relative */
      fwrite(&(relocs[i].r_vaddr), 1, sizeof(long), output_f);
  fwrite(data, 1, sc.s_size, output_f);

  fclose(output_f);
  return 0;
}
