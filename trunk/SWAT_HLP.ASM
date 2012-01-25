;' $Header:   P:/PVCS/386SWAT/SWAT_HLP.ASV   1.5   20 Aug 1998 23:05:54   BOB  $
	 title	 SWAT_HLP -- 386SWAT Help Display Functions
	 page	 58,122
	 name	 SWAT_HLP

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include KEYCODE.INC
NOVER_HTU equ	1
	 include VERSION.INC

	 include SWAT_COM.INC
	 include SWAT_SEG.INC
.list

DATA16	 segment use32 dword public 'data' ; Start DATA16 segment
	 assume  ds:DGROUP

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	 extrn	 HLPATTR:byte
	 extrn	 HLPAATTR:byte
	 extrn	 HLPBATTR:byte
	 extrn	 HKEYATTR:byte
	 extrn	 HTTLATTR:byte

	 extrn	 WINBASE:dword

DATA16	 ends			; End DATA16 segment


DATA	 segment use32 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	public	@SWAT_HLP_DATA
@SWAT_HLP_DATA label byte	; Mark module start in .MAP file

	 extrn	 MSGOFF:dword
	 extrn	 INITERR:byte

HLP_REC  record  $HLP_ACT:1

	 public  HLP_FLAG
HLP_FLAG dw	 0		; Help flags
@HLP_ACT equ	 (mask $HLP_ACT) ; Help subtopic being displayed

	 public  PHTOPTTL
PHTOPTTL dd	 offset WGROUP:HELP_QKYTTL ; Ptrs to help topic titles
	 dd	 offset WGROUP:HELP_NAVTTL
	 dd	 offset WGROUP:HELP_CMDTTL
	 dd	 offset WGROUP:HELP_BKMTTL
	 dd	 offset WGROUP:HELP_AFLTTL
	 dd	 offset WGROUP:HELP_SRCHTTL
	 dd	 offset WGROUP:HELP_WKDTTL
; NEW TOPIC GOES HERE
;;;;;;;; dd	 offset WGROUP:HELP_???TTL

	 public  HLPIND
HLPIND	 dd	 0		; Index into help screen

	 public  HTOPIND
HTOPIND  dd	 0		; Row index into HELP_QKY
	 dd	 0		; ...		     _NAV
	 dd	 0		; ...		     _CMD
	 dd	 0		; ...		     _BKM
	 dd	 0		; ...		     _AFL
	 dd	 0		; ...		     _SRCH
	 dd	 0		; ...		     _WKD
; NEW TOPIC GOES HERE
;;;;;;;; dd	 0		; ...		     _???
@HTOPIND equ	 ($-HTOPIND)/(type HTOPIND) ; # help topics

	 public  HLPTOPIC
HLPTOPIC dd	 offset WGROUP:HELP_QKY
	 dd	 offset WGROUP:HELP_NAV
	 dd	 offset WGROUP:HELP_CMD
	 dd	 offset WGROUP:HELP_BKM
	 dd	 offset WGROUP:HELP_AFL
	 dd	 offset WGROUP:HELP_SRCH
	 dd	 offset WGROUP:HELP_WKD
; NEW TOPIC GOES HERE
;;;;;;;; dd	 offset WGROUP:HELP_???

	 public  ARR_W_HTOP
ARR_W_HTOP W_STR <@HTXT_SROW, @HTXT_SCOL, @HQKY_NROW, @HTXT_NCOL>
	 W_STR	 <@HTXT_SROW, @HTXT_SCOL, @HNAV_NROW, @HTXT_NCOL>
	 W_STR	 <@HTXT_SROW, @HTXT_SCOL, @HCMD_NROW, @HTXT_NCOL>
	 W_STR	 <@HTXT_SROW, @HTXT_SCOL, @HBKM_NROW, @HTXT_NCOL>
	 W_STR	 <@HTXT_SROW, @HTXT_SCOL, @HAFL_NROW, @HTXT_NCOL>
	 W_STR	 <@HTXT_SROW, @HTXT_SCOL, @HSRCH_NROW, @HTXT_NCOL>
	 W_STR	 <@HTXT_SROW, @HTXT_SCOL, @HWKD_NROW, @HTXT_NCOL>
; NEW TOPIC GOES HERE
;;;;;;;; W_STR	 <@HTXT_SROW, @HTXT_SCOL, @H???_NROW, @HTXT_NCOL>

	 public  W_HKEY
W_HKEY	 W_STR	 <@HKEY_SROW, @HKEY_SCOL, @HKEY_NROW,	 @HKEY_NCOL>

	 public  MSG_HKEY
MSG_HKEY db	 'Press ESC to return to Help Menu                                              '
@HKEY_NCOL equ	 $-MSG_HKEY
	 db	 'Press F3 to see previous Help Topic            Press F4 to see next Help Topic'

@HKEY_NROW equ	 ($-MSG_HKEY)/@HKEY_NCOL

@HKEY_SROW equ	 (@NROWS - 1) - (@HKEY_NROW - 1)
@HKEY_SCOL equ	 1

	 public  W_HELP
W_HELP	 W_STR	 <@HELP_SROW, @HELP_SCOL, @HELP_NROW, @HELP_NCOL>

	 public  MSG_HELP
MSG_HELP db	 'ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿'
@HELP_NCOL equ	 $-MSG_HELP
;;;;;;;; db	 '³  386SWAT Version x.xx      ³'
	 db	 '³  386SWAT Version ',VERS_H,'.',VERS_T,VERS_U,'      ³'
	 db	 '³                            ³'
	 db	 '³  Press Enter to Select a   ³'
	 db	 '³         Help Topic         ³'
	 db	 '³                            ³'
@HLIN_SROW equ	 @HELP_SROW + ($-MSG_HELP)/@HELP_NCOL
MSG_HLIN db	 '³  Quick Guide to Keystrokes ³'
	 db	 '³  Navigating 386SWAT        ³'
	 db	 '³  Command Line Actions      ³'
	 db	 '³  Bookmarks                 ³'
	 db	 '³  Autofaults                ³'
	 db	 '³  Searching                 ³'
	 db	 '³  Windows-specific Commands ³'
; NEW TOPIC GOES HERE
;;;;;;;; db	 '³  ???                       ³'
	 public  @HLIN_LEN
@HLIN_LEN equ	 ($-MSG_HLIN)/@HELP_NCOL
	 db	 '³                            ³'
	 db	 '³   Press ESC to Return to   ³'
	 db	 '³      the Main Screen       ³'
	 db	 'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ'
@HELP_NROW equ	 ($-MSG_HELP)/@HELP_NCOL

@HELP_SROW equ	 (@NROWS - 1 - @HELP_NROW)/2 + 4 ; Center the box (plus a little)
@HELP_SCOL equ	 (@NCOLS - 1 - @HELP_NCOL)/2 ; ...

	 public  W_HLIN
	 align	 2
W_HLIN	 W_STR	 <@HLIN_SROW, @HLIN_SCOL, @HLIN_NROW, @HLIN_NCOL>

@HLIN_SCOL equ	 @HELP_SCOL + 1 + 1
@HLIN_NROW equ	 1
@HLIN_NCOL equ	 @HELP_NCOL - 2 - 2

@HASK_NROW equ	 @HLIN_LEN
@HASK_NCOL equ	 @HLIN_NCOL
@HASK_SCOL equ	 @HLIN_SCOL
@HASK_SROW equ	 @HLIN_SROW

	 public  W_HASK
W_HASK	 W_STR	 <@HASK_SROW, @HASK_SCOL, @HASK_NROW, @HASK_NCOL>

	 public  W_HSCR
W_HSCR	 W_STR	 <@HSCR_SROW, @HSCR_SCOL, @HSCR_NROW, @HSCR_NCOL>

	 public  W_HTTL
W_HTTL	 W_STR	 <@HTTL_SROW, @HTTL_SCOL, @HTTL_NROW, @HTTL_NCOL>

@HSCR_SROW equ	 1
@HSCR_SCOL equ	 2

@HSCR_NROW equ	 (@NROWS - 1) - (@HSCR_SROW + 2)
@HSCR_NCOL equ	 (@NCOLS - 1) - (@HSCR_SCOL + 2)

@HTTL_SROW equ	 @HSCR_SROW + 1 	; Skip one row to the title
@HTTL_SCOL equ	 @HSCR_SCOL + 1 	; Indent one col from the left
@HTTL_NROW equ	 1
@HTTL_NCOL equ	 @HSCR_NCOL - (1+3)	; Indent 1 for a space, 3 for elevator

	 public  @HTXT_SROW,@HTXT_SCOL,@HTXT_NCOL,@HTXT_NROW
@HTXT_SROW equ	 @HTTL_SROW + 1 	; Skip one row to the text
@HTXT_SCOL equ	 @HTTL_SCOL + 0
@HTXT_NROW equ	 (@HSCR_NROW - 2) - @HTTL_NROW ; Indent one row from top and
					; bottom, less # rows in title
@HTXT_NCOL equ	 @HTTL_NCOL + 0

	 public  W_HELEV
W_HELEV  W_STR	 <@HELEV_SROW, @HELEV_SCOL, @HELEV_NROW, 1>

	 public  @HELEV_SROW,@HELEV_NROW
@HELEV_SROW equ  @HTXT_SROW + 0
@HELEV_SCOL equ  @HTXT_SCOL + @HTXT_NCOL + 1
@HELEV_NROW equ  @HTXT_NROW + 0

	 public  MSG_HELEV
MSG_HELEV db	 '',(@HELEV_NROW-2) dup ('±'),''

	 public  W_HEBOX
	 align	 2
W_HEBOX  W_STR	 <?, @HELEV_SCOL, 1, 1>

DATA	 ends			; End DATA segment


KEYSEG	 segment use32 word public 'data' ; Start KEYSEG segment
	 assume  ds:DGROUP

	public	@SWAT_HLP_KEYSEG
@SWAT_HLP_KEYSEG label byte	; Mark module start in .MAP file

	 public  HLPVAL
HLPVAL	 label	 word		; First word in the table

KEYSEG	 ends			; End KEYSEG segment


ACTSEG	 segment use32 dword public 'data' ; Start ACTSEG segment
	 assume  ds:DGROUP

	public	@SWAT_HLP_ACTSEG
@SWAT_HLP_ACTSEG label byte	; Mark module start in .MAP file

	 public  HLPACT
HLPACT	 label	 dword		; First action in the table

ACTSEG	 ends			; End ACTSEG segment


	KSTMAC	ESC	, HELP_ESC
	KSTMAC	UP	, HELP_UP
	KSTMAC	XUP	, HELP_UP
	KSTMAC	SHF_UP	, HELP_UP
	KSTMAC	DN	, HELP_DN
	KSTMAC	XDN	, HELP_DN
	KSTMAC	SHF_DN	, HELP_DN
	KSTMAC	PGUP	, HELP_PGUP
	KSTMAC	XPGUP	, HELP_PGUP
	KSTMAC	PGDN	, HELP_PGDN
	KSTMAC	XPGDN	, HELP_PGDN
	KSTMAC	F3	, HELP_PREVTOP
	KSTMAC	F4	, HELP_NEXTTOP
	KSTMAC	CR	, HELP_CR
	KSTMAC	PADENTER, HELP_CR


KEYSEG	 segment use32 word public 'data' ; Start KEYSEG segment
	 assume  ds:DGROUP

NHLPVAL  equ	 ($-HLPVAL)/(type HLPVAL)

KEYSEG	 ends			; End KEYSEG segment


WTXT	 segment use32 byte public 'wdata' ; Start WTXT segment
	 assume  ds:WGROUP

	 extrn	 HELP_QKYTTL:byte
	 extrn	 HELP_NAVTTL:byte
	 extrn	 HELP_CMDTTL:byte
	 extrn	 HELP_BKMTTL:byte
	 extrn	 HELP_AFLTTL:byte
	 extrn	 HELP_SRCHTTL:byte
	 extrn	 HELP_WKDTTL:byte
; NEW TOPIC GOES HERE
;;;;;;;; extrn	 HELP_???TTL:byte

	 extrn	 HELP_QKY:byte
	 extrn	 HELP_NAV:byte
	 extrn	 HELP_CMD:byte
	 extrn	 HELP_BKM:byte
	 extrn	 HELP_AFL:byte
	 extrn	 HELP_SRCH:byte
	 extrn	 HELP_WKD:byte
; NEW TOPIC GOES HERE
;;;;;;;; extrn	 HELP_???:byte

	 extrn	 @HQKY_NROW:abs
	 extrn	 @HNAV_NROW:abs
	 extrn	 @HCMD_NROW:abs
	 extrn	 @HBKM_NROW:abs
	 extrn	 @HAFL_NROW:abs
	 extrn	 @HSRCH_NROW:abs
	 extrn	 @HWKD_NROW:abs
; NEW TOPIC GOES HERE
;;;;;;;; extrn	 @H???_NROW:abs

WTXT	 ends			; End WTXT segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	public	@SWAT_HLP_PROG
@SWAT_HLP_PROG: 		; Mark module start in .MAP file

	 extrn	 GETKEY:near
	 extrn	 CLS:near
	 extrn	 WPUT_C:near
	 extrn	 WPUT_SC:near
	 extrn	 WPUT_SA:near
	 extrn	 WPUT_CSA:near
	 extrn	 WPUT_SHD1:near

	 NPPROC  DISP_HELP -- Display Help Screen
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the help screen menu

This routine runs in Protected Mode.

|

	 pushad 		; Save all EGP registers

; Ensure the help tables have been initialized

	 test	 LCL_FLAG,@LCL_WINTAB ; Izit initialized?
	 jz	 near ptr DISP_HELP_ERR ; Jump if not

; Display the help menu screen

HELP_START:
	 push	 eax		; Save in case we're redisplaying topics

	 mov	 al,HLPATTR	; Get help attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:MSG_HELP ; Pass address of local buffer
	 push	 offset ds:W_HELP ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

; Display a shadow below and to the right of the help screen

	 push	 offset ds:W_HELP ; Pass address of window descriptor
	 call	 WPUT_SHD1	; Display a type 1 shadow

; Display the menu choices in a separate color

	 mov	 al,HLPBATTR	; Get background help line attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_HASK ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute

	 pop	 eax		; Restore key code if redisplaying topics
HELP_NEXT:
	 test	 HLP_FLAG,@HLP_ACT ; Is a subtopic being displayed?
	 jnz	 short @F	; Jump if so

	 push	 eax		; Save (in case it's a key code)

	 mov	 al,HLPAATTR	; Get active help line attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_HLIN ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute

	 pop	 eax		; Restore key code
@@:
	 call	 GETKEY 	; Wait for keystroke, return in AX
HELP_NEXTKEY:
	 lea	 edi,HLPVAL	; ES:EDI ==> valid keys
	 mov	 ecx,NHLPVAL	; # valid keys
   repne scas	 HLPVAL[edi]	; Search for it
	 jne	 short HELP_NEXT ; Jump if not found

	 test	 HLP_FLAG,@HLP_ACT ; Is a subtopic being displayed?
	 jnz	 short @F	; Jump if so

	 mov	 al,HLPBATTR	; Get background help line attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_HLIN ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute
@@:
	 sub	 edi,(type HLPVAL) + offset es:HLPVAL ; Convert to origin-0
LOG2 LOG2@HLPVAL,<type HLPVAL>
	 shr	 edi,LOG2@HLPVAL ; Convert to item count

	 jmp	 HLPACT[edi*(type HLPACT)] ; Take appropriate action


HELP_PGUP:
	 test	 HLP_FLAG,@HLP_ACT ; Is a subtopic being displayed?
	 jz	 short HELP_NEXT ; Jump if not

	 mov	 esi,HLPIND	; Get the current topic index

	 sub	 HTOPIND[esi*(type HTOPIND)],@HTXT_NROW ; Skip to previous page
	 jnc	 short @F	; Jump if not below the top

	 mov	 HTOPIND[esi*(type HTOPIND)],0	; Back to the top
@@:
	 jmp	 HELP_TOPIC	; Join common code


HELP_PGDN:
	 test	 HLP_FLAG,@HLP_ACT ; Is a subtopic being displayed?
	 jz	 near ptr HELP_NEXT ; Jump if not

	 mov	 esi,HLPIND	; Get the current topic index

	 add	 HTOPIND[esi*(type HTOPIND)],@HTXT_NROW ; Skip to the next page

	 jmp	 short HELP_DNCOM ; Join common code


HELP_UP:
	 test	 HLP_FLAG,@HLP_ACT ; Is a subtopic being displayed?
	 jz	 short HELP_UP1 ; Jump if not

	 mov	 esi,HLPIND	; Get the current topic index

	 sub	 HTOPIND[esi*(type HTOPIND)],1	; Skip to previous line
	 jnc	 short @F	; Jump if not below the top

	 mov	 HTOPIND[esi*(type HTOPIND)],0	; Back to the top
@@:
	 jmp	 HELP_TOPIC	; Join common code

HELP_UP1:
	 dec	 HLPIND 	; Skip to previous row
	 jns	 short @F	; Jump if no wrap

	 mov	 HLPIND,@HLIN_LEN - 1 ; Wrap to the end
@@:
	 jmp	 short HELP_COM ; Join common code


HELP_DN:
	 test	 HLP_FLAG,@HLP_ACT ; Is a subtopic being displayed?
	 jz	 short HELP_DN1 ; Jump if not

	 mov	 esi,HLPIND	; Get the current topic index

	 inc	 HTOPIND[esi*(type HTOPIND)] ; Skip to next row
HELP_DNCOM:
	 imul	 ebx,HLPIND,type W_STR ; Get index into ARR_W_HTOP
	 lea	 ebx,ARR_W_HTOP[ebx] ; Get offset of window descriptor

	 movzx	 eax,DGROUP:[ebx].NROW ; Get total # rows

	 sub	 eax,@HTXT_NROW ; Less a page's worth of lines
	 jae	 short @F	; Jump if it's within range

	 xor	 eax,eax	; Use maximum index
@@:

; AX has the maximum valid index

	 cmp	 eax,HTOPIND[esi*(type HTOPIND)] ; Izit valid?
	 jae	 short @F	; Jump if so

	 mov	 HTOPIND[esi*(type HTOPIND)],eax ; Save as maximum index
@@:
	 jmp	 HELP_TOPIC	; Join common code

HELP_DN1:
	 inc	 HLPIND 	; Skip to next row

	 cmp	 HLPIND,@HLIN_LEN - 1 ; Izit above the end?
	 jbe	 short @F	; Jump if no wrap

	 mov	 HLPIND,0	; Wrap to the start
@@:
HELP_COM:
	 mov	 eax,@HLIN_SROW ; Wrap to the start
	 add	 eax,HLPIND	; Plus current index
	 mov	 W_HLIN.SROW,ax ; Save as new starting row

	 jmp	 HELP_NEXT	; Go around again


; Display the next help topic

HELP_NEXTTOP:
	 test	 HLP_FLAG,@HLP_ACT ; Is a subtopic being displayed?
	 jz	 near ptr HELP_NEXT ; Jump if not

	 inc	 HLPIND 	; Skip to next row

	 cmp	 HLPIND,@HLIN_LEN - 1 ; Izit above the end?
	 jbe	 short @F	; Jump if no wrap

	 mov	 HLPIND,0	; Wrap to the start
@@:
	 jmp	 short HELP_TOPCOM ; Join common code


; Display the previous help topic

HELP_PREVTOP:
	 test	 HLP_FLAG,@HLP_ACT ; Is a subtopic being displayed?
	 jz	 near ptr HELP_NEXT ; Jump if not

	 dec	 HLPIND 	; Skip to previous row
	 jns	 short @F	; Jump if no wrap

	 mov	 HLPIND,@HLIN_LEN - 1 ; Wrap to the end
@@:
HELP_TOPCOM:
	 mov	 eax,@HLIN_SROW ; Wrap to the start
	 add	 eax,HLPIND	; Plus current index
	 mov	 W_HLIN.SROW,ax ; Save as new starting row

	 jmp	 short HELP_TOPIC ; Join common code


; Display the chosen help screen

HELP_CR:
	 test	 HLP_FLAG,@HLP_ACT ; Is a subtopic being displayed?
	 jnz	 near ptr HELP_NEXT ; Jump if so

	 call	 CLS		; Display a clear screen

	 mov	 al,HLPATTR	; Get help attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_HSCR ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute

; Display a shadow below and to the right of the help screen

	 push	 offset ds:W_HSCR ; Pass address of window descriptor
	 call	 WPUT_SHD1	; Display a type 1 shadow

; Display the help screen keys

	 mov	 al,HKEYATTR	; Get help key attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:MSG_HKEY ; Pass address of local buffer
	 push	 offset ds:W_HKEY ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

; Display the help topic screen

HELP_TOPIC:

; Display the help topic title

	 mov	 ebx,HLPIND	; Get index into help topic title ptrs
	 mov	 ebx,PHTOPTTL[ebx*(type PHTOPTTL)] ; Get offset to topic in WGROUP
	 add	 ebx,WINBASE	; Plus offset in DGROUP of WGROUP

	 mov	 al,HTTLATTR	; Get help title attribute
	 push	 ax		; Pass attribute to smear
	 push	 ebx		; Pass address of local buffer
	 push	 offset ds:W_HTTL ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

; Display the help topic text

	 imul	 ebx,HLPIND,type W_STR ; Get index into ARR_W_HTOP
	 lea	 ebx,ARR_W_HTOP[ebx] ; Get offset of window descriptor

	 mov	 esi,HLPIND	; Get the current topic index

	 mov	 ecx,HTOPIND[esi*(type HTOPIND)] ; Get current help topic index
	 imul	 eax,ecx,@HTXT_NCOL+1 ; Skip over leading rows
	 add	 eax,HLPTOPIC[esi*(type HLPTOPIC)] ; Plus address of local buffer
	 add	 eax,WINBASE	; Plus offset in DGROUP of WGROUP

	 REGSAVE <DGROUP:[ebx].SROW,DGROUP:[ebx].NROW> ; Save starting & # rows

	 sub	 cx,DGROUP:[ebx].NROW ; Less maximum # rows in text
	 neg	 cx		; Negate to get maximum # rows

	 cmp	 cx,@HTXT_NROW	; Izit within the screen size?
	 jbe	 short @F	; Jump if so

	 mov	 cx,@HTXT_NROW	; Use the maximum
@@:
	 mov	 DGROUP:[ebx].NROW,cx ; Save as # rows

; Display each line using the specified color number
; By convention, the color number is 0 for the default

	 REGSAVE <ecx,edx,esi,DGROUP:[ebx].SROW,DGROUP:[ebx].NROW> ; Save for a moment

	 mov	 ecx,1		; Output one row at a time
	 xchg	 cx,DGROUP:[ebx].NROW ; Swap with actual # rows

	 movzx	 edx,DGROUP:[ebx].NCOL ; Get # cols in text
HELP_TOPIC_NXTROW:
	 movzx	 esi,DGROUP:[eax].LO ; Get the color #
	 movzx	 si,HLPATTR[esi] ; Get the color
	 inc	 eax		; Skip over the color #

	 push	 si		; Pass the color attribute
	 push	 eax		; Pass address of local buffer
	 push	 ebx		; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

	 inc	 DGROUP:[ebx].SROW ; Skip to the next starting row
HELP_TOPIC_LOOP:
	 add	 eax,edx	; Skip to the next row

	 loop	 HELP_TOPIC_NXTROW ; Jump if more rows to display

	 REGREST <DGROUP:[ebx].NROW,DGROUP:[ebx].SROW,esi,edx,ecx> ; Restore

; Clear to the end of the help text screen

	 add	 DGROUP:[ebx].SROW,cx ; Skip to the next row

	 mov	 ax,@HTXT_NROW	; Get maximum # rows on the screen
	 sub	 ax,cx		; Less # rows already displayed
	 mov	 DGROUP:[ebx].NROW,ax ; Save as # rows

	 mov	 al,' '         ; Smear a blank
	 push	 ax		; Pass the character to smear
	 push	 ebx		; Pass address of window descriptor
	 call	 WPUT_SC	; Smear the character

	 REGREST <DGROUP:[ebx].NROW,DGROUP:[ebx].SROW> ; Restore

; Display the elevator if valid

	 cmp	 DGROUP:[ebx].NROW,@HTXT_NROW ; More rows than fit on screen?
	 ja	 short @F	; Jump if so

	 mov	 al,' '         ; Smear a blank
	 push	 ax		; Pass the character to smear
	 push	 offset ds:W_HELEV ; Pass address of window descriptor
	 call	 WPUT_SC	; Smear the character

	 jmp	 short HELP_CR_END ; Join common code

@@:
	 push	 offset ds:MSG_HELEV ; Pass address of local buffer
	 push	 offset ds:W_HELEV ; Pass address of window descriptor
	 call	 WPUT_C 	; Output the characters

COMMENT|

Output the elevator box

Calculate a number between 0 and @HELEV_NROW-3 which
represents approximately where we are in the text display.
This calculation is

(@HELEV_NROW - 3) * HTOPIND[esi*(type HTOPIND)] / (DGROUP:[ebx].NROW - @HTXT_NROW)

|

	 imul	 eax,HTOPIND[esi*(type HTOPIND)],@HELEV_NROW-3 ; Get 1st multiplier
	 xor	 edx,edx	; Zero to use as dword
	 movzx	 ecx,DGROUP:[ebx].NROW ; Get total # rows
	 sub	 ecx,@HTXT_NROW ; Less # rows that fit on screen
	 div	 ecx		; Divide to get value in AX

	 add	 eax,@HELEV_SROW+1 ; Plus starting row
	 mov	 W_HEBOX.SROW,ax ; Save as starting row

	 mov	 al,'²'         ; Smear a half-tone
	 push	 ax		; Pass the character to smear
	 push	 offset ds:W_HEBOX ; Pass address of window descriptor
	 call	 WPUT_SC	; Smear the character
HELP_CR_END:
	 or	 HLP_FLAG,@HLP_ACT ; Mark as subtopic being displayed

	 jmp	 HELP_NEXT	; Go around again


HELP_ESC:

; If we're displaying a help topic, go back and display the
; help menu.  Otherwise, just exit.

	 btr	 HLP_FLAG,$HLP_ACT ; Mark as inactive
	 jnc	 short DISP_HELP_EXIT ; Jump if done

;;;;;;;; call	 DISP_SCRN	; Display the new screen
;;;;;;;; call	 DISP_ACTIV	; Display active elements

	 jmp	 HELP_START	; Display the help menu again

DISP_HELP_ERR:
	 mov	 MSGOFF,offset DGROUP:INITERR ; Save offset of error message
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display
DISP_HELP_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_HELP endp			; End DISP_HELP procedure

PROG	 ends			; End PROG segment

	 MEND			; End SWAT_HLP module
