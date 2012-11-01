;' $Header$

; Define equates for INT 68h calls

@I68_IDENTIFY	equ 43h 	; Identify if debugger present
@I68_PREPARE_PM equ 44h 	; Prepare for entering PM
@I68_RM_INIT	equ 45h 	; Re-initialize from RM after entering PM
@I68_SET_SW	equ 46h 	; Set debugging information
@I68_EXEC_COND	equ 47h 	; Execute conditional breakpoint
@I68_FREE_SEG	equ 48h 	; Undefine RM segment symbols
@I68_SET_BAUD	equ 49h 	; Set COM port baud rate
@I68_REINIT	equ 4Ah 	; Re-initialize for PM
@I68_DEF_DSEGS	equ 4Bh 	; Define debugger's segments
@I68_SET_PORT	equ 4Ch 	; Set COM port number
@I68_LINK_SYM	equ 4Dh 	; Link .SYM file map
@I68_UNLINK_SYM equ 4Eh 	; Unlink .SYM file maps
@I68_REM_SEGS	equ 4Fh 	; Remove undefined segments
@I68_LOAD_SEG	equ 50h 	; Define segment/selector
@I68_DISP_CHAR	equ 51h 	; Display a char
@I68_DISP_STR	equ 52h 	; Display a string
@I68_QUERY_VXD	equ 53h 	; Query debug VxD installed
@I68_SET_VXD	equ 54h 	; Set debug VxD installed
@I68_REG_DOT	equ 55h 	; Register a dot command
@I68_UNREG_DOT	equ 56h 	; De-register a dot command
@I68_PRINTF	equ 57h 	; Printf
@I68_LINK_SYM_P equ 58h 	; Link symbol file w/physical address
@I68_CHECKMAP	equ 59h 	; Check for a map file
@I68_SET_AUTOLD equ 5Ah 	; Set/clear to autoload symbols
@I68_SET_TEFTI	equ 5Bh 	; Set TEFTI port address
@I68_EXEC_CMD	equ 5Ch 	; Execute command script
@I68_LOAD_HIGH	equ 5Dh 	; Load debugger code/data high
@I68_SET_WINVER equ 5Eh 	; Set Windows version #
@I68_SCAN_CHAR	equ 5Fh 	; Scan for a character
@I68_UNGET_CHAR equ 60h 	; Unget a scanned character
@I68_STOP	equ 61h 	; Stop at an address


; Define equates for INT 68h Load Segment types

@ST_code_sel	equ 0		; code selector
@ST_data_sel	equ 1		; data ...
@ST_code_seg	equ 10h 	; code segment
@ST_data_seg	equ 11h 	; data ...
@ST_dual_code	equ 40h 	; code segment and selector
@ST_dual_data	equ 41h 	; data ...
@ST_device_code equ 80h 	; device driver code segment
@ST_device_data equ 81h 	; ...		data ...
@ST_VxD_RM_seg	equ 90h 	; VxD real mode segment


; Define structure to map WKD Load Segment symbols

WKDLS_STR struc

WKDLS_LSEG dw	?		; 00:  Logical segment #
WKDLS_SEL  dw	?		; 02:  Actual selector (or segment if @WKDLS_RM)
WKDLS_BASE dd	?		; 04:  Base linear address
WKDLS_LEN  dd	?		; 08:  Length in bytes
WKDLS_ALIAS dw	?		; 0C:  Alias selector (if any)
WKDLS_FLAG dw	?		; 0E:  Flags (see @WKDLS_xxx below)
WKDLS_DNAME db	8 dup (?)	; 10:  Device name
WKDLS_SNAME db	8 dup (?)	; 18:  Symbolic name

WKDLS_STR ends

WKDLS_REC record $WKDLS_TYPE:8,$WKDLS_RSVD:6,$WKDLS_RM:1,$WKDLS_CODE:1
;WKDLS_TYPE = @ST_xxxx
@WKDLS_RM   equ (mask $WKDLS_RM)   ; Value in WKDLS_SEL is RM
@WKDLS_DATA equ 0		   ; Symbol is data, not code
@WKDLS_CODE equ (mask $WKDLS_CODE) ; Symbol is code, not data


; Define equates for PMINIT calls

@PMINIT_INIT_IDT	      equ 0 ; Initialize the IDT
@PMINIT_INIT_PAGING	      equ 1 ; Initialize for paging
@PMINIT_ENABLE_DEBUG_QUERIES  equ 2 ; Enables dot commands
@PMINIT_INIT_SPARE_PTE	      equ 3 ; Initialize the spare PTE
@PMINIT_SET_ENTER_EXIT_VMM    equ 4 ; Set enter/exit VMM addresses
@PMINIT_GET_SIZE_PHYS	      equ 5 ; Get debugger size/phys address
@PMINIT_SET_BASE_SPARE_PTE    equ 6 ; Set debugger base & spare PTE
@PMINIT_ENABLE_MEMORY_CONTEXT equ 7 ; Enable memory context fns


; Define equates for INT 41h calls

@DEB_PRESENT	equ 0F386h	; Debugger present return result

@I41_OUT_CHAR	equ  0000h	; Display a character
@I41_IN_CHAR	equ  0001h	; Get a character
@I41_OUT_STR	equ  0002h	; Display a 32-bit string
@I41_SCAN_CHAR	equ  0003h	; Scan for a character

@I41_NEWTASK	equ  000Bh	; Used by RegisterPTrace
@I41_FLUSHTASK	equ  000Ch	; ...
@I41_SWITCHOUT	equ  000Dh	; ...
@I41_SWITCHIN	equ  000Eh	; ...
@I41_OUT_SYMB	equ  000Fh	; Find symbol nearest to an address
@I41_DISASM	equ  0010h	; Disassemble an instruction

@I41_OUT_STR16	equ  0012h	; Display a 16-bit string

@I41_INTRINGS	equ  0020h	; Set which rings to trap
@I41_INCLUDESEG equ  0021h	; Handle BPs in this segment

@I41_GO16	equ  0040h	; Goto a specified address

@I41_LINKMAP	equ  0045h	; Link a map
@I41_UNLINKMAP	equ  0046h	; Unlink a map
@I41_CHECKMAP	equ  0047h	; Check a map
@I41_ISAUTOLOAD equ  0048h	; Query autoload symbols

@I41_DEBLOADED	equ  004Fh	; Is debugger loaded?
@I41_LOADSEG16	equ  0050h	; Load a 16-bit segment
@I41_MOVESEG	equ  0051h	; Move a segment
@I41_FREESEG16	equ  0052h	; Free a 16-bit segment

@I41_DGH	equ  0056h	; Dump global heap
@I41_DFL	equ  0057h	; Dump free list
@I41_DLL	equ  0058h	; Dump LRU list
@I41_STARTTASK	equ  0059h	; Start a task
@I41_KERNEL_VAR equ  005Ah	; Set kernel variables (see KVARS_STR below)
@I41_VCPI_NOTE	equ  005Bh	; VCPI notify
@I41_RELSEG	equ  005Ch	; Release a segment
@I41_USER_VARS	equ  005Dh	; Set User vars (see UVARS_STR below)

@I41_POSTLOAD	equ  0060h	; Used by RegisterPTrace

@I41_EXITCALL	equ  0062h	; Task has made exit call, AL = exit code
@I41_INT2	equ  0063h	; ???
@I41_LOADDLL	equ  0064h	; Load DLL:  CX:BX = CS:IP, ES:0 ==> header, ...
@I41_DELMOD	equ  0065h	; Delete module, ES = module handle
@I41_LOGERROR	equ  0066h	; Log an error
@I41_PARAMERR	equ  0067h	; Parameter error

@I41_REG_DOT32	equ  0070h	; Register a 32-bit dot command
@I41_REG_DOT16	equ  0071h	; Register a 16-bit dot command
@I41_UNREG_DOT	equ  0072h	; Unregister a dot command
@I41_PRINTF32	equ  0073h	; Printf for 32-bit args
@I41_PRINTF16	equ  0074h	; Printf for 16-bit args
@I41_GET_REGS	equ  0075h	; Get a register set
@I41_SET_ALTREG equ  0076h	; Set alternate register set
@I41_GETCMDCHAR equ  0077h	; Get a character from command line
@I41_EVAL_EXPR	equ  0078h	; Evaluate an expression
@I41_VER_MEM	equ  0079h	; Verify memory
@I41_PRINT_REG	equ  007Ah	; Print registers
@I41_PRINT_STK	equ  007Bh	; Print stack dump
@I41_SET_THREAD equ  007Ch	; Set a thread ID
@I41_EXEC_CMD	equ  007Dh	; Execute a debug command
@I41_GET_DBGINF equ  007Eh	; Get debugger info
@I41_CHECKFAULT equ  007Fh	; Check on a fault
@I41_SET_BREAK	equ  0080h	; Set Ctrl-C handler
@I41_REDIRECT	equ  0081h	; Redirect I/O to buffers
@I41_PASS_DOT	equ  0082h	; Pass on this dot command
@I41_TRAPFAULT	equ  0083h	; Trap fault
@I41_SET_STK_CB equ  0084h	; Set stack trace callback
@I41_REM_SEGS	equ  0085h	; Remnove undefined groups from a map file
@I41_DEF_DSEGS	equ  0086h	; Define debugger segments
@I41_SET_BAUD	equ  0087h	; Set COM port baud rate
@I41_SET_PORT	equ  0088h	; Set COM port number
@I41_CHG_TASK	equ  0089h	; Change task numbers
@I41_WIN_EXIT	equ  008Ah	; Windows is exiting
@I41_INST_VGA	equ  008Bh	; Install new VGA handler
@I41_GET_BASE	equ  008Ch	; Get COM port base address
@I41_GET_SYMB	equ  008Dh	; Lookup a symbol
@I41_COPY_MEM	equ  008Eh	; Copy memory

@I41_LOADSEG32	equ  0150h	; Load a 32-bit segment
@I41_FREESEG32	equ  0152h	; Free a 32-bit segment

@I41_MAXCONT	equ  0152h	; Maximum contiguous INT 41h function

@I41_COND_BP	equ 0F001h	; Conditional breakpoint
@I41_FORCE_BP	equ 0F002h	; Forced breakpoint
@I41_FORCE_GO	equ 0F003h	; Goto specified address
@I41_HARD_INT1	equ 0F004h	; Query INT 01h hook for all rings

; Local definitions

@I41_LCL	equ 0E0h	; Local function prefix
@I41_DISPLS	equ (@I41_LCL shl 8) + 00h ; Display load segment table (local definition)
@I41_GETLS	equ (@I41_LCL shl 8) + 01h ; Return address of ...
@I41_GETIPF	equ (@I41_LCL shl 8) + 02h ; Return address of IPF struc table


; Define structure for Kernel vars (@I41_KERNEL_VAR)

KVARS_STR struc

KV_hGlobalHeap	 dw ?	; 00:  ****
KV_pGlobalHeap	 dw ?	; 02:  ****
KV_hExeHead	 dw ?	; 04:  ****
KV_hExeSweep	 dw ?	; 06:
KV_topPDB	 dw ?	; 08:
KV_headPDB	 dw ?	; 0A:
KV_topsizePDB	 dw ?	; 0C:
KV_headTDB	 dw ?	; 0E:  ****
KV_curTDB	 dw ?	; 10:  ****
KV_loadTDB	 dw ?	; 12:
KV_LockTDB	 dw ?	; 14:
KV_SelTableLen	 dw ?	; 16:  ****
KV_SelTableStart dd ?	; 18:  ****

KVARS_STR ends


; Define structure for User vars (@I41_USER_VAR)

UVARS_STR1 struc

UV_fDebugUser1	 dw	?	; 00:  1 = DEBUG, 0 = RETAIL
UV_nphHmenuSel	 dw	?	; 02:  Offset in DS to hHmenuSel
UV_nphHwndSel	 dw	?	; 04:  ...	       hHwndSel
UV_nppclsList	 dw	?	; 06:  ...	       pclsList
UV_nppdceFirst	 dw	?	; 08:  ...	       pdceFirst
UV_nphwndDesktop dw	?	; 0A:  ...	       hwndDesktop

UVARS_STR1 ends

UVARS_STR2 struc

UV_fDebugUser2	 dd	?	; 00:  1 = DEBUG, 0 = RETAIL
UV_lphHmenuSel	 dd	?	; 04:  Ptr to hHmenuSel
UV_lphHwndSel	 dd	?	; 08:  ...    hHwndSel
UV_lppclsList	 dd	?	; 0C:  ...    pclsList
UV_lppdceFirst	 dd	?	; 10:  ...    pdceFirst
UV_lphwndDesktop dd	?	; 14:  ...    hwndDesktop

UVARS_STR2 ends

