;*************************************************************************
;*                                                                       *
;* $Id: BIOSKRNL.ASM 1564 2007-09-16 05:14:58Z hharte $                  *
;*                                                                       *
;* Copyright (c) 2005-2007 Howard M. Harte                               *
;* https://github.com/hharte                                             *
;*                                                                       *
;*                                                                       *
;* Module Description:                                                   *
;*     eZ80F91 CPM 3.0 CBIOS Kernel ported to ZDS-II by Howard M. Harte. *
;*                                                                       *
;* Environment:                                                          *
;*     Zilog ZDS-II v4.11.1, (http://www.zilog.com)                      *
;*                                                                       *
;*************************************************************************

    TITLE   'Root module of relocatable BIOS for CP/M 3.0'
    ; version 1.0 15 Sept 82

    INCLUDE "cpm3_defs.inc"
    INCLUDE "SCB.INC"   
;         Copyright (C), 1982
;        Digital Research, Inc
;            P.O. Box 579
;       Pacific Grove, CA  93950
;   This is the invariant portion of the modular BIOS and is
;   distributed as source for informational purposes only.
;   All desired modifications should be performed by
;   adding or changing externally defined modules.
;   This allows producing "standard" I/O modules that
;   can be combined to support a particular system 
;   configuration.
ccp:    equ 0100h       ; Console Command Processor gets loaded into the TPA

    EXTERN  __CS1_LBR_INIT_PARAM    ; 64K Page that CP/M lives in.

    ; initialization
    EXTERN  _init       ; general initialization and signon
    EXTERN  _ldccp,_rlccp   ; load & reload CCP for BOOT & WBOOT
    ; user defined character I/O routines
    EXTERN  _ci,_co,_cist,_cost; each take device in <B>
    EXTERN  _cinit      ; (re)initialize device in <C>
    EXTERN  _ctbl       ; physical character device table
    ; disk communication data items
    EXTERN  _dtbl       ; table of pointers to XDPHs
    PUBLIC  _adrv,_rdrv,_trk,_sect; parameters for disk I/O
    PUBLIC  _dma,_dbnk,_cnt;    ''       ''   ''  ''
    ; memory control
    PUBLIC  _cbnk       ; current bank
    EXTERN  _xmove,_move    ; select move bank, and block move
    EXTERN  _bank       ; select CPU bank
    ; clock support
    EXTERN  _time       ; signal time operation
    ; general utility routines
    PUBLIC  _pmsg,_pdec ; PRINT message, PRINT number from 0 to 65535
    PUBLIC  _pderr  ; PRINT BIOS disk error message header

    ; External names for BIOS entry points
    PUBLIC  _boot,_wboot,_const,_conin,_cono,_list,_auxo,_auxi
    PUBLIC  _home,_sldsk,_sttrk,_stsec,_stdma,_read,_write
    PUBLIC  _lists,_sctrn
    PUBLIC  _conos,_auxis,_auxos,_dvtbl,_devin,_drtbl
    PUBLIC  _mltio,_flush,_mov,_tim,_bnksl,_stbnk,_xmov

    DEFINE BIOS, SPACE = RAM
    SEGMENT BIOS

extern ccp_start    
extern rsxstart

; BIOS Jump vector.
; All BIOS routines are invoked by calling these
;   entry points.
_boot:  JP  boot        ; initial entry on cold start
_wboot: JP  wboot       ; reentry on program exit, warm start
_const: JP  const       ; return console input status
_conin: JP  conin       ; return console input character
_cono:  JP  conout      ; send console output character
_list:  JP  list        ; send list output character
_auxo:  JP  auxout      ; send auxilliary output character
_auxi:  JP  auxin       ; return auxilliary input character
_home:  JP  home        ; set disks to logical home
_sldsk: JP  seldsk      ; select disk drive, return disk parameter INFO
_sttrk: JP  settrk      ; set disk track
_stsec: JP  setsec      ; set disk sector
_stdma: JP  setdma      ; set disk I/O memory address
_read:  JP  read        ; read physical block(s)
_write: JP  write       ; write physical block(s)
_lists: JP  listst      ; return list device status
_sctrn: JP  sectrn      ; translate logical to physical sector
_conos: JP  conost      ; return console output status
_auxis: JP  auxist      ; return aux input status
_auxos: JP  auxost      ; return aux output status
_dvtbl: JP  devtbl      ; return address of device def table
_devin: JP  _cinit      ; change baud rate of device
_drtbl: JP  getdrv      ; return address of disk drive table
_mltio: JP  multio      ; set multiple record count for disk I/O
_flush: JP  flush       ; flush BIOS maintained disk caching
_mov:   JP  _move       ; block move memory to memory
_tim:   JP  _time       ; Signal Time and Date operation
_bnksl: JP  bnksel      ; select bank for code execution and default DMA
_stbnk: JP  setbnk      ; select different bank for disk I/O DMA operations.
_xmov:  JP  _xmove      ; set source and destination banks for one operation
        JP  0       ; reserved for future expansion
        JP  rsxstart ;0     ; reserved for future expansion
        JP  ccp_start ;0        ; reserved for future expansion

; BOOT
;   Initial entry point for system startup.
boot:   
    LD      sp,boot_stack
    LD      C,15        ; initialize all 16 character devices
c_init_loop:    
    PUSH    BC 
    CALL    _cinit 
    POP     BC
    DEC     C 
    jp      nz, c_init_loop
    CALL    _init       ; perform any additional system initialization
                ; and PRINT signon message
    LD      BC,16*256+0 
    LD      HL,_dtbl    ; init all 16 logical disk drives
d_init_loop:    
    PUSH    BC      ; save remaining count and abs drive
    LD      E,(HL) 
    INC     HL 
    LD      D,(HL) 
    INC     HL      ; grab _drv entry
    LD      A,E 
    OR      D 
    JR      Z,d_init_next   ; if null, no drive
    PUSH    HL      ; save _drv pointer 
    EX      DE,HL       ; XDPH address in <HL>
    DEC     HL 
    DEC     HL 
    LD      A,(HL) 
    LD      (_rdrv),A   ; get relative drive code
    LD      A,C 
    LD      (_adrv),A   ; get absolute drive code
    DEC     HL      ; point to init pointer
    LD      D,(HL) 
    DEC     HL 
    LD      E,(HL)      ; get init pointer
    EX      DE,HL
    CALL    ipchl       ; call init routine
    POP     HL      ; recover _drv pointer
d_init_next:    
    POP     BC      ; recover counter and drive #
    INC     C 
    DEC     B 
    JP      NZ,d_init_loop  ; and loop for each drive
    JP      boot_1

boot_1: 
    CALL    set_jumps
    CALL    _ldccp      ; fetch CCP for first time
    JP      ccp

; WBOOT
;   Entry for system restarts.
wboot:  
    LD      sp,boot_stack
    CALL    set_jumps   ; initialize page zero
    CALL    _rlccp      ; reload CCP
    JP      ccp     ; then reset jmp vectors and exit to ccp

set_jumps:  
IF BANKED
    LD  A,1 
    CALL    _bnksl
ENDIF   
    LD      A,0C3H  ;JMP
    LD      (0),A 
    LD      (5),A       ; set up jumps in page zero
    LD      HL,_wboot 
    LD      (1),HL      ; BIOS warm start entry
    LD      HL,(_MXTPA) 
    LD      (6),HL      ; BDOS system call entry
    RET 
    DS      63
boot_stack: DS 1    ;equ    $
    ; DEVTBL
    ;   Return address of character device table
devtbl: 
    LD      HL,_ctbl 
    RET 
    ; GETDRV
    ;   Return address of drive table
getdrv: 
    LD      HL,_dtbl 
    RET 
    ; CONOUT
    ;   Console Output.  Send character in <C>
    ;           to all selected devices
conout: 
    LD      HL,(_COVEC) ; fetch console output bit vector
    JP      out_scan
    ; AUXOUT
    ;   Auxiliary Output. Send character in <C>
    ;           to all selected devices
auxout: 
    LD      HL,(_AOVEC) ; fetch aux output bit vector
    JP      out_scan
    ; LIST
    ;   List Output.  Send character in <C>
    ;           to all selected devices.
list:   
    LD      HL,(_LOVEC) ; fetch list output bit vector
out_scan:   
    LD      B,0     ; start with device 0
co_next:    
    ADD     HL,HL       ; shift out next bit
    JR      NC,not_out_device
    PUSH    HL      ; save the vector
    PUSH    BC      ; save the count and character
not_out_ready:  
    CALL    coster 
    OR      A 
    JR      Z,not_out_ready
    POP     BC 
    PUSH    BC      ; restore and resave the character and device
    CALL    _co     ; if device selected, PRINT it
    POP     BC      ; recover count and character
    POP     HL      ; recover the rest of the vector
not_out_device: 
    INC     B       ; next device number
    LD      A,H 
    OR      L       ; see if any devices left
    JR      NZ,co_next      ; and go find them...
    RET 

; CONOST
;   Console Output Status.  Return true if
;       all selected console output devices
;       are ready.
conost: 
    LD      HL,(_COVEC) ; get console output bit vector
    JP      ost_scan

; AUXOST
;   Auxiliary Output Status.  Return true if
;       all selected auxiliary output devices
;       are ready.
auxost: 
    LD      HL,(_AOVEC) ; get aux output bit vector
    JP      ost_scan

; LISTST
;   List Output Status.  Return true if
;       all selected list output devices
;       are ready.
listst: 
    LD      HL,(_LOVEC) ; get list output bit vector
ost_scan:   
    LD      B,0     ; start with device 0
cos_next:   
    ADD     HL,HL       ; check next bit
    PUSH    HL      ; save the vector
    PUSH    BC      ; save the count
    LD      A,0FFh      ; assume device ready
    CALL    C,coster    ; check status for this device
    POP     BC      ; recover count
    POP     HL      ; recover bit vector
    OR      A       ; see if device ready
    RET     Z       ; if any not ready, return false
    INC     B       ; drop device number
    LD      A,H 
    OR      L       ; see if any more selected devices
    JR      NZ,cos_next
    OR      0FFh        ; all selected were ready, return true
    RET 
coster: ; check for output device ready, including optional
    ;   xon/xoff support
    LD      L,B 
    LD      H,0     ; make device code 16 bits
    PUSH    HL      ; save it in stack
    ADD     HL,HL 
    ADD     HL,HL 
    ADD     HL,HL       ; create offset into device characteristics tbl
    LD      DE,_ctbl+6 
    ADD     HL,DE       ; make address of mode byte
    LD      A,(HL) 
    AND     010H        ; mb_xonxoff
    POP     HL      ; recover console number in <HL>
    JR      Z,_cost     ; not a xon device, go get output status direct
    LD      DE,xofflist 
    ADD     HL,DE       ; make pointer to proper xon/xoff flag
    CALL    cist1       ; see if this keyboard has character
    LD      A,(HL) 
    CALL    NZ,ci1      ; get flag or read key if any
    CP      CTLQ 
    JR      NZ,not_q        ; if its a ctl-Q,
    LD      A,0FFh      ;   set the flag ready
not_q:  
    CP      CTLS 
    JR      NZ,not_s        ; if its a ctl-S,
    LD      A,00h       ;   clear the flag
not_s:  
    LD      (HL),A      ; save the flag
    CALL    cost1       ; get the actual output status,
    AND     (HL)        ; and mask with ctl-Q/ctl-S flag
    RET         ; return this as the status
cist1:  ; get input status with <BC> and <HL> saved
    PUSH    BC 
    PUSH    HL 
    CALL    _cist
    POP     HL 
    POP     BC
    OR      A
    RET 
cost1:  ; get output status, saving <BC> & <HL>
    PUSH    BC 
    PUSH    HL
    CALL    _cost
    POP     HL 
    POP     BC
    OR      A
    RET 
ci1:    ; get input, saving <BC> & <HL>
    PUSH    BC 
    PUSH    HL
    CALL    _ci
    POP     HL 
    POP     BC
    RET 

; CONST
;   Console Input Status.  Return true if
;       any selected console input device
;       has an available character.
const:  
    LD      HL,(_CIVEC) ; get console input bit vector
    JP      ist_scan

; AUXIST
;   Auxiliary Input Status.  Return true if
;       any selected auxiliary input device
;       has an available character.
auxist: 
    LD      HL,(_AIVEC) ; get aux input bit vector
ist_scan:   
    LD      B,0     ; start with device 0
cis_next:   
    ADD     HL,HL       ; check next bit
    LD      A,0     ; assume device not ready
    CALL    C,cist1     ; check status for this device
    OR      A 
    RET     NZ          ; if any ready, return true
    INC     B       ; drop device number
    LD      A,H 
    OR      L       ; see if any more selected devices
    JR      NZ,cis_next
    XOR     A       ; all selected were not ready, return false
    RET 

; CONIN
;   Console Input.  Return character from first
;       ready console input device.
conin:  
    LD      HL,(_CIVEC)
    JP      in_scan

; AUXIN
;   Auxiliary Input.  Return character from first
;       ready auxiliary input device.
auxin:  
    LD      HL,(_AIVEC)
in_scan:    
    PUSH    HL      ; save bit vector
    LD      B,0
ci_next:    
    ADD     HL,HL       ; shift out next bit
    LD      A,0     ; insure zero a  (nonexistant device not ready).
    CALL    C,cist1     ; see if the device has a character
    OR      A
    JR      NZ,ci_rdy   ; this device has a character
    INC     B       ; else, next device
    LD      A,H 
    OR      L       ; see if any more devices   JR  NZ,ci_next  ; go look at them
    POP     HL      ; recover bit vector
    JP      in_scan     ; loop til we find a character
ci_rdy: 
    POP     HL      ; discard extra stack
    JP      _ci

;   Utility Subroutines
ipchl:  ; vectored CALL point
    JP      (HL)
_pmsg:  ; PRINT message @<HL> up to a null
    ; saves <BC> & <DE>
    PUSH    BC
    PUSH    DE
pmsg_loop:  
    LD      A,(HL) 
    OR      A 
    JR      Z,pmsg_exit
    LD      C,A 
    PUSH    HL
    CALL    _cono 
    POP     HL
    INC     HL 
    JP      pmsg_loop
pmsg_exit:  
    POP     DE
    POP     BC
    RET 
_pdec:  ; PRINT binary number 0-65535 from <HL>
    LD      BC,table10
    LD      DE,-10000
next:   
    LD      A,'0'-1
pdecl:  
    PUSH    HL
    INC     A
    ADD     HL,DE
    JR      NC,stoploop
    INC     sp
    INC     sp
    JP      pdecl
stoploop:   
    PUSH    DE
    PUSH    BC
    LD      C,A
    CALL    _cono
    POP     BC
    POP     DE
nextdigit:  
    POP     HL
    LD      A,(BC)
    LD      E,A
    INC     BC
    LD      A,(BC)
    LD      D,A
    INC     BC
    LD      A,E
    OR      D
    JR      NZ,next
    RET 
table10:    
    DW      -1000,-100,-10,-1,0
_pderr: 
    LD      HL,drive_msg 
    CALL    _pmsg       ; error header
    LD      A,(_adrv) 
    ADD     A,'A' 
    LD      C,A 
    CALL    _cono       ; drive code
    LD      HL,track_msg 
    CALL    _pmsg       ; track header
    LD      HL,(_trk) 
    CALL    _pdec       ; track number
    LD      HL,sector_msg 
    CALL    _pmsg       ; sector header
    LD      HL,(_sect) 
    CALL    _pdec       ; sector number
    RET 

; BNKSEL
;   Bank Select.  Select CPU bank for further execution.
bnksel: 
    LD      (_cbnk),A   ; remember current bank
    JP      _bank       ; and go exit through users

; physical bank select routine
xofflist:
    DB      -1,-1,-1,-1,-1,-1,-1,-1; ctl-s clears to zero
    DB      -1,-1,-1,-1,-1,-1,-1,-1

;   Disk I/O interface routines

; SELDSK
;   Select Disk Drive.  Drive code in <C>.
;       Invoke login procedure for drive
;       if this is first select.  Return
;       address of disk parameter header
;       in <HL>
seldsk: 
    LD      A,C 
    LD      (_adrv),A   ; save drive select code
    LD      L,C 
    LD      H,0 
    ADD     HL,HL       ; create index from drive code
    LD      BC,_dtbl 
    ADD     HL,BC       ; get pointer to dispatch table
    LD      A,(HL) 
    INC     HL 
    LD      H,(HL) 
    LD      L,A     ; point at disk descriptor
    OR      H 
    RET     Z       ; if no entry in table, no disk
    LD      A,E 
    AND     1 
    JR      NZ,not_first_select; examine login bit
    PUSH    HL 
    EX      DE,HL       ; put pointer in stack & <DE>
    LD      HL,-2 
    ADD     HL,DE 
    LD      A,(HL) 
    LD      (_rdrv),A   ; get relative drive
    LD      HL,-6 
    ADD     HL,DE       ; find LOGIN addr
    LD      A,(HL) 
    INC     HL 
    LD      H,(HL) 
    LD      L,A     ; get address of LOGIN routine
    CALL    ipchl       ; call LOGIN
    POP     HL      ; recover DPH pointer
not_first_select:   
    RET
	 
; HOME
;   Home selected drive.  Treated as SETTRK(0).
home:   
    LD      BC,0        ; same as set track zero
    ; SETTRK
    ;   Set Track. Saves track address from <BC> 
    ;       in _TRK for further operations.
settrk: 
    LD      L,C 
    LD      H,B
    LD      (_trk),HL
    RET
	 
; SETSEC
;   Set Sector.  Saves sector number from <BC>
;       in _sect for further operations.
setsec: 
    LD      L,C 
    LD      H,B
    LD      (_sect),HL
    RET
	 
; SETDMA
;   Set Disk Memory Address.  Saves DMA address
;       from <BC> in _DMA and sets _DBNK to _CBNK
;       so that further disk operations take place
;       in current bank.
setdma: 
    LD      L,C 
    LD      H,B
    LD      (_dma),HL
    LD      A,(_cbnk)   ; default DMA bank is current bank
; fall through to set DMA bank
; SETBNK
;   Set Disk Memory Bank.  Saves bank number
;       in _DBNK for future disk data
;       transfers.
setbnk: 
    LD      (_dbnk),A
    RET 
    ; SECTRN
    ;   Sector Translate.  Indexes skew table in <DE>
    ;       with sector in <BC>.  Returns physical sector
    ;       in <HL>.  If no skew table (<DE>=0) then
    ;       returns physical=logical.
sectrn: 
    LD      L,C 
    LD      H,B
    inc     hl  ; Physical sector starts at 1
    LD      A,D 
    OR      E 
    RET     Z
    dec     hl  ; If translating, start at sector 0
    EX      DE,HL
    ADD     HL,BC 
    LD      L,(HL) 
    LD      H,0
    RET
 
; read
;   Read physical record from currently selected drive.
;       Finds address of proper read routine from
;       extended disk parameter header (XDPH).
read:   
    LD      HL,(_adrv) 
    LD      H,0 
    ADD     HL,HL       ; get drive code and double it
    LD      DE,_dtbl 
    ADD     HL,DE       ; make address of table entry
    LD      A,(HL) 
    INC     HL 
    LD      H,(HL) 
    LD      L,A     ; fetch table entry
    PUSH    HL      ; save address of table
    LD      DE,-8 
    ADD     HL,DE       ; point to read routine address
    JP      rw_common   ; use common code

; WRITE
;   Write physical sector from currently selected drive.
;       Finds address of proper write routine from
;       extended disk parameter header (XDPH).
write:  
    LD      HL,(_adrv) 
    LD      H,0 
    ADD     HL,HL       ; get drive code and double it
    LD      DE,_dtbl 
    ADD     HL,DE       ; make address of table entry
    LD      A,(HL) 
    INC     HL 
    LD      H,(HL) 
    LD      L,A     ; fetch table entry
    PUSH    HL      ; save address of table
    LD      DE,-10 
    ADD     HL,DE       ; point to write routine address
rw_common:  
    LD      A,(HL) 
    INC     HL 
    LD      H,(HL) 
    LD      L,A     ; get address of routine
    POP     DE      ; recover address of table
    DEC     DE 
    DEC     DE      ; point to relative drive
    LD      A,(DE) 
    LD      (_rdrv),A   ; get relative drive code and post it
    INC     DE 
    INC     DE      ; point to DPH again
    JP      (HL)        ; leap to driver

; MULTIO
;   Set multiple sector count. Saves passed count in
;       _CNT
multio: 
    LD  (_cnt),A 
    RET 

; FLUSH
;   BIOS deblocking buffer flush.  Not implemented.
flush:  
    XOR A 
    RET         ; return with no error

; error message components
drive_msg:  DB  CR,LF,BELL,'BIOS Error on ',0
track_msg:  DB  ': T-',0
sector_msg: DB  ', S-',0

; disk communication data items
_adrv:  DS  1       ; currently selected disk drive
_rdrv:  DS  1       ; controller relative disk drive
_trk:   DS  2       ; current track number
_sect:  DS  2       ; current sector number
_dma:   DS  2       ; current DMA address
_bnk:   DB  __CS1_LBR_INIT_PARAM    ; 64K Page that CP/M lives in
_cnt:   DB  0       ; record count for multisector transfer
_dbnk:  DB  0       ; bank for DMA operations

_cbnk:  DB  0       ; bank for processor operations

end 
