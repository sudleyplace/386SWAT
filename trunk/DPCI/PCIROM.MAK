
P=PCIROM		# Program name
O=RET\			# Destination directory
R=				# Generic source directory

# Default options for MASM
MOPT=/ml /p /r /t /w1

# Which linker to use
LINK=qlink

{$(R)}.asm{$(O)}.obj:
	masm %s /DOEM=$(OEM) $(MOPT), $@;

ALL:				$(O)$(P).COM	\
!IF "$(BINDIR)" != ""
		$(BINDIR)$(P).COM
!ENDIF

OBJS=	$(O)$(P).OBJ

$(O)$(P).COM:		$(OBJS)
	$(LINK) @<<$(O)$(P).ARF
$(OBJS: =+^
)
	$(O)$(P) /tiny
	$(O)$(P) /map /line ;
<<KEEP

$(O)$(P).OBJ:		$(P).ASM
##	masm %s /i. /Ml /t /w1;

$(BINDIR)$(P).COM:	$(O)$(P).COM
	copy /y %s $@

