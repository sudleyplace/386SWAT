#
# NMAKE makefile for HELLO_PM.EXE
#

MASMVER=5		# Change to 6 to use MASM 6.x
PRODNAME=HELLO_PM	# Basename to use
WSG=			# No WSG file needed for debugging this program

.asm.obj:
!IF $(MASMVER) == 6
	 ml /c /W3 /WX /Zd /Cp $< $(ASMOPT)
!ELSE
	 masm $< $(ASMOPT) /p /r /t /w1 /Zd /Ml;
!ENDIF

ALL:			$(PRODNAME).EXE 	$(PRODNAME).SSF

$(PRODNAME).EXE:	$(PRODNAME).OBJ 	$(PRODNAME).MAK
	 link @<<
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
	 ff $*

$(PRODNAME).MAP:	$(PRODNAME).EXE

