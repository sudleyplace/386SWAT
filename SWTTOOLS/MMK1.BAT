@echo off
	QLINK ret\swatrun.obj ret\swatpres.obj,ret\swatrun,ret\swatrun /noi /map /line/tiny;
	mapssf -tret\swatrun ret\swatrun.map
	masm /DLMOD /Iret /II:\ /IQ:\ /IS:\ /Zi swatcmd, ret\swatcmd ;
	link @ret\swatcmd.arf
	mapssf -tret\swatcmd ret\swatcmd.map
	cl /c /Zi /AL /Iret /I /J /Foret\swatlog.obj swatlog.c
	link @ret\swatlog.arf
	mapssf -tret\swatlog ret\swatlog.map
	cl /c /Zi /AL /Iret /I /J /Foret\libsym.obj libsym.c
	link @ret\libsym.lrf
	mapssf -tret\libsym ret\libsym.map
	xc /r ret\mapssf.exe	 D:\SOURCE\LIB\
	xc /r ret\mapssf.map	 D:\SOURCE\LIB\
	xc /r ret\mapssf.ssf	 D:\SOURCE\LIB\
	xc /r ret\swatrun.COM	 D:\SOURCE\LIB\
	xc /r ret\swatrun.map	 D:\SOURCE\LIB\
	xc /r ret\swatrun.ssf	 D:\SOURCE\LIB\
	xc /r ret\swatcmd.exe	 D:\SOURCE\LIB\
	xc /r ret\swatcmd.map	 D:\SOURCE\LIB\
	xc /r ret\swatcmd.ssf	 D:\SOURCE\LIB\
	xc /r ret\swatlog.exe	 D:\SOURCE\LIB\
	xc /r ret\swatlog.map	 D:\SOURCE\LIB\
	xc /r ret\swatlog.ssf	 D:\SOURCE\LIB\
	xc /r ret\libsym.exe	 D:\SOURCE\LIB\
	xc /r ret\libsym.ssf	 D:\SOURCE\LIB\
