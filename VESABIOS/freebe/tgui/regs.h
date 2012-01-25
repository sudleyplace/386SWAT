/* Copyright 1998 (c) by Salvador Eduardo Tropea
   This code is part of the FreeBE/AF project you can use it under the
terms and conditions of the FreeBE/AF project. */

/*
 List of ports used:
 0x3C0,0x3C1,0x3C2,0x3C3,0x3C4,0x3C5,0x3C6,0x3C7,0x3C8,0x3C9,0x3CC,0x3CE,
 0x3CF,0x3D4,0x3D5,0x3DA
 TGUI:
 0x3D8,0x3D9,0x3DB,0x43C6,0x43C7,0x43C8,0x43C9,0x83C6,0x83C8
 0x2100-0x21FF
*/
/*  CRT (Cathode Rays Tube) Controller Registers
    They control the sync signals.
    0x00 to 0x18 */
// SVGALib and XFree86 uses <0x18 so they miss the line compare register,
// don't know why.
#define CRTbase  0
#define CRTcant  25
/*  ATT Attribute Controller Registers
    They control some attributes like 16 colors palette, overscan color, etc.
    0x00 to 0x14 */
#define ATTbase  (CRTbase+CRTcant)
#define ATTcant  21
/*  GRA Graphics Controller Registers
    They control the read/write mode to the video memory.
    0x00 to 0x08 */
#define GRAbase  (ATTbase+ATTcant)
#define GRAcant  9
/*  SEQ Sequence Registers
    They control how the memory is scanned.
    0x00 to 0x04 */
#define SEQbase  (GRAbase+GRAcant)
#define SEQcant  5
/*  MOR Miscellaneous Output Register
    1 register */
#define MORbase  (SEQbase+SEQcant)
#define MORcant  1

#define VGARegsCant (MORbase+MORcant)

/*  Status values: Here I store special status values that doesn't
    correspond to a physical register but to an operation plus some
    special registers */
#define SPbase 0
#define SPcant 12
#define OldNewStatus  SPbase+0
#define ALT_BNK_WRITE SPbase+1
#define ALT_BNK_READ  SPbase+2
#define ALT_CLK       SPbase+3
#define DAC_3C6       SPbase+4
#define DAC_3C6_4th   SPbase+5
#define DAC_WR_ADD    SPbase+6
#define MCLKLOW       SPbase+7
#define MCLKHIG       SPbase+8
#define VCLKLOW       SPbase+9
#define VCLKHIG       SPbase+10
#define DAC_INDEX     SPbase+11
/*  ESEQ Extra Sequence Registers
    0x08 to 0x0F (They have some tricks) */
#define ESEQbase (SPbase+SPcant)
#define ESEQcant 5
#define ESEQ_0D_old   ESEQbase+0
#define ESEQ_0E_old   ESEQbase+1
#define ESEQ_0D_new   ESEQbase+2
#define ESEQ_0E_new   ESEQbase+3
#define ESEQ_0F       ESEQbase+4
/*  ECRT Extra CRT Registers
    0x19 to 0x50 */
#define ECRTbase (ESEQbase+ESEQcant)
#define ECRTcant 33
#define ECRT_19 ECRTbase
#define ECRT_1E ECRTbase+1
#define ECRT_1F ECRTbase+2
#define ECRT_20 ECRTbase+3
#define ECRT_21 ECRTbase+4
#define ECRT_22 ECRTbase+5
#define ECRT_23 ECRTbase+6
#define ECRT_24 ECRTbase+7
#define ECRT_25 ECRTbase+8
#define ECRT_26 ECRTbase+9
#define ECRT_27 ECRTbase+10
#define ECRT_28 ECRTbase+11
#define ECRT_29 ECRTbase+12
#define ECRT_2A ECRTbase+13
#define ECRT_2C ECRTbase+14
#define ECRT_2F ECRTbase+15
#define ECRT_30 ECRTbase+16
#define ECRT_33 ECRTbase+17
#define ECRT_34 ECRTbase+18
#define ECRT_35 ECRTbase+19
#define ECRT_36 ECRTbase+20
#define ECRT_37 ECRTbase+21
#define ECRT_38 ECRTbase+22
#define ECRT_39 ECRTbase+23
#define ECRT_40 ECRTbase+24
#define ECRT_41 ECRTbase+25
#define ECRT_42 ECRTbase+26
#define ECRT_43 ECRTbase+27
#define ECRT_44 ECRTbase+28
#define ECRT_45 ECRTbase+29
#define ECRT_46 ECRTbase+30
#define ECRT_47 ECRTbase+31
#define ECRT_50 ECRTbase+32
/*  EGRA Extra Graphics Controller Registers
    0x0E, 0x0F, 0x23 and 0x2F */
#define EGRAbase (ECRTbase+ECRTcant)
#define EGRAcant 4
#define EGRA_0E_old EGRAbase
#define EGRA_0F     EGRAbase+1
#define EGRA_23     EGRAbase+2
#define EGRA_2F     EGRAbase+3
/* EDAC Extra DAC/Clk */
#define EDACbase  (EGRAbase+EGRAcant)
#define EDACcant  4
#define EDAC_00 EDACbase+0
#define EDAC_01 EDACbase+1
#define EDAC_02 EDACbase+2
#define EDAC_03 EDACbase+3
/* GER Graphics Engine Register. Only the relevant stuff */
/* 0x22 and 0x23 */
#define GERbase (EDACbase+EDACcant)
#define GERcant 6
#define GER_22  GERbase+0
#define GER_23  GERbase+1
#define GER_44  GERbase+2
#define GER_45  GERbase+3
#define GER_46  GERbase+4
#define GER_47  GERbase+5

#define SVGARegsCant (GERbase+GERcant)

#ifdef __cplusplus
extern "C" {
#endif
int  VGASaveRegs(uchar *regs, uchar *Sregs);
void VGALoadRegs(const uchar *regs,const uchar *Sregs);
void TGUI9440SaveRegs(uchar *regs);
void TGUI9440LoadRegs(const uchar *regs);
#ifdef __cplusplus
}
#endif


