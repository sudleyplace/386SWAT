;' $Header$
;
; (C) Copyright 1987-2000 Qualitas, Inc.  All rights reserved.
;
; PS2MM.INC
;
; Structure and equates for PS/2 memory map function.
;

; PS/2 memory map table filled in by BIOS function INT 15h, AH=0C7h.

.xcref PS2_MM_STR
PS2_MM_STR struc

PS2_MM_LEN  dw	?		; 00:  Length of table (excluding this word)
PS2_MM_LCL0 dd	?		; 02:  Local memory between 1M and 16M, in 1K blocks
PS2_MM_LCL1 dd	?		; 06:  Local memory between 16M and 4G, in 1K blocks
PS2_MM_SYS0 dd	?		; 0A:  System memory between 1M and 16M, in 1K blocks
PS2_MM_SYS1 dd	?		; 0E:  System memory between 16M and 4G, in 1K blocks
PS2_MM_CAC0 dd	?		; 12:  Cacheable memory between 1M and 16M, in 1K blocks
PS2_MM_CAC1 dd	?		; 16:  Cacheable memory between 16M and 4G, in 1K blocks
PS2_MM_NSY0 dd	?		; 1A:  1K blocks before start of non-system memory between 1M and 16M
PS2_MM_NSY1 dd	?		; 1E:  1K blocks before start of non-system memory between 16M and 4G
PS2_MM_FSEG dw	?		; 22:  Segment of largest free block from C000:0 to E000:0
PS2_MM_FLEN dw	?		; 24:  Length of ...
PS2_MM_RSVD dd	?		; 26:  Reserved

PS2_MM_STR ends

