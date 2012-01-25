;' $Header:   P:/PVCS/386SWAT/SWAT_DBG.ASV   1.20   10 Jul 1997 14:46:24   BOB  $
	title	SWAT_DBG -- 386SWAT Debug Register Functions
	page	58,122
	name	SWAT_DBG

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-1999 Qualitas, Inc.  All rights reserved.

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
	include OPCODES.INC
	include ALLMEM.INC
	include IOPBITS.INC
	include MOVSPR.INC
	include CPUFET.INC

	include SWAT_COM.INC
	include SWAT_CMD.INC
	include SWAT_DBG.INC
	include SWAT_MOD.INC
	include SWAT_SEG.INC
.list

DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	DBGATTR:byte

	extrn	CPUFET_FLAG:dword

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	CUR_INSTR_ARW:word
	extrn	UNASEL:word
	extrn	UNABASE:dword
	extrn	UNAMODE:word

	extrn	MSGOFF:dword
	extrn	SYNTERR:byte
	extrn	BDREGERR:byte
	extrn	BCREGERR:byte
	extrn	BPREGERR:byte
	extrn	ROMERR:byte

	extrn	SAVE_DR7:dword
	extrn	DSP_STATE:byte

	extrn	SELFDBG:dword

; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Code breakpoint data values
; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

	public	BCDATA,BREAKPT1,BREAKPT2,BREAKPT3,BREAKPT4
BCDATA	BC_STR	@NBC dup (<>)	; Breakpoint code data
BREAKPT1 BC_STR <>		; MUST follow BCDATA for single-skip BP
BREAKPT2 BC_STR <>		; ...
BREAKPT3 BC_STR <>		; ...
BREAKPT4 BC_STR <>		; ...
@NBCX	equ	($-BCDATA)/(type BC_STR) ; # BPs including extras

	public	W_BC
W_BC	W_STR	<>		; Temporary window structure

	public	BC_WIN
BC_WIN	db		  'ีออออออออออออออออออออออออออออออออออออออออออออออออออออธ'
NBCCOLS equ	$-BC_WIN        ; # cols in BC window
BC_LN1	db	@NBC dup ('ณ ? BC? = ____?________ = ________ (__)              ณ')
	db		  'รฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤด'
	db		  'ณ BC   to display                                    ณ'
	db		  'ณ BC*  to clear all         BC* addr to clear addr   ณ'
	db		  'ณ BC+  to enable all        BC+ addr to enable addr  ณ'
	db		  'ณ BC-  to disable all       BC- addr to disable addr ณ'
	db		  'ณ Use BCn*,  BCn+,   BCn-   where n ๎ {0..7} to      ณ'
	db		  'ณ     clear, enable, disable the nth BC              ณ'
	db		  'ิออออออออออออออออออออออออออออออออออออออออออออออออออออพ'
NBCROWS equ	($-BC_WIN)/NBCCOLS ; # rows in BC window

BC_WIN_EN0 equ	2		; Offset from BC_LN1 to enable/disable flag
BC_WIN_IN0 equ	6		; ...			index
BC_WIN_SL0 equ	10		; ...			selector
BC_WIN_SP0 equ	14		; ...			separator
BC_WIN_OF0 equ	15		; ...			offset
BC_WIN_BC0 equ	26		; ...			register
BC_WIN_VL0 equ	36		; ...			value


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Page breakpoint data values
; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

	align	4		; Ensure dword-aligned

	public	BPDATA
BPDATA	BP_STR	@NBP dup (<>)	; Breakpoint page data

	public	W_BP
W_BP	W_STR	<>		; Temporary window structure

	public	BP_WIN
BP_WIN	db		  'ีออออออออออออออออออออออออออออออออออออออออออออออออออออธ'
NBPCOLS equ	$-BP_WIN        ; # cols in BP window
BP_LN1	db	@NBP dup ('ณ ? BP? = ____?________ = ________                   ณ')
	db		  'รฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤด'
	db		  'ณ BP   to display                                    ณ'
	db		  'ณ BP*  to clear all         BP* addr to clear addr   ณ'
	db		  'ณ BP+  to enable all        BP+ addr to enable addr  ณ'
	db		  'ณ BP-  to disable all       BP- addr to disable addr ณ'
	db		  'ณ Use BPn*,  BPn+,   BPn-   where n ๎ {0..7} to      ณ'
	db		  'ณ     clear, enable, disable the nth BP              ณ'
	db		  'ิออออออออออออออออออออออออออออออออออออออออออออออออออออพ'
NBPROWS equ	($-BP_WIN)/NBPCOLS ; # rows in BP window

BP_WIN_EN0 equ	2		; Offset from BP_LN1 to enable/disable flag
BP_WIN_IN0 equ	6		; ...			index
BP_WIN_SL0 equ	10		; ...			selector
BP_WIN_SP0 equ	14		; ...			separator
BP_WIN_OF0 equ	15		; ...			offset
BP_WIN_BC0 equ	26		; ...			register


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Debug register data values
; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

	align	4		; Ensure dword-aligned

@BD_L1	equ	00b		; Length 1
@BD_L2	equ	01b		; Length 2
;;;	equ	10b		; Reserved
@BD_L4	equ	11b		; Length 4
@BD_X	equ	00b		; Instruction fetches
@BD_W	equ	01b		; Data writes
@BD_IO	equ	10b		; I/O reads/writes (P5 only)
@BD_RW	equ	11b		; Data reads/writes, not fetches

	public	BDCMD,BDREGS
BDCMD	BD_STR	<>		; Command line values
BDREGS	BD_STR	<?,0,0,0,0,0,?,?,$RW0,$L0,offset PGROUP:CMD_BDSET0> ; DR0
	BD_STR	<?,0,0,0,0,0,?,?,$RW1,$L1,offset PGROUP:CMD_BDSET1> ; DR1
	BD_STR	<?,0,0,0,0,0,?,?,$RW2,$L2,offset PGROUP:CMD_BDSET2> ; DR2
	BD_STR	<?,0,0,0,0,0,?,?,$RW3,$L3,offset PGROUP:CMD_BDSET3> ; DR3

	public	W_BD
W_BD	W_STR	<>		; Temporary window structure

	public	BDMON
BDMON	db	0		; Bit flags for BD monitor expressions
				; Same as four low-order bits of DR6, $B0-$B3

	public	BDTYPES,BDLENS
BDTYPES db	'X W IORW'
BDLENS	db	'12?4'

	public	DBG_WIN
DBG_WIN db	'ีอออออออออออออออออออออออออออออออออออออออออออออออออธ'
NDBGCOLS equ	$-DBG_WIN       ; # cols in debug window
DBG_LN1 db	'ณ ? DR0 = ____?________ = ________   L1   X       ณ'
	db	'ณ ? DR1 = ____?________ = ________   L1   X       ณ'
	db	'ณ ? DR2 = ____?________ = ________   L1   X       ณ'
	db	'ณ ? DR3 = ____?________ = ________   L1   X       ณ'
DBG_DR6 db	'ณ DR6 = ________                                  ณ'
DBG_DR7 db	'ณ DR7 = ________                                  ณ'
;;;;;;; db	'ณ DR7 = ________ GD GE LE G3 L3 G2 L2 G1 L1 G0 L0 ณ'
	db	'รฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤด'
	db	'ณ BD   to display                                 ณ'
	db	'ณ BD*  to clear all         BDn*  to clear DRn    ณ'
	db	'ณ BD+  to enable all        BDn+  to enable DRn   ณ'
	db	'ณ BD-  to disable all       BDn-  to disable DRn  ณ'
	db	'ิอออออออออออออออออออออออออออออออออออออออออออออออออพ'
NDBGROWS equ	($-DBG_WIN)/NDBGCOLS ; # rows in debug window

DBG_WIN_EN0 equ   2		; Offset from DBG_LN1 to enable/disable flag
DBG_WIN_SL0 equ 10		; ...			 selector
DBG_WIN_SP0 equ 14		; ...			 separator
DBG_WIN_OF0 equ 15		; ...			 offset
DBG_WIN_DR0 equ 26		; ...			 register
DBG_WIN_LN0 equ 38		; ...			 length
DBG_WIN_TP0 equ 42		; ...			 type

DBG_DR6_REG equ 08		; ...	      DBG_DR6 to DR6
DBG_DR6_BT  equ 20		; ...			 BT flag
DBG_DR6_BS  equ 23		; ...			 BS
DBG_DR6_BD  equ 26		; ...			 BD

DBG_DR6_B3  equ 29		; ...			 B3
DBG_DR6_B2  equ 32		; ...			 B2
DBG_DR6_B1  equ 35		; ...			 B1
DBG_DR6_B0  equ 38		; ...			 B0

DBG_DR7_REG equ 08		; ...	      DBG_DR7 to DR7
DBG_DR7_GD  equ 17		; ...			 GD flag
DBG_DR7_GE  equ 20		; ...			 GE
DBG_DR7_LE  equ 23		; ...			 LE
DBG_DR7_G3  equ 26		; ...			 G3
DBG_DR7_L3  equ 29		; ...			 L3
DBG_DR7_G2  equ 32		; ...			 G2
DBG_DR7_L2  equ 35		; ...			 L2
DBG_DR7_G1  equ 38		; ...			 G1
DBG_DR7_L1  equ 41		; ...			 L1
DBG_DR7_G0  equ 44		; ...			 G0
DBG_DR7_L0  equ 47		; ...			 L0

@ANYGL	equ	(mask $G0) or (mask $L0) or (mask $G1) or (mask $L1) or (mask $G2) or (mask $L2) or (mask $G3) or (mask $L3)

	public	CHECK_DBG_RES
CHECK_DBG_RES db 0		; Result of last call to CHECK_DBG

	public	BREAKLIST_CNT,BREAKLIST
	align	4
BREAKLIST_CNT dd 0		; Entries in breakpoint list
BREAKLIST dd	4+@NBC dup (?)	; List to search for active breakpoints

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP

	extrn	CMD_WHITE:near
	extrn	WPUT_CSA:near
	extrn	BIN2DIGIT:near
	extrn	BIN2BYTE:near
	extrn	BIN2WORD:near
	extrn	BIN2DWORD:near
	extrn	U32_LOWERCASE:near
	extrn	PARSE_ADDR:near
	extrn	SET_STATE:near

	extrn	INST_OPR0E:near
	extrn	REST_OPR0E:near

	extrn	GETBASE:near

	NPPROC	CMD_BCCLR -- Breakpoint Code Clear Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Breakpoint code clear command

BC*		Clear all code breakpoints
BCn*		Clear #n code breakpoint (parsed in CMD_BC0TO7)
BC* addr	Clear ones which match this address

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save registers

	inc	esi		; Skip over the '*'

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_BCCLR_ALL ; Yes, treat as clear all

	call	PARSE_ADDR	; Parse DS:ESI for address
	jc	near ptr CMD_BCCLR_SYNTERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

; Ensure there's nothing else on the line

	cmp	ds:[esi].LO,0	; Izit end-of-the-line?
	jne	near ptr CMD_BCCLR_SYNTERR ; Jump if not

; See if this duplicates an existing value in BCDATA

; Fill in segment/selector/mode if no separator specified

	test	cx,@ADDR_SEP	; Izit specified?
	jnz	short @F	; Yes, BX is valid

	mov	bx,UNASEL	; Get segment/selector of current instr
	mov	edx,UNABASE	; Get base of the current instr

	test	UNAMODE,@MODE_VM ; Izit VM86 mode?
	jnz	short @F	; Jump if so

	or	cx,@ADDR_PM	; Mark as PM
@@:

; Loop through the BCDATA structure looking for a match

	mov	si,cx		; Copy flags
	mov	ecx,@NBC	; Get # code breakpoints
	xor	edi,edi 	; Initialize index into BCDATA
CMD_BCCLR_NEXT:
	test	BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short CMD_BCCLR_LOOP ; Jump if not

	cmp	bx,BCDATA[edi].BC_SEL ; Same segment/selector?
	jne	short CMD_BCCLR_LOOP ; Jump if not

	cmp	eax,BCDATA[edi].BC_OFF ; Same offset?
	jne	short CMD_BCCLR_LOOP ; Jump if not

	mov	dx,si		; Copy flags
	xor	dx,BCDATA[edi].BC_FLAG ; Check for same mode

	test	dx,@ADDR_PM	; Izit the same mode?
	jnz	short CMD_BCCLR_LOOP ; Jump if not

	and	BCDATA[edi].BC_FLAG,not @ADDR_INUSE ; Mark as no longer in use
CMD_BCCLR_LOOP:
	add	edi,size BC_STR ; Skip to next entry

	loop	CMD_BCCLR_NEXT	; Jump if more entries

	jmp	CMD_BCCLR_CLC	; Join common OK code


; Clear code breakpoint #n

CMD_BCCLRN macro NN

	public	CMD_BCCLR&NN
CMD_BCCLR&NN:
	and	BCDATA[&NN*(type BC_STR)].BC_FLAG,not @ADDR_INUSE ; Mark as no longer in use

	jmp	short CMD_BCCLRN_COM ; Join common code

	endm			; End CMD_BCCLRN macro


	public	CMD_BCCLRN_COM
CMD_BCCLRN_COM:
	cmp	DSP_STATE,@DSP_BC ; Displaying BC values?
	je	short @F	; Yes

	call	DISP_BC 	; Display 'em
@@:
	call	UD_BREAKLIST	; Update breakpoint list for display
	clc			; Incidate all went well

	ret			; Return to caller


	CMD_BCCLRN 0
	CMD_BCCLRN 1
	CMD_BCCLRN 2
	CMD_BCCLRN 3
	CMD_BCCLRN 4
	CMD_BCCLRN 5
	CMD_BCCLRN 6
	CMD_BCCLRN 7


; Clear all code breakpoints

CMD_BCCLR_ALL:
	mov	ecx,@NBC	; Get # code breakpoints
	xor	edi,edi 	; Initialize index into BCDATA
CMD_BCCLR_NEXT2:

; Mark as disabled and no longer in use

	and	BCDATA[edi].BC_FLAG,not (@ADDR_INUSE or @ADDR_ENA)
	add	edi,size BC_STR ; Skip to next entry

	loop	CMD_BCCLR_NEXT2 ; Jump if more entries
CMD_BCCLR_CLC:
	cmp	DSP_STATE,@DSP_BC ; Displaying BC values?
	je	short @F	; Yes

	call	DISP_BC 	; Display 'em
@@:
	call	UD_BREAKLIST	; Update breakpoint list for display
	clc			; Incidate all went well

	jmp	short CMD_BCCLR_EXIT ; Join common exit code

CMD_BCCLR_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Indicate something went wrong
CMD_BCCLR_EXIT:
	REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BCCLR endp			; End CMD_BCCLR procedure
	NPPROC	CMD_BCENA -- Breakpoint Code Enable Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Breakpoint code enable command

BC+		Enable all code breakpoints
BCn+		Enable #n code breakpoint (parsed in CMD_BC0TO7)
BC+ addr	Enable ones which match this address

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save registers

	inc	esi		; Skip over the '+'

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_BCENA_ALL ; Yes, treat as clear all

	call	PARSE_ADDR	; Parse DS:ESI for address
	jc	near ptr CMD_BCENA_SYNTERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

; Ensure there's nothing else on the line

	cmp	ds:[esi].LO,0	; Izit end-of-the-line?
	jne	near ptr CMD_BCENA_SYNTERR ; Jump if not

; See if this duplicates an existing value in BCDATA

; Fill in segment/selector/mode if no separator specified

	test	cx,@ADDR_SEP	; Izit specified?
	jnz	short @F	; Yes, BX is valid

	mov	bx,UNASEL	; Get segment/selector of current instr
	mov	edx,UNABASE	; Get base of the current instr

	test	UNAMODE,@MODE_VM ; Izit VM86 mode?
	jnz	short @F	; Jump if so

	or	cx,@ADDR_PM	; Mark as PM
@@:

; Loop through the BCDATA structure looking for a match

	mov	si,cx		; Copy flags
	mov	ecx,@NBC	; Get # code breakpoints
	xor	edi,edi 	; Initialize index into BCDATA
CMD_BCENA_NEXT:
	test	BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short CMD_BCENA_LOOP ; Jump if not

	cmp	bx,BCDATA[edi].BC_SEL ; Same segment/selector?
	jne	short CMD_BCENA_LOOP ; Jump if not

	cmp	eax,BCDATA[edi].BC_OFF ; Same offset?
	jne	short CMD_BCENA_LOOP ; Jump if not

	mov	dx,si		; Copy flags
	xor	dx,BCDATA[edi].BC_FLAG ; Check for same mode

	test	dx,@ADDR_PM	; Izit the same mode?
	jnz	short CMD_BCENA_LOOP ; Jump if not

	or	BCDATA[edi].BC_FLAG,@ADDR_ENA ; Mark as enabled
CMD_BCENA_LOOP:
	add	edi,size BC_STR ; Skip to next entry

	loop	CMD_BCENA_NEXT	; Jump if more entries

	jmp	CMD_BCENA_CLC	; Join common OK code


; Enable code breakpoint #n

CMD_BCENAN macro NN

	public	CMD_BCENA&NN
CMD_BCENA&NN:
	or	BCDATA[&NN*(type BC_STR)].BC_FLAG,@ADDR_ENA ; Mark as enabled

	jmp	short CMD_BCENAN_COM ; Join common code

	endm			; End CMD_BCENAN macro


	public	CMD_BCENAN_COM
CMD_BCENAN_COM:
	cmp	DSP_STATE,@DSP_BC ; Displaying BC values?
	je	short @F	; Yes

	call	DISP_BC 	; Display 'em
@@:
	call	UD_BREAKLIST	; Update breakpoint list for display
	clc			; Incidate all went well

	ret			; Return to caller


	CMD_BCENAN 0
	CMD_BCENAN 1
	CMD_BCENAN 2
	CMD_BCENAN 3
	CMD_BCENAN 4
	CMD_BCENAN 5
	CMD_BCENAN 6
	CMD_BCENAN 7


; Enable all code breakpoints

CMD_BCENA_ALL:
	mov	ecx,@NBC	; Get # code breakpoints
	xor	edi,edi 	; Initialize index into BCDATA
CMD_BCENA_NEXT2:
	test	BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short @F	; Jump if not

	or	BCDATA[edi].BC_FLAG,@ADDR_ENA ; Mark as enabled
@@:
	add	edi,size BC_STR ; Skip to next entry

	loop	CMD_BCENA_NEXT2 ; Jump if more entries
CMD_BCENA_CLC:
	cmp	DSP_STATE,@DSP_BC ; Displaying BC values?
	je	short @F	; Yes

	call	DISP_BC 	; Display 'em
@@:
	call	UD_BREAKLIST	; Update breakpoint list for display
	clc			; Incidate all went well

	jmp	short CMD_BCENA_EXIT ; Join common exit code

CMD_BCENA_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Indicate something went wrong
CMD_BCENA_EXIT:
	REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BCENA endp			; End CMD_BCENA procedure
	NPPROC	CMD_BCDIS -- Breakpoint Code Disable Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Breakpoint code disable command

BC-		Disable all code breakpoints
BCn-		Disable #n code breakpoint (parsed in CMD_BC0TO7)
BC- addr	Disable ones which match this address

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save registers

	inc	esi		; Skip over the '-'

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_BCDIS_ALL ; Yes, treat as clear all

	call	PARSE_ADDR	; Parse DS:ESI for address
	jc	near ptr CMD_BCDIS_SYNTERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

; Ensure there's nothing else on the line

	cmp	ds:[esi].LO,0	; Izit end-of-the-line?
	jne	near ptr CMD_BCDIS_SYNTERR ; Jump if not

; See if this duplicates an existing value in BCDATA

; Fill in segment/selector/mode if no separator specified

	test	cx,@ADDR_SEP	; Izit specified?
	jnz	short @F	; Yes, BX is valid

	mov	bx,UNASEL	; Get segment/selector of current instr
	mov	edx,UNABASE	; Get base of the current instr

	test	UNAMODE,@MODE_VM ; Izit VM86 mode?
	jnz	short @F	; Jump if so

	or	cx,@ADDR_PM	; Mark as PM
@@:

; Loop through the BCDATA structure looking for a match

	mov	si,cx		; Copy flags
	mov	ecx,@NBC	; Get # code breakpoints
	xor	edi,edi 	; Initialize index into BCDATA
CMD_BCDIS_NEXT:
	test	BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short CMD_BCDIS_LOOP ; Jump if not

	cmp	bx,BCDATA[edi].BC_SEL ; Same segment/selector?
	jne	short CMD_BCDIS_LOOP ; Jump if not

	cmp	eax,BCDATA[edi].BC_OFF ; Same offset?
	jne	short CMD_BCDIS_LOOP ; Jump if not

	mov	dx,si		; Copy flags
	xor	dx,BCDATA[edi].BC_FLAG ; Check for same mode

	test	dx,@ADDR_PM	; Izit the same mode?
	jnz	short CMD_BCDIS_LOOP ; Jump if not

	and	BCDATA[edi].BC_FLAG,not @ADDR_ENA ; Mark as disabled
CMD_BCDIS_LOOP:
	add	edi,size BC_STR ; Skip to next entry

	loop	CMD_BCDIS_NEXT	; Jump if more entries

	jmp	CMD_BCDIS_CLC	; Join common OK code


; Disable code breakpoint #n

CMD_BCDISN macro NN

	public	CMD_BCDIS&NN
CMD_BCDIS&NN:
	and	BCDATA[&NN*(type BC_STR)].BC_FLAG,not @ADDR_ENA ; Mark as disabled

	jmp	short CMD_BCDISN_COM ; Join common code

	endm			; End CMD_BCDISN macro


	public	CMD_BCDISN_COM
CMD_BCDISN_COM:
	cmp	DSP_STATE,@DSP_BC ; Displaying BC values?
	je	short @F	; Yes

	call	DISP_BC 	; Display 'em
@@:
	call	UD_BREAKLIST	; Update breakpoint list for display
	clc			; Incidate all went well

	ret			; Return to caller


	CMD_BCDISN 0
	CMD_BCDISN 1
	CMD_BCDISN 2
	CMD_BCDISN 3
	CMD_BCDISN 4
	CMD_BCDISN 5
	CMD_BCDISN 6
	CMD_BCDISN 7


; Disable all code breakpoints

CMD_BCDIS_ALL:
	mov	ecx,@NBC	; Get # code breakpoints
	xor	edi,edi 	; Initialize index into BCDATA
CMD_BCDIS_NEXT2:
	test	BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short @F	; Jump if not

	and	BCDATA[edi].BC_FLAG,not @ADDR_ENA ; Mark as disabled
@@:
	add	edi,size BC_STR ; Skip to next entry

	loop	CMD_BCDIS_NEXT2 ; Jump if more entries
CMD_BCDIS_CLC:
	cmp	DSP_STATE,@DSP_BC ; Displaying BC values?
	je	short @F	; Yes

	call	DISP_BC 	; Display 'em
@@:
	call	UD_BREAKLIST	; Update breakpoint list for display
	clc			; Incidate all went well

	jmp	short CMD_BCDIS_EXIT ; Join common exit code

CMD_BCDIS_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Indicate something went wrong
CMD_BCDIS_EXIT:
	REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BCDIS endp			; End CMD_BCDIS procedure
	NPPROC	CMD_BCSET -- Breakpoint Code Set Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Breakpoint code set command

BC* opt_addr
BC+ opt_addr
BC- opt_addr

BC		 Display all code breakpoints
BC addr 	 Set one at this address

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

; Split off cases for clear, enable, and disable

	cmp	DGROUP:[esi].LO,'*' ; Izit clear?
	je	near ptr CMD_BCCLR ; Jump if so

	cmp	DGROUP:[esi].LO,'+' ; Izit enable?
	je	near ptr CMD_BCENA ; Jump if so

	cmp	DGROUP:[esi].LO,'-' ; Izit disable?
	je	near ptr CMD_BCDIS ; Jump if so

	REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save registers

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_BCSET_DISP ; Yes, treat as display all

	call	PARSE_ADDR	; Parse DS:ESI for address
	jc	near ptr CMD_BCSET_SYNTERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

; Ensure there's nothing else on the line

	cmp	ds:[esi].LO,0	; Izit end-of-the-line?
	jne	near ptr CMD_BCSET_SYNTERR ; Jump if not

; See if this duplicates an existing value in BCDATA

; Fill in segment/selector/mode if no separator specified

	test	cx,@ADDR_SEP	; Izit specified?
	jnz	short CMD_BCSET1 ; Yes, BX is valid

	mov	bx,UNASEL	; Get segment/selector of current instr
	mov	edx,UNABASE	; Get base of the current instr

	test	UNAMODE,@MODE_VM ; Izit VM86 mode?
	jnz	short CMD_BCSET1 ; Jump if so

	or	cx,@ADDR_PM	; Mark as PM
CMD_BCSET1:

; Loop through the BCDATA structure looking for a match

	mov	si,cx		; Copy flags
	mov	ecx,@NBC	; Get # code breakpoints
	xor	edi,edi 	; Initialize index into BCDATA
CMD_BCSET_NEXT:
	test	BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short CMD_BCSET_LOOP ; Jump if not

	cmp	bx,BCDATA[edi].BC_SEL ; Same segment/selector?
	jne	short CMD_BCSET_LOOP ; Jump if not

	cmp	eax,BCDATA[edi].BC_OFF ; Same offset?
	jne	short CMD_BCSET_LOOP ; Jump if not

	xor	si,BCDATA[edi].BC_FLAG ; Check for same mode

	test	si,@ADDR_PM	; Izit the same mode?
	jnz	short CMD_BCSET_LOOP0 ; Jump if not

; Enable it, save new original value, exit

	xor	si,BCDATA[edi].BC_FLAG ; Restore original flags
	or	si,@ADDR_ENA	; Mark as enabled
	mov	BCDATA[edi].BC_FLAG,si ; Mark as enabled, etc.

	add	eax,edx 	; Add offset and base to get linear address
	mov	BCDATA[edi].BC_LIN,eax ; Save as new linear address

	mov	al,AGROUP:[eax] ; Get new original value
	mov	BCDATA[edi].BC_VAL,al ; Save as new original value

	jmp	short CMD_BCSET_CLC ; Join common OK code

CMD_BCSET_LOOP0:
	xor	si,BCDATA[edi].BC_FLAG ; Restore original flags
CMD_BCSET_LOOP:
	add	edi,size BC_STR ; Skip to next entry

	loop	CMD_BCSET_NEXT	; Jump if more entries

; No match found, insert a new one

; Look for a free entry

	mov	ecx,@NBC	; Get # code breakpoints
	xor	edi,edi 	; Initialize index into BCDATA
CMD_BCSET_NEXT2:
	test	BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	jnz	short CMD_BCSET_LOOP2 ; Jump if so

; Test the linear address to verify that it is not ROM

	REGSAVE <eax,edx>	; Save registers

	add	eax,edx 	; Add offset and base to get linear address
	mov	dl,@OPCOD_INT3	; Get opcode of breakpoint interrupt instruction

	xchg	AGROUP:[eax],dl ; Swap bytes to set breakpoint
	cmp	AGROUP:[eax].LO,@OPCOD_INT3 ; Did the write to memory stick?
				; ZF is significant

	xchg	AGROUP:[eax],dl ; Swap 'em back

	REGREST <edx,eax>	; Restore registers
	jne	short CMD_BCSET_ROMERR ; Jump if breakpoint won't stick

; Mark as in use, enabled, save new original value, and exit

	or	si,@ADDR_INUSE or @ADDR_ENA ; Mark it
	mov	BCDATA[edi].BC_FLAG,si ; Save flags

	mov	BCDATA[edi].BC_OFF,eax ; Save offset
	mov	BCDATA[edi].BC_SEL,bx ; ... segment/selector

	add	eax,edx 	; Add offset and base to get linear address
	mov	BCDATA[edi].BC_LIN,eax ; Save as new linear address

	mov	al,AGROUP:[eax] ; Get new original value
	mov	BCDATA[edi].BC_VAL,al ; Save as new original value

	jmp	short CMD_BCSET_CLC ; Join common OK code

CMD_BCSET_LOOP2:
	add	edi,size BC_STR ; Skip to next entry

	loop	CMD_BCSET_NEXT2 ; Jump if more entries

; No free entries found

	mov	MSGOFF,offset DGROUP:BCREGERR ; Save offset of error message

	jmp	short CMD_BCSET_ERR ; Join common error code

; The breakpoint is into ROM

CMD_BCSET_ROMERR:
	mov	MSGOFF,offset DGROUP:ROMERR ; Save offset of error message

	jmp	short CMD_BCSET_ERR ; Join common error exit code

; Display all code breakpoints

CMD_BCSET_CLC:
	cmp	DSP_STATE,@DSP_BC ; Displaying BC values?
	jne	short @F	; No
CMD_BCSET_DISP:
	call	DISP_BC 	; Display 'em
@@:
	call	UD_BREAKLIST	; Update breakpoint list for display
	clc			; Incidate all went well

	jmp	short CMD_BCSET_EXIT ; Join common exit code

CMD_BCSET_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
CMD_BCSET_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Indicate something went wrong
CMD_BCSET_EXIT:
	REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BCSET endp			; End CMD_BCSET procedure
	NPPROC	CMD_BC0TO7 -- Code Registers Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Code Register BC0-7 clear, enable, disable commands

BC0*	BC0+	BC0-
BC1*	BC1+	BC1-
BC2*	BC2+	BC2-
BC3*	BC3+	BC3-
BC4*	BC4+	BC4-
BC5*	BC5+	BC5-
BC6*	BC6+	BC6-
BC7*	BC7+	BC7-

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

BCN_MAC macro	NN

	public	CMD_BC&NN
CMD_BC&NN:
	inc	esi		; Skip over the next symbol

	cmp	DGROUP:[esi-1].LO,'*' ; Izit clear?
	je	near ptr CMD_BCCLR&NN ; Jump if so

	cmp	DGROUP:[esi-1].LO,'+' ; Izit enable?
	je	near ptr CMD_BCENA&NN ; Jump if so

	cmp	DGROUP:[esi-1].LO,'-' ; Izit disable?
	je	near ptr CMD_BCDIS&NN ; Jump if so

	jmp	CMD_BC0TO7_SYNTERR ; Jump if none of the above

	endm			; End BCN_MAC macro

; Split off cases for clear, enable, and disable

	BCN_MAC 0
	BCN_MAC 1
	BCN_MAC 2
	BCN_MAC 3
	BCN_MAC 4
	BCN_MAC 5
	BCN_MAC 6
	BCN_MAC 7

CMD_BC0TO7_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BC0TO7 endp 		; End CMD_BC0TO7 procedure
	NPPROC	INST_BCVAL -- Install Code Breakpoint Values
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Install code breakpoint values

|

	REGSAVE <eax,ebx,ecx,edi> ; Save registers

	call	INST_OPR0E	; Install our local Page Fault handler

; Loop through BCDATA and swap original values with an INT 03h

	mov	ecx,@NBC	; Get # code breakpoints
	xor	edi,edi 	; Initialize index into BCDATA
INST_BCVAL_NEXT:
	test	BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short INST_BCVAL_LOOP ; Jump if not

	test	BCDATA[edi].BC_FLAG,@ADDR_ENA ; Izit enabled?
	jz	short INST_BCVAL_LOOP ; Jump if not

	mov	ebx,BCDATA[edi].BC_LIN ; Get linear address
	mov	al,@OPCOD_INT3  ; Get opcode of breakpoint interrupt instruction

; The next instruction might generate a Page Fault if the linear address
; of the original instruction is no longer valid, but it'll be skipped
; by the above-installed Page Fault handler.

	clc			; Assume no Page Fault
	xchg	al,AGROUP:[ebx] ; Swap with original value
	jc	short INST_BCVAL_ERR ; Jump if Page Fault

	mov	BCDATA[edi].BC_VAL,al ; Save as new original value

	jmp	short INST_BCVAL_LOOP ; Join common loop code

INST_BCVAL_ERR:
	and	BCDATA[edi].BC_FLAG,not @ADDR_ENA ; Mark as disabled
INST_BCVAL_LOOP:
	add	edi,size BC_STR ; Skip to next entry

	loop	INST_BCVAL_NEXT ; Jump if more entries

	call	REST_OPR0E	; Restore previous Page Fault handler

	REGREST <edi,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST_BCVAL endp 		; End INST_BCVAL procedure
	NPPROC	CHECK_BCVAL -- Check On Code Breakpoint Values
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

See if the current instruction matches an enabled breakpoint value.

On entry:

SS:EBP	==>	FORW_STR

On exit:

CF	=	1 if there's a match
	=	0 otherwise

|

	REGSAVE <eax,ebx,ecx,edx,edi> ; Save registers

; Loop through BCDATA and check the values

	mov	ecx,@NBC	; Get # code breakpoints
	xor	edi,edi 	; Initialize index into BCDATA
	mov	bx,[ebp].FORW_CS ; Get segment/selector of current instr
	mov	eax,[ebp].FORW_EIP ; Get offset of ...
	xor	dx,dx		; Clear the flags

	test	[ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	jnz	short @F	; Jump if so

	or	dx,@ADDR_PM	; Mark as PM

	test	CUR_INSTR_ARW.HI,mask $DTE_B ; Check for D-bit
	jnz	short CHECK_BCVAL_NEXT ; Jump if USE32
@@:
	movzx	eax,ax		; Zero high-order word
CHECK_BCVAL_NEXT:
	test	BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short CHECK_BCVAL_LOOP ; Jump if not

	test	BCDATA[edi].BC_FLAG,@ADDR_ENA ; Izit enabled?
	jz	short CHECK_BCVAL_LOOP ; Jump if not

	cmp	bx,BCDATA[edi].BC_SEL ; Same segment/selector?
	jne	short CHECK_BCVAL_LOOP ; Jump if not

	cmp	eax,BCDATA[edi].BC_OFF ; Same offset?
	jne	short CHECK_BCVAL_LOOP ; Jump if not

	xor	dx,BCDATA[edi].BC_FLAG ; Check for same mode

	test	dx,@ADDR_PM	; Izit the same mode?
	jnz	short @F	; Jump if not

	stc			; Indicate there's a match

	jmp	short CHECK_BCVAL_EXIT ; Join common exit code

@@:
	xor	dx,BCDATA[edi].BC_FLAG ; Restore original flags
CHECK_BCVAL_LOOP:
	add	edi,size BC_STR ; Skip to next entry

	loop	CHECK_BCVAL_NEXT ; Jump if more entries

	clc			; Indicate there's no match
CHECK_BCVAL_EXIT:
	REGREST <edi,edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_BCVAL endp		; End CHECK_BCVAL procedure
	NPPROC	REST_BCVAL -- Restore Original Code Breakpoint Values
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Restore original code breakpoint values

|

	REGSAVE <eax,ebx,ecx,edi> ; Save registers

	call	INST_OPR0E	; Install our local Page Fault handler

; Loop through BCDATA and restore original values

	mov	ecx,@NBCX	; Get # code breakpoints (plus extra BPs)
	xor	edi,edi 	; Initialize index into BCDATA
REST_BCVAL_NEXT:
	test	BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short REST_BCVAL_LOOP ; Jump if not

	test	BCDATA[edi].BC_FLAG,@ADDR_ENA ; Izit enabled?
	jz	short REST_BCVAL_LOOP ; Jump if not

	mov	ebx,BCDATA[edi].BC_LIN ; Get linear address

; The next instruction might generate a Page Fault if the linear address
; of the original instruction is no longer valid, but it'll be skipped
; by the above-installed Page Fault handler.

	clc			; Assume no Page Fault
	mov	al,AGROUP:[ebx] ; Get the value
	jc	short REST_BCVAL_ERR ; Jump if Page Fault

	cmp	al,@OPCOD_INT3	; Izit an INT 03h?
	jne	short REST_BCVAL_LOOP ; Jump if not

	mov	al,BCDATA[edi].BC_VAL ; Get original value
	mov	AGROUP:[ebx],al ; Restore it

	jmp	short REST_BCVAL_LOOP ; Join common loop code

REST_BCVAL_ERR:
	and	BCDATA[edi].BC_FLAG,not @ADDR_ENA ; Mark as disabled
REST_BCVAL_LOOP:
	add	edi,size BC_STR ; Skip to next entry

	loop	REST_BCVAL_NEXT ; Jump if more entries

; Clear the extra BP's in-use flags

	mov	ecx,@NBCX-@NBC	; Get # extra BPs
	xor	edi,edi 	; Initialize index into BREAKPTx
@@:
	and	BREAKPT1[edi].BC_FLAG,not @ADDR_INUSE ; Mark as no longer in use
	add	edi,size BC_STR ; Skip to next entry
	
	loop	@B		; Jump if more flags to clear

	call	REST_OPR0E	; Restore previous Page Fault handler

	REGREST <edi,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_BCVAL endp 		; End REST_BCVAL procedure
	NPPROC	CMD_BPCLR -- Breakpoint Page Clear Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Breakpoint page clear command

BP*		Clear all page breakpoints
BPn*		Clear #n page breakpoint (parsed in CMD_BP0TO7)
BP* addr	Clear ones which match this address

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save registers

	inc	esi		; Skip over the '*'

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_BPCLR_ALL ; Yes, treat as clear all

	call	PARSE_ADDR	; Parse DS:ESI for address
	jc	near ptr CMD_BPCLR_SYNTERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

; Ensure there's nothing else on the line

	cmp	ds:[esi].LO,0	; Izit end-of-the-line?
	jne	near ptr CMD_BPCLR_SYNTERR ; Jump if not

; See if this duplicates an existing value in BPDATA

; Fill in segment/selector/mode if no separator specified

	test	cx,@ADDR_SEP	; Izit specified?
	jnz	short @F	; Yes, BX is valid

	mov	bx,UNASEL	; Get segment/selector of current instr
	mov	edx,UNABASE	; Get base of the current instr

	test	UNAMODE,@MODE_VM ; Izit VM86 mode?
	jnz	short @F	; Jump if so

	or	cx,@ADDR_PM	; Mark as PM
@@:

; Loop through the BPDATA structure looking for a match

	mov	si,cx		; Copy flags
	mov	ecx,@NBP	; Get # page breakpoints
	xor	edi,edi 	; Initialize index into BpDATA
CMD_BPCLR_NEXT:
	test	BPDATA[edi].BP_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short CMD_BPCLR_LOOP ; Jump if not

	cmp	bx,BPDATA[edi].BP_SEL ; Same segment/selector?
	jne	short CMD_BPCLR_LOOP ; Jump if not

	cmp	eax,BPDATA[edi].BP_OFF ; Same offset?
	jne	short CMD_BPCLR_LOOP ; Jump if not

	mov	dx,si		; Copy flags
	xor	dx,BPDATA[edi].BP_FLAG ; Check for same mode

	test	dx,@ADDR_PM	; Izit the same mode?
	jnz	short CMD_BPCLR_LOOP ; Jump if not

	and	BPDATA[edi].BP_FLAG,not @ADDR_INUSE ; Mark as no longer in use
CMD_BPCLR_LOOP:
	add	edi,size BP_STR ; Skip to next entry

	loop	CMD_BPCLR_NEXT	; Jump if more entries

	jmp	CMD_BPCLR_CLC	; Join common OK code


; Clear page breakpoint #n

CMD_BPCLRN macro NN

	public	CMD_BPCLR&NN
CMD_BPCLR&NN:
	and	BPDATA[&NN*(type BP_STR)].BP_FLAG,not @ADDR_INUSE ; Mark as no longer in use

	jmp	short CMD_BPCLRN_COM ; Join common code

	endm			; End CMD_BPCLRN macro


	public	CMD_BPCLRN_COM
CMD_BPCLRN_COM:
	cmp	DSP_STATE,@DSP_BP ; Displaying BP values?
	je	short @F	; Yes

	call	DISP_BP 	; Display 'em
@@:
	clc			; Incidate all went well

	ret			; Return to caller


	CMD_BPCLRN 0
	CMD_BPCLRN 1
	CMD_BPCLRN 2
	CMD_BPCLRN 3
	CMD_BPCLRN 4
	CMD_BPCLRN 5
	CMD_BPCLRN 6
	CMD_BPCLRN 7


; Clear all page breakpoints

CMD_BPCLR_ALL:
	mov	ecx,@NBP	; Get # page breakpoints
	xor	edi,edi 	; Initialize index into BPDATA
CMD_BPCLR_NEXT2:

; Mark as disabled and no longer in use

	and	BPDATA[edi].BP_FLAG,not (@ADDR_INUSE or @ADDR_ENA)
	add	edi,size BP_STR ; Skip to next entry

	loop	CMD_BPCLR_NEXT2 ; Jump if more entries
CMD_BPCLR_CLC:
	cmp	DSP_STATE,@DSP_BP ; Displaying BP values?
	je	short @F	; Yes

	call	DISP_BP 	; Display 'em
@@:
	clc			; Incidate all went well

	jmp	short CMD_BPCLR_EXIT ; Join common exit code

CMD_BPCLR_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Indicate something went wrong
CMD_BPCLR_EXIT:
	REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BPCLR endp			; End CMD_BPCLR procedure
	NPPROC	CMD_BPENA -- Breakpoint Page Enable Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Breakpoint page enable command

BP+		Enable all page breakpoints
BPn+		Enable #n page breakpoint (parsed in CMD_BP0TO7)
BP+ addr	Enable ones which match this address

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save registers

	inc	esi		; Skip over the '+'

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_BPENA_ALL ; Yes, treat as clear all

	call	PARSE_ADDR	; Parse DS:ESI for address
	jc	near ptr CMD_BPENA_SYNTERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

; Ensure there's nothing else on the line

	cmp	ds:[esi].LO,0	; Izit end-of-the-line?
	jne	near ptr CMD_BPENA_SYNTERR ; Jump if not

; See if this duplicates an existing value in BPDATA

; Fill in segment/selector/mode if no separator specified

	test	cx,@ADDR_SEP	; Izit specified?
	jnz	short @F	; Yes, BX is valid

	mov	bx,UNASEL	; Get segment/selector of current instr
	mov	edx,UNABASE	; Get base of the current instr

	test	UNAMODE,@MODE_VM ; Izit VM86 mode?
	jnz	short @F	; Jump if so

	or	cx,@ADDR_PM	; Mark as PM
@@:

; Loop through the BPDATA structure looking for a match

	mov	si,cx		; Copy flags
	mov	ecx,@NBP	; Get # page breakpoints
	xor	edi,edi 	; Initialize index into BPDATA
CMD_BPENA_NEXT:
	test	BPDATA[edi].BP_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short CMD_BPENA_LOOP ; Jump if not

	cmp	bx,BPDATA[edi].BP_SEL ; Same segment/selector?
	jne	short CMD_BPENA_LOOP ; Jump if not

	cmp	eax,BPDATA[edi].BP_OFF ; Same offset?
	jne	short CMD_BPENA_LOOP ; Jump if not

	mov	dx,si		; Copy flags
	xor	dx,BPDATA[edi].BP_FLAG ; Check for same mode

	test	dx,@ADDR_PM	; Izit the same mode?
	jnz	short CMD_BPENA_LOOP ; Jump if not

	or	BPDATA[edi].BP_FLAG,@ADDR_ENA ; Mark as enabled
CMD_BPENA_LOOP:
	add	edi,size BP_STR ; Skip to next entry

	loop	CMD_BPENA_NEXT	; Jump if more entries

	jmp	CMD_BPENA_CLC	; Join common OK code


; Enable page breakpoint #n

CMD_BPENAN macro NN

	public	CMD_BPENA&NN
CMD_BPENA&NN:
	or	BPDATA[&NN*(type BP_STR)].BP_FLAG,@ADDR_ENA ; Mark as enabled

	jmp	short CMD_BPENAN_COM ; Join common code

	endm			; End CMD_BPENAN macro


	public	CMD_BPENAN_COM
CMD_BPENAN_COM:
	cmp	DSP_STATE,@DSP_BP ; Displaying BP values?
	je	short @F	; Yes

	call	DISP_BP 	; Display 'em
@@:
	clc			; Incidate all went well

	ret			; Return to caller


	CMD_BPENAN 0
	CMD_BPENAN 1
	CMD_BPENAN 2
	CMD_BPENAN 3
	CMD_BPENAN 4
	CMD_BPENAN 5
	CMD_BPENAN 6
	CMD_BPENAN 7


; Enable all page breakpoints

CMD_BPENA_ALL:
	mov	ecx,@NBP	; Get # page breakpoints
	xor	edi,edi 	; Initialize index into BPDATA
CMD_BPENA_NEXT2:
	test	BPDATA[edi].BP_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short @F	; Jump if not

	or	BPDATA[edi].BP_FLAG,@ADDR_ENA ; Mark as enabled
@@:
	add	edi,size BP_STR ; Skip to next entry

	loop	CMD_BPENA_NEXT2 ; Jump if more entries
CMD_BPENA_CLC:
	cmp	DSP_STATE,@DSP_BP ; Displaying BP values?
	je	short @F	; Yes

	call	DISP_BP 	; Display 'em
@@:
	clc			; Incidate all went well

	jmp	short CMD_BPENA_EXIT ; Join common exit code

CMD_BPENA_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Indicate something went wrong
CMD_BPENA_EXIT:
	REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BPENA endp			; End CMD_BPENA procedure
	NPPROC	CMD_BPDIS -- Breakpoint Page Disable Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Breakpoint page disable command

BP-		Disable all page breakpoints
BPn-		Disable #n page breakpoint (parsed in CMD_BP0TO7)
BP- addr	Disable ones which match this address

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save registers

	inc	esi		; Skip over the '-'

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_BPDIS_ALL ; Yes, treat as clear all

	call	PARSE_ADDR	; Parse DS:ESI for address
	jc	near ptr CMD_BPDIS_SYNTERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

; Ensure there's nothing else on the line

	cmp	ds:[esi].LO,0	; Izit end-of-the-line?
	jne	near ptr CMD_BPDIS_SYNTERR ; Jump if not

; See if this duplicates an existing value in BPDATA

; Fill in segment/selector/mode if no separator specified

	test	cx,@ADDR_SEP	; Izit specified?
	jnz	short @F	; Yes, BX is valid

	mov	bx,UNASEL	; Get segment/selector of current instr
	mov	edx,UNABASE	; Get base of the current instr

	test	UNAMODE,@MODE_VM ; Izit VM86 mode?
	jnz	short @F	; Jump if so

	or	cx,@ADDR_PM	; Mark as PM
@@:

; Loop through the BPDATA structure looking for a match

	mov	si,cx		; Copy flags
	mov	ecx,@NBP	; Get # page breakpoints
	xor	edi,edi 	; Initialize index into BPDATA
CMD_BPDIS_NEXT:
	test	BPDATA[edi].BP_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short CMD_BPDIS_LOOP ; Jump if not

	cmp	bx,BPDATA[edi].BP_SEL ; Same segment/selector?
	jne	short CMD_BPDIS_LOOP ; Jump if not

	cmp	eax,BPDATA[edi].BP_OFF ; Same offset?
	jne	short CMD_BPDIS_LOOP ; Jump if not

	mov	dx,si		; Copy flags
	xor	dx,BPDATA[edi].BP_FLAG ; Check for same mode

	test	dx,@ADDR_PM	; Izit the same mode?
	jnz	short CMD_BPDIS_LOOP ; Jump if not

	and	BPDATA[edi].BP_FLAG,not @ADDR_ENA ; Mark as disabled
CMD_BPDIS_LOOP:
	add	edi,size BP_STR ; Skip to next entry

	loop	CMD_BPDIS_NEXT	; Jump if more entries

	jmp	CMD_BPDIS_CLC	; Join common OK code


; Disable page breakpoint #n

CMD_BPDISN macro NN

	public	CMD_BPDIS&NN
CMD_BPDIS&NN:
	and	BPDATA[&NN*(type BP_STR)].BP_FLAG,not @ADDR_ENA ; Mark as disabled

	jmp	short CMD_BPDISN_COM ; Join common code

	endm			; End CMD_BPDISN macro


	public	CMD_BPDISN_COM
CMD_BPDISN_COM:
	cmp	DSP_STATE,@DSP_BP ; Displaying BP values?
	je	short @F	; Yes

	call	DISP_BP 	; Display 'em
@@:
	clc			; Incidate all went well

	ret			; Return to caller


	CMD_BPDISN 0
	CMD_BPDISN 1
	CMD_BPDISN 2
	CMD_BPDISN 3
	CMD_BPDISN 4
	CMD_BPDISN 5
	CMD_BPDISN 6
	CMD_BPDISN 7


; Disable all page breakpoints

CMD_BPDIS_ALL:
	mov	ecx,@NBP	; Get # page breakpoints
	xor	edi,edi 	; Initialize index into BPDATA
CMD_BPDIS_NEXT2:
	test	BPDATA[edi].BP_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short @F	; Jump if not

	and	BPDATA[edi].BP_FLAG,not @ADDR_ENA ; Mark as disabled
@@:
	add	edi,size BP_STR ; Skip to next entry

	loop	CMD_BPDIS_NEXT2 ; Jump if more entries
CMD_BPDIS_CLC:
	cmp	DSP_STATE,@DSP_BP ; Displaying BP values?
	je	short @F	; Yes

	call	DISP_BP 	; Display 'em
@@:
	clc			; Incidate all went well

	jmp	short CMD_BPDIS_EXIT ; Join common exit code

CMD_BPDIS_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Indicate something went wrong
CMD_BPDIS_EXIT:
	REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BPDIS endp			; End CMD_BPDIS procedure
	NPPROC	CMD_BPSET -- Breakpoint Page Set Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Breakpoint page set command

BP* opt_addr
BP+ opt_addr
BP- opt_addr

BP		 Display all page breakpoints
BP addr 	 Set one at this address

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

; Split off cases for clear, enable, and disable

	cmp	DGROUP:[esi].LO,'*' ; Izit clear?
	je	near ptr CMD_BPCLR ; Jump if so

	cmp	DGROUP:[esi].LO,'+' ; Izit enable?
	je	near ptr CMD_BPENA ; Jump if so

	cmp	DGROUP:[esi].LO,'-' ; Izit disable?
	je	near ptr CMD_BPDIS ; Jump if so

	REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save registers

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_BPSET_DISP ; Yes, treat as display all

	call	PARSE_ADDR	; Parse DS:ESI for address
	jc	near ptr CMD_BPSET_SYNTERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

; Ensure there's nothing else on the line

	cmp	ds:[esi].LO,0	; Izit end-of-the-line?
	jne	near ptr CMD_BPSET_SYNTERR ; Jump if not

; See if this duplicates an existing value in BPDATA

; Fill in segment/selector/mode if no separator specified

	test	cx,@ADDR_SEP	; Izit specified?
	jnz	short CMD_BPSET1 ; Yes, BX is valid

	mov	bx,UNASEL	; Get segment/selector of current instr
	mov	edx,UNABASE	; Get base of the current instr

	test	UNAMODE,@MODE_VM ; Izit VM86 mode?
	jnz	short CMD_BPSET1 ; Jump if so

	or	cx,@ADDR_PM	; Mark as PM
CMD_BPSET1:

; Loop through the BPDATA structure looking for a match

	mov	si,cx		; Copy flags
	mov	ecx,@NBP	; Get # page breakpoints
	xor	edi,edi 	; Initialize index into BPDATA
CMD_BPSET_NEXT:
	test	BPDATA[edi].BP_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short CMD_BPSET_LOOP ; Jump if not

	cmp	bx,BPDATA[edi].BP_SEL ; Same segment/selector?
	jne	short CMD_BPSET_LOOP ; Jump if not

	cmp	eax,BPDATA[edi].BP_OFF ; Same offset?
	jne	short CMD_BPSET_LOOP ; Jump if not

	xor	si,BPDATA[edi].BP_FLAG ; Check for same mode

	test	si,@ADDR_PM	; Izit the same mode?
	jnz	short CMD_BPSET_LOOP0 ; Jump if not

; Enable it, save new original value, exit

	xor	si,BPDATA[edi].BP_FLAG ; Restore original flags
	or	si,@ADDR_ENA	; Mark as enabled
	mov	BPDATA[edi].BP_FLAG,si ; Mark as enabled, etc.

	add	eax,edx 	; Add offset and base to get linear address
	mov	BPDATA[edi].BP_LIN,eax ; Save as new linear address

	jmp	short CMD_BPSET_CLC ; Join common OK code

CMD_BPSET_LOOP0:
	xor	si,BPDATA[edi].BP_FLAG ; Restore original flags
CMD_BPSET_LOOP:
	add	edi,size BP_STR ; Skip to next entry

	loop	CMD_BPSET_NEXT	; Jump if more entries

; No match found, insert a new one

; Look for a free entry

	mov	ecx,@NBP	; Get # page breakpoints
	xor	edi,edi 	; Initialize index into BPDATA
CMD_BPSET_NEXT2:
	test	BPDATA[edi].BP_FLAG,@ADDR_INUSE ; Izit in use?
	jnz	short CMD_BPSET_LOOP2 ; Jump if so

; Mark as in use, enabled, save new original value, and exit

	or	si,@ADDR_INUSE or @ADDR_ENA ; Mark it
	mov	BPDATA[edi].BP_FLAG,si ; Save flags

	mov	BPDATA[edi].BP_OFF,eax ; Save offset
	mov	BPDATA[edi].BP_SEL,bx ; ... segment/selector

	add	eax,edx 	; Add offset and base to get linear address
	mov	BPDATA[edi].BP_LIN,eax ; Save as new linear address

	jmp	short CMD_BPSET_CLC ; Join common OK code

CMD_BPSET_LOOP2:
	add	edi,size BP_STR ; Skip to next entry

	loop	CMD_BPSET_NEXT2 ; Jump if more entries

; No free entries found

	mov	MSGOFF,offset DGROUP:BPREGERR ; Save offset of error message

	jmp	short CMD_BPSET_ERR ; Join common error code


; Display all page breakpoints

CMD_BPSET_CLC:
	cmp	DSP_STATE,@DSP_BP ; Displaying BP values?
	jne	short @F	; No
CMD_BPSET_DISP:
	call	DISP_BP 	; Display 'em
@@:
	clc			; Incidate all went well

	jmp	short CMD_BPSET_EXIT ; Join common exit code

CMD_BPSET_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
CMD_BPSET_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Indicate something went wrong
CMD_BPSET_EXIT:
	REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BPSET endp			; End CMD_BPSET procedure
	NPPROC	CMD_BP0TO7 -- Page Registers Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Page Register BP0-7 clear, enable, disable commands

BP0*	BP0+	BP0-
BP1*	BP1+	BP1-
BP2*	BP2+	BP2-
BP3*	BP3+	BP3-
BP4*	BP4+	BP4-
BP5*	BP5+	BP5-
BP6*	BP6+	BP6-
BP7*	BP7+	BP7-

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

BPN_MAC macro	NN

	public	CMD_BP&NN
CMD_BP&NN:
	inc	esi		; Skip over the next symbol

	cmp	DGROUP:[esi-1].LO,'*' ; Izit clear?
	je	near ptr CMD_BPCLR&NN ; Jump if so

	cmp	DGROUP:[esi-1].LO,'+' ; Izit enable?
	je	near ptr CMD_BPENA&NN ; Jump if so

	cmp	DGROUP:[esi-1].LO,'-' ; Izit disable?
	je	near ptr CMD_BPDIS&NN ; Jump if so

	jmp	CMD_BP0TO7_SYNTERR ; Jump if none of the above

	endm			; End BPN_MAC macro

; Split off cases for clear, enable, and disable

	BPN_MAC 0
	BPN_MAC 1
	BPN_MAC 2
	BPN_MAC 3
	BPN_MAC 4
	BPN_MAC 5
	BPN_MAC 6
	BPN_MAC 7

CMD_BP0TO7_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BP0TO7 endp 		; End CMD_BP0TO7 procedure
	NPPROC	CheckTrapCR2 -- Check On CR2 Traps
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

EAX	=	@SWAT_TRAPCR2
CR2	=	Page Fault linear address

On exit:

CF	=	1 if there's a match
	=	0 if not

|

	REGSAVE <eax,ecx,edi,ds> ; Save registers

	SETDATA ds		; Set data selector into DS
	assume	ds:DGROUP	; Tell the assembler about it

	mov	eax,cr2 	; Get current value

; Loop through the BPDATA structure looking for a match

	mov	ecx,@NBP	; Get # page breakpoints
	xor	edi,edi 	; Initialize index into BPDATA
CheckTrapCR2Next:
	test	BPDATA[edi].BP_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short CheckTrapCR2Loop ; Jump if not

	test	BPDATA[edi].BP_FLAG,@ADDR_ENA ; Izit in enabled?
	jz	short CheckTrapCR2Loop ; Jump if not

	cmp	eax,BPDATA[edi].BP_LIN ; Same linear address?
	je	short CheckTrapCR2Match ; Jump if so
CheckTrapCR2Loop:
	add	edi,size BP_STR ; Skip to next entry

	loop	CheckTrapCR2Next ; Jump if more entries

	clc			; Mark as no match

	jmp	short CheckTrapCR2Exit ; Join common exit code

CheckTrapCR2Match:
	stc			; Mark as a match
CheckTrapCR2Exit:
	REGREST <ds,edi,ecx,eax> ; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CheckTrapCR2 endp		; End CheckTrapCR2 procedure
	NPPROC	REFRESH_DEBUG -- Refresh Debug Hook Values
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Refresh debug hook values

One entry:

SS:EBP	==>	FORW_STR

|

	REGSAVE <eax,ebx,ecx,edi> ; Save registers

	call	INST_OPR0E	; Install our local Page Fault handler

; Loop through BCDATA and refresh values

	mov	ecx,@NBCX	; Get # code breakpoints (plus extra BPs)
	xor	edi,edi 	; Initialize index into BCDATA
REFR_DEBUG_NEXT1:
	test	BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short REFR_DEBUG_LOOP1 ; Jump if not

; Because the linear address might have changed, we recalculate it
; from the segment/selector values

	movzx	eax,BCDATA[edi].BC_SEL ; Get the segment/selector
	shl	eax,4-0 	; Convert from paras to bytes

	test	BCDATA[edi].BC_FLAG,@ADDR_PM ; Izit in PM?
	jz	short @F	; Jump if not

	push	BCDATA[edi].BC_SEL ; Pass the selector
	call	GETBASE 	; Return with EAX = selector base
@@:
	mov	ebx,BCDATA[edi].BC_OFF ; Get the offset
	add	ebx,eax 	; Add to get linear address

	cmp	ebx,BCDATA[edi].BC_LIN ; Izit the same?
	je	short @F	; Jump if so

	mov	BCDATA[edi].BC_LIN,ebx ; Save as new linear address
@@:
	test	BCDATA[edi].BC_FLAG,@ADDR_ENA ; Izit enabled?
	jz	short REFR_DEBUG_LOOP1 ; Jump if not

; The next instruction might generate a Page Fault if the linear address
; of the original instruction is no longer valid, but it'll be skipped
; by the above-installed Page Fault handler.

	clc			; Assume no Page Fault
	mov	al,AGROUP:[ebx] ; Get the value
	jc	short REFR_DEBUG_ERR ; Jump if Page Fault

	cmp	al,@OPCOD_INT3	; Izit an INT 03h?
	je	short REFR_DEBUG_LOOP1 ; Jump if so

	cmp	al,BCDATA[edi].BC_VAL ; Izit the original value?
	jne	short REFR_DEBUG_ERR ; Jump if not

	mov	AGROUP:[ebx].LO,@OPCOD_INT3 ; Restore the BC

	jmp	short REFR_DEBUG_LOOP1 ; Join common loop code

REFR_DEBUG_ERR:
	and	BCDATA[edi].BC_FLAG,not @ADDR_ENA ; Mark as disabled
REFR_DEBUG_LOOP1:
	add	edi,size BC_STR ; Skip to next entry

	loop	REFR_DEBUG_NEXT1 ; Jump if more entries

; Loop through BD registers and refresh

	xor	edi,edi 	; Initialize index into BDREGS
	mov	ecx,4		; Get # debug registers
REFR_DEBUG_NEXT2:
	test	BDREGS[edi].BD_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short REFR_DEBUG_LOOP2 ; Jump if not

	movzx	eax,BDREGS[edi].BD_SEL ; Get the segment/selector
	shl	eax,4-0 	; Convert from paras to bytes

	test	BDREGS[edi].BD_FLAG,@ADDR_PM ; Izit in PM?
	jz	short @F	; Jump if not

	push	BDREGS[edi].BD_SEL ; Pass the selector
	call	GETBASE 	; Return with EAX = selector base
@@:
	mov	BDREGS[edi].BD_BASE,eax ; Save as base address
	add	eax,BDREGS[edi].BD_OFF ; Plus the offset
	mov	BDREGS[edi].BD_REG,eax ; Save as register value

	call	BDREGS[edi].BD_SET ; Set the new value into place
REFR_DEBUG_LOOP2:
	add	edi,type BD_STR ; Skip to next entry

	loop	REFR_DEBUG_NEXT2 ; Jump if more registers to refresh

	call	REST_OPR0E	; Restore previous Page Fault handler

	REGREST <edi,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REFRESH_DEBUG endp		; End REFRESH_DEBUG procedure
	NPPROC	CMD_BDCLR0123 -- Debug Register Clear DR0-DR3 Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debug Register clear DR0-DR3 commands

BD0*
BD1*
BD2*
BD3*

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|





	public	CMD_BDCLR0
CMD_BDCLR0:
	REGSAVE <ebx,edi>	; Save registers

	mov	ebx,not ((mask $L0) or (mask $G0)) ; Get the mask for DR0
	mov	edi,0*(size BD_STR) ; EDI = offset into BDREGS

	jmp	short CMD_BDCLRCOM ; Join common code

	public	CMD_BDCLR1
CMD_BDCLR1:
	REGSAVE <ebx,edi>	; Save registers

	mov	ebx,not ((mask $L1) or (mask $G1)) ; Get the mask for DR1
	mov	edi,1*(size BD_STR) ; EDI = offset into BDREGS

	jmp	short CMD_BDCLRCOM ; Join common code

	public	CMD_BDCLR2
CMD_BDCLR2:
	REGSAVE <ebx,edi>	; Save registers

	mov	ebx,not ((mask $L2) or (mask $G2)) ; Get the mask for DR2
	mov	edi,2*(size BD_STR) ; EDI = offset into BDREGS

	jmp	short CMD_BDCLRCOM ; Join common code

	public	CMD_BDCLR3
CMD_BDCLR3:
	REGSAVE <ebx,edi>	; Save registers

	mov	ebx,not ((mask $L3) or (mask $G3)) ; Get the mask for DR3
	mov	edi,3*(size BD_STR) ; EDI = offset into BDREGS

;;;;;;; jmp	short CMD_BDCLRCOM ; Join common code

CMD_BDCLRCOM:
	REGSAVE <eax>		; Save register

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	jne	short CMD_BDCLR0123_SYNTERR ; No, so that's an error

	and	ebx,SAVE_DR7	; Get debug control register, clear bits

	test	ebx,@ANYGL	; Any global or local DRn enables set?
	jnz	short @F	; Yes, continue with global/local enable

	and	ebx,not (mask $GE) ; Clear global enable
@@:
	mov	SAVE_DR7,ebx	; Reset debug control register

; Mark as disabled and available

	and	BDREGS.BD_FLAG[edi],not (@ADDR_ENA or @ADDR_INUSE)

	cmp	DSP_STATE,@DSP_DRn ; Displaying debug registers?
	jne	short @F	; No

	call	DISP_DRn        ; Display 'em
@@:
	call	UD_BREAKLIST	; Update breakpoint list for display
	clc			; Indicate all went well

	jmp	short CMD_BDCLR0123_EXIT ; Join common exit code

CMD_BDCLR0123_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
CMD_BDCLR0123_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Indicate something went wrong
CMD_BDCLR0123_EXIT:
	REGREST <eax>		; Restore
	REGREST <edi,ebx>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BDCLR0123 endp		; End CMD_BDCLR0123 procedure
	NPPROC	CMD_BDCLR -- Debug Register Clear All Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debug Register clear all command

BD*

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax>		; Save register

	inc	esi		; Skip over the '*'

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	jne	short CMD_BDCLR_SYNTERR ; No, so that's an error

	call	CMD_BDCLR0	; Clear DR0
	call	CMD_BDCLR1	; Clear DR1
	call	CMD_BDCLR2	; Clear DR2
	call	CMD_BDCLR3	; Clear DR3

	call	UD_BREAKLIST	; Update breakpoint list for display
	clc			; Indicate all went well

	jmp	short CMD_BDCLR_EXIT ; Join common exit code

CMD_BDCLR_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
CMD_BDCLR_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Indicate something went wrong
CMD_BDCLR_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BDCLR endp			; End CMD_BDCLR procedure
	NPPROC	CMD_BDDIS0123 -- Debug Register Disable DR0-DR3 Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debug Register disable DR0-DR3 commands

BD0-
BD1-
BD2-
BD3-

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	public	CMD_BDDIS0
CMD_BDDIS0:
	REGSAVE <ebx,edi>	; Save registers

	mov	ebx,not ((mask $L0) or (mask $G0)) ; Get the mask for DR0
	mov	edi,0*(size BD_STR) ; EDI = offset into BDREGS

	jmp	short CMD_BDDISCOM ; Join common code

	public	CMD_BDDIS1
CMD_BDDIS1:
	REGSAVE <ebx,edi>	; Save registers

	mov	ebx,not ((mask $L1) or (mask $G1)) ; Get the mask for DR1
	mov	edi,1*(size BD_STR) ; EDI = offset into BDREGS

	jmp	short CMD_BDDISCOM ; Join common code

	public	CMD_BDDIS2
CMD_BDDIS2:
	REGSAVE <ebx,edi>	; Save registers

	mov	ebx,not ((mask $L2) or (mask $G2)) ; Get the mask for DR2
	mov	edi,2*(size BD_STR) ; EDI = offset into BDREGS

	jmp	short CMD_BDDISCOM ; Join common code

	public	CMD_BDDIS3
CMD_BDDIS3:
	REGSAVE <ebx,edi>	; Save registers

	mov	ebx,not ((mask $L3) or (mask $G3)) ; Get the mask for DR3
	mov	edi,3*(size BD_STR) ; EDI = offset into BDREGS

;;;;;;; jmp	short CMD_BDDISCOM ; Join common code

CMD_BDDISCOM:
	REGSAVE <eax>		; Save register

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	jne	short CMD_BDDIS0123_SYNTERR ; No, so that's an error

; Ensure the register is in use

	test	BDREGS.BD_FLAG[edi],@ADDR_INUSE ; Izit in use?
;;;;;;; jz	short CMD_BDDIS0123_ERR ; No, so that's an error
	jz	short CMD_BDDIS0123_EXIT ; No, so just ignore it (note CF=0)

; Disable the register

	and	ebx,SAVE_DR7	; Get debug control register, clear bits

	test	ebx,@ANYGL	; Any global or local DRn enables set?
	jnz	short @F	; Yes, continue with global/local enable

	and	ebx,not (mask $GE) ; Clear global enable
@@:
	mov	SAVE_DR7,ebx	; Reset debug control register

; Mark as disabled

	and	BDREGS.BD_FLAG[edi],not @ADDR_ENA

	cmp	DSP_STATE,@DSP_DRn ; Displaying debug registers?
	jne	short @F	; No

	call	DISP_DRn	; Display 'em
@@:
	call	UD_BREAKLIST	; Update breakpoint list for display
	clc			; Indicate all went well

	jmp	short CMD_BDDIS0123_EXIT ; Join common exit code

CMD_BDDIS0123_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
CMD_BDDIS0123_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Indicate something went wrong
CMD_BDDIS0123_EXIT:
	REGREST <eax>		; Restore
	REGREST <edi,ebx>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BDDIS0123 endp		; End CMD_BDDIS0123 procedure
	NPPROC	CMD_BDDIS -- Debug Register Disable All Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debug Register disable all command

BD-

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax>		; Save register

	inc	esi		; Skip over the '-'

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	jne	short CMD_BDDIS_SYNTERR ; No, so that's an error

; Ensure the register is in use

	test	BDREGS.BD_FLAG[0*(size BD_STR)],@ADDR_INUSE ; Izit in use?
	jz	short @F	; No, so skip it

	call	CMD_BDDIS0	; Disable DR0
@@:
	test	BDREGS.BD_FLAG[1*(size BD_STR)],@ADDR_INUSE ; Izit in use?
	jz	short @F	; No, so skip it

	call	CMD_BDDIS1	; Disable DR1
@@:
	test	BDREGS.BD_FLAG[2*(size BD_STR)],@ADDR_INUSE ; Izit in use?
	jz	short @F	; No, so skip it

	call	CMD_BDDIS2	; Disable DR2
@@:
	test	BDREGS.BD_FLAG[3*(size BD_STR)],@ADDR_INUSE ; Izit in use?
	jz	short @F	; No, so skip it

	call	CMD_BDDIS3	; Disable DR3
@@:
	call	UD_BREAKLIST	; Update breakpoint list for display
	clc			; Indicate all went well

	jmp	short CMD_BDDIS_EXIT ; Join common exit code

CMD_BDDIS_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
CMD_BDDIS_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Indicate something went wrong
CMD_BDDIS_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BDDIS endp			; End CMD_BDDIS procedure
	NPPROC	CMD_BDENA0123 -- Debug Register Enable DR0-DR3 Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debug Register enable DR0-DR3 commands

BD0+
BD1+
BD2+
BD3+

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	public	CMD_BDENA0
CMD_BDENA0:
	REGSAVE <edi>		; Save register

	mov	edi,0*(size BD_STR) ; EDI = offset into BDREGS

	jmp	short CMD_BDENACOM ; Join common code

	public	CMD_BDENA1
CMD_BDENA1:
	REGSAVE <edi>		; Save register

	mov	edi,1*(size BD_STR) ; EDI = offset into BDREGS

	jmp	short CMD_BDENACOM ; Join common code

	public	CMD_BDENA2
CMD_BDENA2:
	REGSAVE <edi>		; Save register

	mov	edi,2*(size BD_STR) ; EDI = offset into BDREGS

	jmp	short CMD_BDENACOM ; Join common code

	public	CMD_BDENA3
CMD_BDENA3:
	REGSAVE <edi>		; Save register

	mov	edi,3*(size BD_STR) ; EDI = offset into BDREGS

;;;;;;; jmp	short CMD_BDENACOM ; Join common code

CMD_BDENACOM:
	REGSAVE <eax>		; Save register

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	jne	short CMD_BDENA0123_SYNTERR ; No, so that's an error

; Ensure the register is in use

	test	BDREGS.BD_FLAG[edi],@ADDR_INUSE ; Izit in use?
;;;;;;; jz	short CMD_BDENA0123_ERR ; No, so that's an error
	jz	short CMD_BDENA0123_EXIT ; No, so just ignore it (note CF=0)

; Enable the register

	call	RESPEC_DR7	; Respecify DR7 from BDREGS[edi]

; Mark as enabled

	or	BDREGS.BD_FLAG[edi],@ADDR_ENA

	mov	eax,BDREGS.BD_BASE[edi] ; Get linear base address
	add	eax,BDREGS.BD_OFF[edi] ; Add offset

; Because we might have gone in and out of Windows, we can't trust that
; the DRn linear address register is still valid as Windows sets it to
; zero upon exit.

	call	BDREGS[edi].BD_SET ; Set the new value into place

	cmp	DSP_STATE,@DSP_DRn ; Displaying debug registers?
	jne	short @F	; No

	call	DISP_DRn	; Display 'em
@@:
	call	UD_BREAKLIST	; Update breakpoint list for display
	clc			; Indicate all went well

	jmp	short CMD_BDENA0123_EXIT ; Join common exit code

CMD_BDENA0123_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
CMD_BDENA0123_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Indicate something went wrong
CMD_BDENA0123_EXIT:
	REGREST <eax>		; Restore
	REGREST <edi>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BDENA0123 endp		; End CMD_BDENA0123 procedure
	NPPROC	CMD_BDENA -- Debug Register Enable All Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debug Register enable all command

BD+

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax>		; Save register

	inc	esi		; Skip over the '+'

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	jne	short CMD_BDENA_SYNTERR ; No, so that's an error

; Ensure the register is in use

	test	BDREGS.BD_FLAG[0*(size BD_STR)],@ADDR_INUSE ; Izit in use?
	jz	short @F	; No, so skip it

	call	CMD_BDENA0	; Enable DR0
@@:
	test	BDREGS.BD_FLAG[1*(size BD_STR)],@ADDR_INUSE ; Izit in use?
	jz	short @F	; No, so skip it

	call	CMD_BDENA1	; Enable DR1
@@:
	test	BDREGS.BD_FLAG[2*(size BD_STR)],@ADDR_INUSE ; Izit in use?
	jz	short @F	; No, so skip it

	call	CMD_BDENA2	; Enable DR2
@@:
	test	BDREGS.BD_FLAG[3*(size BD_STR)],@ADDR_INUSE ; Izit in use?
	jz	short @F	; No, so skip it

	call	CMD_BDENA3	; Enable DR3
@@:
	call	UD_BREAKLIST	; Update breakpoint list for display
	clc			; Indicate all went well

	jmp	short CMD_BDENA_EXIT ; Join common exit code

CMD_BDENA_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
CMD_BDENA_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Indicate something went wrong
CMD_BDENA_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BDENA endp			; End CMD_BDENA procedure
	NPPROC	CMD_BD0123 -- Debug Registers Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debug Register DR0-3 clear, enable, disable commands

BD0*	BD0+	BD0-
BD1*	BD1+	BD1-
BD2*	BD2+	BD2-
BD3*	BD3+	BD3-

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

BDN_MAC macro	NN

	public	CMD_BD&NN
CMD_BD&NN:
	inc	esi		; Skip over the next symbol

	cmp	DGROUP:[esi-1].LO,'*' ; Izit clear?
	je	near ptr CMD_BDCLR&NN ; Jump if so

	cmp	DGROUP:[esi-1].LO,'+' ; Izit enable?
	je	near ptr CMD_BDENA&NN ; Jump if so

	cmp	DGROUP:[esi-1].LO,'-' ; Izit disable?
	je	near ptr CMD_BDDIS&NN ; Jump if so

	jmp	short CMD_BD0123_SYNTERR ; Jump if none of the above

	endm			; End BDN_MAC macro

; Split off cases for clear, enable, and disable

	BDN_MAC 0
	BDN_MAC 1
	BDN_MAC 2
	BDN_MAC 3
CMD_BD0123_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BD0123 endp 		; End CMD_BD0123 procedure
	NPPROC	CMD_BD -- Debug Registers Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debug Register change command

BD  opt_addr
BD*
BD+
BD-

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

; Split off cases for clear, enable, and disable

	SELFBREAK CMD_BD,40h	; Enable conditional breakpoint

	cmp	DGROUP:[esi].LO,'*' ; Izit clear?
	je	near ptr CMD_BDCLR ; Jump if so

	cmp	DGROUP:[esi].LO,'+' ; Izit enable?
	je	near ptr CMD_BDENA ; Jump if so

	cmp	DGROUP:[esi].LO,'-' ; Izit disable?
	je	near ptr CMD_BDDIS ; Jump if so

	REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save registers

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_BD_DISP ; Yes, treat as display request

	call	PARSE_ADDR	; Parse DS:ESI for address
	jc	near ptr CMD_BD_ERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

	mov	BDCMD.BD_OFF,eax ; Save for later use
	or	cx,@ADDR_ENA or @ADDR_INUSE ; Mark as enabled and in use
	mov	BDCMD.BD_FLAG,cx ; Save for later use

	test	cx,@ADDR_SEP	; Separator specified?
	jz	short @F	; Not this time

	mov	BDCMD.BD_SEL,bx ; Save for later use
	mov	BDCMD.BD_BASE,edx ; ...
@@:

; Parse length separator

	mov	BDCMD.BD_TYPE,@BD_X ; Assume instruction fetch
	mov	BDCMD.BD_LEN,@BD_L1 ; Assume length 1 for instruction fetches

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_BD_COM ; Yes, treat as instruction breakpoint

	call	U32_LOWERCASE	; Convert AL to lowercase

	cmp	al,'l'          ; Izit length parameter?
	jne	near ptr CMD_BD_SYNTERR ; No, so that's an error

	inc	esi		; Skip over length separator

; Parse length parameter

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,'1'          ; Izit length 1?
	je	short @F	; Yes

	cmp	al,'2'          ; Izit length 2?
	je	short @F	; Yes

	cmp	al,'4'          ; Izit length 4?
	jne	near ptr CMD_BD_SYNTERR ; No, so that's an error
@@:
	sub	al,'1'          ; Convert to origin-1
	mov	BDCMD.BD_LEN,al ; Save for later use

	inc	esi		; Skip over length parameter

; Parse breakpoint type

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

;;;;;;; cmp	al,0		; Izit end-of-the-line?
;;;;;;; je	short CMD_BD_SYNTERR ; Yes, so that's an error

	call	U32_LOWERCASE	; Convert AL to lowercase

	cmp	al,'r'          ; Izit read/write?
	mov	ah,@BD_RW	; Assume so
	je	short CMD_BDTYP ; Yes

	cmp	al,'w'          ; Izit write-only?
	mov	ah,@BD_W	; Assume so
	je	short CMD_BDTYP ; Yes

	test	CPUFET_FLAG,@CPUFET_IOBRK ; Are I/O breakpoints supported?
	jz	short CMD_BDXP5 ; Jump if not

	cmp	al,'i'          ; Izit I/O read/write?
	mov	ah,@BD_IO	; Assume so
	je	short CMD_BDIO	; Yes

	cmp	al,'o'          ; Izit I/O read/write?
;;;;;;; mov	ah,@BD_IO	; Assume so
	jne	short CMD_BDXP5 ; No
CMD_BDIO:
	test	cx,@ADDR_SEP	; Separator specified?
	jnz	near ptr CMD_BD_SYNTERR ; Yes (not allowed with I/O breakpoints)

; Ensure debugging extensions are enabled

	MOVSPR	ebx,cr4 	; Get CPU extensions register
	or	ebx,mask $DE	; DE=1
	MOVSPR	cr4,ebx 	; Tell the CPU about it

	jmp	short CMD_BDTYP ; Join common code

CMD_BDXP5:
	cmp	al,'x'          ; Izit execute?
	mov	ah,@BD_X	; Assume so
	jne	near ptr CMD_BD_SYNTERR ; No, so that's an error

	cmp	BDCMD.BD_LEN,@BD_L1 ; Ensure execute is length 1
	jne	near ptr CMD_BD_SYNTERR ; No, so that's an error
CMD_BDTYP:
	mov	BDCMD.BD_TYPE,ah ; Save for later use

	inc	esi		; Skip over breakpoint type

; Ensure nothing more on the line

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	jne	near ptr CMD_BD_SYNTERR ; No, so that's an error
CMD_BD_COM:

; Find a debug register to use

	xor	edi,edi 	; Initialize index into BDREGS structure
	mov	ecx,4		; # registers to check
@@:
	test	BDREGS.BD_FLAG[edi],@ADDR_INUSE ; Izit in use?
	jz	short CMD_BD_SET ; No, save values

	add	edi,size BD_STR ; Skip to next register

	loop	@B		; Jump if more registers to check

	jmp	CMD_BD_REGERR	; Jump if none available

CMD_BD_SET:

; Set debug register

	mov	eax,BDCMD.BD_BASE ; Get base address
	add	eax,BDCMD.BD_OFF ; Plus offset

	call	BDREGS[edi].BD_SET ; Set the new value into place

	jmp	short CMD_BDSETCOM ; Join common code

	public	CMD_BDSET_A
CMD_BDSET_A:
CMD_BDSET0:
	mov	dr0,eax 	; Set debug register

	ret			; Return to caller

CMD_BDSET1:
	mov	dr1,eax 	; Set debug register

	ret			; Return to caller

CMD_BDSET2:
	mov	dr2,eax 	; Set debug register

	ret			; Return to caller

CMD_BDSET3:
	mov	dr3,eax 	; Set debug register

	public	CMD_BDSET_Z
CMD_BDSET_Z:
	ret			; Return to caller

CMD_BDSETCOM:

; Copy values to save area

	push	edi		; Save for a moment

	lea	esi,BDCMD	; DS:ESI ==> command line values
	lea	edi,BDREGS[edi] ; ES:EDI ==> save area in BDREGS structure
	mov	ecx,BD_LSHF-BD_REG ; ECX = # bytes in dyanmic structure
S32 rep movs	<BDREGS[edi].LO,BDCMD[esi].LO> ; Copy to structure

	pop	edi		; Restore

	call	RESPEC_DR7	; Respecify DR7 from BDREGS[edi]

	cmp	DSP_STATE,@DSP_DRn ; Displaying debug registers?
	jne	short CMD_BD_CLC ; No, join common OK code
CMD_BD_DISP:
	call	DISP_DRn	; Display 'em
CMD_BD_CLC:
	call	UD_BREAKLIST	; Update breakpoint list for display
	clc			; Indicate all went well

	jmp	short CMD_BD_EXIT ; Join common exit code

CMD_BD_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	jmp	short CMD_BD_ERR ; Join common error exit code

CMD_BD_REGERR:
	mov	MSGOFF,offset DGROUP:BDREGERR ; Save offset of error message
CMD_BD_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_BD_EXIT:
	REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BD	endp			; End CMD_BD procedure
	NPPROC	DISP_DRn -- Debug Register Display
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display debug register values

|

	REGSAVE <eax,ebx,ecx,esi,edi> ; Save registers

; Format debug registers into window

	mov	eax,dr0 	; Get 1st debug register
	mov	BDREGS.BD_REG[0*(size BD_STR)],eax ; Save in data structure
	mov	eax,dr1 	; Get 2nd debug register
	mov	BDREGS.BD_REG[1*(size BD_STR)],eax ; Save in data structure
	mov	eax,dr2 	; Get 3rd debug register
	mov	BDREGS.BD_REG[2*(size BD_STR)],eax ; Save in data structure
	mov	eax,dr3 	; Get 4th debug register
	mov	BDREGS.BD_REG[3*(size BD_STR)],eax ; Save in data structure

	xor	esi,esi 	; Initialize index into BDREGS
	lea	ebx,DBG_LN1	; Initialize index into DBG_WIN
	mov	ecx,4		; # debug registers
DISP_DRn_NEXT:
	mov	al,'+'          ; Assume enabled

	test	BDREGS.BD_FLAG[esi],@ADDR_ENA ; Izit enabled?
	jnz	short @F	; Jump if so

	mov	al,'-'          ; Assume disabled

	test	BDREGS.BD_FLAG[esi],@ADDR_INUSE ; Izit in use, but disabled?
	jnz	short @F	; Jump if so

	mov	al,' '          ; Marker for available
@@:
	mov	DBG_WIN_EN0[ebx],al ; Save in output display

	lea	edi,DBG_WIN_SL0[ebx] ; ES:EDI ==> selector display

; If this is an I/O breakpoint, the selector field is meaningless,
; so we'll display blanks

	mov	DGROUP:[edi].EDD,'   ' ; Blank the field
	mov	al,' '          ; ...

	cmp	BDREGS.BD_TYPE[esi],@BD_IO ; Izit an I/O breakpoint?
	je	short DISP_DRn_IO ; Jump if so

	mov	ax,BDREGS.BD_SEL[esi] ; Get debug selector
	call	BIN2WORD	; Convert the word

	mov	al,'?'          ; Assume not in use

	test	BDREGS.BD_FLAG[esi],@ADDR_INUSE ; Izit in use?
	jz	short @F	; Not this time

	mov	al,'|'          ; Assume PM

	test	BDREGS.BD_FLAG[esi],@ADDR_PM ; Izit Protected Mode?
	jnz	short @F	; Yes

	mov	al,':'          ; It's VM86
@@:
DISP_DRn_IO:
	mov	DBG_WIN_SP0[ebx],al ; Save in window

	mov	eax,BDREGS.BD_OFF[esi] ; Get debug offset
	lea	edi,DBG_WIN_OF0[ebx] ; ES:EDI ==> offset display
	call	BIN2DWORD	; Convert the dword

	mov	eax,BDREGS.BD_REG[esi] ; Get debug register
	lea	edi,DBG_WIN_DR0[ebx] ; ES:EDI ==> register display
	call	BIN2DWORD	; Convert the dword

	movzx	eax,BDREGS.BD_LEN[esi] ; Get debug length
	mov	al,BDLENS[eax]	; Convert to '1', '2', '?', or '4'
	mov	DBG_WIN_LN0[ebx],al ; Save in output display

	movzx	eax,BDREGS.BD_TYPE[esi] ; Get debug type
	mov	ax,BDTYPES.ELO[eax*2] ; Convert to 'X ', 'R ', or 'RW'
	mov	DBG_WIN_TP0[ebx],ax ; Save in output display

	add	esi,size BD_STR ; Skip to next row in BDREGS
	add	ebx,NDBGCOLS	; Skip to next row in DBG_WIN

;;;;;;; loop	DISP_DRn_NEXT	; Jump if more rows to format
	dec	ecx		; One fewer row to format
;;;;;;; and	ecx,ecx 	; Any rows remain?
	jnz	near ptr DISP_DRn_NEXT	; Jump if more rows to format

	call	DISP_DR6	; Format and display DR6
	call	DISP_DR7	; Format and display DR7

; Display the window

	mov	W_BD.SROW,(@NROWS-NDBGROWS)/2 ; Start in middle row
	mov	W_BD.SCOL,(@NCOLS-NDBGCOLS)/2 ; Start in middle col
	mov	W_BD.NROW,NDBGROWS ; # rows in debug window
	mov	W_BD.NCOL,NDBGCOLS ; # cols ...

	mov	al,DBGATTR	; Get debug window attribute
	push	ax		; Pass as attribute to smear
	push	offset ds:DBG_WIN ; Pass address of debug window
	push	offset ds:W_BD	; Pass address of window descriptor
	call	WPUT_CSA	; Output the characters, smear attribute

	mov	al,@DSP_DRn	; Set new display state
	call	SET_STATE	; Set new state

	REGREST <edi,esi,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DRn endp			; End DISP_DRn procedure
	NPPROC	DISP_DR6 -- Format and Display DR6
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display DR6

|

	REGSAVE <eax,ecx,edi>	; Save registers

; Clear flag text for DR6

	lea	edi,DBG_DR6[DBG_DR6_BT] ; ES:EDI ==> output save area
	mov	ecx,2+DBG_DR6_B0-DBG_DR6_BT ; # bytes to clear
	mov	al,' '          ; Clear to this value
    rep stos	DBG_DR6[edi]	; Clear it

; Format DR6

	mov	eax,dr6 	; Get the status register
	lea	edi,DBG_DR6[DBG_DR6_REG] ; ES:EDI ==> register display
	call	BIN2DWORD	; Convert the dword

; Format the flags in DR6

	test	ax,mask $BT	; Izit set?
	jz	short @F	; Not this time

	mov	DBG_DR6.ELO[DBG_DR6_BT],'TB' ; Mark as set
@@:
	test	ax,mask $BS	; Izit set?
	jz	short @F	; Not this time

	mov	DBG_DR6.ELO[DBG_DR6_BS],'SB' ; Mark as set
@@:
	test	ax,mask $BD	; Izit set?
	jz	short @F	; Not this time

	mov	DBG_DR6.ELO[DBG_DR6_BD],'DB' ; Mark as set
@@:
	test	ax,mask $B3	; Izit set?
	jz	short @F	; Not this time

	mov	DBG_DR6.ELO[DBG_DR6_B3],'3B' ; Mark as set
@@:
	test	ax,mask $B2	; Izit set?
	jz	short @F	; Not this time

	mov	DBG_DR6.ELO[DBG_DR6_B2],'2B' ; Mark as set
@@:
	test	ax,mask $B1	; Izit set?
	jz	short @F	; Not this time

	mov	DBG_DR6.ELO[DBG_DR6_B1],'1B' ; Mark as set
@@:
	test	ax,mask $B0	; Izit set?
	jz	short @F	; Not this time

	mov	DBG_DR6.ELO[DBG_DR6_B0],'0B' ; Mark as set
@@:
	REGREST <edi,ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DR6 endp			; End DISP_DR6 procedure
	NPPROC	DISP_DR7 -- Format and Display DR7
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display DR7

|

	REGSAVE <eax,ecx,edi>	; Save registers

; Clear flag text for DR7

	lea	edi,DBG_DR7[DBG_DR7_GD] ; ES:EDI ==> output save area
	mov	ecx,2+DBG_DR7_L0-DBG_DR7_GD ; # bytes to clear
	mov	al,' '          ; Clear to this value
    rep stos	DBG_DR7[edi]	; Clear it

; Format DR7

	mov	eax,SAVE_DR7	; Get the control register
	lea	edi,DBG_DR7[DBG_DR7_REG] ; ES:EDI ==> register display
	call	BIN2DWORD	; Convert the dword

; Format the flags in DR7

	test	ax,mask $GD	; Izit set?
	jz	short @F	; Not this time

	mov	DBG_DR7.ELO[DBG_DR7_GD],'DG' ; Mark as set
@@:
	test	ax,mask $GE	; Izit set?
	jz	short @F	; Not this time

	mov	DBG_DR7.ELO[DBG_DR7_GE],'EG' ; Mark as set
@@:
	test	ax,mask $LE	; Izit set?
	jz	short @F	; Not this time

	mov	DBG_DR7.ELO[DBG_DR7_LE],'EL' ; Mark as set
@@:
	test	ax,mask $G3	; Izit set?
	jz	short @F	; Not this time

	mov	DBG_DR7.ELO[DBG_DR7_G3],'3G' ; Mark as set
@@:
	test	ax,mask $L3	; Izit set?
	jz	short @F	; Not this time

	mov	DBG_DR7.ELO[DBG_DR7_L3],'3L' ; Mark as set
@@:
	test	ax,mask $G2	; Izit set?
	jz	short @F	; Not this time

	mov	DBG_DR7.ELO[DBG_DR7_G2],'2G' ; Mark as set
@@:
	test	ax,mask $L2	; Izit set?
	jz	short @F	; Not this time

	mov	DBG_DR7.ELO[DBG_DR7_L2],'2L' ; Mark as set
@@:
	test	ax,mask $G1	; Izit set?
	jz	short @F	; Not this time

	mov	DBG_DR7.ELO[DBG_DR7_G1],'1G' ; Mark as set
@@:
	test	ax,mask $L1	; Izit set?
	jz	short @F	; Not this time

	mov	DBG_DR7.ELO[DBG_DR7_L1],'1L' ; Mark as set
@@:
	test	ax,mask $G0	; Izit set?
	jz	short @F	; Not this time

	mov	DBG_DR7.ELO[DBG_DR7_G0],'0G' ; Mark as set
@@:
	test	ax,mask $L0	; Izit set?
	jz	short @F	; Not this time

	mov	DBG_DR7.ELO[DBG_DR7_L0],'0L' ; Mark as set
@@:
	REGREST <edi,ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DR7 endp			; End DISP_DR7 procedure
	NPPROC	RESPEC_DR7 -- Respecify DR7
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Respecify DR7

On entry:

EDI	=	offset into BDREGS of current register

|

	REGSAVE <eax,ebx,ecx,edx> ; Save for a moment

	mov	eax,SAVE_DR7	; Get control register

; Set DR7 length/type mask

	movzx	edx,BDREGS[edi].BD_LEN ; Get length bits
	shl	edx,$LEN0-$RW0	; Shift over
	or	dl,BDREGS[edi].BD_TYPE ; Plus type bits
	mov	cl,BDREGS[edi].BD_LSHF ; Get length/type shift amount
	mov	ebx,((mask $LEN0) or (mask $RW0)) shr $RW0 ; Get the bit mask
	shl	ebx,cl		; Shift into place
	not	ebx		; Complement to clear DR7
	and	eax,ebx 	; Clear value for DR7
	shl	edx,cl		; Shift into place
	or	eax,edx 	; Set length/type mask

; Set DR7 enable mask

	mov	edx,(mask $G0) or (mask $L0) ; Get mask for DR0
	mov	cl,BDREGS[edi].BD_ESHF ; Get enable shift amount
	shl	edx,cl		; Shift into place
	or	eax,edx 	; Set enable mask

; Set global enable bit

	or	eax,mask $GE	; Set it

; Set debug control register

	mov	SAVE_DR7,eax	; Set it

	REGREST <edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESPEC_DR7 endp 		; End RESPEC_DR7 procedure
	NPPROC	DISP_BC -- Display All Code Breakpoints
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display all code breakpoints

On entry:

SS:EBP	==>	FORW_STR

|

	REGSAVE <eax,ebx,ecx,esi,edi> ; Save registers

	xor	esi,esi 	; Initialize index into BCDATA
	lea	ebx,BC_LN1	; Initialize index into BC_WIN
	mov	ecx,@NBC	; # code breakpoints
DISP_BC_NEXT:
	mov	al,' '          ; Assume not in use

	test	BCDATA.BC_FLAG[esi],@ADDR_INUSE ; Izit in use?
	jz	short @F	; Jump if not

	mov	al,'+'          ; Assume enabled

	test	BCDATA.BC_FLAG[esi],@ADDR_ENA ; Izit enabled?
	jnz	short @F	; Jump if so

	mov	al,'-'          ; Assume disabled
@@:
	mov	BC_WIN_EN0[ebx],al ; Save in output display

	mov	eax,@NBC	; Get maximum value
	sub	eax,ecx 	; Less current value
	lea	edi,BC_WIN_IN0[ebx] ; ES:EDI ==> index display
	call	BIN2DIGIT	; Convert the digit

	mov	ax,BCDATA.BC_SEL[esi] ; Get BC selector
	lea	edi,BC_WIN_SL0[ebx] ; ES:EDI ==> selector display
	call	BIN2WORD	; Convert the word

	mov	al,'?'          ; Assume not in use

	test	BCDATA.BC_FLAG[esi],@ADDR_INUSE ; Izit in use?
	jz	short @F	; Not this time

	mov	al,'|'          ; Assume PM

	test	BCDATA.BC_FLAG[esi],@ADDR_PM ; Izit Protected Mode?
	jnz	short @F	; Yes

	mov	al,':'          ; It's VM86
@@:
	mov	BC_WIN_SP0[ebx],al ; Save in window

	mov	eax,BCDATA.BC_OFF[esi] ; Get BC offset
	lea	edi,BC_WIN_OF0[ebx] ; ES:EDI ==> offset display
	call	BIN2DWORD	; Convert the dword

	mov	eax,BCDATA.BC_LIN[esi] ; Get linear address
	lea	edi,BC_WIN_BC0[ebx] ; ES:EDI ==> linear address display
	call	BIN2DWORD	; Convert the dword

	mov	BC_WIN_VL0[ebx].ELO,'__' ; Assume not in use

	test	BCDATA.BC_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short @F	; Jump if not

	mov	al,BCDATA.BC_VAL[esi] ; Get original value
	lea	edi,BC_WIN_VL0[ebx] ; ES:EDI ==> original value display
	call	BIN2BYTE	; Convert the byte
@@:
	add	esi,size BC_STR ; Skip to next row in BCDATA
	add	ebx,NBCCOLS	; Skip to next row in BC_WIN

;;;;;;; loop	DISP_BC_NEXT	; Jump if more rows to format
	dec	ecx		; Less one row
	jnz	DISP_BC_NEXT	; Jump if more rows to format

; Display the window

	mov	W_BC.SROW,(@NROWS-NBCROWS)/2 ; Start in middle row
	mov	W_BC.SCOL,(@NCOLS-NBCCOLS)/2 ; Start in middle col
	mov	W_BC.NROW,NBCROWS ; # rows in debug window
	mov	W_BC.NCOL,NBCCOLS ; # cols ...

	mov	al,DBGATTR	; Get debug window attribute
	push	ax		; Pass as attribute to smear
	push	offset ds:BC_WIN ; Pass address of debug window
	push	offset ds:W_BC	; Pass address of window descriptor
	call	WPUT_CSA	; Output the characters, smear attribute

	mov	al,@DSP_BC	; Set new display state
	call	SET_STATE	; Set new state

	REGREST <edi,esi,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_BC endp			; End DISP_BC procedure
	NPPROC	DISP_BP -- Display All Page Breakpoints
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display all page breakpoints

On entry:

SS:EBP	==>	FORW_STR

|

	REGSAVE <eax,ebx,ecx,esi,edi> ; Save registers

	xor	esi,esi 	; Initialize index into BPDATA
	lea	ebx,BP_LN1	; Initialize index into BP_WIN
	mov	ecx,@NBP	; # page breakpoints
DISP_BP_NEXT:
	mov	al,' '          ; Assume not in use

	test	BPDATA.BP_FLAG[esi],@ADDR_INUSE ; Izit in use?
	jz	short @F	; Jump if not

	mov	al,'+'          ; Assume enabled

	test	BPDATA.BP_FLAG[esi],@ADDR_ENA ; Izit enabled?
	jnz	short @F	; Jump if so

	mov	al,'-'          ; Assume disabled
@@:
	mov	BP_WIN_EN0[ebx],al ; Save in output display

	mov	eax,@NBP	; Get maximum value
	sub	eax,ecx 	; Less current value
	lea	edi,BP_WIN_IN0[ebx] ; ES:EDI ==> index display
	call	BIN2DIGIT	; Convert the digit

	mov	ax,BPDATA.BP_SEL[esi] ; Get BP selector
	lea	edi,BP_WIN_SL0[ebx] ; ES:EDI ==> selector display
	call	BIN2WORD	; Convert the word

	mov	al,'?'          ; Assume not in use

	test	BPDATA.BP_FLAG[esi],@ADDR_INUSE ; Izit in use?
	jz	short @F	; Not this time

	mov	al,'|'          ; Assume PM

	test	BPDATA.BP_FLAG[esi],@ADDR_PM ; Izit Protected Mode?
	jnz	short @F	; Yes

	mov	al,':'          ; It's VM86
@@:
	mov	BP_WIN_SP0[ebx],al ; Save in window

	mov	eax,BPDATA.BP_OFF[esi] ; Get BP offset
	lea	edi,BP_WIN_OF0[ebx] ; ES:EDI ==> offset display
	call	BIN2DWORD	; Convert the dword

	mov	eax,BPDATA.BP_LIN[esi] ; Get linear address
	lea	edi,BP_WIN_BC0[ebx] ; ES:EDI ==> linear address display
	call	BIN2DWORD	; Convert the dword

	add	esi,size BP_STR ; Skip to next row in BPDATA
	add	ebx,NBPCOLS	; Skip to next row in BP_WIN

;;;;;;; loop	DISP_BP_NEXT	; Jump if more rows to format
	dec	ecx		; Less one row
	jnz	DISP_BP_NEXT	; Jump if more rows to format

; Display the window

	mov	W_BP.SROW,(@NROWS-NBPROWS)/2 ; Start in middle row
	mov	W_BP.SCOL,(@NCOLS-NBPCOLS)/2 ; Start in middle col
	mov	W_BP.NROW,NBPROWS ; # rows in debug window
	mov	W_BP.NCOL,NBPCOLS ; # cols ...

	mov	al,DBGATTR	; Get debug window attribute
	push	ax		; Pass as attribute to smear
	push	offset ds:BP_WIN ; Pass address of debug window
	push	offset ds:W_BP	; Pass address of window descriptor
	call	WPUT_CSA	; Output the characters, smear attribute

	mov	al,@DSP_BP	; Set new display state
	call	SET_STATE	; Set new state

	REGREST <edi,esi,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_BP endp			; End DISP_BP procedure
	NPPROC	CHECK_DBG -- Check linear address for inclusion in breakpt list
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for a linear address in a list of breakpoints.  This is called
for every instruction line disassembled, so speed is important.

On entry:
EAX	=      linear address to check for

On exit:
CF=1		not a breakpoint
CF=0		is a breakpoint (type unspecified)

CHECK_DBG_RES is also set to 1 if breakpoint, otherwise 0.

|

	REGSAVE <ecx,edi>	; Save registers

	mov	ecx,BREAKLIST_CNT ; Get number of breakpoints active
	jecxz	short CHECK_DBG_ERR ; None active

	lea	edi,BREAKLIST	; Address active breakpoint list
  repne scas	BREAKLIST[edi]	; Find a match
	jnz	short CHECK_DBG_ERR ; Jump if not found

	mov	CHECK_DBG_RES,1 ; Signal success
	clc			; ...
	jmp	short CHECK_DBG_EXIT ; Join common exit code

CHECK_DBG_ERR:
	mov	CHECK_DBG_RES,0 ; Signal failure
	stc			; ...
CHECK_DBG_EXIT:
	REGREST <edi,ecx>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DBG endp			; End CHECK_DBG procedure
	NPPROC UD_BREAKLIST -- Update breakpoint list
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Called after any changes to code or data breakpoints.

Walk through breakpoint structures and update breakpoint list.	This
allows the check for a line with breakpoints on it to be done quickly
when disassembling.

On entry:
nothing

On exit:
nothing

|

	REGSAVE <eax,ecx,esi,edi> ; Save registers

	sub	edi,edi 	; Index first member of BREAKLIST[]
	mov	BREAKLIST_CNT,0 ; Clear count

	sub	esi,esi 	; Index first member of BDREGS
	mov	ecx,4		; Number of debug registers
UD_BREAKLIST_NEXT:
	test	BDREGS.BD_FLAG[esi],@ADDR_INUSE ; Izit used?
	jz	short @F	; Jump if not

	test	BDREGS.BD_FLAG[esi],@ADDR_ENA ; Izit enabled?
	jz	short @F	; Jump if not

	inc	BREAKLIST_CNT	; Increment count of breakpoints
	mov	eax,BDREGS.BD_BASE[esi] ; Get linear base address
	add	eax,BDREGS.BD_OFF[esi] ; Add offset
	mov	BREAKLIST[edi],eax ; Save linear address
	add	edi,type BREAKLIST ; Skip to next dword
@@:
	add	esi,size BD_STR ; Skip to next register structure
	loop	UD_BREAKLIST_NEXT ; Check all debug registers

	sub	esi,esi 	; Index first member of BCDATA
	mov	ecx,@NBC	; Number of code breakpoints
UD_BREAKLIST_NEXT2:
	test	BCDATA.BC_FLAG[esi],@ADDR_INUSE ; Izit in use?
	jz	short @F	; Jump if not

	test	BCDATA.BC_FLAG[esi],@ADDR_ENA ; Izit enabled?
	jz	short @F	; Jump if not

	inc	BREAKLIST_CNT	; Increment count of breakpoints
	mov	eax,BCDATA.BC_LIN[esi] ; Get linear address
	mov	BREAKLIST[edi],eax ; Save it
	add	edi,type BREAKLIST ; Skip to next dword
@@:
	add	esi,size BC_STR ; Skip to next breakpoint structure
	loop	UD_BREAKLIST_NEXT2 ; Check all code breakpoints

	or	LCL_FLAG,@LCL_REDI ; Force redisplay

	REGREST <edi,esi,ecx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UD_BREAKLIST endp		; End UD_BREAKLIST procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_DBG module
