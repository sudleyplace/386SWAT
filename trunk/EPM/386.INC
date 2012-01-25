;
; 386.INC
;
; 386-specific macros, equates, records, and structures
;

; Fault error code record

FAULTCODE record $FSEL:13,$FTI:1,$FIDT:1,$FEXT:1


; CR0 flags

CR0FLAGS record  $PG:1,$CD:1,$NW:1,$CR0RSV0:10,$AM:1,$CR0RSV1:1,$WP:1,\
		 $CR0RSV2:10,$NE:1,$ET:1,$TS:1,$EM:1,$MP:1,$PE:1


; CR3 flags

CR3FLAGS record  $PCD:1,$PWT:1,$CR3_RSV:3


; Linear address format

LAFMT_REC record $LA_DIR:10,$LA_PAGE:10,$LA_OFF:12


; Page Table Entry record

PTE_REC  record  $PTE_FRMHI:16,$PTE_FRM:4,$PTE_AV2:1,$PTE_AV1:1,$PTE_AV0:1,$PTE_0:1,\
		 $PTE_PS:1,$PTE_D:1,$PTE_A:1,$PTE_CD:1,$PTE_WT:1,$PTE_US:1,$PTE_RW:1,$PTE_P:1
@PTE_FRM equ	 ((mask $PTE_FRMHI) or (mask $PTE_FRM))

; Combine User/Read-write/Present into one equate

@PTE_URP equ	 (mask $PTE_US) or (mask $PTE_RW) or (mask $PTE_P)

; Combine      Read-write/Present into one equate

@PTE_RP  equ			   (mask $PTE_RW) or (mask $PTE_P)


; 386 Task State Segment structure

TSS_STR  struc

TSS_LINK dw	 ?,0		; Back link to previous TSS (dynamic)

; The static information begins here

TSS_ESP0 dd	 ?		; ESP for PL0 stack
TSS_SS0  dw	 ?,0		; SS  for ...

TSS_ESP1 dd	 ?		; ESP for PL1 stack
TSS_SS1  dw	 ?,0		; SS  for ...

TSS_ESP2 dd	 ?		; ESP for PL2 stack
TSS_SS2  dw	 ?,0		; SS  for ...

TSS_CR3  dd	 ?		; CR3 (PDBR)

; The rest of the dynamic TSS information begins here

TSS_EIP  dd	 ?		; EIP
TSS_EFL  dd	 ?		; EFL
TSS_EAX  dd	 ?		; EAX
TSS_ECX  dd	 ?		; ECX
TSS_EDX  dd	 ?		; EDX
TSS_EBX  dd	 ?		; EBX
TSS_ESP  dd	 ?		; ESP
TSS_EBP  dd	 ?		; EBP
TSS_ESI  dd	 ?		; ESI
TSS_EDI  dd	 ?		; EDI
TSS_ES	 dw	 ?,0		; ES
TSS_CS	 dw	 ?,0		; CS
TSS_SS	 dw	 ?,0		; SS
TSS_DS	 dw	 ?,0		; DS
TSS_FS	 dw	 ?,0		; FS
TSS_GS	 dw	 ?,0		; GS

; More static information

TSS_LDT  dw	 ?,0		; LDT
TSS_DBG  dw	 0		; Debug bit in low-order
TSS_IOMAP dw	 size TSS_STR	; I/O Map Base

TSS_STR  ends


; 286 Task State Segment structure

TSS2_STR struc

TSS2_LINK dw	 ?		; Back link to previous TSS (dynamic)

; The static information begins here

TSS2_SP0 dw	 ?		; SP for PL0 stack
TSS2_SS0 dw	 ?		; SS for ...

TSS2_SP1 dw	 ?		; SP for PL1 stack
TSS2_SS1 dw	 ?		; SS for ...

TSS2_SP2 dw	 ?		; SP for PL2 stack
TSS2_SS2 dw	 ?		; SS for ...

; The rest of the dynamic TSS information begins here

TSS2_IP  dw	 ?		; IP
TSS2_FL  dw	 ?		; FL
TSS2_AX  dw	 ?		; AX
TSS2_CX  dw	 ?		; CX
TSS2_DX  dw	 ?		; DX
TSS2_BX  dw	 ?		; BX
TSS2_SP  dw	 ?		; SP
TSS2_BP  dw	 ?		; BP
TSS2_SI  dw	 ?		; SI
TSS2_DI  dw	 ?		; DI
TSS2_ES  dw	 ?		; ES
TSS2_CS  dw	 ?		; CS
TSS2_SS  dw	 ?		; SS
TSS2_DS  dw	 ?		; DS

; More static information

TSS2_LDT dw	 ?		; LDT

TSS2_STR ends


PUSHAD_STR struc

PUSHAD_EDI dd	 ?
PUSHAD_ESI dd	 ?
PUSHAD_EBP dd	 ?
PUSHAD_ESP dd	 ?
PUSHAD_EBX dd	 ?
PUSHAD_EDX dd	 ?
PUSHAD_ECX dd	 ?
PUSHAD_EAX dd	 ?

PUSHAD_STR ends


S16	 macro	 I,J,K,L,M,N,O,P

	 I J K L M N O P
if @WordSize eq 4
	 db	 67h		; Use Address Size Prefix
endif				; IF @WordSize EQ 4
	 nop			; Ensure same size NOP

	 endm			; S16


S32	 macro	 I,J,K,L,M,N,O,P

	 I J K L M N O P
if @WordSize eq 2
	 db	 67h		; Use Address Size Prefix
endif				; IF @WordSize EQ 2
	 nop

	 endm			; S32


LOOPS	 macro	 I,J,K,L,M,N,O,P

if @WordSize eq 4
	 db	 67h		; ASP
endif				; IF @WordSize EQ 2
	 loop	 I J K L M N O P

	 endm			; LOOPS


LOOPSZ	 macro	 I,J,K,L,M,N,O,P

if @WordSize eq 4
	 db	 67h		; ASP
endif				; IF @WordSize EQ 2
	 loopz	 I J K L M N O P

	 endm			; LOOPSZ


LOOPSNZ  macro	 I,J,K,L,M,N,O,P

if @WordSize eq 4
	 db	 67h		; ASP
endif				; IF @WordSize EQ 2
	 loopnz  I J K L M N O P

	 endm			; LOOPSNZ


LOOPD	 macro	 I,J,K,L,M,N,O,P

if @WordSize eq 2
	 db	 67h		; ASP
endif				; IF @WordSize EQ 2
	 loop	 I J K L M N O P

	 endm			; LOOPD


PUSHW	 macro	 NN

if @WordSize eq 4
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 4
	 push	 NN

	 endm			; PUSHW


PUSHD	 macro	 NN

if @WordSize eq 2
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 2
	 push	 NN

	 endm			; PUSHD


POPW	 macro	 NN

if @WordSize eq 4
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 4
	 pop	 NN

	 endm			; POPW


POPD	 macro	 NN

if @WordSize eq 2
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 2
	 pop	 NN

	 endm			; POPD


RETFD	 macro	 NN

if @WordSize eq 2
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 2
	 retf	 NN

	 endm			; RETFD


RETD	 macro	 NN

if @WordSize eq 2
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 2
	 retn	 NN

	 endm			; RETD


CALLD	 macro	 NN

if @WordSize eq 2
	 push	 0		; High-order word of return address
endif				; IF @WordSize EQ 2
	 call	 near ptr NN

	 endm			; CALLD


FCALLD	 macro	 NN

	 PUSHD	 cs		; Push dword selector
	 CALLD	 NN

	 endm			; FCALLD


FINTD	 macro	 NN

	 pushfd 		; Simulate 32-bit INT call
	 cli
	 FCALLD  NN

	 endm			; FINTD


FINT	 macro	 NN

	 pushf			; Simulate 16-bit INT call
	 cli
	 push	 cs		; Push word selector
	 call	 near ptr NN

	 endm			; FINT


CPUID	 macro

	 db	 0Fh,0A2h	; MASM doesn't support CPUID as yet

	 endm			; CPUID


SGDTD	 macro	 I,J,K,L,M,N

if @WordSize eq 2
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 2
	 sgdt	  I J K L M N

	 endm			; SGDTD


SIDTD	 macro	 I,J,K,L,M,N

if @WordSize eq 2
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 2
	 sidt	  I J K L M N

	 endm			; SIDTD


LGDTD	 macro	 I,J,K,L,M,N

if @WordSize eq 2
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 2
	 lgdt	  I J K L M N

	 endm			; LGDTD


LIDTD	 macro	 I,J,K,L,M,N

if @WordSize eq 2
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 2
	 lidt	  I J K L M N

	 endm			; LIDTD


