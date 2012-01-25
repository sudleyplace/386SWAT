;' $Header:   P:/PVCS/386SWAT/SWAT_DAT.ASV   1.13   10 Jul 1997 14:46:24   BOB  $
	title	SWAT_DAT-- 386SWAT Data Command Functions
	page	58,122
	name	SWAT_DAT

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-2003 Qualitas, Inc.  All rights reserved.

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

	include SWAT_CMD.INC
	include SWAT_COM.INC
	include SWAT_MOD.INC
	include SWAT_SEG.INC
.list

DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	MSGOFF:dword
	extrn	SYNTERR:byte
	extrn	OVFERR:byte

	extrn	DSP_STATE:byte
	extrn	DSP_STAT2:byte

	extrn	MEMOFF:dword
	extrn	MEMSIZE:dword
	extrn	MEMBASE:dword
	extrn	MEMSEL:word
	extrn	MEMCR3:dword
	extrn	MEMMODE:word
	extrn	MEMMASK:dword
	extrn	MEMTYPE:dword
	extrn	MEMCNT:dword
	extrn	MEMCNTMAX:dword

	extrn	TSSTYPE:word

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP

	extrn	CMD_WHITE:near
	extrn	PARSE_ADDR:near
	extrn	PARSE_EXPR:near

	extrn	MEMACT_B:near
	extrn	MEMACT_W:near
	extrn	MEMACT_D:near
	extrn	MEMACT_V:near
	extrn	MEMACT_G:near
	extrn	MEMACT_I:near
	extrn	MEMACT_T:near

	NPPROC	CMD_DATAB -- Data Byte Display Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data byte display command

DB opt_addr

|

	call	MEMACT_B	; Mark as byte display

	jmp	CMD_DATA	; Join common data display code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_DATAB endp			; End CMD_DATAB procedure
	NPPROC	CMD_DATAW -- Data Word Display Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data word display command

DW opt_addr

|

	call	MEMACT_W	; Mark as word display

	jmp	short CMD_DATA	; Join common data display code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_DATAW endp			; End CMD_DATAW procedure
	NPPROC	CMD_DATAD -- Data Dword Display Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data dword display command

DD opt_addr

|

	call	MEMACT_D	; Mark as dword display

	jmp	short CMD_DATA	; Join common data display code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_DATAD endp			; End CMD_DATAD procedure
	NPPROC	CMD_DATAV -- Data Vector Display Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data vector display command

DV opt_addr

|

	call	MEMACT_V	; Mark as vector display

	jmp	short CMD_DATA	; Join common data display code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_DATAV endp			; End CMD_DATAV procedure
	NPPROC	CMD_DATAG -- Data GDT Display Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data GDT display command

DG opt_addr

|

	call	MEMACT_G	; Mark as GDT display

	jmp	short CMD_DATA	; Join common data display code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_DATAG endp			; End CMD_DATAG procedure
	NPPROC	CMD_DATAI -- Data IDT Display Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data IDT display command

DI opt_addr

|

	call	MEMACT_I	; Mark as IDT display

	jmp	short CMD_DATA	; Join common data display code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_DATAI endp			; End CMD_DATAI procedure
	NPPROC	CMD_DATAT -- Data TSS Display Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data TSS display command

DT opt_addr

|

	call	MEMACT_T	; Mark as TSS display

	jmp	short CMD_DATA	; Join common data display code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_DATAT endp			; End CMD_DATAT procedure
	NPPROC	CMD_DATAT2 -- Data 286 TSS Display Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data 286 TSS display command

DT2 opt_addr

|

	mov	TSSTYPE,@TSS286 ; Mark as displaying 286 TSS

	call	MEMACT_T	; Mark as TSS display

	jmp	short CMD_DATA	; Join common data display code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_DATAT2 endp 		; End CMD_DATAT2 procedure
	NPPROC	CMD_DATAT3 -- Data 386 TSS Display Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data 386 TSS display command

DT3 opt_addr

|

	mov	TSSTYPE,@TSS386 ; Mark as displaying 386 TSS

	call	MEMACT_T	; Mark as TSS display

	jmp	short CMD_DATA	; Join common data display code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_DATAT3 endp 		; End CMD_DATAT3 procedure
	NPPROC	CHECK_WIDTH -- Check For Data Width
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for data width parameter

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise
DS:ESI	==>	character after data width (if present)

|

	REGSAVE <eax,ebx,ecx>	; Save registers

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	cmp	al,'/'          ; Izit data width switch?
	jne	short CHECK_WIDTH_DONE ; Jump if not

	inc	esi		; Skip over it

	call	PARSE_EXPR	; Parse command line for an expression
	jc	short CHECK_WIDTH_EXIT ; Jump if something went wrong (note CF=1)

	mov	ebx,MEMTYPE	; Get the memory type
	mov	ecx,MEMCNTMAX[ebx*(type MEMCNTMAX)] ; Get the maximum count

	cmp	eax,ecx 	; Izit too big?
	jbe	short @F	; Jump if not

	mov	eax,ecx 	; Use the maximum
@@:
	cmp	eax,1		; Izit too small?
	adc	eax,0		; Add in 1 if so

	mov	MEMCNT[ebx*(type MEMCNT)],eax ; Save as new line count
CHECK_WIDTH_DONE:
	clc			; Mark as successful
CHECK_WIDTH_EXIT:
	REGREST <ecx,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_WIDTH endp		; End CHECK_WIDTH procedure
	NPPROC	CMD_DATA -- Data Display Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data display command

Dx-
Dx opt_addr
Dx addr P
Dx addr P exp

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	call	CHECK_WIDTH	; Split off data width, if present
	jc	near ptr CMD_DATA_EXIT1 ; Jump if in error (note CF=1)

; Split off backwards display case

	cmp	DGROUP:[esi].LO,'-' ; Izit backwards?
	je	near ptr CMD_DATABACK ; Jump if so

	REGSAVE <eax,ebx,ecx,edx> ; Save registers

	REGSAVE <MEMMODE,MEMCR3,MEMOFF,MEMSEL,MEMBASE,MEMMASK> ; Save values

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_DATA_PGDN ; Yes, treat as page down

	call	PARSE_ADDR	; Parse DS:ESI for address
	jc	near ptr CMD_DATA_ERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)
	mov	MEMOFF,eax	; Save for display purposes

	and	MEMMODE,not @MODE_PHYS ; Mark as no physical translation

; Check for optional physical marker

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	or	al,20h		; Convert to lowercase

	cmp	al,'p'          ; Izit physical marker?
	jne	short CMD_DATA1 ; Jump if not

	inc	esi		; Skip over it
	or	MEMMODE,@MODE_PHYS ; Mark as physical translation
	mov	MEMCR3,0	; Assume one-to-one translation

; Check for optional CR3

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	cmp	al,0		; Izit end-of-the-line?
	je	short CMD_DATA2 ; Jump if so

; Parse CR3 value for translation

	call	PARSE_EXPR	; Parse command line for an expression
	jc	near ptr CMD_DATA_ERR ; Jump if too large

	and	ax,mask $PTE_FRM ; Isolate 4KB frame
	mov	MEMCR3,eax	; Save as CR3 for translation
CMD_DATA1:

; Ensure nothing more on the line

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	cmp	al,0		; Izit end-of-the-line?
	jne	near ptr CMD_DATA_SYNTERR ; No, so that's an error
CMD_DATA2:
	test	cx,@ADDR_SEP	; Separator specified?
	jz	short @F	; Not this time

	mov	MEMSEL,bx	; Save for display purposes
	mov	MEMBASE,edx	; Save for later use

	and	MEMMODE,not @MODE_VM ; Mark as protected mode
	mov	MEMMASK,-1	; Use all 32 bits

	test	cx,@ADDR_PM	; Check mode
	jnz	short @F	; Jump if PM

	or	MEMMODE,@MODE_VM ; Mark as VM86 mode
	mov	MEMMASK,0000FFFFh ; Use low-order 16 bits
@@:
	mov	eax,MEMOFF	; Get specified offset

	cmp	eax,MEMMASK	; Ensure within mask limits
	ja	short CMD_DATA_OVFERR ; Jump if not

	jmp	short CMD_DATA_CLC ; Join common OK code


CMD_DATA_PGDN:
	test	MEMMODE,@MODE_NEW ; Is this a new mode?
	jnz	short @F	; Yes, don't change the offset

	mov	eax,@NROWS-2	; Get # screen rows in memory display
	mul	MEMSIZE 	; Times size of one memory row
	add	MEMOFF,eax	; Skip to next page
@@:
	and	MEMMODE,not @MODE_NEW ; No longer a new mode
CMD_DATA_CLC:
	mov	DSP_STATE,@DSP_MEM ; Mark as memory state
	mov	DSP_STAT2,@DSP_MEM ; Secondary ...
	or	LCL_FLAG,@LCL_REDI ; Mark as forced re-display of screen

; Use TYPE instead of SIZE in case any of the items is defined by EQU

	add	esp,(type MEMMODE) + (type MEMCR3)  + (type MEMOFF) + \
		     (type MEMSEL)  + (type MEMBASE) + (type MEMMASK)

	clc			; Indicate all went well

	jmp	short CMD_DATA_EXIT ; Join common exit code


CMD_DATA_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	jmp	short CMD_DATA_ERR ; Join common error exit code


CMD_DATA_OVFERR:
	mov	MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

;;;;;;; jmp	short CMD_DATA_ERR ; Join common error exit code


CMD_DATA_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	REGREST <MEMMASK,MEMBASE,MEMSEL,MEMOFF,MEMCR3,MEMMODE> ; Restore values

	stc			; Mark as in error
CMD_DATA_EXIT:
	REGREST <edx,ecx,ebx,eax> ; Restore
CMD_DATA_EXIT1:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_DATA endp			; End CMD_DATA procedure
	NPPROC	CMD_DATABACK -- Data Display Backwards Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data display backwards command

Dx-

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	REGSAVE <eax>		; Save registers

	inc	esi		; Skip over the '-'

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	jne	short CMD_DATABACK_SYNTERR ; No, so that's an error

	mov	eax,@NROWS-2	; Get # screen rows in memory display
	mul	MEMSIZE 	; Times size of one memory row
	sub	MEMOFF,eax	; Skip to previous page

	mov	DSP_STATE,@DSP_MEM ; Mark as memory state
	mov	DSP_STAT2,@DSP_MEM ; Secondary...
	or	LCL_FLAG,@LCL_REDI ; Mark as forced re-display of screen

	clc			; Indicate all went well

	jmp	short CMD_DATABACK_EXIT ; Join common exit code


CMD_DATABACK_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_DATABACK_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_DATABACK endp		; End CMD_DATABACK procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_DAT module
