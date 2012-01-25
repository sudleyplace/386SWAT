@echo off
REM Edit SWAT*.ASM and SWAT*.INC files
REM   To edit a .ASM file only, use   %0 xxx   where xxx
REM	is the three-letter file ID (e.g. VCP for SWAT_VCP.ASM).
REM   To edit a .INC file only, use   %0 . xxx	where xxx
REM	is the three-letter file ID (e.g. VCP for SWAT_VCP.INC).
REM   To edit both the .ASM and .INC files, use   %0 xxx yyy
REM	where xxx and yyy are the three-letter fiel IDs.

if "%2" == "" goto ASM
if "%1" == "." goto INC

Set PSWTASM=
if not exist swat%1.asm Set PSWTASM=%SWTDIR%
Set PSWTINC=
if not exist swat%2.inc Set PSWTINC=%SWTDIR%

call p %PSWTASM%swat%1.asm %PSWTINC%swat%2.inc

goto END

:INC
Set PSWTINC=
if not exist swat%2.inc Set PSWTINC=%SWTDIR%

call p %PSWTINC%swat%2.inc

goto END

:ASM
Set PSWTASM=
if not exist swat%1.asm Set PSWTASM=%SWTDIR%
call p %PSWTASM%swat%1.asm

:END
