	 NPPROC	 FCN_BROWSER -- BROWSER function
	 assume  ds:nothing,es:NGROUP,fs:DGROUP,gs:nothing,ss:nothing
COMMENT|

BROWSER function

User specifies browser buffer size in bytes.  Values less than
FBROWS_BUFLEN (@SYM_READBUFSIZ) are ignored.

On entry:

DS:SI	 ==>	 command line following keyword

On exit:

DS:SI	 ==>	 next character to scan

|

	 REGSAVE <eax,cx>	; Save

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_BROWSER_EQ ; Too bad

	 inc	 si		; Skip over the character

	 call	 SKIP_WHITE	; Skip over more white space

	 mov	 cx,10		; Use base 10 to convert
	 call	 FBASE2BIN	; Convert the number at DS:SI to binary in EAX
	 jc	 short FCN_BROWSER_OVF ; Jump if too large

	 cmp	 eax,FBROWS_BUFLEN ; Izit smaller than the static buffer?
	 jbe	 short @F	; Jump if so (ignore it)

	 mov	 FBROWS_BUFLEN,eax ; Save for later use
	 mov	 FBROWS_BUFP,0	; Indicate that we need to initialize it

	 clc			; Indicate all went well

	 jmp	 short FCN_BROWSER_EXIT ; Join common exit code

FCN_BROWSER_OVF:
	 mov	 si,LASTKEY	; Get offset of last keyword
	 lea	 di,MSG_OVF	; Pass address of error message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 jmp	 short FCN_BROWSER_ERR ; Join common error code

FCN_BROWSER_EQ:
	 push	 offset cs:MSG_SEP ; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we allow no mistakes
FCN_BROWSER_ERR:
	 stc			; Indicate there was a problem
FCN_BROWSER_EXIT:
	 REGREST <cx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_BROWSER endp		; End FCN_BROWSER procedure

