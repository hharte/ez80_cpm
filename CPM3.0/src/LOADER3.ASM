;*************************************************************************
;*                                                                       *
;* $Id: LOADER3.ASM 1555 2007-09-14 07:37:35Z hharte $                   *
;*                                                                       *
;* Copyright (c) 2005-2007 Howard M. Harte                               *
;* https://github.com/hharte                                             *
;*                                                                       *
;* Module Description:                                                   *
;*     CPM 3.0 Loader Ported to ZDS-II by Howard M. Harte.               *
;*                                                                       *
;* Environment:                                                          *
;*     Zilog ZDS-II v4.11.1, (http://www.zilog.com)                      *
;*                                                                       *
;*************************************************************************

title	'CP/M 3 - PROGRAM LOADER RSX - November 1982'
;	version 3.0b  Nov 04 1982 - Kathy Strutynski
;	version 3.0c  Nov 23 1982 - Doug Huskey
;	              Dec 22 1982 - Bruce Skidmore
;
;
;	copyright (c) 1982
;	digital research
;	box 579
;	pacific grove, ca.
;	93950
;
;		****************************************************
;		*****  The following values must be placed in    ***
;		*****  equates at the front of CCP3.ASM.         ***
;		*****                                            ***
;		*****  Note: Due to placement at the front these ***
;		*****  equates cause PHASE errors which can be   ***
;		*****  ignored.                                  ***

include "cpm3_defs.inc"

PUBLIC	rsxstart

equ1:	equ	rsxstart 	;+0100h	;set this equate in the CCP
equ2:	equ	fixchain 	;+0100h	;set this equate in the CCP
equ3:	equ	fixchain1	;+0100h	;set this equate in the CCP
equ4:	equ	fixchain2	;+0100h	;set this equate in the CCP
equ5:	equ	rsx_chain	;+0100h	;set this equate in the CCP
equ6:	equ	reloc    	;+0100h	;set this equate in the CCP
equ7:	equ	calcdest 	;+0100h	;set this equate in the CCP
equ8:	equ	scbaddr	 	;+0100h	;set this equate in the CCP
equ9:	equ	bankedflg	 	;+0100h	;set this equate in the CCP
equ10:	equ	rsxend	 	;+0100h	;set this equate in the CCP
ccporg:	equ	ccp		;set origin to this in CCP
patch:	equ	patcharea	;+0100h	;LOADER patch area
ccp:	equ	40Ah		;ORIGIN OF CCP3.ASM
;		****************************************************
;	conditional assembly toggles:
true:	equ	on
false:	equ	off
spacesaver:	equ	true
stacksize:	equ	32	;16 levels of stack
version:	equ	30h
tpa:		equ	100h
ccptop:		equ	0Fh	;top page of CCP
osbase:		equ	06h	;base page in BDOS jump
off_nxt:	equ	10	;address in next jmp field
currec:		equ	32	;current record field in fcb
ranrec:		equ	33	;random record field in fcb
;
;
;     dsect for SCB
;
bdosbase:	equ	98h	; offset from page boundary
ccpflag1:	equ	0b3h	; offset from page boundary
multicnt:	equ	0e6h	; offset from page boundary
rsx_only_clr:	equ	0FDh	;clear load RSX flag
rsx_only_set:	equ	002h
rscbadd:	equ	3ah	;offset of scbadd in SCB
dmaad:		equ	03ch	;offset of DMA address in SCB
bdosadd:	equ	62h	;offset of bdosadd in SCB
;
loadflag:	equ	02H	;flag for LOADER in memory
;
;     dsect for RSX
entry:		equ	06h	;RSX contain jump to start
;
nextadd:	equ	0bh	;address of next RXS in chain
prevadd:	equ	0ch	;address of previous RSX in chain
warmflg:	equ	0eh	;remove on wboot flag
endchain:	equ	18h	;end of RSX chain flag
;
;
readf:		equ	20	;sequential read
dmaf:		equ	26	;set DMA address
scbf:		equ	49	;get/set SCB info
loadf:		equ	59	;load function
;
;
maxread:	equ	64	;maximum of 64 pages in MULTIO
;
;
wboot:		equ	0000h	;BIOS warm start
bdos:		equ	0005h	;bdos entry point
print:		equ	9	;bdos print function
vers:		equ	12	;get version number
module:		equ	200h	;module address
;
;	DSECT for COM file header
;
comsize:	equ	tpa+1h
scbcode:	equ	tpa+3h
rsxoff:		equ	tpa+10h
rsxlen:		equ	tpa+12h
;
;
;
;
;	cseg	
	DEFINE CCP_SEG, SPACE = RAM
	SEGMENT CCP_SEG

	.ASSUME ADL = 0
;
;
;     ********* LOADER  RSX HEADER ***********
;
rsxstart:	
	JP	ccp		;the ccp will move this loader to 
	DB	0,0,0		;high memory, these first 6 bytes
	;will receive the serial number from
	;the 6 bytes prior to the BDOS entry
	;point
tojump:	
	JP	begin
next:	DB	0c3h		;jump to next module
nextjmp:	DW	06
prevjmp:	DW	07
	DB	0		;warm start flag
	DB	0		;bank flag
	DB	'LOADER  '	;RSX name
	DB	0ffh		;end of RSX chain flag
	DB	0		;reserved
	DB	0		;patch version number
;     ********* LOADER  RSX ENTRY POINT ***********
begin:	
	LD	A,C
	CP	loadf
	jp	nz,next
beginlod:	
	POP	BC
	PUSH	BC		;BC = return address
	LD	HL,0		;switch stacks
	ADD	HL,sp
	LD	sp,stack	;our stack
	LD	(ustack),HL	;save user stack address
	PUSH	BC		;save return address
	EX	DE,HL		;save address of user's FCB
	LD	(usrfcb),HL
	LD	A,H		;is .fcb = 0000h
	OR	L
	PUSH	AF
	call	z,rsx_chain	;if so , remove RSXs with remove flag on
	POP	AF
	call	nz,loadfile
	POP	DE		;return address
	LD	HL,tpa
	LD	A,(HL)
	CP	ret_op
	jp	z,rsxfile
	LD	A,D		;check return address
	DEC	A		; if CCP is calling 
	OR	E		; it will be 100H
	jp	nz,retuser1	;jump if not CCP
retuser:	
	LD	A,(prevjmp+1)	;get high byte
	OR	A		;is it the zero page (i.e. no RSXs present)
	jp	nz,retuser1	;jump if not
	LD	HL,(nextjmp)	;restore five....don't stay arround
	LD	(osbase),HL
	LD	(newjmp),HL
	CALL	setmaxb
retuser1:	
	LD	HL,(ustack)	;restore the stack
	LD	SP,HL
	XOR	A
	LD	L,A
	LD	H,A		;A,HL=0 (successful return)
	RET			;CCP pushed 100H on stack
;
;
;	BDOS FUNC 59 error return
;
reterror:	
	LD	DE,0feh
reterror1:	
	;DE = BDOS error return
	LD	HL,(ustack)
	LD	SP,HL
	POP	HL		;get return address
	PUSH	HL
	DEC	H		;is it 100H_
	LD	A,H
	OR	L
	EX	DE,HL		;now HL = BDOS error return
	LD	A,L
	LD	B,H
	ret	nz		;return if not the CCP
;
;
loaderr:	
	LD	C,print
	LD	DE,nogo		;cannot load program
	CALL	bdos		;to print the message
	JP	wboot		;warm boot
;
;
;;
;************************************************************************
;
;	MOVE RSXS TO HIGH MEMORY
;
;************************************************************************
;
;
;      RSX files are present
;
	
rsxf1:	INC	HL
	LD	C,(HL)
	INC	HL
	LD	B,(HL)		;BC contains RSX length
	LD	A,(bankedflg)
	OR	A		;is this the non-bankedflg system_
	jp	z,rsxf2		;jump if so
	INC	HL		;HL = bankedflg/non-bankedflg flag
	INC	(HL)		;is this RSX only for non-bankedflg_
	jp	z,rsxf3		;skip if so
rsxf2:	PUSH	DE		;save offset
	CALL	calcdest	;calculate destination address and bias
	POP	HL		;rsx offset in file
	CALL	reloc		;move and relocate file
	CALL	fixchain	;fix up rsx address chain
rsxf3:	POP	HL		;RSX length field in header
rsxfile:	
	;HL = .RSX (n-1) descriptor 
	LD	DE,10h		;length of RSX descriptor in header
	ADD	HL,DE		;HL = .RSX (n) descriptor
	PUSH	HL		;RSX offset field in COM header
	LD	E,(HL)
	INC	HL
	LD	D,(HL)		;DE = RSX offset
	LD	A,E
	OR	D
	jp	nz,rsxf1		;jump if RSX offset is non-zero
;
;
;
comfile:	
	;RSXs are in place, now call SCB setting code 
	CALL	scbcode		;set SCB flags for this com file
	;is there a real COM file_
	LD	A,(module)	;is this an RSX only
	CP	ret_op
	jp	nz,comfile2	;jump if real COM file
	LD	HL,(scbaddr)
	LD	L,ccpflag1
	LD	A,(HL)
	OR	rsx_only_set	;set if RSX only
	LD	(HL),A
comfile2:	
	LD	HL,(comsize)	;move COM module to 100H
	LD	B,H
	LD	C,L		;BC contains length of COM module
	LD	HL,tpa+100h	;address of source for COM move to 100H
	LD	DE,tpa		;destination address
	CALL	move
	JP	retuser1	;restore stack and return
;;
;************************************************************************
;
;	ADD AN RSX TO THE CHAIN
;
;************************************************************************
;
;
fixchain:	
	LD	HL,(osbase)	;next RSX link
	LD	L,0
	LD	BC,6
	CALL	move		;move serial number down
	LD	E,endchain
	LD	(DE),A		;set loader flag=0
	LD	E,prevadd+1
	LD	(DE),A		;set previous field to 0007H
	DEC	DE
	LD	A,7
	LD	(DE),A		;low byte = 7H
	LD	L,E		;HL address previous field in next RSX
	LD	E,nextadd	;change previous field in link
	LD	(HL),E
	INC	HL
	LD	(HL),D		;current <-- next
;
fixchain1:	
	;entry:	H=next RSX page, 
	;	DE=.(high byte of next RSX field) in current RSX
	EX	DE,HL		;HL-->current  DE-->next
	LD	(HL),D		;put page of next RSX in high(next field)
	DEC	HL
	LD	(HL),6
;
fixchain2:	
	;entry:	H=page of lowest active RSX in the TPA
	;this routine resets the BDOS address @ 6H and in the SCB
	LD	L,6
	LD	(osbase),HL	;change base page BDOS vector
	LD	(newjmp),HL	;change SCB value for BDOS vector
;
;
setmaxb:	
	LD	DE,scbadd2
scbfun:	
	LD	C,scbf
	JP	bdos
;
;
;;
;************************************************************************
;
;	REMOVE TEMPORARY RSXS
;
;************************************************************************
;
;
;
rsx_chain:	
	;
	;	Chase up RSX chain, removing RSXs with the
	;	remove flag on (0FFH)
	;
	LD	HL,(osbase)	;base of RSX chain
	LD	B,H
rsx_chain1:	
	;B  = current RSX
	LD	H,B
	LD	L,endchain
	INC	(HL)
	DEC	(HL)		;is this the loader_
	ret	nz		;return if so (m=0ffh)
	LD	L,nextadd	;address of next node
	LD	B,(HL)		;DE -> next link
;
;
check_remove:	
;
	LD	L,warmflg	;check remove flag
	LD	A,(HL)		;warmflag in A
	OR	A		;FF if remove on warm start
	jp	z,rsx_chain1	;check next RSX if not
;
remove:	
	;remove this RSX from chain
;
	;first change next field of prior link to point to next RSX
	;HL = current  B = next
;
	LD	L,prevadd
	LD	E,(HL)		;address of previous RSX link
	INC	HL
	LD	D,(HL)
	LD	A,B		;A = next (high byte)
	LD	(DE),A		;store in previous link
	DEC	DE		;previous RSX chains to next RSX
	LD	A,6		;initialize low byte to 6
	LD	(DE),A		;
	INC	DE		;DE = .next (high byte)
;
	;now change previous field of next link to address previous RSX
	LD	H,B		;next in HL...previous in DE
	LD	L,prevadd
	LD	(HL),E
	INC	HL
	LD	(HL),D		;next chained back to previous RSX
	LD	A,D		;check to see if this is the bottom
	OR	A		;RSX...
	PUSH	BC
	call	z,fixchain2	;reset BDOS BASE to page in H
	POP	BC
	JP	rsx_chain1	;check next RSX in the chain
;
;
;;
;************************************************************************
;
;	PROGRAM LOADER
;
;************************************************************************
;
;
;
loadfile:	
;	entry: HL = .FCB
	PUSH	HL
	LD	DE,scbdma		
	CALL	scbfun
	EX	DE,HL
	POP	HL		;.fcb
	PUSH	HL		;save .fcb
	LD	BC,currec
	ADD	HL,BC
	LD	(HL),0		;set current record to 0
	INC	HL
	LD	C,(HL)		;load address 
	INC	HL
	LD	H,(HL)
	LD	L,C
	DEC	H
	INC	H	
	jp	z,reterror	;Load address < 100h
	PUSH	HL		;now save load address
	PUSH	DE		;save the user's DMA
	PUSH	HL
	CALL	multio1		;returns A=multio
	POP	HL
	PUSH	AF		;save A = user's multisector I/O
	LD	E,128		;read 16k
	;stack:		|return address|
	;		|.FCB          |
	;		|Load address  |
	;		|users DMA     |
	;		|users Multio  |
	;
loadf0:	
	;HL= next load address (DMA)
	; E= number of records to read
	LD	A,(osbase+1)	;calculate maximum number of pages
	DEC	A
	SUB	A,H
	jp	c,endload	;we have used all we can
	INC	A
	CP	maxread		;can we read 16k_
	jp	nc,loadf2
	RLCA			;change to sectors
	LD	E,A		;save for multi i/o call
	LD	A,L		;A = low(load address)
	OR	A
	jp	z,loadf2		;load on a page boundary
	LD	B,2		;(to subtract from # of sectors)
	DEC	A		;is it greater than 81h_
	jp	m,subtract	;080h < l(adr) <= 0FFh (subtract 2)
	DEC	B		;000h < l(adr) <= 080h (subtract 1)
subtract:	
	LD	A,E		;reduce the number of sectors to
	SUB	A,B		;compensate for non-page aligned
	;load address
	jp	z,endload	;can't read zero sectors
	LD	E,A
;
loadf2:	
	;read the file
	PUSH	DE		;save number of records to read
	PUSH	HL		;save load address
	CALL	multio		;set multi-sector i/o
	POP	HL
	PUSH	HL
	CALL	readb		;read sector
	POP	HL
	POP	DE		;restore number of records
	PUSH	AF		;zero flag set if no error
	LD	A,E		;number of records in A
	INC	A
	RRA			;convert to pages
	ADD	A,H
	LD	H,A		;add to load address
	LD	(loadtop),HL	;save next free page address
	POP	AF
	jp	z,loadf0	;loop if more to go
loadf4:	
	;FINISHED load  A=1 if successful (eof)
	;		A>1 if a I/O error occured
	;
	POP	BC		;B=multisector I/O count
	DEC	A		;not eof error_
	LD	E,B		;user's multisector count
	CALL	multio
	LD	C,dmaf		;restore the user's DMA address
	POP	DE	
	PUSH	AF		;zero flag => successful load
	CALL	bdos		; user's DMA now restored
	POP	AF
	LD	HL,(bdosret)	;BDOS error return
	EX	DE,HL
	jp	nz,reterror1
	POP	DE		;load address	
	POP	HL		;.fcb
	LD	BC,9		;is it a PRL_
	ADD	HL,BC		;.fcb(type)
	LD	A,(HL)
	AND	7fh		;get rid of attribute bit
	CP	'P'		;is it a P_
	ret	nz		;return if not
	INC	HL
	LD	A,(HL)
	AND	7fh
	CP	'R'		;is it a R
	ret	nz		;return if not
	INC	HL
	LD	A,(HL)
	AND	7fh
	SUB	A,'L'		;is it a L_
	ret	nz		;return if not
	;load PRL file
	LD	A,E
	OR	A		;is load address on a page boundary
	jp	nz,reterror	;error, if not
	LD	H,D
	LD	L,E		;HL,DE = load address
	INC	HL
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	LD	L,E		;HL,DE = load address BC = length
;	jmp	reloc		;relocate PRL file at load address
;
;;
;************************************************************************
;
;	PAGE RELOCATOR
;
;************************************************************************
;
;
reloc:	
;	HL,DE = load address (of PRL header)
;	BC    = length of program (offset of bit map)
	INC	H		;offset by 100h to skip header
	PUSH	DE		;save destination address
	PUSH	BC		;save length in bc
	CALL	move		;move rsx to correct memory location
	POP	BC
	POP	DE
	PUSH	DE		;save DE for fixchain...base of RSX
	LD	E,D		;E will contain the BIAS from 100h
	DEC	E		;base address is now 100h
	;after move HL addresses bit map
	;
	;storage moved, ready for relocation
	;	HL addresses beginning of the bit map for relocation
	;	E contains relocation bias
	;	D contain relocation address
	;	BC contains length of code
rel0:	PUSH	HL		;save bit map base in stack
	LD	H,E		;relocation bias is in e
	LD	E,0
;
rel1:	LD	A,B		;bc=0_
	OR	C
	jp	z,endrel
;
;	not end of the relocation, may be into next byte of bit map
	DEC	BC		;count length down
	LD	A,E
	AND	111b		;0 causes fetch of next byte
	jp	nz,rel2
;	fetch bit map from stacked address
	EX	(SP),HL
	LD	A,(HL)		;next 8 bits of map
	INC	HL
	EX	(SP),HL		;base address goes back to stack
	LD	L,A		;l holds the map as we process 8 locations
rel2:	LD	A,L
	RLA			;cy set to 1 if relocation necessary
	LD	L,A		;back to l for next time around
	jp	nc,rel3		;skip relocation if cy=0
;
;	current address requires relocation
	LD	A,(DE)
	ADD	A,H		;apply bias in h
	LD	(DE),A
rel3:	INC	DE		;to next address
	JP	rel1		;for another byte to relocate
;
endrel:	;end of relocation
	POP	DE		;clear stacked address
	POP	DE		;restore DE to base of PRL
	RET	
;
;;
;************************************************************************
;
;	PROGRAM LOAD TERMINATION
;
;************************************************************************
;
;;	
;;
endload:	
	CALL	multio1		;try to read after memory is filled
	LD	HL,80h		;set load address = default buffer
	CALL	readb
	jp	nz,loadf4	;eof => successful
	LD	HL,0feh		;set BDOSRET to indicate an error
	LD	(bdosret),HL
	JP	loadf4		;unsuccessful (file to big)
;
;;
;
;;
;************************************************************************
;
;	SUBROUTINES
;
;************************************************************************
;
;
;
;	Calculate RSX base in the top of the TPA
;
calcdest:	
;
;	calcdest returns destination in DE
;	BC contains length of RSX
;
	LD	A,(osbase+1)	;a has high order address of memory top
	DEC	A		;page directly below bdos
	DEC	BC		;subtract 1 to reflect last byte of code
	SUB	A,B		;a has high order address of reloc area
	INC	BC		;add 1 back get bit map offset
	CP	ccptop		;are we below the CCP
	jp	c,loaderr
	LD	HL,(loadtop)
	CP	H		;are we below top of this module
	jp	c,loaderr
	LD	D,A
	LD	E,0		;d,e addresses base of reloc area
	RET	
;
;;
;;-----------------------------------------------------------------------
;;
;;	move memory routine
move:	
;	move source to destination
;	where source is in HL and destination is in DE
;	and length is in BC
;
	LD	A,B		;bc=0_
	OR	C
	ret	z	
	DEC	BC		;count module size down to zero
	LD	A,(HL)		;get next absolute location
	LD	(DE),A		;place it into the reloc area
	INC	DE
	INC	HL
	JP	move
;;
;;-----------------------------------------------------------------------
;;
;;	Multi-sector I/O 
;;	(BDOS function #44)
;
multio1:	
	LD	E,1		;set to read 1 sector
;
multio:	
	;entry: E = new multisector count
	;exit:	A = old multisector count
	LD	HL,(scbaddr)
	LD	L,multicnt
	LD	A,(HL)
	LD	(HL),E
	RET	
;;
;;-----------------------------------------------------------------------
;;
;;	read file 
;;	(BDOS function #20)
;;
;;	entry:	hl = buffer address (readb only)
;;	exit	z  = set if read ok
;;
readb:	EX	DE,HL
setbuf:	LD	C,dmaf
	PUSH	HL		;save number of records
	CALL	bdos
	LD	C,readf
	LD	HL,(usrfcb)
	EX	DE,HL
	CALL	bdos
	LD	(bdosret),HL	;save bdos return
	POP	DE		;restore number of records
	OR	A
	ret	z		;no error on read
	LD	E,H		;change E to number records read
	RET	
;
;
;************************************************************************
;
;	DATA AREA
;
;************************************************************************
;
nogo:	DB	CR,LF,'Cannot load Program$'
patcharea:	
	DW	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0	;DS	36		;36 byte patch area
scbaddr:	DW	0
bankedflg:	DB	0
scbdma:		DB	dmaad
		DB	00h		;getting the value
scbadd2:	DB	bdosadd		;current top of TPA
		DB	0feh		;set the value
;
IF .not. spacesaver
newjmp:		DS	2	;new BDOS vector
loadtop:	DS	2	;page above loaded program
usrfcb:		DS	2	;contains user FCB add
ustack:		DS	2	; user stack on entry
bdosret:	DS	2	;bdos error return
;
rsxend:
stack:		equ	rsxend+stacksize
loader3_pad	BLKB	06CH, 0
else	
rsxend:	
newjmp:		equ	rsxend
loadtop:	equ	rsxend+2
usrfcb:		equ	rsxend+4
ustack:		equ	rsxend+6
bdosret:	equ	rsxend+8
stack:		equ	rsxend+10+stacksize

l0394:		db	000h, 080h, 000h, 000h, 080h, 048h, 041h, 010h, 004h, 012h, 024h, 012h, 040h, 008h, 000h, 010h
		db	000h, 088h, 044h, 048h, 000h, 020h, 004h, 080h, 000h, 009h, 000h, 020h, 000h, 000h, 001h, 020h 
		db	000h, 000h, 010h, 000h, 000h, 011h, 012h, 000h, 000h, 041h, 000h, 010h, 040h, 082h, 008h, 021h 
		db	000h, 022h, 008h, 001h, 010h, 000h, 000h, 000h, 020h, 001h, 000h, 004h, 008h, 001h, 002h, 008h 
		db	024h, 012h, 000h, 024h, 040h, 000h, 084h, 000h, 002h, 004h, 000h, 000h, 000h, 000h, 000h, 000h 
		db	000h, 000h, 000h

loader3_pad	BLKB	076H-53h, 0
ENDIF	
	end	
