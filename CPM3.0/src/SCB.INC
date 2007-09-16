;*************************************************************************
;*                                                                       *
;* $Id: SCB.INC 1564 2007-09-16 05:14:58Z hharte $                       *
;*                                                                       *
;* Copyright (c) 2005-2007 Howard M. Harte                               *
;* https://github.com/hharte                                             *
;*                                                                       *
;* Module Description:                                                   *
;*     CPM 3.0 SCB, Ported to ZDS-II by Howard M. Harte.                 *
;*                                                                       *
;* Environment:                                                          *
;*     Zilog ZDS-II v4.11.0, (http://www.zilog.com)                      *
;*                                                                       *
;*************************************************************************

title 'System Control Block Definition for CP/M3 BIOS'

extern SCB
	
scb_base equ    SCB         ; Base of the SCB

_BDRV	equ     scb_base+13h	; Boot Drive
_CIVEC  equ     scb_base+22h    ; Console Input Redirection Vector (word, r/w)
_COVEC  equ     scb_base+24h    ; Console Output Redirection Vector (word, r/w)
_AIVEC  equ     scb_base+26h    ; Auxiliary Input Redirection Vector (word, r/w)
_AOVEC  equ     scb_base+28h    ; Auxiliary Output Redirection Vector (word, r/w)
_LOVEC  equ     scb_base+2Ah    ; List Output Redirection Vector (word, r/w)
_BNKBF  equ     scb_base+35h    ; Address of 128 Byte Buffer for Banked BIOS (word, r/o)
_CRDMA  equ     scb_base+3Ch    ; Current DMA Address 
                                ; (word, r/o)
_CRDSK  equ     scb_base+3Eh    ; Current Disk (byte, r/o)
_VINFO  equ     scb_base+3Fh    ; BDOS Variable "INFO" 
                                ; (word, r/o)
_RESEL  equ     scb_base+41h    ; FCB Flag (byte, r/o)
_FX     equ     scb_base+43h    ; BDOS Function for Error 
                                ; Messages (byte, r/o)
_USRCD  equ     scb_base+44h    ; Current User Code (byte, r/o)
_MLTIO	equ     scb_base+4Ah	; Current Multi-Sector Count
				; (byte,r/w)
_ERMDE  equ     scb_base+4Bh    ; BDOS Error Mode (byte, r/o)
_ERDSK	equ     scb_base+51h	; BDOS Error Disk (byte,r/o)
_MEDIA	equ     scb_base+54h	; Set by BIOS to indicate
				; open door (byte,r/w)
_BFLGS  equ     scb_base+57h    ; BDOS Message Size Flag (byte,r/o)  
_DATE   equ     scb_base+58h    ; Date in Days Since 1 Jan 78 
                                ; (word, r/w)
_HOUR   equ     scb_base+5Ah    ; Hour in BCD (byte, r/w)
_MIN    equ     scb_base+5Bh    ; Minute in BCD (byte, r/w)
_SEC    equ     scb_base+5Ch    ; Second in BCD (byte, r/w)
_ERJMP  equ     scb_base+5Fh    ; BDOS Error Message Jump
                                ; (word, r/w)
_MXTPA  equ     scb_base+62h    ; Top of User TPA 
                                ; (address at 6,7)(word, r/o)
end

