;' $Header:   P:/PVCS/386SWAT/SWAT_FVM.INV   1.1   23 Jun 1992 14:54:44   DAVID  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; SWAT_FVM.INC
;
; Structure for 386SWAT's Find Video Mode routines
;

FVM_STR  struc

FVM_SIZE dd	 ?		; Size of this entry in bytes
FVM_MODE db	 ?		; This video mode (AL)
FVM_CMD  db	 ?		; Command:  @SETMOD = mode,
				;	    @SETTYP = cursor type
				;	    @GETEGA = get EGA information
FVM_CUR  dw	 ?		; Cursor type if @SETTYP,
				; BL if @GETEGA
FVM_STR  ends

@FVM_EOM equ	 -1		; End of video modes marker


