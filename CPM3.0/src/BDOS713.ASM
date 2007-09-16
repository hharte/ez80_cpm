;*************************************************************************
;*                                                                       *
;* $Id: BDOS713.ASM 1555 2007-09-14 07:37:35Z hharte $                   *
;*                                                                       *
;* Copyright (c) 2005-2007 Howard M. Harte                               *
;* https://github.com/hharte                                             *
;*                                                                       *
;* Module Description:                                                   *
;*     CPM 3.0 BDOS Ported to the eZ80 by Howard M. Harte.               *
;*                                                                       *
;* Environment:                                                          *
;*     Zilog ZDS-II v4.11.1, (http://www.zilog.com)                      *
;*                                                                       *
;*************************************************************************

	title	'CP/M BDOS Interface, BDOS, Version 3.0 Dec, 1982'
;	page	0
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
; $Id: BDOS713.ASM 1555 2007-09-14 07:37:35Z hharte $ 
;

include "cpm3_defs.inc"

UNDOC:	equ	on		;undocumented patch in DRI bnkbdos3.spr
;undocumented patch verified against DRI bnkbdos3.spr release 9 oct 97 rhp
PATCH7:	equ	on		; PATCH 7 ADDED 5 OCT 97 RHP
;Patch7 verified against DRI distribution bdos3.spr 7 oct 97 rhp
;patch7 verified against DRI dist bnkbdos3.spr 9 oct 97 rhp
PATCH13:	equ	on	; PATCH 13 ADDED 6 OCT 97 RHP
;patch 13 verified against patched DRI dist bdos3.spr 9 oct 97 rhp
;patch 13 verified against patched DRI dist bnkbdos3.spr 10 oct 97 rhp

EXTERN	BIOS_LOC
EXTERN	BDOS_LOC
PUBLIC	SCB
PUBLIC  _BIOS_SCB
PUBLIC	ccp_curdrv

; Base page definitions
bnkbdos$pg:	equ	base+0fc00h
resbdos$pg:	equ	base+0fd00h
scb$pg:		equ	SCB ;_LOC		;0FE00h	;base+0fb00h
bios$pg:	equ	BIOS_LOC	;base+0ff00h

IF .NOT. MPM
; Bios equates
bios:		equ	BIOS_LOC
bootf:		equ	bios		; 00. cold boot function

IF	BANKED
wbootf:		equ	scb$pg+68h	; 01. warm boot function
constf:		equ	scb$pg+6eh	; 02. console status function
coninf:		equ	scb$pg+74h	; 03. console input function
conoutf:	equ	scb$pg+7ah	; 04. console output function
listf:		equ	scb$pg+80h	; 05. list output function
ELSE	
wbootf:		equ	bios$pg+3	; 01. warm boot function
constf:		equ	bios$pg+6	; 02. console status function
coninf:		equ	bios$pg+9	; 03. console input function
conoutf:	equ	bios$pg+12	; 04. console output function
listf:		equ	bios$pg+15	; 05. list output function
ENDIF	

punchf:		equ	bios$pg+18	; 06. punch output function
readerf:	equ	bios$pg+21; 07. reader input function
homef:		equ	bios$pg+24	; 08. disk home function
seldskf:	equ	bios$pg+27; 09. select disk function
settrkf:	equ	bios$pg+30; 10. set track function
setsecf:	equ	bios$pg+33; 11. set sector function
setdmaf:	equ	bios$pg+36; 12. set dma function
readf:		equ	bios$pg+39	; 13. read disk function
writef:		equ	bios$pg+42	; 14. write disk function
liststf:	equ	bios$pg+45; 15. list status function
sectran:	equ	bios$pg+48; 16. sector translate
conoutstf:	equ	bios$pg+51; 17. console output status function
auxinstf:	equ	bios$pg+54; 18. aux input status function
auxoutstf:	equ	bios$pg+57; 19. aux output status function
devtblf:	equ	bios$pg+60; 20. retunr device table address fx
devinitf:	equ	bios$pg+63; 21. initialize device function
drvtblf:	equ	bios$pg+66; 22. return drive table address
multiof:	equ	bios$pg+69; 23. multiple i/o function
flushf:		equ	bios$pg+72	; 24. flush function
movef:		equ	bios$pg+75	; 25. memory move function
timef:		equ	bios$pg+78	; 26. system get/set time function
selmemf:	equ	bios$pg+81; 27. select memory function
setbnkf:	equ	bios$pg+84; 28. set dma bank function
xmovef:		equ	bios$pg+87	; 29. extended move function
ENDIF	; .NOT. MPM

IF	BANKED
; System Control Block equates
olog:		equ	scb$pg+090h
rlog:		equ	scb$pg+092h
SCB:		equ	scb$pg+09ch
; Expansion Area - 6 bytes
hashl:		equ	scb$pg+09ch
hash:		equ	scb$pg+09dh
version:	equ	scb$pg+0a1h
; Utilities Section - 8 bytes
util$flgs:	equ	scb$pg+0a2h
dspl$flgs:	equ	scb$pg+0a6h
; CLP Section - 4 bytes
clp$flgs:	equ	scb$pg+0aah
clp$errcde:	equ	scb$pg+0ach
; CCP Section - 8 bytes
ccp$comlen:	equ	scb$pg+0aeh
ccp_curdrv:	equ	scb$pg+0afh
ccp$curusr:	equ	scb$pg+0b0h
ccp$conbuff:	equ	scb$pg+0b1h
ccp$flgs:	equ	scb$pg+0b3h
; Device I/O Section - 32 bytes
conwidth:	equ	scb$pg+0b6h
column:		equ	scb$pg+0b7h
conpage:	equ	scb$pg+0b8h
conline:	equ	scb$pg+0b9h
conbuffadd:	equ	scb$pg+0bah
conbufflen:	equ	scb$pg+0bch
conin$rflg:	equ	scb$pg+0beh
conout$rflg:	equ	scb$pg+0c0h
auxin$rflg:	equ	scb$pg+0c2h
auxout$rflg:	equ	scb$pg+0c4h
lstout$rflg:	equ	scb$pg+0c6h
page$mode:	equ	scb$pg+0c8h
pm$default:	equ	scb$pg+0c9h
ctlh$act:	equ	scb$pg+0cah
rubout$act:	equ	scb$pg+0cbh
type$ahead:	equ	scb$pg+0cch
contran:	equ	scb$pg+0cdh
conmode:	equ	scb$pg+0cfh
outdelim:	equ	scb$pg+0d3h
listcp:		equ	scb$pg+0d4h
qflag:		equ	scb$pg+0d5h
; BDOS Section - 42 bytes
scbadd:		equ	scb$pg+0d6h
dmaad:		equ	scb$pg+0d8h
olddsk:		equ	scb$pg+0dah
info:		equ	scb$pg+0dbh
resel:		equ	scb$pg+0ddh
relog:		equ	scb$pg+0deh
fx:		equ	scb$pg+0dfh
usrcode:	equ	scb$pg+0e0h
dcnt:		equ	scb$pg+0e1h
;searcha	equ	scb$pg+0e3h
searchl:	equ	scb$pg+0e5h
mult$cnt:	equ	scb$pg+0e6h
error$mode:	equ	scb$pg+0e7h
searchchain:	equ	scb$pg+0e8h
temp$drive:	equ	scb$pg+0ech
errdrv:		equ	scb$pg+0edh
media$flag:	equ	scb$pg+0f0h
bdos$flags:	equ	scb$pg+0f3h
stamp:		equ	scb$pg+0f4h
common$base:	equ	scb$pg+0f9h
error:		equ	scb$pg+0fbh	;jmp error$sub
bdosadd:	equ	scb$pg+0feh
; Resbdos equates
resbdos:	equ	resbdos$pg
move$out:	equ	resbdos$pg+9; a=bank #, hl=dest, de=srce
move$tpa:	equ	resbdos$pg+0ch; a=bank #, hl=dest, de=srce
srch$hash:	equ	resbdos$pg+0fh; a=bank #, hl=hash table addr
hashmx:		equ	resbdos$pg+12h	; max hash search dcnt
rd$dir$flag:	equ	resbdos$pg+14h; directory read flag
make$xfcb:	equ	resbdos$pg+15h; make function flag
find$xfcb:	equ	resbdos$pg+16h; search function flag
xdcnt:		equ	resbdos$pg+17h	; dcnt save for empty fcb, 
	; user 0 fcb, or xfcb
xdmaad:		equ	resbdos$pg+19h	; resbdos dma copy area addr
curdma:		equ	resbdos$pg+1bh	; current dma
copy$cr$only:	equ	resbdos$pg+1dh; dont restore fcb flag
user$info:	equ	resbdos$pg+1eh; user fcb address
kbchar:		equ	resbdos$pg+20h	; conbdos look ahead char
qconinx:	equ	resbdos$pg+21h; qconin mov a,m routine
ELSE	
move$out:	equ	movef
move$tpa:	equ	movef
ENDIF	
;

PUBLIC	bdose		; BDOS Entry Point

	DEFINE BDOS, SPACE = RAM
	SEGMENT BDOS

serial:	DB	'654321'
;
;	Enter here from the user's program with function number in c,
;	and information address in d,e
;
bdose:	; Arrive here from user programs
	EX	DE,HL
	LD	(info),HL
	EX	DE,HL		; info=de, de=info
	LD	A,C
	LD	(fx),A
	CP	14
	jp	c,bdose2
	LD	HL,0
	LD	(dir$cnt),HL	; dircnt,multnum = 0
	LD	A,(olddsk)
	LD	(seldsk),A	; Set seldsk
IF BANKED
	DEC	A
	LD	(copy$cr$init),A
ENDIF	
	; If mult$cnt ~= 1 then read or write commands
	; are handled by the shell
	LD	A,(mult$cnt)
	DEC	A
	jp	z,bdose2
	LD	HL,mult$fxs
bdose1:	
	LD	A,(HL)
	OR	A
	jp	z,bdose2
	CP	C
	jp	z,shell
	INC	HL
	JP	bdose1
bdose2:	
	LD	A,E
	LD	(linfo),A	; linfo = low(info) - don't equ
	LD	HL,0
	LD	(aret),HL	; Return value defaults to 0000
	LD	(resel),HL	; resel,relog = 0
	; Save user's stack pointer, set to local stack
	ADD	HL,sp
	LD	(entsp),HL	; entsp = stackptr
IF .NOT. BANKED
	LD	sp,lstack	; local stack setup
ENDIF	
	LD	HL,goback	; Return here after all functions
	PUSH	HL		; jmp goback equivalent to ret
	LD	A,C
	CP	nfuncs
	jp	nc,high$fxs	; Skip if invalid #
	LD	C,E		; possible output character to c
	LD	HL,functab
	JP	bdos$jmp
	; look for functions 98 ->
high$fxs:	
	CP	128
	jp	nc,test$152
	SUB	A,98
	jp	c,lret$eq$ff	; Skip if function < 98
	CP	nfuncs2
	jp	nc,lret$eq$ff
	LD	HL,functab2
bdos$jmp:	
	LD	E,A
	LD	D,0		; de=func, hl=.ciotab
	ADD	HL,DE
	ADD	HL,DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)		; de=functab(func)
	LD	HL,(info)	; info in de for later xchg	
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
	ret	nz
	JP	reboote
mult$fxs:	DB	20,21,33,34,40,0
IF BANKED
	DB	'COPYRIGHT (C) 1982,'
	DB	' DIGITAL RESEARCH '
	DB	'151282'
ELSE	
	DB	'COPR. ',027h,'82 DRI 151282'
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
	DW	punchf, listf, func6, func7
	DW	func8, func9, func10, func11
diskf:	equ	12 ;($-functab)/2	; disk funcs
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
nfuncs:	equ	51 ;($-functab)/2
functab2:	
	DW	func98,func99
	DW	func100,func101,func102,func103
	DW	func104,func105,func106,func107
	DW	func108,func109,func110,func111
	DW	func112
nfuncs2:	equ 15 ;equ	($-functab2)/2
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
	LD	HL,sthl$ret
	PUSH	HL
	LD	HL,(info)
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
	CP	':'		;is this a drive?
	DEC	DE
	POP	HL
	PUSH	HL		;HL = .fcb
	jp	nz,parse$name
;
;	Parse the drive-spec
;
parsedrv:	
	CALL	delim
	jp	z,parse$ok
	SUB	A,'A'
	jp	c,perror1
	CP	16
	jp	nc,perror1
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
	jp	z,parse$ok
	LD	BC,7*256
parse6:	LD	A,(DE)		;get a character
	CP	'.'		;file-type next?
	jp	z,parse$type	;branch to file-type processing
	CP	';'
	jp	z,parse$pw
	CALL	gfc		;process one character
	jp	nz,parse6		;loop if .NOT. end of name
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
	jp	z,parse$pw
	CALL	gfc		;process one character
	jp	nz,parse8		;loop if .NOT. end of type
;
parse$ok:	
	POP	BC
	PUSH	DE
	CALL	skps		;skip trailing blanks and tabs
	DEC	DE
	CALL	delim		;is next nonblank char a delim?
	POP	HL
	ret	nz		;no
	LD	HL,0
	OR	A
	ret	z		;return zero if delim = 0
	CP	CR
	ret	z		;return zero if delim = CR
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
parse$pw:	
	INC	DE
	POP	HL
	PUSH	HL
	LD	BC,16
	ADD	HL,BC
	LD	BC,7*256+1
parsepw1:	
	CALL	gfc
	jp	nz,parsepw1
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
	ret	z		;return if so
	CP	' '		;check for control characters
	INC	DE
	jp	c,perror		;error if control characters encountered
	INC	B		;error if too big for field
	DEC	B
	jp	m,perror
	INC	C
	DEC	C
	jp	nz,gfc1
	CP	'*'		;trap "match rest of field" character
	jp	z,setmatch
gfc1:	LD	(HL),A		;put character in fcb
	INC	HL
	DEC	B		;decrement field size counter
	OR	A		;clear zero flag
	RET	
;;
setmatch:	
	LD	(HL),'?'	;set match one character
	INC	HL
	DEC	B
	jp	p,setmatch
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
	jp	z,delim2
	INC	(HL)
	DEC	(HL)		;end of table? (0)
	INC	HL
	jp	nz,delim1
	OR	A		;reset zero flag
delim2:	POP	HL
	ret	z
	;
	;	.NOT. a delimiter, convert to upper case
	;
	CP	'a'
	ret	c
	CP	'z'+1
	jp	nc,delim3
	AND	05fh
delim3:	AND	07fh	
	RET			;return with zero set if so
;
;	pad with blanks or zeros
;
pad:	LD	(HL),B
	INC	HL
	DEC	C
	jp	nz,pad
	RET	
;
;	skip blanks and tabs
;
skps:	LD	A,(DE)
	INC	DE
	CP	' '		;skip spaces & tabs
	jp	z,skps
	CP	TAB
	jp	z,skps
	RET	
;
;	end of PARSE
;
errflg:	
	; report error to console, message address in hl
	PUSH	HL
	CALL	crlf		; stack mssg address, new line
	LD	A,(adrive)
	ADD	A,'A'
	LD	(dskerr),A	; current disk name
	LD	BC,dskmsg
IF	BANKED
	CALL	zprint		; the error message
ELSE	
	CALL	print
ENDIF	
	POP	BC
IF	BANKED
	LD	A,(bdos$flags)
	RLA	
	jp	nc,zprint
	CALL	zprint		; error message tail
	LD	A,(fx)
	LD	B,30h
	LD	HL,pr$fx1
	CP	100
	jp	c,errflg1
	LD	(HL),31h
	INC	HL
	SUB	A,100
errflg1:	
	SUB	A,10
	jp	c,errflg2
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
	jp	z,errflg3
	LD	(HL),20h
	PUSH	DE
	LD	HL,(info)
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
	CALL	crlf
	LD	BC,pr$fx
	JP	zprint
zprint:	
	LD	A,(BC)
	OR	A
	ret	z
	PUSH	BC
	LD	C,A
	CALL	tabout
	POP	BC
	INC	BC
	JP	zprint
pr$fx:	DB	'BDOS Function = '
pr$fx1:	DB	'   '
pr$fcb:	DB	' File = '
pr$fcb1:	DS	12
	DB	0
ELSE	
	JP	print
ENDIF	
reboote:	
	LD	HL,0fffdh
	JP	rebootx0	; BDOS error
rebootx:	
IF	PATCH13
	CALL	new$rebootx
ELSE	
	LD	HL,0fffeh	; CTL-C error
ENDIF	
rebootx0:	
	LD	(clp$errcde),HL
rebootx1:	
	JP	wbootf
entsp:	DS	2		; entry stack pointer
shell:	
	LD	HL,0
	ADD	HL,sp
	LD	(shell$sp),HL
IF	.NOT.	BANKED
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
	jp	nz,shell$err
	LD	A,(fx)
	CP	33
	call	nc,incr$rr
	CALL	adv$dma
	POP	AF
	DEC	A
	jp	nz,mult$io
	LD	H,A
	LD	L,A
	RET	
shell$sp:	DW	0
	DW	0c7c7h,0c7c7h,0c7c7h,0c7c7h,0c7c7h
shell$stk:	; shell has 5 level stack
hold$dma:	DW	0
cbdos:	
	LD	A,(fx)
	LD	C,A
cbdos1:	
	LD	HL,(info)
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
	ret	z
	LD	A,(mult$cnt)
	SUB	A,B
	LD	H,A
	RET	
shell$rtn:	
	PUSH	HL
	LD	A,(fx)
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
conin:	
	;read console character to A
	LD	HL,kbchar
	LD	A,(HL)
	LD	(HL),0
	OR	A
	ret	nz
	;no previous keyboard character ready
	JP	coninf		;get character externally
	;ret
;
conech:	
	LD	HL,sta$ret
	PUSH	HL
CONECH0:	
	;read character with echo
	CALL	conin
	CALL	echoc
	JP	C ,CONECH1	;echo character?
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
	ret	z		;carriage return?
	CP	LF
	ret	z		;line feed?
	CP	TAB
	ret	z		;TAB?
	CP	CTLH
	ret	z		;backspace?
	CP	' '
	RET			;carry set if .NOT. graphic
;
CONSTX:	
	LD	A,(kbchar)
	OR	A
	JP	NZ,conb1
	CALL	constf
	AND	1
	RET	
;
IF	BANKED
SET$CTLS$MODE:	
	;SET CTLS STATUS OR INPUT FLAG FOR QUEUE MANAGER
	LD	HL,qflag
	LD	(HL),40H
	EX	(SP),HL
	JP	(HL)
ENDIF	
;
TEST$CTLS$MODE:	
	;RETURN WITH Z FLAG RESET IF CTL-S CTL-Q CHECKING DISABLED
	LD	B,A
	LD	A,(conmode)
	AND	2
	LD	A,B
	RET	
;
conbrk:	;check for character ready
	CALL	TEST$CTLS$MODE
	JP	NZ,CONSTX
	LD	A,(kbchar)
	OR	A
	jp	nz,CONBRK1		;skip if active kbchar
	;no active kbchar, check external break
	;DOES BIOS HAVE TYPE AHEAD?
IF	BANKED
	LD	A,(type$ahead)
	INC	A
	JP	Z ,CONSTX	;YES
ENDIF	
	;CONBRKX CALLED BY conout
CONBRKX:	
	;HAS CTL-S INTERCEPT BEEN DISABLED?
	CALL	TEST$CTLS$MODE
	RET	NZ		;YES
	;DOES kbchar CONTAIN CTL-S?
	LD	A,(kbchar)
	CP	CTLS
	JP	Z ,CONBRK1	;YES
IF	BANKED
	CALL	SET$CTLS$MODE
ENDIF	
	;IS A CHARACTER READY FOR INPUT?
	CALL	constf
IF	BANKED
	POP	HL
	LD	(HL),0
ENDIF	
	AND	1
	ret	z		;NO
	;character ready, read it
IF	BANKED
	CALL	SET$CTLS$MODE
ENDIF	
	CALL	coninf
IF	BANKED
	POP	HL
	LD	(HL),0
ENDIF	
CONBRK1:	
	CP	CTLS
	jp	nz,conb0		;check stop screen function
	;DOES kbchar CONTAIN A CTL-S?
	LD	HL,kbchar
	CP	(HL)
	JP	NZ,CONBRK2	;NO
	LD	(HL),0		; kbchar = 0
	;found CTLS, read next character
CONBRK2:	
IF	BANKED
	CALL	SET$CTLS$MODE
ENDIF	
	CALL	coninf		;to A
IF	BANKED
	POP	HL
	LD	(HL),0
ENDIF	
	CP	CTLC
	JP	NZ,CONBRK3
	LD	A,(conmode)
	AND	08H
	JP	Z ,rebootx
	XOR	A
CONBRK3:	
	SUB	A,CTLQ
	RET	Z 		; RETURN WITH A = ZERO IF CTLQ
	INC	A
	CALL	CONB3
	JP	CONBRK2
conb0:	
	LD	HL,kbchar
	LD	B,A
	;IS conmode(1) TRUE?
	LD	A,(conmode)
	RRA	
	JP	NC,$+7		;NO
	;DOES kbchar = CTLC?
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
conb1:	
	;return with true set in accumulator
	LD	A,1
	RET	
CONB2:	
	XOR	A
	LD	(HL),A
	RET	
CONB3:	
	CALL	Z ,TOGGLE$listcp
	LD	C,7
	CALL	NZ,conoutf
	RET	
;
TOGGLE$listcp:	
	; IS PRINTER ECHO DISABLED?
	LD	A,(conmode)
	AND	14H
	JP	NZ,TOGGLE$L1	;YES
	LD	HL,listcp
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
	;DOES fx = INPUT?
	LD	A,(fx)
	DEC	A
	JP	Z ,conoutf	;YES
	;IS ESCAPE SEQUENCE DECODING IN EFFECT?
IF	PATCH13
	LD	A,B
	AND	10
	JP	NZ,SCONOUTF	;YES
ELSE	
	LD	A,B
	AND	8
	JP	NZ,SCONOUTF	;YES
ENDIF	
	JP	conoutf
;
conout:	
	;compute character position/write console char from C
	;compcol = true if computing column position
	LD	A,(compcol)
	OR	A
	jp	nz,compout
	;write the character, then compute the column
	;write console character from C
	;B ~= 0 -> ESCAPE SEQUENCE DECODING
	LD	A,(conmode)
	AND	14H
	LD	B,A
	PUSH	BC
	;CALL CONBRKX FOR OUTPUT FUNCTIONS ONLY
	LD	A,(fx)
	DEC	A
	CALL	NZ,CONBRKX
	POP	BC
	PUSH	BC		;recall/save character
	CALL	QCONOUTF	;externally, to console
	POP	BC
	;SKIP ECHO WHEN conmode & 14H ~= 0
	LD	A,B
	OR	A
	JP	NZ,compout
	PUSH	BC		;recall/save character
	;may be copying to the list device
	LD	A,(listcp)
	OR	A
	call	nz,listf		;to printer, if so
	POP	BC		;recall the character
compout:	
	LD	A,C		;recall the character
	;and compute column position
	LD	HL,column	;A = char, HL = .column
	CP	RUBOUT
	ret	z		;no column change if nulls
	INC	(HL)		;column = column + 1
	CP	' '
	ret	nc		;return if graphic
	;.NOT. graphic, reset column position
	DEC	(HL)		;column = column - 1
	LD	A,(HL)
	OR	A
	ret	z		;return if at zero
	;.NOT. at zero, may be backspace or end line
	LD	A,C		;character back to A
	CP	CTLH
	jp	nz,notbacksp
	;backspace character
	DEC	(HL)		;column = column - 1
	RET	
notbacksp:	
	;.NOT. a backspace character, eol?
	CP	CR
	ret	nz		;return if .NOT.
	;end of line, column = 0
	LD	(HL),0		;column = 0
	RET	
;
ctlout:	
	;send C character with possible preceding up-arrow
	LD	A,C
	CALL	echoc		;cy if .NOT. graphic (or special case)
	jp	nc,tabout		;skip if graphic, tab, CR, LF, or CTLH
	;send preceding up arrow
	PUSH	AF
	LD	C,CTL
	CALL	conout		;up arrow
	POP	AF
	OR	40h		;becomes graphic letter
	LD	C,A		;ready to print
IF	BANKED
	CALL	chk$column
	ret	z
ENDIF	
	;(drop through to tabout)
;
tabout:	
	;IS fx AN INPUT FUNCTION?
	LD	A,(fx)
	DEC	A
	JP	Z ,tabout1	;YES - ALWAYS EXPAND TABS FOR ECHO
	;HAS TAB EXPANSION BEEN DISABLED OR
	;ESCAPE SEQUENCE DECODING BEEN ENABLED?
	LD	A,(conmode)
	AND	14H
	JP	NZ,conout	;YES
tabout1:	
	;expand tabs to console
	LD	A,C
	CP	TAB
	jp	nz,conout		;direct to conout if .NOT.
	;tab encountered, move to next tab position
tab0:	
IF	BANKED
	LD	A,(fx)
	CP	1
	jp	nz,tab1
	CALL	chk$column
	ret	z
tab1:	
ENDIF	
	LD	C,' '
	CALL	conout		;another blank
	LD	A,(column)
	AND	111b		;column mod 8 = 0 ?
	jp	nz,tab0		;back for another if .NOT.
	RET	
;
;
backup:	
	;back-up one screen position
	CALL	pCTLH
IF	BANKED
	LD	A,(comchr)
	CP	CTLA
	ret	z
ENDIF	
	LD	C,' '
	CALL	conoutf
;	(drop through to pCTLH)				;
pCTLH:	
	;send CTLH to console without affecting column count
	LD	C,CTLH
	JP	conoutf
	;ret
;
crlfp:	
	;print #, cr, lf for CTLX, CTLU, CTLR functions
	;then move to strtcol (starting column)
	LD	C,'#'
	CALL	conout
	CALL	crlf
	;column = 0, move to position strtcol
crlfp0:	
	LD	A,(column)
	LD	HL,strtcol
	CP	(HL)
	ret	nc		;stop when column reaches strtcol
	LD	C,' '
	CALL	conout		;print blank
	JP	crlfp0
;;
;
crlf:	
	;carriage return line feed sequence
	LD	C,CR
	CALL	conout
	LD	C,LF
	JP	conout
	;ret
;
print:	
	;print message until M(BC) = '$'
	LD	HL,outdelim
	LD	A,(BC)
	CP	(HL)
	ret	z		;stop on $
	;more to print
	INC	BC
	PUSH	BC
	LD	C,A		;char to C
	CALL	tabout		;another character printed
	POP	BC
	JP	print
;
QCONIN:	
IF	BANKED
	LD	HL,(apos)
	LD	A,(HL)
	LD	(CTLA$sw),A
ENDIF	
	;IS BUFFER ADDRESS = 0?
	LD	HL,(conbuffadd)
	LD	A,L
	OR	H
	JP	Z ,conin	;YES
	;IS CHARACTER IN BUFFER < 5?
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
	LD	(conbuffadd),HL
	LD	(conbufflen),HL
	RET	NZ		; NO
	JP	conin
IF	BANKED
	
chk$column:	
	LD	A,(conwidth)
	LD	E,A
	LD	A,(column)
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
	ret	z
	INC	DE
	INC	HL
	LD	(HL),A
	INC	B
	JP	expand1
;
copy$xbuff:	
	LD	A,B
	OR	A
	ret	z
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
	LD	A,(ccp$flgs+1)
	RLA	
	ret	nc
	LD	HL,xbuff
	LD	DE,cbuff
	INC	C
	jp	nz,copy$cbuff1
	EX	DE,HL
	LD	A,B
	OR	A
	ret	z
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
	LD	A,(column)
	LD	(save$column),A
	RET	
;
clear$right:	
	LD	A,(column)
	LD	HL,ctla$column
	CP	(HL)
	ret	nc
	LD	C,20h
	CALL	conout
	JP	clear$right
;
reverse:	
	LD	A,(save$column)
	LD	HL,column
	CP	(HL)
	ret	nc
	LD	C,CTLH
	CALL	conout
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
	jp	z,cbs2
	INC	E
	INC	HL
	JP	cbs1
cbs2:	
	LD	A,B
	ADD	A,E
	CP	C
	PUSH	AF
	LD	C,7
	call	nc,conoutf
	POP	AF
	POP	HL
	POP	BC
	ret	c
	POP	DE
	POP	DE
	JP	readnx
;
refresh:	
	LD	A,(CTLA$sw)
	OR	A
	ret	z
	LD	A,(comchr)
	CP	CTLA
	ret	z
	CP	CTLF
	ret	z
	CP	CTLW
	ret	z
refresh0:	
	PUSH	HL
	PUSH	BC
	CALL	save$col
	LD	HL,(apos)
refresh1:	
	LD	A,(HL)
	OR	A
	jp	z,refresh2
	LD	C,A
	CALL	chk$column
	jp	c,refresh05
	LD	A,E
	LD	(column),A
	JP	refresh2
refresh05:	
	PUSH	HL
	CALL	ctlout
	POP	HL
	INC	HL
	JP	refresh1
refresh2:	
	LD	A,(column)
	LD	(new$ctla$col),A
refresh3:	
	CALL	clear$right
	CALL	reverse
	LD	A,(new$ctla$col)
	LD	(ctla$column),A
	POP	BC
	POP	HL
	RET	
;
init$apos:	
	LD	HL,aposi
	LD	(apos),HL
	XOR	A
	LD	(CTLA$sw),A
	RET	
;
init$xpos:	
	LD	HL,xbuff
	LD	(xpos),HL
	RET	
;
set$ctla$column:	
	LD	HL,CTLA$sw
	LD	A,(HL)
	OR	A
	ret	nz
	INC	(HL)
	LD	A,(column)
	LD	(ctla$column),A
	RET	
;
readi:	
	CALL	chk$column
	call	nc,crlf
	LD	A,(cbuff$len)
	LD	B,A
	LD	C,0
	CALL	copy$cbuff
ELSE	
readi:	
	LD	A,D
	OR	E
	JP	NZ,read
	LD	HL,(dmaad)
	LD	(info),HL
	INC	HL
	INC	HL
	LD	(conbuffadd),HL
ENDIF	
read:	;read to info address (max length, current length, buffer)
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
	LD	(fx),A
	LD	A,(column)
	LD	(strtcol),A	;save start for ctl-x, ctl-h
	LD	HL,(info)
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
	call	z,QCONIN
nxtline:	
	LD	(comchr),A
ELSE	
	CALL	QCONIN		;next char in A
ENDIF	
	;ani 7fh ;mask parity bit
	POP	HL
	POP	BC		;reactivate counters
	CP	CR
	jp	z,readen		;end of line?
	CP	LF
	jp	z,readen		;also end of line
IF	BANKED
	CP	CTLF
	jp	nz,.NOT.$CTLF
do$CTLF:	
	CALL	chk$column
	DEC	E
	CP	E
	jp	nc,readnx
do$CTLF0:	
	EX	DE,HL
	LD	HL,(apos)
	LD	A,(HL)
	OR	A
	jp	z,CTLW$l15
	INC	HL
	LD	(apos),HL
	EX	DE,HL
	JP	notr
.NOT.$CTLF:	
	CP	CTLW
	jp	nz,.NOT.$CTLW
do$CTLW:	
	EX	DE,HL
	LD	HL,(apos)
	LD	A,(HL)
	OR	A
	jp	z,CTLW$l1
	EX	DE,HL
	CALL	chk$column
	DEC	E
	CP	E
	EX	DE,HL
	jp	c,CTLW$l0
	EX	DE,HL
	CALL	refresh0
	EX	DE,HL
	JP	CTLW$l13
CTLW$l0:	
	LD	HL,(apos)
	LD	A,(HL)
	INC	HL
	LD	(apos),HL
	JP	CTLW$l3
CTLW$l1:	
	LD	HL,CTLA$sw
	LD	A,(HL)
	LD	(HL),0
	OR	A
	jp	z,CTLW$l2
CTLW$l13:	
	LD	HL,ctlw$sw
	LD	(HL),0
CTLW$l15:	
	EX	DE,HL
	JP	readnx
CTLW$l2:	
	LD	A,(ctlw$sw)
	OR	A
	jp	nz,CTLW$l25
	LD	A,B
	OR	A
	jp	nz,CTLW$l15
	CALL	init$xpos
CTLW$l25:	
	LD	HL,(xpos)
	LD	A,(HL)
	OR	A
	LD	(ctlw$sw),A
	jp	z,CTLW$l15
	INC	HL
	LD	(xpos),HL
CTLW$l3:	
	LD	HL,ctlw$sw
	LD	(HL),CTLW
	EX	DE,HL
	JP	notr
.NOT.$CTLW:	
	CP	CTLA
	jp	nz,.NOT.$CTLA
do$CTLA:	
	;do we have any characters to back over?
	LD	A,(strtcol)
	LD	D,A
	LD	A,(column)
	CP	D
	jp	z,readnx
	LD	(compcol),A	;COL > 0
	LD	A,B
	OR	A
	jp	z,linelen
	;characters remain in buffer, backup one
	DEC	B		;remove one character
	;compcol > 0 marks repeat as length compute
	;backup one position in xbuff
	PUSH	HL
	CALL	set$ctla$column
	POP	DE
	LD	HL,(apos)
	DEC	HL
	LD	(apos),HL
	LD	A,(DE)
	LD	(HL),A
	EX	DE,HL
	JP	linelen
.NOT.$CTLA:	
	CP	CTLB
	jp	nz,NOT$CTLB
do$CTLB:	
	LD	A,(SAVEPOS)
	CP	B
	jp	nz,CTLB$l0
	LD	A,CTLW
	LD	(CTLA$sw),A
	LD	(comchr),A
	JP	do$CTLW
CTLB$l0:	
	EX	DE,HL
	LD	HL,(apos)
	INC	B
CTLB$l1:	
	DEC	B
	LD	A,(SAVEPOS)
	CP	B
	jp	z,CTLB$l2
	DEC	HL
	LD	A,(DE)
	LD	(HL),A
	DEC	DE
	JP	CTLB$l1
CTLB$l2:	
	LD	(apos),HL
	PUSH	BC
	PUSH	DE
	CALL	set$ctla$column
CTLB$l3:	
	LD	A,(column)
	LD	B,A
	LD	A,(strtcol)
	CP	B
	jp	z,readn0
	LD	C,CTLH
	CALL	conout
	JP	CTLB$l3
NOT$CTLB:	
	CP	CTLK
	jp	nz,NOT$CTLK
	EX	DE,HL
	LD	HL,aposi
	LD	(apos),HL
	EX	DE,HL
	CALL	refresh
	JP	readnx
NOT$CTLK:	
	CP	CTLG
	jp	nz,NOT$CTLG
	LD	A,(CTLA$sw)
	OR	A
	jp	z,readnx
	JP	do$CTLF0
NOT$CTLG:	
ENDIF	
	CP	CTLH
	jp	nz,noth		;backspace?
	LD	A,(ctlh$act)
	INC	A
	JP	Z ,DO$RUBOUT
DO$CTLH:	
	;do we have any characters to back over?
	LD	A,(strtcol)
	LD	D,A
	LD	A,(column)
	CP	D
	jp	z,readnx
	LD	(compcol),A	;COL > 0
	LD	A,B
	OR	A
	JP	Z ,$+4
	;characters remain in buffer, backup one
	DEC	B		;remove one character
	;compcol > 0 marks repeat as length compute
	JP	linelen		;uses same code as repeat
noth:	
	;.NOT. a backspace
	CP	RUBOUT
	jp	nz,notrub		;RUBOUT char?
	LD	A,(rubout$act)
	INC	A
	JP	Z ,DO$CTLH
DO$RUBOUT:	
IF	BANKED
	LD	A,RUBOUT
	LD	(comchr),A
	LD	A,(CTLA$sw)
	OR	A
	jp	nz,DO$CTLH
ENDIF	
	;RUBOUT encountered, RUBOUT if possible
	LD	A,B
	OR	A
	jp	z,readnx		;skip if len=0
	;buffer has characters, resend last char
	LD	A,(HL)
	DEC	B
	DEC	HL		;A = last char
	;blen=blen-1, next to fill - 1 decremented
	JP	rdech1		;act like this is an echo
notrub:	
	;.NOT. a RUBOUT character, check end line
	CP	CTLE
	jp	nz,note		;physical end line?
	;yes, save active counters and force eol
	PUSH	BC
	LD	A,B
	LD	(SAVEPOS),A
	PUSH	HL
IF	BANKED
	LD	A,(CTLA$sw)
	OR	A
	call	nz,clear$right
ENDIF	
	CALL	crlf
IF	BANKED
	CALL	refresh
ENDIF	
	XOR	A
	LD	(strtcol),A	;start position = 00
	JP	readn0		;for another character
note:	
	;.NOT. end of line, list toggle?
	CP	CTLP
	jp	nz,notp		;skip if .NOT. CTLP
	;list toggle - change parity
	PUSH	HL		;save next to fill - 1
	PUSH	BC
	XOR	A
	CALL	CONB3
	POP	BC
	POP	HL
	JP	readnx		;for another char
notp:	
	;NOT a CTLP, line delete?
	CP	CTLX
	jp	nz,notx
	POP	HL		;discard start position
	;loop while column > strtcol
backx:	
	LD	A,(strtcol)
	LD	HL,column
IF	BANKED
	CP	(HL)
	jp	c,backx1
	LD	HL,(apos)
	LD	A,(HL)
	OR	A
	jp	nz,readx
	JP	read
backx1:	
ELSE	
	CP	(HL)
	jp	nc,read		;start again
ENDIF	
	DEC	(HL)		;column = column - 1
	CALL	backup		;one position
	JP	backx
notx:	
	;NOT a control x, control u?
	;NOT control-X, control-U?
	CP	CTLU
	jp	nz,notu		;skip if .NOT.
IF	BANKED
	EX	(SP),HL
	CALL	copy$xbuff
	EX	(SP),HL
ENDIF	
	;delete line (CTLU)
do$ctlu:	
	CALL	crlfp		;physical eol
	POP	HL		;discard starting position
	JP	read		;to start all over
notu:	
	;.NOT. line delete, repeat line?
	CP	CTLR
	jp	nz,notr
	XOR	A
	LD	(SAVEPOS),A
IF	BANKED
	EX	DE,HL
	CALL	init$apos
	EX	DE,HL
	LD	A,B
	OR	A
	jp	z,do$ctlu
	EX	DE,HL
	LD	HL,(apos)
	INC	B
CTLR$l1:	
	DEC	B
	jp	z,CTLR$l2
	DEC	HL
	LD	A,(DE)
	LD	(HL),A
	DEC	DE
	JP	CTLR$l1
CTLR$l2:	
	LD	(apos),HL
	PUSH	BC
	PUSH	DE
	CALL	crlfp
	LD	A,CTLW
	LD	(ctlw$sw),A
	LD	(CTLA$sw),A
	JP	readn0
ENDIF	
linelen:	
	;repeat line, or compute line len (CTLH)
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
	jp	z,rep1		;count len to 00
	INC	HL
	LD	C,(HL)		;next to print
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
	jp	z,readn0		;for another char if so
	;column position computed for CTLH
	LD	HL,column
	SUB	A,(HL)		;diff > 0
	LD	(compcol),A	;count down below
	;move back compcol-column spaces
backsp:	
	;move back one more space
	CALL	backup		;one space
	LD	HL,compcol
	DEC	(HL)
	jp	nz,backsp
IF	BANKED
	CALL	refresh
ENDIF	
	JP	readn0		;for next character
notr:	
	;NOT a CTLR, place into buffer
	;IS BUFFER FULL?
	PUSH	AF
	LD	A,B
	CP	C
	JP	C ,RDECH0	;NO
	;DISCARD CHARACTER AND RING BELL
	POP	AF
	PUSH	BC
	PUSH	HL
	LD	C,7
	CALL	conoutf
	JP	readn0
RDECH0:	
IF	BANKED
	LD	A,(comchr)
	CP	CTLG
	jp	z,rdech05
	LD	A,(CTLA$sw)
	OR	A
	call	nz,chk$buffer$size
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
	LD	C,A		;ready to print
IF	BANKED
	CALL	save$col
ENDIF	
	CALL	ctlout		;may be up-arrow C
	POP	HL
	POP	BC
IF	BANKED
	LD	A,(comchr)
	CP	CTLG
	jp	z,DO$CTLH
	CP	RUBOUT
	jp	z,rdech2
	CALL	refresh
rdech2:	
ENDIF	
IF	PATCH13 
	LD	A,(conmode)
	AND	08H
	JP	NZ,newjump
ELSE	
	LD	A,(conmode)
	AND	08H
	JP	NZ,NOTC
ENDIF	
	LD	A,(HL)		;recall char
	CP	CTLC		;set flags for reboot test
newjump:	LD	A,B	;move length to A
	jp	nz,notc		;skip if .NOT. a control c
	CP	1		;control C, must be length 1
	jp	z,rebootx		;reboot if blen = 1
	;length .NOT. one, so skip reboot
notc:	
	;.NOT. reboot, are we at end of buffer?
IF	BANKED
	CP	C
	jp	nc,buffer$full
ELSE	
	JP	readnx		;go for another if .NOT.
ENDIF	
IF	BANKED
	PUSH	BC
	PUSH	HL
	CALL	chk$column
	jp	c,readn0
	LD	A,(CTLA$sw)
	OR	A
	jp	z,do$newline
	LD	A,(comchr)
	CP	CTLW
	jp	z,back$one
	CP	CTLF
	jp	z,back$one
	
do$newline:	
	LD	A,CTLE
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
	;disable CTLB or CTLW
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
	LD	(conbuffadd),HL
	LD	C,CR
	JP	conout		;return carriage
	;ret
;
func1:	equ	conech
	;return console character with echo
;
func2:	equ	tabout
	;write console character with tab expansion
;
func3:	
	;return reader character
	CALL	readerf
	JP	sta$ret
;
;func4:	equated to punchf
	;write punch character
;
;func5:	equated to listf
	;write list character
	;write to list device
;
func6:	
	;direct console i/o - read if 0ffh
	LD	A,C
	INC	A
	jp	z,dirinp		;0ffh => 00h, means input mode
	INC	A
	JP	Z ,DIRSTAT	;0feh => direct STATUS function
	INC	A
	JP	Z ,dirinp1	;0fdh => direct input, no status
	JP	conoutf
DIRSTAT:	
	;0feH in C for status
	CALL	CONSTX
	JP	NZ,lret$eq$ff
	JP	sta$ret
dirinp:	
	CALL	CONSTX		;status check
	OR	A
	RET	Z 		;skip, return 00 if .NOT. ready
	;character is ready, get it
dirinp1:	
	CALL	conin		;to A
	JP	sta$ret
;
func7:	
	CALL	auxinstf
	JP	sta$ret
;
func8:	
	CALL	auxoutstf
	JP	sta$ret
;
func9:	
	;write line until $ encountered
	EX	DE,HL		;was lhld info	
	LD	C,L
	LD	B,H		;BC=string address
	JP	print		;out to console	
func10:	equ	readi
	;read a buffered console line
func11:	
	;IS conmode(1) TRUE?
	LD	A,(conmode)
	RRA	
	JP	NC,NORMAL$STATUS;NO
	;CTL-C ONLY STATUS CHECK
IF	BANKED
	LD	HL,qflag
	LD	(HL),80H
	PUSH	HL
ENDIF	
	LD	HL,CTLC$STAT$RET
	PUSH	HL
	;DOES kbchar = CTL-C?
	LD	A,(kbchar)
	CP	CTLC
	JP	Z ,conb1	;YES
	;IS THERE A READY CHARACTER?
	CALL	constf
	OR	A
	RET	Z 		;NO
	;IS THE READY CHARACTER A CTL-C?
	CALL	coninf
	CP	CTLC
	JP	Z ,conb0	;YES
	LD	(kbchar),A
	XOR	A
	RET	
CTLC$STAT$RET:	
IF	BANKED
	CALL	sta$ret
	POP	HL
	LD	(HL),0
	RET	
ELSE	
	JP	sta$ret
ENDIF
IF .NOT. MPM	
NORMAL$STATUS:	
	;check console status
	CALL	conbrk
	;(drop through to sta$ret)
sta$ret:	
	;store the A register to aret
	LD	(aret),A
func$ret:	;
	RET			;jmp goback (pop stack for non cp/m functions)
;
setlret1:	
	;set lret = 1
	LD	A,1
	JP	sta$ret		;
ENDIF
;
func109:	;GET/SET CONSOLE MODE
	;DOES DE = 0FFFFH?
	LD	A,D
	AND	E
	INC	A
	LD	HL,(conmode)
	JP	Z ,sthl$ret	;YES - RETURN CONSOLE MODE
	EX	DE,HL
	LD	(conmode),HL
	RET			;NO - SET CONSOLE MODE
;
func110:	;GET/SET FUNCTION 9 DELIMITER
	LD	HL,outdelim
	;DOES DE = 0FFFFH?
	LD	A,D
	AND	E
	INC	A
	LD	A,(HL)
	JP	Z ,sta$ret	;YES - RETURN DELIMITER
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
	LD	A,(fx)
	CP	111
	JP	Z ,BLK$OUT1
	CALL	listf
	JP	BLK$OUT2
BLK$OUT1:	
	CALL	tabout
BLK$OUT2:	
	POP	HL
	INC	HL
	POP	BC
	DEC	BC
	JP	BLK$OUT
SCONOUTF:	EQU	conoutf
;
;	data areas
;
compcol:	DB	0	;true if computing column position
strtcol:	DB	0	;starting column position after read
IF	.NOT.	BANKED
kbchar:	DB	0		;initial key char = 00
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
CTLA$sw:	DB	0
ctlw$sw:	DB	0
save$column:	DB	0
ctla$column:	DB	0
new$ctla$col:	DB	0
ENDIF	
;	end of BDOS Console module
;
	title	'CP/M BDOS Interface, BDOS, Version 3.0 Dec, 1982'
;*****************************************************************
;*****************************************************************
;**                                                             **
;**   B a s i c    D i s k   O p e r a t i n g   S y s t e m    **
;**								**
;**                  M a i n   M o d u l e                      **
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
;	Error Messages
IF	BANKED
md:	equ	0
ELSE	
md:	equ	24h
ENDIF	
dskmsg:	DB	'CP/M Error On '
dskerr:	DB	' : ',md
permsg:	DB	'Disk I/O',md
selmsg:	DB	'Invalid Drive',md
rofmsg:	DB	'Read/Only File',md
rodmsg:	DB	'Read/Only Disk',md
IF	.NOT.	MPM
passmsg:	
IF	BANKED
	DB	'Password Error',md
ENDIF	
fxstsmsg:	
	DB	'File Exists',md
wildmsg:	
	DB	'? in Filename',md
ENDIF	
IF	MPM	
setlret1:
	LD	A,1
sta$ret:	
	LD	(aret),A
func$ret:	
	RET	
entsp:	DS	2
ENDIF	
;*****************************************************************
;*****************************************************************
;
;	common values shared between bdosi and bdos
IF	MPM	
usrcode:	DB	0	; current user number
ENDIF	
aret:	DS	2		; address value to return
lret:	equ	aret		; low(aret)
;*****************************************************************
;*****************************************************************
;**                                                             **
;**   b a s i c    d i s k   o p e r a t i n g   s y s t e m    **
;**                                                             **
;*****************************************************************
;*****************************************************************
;	literal constants
true:	equ	0ffh		; constant true
false:	equ	000h		; constant false
enddir:	equ	0ffffh		; end of directory
byte:	equ	1		; number of bytes for "byte" type
word:	equ	2		; number of bytes for "word" type
;	fixed addresses in low memory
tfcb:	equ	005ch		; default fcb location
tbuff:	equ	0080h		; default buffer location
;	error message handlers
rod$error:	
	; report read/only disk error
	LD	C,2
	JP	goerr
rof$error:	
	; report read/only file error
	LD	C,3
	JP	goerr	
sel$error:	
	; report select error
	LD	C,4
	; Invalidate curdsk to force select call
	; at next curselect call
	LD	A,0ffh
	LD	(curdsk),A
goerr:	
	; hl = .errorhandler, call subroutine
	LD	H,C
	LD	L,0ffh
	LD	(aret),HL
IF	MPM	
	CALL	test$error$mode
	jp	nz,rtn$phy$errs
	LD	A,C
	LD	HL,pererr-2
	JP	bdos$jmp
ELSE	
goerr1:	
	LD	A,(adrive)
	LD	(errdrv),A
	LD	A,(error$mode)
	INC	A
	call	nz,error
ENDIF	
rtn$phy$errs:	
IF	MPM	
	LD	A,(lock$shell)
	OR	A
	jp	nz,lock$perr
ENDIF	
	; Return 0ffffh if fx = 27 or 31
	LD	A,(fx) 
	CP	27
	jp	z,goback0
	CP	31
	jp	z,goback0
	JP	goback
IF	MPM	
test$error$mode:	
	LD	DE,pname+4
test$error$mode1:	
	CALL	rlr
	ADD	HL,DE
	LD	A,(HL)
	AND	80h
	RET	
ENDIF	
IF	BANKED
set$copy$cr$only:	
	LD	A,(copy$cr$init)
	LD	(copy$cr$only),A
	RET	
reset$copy$cr$only:	
	XOR	A
	LD	(copy$cr$init),A
	LD	(copy$cr$only),A
	RET	
ENDIF	
bde$e$bde$m$hl:	
	LD	A,E
	SUB	A,L
	LD	E,A
	LD	A,D
	SBC	A,H
	LD	D,A
	ret	nc
	DEC	B
	RET	
bde$e$bde$p$hl:	
	LD	A,E
	ADD	A,L
	LD	E,A
	LD	A,D
	ADC	A,H
	LD	D,A
	ret	nc
	INC	B
	RET	
shl3bv:	
	INC	C
shl3bv1:	
	DEC	C
	ret	z
	ADD	HL,HL
	ADC	A,A
	JP	shl3bv1
incr$rr:	
	CALL	get$rra
	INC	(HL)
	ret	nz
	INC	HL
	INC	(HL)
	ret	nz
	INC	HL
	INC	(HL)
	RET	
save$rr:	
	CALL	save$rr2
	EX	DE,HL
save$rr1:	
	LD	C,3
	JP	move		; ret
save$rr2:	
	CALL	get$rra
	LD	DE,save$ranr
	RET	
reset$rr:	
	CALL	save$rr2
	JP	save$rr1	; ret
compare:	
	LD	A,(DE)
	CP	(HL)
	ret	nz
	INC	HL
	INC	DE
	DEC	C
	ret	z
	JP	compare
;
;	local subroutines for bios interface
;
move:	
	; Move data length of length c from source de to
	; destination given by hl
	INC	C		; in case it is zero
move0:	
	DEC	C
	ret	z		; more to move
	LD	A,(DE)
	LD	(HL),A		; one byte moved
	INC	DE
	INC	HL		; to next byte
	JP	move0
selectdisk:	
	; Select the disk drive given by register D, and fill
	; the base addresses curtrka - alloca, then fill
	; the values of the disk parameter block
	LD	C,D		; current disk# to c
	; lsb of e = 0 if .NOT. yet logged - in
	CALL	seldskf		; hl filled by call
	; hl = 0000 if error, otherwise disk headers
	LD	A,H
	OR	L
	ret	z		; Return with C flag reset if select error
	; Disk header block address in hl
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL		; de=.tran
	LD	(cdrmaxa),HL
	INC	HL
	INC	HL		; .cdrmax
	LD	(curtrka),HL
	INC	HL
	INC	HL		; hl=.currec
	LD	(curreca),HL
	INC	HL
	INC	HL		; hl=.buffa
	INC	HL
	LD	(drvlbla),HL
	INC	HL
	LD	(lsn$add),HL
	INC	HL
	INC	HL
	; de still contains .tran
	EX	DE,HL
	LD	(tranv),HL	; .tran vector
	LD	HL,dpbaddr	; de= source for move, hl=dest
	LD	C,addlist
	CALL	move		; addlist filled
	; Now fill the disk parameter block
	LD	HL,(dpbaddr)
	EX	DE,HL		; de is source
	LD	HL,sectpt	; hl is destination
	LD	C,dpblist
	CALL	move		; data filled
	; Now set single/double map mode
	LD	HL,(maxall)	; largest allocation number
	LD	A,H		; 00 indicates < 255
	LD	HL,single
	LD	(HL),true	; Assume a=00
	OR	A
	jp	z,retselect
	; high order of maxall .NOT. zero, use double dm
	LD	(HL),false
retselect:	
	; C flag set indicates successful select
	SCF	
	RET	
home:	
	; Move to home position, then offset to start of dir
	CALL	homef
	XOR	A		; constant zero to accumulator
	LD	HL,(curtrka)
	LD	(HL),A
	INC	HL
	LD	(HL),A		; curtrk=0000
	LD	HL,(curreca)
	LD	(HL),A
	INC	HL
	LD	(HL),A		; currec=0000
	INC	HL
	LD	(HL),A		; currec high byte=00
IF	MPM	
	LD	HL,0
	LD	(dblk),HL	; dblk = 0000
ENDIF	
	RET	
rdbuff:	
	; Read buffer and check condition
	LD	A,1
	LD	(readf$sw),A
	CALL	readf		; current drive, track, sector, dma
	JP	diocomp		; Check for i/o errors
wrbuff:	
	; Write buffer and check condition
	; write type (wrtype) is in register c
	XOR	A
	LD	(readf$sw),A
	CALL	writef		; current drive, track, sector, dma
diocomp:	; Check for disk errors
	OR	A
	ret	z
	LD	C,A
	CALL	chk$media$flag
	LD	A,C
	CP	3
	jp	c,goerr
	LD	C,1
	JP	goerr
chk$media$flag:	
	; A = 0ffh -> media changed
	INC	A
	ret	nz
IF	BANKED
	; Handle media changes as I/O errors for 
	; permanent drives
	CALL	chksiz$eq$8000h
	ret	z
ENDIF	
	; BIOS says media change occurred
	; Is disk logged-in?
	LD	HL,(dlog)
	CALL	test$vector
	LD	C,1
	ret	z		; no - return error
	CALL	media$change
	POP	HL		; Discard return address
	; Was this a flush operation (fx = 48)?
	LD	A,(fx)
	CP	48
	ret	z		; yes
	; Is this a flush to another drive?
	LD	HL,adrive
	LD	A,(seldsk)
	CP	(HL)
	jp	nz,reset$relog
	; Bail out if fx = read, write, close, or search next
	CALL	chk$exit$fxs
	; Is this a directory read operation?
	LD	A,(readf$sw)
	OR	A
	ret	nz		; yes
	; Error - directory write operation
	LD	C,2
	JP	goerr		; Return disk read/only error
reset$relog:	
	; Reset relog if flushing to another drive
	XOR	A
	LD	(relog),A
	RET	
IF	BANKED
chksiz$eq$8000h:	
	; Return with Z flag set if drive permanent
	; with no checksum vector
	LD	HL,(chksiz)
	LD	A,80h
	CP	H
	ret	nz
	XOR	A
	CP	L
	RET	
ENDIF	
seek$dir:	
	; Seek the record containing the current dir entry
IF	MPM	
	LD	DE,0ffffh	; mask = ffff
	LD	HL,(dblk)
	LD	A,H
	OR	L
	jp	z,seekdir1
	LD	A,(blkmsk)
	LD	E,A
	XOR	A
	LD	D,A		; mask = blkmsk
	LD	A,(blkshf)
	LD	C,A
	XOR	A
	CALL	shl3bv		; ahl = shl(dblk,blkshf)
seekdir1:	
	PUSH	HL
	PUSH	AF		; Save ahl
ENDIF	
	LD	HL,(dcnt)	; directory counter to hl
	LD	C,dskshf
	CALL	hlrotr		; value to hl
	LD	(drec),HL
IF	MPM	
;	arecord = shl(dblk,blkshf) + shr(dcnt,dskshf) & mask
	LD	A,L
	AND	E
	LD	L,A		; dcnt = dcnt & mask
	LD	A,H
	AND	D
	LD	H,A
	POP	BC
	POP	DE
	CALL	bde$e$bde$p$hl
ELSE	
	LD	B,0
	EX	DE,HL
ENDIF	
set$arecord:	
	LD	HL,arecord
	LD	(HL),E
	INC	HL
	LD	(HL),D
	INC	HL
	LD	(HL),B
	RET	
seek:	
	; Seek the track given by arecord (actual record)
	LD	HL,(curtrka)
	LD	C,(HL)
	INC	HL
	LD	B,(HL)		; bc = curtrk
	PUSH	BC		; s0 = curtrk 
	LD	HL,(curreca)
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	B,(HL)		; bde = currec
	LD	HL,(arecord)
	LD	A,(arecord+2)
	LD	C,A		; chl = arecord
seek0:	
	LD	A,L
	SUB	A,E
	LD	A,H
	SBC	A,D
	LD	A,C
	SBC	A,B
	PUSH	HL		; Save low(arecord)
	jp	nc,seek1		; if arecord >= currec then go to seek1
	LD	HL,(sectpt)
	CALL	bde$e$bde$m$hl	; currec = currec - sectpt
	POP	HL
	EX	(SP),HL
	DEC	HL
	EX	(SP),HL		; curtrk = curtrk - 1
	JP	seek0
seek1:	
	LD	HL,(sectpt)
	CALL	bde$e$bde$p$hl	; currec = currec + sectpt
	POP	HL		; Restore low(arecord)
	LD	A,L
	SUB	A,E
	LD	A,H
	SBC	A,D
	LD	A,C
	SBC	A,B
	jp	c,seek2		; if arecord < currec then go to seek2
	EX	(SP),HL
	INC	HL
	EX	(SP),HL		; curtrk = curtrk + 1
	PUSH	HL		; save low (arecord)
	JP	seek1
seek2:	
	EX	(SP),HL
	PUSH	HL		; hl,s0 = curtrk, s1 = low(arecord)
	LD	HL,(sectpt)
	CALL	bde$e$bde$m$hl	; currec = currec - sectpt
	POP	HL
	PUSH	DE
	PUSH	BC
	PUSH	HL		; hl,s0 = curtrk, 
	; s1 = high(arecord,currec), s2 = low(currec), 
	; s3 = low(arecord)
	EX	DE,HL
	LD	HL,(offset)
	ADD	HL,DE
	LD	B,H
	LD	C,L
	LD	(track),HL
	CALL	settrkf		; call bios settrk routine
	; Store curtrk
	POP	DE
	LD	HL,(curtrka)
	LD	(HL),E
	INC	HL
	LD	(HL),D
	; Store currec
	POP	BC
	POP	DE
	LD	HL,(curreca)
	LD	(HL),E
	INC	HL
	LD	(HL),D
	INC	HL
	LD	(HL),B		; currec = bde
	POP	BC		; bc = low(arecord), de = low(currec)
	LD	A,C
	SUB	A,E
	LD	L,A		; hl = bc - de
	LD	A,B
	SBC	A,D  
	LD	H,A
	CALL	shr$physhf
	LD	B,H
	LD	C,L
	LD	HL,(tranv)
	EX	DE,HL		; bc=sector#, de=.tran
	CALL	sectran		; hl = tran(sector)
	LD	C,L
	LD	B,H		; bc = tran(sector)
	LD	(sector),HL
	CALL	setsecf		; sector selected
	LD	HL,(curdma)
	LD	C,L
	LD	B,H
	JP	setdmaf
	; ret
shr$physhf:	
	LD	A,(physhf)
	LD	C,A
	JP	hlrotr
;	file control block (fcb) constants
empty:	equ	0e5h		; empty directory entry
lstrec:	equ	127		; last record# on extent
recsiz:	equ	128		; record size
fcblen:	equ	32		; file control block size
dirrec:	equ	recsiz/fcblen	; directory fcbs / record
dskshf:	equ	2		; log2(dirrec)
dskmsk:	equ	dirrec-1
fcbshf:	equ	5		; log2(fcblen)
extnum:	equ	12		; extent number field
maxext:	equ	31		; largest extent number
ubytes:	equ	13		; unfilled bytes field
modnum:	equ	14		; data module number
maxmod:	equ	64		; largest module number
fwfmsk:	equ	80h		; file write flag is high order modnum
namlen:	equ	15		; name length
reccnt:	equ	15		; record count field
dskmap:	equ	16		; disk map field
lstfcb:	equ	fcblen-1
nxtrec:	equ	fcblen
ranrec:	equ	nxtrec+1	; random record field (2 bytes)
;	reserved file indicators
rofile:	equ	9		; high order of first type char
invis:	equ	10		; invisible file in dir command
;	utility functions for file access
dm$position:	
	; Compute disk map position for vrecord to hl
	LD	HL,blkshf
	LD	C,(HL)		; shift count to c
	LD	A,(vrecord)	; current virtual record to a
dmpos0:	
	OR	A
	RRA	
	DEC	C
	jp	nz,dmpos0
	; a = shr(vrecord,blkshf) = vrecord/2**(sect/block)
	LD	B,A		; Save it for later addition
	LD	A,8
	SUB	A,(HL)		; 8-blkshf to accumulator
	LD	C,A		; extent shift count in register c
	LD	A,(extval)	; extent value ani extmsk
dmpos1:	
	; blkshf = 3,4,5,6,7, c=5,4,3,2,1
	; shift is 4,3,2,1,0
	DEC	C
	jp	z,dmpos2
	OR	A
	RLA	
	JP	dmpos1
dmpos2:	
	; Arrive here with a = shl(ext and extmsk,7-blkshf)
	ADD	A,B		; Add the previous shr(vrecord,blkshf) value
	; a is one of the following values, depending upon alloc
	; bks blkshf
	; 1k   3     v/8 + extval * 16
	; 2k   4     v/16+ extval * 8
	; 4k   5     v/32+ extval * 4
	; 8k   6     v/64+ extval * 2
	; 16k  7     v/128+extval * 1
	RET			; with dm$position in a
getdma:	
	LD	HL,(info)
	LD	DE,dskmap
	ADD	HL,DE
	RET	
getdm:	
	; Return disk map value from position given by bc
	CALL	getdma
	ADD	HL,BC		; Index by a single byte value
	LD	A,(single)	; single byte/map entry?
	OR	A
	jp	z,getdmd		; Get disk map single byte
	LD	L,(HL)
	LD	H,B
	RET			; with hl=00bb
getdmd:	
	ADD	HL,BC		; hl=.fcb(dm+i*2)
	; double precision value returned
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	RET	
index:	
	; Compute disk block number from current fcb
	CALL	dm$position	; 0...15 in register a
	LD	(dminx),A
	LD	C,A
	LD	B,0
	CALL	getdm		; value to hl
	LD	(arecord),HL
	LD	A,L
	OR	H
	RET	
atran:	
	; Compute actual record address, assuming index called
;	arecord = shl(arecord,blkshf)
	LD	A,(blkshf)
	LD	C,A
	LD	HL,(arecord)
	XOR	A
	CALL	shl3bv
	LD	(arecord),HL
	LD	(arecord+2),A
	LD	(arecord1),HL	; Save low(arecord)
;	arecord = arecord or (vrecord and blkmsk)
	LD	A,(blkmsk)
	LD	C,A
	LD	A,(vrecord)
	AND	C
	LD	B,A		; Save vrecord & blkmsk in reg b & blk$off
	LD	(blk$off),A
	LD	HL,arecord
	OR	(HL)
	LD	(HL),A
	RET	
get$atts:	
	; Get volatile attributes starting at f'5
	; info locates fcb
	LD	HL,(info)
	LD	DE,8
	ADD	HL,DE		; hl = .fcb(f'8)
	LD	C,4
get$atts$loop:	
	LD	A,(HL)
	ADD	A,A
	PUSH	AF
	LD	A,D
	RRA	
	LD	D,A
	POP	AF
	RRCA	
	LD	(HL),A
	DEC	HL
	DEC	C
	jp	nz,get$atts$loop
	LD	A,D
	RET	
gets1:	
	; Get current s1 field to a
	CALL	getexta
	INC	HL
	LD	A,(HL)
	RET	
get$rra:	
	; Get current ran rec field address to hl
	LD	HL,(info)
	LD	DE,ranrec
	ADD	HL,DE		; hl=.fcb(ranrec)
	RET	
getexta:	
	; Get current extent field address to hl
	LD	HL,(info)
	LD	DE,extnum
	ADD	HL,DE		; hl=.fcb(extnum)
	RET	
getrcnta:	
	; Get reccnt address to hl
	LD	HL,(info)
	LD	DE,reccnt
	ADD	HL,DE
	RET	
getfcba:	
	; Compute reccnt and nxtrec addresses for get/setfcb
	CALL	getrcnta
	EX	DE,HL		; de=.fcb(reccnt)
	LD	HL,nxtrec-reccnt
	ADD	HL,DE		; hl=.fcb(nxtrec) 
	RET	
getfcb:	
	; Set variables from currently addressed fcb
	CALL	getfcba		; addresses in de, hl
	LD	A,(HL)
	LD	(vrecord),A	; vrecord=fcb(nxtrec)
	EX	DE,HL
	LD	A,(HL)
	OR	A
	jp	nz,getfcb0
	CALL	get$dir$ext
	LD	C,A
	CALL	set$rc
	LD	A,(HL)
getfcb0:	
	CP	81h
	jp	c,getfcb1
	LD	A,80h
getfcb1:	
	LD	(rcount),A	; rcount=fcb(reccnt) or 80h
	CALL	getexta		; hl=.fcb(extnum)
	LD	A,(extmsk)	; extent mask to a
	AND	(HL)		; fcb(extnum) and extmsk
	LD	(extval),A
	RET	
setfcb:	
	; Place values back into current fcb
	CALL	getfcba		; addresses to de, hl
	; fcb(cr) = vrecord
	LD	A,(vrecord)
	LD	(HL),A
	; Is fx < 22? (sequential read or write)
	LD	A,(fx)
	CP	22
	jp	nc,$+4		; no
	; fcb(cr) = fcb(cr) + 1
	INC	(HL)
	EX	DE,HL
	LD	A,(HL)
	CP	80h
	ret	nc		; dont reset fcb(rc) if > 7fh
	LD	A,(rcount)
	LD	(HL),A		; fcb(reccnt)=rcount
	RET	
zero$ext$mod:	
	CALL	getexta
	LD	(HL),D
	INC	HL
	INC	HL
	LD	(HL),D
	RET	
zero:	
	LD	(HL),B
	INC	HL
	DEC	C
	ret	z
	JP	zero
hlrotr:	
	; hl rotate right by amount c
	INC	C		; in case zero
hlrotr0:	DEC	C
	ret	z		; return when zero
	LD	A,H
	OR	A
	RRA	
	LD	H,A		; high byte
	LD	A,L
	RRA	
	LD	L,A		; low byte
	JP	hlrotr0
compute$cs:	
	; Compute checksum for current directory buffer
	LD	HL,(buffa)	; current directory buffer
	LD	BC,4		; b = 0, c = 4
compute$cs0:	
	LD	D,32		; size of fcb
	XOR	A		; clear checksum value
compute$cs1:	
	ADD	A,(HL)
	INC	HL
	DEC	D 
	jp	nz,compute$cs1
	XOR	B
	LD	B,A
	DEC	C
	jp	nz,compute$cs0
	RET			; with checksum in a
IF	MPM	
compute$cs:	
	; Compute checksum for current directory buffer
	LD	C,recsiz	; size of directory buffer
	LD	HL,(buffa)	; current directory buffer
	XOR	A		; Clear checksum value
computecs0:	
	ADD	A,(HL)
	INC	HL
	DEC	C		; cs = cs+buff(recsiz-c)
	jp	nz,computecs0
	RET			; with checksum in a
chksum$fcb:	; Compute checksum for fcb
	; Add 1st 12 bytes of fcb + curdsk + 
	;     high$ext + xfcb$read$only + bbh
	LD	HL,pdcnt
	LD	A,(HL)
	INC	HL
	ADD	A,(HL)		; Add high$ext
	INC	HL
	ADD	A,(HL)		; Add xfcb$read$only
	INC	HL
	ADD	A,(HL)		; Add curdsk
	ADD	A,0bbh		; Add 0bbh to bias checksum
	LD	HL,(info)
	LD	C,12
	CALL	computecs0
	; Skip extnum
	INC	HL
	; Add fcb(s1)
	ADD	A,(HL)
	INC	HL
	; Skip modnum
	INC	HL
	; Skip fcb(reccnt)
	; Add disk map
	INC	HL
	LD	C,16
	CALL	computecs0
	OR	A
	RET			; Z flag set if checksum valid
set$chksum$fcb:	
	CALL	chksum$fcb
	ret	z
	LD	B,A
	CALL	gets1
	CPL	
	ADD	A,B
	CPL	
	LD	(HL),A
	RET	
reset$chksum$fcb:	
	XOR	A
	LD	(comp$fcb$cks),A
	CALL	chksum$fcb
	ret	nz
	CALL	gets1
	INC	(HL)
	RET	
ENDIF	
check$fcb:	
IF	MPM	
	XOR	A
	LD	(check$fcb4),A
check$fcb1:	
	CALL	chek$fcb
	ret	z
check$fcb2:	
	AND	0fh
	jp	nz,check$fcb3
	LD	A,(pdcnt)
	OR	A
	jp	z,check$fcb3
	CALL	set$sdcnt
	LD	(dont$close),A
	CALL	close1
	LD	HL,lret
	INC	(HL)
	jp	z,check$fcb3
	LD	(HL),0
	CALL	pack$sdcnt
	LD	B,5
	CALL	search$olist
	ret	z
check$fcb3:	
	POP	HL		; Discard return address
check$fcb4:	
	nop	
	LD	A,10
	JP	sta$ret
set$fcb$cks$flag:	
	LD	A,0ffh
	LD	(comp$fcb$cks),A
	RET	
ELSE	
	CALL	gets1
	LD	HL,(lsn$add)
	CP	(HL)
	call	nz,chk$media$fcb
ENDIF	
chek$fcb:	
	LD	A,(high$ext)
IF	MPM	
	; if ext & 0110_0000b = 0110_0000b then
	; set fcb(0) to 0 (user 0)
	CP	0110_0000b
	jp	nz,chek$fcb1
ELSE	
	OR	A
	ret	z
ENDIF	
	LD	HL,(info)
	XOR	A
	LD	(HL),A		; fcb(0) = 0
chek$fcb1:	
IF	MPM	
	JP	chksum$fcb	; ret
ELSE	
	RET	
chk$media$fcb:	
	; fcb(s1) ~= DPH login sequence # field
	; Is fcb addr < bdosadd?
IF	BANKED
	LD	HL,(user$info)
ELSE	
	LD	HL,(info)
ENDIF	
	EX	DE,HL
	LD	HL,(bdosadd)
	CALL	subdh
	jp	nc,chk$media1	; no
	; Is rlog(drive) true?
	LD	HL,(rlog)
	CALL	test$vector
	ret	z		; no
chk$media1:	
	; Return invalid fcb error code
	POP	HL
	POP	HL
chk$media2:	
	LD	A,10
	JP	sta$ret
ENDIF	
hlrotl:	
	; Rotate the mask in hl by amount in c
	INC	C		; may be zero
hlrotl0:	DEC	C
	ret	z		; return if zero
	ADD	HL,HL
	JP	hlrotl0
set$dlog:	
	LD	DE,dlog
set$cdisk:	
	; Set a "1" value in curdsk position of bc
	LD	A,(curdsk)
set$cdisk1:	
	LD	C,A		; Ready parameter for shift
	LD	HL,1		; number to shift
	CALL	hlrotl		; hl = mask to integrate
	LD	A,(DE)
	OR	L
	LD	(DE),A
	INC	DE
	LD	A,(DE)
	OR	H
	LD	(DE),A
	RET	
nowrite:	
	; Return true if dir checksum difference occurred
	LD	HL,(rodsk)
test$vector:	
	LD	A,(curdsk)
test$vector1:	
	LD	C,A
	CALL	hlrotr
	LD	A,L
	AND	1b
	RET			; non zero if curdsk bit on
check$rodir:	
	; Check current directory element for read/only status
	CALL	getdptra	; address of element
check$rofile:	
	; Check current buff(dptr) or fcb(0) for r/o status
	CALL	ro$test
	ret	nc		; Return if .NOT. set
	JP	rof$error	; Exit to read only disk message
ro$test:	
	LD	DE,rofile
	ADD	HL,DE
	LD	A,(HL)
	RLA	
	RET			; carry set if r/o
check$write:	
	; Check for write protected disk
	CALL	nowrite
	ret	z		; ok to write if .NOT. rodsk
	JP	rod$error	; read only disk error
getdptra:	
	; Compute the address of a directory element at
	; positon dptr in the buffer
	LD	HL,(buffa)
	LD	A,(dptr)
_addh:	
	; hl = hl + a
	ADD	A,L
	LD	L,A
	ret	nc
	; overflow to h
	INC	H
	RET	
getmodnum:	
	; Compute the address of the module number 
	; bring module number to accumulator
	; (high order bit is fwf (file write flag)
	LD	HL,(info)
	LD	DE,modnum
	ADD	HL,DE		; hl=.fcb(modnum)
	LD	A,(HL)
	RET			; a=fcb(modnum)
clrmodnum:	
	; Clear the module number field for user open/make
	CALL	getmodnum
	LD	(HL),0		; fcb(modnum)=0
	RET	
clr$ext:	
	; fcb ext = fcb ext & 1fh
	CALL	getexta
	LD	A,(HL)
	AND	0001_1111b
	LD	(HL),A
	RET	
setfwf:	
	CALL	getmodnum	; hl=.fcb(modnum), a=fcb(modnum)
	; Set fwf (file write flag) to "1"
	OR	fwfmsk
	LD	(HL),A		; fcb(modnum)=fcb(modnum) or 80h
	; also returns non zero in accumulator
	RET	
compcdr:	
	; Return cy if cdrmax > dcnt
	LD	HL,(dcnt)
	EX	DE,HL		; de = directory counter
	LD	HL,(cdrmaxa)	; hl=.cdrmax
	LD	A,E
	SUB	A,(HL)		; low(dcnt) - low(cdrmax)
	INC	HL		; hl = .cdrmax+1
	LD	A,D
	SBC	A,(HL)		; hig(dcnt) - hig(cdrmax)
	; condition dcnt - cdrmax  produces cy if cdrmax>dcnt
	RET	
setcdr:	
	; if .NOT. (cdrmax > dcnt) then cdrmax = dcnt+1
	CALL	compcdr
	ret	c		; Return if cdrmax > dcnt
	; otherwise, hl = .cdrmax+1, de = dcnt
	INC	DE
	LD	(HL),D
	DEC	HL
	LD	(HL),E
	RET	
subdh:	
	; Compute hl = de - hl
	LD	A,E
	SUB	A,L
	LD	L,A
	LD	A,D
	SBC	A,H
	LD	H,A
	RET	
newchecksum:	
	LD	C,0feh		; Drop through to compute new checksum
checksum:	
	; Compute current checksum record and update the
	; directory element if c=true, or check for = if .NOT.
	; drec < chksiz?
	LD	HL,(drec)
	EX	DE,HL
	LD	HL,(chksiz)
	LD	A,H
	AND	7fh
	LD	H,A		; Mask off permanent drive bit
	CALL	subdh		; de-hl
	ret	nc		; Skip checksum if past checksum vector size
	; drec < chksiz, so continue
	PUSH	BC		; Save init flag
	CALL	compute$cs	; Check sum value to a
	LD	HL,(checka)	; address of check sum vector
	EX	DE,HL
	LD	HL,(drec)
	ADD	HL,DE		; hl = .check(drec)
	POP	BC		; Recall true=0ffh or false=00 to c
	INC	C		; 0ffh produces zero flag
	jp	z,initial$cs
	INC	C		; 0feh produces zero flag
	jp	z,update$cs
IF	MPM	
	INC	C
	jp	z,test$dir$cs
ENDIF	
	; .NOT. initializing, compare
	CP	(HL)		; compute$cs=check(drec)?
	ret	z		; no message if ok
	; checksum error, are we beyond
	; the end of the disk?
IF	PATCH13
	CALL	nowrite
	nop	
ELSE	
	CALL	nowrite
	ret	nz
ENDIF	
media$change:	
	CALL	discard$data
IF	MPM	
	CALL	flush$file0
ELSE	
	LD	A,0ffh
	LD	(relog),A
	LD	(hashl),A
	CALL	set$rlog
ENDIF	
	; Reset the drive
	CALL	set$dlog
	JP	reset$37x
IF	MPM	
test$dir$cs:	
	CP	(HL)
	jp	nz,flush$files
	RET	
ENDIF	
initial$cs:	
	; initializing the checksum
	CP	(HL)
	LD	(HL),A
	ret	z
	; or 1 into login seq # if media change
	LD	HL,(lsn$add)
	LD	A,1
	OR	(HL)
	LD	(HL),A
	RET	
update$cs:	
	; updating the checksum
	LD	(HL),A
	RET	
set$ro:	
	; Set current disk to read/only
	LD	A,(seldsk)
	LD	DE,rodsk
	CALL	set$cdisk1	; sets bit to 1
	; high water mark in directory goes to max
	LD	HL,(dirmax)
	INC	HL
	EX	DE,HL		; de = directory max
	LD	HL,(cdrmaxa)	; hl = .cdrmax
	LD	(HL),E
	INC	HL
	LD	(HL),D		; cdrmax = dirmax
	RET	
set$rlog:	
	; rlog(seldsk) = true
	LD	HL,(olog)
	CALL	test$vector
	ret	z
	LD	DE,rlog
	JP	set$cdisk
tst$log$fxs:	
	LD	A,(chksiz+1)
	AND	80h
	ret	nz
	LD	HL,log$fxs
tst$log0:	
	LD	A,(fx)
	LD	B,A
tst$log1:	
	LD	A,(HL)
	CP	B
	ret	z
	INC	HL
	OR	A
	jp	nz,tst$log1
	INC	A
	RET	
test$media$flag:	
	LD	HL,(lsn$add)
	INC	HL
	LD	A,(HL)
	OR	A
	RET	
chk$exit$fxs:	
	LD	HL,goback
	PUSH	HL
	; does fx = read or write function?
	; and is drive removable?
	LD	HL,rw$fxs
	CALL	tst$log0
	jp	z,chk$media2	; yes
	; is fx = close or searchn function?
	; and is drive removable?
	LD	HL,sc$fxs
	CALL	tst$log0
	jp	z,lret$eq$ff	; yes
	POP	HL
	RET	
tst$relog:	
	LD	HL,relog
	LD	A,(HL)
	OR	A
	ret	z
	LD	(HL),0
drv$relog:	
	CALL	curselect
	LD	HL,0
	LD	(dcnt),HL
	XOR	A
	LD	(dptr),A
	RET	
set$lsn:	
	LD	HL,(lsn$add)
	LD	C,(HL)
	CALL	gets1
	LD	(HL),C
	RET	
discard$data$bcb:	
	LD	HL,(dta$bcba)
	LD	C,4
	JP	discard0
discard$data:	
	LD	HL,(dta$bcba)
	JP	discard
discard$dir:	
	LD	HL,(dirbcba)
discard:	
	LD	C,1
discard0:	
	LD	A,L
	AND	H
	INC	A
	ret	z
IF	BANKED
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
discard1:	
	PUSH	HL
	PUSH	BC
	LD	DE,adrive
	CALL	compare
	POP	BC
	POP	HL
	jp	nz,discard2
	LD	(HL),0ffh
discard2:	
	LD	DE,13
	ADD	HL,DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	LD	A,L
	OR	H
	ret	z
	JP	discard1
ELSE	
	PUSH	HL
	LD	DE,adrive
	CALL	compare
	POP	HL
	ret	nz
	LD	(HL),0ffh
	RET	
ENDIF	
get$buffa:	
	PUSH	DE
	LD	DE,10
	ADD	HL,DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
IF	BANKED
	INC	HL
	LD	A,(HL)
	LD	(buffer$bank),A
ENDIF	
	EX	DE,HL
	POP	DE
	RET	
rd$dir:	
	; Read a directory entry into the directory buffer
	CALL	seek$dir
	LD	A,3
	JP	wrdir0
seek$copy:	
wrdir:	
	; Write the current directory entry, set checksum
	CALL	check$write
	CALL	newchecksum	; Initialize entry
	LD	A,5
wrdir0:	
	LD	HL,0
	LD	(last$block),HL
	LD	HL,(dirbcba)
IF	BANKED
	CP	5
	jp	nz,$+6
	LD	HL,(curbcba)
ENDIF	
	CALL	deblock
setdata:	
	; Set data dma address
	LD	HL,(dmaad)
	JP	setdma		; to complete the call
setdir1:	
	CALL	get$buffa
setdma:	
	; hl=.dma address to set (i.e., buffa or dmaad)
	LD	(curdma),HL
	RET	
dir$to$user:	
IF	.NOT.	MPM
	; Copy the directory entry to the user buffer
	; after call to search or searchn by user code
	LD	HL,(buffa)
	EX	DE,HL		; source is directory buffer
	LD	HL,(xdmaad)	; destination is user dma address
	LD	BC,recsiz	; copy entire record
	CALL	movef
ENDIF	
	; Set lret to dcnt & 3 if search successful
	LD	HL,lret
	LD	A,(HL)
	INC	A
	ret	z
	LD	A,(dcnt)
	AND	dskmsk
	LD	(HL),A
	RET	
make$fcb$inv:	; Flag fcb as invalid
	; Reset fcb write flag
	CALL	setfwf
	; Set 1st two bytes of diskmap to ffh
	INC	HL
	INC	HL
	LD	A,0ffh
	LD	(HL),A
	INC	HL
	LD	(HL),A
	RET	
chk$inv$fcb:	; Check for invalid fcb
	CALL	getdma
	JP	test$ffff
tst$inv$fcb:	; Test for invalid fcb
	CALL	chk$inv$fcb
	ret	nz
	POP	HL
	LD	A,9
	JP	sta$ret
	; lret = 9
end$of$dir:	
	; Return zero flag if at end of directory, non zero
	; if .NOT. at end (end of dir if dcnt = 0ffffh)
	LD	HL,dcnt
test$ffff:	
	LD	A,(HL)		; may be 0ffh
	INC	HL
	CP	(HL)		; low(dcnt) = high(dcnt)?
	ret	nz		; non zero returned if different
	; high and low the same, = 0ffh?
	INC	A		; 0ffh becomes 00 if so
	RET	
set$end$dir:	
	; Set dcnt to the end of the directory
	LD	HL,enddir
	LD	(dcnt),HL
	RET	
read$dir:	
	CALL	r$dir
	JP	r$dir1
r$dir:	
	; Read next directory entry, with c=true if initializing
	LD	HL,(dirmax)
	EX	DE,HL		; in preparation for subtract
	LD	HL,(dcnt)
	INC	HL
	LD	(dcnt),HL	; dcnt=dcnt+1
	; Continue while dirmax >= dcnt (dirmax-dcnt no cy)
	CALL	subdh		; de-hl
	jp	c,set$end$dir
read$dir0:	
	; .NOT. at end of directory, seek next element
	; initialization flag is in c
	LD	A,(dcnt)
	AND	dskmsk		; low(dcnt) and dskmsk
	LD	B,fcbshf	; to multiply by fcb size
read$dir1:	
	ADD	A,A
	DEC	B
	jp	nz,read$dir1
	; a = (low(dcnt) and dskmsk) shl fcbshf
	LD	(dptr),A	; ready for next dir operation
	OR	A
	ret	nz		; Return if .NOT. a new record
read$dir2:	
	PUSH	BC		; Save initialization flag c
	CALL	rd$dir		; Read the directory record
	POP	BC		; Recall initialization flag
	LD	A,(relog)
	OR	A
	ret	nz
	JP	checksum	; Checksum the directory elt
r$dir2:	
	CALL	read$dir2
r$dir1:	
	LD	A,(relog)
	OR	A
	ret	z
	CALL	chk$exit$fxs
	CALL	tst$relog
	JP	rd$dir
getallocbit:	
	; Given allocation vector position bc, return with byte
	; containing bc shifted so that the least significant
	; bit is in the low order accumulator position.  hl is
	; the address of the byte for possible replacement in
	; memory upon return, and d contains the number of shifts
	; required to place the returned value back into position
	LD	A,C
	AND	111b
	INC	A
	LD	E,A
	LD	D,A
	; d and e both contain the number of bit positions to shift
	LD	H,B
	LD	L,C
	LD	C,3		; bc = bc shr 3
	CALL	hlrotr		; hlrotr does .NOT. touch d and e
	LD	B,H
	LD	C,L
	LD	HL,(alloca)	; base address of allocation vector
	ADD	HL,BC
	LD	A,(HL)		; byte to a, hl = .alloc(bc shr 3)
	; Now move the bit to the low order position of a
rotl:	RLCA	
	DEC	E
	jp	nz,rotl
	RET	
set$alloc$bit:	
	; bc is the bit position of alloc to set or reset.  the
	; value of the bit is in register e.
	PUSH	DE
	CALL	getallocbit	; shifted val a, count in d
	AND	1111_1110b	; mask low bit to zero (may be set)
	POP	BC
	OR	C		; low bit of c is masked into a
	; jmp rotr ; to rotate back into proper position	
	; ret
rotr:	
	; byte value from alloc is in register a, with shift count
	; in register c (to place bit back into position), and
	; target alloc position in registers hl, rotate and replace
	RRCA	
	DEC	D
	jp	nz,rotr		; back into position
	LD	(HL),A		; back to alloc
	RET	
copy$alv:	
	; If Z flag set, copy 1st ALV to 2nd
	; Otherwise, copy 2nd ALV to 1st
IF	.NOT.	BANKED
	LD	A,(bdos$flags)
	RLCA	
	RLCA	
	ret	c
ENDIF	
	PUSH	AF
	CALL	get$nalbs
	LD	B,H
	LD	C,L
	LD	HL,(alloca)
	LD	D,H
	LD	E,L
	ADD	HL,BC
	POP	AF
	jp	z,movef
	EX	DE,HL
	JP	movef
scandm$ab:	
	; Set/Reset 1st and 2nd ALV
	PUSH	BC
	CALL	scandm$a
	POP	BC
	;jmp scandm$b
scandm$b:	
	; Set/Reset 2nd ALV
IF	.NOT.	BANKED
	LD	A,(bdos$flags)
	AND	40h
	ret	nz
ENDIF	
	PUSH	BC
	CALL	get$nalbs
	EX	DE,HL
	LD	HL,(alloca)
	POP	BC
	PUSH	HL
	ADD	HL,DE
	LD	(alloca),HL
	CALL	scandm$a
	POP	HL
	LD	(alloca),HL
	RET	
scandm$a:	
	; Set/Reset 1st ALV
	; Scan the disk map addressed by dptr for non-zero
	; entries, the allocation vector entry corresponding
	; to a non-zero entry is set to the value of c (0,1)
	CALL	getdptra	; hl = buffa + dptr
	; hl addresses the beginning of the directory entry
	LD	DE,dskmap
	ADD	HL,DE		; hl now addresses the disk map
	PUSH	BC		; Save the 0/1 bit to set
	LD	C,fcblen-dskmap+1; size of single byte disk map + 1
scandm0:	
	; Loop once for each disk map entry
	POP	DE		; Recall bit parity
	DEC	C
	ret	z		; all done scanning?
	; no, get next entry for scan
	PUSH	DE		; Replace bit parity
	LD	A,(single)
	OR	A
	jp	z,scandm1
	; single byte scan operation
	PUSH	BC		; Save counter
	PUSH	HL		; Save map address
	LD	C,(HL)
	LD	B,0		; bc=block#
	JP	scandm2
scandm1:	
	; double byte scan operation
	DEC	C		; count for double byte
	PUSH	BC		; Save counter
	LD	C,(HL)
	INC	HL
	LD	B,(HL)		; bc=block#
	PUSH	HL		; Save map address
scandm2:	
	; Arrive here with bc=block#, e=0/1
	LD	A,C
	OR	B		; Skip if = 0000
	jp	z,scandm3
	LD	HL,(maxall)	; Check invalid index
	LD	A,L
	SUB	A,C
	LD	A,H
	SBC	A,B		; maxall - block#
	call	nc,set$alloc$bit
	; bit set to 0/1
scandm3:	
	POP	HL
	INC	HL		; to next bit position
	POP	BC		; Recall counter
	JP	scandm0		; for another item
get$nalbs:	; Get # of allocation vector bytes
	LD	HL,(maxall)
	LD	C,3
	; number of bytes in allocation vector is (maxall/8)+1
	CALL	hlrotr
	INC	HL
	RET	
IF	MPM	
test$dir:	
	CALL	home
	CALL	set$end$dir
test$dir1:	
	LD	C,0feh
	CALL	read$dir
	LD	A,(flushed)
	OR	A
	ret	nz
	CALL	end$of$dir
	ret	z
	JP	test$dir1
ENDIF	
initialize:	
	; Initialize the current disk
	; lret = false ; set to true if $ file exists
	; Compute the length of the allocation vector - 2
IF	MPM	
	LD	HL,(tlog)
	CALL	test$vector
	jp	z,initialize1
	LD	HL,(tlog)
	CALL	remove$drive
	LD	(tlog),HL
	XOR	A
	LD	(flushed),A
	CALL	test$dir
	ret	z
initialize1:	
ENDIF	
;
IF	.NOT.	MPM
	CALL	test$media$flag
	LD	(HL),0		; Reset media change flag
ENDIF	
;
IF	PATCH13 .AND. BANKED
	CALL	chksiz$eq$8000h
	jp	nz,new$discard 
	LD	HL,(lsn$add)
	CP	(HL)
	nop	
	nop	
	jp	z,new$discard
	JP	new$initialize2
ENDIF	
;
IF	.NOT.	MPM
new$discard:	
	CALL	discard$data
	CALL	discard$dir
ENDIF	
;
IF	PATCH13 .AND. BANKED
;___________________________________________________
ENDIF	
;
IF	BANKED .AND. .NOT. PATCH13
	; Is drive permanent with no chksum vector?
	CALL	chksiz$eq$8000h
	jp	nz,initialize2	; no
	; Is this an initial login operation?
	; register A = 0
	LD	HL,(lsn$add)
	CP	(HL)
	LD	(HL),2
	jp	z,initialize2	; yes
	JP	copy$alv	; Copy 2nd ALV to 1st ALV
initialize2:	
ENDIF	
	CALL	get$nalbs	; Get # of allocation vector bytes
	LD	B,H
	LD	C,L		; Count down bc til zero
	LD	HL,(alloca)	; base of allocation vector
	; Fill the allocation vector with zeros
initial0:	
	LD	(HL),0
	INC	HL		; alloc(i)=0
	DEC	BC		; Count length down
	LD	A,B
	OR	C
	jp	nz,initial0
	LD	HL,(drvlbla)
	LD	(HL),A		; Zero out drive desc byte
	; Set the reserved space for the directory
	LD	HL,(dirblk)
	EX	DE,HL
	LD	HL,(alloca)	; hl=.alloc()
	LD	(HL),E
	INC	HL
	LD	(HL),D		; sets reserved directory blks
	; allocation vector initialized, home disk
	CALL	home
	; cdrmax = 3 (scans at least one directory record)
	LD	HL,(cdrmaxa)
	LD	(HL),4
	INC	HL
	LD	(HL),0
	CALL	set$end$dir	; dcnt = enddir
	LD	HL,(hash$tbla)
	LD	(arecord1),HL
	; Read directory entries and check for allocated storage
initial2:	
	LD	C,true
	CALL	read$dir
IF	PATCH13 .AND. BANKED
	CALL	end$of$dir
	jp	z,new$copy$alv
ELSE	
	CALL	end$of$dir
	jp	z,copy$alv
ENDIF	
	; .NOT. end of directory, valid entry?
	CALL	getdptra	; hl = buffa + dptr
	EX	DE,HL
	LD	HL,(arecord1)
	LD	A,H
	AND	L
	INC	A
	EX	DE,HL
	; is hash$tbla ~= 0ffffh
	call	nz,init$hash	; yes - call init$hash
	LD	A,21h
	CP	(HL)
	jp	z,initial2	; Skip date & time records
	LD	A,empty
	CP	(HL)
	jp	z,initial2	; go get another item
	LD	A,20h
	CP	(HL)
	jp	z,drv$lbl
	LD	A,10h
	AND	(HL)
	jp	nz,initial3
	; Now scan the disk map for allocated blocks
	LD	C,1		; set to allocated
	CALL	scandm$a
initial3:	
	CALL	setcdr		; set cdrmax to dcnt
	JP	initial2	; for another entry
drv$lbl:	
	LD	DE,extnum
	ADD	HL,DE
	LD	A,(HL)
	LD	HL,(drvlbla)
	LD	(HL),A
	JP	initial3
copy$dir$loc:	
	; Copy directory location to lret following
	; delete, rename, ... ops
	LD	A,(dirloc)
	JP	sta$ret
	; ret
compext:	
	; Compare extent# in a with that in c, return nonzero
	; if they do .NOT. match
	PUSH	BC		; Save c's original value
	PUSH	AF
	LD	A,(extmsk)
	CPL	
	LD	B,A
	; b has negated form of extent mask
	LD	A,C
	AND	B
	LD	C,A		; low bits removed from c
	POP	AF
	AND	B		; low bits removed from a
	SUB	A,C
	AND	maxext		; Set flags
	POP	BC		; Restore original values
	RET	
get$dir$ext:	
	; Compute directory extent from fcb
	; Scan fcb disk map backwards
	CALL	getfcba		; hl = .fcb(vrecord)
	LD	C,16
	LD	B,C
	INC	C
	PUSH	BC
	; b=dskmap pos (rel to 0)
get$de0:	
	POP	BC
	DEC	C
	XOR	A		; Compare to zero
get$de1:	
	DEC	HL
	DEC	B		; Decr dskmap position
	CP	(HL)
	jp	nz,get$de2		; fcb(dskmap(b)) ~= 0
	DEC	C
	jp	nz,get$de1
	; c = 0 -> all blocks = 0 in fcb disk map
get$de2:	
	LD	A,C
	LD	(dminx),A
	LD	A,(single)
	OR	A
	LD	A,B
	jp	nz,get$de3
	RRA			; .NOT. single, divide blk idx by 2
get$de3:	
	PUSH	BC
	PUSH	HL		; Save dskmap position & count
	LD	L,A
	LD	H,0		; hl = non-zero blk idx
	; Compute ext offset from last non-zero
	; block index by shifting blk idx right
	; 7 - blkshf
	LD	A,(blkshf)
	LD	D,A
	LD	A,7
	SUB	A,D
	LD	C,A
	CALL	hlrotr
	LD	B,L
	; b = ext offset
	LD	A,(extmsk)
	CP	B
	POP	HL
	jp	c,get$de0
	; Verify computed extent offset <= extmsk
	CALL	getexta
	LD	C,(HL)
	CPL	
	AND	maxext
	AND	C
	OR	B
	; dir ext = (fcb ext & (~ extmsk) & maxext) | ext offset
	POP	BC		; Restore stack
	RET			; a = directory extent
searchi:	
	; search initialization
	LD	HL,(info)
	LD	(searcha),HL	; searcha = info
searchi1:	
	LD	A,C
	LD	(searchl),A	; searchl = c
	CALL	set$hash
	LD	A,0ffh
	LD	(dirloc),A	; changed if actually found
	RET	
search$namlen:	
	LD	C,namlen
	JP	search
search$extnum:	
	LD	C,extnum
search:	
	; Search for directory element of length c at info
	CALL	searchi
search1:	; entry point used by rename
	CALL	set$end$dir	; dcnt = enddir
	CALL	tst$log$fxs
	call	z,home
	; (drop through to searchn)
searchn:	
	; Search for the next directory element, assuming
	; a previous call on search which sets searcha and
	; searchl
IF	MPM	
	LD	HL,user0$pass
	XOR	A
	CP	(HL)
	LD	(HL),A
	call	nz,swap
ELSE	
	XOR	A
	LD	(user0$pass),A
ENDIF	
	CALL	search$hash
	jp	nz,search$fin
	LD	C,false
	CALL	read$dir	; Read next dir element
	CALL	end$of$dir
	jp	z,search$fin
	; .NOT. end of directory, scan for match
	LD	HL,(searcha)
	EX	DE,HL		; de=beginning of user fcb
	LD	A,(DE)		; first character
	CP	empty		; Keep scanning if empty
	jp	z,searchnext
	; .NOT. empty, may be end of logical directory
	PUSH	DE		; Save search address
	CALL	compcdr		; past logical end?
	POP	DE		; Recall address
	jp	nc,search$fin	; artificial stop
searchnext:	
	CALL	getdptra	; hl = buffa+dptr
	LD	A,(searchl)
	LD	C,A		; length of search to c
	LD	B,0		; b counts up, c counts down
	LD	A,(HL)
	CP	empty
	call	z,save$dcnt$pos1 
IF	BANKED
	XOR	A
	LD	(save$xfcb),A
	LD	A,(HL)
	AND	1110_1111b
	CP	(HL)
	jp	z,searchloop
	EX	DE,HL
	CP	(HL)
	EX	DE,HL
	jp	nz,searchloop
	LD	A,(find$xfcb)
	OR	A
	jp	z,searchn
	LD	(save$xfcb),A
	JP	searchok
ENDIF	
searchloop:	
	LD	A,C
	OR	A
	jp	z,endsearch
	LD	A,(DE)
	CP	'?'
	jp	z,searchok	; ? in user fcb
	; Scan next character if .NOT. ubytes
	LD	A,B
	CP	ubytes
	jp	z,searchok
	; .NOT. the ubytes field, extent field?
	CP	extnum		; may be extent field
	jp	z,searchext	; Skip to search extent
	CP	modnum
	LD	A,(DE)
	call	z,searchmod
	SUB	A,(HL)
	AND	7fh		; Mask-out flags/extent modulus
	jp	nz,searchnm	; Skip if .NOT. matched
	JP	searchok	; matched character
searchext:	
	LD	A,(DE)
	; Attempt an extent # match
	PUSH	BC		; Save counters
IF	MPM	
	PUSH	HL
	LD	HL,(sdcnt)
	INC	H
	jp	nz,dont$save
	LD	HL,(dcnt)
	LD	(sdcnt),HL
	LD	HL,(dblk)
	LD	(sdblk),HL
dont$save:	
	POP	HL
ENDIF	
	LD	C,(HL)		; directory character to c
	CALL	compext		; Compare user/dir char
	LD	B,A
	LD	A,(user0$pass)
	INC	A
	jp	z,save$dcnt$pos2
	; Disable search of user 0 if any fcb
	; is found under the current user #
	XOR	A
	LD	(search$user0),A
	LD	A,B
	POP	BC		; Recall counters
	OR	A		; Set flag
	jp	nz,searchn		; Skip if no match
searchok:	
	; current character matches
	INC	DE
	INC	HL
	INC	B
	DEC	C
	JP	searchloop
endsearch:	
	; entire name matches, return dir position
IF	BANKED
	LD	A,(save$xfcb)
	INC	A
	jp	nz,endsearch1
	LD	A,(xdcnt+1)
	CP	0feh
	call	z,save$dcnt$pos0
	JP	searchn
endsearch1:	
ENDIF	
	XOR	A
	LD	(dirloc),A	; dirloc = 0
	LD	(lret),A	; lret = 0
	; successful search -
	; return with zero flag reset
	LD	B,A
	INC	B
	RET	
searchmod:	
	AND	3fh
	RET			; Mask off high 2 bits
search$fin:	
	; end of directory, or empty name
	CALL	save$dcnt$pos1
	; Set dcnt = 0ffffh
	CALL	set$end$dir	; may be artifical end
lret$eq$ff:	
	; unsuccessful search -
	; return with zero flag set
	; lret,low(aret) = 0ffh
	LD	A,255
	LD	B,A
	INC	B
	JP	sta$ret
searchnm:	; search no match routine
	LD	A,B
	OR	A
	jp	nz,searchn		; fcb(0)?
	LD	A,(HL)
	OR	A
	jp	nz,searchn		; dir fcb(0)=0?
	LD	A,(search$user0)
	OR	A
	jp	z,searchn
	LD	(user0$pass),A
IF	MPM	
	CALL	swap
ENDIF	
	JP	searchok
IF	MPM	
swap:	; Swap dcnt,sdblk with sdcnt0,sdblk0
	PUSH	HL
	PUSH	DE
	PUSH	BC
	LD	DE,sdcnt
	LD	HL,sdcnt0
	LD	B,4
swap1:	
	LD	A,(DE)
	LD	C,A
	LD	A,(HL)
	LD	(DE),A
	LD	(HL),C
	INC	HL
	INC	DE
	DEC	B
	jp	nz,swap1
	POP	BC
	POP	DE
	POP	HL
	
	RET	
ENDIF	
save$dcnt$pos2:	
	; Save directory position of matching fcb
	; under user 0 with matching extent # & modnum = 0
	; a = 0 on entry
	OR	B
	POP	BC
	LD	BC,searchn
	PUSH	BC
	ret	nz
	INC	HL
	INC	HL
	LD	A,(HL)
	OR	A
	ret	nz
	; Call if user0$pass = 0ffh &
	;         dir fcb(extnum) = fcb(extnum)
	;         dir fcb(modnum) = 0
save$dcnt$pos0:	
	CALL	save$dcnt$pos	; Return to searchn
save$dcnt$pos1:	
	; Save directory position of first empty fcb
	; or the end of the directory
	PUSH	HL
	
	LD	HL,(xdcnt)
	INC	H
	jp	nz,save$dcnt$pos$ret; Return if h ~= 0ffh
save$dcnt$pos:	
	LD	HL,(dcnt)
	LD	(xdcnt),HL
IF	MPM	
	LD	HL,(dblk)
	LD	(xdblk),HL
ENDIF	
save$dcnt$pos$ret:	
	POP	HL
	RET	
IF	BANKED
init$xfcb$search:	
	LD	A,0ffh
init$xfcb$search1:	
	LD	(find$xfcb),A
	LD	A,0feh
	LD	(xdcnt+1),A
	RET	
does$xfcb$exist:	
	LD	A,(xdcnt+1)
	CP	0feh
	ret	z
	CALL	set$dcnt$dblk
	XOR	A
	CALL	init$xfcb$search1
	LD	HL,(searcha)
	LD	A,(HL)
	OR	10h
	LD	(HL),A
	LD	C,extnum
	CALL	searchi1
	JP	searchn 
xdcnt$eq$dcnt:	
	LD	HL,(dcnt)
	LD	(xdcnt),HL
	RET	
restore$dir$fcb:	
	CALL	set$dcnt$dblk
	LD	C,namlen
	CALL	searchi
	JP	searchn
ENDIF	
delete:	
	; Delete the currently addressed file
	CALL	get$atts
IF	BANKED
	LD	(attributes),A
	; Make search return matching fcbs and xfcbs
deletex:	
	LD	A,0feh
	CALL	init$xfcb$search1
ELSE	
	; Return with aret = 0 for XFCB only delete
	; in non-banked systems
	RLA	
	ret	c
ENDIF	
; Delete pass 1 - check r/o attributes and xfcb passwords
	CALL	search$extnum
	ret	z
delete00:	
	jp	z,delete1
IF	BANKED
	; Is addressed dir fcb an xfcb?
	CALL	getdptra
	LD	A,(HL)
	AND	10h
	jp	nz,delete01	; yes
IF	MPM	
	CALL	tst$olist	; Verify fcb .NOT. open by someone else
ENDIF	
	; Check r/o attribute if this is .NOT. an
	; xfcb only delete operation.
	LD	A,(attributes)
	RLA	
	call	nc,check$rodir
ELSE	
	CALL	check$rodir
ENDIF	
IF	BANKED
	; Are xfcb passwords enabled?
	CALL	get$dir$mode
	RLA	
	jp	c,delete02	; no
ENDIF	
	; Is this a wild card delete operation?
	LD	HL,(info)
	CALL	chk$wild
	jp	z,delete02	; yes
	; .NOT. wild & passwords inactive
	; Skip to pass 2
	JP	delete11
IF	BANKED
delete01:	
	; Check xfcb password if passwords enabled
	CALL	get$dir$mode
	RLA	
	jp	nc,delete02
	CALL	chk$xfcb$password
	jp	z,delete02
	CALL	chk$pw$error
	JP	deletex
ENDIF	
delete02:	
	CALL	searchn
	JP	delete00
; Delete pass 2 - delete all matching fcbs and/or xfcbs.
delete1:	
	CALL	search$extnum
delete10:	
	jp	z,copy$dir$loc
delete11:	
	CALL	getdptra
IF	BANKED
	; Is addressed dir fcb an xfcb?
	LD	A,(HL)
	AND	10h
	jp	nz,delete12	; yes
IF	MPM	
	PUSH	HL
	CALL	chk$olist	; Delete olist item if present
	POP	HL
ENDIF	
	; Is this delete operation xfcb only?
	LD	A,(attributes)
	AND	80h
	jp	nz,delete13	; yes
ENDIF	
delete12:	
	; Delete dir fcb or xfcb
	; if fcb free all alocated blocks.
	LD	(HL),empty
IF	BANKED
delete13:	
	PUSH	AF		; Z flag set => free FCB blocks
	; Zero password mode byte in sfcb if sfcb exists
	; Does sfcb exist?
	CALL	get$dtba$8
	OR	A
	jp	nz,$+4		; no
	; Zero mode byte
	LD	(HL),A
ENDIF	
	CALL	wrdir
	LD	C,0
IF	BANKED
	POP	AF
	call	z,scandm$ab
ELSE	
	CALL	scandm$ab
ENDIF	
	CALL	fix$hash
	CALL	searchn
	JP	delete10
get$block:	
	; Given allocation vector position bc, find the zero bit
	; closest to this position by searching left and right.
	; if found, set the bit to one and return the bit position
	; in hl.  if .NOT. found (i.e., we pass 0 on the left, or
	; maxall on the right), return 0000 in hl
	LD	D,B
	LD	E,C		; copy of starting position to de
righttst:	
	LD	HL,(maxall)	; value of maximum allocation#
	LD	A,E
	SUB	A,L
	LD	A,D
	SBC	A,H		; right=maxall?
	jp	nc,retblock0	; return block 0000 if so
	INC	DE
	PUSH	BC
	PUSH	DE		; left, right pushed
	LD	B,D
	LD	C,E		; ready right for call
	CALL	getallocbit
	RRA	
	jp	nc,retblock	; Return block number if zero
	POP	DE
	POP	BC		; Restore left and right pointers
lefttst:	
	LD	A,C
	OR	B
	jp	z,righttst	; Skip if left=0000
	; left .NOT. at position zero, bit zero?
	DEC	BC
	PUSH	DE
	PUSH	BC		; left,right pushed
	CALL	getallocbit
	RRA	
	jp	nc,retblock	; return block number if zero
	; bit is one, so try the right
	POP	BC
	POP	DE		; left, right restored
	JP	righttst
retblock:	
	RLA	
	INC	A		; bit back into position and set to 1
	; d contains the number of shifts required to reposition
	CALL	rotr		; move bit back to position and store
	POP	HL
	POP	DE		; hl returned value, de discarded
	RET	
retblock0:	
	; cannot find an available bit, return 0000
	LD	A,C
	OR	B
	jp	nz,lefttst		; also at beginning    
	LD	HL,0000h
	RET	
copy$dir:	
	; Copy fcb information starting at c for e bytes
	; into the currently addressed directory entry
	LD	D,80h
copy$dir0:	
	CALL	copy$dir2
	INC	C
copy$dir1:	
	DEC	C
	jp	z,seek$copy
	LD	A,(HL)
	AND	B
	PUSH	BC
	LD	B,A
	LD	A,(DE)
	AND	7fh
	OR	B
	LD	(HL),A
	POP	BC
	INC	HL
	INC	DE
	JP	copy$dir1
copy$dir2:	
	PUSH	DE		; Save length for later
	LD	B,0		; double index to bc
	LD	HL,(info)	; hl = source for data
	ADD	HL,BC
	INC	HL
	LD	A,(HL)
	SUB	A,'$'
	call	z,set$submit$flag
	DEC	HL
	EX	DE,HL		; de=.fcb(c), source for copy
	CALL	getdptra	; hl=.buff(dptr), destination
	POP	BC		; de=source, hl=dest, c=length
	RET	
set$submit$flag:	
	LD	DE,ccp$flgs
	LD	A,(DE)
	OR	1
	LD	(DE),A
	RET	
check$wild:	
	; Check for ? in file name or type
	LD	HL,(info)
check$wild0:	; entry point used by rename
	CALL	chk$wild
	ret	nz
	LD	A,9
	JP	set$aret
chk$wild:	
	LD	C,11
chk$wild1:	
	INC	HL
	LD	A,3fh
	SUB	A,(HL)
	AND	7fh
	ret	z
	DEC	C
	jp	nz,chk$wild1
	OR	A
	RET	
copy$user$no:	
	LD	HL,(info)
	LD	A,(HL)
	LD	BC,dskmap
	ADD	HL,BC
	LD	(HL),A
	RET	
rename:	
	; Rename the file described by the first half of
	; the currently addressed file control block. The
	; new name is contained in the last half of the
	; currently addressed file control block.  The file
	; name and type are changed, but the reel number
	; is ignored.  The user number is identical.
	; Verify that the new file name does .NOT. exist.
	; Also verify that no wild chars exist in
	; either filename.
IF	MPM	
	CALL	getatts
	LD	(attributes),A
ENDIF	
	; Verify that no wild chars exist in 1st filename.
	CALL	check$wild
IF	BANKED
	; Check password of file to be renamed.
	CALL	chk$password
	call	nz,chk$pw$error
	; Setup search to scan for xfcbs.
	CALL	init$xfcb$search
ENDIF	
	; Copy user number to 2nd filename
	CALL	copy$user$no
	LD	(searcha),HL
	; Verify no wild chars exist in 2nd filename
	CALL	check$wild0
	; Verify new filename does .NOT. already exist
	LD	C,extnum
	LD	HL,(searcha)
	CALL	searchi1
	CALL	search1
	jp	nz,file$exists	; New filename exists
IF	BANKED
	; If an xfcb exists for the new filename, delete it.
	CALL	does$xfcb$exist
	call	nz,delete11
ENDIF	
	CALL	copy$user$no
IF	BANKED
	CALL	init$xfcb$search
ENDIF	
	; Search up to the extent field
	CALL	search$extnum
	ret	z
	CALL	check$rodir	; may be r/o file
IF	MPM	
	CALL	chk$olist
ENDIF	
	; Copy position 0
rename0:	
	; .NOT. end of directory, rename next element
	LD	C,dskmap
	LD	E,extnum
	CALL	copy$dir
	; element renamed, move to next
	CALL	fix$hash
	CALL	searchn
	jp	nz,rename0
rename1:	
IF	BANKED
	CALL	does$xfcb$exist
	jp	z,copy$dir$loc
	CALL	copy$user$no
	JP	rename0
ELSE	
	JP	copy$dir$loc
ENDIF	
indicators:	
	; Set file indicators for current fcb
	CALL	get$atts	; Clear f5' through f8'
	LD	(attributes),A
IF	BANKED
	CALL	chk$password
	call	nz,chk$pw$error
ENDIF	
	CALL	search$extnum	; through file type
	ret	z
IF	MPM	
	CALL	chk$olist
ENDIF	
indic0:	
	; .NOT. end of directory, continue to change
	LD	C,0
	LD	E,extnum	; Copy name
	CALL	copy$dir2
	CALL	move
	LD	A,(attributes)
	AND	40h
	jp	z,indic1
	; If interface att f6' set, dir fcb(s1) = fcb(cr)
	PUSH	HL
	CALL	getfcba
	LD	A,(HL)
	POP	HL
	INC	HL
	LD	(HL),A
indic1:	
	CALL	seek$copy
	CALL	searchn
	jp	z,copy$dir$loc
	JP	indic0
open:	
	; Search for the directory entry, copy to fcb
IF	PATCH13
	CALL	new$setfwf
ELSE	
	CALL	search$namlen
ENDIF	
open1:	
	ret	z		; Return with lret=255 if end
	; .NOT. end of directory, copy fcb information
open$copy:	
	CALL	setfwf
	LD	E,A
	PUSH	HL
	DEC	HL
	DEC	HL
	LD	D,(HL)
	PUSH	DE		; Save extent# & module# with fcb write flag set
	CALL	getdptra
	EX	DE,HL		; hl = .buff(dptr)
	LD	HL,(info)	; hl=.fcb(0)
	LD	C,nxtrec	; length of move operation
	CALL	move		; from .buff(dptr) to .fcb(0)
	; Note that entire fcb is copied, including indicators
	CALL	get$dir$ext
	LD	C,A
	; Restore module # and extent #
	POP	DE
	POP	HL
	LD	(HL),E
	DEC	HL
	DEC	HL
	LD	(HL),D
	; hl = .user extent#, c = dir extent#
	; above move set fcb(reccnt) to dir(reccnt)
	; if fcb ext < dir ext then fcb(reccnt) = fcb(reccnt) | 128
	; if fcb ext = dir ext then fcb(reccnt) = fcb(reccnt)
	; if fcb ext > dir ext then fcb(reccnt) = 0
set$rc:	; hl=.fcb(ext), c=dirext
	LD	B,0
	EX	DE,HL
	LD	HL,reccnt-extnum
	ADD	HL,DE
	; Is fcb ext = dirext?
	LD	A,(DE)
	SUB	A,C
	jp	z,set$rc2		; yes
	; Is fcb ext > dirext?
	LD	A,B
	jp	nc,set$rc1		; yes - fcb(rc) = 0
	; fcb ext  < dirext
	; fcb(rc) = 128 | fcb(rc)
	LD	A,128
	OR	(HL)
set$rc1:	
	LD	(HL),A
	RET	
set$rc2:	
	; fcb ext = dirext
	LD	A,(HL)
	OR	A
	ret	nz		; ret if fcb(rc) ~= 0
set$rc3:	
	LD	(HL),0		; required by function 99
	LD	A,(dminx)
	OR	A
	ret	z		; ret if no blks in fcb
	LD	(HL),128
	RET			; fcb(rc) = 128
mergezero:	
	; hl = .fcb1(i), de = .fcb2(i),
	; if fcb1(i) = 0 then fcb1(i) := fcb2(i)
	LD	A,(HL)
	INC	HL
	OR	(HL)
	DEC	HL
	ret	nz		; return if = 0000
	LD	A,(DE)
	LD	(HL),A
	INC	DE
	INC	HL		; low byte copied
	LD	A,(DE)
	LD	(HL),A
	DEC	DE
	DEC	HL		; back to input form
	RET	
restore$rc:	
	; hl = .fcb(extnum)
	; if fcb(rc) > 80h then fcb(rc) = fcb(rc) & 7fh
	PUSH	HL
	LD	DE,reccnt-extnum
	ADD	HL,DE
	LD	A,(HL)
	CP	81h
	jp	c,restore$rc1
	AND	7fh
	LD	(HL),A
restore$rc1:	
	POP	HL
	RET	
close:	
	; Locate the directory element and re-write it
	XOR	A
	LD	(lret),A
IF	MPM	
	LD	(dont$close),A
ENDIF	
	CALL	nowrite
	ret	nz		; Skip close if r/o disk
	; Check file write flag - 0 indicates written
	CALL	getmodnum	; fcb(modnum) in a
	AND	fwfmsk
	ret	nz		; Return if bit remains set
close1:	
	CALL	chk$inv$fcb
	jp	z,mergerr
IF	MPM	
	CALL	set$fcb$cks$flag
ENDIF	
IF	PATCH7 .AND. .NOT. BANKED
	CALL	new$dir$ext
	LD	C,A
ENDIF	
IF	UNDOC	.AND. BANKED
	CALL	undoc1
	LD	C,A
ENDIF	
IF	.NOT.	PATCH7 .AND. .NOT. BANKED .or. .NOT. UNDOC .and. BANKED 
	CALL	get$dir$ext
	LD	C,A
ENDIF	
	LD	B,(HL)
	PUSH	BC
	; b = original extent, c = directory extent
	; Set fcb(ex) to directory extent
	LD	(HL),C
	; Recompute fcb(rc)
	CALL	restore$rc
	; Call set$rc if fcb ext > dir ext
	LD	A,C
	CP	B
	call	c,set$rc
	CALL	close$fcb
	; Restore original extent & reset fcb(rc)
	CALL	getexta
	POP	BC
	LD	C,(HL)
	LD	(HL),B
	JP	set$rc	; Reset fcb(rc)
close$fcb:	
	; Locate file
	CALL	search$namlen
	ret	z		; Return if .NOT. found
	; Merge the disk map at info with that at buff(dptr)
	LD	BC,dskmap
	CALL	get$fcb$adds
	LD	C,fcblen-dskmap; length of single byte dm
merge0:	
	LD	A,(single)
	OR	A
	jp	z,merged		; Skip to double
	; This is a single byte map
	; if fcb(i) = 0 then fcb(i) = buff(i)
	; if buff(i) = 0 then buff(i) = fcb(i)
	; if fcb(i) <> buff(i) then error
	LD	A,(HL)
	OR	A
	LD	A,(DE)
	jp	nz,fcbnzero
	; fcb(i) = 0
	LD	(HL),A		; fcb(i) = buff(i)
fcbnzero:	
	OR	A
	jp	nz,buffnzero
	; buff(i) = 0
	LD	A,(HL)
	LD	(DE),A		; buff(i)=fcb(i)
buffnzero:	
	CP	(HL)
	jp	nz,mergerr		; fcb(i) = buff(i)?
	JP	dmset		; if merge ok
merged:	
	; This is a double byte merge operation
	CALL	mergezero	; buff = fcb if buff 0000
	EX	DE,HL
	CALL	mergezero
	EX	DE,HL		; fcb = buff if fcb 0000
	; They should be identical at this point
	LD	A,(DE)
	CP	(HL)
	jp	nz,mergerr		; low same?
	INC	DE
	INC	HL		; to high byte
	LD	A,(DE)
	CP	(HL)
	jp	nz,mergerr		; high same?
	; merge operation ok for this pair
	DEC	C		; extra count for double byte
dmset:	
	INC	DE
	INC	HL		; to next byte position
	DEC	C
	jp	nz,merge0		; for more
	; end of disk map merge, check record count
	; de = .buff(dptr)+32, hl = .fcb(32)
	EX	DE,HL
fcbdelta	equ	fcblen-extnum
	LD	BC,-fcbdelta	; should be 0FFECh
	ADD	HL,BC
	PUSH	HL
	CALL	get$dir$ext
	POP	DE
	; hl = .fcb(extnum), de = .buff(dptr+extnum)
	CALL	compare$extents
	; b=1 -> fcb(ext) ~= dir ext = buff(ext)
	; b=2 -> fcb(ext) = dir ext ~= buff(ext)
	; b=3 -> fcb(ext) = dir ext = buff(ext)
	; fcb(ext), buff(ext) = dir ext
	LD	(HL),A
	LD	(DE),A
	PUSH	BC
	LD	BC,reccnt-extnum
	ADD	HL,BC
	EX	DE,HL
	ADD	HL,BC
	POP	BC
	; hl = .buff(rc) , de = .fcb(rc)
	DEC	B
	jp	z,mrg$rc1		; fcb(rc) = buff(rc)
	DEC	B
	jp	z,mrg$rc2		; buff(rc) = fcb(rc)
	LD	A,(DE)
	CP	(HL)
	jp	c,mrg$rc1		; Take larger rc
	OR	A
	jp	nz,mrg$rc2
	CALL	set$rc3
mrg$rc1:	EX	DE,HL
mrg$rc2:	LD	A,(DE)
	LD	(HL),A
IF	MPM	
	LD	A,(dont$close)
	OR	A
	ret	nz
ENDIF	
	; Set t3' off indicating file update
	CALL	getdptra
	LD	DE,11
	ADD	HL,DE
	LD	A,(HL)
	AND	7fh
	LD	(HL),A
	CALL	setfwf
	LD	C,1
	CALL	scandm$b	; Set 2nd ALV vector
	JP	seek$copy	; OK to "wrdir" here - 1.4 compat
	; ret
mergerr:	
	; elements did .NOT. merge correctly
	CALL	make$fcb$inv
	JP	lret$eq$ff
compare$extents:	
	LD	B,1
	CP	(HL)
	ret	nz
	INC	B
	EX	DE,HL
	CP	(HL)
	EX	DE,HL
	ret	nz
	INC	B
	RET	
set$xdcnt:	
	LD	HL,0ffffh
	LD	(xdcnt),HL
	RET	
set$dcnt$dblk:	
	LD	HL,(xdcnt)
set$dcnt$dblk1:	
	LD	A,1111_1100b
	AND	L
	LD	L,A
	DEC	HL
	LD	(dcnt),HL
IF	MPM	
	LD	HL,(xdblk)
	LD	(dblk),HL
ENDIF	
	RET	
IF	MPM	
sdcnt$eq$xdcnt:	
	LD	HL,sdcnt
	LD	DE,xdcnt
	LD	C,4
	JP	move
ENDIF	
make:	
	; Create a new file by creating a directory entry
	; then opening the file
IF	PATCH13
	CALL	new$xdcnt
	CALL	test$ffff
	call	nz,set$dcnt$dblk
ELSE	
	LD	HL,xdcnt
	CALL	test$ffff
	call	nz,set$dcnt$dblk
ENDIF	
	LD	HL,(info)
	PUSH	HL		; Save fcb address, Look for E5
	LD	HL,efcb
	LD	(info),HL	; info = .empty
	LD	C,1
	CALL	searchi
	CALL	searchn
	; zero flag set if no space
	POP	HL		; Recall info address
	LD	(info),HL	; in case we return here
	ret	z		; Return with error condition 255 if .NOT. found
IF	BANKED
	; Return early if making an xfcb
	LD	A,(make$xfcb)
	OR	A
	ret	nz
ENDIF	
	; Clear the remainder of the fcb
	; Clear s1 byte
	LD	DE,13
	ADD	HL,DE
	LD	(HL),D
	INC	HL
	; Clear and save file write flag of modnum
	LD	A,(HL)
	PUSH	AF
	PUSH	HL
	AND	3fh
	LD	(HL),A
	INC	HL
	LD	A,1
	LD	C,fcblen-namlen	; number of bytes to fill
make0:	
	LD	(HL),D
	INC	HL
	DEC	C
	jp	nz,make0
	DEC	A
	LD	C,D
	call	z,get$dtba
	OR	A
	LD	C,10
	jp	z,make0
	CALL	setcdr		; may have extended the directory
	; Now copy entry to the directory
	LD	C,0
	LD	DE,fcblen
	CALL	copy$dir0
	; and restore the file write flag
	POP	HL
	POP	AF
	LD	(HL),A
	; and set the fcb write flag to "1"
	CALL	fix$hash
	JP	setfwf
open$reel:	
	; Close the current extent, and open the next one
	; if possible.  rmf is true if in read mode
IF	BANKED
	CALL	reset$copy$cr$only
ENDIF	
	CALL	getexta
	LD	A,(HL)
	LD	C,A
	INC	C
	CALL	compext
	jp	z,open$reel3
	PUSH	HL
	PUSH	BC
	CALL	close
	POP	BC
	POP	HL
	LD	A,(lret)
	INC	A
	ret	z
	LD	A,maxext
	AND	C
	LD	(HL),A		; Incr extent field
	; Advance to module & save
	INC	HL
	INC	HL
	LD	A,(HL)
	LD	(save$mod),A
	jp	nz,open$reel0	; Jump if in same module
open$mod:	
	; Extent number overflow, go to next module
	INC	(HL)		; fcb(modnum)=++1
	; Module number incremented, check for overflow
	LD	A,(HL)
	AND	3fh		; Mask high order bits
	jp	z,open$r$err	; cannot overflow to zero
	; otherwise, ok to continue with new module
open$reel0:	
	CALL	set$xdcnt	; Reset xdcnt for make
IF	MPM	
	CALL	set$sdcnt
ENDIF	
IF	PATCH13
	CALL	new$setfwf	; Next extent found_
ELSE	
	CALL	search$namlen	; Next extent found_
ENDIF	
	jp	nz,open$reel1
	; end of file encountered
	LD	A,(rmf)
	INC	A		; 0ffh becomes 00 if read
	jp	z,open$r$err	; sets lret = 1
	; Try to extend the current file
	CALL	make
	; cannot be end of directory
	jp	z,open$r$err	; with lret = 1
IF	MPM	
	CALL	fix$olist$item
	CALL	set$fcb$cks$flag
ENDIF	
	JP	open$reel2
open$reel1:	
	; .NOT. end of file, open
	CALL	open$copy
	
IF	MPM	
	CALL	set$fcb$cks$flag
ENDIF	
open$reel2:	
IF	.NOT.	MPM
	CALL	set$lsn
ENDIF	
	CALL	getfcb		; Set parameters
	XOR	A
	LD	(vrecord),A
	JP	sta$ret		; lret = 0
	; ret ; with lret = 0
open$r$err:	
	; Restore module and extent
	CALL	getmodnum
	LD	A,(save$mod)
	LD	(HL),A
	DEC	HL
	DEC	HL
	LD	A,(HL)
	DEC	A
	AND	1fh
	LD	(HL),A
	JP	setlret1	; lret = 1
open$reel3:	
	INC	(HL)		; fcb(ex) = fcb(ex) + 1
	CALL	get$dir$ext
	LD	C,A
	; Is new extent beyond dir$ext?
	CP	(HL)
	jp	nc,open$reel4	; no
	DEC	(HL)		; fcb(ex) = fcb(ex) - 1
	; Is this a read fx?
	LD	A,(rmf)
	INC	A
	jp	z,setlret1	; yes - Don't advance ext
	INC	(HL)		; fcb(ex) = fcb(ex) + 1
open$reel4:	
	CALL	restore$rc
	CALL	set$rc
	JP	open$reel2
seqdiskread:	
diskread:	; (may enter from seqdiskread)
	CALL	tst$inv$fcb	; Check for valid fcb
	LD	A,true
	LD	(rmf),A		; read mode flag = true (open$reel)
IF	MPM	
	LD	(dont$close),A
ENDIF	
	; Read the next record from the current fcb
	CALL	getfcb		; sets parameters for the read
diskread0:	
	LD	A,(vrecord)
	LD	HL,rcount
	CP	(HL)		; vrecord-rcount
	; Skip if rcount > vrecord
	jp	c,recordok
IF	MPM	
	CALL	test$disk$fcb
	jp	nz,diskread0
	LD	A,(vrecord)
ENDIF	
	; .NOT. enough records in the extent
	; record count must be 128 to continue
	CP	128		; vrecord = 128?
	jp	nz,setlret1	; Skip if vrecord<>128
	CALL	open$reel	; Go to next extent if so
	; Check for open ok
	LD	A,(lret)
	OR	A
	jp	nz,setlret1	; Stop at eof
recordok:	
	; Arrive with fcb addressing a record to read
IF	BANKED
	CALL	set$copy$cr$only
ENDIF	
	CALL	index		; Z flag set if arecord = 0
IF	MPM	
	jp	nz,recordok1
	CALL	test$disk$fcb
	jp	nz,diskread0
ENDIF	
	jp	z,setlret1	; Reading unwritten data
recordok1:	
	; Record has been allocated, read it
	CALL	atran		; arecord now a disk address
	CALL	check$nprs
	jp	c,setfcb
	jp	nz,read$deblock
	CALL	setdata
	CALL	seek		; to proper track,sector
IF	BANKED
	LD	A,1
	CALL	setbnkf
ENDIF	
	CALL	rdbuff		; to dma address
	JP	setfcb		; Replace parameter	
read$deblock:	
	LD	HL,0
	LD	(last$block),HL
	LD	A,1
	CALL	deblock$dta
	JP	setfcb
check$nprs:	
	;
	; on exit,  c flg          -> no i/o operation
	;	    z flg & ~c flg -> direct(physical) i/o operation
	;	   ~z flg & ~c flg -> indirect(deblock) i/o operation
	;
	;          Dir$cnt contains the number of 128 byte records
	;	   to transfer directly.  This routine sets dir$cnt
	;	   when initiating a sequence of direct physical
	;	   i/o operations.  Dir$cnt is decremented each
	;	   time check$nprs is called during such a sequence.
	;
	; Is direct transfer operation in progress?
	LD	A,(blk$off)
	LD	B,A
	LD	A,(phymsk)
	LD	C,A
	AND	B
	PUSH	AF
	LD	A,(dir$cnt)
	CP	2
	jp	c,check$npr1	; no
	; yes - Decrement direct record count
	DEC	A
	LD	(dir$cnt),A
	; Are we at a new physical record?
	POP	AF
	SCF	
	ret	nz		; no - ret with c flg set
	; Perform physical i/o operation
	XOR	A
	RET			; Return with z flag set and c flag reset
check$npr1:	
	; Are we in mid-physical record?
	POP	AF
	jp	z,check$npr11	; no
check$npr1a:	
	; Is phymsk = 0?
	LD	A,C
	OR	A
	ret	z		; yes - Don't deblock
check$npr1b:	
	; Deblocking required
	OR	1
	RET			; ret with z flg reset and c flg reset
check$npr11:	
	LD	A,C
	CPL	
	LD	D,A		; d = ~phymsk
	LD	HL,vrecord
	; Is mult$num < 2?
	LD	A,(mult$num)
	CP	2
	jp	c,check$npr1a	; yes
	ADD	A,(HL)
	CP	80h
	jp	c,check$npr2
	LD	A,80h
check$npr2:	; a = min(vrecord + mult$num),80h) = x
	PUSH	BC		; Save low(arecord) & blkmsk, phymsk
	LD	B,(HL)
	LD	(HL),7fh	; vrecord = 7f
	PUSH	BC		; Save vrecord
	PUSH	HL		; Save .vrecord
	PUSH	AF		; Save x
	LD	A,(blkmsk)
	LD	E,A
	INC	E
	CPL	
	AND	B
	LD	B,A
	; b = vrecord & ~blkmsk
	; e = blkmsk + 1
	POP	HL		; h = x
	; Is this a read function?
	LD	A,(rmf)
	OR	A
	jp	z,check$npr21	; no
	; Is rcount & ~phymsk < x?
	LD	A,(rcount)
	AND	D
	CP	H
	jp	c,check$npr23	; yes
check$npr21:	
	LD	A,H		; a = x
check$npr23:	
	SUB	A,B		; a = a - vrecord & ~blkmsk
	LD	C,A		; c = max # of records from beginning of curr blk
	; Is c < blkmsk+1?
	CP	E
	jp	c,check$npr8	; yes
IF	BANKED
	PUSH	BC		; c = max # of records
	; Compute maximum disk map position
	CALL	dm$position
	LD	B,A		; b = index of last block in extent
	; Does the last block # = the current block #?
	LD	A,(dminx)
	CP	B
	LD	E,A
	jp	z,check$npr5	; yes
	; Compute # of blocks in sequence
	LD	C,A
	PUSH	BC
	LD	B,0
	CALL	getdm		; hl = current block #
check$npr4:	
	; Get next block #
	PUSH	HL
	INC	BC
	CALL	getdm
	POP	DE
	INC	DE
	; Does next block # = previous block # + 1?
	LD	A,D
	SUB	A,H
	LD	D,A
	LD	A,E
	SUB	A,L
	OR	D
	jp	z,check$npr4	; yes
	; Is next block # = 0?
	LD	A,H
	OR	L
	jp	nz,check$npr45	; no
	; Is this a read function?
	LD	A,(rmf)
	OR	A
	jp	nz,check$npr45	; no
	; Is next block # > maxall?
	LD	HL,(maxall)
	LD	A,L
	SUB	A,E
	LD	A,H
	SBC	A,D
	jp	c,check$npr45	; yes
	; Is next block # allocated?
	PUSH	BC
	PUSH	DE
	LD	B,D
	LD	C,E
	CALL	getallocbit
	POP	HL
	POP	BC
	RRA	
	jp	nc,check$npr4	; no - it will be later
check$npr45:	
	DEC	C
	POP	DE
	; Is max dm position less than c?
	LD	A,D
	CP	C
	jp	c,check$npr5	; yes
	LD	A,C		; no
check$npr5:	; a = index of last block
	SUB	A,E
	LD	B,A
	INC	B		; b = # of consecutive blks
	LD	A,(blkmsk)
	INC	A
	LD	C,A
check$npr6:	
	DEC	B
	jp	z,check$npr7
	ADD	A,C
	JP	check$npr6
check$npr7:	
	POP	BC
	LD	B,C		; b = max # of records
	LD	C,A		; c = (# of consecutive blks)*(blkmsk+1)
	LD	A,(rmf)
	OR	A
	jp	z,check$npr8
	LD	A,B
	CP	C
	jp	c,check$npr9
ELSE	
	LD	C,E		; multis-sector max = 1 block in non-banked systems
ENDIF	
check$npr8:	
	LD	A,C
check$npr9:	
	; Restore vrecord
	POP	HL
	POP	BC
	LD	(HL),B
	POP	BC
	; a = max # of consecutive records including current blk
	; b = low(arecord) & blkmsk
	; c = phymsk
	; Is mult$num > a - b
	LD	HL,mult$num
	LD	D,(HL)
	SUB	A,B
	CP	D
	jp	nc,check$npr10
	LD	D,A		; yes - use smaller value to compute dir$cnt
check$npr10:	
	; Does this operation involve at least 1 physical record?
	LD	A,C
	CPL	
	AND	D
	LD	(dir$cnt),A
	jp	z,check$npr1b	; Deblocking required
	; Flush any pending buffers before doing multiple reads
	PUSH	AF
	LD	A,(rmf)
	OR	A
	jp	z,check$npr10a
	CALL	flushx
	CALL	setdata
check$npr10a:	
	POP	AF
	LD	H,A		; Save # of 128 byte records
	; Does this operation involve more than 1 physical record?
	; Register h contains number of 128 byte records
	CALL	shr$physhf
	LD	A,H
	CP	1
	LD	C,A
	call	nz,multiof	; yes - Make bios call
	XOR	A
	RET			; Return with z flg set 
IF	MPM	
test$unlocked:	
	LD	A,(high$ext)
	AND	80h
	RET	
test$disk$fcb:	
	CALL	test$unlocked
	ret	z
	LD	A,(dont$close)
	OR	A
	ret	z
	CALL	close1
test$disk$fcb1:	
	POP	DE
	LD	HL,lret
	INC	(HL)
	LD	A,11
	jp	z,sta$ret
	LD	(HL),0
	PUSH	DE
	CALL	getrcnta
	LD	A,(HL)
	LD	(rcount),A	; Reset rcount
	XOR	A
	LD	(dont$close),A
	INC	A
	RET	
ENDIF	
reset$fwf:	
	CALL	getmodnum	; hl=.fcb(modnum), a=fcb(modnum)
	; Reset the file write flag to mark as written fcb
	AND	(.NOT. fwfmsk) .and. 0ffh; bit reset
	LD	(HL),A		; fcb(modnum) = fcb(modnum) and 7fh
	RET	
set$filewf:	
	CALL	getmodnum
	AND	0100_0000b
	PUSH	AF
	LD	A,(HL)
	OR	0100_0000b
	LD	(HL),A
	POP	AF
	RET	
seqdiskwrite:	
diskwrite:	; (may enter here from seqdiskwrite above)
	LD	A,false
	LD	(rmf),A		; read mode flag
	; Write record to currently selected file
	CALL	check$write	; in case write protected
IF	BANKED
	LD	A,(xfcb$read$only)
	OR	A
	LD	A,3
	jp	nz,set$aret
ENDIF	
	LD	A,(high$ext)
IF	MPM	
	AND	0100_0000b
ELSE	
	OR	A
ENDIF	
	; Z flag reset if r/o mode
	LD	A,3
	jp	nz,set$aret
	LD	HL,(info)	; hl = .fcb(0)
	CALL	check$rofile	; may be a read-only file
	CALL	tst$inv$fcb	; Test for invalid fcb
	CALL	update$stamp
	CALL	getfcb		; to set local parameters
	LD	A,(vrecord)
	CP	lstrec+1	; vrecord-128
	jp	c,disk$write0
	CALL	open$reel	; vrecord = 128, try to open next extent
	LD	A,(lret)
	OR	A
	ret	nz		; no available fcb
disk$write0:	
IF	MPM	
	LD	A,0ffh
	LD	(dont$close),A
disk$write1:	
ENDIF	
	; Can write the next record, so continue
	CALL	index		; Z flag set if arecord = 0
	jp	z,diskwrite2
	; Was the last write operation for the same block & drive?
	LD	HL,adrive
	LD	DE,last$drive
	LD	C,3
	CALL	compare
	jp	z,diskwrite15	; yes
	; no - force preread in blocking/deblocking
	LD	A,0ffh
	LD	(last$off),A
diskwrite15:	
IF	MPM	
	; If file is unlocked, verify record is .NOT. locked
	; Record has to be allocated to be locked
	CALL	test$unlocked
	jp	z,.NOT.$unlocked
	CALL	atran
	LD	C,A
	LD	A,(mult$cnt)
	LD	B,A
	PUSH	BC
	CALL	test$lock
	POP	BC
	XOR	A
	LD	C,A
	PUSH	BC
	JP	diskwr10
.NOT.$unlocked:	
	INC	A
ENDIF	
	LD	C,0		; Marked as normal write operation for wrbuff
	JP	diskwr1
diskwrite2:	
IF	MPM	
	CALL	test$disk$fcb
	jp	nz,diskwrite1
ENDIF	
IF	BANKED
	CALL	reset$copy$cr$only
ENDIF	
	; .NOT. allocated
	; The argument to getblock is the starting
	; position for the disk search, and should be
	; the last allocated block for this file, or
	; the value 0 if no space has been allocated
	CALL	dm$position
	LD	(dminx),A	; Save for later
	LD	BC,0000h	; May use block zero
	OR	A
	jp	z,nopblock	; Skip if no previous block
	; Previous block exists at a
	LD	C,A
	DEC	BC		; Previous block # in bc
	CALL	getdm		; Previous block # to hl
	LD	B,H
	LD	C,L		; bc=prev block#
nopblock:	
	; bc = 0000, or previous block #
	CALL	get$block	; block # to hl
	; Arrive here with block# or zero
	LD	A,L
	OR	H
	jp	nz,blockok
	; Cannot find a block to allocate
	LD	A,2
	JP	sta$ret		; lret=2	
blockok:	
IF	MPM	
	CALL	set$fcb$cks$flag
ENDIF	
	; allocated block number is in hl
	LD	(arecord),HL
	LD	(last$block),HL
	XOR	A
	LD	(last$off),A
	LD	A,(adrive)
	LD	(last$drive),A
	EX	DE,HL		; block number to de
	LD	HL,(info)
	LD	BC,dskmap
	ADD	HL,BC		; hl=.fcb(dskmap)
	LD	A,(single)
	OR	A		; Set flags for single byte dm
	LD	A,(dminx)	; Recall dm index
	jp	z,allocwd		; Skip if allocating word
	; Allocating a byte value
	CALL	_addh
	LD	(HL),E		; single byte alloc
	JP	diskwru		; to continue
allocwd:	
	; Allocate a word value
	LD	C,A
	LD	B,0		; double(dminx)
	ADD	HL,BC
	ADD	HL,BC		; hl=.fcb(dminx*2)
	LD	(HL),E
	INC	HL
	LD	(HL),D		; double wd
diskwru:	
	; disk write to previously unallocated block
	LD	C,2		; marked as unallocated write
diskwr1:	
	; Continue the write operation of no allocation error
	; c = 0 if normal write, 2 if to prev unalloc block
	PUSH	BC		; Save write flag
	CALL	atran		; arecord set
diskwr10:	
	LD	A,(fx)
	CP	40
	jp	nz,diskwr11	; fx ~= wrt rndm zero fill
	LD	A,C
	DEC	A
	DEC	A
	jp	nz,diskwr11	; old allocation  
	; write random zero fill + new block
	POP	BC
	PUSH	AF		; zero write flag
	LD	HL,(arecord)
	PUSH	HL
	LD	HL,phymsk
	LD	E,(HL)
	INC	E
	LD	D,A
	PUSH	DE
	LD	HL,(dirbcba)
IF	BANKED
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
fill00:	
	PUSH	HL
	CALL	get$next$bcba
	POP	DE
	jp	nz,fill00
	EX	DE,HL
ENDIF	
	; Force prereads in blocking/deblocking
	; Discard BCB
	DEC	A
	LD	(last$off),A
	LD	(HL),A 
	CALL	setdir1		; Set dma to BCB buffer
	; Zero out BCB buffer
	POP	DE
	PUSH	DE
	XOR	A
fill0:	
	LD	(HL),A
	INC	HL
	INC	D
	jp	p,fill0
	LD	D,A
	DEC	E
	jp	nz,fill0
	; Write 1st physical record of block
	LD	HL,(arecord1)
	LD	C,2
fill1:	
	LD	(arecord),HL
	PUSH	BC
	CALL	discard$data$bcb
	CALL	seek
IF	BANKED
	XOR	A
	CALL	setbnkf
ENDIF	
	POP	BC
	CALL	wrbuff
	LD	HL,(arecord)
	POP	DE
	PUSH	DE
	; Continue writing until blkmsk & arecord = 0
	ADD	HL,DE
	LD	A,(blkmsk)
	AND	L
	LD	C,0
	jp	nz,fill1
	; Restore arecord
	POP	HL
	POP	HL
	LD	(arecord),HL
	CALL	setdata		; Restore dma
diskwr11:	
	POP	DE
	LD	A,(vrecord)
	LD	D,A		; Load and save vrecord
	PUSH	DE
	CALL	check$nprs
	jp	c,dont$write
	jp	z,write
	LD	A,2		; deblock write code
	CALL	deblock$dta
	JP	dont$write
write:	
	CALL	setdata
	CALL	seek
IF	BANKED
	LD	A,1
	CALL	setbnkf
ENDIF	
	; Discard matching BCB if write is direct
	CALL	discard$data$bcb
	; Set write flag to zero if arecord & blkmsk ~= 0
	POP	BC
	PUSH	BC
	LD	A,(arecord)
	LD	HL,blkmsk
	AND	(HL)
	jp	z,write0
	LD	C,0
write0:	
	CALL	wrbuff
dont$write:	
	POP	BC		; c = 2 if a new block was allocated, 0 if .NOT.
	; Increment record count if rcount<=vrecord
	LD	A,B
	LD	HL,rcount
	CP	(HL)		; vrecord-rcount
	jp	c,diskwr2
	; rcount <= vrecord
	LD	(HL),A
	INC	(HL)		; rcount = vrecord+1
IF	MPM	
	CALL	test$unlocked
	jp	z,write1
	
	; for unlocked files 
	;   rcount = rcount & (~ blkmsk) + blkmsk + 1
	LD	A,(blkmsk)
	LD	B,A
	INC	B
	CPL	
	LD	C,A
	LD	A,(HL)
	DEC	A
	AND	C
	ADD	A,B
	LD	(HL),A
write1:	
ENDIF	
	LD	C,2		; Mark as record count incremented
diskwr2:	
	; a has vrecord, c=2 if new block or new record#
	DEC	C
	DEC	C
	jp	nz,noupdate
	CALL	reset$fwf
IF	MPM	
	CALL	test$unlocked
	jp	z,noupdate
	LD	A,(rcount)
	CALL	getrcnta
	LD	(HL),A
	CALL	close
	CALL	test$disk$fcb1
ENDIF	
noupdate:	
	; Set file write flag if reset
	CALL	set$filewf
IF	BANKED
	jp	nz,disk$write3
	; Reset fcb file write flag to ensure t3' gets
	; reset by the close function
	CALL	reset$fwf
	CALL	reset$copy$cr$only
	JP	setfcb
disk$write3:	
	CALL	set$copy$cr$only
ELSE	
	call	z,reset$fwf
ENDIF	
	JP	setfcb		; Replace parameters
	; ret
rseek:	
	; Random access seek operation, c=0ffh if read mode
	; fcb is assumed to address an active file control block
	; (1st block of FCB = 0ffffh if previous bad seek)
	PUSH	BC		; Save r/w flag
	LD	HL,(info)
	EX	DE,HL		; de will hold base of fcb
	LD	HL,ranrec
	ADD	HL,DE		; hl=.fcb(ranrec)
	LD	A,(HL)
	AND	7fh
	PUSH	AF		; record number
	LD	A,(HL)
	RLA			; cy=lsb of extent#
	INC	HL
	LD	A,(HL)
	RLA	
	AND	11111b		; a=ext#
	LD	C,A		; c holds extent number, record stacked
	LD	A,(HL)
	AND	1111_0000b
	INC	HL
	OR	(HL)
	RRCA	
	RRCA	
	RRCA	
	RRCA	
	LD	B,A
	; b holds module #
	; Check high byte of ran rec <= 3
	LD	A,(HL)
	AND	1111_1100b
	POP	HL
	LD	L,6
	LD	A,H
	; Produce error 6, seek past physical eod
	jp	nz,seekerr
	; otherwise, high byte = 0, a = sought record
	LD	HL,nxtrec
	ADD	HL,DE		; hl = .fcb(nxtrec)
	LD	(HL),A		; sought rec# stored away
	; Arrive here with b=mod#, c=ext#, de=.fcb, rec stored
	; the r/w flag is still stacked.  compare fcb values
	LD	A,(fx)
	CP	99
	jp	z,rseek3
	; Check module # first
	PUSH	DE
	CALL	chk$inv$fcb
	POP	DE
	jp	z,ranclose
	LD	HL,modnum
	ADD	HL,DE
	LD	A,B		; b=seek mod#
	SUB	A,(HL)
	AND	3fh
	jp	nz,ranclose	; same?
	; Module matches, check extent
	LD	HL,extnum
	ADD	HL,DE
	LD	A,(HL)
	CP	C
	jp	z,seekok2		; extents equal
	CALL	compext
	jp	nz,ranclose
	; Extent is in same directory fcb
	PUSH	BC
	CALL	get$dir$ext
	POP	BC
	CP	C
	jp	nc,rseek2		; jmp if dir$ext > ext
	POP	DE
	PUSH	DE
	INC	E
	jp	nz,rseek2		; jmp if write fx
	INC	E
	POP	DE
	JP	setlret1	; error - reading unwritten data
rseek2:	
	LD	(HL),C		; fcb(ext) = c
	LD	C,A		; c = dir$ext
	; hl=.fcb(ext),c=dir ext
	CALL	restore$rc
	CALL	set$rc
	JP	seekok1
ranclose:	
	PUSH	BC
	PUSH	DE		; Save seek mod#,ext#, .fcb
	CALL	close		; Current extent closed
	POP	DE
	POP	BC		; Recall parameters and fill
	LD	L,3		; Cannot close error #3
	LD	A,(lret)
	INC	A
	jp	z,seekerr
rseek3:	
	CALL	set$xdcnt	; Reset xdcnt for make
IF	MPM	
	CALL	set$sdcnt
ENDIF	
	LD	HL,extnum
	ADD	HL,DE
	PUSH	HL
	LD	D,(HL)
	LD	(HL),C		; fcb(extnum)=ext#
	INC	HL
	INC	HL
	LD	A,(HL)
	LD	E,A
	PUSH	DE
	AND	040h
	OR	B
	LD	(HL),A
	; fcb(modnum)=mod#
	CALL	open		; Is the file present?
	LD	A,(lret)
	INC	A
	jp	nz,seekok		; Open successful?
	; Cannot open the file, read mode?
	POP	DE
	POP	HL
	POP	BC		; r/w flag to c (=0ffh if read)
	PUSH	BC
	PUSH	HL
	PUSH	DE		; Restore stack
	LD	L,4		; Seek to unwritten extent #4
	INC	C		; becomes 00 if read operation
	jp	z,badseek		; Skip to error if read operation
	; Write operation, make new extent
	CALL	make
	LD	L,5		; cannot create new extent #5
	jp	z,badseek		; no dir space
IF	MPM	
	CALL	fix$olist$item
ENDIF	
	; file make operation successful
seekok:	
	POP	BC
	POP	BC		; Discard top 2 stacked items
IF	MPM	
	CALL	set$fcb$cks$flag
ELSE	
	CALL	set$lsn
ENDIF	
seekok1:	
IF	BANKED
	CALL	reset$copy$cr$only
ENDIF	
seekok2:	
	POP	BC		; Discard r/w flag or .fcb(ext)
	XOR	A
	JP	sta$ret		; with zero set	
badseek:	
	; Restore fcb(ext) & fcb(mod)
	POP	DE
	EX	(SP),HL		; Save error flag
	LD	(HL),D
	INC	HL
	INC	HL
	LD	(HL),E
	POP	HL		; Restore error flag
seekerr:	
IF	BANKED
	CALL	reset$copy$cr$only; Z flag set
	INC	A		; Reset Z flag
ENDIF	
	POP	BC		; Discard r/w flag
	LD	A,L
	JP	sta$ret		; lret=#, nonzero
randiskread:	
	; Random disk read operation
	LD	C,true		; marked as read operation
	CALL	rseek
	call	z,diskread	; if seek successful
	RET	
randiskwrite:	
	; Random disk write operation
	LD	C,false		; marked as write operation
	CALL	rseek
	call	z,diskwrite	; if seek successful
	RET	
compute$rr:	
	; Compute random record position for getfilesize/setrandom
	EX	DE,HL
	ADD	HL,DE
	; de=.buf(dptr) or .fcb(0), hl = .f(nxtrec/reccnt)
	LD	C,(HL)
	LD	B,0		; bc = 0000 0000 ?rrr rrrr
	LD	HL,extnum
	ADD	HL,DE
	LD	A,(HL)
	RRCA	
	AND	80h		; a=e000 0000
	ADD	A,C
	LD	C,A
	LD	A,0
	ADC	A,B
	LD	B,A
	; bc = 0000 000? errrr rrrr
	LD	A,(HL)
	RRCA	
	AND	0fh
	ADD	A,B
	LD	B,A
	; bc = 000? eeee errrr rrrr
	LD	HL,modnum
	ADD	HL,DE
	LD	A,(HL)		; a=xxmm mmmm
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A		; cy=m a=mmmm 0000
	OR	A
	ADD	A,B
	LD	B,A
	PUSH	AF		; Save carry
	LD	A,(HL)
	RRA	
	RRA	
	RRA	
	RRA	
	AND	0000_0011b	; a=0000 00mm
	LD	L,A
	POP	AF
	LD	A,0
	ADC	A,L		; Add carry
	RET	
compare$rr:	
	LD	E,A		; Save cy
	LD	A,C
	SUB	A,(HL)
	LD	D,A
	INC	HL		; lst byte
	LD	A,B
	SBC	A,(HL)
	INC	HL		; middle byte
	PUSH	AF
	OR	D
	LD	D,A
	POP	AF
	LD	A,E
	SBC	A,(HL)		; carry if .fcb(ranrec) > directory
	RET	
set$rr:	
	LD	(HL),E
	DEC	HL
	LD	(HL),B
	DEC	HL
	LD	(HL),C
	RET	
getfilesize:	
	; Compute logical file size for current fcb
	; Zero the receiving ranrec field
	CALL	get$rra
	PUSH	HL		; Save position
	LD	(HL),D
	INC	HL
	LD	(HL),D
	INC	HL
	LD	(HL),D		; =00 00 00
	CALL	search$extnum
getsize:	
	jp	z,setsize
	; current fcb addressed by dptr
	CALL	getdptra
	LD	DE,reccnt	; ready for compute size
	CALL	compute$rr
	; a=0000 00mm bc = mmmm eeee errr rrrr
	; Compare with memory, larger_
	POP	HL
	PUSH	HL		; Recall, replace .fcb(ranrec)
	CALL	compare$rr
	call	nc,set$rr
	CALL	searchn
	LD	A,0
	LD	(aret),A
	JP	getsize
setsize:	
	POP	HL		; Discard .fcb(ranrec)
	RET	
setrandom:	
	; Set random record from the current file control block
	EX	DE,HL
	LD	DE,nxtrec	; Ready params for computesize
	CALL	compute$rr	; de=info, a=0000 00mm, bc=mmmm eeee errr rrrr
	LD	HL,ranrec
	ADD	HL,DE		; hl = .fcb(ranrec)
	LD	(HL),C
	INC	HL
	LD	(HL),B
	INC	HL
	LD	(HL),A		; to ranrec
	RET	
disk$select:	
	; Select disk info for subsequent input or output ops
	LD	(adrive),A
disk$select1:	; called by deblock
	LD	(HL),A		; curdsk = seldsk or adrive
	LD	D,A		; Save seldsk in register D for selectdisk call
	LD	HL,(dlog)
	CALL	test$vector	; test$vector does .NOT. modify DE
	LD	E,A
	PUSH	DE		; Send to seldsk, save for test below
	CALL	selectdisk
	POP	HL		; Recall dlog vector
	jp	nc,sel$error	; returns with C flag set if select ok
	; Is the disk logged in?
	DEC	L		; reg l = 1 if so
	RET	
tmpselect:	
	LD	HL,seldsk
	LD	(HL),E
curselect:	
	LD	A,(seldsk)
	LD	HL,curdsk
	CP	(HL)
	jp	nz,select
	CP	0ffh
	ret	nz		; return if seldsk ~= ffh
select:	
	CALL	disk$select
IF	MPM	
	jp	nz,select1		; no
	; yes - drive previously logged in
	LD	HL,(rlog)
	CALL	test$vector
	LD	(rem$drv),A
	RET			; Set rem$drv & return
select1:	
ELSE	
	ret	z		; yes - drive previously logged in
ENDIF	
	CALL	initialize	; Log in the directory
	; Increment login sequence # if odd
	LD	HL,(lsn$add)
	LD	A,(HL)
	AND	1
	PUSH	AF
	ADD	A,(HL)
	LD	(HL),A
	POP	AF
	call	nz,set$rlog
	CALL	set$dlog
IF	MPM	
	LD	HL,chksiz+1
	LD	A,(HL)
	RLA	
	LD	A,0
	jp	c,select2
	LD	DE,rlog
	CALL	set$cdisk	; rlog=set$cdisk(rlog)
	LD	A,1
select2:	
	LD	(rem$drv),A
ENDIF	
	RET	
reselectx:	
	XOR	A
	LD	(high$ext),A
IF	BANKED
	LD	(xfcb$read$only),A
ENDIF	
	JP	reselect1
reselect:	
	; Check current fcb to see if reselection necessary
	LD	BC,807fh
	LD	HL,(info)
	LD	DE,7
	EX	DE,HL
	ADD	HL,DE
IF	BANKED
	; xfcb$read$only = 80h & fcb(7)
	LD	A,(HL)
	AND	B
	LD	(xfcb$read$only),A
	; fcb(7) = fcb(7) & 7fh
	LD	A,(HL)
	AND	C
	LD	(HL),A
ENDIF	
IF	MPM	
	; if fcb(8) & 80h
	;    then fcb(8) = fcb(8) & 7fh, high$ext = 60h
	;    else high$ext = fcb(ext) & 0e0h
	INC	HL
	LD	DE,4
	LD	A,(HL)
	AND	C
	CP	(HL)
	LD	(HL),A
	LD	A,60h
	jp	nz,reselect0
	ADD	HL,DE
	LD	A,0e0h
	AND	(HL)
reselect0:	
	LD	(high$ext),A
ELSE	
	; high$ext = 80h & fcb(8)
	INC	HL
	LD	A,(HL)
	AND	B
	LD	(high$ext),A
	; fcb(8) = fcb(8) & 7fh
	LD	A,(HL)
	AND	C
	LD	(HL),A
ENDIF	
	; fcb(ext) = fcb(ext) & 1fh
	CALL	clr$ext
reselect1:	
	LD	HL,0
IF	BANKED
	LD	(make$xfcb),HL	; make$xfcb,find$xfcb = 0
ENDIF	
	LD	(xdcnt),HL	; required by directory hashing
	XOR	A
	LD	(search$user0),A
	DEC	A
	LD	(resel),A	; Mark possible reselect
	LD	HL,(info)
	LD	A,(HL)		; drive select code
	LD	(fcbdsk),A	; save drive code
	AND	1_1111b		; non zero is auto drive select
	DEC	A		; Drive code normalized to 0..30, or 255
	LD	(linfo),A	; Save drive code
	CP	0ffh
	jp	z,noselect
	; auto select function, seldsk saved above
	LD	(seldsk),A
noselect:	
	CALL	curselect
	; Set user code
	LD	A,(usrcode)	; 0...15
	LD	HL,(info)
	LD	(HL),A
noselect0:	
	; Discard directory BCB's if drive is removable
	; and fx = 15,17,19,22,23,30 etc.
	CALL	tst$log$fxs
	call	z,discard$dir
	; Check for media change on currently slected disk
	CALL	check$media
	; Check for media change on any other disks
	JP	check$all$media
check$media:	
	; Check media if DPH media flag set.
	; Is DPH media flag set?
	CALL	test$media$flag
	ret	z		; no
	; Test for media change by reading directory
	; to current high water mark or until media change
	; is detected.
	; First reset DPH media flag & discard directory BCB's
	LD	(HL),0
	CALL	discard$dir
	LD	HL,(dcnt)
	PUSH	HL
	CALL	home
	CALL	set$end$dir
check$media1:	
	LD	C,false
	CALL	r$dir
	LD	HL,relog
	LD	A,(HL)
	OR	A
	jp	z,check$media2
	LD	(HL),0
	POP	HL
	LD	A,(fx)
	CP	48
	ret	z
	CALL	drv$relog
	JP	chk$exit$fxs
check$media2:	
	CALL	compcdr
	jp	c,check$media1
	POP	HL
	LD	(dcnt),HL
	RET	
check$all$media:	
	; This routine checks all logged-in drives for
	; a set DPH media flag and pending buffers.  It reads 
	; the directory for these drives to verify that media 
	; has .NOT. changed.  If media has changed, the drives 
	; get reset (but .NOT. relogged-in).
	; Is SCB media flag set?
	LD	HL,media$flag
	LD	A,(HL)
	OR	A
	ret	z		; no
	; Reset SCB media flag
	LD	(HL),0
	; Test logged-in drives only
	LD	HL,(dlog)
	LD	A,16
chk$am1:	
	DEC	A
	ADD	HL,HL
	jp	nc,chk$am2
	; A = drive #
	; Select drive
	PUSH	AF
	PUSH	HL
	LD	HL,curdsk
	CALL	disk$select
	; Does drive have pending data buffers?
	CALL	test$pending
	call	nz,check$media	; yes
	POP	HL
	POP	AF
chk$am2:	
	OR	A
	jp	nz,chk$am1
	JP	curselect
test$pending:	
	; On return, Z flag reset if buffer pending
	; Does dta$bcba = 0ffffh
	LD	HL,(dta$bcba)
	LD	A,L
	AND	H
	INC	A
	ret	z		; yes
IF	BANKED
test$p1:	
	; Does bcb addr = 0?
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	A,E
	OR	D
	ret	z		; yes - no pending buffers
	LD	HL,4
ELSE	
	LD	DE,4
ENDIF	
	; Is buffer pending?
	ADD	HL,DE
	LD	A,(HL)
	OR	A		; A ~= 0 if so
IF	BANKED
	ret	nz		; yes
	; no - advance to next bcb
	LD	HL,13
	ADD	HL,DE
	JP	test$p1
ELSE	
	RET	
ENDIF	
get$dir$mode:	
	LD	HL,(drvlbla)
	LD	A,(HL)
IF	.NOT.	BANKED
	AND	7fh		; Mask off password bit
ENDIF	
	RET	
IF	BANKED
chk$password:	
	CALL	get$dir$mode
	AND	80h
	ret	z
chk$pw:	; Check password
	CALL	get$xfcb
	ret	z		; a = xfcb options
	JP	cmp$pw
chk$pw$error:	
	; Disable special searches
	XOR	A
	LD	(xdcnt+1),A
	; pw$fcb = dir$xfcb
	CALL	getdptra
	EX	DE,HL
	LD	C,12
	LD	HL,pw$fcb
	PUSH	HL
	CALL	move
	LD	A,(DE)
	INC	HL
	LD	(HL),A
	POP	DE
	LD	HL,(info)
	LD	A,(HL)
	LD	(DE),A
	; push original info and xfcb password mode
	; info = .pw$fcb
	PUSH	HL
	EX	DE,HL
	LD	(info),HL
	; Does fcb(ext = 0, mod = 0) exist?
	CALL	search$namlen
	jp	z,chk$pwe2	; no
	; Does sfcb exist for fcb ?
	CALL	get$dtba$8
	OR	A
	jp	nz,chk$pwe1	; no 
	EX	DE,HL
	LD	HL,pw$mode
	; Is sfcb password mode nonzero?
	LD	B,(HL)
	LD	A,(DE)
	LD	(HL),A
	OR	A
	jp	z,chk$pwe2	; no
	; Do password modes match?
	XOR	B
	AND	0e0h
	jp	z,chk$pwe1	; yes
	; no - update xfcb to match sfcb
	CALL	get$xfcb
	jp	z,chk$pwe1	; no xfcb (error)
	LD	A,(pw$mode)
	LD	(HL),A
	CALL	nowrite
	call	z,seek$copy
chk$pwe1:	
	POP	HL
	LD	(info),HL
	LD	A,(fx)
	CP	15
	ret	z
	CP	22
	ret	z
pw$error:	; password error
	LD	A,7
	JP	set$aret
chk$pwe2:	
	XOR	A
	LD	(pw$mode),A
	CALL	nowrite
	jp	nz,chk$pwe3
	; Delete xfcb
	CALL	get$xfcb
	PUSH	AF
	LD	HL,(info)
	LD	A,(HL)
	OR	10h
	LD	(HL),A
	POP	AF
	call	nz,delete10
chk$pwe3:	
	; Restore info
	POP	HL
	LD	(info),HL
	RET	
cmp$pw:	; Compare passwords
	INC	HL
	LD	B,(HL)
	LD	A,B
	OR	A
	jp	nz,cmp$pw2
	LD	D,H
	LD	E,L
	INC	HL
	INC	HL
	LD	C,9
cmp$pw1:	
	INC	HL
	LD	A,(HL)
	DEC	C
	ret	z
	OR	A
	jp	z,cmp$pw1
	CP	20h
	jp	z,cmp$pw1
	EX	DE,HL
cmp$pw2:	
	LD	DE,23-ubytes
	ADD	HL,DE
	EX	DE,HL
	LD	HL,(xdmaad)
	LD	C,8
cmp$pw3:	
	LD	A,(DE)
	XOR	B
	CP	(HL)
	jp	nz,cmp$pw4
	DEC	DE
	INC	HL
	DEC	C
	jp	nz,cmp$pw3
	RET	
cmp$pw4:	
	DEC	DE
	DEC	C
	jp	nz,cmp$pw4
	INC	DE
IF	MPM	
	CALL	get$df$pwa
	INC	A
	jp	nz,cmp$pw5
	INC	A
	RET	
cmp$pw5:	
ELSE	
	LD	HL,df$password
ENDIF	
	LD	C,8
	JP	compare
IF	MPM	
get$df$pwa:	; a = ff => no df pwa
	CALL	rlr
	LD	BC,console
	ADD	HL,BC
	LD	A,(HL)
	CP	16
	LD	A,0ffh
	ret	nc
	LD	A,(HL)
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	H,0
	LD	L,A
	LD	BC,dfpassword
	ADD	HL,BC
	RET	
ENDIF	
set$pw:	; Set password in xfcb
	PUSH	HL		; Save .xfcb(ex) 
	LD	BC,8		; b = 0, c = 8
	LD	DE,23-extnum
	ADD	HL,DE
	EX	DE,HL
	LD	HL,(xdmaad)
set$pw0:	
	XOR	A
	PUSH	AF
set$pw1:	
	LD	A,(HL)
	LD	(DE),A
	OR	A
	jp	z,set$pw2
	CP	20h
	jp	z,set$pw2
	INC	sp
	INC	sp
	PUSH	AF
set$pw2:	
	ADD	A,B
	LD	B,A
	DEC	DE
	INC	HL
	DEC	C
	jp	nz,set$pw1
	POP	AF
	OR	B
	POP	HL
	jp	nz,set$pw3
	; is fx = 100 (directory label)?
	LD	A,(fx)
	CP	100
	jp	z,set$pw3		; yes
	LD	(HL),0		; zero xfcb(ex) - no password
set$pw3:	
	INC	DE
	LD	C,8
set$pw4:	
	LD	A,(DE)
	XOR	B
	LD	(DE),A
	INC	DE
	DEC	C
	jp	nz,set$pw4
	INC	HL
	RET	
get$xfcb:	
	LD	HL,(info)
	LD	A,(HL)
	PUSH	AF
	OR	010h
	LD	(HL),A
	CALL	search$extnum
	LD	A,0
	LD	(lret),A
	LD	HL,(info)
	POP	BC
	LD	(HL),B
	ret	z
get$xfcb1:	
	CALL	getdptra
	EX	DE,HL
	LD	HL,extnum
	ADD	HL,DE
	LD	A,(HL)
	AND	0e0h
	OR	1
	RET	
adjust$dmaad:	
	PUSH	HL
	LD	HL,(xdmaad)
	ADD	HL,DE
	LD	(xdmaad),HL
	POP	HL
	RET	
init$xfcb:	
	CALL	setcdr		; may have extended the directory
	LD	BC,1014h	; b=10h, c=20
init$xfcb0:	
	; b = fcb(0) logical or mask
	; c = zero count
	PUSH	BC
	CALL	getdptra
	EX	DE,HL
	LD	HL,(info)
	EX	DE,HL
	; Zero extnum and modnum
	LD	A,(DE)
	OR	B
	LD	(HL),A
	INC	DE
	INC	HL
	LD	C,11
	CALL	move
	POP	BC
	INC	C
init$xfcb1:	
	DEC	C
	ret	z
	LD	(HL),0
	INC	HL
	JP	init$xfcb1
chk$xfcb$password:	
	CALL	get$xfcb1
chk$xfcb$password1:	
	PUSH	HL
	CALL	cmp$pw
	POP	HL
	RET	
ENDIF	
stamp1:	
	LD	C,0
	JP	stamp3
stamp2:	
	LD	C,4
stamp3:	
	CALL	get$dtba
	OR	A
	ret	nz
	LD	DE,seek$copy
	PUSH	DE
stamp4:	
IF	MPM	
	PUSH	HL
	CALL	get$stamp$add
	EX	DE,HL
	POP	HL
ELSE	
	LD	DE,stamp
ENDIF	
	PUSH	HL
	PUSH	DE
	LD	C,0
	CALL	timef		; does .NOT. modify hl,de
	LD	C,4
	CALL	compare
	LD	C,4
	POP	DE
	POP	HL
	jp	nz,move
	POP	HL
	RET	
stamp5:	
	CALL	getdptra
	ADD	HL,BC
	LD	DE,func$ret
	PUSH	DE
	JP	stamp4
IF	BANKED
get$dtba$8:	
	LD	C,8
ENDIF	
get$dtba:	
	; c = offset of sfcb subfield (0,4,8)
	; Return with a = 0 if sfcb exists
	; Does fcb occupy 4th item of sector?
	LD	A,(dcnt)
	AND	3
	CP	3
	ret	z		; yes
	LD	B,A
	LD	HL,(buffa)
	LD	DE,96
	ADD	HL,DE
	; Does sfcb reside in 4th directory item?
	LD	A,(HL)
	SUB	A,21h
	ret	nz		; no
	; hl = hl + 10*lret + 1 + c
	LD	A,B
	ADD	A,A
	LD	E,A
	ADD	A,A
	ADD	A,A
	ADD	A,E
	INC	A
	ADD	A,C
	LD	E,A
	ADD	HL,DE
	XOR	A
	RET	
qstamp:	
	; Is fcb 1st logical fcb for file?
	CALL	qdirfcb1
	ret	nz		; no
qstamp1:	
	; Does directory label specify requested stamp?
	LD	HL,(drvlbla)
	LD	A,C
	AND	(HL)
	jp	nz,nowrite		; yes - verify drive r/w
	INC	A
	RET			; no - return with Z flag reset
qdirfcb1:	
	; Routine to determine if fcb is 1st directory fcb
	; for file
	; Is fcb(ext) & ~extmsk & 00011111b = 0?
	LD	A,(extmsk)
	OR	1110_0000b
	CPL	
	LD	B,A
	CALL	getexta
	LD	A,(HL)
	AND	B
	ret	nz		; no
	; is fcb(mod) & 0011_1111B = 0?
	INC	HL
	INC	HL
	LD	A,(HL)
	AND	3fh
	RET			; Z flag set if zero
update$stamp:	
	; Is update stamping requested on drive?
	LD	C,0010_0000b
	CALL	qstamp1
	ret	nz		; no
	; Has file been written to since it was opened?
	CALL	getmodnum
	AND	40h
	ret	nz		; yes - update stamp performed
	; Search for 1st dir fcb
	CALL	getexta
	LD	B,(HL)
	LD	(HL),0
	PUSH	HL
	INC	HL
	INC	HL
	LD	C,(HL)
	LD	(HL),0
	PUSH	BC
	; Search from beginning of directory
	CALL	search$namlen
	; Perform update stamp if dir fcb 1 found
	call	nz,stamp2
	XOR	A
	LD	(lret),A
	; Restore fcb extent and module fields
	POP	BC
	POP	HL
	LD	(HL),B
	INC	HL
	INC	HL
	LD	(HL),C
	RET	
IF	MPM	
pack$sdcnt:	
;packed$dcnt = dblk(low 15 bits) || dcnt(low 9 bits)
;	if sdblk = 0 then dblk = shr(sdcnt,blkshf+2)
;		     else dblk = sdblk
;	dcnt = sdcnt & (blkmsk || '11'b)
;
;	packed$dcnt format (24 bits)
;
;	12345678 12345678 12345678
;	23456789 .......1 ........ sdcnt (low 9 bits)
;	........ 9abcdef. 12345678 sdblk (low 15 bits)
;
	LD	HL,(sdblk)
	LD	A,H
	OR	L
	jp	nz,pack$sdcnt1
	LD	A,(blkshf)
	ADD	A,2
	LD	C,A
	LD	HL,(sdcnt)
	CALL	hlrotr
pack$sdcnt1:	
	ADD	HL,HL
	EX	DE,HL
	LD	HL,sdcnt
	LD	B,1
	LD	A,(blkmsk)
	RLA	
	OR	B
	RLA	
	OR	B
	AND	(HL)
	LD	(packed$dcnt),A
	LD	A,(blkshf)
	CP	7
	jp	nz,pack$sdcnt2
	INC	HL
	LD	A,(HL)
	AND	B
	jp	z,pack$sdcnt2
	LD	A,E
	OR	B
	LD	E,A
pack$sdcnt2:	
	EX	DE,HL
	LD	(packed$dcnt+1),HL
	RET	
; olist element = link(2) || atts(1) || dcnt(3) || 
;		 pdaddr(2) || opncnt(2)
;
;	link = 0 -> end of list
;
;	atts - 80 - open in locked mode
;	       40 - open in unlocked mode
;	       20 - open in read/only mode
;	       10 - deleted item
;	       0n - drive code (0-f)
;
;	dcnt = packed sdcnt+sdblk
;	pdaddr = process descriptor addr
;	opncnt = # of open calls - # of close calls
;		 olist item freed by close when opncnt = 0
;
; llist element = link(2) || drive(1) || arecord(3) || 
;	         pdaddr(2) || .olist$item(2)
;
;	link = 0 -> end of list
;
;	drive - 0n - drive code (0-f)
;
;	arecord = record number of locked record
;	pdaddr = process descriptor addr
;	.olist$item = address of file's olist item
search$olist:	
	LD	HL,open$root
	JP	srch$list0
search$llist:	
	LD	HL,lock$root
	JP	srch$list0
searchn$list:	
	LD	HL,(cur$pos)
srch$list0:	
	LD	(prv$pos),HL
; search$olist, search$llist, searchn$list conventions
;
;	b = 0 -> return next item
;	b = 1 -> search for matching drive
; 	b = 3 -> search for matching dcnt
;	b = 5 -> search for matching dcnt + pdaddr
;	if found then z flag is set
;	              prv$pos -> previous list element
;		      cur$pos -> found list element
;		      hl -> found list element
;	else prv$pos -> list element to insert after
;
;	olist and llist are maintained in drive order
srch$list1:	
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	LD	A,L
	OR	H
	jp	z,srch$list3
	XOR	A
	CP	B
	jp	z,srch$list6
	INC	HL
	INC	HL
	LD	DE,curdsk
	LD	A,(HL)
	AND	0fh
	LD	C,A
	LD	A,(DE)
	SUB	A,C
	jp	nz,srch$list4
	LD	A,B
	DEC	A
	jp	z,srch$list5
	LD	C,B
	PUSH	HL
	INC	DE
	INC	HL
	CALL	compare
	POP	HL
	jp	z,srch$list5
srch$list2:	
	DEC	HL
	DEC	HL
	LD	(prv$pos),HL
	JP	srch$list1
srch$list3:	
	INC	A
	RET	
srch$list4:	
	jp	nc,srch$list2
srch$list5:	
	DEC	HL
	DEC	HL
srch$list6:	
	LD	(cur$pos),HL
	RET	
delete$item:	; hl -> item to be deleted
	di	
	PUSH	DE
	PUSH	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	HL,(prv$pos)
	LD	(cur$pos),HL
	; prv$pos.link = delete$item.link
	LD	(HL),E
	INC	HL
	LD	(HL),D
	LD	HL,(free$root)
	EX	DE,HL
	; free$root = .delete$item
	POP	HL
	LD	(free$root),HL
	; delete$item.link = previous free$root
	LD	(HL),E
	INC	HL
	LD	(HL),D
	POP	DE
	ei	
	RET	
create$item:	; hl -> new item if successful
	; z flag set if no free items
	LD	HL,(free$root)
	LD	A,L
	OR	H
	ret	z
	PUSH	DE
	PUSH	HL
	LD	(cur$pos),HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	; free$root = free$root.link
	EX	DE,HL
	LD	(free$root),HL
	LD	HL,(prv$pos)
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	POP	HL
	; create$item.link = prv$pos.link
	LD	(HL),E
	INC	HL
	LD	(HL),D
	DEC	HL
	EX	DE,HL
	LD	HL,(prv$pos)
	; prv$pos.link = .create$item
	LD	(HL),E
	INC	HL
	LD	(HL),D
	EX	DE,HL
	POP	DE
	RET	
set$olist$item:	
	; a = attributes
	; hl = olist entry address
	INC	HL
	INC	HL
	LD	B,A
	LD	DE,curdsk
	LD	A,(DE)
	OR	B
	LD	(HL),A
	INC	HL
	INC	DE
	LD	C,5
	CALL	move
	XOR	A
	LD	(HL),A
	INC	HL
	LD	(HL),A
	RET	
set$sdcnt:	
	LD	A,0ffh
	LD	(sdcnt+1),A
	RET	
tst$olist:	
	LD	A,0c9h
	LD	(chk$olist05),A
	JP	chk$olist0
chk$olist:	
	XOR	A
	LD	(chk$olist05),A
chk$olist0:	
	LD	DE,dcnt
	LD	HL,sdcnt
	LD	C,4
	CALL	move
	CALL	pack$sdcnt
	LD	B,3
	CALL	search$olist
	ret	nz
	POP	DE		; pop return address
	INC	HL
	INC	HL
	LD	A,(HL)
	AND	80h
	jp	z,openx06 
	DEC	HL
	DEC	HL
	PUSH	DE
	PUSH	HL
	CALL	compare$pds
	POP	HL
	POP	DE
	jp	nz,openx06
	PUSH	DE		; Restore return address
chk$olist05:	
	nop			; tst$olist changes this instr to ret
	CALL	delete$item
	LD	A,(pdcnt)
chk$olist1:	
	ADD	A,16
	jp	z,chk$olist1
	LD	(pdcnt),A
	PUSH	AF
	CALL	rlr
	LD	BC,pdcnt$off
	ADD	HL,BC
	POP	AF
	LD	(HL),A
	RET	
remove$files:	; bc = pdaddr
	LD	HL,(cur$pos)
	PUSH	HL
	LD	HL,(prv$pos)
	PUSH	HL
	LD	D,B
	LD	E,C
	LD	HL,open$root
	LD	(cur$pos),HL
remove$file1:	
	LD	B,0
	PUSH	DE
	CALL	searchn$list
	POP	DE
	jp	nz,remove$file2
	LD	BC,6
	CALL	tst$tbl$lmt
	jp	nz,remove$file1
	INC	HL
	INC	HL
	LD	A,(HL)
	OR	10h
	LD	(HL),A
	LD	(deleted$files),A
	JP	remove$file1
remove$file2:	
	POP	HL
	LD	(prv$pos),HL
	POP	HL
	LD	(cur$pos),HL
	RET	
delete$files:	
	LD	HL,open$root
	LD	(cur$pos),HL
delete$file1:	
	LD	B,0
	CALL	search$nlist
	ret	nz
	INC	HL
	INC	HL
	LD	A,(HL)
	AND	10h
	jp	z,delete$file1
	DEC	HL
	DEC	HL
	CALL	remove$locks
	CALL	delete$item
	JP	delete$file1
flush$files:	
	LD	HL,flushed
	LD	A,(HL)
	OR	A
	ret	nz
	INC	(HL)
flush$file0:	
	LD	HL,open$root
	LD	(cur$pos),HL
flush$file1:	
	LD	B,1
	CALL	searchn$list
	ret	nz
	PUSH	HL
	CALL	remove$locks
	CALL	delete$item
	POP	HL
	LD	DE,6
	ADD	HL,DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	HL,pdcnt$off
	ADD	HL,DE
	LD	A,(HL)
	AND	1
	jp	nz,flush$file1
	LD	A,(HL)
	OR	1
	LD	(HL),A
	LD	HL,(pdaddr)
	LD	C,2
	CALL	compare
	jp	nz,flush$file1
	LD	A,(pdcnt)
	ADD	A,10h
	LD	(pdcnt),A
	JP	flush$file1
free$files:	
	; free$mode = 1 - remove curdsk files for process
	;	      0 - remove all files for process
	LD	HL,(pdaddr)
	EX	DE,HL
	LD	HL,open$root
	LD	(curpos),HL
free$files1:	
	LD	A,(free$mode)
	LD	B,A
	PUSH	DE
	CALL	searchn$list
	POP	DE
	ret	nz
	LD	BC,6
	CALL	tst$tbl$lmt
	jp	nz,free$files1
	PUSH	HL
	INC	HL
	INC	HL
	INC	HL
	CALL	test$ffff
	jp	nz,free$files2
	CALL	test$ffff
	jp	z,free$files3
free$files2:	
	LD	A,0ffh
	LD	(incr$pdcnt),A
free$files3:	
	POP	HL
	CALL	remove$locks
	CALL	delete$item
	JP	free$files1
remove$locks:	
	LD	(file$id),HL
	INC	HL
	INC	HL
	LD	A,(HL)
	AND	40h
	jp	z,remove$lock3
	PUSH	DE
	LD	HL,(prv$pos)
	PUSH	HL
	LD	HL,(file$id)
	EX	DE,HL
	LD	HL,lock$root
	LD	(cur$pos),HL
remove$lock1:	
	LD	B,0
	PUSH	DE
	CALL	searchn$list
	POP	DE
	jp	nz,remove$lock2
	LD	BC,8
	CALL	tst$tbl$lmt
	jp	nz,remove$lock1
	CALL	delete$item
	JP	remove$lock1
remove$lock2:	
	POP	HL
	LD	(prv$pos),HL
	POP	DE
remove$lock3:	
	LD	HL,(file$id)
	RET	
tst$tbl$lmt:	
	PUSH	HL
	ADD	HL,BC
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	SUB	A,E
	jp	nz,tst$tbl$lmt1
	LD	A,H
	SUB	A,D
tst$tbl$lmt1:	
	POP	HL
	RET	
create$olist$item:	
	LD	B,1
	CALL	search$olist
	di	
	CALL	create$item
	LD	A,(attributes)
	CALL	set$olist$item
	ei	
	RET	
count$opens:	
	XOR	A
	LD	(open$cnt),A
	LD	HL,(pdaddr)
	EX	DE,HL
	LD	HL,open$root
	LD	(curpos),HL
count$open1:	
	LD	B,0
	PUSH	DE
	CALL	searchn$list
	POP	DE
	jp	nz,count$open2
	LD	BC,6
	CALL	tst$tbl$lmt
	jp	nz,count$open1
	LD	A,(open$cnt)
	INC	A
	LD	(open$cnt),A
	JP	count$open1
count$open2:	
	LD	HL,open$max
	LD	A,(open$cnt)
	RET	
count$locks:	
	XOR	A
	LD	(lock$cnt),A
	EX	DE,HL
	LD	HL,lock$root
	LD	(cur$pos),HL
count$lock1:	
	LD	B,0
	PUSH	DE
	CALL	searchn$list
	POP	DE
	ret	nz
	LD	BC,8
	CALL	tst$tbl$lmt
	jp	nz,count$lock1
	LD	A,(lock$cnt)
	INC	A
	LD	(lock$cnt),A
	JP	count$lock1
check$free:	
	LD	A,(mult$cnt)
	LD	E,A
	LD	D,0
	LD	HL,free$root
	LD	(cur$pos),HL
check$free1:	
	LD	B,0
	PUSH	DE
	CALL	searchn$list
	POP	DE
	jp	nz,check$free2
	INC	D
	LD	A,D
	SUB	A,E
	jp	c,check$free1
	RET	
check$free2:	
	POP	HL
	LD	A,14
	JP	sta$ret
lock:	; record lock and unlock 
	CALL	reselect
	CALL	check$fcb
	CALL	test$unlocked
	ret	z		; file .NOT. opened in unlocked mode
	LD	HL,(xdmaad)
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	INC	HL
	INC	HL
	LD	A,(HL)
	LD	B,A
	LD	A,(curdsk)
	SUB	A,B
	AND	0fh
	jp	nz,lock8		; invalid file id
	LD	A,B
	AND	40h
	jp	z,lock8		; invalid file id
	DEC	HL
	DEC	HL
	LD	(file$id),HL
	LD	A,(lock$unlock)
	INC	A
	jp	nz,lock1		; jmp if unlock
	CALL	count$locks
	LD	A,(lock$cnt)
	LD	B,A
	LD	A,(mult$cnt)
	ADD	A,B
	LD	B,A
	LD	A,(lock$max)
	CP	B
	LD	A,12
	jp	c,sta$ret		; too many locks by this process
	CALL	check$free
lock1:	
	CALL	save$rr
	LD	HL,lock9
	PUSH	HL
	LD	A,(mult$cnt)
lock2:	
	PUSH	AF
	CALL	get$lock$add
	LD	A,(lock$unlock)
	INC	A
	jp	nz,lock3
	CALL	test$lock
lock3:	
	POP	AF
	DEC	A
	jp	z,lock4
	CALL	incr$rr
	JP	lock2
lock4:	
	CALL	reset$rr
	LD	A,(mult$cnt)
lock5:	
	PUSH	AF
	CALL	get$lock$add
	LD	A,(lock$unlock)
	INC	A
	jp	nz,lock6
	CALL	set$lock
	JP	lock7
lock6:	
	CALL	free$lock
lock7:	
	POP	AF
	DEC	A
	ret	z
	CALL	incr$rr
	JP	lock5
lock8:	
	LD	A,13
	JP	sta$ret		; invalid file id
lock9:	
	CALL	reset$rr
	RET	
get$lock$add:	
	LD	HL,0
	ADD	HL,sp
	LD	(lock$sp),HL
	LD	A,0ffh
	LD	(lock$shell),A
	CALL	rseek
	XOR	A
	LD	(lock$shell),A
	CALL	getfcb
	LD	HL,(aret)
	LD	A,L
	OR	A
	jp	nz,lock$err
	CALL	index
	LD	HL,1
	jp	z,lock$err
	CALL	atran
	RET	
lock$perr:	
	XOR	A
	LD	(lock$shell),A
	EX	DE,HL
	LD	HL,(lock$sp)
	LD	SP,HL
	EX	DE,HL
lock$err:	
	POP	DE		; Discard return address
	POP	BC		; b = mult$cnt-# recs processed
	LD	A,(mult$cnt)
	SUB	A,B
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A
	OR	H
	LD	H,A
	LD	B,A
	LD	(aret),HL
	RET	
test$lock:	
	CALL	move$arecord
	LD	B,3
	CALL	search$llist
	ret	nz
	CALL	compare$pds
	ret	z
	LD	HL,8
	JP	lock$err
set$lock:	
	CALL	move$arecord
	LD	B,1
	CALL	search$llist
	di	
	CALL	create$item
	XOR	A
	CALL	set$olist$item
	EX	DE,HL
	LD	HL,(file$id)
	EX	DE,HL
	LD	(HL),D
	DEC	HL
	LD	(HL),E
	ei	
	RET	
free$lock:	
	CALL	move$arecord
	LD	B,5
	CALL	search$llist
	ret	nz
free$lock0:	
	CALL	delete$item
	LD	B,5
	CALL	searchn$list
	ret	nz
	JP	free$lock0
compare$pds:	
	LD	DE,6
	ADD	HL,DE
	EX	DE,HL
	LD	HL,pdaddr
	LD	C,2
	JP	compare
move$arecord:	
	LD	DE,arecord
	LD	HL,packed$dcnt
fix$olist$item:	
	LD	DE,xdcnt
	LD	HL,sdcnt
	; Is xdblk,xdcnt < sdblk,sdcnt
	LD	C,4
	OR	A
fix$ol1:	
	LD	A,(DE)
	SBC	A,(HL)
	INC	HL
	INC	DE
	DEC	C
	jp	nz,fix$ol1
	ret	nc
	; yes - update olist entry
	CALL	swap
	CALL	sdcnt$eq$xdcnt
	LD	HL,open$root
	LD	(cur$pos),HL
	; Find file's olist entry
fix$ol2:	
	CALL	swap
	CALL	pack$sdcnt
	CALL	swap
	LD	B,3
	CALL	searchn$list
	ret	nz
	; Update olist entry with new dcnt value
	PUSH	HL
	CALL	pack$sdcnt
	POP	HL
	INC	HL
	INC	HL
	INC	HL
	LD	DE,packed$dcnt
	LD	C,3
	CALL	move
	JP	fix$ol2
hl$eq$hl$and$de:	
	LD	A,L
	AND	E
	LD	L,A
	LD	A,H
	AND	D
	LD	H,A
	RET	
remove$drive:	
	EX	DE,HL
	LD	A,(curdsk)
	LD	C,A
	LD	HL,1
	CALL	hlrotl
	LD	A,L
	CPL	
	AND	E
	LD	E,A
	LD	A,H
	CPL	
	AND	D
	LD	D,A
	EX	DE,HL
	RET	
diskreset:	
	LD	HL,0
	LD	(ntlog),HL
	XOR	A
	LD	(set$ro$flag),A
	LD	HL,(info)
intrnldiskreset:	
	EX	DE,HL
	LD	HL,(open$root)
	LD	A,H
	OR	L
	ret	z
	EX	DE,HL
	LD	A,(curdsk)
	PUSH	AF
	LD	B,0
dskrst1:	
	LD	A,L
	RRA	
	jp	c,dskrst3
dskrst2:	
	LD	C,1
	CALL	hlrotr
	INC	B
	LD	A,H
	OR	L
	jp	nz,dskrst1
	POP	AF
	LD	(curdsk),A
	LD	HL,(ntlog)
	EX	DE,HL
	LD	HL,(tlog)
	LD	A,L
	OR	E
	LD	L,A
	LD	A,H
	OR	D
	LD	H,A
	LD	(tlog),HL
	INC	A
	RET	
dskrst3:	
	PUSH	BC
	PUSH	HL
	LD	A,B
	LD	(curdsk),A
	LD	HL,(rlog)
	CALL	test$vector1
	PUSH	AF
	LD	HL,(rodsk)
	LD	A,(curdsk)
	CALL	test$vector1
	LD	B,A
	POP	HL
	LD	A,(set$ro$flag)
	OR	B
	OR	H
	LD	(check$disk),A
	LD	HL,open$root
	LD	(cur$pos),HL
dskrst4:	
	LD	B,1
	CALL	searchn$list
	jp	nz,dskrst6
	LD	A,(check$disk)
	OR	A
	jp	z,dskrst5
	PUSH	HL
	CALL	compare$pds
	jp	z,dskrst45
	POP	HL
	XOR	A
	EX	DE,HL
	JP	dskrst6
dskrst45:	
	LD	DE,ntlog
	CALL	set$cdisk
	POP	HL
	JP	dskrst4
dskrst5:	
	LD	HL,(info)
	CALL	remove$drive
	LD	(info),HL
	OR	1
dskrst6:	
	POP	HL
	POP	BC
	jp	nz,dskrst2
	; error - olist item exists for another process
	; for removable drive to be reset
	POP	AF
	LD	(curdsk),A
	LD	A,B
	ADD	A,41h		; a = ascii drive
	LD	HL,6
	ADD	HL,DE
	LD	C,(HL)
	INC	HL
	LD	B,(HL)		; bc = pdaddr
	PUSH	AF
	CALL	test$error$mode
	POP	DE
	jp	nz,dskrst7
	LD	A,D
	PUSH	BC
	PUSH	AF
	CALL	rlr
	LD	DE,console
	ADD	HL,DE
	LD	D,(HL)		; d = console #
	LD	BC,deniedmsg
	CALL	xprint
	POP	AF
	LD	C,A
	CALL	conoutx
	LD	C,':'
	CALL	conoutx
	LD	BC,cnsmsg
	CALL	xprint
	POP	HL
	PUSH	HL
	LD	BC,console
	ADD	HL,BC
	LD	A,(HL)
	ADD	A,'0'
	LD	C,A
	CALL	conoutx
	LD	BC,progmsg
	CALL	xprint
	POP	HL
	CALL	dsplynm
dskrst7:	
	POP	HL		; Remove return addr from diskreset
	LD	HL,0ffffh
	LD	(aret),HL	; Flag the error
	RET	
deniedmsg:	
	DB	CR,LF,'disk reset denied, drive ',0
cnsmsg:	
	DB	' console ',0
progmsg:	
	DB	' program ',0
ENDIF	
;
;	individual function handlers
;
func12:	
	; Return version number
IF	MPM	
	LD	HL,0100h+dvers
	JP	sthl$ret
ELSE	
	LD	A,(version)
	JP	sta$ret		; lret = dvers (high = 00)
ENDIF	
func13:	
IF	MPM	
	LD	HL,(dlog)
	LD	(info),HL
	CALL	diskreset
	jp	z,reset$all
	CALL	reset$37
	JP	func13$cont
reset$all:	
	; Reset disk system - initialize to disk 0
	LD	HL,0
	LD	(rodsk),HL
	LD	(dlog),HL
	LD	(rlog),HL
	LD	(tlog),HL
func13$cont:	
	LD	A,0ffh
	LD	(curdsk),A
ELSE	
	LD	HL,0ffffh
	CALL	reset$37x
ENDIF	
	XOR	A
	LD	(olddsk),A	; Note that usrcode remains unchanged
IF	MPM	
	XOR	A
	CALL	getmemseg	; a = mem seg tbl index
	OR	A
	ret	z
	INC	A
	ret	z
	CALL	rlradr
	LD	BC,msegtbl-rlros
	ADD	HL,BC
	ADD	A,A
	ADD	A,A
	LD	E,A
	LD	D,0
	ADD	HL,DE
	LD	H,(HL)
	LD	L,80h
	JP	intrnlsetdma
ELSE	
	LD	HL,tbuff
	LD	(dmaad),HL	; dmaad = tbuff
	JP	setdata		; to data dma address
ENDIF	
func14:	
IF	MPM	
	CALL	tmpselect	; seldsk = reg e
	CALL	rlr
	LD	BC,diskselect
	ADD	HL,BC
	LD	A,(HL)
	AND	0fh
	RRCA	
	RRCA	
	RRCA	
	RRCA	
	LD	B,A
	LD	A,(seldsk)
	OR	B
	RRCA	
	RRCA	
	RRCA	
	RRCA	
	LD	(HL),A
	RET	
ELSE	
	CALL	tmpselect	; seldsk = reg e
	LD	A,(seldsk)
	LD	(olddsk),A
	RET	
ENDIF	
func15:	
	; Open file
	CALL	clrmodnum	; Clear the module number
IF	MPM	
	CALL	reselect
	XOR	A
	LD	(make$flag),A
	CALL	set$sdcnt
	LD	HL,open$file
	PUSH	HL
	LD	A,0c9h
	LD	(check$fcb4),A
	CALL	check$fcb1
	POP	HL
	LD	A,(high$ext)
	CP	060h
	jp	nz,open$file
	CALL	home
	CALL	set$end$dir
	JP	open$user$zero
open$file:	
	CALL	set$sdcnt
	CALL	reset$chksum$fcb; Set invalid check sum
ELSE	
	CALL	reselectx
ENDIF	
	CALL	check$wild	; Check for wild chars in fcb
IF	MPM	
	CALL	get$atts
	AND	1100_0000b	; a = attributes
	CP	1100_0000b
	jp	nz,att$ok
	AND	0100_0000b	; Mask off unlock mode 
att$ok:	
	LD	(high$ext),A
	LD	B,A
	OR	A
	RRA	
	jp	nz,att$set
	LD	A,80h
att$set:	
	LD	(attributes),A
	LD	A,B
	AND	80h
	jp	nz,call$open
ENDIF	
	LD	A,(usrcode)
	OR	A
	jp	z,call$open 
	LD	A,0feh
	LD	(xdcnt+1),A
	INC	A
	LD	(search$user0),A
IF	MPM	
	LD	(sdcnt0+1),A
ENDIF	
call$open:	
	CALL	open
	CALL	openx		; returns if unsuccessful, a = 0
	LD	HL,search$user0
	CP	(HL)
	ret	z
	LD	(HL),A
	LD	A,(xdcnt+1)
	CP	0feh
	ret	z
;
;	file exists under user 0
;
IF	MPM	
	CALL	swap
ENDIF	
	CALL	set$dcnt$dblk
IF	MPM	
	LD	A,0110_0000b
ELSE	
	LD	A,80h
ENDIF	
	LD	(high$ext),A
open$user$zero:	
	; Set fcb user # to zero
	LD	HL,(info)
	LD	(HL),0
	LD	C,namlen
	CALL	searchi
	CALL	searchn
	CALL	open1		; Attempt reopen under user zero
	CALL	openx		; openx returns only if unsuccessful
	RET	
openx:	
	CALL	end$of$dir
	ret	z
	CALL	getfcba
	LD	A,(HL)
	INC	A
	jp	nz,openxa
	DEC	DE
	DEC	DE
	LD	A,(DE)
	LD	(HL),A
openxa:	
	; open successful
	POP	HL		; Discard return address
	; Was file opened under user 0 after unsuccessful
	; attempt to open under user n?
IF	MPM	
	LD	A,(high$ext)
	CP	060h
	jp	z,openx00		; yes
	; Was file opened in locked mode?
	OR	A
	jp	nz,openx0		; no
	; does user = zero?
	LD	HL,(info)
	OR	(HL)
	jp	nz,openx0		; no
	; Does file have read/only attribute set?
	CALL	rotest
	jp	nc,openx0		; no
	; Does file have system attribute set?
	INC	HL
	LD	A,(HL)
	RLA	
	jp	nc,openx0		; no
	; Force open mode to read/only mode and set user 0 flag
	; if file opened in locked mode, user = 0, and
	; file has read/only and system attributes set
openx00:	
ELSE	
	LD	A,(high$ext)
	RLA	
	jp	nc,openx0
ENDIF	
	; Is file under user 0 a system file ?
IF	MPM	
	LD	A,20h
	LD	(attributes),A
ENDIF	
	LD	HL,(info)
	LD	DE,10
	ADD	HL,DE
	LD	A,(HL)
	AND	80h
	jp	nz,openx0		; yes - open successful
	; open fails
	LD	(high$ext),A
	JP	lret$eq$ff
openx0:	
IF	MPM	
	CALL	reset$chksum$fcb
ELSE	
	CALL	set$lsn
ENDIF	
IF	BANKED
	; Are passwords enabled on drive?
	CALL	get$dir$mode
	AND	80h
	jp	z,openx1a		; no
	; Is this 1st dir fcb?
	CALL	qdirfcb1
	jp	nz,openx0a		; no
	; Does sfcb exist?
	CALL	get$dtba$8
	OR	A
	jp	nz,openx0a		; no
	; Is sfcb password mode read or write?
	LD	A,(HL)
	AND	0c0h
	jp	z,openx1a		; no
	; Does xfcb exist?
	CALL	xdcnt$eq$dcnt
	CALL	get$xfcb
	jp	nz,openx0b		; yes
	; no - set sfcb password mode to zero
	CALL	restore$dir$fcb
	ret	z		; (error)
	; Does sfcb still exist?
	CALL	get$dtba$8
	OR	A
	jp	nz,openx1a		; no (error)
	; sfcb password mode = 0
	LD	(HL),A
	; update sfcb
	CALL	nowrite
	call	z,seek$copy
	JP	openx1a
openx0a:	
	CALL	xdcnt$eq$dcnt
	; Does xfcb exist?
	CALL	get$xfcb
	jp	z,openx1		; no
openx0b:	
	; yes - check password
	CALL	cmp$pw
	jp	z,openx1
	CALL	chk$pw$error
	LD	A,(pw$mode)
	AND	0c0h
	jp	z,openx1
	AND	80h
	jp	nz,pw$error
	LD	A,080h
	LD	(xfcb$read$only),A
openx1:	
	CALL	restore$dir$fcb
	ret	z		; (error)
openx1a:	
	CALL	set$lsn
IF	MPM	
	CALL	pack$sdcnt
	; Is this file currently open?
	LD	B,3
	CALL	search$olist
	jp	z,openx04
openx01:	
	; no - is olist full?
	LD	HL,(free$root)
	LD	A,L
	OR	H
	jp	nz,openx03
	; yes - error
openx02:	
	LD	A,11
	JP	set$aret
openx03:	
	; Has process exceeded open file maximum?
	CALL	count$opens
	SUB	A,(HL)
	jp	c,openx035
	; yes - error
openx034:	
	LD	A,10
	JP	set$aret
openx035:	
	; Create new olist element
	CALL	create$olist$item
	JP	openx08
openx04:	
	; Do file attributes match?
	INC	HL
	INC	HL
	LD	A,(attributes)
	OR	(HL)
	CP	(HL)
	jp	nz,openx06
	; yes - is open mode locked?
	AND	80h
	jp	nz,openx07
	; no - has this file been opened by this process?
	LD	HL,(prv$pos)
	LD	(cur$pos),HL
	LD	B,5
	CALL	searchn$list
	jp	nz,openx01
openx05:	
	; yes - increment open file count
	LD	DE,8
	ADD	HL,DE
	INC	(HL)
	jp	nz,openx08
	; count overflow
	INC	HL
	INC	(HL)
	JP	openx08
openx06:	
	; error - file opened by another process in imcompatible mode
	LD	A,5
	JP	set$aret
openx07:	
	; Does this olist item belong to this process?
	DEC	HL
	DEC	HL
	PUSH	HL
	CALL	compare$pds
	POP	HL
	jp	nz,openx06		; no - error
	JP	openx05		; yes
openx08:	; Wopen ok
	; Was file opened in unlocked mode?
	LD	A,(attributes)
	AND	40h
	jp	z,openx09		; no
	; yes - return .olist$item in ranrec field of fcb
	CALL	get$rra
	LD	DE,cur$pos
	LD	C,2
	CALL	move
openx09:	
	CALL	set$fcb$cks$flag
	LD	A,(make$flag)
	OR	A
	ret	nz
ENDIF	
ENDIF	
	LD	C,0100_0000b
openx2:	
	CALL	qstamp
	call	z,stamp1
	LD	DE,olog
	JP	set$cdisk
func16:	
	; Close file
	CALL	reselect
IF	MPM	
	CALL	get$atts
	LD	(attributes),A
	LD	HL,close00
	PUSH	HL
	LD	A,0c9h
	LD	(check$fcb4),A
	CALL	check$fcb1
	POP	HL
	CALL	set$sdcnt
	CALL	getmodnum
	AND	80h
	jp	nz,close01
	CALL	close
	JP	close02
close00:	
	LD	A,6
	JP	set$aret
close01:	
	LD	A,0ffh
	LD	(dont$close),A
	CALL	close1
close02:	
ELSE	
	CALL	set$lsn
	CALL	chek$fcb
	CALL	close
ENDIF	
	LD	A,(lret)
	INC	A
	ret	z
	JP	flush		; Flush buffers
IF	MPM	
	LD	A,(attributes)
	RLA	
	ret	c
	CALL	pack$sdcnt
	; Find olist item for this process & file
	LD	B,5
	CALL	search$olist
	jp	nz,close03
	; Decrement open count
	PUSH	HL
	LD	DE,8
	ADD	HL,DE
	LD	A,(HL)
	SUB	A,1
	LD	(HL),A
	INC	HL
	LD	A,(HL)
	SBC	A,0
	LD	(HL),A
	DEC	HL
	; Is open count = 0ffffh
	CALL	test$ffff
	POP	HL
	jp	nz,close03
	; yes - remove file's olist entry
	LD	(file$id),HL
	CALL	delete$item
	CALL	reset$chksum$fcb
	; if unlocked file, remove file's locktbl entries
	CALL	test$unlocked
	jp	z,close03
	LD	HL,(file$id)
	CALL	remove$locks
close03:	
	RET	
ENDIF	
func17:	
	; Search for first occurrence of a file
	EX	DE,HL
	XOR	A
csearch:	
	PUSH	AF
	LD	A,(HL)
	CP	'?'
	jp	nz,csearch1	; no reselect if ?
	CALL	curselect
	CALL	noselect0
	LD	C,0
	JP	csearch3
csearch1:	
	CALL	getexta
	LD	A,(HL)
	CP	'?'
	jp	z,csearch2
	CALL	clr$ext
	CALL	clrmodnum
csearch2:	
	CALL	reselectx
	LD	C,namlen
csearch3:	
	POP	AF
	PUSH	AF
	jp	z,csearch4
	; dcnt = dcnt & 0fch
	LD	HL,(dcnt)
	PUSH	HL
	LD	A,0fch
	AND	L
	LD	L,A
	LD	(dcnt),HL
	CALL	rd$dir
	POP	HL
	LD	(dcnt),HL
csearch4:	
	POP	AF
	LD	HL,dir$to$user
	PUSH	HL
	jp	z,search
	LD	A,(searchl)
	LD	C,A
	CALL	searchi
	JP	searchn
func18:	
	; Search for next occurrence of a file name
IF	BANKED
	EX	DE,HL
	LD	(searcha),HL
ELSE	
	LD	HL,(searcha)
	LD	(info),HL
ENDIF	
	OR	1
	JP	csearch
func19:	
	; Delete a file
IF	PATCH13
	CALL	new$reselx
ELSE	
	CALL	reselectx
ENDIF	
	JP	delete
func20:	
	; Read a file
	CALL	reselect
	CALL	check$fcb
	JP	seqdiskread
func21:	
	; Write a file
	CALL	reselect
	CALL	check$fcb
	JP	seqdiskwrite
func22:	
	; Make a file
IF	BANKED
	CALL	get$atts
	LD	(attributes),A
ENDIF	
	CALL	clr$ext
	CALL	clrmodnum	; fcb mod = 0
	CALL	reselectx
IF	MPM	
	CALL	reset$chksum$fcb
ENDIF	
	CALL	check$wild
	CALL	set$xdcnt	; Reset xdcnt for make
IF	MPM	
	CALL	set$sdcnt
ENDIF	
	CALL	open		; Verify file does .NOT. already exist
IF	MPM	
	CALL	reset$chksum$fcb
ENDIF	
	; Does dir fcb for fcb exist?
	; ora a required to reset carry
	CALL	end$of$dir
	OR	A
	jp	z,makea0		; no
	; Is dir$ext < fcb(ext)?
	CALL	get$dir$ext
	CP	(HL)
	jp	nc,file$exists	; no
makea0:	
	PUSH	AF		; carry set if dir fcb already exists
IF	MPM	
	LD	A,(attributes)
	AND	80h
	RRCA	
	jp	nz,makex00
	LD	A,80h
makex00:	
	LD	(make$flag),A
	LD	A,(sdcnt+1)
	INC	A
	jp	z,makex01
	CALL	pack$sdcnt
	LD	B,3
	CALL	search$olist
	jp	z,make$x02
makex01:	
	LD	HL,(free$root)
	LD	A,L
	OR	H
	jp	z,openx02
	JP	makex03
makex02:	
	INC	HL
	INC	HL
	LD	A,(makeflag)
	AND	(HL)
	jp	z,openx06
	DEC	HL
	DEC	HL
	CALL	compare$pds
	jp	z,makex03
	LD	A,(makeflag)
	RLA	
	jp	c,openx06
makex03:	
ENDIF	
IF	BANKED
	; Is fcb 1st fcb for file?
	CALL	qdirfcb1
	jp	z,makex04		; yes
	; no - does dir lbl require passwords?
	CALL	get$dir$mode
	AND	80h
	jp	z,makex04
	; no - does xfcb exist with mode 1 or 2 password?
	CALL	get$xfcb
	jp	z,makex04
	; yes - check password
	CALL	chk$xfcb$password1
	jp	z,makex04
	; Verify password error
	CALL	chk$pw$error
	LD	A,(pw$mode)
	AND	0c0h
	jp	nz,pw$error
makex04:	
ENDIF	
	; carry on stack indicates a make .NOT. required because
	; of extent folding
	POP	AF
	call	nc,make
IF	MPM	
	CALL	reset$chksum$fcb
ENDIF	
	; end$of$dir call either applies to above make or open call
	CALL	end$of$dir
	ret	z		; Return if make unsuccessful
IF	.NOT.	MPM
	CALL	set$lsn
ENDIF	
IF	BANKED
	; Are passwords activated by dir lbl?
	CALL	get$dir$mode
	AND	80h
	jp	z,make3a
	; Did user set password attribute?
	LD	A,(attributes)
	AND	40h
	jp	z,make3a
	; Is fcb file's 1st logical fcb?
	CALL	qdirfcb1
	jp	nz,make3a
	; yes - does xfcb already exist for file
	CALL	xdcnt$eq$dcnt
	CALL	get$xfcb
	jp	nz,make00		; yes
	; Attempt to make xfcb
	LD	A,0ffh
	LD	(make$xfcb),A
	CALL	make
	jp	nz,make00
	; xfcb make failed - delete fcb that was created above
	CALL	search$namlen
	CALL	delete10
	JP	lret$eq$ff	; Return with a = 0ffh
make00:	
	CALL	init$xfcb	; Initialize xfcb
	; Get password mode from dma + 8
	EX	DE,HL
	LD	HL,(xdmaad)
	LD	BC,8
	ADD	HL,BC
	EX	DE,HL
	LD	A,(DE)
	AND	0e0h
	jp	nz,make2
	LD	A,080h		; default password mode is read protect
make2:	
	LD	(pw$mode),A
	; Set xfcb password mode field
	PUSH	AF
	CALL	get$xfcb1
	POP	AF
	LD	(HL),A
	; Set xfcb password and password checksum
	; Fix hash table and write xfcb
	CALL	set$pw
	LD	(HL),B
	CALL	sdl3
	; Return to fcb
	CALL	restore$dir$fcb
	ret	z
	; Does sfcb exist?
	LD	C,8
	CALL	get$dtba
	OR	A
	jp	nz,make3a		; no
	; Place password mode in sfcb if sfcb exists
	LD	A,(pw$mode)
	LD	(HL),A
	CALL	seek$copy
	CALL	set$lsn
ENDIF	
make3a:	
	LD	C,0101_0000b
IF	MPM	
	CALL	openx2
	LD	A,(make$flag)
	LD	(attributes),A
	AND	40h
	RLA	
	LD	(high$ext),A
	LD	A,(sdcnt+1)
	INC	A
	jp	nz,makexx02
	CALL	sdcnt$eq$xdcnt
	CALL	pack$sdcnt
	JP	openx03
makexx02:	
	CALL	fix$olist$item
	JP	openx1
	JP	set$fcb$cks$flag
ELSE	
	CALL	openx2
	LD	C,0010_0000b
	CALL	qstamp
	ret	nz
	CALL	stamp2
	JP	set$filewf
ENDIF	
file$exists:	
	LD	A,8
set$aret:	
	LD	C,A
	LD	(aret+1),A
	CALL	lret$eq$ff
IF	MPM	
	CALL	test$error$mode
	jp	nz,goback
ELSE	
	JP	goerr1
ENDIF	
IF	MPM	
	LD	A,C
	SUB	A,3
	LD	L,A
	LD	H,0
	ADD	HL,HL
	LD	DE,xerr$list
	ADD	HL,DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	JP	report$err
ENDIF	
func23:	
	; Rename a file
IF	PATCH13
	CALL	new$reselx
ELSE	
	CALL	reselectx
ENDIF	
	JP	rename
func24:	
	; Return the login vector
	LD	HL,(dlog)
	JP	sthl$ret	
func25:	
	; Return selected disk number
	LD	A,(seldsk)
	JP	sta$ret
func26:	
IF	MPM	
	; Save dma address in process descriptor
	LD	HL,(info)
intrnlsetdma:	
	EX	DE,HL
	CALL	rlr
	LD	BC,disksetdma
	ADD	HL,BC
	LD	(HL),E
	INC	HL
	LD	(HL),D
ENDIF	
	; Set the subsequent dma address to info
	EX	DE,HL
	LD	(dmaad),HL	; dmaad = info
	JP	setdata		; to data dma address
func27:	
	; Return the login vector address
	CALL	curselect
	LD	HL,(alloca)
	JP	sthl$ret
IF	MPM	
func28:	
	; Write protect current disk
	; first check for open files on disk
	LD	A,0ffh
	LD	(set$ro$flag),A
	LD	A,(seldsk)
	LD	C,A
	LD	HL,0001h
	CALL	hlrotl
	CALL	intrnldiskreset
	JP	set$ro
ELSE	
func28:	equ	set$ro		; Write protect current disk
ENDIF	
func29:	
	; Return r/o bit vector
	LD	HL,(rodsk)
	JP	sthl$ret
func30:	
	; Set file indicators
	CALL	check$wild
IF	PATCH13
	CALL	new$reselx
ELSE	
	CALL	reselectx
ENDIF	
	CALL	indicators
	JP	copy$dir$loc	; lret=dirloc
func31:	
	; Return address of disk parameter block
	CALL	curselect
	LD	HL,(dpbaddr)
sthl$ret:	
	LD	(aret),HL
	RET	
func32:	
	; Set user code
	LD	A,(linfo)
	CP	0ffh
	jp	nz,setusrcode
	; Interrogate user code instead
	LD	A,(usrcode)
	JP	sta$ret		; lret=usrcode	
setusrcode:	
	AND	0fh
	LD	(usrcode),A
IF	MPM	
	PUSH	AF
	CALL	rlr
	LD	BC,diskselect
	ADD	HL,BC
	POP	BC
	LD	A,(HL)
	AND	0f0h
	OR	B
	LD	(HL),A
ENDIF	
	RET	
func33:	
	; Random disk read operation
	CALL	reselect
	CALL	check$fcb
	JP	randiskread	; to perform the disk read
func34:	
	; Random disk write operation
	CALL	reselect
	CALL	check$fcb
	JP	randiskwrite	; to perform the disk write
func35:	
	; Return file size (0-262,144)
	CALL	reselect
	JP	getfilesize
func36:	equ	setrandom	; Set random record
func37:	
	; Drive reset
IF	MPM	
	CALL	diskreset
reset$37:	
	LD	HL,(info)
ELSE	
	EX	DE,HL
ENDIF	
reset$37x:	
	LD	A,L
	CPL	
	LD	E,A
	LD	A,H
	CPL	
	LD	HL,(dlog)
	AND	H
	LD	D,A
	LD	A,L
	AND	E
	LD	E,A
	LD	HL,(rodsk)
	EX	DE,HL
	LD	(dlog),HL
IF	MPM	
	PUSH	HL
	CALL	hl$eq$hl$and$de
ELSE	
	LD	A,L
	AND	E
	LD	L,A
	LD	A,H
	AND	D
	LD	H,A
ENDIF	
	LD	(rodsk),HL
IF	MPM	
	POP	HL
	EX	DE,HL
	LD	HL,(rlog)
	CALL	hl$eq$hl$and$de
	LD	(rlog),HL
ENDIF	
	; Force select call in next curselect
	LD	A,0ffh
	LD	(curdsk),A
	RET	
IF	MPM	
func38:	
	; Access drive
	LD	HL,packed$dcnt
	LD	A,0ffh
	LD	(HL),A
	INC	HL
	LD	(HL),A
	INC	HL
	LD	(HL),A
	XOR	A
	EX	DE,HL
	LD	BC,16
acc$drv0:	
	ADD	HL,HL
	ADC	A,B
	DEC	C
	jp	nz,acc$drv0
	OR	A
	ret	z
	LD	(mult$cnt),A
	DEC	A
	PUSH	AF
	CALL	acc$drv02
	POP	AF
	JP	openx02		; insufficient free lock list items
acc$drv02:	
	CALL	check$free
	POP	HL		; Discard return addr, free space exists
	CALL	count$opens
	POP	BC
	ADD	A,B
	jp	c,openx034
	SUB	A,(HL)
	jp	nc,openx034	; openmax exceeded
	LD	HL,(info)
	LD	A,(curdsk)
	PUSH	AF
	LD	A,16
acc$drv1:	
	DEC	A
	ADD	HL,HL
	jp	c,acc$drv2
acc$drv15:	
	OR	A
	jp	nz,acc$drv1
	POP	AF
	LD	(curdsk),A
	RET	
acc$drv2:	
	PUSH	AF
	PUSH	HL
	LD	(curdsk),A
	CALL	create$olist$item
	POP	HL
	POP	AF
	JP	acc$drv15
func39:	
	; Free drive
	LD	HL,(open$root)
	LD	A,H
	OR	L
	ret	z
	XOR	A
	LD	(incr$pdcnt),A
	INC	A
	LD	(free$mode),A
	LD	HL,(info)
	LD	A,H
	CP	L
	jp	nz,free$drv1
	INC	A
	jp	nz,free$drv1
	LD	(free$mode),A
	CALL	free$files
	JP	free$drv3
free$drv1:	
	LD	A,(curdsk)
	PUSH	AF
	LD	A,16
free$drv2:	
	DEC	A
	ADD	HL,HL
	jp	c,free$drv4
free$drv25:	
	OR	A
	jp	nz,free$drv2
	POP	AF
	LD	(curdsk),A
free$drv3:	
	LD	A,(incr$pdcnt)
	OR	A
	ret	z
	LD	A,(pdcnt)
	JP	chk$olist1
free$drv4:	
	PUSH	AF
	PUSH	HL
	LD	(curdsk),A
	CALL	free$files
	POP	HL
	POP	AF
	JP	free$drv25
ELSE	
func38:	equ	func$ret
func39:	equ	func$ret
ENDIF	
func40:	equ	func34		; Write random with zero fill
IF	MPM	
func41:	equ	func$ret	; Test & write
func42:	; Record lock
	LD	A,0ffh
	LD	(lock$unlock),A
	JP	lock
func43:	; Record unlock
	XOR	A
	LD	(lock$unlock),A
	JP	lock
ELSE	
func42:	equ	func$ret	; Record lock
func43:	equ	func$ret	; Record unlock
ENDIF	
func44:	; Set multi-sector count
	LD	A,E
	OR	A
	jp	z,lret$eq$ff
	CP	129
	jp	nc,lret$eq$ff
	LD	(mult$cnt),A
IF	MPM	
	LD	D,A
	CALL	rlr
	LD	BC,mult$cnt$off
	ADD	HL,BC
	LD	(HL),D
ENDIF	
	RET	
func45:	; Set bdos error mode
IF	MPM	
	CALL	rlr
	LD	BC,pname+4
	ADD	HL,BC
	CALL	set$pflag
	LD	(HL),A
	INC	HL
	CALL	set$pflag
	LD	(HL),A
	RET	
set$pflag:	
	LD	A,(HL)
	AND	7fh
	INC	E
	ret	nz
	OR	80h
	RET	
ELSE	
	LD	A,E
	LD	(error$mode),A
ENDIF	
	RET	
func46:	
	; Get free space
	; Perform temporary select of specified drive
	CALL	tmpselect
	LD	HL,(alloca)
	EX	DE,HL		; de = alloc vector addr
	CALL	get$nalbs	; Get # alloc blocks
	; hl = # of allocation vector bytes
	; Count # of true bits in allocation vector
	LD	BC,0		; bc = true bit accumulator
gsp1:	LD	A,(DE)
gsp2:	OR	A
	jp	z,gsp4
gsp3:	RRA	
	jp	nc,gsp3
	INC	BC
	JP	gsp2
gsp4:	INC	DE
	DEC	HL
	LD	A,L
	OR	H
	jp	nz,gsp1
	; hl = 0 when allocation vector processed
	; Compute maxall + 1 - bc
	LD	HL,(maxall)
	INC	HL
	LD	A,L
	SUB	A,C
	LD	L,A
	LD	A,H
	SBC	A,B
	LD	H,A
	; hl = # of available blocks on drive
	LD	A,(blkshf)
	LD	C,A
	XOR	A
	CALL	shl3bv
	; ahl = # of available sectors on drive
	; Store ahl in beginning of current dma
	EX	DE,HL
	LD	HL,(xdmaad)
	LD	(HL),E
	INC	HL
	LD	(HL),D
	INC	HL
	LD	(HL),A
	RET	
IF	MPM	
func47:	equ	func$ret
ELSE	
func47:	; Chain to program
	LD	HL,ccp$flgs
	LD	A,(HL)
	OR	80h
	LD	(HL),A
	INC	E
	jp	nz,rebootx1
	LD	A,(HL)
	OR	40h
	LD	(HL),A
	JP	rebootx1
ENDIF	
func48:	; Flush buffers
	CALL	check$all$media
	CALL	flushf
	CALL	diocomp
flush0:	; Function 98 entry point
	LD	HL,(dlog)
	LD	A,16
flush1:	
	DEC	A
	ADD	HL,HL
	jp	nc,flush5
	PUSH	AF
	PUSH	HL
	LD	E,A
	CALL	tmpselect	; seldsk = e
	LD	A,(fx)
	CP	48
	jp	z,flush3
	; Function 98 - reset allocation
	; Copy 2nd ALV over 1st ALV
IF	PATCH13 .and. BANKED
	CALL	copy$alv
	JP	new$flush35
ELSE	
	CALL	copy$alv
	JP	flush35
ENDIF	
;
flush3:	
	CALL	flushx
	; if e = 0ffh then discard buffers after possible flush
	LD	A,(linfo)
	INC	A
	jp	nz,flush4
flush35:	
	CALL	discard$data
flush4:	
	POP	HL
	POP	AF
flush5:	
	OR	A
	jp	nz,flush1
	RET	
flush:	
	CALL	flushf
	CALL	diocomp
flushx:	
	LD	A,(phymsk)
	OR	A
	ret	z
	LD	A,4
	JP	deblock$dta
IF	MPM	
func49:	equ	func$ret
ELSE	
func49:	; Get/Set system control block
	EX	DE,HL
	LD	A,(HL)
	CP	99
	ret	nc
	EX	DE,HL
	LD	HL,SCB
	ADD	A,L
	LD	L,A
	EX	DE,HL
	INC	HL
	LD	A,(HL)
	CP	0feh
	jp	nc,func49$set
	EX	DE,HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	JP	sthl$ret
func49$set:	
	LD	B,A
	INC	HL
	LD	A,(HL)
	LD	(DE),A
	INC	B
	ret	z
	INC	HL
	INC	DE
	LD	A,(HL)
	LD	(DE),A
	RET	
ENDIF	
IF	MPM	
func50:	equ	func$ret
ELSE	
func50:	; Direct bios call
	; de -> function (1 byte)
	;       a  value (1 byte)
	;       bc value (2 bytes)
	;       de value (2 bytes)
	;       hl value (2 bytes)
	LD	HL,func50$ret
	PUSH	HL
	EX	DE,HL
IF	BANKED
	LD	A,(HL)
	CP	27
	ret	z
	CP	12
	jp	nz,dir$bios1
	LD	DE,dir$bios3
	PUSH	DE
dir$bios1:	
	CP	9
	jp	nz,dir$bios2
	LD	DE,dir$bios4
	PUSH	DE
dir$bios2:	
ENDIF	
	PUSH	HL
	INC	HL
	INC	HL
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	EX	(SP),HL
	LD	A,(HL)
	PUSH	HL
	LD	L,A
	ADD	A,A
	ADD	A,L
	LD	HL,bios
	ADD	A,L
	LD	L,A
	EX	(SP),HL
	INC	HL
	LD	A,(HL)
	POP	HL
	EX	(SP),HL
	RET	
IF	BANKED
dir$bios3:	
	LD	A,1
	JP	setbnkf
dir$bios4:	
	LD	A,L
	OR	H
	ret	z
	EX	DE,HL
	LD	HL,10
	ADD	HL,DE
	LD	(HL),0		; Zero login sequence #
	LD	HL,(common$base)
	CALL	subdh
	EX	DE,HL
	ret	nc
	; Copy DPH to common memory
	EX	DE,HL
	LD	HL,(info)
	INC	HL
	PUSH	HL
	LD	BC,25
	CALL	movef
	POP	HL
	RET	
ENDIF	
func50$ret:	
IF	BANKED
	LD	(aret),HL
	LD	B,A
	LD	HL,(info)
	LD	A,(HL)
	CP	9
	ret	z
	CP	16
	ret	z
	CP	20
	ret	z
	CP	22
	ret	z
	LD	A,B
	JP	sta$ret
ELSE	
	EX	DE,HL
	LD	HL,(entsp)
	LD	SP,HL
	EX	DE,HL
	RET	
ENDIF	
ENDIF	
func98:	equ	flush0		; Reset Allocation
func99:	; Truncate file
	CALL	reselectx
	CALL	check$wild
IF	BANKED
	CALL	chk$password
	call	nz,chk$pw$error
ENDIF	
	LD	C,true
	CALL	rseek
	jp	nz,lret$eq$ff
	; compute dir$fcb size
	CALL	getdptra
	LD	DE,reccnt
	CALL	compute$rr	; cba = fcb size
	; Is random rec # >= dir$fcb size
	CALL	get$rra
	CALL	compare$rr
	jp	c,lret$eq$ff	; yes ( > )
	OR	D
	jp	z,lret$eq$ff	; yes ( = )
	; Perform truncate
	CALL	check$rodir	; may be r/o file
	CALL	wrdir		; verify BIOS can write to disk
	CALL	update$stamp	; Set update stamp
	CALL	search$extnum
trunc1:	
	jp	z,copy$dir$loc
	; is dirfcb < fcb?
	CALL	compare$mod$ext
	jp	c,trunc2		; yes
	; remove dirfcb blocks from allocation vector
	PUSH	AF
	LD	C,0
	CALL	scandm$ab
	POP	AF
	; is dirfcb = fcb?
	jp	z,trunc3		; yes
	; delete dirfcb
	CALL	getdptra
	LD	(HL),empty
	CALL	fix$hash
trunc15:	
	CALL	wrdir
trunc2:	
	CALL	searchn
	JP	trunc1
trunc3:	
	CALL	getfcb
	CALL	dm$position
	CALL	zero$dm
	; fcb(extnum) = dir$ext after blocks removed
	CALL	get$dir$ext
	CP	(HL)
	LD	(HL),A
	PUSH	AF
	; fcb(rc) = fcb(cr) + 1
	CALL	getfcba
	LD	A,(HL)
	INC	A
	LD	(DE),A
	; rc = 0 or 128 if dir$ext < fcb(extnum)
	POP	AF
	EX	DE,HL
	call	nz,set$rc3
	; rc = 0 if no blocks remain in fcb
	LD	A,(dminx)
	OR	A
	call	z,set$rc3
	LD	BC,11
	CALL	get$fcb$adds
	EX	DE,HL
	; reset archive (t3') attribute bit
	LD	A,(HL)
	AND	7fh
	LD	(HL),A
	INC	HL
	INC	DE
	; dirfcb(extnum) = fcb(extnum)
	LD	A,(DE)
	LD	(HL),A
	; advance to .fcb(reccnt) & .dirfcb(reccnt)
	INC	HL
	LD	(HL),0
	INC	HL
	INC	HL
	INC	DE
	INC	DE
	INC	DE
	; dirfcb_rc+dskmap = fcb_rc+dskmap
	LD	C,17
	CALL	move
	; restore non-erased blkidxs in allocation vector
	LD	C,1
	CALL	scandm$ab
	JP	trunc15
get$fcb$adds:	
	CALL	getdptra
	ADD	HL,BC
	EX	DE,HL
	LD	HL,(info)
	ADD	HL,BC
	RET	
compare$mod$ext:	
	LD	BC,modnum
	CALL	get$fcb$adds
	LD	A,(HL)
	AND	3fh
	LD	B,A
	; compare dirfcb(modnum) to fcb(modnum)
	LD	A,(DE)
	CP	B
	ret	nz		; dirfcb(modnum) ~= fcb(modnum)
	DEC	HL
	DEC	HL
	DEC	DE
	DEC	DE
	; compare dirfcb(extnum) to fcb(extnum)
	LD	A,(DE)
	LD	C,(HL)
	CALL	compext
	ret	z		; dirfcb(extnum) = fcb(extnum)
	LD	A,(DE)
	CP	(HL)
	RET	
zero$dm:	
	INC	A
	LD	HL,single
	INC	(HL)
	jp	z,zero$dm1
	ADD	A,A
zero$dm1:	
	DEC	(HL)
	CALL	getdma
	LD	C,A
	LD	B,0
	ADD	HL,BC
	LD	A,16
zero$dm2:	
	CP	C
	ret	z
	LD	(HL),B
	INC	HL
	INC	C
	JP	zero$dm2
IF	BANKED
func100:	; Set directory label
	; de -> .fcb
	;       drive location
	;       name & type fields user's discretion
	;       extent field definition
	;       bit 1 (80h): enable passwords on drive
	;       bit 2 (40h): enable file access 	
	;       bit 3 (20h): enable file update stamping
	;       bit 4 (10h): enable file create stamping
	;       bit 8 (01h): assign new password to dir lbl
	CALL	reselectx
	LD	HL,(info)
	LD	(HL),21h
	LD	C,1
	CALL	search
	jp	nz,sdl0
	CALL	getexta
	LD	A,(HL)
	AND	0111_0000b
	jp	nz,lret$eq$ff
sdl0:	
	; Does dir lbl exist on drive?
	LD	HL,(info)
	LD	(HL),20h
	LD	C,1
	CALL	set$xdcnt
	CALL	search
	jp	nz,sdl1
	; no - make one
	LD	A,0ffh
	LD	(make$xfcb),A
	CALL	make
	ret	z		; no dir space
	CALL	init$xfcb
	LD	BC,24
	CALL	stamp5
	CALL	stamp1 
sdl1:	
	; Update date & time stamp
	LD	BC,28
	CALL	stamp5
	CALL	stamp2
	; Verify password - new dir lbl falls through
	CALL	chk$xfcb$password
	jp	nz,pw$error
	LD	BC,0
	CALL	init$xfcb0
	; Set dir lbl dta in extent field
	LD	A,(DE)
	OR	1h
	LD	(HL),A
	; Low bit of dir lbl data set to indicate dir lbl exists
	; Update drive's dir lbl vector element
	PUSH	HL
	LD	HL,(drvlbla)
	LD	(HL),A
	POP	HL
sdl2:	
	; Assign new password to dir lbl or xfcb?
	LD	A,(DE)
	AND	1
	jp	z,sdl3
	; yes - new password field is in 2nd 8 bytes of dma
	LD	DE,8
	CALL	adjust$dmaad
	CALL	set$pw
	LD	(HL),B
	LD	DE,-8
	CALL	adjust$dmaad
sdl3:	
	CALL	fix$hash
	JP	seek$copy
ELSE	
func100:	equ	lret$eq$ff
func103:	equ	lret$eq$ff
ENDIF	
func101:	
	; Return directory label data
	; Perform temporary select of specified drive
	CALL	tmpselect
	CALL	get$dir$mode
	JP	sta$ret
func102:	
	; Read file xfcb
	CALL	reselectx
	CALL	check$wild
	CALL	zero$ext$mod
	CALL	search$namlen
	ret	z
	CALL	getdma
	LD	BC,8
	CALL	zero
	PUSH	HL
	LD	C,0
	CALL	get$dtba
	OR	A
	jp	nz,rxfcb2
	POP	DE
	EX	DE,HL
	LD	C,8
IF	BANKED
	CALL	move
	LD	A,(DE)
	JP	rxfcb3
ELSE	
	JP	move
ENDIF	
rxfcb2:	
	POP	HL
	LD	BC,8
IF	BANKED
	CALL	zero
	CALL	get$xfcb
	ret	z
	LD	A,(HL)
rxfcb3:	
	CALL	getexta
	LD	(HL),A
	RET	
ELSE	
	JP	zero
ENDIF	
IF	BANKED
func103:	
	; Write or update file xfcb
	CALL	reselectx
	; Are passwords enabled in directory label?
	CALL	get$dir$mode
	RLA	
	jp	nc,lret$eq$ff	; no
	CALL	check$wild
	; Save .fcb(ext) & ext
	CALL	getexta
	LD	B,(HL)
	PUSH	HL
	PUSH	BC
	; Set extent & mod to zero
	CALL	zero$ext$mod
	; Does file's 1st fcb exist in directory?
	CALL	search$namlen
	; Restore extent
	POP	BC
	POP	HL
	LD	(HL),B
	ret	z		; no
	CALL	set$xdcnt
	; Does sfcb exist?
	CALL	get$dtba$8
	OR	A
	jp	z,wxfcb5		; yes
	; No - Does xfcb exist?
	CALL	get$xfcb
	jp	nz,wxfcb1		; yes
wxfcb0:	
	; no - does file exist in directory?
	LD	A,0ffh
	LD	(make$xfcb),A
	CALL	search$extnum
	ret	z
	; yes - attempt to make xfcb for file
	CALL	make
	ret	z		; no dir space
	; Initialize xfcb
	CALL	init$xfcb
wxfcb1:	
	; Verify password - new xfcb falls through
	CALL	chk$xfcb$password
	jp	nz,pw$error
	; Set xfcb options data
	PUSH	HL
	CALL	getexta
	POP	DE
	EX	DE,HL
	LD	A,(HL)
	OR	A
	jp	nz,wxfcb2
	LD	A,(DE)
	AND	1
	jp	nz,wxfcb2
	CALL	sdl3
	JP	wxfcb4
wxfcb2:	
	LD	A,(DE)
	AND	0e0h
	jp	nz,wxfcb3
	LD	A,80h
wxfcb3:	
	LD	(HL),A
	CALL	sdl2
wxfcb4:	
	CALL	get$xfcb1
	DEC	A
	LD	(pw$mode),A
	CALL	zero$ext$mod
	CALL	search$namlen
	ret	z
	CALL	get$dtba$8
	OR	A
	ret	nz
	LD	A,(pw$mode)
	LD	(HL),A
	JP	seek$copy
wxfcb5:	
	; Take sfcb's password mode over xfcb's mode
	LD	A,(HL)
	PUSH	AF
	CALL	get$xfcb
	; does xfcb exist?
	POP	BC
	jp	z,wxfcb0		; no
	; Set xfcb's password mode to sfcb's mode
	LD	(HL),B
	JP	wxfcb1
ENDIF	
func104:	; Set current date and time
IF	MPM	
	CALL	get$stamp$add
ELSE	
	LD	HL,stamp
ENDIF	
	CALL	copy$stamp
	LD	(HL),0
	LD	C,0ffh
	JP	timef
func105:	; Get current date and time
IF	MPM	
	CALL	get$stamp$add
ELSE	
	LD	C,0
	CALL	timef
	LD	HL,stamp
ENDIF	
	EX	DE,HL
	CALL	copy$stamp
	LD	A,(DE)
	JP	sta$ret
copy$stamp:	
	LD	C,4
	JP	move		; ret
IF	MPM	
get$stamp$add:	
	CALL	rlradr
	LD	BC,-5
	ADD	HL,BC
	RET	
ENDIF	
IF	BANKED
func106:	; Set default password
IF	MPM	
	CALL	get$df$pwa
	INC	A
	ret	z
	LD	BC,7
	ADD	HL,BC
ELSE	
	LD	HL,df$password+7
ENDIF	
	EX	DE,HL
	LD	BC,8
	PUSH	HL
	JP	set$pw0
ELSE	
func106:	equ	func$ret
ENDIF	
func107:	; Return serial number
IF	MPM	
	LD	HL,(sysdat)
	LD	L,181
ELSE	
	LD	HL,serial
ENDIF	
	EX	DE,HL
	LD	C,6
	JP	move
func108:	; Get/Set program return code
	; Is de = 0ffffh?
	LD	A,D
	AND	E
	INC	A
	LD	HL,(clp$errcde)
	jp	z,sthl$ret	; yes - return return code
	EX	DE,HL
	LD	(clp$errcde),HL
	RET			; no - set return code
goback0:	
	LD	HL,0ffffh
	LD	(aret),HL
goback:	
	; Arrive here at end of processing to return to user
	LD	A,(resel)
	OR	A
	jp	z,retmon
IF	MPM	
	LD	A,(comp$fcb$cks)
	OR	A
	call	nz,set$chksum$fcb
ENDIF	
	LD	HL,(info)
	LD	A,(fcbdsk)
	LD	(HL),A		; fcb(0)=fcbdsk
IF	BANKED
	; fcb(7) = fcb(7) | xfcb$read$only
	LD	DE,7
	ADD	HL,DE
	LD	A,(xfcb$read$only)
	OR	(HL)
	LD	(HL),A
ENDIF	
IF	MPM	
	; if high$ext = 60h then fcb(8) = fcb(8) | 80h
	;                   else fcb(ext) = fcb(ext) | high$ext
	CALL	getexta
	LD	A,(high$ext)
	CP	60h
	jp	nz,goback2
	LD	DE,-4
	ADD	HL,DE
	LD	A,80h
goback2:	
	OR	(HL)
	LD	(HL),A
ELSE	
	; fcb(8) = fcb(8) | high$ext
IF	BANKED
	INC	HL
ELSE	
	LD	DE,8
	ADD	HL,DE
ENDIF	
	LD	A,(high$ext)
	OR	(HL)
	LD	(HL),A
ENDIF	
;	return from the disk monitor
retmon:	
	LD	HL,(entsp)
	LD	SP,HL
	LD	HL,(aret)
	LD	A,L
	LD	B,H
	RET	
;
;	data areas
;
efcb:	DB	empty		; 0e5=available dir entry
rodsk:	DW	0		; read only disk vector
dlog:	DW	0		; logged-in disks
IF	MPM	
rlog:	DW	0		; removeable logged-in disks
tlog:	DW	0		; removeable disk test login vector
ntlog:	DW	0		; new tlog vector
rem$drv:	DS	byte	; curdsk removable drive switch
	; 0 = permanent drive, 1 = removable drive
ENDIF	
IF	.NOT.	BANKED
xdmaad:		equ	curdma;	equ	$
curdma:	DS	word		; current dma address
ENDIF	
IF	.NOT.	MPM
buffa:	DS	word		; pointer to directory dma address
ENDIF	
;
;	curtrka - alloca are set upon disk select
;	(data must be adjacent, do .NOT. insert variables)
;	(address of translate vector, .NOT. used)
cdrmaxa:	DS	word	; pointer to cur dir max value (2 bytes)
curtrka:	DS	word	; current track address (2)
curreca:	DS	word	; current record address (3)
drvlbla:	DS	word	; current drive label byte address (1)
lsn$add:	DS	word	; login sequence # address (1)
	; +1 -> bios media change flag (1)
dpbaddr:	DS	word	; current disk parameter block address
checka:		DS	word	; current checksum vector address
alloca:		DS	word	; current allocation vector address
dirbcba:	DS	word	; dir bcb list head
dta$bcba:	DS	word	; data bcb list head
hash$tbla:	
		DS	word	; directory hash table address
		DS	byte	; directory hash table bank
addlist:	equ	13 ;$-dpbaddr; address list size
;
; 	       buffer control block format
;
; bcb format : drv(1) || rec(3) || pend(1) || sequence(1) ||
;	       0         1         4          5
;
;	       track(2) || sector(2) || buffer$add(2) ||
;	       6           8            10
;
;	       bank(1) || link(2)
;	       12         13
;
;	sectpt - offset obtained from disk parm block at dpbaddr
;	(data must be adjacent, do .NOT. insert variables)
sectpt:	DS	word		; sectors per track
blkshf:	DS	byte		; block shift factor
blkmsk:	DS	byte		; block mask
extmsk:	DS	byte		; extent mask
maxall:	DS	word		; maximum allocation number
dirmax:	DS	word		; largest directory number
dirblk:	DS	word		; reserved allocation bits for directory
chksiz:	DS	word		; size of checksum vector
offset:	DS	word		; offset tracks at beginning
physhf:	DS	byte		; physical record shift
phymsk:	DS	byte		; physical record mask
dpblist:	equ	17 ;$-sectpt; size of area
;
;	local variables
;
drec:	DS	word		; directory record number
blk$off:	DS	byte	; record offset within block
last$off:	DS	byte	; last offset within new block
last$drive:	DS	byte	; drive of last new block
last$block:	DS	word	; last new block
; The following two variables are initialized as a pair on entry
dir$cnt:	DS	byte	; direct i/o count
mult$num:	DS	byte	; multi-sector number
tranv:	DS	word		; address of translate vector
lock$unlock:	
make$flag:	
rmf:	DS	byte		; read mode flag for open$reel
incr$pdcnt:	
dirloc:	DS	byte		; directory flag in rename, etc.
free$mode:	
linfo:	DS	byte		; low(info)
dminx:	DS	byte		; local for diskwrite
IF	MPM	
searchl:	DS	byte	; search length
ENDIF	
IF	BANKED
searcha:	DS	word	; search address
ENDIF	
IF	BANKED
save$xfcb:	
	DS	byte		; search xfcb save flag
ENDIF	
single:	DS	byte		; set true if single byte allocation map
IF	MPM	
seldsk:	DS	byte		; currently selected disk 
ENDIF	
seldsk:	DS	byte		; disk on entry to bdos
rcount:	DS	byte		; record count in current fcb
extval:	DS	byte		; extent number and extmsk
save$mod:	
	DS	byte		; open$reel module save field
vrecord:	DS	byte	; current virtual record
IF	.NOT.	MPM
curdsk:	DB	0ffh		; current disk
ENDIF	
adrive:	DB	0ffh		; current blocking/deblocking disk
arecord:	DS	word	; current actual record
	DS	byte
save$ranr:	DS	3	; random record save area
arecord1:	DS	word	; current actual block# * blkmsk
attributes:	DS	byte	; make attribute hold area
readf$sw:	DS	byte	; BIOS read/write switch
;******** following variable order critical *****************
IF	MPM	
mult$cnt:	DS	byte	; multi-sector count
pdcnt:	DS	byte		; process descriptor count
ENDIF	
high$ext:	DS	byte	; fcb high ext bits
IF	BANKED
xfcb$read$only:	DS	byte	; xfcb read only flag
ENDIF	
IF	MPM	
curdsk:	DB	0ffh		;current disk
packed$dcnt:	DS	3	;
pdaddr:	DS	word		;
;************************************************************
cur$pos:	DS	word	;
prv$pos:	DS	word	;
sdcnt:	DS	word		;
sdblk:	DS	word		;
sdcnt0:	DS	word		;
sdblk0:	DS	word		;
dont$close:	DS	byte	;
open$cnt:	; mp/m temp variable for open
lock$cnt:	DS	word	; mp/m temp variable for lock
file$id:	DS	word	; mp/m temp variable for lock
deleted$files:	DS	byte
lock$shell:	DS	byte
lock$sp:	DS	word
set$ro$flag:	DS	byte
check$disk:	DS	byte
flushed:	DS	byte
fcb$cks$valid:	DS	byte
;				mp/m variables  *
ENDIF	
;	local variables for directory access
dptr:	DS	byte		; directory pointer 0,1,2,3
save$hash:	DS	4	; hash code save area
IF	BANKED
copy$cr$init:	DS	byte	; copy$cr$only initialization value
ELSE	
hashmx:	DS	word		; cdrmax or dirmax
xdcnt:	DS	word		; empty directory dcnt
ENDIF	
IF	MPM	
xdcnt:	DS	word		; empty directory dcnt
xdblk:	DS	word		; empty directory block
dcnt:	DS	word		; directory counter 0,1,...,dirmax
dblk:	DS	word		; directory block index
ENDIF	
search$user0:	DS	byte	; search user 0 for file (open)
user0$pass:	DS	byte	; search user 0 pass flag
fcbdsk:	DS	byte		; disk named in fcb
IF	MPM	
make$xfcb:	DS	1
find$xfcb:	DS	1
ENDIF	
log$fxs:	DB	15,16,17,19,22,23,30,35,99,100,102,103,0
rw$fxs:	DB	20,21,33,34,40,41,0
sc$fxs:	DB	16,18,0
IF	MPM	
comp$fcb$cks:	DS	byte	; compute fcb checksum flag
ENDIF	
IF	BANKED
pw$fcb:	DS	12		;1 |
	DB	0		;2 |
pw$mode:	DB	0	;3 |- Order critical
	DB	0		;4 |
	DB	0		;5 |
df$password:	DS	8
IF	MPM	
	DS	120
ENDIF	
ENDIF	
phy$off:	DS	byte
curbcba:	DS	word
IF	BANKED
lastbcba:	DS	word
rootbcba:	DS	word
emptybcba:	DS	word
seqbcba:	DS	word
buffer$bank:	DS	byte
ENDIF	
track:	DS	word
sector:	DS	word
; 	**************************
; 	Blocking/Deblocking Module
;	**************************
deblock$dta:	
	LD	HL,(dta$bcba)
IF	BANKED
	CP	4
	jp	nz,deblock
deblock$flush:	
	; de = addr of 1st bcb
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	; Search for dirty bcb with lowest track #
	LD	HL,0ffffh
	LD	(track),HL
	EX	DE,HL
deblock$flush1:	
	; Does current drive own bcb?
	LD	A,(adrive)
	CP	(HL)
	jp	nz,deblock$flush2	;no
	; Is bcb's buffer pending?
	EX	DE,HL
	LD	HL,4
	ADD	HL,DE
	LD	A,(HL)
	EX	DE,HL
	INC	A
	jp	nz,deblock$flush2	; no
	; Is bcb(6) < track?
	PUSH	HL
	INC	DE
	INC	DE
	EX	DE,HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	; Subdh computes hl = de - hl
	LD	HL,(track)
	CALL	subdh
	POP	HL
	jp	nc,deblock$flush2	; no
	; yes - track = bcb(6) , sector = addr(bcb)
	EX	DE,HL
	LD	(track),HL
	EX	DE,HL
	LD	(sector),HL
deblock$flush2:	
	; Is this the last bcb?
	CALL	get$next$bcba
	jp	nz,deblock$flush1	; no - hl = addr of next bcb
	; Does track = ffff?
	LD	HL,track
	CALL	test$ffff
	ret	z		; yes - no bcb to flush
	; Flush bcb located by sector
	LD	HL,(sector)
	XOR	A
	LD	A,4
	CALL	deblock
	LD	HL,(dta$bcba)
	JP	deblock$flush	; Repeat until no bcb's to flush
ENDIF	
deblock:	
	; BDOS Blocking/Deblocking routine
	; a = 1 -> read command
	; a = 2 -> write command
	; a = 3 -> locate command
	; a = 4 -> flush command
	; a = 5 -> directory update
	PUSH	AF		; Save z flag and deblock fx
	; phy$off = low(arecord) & phymsk
	; low(arecord) = low(arecord) & ~phymsk
	CALL	deblock8
	LD	A,(arecord)
	LD	E,A
	AND	B
	LD	(phy$off),A
	LD	A,E
	AND	C
	LD	(arecord),A
IF	BANKED
	POP	AF
	PUSH	AF
	call	nz,get$bcba
ENDIF	
	LD	(curbcba),HL
	CALL	get$buffa
	LD	(curdma),HL
	; hl = curbcba, de = .adrive, c = 4
	CALL	deblock9
	; Is BCB discarded?
	LD	A,(HL)
	INC	A
	jp	z,deblock2	; yes
	; Is command flush?
	POP	AF
	PUSH	AF
	CP	4
	jp	nc,deblock1	; yes
	; Is referenced physical record already in buffer?
IF	PATCH7 .and. .NOT. BANKED
	CALL	new$compare
	jp	z,deblock45	; yes
ENDIF	
IF	UNDOC	.and. BANKED
	CALL	undoc2
	jp	z,deblock45	; yes
ENDIF	
IF	.NOT.	PATCH7 .and. .NOT. BANKED .or. .NOT. UNDOC .and. BANKED
	CALL	compare
	jp	z,deblock45	; yes
ENDIF	
	XOR	A
deblock1:	
	; Does buffer contain an updated record?
	CALL	deblock10
	CP	5
	jp	z,deblock15
	LD	A,(HL)
	OR	A
	jp	z,deblock2	; no
deblock15:	
	; Reset record pending flag
	LD	(HL),0
	; Save arecord
	LD	HL,(arecord)
	PUSH	HL
	LD	A,(arecord+2)
	PUSH	AF
	; Flush physical record buffer
	CALL	deblock9
	EX	DE,HL
	CALL	move
	; Select drive to be flushed
	LD	HL,curdsk
	LD	A,(adrive)
	CP	(HL)
	call	nz,disk$select1
	; Write record if drive logged-in
	LD	A,1
	call	z,deblock$io
	; Restore arecord
	POP	BC
	POP	DE
	CALL	set$arecord
	; Restore selected drive
	CALL	curselect
deblock2:	
	; Is deblock command flush | dir write?
	POP	AF
	CP	4
	ret	nc		; yes - return
	; Is deblock command write?
	PUSH	AF
	CP	2
	jp	nz,deblock25	; no
	; Is blk$off < last$off
	LD	HL,last$off
	LD	A,(blk$off)
	CP	(HL)
	jp	nc,deblock3	; no
deblock25:	
	; Discard BCB on read operations in case 
	; I/O error occurs
IF	PATCH7 .and. .NOT. BANKED
	CALL	new$curbcba
	LD	(HL),0ffh
ENDIF	
;
IF	UNDOC	.and. BANKED
	CALL	undoc3
	LD	(HL),0ffh
ENDIF	
IF	.NOT.	PATCH7 .and. .NOT. BANKED .or. .NOT. UNDOC .and. BANKED
	LD	HL,(curbcba)
	LD	(HL),0ffh
ENDIF	
	; Read physical record buffer
	LD	A,2
	JP	deblock35
deblock3:	
	; last$off = blk$off + 1
	INC	A
	LD	(HL),A
	; Place track & sector in bcb
	XOR	A
deblock35:	
	CALL	deblock$io
deblock4:	
	CALL	deblock9	; phypfx = adrive || arecord
	CALL	move
	LD	(HL),0		; zero pending flag
IF	BANKED
	; Zero logical record sequence
	INC	HL
	CALL	set$bcb$seq
ENDIF	
deblock45:	
	; recadd = phybuffa + phy$off*80h
	LD	A,(phy$off)
	INC	A
	LD	DE,80h
	LD	HL,0ff80h
deblock5:	
	ADD	HL,DE
	DEC	A
	jp	nz,deblock5
	EX	DE,HL
	LD	HL,(curdma)
	ADD	HL,DE
	; If deblock command = locate then buffa = recadd; return
	POP	AF
	CP	3
	jp	nz,deblock6
	LD	(buffa),HL
	RET	
deblock6:	
	EX	DE,HL
	LD	HL,(dmaad)
	LD	BC,80h
	; If deblock command = read
	CP	1
IF	BANKED
	jp	nz,deblock7
	; then move to tpa
	LD	A,(common$base+1)
	DEC	A
	CP	D
	jp	c,move$tpa
	LD	A,(buffer$bank)
	LD	C,A
	LD	B,1
	CALL	deblock12
	LD	BC,80h
	JP	move$tpa
deblock7:	
ELSE	
	jp	z,move$tpa	; then move to dma
ENDIF	
	; else move from dma
	EX	DE,HL
IF	BANKED
	LD	A,(common$base+1)
	DEC	A
	CP	H
	jp	c,deblock75
	LD	A,(buffer$bank)
	LD	B,A
	LD	C,1
	CALL	deblock12
	LD	BC,80h
deblock75:	
ENDIF	
	CALL	move$tpa
	; Set physical record pending flag for write command
	CALL	deblock10
	LD	(HL),0ffh
	RET	
deblock8:	
	LD	A,(phymsk)
	LD	B,A
	CPL	
	LD	C,A
	RET	
deblock9:	
	LD	HL,(curbcba)
	LD	DE,adrive
	LD	C,4
	RET	
deblock10:	
	LD	DE,4
deblock11:	
	LD	HL,(curbcba)
	ADD	HL,DE
	RET	
IF	BANKED
deblock12:	
	PUSH	HL
	PUSH	DE
	CALL	xmovef
	POP	DE
	POP	HL
	RET	
ENDIF	
deblock$io:	
	; a = 0 -> seek only
	; a = 1 -> write
	; a = 2 -> read
	PUSH	AF
	CALL	seek
IF	BANKED
	LD	A,(buffer$bank)
	CALL	setbnkf
ENDIF	
	LD	C,1
	POP	AF
	DEC	A
	jp	z,wrbuff
	call	p,rdbuff
	; Move track & sector to bcb
	CALL	deblock10
	INC	HL
	INC	HL
	LD	DE,track
	LD	C,4
	JP	move
IF	BANKED
get$bcba:	
IF	PATCH13 .and. BANKED
	CALL	new$rootbcba
ELSE	
	LD	(rootbcba),HL
ENDIF	
	LD	DE,-13
	ADD	HL,DE
	LD	(lastbcba),HL
	CALL	get$next$bcba
	PUSH	HL
	; Is there only 1 bcb in list?
	CALL	get$next$bcba
	POP	HL
	ret	z		; yes - return
	EX	DE,HL
	LD	HL,0
	LD	(emptybcba),HL
	LD	(seqbcba),HL
	EX	DE,HL
get$bcb1:	
	; Does bcb contain requested record?
	LD	(curbcba),HL
	CALL	deblock9
	CALL	compare
	jp	z,get$bcb4	; yes
	; Is bcb discarded?
	LD	HL,(curbcba)
	LD	A,(HL)
	INC	A
	jp	nz,get$bcb11	; no
	EX	DE,HL
	LD	HL,(lastbcba)
	LD	(emptybcba),HL
	JP	get$bcb14
get$bcb11:	
	; Does bcb contain record from current disk?
	LD	A,(adrive)
	CP	(HL)
	jp	nz,get$bcb15	; no
	EX	DE,HL
	LD	HL,5
	ADD	HL,DE
	LD	A,(phymsk)
	; Is phymsk = 0?
	OR	A
	jp	z,get$bcb14	; yes
	; Does bcb(5) [bcb sequence] = phymsk?
	CP	(HL)
	jp	nz,get$bcb14	; no
IF	PATCH13 .and. BANKED 
	LD	A,(new$bcba)
	OR	A
	nop	
	jp	nz,get$bcb14
ELSE	
	LD	HL,(seqbcba)
	LD	A,L
	OR	H
	jp	nz,get$bcb14
ENDIF	
	LD	HL,(lastbcba)
	LD	(seqbcba),HL
get$bcb14:	
	EX	DE,HL
get$bcb15:	
	; Advance to next bcb - list exhausted?
	PUSH	HL
	CALL	get$next$bcba
	POP	DE
	jp	z,get$bcb2	; yes
	EX	DE,HL
	LD	(lastbcba),HL
	EX	DE,HL
	JP	get$bcb1
get$bcb2:	
	; Matching bcb not found
IF	PATCH13 .and. BANKED
	; Was a sequentially accessed bcb encountered?
	LD	HL,(emptybcba)
	LD	A,L
	OR	H
	jp	nz,get$bcb25	; yes
	; Was a discarded bcb encountered?
	LD	HL,(seqbcba)
	LD	A,L
	OR	H
	jp	z,get$bcb3	; no
ELSE	
	; Was a sequentially accessed bcb encountered?
	LD	HL,(seqbcba)
	LD	A,L
	OR	H
	jp	nz,get$bcb25	; yes
	; Was a discarded bcb encountered?
	LD	HL,(emptybcba)
	LD	A,L
	OR	H
	jp	z,get$bcb3	; no
ENDIF	
get$bcb25:	
	LD	(lastbcba),HL
get$bcb3:	
	; Insert selected bcb at head of list
	LD	HL,(lastbcba)
	CALL	get$next$bcba
	LD	(curbcba),HL
	CALL	get$next$bcba
	EX	DE,HL
	CALL	last$bcb$links$de
	LD	HL,(rootbcba)
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	HL,(curbcba)
	LD	BC,13
	ADD	HL,BC
	LD	(HL),E
	INC	HL
	LD	(HL),D
	LD	HL,(curbcba)
	EX	DE,HL
	LD	HL,(rootbcba)
	LD	(HL),E
	INC	HL
	LD	(HL),D
	EX	DE,HL
	RET	
get$bcb4:	
	; BCB matched arecord
	LD	HL,(curbcba)
	LD	DE,5
	ADD	HL,DE
	; Does bcb(5) = phy$off?
	LD	A,(phy$off)
	CP	(HL)
	jp	z,get$bcb5	; yes
	; Does bcb(5) + 1 = phy$off?
	INC	(HL)
	CP	(HL)
	jp	z,get$bcb5	; yes
	CALL	set$bcb$seq
get$bcb5:	
	; Is bcb at head of list?
	LD	HL,(curbcba)
	EX	DE,HL
	LD	HL,(rootbcba)
	LD	A,(HL)
	INC	HL
	LD	L,(HL)
	LD	H,A
	CALL	subdh
	OR	L
	EX	DE,HL
	ret	z		; yes
	JP	get$bcb3	; no - insert bcb at head of list
last$bcb$links$de:	
	LD	HL,(lastbcba)
	LD	BC,13
	ADD	HL,BC
	LD	(HL),E
	INC	HL
	LD	(HL),D
	RET	
get$next$bcba:	
	LD	BC,13
	ADD	HL,BC
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	LD	A,H
	OR	L
	RET	
set$bcb$seq:	
	LD	A,(phy$off)
	LD	(HL),A
	OR	A
	ret	z
	LD	A,(phymsk)
	INC	A
	LD	(HL),A
	RET	
ENDIF	
IF	.NOT.	MPM
IF	.NOT.	BANKED
IF	PATCH7 .and. .NOT. BANKED
new$dir$ext:	
	LD	A,(chksiz+1)
	RLA	
	jp	c,get$dir$ext
	LD	A,0ffh
	LD	(new$store),A
	JP	get$dir$ext
;
new$compare:	
	CP	03		;^C
	jp	nz,compare
	LD	A,(new$store)
	INC	A
	jp	nz,compare
	POP	HL
	JP	deblock25
;
new$curbcba:	
	XOR	A
	LD	(new$store),A
	LD	HL,(curbcba)
	RET	
new$store:	DS	1
ENDIF	
;
IF	PATCH13 .and. .NOT. BANKED
new$rebootx:	
	LD	HL,0
	LD	(conbuffadd),HL
	LD	(ccp$conbuff),HL
	DEC	HL
	DEC	HL
	RET	
;
new$xdcnt:	
	CALL	check$write
	LD	HL,xdcnt
	RET	
;
new$reselx:	
	CALL	reselectx
	JP	check$write
;
new$setfwf:	
	CALL	setfwf
	JP	search$namlen
ENDIF	
;
IF	PATCH7 .and. .NOT. BANKED .or. PATCH13 .and. .NOT. BANKED
here:	DS	04Ch ;last-$
ELSE	
	DS	112
ENDIF	
;last:	
;	org	base + (((last-base)+255) .and. 0ff00h) - 112
olog:	DW	0    
rlog:	DW	0
patch$flgs:	
IF	PATCH13 .and. PATCH7
	DW	0000,0600	
ENDIF	
IF	PATCH7 .and. .NOT. PATCH13  
	DW	0000,0200	
ENDIF	
IF	.NOT.	PATCH7 .and. .NOT. PATCH13
	DW	0000,0000	
ENDIF	
	DW	BDOS_LOC + 6
	XOR	A
	RET	

	
; System Control Block
SCB:	
; Expansion Area - 6 bytes
hashl:		DB	0		; 00
hash:		DW	0,0		; 01
version:	DB	31h		; 05
; Utilities Section - 8 bytes
util$flgs:	DW	0,0		; 06
dspl$flgs:	DW	0		; 0A
		DW	0		; 0C
; CLP Section - 4 bytes
clp$flgs:	DW	0
clp$errcde:	DW	0		; 10
; CCP Section - 8 bytes
ccp$comlen:	DB	0
_BIOS_SCB:
ccp_curdrv:	DB	2		; 13
ccp$curusr:	DB	0
ccp$conbuff:	DW	0
ccp$flgs:	DW	0
		DB	0 ;2
; Device I/O Section - 32 bytes
conwidth:	DB	79		; 1A
column:		DB	0
conpage:	DB	23		; 1C
conline:	DB	0
conbuffadd:	DW	0
conbufflen:	DW	0
conin$rflg:	DW	0
conout$rflg:	DW	0
auxin$rflg:	DW	0
auxout$rflg:	DW	0
lstout$rflg:	DW	0
page$mode:	DB	0
pm$default:	DB	0
ctlh$act:	DB	0		; 2EH
rubout$act:	DB	0		; 2FH
type$ahead:	DB	0		; 30H
contran:	DW	0
conmode:	DW	0
		DB	0		; 35H
		DB	0
outdelim:	DB	'$'
listcp:		DB	0		; 38H
qflag:		DB	0
; BDOS Section - 42 bytes
scbadd:		DW	SCB
dmaad:		DW	0080h
olddsk:		DB	0
info:		DW	0
resel:		DB	0		; 41H
relog:		DB	0
fx:		DB	0
usrcode:	DB	0
dcnt:		DW	0
searcha:	DW	0
searchl:	DB	0
mult$cnt:	DB	1
error$mode:	DB	0
searchchain:	DB	0,0ffh,0ffh,0ffh
temp$drive:	DB	0		; 50H
errdrv:		DB	0		; 51H
		DW	0
media$flag:	DB	0
		DW	0
bdos$flags:	DB	0C0h	; was 0	; 57H
stamp:		DB	0ffh,0ffh,0ffh,0ffh,0ffh
common$base:	DW	0		; 5DH bnk$top
error:		JP	error$sub
bdosadd:	DW	BDOS_LOC + 6
ENDIF	
ENDIF	

;	SEGMENT BDOS

;	************************
;	Directory Hashing Module
;	************************
; Hash format
; xxsuuuuu xxxxxxxx xxxxxxxx ssssssss
; x = hash code of fcb name field
; u = low 5 bits of fcb user field
;     1st bit is on for XFCB's
; s = shiftr(mod || ext,extshf)
IF	.NOT.	BANKED
hashorg:	
;	org	base+(((hashorg-base)+255) .and. 0ff00h) 
ENDIF	
init$hash:	
	; de = .hash table entry
	; hl = .dir fcb
	PUSH	HL
	PUSH	DE
	CALL	get$hash
	; Move computed hash to hash table entry
	POP	HL
	LD	DE,hash
	LD	BC,4
IF	BANKED
	LD	A,(hash$tbla+2)
	CALL	move$out
ELSE	
	CALL	movef
ENDIF	
	; Save next hash table entry address
	LD	(arecord1),HL
	; Restore dir fcb address
	POP	HL
	RET	
set$hash:	
	; Return if searchl = 0
	OR	A
	ret	z
	; Is searchl < 12 ?
	CP	12
	jp	c,set$hash2	; yes - hashl = 0
	; Is searchl = 12 ?
	LD	A,2
	jp	z,set$hash1	; yes - hashl = 2
	LD	A,3		; hashl = 3
set$hash1:	
	LD	(hashl),A
	EX	DE,HL
	; Is dir hashing invoked for drive?
	CALL	test$hash
	ret	z		; no
	EX	DE,HL
	LD	A,(fx)
	CP	16
	jp	z,get$hash	; bdos fx = 16
	CP	35
	jp	z,set$hash15
	CP	20
	jp	nc,get$hash	; bdos fx = 20 or above
set$hash15:	
	LD	A,2
	LD	(hashl),A	; bdos fx = 15,17,18,19, or 35
	; if fcb wild then hashl = 0, hash = fcb(0)
	;             else hashl = 2, hash = get$hash
	PUSH	HL
	CALL	chk$wild
	POP	HL
	jp	nz,get$hash
set$hash2:	
	XOR	A
	LD	(hashl),A
	; jmp get$hash
get$hash:	
	; hash(0) = fcb(0)
	LD	A,(HL)
	LD	(hash),A
	INC	HL
	EX	DE,HL
	; Don't compute hash for dir lbl & sfcb's
	LD	HL,0
	AND	20h
	jp	nz,get$hash6
	; b = 11, c = 8, ahl = 0 
	; Compute fcb name hash (000000xx xxxxxxxxx xxxxxxxx) (ahl)
	LD	BC,0b08h
get$hash1:	
	; Don't shift if fcb(8)
	DEC	C
	PUSH	BC
	jp	z,get$hash3
	; Don't shift if fcb(6)
	DEC	C
	DEC	C
	jp	z,get$hash3
	; ahl = ahl * 2
	ADD	HL,HL
	ADC	A,A
	PUSH	AF
	LD	A,B
	; is b odd?
	RRA	
	jp	c,get$hash4	; yes
	; ahl = ahl * 2 for even fcb(i)
	POP	AF
	ADD	HL,HL
	ADC	A,A
get$hash3:	
	PUSH	AF
get$hash4:	
	; a = fcb(i) & 7fh - 20h divided by 2 if even
	LD	A,(DE)
	AND	7fh
	SUB	A,20h
	RRA	
	jp	nc,get$hash5
	RLA	
get$hash5:	
	; ahl = ahl + a
	LD	C,A
	LD	B,0
	POP	AF
	ADD	HL,BC
	ADC	A,0
	POP	BC
	; advance to next fcb char
	INC	DE
	DEC	B
	jp	nz,get$hash1
get$hash6:	
	; ahl = 000000xx xxxxxxxx xxxxxxxx
	; Store low 2 bytes of hash
	LD	(hash+1),HL
	LD	HL,hash
	; hash(0) = hash(0) (000uuuuu) | xx000000
	AND	3
	RRCA	
	RRCA	
	OR	(HL)
	LD	(HL),A
	; Does fcb(0) = e5h, 20h, or 21h?
	AND	20h
	jp	nz,get$hash9	; yes
	; bc = 00000mmm mmmeeeee, m = module #, e = extent
	LD	A,(DE)
	AND	1fh
	LD	C,A
	INC	DE
	INC	DE
	LD	A,(DE)
	AND	3fh
	RRCA	
	RRCA	
	RRCA	
	LD	D,A
	AND	7
	LD	B,A
	LD	A,D
	AND	0e0h
	OR	C
	LD	C,A
	; shift bc right by # of bits in extmsk
	LD	A,(extmsk)
get$hash7:	
	RRA	
	jp	nc,get$hash8
	PUSH	AF
	LD	A,B
	RRA	
	LD	B,A
	LD	A,C
	RRA	
	LD	C,A
	POP	AF
	JP	get$hash7
get$hash8:	
	; hash(0) = hash(0) (xx0uuuuu) | 00s00000
	LD	A,B
	AND	1
	RRCA	
	RRCA	
get$hash9:	
	RRCA	
	OR	(HL)
	LD	(HL),A
	; hash(3) = ssssssss
	LD	DE,3
	ADD	HL,DE
	LD	(HL),C
	RET	
test$hash:	
	LD	HL,(hash$tbla)
	LD	A,L
	OR	H
	INC	A
	RET	
search$hash:	
	; Does hash table exist for drive?
	CALL	test$hash
	ret	z		; no
	; Has dir hash search been disabled?
	LD	A,(hashl)
	INC	A
	ret	z		; yes
	; Is searchl = 0?
	LD	A,(searchl)
	OR	A
	ret	z		; yes
	; hashmx = cdrmaxa if searchl ~= 1
	;          dirmax if searchl = 1
	LD	HL,(cdrmaxa)
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	DEC	A
	jp	nz,search$h0
	LD	HL,(dirmax)
search$h0:	
	LD	(hashmx),HL
IF	BANKED
	; call search$hash in resbdos, a = bank, hl = hash tbl addr
	LD	A,(hash$tbla+2)
	LD	HL,(hash$tbla)
	CALL	srch$hash
	; Was search successful?
	jp	nz,search$h1	; no
	; Is directory read required?
	LD	A,(rd$dir$flag)
	OR	A
	LD	C,0
	call	nz,r$dir2		; yes if Z flag reset
	; Is function = 18?
	LD	A,(fx)
	SUB	A,18
	ret	z		; Never reset dcnt for fx 18
	; Was media change detected by above read?
	LD	A,(hashl)
	INC	A
	call	z,set$end$dir	; yes
	XOR	A
	RET			; search$hash successful
search$h1:	
	; Was search initiated from beginning of directory?
	CALL	end$of$dir
	ret	nz		; no
	; Is bdos fx = 15,17,19,22,23,30?
	CALL	tst$log$fxs
	ret	nz		; no
	; Disable hash & return successful
	LD	A,0ffh
	LD	(hashl),A
	LD	HL,(cdrmaxa)
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	DEC	HL
	CALL	set$dcnt$dblk1
	XOR	A
	RET	
ELSE	
	LD	HL,(hash$tbla)
	LD	B,H
	LD	C,L
	LD	HL,(hashmx)
	EX	DE,HL
	; Return with Z flag set if dcnt = hashmx
	LD	HL,(dcnt)
	PUSH	HL
	CALL	subdh
	POP	DE
	OR	L
	ret	z
	; Push hashmx - dcnt (# of hashtbl entries to search)
	; Push dcnt + 1
	PUSH	HL
	INC	DE
	EX	DE,HL
	PUSH	HL
	; Compute .hash$tbl(dcnt)
	DEC	HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,BC
search$h1:	
	; Advance hl to address of next hash$tbl entry
	LD	DE,4
	ADD	HL,DE
	LD	DE,hash
	; Do hash u fields match?
	LD	A,(DE)
	XOR	(HL)
	AND	1fh
	jp	nz,search$h3	; no
	; Do hash's match?
	CALL	search$h6
	jp	z,search$h4	; yes
search$h2:	
	EX	DE,HL
	POP	HL
search$h25:	
	; de = .hash$tbl(dcnt), hl = dcnt
	; dcnt = dcnt + 1
	INC	HL
	EX	(SP),HL
	; hl = # of hash$tbl entries to search
	; decrement & test for zero
	; Restore stack & hl to .hashtbl(dcnt)
	DEC	HL
	LD	A,L
	OR	H
	EX	(SP),HL
	PUSH	HL
	; Are we done?
	EX	DE,HL
	jp	nz,search$h1	; no - keep searching
	; Search unsuccessful
	POP	HL
	POP	HL
	; Was search initiated from beginning of directory?
	CALL	end$of$dir
	ret	nz		; no
	; Is fx = 15,17,19,22,23,30 & drive removeable?
	CALL	tst$log$fxs
	ret	nz		; no
	; Disable hash & return successful
	LD	A,0ffh
	LD	(hashl),A
	LD	HL,(cdrmaxa)
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	DEC	HL
	CALL	set$dcnt$dblk1
	XOR	A
	RET	
search$h3:	
	; Does xdcnt+1 = 0ffh?
	LD	A,(xdcnt+1)
	INC	A
	jp	z,search$h5	; yes
	; Does xdcnt+1 = 0feh?
	INC	A
	jp	nz,search$h2	; no - continue searching
	; Do hash's match?
	CALL	search$h6
	jp	nz,search$h2	; no
	; xdcnt+1 = 0feh
	; Open user 0 search
	; Does hash u field = 0?
	LD	A,(HL)
	AND	1fh
	jp	nz,search$h2	; no
	; Search successful
search$h4:	
	; Successful search
	; Set dcnt to search$hash dcnt-1
	; dcnt gets incremented by read$dir
	; Also discard search$hash loop count
	LD	HL,(dcnt)
	EX	DE,HL
	POP	HL
	DEC	HL
	LD	(dcnt),HL
	POP	BC
	; Does dcnt&3 = 3?
	LD	A,L
	AND	03h
	CP	03h
	ret	z		; yes
	; Does old dcnt & new dcnt reside in same sector?
	LD	A,E
	AND	0fch
	LD	E,A
	LD	A,L
	AND	0fch
	LD	L,A
	CALL	subdh
	OR	L
	ret	z		; yes
	; Read directory record
	CALL	read$dir2
	; Has media change been detected?
	LD	A,(hashl)
	INC	A
	call	z,set$end$dir	; dcnt = -1 if hashl = 0ffh
	XOR	A
	RET	
search$h5:	
	; xdcnt+1 = 0ffh
	; Make search to save dcnt of empty fcb
	; Is hash$tbl entry empty?
	LD	A,(HL)
	CP	0f5h
	jp	nz,search$h2	; no
search$h55:	
	; xdcnt = dcnt
	EX	DE,HL
	POP	HL
	LD	(xdcnt),HL
	JP	search$h25
search$h6:	
	; hash compare routine
	; Is hashl = 0?
	LD	A,(hashl)
	OR	A
	ret	z		; yes - hash compare successful
	; b = 0f0h if hashl = 3
	;     0d0h if hashl = 2
	LD	C,A
	RRCA	
	RRCA	
	RRCA	
	OR	1001_0000b
	LD	B,A
	; hash s field must be screened out of hash(0)
	; if hashl = 2
	; Do hash(0) fields match?
	LD	A,(DE)
	XOR	(HL)
	AND	B
	ret	nz		; no
	; Compare remainder of hash fields for hashl bytes
	PUSH	HL
	INC	HL
	INC	DE
	CALL	compare
	POP	HL
	RET	
ENDIF	
fix$hash:	
	CALL	test$hash
	ret	z
	LD	HL,save$hash
	LD	DE,hash
	LD	BC,4
	PUSH	HL
	PUSH	DE
	PUSH	BC
	CALL	movef
	LD	HL,(hash$tbla)
	PUSH	HL
	CALL	getdptra
	CALL	get$hash
	LD	HL,(dcnt)
	ADD	HL,HL
	ADD	HL,HL
	POP	DE
	ADD	HL,DE
	POP	BC
	POP	DE
	PUSH	DE
	PUSH	BC
IF	BANKED
	LD	A,(hash$tbla+2)
	CALL	move$out
ELSE	
	CALL	movef
ENDIF	
	POP	BC
	POP	HL
	POP	DE
	JP	movef
IF	.NOT.	MPM
IF	BANKED
IF	UNDOC	
;undocumented DRI patch found in bnkbdos3.spr
;
undoc1:	
	LD	A,(288ch)
	RLA	
	jp	c,get$dir$ext
	LD	A,0ffh
	LD	(undocst),A
	JP	get$dir$ext
;
undoc2:	
	CP	03
	jp	nz,compare
	LD	A,(2d23h)
	INC	A
	jp	nz,compare
	POP	HL
	JP	deblock25
;
undoc3:	
	XOR	A
	LD	(undocst),A
	LD	HL,(curbcba)
	RET	
;
undocst:	
	nop	
ENDIF	
;
	DS	1
last:	
;	org	(((last-base)+255) and 0ff00h) - 1
	DB	0
ENDIF	
ELSE	
	DS	192
last:	
;	org	(((last-base)+255) and 0ff00h) - 192
	;	bnkbdos patch area
	DW	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	DW	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	DW	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	DW	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	DW	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	DW	0,0,0,0,0,0,0,0,0,0,0,0
free$root:	DW	0 ;$-$
open$root:	DW	0
lock$root:	DW	0
lock$max:	DB	0
open$max:	DB	0
;	BIOS access table
bios:	equ	openmax+1 ;$	; base of the bios jump table
bootf:	equ	bios		; cold boot function
wbootf:	equ	bootf+3		; warm boot function
constf:	equ	wbootf+3	; console status function
coninf:	equ	constf+3	; console input function
conoutf:	equ	coninf+3; console output function
listf:	equ	conoutf+3	; list output function
punchf:	equ	listf+3		; punch output function
readerf:	equ	punchf+3; reader input function
homef:	equ	readerf+3	; disk home function
seldskf:	equ	homef+3	; select disk function
settrkf:	equ	seldskf+3; set track function
setsecf:	equ	settrkf+3; set sector function
setdmaf:	equ	setsecf+3; set dma function
readf:	equ	setdmaf+3	; read disk function
writef:	equ	readf+3		; write disk function
liststf:	equ	writef+3; list status function
sectran:	equ	liststf+3; sector translate
ENDIF	
;
IF	PATCH13 .and. BANKED
;	org	02d24h
new$rebootx:	
	LD	HL,0
	LD	(conbuffadd),HL
	LD	(ccp$conbuff),HL
	DEC	HL
	DEC	HL
	RET	
;
new$rootbcba:	
	LD	(rootbcba),HL
	SUB	A,3
	LD	(new$bcba),A
	RET	
;
new$bcba:	
	DB	0
;
new$flush35:	
	CALL	new$flush35a
	JP	flush4
;
new$initialize2:	
	CALL	copy$alv
new$flush35a:	
	LD	HL,(dta$bcba)
	LD	A,L
	AND	H
	INC	A
	ret	z
new$loop1:	
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	A,D
	OR	E
	ret	z
	LD	HL,adrive
	LD	A,(DE)
	CP	(HL)
	jp	nz,new$loop2
	LD	HL,4
	ADD	HL,DE
	LD	A,0ffh
	CP	(HL)
	jp	nz,new$loop2
	LD	(DE),A
new$loop2:	
	LD	HL,0dh
	ADD	HL,DE
	JP	new$loop1
;
new$copy$alv:	
	CALL	copy$alv
	LD	HL,(lsn$add)
	LD	A,(HL)
	OR	A
	ret	nz
	LD	(HL),2
	RET	
;
new$xdcnt:	
	CALL	check$write
	LD	HL,xdcnt
	RET	
;
new$reselx:	
	CALL	reselectx
	JP	check$write
;
new$setfwf:	
	CALL	setfwf
	JP	search$namlen
;
	DS	($ .and. 0FF00h + 0100H) - $ ;77h
;
ENDIF	
;

bdos_last:
BDOS_PAD	DS 019h ;(bdos_last + 100H) .AND. 0FF00 - bdos_last

	end

