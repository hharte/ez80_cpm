;*************************************************************************
;*                                                                       *
;* $Id: sdmem_dbg.asm 1555 2007-09-14 07:37:35Z hharte $                 *
;*                                                                       *
;* Copyright (c) 2005-2007 Howard M. Harte                               *
;* https://github.com/hharte                                             *
;*                                                                       *
;* Module Description:                                                   *
;*     eZ80F91 SD/MMC Debug routines                                     *
;*                                                                       *
;* Environment:                                                          *
;*     Zilog ZDS-II v4.11.1, (http://www.zilog.com)                      *
;*                                                                       *
;*************************************************************************

EXTERN _adrv, _trk, _sect

EXTERN _cono

PUBLIC	b_TXstringDE
PUBLIC	b_TXdskStats
EXTERN	b_mmcadrh
EXTERN	b_mmcadrl
EXTERN	b_mmcadrslh
EXTERN	b_mmcadrsll

	DEFINE BIOS, SPACE = RAM
	SEGMENT BIOS

b_TXstringDE:
		ld	a,(de)
		cp	a,'$'
		ret	z
		ld	c,a
		call	_cono
		inc	de
		jr	b_TXstringDE
		
b_TXhexDE:
	ld		a,d
	call	b_TXhexA
	ld		a,e
	call	b_TXhexA
	ret

b_TXhexA:
	push	af							; Save our number for round 2 below.
	and		0F0h						; Mask off bottom 4 bits.
	rra									; Shift top 4 bits down.
	rra									; Shift top 4 bits down.
	rra									; Shift top 4 bits down.
	rra									; Shift top 4 bits down.
	call	b_TXhexA1					; Display first hex digit.
	pop		af							; Restore our number.
	and		0Fh							; Mask off top 4 bits.
	call	b_TXhexA1					; Display first hex digit.
	ret

b_TXhexA1:
	push	de
	ld		hl,b_hexdigits				; Get address of our hex-digit string.
	ld		d,00h						; Zero D as we only need 8 bit addition.
	ld		e,a							; Load E with binary digit.
	add		hl,de						; Calculate offset into the string.
	ld		c,(hl)						; Load C with the ASCII digit.
	call	_cono	;b_conout					; Display it.
	pop		de
	ret									; Done.

b_TXdskStats:
;		ret	; hharte
;	ld		a,(READOP)
;	or		a
;	jr		nz,b_tds1
;	ld		de,b_mwrite
;	jr		b_tds2
b_tds1:
;	ld		de,b_mread
b_tds2:
;	call	b_TXstringDE

	ld		de,b_mdisk
	call	b_TXstringDE
	ld		a,(_adrv)
	call	b_TXhexA
	
	ld		de,b_mtrack
	call	b_TXstringDE
	ld		de,(_trk)
	call	b_TXhexDE

	ld		de,b_msector
	call	b_TXstringDE
	ld		a,(_sect)
	call	b_TXhexA

	ld		de,b_mmmcadr
	call	b_TXstringDE
	ld		de,(b_mmcadrh)
	call	b_TXhexDE
	ld		de,(b_mmcadrl)
	call	b_TXhexDE

	ld		de,b_mmmcadrs
	call	b_TXstringDE
	ld		de,(b_mmcadrslh)
	call	b_TXhexDE
	ld		de,(b_mmcadrsll)
	call	b_TXhexDE

	ret

b_hexdigits:	ASCII	"0123456789ABCDEF"
b_mread:	ASCII	"\r\nRD$"
b_mwrite:	ASCII	"\r\nWR$"
b_mdisk:	ASCII	", DSK=$"
b_mtrack:	ASCII	", TRK=$"
b_msector:	ASCII	", SEC=$"
b_mmmcadr:	ASCII	", MMCaddr=$"
b_mmmcadrs:	ASCII	", MMCsaddr=$"

; End of Debug routines.
