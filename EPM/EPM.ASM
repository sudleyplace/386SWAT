	 title	 EPM -- Enter/Exit Protected Mode
	 page	 58,122
	 name	 EPM

COMMENT|		Module Specifications

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Group DGROUP:
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Tail    segment DTAIL, dword-aligned, public, class 'data'
	       Group SGROUP:
	       Stack   segment STACK, para-aligned,  stack,  class 'stack'

Program derived from:  None.

Original code by:  Bob Smith, March, 1994.

Modifications by:  None.

|
.386p
.xlist
	 include 386.INC
	 include 8255.INC
	 include 8259.INC
	 include ALLMEM.INC
	 include ASCII.INC
	 include BIOSCONF.INC
	 include CMOS.INC
	 include CPUFLAGS.INC
	 include DOSCALL.INC
	 include DPMI.INC
	 include DTE.INC
	 include IOCTL.INC
	 include MASM.INC
	 include OPEN.INC
	 include PTR.INC
	 include VCPI.INC
	 include XMS.INC
.list

PGROUP	 group	 CODE
DGROUP	 group	 DATA,DTAIL
SGROUP	 group	 STACK
PSPGRP	 group	 PSP_SEG


@8253_XCIO equ	 4Fh		; Non-cached I/O port (MC)


@BIT7	 equ	 10000000b	; Bit mask


FIJMP	 macro	 LAB,SEL

	 db	 0EAh		; Opcode for immediate far jump
	 dw	 LAB,SEL	; ...to this label and selector

	 endm			; FIJMP

SETRPL3  macro	 SEL

	 mov	 ax,SEL 	; Get selector
	 or	 ax,RPL3	; Set RPL3
	 mov	 SEL,ax 	; ...

	 endm			; SETRPL3



STACK	 segment use16 para stack 'stack' ; Start STACK segment
	 assume  ss:SGROUP

	 public  PMSTK,PMSTKZ
PMSTK	 dw	 100h dup (?)	; Local stack
PMSTKZ	 label	 word		; Top of stack

	 public  LCLSTK,LCLSTKZ
LCLSTK	 dw	 100h dup (?)	; Local stack
LCLSTKZ  label	 word		; Top of stack

STACK	 ends			; End STACK segment


; Define dummy segment to force segment order (mainly we want DTAIL to be last)

CODE	 segment use16 byte public 'prog' ; Start CODE segment
CODE	 ends			; End CODE segment


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

XDTE_STR struc			; Extende DTE for RM and VCPI

	 db	 (size DTE_STR) dup (0) ; 00-3F INT 15h/89h (initialized to 0)
DTE_PMCS dq	 0		; 40:  1st selector
DTE_PMDS dq	 0		; 48:  2nd ...
DTE_PMES dq	 0		; 50:  3rd ...
DTE_TSS  dq	 0		; 58:  Task ...
DTE_4GB  dq	 0		; 60:  All memory ...
DTE_LDT  dq	 0		; 68:  LDT ...
DTE_ALIAS dq	 0		; 70:  Code alias
DTE_CS3  dq	 0		; 78:  Code selector at PL3
DTE_SS3  dq	 0		; 80:  Stack selector at PL3, big
DTE_DS0  dq	 0		; 88:  Data selector at PL0, small

;**********DEBUG START**********
DTE_SWAT dq	 20 dup (0)	; 90+: Room for SWAT
;***********DEBUG END***********

XDTE_STR ends

	 public  LCLGDT
	 align	 4		; Ensure dword-aligned
LCLGDT	 XDTE_STR <>		; Protected mode DTE structure for RM and VCPI


IDT_MAC  macro	 HL
	 IDT_STR <PGROUP:INTPROC&HL,DTE_CS,,CPL0_INTR3 or DPL3,0>
	 endm			; IDT_MAC

	 public  LCLIDT
	 align	 4		; Ensure dword-aligned
LCLIDT	 label	 qword		; Interrupt descriptor table

@HEX	 equ	 <0123456789ABCDEF> ; Binary to hex translate table
CNT	 =	 0
.xlist
	 rept	 100h		; Define all interrupts

; Extract high- and low-order digits from CNT in ASCII hex as L and H
; and catenate them as a two-character hex representation of CNT in N

H	 substr  @HEX,1+(CNT/16),1
L	 substr  @HEX,1+(CNT mod 16),1
HL	 catstr  H,L

	 IDT_MAC %HL
CNT	 =	 CNT+1

	 endm			; REPT 100h
.list
	 public  LCLIDT_LEN
LCLIDT_LEN equ	 $-LCLIDT	; Length of the IDT


	 public  EPMTAB
	 align	 4		; Ensure dword-aligned
EPMTAB	 VCPEPM_STR <>		; Enter Protected Mode structure

	 public  LCLTSS
	 align	 4		; Ensure dword-aligned
LCLTSS	 TSS_STR <>		; Local TSS

	 public  CON64K,CON1M
CON64K	 dd	 64*1024	; Constant 64 K
CON1M	 dd	 1024*1024	; ...	    1 M

	 public  LDTE_CS3,LDTE_SS3
LDTE_CS3 dw	 DTE_CS3 or RPL3,0 ; Code selector at RPL3 padded to dword
LDTE_SS3 dw	 DTE_SS3 or RPL3,0 ; Stack ...

	 public  XMSDRV_VEC,DPMIDRV_VEC,INT_VEC
XMSDRV_VEC dd	 ?		; XMS driver address
DPMIDRV_VEC dd	 ?		; DPMI driver address
INT_VEC  dd	 ?		; Reflected interrupt address

	 public  PHYSIZE,CMOSIZE,MAXSIZE
PHYSIZE  dd	 ?		; Top of physical extended memory in KB (fn88)
CMOSIZE  dd	 ?		; Top of physical extended memory in KB (CMOS)
MAXSIZE  dd	 ?		; Top of physical extended memory in KB (larger)

	 public  LaCODE,LaDATA,LaSTK,LaCR3,LaPTE,PaCR3,NEXTPTE
LaCODE	 dd	 ?		; Linear address of our code segment
LaDATA	 dd	 ?		; ...			data
LaSTK	 dd	 ?		; ...			stack
LaCR3	 dd	 ?		; ...			CR3
LaPTE	 dd	 ?		; ...			PTEs
PaCR3	 dd	 ?		; Physical		CR3
NEXTPTE  dd	 ?		; Offset of next available PTE in PDT

	 public  OLDINT21_VEC,VMSTK_VEC,VMCSIP_VEC
OLDINT21_VEC dd  ?		; Original INT 21h handler
VMSTK_VEC dd	 ?		; Save area for VM SS:SP
VMCSIP_VEC dd	 ?		; ...		   CS:IP

	 public  VCPI_FVEC
VCPI_FVEC df	 ?		; Address of VCPI PM services

	 public  XMS0LEN
XMS0LEN  dw	 ?		; XMS zero-length handle

	 public  IDTR_REAL
IDTR_REAL df	 4*256-1	; RM IDTR

	 public  DPMI_HPDA
DPMI_HPDA dw	 ?		; DPMI HPDA size in paras

	 public  PMONSTK_FVEC
PMONSTK_FVEC label fword
	 dd	 ?		; Stack ending offset
	 dw	 DTE_SS 	; Stack selector

	 public  HPDASEG
HPDASEG  dw	 ?		; Segment of Host Private Data Area

	 public  NEXTSEG
NEXTSEG  dw	 ?		; Next available segment

	 public  PSPSEG
PSPSEG	 dw	 ?		; Segment of PSP

LCL_REC  record  $LCL_VCPIPREF:1,   \
		 $LCL_VCPI:1,	    \
		 $LCL_DPMI:1,	    \
		 $LCL_XMS:1,	    \
		 $LCL_RM:1,	    \
		 $LCL_MC:1,	    \
		 $LCL_DPMIERR:1,    \
		 $LCL_RSVD:9

@LCL_VCPIPREF equ (mask $LCL_VCPIPREF)	; Prefer VCPI over DPMI if VM
@LCL_VCPI equ	 (mask $LCL_VCPI)	; VCPI services present
@LCL_DPMI equ	 (mask $LCL_DPMI)	; DPMI ...
@LCL_XMS  equ	 (mask $LCL_XMS)	; XMS ...
@LCL_RM   equ	 (mask $LCL_RM) 	; Starting from RM
@LCL_MC   equ	 (mask $LCL_MC) 	; System is MC Architecture
@LCL_DPMIERR equ (mask $LCL_DPMIERR)	; A DPMI error has occurred

	 public  LCL_FLAG
LCL_FLAG LCL_REC <>		; Local flags

	 public  ERRCODE
ERRCODE  db	 0		; Error code to return to DOS

	 public  DPMITERM
DPMITERM db	 0		; 1 = terminating DPMI client

	 public  EMMNAME
EMMNAME  db	 'EMMXXXX0',0   ; EMS service provider name

	 public  IBV0,IBV1
IBV0	 db	 @IMRBASE	; Master IMR base
IBV1	 db	 @IMR2BASE	; Slave ...

	 public  OLDIMR1,OLDIMR2
OLDIMR1  db	 ?		; Save area for original master IMR
OLDIMR2  db	 ?		; ...			 slave	IMR

	 public  MSG_HELP
MSG_HELP db	 'EPM      -- Enter/Exit Protected Mode,',CR,LF
	 db	 CR,LF
	 db	 'Syntax:  EPM [/v]',CR,LF
	 db	 CR,LF
	 db	 'where the optional parameter /v says to use VCPI services',CR,LF
	 db	 'in preference to DPMI services to enter PM when both',CR,LF
	 db	 'services are present.  If no parameter is specified, and',CR,LF
	 db	 'both services are present, DPMI is used.',CR,LF
	 db	 EOS

	 public  MSG_RM,MSG_DPMI,MSG_VCPI
MSG_RM	 db	 'Starting from RM.',CR,LF,0
MSG_DPMI db	 'Starting from VM, using DPMI.',CR,LF,0
MSG_VCPI db	 'Starting from VM, using VCPI.',CR,LF,0

	 public  MSG_SUCCESS,MSG_PRESS
MSG_SUCCESS db	 'We made it to PM.',CR,LF,0
MSG_PRESS db	 'Press any key to continue...',CR,LF,0

DATA	 ends			; End DATA segment


; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

DTAIL	 segment use16 para public 'data' ; Start DTAIL segment
	 assume  ds:DGROUP

	 public  ZTAIL
ZTAIL	 label	 byte

DTAIL	 ends			; End DTAIL segment


PSP_SEG  segment use16 para at 0 ; Start PSP_SEG segment
	 assume  cs:PSPGRP,ds:PSPGRP

	 include PSP.INC	; Define PSP area

PSP_SEG  ends			; End PSP_SEG segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

; For convenience, we define these data items here
; so we can address them using CS: override.

	 public  CODESEG,DATASEG,STACKSEG,SEL_DATA,SEL_ALIAS,SEL_4GB
CODESEG  dw	 seg PGROUP	; PGROUP segment
DATASEG  dw	 seg DGROUP	; DGROUP segment
STACKSEG dw	 seg SGROUP	; SGROUP segment
SEL_DATA dw	 DTE_DS    or RPL3 ; DGROUP data selector at RPL3
SEL_ALIAS dw	 DTE_ALIAS or RPL3 ; PGROUP ...
SEL_4GB  dw	 DTE_4GB   or RPL3 ; AGROUP ...

	 NPPROC  EPM -- Enter/Exit Protected Mode
	 assume  ds:PSPGRP,es:PSPGRP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enter/exit Protected mode

Starting from either Real Mode (RM), or Virtual Mode (VM) using either
VCPI or DPMI, this routine enters Protected Mode and exits upon
pressing a key.  While in PM, this routine also handles hardware (HW)
interrupts, reflecting them to RM or VM as appropriate.

This routine can be used as a model for the process of handling PM in
the several different available contexts.

Command line argument:

/V	 to prefer VCPI over DPMI if starting from VM

|

	 mov	 ax,seg DGROUP	; Get segment of DGROUP
	 mov	 ds,ax		; Address it
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 PSPSEG,es	; Save segment of PSP

	 mov	 es,ax		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 lea	 bx,DGROUP:ZTAIL[16-1] ; Get offset of end of data
				; ...rounded up to para boundary
	 shr	 bx,4-0 	; Convert from bytes to paras
	 add	 ax,bx		; Add to last segment to get next available seg
	 mov	 NEXTSEG,ax	; Save for later use

	 mov	 VMSTK_VEC.VSEG,ss ; Save for DPMI termination

; Check for command line arguments

	 call	 CHECK_ARGS	; Check 'em out
	 jc	 near ptr EPM_EXIT ; Jump if nothing suitable

; Check for special systems

	 call	 CHECK_SYS	; Check 'em out

; Check for physical memory

	 call	 CHECK_PHYS	; See how much physical memory there is

; Check for XMS driver

	 call	 CHECK_XMSDRV	; See if one is present -- if so,
				; allocate a zero-length handle
; Check for the starting mode

	 smsw	 ax		; Get the MSW
	 and	 ax,mask $PE	; Isolate the PE bit (note AH=0)
	 setz	 al		; AL = 1 if RM, 1 if VM
	 shl	 ax,$LCL_RM	; Shift to LCL_RM bit
	 or	 LCL_FLAG,ax	; Mark as present if appropriate

	 test	 LCL_FLAG,@LCL_RM ; Are we starting from RM?
	 jnz	 short @F	; Jump if so

	 call	 CHECK_VCPI	; See if VCPI host is present
	 call	 CHECK_DPMI	; See if DPMI host is present
	 call	 CHECK_PREF	; Resolve VCPI vs. DPMI preferences
	 jc	 near ptr EPM_EXIT ; Jump if nothing suitable
@@:

; If we're using VCPI services, setup data areas for page tables, etc.
; Note that this program does not enable paging if we're starting
; from RM.  If that's desired, call the same SETUP_VCPI routine and
; skip the Lin-to-Phys calls, and ignore the VCPI GPMI call.

	 test	 LCL_FLAG,@LCL_VCPI ; Are we using VCPI services?
	 jz	 short @F	; Jump if not

	 call	 SETUP_VCPI	; Setup data areas for VCPI
	 jc	 near ptr EPM_EXIT ; Jump if something went wrong
@@:

; If we're not using DPMI, we also need to setup various tables
; such as the GDT, IDT, and TSS.

	 test	 LCL_FLAG,@LCL_DPMI ; Are we using DPMI?
	 jnz	 short @F	; Jump if so

	 call	 SETUP_TAB	; Setup GDT, IDT, and TSS
@@:

; At this point, everything should be setup to enter PM

	 call	 ENTER_PM	; Enter PM
	 jc	 short EPM_EXIT ; Jump if something went wrong

	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing

	 sti			; Enable interrupts

; All HW interrupts are automatically reflected to the original mode

; If we started from RM or VCPI (but not DPMI), switch to PL3
; so we're at the same level as DPMI

	 test	 LCL_FLAG,@LCL_DPMI ; Are we using DPMI?
	 jnz	 short EPM_PL3	; Jump if so (already at PL3)

; Set data selectors to RPL3

	 SETRPL3 ds		; Set to RPL3
	 SETRPL3 es		; ...
	 SETRPL3 fs		; ...
	 SETRPL3 gs		; ...

	 mov	 eax,esp	; Copy current stack pointer

	 push	 LDTE_SS3.EDD	; Pass SS:ESP
	 push	 eax		; ...

	 pushfd 		; Pass EFL

	 lea	 eax,PGROUP:EPM_PL3 ; Get EIP

	 push	 LDTE_CS3.EDD	; Pass CS:EIP
	 push	 eax		; ...

	 iretd			; Continue at PL3

EPM_PL3:

; Display message about how we got here

	 test	 LCL_FLAG,@LCL_RM ; Are we starting from RM?
	 lea	 si,MSG_RM	; Assume so
	 jnz	 short @F	; Jump if so

	 test	 LCL_FLAG,@LCL_DPMI ; Are we using DPMI?
	 lea	 si,MSG_DPMI	; Assume so
	 jnz	 short @F	; Jump if so

	 lea	 si,MSG_VCPI	; We must be using VCPI
@@:
	 call	 DISP_ASCIIZ	; Display ASCIIZ string at DS:SI

; Display message of success

	 lea	 si,MSG_SUCCESS ; DS:SI ==> message to output
	 call	 DISP_ASCIIZ	; Display ASCIIZ string at DS:SI

; Display key press message

	 lea	 si,MSG_PRESS	; DS:SI ==> message to output
	 call	 DISP_ASCIIZ	; Display ASCIIZ string at DS:SI

	 mov	 ah,0		; Function code to wait for keystroke
	 int	 16h		; Request keyboard service

; Place PM code here








	 call	 EXIT_PM	; Exit from PM
EPM_EXIT:
	 call	 CLEANUP	; Cleanup before exiting

	 mov	 al,ERRCODE	; Get error code (if any)
	 DOSCALL @EXITRC	; Return to DOS with error code in AL

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EPM	 endp			; End EPM procedure
	 NPPROC  DISP_ASCIIZ -- Display ASCIIZ String
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display ASCIIZ string.

This routine is bimodal.

On entry:

DS:SI	 ==>	 ASCIIZ string to display

|

	 REGSAVE <ax,dx,si>	; Save registers
@@:
	 lods	 ds:[si].LO	; Get next character

	 cmp	 al,0		; Izit EOL?
	 je	 short @F	; Jump if so

	 mov	 dl,al		; Copy to output register
	 DOSCALL @DCONIO	; Output character in DL

	 jmp	 short @B	; Go around again

@@:
	 REGREST <si,dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_ASCIIZ endp		; End DISP_ASCIIZ procedure
	 NPPROC  CLEANUP -- Cleanup Before Exiting
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Cleanup before exiting

|

	 REGSAVE <ax,dx,ds>	; Save registers

; If we allocated a zero length XMS handle, free it now

	 test	 LCL_FLAG,@LCL_XMS ; Is XMS driver present?
	 jz	 short @F	; Jump if not

	 mov	 dx,XMS0LEN	; Get zero-length handle
	 mov	 ah,@XMS_RELXMB ; Function code to release XMS memory
	 call	 XMSDRV_VEC	; Request XMS service
				; Ignore error return
@@:

; If we hooked INT 21h, restore it now

	 cmp	 OLDINT21_VEC,0 ; Did we hook it?
	 je	 short @F	; Jump if not

	 mov	 al,21h 	; Restore this one
	 lds	 dx,OLDINT21_VEC ; DS:DX ==> original handler
	 assume  ds:nothing	; Tell the assembler about it

	 DOSCALL @SETINT	; Restore original handler
@@:
	 REGREST <ds,dx,ax>	; Restore
	 assume  ds:DGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLEANUP  endp			; End CLEANUP procedure
	 NPPROC  CHECK_ARGS -- Check For Command Line Arguments
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for command line arguments

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <ax,dx,si,es>	; Save registers

	 mov	 es,PSPSEG	; Address the PSP
	 assume  es:PSPGRP	; Tell the assembler about it

	 lea	 si,PSP_PARM_STRING ; ES:SI ==> command line
CHECK_ARGS_NEXT:
	 call	 SKIP_WHITE	; Skip over white space at ES:SI
	 lods	 es:[si].LO	; Get next command line character

	 cmp	 al,CR		; Izit EOL?
	 je	 short CHECK_ARGS_EXIT ; Jump if so

	 cmp	 al,'/'         ; Izit a switch character?
	 jne	 short CHECK_ARGS_ERR ; Jump if not

	 call	 SKIP_WHITE	; Skip over white space at ES:SI
	 lods	 es:[si].LO	; Get next command line character

	 call	 LOWERCASE	; Convert AL to lowercase

	 cmp	 al,'v'         ; Prefer VCPI over DPMI?
	 je	 short CHECK_ARGS_VCPI ; Jump if so
CHECK_ARGS_ERR:
	 DOSCALL @STROUT,MSG_HELP ; Give 'em some help

	 stc			; Mark as in error

	 jmp	 short CHECK_ARGS_EXIT ; Join common exit code

CHECK_ARGS_VCPI:
	 or	 LCL_FLAG,@LCL_VCPIPREF ; Mark as such

	 jmp	 short CHECK_ARGS_NEXT ; Go around again

	 clc			; Mark as successful
CHECK_ARGS_EXIT:
	 REGREST <es,si,dx,ax>	; Restore
	 assume  es:DGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ARGS endp 		; End CHECK_ARGS procedure
	 NPPROC  SKIP_WHITE -- Skip Over White Space
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over white space

On entry:

ES:SI	 ==>	 ASCII text

On exit:

AL	 =	 non-white space character
ES:SI	 ==>	 (updated)

|

@@:
	 lods	 es:[si].LO	; Get next character

	 cmp	 al,' '         ; Izit white space?
	 je	 short @B	; Jump if so

	 cmp	 al,TAB 	; izit white space?
	 je	 short @B	; Jump if so

	 dec	 si		; Back off to last non-white space

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SKIP_WHITE endp 		; End SKIP_WHITE procedure
	 NPPROC  LOWERCASE -- Convert AL To Lowercase
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convret AL to lowercase

On entry:

AL	 =	 character to convert

On exit:

AL	 =	 converted character

|

	 cmp	 al,'A'         ; Izit below lower limit?
	 jb	 short @F	; Jump if so

	 cmp	 al,'Z'         ; Izit above upper limit?
	 ja	 short @F	; Jump if so

	 add	 al,'a'-'A'     ; Convert to lowercase
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOWERCASE endp			; End LOWERCASE procedure
	 NPPROC  CHECK_SYS -- Check For Special Systems
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for special systems

|

	 REGSAVE <ax,bx,es>	; Save registers

; For the moment, the only special system is MC Architecture

	 mov	 ah,0C0h	; Attempt to read configuration record
	 stc			; Assume failure
	 int	 15h		; Request BIOS service
	 assume  es:nothing	; Tell the assembler about it
	 jc	 short CHECK_SYS_XMC ; Jump if error

	 cmp	 ah,80h 	; Check for error return
	 je	 short CHECK_SYS_XMC ; Jump if error

	 cmp	 ah,86h 	; Check for error return
	 je	 short CHECK_SYS_XMC ; Jump if error

	 test	 es:[bx].CFG_PARMS,@CFG_MCA ; Izit a Micro Channel Architecture?
	 jz	 short CHECK_SYS_XMC ; Not this time

	 or	 LCL_FLAG,@LCL_MC ; Mark as present
CHECK_SYS_XMC:
	 REGREST <es,bx,ax>	; Restore
	 assume  es:DGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SYS endp			; End CHECK_SYS procedure
	 NPPROC  CHECK_XMSDRV -- Check On XMS Driver
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on XMS driver.

We need to allocate a zero-length handle (and free it upon exit) as
some memory managers which provide XMS services do not switch to VM
until some request occurs to force them to.  By making such a request,
our subsequent code can correctly determine whether we're in a RM or
VM context, and thus whether or not we should enter PM from RM or from
VM (and thus use VCPI or DPMI).

|

	 REGSAVE <ax,bx,dx,es>	; Save registers

	 mov	 ax,@XMS_PRES	; Function code to detect XMS presence
	 int	 2Fh		; Request multiplexor service

	 cmp	 al,80h 	; Izit present?
	 jne	 short CHECK_XMSDRV_EXIT ; Jump if not

	 mov	 ax,@XMS_ADDR	; Function code to get XMS driver entry point
	 int	 2Fh		; Request multiplexor service
	 assume  es:nothing	; Tell the assembler about it

	 mov	 XMSDRV_VEC.VSEG,es ; Save for later use
	 mov	 XMSDRV_VEC.VOFF,bx ; ...

	 xor	 dx,dx		; Size in kilobytes to allocate
	 mov	 ah,@XMS_GETXMB ; Function code to allocate XMS memory
	 call	 XMSDRV_VEC	; Request XMS service

	 mov	 XMS0LEN,dx	; Save handle #

	 cmp	 ax,1		; Did it work?
	 jne	 short CHECK_XMSDRV_EXIT ; Jump if not

	 or	 LCL_FLAG,@LCL_XMS ; Mark as present
CHECK_XMSDRV_EXIT:
	 REGREST <es,dx,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_XMSDRV endp		; End CHECK_XMSDRV procedure
	 NPPROC  CHECK_PHYS -- See How Much Physical Memory There Is
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See how much physical memory there is.

|

	 REGSAVE <eax>		; Save register

; Get size of extended memory from BIOS

	 mov	 ah,88h 	; Function code to get size of extended memory
	 int	 15h		; Request service, result in AX in 1KB blocks

	 movzx	 eax,ax 	; Zero to use as dword
	 and	 eax,not (4-1)	; Round down to a multiple of four
	 add	 eax,1024	; Plus first megabyte
	 mov	 PHYSIZE,eax	; Save for later use

; Get size of extended memory from CMOS

	 cli			; Disallow interrupts
	 xor	 eax,eax	; Zero to use as dword

	 mov	 al,@CMOS_EXTHI ; Get extended memory size, high-order byte
	 out	 @CMOS_CMD,al	; Tell the CMOS about it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 in	 al,@CMOS_DATA	; Get the data byte
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 mov	 ah,al		; Copy to high-order byte

	 mov	 al,@CMOS_EXTLO ; Get extended memory size, low-order byte
	 out	 @CMOS_CMD,al	; Tell the CMOS about it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 in	 al,@CMOS_DATA	; Get the data byte
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 sti			; Allow interrupts

	 add	 eax,1024	; Plus first megabyte

	 mov	 CMOSIZE,eax	; Save for later use

; Save the larger for later use

	 cmp	 eax,PHYSIZE	; Is CMOS larger?
	 jae	 short @F	; Jump if so

	 mov	 eax,PHYSIZE	; Use PHYSIZE
@@:
	 mov	 MAXSIZE,eax	; Save for later use
CHECK_PHYS_EXIT:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PHYS endp 		; End CHECK_PHYS procedure
	 NPPROC  CHECK_DPMI -- Check On DPMI Services
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on DPMI services

|

	 pusha			; Save all GP registers
	 push	 es		; Save

	 mov	 ax,@DPMI_PRES	; Function code to detect DPMI servcices
	 int	 2Fh		; Request multiplexor services
	 assume  es:nothing	; Tell the assembler about it
				; On return
				;   AX	  =   0 (if present)
				;   BX	  =   flags -- Bit 0: 1 = 32-bit apps supported
				;   CL	  =   CPU type (02 = 286, 03 = 386, 04 = 486, etc.)
				;   DH	  =   DPMI major version # (in decimal)
				;   DL	  =   ...  minor ...
				;   SI	  =   # paras in host private data area
				;   ES:DI ==> VM -> PM entry point
	 and	 ax,ax		; Izit present?
	 jnz	 short CHECK_DPMI_EXIT ; Jump if not

	 mov	 DPMIDRV_VEC.VSEG,es ; Save for later use
	 mov	 DPMIDRV_VEC.VOFF,di ; ...
	 mov	 DPMI_HPDA,si	; ...
	 or	 LCL_FLAG,@LCL_DPMI ; Mark as present
CHECK_DPMI_EXIT:
	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it
	 popa			; ...

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DPMI endp 		; End CHECK_DPMI procedure
	 NPPROC  CHECK_WIN3 -- See If Windows 3.x Is Active
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if Windows 3.x is active.

On exit:

CF	 =	 1 if Windows is active
	 =	 0 if not

|

	 REGSAVE <ax,dx>	; Save registers

	 mov	 ax,1600h	; Code for Windows/386 Installation Check
	 int	 2Fh		; Request multiplexor service
				; AL = 00h if not running
				; AL = 80h if not running
				; AL = 01h if Version 2.xx running
				; AL = FFh if Version 2.xx running
				; AL = Major version #, AH = Minor ...

	 test	 al,7Fh 	; Test for 00h and 80h
	 jz	 short CHECK_WIN3_EXIT ; Jump if not running (note CF=0)

	 cmp	 al,01h 	; Izit 2.xx?
	 je	 short CHECK_WIN3_EXIT ; Jump if so (note CF=0)

	 cmp	 al,0FFh	; Izit the other 2.xx?
	 je	 short CHECK_WIN3_EXIT ; Jump if so (note CF=0)

	 stc			; Mark as active
CHECK_WIN3_EXIT:
	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_WIN3 endp 		; End CHECK_WIN3 procedure
	 NPPROC  CHECK_EMS -- Check On EMS Services
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on EMS services

On exit:

CF	 =	 0 if EMS is present
	 =	 1 if not

|

	 REGSAVE <ax,bx,dx>	; Save

	 mov	 al,@OPEN_R	; Code for read-only access
	 lea	 dx,EMMNAME	; DS:DX ==> EMS service name
	 DOSCALL @OPENF2	; Open it
	 jc	 short CHECK_EMS_EXIT ; Jump if no luck (note CF=1)

	 mov	 bx,ax		; Save handle

	 mov	 al,0		; Code to get device info
	 DOSCALL @IOCTL2	; Read device info
	 pushf			; Save CF from call
	 DOSCALL @CLOSF2	; Close the file
	 popf			; Restore CF
	 jc	 short CHECK_EMS_EXIT ; Jump if something went wrong (note CF=1)

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jnz	 short CHECK_EMS_EXIT ; Jump if so (note CF=0)

	 stc			; Not a device
CHECK_EMS_EXIT:
	 REGREST <dx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_EMS endp			; End CHECK_EMS procedure
	 NPPROC  CHECK_VCPI -- Check On VCPI Services
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on VCPI services

|

	 REGSAVE <ax,bx,cx>	; Save registers

; Because Windows is a bit testy about its apps using VCPI calls,
; if Windows is active, we skip this routine.

	 call	 CHECK_WIN3	; See if Windows 3.x is active
	 jc	 short CHECK_VCPI_EXIT ; Jump if so

	 call	 CHECK_EMS	; Is there an EMS provider?
	 jc	 short CHECK_VCPI_EXIT ; Jump if not

	 VCPICALL @VCPI_PRES	; Check on VCPI host
				; Return with AH = 0 if present
				;	 (BH,BL) = version #
	 cmp	 ah,0		; Izit present?
	 jne	 short CHECK_VCPI_EXIT ; Jump if not

	 or	 LCL_FLAG,@LCL_VCPI ; Mark as present

; Read the master and slave IRQ bases

	 VCPICALL @VCPI_GIBV	; Return with BX = master base
				; ...	      CX = slave base
	 mov	 IBV0,bl	; Save for later use
	 mov	 IBV1,cl	; ...
CHECK_VCPI_EXIT:
	 REGREST <cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_VCPI endp 		; End CHECK_VCPI procedure
	 NPPROC  CHECK_PREF -- Check Preference Of VCPI vs. DPMI
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check preference of VCPI vs. DPMI

If both VCPI and DPMI are present, and the user has expressed
a preference of using VCPI, do so.  Otherwise, use DPMI.

If neither service is present, display error message.

On exit:

CF	 =	 0 VCPI or DPMI present
	 =	 1 neither present

|

	 test	 LCL_FLAG,@LCL_DPMI ; Is DPMI present?
	 jz	 short CHECK_PREF_TEST ; Jump if not

	 btr	 LCL_FLAG,$LCL_VCPI ; Is VCPI present (clear if so)?
	 jnc	 short CHECK_PREF_DPMI ; Jump if not (use DPMI)

; Both services are present:  choose one or the other (DPMI is the default)

	 test	 LCL_FLAG,@LCL_VCPIPREF ; Is there a preference to use VCPI?
	 jz	 short CHECK_PREF_DPMI ; Jump if not (use DPMI)

	 or	 LCL_FLAG,@LCL_VCPI ; Mark as using VCPI
	 and	 LCL_FLAG,not @LCL_DPMI  ; ...and not DPMI

	 clc			; Mark as success

	 jmp	 short CHECK_PREF_EXIT ; Join common exit code

CHECK_PREF_DPMI:
	 REGSAVE <ax,bx,dx,ds,es> ; Save registers

; Make room for HPDA segment

	 mov	 ax,NEXTSEG	; Get next available segment
	 mov	 HPDASEG,ax	; Save as HPDA segment
	 add	 ax,DPMI_HPDA	; Plus # paras in HPDA
	 mov	 NEXTSEG,ax	; Protect the HPDA

; To handle terminations, we need to hook INT 21h

	 mov	 al,21h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT21_VEC.VOFF,bx ; Save for later use
	 mov	 OLDINT21_VEC.VSEG,es ; ...

	 mov	 ax,cs		; Get segment of LCL_INT21
	 mov	 ds,ax		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 al,21h 	; Intercept this one
	 DOSCALL @SETINT,LCL_INT21 ; Install our own handler

	 REGREST <es,ds,dx,bx,ax> ; Restore
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it
CHECK_PREF_TEST:
	 test	 LCL_FLAG,@LCL_DPMI or @LCL_VCPI ; Are either present?
	 jnz	 short CHECK_PREF_EXIT ; Jump if so (note CF=0)

	 stc			; Mark as neither present
CHECK_PREF_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PREF endp 		; End CHECK_PREF procedure
	 NPPROC  SETUP_VCPI -- Setup Data For VCPI
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup data values for VCPI calls

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pushad 		; Save registers
	 REGSAVE <es>		; ...

; Setup for VCPI calls

	 movzx	 eax,NEXTSEG	; Get next available segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 add	 eax,4*1024-1	; Round up to 4KB in paras
	 and	 eax,not (4*1024-1) ; ...
	 mov	 LaCR3,eax	; Save as linear address of CR3 (/4KB)
	 add	 eax,4*1024	; Skip over CR3
	 mov	 LaPTE,eax	; Save as linear address of PTEs
	 shr	 eax,4-0	; Convert from bytes to paras
	 mov	 NEXTSEG,ax	; Protect the CR3

; Get the physical address of the CR3

	 mov	 ecx,LaCR3	; Get linear address of CR3 (/4KB)

	 push	 ecx		; Pass linear address as argument
	 call	 ZERO_PAGE	; Zero the contents of the 4KB page

	 shr	 ecx,12-0	; Convert from bytes to 4KB
	 VCPICALL @VCPI_L2P	; Convert linear addr in CX to phys addr in EDX
	 and	 dx,mask $PTE_FRM ; Isolate the 4KB frame
	 mov	 PaCR3,edx	; Save for later use

; Setup PMI

	 mov	 eax,LaPTE	; Get linear address of PTEs (/4KB)

	 push	 eax		; Pass linear address as argument
	 call	 ZERO_PAGE	; Zero the contents of the 4KB page

	 shr	 eax,4-0	; Convert from bytes to paras
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 lea	 si,LCLGDT.DTE_PMCS ; DS:SI ==> three DTEs for PMI
	 xor	 di,di		; ES:DI ==> PTEs
	 VCPICALL @VCPI_GPMI	; Return with EBX=offset, DI=advanced

	 cmp	 ah,0		; Check for error
	 jne	 near ptr SETUP_VCPI_ERR ; Jump if not OK

	 mov	 VCPI_FVEC.FOFF,ebx ; Save offset of PMI
	 mov	 VCPI_FVEC.FSEL,DTE_PMCS ; Save selector of PMI

	 mov	 NEXTPTE.ELO,di ; Save offset of next available PTE

; Make room for more PTEs here if more memory is to be managed
; Arbitrarily, we choose to manage all physical memory

	 mov	 eax,MAXSIZE	; Get size of physical memory (including the
				; 1st megabyte)
	 shl	 eax,10-0	; Convert from 1KB to bytes
	 add	 eax,384*1024	; Plus maximum amount of shadow memory we
				; might recover
	 shr	 eax,(12-2)-0	; Convert from bytes to 4KB in dwords
	 add	 eax,NEXTPTE	; Skip over existing PTEs

; This is the next available offset in bytes after all PTEs

	 mov	 ecx,eax	; Copy as maximum size of PTEs
	 add	 eax,16-1	; Round up to next para
	 shr	 eax,4-0	; Convert from bytes to paras
	 add	 NEXTSEG,ax	; Protect the memory

; Calculate the # PDIRs

	 add	 ecx,4*1024-1	; Round up to 4KB bonudary
	 shr	 ecx,12-0	; Convert from bytes to 4KB (# PDIRs)

; Fill in the PDIRs

	 mov	 eax,LaCR3	; Get linear address of CR3 (/4KB)
	 shr	 eax,4-0	; Convert from bytes to paras
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 xor	 di,di		; ES:DI ==> PDEs

	 mov	 ebx,LaPTE	; Get its linear address (/4KB)
	 shr	 ebx,12-0	; Convert from bytes to 4KB
	 push	 ecx		; Save for a moment
SETUP_VCPI_NEXT:
	 push	 ecx		; Save for a moment

	 mov	 ecx,ebx	; Copy linear address in 4KB
	 VCPICALL @VCPI_L2P	; Convert linear addr in CX to phys addr in EDX

	 pop	 ecx		; Restore

	 mov	 eax,edx	; Copy to output register
	 and	 ax,mask $PTE_FRM ; Isolate the 4KB frame
	 or	 eax,@PTE_URP	; Mark as User/Read-Write/Present
	 stos	 es:[di].EDD	; Save as next PDE

	 inc	 ebx		; Skip to next PDE

	 loop	 SETUP_VCPI_NEXT ; Jump if more PDIRs to fill in

	 pop	 ecx		; Restore

; Zero the second and subsequent PDIRs

	 dec	 ecx		; Less the first PDIR (already filled in)
	 jz	 short SETUP_VCPI_DONE ; Jump if there's only one

	 mov	 eax,LaPTE	; Get its linear address (/4KB)
@@:
	 add	 eax,4*1024	; Skip to the next PDIR

	 push	 eax		; Pass linear address as argument
	 call	 ZERO_PAGE	; Zero the contents of the 4KB page

	 loop	 @B		; Jump if more PDIRs to zero
SETUP_VCPI_DONE:
	 clc			; Mark as successful

	 jmp	 short SETUP_VCPI_EXIT ; Join common exit code

SETUP_VCPI_ERR:
	 stc			; Mark as in error
SETUP_VCPI_EXIT:
	 REGREST <es>		; Restore
	 assume  es:DGROUP	; Tell the assembler about it
	 popad			; ...

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_VCPI endp 		; End SETUP_VCPI procedure
	 NPPROC  ZERO_PAGE -- Zero A 4KB Page
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Zero a 4KB page

|

ZP_STR	 struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
ZP_LA	 dd	 ?		; Linear address of page to zero (/4KB)

ZP_STR	 ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <eax,cx,di,es> ; Save registers

	 mov	 eax,[bp].ZP_LA ; Get the linear address
	 shr	 eax,4-0	; Convert from bytes to paras

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 xor	 di,di		; ES:DI ==> 4KB page to zero
	 xor	 eax,eax	; Set to this value
	 mov	 cx,(4*1024)/4	; # dwords in a 4KB page
     rep stos	 es:[di].EDD	; Zero the 4KB page

	 REGREST <es,di,cx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ZERO_PAGE endp			; End ZERO_PAGE procedure
	 NPPROC  SETUP_TAB -- Setup Various Tables
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup GDT, IDT, and TSS tables for RM or VCPI.

|

	 call	 SETUP_GDT	; Setup the GDT entries
	 call	 SETUP_IDT	; Setup the IDT entries (if any)

; Save master and slave interrupt masks to restore later

	 call	 SAVE_IMR	; Save 'em

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_TAB endp			; End SETUP_TAB procedure
	 NPPROC  SETUP_GDT -- Setup the GDT
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup the GDT entries

|

	 REGSAVE <eax>		; Save register

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,cs		; Get our data segment
	 shl	 eax,4-0	; Convert to paras to bytes
	 mov	 LaCODE,eax	; Save as our code's linear base address

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,ds		; Get our data segment
	 shl	 eax,4-0	; Convert to paras to bytes
	 mov	 LaDATA,eax	; Save as our data's linear base address

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,ss		; Get our stack segment
	 shl	 eax,4-0	; Convert to paras to bytes
	 mov	 LaSTK,eax	; Save as our stack's linear base address

	 test	 LCL_FLAG,@LCL_DPMI ; Is there a DPMI host?
	 jnz	 near ptr SETUP_GDT_EXIT ; Jump if so (no GDT setup needed)

; Setup DTE_CS descriptor to address the code segment

	 push	 LaCODE 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_CODE	; Pass access rights byte
	 push	 DTE_CS 	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup DTE_CS3 descriptor to address the code segment at DPL3

	 push	 LaCODE 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_CODE or DPL3 ; Pass access rights byte
	 push	 DTE_CS3	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup DTE_DS and DTE_ES descriptors to address the data segment at DPL3

	 push	 LaDATA 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_DATA or DPL3 ; Pass access rights byte
	 push	 DTE_DS 	; Pass selector
	 call	 SET_GDT	; Set the GDT

	 push	 LaDATA 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_DATA or DPL3 ; Pass access rights byte
	 push	 DTE_ES 	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup DTE_DS0 descriptor to address the data segment at DPL0

	 push	 LaDATA 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_DATA	; Pass access rights byte
	 push	 DTE_DS0	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup DTE_SS descriptor to address the big stack segment at DPL0

	 push	 LaSTK		; Pass base
	 push	 CON64K 	; Pass length
	 push	 ((mask $DTE_B) shl 8) or CPL0_DATA ; Pass access rights byte
	 push	 DTE_SS 	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup DTE_SS3 descriptor to address the stack segment at DPL3

	 push	 LaSTK		; Pass base
	 push	 CON64K 	; Pass length
	 push	 ((mask $DTE_B) shl 8) or CPL0_DATA or DPL3 ; Pass access rights byte
	 push	 DTE_SS3	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup local code alias descriptor at DPL3

	 push	 LaCODE 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_DATA or DPL3 ; Pass access rights byte
	 push	 DTE_ALIAS	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup local all memory descriptor

	 PUSHD	 0		; Pass base
	 PUSHD	 0		; Pass length
	 push	 CPL0_DATA or DPL3 ; Pass access rights byte
	 push	 DTE_4GB	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup LDT descriptor (not used currently, but we'll set it up anyway)

	 PUSHD	 0		; Pass base
	 PUSHD	 0		; Pass length
	 push	 CPL0_LDT	; Pass access rights byte
	 push	 DTE_LDT	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup DTE_GDT

	 lea	 eax,LCLGDT	; Get the GDT offset to linear address
	 add	 eax,LaDATA	; Plus our 32-bit linear address of DGROUP
	 mov	 LCLGDT.DTE_GDT.DTR_BASE,eax ; Save base
	 mov	 LCLGDT.DTE_GDT.DTR_LIM,(size XDTE_STR)-1 ; Save limit

; Setup DTE_IDT

	 lea	 eax,LCLIDT	; Get the IDT offset to linear address
	 add	 eax,LaDATA	; Plus our 32-bit linear address of DGROUP
	 mov	 LCLGDT.DTE_IDT.DTR_BASE,eax ; Save base
	 mov	 LCLGDT.DTE_IDT.DTR_LIM,LCLIDT_LEN-1 ; Save limit

	 call	 SETUP_TSS	; Setup the TSS

;**********DEBUG START**********

; Setup SWAT in the GDT/IDT

	pushad			; Save registers

	test	LCL_FLAG,@LCL_RM ; Are we starting from RM?
	jnz	short @F	; Jump if so (no CR3, linear address unchanged)

	mov	ebx,PaCR3	; Get new CR3
	mov	edx,-1		; Linear address unchanged
	VCPICALL @VCPI_DBGLIN	; Initialize SWAT's linear addresses
@@:

; Initialize debugger GDT entries

	 mov	 bx,DTE_SWAT	; Get initial selector
	 lea	 di,LCLGDT[bx]	; ES:DI ==> 1st debugger GDT entry
	 VCPICALL @VCPI_DBGINI	; Initialize the GDT entries

	 cmp	 ah,0		; Did it work?
	 jne	 short SETUP_GDT_XDBG ; Jump if not

; Initialize the debugger's IDT entries

	 xor	 bx,bx		; Initial interrupt #
	 mov	 cx,20h 	; # interrupt #s
	 lea	 di,LCLIDT	; ES:DI ==> initial IDT entry
SETUP_GDT_DBGNEXT:
	 VCPICALL @VCPI_DBGIDT	; Initialize an IDT entry

	 inc	 bx		; Skip to next interrupt #
	 add	 di,size IDT_STR ; Skip to next IDT entry

	 loop	 SETUP_GDT_DBGNEXT ; Jump if more interrupt #s
SETUP_GDT_XDBG:
	popad			; Restore
;***********DEBUG END***********

; Split cases between VCPI and RM entry into PM

	 test	 LCL_FLAG,@LCL_VCPI ; Is there a VCPI host?
	 jz	 short SETUP_GDT_EXIT ; Jump if not

; Setup the structures for PM entry via VCPI
; Setup to Enter and Exit Protected Mode

	 call	 SETUP_EPM	; Set it up
SETUP_GDT_EXIT:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_GDT endp			; End SETUP_GDT procedure
	 NPPROC  SET_GDT -- Set Global Descriptor Table
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set a global descriptor table entry.

|

SET_GDT_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
SET_GDT_DTE dw	 ?		; DTE to set
SET_GDT_ARB db	 ?		; Access rights byte
SET_GDT_FLG db	 ?		; DTE flags
SET_GDT_LEN dd	 ?		; Segment length
SET_GDT_BAS dd	 ?		; Segment base

SET_GDT_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <eax,bx,ecx>	; Save registers

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 eax,[bp].SET_GDT_BAS ; Get segment base
	 mov	 ecx,[bp].SET_GDT_LEN ; Get segment length
	 dec	 ecx		; Convert from length to limit

	 cmp	 ecx,CON1M	; Check against limit limit
	 jb	 short @F	; Jump if within range

	 shr	 ecx,12-0	; Convert from bytes to 4KB
	 or	 ecx,(mask $DTE_G) shl 16 ; Set G-bit
@@:
	 mov	 bx,[bp].SET_GDT_DTE ; Get the DTE to set

	 mov	 LCLGDT.DESC_BASE01.EDD[bx],eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 LCLGDT.DESC_BASE3[bx],al ; Save as base byte #3
;;;;;;;; ror	 eax,8		; Rotate back
	 mov	 LCLGDT.DESC_SEGLM0[bx],cx ; Save as data limit
	 rol	 ecx,16 	; Swap high- and low-order words
	 or	 cl,[bp].SET_GDT_FLG ; Include any flags
	 mov	 LCLGDT.DESC_SEGLM1[bx],cl ; Save as data limit
;;;;;;;; ror	 ecx,16 	; Swap back

; Set access rights byte

	 mov	 al,[bp].SET_GDT_ARB ; Get it
	 mov	 LCLGDT.DESC_ACCESS[bx],al ; Set it

	 popf			; Restore flags

	 REGREST <ecx,bx,eax>	; Restore

	 pop	 bp		; Restore

	 ret	 2*2+2*4	; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_GDT  endp			; End SET_GDT procedure
	 NPPROC  SETUP_TSS --  Setup The TSS
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup the TSS for EPM

|

	 REGSAVE <eax>		; Save register

; Setup local TSS descriptor

	 lea	 eax,LCLTSS	; Get local TSS address
	 add	 eax,LaDATA	; Convert from relative to absolute

	 push	 eax		; Pass base
	 push	 dword ptr (size TSS_STR) ; Pass length
	 push	 CPL0_IDLE3	; Pass access rights byte
	 push	 DTE_TSS	; Pass selector
	 call	 SET_GDT	; Set the GDT

	 mov	 LCLTSS.TSS_LDT,DTE_LDT ; Save LDT descriptor

; We use the PL0 stack for PL3 interrupts

	 mov	 LCLTSS.TSS_ESP0,offset SGROUP:PMSTKZ
	 mov	 LCLTSS.TSS_SS0,DTE_SS

	 mov	 eax,PaCR3	; Get CR3 physical address
	 mov	 LCLTSS.TSS_CR3,eax ; Save in TSS

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_TSS endp			; End SETUP_TSS procedure
	 NPPROC  SETUP_EPM -- Setup to Enter and Exit Protected Mode
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup VCPI struc to enter and exit protected mode.

|

	 REGSAVE <eax>		; Save register

; Setup our own CR3

	 mov	 eax,PaCR3	; Get CR3 physical address
	 mov	 EPMTAB.VCPEPM_CR3,eax ; Save in EPMTAB

; Setup pointer to local GDT

	 lea	 eax,LCLGDT.DTE_GDT ; Get pointer
	 add	 eax,LaDATA	; Plus linear address of data segment
	 mov	 EPMTAB.VCPEPM_GDTP,eax ; Save it

; Setup pointer to local IDT

	 lea	 eax,LCLGDT.DTE_IDT ; Get pointer
	 add	 eax,LaDATA	; Plus linear address of data segment
	 mov	 EPMTAB.VCPEPM_IDTP,eax ; Save it

; Setup local LDT and TR

	 mov	 EPMTAB.VCPEPM_LDTR,DTE_LDT ; Use local one
	 mov	 EPMTAB.VCPEPM_TR,DTE_TSS ; Use local one

; Setup return address

	 mov	 EPMTAB.VCPEPM_EXIT.FOFF,offset PGROUP:ENTER_PMSUB_PMON
	 mov	 EPMTAB.VCPEPM_EXIT.FSEL,DTE_CS ; Save our code selector

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_EPM endp			; End SETUP_EPM procedure
	 NPPROC  SETUP_IDT -- Setup IDT Entries
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup IDT entries

|

	 pushad 		; Save all EGP registers

	 test	 LCL_FLAG,@LCL_DPMI ; Is there a DPMI host?
	 jnz	 short SETUP_IDT_EXIT ; Jump if so

; If there's anything special to be done with IDT entries, do so here
; Note that the master and slave PIC bases are in IBV0 and IBV1 -- use
; these values instead of constants 08h and 70h.

; Hook INT 21h to handle termination via @EXITRC

	 lea	 eax,PGROUP:PMINT21 ; Get offset of PM handler

	 mov	 LCLIDT[21h*(type IDT_STR)].IDT_OFFLO,ax ; Save low-order word
	 shr	 eax,16 	; Shift down high-order word
	 mov	 LCLIDT[21h*(type IDT_STR)].IDT_OFFHI,ax ; Save high-order word
;;;;;;;; mov	 LCLIDT[21h*(type IDT_STR)].IDT_SELECT,DTE_CS ; Save selector (already there)
;;;;;;;; mov	 LCLIDT[21h*(type IDT_STR)].IDT_ACCESS,CPL0_INTR3 or DPL3 ; Save A/R byte (already there)






SETUP_IDT_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_IDT endp			; End SETUP_IDT procedure
	 FPPROC  PMINT21 -- PM DOS Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PM DOS Interrupt handler for RM or VCPI.

|

	 cmp	 ah,@EXITRC	; Izit termination time?
	 jne	 short PMINT21_CONT ; Jump if not

	 mov	 ds,SEL_DATA	; Get DGROUP data selector
	 assume  ds:DGROUP	; Tell the assembler about it

	 call	 PM2ORIG	; Switch from PM to original mode (RM or VM)

	 lss	 sp,VMSTK_VEC	; Restore the stack
	 assume  ss:nothing	; Tell the assembler about it

	 jmp	 VMCSIP_VEC	; Join common exit code

	 assume  ds:nothing	; Tell the assembler about it

PMINT21_CONT:
	 jmp	 INTPROC21	; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PMINT21  endp			; End PMINT21 procedure
	 FPPROC  INTPROC -- IDT Entries
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

IDT entries.

HW interrupts come here and are reflected to the original mode.
Return is to the point of interruption.

This means that your RM/VCPI code can call register-based interrupts
and expect to get back valid results.  Any other call made from
PM via RM/VCPI must provide its own translation services.  DPMI
hosts do this automatically for any services such as DOS, BIOS, etc.

On entry:

SS:SP	 ==>	 INT_STR.INT_ERR

|

INT_STR  struc

INT_BP	 dw	 ?		; Caller's BP
	 dw	 4 dup (?)	; DS, ES, FS, GS
INT_ERR  dw	 ?		; Interrupt #
INT_EIP  dd	 ?		; Return EIP
INT_CS	 dw	 ?,?		; ...	 CS w/filler
INT_EFL  dd	 ?		; ...	 EFL

INT_STR  ends

	 public  INTPROC_COM
INTPROC_COM:
	 REGSAVE <ds,es,fs,gs>	; Save for a moment

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 mov	 ds,SEL_DATA	; Get DGROUP data selector
	 assume  ds:DGROUP	; Tell the assembler about it

	 call	 PM2ORIG	; Switch from PM to original mode (RM or VM)

; Reflect the interrupt to the appropriate handler

	 push	 eax		; Save for a moment

	 mov	 ds,DATASEG	; Get segment of DGROUP
	 assume  ds:DGROUP	; Tell the assembler about it

	 xor	 ax,ax		; Get segment of RM IDT
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 movzx	 eax,[bp].INT_ERR ; Get the interrupt #
	 mov	 eax,es:[eax*4] ; Get the Seg:off of the IDT entry
	 mov	 INT_VEC,eax	; Save for later use

; Get caller's flags
; SS:BP  ==>	 INT_STR

FLMASKLO =	 ((mask $NT) or (mask $IOPL) or (mask $TF) or (mask $IF))

	 mov	 ax,[bp].INT_EFL.ELO ; Get caller's flags
	 and	 ax,not FLMASKLO ; NT=IOPL=TF=IF=0
	 push	 ax		; Put into effect
	 popf			; ...

	 pop	 eax		; Restore

	 pop	 bp		; Restore

	 pushf			; Simulate INT environment
;;;;;;;; cli			; ...			   (already done)
	 call	 INT_VEC	; Call the appropriate interrupt

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

FLMASKHI =	 ((mask $VMHI) or (mask $RFHI) or FLMASKLO)

	 push	 eax		; Save for a moment

	 pushfd 		; Get the return flags
	 pop	 eax		; ...
	 and	 eax,not FLMASKHI ; VM=RF=NT=IOPL=TF=IF=0
	 and	 [bp].INT_EFL,FLMASKHI ; Isolate
	 or	 [bp].INT_EFL,eax ; Include

	 pop	 eax		; Restore

	 pop	 bp		; Restore

	 mov	 ds,DATASEG	; Get segment of DGROUP
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 es,DATASEG	; Get segment of DGROUP
	 assume  es:DGROUP	; Tell the assembler about it

	 call	 ENTER_PMSUB	; Enter or fail
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
	 jnc	 short @F	; Jump if all went OK

	 int	 03h		; Call our debugger

	 jmp	 short $	; March in place
@@:
	 REGREST <gs,fs,es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it

	 add	 sp,size INT_ERR ; Strip error code from stack

	 iretd			; Return to caller

LBL	 macro	 NUM
INTPROC&NUM:
	 endm			; LBL

CNT	 =	 0

	 rept	 100h		; Define all entries
; Extract high- and low-order digits from CNT in ASCII hex as L and H
; and catenate them as a two-character hex representation of CNT in N

H	 substr  @HEX,1+(CNT/16),1
L	 substr  @HEX,1+(CNT mod 16),1
HL	 catstr  H,L

	 LBL	 %HL
	 push	 CNT
	 jmp	 INTPROC_COM	; Join common code
CNT	 =	 CNT+1

	 endm

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INTPROC  endp			; End INTPROC procedure
	 NPPROC  ENTER_PM -- Enter PM
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Switch into PM

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

; Insert here any one-time enter PM code








	 call	 ENTER_PMSUB	; Enter or fail
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
	 jc	 short ENTER_PM_EXIT ; Jump if something went wrong



	 clc			; Mark as successful
ENTER_PM_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENTER_PM endp			; End ENTER_PM procedure
	 FPPROC  LCL_INT21 -- Local INT 21h Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local INT 21h handler in VM for DPMI terminations.

|

	 push	 eax		; Save for a moment as placeholder
	 push	 ds		; ...

	 mov	 ds,DATASEG	; Get DGROUP segment
	 assume  ds:DGROUP	; Tell the assembler about it

	 cmp	 ah,@EXITRC	; Izit exit time?
	 jne	 short LCL_INT21_ORIG ; Jump if not

	 cmp	 DPMITERM,1	; Izit our exit time?
	 jne	 short LCL_INT21_ORIG ; Jump if not

	 mov	 DPMITERM,0	; No longer terminating

	 lss	 sp,VMSTK_VEC	; Restore the stack
	 assume  ss:nothing	; Tell the assembler about it

	 jmp	 VMCSIP_VEC	; Join common exit code


LCL_INT21_ORIG:

LINT21_STR struc

	 dw	 ?		; Caller's BP
LINT21_DS dw	 ?		; ...	   DS
LINT21_EAX dd	 ?		; ...	   EAX

LINT21_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 mov	 eax,OLDINT21_VEC ; Get address of next handler in sequence
	 xchg	 eax,[bp].LINT21_EAX ; Swap with saved EAX

	 pop	 bp		; Restore

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 retf			; Continue with next handler in sequence

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT21 endp			; End LCL_INT21 procedure
	 NPPROC  EXIT_PM -- Exit From PM
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Exit from PM as DPMI client.

|

	 mov	 DPMITERM,1	; Mark as DPMI terminate time
	 mov	 VMSTK_VEC.VOFF,sp ; Save VM stack pointer

	 mov	 VMCSIP_VEC.VOFF,offset PGROUP:EXITPM_EXIT ; Save return point
	 mov	 VMCSIP_VEC.VSEG,seg PGROUP ; ...

	 DOSCALL @EXITRC	; Terminate through DOS
EXITPM_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EXIT_PM  endp			; End EXIT_PM procedure
	 NPPROC  PM2ORIG -- Switch From PM To Original Mode
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Switch from PM to the mode from which we started (RM or VM)
and continue with the interrupted instruction.

|

	 REGSAVE <eax,bx,esi>	; Save registers

	 test	 LCL_FLAG,@LCL_VCPI ; Is there a VCPI host?
	 jz	 short PM2ORIG_NOVCPI ; Jump if not

; Return to Virtual Mode

	 mov	 es,SEL_DATA	; Get DGROUP data selector
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,esp	; Copy current ESP

	 PUSHD	 gs		; GS with filler
	 PUSHD	 fs		; FS ...
	 push	 DATASEG.EDD	; DS ...
	 push	 DATASEG.EDD	; ES ...
	 push	 STACKSEG.EDD	; SS ...
	 push	 eax		; ESP
	 PUSHD	 0		; EFL
	 push	 CODESEG.EDD	; Real mode CS with filler
	 lea	 eax,PM2ORIG_PMOFF ; Get return address
	 push	 eax		; EIP

	 mov	 ax,DTE_4GB	; Get all memory selector
	 mov	 ds,ax		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 cli			; Exit with IF=0

	 mov	 ah,@VCPI	; Get major VCPI function code
	 mov	 al,@VCPI_EPM	; Return to VM86 mode
	 lea	 esi,EPMTAB	; Get offset of system tables
	 add	 esi,LaDATA	; Plus base linear address
	 call	 VCPI_FVEC	; Call VCPI PMI code
PM2ORIG_PMOFF:
	 assume  ds:DGROUP,es:DGROUP ; Tell the assembler about it

	 jmp	 short PM2ORIG_EXIT ; Join common exit code

PM2ORIG_NOVCPI:
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it

; It must be true that the linear and physical address for
; this page are identical

	 mov	 ax,DTE_DS0	; Use low memory data selector, not the
				; stack selector as that one has the B-bit set.

; Reset SS:SP to avoid stack fault

	 mov	 ss,ax
	 assume  ss:nothing	; Tell the assembler about it
	 mov	 sp,sp		; Just for the fun of it

; Load all data segment registers with 64KB selector in low memory

	 mov	 ds,ax
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 es,ax
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 fs,ax
	 assume  fs:DGROUP	; Tell the assembler about it

	 mov	 gs,ax
	 assume  gs:DGROUP	; Tell the assembler about it

; Load base and limit of IDT for real mode

	 LIDTD	 IDTR_REAL	; Reset IDT for real mode

; Exit protected mode

	 mov	 eax,cr0	; Get current CR0
	 and	 ax,not mask $PE ; Turn off PE bit
	 mov	 cr0,eax	; Exit protected mode

; Jump to real mode code

	 FIJMP	 PGROUP:@F,<seg PGROUP> ; Far jump to set access rights
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
@@:

; Re-initialize segment registers

	 mov	 ax,DATASEG	; Get segment of DGROUP
	 mov	 ds,ax
	 assume  ds:DGROUP	; Tell the assembler about it
	 mov	 es,ax
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 ss,STACKSEG	; Get segment of stack
	 assume  ss:nothing	; Tell the assembler about it
	 mov	 sp,sp		; Just for the fun of it

	 mov	 fs,ax
	 assume  fs:DGROUP	; Tell the assembler about it

	 mov	 gs,ax
	 assume  gs:DGROUP	; Tell the assembler about it
PM2ORIG_EXIT:
	 REGREST <esi,bx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PM2ORIG  endp			; End PM2ORIG procedure
	 NPPROC  ENTER_PMSUB -- Subroutine To ENTER_PM
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Subroutine to ENTER_PM

On exit:

CF	 =	 0 if successful
DS	 =	 DGROUP
ES	 =	 DGROUP
FS	 =	 0
GS	 =	 AGROUP
IF	 =	 0 if entered from RM/VCPI

CF	 =	 1 otherwise

|

	 pushad 		; Save all EGP registers

	 test	 LCL_FLAG,@LCL_DPMI ; Is there a DPMI host?
	 jz	 near ptr ENTER_PMSUB_NODPMI ; Jump if not

; Address the HPDA

	 mov	 es,HPDASEG	; Get segment of HPDA
	 assume  es:nothing	; Tell the assembler about it

	 or	 LCL_FLAG,@LCL_DPMIERR ; Assume we get an error

	 mov	 DPMITERM,1	; Mark as DPMI terminate time in case we fail

	 mov	 ax,1		; We're a 32-bit client
	 call	 DPMIDRV_VEC	; Request entry into PM
	 mov	 DPMITERM,0	; Mark as no longer DPMI terminate time
	 jc	 near ptr ENTER_PMSUB_DPMIERR0 ; Jump if something went wrong

	 assume  ds:DGROUP	; Tell the assembler about it

	 and	 LCL_FLAG,not @LCL_DPMIERR ; No longer in error

; Get a Read-Write code alias to save SEL_DATA

	 mov	 bx,cs		; Get our code selector
	 DPMICALL @DPMI_GETALIAS ; Return with AX = alias selector
	 jc	 near ptr ENTER_PMSUB_DPMIERR ; Jump if something went wrong

	 mov	 es,ax		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 SEL_DATA,ds	; Save as data selector
	 mov	 SEL_ALIAS,es	; ...	  code alias

	 mov	 es,SEL_DATA	; Get DGROUP data selector
	 assume  es:DGROUP	; Tell the assembler about it

; Hook INT 23h in VM and PM in case the user has an itchy Ctrl-C finger

	 mov	 bl,23h 	; Intercept this one
	 mov	 cx,CODESEG	; Get our code segment
	 lea	 dx,VMINT23	; CX:DX ==> our VM handler
	 DPMICALL @DPMI_SETVMIV ; Setup our VM handler
				; This function always succeeds

	 mov	 bl,23h 	; Intercept this one
	 mov	 cx,cs		; Get our code selector
	 lea	 edx,PMINT23	; CX:EDX ==> our PM handler
	 DPMICALL @DPMI_SETPMIV ; Setup our PM handler
				; This function always succeeds unless
				; you mess up CX

; Setup our all memory selector

	 mov	 cx,1		; Allocate one descriptor
	 DPMICALL @DPMI_GETLDT	; Request DPMI services
	 jc	 short ENTER_PMSUB_DPMIERR ; Jump if something went wrong

	 push	 es		; Save for a moment

	 mov	 es,SEL_ALIAS	; Address code alias
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 SEL_4GB,ax	; Save as all memory selector
	 mov	 bx,ax		; Copy to selector register

	 pop	 es		; Restore
	 assume  es:DGROUP	; Tell the assembler about it

	 lea	 edi,LCLGDT.DTE_4GB ; ES:EDI ==> DTE
;;;;;;;; mov	 bx,SEL_4GB	; Get the selector
	 DPMICALL @DPMI_GETLDTE ; Function code to get LDT descriptor
	 jc	 short ENTER_PMSUB_DPMIERR ; Jump if something went wrong

	 mov	 LCLGDT.DTE_4GB.DESC_SEGLM0,-1 ; Limit is 4GB
	 or	 LCLGDT.DTE_4GB.DESC_SEGLM1,((mask $DTE_G) or (mask $DTE_B) or (mask $SEGLM1)) ; G=B=1

;;;;;;;; lea	 edi,LCLGDT.DTE_4GB ; ES:EDI ==> DTE
;;;;;;;; mov	 bx,SEL_4GB	; Get the selector
	 DPMICALL @DPMI_SETLDTE ; Function code to set LDT descriptor
	 jc	 short ENTER_PMSUB_DPMIERR ; Jump if something went wrong

	 mov	 gs,SEL_4GB	; Get AGROUP data selector
	 assume  gs:AGROUP	; Tell the assembler about it

	 jmp	 ENTER_PMSUB_CLC ; Join common code

ENTER_PMSUB_DPMIERR:
	 or	 LCL_FLAG,@LCL_DPMIERR ; DPMI error occurred, DPMIERR is valid

	 call	 EXIT_PM	; Exit from PM

	 jmp	 ENTER_PMSUB_ERR1 ; Join common error code

; The DPMI switch from VM to PM failed

	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENTER_PMSUB_DPMIERR0:

; If the DPMI host was 386MAX, there's an error code in AX

	 cmp	 ax,8012h	; Izit insufficient memory?
	 jne	 short @F	; Jump if not

;;;;;;;; DPMIERR <'Insufficient memory to enter Protected Mode through DPMI host.'>
@@:
ENTER_PMSUB_ERR1:
	 stc			; Indicate something went wrong

	 jmp	 ENTER_PMSUB_EXIT ; Join common exit code

	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

ENTER_PMSUB_NODPMI:
	 test	 LCL_FLAG,@LCL_VCPI ; Is there a VCPI host?
	 jz	 short ENTER_PMSUB_NOVCPI ; Jump if not

	 mov	 PMONSTK_FVEC.FOFF,esp ; Save current ESP

	 cli			; Enter with IF=0

	 lea	 esi,EPMTAB	; Get offset of system tables
	 add	 esi,LaDATA	; Plus base linear address
	 VCPICALL @VCPI_EPM	; Enter Protected Mode
ENTER_PMSUB_PMON:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 cli			; Some VCPI hosts (RM386 comes to mind)
				; start us off with IF=1

; Ensure no interrupts between above VCPICALL and the following LSS

	 mov	 ds,SEL_DATA	; Get DGROUP data selector
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 es,SEL_DATA	; Get DGROUP data selector
	 assume  es:DGROUP	; Tell the assembler about it

	 lss	 esp,PMONSTK_FVEC ; SS:ESP ==> PM stack
	 assume  ss:nothing	; Tell the assembler about it

	 xor	 ax,ax		; A convenient zero
	 mov	 fs,ax		; Clear selector
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 gs,SEL_4GB	; Get AGROUP data selector
	 assume  gs:AGROUP	; Tell the assembler about it

	 jmp	 ENTER_PMSUB_INRM ; Join common OK code

ENTER_PMSUB_NOVCPI:
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

; Ensure FS and GS are valid

	 xor	 ax,ax		; A convenient zero
	 mov	 fs,ax		; Ensure valid
	 mov	 gs,ax		; ...

; Enter protected mode

	 lea	 si,LCLGDT	; ES:SI ==> descriptor table
;;;;;;;; mov	 bh,IBV0	; Get master IMR base (not used by RM2PM)
;;;;;;;; mov	 bl,IBV1	; ... slave
	 call	 RM2PM		; Enter protected mode from RM
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it

	 jmp	 short ENTER_PMSUB3 ; Join common code

; Return in protected mode with interrupts and NMI enabled

	 public  ENTER_PMSUB2
ENTER_PMSUB2:
	 call	 REST_IMR	; Restore original IMR
	 call	 ENABLE_NMI	; Allow NMI to occur
ENTER_PMSUB3:
	 mov	 ds,SEL_DATA	; Get DGROUP data selector
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 es,SEL_DATA	; Get DGROUP data selector
	 assume  es:DGROUP	; Tell the assembler about it

	 xor	 ax,ax		; A convenient zero
	 mov	 fs,ax		; Ensure valid

	 mov	 gs,SEL_4GB	; Get AGROUP data selector
	 assume  gs:AGROUP	; Tell the assembler about it

	 and	 LCLGDT.DTE_TSS.DESC_ACCESS,not (mask $DS_BUSY) ; Clear the busy bit
	 mov	 ax,DTE_TSS	; Get our TSS selector
	 ltr	 ax		; Put it into effect
ENTER_PMSUB_INRM:

; In case NT is set in the current flags, clear it to avoid a TSS Fault
; on an IRET/D

	 pushf			; Get the current flags
	 pop	 ax		; ...into AX
	 and	 ax,not (mask $NT) ; NT=0
	 push	 ax		; Prepare to POPF
	 popf			; Tell the CPU about it
ENTER_PMSUB_CLC:
	 clc			; Indicate we're successful
ENTER_PMSUB_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENTER_PMSUB endp		; End ENTER_PMSUB procedure
	 NPPROC  RM2PM -- Enter Protected Mode From RM
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enter protected mode from RM

* Disable NMI (no need to disable as we'll re-enable shortly)
* Disable interrupts
* Gate A20 on (note we don't do this anymore to avoid A20 hardware problems)
* Setup DTE_BIOS entry
* Load GDTR
* Load IDTR
* Setup 8259 (note we don't do this anymore to avoid keyboard lockups)
* Enter protected mode
* Setup segment registers
* Load LDTR
* Return to caller

On entry:

ES:SI	 ==>	 descriptor table
BH	 =	 8259 origin for master (unused)
BL	 =	 8259 origin for slave

|

; * Disable interrupts

	 cli

; * Setup DTE_BIOS entry

	 movzx	 eax,CODESEG	; Get current code segment
	 shl	 eax,4-0	; Convert from paras to bytes

	 mov	 es:[si].DTE_BIOS.DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 es:[si].DTE_BIOS.DESC_BASE3,al
;;;;;;;; ror	 eax,8		; Rotate back
	 mov	 es:[si].DTE_BIOS.DESC_SEGLM0,0FFFFh ; 64KB of code
	 mov	 es:[si].DTE_BIOS.DESC_SEGLM1,0
	 mov	 es:[si].DTE_BIOS.DESC_ACCESS,CPL0_CODE

; * Load GDTR from low memory

	 LGDTD	 es:[si].DTE_GDT.EDF

; * Load IDTR

	 LIDTD	 es:[si].DTE_IDT.EDF

; * Enter protected mode

	 mov	 eax,cr0	; Get current CR0
	 or	 ax,mask $PE	; Mark as enabling protected mode
	 mov	 cr0,eax	; Enter protected mode

	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 FIJMP	 PGROUP:@F,DTE_BIOS ; Flush prefetch instruction queue
@@:

; * Setup segment registers

	 mov	 ax,DTE_DS	; Get DS selector
	 mov	 ds,ax
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 ax,DTE_ES	; Get ES selector
	 mov	 es,ax
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 ax,DTE_SS	; Get SS selector
	 mov	 ss,ax
	 assume  ss:nothing	; Tell the assembler about it
	movzx	esp,sp		; Zero to use as dword as the
				; B-bit is set in SS
; Ensure FS and GS are valid

	 xor	 ax,ax		; A convenient zero
	 mov	 fs,ax		; Ensure valid
	 mov	 gs,ax		; ...

; * Load LDTR (optional)

	 mov	 ax,DTE_LDT	; Get LDTR
	 lldt	 ax		; Tell the CPU about it

; * Return to caller

	 pop	 ax		; Get return offset
	 push	 DTE_CS 	; Put return selector on stack
	 push	 ax		; Followed by offset

	 xor	 ax,ax		; Successful return code (AH=0, CF=0, ZF=1)

	 retf			; (Far) return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RM2PM	 endp			; End RM2PM procedure
	 NPPROC  SAVE_IMR -- Save The IMR
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save the original master and slave IMRs.

|

	 REGSAVE <ax>		; Save register

	 in	 al,@IMR	; Get current master interrupt mask register
	 mov	 OLDIMR1,al	; Save to restore later
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 in	 al,@IMR2	; Get current slave IMR
	 mov	 OLDIMR2,al	; Save to restore later
;;;;;;;; call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_IMR endp			; End SAVE_IMR procedure
	 NPPROC  REST_IMR -- Restore IMR to Original Value
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore IMR to original value.

|

	 REGSAVE <ax>		; Save register

	 mov	 al,OLDIMR1	; Copy original master IMR value
	 out	 @IMR,al	; Tell the PIC about it
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 mov	 al,OLDIMR2	; Copy original slave IMR value
	 out	 @IMR2,al	; Tell the PIC about it
;;;;;;;; call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_IMR endp			; End REST_IMR procedure
	 NPPROC  DRAINPIQ -- Drain The Prefetch Instruction Queue
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Drain the Prefetch Instruction Queue.

If we're on a Micro Channel system, write to I/O port 4Fh.
Otherwise, just jump a few times.

Flags are saved and restored over this routine to allow it
to be used with impunity.

|

	 pushf			; Save flags

	 test	 LCL_FLAG,@LCL_MC ; Izit an MC-compatible?
	 jz	 short @F	; Not this time

	 out	 @8253_XCIO,al	; Write to (presumably uncached) port
@@:
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; ...
	 jmp	 short $+2	; ...

	 popf			; Restore flags

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DRAINPIQ endp			; End DRAINPIQ procedure
	 FPPROC  VMINT23 -- VM Ctrl-Brk Termination Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VM Ctrl-Break termination interrupt handler.

Ignore it.

|

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMINT23  endp			; End VMINT23 procedure
	 FPPROC  PMINT23 -- PM Ctrl-Brk Termination Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PM Ctrl-Break termination interrupt handler.

Ignore it.

|

	 iretd			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PMINT23  endp			; End PMINT23 procedure
	 NPPROC  ENABLE_NMI -- Enable NMI
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable NMI

|

	 pushf			; Save flags
	 cli			; Ensure interrupts disabled

	 push	 ax		; Save for a moment

	 call	 CLR_PARITY	; Clear the parity latches

	 mov	 al,@CMOS_ENANMI ; Enable NMI
	 out	 @CMOS_CMD,al
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 in	 al,@CMOS_DATA	; Ensure OUT is followed by IN
;;;;;;;; call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

; If we're on an MCA, reset arbitration mask bit

	 test	 LCL_FLAG,@LCL_MC ; Izit an MCA?
	 jz	 short @F	; Jump if not

	 in	 al,90h 	; Get arbitration register
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

; Clear the arbitration mask bit (Bit 6) as well as everything else
; except for enable system microprocessor cycles (Bit 7)

	 and	 al,@BIT7	; Clear everything except Bit 7
	 out	 90h,al 	; Send it back
;;;;;;;; call	 DRAINPIQ	; Drain the Prefetch Instruction Queue
@@:
ENABLE_NMI2:
	 call	 CLR_PARITY	; Clear the parity latches

	 pop	 ax		; Restore
	 popf			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENABLE_NMI endp 		; End ENABLE_NMI procedure
	 NPPROC  CLR_PARITY -- Clear Parity Latches
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear the parity latches

|

	 REGSAVE <ax>		; Save register

	 mov	 ah,mask $ATPAR ; Get parity mask for AT
	 in	 al,@8255_B	; Get the parity latches
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 or	 al,ah		; Toggle parity check latches off
	 out	 @8255_B,al	; Tell the system about it
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 xor	 al,ah		; Toggle parity check latches on
	 out	 @8255_B,al	; Tell the system about it
;;;;;;;; call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLR_PARITY endp 		; End CLR_PARITY procedure

CODE	 ends			; End CODE segment

	 MEND	 EPM		; End EPM module
