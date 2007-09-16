;*************************************************************************
;*                                                                       *
;* $Id: CTBL.ASM 1361 2007-05-12 03:46:06Z hharte $                      *
;*                                                                       *
;* Copyright (c) 2005-2007 Howard M. Harte                               *
;* https://github.com/hharte                                             *
;*                                                                       *
;* Module Description:                                                   *
;*     eZ80F91 CPM 3.0 CBIOS Character I/O by Howard M. Harte.           *
;*                                                                       *
;* Environment:                                                          *
;*     Zilog ZDS-II v4.10.1, (http://www.zilog.com)                      *
;*                                                                       *
;*************************************************************************

TITLE   'Character I/O handler for the eZ80_SBC'

        ; Character I/O for the Modular CP/M 3 BIOS

        ; hharte: TODO:
        ;       1. Add parallel port I/O support.
        ;       2. Add _cinit support to allow soft-setting the baud rate.

        ; limitations:

	DEFINE BIOS, SPACE = RAM
	SEGMENT BIOS

        PUBLIC  _ctbl

	include "modebaud.inc"


_ctbl:  DEFB    'CON   '    ; device 0, CRT Serial port 0
        DEFB    mb$in$out+mb$serial+mb$soft$baud+mb$xon$xoff
        DEFB    baud$19200
        DEFB    'AUX   '        ; device 1, AUX Serial port 1
        DEFB    mb$in$out+mb$serial+mb$soft$baud+mb$xon$xoff
        DEFB    baud$19200
;       DEFB    'LPT   '        ; device 2, Centronics parallel printer
;       DEFB    MB$OUTPUT
;       DEFB    BAUD$NONE
        DEFB    0               ; table terminator

        END
