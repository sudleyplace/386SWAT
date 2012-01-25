;' $Header:   P:/PVCS/386SWAT/DVGA.ASV   1.1   23 Jun 1992 14:51:34   DAVID  $
	 title	 DVGA -- Dual VGA Initialization
	 page	 58,122
	 name	 DVGA
	 include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1990-92 Qualitas, Inc.  All rights reserved.

Environment:  IBM PC, tested under DOS 3.30.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, byte-aligned,  stack,  class 'prog'
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Tail    segment DTAIL, dword-aligned, public, class 'data'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, August, 1990.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include ASCII.INC
	 include DOSCALL.INC
	 include VIDCALL.INC
	 include BIOSCONF.INC
	 include BITFLAGS.INC
	 include 386.INC
.list

PGROUP	 group	 STACK,CODE,DATA


; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	 segment use16 byte stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

COMMENT|

DVGA POS[0] bit definitions:

Bit 5		 $DVGA_ESOG2	20:  1 = Enable sync on green (section 2)
				     0 = Disable ...
Bit 4		 $DVGA_ESOG1	10:  1 = Enable sync on green (section 1)
				     0 = Disable ...
Bit 3		 $DVGA_ENA2	08:  1 = Enable section 2
				     0 = Disable ...
Bit 2		 $DVGA_ENA1	04:  1 = Enable section 1
				     0 = Disable ...
Bit 1		 $DVGA_RSV	02:  (reserved)
Bit 0		 $DVGA_AENA	01:  1 = Adapter enable
				     0 = ... disable

|

DVGA_REC record  $DVGA_ESOG2:1,$DVGA_ESOG1:1,$DVGA_ENA2:1,$DVGA_ENA1:1,$DVGA_RSV:1,$DVGA_AENA:1
; 0Dh = 08+04+01 = (mask $DVGA_ENA2) or (mask $DVGA_ENA1) or (mask $DVGA_AENA)
; 09h = 08+   01 = (mask $DVGA_ENA2) or 		     (mask $DVGA_AENA)
; 05h =    04+01 =			(mask $DVGA_ENA1) or (mask $DVGA_AENA)
; 00h = 00

@DVGA_ENA12 equ  (mask $DVGA_ENA2) or (mask $DVGA_ENA1) or (mask $DVGA_AENA)
@DVGA_ENA2  equ  (mask $DVGA_ENA2)			   (mask $DVGA_AENA)
@DVGA_ENA1  equ 		      (mask $DVGA_ENA1) or (mask $DVGA_AENA)
@DVGA_ADIS  equ  00h

	 public  MCAID
MCAID	 dw	 8 dup (?)	; MCA adapter IDs

	 public  CURPOS,CURTYP
CURPOS	 dw	 ?		; Original cursor position
CURTYP	 dw	 ?		; ...		  type

	 public  DVGA_SLOT
DVGA_SLOT db	 ?		; DVGA slot # (origin-0)

	 public  LCLSTK,LCLSTKZ
	 align	 2
LCLSTK	 dw	 80h dup (?)	; Local stack
LCLSTKZ  dw	 0		; Top of stack

DATA	 ends			; End DATA segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP
.xlist
	 include PSP.INC	; Define & skip over PSP area for .COM program
.list
	 NPPROC  DVGA -- Dual VGA Initialization and Switch
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

	 lea	 sp,LCLSTKZ	; Switch to local stack

; Ensure it's an MCA

	 stc			; Assume not supported
	 mov	 ah,0C0h	; Function to get BIOS information
	 int	 15h		; Return with ES:BX ==> BIOS information
	 assume  es:nothing	; Tell the assembler about it
	 jc	 short DVGA_EXIT0 ; Jump if something went wrong

	 test	 es:[bx].CFG_PARMS,@CFG_MCA ; Izit a Micro Channel Architecture?
	 jz	 short DVGA_EXIT0 ; Jump if not

	 push	 ds		; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

; Find slot # of adapter ID 8102

	 call	 GET_ALLIDS	; Read and save all adapter IDs, check for 8102
	 jc	 short DVGA_EXIT0 ; Jump if not found

; Parse the command line for <CR>, <'0',CR>, or <'1',CR>

	 lea	 si,PSP_PARM_STRING ; DS:SI ==> command line
@@:
	 lodsb			; Get next character
	 call	 LOWERCASE	; Convert AL to lowercase

	 cmp	 al,' '         ; Izit white space?
	 je	 short @B	; Jump if so

	 cmp	 al,TAB 	; Izit white space?
	 je	 short @B	; Jump if so

	 cmp	 al,CR		; Izit EOL?
	 je	 short DVGA_INIT ; Jump if so (initialize the adapter)

	 cmp	 al,'0'         ; Izit return to original screen?
	 je	 short DVGA_ORIG ; Jump if so

	 cmp	 al,'s'         ; Izit split between system board and section 1?
	 je	 short DVGA_SPLIT ; Jump if so

; Assume it's switch to DVGA section 1 only

	 call	 DISABLE_SYSVGA ; Disable it
DVGA_SPLIT:

; Put the DVGA adapter into setup mode

	 call	 SETUP_DVGA	; Setup DVGA adapter

; Enable section 1 only

	 mov	 dx,102h	; I/O port for POS[0]
	 mov	 al,@DVGA_ENA1	; POS[0] value to enable section 1
	 out	 dx,al		; Tell the DVGA about it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 out	 dx,al		; Tell the DVGA about it

	 call	 DISABLE_SETUP	; Disable adapter setup
DVGA_EXIT0:
	 jmp	 DVGA_EXIT	; Join common exit code

DVGA_ORIG:

; Put the DVGA adapter into setup mode

	 call	 SETUP_DVGA	; Setup DVGA adapter

; Disable the DVGA adapter

	 mov	 dx,102h	; I/O port for POS[0]
	 mov	 al,@DVGA_ADIS	; POS[0] value to disable DVGA
	 out	 dx,al		; Tell the DVGA about it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 out	 dx,al		; Tell the DVGA about it

	 call	 DISABLE_SETUP	; Disable adapter setup

; Enable the system board VGA

	 call	 ENABLE_SYSVGA	; Enable it

	 jmp	 DVGA_EXIT	; Join common exit code

DVGA_INIT:

; Save cursor position and type

	 mov	 bh,0		; Display page #
	 VIDCALL @GETPOS	; Read cursor position into (DH,DL)
				; and cursor type into (CH,CL)
	 mov	 CURPOS,dx	; Save to restore later
	 mov	 CURTYP,cx	; ...

; Disable the system board VGA

	 call	 DISABLE_SYSVGA ; Disable it

	 cli			; Disallow interrupts

; Put the DVGA adapter into setup mode

	 call	 SETUP_DVGA	; Set it up

; Enable both sections

	 mov	 dx,102h	; I/O port for POS[0]
	 mov	 al,@DVGA_ENA12 ; POS[0] value to enable both sections
	 out	 dx,al		; Tell the DVGA about it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 out	 dx,al		; Tell the DVGA about it

; Disable setup mode

	 call	 DISABLE_SETUP	; Disable adapter setup

; Put the DVGA adapter into setup mode

	 call	 SETUP_DVGA	; Setup DVGA adapter

; Enable section 1 only

	 mov	 dx,102h	; I/O port for POS[0]
	 mov	 al,@DVGA_ENA1	; POS[0] value to enable section 1
	 out	 dx,al		; Tell the DVGA about it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 out	 dx,al		; Tell the DVGA about it

; Disable setup mode

	 call	 DISABLE_SETUP	; Disable adapter setup

; Clear the DVGA memory for this section

	 mov	 al,0		; Mark as clearing regen buffer
	 call	 RESET_VIDEO	; Reset it

; Put the DVGA adapter into setup mode

	 call	 SETUP_DVGA	; Set it up

; Enable section 2 only

	 mov	 dx,102h	; I/O port for POS[0]
	 mov	 al,@DVGA_ENA2	; POS[0] value to enable section 2
	 out	 dx,al		; Tell the DVGA about it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 out	 dx,al		; Tell the DVGA about it

; Disable setup mode

	 call	 DISABLE_SETUP	; Disable adapter setup

; Clear the DVGA memory for this section

	 mov	 al,0		; Mark as clearing regen buffer
	 call	 RESET_VIDEO	; Reset it

; Put the DVGA adapter into setup mode

	 call	 SETUP_DVGA	; Set it up

; Disable the DVGA adapter

	 mov	 dx,102h	; I/O port for POS[0]
	 mov	 al,@DVGA_ADIS	; POS[0] value to disable DVGA adapter
	 out	 dx,al		; Tell the DVGA about it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 out	 dx,al		; Tell the DVGA about it

; Disable setup mode

	 call	 DISABLE_SETUP	; Disable adapter setup

; Enable the system board VGA

	 call	 ENABLE_SYSVGA	; Enable it

; Reset the video mode

	 mov	 al,@BIT7	; Mark as saving regen buffer
	 call	 RESET_VIDEO	; Reset it

; Restore cursor position

	 mov	 bh,0		; Display page #
	 mov	 dx,CURPOS	; Get original cursor position
	 VIDCALL @SETPOS	; Store cursor position from (DH,DL)

	 mov	 cx,CURTYP	; Get original cursor type
	 VIDCALL @SETTYP	; Store cursor type from (CH,CL)
DVGA_EXIT:
	 ret			; Return to DOS

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DVGA	 endp			; End DVGA procedure
	 NPPROC  GET_ALLIDS -- Get All Adapter IDs, Check for DVGA
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read and save all adapater iDs, check for DVGA (8102)

On exit:

CF	 =	 0 if DVGA found
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,di>	; Save registers

	 mov	 cx,8		; Loop counter
	 mov	 bl,0		; Start with slot #0
	 lea	 di,MCAID	; ES:DI ==> adapter ID save area
@@:
	 call	 GET_POSID	; Return with AX = POS ID for slot BL (origin-0)
S16	 stos	 MCAID		; Save in MCAID

	 inc	 bl		; Skip to next slot #

	 loop	 @B		; Jump if more adapters to check

	 mov	 ax,8102h	; Look for this one
	 mov	 cx,8		; Loop counter
	 lea	 di,MCAID	; ES:DI ==> adapter ID save area
   repne scasw			; Search for it
	 stc			; Assume not found
	 jne	 short GET_ALLIDS_EXIT ; Jump if not found

	 sub	 cx,8		; Less # slots
	 neg	 cx		; Negate to get slot # (origin-1)
	 dec	 cx		; Convert to origin-0
	 mov	 DVGA_SLOT,cl	; Save for later use

	 clc			; Mark as DVGA found
GET_ALLIDS_EXIT:
	 REGREST <di,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_ALLIDS endp 		; End GET_ALLIDS procedure
	 NPPROC  GET_POSID -- Get POS ID For A Slot
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get the POS ID for a slot.

On entry:

BL	 =	 slot # (origin-0)

On exit:

AX	 =	 POS ID

|

	 REGSAVE <dx>		; Save register

	 cli			; Disallow interrupts

	 mov	 al,bl		; Copy to I/O register
	 or	 al,@BIT3	; Select channel setup
	 out	 96h,al 	; Put into setup mode

	 mov	 dx,100h	; Adapter ID LSB register
	 in	 al,dx		; Get LSB of adapter ID

	 mov	 ah,al		; Save for later use
	 inc	 dx		; Skip to adapter MSB register

	 in	 al,dx		; Get MSB of adapter ID

	 xchg	 al,ah		; Swap to comparison order

	 call	 DISABLE_SETUP	; Disable adapter setup

	 sti			; Allow interrupts

	 REGREST <dx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_POSID endp			; End GET_POSID procedure
	 NPPROC  DISABLE_SYSVGA -- Disable System Board VGA
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable system board VGA

|

	 REGSAVE <ax,bx>	; Save registers

	 mov	 bl,32h 	; Function to enable/disable video
	 mov	 al,1		; Code to disable video
	 VIDCALL @GETEGA	; Request video services

	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISABLE_SYSVGA endp		; End DISABLE_SYSVGA procedure
	 NPPROC  ENABLE_SYSVGA -- Enable System Board VGA
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable system board VGA

|

	 REGSAVE <ax,bx>	; Save registers

	 mov	 bl,32h 	; Function to enable/disable video
	 mov	 al,0		; Code to enable video
	 VIDCALL @GETEGA	; Request video services

	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENABLE_SYSVGA endp		; End ENABLE_SYSVGA procedure
	 NPPROC  SETUP_DVGA -- Setup DVGA Adapter
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Put DVGA adapter into setup mode

|

	 push	 ax		; Save for a moment

	 mov	 al,DVGA_SLOT	; Get the slot # (origin-0)
	 or	 al,@BIT3	; Select channel setup
	 out	 96h,al 	; Put into setup mode

	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_DVGA endp 		; End SETUP_DVGA procedure
	 NPPROC  DISABLE_SETUP -- Disable Adapter Setup
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable adapter setup

|

	 push	 ax		; Save for a moment

	 mov	 al,0		; Disable channel setup
	 out	 96h,al 	; No position selected

	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISABLE_SETUP endp		; End DISABLE_SETUP procedure
	 NPPROC  RESET_VIDEO -- Reset Video Mode
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Reset video mode

On entry:

AL	 =	 80 if save of regen buffer
	 =	  0 otherwise

|

	 push	 ax		; Save for a moment

	 or	 al,03h 	; Mark as mode 03
	 VIDCALL @SETMOD	; Request video service

	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESET_VIDEO endp		; End RESET_VIDEO procedure
	 NPPROC  LOWERCASE -- Convert to Lowercase
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert to lowercase

On entry:

AL	 =	 character to convert

On exit:

AL	 =	 converted character

|

	 cmp	 al,'A'         ; Izit below lower uppercase?
	 jb	 short @F	; Jump if so

	 cmp	 al,'Z'         ; Izit above upper uppercase
	 ja	 short @F	; Jump if so

	 add	 al,'a'-'A'     ; Convert to lowercase
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOWERCASE endp			; End LOWERCASE procedure

CODE	 ends			; End CODE segment

	 MEND	 DVGA		; End DVGA module
