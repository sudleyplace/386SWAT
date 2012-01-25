/* Copyright 1998 (c) by Salvador Eduardo Tropea
   This code is part of the FreeBE/AF project you can use it under the
terms and conditions of the FreeBE/AF project. */
/*****************************************************************************

  ROUTINES to store/retrieve the VGA and TGUI registers.

*****************************************************************************/

#include <pc.h>
#include "mytypes.h"
#include "regs.h"
#include "vga.h"
#include "tgui.h"

//#include <stdio.h>

/**[txh]********************************************************************

  Description:
  This routines captures the TGUI registers in an array. Not all are stored
because isn't needed by now. In fact I'm storing a lot of registers that
are not needed to store.

***************************************************************************/

void TGUI9440SaveRegs(uchar *regs)
{
 int Old_New;
 int i,Protect,DACaccess,DACaddress;

 /* Extended Sequencer */
 /* 8 is an status (old/new mode, field under scaning, FIFO in use) */
 Old_New=ReadSEQ(8);
 regs[OldNewStatus]=Old_New;
 /* 9 is the revision code, A reserved, B chip ID */
 /* Enter in old mode */
 WriteSEQ(0xB,0);
 regs[ESEQ_0D_old]=ReadSEQ(0xD);
 regs[ESEQ_0E_old]=ReadSEQ(0xE);
 regs[EGRA_0E_old]=ReadGRA(0xE);
 /* Enter in new mode */
 ReadSEQ(0xB);
 regs[ESEQ_0D_new]=ReadSEQ(0xD);
 //fprintf(stderr,"Lectura: %X %X\n",ReadSEQ(0x8),ReadSEQ(0xD));
 Protect=
 regs[ESEQ_0E_new]=ReadSEQ(0xE);
 regs[ESEQ_0F]    =ReadSEQ(0xF);
 /* Unprotect the registers */
 WriteSEQ(0xE,Protect | 0x80);

 DACaccess=
 regs[EGRA_0F]=ReadGRA(0xF);
 regs[EGRA_23]=ReadGRA(0x23);
 regs[EGRA_2F]=ReadGRA(0x2F);
 /* Enable access to the DAC */
 WriteGRA(0xF,DACaccess | 4);

 /* These are alternative registers so I don't know if I really need to
    store your content */
 regs[ALT_BNK_WRITE]=inportb(0x3D8);
 regs[ALT_BNK_READ] =inportb(0x3D9);
 regs[ALT_CLK]      =inportb(0x3DB);


 /* These extended register are located in the CRT space but they aren't
    contiguous */
 regs[ECRTbase]=ReadCRT(0x19);   // 0  (0x19)
 for (i=1; i<14; i++)
     regs[ECRTbase+i]=ReadCRT(0x1D+i);  // 1-13 (0x1D-0x2A)
 regs[ECRTbase+i]=ReadCRT(0x2C); // 14
 i++;
 regs[ECRTbase+i]=ReadCRT(0x2F); // 15
 i++;
 regs[ECRTbase+i]=ReadCRT(0x30); // 16
 for (i++; i<24; i++)
     regs[ECRTbase+i]=ReadCRT(0x22+i); // 17-23
 for (; i<32; i++)
     regs[ECRTbase+i]=ReadCRT(0x28+i); // 24-31
 regs[ECRTbase+i]=ReadCRT(0x50); // 32

 /* Map the DAC safetly (0x3C6 so doesn't overlap others) */
 DACaddress=ReadCRT(0x29);
 WriteCRT(0x29,DACaddress & 0xFC);
 regs[DAC_3C6]    =inportb(0x3C6);
 inportb(0x3C6); inportb(0x3C6); inportb(0x3C6);
 regs[DAC_3C6_4th]=inportb(0x3C6);
 regs[DAC_WR_ADD] =inportb(0x3C8);
 regs[MCLKLOW]    =inportb(0x43C6);
 regs[MCLKHIG]    =inportb(0x43C7);
 regs[VCLKLOW]    =inportb(0x43C8);
 regs[VCLKHIG]    =inportb(0x43C9);
 regs[DAC_INDEX]  =inportb(0x83C8);

 for (i=0; i<EDACcant; i++)
     regs[EDACbase+i]=ReadEDAC(i);

 /* The GER */
 /* Enable it and map in memory */
 WriteCRT(0x36,MODEINIT);
 regs[GER_22]=Getb(0x22);
 regs[GER_23]=Getb(0x23);
 *((unsigned *)&regs[GER_44])=Getl(0x44);
 WriteCRT(0x36,regs[ECRT_36]);

 /* Restore the DAC mapping */
 WriteCRT(0x29,DACaddress);
 /* Restore the DAC access */
 if ((DACaccess & 4)==0)
    WriteGRA(0xF,DACaccess);
 /* Restore the protection */
 if ((Protect & 0x80)==0)
    WriteSEQ(0xE,Protect);
 /* Restore the old/new mode */
 if ((Old_New & 0x80)==0)
    WriteSEQ(0xB,0);
}

/**[txh]********************************************************************

  Description:
  This function stores ALL the VGA registers in an array. Additionally it
calls to the routine that stores the TGUI registers around 120 registers
are stored.

***************************************************************************/

int VGASaveRegs(uchar *regs, uchar *Sregs)
{
 int i;
 uchar MORval;

 /* I'm trying to do this routine as strong and generic as possible
    without loosing performance.
    So I ever put the VGA chip in the color mode (ports=0x3Dx) but I
    store the real state */
 MORval=ReadMOR();
 WriteMOR(MORval | 1);
 regs[MORbase]=MORval;

 /* I think the best place to put a call to save the chipset specific
    registers is here because TGUI9440 can save some interesting things
    about the VGA registers. For example: 3x4/5.24.b7 is the current
    state of "Attribute Address Register" (3C0: address or data), that's
    impossible to know in a VGA card. */
 TGUI9440SaveRegs(Sregs);

 for (i=0; i<CRTcant; i++)
     regs[CRTbase+i]=ReadCRT(i);

 /******* The Attribute Registers are worst that a pain in the ass I think
	  the @#*$ people from the Giant Blue tried to make it hard to
	  understand on purpose ********/
 for (i=0; i<ATTcant; i++)
     regs[ATTbase+i]=ReadATT(i);
 ATTEndReads();

 for (i=0; i<GRAcant; i++)
     regs[GRAbase+i]=ReadGRA(i);

 for (i=0; i<SEQcant; i++)
     regs[SEQbase+i]=ReadSEQ(i);

 WriteMOR(MORval);

 return VGARegsCant;
}

/**[txh]********************************************************************

  Description:
  Restores the TGUI registers from an array.

***************************************************************************/

void TGUI9440LoadRegs(const uchar *regs)
{
 int i,Protect,DACaccess,DACaddress;

 /* Enter in old mode */
 WriteSEQ(0xB,0);
 WriteSEQ(0xD,regs[ESEQbase]);
 WriteSEQ(0xE,regs[ESEQbase+1]);
 WriteGRA(0xE,regs[EGRAbase]);
 /* Enter in new mode */
 ReadSEQ(0xB);
 WriteSEQ(0xD,regs[ESEQ_0D_new]);
 //fprintf(stderr,"Escritura: %X %X\n",ReadSEQ(0x8),ReadSEQ(0xD));
 /* Unprotect the registers */
 Protect=regs[ESEQbase+3];
 WriteSEQ(0xE,Protect | 0x80);
 WriteSEQ(0xF,regs[ESEQbase+4]);

 /* Enable access to the DAC */
 DACaccess=regs[EGRAbase+1];
 WriteGRA(0x0F,DACaccess | 4);
 WriteGRA(0x23,regs[EGRAbase+2]);
 WriteGRA(0x2F,regs[EGRAbase+3]);

 /* These are alternative registers so I don't know if I really need to
    store your content */
 outportb(0x3D8,regs[SPbase+1]);
 outportb(0x3D9,regs[SPbase+2]);
 //fprintf(stderr,"Escritura antes 3DB: %X %X\n",ReadSEQ(0x8),ReadSEQ(0xD));
 outportb(0x3DB,regs[SPbase+3]);
 //fprintf(stderr,"Escritura dopo: %X %X\n",ReadSEQ(0x8),ReadSEQ(0xD));


 /* These extended register are located in the CRT space but they aren't
    contiguous */
 WriteCRT(0x19,regs[ECRTbase]);   // 0  (0x19)
 for (i=1; i<14; i++)
     WriteCRT(0x1D+i,regs[ECRTbase+i]);  // 1-13 (0x1D-0x2A)
 WriteCRT(0x2C,regs[ECRTbase+i]); // 14
 i++;
 WriteCRT(0x2F,regs[ECRTbase+i]); // 15
 i++;
 WriteCRT(0x30,regs[ECRTbase+i]); // 16
 for (i++; i<24; i++)
     WriteCRT(0x22+i,regs[ECRTbase+i]); // 17-23
 for (; i<32; i++)
     WriteCRT(0x28+i,regs[ECRTbase+i]); // 24-31
 WriteCRT(0x50,regs[ECRTbase+i]); // 32

 /* Map the DAC safetly (0x3C6 so doesn't overlap others) */
 DACaddress=regs[ECRT_29];
 WriteCRT(0x29,DACaddress & 0xFC);

 inportb(0x3C8);
 outportb(0x3C6,regs[DAC_3C6]);

 inportb(0x3C8);
 inportb(0x3C6); inportb(0x3C6); inportb(0x3C6); inportb(0x3C6);
 outportb(0x3C6,regs[DAC_3C6_4th]);

 outportb(0x3C8,regs[SPbase+6]);
 outportb(0x43C6,regs[SPbase+7]);
 outportb(0x43C7,regs[SPbase+8]);
 outportb(0x43C8,regs[SPbase+9]);
 outportb(0x43C9,regs[SPbase+10]);
 outportb(0x83C8,regs[SPbase+11]);

 for (i=0; i<EDACcant; i++)
     WriteEDAC(i,regs[EDACbase+i]);

 /* The GER */
 /* Enable it and map in memory */
 WriteCRT(0x36,MODEINIT);
 Putb(0x22,regs[GER_22]);
 Putb(0x23,regs[GER_23]);
 Putl(0x44,*((unsigned *)&regs[GER_44]));
 WriteCRT(0x36,regs[ECRT_36]);

 /* Restore the DAC mapping */
 WriteCRT(0x29,DACaddress);
 /* Restore the DAC access */
 if ((DACaccess & 4)==0)
    WriteGRA(0xF,DACaccess);
 /* Restore the protection */
 if ((Protect & 0x80)==0)
    WriteSEQ(0xE,Protect);
 /* Restore the old/new mode */
 if ((regs[OldNewStatus] & 0x80)==0)
    WriteSEQ(0xB,0);
}

/**[txh]********************************************************************

  Description:
  Restores the VGA registers from an array.

***************************************************************************/

void VGALoadRegs(const uchar *regs,const uchar *Sregs)
{
 int i;
 uchar CRT11,MORval;

 MORval=ReadMOR();
 /* Ensure we are in the color mode or the ports could be moved to 0x3Bx */
 WriteMOR(MORval | 1);
 /* Wait a full retrace to avoid extra noise in screen */
 while (inportb(0x3DA) & 8);
 while (!(inportb(0x3DA) & 8));

 /* Screen Off to avoid funny things displayed */
 WriteSEQ(0x01,regs[SEQbase+1] | 0x20);

 /* Synchronous reset ON, we must do it or we could lose video RAM contents */
 WriteSEQ(0x00,1);
 for (i=2; i<SEQcant; i++)
     WriteSEQ(i,regs[SEQbase+i]);
 /* Synchronous reset restored */
 WriteSEQ(0x00,regs[SEQbase]);

 /* Deprotect CRT registers 0-7 */
 CRT11=regs[CRTbase+0x11];
 WriteCRT(0x11,CRT11 & 0x7F);
 /* write CRT registers */
 for (i=0; i<CRTcant; i++)
     if (i!=0x11)
	WriteCRT(i,regs[CRTbase+i]);
 /* Restore the protection state */
 WriteCRT(0x11,CRT11);

 for (i=0; i<GRAcant; i++)
     WriteGRA(i,regs[GRAbase+i]);

 /******* The Attribute Registers are worst that a pain in the ass I think
	  the @#*$ people from the Giant Blue tried to make it hard to
	  understand on purpose ********/
 /* Ensure we will write to the index */
 inportb(ATTdir);
 for (; i<ATTcant; i++)
     WriteATT(i,regs[ATTbase+i]);
 ATTEndReads();

 TGUI9440LoadRegs(Sregs);

 /* Restore MOR */
 WriteMOR(regs[MORbase]);

 /* Restore Screen On/Off status */
 WriteSEQ(0x01,regs[SEQbase+1]);
}

#ifdef INCLUDE_OLD_INERTIA_STUFF
/**[txh]********************************************************************

  Description:
  Returns the vertical sync start and end values. Not optimized because I
think that's a very strange stuff.

***************************************************************************/

void ReadVSync(int *start, int *end)
{
 int s,e,aux;

 s=ReadCRT(0x10);
 aux=ReadCRT(0x7);
 s|=((aux & 0x04)<<6); /* b8 */
 s|=((aux & 0x80)<<2); /* b9 */
 aux=ReadCRT(0x27);
 s|=((aux & 0x40)<<4); /* b10 */
 *start=s;
 /* Only 4 bits are available: */
 e=(s & 0xFFF0) | (ReadCRT(0x11) & 0xF);
 /* Adjust it */
 if (e<s)
    e+=0x10;
 *end=e;
}

/**[txh]********************************************************************

  Description:
  Sets the vertical sync start and end values. Not optimized because I
think that's a very strange stuff.

***************************************************************************/

void SetVSync(int start, int end)
{
 int a;

 WriteCRT(0x10,start);
 a=ReadCRT(0x7) & 0x7B;
 a|=((start & 0x100)>>6); /* b8 */
 a|=((start & 0x200)>>2); /* b9 */
 WriteCRT(0x7,a);
 a=ReadCRT(0x27) & 0xBF;
 a|=((start & 0x400)>>4); /* b10 */
 WriteCRT(0x27,a);
 WriteCRT(0x11,0x80 | (end & 0x0F));
}
#endif

/*
* means stored

 3C3    [No] (Hardware specific)
 46E8   [No] (Hardware specific)
*3C5.08 We must save b7 to recreate the old/new mode and manipulate it.
 3C5.09 [No!] (RO)
 3C5.0A [No] (Reserved)
 3C5.0B [No!] (RO)
 3C5.0C-1 [No] (Hardware specific)
 3C5.0C-2 [No] (BIOS reserved)
*3C5.0D-old [No] CB (Hardware specific)
*3C5.0E-old
*3CF.0E-old
*3C5.0D-new
*3C5.0E-new We must manipulate b7 for other registers (enable from here and
	   restart at the end).
 3CF.0E-new [No!] Have alternative and could mess the alternative.
*3C5.0F [No] (Hardware specific)
*3CF.0F We must enable b2 and restart at the end.
*3CF.23
*3CF.2F
*3D8
*3D9
*3DB
*3D5.19
*3D5.1E
*3D5.1F [No] CB (Reserved) BIOS stores the amount of memory here and the driver
       will read it just once so we don't need to save it.
*3D5.20
*3D5.21 [No] CB It contols the Linear Address but I can't understand how it
       works.
*3D5.22
*3D5.23 [No] CB It fine tunes the DRAM speed.
*3D5.24
*3D5.25
*3D5.26
*3D5.27
*3D5.28 [No] (Hardware specific)
*3D5.29 we must clear b0-1 and enable at the end to access the DAC.
*3D5.2A [No] (Hardware specific)
*3D5.2C
*3D5.2F
*3D5.30 [No] (Reserved)
*3D5.33
*3D5.34
*3D5.35
*3D5.36
*3D5.37 [No] (Hardware specific)
*3D5.38
*3D5.39 [No] (Hardware specific)
*3D5.40-47,50 Ok Hardware cursor.

*3C6
 Here comes a crazy thing: we read 3 times more 3C6
*3C6 (This time is a different value).

 3C7 [No!] the read back value isn't usefull
*3C8 Ok the read back is the address.
 3C9 [No!] we save the whole palette ;-)

*43C6-9
*83C8 That's the 83C6/8 index.
*83C6.00
*83C6.01
*83C6.02
*83C6.03
*83C6.04
 83C6.05 [No!] (RO)
 83C6.30 [No] The following are very optional:
 83C6.31 [No]
 83C6.32 [No]
 83C6.34 [No]
 83C6.35 [No]
 83C6.36 [No]
 83C6.37 [No]
 83C6.38 [No]
*GER.22
*GER.23 22-23 sets the pitch and offset of the operations
*GER.44-47 (patterned lines parameters)
The rest of the GER can change in any way because I set all the values from
call to call.
*/


