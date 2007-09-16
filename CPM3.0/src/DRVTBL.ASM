;*************************************************************************
;*                                                                       *
;* $Id: DRVTBL.ASM 1555 2007-09-14 07:37:35Z hharte $                    *
;*                                                                       *
;* Copyright (c) 2005-2007 Howard M. Harte                               *
;* https://github.com/hharte                                             *
;*                                                                       *
;* Module Description:                                                   *
;*     eZ80_SBC CPM 3.0 Disk Drive Table by Howard M. Harte.             *
;*                                                                       *
;* Environment:                                                          *
;*     Zilog ZDS-II v4.11.1, (http://www.zilog.com)                      *
;*                                                                       *
;*************************************************************************

TITLE   'eZ80_SBC CP/M 3.0 Disk Drive Table'

INCLUDE "cpm3_defs.inc"       ; BIOS Configuration File

DEFINE BIOS, SPACE = RAM
SEGMENT BIOS

USE_DRIVES equ on

PUBLIC  _dtbl


IF USE_DRIVES

EXTERN  flash0
EXTERN  _sdmmc0, _sdmmc1, _sdmmc2, _sdmmc3
EXTERN  sd0phys, sd1phys

_dtbl:  DW  flash0      ; A:
        DW  0           ; B:
IFDEF _ZSSC             ; Zilog Smart Serial Cable does not support SD Cards
        DW  0           ; C:
        DW  0           ; D:
        DW  0           ; E:
        DW  0           ; F:
ELSE                    ; All others supprt SD Cards
        DW  _sdmmc0     ; C:
        DW  _sdmmc1     ; D:
        DW  _sdmmc2     ; E:
        DW  _sdmmc3     ; F:
ENDIF
        DW  0           ; G:
        DW  0           ; H:
        DW  0           ; I:
        DW  0           ; J:
        DW  0           ; K:
        DW  0           ; L:
        DW  0           ; M:
        DW  0           ; N:
        DW  0           ; O:
        DW  0           ; P:

ELSE
_dtbl:  dw  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
ENDIF ; USE_DRIVES

END     
