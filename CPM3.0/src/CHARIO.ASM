;*************************************************************************
;*                                                                       *
;* $Id: CHARIO.ASM 1561 2007-09-16 04:57:56Z hharte $                    *
;*                                                                       *
;* Copyright (c) 2005-2007 Howard M. Harte                               *
;* https://github.com/hharte                                             *
;*                                                                       *
;* Module Description:                                                   *
;*     eZ80F91 CPM 3.0 CBIOS Character I/O by Howard M. Harte.           *
;*                                                                       *
;* Environment:                                                          *
;*     Zilog ZDS-II v4.11.1, (http://www.zilog.com)                      *
;*                                                                       *
;*************************************************************************

TITLE   'Character I/O handler for the eZ80_SBC'

; hharte: TODO:
;       1. Add parallel port I/O support.
;       2. Add _cinit support to allow soft-setting the baud rate.

INCLUDE "cpm3_defs.inc"
INCLUDE	"eZ80F91.inc"                   ; eZ80F91 Register Definitions
INCLUDE "modebaud.inc"

DEFINE  BIOS, SPACE = RAM
SEGMENT BIOS

PUBLIC  _cinit,_ci,_co,_cist,_cost
PUBLIC  _ctbl

PUBLIC  co_port1

MAX_DEVICES EQU 2

_cinit:
    ld      a,03h
    out0    (PD_ALT2),a
    out0    (PC_ALT2),a
    ld      a,0
    out0    (PD_ALT1),a
    out0    (PC_ALT1),a
    dec     a                           ; Save 1 byte over LD A,0FFh
    out0    (PD_DDR),a
    out0    (PC_DDR),a

; Configure UART0 for 115200,8,1,n.
    ld      a,06h                       ; Enable UART 0/1 Rx/Tx for eZ80F91A
    out0    (UART0_FCTL),a              ; but disable FIFO
    out0    (UART1_FCTL),a
    in0     a,(ZDI_ID_REV)
    cp      2                           ; If it is an F91A, then enable the UART FIFOs.
    jp      nz,F91Rev0
    ld      a,07h                       ; Enable UART Rx/Tx for eZ80F91A
    out0    (UART0_FCTL),a              ; Enable UART0 FIFO.
    out0    (UART1_FCTL),a              ; Enable UART1 FIFO.
F91Rev0:
    ld      a,80h
    out0    (UART0_LCTL),a              ; Enable access to BRG.
    ld      a,1Bh
    out0    (UART0_BRG_L),a             ; Load low byte of BRG.
    ld      a,00h
    out0    (UART0_BRG_H),a             ; Load high byte of BRG.
    ld      a,03h
    out0    (UART0_LCTL),a              ; Select 8 bits, no parity, 1 stop.

; Configure UART1 for 115200,8,1,n.
    ld      a,80h
    out0    (UART1_LCTL),a              ; Enable access to BRG.
    ld      a,1Bh
    out0    (UART1_BRG_L),a             ; Load low byte of BRG.
    ld      a,00h
    out0    (UART1_BRG_H),a             ; Load high byte of BRG.
    ld      a,03h
    out0    (UART1_LCTL),a              ; Select 8 bits, no parity, 1 stop.

    ret

; character input
_ci:

    ld      a,b                         ; b = port (serial 0, serial 1, or lpt)

    or      a                           ; check port
    jp      nz,ci_port1

; input character from port 0
ci_port0:
    call    cist_port0                  ; check status
    jp      z,ci_port0                  ; wait if no char
    in0     a,(UART0_RBR)               ; Get character from the RX buffer.
    and     7Fh                         ; mask to ascii
    ret

; input character from port 1
ci_port1:
    call    cist_port1                  ; check status
    jp      z,ci_port1                  ; wait if no char
    in0     a,(UART1_RBR)               ; Get character from the RX buffer.
;   and     7Fh                         ; mask to ascii
    ret

; character input status
_cist:

    ld      a,b                         ; b = port (serial 0, serial 1, or lpt)
    or      a
    jp      nz,cist_port1

; check serial input status for port 0
cist_port0:
    in0     a,(UART0_LSR)               ; Read UART status register of COM Port 0.
cist_portx:
    and     1                           ; char ready to read?
    ret     z
    or      255
    ret
    
; check serial input status for port 1
cist_port1:
    in0     a,(UART1_LSR)               ; Read UART status register of COM Port 1.
    jp      cist_portx                  ; jump to common code

; character output
_co:
    ld      a,b                         ; b = port (serial 0, serial 1, or lpt)
    cp      1
    jp      z,co_port1                  ; serial port 1?
;   jp      nc,co_lpt

; send character to serial port 0
co_port0:
    call    cost_port0
    jp      z,co_port0
    ld      a,c
    out0    (UART0_THR),a   ; Put character in the TX buffer.
    ret

; send character to serial port 1
co_port1:
    call    cost_port1
    jp      z,co_port1
    ld      a,c
    out0    (UART1_THR),a   ; Put character in the TX buffer.
    ret

; character output status
_cost:
    ld      a,b             ; b = port (serial 0, serial 1, or lpt)
    cp      1
    jp      z,cost_port1
;   jp      nc,cost_lpt

cost_port0:
    in0     a,(UART0_LSR)   ; Read UART status register of COM Port 0.
cost_portx:
    and     20h
    ret     z
    or      255
    ret

cost_port1:
    in0     a,(PA_DR)       ; Check USBD_INT#
    and     01h
    ret     z               ; USB Microcontroller is busy, not ready for more data.

    in0     a,(UART1_LSR)   ; Read UART status register of COM Port 1.
    jp      cost_portx

_ctbl:
    DEFB    'CON   '    ; device 0, CRT Serial port 0
    DEFB    mb_in_out+mb_serial+mb_soft_baud+mb_xon_xoff
    DEFB    baud_19200
    DEFB    'AUX   '        ; device 1, AUX Serial port 1
    DEFB    mb_in_out+mb_serial+mb_soft_baud+mb_xon_xoff
    DEFB    baud_19200
;   DEFB    'LPT   '        ; device 2, Centronics parallel printer
;   DEFB    MB_OUTPUT
;   DEFB    BAUD_NONE
    DEFB    0               ; table terminator

END
