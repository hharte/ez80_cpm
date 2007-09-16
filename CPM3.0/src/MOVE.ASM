;*************************************************************************
;*                                                                       *
;* $Id: MOVE.ASM 1555 2007-09-14 07:37:35Z hharte $                      *
;*                                                                       *
;* Copyright (c) 2005-2007 Howard M. Harte                               *
;* https://github.com/hharte                                             *
;*                                                                       *
;* Module Description:                                                   *
;*     eZ80F91 CPM 3.0 CBIOS Memory Move by Howard M. Harte.             *
;*                                                                       *
;* Environment:                                                          *
;*     Zilog ZDS-II v4.11.1, (http://www.zilog.com)                      *
;*                                                                       *
;*************************************************************************

TITLE   'eZ80_SBC bank & move module for CP/M3 linked BIOS'

INCLUDE "cpm3_defs.inc"

DEFINE BIOS, SPACE = RAM
SEGMENT BIOS

PUBLIC  _move,_xmove,_bank
EXTERN  _CBNK

; Not implemented for eZ80 yet.
_xmove:
    RET     

_move:
    EX      DE,HL       ; we are passed source in DE and dest in HL
    LDIR                ; use Z80 block move instruction
    EX      DE,HL       ; need next addresses in same regs
    RET
    ; by exiting through bank select
_bank:
    RET     

END     
