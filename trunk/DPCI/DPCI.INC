
@NROWS	equ	25		; # rows on screen
@NCOLS	equ	80		; # cols ...

; DPCI equates for LCL_FLAG

@LCL_PCI  equ	8000h		; PCI BIOS present
@LCL_PCIMDA equ 4000h		; PCI MDA present
@LCL_DPCI equ	2000h		; Dual PCI VGA adapters present
@LCL_MDA  equ	1000h		; Monochrome adapter present
@LCL_AGP  equ	0800h		; AGP controller present (VBDAGP filled in)
@LCL_MONO equ	0400h		; MONO on command line
@LCL_DVGA equ	0200h		; DVGA ...

