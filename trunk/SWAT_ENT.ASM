;' $Header:   P:/PVCS/386SWAT/SWAT_ENT.ASV   1.14   10 Jul 1997 14:46:32   BOB  $
	 title	 SWAT_ENT -- 386SWAT Enter Data Command Functions
	 page	 58,122
	 name	 SWAT_ENT

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.

|
.386
.xlist
	 include MASM.INC
	 include PTR.INC
	 include 386.INC
	 include KEYCODE.INC
	 include ALLMEM.INC

	 include SWAT_COM.INC
	 include SWAT_MOD.INC
	 include SWAT_SEG.INC
.list

DATA16	 segment use32 dword public 'data' ; Start DATA16 segment
	 assume  ds:DGROUP

	 extrn	 CMD_FLAG:word
	 include SWAT_CMD.INC

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	 extrn	 CMD_LINE:byte
	 extrn	 VIDTYPE:dword
	 extrn	 CURTYPE:word
	 extrn	 CURPOSN:word

DATA16	 ends			; End DATA16 segment


DATA	 segment use32 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 MSGOFF:dword
	 extrn	 SYNTERR:byte
	 extrn	 OVFERR:byte

	 public  ENTOFF,ENTBASE,ENTSEL,ENTMODE,ENTMASK
ENTOFF	 dd	 0		; Data entry offset
ENTBASE  dd	 0		; ...	     base
ENTSEL	 dw	 0		; ...	     selector
ENTMODE  dw	 @MODE_VM	; ...	     mode
ENTMASK  dd	 0000FFFFh	; ...	     mask

	 public  FILLOFF,FILLCR3,FILLBASE,FILLSEL,FILLMODE,FILLMASK
FILLOFF  dd	 0		; Data fill  offset
FILLCR3  dd	 ?		; CR3 to use in physical memory translation
FILLBASE dd	 0		; ...	     base
FILLSEL  dw	 0		; ...	     selector
FILLMODE dw	 @MODE_VM	; ...	     mode
FILLMASK dd	 0000FFFFh	; ...	     mask
FILLLEN  dd	 0		; ...	     length
FILLVAL  db	 00h		; ...	     value

	align	4		; Ensure dword alignment

	 public  MOVEOFF_S,MOVEBASE_S,MOVESEL_S,MOVEMODE_S,MOVEMASK_S
MOVEOFF_S  dd	 0		; Data MOVE  Source offset
MOVEBASE_S dd	 0		; ...		    base
MOVESEL_S  dw	 0		; ...		    selector
MOVEMODE_S dw	 @MODE_VM	; ...		    mode
MOVEMASK_S dd	 0000FFFFh	; ...		    mask

	 public  MOVEOFF_D,MOVEBASE_D,MOVESEL_D,MOVEMODE_D,MOVEMASK_D
MOVEOFF_D  dd	 0		; Data MOVE  Destin offset
MOVEBASE_D dd	 0		; ...		    base
MOVESEL_D  dw	 0		; ...		    selector
MOVEMODE_D dw	 @MODE_VM	; ...		    mode
MOVEMASK_D dd	 0000FFFFh	; ...		    mask

MOVELEN  dd	 0		; ...		    length

	 public  ENT_VAL,ENT_CNT
	 even
ENT_VAL  db	 ?		; Data entry value
ENT_CNT  db	 ?		; ...	     count

	 public  ENT_KEY
ENT_KEY  dw	 @KEY_CR	; CR	    = Process
	 dw	 @KEY_SHF_CR	; Shift-CR  = Process
	 dw	 @KEY_BS	; BS	    = Backspace
	 dw	 @KEY_SPACE	; Space     = Skip to next item
	 dw	 @KEY_INS	; Insert    = Toggle insert mode
	 dw	 @KEY_XINS	; Insert    = Toggle insert mode
	 dw	 @KEY_0 	; 0	    = Entry value
	 dw	 @KEY_1 	; 1	    = Entry value
	 dw	 @KEY_2 	; 2	    = Entry value
	 dw	 @KEY_3 	; 3	    = Entry value
	 dw	 @KEY_4 	; 4	    = Entry value
	 dw	 @KEY_5 	; 5	    = Entry value
	 dw	 @KEY_6 	; 6	    = Entry value
	 dw	 @KEY_7 	; 7	    = Entry value
	 dw	 @KEY_8 	; 8	    = Entry value
	 dw	 @KEY_9 	; 9	    = Entry value
	 dw	 @KEY_A 	; a	    = Entry value
	 dw	 @KEY_SHF_A	; A	    = Entry value
	 dw	 @KEY_B 	; b	    = Entry value
	 dw	 @KEY_SHF_B	; B	    = Entry value
	 dw	 @KEY_C 	; c	    = Entry value
	 dw	 @KEY_SHF_C	; C	    = Entry value
	 dw	 @KEY_D 	; d	    = Entry value
	 dw	 @KEY_SHF_D	; D	    = Entry value
	 dw	 @KEY_E 	; e	    = Entry value
	 dw	 @KEY_SHF_E	; E	    = Entry value
	 dw	 @KEY_F 	; f	    = Entry value
	 dw	 @KEY_SHF_F	; F	    = Entry value
ENT_NKEY equ	 ($-ENT_KEY)/(type ENT_KEY) ; # valid special keys

	 public  ENT_ACT
ENT_ACT  dd	 offset PGROUP:ENT_CR  ; CR	   = Process
	 dd	 offset PGROUP:ENT_CR  ; CR	   = Process
	 dd	 offset PGROUP:ENT_BS  ; BS	   = Backspace
	 dd	 offset PGROUP:ENT_SPC ; Space	   = Skip to next item
	 dd	 offset PGROUP:ENT_INS ; Insert    = Toggle insert mode
	 dd	 offset PGROUP:ENT_INS ; Insert    = Toggle insert mode
	 dd	 offset PGROUP:ENT_NUM ; 0	   = Entry value
	 dd	 offset PGROUP:ENT_NUM ; 1	   = Entry value
	 dd	 offset PGROUP:ENT_NUM ; 2	   = Entry value
	 dd	 offset PGROUP:ENT_NUM ; 3	   = Entry value
	 dd	 offset PGROUP:ENT_NUM ; 4	   = Entry value
	 dd	 offset PGROUP:ENT_NUM ; 5	   = Entry value
	 dd	 offset PGROUP:ENT_NUM ; 6	   = Entry value
	 dd	 offset PGROUP:ENT_NUM ; 7	   = Entry value
	 dd	 offset PGROUP:ENT_NUM ; 8	   = Entry value
	 dd	 offset PGROUP:ENT_NUM ; 9	   = Entry value
	 dd	 offset PGROUP:ENT_HEX ; a	   = Entry value
	 dd	 offset PGROUP:ENT_HEX ; A	   = Entry value
	 dd	 offset PGROUP:ENT_HEX ; b	   = Entry value
	 dd	 offset PGROUP:ENT_HEX ; B	   = Entry value
	 dd	 offset PGROUP:ENT_HEX ; c	   = Entry value
	 dd	 offset PGROUP:ENT_HEX ; C	   = Entry value
	 dd	 offset PGROUP:ENT_HEX ; d	   = Entry value
	 dd	 offset PGROUP:ENT_HEX ; D	   = Entry value
	 dd	 offset PGROUP:ENT_HEX ; e	   = Entry value
	 dd	 offset PGROUP:ENT_HEX ; E	   = Entry value
	 dd	 offset PGROUP:ENT_HEX ; f	   = Entry value
	 dd	 offset PGROUP:ENT_HEX ; F	   = Entry value

	 public  ENT_METHOD
ENT_METHOD db	 0		; 1 if entering data from command line

DATA	 ends			; End DATA segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 extrn	 CMD_WHITE:near
	 extrn	 U32_LOWERCASE:near
	 extrn	 PARSE_ADDR:near
	 extrn	 PARSE_LVAL:near
	 extrn	 CLEAR_CMDLINE:near
	 extrn	 DISP_CMDLINE:near
	 extrn	 GETKEY:near
	 extrn	 ERR_BEEP:near
	 extrn	 SET_CURPOS:near
	 extrn	 SET_CURTYP:near

	 extrn	 BIN2DIGIT:near
	 extrn	 BIN2BYTE:near
	 extrn	 BIN2WORD:near
	 extrn	 BIN2DWORD:near

	extrn	DISPPHYS:near
	extrn	DISPVIRT:near
	extrn	PARSE_EXPR:near

	 NPPROC  CMD_ENTER -- Date Enter Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Data enter command

E addr
E addr lvalist

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save registers

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 near ptr CMD_ENTER_SYNTERR ; Yes, treat as error

	 call	 PARSE_ADDR	; Parse command line for an address
	 jc	 near ptr CMD_ENTER_ERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

; Ensure nothing more on the line

	 push	 eax		; Save for a moment

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 setne	 ENT_METHOD	; Set if data on command line

	 pop	 eax		; Restore

	 mov	 ENTOFF,eax	; Save for display purposes

	 test	 cx,@ADDR_SEP	; Separator specified?
	 jz	 short @F	; Not this time

	 mov	 ENTSEL,bx	; Save for display purposes
	 mov	 ENTBASE,edx	; Save for later use

	 and	 ENTMODE,not @MODE_VM ; Mark as protected mode
	 mov	 ENTMASK,-1	; Use all 32 bits

	 test	 cx,@ADDR_PM	; Check mode
	 jnz	 short @F	; Jump if PM

	 or	 ENTMODE,@MODE_VM ; Mark as VM86 mode
	 mov	 ENTMASK,0000FFFFh ; Use low-order 16 bits
@@:
	 mov	 eax,ENTOFF	; Get specified offset

	 cmp	 eax,ENTMASK	; Ensure within mask limits
	 ja	 near ptr CMD_ENTER_OVFERR ; Jump if not

; If data exists on command line, copy it until we get 1) an overflow
; error/invalid (non-numeric) character or 2) end of line.
	 cmp	 ENT_METHOD,0	; Are we entering data interactively?
	 je	 short CMD_ENTER_NEWLINE ; Jump if so

; DS:ESI ==> next non-whitespace character on line.

CMD_ENTER_NEXTCHAR:
	 call	 PARSE_LVAL	; Get next value on command line
	 jc	 near ptr CMD_ENTER_OVFERR ; Jump if out of range

	 cmp	 eax,0FFh	; Izit out of range?
	 ja	 near ptr CMD_ENTER_OVFERR ; Jump if so

	 mov	 edi,ENTOFF	; GS:EDI ==> offset for data entry
	 and	 edi,ENTMASK	; Mask off wrapped bits (if VM86 mode)
	 add	 edi,ENTBASE	; GS:EDI ==> base address for data entry

	 mov	 AGROUP:[edi].LO,al ; Save byte

	 inc	 ENTOFF 	; Skip to next byte

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 or	 al,al		; Izit the end of the line?
	 jnz	 short CMD_ENTER_NEXTCHAR ; Go around again if not

	 jmp	 CMD_ENTER_DONE ; Join common exit code

CMD_ENTER_NEWLINE:
	 call	 CLEAR_CMDLINE	; Clear the command line

; Display the selector/segment and offset on the command line

	 mov	 ax,ENTSEL	; Get the selector/segment
	 lea	 edi,CMD_LINE	; ES:EDI ==> command line
	 call	 BIN2WORD	; Convert AX to hex at ES:EDI

; Display the appropriate separator

	 mov	 al,':'         ; Assume VM86 mode

	 test	 ENTMODE,@MODE_VM ; Izit in VM86 mode?
	 jnz	 short @F	; Yes

	 mov	 al,'|'         ; It's PM
@@:
S32	 stos	 CMD_LINE[edi]	; Save in command line

; Display the offset

	 mov	 eax,ENTOFF	; Get the offset

	 test	 ENTMODE,@MODE_VM ; Izit in VM86 mode?
	 jnz	 short CMD_ENTER1 ; Yes

	 call	 BIN2DWORD	; Convert EAX to hex at ES:EDI

	 jmp	 short CMD_ENTER2 ; Join common code

CMD_ENTER1:
	 call	 BIN2WORD	; Convert AX to hex at ES:EDI
CMD_ENTER2:
CMD_ENTER_NEXT:
	 mov	 ENT_VAL,0	; Clear digit value
	 mov	 ENT_CNT,0	; ...	      count

; Display a separator

	 mov	 ax,'  '        ; Separator
S32	 stos	 CMD_LINE[edi].ELO ; Save in command line

; Check for end-of-the-line

	 cmp	 edi,offset es:CMD_LINE[@NCOLS-6] ; Are we near the end-of-the-line?
	 jae	 short CMD_ENTER_NEWLINE ; Yes

; Get the next byte of data

	 mov	 esi,ENTOFF	; GS:ESI ==> offset for data entry
	 and	 esi,ENTMASK	; Mask off wrapped bits (if VM86 mode)
	 add	 esi,ENTBASE	; GS:ESI ==> base address for data entry

	 mov	 al,AGROUP:[esi].LO ; Get the next byte

	 call	 BIN2BYTE	; Convert AL to hex at ES:EDI

	 mov	 al,'.'         ; Separator
S32	 stos	 CMD_LINE[edi]	; Save in command line
CMD_ENTER_DISP:
	 call	 DISP_CMDLINE	; Display the command line

; Position the cursor

	 mov	 eax,edi	; Copy current position
	 sub	 eax,offset es:CMD_LINE ; Convert to origin-0
	 mov	 CURPOSN.LO,al	; Save as current cursor position

	 push	 CURPOSN	; Get cursor position
	 call	 SET_CURPOS	; Set it

; Get the next keystroke

CMD_ENTER_KEY:
	 call	 GETKEY 	; Return with AX = keystroke

	 mov	 ebx,edi	; Save for a moment

	 lea	 edi,ENT_KEY	; ES:EDI ==> valid keystrokes
	 mov	 ecx,ENT_NKEY	; ECX = # valid keys
   repne scas	 ENT_KEY[edi]	; Search for it
	 xchg	 ebx,edi	; Swap 'em
	 jne	 short CMD_ENTER_BEEP ; Jump if not found

	 sub	 ebx,(type ENT_KEY)+offset es:ENT_KEY ; Convert to origin-0
	 shl	 ebx,2-1	; Convert from words to dwords

	 jmp	 ENT_ACT[ebx]	; Take appropriate action


; Unknown keystroke

CMD_ENTER_BEEP:
	 call	 ERR_BEEP	; Sound the alarum!!

	 jmp	 CMD_ENTER_KEY	; Go around again


; Accept a hex or numeric entry

ENT_HEX:
	 or	 al,20h 	; Convert to lowercase
	 sub	 al,'a'-('9'+1) ; Convert to origin-('9'+1)
ENT_NUM:
	 sub	 al,'0'         ; Convert to origin-0

	 cmp	 ENT_CNT,2	; Full up?
	 jae	 short CMD_ENTER_BEEP ; Yes, beep at 'em

	 inc	 ENT_CNT	; Count in another digit

	 shl	 ENT_VAL,4	; Shift over the high-order nibble
	 or	 ENT_VAL,al	; Include the low-order nibble
	 call	 BIN2DIGIT	; Convert digit AL to hex at ES:EDI

	 jmp	 CMD_ENTER_DISP ; Go around again


; Delete the previous byte (if any)

ENT_BS:
	 cmp	 ENT_CNT,0	; Check for pending values
	 je	 short @F	; Jump if none

	 shr	 ENT_VAL,4	; Shift over
	 dec	 ENT_CNT	; Count out one

	 dec	 edi		; Back off one character
	 mov	 DGROUP:[edi].LO,' ' ; Blank out the last digit
@@:
	 jmp	 CMD_ENTER_DISP ; Go around again


; Accept the current entry (if any) and display the next byte

ENT_SPC:
	 cmp	 ENT_CNT,0	; Check for pending values
	 je	 short @F	; Jump if none

	 mov	 al,ENT_VAL	; Get the new value
	 mov	 AGROUP:[esi].LO,al ; Save back into memory
@@:
	 inc	 ENTOFF 	; Skip to next byte

	 jmp	 CMD_ENTER_NEXT ; Go around again


; Toggle insert mode

ENT_INS:
	 xor	 CMD_FLAG,@CMD_INS ; Toggle the flag

	 mov	 ax,VIDTYPE.ELO ; Get normal state type

	 test	 CMD_FLAG,@CMD_INS ; Check the state
	 jz	 short @F	; Jump if normal

	 mov	 ax,VIDTYPE.EHI ; Get insert state type
@@:
	 mov	 CURTYPE,ax	; Save as new type

	 push	 CURTYPE	; Get cursor type
	 call	 SET_CURTYP	; Set it

	 jmp	 CMD_ENTER_DISP ; Go around again


; Accept the current entry (if any) and exit

ENT_CR:
	 cmp	 ENT_CNT,0	; Check for pending values
	 je	 short @F	; Jump if none

	 mov	 al,ENT_VAL	; Get the new value
	 mov	 AGROUP:[esi].LO,al ; Save back into memory
@@:
CMD_ENTER_DONE:
	 or	 LCL_FLAG,@LCL_REDI ; Mark as forced re-display of screen

	 clc			; Indicate all went well

	 jmp	 short CMD_ENTER_EXIT ; Join common exit code

CMD_ENTER_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	 jmp	 short CMD_ENTER_ERR ; Join common error exit code

CMD_ENTER_OVFERR:
	 mov	 MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

;;;;;;;; jmp	 short CMD_ENTER_ERR ; Join common error exit code

CMD_ENTER_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Mark as in error
CMD_ENTER_EXIT:
	 REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_ENTER endp			; End CMD_ENTER procedure
	 NPPROC  CMD_FILL -- Data Fill Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Data fill command

F addr L lval lval

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 pushad 		; Save all EGP registers

	 push	 es		; Save segment register

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 near ptr CMD_FILL_SYNTERR ; Yes, treat as error

	 call	 PARSE_ADDR	; Parse command line for an address
	 jc	 near ptr CMD_FILL_ERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

	 mov	 FILLOFF,eax	; Save for display purposes

	 test	 cx,@ADDR_SEP	; Separator specified?
	 jz	 short CMD_FILL1 ; Not this time

	 mov	 FILLSEL,bx	; Save for display purposes
	 mov	 FILLBASE,edx	; Save for later use

	 and	 FILLMODE,not @MODE_VM ; Mark as protected mode
	 mov	 FILLMASK,-1	; Use all 32 bits

	 test	 cx,@ADDR_PM	; Check mode
	 jnz	 short CMD_FILL1 ; Jump if PM

	 or	 FILLMODE,@MODE_VM ; Mark as VM86 mode
	 mov	 FILLMASK,0000FFFFh ; Use low-order 16 bits
CMD_FILL1:
	 mov	 eax,FILLOFF	; Get specified offset

	 cmp	 eax,FILLMASK	; Ensure within mask limits
	 ja	 near ptr CMD_FILL_OVFERR ; Jump if not

; Parse length separator

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_FILL_SYNTERR ; Yes, treat as error

	call	U32_LOWERCASE	; Convert AL to lowercase

	cmp	al,'l'          ; Izit length parameter?
	jne    near ptr CMD_FILL_SYNTERR ; No, so that's an error

	 inc	 esi		; Skip over length separator

; Parse length parameter

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

; Convert the con/reg at DS:ESI to binary

	call	PARSE_LVAL	; Parse command line for a lefthand value
	jc	near ptr CMD_FILL_OVFERR ; Jump if too large

	mov	FILLLEN,eax	; Save for later use

; Parse fill value

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	near ptr CMD_FILL_SYNTERR ; Yes, so that's an error

; Convert the con/reg at DS:ESI to binary

	call	PARSE_LVAL	; Parse command line for a lefthand value
	jc	near ptr CMD_FILL_OVFERR ; Jump if too large

	mov	FILLVAL,al	; Save for later use

	and	FILLMODE,not @MODE_PHYS ; Mark as no physical translation

; Check for optional physical marker

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character
	or	al,20h		; Convert to lowercase

	cmp	al,'p'          ; Izit physical marker?
	jne	short CMD_FILL2 ; Jump if not

	inc	esi		; Skip over it
	or	FILLMODE,@MODE_PHYS ; Mark as physical translation
	mov	FILLCR3,0	; Assume one-to-one translation

; Check for optional CR3

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	je	short CMD_FILL3 ; Jump if so

; Parse CR3 value for translation

	call	PARSE_EXPR     ; Parse command line for an expression
	jc	short CMD_FILL_SYNTERR ; Jump if too large

	and	ax,mask $PTE_FRM ; Isolate 4KB frame
	mov	FILLCR3,eax	; Save as CR3 for translation
CMD_FILL2:

; Ensure nothing more on the line

	call	CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	cmp	al,0		; Izit end-of-the-line?
	jne	short CMD_FILL_SYNTERR ; No, so that's an error
CMD_FILL3:
	 push	 gs		; Get all memory selector
	 pop	 es		; Address it
	 assume  es:AGROUP	; Tell the assembler about it

	test	FILLMODE,@MODE_PHYS ; Izit in physical mode?
	jz	short @F	; Jump if not

	push	FILLCR3 	; Pass new CR3 to use (if non-zero)
	push	FILLBASE	; Pass base memory to use
	push	FILLOFF 	; Pass memory offset to use
	call	DISPPHYS	; Setup for physical memory display

	mov	FILLBASE,eax	; Save as new base address
@@:
	 mov	 edi,FILLOFF	; ES:EDI ==> offset for data entry
	 and	 edi,FILLMASK	; Mask off wrapped bits (if VM86 mode)
	 add	 edi,FILLBASE	; ES:EDI ==> base address for data entry
	 mov	 ecx,FILLLEN	; ECX = length of fill area
	 mov	 al,FILLVAL	; Get the fill value

     rep stos	 AGROUP:[edi].LO ; Fill it up

	test	FILLMODE,@MODE_PHYS ; Izit in physical mode?
	jz	short @F	; Jump if not

	call	DISPVIRT	; Restore virtual mode display
@@:
	 or	 LCL_FLAG,@LCL_REDI ; Mark as forced re-display of screen

	 clc			; Indicate all went well

	 jmp	 short CMD_FILL_EXIT ; Join common exit code

CMD_FILL_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	 jmp	 short CMD_FILL_ERR ; Join common error exit code

CMD_FILL_OVFERR:
	 mov	 MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

;;;;;;;; jmp	 short CMD_FILL_ERR ; Join common error exit code

CMD_FILL_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Mark as in error
CMD_FILL_EXIT:
	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_FILL endp			; End CMD_FILL procedure
	 NPPROC  CMD_MOVE -- Data MOVE Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Data MOVE command

M addr L lval addr

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 pushad 		; Save all EGP registers

	 push	 es		; Sav segment register

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 near ptr CMD_MOVE_SYNTERR ; Yes, treat as error

; Parse the source address

	 call	 PARSE_ADDR	; Parse command line for an address
	 jc	 near ptr CMD_MOVE_ERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

	 mov	 MOVEOFF_S,eax	; Save for display purposes

	 test	 cx,@ADDR_SEP	; Separator specified?
	 jz	 short CMD_MOVE1 ; Not this time

	 mov	 MOVESEL_S,bx	; Save for display purposes
	 mov	 MOVEBASE_S,edx ; Save for later use

	 and	 MOVEMODE_S,not @MODE_VM ; Mark as protected mode
	 mov	 MOVEMASK_S,-1	; Use all 32 bits

	 test	 cx,@ADDR_PM	; Check mode
	 jnz	 short CMD_MOVE1 ; Jump if PM

	 or	 MOVEMODE_S,@MODE_VM ; Mark as VM86 mode
	 mov	 MOVEMASK_S,0000FFFFh ; Use low-order 16 bits
CMD_MOVE1:
	 mov	 eax,MOVEOFF_S	; Get specified offset

	 cmp	 eax,MOVEMASK_S ; Ensure within mask limits
	 ja	 near ptr CMD_MOVE_OVFERR ; Jump if not

; Parse length separator

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 near ptr CMD_MOVE_SYNTERR ; Yes, treat as error

	 call	 U32_LOWERCASE	; Convert AL to lowercase

	 cmp	 al,'l'         ; Izit length parameter?
	 jne	 near ptr CMD_MOVE_SYNTERR ; No, so that's an error

	 inc	 esi		; Skip over length separator

; Parse length parameter

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

; Convert the con/reg at DS:ESI to binary

	 call	 PARSE_LVAL	; Parse command line for a lefthand value
	 jc	 near ptr CMD_MOVE_OVFERR ; Jump if too large

	 mov	 MOVELEN,eax	; Save for later use

; Parse the destination address

	 call	 PARSE_ADDR	; Parse command line for an address
	 jc	 near ptr CMD_MOVE_ERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

	 mov	 MOVEOFF_D,eax	; Save for display purposes

	 test	 cx,@ADDR_SEP	; Separator specified?
	 jz	 short CMD_MOVE2 ; Not this time

	 mov	 MOVESEL_D,bx	; Save for display purposes
	 mov	 MOVEBASE_D,edx ; Save for later use

	 and	 MOVEMODE_D,not @MODE_VM ; Mark as protected mode
	 mov	 MOVEMASK_D,-1	; Use all 32 bits

	 test	 cx,@ADDR_PM	; Check mode
	 jnz	 short CMD_MOVE2 ; Jump if PM

	 or	 MOVEMODE_D,@MODE_VM ; Mark as VM86 mode
	 mov	 MOVEMASK_D,0000FFFFh ; Use low-order 16 bits
CMD_MOVE2:
	 mov	 eax,MOVEOFF_D	; Get specified offset

	 cmp	 eax,MOVEMASK_D ; Ensure within mask limits
	 ja	 near ptr CMD_MOVE_OVFERR ; Jump if not

; Ensure nothing more on the line

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 jne	 short CMD_MOVE_SYNTERR ; No, so that's an error

; Move the data block

	 push	 gs		; Get all memory selector
	 pop	 es		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 esi,MOVEOFF_S	; ES:EDI ==> source offset
	 mov	 edi,MOVEOFF_D	; ES:EDI ==> destin offset

	 and	 esi,MOVEMASK_S ; Mask off wrapped bits (if VM86 mode)
	 and	 edi,MOVEMASK_D ; Mask off wrapped bits (if VM86 mode)

	 add	 esi,MOVEBASE_S ; ES:EDI ==> source base address
	 add	 edi,MOVEBASE_D ; ES:EDI ==> destin base address

	 mov	 ecx,MOVELEN	; ECX = length of MOVE area

; If the regions are overlapped, move the block in backwards so that
; the source does not get overwritten before it is copied

	 pushfd 		; Save direction flag

	 cmp	 esi,edi	; Is the source above the destination?
	 ja	 short @F	; Jump if so

	 add	 esi,ecx	; Start transfer at end of block
	 add	 edi,ecx	; ...

	 dec	 esi		; Address last byte of block
	 dec	 edi		; ...

	 std			; Move block backwards to avoid overlap
@@:

S32  rep movs	 <es:[esi].LO,es:[edi].LO> ; Move the block

	 popfd			; Restore direction flag

	 or	 LCL_FLAG,@LCL_REDI ; Mark as forced re-display of screen

	 clc			; Indicate all went well

	 jmp	 short CMD_MOVE_EXIT ; Join common exit code

CMD_MOVE_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	 jmp	 short CMD_MOVE_ERR ; Join common error exit code

CMD_MOVE_OVFERR:
	 mov	 MSGOFF,offset DGROUP:OVFERR ; Save offset of error message

;;;;;;;; jmp	 short CMD_MOVE_ERR ; Join common error exit code

CMD_MOVE_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Mark as in error
CMD_MOVE_EXIT:
	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_MOVE endp			; End CMD_MOVE procedure

PROG	 ends			; End PROG segment

	 MEND			; End SWAT_ENT module
