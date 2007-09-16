;*************************************************************************
;*                                                                       *
;* $Id: ez80sdmem.asm 1561 2007-09-16 04:57:56Z hharte $                 *
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

INCLUDE	"eZ80F91.inc"                   ; eZ80F91 Register Definitions

	DEFINE BIOS, SPACE = RAM
	SEGMENT BIOS

	.ASSUME ADL = 0

PUBLIC	b_MMCInit
PUBLIC	b_MMCReadSec
PUBLIC	b_MMCWriteSec

PUBLIC	b_SL32

PUBLIC	b_mmcadrl
PUBLIC	b_mmcadrh
PUBLIC	b_mmcadrsll
PUBLIC	b_mmcadrslh

EXTERN	_dma
EXTERN	b_TXstringDE
EXTERN	b_CurSDDrv

SD_DEBUG	equ	0


GO_IDLE_STATE:		EQU	0
SEND_OP_COND:		EQU	1
SEND_CSD		EQU	9
SEND_CID		EQU	10			
SEND_STATUS		EQU	13
READ_SINGLE_BLOCK:	EQU	17
WRITE_BLOCK:		EQU	24
SD_SEND_OP_COND		EQU	41
APP_CMD			EQU	55
GET_OCR			EQU	58

CR			EQU	13
LF			EQU	10

b_MMCInit:
	call	ClaimSPI	
	call	b_SPIInit
	call	b_SPIRaiseCS		; Activate MMC.
	ld		b,0A0h			; Setup to loop 10 times.
b_mi1:		
	call	b_SPICardDelay		; Send 80 dummy clocks (no CS).
	djnz	b_mi1			; Loop until B = 0.

	ld	b,10
SD_GoIdleLoop:
	call    b_SPILowerCS
	ld	a,GO_IDLE_STATE		; Set to SPI Mode.
	ld	hl,0000h
	ld	de,0000h
	call	b_MMCSendCMD
	call	b_SPIGetR1Resp
	ld	(Rsp1Value), a
	call	b_SPIRaiseCS
	call	b_SPICardDelay
	call	b_SPICardDelay
	djnz	SD_GoIdleLoop

	ld	a, (Rsp1Value)
	cp	01h
	jr	z,SD_IdleState
IF SD_DEBUG
	ld	de, b_strNoIdleState
	call	b_TXstringDE
ENDIF
	call	ReleaseSPI
	scf				; Exit with an error.
	ret

b_strNoIdleState	ASCII	"Card did not enter IDLE state.\n\r$"

Rsp1Value	ds	1

SD_IdleState:
	ld	b,0FFh
SD_OpCond:		
	ld	a,APP_CMD
	ld	hl,0000h
	ld	de,0000h
	call	b_MMCSendCMD
	call	b_SPIGetR1Resp
	call	b_SPIRaiseCS
	ld	a,SD_SEND_OP_COND
	ld	hl,0000h
	ld	de,0000h
	call	b_MMCSendCMD
	call	b_SPIGetR1Resp
	push	af
	call	b_SPIRaiseCS
	pop	af
	cp	00h
	jr	nz, try_again

	jr	SD_GoHiSpeed

try_again:
	ld	a,SEND_OP_COND
	ld	hl,0000h
	ld	de,0000h
	call	b_MMCSendCMD
	call	b_SPIGetR1Resp
	push	af
	call	b_SPIRaiseCS
	pop	af
	cp	00h
	jr	nz, TryOpCondAgain

SD_GoHiSpeed:
	ld	a,03h			; @ 50MHz clock, 04h = ~6.25Mbit/s.
	out0	(SPI_BRG_L),a

IF SD_DEBUG
	ld	de, b_strHiSpeed
	call	b_TXstringDE
ENDIF
	call	ReleaseSPI
	scf
	ccf
	ret

TryOpCondAgain:
	djnz	SD_OpCond

	ld	de, b_strNoReady
	call	b_TXstringDE
	call	ReleaseSPI
	scf
	ret

b_strNoReady	ASCII   "Timed out waiting for card to become ready.\n\r$"

IF SD_DEBUG
b_strHiSpeed	ASCII	"High-speed SPI clock enabled.\n\r$"
ENDIF

MMCGetStatus:
	call	b_SPIRaiseCS
	call	b_SPICardDelay
	ld	b,14h
b_StatAgain:
	call	b_SPILowerCS
	ld	a,SEND_STATUS
	ld	hl,0000h
	ld	de,0000h
	call	b_MMCSendCMD
	call	b_SPIGetR1Resp
	push	af
	call	b_SPICardDelay
	call	b_SPIRaiseCS
	call	b_SPICardDelay
	pop	af
	cp	00h
	jr	nz, StatTry_again
	scf
	ccf
	ret
StatTry_again:
	djnz	b_StatAgain
	scf
	ret

SD_GetOCR:
	ld	a,GET_OCR
	ld	hl,0000h
	ld	de,0000h
	call	b_MMCSendCMD
	call	b_SPIGetR1Resp
	push	af
	call	b_SPICardDelay
	call	b_SPICardDelay
	call	b_SPICardDelay
	call	b_SPICardDelay
	call	b_SPIRaiseCS
	pop	af
	cp	01h
	jr	nz, SD_GetOCRFailed
	scf
	ccf
	ret

SD_GetOCRFailed:
	scf
	ret

SD_GetCSD:
	ld	a,SEND_CSD
	jr	SD_DoCIDCSD

SD_GetCID:
	ld	a,SEND_CID
SD_DoCIDCSD:
	ld	hl,0000h
	ld	de,0000h
	call	b_MMCSendCMD
	call	b_SPIGetR1Resp
	cp	00h
	jp	nz, SD_GetCIDFailed

SD_CIDWaitData:
	call	b_SPICardDelay
	cp	0FEh			; Check for ready to send data token.
	jr	nz, SD_CIDWaitData

	ld	b,18
SD_ReadCIDLoop:
	call	b_SPICardDelay
;	call	PT2
;	ld	a, ' '
;	call	conout
	djnz	SD_ReadCIDLoop
	scf
	ccf
	ret

SD_GetCIDFailed:
	scf
	ret


; --------------
ClaimSPI:
	in0		a,(PB_DR)
	and		a,020h
	cp		020h
	jr		nz, ClaimSPI
	in0		a,(PB_DR)
	res		4,a
	set 	5,a
	out0	(PB_DR),a
	in0		a,(PB_DR)
	and		a,020h
	cp		020h
	jr		nz, ClaimSPIErr
	ld		a,3Ch			; 0011 0100 Enable SPI interface. CPOL=1=LK idles High, CPHA=1.
	out0	(SPI_CTL),a
	ret
	ret

ClaimSPIErr:
	in0		a,(PB_DR)
	set		4,a
	out0	(PB_DR),a
	jr		ClaimSPI

ReleaseSPI:
	ld		a,1Ch			; Disable SPI interface.
	out0	(SPI_CTL),a
	in0		a,(PB_DR)
	set		4,a
	out0	(PB_DR),a
	ret

b_MMCReadSec:
	call	ClaimSPI
	ld		a,READ_SINGLE_BLOCK
	call	b_MMCSendCMD
	call	b_SPIGetR1Resp
	cp	00h
	jr	nz,b_mrs4
b_mrs1:		
	call	b_SPICardDelay
	cp	0FEh			; Check for ready to send data token.
	jr	nz,b_mrs1		; Loop until MMC is ready.
	ld	hl,(_dma)
	ld	b,20h			; Setup to loop 32 times.
b_mrs2:
	ld	d,b
	ld	b,10h			; Setup to loop 16 times.
b_mrs3:
	call	b_SPICardDelay
	ld	(hl),a
	inc	hl
	djnz	b_mrs3			; Loop until B = 0.
	ld	b,d
	djnz	b_mrs2			; Loop until B = 0.
	call	b_SPIRaiseCS
	call	b_SPICardDelay
	call	b_SPICardDelay
	call	ReleaseSPI
	scf
	ccf
	ret
b_mrs4:
	call	b_SPIRaiseCS
	call	b_SPICardDelay
	call	ReleaseSPI
	scf
	ret

; --------------

b_MMCWriteSec:
	call	ClaimSPI
	ld	a,WRITE_BLOCK
	call	b_MMCSendCMD
	call	b_SPIGetR1Resp
	cp	00h
	jr	nz,b_mws5
	call	b_SPICardDelay
	ld	a,0FEh
	call	b_SPISendByte		; Data token.
	ld	hl,(_dma)
	ld	b,20h			; Setup to loop 32 times.
b_mws1:
	ld	d,b
	ld	b,10h			; Setup to loop 16 times.
b_mws2:
	ld	a,(hl)
	call	b_SPISendByte
	inc	hl
	djnz	b_mws2			; Loop until B = 0.
	ld	b,d
	djnz	b_mws1			; Loop until B = 0.
	call	b_SPICardDelay		; Send CRC byte.
	call	b_SPICardDelay		; Send CRC byte.
	call	b_SPICardDelay
	push	af
b_mws3:
	call	b_SPICardDelay
	cp	00h
	jr	z,b_mws3		; While busy, loop.
	call	b_SPIRaiseCS
	call	b_SPICardDelay
	call	b_SPILowerCS
	call	b_SPICardDelay
b_mws4:
	call	b_SPICardDelay
	cp	00h
	jr	z,b_mws4		; While busy, loop.
	call	b_SPIRaiseCS
	pop	af
	cp	0E5h			; Data token OK.
	jr	nz,b_mws6		; Error exit.
	call	ReleaseSPI
	scf
	ccf
	ret
b_mws5:
	call	b_SPIRaiseCS
	call	b_SPICardDelay
	call	ReleaseSPI
b_mws6:	scf
	ret

; --------------

b_SPIRaiseCS:
		push	af
IFDEF DEVKIT
		in0		a,(PB_DR)
		set		0,a			; xxxx xxx1 Set bit 0 high.
		out0	(PB_DR),a
ELSE
		in0 	a,(PA_DR)
		set		7,a
		out0 	(PA_DR),a
		ld		a,0FFh
		out0 	(PA_DR),a
ENDIF
		call	b_SPISendByte
		call	b_SPISendByte
		pop		af
		ret

b_SPILowerCS:
		push	af
IFDEF DEVKIT	
		in0		a,(PB_DR)
		res		0,a			; xxxx xxx0 Set bit 0 low.
b_srlcs1:	
		out0	(PB_DR),a
ELSE
		ld		a, (b_CurSDDrv)
		cp		0
		jr		nz, SDDrv1LowerCS
		ld		a,0C0h
SDDrvDoLower:
		out0 	(PA_DR),a
		res		7,a
		out0 	(PA_DR),a
		pop		af
		ret

SDDrv1LowerCS:
		ld		a,0D0h
		jr		SDDrvDoLower

ENDIF
		pop		af
		ret

; --------------

b_MMCSendCMD:
	PUSH	BC
	call	b_SPILowerCS		; Activate MMC.
	or	40h			; Set command bit.
	call	b_SPISendByte
	call	b_SL32			; Address must be aligned to 512 byte boundary.
	ld	a,h
	call	b_SPISendByte
	ld	a,l
	call	b_SPISendByte
	ld	a,d
	call	b_SPISendByte
	ld	a,e
	call	b_SPISendByte
	ld	a,95h
	call	b_SPISendByte
	POP	BC
	ret

; --------------

b_SPIGetR1Resp:
	push	bc
	ld	b,14h
R1WaitLoop:
	call	b_SPICardDelay
	bit	7,a			; bit 7 = 1, z = 0, loop.
	jr	z,GotResponse
	djnz	R1WaitLoop

IF SD_DEBUG
	ld	de, b_strRspTO
	call	b_TXstringDE
ENDIF

GotResponse:
	cp	0
	jp	z, R1NoErr

IF SD_DEBUG
	bit	2,a
	jr	z,chk_param_err
	push	af
	ld	de, b_strIllCmd
	call	b_TXstringDE
	pop	af
chk_param_err:
	bit	6,a
	jr	z,chk_addr_err
	push	af
	ld	de, b_strIllParm
	call	b_TXstringDE
	pop	af
chk_addr_err:
	bit	5,a
	jr	z,R1NoErr
	push	af
	ld	de, b_strAddrErr
	call	b_TXstringDE
	pop	af
ENDIF

R1NoErr:
	pop	bc
	ret

b_SPIStatus:
	push	af
	push	bc
	ld	b,200

b_ss1:
	in0	a,(SPI_SR)
IF SD_DEBUG
	bit	4,a
	jr	z, ChkWCol
SPI_ModeF:
	push	af
	ld	de, b_strSpiModf
	call	b_TXstringDE
	pop	af
ENDIF
ChkWCol:
	bit	6,a
	jr	z, ChkSpiF
IF SD_DEBUG
SPI_WCol:
	push	af
	ld	de, b_strSpiWcol
	call	b_TXstringDE
	pop	af
ENDIF

	bit	7,a
	jr	z, SPI_Finished

IF SD_DEBUG
	ld	de, b_strSpiSpiF
	call	b_TXstringDE
	jr	SPI_Finished
ENDIF

ChkSpiF:
	bit	7,a
	jr	nz, SPI_Finished

	djnz	b_ss1

IF SD_DEBUG
	ld	de, b_strSpifTof
	call	b_TXstringDE
ENDIF
	jr	SPI_Finished

SPI_Finished:
	in0	a,(SPI_SR)
	pop	bc
	pop	af
	ret


; --------------

b_SPICardDelay:	
	ld	a,0FFh
b_SPISendByte:	
	out0	(SPI_TSR),a
	call	b_SPIStatus
	in0	a,(SPI_RBR)
	ret

; --------------

b_SPIInit:
	ld	a,11111001b		; switch off LED, was 10001001b
	out0	(PB_DR),a
	ld	a,11101100b		; 0CCh.
	out0	(PB_DDR),a
	ld	a,00000000b		; 00h.
	out0	(PB_ALT1),a
	ld	a,11001100b		; 0CCh   Configure PORT B for alternative use.
	out0	(PB_ALT2),a		; bit 7O=MOSI,6I=MISO,5x=x,4x=x,3O=SCK,2I=SS,1x=x,0O=/CS.
	ld	a,00H			; Set SPI baudrate. SYSTEMCLOCK(in MHz) / (2 * ClockRate).
	out0	(SPI_BRG_H),a
	ld	a,64			; @ 50MHz CPU clock, 64 = 25MHz/64=390KHz
	out0	(SPI_BRG_L),a
	ld	a,3Ch			; 0011 0100 Enable SPI interface. CPOL=1=LK idles High, CPHA=1.
	out0	(SPI_CTL),a
IFDEF DEVKIT
ELSE
	ld		a,00Fh
	out0	(PA_DDR),a
ENDIF
	ret

; 24-bit shift left by 9 bits
b_SL32:
	ld	h,l
	ld	l,d
	ld	d,e
	ld	e,0			; 8-bit shift Left

	sla	d
	rl	l
	rl	h			; 24-bit shift left by 1 for a total of 9 bits.
	ret


b_mmcadrl	DW	0
b_mmcadrh	DW	0
b_mmcadrsll	DW	0
b_mmcadrslh	DW	0

IF SD_DEBUG
b_strRspTO	ASCII   "Rsp TO$"
b_strIllCmd	ASCII   "ILL CMD$"
b_strIllParm	ASCII	"ILL PARAM$"
b_strAddrErr	ASCII   "ADDR ERR$"

b_strSpiModf	ASCII   "SPI MODF$"
b_strSpiWcol	ASCII	"SPI WCOL$"
b_strSpiSpiF	ASCII   "!SPIF!$"

b_strSpifTof	ASCII   "SPIF TOF$"
ENDIF


; End of MMC routines.
