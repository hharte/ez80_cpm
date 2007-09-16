;*************************************************************************
;*                                                                       *
;* $Id: clock.asm 1564 2007-09-16 05:14:58Z hharte $                     *
;*                                                                       *
;* Copyright (c) 2005-2007 Howard M. Harte                               *
;* https://github.com/hharte                                             *
;*                                                                       *
;* Module Description:                                                   *
;*     eZ80F91 CPM 3.0 CBIOS Real-Time Clock by Howard M. Harte.         *
;*                                                                       *
;* Environment:                                                          *
;*     Zilog ZDS-II v4.11.1, (http://www.zilog.com)                      *
;*                                                                       *
;*************************************************************************

TITLE   'Clock handler for the eZ80_SBC'

; hharte: TODO:
;       1. Fix date handling

INCLUDE "SCB.INC"
INCLUDE "cpm3_defs.inc"
INCLUDE	"eZ80F91.inc"                   ; eZ80F91 Register Definitions

DEFINE  BIOS, SPACE = RAM
SEGMENT BIOS

PUBLIC  _time

; No external clock.
_time:
        push    hl
        push    de
        ld      a,c
        cp      0ffh
        jp      z,setclock
readclock:
;       ld      hl,_DATE
;       ld      bc, 2000
;       ld      (hl), bc
        ld      hl, _SEC
        in0     a,(RTC_SEC)
        ld      (hl), a 
        ld      hl, _MIN
        in0     a,(RTC_MIN)
        ld      (hl), a
        ld      hl, _HOUR
        in0     a,(RTC_HRS)
        ld      (hl), a

        in0     a,(RTC_DOM)
        dec     a               ; subtract 1, becasue DOM starts at 1.
        jp      z,timdon        ; Date has not changed.

        ld      c,a
        ld      b,0
        ld      hl, _DATE
        ld      hl, (hl)
        add     hl, bc
setclock:
        in0     a,(RTC_CTRL)
        or      a,021h
        out0    (RTC_CTRL),a    ; Unlock RTC

        ld      a,(_SEC)
        out0    (RTC_SEC),a
        ld      a,(_MIN)
        out0    (RTC_MIN),a
        ld      a,(_HOUR)
        out0    (RTC_HRS),a

        ld      a,06
        out0    (RTC_YR),a
        ld      a,20
        out0    (RTC_CEN),a
        ld      a,1
        out0    (RTC_DOW),a
        out0    (RTC_DOM),a
        out0    (RTC_MON),a

        in0     a,(RTC_CTRL)
        and     a,0FEh
        out0    (RTC_CTRL),a    ; Lock RTC

timdon: pop     de
        pop     hl
        ret


END
