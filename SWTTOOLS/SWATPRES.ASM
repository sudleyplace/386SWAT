;' $Header:   P:/pvcs/misc/swttools/swatpres.asv   1.0   04 Sep 1992 18:29:50   HENRY  $

	 title	 SWATPRES -- 386SWAT presence detection
	 page	 58,122
	 name	 SWATPRES

COMMENT |		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1992 Qualitas, Inc.

Segmentation:  Group PGROUP:
	       Program segment NCODE,  byte-aligned,  public, class 'prog'
	       Data    segment NDATA,  dword-aligned, public, class 'data'

Link requirements:  Meant to be called from MSC 6.0 or from MASM code

Program derived from:  SWATRUN.ASM

Original code by:  Henry Groover, September, 1992.

Modifications by:  None.

|

.386p

.xlist
	Include MASM.INC
	Include 386.INC
	Include PTR.INC
	Include VCPI.INC
	Include DOSCALL.INC
	Include CPUFLAGS.INC
	Include IOCTL.INC
.list

PGROUP group NCODE,NDATA

NCODE	 segment use16 byte public 'prog' ; Start NCODE segment
NCODE	 ends			; End NCODE segment

NDATA	 segment use16 dword public 'prog' ; Start NDATA segment
NDATA	 ends			; End NDATA segment

NDATA	 segment
	 assume  ds:PGROUP

OLDINT67_VEC	 dd	?	; Previous holder of Int 67h vector

	 public  MAXNAME,SWATNAME
MAXNAME  db	 '\dev\386max$$',0
SWATNAME db	 '\dev\386swat$',0

NDATA	 ends

NCODE	 segment
	 assume  cs:PGROUP

	 NPPROC  LCL_INT67 -- Local Int 67h handler
	 assume  ds:nothing,es:nothing,ss:nothing,fs:nothing,gs:nothing
COMMENT|

We install this handler in case we're in V86 mode to ensure that
we don't send the system south by checking for 386SWAT.

|

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing,fs:nothing,gs:nothing

LCL_INT67 endp			; End LCL_INT67 procedure

	 NPPROC CPUTYPE -- Ensure we have at least an 80386
	 assume ds:nothing,es:nothing,ss:nothing,fs:nothing,gs:nothing
COMMENT|

Return CF=1 if CPU is not a 386 or better.

AX is destroyed.

|
.8086
	 push	 sp		; Push SP
	 pop	 ax		; Pop SP at point of PUSH SP
	 cmp	 ax,sp		; Was it decremented before or after the push?
	 jne	 short CPUTYPE_FAIL ; Isn't a 286 or 386
.286
	 pushf			; Save flags around test

	 push	 mask $IOPL	; Attempt to set IOP bits
	 popf			; Load into FLAGS
	 pushf			; Put it back
	 pop	 ax		; See what stuck

	 popf			; Restore original flags

	 test	 ax,mask $IOPL	; Priv bits won't stick in 286
	 jnz	 short CPUTYPE_EXIT ; Jump if they stuck (note CF=0)
.8086
CPUTYPE_FAIL:
	 stc			; Indicate failure

CPUTYPE_EXIT:
	 ret			; Return to caller
DOT386 p
	 assume  ds:nothing,es:nothing,ss:nothing,fs:nothing,gs:nothing

CPUTYPE  endp			; End CPUTYPE procedure

	 NPPROC  OPEN_DEV -- Check for device existence
	 assume  ds:PGROUP,es:nothing,ss:nothing,fs:nothing,gs:nothing
COMMENT|

Attempt to open the file at PGROUP:DX and verify that it's an
IOCTL device.  If successful, close it and return CF=0, otherwise
return CF=1.

|
	 REGSAVE <ax,bx,dx>	; Save

	 sub	 al,al		; Set compatible sharing mode
	 DOSCALL @OPENF2	; Open file
	 jc	 short OPEN_DEV_EXIT ; Jump if open failed

	 mov	 bx,ax		; Copy to handle register
	 mov	 al,0		; Function code to get device information
	 DOSCALL @IOCTL2	; Get device information into DX
	 jc	 short OPEN_DEV_CEXIT ; Jump if call failed

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jnz	 short OPEN_DEV_CEXIT ; Jump if so (note CF=0)

	 stc			; Indicate failure
OPEN_DEV_CEXIT:
	 pushf			; Save flags
	 DOSCALL @CLOSF2	; Close handle in BX
	 popf			; Restore
OPEN_DEV_EXIT:
	 REGREST <dx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing,fs:nothing,gs:nothing

OPEN_DEV endp			; End OPEN_DEV procedure

	 FPPROC  _SWAT_PRESENT -- Determine If 386SWAT is present
	 assume  ds:nothing,es:nothing,ss:nothing,fs:nothing,gs:nothing
COMMENT|

Determine whether or not SWAT is present.  To check for SWAT, we
need to fulfill all these prerequsites:
1. CPU is 386 or higher.
2. 386MAX$$ or 386SWAT$ is present

If 386MAX$$ is present, we install our local Int 67h handler in case
EMS=0.

To check for SWAT, we make a VCPI debugger API call.

On exit:

AX	 =	 version of VCPI debugger spec if 386SWAT present
	 =	 0 if not
CF	 =	 1 if 386SWAT present
CF	 =	 0 if not

|

.8086
	 REGSAVE <bx,cx,dx,ds,es> ; Save

	 call	 CPUTYPE	; CF=0 if at least a 386
	 jc	 short SWATPRES_ERR ; Jump if not
DOT386 p

	 push	 cs		; Address PGROUP
	 pop	 ds		; ...without generating a fixup
	 assume  ds:PGROUP	; Tell the assembler

	 mov	 al,67h 	; Get this one's vector
	 DOSCALL @GETINT	; ES:BX ==> current holder of Int 67h
	 assume  es:nothing	; Tell the assembler

	 mov	 OLDINT67_VEC.VOFF,bx ; Save offset
	 mov	 OLDINT67_VEC.VSEG,es ; ...  segment

	 lea	 dx,PGROUP:MAXNAME ; IOCTL name '386MAX$$'
	 call	 OPEN_DEV	; Return CF=0 if MAX present
	 jnc	 short @F	; Jump if not

	 lea	 dx,PGROUP:SWATNAME ; IOCTL name '386SWAT$'
	 call	 OPEN_DEV	; Return CF=0 if SWAT present
	 jc	 short SWATPRES_ERR ; Jump if not

	 jmp	 short SWATPRES_VCPICALL ; Try the VCPI call

@@:
	 mov	 al,67h 	; Set vector for this one
	 DOSCALL @SETINT,LCL_INT67 ; Install new Int 67h handler

SWATPRES_VCPICALL:
	 VCPICALL @VCPI_DPRES	; Return AH=0 if successful, BX=version

	 REGSAVE <ax,ds>	; Save

	 lds	 dx,OLDINT67_VEC ; Get old vector to restore
	 assume  ds:nothing	; Tell the assembler

	 mov	 al,67h 	; Restore this one
	 DOSCALL @SETINT	; Restore previous Int 67h vector

	 REGREST <ds,ax>	; Restore
	 assume  ds:PGROUP	; Tell the assembler

	 cmp	 ah,0		; Did the call succeed?
	 mov	 ax,bx		; Get debugger interface spec version
	 je	 short SWATPRES_EXIT ; Join common exit if OK

.8086
SWATPRES_ERR:
	 sub	 ax,ax		; Indicate failure
SWATPRES_EXIT:
	 REGREST <es,ds,dx,cx,bx> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler

	 cmp	 ax,1		; Clear CF if SWAT present
	 cmc			; Set CF for presence

	 ret			; Return to caller
DOT386 p
	 assume  ds:nothing,es:nothing,ss:nothing,fs:nothing,gs:nothing

_SWAT_PRESENT endp		; End SWAT_PRESENT procedure

NCODE	 ends

	 MEND			; End SWATPRES module

