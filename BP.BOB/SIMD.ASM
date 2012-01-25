.686
.xmm

PGROUP	group	CODE,DATA

DATA	segment use16 public 'data'
	assume	ds:PGROUP

Q0	dq	1
Q1	dq	2
Q2	dq	3
Q3	dq	4
Q4	dq	5
Q5	dq	6
Q6	dq	7
Q7	dq	8

Q00	dq	11
Q10	dq	12
Q20	dq	13
Q30	dq	14
Q40	dq	15
Q50	dq	16
Q60	dq	17
Q70	dq	18

DATA	ends


CODE	segment use16 public 'code'
	assume	cs:PGROUP

	public	INIT
INIT:
	mov	ax,seg PGROUP
	mov	ds,ax
	assume	ds:PGROUP	; Tell the assembler about it

MOVQ	    mm0,Q0
MOVQ	    mm1,Q1
MOVQ	    mm2,Q2
MOVQ	    mm3,Q3
MOVQ	    mm4,Q4
MOVQ	    mm5,Q5
MOVQ	    mm6,Q6
MOVQ	    mm7,Q7

MOVQ	    xmm0,Q00
MOVQ	    xmm1,Q10
MOVQ	    xmm2,Q20
MOVQ	    xmm3,Q30
MOVQ	    xmm4,Q40
MOVQ	    xmm5,Q50
MOVQ	    xmm6,Q60
MOVQ	    xmm7,Q70

MOVDQ2Q     mm3 ,xmm4	; 11 xmm  mm	  11 mm   xmm

MOVQ2DQ     xmm4,mm3	; 11 xmm  mm	  11 mm   xmm

MOVDQ2Q     xmm3 ,mm4	; 11 xmm  mm	  11 mm   xmm

MOVQ2DQ     mm4,xmm3	; 11 xmm  mm	  11 mm   xmm

	mov	ah,4Ch
	int	21h

CODE	ends

	end	INIT
