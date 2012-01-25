;' $Header:   P:/PVCS/386SWAT/SWAT_MEM.ASV   1.20   10 Aug 1998 11:01:16   BOB  $
	 title	 SWAT_MEM -- 386SWAT Memory Display Routines
	 page	 58,122
	 name	 SWAT_MEM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include KEYCODE.INC
	include BITFLAGS.INC
	include PDTGRP.INC
	include ALLMEM.INC

	include SWAT_COM.INC
	include SWAT_FMT.INC
	include SWAT_MOD.INC
	include SWAT_SEG.INC
	include SWAT_SYM.INC
.list

DATA16	 segment use32 dword public 'data' ; Start DATA16 segment
	 assume  ds:DGROUP

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	 extrn	 COMMON:tbyte
	 include QMAX_FIL.INC

	 extrn	 DEFATTR:byte
	 extrn	 TTLATTR:byte

	 extrn	 PaLCLPDIR:dword
	 extrn	 PLCLPDIR:dword

DATA16	 ends			; End DATA16 segment


DATA	 segment use32 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	public	@SWAT_MEM_DATA
@SWAT_MEM_DATA label byte	; Mark module start in .MAP file

	 extrn	 CON4KB:dword

	 extrn	 MEMOFF:dword
	 extrn	 SCROFF:dword

	 public  MEMSIZE,MEMMODE,MEMSEL,MEMGRAN,MEMBASE,MEMMASK,MEMCR3
MEMSIZE  dd	 ?		; Size of one row of type MEMTYPE
MEMMODE  dw	 0		; Memory mode (default = PM)
MEMSEL	 dw	 0		; Memory selector/segment
MEMGRAN  dd	 1		; # bytes in memory type (byte is the default)
MEMBASE  dd	 ?		; Memory base
MEMMASK  dd	 0FFFFFFFFh	; Memory mask (32 or 16 bits)
MEMCR3	 dd	 ?		; CR3 to use in physical memory translation

	public	MEMCNT
MEMCNT	dd	@BYTE_CNT	; # elements to display per line (byte is default)
	dd	@WORD_CNT
	dd	@DWORD_CNT
	dd	@VECT_CNT
	dd	@GDT_CNT
	dd	@IDT_CNT
	dd	@TSS_CNT

	 public  MEMTYPE
MEMTYPE  dd	 @MEM_BYTE	; Memory type
@MEM_BYTE  equ	 0
@MEM_WORD  equ	 1
@MEM_DWORD equ	 2
@MEM_VECT  equ	 3
@MEM_GDT   equ	 4
@MEM_IDT   equ	 5
	 public  @MEM_TSS
@MEM_TSS   equ	 6

@BYTE_CNT  equ	 16		; # elements displayed in one row
@WORD_CNT  equ	  8
@DWORD_CNT equ	  8
@VECT_CNT  equ	  4
@GDT_CNT   equ	  1
@IDT_CNT   equ	  1
@TSS_CNT   equ	  1

@BYTE_LEN  equ	 @BYTE_CNT * 1	; Length of one row in bytes
@WORD_LEN  equ	 @WORD_CNT * 2
@DWORD_LEN equ	 @DWORD_CNT* 4
@VECT_LEN  equ	 @VECT_CNT * 4
@GDT_LEN   equ	 @GDT_CNT  * 8
@IDT_LEN   equ	 @IDT_CNT  * 8
@TSS_LEN   equ	 @TSS_CNT  * (size TSS_STR)

	 public  MEMACT
MEMACT	 dd	 offset PGROUP:MEM_BYTE ; Action routines to display the data by type
	 dd	 offset PGROUP:MEM_WORD
	 dd	 offset PGROUP:MEM_DWORD
	 dd	 offset PGROUP:MEM_VECT
	 dd	 offset PGROUP:MEM_GDT
	 dd	 offset PGROUP:MEM_IDT
	 dd	 offset PGROUP:MEM_TSS

	 public  MEMHDR
MEMHDR	 dd	 offset PGROUP:HDR_BYTE ; Action routines to display the header by type
	 dd	 offset PGROUP:HDR_WORD
	 dd	 offset PGROUP:HDR_DWORD
	 dd	 offset PGROUP:HDR_VECT
	 dd	 offset PGROUP:HDR_GDT
	 dd	 offset PGROUP:HDR_IDT
	 dd	 offset PGROUP:HDR_TSS

	public	MEMCNTMAX
MEMCNTMAX dd	17		; Maximum # bytes we can display per line
	dd	14		; ...	    words ...
	dd	 8		; ...	    dwords ...
	dd	 6		; ...	    vectors ...
	dd	 1		; ...	    GDTs ...
	dd	 1		; ...	    IDTs ...
	dd	 1		; ...	    TSSs ...

	 public  TSSTYPE
TSSTYPE  dw	 @TSS386	; TSS type:  286 or 386

	 public  MSG_SELSEG	; Segment/selector message
MSG_SELSEG db	 'Se'
MSG_SELSEG1 db	 '_ '
MSG_SELSEG2 db	 '____'
MSG_SELSEG3 db	 '_ ',0

	 public  MSG_BYTE,MSG_WORD,MSG_DWORD,MSG_VECT,MSG_PHYS,MSG_PCR3
MSG_BYTE db	 'Byte Display',0 ; Header text by type
MSG_WORD db	 'Word Display',0
MSG_DWORD db	 'Dword Display',0
MSG_VECT db	 'Vector Display',0
MSG_PHYS db	 ' -- PHYSICAL',0
MSG_PCR3 db	 ' via '
MSG_PCR3A db	 '________',0

	public	MSG_MEMCNT
MSG_MEMCNT db	' -- Count =  '
MSG_MEMCNT1 db	'x',0

	 public  MSG_IDTMEM
MSG_IDTMEM db	 ' Sel|Offset    ' ; IDT header
	 db	 '(Lin Addr) '
	 db	 'A/R '
	 db	 'Type PL  '
	 db	 'Class'
	 db	 0

	 public  MSG_GDTMEM
MSG_GDTMEM db	 'Base Addr '   ; GDT header
	 db	 'Limit     '
	 db	 'A/R  '
	 db	 'Type PL  '
	 db	 'Class'
	 db	 0

	 public  MSG_TSSL
MSG_TSSL db	 ' TSS',0       ; TSS header

	 public  BLANK4
BLANK4	 db	 4 dup (' '),0  ; Blank filler

@DSYMBOL_MAX	 equ	 50	; Maximum length for symbol display
	 public  DSYMBOL_TXT,DSYMBOL_NAME
DSYMBOL_TXT db	 '  ('          ; Beginning of ASCIIZ to display for symbol name
DSYMBOL_NAME db  @DSYMBOL_MAX dup (?) ; Work space for copying symbol name
	db	')',0

DATA	 ends			; End DATA segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	public	@SWAT_MEM_PROG
@SWAT_MEM_PROG: 		; Mark module start in .MAP file

	 extrn	 DISPHEX2:near
	 extrn	 DISPHEX4:near
	 extrn	 DISPTXT:near
	 extrn	 DISPASCIIZ:near
	 extrn	 BIN2WORD:near
	 extrn	 DD2HEX:near
	 extrn	 NEXTLINE:near
	 extrn	 REMROW:near
	 extrn	 CLEAR_EOL:near
	 extrn	 CLEAR_EOP:near
	 extrn	 DISP_DTE:near
	 extrn	 DISP_IDTLIN:near
	 extrn	 DISP_TSSMEM:near
	 extrn	 FLUSH_CACHE:near

	 extrn	 INST_OPR0E:near
	 extrn	 REST_OPR0E:near
	 extrn	 DBGET:near
	 extrn	 DWGET:near
	 extrn	 DDGET:near
	extrn	DD2DEC:near

	 extrn	 SYMHASH_SRCH:near

	 NPPROC  DISP_MEM -- Display Memory
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display memory from MEMOFF + MEMBASE using MEMCR3 if @MODE_PHYS set.

|

	 REGSAVE <eax,ebx,ecx,esi,edi> ; Save registers

	 mov	 SCROFF,0	; Start at top of screen

	 mov	 esi,MEMTYPE	; Get memory type
	 mov	 eax,MEMGRAN	; Get the granularity
	 imul	 eax,MEMCNT[esi*(type MEMCNT)] ; Times the element count
	 mov	 MEMSIZE,eax	; Save for later use
	 mov	 ebx,MEMACT[esi*(type MEMACT)] ; Get address of action routine

	 call	 MEMHDR[esi*(type MEMHDR)] ; Display the header (if any)
	 call	 NEXTLINE	; Skip to next line, first column

	 call	 REMROW 	; Return with ECX = # remaining rows
	 dec	 ecx		; Back off to allow room for command line

	 REGSAVE <MEMOFF,MEMBASE> ; Save offset and base

	 test	 MEMMODE,@MODE_PHYS ; Izit in physical mode?
	 jz	 short DISPMEM_NEXTROW ; Jump if not

	 push	 MEMCR3 	; Pass new CR3 to use (if non-zero)
	 push	 MEMBASE	; Pass base memory to use
	 push	 MEMOFF 	; Pass memory offset to use
	 call	 DISPPHYS	; Setup for physical memory display

	 mov	 MEMBASE,eax	; Save as new base address
DISPMEM_NEXTROW:
	 mov	 eax,MEMOFF	; Get starting address

	 test	 MEMMODE,@MODE_VM ; Izit VM86 mode?
	 jnz	 short DISPMEM_NEXTROW1 ; Yes

	 call	 DISPHEX4	; Display the dword

	 jmp	 short DISPMEM_NEXTROW2 ; Join common code

DISPMEM_NEXTROW1:
	 lea	 esi,BLANK4	; Blank filler
	 call	 DISPASCIIZ	; Display ASCIIZ string from ESI

	 call	 DISPHEX2	; Display the word
DISPMEM_NEXTROW2:
	 mov	 al,'³'         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 call	 ebx		; Call appropriate routine
	 jc	 short @F	; Jump if that's all

	 loop	 DISPMEM_NEXTROW ; Jump if more rows to display
@@:
	 test	 MEMMODE,@MODE_PHYS ; Izit in physical mode?
	 jz	 short @F	; Jump if not

	 call	 DISPVIRT	; Restore virtual mode display
@@:
	 REGREST <MEMBASE,MEMOFF> ; Restore offset and base

	 REGREST <edi,esi,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_MEM endp			; End DISP_MEM procedure
	 NPPROC  DISPPHYS -- Setup For Physical Memory Display
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Setup for physical memory display

Note we round down to a 64KB boundary in case we're displaying
in VM which wraps at 64KB.

On exit:

EAX	 =	 new base memory address

|

DP1_STR  struc			; Incoming stack structure

DP1_PTE  dd	 17 dup (?)	; 68KB's worth of PTEs in PDE
DP1_PDE  dd	 ?		; PDE
DP1_EBP  dd	 ?		; Caller's EBP
DP1_EIP  dd	 ?		; ...	   EIP
DP1_OFF  dd	 ?		; ...	   offset
DP1_BASE dd	 ?		; ...	   base address
DP1_CR3  dd	 ?		; ...	   CR3 (if non-zero)

DP1_STR  ends


DP2_STR  struc			; Outgoing stack structure

DP2_EBP  dd	 ?		; Caller's EBP
DP2_EIP  dd	 ?		; ...	   EIP
DP2_OFF  dd	 ?		; ...	   offset
DP2_BASE dd	 ?		; ...	   base address
DP2_CR3  dd	 ?		; ...	   CR3 (if non-zero)
DP2_PTE  dd	 (length DP1_PTE) dup (?) ; xxKB's worth of PTEs in PDE
DP2_PDE  dd	 ?		; PDE

DP2_STR  ends

	 push	 ebp		; Prepare to address the stack
	 sub	 esp,DP1_EBP-DP1_PTE ; Make room for extra items
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ebx,ecx,esi,edi,es> ; Save registers

; Transfer from DP1_STR to DP2_STR

	 push	 [ebp].DP1_EBP	; Get original EBP
	 push	 [ebp].DP1_EIP	; ...	       EIP
	 push	 [ebp].DP1_OFF	; ...	       offset
	 push	 [ebp].DP1_BASE ; ...	       base
	 push	 [ebp].DP1_CR3	; ...	       CR3
	 pop	 [ebp].DP2_CR3	; Put into new place
	 pop	 [ebp].DP2_BASE ; ...
	 pop	 [ebp].DP2_OFF	; ...
	 pop	 [ebp].DP2_EIP	; ...
	 pop	 [ebp].DP2_EBP	; ...

	 mov	 eax,cr0	; Get register with Paging bit

	 test	 eax,mask $PG	; Izit enabled?
	 jnz	 short DISPPHYS_PG ; Jump if so

; Paging isn't enabled.  Parse the incoming address as per the specified CR3.

; Note that this technique doesn't work if the linear address
; (plus an unspecified length) spans a 4MB boundary and the
; corresponding PDEs and PTEs aren't physically consecutive.

	mov	eax,[ebp].DP2_BASE ; Get the base address

	mov	ebx,[ebp].DP2_CR3 ; Get the specified CR3
	and	ebx,@PTE_FRM	; Isolate the 4KB frame
	jz	near ptr DISPPHYS_EXIT ; Jump if it's invalid

	 add	 eax,[ebp].DP2_OFF ; Plus the offset
	 and	 eax,mask $LA_DIR ; Isolate the directory index
	 shr	 eax,$LA_DIR	; Shift to low-order

	 mov	 ebx,AGROUP:[ebx+eax*4] ; Get the PDE
	 and	 ebx,@PTE_FRM	; Isolate the 4KB frame

	 mov	 eax,[ebp].DP2_BASE ; Get the base address
	 add	 eax,[ebp].DP2_OFF ; Plus the offset
	 and	 eax,mask $LA_PAGE ; Isolate the page index
	 shr	 eax,$LA_PAGE	; Shift to low-order

	 mov	 ebx,AGROUP:[ebx+eax*4] ; Get the PTE
	 and	 ebx,@PTE_FRM	; Isolate the 4KB frame
	 mov	 eax,[ebp].DP2_BASE ; Get the base address

	 add	 eax,[ebp].DP2_OFF ; Plus the offset
	 and	 eax,mask $LA_OFF ; Isolate the offset
;;;;;;;; shr	 eax,$LA_OFF	; Shift to low-order

	 add	 eax,ebx	; Add to get the new offset
	 sub	 eax,[ebp].DP2_OFF ; Less the original offset
				; to get the new base memory address
	 jmp	 DISPPHYS_EXIT	; Join common exit code

; Establish addressibility to our local PDIR

DISPPHYS_PG:
	 mov	 es,COMMON.FILE_CR3 ; Get selector of our CR3
	 assume  es:PDTGRP	; Tell the assembler about it

; ES:0 = linear address of 1st level PDIR (CR3)

	 mov	 ebx,PLCLPDIR	; Get offset to our local PDIR

	 mov	 eax,OFFPDT[@PDELOC] ; Get the PDE there (if any)
	 mov	 [ebp].DP2_PDE,eax ; Save to restore later

	 mov	 ecx,length DP2_PTE ; Get # PTEs to save
	 xor	 esi,esi	; Zero index register
@@:
	 mov	 eax,DGROUP:[ebx+esi] ; Get next PDE in our local PDIR
	 mov	 [ebp+esi].DP2_PTE,eax ; Save to restore later

	 add	 esi,type DP2_PTE ; Skip to next PTE

	 loop	 @B		; Jump if more PTEs to save

; Setup new PTEs in PDE

	 mov	 eax,PaLCLPDIR	; Get physical address of our local PDIR
	 or	 ax,@PTE_URP	; Mark as User/Read-write/Present
	 mov	 OFFPDT[@PDELOC],eax ; Save as new PDE

; At this point, our local PDIR maps the addresses at AGROUP:@PDELIN

	 cmp	 [ebp].DP2_CR3,0 ; Izit one-to-one?
	 jne	 short DISPPHYS_CR3 ; No, use a specific CR3

	 mov	 eax,[ebp].DP2_BASE ; Get the base address
	 add	 eax,[ebp].DP2_OFF ; Plus the offset
	 xor	 ax,ax		; Isolate the 64KB frame

	 or	 ax,@PTE_URP	; Mark as user/read-write/present
	 mov	 ecx,length DP2_PTE ; Get # PTEs to save
	 xor	 esi,esi	; Zero index register
@@:
	 mov	 DGROUP:[ebx+esi],eax ; Save in local PDIR
	 add	 eax,CON4KB	; Skip to next PTE

	 add	 esi,type DP2_PTE ; Skip to next PTE

	 loop	 @B		; Jump if more PTEs to set

	 call	 FLUSH_CACHE	; Flush the TLB

; The physical address of [ebp].DP2_BASE + [ebp].DP2_OFF
; (rounded down to 64KB boundary) is now addressible at AGROUP:@PDELIN

	 jmp	 short DISPPHYS_COM ; Join common code

; Find the physical address which corresponds to [ebp].DP2_BASE + [ebp].DP2_OFF
; (rounded down to 64KB boundary) in the target CR3

DISPPHYS_CR3:
	 mov	 edi,[ebp].DP2_BASE ; Get the base address
	 add	 edi,[ebp].DP2_OFF ; Plus the offset
	 xor	 di,di		; Isolate the 64KB frame

	 mov	 ecx,length DP2_PTE ; Get # PTEs to save
	 xor	 esi,esi	; Zero index register
@@:
	 call	 DISPPHYS_SUB	; Find PTE for EDI in [ebp].DP2_CR3
				; and save into DGROUP:[EBX+ESI]
				; incrementing ESI and EDI

	 loop	 @B		; Jump if more PTEs to find

COMMENT|

@PDELIN maps ([ebp].DP2_BASE + [ebp].DP2_OFF) & FFFF0000

Calculate new BASE such that for any OFF in [0,64K) (to handle 64KB wrap)

BASE + OFF == (DP2_BASE + OFF) + @PDELIN - ((DP2_BASE + DP2_OFF) & FFFF0000)

|

DISPPHYS_COM:
	 mov	 eax,@PDELIN	; Get the new base address
	 mov	 ebx,[ebp].DP2_BASE ; Get the base address
	 add	 ebx,[ebp].DP2_OFF ; Plus the offset
	 xor	 bx,bx		; Isolate the 64KB frame
	 sub	 eax,ebx	; Subtract to get new base address
	 add	 eax,[ebp].DP2_BASE ; Plus the original base address
DISPPHYS_EXIT:
	 REGREST <es,edi,esi,ecx,ebx> ; Restore
	 assume  es:DGROUP	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 3*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPPHYS endp			; End DISPPHYS procedure
	 NPPROC  DISPPHYS_SUB -- Subroutine to DISPPHYS
	 assume  ds:DGROUP,es:PDTGRP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Subroutine to DISPPHYS.

Find the PTE in [ebp].DP2_CR3 corresponding to EDI
and save it into LCLPDIR

On entry:

EDI	 =	 linear address whose PTE we're to find
DGROUP:[EBX] ==> LCLPDIR
ESI	 =	 index from EBX of next available address in LCLPDIR
SS:EBP	 ==>	 DP2_STR

On exit:

ESI	 =	 (updated)
EDI	 =	 (updated)

|

	 REGSAVE <eax,ecx>	; Save registers

	 push	 DGROUP:[ebx].EDD ; Save current value

	 mov	 eax,[ebp].DP2_CR3 ; Get the target CR3
	 or	 ax,@PTE_URP	; Mark as user/read-write/present
	 mov	 DGROUP:[ebx],eax ; Save in local PDIR
	 call	 FLUSH_CACHE	; Flush the TLB

	 mov	 ecx,@PDELIN	; Copy base address to overcome bug in MASM 5.1

; The target CR3 is now addressible at AGROUP:@PDELIN

	 mov	 eax,edi	; Copy linear address
	 and	 eax,mask $LA_DIR ; Isolate PDIR
	 shr	 eax,$LA_DIR	; Shift to low-order
	 mov	 eax,AGROUP:[ecx+eax*(type OFFPDT)] ; Get the PDE
	 and	 ax,mask $PTE_FRM ; Isolate the 4KB frame
	 or	 ax,@PTE_URP	; Mark as user/read-write/present
	 mov	 DGROUP:[ebx],eax ; Save in local PDIR
	 call	 FLUSH_CACHE	; Flush the TLB

; The corresponding PDE is now addressible at AGROUP:@PDELIN

	 mov	 eax,edi	; Copy linear address
	 and	 eax,mask $LA_PAGE ; Isolate page
	 shr	 eax,$LA_PAGE	; Shift to low-order
	 mov	 eax,AGROUP:[ecx+eax*(type OFFPDT)] ; Get the PTE
	 and	 ax,mask $PTE_FRM ; Isolate the 4KB frame
	 or	 ax,@PTE_URP	; Mark as user/read-write/present

	 pop	 DGROUP:[ebx].EDD ; Restore original value

	 mov	 DGROUP:[ebx+esi],eax ; Save in local PDIR
	 call	 FLUSH_CACHE	; Flush the TLB

	 add	 esi,type DP2_PTE ; Skip to next PTE
	 add	 edi,CON4KB	; Skip to next linear address

	 REGREST <ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPPHYS_SUB endp		; End DISPPHYS_SUB procedure
	 NPPROC  DISPVIRT -- Restore Virtual Mode Display
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Restore PDE and PTEs setup in DISPPHYS.

|

DV_STR	 struc			; Incoming stack structure

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
DV_PTE	 dd	 (length DP2_PTE) dup (?) ; xxKB's worth of PTEs in PDE
DV_PDE	 dd	 ?		; PDE

DV_STR	 ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ebx,ecx,esi,es> ; Save registers

	 mov	 eax,cr0	; Get register with Paging bit

	 test	 eax,mask $PG	; Izit enabled?
	 jz	 short DISPVIRT_EXIT ; Jump if not

; Establish addressibility to our local PDIR

	 mov	 es,COMMON.FILE_CR3 ; Get selector of our CR3
	 assume  es:PDTGRP	; Tell the assembler about it

; ES:0 = linear address of 1st level PDIR (CR3)

	 mov	 ebx,PLCLPDIR	; Get offset to our local PDIR

	 mov	 eax,[ebp].DV_PDE ; Get original PDE
	 mov	 OFFPDT[@PDELOC],eax ; Restore

	 mov	 ecx,length DV_PTE ; Get # PTEs to restore
	 xor	 esi,esi	; Zero index register
@@:
	 mov	 eax,[ebp+esi].DV_PTE ; Get original next PTE
	 mov	 DGROUP:[ebx+esi],eax ; Restore

	 add	 esi,type DV_PTE ; Skip to next PTE

	 loop	 @B		; Jump if more PTEs to save

	 call	 FLUSH_CACHE	; Flush the TLB
DISPVIRT_EXIT:
	 REGREST <es,esi,ecx,ebx,eax> ; Restore
	 assume  es:DGROUP	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 DP1_EBP-DP1_PTE ; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPVIRT endp			; End DISPVIRT procedure
	 NPPROC  MEMACT_B -- Memory Key Byte Mode
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Memory key for byte mode

|

	 mov	 MEMGRAN,1	; Save as # bytes in a byte

	 cmp	 MEMTYPE,@MEM_BYTE ; Same as before?
	 mov	 MEMTYPE,@MEM_BYTE ; Mark as byte mode
	 je	 short @F	; Jump if so

	 or	 MEMMODE,@MODE_NEW ; Mark as new mode
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMACT_B endp			; End MEMACT_B procedure
	 NPPROC  MEMACT_W -- Memory Key Word Mode
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Memory key for word mode

|

	 mov	 MEMGRAN,2	; Save as # bytes in a word

	 cmp	 MEMTYPE,@MEM_WORD ; Same as before?
	 mov	 MEMTYPE,@MEM_WORD ; Mark as word mode
	 je	 short @F	; Jump if so

	 or	 MEMMODE,@MODE_NEW ; Mark as new mode
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMACT_W endp			; End MEMACT_W procedure
	 NPPROC  MEMACT_D -- Memory Key Dword Mode
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Memory key for dword mode

|

	 mov	 MEMGRAN,4	; Save as # bytes in a dword

	 cmp	 MEMTYPE,@MEM_DWORD ; Same as before?
	 mov	 MEMTYPE,@MEM_DWORD ; Mark as dword mode
	 je	 short @F	; Jump if so

	 or	 MEMMODE,@MODE_NEW ; Mark as new mode
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMACT_D endp			; End MEMACT_D procedure
	 NPPROC  MEMACT_V -- Memory Key Vector Mode
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Memory key for vector mode

|

	 mov	 MEMGRAN,4	; Save as # bytes in a vector

	 cmp	 MEMTYPE,@MEM_VECT ; Same as before?
	 mov	 MEMTYPE,@MEM_VECT ; Mark as vector mode
	 je	 short @F	; Jump if so

	 or	 MEMMODE,@MODE_NEW ; Mark as new mode
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMACT_V endp			; End MEMACT_V procedure
	 NPPROC  MEMACT_G -- Memory Key GDT Mode
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Memory key for GDT mode

|

	 mov	 MEMGRAN,8	; Save as # bytes in a GDT entry

	 cmp	 MEMTYPE,@MEM_GDT ; Same as before?
	 mov	 MEMTYPE,@MEM_GDT ; Mark as GDT mode
	 je	 short @F	; Jump if so

	 or	 MEMMODE,@MODE_NEW ; Mark as new mode
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMACT_G endp			; End MEMACT_G procedure
	 NPPROC  MEMACT_I -- Memory Key IDT Mode
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Memory key for IDT mode

|

	 mov	 MEMGRAN,8	; Save as # bytes in an IDT entry

	 cmp	 MEMTYPE,@MEM_IDT ; Same as before?
	 mov	 MEMTYPE,@MEM_IDT ; Mark as IDT mode
	 je	 short @F	; Jump if so

	 or	 MEMMODE,@MODE_NEW ; Mark as new mode
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMACT_I endp			; End MEMACT_I procedure
	 NPPROC  MEMACT_T -- Memory Key TSS Mode
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Memory key for TSS mode

|

	 mov	 MEMGRAN,size TSS_STR ; Save as # bytes in a TSS entry

	 cmp	 MEMTYPE,@MEM_TSS ; Same as before?
	 mov	 MEMTYPE,@MEM_TSS ; Mark as TSS mode
	 je	 short @F	; Jump if so

	 or	 MEMMODE,@MODE_NEW ; Mark as new mode
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMACT_T endp			; End MEMACT_T procedure
	 NPPROC  DSPBYTE -- Get And Display Next Byte
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get and display the next byte from MEMBASE+MEMOFF.

On entry:

MEMBASE  =	 base of memory to retrieve
MEMOFF	 =	 offset ...

On exit:

MEMOFF	 =	 (updated)

|

	 REGSAVE <ebx>		; Save register

	 mov	 ebx,MEMBASE	; GS:ESI ==> base  of memory to display
	 add	 ebx,MEMOFF	; GS:ESI ==> start ...

;;;;;;;; mov	 al,gs:[ebx+0]	; Get the byte to format
	 PUSHD	 1		; Pass text display flag
	 PUSHD	 0		; Pass offset as argument
	 call	 DBGET		; Get and display a byte

	 inc	 MEMOFF 	; Skip to the next offset
	 mov	 ebx,MEMMASK	; Get the mask value
	 and	 MEMOFF,ebx	; Mask off wrapped bits (if VM86 mode)

	 REGREST <ebx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DSPBYTE  endp			; End DSPBYTE procedure
	 NPPROC  GETBYTE -- Get, Format, And Display Next Byte
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get, format, and display the next byte from MEMBASE+MEMOFF.

On entry:

MEMBASE  =	 base of memory to retrieve
MEMOFF	 =	 offset ...

On exit:

MEMOFF	 =	 (updated)

|

GETB_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
GETB_OFF dd	 ?		; ...	   offset

GETB_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ebx>		; Save register

	 mov	 ebx,MEMBASE	; GS:ESI ==> base  of memory to display
	 add	 ebx,MEMOFF	; GS:ESI ==> start ...

;;;;;;;; mov	 al,gs:[ebx+0]	; Get the byte to format

	 PUSHD	 0		; Pass hex display flag
	 push	 [ebp].GETB_OFF ; Pass offset as argument
	 call	 DBGET		; Get, format, and display a byte

	 inc	 MEMOFF 	; Skip to the next offset
	 mov	 ebx,MEMMASK	; Get the mask value
	 and	 MEMOFF,ebx	; Mask off wrapped bits (if VM86 mode)

	 REGREST <ebx>		; Restore

	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETBYTE  endp			; End GETBYTE procedure
	 NPPROC  GETWORD -- Get, Format, And Display Word
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get, format, and display the next word.

On entry:

MEMBASE  =	 base of memory to retrieve
MEMOFF	 =	 offset ...

On exit:

MEMOFF	 =	 (updated)

|

GETW_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
GETW_OFF dd	 ?		; ...	   offset

GETW_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ebx>		; Save register

	 mov	 ebx,MEMBASE	; GS:EBX ==> base  of memory to display
	 add	 ebx,MEMOFF	; GS:EBX ==> start ...

;;;;;;;; mov	 ax,gs:[ebx+0]	; Get the word to format
	 push	 [ebp].GETW_OFF ; Pass offset as argument
	 call	 DWGET		; Get, format, and display a word

	 add	 MEMOFF,2	; Skip to the next offset
	 mov	 ebx,MEMMASK	; Get the mask value
	 and	 MEMOFF,ebx	; Mask off wrapped bits (if VM86 mode)

	 REGREST <ebx>		; Restore

	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETWORD  endp			; End GETWORD procedure
	 NPPROC  GETDWORD -- Get, Format, And Display Dword
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get, format, and display the next dword.

On entry:

MEMBASE  =	 base of memory to retrieve
MEMOFF	 =	 offset ...

On exit:

MEMOFF	 =	 (updated)

|

GETD_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
GETD_OFF dd	 ?		; ...	   offset

GETD_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ebx>		; Save register

	 mov	 ebx,MEMBASE	; GS:EBX ==> base  of memory to display
	 add	 ebx,MEMOFF	; GS:EBX ==> start ...

;;;;;;;; mov	 eax,gs:[ebx+0] ; Get the dword to format
	 push	 [ebp].GETD_OFF ; Pass offset as argument
	 call	 DDGET		; Get, format, and display a dword

	 add	 MEMOFF,4	; Skip to the next offset
	 mov	 ebx,MEMMASK	; Get the mask value
	 and	 MEMOFF,ebx	; Mask off wrapped bits (if VM86 mode)

	 REGREST <ebx>		; Restore

	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETDWORD endp			; End GETDWORD procedure
	 NPPROC  MEM_BYTE -- Display Byte Memory
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display one row of memory in byte format.

On entry:

MEMBASE  =	 base of memory to display
MEMOFF	 =	 offset ...

On exit:

MEMOFF	 =	 (updated)
CF	 =	 0 to continue with next row
	 =	 1 to stop with this row

|

	 REGSAVE <eax,ecx>	; Save registers

	 call	 INST_OPR0E	; Install our local Page Fault handler

	 mov	 ecx,MEMCNT[@MEM_BYTE*(type MEMCNT)] ; Get # entries in one line

	 push	 MEMOFF 	; Save over inner loop
MEM_BYTE_NEXT:

; Put out tick mark if we're on an 8-byte boundary

	 mov	 al,' '         ; Separator if not 8-byte boundary

	 cmp	 ecx,MEMCNT[@MEM_BYTE*(type MEMCNT)] ; But not at start of line
	 je	 short @F	; Jump if at start

	 test	 MEMOFF,@BIT0 or @BIT1 or @BIT2 ; Check for 8-byte boundary
	 jnz	 short @F	; Jump if not there

	 mov	 al,'-'         ; Separator if 8-byte boundary
@@:
	 call	 DISPTXT	; Display byte on screen as text

	 PUSHD	 0		; Pass offset as argument
	 call	 GETBYTE	; Get, format, and display byte from MEMBASE+MEMOFF

	 loop	 MEM_BYTE_NEXT	; Jump if more columns to display

	 pop	 MEMOFF 	; Restore

; Now display the ASCII bytes

	 mov	 al,' '         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 mov	 al,'³'         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 mov	 al,' '         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 mov	 ecx,MEMCNT[@MEM_BYTE*(type MEMCNT)] ; Get # entries in one line
@@:
	 call	 DSPBYTE	; Get and display byte from MEMBASE+MEMOFF

	 loop	 @B		; Jump if more bytes to display

	 call	 CLEAR_EOL	; Clear to the end-of-the-line
	 call	 NEXTLINE	; Skip to next line, first column

	 call	 REST_OPR0E	; Restore previous Page Fault handler

	 REGREST <ecx,eax>	; Restore

	 clc			; Indicate we should continue with next row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEM_BYTE endp			; End MEM_BYTE procedure
	 NPPROC  MEM_WORD -- Display Word Memory
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display one row of memory in word format.

On entry:

MEMBASE  =	 base of memory to display
MEMOFF	 =	 offset ...

On exit:

MEMOFF	 =	 (updated)
CF	 =	 0 to continue with next row
	 =	 1 to stop with this row

|

	 REGSAVE <eax,ecx>	; Save registers

	 call	 INST_OPR0E	; Install our local Page Fault handler

	 mov	 ecx,MEMCNT[@MEM_WORD*(type MEMCNT)] ; Get # entries in one line
MEM_WORD_NEXT:

; Put out tick mark if we're on an 8-byte boundary

	 mov	 al,' '         ; Separator if not 8-byte boundary

	 cmp	 ecx,MEMCNT[@MEM_WORD*(type MEMCNT)] ; But not at start of line
	 je	 short @F	; Jump if at start

	 test	 MEMOFF,@BIT0 or @BIT1 or @BIT2 ; Check for 8-byte boundary
	 jnz	 short @F	; Jump if not there

	 mov	 al,'-'         ; Separator if 8-byte boundary
@@:
	 call	 DISPTXT	; Display byte on screen as text

	 PUSHD	 0		; Pass offset as argument
	 call	 GETWORD	; Get, format, and display word from MEMBASE+MEMOFF

	 loop	 MEM_WORD_NEXT	; Jump if more columns to display

	 call	 CLEAR_EOL	; Clear to the end-of-the-line
	 call	 NEXTLINE	; Skip to next line, first column

	 call	 REST_OPR0E	; Restore previous Page Fault handler

	 REGREST <ecx,eax>	; Restore

	 clc			; Indicate we should continue with next row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEM_WORD endp			; End MEM_WORD procedure
	 NPPROC  MEM_DWORD -- Display Dword Memory
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display one row of memory in dword format.

On entry:

MEMBASE  =	 base of memory to display
MEMOFF	 =	 offset ...

On exit:

MEMOFF	 =	 (updated)
CF	 =	 0 to continue with next row
	 =	 1 to stop with this row

|

	 REGSAVE <eax,ecx>	; Save registers

	 call	 INST_OPR0E	; Install our local Page Fault handler

	 mov	 ecx,MEMCNT[@MEM_DWORD*(type MEMCNT)] ; Get # entries in one line
MEM_DWORD_NEXT:
	 PUSHD	 2		; Pass offset as argument
	 call	 GETWORD	; Get, format, and display word from MEMBASE+MEMOFF

	 PUSHD	 -2		; Pass offset as argument
	 call	 GETWORD	; Get, format, and display word from MEMBASE+MEMOFF

	 cmp	 ecx,1		; Izit the last entry?
	 je	 short @F	; Jump if so (no trailing space)

	 mov	 al,' '         ; Separator
	 call	 DISPTXT	; Display byte on screen as text
@@:
	 loop	 MEM_DWORD_NEXT ; Jump if more columns to display

	 call	 CLEAR_EOL	; Clear to the end-of-the-line
	 call	 NEXTLINE	; Skip to next line, first column

	 call	 REST_OPR0E	; Restore previous Page Fault handler

	 REGREST <ecx,eax>	; Restore

	 clc			; Indicate we should continue with next row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEM_DWORD endp			; End MEM_DWORD procedure
	 NPPROC  MEM_VECT -- Display Vector Memory
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display one row of memory in vector format.

On entry:

MEMBASE  =	 base of memory to display
MEMOFF	 =	 offset ...

On exit:

MEMOFF	 =	 (updated)
CF	 =	 0 to continue with next row
	 =	 1 to stop with this row

|

	 REGSAVE <eax,ecx>	; Save registers

	 call	 INST_OPR0E	; Install our local Page Fault handler

	 mov	 ecx,MEMCNT[@MEM_VECT*(type MEMCNT)] ; Get # entries in one line
MEM_VECT_NEXT:
	 mov	 al,' '         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 mov	 al,' '         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 PUSHD	 2		; Pass offset as argument
	 call	 GETWORD	; Get, format, and display word from MEMBASE+MEMOFF

	 mov	 al,':'         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 PUSHD	 -2		; Pass offset as argument
	 call	 GETWORD	; Get, format, and display word from MEMBASE+MEMOFF

	 loop	 MEM_VECT_NEXT	; Jump if more columns to display

	 call	 CLEAR_EOL	; Clear to the end-of-the-line
	 call	 NEXTLINE	; Skip to next line, first column

	 call	 REST_OPR0E	; Restore previous Page Fault handler

	 REGREST <ecx,eax>	; Restore

	 clc			; Indicate we should continue with next row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEM_VECT endp			; End MEM_VECT procedure
	 NPPROC  MEM_GDT -- Display GDT Memory
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display one row of memory in GDT format.

Note, we don't handle VM86 mode 64KB wrap of
a single GDT entry over the boundary.

On entry:

MEMBASE  =	 base of memory to display
MEMOFF	 =	 offset ...

On exit:

MEMOFF	 =	 (updated)
CF	 =	 0 to continue with next row
	 =	 1 to stop with this row

|

	 REGSAVE <eax,ecx,edx,esi> ; Save registers

	 call	 INST_OPR0E	; Install our local Page Fault handler

	 mov	 al,' '         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 mov	 esi,MEMBASE	; GS:ESI ==> base  of memory to display
	 add	 esi,MEMOFF	; GS:ESI ==> start ...

	 and	 LCL_FLAG,not @LCL_IDX ; Mark as not displaying index
	 mov	 dx,0		; Indicate it's from the GDT
	 mov	 ecx,1		; Display one entry
	 call	 DISP_DTE	; Display ECX descriptor table entry at GS:ESI

	 add	 MEMOFF,size DESC_STR ; Skip to next entry
	 mov	 eax,MEMMASK	; Get the mask value
	 and	 MEMOFF,eax	; Mask off wrapped bits (if VM86 mode)

	 call	 REST_OPR0E	; Restore previous Page Fault handler

	 REGREST <esi,edx,ecx,eax> ; Restore

	 clc			; Indicate we should continue with next row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEM_GDT  endp			; End MEM_GDT procedure
	 NPPROC  MEM_IDT -- Display IDT Memory
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display one row of memory in IDT format.

Note, we don't handle VM86 mode 64KB wrap of
a single IDT entry over the boundary.

On entry:

MEMBASE  =	 base of memory to display
MEMOFF	 =	 offset ...

On exit:

MEMOFF	 =	 (updated)
CF	 =	 0 to continue with next row
	 =	 1 to stop with this row

|

	 REGSAVE <eax,ecx,edx,esi> ; Save registers

	 call	 INST_OPR0E	; Install our local Page Fault handler

	 mov	 al,' '         ; Separator
	 call	 DISPTXT	; Display byte on screen as text

	 mov	 esi,MEMBASE	; GS:ESI ==> base  of memory to display
	 add	 esi,MEMOFF	; GS:ESI ==> start ...

	 and	 LCL_FLAG,not @LCL_IDX ; Mark as not displaying index
	 mov	 dx,0		; Interrupt #
	 mov	 ecx,1		; Display one entry
	 call	 DISP_IDTLIN	; Display ECX descriptor table entry at GS:ESI

	 add	 MEMOFF,size IDT_STR ; Skip to next entry
	 mov	 eax,MEMMASK	; Get the mask value
	 and	 MEMOFF,eax	; Mask off wrapped bits (if VM86 mode)

	 call	 REST_OPR0E	; Restore previous Page Fault handler

	 REGREST <esi,edx,ecx,eax> ; Restore

	 clc			; Indicate we should continue with next row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEM_IDT  endp			; End MEM_IDT procedure
	 NPPROC  MEM_TSS -- Display TSS Memory
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display one row of memory in TSS format.

Note, we don't handle VM86 mode 64KB wrap of
the TSS over the boundary.

On entry:

MEMBASE  =	 base of memory to display
MEMOFF	 =	 offset ...

On exit:

MEMOFF	 =	 NOT updated
CF	 =	 0 to continue with next row
	 =	 1 to stop with this row

|

;;;;;;;; mov	 SCROFF,@NCOLS*2*2 ; Start in column 0, row #2
	 call	 CLEAR_EOL	; Clear to the end-of-the-line
	 call	 NEXTLINE	; Skip to next line, first column

	 REGSAVE <esi>		; Save for a moment

	 call	 INST_OPR0E	; Install our local Page Fault handler

	 mov	 esi,MEMBASE	; GS:ESI ==> base  of memory to display
	 add	 esi,MEMOFF	; GS:ESI ==> start ...

	 push	 TSSTYPE	; Mark as 286 or 386 TSS
	 PUSHW	 0		; Use pseudo-selector
	 call	 DISP_TSSMEM	; Display GS:ESI in TSS format

	 call	 REST_OPR0E	; Restore previous Page Fault handler

	 REGREST <esi>		; Restore

	 call	 CLEAR_EOP	; Clear to the end-of-the-page

	 stc			; Indicate we should stop with this row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEM_TSS  endp			; End MEM_TSS procedure
	NPPROC	DISP_MEMCNT -- Display Memory Width Count
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the memory width count

|

DMC_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
DMC_CNT dd	?		; The count

DMC_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,esi,edi>	; Save registers

	mov	MSG_MEMCNT1[-1],' ' ; Ensure clear from last time
	mov	eax,[ebp].DMC_CNT ; Get the count
	lea	edi,MSG_MEMCNT1 ; ES:EDI ==> output save area

	push	@DEC_RIGHT	; Mark as right-justified
	call	DD2DEC		; Convert EAX to decimal at ES:EDI

	lea	esi,MSG_MEMCNT	; DS:ESI ==> ASCIIZ string to display
	call	DISPASCIIZ	; Display ASCIIZ string from DS:ESI

	REGREST <edi,esi,eax>	; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_MEMCNT	endp		; End DISP_MEMCNT procedure
	 NPPROC  HDR_BYTE -- Display Byte Header
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <eax,esi>	; Save registers

	 mov	 al,TTLATTR	; Get title attribute
	 xchg	 al,DEFATTR	; Swap with default attribute

	 call	 DISP_SELSEG	; Display selector/segment

	 lea	 esi,MSG_BYTE	; Line 1 of byte header
	 call	 DISPASCIIZ	; Display ASCIIZ string from ESI

	push	MEMCNT[@MEM_BYTE*(type MEMCNT)] ; Pass the count
	call	DISP_MEMCNT	; Display the memory width count

	 call	 HDR_PHYS	; Display physical message (if any)

	 call	 HDR_SYMBOL	; Check for symbol at starting offset

	 call	 CLEAR_EOL	; Clear to the end-of-the-line
	 xchg	 al,DEFATTR	; Restore default attribute

	 REGREST <esi,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HDR_BYTE endp			; End HDR_BYTE procedure
	 NPPROC  HDR_WORD -- Display Word Header
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <eax,esi>	; Save registers

	 mov	 al,TTLATTR	; Get title attribute
	 xchg	 al,DEFATTR	; Swap with default attribute

	 call	 DISP_SELSEG	; Display selector/segment

	 lea	 esi,MSG_WORD	; Line 1 of word header
	 call	 DISPASCIIZ	; Display ASCIIZ string from ESI

	push	MEMCNT[@MEM_WORD*(type MEMCNT)] ; Pass the count
	call	DISP_MEMCNT	; Display the memory width count

	 call	 HDR_PHYS	; Display physical message (if any)

	 call	 HDR_SYMBOL	; Check for symbol at starting offset

	 call	 CLEAR_EOL	; Clear to the end-of-the-line
	 xchg	 al,DEFATTR	; Restore default attribute

	 REGREST <esi,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HDR_WORD endp			; End HDR_WORD procedure
	 NPPROC  HDR_DWORD -- Display Dword Header
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <eax,esi>	; Save registers

	 mov	 al,TTLATTR	; Get title attribute
	 xchg	 al,DEFATTR	; Swap with default attribute

	 call	 DISP_SELSEG	; Display selector/segment

	 lea	 esi,MSG_DWORD	; Line 1 of dword header
	 call	 DISPASCIIZ	; Display ASCIIZ string from ESI

	push	MEMCNT[@MEM_DWORD*(type MEMCNT)] ; Pass the count
	call	DISP_MEMCNT	; Display the memory width count

	 call	 HDR_PHYS	; Display physical message (if any)

	 call	 HDR_SYMBOL	; Check for symbol at starting offset

	 call	 CLEAR_EOL	; Clear to the end-of-the-line
	 xchg	 al,DEFATTR	; Restore default attribute

	 REGREST <esi,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HDR_DWORD endp			; End HDR_DWORD procedure
	 NPPROC  HDR_VECT -- Display Vector Header
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <eax,esi>	; Save registers

	 mov	 al,TTLATTR	; Get title attribute
	 xchg	 al,DEFATTR	; Swap with default attribute

	 call	 DISP_SELSEG	; Display selector/segment

	 lea	 esi,MSG_VECT	; Line 1 of vector header
	 call	 DISPASCIIZ	; Display ASCIIZ string from ESI

	push	MEMCNT[@MEM_VECT*(type MEMCNT)] ; Pass the count
	call	DISP_MEMCNT	; Display the memory width count

	 call	 HDR_PHYS	; Display physical message (if any)

	 call	 HDR_SYMBOL	; Check for symbol at starting offset

	 call	 CLEAR_EOL	; Clear to the end-of-the-line
	 xchg	 al,DEFATTR	; Restore default attribute

	 REGREST <esi,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HDR_VECT endp			; End HDR_VECT procedure
	 NPPROC  HDR_GDT -- Display GDT Header
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <eax,esi>	; Save registers

	 mov	 al,TTLATTR	; Get title attribute
	 xchg	 al,DEFATTR	; Swap with default attribute

	 call	 DISP_SELSEG	; Display selector/segment

	 lea	 esi,MSG_GDTMEM ; Line 1 of GDT header
	 call	 DISPASCIIZ	; Display ASCIIZ string from ESI

	 call	 HDR_PHYS	; Display physical message (if any)

	 call	 CLEAR_EOL	; Clear to the end-of-the-line
	 xchg	 al,DEFATTR	; Restore default attribute

	 REGREST <esi,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HDR_GDT  endp			; End HDR_GDT procedure
	 NPPROC  HDR_IDT -- Display IDT Header
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <eax,esi>	; Save registers

	 mov	 al,TTLATTR	; Get title attribute
	 xchg	 al,DEFATTR	; Swap with default attribute

	 call	 DISP_SELSEG	; Display selector/segment

	 lea	 esi,MSG_IDTMEM ; Line 1 of IDT header
	 call	 DISPASCIIZ	; Display ASCIIZ string from ESI

	 call	 HDR_PHYS	; Display physical message (if any)

	 call	 CLEAR_EOL	; Clear to the end-of-the-line
	 xchg	 al,DEFATTR	; Restore default attribute

	 REGREST <esi,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HDR_IDT  endp			; End HDR_IDT procedure
	 NPPROC  HDR_TSS -- Display TSS Header
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <eax,esi>	; Save registers

	 mov	 al,TTLATTR	; Get title attribute
	 xchg	 al,DEFATTR	; Swap with default attribute

	 call	 DISP_SELSEG	; Display selector/segment

	 lea	 esi,MSG_TSSL	; TSS header line
	 call	 DISPASCIIZ	; Display ASCIIZ string from ESI

	 call	 HDR_PHYS	; Display physical message (if any)

	 call	 CLEAR_EOL	; Clear to the end-of-the-line
	 xchg	 al,DEFATTR	; Restore default attribute

	 REGREST <esi,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HDR_TSS  endp			; End HDR_TSS procedure
	 NPPROC  HDR_PHYS -- Display Physical Header
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display physical header message

|

	 test	 MEMMODE,@MODE_PHYS ; Izit physical display?
	 jz	 short @F	; Jump if not

	 push	 eax		; Save for a moment

	 mov	 eax,MEMCR3	; Get translated CR3 (if non-zero)
	 call	 HDR_PHYS_SUB	; Use common subroutine

	 pop	 eax		; Restore
@@:
	 ret			; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HDR_PHYS endp			; End HDR_PHYS procedure
	 NPPROC  HDR_PHYS_SUB -- Subroutine to HDR_PHYS
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display physical header message

On entry:

EAX	 =	 CR3 to use (possibly zero)

|

	 REGSAVE <esi,edi>	; Save registers

	 lea	 esi,MSG_PHYS	; Let's get physical
	 call	 DISPASCIIZ	; Display ASCIIZ string from ESI

	 and	 eax,eax	; Izit valid?
	 jz	 short @F	; Jump if not

	 lea	 edi,MSG_PCR3A	; ES:EDI ==> output save area
	 call	 DD2HEX 	; Convert EAX to ASCII hex at ES:EDI

	 lea	 esi,MSG_PCR3	; Let's get translated
	 call	 DISPASCIIZ	; Display ASCIIZ string from ESI
@@:
	 REGREST <edi,esi>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HDR_PHYS_SUB endp		; End HDR_PHYS_SUB procedure
	 NPPROC  DISP_SELSEG -- Display Selector/segment
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display selector/segment

|

	 REGSAVE <eax,esi,edi>	; Save registers

	 mov	 ax,':g'        ; Assume VM86 mode

	 test	 MEMMODE,@MODE_VM ; Izit VM86 mode?
	 jnz	 short @F	; Yes

	 mov	 ax,'|l'        ; It's PM
@@:
	 mov	 MSG_SELSEG1,al ; Save in message
	 mov	 MSG_SELSEG3,ah ; Save in message

	 mov	 ax,MEMSEL	; Get selector/segment
	 lea	 edi,MSG_SELSEG2 ; ES:EDI ==> output save area
	 call	 BIN2WORD	; Convert AX to hex at ES:EDI

	 lea	 esi,MSG_SELSEG ; Selector/segment message
	 call	 DISPASCIIZ	; Display ASCIIZ string from ESI

	 REGREST <edi,esi,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_SELSEG endp		; End DISP_SELSEG procedure
	 NPPROC HDR_SYMBOL -- Display symbol matching beginning offset
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If we are not displaying with a different CR3, which will most likely
invalid symbolic information besides leaving less room, check
MEMBASE+MEMOFF for a symbol table match.  If found, display the
symbol name.

|

	 REGSAVE <eax,ecx,esi,edi> ; Save registers

	 test	 MEMMODE,@MODE_PHYS ; Izit physical display?
	 jnz	 short HDR_SYMBOL_EXIT ; Jump if so

	 mov	 eax,MEMBASE	; Get base of segment/selector
	 add	 eax,MEMOFF	; Add offset

	 call	 SYMHASH_SRCH	; Return DGROUP:EAX ==> symbol record or
				; CF=1 if no match
	 jc	 short HDR_SYMBOL_EXIT ; Jump if not found

	 lea	 esi,DGROUP:[eax].SYM_NAMLEN ; Get length byte
	 lods	 DGROUP:[esi].LO ; Put length byte in AL
	 movzx	 ecx,al 	; Prepare for string operation
	 jecxz	 HDR_SYMBOL_EXIT ; Exit if length=0

	 lea	 edi,DSYMBOL_NAME ; Destination for symbol
	 cmp	 ecx,@DSYMBOL_MAX ; Izit over the limit?
	 jna	 short @F	; Jump if not

	 mov	 ecx,@DSYMBOL_MAX ; Truncate
@@:
	 cld			; Set forward direction
S32 rep  movs	 <DGROUP:[edi].LO,DGROUP:[esi].LO> ; Copy symbol name
	 mov	 ax,')'         ; Put in closing ')' and trailing NULL
S32	 stos	 DGROUP:[edi].ELO ; Blast them in

	 lea	 esi,DSYMBOL_TXT ; ASCIIZ string to display
	 call	 DISPASCIIZ	; Display it
HDR_SYMBOL_EXIT:
	 REGREST <edi,esi,ecx,eax> ; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HDR_SYMBOL endp 		; End HDR_SYMBOL procedure

PROG	 ends			; End PROG segment

	 MEND			; End SWAT_MEM module
