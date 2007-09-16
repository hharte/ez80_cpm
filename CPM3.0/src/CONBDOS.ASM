	title	'CP/M Bdos Interface, Bdos, Version 3.0 Nov, 1982'
;*****************************************************************
;*****************************************************************
;**                                                             **
;**   B a s i c    D i s k   O p e r a t i n g   S y s t e m    **
;**								**
;**               C o n s o l e   P o r t i o n                 **
;**                                                             **
;*****************************************************************
;*****************************************************************
;
;       November 1982
;
;
;	Console handlers
;

include	"cpm3_defs.inc"

EXTERN	CONINF
EXTERN	CONMODE, CONSTF
EXTERN	REBOOTX, CONOUTF, LISTCP, FX
PUBLIC	COMPOUT
EXTERN	LISTF, COLUMN
EXTERN	CONOUTF, OUTDELIM, CONBUFFADD
EXTERN	CONBUFFLEN, DMAAD, INFO
EXTERN	STRTCP
EXTERN	RUBOUT$ACT, SAVE$POS
EXTERN	CTLH$ACT, READERF, LRET$EQ$FF
EXTERN	AUXINSTF, AUXOUTSTF, CONINF, ARET, STHL$RET
EXTERN	OUT$DELIM
PUBLIC	PRINT

PUBLIC	func1, func2, func3
PUBLIC	func6, func7
PUBLIC	func8, func9, func10, func11
PUBLIC	func110, func111, func112

PUBLIC	CRLF
PUBLIC	setlret1

IF	.NOT. MPM
PUBLIC 	STA$RET
PUBLIC	FUNC$RET
ENDIF

	DEFINE BDOS, SPACE = RAM
	SEGMENT BDOS

CONIN:	
	;read console character to A
	LD	HL,KBCHAR
	LD	A,(HL)
	LD	(HL),0
	OR	A
	ret nz	
	;no previous keyboard character ready
	JP	CONINF		;get character externally
	;ret
;
CONECH:	
	LD	HL,STA$RET
	PUSH	HL
CONECH0:	
	;read character with echo
	CALL	CONIN
	CALL	echoc
	JP	C ,CONECH1	;echo character_
	;character must be echoed before return
	PUSH	AF
	LD	C,A
	CALL	tabout
	POP	AF
	RET	
CONECH1:	
	CALL	TEST$CTLS$MODE
	RET	NZ
	CP	CTLS
	JP	NZ,CONECH2
	CALL	CONBRK2
	JP	CONECH0
CONECH2:	
	CP	CTLQ
	JP	Z ,CONECH0
	CP	CTLP
	JP	Z ,CONECH0
	RET	
;
echoc:	
	;echo character if graphic
	;cr, lf, tab, or backspace
	CP	CR
	ret	z		;carriage return_
	CP	LF
	ret	z		;line feed_
	CP	TAB
	ret	z		;tab_
	CP	CTLH
	ret	z		;backspace_
	CP	' '
	RET			;carry set if not graphic
;
CONSTX:	
	LD	A,(KBCHAR)
	OR	A
	JP	NZ,CONB1
	CALL	CONSTF
	AND	1
	RET	
;
IF	BANKED
SET$CTLS$MODE:	
	;SET CTLS STATUS OR INPUT FLAG FOR QUEUE MANAGER
	LD	HL,QFLAG
	LD	(HL),40H
	EX	(SP),HL
	JP	(HL)
ENDIF	
;
TEST$CTLS$MODE:	
	;RETURN WITH Z FLAG RESET IF CTL-S CTL-Q CHECKING DISABLED
	LD	B,A
	LD	A,(CONMODE)
	AND	2
	LD	A,B
	RET	
;
conbrk:	;check for character ready
	CALL	TEST$CTLS$MODE
	JP	NZ,CONSTX
	LD	A,(KBCHAR)
	OR	A
	jr	nz,CONBRK1		;skip if active KBCHAR
	;no active KBCHAR, check external break
	;DOES BIOS HAVE TYPE AHEAD_
IF	BANKED
	LD	A,(TYPE$AHEAD)
	INC	A
	JP	Z ,CONSTX	;YES
ENDIF	
	;CONBRKX CALLED BY CONOUT
CONBRKX:	
	;HAS CTL-S INTEret cEPT BEEN DISABLED_
	CALL	TEST$CTLS$MODE
	RET	NZ		;YES
	;DOES KBCHAR CONTAIN CTL-S_
	LD	A,(KBCHAR)
	CP	CTLS
	JP	Z ,CONBRK1	;YES
IF	BANKED
	CALL	SET$CTLS$MODE
ENDIF	
	;IS A CHARACTER READY FOR INPUT_
	CALL	CONSTF
IF	BANKED
	POP	HL
	LD	(HL),0
ENDIF	
	AND	1
	ret z			;NO
	;character ready, read it
IF	BANKED
	CALL	SET$CTLS$MODE
ENDIF	
	CALL	CONINF
IF	BANKED
	POP	HL
	LD	(HL),0
ENDIF	
CONBRK1:	
	CP	CTLS
	jr nz,	conb0		;check stop screen function
	;DOES KBCHAR CONTAIN A CTL-S_
	LD	HL,KBCHAR
	CP	(HL)
	JP	NZ,CONBRK2	;NO
	LD	(HL),0		; KBCHAR = 0
	;found ctls, read next character
CONBRK2:	
IF	BANKED
	CALL	SET$CTLS$MODE
ENDIF	
	CALL	CONINF		;to A
IF	BANKED
	POP	HL
	LD	(HL),0
ENDIF	
	CP	CTLC
	JP	NZ,CONBRK3
	LD	A,(CONMODE)
	AND	08H
	JP	Z ,REBOOTX
	XOR	A
CONBRK3:	
	SUB	A,CTLQ
	RET	Z 		; RETURN WITH A = ZERO IF CTLQ
	INC	A
	CALL	CONB3
	JP	CONBRK2
conb0:	
	LD	HL,KBCHAR
	LD	B,A
	;IS CONMODE(1) TRUE_
	LD	A,(CONMODE)
	RRA	
	JP	NC,$+7		;NO
	;DOES KBCHAR = CTLC_
	LD	A,CTLC
	CP	(HL)
	RET	Z 		;YES - RETURN
	LD	A,B
	CP	CTLQ
	JP	Z ,CONB2
	CP	CTLP
	JP	Z ,CONB2
	;character in accum, save it
	LD	(HL),A
CONB1:	
	;return with true set in accumulator
	LD	A,1
	RET	
CONB2:	
	XOR	A
	LD	(HL),A
	RET	
CONB3:	
	CALL	Z ,TOGGLE$LISTCP
	LD	C,7
	CALL	NZ,CONOUTF
	RET	
;
TOGGLE$LISTCP:	
	; IS PRINTER ECHO DISABLED_
	LD	A,(CONMODE)
	AND	14H
	JP	NZ,TOGGLE$L1	;YES
	LD	HL,LISTCP
	LD	A,1
	XOR	(HL)
	AND	1
	LD	(HL),A
	RET	
TOGGLE$L1:	
	XOR	A
	RET	
;
QCONOUTF:	
	;DOES FX = INPUT_
	LD	A,(FX)
	DEC	A
	JP	Z ,CONOUTF	;YES
	;IS ESCAPE SEQUENCE DECODING IN EFFECT_
	LD	A,B
;;;	ANI 8		;[JCE] DRI Patch 13
	AND	10h
	JP	NZ,SCONOUTF	;YES
	JP	CONOUTF
;
CONOUT:	
	;compute character position/write console char from C
	;compcol = true if computing COLUMN position
	LD	A,(compcol)
	OR	A
	jr nz,	COMPOUT
	;write the character, then compute the COLUMN
	;write console character from C
	;B ~= 0 -> ESCAPE SEQUENCE DECODING
	LD	A,(CONMODE)
	AND	14H
	LD	B,A
	PUSH	BC
	;CALL CONBRKX FOR OUTPUT FUNCTIONS ONLY
	LD	A,(FX)
	DEC	A
	CALL	NZ,CONBRKX
	POP	BC
	PUSH	BC		;recall/save character
	CALL	QCONOUTF	;externally, to console
	POP	BC
	;SKIP ECHO WHEN CONMODE & 14H ~= 0
	LD	A,B
	OR	A
	JP	NZ,COMPOUT
	PUSH	BC		;recall/save character
	;may be copying to the list device
	LD	A,(LISTCP)
	OR	A
	call	nz,LISTF		;to printer, if so
	POP	BC		;recall the character
COMPOUT:	
	LD	A,C		;recall the character
	;and compute COLUMN position
	LD	HL,COLUMN	;A = char, HL = .COLUMN
	CP	RUBOUT
	ret z			;no COLUMN change if nulls
	INC	(HL)		;COLUMN = COLUMN + 1
	CP	' '
	ret nc			;return if graphic
	;not graphic, reset COLUMN position
	DEC	(HL)		;COLUMN = COLUMN - 1
	LD	A,(HL)
	OR	A
	ret z			;return if at zero
	;not at zero, may be backspace or end line
	LD	A,C		;character back to A
	CP	CTLH
	jr nz,	notbacksp
	;backspace character
	DEC	(HL)		;COLUMN = COLUMN - 1
	RET	
notbacksp:	
	;not a backspace character, eol_
	CP	CR
	ret nz			;return if not
	;end of line, COLUMN = 0
	LD	(HL),0		;COLUMN = 0
	RET	
;
ctlout:	
	;send C character with possible preceding up-arrow
	LD	A,C
	CALL	echoc		;cy if not graphic (or special case)
	jr nc,	tabout		;skip if graphic, tab, cr, lf, or ctlh
	;send preceding up arrow
	PUSH	AF
	LD	C,CTL
	CALL	CONOUT		;up arrow
	POP	AF
	OR	40h		;becomes graphic letter
	LD	C,A		;ready to PRINT
IF	BANKED
	CALL	chk$COLUMN
	ret z	
ENDIF	
	;(drop through to tabout)
;
tabout:	
	;IS FX AN INPUT FUNCTION_
	LD	A,(FX)
	DEC	A
	JP	Z ,TABOUT1	;YES - ALWAYS EXPAND TABS FOR ECHO
	;HAS TAB EXPANSION BEEN DISABLED OR
	;ESCAPE SEQUENCE DECODING BEEN ENABLED_
	LD	A,(CONMODE)
	AND	14H
	JP	NZ,CONOUT	;YES
TABOUT1:	
	;expand tabs to console
	LD	A,C
	CP	TAB
	jr nz,	CONOUT		;direct to CONOUT if not
	;tab encountered, move to next tab position
tab0:	
IF	BANKED
	LD	A,(FX)
	CP	1
	jr nz,	tab1
	CALL	chk$COLUMN
	ret z	
tab1:	
ENDIF	
	LD	C,' '
	CALL	CONOUT		;another blank
	LD	A,(COLUMN)
	AND	111b		;COLUMN mod 8 = 0 _
	jr nz,	tab0		;back for another if not
	RET	
;
;
backup:	
	;back-up one screen position
	CALL	pctlh
IF	BANKED
	LD	A,(comchr)
	CP	ctla
	ret z	
ENDIF	
	LD	C,' '
	CALL	CONOUTF
;	(drop through to pctlh)				;
pctlh:	
	;send ctlh to console without affecting COLUMN count
	LD	C,CTLF
	JP	CONOUTF
	;ret
;
crlfp:	
	;PRINT #, cr, lf for ctlx, ctlu, ctlr functions
	;then move to strtcol (starting COLUMN)
	LD	C,'#'
	CALL	CONOUT
	CALL	CRLF
	;COLUMN = 0, move to position strtcol
crlfp0:	
	LD	A,(COLUMN)
	LD	HL,strtcol
	CP	(HL)
	ret nc			;stop when COLUMN reaches strtcol
	LD	C,' '
	CALL	CONOUT		;PRINT blank
	JP	crlfp0
;;
;
CRLF:	
	;carriage return line feed sequence
	LD	C,CR
	CALL	CONOUT
	LD	C,LF
	JP	CONOUT
	;ret
;
PRINT:	
	;PRINT message until M(BC) = '$'
	LD	HL,OUTDELIM
	LD	A,(BC)
	CP	(HL)
	ret z			;stop on $
	;more to PRINT
	INC	BC
	PUSH	BC
	LD	C,A		;char to C
	CALL	tabout		;another character printed
	POP	BC
	JP	PRINT
;
QCONIN:	
IF	BANKED
	LD	HL,(apos)
	LD	A,(HL)
	LD	(ctla$sw),A
ENDIF	
	;IS BUFFER ADDRESS = 0_
	LD	HL,(CONBUFFADD)
	LD	A,L
	OR	H
	JP	Z ,CONIN	;YES
	;IS CHARACTER IN BUFFER < 5_
IF	BANKED
	CALL	qconinx		; mov a,m with bank 1 switched in
ELSE	
	LD	A,(HL)
ENDIF	
	INC	HL
	OR	A
	JP	NZ,QCONIN1	; NO
	LD	HL,0
QCONIN1:	
	LD	(CONBUFFADD),HL
	LD	(CONBUFFLEN),HL
	RET	NZ		; NO
	JP	CONIN
IF	BANKED
	
chk$COLUMN:	
	LD	A,(conwidth)
	LD	E,A
	LD	A,(COLUMN)
	CP	E
	RET	
;
expand:	
	EX	DE,HL
	LD	HL,(apos)
	EX	DE,HL
expand1:	
	LD	A,(DE)
	OR	A
	ret z	
	INC	DE
	INC	HL
	LD	(HL),A
	INC	B
	JP	expand1
;
copy$xbuff:	
	LD	A,B
	OR	A
	ret z	
	PUSH	BC
	LD	C,B
	PUSH	HL
	EX	DE,HL
	INC	DE
	LD	HL,xbuff
	CALL	move
	LD	(HL),0
	LD	(xpos),HL
	POP	HL
	POP	BC
	RET	
;
copy$cbuff:	
	LD	A,(ccpflgs+1)
	RLA	
	ret nc	
	LD	HL,xbuff
	LD	DE,cbuff
	INC	C
	jr nz,	copy$cbuff1
	EX	DE,HL
	LD	A,B
	OR	A
	ret z	
	LD	(cbuff$len),A
	PUSH	DE
	LD	BC,copy$cbuff2
	PUSH	BC
	LD	B,A
copy$cbuff1:	
	INC	B
	LD	C,B
	JP	move
copy$cbuff2:	
	POP	HL
	DEC	HL
	LD	(HL),0
	RET	
;
save$col:	
	LD	A,(COLUMN)
	LD	(save$COLUMN),A
	RET	
;
clear$right:	
	LD	A,(COLUMN)
	LD	HL,ctla$COLUMN
	CP	(HL)
	ret nc	
	LD	C,20h
	CALL	CONOUT
	JP	clear$right
;
reverse:	
	LD	A,(save$COLUMN)
	LD	HL,COLUMN
	CP	(HL)
	ret nc	
	LD	C,ctlh
	CALL	CONOUT
	JP	reverse
;
chk$buffer$size:	
	PUSH	BC
	PUSH	HL
	LD	HL,(apos)
	LD	E,0
cbs1:	
	LD	A,(HL)
	OR	A
	jr z,	cbs2
	INC	E
	INC	HL
	JP	cbs1
cbs2:	
	LD	A,B
	ADD	A,E
	CP	C
	PUSH	AF	a
	LD	C,7
	call nc,	CONOUTF
	POP	AF	a
	POP	HL
	POP	BC
	ret	c	
	POP	DE
	POP	DE
	JP	readnx
;
refresh:	
	LD	A,(ctla$sw)
	OR	A
	ret	z	
	LD	A,(comchr)
	CP	ctla
	ret	z	
	CP	ctlf
	ret	z	
	CP	ctlw
	ret	z	
refresh0:	
	PUSH	HL
	PUSH	BC
	CALL	save$col
	LD	HL,(apos)
refresh1:	
	LD	A,(HL)
	OR	A
	jr	z,refresh2
	LD	C,A
	CALL	chk$COLUMN
	jr	c,refresh05
	LD	A,E
	LD	(COLUMN),A
	JP	refresh2
refresh05:	
	PUSH	HL
	CALL	ctlout
	POP	HL
	INC	HL
	JP	refresh1
refresh2:	
	LD	A,(COLUMN)
	LD	(new$ctla$col),A
refresh3:	
	CALL	clear$right
	CALL	reverse
	LD	A,(new$ctla$col)
	LD	(ctla$COLUMN),A
	POP	BC
	POP	HL
	RET	
;
init$apos:	
	LD	HL,aposi
	LD	(apos),HL
	XOR	A
	LD	(ctla$sw),A
	RET	
;
init$xpos:	
	LD	HL,xbuff
	LD	(xpos),HL
	RET	
;
set$ctla$COLUMN:	
	LD	HL,ctla$sw
	LD	A,(HL)
	OR	A
	ret nz	
	INC	(HL)
	LD	A,(COLUMN)
	LD	(ctla$COLUMN),A
	RET	
;
readi:	
	CALL	chk$COLUMN
	call nc,	CRLF
	LD	A,(cbuff$len)
	LD	B,A
	LD	C,0
	CALL	copy$cbuff
ELSE	
readi:	
	LD	A,D
	OR	E
	JP	NZ,read
	LD	HL,(DMAAD)
	LD	(INFO),HL
	INC	HL
	INC	HL
	LD	(CONBUFFADD),HL
ENDIF	
read:	;read to INFO address (max length, current length, buffer)
IF	BANKED
	CALL	init$xpos
	CALL	init$apos
readx:	
	CALL	refresh
	XOR	A
	LD	(ctlw$sw),A
readx1:	
ENDIF	
	LD	A,1
	LD	(FX),A
	LD	A,(COLUMN)
	LD	(strtcol),A	;save start for ctl-x, ctl-h
	LD	HL,(INFO)
	LD	C,(HL)
	INC	HL
	PUSH	HL
	XOR	A
	LD	B,A
	LD	(SAVEPOS),A
	CP	C
	JP	NZ,$+4
	INC	C
	;B = current buffer length,
	;C = maximum buffer length,
	;HL= next to fill - 1
readnx:	
	;read next character, BC, HL active
	PUSH	BC
	PUSH	HL		;blen, cmax, HL saved
readn0:	
IF	BANKED
	LD	A,(ctlw$sw)
	OR	A
	cz	qconin
nxtline:	
	LD	(comchr),A
ELSE	
	CALL	QCONIN		;next char in A
ENDIF	
	;ani 7fh ;mask parity bit
	POP	HL
	POP	BC		;reactivate counters
	CP	CR
	jr z,	readen		;end of line_
	CP	LF
	jr z,	readen		;also end of line
IF	BANKED
	CP	ctlf
	jr nz,	not$ctlf
do$ctlf:	
	CALL	chk$COLUMN
	DEC	E
	CP	E
	jr nc,	readnx
do$ctlf0:	
	EX	DE,HL
	LD	HL,(apos)
	LD	A,(HL)
	OR	A
	jr z,	ctlw$l15
	INC	HL
	LD	(apos),HL
	EX	DE,HL
	JP	notr
not$ctlf:	
	CP	ctlw
	jr nz,	not$ctlw
do$ctlw:	
	EX	DE,HL
	LD	HL,(apos)
	LD	A,(HL)
	OR	A
	jr z,	ctlw$l1
	EX	DE,HL
	CALL	chk$COLUMN
	DEC	E
	CP	E
	EX	DE,HL
	jc	ctlw$l0
	EX	DE,HL
	CALL	refresh0
	EX	DE,HL
	JP	ctlw$l13
ctlw$l0:	
	LD	HL,(apos)
	LD	A,(HL)
	INC	HL
	LD	(apos),HL
	JP	ctlw$l3
ctlw$l1:	
	LD	HL,ctla$sw
	LD	A,(HL)
	LD	(HL),0
	OR	A
	jr z,	ctlw$l2
ctlw$l13:	
	LD	HL,ctlw$sw
	LD	(HL),0
ctlw$l15:	
	EX	DE,HL
	JP	readnx
ctlw$l2:	
	LD	A,(ctlw$sw)
	OR	A
	jr nz,	ctlw$l25
	LD	A,B
	OR	A
	jr nz,	ctlw$l15
	CALL	init$xpos
ctlw$l25:	
	LD	HL,(xpos)
	LD	A,(HL)
	OR	A
	LD	(ctlw$sw),A
	jr z,	ctlw$l15
	INC	HL
	LD	(xpos),HL
ctlw$l3:	
	LD	HL,ctlw$sw
	LD	(HL),ctlw
	EX	DE,HL
	JP	notr
not$ctlw:	
	CP	ctla
	jr nz,	not$ctla
do$ctla:	
	;do we have any characters to back over_
	LD	A,(strtcol)
	LD	D,A
	LD	A,(COLUMN)
	CP	D
	jr z,	readnx
	LD	(compcol),A	;COL > 0
	LD	A,B
	OR	A
	jr z,	linelen
	;characters remain in buffer, backup one
	DEC	B		;remove one character
	;compcol > 0 marks repeat as length compute
	;backup one position in xbuff
	PUSH	HL
	CALL	set$ctla$COLUMN
	POP	DE
	LD	HL,(apos)
	DEC	HL
	LD	(apos),HL
	LD	A,(DE)
	LD	(HL),A
	EX	DE,HL
	JP	linelen
not$ctla:	
	CP	ctlb
	jr nz,	not$ctlb
do$ctlb:	
	LD	A,(save$pos)
	CP	B
	jr nz,	ctlb$l0
	LD	A,ctlw
	LD	(ctla$sw),A
	LD	(comchr),A
	JP	do$ctlw
ctlb$l0:	
	EX	DE,HL
	LD	HL,(apos)
	INC	B
ctlb$l1:	
	DEC	B
	LD	A,(save$pos)
	CP	B
	jr z,	ctlb$l2
	DEC	HL
	LD	A,(DE)
	LD	(HL),A
	DEC	DE
	JP	ctlb$l1
ctlb$l2:	
	LD	(apos),HL
	PUSH	BC
	PUSH	DE
	CALL	set$ctla$COLUMN
ctlb$l3:	
	LD	A,(COLUMN)
	LD	B,A
	LD	A,(strtcol)
	CP	B
	jr z,	read$n0
	LD	C,ctlh
	CALL	CONOUT
	JP	ctlb$l3
not$ctlb:	
	CP	ctlk
	jr nz,	not$ctlk
	EX	DE,HL
	LD	HL,aposi
	LD	(apos),HL
	EX	DE,HL
	CALL	refresh
	JP	readnx
not$ctlk:	
	CP	ctlg
	jr nz,	not$ctlg
	LD	A,(ctla$sw)
	OR	A
	jr z,	readnx
	JP	do$ctlf0
not$ctlg:	
ENDIF	
	CP	CTLH
	jr nz,	noth		;backspace_
	LD	A,(CTLH$ACT)
	INC	A
	JP	Z ,DO$RUBOUT
DO$CTLH:	
	;do we have any characters to back over_
	LD	A,(strtcol)
	LD	D,A
	LD	A,(COLUMN)
	CP	D
	jr z,	readnx
	LD	(compcol),A	;COL > 0
	LD	A,B
	OR	A
	JP	Z ,$+4
	;characters remain in buffer, backup one
	DEC	B		;remove one character
	;compcol > 0 marks repeat as length compute
	JP	linelen		;uses same code as repeat
noth:	
	;not a backspace
	CP	RUBOUT
	jr nz,	notrub		;rubout char_
	LD	A,(RUBOUT$ACT)
	INC	A
	JP	Z ,DO$CTLH
DO$RUBOUT:	
IF	BANKED
	LD	A,rubout
	LD	(comchr),A
	LD	A,(ctla$sw)
	OR	A
	jr nz,	do$ctlh
ENDIF	
	;rubout encountered, rubout if possible
	LD	A,B
	OR	A
	jr z,	readnx		;skip if len=0
	;buffer has characters, resend last char
	LD	A,(HL)
	DEC	B
	DEC	HL		;A = last char
	;blen=blen-1, next to fill - 1 decremented
	JP	rdech1		;act like this is an echo
notrub:	
	;not a rubout character, check end line
	CP	CTLE
	jr nz,	note		;physical end line_
	;yes, save active counters and force eol
	PUSH	BC
	LD	A,B
	LD	(SAVE$POS),A
	PUSH	HL
IF	BANKED
	LD	A,(ctla$sw)
	OR	A
	cnz	clear$right
ENDIF	
	CALL	CRLF
IF	BANKED
	CALL	refresh
ENDIF	
	XOR	A
	LD	(strtcol),A	;start position = 00
	JP	readn0		;for another character
note:	
	;not end of line, list toggle_
	CP	CTLP
	jr 	nz,notp		;skip if not ctlp
	;list toggle - change parity
	PUSH	HL		;save next to fill - 1
	PUSH	BC
	XOR	A
	CALL	CONB3
	POP	BC
	POP	HL
	JP	readnx		;for another char
notp:	
	;not a ctlp, line delete_
	CP	CTLX
	jr nz,	notx
	POP	HL		;discard start position
	;loop while COLUMN > strtcol
backx:	
	LD	A,(strtcol)
	LD	HL,COLUMN
IF	BANKED
	CP	(HL)
	jc	backx1
	LD	HL,(apos)
	LD	A,(HL)
	OR	A
	jr nz,	readx
	JP	read
backx1:	
ELSE	
	CP	(HL)
	jr nc,	read		;start again
ENDIF	
	DEC	(HL)		;COLUMN = COLUMN - 1
	CALL	backup		;one position
	JP	backx
notx:	
	;not a control x, control u_
	;not control-X, control-U_
	CP	CTLU
	jr nz,	notu		;skip if not
IF	BANKED
	EX	(SP),HL
	CALL	copy$xbuff
	EX	(SP),HL
ENDIF	
	;delete line (ctlu)
do$ctlu:	
	CALL	crlfp		;physical eol
	POP	HL		;discard starting position
	JP	read		;to start all over
notu:	
	;not line delete, repeat line_
	CP	CTLR
	jr nz,	notr
	XOR	A
	LD	(SAVEPOS),A
IF	BANKED
	EX	DE,HL
	CALL	init$apos
	EX	DE,HL
	LD	A,B
	OR	A
	jr z,	do$ctlu
	EX	DE,HL
	LD	HL,(apos)
	INC	B
ctlr$l1:	
	DEC	B
	jr z,	ctlr$l2
	DEC	HL
	LD	A,(DE)
	LD	(HL),A
	DEC	DE
	JP	ctlr$l1
ctlr$l2:	
	LD	(apos),HL
	PUSH	BC
	PUSH	DE
	CALL	crlfp
	LD	A,ctlw
	LD	(ctlw$sw),A
	LD	(ctla$sw),A
	JP	readn0
ENDIF	
linelen:	
	;repeat line, or compute line len (ctlh)
	;if compcol > 0
	PUSH	BC
	CALL	crlfp		;save line length
	POP	BC
	POP	HL
	PUSH	HL
	PUSH	BC
	;bcur, cmax active, beginning buff at HL
rep0:	
	LD	A,B
	OR	A
	jr 	z,rep1		;count len to 00
	INC	HL
	LD	C,(HL)		;next to PRINT
	DEC	B
	POP	DE
	PUSH	DE
	LD	A,D
	SUB	A,B
	LD	D,A
	PUSH	BC
	PUSH	HL		;count length down
	LD	A,(SAVEPOS)
	CP	D
	CALL	C ,ctlout
	POP	HL
	POP	BC		;recall remaining count
	JP	rep0		;for the next character
rep1:	
	;end of repeat, recall lengths
	;original BC still remains pushed
	PUSH	HL		;save next to fill
	LD	A,(compcol)
	OR	A		;>0 if computing length
	jr z,	readn0		;for another char if so
	;COLUMN position computed for ctlh
	LD	HL,COLUMN
	SUB	A,(HL)		;diff > 0
	LD	(compcol),A	;count down below
	;move back compcol-COLUMN spaces
backsp:	
	;move back one more space
	CALL	backup		;one space
	LD	HL,compcol
	DEC	(HL)
	jr nz,	backsp
IF	BANKED
	CALL	refresh
ENDIF	
	JP	readn0		;for next character
notr:	
	;not a ctlr, place into buffer
	;IS BUFFER FULL_
	PUSH	AF
	LD	A,B
	CP	C
	JP	C ,RDECH0	;NO
	;DISCARD CHARACTER AND RING BELL
	POP	AF
	PUSH	BC
	PUSH	HL
	LD	C,7
	CALL	CONOUTF
	JP	readn0
RDECH0:	
IF	BANKED
	LD	A,(comchr)
	CP	ctlg
	jr z,	rdech05
	LD	A,(ctla$sw)
	OR	A
	cnz	chk$buffer$size
rdech05:	
ENDIF	
	POP	AF
	INC	HL
	LD	(HL),A		;character filled to mem
	INC	B		;blen = blen + 1
rdech1:	
	;look for a random control character
	PUSH	BC
	PUSH	HL		;active values saved
	LD	C,A		;ready to PRINT
IF	BANKED
	CALL	save$col
ENDIF	
	CALL	ctlout		;may be up-arrow C
	POP	HL
	POP	BC
IF	BANKED
	LD	A,(comchr)
	CP	ctlg
	jr z,	do$ctlh
	CP	rubout
	jr z,	rdech2
	CALL	refresh
rdech2:	
ENDIF	
	LD	A,(CONMODE)
	AND	08H
;;;			jr nz, NOTC	;[JCE] DRI Patch 13
	jr nz,	patch$064b
	LD	A,(HL)		;recall char
	CP	CTLC		;set flags for reboot test
patch$064b:	LD	A,B	;move length to A
	jr nz,	notc		;skip if not a control c
	CP	1		;control C, must be length 1
	jr z,	REBOOTX		;reboot if blen = 1
	;length not one, so skip reboot
notc:	
	;not reboot, are we at end of buffer_
IF	BANKED
	CP	C
	jr 	nc,buffer$full
ELSE	
	JP	readnx		;go for another if not
ENDIF	
IF	BANKED
	PUSH	BC
	PUSH	HL
	CALL	chk$COLUMN
	jc	readn0
	LD	A,(ctla$sw)
	OR	A
	jr z,	do$new$line
	LD	A,(comchr)
	CP	ctlw
	jr z,	back$one
	CP	ctlf
	jr z,	back$one
	
do$newline:	
	LD	A,ctle
	JP	nxtline
back$one:	
	;back up to previous character
	POP	HL
	POP	BC
	DEC	B
	EX	DE,HL
	LD	HL,(apos)
	DEC	HL
	LD	(apos),HL
	LD	A,(DE)
	LD	(HL),A
	EX	DE,HL
	DEC	HL
	PUSH	BC
	PUSH	HL
	CALL	reverse
	;disable ctlb or ctlw
	XOR	A
	LD	(ctlw$sw),A
	JP	readn0
	
buffer$full:	
	XOR	A
	LD	(ctlw$sw),A
	JP	readnx
ENDIF	
readen:	
	;end of read operation, store blen
IF	BANKED
	CALL	expand
ENDIF	
	POP	HL
	LD	(HL),B		;M(current len) = B
IF	BANKED
	PUSH	BC
	CALL	copy$xbuff
	POP	BC
	LD	C,0ffh
	CALL	copy$cbuff
ENDIF	
	LD	HL,0
	LD	(CONBUFFADD),HL
	LD	C,CR
	JP	CONOUT		;return carriage
	;ret
;
func1:	equ	CONECH
	;return console character with echo
;
func2:	equ	tabout
	;write console character with tab expansion
;
func3:	
	;return reader character
	CALL	READERF
	JP	STA$RET
;
;func4:	equated to punchf
	;write punch character
;
;func5:	equated to LISTF
	;write list character
	;write to list device
;
func6:	
	;direct console i/o - read if 0ffh
	LD	A,C
	INC	A
	jr 	z,dirinp		;0ffh => 00h, means input mode
	INC	A
	JP	Z ,DIRSTAT	;0feh => direct STATUS function
	INC	A
	JP	Z ,DIRINP1	;0fdh => direct input, no status
	JP	CONOUTF
DIRSTAT:	
	;0feH in C for status
	CALL	CONSTX
	JP	NZ,LRET$EQ$FF
	JP	STA$RET
dirinp:	
	CALL	CONSTX		;status check
	OR	A
	RET	Z 		;skip, return 00 if not ready
	;character is ready, get it
DIRINP1:	
	CALL	CONIN		;to A
	JP	STA$RET
;
func7:	
	CALL	AUXINSTF
	JP	STA$RET
;
func8:	
	CALL	AUXOUTSTF
	JP	STA$RET
;
func9:	
	;write line until $ encountered
	EX	DE,HL		;was lhld INFO	
	LD	C,L
	LD	B,H		;BC=string address
	JP	PRINT		;out to console	
func10:	equ	readi
	;read a buffered console line
func11:	
	;IS CONMODE(1) TRUE_
	LD	A,(CONMODE)
	RRA	
	JP	NC,NORMAL$STATUS;NO
	;CTL-C ONLY STATUS CHECK
IF	BANKED
	LD	HL,QFLAG
	LD	(HL),80H
	PUSH	HL
ENDIF	
	LD	HL,CTLC$STAT$RET
	PUSH	HL
	;DOES KBCHAR = CTL-C_
	LD	A,(KBCHAR)
	CP	CTLC
	JP	Z ,CONB1	;YES
	;IS THERE A READY CHARACTER_
	CALL	CONSTF
	OR	A
	RET	Z 		;NO
	;IS THE READY CHARACTER A CTL-C_
	CALL	CONINF
	CP	CTLC
	JP	Z ,conb0	;YES
	LD	(KBCHAR),A
	XOR	A
	RET	
CTLC$STAT$RET:	
IF	BANKED
	CALL	STA$RET
	POP	HL
	LD	(HL),0
	RET	
ELSE	
	JP	STA$RET
ENDIF	
NORMAL$STATUS:	
	;check console status
	CALL	conbrk
	;(drop through to STA$RET)
STA$RET:	
	;store the A register to ARET
	LD	(ARET),A
FUNC$RET:	;
	RET			;jmp goback (pop stack for non cp/m functions)
;
setlret1:	
	;set lret = 1
	LD	A,1
	JP	STA$RET		;
;
FUNC109:	;GET/SET CONSOLE MODE
	;DOES DE = 0FFFFH_
	LD	A,D
	AND	E
	INC	A
	LD	HL,(CONMODE)
	JP	Z ,STHL$RET	;YES - RETURN CONSOLE MODE
	EX	DE,HL
	LD	(CONMODE),HL
	RET			;NO - SET CONSOLE MODE
;
func110:	;GET/SET FUNCTION 9 DELIMITER
	LD	HL,OUT$DELIM
	;DOES DE = 0FFFFH_
	LD	A,D
	AND	E
	INC	A
	LD	A,(HL)
	JP	Z ,STA$RET	;YES - RETURN DELIMITER
	LD	(HL),E
	RET			;NO - SET DELIMITER
;
func111:	;PRINT BLOCK TO CONSOLE
func112:	;LIST BLOCK
	EX	DE,HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	EX	DE,HL
	;HL = ADDR OF STRING
	;BC = LENGTH OF STRING
BLK$OUT:	
	LD	A,B
	OR	C
	RET	Z 
	PUSH	BC
	PUSH	HL
	LD	C,(HL)
	LD	A,(FX)
	CP	111
	JP	Z ,BLK$OUT1
	CALL	LISTF
	JP	BLK$OUT2
BLK$OUT1:	
	CALL	tabout
BLK$OUT2:	
	POP	HL
	INC	HL
	POP	BC
	DEC	BC
	JP	BLK$OUT
SCONOUTF:	EQU	CONOUTF
;
;	data areas
;
compcol:	DB	0	;true if computing COLUMN position
strtcol:	DB	0	;starting COLUMN position after read
IF	.not.	BANKED
KBCHAR:		DB	0		;initial key char = 00
ENDIF	
SAVEPOS:	DB	0	;POSITION IN BUFFER CORRESPONDING TO
	;BEGINNING OF LINE
IF	BANKED
comchr:	DB	0
cbuff$len:	DB	0
cbuff:	DS	256
	DB	0
xbuff:	DB	0
	DS	354
aposi:	DB	0
xpos:	DW	0
apos:	DW	0
ctla$sw:	DB	0
ctlw$sw:	DB	0
save$COLUMN:	DB	0
ctla$COLUMN:	DB	0
new$ctla$col:	DB	0
ENDIF	
;	end of BDOS Console module
