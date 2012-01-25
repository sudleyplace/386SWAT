
;*********************** INTEL CONFIDENTIAL **************************
; Check for A1 step SL Enhanced 486 CPUs with feature bits.  Note that
; the stepping information in the following comments is under Intel NDA.

	test	edx,@CPUFET_VME ; Any Virtual Mode Extensions supported?
	jz	short CHECK_P5_VMEOK ; Jump if not

; The A1 step says it supports VME, but has some serious bugs which may
; cause misdirection of some interrupts.  Later steppings also have this
; bug, but correctly say they don't support VME.

	mov	ebx,CPUSIG	; Copy stepping info
	and	ebx,@CPUSIG_FAM or @CPUSIG_MOD or @CPUSIG_REV ; Isolate family,
				; model, and stepping in BX
	cmp	bx,0414h	; Izit S series 486DX, A1 step?
	je	short @F	; Jump if so

	cmp	bx,0424h	; Izit S series 486SX, A1 step?
	je	short @F	; Jump if so

	cmp	bx,0434h	; Izit S series 486DX-2, A1 step?
	jne	short CHECK_P5_VMEOK ; Jump if not
@@:
	and	edx,not @CPUFET_VME ; Don't enable Virtual Mode Extensions
CHECK_P5_VMEOK:
;************************ END INTEL CONFIDENTIAL **********************
