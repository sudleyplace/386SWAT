;
;  To do, need to identify MONO monitors, and overwite vBase w/B000
;  also, write a C prog to align the ;'s
;  also, write a C prog that will pull out the comments, w/the line number
;  so I can spell check them, and then let the C prog put in the updated
;  comments
;
MODEL SMALL
Stack 256

dataseg
     attrib   equ   07h
     exitcode db    0	  ; exit code for installation program

     KFlagsSeg equ 0040h   ; The segment for DOS stuff
     KFlagsOff equ 0017h   ; Where the keyboard flags are


codeseg

	Public	Start,StartRes
Start:		; This is an old label, we now use END INIT
     jmp   init
StartRes:	; Resident portion here

      sti			 ; enable interrupts
      dec   cs:counter
      jnz   ExitTSR		 ; If the counter is not zero, exit
      mov   cs:counter, 6*18  ; Reset the counter
      push  ax
      push  bx
      push  cx
      push  dx

      push  es
      push  di

      push  ds
      push  si

      jmp   AfterVars		 ; Will put vars w/ TSR code, DOSSEG may have been
				 ; Screwing with me.

	Public	 vBase,Pressed,NotPressed,Counter,OldInt1C
    vBase	  dw 0b800h	 ; define video base

    Pressed	  db 'Ins'       ; Message to print when ins is pressed
    LenPressed =  $ - pressed	 ; Len of message

    NotPressed	  db '   '       ; Message to print when ins is NOT pressed
    LenNotPressed = $ - notPressed  ; Len of message

    counter	  db 6	  ; Set to 18 decimal

    OldInt1C  dd 0  ; Holder for previous int 1C vectors

	Public	AfterVars
AfterVars:
      mov   cx, LenNotPressed	   ; Setup the length
      mov   si, offset NotPressed  ; Setup the NotPressed message

      mov   al,   [KFlagsSeg:KFlagsOff]     ; Move the kboard flag into al
      and   al, 80h	 ; This will isolate the Ins bit
      jz    SkipAlt	; If its Zero skip setting up the INS message

	Public	Alt_key,SkipAlt,Top
Alt_Key:
      mov   si, offset Pressed

SkipAlt:
      mov	 es,	[vBase]  ; set up the video BASE
      mov	 di,	2*70	 ; setup where to start printing

top:
    ; use loadsb
      mov	 ah,	[cs:si]  ; read the charactor to print
      mov	 [es:di],  ah	 ; display it

      inc	 di   ; move the next video spot
      inc	 di   ; move past the video attribute
      inc	 si   ; move to the next piece of data
      loop top

      pop   si
      pop   ds

      pop   di
      pop   es

      pop   dx
      pop   cx
      pop   bx
      pop   ax

	Public	ExitTSR
ExitTSR:
      jmp   oldint1c	; transfer control to other int 1C handler



;
;!!!!!!!!!!!	       End of TSR portion, installation follows
;

keep = $ ; Store how much to keep (later turned to para)

	Public	Initial,Init
; TASM ideal mode won't take (offset Initial)
Initial	label	byte
Init:
      int   03h 	  ; Kick in SWAT if it is arround
      mov   ax, @data
      mov   ds, ax
      mov   es, ax	  ; es,ds,ax are all equal to @data

; Ask DOS for current interrupt vector for 1C

      push  es		  ; Preserve es
      mov  ah, 35h	  ; Get interrupt function
      mov  al, 1Ch	 ; Interrupt to get
      int  21h		  ; Let DOS get the vector
      mov  word ptr OLDINT1C,	bx ; Save the offset
      mov  word ptr OLDINT1C+2, es ; ... and the segment
      pop  es		  ; Restore es

;
;    Get ready to install my stuff
;
     push  ds			; Preserve ds
     mov   ah, 25h		; Install interrupt function
     mov   al, 1Ch		; Interrupt to install
     push  cs			; Get the codeseg and,
     pop   ds			; Put Code Seg into ds
     mov   dx, offset StartRes	; dx if offset for interrupt
     int   21h			; Do the deed, we are now installed
     pop   ds			; Restore ds

     int   1Ch		  ; force a timer update so debugger will go through code

exit:
;  User the function 31 of int 21 per Henry's suggestion
;      mov   ax, 1Ah   ; keep the correct amount
 ;     mov   dx, ax	; Tell DOS what to keep
      lea   dx,Initial[15]	; Next even paragraph after resident code
      mov   ah, 31h	 ; keep function
      int   21h 	       ; go TSR

    END   start  ; where to start executing
