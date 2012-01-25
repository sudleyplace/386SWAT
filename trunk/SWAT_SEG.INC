;' $Header:   P:/PVCS/386SWAT/SWAT_SEG.INV   1.9   10 Jul 1997 12:00:20   BOB  $
;
; (C) Copyright 1987-95 Qualitas, Inc.	All rights reserved.
;
; SWAT_SEG.INC
;
; All segments in SWAT in order of appearance
;

PGROUP	group	PROG0,PROG
PCODEZ	 group	 CODEZ
DGROUP	 group	 DATA16,DATA,KEYSEG,ACTSEG,SEG_TAB,SEG_LEN,SEG_ACT, \
		 SREG_TAB,SREG_MAX,SREG_OFF,SREG_ACTGET,SREG_ACTSET,SREG_LEN, \
		 KSEGCOD,KSEGACT,KSEGTAB,KSEGTOG,KSEGNAM,KSEGOFF, \
		 TEXT,INSTR,ESCOD
XGROUP	 group	 XCODE,XDATA,XDATAZ
NGROUP	 group	 NCODE,NDATA,ASEGTAB,ASEGLEN,ASEGACT,ASEGTOG,NDATAZ
RGROUP	group	RCODE0,RCODE,RDATAZ
WGROUP	 group	 WTAB,WVALW,WPTR,WTXT,WDATAZ


PROG0	segment use32 byte public 'prog' ; Start PROG0 segment
PROG0	ends			; End PROG0 segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
PROG	 ends			; End PROG segment


CODEZ	 segment use16 para public 'codez' ; Start CODEZ segment
CODEZ	 ends			; End CODEZ segment


DATA16	 segment use32 dword public 'data' ; Start DATA16 segment
DATA16	 ends			; End DATA16 segment


DATA	 segment use32 dword public 'data' ; Start DATA segment
DATA	 ends			; End DATA segment


KEYSEG	 segment use32 word public 'data' ; Start KEYSEG segment
KEYSEG	 ends			; End KEYSEG segment


ACTSEG	 segment use32 dword public 'data' ; Start ACTSEG segment
ACTSEG	 ends			; End ACTSEG segment


SEG_TAB  segment use32 dword public 'data' ; Start SEG_TAB segment
SEG_TAB  ends			; End SEG_TAB segment


SEG_LEN  segment use32 dword public 'data' ; Start SEG_LEN segment
SEG_LEN  ends			; End SEG_LEN segment


SEG_ACT  segment use32 dword public 'data' ; Start SEG_ACT segment
SEG_ACT  ends			; End SEG_ACT segment


SREG_TAB segment use32 dword public 'data' ; Start SREG_TAB segment
SREG_TAB ends			; End SREG_TAB segment


SREG_MAX segment use32 dword public 'data' ; Start SREG_MAX segment
SREG_MAX ends			; End SREG_MAX segment


SREG_OFF segment use32 word public 'data' ; Start SREG_OFF segment
SREG_OFF ends			; End SREG_OFF segment


SREG_ACTGET segment use32 dword public 'data' ; Start SREG_ACTGET segment
SREG_ACTGET ends		; End SREG_ACTGET segment


SREG_ACTSET segment use32 dword public 'data' ; Start SREG_ACTSET segment
SREG_ACTSET ends		; End SREG_ACTSET segment


SREG_LEN segment use32 dword public 'data' ; Start SREG_LEN segment
SREG_LEN ends			; End SREG_LEN segment


KSEGCOD  segment use32 byte public 'data' ; Start KSEGCOD segment
KSEGCOD  ends			; End KSEGCOD segment


KSEGACT  segment use32 dword public 'data' ; Start KSEGACT segment
KSEGACT  ends			; End KSEGACT segment


KSEGTAB  segment use32 word public 'data' ; Start KSEGTAB segment
KSEGTAB  ends			; End KSEGTAB segment


KSEGTOG  segment use32 byte public 'data' ; Start KSEGTOG segment
KSEGTOG  ends			; End KSEGTOG segment


KSEGNAM  segment use32 byte public 'data' ; Start KSEGNAM segment
KSEGNAM  ends			; End KSEGNAM segment


KSEGOFF  segment use32 dword public 'data' ; Start KSEGOFF segment
KSEGOFF  ends			; End KSEGOFF segment


TEXT	 segment use32 byte public 'data' ; Start TEXT segment
TEXT	 ends			; End TEXT segment


INSTR	 segment use32 dword public 'data' ; Start INSTR segment
INSTR	 ends			; End INSTR segment


ESCOD	 segment use32 dword public 'data' ; Start ESCOD segment
ESCOD	 ends			; End ESCOD segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
XCODE	 ends			; End XCODE segment


XDATA	 segment use16 dword public 'xdata' ; Start XDATA segment
XDATA	 ends			; End XDATA segment


XDATAZ	 segment use16 para public 'xdataz' ; Start XDATAZ segment
XDATAZ	 ends			; End XDATAZ segment


NCODE	 segment use16 para public 'ncode' ; Start NCODE segment
NCODE	 ends			; End NCODE segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
NDATA	 ends			; End NDATA segment


ASEGTAB  segment use16 word public 'ndata' ; Start ASEGTAB segment
ASEGTAB  ends			; End ASEGTAB segment


ASEGLEN  segment use16 word public 'ndata' ; Start ASEGLEN segment
ASEGLEN  ends			; End ASEGLEN segment


ASEGACT  segment use16 word public 'ndata' ; Start ASEGACT segment
ASEGACT  ends			; End ASEGACT segment


ASEGTOG  segment use16 byte public 'ndata' ; Start ASEGTOG segment
ASEGTOG  ends			; End ASEGTOG segment


NDATAZ	 segment use16 para public 'ndataz' ; Start NDATAZ segment
NDATAZ	 ends			; End NDATAZ segment


RCODE0	segment use16 para public 'rcode' ; Start RCODE0 segment
RCODE0	ends			; End RCODE0 segment


RCODE	 segment use16 para public 'rcode' ; Start RCODE segment
RCODE	 ends			; End RCODE segment


RDATAZ	 segment use16 para public 'rdataz' ; Start RDATAZ segment
RDATAZ	 ends			; End RDATAZ segment


WTAB	 segment use32 dword public 'wdata' ; Start WTAB segment
WTAB	 ends			; End WTAB segment


WVALW	 segment use32 word public 'wdata' ; Start WVALW segment
WVALW	 ends			; End WVALW segment


WPTR	 segment use32 dword public 'wdata' ; Start WPTR segment
WPTR	 ends			; End WPTR segment


WTXT	 segment use32 byte public 'wdata' ; Start WTXT segment
WTXT	 ends			; End WTXT segment


WDATAZ	 segment use32 para public 'wdataz' ; Start WDATAZ segment
WDATAZ	 ends			; End WDATAZ segment


STACK	 segment use16 byte stack ; Start STACK segment
STACK	 ends			; End STACK segment


