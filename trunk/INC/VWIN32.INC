; $Header$
;
; VWIN32.INC
;
; (C) Copyright 1997 Qualitas, Inc.  All rights reserved.
;
; Equates and strucs for VWIN32.VxD services

; _PageReserve flags
PR_PRIVATE	equ	80000400h
PR_SHARED	equ	80060000h
PR_SYSTEM	equ	80080000h
PR_FIXED	equ	00000008h
PR_4MEG 	equ	00000001h
PR_STATIC	equ	00000010h

; _PageDecommit flags
PD_ZEROINIT	equ	00000001h
PD_NOINIT	equ	00000002h
PD_FIXEDZERO	equ	00000003h
PD_FIXED	equ	00000004h

; _PageCommit flags
PC_FIXED	equ	00000008h
PC_LOCKED	equ	00000080h
PC_LOCKEDIFDP	equ	00000100h
PC_WRITEABLE	equ	00020000h
PC_USER 	equ	00040000h
PC_INCR 	equ	40000000h
PC_PRESENT	equ	80000000h
PC_STATIC	equ	20000000h
PC_DIRTY	equ	08000000h

; _PageCommitContig flags
PCC_ZEROINIT	equ	00000001h
PCC_NOLIN	equ	10000000h

VWIN32_GET_VER			equ 00h   ; 
VWIN32_THREAD_SWITCH		equ 01h   ; 
VWIN32_DPMI_FAULT		equ 02h   ; 
VWIN32_MMGR_FUNCTIONS		equ 03h   ; 
VWIN32_MMGR_RESERVE		equ 0300h ; _PageReserve (type, npages, flags)
VWIN32_MMGR_COMMIT		equ 0301h ; _PageCommit (pageno, npages, hpd, pagerdata, flags)
VWIN32_MMGR_DECOMMIT		equ 0302h ; _PageDecommit ()
VWIN32_MMGR_PAGEFREE		equ 0303h ; _PageFree (hMem, flags)
VWIN32_EVENT_CREATE		equ 04h   ; 
VWIN32_EVENT_DESTROY		equ 05h   ; 
VWIN32_EVENT_WAIT		equ 06h   ; 
VWIN32_EVENT_SET		equ 07h   ; 
VWIN32_PDB_INFO 		equ 08h   ; 
VWIN32_THREAD_BOOST_PRIORITY	equ 09h   ; 
VWIN32_WAIT_CRST		equ 0Ah   ; 
VWIN32_WAKE_CRST		equ 0Bh   ; 
VWIN32_SET_FAULT_INFO		equ 0Ch   ; 
VWIN32_EXIT_TIME		equ 0Dh   ; 
VWIN32_BOOST_THREAD_GROUP	equ 0Eh   ; 
VWIN32_BOOST_THREAD_STATIC	equ 0Fh   ; 
VWIN32_WAKE_IDLE_SYS		equ 10h   ; 
VWIN32_MAKE_IDLE_SYS		equ 11h   ; 
VWIN32_DELIVER_PENDING_KRNL_APC equ 12h   ; Deliver pending Kernel APCs

