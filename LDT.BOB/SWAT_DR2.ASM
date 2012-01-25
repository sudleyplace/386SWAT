;' $Header:   P:/PVCS/386SWAT/SWAT_DR2.ASV   1.8   10 Jul 1997 14:46:26   BOB  $
	title	SWAT_DR2 -- 386SWAT More Device Driver Routines
	page	58,122
	name	SWAT_DR2

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-2001 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, December, 1993.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include ASCII.INC
	include ALLMEM.INC
	include MAXDEV.INC
	include OPCODES.INC
	include IOPBITS.INC
	include VCPI.INC

	include SWAT_FIL.INC
	include SWAT_COM.INC
	include SWAT_DRV.INC
	include SWAT_SEG.INC
	include SWAT_VCP.INC
.list

PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	ds:PGROUP

	extrn	SWATINI:tbyte
	extrn	DEVLOAD:byte

PROG	ends			; End PROG segment


DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	extrn	LC4_FLAG:dword
	include SWAT_LC4.INC

	extrn	BLCLPDIR:dword
	extrn	RUD_GDTR:fword
	extrn	RUD_IDTR:fword
;;;;;;; extrn	MSG_FLVM:byte

	public	MMCODESEL,MMDATASEL,MMAGRSEL,MMCR3SEL,MMSELS
MMCODESEL dw	?		; SWAT's code selector in MM's GDT
MMDATASEL dw	?		; SWAT's data ...
MMAGRSEL dw	?		; AGROUP ...
MMCR3SEL dw	?		; CR3 ...
MMSELS	dd	(size RUDGDT_STR)/(size DESC_STR) ; # selectors needed

DATA16	ends			; End DATA16 segment


RCODE	segment use16 para public 'rcode' ; Start RCODE segment
	assume	cs:RGROUP,ds:RGROUP

	extrn	DEV_FLAG:word
	extrn	PMI_FVEC:fword
	extrn	PTR_DEV_WINCB:word
	extrn	DEV_WINCB:far
	extrn	DEV_AGRSEL:word
	extrn	DEV_CR3:dword
	extrn	PTR_INIT_PROT:fword
	extrn	PTR_REST_PROT:fword

	public	MMPaCR3,MMLaCR3,MMLaCR3B,MMLaXMS
MMPaCR3 dd	?		; Physical address of MM's CR3
MMLaCR3 dd	?		; Linear ...
MMLaCR3B dd	?		; Linear ...
MMLaXMS dd	?		; Linear address of XMS allocation if VCPI/MM

	public	RUDSTK_FVEC
RUDSTK_FVEC df	?		; Save area for our stack

	align	16		; Fill tail with NOPs

RCODE	ends			; End RCODE segment


NDATA	segment use16 dword public 'ndata' ; Start NDATA segment
	assume	ds:NGROUP

	extrn	LaCODE:dword
	extrn	LaDATA:dword
	extrn	SWAT_TSIZ:dword
	extrn	SWAT_ISIZ:dword
	extrn	SWAT_DAT:dword
	extrn	MMPaXMS:dword
	extrn	SegCR3:word
	extrn	SegPTE:word
	extrn	RUDLaGDT:dword
	extrn	RUDLaIDT:dword
	extrn	RUDGDTCNT:word
	extrn	RUDIDTCNT:word
	extrn	RUD_ERRMSG:word
	extrn	@ERRMSG_NONE:abs
	extrn	QMAX_PDE:dword
	extrn	PSWAT_CR3SEL:word

	public	RUD_GDTLEN
RUD_GDTLEN dd	?		; Length of the GDT

; Some MM's use a full CR3 meaning that all entries are valid,
; although some might not be present.  Some don't.  This makes
; a difference when we search for a physical address in the MM's
; linear address space so we know when to stop.  If the MM uses
; a full CR3, we stop when we run out of PDIRs.  Otherwise, we
; stop at the first Page Fault.  The default is the latter.

	public	RUDPF_NF
RUDPF_NF dw	NGROUP:PHYS2MMLIN_NOTFOUND ; Not Found w/o full CR3

	public	RUD_FLAG
RUD_FLAG dw	0		; INTRUDE flags
@RUD_PDE equ	8000h		; 386MAX PDE swapped out

NDATA	ends			; End NDATA segment


NCODE	segment use16 para public 'ncode' ; Start NCODE segment
	assume	cs:NGROUP

	extrn	SET_DEVGDT:near

	FPPROC	GDINT01 -- GD Bit INT 01h Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

GD Bit INT 01h handler

|

	iretd			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GDINT01 endp			; End GDINT01 procedure
	NPPROC	INTRUDE -- Intrude Into Memory Manager
	assume	ds:nothing,es:AGROUP,fs:RGROUP,gs:nothing,ss:NGROUP
COMMENT|

Attempt to intrude into another memory manager's PL0 context
inserting our own GDT and IDT entries.

On exit:

CF	=	0 if no error
	=	1 otherwise

|

; The following structure represents the DTEs we need to insert
; into the memory manager's GDT

RUDGDT_STR struc

RUDGDT_CODE dq	?		; Code selector
RUDGDT_DATA dq	?		; Data ...
RUDGDT_CR3  dq	?		; CR3  ...

RUDGDT_STR ends

	pushad			; Save all EGP registers
	REGSAVE <ds,es,fs,gs>	; Save register

	mov	ax,fs		; Copy RGROUP data selector
	mov	gs,ax		; ...here for SET_DEVGDT
	assume	gs:RGROUP	; Tell the assembler about it

	mov	ax,DTE_DS	; Get PGROUP data selector in low memory
	mov	fs,ax		; Address it
	assume	fs:PGROUP	; Tell the assembler about it

; Ensure we've been asked to intrude

	test	DEV_FLAG,@DEV_INTRUDE ; Are we INTRUDEing today?
	jz	near ptr INTRUDE_ERR ; Jump if not

; If there's a preceding SWAT, start debugging

	test	DEVLOAD,@DEVL_PSWAT ; Izit present?
	jz	short @F	; Jump if not

	int	01h		; Call our debugger
@@:

; Set special variables based upon which MM is in effect

	test	DEV_FLAG,@DEV_FCR3 ; Does this MM use a full CR3?
	jz	short @F	; Jump if not

	mov	RUDPF_NF,offset NGROUP:PHYS2MMLIN_LOOPPDIR ; Jump if PDIR not present
@@:

; Ensure there's an XMS driver present

	test	DEV_FLAG,@DEV_XMS ; Is there an XMS driver present?
	SETMSG	RUD,"No XMS driver:  not INTRUDEing."
	jz	near ptr INTRUDE_ERR ; Jump if not

; Find the MM's CR3

	call	MM_FIND_CR3	; Return in EAX

	cmp	eax,0		; Izit valid?
	SETMSG	RUD,"Unable to find MM's CR3:  not INTRUDEing."
	je	near ptr INTRUDE_ERR ; Jump if not

	mov	MMPaCR3,eax	; Save for later use

	PUSHD	0		; Pass minimum acceptable linear address
	push	eax		; Pass the MM's CR3
	push	eax		; Pass the physical address (/4KB)
	call	PHYS2MMLIN	; Translate physical addr to MM-linear in EAX
	SETMSG	RUD,"Unable to translate CR3 from physical to MM-linear:  not INTRUDEing."
	jc	near ptr INTRUDE_ERR ; Jump if we failed

	mov	MMLaCR3,eax	; Save for later use
	mov	MMLaCR3B,eax	; ...

; If this is 386MAX, re-write the 1st PDE

	test	DEV_FLAG,@DEV_MAX ; Izit 386MAX?
	jz	short INTRUDE_XMAX ; Jump if not

;;;;;;; mov	eax,MMLaCR3	; Get the CR3 linear address
	mov	ebx,QMAX_PDE	; Get the 1st PDE
	xchg	AGROUP:[eax].EDD,ebx ; Swap with 1st PDE
	mov	QMAX_PDE,ebx	; Save to restore later
	or	RUD_FLAG,@RUD_PDE ; Mark as PDE swapped out

; Flush the TLB

	mov	eax,cr3 	; Get current value
	mov	cr3,eax 	; Flush it

	PUSHD	0		; Pass minimum acceptable linear address
	push	MMPaCR3 	; Pass the MM's CR3
	push	MMPaCR3 	; Pass the physical address (/4KB)
	call	PHYS2MMLIN	; Translate physical addr to MM-linear in EAX
	SETMSG	RUD,"Unable to translate CR3 from physical to MM-linear."
	jc	near ptr INTRUDE_ERR ; Jump if we failed

	mov	MMLaCR3B,eax	; Save for later use
INTRUDE_XMAX:
COMMENT|

The GDT and IDT base addresses are in the MM's linear address space
and might not correspond to the same linear addresses in ours.
Translate them to addresses which are in our linear address space.

|

; Because we don't have addressibility to our DGROUP in low memory,
; we use the linear address of DGROUP in low memory off of AGROUP.

	xor	edi,edi 	; Zero to use as dword
	mov	di,seg DGROUP	; Get segment of DGROUP
	shl	edi,4-0 	; Convert from paras to bytes
				; AGROUP:EDI ==> DGROUP in low memory

	movzx	ebx,SegPTE	; Get segment of PTE (/4KB)
	shl	ebx,4-0 	; Convert from paras to bytes

; Do it for the GDT

	mov	edx,RUDLaGDT	; Get linear address of GDT in our space
	assume	es:DGROUP	; Tell the assembler about it (note lie)
	xchg	edx,RUD_GDTR.DTR_BASE[edi] ; Swap GDT linear address
	assume	es:AGROUP	; Tell the assembler about it

	push	MMPaCR3 	; Pass the MM's CR3
	push	edx		; Pass GDT linear address
	call	MMLIN2PHYS	; Translate MM-linear to physical address
				; Return with physical address in EAX (/4KB)
	or	eax,@PTE_URP	; Mark as User/Read-write/Present

	mov	edx,RUDLaGDT	; Get linear address of GDT in our space
	shr	edx,12-0	; Convert from bytes to 4KB
	mov	cx,RUDGDTCNT	; Get # PTEs needed by the GDT
@@:
	mov	AGROUP:[ebx+edx*4].EDD,eax ; Save next PTE
	add	eax,4*1024	; Skip to next PTE
	inc	edx		; ...

	loop	@B		; Jump if more PTEs to save

; Do it for the IDT

	mov	edx,RUDLaIDT	; Get linear address of IDT in our space
	assume	es:DGROUP	; Tell the assembler about it (note lie)
	xchg	edx,RUD_IDTR.DTR_BASE[edi] ; Swap IDT linear address
	assume	es:AGROUP	; Tell the assembler about it

	push	MMPaCR3 	; Pass the MM's CR3
	push	edx		; Pass IDT linear address
	call	MMLIN2PHYS	; Translate MM-linear to physical address
				; Return with physical address in EAX (/4KB)
	or	eax,@PTE_URP	; Mark as User/Read-write/Present

	mov	edx,RUDLaIDT	; Get linear address of IDT in our space
	shr	edx,12-0	; Convert from bytes to 4KB
	mov	cx,RUDIDTCNT	; Get # PTEs needed by the IDT
@@:
	mov	AGROUP:[ebx+edx*4].EDD,eax ; Save next PTE
	add	eax,4*1024	; Skip to next PTE
	inc	edx		; ...

	loop	@B		; Jump if more PTEs to save

; Get the GDT limit and base address

	assume	es:DGROUP	; Tell the assembler about it (note lie)
	movzx	edx,RUD_GDTR.DTR_LIM[edi] ; Get GDT limit
	assume	es:AGROUP	; Tell the assembler about it

	inc	edx		; Convert from limit to length
	and	edx,not ((size DESC_STR)-1) ; Round down to DTE boundary
				; in case someone uses a length instead
				; of a limit
	mov	RUD_GDTLEN,edx	; Save as length of GDT

; Find and save the CR3 selector (if available)

	cmp	PSWAT_CR3SEL,0	; Izit already found?
	jne	short @F	; Jump if so

	call	FIND_MMCR3	; Find the MM's CR3 selector
	jc	short @F	; Jump if we failed (we'll make one ourselves)
				; Return with selector in AX
	mov	PSWAT_CR3SEL,ax ; Save for later use
@@:

; Ensure there are enough GDT entries for us

; If there's a CR3 selector from a preceding SWAT, use it instead of our own

	cmp	PSWAT_CR3SEL,1	; Izit valid?
				; CF = 1 if not
	assume	es:DGROUP	; Tell the assembler about it (note lie)
	mov	eax,MMSELS[edi] ; Get # selectors needed
	adc	eax,-1		; Add 1-1 if not, add -1 if so
	assume	es:AGROUP	; Tell the assembler about it

	push	ax		; Pass # entries needed
	call	FIND_GDTE	; Find GDT entries
				; Return with EDX = base selector
	jc	near ptr INTRUDE_ERR ; Jump if none

; Find and save the AGROUP data selector

	call	FIND_MMAGR	; Find the MM's AGROUP data selector
	SETMSG	RUD,"Unable to find MM's AGROUP selector:  not INTRUDEing."
	jc	near ptr INTRUDE_ERR ; Jump if we failed
				; Return with selector in AX
	assume	es:DGROUP	; Tell the assembler about it (note lie)
	mov	MMAGRSEL[edi],ax ; Save for later use
	assume	es:AGROUP	; Tell the assembler about it

; Find the linear address of our XMS allocation in the MM's address space

	call	FIND_XMS_MMLIN	; Find our XMS memory in the MM's linear address
	SETMSG	RUD,"Unable to find MM-linear address of our XMS memory:  not INTRUDEing."
	jc	near ptr INTRUDE_ERR ; Jump if we failed
				; Return with MM's linear address in EAX
	mov	MMLaXMS,eax	; Save for later use

; Insert ourselves into the GDT

	mov	SWATINI.MD_IPROT.FSEL,DTE_RUDCODE ; Save for protected mode init
	mov	SWATINI.MD_RPROT.FSEL,DTE_RUDCODE ; ... 	     restore

	mov	esi,RUDLaGDT	; Get linear address of GDT in our space

	mov	ecx,SWAT_TSIZ	; Get length of SWAT

	lea	ax,[edx].RUDGDT_CODE ; Get DTE for code
	assume	es:DGROUP	; Tell the assembler about it (note lie)
	mov	MMCODESEL[edi],ax ; Save for later use
	assume	es:AGROUP	; Tell the assembler about it

	push	ecx		; Get length of SWAT code and aata
	push	MMLaXMS 	; Get base address
	push	ax		; Get DTE
	push	((mask $DTE_B) shl 8) or CPL0_CODE ; Get A/R byte and flags
	call	SET_RUDGDT	; Set the GDT entry

	push	ecx		; Get length of SWAT code and aata
	push	LaCODE		; Get base address
	push	DTE_RUDCODE	; Get DTE
	push	((mask $DTE_B) shl 8) or CPL0_CODE ; Get A/R byte and flags
	call	SET_DEVGDT	; Set the GDT entry

	sub	ecx,SWAT_DAT	; Less its length

	mov	ebx,MMLaXMS	; Get base address in MM's address space
	add	ebx,SWAT_DAT	; Skip to data

	lea	ax,[edx].RUDGDT_DATA ; Get DTE for data
	assume	es:DGROUP	; Tell the assembler about it (note lie)
	mov	MMDATASEL[edi],ax ; Save for later use
	assume	es:AGROUP	; Tell the assembler about it

	push	ecx		; Get length of SWAT data
	push	ebx		; Get base address
	push	ax		; Get DTE
	push	((mask $DTE_B) shl 8) or CPL0_DATA ; Get A/R byte and flags
	call	SET_RUDGDT	; Set the GDT entry

	mov	ebx,LaCODE	; Get base address
	add	ebx,SWAT_DAT	; Skip to data

	push	ecx		; Get length of SWAT data
	push	ebx		; Get base address
	push	DTE_RUDDATA	; Get DTE
	push	((mask $DTE_B) shl 8) or CPL0_DATA ; Get A/R byte and flags
	call	SET_DEVGDT	; Set the GDT entry

	mov	bx,PSWAT_CR3SEL ; Get preceding SWAT CR3 selector (if any)

	and	bx,bx		; Izit valid?
	jnz	short @F	; Jump if so

	lea	bx,[edx].RUDGDT_CR3 ; Get DTE for CR3 base
@@:
	assume	es:DGROUP	; Tell the assembler about it (note lie)
	mov	MMCR3SEL[edi],bx ; Save for later use
	assume	es:AGROUP	; Tell the assembler about it

	cmp	PSWAT_CR3SEL,0	; Izit valid?
	jne	short @F	; Jump if so (already set)

	push	dword ptr (64*1024) ; Use arbitrary length
	push	MMLaCR3B	; Get base address
	push	bx		; Get DTE
	push	CPL0_DATA	; Get A/R byte
	call	SET_RUDGDT	; Set the GDT entry

	mov	ax,bx		; Copy as last selector used
@@:

; Clear our DEVLOAD state as we're no longer either Device or VCPI SWAT

	and	DEVLOAD,not (@DEVL_VCPI or @DEVL_LOAD) ; No longer Device or VCPI SWAT
	or	DEVLOAD,@DEVL_XDTE2 ; Mark as no spare DTE

; Setup MD_PHYS so INIT_PROT calculates the correct value for
; PLCLPDIR, PaLCLPDIR, PaTMPPAGE, PLCLMONO, and PLCLCOLR.

; First, find the physical address of BLCLPDIR rounded up to
; the next 4KB boundary

	assume	es:DGROUP	; Tell the assembler about it (note lie)
	mov	eax,BLCLPDIR[edi] ; Get its base address in DGROUP
	assume	es:AGROUP	; Tell the assembler about it
	add	eax,LaDATA	; Plus linear address of DGROUP
	add	eax,4*1024-1	; Round up to 4KB boundary
	shr	eax,12-0	; Convert from bytes to 4KB

	movzx	ebx,SegPTE	; Get segment of PTEs (/4KB)
	shl	ebx,4-0 	; Convert from paras to bytes

	mov	ebx,AGROUP:[ebx+eax*4] ; Get the PTE
	and	bx,mask $PTE_FRM ; Isolate the 4KB frame
	add	ebx,LaCODE	; Plus linear address of PGROUP
	shl	eax,12-0	; Convert from 4KB to bytes
	sub	ebx,eax 	; Subtract to get pseudo-physical address
	mov	SWATINI.MD_PHYS,ebx ; Save as physical address of code segment

; Copy SWAT to extended memory

	xor	esi,esi 	; Zero to use as dword
	mov	si,seg PGROUP	; Get segment of PGROUP
	shl	esi,4-0 	; Convert from paras to bytes
	mov	edi,LaCODE	; Get linear address of code/data

	mov	ecx,SWAT_ISIZ	; Get size of initialized code/data
	shr	ecx,2-0 	; Convert from bytes to dwords
S32 rep movs	<AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy SWAT to extended mem

; Setup common data in load module data area in extended memory

	mov	ax,DTE_LOAD+1*(type DESC_STR) ; Get SWAT's data selector
	mov	ds,ax		; Address the file's data segment
	assume	ds:DGROUP	; Tell the assembler about it

	mov	ds:[0].FILE_4GB,DTE_4GB ; Save selector of our (VCPI) AGROUP

; In case the GD bit is set, we need to install an INT 01h handler
; to allow references to the debug registers to be processed

; Establish addressibility to IDT

	sub	esp,size DTR_STR ; Make room on stack
	SIDTD	[esp].EDF	; Save IDTR on stack
	mov	ebx,[esp].DTR_BASE ; ES:EBX ==> IDT
	add	esp,size DTR_STR ; Strip from stack

	push	AGROUP:[ebx+01h*(size IDT_STR)].EDQHI ; Save current entry
	push	AGROUP:[ebx+01h*(size IDT_STR)].EDQLO ; ...

; If there's a preceding SWAT, don't install this handler as
; it'll prevent us from single-stepping inside the MD_IPROT code

	test	DEVLOAD,@DEVL_PSWAT ; Izit present?
	jnz	short @F	; Jump if so

	lea	eax,GDINT01	; Get offset of handler

	mov	AGROUP:[ebx+01h*(size IDT_STR)].IDT_OFFLO,ax ; Save in IDT
	shr	eax,16		; Shift down high-order word
	mov	AGROUP:[ebx+01h*(size IDT_STR)].IDT_OFFHI,ax ; ...
	mov	AGROUP:[ebx+01h*(size IDT_STR)].IDT_SELECT,cs ; ...
	mov	AGROUP:[ebx+01h*(size IDT_STR)].IDT_ACCESS,CPL0_INTR3 ; ...
@@:

; Call protected mode initialization code

	call	SWATINI.MD_IPROT ; Call it

	pop	AGROUP:[ebx+01h*(size IDT_STR)].EDQLO ; Restore
	pop	AGROUP:[ebx+01h*(size IDT_STR)].EDQHI ; ...

; Reset selectors in common data to the ones in the MM's GDT

	mov	ax,MMAGRSEL	; Get MM's AGROUP data selector
	mov	ds:[0].FILE_4GB,ax ; Save in struc
	mov	ds:[0].FINT_BEG[@IMODE_PMI * (type FINT_STR)].FINT_4GB,ax ; ...
	mov	ax,MMCR3SEL	; Get CR3 data selector
	mov	ds:[0].FILE_CR3,ax ; Save in struc
	mov	ds:[0].FINT_BEG[@IMODE_PMI * (type FINT_STR)].FINT_CR3,ax ; ...

; The bit flag in DEVLOAD in extended memory is cleared so we
; don't take that path again in SETUP and other places in SWAT
; as a LOD module.

	mov	eax,LaCODE	; Get linear address of code/data
	lea	eax,DEVLOAD[eax] ; Plus offset to DEVLOAD
	and	AGROUP:[eax].LO,not @DEVL_INTRUDE ; Mark as not INTRUDEing today
;;;;;;; mov	MSG_FLVM[3],'V' ; Mark as VM instead of RM

; To handle Windows transitions, we need to use a different RM callback routine

	mov	PTR_DEV_WINCB,offset RGROUP:DEV_WINCB ; Save new offset

; Copy MM data to low DOS for Windows callback

	mov	ax,MMAGRSEL	; Get MM's AGROUP data selector
	mov	DEV_AGRSEL,ax	; Save for later use

	mov	eax,MMPaCR3	; Get MM's CR3
	mov	DEV_CR3,eax	; Save for later use

	mov	ax,MMCODESEL	; Get SWAT's code selector in MM's GDT
	mov	PTR_INIT_PROT.FSEL,ax ; Save for later use
	mov	PTR_REST_PROT.FSEL,ax ; ...

; Clear the SETUP bit in LC4 as we've made changes to the
; environment

	and	LC4_FLAG,not @LC4_SETUP ; Clear it

	mov	RUD_ERRMSG,@ERRMSG_NONE ; Mark as no error

	clc			; Indicate all went well

	jmp	short INTRUDE_EXIT ; Join common exit code

INTRUDE_ERR:
	and	DEV_FLAG,not @DEV_INTRUDE ; Mark as not INTRUDEing today
	and	DEVLOAD,not @DEVL_INTRUDE ; ...

	stc			; Mark as in error
INTRUDE_EXIT:
	pushf			; Save CF

; If this is 386MAX, re-write the 1st PDE

	test	RUD_FLAG,@RUD_PDE ; Izit swapped out?
	jz	short @F	; Jump if not

	mov	eax,MMLaCR3	; Get the CR3 linear address
	mov	ebx,QMAX_PDE	; Get the 1st PDE
	xchg	AGROUP:[eax].EDD,ebx ; Swap with 1st PDE

; Flush the TLB

	mov	eax,cr3 	; Get current value
	mov	cr3,eax 	; Flush it
@@:
	popf			; Restore CF

	REGREST <gs,fs,es,ds>	; Restore
	assume	ds:nothing,es:AGROUP ; Tell the assembler about it
	assume	fs:RGROUP,gs:nothing ; ...
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INTRUDE endp			; End INTRUDE procedure
	NPPROC	MM_FIND_CR3 -- Find The MM's CR3
	assume	ds:nothing,es:AGROUP,fs:nothing,gs:RGROUP,ss:nothing
COMMENT|

Find the memory manager's CR3

On exit:

EAX	=	CR3

|

	REGSAVE <ebx>		; Save register

COMMENT|

The technique used here to find the MM's CR3 is borrowed from the
fellow who did Q387 (from QuickWare).  He solved the problem by
calling back to the VCPI host with a mode switch, but with the CS set
to RPL and DPL 1.  That way, when the VCPI host restores its own CR3
it signals a GP Fault because it is attempting to use a PL0 resource
at PL1.  The temporarily installed GP Fault handler intercepts this
case and tucks away the value the MM is about to move into CR3.

|

; Save the original GP Fault handler and install our own.

	sub	sp,size DTR_STR ; Make room for IDTR
	mov	bx,sp		; Address the stack
	SIDTD	ss:[bx].EDF	; Save on the stack
	mov	ebx,ss:[bx].DTR_BASE ; Get base address
	add	sp,size DTR_STR ; Strip from stack

	push	AGROUP:[ebx+0Dh*(type IDT_STR)].EDQHI ; Save high-order dword
	push	AGROUP:[ebx+0Dh*(type IDT_STR)].EDQLO ; ...
	push	ebx		; Save offset in AGROUP

	mov	AGROUP:[ebx+0Dh*(type IDT_STR)].IDT_SELECT,cs ; Save selector
	lea	eax,RUD_INT0D	; Get offset of our handler
	mov	AGROUP:[ebx+0Dh*(type IDT_STR)].IDT_OFFLO,ax ; ... offset
	shr	eax,16		; Shift to low-order
	mov	AGROUP:[ebx+0Dh*(type IDT_STR)].IDT_OFFHI,ax ; ... offset
	mov	AGROUP:[ebx+0Dh*(type IDT_STR)].IDT_ACCESS,CPL0_INTR3 ; ... A/R

; Set the VCPI host's code and data selector DPL to 1

	mov	al,1 shl $DT_DPL ; New DPL value
	call	MM_SETDPL	; Set various DPLs

; Set the VCPI host's code selector RPL to 1

	or	PMI_FVEC.FSEL,1 shl $PL ; RPL=1

; Call the VCPI host

	movzx	esp,sp		; Ensure high-order word is zero before
				; letting the MM switch stacks so we can use
				; ESP as a base address (copied to EBP)
				; in case it uses a 32-bit stack.
	REGSAVE <ds,es,fs,gs>	; Save all segment registers

	pushf			; Save flags
	cli			; Ensure IF=0

VCPIVMRET_STR struc

VCPIVMRET_EIP dd ?		; 00:  VCPI VM return EIP
VCPIVMRET_CS dw ?,?		; 04:  ...	      CS w/filler
VCPIVMRET_EFL dd ?		; 08:  ...	      EFL
VCPIVMRET_ESP dd ?		; 0C:  ...	      ESP
VCPIVMRET_SS dw ?,?		; 10:  ...	      SS w/filler
VCPIVMRET_ES dw ?,?		; 14:  ...	      ES ...
VCPIVMRET_DS dw ?,?		; 18:  ...	      DS ...
VCPIVMRET_FS dw ?,?		; 1C:  ...	      FS ...
VCPIVMRET_GS dw ?,?		; 20:  ...	      GS ...

VCPIVMRET_STR ends

; Make room for VCPI VM return strcture
; (we don't care what's in it as it won't be used to return to VM).

	sub	esp,size VCPIVMRET_STR ; Make room

; Save away our SS and ESP to restore later in case the VCPI
; host changes to its own stack before GP Faulting.

	mov	RUDSTK_FVEC.FOFF,esp ; Save to restore later
	mov	RUDSTK_FVEC.FSEL,ss  ; ...

	mov	ax,DTE_4GB or (1 shl $PL) ; Get AGROUP data selector at PL1
	mov	ds,ax		; Address it
	assume	ds:AGROUP	; Tell the assembler about it

	mov	ax,(@VCPI shl 8) or @VCPI_EPM ; Get return function
;;;;;;; call	PMI_FVEC	; Request VCPI service

	push	dword ptr (DTE_RUDSS1 or (1 shl $PL)) ; Pass SS w/filler at PL1
	push	RUDSTK_FVEC.FOFF ; ...	ESP at PL1
	pushfd			; ...  EFL
	push	PMI_FVEC.FSEL.EDD ; ... CS w/filler at PL1
	push	PMI_FVEC.FOFF	; ... EIP

	iretd			; Call VCPI host at PL1

; Return here from Page Fault handler with EAX = MM's CR3

MM_FIND_CR3_RETURN:
	add	esp,size VCPIVMRET_STR ; Strip VCPI VM return struc from stack

	popf			; Restore

	REGREST <gs,fs,es,ds>	; ...
	assume	ds:nothing,es:AGROUP ; Tell the assembler about it
	assume	fs:nothing,gs:RGROUP ; ...

; Set the VCPI host's code and data selector DPL to 0

	push	ax		; Save for a moment

	mov	al,0 shl $DT_DPL ; New DPL value
	call	MM_SETDPL	; Set various DPLs

	pop	ax		; Restore

; Set the VCPI host's code selector RPL to 0

	and	PMI_FVEC.FSEL,not (mask $PL) ; RPL=0

; Restore the previous GP fault handler

	pop	ebx		; Restore offset in AGROUP
	pop	AGROUP:[ebx+0Dh*(type IDT_STR)].EDQLO ; Restore low-order dword
	pop	AGROUP:[ebx+0Dh*(type IDT_STR)].EDQHI ; ...	 high-order ...

	REGREST <ebx>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MM_FIND_CR3 endp		; End MM_FIND_CR3 procedure
	NPPROC	MM_SETDPL -- Set Various DPLs
	assume	ds:nothing,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set various DPLs

On entry:

AL	=	new DPL

|

	REGSAVE <bx>		; Save register

	sub	sp,size DTR_STR ; Make room for GDTR
	mov	bx,sp		; Address the stack
	SGDTD	ss:[bx].EDF	; Save on the stack
	mov	ebx,ss:[bx].DTR_BASE ; Get base address
	add	sp,size DTR_STR ; Strip from stack

	and	AGROUP:[ebx].DTE_4GB.DESC_ACCESS,not (mask $DT_DPL) ; DPL=0
	and	AGROUP:[ebx+2*(size DESC_STR)].DTE_VCPI.DESC_ACCESS,not (mask $DT_DPL) ; DPL=0
	and	AGROUP:[ebx+1*(size DESC_STR)].DTE_VCPI.DESC_ACCESS,not (mask $DT_DPL) ; ...
	and	AGROUP:[ebx+0*(size DESC_STR)].DTE_VCPI.DESC_ACCESS,not (mask $DT_DPL) ; ...

	or	AGROUP:[ebx].DTE_4GB.DESC_ACCESS,al ; Set new DPL
	or	AGROUP:[ebx+2*(size DESC_STR)].DTE_VCPI.DESC_ACCESS,al ; ...
	or	AGROUP:[ebx+1*(size DESC_STR)].DTE_VCPI.DESC_ACCESS,al ; ...
	or	AGROUP:[ebx+0*(size DESC_STR)].DTE_VCPI.DESC_ACCESS,al ; ...

	REGREST <bx>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MM_SETDPL endp			; End MM_SETDPL procedure
	FPPROC	RUD_INT0D -- INTRUDE GP Fault Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

INTRUDE GP Fault handler

The instruction we're looking for is MOV CR3,r32.  When we find this
one, we save the value to be stored into CR3 and return to a point in
MM_FIND_CR3.  Other instructions we may encounter (as GP Faults) but
which we skip over are

	 MOV	 CRn,r32
	 MOV	 r32,CRn
	 MOV	 DRn,r32
	 MOV	 r32,DRn
	 Group 6 (LLDT, LTR)
	 Group 7 (LGDT, LIDT)

|

RUDGP_STR struc

RUDGP_PUSHAD db (size PUSHAD_STR) dup (?) ; ... EGP
RUDGP_ERR dd	?		; ...	   Error code
RUDGP_EIP dd	?		; ...	   EIP
RUDGP_CS  dw	?,?		; ...	   CS w/filler
RUDGP_EFL dd	?		; ...	   EFL
RUDGP_ESP dd	?		; ...	   ESP
RUDGP_SS  dw	?,?		; ...	   SS w/filler

RUDGP_STR ends

	pushad			; Save all EGP registers
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <ds>		; Save register

	lds	eax,[ebp].RUDGP_EIP.EDF ; DS:EAX ==> caller's CS:EIP
	assume	ds:nothing	; Tell the assembler about it

	cmp	ds:[eax].LO,@OPCOD_OSP ; Izit an OSP?
	jne	short @F	; Jump if not

	inc	eax		; Skip over it
@@:
	cmp	ds:[eax].ELO,@OPCOD_MOV_CRn_R32 ; Izit MOV CRn,r32?
	jne	short RUD_INT0D_EMU ; Jump if not

	mov	bh,ds:[eax+2]	; Get the MOD R/M byte

	mov	bl,bh		; Copy for destructive testing
	and	bl,mask $REG	; Isolate the REG field

	cmp	bl,3 shl $REG	; Izit CR3?
	jne	short RUD_INT0D_SKIP ; Jump if not

	mov	bl,bh		; Copy for destructive testing
	and	ebx,mask $RM	; Isolate the RM field
	shr	ebx,$RM 	; Shift to low-order
	neg	ebx		; Subtract from 7 to match PUSHAD order
	add	ebx,mask $RM	; ...
	mov	ebx,[ebp].RUDGP_PUSHAD.EDD[ebx*4] ; Get the EGP register value
	and	ebx,@PTE_FRM	; Isolate the 4KB frame
RUD_INT0D_ERR:
	mov	[ebp].RUDGP_PUSHAD.EDD[(7-@eax)*4],ebx ; Save as EAX

	REGREST <ds>		; Restore
	assume	ds:nothing	; Tell the assembler about it

	mov	ax,DTE_ES	; Get RGROUP data selector
	mov	ds,ax		; Address it
	assume	ds:RGROUP	; Tell the assembler about it

	popad			; Restore

	lss	esp,RUDSTK_FVEC ; Restore our original stack
	assume	ss:nothing	; Tell the assembler about it

	jmp	MM_FIND_CR3_RETURN ; Continue on

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
RUD_INT0D_EMU:

; At this point, we must special case various instructions.

	cmp	ds:[eax].ELO,@OPCOD_MOV_CRn_R32 ; Izit MOV CRn,r32?
	je	short RUD_INT0D_SKIP ; Jump if so

	cmp	ds:[eax].ELO,@OPCOD_MOV_R32_CRn ; Izit MOV r32,CRn?
	je	short RUD_INT0D_SKIP ; Jump if so

	cmp	ds:[eax].ELO,@OPCOD_MOV_DRn_R32 ; Izit MOV DRn,r32?
	je	short RUD_INT0D_SKIP ; Jump if so

	cmp	ds:[eax].ELO,@OPCOD_MOV_R32_DRn ; Izit MOV r32,DRn?
	je	short RUD_INT0D_SKIP ; Jump if so

	cmp	ds:[eax].ELO,@OPCOD_GRP6 ; Izit a Group 6?
	je	short RUD_INT0D_SKIP ; Jump if so

	cmp	ds:[eax].ELO,@OPCOD_GRP7 ; Izit a Group 7?
	je	short RUD_INT0D_SKIP ; Jump if so

; If there's a preceding SWAT, tell it we have a problem

	mov	ax,DTE_DS	; Get PGROUP data selector in low memory
	mov	ds,ax		; Address it
	assume	ds:PGROUP	; Tell the assembler about it

	test	DEVLOAD,@DEVL_PSWAT ; Izit present?
	jz	short @F	; Jump if not

	int	03h		; Call our debugger
@@:
	xor	ebx,ebx 	; Use error return value

	jmp	RUD_INT0D_ERR	; Join common error code

	assume	ds:nothing	; Tell the assembler about it

RUD_INT0D_SKIP:
	mov	bh,ds:[eax+2]	; Get the MOD R/M byte
	add	eax,2+1 	; Skip over the opcode and MOD R/M byte

	mov	bl,bh		; Copy for destructive testing
	and	bl,mask $MOD	; Isolate the MOD field

	cmp	bl,11b shl $MOD ; Izit a register operand?
	je	short RUD_INT0D_CONT ; Jump if so

	cmp	bl,10b shl $MOD ; Check for MOD=10 (DISP16)
	je	short RUD_INT0D_D16 ; Jump if so

	cmp	bl,01b shl $MOD ; Check for MOD=01 (DISP8)
	je	short RUD_INT0D_D8 ; Jump if so

	mov	bl,bh		; Copy for destructive testing
	and	bl,mask $RM	; Isolate the RM bits

	cmp	bl,110b shl $RM ; Check for special DISP16
	jne	short RUD_INT0D_CONT ; Not this time
RUD_INT0D_D16:
	inc	eax		; Skip past the instruction byte
RUD_INT0D_D8:
	inc	eax		; Skip past the instruction byte
RUD_INT0D_CONT:
	mov	[bp].RUDGP_EIP,eax ; Skip the instruction

	REGREST <ds>		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popad			; Restore

	add	esp,size RUDGP_ERR ; Strip off error code

	iretd			; Continue on

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RUD_INT0D endp			; End RUD_INT0D procedure
	NPPROC	FIND_MMAGR -- Find And Save The MM's AGROUP Data Selector
	assume	ds:nothing,es:AGROUP,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Find and save the MM's AGROUP data selector.

On entry:

AGROUP:EDI ==>	 DGROUP in low memory

On exit:

AX	=	selector
CF	=	0 if all went well
	=	1 if we failed

|

	REGSAVE <ebx,ecx,edx>	; Save registers

	mov	ebx,RUDLaGDT	; Get linear address of GDT in our space

	assume	es:DGROUP	; Tell the assembler about it (note lie)
	movzx	ecx,RUD_GDTR.DTR_LIM[edi] ; Get GDT limit
	assume	es:AGROUP	; Tell the assembler about it

	inc	ecx		; Convert from limit to length
	shr	ecx,3		; Convert from bytes to DTEs
	xor	eax,eax 	; Initialize index into GDT
FIND_MMAGR_NEXT:

; We're looking for a GDT entry with a 32-bit base of zero and a
; 32-bit limit of -1 (which can be accomplished only with a page
; granular selector with a 20-bit limit of -1).

	cmp	AGROUP:[eax+ebx].DESC_BASE01,0 ; Are bytes 0-1 zero?
	jne	short FIND_MMAGR_LOOP ; Jump if not

	cmp	AGROUP:[eax+ebx].DESC_BASE2,0 ; Is byte 2 zero?
	jne	short FIND_MMAGR_LOOP ; Jump if not

	cmp	AGROUP:[eax+ebx].DESC_BASE3,0 ; Is byte 3 zero?
	jne	short FIND_MMAGR_LOOP ; Jump if not

	cmp	AGROUP:[eax+ebx].DESC_SEGLM0,-1 ; Is segment limit all 1s?
	jne	short FIND_MMAGR_LOOP ; Jump if not

	mov	dl,AGROUP:[eax+ebx].DESC_ACCESS ; Get A/R byte
	and	dl,not ((mask $DT_DPL) or (mask $DC_ACC)) ; DPL=ACC=0

	cmp	dl,CPL0_DATA	; Izit a data selector?
	jne	short FIND_MMAGR_LOOP ; Jump if not

	mov	dl,AGROUP:[eax+ebx].DESC_SEGLM1 ; Get segment limit and flags

	test	dl,mask $DTE_G	; Izit a page granular selector?
	jz	short FIND_MMAGR_LOOP ; Jump if not

	and	dl,mask $SEGLM1 ; Isolate limit bits 15-19

	cmp	dl,0Fh		; Izit all 1s?
	je	short FIND_MMAGR_EXIT ; Jump if so (note CF=0)
FIND_MMAGR_LOOP:
	add	ax,size DESC_STR ; Skip to next DTE

	loop	FIND_MMAGR_NEXT ; Jump if more DTEs to check

	stc			; Mark as not found
FIND_MMAGR_EXIT:
	REGREST <edx,ecx,ebx>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_MMAGR endp 		; End FIND_MMAGR procedure
	NPPROC	FIND_MMCR3 -- Find And Save The MM's CR3 Selector
	assume	ds:nothing,es:AGROUP,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Find and save the MM's CR3 selector.

On entry:

AGROUP:EDI ==>	 DGROUP in low memory

On exit:

AX	=	selector
CF	=	0 if all went well
	=	1 if we failed

|

	REGSAVE <ebx,ecx,edx>	; Save registers

	mov	ebx,RUDLaGDT	; Get linear address of GDT in our space

	assume	es:DGROUP	; Tell the assembler about it (note lie)
	movzx	ecx,RUD_GDTR.DTR_LIM[edi] ; Get GDT limit
	assume	es:AGROUP	; Tell the assembler about it

	inc	ecx		; Convert from limit to length
	shr	ecx,3		; Convert from bytes to DTEs
	xor	eax,eax 	; Initialize index into GDT
FIND_MMCR3_NEXT:

; We're looking for a GDT entry whose base is that of MMLaCR3B,
; and is a data selector with a length of at least 4KB

	mov	edx,AGROUP:[eax+ebx].DESC_BASE01.EDD ; Get bytes 0-2
	shl	edx,8		; Shift up to make room for byte 3
	mov	dl,AGROUP:[eax+ebx].DESC_BASE3 ; Get byte 3
	ror	edx,8		; Shift back into position

	cmp	edx,MMLaCR3B	; Izit the same?
	jne	short FIND_MMCR3_LOOP ; Jump if not

	mov	dl,AGROUP:[eax+ebx].DESC_ACCESS ; Get A/R byte
	and	dl,not ((mask $DT_DPL) or (mask $DC_ACC)) ; DPL=ACC=0

	cmp	dl,CPL0_DATA	; Izit a data selector?
	jne	short FIND_MMCR3_LOOP ; Jump if not

	mov	dl,AGROUP:[eax+ebx].DESC_SEGLM1 ; Get segment limit and flags

	test	dl,mask $DTE_G	; Izit a page granular selector?
	jnz	short FIND_MMCR3_EXIT ; Jump if so (must be 4KB or more)
				; Note CF=0
	and	dx,mask $SEGLM1 ; Isolate limit bits 15-19
	shl	edx,16		; Shift to high-order
	mov	dx,AGROUP:[eax+ebx].DESC_SEGLM0 ; Get the limit bits 0-15

	cmp	edx,4*1024-1	; Izit big enough?
	jae	short FIND_MMCR3_EXIT ; Jump if so (note CF=0)
FIND_MMCR3_LOOP:
	add	eax,size DESC_STR ; Skip to next DTE

	loop	FIND_MMCR3_NEXT ; Jump if more DTEs to check

	stc			; Mark as not found
FIND_MMCR3_EXIT:
	REGREST <edx,ecx,ebx>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_MMCR3 endp 		; End FIND_MMCR3 procedure
	NPPROC	FIND_XMS_MMLIN -- Find Linear Address of XMS Allocation
	assume	ds:nothing,es:AGROUP,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Find linear address of XMS allocation in the MM's address space.

On exit:

CF	=	0 if we found it
	=	1 otherwise

|

	REGSAVE <ebx>		; Save register

	mov	ebx,MMPaXMS	; Get the physical address in MM address space
	and	ebx,@PTE_FRM	; Isolate the 4KB frame

; Search in the MM's CR3 for this address
; Note that we ensure that the linear address is at or above 1MB
; as I've run into some false positives before (at 000E3000 I seem to recall).

	push	dword ptr (1*1024*1024) ; Pass minimum acceptable linear address
	push	MMPaCR3 	; Pass the MM's CR3
	push	ebx		; Pass the physical address (/4KB)
	call	PHYS2MMLIN	; Translate physical addr to MM-linear in EAX
	jc	short FIND_XMS_MMLIN_EXIT ; Jump if not found (note CF=0)

	mov	ebx,MMPaXMS	; Get the physical address in MM address space
	and	ebx,not @PTE_FRM ; Isolate the offset withing 4KB frame
	add	eax,ebx 	; Add to get corresponding linear address

	clc			; Indicate we succeeded
FIND_XMS_MMLIN_EXIT:
	REGREST <ebx>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_XMS_MMLIN endp		; End FIND_XMS_MMLIN procedure
	NPPROC	MMLIN2PHYS -- MM-Linear To Physical
	assume	ds:nothing,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Translate MM-linear address to a physical address (/4KB) which
contains the linear address.

On exit:

EAX	=	physical address (/4KB)

|

MML2P_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
MML2P_LIN dd	?		; Linear address to translate
MML2P_CR3 dd	?		; MM's CR3

MML2P_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ebx>		; Save register

	movzx	ebx,SegCR3	; Get segment of CR3 (/4KB)
	shl	ebx,4-0 	; Convert from paras to bytes

@MML2P_LIN equ	-4*1024*1024	; Use this linear address (/4MB)

	push	AGROUP:[ebx+@MML2P_LIN shr ($LA_DIR-2)].EDD ; Save current value
	push	ebx		; Save the offset in AGROUP

	mov	eax,[bp].MML2P_CR3 ; Get the MM's CR3
	or	eax,@PTE_URP	; Mark as User/Read-write/Present
	mov	AGROUP:[ebx+@MML2P_LIN shr ($LA_DIR-2)],eax ; Put into place

; Flush the TLB

	mov	eax,cr3 	; Get current value
	mov	cr3,eax 	; Flush it

	mov	eax,[bp].MML2P_LIN ; Get the linear address
	shr	eax,12-0	; Convert from bytes to 4KB

; Note that MASM 5.10b doesn't correctly handle the expression
;;;;;;; mov	eax,AGROUP:[eax*4+@MML2P_LIN]
; so we have to do it ourselves.

	shl	eax,12-(12-2)	; Convert from 4KB to 4KB in dwords
	add	eax,@MML2P_LIN	; Plus the base address
	mov	eax,AGROUP:[eax] ; Get the PTE
	and	eax,@PTE_FRM	; Isolate the frame

; Restore previous PDIR

	pop	ebx		; Restore offset in AGROUP
	pop	AGROUP:[ebx+@MML2P_LIN shr ($LA_DIR-2)].EDD ; Restore PDIR

; Flush the TLB

	mov	ebx,cr3 	; Get current value
	mov	cr3,ebx 	; Flush it

	REGREST <ebx>		; Restore

	pop	bp		; Restore

	ret	4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MMLIN2PHYS endp 		; End MMLIN2PHYS procedure
	NPPROC	PHYS2MMLIN -- Physical To MM-Linear
	assume	ds:nothing,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Translate physical address to MM-linear address.

On exit:

CF	=	0 if we found it
	=	1 otherwise

|

P2MML_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
P2MML_PHYS dd	?		; Physical address to translate
P2MML_CR3 dd	?		; MM's CR3
P2MML_MIN dd	?		; Minimum acceptable linear address

P2MML_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ebx,esi>	; Save registers

	movzx	ebx,SegCR3	; Get segment of CR3 (/4KB)
	shl	ebx,4-0 	; Convert from paras to bytes

@P2MML_LIN equ	-4*1024*1024	; Use this linear address (/4MB)

	push	AGROUP:[ebx+@P2MML_LIN shr ($LA_DIR-2)].EDD ; Save current value
	push	ebx		; Save the offset in AGROUP

	mov	eax,[bp].P2MML_CR3 ; Get the MM's CR3
	or	eax,@PTE_URP	; Mark as User/Read-write/Present
	mov	AGROUP:[ebx+@P2MML_LIN shr ($LA_DIR-2)],eax ; Put into place

; Flush the TLB

	mov	eax,cr3 	; Get current value
	mov	cr3,eax 	; Flush it

; Save the original Page Fault handler and install our own.

	sub	sp,size DTR_STR ; Make room for IDTR
	mov	bx,sp		; Address the stack
	SIDTD	ss:[bx].EDF	; Save on the stack
	mov	ebx,ss:[bx].DTR_BASE ; Get base address
	add	sp,size DTR_STR ; Strip from stack

	push	AGROUP:[ebx+0Eh*(type IDT_STR)].EDQHI ; Save high-order dword
	push	AGROUP:[ebx+0Eh*(type IDT_STR)].EDQLO ; ...
	push	ebx		; Save offset in AGROUP

	mov	AGROUP:[ebx+0Eh*(type IDT_STR)].IDT_SELECT,cs ; Save selector
	lea	eax,RUD_INT0E	; Get offset of our handler
	mov	AGROUP:[ebx+0Eh*(type IDT_STR)].IDT_OFFLO,ax ; ... offset
	shr	eax,16		; Shift to low-order
	mov	AGROUP:[ebx+0Eh*(type IDT_STR)].IDT_OFFHI,ax ; ... offset
	mov	AGROUP:[ebx+0Eh*(type IDT_STR)].IDT_ACCESS,CPL0_INTR3 ; ... A/R

	mov	esi,@P2MML_LIN	; Get linear address of the PTEs

	cld			; String ops forwardly
PHYS2MMLIN_NEXT:
	lods	AGROUP:[esi].EDD ; Get next PTE

	test	eax,mask $PTE_P ; Izit Present?
	jz	short PHYS2MMLIN_LOOPPTE ; Jump if not

	and	eax,@PTE_FRM	; Isolate the frame

	cmp	eax,[bp].P2MML_PHYS ; Izit the same physical address?
	je	short PHYS2MMLIN_FOUND ; Jump if so
PHYS2MMLIN_LOOPPTE:
	cmp	esi,@P2MML_LIN+4*1024*1024 ; Izit over?
	jne	short PHYS2MMLIN_NEXT ; Jump if not
PHYS2MMLIN_NOTFOUND:
	mov	eax,-1		; Mark as not found

	jmp	short PHYS2MMLIN_EXIT ; Join common exit code

PHYS2MMLIN_LOOPPDIR:
	add	esi,4*1024	; Skip to next PDIR

	jmp	short PHYS2MMLIN_LOOPPTE ; Go around again

PHYS2MMLIN_FOUND:
	mov	eax,esi 	; Copy next offset
	sub	eax,@P2MML_LIN+4 ; Convert to origin-0
	shl	eax,(12-2)-0	; Convert from 4KB in dwords to bytes

	cmp	eax,[bp].P2MML_MIN ; Izit below minimum acceptable?
	jb	short PHYS2MMLIN_LOOPPTE ; Jump if so (false positive)
PHYS2MMLIN_EXIT:

; Restore the previous Page fault handler

	pop	ebx		; Restore offset in AGROUP
	pop	AGROUP:[ebx+0Eh*(type IDT_STR)].EDQLO ; Restore low-order dword
	pop	AGROUP:[ebx+0Eh*(type IDT_STR)].EDQHI ; ...	 high-order ...

; Restore previous PDIR

	pop	ebx		; Restore offset in AGROUP
	pop	AGROUP:[ebx+@P2MML_LIN shr ($LA_DIR-2)].EDD ; Restore PDIR

; Flush the TLB

	mov	ebx,cr3 	; Get current value
	mov	cr3,ebx 	; Flush it

	cmp	eax,-1		; Did we find it?
	cmc			; CF=0 if found, CF=1 if not

	REGREST <esi,ebx>	; Restore

	pop	bp		; Restore

	ret	4+4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PHYS2MMLIN endp 		; End PHYS2MMLIN procedure
	FPPROC	RUD_INT0E -- INTRUDE Page Fault Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

INTRUDE Page Fault handler

|

	add	sp,4		; Strip off error code

RUDPF_STR struc

	dw	?		; Caller's BP
RUDPF_EIP dd	?		; ...	   EIP
RUDPF_CS  dw	?,?		; ...	   CS w/filler
RUDPF_EFL dd	?		; ...	   EFL

RUDPF_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

COMMENT|

In an earlier incarnation of this code, I skipped this PDIR and
continued on with the next one on the theory that the MM might have
non-contiguous present PDIRs.  Then I found one MM which overlaps the
GDT in the 4KB page used by CR3 which then looped through what we
thought were PDIRs but were really GDT entries.  The real problem was
that when we referenced a PDIR, the CPU set the accessed bit in the
PDIR entry which had the effect of changing the base address of some
GDT entries!  Now we take care to distinguish between those MMs which
have a full CR3 (via @DEV_FCR3) which also implies that they might
have some not-present PDIRs between the start and the linear addresses
we're looking for.

|

	push	ax		; Save for a moment

	mov	ax,RUDPF_NF	; Get offset of Not Found return point
	mov	[bp].RUDPF_EIP.ELO,ax ; Jump if PDIR not present

	pop	ax		; Restore

	pop	bp		; Restore

	iretd			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RUD_INT0E endp			; End RUD_INT0E procedure
	NPPROC	SET_RUDGDT -- Set INTRUDE GDT Entry
	assume	ds:nothing,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set INTRUDE GDT entry

|

SDG_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
SDG_ARB db	?		; A/R byte
SDG_FLG db	?		; Flags
SDG_DTE dw	?		; DTE
SDG_BASE dd	?		; Base address
SDG_LEN dd	?		; Length

SDG_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <eax,ebx,ecx>	; Save registers

	mov	eax,[bp].SDG_BASE ; Get base address
	movzx	ebx,[bp].SDG_DTE ; Get the DTE #
	and	bx,not (mask $PL) ; Clear the PL bits

	mov	ecx,[bp].SDG_LEN ; Get DTE length
	dec	ecx		; Convert from length to limit

	cmp	ecx,1024*1024	; Check against limit limit
	jb	short @F	; Jump if within range

	shr	ecx,12-0	; Convert from bytes to 4KB
	or	ecx,(mask $DTE_G) shl 16 ; Set G-bit
@@:
	add	ebx,RUDLaGDT	; Plus linear address of GDT in our space

	mov	AGROUP:[ebx].DESC_BASE01.EDD,eax
	rol	eax,8		; Rotate out the high-order byte
	mov	AGROUP:[ebx].DESC_BASE3,al ; Save as base byte #3
;;;;;;; ror	eax,8		; Rotate back
	mov	AGROUP:[ebx].DESC_SEGLM0,cx ; Save as data limit
	rol	ecx,16		; Swap high- and low-order words
	or	cl,[bp].SDG_FLG ; Include flags
	mov	AGROUP:[ebx].DESC_SEGLM1,cl ; Save as data limit and flags

	mov	al,[bp].SDG_ARB ; Get the A/R byte
	mov	AGROUP:[ebx].DESC_ACCESS,al ; Save in the GDT

	REGREST <ecx,ebx,eax>	; Restore

	pop	bp		; Restore

	ret	4+4+2+1+1	; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_RUDGDT endp 		; End SET_RUDGDT procedure
	NPPROC	FIND_GDTE -- Find GDT Entries
	assume	ds:nothing,es:AGROUP,fs:PGROUP,gs:RGROUP,ss:NGROUP
COMMENT|

Find GDT entries

On exit:

EDX	=	base selector

CF	=	0 if successful
	=	1 if not

|

FGDTE_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
FGDTE_NSELS dw	?		; # selectors needed

FGDTE_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <eax,ebx,ecx>	; Save registers

	mov	ebx,RUDLaGDT	; Get linear address of GDT in our space
	mov	edx,RUD_GDTLEN	; Get length of the GDT
FIND_GDTE_NEXTBLK:
	mov	cx,[bp].FGDTE_NSELS ; Get # entries needed
FIND_GDTE_NEXTDTE:
	cmp	edx,1+size DESC_STR ; Ensure enough room
	SETMSG	RUD,"Unable to find enough GDT entries."
	jb	short FIND_GDTE_EXIT ; Jump if none (note CF=1)

	sub	edx,size DESC_STR ; Skip back to the previous GDT entry

COMMENT|

Because of various MM's idea of what constitutes an unused GDT entry,
we limit our checking to a 32-bit base of zero and a limit of either
zero or 64KB.
		   Base      Limit    A/R  P/L
386MAX		 00000000   00000000  000   0
QEMM		 00000000   0000FFFF  0F2   3
NETROOM 	 00000000   00000FFF  D92   0
DRDOS		 00000000   00000000  000   0
MSDOS		 00000000   0000FFFF  000   0

|

	cmp	AGROUP:[ebx+edx].DESC_SEGLM0,0 ; Izit available?
	je	short @F	; Jump if so

	cmp	AGROUP:[ebx+edx].DESC_SEGLM0,-1 ; Izit available?
	jne	short FIND_GDTE_NEXTBLK ; Not this one
@@:
	cmp	AGROUP:[ebx+edx].DESC_BASE01,0 ; Izit available?
	jne	short FIND_GDTE_NEXTBLK ; Not this one

	cmp	AGROUP:[ebx+edx].DESC_BASE2,0 ; Izit available?
	jne	short FIND_GDTE_NEXTBLK ; Not this one

	cmp	AGROUP:[ebx+edx].DESC_BASE3,0 ; Izit available?
	jne	short FIND_GDTE_NEXTBLK ; Not this one

	mov	al,AGROUP:[ebx+edx].DESC_SEGLM1 ; Get limit and flags

	and	al,mask $SEGLM1 ; Isolate the limit bits
	jnz	short FIND_GDTE_NEXTBLK ; Not this one

	loop	FIND_GDTE_NEXTDTE ; Jump if more needed

	clc			; Mark as successful
FIND_GDTE_EXIT:
	REGREST <ecx,ebx,eax>	; Restore

	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_GDTE endp			; End FIND_GDTE procedure

NCODE	ends			; End NCODE segment

	MEND			; End SWAT_DR2 module
