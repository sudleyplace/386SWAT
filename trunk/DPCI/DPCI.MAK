O=RET\				# Destination directory
R=				# Generic source directory

# Which linker to use
LINK=link
AFLAGS=/W1 /p /t /Mu /r 	# MASM 5.10b options

{$(R)}.asm{$(O)}.obj:
	masm %s $(AFLAGS) /DOEM=$(OEM), $@;

ALL:	$(O)DPCI.COM	\
!IF "$(BINDIR)" != ""
	$(BINDIR)DPCI.COM
!ENDIF

OBJS=	$(O)DPCI.OBJ	\
	$(O)DPCI_MSC.OBJ

$(O)DPCI.COM:	$(OBJS)
	$(LINK) @<<$(O)DPCI.ARF
$(OBJS: =+^
)
	$(O)DPCI /tiny
	$(O)DPCI /map /line ;
<<KEEP

$(O)DPCI.OBJ:		DPCI.ASM
##	masm %s /i. /Ml /t /w1;

$(O)DPCI_MSC.OBJ:	DPCI_MSC.ASM
##	masm %s /i. /Ml /t /w1;

$(BINDIR)DPCI.COM: $(O)DPCI.COM
	copy /y %s $@

