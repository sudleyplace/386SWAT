;
; MASM.INC
;
; MASM Macros
;

	 if1
REGSAVE  macro	 LIST		; Register save macro

	 irp	 XX,<LIST>
	 push	 XX
	 endm

	 endm			; REGSAVE


REGREST  macro	 LIST		; Register restore macro

	 irp	 XX,<LIST>
	 pop	 XX
	 endm

	 endm			; REGREST


NPROC	 macro	 @PROC,@T1,@T2,@T3,@T4,@T5,@T6,@T7,@T8,@T9,@T10
	 subttl  @PROC Procedure @T1 @T2 @T3 @T4 @T5 @T6 @T7 @T8 @T9 @T10
	 page
@PROC	 proc	 near
	 endm			; NPROC


PPROC	 macro	 @PROC,@T1,@T2,@T3,@T4,@T5,@T6,@T7,@T8,@T9,@T10
	 subttl  @PROC Procedure @T1 @T2 @T3 @T4 @T5 @T6 @T7 @T8 @T9 @T10
	 page
	 public  @PROC
@PROC	 proc
	 endm			; PPROC


NPPROC	 macro	 @PROC,@T1,@T2,@T3,@T4,@T5,@T6,@T7,@T8,@T9,@T10
	 subttl  @PROC Procedure @T1 @T2 @T3 @T4 @T5 @T6 @T7 @T8 @T9 @T10
	 page
	 public  @PROC
@PROC	 proc	 near
	 endm			; NPPROC


NPPROCE  macro	 @PROC,@T1,@T2,@T3,@T4,@T5,@T6,@T7,@T8,@T9,@T10
	 subttl  @PROC Procedure @T1 @T2 @T3 @T4 @T5 @T6 @T7 @T8 @T9 @T10
	 page
	 even
	 public  @PROC
@PROC	 proc	 near
	 endm			; NPPROCE


FPROC	 macro	 @PROC,@T1,@T2,@T3,@T4,@T5,@T6,@T7,@T8,@T9,@T10
	 subttl  @PROC Procedure @T1 @T2 @T3 @T4 @T5 @T6 @T7 @T8 @T9 @T10
	 page
@PROC	 proc	 far
	 endm			; FPROC


FPPROC	 macro	 @PROC,@T1,@T2,@T3,@T4,@T5,@T6,@T7,@T8,@T9,@T10
	 subttl  @PROC Procedure @T1 @T2 @T3 @T4 @T5 @T6 @T7 @T8 @T9 @T10
	 page
	 public  @PROC
@PROC	 proc	 far
	 endm			; FPPROC


MEND	 macro	 @START

	 if1
%OUT Pass 1 complete
	 else
%OUT Pass 2 complete
	 endif

	 end	 @START

	 endm			; MEND


FCALL	 macro	 NAME

	 push	 cs
	 call	 near ptr NAME

	 endm			; FCALL

	 endif			; IF1 ******************************

