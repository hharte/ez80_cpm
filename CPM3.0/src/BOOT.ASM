;*************************************************************************
;*                                                                       *
;* $Id: BOOT.ASM.in 1205 2007-02-17 22:37:19Z hharte $                   *
;*                                                                       *
;* Copyright (c) 2005-2007 Howard M. Harte                               *
;* https://github.com/hharte                                             *
;*                                                                       *
;* Module Description:                                                   *
;*     Boot code.                                                        *
;*                                                                       *
;* Environment:                                                          *
;*     Zilog ZDS-II v4.11.1, (http://www.zilog.com)                      *
;*                                                                       *
;*************************************************************************

TITLE   'eZ80_SBC CBIOS BOOT Module for CP/M 3.0'

INCLUDE "SCB.INC"
INCLUDE "cpm3_defs.inc"
INCLUDE	"eZ80F91.inc"                   ; eZ80F91 Register Definitions

DEFINE  BIOS, SPACE = RAM
SEGMENT BIOS

PUBLIC  _init,_ldccp,_rlccp
EXTERN  _pmsg,_conin
EXTERN  ccp_curdrv
EXTERN  _cbnk,_bnksl
EXTERN  bdose
EXTERN  sd_init

EXTERN  co_port1

EXTERN CCP_LEN
EXTERN CCP_LOC
EXTERN CCP_ROM_LOC

_init:
        LD      HL,bdose
        LD      (_MXTPA),HL     ; Set up BDOS Entry Point
        LD      HL,08000H 
        LD      (_CIVEC),HL 
        LD      (_COVEC),HL     ; assign console to CON:
        LD      HL,02000H 
        LD      (_LOVEC),HL     ; assign printer to LPT:
        LD      HL,04000H 
        LD      (_AIVEC),HL 
        LD      (_AOVEC),HL     ; assign AUX to AUX:

IF .NOT. LDRBIOS
        in0     a,(ZDI_ID_REV)
        add     a,'0'
        ld      (F91Revision), a

        LD      HL,SIGNON_MSG 
        call    _pmsg           ; print signon message
ENDIF

        xor     a,a
        ld      (ccp_curdrv), a
        call    sd_init
        jr      z,def_c_drive
        RET

def_c_drive:
        ld      a,0              ; default to drive A, internal FLASH drive
        ld      (ccp_curdrv), a
        ret
      
;   This version of the boot loader loads the CCP from the Flash ROM
_rlccp:
_ldccp:
        ; Copy CCP to RAM at 01D800h, so it can be reloaded during warm boot.
        ld.lil  hl, CCP_LOC + 010000h
        ld.lil  de, CCP_LOC
        ld.lil  bc, CCP_LEN
        ldir.lil                 ; Copy the CCP

        RET     

; CP/M BDOS Function Interfaces

CCP_MSG:            defb        'Loading CCP from FLASH.',13,10,0
CCP_DONE:           defb        'CCP Load complete.',13,10,0

IF LDRBIOS
SIGNON_MSG:         DEFB        13,10,13,10,'eZ80F91 LDRBIOS v0.0'
                    DEFB        13,10

                    DEFB        '(c) 2000-2007 Howard M. Harte.',13,10,10,0
ELSE
    IF BANKED
SIGNON_MSG:         DEFB        13,10,13,10,'eZ80F91 Banked CBIOS v0.0'

                    DEFB        13,10
                    DEFB        '(c) 2000-2007 Howard M. Harte.',13,10,10,0
    ELSE
SIGNON_MSG:         DEFB        CR,LF,CR,LF,'64K CP/M V3.1 - eZ80F91 Rev '
F91Revision:        DEFB        '0'
                    DEFB        ' CBIOS v1.0.0.3107 of 2008-01-10'
        IFDEF _MDS
                    DEFB        ' [MDS, '       ; Mini Development Kit/Module
        ELSE
                IFDEF _ZSSC
                    DEFB        ' [ZSSC, '      ; Zilog Smart Serial Cable
                ELSE
                        IFDEF _PLT
                    DEFB        ' [PLT, '       ; Development Platform or Large Ethernet Module
                        ELSE
                    DEFB        ' [???, '       ; Unknown configuration
                        ENDIF
                ENDIF
        ENDIF
IFDEF _DEBUG
                    DEFB        'DEBUG]'
ELSE
                    DEFB        'RELEASE]'
ENDIF
                    DEFB        CR,LF,'Copyright (C) 1982, Digital Research'
                    DEFB        CR,LF,'Copyright (C) 2000-2007, Howard M. Harte'
                    DEFB        CR,LF,LF,0
    ENDIF
ENDIF

END     
