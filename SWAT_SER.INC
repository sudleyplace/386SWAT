;' $Header:   P:/PVCS/386SWAT/SWAT_SER.INV   1.0   24 Sep 1992 07:34:50   HENRY  $
;
; (C) Copyright 1992 Qualitas, Inc.	All rights reserved.
;
; SWAT_SER.INC
;
; Equates and structures for remote debugging via serial ports
;

; Port base I/O addresses
@COM1BASE equ	 03F8h
@COM2BASE equ	 02F8h
@COM3BASE equ	 03E8h
@COM4BASE equ	 02E8h

; IRQ bits in IMR
IRQ_REC record $IRQ765:3,$COM13:1,$COM24:1,$IRQ210:3

; Register offsets (added to base address)
@TXR	 equ	 00h		; Transmit register (write only)
@RXR	 equ	 00h		; Receive register (read only)

@IER	 equ	 01h		; Interrupt enable register
IER_REC record $IER_RSVD:4,$IER_DELTA:1,$IER_ERR:1,$IER_THR_EMPTY:1,$IER_RX:1

@IIR	 equ	 02h		; Interrupt identification register
IIR_REC record $IIR_RSVD:5,$IIR_ID:2,$IIR_PENDING:1
@IIR_ERR equ	 03h		; BREAK or error (presented first)
@IIR_RX  equ	 02h		; Data received
@IIR_THR_EMPTY equ 01h		; Xmit holding buffer ready
@IIR_DELTA equ	 00h		; Change in MSR (presented last)

@LCR	 equ	 03h		; Line control register
LCR_REC record $LCR_DLATCH:1,$LCR_BREAK:1,$LCR_PSTICK:1,$LCR_PEVEN:1,\
	$LCR_PARITY:1,$LCR_STOP2:1,$LCR_BITS:2
@LCR_P8N1 equ	 (11b shl $LCR_BITS) ; LCR value for 8 bits, no parity, 1 stop

@MCR	 equ	 04h		; Modem control register
MCR_REC record $MCR_RSVD:3,$MCR_LOOPBK:1,$MCR_GP02:1,$MCR_GP01:1,\
	$MCR_RTSHIGH:1,$MCR_DTRHIGH:1
@MCR_EI equ	 (mask $MCR_GP02)

@LSR	 equ	 05h		; Line status register
LSR_REC record $LSR_TIMEOUT:1,$LSR_XMTEMPTY:1,$LSR_XMTREADY:1,$LSR_BREAK:1,\
	$LSR_FRAMERR:1,$LSR_PERR:1,$LSR_OVRERR:1,$LSR_RCVREADY:1

@MSR	 equ	 06h		; Modem status
MSR_REC record $MSR_DCD:1,$MSR_RI:1,$MSR_DSR:1,$MSR_CTS:1,\
	$MSR_DELTADCD:1,$MSR_DELTARI:1,$MSR_DELTADSR:1,$MSR_DELTACTS:1

@SRP	 equ	 07h		; Scratch pad register
@DLL	 equ	 00h		; Divisor latch - low
@DLH	 equ	 01h		; Divisor latch - high

@BAUD_DIVISOR equ 115200	; Divide by baud rate to obtain divisor latch

