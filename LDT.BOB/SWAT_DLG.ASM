;' $Header$
	title	SWAT_DLG -- 386SWAT Dialog Display Functions
	page	58,122
	name	SWAT_DLG

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1998-1999 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, August 1998.

Modifications by:  None.

|
.386
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include ASCII.INC
	include ALLMEM.INC
	include DEBUGSYS.INC
	include OPCODES.INC

	include WKD.INC
	include WINUSER.INC
	include SWAT_CMD.INC
	include SWAT_COM.INC
	include SWAT_DLG.INC
	include SWAT_MOD.INC
	include SWAT_SEG.INC
	include SWATVXD.INC
.list

DATA16	segment use32 dword public 'data' ; Start DATA16 segment
	assume	ds:DGROUP

;;;;;;; extrn	SWATINFO:tbyte
;;;;;;; include SWAT_INF.INC
;;;;;;;
	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	extrn	SWATDATA:dword
	extrn	DEFATTR:byte
	extrn	TTLATTR:byte

;;;;;;; extrn	EnterVMM:fword
;;;;;;; extrn	ExitVMM:fword
;;;;;;;
DATA16	ends			; End DATA16 segment


DATA	segment use32 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	@SWAT_DLG_DATA
@SWAT_DLG_DATA label byte	; Mark module start in .MAP file

;;;;;;; extrn	COMMON:tbyte
;;;;;;; include SWAT_FIL.INC
;;;;;;;
;;;;;;; extrn	COMSTK_FVEC:fword
;;;;;;;
	extrn	OUT_SCRN:byte
	extrn	OUT_FLAG:byte
	extrn	SCROFF:dword
	extrn	DLGNDX:dword
	extrn	DSP_STATE:byte
	extrn	DSP_STAT2:byte
	extrn	MSGOFF:dword
	extrn	SYNTERR:byte
;;;;;;; extrn	NOWINERR:byte

	public	DLGMODE,DLGSEL,DLGOFF,DLGBASE,DLGMASK
DLGMODE dw	@ADDR_SEP	; Dialog mode (default = PM)
DLGSEL	dw	?		; Dialog selector
DLGOFF	dd	?		; Dialog offset
DLGBASE dd	?		; Dialog base
DLGMASK dd	0000FFFFh	; Dialog mask (32 or 16 bits)

	public	DLG_FVEC
DLG_FVEC df	?		; Address save area
	dw	?		; For alignment

	public	OLDDLGSTK_FVEC
OLDDLGSTK_FVEC df ?		; Save area for stack
	dw	?		; For alignment

	public	CTL_COUNT,DLGTYPE
CTL_COUNT dd	?		; Count of # controls displayed
DLGTYPE db	@DLGW		; Dialog type:	@DLGA or @DLGW

	public	DLGHDR_STYLEHI,DLGHDR_STYLELO,DLGHDR_EXTSTYLE
	public	DLGHDR_NONE
DLGHDR_STYLEHI db 'Style = ',0
DLGHDR_STYLELO db '        ',0
DLGHDR_EXTSTYLE db 'Extended Style = ',0
DLGHDR_NONE db	'(none)',0

	public	DLGHDR0
	public	DLGHDR1A,DLGHDR1W
	public	DLGHDR2
	public	DLGHDR3A,DLGHDR3W
	public	DLGHDR4
	public	DLGHDR5A,DLGHDR5W
	public	DLGHDR6A,DLGHDR6W
	public	DLGHDR7A,DLGHDR7W,DLGHDR7X
	public	DLGHDR8A,DLGHDR8W,DLGHDR8X
	public	DLGHDR9A,DLGHDR9W
	public	DLGHDR10
	public	DLGHDR11A,DLGHDR11W
	public	DLGHDR12,DLGHDR13
	public	DLGHDR14X
	public	DLGHDR15A,DLGHDR15W
DLGHDR0 db	'%04hX|%08lX -- Dialog Display',CR,LF,0
DLGHDR1A  db	'# controls = %tu, x = %hu, y = %hu, cx = %hu, cy = %hu',CR,LF,0
DLGHDR1W  db	'# controls = %hu, x = %hu, y = %hu, cx = %hu, cy = %hu',CR,LF,0
DLGHDR1X equ	DLGHDR1W
DLGHDR2   db	'Version = %04hu, Signature = %04hX, HelpID = %08lX',CR,LF,0
DLGHDR3A  db	'Menu name = <%Fs>',CR,LF,0
DLGHDR3W  db	'Menu name = <%FS>',CR,LF,0
DLGHDR3X equ	DLGHDR3W
DLGHDR4   db	'Menu # = %04hX',CR,LF,0
DLGHDR5A  db	'Class name = <%Fs>',CR,LF,0
DLGHDR5W  db	'Class name = <%FS>',CR,LF,0
DLGHDR5X equ	DLGHDR5W
DLGHDR6A  db	'Caption = <%Fs>',CR,LF,0
DLGHDR6W  db	'Caption = <%FS>',CR,LF,0
DLGHDR6X equ	DLGHDR6W
DLGHDR7A  db	'Point size = %hu',0
DLGHDR7W  equ	DLGHDR7A
DLGHDR7X  db	'Point size = %hu, Weight = %hu, Italic = %hu',0
DLGHDRFA  db	', Font = <%Fs>',CR,LF,0
DLGHDRFW  db	', Font = <%FS>',CR,LF,0
DLGHDRFX  equ	DLGHDRFW

@CTL_IND equ   <'    '>         ; Indent for control text

DLGHDR8A  db	@CTL_IND,'x = %hu, y = %hu, cx = %hu, cy = %hu, ID = %hu',CR,LF,0
DLGHDR8W equ	DLGHDR8A
DLGHDR8X  db	@CTL_IND,'x = %hu, y = %hu, cx = %hu, cy = %hu, ID = %lu',CR,LF,0
DLGHDR_CTL db	'%2.2lu> ',0
DLGHDR9A  db	@CTL_IND,'Class name = <%Fs>',CR,LF,0
DLGHDR9W  db	@CTL_IND,'Class name = <%FS>',CR,LF,0
DLGHDR9X  equ	DLGHDR9W
DLGHDR10  db	@CTL_IND,'Resource ID = %hu',CR,LF,0
DLGHDR11A db	@CTL_IND,'Control text = <%Fs>',CR,LF,0
DLGHDR11W db	@CTL_IND,'Control text = <%FS>',CR,LF,0
DLGHDR11X equ	DLGHDR11W
DLGHDR12  db	@CTL_IND,'Extra bytes = ',0
DLGHDR13  db	'%02X ',0
DLGHDR14X db	@CTL_IND,'Help ID = %08lX',CR,LF,0
DLGHDR15A db	@CTL_IND,'User class = <%Fs>',CR,LF,0
DLGHDR15W db	@CTL_IND,'User class = <%FS>',CR,LF,0
DLGHDR15X equ	DLGHDR15W
DLGHDR_CRLF db	CR,LF,0

	public	DLGCTLIND
DLGCTLIND db	@CTL_IND,0

	public	CTLBUTTON,CTLEDIT,CTLSTATIC,CTLLBOX,CTLSBAR,CTLCBOX
CTLBUTTON db	@CTL_IND,'Button = ',0
@CTL_BSLEN equ	$-CTLBUTTON-1	; Length of the control name
CTLEDIT   db	@CTL_IND,'Edit = ',0
@CTL_ESLEN equ	$-CTLEDIT-1	; Length of the control name
CTLSTATIC db	@CTL_IND,'Static = ',0
@CTL_SSLEN equ	$-CTLSTATIC-1	; Length of the control name
CTLLBOX   db	@CTL_IND,'Listbox = ',0
@CTL_LBSLEN equ $-CTLLBOX-1	; Length of the control name
CTLSBAR   db	@CTL_IND,'Scrollbar = ',0
@CTL_SBSLEN equ $-CTLSBAR-1	; Length of the control name
CTLCBOX   db	@CTL_IND,'Combobox = ',0
@CTL_CBSLEN equ $-CTLCBOX-1	; Length of the control name

	public	DLGTEMP
DLGTEMP db	' '
DLGTEMP1 db	'xxxxxxxx',0


STYLE_STR struc

STYLE_VAL dd	?		; Value
STYLE_TXT dd	?		; Offset in DGROUP of matching text string

STYLE_STR ends

STYLE_MAC macro VAL,TXT
	local	L1

TEXT	segment use32 byte public 'data' ; Start TEXT segment

L1	db	TXT," ",0       ; Define text

TEXT	ends			; End TEXT segment

	STYLE_STR <VAL,offset DGROUP:L1>

	endm			; STYLE_MAC

	align	4		; Ensure dword-aligned

	public	STYLEHI_TAB
STYLEHI_TAB label tbyte
	STYLE_MAC WS_POPUP	 , "WS_POPUP"
	STYLE_MAC WS_CHILD	 , "WS_CHILD"
	STYLE_MAC WS_MINIMIZE	 , "WS_MINIMIZE"
	STYLE_MAC WS_VISIBLE	 , "WS_VISIBLE"
	STYLE_MAC WS_DISABLED	 , "WS_DISABLED"
	STYLE_MAC WS_CLIPSIBLINGS, "WS_CLIPSIBLINGS"
	STYLE_MAC WS_CLIPCHILDREN, "WS_CLIPCHILDREN"
	STYLE_MAC WS_MAXIMIZE	 , "WS_MAXIMIZE"
	STYLE_MAC WS_CAPTION	 , "WS_CAPTION"
	STYLE_MAC WS_BORDER	 , "WS_BORDER"
	STYLE_MAC WS_DLGFRAME	 , "WS_DLGFRAME"
	STYLE_MAC WS_VSCROLL	 , "WS_VSCROLL"
	STYLE_MAC WS_HSCROLL	 , "WS_HSCROLL"
	STYLE_MAC WS_SYSMENU	 , "WS_SYSMENU"
	STYLE_MAC WS_THICKFRAME  , "WS_THICKFRAME"
	STYLE_MAC WS_GROUP	 , "WS_GROUP"
	STYLE_MAC WS_TABSTOP	 , "WS_TABSTOP"
	STYLE_MAC WS_MINIMIZEBOX , "WS_MINIMIZEBOX"
	STYLE_MAC WS_MAXIMIZEBOX , "WS_MAXIMIZEBOX"
@STYLEHI_TAB equ ($-STYLEHI_TAB)/(type STYLE_STR)

	public	STYLELO_TAB
STYLELO_TAB label tbyte
	STYLE_MAC DS_ABSALIGN	  , "DS_ABSALIGN"
	STYLE_MAC DS_SYSMODAL	  , "DS_SYSMODAL"
	STYLE_MAC DS_LOCALEDIT	  , "DS_LOCALEDIT"
	STYLE_MAC DS_SETFONT	  , "DS_SETFONT"
	STYLE_MAC DS_MODALFRAME   , "DS_MODALFRAME"
	STYLE_MAC DS_NOIDLEMSG	  , "DS_NOIDLEMSG"
	STYLE_MAC DS_3DLOOK	  , "DS_3DLOOK"
	STYLE_MAC DS_FIXEDSYS	  , "DS_FIXEDSYS"
	STYLE_MAC DS_NOFAILCREATE , "DS_NOFAILCREATE"
	STYLE_MAC DS_SETFOREGROUND, "DS_SETFOREGROUND"
	STYLE_MAC DS_CONTROL	  , "DS_CONTROL"
	STYLE_MAC DS_CENTER	  , "DS_CENTER"
	STYLE_MAC DS_CENTERMOUSE  , "DS_CENTERMOUSE"
	STYLE_MAC DS_CONTEXTHELP  , "DS_CONTEXTHELP"
@STYLELO_TAB equ ($-STYLELO_TAB)/(type STYLE_STR)

	public	EXTSTYLE_TAB
EXTSTYLE_TAB label tbyte
	STYLE_MAC WS_EX_DLGMODALFRAME , "WS_EX_DLGMODALFRAME"
	STYLE_MAC WS_EX_NOPARENTNOTIFY, "WS_EX_NOPARENTNOTIFY"
	STYLE_MAC WS_EX_TOPMOST       , "WS_EX_TOPMOST"
	STYLE_MAC WS_EX_ACCEPTFILES   , "WS_EX_ACCEPTFILES"
	STYLE_MAC WS_EX_TRANSPARENT   , "WS_EX_TRANSPARENT"
	STYLE_MAC WS_EX_MDICHILD      , "WS_EX_MDICHILD"
	STYLE_MAC WS_EX_TOOLWINDOW    , "WS_EX_TOOLWINDOW"
	STYLE_MAC WS_EX_WINDOWEDGE    , "WS_EX_WINDOWEDGE"
	STYLE_MAC WS_EX_CLIENTEDGE    , "WS_EX_CLIENTEDGE"
	STYLE_MAC WS_EX_CONTEXTHELP   , "WS_EX_CONTEXTHELP"
	STYLE_MAC WS_EX_RIGHT	      , "WS_EX_RIGHT"
	STYLE_MAC WS_EX_LEFT	      , "WS_EX_LEFT"
	STYLE_MAC WS_EX_RTLREADING    , "WS_EX_RTLREADING"
	STYLE_MAC WS_EX_LTRREADING    , "WS_EX_LTRREADING"
	STYLE_MAC WS_EX_LEFTSCROLLBAR , "WS_EX_LEFTSCROLLBAR"
	STYLE_MAC WS_EX_RIGHTSCROLLBAR, "WS_EX_RIGHTSCROLLBAR"
	STYLE_MAC WS_EX_CONTROLPARENT , "WS_EX_CONTROLPARENT"
	STYLE_MAC WS_EX_STATICEDGE    , "WS_EX_STATICEDGE"
	STYLE_MAC WS_EX_APPWINDOW     , "WS_EX_APPWINDOW"
@EXTSTYLE_TAB equ ($-EXTSTYLE_TAB)/(type STYLE_STR)

	public	BS_LST
BS_LST	label	tbyte		; 80
	STYLE_MAC BS_PUSHBUTTON     , "BS_PUSHBUTTON"           ; 0000
	STYLE_MAC BS_DEFPUSHBUTTON  , "BS_DEFPUSHBUTTON"        ; 0001
	STYLE_MAC BS_CHECKBOX	    , "BS_CHECKBOX"             ; 0002
	STYLE_MAC BS_AUTOCHECKBOX   , "BS_AUTOCHECKBOX"         ; 0003
	STYLE_MAC BS_RADIOBUTTON    , "BS_RADIOBUTTON"          ; 0004
	STYLE_MAC BS_3STATE	    , "BS_3STATE"               ; 0005
	STYLE_MAC BS_AUTO3STATE     , "BS_AUTO3STATE"           ; 0006
	STYLE_MAC BS_GROUPBOX	    , "BS_GROUPBOX"             ; 0007
	STYLE_MAC BS_USERBUTTON     , "BS_USERBUTTON"           ; 0008
	STYLE_MAC BS_AUTORADIOBUTTON, "BS_AUTORADIOBUTTON"      ; 0009
	STYLE_MAC 000Ah 	    , "BS_000A"                 ; 000A
	STYLE_MAC BS_OWNERDRAW	    , "BS_OWNERDRAW"            ; 000B
	STYLE_MAC 000Ch 	    , "BS_000C"                 ; 000C
	STYLE_MAC 000Dh 	    , "BS_000D"                 ; 000D
	STYLE_MAC 000Eh 	    , "BS_000E"                 ; 000E
	STYLE_MAC 000Fh 	    , "BS_000F"                 ; 000F
@BS_LST equ	($-BS_LST)/(type STYLE_STR)
@BS_TYPMSK equ	000Fh		; Type mask

	public	BS_TAB
BS_TAB	label	tbyte		; 80
;;;;;;; STYLE_MAC BS_TEXT     , "BS_TEXT"
	STYLE_MAC BS_LEFTTEXT , "BS_LEFTTEXT"
	STYLE_MAC BS_ICON     , "BS_ICON"
	STYLE_MAC BS_BITMAP   , "BS_BITMAP"
	STYLE_MAC BS_CENTER   , "BS_CENTER"
	STYLE_MAC BS_LEFT     , "BS_LEFT"
	STYLE_MAC BS_RIGHT    , "BS_RIGHT"
	STYLE_MAC BS_VCENTER  , "BS_VCENTER"
	STYLE_MAC BS_TOP      , "BS_TOP"
	STYLE_MAC BS_BOTTOM   , "BS_BOTTOM"
	STYLE_MAC BS_PUSHLIKE , "BS_PUSHLIKE"
	STYLE_MAC BS_MULTILINE, "BS_MULTILINE"
	STYLE_MAC BS_NOTIFY   , "BS_NOTIFY"
	STYLE_MAC BS_FLAT     , "BS_FLAT"
@BS_TAB equ	($-BS_TAB)/(type STYLE_STR)

	public	ES_LST
ES_LST	label	tbyte		; 81
	STYLE_MAC ES_LEFT  , "ES_LEFT"                          ; 0000
	STYLE_MAC ES_CENTER, "ES_CENTER"                        ; 0001
	STYLE_MAC ES_RIGHT , "ES_RIGHT"                         ; 0002
	STYLE_MAC 0003h    , "ES_0003"                          ; 0003
@ES_LST equ	($-ES_LST)/(type STYLE_STR)
@ES_TYPMSK equ	0003h		; Type mask

	public	ES_TAB
ES_TAB	label	tbyte		; 81
	STYLE_MAC ES_MULTILINE	, "ES_MULTILINE"
	STYLE_MAC ES_UPPERCASE	, "ES_UPPERCASE"
	STYLE_MAC ES_LOWERCASE	, "ES_LOWERCASE"
	STYLE_MAC ES_PASSWORD	, "ES_PASSWORD"
	STYLE_MAC ES_AUTOVSCROLL, "ES_AUTOVSCROLL"
	STYLE_MAC ES_AUTOHSCROLL, "ES_AUTOHSCROLL"
	STYLE_MAC ES_NOHIDESEL	, "ES_NOHIDESEL"
	STYLE_MAC ES_OEMCONVERT , "ES_OEMCONVERT"
	STYLE_MAC ES_READONLY	, "ES_READONLY"
	STYLE_MAC ES_WANTRETURN , "ES_WANTRETURN"
	STYLE_MAC ES_NUMBER	, "ES_NUMBER"
@ES_TAB equ	($-ES_TAB)/(type STYLE_STR)

	public	SS_LST
SS_LST	label	tbyte		; 82
	STYLE_MAC SS_LEFT	   , "SS_LEFT"                  ; 0000
	STYLE_MAC SS_CENTER	   , "SS_CENTER"                ; 0001
	STYLE_MAC SS_RIGHT	   , "SS_RIGHT"                 ; 0002
	STYLE_MAC SS_ICON	   , "SS_ICON"                  ; 0003
	STYLE_MAC SS_BLACKRECT	   , "SS_BLACKRECT"             ; 0004
	STYLE_MAC SS_GRAYRECT	   , "SS_GRAYRECT"              ; 0005
	STYLE_MAC SS_WHITERECT	   , "SS_WHITERECT"             ; 0006
	STYLE_MAC SS_BLACKFRAME    , "SS_BLACKFRAME"            ; 0007
	STYLE_MAC SS_GRAYFRAME	   , "SS_GRAYFRAME"             ; 0008
	STYLE_MAC SS_WHITEFRAME    , "SS_WHITEFRAME"            ; 0009
	STYLE_MAC SS_USERITEM	   , "SS_USERITEM"              ; 000A
	STYLE_MAC SS_SIMPLE	   , "SS_SIMPLE"                ; 000B
	STYLE_MAC SS_LEFTNOWORDWRAP, "SS_LEFTNOWORDWRAP"        ; 000C
	STYLE_MAC SS_OWNERDRAW	   , "SS_OWNERDRAW"             ; 000D
	STYLE_MAC SS_BITMAP	   , "SS_BITMAP"                ; 000E
	STYLE_MAC SS_ENHMETAFILE   , "SS_ENHMETAFILE"           ; 000F
	STYLE_MAC SS_ETCHEDHORZ    , "SS_ETCHEDHORZ"            ; 0010
	STYLE_MAC SS_ETCHEDVERT    , "SS_ETCHEDVERT"            ; 0011
	STYLE_MAC SS_ETCHEDFRAME   , "SS_ETCHEDFRAME"           ; 0012
	STYLE_MAC 0013h 	   , "SS_0013"                  ; 0013
	STYLE_MAC 0014h 	   , "SS_0014"                  ; 0014
	STYLE_MAC 0015h 	   , "SS_0015"                  ; 0015
	STYLE_MAC 0016h 	   , "SS_0016"                  ; 0016
	STYLE_MAC 0017h 	   , "SS_0017"                  ; 0017
	STYLE_MAC 0018h 	   , "SS_0018"                  ; 0018
	STYLE_MAC 0019h 	   , "SS_0019"                  ; 0019
	STYLE_MAC 001Ah 	   , "SS_001A"                  ; 001A
	STYLE_MAC 001Bh 	   , "SS_001B"                  ; 001B
	STYLE_MAC 001Ch 	   , "SS_001C"                  ; 001C
	STYLE_MAC 001Dh 	   , "SS_001D"                  ; 001D
	STYLE_MAC 001Eh 	   , "SS_001E"                  ; 001E
	STYLE_MAC 001Fh 	   , "SS_001F"                  ; 001F
@SS_LST equ	($-SS_LST)/(type STYLE_STR)
@SS_TYPMSK equ	001Fh		; Type mask

	public	SS_TAB
SS_TAB	label	tbyte		; 82
	STYLE_MAC SS_NOPREFIX	  , "SS_NOPREFIX"               ;
	STYLE_MAC SS_NOTIFY	  , "SS_NOTIFY"                 ;
	STYLE_MAC SS_CENTERIMAGE  , "SS_CENTERIMAGE"            ;
	STYLE_MAC SS_RIGHTJUST	  , "SS_RIGHTJUST"              ;
	STYLE_MAC SS_REALSIZEIMAGE, "SS_REALSIZEIMAGE"          ;
	STYLE_MAC SS_SUNKEN	  , "SS_SUNKEN"                 ;
@SS_TAB equ	($-SS_TAB)/(type STYLE_STR)

	public	LBS_TAB
LBS_TAB label	tbyte		; 83
	STYLE_MAC LBS_NOTIFY	       , "LBS_NOTIFY"
	STYLE_MAC LBS_SORT	       , "LBS_SORT"
	STYLE_MAC LBS_NOREDRAW	       , "LBS_NOREDRAW"
	STYLE_MAC LBS_MULTIPLESEL      , "LBS_MULTIPLESEL"
	STYLE_MAC LBS_OWNERDRAWFIXED   , "LBS_OWNERDRAWFIXED"
	STYLE_MAC LBS_OWNERDRAWVARIABLE, "LBS_OWNERDRAWVARIABLE"
	STYLE_MAC LBS_HASSTRINGS       , "LBS_HASSTRINGS"
	STYLE_MAC LBS_USETABSTOPS      , "LBS_USETABSTOPS"
	STYLE_MAC LBS_NOINTEGRALHEIGHT , "LBS_NOINTEGRALHEIGHT"
	STYLE_MAC LBS_MULTICOLUMN      , "LBS_MULTICOLUMN"
	STYLE_MAC LBS_WANTKEYBOARDINPUT, "LBS_WANTKEYBOARDINPUT"
	STYLE_MAC LBS_EXTENDEDSEL      , "LBS_EXTENDEDSEL"
	STYLE_MAC LBS_DISABLENOSCROLL  , "LBS_DISABLENOSCROLL"
	STYLE_MAC LBS_NODATA	       , "LBS_NODATA"
	STYLE_MAC LBS_NOSEL	       , "LBS_NOSEL"
@LBS_TAB equ	($-LBS_TAB)/(type STYLE_STR)
@LBS_TYPMSK equ 0000h		; Type mask

	public	SBS_LST
SBS_LST label	tbyte		; 84
	STYLE_MAC SBS_HORZ    , "SBS_HORZ"                      ; 0000
	STYLE_MAC SBS_VERT    , "SBS_VERT"                      ; 0001
	STYLE_MAC 0002h       , "SBS_0002"                      ; 0002
	STYLE_MAC 0003h       , "SBS_0003"                      ; 0003
	STYLE_MAC 0004h       , "SBS_0004"                      ; 0004
	STYLE_MAC 0005h       , "SBS_0005"                      ; 0005
	STYLE_MAC 0006h       , "SBS_0006"                      ; 0006
	STYLE_MAC 0007h       , "SBS_0007"                      ; 0007
	STYLE_MAC SBS_SIZEBOX , "SBS_SIZEBOX"                   ; 0008
	STYLE_MAC 0009h       , "SBS_0009"                      ; 0009
	STYLE_MAC 000Ah       , "SBS_000A"                      ; 000A
	STYLE_MAC 000Bh       , "SBS_000B"                      ; 000B
	STYLE_MAC 000Ch       , "SBS_000C"                      ; 000C
	STYLE_MAC 000Dh       , "SBS_000D"                      ; 000D
	STYLE_MAC 000Eh       , "SBS_000E"                      ; 000E
	STYLE_MAC 000Fh       , "SBS_000F"                      ; 000F
	STYLE_MAC SBS_SIZEGRIP, "SBS_SIZEGRIP"                  ; 0010
	STYLE_MAC 0011h       , "SBS_0011"                      ; 0011
	STYLE_MAC 0012h       , "SBS_0012"                      ; 0012
	STYLE_MAC 0013h       , "SBS_0013"                      ; 0013
	STYLE_MAC 0014h       , "SBS_0014"                      ; 0014
	STYLE_MAC 0015h       , "SBS_0015"                      ; 0015
	STYLE_MAC 0016h       , "SBS_0016"                      ; 0016
	STYLE_MAC 0017h       , "SBS_0017"                      ; 0017
	STYLE_MAC 0018h       , "SBS_0018"                      ; 0018
	STYLE_MAC 0019h       , "SBS_0019"                      ; 0019
	STYLE_MAC 001Ah       , "SBS_001A"                      ; 001A
	STYLE_MAC 001Bh       , "SBS_001B"                      ; 001B
	STYLE_MAC 001Ch       , "SBS_001C"                      ; 001C
	STYLE_MAC 001Dh       , "SBS_001D"                      ; 001D
	STYLE_MAC 001Eh       , "SBS_001E"                      ; 001E
	STYLE_MAC 001Fh       , "SBS_001F"                      ; 001F
@SBS_LST equ	($-SBS_LST)/(type STYLE_STR)
@SBS_TYPMSK equ 001Fh		; Type mask

	public	SBS_HORZ_TAB
SBS_HORZ_TAB label tbyte	; 84
	STYLE_MAC SBS_LEFTALIGN , "SBS_LEFTALIGN"               ;
	STYLE_MAC SBS_RIGHTALIGN, "SBS_RIGHTALIGN"              ;
@SBS_HORZ_TAB equ ($-SBS_HORZ_TAB)/(type STYLE_STR)

	public	SBS_VERT_TAB
SBS_VERT_TAB label tbyte	; 84
	STYLE_MAC SBS_TOPALIGN ,   "SBS_TOPALIGN"               ;
	STYLE_MAC SBS_BOTTOMALIGN, "SBS_BOTTOMALIGN"            ;
@SBS_VERT_TAB equ ($-SBS_VERT_TAB)/(type STYLE_STR)

	public	SBS_SIZE_TAB
SBS_SIZE_TAB label tbyte	; 84
	STYLE_MAC SBS_SIZEBOXTOPLEFTALIGN ,    "SBS_SIZEBOXTOPLEFTALIGN"
	STYLE_MAC SBS_SIZEBOXBOTTOMRIGHTALIGN, "SBS_SIZEBOXBOTTOMRIGHTALIGN"
@SBS_SIZE_TAB equ ($-SBS_SIZE_TAB)/(type STYLE_STR)

SBS_GRIP_TAB  equ SBS_SIZE_TAB
@SBS_GRIP_TAB equ @SBS_SIZE_TAB

	public	CBS_LST
CBS_LST label	tbyte		; 85
	STYLE_MAC 0000h 	  , "CBS_0000"                  ; 0000
	STYLE_MAC CBS_SIMPLE	  , "CBS_SIMPLE"                ; 0001
	STYLE_MAC CBS_DROPDOWN	  , "CBS_DROPDOWN"              ; 0002
	STYLE_MAC CBS_DROPDOWNLIST, "CBS_DROPDOWNLIST"          ; 0003
	STYLE_MAC 0004h 	  , "CBS_0004"                  ; 0004
	STYLE_MAC 0005h 	  , "CBS_0005"                  ; 0005
	STYLE_MAC 0006h 	  , "CBS_0006"                  ; 0006
	STYLE_MAC 0007h 	  , "CBS_0007"                  ; 0007
	STYLE_MAC 0008h 	  , "CBS_0008"                  ; 0008
	STYLE_MAC 0009h 	  , "CBS_0009"                  ; 0009
	STYLE_MAC 000Ah 	  , "CBS_000A"                  ; 000A
	STYLE_MAC 000Bh 	  , "CBS_000B"                  ; 000B
	STYLE_MAC 000Ch 	  , "CBS_000C"                  ; 000C
	STYLE_MAC 000Dh 	  , "CBS_000D"                  ; 000D
	STYLE_MAC 000Eh 	  , "CBS_000E"                  ; 000E
	STYLE_MAC 000Fh 	  , "CBS_000F"                  ; 000F
@CBS_LST equ	($-CBS_LST)/(type STYLE_STR)
@CBS_TYPMSK equ 000Fh		; Type mask

	public	CBS_TAB
CBS_TAB label	tbyte		; 85
	STYLE_MAC CBS_OWNERDRAWFIXED   , "CBS_OWNERDRAWFIXED"   ; 0010
	STYLE_MAC CBS_OWNERDRAWVARIABLE, "CBS_OWNERDRAWVARIABLE"; 0020
	STYLE_MAC CBS_AUTOHSCROLL      , "CBS_AUTOHSCROLL"      ; 0040
	STYLE_MAC CBS_OEMCONVERT       , "CBS_OEMCONVERT"       ; 0080
	STYLE_MAC CBS_SORT	       , "CBS_SORT"             ; 0100
	STYLE_MAC CBS_HASSTRINGS       , "CBS_HASSTRINGS"       ; 0200
	STYLE_MAC CBS_NOINTEGRALHEIGHT , "CBS_NOINTEGRALHEIGHT" ; 0400
	STYLE_MAC CBS_DISABLENOSCROLL  , "CBS_DISABLENOSCROLL"  ; 0800
	STYLE_MAC CBS_UPPERCASE        , "CBS_UPPERCASE"        ; 2000
	STYLE_MAC CBS_LOWERCASE        , "CBS_LOWERCASE"        ; 4000
@CBS_TAB equ	($-CBS_TAB)/(type STYLE_STR)

	public	MSG_WS_OVERLAPPED
MSG_WS_OVERLAPPED db "WS_OVERLAPPED ",0

DATA	ends			; End DATA segment


PROG	segment use32 byte public 'prog' ; Start PROG segment
	assume	cs:PGROUP,ds:PGROUP

	public	@SWAT_DLG_PROG
@SWAT_DLG_PROG: 		; Mark module start in .MAP file

	extrn	SWATINI:tbyte
	include MAXDEV.INC

	extrn	DD2HEX:near
	extrn	StrLen:near
	extrn	StrLenW:near
	extrn	PARSE_ADDR:near
	extrn	IZITEOL:near
	extrn	CLEAR_EOL:near
	extrn	CLEAR_EOP:near
	extrn	LCL_INT41:far

	NPPROC	CMD_DLG -- Display Last Dialog Command
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display last dialog

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	pushad			; Save all EGP registers

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
;;;;;;; jz	short CMD_DLG_ERR_NOWIN ; Jump if not
;;;;;;;
	call	IZITEOL 	; Izit end-of-the-line?
	jne	short CMD_DLG_SYNTERR ; No, so that's an error

	mov	al,@DSP_DLG	; Screen state is DLG
	mov	DSP_STATE,al	; Set primary state
	mov	DSP_STAT2,al	; ... secondary ...
	or	LCL_FLAG,@LCL_REDI ; Mark as forced re-display of screen

	clc			; Indicate all went well

	jmp	short CMD_DLG_EXIT ; Join common exit code


;;;_DLG_ERR_NOWIN:
;;;;;;; mov	MSGOFF,offset DGROUP:NOWINERR ; Save offset of error message
;;;;;;;
;;;;;;; jmp    short CMD_DLG_ERR ; Join common code
;;;;;;;
CMD_DLG_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

;;;;;;; jmp	short CMD_DLG_ERR ; Join common error exit code

CMD_DLG_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_DLG_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_DLG endp		; End CMD_DLG procedure
	NPPROC	CMD_DLGA -- Display Dialog-A Command
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display dialog-A command

DLGA addr
DLG16 addr

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	mov	DLGTYPE,@DLGA	; Mark as Dialog-A format

	jmp	short CMD_DLGx_COM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_DLGA endp			; End CMD_DLGA procedure
	NPPROC	CMD_DLGW -- Display Dialog-W Command
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display dialog-W command

DLGW addr
DLG32 addr

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error
	=	1 otherwise

|

	mov	DLGTYPE,@DLGW	; Mark as Dialog-W format
CMD_DLGx_COM:
	pushad			; Save all EGP registers

;;;;;;; test	SWATINI.MD_ATTR,@MD_WIN3 ; Running under Windows?
;;;;;;; jz	near ptr CMD_DLGx_ERR_NOWIN ; Jump if not
;;;;;;;
	call	IZITEOL 	; Izit end-of-the-line?
	je	near ptr CMD_DLGx_SYNTERR ; Yes, so that's an error

	call	PARSE_ADDR	; Parse command line for an address
	jc	near ptr CMD_DLGx_ERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

; See if there's more on the line

	call	IZITEOL 	; Izit end-of-the-line?
	jne	short CMD_DLGx_SYNTERR ; No, so that's an error

	mov	DLGOFF,eax	; Save for later use

	test	cx,@ADDR_SEP	; Separator specified?
	jz	short @F	; Not this time

	mov	DLGSEL,bx	; Save for display purposes
	mov	DLGBASE,edx	; Save for later use

	and	DLGMODE,not @MODE_VM ; Mark as protected mode
	mov	DLGMASK,-1	; Use all 32 bits

	test	cx,@ADDR_PM	; Check mode
	jnz	short @F	; Jump if PM

	or	DLGMODE,@MODE_VM ; Mark as VM86 mode
	mov	DLGMASK,0000FFFFh ; Use low-order 16 bits
@@:
	mov	DLGNDX,0	; Start with the first control

	mov	al,@DSP_DLG	; Screen state is DLG
	mov	DSP_STATE,al	; Set primary state
	mov	DSP_STAT2,al	; ... secondary ...
	or	LCL_FLAG,@LCL_REDI ; Mark as forced re-display of screen

	clc			; Indicate all went well

	jmp	short CMD_DLGx_EXIT ; Join common exit code

;;;_DLGx_ERR_NOWIN:
;;;;;;; mov	MSGOFF,offset DGROUP:NOWINERR ; Save offset of error message
;;;;;;;
;;;;;;; jmp    short CMD_DLGx_ERR ; Join common code
;;;;;;;
CMD_DLGx_SYNTERR:
	mov	MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

;;;;;;; jmp	short CMD_DLGx_ERR ; Join common error exit code

CMD_DLGx_ERR:
	or	LC2_FLAG,@LC2_MSG ; Mark as message to display

	stc			; Mark as in error
CMD_DLGx_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_DLGW endp			; End CMD_DLGW procedure
	NPPROC	HDR_DLG -- Display Dialog Screen Header
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display dialog screen header

|

	REGSAVE <eax,ebx,esi,edi> ; Save registers

	mov	bl,TTLATTR	; Get title attribute
	xchg	bl,DEFATTR	; Swap with default attribute

	lea	edi,DLGSEL	; ES:EDI ==> arguments
	lea	esi,DLGHDR0	; DS:ESI ==> format string
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

;;;;;;; call	HDR_SYMBOL	; Check for symbol at starting offset
;;;;;;;
	call	CLEAR_EOL	; Clear to the end-of-the-line
	xchg	bl,DEFATTR	; Restore default attribute

	REGREST <edi,esi,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HDR_DLG endp		; End HDR_DLG procedure
;;;	    NPPROC  VERIFYMEM -- Verify And Page In Memory
;;;	    assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
;;; COMMENT|
;;;
;;; Verify and page in memory
;;;
;;; On exit:
;;;
;;; CF	    =	    0 if valid (and paged in) memory
;;;	    =	    1 if not
;;;
;;; |
;;;
;;; VRF_STR struc
;;;
;;;	    db	    (type PUSHAD_STR) dup (?) ; Caller's EGPs
;;;	    dd	    ?		    ; ...      EIP
;;; VRF_LEN dd	    ?		    ; Length of memory
;;; VRF_LA  dd	    ?		    ; Linear address ...
;;;
;;; VRF_STR ends
;;;
;;;	    pushad		    ; Prepare to address the stack
;;;	    mov     ebp,esp	    ; Hello, Mr. Stack
;;;
;;;	    REGSAVE <ds,es,fs,gs>   ; Save registers
;;;
;;;	    mov     ax,ds	    ; Copy DGROUP selector
;;;	    mov     gs,ax	    ; Address it
;;;	    assume  gs:DGROUP	    ; Tell the assembler about it
;;;
;;;	    mov     ax,COMMON.FILE_4GB ; Get all memory selector
;;;
;;;	    mov     ds,ax	    ; Address it
;;;	    assume  ds:AGROUP	    ; Tell the assembler about it
;;;
;;;	    mov     es,ax	    ; Address it
;;;	    assume  ds:AGROUP	    ; Tell the assembler about it
;;;
;;;	    mov     esi,[ebp].VRF_LA ; Get the linear address
;;;	    mov     ecx,[ebp].VRF_LEN ; Get the length in bytes
;;;
;;;	    mov     OLDDLGSTK_FVEC.FOFF,esp ; Save to restore later
;;;	    mov     OLDDLGSTK_FVEC.FSEL,ss ; ...
;;;
;;; ;Restore the original stack
;;;
;;;	    lss     esp,COMSTK_FVEC ; Switch to caller's stack
;;;	    assume  ss:nothing	    ; Tell the assembler about it
;;;
;;; COMSTK_STR struc
;;;
;;;	    dq	    ?		    ; Return CS:EIP
;;; COMSTK_EIP dd   ?		    ; Caller's EIP
;;; COMSTK_CSF dd   ?		    ; ...      CS w/filler
;;; COMSTK_EFL dd   ?		    ; ...      EFL
;;; COMSTK_ESP dd   ?		    ; ...      ESP
;;; COMSTK_SSF dd   ?		    ; ...      SS w/filler
;;; COMSTK_ESF dd   ?		    ; ...      ES ...
;;; COMSTK_DSF dd   ?		    ; ...      DS ...
;;; COMSTK_FSF dd   ?		    ; ...      FS ...
;;; COMSTK_GSF dd   ?		    ; ...      GS ...
;;;
;;; COMSTK_STR ends
;;;
;;;	    mov     ebp,esp	    ; SS:EBP ==> COMSTK_STR
;;;
;;;	    mov     edx,SWATINI.MD_DATA ; Get offset32 to data segment
;;;
;;;	    push    [ebp].COMSTK_GSF ; Pass caller's GS w/filler
;;;	    push    [ebp].COMSTK_FSF ; ...	     FS ...
;;;	    push    [ebp].COMSTK_DSF ; ...	     DS ...
;;;	    push    [ebp].COMSTK_ESF ; ...	     ES ...
;;;	    push    [ebp].COMSTK_SSF ; ...	     SS ...
;;;	    push    [ebp].COMSTK_ESP ; ...	     ESP
;;;	    push    [ebp].COMSTK_EFL ; ...	     EFL
;;;	    push    [ebp].COMSTK_CSF ; ...	     CS w/filler
;;;	    push    [ebp].COMSTK_EIP ; ...	     EIP
;;;	    call    EnterVMM	    ; Tell 'em we're coming
;;;	    assume  ds:AGROUP,es:AGROUP ; Tell the assembler about it
;;;	    assume  fs:AGROUP,gs:AGROUP ; ...
;;;
;;;	    push    SWAT_LinPageLock ; Pass parameter
;;;	    assume  ds:DGROUP	    ; Tell a white lie
;;;	    db	    @OPCOD_CS	    ; Use CS override
;;;	    call    SWATINFO[edx].SWTINF_VxD_PMAPI ; Request VxD service
;;;	    assume  ds:nothing	    ; Retract nose
;;;
;;;	    push    cs		    ; Save to create DS
;;;	    add     [esp].EDD,size DESC_STR ; Add to get next DTE
;;;	    pop     ds		    ; Restore
;;;	    assume  ds:DGROUP	    ; Tell the assembler about it
;;;
;;; ; *FIXME*
;;; ;;;;;;; call    ExitVMM	    ; Tell 'em we're leaving
;;;	    assume  ds:DGROUP	    ; Tell the assembler about it
;;;	    assume  es:DGROUP	    ; Tell the assembler about it
;;; ; *FIXME*
;;;	    lss     esp,OLDDLGSTK_FVEC ; Restore the stack
;;;	    assume  ss:nothing	    ; Tell the assembler about it
;;;
;;;	    REGREST <gs,fs,es,ds>   ; Restore
;;;	    assume  ds:DGROUP,es:nothing ; Tell the assembler about it
;;;	    assume  es:nothing,gs:nothing ; ...
;;;
;;;
;;;
;;;
;;;
;;;
;;;
;;;	    clc 		    ; Mark as valid
;;; VERIFYMEM_EXIT:
;;;	    popad		    ; Restore
;;;
;;;	    ret     2*4 	    ; Return to caller, popping arguments
;;;
;;;	    assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; VERIFYMEM endp		    ; End VERIFYMEM procedure
	NPPROC	DISP_DLG -- Display Memory in Dialog Format
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display memory in DLG format

|

	pushad			; Save all registers
	REGSAVE <OUT_SCRN.EDD,es> ; Save registers

; Calculate the address we're to display

	mov	esi,DLGBASE	; Get base address
	add	esi,DLGOFF	; Plus the offset

;;; ; Ensure the memory is valid and paged in
;;;
;;;	    push    esi 	    ; Pass the linear address
;;;	    push    4096	    ; Pass length (arbitrary number)
;;;	    call    VERIFYMEM	    ; Verify and page in memory
;;; ;;;;;;; jc	    short ...	    ; Jump if it's not valid
;;;
	mov	SCROFF,0	; Start at the top

	mov	OUT_SCRN,1	; Mark as all INT 41h output as going
				; to the main screen
	call	HDR_DLG 	; Display the screen header

	mov	eax,gs		; Set AGROUP data selector
	mov	es,eax		; Address it
	assume	es:AGROUP	; Tell the assembler about it

	cmp	DLGTYPE,@DLGW	; Izit a DLG-W Format?
	je	short DISP_DLGW ; Jump if so

; It's DLG-A format

; Display the fixed portion of the dialog header

	push	0FFFFFFFFh	; Pass bit mask for (none) testing
	push	AGROUP:[esi].DLGHDRA_Style ; Pass styles
	call	DISP_DLG_STYLE_HI ; Display the dialog style

	push	AGROUP:[esi].DLGHDRA_Style ; Pass styles
	call	DISP_DLG_STYLE_LO ; Display the dialog style

	push	esi		; Save for a moment

	lea	edi,[esi].DLGHDRA_NumItems ; ES:EDI ==> arguments
	lea	esi,DLGHDR1A	; DS:ESI ==> format string
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

	pop	esi		; Restore

; Display the optional trailing strucs

	lea	edi,AGROUP:[esi+(type DLGHDRA)] ; Skip to variable fields

; Display the optional menu

	call	DISP_DLG_MENUA	; Display it
				; Return with EDI updated
; Display the optional class name

	call	DISP_DLG_CLASSA ; Display it
				; Return with EDI updated
; Display the optional caption

	call	DISP_DLG_CAPTIONA ; Display it
				; Return with EDI updated
; Display the optional font data

	call	DISP_DLG_FONTA	; Display it
				; Return with EDI updated
	movzx	ecx,AGROUP:[esi].DLGHDRA_NumItems ; Get # controls
	lea	ebx,DISP_DLG_CTLA ; PGROUP:EBX ==> common control display routine

	jmp	DISP_DLG_COM	; Join common code


; It's DLG-W or DLG-X format

DISP_DLGW:
	cmp	AGROUP:[esi].DLGHDRX_Sign,DBHX_SIG ; Izit DLG-X format?
	je	near ptr DISP_DLGX ; Jump if so

; Display the fixed portion of the dialog header

	push	0FFFFFFFFh	; Pass bit mask for (none) testing
	push	AGROUP:[esi].DLGHDRW_Style ; Pass styles
	call	DISP_DLG_STYLE_HI ; Display the dialog style

	push	AGROUP:[esi].DLGHDRW_Style ; Pass styles
	call	DISP_DLG_STYLE_LO ; Display the dialog style

	push	AGROUP:[esi].DLGHDRW_ExtStyle ; Pass extended styles
	call	DLG_EXTSTYLE	; Display the dialog extended style

	push	esi		; Save for a moment

	lea	edi,[esi].DLGHDRW_NumItems ; ES:EDI ==> arguments
	lea	esi,DLGHDR1W	; DS:ESI ==> format string
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

	pop	esi		; Restore

; Display the optional trailing strucs

	lea	edi,AGROUP:[esi+(type DLGHDRW)] ; Skip to variable fields

; Display the optional menu

	call	DISP_DLG_MENUW	; Display it
				; Return with EDI updated
; Display the optional class name

	call	DISP_DLG_CLASSW ; Display it
				; Return with EDI updated
; Display the optional caption

	call	DISP_DLG_CAPTIONW ; Display it
				; Return with EDI updated
; Display the optional font data

	call	DISP_DLG_FONTW	; Display it
				; Return with EDI updated
	movzx	ecx,AGROUP:[esi].DLGHDRW_NumItems ; Get # controls
	lea	ebx,DISP_DLG_CTLW ; PGROUP:EBX ==> common control display routine

	jmp	DISP_DLG_COM	; Join common code


; It's DLG-X format

DISP_DLGX:

; Display the fixed portion of the dialog header

	push	esi		; Save for a moment

	lea	edi,[esi].DLGHDRX_Ver ; ES:EDI ==> arguments
	lea	esi,DLGHDR2	; DS:ESI ==> format string
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

	pop	esi		; Restore

	push	0FFFFFFFFh	; Pass bit mask for (none) testing
	push	AGROUP:[esi].DLGHDRX_Style   ; Pass styles
	call	DISP_DLG_STYLE_HI ; Display the dialog style

	push	AGROUP:[esi].DLGHDRX_Style ; Pass styles
	call	DISP_DLG_STYLE_LO ; Display the dialog style

	push	AGROUP:[esi].DLGHDRX_ExtStyle ; Pass extended styles
	call	DLG_EXTSTYLE	; Display the dialog extended style

	push	esi		; Save for a moment

	lea	edi,[esi].DLGHDRX_NumItems ; ES:EDI ==> arguments
	lea	esi,DLGHDR1X	; DS:ESI ==> format string
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

	pop	esi		; Restore

; Display the optional trailing strucs

	lea	edi,AGROUP:[esi+(type DLGHDRX)] ; Skip to variable fields

; Display the optional menu

	call	DISP_DLG_MENUW	; Display it
				; Return with EDI updated

; Display the optional class name

	call	DISP_DLG_CLASSW ; Display it,
				; Return with EDI updated
; Display the optional caption

	call	DISP_DLG_CAPTIONW ; Display it
				; Return with EDI updated
; Display the optional font data

	call	DISP_DLG_FONTX	; Display it
				; Return with EDI updated
; Display the controls

	movzx	ecx,AGROUP:[esi].DLGHDRX_NumItems ; Get # controls
	lea	ebx,DISP_DLG_CTLX ; PGROUP:EBX ==> common control display routine
DISP_DLG_COM:
	call	DISP_DLGBAR	; Display a separator

	jecxz	DISP_DLG_EXIT	; Jump if no controls
	mov	CTL_COUNT,0	; Initialize the count

; Reduce DLGNDX to within NumItems limits

	mov	eax,DLGNDX	; Get first index to display

	cmp	eax,ecx 	; Izit within limits?
	jb	short @F	; Jump if so

	mov	eax,ecx 	; Use maximum
	dec	eax		; Convert from count to index
	mov	DLGNDX,eax	; Save for next time
@@:

; Check for whether or not we should display this dialog

	cmp	eax,CTL_COUNT	; Izit to be displayed?
	seta	OUT_FLAG	; 1 = ignore, 0 = display

	call	ebx		; Display it
				; Return with EDI updated
	inc	CTL_COUNT	; Count in another one

	loop	@B		; Jump if more controls
DISP_DLG_EXIT:
	call	CLEAR_EOP	; Clear to the end of the page

	REGREST <es,OUT_SCRN.EDD> ; Restore
	assume	es:nothing	; Tell the assembler about it
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DLG endp			; End DISP_DLG procedure
	NPPROC	DISP_DLGBAR -- Display A Dialog Separator
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display a dialog separator

|

	REGSAVE <eax,ecx,edx>	; Save registers

	mov	dl,'Ä'          ; The separator
	mov	ecx,@NCOLS	; # cols on the screen
@@:
	mov	ax,@I41_OUT_CHAR ; Function code to display char in DL
	INT41			; Request WKD services

	loop	@B		; Jump if more chars to display

	REGREST <edx,ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DLGBAR endp		; End DISP_DLGBAR procedure
	NPPROC	DISP_DLG_STYLE_HI -- Display Dialog Style
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display dialog styles, high-order word

|

DISP_DLGSTYLE_HI_STR struc

	db	(type PUSHAD_STR) dup (?) ; Caller's EGP registers
	dd	?		; ...	   EIP
DISP_DLGSTYLE_HI_VAL dd ?	; The style
DISP_DLGSTYLE_HI_MSK dd ?	; Bit mask for (none) testing

DISP_DLGSTYLE_HI_STR ends

	pushad			; Save registers
	mov	ebp,esp 	; Address the stack

	lea	esi,DLGHDR_STYLEHI ; DS:ESI ==> string
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	INT41			; Request WKD services

; Do high style bits

TYPEMASK =	0C0000000h

; Handle the scratch case

	mov	edi,[ebp].DISP_DLGSTYLE_HI_VAL ; Get the style value

	test	edi,[ebp].DISP_DLGSTYLE_HI_MSK ; Izit (none) time?
	jz	near ptr DISP_DLG_STYLE_HI_NONE ; Jump if so

	test	edi,TYPEMASK	; Are any bits defined?
	jnz	short @F	; Jump if so

	push	offset DGROUP:MSG_WS_OVERLAPPED ; Pass the offset in DGROUP
	call	OUTSTR		; Display the string
@@:
	mov	ecx,@STYLEHI_TAB ; Get # entries to check
	xor	ebx,ebx 	; Initialize index into STYLE_TAB

BITMASK =	0FFFF0000h

	test	edi,BITMASK	; Any bits in this part?
	jz	near ptr DISP_DLG_STYLE_HI_EXIT ; Jump if no more bits
DISP_DLG_STYLE_HI_NEXT:
	mov	edx,STYLEHI_TAB[ebx*(type STYLE_STR)].STYLE_VAL ; Get the style value
	mov	eax,edi 	; Copy the style
	and	eax,edx 	; Isolate the value

	cmp	eax,edx 	; Izit the same?
	jne	short @F	; Jump if not

	push	STYLEHI_TAB[ebx*(type STYLE_STR)].STYLE_TXT ; Pass offset in DGROUP
	call	OUTSTR		; Display the string

	not	edx		; Complement to remove the bits
	and	edi,edx 	; Remove 'em

	test	edi,BITMASK	; Any more bits in this part?
	jz	short DISP_DLG_STYLE_HI_EXIT ; Jump if not
@@:
	inc	ebx		; Skip to next entry

	loop	DISP_DLG_STYLE_HI_NEXT ; Jump if more entries

; Display unused bits in the high-order word

	mov	eax,edi 	; Copy the style dword
	and	eax,BITMASK	; Isolate the high-order word
	jz	short DISP_DLG_STYLE_HI_EXIT ; Jump if no undisplayed bits

	push	es		; Save for a moment

	mov	bx,ds		; Get DGROUP data selector
	mov	es,bx		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	lea	edi,DLGTEMP1	; ES:EDI ==> output save area
	call	DD2HEX		; Convert EAX to ASCII hex at ES:EDI

	mov	esi,edi 	; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	INT41			; Request WKD services

	pop	es		; Restore
	assume	es:AGROUP	; Tell the assembler about it

	jmp	short DISP_DLG_STYLE_HI_EXIT ; Join common exit code

DISP_DLG_STYLE_HI_NONE:
	lea	esi,DLGHDR_NONE ; DS:ESI ==> string
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	INT41			; Request WKD services
DISP_DLG_STYLE_HI_EXIT:
	call	DISP_EOL	; End the line

	popad			; Restore

	ret	4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DLG_STYLE_HI endp		; End DISP_DLG_STYLE_HI procedure
	NPPROC	DISP_DLG_STYLE_LO -- Display Dialog Style
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display dialog styles, low-order word

|

DISP_DLGSTYLE_LO_STR struc

	db	(type PUSHAD_STR) dup (?) ; Caller's EGP registers
	dd	?		; ...	   EIP
DISP_DLGSTYLE_LO_VAL dd ?	; The style

DISP_DLGSTYLE_LO_STR ends

	pushad			; Save registers
	mov	ebp,esp 	; Address the stack

	lea	esi,DLGHDR_STYLELO ; DS:ESI ==> string
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	INT41			; Request WKD services

; Do low style bits

	mov	ecx,@STYLELO_TAB ; Get # entries to check
	xor	ebx,ebx 	; Initialize index into STYLE_TAB
	mov	edi,[ebp].DISP_DLGSTYLE_LO_VAL ; Get the style value

BITMASK =	00000FFFFh

	test	edi,BITMASK	; Any bits in this part?
	jz	short DISP_DLG_STYLE_LO_EXIT ; Jump if no more bits
DISP_DLG_STYLE_LO_NEXT:
	mov	edx,STYLELO_TAB[ebx*(type STYLE_STR)].STYLE_VAL ; Get the style value
	mov	eax,edi 	; Copy the style
	and	eax,edx 	; Isolate the value

	cmp	eax,edx 	; Izit the same?
	jne	short @F	; Jump if not

	push	STYLELO_TAB[ebx*(type STYLE_STR)].STYLE_TXT ; Pass offset in DGROUP
	call	OUTSTR		; Display the string

	not	edx		; Complement to remove the bits
	and	edi,edx 	; Remove 'em

	test	edi,BITMASK	; Any more bits in this part?
	jz	short DISP_DLG_STYLE_LO_EXIT ; Jump if no more bits
@@:
	inc	ebx		; Skip to next entry

	loop	DISP_DLG_STYLE_LO_NEXT ; Jump if more entries

; Display unused bits in the low-order word

	mov	eax,edi 	; Copy the style dword
	and	eax,BITMASK	; Isolate the high-order word
	jz	short DISP_DLG_STYLE_LO_EXIT ; Jump if no undisplayed bits

	push	es		; Save for a moment

	mov	bx,ds		; Get DGROUP data selector
	mov	es,bx		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	lea	edi,DLGTEMP1	; ES:EDI ==> output save area
	call	DD2HEX		; Convert EAX to ASCII hex at ES:EDI

	mov	esi,edi 	; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	INT41			; Request WKD services

	pop	es		; Restore
	assume	es:AGROUP	; Tell the assembler about it
DISP_DLG_STYLE_LO_EXIT:
	call	DISP_EOL	; End the line

	popad			; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DLG_STYLE_LO endp		; End DISP_DLG_STYLE_LO procedure
	NPPROC	DLG_EXTSTYLE -- Display Dialog Extended Style
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display dialog extended styles

|

DLGEXTSTYLE_STR struc

	db	(type PUSHAD_STR) DUP (?) ; Caller's EGP registers
	dd	?		; ...	   EIP
DLGEXTSTYLE_VAL dd ?		; The extended style

DLGEXTSTYLE_STR ends

	pushad			; Save registers
	mov	ebp,esp 	; Address the stack

	lea	esi,DLGHDR_EXTSTYLE ; DS:ESI ==> string
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	INT41			; Request WKD services

	mov	ecx,@EXTSTYLE_TAB ; Get # entries to check
	xor	ebx,ebx 	; Initialize index into STYLE_TAB
	mov	edi,[ebp].DLGEXTSTYLE_VAL ; Get the style value

	and	edi,edi 	; Any bits in this part?
	jz	short DLG_EXTSTYLE_NONE ; Jump if no more bits
DLG_EXTSTYLE_NEXT:
	mov	edx,EXTSTYLE_TAB[ebx*(type STYLE_STR)].STYLE_VAL ; Get the style value
	and	edx,edi 	; Isolate the value

	cmp	edi,edx 	; Izit the same?
	jne	short @F	; Jump if not

	push	EXTSTYLE_TAB[ebx*(type STYLE_STR)].STYLE_TXT ; Pass offset in DGROUP
	call	OUTSTR		; Display the string

	not	edx		; Complement to remove the bits
	and	edi,edx 	; Remove 'em

	and	edi,edi 	; Any more bits in this part?
	jz	short DLG_EXTSTYLE_EXIT ; Jump if no more bits
@@:
	inc	ebx		; Skip to next entry

	loop	DLG_EXTSTYLE_NEXT ; Jump if more entries

; Display unused bits

	mov	eax,edi 	; Copy the style dword
	and	eax,eax 	; Izit empty?
	jz	short DLG_EXTSTYLE_EXIT ; Jump if no undisplayed bits

	push	es		; Save for a moment

	mov	bx,ds		; Get DGROUP data selector
	mov	es,bx		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	lea	edi,DLGTEMP1	; ES:EDI ==> output save area
	call	DD2HEX		; Convert EAX to ASCII hex at ES:EDI

	mov	esi,edi 	; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	INT41			; Request WKD services

	pop	es		; Restore
	assume	es:AGROUP	; Tell the assembler about it

	jmp	short DLG_EXTSTYLE_EXIT ; Join common exit code

DLG_EXTSTYLE_NONE:
	lea	esi,DLGHDR_NONE ; DS:ESI ==> string
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	INT41			; Request WKD services
DLG_EXTSTYLE_EXIT:
	call	DISP_EOL	; End the line

	popad			; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DLG_EXTSTYLE endp		; End DLG_EXTSTYLE procedure
	NPPROC	OUTSTR -- Output String
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Output string

|

OUTSTR_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
OUTSTR_TXT dd	?		; Offset in DGROUP of string

OUTSTR_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,esi>	; Save registers

	mov	esi,[ebp].OUTSTR_TXT ; DS:ESI ==> string
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	INT41			; Request WKD services

	REGREST <esi,eax>	; Restore

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OUTSTR	endp			; End OUTSTR procedure
	NPPROC	OUTSTR_WRAP -- Outpyut String With Wrap
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Output string wrapping at @NCOLS as necessary

On entry:

On exit:

|

OSW_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
OSW_ASZ dd	?		; Offset in DGROUP of string to display
OSW_LEN dd	?		; Length of indent

OSW_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	REGSAVE <eax,ecx,edx,esi> ; Save registers

; Get current screen column

	mov	eax,SCROFF	; Get current screen offset
	xor	edx,edx 	; Zero to use EDX:EAX as qword
	mov	ecx,@NCOLS*2	; Characters & attributes per screen row
	div	ecx		; EAX = Current row, EDX = current col*2
	shr	edx,1		; Divide by two to get current col

; Get string length

	push	ds		; Pass string selector
	push	[ebp].OSW_ASZ	; ...	      offset
	call	StrLen		; Return with length in EAX

	add	eax,edx 	; Add to get next column

	cmp	eax,@NCOLS	; Izit too long?
	jb	short OUSTR_WRAP1 ; Jump if not

	push	offset DGROUP:DLGHDR_CRLF ; Pass the offset in DGROUP
	call	OUTSTR		; Display the string

; Display the indent

	mov	dl,' '          ; Display this
	mov	ecx,[ebp].OSW_LEN ; For this many characters
@@:
	mov	ax,@I41_OUT_CHAR ; Function code to display char in DL
	INT41			; Request WKD services

	loop	@B		; Jump if more characters to display
OUSTR_WRAP1:
	mov	esi,[ebp].OSW_ASZ ; DS:ESI ==> string
	mov	ax,@I41_OUT_STR ; Function code to display string at DS:ESI
	INT41			; Request WKD services

	REGREST <esi,edx,ecx,eax> ; Restore

	pop	ebp		; Restore

	ret	2*4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OUTSTR_WRAP	endp		; End OUTSTR_WRAP procedure
	NPPROC	DISP_EOL -- End the line
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

End the line unless it's already in column zero.

|

	REGSAVE <eax,ecx,edx>	; Save registers

	mov	eax,SCROFF	; Get current screen offset
	xor	edx,edx 	; Zero to use EDX:EAX as qword
	mov	ecx,@NCOLS*2	; Characters & attributes per screen row
	div	ecx		; EAX = Current row, EDX = current col*2

	and	edx,edx 	; Izit in column zero?
	jz	short @F	; Jump if so

	push	offset DGROUP:DLGHDR_CRLF ; Pass the offset in DGROUP
	call	OUTSTR		; Display the string
@@:
	REGREST <edx,ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_EOL endp			; End DISP_EOL procedure
	NPPROC	DISP_FSTR -- Display Far String
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display far string

On entry:

DS:ESI	==>	format string
ES:EDI	==>	string

|

	REGSAVE <eax,edi,es>	; Save registers

	mov	DLG_FVEC.FOFF,edi ; Save offset
	mov	DLG_FVEC.FSEL,es ; ...	 selector

	mov	eax,ds		; Get DGROUP data selector
	mov	es,eax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	lea	edi,DLG_FVEC	; ES:EDI ==> argument
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

	REGREST <es,edi,eax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_FSTR endp			; End DISP_FSTR procedure
	NPPROC	DISP_CTLIND -- Display Control Indent
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display control indent

|

	push	offset DGROUP:DLGCTLIND ; Pass offset in DGROUP of text string
	call	OUTSTR		; Display the string

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_CTLIND endp		; End DISP_CTLIND procedure
	NPPROC	DISP_DLG_MENUA -- Display Dialog Menu
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display dialog menu

On entry:

ES:EDI	==>	dialog class menu marker

On exit:

ES:EDI	==>	(updated)

|

	REGSAVE <eax,esi>	; Save registers

	mov	al,AGROUP:[edi] ; Get menu marker
	inc	edi		; Skip over the marker

	cmp	al,0		; Is there a menu?
	je	short DISP_DLG_MENUA_EXIT ; Jump if not

	cmp	al,-1		; Is the menu an ordinal?
	je	short DISP_DLG_MENUA1 ; Jump if so

; The menu is an ASCIIZ string

	lea	esi,DLGHDR3A	; DS:ESI ==> format string
	call	DISP_FSTR	; Display the string at ES:EDI via DS:ESI

	push	es		; Pass the selector
	push	edi		; ...	   offset
	call	StrLen		; Return with length in EAX
	lea	edi,[edi+eax+1] ; Skip over the string

	jmp	short DISP_DLG_MENUA_EXIT ; Join common code

; The menu is an ordinal

DISP_DLG_MENUA1:
	lea	esi,DLGHDR4	; DS:ESI ==> format string
				; ES:EDI ==> argument
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

	add	edi,2		; Skip over the ordinal
DISP_DLG_MENUA_EXIT:
	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DLG_MENUA endp		; End DISP_DLG_MENUA procedure
	NPPROC	DISP_DLG_MENUW -- Display Dialog Menu, Wide
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display dialog menu, wide

On entry:

ES:EDI	==>	dialog class menu marker

On exit:

ES:EDI	==>	(updated)

|

	REGSAVE <eax,esi>	; Save registers

	mov	ax,AGROUP:[edi] ; Get menu marker
	add	edi,2		; Skip over the marker

	cmp	ax,0		; Is there a menu?
	je	short DISP_DLG_MENUW_EXIT ; Jump if not

	cmp	ax,-1		; Is the menu an ordinal?
	je	short DISP_DLG_MENUW1 ; Jump if so

; The menu is a wide ASCIIZ string

	lea	esi,DLGHDR3W	; DS:ESI ==> format string
	call	DISP_FSTR	; Display the string at ES:EDI via DS:ESI

	push	es		; Pass the selector
	push	edi		; ...	   offset
	call	StrLenW 	; Return with length in EAX
	lea	edi,[edi+eax*2+2] ; Skip over the wide string

	jmp	short DISP_DLG_MENUA_EXIT ; Join common code

; The menu is an ordinal

DISP_DLG_MENUW1:
	lea	esi,DLGHDR4	; DS:ESI ==> format string
				; ES:EDI ==> argument
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

	add	edi,2		; Skip over the ordinal
DISP_DLG_MENUW_EXIT:
	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DLG_MENUW endp		; End DISP_DLG_MENUW procedure
	NPPROC	DISP_DLG_CLASSA -- Display Dialog Class Name
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display dialog class name

On entry:

ES:EDI	==>	dialog class name

On exit:

ES:EDI	==>	(updated)

|

	REGSAVE <eax,esi>	; Save registers

	cmp	AGROUP:[edi].ELO,0 ; Izit empty?
	je	short @F	; Jump if so

; The class name is an ASCIIZ string

	lea	esi,DLGHDR5A	; DS:ESI ==> format string
	call	DISP_FSTR	; Display the string at ES:EDI via DS:ESI
@@:
	push	es		; Pass the selector
	push	edi		; ...	   offset
	call	StrLen		; Return with length in EAX
	lea	edi,[edi+eax+1] ; Skip over the string

	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DLG_CLASSA endp		; End DISP_DLG_CLASSA procedure
	NPPROC	DISP_DLG_CLASSW -- Display Dialog Class Name, Wide
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display dialog class name, wide

On entry:

ES:EDI	==>	dialog class name

On exit:

ES:EDI	==>	(updated)

|

	REGSAVE <eax,esi>	; Save registers

	cmp	AGROUP:[edi].ELO,0 ; Izit empty?
	je	short @F	; Jump if so

; The class name is a wide ASCIIZ string

	lea	esi,DLGHDR5W	; DS:ESI ==> format string
	call	DISP_FSTR	; Display the string at ES:EDI via DS:ESI
@@:
	push	es		; Pass the selector
	push	edi		; ...	   offset
	call	StrLenW 	; Return with length in EAX
	lea	edi,[edi+eax*2+2] ; Skip over the wide string

	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DLG_CLASSW endp		; End DISP_DLG_CLASSW procedure
	NPPROC	DISP_DLG_CAPTIONA -- Display Dialog Caption
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display dialog caption

On entry:

ES:EDI	==>	dialog class name

On exit:

ES:EDI	==>	(updated)

|

	REGSAVE <eax,esi>	; Save registers

	cmp	AGROUP:[edi].ELO,0 ; Izit empty?
	je	short @F	; Jump if so

; The class name is an ASCIIZ string

	lea	esi,DLGHDR6A	; DS:ESI ==> format string
	call	DISP_FSTR	; Display the string at ES:EDI via DS:ESI
@@:
	push	es		; Pass the selector
	push	edi		; ...	   offset
	call	StrLen		; Return with length in EAX
	lea	edi,[edi+eax+1] ; Skip over the string

	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DLG_CAPTIONA endp		; End DISP_DLG_CAPTIONA procedure
	NPPROC	DISP_DLG_CAPTIONW -- Display Dialog Caption, Wide
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display dialog caption, wide

On entry:

ES:EDI	==>	dialog class name

On exit:

ES:EDI	==>	(updated)

|

	REGSAVE <eax,esi>	; Save registers

	cmp	AGROUP:[edi].ELO,0 ; Izit empty?
	je	short @F	; Jump if so

; The class name is a wide ASCIIZ string

	lea	esi,DLGHDR6W	; DS:ESI ==> format string
	call	DISP_FSTR	; Display the string at ES:EDI via DS:ESI
@@:
	push	es		; Pass the selector
	push	edi		; ...	   offset
	call	StrLenW 	; Return with length in EAX
	lea	edi,[edi+eax*2+2] ; Skip over the wide string

	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DLG_CAPTIONW endp		; End DISP_DLG_CAPTIONW procedure
	NPPROC	DISP_DLG_FONTA -- Display Dialog Font Data
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display dialog font data

On entry:

ES:EDI	==>	dialog font data

On exit:

ES:EDI	==>	(updated)

|

	REGSAVE <eax,esi>	; Save registers

	lea	esi,DLGHDR7A	; DS:ESI ==> format string
				; ES:EDI ==> argument
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

	add	edi,type DLGFONTA ; Skip over the fixed data

; Display the font name

	lea	esi,DLGHDRFA	; DS:ESI ==> format string
	call	DISP_FSTR	; Display the string at ES:EDI via DS:ESI

; Skip over the string

	push	es		; Pass the selector
	push	edi		; ...	   offset
	call	StrLen		; Return with length in EAX
	lea	edi,[edi+eax+1] ; Skip over the string

	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DLG_FONTA endp		; End DISP_DLG_FONTA procedure
	NPPROC	DISP_DLG_FONTW -- Display Dialog Font Data, Wide
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display dialog font data, wide

On entry:

ES:EDI	==>	dialog font data

On exit:

ES:EDI	==>	(updated)

|

	REGSAVE <eax,esi>	; Save registers

	lea	esi,DLGHDR7W	; DS:ESI ==> format string
				; ES:EDI ==> argument
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

	add	edi,type DLGFONTW ; Skip over the fixed data

; Display the font name

	lea	esi,DLGHDRFW	; DS:ESI ==> format string
	call	DISP_FSTR	; Display the string at ES:EDI via DS:ESI

	push	es		; Pass the selector
	push	edi		; ...	   offset
	call	StrLenW 	; Return with length in EAX
	lea	edi,[edi+eax*2+2] ; Skip over the wide string

	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DLG_FONTW endp		; End DISP_DLG_FONTW procedure
	NPPROC	DISP_DLG_FONTX -- Display Dialog Font Data, Extra Wide
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display dialog font data, extra wide

On entry:

ES:EDI	==>	dialog font data

On exit:

ES:EDI	==>	(updated)

|

	REGSAVE <eax,esi>	; Save registers

	lea	esi,DLGHDR7X	; DS:ESI ==> format string
				; ES:EDI ==> argument
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

	add	edi,type DLGFONTX ; Skip over the fixed data

; Display the font name

	lea	esi,DLGHDRFX	; DS:ESI ==> format string
	call	DISP_FSTR	; Display the string at ES:EDI via DS:ESI

	push	es		; Pass the selector
	push	edi		; ...	   offset
	call	StrLenW 	; Return with length in EAX
	lea	edi,[edi+eax*2+2] ; Skip over the wide string

	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DLG_FONTX endp		; End DISP_DLG_FONTX procedure
	NPPROC	DISP_DLG_CTLA -- Display Dialog Control
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display dialog control

On entry:

ES:EDI	==>	dialog control

On exit:

ES:EDI	==>	(updated)

|

	REGSAVE <eax,esi>	; Save registers

; Display the style

	movzx	eax,AGROUP:[edi+(type DLGCTLA)] ; Get control class

	push	AGROUP:[edi].DLGCTLA_Style ; Pass the control style
	push	eax		; Pass the control class
	call	DISP_CTL_STYLE	; Display it
	jnc	short @F	; Jump if we matched a pre-defined class

	push	edi		; Save for a moment

	lea	edi,AGROUP:[edi+(type DLGCTLA)] ; Point to control class
	lea	esi,DLGHDR15A	; DS:ESI ==> format string
	call	DISP_FSTR	; Display the string at ES:EDI via DS:ESI

	pop	edi		; Restore
@@:

; Display the fixed portion of the control data

	REGSAVE <eax,edi>	; Save the class

	lea	esi,DLGHDR8A	; DS:ESI ==> format string
	lea	edi,[edi].DLGCTLA_x ; ES:EDI ==> arguments
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

	REGREST <edi,eax>	; Restore

	add	edi,type DLGCTLA ; Skip over the fixed data

; Display the class name (if present)

	test	al,80h		; Izit a pre-defined control?
	jnz	short @F	; Jump if so

	lea	esi,DLGHDR9A	; DS:ESI ==> format string
	call	DISP_FSTR	; Display the string at ES:EDI via DS:ESI

; Skip over the string

	push	es		; Pass the selector
	push	edi		; ...	   offset
	call	StrLen		; Return with length in EAX
	lea	edi,[edi+eax]	; Skip over the string (not trailing zero)
@@:
	inc	edi		; Skip over the class byte or trailing zero

; Display the resource ID or control text

	cmp	AGROUP:[edi].LO,-1 ; Izit flag for resource ID?
	jne	short DISP_DLG_CTLA1 ; Jump if not

	inc	edi		; Skip over the flag

	lea	esi,DLGHDR10	; DS:ESI ==> format string
				; ES:EDI ==> argument
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

	add	edi,2		; Skip over the resource ID

	jmp	short DISP_DLG_CTLA2 ; Join common code

; Display the control text

DISP_DLG_CTLA1:
	lea	esi,DLGHDR11A	; DS:ESI ==> format string
	call	DISP_FSTR	; Display the string at ES:EDI via DS:ESI

; Skip over the string

	push	es		; Pass the selector
	push	edi		; ...	   offset
	call	StrLen		; Return with length in EAX
	lea	edi,[edi+eax+1] ; Skip over the string
DISP_DLG_CTLA2:

; Display the extra bytes

	movzx	ecx,AGROUP:[edi].LO ; Get # extra bytes
	inc	edi		; Skip over it
	jecxz	DISP_DLG_CTLA_EXIT ; Jump if no extra bytes

	push	offset DGROUP:DLGHDR12 ; Pass the offset in DGROUP
	call	OUTSTR		; Display the string
@@:
	lea	esi,DLGHDR13	; DS:ESI ==> format string
				; ES:EDI ==> argument
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

	inc	edi		; Skip over the extra byte

	loop	@B		; Jump if more extra bytes to display

	call	DISP_EOL	; End the line
DISP_DLG_CTLA_EXIT:
	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DLG_CTLA endp		; End DISP_DLG_CTLA procedure
	NPPROC	DISP_DLG_CTLW -- Display Dialog Control, Wide
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display dialog control, wide

On entry:

ES:EDI	==>	dialog control

On exit:

ES:EDI	==>	(updated)

|

	REGSAVE <eax,esi>	; Save registers

	add	edi,4-1 	; Round up to dword
	and	edi,not (4-1)	; ...boundary

	mov	eax,AGROUP:[edi+(type DLGCTLW)] ; Get control class
	mov	esi,eax 	; Copy for later use

	cmp	ax,-1		; Izit a pre-defined control?
	jne	short @F	; Jump if not

	shr	esi,16		; Shift down the class word
@@:

; Display the style

	push	AGROUP:[edi].DLGCTLW_Style ; Pass the control style
	push	esi		; Pass the control class
	call	DISP_CTL_STYLE	; Display it
	jnc	short @F	; Jump if we matched a pre-defined class

	push	edi		; Save for a moment

	lea	edi,AGROUP:[edi+(type DLGCTLW)] ; Point to control class
	lea	esi,DLGHDR15W	; DS:ESI ==> format string
	call	DISP_FSTR	; Display the string at ES:EDI via DS:ESI

	pop	edi		; Restore
@@:

; Display the extended style

	call	DISP_CTLIND	; Indent the current line

	push	AGROUP:[edi].DLGCTLW_ExtStyle ; Pass the control extended style
	call	DLG_EXTSTYLE	; Display the dialog extended style at ES:ESI

; Display the fixed portion of the control data

	REGSAVE <eax,edi>	; Save the class

	lea	esi,DLGHDR8W	; DS:ESI ==> format string
	lea	edi,[edi].DLGCTLW_x ; ES:EDI ==> arguments
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

	REGREST <edi,eax>	; Restore

	add	edi,type DLGCTLW ; Skip over the fixed data

; Display common wide and extra-wide data

	call	DISP_DLG_CTL_COM_WX ; Display it, using EAX
				; Returning EDI updated

	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DLG_CTLW endp		; End DISP_DLG_CTLW procedure
	NPPROC	DISP_DLG_CTLX -- Display Dialog Control, Extra Wide
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display dialog control, extra wide

On entry:

ES:EDI	==>	dialog control

On exit:

ES:EDI	==>	(updated)

|

	REGSAVE <eax,esi>	; Save registers

	add	edi,4-1 	; Round up to dword
	and	edi,not (4-1)	; ...boundary

	mov	eax,AGROUP:[edi+(type DLGCTLX)] ; Get control class
	mov	esi,eax 	; Copy for later use

	cmp	ax,-1		; Izit a pre-defined control?
	jne	short @F	; Jump if not

	shr	esi,16		; Shift down the class word
@@:

; Display the style

	push	AGROUP:[edi].DLGCTLX_Style ; Pass the control style
	push	esi		; Pass the control class
	call	DISP_CTL_STYLE	; Display it
	jnc	short @F	; Jump if we matched a pre-defined class

	push	edi		; Save for a moment

	lea	edi,[edi+(type DLGCTLX)] ; Point to control class
	lea	esi,DLGHDR15X	; DS:ESI ==> format string
	call	DISP_FSTR	; Display the string at ES:EDI via DS:ESI

	pop	edi		; Restore
@@:

; Display the extended style

	call	DISP_CTLIND	; Indent the current line

	push	AGROUP:[edi].DLGCTLX_ExtStyle ; Pass the control extended style
	call	DLG_EXTSTYLE	; Display the dialog extended style at ES:ESI

; Display the help ID

	push	eax		; Save the class

	lea	esi,DLGHDR14X	; DS:ESI ==> format string
				; ES:EDI ==> argument
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

	pop	eax		; Restore

; Display the fixed portion of the control data

	REGSAVE <eax,edi>	; Save the class

	lea	esi,DLGHDR8W	; DS:ESI ==> format string
	lea	edi,[edi].DLGCTLX_x ; ES:EDI ==> arguments
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

	REGREST <edi,eax>	; Restore

	add	edi,type DLGCTLX ; Skip over the fixed data

; Display common wide and extra-wide data

	call	DISP_DLG_CTL_COM_WX ; Display it, using EAX
				; Returning EDI updated

	REGREST <esi,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DLG_CTLX endp		; End DISP_DLG_CTLX procedure
	NPPROC	DISP_DLG_CTL_COM_WX -- Display Dialog Control Common WX Data
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display dialog control common WX data

On entry:

EAX	=	class
ES:EDI	==>	dialog control

On exit:

ES:EDI	==>	(updated)

|

	REGSAVE <eax,ecx,esi>	; Save registers

; Display the class name (if present)

	cmp	ax,-1		; Izit a pre-defined control?
	je	short @F	; Jump if so

	lea	esi,DLGHDR9W	; DS:ESI ==> format string
	call	DISP_FSTR	; Display the string at ES:EDI via DS:ESI

; Skip over the string

	push	es		; Pass the selector
	push	edi		; ...	   offset
	call	StrLenW 	; Return with length in EAX
	lea	edi,[edi+eax+2+2-4] ; Skip over the wide string (not trailing zero)
@@:
	add	edi,4		; Skip over the class dword or trailing zero

; Display the resource ID or control text

	cmp	AGROUP:[edi].ELO,-1 ; Izit flag for resource ID?
	jne	short DISP_DLG_CTL_COM_WX1 ; Jump if not

	add	edi,2		; Skip over the flag

	lea	esi,DLGHDR10	; DS:ESI ==> format string
				; ES:EDI ==> argument
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

	add	edi,2		; Skip over the resource ID

	jmp	short DISP_DLG_CTL_COM_WX2 ; Join common code

; Display the control text

DISP_DLG_CTL_COM_WX1:
	lea	esi,DLGHDR11W	; DS:ESI ==> format string
	call	DISP_FSTR	; Display the string at ES:EDI via DS:ESI

; Skip over the string

	push	es		; Pass the selector
	push	edi		; ...	   offset
	call	StrLenW 	; Return with length in EAX
	lea	edi,[edi+eax*2+2] ; Skip over the wide string
DISP_DLG_CTL_COM_WX2:

; Display the extra bytes

	movzx	ecx,AGROUP:[edi].ELO ; Get # extra bytes
	add	edi,2		; Skip over it
	jecxz	DISP_DLG_CTL_COM_WX_EXIT ; Jump if no extra bytes

	push	offset DGROUP:DLGHDR12 ; Pass the offset in DGROUP
	call	OUTSTR		; Display the string
@@:
	lea	esi,DLGHDR13	; DS:ESI ==> format string
				; ES:EDI ==> argument
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

	inc	edi		; Skip over the extra byte

	loop	@B		; Jump if more extra bytes to display

	call	DISP_EOL	; End the line
DISP_DLG_CTL_COM_WX_EXIT:
	REGREST <esi,ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DLG_CTL_COM_WX endp	; End DISP_DLG_CTL_COM_WX procedure
	NPPROC	DISP_CTL_STYLE -- Display Control Style
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display control style

The class is either one of CLS_xxx or it's a user-defined class.

On exit:

CF	=	0 if we matched a pre-defined class
	=	1 if not

|

DCS_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
DCS_CLASS dd	?		; Control class
DCS_STYLE dd	?		; ...	  style

DCS_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

; Mark as another control

	REGSAVE <eax,esi,edi>	; Save for a moment

	lea	edi,CTL_COUNT	; ES:EDI ==> arguments
	add	edi,SWATDATA	; Convert from DGROUP to AGROUP
	lea	esi,DLGHDR_CTL	; DS:ESI ==> format string
	mov	ax,@I41_PRINTF32 ; Display via PRINTF
	INT41			; Request WKD services

	REGREST <edi,esi,eax>	; Restore

; Display the high-order word style

	push	0FFFF0000h	; Pass bit mask for (none) testing
	push	[ebp].DCS_STYLE ; Pass the control style
	call	DISP_DLG_STYLE_HI ; Display the dialog style

; Display the low-order word style

	cmp	[ebp].DCS_CLASS,CLS_BUTTON ; Izit button class?
	jne	short @F	; Jump if not

	push	[ebp].DCS_STYLE ; Pass the control style
	call	DISP_CTL_BUTTON ; Display button class styles

	jmp	short DISP_CTL_STYLE_DONE ; Join common done code

@@:
	cmp	[ebp].DCS_CLASS,CLS_EDIT ; Izit edit class?
	jne	short @F	; Jump if not

	push	[ebp].DCS_STYLE ; Pass the control style
	call	DISP_CTL_EDIT	; Display edit class styles

	jmp	short DISP_CTL_STYLE_DONE ; Join common done code

@@:
	cmp	[ebp].DCS_CLASS,CLS_STATIC ; Izit static class?
	jne	short @F	; Jump if not

	push	[ebp].DCS_STYLE ; Pass the control style
	call	DISP_CTL_STATIC ; Display static class styles

	jmp	short DISP_CTL_STYLE_DONE ; Join common done code

@@:
	cmp	[ebp].DCS_CLASS,CLS_LISTBOX ; Izit listbox class?
	jne	short @F	; Jump if not

	push	[ebp].DCS_STYLE ; Pass the control style
	call	DISP_CTL_LISTBOX ; Display listbox class styles

	jmp	short DISP_CTL_STYLE_DONE ; Join common done code

@@:
	cmp	[ebp].DCS_CLASS,CLS_SCROLLBAR ; Izit scrollbar class?
	jne	short @F	; Jump if not

	push	[ebp].DCS_STYLE ; Pass the control style
	call	DISP_CTL_SCROLLBAR ; Display scrollbar class styles

	jmp	short DISP_CTL_STYLE_DONE ; Join common done code

@@:
	cmp	[ebp].DCS_CLASS,CLS_COMBOBOX ; Izit combobox class?
	jne	short @F	; Jump if not

	push	[ebp].DCS_STYLE ; Pass the control style
	call	DISP_CTL_COMBOBOX ; Display combobox class styles

	jmp	short DISP_CTL_STYLE_DONE ; Join common done code

@@:
	stc			; Mark as not found

	jmp	short DISP_CTL_STYLE_EXIT ; Join common exit code

DISP_CTL_STYLE_DONE:
	clc			; Mark as found
DISP_CTL_STYLE_EXIT:
	pop	ebp		; Restore

	ret	4+4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_CTL_STYLE endp		; End DISP_CTL_STYLE procedure
	NPPROC	DISP_CTL_BUTTON -- Display Class Button Styles
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display class button styles

|

DCBS_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
DCBS_STYLE dd	?		; Style

DCBS_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	push	offset DGROUP:CTLBUTTON ; Pass offset in DGROUP of text string
	call	OUTSTR		; Display the string

	push	@CTL_BSLEN	; Pass length of control name
	push	@BS_TYPMSK	; Pass type mask
	push	[ebp].DCBS_STYLE ; ... style
	push	offset DGROUP:BS_LST ; ... list
	push	offset DGROUP:BS_TAB ; ... table
	push	@BS_TAB 	; ... table length
	call	DISP_CTL_COM	; Call common routine

	call	DISP_EOL	; End the line

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_CTL_BUTTON endp		; End DISP_CTL_BUTTON procedure
	NPPROC	DISP_CTL_EDIT -- Display Class Edit Styles
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display class edit styles

|

DCED_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
DCED_STYLE dd	?		; Style

DCED_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	push	offset DGROUP:CTLEDIT ; Pass offset in DGROUP of text string
	call	OUTSTR		; Display the string

	push	@CTL_ESLEN	; Pass length of control name
	push	@ES_TYPMSK	; Pass type mask
	push	[ebp].DCED_STYLE ; ... style
	push	offset DGROUP:ES_LST ; ... list
	push	offset DGROUP:ES_TAB ; ... table
	push	@ES_TAB 	; ... table length
	call	DISP_CTL_COM	; Call common routine

	call	DISP_EOL	; End the line

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_CTL_EDIT endp		; End DISP_CTL_EDIT procedure
	NPPROC	DISP_CTL_STATIC -- Display Class Static Styles
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display class static styles

|

DCST_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
DCST_STYLE dd	?		; Style

DCST_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	push	offset DGROUP:CTLSTATIC ; Pass offset in DGROUP of text string
	call	OUTSTR		; Display the string

	push	@CTL_SSLEN	; Pass length of control name
	push	@SS_TYPMSK	; Pass type mask
	push	[ebp].DCST_STYLE ; ... style
	push	offset DGROUP:SS_LST ; ... list
	push	offset DGROUP:SS_TAB ; ... table
	push	@SS_TAB 	; ... table length
	call	DISP_CTL_COM	; Call common routine

	call	DISP_EOL	; End the line

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_CTL_STATIC endp		; End DISP_CTL_STATIC procedure
	NPPROC	DISP_CTL_LISTBOX -- Display Class Listbox Styles
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display class listbox styles

|

DCLB_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
DCLB_STYLE dd	?		; Style

DCLB_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	push	offset DGROUP:CTLLBOX ; Pass offset in DGROUP of text string
	call	OUTSTR		; Display the string

	push	@CTL_LBSLEN	; Pass length of control name
	push	@LBS_TYPMSK	; Pass type mask
	push	[ebp].DCLB_STYLE ; ... style
	push	0		; ... list (none)
	push	offset DGROUP:LBS_TAB ; ... table
	push	@LBS_TAB	; ... table length
	call	DISP_CTL_COM	; Call common routine

	call	DISP_EOL	; End the line

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_CTL_LISTBOX endp		; End DISP_CTL_LISTBOX procedure
	NPPROC	DISP_CTL_SCROLLBAR -- Display Class Scrollbar Styles
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display class scrollbar styles

|

DCSB_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
DCSB_STYLE dd	?		; Style

DCSB_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	push	offset DGROUP:CTLSBAR ; Pass offset in DGROUP of text string
	call	OUTSTR		; Display the string

	test	[ebp].DCSB_STYLE,SBS_HORZ ; Izit horizontal?
	jz	short @F	; Jump if not

	push	@CTL_SBSLEN	; Pass length of control name
	push	@SBS_TYPMSK	; Pass type mask
	push	[ebp].DCSB_STYLE ; ... style
	push	offset DGROUP:SBS_LST ; ... list
	push	offset DGROUP:SBS_HORZ_TAB ; ... table
	push	@SBS_HORZ_TAB	; ... table length
	call	DISP_CTL_COM	; Call common routine

	jmp	short DCSB_EXIT ; Join common code

@@:
	test	[ebp].DCSB_STYLE,SBS_VERT ; Izit vertical?
	jz	short @F	; Jump if not

	push	@CTL_SBSLEN	; Pass length of control name
	push	@SBS_TYPMSK	; Pass type mask
	push	[ebp].DCSB_STYLE ; ... style
	push	offset DGROUP:SBS_LST ; ... list
	push	offset DGROUP:SBS_VERT_TAB ; ... table
	push	@SBS_VERT_TAB	; ... table length
	call	DISP_CTL_COM	; Call common routine

	jmp	short DCSB_EXIT ; Join common code

@@:
	test	[ebp].DCSB_STYLE,SBS_SIZEBOX ; Izit sizebox?
	jz	short @F	; Jump if not

	push	@CTL_SBSLEN	; Pass length of control name
	push	@SBS_TYPMSK	; Pass type mask
	push	[ebp].DCSB_STYLE ; ... style
	push	offset DGROUP:SBS_LST ; ... list
	push	offset DGROUP:SBS_SIZE_TAB ; ... table
	push	@SBS_SIZE_TAB	; ... table length
	call	DISP_CTL_COM	; Call common routine

	jmp	short DCSB_EXIT ; Join common code

@@:
	test	[ebp].DCSB_STYLE,SBS_SIZEGRIP ; Izit gripbox?
	jz	short @F	; Jump if not

	push	@CTL_SBSLEN	; Pass length of control name
	push	@SBS_TYPMSK	; Pass type mask
	push	[ebp].DCSB_STYLE ; ... style
	push	offset DGROUP:SBS_LST ; ... list
	push	offset DGROUP:SBS_GRIP_TAB ; ... table
	push	@SBS_GRIP_TAB	; ... table length
	call	DISP_CTL_COM	; Call common routine

;;;;;;; jmp	short DCSB_EXIT ; Join common code

@@:
DCSB_EXIT:
	call	DISP_EOL	; End the line

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_CTL_SCROLLBAR endp 	  ; End DISP_CTL_SCROLLBAR procedure
	NPPROC	DISP_CTL_COMBOBOX -- Display Class Combobox Styles
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display class combobox styles

|

DCCB_STR struc

	dd	?		; Caller's EBP
	dd	?		; ...	   EIP
DCCB_STYLE dd	?		; Style

DCCB_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	push	offset DGROUP:CTLCBOX ; Pass offset in DGROUP of text string
	call	OUTSTR		; Display the string

	push	@CTL_CBSLEN	; Pass length of control name
	push	@CBS_TYPMSK	; Pass type mask
	push	[ebp].DCCB_STYLE ; ... style
	push	offset DGROUP:CBS_LST ; ... list
	push	offset DGROUP:CBS_TAB ; ... table
	push	@CBS_TAB	; ... table length
	call	DISP_CTL_COM	; Call common routine

	call	DISP_EOL	; End the line

	pop	ebp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_CTL_COMBOBOX endp		  ; End DISP_CTL_COMBOBOX procedure
	NPPROC	DISP_CTL_COM -- Display Control Common Routine
	assume	ds:DGROUP,es:AGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display control common routine

|

DCC_STR struc

	db	(type PUSHAD_STR) dup (?) ; Caller's EGP registers
	dd	?		; ...	   EIP
DCC_TABLEN dd	?		; Table length
DCC_TAB dd	?		; Table
DCC_LST dd	?		; List
DCC_STYLE dd	?		; Style
DCC_TYPEMASK dd ?		; Type mask
DCC_CTLLEN dd	?		; Length of control name

DCC_STR ends

	pushad			; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	movzx	edi,[ebp].DCC_STYLE.ELO ; Get the low-order style word
	mov	eax,edi 	; Copy for testing

	and	eax,eax 	; Any style bits?
	jz	near ptr DISP_CTL_NONE ; Jump if none

	and	eax,[ebp].DCC_TYPEMASK ; Isolate the bit field
	jz	short @F	; Jump if none

	mov	ebx,[ebp].DCC_LST ; Get offset in DGROUP of list
	push	DGROUP:[ebx+eax*(type STYLE_STR)].STYLE_TXT ; Pass text string
	call	OUTSTR		; Display the string

	mov	eax,[ebp].DCC_TYPEMASK ; Get the mask bits
	not	eax		; Complement to delete those bits
	and	edi,eax 	; Remove the bits
@@:
	mov	ecx,[ebp].DCC_TABLEN ; Get # entries to check
	xor	ebx,ebx 	; Initialize index into STYLE_TAB
	mov	esi,[ebp].DCC_TAB ; Get offset in DGROUP of table

	and	edi,edi 	; Any bits in this part?
	jz	near ptr DISP_CTL_EXIT ; Jump if not
DISP_CTL_COM1:
	mov	edx,DGROUP:[esi+ebx*(type STYLE_STR)].STYLE_VAL ; Get the style value
	mov	eax,edi 	; Copy the remaining style bits
	and	eax,edx 	; Isolate the value

	cmp	eax,edx 	; Izit the same?
	jne	short @F	; Jump if not

	push	[ebp].DCC_CTLLEN ; Pass length of control name
	push	DGROUP:[esi+ebx*(type STYLE_STR)].STYLE_TXT ; Pass offset in DGROUP
	call	OUTSTR_WRAP	; Display the string, wrapping to next line
				; if necessary
	not	edx		; Complement to remove the bits
	and	edi,edx 	; Remove 'em

	and	edi,edi 	; Any more bits in this part?
	jz	short DISP_CTL_EXIT ; Jump if not
@@:
	inc	ebx		; Skip to next entry

	loop	DISP_CTL_COM1	; Jump if more entries

; Display unused bits

	mov	eax,edi 	; Copy the style dword
	and	eax,eax 	; Izit empty?
	jz	short DISP_CTL_EXIT ; Jump if no undisplayed bits

	push	es		; Save for a moment

	mov	bx,ds		; Get DGROUP data selector
	mov	es,bx		; Address it
	assume	es:DGROUP	; Tell the assembler about it

	lea	edi,DLGTEMP1	; ES:EDI ==> output save area
	call	DD2HEX		; Convert EAX to ASCII hex at ES:EDI

	mov	esi,edi 	; DS:ESI ==> string to display
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	INT41			; Request WKD services

	pop	es		; Restore
	assume	es:AGROUP	; Tell the assembler about it

	jmp	short DISP_CTL_EXIT ; Join common exit code


DISP_CTL_NONE:
	lea	esi,DLGHDR_NONE ; DS:ESI ==> string
	mov	ax,@I41_OUT_STR ; Get function code to display string at DS:ESI
	INT41			; Request WKD services
DISP_CTL_EXIT:
	popad			; Restore

	ret	6*4		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_CTL_COM endp		; End DISP_CTL_COM procedure

PROG	ends			; End PROG segment

	MEND			; End SWAT_DLG module
