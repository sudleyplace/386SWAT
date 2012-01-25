/*
 *       ______             ____  ______     _____  ______ 
 *      |  ____|           |  _ \|  ____|   / / _ \|  ____|
 *      | |__ _ __ ___  ___| |_) | |__     / / |_| | |__ 
 *      |  __| '__/ _ \/ _ \  _ <|  __|   / /|  _  |  __|
 *      | |  | | |  __/  __/ |_) | |____ / / | | | | |
 *      |_|  |_|  \___|\___|____/|______/_/  |_| |_|_|
 *
 *
 *      Startup and relocation code.
 *
 *      See readme.txt for copyright information.
 */



.data

.globl _hdraddr,_reladdr

_hdraddr: .long 0
_reladdr: .long 0


.text

.globl StartDriver, PlugAndPlayInit, OemExt



/* helper for relocating the driver */

#define DO_RELOCATION()                                                      \
									   ; \
   movl %ebx, _reladdr(%ebx)     /* store relocations */                   ; \
   movl %edx, _hdraddr(%ebx)                                               ; \
									   ; \
   movl 876(%edx), %ecx          /* get relocation count */                ; \
   jecxz 1f                                                                ; \
									   ; \
   pushl %esi                    /* get relocation data */                 ; \
   leal 880(%edx), %esi                                                    ; \
   cld                                                                     ; \
									   ; \
 0:                                                                        ; \
   lodsl                                                                   ; \
   addl %ebx, (%ebx, %eax)                                                 ; \
   loop 0b                                                                 ; \
									   ; \
   popl %esi                     /* relocation is complete */



/* Entry point for the standard VBE/AF interface. When used with our
 * extension mechanism, the driver will already have been relocated by
 * the OemExt function, so this routine must detect that and do the
 * right thing in either case. After sorting out the relocation, it
 * chains to a C function called SetupDriver.
 */
PlugAndPlayInit:
   movl %ebx, %edx               /* save base address in %edx */
   movl 576(%ebx), %eax          /* retrieve our actual address */
   subl $PlugAndPlayInit, %eax   /* subtract the linker address */
   addl %eax, %ebx               /* add to our base address */

   cmpl $0, _reladdr(%ebx)       /* quit if we are already relocated */
   jne 1f

   DO_RELOCATION()               /* relocate ourselves */

 1:
   pushl %edx                    /* do high-level initialization */
   call _SetupDriver
   popl %edx
   ret



/* Driver init function. This is just a wrapper for the C routine called
 * InitDriver, with a safety check to bottle out if we are being used
 * by a VBE/AF 1.0 program (in that case, we won't have been relocated yet
 * so we must give up in disgust).
 */
StartDriver:
   pushl %ebx                    /* check that we have been relocated */
   movl 412(%ebx), %eax
   subl $StartDriver, %eax
   addl %eax, %ebx
   cmpl $0, _reladdr(%ebx)
   je 0f

   call _InitDriver              /* ok, this program is using VBE/AF 2.0 */
   popl %ebx
   ret

 0:
   movl $-1, %eax                /* argh, trying to use VBE/AF 1.0! */
   popl %ebx
   ret



/* Extension function for the FreeBE/AF enhancements. This will be the
 * very first thing called by a FreeBE/AF aware application, and must
 * relocate the driver in response. On subsequent calls it will just 
 * chain to the C function called FreeBEX.
 */
OemExt:
   cmpl $0x494E4954, 8(%esp)     /* check for FAFEXT_INIT parameter */
   jne 2f

   pushl %ebx
   movl 8(%esp), %ebx            /* read driver address from the stack */
   movl %ebx, %edx               /* save base address in %edx */
   movl 580(%ebx), %eax          /* retrieve our actual address */
   subl $OemExt, %eax            /* subtract the linker address */
   addl %eax, %ebx               /* add to our base address */

   cmpl $0, _reladdr(%ebx)       /* quit if we are already relocated */
   jne 1f

   addl %edx, 580(%edx)          /* relocate the OemExt pointer */

   DO_RELOCATION()               /* relocate the rest of the driver */

 1:
   popl %ebx
   movl $0x45583031, %eax        /* return FAFEXT_MAGIC1 */
   ret

 2:
   jmp _FreeBEX                  /* let the driver handle this request */
