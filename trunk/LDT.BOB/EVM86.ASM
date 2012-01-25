; Enter VM code from comp.lang.asm.x86 message
; Sat, 11 May 2002 18:56:05

org 100h

; Some selectors in our GDT...
%define CODE16_SEL 08h
%define CODE32_SEL 10h
%define DATA32_SEL 18h
%define CORE32_SEL 20h
%define TSS32_SEL 28h


	smsw	ax
	test	al, 1
	jz		really_mode
	mov	ah, 9
	mov	dx, protmode_msg
	int	21h
	ret

protmode_msg:
	db 'CPU is already in V86 mode.',13,10,'$'

really_mode:
	mov	eax, 1
	cpuid
	test	edx, 2
	jnz	near have_pentium
	mov	ah, 9
	mov	dx, vme_msg
	int	21h
	ret

vme_msg:
	db 'Pentium class CPU with Virtual Mode Extensions required.',13,10,'$'

copyright:
	db 'V86 monitor for DOS, (C) 2002. NO WARRANTY',13,10,'$'

have_pentium:
	mov	ah, 9
	mov	dx, copyright
	int	21h

	mov	[realmode_cs], cs	 ; Needed for V86 switch

; Patch GDT
	mov	ax, cs
	movzx	eax, ax
	shl	eax, 4	 ; Make linear address
	mov	ebx, eax
	add	ebx, tss ; Accommodate for TSS base
	mov	[gdt.code16+2], ax
	mov	[gdt.code32+2], ax
	mov	[gdt.data32+2], ax
	mov	[gdt.tss32+2], bx
	shr	eax, 16
	shr	ebx, 16
	mov	[gdt.code16+4], al
	mov	[gdt.code32+4], al
	mov	[gdt.data32+4], al
	mov	[gdt.tss32+4], bl

	call	relocate_irqs  ; Only master PIC is reprogrammed, because slave
						   ; does not overlap exceptions

; Patch DTRs
	mov	ax, cs
	movzx	eax, ax
	shl	eax, 4	 ; Make linear address
	mov	ebx, eax
	add	ebx, gdt
	mov	[gdtr.base], ebx
	add	eax, idt
	mov	[idtr.base], eax

	call	InitSWAT	; Initialize 386SWAT

; Switch to PM
	cli
	lidt	[idtr]
	lgdt	[gdtr]
	mov	eax, cr0
	and	eax, 7FFFFFF0h	; Clear PG, MP, TS, EM
	or		al, 1			; Set PE
	mov	cr0, eax
	jmp	CODE32_SEL:start32

bits 32

start32:
; Load segment regs.
	mov	ax, DATA32_SEL
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	gs, ax

; Setup stack
	mov	ss, ax
	mov	esp, stack_end
	and	esp, ~3 		 ; dword alignment
	mov	[tss.esp0], esp  ; Patch TSS

; Setup LDT
	xor	ax, ax
	lldt	ax		  ; We don't use the LDT

; Enable VME
	mov	eax, cr4
	or	al, 2
	mov	cr4, eax

; Setup our task
	mov	ax, TSS32_SEL
	ltr	ax
	clts		  ; I don't want excp 7 in any case

; Exceptions do work. Try this here:
;	 ud2
; Or this:
;	 xor eax, eax
;	 div eax

; Prepare for V86
	movzx	eax, word [realmode_cs]
	push	eax		  ; GS
	push	eax		  ; FS
	push	eax		  ; DS
	push	eax		  ; ES
	push	eax		  ; SS
	push	dword 0FFFEh  ; ESP (same as during our .COM program start)
	pushfd
	pop	ebx		  ; flags = 1X X011 XX0X XXXX XXXX
	or		ebx, 23000h   ; Turn on VM flag and set IOPL to 3
	and	ebx, ~04200h	; Make sure NT and IF are clear
	push	ebx				 ; EFLAGS
	push	dword [realmode_cs]  ; CS + 16bits of garbage
	push	dword v86_entry 	 ; EIP
	iretd						 ; "return" to V86 mode

bits 16

v86_entry:	 ; We're in V86 mode! Print a message and wait for reset
	mov	ax, 0B805h
	mov	es, ax
	xor	di, di
	mov	ah, 1Eh
	mov	si, .msg
.loop:
	lodsb
	test	al, al
	jz		.done
	stosw
	jmp	short .loop
.done:
	jmp	short $ 	   ; Hang until reset
	.msg:	db 'Look ma, I',39,'m running in V86 mode!',0


; Reprograms master PIC to int 50h-57h
relocate_irqs:
	mov	al, 1Dh
	out	20h, al
	mov	al, 50h
	out	21h, al
	mov	al, 4
	out	21h, al
	mov	al, 1Dh
	out	21h, al
	ret

InitSWAT:
	mov	ax,0DEF0h	; Check for presence
	int	67h		; Request SWAT services

	cmp	ah,0		; Izit present?
	jne	short InitSWAT_Exit ; Jump if not

	mov	ax,0DEF2h	; Initialize GDT
	mov	di,swat32	; ES:DI ==> GDT
	mov	bx,swat32-gdt	; BX = 1st selector
	int	67h		; Request SWAT services

	mov	ax,0DEF3h	; Initialize IDT
	mov	bx,01h		; INT 01h
	mov	di,idt+8*01h	; ES:DI ==> IDT entry
	int	67h		; Request SWAT services

	mov	ax,0DEF3h	; Initialize IDT
	mov	bx,03h		; INT 03h
	mov	di,idt+8*03h	; ES:DI ==> IDT entry
	int	67h		; Request SWAT services

	mov	ax,0DEF3h	; Initialize IDT
	mov	bx,0Ah		; INT 0Ah
	mov	di,idt+8*0Ah	; ES:DI ==> IDT entry
	int	67h		; Request SWAT services

	mov	ax,0DEF3h	; Initialize IDT
	mov	bx,0Dh		; INT 0Dh
	mov	di,idt+8*0Dh	; ES:DI ==> IDT entry
	int	67h		; Request SWAT services

	mov	ax,0DE0Bh	; Tell SWAT about relocated IRQs
	mov	bl,50h		; Master PIC base
	mov	cl,70h		; Slave ...
	int	67h		; Request SWAT services
InitSWAT_Exit:
	ret



; The GDT

; Patch: selector+2=word base low, +4=byte base middle, +7=byte base high
; base high need not be patched, we run from conventional memory.
gdt:
.null:		dd 0, 0
.code16:	dw 0FFFFh, 0	   ; Executable ExpandUp PageGranular Readable
			db 0, 9Ah, 08Fh, 0 ; 16bit NonConforming
.code32:	dw 0FFFFh, 0
			db 0, 9Ah, 0CFh, 0 ; Same, but 32-bit
.data32:	dw 0FFFFh, 0
			db 0, 92h, 0CFh, 0 ; NonExecutable Writeable 32bit
.core32:	dw 0FFFFh, 0
			db 0, 92h, 0CFh, 0 ; Static data desc for all memory from base 0
.tss32: 	dw (tss_end-tss)-1, 0
			db 0, 89h, 0, 0    ; TSS, 32-bit, byte granular, available
swat32: 	dd 0,0		; How does NASM do   dq 30 dup (0)  ?
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0

gdtr:
.limit: dw $-gdt
.base:	dd 0   ; Patched


; The IDT

idt:
.divby0:	dw divby0, CODE32_SEL
			db 0, 08Eh, 0, 0   ; Int gate, 32-bit, 0 words, DPL 0
.sstep: 	dd 0, 0
.nmi:		dw nmi, CODE32_SEL
			db 0, 08Eh, 0, 0
.brk:		dw brk, CODE32_SEL
			db 0, 08Eh, 0, 0
.overflow:	dd 0, 0
.bound: 	dd 0, 0
.invop: 	dw invop, CODE32_SEL
			db 0, 08Eh, 0, 0
.copro: 	dd 0, 0
.double:	dd 0, 0
.coproseg:	dd 0, 0
.invtss:	dw invtss, CODE32_SEL
			db 0, 08Eh, 0, 0
.segpres:	dd 0, 0
.stkfault:	dd 0, 0
.gpfault:	dw gpfault, CODE32_SEL
			db 0, 08Eh, 0, 0
times 60*8 db 0  ; Fill unused until relocated irq's
.irq0:		dw irq0, CODE32_SEL
			db 0, 08Eh, 0, 0
.irq1:		dw irq1, CODE32_SEL
			db 0, 08Eh, 0, 0
.irq2:		dw irq2, CODE32_SEL
			db 0, 08Eh, 0, 0
.irq3:		dw irq3, CODE32_SEL
			db 0, 08Eh, 0, 0
.irq4:		dw irq4, CODE32_SEL
			db 0, 08Eh, 0, 0
.irq5:		dw irq5, CODE32_SEL
			db 0, 08Eh, 0, 0
.irq6:		dw irq6, CODE32_SEL
			db 0, 08Eh, 0, 0
.irq7:		dw irq7, CODE32_SEL
			db 0, 08Eh, 0, 0
times 24*8 db 0   ; Fill until nonrelocated slave irq's
.irq8:		dw irq8, CODE32_SEL
			db 0, 08Eh, 0, 0
.irq9:		dw irq9, CODE32_SEL
			db 0, 08Eh, 0, 0
.irq10: 	dw irq10, CODE32_SEL
			db 0, 08Eh, 0, 0
.irq11: 	dw irq11, CODE32_SEL
			db 0, 08Eh, 0, 0
.irq12: 	dw irq12, CODE32_SEL
			db 0, 08Eh, 0, 0
.irq13: 	dw irq13, CODE32_SEL
			db 0, 08Eh, 0, 0
.irq14: 	dw irq14, CODE32_SEL
			db 0, 08Eh, 0, 0
.irq15: 	dw irq15, CODE32_SEL
			db 0, 08Eh, 0, 0

idtr:
.limit: dw $-idt
.base:	dd 0   ; Patched

realmode_cs: dw 0

bits 32

; Exception handling
divby0:
	mov	esi, .msg
	jmp	fatal_exception_tail
	.msg:	db 'Divide overflow',0
nmi:
	mov	esi, .msg
	jmp	fatal_exception_tail
	.msg:	db 'Non-maskable interrupt',0
brk:
	mov	esi, .msg
	jmp	fatal_exception_tail
	.msg:	db 'Breakpoint',0
invop:
	mov	esi, .msg
	jmp	fatal_exception_tail
	.msg:	db 'Invalid opcode',0
invtss:
	mov	esi, .msg
	jmp	fatal_exception_tail
	.msg:	db 'Invalid TSS',0
fatal_exception_tail:
	mov	ax, DATA32_SEL
	mov	ds, ax
	call	print32
.hang:
	hlt
	jmp	short .hang

; IRQ redirectors. TODO
irq0:
irq1:
irq2:
irq3:
irq4:
irq5:
irq6:
irq7:
irq8:
irq9:
irq10:
irq11:
irq12:
irq13:
irq14:
irq15:


; Prints a message to top left corner of display. ESI=ASCIIZ.
print32:
	mov	ax, CORE32_SEL
	mov	gs, ax
	mov	edi, 0B8000h
	mov	ah, 0CFh	 ; Blinking bright white on red
.loop:
	lodsb
	test	al, al
	jz		.done
	mov	[gs:edi], ax
	add	edi, byte 2
	jmp	short .loop
.done:
	ret


; Handle VM faults. TODO
gpfault:
	pushad			 ; there's an error code too...
	mov	esi, .msg
	jmp	fatal_exception_tail
	popad
	iret
	.msg:	db 'General Protection Fault',0




; The TSS
; PL0 stack pointer is patched. The rest shouldn't matter. I/O permission
; bitmap is static.
tss:
.prev:	dd 0
.esp0:	dd 0  ; Patched
.ss0:	dd DATA32_SEL
.esp1:	dd 0
.ss1:	dd 0
.esp2:	dd 0
.ss2:	dd 0
.cr3:	dd 0
.eip:	dd 0
.flags: dd 0
.eax:	dd 0
.ecx:	dd 0
.edx:	dd 0
.ebx:	dd 0
.esp:	dd 0
.ebp:	dd 0
.esi:	dd 0
.edi:	dd 0
.es:	dd 0
.cs:	dd 0
.ss:	dd 0
.ds:	dd 0
.fs:	dd 0
.gs:	dd 0
.ldt:	dd 0
.tf:	dw 0
.iobp:	dw tss.iomap-tss	; I/O map base pointer
.redir: times 32 db 0		; VME-specific
.iomap: times 5 db 0
		db 0Ch	  ; Ports 42h, 43h
		db 0
		db 20h	  ; Port 61h
		times 120 db 0		; Up to 3FFh ports
		db 0FFh
tss_end:

; Protected mode and fault handler stack
stack:
	times 63 db 'STACK32!'
stack_end:
	db 'STACK32!'

