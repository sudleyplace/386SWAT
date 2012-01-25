;
; PTR.INC
;
; Pointer Structures and others
;

VECTOR	 struc

VOFF	 dw	 ?		; Offset
VSEG	 dw	 ?		; Segment

VECTOR	 ends


HILO_STR struc

LO	 db	 ?		; Register low-order byte
HI	 db	 ?		; Register high-order byte

HILO_STR ends


EGP_STR  struc

ELO	 dw	 ?		; Extended register low-order word
EHI	 dw	 ?		; Extended register high-order word

EGP_STR  ends


EDD_STR struc

EDD	 dd	 ?		; Doubleword

EDD_STR ends


EDF_STR struc

EDF	 df	 ?		; Six-bytes

EDF_STR ends


PTR32_STR struc

FOFF	 dd	 ?		; 32-bit base offset
FSEL	 dw	 ?		; Selector

PTR32_STR ends


EDQ_STR struc

EDQLO	 dd	 ?		; Low-order dword
EDQHI	 dd	 ?		; High-...

EDQ_STR ends


