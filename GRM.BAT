@echo off
Set PSWTASM=
if not exist 386swat.grm Set PSWTASM=%SWTDIR%
call p %PSWTASM%386swat.grm
