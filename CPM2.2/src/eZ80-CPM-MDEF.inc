
; CP/M Defines - Memory and associated defines.

;======================================================================================================
;  Copyright © 1976, 1977, 1978, 1979, 1982, and 1983 by Digital Research.
;  All rights reserved.

;  2004-12-09:	BIOS version 1.2.
;		  Ch
;  2004-11-05:	BIOS version 1.1.
; 		  Wrote a bootloader based on the feedback from ZiLOG customer support (thanks Tom) and
;		  managed to get CP/M 2.2 running finally.  Now to write a BIOS driver to  utilise a CF
; 		  FLASH storage card as a solid state 32MB hard drive.

;  2004-02-10:	BIOS version 1.0.  Start of BIOS.
;		  Reformatted code so it would assemble with ZDSII. Changed the names of the halt, type
;		  and space label to haltc, typec & spacec because of possible reserved word conflicts.
; 		  Started modification of the skeletal  BIOS source code for the ZiLOG eZ80Acclaim! F91
; 		  development board and ZDSII.

;  2002-06-17:	CP/M version 2.2.  Start of project by Jean-Michel Howland.
; 		  Reformatted code so it would assemble with TASM.
; 		  Fixed  bugs with  8080 to  Z80 mnemonic  version.  Whatever  was used  to convert the
; 		  original code spat and produced these weird mnemonics 'ADD A,M' and 'SBC A,M'.

;  1981-02-27:	Reconstructed from a memory image by Clark A. Calkins.
;======================================================================================================

NOLIST

EXTERN RAM_START
EXTERN TPA_LOC
EXTERN CCP_LOC
EXTERN BDOS_LOC
EXTERN BIOS_LOC

ramstart:	EQU	RAM_START					; Set RAM base to 0000h.

tpa:		EQU	TPA_LOC ;ramstart + 0100h			; Base of TPA.
ccp:		EQU	CCP_LOC ;ramstart + 0D800h			; Base of CCP.
bdos:		EQU	BDOS_LOC+6 ;ccp + 0806h				; Base of BDOS.
bios:		EQU	BIOS_LOC ;ccp + 1600h				; Base of BIOS.

; Set CP/M low memory data, vector and buffer addresses.

iobyte:		EQU	ramstart + 03h				; Intel standard I/O definition byte.
usrdrv:		EQU	ramstart + 04h				; Current user number and drive.
bdosen:		EQU	ramstart + 05h				; Entry point for the BDOS.
tpafcb:		EQU	ramstart + 5Ch				; Default File Control Block.
tpabuf:		EQU	ramstart + 80h				; Default I/O buffer and command line storage.

; Set control character equates.

cntrlc:		EQU	03h					; Control-C (Reboots CP/M system).
cntrle:		EQU	05h					; Control-E (Physical EOL, line not sent until CR pressed).
bs:		EQU	08h					; Control-H (Backspace).
tab:		EQU	09h					; Control-I (Tab).
lf:		EQU	0Ah					; Control-J (Line feed).
ff:		EQU	0Ch					; Control-L (Form feed).
cr:		EQU	0Dh					; Control-M (Carriage return).
cntrlp:		EQU	10h					; Control-P (Toggle I/O to current list device).
cntrlr:		EQU	12h					; Control-R (Retypes current command line).
cntrls:		EQU	13h					; Control-S (Stops console output temporarily).
cntrlu:		EQU	15h					; Control-U (Deletes the entire line typed).
cntrlx:		EQU	18h					; Control-X (Same as Control-U).
cntrlz:		EQU	1Ah					; Control-Z (End-Of-File mark).
del:		EQU	7Fh					; Rubout.

; End of CP/M Defines.

LIST

