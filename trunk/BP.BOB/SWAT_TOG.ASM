;' $Header:   P:/PVCS/386SWAT/SWAT_TOG.ASV   1.9   10 Aug 1998 11:01:42   BOB  $
	title	SWAT_TOG -- 386SWAT Toggle Interrupt Interception Command Functions
	page	58,122
	name	SWAT_TOG

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-2002 Qualitas, Inc.  All rights reserved.

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
	include ALLMEM.INC
	include CPUFLAGS.INC

	include SWAT_COM.INC
	include SWAT_DRV.INC
	include SWAT_FIL.INC
	include SWAT_SEG.INC
.list


TOGIDTMAC macro N1,SRC,SAV
	local	L1

IDT	equ	<AGROUP:[ebx+N1*(type IDT_STR)]>

	mov	esi,DGROUP:[edx].INTR_&SRC&_FVEC ; Get offset of SRC&_FVEC
	mov	ax,DGROUP:[esi].FSEL ; Get selector
	xchg	ax,IDT.IDT_SELECT ; Swap with IDT
ifnb <SAV>
	mov	edi,DGROUP:[edx].INTR_&SAV&_FVEC ; Get offset of SAV&_FVEC
	mov	DGROUP:[edi].FSEL,ax ; Save for later use
endif
	mov	eax,DGROUP:[esi].FOFF ; Get 32-bit offset
	xchg	ax,IDT.IDT_OFFLO ; Swap with IDT
ifnb <SAV>
	mov	DGROUP:[edi].FOFF.ELO,ax ; Save for later use
endif
	shr	eax,16		; Shift to low-order
	xchg	ax,IDT.IDT_OFFHI ; Swap with IDT
ifnb <SAV>
	mov	DGROUP:[edi].FOFF.EHI,ax ; Save for later use
endif
	mov	esi,DGROUP:[edx].INTR_&SRC&_ARB ; Get offset of SRC&_ARB
	mov	al,DGROUP:[esi] ; Get access rights byte
	xchg	al,IDT.IDT_ACCESS ; Swap with IDT
ifnb <SAV>
	mov	edi,DGROUP:[edx].INTR_&SAV&_ARB ; Get offset of SAV&_ARB
	mov	DGROUP:[edi],al ; Save for later use
endif
L1:
	endm			; TOGIDTMAC


RCODE	segment use16 para public 'rcode' ; Start RCODE segment
	assume	cs:RGROUP

	extrn	TRP_FLAG:dword

RCODE	ends			; End RCODE segment


DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	public	@SWAT_TOG_DATA16
@SWAT_TOG_DATA16 label byte	; Mark module start in .MAP file

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	LC3_FLAG:dword
	include SWAT_LC3.INC

	extrn	LC4_FLAG:dword
	include SWAT_LC4.INC

@TOGINTS equ	<00,01,02,03,05,06,0A,0B,0C,0D,0E>

%	irp	XX,<@TOGINTS>

	extrn	LCLINT&XX&_FVEC:dword,LCLINT&XX&_ARB:byte
	extrn	OLDINT&XX&_FVEC:dword,OLDINT&XX&_ARB:byte
	extrn	OLDTSSINT&XX&_FVEC:dword,OLDTSSINT&XX&_ARB:byte

	endm			; IRP

%	irp	XX,<41>

	extrn	LCLINT&XX&_FVEC:dword,LCLINT&XX&_ARB:byte
	extrn	OLDINT&XX&_FVEC:dword,OLDINT&XX&_ARB:byte

	endm			; IRP

	public	RGRSEG2
RGRSEG2 dw	seg PGROUP	; Segment of RGROUP changed by COPYLOW
				; to reflect reality
				; Must be <64KB *FIXME*

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	@SWAT_TOG_DATA
@SWAT_TOG_DATA label byte	; Mark module start in .MAP file

	extrn	MSGOFF:dword
	extrn	SYNTERR:byte
	extrn	VALERR:byte
	extrn	IntMode:dword

	extrn	TSSINT_FLAG:dword

%	irp	XX,<@TOGINTS>

	extrn	TSSINT&XX&_FVEC:dword,TSSINT&XX&_ARB:byte
	extrn	LCLPMG&XX&_FVEC:fword,LCLPMG&XX&_ARB:byte
	extrn	OLDPMG&XX&_FVEC:fword,OLDPMG&XX&_ARB:byte
	extrn	MSG_&XX&ON:byte

	endm			; IRP

	extrn	MSG_OFF:byte
	extrn	TSS_CNT:dword

	public	TOGINT_TAB,TOGINT_CNT
	public	TOGINT00,TOGINT01,TOGINT02,TOGINT03,TOGINT05
	public	TOGINT06,TOGINT0A,TOGINT0B,TOGINT0C,TOGINT0D,TOGINT0E
TOGINT_TAB label  tbyte
TOGINT00 INTR_STR <1 shl 00h,00h,offset DGROUP:LC4_FLAG,@LC4_DIVO, @TRP_I00, \
 offset DGROUP:LCLINT00_FVEC,	offset DGROUP:LCLINT00_ARB,\
 offset DGROUP:OLDINT00_FVEC,	offset DGROUP:OLDINT00_ARB,\
 offset DGROUP:TSSINT00_FVEC,	offset DGROUP:TSSINT00_ARB,\
 offset DGROUP:OLDTSSINT00_FVEC,offset DGROUP:OLDTSSINT00_ARB,\
 offset DGROUP:MSG_00ON,	offset DGROUP:MSG_OFF,\
 offset DGROUP:LCLPMG00_FVEC,	offset DGROUP:LCLPMG00_ARB,\
 offset DGROUP:OLDPMG00_FVEC,	offset DGROUP:OLDPMG00_ARB> ; INT 00h
TOGINT01 INTR_STR <1 shl 01h,01h,offset DGROUP:LC3_FLAG,@LC3_STEP, @TRP_I01, \
 offset DGROUP:LCLINT01_FVEC,	offset DGROUP:LCLINT01_ARB,\
 offset DGROUP:OLDINT01_FVEC,	offset DGROUP:OLDINT01_ARB,\
 offset DGROUP:TSSINT01_FVEC,	offset DGROUP:TSSINT01_ARB,\
 offset DGROUP:OLDTSSINT01_FVEC,offset DGROUP:OLDTSSINT01_ARB,\
 offset DGROUP:MSG_01ON,	offset DGROUP:MSG_OFF,\
 offset DGROUP:LCLPMG01_FVEC,	offset DGROUP:LCLPMG01_ARB,\
 offset DGROUP:OLDPMG01_FVEC,	offset DGROUP:OLDPMG01_ARB> ; INT 01h
TOGINT02 INTR_STR <1 shl 02h,02h,offset DGROUP:LCL_FLAG,@LCL_NMI,  @TRP_I02, \
 offset DGROUP:LCLINT02_FVEC,	offset DGROUP:LCLINT02_ARB,\
 offset DGROUP:OLDINT02_FVEC,	offset DGROUP:OLDINT02_ARB,\
 offset DGROUP:TSSINT02_FVEC,	offset DGROUP:TSSINT02_ARB,\
 offset DGROUP:OLDTSSINT02_FVEC,offset DGROUP:OLDTSSINT02_ARB,\
 offset DGROUP:MSG_02ON,	offset DGROUP:MSG_OFF,\
 offset DGROUP:LCLPMG02_FVEC,	offset DGROUP:LCLPMG02_ARB,\
 offset DGROUP:OLDPMG02_FVEC,	offset DGROUP:OLDPMG02_ARB> ; INT 02h
TOGINT03 INTR_STR <1 shl 03h,03h,offset DGROUP:LC3_FLAG,@LC3_SKIP, @TRP_I03, \
 offset DGROUP:LCLINT03_FVEC,	offset DGROUP:LCLINT03_ARB,\
 offset DGROUP:OLDINT03_FVEC,	offset DGROUP:OLDINT03_ARB,\
 offset DGROUP:TSSINT03_FVEC,	offset DGROUP:TSSINT03_ARB,\
 offset DGROUP:OLDTSSINT03_FVEC,offset DGROUP:OLDTSSINT03_ARB,\
 offset DGROUP:MSG_03ON,	offset DGROUP:MSG_OFF,\
 offset DGROUP:LCLPMG03_FVEC,	offset DGROUP:LCLPMG03_ARB,\
 offset DGROUP:OLDPMG03_FVEC,	offset DGROUP:OLDPMG03_ARB> ; INT 03h
TOGINT05 INTR_STR <1 shl 05h,05h,offset DGROUP:LC4_FLAG,@LC4_BOUND,@TRP_I05, \
 offset DGROUP:LCLINT05_FVEC,	offset DGROUP:LCLINT05_ARB,\
 offset DGROUP:OLDINT05_FVEC,	offset DGROUP:OLDINT05_ARB,\
 offset DGROUP:TSSINT05_FVEC,	offset DGROUP:TSSINT05_ARB,\
 offset DGROUP:OLDTSSINT05_FVEC,offset DGROUP:OLDTSSINT05_ARB,\
 offset DGROUP:MSG_05ON,	offset DGROUP:MSG_OFF,\
 offset DGROUP:LCLPMG05_FVEC,	offset DGROUP:LCLPMG05_ARB,\
 offset DGROUP:OLDPMG05_FVEC,	offset DGROUP:OLDPMG05_ARB> ; INT 05h
TOGINT06 INTR_STR <1 shl 06h,06h,offset DGROUP:LC3_FLAG,@LC3_INV,  @TRP_I06, \
 offset DGROUP:LCLINT06_FVEC,	offset DGROUP:LCLINT06_ARB,\
 offset DGROUP:OLDINT06_FVEC,	offset DGROUP:OLDINT06_ARB,\
 offset DGROUP:TSSINT06_FVEC,	offset DGROUP:TSSINT06_ARB,\
 offset DGROUP:OLDTSSINT06_FVEC,offset DGROUP:OLDTSSINT06_ARB,\
 offset DGROUP:MSG_06ON,	offset DGROUP:MSG_OFF,\
 offset DGROUP:LCLPMG06_FVEC,	offset DGROUP:LCLPMG06_ARB,\
 offset DGROUP:OLDPMG06_FVEC,	offset DGROUP:OLDPMG06_ARB> ; INT 06h
TOGINT0A INTR_STR <1 shl 0Ah,0Ah,offset DGROUP:LC3_FLAG,@LC3_TSS,  @TRP_I0A, \
 offset DGROUP:LCLINT0A_FVEC,	offset DGROUP:LCLINT0A_ARB,\
 offset DGROUP:OLDINT0A_FVEC,	offset DGROUP:OLDINT0A_ARB,\
 offset DGROUP:TSSINT0A_FVEC,	offset DGROUP:TSSINT0A_ARB,\
 offset DGROUP:OLDTSSINT0A_FVEC,offset DGROUP:OLDTSSINT0A_ARB,\
 offset DGROUP:MSG_0AON,	offset DGROUP:MSG_OFF,\
 offset DGROUP:LCLPMG0A_FVEC,	offset DGROUP:LCLPMG0A_ARB,\
 offset DGROUP:OLDPMG0A_FVEC,	offset DGROUP:OLDPMG0A_ARB> ; INT 0Ah
TOGINT0B INTR_STR <1 shl 0Bh,0Bh,offset DGROUP:LC4_FLAG,@LC4_SEGNP,@TRP_I0B, \
 offset DGROUP:LCLINT0B_FVEC,	offset DGROUP:LCLINT0B_ARB,\
 offset DGROUP:OLDINT0B_FVEC,	offset DGROUP:OLDINT0B_ARB,\
 offset DGROUP:TSSINT0B_FVEC,	offset DGROUP:TSSINT0B_ARB,\
 offset DGROUP:OLDTSSINT0B_FVEC,offset DGROUP:OLDTSSINT0B_ARB,\
 offset DGROUP:MSG_0BON,	offset DGROUP:MSG_OFF,\
 offset DGROUP:LCLPMG0B_FVEC,	offset DGROUP:LCLPMG0B_ARB,\
 offset DGROUP:OLDPMG0B_FVEC,	offset DGROUP:OLDPMG0B_ARB> ; INT 0Bh
TOGINT0C INTR_STR <1 shl 0Ch,0Ch,offset DGROUP:LC3_FLAG,@LC3_STK,  @TRP_I0C, \
 offset DGROUP:LCLINT0C_FVEC,	offset DGROUP:LCLINT0C_ARB,\
 offset DGROUP:OLDINT0C_FVEC,	offset DGROUP:OLDINT0C_ARB,\
 offset DGROUP:TSSINT0C_FVEC,	offset DGROUP:TSSINT0C_ARB,\
 offset DGROUP:OLDTSSINT0C_FVEC,offset DGROUP:OLDTSSINT0C_ARB,\
 offset DGROUP:MSG_0CON,	offset DGROUP:MSG_OFF,\
 offset DGROUP:LCLPMG0C_FVEC,	offset DGROUP:LCLPMG0C_ARB,\
 offset DGROUP:OLDPMG0C_FVEC,	offset DGROUP:OLDPMG0C_ARB> ; INT 0Ch
TOGINT0D INTR_STR <1 shl 0Dh,0Dh,offset DGROUP:LCL_FLAG,@LCL_GENP, @TRP_I0D, \
 offset DGROUP:LCLINT0D_FVEC,	offset DGROUP:LCLINT0D_ARB,\
 offset DGROUP:OLDINT0D_FVEC,	offset DGROUP:OLDINT0D_ARB,\
 offset DGROUP:TSSINT0D_FVEC,	offset DGROUP:TSSINT0D_ARB,\
 offset DGROUP:OLDTSSINT0D_FVEC,offset DGROUP:OLDTSSINT0D_ARB,\
 offset DGROUP:MSG_0DON,	offset DGROUP:MSG_OFF,\
 offset DGROUP:LCLPMG0D_FVEC,	offset DGROUP:LCLPMG0D_ARB,\
 offset DGROUP:OLDPMG0D_FVEC,	offset DGROUP:OLDPMG0D_ARB> ; INT 0Dh
TOGINT0E INTR_STR <1 shl 0Eh,0Eh,offset DGROUP:LCL_FLAG,@LCL_PAGE, @TRP_I0E, \
 offset DGROUP:LCLINT0E_FVEC,	offset DGROUP:LCLINT0E_ARB,\
 offset DGROUP:OLDINT0E_FVEC,	offset DGROUP:OLDINT0E_ARB,\
 offset DGROUP:TSSINT0E_FVEC,	offset DGROUP:TSSINT0E_ARB,\
 offset DGROUP:OLDTSSINT0E_FVEC,offset DGROUP:OLDTSSINT0E_ARB,\
 offset DGROUP:MSG_0EON,	offset DGROUP:MSG_OFF,\
 offset DGROUP:LCLPMG0E_FVEC,	offset DGROUP:LCLPMG0E_ARB,\
 offset DGROUP:OLDPMG0E_FVEC,	offset DGROUP:OLDPMG0E_ARB> ; INT 0Eh
TOGINT41 INTR_STR <0, 41h, offset DGROUP:LCL_FLAG, @LCL_I41, 0, \
 offset DGROUP:LCLINT41_FVEC,	offset DGROUP:LCLINT41_ARB,\
 offset DGROUP:OLDINT41_FVEC,	offset DGROUP:OLDINT41_ARB,\
 0,				0,			   \
 0,				0,			   \
 0,				0,			   \
 0,				0,			   \
 0,				0> ; INT 41h
TOGINT_CNT equ	($-TOGINT_TAB)/(type INTR_STR) ; # entries in the table

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP,ds:PGROUP

	public	@SWAT_TOG_PROG
@SWAT_TOG_PROG: 		; Mark module start in .MAP file

	extrn	SWATINI:tbyte
	include MAXDEV.INC

	extrn	IZITEOL:near
	extrn	PARSE_LVAL:near

	extrn	SAVE_IRQS:near
	extrn	REST_IRQS:near

	NPPROC	CMD_TOGINT -- Toggle Interrupt Interception Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Toggle interrupt interception command

TOGINT lval

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax,ecx,edx>	; Save registers

	call	IZITEOL 	; Izit end-of-the-line?
	je	near ptr CMD_TOGINT_SYNTERR ; Yes, so that's an error
CMD_TOGINT_NEXT:
	call	PARSE_LVAL	; Parse command line for lefthand value
	jc	near ptr CMD_TOGINT_ERR ; Jump if error
				; EAX = value
	cmp	eax,0FFFFh	; Izit too big?
	ja	short CMD_TOGINT_VALERR ; Jump if so

; Search for this interrupt # in our table

	mov	ecx,TOGINT_CNT	; Get # table entries
	lea	edx,TOGINT_TAB	; Get offset of start of table
@@:
	cmp	eax,DGROUP:[edx].INTR_NUMB ; Duzit match?
	je	short @F	; Jump if so

	add	edx,type INTR_STR ; Skip to next entry

	loop	@B		; Jump if more entries

	jmp	short CMD_TOGINT_VALERR ; Join common error code


@@:
	call	ACT_TOGINT	; Toggle an interrupt intercept

; See if there's more on the line

	call	IZITEOL 	; Izit end-of-the-line?
	jne	short CMD_TOGINT_NEXT ; No, so that's an error

	or	LCL_FLAG,@LCL_REDI ; Mark as forced re-display of screen

	clc			; Indicate all went well

	jmp	short CMD_TOGINT_EXIT ; Join common exit code


CMD_TOGINT_VALERR:
	mov	MSGOFF,offset DGROUP:VALERR ; Save offset of error message
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	jmp	short CMD_TOGINT_ERR ; Join common error exit code


CMD_TOGINT_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

;;;;;;; jmp	short CMD_TOGINT_ERR ; Join common error exit code


CMD_TOGINT_ERR:
	stc			; Mark as in error
CMD_TOGINT_EXIT:
	REGREST <edx,ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_TOGINT endp 		; End CMD_TOGINT procedure
	NPPROC	ACT_TOGINT -- Toggle An Interrupt Intercept
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Toggle an interrupt intercept

On entry:

DGROUP:EDX ==>	TOGINTxx table entry
SS:EBP	==>	FORW_STR

|

	pushad			; Save registers

	pushfd			; Save flags
	cli			; Nobody move as our interrupts are not active

	call	REST_IRQS	; Restore original IRQ-specific interrupt
				; handlers
	mov	ecx,DGROUP:[edx].INTR_NUMB ; Get the interrupt #

; If we're in device SWAT, toggle the @TRP_Ixx bit

	test	[ebp].FORW_EFL,mask $R2 ; Izit device load?
	jz	short @F	; Jump if not

	cmp	DGROUP:[edx].INTR_RMSK,0 ; No bit to toggle?
	je	short @F	; Jump if so

	push	DGROUP:[edx].INTR_RMSK ; Pass bit to toggle
	call	TOGGLE_TRP	; Toggle the @TRP_Ixx bit

; If we're in Windows, toggle the IDT entries, too

	test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
	jz	near ptr ACT_TOGINT_TRP  ; Jump if not
@@:
	mov	ebx,[ebp-@BPBACK].BACK_IDT.DTR_BASE ; Get IDTR base

	cmp	TSS_CNT,0	; Are we using TSSs?
	jne	near ptr ACT_TOGINT_TSS ; Jump if so

	mov	edi,DGROUP:[edx].INTR_DOFF ; Get offset in DGROUP of flag dword
	mov	eax,DGROUP:[edx].INTR_DMSK ; Get mask

	test	eax,DGROUP:[edi] ; Check state
	jnz	near ptr ACT_TOGINT1 ; Jump if currently intercepted

	cmp	IntMode,@IMODE_PMG ; Doing PM Interrupt Gates?
	jne	short @F	; Jump if not

	TOGIDTMAC ecx,PLCG,POLG ; IDT to OLG, LCG to IDT (EAX/ESI/EDI clobbered)

	jmp	ACT_TOGINT2	; Join common code


@@:
	TOGIDTMAC ecx,PLCL,POLD ; IDT to OLD, LCL to IDT (EAX/ESI/EDI clobbered)

	jmp	short ACT_TOGINT2 ; Join common code


ACT_TOGINT1:
	cmp	IntMode,@IMODE_PMG ; Doing PM Interrupt Gates?
	jne	short @F	; Jump if not

	TOGIDTMAC ecx,POLG	; OLG to IDT (EAX/ESI/EDI clobbered)

	jmp	short ACT_TOGINT2 ; Join common code


@@:
	TOGIDTMAC ecx,POLD	; OLD to IDT (EAX/ESI/EDI clobbered)
ACT_TOGINT2:
ACT_TOGINT_TRP:
	mov	edi,DGROUP:[edx].INTR_DOFF ; Get offset in DGROUP of flag dword
	mov	eax,DGROUP:[edx].INTR_DMSK ; Get mask

	xor	DGROUP:[edi],eax ; Toggle state

	jmp	short ACT_TOGINT_EXIT ; Join common exit code


ACT_TOGINT_TSS:
	cmp	ecx,32		; Izit too big?
	jae	short ACT_TOGINT_EXIT ; Jump if so

	btc	TSSINT_FLAG,ecx ; Izit already intercepted?
	jc	short ACT_TOGINT_TSS1 ; Jump if so

	TOGIDTMAC ecx,PTSS,POLDTSS ; IDT to OLDTSS, TSS to IDT (EAX/ESI/EDI clobbered)

	jmp	short ACT_TOGINT_TSS2 ; Join common code


ACT_TOGINT_TSS1:
	TOGIDTMAC ecx,POLDTSS	; OLDTSS to IDT (EAX/ESI/EDI clobbered)
ACT_TOGINT_TSS2:
ACT_TOGINT_EXIT:
	call	SAVE_IRQS	; Save original IRQ-specific interrupt handlers,
				; install ours
	popfd			; Restore flags (in particular IF)

	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_TOGINT endp 		; End ACT_TOGINT procedure
	NPPROC	TOGGLE_TRP -- Toggle The @TRP_Ixx Bit
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Toggle the @TRP_Ixx bit

|

TOGGLE_TRP_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
TOGGLE_TRP_FLG dd ?		; @TRP_Ixx bit to toggle

TOGGLE_TRP_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ebx>	; Save registers

	movzx	ebx,RGRSEG2	; Get the (relocated) segment of RGROUP
	shl	ebx,4-0 	; Convert from paras to bytes

	mov	eax,[ebp].TOGGLE_TRP_FLG ; Get the @TRP_Ixx flag

	assume	gs:RGROUP	; Tell a white lie to get addressibility
	xor	TRP_FLAG[ebx],eax ; Toggle the bit
	assume	gs:AGROUP	; Retract nose

	REGREST <ebx,eax>	; Restore

	pop	ebp		; Restore

	ret	(type TOGGLE_TRP_FLG) ; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TOGGLE_TRP endp 		; End TOGGLE_TRP procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_TOG module
