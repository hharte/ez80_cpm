;*************************************************************************
;*                                                                       *
;* $Id: CCP3.ASM 1555 2007-09-14 07:37:35Z hharte $                      *
;*                                                                       *
;* Copyright (c) 2005-2007 Howard M. Harte                               *
;* https://github.com/hharte                                             *
;*                                                                       *
;* Module Description:                                                   *
;*     CPM 3.0 CCP Ported to ZDS-II by Howard M. Harte.                  *
;*                                                                       *
;* Environment:                                                          *
;*     Zilog ZDS-II v4.11.1, (http://www.zilog.com)                      *
;*                                                                       *
;*************************************************************************

title	'CP/M 3 - Console Command Processor - November 1982'
;	version 3.00  Nov 30 1982 - Doug Huskey
;  Copyright (C) 1982
;  Digital Research	ch
;  P.O. Box 579
;  Pacific Grove, CA 93950
;  Revised: John Elliott, 25-5-1998, to include DRI patches and multiple
;          error checking ability:
;
;          If the sequence
;               COMMAND
;               :C1
;               :C2
;
;           was executed under DRI's CCP, and COMMAND returned an error,
;           then C1 would not be executed but C2 would. Under this CCP
;           C2 would not be.

include "cpm3_defs.inc"

extern rsxstart

;
;	****************************************************
;	*****  The following equates must be set to 100H ***
;	*****  + the addresses specified in LOADER.PRN   ***
;	*****                                            ***
equ1:		equ	rsxstart	;does this adr match loader's?
equ2:		equ	fixchain	;does this adr match loader's?
equ3:		equ	fixchain1	;does this adr match loader's?
equ4:		equ	fixchain2	;does this adr match loader's?
equ5:		equ	rsx$chain	;does this adr match loader's?
equ6:		equ	reloc		;does this adr match loader's?
equ7:		equ	calcdest	;does this adr match loader's?
equ8:		equ	scbaddr		;does this adr match loader's?
equ9:		equ	bankedp		;does this adr match loader's?
equ10:		equ	rsxend		;does this adr match loader's?
equ11:		equ	ccporg		;does this adr match loader's?
equ12:		equ	ccpend		;This should be 0D80h
;rsxstart	equ	0100h
fixchain	equ	01D0h
fixchain1	equ	01EBh
fixchain2	equ	01F0h
rsx$chain	equ	0200h
reloc		equ	02CAh
calcdest	equ	030Fh
scbaddr		equ	038Dh
bankedp		equ	038Fh
rsxend		equ	0394h
ccporg		equ	040Ah;[JCE] was 041Ah, but reduced 
	;      to incorporate patches
;	****************************************************
;	NOTE: THE ABOVE EQUATES MUST BE CORRECTED IF NECESSARY
;	AND THE JUMP TO START AT THE BEGINNING OF THE LOADER
;	MUST BE SET TO THE ORIGIN ADDRESS BELOW:
;	org	ccporg		;LOADER is at 100H to 3??H
;	(BE SURE THAT THIS LEAVES ENOUGH ROOM FOR THE LOADER BIT MAP)
;  Conditional Assembly toggles:
;true:	equ	0ffffh
;false:	equ	0h
newdir:		equ	on ;true
newera:		equ	on ;true		;confirm any ambiguous file name
dayfile:	equ	on ;true		
prompts:	equ	off ;false
func152:	equ	on ;true
multi:		equ	on ;true		;multiple command lines
	;also shares code with loader (100-2??h)

jmp_op		equ	0C3h
;
;************************************************************************
;
;	GLOBAL EQUATES
;
;************************************************************************
;
;
;	CP/M BASE PAGE
;
wstart:		equ	0		;warm start entry point
defdrv:		equ	4		;default user & disk
bdos:		equ	5		;CP/M BDOS entry point
osbase:		equ	bdos+1		;base of CP/M BDOS
cmdrv:		equ	050h		;command drive
dcfcb:	equ	05ch		;1st default cfcb
ducfcb:	equ	dcfcb-1		;1st default cfcb user number
pass0:		equ	051h		;1st default cfcb password addr
len0:		equ	053h		;1st default cfcb password length
dcfcb1:	equ	06ch		;2nd default cfcb
ducfcb1:	equ	dcfcb1-1		;2nd default cfcb user number
pass1:		equ	054h		;2nd default cfcb password addr
len1:		equ	056h		;2nd default cfcb password length
buf:		equ	80h		;default buffer
tpa:		equ	100h		;transient program area

IF multi
comlen:	equ	100h-19h	;maximum size of multiple command
	;RSX buffer with 16 byte header &
	;terminating zero
	else	
comlen:	equ	tpa-buf
ENDIF	

;
;	BDOS FUNCTIONS
;
vers:		equ	31h		;BDOS vers 3.1
cinf:		equ	1		;console input
coutf:		equ	2		;console output
crawf:		equ	6		;raw console input 
pbuff:		equ	9		;PRINT buffer to console
rbuff:		equ	10		;read buffer from console
cstatf:		equ	11		;console status
resetf:		equ	13		;disk system reset
self:		equ	14		;select drive
openf:		equ	15		;open file
closef:		equ	16		;close file
searf:		equ	17		;search first
searnf:		equ	18		;search next
delf:		equ	19		;delete file
readf:		equ	20		;read file
makef:		equ	22		;make file
renf:		equ	23		;rename file
dmaf:		equ	26		;set DMA address
userf:		equ	32		;set/get user number
rreadf:		equ	33		;read file
flushf:		equ	48		;flush buffers
scbf:		equ	49		;set/get SCB value
loadf:		equ	59		;program load
allocf:		equ	98		;reset allocation vector
trunf:		equ	99		;read file
parsef:		equ	152		;parse file
;
;
;	RSX MEMORY MANAGEMENT EQUATES
;
;     	RSX header equates
;	
entry:		equ	06h		;RSX contain jump to start
nextadd:	equ	0bh		;address of next RXS in chain
prevadd:	equ	0ch		;address of previous RSX in chain
warmflg:	equ	0eh		;remove on wboot flag
endchain:	equ	18h		;end of RSX chain flag

;
;	LOADER.RSX equates
;
module:		equ	100h		;module address
;
;	COM file header equates
;
comsize:	equ	tpa+1h		;size of the COM file
rsxoff:		equ	tpa+10h		;offset of the RSX in COM file
rsxlen:		equ	tpa+12h		;length of the RSX
;
;
;	SYSTEM CONTROL BLOCK OFFSETS
;
pag$off:	equ	09ch
;
olog:		equ	pag$off-0ch	; removeable media open vector
rlog:		equ	pag$off-0ah	; removeable media login vector
bdosbase:	equ	pag$off-004h	; real BDOS entry point
hashl:		equ	pag$off+000h	; system variable
hash:		equ	pag$off+001h	; hash code
bdos$version:	equ	pag$off+005h	; BDOS version number
util$flgs:	equ	pag$off+006h	; utility flags
dspl$flgs:	equ	pag$off+00ah	; display flags
clp$flgs:	equ	pag$off+00eh	; CLP flags
clp$drv:	equ	pag$off+00fh	; submit file drive
prog$ret$code:	equ	pag$off+010h	; program return code
multi$rsx$pg:	equ	pag$off+012h	; multiple command buffer page
ccpdrv:		equ	pag$off+013h	; ccp default drive
ccpusr:		equ	pag$off+014h	; ccp default user number
ccpconbuf:	equ	pag$off+015h	; ccp console buffer address
ccpflag1:	equ	pag$off+017h	; ccp flags byte 1
ccpflag2:	equ	pag$off+018h	; ccp flags byte 2
ccpflag3:	equ	pag$off+019h	; ccp flags byte 3
conwidth:	equ	pag$off+01ah	; console width
concolumn:	equ	pag$off+01bh	; console COLUMN position
conpage:	equ	pag$off+01ch	; console page length (lines)
conline:	equ	pag$off+01dh	; current console line number
conbuffer:	equ	pag$off+01eh	; console input buffer address
conbuffl:	equ	pag$off+020h	; console input buffer length
conin$rflg:	equ	pag$off+022h	; console input redirection flag
conout$rflg:	equ	pag$off+024h	; console output redirection flag
auxin$rflg:	equ	pag$off+026h	; auxillary input redirection flag
auxout$rflg:	equ	pag$off+028h	; auxillary output redirection flag
listout$rflg:	equ	pag$off+02ah	; list output redirection flag
page$mode:	equ	pag$off+02ch	; page mode flag 0=on, 0ffH=off
page$def:	equ	pag$off+02dh	; page mode default
CTLH$ACT:	equ	pag$off+02eh	; ctl-h active
RUBOUT$ACT:	equ	pag$off+02fh	; rubout active (boolean)
type$ahead:	equ	pag$off+030h	; type ahead active
contran:	equ	pag$off+031h	; console translation subroutine
con$mode:	equ	pag$off+033h	; console mode (raw/cooked)
ten$buffer:	equ	pag$off+035h	; 128 byte buffer available
	; to banked BIOS
outdelim:	equ	pag$off+037h	; output delimiter
listcp:		equ	pag$off+038h	; list output flag (ctl-p)
q$flag:		equ	pag$off+039h	; queue flag for type ahead
scbad:		equ	pag$off+03ah	; system control block address
dmaad:		equ	pag$off+03ch	; dma address
seldsk:		equ	pag$off+03eh	; current disk
INFO:		equ	pag$off+03fh	; BDOS variable "INFO"
resel:		equ	pag$off+041h	; disk reselect flag
relog:		equ	pag$off+042h	; relog flag
FX:		equ	pag$off+043h	; function number
usrcode:	equ	pag$off+044h	; current user number
dcnt:		equ	pag$off+045h	; directory record number
searcha:	equ	pag$off+047h	; cfcb address for searchn function
searchl:	equ	pag$off+049h	; scan length for search functions
multcnt:	equ	pag$off+04ah	; multi-sector I/O count
errormode:	equ	pag$off+04bh	; BDOS error mode
drv0:		equ	pag$off+04ch	; search chain - 1st drive
drv1:		equ	pag$off+04dh	; search chain - 2nd drive
drv2:		equ	pag$off+04eh	; search chain - 3rd drive
drv3:		equ	pag$off+04fh	; search chain - 4th drive
tempdrv:	equ	pag$off+050h	; temporary file drive
patch$flag:	equ	pag$off+051h	; patch flags
date:		equ	pag$off+058h	; date stamp 
com$base:	equ	pag$off+05dh	; common memory base address
error:		equ	pag$off+05fh	; error jump...all BDOS errors
top$tpa:	equ	pag$off+062h	; top of user TPA (address at 6,7)
;
;	CCP FLAG 1 BIT MASKS
;	(used with getflg, setflg and resetflg routines)
;
chainflg:	equ	080h	; program chain (funct 49)
not$chainflg:	equ	03fh	; mask to reset chain flags
chainenv:	equ	040h	; preserve usr/drv for chained prog
comredirect:	equ	0b320h	; command line redirection active
menu:		equ	0b310h	; execute ccp.ovl for menu systems
echo:		equ	0b308h	; echo commands in batch mode
userparse:	equ	0b304h	; parse user numbers in commands
subfile:	equ	0b301h	; $$$.SUB file found or active
subfilemask:	equ	subfile-0b300h
rsx$only$set:	equ	02h	; RSX only load (null COM file)
rsx$only$clr:	equ	0FDh	; reset RSX only flag
;
;	CCP FLAG 2 BIT MASKS
;	(used with getflg, setflg and resetflg routines)
;
ccp10:		equ	0b4a0h	; CCP function 10 call (2 bits)
ccpsub:		equ	0b420h	; CCP present (for SUBMIT, PUT, GET)
ccpbdos:	equ	0b480h	; CCP present (for BDOS buffer save)
dskreset:	equ	20h	; CCP does disk reset on ^C from prompt
submit:		equ	0b440h	; input redirection active
submitflg:	equ	40h	; input redirection flag value
order:		equ	0b418h	; command order
	;  0 - COM only
	;  1 - COM,SUB
	;  2 - SUB,COM
	;  3 - reserved
datetime:	equ	0b404h	; display date & time of load
display:	equ	0b403h	; display filename & user/drive
filename:	equ	02h	; display filename loaded 
location:	equ	01h	; display user & drive loaded from
;
;	CCP FLAG 3 BIT MASKS
;	(used with getflg, setflg and resetflg routines)
;
rsxload:	equ	1h	; load RSX, don't fix chain
coldboot:	equ	2h	; try to exec profile.sub
;
;   	CONMODE BIT MASKS
;
ctlc$stat:	equ	0cf01h	;conmode CTL-C status
;
;
;************************************************************************
;
;	Console Command Processor - Main Program
;
;************************************************************************
;
;
;
	DEFINE CCP_SEG, SPACE = RAM
	SEGMENT CCP_SEG

	.ASSUME ADL = 0
	PUBLIC ccp_start

ccp_start:
start:	
;
	LD	sp,stack
	LD	HL,ccpret	;push CCPRET on stack, in case of
	PUSH	HL		;profile error we will go there
	LD	DE,scbadd
	LD	C,scbf
	CALL	bdos
	LD	(scbaddr),HL	;save SCB address
	LD	L,com$base+1
	LD	A,(HL)		;high byte of commonbase
	LD	(bankedp),A	;save in loader
	LD	L,bdosbase+1	;HL addresses real BDOS page
	LD	A,(HL)		;BDOS base in H
	LD	(realdos),A	;save it for use in XCOM routine
;
	LD	A,(osbase+1)	;is the LOADER in memory?
	SUB	A,(HL)		;compare link at 6 with real BDOS
	jp	nz,reset$alloc	;skip move if loader already present
;
;
movldr:	
	LD	BC,rsxend-rsxstart;length of loader RSX
	CALL	calcdest	;calculate destination and (bias+200h)
	LD	H,E		;set to zero
	LD	L,E
;	lxi	h,module-100h	;base of loader RSX (less 100h)
	CALL	reloc		;relocate loader
	LD	HL,(osbase)	;HL = BDOS entry, DE = LOADER base
	LD	L,E		;set L=0
	LD	C,6
	CALL	move		;move the serial number down
	LD	E,nextadd
	CALL	fixchain1
;
;
reset$alloc:	
	LD	C,allocf
	CALL	bdos
;
;	
;
;************************************************************************
;
;	INITIALIZE SYSTEM CONTROL BLOCK
;
;************************************************************************
;
;
scbinit:	
	;
	;	# dir columns, page size & function 9 delimiter
	;
	LD	B,conwidth	
	CALL	getbyte
	INC	A		;get console width (rel 1)
	RRCA	
	RRCA	
	RRCA	
	RRCA	
	AND	0fh		;divide by 16
	LD	DE,dircols
	LD	(DE),A		;dircols = conwidth/16
	LD	L,conpage
	LD	A,(HL)
	DEC	A		;subtract 1 for space before prompt
	INC	DE
	LD	(DE),A		;pgsize = conpage
	XOR	A
	INC	DE
	LD	(DE),A		;line=0
	LD	A,'$'
	INC	DE
	LD	(DE),A		;pgmode = nopage (>0)
	LD	L,outdelim
	LD	(HL),A		;set function 9 delimiter 
	;
	;	multisector count, error mode, console mode 
	;		& BDOS version no.
	;
	LD	L,multcnt 
	LD	(HL),1		;set multisector I/O count = 1
	INC	HL		;.errormode
	XOR	A
	LD	(HL),A		;set return error mode = 0
	LD	L,con$mode
	LD	(HL),1		;set ^C status mode
	INC	HL
	LD	(HL),A		;zero 2nd conmode byte
	LD	L,bdos$version
	LD	(HL),vers	;set BDOS version no.
	;
	;	disk reset check 
	;
	LD	L,ccpflag2
	LD	A,(HL)
	AND	dskreset	;^C at CCP prompt?
	LD	C,resetf
	PUSH	HL
	call	nz,bdos		;perform disk reset if so
	POP	HL
	;
	;	remove temporary RSXs (those with remove flag on)
	;
rsxck:	
	LD	L,ccpflag1	;check CCP flag for RSX only load
	LD	A,(HL)
	AND	rsx$only$set	;bit = 1 if only RSX has been loaded
	PUSH	HL
	call	z,rsx$chain	;don't fix-up RSX chain if so
	POP	HL
	LD	A,(HL)
	AND	rsx$only$clr	;clear RSX only loader flag
	LD	(HL),A		;replace it
	;
	;	chaining environment
	;
	AND	chainenv	;non-zero if we preserve programs
	PUSH	HL		;user & drive for next transient
	;
	;	user number
	;
	LD	L,ccpusr	; HL = .CCP USER (saved in SCB)
	LD	BC,usernum	; BC = .CCP'S DEFAULT USER
	LD	D,H
	LD	E,usrcode	; DE = .BDOS USER CODE
	LD	A,(DE)
	LD	(BC),A		; usernum = bdos user number
	LD	A,(HL)		; ccp user
	jp	nz,scb1		; jump if chaining env preserved
	LD	(BC),A		; usernum = ccp default user
scb1:	LD	(DE),A		; bdos user = ccp default user
	;
	;	transient program's current disk
	;
	INC	BC		;.CHAINDSK
	LD	E,seldsk	;.BDOS CURRENT DISK
	LD	A,(DE)
	jp	nz,scb2		; jump if chaining env preserved
	LD	A,0ffh
;	cma			; make an invalid disk
scb2:	LD	(BC),A		; chaindsk = bdos disk (or invalid)
	;
	;	current disk
	;
	DEC	HL		;.CCP's DISK (saved in SCB)
	INC	BC		;.CCP's CURRENT DISK
	LD	A,(HL)
	LD	(BC),A
	LD	(DE),A		; BDOS current disk
	;
	;	$$$.SUB drive 
	;
	LD	L,tempdrv 
	INC	BC		;.SUBFCB
	LD	A,(HL)
	LD	(BC),A		; $$$.SUB drive = temporary drive
	;	
	;	check for program chain
	;
	POP	HL		;HL =.ccpflag1
	LD	A,(HL)
	AND	chainflg	;is it a chain function (47)
	jp	z,ckboot		;jump if not
	LD	HL,buf 
chain:	LD	DE,cbufl 
	LD	C,tpa-buf-1
	LD	A,C
	LD	(DE),A
	INC	DE
	CALL	move		;hl = souret	ce, de = dest, c = count
	JP	ccpparse
	;	
	;	execute profile.sub ?
	;
ckboot:	LD	L,ccpflag3
	LD	A,(HL)
	AND	coldboot	;is this a cold start
	jp	nz,ccpcr		;jump if not
	LD	A,(HL)
	OR	coldboot	;set flag for next time
	LD	(HL),A
	LD	(errflg),A	;set to ignore errors
	LD	HL,profile
	JP	chain		;attempt to exec profile.sub
profile:	
	DB	'PROFILE.S',0
;
;
;
;************************************************************************
;
;	BUILT-IN COMMANDS (and errors) RETURN HERE
;
;************************************************************************
;
;
ccpcr:	
	;	enter here on each command or error condition
	CALL	setccpflg
	CALL	ccp_crlf
ccpret:	
	LD	HL,stack-2	;reset stack in case of error
	LD	SP,HL		;preserve CCPRET on stack
	XOR	A
	LD	(line),A
	LD	HL,ccpret	;return for next builtin
	PUSH	HL
	CALL	setccpflg
	DEC	HL		;.CCPFLAG1
	LD	A,(HL)
	AND	subfilemask	;check for $$$.SUB submit
	jp	z,prompt
;
;
;
;************************************************************************
;
;	$$$.SUB file processing
;
;************************************************************************
;
;
	LD	DE,cbufl	;set DMA to command buffer
	CALL	setbuf
	LD	C,openf
	CALL	sudos		;open it if flag on
	LD	C,cstatf	;check for break if successful open
	call	z,sudos		;^C typed?
	jp	nz,subclose	;delete $$$.SUB if break or open failed
	LD	HL,subrr2
	LD	(HL),A		;zero high random record #
	DEC	HL
	LD	(HL),A		;zero middle random record #
	DEC	HL
	PUSH	HL
	LD	A,(subrc) 
	DEC	A 	
	LD	(HL),A		;set to read last record of file
	LD	C,rreadf
	call	p,sudos
	POP	HL
	DEC	(HL)		;record count (truncate last record)
	LD	C,delf
	call	m,sudos
	OR	A		;error on read?
	;
	;
subclose:	
	PUSH	AF
	LD	C,trunf		;truncate file (& close it)
	CALL	sudos
	POP	AF		;any errors ?
	jp	z,ccpparse	;parse command if not
	;
	;
subkill:	
	LD	BC,subfile
	CALL	resetflg	;turn off submit flag
	LD	C,delf
	CALL	sudos		;kill submit
;
;
;
;************************************************************************
;
;	GET NEXT COMMAND
;
;************************************************************************
;
;
	;
	; 	prompt user
	;
prompt:	
	LD	A,(usernum)
	OR	A 
	call	nz,pdb		;PRINT user # if non-zero
	CALL	dirdrv1
	LD	A,'>' 
	CALL	putc
	;
IF	multi
	;move ccpconbuf addr to conbuffer addr
	LD	DE,ccpconbuf*256+conbuffer
	CALL	wordmov		;process multiple command, unless in submit
	OR	A		;non-zero => multiple commands active
	PUSH	AF		;save A=high byte of ccpconbuf
	LD	BC,ccpbdos
	call	nz,resetflg	;turn off BDOS flag if multiple commands
ENDIF				;multi
	CALL	rcln		;get command line from console
	CALL	resetccpflg	;turn off BDOS, SUBMIT & GET ccp flags
IF	multi
	POP	AF		;D=high byte of ccpconbuf
	call	nz,multisave	;save multiple command buffer
ENDIF				;multi
;
;
;
;************************************************************************
;
;	PARSE COMMAND
;
;************************************************************************
;
;
ccpparse:	
	;
	;	reset default page mode 
	;	(in case submit terminated)
	;
	CALL	subtest		;non-zero if submit is active
	jp	nz,get$pg$mode	;skip, if so
set$pg$mode:	
	LD	L,page$def
	LD	A,(HL)		;pick up default
	DEC	HL
	LD	(HL),A		;place in mode
get$pg$mode:	
	LD	L,page$mode
	LD	A,(HL)
	LD	(pgmode),A
	;
	;check for multiple commands
	;convert to upper case
	;reset ccp flag, in case entered from a CHAIN (or profile)
	;
	CALL	uc		;convert to upper case, ck if multiple command
	ret	z			;get another line if null or comment
	;
	;transient or built-in command?
	;
	LD	DE,ucfcb		;include user number byte in front of FCB
	CALL	gcmd		;parse command name
	LD	A,(cfcb+9)	;file type specified?
	CP	' '
	jp	nz,ccpdisk2	;execute from disk, if so
	LD	HL,ucfcb		;user or drive specified?
	LD	A,(HL)		;user number
	INC	HL
	OR	(HL)		;drive
	INC	HL
	LD	A,(HL)		;get 1st character of filename
	jp	nz,ccpdisk3	;jump if so
	;
	;BUILT-IN HANDLER
	;
ccpbuiltin:	
	LD	HL,ctbl		;search table of internal commands
	LD	DE,cfcb+1
	LD	A,(cfcb+3)
	CP	' '+1		;is it shorter that 3 characters?
	call	nc,tbls		;is it a built-in?
	jp	nz,ccpdisk0	;load from disk if not
	LD	A,(option)	;[ in command line?
	OR	A		;options specified?
	LD	A,B		;built-in index from tbls
	LD	HL,(parsep)
	LD	(errsav),HL	;save beginning of command tail
	LD	HL,ptbl		;jump to processor if options not
	jp	z,tblj		;specified
	CP	4
	jp	c,trycom
	LD	HL,cfcb+4
	jp	nz,ccpdisk0	;if DIRS then look for DIR.COM
	LD	(HL),' '
	;
	;LOAD TRANSIENT (file type unspecified)
	;
ccpdisk0:	
	LD	BC,order
	CALL	getflg		;0=COM   8=COM,SUB  16=SUB,COM
	jp	z,ccpdisk2	;search for COM file only
	LD	B,8		;=> 2nd choice is SUB
	SUB	A,B		;now a=0 (COM first) or 8 (SUB first)
	jp	z,ccpdisk1	;search for COM first then SUB
	LD	B,0		;search for SUB first then COM
ccpdisk1:	
	PUSH	BC		;save 2nd type to try
	CALL	settype		; A = offset of type in type table
	CALL	exec		;try to execute, return if unsuccessful
	POP	AF		;try 2nd type 
	CALL	settype
	;
	;LOAD TRANSIENT (file type specified)
	;
ccpdisk2:	
	CALL	exec
	JP	perror		;error if can't find it
	;
	;DRIVE SPECIFIED (check for change drives/users command)
	;
ccpdisk3:	
	CP	' '		;check for filename
	jp	nz,ccpdisk0	;execute from disk if specified
	CALL	eoc		;error if not end of command
	LD	A,(ucfcb)	;user specified?
	SUB	A,1
	jp	c,ccpdrive
ccpuser:	
	LD	(usernum),A	;CCP's user number
	LD	B,ccpusr
	CALL	setbyte		;save it in SCB
	CALL	setuser		;set current user
ccpdrive:	
	LD	A,(cfcb)		;drive specified?
	DEC	A
	ret	m		;return if not
	PUSH	AF
	CALL	select
	POP	AF
	LD	(disk),A	;CCP's drive
	LD	B,ccpdrv
	JP	setbyte		;save it in SCB
;;
;
;************************************************************************
;
;	BUILT-IN COMMANDS 
;
;************************************************************************
;
;
;	Table of internal ccp commands
;
;
ctbl:	DB	'DIR '
	DB	'TYPE '
	DB	'ERASE '
	DB	'RENAME '
	DB	'DIRSYS '
	DB	'USER '
	DB	0
;
ptbl:	DW	dir
	DW	type
	DW	era
	DW	ren
	DW	dirs
	DW	user
;;
;;-----------------------------------------------------------------------
;;
;;	DIR Command
;;
;;	DIR		list directory of current default user/drive
;;	DIR <X>:	list directory of user/drive <X>
;;	DIR <AFN>	list all files on the current default user/drive
;;			with names that match <AFN>
;;	DIR <X>:<AFN>	list all files on user/drive <X> with names that
;;			match <AFN>
;;
;;-----------------------------------------------------------------------
;;
;
	if	newdir
dirdrv:	
	LD	A,(dcfcb)	;get disk number
	endif			;newdir
dirdrv0:	
	DEC	A
	jp	p,dirdrv2
dirdrv1:	
	LD	A,(disk)	;get current disk
dirdrv2:	
	ADD	A,'A'
	JP	pfc		;PRINT it (save BC,DE)
;
;
	if	newdir
dir:	
	LD	C,0		;flag for DIR (normal)
	LD	DE,sysfiles
	JP	dirs1
;
;
dirs:	
	LD	C,080h		;flag for DIRS (system)
	LD	DE,dirfiles
dirs1:	PUSH	DE
; [JCE] Patch 15
	XOR	A		;Reset "anyfiles" before starting
	LD	(anyfiles),A	; - it might not have been cleared
	CALL	direct
	POP	DE		;de = .system files message
	jp	z,nofile		;jump if no files found
	LD	A,L		;A = number of columns
	CP	B		;did we PRINT any files?
	call	nc,ccp_crlf		;PRINT CRLF if so
	LD	HL,anyfiles
	DEC	(HL)
	INC	(HL)
	ret	z			;return if no files 
	;except those requested
	DEC	(HL)		;set to zero
	JP	pmsgnl		;tell the operator other files exist
;
;
direct:	
	PUSH	BC		;save DIR/DIRS flag
	CALL	sbuf80		;set DMA = 80h
	CALL	gfn		;parse file name
	LD	DE,dcfcb+1
	LD	A,(DE)
	CP	' '
	LD	B,11
	call	z,setmatch	;use "????????.???" if none
	CALL	eoc		;make sure there's nothing else
	CALL	srchf		;search for first directory entry
	POP	BC
	ret	z			;if no files found
dir0:	
	LD	A,(dircols)	;number of columns for dir
	LD	L,A
	LD	B,A
	INC	B		;set # names to PRINT per line (+1)
dir1:	
	PUSH	HL		;L=#cols, B=curent col, C=dir/dirs 
	LD	HL,10		;get byte with SYS bit
	ADD	HL,DE
	LD	A,(HL)
	POP	HL
	AND	80h		;look at SYS bit
	CP	C		;DIR/DIRS flag in C
	jp	z,dir2		;display, if modes agree
	LD	A,1		;set anyfiles true
	LD	(anyfiles),A
	JP	dir3		;don't PRINT anything
;
;	display the filename
;
dir2:	
	DEC	B
	call	z,dirln		;sets no. of columns, puts CRLF
	LD	A,B		;number left to PRINT on line
	CP	L		;is current col = number of cols
	call	z,dirdrv		;display the drive, if so
	LD	A,':'
	CALL	pfc		;PRINT colon
	CALL	space
	CALL	pfn		;PRINT file name
	CALL	space		;pad with space
dir3:	
	PUSH	BC		;save current col(B), DIR/DIRS(C)
	PUSH	HL		;save number of columns(L)
	CALL	break		;drop out if keyboard struck
	CALL	srchn		;search for another match
	POP	HL
	POP	BC
	jp	nz,dir1
direx:	
	INC	A		;clear zero flag 
	RET	
	else			;newdir
dirs:	; display system files only
	LD	A,0d2h		; JNC instruction
	LD	(dir11),A	; skip on non-system files
;
dir:	; display non-system files only
	LD	HL,ccpcr
	PUSH	HL		; push return address
	CALL	gfn		;parse file name
	INC	DE
	LD	A,(DE)
	CP	' '
	LD	B,11
	call	z,setmatch	;use "????????.???" if none
	CALL	eoc		;make sure there's nothing else
	CALL	findone		;search for first directory entry
	jp	z,dir4
	LD	B,5		;set # names to PRINT per line
dir1:	LD	HL,10		;get byte with SYS bit
	ADD	HL,DE
	LD	A,(HL)
	RLA			;look at SYS bit
dir11:	jp	c,dir3		;don't PRINT it if SYS bit set
	LD	A,B
	PUSH	BC
dir2:	LD	HL,9		;get byte with R/O bit
	ADD	HL,DE
	LD	A,(HL)
	RLA			;look at R/O bit
	LD	A,' '		;PRINT space if not R/O
	jp	nc,dir21		;jump if not R/O
	LD	A,'*'		;PRINT star if R/O
dir21:	CALL	pfc		;PRINT character
	CALL	pfn		;PRINT file name
	LD	A,13		;figure out how much padding is needed
	SUB	A,C
dir25:	PUSH	AF
	CALL	space		;pad it out with spaces
	POP	AF
	DEC	A
	jp	nz,dir25		;loop if more required
	POP	BC
	DEC	B		;decrement # names left on line
	jp	nz,dir3
	CALL	ccp_crlf		;go to new line
	LD	B,5		;set # names to PRINT on new line
dir3:	PUSH	BC
	CALL	break		;drop out if keyboard struck
	CALL	srchn		;search for another match
	POP	BC
	jp	nz,dir1
dir4:	LD	A,0dah		;JC instruction
	LD	(dir11),A	;restore normal dir mode (skip system files)
	JP	ccpcr
	endif			;newdir
;;
;;-----------------------------------------------------------------------
;;
;;	TYPE command
;;
;;	TYPE <UFN>	Print the contents of text file <UFN> on
;;			the console.
;;
;;-----------------------------------------------------------------------
;;
type:	LD	HL,ccpcr
	PUSH	HL		;push return address
	CALL	getfn		;get and parse filename
	LD	A,127		;initialize buffer pointer
	LD	(bufp),A
	LD	C,openf
	CALL	sbdosf		;open file if a filename was typed
type1:	CALL	break		;exit if keyboard struck
	CALL	getb		;read byte from file
	ret	nz		;exit if physical eof or read error
	CP	EOF		;check for eof character
	ret	z		;exit if so
	CALL	putc		;PRINT character on console
	JP	type1		;loop
;
;;-----------------------------------------------------------------------
;;
;;	USER command
;;
;;	USER <NN>	Set the user number
;;
;;-----------------------------------------------------------------------
;;
user:	
	LD	DE,unmsg	;Enter User #:
	CALL	getprm
	CALL	gdn		;convert to binary
	ret	z			;return if nothing typed
	JP	ccpuser		;set user number 
;
;;-----------------------------------------------------------------------
;;
;;	ERA command
;;
;;	ERA <AFN>	Erase all file on the current user/drive
;;			which match <AFN>.
;;	ERA <X>:<AFN>	Erase all files on user/drive <X> which
;;			match <AFN>.
;;
;;-----------------------------------------------------------------------
;;
era:	CALL	getfn		;get and parse filename
	jp	z,era1
	CALL	ckafn		;is it ambiguous?
	jp	nz,era1
	LD	DE,eramsg
	CALL	pmsg
	LD	HL,(errorp)
	LD	C,' '		;stop at exclamation mark or 0
	CALL	pstrg		;echo command
	LD	DE,confirm
	CALL	getc
	CALL	ccp_crlf
	LD	A,L		;character in L after CRLF routine
	AND	5fh		;convert to U/C
	CP	'Y'		;Y (yes) typed?
	ret	nz		;return, if not
	OR	A		;reset zero flag
era1:	LD	C,delf	
	JP	sbdosf
;;-----------------------------------------------------------------------
;;
;;
;;	REN command
;;
;;-----------------------------------------------------------------------
;;
ren:	CALL	gfn		;zero flag set if nothing entered
	PUSH	AF		
	LD	HL,16
	ADD	HL,DE
	EX	DE,HL
	PUSH	DE		;DE = .dcfcb+16
	PUSH	HL		;HL = .dcfcb
	LD	C,16
	CALL	move		;DE = dest, HL = souret	ce
	CALL	gfn
	POP	HL		;HL=.dcfcb
	POP	DE		;DE=.dcfcb+16
	CALL	drvok
	LD	C,renf		;make rename call
	POP	AF		;zero flag set if nothing entered
;
;;-----------------------------------------------------------------------
;;
;;	BUILT-IN COMMAND BDOS CALL & ERROR HANDLERS
;;
;;-----------------------------------------------------------------------
;
sbdosf:	
	PUSH	AF
	call	nz,eoc		;make sure there's nothing else
	POP	AF
	LD	DE,dcfcb
	LD	B,0ffh
	LD	H,1		;execute disk command if we don't call
	call	nz,bdosf		;call if something was entered
	ret	nz		;return if successful
ferror:	
	DEC	H		;was it an extended error?
	jp	m,nofile
	LD	HL,(errsav)
	LD	(parsep),HL
trycom:	CALL	exec
	CALL	pfn
	LD	DE,required
	JP	builtin$err
;
;;-----------------------------------------------------------------------
;
;
;	check for drive conflict
;	HL =  FCB 
;	DE =  FCB+16
;
drvok:	LD	A,(DE)		;get byte from 2nd cfcb
	CP	(HL)		;ok if they match
	ret	z	
	OR	A		;ok if 2nd is 0
	ret	z	
	INC	(HL)		;error if the 1st one's not 0
	DEC	(HL)
	jp	nz,perror
	LD	(HL),A		;copy from 2nd to 1st
	RET	
;;-----------------------------------------------------------------------
;;
;;	check for ambiguous reference in file name/type
;;
;;	entry:	b  = length of string to check (ckafn0)
;;		de = cfcb area to check (ckafn0) - 1
;;	exit:	z  = set if any ? in file reference (ambiguous)
;;		z  = clear if unambiguous file reference
;;
ckafn:	
	LD	B,11		;check entire name and type
ckafn0:	INC	DE
	LD	A,(DE)
	CP	'?'		;is it an ambiguous file name
if	newera
	ret	z			;return true if any afn
else	;newera
	ret	nz		;return true only if *.*
endif	;newera
	DEC	B
	jp	nz,ckafn0
if	newera
	DEC	B		;clear zero flag to return false
endif	;newera
	RET			;remove above DCR to return true
;;
;;-----------------------------------------------------------------------
;;
;;	get parameter (generally used to get a missing one)
;;
getprm:	
	CALL	skps		;see if already there
	ret	nz		;return if so
getp0:	
	if	prompts
	PUSH	DE
	LD	DE,enter
	CALL	pmsg
	POP	DE
	endif	
	CALL	pmsg		;PRINT prompt
	CALL	rcln		;get response
	JP	uc		;convert to upper case
;
;;
;;-----------------------------------------------------------------------
if .not. newdir
;;
;;	search for first file, PRINT "No File" if none
;;
findone:	
	CALL	srchf
	ret	nz		;found
	endif			;not newdir
;;-----------------------------------------------------------------------
nofile:	
	LD	DE,nomsg	;tell user no file found
builtin$err:	
	CALL	pmsgnl
	JP	ccpret
;
;
;************************************************************************
;
;	EXECUTE DISK RESIDENT COMMAND
;
;************************************************************************
;
;
xcfcb: DB	0,'SUBMIT  COM'	;processor cfcb
;
;
;	execute submit file  (or any other processor)
;
xsub:	;DE = .cfcb
	LD	A,(DE)
	LD	B,clp$drv
	CALL	setbyte		;save submit file drive
	LD	HL,xcfcb
	LD	C,12
	CALL	move		;copy processor into cfcb
	LD	HL,cbufl	;set parser pointer back to beginning
	LD	(HL),' '
	INC	HL		;move past blank
	LD	(parsep),HL
;				 execute SUBMIT.COM
;
;	
;	execute disk resident command (return if not found or error)
;
exec:	
	;try to open and execute cfcb
	LD	DE,cfcb+9
	LD	HL,typtbl
	CALL	tbls		;search for type in type table
	ret	nz		;return if no match
	LD	DE,ucfcb
	LD	A,(DE)		;check to see if user specified
	OR	A
	ret	nz		;return if so
	INC	DE
	LD	A,(DE)		;check if drive specified
	LD	C,A
	PUSH	BC		;save type (B) and drive (C)
	LD	C,0		;try only 1 open if drive specified
	OR	A
	jp	nz,exec1		;try to open as specified
drv_chn_open	equ (drv0 - 1) * 256 + 4
	LD	BC,drv_chn_open	;try upto four opens from drv chain
	LD	A,(disk)
	INC	A
	LD	H,A		;save default disk in H
	LD	L,1		;allow only 1 match to default disk
exec0:	INC	B		;next drive to try in SCB drv chain
	DEC	C		;any more tries?
	LD	A,C
	PUSH	HL
	call	p,getbyte
	POP	HL
	OR	A
	jp	m,exec3
	jp	z,exec01	;jump if drive is 0 (default drive)
	CP	H		;is it the default drive
	jp	nz,exec02	;jump if not
exec01:	LD	A,H		;set drive explicitly
	DEC	L		;is it the 2nd reference 
	jp	m,exec0		;skip, if so
exec02:	LD	(DE),A		;put drive in FCB
exec1:	PUSH	BC		;save drive offset(B) & count(C)
	PUSH	HL
	CALL	opencom		;on default drive & user
	POP	HL
	POP	BC
	jp	z,exec0		;try next if open unsuccessful
;
;	successful open, now jump to processor
;	
exec2:	
	if	dayfile
	LD	BC,display
	CALL	getflg
	jp	z,exec21
	LD	A,(DE)
	CALL	dirdrv0
	LD	A,':'
	CALL	pfc
	PUSH	DE
	CALL	pfn
	POP	DE
	PUSH	DE
	LD	HL,8
	ADD	HL,DE
	LD	A,(HL)
	AND	80h
	LD	DE,userzero
	call	nz,pmsg
	CALL	ccp_crlf
	POP	DE
	endif			;dayfile
exec21:	POP	AF		;recover saved command type
	LD	HL,xptbl
;
;	table jump
;
;	entry:	hl = address of table of addresses
;		a  = entry # (0 thru n-1)
;
tblj:	ADD	A,A		;adjust for two byte entries
	CALL	addhla		;compute address of entry
	PUSH	DE
	LD	E,(HL)		;fetch entry
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	POP	DE
	JP	(HL)		;jump to it
;
typtbl:	DB	'COM '
	DB	'SUB '
	DB	'PRL '
	DB	0
;
xptbl:	DW	xcom
	DW	xsub
	DW	xcom
;
;	unsuccessful attempt to open command file
;
exec3:	POP	BC		;recover drive
	LD	A,C
	LD	(DE),A		;replace in cfcb
	RET	
;
;
settype:	
	;set file type specified from type table
	;a = offset (x2) of desired type (in bytes)
	RRCA	
	LD	HL,typtbl
	CALL	addhla		;hl = type in type table
	LD	DE,cfcb+9
	LD	C,3
	JP	move		;move type into cfcb
;
;
;
;	EXECUTE COM FILE
;
xcom:	;DE = .cfcb
	;
	;	set up FCB for loader to use
	;
	LD	HL,tpa
	LD	(cfcbrr),HL	;set load address to 100h
	LD	HL,(realdos-1)	;put cfcb in the loader's stack
	DEC	H		;page below LOADER (or bottom RSX)
	LD	L,0C0h		;offset for FCB in page below the BDOS
	PUSH	HL		;save for LOADER call
	LD	A,(DE)		;get drive from cfcb(0)
	LD	(cmdrv),A	;set command drive field in base page
	EX	DE,HL
	LD	C,35
	CALL	move		;now move FCB to the top of the TPA
	;	
	;	set up base page
	;
	LD	HL,errflg	;tell parser to ignore errors
	INC	(HL)
xcom3:	LD	HL,(parsep)
	DEC	HL		;backup over delimiter
	LD	DE,buf+1
	EX	DE,HL
	LD	(parsep),HL	;set parser to 81h
	CALL	copy0		;copy command tail to 81h with
	;terminating 0 (returns A=length)
	LD	(buf),A		;put command tail length at 80h
xcom5:	CALL	gfn		;parse off first argument
	LD	(pass0),HL
	LD	A,B
	LD	(len0),A
	LD	DE,dcfcb1
	CALL	gfn0		;parse off second argument
	LD	(pass1),HL
	LD	A,B
	LD	(len1),A
xcom7:	LD	HL,chaindsk	;.CHAINDSK
	LD	A,(HL)
	OR	A
	call	p,select
	LD	A,(usernum)
	CALL	setuser		;set default user, returns H=SCB
	ADD	A,A		;shift user to high nibble
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	L,seldsk
	OR	(HL)		;put disk in low nibble
	LD	(defdrv),A	;set location 4 
	;
	; 	initialize stack
	;
xcom8:	POP	DE		;DE = .cfcb
	LD	HL,(realdos-1)	;base page of BDOS
	XOR	A
	LD	L,A		;top of stack below BDOS
	LD	SP,HL		;change the stack pointer for CCP
	LD	H,A		;push warm start address on stack
	PUSH	HL		;for programs returning to the CCP
	INC	H		;Loader will return to TPA
	PUSH	HL		;after loading a transient program
	;
	;	initialize cfcb0(CR), console mode, program return code
	;	& removable media open and login vectors
	;
xcom9:	LD	(7ch),A		;clear next record to read
	LD	B,con$mode
	CALL	setbyte		;set to zero (turn off ^C status)
	LD	L,olog
	LD	(HL),A		;zero removable open login vector
	INC	HL
	LD	(HL),A
	INC	HL
	LD	(HL),A		;zero removable media login vector
	INC	HL
	LD	(HL),A
	LD	L,ccpflag1
	LD	A,(HL)
	AND	chainflg	;chaining?
	jp	nz,loader	;load program without clearing
	LD	L,prog$ret$code	;the program return code
	LD	(HL),A		;A=0
	INC	HL
	LD	(HL),A		;set program return = 0000h
	;
	;	call loader
	;
loader:	
	LD	A,(HL)		;reset chain flag if set,
	AND	not$chainflg	;has no effect if we fell through
	LD	(HL),A
	LD	C,loadf		;use load RSX to load file
	JP	bdos		;now load it
;
;
;
;
;************************************************************************
;
;	BDOS FUNCTION INTERFACE - Non FCB functions
;
;************************************************************************
;
;
;
;;-----------------------------------------------------------------------
;;
;;
;;
;;	PRINT character on terminal
;;	pause if screen is full
;;	(BDOS function #2)
;;
;;	entry:	a  = character (putc entry)
;;		e  = character (putc2 entry)
;;
putc:	CP	LF		;end of line?
	jp	nz,putc1		;jump if not
	LD	HL,pgsize	;.pgsize
	LD	A,(HL)		;check page size
	INC	HL		;.line
	INC	(HL)		;line=line+1
	SUB	A,(HL)		;line=page?
	jp	nz,putc0		
	LD	(HL),A		;reset line=0 if so
	INC	HL		;.pgmode
	LD	A,(HL)		;is page mode off?
	OR	A		;page=0 if so
	LD	DE,more
	call	z,getc		;wait for input if page mode on
	CP	CTLC
	jp	z,ccpcr
	LD	E,CR
	CALL	putc2		;PRINT a cr
putc0:	LD	A,LF		;PRINT the end of line char
putc1:	LD	E,A
putc2:	LD	C,coutf
	JP	bdos
;;
;;-----------------------------------------------------------------------
;;
;;	get character from console
;;	(BDOS function #1)
;;
getc:	CALL	pmsg
getc1:	LD	C,cinf
	JP	bdos
;;
;;-----------------------------------------------------------------------
;;
;;	PRINT message string on terminal
;;	(BDOS function #9)
;;
pmsg:	LD	C,pbuff
	JP	bdos
;;
;;-----------------------------------------------------------------------
;;
;;	read line from console
;;	(calls BDOS function #10)
;;
;;	exit:	z  = set if null line
;;
;;	This function uses the buffer "cbuf" (see definition of
;;	function 10 for a description of the buffer).  All input
;;	is converted to upper case after reading and the pointer
;;	"parsep" is set to the begining of the first non-white
;;	character string.
;;
rcln:	LD	HL,cbufmx	;get line from terminal
	LD	(HL),comlen	;set maximum buffer size
	EX	DE,HL
	LD	C,rbuff
	CALL	bdos
	LD	HL,cbufl	;terminate line with zero byte
	LD	A,(HL)
	INC	HL
	CALL	addhla
	LD	(HL),0		;put zero at the end 
	JP	ccp_crlf		;advance to next line
;
;;
;;-----------------------------------------------------------------------
;;
;;	exit routine if keyboard struck
;;	(calls BDOS function #11)
;;
;;	Control is returned to the caller unless the console
;;	keyboard has a character ready, in which case control
;;	is transfer to the main program of the CCP.
;;
break:	CALL	break1	
	ret	z	
	JP	ccpcr
break1:	LD	C,cstatf
	CALL	rw
	ret	z	
	LD	C,cinf
	JP	rw
;;
;;-----------------------------------------------------------------------
;;
;;	set disk buffer address
;;	(BDOS function #26)
;;
;;	entry:	de -> buffer ("setbuf" only)
;;
sbuf80:	LD	DE,buf
setbuf:	LD	C,dmaf
	JP	bdos
;;
;;-----------------------------------------------------------------------
;;
;;	select disk
;;	(BDOS function #14)
;;
;;	entry:	a  = drive
;;
select:	
	LD	E,A
	LD	C,self
	JP	bdos
;
;;
;;-----------------------------------------------------------------------
;;
;;	set user number
;;	(BDOS function #32)
;;
;;	entry:	a  = user # 
;;	exit:	H  = SCB page
;;
setuser:	
	LD	B,usrcode 
	JP	setbyte
;
;
;
;************************************************************************
;
;	BDOS FUNCTION INTERFACE - Functions with a FCB Parameter
;
;************************************************************************
;
;
;;
;;	open file 
;;	(BDOS function #15)
;;
;;	exit:	z  = set if file not found
;;
;;
opencom:	;open command file (SUB, COM or PRL)
	LD	BC,openf	;b=0 => return error mode of 0
	LD	DE,cfcb		;use internal FCB
;;	BDOS CALL ENTRY POINT   (used by built-ins)
;;
;;	entry:	b  = return error mode (must be 0 or 0ffh)
;;		c  = function no.
;;		de = .cfcb
;;	exit:	z  = set if error
;;		de = .cfcb
;;
bdosf:	LD	HL,32		;offset to current record
	ADD	HL,DE		;HL = .current record
	LD	(HL),0		;set to zero for read/write
	PUSH	BC		;save function(C) & error mode(B)
	PUSH	DE		;save .cfcb
	LD	A,(DE)		;was a disk specified?
	AND	B		;and with 0 or 0ffh
	DEC	A		;if so, select it in case
	call	p,select	;of permanent error (if errmode = 0ffh)
	LD	DE,passwd
	CALL	setbuf		;set dma to password
	POP	DE		;restore .cfcb
	POP	BC		;restore function(C) & error mode(B)
	PUSH	DE
	LD	HL,(scbaddr)
	LD	L,errormode
	LD	(HL),B		;set error mode
	PUSH	HL		;save .errormode
	CALL	bdos
	POP	DE		;.errormode
	XOR	A
	LD	(DE),A		;reset error mode to 0
	LD	A,(disk)
	LD	E,seldsk
	LD	(DE),A		;reset current disk to default
	PUSH	HL		;save bdos return values
	CALL	sbuf80
	POP	HL		;bdos return
	INC	L		;set z flag if error
	POP	DE		;restore .cfcb
	RET	
;;
;;-----------------------------------------------------------------------
;;
;;	close file 
;;	(BDOS function #16)
;;
;;	exit:	z  = set if close error
;;
;;close:	mvi	c,closef
;;		jmp	oc
;;
;;-----------------------------------------------------------------------
;;
;;	delete file 
;;
;;	exit:	z  = set if file not found
;;
;;	The match any character "?" may be used without restriction
;;	for this function.  All matched files will be deleted.
;;
;;
;;delete:
;;	mvi	c,delf
;;	jmp	oc
;;
;;-----------------------------------------------------------------------
;;
;;	create file 
;;	(BDOS function #22)
;;
;;	exit:	z  = set if create error
;;
;;make:		mvi	c,makef
;;		jmp	oc
;;-----------------------------------------------------------------------
;;
;;	search for first filename match (using "DFCB" and "BUF")
;;	(BDOS function #17)
;;
;;	exit:	z  = set if no match found
;;		z  = clear if match found
;;		de -> directory entry in buffer
;;
srchf:	LD	C,searf		;set search	ch first function
	JP	srch
;;
;;-----------------------------------------------------------------------
;;
;;	search for next filename match (using "DFCB" and "BUF")
;;	(BDOS function #18)
;;
;;	exit:	z  = set if no match found
;;		z  = clear if match found
;;		de -> directory entry in buffer
;;
srchn:	LD	C,searnf	;set search	ch next function
srch:	LD	DE,dcfcb		;use default cfcb
	CALL	bdos
	INC	A		;return if not found
	ret	z	
	DEC	A		;restore original return value
	ADD	A,A		;shift to compute buffer pos'n
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	HL,buf		;add to buffer start address
	CALL	addhla
	EX	DE,HL		;de -> entry in buffer
	XOR	A		;may be needed to clear z flag
	DEC	A		;depending of value of "buf"
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
read:	XOR	A		;clear getc pointer
	LD	(bufp),A
	LD	C,readf
	LD	DE,dcfcb
rw:	CALL	bdos
	OR	A
	RET	
;
;;
;;-----------------------------------------------------------------------
;;
;;	$$$.SUB interface
;;
;;	entry:	c = bdos function number
;;	exit	z  = set if successful
sudos:	LD	DE,subcfcb
	JP	rw
;
;
;
;************************************************************************
;
;	COMMAND LINE PARSING SUBROUTINES 
;
;************************************************************************
;
;------------------------------------------------------------------------
;
;	COMMAND LINE PREPARSER
;	reset function 10 flag
;	set up parser
;	convert to upper case
;
;	All input is converted to upper case and the pointer
;	"parsep" is set to the begining of the first non-blank
;	character string.  If the line begins with a ; or :, it
;	is treated specially:
;
;		;	comment 	the line is ignored
;		:	conditional	the line is ignored if a fatal
;					error occured during the previous
;					command, otherwise the : is 
;					ignored
;
;	An exclamation point is used to separate multiple commands on a 
;	a line.  Two adjacent exclaimation points translates into a single 
;	exclaimation point in the command tail for compatibility.
;------------------------------------------------------------------------
;
;
uc:	
	CALL	resetccpflg
	EX	DE,HL		;DE = .SCB
	XOR	A
	LD	(option),A	;zero option flag
	LD	HL,cbuf
	CALL	skps1		;skip leading spaces/tabs
	EX	DE,HL
	CP	';'		;HL = .scb
	ret	z	
	CP	'!'
	jp	z,uc0
	CP	':'
	jp	nz,uc1
;
;[JCE] this fragment rewritten not to trash the program return code when 
;      reading it.
;
	LD	L,prog$ret$code
	LD	A,(HL)		;[JCE]
	INC	A		;[JCE]
	INC	A		;[JCE]
;;;	inr	m
;;;	inr	m		;was ^C typed? (low byte 0FEh)
	jp	z,uc0		;successful, if so
	INC	HL
	LD	A,(HL)		;[JCE]
	INC	A		;[JCE]
;;;	inr	m		;is high byte 0FFh?
	ret	z			;skip command, if so
uc0:	INC	DE		;skip over 1st character
uc1:	EX	DE,HL		;HL=.command line
	LD	(parsep),HL	;set parse pointer to beginning of line
uc3:	LD	A,(HL)		;convert lower case to upper
	CP	'['
	jp	nz,uc4
	LD	(option),A	;'[' is the option delimiter => command option
uc4:	CP	'a'
	jp	c,uc5
	CP	'z'+1
	jp	nc,uc5
	SUB	A,'a'-'A'
	LD	(HL),A
uc5:	
	if	multi
	CP	'!'
	call	z,multistart	;HL=.char, A=char
	endif			;multi
	INC	HL		;advance to next character
	OR	A		;loop if not end of line
	jp	nz,uc3
;
;	skip spaces
;	return with zero flag set if end of line
;
skps:	LD	HL,(parsep)	;get current position
skps1:	LD	(parsep),HL	;save position
	LD	(errorp),HL	;save position for error message
	LD	A,(HL)
	OR	A		;return if end of command
	ret	z	
	CP	' '
	jp	z,skps2
	CP	TAB		;skip spaces & tabs
	ret	nz	
skps2:	INC	HL		;advance past space/tab
	JP	skps1		;loop
;
;-----------------------------------------------------------------------
;
;	MULTIPLE COMMANDS PER LINE HANDLER
;
;-----------------------------------------------------------------------
	if	multi
multistart:	
	;
	;	A  = current character in command line
	;	HL = address of current character in command line
	;
	;double exclaimation points become one
	LD	E,L
	LD	D,H
	INC	DE
	LD	A,(DE)
	CP	'!'		;double exclaimation points
	PUSH	AF
	PUSH	HL
	call	z,copy0		;convert to one, if so
	POP	HL
	POP	AF
	ret	z	
	;we have a valid multiple command line
	LD	(HL),0		;terminate command line here
	EX	DE,HL
	;multiple commands not allowed in submits
	;NOTE: submit unravels multiple commands making the
	;following test unnecessary.  However, with GET[system]
	;or CP/M 2.2 SUBMIT multiple commands will be posponed 
	;until the entire submit completes...  
;	call	subtest		;submit active
;	mvi	a,0		
;	rnz			;return with A=0, if so
	;set up the RSX buffer
	LD	HL,(osbase)	;get high byte of TPA address
	DEC	H		;subtract 1 page for buffer
	LD	L,endchain	;HL = RSX buffer base-1
	LD	(HL),A		;set end of chain flag to 0
	PUSH	HL		;save it 
multi0:	INC	HL
	INC	DE
	LD	A,(DE)		;get character from cbuf
	LD	(HL),A		;place in RSX
	CP	'!'
	jp	nz,multi1
	LD	(HL),CR		;change exclaimation point to cr
multi1:	OR	A
	jp	nz,multi0
	LD	(HL),CR		;end last command with cr
	INC	HL
	LD	(HL),A		;terminate with a zero
	;set up RSX prefix
	LD	L,6		;entry point
	LD	(HL),jmp_op	;put a jump instruction there
	INC	HL
	LD	(HL),9		;make it a jump to base+9 (RSX exit)
	INC	HL
	LD	(HL),H	
	INC	HL		;HL = RSX exit point
	LD	(HL),jmp_op	;put a jump instruction there
	LD	L,warmflg	;HL = remove on warm start flag
	LD	(HL),A		;set (0) for RSX to remain resident
	LD	L,A		;set low byte to 0 for fixchain
	EX	DE,HL		;DE = RSX base
	CALL	fixchain	;add the RSX to the chain
	;save buffer address
	LD	HL,(scbaddr)
	LD	L,ccpconbuf	;save buffer address in CCP conbuf field
	POP	DE		;DE = RSX base
	INC	DE
	LD	(HL),E
	INC	HL
	LD	(HL),D
	LD	L,multi$rsx$pg
	LD	(HL),D		;save the RSX base
	XOR	A		;zero in a to fall out of uc
	RET	
	;
	;
	;	save the BDOS conbuffer address and
	;	terminate RSX if necessary.
	;
multisave:	
	LD	DE,conbuffer*256+ccpconbuf
	CALL	wordmov		;first copy conbuffer in case SUBMIT 
	OR	A		;and/or GET are active
	LD	DE,conbuffl*256+ccpconbuf
	call	z,wordmov		;if conbuff is zero then conbufl has the 
	PUSH	HL		;next address
	CALL	break1
	POP	HL		;H = SCB page
	LD	L,ccpconbuf
	jp	nz,multiend
	LD	E,(HL)
	INC	HL
	LD	D,(HL)		;DE = next conbuffer address
	INC	(HL)
	DEC	(HL)		;is high byte zero? 
	DEC	HL		;HL = .ccpconbuf
	jp	z,multiend	;remove multicmd RSX if so
	LD	A,(DE)		;check for terminating zero
	OR	A
	ret	nz		;return if not
	;
	;	we have exhausted all the commands
multiend:	
	;	HL = .ccpconbuf
	XOR	A
	LD	(HL),A		;set buffer to zero
	INC	HL
	LD	(HL),A
	LD	L,multi$rsx$pg
	LD	H,(HL)
	LD	L,0eh		;HL=RSX remove on warmstart flag
	DEC	(HL)		;set to true for removal
	JP	rsx$chain	;remove the multicmd rsx buffer
	endif			;multi
;;
;************************************************************************
;
;	FILE NAME PARSER
;
;************************************************************************
;
;
;
;	get file name (read in if none present)
;
;
;;	The file-name parser in this CCP implements
;;	a user/drive specification as an extension of the normal
;;	CP/M drive selection feature.  The syntax of the
;;	user/drive specification is given below.  Note that a
;;	colon must follow the user/drive specification.
;;
;;	<a>:	<a> is an alphabetic character A-P specifing one
;;		of the CP/M disk drives.
;;
;;	<n>:	<n> is a decimal number 0-15 specifying one of the
;;		user areas.
;;
;;	<n><a>:	A specification of both user area and drive.
;;
;;	<a><n>:	Synonymous with above.
;;
;;	Note that the user specification cannot be included
;;	in the parameters of transient programs or precede a file
;;	name.  The above syntax is parsed by gcmd (get command).
;;
;; ************************************************************
getfn:	
	if	prompts
	LD	DE,fnmsg
getfn0:	
	CALL	getprm
	endif			;prompts
gfn:	LD	DE,dcfcb
gfn0:	CALL	skps		;sets zero flag if eol
	PUSH	AF
	CALL	gfn2
	POP	AF
	RET	
	;
	;	BDOS FUNCTION 152 INTERFACE
	;
	;entry:	DE = .FCB
	;	HL = .buffer
	;flags/A reg preserved
	;exit:  DE = .FCB
	;
	;
gfn2:	LD	(parsep),HL
	LD	(errorp),HL
	PUSH	DE		;save .cfcb
	LD	DE,pfncb
	LD	C,parsef
if	func152
	CALL	bdos
ELSE	;func152
	CALL	parse
endif	;func152
	POP	DE		;.cfcb
	LD	A,H
	OR	L		;end of command? (HL = 0)
	LD	B,(HL)		;get delimiter
	INC	HL		;move past delimiter
	jp	nz,gfn3
	LD	HL,zero+2	;set HL = .0
gfn3:	LD	A,H
	OR	L		;parse error? (HL = 0ffffh)
	jp	nz,gfn4
	LD	HL,zero+2
	CALL	perror		
gfn4:	LD	A,B
	CP	'.'
	jp	nz,gfn6
	DEC	HL
gfn6:	LD	(parsep),HL	;update parse pointer
gfnpwd:	LD	C,16
	LD	HL,pcfcb
	PUSH	DE
	CALL	move
	LD	DE,passwd	;HL = .disk map in pcfcb
	LD	C,10
	CALL	move		;copy to passwd
	POP	DE		;HL = .password len
	LD	A,(HL)
zero:	LD	HL,0		;must be an "lxi h,0"
	OR	A		;is there a password?
	LD	B,A
	jp	z,gfn8
	LD	HL,(errorp)	;HL = .filename
gfn7:	LD	A,(HL)
	CP	';'
	INC	HL
	jp	nz,gfn7
gfn8:	RET			;B = len, HL = .password
;
;	PARSE CP/M 3 COMMAND
;	entry:	DE  = .UFCB  (user no. byte in front of FCB)
;		PARSEP = .command line
gcmd:	
	PUSH	DE
	XOR	A
	LD	(DE),A		;clear user byte
	INC	DE
	LD	(DE),A		;clear drive byte
	INC	DE
	CALL	skps		;skip leading spaces
;
;	Begin by looking for user/drive-spec.  If none if found,
;	fall through to main file-name parsing section.  If one is found
;	then branch to the section that handles them.  If an error occurs
;	in the user/drive spec; treat it as a filename for compatibility
;	with CP/M 2.2.  (e.g. STAT VAL: etc.)
;
	LD	HL,(parsep)	;get pointer to current parser position
	POP	DE
	PUSH	DE		;DE = .UFCB
	LD	B,4		;maximum length of user/drive spec
gcmd1:	LD	A,(HL)		;get byte
	CP	':'		;end of user/drive-spec?
	jp	z,gcmd2		;parse user/drive if so
	OR	A		;end of command?
	jp	z,gcmd8		;parse filename (Func 152), if so 
	CP	9		;[JCE] Patch 12, bug in "P B:" type commands
	jp	z,gcmd8		;[JCE]
	CP	' '		;[JCE]
	jp	z,gcmd8		;[JCE]
	DEC	B		;maximum user/drive spec length exceeded?
	INC	HL
	jp	nz,gcmd1		;loop if not
	;
	;	Parse filename, type and password
	;
gcmd8:	
	POP	DE
	XOR	A
	LD	(DE),A		;set user = default
	LD	HL,(parsep)
gcmd9:	INC	DE		;past user number byte
	LD	A,(DE)		;A=drive
	PUSH	AF
	CALL	gfn2		;BDOS function 152 interface
	POP	AF
	LD	(DE),A
	RET	
	;
	;	Parse the user/drive-spec
	;
gcmd2:	
	LD	HL,(parsep)	;get pointer to beginning of spec
	LD	A,(HL)		;get character
gcmd3:	CP	'0'		;check for user number
	jp	c,gcmd4		;jump if not numeric
	CP	'9'+1
	jp	nc,gcmd4
	CALL	gdns		;get the user # (returned in B)
	POP	DE
	PUSH	DE
	LD	A,(DE)		;see if we already have a user #
	OR	A
	jp	nz,gcmd8		;skip if we do
	LD	A,B		;A = specified user number 
	INC	A		;save it as the user-spec
	LD	(DE),A
	JP	gcmd5
gcmd4:	CP	'A'		;check for drive-spec
	jp	c,gcmd8		;skip if not a valid drive character
	CP	'P'+1
	jp	nc,gcmd8
	POP	DE
	PUSH	DE
	INC	DE
	LD	A,(DE)		;see if we already have a drive
	OR	A
	jp	nz,gcmd8		;skip if so
	LD	A,(HL)
	SUB	A,'@'		;convert to a drive-spec
	LD	(DE),A
	INC	HL
gcmd5:	LD	A,(HL)		;get next character
	CP	':'		;end of user/drive-spec?
	jp	nz,gcmd3		;loop if not
	INC	HL
	POP	DE		;.ucfcb
	JP	gcmd9		;parse the file name
;
;************************************************************************
;
;		TEMPORARY PARSE CODE
;
;************************************************************************
;
if .not. func152
;	version 3.0b  Oct 08 1982 - Doug Huskey
;
;
passwords:	equ	on ;true
parse:	; DE->.(.filename,.cfcb)
	;
	; filename = [d:]file[.type][;password]
	;             
	; cfcb assignments
	;
	;   0     => drive, 0 = default, 1 = A, 2 = B, ...
	;   1-8   => file, converted to upper case,
	;            padded with blanks (left justified)
	;   9-11  => type, converted to upper case,
	;	     padded with blanks (left justified)
	;   12-15 => set to zero
	;   16-23 => password, converted to upper case,
	;	     padded with blanks
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
	EX	DE,HL
	LD	E,(HL)		;get first parameter
	INC	HL
	LD	D,(HL)
	PUSH	DE		;save .filename
	INC	HL
	LD	E,(HL)		;get second parameter
	INC	HL
	LD	D,(HL)
	POP	HL		;DE=.cfcb  HL=.filename
	EX	DE,HL
parse0:	
	PUSH	HL		;save .cfcb
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
	CALL	pad
	CALL	skip
;
;	check for drive
;
	LD	A,(DE)
	CP	':'		;is this a drive?
	DEC	DE
	POP	HL
	PUSH	HL		;HL = .cfcb
	jp	nz,parse$name
;
;	Parse the drive-spec
;
parsedrv:	
	LD	A,(DE)		;get character
	AND	5fh		;convert to upper case
	SUB	A,'A'
	jp	c,perr1
	CP	16
	jp	nc,perr1
	INC	DE
	INC	DE		;past the ':'
	INC	A		;set drive relative to 1
	LD	(HL),A		;store the drive in FCB(0)
;
;	Parse the file-name
;
parse$name:	
	INC	HL		;HL = .cfcb(1)
	CALL	delim
	jp	z,parse$ok
if	passwords
	LD	BC,0700H	;7*256
ELSE	;passwords
	LD	B,7
endif	;passwords
parse6:	LD	A,(DE)		;get a character
	CP	'.'		;file-type next?
	jp	z,parse$type	;branch to file-type processing
	CP	';'
	jp	z,parsepw
	CALL	gfc		;process one character
	jp	nz,parse6		;loop if not end of name
	JP	parse$ok
;
;	Parse the file-type
;
parse$type:	
	INC	DE		;advance past dot
	POP	HL
	PUSH	HL		;HL =.cfcb
	LD	BC,9
	ADD	HL,BC		;HL =.cfcb(9)
if	passwords
	LD	BC,2*256
ELSE	;passwords
	LD	B,2
endif	;passwords
parse8:	LD	A,(DE)
	CP	';'
	jp	z,parsepw
	CALL	gfc		;process one character
	jp	nz,parse8		;loop if not end of type
;
parse$ok:	
	POP	BC
	PUSH	DE
	CALL	skip
	CALL	delim
	POP	HL
	rnz	
	LD	HL,0
	OR	A
	ret	z	
	CP	CR
	ret	z	
	EX	DE,HL
	RET	
;
;	handle parser error
;
perr:	
	POP	BC		;throw away return addr
perr1:	
	POP	BC
	LD	HL,0ffffh
	RET	
;
if	passwords
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
ELSE	
;
;	skip over password
;
parsepw:	
	INC	DE
	CALL	delim
	jp	nz,parsepw
	JP	parse$ok
endif	;passwords
;
;	get next character of name, type or password
;
gfc:	CALL	delim		;check for end of filename
	ret	z		;return if so
	CP	' '		;check for control characters
	INC	DE
	jp	c,perr		;error if control characters encountered
	INC	B		;error if too big for field
	DEC	B
	jp	m,perr
if	passwords
	INC	C
	DEC	C
	jp	nz,gfc1
endif	
	CP	'*'		;trap "match rest of field" character
	jp	z,setwild
gfc1:	LD	(HL),A		;put character in cfcb
	INC	HL
	DEC	B		;decrement field size counter
	OR	A		;clear zero flag
	RET	
;;
setwild:	
	LD	(HL),'?'	;set match one character
	INC	HL
	DEC	B
	jp	setwild
	RET	
;
;	skip spaces
;
skip0:	INC	DE
skip:	LD	A,(DE)
	CP	' '		;skip spaces & tabs
	jp	z,skip0
	CP	TAB
	jp	z,skip0
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
	;	not a delimiter, convert to upper case
	;
	CP	'a'
	ret	c	
	CP	'z'+1
	jp	nc,delim3
	AND	05fh
delim3:	AND	07fh	
	RET			;return with zero set if so
;
;	pad with blanks
;
pad:	LD	(HL),B
	INC	HL
	DEC	C
	jp	nz,pad
	RET	
;
endif	
;
;
;************************************************************************
;
;	SUBROUTINES 
;
;************************************************************************
;
IF multi
;
;	copy SCB memory word
;	d = souret	ce offset e = destination offset
;
wordmov:	
	LD	HL,(scbaddr)
	LD	L,D
	LD	D,H
	LD	C,2
;
ENDIF			;multi
;
;	copy memory bytes 
;	de = destination  hl = souret	ce  c = count
;
move:	
	LD	A,(HL) 
	LD	(DE),A		;move byte to destination
	INC	HL 
	INC	DE		;advance pointers
	DEC	C		;loop if non-zero
	jp	nz,move
	RET	
;
;	copy memory bytes with terminating zero
;	hl = destination  de = souret	ce  
;	returns c=length
copy0:	LD	C,0
copy1:	LD	A,(DE)
	LD	(HL),A
	OR	A
	LD	A,C
	ret	z	
	INC	HL
	INC	DE
	INC	BC
	JP	copy1
;;
;;-----------------------------------------------------------------------
;;
;;	get byte from file
;;
;;	exit:	z  = set if byte gotten
;;		a  = byte read
;;		z  = clear if error or eof
;;		a  = return value of bdos read call
;;
getb:	XOR	A		;clear accumulator
	LD	HL,bufp		;advance buffer pointer
	INC	(HL)
	call	m,read		;read sector if buffer empty
	OR	A
	ret	nz		;return if read error or eof
	LD	A,(bufp)	;compute pointer into buffer
	LD	HL,buf
	CALL	addhla
	XOR	A		;set zero flag
	LD	A,(HL)		;get byte
	RET	
;;
;;-----------------------------------------------------------------------
;;
;;
;;	system control block flag routines
;;
;;	entry:	c  = bit mask (1 bit on)
;;		b  = scb byte offset
;;
subtest:	
	LD	BC,submit
getflg:	
;	return flag value
;	exit:	zero flag set if flag reset
;		c  = bit mask
;		hl = flag byte address
;
	LD	HL,(scbaddr) 
	LD	L,B
	LD	A,(HL)
	AND	C		; a = bit
	RET	
;
setccpflg:	
	LD	BC,ccp10
;
setflg:	
;	set flag on (bit = 1)
;
	CALL	getflg
	LD	A,C
	OR	(HL)
	LD	(HL),A
	RET	
;
resetccpflg:	
	LD	BC,ccp10
;
resetflg:	
;	reset flag off (bit = 0)
;
	CALL	getflg
	LD	A,C
	CPL	
	AND	(HL) 
	LD	(HL),A
	RET	
;;
;;
;;	SET/GET SCB BYTE
;;
;;	entry:	 A  = byte ("setbyte" only)
;;		 B  = SCB byte offset from page
;;
;;	exit:	 A  = byte ("getbyte" only)
;;
setbyte:	
	LD	HL,(scbaddr) 
	LD	L,B 
	LD	(HL),A
	RET	
;
getbyte:	
	LD	HL,(scbaddr) 
	LD	L,B 
	LD	A,(HL)
	RET	
;
;;-----------------------------------------------------------------------
;;
;;
;;	PRINT message followed by newline
;;
;;	entry:	de -> message string
;;
pmsgnl:	CALL	pmsg
;
;	PRINT CRLF
;
dirln:	LD	B,L		;number of columns for DIR
ccp_crlf:
	LD	A,CR
	CALL	pfc
	LD	A,LF
	JP	pfc
;;
;;-----------------------------------------------------------------------
;;
;;	PRINT decimal byte
;;
pdb:	SUB	A,10
	jp	c,pdb2
	LD	E,'0'
pdb1:	INC	E
	SUB	A,10
	jp	nc,pdb1
	PUSH	AF
	CALL	putc2
	POP	AF
pdb2:	ADD	A,10+'0'
	JP	putc
;;-----------------------------------------------------------------------
;;
;;
;;	PRINT string terminated by 0 or char in c
;;
pstrg:	LD	A,(HL)		;get character
	OR	A
	ret	z	
	CP	C
	ret	z	
	CALL	pfc		;PRINT character
	INC	HL		;advance pointer
	JP	pstrg		;loop
;;
;;-----------------------------------------------------------------------
;;
;;	check for end of command (error if extraneous parameters)
;;
eoc:	CALL	skps
	ret	z	
;
;	handle parser error
;
perror:	
	LD	HL,errflg
	LD	A,(HL)
	OR	A		;ignore error????
	LD	(HL),0		;clear error flag
	ret	nz		;yes...just return to CCPRET
	LD	HL,(errorp)	;get pointer to what we're parsing
	LD	C,' '
	CALL	pstrg
perr2:	LD	A,'?'		;PRINT question mark
	CALL	putc
	JP	ccpcr
;
;;-----------------------------------------------------------------------
;;
;;
;;	PRINT error message and exit processor
;;
;;	entry:	bc -> error message
;;
;;msgerr:	push	b
;;	call	ccp_crlf
;;	pop	d
;;	jmp	pmsgnl
;;
;;-----------------------------------------------------------------------
;;
;;	get decimal number (0 <= N <= 255)
;;
;;	exit:	a  = number
;;
gdn:	CALL	skps		;skip initial spaces
	LD	HL,(parsep)	;get pointer to current character
	LD	(errorp),HL	;save in case of parsing error
	ret	z			;return if end of command
	LD	A,(HL)		;get it
	CP	'0'		;error if non-numeric
	jp	c,perror
	CP	'9'+1
	jp	nc,perror
	CALL	gdns		;convert number
	LD	(parsep),HL	;save new position
	OR	1		;clear zero and carry flags
	LD	A,B
	RET	
;
gdns:	LD	B,0
gdns1:	LD	A,(HL)
	SUB	A,'0'
	ret	c	
	CP	10
	ret	nc	
	PUSH	AF
	LD	A,B		;multiply current accumulator by 10
	ADD	A,A
	ADD	A,A
	ADD	A,B
	ADD	A,A
	LD	B,A
	POP	AF
	INC	HL		;advance to next character
	ADD	A,B		;add it in to the current accumulation
	LD	B,A
	CP	16
	jp	c,gdns1		;loop unless >=16
	JP	perror		;error if invalid user number
;;
;;-----------------------------------------------------------------------
;;
;;	PRINT file name
;;
	if	newdir
pfn:	INC	DE		;point to file name
	LD	H,8		;set # characters to PRINT, clear # printed
	CALL	pfn1		;PRINT name field
	CALL	space
	LD	H,3		;set # characters to PRINT
pfn1:	LD	A,(DE)		;get character
	AND	7fh
	CALL	pfc		;PRINT it if not
	INC	DE		;advance pointer
	DEC	H		;loop if more to PRINT
	jp	nz,pfn1
	RET	
;
space:	LD	A,' '
;
pfc:	PUSH	BC
	PUSH	DE
	PUSH	HL
	CALL	putc
	POP	HL
	POP	DE
	POP	BC
	RET	
	
	else	
pfn:	INC	DE		;point to file name
	LD	BC,8*256	;set # characters to PRINT, clear # printed
	CALL	pfn1		;PRINT name field
	LD	A,(DE)		;see if there's a type
	AND	7fh
	CP	' '
	ret	z			;return if not
	LD	A,'.'		;PRINT dot
	CALL	pfc
	LD	B,3		;set # characters to PRINT
pfn1:	LD	A,(DE)		;get character
	AND	7fh
	CP	' '		;is it a space?
	call	nz,pfc		;PRINT it if not
	INC	DE		;advance pointer
	DEC	B		;loop if more to PRINT
	jp	nz,pfn1
	RET	
;
space:	LD	A,' '
;
pfc:	INC	C		;increment # characters printed
	PUSH	BC
	PUSH	DE
	CALL	putc
	POP	DE
	POP	BC
	RET	
	endif	
;;
;;-----------------------------------------------------------------------
;;
;;	add a to hl
;;
addhla:	ADD	A,L
	LD	L,A
	ret	nc	
	INC	H
	RET	
;;
;;-----------------------------------------------------------------------
;;
;;	set match-any string into cfcb
;;
;;	entry:	de -> cfcb area
;;		b  = # bytes to set
;;
setmatch:	
	LD	A,'?'		;set match one character
setm1:	LD	(DE),A		;fill rest of field with match one
	INC	DE
	DEC	B		;loop if more to fill
	jp	nz,setm1
	OR	A
	RET	
;;
;;-----------------------------------------------------------------------
;;
;;	table search
;;
;;	Searet	ch table of strings separated by spaces and terminated 
;;	by 0.  Accept abbreviations, but set string = matched string
;;	on exit so that we don't try to execute abbreviation.
;;
;;	entry:	de -> string to search for
;;		hl -> table of strings to match (terminate table with 0)
;;	exit:	z  = set if match found
;;		a  = entry # (0 thru n-1)
;;		z  = not set if no match found
;;
tbls:	LD	BC,0ffh		;clear entry & entry length counters
tbls0:	PUSH	DE		;save match string addr
	PUSH	HL		;save table string addr
tbls1:	LD	A,(DE)		;compare bytes
	AND	7fh		;kill upper bit (so SYS + R/O match)
	CP	' '+1		;end of search string?
	jp	c,tbls2		;skip compare, if so
	CP	(HL)
	jp	nz,tbls3	;jump if no match
tbls2:	INC	DE		;advance string pointer
	INC	C		;increment entry length counter
	LD	A,' '
	CP	(HL)
	INC	HL		;advance table pointer
	jp	nz,tbls1	;continue with this entry if more
	POP	HL		;HL = matched string in table
	POP	DE		;DE = string address
	CALL	move		; C = length of string in table
	LD	A,B		;return current entry counter value
	RET	
;
tbls3:	LD	A,' '		;advance hl past current string
tbls4:	CP	(HL)
	INC	HL
	jp	nz,tbls4
	POP	DE		;throw away last table address
	POP	DE		;DE = string address
	INC	B		;increment entry counter
	LD	C,0ffh
	LD	A,(HL)		;check for end of table
	SUB	A,1
	jp	nc,tbls0	;loop if more entries to test
	RET	
;
;************************************************************************
;************************************************************************
;
;************************************************************************
;
;	DATA AREA
;
;************************************************************************
;	;Note uninitialized data placed at the end (DS)
;
;
IF	prompts
enter:	DB	'Enter $'
unmsg:	DB	'User #: $'
fnmsg:	DB	'File: $'
	else	
unmsg:	DB	'Enter User #: $'
	endif	
nomsg:	DB	'No File$'
required:	
	DB	' required$'
eramsg:	
	DB	'ERASE $'
confirm:	
	DB	' (Y/N)? $'
more:	DB	CR,LF,CR,LF,'Press RETURN to Continue $'
	if	dayfile
userzero:	DB	'  (User 0)$'
ENDIF	
;
;
;
IF	newdir
anyfiles:	DB	0	;flag for SYS or DIR files exist
dirfiles:	DB	'NON-'
sysfiles:	DB	'SYSTEM FILE(S) EXIST$'
ENDIF	
errflg:	DB	0		;parse error flag
IF	multi
multibufl:	
	DW	0		;multiple commands buffer length
ENDIF	
scbadd:	DB	scbad-pag$off,0
	;********** CAUTION FOLLOWING DATA MUST BE IN THIS ORDER *********
pfncb:	;BDOS func 152 (parse filename)
parsep:	DW	0		;pointer to current position in command
pfncfcb:	DW	pcfcb		;.cfcb for func 152
usernum:	;CCP current user
	DB	0
chaindsk:	
	DB	0		;transient's current disk
disk:	DB	0		;CCP current disk
subcfcb:	DB	1,'$$$     SUB',0
ccpend:	;end of file (on disk)
	DS	1
submod:	DS	1
subrc:	DS	1
	DS	16
subcr:	DS	1
subrr:	DS	2
subrr2:	DS	1
dircols:	DS	1		;number of columns for DIR/DIRS
pgsize:	DS	1		;console page size
line:	DS	1		;console line #
pgmode:	DS	1		;console page mode
	;*****************************************************************
errorp:	DS	2		;pointer to beginning of current param.
errsav:	DS	2		;pointer to built-in command tail
bufp:	DS	1		;buffer pointer for getb
realdos:	
	DS	1		;base page of BDOS
;
option:	DS	1		;'[' in line?
passwd:	DS	10		;password
ucfcb:	DS	1		;user number (must procede cfcb)
cfcb:	
	DS	1		; drive code
	DS	8		; file name
	DS	3		; file type
	DS	4		; control INFO
	DS	16		; disk map
cfcbcr:	DS	1		; current record
cfcbrr:	DS	2		; random record
pcfcb:	DS	36		; cfcb for parsing
;
;
;
;
; 	command line buffer
;
cbufmx:	DS	1
cbufl:	DS	1
cbuf:	DS	comlen
	DS	50h
stack:	
ccptop:	;top page of CCP
	end	
