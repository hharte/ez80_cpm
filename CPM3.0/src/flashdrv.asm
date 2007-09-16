;*************************************************************************
;*                                                                       *
;* $Id: flashdrv.asm 1555 2007-09-14 07:37:35Z hharte $                  *
;*                                                                       *
;* Copyright (c) 2005-2007 Howard M. Harte                               *
;* https://github.com/hharte                                             *
;*                                                                       *
;* Module Description:                                                   *
;*     eZ80 Internal FLASH Disk Driver by Howard M. Harte                *
;*                                                                       *
;* Environment:                                                          *
;*     Zilog ZDS-II v4.11.1, (http://www.zilog.com)                      *
;*                                                                       *
;*************************************************************************

TITLE   'eZ80F91 Internal FLASH Disk Driver'
        
include "cpm3_defs.inc"       ; BIOS Configuration File
                
; Variables containing parameters passed by BDOS

FLASH_DEBUG equ 0

DEFINE BIOS, SPACE = RAM
SEGMENT BIOS

PUBLIC  flash0
PUBLIC  flsh0dirbcb

EXTERN   _adrv,_rdrv
EXTERN   _dma,_trk,_sect
EXTERN   _dbnk

EXTERN  b_SL32

EXTERN  b_HLDE
EXTERN  b_mmcadrl
EXTERN  b_mmcadrh
EXTERN  b_mmcadrsll
EXTERN  b_mmcadrslh

EXTERN  FLASHDSK

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


; Extended Disk Parameter Headers (XPDHs)
    dw  flsh_write
    dw  flsh_read
    dw  flsh_login
    dw  flsh_init
    db  0,0                             ; relative drive zero
flash0:
    dw  00000h                          ; XLT table
    db  0,0,0,0,0,0,0,0,0               ; Reserved
    db  0FFh                            ; Media Flag (MF)
    dw  dpbflash0                       ; Pointer to DPB
    dw  00000h                          ; Pointer to CSV (not needed for HD)
    dw  flsh0alv                        ; Pointer to ALV (assigned by GENCPM)
    dw  flsh0dirbcb                     ; Pointer to DIRBCB ("      "   "   )
    dw  flsh0dirbcb                     ; Pointer to DTABCB ("      "   "   )
    dw  0FFFFh                          ; Pointer to HASH   (Hashing Disabled)
    db  0                               ; HBANK (0 for nonbanked system)
    
dpbflash0:    
    dw  32                              ; # of 128 byte records/track (SPT)
    db  3                               ; BSH (1K byte blocks)
    db  7                               ; BLM
    db  0                               ; EXM
    dw  127                             ; DSM 128 1K Blocks
    dw  63                              ; DRM 64 Directory Entries
    db  0C0h                            ; AL0   
    db  000h                            ; AL1   
    dw  0h                              ; CKS (Set to 08000h for hard drives)
    dw  0                               ; OFF (# tracks to skip for system)     
    db  2                               ; PSH (Physical Record Shift Factor) (512 -
    db  3                               ; PHM (Physical Record Shift Mask)    byte sectors)

flsh0dirbcb:
    db  0                               ; 0 drive
    db  0                               ; 1-3 rec (24-bit)
    dw  0000                            ; 
    db  0                               ; 4 wflag
    db  0                               ; scratch
    dw  0                               ; 6 track
    dw  0                               ; 8 sector
    dw  fldirbuf                        ; A buffptr
    db  0                               ; C bank
    dw  0                               ; D chain

fldirbuf:   blkb    512,0

flsh0alv:   blkb    32,0

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

flsh_write:
IF FLASH_DEBUG
    LD      HL,flsh_wr_msg
    call    _pmsg                       ; print FLASH Write Error message
ENDIF
    ld      a, 0FFh
    ret

;***************************************************************
;Function:  flsh_read:
;Purpose:   Do physical read of IDE drive
;Entry:     hstdsk, hsttrk, hstdsk set up
;Exit:      sector read into hstbuf
;Used:      all
;***************************************************************

flsh_read:
IF FLASH_DEBUG
    LD      HL,flsh_rd_msg
    call    _pmsg                       ; print FLASH Read message
ENDIF
    call    b_flrwsetup
    ld.lil  bc, 0200h
    ld.lil  de, (_dma)
    ldir.lil                            ; Read sector from FLASH
;   call    b_TXdskStats
    scf
    ccf
    jr      b_rwfinish      

flsh_login:                             ; nothing to do for non-removable disk.
flsh_init:
IF FLASH_DEBUG
    LD      HL,flsh_login_msg
    call    _pmsg                       ; print signon message
ENDIF
    xor     a,a
    ret
    
b_flrwsetup:
    ld      de,(_sect)                  ; Sector # into E, Track into D
    dec     de                          ; physical sector is one more than actual hardware sector

    ld      (b_mmcadrl), de

    ld      hl,(_trk)                   ; MMCSector = (b_track * 32) + b_sector.
    add     hl,hl                       ; * 2
    add     hl,hl                       ; * 4
    add     hl,hl                       ; * 8
    ld      d,0

    add     hl,de                       ; Add in sector.
    ex      de,hl                       ; Put sector number in DE.
    ld      hl,0000h                    ; Zero HL for now.
    call    b_SL32
    ld      a,(_trk)
    and     10h
    jr      nz, b_flupper
    ld.lil  hl,FLASHDSK
    add.lil hl,de
    ret

b_flupper:
    ld.lil  hl,FLASHDSK + 010000h
    add.lil hl,de
    ret

b_rwfinish:
    jr      nc,rf1                      ; C = 1 if an error occured.
    ld      a,1
    jr      rf2
rf1:
    xor     a
rf2:
    ld      (erflag),a
;   jp      b_TXdskStats
    ret

erflag:     ds  1

IF FLASH_DEBUG
flsh_login_msg: DEFB  'FLASH Login\n\r',0
flsh_rd_msg:    DEFB  'FLASH Rd\n\r',0
flsh_wr_msg:    DEFB  'FLASH Wr\n\r',0
ENDIF

 END
