;*************************************************************************
;*                                                                       *
;* $Id: eZ80-CPM-UART.asm 834 2006-09-14 07:43:55Z Hharte $              *
;*                                                                       *
;* Portions Copyright (c) 2005-2007 Howard M. Harte                      *
;* https://github.com/hharte                                             *
;*                                                                       *
;* Converted to Z80 assembler and modified to work on the eZ80F91        *
;* platform by Jean-Michel Howland, vegeneering, 2004.                   *
;* http://www.vegeneering.com/                                           *
;*                                                                       *
;* Environment:                                                          *
;*     Zilog ZDS-II v4.11.1, (http://www.zilog.com)                      *
;*                                                                       *
;*************************************************************************/

PUBLIC	b_UART0Init
PUBLIC	b_UART0GetByte
PUBLIC	b_UART0PutByte
PUBLIC	b_UART0Status

INCLUDE	"eZ80F91.inc"	; eZ80F91 Register Definitions

; UART - UART routines.

BAUD_300:	EQU	28B0h           ; 300.0192012
BAUD_600:	EQU	1458h           ; 600.0384025
BAUD_1200:	EQU	0A2Ch           ; 1200.076805
BAUD_2400:	EQU	0516h           ; 2400.15361 
BAUD_4800:	EQU	028Bh           ; 4800.30722 
BAUD_9600:	EQU	0145h           ; 9615.384615
BAUD_19200:	EQU	00A3h           ; 19171.77914
BAUD_115200:	EQU	001Bh		; 115740.7407

	DEFINE BIOS, SPACE = RAM
	SEGMENT BIOS

; Set the alternate function for PORT D to use UART0.

b_UART0Init:	ld	a,01h
		out0	(PD_ALT2),a
		dec	a					; Save 1 byte over LD A,0.
		out0	(PD_ALT1),a
		dec	a					; Save 1 byte over LD A,0FFh
		out0	(PD_DDR),a

; Configure UART0 for 115200,8,1,n.

		ld	a,00h
		out0	(UART0_FCTL),a				; Disable UART0 FIFO.
		ld	a,80h
		out0	(UART0_LCTL),a				; Enable access to BRG.
		ld	a,1Bh
		out0	(UART0_BRG_L),a				; Load low byte of BRG.
		ld	a,00h
		out0	(UART0_BRG_H),a				; Load high byte of BRG.
		ld	a,03h
		out0	(UART0_LCTL),a				; Select 8 bits, no parity, 1 stop.
		ret

b_UART0GetByte:	in0	a,(UART0_RBR)				; Get character from the RX buffer.
		ret

b_UART0PutByte:	out0	(UART0_THR),a				; Put character in the TX buffer.
		ret						; Done.

b_UART0Status:	in0	a,(UART0_LSR)				; Read UART status register of COM Port 1.
		ret

; End of UART routines.
