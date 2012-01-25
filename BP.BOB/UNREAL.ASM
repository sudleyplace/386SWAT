	include MASM.INC
	include DOSCALL.INC

.386p
PGROUP	group	CODE,DATA

CODE	segment use16 public para 'prog' ; Start CODE segment
CODE	ends			; End CODE segment


DATA	segment use16 public para 'prog' ; Start DATA segment
DATA	ends			; End DATA segment


CODE	segment
	assume	cs:PGROUP

	NPPROC	UNREAL -- Test Unreal Mode
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Test Unreal mode

|

	mov	esi,10000h	; Get offset above 64KB
	mov	eax,ds:[esi]	; Attempt to read above 64KB

	DOSCALL @EXITRC 	; Exit the program

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UNREAL	endp			; End UNREAL procedure

CODE	ends

	MEND	UNREAL		; End UNREAL module
