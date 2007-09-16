;*************************************************************************
;*                                                                       *
;* $Id: cpm_startup.asm 1557 2007-09-15 16:28:48Z hharte $               *
;*                                                                       *
;* Copyright (c) 2005-2007 Howard M. Harte                               *
;* https://github.com/hharte                                             *
;*                                                                       *
;* Module Description:                                                   *
;*     eZ80_SBC eZ80F91 Initialization Code, based on Zilog example.     *
;*                                                                       *
;* Environment:                                                          *
;*     Zilog ZDS-II v4.11.1, (http://www.zilog.com)                      *
;*                                                                       *
;*************************************************************************


;*****************************************************************************
; init_params_f91.asm
;
; minimum eZ80F91 initialization
;*****************************************************************************
; Copyright (C) 2005 by ZiLOG, Inc.  All Rights Reserved.
;*****************************************************************************

 INCLUDE "ez80f91.inc"


	PUBLIC _main       
    EXTERN _boot

	EXTERN CCP_LEN
	EXTERN BDOS_LEN
	EXTERN BIOS_LEN

	EXTERN CCP_LOC
	EXTERN CCP_ROM_LOC
	EXTERN BDOS_LOC
	EXTERN BDOS_ROM_LOC
	EXTERN BIOS_LOC
	EXTERN BIOS_ROM_LOC

	EXTERN _BOOT_FROM_FLASH
	EXTERN __CS1_LBR_INIT_PARAM

	PUBLIC _BootFromFlash


;*****************************************************************************
; Startup code
        DEFINE .STARTUP, SPACE = ROM
        SEGMENT .STARTUP
        .ASSUME ADL = 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Minimum default initialization for eZ80F91
_main
    ld a, __CS1_LBR_INIT_PARAM

	ld	MB, a
    ld	a, MB

	ld	a,%F0
	out0 (PA_ALT1), a        ;
	ld	a,%FF
	out0 (PA_DR), a

	; Copy FLASH code to RAM
	ld	a, (_BootFromFlash)
	cp	0
	jr	z, CopyDone
	ld.lil	hl, CCP_ROM_LOC		; Source CCP Location in FLASH
	ld.lil	de, CCP_LOC		; Destination CCP Location in RAM
	ld.lil  bc, CCP_LEN
	ldir.lil			; Copy the CCP from FLASH to RAM

	ld.lil	hl, BDOS_ROM_LOC	; Source BDOS Location in FLASH
	ld.lil	de, BDOS_LOC		; Destination BDOS Location in RAM
	ld.lil  bc, BDOS_LEN
	ldir.lil			; Copy the BDOS from FLASH to RAM

	ld.lil	hl, BIOS_ROM_LOC	; Source BIOS Location in FLASH
	ld.lil	de, BIOS_LOC		; Destination BIOS Location in FLASH
	ld.lil  bc, BIOS_LEN
	ldir.lil			; Copy the BIOS from FLASH to RAM

CopyDone:
	; Copy CCP to RAM at 01D800h, so it can be reloaded during warm boot.
	ld.lil	hl, CCP_LOC
	ld.lil	de, CCP_LOC + 010000h
	ld.lil  bc, CCP_LEN
	ldir.lil              		; Copy the CCP


	di				;Disable Interrupts
	jp.sis	_boot

_BootFromFlash
	DB	_BOOT_FROM_FLASH	; set to a non-zero value if we are booting from FLASH

;PUBLIC STARTUP_PAD
;STARTUP_PAD	ds 02000H-$

