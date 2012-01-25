;' $Header:   P:/PVCS/386SWAT/SWAT_SRC.ASV   1.12   10 Jul 1997 14:47:48   BOB  $
	title	SWAT_SRC -- 386SWAT Search Data Command Functions
	page	58,122
	name	SWAT_SRC

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
	include PTR.INC
	include 386.INC
	include BITFLAGS.INC
	include ALLMEM.INC

	include SWAT_CMD.INC
	include SWAT_COM.INC
	include SWAT_MOD.INC
	include SWAT_SEG.INC
.list

DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	DEFATTR:byte
	extrn	TTLATTR:byte
	extrn	WRKATTR:byte

DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

@SRCPTE_BASE equ 0FFC00000h	; Base address for PTE search

	extrn	SCROFF:dword

	extrn	MSGOFF:dword
	extrn	SYNTERR:byte
	extrn	OVFERR:byte

	extrn	INSTROUT:byte
	extrn	@OFFBYTE:abs

	public	SRCHLEN,SRCHVAL,SRCHCNT,PSRCHCMP,PSRCHDSP,PSRCHTYP
	public	SRCHNOFF,SRCHNLEN,SRCHCNT,SRCHINC
	public	SRCHTEXTSTR,SRCHTEXTLEN
SRCHLEN dd	0		; Data search length
SRCHVAL dd	?		; ...	      value
PSRCHCMP dd	offset PGROUP:SRCH1CMP ; ...	    width compare action
PSRCHDSP dd	offset PGROUP:SRCH1DSP ; ...	    width display action
PSRCHTYP dd	offset DGROUP:SRCH_HBYTE ; ...	    width header type text
SRCHNOFF dd	?		; ...	      next search offset
SRCHNLEN dd	?		; ...	      next search length
SRCHCNT db	?		; ...	      line count
SRCHINC db	0		; Instruction search increment
				; 0 = next instruction
				; 1 = next byte
SRCHTEXTSTR db	80 dup (?)	; Text to search for
SRCHTEXTLEN dd	?		; Length of text search

	public	SRCHILEN,SRCHTEXT
SRCHILEN db	?		; Instruction search length
SRCHTEXT db	80 dup (?)	; Instruction search text

	public	SRCHWID_CMP
	align	4
SRCHWID_CMP dd	offset PGROUP:SRCH1CMP ; Conversion table for search width comparison
	dd	offset PGROUP:SRCH2CMP
	dd	offset PGROUP:SRCH4CMP
	dd	offset PGROUP:SRCH4CMP

	public	SRCHWID_CMPNOT
SRCHWID_CMPNOT dd offset PGROUP:SRCH1CMPNOT
	dd	offset PGROUP:SRCH2CMPNOT
	dd	offset PGROUP:SRCH4CMPNOT
	dd	offset PGROUP:SRCH4CMPNOT

	public	SRCHWID_DSP
SRCHWID_DSP dd	offset PGROUP:SRCH1DSP ; Conversion table for search width comparison
	dd	offset PGROUP:SRCH2DSP
	dd	offset PGROUP:SRCH4DSP
	dd	offset PGROUP:SRCH4DSP

	public	SRC1OFF,SRC1BASE,SRC1SEL,SRC1MODE,SRC1MASK
	align	4
SRC1OFF dd	0		; Data search #1 offset
SRC1BASE dd	0		; ...		 base
SRC1SEL dw	0		; ...		 selector
SRC1MODE dw	0		; ...		 mode (PM)
SRC1MASK dd	0FFFFFFFFh	; ...		 mask

	public	SRC2OFF,SRC2BASE,SRC2SEL,SRC2MODE,SRC2MASK
SRC2OFF dd	0		; Data search #2 offset
SRC2BASE dd	0		; ...		 base
SRC2SEL dw	0		; ...		 selector
SRC2MODE dw	0		; ...		 mode (PM)
SRC2MASK dd	0FFFFFFFFh	; ...		 mask

	public	SRCH_HDR,SRCH_HSEL,SRCH_HSEP,SRCH_HOFF1,SRCH_HOFF2
SRCH_HDR db	'ÚÄÄÄÄÄÄÂÄ '
SRCH_HSEL db	'xxxx'
SRCH_HSEP db	':'
SRCH_HOFF1 db	'xxxxxxxx - '
SRCH_HOFF2 db	'xxxxxxxx ÄÄÄÄÄÄÄÄ'
SRCH_HTYPE db	'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',0

	public  SRCHWID_TYP
	align	4
SRCHWID_TYP dd	offset DGROUP:SRCH_HBYTE ; Offset of header type text
	dd	offset DGROUP:SRCH_HWORD
	dd	offset DGROUP:SRCH_HDWORD
	dd	offset DGROUP:SRCH_HDWORD

	public  SRCH_HBYTE,SRCH_HWORD,SRCH_HDWORD,SRCH_HINSTR
SRCH_HBYTE db	'ÂÂÄÄÄÄÄÄ'             ; Header type text for byte search
SRCH_HWORD db	'ÂÄÄÂÄÄÄÄ'             ; ...                  word
SRCH_HDWORD db	'ÂÄÄÄÄÄÄÂ'             ; ...                  dword
SRCH_HINSTR db	'ÄÄÄÄÄÄÄÄ'             ; ...                  instr
SRCH_HTYPLEN equ $-SRCH_HINSTR		; Length of ...
SRCH_HPTE equ	SRCH_HDWORD		; ...		       PTE

	public  SRCH_LIN,SRCH_OFF,SRCH_LVAL
SRCH_LIN label	byte
SRCH_OFF db	'xxxxxxxx  '
SRCH_LVAL db	'00 11 22 33 44 55 66 77 88 99 AA xx AA 99 88 77 66 55 44 33 22 11 00  ',0
		 ;   0000 1111 2222 3333 4444 5555 xxxx 5555 4444 3333 2222 1111 0000	',0
		 ;	00000000 11111111 22222222 xxxxxxxx 22222222 11111111 0000000	',0
SRCH_LVLEN equ	$-SRCH_LVAL-1	; Length of line value

@SRCH1_OFF  equ 0		; Leading offset for byte display
@SRCH2_OFF  equ 3		; ...		     word
@SRCH4_OFF  equ 6		; ...		     dword
@SRCH1_SIDE equ 11		; # bytes displayed on each side of search
@SRCH2_SIDE equ 6		; # words ...
@SRCH4_SIDE equ 3		; # dwords ...

	public  MSG_WORK,MSG_DONE
MSG_WORK db	' Working '     ; Message when searching
MSG_WORKLEN equ $-MSG_WORK
MSG_DONE db	'ÄÄÄÄÄÄÄÄÄ'     ; Message when done searching
MSG_DONELEN equ $-MSG_DONE

	public	W_SRC
	align	2
W_SRC	W_STR	<0,@NCOLS-MSG_WORKLEN,1,MSG_WORKLEN> ; Window for Working

	public	SRC_FLAG
SRC_FLAG dd	0		; Search flags

SRC_REC record	$SRC_NOT:1

@SRC_NOT equ	mask $SRC_NOT	; Search for not the value

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP

	extrn	CMD_WHITE:near
	extrn	DISPASCIIZ:near
	extrn	BIN2BYTE:near
	extrn	BIN2WORD:near
	extrn	BIN2DWORD:near
	extrn	U32_LOWERCASE:near
	extrn	UPPERCASE:near
	extrn	PARSE_ADDR:near
	extrn	PARSE_ATOM:near
	extrn	PARSE_EXPR:near
	extrn	SET_STATE:near
	extrn	CLEAR_EOP:near

	extrn	INSTRDEC:near
	extrn	CLEAR_OUT:near
	extrn	WPUT_CSA:near

	extrn	INST_OPR0E:near
	extrn	REST_OPR0E:near

	extrn	READ_CR3:near
	extrn	LIN2PPDIR:near
	extrn	LIN2PPTEZ:near

	NPPROC	CMD_SRC1 -- Data Search One Byte Increment Command
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data search one byte increment command

S addr L len val
S addr addr  val

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	mov	SRCHINC,1	; Mark as next byte increment

	jmp	short CMD_SRCH_COM ; Join common code

CMD_SRC1 endp			; End CMD_SRC1 procedure
	NPPROC  CMD_SRCH -- Data Search Command
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT $

Data search command

S addr addr   val
S addr L expr val
S addr addr   ~val
S addr L expr ~val
S addr addr   ! instr
S addr L expr ! instr
S addr addr   # PTE
S addr L expr # PTE

Note that for PTE search, only the offsets of each address are used.

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

$

	mov	SRCHINC,0	; Mark as next instruction increment
CMD_SRCH_COM:
	pushad  		; Save all EGP registers

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_SRCH_DISP ; Yes, treat as request to display

	and	SRC1MODE,not @MODE_INSTR ; Mark as not searching instructions

	call	PARSE_ADDR	; Parse command line for an address
	jc	near ptr CMD_SRCH_ERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

	mov	SRC1OFF,eax	; Save for display purposes

	test	cx,@ADDR_SEP	; Separator specified?
	jz	short CMD_SRCH1 ; Not this time

	mov	SRC1SEL,bx	; Save for display purposes
	mov	SRC1BASE,edx	; Save for later use

	or	SRC1MODE,@MODE_SEP ; Mark as separator specified
	and	SRC1MODE,not @MODE_VM ; Mark as protected mode
	mov	SRC1MASK,-1	; Use all 32 bits

	test	cx,@ADDR_PM	; Check mode
	jnz	short CMD_SRCH1 ; Jump if PM

	or	SRC1MODE,@MODE_VM ; Mark as VM86 mode
	mov	SRC1MASK,0000FFFFh ; Use low-order 16 bits
CMD_SRCH1:

; Parse length separator or second address

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_SRCH_SYNTERR ; Yes, treat as error

	call	U32_LOWERCASE	; Convert AL to lowercase

	cmp	al,'l'          ; Izit length separator?
	je	near ptr CMD_SRCH_LPARM ; Yes, parse the length parameter

	call	PARSE_ADDR	; Parse command line for an address
	jc	near ptr CMD_SRCH_ERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

	mov	SRC2OFF,eax	; Save for display purposes

	test	cx,@ADDR_SEP	; Separator specified?
	jz	short CMD_SRCH2 ; Not this time

	mov	SRC2SEL,bx	; Save for display purposes
	mov	SRC2BASE,edx	; Save for later use

	or	SRC2MODE,@MODE_SEP ; Mark as separator specified
	and	SRC2MODE,not @MODE_VM ; Mark as protected mode
	mov	SRC2MASK,-1	; Use all 32 bits

	test	cx,@ADDR_PM	; Check mode
	jnz	short CMD_SRCH3 ; Jump if PM

	or	SRC2MODE,@MODE_VM ; Mark as VM86 mode
	mov	SRC2MASK,0000FFFFh ; Use low-order 16 bits

	jmp	short CMD_SRCH3 ; Join common code

; No separator specified -- use the ones from SRC1 if that was specified

CMD_SRCH2:
	test	SRC1MODE,@MODE_SEP ; Was 1st addr separator specified?
	jz	short CMD_SRCH3 ; Jump if not

	mov	ax,SRC1SEL	; Get the 1st selector
	mov	SRC2SEL,ax	; Save as 2nd

	mov	eax,SRC1BASE	; Get the 1st base
	mov	SRC2BASE,eax	; Save as 2nd

	mov	eax,SRC1MASK	; Get the 1st mask
	mov	SRC2MASK,eax	; Save as 2nd

	mov	ax,SRC1MODE	; Get the 1st mode
	mov	SRC2MODE,ax	; Save as 2nd
CMD_SRCH3:

; Calculate search length

	mov	eax,SRC2BASE	; Get second search base
	add	eax,SRC2OFF	; Plus its offset
	sub	eax,SRC1BASE	; Less first search base
	sub	eax,SRC1OFF	; Less first search offset
	inc	eax		; Convert from limit to length
	jnz	short @F	; Jump if no overflow

	dec	eax		; Back to -1
@@:
	jmp	short CMD_SRCH_LEN ; Join common code

CMD_SRCH_LPARM:
	mov	eax,SRC1MASK	; Get the 1st mask
	mov	SRC2MASK,eax	; Save as 2nd

	inc	esi		; Skip over length separator

; Parse length parameter

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

; Convert the expression at DS:ESI to binary

	call	PARSE_EXPR	; Parse command line for an expression
	jc	near ptr CMD_SRCH_OVFERR ; Jump if too large
CMD_SRCH_LEN:
	mov	SRCHLEN,eax	; Save for later use

	and	SRC_FLAG,not @SRC_NOT ; Clear the not flag

; Parse search value

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_SRCH_SYNTERR ; Yes, so that's an error

	cmp	al,'"'          ; Izit text search?
	je	near ptr CMD_SRCH_TEXT ; Jump if so

	cmp	al,'!'          ; Izit instruction search?
	je	near ptr CMD_SRCH_INSTR ; Jump if so

	cmp	al,'#'          ; Izit PTE search?
	je	near ptr CMD_SRCH_PTE ; Jump if so

	cmp	al,'~'          ; Izit not search?
	jne    short @F 	; Jump if not

	inc	esi		; Skip over NOT symbol

	or	SRC_FLAG,@SRC_NOT ; Set the not flag
@@:

; Convert the expression at DS:ESI to binary

	mov	ebx,esi 	; Save as old offset

COMMENT|

Note that we need to use PARSE_ATOM here not PARSE_EXPR as the latter
moves the pointer past trailing white space, but the former doesn't.
The length of the atom (presumed to be a constant) is used to
determine the width of the search.

|

	call	PARSE_ATOM	; Parse command line for an atom
	jc	near ptr CMD_SRCH_OVFERR ; Jump if too large

	mov	SRCHVAL,eax	; Save for later use

; Determine data search action (byte/word/dword) from # digits in value

	sub	ebx,esi 	; Less old offset
	neg	ebx		; Negate to make positive
				; EBX = 1 2 3 4 5 6 7 8
	dec	ebx		; EBX = 0 1 2 3 4 5 6 7
	and	ebx,not (2-1)	; EBX = 0 0 2 2 4 4 6 6
	shr	ebx,1		; EBX = 0 0 1 1 2 2 3 3

; Convert 0 1 2 3 into data search action

	mov	eax,SRCHWID_TYP[ebx*(type SRCHWID_TYP)]
	mov	PSRCHTYP,eax	; Save as data search header type text
	lea	eax,SRCHWID_CMP ; Assume not NOT

	test	SRC_FLAG,@SRC_NOT ; Searching for NOT?
	jz	short @F	; Jump if not

	lea	eax,SRCHWID_CMPNOT ; It's NOT
@@:
	mov	eax,DGROUP:[eax+ebx*(type SRCHWID_CMP)] ; Convert it
	mov	PSRCHCMP,eax	; Save as data search action routine
	mov	eax,SRCHWID_DSP[ebx*(type SRCHWID_DSP)] ; Convert it
	mov	PSRCHDSP,eax	; Save as data display action routine

; Ensure nothing more on the line

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	jne	near ptr CMD_SRCH_SYNTERR ; No, so that's an error

	jmp	CMD_SRCH_DISP	; Join common display code

CMD_SRCH_TEXT:
	inc	esi		; Skip over quote mark

	movzx	eax,ds:[esi].LO ; Get first character in text string
	mov	SRCHVAL,eax	; Save for later use

	mov	SRCHTEXTLEN,0	; Clear text string length

	REGSAVE <edi>		; Save register

	lea	edi,SRCHTEXTSTR ; Address destination string
@@:
S32	movs	<SRCHTEXTSTR[edi],ds:[esi].LO> ; Move one byte to text byffer
	inc	SRCHTEXTLEN	; Count in one more byte

	cmp	ds:[esi-1].LO,0 ; End of string?
	je	short @F	; Jump if so

	cmp	ds:[esi-1].LO,'"' ; End of string?
	jne	short @B	; Jump if not
@@:
	REGREST <edi>		; Restore

	dec	SRCHTEXTLEN	; Don't include training quote mark

	mov	PSRCHCMP,offset PGROUP:SRCH0CMP ; Data search action routine
	mov	PSRCHDSP,offset PGROUP:SRCH1DSP ; Data display action routine
	mov	PSRCHTYP,offset DGROUP:SRCH_HBYTE ; Data search header type text

	jmp	CMD_SRCH_DISP	; Join common display code

CMD_SRCH_INSTR:
	or	SRC1MODE,@MODE_INSTR ; Mark as searching instructions
	mov	PSRCHTYP,offset DGROUP:SRCH_HINSTR ; Save as instr search header type text

	inc	esi		; Skip over instruction separator

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_SRCH_SYNTERR ; Yes, so that's an error

; Save instruction text

	lea	edi,SRCHTEXT	; ES:EDI ==> instruction text save area
	xor	ecx,ecx 	; Zero counter
@@:
	lods	ds:[esi].LO	; Get next instruction byte
	call	UPPERCASE	; Convert AL to uppercase
S32	stos	es:[edi].LO	; Save as instruction search text
	inc	ecx		; Count in another byte

	cmp	al,0		; Izit end-of-the-line?
	jne	short @B	; Jump if not

	dec	esi		; Back off to terminator

; Strip off trailing blanks

	sub	edi,2		; Back off to last byte
	dec	ecx		; Account for terminator

	mov	al,' '          ; Skip over this
	std			; Scan backwards
   repe scas	es:[edi].LO	; Skip over blanks
	cld			; Restore
	je	short @F	; Jump if all blank

	inc	ecx		; Skip to last non-blank
@@:
	mov	SRCHILEN,cl	; Save as instruction length

	jmp	CMD_SRCH_DISP	; Join common display code

CMD_SRCH_PTE:
	or	SRC1MODE,@MODE_PTE ; Mark as searching PTEs
	mov	PSRCHTYP,offset DGROUP:SRCH_HPTE ; Save as PTE search header type text
	mov	PSRCHDSP,offset PGROUP:SRCH4DSP ; Data display action routine

; Parse the PTE

	inc	esi		; Skip over instruction separator

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	short CMD_SRCH_SYNTERR ; Yes, so that's an error

; Convert the expression at DS:ESI to binary

	mov	ebx,esi 	; Save as old offset

	call	PARSE_EXPR	; Parse command line for an expression
	jc	near ptr CMD_SRCH_OVFERR ; Jump if too large

	and	eax,@PTE_FRM	; Isolate the 4KB frame
	mov	SRCHVAL,eax	; Save for later use

; Ensure nothing more on the line

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	cmp	al,0		; Izit end-of-the-line?
	jne	near ptr CMD_SRCH_SYNTERR ; No, so that's an error

	jmp	short CMD_SRCH_DISP1 ; Join common code

CMD_SRCH_DISP:
	mov	eax,SRC1OFF	; Get specified offset

	cmp	eax,SRC1MASK	; Ensure within mask limits
	ja	short CMD_SRCH_OVFERR ; Jump if not

	mov	eax,SRC2OFF	; Get specified offset

	cmp	eax,SRC2MASK	; Ensure within mask limits
	ja	short CMD_SRCH_OVFERR ; Jump if not
CMD_SRCH_DISP1:
	call	DISP_SRCH	; Display the search window

	clc			; Indicate all went well

	jmp	short CMD_SRCH_EXIT ; Join common exit code

CMD_SRCH_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	jmp	short CMD_SRCH_ERR ; Join common error exit code

CMD_SRCH_OVFERR:
	mov	MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

;;;;;;; jmp	short CMD_SRCH_ERR ; Join common error exit code

CMD_SRCH_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_SRCH_EXIT:
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_SRCH endp			; End CMD_SRCH procedure
	NPPROC  DISP_SRCH -- Display Search Window
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display search window

On entry:

SS:EBP	==>	FORW_STR
GS	=	DTE_D4GB

|

	pushad  		; Save all EGP registers

	mov	SCROFF,0	; Start at top of screen

	mov	al,@DSP_SRCH	; Set new display state
	call	SET_STATE	; Set new state

	mov	al,':'          ; Assume VM86 mode

	test	SRC1MODE,@MODE_VM ; Izit VM86 mode?
	jnz	short @F	; Jump if so

	mov	al,'|'          ; It's PM
@@:
	mov	SRCH_HSEP,al	; Save as separator

; Display the selector/segment in the header

	mov	ax,SRC1SEL	; Get it
	lea	edi,SRCH_HSEL	; ES:EDI ==> output save area
	call	BIN2WORD	; Convert AX to hex at ES:EDI

; Display the initial offsets in the header

	mov	eax,SRC1OFF	; Get initial offset for data entry
	lea	edi,SRCH_HOFF1  ; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

	add	eax,SRCHLEN	; Plus ending offset for data entry
	dec	eax		; Back off to last byte
	lea	edi,SRCH_HOFF2  ; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

; Copy the type text to the header

	mov	esi,PSRCHTYP	; DS:ESI ==> header type text
	lea	edi,SRCH_HTYPE  ; ES:EDI ==> output save area
	mov	ecx,SRCH_HTYPLEN ; ECX = # bytes in header type text
S32 rep movs	<es:[edi].LO,ds:[esi].LO> ; Copy to header

	mov	al,TTLATTR	; Get title attribute
	xchg	al,DEFATTR	; Swap with default attribute

	lea	esi,SRCH_HDR	; Search header
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	xchg	al,DEFATTR	; Restore default attribute

	mov	edi,SRC1OFF	; ES:EDI ==> offset for data entry
	add	edi,SRC1BASE	; ES:EDI ==> base address for data entry
	mov	ecx,SRCHLEN	; ECX = length of search area
	mov	SRCHCNT,@NROWS-2 ; # search lines we can fit on screen

	test	SRC1MODE,@MODE_INSTR ; Searching for instructions?
	jnz	short DISP_SRCH_INSTR ; Jump if so

	test	SRC1MODE,@MODE_PTE ; Searching for PTEs?
	jnz	short DISP_SRCH_PTE ; Jump if so

	call	SRCH_DATA	; Search and display data

	jmp	short DISP_SRCH_END ; Join common code

DISP_SRCH_INSTR:
	call	SRCH_INSTR	; Search and display instructions

	jmp	short DISP_SRCH_END ; Join common code

DISP_SRCH_PTE:
	call	SRCH_PTE	; Search and display PTEs
DISP_SRCH_END:
	call	CLEAR_EOP	; Clear to the end-of-the-page

	popad			; Restore all EGP registers

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_SRCH endp			; End DISP_SRCH procedure
	NPPROC  SRCH_DATA -- Search and Display Data
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Search and display data

On entry:

ECX	=	# bytes to search
EDI	=	offset in DTE_4GB of next byte to search

On exit:

ECX	=	(updated)
EDI	=	(updated)

|

	REGSAVE <eax,ebx,esi>	; Save registers

	call	INST_OPR0E	; Install our local Page Fault handler

	call	SRCHWORK	; Mark as working
SRCH_DATA_NEXT:
	jecxz	SRCH_DATA_EXIT  ; Jump if no more bytes to search

	push	es		; Save for a moment

	push	gs		; Get all memory selector
	pop	es		; Address it
	assume  es:AGROUP	; Tell the assembler about it

	mov	eax,SRCHVAL	; Get the search value
SRCH_DATA_SCAS:
	test	SRC_FLAG,@SRC_NOT ; Izit NOT time?
	jz	short SRCH_DATA_SCAS1 ; Jump if not

   repe scas	AGROUP:[edi].LO ; Search for the first byte
	je	short SRCH_DATA1 ; Jump if that's all (note CF=0)

	jmp	short SRCH_DATA_SCAS2 ; Join common code

SRCH_DATA_SCAS1:
  repne scas	AGROUP:[edi].LO ; Search for the first byte
	clc			; Assume that's all
	jne	short SRCH_DATA1 ; Jump if that's all
SRCH_DATA_SCAS2:

; Page Faults fall through, so we check for them via CR2

	mov	ebx,cr2 	; Get Page Fault linear address

	cmp	ebx,edi 	; Izit a Page Fault here?
	jne	short SRCH_DATA0 ; Jump if not

; Round up to next 4KB boundary

	inc	edi		; Skip over it
	dec	ecx		; Account for it
	add	ecx,edi 	; Add to get ending address
	add	edi,4*1024-1	; Round up to 4KB boundary
	and	edi,not (4*1024-1) ; ...
	sub	ecx,edi 	; Subtract to get new count
	ja	short SRCH_DATA_SCAS ; Jump if there's more

	clc			; Ensure CF=0 (that's all)

	jmp	short SRCH_DATA1 ; Join common exit code

SRCH_DATA0:
	lea	esi,AGROUP:[edi-1] ; Copy offset of first matching byte

	call	PSRCHCMP        ; Call special width comparison routine
	jnc	short SRCH_DATA_SCAS ; Jump if no trailing match
SRCH_DATA1:
	pop	es		; Restore
	assume  es:DGROUP	; Tell the assembler about it

	jnc	short SRCH_DATA_EXIT ; Jump if that's all

	REGSAVE <ecx,edi>	; Save for a moment

; Display the offset of the first matching byte

	mov	eax,esi 	; Get absolute offset
	sub	eax,SRC1BASE	; Less the base
	lea	edi,SRCH_OFF	; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

COMMENT|

Handle Page Faults in data search command.  In particular, if a search
match occurs in the first few bytes of memory (starting at 0:0), the
context displayed to the left of the match wraps to be negative (that
is, just below 4GB) which might signal a Page Fault).  For this
reason, we install and restore our Page Fault handler around the
display routine.

|

; Display the data in context

	call	PSRCHDSP	; Call special width display routine

; Display the line

	lea	esi,SRCH_LIN	; Search line
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	REGREST <edi,ecx>	; Restore

	dec	SRCHCNT 	; Count out one more line
	jnz	short SRCH_DATA_NEXT ; Go around again if more lines
SRCH_DATA_EXIT:
	call	REST_OPR0E	; Restore previous Page Fault handler

	mov	SRCHNOFF,edi	; Save as next offset
	mov	SRCHNLEN,ecx	; ...	       length

	call	SRCHDONE	; Mark as done

	REGREST <esi,ebx,eax>	; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCH_DATA endp			; End SRCH_DATA procedure
	NPPROC  SRCH0CMP -- Data Search Text Comparison Routine
	assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data search variable length comparison routine

Check for match with text string.
If match, exit with ECX and EDI updated and ZF=1.

On entry:

AL	=	byte to search for
ECX	=	# remaining bytes to search
ES:ESI	==>	First matching byte
ES:EDI	==>	Next byte to search

On exit:

ECX	=	(updated)
ES:EDI	==>	(updated)
ZF	=	1 if match
	=	0 if not

|

	REGSAVE <ecx>		; Save registers

	add	ecx,2		; Adjust for overscan
	cmp	ecx,SRCHTEXTLEN ; Ensure enough room
	REGREST <ecx>		; Restore registers
	jb	short SRCH0CMP_EXIT ; Jump if not (note ZF=0)

	REGSAVE <ecx,esi,edi>	; Save registers

	mov	ecx,SRCHTEXTLEN ; Number of bytes in search text string
	mov	edi,esi 	; Matching byte (within memory)
	lea	esi,SRCHTEXTSTR ; Text to search for

   repe cmps	SRCHTEXTSTR[esi],es:[edi].LO ; Compare the strings

	REGREST <edi,esi,ecx>	; Restore registers
	jne	short SRCH0CMP_EXIT ; Jump if mismatch (note ZF=0)

	inc	edi		; Skip over match
	dec	ecx		; Account for it

	cmp	ax,ax		; Set ZF=1
SRCH0CMP_EXIT:
	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCH0CMP endp			; End SRCH0CMP procedure
	NPPROC	SRCH1CMP -- Data Search Byte Comparison Routine
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data search byte comparison routine

Nothing to do

On entry:

AL	=	byte to search for
ECX	=	# remaining bytes to search
ES:ESI	==>	First matching byte
ES:EDI	==>	Next byte to search

On exit:

ECX	=	(updated)
ES:EDI	==>	(updated)
CF	=	1 if match
	=	0 if not

|

	stc			; CF=1

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCH1CMP endp			; End SRCH1CMP procedure
	NPPROC	SRCH1CMPNOT -- Data Search Byte NOT Comparison Routine
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data search byte NOT comparison routine

Nothing to do

On entry:

AL	=	byte to search for
ECX	=	# remaining bytes to search
ES:ESI	==>	First matching byte
ES:EDI	==>	Next byte to search

On exit:

ECX	=	(updated)
ES:EDI	==>	(updated)
CF	=	1 if no match
	=	0 if not

|

	stc			; CF=1

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCH1CMPNOT endp		; End SRCH1CMPNOT procedure
	NPPROC	SRCH2CMP -- Data Search Word Comparison Routine
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data search word comparison routine

Check for match with next byte.
If match, exit with ECX and EDI updated and CF=1.

On entry:

AX	=	word to search for
ECX	=	# remaining bytes to search
ES:ESI	==>	First matching byte
ES:EDI	==>	Next byte to search

On exit:

ECX	=	(updated)
ES:EDI	==>	(updated)
CF	=	1 if match
	=	0 if not

|

	cmp	ecx,1		; Ensure enough room
				; CF=1 if no match
	cmc			; Complement so that CF=0 if no match
	ja	short @F	; Jump if not (note CF=0)

	cmp	ax,es:[esi]	; Check out the value
	clc			; Assume no match
	jne	short @F	; Jump if mismatch (note CF=0)

	inc	edi		; Skip over match
	dec	ecx		; Account for it

	stc			; Mark as match (note CF=1)
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCH2CMP endp			; End SRCH2CMP procedure
	NPPROC	SRCH2CMPNOT -- Data Search Word NOT Comparison Routine
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data search word NOT comparison routine

Check for non-match with next byte.
If no match, exit with ECX and EDI updated and CF=1.

On entry:

AX	=	word to search for
ECX	=	# remaining bytes to search
ES:ESI	==>	First matching byte
ES:EDI	==>	Next byte to search

On exit:

ECX	=	(updated)
ES:EDI	==>	(updated)
CF	=	1 if no match
	=	0 if not

|

	cmp	ecx,1		; Ensure enough room
				; CF=1 if no match
	jb	short @F	; Jump if not (note CF=1)

	push	ebx		; Save for a moment
	mov	eax,ebx 	; Copy comparison value
	mov	bl,es:[esi]	; Copy unmatched byte
	cmp	bx,es:[esi]	; Check out the value
	pop	ebx		; Restore
	je	short @F	; Jump if match (note CF=0)

	inc	edi		; Skip over non-match
	dec	ecx		; Account for it

	stc			; Mark as non-match (note CF=1)
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCH2CMPNOT endp		; End SRCH2CMPNOT procedure
	NPPROC	SRCH4CMP -- Data Search Dword Comparison Routine
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data search dword comparison routine

Check for match with next three bytes.
If match, exit with ECX and EDI updated and CF=1.

On entry:

AX	=	word to search for
ECX	=	# remaining bytes to search
ES:ESI	==>	First matching byte
ES:EDI	==>	Next byte to search

On exit:

ECX	=	(updated)
ES:EDI	==>	(updated)
CF	=	1 if match
	=	0 if not

|

	cmp	ecx,3		; Ensure enough room
				; CF=1 if no match
	cmc			; Complement so that CF=0 if no match
	ja	short @F	; Jump if not (note CF=0)

	cmp	eax,es:[esi]	; Check out the value
	clc			; Assume no match
	jne	short @F	; Jump if mismatch (note CF=0)

	add	edi,3		; Skip over match
	sub	ecx,3		; Account for it

	stc			; Mark as match (note CF=1)
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCH4CMP endp			; End SRCH4CMP procedure
	NPPROC	SRCH4CMPNOT -- Data Search Dword NOT Comparison Routine
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data search dword NOT comparison routine

Check for no match with next three bytes.
If no match, exit with ECX and EDI updated and CF=1.

On entry:

AX	=	word to search for
ECX	=	# remaining bytes to search
ES:ESI	==>	First matching byte
ES:EDI	==>	Next byte to search

On exit:

ECX	=	(updated)
ES:EDI	==>	(updated)
CF	=	1 if no match
	=	0 if not

|

	cmp	ecx,3		; Ensure enough room
				; CF=1 if no match
	jb	short @F	; Jump if not (note CF=1)

	push	ebx		; Save for a moment
	mov	eax,ebx 	; Copy comparison value
	mov	bl,es:[esi]	; Copy unmatched byte
	cmp	ebx,es:[esi]	; Check out the value
	pop	ebx		; Restore
	je	short @F	; Jump if match (note CF=0)

	add	edi,3		; Skip over match
	sub	ecx,3		; Account for it

	stc			; Mark as non-match (note CF=1)
@@:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCH4CMPNOT endp		; End SRCH4CMPNOT procedure
	NPPROC  SRCH1DSP -- Data Search Byte Display Routine
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data search byte display routine

On entry:

GS:ESI	==>	first matching byte

|

	REGSAVE <eax,ecx,esi,edi> ; Save registers

; Fill the start of the line with blanks

	lea	edi,SRCH_LVAL	; ES:EDI ==> output save area
	mov	ecx,@SRCH1_OFF  ; Get # leading bytes to fill
	mov	al,' '          ; Fill with this
    rep stos	es:[edi].LO	; Blank it out

	sub	esi,1*@SRCH1_SIDE ; Back off to left side
	mov	ecx,@SRCH1_SIDE+1+@SRCH1_SIDE ; # bytes to display
SRCH1DSP_NEXT:
	clc			; Mark as no error
	lods	gs:[esi].LO	; Get next byte
	jnc	short SRCH1DSP_DISP ; Jump if all went OK

	inc	esi		; Skip over the byte
	mov	ax,'??'         ; Get invalid marker for byte
S32	stos	es:[edi].ELO	; Save it

	jmp	short SRCH1DSP_SEP ; Join common code

SRCH1DSP_DISP:
	call	BIN2BYTE	; Convert AL to hex at ES:EDI
SRCH1DSP_SEP:
	mov	al,' '          ; Blank separator
S32	stos	es:[edi].LO	; Save it

	loop	SRCH1DSP_NEXT	; Jump if more bytes to display

; Fill the rest of the line with blanks

	mov	al,' '          ; Fill with this
	lea	ecx,SRCH_LVAL[SRCH_LVLEN] ; Get end of the line
	sub	ecx,edi 	; Less offset of next character
    rep stos	es:[edi].LO	; Blank it out

	REGREST <edi,esi,ecx,eax> ; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCH1DSP endp			; End SRCH1DSP procedure
	NPPROC  SRCH2DSP -- Data Search Word Display Routine
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data search word display routine

On entry:

GS:ESI	==>	first matching byte

|

	REGSAVE <eax,ecx,esi,edi> ; Save registers

; Fill the start of the line with blanks

	lea	edi,SRCH_LVAL	; ES:EDI ==> output save area
	mov	ecx,@SRCH2_OFF  ; Get # leading bytes to fill
	mov	al,' '          ; Fill with this
    rep stos	es:[edi].LO	; Blank it out

	sub	esi,2*@SRCH2_SIDE ; Back off to left side
	mov	ecx,@SRCH2_SIDE+1+@SRCH2_SIDE ; # words to display
SRCH2DSP_NEXT:
	clc			; Mark as no error
	lods	gs:[esi].ELO	; Get next word
	jnc	short SRCH2DSP_DISP ; Jump if all went OK

	add	esi,2		; Skip over the word
	mov	eax,'????'      ; Get invalid marker for word
S32	stos	es:[edi].EDD	; Save it

	jmp	short SRCH2DSP_SEP ; Join common code

SRCH2DSP_DISP:
	call	BIN2WORD	; Convert AX to hex at ES:EDI
SRCH2DSP_SEP:
	mov	al,' '          ; Blank separator
S32	stos	es:[edi].LO	; Save it

	loop	SRCH2DSP_NEXT	; Jump if more bytes to display

; Fill the rest of the line with blanks

	mov	al,' '          ; Fill with this
	lea	ecx,SRCH_LVAL[SRCH_LVLEN] ; Get end of the line
	sub	ecx,edi 	; Less offset of next character
    rep stos	es:[edi].LO	; Blank it out

	REGREST <edi,esi,ecx,eax> ; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCH2DSP endp			; End SRCH2DSP procedure
	NPPROC  SRCH4DSP -- Data Search Dword Display Routine
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Data search dword display routine

On entry:

GS:ESI	==>	first matching byte

|

	REGSAVE <eax,ecx,esi,edi> ; Save registers

; Fill the start of the line with blanks

	lea	edi,SRCH_LVAL	; ES:EDI ==> output save area
	mov	ecx,@SRCH4_OFF  ; Get # leading bytes to fill
	mov	al,' '          ; Fill with this
    rep stos	es:[edi].LO	; Blank it out

	sub	esi,4*@SRCH4_SIDE ; Back off to left side
	mov	ecx,@SRCH4_SIDE+1+@SRCH4_SIDE ; # dwords to display
SRCH4DSP_NEXT:
	clc			; Mark as no error
	lods	gs:[esi].EDD	; Get next dword
	jnc	short SRCH4DSP_DISP ; Jump if all went OK

	add	esi,4		; Skip over the dword
	mov	eax,'????'      ; Get invalid marker for word
S32	stos	es:[edi].EDD	; Save it
S32	stos	es:[edi].EDD	; Save it

	jmp	short SRCH4DSP_SEP ; Join common code

SRCH4DSP_DISP:
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI
SRCH4DSP_SEP:
	mov	al,' '          ; Blank separator
S32	stos	es:[edi].LO	; Save it

	loop	SRCH4DSP_NEXT	; Jump if more bytes to display

; Fill the rest of the line with blanks

	mov	al,' '          ; Fill with this
	lea	ecx,SRCH_LVAL[SRCH_LVLEN] ; Get end of the line
	sub	ecx,edi 	; Less offset of next character
    rep stos	es:[edi].LO	; Blank it out

	REGREST <edi,esi,ecx,eax> ; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCH4DSP endp			; End SRCH4DSP procedure
	NPPROC  SRCH_INSTR -- Search and Display Instructions
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Search and display instructions

On entry:

ECX	=	# bytes to search
EDI	=	offset in DTE_4GB of next byte to search

On exit:

ECX	=	(updated)
EDI	=	(updated)

|

	REGSAVE <eax,ebx,esi,fs> ; Save registers

	call	SRCHWORK	; Mark as working

	push	SCROFF  	; Save current screen offset
	call	CLEAR_EOP	; Clear to the end-of-the-page
	pop	SCROFF  	; Restore

	push	gs		; Get our data selector
	pop	fs		; Address it
	assume  fs:AGROUP	; Tell the assembler about it

	mov	esi,edi 	; FS:ESI ==> instruction to disassemble
SRCH_INSTR_NEXT:
	mov	edi,esi 	; Save as old ptr

	REGSAVE <ecx,edi>	; Save for a moment

	lea	edi,INSTROUT	; ES:EDI ==> output line
	call	CLEAR_OUT	; Clear the output buffer

; Disassemble the instruction at FS:ESI into ES:EDI using EBX as an offset base

; EBX	 =	 segment/selector offset base (used for relative offsets)
; FS:ESI ==>	 instruction to disassemble
; ES:EDI ==>	 output save area

	mov	ebx,SRC1BASE	; Get initial segment/selector offset base

	xor	cx,cx		; Assume USE16 disassembly

	test	SRC1MODE,@MODE_USE32 ; Check for USE32
	jz	short @F	; Jump if USE16

	or	cx,@BIT0	; Mark as USE32
@@:
	test	SRC1MODE,@MODE_VM ; Izit VM 8086 mode?
	jnz	short @F	; Jump if so

	or	cx,@BIT1	; Mark as PM
@@:
	call	INSTRDEC	; Disassemble the next instruction
				; returning FS:ESI ==> next instruction
				; ...	    ES:EDI ==> next output byte
	mov	ebx,edi 	; Save for later use
	sub	ebx,offset DGROUP:INSTROUT ; Convert to length

; Compare with specified instruction text

	push	esi		; Save for a moment
	movzx	ecx,SRCHILEN	; Get instruction length
	lea	edi,SRCHTEXT	; ES:EDI ==> instruction search text
	lea	esi,INSTROUT	; DS:ESI ==> instruction disassembly
	add	esi,@OFFBYTE	; Skip over byte display area
SRCH_INSTR_CMP:
	cmp	ax,ax		; Ensure ZF=1

   repe cmps	ds:[esi].LO,es:[edi].LO ; Compare 'em
	je	short SRCH_INSTR_CMPZ ; Jump if all equal (note ZF=1)

; Allow wild cards in specified instruction search text

	cmp	DGROUP:[edi-1].LO,'?' ; Izit a wild card?
	je	short SRCH_INSTR_CMP ; Yes, continue searching

; Allow lowercase in INSTROUT

	mov	al,DGROUP:[esi-1] ; Get mismatch byte
	call	UPPERCASE	; Convert AL to uppercase

	cmp	al,DGROUP:[edi-1] ; Check against specified byte
	je	short SRCH_INSTR_CMP ; Jump if it's a match

; Allow white space in INSTROUT

	cmp	al,' '          ; Izit white space?
	jne	short SRCH_INSTR_CMPZ ; Not this time (note ZF=0)

	inc	ecx		; Count it back in
	dec	edi		; Back off in search text

	jmp	short SRCH_INSTR_CMP ; Go around again

SRCH_INSTR_CMPZ:
	pop	esi		; Restore
	REGREST <edi,ecx>	; Restore
	jne	short SRCH_INSTR_MISS ; Jump if no match

	REGSAVE <ecx,esi,edi>	; Save for a moment

	mov	esi,edi 	; Copy current offset

; Display the offset

	mov	eax,esi 	; Get absolute offset
	sub	eax,SRC1BASE	; Less the base
	lea	edi,SRCH_OFF	; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

; Display the instruction in context

	mov	ecx,SRCH_LVLEN  ; Get length of output save area

	cmp	ecx,ebx 	; Use the smaller
	jb	short @F	; Jump if search area smaller

	mov	ecx,ebx 	; Use instruction length
@@:
	lea	edi,SRCH_LVAL	; ES:EDI ==> output save area
	lea	esi,INSTROUT	; DS:ESI ==> instruction disassembly
S32 rep movs	<es:[edi].LO,ds:[esi].LO> ; Copy to output save area

; Fill the rest of the line with blanks

	mov	al,' '          ; Fill with this
	lea	ecx,SRCH_LVAL[SRCH_LVLEN] ; Get end of the line
	sub	ecx,edi 	; Less offset of next character
    rep stos	es:[edi].LO	; Blank it out

; Display the line

	lea	esi,SRCH_LIN	; Search line
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	REGREST <edi,esi,ecx>	; Restore

	dec	SRCHCNT 	; Count out one more line

; Update the pointers

SRCH_INSTR_MISS:
	cmp	SRCHINC,0	; Check search increment
	je	short @F	; Jump if next instruction

	lea	esi,[edi+1]	; Search next byte
@@:
	mov	eax,esi 	; Copy new offset
	sub	eax,edi 	; Subtract old ptr from new ptr

	sub	ecx,eax 	; Account for in # bytes remaining
	jc	short SRCH_INSTR_END ; Jump if no more
	je	short SRCH_INSTR_EXIT ; Jump if no more bytes to search

	cmp	SRCHCNT,0	; Any more lines to display?
	je	short SRCH_INSTR_EXIT ; Join common exit code

	jmp	SRCH_INSTR_NEXT ; Jump if more lines to display

SRCH_INSTR_END:
	xor	ecx,ecx 	; Ensure count is zero
SRCH_INSTR_EXIT:
	mov	SRCHNOFF,edi	; Save as next offset
	mov	SRCHNLEN,ecx	; ...	       length

	call	SRCHDONE	; Mark as done

	REGREST <fs,esi,ebx,eax> ; Restore
	assume  fs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCH_INSTR endp 		; End SRCH_INSTR procedure
	NPPROC  SRCH_PTE -- Search and Display PTEs
	assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Search and display PTEs

On entry:

ECX	=	# bytes to search
EDI	=	offset in DTE_4GB of next byte to search

On exit:

ECX	=	(updated)
EDI	=	(updated)

|

	REGSAVE <eax,ebx,esi>	; Save registers

	call	INST_OPR0E	; Install our local Page Fault handler

	call	SRCHWORK	; Mark as working

	call	READ_CR3	; Get the value into EAX
	and	eax,@PTE_FRM	; Isolate 4KB frame
	or	eax,@PTE_URP	; Mark as User/Read-write/Present
	mov	ebx,eax 	; Save for a moment

	PUSHD	0		; Make room for original PTE
	PUSHD	1		; # PTEs to follow
	PUSHD	0		; Make room for original PDE
	push	@SRCPTE_BASE	; Pass the linear address
	push	ebx		; Pass the CR3 to use
	call	LIN2PPDIR	; Return with AGROUP:EAX ==> corresponding PDIR

	mov	AGROUP:[eax],ebx ; Save CR3 as a PTE

	shr	ecx,12-0	; Convert from bytes to 4KB
	and	edi,not (4*1024-1) ; Round down to 4KB boundary
	shr	edi,(12-2)-0	; Convert from bytes to 4KB in dwords
	add	edi,@SRCPTE_BASE ; Plus linear address of CR3
SRCH_PTE_NEXT:
	jecxz	SRCH_PTE_EXIT	; Jump if no more bytes to search

	push	es		; Save for a moment

	push	gs		; Get all memory selector
	pop	es		; Address it
	assume	es:AGROUP	; Tell the assembler about it

	mov	eax,SRCHVAL	; Get the search value
SRCH_PTE_SCAS:
	clc			; Mark as no error
	mov	ebx,AGROUP:[edi] ; Get the next PTE
	jc	short @F	; Jump if Page Fault

	and	ebx,@PTE_FRM	; Isolate the 4KB frame

	cmp	eax,ebx 	; Izit the same PTE?
	je	short SRCH_PTE1 ; Jump if so (note ZF=1)
@@:
	add	edi,4		; Skip over it

	loop	SRCH_PTE_SCAS	; Jump if more data to search

	cmp	eax,ebx 	; Ensure ZF=0
SRCH_PTE1:
	pop	es		; Restore
	assume	es:DGROUP	; Tell the assembler about it

	jne	short SRCH_PTE_EXIT ; Jump if that's all

	mov	esi,edi 	; Copy absolute offset
	add	edi,4		; Skip over it
	dec	ecx		; Count it out

	REGSAVE <ecx,edi>	; Save for a moment

; Display the linear address which the PTE covers

	mov	eax,esi 	; Get absolute offset
	sub	eax,@SRCPTE_BASE ; Less the CR3 linear address
	shl	eax,(12-2)-0	; Convert from 4KB in dwords to bytes
	lea	edi,SRCH_OFF	; ES:EDI ==> output save area
	call	BIN2DWORD	; Convert EAX to hex at ES:EDI

; Display the data in context

	call	PSRCHDSP	; Call special width display routine

; Display the line

	lea	esi,SRCH_LIN	; Search line
	call	DISPASCIIZ	; Display ASCIIZ string from ESI

	REGREST <edi,ecx>	; Restore

	dec	SRCHCNT 	; Count out one more line
	jnz	short SRCH_PTE_NEXT ; Go around again if more lines
SRCH_PTE_EXIT:
	sub	edi,@SRCPTE_BASE ; Less the CR3 linear address
	shl	edi,(12-2)-0	; Convert from 4KB in dwords to bytes
	shl	ecx,12-0	; Convert from 4KB to bytes

	mov	SRCHNOFF,edi	; Save as next offset
	mov	SRCHNLEN,ecx	; ...	       length

	call	LIN2PPTEZ	; Cleanup after LIN2PPDIR
	add	esp,1*4 	; Pop the PTE

	call	SRCHDONE	; Mark as done

	call	REST_OPR0E	; Restore previous Page Fault handler

	REGREST <esi,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCH_PTE endp			; End SRCH_PTE procedure
	NPPROC  SRCHWORK -- Display Search Working Message
	assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display search working message

|

	REGSAVE <eax>		; Save register

	mov	al,WRKATTR	; Get working attribute
	push	ax		; Pass as attribute to smear
	push	offset DGROUP:MSG_WORK ; Pass offset of window
	push	offset DGROUP:W_SRC ; Pass offset of window descriptor
	call	WPUT_CSA	; Output the characters, smear attribute

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCHWORK endp			; End SRCHWORK procedure
	NPPROC  SRCHDONE -- Display Search Done Message
	assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display search done message

|

	REGSAVE <eax>		; Save register

	mov	al,TTLATTR	; Get title attribute
	push	ax		; Pass as attribute to smear
	push	offset DGROUP:MSG_DONE ; Pass offset of window
	push	offset DGROUP:W_SRC ; Pass offset of window descriptor
	call	WPUT_CSA	; Output the characters, smear attribute

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCHDONE endp			; End SRCHDONE procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_SRC module
