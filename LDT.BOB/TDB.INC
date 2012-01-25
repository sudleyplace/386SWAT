;' $Header:   P:/PVCS/MAX/INC/WINSTR.INV   1.3   15 Jun 1998 15:59:52   BOB  $
;
; TDB.INC
;
; Windows structures and equates
;


@MPI_SIG equ	'TP'            ; MakeProcInstance signature
@TDB_SIG equ	'DT'            ; TDB signature

TDB_STR struc			; Task Database

TDB_NEXT dw	?		; 00:  Selector of next task (0=end)
TDB_STKVEC dd	?		; 02:  SS:SP of the task when last switched away from
TDB_NEVENTS dw	?		; 06:  # events waiting for the task
TDB_PRIORITY db ?		; 08:  Priority
	db	?		; 09:  Unused???
	dw	?		; 0A:  Unused???
TDB_SEL dw	?		; 0C:  This task's selector
	dw	?		; 0E:  Unused???
	dw	?		; 10:  Unused???
	dw	?		; 12:  Unused???
TDB_FLDCW dw	?		; 14:  80x87 control word
TDB_FLAGS dw	?		; 16:  Flags (See TDBF_xxx below)
TDB_ERRFL dw	?		; 18:  Error flags (See SEM_xxx below)
TDB_MINVER dw	?		; 1A:  Minimum version of Windows to run this task
TDB_DGR dw	?		; 1C:  Instance handle (DGROUP) for this task
TDB_MOD dw	?		; 1E:  Module handle for task
TDB_TMQ dw	?		; 20:  Selector for task message queue
TDB_PARENT dw	?		; 22:  Selector of TDB parent
TDB_ASHFL dw	?		; 24:  Flags for TDB_ASH
TDB_ASH dd	?		; 26:  Application Signal Handler address
TDB_USH dd	?		; 2A:  User Signal handler address
TDB_GDNH dd	?		; 2E:  GlobalDiscard () notification handler
TDB_INT00 dd	?		; 32:  Interrupt 00h address
TDB_INT02 dd	?		; 36:  ...	 02h ...
TDB_INT04 dd	?		; 3A:  ...	 04h ...
TDB_INT06 dd	?		; 3E:  ...	 06h ...
TDB_INT07 dd	?		; 42:  ...	 07h ...
TDB_INT3E dd	?		; 46:  ...	 3Eh ...
TDB_INT75 dd	?		; 4A:  ...	 75h ...
TDB_COMPFL dd	?		; 4E:  Application compatibility flags
TDB_TIBSEL dw	?		; 52:  Thread Information Block selector
TDB_LATDB dd	?		; 54:  Linear address of Thread Database
TDB_HTASK16 dw	?		; 58:  For Win16 tasks, DGROUP handle
	db	6 dup (?)	; 5A:  Unused???
TDB_PSPSEL dw	?		; 60:  Selector of PSP
TDB_DTA dd	?		; 62:  Ptr to DTA
TDB_CURDRV db	?		; 66:  Current drive of task + 80h (origin-80)
TDB_CURDIR db	65 dup (?)	; 67:  Current directory of task
	dw	?		; A8:  Unused???
TDB_HNEXT dw	?		; AA:  hTask to be scheduled next
TDB_DLLCHAIN dd ?		; AC:  Ptr to chain of referenced DLLs
TDB_CSALIAS dw	?		; B0:  Code selector alias
TDB_MPISEL dw	?		; B2:  Selector to additional MakeProcInstance thunks
TDB_MPISIG dw	@MPI_SIG	; B4:  'PT' signature for MakeProcInstance thunks
	dw	?		; B6:  Unused???
TDB_MPINEXT dw	?		; B8:  Next available MakeProcInstance thunk
TDB_MPITHUNKS db (7*8) dup (?)	; BA:  Space for up to seven MakeProcInstance thunks
TDB_MODNAME db	8 dup (?)	; F2:  ASCIIZ Module name for task, no terminating zero if full
TDB_TDBSIG dw	@TDB_SIG	; FA:  TDB signature
	dd	?		; FC:  Unused???
TDB_PSP db	100h dup (?)	;100:  PSP

TDB_STR ends

TDBF_WINOLDAP equ	0001h
TDBF_NEWTASK  equ	0008h
TDBF_WIN32    equ	0010h

SEM_FAILCRITICALERRORS		equ 0001h
SEM_NOGPFAULTERRORBOX		equ 0002h
SEM_NOALIGNMENTFAULTEXCEPT	equ 0004h
SEM_NOOPENFILEERRORBOX		equ 8000h

