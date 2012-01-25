;' $Header:   P:/PVCS/MAX/INC/WINSTR.INV   1.3   15 Jun 1998 15:59:52   BOB  $
;
; MOD.INC
;
; Windows structures and equates
;

@MOD_SIG equ	'EN'            ; Module signature

MOD_STR struc			; Module

MOD_MODSIG dw	@MOD_SIG	; 00:  Module signature
MOD_USECNT dw	?		; 02:  Usage count
MOD_NPENTRY dw	?		; 04:  Near ptr to entry table
MOD_NEXT dw	?		; 06:  Selector of next module (0=end)
MOD_NPSEGDRP dw ?		; 08:  Near ptr to segment table entry for DGROUP
MOD_NPLFI dw	?		; 0A:  Near ptr to load file info (LFIxxSTRUCT)
MOD_FLAGS dw	?		; 0C:  Module flags (based on NE flags)
MOD_LSEG  dw	?		; 0E:  Logical segment # of DGROUP (1-based)
MOD_IHEAP dw	?		; 10:  Initial local heap byte size
MOD_ISTACK dw	?		; 12:  Initial stack byte size
MOD_CSIP  dd	?		; 14:  Starting CS:IP
MOD_SSSP  dd	?		; 18:  Starting SS:SP
MOD_NSEGS dw	?		; 1C:  # segments in segment table
MOD_NMREF dw	?		; 1E:  # entries in module ref table
MOD_SNRNT dw	?		; 20:  Size of non-resident names table on disk
MOD_NPSEG dw	?		; 22:  Near ptr to segment table
MOD_NPRES dw	?		; 24:  Near ptr to resource table
MOD_NPRNAM dw	?		; 26:  Near ptr to resident name table
MOD_NPMREF dw	?		; 28:  Near ptr to module reference table
MOD_NPINAM dw	?		; 2A:  Near ptr to imported names table
MOD_ONRNT dd	?		; 2C:  File offset of non-resident name table
MOD_NMOVE dw	?		; 30:  # moveable entries in entry table
MOD_SHIFT dw	?		; 32:  Alignment shift count
MOD_TTFNT dw	?		; 34:  Set to 2 if True Type font
MOD_OSFLG db	?		; 36:  Operating system flags
MOD_OTHER db	?		; 37:  Other flags
MOD_SAME1 dw	?		; 38:  Same as offset 2Ah
MOD_SAME2 dw	?		; 3A:  Same as offset 2Ah except in KERNEL
MOD_SWAP  dw	?		; 3C:  Minimum swap area size for this module
MOD_EXPWV dw	?		; 3E:  Expected Windows version #
MOD_PE_RVA dd	?		; 40:  PE-only RVA of PE file
MOD_PE_BASE dd	?		; 44:  PE-only LA of PE file base
MOD_PE_RSRC dd	?		; 48:  PE-only LA of PE file resources

MOD_STR ends

MDBF_DLL	equ 8000h	; It's a DLL
MDBF_CALL_WEP	equ 4000h	; Call WEP on unload
MDBF_SELF_LOAD	equ 0800h	; Uses self-loading mechanism
MDBF_TEXTMODE	equ 0200h	; Console app
MDBF_FULLSCREEN equ 0100h	; Writes into video buffer
MDBF_PRELOAD	equ 0040h	; Load when module is loaded rather than when accessed
MDBF_WIN32	equ 0010h	; Win32 PE file
MDBF_AUTODATA	equ 0002h	; Each module gets separate DGROUP
MDBF_SINGLEDATA equ 0001h	; Single DGROUP for all instances


MDBF_DATA     equ 0001h 	; Set = Data segment, Clr = Code segment
MDBF_ITERATED equ 0008h 	; Contains run length encoded data
MDBF_MOVEABLE equ 0010h 	; Set = Moveable in linear memory, Clr = FIXED
MDBF_PRELOAD  equ 0040h 	; Load when module is loaded rather than when accessed
MDBF_RELOC    equ 0100h 	; Contains relocation data
MDBF_DISCARD  equ 1000h 	; Discardable
MDBF_32BIT    equ 2000h 	; 32-bit code segment

