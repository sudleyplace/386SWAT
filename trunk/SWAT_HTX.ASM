;' $Header:   P:/PVCS/386SWAT/SWAT_HTX.ASV   1.26   20 Aug 1998 23:05:54   BOB  $

	include ASCII.INC
	include WRAPPER.INC	; Handy Macros

.model SMALL
.code

STACK	segment byte stack 'prog' ; Start STACK segment
STACK	ends			; End STACK segment

	org	100h
START:

; Setup some initial values

COL_WIDTH 70
INDENT 0			; Set indenting for next few paras

RAWOUT <".386p">                ; Setup for use32 segment
RAWOUT <"WGROUP  group   WTXT">
RAWOUT <"WTXT    segment use32 byte public 'wdata' ; Start WTXT segment">
RAWOUT <"        assume  ds:WGROUP">

RAWOUT <"        public  @SWAT_HTX_WTXT">
RAWOUT <"@SWAT_HTX_WTXT  label byte  ; Mark module start in .MAP file">

ONESYMNAME HELP_QKYTTL
CENTER	<"QUICK GUIDE TO KEYSTROKES">

ONESYMNAME HELP_NAVTTL
CENTER	<"NAVIGATING 386SWAT">

ONESYMNAME HELP_CMDTTL
CENTER	<"COMMAND LINE ACTIONS">

ONESYMNAME HELP_BKMTTL
CENTER	<"BOOKMARKS">

ONESYMNAME HELP_AFLTTL
CENTER	<"AUTOFAULTS">

ONESYMNAME HELP_SRCHTTL
CENTER	<"SEARCHING">

ONESYMNAME HELP_WKDTTL
CENTER	<"WINDOWS-SPECIFIC COMMANDS">

; NEW TOPIC GOES HERE
; ONESYMNAME HELP_???TTL
; CENTER  <"???">

; Give some symbol names

COL_WIDTH 70
COLOR 0 			; Mark as using colors

;===============================================================================
SYMNAME HELP_NAV,@HNAV_NCOL,@HNAV_NROW ; Name this section

COLOR 1 		; Display the following line using color #1
 db  'Screen Overview',CR
 db  CR
 db  'The top of the initial debugging screen consists of a row of the '
 db  '32-bit general purpose registers, two rows of the segment registers, '
 db  'and one row of CR0, CR2, and extended flags.',CR
 db  CR
 db  'The rest of the initial debugging screen displays the instructions to '
 db  'be executed with the stack appearing on the right in one or two '
 db  'columns.  If the current instruction references memory, the segment '
 db  'register, offset, and memory value of the reference are displayed on '
 db  'the line separating the registers from the instructions.',CR
 db  CR
 db  'The last line is the command line.',CR
 db  CR
COLOR 1 		; Display the following line using color #1
 db  'Keystrokes',CR
 db  CR
 db  'There are several keystrokes available at this point:',CR
 db  CR
INDENT 17			; Set indenting for next section
 db  'ESC              Continue processing.  Equivalent to Go command in '
 db  'other debuggers.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'F1               Display a help screen with keystroke assignments.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'F2               Display GDT entries.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'F3               Display LDT entries.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'F4               Display IDT entries.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'F5               Display PTE entries.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'F6               Display search screen.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'F7               Display memory.  While this display is active, Ctl-B '
 db  'displays in byte format, Ctl-W, in word format, Ctl-D '
 db  'in dword format, Ctl-V in vector format, Ctl-G in GDT '
 db  'format, Ctl-I in IDT format, and Ctl-T in TSS format.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'F8               Display TSS entries.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'F9               Display the instruction disassembly screen.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'F10              Display screen on entry to debugger (this feature has '
 db  'no effect on two-monitor systems)'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'F11              Single-step the current instruction (see Padplus).  '
 db  'This key as well as F12 are useful on systems '
 db  'without a Padplus/Padminus key, or ones for which '
 db  'this key is difficult to type such as some laptops. '
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'F12              Single-skip the current instruction (see Padminus).'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  's-F1             Goto the immediate CALL or JMP address of the '
 db  'instruction at the top of the screen and save the '
 db  'address of the current instruction (see Disassembly '
 db  'Bookmarks below).'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  's-F2             Return from the previous s-F1 goto.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  's-F3             Goto the instruction on the top line (see Padstar).'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  's-F4             Display the last Auto Fault message.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  's-F5             Display the Real Mode Interrupt Vector Table.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  's-F10            Save the current screen into the last screen buffers.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'a-F1             Toggle intercept of INTs 01h/03h.  The current state '
 db  'appears below the segment/selector register display '
 db  'as 01 or blank, 03 or blank.  The default state is '
 db  'controlled by the presence or absence of the '
 db  'TRAPDEBUG keyword.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'a-F2             Toggle intercept of INT 02h.  The current state '
 db  'appears below the segment/selector register display '
 db  'as 02 or blank.  The default state is controlled by '
 db  'the presence or absence of the TRAPNMI keyword.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'a-F3             Toggle intercept of INT 0Dh.  The current state '
 db  'appears below the segment/selector register display '
 db  'as 0D or blank.  The default state is controlled by '
 db  'the presence or absence of the TRAPGENP keyword.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'a-F4             Toggle intercept of INT 0Eh.  The current state '
 db  'appears below the segment/selector register display '
 db  'as 0E or blank.  The default state is controlled by '
 db  'the presence or absence of the TRAPPAGE keyword.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'a-F5             Toggle stack display state between two columns of '
 db  'and one column of dwords.  The tick marks '
 db  'appear every 16 bytes.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'a-F6             Toggle screen save state (eliminates screen flicker '
 db  'when single-stepping over instructions which don''t '
 db  'write to the screen).  The current state appears '
 db  'below the segment/selector register display as SS=ON '
 db  'or SS=OFF.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'a-F7             Toggle video base (switch debugging screens in a '
 db  'two-monitor system).'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'a-F8             Display NDP register screen.  Use the same keystroke '
 db  'to remove the NDP screen.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'a-F9             Display debug register screen.  This screen remains '
 db  'active until it is replaced by another screen.  That '
 db  'is, you may type on the command line, etc. while the '
 db  'debug register screen is displayed.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'a-F10            Display previous debugging screens.  This option can '
 db  'be used to compare changes over a single-step or '
 db  'single-skip.  Up to sixteen previous screens can be '
 db  'displayed in this manner using the Up and Down arrows. '
 db  'To change from the default value of sixteen, use the '
 db  'keyword SAVESCREEN (see above).'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'a-F              Goto the far return address at SS:SP or SS|eSP '
 db  '(depending upon the current mode).  If the current '
 db  'code segment is USE16, the far return address is '
 db  'assumed to be word:word (or word|word); if it''s '
 db  'USE32, the format is assumed to be word:dword (or '
 db  'word|dword).  This shortcut is equivalent to typing '
 db  'G .RETF at the command line.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'a-N              Goto the near return address at SS:SP or SS|eSP '
 db  '(depending upon the current mode).  If the current '
 db  'code segment is USE16, the near return address is '
 db  'assumed to be word; if it''s USE32, the format is '
 db  'assumed to be dword.  This shortcut is equivalent to '
 db  'typing G .RETN at the command line.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'a-<              Retrieve the previous command.',CR
 db  'a->              Retrieve the next command.',CR
 db  'a-?              Display the command history.  A command may be '
 db  'chosen from the list by scrolling up or down and pressing the '
 db  'Enter key, or by typing the corresponding letter which is displayed '
 db  'to the left of the command.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-F1             Toggle intercept of INT 01h only.  The current state '
 db  'appears below the segment/selector register display '
 db  'as 01 or blank.  The default state is controlled '
 db  'by the presence or absence of the TRAPSTEP keyword.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-F2             Toggle intercept of INT 03h only.  The current state '
 db  'appears below the segment/selector register display '
 db  'as 03 or blank.  The default state is controlled '
 db  'by the presence or absence of the TRAPSKIP keyword.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-F3             Toggle intercept of INT 06h.  The current state '
 db  'appears below the segment/selector register display '
 db  'as 06 or blank.  The default state is controlled '
 db  'by the presence or absence of the TRAPINV keyword.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-F4             Toggle intercept of INT 0Ch.  The current state '
 db  'appears below the segment/selector register display '
 db  'as 0C or blank.  The default state is controlled '
 db  'by the presence or absence of the TRAPSTACK keyword.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-F5             Display PDE entries.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-F6             Display symbols.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-F7             Display file browser.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-F8             Enter CHAT mode.  This allows two connected machines '
 db  'to test the serial port connection.  What you type is '
 db  'displayed on the lower screen and sent to the other '
 db  'system; whatever is received is displayed on the top '
 db  'screen.  If only garbage characters appear the two '
 db  'machines may not have the same data transfer rate set.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-F9             Attempt to connect for remote debugging.  See the section '
 db  'at the end of this document on remote debugging.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-F10            Display error log.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-F11            Single-step INT-like instruction in VM to PM, '
 db  'otherwise just single-step (same as c-Padplus).'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-Up             Decrement the location pointer to the previous entry.'
 db  'This change has a different effect depending upon the '
 db  'type of information being displayed.  If used in a '
 db  'data display, it moves back one data item (byte, '
 db  'word, dword, etc.).  If used in a TSS display, the '
 db  'I/O ports in the I/O bit permission map scroll up.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-Down           Increment the location pointer to the next entry.  '
 db  'This change has a different effect depending upon the '
 db  'type of information being displayed.  If used in a '
 db  'data display, it moves forward one data item (byte, '
 db  'word, dword, etc.).  If used in a TSS display, the '
 db  'I/O ports in the I/O bit permission map scroll down.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-Home           Place the current instruction at the top of the '
 db  'screen.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-B              Display memory in byte (xx) format.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-D              Display memory in dword (xxxxxxxx) format.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-G              Display memory in GDT format.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-I              Display memory in IDT format.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-K              Display the Windows Kernel Debugger structures menu.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-M              Display the DOS Memory Allocation Chain (MAC) based '
 db  'from the address in MACBASE.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-T              Display memory in TSS format.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-V              Display memory in vector (xxxx:xxxx) format.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-W              Display memory in word (xxxx) format.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-Z              Zap (convert to NOPs) the instruction at the top of '
 db  'the instruction disassembly window.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-ESC            Same as ESC, but if you''re on an INT 03h, it skips '
 db  'over it first and then continues.  If the current '
 db  'instruction is not an INT 03h, this keystroke behaves '
 db  'identically to ESC.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'Padplus          Single-step the current instruction (same as F11).'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-Padplus        Single-step INT-like instruction in VM to PM, '
 db  'otherwise just single-step (same as c-F11).'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'Padminus         Single-skip the current instruction (same as F12).  That is, '
 db  'execute the current instruction and put a breakpoint '
 db  'on the instruction following.  This is used to '
 db  'execute but not single-step through a CALL or LOOP '
 db  'instruction.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'Padstar          Goto the instruction on the top line.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'Up               Scroll the screen up one line.  This key has the same '
 db  'effect in almost all screen displays.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'Down             Scroll the screen down one line.  This key has the '
 db  'same effect in almost all screen displays.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'PgUp             Scroll the screen up one page.  This key has the same '
 db  'effect in almost all screen displays.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'PgDown           Scroll the screen down one page.  This key has the '
 db  'same effect in almost all screen displays.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  's-PrtSc          Print the screen.  Note that if either the previous '
 db  'application screen (F10) or one of the previous '
 db  'debugging screens (a-F10) is currently displayed, '
 db  'that screen is sent to the printer.  The I/O port in '
 db  'the BIOS data area which corresponds to LPT1 is used.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'c-s-PrtSc        Print the instruction portion of the screen.  '
 db  'If the current screen displayed is the instruction disassembly '
 db  'window, print only the instruction portion of that screen.  '
 db  'The I/O port in the BIOS data area which corresponds to LPT1 is used.'
INDENT 0			; Clear indenting
 db  CR
INDENT 17			; Set indenting for next section
 db  'Ctl-Alt-Del      Reboot the system.',CR


;===============================================================================
SYMNAME HELP_CMD,@HCMD_NCOL,@HCMD_NROW ; Name this section

INDENT 0			; Clear indenting
 db  'The line at the bottom of the screen is used to enter various '
 db  'commands. The following table summarizes the possibilities.  The '
 db  'usual editing keys are available such as Left, Right, Home, End, '
 db  'Insert, Backspace, and Delete.  Note that a colon (:) is used to '
 db  'separate a segment from an offset (Virtual 8086 Mode) and that a '
 db  'broken stile (|) is used to separate a selector from an offset '
 db  '(Protected Mode).  The command line is parsed according to the grammar '
 db  'found in the file 386SWAT.GRM which includes an LALR parser with '
 db  'nested parentheses.',CR
 db  CR
 db  'Commands entered on the command line are saved in a ring buffer whose '
 db  'length can be changed from the default of 1024 via the profile keyword '
 db  'CMDHIST=nnn.',CR
 db  CR
 db  'Previous commands can be retrieved via the keystrokes Alt-< (previous '
 db  'command) and Alt-> (next command).  Pressing either of these keys '
 db  'repeatedly scrolls through the buffer in the chosen direction.  The '
 db  'keystroke Alt-? displays a history of (up to 25) commands from which a '
 db  'command can be chosen by scrolling up or down through the list, or by '
 db  'typing the letter next to the command.  A command may be deleted from '
 db  'this list via the Del key.',CR
 db  CR
 db  'Note that whenever an address is called for, the following may be used '
 db  'instead:',CR
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Effective Addressing',CR
 db  '.EA               Effective Address #1 (or the only one).',CR
 db  '.EA2              ...               #2.',CR
 db  '.GDT              GDT base address (using selector zero).',CR
 db  '.IDT              IDT ...',CR
 db  '.LDT              LDT ...',CR
 db  '.TSS              TSS ...',CR
 db  '.MDB              Current Module Database base address',CR
 db  '.TDB              ...     Task ...',CR
 db  '.CMAC             Seg:Off of next C MAC entry.',CR
 db  '.CODE             current code display address.',CR
 db  '.CSIP             address of current cs:[e]ip.',CR
 db  '.DATA             current data display address.',CR
 db  '.DMAC             Seg:0 of first DOS MAC entry.',CR
 db  '.NMAC             Seg:0 of next  DOS MAC entry.',CR
 db  '.PMIxx            Sel|Off of PM Interrupt xxh.',CR
 db  '.RMIxx            Seg:Off of RM interrupt # xx.',CR
 db  '.VMIxx            ..         VM ...',CR
INDENT 18			; Set indenting for next section
 db  '.IRET             far word:dword return address on stack '
 db  'allowing a mode switch from PM to VM.'
INDENT 0			; Clear indenting
 db  CR
INDENT 18			; Set indenting for next section
 db  '.RETN             near return address on stack '
 db  'with a word or dword offset depending upon D-bit in CS '
 db  'and CS:Off or CS|Off depending upon VM bit in EFL.'
INDENT 0			; Clear indenting
 db  CR
INDENT 18			; Set indenting for next section
 db  '.RETND            near dword return address on stack '
 db  'and CS:Off or CS|Off depending upon VM bit in EFL.'
INDENT 0			; Clear indenting
 db  CR
INDENT 18			; Set indenting for next section
 db  '.RETNS            near word return address on stack '
 db  'and CS:Off or CS|Off depending upon VM bit in EFL.'
INDENT 0			; Clear indenting
 db  CR
INDENT 18			; Set indenting for next section
 db  '.RETF             far return address on stack '
 db  'with a word or dword offset depending upon D-bit in CS '
 db  'and Seg:Off or Sel|Off depending upon VM bit in EFL.'
INDENT 0			; Clear indenting
 db  CR
INDENT 18			; Set indenting for next section
 db  '.RETFD            far word:dword return address on stack '
 db  'and Seg:Off or Sel|Off depending upon VM bit in EFL.'
INDENT 0			; Clear indenting
 db  CR
INDENT 18			; Set indenting for next section
 db  '.RETFS            far word:word return address on stack '
 db  'and Seg:Off or Sel|Off depending upon VM bit in EFL.'
INDENT 0			; Clear indenting
 db  CR
INDENT 18			; Set indenting for next section
 db  '.VM               address of Windows VM structure.',CR
 db  '.VMCRS            address of Windows VM Client Register Struc in .VM.',CR
 db  '.VMRET            return CS|EIP in Windows .VMCRS.',CR
INDENT 0			; Clear indenting
 db  CR
 db  '.XBDA             Seg:Off of XBDA; same as ([40:0E):0.',CR
INDENT 18			; Set indenting for next section
 db  '.XBDA2            Seg:Off of secondary XBDA; same as ((S..XBDA)+[.XBDA+B4):0.'
INDENT 0			; Clear indenting
 db  CR
INDENT 18			; Set indenting for next section
 db  ':[ ea             extract word:word at effective address.',CR
 db  ':{ ea             ...     word:dword ...',CR
 db  '|[ ea             ...     word|word ...',CR
 db  '|{ ea             ...     word|dword ...',CR
 db  '|G ea             ...     in GDT-format (using selector zero).',CR
 db  '|I ea             ...     in IDT-format (using IDT selector).',CR
 db  '|L ea             ...     in LDT-format (same as GDT-format).',CR
 db  '|T ea             ...     in TSS-format (using CS|EIP).',CR
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Code Breakpoints',CR
 db  'BC               ð Display all code breakpoints.',CR
 db  'BC addr          ð Set code breakpoint at ADDR.',CR
 db  'BC*              ð Clear all code breakpoints.',CR
 db  'BC* addr         ð Clear code breakpoint at ADDR.',CR
 db  'BC+              ð Enable all code breakpoints.',CR
 db  'BC+ addr         ð Enable code breakpoint at ADDR.',CR
 db  'BC-              ð Disable all code breakpoints.',CR
 db  'BC- addr         ð Disable code breakpoint at ADDR.',CR
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Debug Registers DR0 to DR3',CR
 db  'BD addr          ð Set DR breakpoint on instruction fetches at address '
 db  'addr.',CR
 db  'BD addr Ln R     ð Set DR breakpoint on read/writes of length n (n=1, '
 db  '2, 4). at address addr',CR
 db  'BD addr Ln W     ð Set DR breakpoit on writes of length n (n=1, 2, 4) '
 db  'at address addr.',CR
 db  'BDn*             ð Clear DRn.',CR
 db  'BDn+             ð Enable DRn.',CR
 db  'BDn-             ð Disable DRn.',CR
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Data Display',CR
 db  'D addr           ð Data display.',CR
 db  'D-               ð Data display back one page.',CR
INDENT 30			; Set indenting for next section
 db  'Dx addr          ð Data type display (B = Byte,   W = Word, D = Dword, '
 db  'V = Vector, G = GDT,  I = IDT, T = TSS, '
 db  'T2 = 286 TSS, T3 = 386 TSS).',CR
INDENT 0			; Clear indenting
INDENT 19			; Set indenting for next section
 db  'Dx addr P        ð Data display as physical data (say in ROM which has '
 db  'been mapped over by 386MAX).',CR
INDENT 0			; Clear indenting
INDENT 19			; Set indenting for next section
 db  'Dx addr P exp    ð Data display using exp as CR3 - this is useful when '
 db  'debugging VCPI clients because they use a separate '
 db  'CR3.',CR
INDENT 0			; Clear indenting
 db  'All data display commands may be followed by an optional width '
 db  'switch (e.g., DW/5 which displays the data at five words per '
 db  'line instead of the usual eight).  The data width switch must '
 db  'be placed between the data command and its arguments (if any) '
 db  'as in DW/5 DS:0.',CR
INDENT 0			; Clear indenting
INDENT 19			; Set indenting for next section
 db  'DTE sel          ð Display the Descriptor Table Entry for the given '
 db  'selector.',CR
INDENT 0			; Clear indenting
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Data Entry',CR
INDENT 19			; Set indenting for next section
 db  'E addr [xx ...]  ð Enter data starting at ADDR using optional hex '
 db  'bytes xx.',CR
INDENT 0			; Clear indenting
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Exit To DOS',CR
INDENT 19			; Set indenting for next section
 db  'EXIT             ð Exit to DOS.  This command is equivalent to the '
 db  'following command sequence:',CR
 db  '                   R AH=4C',CR
 db  '                   SIGINT 21',CR
 db  '                   G',CR
INDENT 0			; Clear indenting
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Data Fill',CR
INDENT 19			; Set indenting for next section
 db  'F addr L len xx  ð Fill data starting at ADDR of length LEN with '
 db  'byte value xx.',CR
INDENT 0			; Clear indenting
INDENT 19			; Set indenting for next section
 db  'F addr L len xx P ð Fill physical data starting at ADDR of length '
 db  'LEN with byte value xx.',CR
INDENT 0			; Clear indenting
INDENT 19			; Set indenting for next section
 db  'F addr L len xx P exp ð Fill data starting at ADDR of length '
 db  'LEN with byte value xx where ADDR is translated using exp as CR3 '
 db  '- this is useful when '
 db  'debugging VCPI clients because they use a separate '
 db  'CR3.',CR
INDENT 0			; Clear indenting
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Insertion Into PM Context',CR
INDENT 19			; Set indenting for next section
 db  'INSERT gdtr idtr [cr3 [lapde]] ð Insert into PM context.',CR
 db  'INSERT *    idtr               ð Insert into IDT.',CR
 db  'where gdtr = linear address of fword describing the GDT',CR
 db  '      idtr = ...                                    IDT',CR
 db  '      cr3  = incoming CR3 (optional)',CR
 db  '      lapde= linear address of 4MB block where 386SWAT''s',CR
 db  '             PDE(s) should be copied',CR
INDENT 0			; Clear indenting
 db  CR
 db  'Insert 386SWAT into a PM context while still in RM.  '
 db  'This feature is useful when attempting to debug across '
 db  'the boundary from RM to PM.  In particular, it can be used '
 db  'to gain control shortly after Windows enters PM.',CR
INDENT 0			; Clear indenting
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Data Move',CR
INDENT 19			; Set indenting for next section
 db  'M addr L len addr ð Move data starting at first ADDR of length LEN '
 db  'to second ADDR.',CR
INDENT 0			; Clear indenting
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         MAC Display',CR
INDENT 19			; Set indenting for next section
 db  'MACBASE addr     ð Set the base address of the MAC chain in '
 db  'case it''s different from .DMAC.  This is handy when '
 db  'displaying the DOS subsegment chain.',CR
INDENT 0			; Clear indenting
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Hex Arithmetic',CR
 db  'H exp            ð Display hex arithmetic result.',CR
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Instruction Goto',CR
 db  'G                ð Go without stopping (same as ESC).',CR
 db  'G addr           ð Goto to instruction at address ADDR.',CR
INDENT 19			; Set indenting for next section
 db  'GM exp           ð Single-step until expression is TRUE. '
 db  'Monitor expressions may use * / + - << >> < <= > >= == != & ^ && and ||. '
 db  'For example:',CR
 db  '                   gm al!=0 && ([.csip-2)==21cd',CR
 db  'GM               ð Single-step using previous monitor expression.',CR
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Instruction Disassembly',CR
 db  'U addr           ð Unassemble instructions starting at ADDR.',CR
 db  'U-               ð Unassemble instructions back one page.',CR
INDENT 19			; Set indenting for next section
 db  'U16 addr         ð Unassemble instructions starting at ADDR as a '
 db  '16-bit code segment.',CR
INDENT 0			; Clear indenting
INDENT 19			; Set indenting for next section
 db  'U32 addr         ð Unassemble instructions starting at ADDR as a '
 db  '32-bit code segment.',CR
INDENT 0			; Clear indenting
INDENT 19			; Set indenting for next section
 db  'Ux addr P        ð Unassemble instructions as physical data (say in '
 db  'ROM which has been mapped over by 386MAX).',CR
INDENT 0			; Clear indenting
INDENT 19			; Set indenting for next section
 db  'Ux addr P exp    ð Unassemble instructions starting at ADDR using exp '
 db  'as CR3 - this is useful when debugging VCPI clients '
 db  'because they use a separate CR3.',CR
INDENT 0			; Clear indenting
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Page Table Display',CR
 db  'PTE addr         ð Display the Page Directory and Page Table entries',CR
INDENT 19			; Set indenting for next section
 db  'PTE val            which correspond to the address addr or linear '
 db  'address val.',CR
INDENT 0			; Clear indenting
 db  CR
INDENT 19			; Set indenting for next section
 db  'SPTE addr/val    ð Same as PTE command, but also displays the matching '
 db  'PTE in the PTE display screen (F5).',CR
INDENT 0			; Clear indenting
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Signal Interrupt',CR
INDENT 19			; Set indenting for next section
 db  'SIGINT xx        ð Signal interrupt xx (00 to FF, of course).  This '
 db  'keyword is useful (particularly for hardware '
 db  'interrupts) when you are debugging a time-critical '
 db  'piece of code and need to see what would happen if '
 db  '(say) a timer tick happened at this particular '
 db  'point.',CR
INDENT 0			; Clear indenting
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Toggle Interrupt Interception',CR
INDENT 19			; Set indenting for next section
 db  'TOGINT xx [xx ...] ð Toggle interception of interrupt xx (00 to FF, '
 db  'of course).  Valid interrupts are 00, 01, 02, 03, '
 db  '05, 06, 0C, 0D, 0E.  For example, if TRAPINV does '
 db  'not appear in the 386SWAT profile and you wish to '
 db  'enable it, use TOGINT 6.',CR
INDENT 0			; Clear indenting
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Register Operations',CR
INDENT 19			; Set indenting for next section
 db  'R reg=exp        ð Set register REG to EXP.  Valid registers include '
 db  'all GP and EGP as well as FL, EFL, CRn, DRn, TRn, TR, and '
 db  'LDTR.  There are two ways to crash the system via '
 db  'this command:  setting CR3 to a bad value, or '
 db  'setting EFL with a bad value for the VM or IOPL '
 db  'flags.  The code which sets CR0 forces the Page '
 db  'Enable and Protect Enable bits on (as evidenced by '
 db  'typing R CR0=0), so experiment without fear.  Use '
 db  'the pseudo-register names CSIP or CSEIP to set both '
 db  'registers to an address.',CR
INDENT 0			; Clear indenting
INDENT 19			; Set indenting for next section
 db  'R reg.str=exp    ð This command also supports bit mask qualifiers on '
 db  'registers.  For example, to set the AM bit in CR0, '
 db  'type R CR0.AM=1.  See below for a complete list of '
 db  'mask values supported.',CR
INDENT 0			; Clear indenting
INDENT 19			; Set indenting for next section
 db  'RC               ð Clear saved register state so another RS may execute.',CR
 db  'RR               ð Restore saved registers.',CR
 db  'RS               ð Save registers to restore later via RR.  Only '
 db  'one RS may be executed at a time without either restoring the '
 db  'state via RR or clearing the state via RC.',CR
INDENT 0			; Clear indenting
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Search Operations',CR
 db  'S addr1 addr2 tgt ð Search from addr1 to addr2 or from ea for len.',CR
INDENT 19			; Set indenting for next section
 db  'S addr L len tgt   bytes for target tgt.  The search results are '
 db  'displayed on a separate screen which may be made '
 db  'active at other times by pressing F6.  Only the '
 db  'first 23 matches are displayed.  In a future release the Up, Down, '
 db  'Page Up, and Page Down keys might allow scrolling through successive '
 db  'matches.  The target may take one of several forms:',CR
INDENT 0			; Clear indenting
 db  CR
INDENT 2			; Set indenting for next section
 db  '* Use a target of the form xx, xxxx, xxxxxxxx where x represents a hex '
 db  'digit to search for bytes, words, or dwords of a specified value.  '
 db  'For example, the form S 0:0 L FFFF 10CD searches for all occurrences '
 db  'of the hex bytes CD followed by 10 in the first 64KB of conventional '
 db  'memory.  Word and dword searches do not require word or dword '
 db  'alignment of the matching data.',CR
INDENT 0			; Clear indenting
 db  CR
INDENT 2			; Set indenting for next section
 db  '* Use a target of the form "search_string" to search for a case '
 db  'sensitive string.  For example, S 0:0 L FFFF "386MAX" searches for '
 db  'all occurrences of the string 386MAX in the first 64KB of conventional '
 db  'memory.  The ability to search for a case insensitive string will be added '
 db  'in the future.',CR
INDENT 0			; Clear indenting
 db  CR
INDENT 2			; Set indenting for next section
 db  '* Use a target of the form !instr to search for a specific assembler '
 db  'instruction.  For example, S 0:0 L FFFF !INT 10 searches for all '
 db  'occurrences of video interrupt calls in the first 64KB of conventional '
 db  'memory.  This target is found by disassembling the code between the '
 db  'start and stop addresses instruction by instruction, thus the '
 db  'alignment of the matching instructions and the starting address is '
 db  'critical.  If data appears within that range, some matches may be '
 db  'missed.  The command S1 (instead of S) can be used to disassemble '
 db  'the code byte by byte.  That is, with the S command, having '
 db  'disassembled an instruction which does not match the specified '
 db  'pattern, the next instruction is searched; with the S1 command, the '
 db  'next byte is searched.',CR
 db  CR
INDENT 2			; Set indenting for next section
 db  '  The code search text may include one or more question marks as '
 db  'wildcards which match any character in the disassembled '
 db  'instructions. For example, use S 50|0 FFFF !mov e??,cr? to find '
 db  'all moves from a control register to a 32-bit register.  Try the '
 db  'forms S 3BC7:100 FFFF !mov [1234] and S 3BC7:100 FFFF !mov ?s:[1234] '
 db  'to find all moves into location [1234] with or without a segment '
 db  'override.  To find jumps to a specific location, use the code '
 db  'targets !j? 1234, !j?? 1234, and !j??? 1234.  Note that floating '
 db  'point instructions may be disassembled beginning with either ''F'' or '
 db  '''FN'' depending upon the presence of a preceding WAIT opcode (9Bh).  '
 db  'To be safe, search for both.',CR
INDENT 0			; Clear indenting
 db  CR
INDENT 2			; Set indenting for next section
 db  '* Use a target of the form #PTE to search for a PTE in the Page '
 db  'Tables.  For example, S 0 C0000000 # CF4000 searches for the PTE '
 db  'CF4000 from linear 0 through linear C0000000.  The linear addresses '
 db  'are both rounded down to a 4KB boundary.  A match at a particular '
 db  'linear address means that the PTE was found and it covers the 4KB '
 db  'block at the linear address displayed.  When comparing PTEs, the '
 db  'flag bits are ignored, thus a match might be found when the PTE in '
 db  'the Page Tables is not present.',CR
INDENT 0			; Clear indenting
 db  CR
INDENT 19			; Set indenting for next section
 db  'SGH [/b | /s | /h | /o] [/c] expr searches the Windows Global '
 db  'Heap for values.  The expression (expr) entered is interpreted as '
 db  'a base address if /b is specified, size if /s, handle if /h, and '
 db  'owner if /h.  If /c is specified, the search continues from the '
 db  'currently displayed entry; otherwise, the search starts at the top '
 db  'of the heap.',CR
INDENT 0			; Clear indenting
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         I/O Port Read/Write',CR
 db  'Ix port          ð Input Byte, Word, or Dword from PORT.',CR
INDENT 19			; Set indenting for next section
 db  'IMR              ð Display current Interrupt Mask Register values for '
 db  'master and slave PICs.',CR
INDENT 0			; Clear indenting
 db  'IRR              ð Display current Interrupt Request Register values.',CR
 db  'ISR              ð Display current In-Service Register values.',CR
 db  'Ox port val      ð Output Byte, Word, Dword VAL to PORT.',CR
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Symbolic Debugging (see SWATSYM.DOC for details)',CR
 db  'CD [d:][path]    ð Change the current directory to path.  If no',CR
 db  'CHDIR [d:][path]   argument, display the current drive/directory.',CR
 db  'FS               ð Flush symbol table.',CR
 db  'LF filename      ð Load file into browser.',CR
 db  'LI +             ð Enable line number display in disassembly screen.',CR
 db  'LI -             ð Disable line number display.',CR
 db  'LI dddd          ð Go to line dddd (decimal) in file browser.',CR
 db  'LI dddd+         ð Go to line dddd forward from current line.',CR
 db  'LI dddd-         ð Go to line dddd back from current line.',CR
 db  'LS filename      ð Load symbol file.',CR
INDENT 19			; Set indenting for next section
 db  'LS filename exp  ð Load symbol file and add 16-bit value to all VM segments.',CR
INDENT 0			; Clear indenting
 db  'PATH d:\dir1[,d:\dir2[,...]] ð Set source file search path.',CR
 db  'PATH+ d:\dira[,d:\dirb[,...]] ð Add to source file search path.',CR
 db  'PS r             ð Set range of symbol proximity searches to r.',CR
INDENT 19			; Set indenting for next section
 db  'PS r g           ð Set range and granularity (1=bytes, 2=words, 4=dwords) '
 db  'of symbol proximity searches.',CR
INDENT 0			; Clear indenting
INDENT 19			; Set indenting for next section
 db  'QS addr          ð Display the symbol nearest to (and below) the given '
 db  'address.',CR
INDENT 0			; Clear indenting
 db  'SB+              ð Enable source browser mode.',CR
 db  'SB-              ð Disable source browser mode.',CR
INDENT 19			; Set indenting for next section
 db  'SB*+             ð Enable source browser mode but disregard module names.',CR
INDENT 0			; Clear indenting
INDENT 19			; Set indenting for next section
 db  'TS               ð Force all symbols to be retranslated according to '
 db  'current GDT and LDT.',CR
INDENT 0			; Clear indenting
 db  'TS sel           ð Retranslates only for selector/segment sel.',CR
INDENT 19			; Set indenting for next section
 db  'TS * ID          ð Retranslates for all selectors/segments with ID specified.',CR
INDENT 0			; Clear indenting
INDENT 19			; Set indenting for next section
 db  'TS sel ID        ð Retranslates only for selector/segment sel with ID specified.',CR
INDENT 0			; Clear indenting
INDENT 19			; Set indenting for next section
 db  'TS *|sel *|ID v|p ð Change to specified mode for selector and/or ID specified.',CR
INDENT 19			; Set indenting for next section
 db  'TS *|sel *|ID *|v|p nsel ð Replace segment/selector and mode for specified '
 db  'selectors and IDs.  If * is specified for mode, the mode '
 db  'is left alone.',CR
INDENT 0			; Clear indenting
INDENT 19			; Set indenting for next section
 db  'TS *|sel *|ID *|v|p nsel+ ð nsel is added to all specified segments.',CR
INDENT 0			; Clear indenting
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Remote debugging',CR
INDENT 19			; Set indenting for next section
 db  'APPKEY           ð Edit application keystroke buffer.  This is primarily '
 db  'useful for remote debugging.  If an application is waiting '
 db  'for a keystroke, this feature allows you to send one to '
 db  'the application, as well as to view any that may already '
 db  'be available.',CR
INDENT 0			; Clear indenting
 db  'CHAT             ð Enter CHAT mode (also via Ctl-F8)',CR
INDENT 19			; Set indenting for next section
 db  'SETCOM port bps  ð Initialize specified serial port for communications. '
 db  'See SETCOM= profile option for full syntax.',CR
INDENT 0			; Clear indenting
INDENT 19			; Set indenting for next section
 db  'SETCOM           ð Reinitialize the serial port with values last specified '
 db  'by SETCOM or SETCOM=.  This is useful when an application '
 db  'has reprogrammed the UART.',CR
INDENT 0			; Clear indenting
INDENT 19			; Set indenting for next section
 db  'SETCOM -         ð Ignore all activity on serial port.  Use this if you are '
 db  'done with remote debugging and wish an application to '
 db  'have access to the serial port.  When 386SWAT is using the '
 db  'serial port, no serial port interrupts will be visible '
 db  'to virtual mode programs.',CR
INDENT 0			; Clear indenting
 db  'SETCOM RTS+      ð Pull RTS (Request To Send) line high.',CR
 db  'SETCOM RTS-      ð Drop RTS (Request To Send) line low.',CR
 db  'SETCOM DTR+      ð Pull DTR (Data Terminal Ready) line high.',CR
INDENT 19			; Set indenting for next section
 db  'SETCOM DTR-      ð Drop DTR (Data Terminal Ready) line low.  This is one '
 db  'way to hang up a modem that won''t respond to (wait)+++ '
 db  '(wait)ATH(ENTER).',CR
INDENT 0			; Clear indenting
INDENT 19			; Set indenting for next section
 db  'REMDBG           ð Attempt to establish remote debugging session (also '
 db  'via Ctl-F9).  See the section below on remote debugging.',CR
INDENT 0			; Clear indenting
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Unreal Mode',CR
INDENT 19			; Set indenting for next section
 db  'UNREAL s reg [s reg ...] ð Turn on or off Unreal Mode for all or '
 db  'selected segment registers.  This mode is a '
 db  'variant of Real Mode in which any segment register '
 db  'can access all of the 4GB address space.  That is, instead of the '
 db  'normal 64KB length of a segment, the length is 4GB.  This command '
 db  'can enable all or just some of the segment registers for UM.',CR
 db  CR
 db  '                   Legend:  s is either + or - and reg is one of '
 db  'ALL CS DS ES FS GS or SS',CR
 db  CR
 db  '                   For example:',CR
 db  '                   To enable all segment registers, use +ALL',CR
 db  '                   To disable all segment registers, use -ALL',CR
 db  '                   To enable or disable selected segment registers, '
 db  'use +xS or -xS, where x is C D E F G or S, as in +DS or -ES.  You '
 db  'may specify multiple registers on the same line as in +DS +ES.',CR
 db  CR
 db  '                   To see if a segment register is enabled for UM, '
 db  'look for the plus sign next to the segment number in the instruction '
 db  'disassembly window.',CR
INDENT 0			; Clear indenting
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Virtual Mode Switches',CR
INDENT 19			; Set indenting for next section
 db  'VMSCOUNT=val     ð Don''t intrude into the GDT/IDT for VCPI debugging '
 db  'until the value in this counter has decremented to '
 db  'zero.  This keyword is useful for occasions where '
 db  'the VCPI client shuffles its GDT and IDT around for '
 db  'a while before deciding just where it''s going to be.',CR
INDENT 0			; Clear indenting
 db  CR
INDENT 19			; Set indenting for next section
 db  'VMSINT ON|OFF    ð Turn VMS interrupt interception ON or OFF.',CR
 db  'VMSINT=xx,xx,... ð Enable VMS interrupt interception for these interrupts '
 db  'only.  This change takes effect upon entry to the VCPI client.',CR
INDENT 0			; Clear indenting
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Windows Kernel Debugger Commands',CR
INDENT 19			; Set indenting for next section
 db  'WKD [ON|OFF]     ð Turn ON or OFF Kernel Debugging.  This command '
 db  'cannot be used from within Windows.',CR
 db  'WKD [QUIET|NOISY] ð Disable (QUIET) or Enable (NOISY) reports on '
 db  'Parameter Errors.',CR
 db  'WKD LOGERROR [ON|OFF] ð Turn ON or OFF the INT 01h trap of LogErrors.',CR
 db  'WKD FAULT [ON|OFF|SKIP] ð Turn ON, OFF, or SKIP once traps for Faults.',CR
INDENT 0			; Clear indenting
 db  CR
INDENT 19			; Set indenting for next section
 db  'IPF [/d] [/s] [/r] expr ð If Invalid Page Faults are being trapped '
 db  'by 386SWAT''s VxD (see SWATVXD.DOC for more details), use the IPF '
 db  'command to control how these events are to be handled.  '
 db  'The optional switch /d tells 386SWAT not to display a message on '
 db  'the mono screen describing this event, /s tells 386SWAT not to '
 db  'stop when this event occurs, /r tells 386SWAT to remove this entry '
 db  'from its local tables, and expr is an expression which '
 db  'evaluates to a linear address corresponding to the Invalid '
 db  'Page Fault.',CR
 db  CR
COLOR 1 		; Display the following line using color #1
 db  '         Pentium Pro CPU Specific Commands',CR
INDENT 19			; Set indenting for next section
 db  'BTF              ð Display Branch Trace Facility state (ON or OFF).',CR
 db  'BTF ON|OFF       ð Turn Branch Trace Facility state ON or OFF.',CR
 db  'LBR              ð Display Last Branch/Exception values on the '
 db  'command line.',CR
 db  'LBR ON|OFF       ð Turn Last Branch/Exception window display ON or '
 db  'OFF.  The four-line window displays the Last Branch From EIP, '
 db  'Last Branch To EIP, Last Exception From EIP, and Last Exception '
 db  'To EIP.  Also, the keywords .LBRFR, .LBRTO, .LEXFR, .LEXTO contain '
 db  'the value of the Last Branch/Exception From/To EIP in case '
 db  'these need to be used in command line expressions (e.g., U .LBRFR).',CR
INDENT 0			; Clear indenting
 db  CR
COLOR 1 		; Display the following line using color #1
CENTER <'Register Mask Values'>
COLOR 1 		; Display the following line using color #1
CENTER <'--------------------'>
 db  CR
 db  'The following pseudo-records describe the bit masks supported by the '
 db  'register command where "*" represents reserved bits with no '
 db  'corresponding name:',CR
 db  CR
INDENT 12			; Set indenting for next section
 db  'EFL record  *:10, ID:1, VIP:1, VIF:1, AC:1, VM:1, RF:1, *:1, NT:1, IOPL:2, OF:1, DF:1, '
 db  'IF:1, TF:1, SF:1, ZF:1, *:1, AF:1, *:1, PF:1, *:1, CF:1',CR
INDENT 0			; Clear indenting
 db  CR
INDENT 12			; Set indenting for next section
 db  'CR0 record  PG:1, CD:1, NW:1, *:10, AM:1, *:1,  WP:1, '
 db  '*:10, NE:1, ET:1, TS:1, EM:1, MP:1, PE:1',CR
INDENT 0			; Clear indenting
 db  CR
INDENT 12			; Set indenting for next section
 db  'PTE record  FRM:20,   PTE_AVL:3, *:2,      PTE_D:1,  PTE_A:1, '
 db  'PTE_CE:1, PTE_WT:1,  PTE_US:1, PTE_RW:1, PTE_P:1',CR
INDENT 0			; Clear indenting
 db  CR
 db  'SEL record  SEL:13, TI:1, PL:2',CR
 db  CR
 db  'DR6 record  *:16, BT:1, BS:1, BD:1, *:9, B3:1, B2:1, B1:1, B0:1',CR
INDENT 12			; Set indenting for next section
 db  'DR7 record  LEN3:2, RW3:2, LEN2:2, RW2:2, LEN1:2, RW1:2, LEN0:2, RW0:2, '
 db  '*:2, GD:1, *:3, GE:1, LE:1, G3:1, L3:1, G2:1, L2:1, G1:1, L1:1, '
 db  'G0:1, L0:1',CR
INDENT 0			; Clear indenting
 db  CR
 db  'TR4 record  TR4_TAG:21, TR4_WVAL:1, TR4_LRU:3, TR4_RVAL:4, *:3',CR
 db  'TR5 record  *:21, TR5_SSEL:7, TR5_ESEL:2, TR5_CTL:2',CR
INDENT 12			; Set indenting for next section
 db  'TR6 record  FRM:20, TR6_V:1, TR6_D:1, TR6_DP:1, TR6_U:1, TR6_UP:1, '
 db  'TR6_W:1, TR6_WP:1, *:4, TR6_C:1',CR
INDENT 0			; Clear indenting
 db  'TR7 record  FRM:20,*:7, TR7_HT:1, TR7_REP:2, *:2',CR


;===============================================================================
SYMNAME HELP_QKY,@HQKY_NCOL,@HQKY_NROW ; Name this section

INDENT 0
 db  'F1  ð Help        A-F1  ð Toggle INT 01/03    C-F1  ð Toggle INT 01   ',CR
 db  'F2  ð GDT         A-F2  ð Toggle INT 02       C-F2  ð Toggle INT 03   ',CR
 db  'F3  ð LDT         A-F3  ð Toggle INT 0D       C-F3  ð Toggle INT 06   ',CR
 db  'F4  ð IDT         A-F4  ð Toggle INT 0E       C-F4  ð Toggle INT 0C   ',CR
 db  'F5  ð PTE         A-F5  ð Toggle Stack Width  C-F5  ð Display PDEs    ',CR
 db  'F6  ð Search      A-F6  ð Toggle Screen Save  C-F6  ð Display symbols ',CR
 db  'F7  ð Memory      A-F7  ð Toggle Video base   C-F7  ð File browser    ',CR
 db  'F8  ð TSS         A-F8  ð Toggle NDP regs     C-F8  ð Chat screen     ',CR
 db  'F9  ð Registers   A-F9  ð Debug registers     C-F9  ð Remote session  ',CR
 db  'F10 ð Alt scrn    A-F10 ð Last debug screen   C-F10 ð Error log       ',CR
 db  'F11 ð Single-step                             C-F11 ð Single-step INT ',CR
 db  'F12 ð Single-skip                                     from Vm to PM   ',CR
 db  '                                                                      ',CR
 db  'S-F1 ð Bookmark       Padplus  ð Single-step  C-Padplus ð Single-step ',CR
 db  'S-F2 ð Undo Bookmark  Padminus ð Single-skip         INT from VM to PM',CR
 db  'S-F3 ð Goto .code     PadStar  ð Goto .code   C-Up  ð Decrement EIP   ',CR
 db  'S-F4 ð AutoFault msg       Esc ð Go           C-Dn  ð Increment EIP   ',CR
 db  'S-F5 ð RM IVT         C-Home ð Home to CS|EIP C-Z   ð ZAP .code to NOP',CR
 db  'Up  ð Scroll up       PgUp  ð Page up                                 ',CR
 db  'Dn  ð Scroll down     PgDn  ð Page down                               ',CR
COLOR 1 		; Display the following line using color #1
 db  '         Display memory formats                                       ',CR
 db  'C-B ð Bytes   C-V ð Seg:Off  C-T ð TSS      A-F ð  G .RETF            ',CR
 db  'C-W ð Words   C-G ð GDT      C-M ð MAC      A-N ð  G .RETN            ',CR
 db  'C-D ð Dwords  C-I ð IDT      C-K ð WKD                                ',CR
COLOR 1 		; Display the following line using color #1
 db  '         Command Recall                                               ',CR
 db  'A-< ð Retrieve previous  A-> ð Retrieve next  A-? ð Display history   ',CR
 db  '         Screen Printing                                              ',CR
 db  'S-PrtSc ð Print the screen  C-S-PrtSc ð Print disassembly window only ',CR


;===============================================================================
SYMNAME HELP_BKM,@HBKM_NCOL,@HBKM_NROW ; Name this section
INDENT 0
db 'At times you need to browse through some code (sometimes it''s even '
db 'your own code) following subroutine calls, conditional jumps, etc.  '
db 'wherever they might go.  To make this task easier, use the s-F1 and '
db 's-F2 keys.  To disassemble at the target of some instruction which '
db 'transfers control, place the instruction at the top of the disassembly '
db 'window and press s-F1.  For example, say at offset 1234 in the code '
db 'segment there is a CALL 5678.  Place the CALL at the top of the '
db 'disassembly window and press s-F1.  The disassembly window now '
db 'displays the code at 5678 with an invisible bookmark left at the '
db 'return address 1234.  Each time s-F1 is used, it leaves a bookmark at '
db 'the instruction at the top of the disassembly window and disassembles '
db 'at that instruction''s target.  To return to the previous bookmark, '
db 'press s-F2.  386SWAT supports up to 128 nested levels of such '
db 'disassembly.',CR
db CR
db 'As another example, you should be able to disassemble almost any '
db 'interrupt (say, U .VMI21 which disassembles at VM interrupt 21h), and '
db 'using the bookmark feature exclusively, go down to the bottom of the '
db 'chain.',CR
db CR
db 'This feature is clever, but not that clever.  It can figure out where '
db '(say) JMP Dword Ptr CS:[1234] is going and disassemble at that target, '
db 'but it can''t figure out the same instruction with a DS override.  Nor '
db 'can it handle effective addresses other than ones with an immediate '
db 'displacement only (i.e., no registers such as [BX+SI]).',CR


;===============================================================================
SYMNAME HELP_AFL,@HAFL_NCOL,@HAFL_NROW ; Name this section
INDENT 0
db 'Have you ever been puzzled by some CPU fault as to why it occurred, '
db 'that is, why did the CPU think there was a problem?  If so, this '
db 'feature is for you.  Whenever 386SWAT is called on the difficult to '
db 'figure out CPU faults (TSS Fault, Stack fault, GP Fault, or Page '
db 'Fault), the Autofault feature attempts to determine why and to present '
db 'a short prose description of the cause.  The description is displayed '
db 'in the lower lefthand corner of the screen.  Pressing a key causes the '
db 'message to disappear.  To display it again (up to the time another '
db 'fault occurs), press s-F4.',CR
db CR
db 'This feature is implemented for GP, TSS, and Page Faults.',CR


;===============================================================================
SYMNAME HELP_SRCH,@HSRCH_NCOL,@HSRCH_NROW ; Name this section
INDENT 0
db 'The various ways of searching for data are described here.',CR
db CR
db 'To search through normal data, code, or PTEs, use the S command:',CR
db CR
db '   S addr1 addr2 tgt ',CR
db 'which searches from addr1 to addr2 for tgt, or the alternate form',CR
db '   S addr L len tgt ',CR
db 'which searches from addr1 for len bytes for tgt.',CR
db CR
db 'The search results are '
db 'displayed on a separate screen which may be made '
db 'active at other times by pressing F6.  Only the '
db 'first 23 matches are displayed.  In a future release the Up, Down, '
db 'Page Up, and Page Down keys might allow scrolling through successive '
db 'matches.  The target may take one of several forms depending upon '
db 'whether you are searching for data (as bytes, words, or dwords), '
db 'code, or a specific PTE:',CR
db CR
INDENT 2
db '* Use a target of the form xx, xxxx, xxxxxxxx where x represents a hex '
db 'digit to search for bytes, words, or dwords of a specified value.  '
db 'For example, the form S 0:0 L FFFF 10CD searches for all occurrences '
db 'of the hex bytes CD followed by 10 in the first 64KB of conventional '
db 'memory.  Word and dword searches do not require word or dword '
db 'alignment of the matching data.',CR
db CR
db '* Use a target of the form "search_string" to search for a case '
db 'sensitive string.  For example, S 0:0 L FFFF "386MAX" searches for '
db 'all occurrences of the string 386MAX in the first 64KB of conventional '
db 'memory.  The ability to search for a case insensitive string will be added '
db 'in the future.',CR
db CR
db '* Use a target of the form !instr to search for a specific assembler '
db 'instruction.  For example, S 0:0 L FFFF !INT 10 searches for all '
db 'occurrences of video interrupt calls in the first 64KB of conventional '
db 'memory.  This target is found by disassembling the code between the '
db 'start and stop addresses instruction by instruction, thus the '
db 'alignment of the matching instructions and the starting address is '
db 'critical.  If data appears within that range, some matches may be '
db 'missed.  The command S1 (instead of S) can be used to disassemble '
db 'the code byte by byte.  That is, with the S command, having '
db 'disassembled an instruction which does not match the specified '
db 'pattern, the next instruction is searched; with the S1 command, the '
db 'next byte is searched.',CR
db CR
db '  The code search text may include one or more question marks as '
db 'wildcards which match any character in the disassembled '
db 'instructions. For example, use S 50|0 FFFF !mov e??,cr? to find '
db 'all moves from a control register to a 32-bit register.  Try the '
db 'forms S 3BC7:100 FFFF !mov [1234] and S 3BC7:100 FFFF !mov ?s:[1234] '
db 'to find all moves into location [1234] with or without a segment '
db 'override.  To find jumps to a specific location, use the code '
db 'targets !j? 1234, !j?? 1234, and !j??? 1234.  Note that floating '
db 'point instructions may be disassembled beginning with either ''F'' or '
db '''FN'' depending upon the presence of a preceding WAIT opcode (9Bh).  '
db 'To be safe, search for both.',CR
db CR
db '* Use a target of the form #PTE to search for a PTE in the Page '
db 'Tables.  For example, S 0 C0000000 # CF4000 searches for the PTE '
db 'CF4000 from linear 0 through linear C0000000.  The linear addresses '
db 'are both rounded down to a 4KB boundary.  A match at a particular '
db 'linear address means that the PTE was found and it covers the 4KB '
db 'block at the linear address displayed.  When comparing PTEs, the '
db 'flag bits are ignored, thus a match might be found when the PTE in '
db 'the Page Tables is not present.',CR
db CR
db 'To display the search screen, press F6.',CR
db CR
INDENT 0
db 'To search through the Windows Global Heap (WGH) for a specific entry, '
db 'use the SGH command: ',CR
db CR
db '  SGH [/b|/s|/h|/o] [/c] expr ',CR
db CR
db 'The expression (expr) entered is interpreted as a base address if /b '
db 'is specified, size if /s, handle if /h, and owner if /h.  If /c is '
db 'specified, the search continues from the currently displayed entry; '
db 'otherwise, the search starts at the top of the heap.  If the value '
db 'is found in the WGH, the WGH is displayed with the matching entry at '
db 'the top of the screen.  If you wish to repeat the search (perhaps '
db 'becayse there are multiple entries with the same owner), either '
db 'retype the command (and specify /c so the search continues with the '
db 'next entry after the one at the top of the screen), or start the '
db 'command with a slash so it is not erased after successful execution.  '
db 'If the value is not found in the WGH, an error message is displayed.  '
db CR
db 'To search for a particular linear address in the Page Tables (rather '
db 'than scrolling through many miles of PTEs), use',CR
db CR
db '  SPTE addr/val',CR
db CR
db 'This command is the same as the PTE command (which displays the '
db 'Page Directory and Page Table entries), but also displays the matching '
db 'PTE in the PTE display screen (F5).',CR
INDENT 0


;===============================================================================
SYMNAME HELP_WKD,@HWKD_NCOL,@HWKD_NROW ; Name this section
INDENT 0
db 'The various Windows-specific commands are described here.',CR
db CR
INDENT 2
db '* To enable or disable WKD services entirely, use',CR
db CR
db '      WKD [ON|OFF]',CR
db CR
db '  This option is available outside Windows only.  If you have '
db 'specified NOWINK in the 386SWAT profile, this option has no effect '
db '-- you must remove that profile option and reboot the system to '
db 'enable WKD services.',CR
db CR
db '* To change the response to a parameter error, use',CR
db CR
db '      WKD [NOISY|QUIET]',CR
db CR
db '  If NOISY is specified, then each parameter error is followed by the '
db 'prompt "Break, Ignore, Quiet?" to which you must respond B, I, or '
db 'Q.',CR
db CR
db '  A response of Q, is equivalent to setting WKD QUIET after which '
db 'parameter errors are logged to the screen, but execution does not '
db 'stop for any more parameter errors until you break into 386SWAT and '
db 'type WKD NOISY on 386SWAT''s command line.  This is the default '
db 'state, so you''ll see parameter errors fly past on the mono screen '
db 'without pause.  I recommend that when you are debugging your own '
db 'code, use WKD NOISY; otherwise, use WKD QUIET.  This is because many '
db 'commercial packages contain so many parameter errors that you''ll '
db 'constantly be interrupted with a BIQ prompt.',CR
db CR
db '  A response of I, ignores this one error only and continues '
db 'execution.',CR
db CR
db '  A response of B, triggers a single step breakpoint at an IRETD '
db 'inside 386SWAT.  Tracing over this instruction returns to the '
db 'instruction inside Windows immediately following the call to '
db '386SWAT (typically an INT 41h).  Tracing from this point on '
db 'eventually gets you back to a call to LogError which was called by '
db 'the Windows API function which encountered the invalid parameter, '
db 'and then back to the application which called the Windows API with '
db 'an invalid parameter.  If the application is Win32, then you''ll have '
db 'to trace back through a thunking layer before you get to the '
db 'application.  This can be quite tricky.  At some point, I''ll try to '
db 'put in some stack tracing to aid this process.',CR
db CR
db '* Sometimes Windows and/or applications make direct calls to LogError '
db 'as opposed to indirect calls as part of a parameter error.  These '
db 'calls are uncommon, so there is a separate switch to control '
db '386SWAT''s response to such an event.  Use ',CR
db CR
db '      WKD LOGERROR [ON|OFF]',CR
db CR
db '  to change the response of stopping at an IRETD inside 386SWAT or '
db 'not.  The default setting is OFF. ',CR
db CR
db '* Sometimes an application is bad enough that it triggers an '
db 'unrecoverable fault (typically a GP or Page Fault) and it must be '
db 'terminated.  Windows gives the WKD a crack at it first to which '
db '386SWAT responds by stopping in the application at the faulting '
db 'instruction, thus giving you the opportunity to debug the problem.  '
db 'If you wish to tell Windows to handle the fault itself (typically '
db 'by terminating the application), use ',CR
db CR
db '      WKD FAULT SKIP',CR
db CR
db '  If you do not want to receive any more fault messages from Windows, '
db '  use ',CR
db CR
db '      WKD FAULT OFF',CR
db CR
db '  To restart receiving fault messages, use ',CR
db CR
db '      WKD FAULT ON',CR
db CR
db '* The keystroke Ctrl-K brings up a menu from which you can choose to '
db 'display various internal Windows structures.  At the moment, the '
db 'only one which has been fleshed out is the display of the Windows '
db 'Global Heap (WGH).  The WGH contains one entry for each globally '
db 'allocated region of memory.  For example, the various code and data '
db 'segments of KRNL386.EXE are global allocations and have entries in '
db 'this table.  To scroll through this table, use the usual up and down '
db 'arrow keys as well as Page Up and Page Down. ',CR
db CR
db '  To search through the WGH for a specific entry, use ',CR
db CR
db '      SGH [/b|/s|/h|/o] [/c] expr',CR
db CR
db '  The expression (expr) entered is interpreted as a base address if /b '
db 'is specified, size if /s, handle if /h, and owner if /h.  If /c is '
db 'specified, the search continues from the currently displayed entry; '
db 'otherwise, the search starts at the top of the heap.  If the value '
db 'is found in the WGH, the WGH is displayed with the matching entry at '
db 'the top of the screen.  If you wish to repeat the search (perhaps '
db 'becayse there are multiple entries with the same owner), either '
db 'retype the command (and specify /c so the search continues with the '
db 'next entry after the one at the top of the screen), or start the '
db 'command with a slash so it is not erased after successful execution.  '
db 'If the value is not found in the WGH, an error message is displayed.',CR
db CR
db '* If Invalid Page Faults are being trapped by 386SWAT''s VxD (see '
db 'SWATVXD.DOC for more details), use the IPF command to control how '
db 'these events are to be handled. ',CR
db CR
db '      IPF [/d] [/s] [/r] expr',CR
db CR
db '  where /d tells 386SWAT not to display a message on the mono screen '
db 'describing this event, /s tells 386SWAT not to stop when this event '
db 'occurs, /r tells 386SWAT to remove this entry from its local tables, '
db 'and expr is an expression which evaluates to a linear address '
db 'corresponding to the Invalid Page Fault.  ',CR
db CR
db '* To display an area of memory as a Module Database (MDB), use the '
db 'command',CR
db CR
db '      MDB expr',CR
db CR
db '  where expr represents a selector which correponds to the MDB.',CR
db CR
db '* To display an area of memory as a Task Database (TDB), use the '
db 'command',CR
db CR
db '      TDB expr',CR
db CR
db '  where expr represents a selector which correponds to the TDB.',CR
INDENT 0


; NEW TOPIC GOES HERE
;===============================================================================
; SYMNAME HELP_???,@H???_NCOL,@H???_NROW ; Name this section

EOT					; End of text

RAWOUT <'WTXT    ends                   ; End WTXT segment'>

RAWOUT <"        end">

	end	START
