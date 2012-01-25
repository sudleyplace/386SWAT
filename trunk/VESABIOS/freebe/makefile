##############################################################################
#                                                                            #
#  FreeBE/AF makefile.                                                       #
#                                                                            #
#  The default target is 'drivers', which will build all the vbeaf.drv       #
#  files. Run 'make cardname/vbeaf.drv' to compile a specific driver.        #
#                                                                            #
#  To build the install program for a binary distribution, run 'make all'.   #
#  This requires the Allegro utilties dat.exe and exedat.exe (from the       #
#  allegro/tools/ directory) to be located somewhere on your path.           #
#                                                                            #
#  To reconvert the documentation from the ._tx source, run "make docs".     #
#  This needs the Allegro makedoc utility (allegro/obj/djgpp/makedoc.exe)    #
#  to be located somewhere on your path.                                     #
#                                                                            #
#  The 'clean' target requires the rm utility from GNU fileutils.            #
#                                                                            #
##############################################################################


DRIVERS = stub ati avance cirrus54 mach64 matrox \
	  paradise s3 tgui trident tseng video7

ifdef DEBUGMODE
CFLAGS = -O -Wall -Werror
else
ifdef PGCC
CFLAGS = -O6 -mpentium -fomit-frame-pointer -Wall -Werror
else
CFLAGS = -O3 -m486 -fomit-frame-pointer -Wall -Werror
endif
endif

.PHONY: dummy drivers install all docs clean

.PRECIOUS: %.o drvgen.exe

drivers: $(addsuffix /vbeaf.drv, $(DRIVERS))

install: install.exe

all: drivers install

install.exe: install.o drivers.dat
	gcc -s -o install.exe install.o -lalleg
	-djp -q install.exe
	exedat -c -a install.exe drivers.dat

drivers.dat: $(addsuffix .dat, $(DRIVERS))
	dat -a -s1 drivers.dat $(addsuffix .dat, $(DRIVERS))

%.dat: %/vbeaf.drv %/notes.txt
	dat -a -s1 $*.dat $*/vbeaf.drv $*/notes.txt

#special target needed to force recursive makes
dummy:

%/vbeaf.drv: start.o helper.o drvgen.o dummy
	@cd $*
	make.exe -f ../makefile IFLAGS=-I.. vbeaf.drv
	@cd ..

vbeaf.drv: drvgen.exe ../start.o ../helper.o $(subst drvhdr.o ,,$(subst .c,.o,$(wildcard *.c)))
	drvgen vbeaf.drv OemExt PlugAndPlayInit StartDriver $(subst drvgen.exe ,,$^)

drvgen.exe: ../drvgen.o drvhdr.o
	gcc -s -o drvgen.exe ../drvgen.o drvhdr.o

%.o: %.c
	gcc $(CFLAGS) $(IFLAGS) -MMD -o $@ -c $<

%.o: %.s
	gcc -x assembler-with-cpp -o $@ -c $<

docs: freebe.html freebe.txt readme.txt

freebe.html: freebe._tx
	makedoc -html freebe.html freebe._tx

freebe.txt: freebe._tx
	makedoc -ascii freebe.txt freebe._tx

readme.txt: freebe._tx
	makedoc -part -ascii readme.txt freebe._tx

clean:
	-rm -v *.o */*.o *.d */*.d *.exe */*.exe *.dat */*.drv freebe.html freebe.txt readme.txt

-include *.d
