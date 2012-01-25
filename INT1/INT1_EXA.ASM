;' $Header:   P:/PVCS/386SWAT/INT1/INT1_EXA.ASV   1.2   01 Jul 1997 17:55:54   BOB  $
	 title	 INT1_EXA -- INT 01h Example Instructions
	 page	 58,122
	 name	 INT1_EXA

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  See SWAT_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, April, 1988.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
.list

PGROUP	 group	 PROG
DGROUP	 group	 NDATA


NDATA	 segment use16 word public 'data' ; Start NDATA segment
	 assume  ds:DGROUP

DATA1	 dw	 ?

NDATA	 ends			; End NDATA segment


PROG	 segment use16 byte public 'prog' ; Start PROG segment
	 assume  cs:PGROUP

	 NPPROC  EXAMPLES -- Sample Instructions
	 assume  ds:DGROUP,es:DGROUP

	 db	 0Fh,0AAh	; RSM in 386 SL

	 int	 67h
	 int	 20h
	 dw	 0000h,0001h
	 int	 20h
	 dw	 0001h,0001h
	 int	 20h
	 dw	 0012h,0001h

    lock xchg	 ax,ds:[0]
    lock xchg	 eax,ds:[eax+ebx*8+012345678h]

	 fnstsw  word ptr fs:[1234h]
	 fstsw	 word ptr fs:[1234h]

	 call	 EXAMPLES
	 calld	 EXAMPLES

	 mov	 al,ds:[1234h]
	 mov	 ax,ds:[1234h]
	 mov	 eax,ds:[1234h]

	 mov	 al,ds:[12345678h]
	 mov	 ax,ds:[12345678h]
	 mov	 eax,ds:[12345678h]

	 fld1
	 fprem
	 fprem1
	 fstp	 st(0)

	 jz	 near ptr FOO1
	 jz	 short EXAMPLES
FOO1:
	 jcxz	 FOO1
	 jecxz	 FOO1

	 xchg	 eax,eax

	 db	 66h
	 lldt	 ax
;;;;;;;; lldt	 eax

	 db	 66h
	 lmsw	 ax
;;;;;;;; lmsw	 eax

	 db	 66h
	 mov	 eax,cr0
	 mov	 eax,cr0
;;;;;;;; mov	 [bx+si],cr0
	 db	 0Fh,20h,00h	; MOV  [BX+SI],CR0

	 mov	 eax,cr3
;;;;;;;; mov	 [bx+si],cr3
	 db	 0Fh,20h,18h	; MOV  [BX+SI],CR3

	 pop	 [esp+6].ELO

	 mov	 gs,ds:[1234h]

	 add	 ds:[esi+1234h].EDD,1

	 lea	 eax,DATA1
	 lea	 eax,dword ptr DATA1
	 lea	 eax,ds:[12345678h]
	 lea	 eax,[esp+edx*4+12345678h]

	 bt	 cs:[1234h+ebx*4],dx
	 bt	 cs:[1234h+ebx*4+esp],dx

	 ret
	 db	 66h
	 ret
	 retf

	 ret	 2
	 db	 66h
	 ret	 3
	 retf	 4

	 iret
	 iretd

     rep movs	 es:[edi].EDD,ds:[esi].EDD

	 mov	 ds:[1234h],eax

	 stos	 es:[di].LO
	 stos	 es:[di].ELO
	 stos	 es:[di].EDD
	 stos	 es:[edi].LO
	 stos	 es:[edi].ELO
	 stos	 es:[edi].EDD

	 lods	 fs:[si].LO
	 lods	 fs:[si].ELO
	 lods	 fs:[si].EDD
	 lods	 fs:[esi].LO
	 lods	 fs:[esi].ELO
	 lods	 fs:[esi].EDD

	 mov	 al,[ebp]
	 mov	 al,[ebp+12345678h]

	 mov	 al,[ebp+eax*1]
	 mov	 al,[ebp+eax*1+1]
	 mov	 al,[ebp+eax*1+12345678h]
	 mov	 al,[ebp+eax*2]
	 mov	 al,[ebp+eax*2+1]
	 mov	 al,[ebp+eax*2+12345678h]
	 mov	 al,[ebp+eax*4]
	 mov	 al,[ebp+eax*4+1]
	 mov	 al,[ebp+eax*4+12345678h]
	 mov	 al,[ebp+eax*8]
	 mov	 al,[ebp+eax*8+1]
	 mov	 al,[ebp+eax*8+12345678h]

	 movzx	 eax,byte ptr fs:[0FFFFh]
	 movzx	 eax,word ptr gs:[0FFFEh]
	 movzx	  ax,byte ptr ss:[0FFFDh]

	 movsx	 eax,byte ptr fs:[0FFFFh]
	 movsx	 eax,word ptr gs:[0FFFEh]
	 movsx	  ax,byte ptr ss:[0FFFDh]

	 mov	 eax,fs:[00003210h]
	 mov	 eax,gs:[76543210h]

	 shr	 esp,cl
	 shr	 esp,1
	 shr	 esp,2

	 shr	 dword ptr fs:[123h],cl
	 shr	 dword ptr gs:[123h],1
	 shr	 dword ptr ss:[123h],2

	 mov	 eax,ds:[123h]
	 push	 word ptr ds:[45h]
	 push	 dword ptr ds:[45h]
	 push	 80h
	 push	 8000h
	 push	 dword ptr 80000000h
	 push	 dword ptr 0
	 push	 dword ptr 7Fh
	 push	 dword ptr -1

	 xor	 eax,eax
	 mov	 cr3,eax

	 db	 0D6h		; SALC				8088

	 db	 0Fh,01h,38h	; INVLPG Word ptr [BX+SI]	486
	 db	 0Fh,05h	; LOADALL			286
	 db	 0Fh,06h	; CLTS				286
	 db	 0Fh,07h	; LOADALLD			386
	 db	 0Fh,08h	; INVD				486
	 db	 0Fh,09h	; WBINVD			486
	 db	 0Fh,10h,08h	; MOV	[BX+SI],CL		386
	 db	 0Fh,11h,08h	; MOV	CX,[BX+SI]		386
	 db	 0Fh,12h,08h	; MOV	CL,[BX+SI]		386
	 db	 0Fh,13h,08h	; MOV	[BX+SI],CX		386
	 db	 0Fh,0C8h	; BSWAP AX			486
	 db	 66h,0Fh,0C8h	; BSWAP EAX			486
	 db	 0Fh,0C0h,00h	; XADD	[BX+SI],AL		486
	 db	 0Fh,0C1h,00h	; XADD	[BX+SI],AX		486

	 fnstsw  ax
	 fstsw	 ax

	 fnstsw  word ptr fs:[1234h]
	 fstsw	 word ptr fs:[1234h]

	 finit
	 fninit

	 fadd	 st,st(4)
	 db	 09Bh
	 fadd	 st,st(4)

	 call	 dword ptr [bx]
	 call	 fword ptr [bx]
	 jmp	 dword ptr [bx]
	 jmp	 fword ptr [bx]

	 add	 al,4
	 add	 ax,4
	 add	 eax,4
	 add	 eax,88888888h
	 add	 eax,00001000h
	 add	 esi,00001000h
	 add	 al,[bx+si-9]
	 add	 [bx+si-9],al
	 add	 [ebx-8],al
	 add	 [ebx+ebp*8-8],al
	 add	 fs:[ebx+ebp*8	],al
	 add	    [	 ebp*8-8],al
	 add	    [	 ebp*8	],al
	 add	 gs:[eax+ebp*8-8].EDD,88888888h
	 add	 gs:[eax+ebp*8+98765432h].EDD,87654321h
	 add	 gs:[	 ebp*8+98765432h].EDD,87654321h

	 mov	 gs,sp
	 db	 082h
	 db	 0D6h
	 db	 0F1h
	 lods	 dword ptr ss:[esi]

	 bound	 eax,qword ptr gs:[eax+ebp*8+98765432h]

	 imul	 edi,gs:[eax+ebp*8+98765432h].EDD,87654321h

	 db	 66h
	 lgdt	 fword ptr gs:[1234h]
	 lidt	 fword ptr gs:[1234h]

	 fadd	 dword ptr gs:[0h]
	 fmul	 dword ptr gs:[1h]
	 fcom	 dword ptr gs:[2h]
	 fcomp	 dword ptr gs:[3h]
	 fsub	 dword ptr gs:[4h]
	 fsubr	 dword ptr gs:[5h]
	 fdiv	 dword ptr gs:[6h]
	 fdivr	 dword ptr gs:[7h]
	 fadd	 st,st(0)
	 fmul	 st,st(1)
	 fcom	 st(2)
	 fcomp	 st(3)
	 fsub	 st,st(4)
	 fsubr	 st,st(5)
	 fdiv	 st,st(6)
	 fdivr	 st,st(7)

	 db	 66h
	 fldenv  gs:[ebx+7890h]
	 fldenv  gs:[ebx+7890h]

	 assume  ds:nothing,es:nothing

EXAMPLES endp			; End EXAMPLES procedure

PROG	 ends			; End PROG segment

	 MEND			; End INT1_EXA module
