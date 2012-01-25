;' $Header:   P:/PVCS/386SWAT/INT1/INT1_STB.ASV   1.3   01 Jul 1997 17:55:56   BOB  $
	 title	 INT1_STB -- Symbol support stub routines
	 page	 58,122
	 name	 INT1_STB

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Henry Groover, November, 1991.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
.list

PGROUP	 group	 CODE
DGROUP	 group	 DATA


DATA	 segment use16 word public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 public  SELFDBG,SYMCOUNT,PROXSRCH
SELFDBG  dd	0		; Breakpoint reentrancy flags
SYMCOUNT dd	0		; Size of symbol table
PROXSRCH dw	0		; Proximity search parameters

DATA	 ends			; End DATA segment


CODE	 segment use16 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 NPPROC  SYMHASH_SRCH -- Stub for symbol table hash search
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Always return failure (CF=1).

|

	 stc			; Indicate failure

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SYMHASH_SRCH	 endp		; End SYMHASH_SRCH procedure

	 NPPROC  GETBASE -- Stub for get selector base
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Always return failure (CF=1).

|

	 stc			; Indicate failure

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETBASE 	 endp		; End GETBASE procedure


CODE	 ends			; End CODE segment

	 MEND			; End INT1_STB module
