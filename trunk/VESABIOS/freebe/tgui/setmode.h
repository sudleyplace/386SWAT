/* Copyright 1998 (c) by Salvador Eduardo Tropea
   This code is part of the FreeBE/AF project you can use it under the
terms and conditions of the FreeBE/AF project. */
/***** Flags used in the video mode structure *****/
/* b0-b1 */
#define NHSync 1
#define NVSync 2
#define PHSync 0
#define PVSync 0
/* b2-b3 */
#define DoubleScan 4
#define TripleScan 8
#define QuadrupleScan 0xC
/* b4-b6 */
#define BPP8  0x00
#define BPP15 0x10
#define BPP16 0x20
#define BPP24 0x30
/* b7 */
#define Interlaced 0x80
/* b31 */
#define HaveAccel2D  0x80000000
/* This mask erase all the flags passed in the CRTC structure */
#define InternalMask 0xFFFFFF70

#define ExtractBPP(a) ((a & 0x70)>>4)
#define is8BPP  0
#define is15BPP 1
#define is16BPP 2
#define is24BPP 3

/**** Video mode structure ****/
typedef struct
{
 int flags;
 ushort hDisplay,hSyncStart,hSyncEnd,hTotal;
 ushort vDisplay,vSyncStart,vSyncEnd,vTotal;
 ushort minBytesPerScan;
 uchar ClockType;
 uchar ClockValHigh,ClockValLow;
} VideoModeStr;

extern VideoModeStr *SupportedVideoModes[];
extern int NumSupportedVideoModes;
extern short SupportedVideoModesNums[];

#ifdef __cplusplus
extern "C" {
#endif
void CaptureSVGAStart(void);
void Set640x480x8bpp(void);
int  GetBestPitchFor(int BytesPerScan, int BytesPerPixel);
void SetVideoModeH(VideoModeStr *modeInfo, int width, int bpp);
void SetTextModeVGA(void);
void ReadVSync(int *start, int *end);
void SetVSync(int start, int end);
#ifdef __cplusplus
}
#endif

