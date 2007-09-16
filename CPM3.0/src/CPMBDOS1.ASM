	title	'CP/M BDOS Interface, BDOS, Version 3.0 Dec, 1982'
;*****************************************************************
;*****************************************************************
;**                                                             **
;**   B a s i c    D i s k   O p e r a t i n g   S y s t e m    **
;**								**
;**            I n t e r f a c e   M o d u l e                  **
;**                                                             **
;*****************************************************************
;*****************************************************************
;
;	Copyright (c) 1978, 1979, 1980, 1981, 1982
;	Digital Research
;	Box 579, Pacific Grove
;	California
;
;       December 1982
;
include "cpm3_defs.inc"

PUBLIC	FX
PUBLIC	LISTF
PUBLIC	rebootx1
PUBLIC	movef
PUBLIC	flushf
PUBLIC	wbootf
PUBLIC	flushf
PUBLIC	move$tpa
PUBLIC	move$out
	
;	org	0000h
;base:	equ	0000h ;$
; Base page definitions
bnkbdos$pg:	equ	base+0fc00h
resbdos$pg:	equ	base+0fd00h
scb_pg:	equ	base+0fb00h
bios$pg:	equ	base+0ff00h
; Bios equates
bios:	equ	bios$pg
bootf:	equ	bios$pg		; 00. cold boot function
IF	BANKED
wbootf:	equ	scb_pg+68h	; 01. warm boot function
CONSTF:	equ	scb_pg+6eh	; 02. console status function
CONINF:	equ	scb_pg+74h	; 03. console input function
conoutf:	equ	scb_pg+7ah; 04. console output function
LISTF:	equ	scb_pg+80h	; 05. list output function
ELSE	
wbootf:	equ	bios$pg+3	; 01. warm boot function
CONSTF:	equ	bios$pg+6	; 02. console status function
CONINF:	equ	bios$pg+9	; 03. console input function
conoutf:	equ	bios$pg+12; 04. console output function
LISTF:	equ	bios$pg+15	; 05. list output function
ENDIF	
punchf:	equ	bios$pg+18	; 06. punch output function
READERF:	equ	bios$pg+21; 07. reader input function
homef:	equ	bios$pg+24	; 08. disk home function
seldskf:	equ	bios$pg+27; 09. select disk function
settrkf:	equ	bios$pg+30; 10. set track function
setsecf:	equ	bios$pg+33; 11. set sector function
setdmaf:	equ	bios$pg+36; 12. set dma function
readf:	equ	bios$pg+39	; 13. read disk function
writef:	equ	bios$pg+42	; 14. write disk function
liststf:	equ	bios$pg+45; 15. list status function
sectran:	equ	bios$pg+48; 16. sector translate
conoutstf:	equ	bios$pg+51; 17. console output status function
AUXINSTF:	equ	bios$pg+54; 18. aux input status function
AUXOUTSTF:	equ	bios$pg+57; 19. aux output status function
devtblf:	equ	bios$pg+60; 20. retunr device table address FX
devinitf:	equ	bios$pg+63; 21. initialize device function
drvtblf:	equ	bios$pg+66; 22. return drive table address
multiof:	equ	bios$pg+69; 23. multiple i/o function
flushf:	equ	bios$pg+72	; 24. flush function
movef:	equ	bios$pg+75	; 25. memory move function
timef:	equ	bios$pg+78	; 26. system get/set time function
selmemf:	equ	bios$pg+81; 27. select memory function
setbnkf:	equ	bios$pg+84; 28. set dma bank function
xmovef:	equ	bios$pg+87	; 29. extended move function
IF	BANKED
; System Control Block equates
olog:	equ	scb_pg+090h
rlog:	equ	scb_pg+092h
SCB:	equ	scb_pg+09ch
; Expansion Area - 6 bytes
hashl:	equ	scb_pg+09ch
hash:	equ	scb_pg+09dh
version:	equ	scb_pg+0a1h
; Utilities Section - 8 bytes
util$flgs:	equ	scb_pg+0a2h
dspl$flgs:	equ	scb_pg+0a6h
; CLP Section - 4 bytes
clp$flgs:	equ	scb_pg+0aah
clp$errcde:	equ	scb_pg+0ach
; CCP Section - 8 bytes
ccp$comlen:	equ	scb_pg+0aeh
ccp$curdrv:	equ	scb_pg+0afh
ccp$curusr:	equ	scb_pg+0b0h
ccp$conbuff:	equ	scb_pg+0b1h
ccp$flgs:	equ	scb_pg+0b3h
; Device I/O Section - 32 bytes
conwidth:	equ	scb_pg+0b6h
COLUMN:	equ	scb_pg+0b7h
conpage:	equ	scb_pg+0b8h
conline:	equ	scb_pg+0b9h
conbuffadd:	equ	scb_pg+0bah
conbufflen:	equ	scb_pg+0bch
conin$rflg:	equ	scb_pg+0beh
conout$rflg:	equ	scb_pg+0c0h
auxin$rflg:	equ	scb_pg+0c2h
auxout$rflg:	equ	scb_pg+0c4h
lstout$rflg:	equ	scb_pg+0c6h
page$mode:	equ	scb_pg+0c8h
pm$default:	equ	scb_pg+0c9h
CTLH$ACT:	equ	scb_pg+0cah
RUBOUT$ACT:	equ	scb_pg+0cbh
type$ahead:	equ	scb_pg+0cch
contran:	equ	scb_pg+0cdh
conmode:	equ	scb_pg+0cfh
outdelim:	equ	scb_pg+0d3h
listcp:	equ	scb_pg+0d4h
qflag:	equ	scb_pg+0d5h
; BDOS Section - 42 bytes
scbadd:	equ	scb_pg+0d6h
dmaad:	equ	scb_pg+0d8h
olddsk:	equ	scb_pg+0dah
INFO:	equ	scb_pg+0dbh
resel:	equ	scb_pg+0ddh
relog:	equ	scb_pg+0deh
FX:	equ	scb_pg+0dfh
usrcode:	equ	scb_pg+0e0h
dcnt:	equ	scb_pg+0e1h
;searcha	equ	scb_pg+0e3h
searchl:	equ	scb_pg+0e5h
multcnt:	equ	scb_pg+0e6h
errormode:	equ	scb_pg+0e7h
searchchain:	equ	scb_pg+0e8h
temp$drive:	equ	scb_pg+0ech
errdrv:	equ	scb_pg+0edh
media$flag:	equ	scb_pg+0f0h
bdos$flags:	equ	scb_pg+0f3h
stamp:	equ	scb_pg+0f4h
commonbase:	equ	scb_pg+0f9h
errors:	equ	scb_pg+0fbh	;jmp error$sub
bdosadd:	equ	scb_pg+0feh
; Resbdos equates
resbdos:	equ	resbdos$pg
move$out:	equ	resbdos$pg+9; a=bank #, hl=dest, de=srce
move$tpa:	equ	resbdos$pg+0ch; a=bank #, hl=dest, de=srce
srch$hash:	equ	resbdos$pg+0fh; a=bank #, hl=hash table addr
hashmx:	equ	resbdos$pg+12h	; max hash search dcnt
rd$dir$flag:	equ	resbdos$pg+14h; directory read flag
make$xfcb:	equ	resbdos$pg+15h; make function flag
find$xfcb:	equ	resbdos$pg+16h; search function flag
xdcnt:	equ	resbdos$pg+17h	; dcnt save for empty fcb, 
	; user 0 fcb, or xfcb
xdmaad:	equ	resbdos$pg+19h	; resbdos dma copy area addr
curdma:	equ	resbdos$pg+1bh	; current dma
copy$cr$only:	equ	resbdos$pg+1dh; dont restore fcb flag
user$INFO:	equ	resbdos$pg+1eh; user fcb address
KBCHAR:	equ	resbdos$pg+20h	; conbdos look ahead char
qconinx:	equ	resbdos$pg+21h; qconin mov a,m routine
ELSE	
FX	equ	0
EXTERN	INFO

EXTERN	dircnt, olddsk, seldsk
EXTERN	mult$cnt, linfo, ARET, resel, goback, error$mode
EXTERN	permsg, rodmsg, rofmsg, selmsg, passmsg, fxstsmsg
EXTERN	wildmsg, STHL$RET, parse$pw, CRLF
EXTERN	adrive, dskerr, dskmsg, PRINT, patch$1e25, clp$errcde
EXTERN	save$rr, mult$num, incr$rr, dmaad, setdma, reset$rr

EXTERN	func1, func2, func3
EXTERN	func6, func7
EXTERN	func8, func9, func10, func11

EXTERN	func12,func13,func14,func15
EXTERN	func16,func17,func18,func19
EXTERN	func20,func21,func22,func23
EXTERN	func24,func25,func26,func27
EXTERN	func28,func29,func30,func31
EXTERN	func32,func33,func34,func35
EXTERN	func36,func37,func38,func39
EXTERN	func40,lret$eq$ff,func42,func43
EXTERN	func44,func45,func46,func47
EXTERN	func48,func49,func50

EXTERN	func98,func99
EXTERN	func100,func101,func102,func103
EXTERN	func104,func105,func106,func107
EXTERN	func108,func109,func110,func111
EXTERN	func112




move$out:	equ	movef
move$tpa:	equ	movef
ENDIF	
;
	DEFINE BDOS, SPACE = RAM
	SEGMENT BDOS

serial:	DB	'654321'
;
;	Enter here from the user's program with function number in c,
;	and information address in d,e
;
bdose:	; Arrive here from user programs
	EX	DE,HL
	LD	(INFO),HL
	EX	DE,HL		; INFO=de, de=INFO
	LD	A,C
	LD	(FX),A
	CP	14
	jr c,	bdose2
	LD	HL,0
	LD	(dircnt),HL	; dircnt,multnum = 0
	LD	A,(olddsk)
	LD	(seldsk),A	; Set seldsk
IF	BANKED
	DEC	A
	LD	(copy$cr$init),A
ENDIF	
	; If mult$cnt ~= 1 then read or write commands
	; are handled by the shell
	LD	A,(mult$cnt)
	DEC	A
	jr z,	bdose2
	LD	HL,mult$fxs
bdose1:	
	LD	A,(HL)
	OR	A
	jr z,	bdose2
	CP	C
	jr z,	shell
	INC	HL
	JP	bdose1
bdose2:	
	LD	A,E
	LD	(linfo),A	; linfo = low(INFO) - don't equ
	LD	HL,0
	LD	(ARET),HL	; Return value defaults to 0000
	LD	(resel),HL	; resel,relog = 0
	; Save user's stack pointer, set to local stack
	ADD	HL,sp
	LD	(entsp),HL	; entsp = stackptr
IF	.not.	BANKED
	LD	sp,lstack	; local stack setup
ENDIF	
	LD	HL,goback	; Return here after all functions
	PUSH	HL		; jmp goback equivalent to ret
	LD	A,C
	CP	nfuncs
	jr nc,	high$fxs	; Skip if invalid #
	LD	C,E		; possible output character to c
	LD	HL,functab
	JP	bdos$jmp
	; look for functions 98 ->
high$fxs:	
	CP	128
	jr nc,	test$152
	SUB	A,98
	jr c,	lret$eq$ff	; Skip if function < 98
	CP	nfuncs2
	jr nc,	lret$eq$ff
	LD	HL,functab2
bdos$jmp:	
	LD	E,A
	LD	D,0		; de=func, hl=.ciotab
	ADD	HL,DE
	ADD	HL,DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)		; de=functab(func)
	LD	HL,(INFO)	; INFO in de for later xchg	
	EX	DE,HL
	JP	(HL)		; dispatched
;	   CAUTION: In banked systems only,
;          error$sub is referenced indirectly by the SCB ERROR
; 	   field in RESBDOS as (0fc7ch).  This value is converted
; 	   to the actual address of error$sub by GENSYS.  If the offset
; 	   of error$sub is changed, the SCB ERROR value must also
; 	   be changed.
;
;	error subroutine
;
error$sub:	
	LD	B,0
	PUSH	BC
	DEC	C
	LD	HL,errtbl
	ADD	HL,BC
	ADD	HL,BC
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	CALL	errflg
	POP	BC
	LD	A,(error$mode)
	OR	A
	ret nz	
	JP	reboote
mult$fxs:	DB	20,21,33,34,40,0
;	maclib	makedate
IF	BANKED
;	@LCOPY
;	@BDATE
else	
;	@SCOPY
;	@BDATE
	;	31 level stack
	DW	0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h
	DW	0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h
	DW	0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h
	DW	0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h
lstack:	
ENDIF	
;	dispatch table for functions
functab:	
	DW	rebootx1, func1, func2, func3
	DW	punchf, LISTF, func6, func7
	DW	func8, func9, func10, func11
diskf:	equ	($-functab)/2	; disk funcs
	DW	func12,func13,func14,func15
	DW	func16,func17,func18,func19
	DW	func20,func21,func22,func23
	DW	func24,func25,func26,func27
	DW	func28,func29,func30,func31
	DW	func32,func33,func34,func35
	DW	func36,func37,func38,func39
	DW	func40,lret$eq$ff,func42,func43
	DW	func44,func45,func46,func47
	DW	func48,func49,func50
nfuncs:	equ	($-functab)/2
functab2:	
	DW	func98,func99
	DW	func100,func101,func102,func103
	DW	func104,func105,func106,func107
	DW	func108,func109,func110,func111
	DW	func112
nfuncs2:	equ	($-functab2)/2
errtbl:	
	DW	permsg
	DW	rodmsg
	DW	rofmsg
	DW	selmsg
	DW	0
	DW	0
	DW	passmsg
	DW	fxstsmsg
	DW	wildmsg
test$152:	
	CP	152
	ret	nz	
;
;	PARSE version 3.0b  Oct 08 1982 - Doug Huskey
;
;
	; DE->.(.filename,.fcb)
	;
	; filename = [d:]file[.type][;password]
	;             
	; fcb assignments
	;
	;   0     => drive, 0 = default, 1 = A, 2 = B, ...
	;   1-8   => file, converted to upper case,
	;            padded with blanks (left justified)
	;   9-11  => type, converted to upper case,
	;	     padded with blanks (left justified)
	;   12-15 => set to zero
	;   16-23 => password, converted to upper case,
	;	     padded with blanks
	;   24-25 => 0000h
	;   26    => length of password (0 - 8)
	;
	; Upon return, HL is set to FFFFH if DE locates
	;            an invalid file name;
	; otherwise, HL is set to 0000H if the delimiter
	;            following the file name is a 00H (NULL)
	; 	     or a 0DH (CR);
	; otherwise, HL is set to the address of the delimiter
	;            following the file name.
	;
	LD	HL,STHL$RET
	PUSH	HL
	LD	HL,(INFO)
	LD	E,(HL)		;get first parameter
	INC	HL
	LD	D,(HL)
	PUSH	DE		;save .filename
	INC	HL
	LD	E,(HL)		;get second parameter
	INC	HL
	LD	D,(HL)
	POP	HL		;DE=.fcb  HL=.filename
	EX	DE,HL
parse0:	
	PUSH	HL		;save .fcb
	XOR	A
	LD	(HL),A		;clear drive byte
	INC	HL
	LD	BC,20h*256+11
	CALL	pad		;pad name and type w/ blanks
	LD	BC,4
	CALL	pad		;EXT, S1, S2, RC = 0
	LD	BC,20h*256+8
	CALL	pad		;pad password field w/ blanks
	LD	BC,12
	CALL	pad		;zero 2nd 1/2 of map, cr, r0 - r2
;
;	skip spaces
;
	CALL	skps
;
;	check for drive
;
	LD	A,(DE)
	CP	':'		;is this a drive_
	DEC	DE
	POP	HL
	PUSH	HL		;HL = .fcb
	jr nz,	parse$name
;
;	Parse the drive-spec
;
parsedrv:	
	CALL	delim
	jr 	z,parse$ok
	SUB	A,'A'
	jr 	c,perror1
	CP	16
	jr 	nc,perror1
	INC	DE
	INC	DE		;past the ':'
	INC	A		;set drive relative to 1
	LD	(HL),A		;store the drive in FCB(0)
;
;	Parse the file-name
;
parse$name:	
	INC	HL		;HL = .fcb(1)
	CALL	delim
	jr 	z,parse$ok
	LD	BC,7*256
parse6:	LD	A,(DE)		;get a character
	CP	'.'		;file-type next_
	jp 	z,parse$type	;branch to file-type processing
	CP	';'
	jr z,	parse$pw
	CALL	gfc		;process one character
	jr nz,	parse6		;loop if not end of name
	JP	parse$ok
;
;	Parse the file-type
;
parse$type:	
	INC	DE		;advance past dot
	POP	HL
	PUSH	HL		;HL =.fcb
	LD	BC,9
	ADD	HL,BC		;HL =.fcb(9)
	LD	BC,2*256
parse8:	LD	A,(DE)
	CP	';'
	jr z,	parsepw
	CALL	gfc		;process one character
	jr nz,	parse8		;loop if not end of type
;
parse$ok:	
	POP	BC
	PUSH	DE
	CALL	skps		;skip trailing blanks and tabs
	DEC	DE
	CALL	delim		;is next nonblank char a delim_
	POP	HL
	ret 	nz		;no
	LD	HL,0
	OR	A
	ret 	z		;return zero if delim = 0
	CP	CR
	ret	z		;return zero if delim = cr
	EX	DE,HL
	RET	
;
;	handle parser error
;
perror:	
	POP	BC		;throw away return addr
perror1:	
	POP	BC
	LD	HL,0ffffh
	RET	
;
;	Parse the password
;
parsepw:	
	INC	DE
	POP	HL
	PUSH	HL
	LD	BC,16
	ADD	HL,BC
	LD	BC,7*256+1
parsepw1:	
	CALL	gfc
	jr nz,	parsepw1
	LD	A,7
	SUB	A,B
	POP	HL
	PUSH	HL
	LD	BC,26
	ADD	HL,BC
	LD	(HL),A
	LD	A,(DE)		;delimiter in A
	JP	parse$ok
;
;	get next character of name, type or password
;
gfc:	CALL	delim		;check for end of filename
	ret z			;return if so
	CP	' '		;check for control characters
	INC	DE
	jr c,	perror		;error if control characters encountered
	INC	B		;error if too big for field
	DEC	B
	jp	m,perror
	INC	C
	DEC	C
	jr nz,	gfc1
	CP	'*'		;trap "match rest of field" character
	jr z,	setmatch
gfc1:	LD	(HL),A		;put character in fcb
	INC	HL
	DEC	B		;decrement field size counter
	OR	A		;clear zero flag
	RET	
;;
setmatch:	
	LD	(HL),'_'	;set match one character
	INC	HL
	DEC	B
	jp	setmatch
	RET	
;	
;	check for delimiter
;
;	entry:	A = character
;	exit:	z = set if char is a delimiter
;
delimiters:	DB	CR,TAB,' .,:;[]=<>|',0
delim:	LD	A,(DE)		;get character
	PUSH	HL
	LD	HL,delimiters
delim1:	CP	(HL)		;is char in table
	jr z,	delim2
	INC	(HL)
	DEC	(HL)		;end of table_ (0)
	INC	HL
	jr 	nz,delim1
	OR	A		;reset zero flag
delim2:	POP	HL
	ret 	z	
	;
	;	not a delimiter, convert to upper case
	;
	CP	'a'
	ret	c	
	CP	'z'+1
	jr 	nc,delim3
	AND	05fh
delim3:	AND	07fh	
	RET			;return with zero set if so
;
;	pad with blanks or zeros
;
pad:	LD	(HL),B
	INC	HL
	DEC	C
	jr 	nz,pad
	RET	
;
;	skip blanks and tabs
;
skps:	LD	A,(DE)
	INC	DE
	CP	' '		;skip spaces & tabs
	jr 	z,skps
	CP	TAB
	jr z,	skps
	RET	
;
;	end of PARSE
;
errflg:	
	; report error to console, message address in hl
	PUSH	HL
	CALL	CRLF		; stack mssg address, new line
	LD	A,(adrive)
	ADD	A,'A'
	LD	(dskerr),A	; current disk name
	LD	BC,dskmsg
IF	BANKED
	CALL	zprint		; the error message
else	
	CALL	PRINT
ENDIF	
	POP	BC
IF	BANKED
	LD	A,(bdos$flags)
	RLA	
	jr nc,	zprint
	CALL	zprint		; error message tail
	LD	A,(FX)
	LD	B,30h
	LD	HL,pr$fx1
	CP	100
	jr c,	errflg1
	LD	(HL),31h
	INC	HL
	SUB	A,100
errflg1:	
	SUB	A,10
	jr c,	errflg2
	INC	B
	JP	errflg1
errflg2:	
	LD	(HL),B
	INC	HL
	ADD	A,3ah
	LD	(HL),A
	INC	HL
	LD	(HL),20h
	LD	HL,pr$fcb
	LD	(HL),0
	LD	A,(resel)
	OR	A
	jr z,	errflg3
	LD	(HL),20h
	PUSH	DE
	LD	HL,(INFO)
	INC	HL
	EX	DE,HL
	LD	HL,pr$fcb1
	LD	C,8
	CALL	move
	LD	(HL),'.'
	INC	HL
	LD	C,3
	CALL	move
	POP	DE
errflg3:	
	CALL	CRLF
	LD	BC,pr$FX
	JP	zprint
zprint:	
	LD	A,(BC)
	OR	A
	ret z	
	PUSH	BC
	LD	C,A
	CALL	tabout
	POP	BC
	INC	BC
	JP	zprint
pr$FX:	DB	'BDOS Function = '
pr$fx1:	DB	'   '
pr$fcb:	DB	' File = '
pr$fcb1:	DS	12
	DB	0
else	
	JP	PRINT
ENDIF	
reboote:	
	LD	HL,0fffdh
	JP	rebootx0	; BDOS error
rebootx:	
;;;	lxi h,0fffeh ; CTL-C error
	CALL	patch$1e25	;[JCE] DRI patch 13 
rebootx0:	
	LD	(clp$errcde),HL
rebootx1:	
;	JP	wbootf		; Getting RANGE error.
	jp	0
entsp:	DS	2		; entry stack pointer
shell:	
	LD	HL,0
	ADD	HL,sp
	LD	(shell$sp),HL
IF	.not.	BANKED
	LD	sp,shell$stk
ENDIF	
	LD	HL,shell$rtn
	PUSH	HL
	CALL	save$rr
	CALL	save$dma
	LD	A,(mult$cnt)
mult$io:	
	PUSH	AF
	LD	(mult$num),A
	CALL	cbdos
	OR	A
	jr nz,	shell$err
	LD	A,(FX)
	CP	33
	call	nc,	incr$rr
	CALL	adv$dma
	POP	AF
	DEC	A
	jr nz,	mult$io
	LD	H,A
	LD	L,A
	RET	
shell$sp:	DW	0
	DW	0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h
shell$stk:	; shell has 5 level stack
hold$dma:	DW	0
cbdos:	
	LD	A,(FX)
	LD	C,A
cbdos1:	
	LD	HL,(INFO)
	EX	DE,HL
	JP	bdose2
adv$dma:	
	LD	HL,(dmaad)
	LD	DE,80h
	ADD	HL,DE
	JP	reset$dma1
save$dma:	
	LD	HL,(dmaad)
	LD	(hold$dma),HL
	RET	
reset$dma:	
	LD	HL,(hold$dma)
reset$dma1:	
	LD	(dmaad),HL
	JP	setdma
shell$err:	
	POP	BC
	INC	A
	ret z	
	LD	A,(mult$cnt)
	SUB	A,B
	LD	H,A
	RET	
shell$rtn:	
	PUSH	HL
	LD	A,(FX)
	CP	33
	call	nc,reset$rr
	CALL	reset$dma
	POP	DE
	LD	HL,(shell$sp)
	LD	SP,HL
	EX	DE,HL
	LD	A,L
	LD	B,H
	RET	
	page	
