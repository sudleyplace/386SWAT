#
# NMAKE makefile for HELLO_PM.EXE
#
# Note that you must use a linker which produces a DOS
# executable -- this means 16-bit linker, not 32-bits.
# Use a DPMI host (386MAX or DPMIONE) to run the program,
# and use 386SWAT to debug.
# DPMIONE and 386SWAT can be found at http://www.sudlyeplace.com.

MASMVER=6		# Change to 5/6 to use MASM 5.10b/6.x
PRODNAME=HELLO_PM	# Basename to use
WSG=			# No WSG file needed for debugging this program
ML=C:\Util\masm\ml
LD=C:\Util\masm\link

.asm.obj:
!IF $(MASMVER) == 6
	 $(ML) /II:\ /c /W3 /WX /Zd /Fl /Cp $< $(ASMOPT)
!ELSE
	 masm $< $(ASMOPT) /p /r /t /w1 /Zd /Ml /l;
!ENDIF

ALL:			$(PRODNAME).EXE   ##	$(PRODNAME).SSF

$(PRODNAME).EXE:	$(PRODNAME).OBJ 	$(PRODNAME).MAK
	 $(LD) @<<
	 $*
	 $*.exe
	 $*.map /line /map /cparmaxalloc:0x800 ;
<<NOKEEP

$(PRODNAME).OBJ:	$(PRODNAME).ASM

$(PRODNAME).SSF:	$(WSG)			$(PRODNAME).MAP
!IF "$(WSG)" == ""
	 mapssf -t$* $*.map
!ELSE
	 mapssf -t$* -w$*.wsg $*.map
!ENDIF

$(PRODNAME).MAP:	$(PRODNAME).EXE
