;*************************************************************************
;*                                                                       *
;* $Id: eZ80-CPM-BIOS.asm 848 2006-09-21 06:39:33Z Hharte $              *
;*                                                                       *
;* Copyright (c) 1979 Digital Research, Inc.                             *
;*                                                                       *
;* THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY *
;* KIND, EITHER EXPRESSED OR  IMPLIED, INCLUDING BUT NOT  LIMITED TO THE *
;* IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR *
;* PURPOSE.                                                              *
;*                                                                       *
;* Module Description:                                                   *
;*     CP/M 2.2 BIOS                                                     *
;* Slightly modified by Howard M. Harte for use with the ZDS-II tools.   *
;* Modifications were primarily to be able to use this module with the   *
;* ZDS-II debugger, to allow single-stepping through the code.           *
;*                                                                       *
;* Environment:                                                          *
;*     Assemble/Link with Zilog ZDS-II v4.11.1 for the eZ80.             *
;*                                                                       *
;*************************************************************************/

		INCLUDE	"eZ80-CPM-MDEF.inc"			; CP/M memory defines.

EXTERN	__CS1_LBR_INIT_PARAM
EXTERN 	FLASHDSK
EXTERN	CCP_LEN

EXTERN	b_UART0Init

EXTERN	b_UART0GetByte
EXTERN	b_UART0PutByte
EXTERN	b_UART0Status

EXTERN 	b_MMCInit
EXTERN	b_MMCWriteSec
EXTERN	b_MMCReadSec
EXTERN	b_SL32

EXTERN 	b_TXdskStats
EXTERN	b_TXstringDE
EXTERN	b_mmcadrh
EXTERN	b_mmcadrl

PUBLIC 	SEKTRK
PUBLIC	SEKSEC
PUBLIC	UNASEC

;PUBLIC	b_conout
PUBLIC	READOP
PUBLIC	_adrv
PUBLIC	_trk
PUBLIC	_sect
PUBLIC	_dma

PUBLIC	HSTBUF

PUBLIC ?boot
PUBLIC wboot
PUBLIC const
PUBLIC conin
PUBLIC ?cono
PUBLIC listd
PUBLIC punch
PUBLIC reader
PUBLIC home
PUBLIC seldsk
PUBLIC settrk
PUBLIC setsec
PUBLIC setdma
PUBLIC read
PUBLIC write
PUBLIC listst
PUBLIC sectrn

PUBLIC b_dpbase

; BIOS - Basic I/O System.

	LIST

	DEFINE BIOS, SPACE = RAM
	SEGMENT BIOS

	.ASSUME ADL = 0

; BIOS jump table.

?boot:		jp	b_boot					;  0 Initialize.
wboot:		jp	b_wboot					;  1 Warm boot.
const:		jp	b_const					;  2 Console status.
conin:		jp	b_conin					;  3 Console input.
?cono:		jp	b_conout				;  4 Console output.
listd:		jp	b_list					;  5 List output.
punch:		jp	b_punch					;  6 Punch output.
reader:		jp	b_reader				;  7 Reader input.
home:		jp	b_home					;  8 Home disk.
seldsk:		jp	b_seldsk				;  9 Select disk.
settrk:		jp	b_settrk				; 10 Select track.
setsec:		jp	b_setsec				; 11 Select sector.
setdma:		jp	b_setdma				; 12 Set DMA address.
read:		jp	b_read					; 13 Read 128 bytes.
write:		jp	b_write					; 14 Write 128 bytes.
listst:		jp	b_listst				; 15 List status.
sectrn:		jp	b_sectrn				; 16 Sector translate.

; BIOS subroutines start here.

; BOOT Routine.

; The  BOOT  entry  point  gets  control  from  the cold  start  loader  and  is  responsible  for  basic system
; initialization, including sending a sign-on message, which can be omitted in the first version. If the  IOBYTE
; function is implemented, it must be set at this point. The various system parameters that are set by the WBOOT
; entry point must be  initialized, and control is  transferred to the CCP at 0x3400 + b for further processing.
; Note that register C must be set to zero to select drive A.

rlccp:
	ld.lil	hl, CCP_LOC + 010000h
	ld.lil	de, CCP_LOC
	ld.lil  bc, CCP_LEN
	ldir.lil                       	; Reload the CCP
	ld.lil	hl,0
	jp.sis	doneccp

b_boot:
	di
	ld	sp,b_biosstack		; Set default stack.

	call	b_UART0Init		; Initialise the UART.

	ld	c,09h			; BDOS Function 9, print string.
	ld	de,b_bootmsg		; Address of sign on message text.
	call	bdos			; Display CP/M sign on message.

; Initialize CP/M I/O & drive byte.
b_boot2:
	xor	a			; Set to drive A.
	ld	(iobyte),a		; Clear I/O byte.
	ld	(usrdrv),a		; Save new drive number (0).
	ld	(MMCINITDONE),a		; MMC Disk initialization not done yet.


; WBOOT Routine.

; The WBOOT entry point gets control when a warm start occurs. A warm start is performed whenever a user program
; branches to  location 0x0000, or when the CPU is reset  from the front panel.  The CP/M system  must be loaded
; from the first two tracks of drive A  up to, but not including, the BIOS,  or CBIOS, if the user has completed
; the patch. System parameters must be initialized as follows:

; Location 0,1,2
;	Set to JP WBOOT for warm starts (0x0000: jp 0x4a03 + b).
; Location 3
;	Set initial value of IOBYTE, if implemented in the CBIOS.
; Location 4
;	High nibble = current user number, low nibble = current drive.
; Location 5,6,7
;	Set to JP BDOS, which is the primary entry point to CP/M for transient programs (0x0005: jp 0x3c06 + b).

; Refer to  Section 6.9  of the  CP/M® Operating  System Manual  for complete  details of   page zero  use. Upon
; completion of  the initialization,   the WBOOT  program must  branch to  the CCP  at 0x3400 + b to restart the
; system. Upon entry  to the CCP,  register C is  set to the  drive to select  after  system initialization. The
; WBOOT routine  should read  location 4 in  memory,  verify that is a  legal drive, and pass  it to the CCP  in
; register C.

b_wboot:
	di				; Disable interrupts.
	ld	sp,b_biosstack		; Set default stack.

;	ld	c,09h			; BDOS Function 9, print string.
;	ld	de,b_ccpmsg		; Address of sign on message text.
;	call	bdos			; Display CP/M sign on message.

	jp.lil	rlccp

doneccp:
	xor	a
	ld	(HSTACT),a
	ld	(UNACNT),a

	ld	a,0C3h			; Opcode for 'jp'.
	ld	(ramstart),a		; Address 0000h.
	ld	(bdosen),a		; Address 0005h.

	ld	hl,wboot		; Address vector for a warm boot.
	ld	(ramstart + 01h),hl	; Address 0001h.
	ld	hl,bdos			; Address vector for the BDOS entry.
	ld	(bdosen + 01h),hl	; Address 0006h.

	ld	bc,tpabuf		; Set default 128 byte disk buffer.
	call	b_setdma		; And use BIOS routine to do it.

	ld	a,(usrdrv)		; Get current logged drive.
	cp	b_maxdrvs		; Must be between A (0) and b_maxdrvs.
	jr	c,b_wboot1		; Carry if <= b_maxdrvs, so it's legal.
	xor	a			; Illegal drive so reset to drive A (0).
	ld	(usrdrv),a		; Save new drive number.
b_wboot1:
	push	af
	xor	a
	ld	(MMCINITDONE),a
	pop	af
;	cp	a,0
;	call	nz,	b_MMCInit	; Initialise MMC FLASH Memory Card.
;	pop	af
	ld	c,a			; Pass drive number in C.

	jp	ccp			; And start CP/M by jumping to the CCP.

; CONST Routine.

; You should sample  the status of  the currently assigned  console device and  return 0xff in  register A if  a
; character is ready to read and 0x00 in register A if no console characters are ready.

b_const:
	call	b_UART0Status		; Read UART status register of COM Port 1.
	bit	0,a			; Test character ready bit.
	jr	z,b_cs1			; If Z=1 then character not available.
	ld	a,0FFh			; Set character is available flag.
	ret				; Done.
b_cs1:	xor	a			; Set character not available flag.
	ret				; Done.

; CONIN Routine.

; The next console character is read into register A, and the parity bit (bit 7) is set to zero.  If no  console
; character is ready, wait until a character is typed before returning.

b_conin:
	call	b_UART0Status		; Read UART status register of COM Port 1.
	bit	0,a			; Test character ready bit and loop
	jr	z,b_conin		; until a character is available.
	call	b_UART0GetByte		; Get character from receive buffer
	and	7Fh			; Strip the high bit (CP/M rules).
	ret				; Done.

; CONOUT Routine.

; The character is sent from register C to the console output device. The character is in ASCII, with high-order
; parity bit set to zero. You might want to include a time-out on a line-feed or carriage return, if the console
; device requires some time interval at the end of the  line (such as a TI Silent 700 terminal). You can  filter
; out control  characters that  cause the  console device  to react  in a  strange way  (CTRL-Z causes  the Lear
; - Siegler terminal to clear the screen, for example).

b_conout:
	push	af
b_co1:	call	b_UART0Status		; Read UART status register of COM port 1.
	bit	5,a			; Test TX Data Register Empty ready bit and
	jr	z,b_co1			; loop until TX buffer is empty.
	ld	a,c
	and	07FH
	call	b_UART0PutByte		; TX the character.
	pop	af
	ret				; Done.

; LIST Routine.

; The character is sent from register C to the currently assigned listing device. The character is in ASCII with
; zero parity bit.

b_list:
	ret				; Done.

; PUNCH Routine.

; The character is sent from register C to the  currently assigned punch device. The character is in ASCII  with
; zero parity.

b_punch:
	ret				; Done.

; READER Routine.

; The next character is read  from the currently assigned reader  device into register A with  zero parity (high
; -order bit must be zero); an End-Of-File condition is reported by returning an ASCII CTRL-Z (0x1a).

b_reader:
	ld	a,1Ah			; No reader so just fake an EOF and return.
	ret				; Done.

; SELDSK Routine.

; The disk drive given by register C is selected  for further operations, where register C contains 0 for  drive
; A, 1  for drive  B, and  so on  up to  15 for  drive P  (the standard  CP/M distribution version supports four
; drives). On each disk  select, SELDSK must return  in HL the base  address of a 16 byte  area, called the Disk
; Parameter Header, described  in Section 6.10  of the CP/M®  Operating System Manual.  For standard floppy disk
; drives, the contents of the header and associated tables do not change; thus, the program segment included  in
; the sample CBIOS performs this operation automatically.

; If there  is an  attempt to  select a  nonexistent drive,  SELDSK  returns HL = 0x0000 as  an error indicator.
; Although SELDSK must return  the header address on  each call, it is  advisable to postpone the  physical disk
; select operation until  an I/O function  (seek, read, or  write) is actually  performed, because disk  selects
; often occur without ultimately performing any disk I/O,  and many controllers unload  the head of the  current
; disk before  selecting the  new drive.  This causes  an excessive  amount of  noise and  disk wear.  The least
; significant bit of register E is zero if this is the first occurrence of the drive select since the last  cold
; or warm start.

b_seldsk:
	ld	a,c					; Load A with disk to select.
	ld	(SEKDSK),a
	push	af
	cp	a,0
	jr	z, b_seldsk_noinit
	ld	a, (MMCINITDONE)
	cp	a,0
	call	z,b_MMCInit					; Initialise MMC FLASH Memory Card.
	ld	a,1
	ld	(MMCINITDONE),a
b_seldsk_noinit:
	pop	af
	ld	l,a					; Disk number in range so compute DPH address. L = disk number 0, 1, 2, .. 15.
	ld	h,0
	add	hl,hl					; *  2.
	add	hl,hl					; *  4.
	add	hl,hl					; *  8.
	add	hl,hl					; * 16.
	ld	de,b_dpbase				; Base address of disk parameter block.
	add	hl,de					; HL = (diskno * 16) + dpbase.
	ret						; Done.

; HOME Routine.

; The disk head  of the currently  selected disk (initially  disk A) is  moved to the  track 0 position. If  the
; controller allows access to the  track 0 flag from the  drive, the head is stepped  until the track 0 flag  is
; detected. If the controller does not support this feature,  the HOME call is translated into a call to  SETTRK
; with a parameter of 0.

b_home:		ld	bc,0000h				; Select track 0.
		call	b_settrk
		ld	a,(HSTWRT)
		or	a
		ret	nz
		ld	(HSTACT),a
		ret

; SETTRK Routine.

; Register BC contains the track number for subsequent disk accesses on the currently selected drive. The sector
; number in BC  is the same  as the number  returned from the  SECTRAN entry point.  You can choose  to seek the
; selected track at this time or  delay the seek until the next  read or write actually occurs. Register  BC can
; take on values in the range 0 - 76 corresponding to valid track numbers  for standard floppy disk drives and 0
; - 65535 for nonstandard disk subsystems.

b_settrk:	ld	(SEKTRK),bc				; Set track passed from BDOS in register BC.
		ret						; Done.

; SECSEC Routine.

; Register BC contains the sector number, 1 through  26, for subsequent disk accesses on the currently  selected
; drive. The sector number in BC is the same as the number returned from the SECTRAN entry point. You can choose
; to send this  information to the  controller at this  point or delay  sector selection until  a read or  write
; operation occurs.

b_setsec:
		ld	(SEKSEC),bc				; Set sector passed from BDOS in register BC.
		ret						; Done.

; SETDMA Routine.

; Register  BC contains  the DMA  (Disk Memory  Access) address  for subsequent  read or  write operations.  For
; example, if B = 0x00 and C = 0x80 when  SETDMA is called, all subsequent read operations read their data  into
; 0x80 through 0xff and all  subsequent write operations get their  data from 0x80 through 0xff,  until the next
; call  to SETDMA occurs.  The initial DMA address  is assumed  to be  0x0080. The controller need  not actually
; support Direct Memory Access. If,  for example, all data transfers   are through I/O ports, the  CBIOS that is
; constructed uses the 128 byte  area  starting at the selected   DMA address for the  memory  buffer during the
; subsequent read or
; write operations.

b_setdma:	ld	(DMAADR),bc				; Set DMA address given by registers BC.
		ret						; Done.

; LISTST Routine.

; You return the ready status of the list device used by the DESPOOL program to improve console response  during
; its operation. The value 0x00 is returned in A if the list device  is not ready to accept a character and 0xff
; if a character can be sent to the printer. A 0x00 value should be returned if LIST status is not implemented.

b_listst:	xor	a					; Return list status of 0x00 (not ready).
		ret						; Done.

; SECTRN Routine.

; Logical-to-physical sector translation  is performed to  improve the overall  response of CP/M.  Standard CP/M
; systems are shipped with a skew factor of 6, where six physical sectors are skipped between each logical  read
; operation. This skew factor allows enough time between sectors for most programs to load their buffers without
; missing the next sector. In particular computer systems that use fast processors, memory, and disk subsystems,
; the skew  factor might  be changed  to improve  overall response.  However, the  user should maintain a single
; -density IBM-compatible version of CP/M for information transfer into and out of the computer system, using  a
; skew factor of 6.

; In general, SECTRAN receives a logical sector number relative  to zero in BC and a translate table address  in
; DE. The sector number is used as an index into the translate table, with the resulting physical sector  number
; in HL. For standard systems, the table and indexing code is provided in the CBIOS and need not be changed.

b_sectrn:	ld	hl,bc					; Pass BC back in HL.
;		inc	hl					; Physical sectors start at 1
		ret						; Done.

; READ Routine.

; Assuming the drive has been selected, the track has been set, and the DMA address has been specified, the READ
; subroutine attempts to read one sector based upon  these parameters and returns the following error codes   in
; register A:

; 0 - no errors occurred.
; 1 - nonrecoverable error condition occurred.

; Currently, CP/M responds only to a zero or nonzero value as the return code. That is, if the value in register
; A is 0x00, CP/M assumes that the disk operation was completed properly.  If an error  occurs the CBIOS  should
; attempt at least 10 retries to see if the error is recoverable. When an error is reported the BDOS prints  the
; message BDOS ERR ON x: BAD SECTOR.  The operator then has the  option of pressing a carriage return  to ignore
; the error, or CTRL-C to abort.

b_read:		xor	a
		ld	(UNACNT),a
		ld	a,1
		ld	(READOP),a
		ld	(RSFLAG),a
		ld	a,WRUAL
		ld	(WRTYPE),a
		call	rwoper
		cp	a,0
		ret	z

		push	af
		call	b_MMCInit					; Initialise MMC FLASH Memory Card.
		pop	af
		ret

; WRITE Routine.

; Data is written from the  currently selected DMA address to  the currently selected drive, track,  and sector.
; For floppy  disks, the  data should  be marked  as non deleted data to  maintain compatibility with other CP/M
; systems. The error codes given in the READ command are returned in register A, with error recovery attempts as
; described above.

; On each call to WRITE, the BDOS provides the following information in register C:

; 0x00 Normal sector write. (Write can be deferred).
; 0x01 Write to directory sector. (Write must be immediate).
; 0x02 Write to the first sector of a new data block. (Write can be deferred, no pre-read is necessary).

; Condition 0 occurs whenever the next write operation is into a previously written area, such as a random  mode
; record update; when the write is to other than the first sector of an unallocated block; or when the write  is
; not into the directory area. Condition 1 occurs when a write into the directory area is performed. Condition 2
; occurs when the first  record (only) of a  newly allocated data block  is written. In most  cases, application
; programs read  or write  multiple 128 byte  sectors in  sequence; thus,  there is  little overhead involved in
; either operation when blocking and deblocking records, because preread operations can be avoided when  writing
; records.

b_write:	xor	a					; 0 to accumulator
		ld	(READOP),a				; Not a read operation
		ld	a,c					; Write type in c
		ld	(WRTYPE),a
		cp	WRUAL					; Write unallocated?
		jp	nz,chkuna				; Check for unalloc
;	write to unallocated, set parameters
		ld	a,BLKSIZ / 128				; Next unalloc recs
		ld	(UNACNT),a
		ld	a,(SEKDSK)				; Disk to seek
		ld	(UNADSK),a				; Unadsk = sekdsk
		ld	hl,(SEKTRK)
		ld	(UNATRK),hl				; Unatrk = sectrk
		ld	hl,(SEKSEC)
		ld	(UNASEC),hl				; Unasec = SEKSEC
;	check for write to unallocated sector
chkuna:		ld	a,(UNACNT)				; Any unalloc remain?
		or	a
		jp	z,alloc					; Skip if not
;	more unallocated records remain
		dec	a					; Unacnt = unacnt-1
		ld	(UNACNT),a
		ld	a,(SEKDSK)				; Same disk?
		ld	hl,UNADSK
		cp	(hl)					; Sekdsk = unadsk?
		jp	nz,alloc				; Skip if not
;	disks are the same
		ld	hl,UNATRK+1				; Start compare at high byte
		call	sektrkcmp				; Sektrk = unatrk?
		jp	nz,alloc				; Skip if not
;	tracks are the same
;		ld	a,(SEKSEC)				; Same sector?
;		ld	hl,UNASEC
;		cp	(hl)					; Seksec = UNASEC?

		ld	de,SEKSEC
		ld	hl,UNASEC
		call	cmp16

		jp	nz,alloc				; Skip if not
;	match, move to next sector for future ref
		inc	(hl)					; Unasec = UNASEC+1
		ld	a,(hl)					; End of track?
		cp	CPMSPT					; Count CP/M sectors
		jp	c,noovf					; Skip if no overflow
;	overflow to next track
		ld	(hl),0					; Unasec = 0
		ld	hl,(UNATRK)
		inc	hl
		ld	(UNATRK),hl				; Unatrk = unatrk+1
;	match found, mark as unnecessary read
noovf:		xor	a					; 0 to accumulator
		ld	(RSFLAG),a				; Rsflag = 0
		jp	rwoper					; To perform the write
;	not an unallocated record, requires pre-read
alloc:		xor	a					; 0 to accum
		ld	(UNACNT),a				; Unacnt = 0
		inc	a					; 1 to accum
		ld	(RSFLAG),a				; Rsflag = 1
;
;*****************************************************
;*                                                   *
;*	Common code for READ and WRITE follows       *
;*                                                   *
;*****************************************************

;	enter here to perform the read/write
rwoper:		xor	a					; Zero to accum
		ld	(ERFLAG),a				; No errors (yet)
;		ld	a,(SEKSEC)				; Compute host sector
;	rept	secshf
;		or	a					; Carry = 0
;		rra						; Shift right
;	endm
;		or	a					; Carry = 0
;		rra						; Shift right
;		or	a					; Carry = 0
;		rra						; Shift right

		ld	hl,(SEKSEC)
		srl	h					; Shift high byte
		rr	l					; Shift low byte
		srl	h					; Again
		rr	l
		ld	a,l					; new host sector to a

		ld	(SEKHST),a				; Host sector to seek
;	active host sector?
		ld	hl,HSTACT				; Host active flag
		ld	a,(hl)
		ld	(hl),1					; Always becomes 1
		or	a					; Was it already?
		jp	z,filhst				; Fill host if not
;	host buffer active, same as seek buffer?
		ld	a,(SEKDSK)
		ld	hl,_adrv				; Same disk?
		cp	(hl)					; Sekdsk = hstdsk?
		jp	nz,nomatch
;	same disk, same track?
		ld	hl,_trk+1				; Start compare at high byte
		call	sektrkcmp				; Sektrk = hsttrk?
		jp	nz,nomatch
;	same disk, same track, same buffer?
		ld	a,(SEKHST)
		ld	hl,_sect				; Sekhst = hstsec?
		cp	(hl)
		jp	z,match					; Skip if match
;	proper disk, but not correct sector
nomatch:	ld	a,(HSTWRT)				; Host written?
		or	a
		call	nz,writehst				; Clear host buff
;	may have to fill the host buffer
filhst:		ld	a,(SEKDSK)
		ld	(_adrv),a
		ld	hl,(SEKTRK)
		ld	(_trk),hl
		ld	a,(SEKHST)
		ld	(_sect),a
		ld	a,(RSFLAG)				; Need to read?
		or	a
		call	nz,readhst				; Yes, if 1
		xor	a					; 0 to accum
		ld	(HSTWRT),a				; No pending write
;	copy data to or from buffer
match:		ld	a,(SEKSEC)				; Mask buffer number
		and	SECMSK					; Least signif bits
		ld	l,a					; Ready to shift
		ld	h,0					; Double count
;	rept	7						; Shift left 7
;		add	hl,hl
;	endm
		add	hl,hl
		add	hl,hl
		add	hl,hl
		add	hl,hl
		add	hl,hl
		add	hl,hl
		add	hl,hl
;	hl has relative host buffer address
		ld	de,HSTBUF
		add	hl,de					; Hl = host address
		ex	de,hl					; Now in DE
		ld	hl,(DMAADR)				; Get/put CP/M data
		ld	c,128					; Length of move
		ld	a,(READOP)				; Which way?
		or	a
		jp	nz,rwmove				; Skip if read
;	write operation, mark and switch direction
		ld	a,1
		ld	(HSTWRT),a				; Hstwrt = 1
		ex	de,hl					; Source/dest swap
;	C initially 128, DE is source, HL is dest
rwmove:		ld	a,(de)					; Source character
		inc	de
		ld	(hl),a					; To dest
		inc	hl
		dec	c					; Loop 128 times
		jp	nz,rwmove
;	data has been moved to/from host buffer
		ld	a,(WRTYPE)				; Write type
		cp	WRDIR					; To directory?
		ld	a,(ERFLAG)				; In case of errors
		ret	nz					; No further processing
;	clear host buffer for directory write
		or	a					; Errors?
		ret	nz					; Skip if so
		xor	a					; 0 to accum
		ld	(HSTWRT),a				; Buffer written
		call	writehst
		ld	a,(ERFLAG)
		ret

;	Utility subroutine for 16-bit compare.

sektrkcmp:
        ;HL = .unatrk or .hsttrk, compare with sektrk
        ex      de,hl
        ld      hl,SEKTRK
cmp16:
        ld      a,(de)          ;high byte compare
        cp      (hl)            ;same?
        ret     nz              ;return if not
;       High bytes equal, compare low bytes
        dec     de
        dec     hl
        ld      a,(de)
        cp      (hl)            ;sets flags
        ret

;sektrkcmp:
;	or	a
;	sbc	hl,de
;	add	hl,de
;	ret


; Creates an MMC compatible 32 bit sector buffer address from the track and sector number passed from CP/M.
; On exit, HLDE contain the 32 bit number.

b_rwsetup:
	ld	de,(_sect)	; Sector # into E, Track into D
;	dec	de		; sectors start at 0, when accessing the disk.

	ld	(b_mmcadrl), de
;	Please note the above line was a bug in the original code,
;	hstsec is one byte in length it ended up with sekhst in D.
;	When I changed the order of track/sector storage it now loads
;	both the track and sector into the correct registers,
;	in other words I fixed the bug by doing nothing to the bug ;-)

	ld	hl,(_trk)				; MMCSector = (b_track * 32) + b_sector.
	add	hl,hl					; * 2
	add	hl,hl					; * 4
	add	hl,hl					; * 8
	ld	d,0
;	add	hl,hl					; * 16
;	add	hl,hl					; * 32
	add	hl,de					; Add in sector.
	ex	de,hl					; Put sector number in DE.
	ld	hl,0000h				; Zero HL for now.
	ret

; WRITEHST performs the physical write to the host disk.
; _adrv = host disk #, _trk = host track #,
; _sect = host sect #. write "HSTSIZ" bytes
; from HSTBUF and return error flag in ERFLAG.

writehst:
	ld	a, (_adrv)
	cp	a,0
	jp	z, writeflash

	call	b_rwsetup
	call	b_MMCWriteSec
	jr	b_rwfinish

; READHST performs the read from the physical disk.
; _adrv = host disk #, _trk = host track #,
; into HSTBUF and return error flag in ERFLAG.

readhst:
	ld	a, (_adrv)
	cp	a,0
	jp	z, readflash
	call	b_rwsetup
	call	b_MMCReadSec
b_rwfinish:	jr	nc,rf1					; C = 1 if an error occured.
	ld	a,1
	jr	rf2
rf1:	xor	a
rf2:	ld	(ERFLAG),a
;	jp	b_TXdskStats
	ret

readflash:
	call	b_flrwsetup
	ld.lil	bc, 0200h
	ld.lil	de, HSTBUF
	ldir.lil                       ; Copy the data section
;	call	b_TXdskStats
   	scf
	ccf
	jr	b_rwfinish		

writeflash:
	ld	de, b_flwrite
	jp	b_TXstringDE

b_flwrite:
	ASCII	"\r\nCannot write FLASH disk.$"


b_flrwsetup:
	ld	de,(_sect)	; Sector # into E, Track into D
;	dec	de		; sectors start at 0, when accessing the disk.

	ld	(b_mmcadrl), de
;	Please note the above line was a bug in the original code,
;	hstsec is one byte in length it ended up with sekhst in D.
;	When I changed the order of track/sector storage it now loads
;	both the track and sector into the correct registers,
;	in other words I fixed the bug by doing nothing to the bug ;-)

	ld	hl,(_trk)				; MMCSector = (b_track * 32) + b_sector.
	add	hl,hl					; * 2
	add	hl,hl					; * 4
	add	hl,hl					; * 8
	ld	d,0

	add	hl,de					; Add in sector.
	ex	de,hl					; Put sector number in DE.
	ld	hl,0000h				; Zero HL for now.
	call	b_SL32
	ld	a,(_trk)
	and	10h
	jr	nz, b_flupper
	ld.lil	hl,FLASHDSK
	add.lil	hl,de
	ret

b_flupper:
	ld.lil	hl,FLASHDSK + 010000h
	add.lil	hl,de
	ret


; End of required BIOS routines.

;		INCLUDE	"eZ80-CPM-MMC.asm"			; CP/M MMC routines.
;		INCLUDE	"eZ80-CPM-UART.asm"			; CP/M MMC routines.

; BIOS data and variable storage.

b_maxdrvs:	EQU	04h					; Number of drives in system.

; XLT    Address of the logical-to-physical translation vector, if used for this particular drive, or the  value
;        0x0000 if no sector translation takes place (that is, the  physical and logical sector numbers  are the
;        same). Disk drives with identical sector skew factors (skf) share the same translate tables.
; 0000   Scratch pad values for use within the BDOS, initial value is unimportant.
; 0000   Scratch pad values for use within the BDOS, initial value is unimportant.
; 0000   Scratch pad values for use within the BDOS, initial value is unimportant.
; DIRBUF Address of a 128 byte scratch pad area for directory operations within BDOS. All DPHs address the  same
;        scratch pad area.
; DPB    Address of a disk  parameter block for this drive.  Drives with identical disk characteristics  address
;        the same disk parameter block.
; CSV    Address of a scratch pad area used for software check for changed disks. This address is different  for
;        each DPH.
; ALV    Address  of a  scratch pad  area used  by the  BDOS to  keep disk  storage allocation information. This
;        address is different for each DPH.

; Disk Parameter Header for disk 0 and 1.

b_dpbase:;	EQU	$
b_dpe3:		DW	b_xlt3,0000h,0000h,0000h,b_dirbuf,b_dpb3,b_csv3,b_alv3
b_dpe2:		DW	b_xlt2,0000h,0000h,0000h,b_dirbuf,b_dpb2,b_csv2,b_alv2
b_dpe0:		DW	b_xlt0,0000h,0000h,0000h,b_dirbuf,b_dpb0,b_csv0,b_alv0
b_dpe1:		DW	b_xlt1,0000h,0000h,0000h,b_dirbuf,b_dpb1,b_csv1,b_alv1


; Disk Parameter Block for drive 0. Calculated using DISKDEF values 0,0,31,0,8192,4096,128,0,0

b_dpb0:		DW	32					; SPT total number of sectors per track.
		DB	5					; BSH data allocation block shift factor, determined by the data block allocation size.
		DB	31					; BLM data allocation block mask (2[BSH - 1]).
		DB	1					; EXM extent mask determined by the data block allocation size and the number of disk blocks.
		DW	2047-6					; DSM determines total storage capacity of this drive. (disk size - 1).
		DW	1023					; DRM total number of directory entries that can be stored on this drive.
		DB	255					; AL0 determine reserved directory blocks.
		DB	0					; AL1 determine reserved directory blocks.
		DW	0					; CKS size of the directory check vector.
		DW	046h ;0					; OFF number of reserved tracks at the beginning of the disk.
		db  	2                   			; PSH (Physical Record Shift Factor) (512 -
		db  	3                   			; PHM (Physical Record Shift Mask)    byte sectors)
b_xlt0:		EQU	0
b_csv0:		DS	1					; Check vector for drive 0.
b_alv0:		DS	256					; Allocation vector for drive 0.

; Disk Parameter Block for drive 1. Calculated using DISKDEF values 1,0,31,0,16384,4096,128,0,0
b_dpb1:		DW	32					; SPT total number of sectors per track.
		DB	5					; BSH data allocation block shift factor, determined by the data block allocation size.
		DB	31					; BLM data allocation block mask (2[BSH - 1]).
		DB	1					; EXM extent mask determined by the data block allocation size and the number of disk blocks.
		DW	2047-6					; DSM determines total storage capacity of this drive. (disk size - 1).
		DW	1023					; DRM total number of directory entries that can be stored on this drive.
		DB	255					; AL0 determine reserved directory blocks.
		DB	0					; AL1 determine reserved directory blocks.
		DW	0					; CKS size of the directory check vector.
		DW	0846h					; OFF number of reserved tracks at the beginning of the disk.
		db  	2                   			; PSH (Physical Record Shift Factor) (512 -
		db  	3                   			; PHM (Physical Record Shift Mask)    byte sectors)
b_xlt1:		EQU	0
b_csv1:		DS	1					; Check vector for drive 1.
b_alv1:		DS	256					; Allocation vector for drive 1.

; Disk Parameter Block for drive 1. Calculated using DISKDEF values 1,0,31,0,16384,4096,128,0,0
b_dpb2:		DW	32				; SPT total number of sectors per track.
		DB	3					; BSH data allocation block shift factor, determined by the data block allocation size.
		DB	7					; BLM data allocation block mask (2[BSH - 1]).
		DB	0					; EXM extent mask determined by the data block allocation size and the number of disk blocks.
		DW	127					; DSM determines total storage capacity of this drive. (disk size - 1).
		DW	63					; DRM total number of directory entries that can be stored on this drive.
		DB	0C0h				; AL0 determine reserved directory blocks.
		DB	0					; AL1 determine reserved directory blocks.
		DW	0					; CKS size of the directory check vector.
		DW	1040h					; OFF number of reserved tracks at the beginning of the disk.
		db  	2                   			; PSH (Physical Record Shift Factor) (512 -
		db  	3                   			; PHM (Physical Record Shift Mask)    byte sectors)
b_xlt2:		EQU	0
b_csv2:		DS	1 ; was 0					; Check vector for drive 1.
b_alv2:		DS	16					; Allocation vector for drive 1.

; Disk Parameter Block for drive 1. Calculated using DISKDEF values 1,0,31,0,16384,4096,128,0,0
b_dpb3:		DW	32		; SPT total number of sectors per track.
		DB	3		; BSH data allocation block shift factor, determined by the data block allocation size.
		DB	7		; BLM data allocation block mask (2[BSH - 1]).
		DB	0		; EXM extent mask determined by the data block allocation size and the number of disk blocks.
		DW	127		; DSM determines total storage capacity of this drive. (disk size - 1).
		DW	63		; DRM total number of directory entries that can be stored on this drive.
		DB	0C0h		; AL0 determine reserved directory blocks.
		DB	0		; AL1 determine reserved directory blocks.
		DW	0		; CKS size of the directory check vector.
		DW	0h		; OFF number of reserved tracks at the beginning of the disk.
		db  	2                   			; PSH (Physical Record Shift Factor) (512 -
		db  	3                   			; PHM (Physical Record Shift Mask)    byte sectors)
b_xlt3:		EQU	0
b_csv3:		DS	1		; Check vector for drive 1.
b_alv3:		DS	16		; Allocation vector for drive 1.

BLKSIZ:		EQU	8192					; CP/M allocation size.
HSTSIZ:		EQU	512					; Host disk sector size.
HSTSPT:		EQU	32 ;1024					; Host disk sectors/trk.
HSTBLK:		EQU	HSTSIZ / 128				;   4 CP/M sects/host buff.
CPMSPT:		EQU	HSTBLK * HSTSPT				; 128 CP/M sectors/track.
SECMSK:		EQU	HSTBLK - 1				;   3 Sector mask.
;		smask	HSTBLK					; Compute sector mask.
SECSHF:		EQU	2 					; Log2(hstblk).

WRALL:		EQU	0					; Write to allocated.
WRDIR:		EQU	1					; Write to directory.
WRUAL:		EQU	2					; Write to unallocated.

_dma:		DW	HSTBUF

b_bootmsg:
	ASCII	"\r\n\r\neZ80F91 Acclaim! 128k CP/M vers 2.2 (c) (p) 1982 Digital Research Inc.\r\n"
	ASCII	"BIOS vers 1.3\r\n"
	ASCII	"Initial eZ80 and MMC support, 2004 by www.vegeneering.com\r\n"
	ASCII	"SD and Internal FLASH support added by Howard M. Harte\r\n\n$"

;b_ccpmsg: ASCII "Reload CCP$"

;	Unitialized RAM data areas.

MMCINITDONE: DS 1					; MMC Drive Initialization Done flag.
SEKDSK:		DS	1					; Seek disk number.
SEKTRK:		DS	2					; Seek track number
SEKSEC:		DS	2					; Seek sector number.

_adrv:		DS	1					; Host disk number.
_sect:		DS	1					; Host sector number.
_trk:		DS	2					; Host track number.

SEKHST:		DS	1					; Seek shr secshf.
HSTACT:		DS	1					; Host active flag.
HSTWRT:		DS	1					; Host written flag.

UNACNT:		DS	1					; Unalloc record count.
UNADSK:		DS	1					; Last unalloc disk.
UNATRK:		DS	2					; Last unalloc track.
UNASEC:		DS	2					; Last unalloc sector.

ERFLAG:		DS	1					; Error reporting.
RSFLAG:		DS	1					; Read sector flag.
READOP:		DS	1					; 1 if read operation.
WRTYPE:		DS	1					; Write operation type.
DMAADR:		DS	2					; Last dma address.
HSTBUF:		DS	HSTSIZ				; Host buffer.

b_dirbuf:	DS	80h					; 128 byte BDOS scratch pad.
			DS	7Fh
b_biosstack:	DS 1				; Use dirbuff as tempory stack space

