;' $Header:   P:/pvcs/misc/swttools/swatrun.asv   1.10   03 Dec 1993 15:06:58   BOB  $
	title	SWATRUN -- 386SWAT program loader for V86-mode debugging
	name	SWATRUN
	page	60,132

COMMENT|	       Module Specifications

Copyright:  (C) Copyright 1991-2000 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, byte-aligned,  stack,  class 'prog'
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Data    segment DATZ,  para-aligned, public, class 'data'
	       Program segment CODE2,  byte-aligned,  public, class 'prog'
	       Data    segment DATA2,  dword-aligned, public, class 'data'
	       Data    segment DATZ2,  para-aligned, public, class 'data'
	       Program segment NCODE,  byte-aligned,  public, class 'prog'
	       Data    segment NDATA,  dword-aligned, public, class 'data'

Program derived from:  None.

Original code by: Henry Groover, June 1991

Modifications by:  None.

**************************** QUALITAS *******************************
*************************** CONFIDENTIAL ****************************

|

.386p
.xlist
	Include MASM.INC
	Include DOSCALL.INC
	Include ASCII.INC
	Include PTR.INC
	Include EXE.INC
	Include MAC.INC
	Include CPUFLAGS.INC
	Include VCPI.INC
	Include EXEC.INC
	Include BIOSDATA.INC
	Include IOCTL.INC
	Include OPEN.INC

	Include SWAT_SSF.INC
	Include SWAT_SYM.INC
.list

CRLF		equ	<CR,LF>
EXEHDRSIZE	equ	size EXE_STR
FSHARE		equ	2		; Default file share mode for OPEN
@MAX_PATH	equ	129		; Maximum path length + 1
@PSP_SIZE	equ	100h		; Size of PSP in bytes

@CHANGESTRA	equ	0		; Set to 1 to change MAC strategy

; Note that to declare an initialized structure in a .COM file,
; it is not possible to use dd for pointers.  Neither is it
; possible to use dw ?,?
EXE0_Block_str	struc
	env	dw	0		; Copy environment from parent
	cmdtail dw	?		; Far ptr to command line
		dw	?		; Segment portion of pointer
	FCB1	dw	?		; Far ptr to first FCB
		dw	?		; Segment portion of pointer
	FCB2	dw	?		; Far ptr to second FCB
		dw	?		; Segment portion of pointer
EXE0_Block_str	ends

EXE1_Block_str	struc
	env_1	dw	?		; Environment segment
	cmd1	dw	?		; Command line ptr
		dw	?		; Segment portion of pointer
	FCB1ptr dw	?		; FCB1 ptr
		dw	?		; Segment portion of pointer
	FCB2ptr dw	?		; FCB2 ptr
		dw	?		; Segment portion of pointer
	;---- RETURN VALUES ---------------------------------
	initstack dd	?		; initial SS:SP
	initcode dd	?		; initial CS:IP
EXE1_Block_str	ends

MSGDISP macro	msg
ifnb	<msg>
	lea	dx,msg		; Length-prefixed message
endif
	call	MSGDISPLAY	; Display message
	endm			; MSGDISP

CGROUP	group	BIOSDATA
PGROUP	group	STACK,CODE,DATA,DATZ,CODE2,DATA2,DATZ2,NCODE,NDATA

; Satisfies the LINKer's need to have a stack segment.

STACK	 segment use16 byte stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment

CODE	 segment use16 byte public 'prog' ; Start CODE segment
CODE	 ends			; End CODE segment

DATA	 segment use16 dword public 'prog' ; Start DATA segment
DATA	 ends			; End DATA segment

DATZ	 segment use16 para public 'prog' ; Start DATZ segment
DATZ	 ends			; End DATZ segment

CODE2	 segment use16 byte public 'prog' ; Start CODE2 segment
CODE2	 ends			; End CODE2 segment

DATA2	 segment use16 para public 'prog' ; Start DATA2 segment
DATA2	 ends			; End DATA2 segment

DATZ2	 segment use16 dword public 'prog' ; Start DATZ2 segment
DATZ2	 ends			; End DATZ2 segment

NCODE	 segment use16 byte public 'prog' ; Start NCODE segment
NCODE	 ends			; End NCODE segment

NDATA	 segment use16 dword public 'prog' ; Start NDATA segment
NDATA	 ends			; End NDATA segment

DATA	 segment ; Start DATA segment
	 assume  ds:PGROUP

; Essential resident data.  Data in this segment will be needed
; to load the client program and upon return.

; Local flags and options
	Public	SRFlags
SRFlags 	dw	0		; Flags defined below:
@SRF_BREAK	equ	0001h		;  Trigger Int 1 breakpoint at beginning
@SRF_NOSYMBOLS	equ	0002h		;  Do not load symbols

@SRF_MAPNAME	equ	0004h		;  Name of map file to load
@SRF_SYMNAME	equ	(@SRF_MAPNAME * 2) ;  Name of .SSF file to load & fix up
@SRF_LAST	equ	@SRF_SYMNAME	; Last bit for symbol file extensions
@SRF_EXE	equ	0010h		;  File is .EXE format
@SRF_BREAKEND	equ	0020h		;  Trigger Int 1 breakpoint at end

; EXEC data for EXEC subfunction 1 (load & prepare for execution)
	Public	EXE_cmdtail,EXE_FCB1,EXE_FCB2,EXE_Block
EXE_cmdtail	db	0,CR,126 dup (0)	; Command tail for file
EXE_FCB1	db	16 dup (0)		; FCB1 for file
EXE_FCB2	db	16 dup (0)		; FCB2 for file
EXE_Block	EXE1_Block_str	<0,PGROUP:EXE_cmdtail,,PGROUP:EXE_FCB1,,PGROUP:EXE_FCB2>

if @CHANGESTRA
	Public	Old_stra,Old_link
Old_stra	dw	?		; Old MAC strategy (5800)
Old_link	dw	?		; Old link state (5802)
endif					; IF @CHANGESTRA

; Local data
	Public	Stack_save,Xlat_word
Stack_save	dd	?		; Our saved SS:SP (for DOS < 3.0)
Xlat_word	dw	0		; Translation value for MAPSSF

	Public	SaveBX
SaveBX		dw	?		; BX on return from EXEC load

	 Public  EXECLoad_failed,EXE_Name,EXEC_mismatch
EXECLoad_failed db 'EXEC load function call failed- complete filespec was',CRLF
EXE_Name	db	@MAX_PATH dup (0),0	; File we're debugging
EXEC_mismatch	db 'MAC changed during EXEC.',CRLF,0

	Align	4			; Ensure dword alignment
	Public	Ourstack,Stack_end
Ourstack dw	50h	dup (?) 	; Stack space
Stack_end	label byte		; New location for SP
					; Also end of resident code/data

	 assume  ds:nothing
DATA	 ends			; End DATA segment

DATZ	 segment ; Start DATZ segment (end of resident code/data)
	 assume  ds:PGROUP

	 Public  End_res
End_res  label byte			; End of resident code/data

	 assume  ds:nothing
DATZ	 ends			; End DATZ segment

DATA2	 segment ; Start DATA2 segment
	 assume  ds:PGROUP

; Nonessential resident data.  Data in this segment will not be needed
; to load the client program.

; Data used by Load_SSF
	Public	 LSSF_fh,LSSF_cnt,LSSF_symcnt,LSSF_symsub,LSSF_bufp
LSSF_fh  dw	 ?		; File handle used by Load_ssf
LSSF_cnt dw	 ?		; Bytes read from ssf file into LSSF_buf
LSSF_symcnt dd	 ?		; Number of records according to file header
LSSF_symsub dw	 ?		; Subtotal for number of records
@LSSF_BUFSIZ	 equ	16384	; Size of SSF read buffer
LSSF_bufp dw	 ?		; Buffer for reading SSF files

	Public	Append_mode
Append_mode db	?			; Mode for loading SSF files

; EXEC data for EXEC subfunction 0 (load & execute)
	Public	EXE2_Name,EXE2_cmdtail,EXE2_dbglvl,EXE2_overflg
	Public	EXE2_hexadd,EXE2_path,EXE2_Block
EXE2_Name	db	@MAX_PATH dup (0) ; COMSPEC gets copied here
EXE2_cmdtail	db	0,'/c MAPSSF -x'
EXE2_dbglvl	db	'0 '
EXE2_overflg	db	'   -s'
EXE2_hexadd	db	'$$$$v+ '
EXE2_path	db	@MAX_PATH dup (?) ; End of %COMSPEC% command tail
EXE2_Block	EXE0_Block_str	<0,PGROUP:EXE2_cmdtail,,PGROUP:PSP_FCB1,,PGROUP:PSP_FCB2>

; Data for EXEC subfunction 5 (DOS 5 Enter EXEC state)
	 Public  DOSVER,EES
DOSVER	 dw	 ?			; DOS version (HI=maj,LO=min)
EES	 EES_STR <0,0,,,,>		; Enter EXEC state structure

; Resident messages
	 Public  EXEC_alloc
	 Public  LoadMsg,LoadMsgAt,LoadMsgMap,LoadMsgSSF,LoadMsgNoSym
	 Public  ExecMapFailed,LoadSSF_failed
EXEC_alloc	db 'Memory allocation error.',CRLF,0
LoadMsg  db	'Loading ',0
LoadMsgAt db	' at '
LoadMsg1 db	'$$$$h ',0
LoadMsgMap db	'using MAPSSF',CRLF,0
LoadMsgSSF db	'using SSF file',CRLF,0
LoadMsgNoSym db '(no symbol data found)',CRLF,0
ExecMapFailed db BEL,'Unable to execute MAPSSF.',CRLF,0
LoadSSF_failed db BEL,'Unable to load symbol file.',CRLF,0

	 Public  LoadSSF_Added,LoadSSF_short,LoadSSF_shortld,LoadSSF_shortlft
LoadSSF_Added dd ?			; Records succesfully added
LoadSSF_short db BEL,'Only '
LoadSSF_shortld db 'xxxxxxxxh symbols out of '
LoadSSF_shortlft db 'xxxxxxxxh were loaded.  Increase SYMSIZE.',CRLF,0

	 Public  ExecSep
ExecSep db	 '컴컴컴컴컴컴컴컴컴컴 Ready to execute 컴컴컴컴컴컴컴컴컴컴컴컴컴',CRLF,0

	 assume  ds:nothing
DATA2	 ends			; End DATA2 segment

DATZ2	 segment ; Start DATZ2 segment (end of resident code/data 2)
	 assume  ds:PGROUP

	 Public  End_res2
End_res2 label byte			; End of resident code/data 2

	 assume  ds:nothing
DATZ2	 ends			; End DATZ2 segment

NDATA	 segment ; Start NDATA segment (non-resident data)
	 assume  ds:PGROUP

	 Public  Copyright
Copyright label byte
db '旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커',CRLF
db '�   SWATRUN version 1.11  컴  A program loader for 386SWAT     �',CRLF
db '� (c) Copyright 1991-2000 Qualitas, Inc.  All rights reserved. �',CRLF
db '읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸',CRLF,0

	 Public  NoFilename
NoFilename db 'No filename specified on command line.',CRLF,0

	Public	InvalidOption,Syntax
InvalidOption db 'Invalid option specified.', CRLF
Syntax	db	'Syntax: SWATRUN [options] progname.ext [arguments]', CRLF
	db	'  If progname.ssf exists, it will be loaded;',CRLF
	db	'  otherwise, if progname.map exists, it will',CRLF
	db	'  be loaded via MAPSSF.',CRLF
	db	'  Valid options are:',CRLF
	db	'    /b   Generate Int 1 at beginning of SWATRUN',CRLF
	db	'    /z   Generate Int 1 at exit of SWATRUN',CRLF
	db	'    /mMAPFILE Load MAPFILE instead of progname.map',CRLF
	db	'    /n   Do not call MAPSSF.EXE to load symbols',CRLF
	db	'    /o   Overwrite existing SWAT symbols',CRLF
	db	'    /sSYMFILE Load SYMFILE instead of progname.ssf',CRLF
	db	'    /?   Display this message',CRLF,0

	 Public  FileNotFound
FileNotFound db 'File not found.',CRLF,0

	Public	 Comspec_not_found,Comspec_too_long
Comspec_not_found db 'Unable to find COMSPEC in environment',CRLF,0
Comspec_too_long db  'COMSPEC exceeds maximum path length',CRLF,0

	Public	 MsgNotDOS3,MsgNoDebugger
;;;;;;	Public	 MsgMaxNotPres
MsgNotDOS3 db	'DOS 3.0 or higher is required.',CRLF,0
;;;;MsgMaxNotPres db '386MAX not present.',CRLF,0
MsgNoDebugger db 'No VCPI debugger interface present.',CRLF,0

	Public	 COMSPEC
COMSPEC db	'COMSPEC='      ; Comparison for finding COMSPEC in environment
COMSPEC_LEN equ $-COMSPEC	; Length to compare

	Public	 Ext_list
Ext_list dd	'MOC.','EXE.'   ; Extensions to try when none is specified
@EXT_LISTSIZ	equ	($-Ext_list) / 4 ; Number of extensions in list

	Public	 Exe_name2
Exe_name2 db	 @MAX_PATH dup (?) ; Temporary copy of Exe_name

;;;;;;;  public  MAXNAME
;;;;;;;MAXNAME	db	 '386MAX$$',0   ; Name of our device

	 Public  ValPathTerms
ValPathTerms db ' ="/[]|;,',TAB,CR,LF,0 ; Command separators for command line
				; Note that / may not be part of a pathname
@VALPATHTERMLEN equ $-ValPathTerms

	 Public  Symextlist
Symextlist dd	'FSS.', 'PAM.'          ; Note that these extensions must
					; match (in inverse sequence) their
					; respective bit definitions in
					; SRFlags.
@SYMEXTLIST_SIZ equ ($-Symextlist) / 4	; Number of extensions in list

	 assume  ds:nothing
NDATA	 ends			; End NDATA segment

CODE	 segment  ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP,es:PGROUP,ss:nothing

.xlist
	 include PSP.INC	; Define & skip over PSP area for .COM program
.list
.8086
START:
	NPPROC	SWATRUN_INIT -- Main entry point for initialization
	assume	ds:PGROUP,es:PGROUP	; Valid assumptions for .COM file

	lea	sp,Stack_end		; Get top of stack space

	call	Init			; Do initialization
	MJ c	SWATRUN_ERR		; DS:DX ==> error message
DOT386 p
	call	SWATRUN_INIT2	; Call resident initialization code
	jc	near ptr SWATRUN_ERR ; DS:DX ==> error message

; Free unneeded resident code and data

	push	cs			; Address PSP
	pop	es			; Segment to modify
	assume	es:nothing		; Tell the assembler

	lea	bx,End_res[16-1]	; New size in bytes
	shr	bx,4-0			; Convert to paras
	DOSCALL @MODMEM 		; Resize ES to BX paras

;--------------- Code and data in CODE2 and DATA2 is invalid --------------

if @CHANGESTRA
; This code could be used to emulate debugging in the LH environment.
	mov	ax,(@MACALG*256)+00h	; Get strategy
	DOSCALL 			; AX = current allocation strategy
	int	1			; Call SWAT
	mov	Old_stra,ax		; Save for later
	mov	ax,(@MACALG*256)+02h	; Get link state
	DOSCALL 			; AL = 1 if arenas are linked
	sub	ah,ah			; Clear high byte
	mov	Old_link,ax		; Save for later
	mov	bx,1			; Link low and high DOS arenas
	mov	ax,(@MACALG*256)+03h	; Set link state to BX
	DOSCALL 			; Ignore error
	mov	bx,0080h		; First fit high
	mov	ax,(@MACALG*256)+01h	; Set strategy to BX
	DOSCALL 			; Ignore error
endif					; IF @CHANGESTRA
	call	PLUG_HOLES		; Plug up holes below us
					; so we load above us (as calculated
					; in INIT2)
; Load for EXEC

	lea	bx, EXE_block		; ES:BX ==> EXE block
	lea	dx, EXE_name		; DS:DX ==> name to load
	mov	al, 1			; Subfunction 1- load for debugging
	DOSCALL @EXEC			; EXEC
	assume	ds:nothing, es:nothing, ss:nothing
	pushf				; Save CF
	call	UNPLUG_HOLES		; Unplug 'em
	popf				; Restore CF
	jnc	short @F		; Call was successful

	lea	dx, EXECLoad_failed	; Display "EXEC/Load failed"
	jmp	SWATRUN_ERR		; Join common error code

@@:
.8086
	mov	SaveBX,bx		; Save BX from EXEC call
DOT386 p
	DOSCALL @GETPS0 		; BX = PSP
	mov	ds, bx			; Setup client's DS
	mov	es, bx			; Also put PSP in ES
	assume	ds:nothing, es:nothing	; Tell the assembler about it

; By default, the return address for the client program is the first
; instruction after the EXEC call.  We need to change the return address
; in the client's PSP, hence the petty chicanery below.

	assume	ds:PGROUP		; Tell a little white lie
	mov	PSP_TERMINATE.VOFF,offset PGROUP:SWATRUN_RETURN ; Set IP for return
	mov	PSP_TERMINATE.VSEG,cs	; Set CS for return
	assume	ds:nothing		; Retract nose

; If /n(osymbols) option was specified, don't test for load mismatch

	test	SRFlags,@SRF_NOSYMBOLS	; Did we specify Nosymbols?
	jnz	short SWATRUN_ENTER	; Yes, so skip test below

; Get fixup value to compare with Xlat_word

	test	SRFlags,@SRF_EXE	; Izit .EXE format?
	jz	short @F		; Use BX to compare with CS

	add	bx,@PSP_SIZE shr 4	; Skip PSP
@@:
	cmp	bx,Xlat_word		; Izit the same as the first time?
	je	short SWATRUN_ENTER	; Yes, all's cool

	DOSCALL @GETPS0 		; Get client's PSP
	mov	es,bx			; ES:0 is PSP
	assume	es:nothing		; Tell the assembler

	push	bx			; Save PSP block
	mov	bx,cs			; Get our PSP
	DOSCALL @SETPSP 		; Set PSP to BX

	mov	es,es:PSP_ENVIR_PTR	; Get client's environment block
	assume	es:nothing		; Tell the assembler

	DOSCALL @RELMEM 		; Release it

; Release client's PSP

	pop	es			; Get client's PSP from stack
	assume	es:nothing		; Tell the assembler
	DOSCALL @RELMEM 		; Release it

	push	cs			; Move code segment into DS
	pop	ds			; Get data segment for message display
	assume	ds:PGROUP		; Tell the assembler

	lea	dx, EXEC_Mismatch	; Display "Memory configuration changed"
	jmp	SWATRUN_ERR		; Join common error code
	assume	ds:nothing		; Tell the assembler

	Public	SWATRUN_ENTER
SWATRUN_ENTER:
	lss	sp, EXE_BLOCK.Initstack ; Set up stack
	assume	ss:nothing		; Tell the assembler about it

; If this is a .COM file and the stack comes back as 0FFFCh,
; this is a bug in DOS and should be 0FFFEh.
; Some .COM programs (APINIT from Creative Labs) expect the
; stack to be correct and misbehave if not.

	test	SRFlags,@SRF_EXE	; Izit .EXE format?
	jnz	short @F		; Jump if so

	cmp	sp,0FFFCh		; Izit a problem?
	jnz	short @F		; Jump if not

	mov	sp,0FFFEh		; Correct it
@@:
	push	EXE_BLOCK.InitCode	; Put CS:IP on stack

	pushf				; Put flags on stack
	pop	ax			; Get flags in AX
	or	ax,mask $TF		; Set trap flag
	push	ax			; Put flags on stack with TF=1

	mov	ax,-1			; No valid FCB's
	mov	bx,SaveBX		; Restore BX returned from EXEC call
					; Note: all GP registers except AX, BX,
					; SP and all segment registers have been
					; preserved from EXEC call
	xor	cx,cx			; Ensure zero
	xor	dx,dx			; ...
	popf				; Set trap flag

	retf				; Go to first instruction and break

	Public	SWATRUN_RETURN
SWATRUN_RETURN:
	assume	ds:nothing, es:nothing
	push	cs			; Get our code segment
	pop	ds			; Restore DS
	assume	ds:PGROUP		; Tell the assembler

	jnc	@F			; If CF = 0, everything's OK

	lea	dx, EXECLoad_failed	; Tell 'em we failed to load
	jmp	SWATRUN_ERR		; Join common error code
@@:
if @CHANGESTRA
	mov	bx,Old_stra		; Previous allocation strategy
	mov	ax,(@MACALG*256)+01h	; Set strategy to BX
	DOSCALL 			; Ignore error
	mov	bx,Old_link		; Previous arena link state
	mov	ax,(@MACALG*256)+03h	; Set link state to BX
	DOSCALL 			; Ignore error
endif					; IF @CHANGESTRA
	DOSCALL @GETRC			; Get return code

	lea	dx,Stack_end[16-1]	; Get our ending address (para aligned)
	shr	dx,4-0			; Convert bytes to paragraphs

	test	SRFlags,@SRF_BREAKEND	; Did we specify Break at end?
	jz	short @F		; Jump if not

	; AL = return code from client program
	int	01			; "Hello, may I speak to Mr. SWAT?"
@@:
	Public	CLIENT_ERRLEVEL_IN_AL
CLIENT_ERRLEVEL_IN_AL:
	sub	al,al			; Return code 0
	cmp	ah,3			; Did client go resident?
	jne	short SWATRUN_EXIT	; Jump if not

	Public	SWATRUN_TSR
SWATRUN_TSR:
; If client goes resident, we should, too.
	DOSCALL @KEEPRC 		; DX=paras to keep

.8086
	Public	SWATRUN_ERR
SWATRUN_ERR:
	MSGDISP 			; DS:DX already points to error msg
	mov	al, 0ffh		; Return code -1

	Public	SWATRUN_EXIT
SWATRUN_EXIT:
	DOSCALL @EXITRC 		; Return to DOS
DOT386 p

	assume	ds:nothing,es:nothing,ss:nothing

SWATRUN_INIT	endp			; End SWATRUN_INIT procedure

	 NPPROC MSGDISPLAY -- Display ASCIIZ message at PGROUP:DX to STDERR
	 assume ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Display ASCIIZ message at PGROUP:DX.

On entry:
PGROUP:DX ==>	ASCIIZ message text

On exit:
Nothing.

|
	REGSAVE <ax,bx,cx,di,es> ; Save

	push	ds		; Get PGROUP segment
	pop	es		; Prepare for SCASB
	assume	es:nothing	; Tell the assembler

	mov	di,dx		; Offset to scan from
	mov	cx,-1		; Maximum bytes to scan
	sub	al,al		; What to look for
	cld			; Scan forwardly
  repne scas	es:[di].LO	; Find end byte
	not	cx		; Get 1's complement of length + 1
	dec	cx		; Subtract null

	mov	bx,@STD_ERR	; File handle to write to
	DOSCALL @WRITF2 	; Send to stderr

	REGREST <es,di,cx,bx,ax> ; Restore
	assume	es:nothing	; Tell the assembler

	ret			; Return to caller
	assume ds:nothing,es:nothing,ss:nothing

MSGDISPLAY endp 		; End MSGDISPLAY procedure
	NPPROC	UNPLUG_HOLES -- Unplug Holes Below Us
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Unplug holes below us

|

	REGSAVE <ax,bx,cx,es>	; Save registers

; Get start of MAC chain

	DOSCALL @GETLST 	; Get LoL ptr into ES:BX
	assume	es:nothing	; Tell the assembler about it
	mov	es,es:[bx-2]	; Get segment of start of MAC chain
	assume	es:nothing	; Tell the assembler about it

	mov	bx,cs		; Get code segment for comparison
UNPLUG_HOLES_NEXT:
	mov	ax,es		; Get segment

	cmp	ax,bx		; Izit below us?
	jae	short UNPLUG_HOLES_EXIT ; Jump if not

	cmp	es:[0].MAC_OWNR,@MAC_PLUG ; Izit plugged?
	jne	short @F	; Jump if not

	mov	es:[0].MAC_OWNR,@MAC_FREE ; Free it
@@:
	add	ax,es:[0].MAC_NPAR ; Plus # paras in this entry
	inc	ax		; Plus MAC entry
	mov	es,ax		; Address it

	jmp	short UNPLUG_HOLES_NEXT ; Go around again

UNPLUG_HOLES_EXIT:
	REGREST <es,cx,bx,ax>	; Restore
	assume	es:PGROUP	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UNPLUG_HOLES endp		; End UNPLUG_HOLES procedure
	NPPROC	SWATRUN_INIT2 -- Resident initialization code
	assume	ds:PGROUP,es:nothing	; Valid assumptions for .COM file

	lea	bx,End_res2[16-1] ; Get our ending address & make sure it's
				; paragraph aligned
	shr	bx,4-0		; Convert bytes to paragraphs
	DOSCALL @MODMEM 	; Shrink memory allocation - ES = CS = PSP seg

; We don't set up FCB's for client from Cmdtail, although we should to be
; compatible with CP/M style apps...

; If /n (Nosymbols) option was specified, return to caller

	test	SRFlags,@SRF_NOSYMBOLS	; Did we specify Nosymbols?
	jnz	near ptr SRINIT2_EXIT	; Jump if so

COMMENT|

We calculate the client's load address as follows:

1. Blast parent's PSP_ENVIR_PTR into our PSP
2. Calculate the length of parent's environment (not including STRINGS)
3a. Add to #2 the length of the fully qualified pathname EXE_name
3b. If we're on Win95, add one to the EXE_name length to overcome a bug
4. Round up and convert to paragraph value
5. Allocate the number of paras needed for client environment
6. Allocate the maximum paras.	If segment address is contiguous with
   our storage, reduce the load address by the length of End_res2 - End_res.
   Save the resulting PSP address.
7. Free allocations from 5 and 6.

|
; 1. Blast parent's PSP_ENVIR_PTR into our PSP if it exists

	 mov	 es,PSP_CTRL_PSP	; Address parent's PSP (COMMAND.COM)
	 assume  ds:nothing,es:PGROUP	; Tell a little white lie
	 mov	 ax,PSP_ENVIR_PTR	; Get parent's environment segment
	 assume  ds:PGROUP,es:nothing	; Retract nose

; 2. Calculate length of parent's environment
; Note that if INSTALL=SWATRUN.COM progname is used, there will
; be no environment other than the one created for us.

	 or	 ax,ax			; Does environment exist?
	 jz	 short NO_ENV		; Jump if not

	 mov	 es,PSP_ENVIR_PTR	; Get our environment segment
	 assume  es:nothing		; Tell the assembler

	 mov	 PSP_ENVIR_PTR,ax	; Usurp parent's environment segment

	 DOSCALL @RELMEM		; Release segment in ES
NO_ENV:
	 mov	 es,PSP_ENVIR_PTR	; Address environment segment
	 assume  es:nothing		; Tell the assembler

	 sub	 di,di			; Start at beginning
	 mov	 cx,8000h		; Maximum environment size
	 sub	 al,al			; End of environment string
@@:
  repne  scas	 es:[di].LO		; ES:DI ==> byte after 0
	 jne	 short NO_ENV		; Jump if not found (???)

	 cmp	 es:[di].LO,0		; Izit the end of the environment?
	 jne	 short @B		; Go around again if not

; 3a. Add to #2 the length of the fully qualified pathname EXE_name

	 lea	 bx,[di+1+2]		; Save length of environment in bytes
					; plus word for number of STRINGS
	 push	 ds			; Get PGROUP segment
	 pop	 es			; Prepare to address PGROUP
	 assume  es:PGROUP		; Tell the assembler

	 lea	 di,EXE_name		; ES:DI ==> fully qualified pathname
	 mov	 cx,@MAX_PATH		; Maximum length
	 sub	 al,al			; End of program name
  repne  scas	 EXE_name		; ES:DI ==> byte after 0
	 sub	 di,offset PGROUP:EXE_name ; Convert to length

; 3b. If we're on Win95, add one to the EXE_name length to overcome a bug
; This bug is a miscalculation of the environment size by one byte which
; can cause the environment to be one para larger and can cause our
; calculations to fail.  This bug appears to be fixed in Win98

	mov	ax,1600h		; Function code to get Win version
	int	2Fh			; Request multiplexor service

	cmp	al,00h			; Izit not installed?
	je	short @F		; Jump if so

	xchg	al,ah			; Swap to comparison order

	cmp	ax,0400h		; Izit Win95 or later?
	jb	short @F		; Jump if not

	cmp	ax,040Ah		; Izit Win98 or later?
	jae	short @F		; Jump if so

	inc	di			; Add to name length
@@:

; 4. Round up and convert to paragraph value

	 lea	 bx,[bx+di+16-1]	; BX = length in bytes for client env
	 shr	 bx,4-0 		; Convert from bytes to paras

; 5. Allocate the number of paras needed for client environment

	push	bx			; Save actual value

	 mov	 bx,-1			; Impossible segment value
	 DOSCALL @GETMEM		; BX = largest possible value
	 DOSCALL @GETMEM		; AX = environment address

	pop	bx			; Restore
	 lea	 dx,EXEC_alloc		; Error message to display
	 jc	 near ptr SRINIT2_EXIT2 ; Join common error code if we failed

	REGSAVE <ax,es> 		; Save environment address

	mov	es,ax			; Address the block
	assume	es:nothing		; Tell the assembler about it
	DOSCALL @MODMEM 		; Modify down to needed value

	REGREST <es,ax> 		; Restore
	assume	es:PGROUP		; Tell the assembler

; 6. Allocate the maximum paras.  If segment address is contiguous with
;    our storage, reduce the load address by the length of End_res2 - End_res.
;    Note that this condition is fulfilled either a) by the segment address
;    itself or b) by the program's putative environment, when the environment
;    is also contiguous with the program.
;    Save the resulting PSP address.

	 push	 ax			; Save allocated environment block

	 mov	 bx,-1			; Impossible segment value
	 DOSCALL @GETMEM		; BX = largest possible value
	 DOSCALL @GETMEM		; AX = PSP address

	 mov	 bx,cs			; Get our PSP
	 dec	 bx			; Back off to MAC entry
	 mov	 es,bx			; Address PSP MAC entry
	 assume  es:nothing		; Tell the assembler

	 add	 bx,es:[0].MAC_NPAR	; Add length
	 add	 bx,1+1 		; Add MAC entries

	 pop	 cx			; Get environment block for comparison
	 push	 cx			; Put back on stack

	 push	 ax			; Save PSP segment to release later

	 cmp	 bx,ax			; Izit contiguous?
	 je	 short PSP_CONTIGUOUS	; Jump if so (case a)

	 cmp	 bx,cx			; Izit contiguous with the environment?
	 jne	 short NOT_CONTIGUOUS	; Jump if not

; Test for case b.  Ensure that environment is contiguous with PSP.

	 push	 es			; Save our MAC segment

	 dec	 cx			; Back off to environment MAC entry
	 mov	 es,cx			; Address client's environment MAC
	 assume  es:nothing		; Tell the assembler

	 add	 cx,es:[0].MAC_NPAR	; Add length
	 add	 cx,1+1 		; Add environment and PSP MAC entries

	 cmp	 cx,ax			; Is client's environment contiguous with its PSP?

	 pop	 es			; Restore our MAC segment
	 assume  es:nothing		; Tell the assembler

	 jne	 short NOT_CONTIGUOUS	; Jump if not contiguous
PSP_CONTIGUOUS:
	 lea	 bx,End_res[16-1]	; New size in bytes
	 shr	 bx,4-0 		; Convert to paras
	 neg	 bx			; Subtract...
	 add	 bx,es:[0].MAC_NPAR	; ...from current size
	 sub	 ax,bx			; Move load location even further down
NOT_CONTIGUOUS:
	 add	 Xlat_word,ax		; Fix up relocation factor
	 mov	 EES.EES_PSP,ax 	; Save PSP for DOS 5 Enter Exec State
	 add	 EES.EES_CSIP.VSEG,ax	; Fix up initial CS:IP for EES call

; 7. Free allocations from 5 and 6.

	 pop	 es			; Get PSP segment to release
	 assume  es:nothing		; Tell the assembler

	 DOSCALL @RELMEM		; Release segment in ES

	 pop	 es			; Get environment segment to release
	 assume  es:nothing		; Tell the assembler

	 DOSCALL @RELMEM		; Release it

	 push	 ds			; Get PGROUP segment
	 pop	 es			; Restore addressability to PGROUP
	 assume  es:PGROUP		; Tell the assembler

; Set up message

	mov	ax,XLAT_WORD		; Get translation value
	lea	di,EXE2_Hexadd		; address of -sxxxxv+ arg for MAPSSF
	call	Bin2Hex 		; Blast AX into ES:DI as hex string
	lea	di,LoadMsg1		; Address of xxxxh part of "Load..."
	call	Bin2Hex 		; Blast AX into ES:DI as hex string

	MSGDISP LoadMsg 		; Display "Loading..." message

	MSGDISP EXE_name		; Display qualified path

	MSGDISP LoadMsgAt		; Display " at xxxx"

	test	SRFlags,@SRF_MAPNAME or @SRF_SYMNAME ; Did we try to find a symbol file and fail?
	jnz	short @F		; /m, /s, or /n specified, or file found

; Failed to detect .SSF or .MAP file.  Skip call to MAPSSF.

	MSGDISP LoadMsgNoSym		; Display "(no symbol data found)"

	jmp	short SRINIT2_EXIT	; Join common exit code

@@:

; If @SRF_SYMNAME is set, load .SSF file specified

	test	SRFlags,@SRF_SYMNAME	; Did we specify a symbol file name?
	jz	short @F		; Jump if not

	MSGDISP LoadMsgSSF		; Display " ... using SSF file"

	call	Load_ssf		; Load symbols & fixup VM symbols
	jnc	short SRINIT2_EXIT	; Continue if successful

	MSGDISP LoadSSF_failed		; Bitch about failure and continue

	jmp	short SRINIT2_EXIT	; Join common code to reload

@@:
	MSGDISP LoadMsgMAP		; Display "... using MAPSSF"

; EXEC 0 block is already set up.  Do it...

	mov	Stack_save.VSEG,ss	; Save SS across EXEC call
	mov	Stack_save.VOFF,sp	; Save SP across EXEC call
	lea	dx,EXE2_name		; Get 'command'
	lea	bx,EXE2_block		; Get command block
	mov	al, 0			; Subfunction 0: execute
	DOSCALL @EXEC			; Load and execute
	Assume	ds:nothing, es:nothing, ss:nothing

	lss	sp, Stack_save		; Restore our stack
	assume	ss:nothing		; Tell the assembler

	mov	ax,cs			; Get code segment
	mov	ds,ax			; Address code with DS
	mov	es,ax			; Also ES
	assume	ds:PGROUP,es:PGROUP	; Tell the assembler

	jnc	short SRINIT2_EXIT	; Jump if EXEC was OK

	MSGDISP ExecMapFailed		; Display "Could not exec MAPSSF"
SRINIT2_EXIT:
	test	SRFlags,@SRF_NOSYMBOLS	; Did we specify Nosymbols?
	jnz	short @F		; Jump if so

; Display a separator to distinguish MapSSF & SWATRUN output from client

	MSGDISP ExecSep 		; Display separator
@@:

; If DOS 5, call Enter Exec State (EXEC subfunction 5)

	cmp	DOSVER,0500h		; Izit DOS 5 or higher?
	jb	short @F		; Jump if so

	mov	al,5			; Subfunction 5- Enter EXEC state
	DOSCALL @EXEC,EES		; Ignore return code
@@:
	clc				; Indicate success
SRINIT2_EXIT2:
	ret				; Return to caller

	assume	ds:nothing, es:nothing, ss:nothing

SWATRUN_INIT2	endp			; End SWATRUN_INIT2 procedure

CODE	 ends				; End CODE segment

CODE2	 segment  ; Start CODE2 segment
	 assume  cs:PGROUP,ds:PGROUP,es:PGROUP,ss:nothing

	NPPROC Load_ssf -- Load and fixup SSF symbol file
	assume ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

EXE2_path contains ASCIIZ filename of .ssf file.  Read it in,
apply fixup in Xlat_word to all VM non-ABS symbol records, and
pass modified records to SWAT.

On entry:
Nothing.

On exit:
CF = 0		Some symbols were loaded.
   = 1		No symbols were loaded (invalid or nonexistent file, or
		no memory for buffer).

|
	REGSAVE <eax,bx,cx,dx,si,di,ds,es> ; Save

	sub	eax,eax 		; Get a convenient 0
	mov	LSSF_fh,ax		; Initialize file handle (not opened)
	mov	LSSF_bufp,ax		; Initialize buffer pointer
	mov	LoadSSF_Added,eax	; Initialize count of records added

	lea	dx,EXE2_path		; Name of ssf file
	mov	al,0			; Read-only, sharing compatibility mode
	DOSCALL @OPENF2 		; Open file
	jc	near ptr LOAD_SSF_EXIT	; Jump if failed

	mov	LSSF_fh,ax		; Save file handle

	mov	bx,(@LSSF_BUFSIZ+15) shr 4 ; Paragraphs for buffer
	DOSCALL @GETMEM 		; Return segment in AX
	jc	near ptr LOAD_SSF_EXIT	; Jump if failed

	mov	LSSF_bufp,ax		; Save buffer pointer
	mov	ds,ax			; Segment of read buffer
	assume	ds:nothing		; Tell the assembler not to use DS

	mov	bx,LSSF_fh		; File handle for read
	sub	dx,dx			; Offset within buffer segment
	mov	cx,size SSF_STR 	; Bytes to read
	DOSCALL @READF2 		; Read data from handle BX into DS:DX
	jc	near ptr LOAD_SSF_EXIT	; Jump if failed

 ; Check file header data

	cmp	ds:[0].SSF_SIG,@SSF_SIG ; Izit an SSF file?
	jne	near ptr LOAD_SSF_EXIT	; Jump if not

	mov	eax,ds:[0].SSF_COUNT	; Get number of records
	or	eax,eax 		; Izit non-zero?
	jz	near ptr LOAD_SSF_EXIT	; Jump if empty

	mov	LSSF_symcnt,eax 	; Save total record count
	ror	eax,16			; Get high word of count
	lea	di,LoadSSF_shortlft	; Location for total record display
	call	Bin2Hex 		; Convert AX; ES:DI updated
	ror	eax,16			; Restore low word of count
	call	Bin2Hex 		; Convert low word

	cmp	ds:[0].SSF_VER,@SSF_CVER ; Izit version 0.11 or higher?
	jnb	short @F		; Flags and pointer supported

	mov	ds:[0].SSF_FLAGS,0	; Simulate flags cleared
	mov	ds:[0].SSF_DATA,@SSF_OLDDATA ; Simulate data offset
@@:
	test	ds:[0].SSF_FLAGS,@SSFFL_FLUSH ; Was flush specified in SSF file?
	jnz	short LOAD_SSF_FLUSH	; Jump if so

; If /o option was specified, ask SWAT to flush symbol table

	cmp	EXE2_overflg.ELO.HI,'o' ; Did we process /o option?
	jne	short @F		; Jump if not
LOAD_SSF_FLUSH:
	mov	bl,@DBGSYM_FLUSH	; Symbol table flush subservice
	VCPICALL @VCPI_DBGSYM		; Call debugger API
@@:
	mov	Append_mode,@DBGSYM_APPND ; Assume normal append
	test	ds:[0].SSF_FLAGS,@SSFFL_RAW ; Was raw append specified?
	jz	short @F		; Jump if not

	mov	Append_mode,@DBGSYM_RAPPND ; Raw append (dupes allowed)
@@:
	mov	cx,ds:[0].SSF_DATA.EHI	; High word of seek offset
	mov	dx,ds:[0].SSF_DATA.ELO	; Low word	 "
	sub	al,al			; Seek from beginning of file
	mov	bx,LSSF_fh		; Get file handle
	DOSCALL @MOVFP2 		; Move file pointer, return in DX:AX
	jc	near ptr LOAD_SSF_EXIT	; Jump if failed

	sub	dx,dx			; Address start of buffer
	mov	cx,@LSSF_BUFSIZ 	; Attempt to fill buffer
	mov	LSSF_cnt,0		; Initialize bytes remaining

LOAD_SSF_GETBLOCK:
	mov	bx,LSSF_fh		; Get file handle
	DOSCALL @READF2 		; Read data from BX into DS:DX
	jc	near ptr LOAD_SSF_EXIT	; Jump if failed

	or	ax,ax			; Izit EOF?
	jz	near ptr LOAD_SSF_EXIT	; Jump if so

	add	LSSF_cnt,ax		; Add bytes read to bytes remaining
	mov	cx,LSSF_cnt		; Keep bytes remaining in CX
	mov	LSSF_symsub,0		; Clear record subtotal

	sub	si,si			; Address start of buffer
	mov	ax,Xlat_word		; Fixup value for VM segments

; Trundle through the records, fixing up VM segments.
; Keep track of the number of records for the SWAT API call.

LOAD_SSF_FIXNEXT:
	mov	bx,ds:[si].ISYM_FLAG	; Grab flags

	test	bx,mask $SYMFL_VM	; Izit a real mode segment?
	jz	short LOAD_SSF_SKIP	; Jump if not

	and	bx,mask $SYMFL_TYP	; Mask off record type field

	cmp	bx,@SYMTYP_ABS shl $SYMFL_TYP ; Izit an ABS record?
	je	short LOAD_SSF_SKIP	; Jump if so

	add	ds:[si].ISYM_FVEC.FSEL,ax ; Fixup segment
LOAD_SSF_SKIP:
	inc	LSSF_symsub		; Bump record count
	movzx	bx,ds:[si].ISYM_SYMLEN	; Get length of name
	add	bx,size ISYM_STR	; Add length of structure
	add	si,bx			; Skip to next record
	sub	cx,bx			; Keep track of remaining bytes

	cmp	cx,(size ISYM_STR) + 1	; Izit the minimum size?
	jb	short @F		; Jump if not

	dec	LSSF_symcnt		; Adjust count
	jz	short @F		; Jump if done

	movzx	bx,ds:[si].ISYM_SYMLEN	; Get length of next name
	add	bx,size ISYM_STR	; Add structure length
	cmp	cx,bx			; Izit all there?
	ja	short LOAD_SSF_FIXNEXT	; Jump if not

@@:
; Add LSSF_symsub to LSSF_symcnt, and send contents of buffer up to SWAT
	REGSAVE <ecx,esi,ds>		; Save

	movzx	ecx,LSSF_symsub 	; Get number of records
	or	ecx,ecx 		; Are there any left?
	jz	short @F		; Jump if none (note CF=0)

	sub	esi,esi 		; Address start of buffer
	mov	bl,Append_mode		; Append entries subservices
	VCPICALL @VCPI_DBGSYM		; Call SWAT API
	add	LoadSSF_Added,ecx	; Update total successfully added
	or	ah,ah			; Did we succeed?
	jz	short @F		; Jump if so (note CF=0)

; Call failed.	Display error message and exit.
	mov	ax,LoadSSF_Added.EHI	; Get high word of number to convert
	lea	di,LoadSSF_shortld	; Offset for hex string
	call	Bin2Hex 		; Convert AX to hex; ES:DI updated
	mov	ax,LoadSSF_Added.ELO	; Get low word
	call	Bin2Hex 		; Convert to hex

	push	es			; Get PGROUP segment
	pop	ds			; Segment of message
	assume	ds:PGROUP		; Tell the assembler

	MSGDISP LoadSSF_short		; "Only x symbols out of y were loaded"

	stc				; Indicate failure
@@:
	REGREST <ds,esi,ecx>		; Restore
	assume	ds:nothing		; Tell the assembler

	jc	short LOAD_SSF_EXIT0	; Bail out if not all symbols went up

	cmp	LSSF_symcnt,0		; Do we have any left?
	jz	short LOAD_SSF_EXIT0	; Jump if not

; We may have part of a record.  We need to move it to the beginning of the
; buffer and reset the read pointer so that the data read in will be appended.
; This convoluted scheme ensures that we always have a record-granular
; buffer without doing time-consuming disk seeks.
	sub	di,di			; Assume start of buffer
	mov	bx,cx			; Save number of bytes
	mov	LSSF_cnt,cx		; Reinitialize bytes remaining
	or	cx,cx			; Is there anything left?
	jz	short LOAD_SSF_CALCBUF	; Jump if not

; Move CX bytes from DS:SI to beginning of buffer, leaving
; DS:DI ==> location in buffer for next file read.
	push	es			; Save for a moment
	mov	es,LSSF_bufp		; Address buffer segment
	assume	es:nothing		; Tell the assembler
   rep	movs	es:[di].LO,ds:[si].LO	; Move it
	pop	es			; Restore
	assume	es:PGROUP		; Tell the assembler

LOAD_SSF_CALCBUF:
; DS:DI ==> at or past buffer start.  Move it into DX for file read.
; Put 32K-BX in CX for bytes to read.
	mov	dx,di			; Load DX for read
	mov	cx,@LSSF_BUFSIZ 	; Attempt to fill buffer
	sub	cx,bx			; Subtract bytes already in buffer
	jmp	near ptr LOAD_SSF_GETBLOCK ; Get next chunk of file

LOAD_SSF_EXIT0:
	clc				; Indicate success
LOAD_SSF_EXIT:
	pushf				; Save flags (CF significant)

	mov	bx,LSSF_fh		; Get file handle
	or	bx,bx			; Izit valid?
	jz	short @F		; Jump if not

	DOSCALL @CLOSF2 		; Close file handle in BX
@@:
	mov	ax,LSSF_bufp		; Get buffer pointer
	or	ax,ax			; Izit empty?
	jz	short @F		; Jump if so

	push	es			; Save for a moment
	mov	es,ax			; Prepare to release pointer
	assume	es:nothing		; Tell the assembler
	DOSCALL @RELMEM 		; Release pointer in ES
	pop	es			; Restore
	assume	es:PGROUP		; Tell the assembler
@@:

	popf				; Restore flags with CF significant

	REGREST <es,ds,di,si,dx,cx,bx,eax> ; Restore
	assume	ds:PGROUP		; Tell the assembler

	ret				; Return to caller
	assume ds:nothing,es:nothing,ss:nothing

Load_ssf	endp			; End Load_ssf procedure

	 NPPROC HexByte -- Convert AL to ASCII hex digit
	 assume ds:PGROUP,es:PGROUP,ss:nothing
COMMENT |
On entry:	AL = binary value
On exit:	AH,AL = ASCII value
|

	mov	ah,al	; save AL
	shr	al,4	; get high nybble of AL
	call	HexDigitSub ; convert to hex digit in AL
	xchg	ah,al	; get low nybble in AL, save ASCII high in AH

	Public	HEXDIGITSUB
HEXDIGITSUB:
	and	al,0fh	; Mask off low nybble
	add	al,90h	; Add 90h so DAA will set CF on wrap past 99h
	daa		; Convert to BCD & set CF if A-F
	adc	al,'@'  ; Add 40h + CF (no change to low nybble if 0-9)
	daa		; Convert to BCD (ignore CF)

	ret		; return to caller

	assume ds:nothing,es:nothing,ss:nothing

HexByte 	endp	; End HexByte procedure

	 NPPROC Bin2Hex -- Convert AX to hex string at es:di
	 assume ds:PGROUP,es:PGROUP,ss:nothing
COMMENT |
On entry:	AX = unsigned integer
		ES:DI ==> location to write hex string

On exit:	ES:DI ==> updated to pointer after string
|

	REGSAVE ax		; Save caller's register

	cld			; Set forward direction
	push	ax		; Save ax
	mov	al,ah		; Get high byte in AL
	call	HexByte 	; AH,AL = ASCII digits
	xchg	ah,al		; swap byte order
	stosw			; blast into string
	pop	ax		; Restore original AX
	call	HexByte 	; AH,AL = Ascii digits for low byte
	xchg	ah,al		; swap byte order
	stosw			; blast into string

	REGREST ax		; Restore caller's register

	ret			; Return to caller

	assume ds:nothing,es:nothing,ss:nothing

Bin2Hex endp			; End Bin2Hex procedure
	NPPROC	PLUG_HOLES -- Plug Holes Below Us
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Plug holes below us

|

	REGSAVE <ax,bx,cx,es>	; Save registers

; Get start of MAC chain

	DOSCALL @GETLST 	; Get LoL ptr into ES:BX
	assume	es:nothing	; Tell the assembler about it
	mov	es,es:[bx-2]	; Get segment of start of MAC chain
	assume	es:nothing	; Tell the assembler about it

	mov	bx,cs		; Get code segment for comparison
PLUG_HOLES_NEXT:
	mov	ax,es		; Get segment

	cmp	ax,bx		; Izit below us?
	jae	short PLUG_HOLES_EXIT ; Jump if not

	cmp	es:[0].MAC_OWNR,@MAC_FREE ; Izit free?
	jne	short @F	; Jump if not

	mov	es:[0].MAC_OWNR,@MAC_PLUG ; Plug it
@@:
	add	ax,es:[0].MAC_NPAR ; Plus # paras in this entry
	inc	ax		; Plus MAC entry
	mov	es,ax		; Address it

	jmp	short PLUG_HOLES_NEXT ; Go around again

PLUG_HOLES_EXIT:
	REGREST <es,cx,bx,ax>	; Restore
	assume	es:PGROUP	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PLUG_HOLES endp 		; End PLUG_HOLES procedure

CODE2	 ends				; End CODE2 segment

NCODE	 segment			; Begin non-resident code segment

	 extrn	 _SWAT_PRESENT:far

	 NPPROC IZITSEP -- Is AL a command separator?
	 assume ds:PGROUP,es:nothing,ss:nothing
COMMENT|

If AL is a member of ValPathTerms (which includes 0) return ZF=1.

|

	REGSAVE <cx,di,es>		; Save

	push	ds			; Get PGROUP segment
	pop	es			; Address for SCAS
	assume	es:PGROUP		; Tell the assembler

	mov	cx,@VALPATHTERMLEN	; Number of characters to scan
	lea	di,ValPathTerms 	; Set to scan
	cld				; Ensure string ops forwardly
  repne scas	ValPathTerms[di]	; Set ZF if found

	REGREST <es,di,cx>		; Restore
	assume	es:nothing		; Tell the assembler

	ret				; Return to caller

	assume	ds:nothing,es:nothing,ss:nothing

IZITSEP endp				; End IZITSEP procedure
	 NPPROC Calc_cmdlength -- Calculate length of EXE2_cmdtail
	 assume ds:PGROUP,es:PGROUP,ss:nothing
COMMENT |

Calculate length of EXE2_cmdtail and store it in EXE2_cmdtail[0].
No output.

|

	REGSAVE <ax,bx,cx,di>		; Save registers

	lea	di,EXE2_cmdtail[1]	; Address beginning of data
	sub	al,al			; Search for null
	mov	cx,-1			; Maximum length
  repne scas	PGROUP:[di].LO		; ES:DI ==> byte after trailing null
	not	cx			; Get 1's complement of length + null
	dec	cx			; Subtract null
	mov	EXE2_cmdtail[0],cl	; Set length

	REGREST <di,cx,bx,ax>		; Restore registers

	ret				; Return to caller
	assume ds:nothing,es:nothing,ss:nothing

Calc_cmdlength		endp

	NPPROC	GETSYM -- Get symbol file name and copy to EXE2_path
	assume	ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Get the base name of the file we're loading, check for a symbol file
if one wasn't explicitly specified, and set SRFlags accordingly.

|

	REGSAVE <eax,bx,si,di,es>	; Save

	; Copy fname part if we did not specify an ssf file name with the
	; /sSYMNAME option, or a map name with the /mMAPNAME option...
	test	SRFlags,(@SRF_SYMNAME or @SRF_MAPNAME) ; Did we specify an SSF or MAP file name?
	jnz	short GETSYM_EXIT	; Jump if so

	lea	si, EXE_name		; DS:SI ==> path name
	lea	di, EXE2_path		; ES:DI ==> path sans .ext
	sub	bx,bx			; BX gets address of last '.'

Copy_basename:
	lodsb				; Get byte
	cmp	al,'.'                  ; Izit a .?
	jne	short @F		; Nope
	mov	bx,di			; Save offset
@@:
	stosb				; Store byte in target string

	cmp	al,'\'                  ; Izit a path separator?
	jne	short @F		; Jump if not

	sub	bx,bx			; Clear last '.' pointer
	jmp	short Copy_basename	; Get next byte

@@:
	call	IZITSEP 		; Is AL a command separator?
	jne	short Copy_basename	; Jump if not

Copy_done:
	dec	di			; Back up to terminating \0
	or	bx,bx			; Was there an extension?
	jz	short @F		; Jump if not

	mov	di,bx			; Set extension offset
@@:
	; PGROUP:DI ==> location for '.SSF', '.MAP'
	lea	si,Symextlist		; Address list of symbol file extensions
	mov	cx,@SYMEXTLIST_SIZ	; Number of iterations
	mov	bx,@SRF_LAST		; Starting mask
	mov	PGROUP:[di].LO[4],0	; Null terminate filename

Symfile_chk_next:
	lods	PGROUP:[si].EDD 	; Get extension
	mov	PGROUP:[di].EDD,eax	; Blast into filename

	; Check for existence
	REGSAVE <bx,cx,si,di>		; Save for a moment
	mov	al,0			; Subfunction 0: get file mode
	lea	dx,EXE2_path		; Filename to check
	DOSCALL @GSTMOD 		; Get file mode in CX
	REGREST <di,si,cx,bx>		; Restore

	jc	short @F		; Jump if file does not exist or is
					; unreadable
	or	SRFlags,bx		; Mark type of file found
	jmp	short EXEC_FOUNDSYM	; Join common code for symbol file found

@@:
	shr	bx,1			; Shift mask
	loop	Symfile_chk_next	; Try next extension

	jmp	 short GETSYM_EXIT	; Failed; join common exit

EXEC_FOUNDSYM:
	call	Calc_cmdlength		; Calculate length of EXE2_cmdtail

GETSYM_EXIT:
	REGREST <es,di,si,cx,bx,eax>	; Save
	assume	es:nothing		; Tell the assembler

	ret				; Return to caller

	assume	ds:nothing,es:nothing,ss:nothing ; Tell the assembler

GETSYM	endp				; End GETSYM procedure
	NPPROC IzitSwitch -- Determine whether character in AL is a switchar
	assume ds:PGROUP,es:PGROUP,ss:nothing
COMMENT |

If AL is a switch character, return CF=0.  Otherwise, return CF=1.

|

	cmp	al,'/'                  ; Izit '/'?
	je	short IZITSWITCH_EXIT	; Yes (Note CF=0)

	cmp	al,'-'                  ; Izit '-'?
	je	short IZITSWITCH_EXIT	; Yes (Note CF=0)

	stc				; Indicate it's not a switch

IZITSWITCH_EXIT:
	ret				; Return to caller
	Assume ds:nothing,es:nothing,ss:nothing

IzitSwitch endp 			; End IzitSwitch procedure
	 NPPROC ToUpper -- Convert AL to uppercase if alphabetic
	 assume ds:PGROUP,es:PGROUP,ss:nothing
COMMENT |

If AL is in the range a-z, convert to uppercase.

|

	cmp	al,'a'                  ; Izit < 'a'?
	jb	short @F		; No conversion

	cmp	al,'z'                  ; Izit > 'z'?
	ja	short @F		; No conversion

	sub	al,'a'-'A'              ; Convert to uppercase

@@:
	ret				; Return to caller
	assume ds:nothing,es:nothing,ss:nothing

ToUpper 	endp			; End ToUpper procedure

	 NPPROC SkipWhite -- Skip over white space in DS:SI with count in CX
	 assume ds:PGROUP,es:PGROUP,ss:nothing
COMMENT |

Scan to first non-space character.  Return ZF=1 if end of string.
SI and CX are updated.

|

	REGSAVE <ax>			; Save registers

SKIPWHITE_NEXT:
	lodsb				; Get next character

	or	al,al			; Izit the end of the string?
	jz	short SKIPWHITE_EXIT	; Jump if so (ZF=1)

	cmp	al,' '                  ; Izit space?
	je	short @F		; Keep scanning if so

	cmp	al,TAB			; Izit a tab character?
	je	short @F		; Keep scanning if so

	lea	si,[si-1]		; Point SI to previous character
	jmp	short SKIPWHITE_EXIT	; Join common exit code (note ZF=0)

@@:
	loop	SKIPWHITE_NEXT		; Get next character
	or	cx,cx			; Set ZF if CX = 0

SKIPWHITE_EXIT:
	REGREST <ax>			; Restore registers

	ret				; Return to caller
	assume ds:nothing,es:nothing,ss:nothing

SkipWhite	endp			; End SkipWhite procedure

	NPPROC	GET_ALTMAP -- Get alternate MAP or SSF name
	assume ds:PGROUP,es:PGROUP,ss:nothing
COMMENT |

On input:	ds:si ==> first character of map/ssf filename
		bx = terminating characters (\r\0 for MAP, \0\0 for SSF)
		cx = characters remaining in command line
Output: 	ds:si ==> first character after map/ssf filename
		cx = characters remaining in command line after map filename

|

	lea	di,EXE2_Path		; Get address of map/ssf filename
	call	SkipWhite		; Skip over whitespace
	jz	short MAPNAME_NULL	; If empty, truncate

MAPNAME_COPY:
	lodsb				; Get character

	call	IZITSEP 		; Is AL a command separator?
	je	short MAPNAME_BACK	; End of the road if so

	stosb				; Put it in map name

	loop	MAPNAME_COPY		; Get next character

MAPNAME_BACK:
	dec	si			; Back off to space
	inc	cx			; Adjust count

MAPNAME_NULL:
	call	Calc_cmdlength		; Calculate length of EXE2_cmdtail
					; (used for mapfile loads only)

	mov	ax,bx			; Get terminator in AX
	stosw				; Terminate the sucker

	ret				; Return to caller
	Assume ds:nothing,es:nothing,ss:nothing

GET_ALTMAP		endp		; End GET_ALTMAP procedure

	NPPROC ParseCmd -- Parse command line for options and filename
	assume ds:PGROUP,es:PGROUP,ss:nothing
COMMENT |

Parse command line in PSP for options and filename.
Return CF=0 if successful.

Input:	None.
Output: CF=0	Success
	CF=1	Failure, DS:DX ==> error message

|

	movzx	cx, PSP_PARM_COUNT	; Get length of command line
	or	cx,cx			; Izit 0?
	jz	near ptr PARSE_NOFILENAME ; If empty, abort

	lea	si, PSP_PARM_STRING	; Get address of command line

	call	SkipWhite		; Skip space
	jz	near ptr PARSE_NOFILENAME ; If empty, abort

	cmp	PGROUP:[si].LO,CR	; Izit the end?
	je	near ptr PARSE_NOFILENAME ; If empty, abort

PARSECMD_SKIPSPACE:
	call	SkipWhite		; Skip over spaces
	jz	near ptr PARSECMD_DONE	; End of string

	lodsb				; Get character

	cmp	al, CR			; Izit CR?
	je	near ptr PARSECMD_DONE	; End of command line

	call	IzitSwitch		; Izit a switch character?
	jc	near ptr PARSECMD_FNAME ; Get filename & arguments

	dec	cx			; Adjust count
PARSECMD_OPTION:
	lodsb				; Get first letter of option group
	dec	cx			; Adjust count

PARSECMD_OPTION2:
	;;; process options
	call	ToUpper 		; Convert to upper case

	lea	dx,Syntax		; Display "Syntax" message
	cmp	al, '?'                 ; Izit ?
	je	near ptr PARSECMD_ERR	; Treat it as an error

	cmp	al,'B'                  ; Izit Break?
	jne	short @F		; Nope

	or	SRFlags,@SRF_BREAK	; Indicate int 1 before starting
	jmp	short PARSECMD_OPTNEXT	; Get next option

@@:
	cmp	al,'M'                  ; Izit Mapname?
	jne	short @F		; Nope

	or	SRFlags,@SRF_MAPNAME	; Indicate map filename specified
	mov	bx,CR			; Terminate with \r\0
	call	GET_ALTMAP		; Copy alternate .MAP file name
	jmp	short PARSECMD_OPTNEXT	; Get next option

@@:
	cmp	al,'N'                  ; Izit Nosymbols?
	jne	short @F		; Nope

	or	SRFlags,@SRF_NOSYMBOLS	; Indicate no loading of symbols

	jmp	short PARSECMD_OPTNEXT	; Get next option

@@:
	cmp	al,'O'                  ; Izit Overwrite?
	jne	short @F		; Nope

	mov	EXE2_overflg.ELO,'o-'   ; Blank out overwrite flag for mapssf

	jmp	short PARSECMD_OPTNEXT	; Get next option

@@:
	cmp	al,'S'                  ; Izit Symname?
	jne	short @F		; Nope

	or	SRFlags,@SRF_SYMNAME	; Indicate .SSF filename specified
	sub	bx,bx			; Terminate with \0\0
	call	GET_ALTMAP		; Copy alternate .SSF file name

	jmp	short PARSECMD_OPTNEXT	; Get next option

@@:
	cmp	al,'Z'                  ; Izit Break at end?
	jne	short @F		; Nope

	or	SRFlags,@SRF_BREAKEND	; Indicate int 1 after ending

	jmp	short PARSECMD_OPTNEXT	; Get next option

@@:
	jmp	short PARSECMD_OPTERR	; Undefined option

PARSECMD_OPTNEXT:
	jcxz	short PARSECMD_DONE	; Are we done?

	lodsb				; get next letter

	cmp	al, ' '                 ; Izit ' '?
	je	short PARSECMD_OPTEND	; End of option group

	cmp	al,TAB			; Izit other whitespace?
	je	short PARSECMD_OPTEND	; End of option group

	call	IzitSwitch		; Is AL a switch character?
	jnc	short PARSECMD_OPTION	; Get next option group

	loop	PARSECMD_OPTION2	; get next option

	jmp	short PARSE_NOFILENAME	; Join common error code for no filename

PARSECMD_OPTEND:
;;;;;;; loop	PARSECMD_SKIPSPACE	; Get next token on command line
	dec	cx			; One fewer token on command line
	jnz	PARSECMD_SKIPSPACE	; Jump if more

	jmp	short PARSE_NOFILENAME	; Join common error code for no filename

PARSECMD_OPTERR:
	lea	dx,InvalidOption	; Display "Invalid option"

	jmp	short PARSECMD_ERR	; Join common error code

PARSECMD_FNAME:
	lea	di, EXE_Name		; es:di points to local buffer
@@:
	call	IZITSEP 		; Is AL a command separator?
	je	short PARSECMD_FNAME_END ; Jump if so (end of fname)

	stosb				; Stash it in our buffer
	lodsb				; Get next

	loop	@B			; Repeat until line is finished
PARSECMD_FNAME_END:
	xchg	ah, al			; Save character
	sub	al, al			; Get a \0 in al
	stosb				; Terminate the sucker
	lea	di, EXE_cmdtail 	; es:di points to local copy of cmdtail
	mov	al,cl			; Get length of cmdtail - ignore hi byte
	stosb				; Put length in EXE_cmdtail
	xchg	ah, al			; Restore character
@@:
	stosb				; Put character in local cmdtail
	jcxz	PARSECMD_FNAME_NULL	; CX may be 0 on entry

	lodsb				; Get next

	loop @B 			; Until command line is done
PARSECMD_FNAME_NULL:
	cmp	PGROUP:[di-1].LO,CR	; Is there already a CR at the end?
	je	short PARSECMD_DONE	; Jump if so

	mov	ax,CR			; Get a \0 in AH; AL = CR
	stosw				; Make sure it's \r\0 terminated
PARSECMD_DONE:
	lea	dx,FileNotFound 	; Display "File not found" if we fail
	call	QualifyPath		; Expand filename to full path
	jc	short PARSECMD_EXIT	; Join common exit with CF significant

	call	GETSYM			; Find symbol file
	clc				; Indicate success
	jmp	short PARSECMD_EXIT	; Join common exit with CF significant

PARSE_NOFILENAME:
	lea	dx,NoFilename		; Display "No filename specified"
PARSECMD_ERR:
	stc				; Indicate failure
PARSECMD_EXIT:
	ret				; Return to caller

	assume ds:nothing,es:nothing,ss:nothing

ParseCmd endp				; End ParseCmd procedure
	 NPPROC QualifyPath -- Expand Exe_name into full path
	 assume ds:PGROUP,es:PGROUP,ss:nothing
COMMENT |

Besides converting a simple filename into a full path with drive
letter, we also look for .COM and .EXE extensions (in that order)
if no extension was specified.

On entry:
Exe_name	filename as passed on command line

On exit:
Exe_name	fully qualified path to file, including drive and extension
Xlat_word	10h if file has .EXE header, otherwise unchanged
CF=0		file exists
CF=1		file does not exist

|

QP_STR	 struc				; Local variables for QualifyPath
QP_FH	 dw	?			; File handle
QP_EXE	 db (size EXE_STR) dup (?)	; EXE header
QP_STR	 ends

QP_FLAGS equ	ELO[(size QP_STR)]	; Return flags (CF significant)

	pushad				; Save GP regs

	pushf				; Allocate space for flags on return

	sub	sp,size QP_STR		; Allocate local storage
	mov	bp,sp			; Prepare to address stack

	mov	[bp].QP_FH,-1		; Mark file as never opened

	lea	di,Exe_name		; Start of filename
	sub	al,al			; Find end of string
	mov	cx,-1			; Don't care how far we look
	cld				; String ops forwardly
  repne scas	PGROUP:[di].LO		; ES:DI points past trailing null
	dec	di			; Back off to trailing null
	mov	bx,di			; Save pointer to end

	mov	cx,4			; Maximum length of extension
	std				; Do it backwards
	mov	al,'.'                  ; What to look for
	dec	di			; Point to last character of string
  repne scas	PGROUP:[di].LO		; ES:DI points to character before '.'

	cld				; Restore direction flag
	mov	cx,0+1			; Assume it has an extension
	lea	si,Ext_list		; Index start of extension list
	je	short QPATH_TESTFNAME	; If it has an extension, test existence

; Filename has no extension.  Try .COM and .EXE
	mov	cx,@EXT_LISTSIZ 	; Loop counter for extensions
QPATH_ADDEXT:
	lods	PGROUP:[si].EDD 	; Get extension in EAX
	mov	PGROUP:[bx].EDD,eax	; Blast into filename
	mov	PGROUP:[bx].EDQHI.LO,0	; Ensure null terminator

QPATH_TESTFNAME:
	REGSAVE <bx,cx> 		; Save loop counter & end pointer

	lea	dx,Exe_name		; DS:DX ==> filename
	sub	al,al			; Subfunction 0: get file attributes
	DOSCALL @GSTMOD 		; Return attributes in CX or CF=1

	REGREST <cx,bx> 		; Restore

	jnc	short QPATH_FOUNDFILE	; Jump if file exists

	loop	QPATH_ADDEXT		; Try another extension

; If we fell through, file did not exist
	stc				; Indicate failure
	jmp	near ptr QPATH_EXIT	; Join common exit code

; We have an existing filename.  Read header data for DOS 5 EES.
QPATH_FOUNDFILE:
	mov	al,0			; Read-only, sharing compatibility
	DOSCALL @OPENF2,Exe_name	; Open file
	jc	near ptr QPATH_EXIT	; Join common exit if failed

	mov	[bp].QP_FH,ax		; Save file handle
	mov	bx,ax			; Put in BX for read
	mov	cx,size EXE_STR 	; Bytes to read
	DOSCALL @READF2,[bp].QP_EXE	; Read EXE header
	jc	near ptr QPATH_EXIT	; Jump if failed

	cmp	ax,size EXE_STR 	; Did we get the entire header?
	jne	short QPATH_NOTEXE	; Jump if not (not an EXE file)

	cmp	[bp].QP_EXE.EXE_SIGN,@EXE_SIGN ; Does the signature match?
	je	short @F		; Jump if so

	cmp	[bp].QP_EXE.EXE_SIGN,@EXE_SIG2 ; Does alternate signature match?
	jne	short QPATH_NOTEXE	; Jump if not
@@:
; Adjust the file size Q512 down by one if R512 not zero
	movzx	eax,[bp].QP_EXE.EXE_Q512 ; Get image size / 512

	cmp	[bp].QP_EXE.EXE_R512,1	; Iff R512 != 0, CF=0
	cmc				; Iff R512 != 0, CF=1
	sbb	ax,0			; Subtract 1 iff R512 != 0

	shl	eax,9-0 		; Convert from 512 bytes to bytes
	add	ax,[bp].QP_EXE.EXE_R512 ; Add remainder (ignore CF- low order
					; 9 bits only are significant)
	movzx	ebx,[bp].QP_EXE.EXE_HSIZ ; Get header size in paras
	shl	ebx,4-0 		; Convert from paras to bytes
	sub	eax,ebx 		; Subtract from file size
	mov	EES.EES_FLAGS,@EES_EXE	; Flag as .EXE format
	or	SRFlags,@SRF_EXE	; ...
	mov	Xlat_word,@PSP_SIZE shr 4 ; Skip PSP for translation
	mov	bx,[bp].QP_EXE.EXE_CS	; Initial CS (to fix up later)
	shl	ebx,16			; High word of segment:offset
	mov	bx,[bp].QP_EXE.EXE_IP	; Initial IP
	jmp	short QPATH_INITEES	; Join common code

QPATH_NOTEXE:
	mov	al,2			; Seek from end of file
	sub	cx,cx			; Zero high word of seek offset
	sub	dx,dx			; Zero low word
	DOSCALL @MOVFP2 		; Return file size in DX:AX
	jc	near ptr QPATH_EXIT	; Join common exit if failed

	xchg	dx,ax			; Get high order word
	shl	eax,16			; Move it over
	mov	ax,dx			; Get low order word
	mov	ebx,@PSP_SIZE		; Initial (CS:)IP for .COM files
;;;;;	jmp	short QPATH_INITEES	; Join common code

QPATH_INITEES:
; Setup data for EES call prior to 4B01 call
; On entry:	EAX = image size less PSP
;		EBX = initial CS:IP
	add	eax,@PSP_SIZE		; Add size of PSP
	mov	EES.EES_SIZE,eax	; Set size in bytes including PSP
	mov	EES.EES_NAME.VOFF,offset PGROUP:Exe_name ; File name offset
	mov	EES.EES_NAME.VSEG,ds	; ...segment
	mov	EES.EES_CSIP,ebx	; Save initial CS:IP

; Expand to a full drive:path\filespec
	lea	si,Exe_name		; File name to copy
	lea	di,Exe_name2		; Temporary destination
@@:
	lods	PGROUP:[si].LO		; Get a byte
	stos	PGROUP:[di].LO		; Copy it
	or	al,al			; Izit the end?
	jnz	short @B		; Jump if not

; If drive letter is included, that's the directory we need to get
;;;;	sub	al,al			; Drive to get directory for
	cmp	Exe_name[1],':'         ; Is Exe_name[0] a drive letter?
	jne	short QPATH_NODRIVE	; No drive specified

	cmp	Exe_name[2],'/'         ; Is Exe_name already a full path?
	je	near ptr QPATH_EXIT	; Jump if so

	cmp	Exe_name[2],'\'         ; Izit already a path?
	je	near ptr QPATH_EXIT	; Jump if so

	mov	al,Exe_name[0]		; Get drive letter
	and	al,5fh			; Make it uppercase
	sub	al,'@'                  ; A=1, B=2, C=3,...
	jc	near ptr QPATH_EXIT	; Exit with CF=1

QPATH_NODRIVE:
	mov	dl,al			; Drive to get dir for (0=default or
					; toupper(d) - '@'
	mov	Exe_name[2],'\'         ; Add backslash after colon
	lea	si,Exe_name[3]		; Place to store directory part of path
	DOSCALL @GETDIR 		; Path ==> DS:[SI]
	jc	short QPATH_EXIT	; Exit with CF=1 if we failed

	cmp	Exe_name[1],':'         ; Was a drive letter specified?
	je	short DRIVE_SPECIFIED	; Jump if so (d:filename)

	DOSCALL @GETDSK 		; Get default drive in AL ('A'=0)
					; (No error return code)

	add	al,'A'                  ; Convert to letter
	mov	Exe_name[0],al		; Set drive letter
	mov	Exe_name[1],':'         ; Set ':'

; If the user-supplied path started from the root, we need only add
; a drive letter.
	lea	di,Exe_name[2]		; Index past ':' in drive:[\directory]
	lea	si,Exe_name2		; Index original \pathspec

	cmp	Exe_name2[0],'\'        ; Was it a complete path without drive?
	je	short QPATH_DRIVEONLY	; Jump if so

	cmp	Exe_name2[0],'/'        ; Was it a complete path without drive?
	jne	short DRIVE_SPECIFIED	; Jump if not

; Add complete path to the drive letter and colon
QPATH_DRIVEONLY:
	lods	PGROUP:[si].LO		; Get char from original \pathspec
	stos	PGROUP:[di].LO		; Add to d:\pathspec
	or	al,al			; Izit the end of string?
	jnz	short QPATH_DRIVEONLY	; Jump if not

	jmp	short QPATH_EXIT	; We're done

DRIVE_SPECIFIED:
	lea	di,Exe_name		; Address drive:\directory
	sub	al,al			; Search for end
	mov	cx,-1			; 64K-1
  repne scas	PGROUP:[di].LO		; ES:DI ==> past trailing null
	dec	di			; Back up to trailing null

	cmp	PGROUP:[di-1].LO,'\'    ; Does it already end with backslash?
	je	short @F		; Jump if so (d:\filename)

	mov	al,'\'                  ; Add trailing backslash
	stos	PGROUP:[di].LO		; ...to directory name

@@:
	lea	si,Exe_name2		; Original filename
	lods	PGROUP:[si].LO		; Get first character
	cmp	al,'\'                  ; Did it begin with \?
	je	short QPATH_NEXTCHAR	; Jump if so (skip it)

	cmp	al,'/'                  ; Did it begin with /?
	je	short QPATH_NEXTCHAR	; Jump if so (skip it)

	cmp	PGROUP:[si].LO,':'      ; Was original filespec 'd:.\fname' ?
	jne	short @F		; Jump if not

	inc	si			; DS:SI ==> character after :
QPATH_NEXTCHAR:
	lods	PGROUP:[si].LO		; Get next character
@@:
	stos	PGROUP:[di].LO		; Append to complete path
	or	al,al			; Izit the end?
	jnz	short QPATH_NEXTCHAR	; Jump if not

;;;;	clc				; Indicate success

QPATH_EXIT:
	pushf				; Save flags (CF significant)
	pop	[bp].QP_FLAGS		; Put on caller's stack

	mov	bx,[bp].QP_FH		; Get file handle
	cmp	bx,-1			; Izit valid?
	je	short @F		; Jump if so

	DOSCALL @CLOSF2 		; Close file (ignore return)
@@:
	add	sp,size QP_STR		; Deallocate local storage

	popf				; Restore flags with CF significant

	popad				; Restore GP regs

	ret				; Return to caller
	assume ds:nothing,es:nothing,ss:nothing

QualifyPath	endp			; End QualifyPath procedure

	 NPPROC GetComspec -- Get COMSPEC from environment & copy to EXE2_name
	 assume ds:PGROUP,es:PGROUP,ss:nothing
COMMENT |

Copy COMSPEC from environment to EXE2_name for indirect execution of
MAPSSF.

Input:	None
Output: CF=0	Success
	CF=1	Failure, DS:DX ==> error message

|

	REGSAVE <cx,si,di,ds>		; Save

	mov	ds,PSP_ENVIR_PTR	; Get environment pointer
	assume	ds:nothing		; Tell the assembler

	sub	si,si			; Start at beginning of environment
	lea	di,COMSPEC		; Get comparison string
	mov	cx,COMSPEC_LEN		; Get length to compare

GCS_GETVAR:
	lodsb				; Get next byte
	or	al,al			; Izit the end of the string?
	jz	short GCS_NEXTVAR	; Get next variable

	REGSAVE <cx,di> 		; Save length and pointer
	dec	si			; Back off to previous character
GCS_STRNICMP:
	lodsb				; Get character from environment
	cmp	al,1			; Izit 0 (end of string)?
	jb	short @F		; Get next variable (note ZF=0)

	call	ToUpper 		; Make AL uppercase
	scasb				; Compare and bump di
	loope	GCS_STRNICMP		; If they compare OK, keep going
@@:
	REGREST <di,cx> 		; Restore comparison length and pointer

	je	short GCS_STRCPY	; Found our boy... copy to destination

@@:
	or	al,al			; Izit 0?
	jz	short GCS_NEXTVAR	; If so, check for end of environment

	lodsb				; Get next character
	jmp	short @B		; Check for 0

GCS_NEXTVAR:
	cmp	ds:[si].LO,0		; Izit the end of the environment?
	jne	short GCS_GETVAR	; Not yet

	lea	dx,Comspec_not_found	; Error message "COMSPEC not found"
	jmp	short GCS_ERR		; End of environment and still no luck

GCS_STRCPY:
	lea	di,EXE2_name		; DS:DI ==> destination string
	mov	cx,@MAX_PATH		; Maximum path length is 128 + 1
@@:
	lodsb				; Get a byte
	stosb				; Store it
	or	al,al			; Wuzit the last byte?
	loopnz	@B			; Copy next

	jz	short GCS_EXIT		; Join common exit code (note CF=0)

	lea	dx,Comspec_too_long	; Error message "COMSPEC too long"

GCS_ERR:
	stc				; Indicate failure

GCS_EXIT:
	REGREST <ds,di,si,cx>		; Restore registers

	ret				; Return to caller
	assume	ds:nothing,es:nothing,ss:nothing

GetComspec	endp			; End GetComspec procedure

	 NPPROC Init -- Get command line parameters and set up EXEC blocks
	 assume ds:PGROUP,es:PGROUP,ss:nothing
COMMENT |

This is code that is used to prepare for execution, but need not be
kept after we have parsed the command line.

Input:	None.
Output: CF=0	Success
	CF=1	Failure; DS:DX ==> error message

|
.8086
	mov	 ax,seg BIOSDATA	; Prepare to address BIOS data area

	push	 ds			; Save DS
	mov	 ds,ax			; Use DS for BIOS data area
	assume	 ds:CGROUP		; Tell the assembler

	mov	 al,KB_FLAG		; Get keyboard flags
	pop	 ds			; Restore
	assume	 ds:PGROUP		; Tell the assembler

	test	 al,mask $KB_CAPL	; Is CAPS LOCK on?
	jz	 short @F		; No, so don't break

	int	 1			; Call SWAT
@@:
	MSGDISP Copyright		; Tell 'em we're here

	; Ensure we're running DOS 3.0 or higher
	DOSCALL @DOSVER 		; Get DOS version in AX
	xchg	 ah,al			; Put bytes in order
	mov	 DOSVER,ax		; Save for later use

	lea	 dx,MsgNotDOS3		; Display "Must be DOS 3 or higher"
	cmp	 ax,0300h		; Izit DOS 3.0?
	jb	 short INIT_EXIT	; Jump if not

	FCALL	 _SWAT_PRESENT		; Return VCPI debugger spec in AX (BCD) or 0 if not present
	lea	 dx,MsgNoDebugger	; Display "No VCPI debugger"
	cmp	 ax,0001h		; Izit debugger spec 0.01 or higher?
	jb	 short INIT_EXIT	; Jump if not

DOT386 p
	; Fix up segment references in EXE blocks
	mov	EXE_Block.cmdtail.VSEG,cs ; Set segment portion of far ptr
	mov	EXE2_Block.cmdtail.VSEG,cs ; Do it for EXE2_block
	mov	EXE_Block.FCB1.VSEG,cs	; Segment for FCB1 far ptr
	mov	EXE2_Block.FCB1.VSEG,cs ; Do the same for EXE2_block
	mov	EXE_Block.FCB2.VSEG,cs	; Segment for FCB2 far ptr
	mov	EXE2_Block.FCB2.VSEG,cs ; Do the same for EXE2_block

	call	ParseCmd		; parse command line
	jc	short INIT_EXIT 	; DS:DX ==> error message and CF=1

; If /b (Break) option was specified, call Swat now
	test	SRFlags,@SRF_BREAK	; Did we specify Break?
	jz	short @F		; No, so continue

	int	01h			; Call Swat
	Public	BREAKOPTION
BREAKOPTION:

@@:
	call	GetComspec		; Get COMSPEC from environment
	jc	short INIT_EXIT 	; We failed; DS:DX ==> error message

	clc				; Indicate success

.8086
INIT_EXIT:
	ret				; Return to caller
DOT386 p
	assume ds:nothing,es:nothing,ss:nothing

Init	endp

;;;;;;;  NPPROC  MAXPRES -- Determine Presence of 386MAX
;;;;;;;  assume  ds:PGROUP,es:nothing,ss:nothing
;;;;;;;COMMENT|
;;;;;;;
;;;;;;;Determine presence of 386MAX.
;;;;;;;
;;;;;;;On exit:
;;;;;;;
;;;;;;;CF	 =	 0 if present (with additional variables defined)
;;;;;;;  =	 1 if not
;;;;;;;
;;;;;;;|
;;;;;;;
;;;;;;;  REGSAVE <ax,bx,cx,dx>	; Save registers
;;;;;;;
;;;;;;;  mov	 al,@OPEN_R	; Function code for read-only access
;;;;;;;  DOSCALL @OPENF2,MAXNAME ; Attempt to open the device
;;;;;;;
;;;;;;;  jc	 short MAXPRES_ERR ; Jump if not
;;;;;;;
;;;;;;;  push	 ax		; Save handle
;;;;;;;
;;;;;;;  mov	 bx,ax		; Copy to handle register
;;;;;;;  mov	 al,0		; Function code to get device information
;;;;;;;  DOSCALL @IOCTL2	; Get device information into DX
;;;;;;;
;;;;;;;  pop	 bx		; Restore handle
;;;;;;;
;;;;;;;  pushf			; Save flags
;;;;;;;  DOSCALL @CLOSF2	; Close the file
;;;;;;;  popf			; Restore flags from get device info
;;;;;;;  jc	 short MAXPRES_ERR ; Jump if call failed
;;;;;;;
;;;;;;;  test	 dx,@IOCTL_DEV	; Izit a device?
;;;;;;;  jnz	 short MAXPRES_EXIT ; Jump if so (note CF=0)
;;;;;;;
;;;;;;;MAXPRES_ERR:
;;;;;;;  stc			; Indicate not present
;;;;;;;MAXPRES_EXIT:
;;;;;;;  REGREST <dx,cx,bx,ax>	; Restore
;;;;;;;
;;;;;;;  ret			; Return to caller
;;;;;;;
;;;;;;;  assume  ds:nothing,es:nothing,ss:nothing
;;;;;;;
;;;;;;;MAXPRES	endp			; End MAXPRES procedure
;;;;;;;

NCODE	ENDS

	END	START
