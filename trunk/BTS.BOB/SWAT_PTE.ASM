;' $Header:   P:/PVCS/386SWAT/SWAT_PTE.ASV   1.11   10 Aug 1998 11:01:22   BOB  $
	title	SWAT_PTE -- 386SWAT PTE Command Functions
	page	58,122
	name	SWAT_PTE

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-2002 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1993.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include ALLMEM.INC
	include CPUFET.INC
	include MOVSPR.INC
	include IOPBITS.INC

	include SWAT_CMD.INC
	include SWAT_COM.INC
	include SWAT_SEG.INC
.list

DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	CMD_LINE_TERM:byte
	extrn	CPUFET_FLAG:dword

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	@SWAT_PTE_DATA
@SWAT_PTE_DATA label byte	; Mark module start in .MAP file

	extrn	MSGOFF:dword
	extrn	SYNTERR:byte
	extrn	PAGERR:byte

	extrn	PTE_START:dword
	extrn	DSP_STATE:byte
	extrn	DSP_STAT2:byte

	public	PTEOFF,PTECR3
PTEOFF	dd	?		; Offset in address
PTECR3	dd	?		; CR3 to use in translation

	public	PDE_BITS,PDE_BITS_LEN
PDE_BITS dw	' G'            ; Global
	dw	'SP'            ; Page Size
	dw	' D'            ; Dirty
	dw	' A'            ; Accessed
	dw	'DC'            ; Cache-disable
	dw	'TW'            ; Write-through
	dw	' U'            ; User
	dw	' W'            ; Writable
	dw	' P'            ; Present
PDE_BITS_LEN equ ($-PDE_BITS)/(type PDE_BITS) ; # entries

	public	PTE_BITS,PTE_BITS_LEN
PTE_BITS dw	' G'            ; Global
	dw	'SP'            ; (Unused)
	dw	' D'            ; Dirty
	dw	' A'            ; Accessed
	dw	'DC'            ; Cache-disable
	dw	'TW'            ; Write-through
	dw	' U'            ; User
	dw	' W'            ; Writable
	dw	' P'            ; Present
PTE_BITS_LEN equ ($-PTE_BITS)/(type PTE_BITS) ; # entries

	public	MSG_PDTE
MSG_PDTE db	' = '
MSG_PDTE1 db	(80-($-MSG_PDTE)) dup (' ')

PTEREC	record	$PTE_SHOW:1, \
		$PTE_PHYS:1
@PTE_SHOW equ	(mask $PTE_SHOW) ; 02:	Show PTE command
@PTE_PHYS equ	(mask $PTE_PHYS) ; 01:	Physical translation

	public	PTECMD
PTECMD	PTEREC	<>		; Command type (Normal vs. Show)

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP

	public	@SWAT_PTE_PROG
@SWAT_PTE_PROG: 		; Mark module start in .MAP file

	extrn	IZITEOL:near
	extrn	CMD_WHITE:near
	extrn	PARSE_ADDR:near
	extrn	PARSE_EXPR:near
	extrn	BIN2DWORD:near
	extrn	READ_CR3:near
	extrn	LIN2PPTE:near
	extrn	LIN2PPDIR:near
	extrn	LIN2PPTEZ:near

	extrn	ENDOF_CMDLINE:near
	extrn	DISP_CMDLINE:near
	extrn	PURGE_KBUFF:near
	extrn	GETNDKEY:near
	extrn	U32_LOWERCASE:near

	extrn	DISP_PTE:near

	NPPROC	CMD_SPTE -- SPTE Calculation Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

SPTE calculation command

SPTE addr
SPTE exp
SPTE addr P exp
SPTE exp  P exp

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	or	PTECMD,@PTE_SHOW ; Mark as show PTE command

	jmp	short CMD_PTE_COM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_SPTE endp			; End CMD_SPTE procedure
	NPPROC	CMD_PTE -- PTE Calculation Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

PTE calculation command

PTE addr
PTE exp
PTE addr P exp
PTE exp  P exp

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	and	PTECMD,not @PTE_SHOW ; Mark as normal PTE command
CMD_PTE_COM:
	REGSAVE <eax,ebx,ecx,edx,edi,fs> ; Save registers

	call	IZITEOL 	; Izit end-of-the-line?
	je	near ptr CMD_PTE_SYNTERR ; Yes, so that's an error

	call	PARSE_ADDR	; Parse command line for an address
	jc	near ptr CMD_PTE_ERR ; Jump if error
				; BX  = selector/segment (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = 32-bit base address for BX
	mov	PTEOFF,eax	; Save for later use

; Check for optional physical marker

	call	READ_CR3	; Get the value into EAX
	and	ax,mask $PTE_FRM ; Isolate 4KB frame
	mov	PTECR3,eax	; Use as default value

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	call	U32_LOWERCASE	; Convert AL to lowercase

	cmp	al,'p'          ; Izit physical marker?
	jne	short CMD_PTE_XPHYS ; Jump if not

	inc	esi		; Skip over it

; Check for required CR3

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_PTE_SYNTERR ; Jump if so

; Parse CR3 value for translation

	call	PARSE_EXPR	; Parse command line for an expression
	jc	near ptr CMD_PTE_ERR ; Jump if too large

	and	ax,mask $PTE_FRM ; Isolate 4KB frame
	mov	PTECR3,eax	; Save as CR3 for translation
	and	PTECMD,not @PTE_SHOW ; No Show PTE for physical displays
	or	PTECMD,@PTE_PHYS ; Mark as physical
CMD_PTE_XPHYS:

; Ensure nothing more on the line

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,'='          ; Izit start of result leftover from /PTE?
	je	short @F	; Jump if so

	cmp	al,0		; Izit end-of-the-line?
@@:
	jne	near ptr CMD_PTE_SYNTERR ; No, so that's an error

	mov	ds:[esi].LO,0	; Mark as EOL in case trailing result

; If the address has a segment/selector part, convert it into a linear address

	mov	eax,PTEOFF	; Get the offset

	test	cx,@ADDR_SEP	; Izit specified?
	jz	short @F	; Jump if not

	add	eax,edx 	; Add to get 32-bit linear address
@@:

; If we're using optional physical translation, don't worry about $PG

	test	PTECMD,@PTE_PHYS ; Izit physical?
	jnz	short @F	; Jump if so

	mov	ebx,cr0 	; Get register with Paging bit

	test	ebx,mask $PG	; Izit enabled?
	jz	near ptr CMD_PTE_PAGERR ; Jump if not
@@:
	lea	edi,MSG_PDTE1	; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	mov	ebx,eax 	; Save the linear address

	PUSHD	0		; Make room for original PTE
	PUSHD	1		; # PTEs to follow
	PUSHD	0		; Make room for original PDE
	push	ebx		; Pass the linear address
	push	PTECR3		; Pass the CR3 to use
	call	LIN2PPDIR	; Return with AGROUP:EAX ==> corresponding PDIR

	mov	eax,AGROUP:[eax] ; Get the corresponding PDIR

	call	LIN2PPTEZ	; Cleanup after LIN2PPDIR
	add	esp,1*4 	; Pop the PTE

	mov	es:[edi].LO,' ' ; Save separator
	inc	edi		; Skip over it

	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

; Display the low-order page directory type bits

	push	eax		; Pass the PDE
	push	offset DGROUP:PDE_BITS ; Pass the table offset in DGROUP
	push	PDE_BITS_LEN	; Pass the table length
	call	DISP_PAGE_BITS	; Dispay the page bits,
				; return with ES:EDI ==> next byte
	test	eax,mask $PTE_P ; Izit present?
	jz	short CMD_PTE1	; Jump if not

	test	CPUFET_FLAG,@CPUFET_PSE ; Are Page-Size Extensions supported?
	jz	short @F	; Jump if not

	MOVSPR	ecx,cr4 	; Get current Arch Ext register

	test	ecx,@PSE	; Are 4MB pages active?
	jz	short @F	; Jump if not

	test	eax,mask $PTE_PS ; Izit a 4MB page?
	jnz	short CMD_PTE1	; Jump if so
@@:
	PUSHD	0		; Make room for original PTE
	PUSHD	1		; # PTEs to follow
	PUSHD	0		; Make room for original PDE
	push	ebx		; Pass the linear address
	push	PTECR3		; Pass the CR3 to use
	call	LIN2PPTE	; Return with AGROUP:EAX ==> corresponding PTE

	mov	eax,AGROUP:[eax] ; Get the corresponding PTE

	call	LIN2PPTEZ	; Cleanup after LIN2PPTE
	add	esp,1*4 	; Pop the PTE

	mov	es:[edi].LO,' ' ; Save separator
	inc	edi		; Skip over it

	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

; Display the low-order page table type bits

	push	eax		; Pass the PTE
	push	offset DGROUP:PTE_BITS ; Pass the table offset in DGROUP
	push	PTE_BITS_LEN	; Pass the table length
	call	DISP_PAGE_BITS	; Dispay the page bits

	jmp	short CMD_PTE2	; Join common code

CMD_PTE1:
	and	PTECMD,not @PTE_SHOW ; No Show PTE for not present PDIRs
CMD_PTE2:
	test	PTECMD,@PTE_PHYS ; Izit physical?
	jz	short @F	; Jump if not

	mov	es:[edi].LO,' ' ; Save separator
	inc	edi		; Skip over it

	mov	eax,PTECR3	; Get the CR3 we're using
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI
@@:
	lea	esi,MSG_PDTE	; DS:ESI ==> message to display
	mov	ecx,edi 	; Copy address of next available byte
	sub	ecx,esi 	; ECX = # bytes in message

	call	ENDOF_CMDLINE	; Return with ES:EDI ==> end of the command line

	add	ecx,edi 	; Get end of line after copy
	lea	eax,CMD_LINE_TERM ; Use maximum

	cmp	ecx,eax 	; Izit too long?
	jbe	short @F	; Jump if not

	mov	ecx,eax 	; Use maximum
@@:
	sub	ecx,edi 	; Less end of the line
S32 rep movs	<MSG_PDTE[edi],MSG_PDTE[esi]> ; Copy to command line

; If it's show PTE time, display the PTE screen

	test	PTECMD,@PTE_SHOW ; Izit show PTE time?
	jz	short @F	; Jump if not

	shr	ebx,12-0	; Convert from bytes to 4KB
	shl	ebx,12-(12-2)	; Convert from 4KB to 4KB in dwords
	mov	PTE_START,ebx	; Save as PTE display start

	mov	al,@DSP_PTE	; Screen state is PTE
	mov	DSP_STATE,al	; Set primary state
	mov	DSP_STAT2,al	; ... secondary ...
	call	DISP_PTE	; Display the PTEs
@@:
	call	DISP_CMDLINE	; Display the command line
	call	PURGE_KBUFF	; First purge the keyboard buffer
	call	GETNDKEY	; Get non-destructive key

	clc			; Indicate all went well

	jmp	short CMD_PTE_EXIT ; Join common exit code

CMD_PTE_PAGERR:
	mov	MSGOFF,offset DGROUP:PAGERR ; Save offset of error message
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	jmp	short CMD_PTE_ERR ; Join common error exit code

CMD_PTE_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

;;;;;;; jmp	short CMD_PTE_ERR ; Join common error exit code

CMD_PTE_ERR:
	stc			; Mark as in error
CMD_PTE_EXIT:
	REGREST <fs,edi,edx,ecx,ebx,eax> ; Restore
	assume	fs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_PTE endp			; End CMD_PTE procedure
	NPPROC	DispBits -- Display Bits
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display Bits

On entry:

ES:EDI	==>	output save area

On exit:

ED:EDI	==>	(updated)

|

DB_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
DB_LEN	dd	?		; Table length
DB_TAB	dd	?		; Table offset in DGROUP
DB_PAG	dd	?		; Value

DB_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ebx,ecx,edx,esi> ; Save registers

	mov	edx,[ebp].DB_PAG ; Get the value
	mov	ecx,[ebp].DB_LEN ; Get # low-order bits to check
	ror	edx,cl		; Rotate to high-order bits
	xor	ebx,ebx 	; Initialize index into table
	mov	esi,[ebp].DB_TAB ; Get offset in DGROUP of table

	mov	ax,'( '         ; Get separator
	stos	es:[edi].ELO	; Save in output area
DispBitsNext:
	shl	edx,1		; Check the next bit
	jnc	short @F	; Jump if clear

	mov	ax,DGROUP:[esi+ebx*(type PTE_BITS)] ; Get next entry
	stos	es:[edi].ELO	; Save in output area

	cmp	ah,' '          ; Already got a separator?
	je	short @F	; Jump if so

	mov	al,' '          ; Get separator
	stos	es:[edi].LO	; Save in output area
@@:
	inc	ebx		; Skip to next entry

	loop	DispBitsNext	; Jump if more bits to display

	cmp	es:[edi-1].LO,' ' ; Duzit end with a blank?
	jne	short @F	; Jump if not

	dec	edi		; Back up to it
@@:
	mov	al,')'          ; Get trailing separator
	stos	es:[edi].LO	; Save in output area

	REGREST <esi,edx,ecx,ebx,eax> ; Restore

	pop	ebp		; Restore

	ret	3*4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DispBits endp			; End DispBits procedure
	NPPROC	DISP_PAGE_BITS -- Display Page Bits
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display page bits

On entry:

ES:EDI	==>	output save area

On exit:

ED:EDI	==>	(updated)

|

DPB_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
DPB_LEN dd	?		; Table length
DPB_TAB dd	?		; Table offset in DGROUP
DPB_PAG dd	?		; PTE or PDE

DPB_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	test	[ebp].DPB_PAG,mask $PTE_P ; Izit present?
	jz	short @F	; Jump if not (other bits not meaningful)

	push	[ebp].DPB_PAG	; Pass the value
	push	[ebp].DPB_TAB	; ...	   table offset in DGROUP
	push	[ebp].DPB_LEN	; ...	   table length
	call	DispBits	; Display the bits
@@:
	pop	ebp		; Restore

	ret	3*4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_PAGE_BITS endp		; End DISP_PAGE_BITS procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_PTE module
