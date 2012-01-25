;' $Header:   P:/PVCS/386SWAT/SWAT_DRV.ASV   1.37   29 Aug 1998 11:25:14   BOB  $
	title	SWAT_DRV -- 386SWAT Device Driver Routines
	page	58,122
	name	SWAT_DRV

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-2002 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, August, 1992.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include DOSCALL.INC
	include KEYCALL.INC
	include ASCII.INC
	include 386.INC
	include PTR.INC
	include DEVDRV.INC
	include MAXDEV.INC
	include CMOS.INC
	include CPUID.INC
	include A20.INC
	include HMA.INC
	include BIOSCONF.INC
	include 8253.INC
	include 8255.INC
	include 8259.INC
	include BITFLAGS.INC
	include MASM5.MAC
	include ALLMEM.INC
	include CPUFLAGS.INC
	include VCPI.INC
	include BIOSDATA.INC
	include SCANCODE.INC
	include INTVEC.INC
	include OPEN.INC
	include IOCTL.INC
	include XMS.INC
	include VDS.INC
	include SWATVXD.INC
	include WINDEVID.INC
	include INT2FAPI.INC
	include OPCODES.INC
	include WKD.INC

	include SWAT_DRV.INC
	include SWAT_FMT.INC
	include SWAT_LDT.INC
	include SWAT_SEG.INC
	include SWAT_WKD.INC

	include SWAT_FIL.INC
.list

CGROUP	group	CPUID_SEG


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP,ds:PGROUP

	public	@SWAT_DRV_PROG
@SWAT_DRV_PROG: 		; Mark module start in .MAP file

@HOOKINTS equ	<00,01,02,03,05,06,09,0B,0C,0D,67>

	extrn	INIT_PROT:far
	extrn	REST_PROT:far

	extrn	SWATINI:tbyte
	extrn	DEVLOAD:byte
	extrn	Phys2LinBias:dword

%	irp	XX,<@HOOKINTS,68>
if XX&h ne 09h
	extrn	LCL_RVM&XX:byte
endif
	endm

PROG	ends			; End PROG segment


DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	public	@SWAT_DRV_DATA16
@SWAT_DRV_DATA16 label byte	; Mark module start in .MAP file

	extrn	ARG_FLAG:word
	include SWAT_ARG.INC

	extrn	AR2_FLAG:word
	include SWAT_AR2.INC

	extrn	COMMON:tbyte
	extrn	INIT_COUNT:word
	extrn	WINVER:word

;;;;;;; extrn	MSG_FLVM:byte
	extrn	BLCLPDIR:dword
	extrn	PaTMPPAGE:dword
	extrn	EXTSYM_OFF:dword
	extrn	EXTSYM_LEN:dword
	extrn	RGRSEG2:word

	public	LaDEVINTCOM,LaRM_IDT
LaDEVINTCOM dd	?		; Linear address of DEVINTCOM
LaRM_IDT dd	?		; ...		    RM_IDT

	public	RUD_GDTR,RUD_IDTR
RUD_GDTR df	?		; Current GDTR for INTRUDEing
	align	4		; For alignment
RUD_IDTR df	?		; ...	  IDTR ...

DATA16	ends			; End DATA16 segment


RCODE0	segment use16 para public 'rcode' ; Start RCODE0 segment
	assume	cs:RGROUP,ds:RGROUP

	public	@SWAT_DRV_RCODE0
@SWAT_DRV_RCODE0:		; Mark module start in .MAP file

; DEV_SWATINI must be the first variable in this group

	public	DEV_SWATINI
DEV_SWATINI MD_STR <>		; Resident device driver header

; RSWAT_WKD must be the second entry, and
; RSWAT_INT41 must be the third entry in this group
; so that the corresponding variables in SWAT.ASM are
; at the same offset within the code segment

	public	RSWAT_WKDCB
RSWAT_WKDCB:
	jmp	near ptr DEV_WKDCB ; Jump to actual code


	nop			; Pad with NOPs to match
	nop			; USE32 JMP NEAR PTR ... in SWAT.ASM

	public	RSWAT_INT41
RSWAT_INT41:
	jmp	near ptr DEV_INT41 ; Jump to actual code


	nop			; Pad with NOPs to match
	nop			; USE32 JMP NEAR PTR ... in SWAT.ASM

	public	VCPSTK_FVEC
VCPSTK_FVEC df	VCPSTKZ-DEV_SWATINI ; Ptr to Device VCPI stack

	public	VCPSTK,VCPSTKZ
	align	4
VCPSTK	dd	32 dup (?)	; Device VCPI stack
VCPSTKZ label	dword		; Top of the stack

	align	16		; Fill tail with NOPs

RCODE0	ends			; End RCODE0 segment


RCODE	segment use16 para public 'rcode' ; Start RCODE segment
	assume	cs:RGROUP,ds:RGROUP

	public	@SWAT_DRV_RCODE
@SWAT_DRV_RCODE:		; Mark module start in .MAP file

	extrn	A20COM_I92:near
	extrn	A20COM_XT:near
	extrn	GATEA20:near
	extrn	DEGATEA20:near
	extrn	CHECKA20:near

	extrn	A20SUP:word
	extrn	ACTA20_COMSUB:word

	public	SWATLDT
SWATLDT DLDT_STR <>		; Device Drivers' LDT

	public	RMSDRV_VEC
RMSDRV_VEC dd	?		; Same as XMSDRV_VEC but in RGROUP

	public	RH_VEC
RH_VEC	dd	?		; Save area for request vector

	public	OLDDEV_WINCB_VEC
OLDDEV_WINCB_VEC dd ?		; Save area for previous Windows callback routine

	public	OLDDEV2F_VEC,OLDDEV68_VEC
OLDDEV2F_VEC dd ?		; Next handler in sequence for INT 2Fh
OLDDEV68_VEC dd ?		; ...				   68h

	public	DEVSTK_VEC
DEVSTK_VEC dd	?		; Save area for SS:SP

	public ROLDINT67_VEC
ROLDINT67_VEC dd ?		; Old INT 67h handler

	public	SWAT_VMAPI_VEC
SWAT_VMAPI_VEC dd 0		; Seg:Off of SWATVxD VM API entry point

	public	WKDDOT_TAB
WKDDOT_TAB WKDDOT_STR @WKDDOT_MAX dup (<0>) ; WKD dot command table

	public	RM_IDTRL
RM_IDTRL df	(size RM_IDT)-1 ; IDTR in local memory

	public	PTR_DEV_WINCB
PTR_DEV_WINCB dw RGROUP:RM_WINCB ; Offset of our Windows callback routine
				; If we're INTRUDing, it's DEV_WINCB

	public	DEV_CR3,DEV_GDTR,DEV_GDTR2,DEV_AGRSEL,DEV_IDTR
DEV_CR3 dd	?		; The MM's CR3
DEV_GDTR df	?		; ...	   GDTR
DEV_AGRSEL dw	?		; ...	   AGROUP data selector
DEV_GDTR2 df	?		; ...	   GDTR2
	align	4		; For alignment
DEV_IDTR df	?		; ...	   IDTR
@DEV_RCS equ	08h		; Arbitrary code selector for RGROUP
@DEV_RDS equ	10h		; ...	    data ...
@DEV_RSS equ	18h		; ...	    stack ...

	public	PE_MASK
PE_MASK dw	mask $PE	; PE mask unless VCPI (zero then)

	public	PTR_INIT_PROT,PTR_INIT_PROT2
	public	PTR_REST_PROT,PTR_REST_PROT2
PTR_INIT_PROT  df offset PGROUP:INIT_PROT
	align	4		; For alignment
PTR_INIT_PROT2 df offset PGROUP:INIT_PROT
	align	4		; For alignment
PTR_REST_PROT  df offset PGROUP:REST_PROT
	align	4		; For alignment
PTR_REST_PROT2 df offset PGROUP:REST_PROT

	public	DEV_WINVER
DEV_WINVER dw	?		; Windows version #

	public	WKDIDT_FVEC
WKDIDT_FVEC df	?		; Sel|Off to WKD IDT

	public	WKD_AGRSEL
WKD_AGRSEL dw	?		; Windows Kernel Debugger AGROUP data selector

	public	DEVINT41_FVEC,DEVINT41_ARB
DEVINT41_FVEC df ?		; Save area for old INT 41h handler in Windows
DEVINT41_ARB db ?		; A/R byte
	db	?		; For alignment

	public	WKD_SWATPHYS_CS,WKD_SWATPHYS_DS
WKD_SWATPHYS_CS dd ?		; Physical address of SWAT's code
WKD_SWATPHYS_DS dd ?		; ...			     data

	public	W386_SIS
W386_SIS Win386_Startup_Info_Struc <> ; Used to start with our VxD

	public	TRP_FLAG
TRP_FLAG dd	@TRP_I09 or \
		@TRP_I0B or \
		@TRP_I0C or \
		@TRP_I15 or \
		@TRP_WCB or \
		@TRP_I67 or \
		@TRP_I68 or \
		@TRP_WKD or \
		@TRP_VXD ; TRAPxxx flags

	public	SWATVXD_PRES
SWATVXD_PRES dw 0		; Offset of SWAT's VxD name if present
				; zero if not
	public	DEV_FLAG
DEV_FLAG dw	0		; Device driver flags

	public	IBV0,IBV1
IBV0	db	?		; Save area for SWAT's IBV0
IBV1	db	?		; ...		       IBV1

	FPPROC	DEV_STRA -- Resident/Non-resident Device Strategy Routine
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Resident/non-resident device driver strategy routine.

|

.8086
	mov	RH_VEC.VOFF,bx	; Save for later use
	mov	RH_VEC.VSEG,es
DOT386 p

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEV_STRA endp			; End DEV_STRA procedure
	FPPROC	DEV_INTR -- Resident Device Interrupt Routine
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Resident device driver interrupt routine.

|

	REGSAVE <bx,es> 	; Save registers

	les	bx,RH_VEC	; ES:BX ==> request header
	assume	es:nothing	; Tell the assembler about it

	STATUS	DONE,NOERROR	; Set status word (done, no error)

	REGREST <es,bx> 	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEV_INTR endp			; End DEV_INTR procedure
	FPPROC	DEV_GPMITAIL -- GPMI Tail Return Point
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

GPMI tail return point

On entry:

ES:DI	==>	tail of caller's PTE buffer

|

	VCPICALL @VCPI_GPMITAIL ; Call GPMI tail code in PM

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEV_GPMITAIL endp		; End DEV_GPMITAIL procedure
	NPPROC	CHECK_VMTF -- Check On VM And TF
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on VM and TF -- if either is set return ZF=0

On exit:

ZF	=	0 if either VM or TF set
	=	1 otherwise

|

	push	ax		; Save for a moment

	pushf			; Save flags to test TF
	pop	ax		; Save to test

	test	ax,mask $TF	; Izit set?
	jnz	short @F	; Jump if so (note ZF=0)

	smsw	ax		; Get MSW
	test	ax,PE_MASK	; Are we in VM?
				; Return with ZF=0 if so
@@:
	pop	ax		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_VMTF endp 		; End CHECK_VMTF procedure
	NPPROC	CHECK_VXD -- Check On SWAT VxD
	assume	ds:nothing,es:RGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on SWAT's VxD

On entry:

CX:BX	==>	incoming SIS

On exit:

|

	REGSAVE <ax,bx,dx,ds>	; Save for a moment

	mov	ax,SWATVXD_PRES ; Get VxD name presence flag (offset), 0=not

	cmp	ax,1		; Izit present?
	jb	short @F	; Jump if not (note CF=1)

	mov	W386_SIS.SIS_Virt_Dev_File_Ptr.VSEG,es ; Save as VxD name
	mov	W386_SIS.SIS_Virt_Dev_File_Ptr.VOFF,ax ; ...
	mov	W386_SIS.SIS_Next_Ptr.VSEG,cx ; Save as next ptr
	mov	W386_SIS.SIS_Next_Ptr.VOFF,bx ; ...
	mov	W386_SIS.SIS_Reference_Data.VSEG,cs ; Segment of local INT 67 ptr
	mov	W386_SIS.SIS_Reference_Data.VOFF,offset RGROUP:CHECK_VXD_INT67 ; Offset ...

	mov	dx,ax		; Get offset of name
	mov	ax,cs		; Get segment ...
	mov	ds,ax		; Address it
	assume	ds:RGROUP	; Tell the assembler about it

	mov	al,@OPEN_R	; Code for read-only
	DOSCALL @OPENF2 	; Request DOS services
	jc	short @F	; Jump if not present

	mov	bx,ax		; Copy to handle register
	DOSCALL @CLOSF2 	; Close it
@@:
	REGREST <ds,dx,bx,ax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller


COMMENT|

The following charade is necessary to mimic the behavior of SWATVXD in
its real mode installation.  See the comments in SWAT_RMI.ASM for
details.

|

CHECK_VXD_IRET:
	iret


CHECK_VXD_INT67:
	db	@OPCOD_JMPF	; Opcode for far jump immediate
	dw	offset RGROUP:CHECK_VXD_IRET ; Offset of IRET
	dw	seg PGROUP	; Segment ...

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_VXD endp			; End CHECK_VXD procedure
	FPPROC	RMDEV2F -- Multiplex Services Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Multiplex services interrupt handler

On entry:

If AX=1605,

ES:BX	==	 0:0
DS:SI	==	 0:0
DI	=	version # (major,minor)
CX	=	0
DX	=	flags
		 Bit 0 = 1 if Windows 286 DOS extender (standard mode)
		       = 0 if ...     386	       (enhanced mode)

On exit:

DS:SI	==>	Callback routine
ES:BX	==>	SIS
CX	=	0 if successful
	<>	0 if not

|

RM2F_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
	dw	?		; ...	   CS
RM2F_FL dw	?		; ...	   FL

RM2F_STR ends

	pushf			; Save flags for a moment

	call	CHECK_VMTF	; Check VM and TF
	jnz	short RMDEV2F_ORIG ; Jump if either is set

	cmp	ax,1605h	; Izit Windows Begin Initialization?
	jne	short RMDEV2F_ORIG ; Jump if not

	popf			; Restore flags

; Put caller's flags into effect

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack
	push	[bp].RM2F_FL	; Get caller's flags
	popf			; Put into effect
	pop	bp		; Restore

	pushf			; Simulate INT environment
	cli			; ...
	call	OLDDEV2F_VEC	; Continue with next handler in sequence

	and	cx,cx		; Izit failing?
	jnz	short RMDEV2F_DONE ; Jump if so

	mov	cx,es		; Save for a moment

	push	cs		; Get our code/data segment
	pop	es		; Address it
	assume	es:RGROUP	; Tell the assembler about it

	test	dx,@BIT0	; Izit 286 DOS extender?
	jnz	short @F	; Jump if so (no VxD for them)

; Ensure SWATVXD file is present on disk where we think it should be

	call	CHECK_VXD	; Check on it
	jc	short @F	; Jump if not present

	mov	cx,es		; Pass ptr to our SIS
	lea	bx,W386_SIS	; ES:BX ==> our SIS
@@:
	mov	DEV_WINVER,di	; Save for later use

	mov	OLDDEV_WINCB_VEC.VSEG,ds ; Save for later use
	mov	OLDDEV_WINCB_VEC.VOFF,si ; ...

	cmp	OLDDEV_WINCB_VEC,0 ; Is there a next handler?
	jne	short @F	; Jump if so

	mov	OLDDEV_WINCB_VEC.VSEG,cs ; Save for later use
	mov	OLDDEV_WINCB_VEC.VOFF,offset RGROUP:DEV_WINCB_CLC ; ...
@@:
	mov	es,cx		; Restore
	assume	es:nothing	; Tell the assembler about it

	xor	cx,cx		; Continue with success

	push	cs		; Get our code segment
	pop	ds		; Address it
	mov	si,PTR_DEV_WINCB ; DS:SI ==> our callback routine
RMDEV2F_DONE:
	ret	2		; Return to caller, popping flags


RMDEV2F_ORIG:
	popf			; Restore flags

	jmp	OLDDEV2F_VEC	; Continue with next handler in sequence

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RMDEV2F endp			; End RMDEV2F procedure
	NPPROC	DEV_EPM -- Enter PM For Windows Callback
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enter PM for Windows callback

|

	REGSAVE <eax>		; Save register

	LGDTD	DEV_GDTR	; Tell the CPU about incoming GDTR
	LIDTD	DEV_IDTR	; ...			      IDTR

	mov	eax,DEV_CR3	; Get the incoming CR3
	mov	cr3,eax 	; Tell the CPU about it

	mov	eax,cr0 	; Get current contents
	or	eax,(mask $PG) or (mask $PE) ; Enable paging and PE
	mov	cr0,eax 	; Tell the CPU about it

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEV_EPM endp			; End DEV_EPM procedure
	NPPROC	DEV_ERM -- Enter RM For Windows Callback
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enter RM from PM

|

	push	eax		; Save register

; Load base and limit of IDT for real mode
; Note that we do it here in case the FAR JMP below signals
; an error.

	LIDTD	RM_IDTRL	; Reset IDT to the table in local memory

; Exit protected mode

	mov	eax,cr0 	; Get current CR0
	and	eax,not ((mask $PG) or (mask $PE)) ; Turn off PG & PE bits
	mov	cr0,eax 	; Exit protected mode

; Jump to real mode code

;;;;;;; FIJMP	RGROUP:@F,<seg RGROUP> ; Far jump to set access rights
	db	0EAh		; Far jump immediate
	dw	RGROUP:@F
GOREAL_SEG dw	seg RGROUP
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it
@@:
	mov	eax,cr3 	; Get the current value
	mov	cr3,eax 	; Flush the TLB

	pop	eax		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEV_ERM endp			; End DEV_ERM procedure
	NPPROC	WINCB_DIS -- Windows Callback Disable
	assume	ds:RGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Windows callback disable
Paging is disabled

|

	REGSAVE <eax,ebx,ecx>	; Save for a moment

	mov	ebx,DEV_SWATINI.MD_PHYS ; Get physical address of code segment
	mov	ecx,DEV_SWATINI.MD_DATA ; Get the offset to data segment

; We're disabling, so we need to save the IBV values
; so we can restore them later.

	assume	gs:PGROUP	; Tell a white lie (use with EBX as index)
	mov	al,SWATINI[ebx].MD_IBV0 ; Get the original value
	mov	IBV0,al 	; Save it

	mov	al,SWATINI[ebx].MD_IBV1 ; Get the original value
	mov	IBV1,al 	; Save it
	assume	gs:AGROUP	; Retract nose

; Tell SWAT we'll be running under Windows and possibly be
; a Windows Kernel debugger

	mov	eax,@MD_WIN3	; Get Windows flag

	test	TRP_FLAG,@TRP_WKD ; Izit enabled?
	jz	short @F	; Jump if not

	or	eax,@MD_WKD	; Include WKD flag
@@:
	assume	gs:PGROUP	; Tell a white lie (use with EBX as index)
	or	SWATINI[ebx].MD_ATTR,eax ; Include new flags
;;;;;;; assume	gs:AGROUP	; Retract nose

; Save current FILE_4GB and FILE_CR3 selectors
; in	       FOLD_4GB and FOLD_CR3
; so we can restore them upon return

	assume	gs:DGROUP	; Tell a white lie (use with EBX+ECX as index)
	mov	ax,COMMON[ebx+ecx].FILE_4GB ; Get the all memory selector
	mov	COMMON[ebx+ecx].FOLD_4GB,ax ; Save for later use
	mov	ax,COMMON[ebx+ecx].FILE_CR3 ; Get the CR3 selector
	mov	COMMON[ebx+ecx].FOLD_CR3,ax ; Save for later use

; Save Windows version #

	mov	ax,DEV_WINVER	; Get windows version #
	mov	WINVER[ebx+ecx],ax ; Save for later use

	assume	gs:AGROUP	; Retract nose

	REGREST <ecx,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WINCB_DIS endp			; End WINCB_DIS procedure
	NPPROC	WINCB_ENA -- Windows Callback Enable
	assume	ds:nothing,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Windows callback enable

|

	REGSAVE <eax,ebx,ecx>	; Save registers

	mov	ebx,DEV_SWATINI.MD_PHYS ; Get physical address of code segment
	mov	ecx,DEV_SWATINI.MD_DATA ; Get the offset to data segment

; We're enabling, so we need to restore the IBV values
; before INIT_PROT is called; otherwise, INIT_PROT
; sets up the wrong IDT entries.

; Restore the original IBV values

	assume	gs:PGROUP	; Tell a white lie (use with EBX as index)
	mov	al,IBV0 	; Get the original value
	mov	SWATINI[ebx].MD_IBV0,al ; Restore

	mov	al,IBV1 	; Get the original value
	mov	SWATINI[ebx].MD_IBV1,al ; Restore
	assume	gs:AGROUP	; Retract nose

; Tell SWAT we're no longer running under Windows and no longer
; a Windows Kernel debugger

	assume	gs:PGROUP	; Tell a white lie (use with EBX as index)
	and	SWATINI[ebx].MD_ATTR,not (@MD_WIN3 or @MD_WKD or @MD_WSVC) ; Exclude new flags
;;;;;;; assume	gs:AGROUP	; Retract nose

; Restore FOLD_4GB and FOLD_CR3 selectors
; to	  FILE_4GB and FILE_CR3

	assume	gs:DGROUP	; Tell a white lie (use with EBX+ECX as index)
	mov	ax,COMMON[ebx+ecx].FOLD_4GB ; Get original all memory selector
	mov	COMMON[ebx+ecx].FILE_4GB,ax ; Restore
	mov	COMMON[ebx+ecx].FINT_4GB,ax ; ...
	mov	ax,COMMON[ebx+ecx].FOLD_CR3 ; Get the original CR3 selector
	mov	COMMON[ebx+ecx].FILE_CR3,ax ; Restore
	mov	COMMON[ebx+ecx].FINT_CR3,ax ; ...
	assume	gs:AGROUP	; Retract nose

; If we loaded as a device driver and are coming back from Windows,
; restore the bit settings

	assume	gs:PGROUP	; Tell a white lie (use with EBX as index)
	btr	DEVLOAD[ebx],$DEVL_WIN3 ; Were we device loaded?
	jnc	short @F	; Jump if not

	or	DEVLOAD[ebx],@DEVL_LOAD ; Mark as such
	assume	gs:AGROUP	; Retract nose
@@:

COMMENT|

Also, if the old (pre-WKD) VxD is active, it called REST_PROT for us.
However, if the new VxD is active, there was no call to REST_PROT (and
intentionally so, to enable us can debug farther into Windows
termination).  If the latter is the case, we need to decrement
INIT_COUNT so INIT_PROT runs.

|

	assume	gs:DGROUP	; Tell a white lie (use with EBX+ECX as index)
	cmp	INIT_COUNT[ebx+ecx],0 ; Izit normal?
	je	short @F	; Jump if so

	dec	INIT_COUNT[ebx+ecx] ; Count out another instance
@@:
	assume	gs:AGROUP	; Retract nose

	REGREST <ecx,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WINCB_ENA endp			; End WINCB_ENA procedure
	FPPROC	DEV_WINCB -- Windows Callback Routine
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Windows callback routine used when it wants to gain/return control
from/to the memory manager.

This routine is called when SWAT intrudes into an existing MM.

On entry:

IF	=	0	Interrupts are disabled
AX	=	0	If we're to disable ourselves (we're in VM -> RM)
	=	1	If we're to re-enable ourselves (we're in RM -> VM)
ESI	=	???	For AX=0, if a certain flag inside Windows is set
EDI	=	???	...(checked for via TEST CS:[001A],0040h in Win98SE)

On exit:

If disabling ourselves (AX = 0),

CF	=	0	if successful
	=	1	if not

|

DEVEPM_MAC macro PTR_PROT,DISABLE

	pushf			; Save caller's return result in CF

	REGSAVE <eax,ebx,ds,es,fs,gs> ; Save for a moment
.8086
	mov	DEVSTK_VEC.VOFF,sp ; Save to restore later
	mov	DEVSTK_VEC.VSEG,ss ; ...
DOT386 p
	xor	eax,eax 	; Zero to use as dword
	mov	ds,ax		; Ensure valid in PM
	mov	es,ax		; ...
	mov	fs,ax		; ...
	mov	gs,ax		; ...
	mov	ax,cs		; Get our CS
	shl	eax,4-0 	; Convert from paras to bytes

	call	DEV_EPM 	; Enter PM

; Because we need a footprint here in low DOS, we need to
; grab a GDT entry for our code and stack.  Arbitrarily, we pick
; entries low in the GDT, save our base address into them
; and restore them upon return.

	mov	gs,DEV_AGRSEL	; Get the MM's AGROUP selector
	assume	gs:AGROUP	; Tell the assembler about it

	mov	ebx,DEV_GDTR.DTR_BASE ; Get the GDT's base address

	push	AGROUP:[ebx+@DEV_RCS].EDQHI ; Save high-order dword
	push	AGROUP:[ebx+@DEV_RCS].EDQLO ; ...  low-...

	push	AGROUP:[ebx+@DEV_RDS].EDQHI ; Save high-order dword
	push	AGROUP:[ebx+@DEV_RDS].EDQLO ; ...  low-...

	push	AGROUP:[ebx+@DEV_RSS].EDQHI ; Save high-order dword
	push	AGROUP:[ebx+@DEV_RSS].EDQLO ; ...  low-...

; Setup code and data selectors

	mov	AGROUP:[ebx+@DEV_RCS].DESC_BASE01,ax ; Save bytes 0-1
	mov	AGROUP:[ebx+@DEV_RDS].DESC_BASE01,ax ; ...
	shr	eax,16		; Shift down high-order word
	mov	AGROUP:[ebx+@DEV_RCS].DESC_BASE2,al ; Save byte 2
	mov	AGROUP:[ebx+@DEV_RDS].DESC_BASE2,al ; ...
	mov	AGROUP:[ebx+@DEV_RCS].DESC_BASE3,ah ; Save byte 3
	mov	AGROUP:[ebx+@DEV_RDS].DESC_BASE3,ah ; ...
	mov	AGROUP:[ebx+@DEV_RCS].DESC_SEGLM0,-1 ; Save as segment limit
	mov	AGROUP:[ebx+@DEV_RDS].DESC_SEGLM0,-1 ; ...
	mov	AGROUP:[ebx+@DEV_RCS].DESC_SEGLM1,0  ; ...
	mov	AGROUP:[ebx+@DEV_RDS].DESC_SEGLM1,0  ; ...
	mov	AGROUP:[ebx+@DEV_RCS].DESC_ACCESS,CPL0_CODE ; Save A/R byte
	mov	AGROUP:[ebx+@DEV_RDS].DESC_ACCESS,CPL0_DATA ; ...

; Setup stack selector

	movzx	eax,DEVSTK_VEC.VSEG ; Get stack segment
	shl	eax,4-0 	; Convert from paras to bytes

	mov	AGROUP:[ebx+@DEV_RSS].DESC_BASE01,ax ; Save bytes 0-1
	shr	eax,16		; Shift down high-order word
	mov	AGROUP:[ebx+@DEV_RSS].DESC_BASE2,al ; Save byte 2
	mov	AGROUP:[ebx+@DEV_RSS].DESC_BASE3,ah ; Save byte 3
	mov	AGROUP:[ebx+@DEV_RSS].DESC_SEGLM0,-1 ; Save as segment limit
	mov	AGROUP:[ebx+@DEV_RSS].DESC_SEGLM1,0  ; ...
	mov	AGROUP:[ebx+@DEV_RSS].DESC_ACCESS,CPL0_DATA ; Save A/R byte

	mov	ax,@DEV_RDS	; Get the data selector
	mov	ds,ax		; Address it
	assume	ds:RGROUP	; Tell the assembler about it

	mov	ax,@DEV_RSS	; Get the stack selector
	mov	ss,ax		; Address it
	movzx	esp,sp		; Zero to use as dword

	push	@DEV_RCS	; Pass code selector
	push	offset RGROUP:@F ; ...	    offset
	retf			; "Jump" to that location to set A/R
@@:
ifnb <DISABLE>
	call	WINCB_DIS	; Disable ourselves so W can enter PM
else
	call	WINCB_ENA	; Enable ourselves so we can run IN RM/VM
endif

; Tell our code upstairs to run &PRT_PROT

	call	PTR_PROT	; Call &PTR_PROT in PM

; Ensure all selectors have 64KB-1 limit
; except for GS which we need for the POPs which restore
; the original DTEs.  This means that GS has a larger limit
; than it should, but that should be harmless.

	mov	ax,ss		; Copy stack selector

	mov	ds,ax		; Ensure valid limit
	assume	ds:nothing	; Tell the assembler about it

	mov	es,ax		; ...
	assume	es:nothing	; ...

	mov	fs,ax		; ...
	assume	fs:nothing	; ...

;;;;;;; mov	gs,ax		; ...
;;;;;;; assume	gs:nothing	; ...

; Note that the DTEs for CS, DS, and SS are no longer valid after
; the following POPs

	pop	AGROUP:[ebx+@DEV_RSS].EDQLO ; Restore low-order dword
	pop	AGROUP:[ebx+@DEV_RSS].EDQHI ; ...     high-...

	pop	AGROUP:[ebx+@DEV_RDS].EDQLO ; Restore low-order dword
	pop	AGROUP:[ebx+@DEV_RDS].EDQHI ; ...     high-...

	pop	AGROUP:[ebx+@DEV_RCS].EDQLO ; Restore low-order dword
	pop	AGROUP:[ebx+@DEV_RCS].EDQHI ; ...     high-...

	call	DEV_ERM 	; Enter RM
	assume	ds:nothing,es:nothing ; Tell the assembler about it
	assume	fs:nothing,gs:nothing ; Tell the assembler about it

; Note that SS still has the PM selector value and
; its descriptor cache has not been changed.

	lss	sp,DEVSTK_VEC	; Restore

	REGREST <gs,fs,es,ds,ebx,eax> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it
	assume	fs:nothing,gs:nothing ; Tell the assembler about it

	popf			; Restore flags on entry

	endm			; DEVEPM_MAC


	cmp	ax,1		; Izit re-enable?
	je	near ptr DEV_WINCB_ENA ; Jump if so

; If asked to, signal a breakpoint

	test	TRP_FLAG,@TRP_DBGWCB ; Are we debugging?
	jz	short @F	; Jump if not

	int	01h		; Call our debugger
@@:
	SGDTD	DEV_GDTR	; Save current GDTR
	SIDTD	DEV_IDTR	; ...	       IDTR

; We're in VM

	call	OLDDEV_WINCB_VEC ; Continue with next handler in sequence

; We're in RM -- enter PM to call REST_PROT, then return to RM

	DEVEPM_MAC PTR_REST_PROT,DISABLE

	ret			; Return to caller

; It's time to re-enable ourselves

DEV_WINCB_ENA:

; We're in RM -- enter PM to call INIT_PROT, then return to RM

	DEVEPM_MAC PTR_INIT_PROT

	call	OLDDEV_WINCB_VEC ; Continue with next handler in sequence

; If we're on a VME system, we need to restore the SIRB values

	REGSAVE <ax,bx> 	; Save registers

	mov	bx,-1		; Tell SWAT to ignore this value
	XVCPICALL @VCPI_DBGHOST,R ; Set host feature flags

	REGREST <bx,ax> 	; Restore
DEV_WINCB_CLC:
	clc			; Indicate we succeeded

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEV_WINCB endp			; End DEV_WINCB procedure
	FPPROC	DEV_WKDCB -- Windows Kernel Debugger Callback
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Windows kernel debugger callback
This routine is called in PM only.

This is the low DOS version of PMINIT (as the WDEB386 docs call it).

The initial calls to PMINIT are made with AL = (0, 2, 5, 6, 4, 7) or
(0, 2, 5, 1, 3, 4, 7).	Calls 0, 1, 2, 5, 6 are made in low DOS and
are handled by DEV_WKDCB.  After function 1 is called, the base of
the code selector is changed to be in extended memory, so the rest
of the calls are handled by PM_WKDCB in extended memory.

On entry:

AL	=	0:  Initialize IDT
  ES:EDI ==>	IDT
  Note that we don't fill in the IDT at this time as W has
  not filled in its PTEs as yet beyond the first megabyte
  (no high DOS either).

AL	=	1:  Initialize page checking
  BX	=	physical selector
  ECX	=	linear bias

AL	=	2:  Debug queries are supported (via PM INT 22h)

AL	=	3:  Set spare PTE
  EBX	=	linear address of spare PTE contents
  EDX	=	linear address of spare PTE

AL	=	4:  Set VMM routine address
  EBX	=	Enter VMM routine address
  ECX	=	Exit ...
  EDX	=	_Trace_Out_Service
  ESI	=	_Debug_Out_Service

AL	=	5:  Get debugger size/physical address
  Returns
  AL	=	0 (don't call AL=1, Initialize page checking)
  ECX	=	debugger size in bytes
  ESI	=	debugger starting physical address
		if this call is ignored, then AL=1 is called

AL	=	6:  Set debugger base/spare PTE
  EBX	=	linear address of spare PTE contents
  EDX	=	linear address of spare PTE
  ESI	=	debugger starting linear address

AL	=	7:  Enable memory context functions

|

	cmp	al,@PMINIT_INIT_IDT ; Izit IDT initialization?
	je	short DEV_WKDCB_INITIDT ; Jump if so

	cmp	al,@PMINIT_INIT_PAGING ; Izit Page Checking?
	je	short DEV_WKDCB_PAGECHK ; Jump if so

	cmp	al,@PMINIT_ENABLE_DEBUG_QUERIES ; Izit Enable Debug Queries?
	je	near ptr DEV_WKDCB_ENABLE_DEBUG_QUERIES ; Jump if so

;;;;;;; cmp	al,@PMINIT_INIT_SPARE_PTE ; Izit Set Spare PTE?
;;;;;;; je	near ptr DEV_WKDCB_SETPTE ; Jump if so
;;;;;;;
;;;;;;; cmp	al,@PMINIT_SET_ENTER_EXIT_VMM ; Izit Set Enter/Exit VMM Address?
;;;;;;; je	near ptr ???	; Jump if so
;;;;;;;
	cmp	al,@PMINIT_GET_SIZE_PHYS ; Izit Get debugger size/physical address?
	je	near ptr DEV_WKDCB_GETSIZE ; Jump if so

;;;;;;; cmp	al,@PMINIT_SET_BASE_SPARE_PTE ; Izit Set debugger base/spare PTE?
;;;;;;; je	near ptr DEV_WKDCB_SETBASE ; Jump if so
;;;;;;;
;;;;;;; cmp	al,@PMINIT_ENABLE_MEMORY_CONTEXT ; Izit Enable Memory Contexts?
;;;;;;; je	near ptr ???	; Jump if so
;;;;;;;
	int	03h		; Call ourselves

	jmp	DEV_WKDCB_EXIT	; Join common exit code


COMMENT|

Set PM IDT

On entry:

AL	=	0
ES:EDI	==>	PM IDT

On exit:

nothing

|

DEV_WKDCB_INITIDT:
	REGSAVE <eax,ds>	; Save for a moment

	mov	ax,cs		; Get code selector
	add	ax,size DESC_STR ; Skip to data selector
	mov	ds,ax		; Address it
	assume	ds:RGROUP	; Tell the assembler about it

	mov	WKDIDT_FVEC.FSEL,es ; Save for later use
	mov	WKDIDT_FVEC.FOFF,edi ; ...

; Fill in INT 41h to catch messages

	lea	eax,RSWAT_INT41 ; Get the offset
	xchg	es:[edi+41h*(type IDT_STR)].IDT_OFFLO,ax ; Save low-order word
	ror	eax,16		; Shift down the high-order word
	xchg	es:[edi+41h*(type IDT_STR)].IDT_OFFHI,ax ; Save high-order word
	rol	eax,16		; Shift back
	mov	DEVINT41_FVEC.FOFF,eax ; Save to restore later
	mov	ax,cs		; Get our selector
	xchg	es:[edi+41h*(type IDT_STR)].IDT_SELECT,ax ; Save selector
	mov	DEVINT41_FVEC.FSEL,ax ; Save to restore later
	mov	al,es:[edi+41h*(type IDT_STR)].IDT_ACCESS ; Get A/R byte
	mov	DEVINT41_ARB,al ; Save to restore later

	REGREST <ds,eax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	jmp	DEV_WKDCB_EXIT	; Join common exit code


COMMENT|

It's Page Checking time.

This means that W has finally hooked up some more PTEs sufficient for
us to be able to relocate our GDT entries

On entry:

AL	=	1
BX	=	physical selector
ECX	=	linear bias

On exit:

nothing

|

DEV_WKDCB_PAGECHK:
	pushad			; Save registers
	REGSAVE <ds,es> 	; Save registers

	mov	ax,cs		; Get code selector
	add	ax,size DESC_STR ; Skip to data selector
	mov	ds,ax		; Address it
	assume	ds:RGROUP	; Tell the assembler about it

	mov	PTR_INIT_PROT2.FSEL,cs ; Save for later use
	mov	PTR_REST_PROT2.FSEL,cs ; ...

	mov	es,WKD_AGRSEL	; Get all memory selector
	assume	es:AGROUP	; Tell the assembler about it

	SGDTD	DEV_GDTR2	; Save current GDTR

	mov	eax,DEV_GDTR2.DTR_BASE ; Get linear address

	mov	ebx,WKD_SWATPHYS_CS ; Get SWAT's physical address for CS
	add	ebx,ecx 	; Add in linear bias

	assume	es:PGROUP	; Tell a white lie
	mov	SWATINI[ebx].MD_IPROT.FSEL,cs ; Save for later use
	mov	SWATINI[ebx].MD_RPROT.FSEL,cs ; ...

; Put new IBV values into effect
; The old values are saved and restored in DEV_WINCB

@WINDOWS_IBV0	equ	50h	; Master PIC base (according to Aaron Reynolds)
@WINDOWS_IBV1	equ	58h	; Slave  PIC base ???

	mov	SWATINI[ebx].MD_IBV0,@WINDOWS_IBV0 ; Update IBV0 in SWAT
	mov	SWATINI[ebx].MD_IBV1,@WINDOWS_IBV1 ; ...    IBV1 ...

	mov	Phys2LinBias[ebx],ecx ; Save for later use

	assume	es:AGROUP	; Retract nose

	xor	edx,edx 	; Zero to use as dword
	mov	dx,cs		; Get SWAT's code selector

	mov	AGROUP:[eax+edx].DESC_BASE01,bx ; Save bytes 0-1
	ror	ebx,16		; Swap high- and low-order words
	mov	AGROUP:[eax+edx].DESC_BASE2,bl ; Save byte 2
	mov	AGROUP:[eax+edx].DESC_BASE3,bh ; ...	   3
	or	AGROUP:[eax+edx].DESC_SEGLM1,mask $DTE_B ; Set D-bit for USE32
;;;;;;; ror	ebx,16		; Restore original address

; Note that our current code selector is now running on the IDC

	mov	ebx,WKD_SWATPHYS_DS ; Get SWAT's physical address for DS
	add	ebx,ecx 	; Add in linear bias

	mov	AGROUP:[ebx].FILE_4GB,es ; Save our all memory selector

	add	dx,size DESC_STR ; Skip to 2nd (data) selector

	mov	AGROUP:[eax+edx].DESC_BASE01,bx ; Save bytes 0-1
	ror	ebx,16		; Swap high- and low-order words
	mov	AGROUP:[eax+edx].DESC_BASE2,bl ; Save byte 2
	mov	AGROUP:[eax+edx].DESC_BASE3,bh ; ...	   3
	ror	ebx,16		; Restore original address

; Note that our current code selector is now running on the IDC

; Setup SWAT's CR3 selector

	add	dx,size DESC_STR ; Skip to 3rd (CR3) selector
	mov	AGROUP:[ebx].FILE_CR3,dx ; Save our CR3 selector
	mov	AGROUP:[ebx].FINT_CR3,dx ; ...

	mov	ebx,cr3 	; Get current value
	and	ebx,@PTE_FRM	; Isolate the 4KB frame
	add	ebx,ecx 	; Add in linear bias

; Technically we should add in the base of the incoming selector BX

	mov	AGROUP:[eax+edx].DESC_BASE01,bx ; Save bytes 0-1
	shr	ebx,16		; Shift down the high-order word
	mov	AGROUP:[eax+edx].DESC_BASE2,bl ; Save byte 2
	mov	AGROUP:[eax+edx].DESC_BASE3,bh ; ...	   3

; Fill in code and data selectors for WKD registered dot commands

	mov	ecx,@WKDDOT_MAX ; Get maximum # registered dot commands
	xor	ebx,ebx 	; Initialize index into WKDDOT_TAB
	mov	ax,WKD_AGRSEL	; Get all memory selector
	mov	dx,ax		; ...
	sub	dx,size DESC_STR ; Back off to code selector
@@:
	mov	WKDDOT_TAB[ebx].WKDDOT_HLP.FSEL,ax ; Save for later use
	mov	WKDDOT_TAB[ebx].WKDDOT_ACT.FSEL,dx ; ...

	add	ebx,type WKDDOT_STR ; Skip to next entry

	loop	@B		; Jump if more registerable dot commands

	REGREST <es,ds> 	; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it
	popad			; ...

; Now tell SWAT to initialize itself

	jmp	PTR_INIT_PROT2	; Join common code (note that it exits
				; via a RETFD, the same way in which
				; we were called)
				; Note we can't call this address as our
				; return address isn't valid because the
				; execution of INIT_PROT changes the base
				; address of CS.


COMMENT|

Enabe debug queries (dot commands, etc.)

On entry:

AL	=	2

|

DEV_WKDCB_ENABLE_DEBUG_QUERIES:
	jmp	short DEV_WKDCB_EXIT ; Join common exit code


COMMENT|

Get debugger size and physical address

On entry:

AL	=	5

On exit:

AL	=	0 (don't call AL=1)
ECX	=	debugger size in bytes
ESI	=	debugger starting physical address

|

DEV_WKDCB_GETSIZE:
;;;;;;; mov	al,0		; Tell 'em not to call AL=1
;;;;;;; mov	ecx,DEV_SWATINI.MD_SIZE ; Get size of initialized data
;;;;;;; add	ecx,DEV_SWATINI.MD_USIZE ; Plus size of uninitialized data
;;;;;;; mov	esi,DEV_SWATINI.MD_PHYS ; Get starting physical address

	jmp	short DEV_WKDCB_EXIT ; Join common exit code


COMMENT|

Set debugger base address and spare PTE

On entry:

AL	=	6
EBX	=	linear address of spare PTE contents
EDX	=	linear address of spare PTE
ESI	=	debugger starting linear address

|

DEV_WKDCB_SETBASE:


;;;;;;; jmp	short DEV_WKDCB_EXIT ; Join common exit code


DEV_WKDCB_EXIT:
	RETFD			; Return to 32-bit caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEV_WKDCB endp			; End DEV_WKDCB procedure
	FPPROC	DEV_INT41 -- Windows Kernel Debugger PM Interface
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Windows kernel debugger PM interface

This interrupt is called from PM under control of Windows only if we
responded to the appropriate INT 68h inquiry function.

At this point, CS and CS+8 point to RGROUP; DGROUP isn't initialized
until AL=1 in PMINIT.

On entry:

AX	=    *	004Fh	Debugger identification (returns AX=@DEB_PRESENT if so)
	=    *	005Bh	VCPI Windows 286 (Windows SETUP uses this)
	=    *	0070h	Register a 32-bit dot command
	=    * 0F001h	Conditional breakpoint

*	=	actually seen

On exit:

Depends upon the function.

|

	cmp	ax,@I41_DEBLOADED ; Izit debugger identification?
	je	short DEV_INT41_IDENT ; Jump if so

	cmp	ax,@I41_VCPI_NOTE ; Izit Windows 286?
	je	short DEV_INT41_VCPI ; Jump if so

	cmp	ax,@I41_REG_DOT32 ; Izit register a 32-bit dot command?
	je	short DEV_INT41_REG_DOT32 ; Jump if so

	cmp	ax,@I41_COND_BP ; Izit conditional breakpoint?
	je	short DEV_INT41_CBRK ; Jump if so

	REGSAVE <eax,ds>	; Save for a moment

	mov	eax,cs		; Get code selector
	add	eax,size DESC_STR ; Skip to data selector
	mov	ds,eax		; Address it
	assume	ds:RGROUP	; Tell the assembler about it

	test	TRP_FLAG,@TRP_INS ; Are we in INSERT mode?
	REGREST <ds,eax>	; Restore
	assume	ds:nothing	; Tell the assembler about it
	jz	short @F	; Jump if not

	int	01h		; Call ourselves
@@:
	iretd			; Return to caller


COMMENT|

Debugger identification

On entry:

AX	=	004Fh

On exit:

AX	=	@DEB_PRESENT

|

DEV_INT41_IDENT:
	mov	ax,@DEB_PRESENT ; Mark as present

	iretd			; Return to caller


COMMENT|

VCPI Windows 286

On entry:

AX	=	005Bh

ES:DI	==>	VCPEPM_STR struc

|

DEV_INT41_VCPI:
	iretd			; Return to caller


COMMENT|

Register a 32-bit dot command

On entry:

AX	=	0070h
BL	=	command character (e.g. "M")
ESI	=	linear address of dot command routine (RETFD)
   Dot command routine:
       ENTRY:	AL = command character
		DS, ES = flat data selector

       EXIT:	AX == 0, no errors
		AX != 0, command line or option error

       NOTE:	MUST return with a 32 bit FAR return (retfd)
EDI	=	linear address of help text

On exit:

AX	=	0 if successful
	!=	0 if dot command already used or out of dot commands

|

DEV_INT41_REG_DOT32:
	REGSAVE <ecx,edx,ds>	; Save for a moment

	mov	edx,cs		; Get code selector
	add	edx,size DESC_STR ; Skip to data selector
	mov	ds,edx		; Address it
	assume	ds:RGROUP	; Tell the assembler about it

	mov	ecx,@WKDDOT_MAX ; Get maximum # of registered WKD dot commands
	xor	edx,edx 	; Initialize index into WKDDOT_TAB
@@:
	cmp	WKDDOT_TAB[edx].WKDDOT_CHR,0 ; Izit empty?
	je	short @F	; Jump if so

	cmp	WKDDOT_TAB[edx].WKDDOT_CHR,bl ; Izit already in use?
	je	short DEV_INT41_REG_DOT32_EXIT ; Jump if so (note AX != 0)

	add	edx,type WKDDOT_STR ; Skip to next entry

	loop	@B		; Jump if more entries

	jmp	short DEV_INT41_REG_DOT32_EXIT ; Jump if no more entries
				; Note AX != 0

@@:
	mov	WKDDOT_TAB[edx].WKDDOT_CHR,bl ; Save the char
	mov	WKDDOT_TAB[edx].WKDDOT_ACT.FOFF,esi ; ... routine offset
	mov	WKDDOT_TAB[edx].WKDDOT_HLP.FOFF,edi ; ... help offset

	xor	ax,ax		; Mark as successful
DEV_INT41_REG_DOT32_EXIT:
	REGREST <ds,edx,ecx>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Return to caller


COMMENT|

Conditional breakpoint

This function is called after we've told W that we're a WKD (INT
68h/AH=43h) and after W has taken control and told us where its IDT is
(PMINIT/AL=0) but before we've had a chance to hook up our interrupts
in extended memory (we're waiting for PMINIT/AL=1).

We just ignore it (so there).  BTW, if we don't hook up an interrupt
to ignore this call, the system crashes.

On entry:

AX	=	0F001h
ESI	==>	ASCIIZ string to display

On exit:

Nothing

|

DEV_INT41_CBRK:
	iretd			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEV_INT41 endp			; End DEV_INT41 procedure
	FPPROC	DEV_INT68 -- Windows Kernel Debugger RM Interface
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Windows kernel debugger RM/VM interface

This routine is called in RM/VM only.

On entry:

AH	=     * 43 Debugger identification
	=	44 Prepare for PM operation
	=     * 45 Re-init for RM as Windows is about to exit (Win95)
	=	46 Set debugging switches
	=     * 47 Conditional break
	=	48 Undefine RM segment's symbols
	=	49 Set COM port baud rate
	=	4A Re-initialize debugger for PM
	=	4B Define debugger's segments
	=	4C Define COM port #
	=	4D Link SYM file map
	=	4E Unlink SYM file maps
	=	4F Remove any undefined segments from the module's symbols
	=	50 Define a segment/selector for symbol processing
	=	51 Display a character to debugging window
	=	52 Display an ASCIIZ string to the debugging window
	=	53 Is debug vXD installed?
	=	54 Set debug VxD installed
	=	55 Registers dot command
	=	56 De-registers dot command
	=	57 Printf
	=	58 Link symbol file with physical address
	=	59 Pointer to module name
	=	5A Autoload symbols on/off
	=	5B TEFTI port address
	=	5C Execute debugger command script
	=	5D Copy debugger code/data high
	=	5E Sets Windows version #
	=	5F Scan for character
	=	60 Ungetchar
	=	61 Stop at CS:IP

*	=	actually seen

On exit:

Depends upon the function

|

	test	TRP_FLAG,@TRP_I68 ; Izit enabled?
	jz	short DEV_INT68_ORIG ; Jump if not

	cmp	ah,@I68_IDENTIFY ; Izit debugger identification?
	je	short DEV_INT68_IDENT ; Jump if so

	cmp	ah,@I68_RM_INIT ; Izit re-init for RM?
	je	short DEV_INT68_RPROT ; Jump if so

	cmp	ah,@I68_EXEC_COND ; Izit conditional break?
	je	short DEV_INT68_CBRK ; Jump if so

	int	03h		; Not handled as yet *FIXME*

	iret			; Return to caller


DEV_INT68_ORIG:
	jmp	OLDDEV68_VEC	; Continue with next handler


COMMENT|

Debugger identification (called from RM/VM)

The only time this routine sees this function is if
NOWINK is specified in the 386SWAT profile which we
should respect.

On entry:

AH	=	43h

On exit:

AX	=	@DEB_PRESENT

|

DEV_INT68_IDENT:
	iret			; Return to caller

COMMENT|

Re-initialization for RM

This function is handled by the Win CB Enable (AX=1).

On entry:

AH	=	45h

On exit:

Nothing

|

DEV_INT68_RPROT:
	iret			; Return to caller

COMMENT|

Conditional break

On entry:

AH	=	47h
ES:SI	==>	ASCIIZ string to display

On exit:

Nothing

|

DEV_INT68_CBRK:

; Check for SWAT VxD presence

	cmp	SWAT_VMAPI_VEC,0 ; Izit unspecified?
	jne	short DEV_INT68_CBRK1 ; Jump if not

	REGSAVE <ax,bx,di,ds,es> ; Save for a moment

	mov	ax,cs		; Get code segment
	mov	ds,ax		; Address it
	assume	ds:RGROUP	; Tell the assembler about it

	xor	di,di		; Set ES:DI = 0:0
	mov	es,di		; ...
	assume	es:nothing	; Tell the assembler about it

	mov	bx,SWAT_Device_ID ; Get SWAT VxD's ID
	mov	ax,1684h	; Get function code for Device API entry point
	int	2Fh		; Request API service
	assume	es:nothing	; Tell the assembler about it

	mov	SWAT_VMAPI_VEC.VOFF,di ; Save for later use
	mov	SWAT_VMAPI_VEC.VSEG,es ; ...

	REGREST <es,ds,di,bx,ax> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	cmp	SWAT_VMAPI_VEC,0 ; Izit invalid?
	je	short DEV_INT68_CBRK2 ; Jump if so
DEV_INT68_CBRK1:
	REGSAVE <ax,ds> 	; Save for a moment

	mov	ax,es		; Copy ASCIIZ string segment
	mov	ds,ax		; Address it (DS:SI ==> ASCIIZ string)
	assume	ds:nothing	; Tell the assembler about it

	mov	ax,SWATVM_Out_Mono_String ; Get function code
	call	SWAT_VMAPI_VEC	; Request SWAT service

	REGREST <ds,ax> 	; Restore
	assume	ds:nothing	; Tell the assembler about it

	iret			; Return to caller


DEV_INT68_CBRK2:
	pusha			; Save registers
	REGSAVE <ds>		; ...

	mov	di,si		; ES:DI ==> ASCIIZ string to display
	mov	cx,-1		; We know it's there
	mov	al,0		; What to search for
	cld			; String ops forwardly
  repne scas	es:[di].LO	; Search for it
	neg	cx		; Negate to get length
	dec	cx		; Account for original -1
	dec	cx		; Account for trailing zero

	mov	ax,es		; Get segment of string
	mov	ds,ax		; Address it
	assume	ds:nothing	; Tell the assembler about it

	mov	dx,si		; DS:DX ==> string to display
	mov	bx,@STD_ERR	; Send to standard error handle
	DOSCALL @WRITF2 	; Write it out

	REGREST <ds>		; Restore
	assume	ds:nothing	; Tell the assembler about it
	popa			; ...

	iret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEV_INT68 endp			; End DEV_INT68 procedure

	public	DEV_INTRZ
DEV_INTRZ label byte		; Last byte in header if we're INTRUDEing

	public	SWATGDT
	align	4		; Ensure dword-aligned
SWATGDT XDTE_STR <>		; Device driver's GDT

	public	SWATGDTR,SWATIDTR
SWATGDTR equ	SWATGDT.DTE_GDT.EDF ; DTR for GDT in low memory
SWATIDTR equ	SWATGDT.DTE_IDT.EDF ; ...     IDT in extended memory

	public	SAVE_EAX,SAVE_ESI
SAVE_EAX dd	?		; Save area
SAVE_ESI dd	?		; ...

	public	VCPEPM
VCPEPM	VCPEPM_STR <>		; VCPI Enter PM Structure

	public	LaVCPEPM
LaVCPEPM dd	?		; Linear address of VCPEPM

	public	PMI_FVEC
PMI_FVEC df	?		; Sel:Off to PMI code

@SWATSTK_LEN equ 256		; SWAT stack length per interrupt
@SWATSTK_CNT equ 4		; ...	     count

	public	SWATSTK_FVEC
SWATSTK_FVEC label fword	; Pointer to SWAT stack in extended memory
	dd	@SWATSTK_LEN*@SWATSTK_CNT ; Initial top of stack
	dw	DTE_SS		; Selector

	public	PDTE_DS,PDTE_ES,PDTE_FS,PDTE_GS,PDTE_SS
PDTE_DS dw	LDTE_DS 	; DS 64KB or 4GB data selector for GOREAL
PDTE_ES dw	LDTE_DS 	; ES ...
PDTE_FS dw	LDTE_DS 	; FS ...
PDTE_GS dw	LDTE_DS 	; GS ...
PDTE_SS dw	LDTE_SSB0S	; SS ...

	align	4

	public	RM_ERM_VEC
RM_ERM_VEC label dword		; Jump point to set/clear G-bit in CS
	VECTOR	<offset RGROUP:RM_ERM1,LDTE_CS>

	public	PDTE_CS
PDTE_CS equ	RM_ERM_VEC.VSEG ; CS 64KB or 4GB code selector for GOREAL

	public	DEVEXTSIZE
DEVEXTSIZE dd	?		; Size of extended memory below us

	public	RMSTK_FVEC
RMSTK_FVEC df	?		; Pointer to RM stack
	dw	?		; Pad RMSTK_VEC to use as qword

	public	GOREAL_VEC
GOREAL_VEC label dword
	VECTOR	<offset RGROUP:GOREAL1,?>

	public	RM_EIP,RM_CSF,RM_EFL,RM_ESF,RM_DSF,RM_FSF,RM_GSF
	public	RM_NEXT,RM_TRP,RM_RIP
RM_EIP	dd	0		; Save area for EIP
RM_CSF	dw	?,?		; ...		CS w/filler
RM_EFL	dd	?		; ...		EFL
RM_ESF	dw	?,?		; ...		ES w/filler
RM_DSF	dw	?,?		; ...		DS ...
RM_FSF	dw	?,?		; ...		FS ...
RM_GSF	dw	?,?		; ...		GS ...
RM_NEXT dd	?		; ...		next handler in sequence
RM_TRP	dd	?		; ...		@TRP_Ixx flag
RM_RIP	dw	?		; ...		return IP

	public	RM_GDTR,RM_IDTR,RM_IDTR0
RM_GDTR df	?		; GDTR upon entry to debugger
RM_IDTR df	?		; IDTR ...
RM_IDTR0 df	(size RM_IDT)-1 ; IDTR at 0:0

	align	4
%	irp	XX,<@HOOKINTS,15>

	public	OLDDEV&XX&_VEC
OLDDEV&XX&_VEC dd ?		; Next handler in sequence for INT XX&h

	endm

	public	RMIRQ,RMPORTBASE,RMINPUT
RMIRQ	db	0FFh,?		; Serial port IRQ active or 0FFh to ignore
RMPORTBASE dw	?		; Serial port base
RMINPUT dd	0		; Input buffer for BREAK signal interrupt

	public	RGRSEG1,RGRSEL,AGRSEL
RGRSEG1 dw	seg RGROUP	; Segment of RGROUP changed by COPYLOW
				; to reflect reality
RGRSEL	dw	DTE_ES		; Selector of RGROUP ...
AGRSEL	dw	DTE_4GB 	; ...	      AGROUP

	NPPROC	DEVINTCOM -- Device SWAT Interrupt Common Routine
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Device SWAT Interrupt Common Routine

The incoming code segment is (seg PGROUP) - INT #.
Note that this means we can't use any CS: overrides.

|

DEVINT_STR struc

	dw	?		; Caller's BP
DEVINT_VEC dd	?		; Room for CS:IP

DEVINT_STR ends

	push	ebx		; Make room for DEVINT_VEC
	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	pushf			; Save flags

	push	ds		; Save register

	mov	bx,seg INTVEC	; Get segment of RM IDT
	mov	ds,bx		; Address it
	assume	ds:INTVEC	; Tell the assembler about it

	mov	bx,cs		; Get code segment to get INT #
	sub	bx,seg PGROUP	; Less the expected segment #
	neg	bx		; Negate to get INT #
	shl	bx,2-0		; Convert from INT # to bytes

	mov	ebx,INT00_VEC[bx] ; Get the Seg:Off
	xchg	ebx,[bp].DEVINT_VEC ; Save back onto stack, restore EBX

	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	popf			; Restore

	pop	bp		; Restore

	retf			; Continue with next handler in sequence

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEVINTCOM endp			; End DEVINTCOM procedure
	FPPROC	RMDEV00 -- RM Device Driver Divide Overflow Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

RM device driver divide overflow interrupt handler

|

	push	dword ptr @TRP_I00 ; Pass trap flag to test
	push	OLDDEV00_VEC	; Pass address of next handler in sequence
	call	RM_EPM		; Enter PM from RM
	jc	short RMDEV00_VM ; Jump if we're in VM

	or	[esp].DEVSTK_EFL.EHI,mask $RF ; RF=1 for fault

	FIJMP32 PGROUP:LCL_RVM00,DTE_LOAD ; Join common code in PM

RMDEV00_VM:
	jmp	OLDDEV00_VEC	; Continue with next handler in sequence

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RMDEV00 endp			; End RMDEV00 procedure
	FPPROC	RMDEV01 -- RM Device Driver Single-Step Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

RM device driver single-step interrupt handler

|

	push	dword ptr @TRP_I01 ; Pass trap flag to test
	push	OLDDEV01_VEC	; Pass address of next handler in sequence
	call	RM_EPM		; Enter PM from RM
	jc	short RMDEV01_VM ; Jump if we're in VM

	FIJMP32 PGROUP:LCL_RVM01,DTE_LOAD ; Join common code in PM

RMDEV01_VM:
	jmp	OLDDEV01_VEC	; Continue with next handler in sequence

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RMDEV01 endp			; End RMDEV01 procedure
	FPPROC	RMDEV02 -- RM Device Driver NMI Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

RM device driver NMI handler

|

	push	dword ptr @TRP_I02 ; Pass trap flag to test
	push	OLDDEV02_VEC	; Pass address of next handler in sequence
	call	RM_EPM		; Enter PM from RM
	jc	short RMDEV02_VM ; Jump if we're in VM

	FIJMP32 PGROUP:LCL_RVM02,DTE_LOAD ; Join common code in PM

RMDEV02_VM:
	jmp	OLDDEV02_VEC	; Continue with next handler in sequence

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RMDEV02 endp			; End RMDEV02 procedure
	FPPROC	RMDEV03 -- RM Device Driver Breakpoint Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

RM device driver breakpoint interrupt handler

|

	push	dword ptr @TRP_I03 ; Pass trap flag to test
	push	OLDDEV03_VEC	; Pass address of next handler in sequence
	call	RM_EPM		; Enter PM from RM
	jc	short RMDEV03_VM ; Jump if we're in VM

	FIJMP32 PGROUP:LCL_RVM03,DTE_LOAD ; Join common code in PM

RMDEV03_VM:
	jmp	OLDDEV03_VEC	; Continue with next handler in sequence

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RMDEV03 endp			; End RMDEV03 procedure
	FPPROC	RMDEV05 -- RM Device Driver Bound Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

RM device driver bound interrupt handler

|

	push	dword ptr @TRP_I05 ; Pass trap flag to test
	push	OLDDEV05_VEC	; Pass address of next handler in sequence
	call	RM_EPM		; Enter PM from RM
	jc	short RMDEV05_VM ; Jump if we're in VM

	or	[esp].DEVSTK_EFL.EHI,mask $RF ; RF=1 for fault

	FIJMP32 PGROUP:LCL_RVM05,DTE_LOAD ; Join common code in PM

RMDEV05_VM:
	jmp	OLDDEV05_VEC	; Continue with next handler in sequence

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RMDEV05 endp			; End RMDEV05 procedure
	FPPROC	RMDEV06 -- RM Device Driver Invalid Opcode Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

RM device driver invalid opcode interrupt handler

|

	push	dword ptr @TRP_I06 ; Pass trap flag to test
	push	OLDDEV06_VEC	; Pass address of next handler in sequence
	call	RM_EPM		; Enter PM from RM
	jc	short RMDEV06_VM ; Jump if we're in VM

	or	[esp].DEVSTK_EFL.EHI,mask $RF ; RF=1 for fault

	FIJMP32 PGROUP:LCL_RVM06,DTE_LOAD ; Join common code in PM

RMDEV06_VM:
	jmp	OLDDEV06_VEC	; Continue with next handler in sequence

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RMDEV06 endp			; End RMDEV06 procedure
	FPPROC	RMDEV09 -- RM Device Driver Keyboard Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

RM device driver keyboard interrupt handler

|

; Because we can't afford to gate A20 on (as it might interfere
; with processing this scancode via the 8042), we check for
; scancodes to activate SWAT in RM.  We also check for VM and/or TF
; early so we don't delatch the scancode unnecessarily.

	call	CHECK_VMTF	; Check VM and TF
	jnz	short RMDEV09_VM ; Jump if either is set

	test	DEV_FLAG,@DEV_NORMLIDT ; Izit NORMLIDT?
	jnz	short @F	; Jump if so

	LIDTD	RM_IDTRL	; Reset IDT to the table in local memory
@@:
	call	CHECK_SCAN	; Check for our activating scan codes
	jc	short RMDEV09_VM ; Jump if it's not us

	push	dword ptr @TRP_I09 ; Pass trap flag to test
	push	OLDDEV09_VEC	; Pass address of next handler in sequence
	call	RM_EPM		; Enter PM from RM
	jc	short RMDEV09_VM ; Jump if we're in VM

	FIJMP32 PGROUP:LCL_RVM01,DTE_LOAD ; Join common code in PM

RMDEV09_VM:
	jmp	OLDDEV09_VEC	; Continue with next handler in sequence

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RMDEV09 endp			; End RMDEV09 procedure
	FPPROC	RMDEV0B -- RM Device Driver Segment Not Present Fault / IRQ3 Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

RM device driver Segment Not Present Fault / IRQ3 interrupt handler (IRQ3
used for COM2/COM4 in remote debugging)

|

	push	dword ptr @TRP_I0B ; Pass trap flag to test
	push	OLDDEV0B_VEC	; Pass address of next handler in sequence
	call	RM_EPM		; Enter PM from RM
	jc	short RMDEV0B_VM ; Jump if we're in VM

	or	[esp].DEVSTK_EFL.EHI,mask $RF ; RF=1 for fault

	FIJMP32 PGROUP:LCL_RVM0B,DTE_LOAD ; Join common code in PM

RMDEV0B_VM:
	jmp	OLDDEV0B_VEC	; Continue with next handler in sequence

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RMDEV0B endp			; End RMDEV0B procedure
	FPPROC	RMDEV0C -- RM Device Driver Stack Fault / IRQ4 Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

RM device driver Stack Fault / IRQ4 interrupt handler (IRQ4 used for
COM1/COM3 in remote debugging)

|

	push	dword ptr @TRP_I0C ; Pass trap flag to test
	push	OLDDEV0C_VEC	; Pass address of next handler in sequence
	call	RM_EPM		; Enter PM from RM
	jc	short RMDEV0C_VM ; Jump if we're in VM

	or	[esp].DEVSTK_EFL.EHI,mask $RF ; RF=1 for fault

	FIJMP32 PGROUP:LCL_RVM0C,DTE_LOAD ; Join common code in PM

RMDEV0C_VM:
	jmp	OLDDEV0C_VEC	; Continue with next handler in sequence

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RMDEV0C endp			; End RMDEV0C procedure
	FPPROC	RMDEV0D -- RM Device Driver GP Fault Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

RM device driver GP Fault interrupt handler

|

	push	dword ptr @TRP_I0D ; Pass trap flag to test
	push	OLDDEV0D_VEC	; Pass address of next handler in sequence
	call	RM_EPM		; Enter PM from RM
	jc	short RMDEV0D_VM ; Jump if we're in VM

	or	[esp].DEVSTK_EFL.EHI,mask $RF ; RF=1 for fault

	FIJMP32 PGROUP:LCL_RVM0D,DTE_LOAD ; Join common code in PM

RMDEV0D_VM:
	jmp	OLDDEV0D_VEC	; Continue with next handler in sequence

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RMDEV0D endp			; End RMDEV0D procedure
	FPPROC	RMDEV15 -- BIOS Services Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BIOS services interrupt handler

|

RM15_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
	dw	?		; ...	   CS
RM15_FL dw	?		; ...	   FL

RM15_STR ends

	pushf			; Save flags for a moment

	cmp	ah,87h		; Izit BIOS Block Move?
	jne	short RMDEV15_X87 ; Jump if not

	test	DEV_FLAG,@DEV_NORMLIDT ; Izit NORMLIDT?
	jnz	short RMDEV15_X87 ; Jump if so

	call	CHECK_VMTF	; Check VM and TF
	jnz	short RMDEV15_X87 ; Jump if either is set

	popf			; Restore flags

; Because this BIOS call resets the RM IDT, we hold onto it and
; reload our IDTR afterwards so we can maintain control.

; Put caller's flags into effect

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack
	push	[bp].RM15_FL	; Get caller's flags
	popf			; Put into effect
	pop	bp		; Restore

	pushf			; Simulate INT environment
	cli			; ...
	call	OLDDEV15_VEC	; Continue with next handler in sequence

	LIDTD	RM_IDTRL	; Reset IDT to the table in local memory

	ret	2		; Return to caller, popping flags


RMDEV15_X87:

; If an XMS driver is present, we allocated our memory from it,
; so we don't need to reduce this value.

	test	DEV_FLAG,@DEV_XMS ; Is XMS driver present?
	jnz	near ptr RMDEV15_ORIG ; Jump if so

	test	DEV_FLAG,@DEV_X15 ; Are we to pass through INT 15h memory calls?
	jnz	near ptr RMDEV15_ORIG ; Jump if so

	cmp	ah,88h		; Izit Get Extended Memory function?
	jne	short RMDEV15_X88 ; Jump if not

	mov	ax,DEVEXTSIZE.ELO ; Get low-order word of extended memory size

	cmp	DEVEXTSIZE,0FFFFh ; Izit bigger than AX can hold?
	jbe	short @F	; Jump if not

	mov	ax,-1		; Use largest value
@@:
	popf			; Restore flags

	iret			; Return to caller


RMDEV15_X88:
	cmp	ax,0DA88h	; Izit Get PCI Memory Size?
	jne	short RMDEV15_XDA88  ; Jump if not

	mov	bx,DEVEXTSIZE.ELO ; Get low-order word of extended memory size
	mov	cl,DEVEXTSIZE.EHI.LO ; Get next byte

	popf			; Restore flags

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack
	push	[bp].RM15_FL	; Get caller's flags
	popf			; Put into effect
	pop	bp		; Restore

	xor	ax,ax		; Clear return value, set CF=0

	retf	2		; Return to caller, popping flags


RMDEV15_XDA88:
	cmp	ax,0E801h	; Izit Get Ext Memory Size?
	jne	short RMDEV15_XE801  ; Jump if not

	mov	ax,DEVEXTSIZE.ELO ; Get low-order word of extended memory size
	xor	bx,bx		; Assume <= 15MB extmem
	xor	dx,dx		; ...

	cmp	DEVEXTSIZE,15*1024 ; Izit > 15MB of extmem?
	jb	short @F	; Jump if not

	and	ax,64-1 	; Get size modulo 64KB
	add	ax,15*1024	; Plus first 15MB

	mov	bx,DEVEXTSIZE.ELO ; Get low-order word of extended memory size
	mov	dx,DEVEXTSIZE.EHI ; ... high-...
	sub	bx,ax		; Less amount below 16MB
	sbb	dx,0		; In case of underflow
	shrd	bx,dx,16-10	; Convert from 1KB to 16KB
	mov	dx,bx		; Return same value in DX
@@:
	mov	cx,ax		; Return same value in CX

	popf			; Restore flags

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack
	push	[bp].RM15_FL	; Get caller's flags
	popf			; Put into effect
	pop	bp		; Restore

	clc			; In case anyone's checking

	retf	2		; Return to caller, popping flags


RMDEV15_XE801:
	cmp	ax,0E820h	; Izit Get Ext Memory Size?
	jne	short RMDEV15_XE820  ; Jump if not

	popf			; Restore flags

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack
	push	[bp].RM15_FL	; Get caller's flags
	popf			; Put into effect
	pop	bp		; Restore

	stc			; In case anyone's checking

	retf	2		; Return to caller, popping flags


RMDEV15_XE820:
RMDEV15_ORIG:
	popf			; Restore flags

	jmp	OLDDEV15_VEC	; Continue with next handler in sequence

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RMDEV15 endp			; End RMDEV15 procedure
	FPPROC	RM_WINCB -- Windows Callback Routine
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Windows callback routine used when it wants to gain/return control
from/to the memory manager.

This routine is called when SWAT loads in RM or VCPI/VM.

On entry:

IF	=	0	Interrupts are disabled
AX	=	0	If we're to disable ourselves (we're in VM -> RM)
	=	1	If we're to re-enable ourselves (we're in RM -> VM)

On exit:

If disabling ourselves (AX = 0),

CF	=	0	if successful
	=	1	if not

|

; Because we're called with a RETF frame and RM_EPM/RM_ERM expect
; an IRET frame, we need to manipulate the stack

.8086
	pop	RM_EIP.ELO	; Save return address
	pop	RM_CSF		; ...
DOT386 p
	clc			; CF=0 for AX=0 case
	pushf			; Pass flags
	push	RM_CSF		; ...  CS
	push	RM_EIP.ELO	; ...  IP

	cmp	ax,1		; Izit re-enable?
	je	short RM_WINCB_ENA ; Jump if so

; We're in RM/VM -- tell our code upstairs to REST_PROT

	push	dword ptr @TRP_WCB ; Pass trap flag to test
	push	cs		; Pass address of next handler in sequence
	push	offset RGROUP:RM_WINCB1 ; ...
	call	RM_EPM		; Enter PM from RM
	jc	near ptr RM_WINCB1 ; Jump if we're in VM

	SETLDTX 		; Put our LDT into effect

	mov	ds,RGRSEL	; Get RGROUP data selector
	assume	ds:RGROUP	; Tell the assembler about it

	mov	gs,AGRSEL	; Get AGROUP data selector
	assume	gs:AGROUP	; Tell the assembler about it

	call	WINCB_DIS	; Disable ourselves so W can enter PM
	assume	ds:nothing,gs:nothing ; Tell the assembler about it

	FICALL32 PGROUP:REST_PROT,DTE_LOAD ; Call REST_PROT in PM

	jmp	RM_ERM		 ; Return to RM/VM


RM_WINCB1:
.8086
	pop	RM_EIP.ELO	; Save return address
	pop	RM_CSF		; ...
	pop	RM_EFL.ELO	; ...
DOT386 p
	push	RM_CSF		; Pass CS
	push	RM_EIP.ELO	; ...  IP

	jmp	OLDDEV_WINCB_VEC ; Continue with next handler in sequence


; It's time to re-enable ourselves

RM_WINCB_ENA:

; We're in RM

	call	OLDDEV_WINCB_VEC ; Continue with next handler in sequence

; We're in RM/VM -- tell our code upstairs to INIT_PROT

	push	dword ptr @TRP_WCB ; Pass trap flag to test
	push	cs		; Pass address of next handler in sequence
	push	offset RGROUP:RM_WINCB2 ; ...
	call	RM_EPM		; Enter PM from RM
	jc	short RM_WINCB2 ; Jump if we're in VM

	mov	gs,AGRSEL	; Get AGROUP data selector
	assume	gs:AGROUP	; Tell the assembler about it

	call	WINCB_ENA	; Enable ourselves so we can run in RM/VM
	assume	gs:nothing	; Tell the assembler about it

	FICALL32 PGROUP:INIT_PROT,DTE_LOAD ; Call INIT_PROT in PM

	jmp	RM_ERM		; Return to RM/VM


RM_WINCB2:
.8086
	pop	RM_EIP.ELO	; Save return address
	pop	RM_CSF		; ...
	pop	RM_EFL.ELO	; ...
DOT386 p
	push	RM_CSF		; Pass CS
	push	RM_EIP.ELO	; ...  IP

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RM_WINCB endp			; End RM_WINCB procedure
	FPPROC	RMDEV67 -- RM Device Driver EMS Services Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

RM device driver EMS services interrupt handler

|

	cmp	ah,@VCPI	; Izit a VCPI debugging function?
	jne	short RMDEV67_VM1 ; Jump if not

	test	DEV_FLAG,@DEV_VCPI ; Are we using VCPI services?
	jz	short @F	; Jump if not

	cmp	al,@VCPI_EPM	; Izit Enter PM?
	je	short RMDEV67_VM ; Jump if so (can't use w/VCPI)
@@:
RMDEV67_EPM:
	push	dword ptr @TRP_I67 ; Pass trap flag to test
	push	OLDDEV67_VEC	; Pass address of next handler in sequence
	call	RM_EPM		; Enter PM from RM
	jc	short RMDEV67_VM ; Jump if we're in VM

	FIJMP32 PGROUP:LCL_RVM67,DTE_LOAD ; Call our debugger

RMDEV67_VM:
	jmp	OLDDEV67_VEC	; Continue with next handler in sequence


; This exit point is for debugging EMS calls.  Put a BD .CODE here to catch
; non-VCPI EMS calls.

RMDEV67_VM1:
	jmp	OLDDEV67_VEC	; Continue with next handler in sequence


RMDEV67_IRET:
	mov	ah,84h		; Mark as invalid function

	iret			; Return to caller


	public	RMDEV_GPMITAIL
RMDEV_GPMITAIL:
	sub	sp,3*2		; Make room for pseudo-IRET return struc

	mov	ax,(@VCPI shl 8) or @VCPI_GPMITAIL ; Use GPMI tail

	jmp	RMDEV67_EPM	; Continue with EPM

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RMDEV67 endp			; End RMDEV67 procedure
	FPPROC	RMDEV68 -- RM Device Driver WKD Services Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

RM device driver Windows Kernel Debugging services interrupt handler

|

; Because when @I68_RM_INIT is called we haven't setup
; for normal entry, we pick off this function and ignore it

	cmp	ah,@I68_RM_INIT ; Izit re-init for RM?
	je	short RMDEV68_VM ; Jump if so

	push	dword ptr @TRP_I68 ; Pass trap flag to test
	push	OLDDEV68_VEC	; Pass address of next handler in sequence
	call	RM_EPM		; Enter PM from RM
	jc	short RMDEV68_VM ; Jump if we're in VM

	FIJMP32 PGROUP:LCL_RVM68,DTE_LOAD ; Call our debugger

RMDEV68_VM:
	jmp	OLDDEV68_VEC	; Continue with next handler in sequence

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RMDEV68 endp			; End RMDEV68 procedure
	NPPROC	RM_EPM -- Enter PM From RM/VM
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enter PM

If we're already in PM (actually VM) or if we're entered with TF set
(perhaps 386MAX is single-stepping through us), then don't try to enter
PM; otherwise, do it.

On exit:

CF	=	0 if we're in PM
	=	1 ...	       VM or TF=1

|

EPM_STR struc

EPM_RIP dw	?		; Caller's return IP
EPM_NEXT dd	?		; Address of next handler in sequence
EPM_TRP dd	?		; @TRP_Ixx flag to test
EPM_IP	dw	?		; Caller's IP
EPM_CS	dw	?		; ...	   CS
EPM_FL	dw	?		; ...	   FL

EPM_STR ends

; The stack is mapped by EPM_STR

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	push	eax		; Save for a moment

	mov	eax,[bp+2].EPM_TRP ; Get @TRP_Ixx flag to test (+2 for BP)

	test	eax,TRP_FLAG	; Should we intercept this one?
	pop	eax		; Restore
	pop	bp		; Restore
	jz	short EPM_ORIG	; Jump if not (continue with original handler)

	call	CHECK_VMTF	; Check VM and TF
	jz	short @F	; Jump if neither is set
EPM_ORIG:
	stc			; Indicate we're in VM

	ret	(size EPM_NEXT) + (size EPM_TRP) ; Return to caller,
				; popping arguments

@@:
	push	ds		; Save for a moment
	push	es		; ...
	push	fs		; ...
	push	gs		; ...

	push	cs		; Get segment of RM_xxx
	pop	ds		; Address it
	assume	ds:RGROUP	; Tell the assembler about it

	pop	RM_GSF		; Save for later use
	pop	RM_FSF		; ...
	pop	RM_ESF		; ...
	pop	RM_DSF		; ...

	pop	RM_RIP		; ...
	pop	RM_NEXT 	; ...
	pop	RM_TRP		; ...
	pop	RM_EIP.ELO	; ...
	pop	RM_CSF		; ...

	pushfd			; Get current EFL
	pop	RM_EFL		; Save high-order word for later use
	pop	RM_EFL.ELO	; ...
	or	RM_EFL.EHI,mask $VM ; VM=1

	mov	RMSTK_FVEC.FSEL,ss  ; Save for later use
	mov	RMSTK_FVEC.FOFF,esp ; ...

	test	DEV_FLAG,@DEV_VCPI ; Are we using VCPI services?
	jnz	short EPM_VCPI	; Jump if so

; Mark as entering from RM

	or	RM_EFL,mask $R2 ; RM=1

; Gate A20 ON unless it's already ON

	or	DEV_FLAG,@DEV_A20ON ; Assume A20 enabled upon entry
@@:
	call	CHECKA20	; Izit enabled?
	jc	short @F	; Jump if so

	and	DEV_FLAG,not @DEV_A20ON ; Mark as A20 not enabled upon entry
	call	GATEA20 	; Gate A20 on

	jmp	short @B	; Jump if not


@@:

; Enter PM

	SGDTD	RM_GDTR 	; Save old GDTR
	SIDTD	RM_IDTR 	; ...	   IDTR
	LGDTD	SWATGDTR	; Point GDTR to low memory
	LIDTD	SWATIDTR	; ...	IDTR to extended memory

	push	eax		; Save for a moment

	mov	eax,cr0 	; Get current CR0
	or	ax,mask $PE	; Mark as enabling protected mode
	mov	cr0,eax 	; Enter protected mode

	FIJMP	RGROUP:@F,DTE_CS ; Put the PM CS into effect
@@:
	SETLDTX 		; Put our LDT into effect
	and	SWATGDT.DTE_TSS.DESC_ACCESS,not (mask $DS_BUSY) ; Clear the busy bit

; Ensure the NT bit is clear

	pushf			; Copy flags
	pop	ax		; ...into AX
	and	ax,not (mask $NT) ; NT=0
	push	ax		; Copy AX
	popf			; ...into flags

	pop	eax		; Restore

	jmp	short EPM_PMCOM ; Join common code


EPM_VCPI:
	mov	SAVE_EAX,eax	; Save register
	mov	SAVE_ESI,esi	; ...

	cli			; Enter with IF=0

	mov	esi,LaVCPEPM	; Get linear address of VCPEPM
	VCPICALL @VCPI_EPM	; Enter PM using ESI = EPM struc
EPM_VCPI_PMINI:
	cli			; Some VCPI hosts (RM386 comes to mind)
				; start us off with IF=1
	xor	ax,ax		; A convenient zero
	mov	ds,ax		; Clear to avoid fault
	assume	ds:nothing	; Tell the assembler about it
	mov	es,ax		; Clear to avoid fault
	assume	es:nothing	; Tell the assembler about it
	mov	fs,ax		; Clear to avoid fault
	assume	fs:nothing	; Tell the assembler about it
	mov	gs,ax		; ...
	assume	gs:nothing	; Tell the assembler about it

	mov	eax,SAVE_EAX	; Restore
	mov	esi,SAVE_ESI	; ...

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EPM_PMCOM:
	mov	ds,RGRSEL	; Get RGROUP selector
	assume	ds:RGROUP	; Tell the assembler about it (note lie)

; Switch to SWAT's stack in extended memory

	lss	esp,SWATSTK_FVEC ; Address it
	assume	ss:nothing	; Tell the assembler about it

; Delete this portion in case we're re-entrant

	sub	SWATSTK_FVEC.FOFF,@SWATSTK_LEN ; Count out one stack frame

; Setup segment registers

	mov	ds,SWATGDT.ELO	; Zero the selector
	assume	ds:nothing	; Tell the assembler about it

	mov	es,SWATGDT.ELO	; ...
	assume	es:nothing	; Tell the assembler about it

	mov	fs,SWATGDT.ELO	; ...
	assume	fs:nothing	; Tell the assembler about it

	mov	gs,SWATGDT.ELO	; ...
	assume	gs:nothing	; Tell the assembler about it

; Setup stack as per VM

	push	RM_GDTR.DTR_BASE ; Save old GDTR
	push	RM_GDTR.DTR_LIM ; ...
	push	DEV_FLAG	; Save flags upon entry
;;;;;;; push	RM_TRP		; Pass back @TRP_Ixx flag
	push	RM_NEXT 	; Pass back address of next handler in sequence
	push	RM_GSF.EDD	; Setup GS w/filler
	push	RM_FSF.EDD	; ...	FS ...
	push	RM_DSF.EDD	; ...	DS ...
	push	RM_ESF.EDD	; ...	ES ...
	push	RMSTK_FVEC.FSEL.EDD ; ...   SS ...
	push	RMSTK_FVEC.FOFF ; ...	ESP
	push	RM_EFL		; ...	EFL
	push	RM_CSF.EDD	; ...	CS w/filler
	push	RM_EIP		; ...	EIP

	clc			; Indicate all went well

	jmp	RM_RIP		; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RM_EPM	endp			; End RM_EPM procedure
	NPPROC	RM_ERM -- Enter RM
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enter RM

On entry:

We're in PM

SS:ESP	==>	VM IRETD stack frame
DS,ES,FS,GS,SS are still PM selectors

On exit:

We're in RM

|

; The PM stack has pushed onto it RM_GDTR through RM_EIP
; Pop these into the associated variables

	SETLDTX 		; Put our LDT into effect

	mov	ds,RGRSEL	; Get RGROUP data selector
	assume	ds:RGROUP	; Tell the assembler about it

	pop	RM_EIP		; Save	EIP temporarily
	pop	RM_CSF.EDD	; ...	CS w/filler
	pop	RM_EFL		; ...	EFL
	pop	RMSTK_FVEC.FOFF ; ...  ESP
	pop	RMSTK_FVEC.FSEL.EDD ; ... SS w/filler
	pop	RM_ESF.EDD	; ...	ES ...
	pop	RM_DSF.EDD	; ...	DS ...
	pop	RM_FSF.EDD	; ...	FS ...
	pop	RM_GSF.EDD	; ...	GS ...
	pop	RM_NEXT 	; ... next handler
;;;;;;; pop	RM_TRP		; ... @TRP_Ixx flag
	pop	DEV_FLAG	; ... flags set upon entry
	pop	RM_GDTR.DTR_LIM ; Old GDTR
	pop	RM_GDTR.DTR_BASE ; ...

	test	DEV_FLAG,@DEV_VCPI ; Are we using VCPI services?
	jz	short RM_ERM_NOVCPI ; Jump if not

	lss	esp,VCPSTK_FVEC ; Use stack in one-to-one memory
	assume	ss:nothing	; Tell the assembler about it
				; as there's a bug in EMM386
	mov	SAVE_EAX,eax	; Save register

	mov	ax,seg PGROUP	; Get segment of PGROUP

	push	eax		; Pass resulting GS w/filler
	push	eax		; ...		 FS ...
	push	RGRSEG1.EDD	; ...		 DS ...
	push	RGRSEG1.EDD	; ...		 ES ...
	push	RMSTK_FVEC.FSEL.EDD ; ...	 SS ...
	push	RMSTK_FVEC.FOFF ; ...		 ESP
	pushfd			; ...		 EFL
	push	RGRSEG1.EDD	; ...		 CS ...
	lea	eax,RGROUP:@F	; Get return EIP
	push	eax		; ...		 EIP ...

	mov	ax,LDTE_4GB	; Get AGROUP data selector
	mov	ds,ax		; Address it
	assume	ds:AGROUP	; Tell the assembler about it

	cli			; Exit with IF=0

	mov	ax,(@VCPI shl 8) or @VCPI_EPM ; Get return function
	call	PMI_FVEC	; Request VCPI service
@@:
	assume	ds:RGROUP,es:RGROUP ; Tell the assembler about it
	assume	fs:PGROUP,gs:PGROUP ; Tell the assembler about it

	mov	eax,SAVE_EAX	; Restore

	add	SWATSTK_FVEC.FOFF,@SWATSTK_LEN ; Count in one stack frame

	jmp	short RM_ERM_COM ; Join common code


	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RM_ERM_NOVCPI:
	jmp	RM_ERM_VEC	; Jump to next instruction to set/clear G-bit


RM_ERM1:
	lss	esp,VCPSTK_FVEC ; SS:ESP ==> VCPSTK (with same base SS
				; as used by GOREAL)
	assume	ss:nothing	; Tell the assembler about it

	call	GOREAL		; Enter RM
;;;;;;; FICALL	RGROUP:GOREAL,LDTE_CS,<seg PGROUP> ; Enter RM
	assume	ds:RGROUP,es:RGROUP ; Tell the assembler about it
	assume	fs:PGROUP,gs:PGROUP ; Tell the assembler about it

; Note that SS still has the PM selector value and
; its descriptor cache has not been changed.

	lss	esp,RMSTK_FVEC	; Re-specify the stack
	assume	ss:nothing	; Tell the assembler about it

; Add back in this portion

	add	SWATSTK_FVEC.FOFF,@SWATSTK_LEN ; Count in one stack frame

; Restore the original GDTR

	LGDTD	RM_GDTR 	; Restore it

; Now that we're back in RM and on a valid stack, restore
; A20 to the state we found it.

	test	DEV_FLAG,@DEV_A20ON ; Wuzit enabled upon entry?
	jnz	short @F	; Jump if so

	call	DEGATEA20	; Disable address line A20
	jnc	short @F	; Jump if no error

	int	03h		; Call our debugger
@@:
RM_ERM_COM:

; Note that we pass back the 32-bit IRETD frame so we can
; take advantage of possible RF setting

	push	RM_EFL		; Pass back EFL
	push	RM_CSF.EDD	; ...	    CS w/filler
	push	RM_EIP		; ...	    EIP

; Note that we re-specify DS last so as to use it for
; the other variables.

	mov	gs,RM_GSF	; ...	  GS
	assume	gs:nothing	; Tell the assembler about it

	mov	fs,RM_FSF	; ...	  FS
	assume	fs:nothing	; Tell the assembler about it

	mov	es,RM_ESF	; ...	  ES
	assume	es:nothing	; Tell the assembler about it

	mov	ds,RM_DSF	; Restore DS
	assume	ds:nothing	; Tell the assembler about it

	iretd			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RM_ERM	endp			; End RM_ERM procedure
	NPPROC	GOREAL -- Enter Real Mode
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enter Real Mode

On entry:

We're in protected mode

On exit:

We're in real mode

DS,ES	=	RGROUP
FS,GS	=	PGROUP

Note that SS still has the PM selector value and
its descriptor cache has not been changed.

|

	SETLDTX 		; Put our LDT into effect

	push	eax		; Save register

	mov	ds,PDTE_DS	; Get 64KB or 4GB limit selector
	mov	es,PDTE_ES	; ...
	mov	fs,PDTE_FS	; ...
	mov	gs,PDTE_GS	; ...
	assume	ds:nothing,es:nothing ; Tell the assembler about it
	assume	fs:nothing,gs:nothing ; Tell the assembler about it

	mov	ss,PDTE_SS	; Set to valid value
	assume	ss:nothing	; Tell the assembler about it
	nop			; So we can single-step the MOV SS,...

	call	DEV_ERM 	; Enter RM
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it

; Re-initialize segment registers

	mov	ds,RGRSEG1	; Get relocated RGROUP segment
	assume	ds:RGROUP	; Tell the assembler about it

	mov	es,RGRSEG1	; Get relocated RGROUP segment
	assume	es:RGROUP	; Tell the assembler about it

	mov	ax,seg PGROUP
	mov	fs,ax
	assume	fs:PGROUP	; Tell the assembler about it

	mov	gs,ax
	assume	gs:PGROUP	; Tell the assembler about it

	mov	GOREAL_VEC.VSEG,ds  ; Save for far jump

	jmp	GOREAL_VEC	; Set the A/R byte


GOREAL1:

; Note that we have to wait until we switch back to the RM stack
; before degating A20 as the current stack is in extended memory.

	pop	eax		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GOREAL	endp			; End GOREAL procedure
	FPPROC	FGOREAL -- Far Call To GOREAL
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to GOREAL

On entry:

We're in protected mode

On exit:

We're in real mode

DS,ES	=	RGROUP
FS,GS	=	PGROUP

Note that SS still has the PM selector value and
its descriptor cache has not been changed.

|

	call	GOREAL		; Enter RM

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FGOREAL endp			; End FGOREAL procedure
	NPPROC	CHECK_SCAN -- Check On Activating Scan Codes
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

We're called from an INT 09h -- check on activating scan codes

On exit:

CF	=	0 if we're to activate
	=	1 otherwise

|

	REGSAVE <ax>		; Save registers

; Ensure shift states are Ctrl- and Alt-

	call	DEVGETSHIFT	; Return with shift states in AL

	and	al,(mask $DALT) or (mask $DCTL) ; Isolate just these two

	cmp	al,(mask $DALT) or (mask $DCTL) ; Ctrl and Alt pressed?
	jne	short CHECK_SCAN_ERR ; Jump if something else pressed

; Read in the scan code to check for the PAD5 or SYSREQ keys

	in	al,@8255_A	; Read in the scan code

	cmp	al,@SSC_PAD5	; Check for PAD5 key
	je	short CHECK_SCAN_EXIT ; Jump if so (note CF=0)

	cmp	al,@SSC_SYSREQ	; Check for SysReq key
	je	short CHECK_SCAN_EXIT ; Jump if so (note CF=0)

; Because we've respecified the RM IDT to other than 0:0, if the
; system is rebooting, set the RM IDT back to 0:0.

	cmp	al,@SSC_DEL	; Check for Delete key
	jne	short CHECK_SCAN_ERR ; Jump if not

	test	DEV_FLAG,@DEV_NORMLIDT ; Izit NORMLIDT?
	jnz	short CHECK_SCAN_ERR ; Jump if so

	LIDTD	RM_IDTR0	; Respecify to 0:0 as we're going out of business
CHECK_SCAN_ERR:
	stc			; Mark as not activating
CHECK_SCAN_EXIT:
	REGREST <ax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SCAN endp 		; End CHECK_SCAN procedure
	NPPROC	DEVGETSHIFT -- Get Keyboard Shift States
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get keyboard shift states

On exit:

AL	=	keyboard Ctrl-, Alt-, and L&R-shift states
ZF	=	1 if all states off
	=	0 otherwise

|

	REGSAVE <ds>		; Save for a moment

	mov	ax,seg BIOSDATA ; Get segment of BIOS data area
	mov	ds,ax		; Address it
	assume	ds:BIOSDATA	; Tell the assembler about it

	mov	al,KB_FLAG	; Get keyboard flags

; Isolate Ctrl, Alt, and L&R Shift states

	and	al,(mask $DALT) or (mask $DCTL) or (mask $DLSH) or (mask $DRSH)
	REGREST <ds>		; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEVGETSHIFT endp		; End DEVGETSHIFT procedure

	align	16		; Fill tail with NOPs

RCODE	ends			; End RCODE segment


RDATAZ	segment use16 para public 'rdataz'; Start RDATAZ segment
	assume	ds:RGROUP

	public	@SWAT_DRV_RDATAZ
@SWAT_DRV_RDATAZ label byte	; Mark module start in .MAP file

	public	RTAIL_NORMLIDT
RTAIL_NORMLIDT label byte	; This label marks the end of the device
				; driver resident code/data with NORMLIDT.

	public	RM_IDT
	align	4
RM_IDT	dd	256 dup (?)	; Real mode IDT filled in by SETINTS

	public	RTAIL
RTAIL	label	byte		; This label marks the end of the device
				; driver resident code/data.

	FPPROC	FGATEA20 -- Far Call To GATEA20
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to GATEA20

|

	call	GATEA20 	; Gate A20 on

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FGATEA20 endp			; End FGATEA20 procedure
	FPPROC	FDEGATEA20 -- Far Call To DEGATEA20
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to DEGATEA20

|

	call	DEGATEA20	; Gate A20 off

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FDEGATEA20 endp 		; End FDEGATEA20 procedure
	FPPROC	FCHECKA20 -- Far Call To CHECKA20
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to CHECKA20

|

	call	CHECKA20	; Izit enabled?
				; Return with CF significant
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCHECKA20 endp			; End FCHECKA20 procedure

	public	RTAIL_NR
RTAIL_NR label	byte		; This label marks the end of the device
				; driver non-resident code/data.

RDATAZ	ends			; End RDATAZ segment


NDATA	segment use16 dword public 'ndata' ; Start NDATA segment
	assume	ds:NGROUP

	public	@SWAT_DRV_NDATA
@SWAT_DRV_NDATA label byte	; Mark module start in .MAP file

	extrn	MAPSEG_NXT:word
	extrn	MAPSEG_LST:word
	extrn	SYM_XMSHNDL:word

	public	MOVE_TAB
MOVE_TAB MDTE_STR <>		; Move block descriptor tables

	public	PSWATGDT
PSWATGDT dd	RGROUP:SWATGDT	; Seg:Off of SWAT's GDT

	public	PVCPEPM
PVCPEPM dd	RGROUP:VCPEPM	; Seg:Off of VCPEPM

	public	BIOSCONF_VEC
BIOSCONF_VEC dd 0		; Seg:Off of BIOS configuration data (0 if none)

	public	SWAT_TSIZ,SWAT_ISIZ,SWAT_USIZ,SWAT_DAT,SWAT_XTRA
SWAT_TSIZ dd	?		; Total size of PM-resident SWAT module
SWAT_ISIZ dd	?		; Size of initialized code/data
SWAT_USIZ dd	?		; ...	  uninitialized data
SWAT_DAT dd	?		; Offset to data segment
SWAT_XTRA dd	(@SWATSTK_LEN*@SWATSTK_CNT) + \
		(256*(type IDT_STR)) + \
		(size TSS_STR)	; Size of extra data

	public	OLDINT67_VEC
OLDINT67_VEC dd ?		; Old INT 67h handler

	public	MMPaXMS
MMPaXMS dd	?		; Physical address of XMS allocation if VCPI/MM

	public	RUDLaGDT,RUDLaIDT,RUDGDTCNT,RUDIDTCNT
RUDLaGDT dd	?		; Linear address in our space of MM's GDT
RUDLaIDT dd	?		; ...				      IDT
RUDGDTCNT dw	?		; # PTEs needed by GDT
RUDIDTCNT dw	?		; ...		   IDT

	public	RUDSTK
RUDSTK	dd	32 dup (?)	; INTRUDE stack
RUDSTKZ label	dword		; End of ...

	public	XMSDRV_VEC
XMSDRV_VEC dd	?		; Seg:Off of XMS driver entry point

	public	DDS
DDS	DDS_STR <>		; DMA Descriptor Structure

	public	LaCODE,LaDATA,LaIDT,LaTSS,LaSTK,LaEND,OffCR3,OffPDIR,OffSYM
	public	SegCR3,SegPTE,SegIDT,SegTSS
	public	NEXTPTE,NDRVPDIR,NDRVPTE,NSYMPTE
	public	LaPSWAT,PSWAT_TSIZ
LaCODE	dd	?		; Linear address of our code segment
LaDATA	dd	?		; ...			data
LaIDT	dd	?		; ...			IDT
LaTSS	dd	?		; ...			TSS
LaSTK	dd	?		; ...		    SWAT's stack
LaEND	dd	?		; ...		    the end (including extra data)
LaPSWAT dd	-1		; ...		    PSWAT's code/data (-1=none) (/4KB)
PSWAT_TSIZ dd	4*1024*1024	; Total size of PM-resident preceding SWAT (/4KB)
				; Note we don't know the actual size, so we guess
OffCR3	dd	?		; Offset of CR3 in SegPTE
OffPDIR dd	?		; ...	    PDIRs ...
OffSYM	dd	?		; ...	    symbols ...
SegCR3	dw	?		; Segment of CR3	CR3 (/4KB)
SegPTE	dw	?		; ...			PTEs (/4KB)
SegIDT	dw	?		; ...			IDT
SegTSS	dw	?		; ...			TSS
NEXTPTE dd	?		; Offset of next available PTE in PDT
NDRVPDIR dd	?		; # PDIRs needed for VCPI SWAT counting the IDT,
				; stack, and TSS
NDRVPTE dd	?		; # PTEs ...
NSYMPTE dd	?		; # PTEs needed for symbol table

	public	XMBMOVE
XMBMOVE XMBMOVE_STR <>		; XMS Block Move

	public	PHYSIZE
PHYSIZE dd	?		; Size of physical memory

	public	PMSTK_FVEC
PMSTK_FVEC df	?		; PM stack for VCPI EPM

	public	NUM_VCPI_PTE
NUM_VCPI_PTE dw ?		; # PTEs used for VCPI

	public	DRVPATH_VEC,DRVPATH_END
DRVPATH_VEC dd	?		; Seg:Off of driver DPFE
DRVPATH_END dw	?		; Ending offset of DPFE

	public	PSWAT_VER,PSWAT_CR3SEL,PSWAT_4GBSEL
PSWAT_VER dw	?		; Version # of preceding SWAT (if any)
PSWAT_CR3SEL dw 0		; CR3 selector (0=none)
PSWAT_4GBSEL dw 0		; 4GB ...

	public	XMSHNDL
XMSHNDL dw	?		; XMS handle for LOADUP

	public	XMSZLEN
XMSZLEN dw	0		; Zero-length XMS handle (0=none)

	public	PICBASE
PICBASE dw	0870h		; (Master, Slave) PIC base values

	public	PRTAIL
PRTAIL	dw	RGROUP:RTAIL	; Offset of next available byte in RGROUP

	public	DRV_ERRMSG,RUD_ERRMSG,@ERRMSG_NONE
@ERRMSG_NONE equ -1		; No error message
DRV_ERRMSG dw	@ERRMSG_NONE	; Address of driver error message
RUD_ERRMSG dw	@ERRMSG_NONE	; Address of INTRUDE error message

	public	DEVNMIPORT,DEVNMIENA,DEVNMIDIS,DEVNMIMASK
DEVNMIPORT dw	@CMOS_CMD	; NMI clear I/O port
DEVNMIENA  db	@CMOS_ENANMI	; ... enable value
DEVNMIDIS  db	@CMOS_DISNMI	; ... disable value
DEVNMIMASK db	mask $ATPAR	; ... clear mask

	public	SWTNAME,MAXNAME,QEMMNAME
SWTNAME db	'386SWAT$',0    ; 386SWAT device name
MAXNAME db	'386MAX$$',0    ; 386MAX ...
QEMMNAME db	'QEMM386$',0    ; QEMM ...

	public	EMMNAME,EMMNAM2,EMMNAM3
EMMNAME db	'EMMXXXX0',0    ; Generic EMM device name
EMMNAM2 db	'$MMXXXX0',0    ; MSDOS device name if NOEMS
EMMNAM3 db	'EMMQXXX0',0    ; NetRoom/DRDOS device name if NOFRAME
;;;NAM4  db	 'EMMXXXQ0',0   ; QEMM device name if NOEMS
;;;NAM5  db	 'QMMXXXX0',0   ; 386MAX device name if EMS=0

MMDEV_STR struc

MMDEV_OFF dw	?		; Offset in NGROUP of ASCIIZ name
MMDEV_FLG dw	?		; DEV_FLAG bits to set

MMDEV_STR ends

COMMENT|

Note that we do not include in this table the device name for either
QEMM or 386MAX when EMS support is disabled as we catch them through
their nested device names which are always present.

|

	public	PMMDEV
	align	2		; Ensure word alignment
PMMDEV	MMDEV_STR <NGROUP:MAXNAME, @DEV_VDS or @DEV_MAX> ; 386MAX nested device name
	MMDEV_STR <NGROUP:QEMMNAME,@DEV_FCR3> ; QEMM nested device name
	MMDEV_STR <NGROUP:EMMNAM2, 0	     > ; MSDOS w/NOEMS
	MMDEV_STR <NGROUP:EMMNAM3, 0	     > ; NetRoom/DRDOS w/NOFRAME
;;;;;;; MMDEV_STR <NGROUP:EMMNAM4, @DEV_FCR3> ; QEMM w/NOEMS
;;;;;;; MMDEV_STR <NGROUP:EMMNAM5, 0	     > ; 386MAX w/EMS=0
	MMDEV_STR <NGROUP:EMMNAME, 0	     > ; Generic should be last
PMMDEV_LEN equ ($-PMMDEV)/(type MMDEV_STR) ; # entries

	public	INTA01,INTB01
INTA01	db	?		; Save area for master IMR
INTB01	db	?		; ...		slave

	public	MACHID
MACHID	db	?		; Machine ID

	public	MSG_NOVCPMEM,MSG_NOTINST,MSG_PRESS
	public	MSG_PTEFULL
MSG_NOVCPMEM db      '様> Insufficient VCPI memory to load.',CR,LF,EOS
MSG_NOTINST db	     '様> 386SWAT.LOD not installed.',CR,LF,EOS
MSG_PRESS db	BEL,'    Press any key to continue...',CR,LF,EOS
MSG_PTEFULL db	     '様> Number of PTEs exceeds 4MB by '
;;;;;;; 	     '__,___ KB',EOS
MSG_PTEFULL1 db      '         ',EOS
MSG_PTEFULL2 db      ' for VCPI clients.',CR,LF,EOS

	public	OLDDEVSTK_VEC,INIDEVSTK_VEC
	align	4
OLDDEVSTK_VEC dd ?		; Save area for old stack pointer
INIDEVSTK_VEC dd NGROUP:DEVSTKZ ; Pointer to local stack

	public	DEVSTK
DEVSTK	dw	256 dup (?)	; Local initialization stack
DEVSTKZ label	word

	public	MSG_VCPI,MSG_PSWAT
	public	MSG_DEVSWAT,MSG_VCPISWAT,MSG_LOADSWAT
	public	MSG_NOWINK,MSG_NOVXD,MSG_NOVIDEO
MSG_VCPI  db	"....VCPI host detected.",CR,LF,EOS
MSG_PSWAT db	"....Preceding SWAT detected.",CR,LF,EOS
MSG_DEVSWAT db	"....Loading as Real Mode SWAT.",CR,LF,EOS
MSG_VCPISWAT db "....Loading as Virtual Mode SWAT.",CR,LF,EOS
MSG_LOADSWAT db "....Loading as Protected Mode SWAT.",CR,LF,EOS
MSG_NOWINK   db "....Disabling Windows Kernel Debugger Services.",CR,LF,EOS
MSG_NOVXD    db "....SWATVXD.EXE not in same directory as 386SWAT.LOD.",CR,LF,EOS
MSG_NOVIDEO  db "....No monochrome or dual PCI video adapter, so no debugging under Windows.",CR,LF,EOS

	public	MSG_RUDESWAT
MSG_RUDESWAT db "....Loading as PL0 Intrude SWAT.",CR,LF,EOS

	public	MSG_NOVCPI
MSG_NOVCPI db	BEL,"様> The CPU is in VM and there's no VCPI host.",CR,LF,EOS

	public	MEMERR
	public	MEMERR_SEGPTE,MEMERR_ALLPTE,MEMERR_TSS,MEMERR_IDT
	public	MEMERR_IREAL,MEMERR_DVGA,MEMERR_PRO,MEMERR_VIDEO
	public	MEMERR_SETUPDPCI
MEMERR	db	BEL,'様> Out of memory error at:  ',EOS
MEMERR_SEGPTE db 'SegPTE',CR,LF,EOS   ; Specific error message
MEMERR_ALLPTE db 'All PTEs',CR,LF,EOS ; ...
MEMERR_TSS db	'TSS',CR,LF,EOS      ; ...
MEMERR_IDT db	'IDT',CR,LF,EOS      ; ...
MEMERR_IREAL db 'INIT_REAL',CR,LF,EOS ; ...
MEMERR_DVGA db	'DVGA',CR,LF,EOS     ; ...
MEMERR_PRO  db	'PRO=',CR,LF,EOS     ; ...
MEMERR_VIDEO db 'VIDEO=',CR,LF,EOS   ; ...
MEMERR_SETUPDPCI db 'SETUP_DPCI',CR,LF,EOS ; ...

	public	MSG_CHECK_XMS,MSG_CHECK_MODEL,MSG_CHECK_VCPI
	public	MSG_CHECK_EXT,MSG_CHECK_PSWAT,MSG_DEV_ARGS
	public	MSG_INIT_VCPI, MSG_INIT_VCPI1,MSG_INIT_VCPI2
	public	MSG_INIT_VCPI3,MSG_INIT_VCPI4,MSG_INIT_VCPIZ
	public	MSG_CHECK_CPUID,MSG_CHECK_P5,MSG_CHECK_NDP,MSG_CHECK_VID,MSG_CHECK_PCI_BIOS
	public	MSG_CHECK_ARGS,MSG_CHECK_BPI,MSG_SET_MONO,MSG_SET_CO80,
	public	MSG_U16_SET_ATTRS,MSG_LOADUP,MSG_PROT_INIT,MSG_PROT_INITZ
	public	MSG_COPYLOW,MSG_COPYLOWZ,MSG_SETINTS,MSG_INTRUDE_HOOK,MSG_VIRT_INIT
	public	MSG_VCPI_PRES,MSG_VCPI_DPRES,MSG_VCPI_GETINFO,MSG_VCPI_DBGINI
MSG_CHECK_XMS db    '....Calling CHECK_XMS',CR,LF,EOS
MSG_CHECK_MODEL db  '....Calling CHECK_MODEL',CR,LF,EOS
MSG_CHECK_VCPI	db  '....Calling CHECK_VCPI',CR,LF,EOS
MSG_CHECK_EXT db    '....Calling CHECK_EXT',CR,LF,EOS
MSG_CHECK_PSWAT db  '....Calling CHECK_PSWAT',CR,LF,EOS
MSG_DEV_ARGS	db  '....Calling DEV_ARGS',CR,LF,EOS
MSG_CHECK_CPUID db  '....Calling CHECK_CPUID',CR,LF,EOS
MSG_CHECK_P5	db  '....Calling CHECK_P5',CR,LF,EOS
MSG_CHECK_NDP	db  '....Calling CHECK_NDP',CR,LF,EOS
MSG_CHECK_VID	db  '....Calling CHECK_VID',CR,LF,EOS
MSG_CHECK_PCI_BIOS db '....Calling CHECK_PCI_BIOS',CR,LF,EOS
MSG_CHECK_ARGS	db  '....Calling CHECK_ARGS',CR,LF,EOS
MSG_CHECK_BPI	db  '....Calling CHECK_BPI',CR,LF,EOS
MSG_SET_MONO	db  '....Calling SET_MONO',CR,LF,EOS
MSG_SET_CO80	db  '....Calling SET_CO80',CR,LF,EOS
MSG_U16_SET_ATTRS db'....Calling U16_SET_ATTRS',CR,LF,EOS
MSG_INIT_VCPI	db  '....Calling INIT_VCPI',CR,LF,EOS
MSG_INIT_VCPI1	db  '....Calling INIT_VCPI1',CR,LF,EOS
MSG_INIT_VCPI2	db  '....Calling INIT_VCPI2',CR,LF,EOS
MSG_INIT_VCPI3	db  '....Calling INIT_VCPI3',CR,LF,EOS
MSG_INIT_VCPI4	db  '....Calling INIT_VCPI4',CR,LF,EOS
MSG_INIT_VCPIZ	db  '....Called  INIT_VCPI',CR,LF,EOS
MSG_LOADUP	db  '....Calling LOADUP',CR,LF,EOS
MSG_PROT_INIT	db  '....Calling PROT_INIT',CR,LF,EOS
MSG_PROT_INITZ	db  '....Called  PROT_INIT',CR,LF,EOS
MSG_COPYLOW	db  '....Calling COPYLOW',CR,LF,EOS
MSG_COPYLOWZ	db  '....Called  COPYLOW',CR,LF,EOS
MSG_SETINTS	db  '....Calling SETINTS',CR,LF,EOS
MSG_GOPROT	db  '....Calling GOPROT',CR,LF,EOS
MSG_GOPROTZ	db  '....Called  GOPROT',CR,LF,EOS
MSG_INTRUDE_HOOK db '....Calling INTRUDE_HOOK',CR,LF,EOS
MSG_VIRT_INIT	db  '....Calling VIRT_INIT',CR,LF,EOS
MSG_MD_IVIRT	db  '....Calling MD_IVIRT',CR,LF,EOS
MSG_MD_IVIRTZ	db  '....Called  MD_IVIRT',CR,LF,EOS
MSG_VCPI_PRES	db  '....Calling @VCPI_PRES',CR,LF,EOS
MSG_VCPI_DPRES	db  '....Calling @VCPI_DPRES',CR,LF,EOS
MSG_VCPI_GETINFO db '....Calling @VCPI_GETINFO',CR,LF,EOS
MSG_VCPI_DBGINI db  '....Calling @VCPI_DBGINI',CR,LF,EOS

	public	SHF_FLAG
SHF_FLAG db	0		; 1 = Shift-SWAT enabled, 0 = not

	public	SWATVXD_NAME
SWATVXD_NAME db 'SWATVXD.EXE',0 ; SWAT's VxD name
SWATVXD_LEN equ $-SWATVXD_NAME	; Length of ...

	public	MSG_WINCB
MSG_WINCB db	'....The Windows callback address is '
MSG_WINCB1 db	'xxxx:'
MSG_WINCB2 db	'xxxx.',CR,LF,EOS

NDATA	ends			; End NDATA segment


NCODE	segment use16 para public 'ncode' ; Start NCODE segment
	assume	cs:NGROUP

	public	@SWAT_DRV_NCODE
@SWAT_DRV_NCODE:		; Mark module start in .MAP file

	extrn	DISP_COPY:near
	extrn	SKIP_WHITE:near
	extrn	CHECK_I78:near
	extrn	CHECK_I92:near
	extrn	FCN_NORMLIDT:near
	extrn	INIT_MAX:near
	extrn	INTRUDE:near
	extrn	U16_BIN2WORD:near
	extrn	U16_DD2DEC:near

	NPPROC	CHECK_SHIFT -- Check Keyboard Shift States
	assume	ds:NGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check keyboard shift states

|

	REGSAVE <es>		; Save for a moment

	push	seg BIOSDATA	; Get segment of BIOS data area
	pop	es		; Address it
	assume	es:BIOSDATA	; Tell the assembler about it

	test	KB_FLAG,(mask $KB_LSHFT) or (mask $KB_RSHFT) ; Either shift key down?
	jz	short @F	; Jump if not

	mov	SHF_FLAG,1	; Mark as Shift-SWAT enabled
@@:
	REGREST <es>		; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SHIFT endp		; End CHECK_SHIFT procedure
	NPPROC	DISP_PROGMSG -- Display Progress Message
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display progress message

|

DPM_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
DPM_OFF dw	?		; Offset in NGROUP of progress message

DPM_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	cmp	SHF_FLAG,1	; Izit enabled?
	jne	short DISP_PROGMSG_EXIT ; Jump if not

	REGSAVE <ax,dx,ds>	; Save registers

	mov	ax,cs		; Get segment of NGROUP
	mov	ds,ax		; Address it
	assume	ds:NGROUP	; Tell the assembler about it

	mov	dx,[bp].DPM_OFF ; Get offset in NGROUP of progress message
	DOSCALL @STROUT 	; Display specific name

	mov	ah,0		; Wait for a keystroke
	int	16h		; Request keyboard service

	REGREST <ds,dx,ax>	; Restore
	assume	ds:nothing	; Tell the assembler about it
DISP_PROGMSG_EXIT:
	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_PROGMSG endp		; End DISP_PROGMSG procedure
	NPPROC	CHECK_NXTSEG -- Check On Next Segment
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on next segment to ensure we have enough room

|

CNS_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
CNS_OFF dw	?		; Offset in NGROUP of error text

CNS_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ax,dx,ds>	; Save registers

	mov	ax,MAPSEG_NXT	; Get next available segment

	cmp	ax,MAPSEG_LST	; Check against the last segment
	jbe	short @F	; Jump if within range

	mov	ax,cs		; Get segment of NGROUP
	mov	ds,ax		; Address it
	assume	ds:NGROUP	; Tell the assembler about it

	DOSCALL @STROUT,MEMERR	; Display general out-of-memory error
	mov	dx,[bp].CNS_OFF ; Get offset in NGROUP of specific text
	DOSCALL @STROUT 	; Display specific name
@@:
	REGREST <ds,dx,ax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_NXTSEG endp		; End CHECK_NXTSEG procedure
	NPPROC	APPENDVXD -- Append VxD Name
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Append our VxD name to the end of resident memory

Note that COPYLOW has already been called
so the resident data is actually in PGROUP
although the data references are in RGROUP.

|

	pusha			; Save all GP registers
	REGSAVE <ds,es> 	; Save segment registers

	lds	si,DRVPATH_VEC	; Get address of driver path
	assume	ds:nothing	; Tell the assembler about it

	cmp	ds:[si+1].ELO,'\:' ; Is drive/path separator present?
	jne	short APPENDVXD_EXIT ; Jump if not

	mov	ax,seg PGROUP	; Get actual resident data segment
	mov	es,ax		; Address it
	assume	es:PGROUP	; Tell the assembler about it

	mov	di,PRTAIL	; Get ending address

; Copy device driver path

	mov	cx,DRVPATH_END	; Get ending offset
	sub	cx,si		; Less starting offset
    rep movs	es:[di].LO,ds:[si].LO ; Copy to ending address

; Working backwards, stop at path separator

@@:
	dec	di		; Back off to last character

	cmp	di,PRTAIL	; Izit back to start?
	je	short APPENDVXD_EXIT ; Jump if so

	cmp	es:[di].LO,'\'  ; Izit path separator?
	jne	short @B	; Jump if not

	inc	di		; Skip over path separator

	lea	si,SWATVXD_NAME ; Get offset of VxD name
	mov	cx,SWATVXD_LEN	; Get length of ...
    rep movs	es:[di].LO,SWATVXD_NAME[si] ; Copy the name

	mov	ax,seg NGROUP	; Get segment of PRTAIL
	mov	ds,ax		; Address it
	assume	ds:NGROUP	; Tell the assembler about it

	xchg	di,PRTAIL	; Save as new ending address
	assume	es:RGROUP	; Tell white lie
	mov	SWATVXD_PRES,di ; Mark as present
	assume	es:PGROUP	; Retract nose

; Ensure SWATVXD file is present on disk where we think it should be

	push	ds		; Save for a moment

	mov	ax,es		; Copy segment of VxD name
	mov	ds,ax		; Address if
	assume	ds:nothing	; Tell the assembler about it
	mov	dx,di		; Copy offset of VxD name

	mov	al,@OPEN_R	; Code for read-only
	DOSCALL @OPENF2 	; Request DOS services
	pop	ds		; Restore
	assume	ds:NGROUP	; Tell the assembler about it
	jc	short @F	; Jump if not present

	mov	bx,ax		; Copy to handle register
	DOSCALL @CLOSF2 	; Close it

	jmp	short APPENDVXD_EXIT ; Jump if present


@@:
	xor	di,di		; Get zero to clear flag
	assume	es:RGROUP	; Tell white lie
	xchg	di,SWATVXD_PRES ; Mark as not present
	assume	es:PGROUP	; Retract nose
	mov	PRTAIL,di	; Restore original tail

	DOSCALL @STROUT,MSG_NOVXD ; Tell 'em about our problem
APPENDVXD_EXIT:
	REGREST <es,ds> 	; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it
	popa			; ...

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

APPENDVXD endp			; End APPENDVXD procedure
	NPPROC	DISP_WINCB -- Display Win CB Address
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Display the Windows Callback address for the INSERT command

|

	REGSAVE <ax,dx,di,es>	; Save registers

	mov	ax,ds		; Get NGROUP segment
	mov	es,ax		; Address it
	assume	es:NGROUP	; Tell the assembler about it

	mov	ax,RGRSEG1	; Get the segment
	lea	di,MSG_WINCB1	; ES:DI ==> output save area
	call	U16_BIN2WORD	; Convert AX to hex at ES:DI

	mov	ax,PTR_DEV_WINCB ; Get the offset
	lea	di,MSG_WINCB2	; ES:DI ==> output save area
	call	U16_BIN2WORD	; Convert AX to hex at ES:DI

	DOSCALL @STROUT,MSG_WINCB ; Display the string

	REGREST <es,di,dx,ax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_WINCB endp 		; End DISP_WINCB procedure
	FPPROC	DEV_INTR_NR -- Device Interrupt Routine
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Non-resident device driver interrupt routine.

|

.8086
	mov	OLDDEVSTK_VEC.VOFF,sp ; Save old stack pointer
	mov	OLDDEVSTK_VEC.VSEG,ss ; ...
DOT386 p
	movzx	esp,sp		; In case it's non-zero
	lss	sp,INIDEVSTK_VEC ; Install our local stack
	assume	ss:nothing	; Tell the assembler about it

	pushad			; Save all EGP registers
	REGSAVE <ds,es,fs,gs>	; Save segment registers

	push	seg NGROUP	; Get NGROUP data segment
	pop	ds		; Address it
	assume	ds:NGROUP	; Tell the assembler about it

	push	seg PGROUP	; Get PGROUP data segment
	pop	fs		; Address it
	assume	fs:PGROUP	; Tell the assembler about it

	push	seg RGROUP	; Get RGROUP data segment
	pop	gs		; Address it
	assume	gs:RGROUP	; Tell the assembler about it

	les	bx,RH_VEC	; ES:BX ==> request header
	assume	es:nothing	; Tell the assembler about it

	STATUS	DONE,NOERROR	; Set status word (done, no error)

; Mark as being loaded as a device driver
; and that we need to append our PTEs to the end of the VCPI DE01 call

	or	DEVLOAD,@DEVL_LOAD or @DEVL_VCPIPTE ; Mark it

	cmp	es:[bx].SRH_CCD,0 ; Izit initialization?
	jne	near ptr DEV_INTR_NR_EXIT ; Not this time

	mov	ax,es:[bx].INIT_END_VEC.VSEG ; Get last available para
	mov	MAPSEG_LST,ax	; Save for later use

	push	ds		; Save for a moment

	push	seg DGROUP	; Get DGROUP data segment
	pop	ds		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

;;;;;;; mov	MSG_FLVM[3],'R' ; Mark as RM instead of VM
;;;;;;;
	xor	eax,eax 	; Zero to use as dword
	mov	ax,seg PGROUP	; Get segment to which DEVINTCOM is relocated
	shl	eax,4-0 	; Convert from paras to bytes
	add	eax,offset RGROUP:DEVINTCOM ; Plus its offset
	mov	LaDEVINTCOM,eax ; Save for later use

	xor	eax,eax 	; Zero to use as dword
	mov	ax,seg PGROUP	; Get segment to which RM_IDTRL is relocated
	shl	eax,4-0 	; Convert from paras to bytes
	add	eax,offset RGROUP:RM_IDT ; Plus its offset
	mov	LaRM_IDT,eax	; Save for later use

	pop	ds		; Restore
	assume	ds:NGROUP	; Tell the assembler about it

	call	DISP_COPY	; Display our copyright notice

; See if either shift key is held down

	call	CHECK_SHIFT	; Check on shift key state

; Check on preceding device SWAT.  Note we put the check here
; so we can test the presence bit in INIT_REAL.

	STROUT	CHECK_PSWAT
	call	CHECK_PSWAT	; Check on it

; See if there's an XMS handler present

	STROUT	CHECK_XMS
	call	CHECK_XMS	; See if it's present

; See what type of system we're running on

	STROUT	CHECK_MODEL
	call	CHECK_MODEL	; Set model-specific flags

; See if there's a VCPI host present

	STROUT	CHECK_VCPI
	call	CHECK_VCPI	; See if it's present
	jc	near ptr DEV_INTR_NR_ERR ; Jump if something went wrong

; Get physical size of memory

	STROUT	CHECK_EXT
	call	CHECK_EXT	; Get size of extended memory

	STROUT	DEV_ARGS
	call	DEV_ARGS	; Process arguments, call INIT_REAL
	jc	near ptr DEV_INTR_NR_ERR ; Jump if something went wrong

	STROUT	INIT_VCPI
	call	INIT_VCPI	; Initialize VCPI data if appropriate
	jc	near ptr DEV_INTR_NR_ERR ; Jump if something went wrong

	STROUT	INIT_VCPIZ
	test	DEV_FLAG,@DEV_INTRUDE ; Are we INTRUDEing today?
	jnz	short DEV_INTR_NR_INTRUDE ; Jump if we were successful

; Copy the resident portion to extended memory

	STROUT	LOADUP
	call	LOADUP		; Copy it upstairs
	jc	short DEV_INTR_NR_ERR ; Jump if something went wrong

	STROUT	PROT_INIT
	call	PROT_INIT	; Initialize PM
	jc	short DEV_INTR_NR_ERR ; Jump if something went wrong
	STROUT	PROT_INITZ
DEV_INTR_NR_INTRUDE:
	STROUT	COPYLOW
	call	COPYLOW 	; Copy RGROUP to low memory in PGROUP
	STROUT	COPYLOWZ

	test	DEV_FLAG,@DEV_INTRUDE ; Are we INTRUDEing today?
	jnz	short @F	; Jump if so

	STROUT	SETINTS
	call	SETINTS 	; Setup interrupt handlers
@@:
	test	DEV_FLAG,@DEV_INTRUDE ; Are we INTRUDEing today?
	jz	short @F	; Jump if not

; Hook INTRUDE interrupts

	STROUT	INTRUDE_HOOK
	call	INTRUDE_HOOK	; Hook it
@@:
	STROUT	VIRT_INIT
	call	VIRT_INIT	; Initialize VM
	jc	short DEV_INTR_NR_ERR ; Jump if something went wrong

	call	DISP_WINCB	; Display a message about the Win CB address

; If we're providing WKD services, and SWATVXD is present
; in the same directory as SWAT, append its path to the
; end of resident memory for use at 1605 time

	test	TRP_FLAG,@TRP_VXD ; Izit to be loaded?
	jz	short @F	; Jump if not

	call	APPENDVXD	; Append the VxD name to PRTAIL
@@:
	mov	es:[bx].INIT_END_VEC.VSEG,seg PGROUP ; Mark as ending address
	mov	ax,PRTAIL	; Get ending offset in RGROUP
	mov	es:[bx].INIT_END_VEC.VOFF,ax ; ...

	jmp	short DEV_INTR_NR_EXIT ; Join common exit code


DEV_INTR_NR_ERR:
	mov	SWATINI.MD_DD.DD_ATTR,0 ; Bug in DOS doesn't allow char devices to
				; fail initialization -- convert to block device
	mov	es:[bx].INIT_UNITS,0 ; No units defined
	mov	es:[bx].INIT_END_VEC.VSEG,seg PGROUP ; Mark as ending address
	mov	es:[bx].INIT_END_VEC.VOFF,0 ; ...

	STATUS	DONE,ERROR,ERR_UGH ; Mark as general failure

	mov	dx,DRV_ERRMSG	; Get address of error message (if any)

	cmp	dx,@ERRMSG_NONE ; No error message?
	je	short @F	; Jump if so

	DOSCALL @STROUT 	; Tell 'em why
@@:
	DOSCALL @STROUT,MSG_NOTINST ; Tell 'em we're not installed
	DOSCALL @STROUT,MSG_PRESS ; Tell 'em what to do

; Purge the keyboard buffer and wait for a key press -- discard the key

	call	KEYWAIT 	; Wait for an acknowledgement
				; Return with key in AX
DEV_INTR_NR_EXIT:

; If we allocated a zero-length XMS handle, free it now

	mov	dx,XMSZLEN	; Get XMS handle

	and	dx,dx		; Wuzit allocated?
	jz	short @F	; Jump if not

	mov	ah,@XMS_RELXMB	; Function code to free XMS memory
	call	XMSDRV_VEC	; Request XMS service

	cmp	ax,1		; Did it work?
	je	short @F	; Jump if so

	int	03h		; Call our debugger
@@:
	REGREST <gs,fs,es,ds>	; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it
	assume	fs:nothing,gs:nothing ; ...
	popad			; Restore all EGP registers

	lss	sp,OLDDEVSTK_VEC ; Restore original stack
	assume	ss:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEV_INTR_NR endp		; End DEV_INTR_NR procedure
	NPPROC	INTRUDE_HOOK -- Hook Interrupts INTRUDE
	assume	ds:NGROUP,es:nothing,fs:nothing,gs:RGROUP,ss:nothing
COMMENT|

Hook INT 2Fh for Windows callback
Hook INT 68h for Windows Kernel Debugger

Note that this routine is called after COPYLOW, so RGROUP is in PGROUP.

The incoming value in GS:RGROUP is the pre-COPYLOW value.  The value
in RGRSEG1 is the post-COPYLOW value.  The former is needed to address
RGRSEG1, the latter is needed to store into OLDDEV2F_VEC and address
RMDEV2F.

|

	REGSAVE <ax,bx,dx,ds,es> ; Save for a moment

	mov	ds,RGRSEG1	; Address it
	assume	ds:RGROUP	; Tell the assembler about it

	mov	al,2Fh		; Intercept this one
	DOSCALL @GETINT 	; Return with ES:BX ==> old handler
	assume	es:nothing	; Tell the assembler about it

	mov	OLDDEV2F_VEC.VOFF,bx ; Save for later use
	mov	OLDDEV2F_VEC.VSEG,es ; ...

;;;;;;; mov	al,2Fh		; Intercept this one
	DOSCALL @SETINT,RMDEV2F ; Install our handler

	test	TRP_FLAG,@TRP_I68 ; Izit enabled?
	jz	short @F	; Jump if not

	mov	al,68h		; Intercept this one
	DOSCALL @GETINT 	; Return with ES:BX ==> old handler
	assume	es:nothing	; Tell the assembler about it

	mov	OLDDEV68_VEC.VOFF,bx ; Save for later use
	mov	OLDDEV68_VEC.VSEG,es ; ...

;;;;;;; mov	al,68h		; Intercept this one
	DOSCALL @SETINT,DEV_INT68 ; Install our handler
@@:
	REGREST <es,ds,dx,bx,ax> ; Restore
	assume	ds:NGROUP,es:nothing ; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INTRUDE_HOOK endp		; End INTRUDE_HOOK procedure
	NPPROC	CHECK_XMS -- Check On XMS Driver
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Check on XMS driver

|

	REGSAVE <ax,bx,es>	; Save registers

	mov	ax,4300h	; Function code to check on XMS driver
	int	2Fh		; Request multiplexor service

	cmp	al,80h		; Izit present?
	jne	short CHECK_XMS_EXIT ; Jump if not

	mov	ax,4310h	; Function code to get driver entry point
	int	2Fh		; Request multiplexor service
	assume	es:nothing	; Tell the assembler about it

	mov	XMSDRV_VEC.VOFF,bx ; Save for later use
	mov	XMSDRV_VEC.VSEG,es ; ...

	mov	RMSDRV_VEC.VOFF,bx ; Save for later use
	mov	RMSDRV_VEC.VSEG,es ; ...

	or	DEV_FLAG,@DEV_XMS ; Mark as present
CHECK_XMS_EXIT:
	REGREST <es,bx,ax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_XMS endp			; End CHECK_XMS procedure
	NPPROC	CHECK_VCPI -- Check On VCPI Host
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Check on VCPI host

|

	pusha			; Save all GP registers

; In case we're under a memory manager in AUTO mode, allocate
; a zero-length XMS handle to put it into VM.

	test	DEV_FLAG,@DEV_XMS ; Is there an XMS driver present?
	jz	short @F	; Jump if not

	xor	dx,dx		; Size of request in kilobytes
	mov	ah,@XMS_GETXMB	; Function code to allocate XMS memory
	call	XMSDRV_VEC	; Request XMS service

	cmp	ax,1		; Did it work?
	jne	short @F	; Jump if not

	mov	XMSZLEN,dx	; Save to free later
@@:
	smsw	ax		; Get MSW

	test	ax,mask $PE	; Izit in VM86 mode?
	jz	near ptr CHECK_VCPI_CLC ; Jump if not

; Check for various known memory managers

	mov	cx,PMMDEV_LEN	; Get # table entries
	xor	si,si		; Initialize index into table
CHECK_VCPI_NEXT:
	mov	al,@OPEN_R	; Code for read-only access
	mov	dx,PMMDEV[si].MMDEV_OFF ; Get offset in NGROUP of ASCIIZ name
	DOSCALL @OPENF2 	; Attempt to open the device
	jnc	short CHECK_VCPI_FND ; Jump if present
CHECK_VCPI_LOOP:
	add	si,type MMDEV_STR ; Skip to next entry

	loop	CHECK_VCPI_NEXT ; Jump if more table entries to check

	jmp	CHECK_VCPI_CLC	; Join common exit code


CHECK_VCPI_FND:
	mov	bx,ax		; Copy to handle register

	mov	al,0		; Code to get device info
	DOSCALL @IOCTL2 	; Return with DX = device info
	pushf			; Save CF from DOSCALL
	DOSCALL @CLOSF2 	; Close the file
	popf			; Restore
	jc	short CHECK_VCPI_LOOP ; Jump if IOCTL failed

	test	dx,@IOCTL_DEV	; Izit a device?
	jz	short CHECK_VCPI_LOOP ; Jump if not

; Set the flag bits

	mov	ax,PMMDEV[si].MMDEV_FLG ; Get DEV_FLAG bits to set
	or	DEV_FLAG,ax	; Set them bits

; See if there's a VCPI host present

	STROUT	VCPI_PRES
	VCPICALL @VCPI_PRES	; Check on VCPI host
				; Return with AH = 0 if present
				;	 (BH,BL) = version #
	cmp	ah,0		; Izit present?
	jne	short CHECK_VCPI_ERR ; Jump if not

	DOSCALL @STROUT,MSG_VCPI ; Tell 'em what we found

	or	DEV_FLAG,@DEV_VCPI ; Mark as using VCPI services to enter PM
	or	DEVLOAD,@DEVL_VCPI ; ...
	mov	PE_MASK,0	; Zero for CHECK_VMTF
	mov	VCPSTK_FVEC.FSEL,DTE_ES ; Setup VCPI device stack

; Read the master and slave IRQ bases

	VCPICALL @VCPI_GIBV	; Return with BX = master base
				; ...	      CX = slave base
	mov	SWATINI.MD_IBV0,bl ; Save for later use
	mov	SWATINI.MD_IBV1,cl ; ...

	REGSAVE <es,fs> 	; Save for a moment

	mov	ax,seg NGROUP	; Get segment for FCN_NORMLIDT
	mov	es,ax		; Address it
	assume	es:NGROUP	; Tell the assembler about it

	mov	ax,seg DGROUP	; Get segment for FCN_NORMLIDT
	mov	fs,ax		; Address it
	assume	fs:DGROUP	; Tell the assembler about it

	call	FCN_NORMLIDT	; Mark as NORMLIDT in effect

; Get current INT 67h holder

	mov	al,67h		; Interrupt #
	DOSCALL @GETINT 	; Return with ES:BX ==> handler
	assume	es:nothing	; Tell the assembler about it

	mov	OLDINT67_VEC.VOFF,bx ; Save for later use
	mov	OLDINT67_VEC.VSEG,es ; ...

	REGREST <fs,es> 	; Restore
	assume	es:nothing,fs:nothing ; Tell the assembler about it
CHECK_VCPI_CLC:
	clc			; Mark as successful

	jmp	short CHECK_VCPI_EXIT ; Join common exit code


CHECK_VCPI_ERR:
	mov	DRV_ERRMSG,offset NGROUP:MSG_NOVCPI ; Tell 'em the bad news

	stc			; Mark as in error
CHECK_VCPI_EXIT:
	popa			; Restore all GP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_VCPI endp 		; End CHECK_VCPI procedure
	NPPROC	INIT_VCPI -- Initialize VCPI Data
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Initialize VCPI data

The low memory is organized as follows:

* SegCR3 is on a 4KB boundary and contains PDIR entries for 4KB.  The
  initial entries are of SegPTE and as many following 4KB PDIRs as
  needed.

* SegPTE follows SegCR3 (and thus is also on a 4KB boundary).  It is
  filled in with as many PTEs as the VCPI host requires.  This is
  immediately followed by as many PTEs as SWAT requires (based on
  SWAT_TSIZ).  At OffCR3 we save the physical address of the extended
  memory CR3 (SegCR3 is temporary).  At OffPDIR and following are the
  physical addresses of as many PDIRs needed to cover all of the
  needed linear addresses (typically, this is a single PDIR but it can
  be more in case SWAT plus the VCPI host's PTEs overflow into the
  next 4MB).

  By putting the new CR3 and PDIRs into the PTE we can address them
  via the linear address which corresponds to OffCR3 and OffPDIR.

  Note that when we copy the PTEs to extended memory, we also copy the
  PTE which corresponds to CR3.  This way, SWAT can find it when doing
  a LIN2LIN.

*

|

	pushad			; Save all EGP registers
	REGSAVE <es>		; Save register

	test	DEV_FLAG,@DEV_VCPI ; Are we using VCPI services?
	lea	dx,MSG_DEVSWAT	; Assume we're loading as device SWAT
	jz	near ptr INIT_VCPI_CLC ; Jump if not

	mov	SWATINI.MD_IPROT.FSEL,DTE_LOAD ; Save for protected mode init
	mov	SWATINI.MD_RPROT.FSEL,DTE_LOAD ; ...			  restore

; Setup for VCPI calls

	mov	ax,MAPSEG_NXT	; Get next available segment
	add	ax,(4*1024/16-1) ; Round up to 4KB boundary
	and	ax,not (4*1024/16-1) ; ...
	mov	SegCR3,ax	; Save as segment of CR3 (/4KB)
	add	ax,4*1024/16	; Skip over CR3
	mov	SegPTE,ax	; Save as segment of PTEs (/4KB)
	mov	MAPSEG_NXT,ax	; Protect the CR3

	push	offset NGROUP:MEMERR_SEGPTE ; Pass offset of error message
	call	CHECK_NXTSEG	; Ensure we've enough room

; Setup PMI

	mov	es,SegPTE	; Get segment of PTEs (/4KB)
	assume	es:nothing	; Tell the assembler about it

	xor	di,di		; ES:DI ==> PTEs

	push	ds		; Save for a moment

	lds	si,PSWATGDT	; DS:SI ==> SWAT's GDT
	assume	ds:RGROUP	; Tell the assembler about it

	add	si,DTE_VCPI	; DS:SI ==> three DTEs for PMI
	VCPICALL @VCPI_GPMI	; Return with EBX=offset, DI=advanced

	pop	ds		; Restore
	assume	ds:NGROUP	; Tell the assembler about it

	cmp	ah,0		; Check for error
	SETMSG	DRV,"Unable to read VCPI Protected Mode Interface data."
	jne	near ptr INIT_VCPI_ERR ; Jump if not OK

	mov	PMI_FVEC.FOFF,ebx ; Save offset of PMI
	mov	PMI_FVEC.FSEL,DTE_VCPI ; Save selector of PMI

	movzx	edi,di		; Zero to use as dword
	mov	ax,di		; Copy offset
	shr	ax,12-(12-2)	; Convert from 4KB in dwords to 4KB
	mov	NUM_VCPI_PTE,ax ; Save for later use

; In case the VCPI host doesn't include the HMA, we include it here
; For some reason, EMM386 fills in 0410h bytes (1MB + 16KB) and the
; 4 PTEs at 1MB are not one-to-one.  Moreover, those PTEs do not
; reflect the mapping it uses when DOS is in effect.  The workaround
; here is to blast in one-to-one PTEs.	Damn the torpedoes!

	cmp	edi,((1024+64)*1024) shr (12-2) ; Izit at or above 1.1MB?
	jae	short INIT_VCPI_HMAOK ; Jump if so

	mov	ecx,64/4	; Get # PTEs to blast in
	mov	edi,(1024*1024) shr (12-2) ; Get offset of 1MB

	mov	eax,edi 	; Copy ending offset
	shl	eax,(12-2)-0	; Convert from 4KB in dwords to bytes
	or	eax,@PTE_URP	; Mark as User/Read-Write/Present
@@:
S32	stos	es:[edi].EDD	; Save as address of next PTE
	add	eax,4*1024	; Skip to next PTE

	LOOPD	@B		; Jump if more PDIRs to fill in
INIT_VCPI_HMAOK:

; If we're INTRUDEing, reserve space for the MM's GDT and IDT

	test	DEV_FLAG,@DEV_INTRUDE ; Are we INTRUDEing today?
	jz	near ptr INIT_VCPI_XINTRUDE ; Jump if not

	push	es		; Save for a moment

	mov	ax,seg DGROUP	; Get segment of RUD_xDTR variables
	mov	es,ax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	SGDTD	RUD_GDTR	; Save old GDTR for when we INTRUDE
	SIDTD	RUD_IDTR	; ...	   IDTR ...

	shl	edi,(12-2)-0	; Convert from 4KB in dwords to bytes

	movzx	eax,RUD_GDTR.DTR_LIM ; Get the GDT limit
	inc	eax		; Convert from limit to length
	and	eax,not ((size DESC_STR)-1) ; Round down to DTE boundary
				; in case someone uses a length instead
				; of a limit
	mov	ebx,RUD_GDTR.DTR_BASE ; Get the base address
	and	ebx,not @PTE_FRM ; Isolate the offset
	add	eax,ebx 	; Add to get ending address
	add	eax,4*1024-1	; Round up to 4KB boundary
	and	eax,not (4*1024-1) ; ...
	mov	RUDLaGDT,edi	; Save as offset of GDT in our linear address space
	add	RUDLaGDT,ebx	; Plus the offset in the 4KB page
	add	edi,eax 	; Skip over the GDT
	shr	eax,12-0	; Convert from bytes to 4KB (# PTEs)
	mov	RUDGDTCNT,ax	; Save for later use

	movzx	eax,RUD_IDTR.DTR_LIM ; Get the IDT limit
	inc	eax		; Convert from limit to length
	and	eax,not ((size IDT_STR)-1) ; Round down to IDT boundary
				; in case someone uses a length instead
				; of a limit
	mov	ebx,RUD_IDTR.DTR_BASE ; Get the base address
	and	ebx,not @PTE_FRM ; Isolate the offset
	add	eax,ebx 	; Add to get ending address
	add	eax,4*1024-1	; Round up to 4KB boundary
	and	eax,not (4*1024-1) ; ...
	mov	RUDLaIDT,edi	; Save as offset of IDT in our linear address space
	add	RUDLaIDT,ebx	; Plus the offset in the 4KB page
	add	edi,eax 	; Skip over the IDT
	shr	eax,12-0	; Convert from bytes to 4KB (# PTEs)
	mov	RUDIDTCNT,ax	; Save for later use

	shr	edi,(12-2)-0	; Convert from bytes to 4KB in dwords

	pop	es		; Restore
	assume	es:nothing	; Tell the assembler about it
INIT_VCPI_XINTRUDE:

; If there's a preceding SWAT, reserve space for it

	test	DEVLOAD,@DEVL_PSWAT ; Izit present?
	jz	short @F	; Jump if not

	shl	edi,(12-2)-0	; Convert from 4KB in dwords to bytes
	mov	LaPSWAT,edi	; Save as new linear address (/4KB)
	add	edi,PSWAT_TSIZ	; Skip over it
	shr	edi,(12-2)-0	; Convert from bytes to 4KB in dwords
@@:
	mov	NEXTPTE.ELO,di	; Save offset of next available PTE

; Next in the extended memory linear address space is the IDT,
; device SWAT's stack (after entering PM but before calling SWAT),
; and the TSS (for VCPI SWAT) followed by SWAT itself (code/data).

	mov	eax,edi 	; Copy offset in 4KB in dwords
	shl	eax,(12-2)-0	; Convert from 4KB in dwords to bytes

	mov	LaCODE,eax	; Save as linear address of our code
	add	eax,SWAT_DAT	; Plus offset to data segment

	mov	LaDATA,eax	; Save as linear address of our data

	mov	eax,LaCODE	; Get linear address of our code
	add	eax,SWAT_TSIZ	; Plus total size of PM-resident SWAT
	mov	LaIDT,eax	; Save as linear address of IDT

	add	eax,256*(type IDT_STR) ; Skip over the IDT
	mov	LaSTK,eax	; Save as linear address of stack

	add	eax,SWATSTK_FVEC.FOFF ; Skip over the stack
	mov	LaTSS,eax	; Save as linear address of TSS

	add	eax,size TSS_STR ; Skip over TSS
	mov	LaEND,eax	; Save as ending linear address

; Make room for the Page Directory followed by PTEs sufficient
; for room for the IDT, stack, TSS, and SWAT

;;;;;;; mov	eax,LaEND	; Get ending linear address
	add	eax,4*1024-1	; Round up to 4KB boundary
	and	eax,not (4*1024-1) ; ...
	shr	eax,(12-2)-0	; Convert from bytes to 4KB in dwords
	sub	eax,NEXTPTE	; Less # PTEs already saved

	shr	eax,12-(12-2)	; Convert from 4KB in dwords to 4KB (# PTEs)
	mov	NDRVPTE,eax	; Save for later use

	REGSAVE <eax,es>	; Save for a moment

	mov	eax,LaEND	; Get ending linear address
	add	eax,4*1024-1	; Round up to 4KB boundary
	and	eax,not (4*1024-1) ; ...
	shr	eax,10-0	; Convert from bytes to 1KB

	sub	eax,4*1024	; Izit too big for VCPI clients?
	jbe	short @F	; Jump if not

	mov	di,seg NGROUP	; Get segment of RUD_xDTR variables
	mov	es,di		; Address it
	assume	es:NGROUP	; Tell the assembler about it

	lea	di,MSG_PTEFULL1 ; ES:DI ==> output save area
	push	@DEC_LEFT or @DEC_COMMA ; Left-justified, comma-inserted
	call	U16_DD2DEC	; Convert EAX to decimal at ES:DI

	mov	eax,(EOS shl 24) or ('B' shl 16) or ('K' shl 8) or ' ' ; Ending
	stos	es:[di].EDD	; Save as terminator

	DOSCALL @STROUT,MSG_PTEFULL ; Tell 'em to be careful
	DOSCALL @STROUT,MSG_PTEFULL2 ; ...
@@:
	REGREST <es,eax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	shl	eax,12-(12-2)	; Convert from 4KB to 4KB in dwords
	add	eax,NEXTPTE	; Skip over existing PTEs

@NDRVPDIR equ	4		; Maximum # temporary PDIRs we support

	mov	OffCR3,eax	; Save for later use
	add	eax,4		; Skip over it
	mov	OffPDIR,eax	; Save for later use
	add	eax,4*@NDRVPDIR ; Skip over temp @NDRVPDIR PDIRs
				; Note that @NDRVPDIR must be <= NRDVPDIR
				; In other words, the VCPI host plus SWAT
				; cannot exceed 4MB * @NDRVPDIR.

; If we're loading any symbols, reserve space for the PTEs in SegPTE
; but don't allocate the PTEs as we'll use the physical address from
; the XMS lock possibly modified by VDS.

	mov	cx,seg DGROUP	; Get segment of EXTSYM_xxx
	mov	es,cx		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	OffSYM,eax	; Save for later use

; Handle the case where the symbol table physical address is not
; on a 4KB boundary

	mov	ebx,EXTSYM_OFF	; Get symbol table physical address
	mov	ecx,EXTSYM_LEN	; Get byte size of symbol table
	add	ecx,ebx 	; Add to get ending address
	and	ebx,not (4*1024-1) ; Round down to 4KB boundary
	sub	ecx,ebx 	; Subtract to get rounded up length
	add	ecx,4*1024-1	; Round up to 4KB boundary
	shr	ecx,12-0	; Convert from bytes to 4KB
	mov	NSYMPTE,ecx	; Save for later use
	shl	ecx,12-(12-2)	; Convert from 4KB to 4KB in dwords
	add	eax,ecx 	; Skip over symbol table PTEs

; This is the next available offset in bytes after all PTEs

	mov	ecx,eax 	; Copy as maximum size of PTEs
	add	eax,16-1	; Round up to next para
	shr	eax,4-0 	; Convert from bytes to paras
	add	MAPSEG_NXT,ax	; Protect the PTEs

	push	offset NGROUP:MEMERR_ALLPTE ; Pass offset of error message
	call	CHECK_NXTSEG	; Ensure we've enough room

; Calculate the # PDIRs

	add	ecx,4*1024-1	; Round up to 4KB boundary
	shr	ecx,12-0	; Convert from bytes to 4KB (# PDIRs)
	mov	NDRVPDIR,ecx	; Save for later use

; Store symbol table PTEs

	mov	ecx,NSYMPTE	; Get # symbol table PTEs
	jecxz	INIT_VCPI_NOSYM1 ; Jump if nothing to store

	mov	edi,OffSYM	; ES:EDI ==> symbol table PTEs
	mov	eax,edi 	; Copy to calculate the linear address
	shl	eax,(12-2)-0	; Convert from 4KB in dwords to bytes
	xchg	eax,EXTSYM_OFF	; Swap with physical address

	mov	ebx,eax 	; Copy physical address
	and	ebx,4*1024-1	; Isolate offset within 4KB page
	or	EXTSYM_OFF,ebx	; Incorporate back into linear address

	mov	es,SegPTE	; Get segment of PTEs (/4KB)
	assume	es:nothing	; Tell the assembler about it

	or	eax,@PTE_URP	; Mark as User/Read-Write/Present
@@:
S32	stos	es:[edi].EDD	; Save as address of next PTE
	add	eax,4*1024	; Skip to next PTE

	LOOPD	@B		; Jump if more PDIRs to fill in
INIT_VCPI_NOSYM1:

; Zero the temp PDIR PTEs

	mov	es,SegPTE	; Get segment of PTEs (/4KB)
	assume	es:nothing	; Tell the assembler about it

	mov	edi,OffPDIR	; Get offset of temp PDIRs
	mov	ecx,@NDRVPDIR	; Get # PDIRs reserved
	xor	eax,eax 	; A convenient zero
    rep stos	es:[edi].EDD	; Zero the temp PDIRs

; Initialize the PDIR with zeros

	mov	es,SegCR3	; Get segment of CR3 (/4KB)
	assume	es:nothing	; Tell the assembler about it

	xor	edi,edi 	; ES:EDI ==> PDEs

	mov	ecx,4*1024/4	; Get maximum # PDEs
	xor	eax,eax 	; Set 'em all to zero
    rep stos	es:[edi].EDD	; Save as next PDE

; Fill in the PDIRs

	movzx	eax,SegPTE	; Get segment of PTEs (/4KB)
	shl	eax,4-0 	; Convert from paras to bytes
	xor	edi,edi 	; ES:EDI ==> PTEs
	mov	ecx,NDRVPDIR	; Get # PDIRs for SWAT
	or	eax,@PTE_URP	; Mark as User/Read-Write/Present
@@:
S32	stos	es:[edi].EDD	; Save as address of next PDIR
	add	eax,4*1024	; Skip to next PTE

	LOOPD	@B		; Jump if more PDIRs to fill in

; Setup the GDT

	call	INIT_GDT	; Initialize it

; Setup TSS descriptor to point to low memory as we haven't copied
; our code/data to extended memory as yet.

	movzx	ebx,MAPSEG_NXT	; Get next available segment
	mov	SegTSS,bx	; Save for later use
	mov	es,bx		; Address it
	assume	es:nothing	; Tell the assembler about it

	add	MAPSEG_NXT,1+(size TSS_STR)/16 ; Protect the TSS

	push	offset NGROUP:MEMERR_TSS ; Pass offset of error message
	call	CHECK_NXTSEG	; Ensure we've enough room

; Zero the temporary TSS

	xor	edi,edi 	; ES:EDI ==> temporary TSS
	xor	eax,eax 	; A convenient zero
	mov	ecx,(size TSS_STR)/4 ; Get # dwords in TSS
    rep stos	es:[edi].EDD	; Zero it

	shl	ebx,4-0 	; Convert from paras to bytes

	push	dword ptr (size TSS_STR) ; Get length of TSS data
	push	ebx		; Get base address
	push	DTE_TSS 	; Get DTE
	push	CPL0_IDLE3	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

; Fill in the Enter PM structure in preparation for entering PM via VCPI
; Note that these values are temporary solely for the purpose of
; allocating memory for SWAT and its tables.

	mov	VCPEPM.VCPEPM_TR,DTE_TSS ; Save TR
	movzx	eax,SegCR3	; Get segment of CR3 (/4KB)
	shl	eax,4-0 	; Convert from paras to bytes
	mov	VCPEPM.VCPEPM_CR3,eax ; Save in VCPI EPM struc
	mov	es:[0].TSS_CR3,eax ; Save in TSS
	mov	es:[0].TSS_SS0,DTE_SS ; ...
	mov	es:[0].TSS_ESP0,offset NGROUP:RUDSTKZ ; ...

	movzx	eax,PSWATGDT.VSEG ; Get SWAT GDT's segment
	shl	eax,4-0 	; Convert from paras to bytes
	movzx	ebx,PSWATGDT.VOFF ; Get SWAT GDT's offset
	add	eax,ebx 	; Add to get 32-bit linear address
	add	eax,DTE_GDT	; Skip to GDT entry
	mov	VCPEPM.VCPEPM_GDTP,eax ; Save in VCPI EPM struc
	add	eax,DTE_IDT-DTE_GDT ; Skip to IDT entry
	mov	VCPEPM.VCPEPM_IDTP,eax ; Save in VCPI EPM struc

; If there's a preceding SWAT, tell it about the new CR3

	test	DEVLOAD,@DEVL_PSWAT ; Izit present?
	jz	short INIT_VCPI_XPSWAT ; Jump if not

	mov	edx,LaPSWAT	; Get new linear address (/4KB)
	mov	ebx,VCPEPM.VCPEPM_CR3 ; Get the new CR3
	XVCPICALL @VCPI_DBGLIN	; Request SWAT services

; Because we changed the linear address, we need to re-initialize
; the preceding SWAT in our PM GDT.

	push	es		; Save for a moment

	les	di,PSWATGDT	; ES:DI ==> SWAT's GDT
	assume	es:RGROUP	; Tell the assembler about it

	mov	bx,DTE_PSWAT	; Get its code selector
	add	di,bx		; ES:DI ==> GDT entries for preceding device SWAT

	XVCPICALL @VCPI_DBGINI	; Initialize debugger interface with
				; with BX = code selector
				; and ES:DI ==> GDT entries to fill in
				; Return with BX:EDX ==> PM entry point
	pop	es		; Restore
	assume	es:nothing	; Tell the assembler about it
;;;;;;;
;;;;;;; cmp	ah,0		; Did it succeed?
;;;;;;; jne	short ???	; Jump if not
INIT_VCPI_XPSWAT:

; Setup dummy IDT

	movzx	eax,SegIDT	; Get segment of the temporary IDT
	shl	eax,4-0 	; Convert from paras to bytes
	mov	SWATIDTR.DTR_BASE,eax ; Save for later use
	mov	SWATIDTR.DTR_LIM,(type IDT_STR)*256-1 ; ...

; If there's an XMS driver present with enough memory,
; allocate memory that way.

	test	DEV_FLAG,@DEV_XMS ; Is there an XMS driver present?
	jz	near ptr INIT_VCPI_NOXMS ; Jump if not

; Calculate how many 4KB pages we need to allocate

	mov	edx,1		; One for CR3
	add	edx,NDRVPDIR	; Plus PDIRs
	add	edx,NDRVPTE	; Plus PTEs
	shl	edx,12-0	; Convert from 4KB to bytes
	add	edx,4*1024-1	; Add in extra page-1 in case the
				; address we get back isn't on 4KB boundary
	call	ALLOC_XMS	; Allocate EDX bytes of XMS memory
				; returning EAX = base physical address
				;	    CX = handle
	jc	near ptr INIT_VCPI_ERR ; Jump if something went wrong

	test	DEV_FLAG,@DEV_XMS ; Did we fail trying XMS?
	jz	short INIT_VCPI_NOXMS ; Jump if so (try VCPI alone)

	add	eax,4*1024-1	; Round up to 4KB boundary
	and	eax,not (4*1024-1) ; ...

	mov	XMSHNDL,cx	; Save for later use

	mov	es,SegPTE	; Get segment of PTEs (/4KB)
	assume	es:nothing	; Tell the assembler about it

	or	eax,@PTE_URP	; Mark as User/Read-Write/Present

; The first 4KB page is used for CR3

	mov	edi,OffCR3	; Get offset of CR3 temp PTE
S32	stos	es:[edi].EDD	; Save as PTE

; The next NDRVPDIRs are used for PDIRs

	mov	ecx,NDRVPDIR	; Get # PDIRs
	mov	edi,OffPDIR	; Get offset of temp PDIRs
@@:
	add	eax,4*1024	; Skip to next 4KB page
S32	stos	es:[edi].EDD	; Save as PTE

	LOOPD	@B		; Jump if more PDIRs

	mov	ebx,eax 	; Copy last PTE
	and	ebx,@PTE_FRM	; Isolate the 4KB frame
	add	ebx,4*1024	; Skip to next 4KB page
	mov	MMPaXMS,ebx	; Save in case we're INTRUDEing into a MM

; The next NDRVPTEs are used for PTEs

	mov	edi,NEXTPTE	; ES:EDI ==> next available PTE
	mov	ecx,NDRVPTE	; Get # PTEs needed
@@:
	add	eax,4*1024	; Skip to next 4KB page
S32	stos	es:[edi].EDD	; Save as PTE

	LOOPD	@B		; Jump if more PTEs
INIT_VCPI_NOXMS:

; If the MM is 386MAX, read the first PDE in MAX's Page Directory
; because MAX hides this information from the VCPI client.

	test	DEV_FLAG,@DEV_MAX ; Izit present?
	jz	short @F	; Jump if not

	call	INIT_MAX	; Initialize for 386MAX
@@:

; Enter PM via VCPI, allocate all needed memory, fill in the
; PDIR and PTE entries, and copy code and data to extended memory.

	mov	VCPEPM.VCPEPM_EXIT.FSEL,DTE_CS ; Save initial CS
	mov	VCPEPM.VCPEPM_EXIT.FOFF,offset cs:INIT_VCPI_PMINI1 ; ... EIP

	movzx	esi,PVCPEPM.VSEG ; Get segment of VCPEPM
	movzx	eax,PVCPEPM.VOFF ; ... offset ...
	shl	esi,4-0 	; Convert from paras to bytes
	add	esi,eax 	; Add to get 32-bit linear address
	mov	LaVCPEPM,esi	; Save for later use

	STROUT	INIT_VCPI1

; Put return VM registers onto the stack

	mov	eax,esp 	; Get current ESP

	PUSHD	gs		; Place GS onto stack
	PUSHD	fs		; ...	FS ...
	PUSHD	ds		; ...	DS ...
	PUSHD	es		; ...	ES ...
	PUSHD	ss		; ...	SS ...
	push	eax		; ...	ESP ...
	pushfd			; ...	EFL ...
	PUSHD	cs		; ...	CS ...
	lea	eax,INIT_VCPI_VMRET1 ; Get return EIP
	push	eax		; ...	EIP ...

	mov	PMSTK_FVEC.FSEL,DTE_SS ; Setup stack for later use
	mov	PMSTK_FVEC.FOFF,esp ; ...

	cli			; Enter with IF=0

;;;;;;; mov	esi,LaVCPEPM	; ESI = VCPEPM
	VCPICALL @VCPI_EPM	; Enter PM using ESI = EPM struc
INIT_VCPI_PMINI1:
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	cli			; Some VCPI hosts (RM386 comes to mind)
				; start us off with IF=1
	lss	esp,PMSTK_FVEC	; Setup our stack
	assume	ss:nothing	; Tell the assembler about it

	xor	ax,ax		; A convenient zero
	mov	ds,ax		; Clear to avoid fault
	assume	ds:nothing	; Tell the assembler about it
	mov	es,ax		; Clear to avoid fault
	assume	es:nothing	; Tell the assembler about it
	mov	fs,ax		; Clear to avoid fault
	assume	fs:nothing	; Tell the assembler about it
	mov	gs,ax		; ...
	assume	gs:nothing	; Tell the assembler about it

	mov	ax,DTE_4GB	; Get AGROUP data selector
	mov	es,ax		; Address it
	assume	es:AGROUP	; Tell the assembler about it

	mov	ax,DTE_ES	; Get RGROUP data selector
	mov	fs,ax		; Address it
	assume	fs:RGROUP	; Tell the assembler about it

; If we've been asked to, attempt to intrude into the memory manager's
; PL0 context.

	call	INTRUDE 	; Whether they like it or not
	jnc	near ptr INIT_VCPI_INTRUDE1 ; Jump if we succeeded

; Allocate a 4KB page for the permanent CR3

	movzx	ebx,SegPTE	; Get segment of PTEs (/4KB)
	shl	ebx,4-0 	; Convert from paras to bytes
	add	ebx,OffCR3	; Plus offset of CR3 temp PTE

	mov	edx,AGROUP:[ebx] ; Get PDIR at OffCR3 if using XMS

	test	DEV_FLAG,@DEV_XMS ; Is there an XMS driver present?
	jnz	short @F	; Jump if so (already allocated and in EDX)

	mov	ax,(@VCPI shl 8) or @VCPI_ALLOC ; Allocate 4KB for CR3
	call	PMI_FVEC	; Request VCPI service

	cmp	ah,0		; Did it work?
	jne	near ptr INIT_VCPI_PMERR ; Jump if not
@@:
	or	edx,@PTE_URP	; Mark as User/Read-Write/Present
	mov	AGROUP:[ebx],edx ; Save as PDIR at OffCR3

; Flush CR3

	mov	eax,VCPEPM.VCPEPM_CR3 ; Get current value
	mov	cr3,eax 	; Flush it

; Zero the new CR3 page

	mov	edi,OffCR3	; Get offset of CR3 temp PTE
	shl	edi,(12-2)-0	; Convert from 4KB in dwords to bytes
	xor	eax,eax 	; A convenient zero
	mov	ecx,4*1024/4	; # dwords in a 4KB page
    rep stos	AGROUP:[edi].EDD ; Zero the PDIR

; Allocate a 4KB page for each PDIR

	movzx	ebx,SegPTE	; Get segment of PTEs (/4KB)
	shl	ebx,4-0 	; Convert from paras to bytes
	add	ebx,OffPDIR	; Plus offset of temp PDIRs

	mov	edi,OffCR3	; Get offset of CR3 temp PTE
	shl	edi,(12-2)-0	; Convert from 4KB in dwords to bytes
	mov	ecx,NDRVPDIR	; Get # PDIRs
INIT_VCPI_NEXTPDIR:
	mov	edx,AGROUP:[ebx] ; Get PTE if using XMS

	test	DEV_FLAG,@DEV_XMS ; Is there an XMS driver present?
	jnz	short @F	; Jump if so (allready allocated and in EDX)

	mov	ax,(@VCPI shl 8) or @VCPI_ALLOC ; Allocate 4KB for next PDIR
	call	PMI_FVEC	; Request VCPI service

	cmp	ah,0		; Did it work?
	jne	near ptr INIT_VCPI_PMERR ; Jump if not
@@:
	mov	eax,edx 	; Copy to output register
	and	ax,mask $PTE_FRM ; Isolate the 4KB frame
	or	eax,@PTE_URP	; Mark as User/Read-Write/Present
S32	stos	AGROUP:[edi].EDD ; Save as next PDE

	mov	AGROUP:[ebx],eax ; Save as PTE
	add	ebx,4		; Skip over last PTE

	LOOPD	INIT_VCPI_NEXTPDIR ; Jump if more PDIRs to fill in

; Allocate 4KB pages for each PTE and save the physical addresses
; into the PDIRs

	movzx	edi,SegPTE	; Get segment of PTEs (/4KB)
	shl	edi,4-0 	; Convert from paras to bytes
	add	edi,NEXTPTE	; ES:EDI ==> next available PTE

	mov	ecx,NDRVPTE	; Get # PTEs needed

	test	DEV_FLAG,@DEV_XMS ; Is there an XMS driver present?
	jnz	short INIT_VCPI_FLUSH ; Jump if so (already allocated
				; and in SegPTE following NEXTPTE)
INIT_VCPI_NEXTPTE:
	mov	ax,(@VCPI shl 8) or @VCPI_ALLOC ; Allocate 4KB for next PTE
	call	PMI_FVEC	; Request VCPI service

	cmp	ah,0		; Did it work?
	jne	near ptr INIT_VCPI_PMERR ; Jump if not

	mov	eax,edx 	; Copy to output register
	and	ax,mask $PTE_FRM ; Isolate the 4KB frame
	or	eax,@PTE_URP	; Mark as User/Read-Write/Present
S32	stos	AGROUP:[edi].EDD ; Save as next PDE

	LOOPD	INIT_VCPI_NEXTPTE ; Jump if more PTEs to fill in
INIT_VCPI_FLUSH:

; Flush CR3

	mov	eax,VCPEPM.VCPEPM_CR3 ; Get current value
	mov	cr3,eax 	; Flush it

; Copy the temporary PTEs to their permanent home
; At this point, because we put the physical address of the
; new PDIRs as PTEs at OffPDIR and following, we can copy
; all of the PTEs to their final resting place using the
; linear address corresponding to OffPDIR.

	movzx	esi,SegPTE	; Get segment of PTEs (/4KB)
	shl	esi,4-0 	; Convert from paras to bytes

	mov	edi,OffPDIR	; Get offset of temp PDIRs
	shl	edi,(12-2)-0	; Convert from 4KB in dwords to bytes

	mov	ecx,NEXTPTE	; Get offset of next PTE
	shr	ecx,12-(12-2)	; Convert from 4KB in dwords to 4KB (# PTEs)
	add	ecx,NDRVPTE	; Plus # PTEs to copy
	inc	ecx		; Plus the CR3 temp PTE
	add	ecx,@NDRVPDIR	; Plus maximum # temp PDIRs
	add	ecx,NSYMPTE	; Plus # symbol table PTEs
S32 rep movs	<AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy old to new PTEs

; Setup MD_PHYS so INIT_PROT calculates the correct value for
; PLCLPDIR, PaLCLPDIR, PaTMPPAGE, PLCLMONO, and PLCLCOLR.

; Because we don't have addressibility to our DGROUP in low memory,
; we use the linear address of DGROUP in low memory off of AGROUP.

	mov	ax,DTE_DS	; Get PGROUP data selector in low memory
	mov	gs,ax		; Address it
	assume	gs:PGROUP	; Tell the assembler about it

	xor	esi,esi 	; Zero to use as dword
	mov	si,seg DGROUP	; Get segment of DGROUP
	shl	esi,4-0 	; Convert from paras to bytes
				; AGROUP:ESI ==> DGROUP in low memory

; First, find the physical address of BLCLPDIR rounded up to
; the next 4KB boundary

	assume	es:DGROUP	; Tell the assembler about it (note lie)
	mov	eax,BLCLPDIR[esi] ; Get its base address in DGROUP
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
	mov	si,seg PGROUP	; Get start of SWAT
	shl	esi,4-0 	; Convert from paras to bytes

	mov	edi,LaCODE	; Get linear address of code/data

	mov	ecx,SWAT_ISIZ	; Get size of initialized code/data
	shr	ecx,2-0 	; Convert from bytes to dwords
S32 rep movs	<AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy SWAT to extended mem

; Copy the dummy TSS to extended memory

	movzx	esi,SegTSS	; Get segment of TSS
	shl	esi,4-0 	; Convert from paras to bytes

	mov	edi,LaTSS	; Get linear address of TSS in extended memory
	mov	ecx,(size TSS_STR)/4 ; Get length of TSS data in dwords
S32 rep movs	<AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy TSS to extended mem

; Save new CR3 into TSS in extended memory

	movzx	eax,SegPTE	; Get segment of PTEs (/4KB)
	shl	eax,4-0 	; Convert from paras to bytes
	add	eax,OffCR3	; Plus offset to CR3 temp PTE
	mov	eax,AGROUP:[eax] ; Get new CR3
	and	ax,mask $PTE_FRM ; Isolate the 4KB frame
	mov	ebx,LaTSS	; Get linear address of TSS in extended memory
	mov	AGROUP:[ebx].TSS_CR3,eax ; Save in TSS

; Copy the dummy IDT to extended memory

	mov	esi,SWATIDTR.DTR_BASE ; Get source IDT
	mov	edi,LaIDT	; Get destination IDT
	mov	ecx,(256*(type IDT_STR))/4 ; Get # dwords in IDT
S32 rep movs	<AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy IDT to extended mem





INIT_VCPI_INTRUDE1:
	mov	bx,DRV_ERRMSG	; Mark as no error

	jmp	short INIT_VCPI_PMRET ; Join common return code


INIT_VCPI_PMERR:
	lea	bx,MSG_NOVCPMEM ; Insufficient VCPI memory
INIT_VCPI_PMRET:
	mov	ax,DTE_4GB	; Get AGROUP data selector
	mov	ds,ax		; Address it
	assume	ds:AGROUP	; Tell the assembler about it

	cli			; Exit with IF=0

	mov	ax,(@VCPI shl 8) or @VCPI_EPM ; Get return function
	call	PMI_FVEC	; Request VCPI service
INIT_VCPI_VMRET1:
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing

	sti			; Enable interrupts

	STROUT	INIT_VCPI2

; Check for errors from PM

	mov	DRV_ERRMSG,bx	; Save error offset (if any)

	cmp	bx,@ERRMSG_NONE ; No error messages?
	jne	near ptr INIT_VCPI_ERR ; Jump if not

	mov	dx,RUD_ERRMSG	; Get address of error message (if any)

	cmp	dx,@ERRMSG_NONE ; No error messages?
	je	short @F	; Jump if so

	DOSCALL @STROUT 	; Tell 'em why
@@:
	test	DEV_FLAG,@DEV_INTRUDE ; Are we INTRUDEing today?
	jnz	near ptr INIT_VCPI_INTRUDE2 ; Jump if so

; Setup TSS descriptor to point to extended memory

	push	dword ptr (size TSS_STR) ; Get length of TSS data
	push	LaTSS		; Get base address
	push	DTE_TSS 	; Get DTE
	push	CPL0_IDLE3	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

; Save new CR3

	mov	es,SegPTE	; Get segment of PTEs (/4KB)
	assume	es:nothing	; Tell the assembler about it

	mov	eax,OffCR3	; Get offset of CR3 temp PTE
	mov	eax,es:[eax]	; Get new CR3
	and	ax,mask $PTE_FRM ; Isolate the 4KB frame
	mov	VCPEPM.VCPEPM_CR3,eax ; Save in VCPI EPM struc

; If there's a preceding SWAT, tell it about the new CR3

	test	DEVLOAD,@DEVL_PSWAT ; Izit present?
	jz	short @F	; Jump if not

	mov	edx,LaPSWAT	; Get new linear address (/4KB)
	mov	ebx,VCPEPM.VCPEPM_CR3 ; Get the new CR3
	XVCPICALL @VCPI_DBGLIN	; Request SWAT services
@@:
	mov	eax,LaIDT	; Get linear address of SWAT's IDT
	mov	SWATIDTR.DTR_BASE,eax ; Save for later use

; Enter PM again with using the new CR3 and initialize PM

	mov	VCPEPM.VCPEPM_EXIT.FSEL,DTE_CS ; Save initial CS
	mov	VCPEPM.VCPEPM_EXIT.FOFF,offset cs:INIT_VCPI_PMINI2 ; ... EIP

	STROUT	INIT_VCPI3

; Put return VM registers onto the stack

	mov	eax,esp 	; Get current ESP

	PUSHD	gs		; Place GS onto stack
	PUSHD	fs		; ...	FS ...
	PUSHD	ds		; ...	DS ...
	PUSHD	es		; ...	ES ...
	PUSHD	ss		; ...	SS ...
	push	eax		; ...	ESP ...
	pushfd			; ...	EFL ...
	PUSHD	cs		; ...	CS ...
	lea	eax,INIT_VCPI_VMRET2 ; Get return EIP
	push	eax		; ...	EIP ...

	mov	PMSTK_FVEC.FSEL,DTE_SS ; Setup stack for later use
	mov	PMSTK_FVEC.FOFF,esp ; ...

	cli			; Enter with IF=0

	mov	esi,LaVCPEPM	; Get linear address of VCPEPM
	VCPICALL @VCPI_EPM	; Enter PM using ESI = EPM struc
INIT_VCPI_PMINI2:
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	cli			; Some VCPI hosts (RM386 comes to mind)
				; start us off with IF=1
	lss	esp,PMSTK_FVEC	; Setup our stack
	assume	ss:nothing	; Tell the assembler about it

	xor	ax,ax		; A convenient zero
	mov	ds,ax		; Clear to avoid fault
	assume	ds:nothing	; Tell the assembler about it
	mov	es,ax		; Clear to avoid fault
	assume	es:nothing	; Tell the assembler about it
	mov	fs,ax		; Clear to avoid fault
	assume	fs:nothing	; Tell the assembler about it
	mov	gs,ax		; ...
	assume	gs:nothing	; Tell the assembler about it

; Setup common data in load module data area in extended memory

	mov	ax,DTE_LOAD+1*(type DESC_STR) ; Get SWAT's data selector
	mov	fs,ax		; Address the file's data segment
	assume	fs:DGROUP	; Tell the assembler about it

	mov	fs:[0].FILE_4GB,DTE_4GB ; Save descriptor
	mov	fs:[0].FINT_4GB,DTE_4GB ; ...
;;;;;;; mov	fs:[0].FILE_VID,DTE_VID ; ...
	mov	fs:[0].FILE_CR3,DTE_CR3 ; ...
	mov	fs:[0].FINT_CR3,DTE_CR3 ; ...

	mov	ax,DTE_LOAD	; Get PGROUP data selector
	mov	es,ax		; Address it
	assume	es:PGROUP	; Tell the assembler about it

; Call protected mode initialization code

	call	SWATINI.MD_IPROT ; Call it

; Re-specify PaTMPPAGE as it was set in INIT_PROT under the
; assumption that SWAT's code and data are physically contiguous.
; Because we may have allocated VCPI memory, we have no such
; assurances.

	mov	ax,DTE_4GB	; Get AGROUP data selector
	mov	ds,ax		; Address it
	assume	ds:AGROUP	; Tell the assembler about it

	mov	esi,BLCLPDIR	; Get its base address in DGROUP
	add	esi,LaDATA	; Plus linear address of DGROUP
	add	esi,4*1024-1	; Round up to 4KB boundary
	shr	esi,12-0	; Convert from bytes to 4KB

	movzx	ebx,SegPTE	; Get segment of PTEs (/4KB)
	shl	ebx,4-0 	; Convert from paras to bytes

	mov	eax,AGROUP:[ebx+esi*4+4] ; Get the PTE
	and	ax,mask $PTE_FRM ; Isolate the frame
	mov	PaTMPPAGE,eax	; Save for later use

	mov	ax,DTE_ES	; Get RGROUP data selector
	mov	es,ax		; Address it
	assume	es:RGROUP	; Tell the assembler about it

	cli			; Exit with IF=0

	mov	ax,(@VCPI shl 8) or @VCPI_EPM ; Get return function
	call	PMI_FVEC	; Request VCPI service
INIT_VCPI_VMRET2:
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing

	sti			; Enable interrupts

	STROUT	INIT_VCPI4

; Re-specify the SWAT stack into extended memory

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	LaSTK		; Get base address
	push	DTE_SS		; Get DTE
	push	((mask $DTE_B) shl 8) or CPL0_DATA ; Get A/R byte and flags
	call	SET_DEVGDT	; Set the GDT entry

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	LaSTK		; Get base address
	push	DTE_SSB0S	; Get DTE
	push	CPL0_DATA	; Get A/R byte and flags
	call	SET_DEVGDT	; Set the GDT entry

;;;;;;; PUSHD	0		; Get length of SWAT low memory
;;;;;;; push	LaSTK		; Get base address
;;;;;;; push	DTE_SSB0L	; Get DTE
;;;;;;; push	CPL0_DATA	; Get A/R byte and flags
;;;;;;; call	SET_DEVGDT	; Set the GDT entry
;;;;;;;
; Re-specify the RGROUP code selector as per COPYLOW

	xor	eax,eax 	; Zero to use as dword
	mov	ax,seg PGROUP	; Get PGROUP segment
	shl	eax,4-0 	; Convert from paras to bytes

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	eax		; Get base address
	push	DTE_CS		; Get DTE
	push	CPL0_CODE	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

; Re-specify the VCPI entry address

	mov	VCPEPM.VCPEPM_EXIT.FSEL,DTE_CS ; Save initial CS
	mov	VCPEPM.VCPEPM_EXIT.FOFF,offset RGROUP:EPM_VCPI_PMINI ; ... EIP
INIT_VCPI_INTRUDE2:

; If we allocated XMS memory for symbols, free it now

	mov	dx,SYM_XMSHNDL	; Get XMS memory handle

	cmp	dx,0		; Izit invalid?
	je	short INIT_VCPI_NOSYM2 ; Jump if so

	mov	ah,@XMS_UNLXMB	; Function code to unlock an XMB, DX=handle
	call	XMSDRV_VEC	; Request XMS service
				; Return with AX = 1 if successful
	cmp	ax,1		; Did it work?
	je	short @F	; Jump if so

	int	03h		; Call our debugger
@@:
	mov	ah,@XMS_RELXMB	; Function code to release an XMB, DX=handle
	call	XMSDRV_VEC	; Request XMS service
				; Return with AX = 1 if successful
	cmp	ax,1		; Did it work?
	je	short @F	; Jump if so

	int	03h		; Call our debugger
@@:
INIT_VCPI_NOSYM2:
	lea	dx,MSG_VCPISWAT ; Assume we're loading as VCPI SWAT
INIT_VCPI_CLC:
	test	DEV_FLAG,@DEV_INTRUDE ; Are we INTRUDEing today?
	jz	short @F	; Jump if not

	lea	dx,MSG_RUDESWAT ; We're loading as RUDE SWAT
	mov	PRTAIL,offset RGROUP:DEV_INTRZ ; Save new ending address
@@:
	DOSCALL @STROUT 	; Tell 'em what we're doing

	clc			; Mark as successful

	jmp	short INIT_VCPI_EXIT ; Join common exit code


INIT_VCPI_ERR:
	stc			; Indicate something went wrong
INIT_VCPI_EXIT:
	REGREST <es>		; Restore
	assume	es:nothing	; Tell the assembler about it
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_VCPI endp			; End INIT_VCPI procedure
	NPPROC	ALLOC_XMS -- Allocate XMS Memory
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Allocate XMS memory

On entry:

EDX	=	size in bytes to allocate

On exit:

EAX	=	base physical address
CX	=	XMS handle
CF	=	0 if all went well (although @DEV_XMS might be clear)
	=	1 otherwise

|

	REGSAVE <bx,edx,di,ds,es> ; Save registers

	mov	ax,seg RGROUP	; Get segment of RGROUP
	mov	ds,ax		; Address it
	assume	ds:RGROUP	; Tell the assembler about it

	mov	ax,seg NGROUP	; Get segment of NGROUP
	mov	es,ax		; Address it
	assume	es:NGROUP	; Tell the assembler about it

	mov	DDS.DDS_SIZE,edx ; Save in case we need VDS translation
	add	edx,1024-1	; Round up to 1KB boundary
	shr	edx,10-0	; Convert from bytes to 1KB

	mov	ah,@XMS_GETXMB	; Function code to allocate DX kilobytes
	call	XMSDRV_VEC	; Request XMS service
				; Return with AX = 1 if successful
				;	      DX = XMS handle
	cmp	ax,1		; Did it work?
	SETMSG	DRV,"Unable to allocate XMS memory."
	jne	short ALLOC_XMS_ERRXMS ; Jump if not

	mov	cx,dx		; Save to return as result

; Lock the memory to get its linear/physical address

	mov	ah,@XMS_LCKXMB	; Function code to lock an XMB, DX=handle
	call	XMSDRV_VEC	; Request XMS service
				; Return with AX = 1 if successful
				;	      DX:BX = 32-bit linear/physical addr
	cmp	ax,1		; Did it work?
	SETMSG	DRV,"Unable to lock XMS memory."
	jne	short ALLOC_XMS_ERRXMS0 ; Jump if not

	mov	ax,dx		; Copy high-order word
	shl	eax,16		; Shift to high-order word
	mov	ax,bx		; Copy low-order word

; If we're running under 386MAX or Memory Commander, translate
; the incoming address from linear to physical.

	test	DEV_FLAG,@DEV_VDS ; Do we need VDS translation?
	jz	short ALLOC_XMS_NOVDS ; Jump if not

	mov	DDS.DDS_FVEC.FOFF,eax ; Save as linear address

	mov	dx,@VDSF_XBUF	; Disable automatic buffer allocation
	lea	di,DDS		; ES:DI ==> DDS
	VDSCALL @VDS_LOCK	; Request VDS service
	jnc	short @F	; Jump if no error

	SETMSG	DRV,"VDS translation error."

	jmp	short ALLOC_XMS_ERRXMS ; Join common exit code


@@:
	mov	eax,DDS.DDS_POFF ; Get the physical address
ALLOC_XMS_NOVDS:
	mov	DRV_ERRMSG,@ERRMSG_NONE ; Mark as no error

	clc			; Indicate all went well

	jmp	short ALLOC_XMS_EXIT ; Join common exit code with EAX=addr


ALLOC_XMS_ERRXMS0:
	mov	ah,@XMS_RELXMB	; Function code to release an XMB, DX=handle
	call	XMSDRV_VEC	; Request XMS service
ALLOC_XMS_ERRXMS:
;;;;;;; and	DEV_FLAG,not @DEV_XMS ; Mark as not present

	stc			; Indicate something went wrong
ALLOC_XMS_EXIT:
	REGREST <es,ds,di,edx,bx> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ALLOC_XMS endp			; End ALLOC_XMS procedure
	NPPROC	CHECK_EXT -- Get Size of Extended Memory
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Get size of extended memory

|

	REGSAVE <eax,bx,cx,edx> ; Save registers

	test	DEV_FLAG,@DEV_VCPI ; Are we using VCPI services?
	jnz	short CHECK_EXT_EXIT ; Jump if so (no need for this info)

; See if COMPAQ/Phoenix/maybe others memory function works

	xor	cx,cx		; Set to known value
	xor	dx,dx		; ...
	mov	ax,0E801h	; Get function code to return extended memory
	int	15h		; Request BIOS service
				; Return AX = installed extmem in 1KB up to 16MB
				; ...	 BX = ..		 64KB above 16MB
				; ...	 CX = configured extmem in 1KB up to 16MB
				; ...	 DX = ..		 64KB above 16MB
	jcxz	@F		; Jump if not supported

	movzx	eax,cx		; Get extended memory up to 16MB in 1KB
	movzx	edx,dx		; Zero to use as dword
	shl	edx,16-10	; Convert from 64KB to 1KB
	add	eax,edx 	; Plus extmem up to 16MB

	jmp	short CHECK_EXT1 ; Join common code


@@:

; See if the AMI BIOS PCI Memory Function works

	mov	ax,0DA88h	; Get function code to return extended memory
	int	15h		; Request BIOS service
				; Return extended memory in CL:BX, AX=0
	cmp	ax,0		; Did it work?
	jne	short @F	; Jump if not

	mov	al,cl		; Copy the high-order byte (AH already zero)
	shl	eax,16		; Shift to high-order word
	mov	ax,bx		; Copy low-order word

	jmp	short CHECK_EXT1 ; Join common code


@@:
	mov	ah,88h		; Function code to get size of extended memory
	int	15h		; Request service, result in AX in 1KB blocks
	movzx	eax,ax		; Zero to use as dword
CHECK_EXT1:
	and	eax,not (4-1)	; Round down to a multiple of four

	add	eax,1024	; Plus first megabyte
	mov	PHYSIZE,eax	; Save as top of physical memory
CHECK_EXT_EXIT:
	REGREST <edx,cx,bx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_EXT endp			; End CHECK_EXT procedure
	NPPROC	DEV_ARGS -- Process Arguments, Call INIT_REAL
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Process arguments and call INIT_REAL.

On entry:

ES:BX	==>	Request header

On exit:

CF	=	0 if all went well
	=	1 otherwise

|

	pushad			; Save all EGP registers
	REGSAVE <ds,es> 	; Save registers

COMMENT|

Setup registers for INIT_REAL call

DS:DX	==>	"d:\path\filename.ext [arguments]",0
DS:SI	==>	"[arguments]",0

|

	lds	si,es:[bx].INIT_CMD_VEC ; Get address of command line args
	assume	ds:nothing	; Tell the assembler about it

	mov	dx,si		; DS:DX ==> start of line

	push	seg NGROUP	; Get our segment
	pop	es		; Address it
	assume	es:NGROUP	; Tell the assembler about it

	mov	DRVPATH_VEC.VOFF,si ; Save for later use
	mov	DRVPATH_VEC.VSEG,ds ; ...

; Skip to [arguments] if any

DEV_ARGS_FILE:			; Initial scan to skip over file name
	lods	ds:[si].LO	; Get the next byte

	cmp	al,CR		; If CR, then no arguments
	je	short DEV_ARGS_DEF ; Use defaults

	cmp	al,LF		; If LF, then no arguments
	jne	short @F	; Jump if not
DEV_ARGS_DEF:
	dec	si		; Back off to terminator

	jmp	short DEV_ARGS_SRCH ; Join common search code


@@:
	cmp	al,' '          ; If white space, then we've reached the end
	je	short DEV_ARGS_SRCH ; Yup

	cmp	al,TAB		; If white space, then we've reached the end
	je	short DEV_ARGS_SRCH ; Yup

	and	al,al		; If zero, we've reached the end
	jnz	short DEV_ARGS_FILE ; Not as yet
DEV_ARGS_SRCH:			; Search for arguments
	lea	bx,[si-1]	; Copy offset of filename terminator
	mov	DRVPATH_END,bx	; Save for later use

	call	SKIP_WHITE	; Skip over white space

	push	si		; Save start of args for a moment

; Skip to end of the argument list to plant a terminating zero

DEV_ARGS_TERM:
	lods	ds:[si].LO	; Get the next byte

	cmp	al,CR		; If CR, then end of arguments
	je	short @F	; Jump if so

	cmp	al,LF		; If LF, then end of arguments
	je	short @F	; Jump if so

	and	al,al		; If zero, we've reached the end
	jnz	short DEV_ARGS_TERM ; Not as yet
@@:
	lea	di,[si-1]	; Save ending offset in index register

	pop	si		; Restore starting argument offset

; Set flags for XT or MCA if necessary

	test	DEV_FLAG,@DEV_XT ; Izit an XT?
	jz	short @F	; Not this time

	or	SWATINI.MD_ATTR,@MD_XT ; Mark as an XT
@@:
	test	DEV_FLAG,@DEV_MCA ; Izit an MCA-compatible machine?
	jz	short @F	; Not this time

	or	SWATINI.MD_ATTR,@MD_MCA ; Mark as an MCA-compatible
@@:

; Tell the load module that we support APIVER features if it does

	test	SWATINI.MD_ATTR,@MD_VER ; Duzit?
	jz	short @F	; Jump if not

	mov	SWATINI.MD_MAXVER,01h ; Tell 'em
@@:

; Tell the load module we support MD_VSIZE if it does

	or	SWATINI.MD_ATTR,@MD_VSIZE ; Tell 'em

; Initialize real mode

	mov	cx,0		; Terminators
	xchg	cl,ds:[bx]	; Swap 'em
	xchg	ch,ds:[di]	; Swap 'em
	call	SWATINI.MD_IREAL ; Call INIT_REAL
	xchg	ch,ds:[di]	; Restore
	xchg	cl,ds:[bx]	; Restore

	test	SWATINI.MD_ATTR,@MD_RMIE ; Test for real mode initialization error
	jnz	near ptr DEV_ARGS_ERR ; Jump if something went wrong

	mov	eax,SWATINI.MD_SIZE ; Get the initialization size in bytes
	add	eax,16-1	; Round up to para boundary
	and	ax,not (16-1)	; and down again
	mov	SWAT_TSIZ,eax	; Save for later use
	mov	SWAT_ISIZ,eax	; ...

	mov	eax,SWATINI.MD_USIZE ; Get byte size of uninitialized data
	add	eax,16-1	; Round up to para boundary
	and	ax,not (16-1)	; and down again
	add	SWAT_TSIZ,eax	; Add into accumulated load count
	mov	SWAT_USIZ,eax	; Save as uninitialized data size

	mov	eax,SWATINI.MD_DATA ; Read in the data segment offset
	mov	SWAT_DAT,eax	; Save for later use

; Transfer flags from the main engine to local data area

	mov	ax,seg DGROUP	; Get segment of ARG_FLAG
	mov	ds,ax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	test	ARG_FLAG,@ARG_DIVO ; Initialize INT 00h?
	jz	short @F	; Jump if not

	or	TRP_FLAG,@TRP_I00 ; Mark as trapping
@@:
	test	ARG_FLAG,@ARG_STEP ; Initialize INT 01h?
	jz	short @F	; Jump if not

	or	TRP_FLAG,@TRP_I01 ; Mark as trapping
@@:
	test	ARG_FLAG,@ARG_NMI ; Initialize INT 02h?
	jz	short @F	; Jump if not

	or	TRP_FLAG,@TRP_I02 ; Mark as trapping
@@:
	test	ARG_FLAG,@ARG_SKIP ; Initialize INT 03h?
	jz	short @F	; Jump if not

	or	TRP_FLAG,@TRP_I03 ; Mark as trapping
@@:
	test	ARG_FLAG,@ARG_BOUND ; Initialize INT 05h?
	jz	short @F	; Jump if not

	or	TRP_FLAG,@TRP_I05 ; Mark as trapping
@@:
	test	ARG_FLAG,@ARG_INV ; Initialize INT 06h?
	jz	short @F	; Jump if not

	or	TRP_FLAG,@TRP_I06 ; Mark as trapping
@@:
	test	AR2_FLAG,@AR2_TSS ; Check state
	jz	short @F	; Jump if not

	or	TRP_FLAG,@TRP_I0A ; Mark as trapping
@@:
	test	AR2_FLAG,@AR2_STACK ; Check state
	jz	short @F	; Jump if not

	or	TRP_FLAG,@TRP_I0C ; Mark as trapping
@@:
	test	ARG_FLAG,@ARG_GENP ; Check state
	jz	short @F	; Jump if not

	or	TRP_FLAG,@TRP_I0D ; Mark as trapping
@@:
	clc			; Indicate all went well

	jmp	short DEV_ARGS_EXIT ; Join common exit code


DEV_ARGS_ERR:
	stc			; Indicate something went wrong
DEV_ARGS_EXIT:
	REGREST <es,ds> 	; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it
	popad			; Save all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEV_ARGS endp			; End DEV_ARGS procedure
	NPPROC	LOADUP -- Copy LOD Module To Extended Memory
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Copy a load module to extended memory
In each case, the data map is LaCODE, LaDATA, LaIDT, LaSTK, LaTSS.

1. If we're not using VCPI w/o XMS manager, use BIOS block move.
2. If we're not using VCPI w/XMS manager, allocate XMS memory,
   and use XMS block move.

On entry:

CF	=	0 if all went well
	=	1 otherwise

|

	REGSAVE <eax,ebx,ecx,edx,si,es> ; Save registers

	test	DEV_FLAG,@DEV_VCPI ; Are we using VCPI services?
	jnz	near ptr LOADUP_EXIT ; Jump if so (already done) (note CF=0)

	push	seg NGROUP	; Get our segment
	pop	es		; Address it
	assume	es:NGROUP	; Tell the assembler about it

	mov	SWATINI.MD_IPROT.FSEL,DTE_LOAD ; Save for protected mode init
	mov	SWATINI.MD_RPROT.FSEL,DTE_LOAD ; ...			  restore

	test	DEV_FLAG,@DEV_XMS ; Is there an XMS driver present?
	jnz	near ptr LOADUP_XMS ; Jump if so

	mov	edx,PHYSIZE	; Use current physical size
	shl	edx,10-0	; Convert from 1KB to bytes
	mov	LaEND,edx	; Save as ending linear/physical address

	sub	edx,size TSS_STR ; Less size of TSS
	jb	near ptr LOADUP_ERR0 ; Jump if too small

	mov	LaTSS,edx	; Save as linear/physical address of TSS

	sub	edx,SWATSTK_FVEC.FOFF ; Less size of stack
	jb	near ptr LOADUP_ERR0 ; Jump if too small

	mov	LaSTK,edx	; Save as linear/physical address of stack

	sub	edx,256*(type IDT_STR) ; Less size of IDT
	jb	near ptr LOADUP_ERR0 ; Jump if too small

	mov	LaIDT,edx	; Save as linear/physical address of IDT

	sub	edx,SWAT_TSIZ	; Less size of PM-resident data
	jb	near ptr LOADUP_ERR0 ; Jump if too small

	and	edx,not (1024-1) ; Round down to 1KB boundary
	mov	LaCODE,edx	; Save linear/physical address of code

	cmp	edx,1024*1024	; Izit too small?
	jb	near ptr LOADUP_ERR0 ; Jump if too small

	mov	SWATINI.MD_PHYS,edx ; Save physical address of code segment

	add	edx,SWAT_DAT	; Plus size of data segment
	mov	LaDATA,edx	; Save linear/physical address of data

; Calculate DTE limit

	mov	ecx,SWAT_ISIZ	; Get size of initialized code/data
	mov	ebx,ecx 	; Copy to save in DTEs

	dec	ebx		; Convert from length to limit

	cmp	ebx,1024*1024	; Check against limit limit
	jb	short @F	; Jump if within range

	shr	ebx,12-0	; Convert from bytes to 4KB
	or	ebx,(mask $DTE_G) shl (8*(DESC_SEGLM1-DESC_BASE2)) ; Set G-bit
@@:

; Save DTE for source and destination limits

	mov	MOVE_TAB.MDTE_DS.DESC_SEGLM0,bx ; Save as data limit
	mov	MOVE_TAB.MDTE_ES.DESC_SEGLM0,bx ; ...
	rol	ebx,16		; Swap high- and low-order words
	mov	MOVE_TAB.MDTE_DS.DESC_SEGLM1,bl ; Save size & flags
	mov	MOVE_TAB.MDTE_ES.DESC_SEGLM1,bl ; ...
;;;;;;; ror	ebx,16		; Swap back

	xor	ebx,ebx 	; Zero to use as dword
	mov	bx,seg PGROUP	; Get segment of module in low DOS
	shl	ebx,4-0 	; Convert from paras to bytes

	mov	edx,SWATINI.MD_PHYS ; Get physical address of code segment
LOADUP_NEXT:

; Save DTE for source base and A/R

	mov	MOVE_TAB.MDTE_DS.DESC_BASE01.EDD,ebx
	rol	ebx,8		; Rotate out the high-order byte
	mov	MOVE_TAB.MDTE_DS.DESC_BASE3,bl ; Save as base byte #3
	ror	ebx,8		; Rotate back
	mov	MOVE_TAB.MDTE_DS.DESC_ACCESS,CPL0_DATA

; Save DTE for destination base and A/R

	mov	MOVE_TAB.MDTE_ES.DESC_BASE01.EDD,edx
	rol	edx,8		; Rotate out the high-order byte
	mov	MOVE_TAB.MDTE_ES.DESC_BASE3,dl ; Save as base byte #3
	ror	edx,8		; Rotate back
	mov	MOVE_TAB.MDTE_ES.DESC_ACCESS,CPL0_DATA

	REGSAVE <ebx,ecx,edx,fs,gs> ; Save because you can never tell
				; what a BIOS might clobber

; Set move length as smaller of actual length
; and the maximum move length (64KB).

	cmp	ecx,64*1024	; Izit too big?
	jbe	short @F	; Jump if not

	mov	ecx,64*1024	; Use smaller
@@:
	shr	ecx,1-0 	; Convert from bytes to words

	lea	si,MOVE_TAB	; ES:SI ==> GDT
	mov	ah,87h		; Function code to BIOS block move
	int	15h		; Request BIOS service

	REGREST <gs,fs,edx,ecx,ebx> ; Restore

	cmp	ah,0		; Did it work?
	jne	near ptr LOADUP_ERR ; Jump if not

	mov	eax,64*1024	; Get maximum length moved

	add	ebx,eax 	; Skip to next source base
	add	edx,eax 	; ...	       destin ...

	sub	ecx,eax 	; Less length
	ja	short LOADUP_NEXT ; Jump if there's more to do

	clc			; Indicate all went well

	jmp	LOADUP_EXIT	; Join common exit code


; XMS driver present:  use its memory to copy code/data to extended memory

LOADUP_XMS:

; Calculate how many 1KB blocks we need to allocate

	mov	edx,SWAT_ISIZ	; Get size of initialized code/data
	mov	XMBMOVE.XMBMOVE_LEN,edx ; Save as move length

	add	edx,SWAT_USIZ	; Plus size of uninitialized data
	add	edx,SWAT_XTRA	; Plus size of extra data
	call	ALLOC_XMS	; Allocate EDX bytes of XMS memory
				; returning EAX = base physical address
				;	    CX = handle
	jc	near ptr LOADUP_ERR0 ; Jump if something went wrong

	mov	XMSHNDL,cx	; Save for later use
	mov	SWATINI.MD_PHYS,eax ; Save physical address of code segment
	mov	LaCODE,eax	; Save linear address of image

	add	eax,SWAT_DAT	; Plus offset to data segment
	mov	LaDATA,eax	; Save as linear address of our data

	mov	eax,LaCODE	; Get linear address of our code
	add	eax,SWAT_TSIZ	; Plus size of PM-resident data
	mov	LaIDT,eax	; Save as linear address of IDT

	add	eax,256*(type IDT_STR) ; Plus size of IDT
	mov	LaSTK,eax	; Save as linear address of stack

	add	eax,SWATSTK_FVEC.FOFF ; Plus size of stack
	mov	LaTSS,eax	; Save as linear address of TSS

	add	eax,size TSS_STR ; Plus size of TSS
	mov	LaEND,eax	; Save as ending linear address

	test	DEV_FLAG,@DEV_XMS ; Did we fail trying XMS?
	jz	short LOADUP_ERR0 ; Jump if so

; Move data to XMS memory

	mov	XMBMOVE.XMBMOVE_SHNDL,0 ; Save as source handle
				; meaning it's in the first megabyte
	mov	XMBMOVE.XMBMOVE_SOFF.VOFF,0 ; Save as source offset
	mov	XMBMOVE.XMBMOVE_SOFF.VSEG,seg PGROUP ; ...   segment

	mov	dx,XMSHNDL	; Get XMS handle #
	mov	XMBMOVE.XMBMOVE_DHNDL,dx ; Save as destin handle
	mov	XMBMOVE.XMBMOVE_DOFF,0 ; ...		   offset

	lea	si,XMBMOVE	; DS:SI ==> XMS block move struc
	mov	ah,@XMS_MOVXMB	; Function code for block move using DS:SI
	call	XMSDRV_VEC	; Request XMS service
				; Return with AX = 1 if successful
	cmp	ax,1		; Did it work?
	je	short LOADUP_EXIT ; Jump if so (note CF=0)

; An error occurred using XMS services; unlock and release the memory

LOADUP_ERRXMS:
	mov	ah,@XMS_UNLXMB	; Function code to unlock an XMB, DX=handle
	call	XMSDRV_VEC	; Request XMS service
				; Return with AX = 1 if successful
	cmp	ax,1		; Did it work?
	je	short @F	; Jump if so

	int	03h		; Call our debugger
@@:
	mov	ah,@XMS_RELXMB	; Function code to release an XMB, DX=handle
	call	XMSDRV_VEC	; Request XMS service
				; Return with AX = 1 if successful
	cmp	ax,1		; Did it work?
	je	short @F	; Jump if so

	int	03h		; Call our debugger
@@:
LOADUP_ERR0:
	SETMSG	DRV,"Insufficient extended memory to load."
LOADUP_ERR:
	stc			; Indicate the move failed
LOADUP_EXIT:
	REGREST <es,si,edx,ecx,ebx,eax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOADUP	endp			; End LOADUP procedure
	NPPROC	KEYWAIT -- Wait For Keyboard Acknowledgement
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Purge the keyboard buffer and wait for a key press -- discard the key

On exit:

AX	=	last key pressed

|

KEYWAIT_NEXT:
	KEYCALL @GETKST 	; Get buffer state
	jz	short KEYWAIT_PAUSE ; Nothing available

	KEYCALL @GETKEY 	; Get the key

	jmp	KEYWAIT_NEXT	; Go around again


KEYWAIT_PAUSE:
	KEYCALL @GETKEY 	; Get the key

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

KEYWAIT endp			; End KEYWAIT procedure
	NPPROC	OUTCMOS -- Out To CMOS, Conditional Read
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Out to CMOS, conditional read.

Note that this routine is bimodal.

This routine should not be interrupted between the OUT and IN.

|

	pushf			; Save flags
	cli			; Disallow interrupts

	out	dx,al		; Send to CMOS

	cmp	dx,@CMOS_CMD	; Izit an AT?
	jne	short @F	; Jump if not

	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay

	in	al,@CMOS_DATA	; Ensure OUT is followed by IN
@@:
	popf			; Restore flags

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OUTCMOS endp			; End OUTCMOS procedure
	NPPROC	CHECK_MODEL -- Check for MCA-Compatible Machines
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Check for MCA-compatible, EISA, and a whole bunch more machines.

|

	REGSAVE <ax,bx,cx,dx,di,es> ; Save registers

	push	seg CGROUP	; Get ROM BIOS segment
	pop	es		; Address via segment register
	assume	es:CGROUP	; Tell the assembler about it

	mov	al,BIOSCPUID	; Get the machine ID byte
	mov	MACHID,al	; Save for later use

	test	DEV_FLAG,@DEV_XMS ; Are there XMS services present?
	jnz	near ptr CHECK_MODEL_EXIT ; Jump if so

; Check on using I/O port 92h for toggling A20

	mov	ax,@A20_SUP	; A20 function, Query A20 gate support
	int	15h		; Request BIOS service

	cmp	ah,0		; Did it succeed?
	jne	short @F	; Jump if not

	mov	A20SUP,bx	; Save for later use
	or	DEV_FLAG,@DEV_A20FN ; Mark as services present

	test	bx,mask $A20_I92 ; Duzit use I/O port 92h to toggle A20?
	jz	short @F	; Jump if not

	mov	ACTA20_COMSUB,offset RGROUP:A20COM_I92 ; Save routine addr
@@:

; If this BIOS doesn't support A20 Architecture functions,
; check for I/O port 78h or 92h gating of A20

	test	DEV_FLAG,@DEV_A20FN ; Are A20 Architecture services present?
	jnz	short @F	; Jump if so

	smsw	ax		; Get MSW

	test	ax,mask $PE	; Are we in VM?
	jnz	short @F	; Skip this (especially CHECK_I92
				; as it can reboot the system)
	call	CHECK_I78	; Check for I/O port 78h toggle of A20
	call	CHECK_I92	; Check for I/O port 92h A20 gating
@@:

; Save pointer to BIOS configuration data (if supported)

	push	es		; Save for a moment

	mov	ah,0C0h 	; Attempt to read configuration record
	stc			; Assume failure
	int	15h		; Request BIOS service
	assume	es:nothing	; Tell the assembler about it
	jc	short @F	; Jump if error

	cmp	ah,80h		; Check for error return
	je	short @F	; Jump if error

	cmp	ah,86h		; Check for error return
	je	short @F	; Jump if error

	mov	BIOSCONF_VEC.VOFF,bx ; Save for later use
	mov	BIOSCONF_VEC.VSEG,es ; ...
@@:
	pop	es		; Restore
	assume	es:CGROUP	; Tell the assembler about it

; Check for EISA signature at F000:FFD9

; Some early EISA machines don't follow the spec, they put their
; signature somewhere else in the BIOS.  However, we can't search
; through the entire BIOS, because many ISA machines have EISA
; strings that we would pick up as false positives.

	cmp	dword ptr EISASIGN,'ASIE' ; Check for EISA signature
	jne	short CHECK_MODEL_XEISA ; Jump if not EISA machine

	or	DEV_FLAG,@DEV_EISA ; Mark as present (EISA machine)

	jmp	CHECK_MODEL_EXIT ; Join common code


CHECK_MODEL_XEISA:

; Check for MCA-compatible machines

	cmp	BIOSCONF_VEC.VSEG,0 ; Izit valid?
	je	short CHECK_MODEL_XMCA; Jump if not

	les	bx,BIOSCONF_VEC ; ES:BX ==> BIOS configuration data
	assume	es:nothing	; Tell the assembler about it

	test	es:[bx].CFG_PARMS,@CFG_MCA ; Izit a Micro Channel Architecture?
	jz	short CHECK_MODEL_XMCA ; Not this time

	or	DEV_FLAG,@DEV_MCA ; Mark as an MCA-compatible machine
	mov	ACTA20_COMSUB,offset RGROUP:A20COM_I92 ; Save routine addr

	test	DEV_FLAG,@DEV_A20FN ; A20 services present?
	jnz	short @F	; Jump if so

	mov	A20SUP,mask $A20_I92 ; Mark as A20 support value
@@:
	jmp	short CHECK_MODEL_EXIT ; Join common exit code


	assume	es:nothing	; Tell the assembler about it

CHECK_MODEL_XMCA:
	mov	al,MACHID	; Restore machine ID

	cmp	al,@CPU_MCA	; Check for other MCA (128KB BIOS?)
	je	short CHECK_MODEL_EXIT ; Jump if present

	cmp	al,@CPU_AT	; Izit a 286 processor?
	je	short CHECK_MODEL_EXIT ; Jump if so

	cmp	al,@CPU_PC	; Check for PC
	je	short CHECK_MODEL_PCXT ; Jump if present

	cmp	al,@CPU_XT	; Check for XT
	je	short CHECK_MODEL_PCXT ; Jump if present

	cmp	al,@CPU_XT2	; Check for XT2
	je	short CHECK_MODEL_PCXT ; Jump if present

	cmp	al,@CPU_M30	; Check for PS/2 Model 30
	je	short CHECK_MODEL_PCXT ; Jump if present

	cmp	al,@CPU_CNV	; Check for Convertible
	je	short CHECK_MODEL_PCXT ; Jump if present

	cmp	al,@CPU_JR	; Check for Jr
	jne	short CHECK_MODEL_EXIT ; Jump if not
CHECK_MODEL_PCXT:
	call	MARK_XT 	; Mark as PC/XT present
CHECK_MODEL_EXIT:
	REGREST <es,di,dx,cx,bx,ax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_MODEL endp		; End CHECK_MODEL procedure
	NPPROC	MARK_XT -- Mark as PC/XT Present
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Mark as PC/XT present.

|

	or	DEV_FLAG,@DEV_XT ; Mark as PC/XT present
	mov	ACTA20_COMSUB,offset RGROUP:A20COM_XT ; Save routine addr

	mov	DEVNMIPORT,0A0h   ; NMI clear I/O port
	mov	DEVNMIENA,80h	   ; ... enable value
	mov	DEVNMIDIS,00h	   ; ... disable value
	mov	DEVNMIMASK,mask $XTPAR ; ... clear mask

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MARK_XT endp			; End MARK_XT procedure
	NPPROC	INIT_GDT -- Initialize The GDT
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Initialize SWAT's GDT

|

	pushad			; Save all EGP registers

	movzx	eax,PSWATGDT.VSEG ; Get segment of SWATGDT
	movzx	ebx,PSWATGDT.VOFF ; ... offset ...
	shl	eax,4-0 	; Convert from paras to bytes
	add	eax,ebx 	; Add to get 32-bit linear address
	mov	SWATGDTR.DTR_BASE,eax ; Save for later use
	mov	SWATGDTR.DTR_LIM,(size XDTE_STR)-1 ; ...

	xor	eax,eax 	; Zero to use as dword
	mov	ax,cs		; Get current code segment
	shl	eax,4-0 	; Convert from paras to bytes

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	eax		; Get base address
	push	DTE_CS		; Get DTE
	push	CPL0_CODE	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

	PUSHD	0		; Get length of 4GB segment
	push	eax		; Get base address
	push	DTE_CS4GB	; Get DTE
	push	CPL0_CODE	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

	xor	eax,eax 	; Zero to use as dword
	mov	ax,seg PGROUP	; Get PGROUP segment
	shl	eax,4-0 	; Convert from paras to bytes

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	eax		; Get base address
	push	DTE_DS		; Get DTE
	push	CPL0_DATA	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

	movzx	eax,RGRSEG1	; Get RGROUP segment
	shl	eax,4-0 	; Convert from paras to bytes

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	eax		; Get base address
	push	DTE_CSR 	; Get DTE
	push	CPL0_CODE	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	eax		; Get base address
	push	DTE_ES		; Get DTE
	push	CPL0_DATA	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

	xor	eax,eax 	; Zero to use as dword
	mov	ax,ss		; Get current stack segment
	shl	eax,4-0 	; Convert from paras to bytes

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	eax		; Get base address
	push	DTE_SS		; Get DTE
	push	((mask $DTE_B) shl 8) or CPL0_DATA ; Get A/R byte and flags
	call	SET_DEVGDT	; Set the GDT entry

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	eax		; Get base address
	push	DTE_SSB0S	; Get DTE
	push	CPL0_DATA	; Get A/R byte and flags
	call	SET_DEVGDT	; Set the GDT entry

	PUSHD	0		; Get length of SWAT low memory
	push	eax		; Get base address
	push	DTE_SSB0L	; Get DTE
	push	CPL0_DATA	; Get A/R byte and flags
	call	SET_DEVGDT	; Set the GDT entry

	test	DEV_FLAG,@DEV_INTRUDE ; Are we INTRUDEing today?
	jz	short @F	; Jump if not

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	eax		; Get base address
	push	DTE_RUDSS1	; Get DTE
	push	((mask $DTE_B) shl 8) or CPL0_DATA or CPL1 ; Get A/R byte and flags
	call	SET_DEVGDT	; Set the GDT entry
@@:
	mov	eax,OffCR3	; Get offset of CR3 temp PTE
	shl	eax,(12-2)-0	; Convert from 4KB in dwords to bytes

	push	dword ptr (4*1024) ; Get length of 4KB page
	push	eax		; Get base address
	push	DTE_CR3 	; Get DTE
	push	CPL0_DATA	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

	PUSHD	0		; Get length of all memory selector
	PUSHD	0		; Get base address
	push	DTE_4GB 	; Get DTE
	push	((mask $DTE_B) shl 8) or CPL0_DATA ; Get A/R byte and flags
	call	SET_DEVGDT	; Set the GDT entry

; Setup DTE_LOAD entries

	mov	ecx,SWAT_TSIZ	; Get length of SWAT
	mov	ebx,LaCODE	; Get base address
	mov	dx,DTE_LOAD	; Get DTE for code

	push	ecx		; Get length of SWAT code and aata
	push	ebx		; Get base address
	push	dx		; Get DTE
	push	((mask $DTE_B) shl 8) or CPL0_CODE ; Get A/R byte and flags
	call	SET_DEVGDT	; Set the GDT entry

	add	ebx,SWAT_DAT	; Skip to data
	sub	ecx,SWAT_DAT	; Less its length
	add	dx,type DESC_STR ; Skip to next entry:	DTE_LOAD+1*(size DESC_STR)

	push	ecx		; Get length of SWAT data
	push	ebx		; Get base address
	push	dx		; Get DTE
	push	CPL0_DATA	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

	add	dx,type DESC_STR ; Skip to next entry:	DTE_LOAD+2*(size DESC_STR)

	xor	eax,eax 	; Zero to use as dword
	mov	ax,seg RGROUP	; Get PGROUP segment
	shl	eax,4-0 	; Convert from paras to bytes

	push	dword ptr (size SWATLDT) ; Get length of LDT
	lea	edi,SWATLDT[eax] ; Plus offset of LDT
	push	edi		; Pass base address
	push	dx		; Get DTE
	push	CPL0_LDT	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

	push	dword ptr (size SWATLDT) ; Get length of LDT
;;;;;;; lea	edi,SWATLDT[eax] ; Plus offset of LDT
	push	edi		; Pass base address
	push	DTE_LDTCS	; Get DTE
	push	CPL0_LDT	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

	push	dword ptr (size SWATLDT) ; Get length of LDT
;;;;;;; lea	edi,SWATLDT[eax] ; Plus offset of LDT
	push	edi		; Pass base address
	push	DTE_LDTCSR	; Get DTE
	push	CPL0_LDT	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

	push	dword ptr (size SWATLDT) ; Get length of LDT
;;;;;;; lea	edi,SWATLDT[eax] ; Plus offset of LDT
	push	edi		; Pass base address
	push	DTE_LDTCS4GB	; Get DTE
	push	CPL0_LDT	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

; Setup LDT entries

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	eax		; Get base address
	push	LDTE_CS 	; Get LDTE
	push	CPL0_CODE	; Get A/R byte
	call	SET_DEVGDT	; Set the LDT entry

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	eax		; Get base address
	push	LDTE_DS 	; Get LDTE
	push	CPL0_DATA	; Get A/R byte
	call	SET_DEVGDT	; Set the LDT entry

	PUSHD	0		; Get length of 4GB segment
	push	eax		; Get base address
	push	LDTE_CS4GB	; Get DTE
	push	CPL0_CODE	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

	PUSHD	0		; Get length of all memory selector
	PUSHD	0		; Get base address
	push	LDTE_4GB	; Get DTE
	push	((mask $DTE_B) shl 8) or CPL0_DATA ; Get A/R byte and flags
	call	SET_DEVGDT	; Set the GDT entry

	xor	eax,eax 	; Zero to use as dword
	mov	ax,ss		; Get current stack segment
	shl	eax,4-0 	; Convert from paras to bytes

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	eax		; Get base address
	push	LDTE_SSB0S	; Get DTE
	push	CPL0_DATA	; Get A/R byte and flags
	call	SET_DEVGDT	; Set the GDT entry

	PUSHD	0		; Get length of SWAT low memory
	push	eax		; Get base address
	push	LDTE_SSB0L	; Get DTE
	push	CPL0_DATA	; Get A/R byte and flags
	call	SET_DEVGDT	; Set the GDT entry







; Setup TSS descriptor

	push	dword ptr (size TSS_STR) ; Get length of TSS data
	push	LaTSS		; Get base address
	push	DTE_TSS 	; Get DTE
	push	CPL0_IDLE3	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

; Setup temporary IDT

	push	es		; Save for a moment

	mov	ax,MAPSEG_NXT	; Get next available segment
	mov	SegIDT,ax	; Save for later use
	mov	es,ax		; Address it
	assume	es:nothing	; Tell the assembler about it

	add	MAPSEG_NXT,(256*(type IDT_STR))/16 ; Protect the IDT

	push	offset NGROUP:MEMERR_IDT ; Pass offset of error message
	call	CHECK_NXTSEG	; Ensure we've enough room

; Zero the IDT table

	xor	eax,eax 	; A convenient zero
	mov	cx,(256*(type IDT_STR))/4 ; Get # dwords in IDT
	xor	di,di		; Start at the beginning of the segment
    rep stos	es:[di].EDD	; Zero the IDT

	pop	es		; Restore
	assume	es:nothing	; Tell the assembler about it

; If there's a preceding copy of device SWAT running, install it
; in our PM GDT/IDT

	call	INIT_PSWAT	; Initialize it

	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_GDT endp			; End INIT_GDT procedure
	NPPROC	PROT_INIT -- Initialize Protected Mode
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Initialize protected mode

On exit:

CF	=	0 if all went well
	=	1 otherwise

|

	pushad			; Save all EGP registers

	test	DEV_FLAG,@DEV_VCPI ; Are we using VCPI services?
	jnz	near ptr PROT_INIT_EXIT ; Jump if so (note CF=0)

	mov	eax,LaIDT	; Get linear address of IDT
	mov	SWATIDTR.DTR_BASE,eax	; Save for later use
	mov	SWATIDTR.DTR_LIM,(type IDT_STR)*256-1 ; ...

	mov	eax,LaCODE	; Get linear address of SWAT start
	shr	eax,10-0	; Convert from bytes to 1KB (rounding down)
	sub	eax,1024	; Less first megabyte
	mov	DEVEXTSIZE,eax	; Save for our INT 15h handler

; Setup the GDT

	call	INIT_GDT	; Initialize it

	mov	RMSTK_FVEC.FSEL,ss  ; Save to restore later
	mov	RMSTK_FVEC.FOFF,esp ; ...

; Save the current state of A20 in DEV_FLAG to restore later

	or	DEV_FLAG,@DEV_A20ON ; Assume A20 enabled upon entry

	call	FCHECKA20	; Izit enabled?
	jc	short @F	; Jump if so

	and	DEV_FLAG,not @DEV_A20ON ; Mark as A20 not enabled upon entry
@@:
	REGSAVE <ds,es,fs,gs>	; Save registers

	mov	es,RGRSEG1	; Get segment of SWATGDT
	assume	es:RGROUP	; Tell the assembler about it

	lea	si,SWATGDT	; ES:SI ==> GDT to use

	STROUT	GOPROT
	call	GOPROT		; Enter PM
	assume	ds:PGROUP,es:RGROUP   ; Tell the assembler about it
	assume	fs:nothing,gs:nothing ; Tell the assembler about it

; Re-specify the GDTR and IDTR in case the BIOS loaded the
; 24-bit address only.

	LGDTD	SWATGDTR	; Point GDTR to low memory
	LIDTD	SWATIDTR	; ...	IDTR to extended memory

	push	es		; Save for a moment

	mov	ax,DTE_4GB	; Get AGROUP data selector
	mov	es,ax		; Address it
	assume	es:AGROUP	; Tell the assembler about it

; Copy the dummy IDT to extended memory

	movzx	esi,SegIDT	; Get segment of low memory IDT
	shl	esi,4-0 	; Convert from paras to bytes
	mov	edi,LaIDT	; Get destination IDT
	mov	ecx,(256*(type IDT_STR))/4 ; Get # dwords in IDT
S32 rep movs	<AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy IDT to extended mem

; Initialize the TSS

	mov	edi,LaTSS	; ES:EDI ==> TSS
	mov	AGROUP:[edi].TSS_LDT,DTE_LDTCS ; LDT

	pop	es		; Restore
	assume	es:RGROUP	; Tell the assembler about it

; Handle preceding SWAT issues if present

	test	DEVLOAD,@DEVL_PSWAT ; Izit present?
	jz	short PROT_INIT_NOPSWAT ; Jump if not

; Zero the TSS

	push	es		; Save for a moment

	mov	ax,DTE_4GB	; Get AGROUP data selector
	mov	es,ax		; Address it
	assume	es:AGROUP	; Tell the assembler about it

	mov	edi,LaTSS	; ES:EDI ==> TSS
	xor	eax,eax 	; A convenient zero
	mov	ecx,(size TSS_STR)/4 ; Get # dwords in TSS
    rep stos	AGROUP:[edi].EDD ; Zero it

	mov	edi,LaTSS	; ES:EDI ==> TSS
	mov	AGROUP:[edi].TSS_LDT,DTE_LDTCS ; LDT

	pop	es		; Restore
	assume	es:RGROUP	; Tell the assembler about it

	mov	ax,DTE_TSS	; Get TSS selector
	ltr	ax		; Put it into effect

	int	01h		; Call our debugger
PROT_INIT_NOPSWAT:

; Setup common data in load module data area

	mov	ax,DTE_LOAD+1*(type DESC_STR) ; Get SWAT's data selector
	mov	fs,ax		; Address the file's data segment
	assume	fs:nothing	; Tell the assembler about it

	mov	fs:[0].FILE_4GB,DTE_4GB ; Save descriptor
	mov	fs:[0].FINT_4GB,DTE_4GB ; ...
;;;;;;; mov	fs:[0].FILE_VID,DTE_VID ; ...
;;;;;;; mov	fs:[0].FILE_CR3,DTE_CR3 ; ...
;;;;;;; mov	fs:[0].FINT_CR3,DTE_CR3 ; ...

; Call protected mode initialization code

	call	SWATINI.MD_IPROT ; Call it

	FICALL	RGROUP:FGOREAL,DTE_CSR,<seg NGROUP> ; Enter RM
;;;;;;; FICALL	RGROUP:GOREAL,DTE_CSR,<seg NGROUP> ; Enter RM
	assume	ds:RGROUP,es:RGROUP ; Tell the assembler about it
	assume	fs:PGROUP,gs:PGROUP ; Tell the assembler about it

; Reset segment registers

	REGREST <gs,fs,es,ds>	; Restore
	assume	ds:NGROUP,es:nothing ; Tell the assembler about it
	assume	fs:PGROUP,gs:RGROUP ; Tell the assembler about it

	lss	esp,RMSTK_FVEC	; Re-specify the stack
	assume	ss:nothing	; Tell the assembler about it

	STROUT	GOPROTZ

; Now that we're back in RM and on a valid stack, restore
; A20 to the state we found it.

	test	DEV_FLAG,@DEV_A20ON ; Wuzit enabled upon entry?
	jnz	short @F	; Jump if so

	call	FDEGATEA20	; Disable address line A20
	jnc	short @F	; Jump if no error

	int	03h		; Call our debugger
@@:
	call	ENABLE_IMR	; Enable the 8259 interrupt mask register

	call	DEVENABLE_NMI	; Enable NMI

	sti			; Allow interrupts

; Re-specify the SWAT stack into extended memory

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	LaSTK		; Get base address
	push	DTE_SS		; Get DTE
	push	((mask $DTE_B) shl 8) or CPL0_DATA ; Get A/R byte and flags
	call	SET_DEVGDT	; Set the GDT entry

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	LaSTK		; Get base address
	push	DTE_SSB0S	; Get DTE
	push	CPL0_DATA	; Get A/R byte and flags
	call	SET_DEVGDT	; Set the GDT entry

	PUSHD	0		; Get length of SWAT low memory
	push	LaSTK		; Get base address
	push	DTE_SSB0L	; Get DTE
	push	CPL0_DATA	; Get A/R byte and flags
	call	SET_DEVGDT	; Set the GDT entry

; Note we must not set the B-bit in the stack selector as
; we don't reset the A/R byte when we return to RM.

	clc			; Mark as successful
PROT_INIT_EXIT:
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROT_INIT endp			; End PROT_INIT procedure
	NPPROC	VIRT_INIT -- Initialize Virtual Mode
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Initialize virtual mode (actually real mode, but who's counting).

On exit:

CF	=	0 if all went well
	=	1 otherwise

|

; Does this file support the INIT_VIRT entry point?

	test	SWATINI.MD_ATTR,@MD_VER ; Does this one have init_virt?
	jz	short VIRT_INIT_EXIT ; Nope, just exit (note CF=0)

; Relocate the INIT_VIRT code

	pusha			; Save all GP registers
	REGSAVE <ds,es> 	; Save for a moment

	mov	cx,SWATINI.MD_VSIZE.ELO ; Get # bytes to move

	mov	ax,PRTAIL	; Get ending offset in RGROUP
	add	ax,16-1 	; Round up to para boundary
	shr	ax,4-0		; Convert from bytes to paras
	add	ax,RGRSEG1	; Plus segment of (relocated) RGROUP
	mov	es,ax		; Address it
	assume	es:nothing	; Tell the assembler about it

	xchg	ax,SWATINI.MD_IVIRT.VSEG ; Get INIT_VIRT segment

	mov	ds,ax		; Address it
	assume	ds:nothing	; Tell the assembler about it

	xor	si,si		; Start at the beginning of the segment
	xor	di,di		; ...

S16 rep movs	<es:[di].LO,ds:[si].LO> ; Copy to lower memory

	REGREST <es,ds> 	; Restore
	assume	ds:NGROUP,es:PGROUP ; Tell the assembler about it
	popa			; Restore GP registers

; Call the file's INIT_VIRT routine

	STROUT	MD_IVIRT
	call	SWATINI.MD_IVIRT ; Call it
	STROUT	MD_IVIRTZ

	test	SWATINI.MD_ATTR,@MD_VMIE ; Did it fail?
	jz	short VIRT_INIT_EXIT ; Jump if not (note CF=0)

	stc			; Indicate it failed
VIRT_INIT_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VIRT_INIT endp			; End VIRT_INIT procedure
	NPPROC	SET_DEVGDT -- Set GDT/LDT Entry
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Set GDT/LDT entry

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

	REGSAVE <eax,bx,ecx,si> ; Save registers

	mov	eax,[bp].SDG_BASE ; Get base address
	mov	bx,[bp].SDG_DTE ; Get the DTE #
	and	bx,not (mask $PL) ; Clear the RPL bits

	mov	ecx,[bp].SDG_LEN ; Get DTE length
	dec	ecx		; Convert from length to limit

	cmp	ecx,1024*1024	; Check against limit limit
	jb	short @F	; Jump if within range

	shr	ecx,12-0	; Convert from bytes to 4KB
	or	ecx,(mask $DTE_G) shl 16 ; Set G-bit
@@:
	lea	si,SWATGDT	; Assume it's in the GDT

	btr	bx,$TI		; Izit in the LDT?
	jnc	short @F	; Jump if not

	lea	si,SWATLDT	; Assume it's in the LDT
@@:
	mov	RGROUP:[bx+si].DESC_BASE01.EDD,eax
	rol	eax,8		; Rotate out the high-order byte
	mov	RGROUP:[bx+si].DESC_BASE3,al ; Save as base byte #3
;;;;;;; ror	eax,8		; Rotate back
	mov	RGROUP:[bx+si].DESC_SEGLM0,cx ; Save as data limit
	rol	ecx,16		; Swap high- and low-order words
	or	cl,[bp].SDG_FLG ; Include flags
	mov	RGROUP:[bx+si].DESC_SEGLM1,cl ; Save as data limit and flags

	mov	al,[bp].SDG_ARB ; Get the A/R byte
	mov	RGROUP:[bx+si].DESC_ACCESS,al ; Save in the GDT

	REGREST <si,ecx,bx,eax> ; Restore

	pop	bp		; Restore

	ret	4+4+2+1+1	; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_DEVGDT endp 		; End SET_DEVGDT procedure
	NPPROC	CHECK_PSWAT -- Check On Preceding Device SWAT
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Check on preceding device SWAT.

|

	pushad			; Save all EGP registers

; Attempt to open the device '386SWAT$'

	mov	al,@OPEN_R	; Code for read-only access
	DOSCALL @OPENF2,SWTNAME ; Attempt to open the device
	jnc	short CHECK_PSWAT1 ; Jump if present

; Attempt to open the device '386MAX$$'

	mov	al,@OPEN_R	; Code for read-only access
	DOSCALL @OPENF2,MAXNAME ; Attempt to open the device
	jc	near ptr CHECK_PSWAT_EXIT ; Jump if not present
CHECK_PSWAT1:
	mov	bx,ax		; Copy to handle register

	mov	al,0		; Code to get device info
	DOSCALL @IOCTL2 	; Return with DX = device info
	pushf			; Save CF from DOSCALL
	DOSCALL @CLOSF2 	; Close the file
	popf			; Restore
	jc	near ptr CHECK_PSWAT_EXIT ; Jump if IOCTL failed

	test	dx,@IOCTL_DEV	; Izit a device?
	jz	near ptr CHECK_PSWAT_EXIT ; Jump if not

; See if there's a debugging host present

	STROUT	VCPI_DPRES
	XVCPICALL @VCPI_DPRES	; Check on VCPI debugging host
				; Return with AH = 0 if present
				;	 (BH,BL) = version #
	cmp	ah,0		; Izit present?
	jne	short CHECK_PSWAT_EXIT ; Jump if not

	mov	PSWAT_VER,bx	; BH = major, BL = minor

; Get SWAT's selectors

	STROUT	VCPI_GETINFO
	mov	bl,@GETINFO_SELS ; Get SWAT's selectors
	XVCPICALL @VCPI_GETINFO ; Return SWAT internal information
				;	 CX = 4GB selector
				;	 DX = CR3 selector
	and	ah,ah		; Did it work?
	jne	short @F	; Jump if not

	mov	PSWAT_4GBSEL,cx ; Save for later use
	mov	PSWAT_CR3SEL,dx ; ...
@@:

; Initialize the preceding SWAT in our PM GDT

	push	es		; Save for a moment

	les	di,PSWATGDT	; ES:DI ==> SWAT's GDT
	assume	es:RGROUP	; Tell the assembler about it

	mov	bx,DTE_PSWAT	; Get its code selector
	add	di,bx		; ES:DI ==> GDT entries for preceding device SWAT

	STROUT	VCPI_DBGINI
	XVCPICALL @VCPI_DBGINI	; Initialize debugger interface with
				; with BX = code selector
				; and ES:DI ==> GDT entries to fill in
				; Return with BX:EDX ==> PM entry point
	pop	es		; Restore
	assume	es:nothing	; Tell the assembler about it

	cmp	ah,0		; Did it succeed?
	jne	short CHECK_PSWAT_ERR ; Jump if not

	DOSCALL @STROUT,MSG_PSWAT ; Tell 'em what we found

	or	DEVLOAD,@DEVL_PSWAT ; Mark as present

	int	01h		; Call our debugger

	jmp	short CHECK_PSWAT_EXIT ; Join common exit code


CHECK_PSWAT_ERR:
	int	03h		; Call our debugger
CHECK_PSWAT_EXIT:
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PSWAT endp		; End CHECK_PSWAT procedure
	NPPROC	INIT_PSWAT -- Initialize Preceding Device SWAT Data
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Initialize preceding device SWAT data.

|

	pushad			; Save all EGP registers
	REGSAVE <ds,es,fs,gs>	; Save registers

	test	DEVLOAD,@DEVL_PSWAT ; Izit present?
	jz	near ptr INIT_PSWAT_EXIT ; Jump if not

	mov	es,SegIDT	; Get the segment of the temporary IDT
	assume	es:nothing	; Tell the assembler about it

%	irp	XX,<@HOOKINTS>
	mov	bx,0&XX&h	; Interrupt #
	mov	di,0&XX&h*(type IDT_STR) ; ES:DI ==> this IDT entry
	XVCPICALL @VCPI_DBGIDT	; Initialize debugger IDT entry
				; Ignore error return
	endm			; IRP XX,<@HOOKINTS>

	test	DEV_FLAG,@DEV_VCPI ; Are we using VCPI services?
	jnz	short INIT_PSWAT_VCPI ; Jump if so

; Save DTE for source and destination limits

	movzx	eax,SWATIDTR.DTR_LIM ; Get IDT limit
	mov	MOVE_TAB.MDTE_DS.DESC_SEGLM0,ax ; Save as data limit
	mov	MOVE_TAB.MDTE_ES.DESC_SEGLM0,ax ; ...
	rol	eax,16		; Swap high- and low-order words
	mov	MOVE_TAB.MDTE_DS.DESC_SEGLM1,al ; Save size & flags
	mov	MOVE_TAB.MDTE_ES.DESC_SEGLM1,al ; ...
;;;;;;; ror	eax,16		; Swap back

; Save DTE for source base and A/R

	xor	eax,eax 	; Zero to use as dword
	mov	ax,es		; Get the IDT's segment
	shl	eax,4-0 	; Convert from paras to bytes
	mov	MOVE_TAB.MDTE_DS.DESC_BASE01.EDD,eax
	rol	eax,8		; Rotate out the high-order byte
	mov	MOVE_TAB.MDTE_DS.DESC_BASE3,al ; Save as base byte #3
;;;;;;; ror	eax,8		; Rotate back
	mov	MOVE_TAB.MDTE_DS.DESC_ACCESS,CPL0_DATA

; Save DTE for destination base and A/R

	mov	eax,SWATIDTR.DTR_BASE ; Get base address of the IDT
	mov	MOVE_TAB.MDTE_ES.DESC_BASE01.EDD,eax
	rol	eax,8		; Rotate out the high-order byte
	mov	MOVE_TAB.MDTE_ES.DESC_BASE3,al ; Save as base byte #3
;;;;;;; ror	eax,8		; Rotate back
	mov	MOVE_TAB.MDTE_ES.DESC_ACCESS,CPL0_DATA

; Copy the new PM IDT to extended memory

	movzx	ecx,SWATIDTR.DTR_LIM ; Get IDT limit
	inc	ecx		; Convert from limit to length
	shr	ecx,1-0 	; Convert from bytes to words

	push	seg NGROUP	; Get segment of MOVE_TAB
	pop	es		; Address it
	assume	es:NGROUP	; Tell the assembler about it

	lea	si,MOVE_TAB	; ES:SI ==> GDT
	mov	ah,87h		; Function code to BIOS block move
	int	15h		; Request BIOS service

	cmp	ah,0		; Did it work?
	je	short INIT_PSWAT_EXIT ; Jump if so
INIT_PSWAT_ERR:
	int	03h		; Call our debugger
INIT_PSWAT_VCPI:
	cmp	PSWAT_VER,0400h ; Does it support fill PTE function?
	jb	short INIT_PSWAT_VCPIERR ; Jump if not

	mov	edi,LaPSWAT	; Get linear address of preceding SWAT (/4KB)

; Convert the linear address to offset into the PDIR

	movzx	eax,SegPTE	; Get segment of PTEs (/4KB)
	shl	eax,4-0 	; Convert from paras to bytes

	shr	edi,(12-2)-0	; Convert from bytes to 4KB in dwords
	add	edi,eax 	; Plus linear address of the PTEs (/4KB)

	xor	ax,ax		; A convenient zero
	mov	es,ax		; Address it
	assume	es:nothing	; Tell the assembler about it

; Request that SWAT fill in the PTEs

	mov	ecx,PSWAT_TSIZ	; Get total size of PM-resident PSWAT (/4KB)
	shr	ecx,12-0	; Convert from bytes to 4KB (# PTEs)
	XVCPICALL @VCPI_FILLPTE ; Fill in ECX PTEs into ES:EDI
				; Return with ECX = # PTEs not filled in
	or	ah,ah		; Did it work?
	jz	short INIT_PSWAT_EXIT ; Jump so
INIT_PSWAT_VCPIERR:
	and	DEVLOAD,not @DEVL_PSWAT ; Mark as not present
INIT_PSWAT_EXIT:
	REGREST <gs,fs,es,ds>	; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it
	assume	fs:nothing,gs:nothing ; ...
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_PSWAT endp 		; End INIT_PSWAT procedure
	NPPROC	COPYLOW -- Copy RGROUP To Low Memory
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Copy RGROUP to low memory except for SWATINI.

|

	REGSAVE <eax,cx,si,edi,es> ; Save registers

; Note that this doesn't change the value of RGRSEG2 in extended memory

	mov	ax,seg DGROUP	; Get segment of RUD_xDTR variables
	mov	es,ax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	mov	GOREAL_SEG,seg PGROUP ; Relocate
	mov	RGRSEG1,seg PGROUP ; ...
	mov	RGRSEG2,seg PGROUP ; ...
	mov	RGRSEL,LDTE_DS	; ...
	mov	VCPSTK_FVEC.FSEL,LDTE_DS ; ...

; Relocate VCPI pointers

	xor	eax,eax 	; Zero to use as dword
	mov	ax,seg RGROUP	; Get old segment
	sub	ax,seg PGROUP	; Get new segment
	shl	eax,4-0 	; Convert from paras to bytes

	sub	LaVCPEPM,eax	; Relocate from RGROUP to PGROUP
	sub	VCPEPM.VCPEPM_GDTP,eax ; ...
	sub	VCPEPM.VCPEPM_IDTP,eax ; ...
	sub	SWATGDTR.DTR_BASE,eax ; ...

; Relocate the code selector to PGROUP

	movzx	eax,RGRSEG1	; Get new segment of RGROUP
	shl	eax,4-0 	; Convert from paras to bytes

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	eax		; Get base address
	push	DTE_CS		; Get DTE
	push	CPL0_CODE	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

	PUSHD	0		; Get length of SWAT low memory
	push	eax		; Get base address
	push	DTE_CS4GB	; Get DTE
	push	CPL0_CODE	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

; Relocate the data selector to PGROUP

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	eax		; Get base address
	push	DTE_DS		; Get DTE
	push	CPL0_DATA	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

; Relocate the LDT selectors to PGROUP

	push	dword ptr (size SWATLDT) ; Get length of LDT
	lea	edi,SWATLDT[eax] ; Plus offset of LDT
	push	edi		; Pass base address
	push	DTE_LOAD+2*(size DESC_STR) ; Get DTE
	push	CPL0_LDT	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

	push	dword ptr (size SWATLDT) ; Get length of LDT
;;;;;;; lea	edi,SWATLDT[eax] ; Plus offset of LDT
	push	edi		; Pass base address
	push	DTE_LDTCS	; Get DTE
	push	CPL0_LDT	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

	push	dword ptr (size SWATLDT) ; Get length of LDT
;;;;;;; lea	edi,SWATLDT[eax] ; Plus offset of LDT
	push	edi		; Pass base address
	push	DTE_LDTCSR	; Get DTE
	push	CPL0_LDT	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

	push	dword ptr (size SWATLDT) ; Get length of LDT
;;;;;;; lea	edi,SWATLDT[eax] ; Plus offset of LDT
	push	edi		; Pass base address
	push	DTE_LDTCS4GB	; Get DTE
	push	CPL0_LDT	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

; Relocate the LDT entries to PGROUP

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	eax		; Get base address
	push	LDTE_CS 	; Get LDTE
	push	CPL0_CODE	; Get A/R byte
	call	SET_DEVGDT	; Set the LDT entry

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	eax		; Get base address
	push	LDTE_DS 	; Get LDTE
	push	CPL0_DATA	; Get A/R byte
	call	SET_DEVGDT	; Set the LDT entry

	PUSHD	0		; Get length of 4GB segment
	push	eax		; Get base address
	push	LDTE_CS4GB	; Get DTE
	push	CPL0_CODE	; Get A/R byte
	call	SET_DEVGDT	; Set the GDT entry

	push	dword ptr (64*1024) ; Get length of SWAT low memory
	push	eax		; Get base address
	push	LDTE_SSB0S	; Get DTE
	push	CPL0_DATA	; Get A/R byte and flags
	call	SET_DEVGDT	; Set the GDT entry

	PUSHD	0		; Get length of SWAT low memory
	push	eax		; Get base address
	push	LDTE_SSB0L	; Get DTE
	push	CPL0_DATA	; Get A/R byte and flags
	call	SET_DEVGDT	; Set the GDT entry

	mov	es,RGRSEG1	; Address it
	assume	es:PGROUP	; Tell the assembler about it

	lea	di,PGROUP:SWATINI [size MD_STR] ; Get next byte after SWATINI
	lea	si,RGROUP:DEV_SWATINI[size MD_STR] ; ...	       DEV_SWATINI

	mov	cx,PRTAIL	; Get last byte in RGROUP
	sub	cx,si		; Less starting offset to get length

S16 rep movs	<SWATINI.LO[di],DEV_SWATINI.LO[si]> ; Copy to low memory

	mov	SWATINI.MD_DD.DD_STRA,offset RGROUP:DEV_STRA ; Note for next time
	mov	SWATINI.MD_DD.DD_INTR,offset RGROUP:DEV_INTR ; ...

	REGREST <es,edi,si,cx,eax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COPYLOW endp			; End COPYLOW procedure
	NPPROC	GOPROT -- Enter Protected Mode
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Common routine to enter Protected Mode.

On entry:

ES:SI	==>	Global Descriptor Table

On exit:

CF	=	0 if all went well
	=	1 otherwise
AH	=	error code if CF=1
BX	=	clobbered
CX	=	clobbered by some BIOSs
FS	=	0
GS	=	0

IF	=	0
NMI	=	disabled

|

	call	DISABLE_IMR	; Disable the 8259 interrupt mask register
	call	DEVDISABLE_NMI	; Disable NMI

	mov	bx,PICBASE	; Initialize hardware interrupts here
	call	near ptr INT15PROT ; Enter protected mode
;;;;;;; mov	ah,89h
;;;;;;; int	15h
	assume	ds:PGROUP,es:RGROUP ; Tell the assembler about it

; Return in protected mode with interrupts and NMI disabled

	xor	ax,ax		; A convenient zero

	mov	fs,ax		; Ensure valid
	assume	fs:nothing	; Tell the assembler about it

	mov	gs,ax		; Ensure valid
	assume	gs:nothing	; Tell the assembler about it

	clc			; Indicate we are in protected mode

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GOPROT	endp			; End GOPROT procedure
	FPPROC	INT15PROT -- Enter Protected Mode
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Enter protected mode on an XT that doesn't support
INT 15h BIOS function 89h.

On entry:

* Disable NMI
* Disable IMR

ES:SI	==>	descriptor table
BH	=	8259 origin for master
BL	=	8259 origin for slave

On exit:

* Disable interrupts
* Read and save A20 state
* Gate A20 on
* Setup DTE_BIOS entry
* Load GDTR
* Load IDTR
* Program the 8259
* Enter protected mode
* Setup segment registers
* Return to caller

|

; * Disable NMI
;;;;;;;
;;;;;;; call	DEVDISABLE_NMI	; Disable NMI
;;;;;;;
; * Disable interrupts

	cli

; * Gate A20 on

	call	FGATEA20

; * Setup DTE_BIOS entry

	xor	eax,eax 	; Zero entire register
	mov	ax,cs		; Get current code segment
	shl	eax,4-0 	; Convert from paras to bytes

	mov	es:[si].DTE_BIOS.DESC_BASE01.EDD,eax
	rol	eax,8		; Rotate out the high-order byte
	mov	es:[si].DTE_BIOS.DESC_BASE3,al
	ror	eax,8		; Rotate back
	mov	es:[si].DTE_BIOS.DESC_SEGLM0,0FFFFh ; 64KB of code
	mov	es:[si].DTE_BIOS.DESC_SEGLM1,0
	mov	es:[si].DTE_BIOS.DESC_ACCESS,CPL0_CODE

; * Load GDTR from low memory

	LGDTD	es:[si].DTE_GDT.EDF

; * Load IDTR

	LIDTD	es:[si].DTE_IDT.EDF

; * Program the 8259

	test	DEV_FLAG,@DEV_XT ; Running on an XT?
	jz	short INT15PROT1 ; Not this time

; ICW1

	mov	al,13h		; ICW1 -- edge-triggered, single, ICW4 needed
	out	@ICR,al 	; Send to 8259
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay

; ICW2

	mov	al,bh		; ICW2 -- start of 8259 vector
	out	@IMR,al 	; Send to 8259
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay

; ICW3 (none because it's not in cascade mode)
; ICW4

	mov	al,09h		; ICW4 -- buffered slave, normal EOI, 8086 mode
	out	@IMR,al 	; Send to 8259
;;;;;;; jmp	short $+2	; I/O delay
;;;;;;; jmp	short $+2	; I/O delay
;;;;;;; jmp	short $+2	; I/O delay

	jmp	short INT15PROT2 ; Join common code


INT15PROT1:

; ICW1 -- master 8259

	mov	al,11h		; ICW1 -- edge-triggered, cascade, ICW4 needed

	test	DEV_FLAG,@DEV_MCA ; Izit an MCA-compatible machine?
	jz	short @F	; Not this time

	or	al,08h		; Mark as level-triggered
@@:
	mov	ah,al		; Save for later use
	out	@ICR,al 	; Send to master 8259
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay

; ICW2 -- master 8259

	mov	al,bh		; ICW2 -- start of 8259 vector
	out	@IMR,al 	; Send to 8259
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay

; ICW3 -- master 8259

	mov	al,@BIT2	; ICW3 -- master level 2
	out	@IMR,al 	; Send to master 8259
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay

; ICW4 -- master 8259

	mov	al,01h		; ICW4 -- not SFNM, normal EOI, 8086 mode
	out	@IMR,al 	; Send to master 8259
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay

; ICW1 -- slave 8259

	mov	al,ah		; ICW1 -- level/edge-triggered, cascade, ICW4 needed
	out	@ICR2,al	; Send to slave 8259
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay

; ICW2 -- slave 8259

	mov	al,bl		; ICW2 -- start of slave 8259 vector
	out	@IMR2,al	; Send to slave 8259
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay

; ICW3 -- slave 8259

	mov	al,02h		; ICW3 -- slave level 2
	out	@IMR2,al	; Send to slave 8259
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay

; ICW34-- slave 8259

	mov	al,01h		; ICW4 -- not SFNM, normal EOI, 8086 mode
	out	@IMR2,al	; Send to slave 8259
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay
INT15PROT2:

; * Disable IMR
;;;;;;;
;;;;;;; call	DISABLE_IMR	; Disable the 8259 interrupt mask register
;;;;;;;
; * Enter protected mode

	mov	eax,cr0 	; Get current CR0
	or	ax,mask $PE	; Mark as enabling protected mode
	mov	cr0,eax 	; Enter protected mode

	assume	ds:nothing,es:nothing ; Tell the assembler about it

	FIJMP	NGROUP:@F,DTE_BIOS ; Flush prefetch instruction queue
@@:

; * Setup segment registers

	mov	ax,DTE_DS	; Get DS selector
	mov	ds,ax
	assume	ds:PGROUP	; Tell the assembler about it

	mov	ax,DTE_ES	; Get DS selector
	mov	es,ax
	assume	es:RGROUP	; Tell the assembler about it

	xor	ax,ax		; A convenient zero

	mov	fs,ax		; Ensure valid
	assume	fs:nothing	; Tell the assembler about it

	mov	gs,ax		; Ensure valid
	assume	gs:nothing	; Tell the assembler about it

	mov	ax,DTE_SS	; Get SS selector
	mov	ss,ax
	assume	ss:nothing	; Tell the assembler about it

; * Return to caller

	pop	ax		; Get return offset
	push	DTE_CS		; Put return selector on stack
	push	ax		; Followed by offset

	xor	ax,ax		; Successful return code (AH=0, CF=0, ZF=1)

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT15PROT endp			; End INT15PROT procedure
	NPPROC	DISABLE_IMR -- Disable the 8259 Interrupt Mask Register
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Disable the 8259 interrupt mask register

This routine is called from real mode only.

|

	REGSAVE <ax>		; Save register

	in	al,@IMR 	; Get current value
	jmp	short $+2	; Drain PIQ
	jmp	short $+2	; Drain PIQ
	jmp	short $+2	; Drain PIQ

	mov	INTA01,al	; Save to restore later

	mov	al,0FFh 	; Disable all interrupts
	out	@IMR,al 	; Send to 8259

	test	DEV_FLAG,@DEV_XT ; Running on an XT?
	jnz	short DISABLE_IMR_EXIT ; Yes, so there's no slave controller

	jmp	short $+2	; Drain PIQ
	jmp	short $+2	; Drain PIQ
	jmp	short $+2	; Drain PIQ

	in	al,@IMR2	; Get current value
	jmp	short $+2	; Drain PIQ
	jmp	short $+2	; Drain PIQ
	jmp	short $+2	; Drain PIQ

	mov	INTB01,al	; Save to restore later

	mov	al,0FFh 	; Disable all interrupts
	out	@IMR2,al	; Reset in slave 8259
;;;;;;; jmp	short $+2	; Drain PIQ
;;;;;;; jmp	short $+2	; Drain PIQ
;;;;;;; jmp	short $+2	; Drain PIQ
DISABLE_IMR_EXIT:
	REGREST <ax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISABLE_IMR endp		; End DISABLE_IMR procedure
	NPPROC	ENABLE_IMR -- Enable the 8259 Interrupt Mask Register
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Enable the 8259 interrupt mask register

|

	REGSAVE <ax>		; Save register

	mov	al,INTA01	; Get original master interrupt mask
	out	@IMR,al 	; Reset in master 8259

	test	DEV_FLAG,@DEV_XT ; Running on an XT?
	jnz	short ENABLE_IMR_EXIT ; Yes, so there's no slave controller

	jmp	short $+2	; Drain PIQ
;;;;;;; jmp	short $+2	; Drain PIQ
;;;;;;; jmp	short $+2	; Drain PIQ

	mov	al,INTB01	; Get original slave interrupt mask
	out	@IMR2,al	; Reset in slave 8259
;;;;;;; jmp	short $+2	; Drain PIQ
;;;;;;; jmp	short $+2	; Drain PIQ
;;;;;;; jmp	short $+2	; Drain PIQ
ENABLE_IMR_EXIT:
	REGREST <ax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENABLE_IMR endp 		; End ENABLE_IMR procedure
	NPPROC	DEVDISABLE_NMI -- Disable NMI
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Disable NMI

Note that this routine is bimodal.

|

	pushf			; Save flags
	cli			; Ensure interrupts disabled

	REGSAVE <ax,dx> 	; Save for a moment

; Disable NMI

	mov	dx,DEVNMIPORT	; Get NMI clear I/O port
	mov	al,DEVNMIDIS	; ...	  disable value
	call	OUTCMOS 	; Out to CMOS, conditional read

	REGREST <dx,ax> 	; Restore
	popf			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEVDISABLE_NMI endp		; End DEVDISABLE_NMI procedure
	NPPROC	DEVENABLE_NMI -- Enable NMI, Clear Parity Latches
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:RGROUP,ss:nothing
COMMENT|

Enable NMI, clear parity latches.

Note that this routine is bimodal.

|

	pushf			; Save flags
	cli			; Ensure interrupts disabled

	REGSAVE <ax,dx> 	; Save for a moment

; Clear the parity latches

	call	CLR_PARITY	; Clear any parity errors

; Enable the NMI latch

	mov	dx,DEVNMIPORT	; Get NMI clear I/O port
	mov	al,DEVNMIENA	; ...	  enable value
	call	OUTCMOS 	; Out to CMOS, conditional read

	REGREST <dx,ax> 	; Restore
	popf			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEVENABLE_NMI endp		; End DEVENABLE_NMI procedure
	NPPROC	CLR_PARITY -- Clear Parity Latches
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear the parity latches

Note that this routine is bimodal.

|

	REGSAVE <ax>		; Save register

;;;;;;; test	DEV_FLAG,@DEV_XPARITY ; Was NOPARITY specified?
;;;;;;; jnz	short CLR_PARITY_EXIT ; Jump if so
;;;;;;;
	mov	ah,DEVNMIMASK	; Get parity mask
	in	al,@8255_B	; Get the parity latches
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay

	or	al,ah		; Toggle parity check latches off
	out	@8255_B,al	; Tell the system about it
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay
	jmp	short $+2	; I/O delay

	xor	al,ah		; Toggle parity check latches on
	out	@8255_B,al	; Tell the system about it
;;;;;;; jmp	short $+2	; I/O delay
;;;;;;; jmp	short $+2	; I/O delay
;;;;;;; jmp	short $+2	; I/O delay

CLR_PARITY_EXIT:
	REGREST <ax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLR_PARITY endp 		; End CLR_PARITY procedure
	NPPROC	SETINTS -- Setup Interrupts
	assume	ds:NGROUP,es:nothing,fs:PGROUP,gs:nothing,ss:nothing
COMMENT|

Install RM interrupt handlers

RGROUP code has been copied down to the bottom of PGROUP.

|

	REGSAVE <eax,cx,di,ds,es,fs> ; Save registers

	mov	ax,seg DGROUP	; Get DGROUP segment
	mov	fs,ax		; Address it
	assume	fs:DGROUP	; Tell the assembler about it

	mov	ax,seg PGROUP	; Get segment for RM_IDT and RGRSEG1 as relocated
	mov	es,ax		; Address it
	assume	es:RGROUP	; Tell the assembler about it (note lie)

	test	DEV_FLAG,@DEV_NORMLIDT ; Izit NORMLIDT?
	jz	near ptr SETINTS_RMLIDT ; Jump if not

	mov	ax,seg NGROUP	; Get NGROUP segment
	mov	ds,ax		; Address it
	assume	ds:NGROUP	; Tell the assembler about it

	mov	PRTAIL,offset RGROUP:RTAIL_NORMLIDT ; Save new ending address

	mov	ax,seg INTVEC	; Get INTVEC segment
	mov	ds,ax		; Address it
	assume	ds:INTVEC	; Tell the assembler about it

; Set our special interrupts in the RM IDT
; INTs 15h, 2Fh, and 68h are extra as we don't reflect them to PM.

%	irp	XX,<@HOOKINTS,15,2F>

	mov	al,0&XX&h	; Mark the start of the set
	lea	ax,RMDEV&XX	; Get offset to save
	xchg	ax,INT00_VEC[0&XX&h*(type INT00_VEC)].VOFF ; Swap with old
	mov	OLDDEV&XX&_VEC.VOFF,ax ; Save for later use
	mov	ax,seg PGROUP	; Get segment to save
	xchg	ax,INT00_VEC[0&XX&h*(type INT00_VEC)].VSEG
	mov	OLDDEV&XX&_VEC.VSEG,ax ; Save for later use

	endm

	test	TRP_FLAG,@TRP_I68 ; Izit enabled?
	jz	short @F	; Jump if not

%	irp	XX,<68>

	lea	ax,RMDEV&XX	; Get offset to save
	xchg	ax,INT00_VEC[0&XX&h*(type INT00_VEC)].VOFF ; Swap with old
	mov	OLDDEV&XX&_VEC.VOFF,ax ; Save for later use
	mov	ax,seg PGROUP	; Get segment to save
	xchg	ax,INT00_VEC[0&XX&h*(type INT00_VEC)].VSEG
	mov	OLDDEV&XX&_VEC.VSEG,ax ; Save for later use

	endm
@@:
	jmp	SETINTS_COM	; Join common code


	assume	ds:nothing	; Tell the assembler about it

SETINTS_RMLIDT:

; Initialize the RM IDT in local memory

	lea	di,RM_IDT	; ES:EDI ==> RM IDT in extended memory

	mov	cx,256		; All interrupts
	mov	ax,seg PGROUP	; Get new segment
	shl	eax,16		; Shift to high-order word
	lea	ax,DEVINTCOM	; Get offset
@@:
S16	stos	RM_IDT[di].VOFF ; Store the offset
	add	ax,16		; Skip to next para in offset units
	rol	eax,16		; Rotate to get segment

S16	stos	RM_IDT[di].VSEG ; Store the segment
	dec	ax		; Skip to previous para in segment units
	ror	eax,16		; Rotate back

	LOOPS	@B		; Jump if more interrupts to relocate

; Set our special interrupts in the local IDT
; INTs 15h, 2Fh, and 68h are extra as we don't reflect them to PM.

%	irp	XX,<@HOOKINTS,15,2F>

	lea	ax,RMDEV&XX	; Get offset to save
	xchg	ax,RM_IDT[0&XX&h*(type INT00_VEC)].VOFF ; Swap with old
	mov	OLDDEV&XX&_VEC.VOFF,ax ; Save for later use
	mov	ax,seg PGROUP	; Get segment to save
	xchg	ax,RM_IDT[0&XX&h*(type INT00_VEC)].VSEG
	mov	OLDDEV&XX&_VEC.VSEG,ax ; Save for later use

	endm

	test	TRP_FLAG,@TRP_I68 ; Izit enabled?
	jz	short @F	; Jump if not

%	irp	XX,<68>

	lea	ax,RMDEV&XX	; Get offset to save
	xchg	ax,RM_IDT[0&XX&h*(type INT00_VEC)].VOFF ; Swap with old
	mov	OLDDEV&XX&_VEC.VOFF,ax ; Save for later use
	mov	ax,seg PGROUP	; Get segment to save
	xchg	ax,RM_IDT[0&XX&h*(type INT00_VEC)].VSEG
	mov	OLDDEV&XX&_VEC.VSEG,ax ; Save for later use

	endm
@@:
	assume	es:nothing	; Tell the assembler about it

	push	seg RGROUP	; Get RGROUP segment
	pop	ds		; Address it
	assume	ds:RGROUP	; Tell the assembler about it

	test	DEV_FLAG,@DEV_VCPI ; Are we using VCPI services?
	jnz	short SETINTS_EXIT ; Jump if so

; Point the IDTR to RM_IDT

	push	seg PGROUP	; Get PGROUP segment
	pop	ds		; Address it
	assume	ds:PGROUP	; Tell the assembler about it

; Because we've already copied RGROUP low (to PGROUP), we need to
; load the new IDTR from the variable in PGROUP, hence the
; following chicanery.

	xor	eax,eax 	; Zero to use as dword

	mov	ax,seg PGROUP	; Get segment RM_IDT as relocated
	shl	eax,4-0 	; Convert from paras to bytes
	add	eax,offset RGROUP:RM_IDT ; Plus its offset

	assume	ds:RGROUP	; Tell a white lie
	mov	RM_IDTRL.DTR_BASE,eax ; Save for later use

	LIDTD	RM_IDTRL	; Reset IDT to the table in local memory
	assume	ds:PGROUP	; Retract nose
SETINTS_COM:
	mov	ax,seg PGROUP	; Get segment for RM_IDT and RGRSEG1 as relocated
	mov	es,ax		; Address it
	assume	es:RGROUP	; Tell the assembler about it (note lie)

; If OLDDEV67_VEC is zero, point it to an IRET

	cmp	OLDDEV67_VEC,0	; Izit invalid?
	jne	short SETINTS_EXIT ; Jump if not

	mov	OLDDEV67_VEC.VSEG,es ; Save as segment
	mov	OLDDEV67_VEC.VOFF,offset RGROUP:RMDEV67_IRET ; Save as offset
SETINTS_EXIT:
	REGREST <fs,es,ds,di,cx,eax> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it
	assume	fs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETINTS endp			; End SETINTS procedure

NCODE	ends			; End NCODE segment

	MEND			; End SWAT_DRV module
