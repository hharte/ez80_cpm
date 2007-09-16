;*************************************************************************
;*                                                                       *
;* $Id: sdmmcdrv.asm 1555 2007-09-14 07:37:35Z hharte $                  *
;*                                                                       *
;* Copyright (c) 2005-2007 Howard M. Harte                               *
;* https://github.com/hharte                                             *
;*                                                                       *
;* Module Description:                                                   *
;*     eZ80_SBC SD/MMC Disk Driver by Howard M. Harte                    *
;*                                                                       *
;* Environment:                                                          *
;*     Zilog ZDS-II v4.11.1, (http://www.zilog.com)                      *
;*                                                                       *
;*************************************************************************

TITLE   'eZ80F91 SD/MMC Disk Driver'
        
INCLUDE "cpm3_defs.inc"       ; BIOS Configuration File
SPI_CTL:    EQU %BA

DEFINE  BIOS, SPACE = RAM
SEGMENT BIOS
                
PUBLIC  _sdmmc0, _sdmmc1, _sdmmc2, _sdmmc3
PUBLIC  sd_init
PUBLIC  sd_off_tbl
PUBLIC  b_CurSDDrv


; Variables containing parameters passed by BDOS

EXTERN   _adrv,_rdrv
EXTERN   _dma,_trk,_sect
EXTERN   _dbnk

EXTERN  flsh0dirbcb
EXTERN  flsh0alv

EXTERN  b_MMCInit;
EXTERN  b_MMCReadSec
EXTERN  b_MMCWriteSec

EXTERN  b_mmcadrl
EXTERN  b_mmcadrsll
EXTERN  b_mmcadrslh

SD_DEBUG    equ off

; System Control Block variables

EXTERN   _ermde                         ; BDOS error mode

; Utility routines in standard BIOS

EXTERN   _wboot                         ; warm boot vector
EXTERN   _pmsg                          ; print message _<HL> up to 00, saves <BC> & <DE>
EXTERN   _pdec                          ; print binary number in <A> from 0 to 99.
EXTERN   _pderr                         ; print BIOS disk error header
EXTERN   _conin                         ; console input
EXTERN   _cono                          ; console output
EXTERN   _const                         ; get console status

PUBLIC  _dpbsd0

;Disk Parameter Block for an 8MB Non-removable drive
_dpbsd0:    
    dw  192                             ; # of 128 byte records/track (SPT)
    db  5                               ; BSH (4K byte blocks)
    db  31                              ; BLM
    db  1                               ; EXM
    dw  2047-6                          ; DSM 2042 4K Blocks
    dw  1023                            ; DRM 1024 Directory Entries
    db  0FFh                            ; AL0   
    db  000h                            ; AL1   
    dw  08000h                          ; CKS (Set to 08000h for hard drives)
    dw  1                               ; OFF (# tracks to skip for system)     
    db  2                               ; PSH (Physical Record Shift Factor) (512 -
    db  3                               ; PHM (Physical Record Shift Mask)    byte sectors)
    dw  sd_off_tbl                      ; Pointer to the track offset table
    
dpbsd256:
    dw  32                              ; # of 128 byte records/track (SPT)
    db  3                               ; BSH (1K byte blocks)
    db  7                               ; BLM
    db  0                               ; EXM
    dw  191                             ; DSM 128 1K Blocks
    dw  63                              ; DRM 64 Directory Entries
    db  0E0h                            ; AL0   
    db  000h                            ; AL1   
    dw  08000h                          ; CKS (Set to 08000h for hard drives)
    dw  10H                             ; OFF (# tracks to skip for system)     
    db  2                               ; PSH (Physical Record Shift Factor) (512 -
    db  3                               ; PHM (Physical Record Shift Mask)    byte sectors)
    dw  sd_off_tbl                      ; Pointer to the track offset table


; Extended Disk Parameter Headers (XPDHs)
    dw  sd_write
    dw  sd_read
    dw  sd_login
    dw  sd_init
    db  0,0                             ; relative drive 0
_sdmmc0:
    dw  00000h                          ; XLT table
    db  0,0,0,0,0,0,0,0,0               ; Reserved
    db  0FFh                            ; Media Flag (MF)
    dw  _dpbsd0                         ; Pointer to DPB
    dw  00000h                          ; Pointer to CSV (not needed for HD)
    dw  sd0alv                          ; Pointer to ALV (assigned by GENCPM)
    dw  flsh0dirbcb                     ; Pointer to DIRBCB ("      "   "   )
    dw  flsh0dirbcb                     ; Pointer to DTABCB ("      "   "   )
    dw  0FFFFh                          ; Pointer to HASH   (Hashing Disabled)
    db  0                               ; HBANK (0 for nonbanked system)
    
    dw  sd_write
    dw  sd_read
    dw  sd_login
    dw  sd_init
    db  1,0                             ; relative drive 1
_sdmmc1:
    dw  00000h                          ; XLT table
    db  0,0,0,0,0,0,0,0,0               ; Reserved
    db  0FFh                            ; Media Flag (MF)
    dw  _dpbsd0                         ; Pointer to DPB
    dw  00000h                          ; Pointer to CSV (not needed for HD)
    dw  sd1alv                          ; Pointer to ALV (assigned by GENCPM)
    dw  flsh0dirbcb                     ; Pointer to DIRBCB ("      "   "   )
    dw  flsh0dirbcb                     ; Pointer to DTABCB ("      "   "   )
    dw  0FFFFh                          ; Pointer to HASH   (Hashing Disabled)
    db  0                               ; HBANK (0 for nonbanked system)

    dw  sd_write
    dw  sd_read
    dw  sd_login
    dw  sd_init
    db  2,0                             ; relative drive 2
_sdmmc2:
    dw  00000h                          ; XLT table
    db  0,0,0,0,0,0,0,0,0               ; Reserved
    db  0FFh                            ; Media Flag (MF)
    dw  _dpbsd0                         ; Pointer to DPB
    dw  00000h                          ; Pointer to CSV (not needed for HD)
    dw  sd2alv                          ; Pointer to ALV (assigned by GENCPM)
    dw  flsh0dirbcb                     ; Pointer to DIRBCB ("      "   "   )
    dw  flsh0dirbcb                     ; Pointer to DTABCB ("      "   "   )
    dw  0FFFFh                          ; Pointer to HASH   (Hashing Disabled)
    db  0                               ; HBANK (0 for nonbanked system)

    dw  sd_write
    dw  sd_read
    dw  sd_login
    dw  sd_init
    db  3,0                             ; relative drive 3
_sdmmc3:
    dw  00000h                          ; XLT table
    db  0,0,0,0,0,0,0,0,0               ; Reserved
    db  0FFh                            ; Media Flag (MF)
    dw  _dpbsd0                         ; Pointer to DPB
    dw  00000h                          ; Pointer to CSV (not needed for HD)
    dw  sd3alv                          ; Pointer to ALV (assigned by GENCPM)
    dw  flsh0dirbcb                     ; Pointer to DIRBCB ("      "   "   )
    dw  flsh0dirbcb                     ; Pointer to DTABCB ("      "   "   )
    dw  0FFFFh                          ; Pointer to HASH   (Hashing Disabled)
    db  0                               ; HBANK (0 for nonbanked system)

    
sd0alv: blkb    256,0                   ; Using double allocation vectors...
sd1alv: blkb    256,0
sd2alv: blkb    256,0
sd3alv: blkb    256,0

sd_off_tbl:
;       track   sect
    dw  0000AH, 00020H                  ; Track/sector offset for drive 0
    dw  0FFFFH, 00000H                  ; Track/sector offset for drive 1
    dw  0FFFFH, 00000H                  ; Track/sector offset for drive 2
    dw  0FFFFH, 00000H                  ; Track/sector offset for drive 3
    dw  0FFFFH, 00000H                  ; Track/sector offset for drive 4
    dw  0FFFFH, 00000H                  ; Track/sector offset for drive 5
    dw  0FFFFH, 00000H                  ; Track/sector offset for drive 6
    dw  0FFFFH, 00000H                  ; Track/sector offset for drive 7

b_CurSDDrv: db  0


; Disk READ and WRITE entry points.
;***************************************************************
; These entries are called with the following arguments:
;
; Relative drive number in _rdrv (8 bits)
; Absolute drive number in _adrv (8 bits)
; Disk transfer address in _dma (16 bits)
; Disk transfer bank    in _dbnk (8 bits)
; Disk track address    in _trk (16 bits)
; Disk sector address   in _sect (16 bits)
; Pointer to XDPH       in <DE>
;
; They transfer the appropriate data, perform retries
; if necessary, then return an error code in <A>
;***************************************************************


;***************************************************************
;Function:  flsh_write:
;Purpose:   Do physical write to IDE drive
;Entry:     hstdsk, hsttrk, hstdsk set up
;Exit:      sector in hstbuf written to disk
;Used:      all
;***************************************************************

sd_write:
IF SD_DEBUG
    LD      HL,sd_wr_msg
    call    _pmsg                       ; print SD Write trace message
ENDIF
    call    b_rwsetup
    call    b_MMCWriteSec
    jr      b_rwfinish      
    ret

;***************************************************************
;Function:  flsh_read:
;Purpose:   Do physical read of IDE drive
;Entry:     hstdsk, hsttrk, hstdsk set up
;Exit:      sector read into hstbuf
;Used:      all
;***************************************************************

sd_read:
IF SD_DEBUG
    LD      HL,sd_rd_msg
    call    _pmsg                       ; print FLASH Read message
ENDIF
    call    b_rwsetup
    call    b_MMCReadSec
;   call    b_TXdskStats
    jr      b_rwfinish      

sd_login:                               ; nothing to do for non-removable disk.
IF SD_DEBUG
    LD      HL,sd_login_msg
    call    _pmsg                       ; print login message
ENDIF

sd_init:
    ld      a,(_rdrv)
    srl     a
    ld      (b_CurSDDrv), a

IF SD_DEBUG
    LD      HL,sd_init_msg
    call    _pmsg                       ; print init message
ENDIF
IFNDEF _ZSSC							; Smart Serial Cable dsoes not support SD Cards
    call    b_MMCInit                   ; Initialise MMC FLASH Memory Card.

ENDIF
    jp      b_rwfinish

; Creates an MMC compatible 32 bit sector buffer address from the track and sector number passed from CP/M.
; On exit, HLDE contain the 32 bit number.

_spt    db  0

b_rwsetup:                              ; This first part is a hack.  Physical drive should come from a table (similar to sd_off_tbl)
                                        ; that is set up by the mount utility.
    ld      a,(_rdrv)                   ; Compute physical SD card slot based on _rdrv.
    srl     a                           ; _rdrv 0,1=slot 0, _rdrv 2,3=slot 1.
    ld      (b_CurSDDrv), a
    ld      hl,12
    add     hl,de
    ld      hl,(hl)
    ld      a,(hl)                      ; Get number of 128-byte records/track
    srl     a
    srl     a                           ; convert to sectors/track
    ld      (_spt), a
    ld      de,(_sect)                  ; Sector # into E, Track into D
    dec     de                          ; physical sector is one more than actual hardware sector

    ld      (b_mmcadrl), de
    ld      a,(_adrv)                   ; Controller Relative Drive #
    ld      a,(_rdrv)                   ; Controller Relative Drive #
    add     a,a                         ; * 2
    add     a,a                         ; * 4
    ld      c,a
    ld      b,0
    ld      hl,sd_off_tbl
    add     hl,bc                       ; Get table address of rdrv
    ld      c,(hl)
    inc     hl
    ld      b,(hl)                      ; get rdrv track offset.
    inc     hl
    ld      a,(hl)                      ; get sector offset from table.
    ld      h,0
    ld      l,a
    add     hl,de
    ex      hl,de                       ; add sector from table into passed in sector.
    ld      hl,(_trk)                   ; MMCSector = (b_track * 8) + b_sector.
    adc     hl,bc                       ; compute rdrv track offset + _trk
    ld      a,(_spt)
    ld      ix,hl

    call    mlt16x8                     ; Convert track number into sectors.

    ld      d,0
    add     ix,de                       ; Add in sector.
    ld      de,ix                       ; Put sector number in DE.

    adc     a,0                         ; add carry from sector add.
    ld      l,a                         ; put overflow into L.  H is don't care since the 9-bit shift will overwrite it anyway.
    ret

; Perform a 16*8 multiply, using the eZ80's 8*8 MLT instruction.
; 8-bit multiplicand in A
; 16-bit multiplicand in IX
; Result returned in A:IX
mlt16x8:
    exx
    ld      hl,ix
    ld      e,l
    ld      d,a
    mlt     de
    ld      l,a
    mlt     hl
    ld      a,l
    add     a,d
    ld      d,a
    ld      a,h
    adc     a,0                         ; Add carry into result
    ld      ix,de
    exx                                 ; Result in A:IX
    ret

b_rwfinish:
    jr      nc,rf1                      ; C = 1 if an error occured.
rw_err:
    ld      a,1
    jr      rf2
rf1:
    xor     a
rf2:
    ld      (erflag),a
;   jp      b_TXdskStats
    ret

erflag:     ds  1

IF SD_DEBUG
sd_init_msg:    db  'SD Init\n\r',0
sd_login_msg:   db  'SD Login\n\r',0
sd_rd_msg:      db  'SD Rd\n\r',0
sd_wr_msg:      db  'SD Wr\n\r',0
ENDIF

end             ; sdmmcdrv.asm
