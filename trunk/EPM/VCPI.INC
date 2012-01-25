;
; VCPI.INC
;
; VCPICALL macro and equates
;

@VCPI	    equ 0DEh		; Major function code

@VCPI_PRES  equ  00h		; Presence detection
@VCPI_GPMI  equ  01h		; Get protected mode interface
@VCPI_GMPA  equ  02h		; Get maximum physical address
@VCPI_GNFP  equ  03h		; Get # free 4KB pages
@VCPI_ALLOC equ  04h		; Allocate a 4KB page
@VCPI_FREE  equ  05h		; Free a 4KB page
@VCPI_L2P   equ  06h		; Linear to physical address mapping
@VCPI_GCR0  equ  07h		; Get CR0
@VCPI_GDRN  equ  08h		; Get DRn
@VCPI_SDRN  equ  09h		; Set DRn
@VCPI_GIBV  equ  0Ah		; Get Interrupt Base Values
@VCPI_SIBV  equ  0Bh		; Set ...
@VCPI_EPM   equ  0Ch		; Enter/exit protected mode

@VCPI_DPRES  equ 0F0h		; Debugger presence detection
@VCPI_DBGINF equ 0F1h		; Get debugger info
@VCPI_DBGINI equ 0F2h		; Initialize debugger interface
@VCPI_DBGIDT equ 0F3h		; Initialize debugger IDT entry
@VCPI_DBGLIN equ 0F4h		; Set new debugger linear address
@VCPI_DBGP2L equ 0F5h		; Translate physical to linear address
@VCPI_DBGSYM equ 0F6h		; Symbol Table Management with subfunctions
@DBGSYM_APPND equ 00h		; Append ECX names from DS:ESI
@DBGSYM_SRCH  equ 01h		; Search for name DS:ESI
@DBGSYM_TRANS equ 02h		; Translate old seg/sel CX, grp DX to ESI/EDI
@DBGSYM_FLUSH equ 03h		; Flush the symbol table
@DBGSYM_RAPPND equ 04h		; Append without replacing existing symbols
				; (allow duplicates of existing symbols)
@DBGSYM_COMMAND equ 05h 	; Execute ASCIIZ command at DS:ESI
@DBGSYM_LDISP equ 06h		; Copy ASCIIZ string at DS:ESI to error log

@VCPI_DBGHOST equ 0F7h		; Pass host features flags in BX
@HOSTFLAGS_DPMI equ	0001h	; Host supports DPMI services
@HOSTFLAGS_DPMI32 equ	0002h	; Host supports 32-bit DPMI clients

@VCPI_DBGWINVARS equ	0F8h	; Pass addresses of WIN386 internal variables
@DBGWINVARS_CURVM equ	01h	; CX:EDX = Address of Cur_VM_Handle
@DBGWINVARS_SYSVM equ	02h	; CX:EDX = Address of Sys_VM_Handle

@VCPI_FILLPTE equ 0F9h		; Fill in at most ECX PTEs into ES:DI
				; return # filled in ECX
@VCPI_XFERDATA equ 0FAh 	; Transfer data to SWAT
@XFER_WINTAB equ 0		; Data transfer is WINTAB


VCPICALL macro	 FUNC

ifnb	<FUNC>
	 mov	 al,FUNC	; Get subfunction
endif				; IFNB <FUNC>
	 mov	 ah,@VCPI	; VCPI major function
	 int	 67h		; Request VCPI service

	 endm			; VCPICALL


; VCPI Enter Protected Mode structure for DE0C VM to PM call

VCPEPM_STR struc

VCPEPM_CR3  dd	 ?		; 00-03:  New CR3
VCPEPM_GDTP dd	 ?		; 04-07:  Pointer to new GDTR base
VCPEPM_IDTP dd	 ?		; 08-0B:  Pointer to new IDTR base
VCPEPM_LDTR dw	 0		; 0C-0D:  New LDTR
VCPEPM_TR   dw	 ?		; 0E-0F:  New TR
VCPEPM_EXIT df	 ?		; 10-15:  CS:EIP of exit point

VCPEPM_STR ends


