;' $Header:   P:/PVCS/386SWAT/INT1/INT1.ASV   1.2   01 Jul 1997 17:55:52   BOB  $
	 title	 INT1 -- INT 01h Driver
	 page	 58,122
	 name	 INT1

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Code    segment CODE,	 byte-aligned, public, class 'prog'
	       Stack   segment STACK,	 byte-aligned, stack,  class 'prog'
	       Program segment PROG,	 byte-aligned, public, class 'prog'
	       Data    segment NDATA,	 byte-aligned, public, class 'data'
	       Group WGROUP:
	       Data    segment WTAB,	 word-aligned, public, class 'wdata'
	       Data    segment WPTR,	 word-aligned, public, class 'wdata'
	       Data    segment WTXT,	 byte-aligned, public, class 'wdata'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, April, 1988.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include PTR.INC

	 include INT1_FNS.INC
.list

PGROUP	 group	 CODE,STACK,PROG
DGROUP	 group	 DATA,NDATA
WGROUP	 group	 WTAB,WPTR,WTXT


CODE	 segment use16 byte public 'prog' ; Start CODE segment
CODE	 ends			; End CODE segment


STACK	 segment use16 byte stack 'prog' ; Start STACK segment

	 db	 100 dup ('I1')

STACK	 ends			; End STACK segment


DATA	 segment use16 word public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 public  WINBASE
WINBASE  dd	 ?		; Offset in DGROUP of WGROUP

DATA	 ends			; End DATA segment


NDATA	 segment use16 word public 'data' ; Start NDATA segment
	 assume  ds:DGROUP

	 public  OPERAND
OPERAND  OPER_STR <>		; Operand data structure

	 public  OPERFL
OPERFL	 db	 ?		; Operand analysis flag:  CR = don't, other = do

	 public  OUTPUT
OUTPUT	 db	 90 dup (?)	; Output stream
OUTPUT_LEN equ	 $-OUTPUT	; Length of ...
	 db	 CR,LF,EOS	; EOS trailers

	 public  HEXTABLE
HEXTABLE db	 '0123456789ABCDEF' ; Binary to ASCII hex translate table
	 db	 'G'            ; To handle JCXZ CC

	 public  TXT_JCC
TXT_JCC  db	 ', Jump with CC = '
TXT_JCC_LEN equ  $-TXT_JCC	; # bytes in text

	 public  TXT_MODRM
TXT_MODRM db	 ', Mod R/M = '
TXT_MODRM_LEN equ $-TXT_MODRM	; # bytes in text

	 public  TXT_SIB
TXT_SIB  db	 ', SIB = '
TXT_SIB_LEN equ  $-TXT_SIB	; # bytes in text

	 public  TXT_1B
TXT_1B	 db	 ', One byte data'
TXT_1B_LEN equ	 $-TXT_1B	; # bytes in text

	 public  TXT_2B
TXT_2B	 db	 ', Two byte data'
TXT_2B_LEN equ	 $-TXT_2B	; # bytes in text

	 public  TXT_4B
TXT_4B	 db	 ', Four byte data'
TXT_4B_LEN equ	 $-TXT_4B	; # bytes in text

	 public  TXT_6B
TXT_6B	 db	 ', Six byte data'
TXT_6B_LEN equ	 $-TXT_6B	; # bytes in text

	 public  TXT_RD
TXT_RD	 db	 ', Data read'
TXT_RD_LEN equ	 $-TXT_RD	; # bytes in text

	 public  TXT_WR
TXT_WR	 db	 ', Data write'
TXT_WR_LEN equ	 $-TXT_WR	; # bytes in text

	 public  TXT_DISP
TXT_DISP db	 ', Disp = '
TXT_DISP_LEN equ $-TXT_DISP	; # bytes in text

	 public  SEGREG
SEGREG	 dw	 DGROUP:SEG_ES
	 dw	 DGROUP:SEG_CS
	 dw	 DGROUP:SEG_SS
	 dw	 DGROUP:SEG_DS
	 dw	 DGROUP:SEG_FS
	 dw	 DGROUP:SEG_GS
	 dw	 DGROUP:SEG_UNK
	 dw	 DGROUP:SEG_UNK

SEG_ES	 db	 ', ES'
SEG_CS	 db	 ', CS'
SEG_SS	 db	 ', SS'
SEG_DS	 db	 ', DS'
SEG_FS	 db	 ', FS'
SEG_GS	 db	 ', GS'
SEG_UNK  db	 ', ??'

NDATA	 ends			; End NDATA segment


WTAB	 segment use16 word public 'wdata' ; Start WTAB segment
WTAB	 ends			; End WTAB segment


WPTR	 segment use16 word public 'wdata' ; Start WPTR segment
WPTR	 ends			; End WPTR segment


WTXT	 segment use16 byte public 'wdata' ; Start WTXT segment
WTXT	 ends			; End WTXT segment


PROG	 segment use16 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 extrn	 INSTRDEC:near
	 extrn	 INSTROPER:near
	 extrn	 DB2HEX:near
	 extrn	 DW2HEX:near
	 extrn	 DD2HEX:near
	 extrn	 EXAMPLES:near

	 NPPROC  INT1 -- INT 01h Driver
	 assume  ds:nothing,es:nothing

	 mov	 ax,seg DGROUP	; Get segment
	 mov	 es,ax		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

; Check arguments for decoder or operand analyzer

	 mov	 si,81h 	; DS:SI ==> command line
@@:
	 lodsb			; Get next character

	 cmp	 al,' '         ; Check for white space
	 je	 short @B	; Jump if so

	 cmp	 al,TAB 	; Check for white space
	 je	 short @B	; Jump if so

	 mov	 OPERFL,al	; Save it

	 mov	 ax,seg DGROUP	; Get segment
	 mov	 ds,ax		; Address it
	 assume  ds:DGROUP	; Tell the assembler about it

; Calculate offset in DGROUP of WGROUP

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,seg WGROUP	; Get segment of WGROUP
	 sub	 ax,seg DGROUP	; Less ...	 DGROUP
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 WINBASE,eax	; Save for later use

	 push	 cs		; Setup FS for INSTRDEC
	 pop	 fs
	 assume  fs:nothing	; Tell the assembler about it

	 lea	 esi,EXAMPLES	; FS:ESI ==> instruction stream
	 mov	 cx,1000	; Disassemble this many instruction
	 xor	 ebx,ebx	; Zero entire register
;;;;;;;; mov	 bx,fs		; Copy segment base
;;;;;;;; shl	 ebx,4-0	; Convert from paras to bytes
INT1_NEXT1:

; Format the CS:IP into the output area

	 call	 FMT_CSIP	; Format it, return with ES:DI ==> next byte

	 cmp	 OPERFL,CR	; Display operand analysis?
	 je	 short @F	; Not this time

	 push	 di		; Save output pointer

	 lea	 di,OPERAND	; ES:DI ==> operand data structure

; Analyze operands at FS:ESI into ES:DI

	 push	 cx		; Save for a moment
	 xor	 cx,cx		; Indicate USE16 disassembly, real mode
	 call	 INSTROPER	; Analyze the next instruction
	 pop	 cx		; Restore

	 pop	 di		; Restore output pointer

; Display operand analysis at ES:DI

	 call	 DISP_OPER	; Display it
@@:

; Format the CS:IP into the output area

	 call	 FMT_CSIP	; Format it, return with ES:DI ==> next byte

; Disassemble the instruction at FS:ESI into ES:DI using EBX as an offset base

	 push	 cx		; Save for a moment
	 xor	 cx,cx		; Indicate USE16 disassembly, real mode
	 call	 INSTRDEC	; Disassemble the next instruction
	 pop	 cx		; Restore

	 mov	 al,CR		; End with a CR
	 stosb			; Save in output stream
	 mov	 al,LF		; ...LF
	 stosb			; Save in output stream
	 mov	 al,EOS 	; ...EOS
	 stosb			; Save in output stream

	 DOSCALL @STROUT,OUTPUT ; Display it

	 loop	 INT1_NEXT1	; Jump if more instruction to disassemble

	 mov	 al,0		; OK reason code
	 DOSCALL @EXITRC	; Return to DOS with reason code in AL

	 assume  ds:nothing,es:nothing

INT1	 endp			; End INT1 procedure
	 NPPROC  FMT_CSIP -- Format CS:IP Into Output Stream
	 assume  ds:DGROUP,es:DGROUP
COMMENT|

Format CS:IP into the output stream.

On entry:

FS:ESI	 =	  CS:IP to format

On exit:

ES:DI	 ==>	 next byte in output stream

|

	 REGSAVE <ax>		; Save register

	 call	 CLEAR_OUT	; Clear the output stream

; Format the CS:IP into the output area

	 lea	 di,OUTPUT	; ES:DI ==> output stream
	 mov	 ax,fs		; Get caller's segment
	 call	 DW2HEX 	; Display AX in hex at ES:DI

	 mov	 al,':'         ; Separator
	 stosb			; Save in output stream

	 mov	 ax,si		; FS:ESI ==> instruction stream start
	 call	 DW2HEX 	; Display AX in hex at ES:DI

	 mov	 al,' '         ; Separator
	 stosb			; Save in output stream

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

FMT_CSIP endp			; End FMT_CSIP procedure
	 NPPROC  DISP_OPER -- Display Operand Analysis Data
	 assume  ds:DGROUP,es:DGROUP
COMMENT|

Display operand analysis data.

On entry:

ES:DI	 ==>	  output stream

|

	 pushad 		; Save all EGP registers

; Display operand analysis at ES:DI

	 test	 OPERAND.OPER1_FLAG,@OPER_JCC ; Check for Jcc instruction
	 jz	 short DISP_OPER1 ; Not this time

	 lea	 si,TXT_JCC	; DS:SI ==> text to display
	 mov	 cx,TXT_JCC_LEN ; Get # bytes in text
     rep movsb			; Copy to output stream

	 mov	 al,OPERAND.OPER1_CC ; Get the condition code (00-0F)
	 lea	 bx,HEXTABLE	; DS:BX ==> hex translate table
	 xlat	 HEXTABLE	; Translate into hex
	 stosb			; Save in output stream

	 jmp	 DISP_OPER_COM	; Join common display code

DISP_OPER1:
	 test	 OPERAND.OPER1_FLAG,@OPER_MEM ; Does it reference memory?
	 jz	 near ptr DISP_OPER_COM ; No, skip all this

	 test	 OPERAND.OPER1_FLAG,@OPER_OSP ; Check for operand size prefix
	 jz	 short @F	; Not this time

	 mov	 eax,'PSO '     ; Get text to store
	 stosd			; Save in output stream
@@:
	 test	 OPERAND.OPER1_FLAG,@OPER_ASP ; Check for address size prefix
	 jz	 short @F	; Not this time

	 mov	 eax,'PSA '     ; Get text to store
	 stosd			; Save in output stream
@@:

; Display segment register

	 movzx	 si,OPERAND.OPER1_SEG ; Get the segment register
	 shl	 si,1		; Times two to index table of words
	 mov	 si,SEGREG[si]	; DS:SI ==> segment register name
	 movsd			; Copy to output stream

	 test	 OPERAND.OPER1_FLAG,@OPER_MRM ; Check for Mod R/M byte
	 jz	 short @F	; Not this time

	 lea	 si,TXT_MODRM	; DS:SI ==> text to display
	 mov	 cx,TXT_MODRM_LEN ; Get # bytes in text
     rep movsb			; Copy to output stream

	 mov	 al,OPERAND.OPER1_MODRM ; Get the byte to display
	 call	 DB2HEX 	; Display AL in hex at ES:DI
@@:
	 test	 OPERAND.OPER1_FLAG,@OPER_SIB ; Check for SIB
	 jz	 short @F	; Not this time

	 lea	 si,TXT_SIB	; DS:SI ==> text to display
	 mov	 cx,TXT_SIB_LEN ; Get # bytes in text
     rep movsb			; Copy to output stream

	 mov	 al,OPERAND.OPER1_SIB ; Get the byte to display
	 call	 DB2HEX 	; Display AL in hex at ES:DI
@@:
	 test	 OPERAND.OPER1_DWID,@DWIDTH_BYTE ; Check for one-byte data
	 jz	 short @F	; Not this time

	 lea	 si,TXT_1B	; DS:SI ==> text to display
	 mov	 cx,TXT_1B_LEN	; Get # bytes in text
     rep movsb			; Copy to output stream
@@:
	 test	 OPERAND.OPER1_DWID,@DWIDTH_WORD ; Check for two-byte data
	 jz	 short @F	; Not this time

	 lea	 si,TXT_2B	; DS:SI ==> text to display
	 mov	 cx,TXT_2B_LEN	; Get # bytes in text
     rep movsb			; Copy to output stream
@@:
	 test	 OPERAND.OPER1_DWID,@DWIDTH_DWORD ; Check for four-byte data
	 jz	 short @F	; Not this time

	 lea	 si,TXT_4B	; DS:SI ==> text to display
	 mov	 cx,TXT_4B_LEN	; Get # bytes in text
     rep movsb			; Copy to output stream
@@:
	 test	 OPERAND.OPER1_FLAG,@OPER_RD ; Check for data read
	 jz	 short @F	; Not this time

	 lea	 si,TXT_RD	; DS:SI ==> text to display
	 mov	 cx,TXT_RD_LEN	; Get # bytes in text
     rep movsb			; Copy to output stream
@@:
	 test	 OPERAND.OPER1_FLAG,@OPER_WR ; Check for data write
	 jz	 short @F	; Not this time

	 lea	 si,TXT_WR	; DS:SI ==> text to display
	 mov	 cx,TXT_WR_LEN	; Get # bytes in text
     rep movsb			; Copy to output stream
@@:
	 test	 OPERAND.OPER1_FLAG,@OPER_DSP ; Check for displacement
	 jz	 short @F	; Not this time

	 lea	 si,TXT_DISP	; DS:SI ==> text to display
	 mov	 cx,TXT_DISP_LEN ; Get # bytes in text
     rep movsb			; Copy to output stream

	 mov	 eax,OPERAND.OPER1_DISP ; Get displacement
	 call	 DD2HEX 	; Display EAX in hex at ES:DI
@@:




DISP_OPER_COM:
	 mov	 al,CR		; End with a CR
	 stosb			; Save in output stream

	 mov	 al,LF		; ...LF
	 stosb			; Save in output stream

	 mov	 al,EOS 	; ...EOS
	 stosb			; Save in output stream

	 DOSCALL @STROUT,OUTPUT ; Display it

	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

DISP_OPER endp			; End DISP_OPER procedure
	 NPPROC  CLEAR_OUT -- Clear the Output Stream Area
	 assume  ds:DGROUP,es:DGROUP
COMMENT|

Clear the output stream area.

|

	 REGSAVE <ax,cx,di>	; Save registers

	 lea	 di,OUTPUT	; ES:DI ==> output stream
	 mov	 cx,OUTPUT_LEN	; CX = length of stream
	 mov	 al,' '         ; Fill with blanks
     rep stosb			; Clear it

	 REGREST <di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

CLEAR_OUT endp			; End CLEAR_OUT procedure

PROG	 ends			; End PROG segment

	 MEND	 INT1		; End INT1 module
