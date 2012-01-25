;' $Header:   P:/PVCS/386SWAT/POP87.ASV   1.6   21 Aug 1997 15:00:24   BOB  $
	 title	 POP87 -- Display The Status Of The 8087
	 page	 58,122
	 name	 POP87

COMMENT |		 Module Specifications

Copyright:  (C) Copyright 1985-97 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May 1985.

Modifications by:  None.

|
.386p
.xlist
	 include DOSCALL.INC
	 include 386.INC
	 include MASM.INC
	 include KEYCODE.INC
	 include PTR.INC
	 include ALLMEM.INC

	 include POP87.INC
	 include SWAT_COM.INC
	 include SWAT_SEG.INC
.list

DATA16	 segment use32 dword public 'data' ; Start DATA16 segment
	 assume  ds:DGROUP

	 extrn	 CURTYPE:word
	 extrn	 CURPOSN:word

	 extrn	 VIDTYPE:dword

	 extrn	 NDPATTR:byte

DATA16	 ends			; End DATA16 segment


DATA	 segment use32 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 FPSTATE:tbyte
	 extrn	 F_INIT:tbyte
	 extrn	 FL:abs
	 extrn	 NFLDS:abs

	 public  OLDCURPOS,OLDCURTYP
OLDCURPOS dw	 ?		; Save area for old cursor position
OLDCURTYP dw	 ?		; Save area for old cursor type

	 public  PCURFLD
PCURFLD  dd	 offset DGROUP:F_INIT ; Pointer to current field

	 public  STATE,CTWD,STWD,TGWD,IPDD,CSWD,OCWD,OPDD,DSWD,STKELT
STATE	 label	 byte		; Save area for 8087 state
CTWD	 CTL	 <>		; Control word
	 dw	 0		; Filler
STWD	 SWD	 <>		; Status word
	 dw	 0		; Filler
TGWD	 TWD	 <>		; Tag word
	 dw	 0		; Filler
IPDD	 dd	 ?		; EIP dword (bits 0-31)
CSWD	 dw	 ?		; CS word
OCWD	 OPC_WD  <>		; Opcode word (0-10)
OPDD	 dd	 ?		; Operand pointer (0-31)
DSWD	 dw	 ?		;    "    selector
	 dw	 0		; Filler
STKELT	 dt	 8 dup (?)	; Stack elements

	 public  TGW2,OCW2,OCW3
TGW2	 dw	 ?		; Secondary tag word (normalized)
OCW2	 dw	 ?		; Secondary opcode word (display order w/D800)
OCW3	 dw	 ?,0,0,0,0	; Tertiary ...	    (disassembly order w/D800)

	 public  STK0,STK1,STK2,STK3,STK4,STK5,STK6,STK7
STK0	 equ	 STKELT+0*type STKELT
STK1	 equ	 STKELT+1*type STKELT
STK2	 equ	 STKELT+2*type STKELT
STK3	 equ	 STKELT+3*type STKELT
STK4	 equ	 STKELT+4*type STKELT
STK5	 equ	 STKELT+5*type STKELT
STK6	 equ	 STKELT+6*type STKELT
STK7	 equ	 STKELT+7*type STKELT

	 public  SCRN,NCOLS,NROWS
SCRN	 label	 byte
MSG_CLR  equ	 SCRN+1
db'ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป'
NCOLS	 equ	 $-SCRN
	 public  R_CW,C_CW,C_CW0,C_CW1,C_CW2,C_CW3
db'บ CW: '
R_CW	 equ	 ($-SCRN)/NCOLS
C_CW	 equ	 ($-SCRN)-R_CW*NCOLS
C_CW0	 equ	 C_CW+0
C_CW1	 equ	 C_CW+1
C_CW2	 equ	 C_CW+2
C_CW3	 equ	 C_CW+3

	 public  R_RC,C_RC,C_RC0,C_RC1,R_@RC,C_@RC
db'....  RC: '
R_RC	 equ	 ($-SCRN)/NCOLS
C_RC	 equ	 ($-SCRN)-R_RC*NCOLS
C_RC0	 equ	 C_RC+0
C_RC1	 equ	 C_RC+1
db'..='
R_@RC	 equ	 ($-SCRN)/NCOLS
C_@RC	 equ	 ($-SCRN)-R_@RC*NCOLS

	 public  R_PC,C_PC,C_PC0,C_PC1,R_@PC,C_@PC
db'....  PC: '
R_PC	 equ	 ($-SCRN)/NCOLS
C_PC	 equ	 ($-SCRN)-R_PC*NCOLS
C_PC0	 equ	 C_PC+0
C_PC1	 equ	 C_PC+1
db'..='
R_@PC	 equ	 ($-SCRN)/NCOLS
C_@PC	 equ	 ($-SCRN)-R_@PC*NCOLS

	 public  R_IEM,C_IEM
db'..  IEM:'
R_IEM	 equ	 ($-SCRN)/NCOLS
C_IEM	 equ	 ($-SCRN)-R_IEM*NCOLS

	 public  R_PM,C_PM,R_UM,C_UM,R_OM,C_OM,R_ZM,C_ZM,R_DM,C_DM,R_IM,C_IM
db'.  PM:'
R_PM	 equ	 ($-SCRN)/NCOLS
C_PM	 equ	 ($-SCRN)-R_PM*NCOLS
db'.  UM:'
R_UM	 equ	 ($-SCRN)/NCOLS
C_UM	 equ	 ($-SCRN)-R_UM*NCOLS
db'.  OM:'
R_OM	 equ	 ($-SCRN)/NCOLS
C_OM	 equ	 ($-SCRN)-R_OM*NCOLS
db'.  ZM:'
R_ZM	 equ	 ($-SCRN)/NCOLS
C_ZM	 equ	 ($-SCRN)-R_ZM*NCOLS
db'.  DM:'
R_DM	 equ	 ($-SCRN)/NCOLS
C_DM	 equ	 ($-SCRN)-R_DM*NCOLS
db'.  IM:'
R_IM	 equ	 ($-SCRN)/NCOLS
C_IM	 equ	 ($-SCRN)-R_IM*NCOLS
db'.  บ'

	 public  R_IC,C_IC,R_@IC,C_@IC
db'บ           IC:  '
R_IC	 equ	 ($-SCRN)/NCOLS
C_IC	 equ	 ($-SCRN)-R_IC*NCOLS
db'.='
R_@IC	 equ	 ($-SCRN)/NCOLS
C_@IC	 equ	 ($-SCRN)-R_@IC*NCOLS

	 public  R_IR,C_IR
db'....              IR:'
R_IR	 equ	 ($-SCRN)/NCOLS
C_IR	 equ	 ($-SCRN)-R_IR*NCOLS

	 public  R_PE,C_PE,R_UE,C_UE,R_OE,C_OE,R_ZE,C_ZE,R_DE,C_DE,R_IE,C_IE
db'.  PE:'
R_PE	 equ	 ($-SCRN)/NCOLS
C_PE	 equ	 ($-SCRN)-R_PE*NCOLS
db'.  UE:'
R_UE	 equ	 ($-SCRN)/NCOLS
C_UE	 equ	 ($-SCRN)-R_UE*NCOLS
db'.  OE:'
R_OE	 equ	 ($-SCRN)/NCOLS
C_OE	 equ	 ($-SCRN)-R_OE*NCOLS
db'.  ZE:'
R_ZE	 equ	 ($-SCRN)/NCOLS
C_ZE	 equ	 ($-SCRN)-R_ZE*NCOLS
db'.  DE:'
R_DE	 equ	 ($-SCRN)/NCOLS
C_DE	 equ	 ($-SCRN)-R_DE*NCOLS
db'.  IE:'
R_IE	 equ	 ($-SCRN)/NCOLS
C_IE	 equ	 ($-SCRN)-R_IE*NCOLS
db'.  บ'

	 public  R_SW,C_SW,C_SW0,C_SW1,C_SW2,C_SW3
db'บ SW: '
R_SW	 equ	 ($-SCRN)/NCOLS
C_SW	 equ	 ($-SCRN)-R_SW*NCOLS
C_SW0	 equ	 C_SW+0
C_SW1	 equ	 C_SW+1
C_SW2	 equ	 C_SW+2
C_SW3	 equ	 C_SW+3

	 public  R_BSY,C_BSY
db'....  BUSY: '
R_BSY	 equ	 ($-SCRN)/NCOLS
C_BSY	 equ	 ($-SCRN)-R_BSY*NCOLS

	 public  R_CC,C_CC,C_CC0,C_CC1,C_CC2,C_CC3
db'.      C3210: '
R_CC	 equ	 ($-SCRN)/NCOLS
C_CC	 equ	 ($-SCRN)-R_CC*NCOLS
C_CC0	 equ	 C_CC+0
C_CC1	 equ	 C_CC+1
C_CC2	 equ	 C_CC+2
C_CC3	 equ	 C_CC+3

	 public  R_TST,C_TST,R_REM,C_REM,R_XAM,C_XAM
db'....  FTST: '
R_TST	 equ	 ($-SCRN)/NCOLS
C_TST	 equ	 ($-SCRN)-R_TST*NCOLS
db'.  FPREM: '
R_REM	 equ	 ($-SCRN)/NCOLS
C_REM	 equ	 ($-SCRN)-R_REM*NCOLS
db'.....  FXAM: '
R_XAM	 equ	 ($-SCRN)/NCOLS
C_XAM	 equ	 ($-SCRN)-R_XAM*NCOLS

db'.........   บ'

	 public  R_TP,C_TP,C_TP0,C_TP1,C_TP2
db'บ TOP: '
R_TP	 equ	 ($-SCRN)/NCOLS
C_TP	 equ	 ($-SCRN)-R_TP*NCOLS
C_TP0	 equ	 C_TP+0
C_TP1	 equ	 C_TP+1
C_TP2	 equ	 C_TP+2

	 public  R_CS,C_CS,C_CS0,C_CS1,C_CS2,C_CS3
db'...  IPTR='
R_CS	 equ	 ($-SCRN)/NCOLS
C_CS	 equ	 ($-SCRN)-R_CS*NCOLS
C_CS0	 equ	 C_CS+0
C_CS1	 equ	 C_CS+1
C_CS2	 equ	 C_CS+2
C_CS3	 equ	 C_CS+3

	 public  R_IP,C_IP,C_IP0,C_IP1,C_IP2,C_IP3
db'....:'
R_IP	 equ	 ($-SCRN)/NCOLS
C_IP	 equ	 ($-SCRN)-R_IP*NCOLS
C_IP0	 equ	 C_IP+0
C_IP1	 equ	 C_IP+1
C_IP2	 equ	 C_IP+2
C_IP3	 equ	 C_IP+3

	 public  R_DS,C_DS,C_DS0,C_DS1,C_DS2,C_DS3
db'....  OPTR='
R_DS	 equ	 ($-SCRN)/NCOLS
C_DS	 equ	 ($-SCRN)-R_DS*NCOLS
C_DS0	 equ	 C_DS+0
C_DS1	 equ	 C_DS+1
C_DS2	 equ	 C_DS+2
C_DS3	 equ	 C_DS+3
	 public  R_OF,C_OF,C_OF0,C_OF1,C_OF2,C_OF3
db'....:'
R_OF	 equ	 ($-SCRN)/NCOLS
C_OF	 equ	 ($-SCRN)-R_OF*NCOLS
C_OF0	 equ	 C_OF+0
C_OF1	 equ	 C_OF+1
C_OF2	 equ	 C_OF+2
C_OF3	 equ	 C_OF+3

	 public  R_OC,C_OC,C_OC0,C_OC1,C_OC2,C_OC3
db'....  OPCD: '
R_OC	 equ	 ($-SCRN)/NCOLS
C_OC	 equ	 ($-SCRN)-R_OC*NCOLS
C_OC0	 equ	 C_OC+0
C_OC1	 equ	 C_OC+1
C_OC2	 equ	 C_OC+2
C_OC3	 equ	 C_OC+3

	 public  R_DC,C_DC
db'....='
R_DC	 equ	 ($-SCRN)/NCOLS
C_DC	 equ	 ($-SCRN)-R_DC*NCOLS
S_DC	 label	 byte
db'.......................'
	 public  S_DCLEN
S_DCLEN  equ	 $-S_DC
db' บ'

	 irpc	 X,01234567
db'บ '
	 public  R_TG&X,C_TG&X,R_@T&X,C_@T&X
R_TG&X	 equ	 ($-SCRN)/NCOLS
C_TG&X	 equ	 ($-SCRN)-R_TG&X*NCOLS
db'..='
R_@T&X	 equ	 ($-SCRN)/NCOLS
C_@T&X	 equ	 ($-SCRN)-R_@T&X*NCOLS
db'.......  STK&X:'
db' '
	 public  R_S&X
R_S&X	 equ	 ($-SCRN)/NCOLS

	 irpc	 Y,ABCD
	 public  C_S&X&&Y
C_S&X&&Y equ	 ($-SCRN)-R_S&X*NCOLS
db'.'
	 endm
db' '
	 irpc	 Y,EFGH
	 public  C_S&X&&Y
C_S&X&&Y equ	 ($-SCRN)-R_S&X*NCOLS
db'.'
	 endm
db' '
	 irpc	 Y,IJKL
	 public  C_S&X&&Y
C_S&X&&Y equ	 ($-SCRN)-R_S&X*NCOLS
db'.'
	 endm
db' '
	 irpc	 Y,MNOP
	 public  C_S&X&&Y
C_S&X&&Y equ	 ($-SCRN)-R_S&X*NCOLS
db'.'
	 endm
db' '
	 irpc	 Y,QRST
	 public  C_S&X&&Y
C_S&X&&Y equ	 ($-SCRN)-R_S&X*NCOLS
db'.'
	 endm
db' = '
	 public  R_NM&X,C_NM&X
R_NM&X	 equ	 ($-SCRN)/NCOLS
C_NM&X	 equ	 ($-SCRN)-R_NM&X*NCOLS
db'-u.mmmmmmmmmmmmmmmmmmmmE-eeeee Dบ'
	 endm

	 public  R_SP,C_SP
R_SP	 equ	 R_@T0+0
C_SP	 equ	 C_@T0+8

db'ศอ'
O_LIMLO  label	 byte
db'0-'
O_LIMHI  label	 byte
db'1 to changeออ',1Bh,18h,1Ah,19h,' TAB S-TAB to moveออAlt-F8 to exitออ'
O_INS	 label	 byte
db'ออออออออออออออออออออออผ'
NROWS	 equ	 ($-SCRN)/NCOLS

	 public  MSG_INS
MSG_INS  db	 'INS to toggle empty'
MSG_LEN  equ	 $-MSG_INS

	 public  W_SCR,OLDSCRN
W_SCR	 dw	 0,0,NROWS,NCOLS ; Window descriptor for screen
OLDSCRN  db	 (NROWS*NCOLS*2) dup (?) ; Save area for old screen

	 public  LIMTAB
LIMTAB	 label	 word		; Limits table -- lower, upper
	 db	 '00'           ; Type 0
	 db	 '01'           ;      1
	 db	 '0F'           ;      2
	 db	 '8F'           ;      3

; Note:  the code below assumes that the first 15 entries in K87_TAB &
;	 K87_ACT are for the hex digits 00h to 0Fh.

	 public  K87_TAB,NKEYS
K87_TAB  dw	 @KEY_0 	; 0
	 dw	 @KEY_1 	; 1
	 dw	 @KEY_2 	; 2
	 dw	 @KEY_3 	; 3
	 dw	 @KEY_4 	; 4
	 dw	 @KEY_5 	; 5
	 dw	 @KEY_6 	; 6
	 dw	 @KEY_7 	; 7
	 dw	 @KEY_8 	; 8
	 dw	 @KEY_9 	; 9
	 dw	 @KEY_A 	; A
	 dw	 @KEY_B 	; B
	 dw	 @KEY_C 	; C
	 dw	 @KEY_D 	; D
	 dw	 @KEY_E 	; E
	 dw	 @KEY_F 	; F
	 dw	 @KEY_UP	; Up
	 dw	 @KEY_XUP	; X-Up
	 dw	 @KEY_DN	; Down
	 dw	 @KEY_XDN	; X-Down
	 dw	 @KEY_LEFT	; Left
	 dw	 @KEY_XLEFT	; X-Left
	 dw	 @KEY_RIGHT	; Right
	 dw	 @KEY_XRIGHT	; X-Right
	 dw	 @KEY_INS	; Ins
	 dw	 @KEY_XINS	; X-Ins
	 dw	 @KEY_TAB	; Tab
	 dw	 @KEY_SHF_TAB	; S-Tab
	 dw	 @KEY_ALT_F8	; Exit
NKEYS	 equ	 ($-K87_TAB)/(type K87_TAB)

	 public  K87_ACT
K87_ACT  dd	 offset PGROUP:K_0     ; 0
	 dd	 offset PGROUP:K_1     ; 1
	 dd	 offset PGROUP:K_2     ; 2
	 dd	 offset PGROUP:K_3     ; 3
	 dd	 offset PGROUP:K_4     ; 4
	 dd	 offset PGROUP:K_5     ; 5
	 dd	 offset PGROUP:K_6     ; 6
	 dd	 offset PGROUP:K_7     ; 7
	 dd	 offset PGROUP:K_8     ; 8
	 dd	 offset PGROUP:K_9     ; 9
	 dd	 offset PGROUP:K_A     ; A
	 dd	 offset PGROUP:K_B     ; B
	 dd	 offset PGROUP:K_C     ; C
	 dd	 offset PGROUP:K_D     ; D
	 dd	 offset PGROUP:K_E     ; E
	 dd	 offset PGROUP:K_F     ; F
	 dd	 offset PGROUP:K_UP    ; Up
	 dd	 offset PGROUP:K_UP    ; X-Up
	 dd	 offset PGROUP:K_DN    ; Down
	 dd	 offset PGROUP:K_DN    ; X-Down
	 dd	 offset PGROUP:K_LFT   ; Left
	 dd	 offset PGROUP:K_LFT   ; X-Left
	 dd	 offset PGROUP:K_RHT   ; Right
	 dd	 offset PGROUP:K_RHT   ; X-Right
	 dd	 offset PGROUP:K_INS   ; Ins
	 dd	 offset PGROUP:K_INS   ; X-Ins
	 dd	 offset PGROUP:K_TAB   ; Tab
	 dd	 offset PGROUP:K_STAB  ; S-Tab
	 dd	 offset PGROUP:K_EXIT  ; Exit

	 public  HEXTAB,DISP_STATUS
HEXTAB	 db	 '0123456789ABCDEF' ; Binary to hex translate table
DISP_STATUS db	 1		; Display status:  1=display, 0=not

P_TAG	 label	 dword
	 irpc	 X,01234567
	 extrn	 F_TAG&X:byte
	 dd	 offset DGROUP:F_TAG&X
	 endm

P_NUM	 label	 dword
	 irpc	 X,01234567
	 extrn	 F_NM&X:byte
	 dd	 offset DGROUP:F_NM&X
	 endm

DATA	 ends			; End DATA segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 extrn	 GETKEY:near

	 extrn	 SET_CURPOS:near
	 extrn	 SET_CURTYP:near

	 extrn	 WGET_CA:near
	 extrn	 WPUT_CA:near
	 extrn	 WPUT_CSA:near
	 extrn	 WPUT_C:near

	 extrn	 D_NUM:near

	 NPPROC  DISP_NDP -- Display Status Of NDP Chip
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Save screen
Save cursor
Save state
Display state
Set cursor
Take input
Restore state
Restore cursor
Restore screen

|

	 pushad 		; Save all EGP registers

	 cld			; String ops forwardly

; Save the screen

	 call	 SAVE_SCREEN

; Save the cursor position

	 call	 SAVE_CURSOR

; Save the state

	 call	 SAVE_STATE

; Display the state

	 call	 DISP_STATE

; Set the cursor to the current field

	 mov	 esi,PCURFLD	; Get pointer to current field #
	 call	 INI_SCREEN	; Set initial screen
	 call	 SET_NEWCURP	; Set new cursor position

; Take input

NEXT_KEY:
	 cmp	 DISP_STATUS,0	; Check display status
	 je	 short NEXT_KEY1 ; No need to display the screen

	 call	 NEW_SCREEN	; Display the new screen
	 mov	 DISP_STATUS,0	; Clear the display status
NEXT_KEY1:
	 call	 GETKEY 	; Get a key into AX
	 mov	 ecx,NKEYS	; # keys
	 lea	 edi,K87_TAB	; ES:EDI ==> valid keys
   repne scas	 K87_TAB[edi]	; Search for it
	 jne	 short NEXT_KEY1 ; Not found, ignore it

	 sub	 edi,(type K87_TAB)+offset DGROUP:K87_TAB ; Convert to origin-0
	 mov	 ebx,edi	; Copy 2*index
LOG2 LOG2@K87_TAB,<type K87_TAB>
	 shr	 ebx,LOG2@K87_TAB ; Convert to item count
	 mov	 esi,PCURFLD	; Get pointer to current field #

	 jmp	 K87_ACT[ebx*(type K87_ACT)] ; Take appropriate action

K_EXIT:
	 call	 REST_STATE	; Restore the state

; Restore the cursor position

	 call	 REST_CURSOR

; Restore the screen

	 call	 OLD_SCREEN	; Display old screen

	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_NDP endp			; End DISP_NDP procedure
	 NPPROC  SAVE_SCREEN -- Save The Current Screen
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 push	 offset DGROUP:OLDSCRN ; Pointer to screen
	 push	 offset DGROUP:W_SCR ; Pointer to window descriptor
	 call	 WGET_CA	; Save the screen

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_SCREEN endp		; End SAVE_SCREEN procedure
	 NPPROC  SAVE_STATE -- Save The Current NDP State
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <eax,ecx>	; Save registers

	 pushfd 		; Save flags
	 cli			; Ensure no interrupts allowed during FNSAVE

	 clts			; Ensure TS clear in CR0
if @WordSize EQ 2
	 db	 66h		; Use 32-bit format *FIXME*
endif				; IF @WordSize EQ 2
	 fnsave  STATE		; Write out the full state
	 fwait			; Wait for state to be stored

	 popfd			; Restore flags

; Normalize the tag word so that the bits for tag i correspond to ST(i)

	 mov	 cx,STWD	; Get status word
	 and	 cx,mask $TOP	; Isolate TOP bits
	 shr	 cx,$TOP	; Shift to low-order
	 shl	 cx,1		; Convert from 2-bits to bits
	 mov	 ax,TGWD	; Get tag word
	 ror	 ax,cl		; Rotate into position
	 mov	 TGW2,ax	; Save for later use

; Convert the opcode word to origin-D8

	 mov	 ax,OCWD	; Get opcode word
	 and	 ax,mask $OPCODE ; Isolate opcode
	 or	 ax,0D800h	; Include ESC prefix
	 mov	 OCW2,ax	; Save as new opcode

	 REGREST <ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_STATE endp 		; End SAVE_STATE procedure
	 NPPROC  REST_STATE -- Restore NDP State
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <eax,ecx>	; Save registers

; Unnormalize the tag word to original format

	 mov	 cx,STWD	; Get status word
	 and	 cx,mask $TOP	; Isolate TOP bits
	 shr	 cx,$TOP	; Shift to low-order
	 shl	 cx,1		; Convert from 2-bits to bits
	 mov	 ax,TGW2	; Get tag word
	 rol	 ax,cl		; Rotate into position
	 mov	 TGWD,ax	; Save for later use

; Convert the opcode word to origin-0

	 mov	 ax,OCW2	; Get secondary opcode word
	 and	 ax,mask $OPCODE ; Isolate opcode bits
	 and	 OCWD,not (mask $OPCODE) ; Zero bits in primary word
	 or	 OCWD,ax	; Include bits in case they changed

if @WordSize EQ 2
	 db	 66h		; Use 32-bit format *FIXME*
endif				; IF @WordSize EQ 2
	 fnrstor STATE		; Restore the NDP state

	 REGREST <ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_STATE endp 		; End REST_STATE procedure
	 NPPROC  DISP_STATE -- Display The Current NDP State
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <ecx,esi>	; Save registers

	 lea	 esi,FPSTATE	; DS:ESI ==> start of fields
	 mov	 ecx,NFLDS	; # fields
DISP_STATE_NEXT:
	 call	 DGROUP:[esi].F_PDSP ; Call the display function

	 add	 esi,FL 	; Skip to next field

	 loop	 DISP_STATE_NEXT ; Jump if more fields to display

	 REGREST <esi,ecx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_STATE endp 		; End DISP_STATE procedure
	 NPPROC  INI_SCREEN -- Display The Initial Screen
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 push	 eax		; Save register

	 mov	 al,NDPATTR	; Use NDP attribute
	 push	 ax		; Pass as argument #3
	 push	 offset DGROUP:SCRN ; Pointer to screen
	 push	 offset DGROUP:W_SCR ; Pointer to window descriptor
	 call	 WPUT_CSA	; Display the screen

	 pop	 eax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INI_SCREEN endp 		; End INI_SCREEN procedure
	 NPPROC  NEW_SCREEN -- Display The New Screen
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 push	 offset DGROUP:SCRN ; Pointer to screen
	 push	 offset DGROUP:W_SCR ; Pointer to window descriptor
	 call	 WPUT_C 	; Display the screen

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

NEW_SCREEN endp 		; End NEW_SCREEN procedure
	 NPPROC  OLD_SCREEN -- Display The Old Screen
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 push	 offset DGROUP:OLDSCRN ; Pointer to screen
	 push	 offset DGROUP:W_SCR ; Pointer to window descriptor
	 call	 WPUT_CA	; Display the screen

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OLD_SCREEN endp 		; End OLD_SCREEN procedure
	 NPPROC  K_ACT -- Key Action Routines
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Key Action Routines

On entry:

ESI	 ==>	 current field
EDI	 =	 2*key # (relative to K87_TAB)

|

K_F:
K_E:
K_D:
K_C:
K_B:
K_A:
K_9:
K_8:
	 cmp	 DGROUP:[esi].F_TYPE,1 ; Check for bit input
	 jne	 short K_INP	; Not bit, OK key

	 jmp	 NEXT_KEY	; Ignore the key

K_7:
K_6:
K_5:
K_4:
K_3:
K_2:
	 cmp	 DGROUP:[esi].F_TYPE,10 ; Check for hex input (stack elements)
	 jae	 short K_INP	; It's OK

	 cmp	 DGROUP:[esi].F_TYPE,2 ; Check for hex input
	 jne	 near ptr NEXT_KEY ; Not hex, ignore the key
K_1:
K_0:
	 cmp	 DGROUP:[esi].F_TYPE,3 ; Check for 8-F input type
	 je	 near ptr NEXT_KEY ; It is, ignore the key
K_INP:
	 call	 SET_LIMS	; Set input limits

	 mov	 eax,edi	; Copy 2*key value
	 shr	 eax,1		; Get actual binary value
	 mov	 cl,DGROUP:[esi].F_SHFT ; Get shift amount
	 shl	 eax,cl 	; Shift into place

	 call	 SET_DISP	; Set and display the value

	 jmp	 short K_RHT	; Hang a right

	 subttl  Insert Key
	 page
K_INS:
	 mov	 bl,DGROUP:[esi].F_TYPE ; Get this field's type

	 sub	 bl,10		; Check for stack elements
	 jc	 near ptr NEXT_KEY ; Not this time

	 xor	 bh,bh		; Zero to use as word

; Get state of current stack element's tag

	 mov	 esi,P_TAG[ebx*(type P_TAG)] ; DS:ESI ==> current field's tag struct
	 mov	 edi,DGROUP:[esi].F_PVAL ; Get pointer to value
	 mov	 ax,DGROUP:[edi] ; Get value
	 mov	 dx,DGROUP:[esi].F_MSK	; Get mask
	 and	 ax,dx		; Isolate bits

	 cmp	 ax,dx		; Check for 11 = Empty
	 jne	 short K_INS_MT ; It's non-empty now, make empty

	 not	 dx		; Complement to zero value
	 and	 DGROUP:[edi],dx ; Zero those positions
	 not	 dx		; Restore
	 push	 esi		; Save pointer to tag field
	 mov	 esi,P_NUM[ebx*(type P_NUM)] ; Get pointer to corresponding NUM field
	 call	 D_NUM		; Examine the value and display
	 pop	 esi		; Restore
	 and	 dx,DGROUP:[edi] ; Get new bits
K_INS_MT:
	 mov	 ax,dx		; Set bits to this
	 call	 SET_DISP	; Set and display the tag value

	 jmp	 NEXT_KEY	; Join common exit code

	 subttl  Cursor Movement Keys
	 page
K_UP:
	 mov	 al,DGROUP:[esi].F_UP ; Get new field #

	 jmp	 short K_DIR_COM ; Join common direction code

K_DN:
	 mov	 al,DGROUP:[esi].F_DN ; Get new field #

	 jmp	 short K_DIR_COM ; Join common direction code

K_LFT:
	 mov	 al,DGROUP:[esi].F_LFT ; Get new field #

	 jmp	 short K_DIR_COM ; Join common direction code

K_RHT:
	 mov	 al,DGROUP:[esi].F_RHT ; Get new field #

	 jmp	 short K_DIR_COM ; Join common direction code

K_TAB:
	 mov	 al,DGROUP:[esi].F_TAB ; Get new field #

	 jmp	 short K_DIR_COM ; Join common direction code

K_STAB:
	 mov	 al,DGROUP:[esi].F_STAB ; Get new field #
K_DIR_COM:
	 mov	 ah,FL		; Get structure length
	 mul	 ah		; AX = offset into structure of new field
	 movzx	 eax,ax 	; Zero to use as dword
	 add	 eax,offset DGROUP:FPSTATE ; Absolute offset now
	 mov	 PCURFLD,eax	; Save for later use
	 mov	 esi,eax	; Copy for SET_NEWCURP
	 call	 SET_LIMS	; Set input limits
	 call	 SET_NEWCURP	; Set new cursor position

	 jmp	 NEXT_KEY	; Get next key

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

K_ACT	 endp			; End K_ACT procedure
	 NPROC	 SET_LIMS -- Set Input Limits
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 push	 ebx		; Save register

	 mov	 bl,DGROUP:[esi].F_TYPE ; Get the field type

	 cmp	 bl,10		; Check for stack element input
	 jb	 short SET_LIMS1 ; Not this time

	 mov	 bl,2		; Call it hex input
SET_LIMS1:
	 movzx	 ebx,bl 	; Zero to use as dword
	 mov	 bx,LIMTAB[ebx*(type LIMTAB)] ; Get upper and lower limits
	 mov	 O_LIMLO,bl	; Save in screen buffer
	 mov	 O_LIMHI,bh

	 mov	 DISP_STATUS,1	; Set display status on

	 pop	 ebx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_LIMS endp			; End SET_LIMS procedure
	 NPPROC  SET_DISP -- Set And Display The Value
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set & display a value

On entry:

AX	 =	 new bits
DS:ESI	 ==>	 current field's structure

|

	 REGSAVE <ebx,edx,esi>	; Save registers

	 mov	 dx,DGROUP:[esi].F_MSK ; Get mask
	 not	 dx		; Complement to zero value
	 mov	 ebx,DGROUP:[esi].F_PVAL ; Get pointer to value
	 and	 DGROUP:[ebx],dx ; Zero those positions
	 or	 DGROUP:[ebx],ax ; Include new value

	 mov	 DISP_STATUS,1	; Set display status on
	 call	 DGROUP:[esi].F_PDSP ; Call the display function

	 mov	 ebx,DGROUP:[esi].F_PREL ; Get ptr to vector of ptrs to related fields
SET_DISP_NEXT:
	 cmp	 DGROUP:[ebx].ELO,0 ; End of the line?
	 je	 short SET_DISP_EXIT ; Yes

	 mov	 esi,DGROUP:[ebx] ; Get the field offset
	 call	 DGROUP:[esi].F_PDSP ; Call the related display function
	 add	 ebx,2		; Skip to next entry

	 jmp	 short SET_DISP_NEXT ; Go around again

SET_DISP_EXIT:
	 REGREST <esi,edx,ebx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_DISP endp			; End SET_DISP procedure
	 NPPROC  SAVE_CURSOR -- Save The Current Cursor Position
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing

	 REGSAVE <eax>		; Save register

	 mov	 ax,CURPOSN	; Get current cursor position
	 mov	 OLDCURPOS,ax	; Save as old ...

	 mov	 ax,CURTYPE	; Get current cursor type
	 mov	 OLDCURTYP,ax	; Save as old ...

	 push	 VIDTYPE.EHI	; Set to insert mode
	 call	 SET_CURTYP	; Set cursor type

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_CURSOR endp		; End SAVE_CURSOR procedure
	 NPPROC  SET_NEWCURP -- Set New Cursor Position
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <eax,ecx,esi,edi> ; Save registers

	 mov	 ah,DGROUP:[esi].F_ROW ; Get row offset
	 mov	 al,DGROUP:[esi].F_COL ; Get col offset
	 push	 ax		; Pass as argument
	 call	 SET_CURPOS	; Set cursor position

	 lea	 edi,O_INS	; ES:EDI ==> insert message

	 cmp	 DGROUP:[esi].F_TYPE,10 ; Check for INS mode available
	 jb	 short SET_NEWCURP2 ; Not this time, clear the field

	 lea	 esi,MSG_INS	; DS:ESI ==> insert message

	 jmp	 short SET_NEWCURP3 ; Join common move code

SET_NEWCURP2:
	 lea	 esi,MSG_CLR	; DS:ESI ==> clear message
SET_NEWCURP3:
	 mov	 ecx,MSG_LEN	; ECX = message length
S32  rep movs	 <es:[edi].LO,ds:[esi].LO> ; Move in the message
	 mov	 DISP_STATUS,1	; Set display status on
SET_NEWCURP_EXIT:
	 REGREST <edi,esi,ecx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_NEWCURP endp		; End SET_NEWCURP procedure
	 NPPROC  REST_CURSOR -- Restore The Old Cursor Position
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing

	 push	 OLDCURPOS	; Pass as argument
	 call	 SET_CURPOS	; Set cursor position

	 push	 OLDCURTYP	; Pass as argument
	 call	 SET_CURTYP	; Set cursor type

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_CURSOR endp		; End REST_CURSOR procedure

PROG	 ends			; End PROG segment

	 MEND			; End POP87 module
