NOLIST

;
;	equates for non graphic characters
;
CTLA:	equ	'A'-40h		; control a
CTLB:	equ	'B'-40h		; control b
CTLC:	equ	'C'-40h		; control c
CTLE:	equ	'E'-40h		; physical eol
CTLF:	equ	'F'-40h		; control f
CTLG:	equ	'G'-40h		; control g
CTLH:	equ	'H'-40h		; backspace
CTLK:	equ	'K'-40h		; control k
CTLP:	equ	'P'-40h		; prnt toggle
CTLQ:	equ	'Q'-40h		; start screen
CTLR:	equ	'R'-40h		; repeat line
CTLS:	equ	'S'-40h		; stop screen
CTLU:	equ	'U'-40h		; line delete
CTLW:	equ	'W'-40h		; control w
CTLX:	equ	'X'-40h		; =ctl-u
CTLZ:	equ	'Z'-40h		; end of file
RUBOUT:	equ	7fh		; char delete
BELL	equ	07h		; bell
TAB:	equ	09h		; tab char
CR:	equ	0dh		; carriage return
LF:	equ	0ah		; line feed
CTL:	equ	5eh		; up arrow
EOF:	equ	'Z'-40h

base:	equ	0000h

off:	equ	00000h
on:	equ	.NOT. off
MPM:	equ	off
BANKED:	equ	off
LDRBIOS equ	off
z80proc equ	on
cpmfcb	equ	080h

ret_op	equ	0C9h		; opcode for a return instruction

LIST
