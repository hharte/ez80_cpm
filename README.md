# CP/M 3.0 for the Zilog eZ80


# Introduction

This repository contains CP/M 3 for the [Zilog eZ80F91](https://www.zilog.com/index.php?option=com_product&task=product&businessLine=1&id=77&parent_id=77&Itemid=57) Development Kits.  This code was developed between 2005 and 2007.

In addition to the eZ80F91 Modular Development Kit, you will also need to [make an adapter card in order to use SD Memory Cards](https://raw.githubusercontent.com/hharte/ez80_cpm/main/Doc/mmc-to-ez80.png) with your eZ80F91 Modular Development Kit.  This adapter card consists of an SD Memory Card socket, and several passive components.  See the included schematic diagram for information on how to build this adapter board.  In addition to making the SD Adapter card, you will also have to modify your eZ80 Modular Development kit board to permanently enable the RS-232 Console port.  This is required, because one of the eZ80's GPIO pins that is required for the SD Card Interface is used by the stock eZ80F91 Modular Development Kit to enable and disable the Console serial port.  If you do not make this modification to your board, you will be able to see Console output on your serial terminal, but the eZ80F91 Kit will not be able to receive input from the Console Terminal.  See the attached schematic for information on how to make this simple wire modification to your eZ80F91 Modular Development Kit.


There are three platforms supported by this release:

1. eZ80SBC with Mini Ethernet Module (MDS): Zilog Part Number: EZ80F910100KIT

2. eZ80SBC with Full Size Ethernet Module (Platform)

3. Zilog Smart Serial Cable (ZSSC)

For each platform, there is a Debug and Release build.

The Debug build may contain extra debugging code, and is designed to run from RAM on the target.  The FLASH disk image must have been previously loaded on the FLASH by burning one of the Release builds.

The Release build is intended for burning the entire image to the FLASH.  This includes the Startup code, CCP,  BDOS, and CBIOS as well as the FLASH disk image.  During startup, the CCP, BDOS, and CBIOS are copied from FLASH to RAM, and executed from RAM.

The CP/M CCP, BDOS, and low-level SD card access routines are contained in CPM3LIB.LIB  This is linked with the CBIOS source to form a complete CP/M image.


# Required Tools

This package builds with [Zilog Developer Studio II version 4.11.1](https://www.driverguide.com/driver/detail.php?driverid=1365679) (md5sum: 46c660a7b8b154d66364385e7ccc6f68)  It will not work with previous versions of ZDS-II.   The [latest release of ZDS-II](https://www.zilog.com/index.php?option=com_zcm&task=sdlp&Itemid=74) (5.3.5) does not work as the linker generates “range errors.”


# Installation


## eZ80F91 Modular Development Kit


### Hardware Configuration



1. Use a Zilog eZ80F91 Modular Development Kit (the one with the "Mini" Ethernet module.)
2. Lift pin 1 of U6, and tie it to the left hand side of C9.  Left hand when viewing the silkscreen text in the readable direction. Without this mod, CP/M will still boot, and you'll get an A> prompt, but you won't be able to type anything.
3. Use a "straight through" DB9-M to DB9-F serial cable to connect the serial port of the eZ80F91 Modular Development Kit to the serial port on your PC.
4. Run and configure your favorite communication program to the following parameters:

    115200 baud, N, 8, 1, No Hardware flow control.

5. Attach a Zilog USB Smart Cable to the ZDI connector on the eZ80F91 MDS, and connect the USB end to your PC.
6. Apply power to the eZ80F91 MDS.
7. Burn CP/M to FLASH (See Below)
8. Disconnect the ZDI Cable from the eZ80F91 MDS and Press the Reset button or cycle power.  If the ZDI Cable is not unplugged, the eZ80F91 will be held in reset.
9. CP/M should boot up to an A> prompt, and the files in the A> directory are stored in the upper 128K of the eZ80F91's 256K of internal FLASH.
10. If you add an SD card adapter to the eZ80F91 MDK, you will have a B: drive, which is 128K in size, on the SD Card, and a C: and D: drive also on the FLASH card which are 8MB each.


### Burning the CP/M FLASH Image



1. Run Zilog Smart Flash Programmer v2.0.1. (ZdsFlash.exe)
2. Browse for the project "cpm22.zfpproj"
3. Click on the "Advanced Configuration" button.
4. Select "Communication" in the tree at the left.
5. Pick the communication type (ie, USB, and then check the box next to the serial number of your USB Download Cable.)
6. Now, press the Program/Verify button, and wait while the FLASH is erased and programmed.


# Serial Ports

The BIOS supports the second serial port on the eZ80F91; however, this port is not RS-232 on the eZ80F91 Modular Development Kit.  Instead, it is at low-voltage CMOS (3.3V) levels.  In order to use this port with the PC, it is possible to connect a TTL USB-Serial module to the eZ80F91 Modular Development Kit.

The communication parameters for the second serial port are the same as those for the Console port. This port works well with the generic version of CP/M Kermit-80.  When transferring files to/from a PC, you can use MS-DOS Kermit under Windows XP; however, MS-DOS kermit performs poorly under XP, and file transfers are relatively slow.  As an alternative, a native Win32 program that supports the Kermit file transfer protocol can be used.  One such program is HyperTerminal, included with Windows XP.


# SD Card Disk Images

The eZ80 can access SIMH/AltairZ80 HDSK images written to the SD Memory card. Download and install SIMH/AltairZ80 from:

	[http://www.schorn.ch/cpm/intro.html](http://www.schorn.ch/cpm/intro.html)

You can use SIMH to prepare an 8MB HDSK image for use with eZ80F91 CP/M 3.1.


## Using SD Memory Cards with CP/M

1. The SD Memory Card should be formatted with the FAT16 filesystem.  This can

   be accomplished with the FORMAT command under Windows XP as follows:

FORMAT x: /fs:fat - where x: is the drive letter of your SD Card Reader

                    or card slot on your PC.

   Many SD Cards are FAT-12 formatted from the factory, so this

   step is critical.

2. Copy SIMH/AltairZ80 disk images (up to four) to the SD card.

3. Boot CP/M on the eZ80F91 Kit, and at the A> prompt, execute

   the following command:

A>MOUNT C:

MOUNT V-0.62 (24-Sep-2006)

Drive C [ 0/0 ]

------------------------

512 bytes/sector

342 tracks

48 sectors per track

4096 byte block size

2043 block count

MBR on Track: 0, Sector: 1

Boot Sector on Track: 0, Sector: 1

FAT Information:

512 bytes per sector

2 sectors/cluster

4 reserved sectors

2 FATs

512 root directory entries

238 sectors/FAT

0 hidden sectors

480 root directory sector

512 data start sector

Root directory on Track: 10, Sector: 1

0: CPM3_C  DSK, Cluster: 0, abs Sector: 512 Mounted as C:

1: CPM3_D  DSK, Cluster: 8192, abs Sector: 16896 Mounted as D:

2: CPM3_E  DSK, Cluster: 16384, abs Sector: 33280 Mounted as E:

3: CPM3_F  DSK, Cluster: 24608, abs Sector: 49728 Mounted as F:

A>

4. At this point, up to four CP/M drives (C: through F:) may have

   been mounted, depending on how many DSK image files were on

   the SD card.


## Compatibility with SIMH/AltairZ80

The eZ80F91 Kit CP/M reads and writes HDSK files to be compatible with SIMH.  There are a couple differences between SIMH and the eZ80F91 Kit's access to these HDSK files:

1. The eZ80F91 Kit uses a 512-byte hardware sector size, not 128-bytes like SIMH.

2. The eZ80F91 Kit uses 192 records/track, whereas AltairZ80 uses 32.  For this reason, tracks are 24K on the eZ80F91, and 4K on SIMH.

Because of these differences, two of the utilities supplied with SIMH/AltairZ80 had to be modified:

XFORMAT.COM - Modified to support 512-byte physical sectors.  Also supports 128- and 256-byte sectors.

SHOWSEC.COM - Modified to support 512-byte physical sectors.  Also supports 128- and 256-byte sectors.

The modified versions of these programs are included on the eZ80F91's Internal 128K FLASH disk.


# Bugs and Limitations


## Real-Time Clock (clock.asm)

The Real-Time Clock is not supported properly.


## SD Memory Card Driver (sdmmcdrv.asm)

The MOUNT utility and the SD Memory Card Driver do not really understand the FAT filesystem fully.  The MOUNT utility is able to find the first sector of a given file on the SD card, but the driver does not understand FAT cluster chains, and cannot follow these chains.  For this reason, files on the SD card must be contiguous.  This can be accomplished by formatting the SD card with Windows, and then copying the files one at a time.

Because the MOUNT utility uses 16-bit arithmetic, it cannot mount a file on the SD card which is beyond 32 Megabytes from the beginning of the SD card.  This limitation is only because of the MOUNT utility, and is not a limitation of the CBIOS itself.

The SD Memory Card Driver does not support High-Capacity SD cards (SD-HC.)  The SD-HC cards are SD Memory Cards greater than 2GB.

Since the SD card support is primitive, does not fully understand the FAT filesystem, and contains little error checking, it is advisable to dedicate an SD card for use with this Kit, and not rely on this card for storage of other files.

1. Only .DSK image files starting in the first 32MB of the SD card can be mounted. It is ok for the .DSK image to cross the 32MB boundary.

2. DSK image files must be contiguous on the SD card (ie, not fragmented.)  For this reason, it is recommended to start with a freshly formatted SD card.

3. Do Not write to CP/M drives that have not been mounted. Doing so will cause corruption on the SD Memory Card.

4. DSK image files are mounted by the MOUNT command in the order they are found in the SD card's Directory.

5. DSK image files must be in the root directory of the SD card.

6. DSK image files are checked for the correct file length (8MB) but no other checks are made.

7. The Write-Protect switch on SD Cards is not observed, and will not write-protect the SD card when being accessed from the eZ80F91 kit.

8. Real-time clock support is incomplete and buggy in the eZ80F91 BIOS.

I have tested several different SD Memory cards with this platform, and all appear to work fine, except one 256MB SanDisk Mini-SD Card. This particular card also does not work well with my laptop's SD connector, so I believe the card itself is faulty.  I have tried several cards from SanDisk and PNY, up to 2GB.  The cards that I use most frequently are SanDisk 64MB Cards.

MMC Memory cards should also work, but these have not been extensively tested.


## Internal FLASH Filesystem is Read-Only (flashdrv.asm)

The Internal 128K FLASH Filesystem (A: drive) is read-only.  In order to generate the disk image for this drive, the 128k.dsk image file can be mounted with SIMH/AltairZ80 and manipulated.  This file must be converted to a an array of bytes and placed in the file FLASHDSK.C.  The FLASH filesystem must include the MOUNT.COM utility, so that SD Memory Cards can be mounted.

The Internal FLASH drive could be made writable, by adding support to flashdrv.asm.  This would require using some of the eZ80SBC's RAM to handle blocking/deblocking.  In order not to interfere with the CP/M TPA, this code should use ADL mode and locate the blocking/deblocking buffer outside of CP/M's 64K bank.


# Resources

Zilog eZ80 development tools and documentation: [www.zilog.com](www.zilog.com)

[SIMH](https://github.com/open-simh/simh)/AltairZ80: [http://www.schorn.ch/cpm/intro.html](http://www.schorn.ch/cpm/intro.html)

SD Card Socket Breakout Board from [SparkFun](http://www.sparkfun.com/commerce/product_info.php?products_id=204)


# License

CP/M 2.2 and 3.0 are licensed per the [CP/M license](http://www.cpm.z80.de/license.html) as updated in 2022.

Files not part of the CP/M distribution are licensed under the MIT license.


# Frequently Asked Questions



1. Q: Is this distribution compatible with a Z80 or Z8S180?

A: No, the CBIOS takes advantage of some instructions specific to the eZ80 family of processors, and also uses the ADL mode for accessing more than 64K of memory.



2. Q: Is there any technical support for this distribution?

A: This distribution is provided as-is for people to experiment with, without support.  Feel free to submit pull requests.



3. Q: Will this distribution work without having an SD Adapter card attached to the eZ80F91 Kit?

A: Yes, as long as you make the serial port enable modification to the eZ80F91 Modular Development Kit, you should be able to get an A> prompt, and run the programs included on the internal FLASH drive.



4. Q: Is the Internal FLASH drive writable or erasable?

A: The FLASH can be erased with the Zilog FLASH Programmer, but it is generally not user-writable.



5. Q: Is there any support for the eZ80F91's Ethernet controller?

A: No.



6. Q: Can CP/M 2.2, ZCPR, etc. run on the eZ80F91 Modular Development Kit?

A: Yes, I have these running on the Kit, but not to the same level of functionality as CP/M 3.