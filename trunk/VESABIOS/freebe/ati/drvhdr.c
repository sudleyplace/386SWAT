/*
 *       ______             ____  ______     _____  ______ 
 *      |  ____|           |  _ \|  ____|   / / _ \|  ____|
 *      | |__ _ __ ___  ___| |_) | |__     / / |_| | |__ 
 *      |  __| '__/ _ \/ _ \  _ <|  __|   / /|  _  |  __|
 *      | |  | | |  __/  __/ |_) | |____ / / | | | | |
 *      |_|  |_|  \___|\___|____/|______/_/  |_| |_|_|
 *
 *
 *      VBE/AF driver header, used as input for DRVGEN.
 *
 *      See freebe.txt for copyright information.
 */


#include "vbeaf.h"



AF_DRIVER drvhdr =
{
   "VBEAF.DRV",                                             /* Signature */
   0x200,                                                   /* Version */
   0,                                                       /* DriverRev */
   "FreeBE/AF ATI 18800/28800 driver " FREEBE_VERSION,      /* OemVendorName */
   "This driver is free software",                          /* OemCopyright */
   NULL,                                                    /* AvailableModes */
   0,                                                       /* TotalMemory */
   0,                                                       /* Attributes */
   0,                                                       /* BankSize */
   0,                                                       /* BankedBasePtr */
   0,                                                       /* LinearSize */
   0,                                                       /* LinearBasePtr */
   0,                                                       /* LinearGranularity */
   NULL,                                                    /* IOPortsTable */
   { NULL, NULL, NULL, NULL },                              /* IOMemoryBase */
   { 0, 0, 0, 0 },                                          /* IOMemoryLen */
   0,                                                       /* LinearStridePad */
   -1,                                                      /* PCIVendorID */
   -1,                                                      /* PCIDeviceID */
   -1,                                                      /* PCISubSysVendorID */
   -1,                                                      /* PCISubSysID */
   0                                                        /* Checksum */
};

