;' $Header:   P:/PVCS/MAX/INC/CPUFET.INV   1.2   30 May 1997 11:15:56   BOB  $
;
; (C) Copyright 1992-2006 Qualitas, Inc.  All rights reserved.
;
; CPUFET.INC
;
; CPU feature bits
;
; The following record maps the CPU feature bits for CPUs which
; support the CPUID instruction.

if (@Cpu and 1000b)		; If 80386 instructions
.xcref VENDOR_REC
VENDOR_REC record \
 $VEND_INTEL:1, \
 $VEND_CYRIX:1, \
 $VEND_AMD:1

.xcref CPUFET_REC
;$CPUFET_INVD:1,   $CPUFET_INTEL:1,  $CPUFET_RSV2:2,   $CPUFET_SNOOP:1,  \
CPUFET_REC record  \
 $CPUFET_SSE2:1,   $CPUFET_SSE:1,    $CPUFET_FXSR:1,   $CPUFET_MMX:1,	 \
 $CPUFET_ACPI:1,   $CPUFET_DBGTR:1,  $CPUFET_RSV1:1,   $CPUFET_CLFLSH:1, \
 $CPUFET_PSN:1,    $CPUFET_PSE36:1,  $CPUFET_PAT:1,    $CPUFET_CMOV:1,	 \
 $CPUFET_MCA:1,    $CPUFET_PGE:1,    $CPUFET_MTRR:1,   $CPUFET_SEP:1,	 \
 $CPUFET_P54C_MP:1,$CPUFET_APIC:1,   $CPUFET_CMP8B:1,  $CPUFET_MCE:1,	 \
 $CPUFET_PAE:1,    $CPUFET_MSREG:1,  $CPUFET_TSCNT:1,  $CPUFET_4MBPG:1,  \
 $CPUFET_IOBRK:1,  $CPUFET_VME:1,    $CPUFET_NDPIN:1

;;.xcref @CPUFET_LOCAL, @CPUFET_INVD,  @CPUFET_INTEL, @CPUFET_FXSR
.xcref @CPUFET_MMX,   @CPUFET_PSE36, @CPUFET_PAT,  @CPUFET_CMOV
.xcref @CPUFET_MCA,   @CPUFET_PGE,   @CPUFET_MTRR,  @CPUFET_SEP
.xcref @CPUFET_P54C_MP,@CPUFET_APIC, @CPUFET_CMP8B, @CPUFET_MCE
.xcref @CPUFET_PAE,   @CPUFET_MSREG, @CPUFET_TSCNT
.xcref @CPUFET_4MBPG, @CPUFET_PSE,   @CPUFET_IOBRK, @CPUFET_VME, @CPUFET_NDPIN

; @CPUFET_LOCAL contains local flags not defined by Pentium; append
; to this list any new flags in the same category.

;;@CPUFET_LOCAL  equ  ((mask $CPUFET_INVD) or (mask $CPUFET_INTEL))

;;@CPUFET_INVD	 equ  mask $CPUFET_INVD ; 80000000: INVD/WBINVD supported
;;@CPUFET_INTEL  equ  mask $CPUFET_INTEL; 40000000: GenuineIntel CPU
;;;;;;;_RSV2   equ  mask $CPUFET_RSV2	; 30000000: (Reserved)
;;;;;;;_RSV2   equ  mask $CPUFET_SNOOP	; 08000000: Selfsnoop
@CPUFET_SSE2   equ  mask $CPUFET_SSE2	; 04000000: SSE2 instructions
@CPUFET_SSE    equ  mask $CPUFET_SSE	; 02000000: SSE, MXCSR, CR4, OSXMMEXCPT, #XF
@CPUFET_FXSR   equ  mask $CPUFET_FXSR	; 01000000: Fast FP Save/Restore
@CPUFET_MMX    equ  mask $CPUFET_MMX	; 00800000: MMX technology supported
@CPUFET_ACPI   equ  mask $CPUFET_ACPI	; 00400000: Processor Duty Cycle Ctl (ACPI)
@CPUFET_DBGTR  equ  mask $CPUFET_DBGTR	; 00200000: Debug Trace and EMON Store (DTES)
;;;;;;;_RSV1   equ  mask $CPUFET_RSV1	; 00100000: (Reserved)
@CPUFET_CLFLSH equ  mask $CPUFET_CLFLSH ; 00080000: Cache Line Flush instruction
@CPUFET_PSN    equ  mask $CPUFET_PSN	; 00040000: Processor Serial Number
@CPUFET_PSE36  equ  mask $CPUFET_PSE36	; 00020000: Page Size Extensions-36
@CPUFET_PAT    equ  mask $CPUFET_PAT	; 00010000: Page Attribute Table
@CPUFET_CMOV   equ  mask $CPUFET_CMOV	; 00008000: Conditional move supported
@CPUFET_MCA    equ  mask $CPUFET_MCA	; 00004000: Machine Check Architecture
@CPUFET_PGE    equ  mask $CPUFET_PGE	; 00002000: Global PTE bit (avoids TLB flush)
@CPUFET_MTRR   equ  mask $CPUFET_MTRR	; 00001000: Memory Type Range Register MSRs
@CPUFET_SEP    equ  mask $CPUFET_SEP	; 00000800: Fast System Call (was RDECR/WRECR)
@CPUFET_P54C_MP equ mask $CPUFET_P54C_MP ;00000400: P54C/CM/Multiprocessor/Overdrive
@CPUFET_APIC   equ  mask $CPUFET_APIC	; 00000200: On-chip APIC supported
@CPUFET_CMP8B  equ  mask $CPUFET_CMP8B	; 00000100: CMPXCHG8B
@CPUFET_MCE    equ  mask $CPUFET_MCE	; 00000080: Machine Check Exception
@CPUFET_PAE    equ  mask $CPUFET_PAE	; 00000040: Physical Address Extensions
@CPUFET_MSREG  equ  mask $CPUFET_MSREG	; 00000020: Model-specific registers ...
@CPUFET_TSCNT  equ  mask $CPUFET_TSCNT	; 00000010: Time Stamp counter ...
@CPUFET_4MBPG  equ  mask $CPUFET_4MBPG	; 00000008: 4MB page ...
@CPUFET_PSE    equ  @CPUFET_4MBPG	;	    Page Size Extensions
@CPUFET_IOBRK  equ  mask $CPUFET_IOBRK	; 00000004: I/O breakpoint ...
@CPUFET_VME    equ  mask $CPUFET_VME	; 00000002: V86 mode extensions ...
@CPUFET_NDPIN  equ  mask $CPUFET_NDPIN	; 00000001: NDP installed (not necessarily on chip
					; as the Pentium bit defines)
endif				; IF (@Cpu AND 1000b)
