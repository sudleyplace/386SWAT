;' $Header:   P:/PVCS/386SWAT/SWAT_WIN.ASV   1.9   21 Aug 1997 15:00:26   BOB  $
	 title	 SWAT_WIN -- 386SWAT Window Routines
	 page	 58,122
	 name	 SWAT_WIN

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC
	 include PTR.INC
	 include 386.INC
	 include ALLMEM.INC
	 include BITFLAGS.INC
	 include VIDATTR.INC

	 include SWAT_COM.INC
	 include SWAT_SEG.INC
.list

DATA16	 segment use32 dword public 'data' ; Start DATA16 segment
	 assume  ds:DGROUP

	 extrn	 VIDBASE_FVEC:fword

DATA16	 ends			; End DATA16 segment


DATA	 segment use32 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 public  W_SHD
W_SHD	 W_STR	 <>		; Window descriptor used for all shadowing
				; Note that it's not re-entrant
	 public  MSG_SHD1
MSG_SHD1 db	 @NCOLS dup (?) ; Save area for SHD1 values

DATA	 ends			; End DATA segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 NPPROC  WSETUP -- Common Window Setup
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common window setup

On exit:

ES:EDI	 =	 starting offset in screen buffer
ECX	 =	 # columns in window
EDX	 =	 # rows ...

|

	 REGSAVE <eax,esi>	; Save registers

	 mov	 es,VIDBASE_FVEC.FSEL ; Get video base selector
	 assume  es:nothing	; Tell the assembler about it

	 mov	 esi,[ebp].WPUT_C_DESC ; DS:ESI ==> window descriptor

	 movzx	 eax,DGROUP:[esi].SROW ; Get the starting row
	 mov	 ecx,@NCOLS*2	; Get # bytes per row
	 mul	 ecx		; EAX = offset in screen buffer (EDX clobbered)
	 mov	 edi,eax	; ES:EDI ==> screen base

	 movzx	 eax,DGROUP:[esi].SCOL ; Get the starting column
	 shl	 eax,1-0	; Convert from chars to bytes
	 add	 edi,eax	; Add into screen base
	 add	 edi,VIDBASE_FVEC.FOFF ; Plus our video base

	 movzx	 edx,DGROUP:[esi].NROW ; Get # rows
	 movzx	 ecx,DGROUP:[esi].NCOL ; Get # columns

	 REGREST <esi,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WSETUP	 endp			; End WSETUP procedure
	 NPPROC  WPUT_C -- Output Characters
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Output characters.

|

WPUT_C_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
WPUT_C_DESC dd	 ?		; Offset of descriptor
WPUT_C_IBUF dd	 ?		; Offset of input buffer

WPUT_C_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ecx,edx,esi,edi,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
	 assume  es:nothing	; Tell the assembler about it
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; EDX	 = # rows ...

	 jecxz	 WPUT_C_EXIT	; Jump if no columns

	 and	 edx,edx	; Check # rows to output
	 jz	 short WPUT_C_EXIT ; Jump if no rows

	 mov	 esi,[ebp].WPUT_C_IBUF ; DS:ESI ==> input buffer
WPUT_C_NEXTROW:
	 REGSAVE <ecx,edi>	; Save for a moment
WPUT_C_NEXTCOL:
S32	 movs	 <es:[edi].LO,DGROUP:[esi].LO> ; Move the first character

	 inc	 edi		; Skip over attribute

	 loop	 WPUT_C_NEXTCOL ; Jump if more character in this row

	 REGREST <edi,ecx>	; Restore

	 add	 edi,@NCOLS*2	; Skip to next row

	 dec	 edx		; Account for one less row
	 jnz	 WPUT_C_NEXTROW ; Jump if more rows to output
WPUT_C_EXIT:
	 REGREST <es,edi,esi,edx,ecx> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 4+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_C	 endp			; End WPUT_C procedure
	 NPPROC  WPUT_CA -- Output Characters and Attributes
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Output characters and attributes.

|

WPUT_CA_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
WPUT_CA_DESC dd  ?		; Offset of descriptor
WPUT_CA_IBUF dd  ?		; Offset of input buffer

WPUT_CA_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ax,ecx,edx,esi,edi,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
	 assume  es:nothing	; Tell the assembler about it
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; EDX	 = # rows ...

	 jecxz	 WPUT_CA_EXIT  ; Jump if no columns

	 and	 edx,edx	; Check # rows to input
	 jz	 short WPUT_CA_EXIT ; Jump if no rows

	 mov	 esi,[ebp].WPUT_CA_IBUF ; DS:ESI ==> input buffer
WPUT_CA_NEXTROW:
	 REGSAVE <ecx,edi>	; Save for a moment

S32  rep movs	 <es:[edi].ELO,DGROUP:[esi].ELO> ; Copy chars and attrs to screen

	 REGREST <edi,ecx>	; Restore

	 add	 edi,@NCOLS*2	; Skip to next row

	 dec	 edx		; Account for one less row
	 jnz	 WPUT_CA_NEXTROW ; Jump if more rows to input
WPUT_CA_EXIT:
	 REGREST <es,edi,esi,edx,ecx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 4+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_CA  endp			; End WPUT_CA procedure
	 NPPROC  WPUT_CSA -- Output Characters, Smear Attribute
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Output characters.

|

WPUT_CSA_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
WPUT_CSA_DESC dd ?		; Offset of descriptor
WPUT_CSA_IBUF dd ?		; Offset of input buffer
WPUT_CSA_ATTR db ?,?		; Attribute to smear

WPUT_CSA_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ecx,edx,esi,edi,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
	 assume  es:nothing	; Tell the assembler about it
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; EDX	 = # rows ...

	 jecxz	 WPUT_CSA_EXIT	; Jump if no columns

	 and	 edx,edx	; Check # rows to output
	 jz	 short WPUT_CSA_EXIT ; Jump if no rows

	 mov	 esi,[ebp].WPUT_CSA_IBUF ; DS:ESI ==> input buffer
	 mov	 ah,[ebp].WPUT_CSA_ATTR ; Get the attribute to smear
WPUT_CSA_NEXTROW:
	 REGSAVE <ecx,edi>	; Save for a moment
WPUT_CSA_NEXTCOL:
	 lods	 DGROUP:[esi].LO ; Get the next character to output

S32	 stos	 es:[edi].ELO	; Store it along with the attribute

	 loop	 WPUT_CSA_NEXTCOL ; Jump if more character in this row

	 REGREST <edi,ecx>	; Restore

	 add	 edi,@NCOLS*2	; Skip to next row

	 dec	 edx		; Account for one less row
	 jnz	 WPUT_CSA_NEXTROW ; Jump if more rows to output
WPUT_CSA_EXIT:
	 REGREST <es,edi,esi,edx,ecx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 4+4+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_CSA endp			; End WPUT_CSA procedure
	 NPPROC  WPUT_SC -- Smear Character
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Smear character.

|

WPUT_SC_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
WPUT_SC_DESC dd  ?		; Offset of descriptor
WPUT_SC_CHAR db  ?,?		; Character to smear

WPUT_SC_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ecx,edx,edi,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
	 assume  es:nothing	; Tell the assembler about it
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; EDX	 = # rows ...

	 jecxz	 WPUT_SC_EXIT	; Jump if no columns

	 and	 edx,edx	; Check # rows to output
	 jz	 short WPUT_SC_EXIT ; Jump if no rows

	 mov	 al,[ebp].WPUT_SC_CHAR ; Get the character to smear
WPUT_SC_NEXTROW:
	 REGSAVE <ecx,edi>	; Save for a moment
@@:
S32	 stos	 es:[edi].LO	; Store character

	 inc	 edi		; Skip over attribute

	 loop	 @B		; Jump if more columns

	 REGREST <edi,ecx>	; Restore

	 add	 edi,@NCOLS*2	; Skip to next row

	 dec	 edx		; Account for one less row
	 jnz	 WPUT_SC_NEXTROW ; Jump if more rows to output
WPUT_SC_EXIT:
	 REGREST <es,edi,edx,ecx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 4+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_SC  endp			; End WPUT_SC procedure
	 NPPROC  WPUT_SA -- Smear Attribute
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Smear attribute.

|

WPUT_SA_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
WPUT_SA_DESC dd  ?		; Offset of descriptor
WPUT_SA_ATTR db  ?,?		; Attribute to smear

WPUT_SA_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ecx,edx,edi,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
	 assume  es:nothing	; Tell the assembler about it
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; EDX	 = # rows ...

	 jecxz	 WPUT_SA_EXIT	; Jump if no columns

	 and	 edx,edx	; Check # rows to output
	 jz	 short WPUT_SA_EXIT ; Jump if no rows

	 mov	 al,[ebp].WPUT_SA_ATTR ; Get the attribute to smear
WPUT_SA_NEXTROW:
	 REGSAVE <ecx,edi>	; Save for a moment
@@:
	 inc	 edi		; Skip over character

S32	 stos	 es:[edi].LO	; Store attribute

	 loop	 @B		; Jump if more columns

	 REGREST <edi,ecx>	; Restore

	 add	 edi,@NCOLS*2	; Skip to next row

	 dec	 edx		; Account for one less row
	 jnz	 WPUT_SA_NEXTROW ; Jump if more rows to output
WPUT_SA_EXIT:
	 REGREST <es,edi,edx,ecx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 4+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_SA  endp			; End WPUT_SA procedure
	 NPPROC  WPUT_SCA -- Smear Character and Attribute
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Smear character and attribute.

|

WPUT_SCA_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
WPUT_SCA_DESC dd ?		; Offset of descriptor
WPUT_SCA_CAT dw  ?		; Character/Attribute to smear

WPUT_SCA_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ecx,edx,edi,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
	 assume  es:nothing	; Tell the assembler about it
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; EDX	 = # rows ...

	 jecxz	 WPUT_SCA_EXIT	; Jump if no columns

	 and	 edx,edx	; Check # rows to output
	 jz	 short WPUT_SCA_EXIT ; Jump if no rows

	 mov	 ax,[ebp].WPUT_SCA_CAT ; Get the character/attribute
WPUT_SCA_NEXTROW:
	 REGSAVE <ecx,edi>	; Save for a moment

     rep stos	 es:[edi].ELO	; Smear character/attribute throughout the row

	 REGREST <edi,ecx>	; Restore

	 add	 edi,@NCOLS*2	; Skip to next row

	 dec	 edx		; Account for one less row
	 jnz	 WPUT_SCA_NEXTROW ; Jump if more rows to output
WPUT_SCA_EXIT:
	 REGREST <es,edi,edx,ecx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 4+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_SCA endp			; End WPUT_SCA procedure
	 NPPROC  WPUT_ASC -- Output Attribute, Smear Character
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Output attribute, smear character.

|

WPUT_ASC_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; Caller's EIP
WPUT_ASC_DESC dd ?		; Offset of descriptor
WPUT_ASC_IBUF dd ?		; Offset of input buffer
WPUT_ASC_CHAR db ?,?		; Character to smear

WPUT_ASC_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ecx,edx,esi,edi,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
	 assume  es:nothing	; Tell the assembler about it
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; EDX	 = # rows ...

	 jecxz	 WPUT_ASC_EXIT	; Jump if no columns

	 and	 edx,edx	; Check # rows to output
	 jz	 short WPUT_ASC_EXIT ; Jump if no rows

	 mov	 esi,[ebp].WPUT_ASC_IBUF ; DS:ESI ==> input buffer
	 mov	 ah,[ebp].WPUT_ASC_CHAR ; Get the character to smear
WPUT_ASC_NEXTROW:
	 REGSAVE <ecx,edi>	; Save for a moment
WPUT_ASC_NEXTCOL:
	 lods	 ds:[esi].LO	; Get the next attribute to output

	 xchg	 al,ah		; Swap character and attribute
S32	 stos	 es:[edi].ELO	; Store it along with the character
	 xchg	 al,ah		; Swap character and attribute

	 loop	 WPUT_ASC_NEXTCOL ; Jump if more attributes in this row

	 REGREST <edi,ecx>	; Restore

	 add	 edi,@NCOLS*2	; Skip to next row

	 dec	 edx		; Account for one less row
	 jnz	 WPUT_ASC_NEXTROW ; Jump if more rows to output
WPUT_ASC_EXIT:
	 REGREST <es,edi,esi,edx,ecx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 4+4+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_ASC endp			; End WPUT_ASC procedure
	 NPPROC  WPUT_SHD1 -- Display A Type 1 Shadow
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display a type 1 shadow (outside the existing window).

|

WPUT_SHD1_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; Caller's EIP
WPUT_SHD1_DESC dd ?		; Offset of descriptor

WPUT_SHD1_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,esi>	; Save registers

; Display the shadow below the window

	 mov	 esi,[ebp].WPUT_C_DESC ; DS:ESI ==> window descriptor

	 mov	 ax,ds:[esi].SROW ; Get the starting row
	 add	 ax,ds:[esi].NROW ; Plus # rows
	 mov	 W_SHD.SROW,ax	; Save as starting row of shadow

	 mov	 ax,ds:[esi].SCOL ; Get the starting col
	 inc	 ax		; Plus one to offset to the right
	 mov	 W_SHD.SCOL,ax	; Save as starting col of shadow

	 mov	 W_SHD.NROW,1	; Save as # rows

	 mov	 ax,ds:[esi].NCOL ; Get # cols
	 mov	 W_SHD.NCOL,ax	; Save as # cols

	 call	 WPUT_SHD1_SUB	; Read in attributes, set color

; Display the bottom shadow

	 mov	 al,'ß'         ; Smear an upper-half character
	 push	 ax		; Pass as character to smear
	 push	 offset ds:MSG_SHD1 ; Pass offset of local buffer
	 push	 offset ds:W_SHD ; Pass address of window descriptor
	 call	 WPUT_ASC	; Output the attributes, smear character

; Display the shadow to the right of the window

	 mov	 ax,ds:[esi].SROW ; Get the starting row
	 mov	 W_SHD.SROW,ax	; Save as starting row of shadow

	 mov	 ax,ds:[esi].SCOL ; Get the starting col
	 add	 ax,ds:[esi].NCOL ; Plus # cols
	 mov	 W_SHD.SCOL,ax	; Save as starting col of shadow

	 mov	 ax,ds:[esi].NROW ; Get # rows
	 mov	 W_SHD.NROW,ax	; Save as # rows

	 mov	 W_SHD.NCOL,1	; Save as # cols

	 call	 WPUT_SHD1_SUB	; Read in attributes, set color

	 mov	 W_SHD.NROW,1	; Save as # rows

	 mov	 al,'Ü'         ; Smear a lower-half character
	 push	 ax		; Pass as character to smear
	 push	 offset ds:MSG_SHD1 ; Pass offset of local buffer
	 push	 offset ds:W_SHD ; Pass address of window descriptor
	 call	 WPUT_ASC	; Output the attributes, smear character

	 inc	 W_SHD.SROW	; Skip to next row for full charcaters
	 mov	 ax,ds:[esi].NROW ; Get # rows
	 dec	 ax		; Less one to account for above offset
	 mov	 W_SHD.NROW,ax	; Save as # rows

	 mov	 al,'Û'         ; Smear a full character
	 push	 ax		; Pass as character to smear
	 push	 offset ds:MSG_SHD1 ; Pass offset of local buffer
	 push	 offset ds:W_SHD ; Pass address of window descriptor
	 call	 WPUT_ASC	; Output the attributes, smear character

	 REGREST <esi,eax>	; Restore

	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_SHD1 endp			; End WPUT_SHD1 procedure
	 NPPROC  WPUT_SHD1_SUB -- Read In Attributes, Set Shadow Color
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read in attributes, set shadow color

|

	 REGSAVE <eax,ecx,edx,esi> ; Save registers

; Read in the exising attributes

	 push	 offset ds:MSG_SHD1 ; Pass address of local buffer
	 push	 offset ds:W_SHD ; Pass address of window descriptor
	 call	 WGET_A 	; Input the attributes

; Set the foreground color of each attribute to black

	 mov	 ax,W_SHD.NROW	; Get # rows
	 mul	 W_SHD.NCOL	; Times # cols
	 movzx	 ecx,ax 	; Copy to count register
	 jecxz	 WPUT_SHD1_SUB_EXIT ; Jump if nothing to do

	 lea	 esi,MSG_SHD1	; DS:ESI ==> table of attributes
@@:
	 lods	 MSG_SHD1[esi]	; Get the next attribute

	 and	 al,@NIB1	; Isolate the background color
	 or	 al,@ATCFblack	; Set the foreground to black

	 mov	 DGROUP:[esi-1],al ; Save back

	 loop	 @B		; Jump if more attributes
WPUT_SHD1_SUB_EXIT:
	 REGREST <esi,edx,ecx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_SHD1_SUB endp		; End WPUT_SHD1_SUB procedure
	 NPPROC  WGET_A -- Input Attributes
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Input attributes.

|

WGET_A_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; Caller's EIP
WGET_A_DESC dd	 ?		; Offset of descriptor
WGET_A_IBUF dd	 ?		; Offset of output buffer

WGET_A_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ecx,edx,esi,edi,ds,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
	 assume  es:nothing	; Tell the assembler about it
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; EDX	 = # rows ...

	 jecxz	 WGET_A_EXIT	; Jump if no columns

	 and	 edx,edx	; Check # rows to input
	 jz	 short WGET_A_EXIT ; Jump if no rows

	 mov	 esi,[ebp].WGET_A_IBUF ; DS:ESI ==> input buffer
	 xchg	 esi,edi	; Swap the offsets

	 push	 es		; Save to swap

	 push	 ds		; Save to swap
	 pop	 es		; Restore to ES
	 assume  es:DGROUP	; Tell the assembler about it

	 pop	 ds		; Restore to DS
	 assume  ds:nothing	; Tell the assembler about it
WGET_A_NEXTROW:
	 REGSAVE <ecx,esi>	; Save for a moment
WGET_A_NEXTCOL:
	 inc	 esi		; Skip over character

S32	 movs	 <es:[edi].LO,ds:[esi].LO> ; Move the next attribute

	 loop	 WGET_A_NEXTCOL ; Jump if more attributes in this row

	 REGREST <esi,ecx>	; Restore

	 add	 esi,@NCOLS*2	; Skip to next row

	 dec	 edx		; Account for one less row
	 jnz	 WGET_A_NEXTROW ; Jump if more rows to input
WGET_A_EXIT:
	 REGREST <es,ds,edi,esi,edx,ecx> ; Restore
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 4+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WGET_A	 endp			; End WGET_A procedure
	 NPPROC  WGET_CA -- Input Characters and Attributes
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Input characters and attributes.

|

WGET_CA_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   EIP
WGET_CA_DESC dd  ?		; Offset of descriptor
WGET_CA_IBUF dd  ?		; Offset of output buffer

WGET_CA_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ecx,edx,esi,edi,ds,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
	 assume  es:nothing	; Tell the assembler about it
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; EDX	 = # rows ...

	 jecxz	 WGET_CA_EXIT  ; Jump if no columns

	 and	 edx,edx	; Check # rows to input
	 jz	 short WGET_CA_EXIT ; Jump if no rows

	 mov	 esi,[ebp].WGET_CA_IBUF ; DS:ESI ==> output buffer
	 xchg	 esi,edi	; Swap the offsets

	 push	 es		; Save to swap

	 push	 ds		; Save to swap
	 pop	 es		; Restore to ES
	 assume  es:DGROUP	; Tell the assembler about it

	 pop	 ds		; Restore to DS
	 assume  ds:nothing	; Tell the assembler about it
WGET_CA_NEXTROW:
	 REGSAVE <ecx,esi>	; Save for a moment

S32  rep movs	 <DGROUP:[edi].ELO,ds:[esi].ELO> ; Copy chars and attrs to buffer

	 REGREST <esi,ecx>	; Restore

	 add	 esi,@NCOLS*2	; Skip to next row

	 dec	 edx		; Account for one less row
	 jnz	 WGET_CA_NEXTROW ; Jump if more rows to input
WGET_CA_EXIT:
	 REGREST <es,ds,edi,esi,edx,ecx,eax> ; Restore
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 4+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WGET_CA  endp			; End WGET_CA procedure

PROG	 ends			; End PROG segment

	 MEND			; End SWAT_WIN module
