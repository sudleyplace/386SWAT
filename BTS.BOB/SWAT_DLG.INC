;' $Header$
;
; (C) Copyright 1987-98 Qualitas, Inc.	All rights reserved.
;
; SWAT_DLG.INC
;
; Structs for Dialogs
;


; Define dialog structures

DLGHDRA struc

DLGHDRA_Style dd ?		; Style (DS_xxx)
DLGHDRA_NumItems db ?		; # controls
DLGHDRA_x  dw ? 		; x-coord in dialog units of UL corner
DLGHDRA_y  dw ? 		; y-...
DLGHDRA_cx dw ? 		; Width in dialog units
DLGHDRA_cy dw ? 		; Height ...

DLGHDRA ends

; This struct is followed by
;      union {
;	       struct {
;		       BYTE Flag = 0x00;   // No menu
;		      };
;	       struct {
;		       BYTE Flag = 0xFF;   // Menu is Ordinal
;		       WORD Ordinal;
;		      };
;	       char szMenuName[];	   // ASCIIZ Menu name
;	     } menu;
;      char szClassName[];		   // ASCIIZ Class name
;      char szCaption[];		   // ASCIIZ Caption
;      If (DIALOGBOXHEADER.lStyle & DS_SETFONT)
;	   FONTDATAA font;


DLGHDRW struc

DLGHDRW_Style dd ?		; Style (DS_xxx)
DLGHDRW_ExtStyle dd ?		; Extended Style (WS_EX_xxx)
DLGHDRW_NumItems dw ?		; # controls
DLGHDRW_x  dw ? 		; x-coord in dialog units of UL corner
DLGHDRW_y  dw ? 		; y-...
DLGHDRW_cx dw ? 		; Width in dialog units
DLGHDRW_cy dw ? 		; Height ...

DLGHDRW ends

; This struct is followed by
;      union {
;	       struct {
;		       WORD Flag = 0x0000; // No menu
;		      };
;	       struct {
;		       WORD Flag = 0xFFFF; // Menu is ordinal
;		       WORD Ordinal;
;		      };
;	       wchar_t szMenuName[];	   // ASCIIZ Menu name
;	     } menu;
;      wchar_t szClassName[];		   // ASCIIZ Class name
;      wchar_t szCaption[];		   // ASCIIZ Caption
;      If (DIALOGBOXHEADER.lStyle & DS_SETFONT)
;	   FONTDATAW font;


DBHX_SIG equ	0FFFFh

DLGHDRX struc

DLGHDRX_Ver dw	?		; Version # (0x0001)	  
DLGHDRX_Sign dw ?		; Signature (DBHX_SIG)	
DLGHDRX_HelpID dd ?		; Dialog's context help ID
DLGHDRX_ExtStyle dd ?		; Extended Style (WS_EX_xxx)
DLGHDRX_Style dd ?		; Style (DS_xxx)
DLGHDRX_NumItems dw ?		; # controls
DLGHDRX_x  dw ? 		; x-coord in dialog units of UL corner
DLGHDRX_y  dw ? 		; y-...
DLGHDRX_cx dw ? 		; Width in dialog units
DLGHDRX_cy dw ? 		; Height ...

DLGHDRX ends

; This struct is followed by
;      union {
;	       struct {
;		       WORD Flag = 0x0000; // No menu
;		      };
;	       struct {
;		       WORD Flag = 0xFFFF; // Menu is ordinal
;		       WORD Ordinal;
;		      };
;	       wchar_t szMenuName[];	   // ASCIIZ Menu name
;	     } menu;
;      wchar_t szClassName[];		   // ASCIIZ Class name
;      wchar_t szCaption[];		   // ASCIIZ Caption
;      If (DIALOGBOXHEADER.lStyle & DS_SETFONT)
;	   FONTDATAX font;


DLGFONTA struc

DLGFONTA_PtSize dw ?		; Point size
; This data is followed by the ASCIIZ string of the face name

DLGFONTA ends


DLGFONTW struc

DLGFONTW_PtSize dw ?		; Point size
; This data is followed by the wide ASCIIZ string of the face name

DLGFONTW ends


DLGFONTX struc

DLGFONTX_PtSize dw ?		; Point size
DLGFONTX_Weight dw ?		; Weight (see FW_xxx)
DLGFONTX_Italic dw ?		; TRUE iff Italic font
; This data is followed by the wide ASCIIZ string of the face name

DLGFONTX ends


DLGCTLA struc

DLGCTLA_x dw	?		; x-coord in dialog units of UL corner
DLGCTLA_y dw	?		; y-... 			      
DLGCTLA_cx dw	?		; Width in dialog units 	      
DLGCTLA_cy dw	?		; Height ...			      
DLGCTLA_ID dw	?		; Control identifier		      
DLGCTLA_Style dd ?		; Style (window- and control-specific)

DLGCTLA ends

; This struct is followed by
;      union
;      {
;	   BYTE class;	       // If (class & 0x80)
;	   char szClass[];     // else (ASCIIZ)
;      } class;
;      union
;      {
;	   struct
;	   {
;	       BYTE Flag;      // If (Flag == 0xFF)
;	       WORD wID;       // Resource ID
;	   } ResID;
;	   char szText[];      // Control text (ASCIIZ)
;      }
;      BYTE cExtra;	       // Count of extra bytes
;      BYTE Extra[cExtra];     // The extra bytes

DLGCTLW struc

DLGCTLW_Style dd ?		; Style (window- and control-specific)
DLGCTLW_ExtStyle dd ?		; Extended style (WS_EX_xxx)
DLGCTLW_x dw	?		; x-coord in dialog units of UL corner
DLGCTLW_y dw	?		; y-... 			      
DLGCTLW_cx dw	?		; Width in dialog units 	      
DLGCTLW_cy dw	?		; Height ...			      
DLGCTLW_ID dw	?		; Control identifier		      

DLGCTLW ends

; This struct is followed by
;      union
;      {
;	   DWORD class;        // If (LOWORD (class) = 0xFFFF)
;	   wchar_t szClass[];  // else
;      } class;
;      union
;      {
;	   struct
;	   {
;	       WORD Flag;      // If (Flag == 0xFFFF)
;	       WORD wID;       // Resource ID
;	   } ResID;
;	   wchar_t szText[];   // Control text (ASCIIZ)
;      }
;      WORD wExtra;	       // Count of extra bytes
;      BYTE Extra[wExtra];     // The extra bytes

DLGCTLX struc

DLGCTLX_HelpID dd ?		; Dialog's context help ID
DLGCTLX_ExtStyle dd ?		; Extended style (WS_EX_xxx)
DLGCTLX_Style dd ?		; Style (window- and control-specific)
DLGCTLX_x dw	?		; x-coord in dialog units of UL corner
DLGCTLX_y dw	?		; y-... 			      
DLGCTLX_cx dw	?		; Width in dialog units 	      
DLGCTLX_cy dw	?		; Height ...			      
DLGCTLX_ID dd	?		; Control identifier		      

DLGCTLX ends

; This struct is followed by
;      union
;      {
;	   DWORD class;        // If (LOWORD (class) = 0xFFFF)
;	   wchar_t szClass[];  // else
;      } class;
;      union
;      {
;	   struct
;	   {
;	       WORD Flag;      // If (Flag == 0xFFFF)
;	       WORD wID;       // Resource ID
;	   } ResID;
;	   wchar_t szText[];   // Control text (ASCIIZ)
;      }
;      WORD wExtra;	       // Count of extra bytes
;      BYTE Extra[wExtra];     // The extra bytes

