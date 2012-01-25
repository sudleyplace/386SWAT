;' $Header:   P:/PVCS/386SWAT/SWAT_DBG.ASV   1.20   10 Jul 1997 14:46:24   BOB  $
	 title	 SWAT_DBG -- 386SWAT Debug Register Functions
	 page	 58,122
	 name	 SWAT_DBG

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.


|
.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include OPCODES.INC
	 include ALLMEM.INC
	 include IOPBITS.INC
	 include MOVSPR.INC
	 include CPUFET.INC

	 include SWAT_COM.INC
	 include SWAT_CMD.INC
	 include SWAT_MOD.INC
	 include SWAT_SEG.INC
.list

DATA16	 segment use32 dword public 'data' ; Start DATA16 segment
	 assume  ds:DGROUP

	extrn	LCL_FLAG:dword
	include SWAT_LCL.INC

	extrn	LC2_FLAG:dword
	include SWAT_LC2.INC

	 extrn	 DBGATTR:byte

	 extrn	 CPUFET_FLAG:dword

DATA16	 ends			; End DATA16 segment


DATA	 segment use32 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 CUR_INSTR_ARW:word
	 extrn	 UNASEL:word
	 extrn	 UNABASE:dword
	 extrn	 UNAMODE:word

	 extrn	 MSGOFF:dword
	 extrn	 SYNTERR:byte
	 extrn	 BDREGERR:byte
	 extrn	 BCREGERR:byte
	 extrn	 ROMERR:byte

	 extrn	 SAVE_DR7:dword
	 extrn	 DSP_STATE:byte

	 extrn	 SELFDBG:dword

; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Code breakpoint data values
; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

BC_STR	 struc

BC_LIN	 dd	 ?		; Linear address
BC_OFF	 dd	 ?		; Code offset
BC_SEL	 dw	 ?		; ...  segment/selector
BC_FLAG  dw	 0		; Flags (see SWAT_CMD.INC)
BC_VAL	 db	 ?		; Original value
	 db	 3 dup (?)	; Filler

BC_STR	 ends

@NBC	 equ	 8		; # code breakpoints supported

	 public  BCDATA
BCDATA	 BC_STR  @NBC dup (<>)	; Breakpoint code data
BREAKPT  BC_STR  <>		; MUST follow BCDATA for single-skip BP

	 public  BREAKPT_PTR,BREAKPT_VAL,BREAKPT_FLAG
	public	BREAKPT_SEL,BREAKPT_OFF
BREAKPT_PTR equ  BREAKPT.BC_LIN
BREAKPT_VAL equ  BREAKPT.BC_VAL
BREAKPT_FLAG equ BREAKPT.BC_FLAG
BREAKPT_SEL equ  BREAKPT.BC_SEL
BREAKPT_OFF equ  BREAKPT.BC_OFF

	 public  W_BC
W_BC	 W_STR	 <>		; Temporary window structure

	 public  BC_WIN
BC_WIN	 db		   'ีออออออออออออออออออออออออออออออออออออออออออออออออออออธ'
NBCCOLS  equ	 $-BC_WIN	; # cols in BC window
BC_LN1	 db	 @NBC dup ('ณ ? BC? = ____?________ = ________ (__)              ณ')
	 db		   'รฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤด'
	 db		   'ณ BC   to display                                    ณ'
	 db		   'ณ BC*  to clear all         BC* addr to clear addr   ณ'
	 db		   'ณ BC+  to enable all        BC+ addr to enable addr  ณ'
	 db		   'ณ BC-  to disable all       BC- addr to disable addr ณ'
	 db		   'ิออออออออออออออออออออออออออออออออออออออออออออออออออออพ'
NBCROWS  equ	 ($-BC_WIN)/NBCCOLS ; # rows in BC window

BC_WIN_EN0 equ	 2		; Offset from BC_LN1 to enable/disable flag
BC_WIN_IN0 equ	 6		; ...			index
BC_WIN_SL0 equ	10		; ...			selector
BC_WIN_SP0 equ	14		; ...			separator
BC_WIN_OF0 equ	15		; ...			offset
BC_WIN_BC0 equ	26		; ...			register
BC_WIN_VL0 equ	36		; ...			value


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Debug register data values
; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

@BD_L1	 equ	 00b		; Length 1
@BD_L2	 equ	 01b		; Length 2
@BD_L4	 equ	 11b		; Length 4
@BD_X	 equ	 00b		; Instruction fetches
@BD_W	 equ	 01b		; Data writes
@BD_IO	 equ	 10b		; I/O reads/writes (P5 only)
@BD_RW	 equ	 11b		; Data reads/writes, not fetches


BD_STR	 struc			; Debug register structure

; The following values are dynamic

BD_REG	 dd	 ?		; 32-bit register value
BD_OFF	 dd	 0		; 32-bit linear offset
BD_BASE  dd	 0		; 32-bit linear base address
BD_SEL	 dw	 0		; Selector/segment
BD_FLAG  dw	 0		; Flags (see SWAT_CMD.INC)
BD_LEN	 db	 ?		; Length (00 = 1, 01 = 2, 10 = undef, 11 = 4)
BD_TYPE  db	 ?		; Type	 (00 = x, 01 = w, 10 = I/O rw, 11 = rw)

; The following values are static

BD_SET	 dd	 ?		; Action to set
BD_LSHF  db	 ?		; Length/type shift amount
BD_ESHF  db	 ?		; Enable      ...

BD_STR	 ends


	 public  BDCMD,BDREGS
BDCMD	 BD_STR  <>		; Command line values
BDREGS	 BD_STR  <?,0,0,0,0,?,?,offset PGROUP:CMD_BDSET0,$RW0,$L0> ; DR0
	 BD_STR  <?,0,0,0,0,?,?,offset PGROUP:CMD_BDSET1,$RW1,$L1> ; DR1
	 BD_STR  <?,0,0,0,0,?,?,offset PGROUP:CMD_BDSET2,$RW2,$L2> ; DR2
	 BD_STR  <?,0,0,0,0,?,?,offset PGROUP:CMD_BDSET3,$RW3,$L3> ; DR3

	 public  W_BD
W_BD	 W_STR	 <>		; Temporary window structure

	 public  BDTYPES,BDLENS
BDTYPES  db	 'X W IORW'
BDLENS	 db	 '12?4'

	 public  DBG_WIN
DBG_WIN  db	 'ีอออออออออออออออออออออออออออออออออออออออออออออออออธ'
NDBGCOLS equ	 $-DBG_WIN	; # cols in debug window
DBG_LN1  db	 'ณ ? DR0 = ____?________ = ________   L1   X       ณ'
	 db	 'ณ ? DR1 = ____?________ = ________   L1   X       ณ'
	 db	 'ณ ? DR2 = ____?________ = ________   L1   X       ณ'
	 db	 'ณ ? DR3 = ____?________ = ________   L1   X       ณ'
DBG_DR6  db	 'ณ DR6 = ________                                  ณ'
DBG_DR7  db	 'ณ DR7 = ________                                  ณ'
;;;;;;;; db	 'ณ DR7 = ________ GD GE LE G3 L3 G2 L2 G1 L1 G0 L0 ณ'
	 db	 'รฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤด'
	 db	 'ณ BD   to display                                 ณ'
	 db	 'ณ BD*  to clear all         BDn*  to clear DRn    ณ'
	 db	 'ณ BD+  to enable all        BDn+  to enable DRn   ณ'
	 db	 'ณ BD-  to disable all       BDn-  to disable DRn  ณ'
	 db	 'ิอออออออออออออออออออออออออออออออออออออออออออออออออพ'
NDBGROWS equ	 ($-DBG_WIN)/NDBGCOLS ; # rows in debug window

DBG_WIN_EN0 equ   2		; Offset from DBG_LN1 to enable/disable flag
DBG_WIN_SL0 equ  10		; ...			 selector
DBG_WIN_SP0 equ  14		; ...			 separator
DBG_WIN_OF0 equ  15		; ...			 offset
DBG_WIN_DR0 equ  26		; ...			 register
DBG_WIN_LN0 equ  38		; ...			 length
DBG_WIN_TP0 equ  42		; ...			 type

DBG_DR6_REG equ  08		; ...	      DBG_DR6 to DR6
DBG_DR6_BT  equ  20		; ...			 BT flag
DBG_DR6_BS  equ  23		; ...			 BS
DBG_DR6_BD  equ  26		; ...			 BD

DBG_DR6_B3  equ  29		; ...			 B3
DBG_DR6_B2  equ  32		; ...			 B2
DBG_DR6_B1  equ  35		; ...			 B1
DBG_DR6_B0  equ  38		; ...			 B0

DBG_DR7_REG equ  08		; ...	      DBG_DR7 to DR7
DBG_DR7_GD  equ  17		; ...			 GD flag
DBG_DR7_GE  equ  20		; ...			 GE
DBG_DR7_LE  equ  23		; ...			 LE
DBG_DR7_G3  equ  26		; ...			 G3
DBG_DR7_L3  equ  29		; ...			 L3
DBG_DR7_G2  equ  32		; ...			 G2
DBG_DR7_L2  equ  35		; ...			 L2
DBG_DR7_G1  equ  38		; ...			 G1
DBG_DR7_L1  equ  41		; ...			 L1
DBG_DR7_G0  equ  44		; ...			 G0
DBG_DR7_L0  equ  47		; ...			 L0

@ANYGL	 equ	 (mask $G0) or (mask $L0) or (mask $G1) or (mask $L1) or (mask $G2) or (mask $L2) or (mask $G3) or (mask $L3)

	 public  CHECK_DBG_RES
CHECK_DBG_RES db 0		; Result of last call to CHECK_DBG

	 public  BREAKLIST_CNT,BREAKLIST
	 align	 4
BREAKLIST_CNT dd 0		; Entries in breakpoint list
BREAKLIST dd	 4+@NBC dup (?) ; List to search for active breakpoints

DATA	 ends			; End DATA segment


PROG	 segment use32 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 extrn	 CMD_WHITE:near
	 extrn	 WPUT_CSA:near
	 extrn	 BIN2DIGIT:near
	 extrn	 BIN2BYTE:near
	 extrn	 BIN2WORD:near
	 extrn	 BIN2DWORD:near
	 extrn	 U32_LOWERCASE:near
	 extrn	 PARSE_ADDR:near
	 extrn	 SET_STATE:near

	 extrn	 INST_OPR0E:near
	 extrn	 REST_OPR0E:near

	extrn	GETBASE:near

	 NPPROC  CMD_BCCLR -- Breakpoint Code Clear Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Breakpoint code clear command

BC*		 Clear all code breakpoints
BC* addr	 Clear ones which match this address

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save registers

	 inc	 esi		; Skip over the '*'

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 short CMD_BCCLR_ALL ; Yes, treat as clear all

	 call	 PARSE_ADDR	; Parse DS:ESI for address
	 jc	 near ptr CMD_BCCLR_SYNTERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

; Ensure there's nothing else on the line

	 cmp	 ds:[esi].LO,0	; Izit end-of-the-line?
	 jne	 near ptr CMD_BCCLR_SYNTERR ; Jump if not

; See if this duplicates an existing value in BCDATA

; Fill in segment/selector/mode if no separator specified

	 test	 cx,@ADDR_SEP	; Izit specified?
	 jnz	 short CMD_BCCLR1 ; Yes, BX is valid

	 mov	 bx,UNASEL	; Get segment/selector of current instr
	 mov	 edx,UNABASE	; Get base of the current instr

	 test	 UNAMODE,@MODE_VM ; Izit VM86 mode?
	 jnz	 short CMD_BCCLR1 ; Jump if so

	 or	 cx,@ADDR_PM	; Mark as PM
CMD_BCCLR1:

; Loop through the BCDATA structure looking for a match

	 mov	 si,cx		; Copy flags
	 mov	 ecx,@NBC	; Get # code breakpoints
	 xor	 edi,edi	; Initialize index into BCDATA
CMD_BCCLR_NEXT:
	 test	 BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	 jz	 short CMD_BCCLR_LOOP ; Jump if not

	 cmp	 bx,BCDATA[edi].BC_SEL ; Same segment/selector?
	 jne	 short CMD_BCCLR_LOOP ; Jump if not

	 cmp	 eax,BCDATA[edi].BC_OFF ; Same offset?
	 jne	 short CMD_BCCLR_LOOP ; Jump if not

	 mov	 dx,si		; Copy flags
	 xor	 dx,BCDATA[edi].BC_FLAG ; Check for same mode

	 test	 dx,@ADDR_PM	; Izit the same mode?
	 jnz	 short CMD_BCCLR_LOOP ; Jump if not

	 and	 BCDATA[edi].BC_FLAG,not @ADDR_INUSE ; Mark as no longer in use
CMD_BCCLR_LOOP:
	 add	 edi,size BC_STR ; Skip to next entry

	 loop	 CMD_BCCLR_NEXT ; Jump if more entries

	 jmp	 short CMD_BCCLR_CLC ; Join common OK code


; Clear all code breakpoints

CMD_BCCLR_ALL:
	 mov	 ecx,@NBC	; Get # code breakpoints
	 xor	 edi,edi	; Initialize index into BCDATA
CMD_BCCLR_NEXT2:

; Mark as disabled and no longer in use

	 and	 BCDATA[edi].BC_FLAG,not (@ADDR_INUSE or @ADDR_ENA)
	 add	 edi,size BC_STR ; Skip to next entry

	 loop	 CMD_BCCLR_NEXT2 ; Jump if more entries
CMD_BCCLR_CLC:
	 cmp	 DSP_STATE,@DSP_BC ; Displaying BC values?
	 jne	 short @F	; No

	 call	 DISP_BC	; Display 'em
@@:
	 call	 UD_BREAKLIST	; Update breakpoint list for display
	 clc			; Incidate all went well

	 jmp	 short CMD_BCCLR_EXIT ; Join common exit code

CMD_BCCLR_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Indicate something went wrong
CMD_BCCLR_EXIT:
	 REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BCCLR endp			; End CMD_BCCLR procedure
	 NPPROC  CMD_BCENA -- Breakpoint Code Enable Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Breakpoint code enable command

BC+		 Enable all code breakpoints
BC+ addr	 Enable ones which match this address

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save registers

	 inc	 esi		; Skip over the '+'

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 short CMD_BCENA_ALL ; Yes, treat as clear all

	 call	 PARSE_ADDR	; Parse DS:ESI for address
	 jc	 near ptr CMD_BCENA_SYNTERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

; Ensure there's nothing else on the line

	 cmp	 ds:[esi].LO,0	; Izit end-of-the-line?
	 jne	 near ptr CMD_BCENA_SYNTERR ; Jump if not

; See if this duplicates an existing value in BCDATA

; Fill in segment/selector/mode if no separator specified

	 test	 cx,@ADDR_SEP	; Izit specified?
	 jnz	 short CMD_BCENA1 ; Yes, BX is valid

	 mov	 bx,UNASEL	; Get segment/selector of current instr
	 mov	 edx,UNABASE	; Get base of the current instr

	 test	 UNAMODE,@MODE_VM ; Izit VM86 mode?
	 jnz	 short CMD_BCENA1 ; Jump if so

	 or	 cx,@ADDR_PM	; Mark as PM
CMD_BCENA1:

; Loop through the BCDATA structure looking for a match

	 mov	 si,cx		; Copy flags
	 mov	 ecx,@NBC	; Get # code breakpoints
	 xor	 edi,edi	; Initialize index into BCDATA
CMD_BCENA_NEXT:
	 test	 BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	 jz	 short CMD_BCENA_LOOP ; Jump if not

	 cmp	 bx,BCDATA[edi].BC_SEL ; Same segment/selector?
	 jne	 short CMD_BCENA_LOOP ; Jump if not

	 cmp	 eax,BCDATA[edi].BC_OFF ; Same offset?
	 jne	 short CMD_BCENA_LOOP ; Jump if not

	 mov	 dx,si		; Copy flags
	 xor	 dx,BCDATA[edi].BC_FLAG ; Check for same mode

	 test	 dx,@ADDR_PM	; Izit the same mode?
	 jnz	 short CMD_BCENA_LOOP ; Jump if not

	 or	 BCDATA[edi].BC_FLAG,@ADDR_ENA ; Mark as enabled
CMD_BCENA_LOOP:
	 add	 edi,size BC_STR ; Skip to next entry

	 loop	 CMD_BCENA_NEXT ; Jump if more entries

	 jmp	 short CMD_BCENA_CLC ; Join common OK code


; Enable all code breakpoints

CMD_BCENA_ALL:
	 mov	 ecx,@NBC	; Get # code breakpoints
	 xor	 edi,edi	; Initialize index into BCDATA
CMD_BCENA_NEXT2:
	 test	 BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	 jz	 short @F	; Jump if not

	 or	 BCDATA[edi].BC_FLAG,@ADDR_ENA ; Mark as enabled
@@:
	 add	 edi,size BC_STR ; Skip to next entry

	 loop	 CMD_BCENA_NEXT2 ; Jump if more entries
CMD_BCENA_CLC:
	 cmp	 DSP_STATE,@DSP_BC ; Displaying BC values?
	 jne	 short @F	; No

	 call	 DISP_BC	; Display 'em
@@:
	 call	 UD_BREAKLIST	; Update breakpoint list for display
	 clc			; Incidate all went well

	 jmp	 short CMD_BCENA_EXIT ; Join common exit code

CMD_BCENA_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Indicate something went wrong
CMD_BCENA_EXIT:
	 REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BCENA endp			; End CMD_BCENA procedure
	 NPPROC  CMD_BCDIS -- Breakpoint Code Disable Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Breakpoint code disable command

BC-		 Disable all code breakpoints
BC- addr	 Disable ones which match this address

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save registers

	 inc	 esi		; Skip over the '-'

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 short CMD_BCDIS_ALL ; Yes, treat as clear all

	 call	 PARSE_ADDR	; Parse DS:ESI for address
	 jc	 near ptr CMD_BCDIS_SYNTERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

; Ensure there's nothing else on the line

	 cmp	 ds:[esi].LO,0	 ; Izit end-of-the-line?
	 jne	 near ptr CMD_BCDIS_SYNTERR ; Jump if not

; See if this duplicates an existing value in BCDATA

; Fill in segment/selector/mode if no separator specified

	 test	 cx,@ADDR_SEP	; Izit specified?
	 jnz	 short CMD_BCDIS1 ; Yes, BX is valid

	 mov	 bx,UNASEL	; Get segment/selector of current instr
	 mov	 edx,UNABASE	; Get base of the current instr

	 test	 UNAMODE,@MODE_VM ; Izit VM86 mode?
	 jnz	 short CMD_BCDIS1 ; Jump if so

	 or	 cx,@ADDR_PM	; Mark as PM
CMD_BCDIS1:

; Loop through the BCDATA structure looking for a match

	 mov	 si,cx		; Copy flags
	 mov	 ecx,@NBC	; Get # code breakpoints
	 xor	 edi,edi	; Initialize index into BCDATA
CMD_BCDIS_NEXT:
	 test	 BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	 jz	 short CMD_BCDIS_LOOP ; Jump if not

	 cmp	 bx,BCDATA[edi].BC_SEL ; Same segment/selector?
	 jne	 short CMD_BCDIS_LOOP ; Jump if not

	 cmp	 eax,BCDATA[edi].BC_OFF ; Same offset?
	 jne	 short CMD_BCDIS_LOOP ; Jump if not

	 mov	 dx,si		; Copy flags
	 xor	 dx,BCDATA[edi].BC_FLAG ; Check for same mode

	 test	 dx,@ADDR_PM	; Izit the same mode?
	 jnz	 short CMD_BCDIS_LOOP ; Jump if not

	 and	 BCDATA[edi].BC_FLAG,not @ADDR_ENA ; Mark as disabled
CMD_BCDIS_LOOP:
	 add	 edi,size BC_STR ; Skip to next entry

	 loop	 CMD_BCDIS_NEXT ; Jump if more entries

	 jmp	 short CMD_BCDIS_CLC ; Join common OK code


; Disable all code breakpoints

CMD_BCDIS_ALL:
	 mov	 ecx,@NBC	; Get # code breakpoints
	 xor	 edi,edi	; Initialize index into BCDATA
CMD_BCDIS_NEXT2:
	 test	 BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	 jz	 short @F	; Jump if not

	 and	 BCDATA[edi].BC_FLAG,not @ADDR_ENA ; Mark as disabled
@@:
	 add	 edi,size BC_STR ; Skip to next entry

	 loop	 CMD_BCDIS_NEXT2 ; Jump if more entries
CMD_BCDIS_CLC:
	 cmp	 DSP_STATE,@DSP_BC ; Displaying BC values?
	 jne	 short @F	; No

	 call	 DISP_BC	; Display 'em
@@:
	 call	 UD_BREAKLIST	; Update breakpoint list for display
	 clc			; Incidate all went well

	 jmp	 short CMD_BCDIS_EXIT ; Join common exit code

CMD_BCDIS_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Indicate something went wrong
CMD_BCDIS_EXIT:
	 REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BCDIS endp			; End CMD_BCDIS procedure
	 NPPROC  CMD_BCSET -- Breakpoint Code Set Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Breakpoint code set command

BC* opt_addr
BC+ opt_addr
BC- opt_addr

BC		 Display all code breakpoints
BC addr 	 Set one at this address

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

; Split off cases for clear, enable, and disable

	 cmp	 DGROUP:[esi].LO,'*' ; Izit clear?
	 je	 near ptr CMD_BCCLR ; Jump if so

	 cmp	 DGROUP:[esi].LO,'+' ; Izit enable?
	 je	 near ptr CMD_BCENA ; Jump if so

	 cmp	 DGROUP:[esi].LO,'-' ; Izit disable?
	 je	 near ptr CMD_BCDIS ; Jump if so

	 REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save registers

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 near ptr CMD_BCSET_DISP ; Yes, treat as display all

	 call	 PARSE_ADDR	; Parse DS:ESI for address
	 jc	 near ptr CMD_BCSET_SYNTERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

; Ensure there's nothing else on the line

	 cmp	 ds:[esi].LO,0	; Izit end-of-the-line?
	 jne	 near ptr CMD_BCSET_SYNTERR ; Jump if not

; See if this duplicates an existing value in BCDATA

; Fill in segment/selector/mode if no separator specified

	 test	 cx,@ADDR_SEP	; Izit specified?
	 jnz	 short CMD_BCSET1 ; Yes, BX is valid

	 mov	 bx,UNASEL	; Get segment/selector of current instr
	 mov	 edx,UNABASE	; Get base of the current instr

	 test	 UNAMODE,@MODE_VM ; Izit VM86 mode?
	 jnz	 short CMD_BCSET1 ; Jump if so

	 or	 cx,@ADDR_PM	; Mark as PM
CMD_BCSET1:

; Loop through the BCDATA structure looking for a match

	 mov	 si,cx		; Copy flags
	 mov	 ecx,@NBC	; Get # code breakpoints
	 xor	 edi,edi	; Initialize index into BCDATA
CMD_BCSET_NEXT:
	 test	 BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	 jz	 short CMD_BCSET_LOOP ; Jump if not

	 cmp	 bx,BCDATA[edi].BC_SEL ; Same segment/selector?
	 jne	 short CMD_BCSET_LOOP ; Jump if not

	 cmp	 eax,BCDATA[edi].BC_OFF ; Same offset?
	 jne	 short CMD_BCSET_LOOP ; Jump if not

	 xor	 si,BCDATA[edi].BC_FLAG ; Check for same mode

	 test	 si,@ADDR_PM	; Izit the same mode?
	 jnz	 short CMD_BCSET_LOOP0 ; Jump if not

; Enable it, save new original value, exit

	 xor	 si,BCDATA[edi].BC_FLAG ; Restore original flags
	 or	 si,@ADDR_ENA	; Mark as enabled
	 mov	 BCDATA[edi].BC_FLAG,si ; Mark as enabled, etc.

	 add	 eax,edx	; Add offset and base to get linear address
	 mov	 BCDATA[edi].BC_LIN,eax ; Save as new linear address

	 mov	 al,AGROUP:[eax] ; Get new original value
	 mov	 BCDATA[edi].BC_VAL,al ; Save as new original value

	 jmp	 short CMD_BCSET_CLC ; Join common OK code

CMD_BCSET_LOOP0:
	 xor	 si,BCDATA[edi].BC_FLAG ; Restore original flags
CMD_BCSET_LOOP:
	 add	 edi,size BC_STR ; Skip to next entry

	 loop	 CMD_BCSET_NEXT ; Jump if more entries

; No match found, insert a new one

; Look for a free entry

	 mov	 ecx,@NBC	; Get # code breakpoints
	 xor	 edi,edi	; Initialize index into BCDATA
CMD_BCSET_NEXT2:
	 test	 BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	 jnz	 short CMD_BCSET_LOOP2 ; Jump if so

; Test the linear address to verify that it is not ROM

	 REGSAVE <eax,edx>	; Save registers

	 add	 eax,edx	; Add offset and base to get linear address
	 mov	 dl,@OPCOD_INT3 ; Get opcode of breakpoint interrupt instruction

	 xchg	 AGROUP:[eax],dl ; Swap bytes to set breakpoint
	 cmp	 AGROUP:[eax].LO,@OPCOD_INT3 ; Did the write to memory stick?
				; ZF is significant

	 xchg	 AGROUP:[eax],dl ; Swap 'em back

	 REGREST <edx,eax>	; Restore registers
	 jne	 short CMD_BCSET_ROMERR ; Jump if breakpoint won't stick

; Mark as in use, enabled, save new original value, and exit

	 or	 si,@ADDR_INUSE or @ADDR_ENA ; Mark it
	 mov	 BCDATA[edi].BC_FLAG,si ; Save flags

	 mov	 BCDATA[edi].BC_OFF,eax ; Save offset
	 mov	 BCDATA[edi].BC_SEL,bx ; ... segment/selector

	 add	 eax,edx	; Add offset and base to get linear address
	 mov	 BCDATA[edi].BC_LIN,eax ; Save as new linear address

	 mov	 al,AGROUP:[eax] ; Get new original value
	 mov	 BCDATA[edi].BC_VAL,al ; Save as new original value

	 jmp	 short CMD_BCSET_CLC ; Join common OK code

CMD_BCSET_LOOP2:
	 add	 edi,size BC_STR ; Skip to next entry

	 loop	 CMD_BCSET_NEXT2 ; Jump if more entries

; No free entries found

	 mov	 MSGOFF,offset DGROUP:BCREGERR ; Save offset of error message

	 jmp	 short CMD_BCSET_ERR ; Join common error code

; The breakpoint is into ROM

CMD_BCSET_ROMERR:
	 mov	 MSGOFF,offset DGROUP:ROMERR ; Save offset of error message

	 jmp	 short CMD_BCSET_ERR ; Join common error exit code

; Display all code breakpoints

CMD_BCSET_CLC:
	 cmp	 DSP_STATE,@DSP_BC ; Displaying BC values?
	 jne	 short @F	; No
CMD_BCSET_DISP:
	 call	 DISP_BC	; Display 'em
@@:
	 call	 UD_BREAKLIST	; Update breakpoint list for display
	 clc			; Incidate all went well

	 jmp	 short CMD_BCSET_EXIT ; Join common exit code

CMD_BCSET_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
CMD_BCSET_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Indicate something went wrong
CMD_BCSET_EXIT:
	 REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BCSET endp			; End CMD_BCSET procedure
	 NPPROC  INST_BCVAL -- Install Code Breakpoint Values
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Install code breakpoint values

|

	 REGSAVE <eax,ebx,ecx,edi> ; Save registers

	 call	 INST_OPR0E	; Install our local Page Fault handler

; Loop through BCDATA and swap original values with an INT 03h

	 mov	 ecx,@NBC	; Get # code breakpoints
	 xor	 edi,edi	; Initialize index into BCDATA
INST_BCVAL_NEXT:
	 test	 BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	 jz	 short INST_BCVAL_LOOP ; Jump if not

	 test	 BCDATA[edi].BC_FLAG,@ADDR_ENA ; Izit enabled?
	 jz	 short INST_BCVAL_LOOP ; Jump if not

	 mov	 ebx,BCDATA[edi].BC_LIN ; Get linear address
	 mov	 al,@OPCOD_INT3 ; Get opcode of breakpoint interrupt instruction

; The next instruction might generate a Page Fault if the linear address
; of the original instruction is no longer valid, but it'll be skipped
; by the above-installed Page Fault handler.

	 clc			; Assume no Page Fault
	 xchg	 al,AGROUP:[ebx] ; Swap with original value
	 jc	 short INST_BCVAL_ERR ; Jump if Page Fault

	 mov	 BCDATA[edi].BC_VAL,al ; Save as new original value

	 jmp	 short INST_BCVAL_LOOP ; Join common loop code

INST_BCVAL_ERR:
	 and	 BCDATA[edi].BC_FLAG,not @ADDR_ENA ; Mark as disabled
INST_BCVAL_LOOP:
	 add	 edi,size BC_STR ; Skip to next entry

	 loop	 INST_BCVAL_NEXT ; Jump if more entries

	 call	 REST_OPR0E	; Restore previous Page Fault handler

	 REGREST <edi,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST_BCVAL endp 		; End INST_BCVAL procedure
	 NPPROC  CHECK_BCVAL -- Check On Code Breakpoint Values
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

See if the current instruction matches an enabled breakpoint value.

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 1 if there's a match
	 =	 0 otherwise

|

	 REGSAVE <eax,ebx,ecx,edx,edi> ; Save registers

; Loop through BCDATA and check the values

	 mov	 ecx,@NBC	; Get # code breakpoints
	 xor	 edi,edi	; Initialize index into BCDATA
	 mov	 bx,[ebp].FORW_CS ; Get segment/selector of current instr
	 mov	 eax,[ebp].FORW_EIP ; Get offset of ...
	 xor	 dx,dx		; Clear the flags

	 test	 [ebp].FORW_EFL.EHI,mask $VM ; Izit VM 8086 mode?
	 jnz	 short @F	; Jump if so

	 or	 dx,@ADDR_PM	; Mark as PM

	 test	 CUR_INSTR_ARW.HI,mask $DTE_B ; Check for D-bit
	 jnz	 short CHECK_BCVAL_NEXT ; Jump if USE32
@@:
	 movzx	 eax,ax 	; Zero high-order word
CHECK_BCVAL_NEXT:
	 test	 BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	 jz	 short CHECK_BCVAL_LOOP ; Jump if not

	 test	 BCDATA[edi].BC_FLAG,@ADDR_ENA ; Izit enabled?
	 jz	 short CHECK_BCVAL_LOOP ; Jump if not

	 cmp	 bx,BCDATA[edi].BC_SEL ; Same segment/selector?
	 jne	 short CHECK_BCVAL_LOOP ; Jump if not

	 cmp	 eax,BCDATA[edi].BC_OFF ; Same offset?
	 jne	 short CHECK_BCVAL_LOOP ; Jump if not

	 xor	 dx,BCDATA[edi].BC_FLAG ; Check for same mode

	 test	 dx,@ADDR_PM	; Izit the same mode?
	 jnz	 short @F	; Jump if not

	 stc			; Indicate there's a match

	 jmp	 short CHECK_BCVAL_EXIT ; Join common exit code

@@:
	 xor	 dx,BCDATA[edi].BC_FLAG ; Restore original flags
CHECK_BCVAL_LOOP:
	 add	 edi,size BC_STR ; Skip to next entry

	 loop	 CHECK_BCVAL_NEXT ; Jump if more entries

	 clc			; Indicate there's no match
CHECK_BCVAL_EXIT:
	 REGREST <edi,edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_BCVAL endp		; End CHECK_BCVAL procedure
	 NPPROC  REST_BCVAL -- Restore Original Code Breakpoint Values
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Restore original code breakpoint values

|

	 REGSAVE <eax,ebx,ecx,edi> ; Save registers

	 call	 INST_OPR0E	; Install our local Page Fault handler

; Loop through BCDATA and restore original values

	 mov	 ecx,@NBC+1	; Get # code breakpoints (plus single-skip BP)
	 xor	 edi,edi	; Initialize index into BCDATA
REST_BCVAL_NEXT:
	 test	 BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	 jz	 short REST_BCVAL_LOOP ; Jump if not

	 test	 BCDATA[edi].BC_FLAG,@ADDR_ENA ; Izit enabled?
	 jz	 short REST_BCVAL_LOOP ; Jump if not

	 mov	 ebx,BCDATA[edi].BC_LIN ; Get linear address

; The next instruction might generate a Page Fault if the linear address
; of the original instruction is no longer valid, but it'll be skipped
; by the above-installed Page Fault handler.

	 clc			; Assume no Page Fault
	 mov	 al,AGROUP:[ebx] ; Get the value
	 jc	 short REST_BCVAL_ERR ; Jump if Page Fault

	 cmp	 al,@OPCOD_INT3  ; Izit an INT 03h?
	 jne	 short REST_BCVAL_LOOP ; Jump if not

	 mov	 al,BCDATA[edi].BC_VAL ; Get original value
	 mov	 AGROUP:[ebx],al ; Restore it

	 jmp	 short REST_BCVAL_LOOP ; Join common loop code

REST_BCVAL_ERR:
	 and	 BCDATA[edi].BC_FLAG,not @ADDR_ENA ; Mark as disabled
REST_BCVAL_LOOP:
	 add	 edi,size BC_STR ; Skip to next entry

	 loop	 REST_BCVAL_NEXT ; Jump if more entries

	 and	 BREAKPT_FLAG,not @ADDR_INUSE ; Mark as no longer in use

	 call	 REST_OPR0E	; Restore previous Page Fault handler

	 REGREST <edi,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_BCVAL endp 		; End REST_BCVAL procedure
	NPPROC	REFRESH_DEBUG -- Refresh Debug Hook Values
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Refresh debug hook values

One entry:

SS:EBP	==>	FORW_STR

|

	REGSAVE <eax,ebx,ecx,edi> ; Save registers

	call	INST_OPR0E	; Install our local Page Fault handler

; Loop through BCDATA and refresh values

	mov	ecx,@NBC+1	; Get # code breakpoints (plus single-skip BP)
	xor	edi,edi 	; Initialize index into BCDATA
REFR_DEBUG_NEXT1:
	test	BCDATA[edi].BC_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short REFR_DEBUG_LOOP1 ; Jump if not

; Because the linear address might have changed, we recalculate it
; from the segment/selector values

	movzx	eax,BCDATA[edi].BC_SEL ; Get the segment/selector
	shl	eax,4-0 	; Convert from paras to bytes

	test	BCDATA[edi].BC_FLAG,@ADDR_PM ; Izit in PM?
	jz	short @F	; Jump if not

	push	BCDATA[edi].BC_SEL ; Pass the selector
	call	GETBASE 	; Return with EAX = selector base
@@:
	mov	ebx,BCDATA[edi].BC_OFF ; Get the offset
	add	ebx,eax 	; Add to get linear address

	cmp	ebx,BCDATA[edi].BC_LIN ; Izit the same?
	je	short @F	; Jump if so

	mov	BCDATA[edi].BC_LIN,ebx ; Save as new linear address
@@:
	test	BCDATA[edi].BC_FLAG,@ADDR_ENA ; Izit enabled?
	jz	short REFR_DEBUG_LOOP1 ; Jump if not

; The next instruction might generate a Page Fault if the linear address
; of the original instruction is no longer valid, but it'll be skipped
; by the above-installed Page Fault handler.

	clc			; Assume no Page Fault
	mov	al,AGROUP:[ebx] ; Get the value
	jc	short REFR_DEBUG_ERR ; Jump if Page Fault

	cmp	al,@OPCOD_INT3	; Izit an INT 03h?
	je	short REFR_DEBUG_LOOP1 ; Jump if so

	cmp	al,BCDATA[edi].BC_VAL ; Izit the original value?
	jne	short REFR_DEBUG_ERR ; Jump if not

	mov	AGROUP:[ebx].LO,@OPCOD_INT3 ; Restore the BC

	jmp	short REFR_DEBUG_LOOP1 ; Join common loop code

REFR_DEBUG_ERR:
	and	BCDATA[edi].BC_FLAG,not @ADDR_ENA ; Mark as disabled
REFR_DEBUG_LOOP1:
	add	edi,size BC_STR ; Skip to next entry

	loop	REFR_DEBUG_NEXT1 ; Jump if more entries

; Loop through BD registers and refresh

	xor	edi,edi 	; Initialize index into BDREGS
	mov	ecx,4		; Get # debug registers
REFR_DEBUG_NEXT2:
	test	BDREGS[edi].BD_FLAG,@ADDR_INUSE ; Izit in use?
	jz	short REFR_DEBUG_LOOP2 ; Jump if not

	movzx	eax,BDREGS[edi].BD_SEL ; Get the segment/selector
	shl	eax,4-0 	; Convert from paras to bytes

	test	BDREGS[edi].BD_FLAG,@ADDR_PM ; Izit in PM?
	jz	short @F	; Jump if not

	push	BDREGS[edi].BD_SEL ; Pass the selector
	call	GETBASE 	; Return with EAX = selector base
@@:
	mov	BDREGS[edi].BD_BASE,eax ; Save as base address
	add	eax,BDREGS[edi].BD_OFF ; Plus the offset
	mov	BDREGS[edi].BD_REG,eax ; Save as register value

	call	BDREGS[edi].BD_SET ; Set the new value into place
REFR_DEBUG_LOOP2:
	add	edi,type BD_STR ; Skip to next entry

	loop	REFR_DEBUG_NEXT2 ; Jump if more registers to refresh

	call	REST_OPR0E	; Restore previous Page Fault handler

	REGREST <edi,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REFRESH_DEBUG endp		; End REFRESH_DEBUG procedure
	 NPPROC  CMD_BDCLR0123 -- Debug Register Clear DR0-DR3 Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debug Register clear DR0-DR3 commands

BD0*
BD1*
BD2*
BD3*

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 public  CMD_BDCLR0
CMD_BDCLR0:
	 REGSAVE <ebx,edi>	; Save registers

	 mov	 ebx,not ((mask $L0) or (mask $G0)) ; Get the mask for DR0
	 mov	 edi,0*(size BD_STR) ; EDI = offset into BDREGS

	 jmp	 short CMD_BDCLRCOM ; Join common code

	 public  CMD_BDCLR1
CMD_BDCLR1:
	 REGSAVE <ebx,edi>	; Save registers

	 mov	 ebx,not ((mask $L1) or (mask $G1)) ; Get the mask for DR1
	 mov	 edi,1*(size BD_STR) ; EDI = offset into BDREGS

	 jmp	 short CMD_BDCLRCOM ; Join common code

	 public  CMD_BDCLR2
CMD_BDCLR2:
	 REGSAVE <ebx,edi>	; Save registers

	 mov	 ebx,not ((mask $L2) or (mask $G2)) ; Get the mask for DR2
	 mov	 edi,2*(size BD_STR) ; EDI = offset into BDREGS

	 jmp	 short CMD_BDCLRCOM ; Join common code

	 public  CMD_BDCLR3
CMD_BDCLR3:
	 REGSAVE <ebx,edi>	; Save registers

	 mov	 ebx,not ((mask $L3) or (mask $G3)) ; Get the mask for DR3
	 mov	 edi,3*(size BD_STR) ; EDI = offset into BDREGS

;;;;;;;; jmp	 short CMD_BDCLRCOM ; Join common code

CMD_BDCLRCOM:
	 REGSAVE <eax>		; Save register

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 jne	 short CMD_BDCLR0123_SYNTERR ; No, so that's an error

	 and	 ebx,SAVE_DR7	; Get debug control register, clear bits

	 test	 ebx,@ANYGL	; Any global or local DRn enables set?
	 jnz	 short @F	; Yes, continue with global/local enable

	 and	 ebx,not (mask $GE) ; Clear global enable
@@:
	 mov	 SAVE_DR7,ebx	; Reset debug control register

; Mark as disabled and available

	 and	 BDREGS.BD_FLAG[edi],not (@ADDR_ENA or @ADDR_INUSE)

	 cmp	 DSP_STATE,@DSP_DRn ; Displaying debug registers?
	 jne	 short @F	; No

	 call	 DISP_DRn	; Display 'em
@@:
	 call	 UD_BREAKLIST	; Update breakpoint list for display
	 clc			; Indicate all went well

	 jmp	 short CMD_BDCLR0123_EXIT ; Join common exit code

CMD_BDCLR0123_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
CMD_BDCLR0123_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Indicate something went wrong
CMD_BDCLR0123_EXIT:
	 REGREST <eax>		; Restore
	 REGREST <edi,ebx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BDCLR0123 endp		; End CMD_BDCLR0123 procedure
	 NPPROC  CMD_BDCLR -- Debug Register Clear All Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debug Register clear all command

BD*

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax>		; Save register

	 inc	 esi		; Skip over the '*'

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 jne	 short CMD_BDCLR_SYNTERR ; No, so that's an error

	 call	 CMD_BDCLR0	; Clear DR0
	 call	 CMD_BDCLR1	; Clear DR1
	 call	 CMD_BDCLR2	; Clear DR2
	 call	 CMD_BDCLR3	; Clear DR3

	 call	 UD_BREAKLIST	; Update breakpoint list for display
	 clc			; Indicate all went well

	 jmp	 short CMD_BDCLR_EXIT ; Join common exit code

CMD_BDCLR_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
CMD_BDCLR_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Indicate something went wrong
CMD_BDCLR_EXIT:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BDCLR endp			; End CMD_BDCLR procedure
	 NPPROC  CMD_BDDIS0123 -- Debug Register Disable DR0-DR3 Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debug Register disable DR0-DR3 commands

BD0-
BD1-
BD2-
BD3-

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 public  CMD_BDDIS0
CMD_BDDIS0:
	 REGSAVE <ebx,edi>	; Save registers

	 mov	 ebx,not ((mask $L0) or (mask $G0)) ; Get the mask for DR0
	 mov	 edi,0*(size BD_STR) ; EDI = offset into BDREGS

	 jmp	 short CMD_BDDISCOM ; Join common code

	 public  CMD_BDDIS1
CMD_BDDIS1:
	 REGSAVE <ebx,edi>	; Save registers

	 mov	 ebx,not ((mask $L1) or (mask $G1)) ; Get the mask for DR1
	 mov	 edi,1*(size BD_STR) ; EDI = offset into BDREGS

	 jmp	 short CMD_BDDISCOM ; Join common code

	 public  CMD_BDDIS2
CMD_BDDIS2:
	 REGSAVE <ebx,edi>	; Save registers

	 mov	 ebx,not ((mask $L2) or (mask $G2)) ; Get the mask for DR2
	 mov	 edi,2*(size BD_STR) ; EDI = offset into BDREGS

	 jmp	 short CMD_BDDISCOM ; Join common code

	 public  CMD_BDDIS3
CMD_BDDIS3:
	 REGSAVE <ebx,edi>	; Save registers

	 mov	 ebx,not ((mask $L3) or (mask $G3)) ; Get the mask for DR3
	 mov	 edi,3*(size BD_STR) ; EDI = offset into BDREGS

;;;;;;;; jmp	 short CMD_BDDISCOM ; Join common code

CMD_BDDISCOM:
	 REGSAVE <eax>		; Save register

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 jne	 short CMD_BDDIS0123_SYNTERR ; No, so that's an error

; Ensure the register is in use

	 test	 BDREGS.BD_FLAG[edi],@ADDR_INUSE ; Izit in use?
;;;;;;;; jz	 short CMD_BDDIS0123_ERR ; No, so that's an error
	 jz	 short CMD_BDDIS0123_EXIT ; No, so just ignore it (note CF=0)

; Disable the register

	 and	 ebx,SAVE_DR7	; Get debug control register, clear bits

	 test	 ebx,@ANYGL	; Any global or local DRn enables set?
	 jnz	 short @F	; Yes, continue with global/local enable

	 and	 ebx,not (mask $GE) ; Clear global enable
@@:
	 mov	 SAVE_DR7,ebx	; Reset debug control register

; Mark as disabled

	 and	 BDREGS.BD_FLAG[edi],not @ADDR_ENA

	 cmp	 DSP_STATE,@DSP_DRn ; Displaying debug registers?
	 jne	 short @F	; No

	 call	 DISP_DRn	; Display 'em
@@:
	 call	 UD_BREAKLIST	; Update breakpoint list for display
	 clc			; Indicate all went well

	 jmp	 short CMD_BDDIS0123_EXIT ; Join common exit code

CMD_BDDIS0123_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
CMD_BDDIS0123_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Indicate something went wrong
CMD_BDDIS0123_EXIT:
	 REGREST <eax>		; Restore
	 REGREST <edi,ebx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BDDIS0123 endp		; End CMD_BDDIS0123 procedure
	 NPPROC  CMD_BDDIS -- Debug Register Disable All Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debug Register disable all command

BD-

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax>		; Save register

	 inc	 esi		; Skip over the '-'

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 jne	 short CMD_BDDIS_SYNTERR ; No, so that's an error

; Ensure the register is in use

	 test	 BDREGS.BD_FLAG[0*(size BD_STR)],@ADDR_INUSE ; Izit in use?
	 jz	 short @F	; No, so skip it

	 call	 CMD_BDDIS0	; Disable DR0
@@:
	 test	 BDREGS.BD_FLAG[1*(size BD_STR)],@ADDR_INUSE ; Izit in use?
	 jz	 short @F	; No, so skip it

	 call	 CMD_BDDIS1	; Disable DR1
@@:
	 test	 BDREGS.BD_FLAG[2*(size BD_STR)],@ADDR_INUSE ; Izit in use?
	 jz	 short @F	; No, so skip it

	 call	 CMD_BDDIS2	; Disable DR2
@@:
	 test	 BDREGS.BD_FLAG[3*(size BD_STR)],@ADDR_INUSE ; Izit in use?
	 jz	 short @F	; No, so skip it

	 call	 CMD_BDDIS3	; Disable DR3
@@:

	 call	 UD_BREAKLIST	; Update breakpoint list for display
	 clc			; Indicate all went well

	 jmp	 short CMD_BDDIS_EXIT ; Join common exit code

CMD_BDDIS_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
CMD_BDDIS_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Indicate something went wrong
CMD_BDDIS_EXIT:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BDDIS endp			; End CMD_BDDIS procedure
	 NPPROC  CMD_BDENA0123 -- Debug Register Enable DR0-DR3 Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debug Register enable DR0-DR3 commands

BD0+
BD1+
BD2+
BD3+

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 public  CMD_BDENA0
CMD_BDENA0:
	 REGSAVE <edi>		; Save register

	 mov	 edi,0*(size BD_STR) ; EDI = offset into BDREGS

	 jmp	 short CMD_BDENACOM ; Join common code

	 public  CMD_BDENA1
CMD_BDENA1:
	 REGSAVE <edi>		; Save register

	 mov	 edi,1*(size BD_STR) ; EDI = offset into BDREGS

	 jmp	 short CMD_BDENACOM ; Join common code

	 public  CMD_BDENA2
CMD_BDENA2:
	 REGSAVE <edi>		; Save register

	 mov	 edi,2*(size BD_STR) ; EDI = offset into BDREGS

	 jmp	 short CMD_BDENACOM ; Join common code

	 public  CMD_BDENA3
CMD_BDENA3:
	 REGSAVE <edi>		; Save register

	 mov	 edi,3*(size BD_STR) ; EDI = offset into BDREGS

;;;;;;;; jmp	 short CMD_BDENACOM ; Join common code

CMD_BDENACOM:
	 REGSAVE <eax>		; Save register

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 jne	 short CMD_BDENA0123_SYNTERR ; No, so that's an error

; Ensure the register is in use

	 test	 BDREGS.BD_FLAG[edi],@ADDR_INUSE ; Izit in use?
;;;;;;;; jz	 short CMD_BDENA0123_ERR ; No, so that's an error
	 jz	 short CMD_BDENA0123_EXIT ; No, so just ignore it (note CF=0)

; Enable the register

	call	RESPEC_DR7	; Respecify DR7 from BDREGS[edi]

; Mark as enabled

	 or	 BDREGS.BD_FLAG[edi],@ADDR_ENA

	 mov	 eax,BDREGS.BD_BASE[edi] ; Get linear base address
	 add	 eax,BDREGS.BD_OFF[edi] ; Add offset

; Because we might have gone in and out of Windows, we can't trust that
; the DRn linear address register is still valid as Windows sets it to
; zero upon exit.

	call	BDREGS[edi].BD_SET ; Set the new value into place

	 cmp	 DSP_STATE,@DSP_DRn ; Displaying debug registers?
	 jne	 short @F	; No

	 call	 DISP_DRn	; Display 'em
@@:
	 call	 UD_BREAKLIST	; Update breakpoint list for display
	 clc			; Indicate all went well

	 jmp	 short CMD_BDENA0123_EXIT ; Join common exit code

CMD_BDENA0123_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
CMD_BDENA0123_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Indicate something went wrong
CMD_BDENA0123_EXIT:
	 REGREST <eax>		; Restore
	 REGREST <edi>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BDENA0123 endp		; End CMD_BDENA0123 procedure
	 NPPROC  CMD_BDENA -- Debug Register Enable All Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debug Register enable all command

BD+

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

	 REGSAVE <eax>		; Save register

	 inc	 esi		; Skip over the '+'

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 jne	 short CMD_BDENA_SYNTERR ; No, so that's an error

; Ensure the register is in use

	 test	 BDREGS.BD_FLAG[0*(size BD_STR)],@ADDR_INUSE ; Izit in use?
	 jz	 short @F	; No, so skip it

	 call	 CMD_BDENA0	; Enable DR0
@@:
	 test	 BDREGS.BD_FLAG[1*(size BD_STR)],@ADDR_INUSE ; Izit in use?
	 jz	 short @F	; No, so skip it

	 call	 CMD_BDENA1	; Enable DR1
@@:
	 test	 BDREGS.BD_FLAG[2*(size BD_STR)],@ADDR_INUSE ; Izit in use?
	 jz	 short @F	; No, so skip it

	 call	 CMD_BDENA2	; Enable DR2
@@:
	 test	 BDREGS.BD_FLAG[3*(size BD_STR)],@ADDR_INUSE ; Izit in use?
	 jz	 short @F	; No, so skip it

	 call	 CMD_BDENA3	; Enable DR3
@@:
	 call	 UD_BREAKLIST	; Update breakpoint list for display
	 clc			; Indicate all went well

	 jmp	 short CMD_BDENA_EXIT ; Join common exit code

CMD_BDENA_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
CMD_BDENA_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Indicate something went wrong
CMD_BDENA_EXIT:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BDENA endp			; End CMD_BDENA procedure
	 NPPROC  CMD_BD0123 -- Debug Registers Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debug Register DR0-3 clear, enable, disable commands

BD0*	 BD0+	  BD0-
BD1*	 BD1+	  BD1-
BD2*	 BD2+	  BD2-
BD3*	 BD3+	  BD3-

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

; Split off cases for clear, enable, and disable

	 public  CMD_BD0
CMD_BD0:
	 inc	 esi		; Skip over the next symbol

	 cmp	 DGROUP:[esi-1].LO,'*' ; Izit clear?
	 je	 near ptr CMD_BDCLR0 ; Jump if so

	 cmp	 DGROUP:[esi-1].LO,'+' ; Izit enable?
	 je	 near ptr CMD_BDENA0 ; Jump if so

	 cmp	 DGROUP:[esi-1].LO,'-' ; Izit disable?
	 je	 near ptr CMD_BDDIS0 ; Jump if so

	 jmp	 short CMD_BD0123_SYNTERR ; Jump if none of the above


	 public  CMD_BD1
CMD_BD1:
	 inc	 esi		; Skip over the next symbol

	 cmp	 DGROUP:[esi-1].LO,'*' ; Izit clear?
	 je	 near ptr CMD_BDCLR1 ; Jump if so

	 cmp	 DGROUP:[esi-1].LO,'+' ; Izit enable?
	 je	 near ptr CMD_BDENA1 ; Jump if so

	 cmp	 DGROUP:[esi-1].LO,'-' ; Izit disable?
	 je	 near ptr CMD_BDDIS1 ; Jump if so

	 jmp	 short CMD_BD0123_SYNTERR ; Jump if none of the above

	 public  CMD_BD2
CMD_BD2:
	 inc	 esi		; Skip over the next symbol

	 cmp	 DGROUP:[esi-1].LO,'*' ; Izit clear?
	 je	 near ptr CMD_BDCLR2 ; Jump if so

	 cmp	 DGROUP:[esi-1].LO,'+' ; Izit enable?
	 je	 near ptr CMD_BDENA2 ; Jump if so

	 cmp	 DGROUP:[esi-1].LO,'-' ; Izit disable?
	 je	 near ptr CMD_BDDIS2 ; Jump if so

	 jmp	 short CMD_BD0123_SYNTERR ; Jump if none of the above


	 public  CMD_BD3
CMD_BD3:
	 inc	 esi		; Skip over the next symbol

	 cmp	 DGROUP:[esi-1].LO,'*' ; Izit clear?
	 je	 near ptr CMD_BDCLR3 ; Jump if so

	 cmp	 DGROUP:[esi-1].LO,'+' ; Izit enable?
	 je	 near ptr CMD_BDENA3 ; Jump if so

	 cmp	 DGROUP:[esi-1].LO,'-' ; Izit disable?
	 je	 near ptr CMD_BDDIS3 ; Jump if so

;;;;;;;; jmp	 short CMD_BD0123_SYNTERR ; Jump if none of the above

CMD_BD0123_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Mark as in error

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BD0123 endp 		; End CMD_BD0123 procedure
	 NPPROC  CMD_BD -- Debug Registers Command
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debug Register change command

BD  opt_addr
BD*
BD+
BD-

On entry:

DS:ESI	 ==>	 text following command
SS:EBP	 ==>	 FORW_STR

On exit:

CF	 =	 0 if no error
	 =	 1 otherwise

|

; Split off cases for clear, enable, and disable

	 SELFBREAK CMD_BD,40h	; Enable conditional breakpoint

	 cmp	 DGROUP:[esi].LO,'*' ; Izit clear?
	 je	 near ptr CMD_BDCLR ; Jump if so

	 cmp	 DGROUP:[esi].LO,'+' ; Izit enable?
	 je	 near ptr CMD_BDENA ; Jump if so

	 cmp	 DGROUP:[esi].LO,'-' ; Izit disable?
	 je	 near ptr CMD_BDDIS ; Jump if so

	 REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save registers

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 near ptr CMD_BD_DISP ; Yes, treat as display request

	 call	 PARSE_ADDR	; Parse DS:ESI for address
	 jc	 near ptr CMD_BD_ERR ; Jump if error
				; BX  = segment/selector (if @ADDR_SEP)
				; EAX = offset
				; CX  = flags
				; EDX = address base for BX (if @ADDR_SEP)

	 mov	 BDCMD.BD_OFF,eax ; Save for later use
	 or	 cx,@ADDR_ENA or @ADDR_INUSE ; Mark as enabled and in use
	 mov	 BDCMD.BD_FLAG,cx ; Save for later use

	 test	 cx,@ADDR_SEP	; Separator specified?
	 jz	 short @F	; Not this time

	 mov	 BDCMD.BD_SEL,bx ; Save for later use
	 mov	 BDCMD.BD_BASE,edx
@@:

; Parse length separator

	 mov	 BDCMD.BD_TYPE,@BD_X ; Assume instruction fetch
	 mov	 BDCMD.BD_LEN,@BD_L1 ; Assume length 1 for instruction fetches

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 near ptr CMD_BD_COM ; Yes, treat as instruction breakpoint

	 call	 U32_LOWERCASE	; Convert AL to lowercase

	 cmp	 al,'l'         ; Izit length parameter?
	 jne	 near ptr CMD_BD_SYNTERR ; No, so that's an error

	 inc	 esi		; Skip over length separator

; Parse length parameter

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,'1'         ; Izit length 1?
	 je	 short @F	; Yes

	 cmp	 al,'2'         ; Izit length 2?
	 je	 short @F	; Yes

	 cmp	 al,'4'         ; Izit length 4?
	 jne	 near ptr CMD_BD_SYNTERR ; No, so that's an error
@@:
	 sub	 al,'1'         ; Convert to origin-1
	 mov	 BDCMD.BD_LEN,al ; Save for later use

	 inc	 esi		; Skip over length parameter

; Parse breakpoint type

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

;;;;;;;; cmp	 al,0		; Izit end-of-the-line?
;;;;;;;; je	 short CMD_BD_SYNTERR ; Yes, so that's an error

	 call	 U32_LOWERCASE	; Convert AL to lowercase

	 cmp	 al,'r'         ; Izit read/write?
	 mov	 ah,@BD_RW	; Assume so
	 je	 short CMD_BDTYP ; Yes

	 cmp	 al,'w'         ; Izit write-only?
	 mov	 ah,@BD_W	; Assume so
	 je	 short CMD_BDTYP ; Yes

	 test	 CPUFET_FLAG,@CPUFET_IOBRK ; Are I/O breakpoints supported?
	 jz	 short CMD_BDXP5 ; Jump if not

	 cmp	 al,'i'         ; Izit I/O read/write?
	 mov	 ah,@BD_IO	; Assume so
	 je	 short CMD_BDIO ; Yes

	 cmp	 al,'o'         ; Izit I/O read/write?
;;;;;;;; mov	 ah,@BD_IO	; Assume so
	 jne	 short CMD_BDXP5 ; No
CMD_BDIO:
	 test	 cx,@ADDR_SEP	; Separator specified?
	 jnz	 near ptr CMD_BD_SYNTERR ; Yes (not allowed with I/O breakpoints)

; Ensure debugging extensions are enabled

	 MOVSPR  ebx,cr4	; Get CPU extensions register
	 or	 ebx,mask $DE	; DE=1
	 MOVSPR  cr4,ebx	; Tell the CPU about it

	 jmp	 short CMD_BDTYP ; Join common code

CMD_BDXP5:
	 cmp	 al,'x'         ; Izit execute?
	 mov	 ah,@BD_X	; Assume so
	 jne	 near ptr CMD_BD_SYNTERR ; No, so that's an error

	 cmp	 BDCMD.BD_LEN,@BD_L1 ; Ensure execute is length 1
	 jne	 near ptr CMD_BD_SYNTERR ; No, so that's an error
CMD_BDTYP:
	 mov	 BDCMD.BD_TYPE,ah ; Save for later use

	 inc	 esi		; Skip over breakpoint type

; Ensure nothing more on the line

	 call	 CMD_WHITE	; Skip over leading white space
				; Return with AL = last character

	 cmp	 al,0		; Izit end-of-the-line?
	 jne	 near ptr CMD_BD_SYNTERR ; No, so that's an error
CMD_BD_COM:

; Find a debug register to use

	 xor	 edi,edi	; Initialize index into BDREGS structure
	 mov	 ecx,4		; # registers to check
@@:
	 test	 BDREGS.BD_FLAG[edi],@ADDR_INUSE ; Izit in use?
	 jz	 short CMD_BD_SET ; No, save values

	 add	 edi,size BD_STR ; Skip to next register

	 loop	 @B		; Jump if more registers to check

	 jmp	 CMD_BD_REGERR ; Jump if none available

CMD_BD_SET:

; Set debug register

	 mov	 eax,BDCMD.BD_BASE ; Get base address
	 add	 eax,BDCMD.BD_OFF ; Plus offset

	call	BDREGS[edi].BD_SET ; Set the new value into place

	 jmp	 short CMD_BDSETCOM ; Join common code

	public	CMD_BDSET_A
CMD_BDSET_A:
CMD_BDSET0:
	 mov	 dr0,eax	; Set debug register

	 ret			; Return to caller

CMD_BDSET1:
	 mov	 dr1,eax	; Set debug register

	 ret			; Return to caller

CMD_BDSET2:
	 mov	 dr2,eax	; Set debug register

	 ret			; Return to caller

CMD_BDSET3:
	 mov	 dr3,eax	; Set debug register

	public	CMD_BDSET_Z
CMD_BDSET_Z:
	 ret			; Return to caller

CMD_BDSETCOM:

; Copy values to save area

	push	edi		; Save for a moment

	 lea	 esi,BDCMD	; DS:ESI ==> command line values
	 lea	 edi,BDREGS[edi] ; ES:EDI ==> save area in BDREGS structure
	 mov	 ecx,BD_SET-BD_REG ; ECX = # bytes in dyanmic structure
S32  rep movs	 <es:[edi].LO,ds:[esi].LO> ; Copy to structure

	pop	edi		; Restore

	call	RESPEC_DR7	; Respecify DR7 from BDREGS[edi]

	 cmp	 DSP_STATE,@DSP_DRn ; Displaying debug registers?
	 jne	 short CMD_BD_CLC ; No, join common OK code
CMD_BD_DISP:
	 call	 DISP_DRn	; Display 'em
CMD_BD_CLC:
	 call	 UD_BREAKLIST	; Update breakpoint list for display
	 clc			; Indicate all went well

	 jmp	 short CMD_BD_EXIT ; Join common exit code

CMD_BD_SYNTERR:
	 mov	 MSGOFF,offset DGROUP:SYNTERR ; Save offset of error message

	 jmp	 short CMD_BD_ERR ; Join common error exit code

CMD_BD_REGERR:
	 mov	 MSGOFF,offset DGROUP:BDREGERR ; Save offset of error message
CMD_BD_ERR:
	 or	 LC2_FLAG,@LC2_MSG ; Mark as message to display

	 stc			; Mark as in error
CMD_BD_EXIT:
	 REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_BD	 endp			; End CMD_BD procedure
	 NPPROC  DISP_DRn -- Debug Register Display
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display debug register values

|

	 REGSAVE <eax,ebx,ecx,esi,edi> ; Save registers

; Format debug registers into window

	 mov	 eax,dr0	; Get 1st debug register
	 mov	 BDREGS.BD_REG[0*(size BD_STR)],eax ; Save in data structure
	 mov	 eax,dr1	; Get 2nd debug register
	 mov	 BDREGS.BD_REG[1*(size BD_STR)],eax ; Save in data structure
	 mov	 eax,dr2	; Get 3rd debug register
	 mov	 BDREGS.BD_REG[2*(size BD_STR)],eax ; Save in data structure
	 mov	 eax,dr3	; Get 4th debug register
	 mov	 BDREGS.BD_REG[3*(size BD_STR)],eax ; Save in data structure

	 xor	 esi,esi	; Initialize index into BDREGS
	 lea	 ebx,DBG_LN1	; Initialize index into DBG_WIN
	 mov	 ecx,4		; # debug registers
DISP_DRn_NEXT:
	 mov	 al,'+'         ; Assume enabled

	 test	 BDREGS.BD_FLAG[esi],@ADDR_ENA ; Izit enabled?
	 jnz	 short @F	; Jump if so

	 mov	 al,'-'         ; Assume disabled

	 test	 BDREGS.BD_FLAG[esi],@ADDR_INUSE ; Izit in use, but disabled?
	 jnz	 short @F	; Jump if so

	 mov	 al,' '         ; Marker for available
@@:
	 mov	 DBG_WIN_EN0[ebx],al ; Save in output display

	 lea	 edi,DBG_WIN_SL0[ebx] ; ES:EDI ==> selector display

; If this is an I/O breakpoint, the selector field is meaningless,
; so we'll display blanks

	 mov	 DGROUP:[edi].EDD,'   ' ; Blank the field
	 mov	 al,' '         ; ...

	 cmp	 BDREGS.BD_TYPE[esi],@BD_IO ; Izit an I/O breakpoint?
	 je	 short DISP_DRn_IO ; Jump if so

	 mov	 ax,BDREGS.BD_SEL[esi] ; Get debug selector
	 call	 BIN2WORD	; Convert the word

	 mov	 al,'?'         ; Assume not in use

	 test	 BDREGS.BD_FLAG[esi],@ADDR_INUSE ; Izit in use?
	 jz	 short @F	; Not this time

	 mov	 al,'|'         ; Assume PM

	 test	 BDREGS.BD_FLAG[esi],@ADDR_PM ; Izit Protected Mode?
	 jnz	 short @F	; Yes

	 mov	 al,':'         ; It's VM86
@@:
DISP_DRn_IO:
	 mov	 DBG_WIN_SP0[ebx],al ; Save in window

	 mov	 eax,BDREGS.BD_OFF[esi] ; Get debug offset
	 lea	 edi,DBG_WIN_OF0[ebx] ; ES:EDI ==> offset display
	 call	 BIN2DWORD	; Convert the dword

	 mov	 eax,BDREGS.BD_REG[esi] ; Get debug register
	 lea	 edi,DBG_WIN_DR0[ebx] ; ES:EDI ==> register display
	 call	 BIN2DWORD	; Convert the dword

	 movzx	 eax,BDREGS.BD_LEN[esi] ; Get debug length
	 mov	 al,BDLENS[eax] ; Convert to '1', '2', '?', or '4'
	 mov	 DBG_WIN_LN0[ebx],al ; Save in output display

	 movzx	 eax,BDREGS.BD_TYPE[esi] ; Get debug type
	 mov	 ax,BDTYPES.ELO[eax*2] ; Convert to 'X ', 'R ', or 'RW'
	 mov	 DBG_WIN_TP0[ebx],ax ; Save in output display

	 add	 esi,size BD_STR ; Skip to next row in BDREGS
	 add	 ebx,NDBGCOLS	; Skip to next row in DBG_WIN

;;;;;;;; loop	 DISP_DRn_NEXT	; Jump if more rows to format
	 dec	 ecx		; One fewer row to format
;;;;;;;; and	 ecx,ecx	; Any rows remain?
	 jnz	 near ptr DISP_DRn_NEXT  ; Jump if more rows to format

	 call	 DISP_DR6	; Format and display DR6
	 call	 DISP_DR7	; Format and display DR7

; Display the window

	 mov	 W_BD.SROW,(@NROWS-NDBGROWS)/2 ; Start in middle row
	 mov	 W_BD.SCOL,(@NCOLS-NDBGCOLS)/2 ; Start in middle col
	 mov	 W_BD.NROW,NDBGROWS ; # rows in debug window
	 mov	 W_BD.NCOL,NDBGCOLS ; # cols ...

	 mov	 al,DBGATTR	; Get debug window attribute
	 push	 ax		; Pass as attribute to smear
	 push	 offset ds:DBG_WIN ; Pass address of debug window
	 push	 offset ds:W_BD ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

	 mov	 al,@DSP_DRn	; Set new display state
	 call	 SET_STATE	; Set new state

	 REGREST <edi,esi,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DRn endp			; End DISP_DRn procedure
	 NPPROC  DISP_DR6 -- Format and Display DR6
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display DR6

|

	 REGSAVE <eax,ecx,edi>	; Save registers

; Clear flag text for DR6

	 lea	 edi,DBG_DR6[DBG_DR6_BT] ; ES:EDI ==> output save area
	 mov	 ecx,2+DBG_DR6_B0-DBG_DR6_BT ; # bytes to clear
	 mov	 al,' '         ; Clear to this value
     rep stos	 DBG_DR6[edi]	; Clear it

; Format DR6

	 mov	 eax,dr6	; Get the status register
	 lea	 edi,DBG_DR6[DBG_DR6_REG] ; ES:EDI ==> register display
	 call	 BIN2DWORD	; Convert the dword

; Format the flags in DR6

	 test	 ax,mask $BT	; Izit set?
	 jz	 short @F	; Not this time

	 mov	 DBG_DR6.ELO[DBG_DR6_BT],'TB' ; Mark as set
@@:
	 test	 ax,mask $BS	; Izit set?
	 jz	 short @F	; Not this time

	 mov	 DBG_DR6.ELO[DBG_DR6_BS],'SB' ; Mark as set
@@:
	 test	 ax,mask $BD	; Izit set?
	 jz	 short @F	; Not this time

	 mov	 DBG_DR6.ELO[DBG_DR6_BD],'DB' ; Mark as set
@@:
	 test	 ax,mask $B3	; Izit set?
	 jz	 short @F	; Not this time

	 mov	 DBG_DR6.ELO[DBG_DR6_B3],'3B' ; Mark as set
@@:
	 test	 ax,mask $B2	; Izit set?
	 jz	 short @F	; Not this time

	 mov	 DBG_DR6.ELO[DBG_DR6_B2],'2B' ; Mark as set
@@:
	 test	 ax,mask $B1	; Izit set?
	 jz	 short @F	; Not this time

	 mov	 DBG_DR6.ELO[DBG_DR6_B1],'1B' ; Mark as set
@@:
	 test	 ax,mask $B0	; Izit set?
	 jz	 short @F	; Not this time

	 mov	 DBG_DR6.ELO[DBG_DR6_B0],'0B' ; Mark as set
@@:
	 REGREST <edi,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DR6 endp			; End DISP_DR6 procedure
	 NPPROC  DISP_DR7 -- Format and Display DR7
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display DR7

|

	 REGSAVE <eax,ecx,edi>	; Save registers

; Clear flag text for DR7

	 lea	 edi,DBG_DR7[DBG_DR7_GD] ; ES:EDI ==> output save area
	 mov	 ecx,2+DBG_DR7_L0-DBG_DR7_GD ; # bytes to clear
	 mov	 al,' '         ; Clear to this value
     rep stos	 DBG_DR7[edi]	; Clear it

; Format DR7

	 mov	 eax,SAVE_DR7	; Get the control register
	 lea	 edi,DBG_DR7[DBG_DR7_REG] ; ES:EDI ==> register display
	 call	 BIN2DWORD	; Convert the dword

; Format the flags in DR7

	 test	 ax,mask $GD	; Izit set?
	 jz	 short @F	; Not this time

	 mov	 DBG_DR7.ELO[DBG_DR7_GD],'DG' ; Mark as set
@@:
	 test	 ax,mask $GE	; Izit set?
	 jz	 short @F	; Not this time

	 mov	 DBG_DR7.ELO[DBG_DR7_GE],'EG' ; Mark as set
@@:
	 test	 ax,mask $LE	; Izit set?
	 jz	 short @F	; Not this time

	 mov	 DBG_DR7.ELO[DBG_DR7_LE],'EL' ; Mark as set
@@:
	 test	 ax,mask $G3	; Izit set?
	 jz	 short @F	; Not this time

	 mov	 DBG_DR7.ELO[DBG_DR7_G3],'3G' ; Mark as set
@@:
	 test	 ax,mask $L3	; Izit set?
	 jz	 short @F	; Not this time

	 mov	 DBG_DR7.ELO[DBG_DR7_L3],'3L' ; Mark as set
@@:
	 test	 ax,mask $G2	; Izit set?
	 jz	 short @F	; Not this time

	 mov	 DBG_DR7.ELO[DBG_DR7_G2],'2G' ; Mark as set
@@:
	 test	 ax,mask $L2	; Izit set?
	 jz	 short @F	; Not this time

	 mov	 DBG_DR7.ELO[DBG_DR7_L2],'2L' ; Mark as set
@@:
	 test	 ax,mask $G1	; Izit set?
	 jz	 short @F	; Not this time

	 mov	 DBG_DR7.ELO[DBG_DR7_G1],'1G' ; Mark as set
@@:
	 test	 ax,mask $L1	; Izit set?
	 jz	 short @F	; Not this time

	 mov	 DBG_DR7.ELO[DBG_DR7_L1],'1L' ; Mark as set
@@:
	 test	 ax,mask $G0	; Izit set?
	 jz	 short @F	; Not this time

	 mov	 DBG_DR7.ELO[DBG_DR7_G0],'0G' ; Mark as set
@@:
	 test	 ax,mask $L0	; Izit set?
	 jz	 short @F	; Not this time

	 mov	 DBG_DR7.ELO[DBG_DR7_L0],'0L' ; Mark as set
@@:
	 REGREST <edi,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DR7 endp			; End DISP_DR7 procedure
	NPPROC	RESPEC_DR7 -- Respecify DR7
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Respecify DR7

On entry:

EDI	=	offset into BDREGS of current register

|

	REGSAVE <eax,ebx,ecx,edx> ; Save for a moment

	mov	eax,SAVE_DR7	; Get control register

; Set DR7 length/type mask

	movzx	edx,BDREGS[edi].BD_LEN ; Get length bits
	shl	edx,$LEN0-$RW0	; Shift over
	or	dl,BDREGS[edi].BD_TYPE ; Plus type bits
	mov	cl,BDREGS[edi].BD_LSHF ; Get length/type shift amount
	mov	ebx,((mask $LEN0) or (mask $RW0)) shr $RW0 ; Get the bit mask
	shl	ebx,cl		; Shift into place
	not	ebx		; Complement to clear DR7
	and	eax,ebx 	; Clear value for DR7
	shl	edx,cl		; Shift into place
	or	eax,edx 	; Set length/type mask

; Set DR7 enable mask

	mov	edx,(mask $G0) or (mask $L0) ; Get mask for DR0
	mov	cl,BDREGS[edi].BD_ESHF ; Get enable shift amount
	shl	edx,cl		; Shift into place
	or	eax,edx 	; Set enable mask

; Set global enable bit

	or	eax,mask $GE	; Set it

; Set debug control register

	mov	SAVE_DR7,eax	; Set it

	REGREST <edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESPEC_DR7 endp 		; End RESPEC_DR7 procedure
	 NPPROC  DISP_BC -- Display All Code Breakpoints
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display all code breakpoints

On entry:

SS:EBP	 ==>	 FORW_STR

|

	 REGSAVE <eax,ebx,ecx,esi,edi> ; Save registers

	 xor	 esi,esi	; Initialize index into BCDATA
	 lea	 ebx,BC_LN1	; Initialize index into BC_WIN
	 mov	 ecx,@NBC	; # code breakpoints
DISP_BC_NEXT:
	 mov	 al,' '         ; Assume not in use

	 test	 BCDATA.BC_FLAG[esi],@ADDR_INUSE ; Izit in use?
	 jz	 short @F	; Jump if not

	 mov	 al,'+'         ; Assume enabled

	 test	 BCDATA.BC_FLAG[esi],@ADDR_ENA ; Izit enabled?
	 jnz	 short @F	; Jump if so

	 mov	 al,'-'         ; Assume disabled
@@:
	 mov	 BC_WIN_EN0[ebx],al ; Save in output display

	 mov	 eax,@NBC	; Get maximum value
	 sub	 eax,ecx	; Less current value
	 lea	 edi,BC_WIN_IN0[ebx] ; ES:EDI ==> index display
	 call	 BIN2DIGIT	; Convert the digit

	 mov	 ax,BCDATA.BC_SEL[esi] ; Get BC selector
	 lea	 edi,BC_WIN_SL0[ebx] ; ES:EDI ==> selector display
	 call	 BIN2WORD	; Convert the word

	 mov	 al,'?'         ; Assume not in use

	 test	 BCDATA.BC_FLAG[esi],@ADDR_INUSE ; Izit in use?
	 jz	 short @F	; Not this time

	 mov	 al,'|'         ; Assume PM

	 test	 BCDATA.BC_FLAG[esi],@ADDR_PM ; Izit Protected Mode?
	 jnz	 short @F	; Yes

	 mov	 al,':'         ; It's VM86
@@:
	 mov	 BC_WIN_SP0[ebx],al ; Save in window

	 mov	 eax,BCDATA.BC_OFF[esi] ; Get BC offset
	 lea	 edi,BC_WIN_OF0[ebx] ; ES:EDI ==> offset display
	 call	 BIN2DWORD	; Convert the dword

	 mov	 eax,BCDATA.BC_LIN[esi] ; Get linear address
	 lea	 edi,BC_WIN_BC0[ebx] ; ES:EDI ==> linear address display
	 call	 BIN2DWORD	; Convert the dword

	 mov	 BC_WIN_VL0[ebx].ELO,'__' ; Assume not in use

	 test	 BCDATA.BC_FLAG,@ADDR_INUSE ; Izit in use?
	 jz	 short @F	; Jump if not

	 mov	 al,BCDATA.BC_VAL[esi] ; Get original value
	 lea	 edi,BC_WIN_VL0[ebx] ; ES:EDI ==> original value display
	 call	 BIN2BYTE	; Convert the byte
@@:
	 add	 esi,size BC_STR ; Skip to next row in BCDATA
	 add	 ebx,NBCCOLS	; Skip to next row in BC_WIN

;;;;;;;; loop	 DISP_BC_NEXT	; Jump if more rows to format
	 dec	 ecx		; Less one row
	 jnz	 DISP_BC_NEXT	; Jump if more rows to format

; Display the window

	 mov	 W_BC.SROW,(@NROWS-NBCROWS)/2 ; Start in middle row
	 mov	 W_BC.SCOL,(@NCOLS-NBCCOLS)/2 ; Start in middle col
	 mov	 W_BC.NROW,NBCROWS ; # rows in debug window
	 mov	 W_BC.NCOL,NBCCOLS ; # cols ...

	 mov	 al,DBGATTR	; Get debug window attribute
	 push	 ax		; Pass as attribute to smear
	 push	 offset ds:BC_WIN ; Pass address of debug window
	 push	 offset ds:W_BC ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

	 mov	 al,@DSP_BC	; Set new display state
	 call	 SET_STATE	; Set new state

	 REGREST <edi,esi,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_BC  endp			; End DISP_BC procedure
	 NPPROC CHECK_DBG -- Check linear address for inclusion in breakpt list
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for a linear address in a list of breakpoints.  This is called
for every instruction line disassembled, so speed is important.

On entry:
EAX	 =	linear address to check for

On exit:
CF=1		not a breakpoint
CF=0		is a breakpoint (type unspecified)

CHECK_DBG_RES is also set to 1 if breakpoint, otherwise 0.

|

	 REGSAVE <ecx,edi>	; Save

	 mov	 ecx,BREAKLIST_CNT ; Get number of breakpoints active
	 jecxz	 short CHECK_DBG_ERR ; None active

	 lea	 edi,BREAKLIST	; Address active breakpoint list
   repne scas	 BREAKLIST[edi] ; Find a match
	 jnz	 short CHECK_DBG_ERR ; Jump if not found

	 mov	 CHECK_DBG_RES,1 ; Signal success
	 clc			; Clear CF
	 jmp	 short CHECK_DBG_EXIT ; Join common exit code

CHECK_DBG_ERR:
	 mov	 CHECK_DBG_RES,0 ; Signal failure
	 stc			; Signal failure

CHECK_DBG_EXIT:
	 REGREST <edi,ecx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DBG endp			; End CHECK_DBG procedure
	 NPPROC UD_BREAKLIST -- Update breakpoint list
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Called after any changes to code or data breakpoints.

Walk through breakpoint structures and update breakpoint list.	This
allows the check for a line with breakpoints on it to be done quickly
when disassembling.

On entry:
nothing

On exit:
nothing

|

	 REGSAVE <eax,ecx,esi,edi> ; Save

	 sub	 edi,edi	; Index first member of BREAKLIST[]
	 mov	 BREAKLIST_CNT,0 ; Clear count

	 sub	 esi,esi	; Index first member of BDREGS
	 mov	 ecx,4		; Number of debug registers
UD_BREAKLIST_NEXT:
	 test	 BDREGS.BD_FLAG[esi],@ADDR_INUSE ; Izit used?
	 jz	 short @F	; Jump if not

	 test	 BDREGS.BD_FLAG[esi],@ADDR_ENA ; Izit enabled?
	 jz	 short @F	; Jump if not

	 inc	 BREAKLIST_CNT	; Increment count of breakpoints
	 mov	 eax,BDREGS.BD_BASE[esi] ; Get linear base address
	 add	 eax,BDREGS.BD_OFF[esi] ; Add offset
	 mov	 BREAKLIST[edi],eax ; Save linear address
	 add	 edi,type BREAKLIST ; Skip to next dword
@@:
	 add	 esi,size BD_STR ; Skip to next register structure
	 loop	 UD_BREAKLIST_NEXT ; Check all debug registers

	 sub	 esi,esi	; Index first member of BCDATA
	 mov	 ecx,@NBC	; Number of code breakpoints
UD_BREAKLIST_NEXT2:
	 test	 BCDATA.BC_FLAG[esi],@ADDR_INUSE ; Izit in use?
	 jz	 short @F	; Jump if not

	 test	 BCDATA.BC_FLAG[esi],@ADDR_ENA ; Izit enabled?
	 jz	 short @F	; Jump if not

	 inc	 BREAKLIST_CNT	; Increment count of breakpoints
	 mov	 eax,BCDATA.BC_LIN[esi] ; Get linear address
	 mov	 BREAKLIST[edi],eax ; Save it
	 add	 edi,type BREAKLIST ; Skip to next dword
@@:
	 add	 esi,size BC_STR ; Skip to next breakpoint structure
	 loop	 UD_BREAKLIST_NEXT2 ; Check all code breakpoints

	 or	 LCL_FLAG,@LCL_REDI ; Force redisplay

	 REGREST <edi,esi,ecx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UD_BREAKLIST endp		; End UD_BREAKLIST procedure

PROG	 ends			; End PROG segment

	 MEND			; End SWAT_DBG module
