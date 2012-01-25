@echo off

echo S16CHK v0.11  Updated 10/6/93

REM Batch file to check for places where S16 or S32 may be required.
REM Requires the Borland grep, renamed as BGREP.
REM Borland's grep is shipped with all their tools.  Microsoft's
REM grep or the MKS grep (any standard grep) will not work.

REM Also checks for places where S16 or S32 are used unnecessarily with
REM REP STOS.

if "%1" == "" goto error
if "%TMP%" == "" goto tmpdef

%COMSPEC%/c >%TMP%foo
if exist %TMP%foo goto tmpset

echo You need to define the %%TMP%% environment variable with a trailing
echo backslash.  %0 could not create %TMP%foo;
echo the path may be invalid, or TMP may not have a trailing backslash.
:tmpdef
set TMP=.
echo Note: TMP environment variable not set.  Set to RAM drive for
echo faster execution (trailing backslash required).

:tmpset
echo Collecting list of all stos lines
bgrep -i -n -o "stos" %1 %2 %3 %4 %5 %6 %7 %8 %9 >%TMP%foo

echo Collecting list of all movs lines
bgrep -i -n -o "movs" %1 %2 %3 %4 %5 %6 %7 %8 %9 >>%TMP%foo

echo Eliminating movsx lines
bgrep -i -v    "^[^ ]*[ ]*[^ ]*[ ]*movsx" <%TMP%foo >%TMP%foo2

echo Eliminating movspr lines
bgrep -i -v    "^[^ ]*[ ]*[^ ]*[ ]*movspr" <%TMP%foo2 >%TMP%foo

echo Eliminating OPCODE macro lines
bgrep    -v    "^[^ ]*[ ]*[^ ]*[ ]*OPCODE" <%TMP%foo >%TMP%foo2

echo Eliminating extrn lines
bgrep -i -v    "^[^ ]*[ ]*[^ ]*[ ]*extrn" <%TMP%foo2 >%TMP%foo

echo Eliminating TMAC macro lines
bgrep    -v    "^[^ ]*[ ]*[^ ]*[ ]*TMAC" <%TMP%foo >%TMP%foo2

echo Eliminating lines where stos is in comments
bgrep -i       "^[^ ]*[ ]*[^ ]*[ ]*[^ ;]*[ ]*[^ ;]*[ ]*stos" <%TMP%foo2 >%TMP%foo

echo Eliminating lines where movs is not an opcode
bgrep -i       "^[^ ]*[ ]*[^ ]*[ ]*[^ ;]*[ ]*[^ ;]*[ ]*movs" <%TMP%foo2 >>%TMP%foo

echo Eliminating S16/stosb/w/d pairs (S16/S32 rep stos left alone)
rem vi %TMP%foo
bgrep -i -v    "^[^ ]*[ ]*[^ ]*[ ]*S16[ ]*stosb" <%TMP%foo  >%TMP%foo2
bgrep -i -v    "^[^ ]*[ ]*[^ ]*[ ]*S16[ ]*stosw" <%TMP%foo2 >%TMP%foo
bgrep -i -v    "^[^ ]*[ ]*[^ ]*[ ]*S16[ ]*stosd" <%TMP%foo  >%TMP%foo2

echo Eliminating properly matched S16/stos ?:[di] pairs
rem vi %TMP%foo2
bgrep -i -v    "^[^ ]*[ ]*[^ ]*[ ]*S16[ ]*stos.*\[di"   <%TMP%foo2 >%TMP%foo

echo Eliminating matched S32/stos ?:[edi] pairs
bgrep -i -v    "^[^ ]*[ ]*[^ ]*[ ]*S32[ ]*stos.*\[edi" <%TMP%foo  >%TMP%foo2

echo Eliminating S16/movsb/w/d pairs
bgrep -i -v    "^[^ ]*[ ]*[^ ]*[ ]*S16.*movsb" <%TMP%foo2 >%TMP%foo
bgrep -i -v    "^[^ ]*[ ]*[^ ]*[ ]*S16.*movsw" <%TMP%foo  >%TMP%foo2
bgrep -i -v    "^[^ ]*[ ]*[^ ]*[ ]*S16.*movsd" <%TMP%foo2 >%TMP%foo

echo Eliminating properly matched S16/movs ?:[di] pairs
bgrep -i -v    "^[^ ]*[ ]*[^ ]*[ ]*S16.*movs.*\[di.*\[si"   <%TMP%foo  >%TMP%foo2

echo Eliminating properly matched S32/movs ?:[edi] pairs
bgrep -i -v    "^[^ ]*[ ]*[^ ]*[ ]*S32.*movs.*\[edi.*\[esi" <%TMP%foo2 >%TMP%foo

echo Eliminating rep stos w/o S16/S32
rem vi %TMP%foo
bgrep -i -v    "^[^ ]*[ ]*[^ ]*[ ]*rep[ ]+stos" <%TMP%foo >%TMP%foo2

echo Eliminating lines with no index registers
bgrep -i -v    "S[13][62][ ]*stos[ ]*[\_A-Z0-9]*[ ]*" <%TMP%foo2 >%TMP%foo

echo Eliminating INCLUDE lines
rem vi %TMP%foo
bgrep -i -v    "^[^ ]*[ ]*[^ ]*[ ]*include" <%TMP%foo >%TMP%foo2

echo Eliminating labels
bgrep -i -v    "^[^ ]*[ ]*[^ ]*[ ]*[^ ]+:$" <%TMP%foo2 >%TMP%foo

echo Eliminating embedded STOS
bgrep -i -v    "^[^ ]*[ ]+[^ ]*.*[ ]+[^ ]+stos" <%TMP%foo >%TMP%foo2

echo Eliminating embedded MOVS
rem vi %TMP%foo2
bgrep -i -v    "^[^ ]*[ ]+[^ ]*.*[ ]+[^ ]+movs" <%TMP%foo2 >%TMP%foo

echo Sorting output
bgrep -v       "^File [^ ]*:$" <%TMP%foo | sort >%TMP%foo2

copy %TMP%foo2 %TMP%foo
del %TMP%foo2

echo Output is in %TMP%foo
dir %TMP%foo
goto end

:error
echo You must supply at least one argument (wildcards allowed)

:end
