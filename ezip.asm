; Infocom EZIP (Z-Machine architecture v4) interpreter for Apple II,

; The EZIP interpreter is copyrighted by Infocom, Inc.

; This partially reverse-engineered source code is
; Ccopyright 2023 Eric Smith <spacewar@gmail.com>

	cpu	6502

; The differences between revisions stated here is not comprehensizve.

iver2a	equ	$0201		; Has exactly four save positions per disk, will only
				; work for games that have up to 32 KiB saves.
				; Released with A Mind Forever Voyaging r77 850814

iver2b	equ	$0202		; Allows disks to have three or four save positions,
				; supporting games with up to 46 KiB saves.
				; Forces CSWL to be COUT1 at start.
				; Adds "be patient" message to verify.
				; Radically changes implementation of get_prop_addr,
				; purpose unknown.
				; Changes random number generator, purpose unknown.
				; Changes subroutine Seb96, purpose unknown.
				; Changes some constants in save and restore,
				; purpose unknown.
				; Released with Trinity r11 860509

iver2c	equ	$0203		; Changes deselecting output stream 3
				; (table), to prevent table stream stack underflow.
				; Changes data tables used by random number generator,
				; purpose unknown.
				; Released with Bureaucracy r86 870212

iver2d	equ	$0204		; Changes spaces to tabs in save messages (probably
				; by mistake).
				; Changes a constant in scan_table, purpose unknown.
				; Released with Bureaucracy r116 870602

; No Apple II games with EZIP versions 2E through 2G have been found

iver2h	equ	$0208		; Removes several calls to HOME.
				; Changes the tabs in messages back to spaces.
				; Adds two extra carriage returns at the end of
				; some messages.
			 	; Released with Nord and Bert r19 870723


char_tab	equ	$09
char_cr		equ	$0d


	ifndef	iver
iver	equ	iver2a
	endif


fillto	macro	addr, val
	while	* < addr
size	set	addr-*
	if	size > 256
size	set	256
	endif
	fcb	[size] val
	endm
	endm

	if	iver==iver2a

; EZIP 2A sets the high bit of interpreter message strings
; macro for text string
text_str	macro	arg
	irpc	char,arg
	fcb	'char'+$80
	endm
	endm
	else

; EZIP 2B and later do NOT set the high bit of interpreter message strings
; macro for text string
text_str	macro	arg
	fcb	arg
	endm

	endif

; macro to print a message
prt_msg	macro	name
	ldx	#msg_name&$ff
	lda	#msg_name>>8
	ldy	#msg_len_name
	jsr	msg_out
	endm

; macro to print a message and return
prt_msg_ret	macro	name
	ldx	#msg_name&$ff
	lda	#msg_name>>8
	ldy	#msg_len_name
	jmp	msg_out
	endm

; macro to print a message, loads in alternate order (sigh)
prt_msg_alt	macro	name
	lda	#msg_name>>8
	ldx	#msg_name&$ff
	ldy	#msg_len_name
	jsr	msg_out
	endm

; macro to start a table of addresses, split into a high byte table and a low byte table
optab_start	macro	label,size
label_hi	equ	*
label_lo	equ	*+size
optab_org	set	*
optab_siz	set	size
optab_idx	set	0
		endm

; macro for an entry in a table of addresses, split into a high byte table and a low byte table
optab_ent	macro	addr
		org	optab_org+optab_idx
		fcb	addr>>8
		org	optab_org+optab_siz+optab_idx
		fcb	addr&$ff
optab_idx	set	optab_idx+1
		endm


; disk zero page variables
		org	$00

Z00:		rmb	1
Z01:		rmb	1
Z02:		rmb	1
Z03:		rmb	1
rwts_sector:	rmb	1
rwts_track:	rmb	1
Z06:		rmb	1
rwts_cmd:	rmb	1
rwts_buf:	rmb	2
Z0a:		rmb	1
rwts_slotx16:	rmb	1
Z0c:		rmb	1
Z0d:		rmb	1
Z0e:		rmb	1
Z0f:		rmb	1
Z10:		rmb	1
rwts18_sector:	rmb	1
		rmb	1
Z13:		rmb	1
Z14:		rmb	1
Z15:		rmb	1
		rmb	1
rwts18_sector_temp:	rmb	1
		rmb	2
Z1a:		rmb	1


; Apple II zero page locations
wndwdt	equ	$21
wndtop	equ	$22
wndbot	equ	$23
cursrh	equ	$24
cursrv	equ	$25
Z2b	equ	$2b
invflg	equ	$32
cswl	equ	$36
rndloc	equ	$4e


; interpreter zero page variables
interp_zp_origin	equ	$56
	org	interp_zp_origin

opcode:	rmb	1
argcnt:	rmb	1

arg1:	rmb	2
arg2:	rmb	2
arg3:	rmb	2
arg4:	rmb	2
arg5:	rmb	2
arg6:	rmb	2
arg7:	rmb	2
arg8:	rmb	2

Z68:	rmb	1
Z69:	rmb	1
Z6a:	rmb	1

acc:	rmb	2

Z6d:	rmb	1
Z6e:	rmb	1
Z6f:	rmb	1
Z70:	rmb	1
Z71:	rmb	1
Z72:	rmb	1
Z73:	rmb	1
Z74:	rmb	1
pc:	rmb	3
Z78:	rmb	1
Z79:	rmb	1
Z7a:	rmb	1
Z7b:	rmb	1
Z7c:	rmb	1
Z7d:	rmb	1
Z7e:	rmb	1
Z7f:	rmb	1
Z80:	rmb	1
Z81:	rmb	1
Z82:	rmb	1
Z83:	rmb	1
Z84:	rmb	1
	rmb	2
Z87:	rmb	1
Z88:	rmb	1
Z89:	rmb	1
Z8a:	rmb	1
Z8b:	rmb	1
	rmb	8
Z94:	rmb	1
Z95:	rmb	1
Z96:	rmb	1
Z97:	rmb	1
Z98:	rmb	1
Z99:	rmb	1
Z9a:	rmb	1
Z9b:	rmb	1
Z9c:	rmb	1
Z9d:	rmb	1
Z9e:	rmb	1
Z9f:	rmb	1
Za0:	rmb	1
Za1:	rmb	1
Za2:	rmb	1
Za3:	rmb	1
Za4:	rmb	1
Za5:	rmb	1
Za6:	rmb	1
Za7:	rmb	1
Za8:	rmb	1
Za9:	rmb	1
Zaa:	rmb	1
Zab:	rmb	1
Zac:	rmb	1
Zad:	rmb	1
Zae:	rmb	1
Zaf:	rmb	1
disk_block_num:	rmb	2
Zb2:	rmb	1
Zb3:	rmb	1
	rmb	2
Zb6:	rmb	1
Zb7:	rmb	1
Zb8:	rmb	1
Zb9:	rmb	1
Zba:	rmb	1
	rmb	2
Zbd:	rmb	1
Zbe:	rmb	1
Zbf:	rmb	1
Zc0:	rmb	1
Zc1:	rmb	1
Zc2:	rmb	1
Zc3:	rmb	1
Zc4:	rmb	1
Zc5:	rmb	1
Zc6:	rmb	1
Zc7:	rmb	1
Zc8:	rmb	1
Zc9:	rmb	1
Zca:	rmb	1
Zcb:	rmb	1
Zcc:	rmb	1
Zcd:	rmb	1
Zce:	rmb	1
Zcf:	rmb	1
Zd0:	rmb	1
Zd1:	rmb	1
Zd2:	rmb	1
Zd3:	rmb	1
Zd4:	rmb	1
Zd5:	rmb	1
	rmb	1
Zd7:	rmb	1
	rmb	1
Zd9:	rmb	1
	rmb	4
Zde:	rmb	1
	rmb	2
Ze1:	rmb	1
Ze2:	rmb	1
Ze3:	rmb	1
Ze4:	rmb	1
Ze5:	rmb	1
	rmb	1
Ze7:	rmb	1
Ze8:	rmb	2
	rmb	1
Zeb:	rmb	2	; stack pointer
Zed:	rmb	2	; two bytes
	rmb	2
ostream_1_state:	rmb	1
ostream_2_state:	rmb	1
ostream_3_state:	rmb	1
Zf4:	rmb	1
Zf5:	rmb	1
Zf6:	rmb	1
Zf7:	rmb	1


D0100	equ	$0100
D01ff	equ	$01ff

D0200	equ	$0200

D057b	equ	$057b

D086a	equ	$086a
S086b	equ	$086b

		org	$0900
rwts_sec_buf_size	equ	86

rwts_data_buf	rmb	256	; user data
rwts_pri_buf:	rmb	256	; disk nibbles
rwts_sec_buf:	rmb	86	; disk nibbles

	if	iver>=iver2b
	align	$0100
	endif

D0b56:	rmb	128
D0bd6:	rmb	128
D0c56:	rmb	128
D0cd6:	rmb	128

; data stack, 256 words, builds upward
D0d56:	rmb	$0100
D0e56:	rmb	$0100
D0f56:	rmb	$0100
D1056:	rmb	$0100

local_vars:	rmb	30

		rmb	2

D1176:		rmb	2	; save hdr_game_ver
D1178:		rmb	2	; save Zeb
D117a:		rmb	2	; save Zed
D117c:		rmb	3	; save PC

	align	$0100

; game header

hdr_arch:	rmb	1	; Z-machine architecture version
hdr_flags_1:	rmb	1	; flags 1
hdr_game_ver:	rmb	2	; game version
hdr_high_mem:	rmb	2	; base of high memory
hdr_init_pc:	rmb	2	; initial value of program counter (byte address)
hdr_vocab:	rmb	2	; location of dictionary
hdr_object:	rmb	2	; object table
hdr_globals:	rmb	2	; global variable table
hdr_pure:	rmb	2	; base of pure (immutable) memory
hdr_flags2:	rmb	2	; flags 2
		rmb	6	; "serial" (usually game release date)
hdr_abbrev:	rmb	2	; abbreviation table
hdr_length:	rmb	2	; length of file
hdr_checksum:	rmb	2	; checksum of file
hdr_interp_ver:	rmb	1	; interpreter version number
hdr_interp_rev:	rmb	1	; interpreter reversion
hdr_scr_height:	rmb	1	; screen height, characters
hdr_scr_width:	rmb	1	; screen width, characters


D1000	equ	$1000		; used for memory test at startup only, otherwise
				; would overlap Z-Machine stack or other vars



; Apple IIe I/O
kbd		equ	$c000
rd_main_ram	equ	$c002
rd_card_ram	equ	$c003
wr_main_ram	equ	$c004
wr_card_ram	equ	$c005
kbd_strb	equ	$c010
spkr		equ	$c030
text_on		equ	$c051
mixed_off	equ	$c052
txt_page_1	equ	$c054

; Disk II I/O (indexed by slot x 16)
ph_off	equ	$c080
mtr_off	equ	$c088
mtr_on	equ	$c089
drv0_en	equ	$c08a
drv1_en	equ	$c08b
q6l	equ	$c08c
q6h	equ	$c08d
q7l	equ	$c08e
q7h	equ	$c08f

; Apple slot 3 firmware (80-column)
sl3fw	equ	$c300


; Apple II monitor ROM locations
			;      IIe  IIe       IIc  IIc   IIc
			; IIe  enh  opt  IIc  3.5  mem1  mem2  IIc+  IIgs
romid	equ	$fbb3	; $06  $06  $06  $06  $06  $06   $06   $06   $06f
romid2	equ	$fbc0	; $ea  $e0  $e0  $00  $00  $00   $00   $00   $ea

vtab	equ	$fc22
home	equ	$fc58
clreol	equ	$fc9c
Sfca8	equ	$fca8
rdkey	equ	$fd0c
cout	equ	$fded
cout1	equ	$fdf0
bell	equ	$ff3a

	org	$d000

rwts:
	nop
	nop
	nop
	php
	sei
	jsr	rwts_inner
	bcs	.fail
	plp
	clc
	rts
.fail:	plp
	sec
	rts


pre_nibble:
	ldx	#$00
	ldy	#$02
.loop1:	dey
	lda	(rwts_buf),y
	lsr
	rol	rwts_sec_buf,x
	lsr
	rol	rwts_sec_buf,x
	sta	rwts_pri_buf,y
	inx
	cpx	#rwts_sec_buf_size
	bcc	.loop1
	ldx	#$00
	tya
	bne	.loop1
	ldx	#rwts_sec_buf_size-1
.loop2:	lda	rwts_sec_buf,x
	and	#$3f
	sta	rwts_sec_buf,x
	dex
	bpl	.loop2
	rts


; write data field
Sd03a:	stx	Z0e
	stx	Dd474
	sec

	lda	q6h,x		; check write protect
	lda	q7l,x
	bmi	.exit

	lda	rwts_sec_buf
	sta	Z0d

	lda	#$ff		; write a sync pattern
	sta	q7h,x
	ora	q6l,x
	pha
	pla
	nop

	ldy	#$04		; write four more sync patterns
.loop1:	pha
	pla
	jsr	write_28
	dey
	bne	.loop1

	lda	#$d5		; write data field prologue
	jsr	write_30
	lda	#$aa
	jsr	write_30
	lda	#$ad
	jsr	write_30

; write secondary buffer (reverse order)
	tya
	ldy	#rwts_sec_buf_size
	bne	.lp2a
.loop2:	lda	rwts_sec_buf,y
.lp2a:	eor	rwts_sec_buf-1,y
	tax
	lda	nib_tab,x
	ldx	Z0e
	sta	q6h,x
	lda	q6l,x
	dey
	bne	.loop2

; write primary buffer
	lda	Z0d
	nop
.loop3:	eor	rwts_pri_buf,y
	tax
	lda	nib_tab,x
	ldx	Dd474
	sta	q6h,x
	lda	q6l,x
	lda	rwts_pri_buf,y
	iny
	bne	.loop3

	tax			; write checksum
	lda	nib_tab,x
	ldx	Z0e
	jsr	write_21

	lda	#$de		; write data field epilogue
	jsr	write_30
	lda	#$aa
	jsr	write_30
	lda	#$eb
	jsr	write_30

	lda	#$ff		; dummy write to get third byte of data field epilogue out
	jsr	write_30

	lda	q7l,x		; turn off writing
.exit:	lda	q6l,x
	rts


write_30:
	clc			; 2

write_28:
	pha			; 3
	pla			; 4

write_21:
	sta	q6h,x		; 5
	ora	q6l,x		; 4
	rts			; 6
				; +6 jsr


post_nibble:
	ldy	#$00
.loop1:	ldx	#rwts_sec_buf_size
.loop2:	dex
	bmi	.loop1
	lda	rwts_pri_buf,y
	lsr	rwts_sec_buf,x
	rol
	lsr	rwts_sec_buf,x
	rol
	sta	(rwts_buf),y
	iny
	cpy	Z0d
	bne	.loop2
	rts


read_data_field_16:
	ldy	#$20
.loop1:	dey
	beq	read_data_field_16_fail
.loop2:	lda	q6l,x
	bpl	.loop2
.loop3:	eor	#$d5		; check for data field prologue 1st byte
	bne	.loop1
	nop

.loop4:	lda	q6l,x
	bpl	.loop4
	cmp	#$aa		; check for data field prologue 2nd byte
	bne	.loop3
	ldy	#rwts_sec_buf_size
.loop5:	lda	q6l,x
	bpl	.loop5
	cmp	#$ad		; check for data field prologue 3rd byte
	bne	.loop3

; read secondary buffer in reverse order (high to low)
	lda	#$00
.loop6:	dey
	sty	Z0d
.loop7:	ldy	q6l,x
	bpl	.loop7
	eor	denib_tab,y
	ldy	Z0d
	sta	rwts_sec_buf,y
	bne	.loop6

; read primary buffer in forward order
.loop8:	sty	Z0d
.loop9:	ldy	q6l,x
	bpl	.loop9
	eor	denib_tab,y
	ldy	Z0d
	sta	rwts_pri_buf,y
	iny
	bne	.loop8

.loop10:
	ldy	q6l,x
	bpl	.loop10
	cmp	denib_tab,y	; verify checksum
	bne	read_data_field_16_fail

.loop11:
	lda	q6l,x
	bpl	.loop11
	cmp	#$de		; check for data field epilogue 1st byte
	bne	read_data_field_16_fail
	nop

.loop12:
	lda	q6l,x
	bpl	.loop12
	cmp	#$aa		; check for data field epilogue 2nd byte
	beq	read_address_field_success
read_data_field_16_fail:
	sec
	rts


; search for and read address field
read_address_field:
	ldy	#$fc
	sty	Z0d
.loop1:	iny
	bne	.loop2
	inc	Z0d
	beq	read_data_field_16_fail
.loop2:	lda	q6l,x
	bpl	.loop2
.loop3:	cmp	#$d5		; check for address field prologue 1st byte
	bne	.loop1
	nop
.loop4:	lda	q6l,x
	bpl	.loop4
	cmp	#$aa		; check for address field prologue 2nd byte
	bne	.loop3
	ldy	#$03
.loop5:	lda	q6l,x
	bpl	.loop5
	cmp	#$96		; check for address field prologue 3rd byte
	bne	.loop3
	lda	#$00
.loop6:	sta	Z0e
.loop7:	lda	q6l,x
	bpl	.loop7
	rol
	sta	Z0d
.loop8:	lda	q6l,x
	bpl	.loop8
	and	Z0d
	sta	Z0f,y
	eor	Z0e
	dey
	bpl	.loop6
	tay
	bne	read_data_field_16_fail
.loop9:	lda	q6l,x
	bpl	.loop9
	cmp	#$de		; check for address field epilogue 1st byte
	bne	read_data_field_16_fail
	nop
.loop10:
	lda	q6l,x
	bpl	.loop10
	cmp	#$aa		; check for address field epilogue 2nd byte
	bne	read_data_field_16_fail
read_address_field_success:
	clc
	rts


seek_track:
	stx	rwts_slotx16
	sta	Z0c
	cmp	Dd461
	beq	.rtn
	lda	#$00
	sta	Z0d
.loop1:	lda	Dd461
	sta	Z0e
	sec
	sbc	Z0c
	beq	.fwd5
	bcs	.fwd1
	eor	#$ff
	inc	Dd461
	bcc	.fwd2
.fwd1:	adc	#$fe
	dec	Dd461
.fwd2:	cmp	Z0d
	bcc	.fwd3
	lda	Z0d
.fwd3:	cmp	#$0c
	bcs	.fwd4
	tay
.fwd4:	sec
	jsr	.subr1
	lda	motor_on_time_tab,y
	jsr	delay
	lda	Z0e
	clc
	jsr	.subr2
	lda	motor_off_time_tab,y
	jsr	delay
	inc	Z0d
	bne	.loop1
.fwd5:	jsr	delay
	clc
.subr1:	lda	Dd461
.subr2:	and	#$03
	rol
	ora	rwts_slotx16
	tax
	lda	ph_off,x
	ldx	rwts_slotx16
.rtn:	rts


delay:	ldx	#$11
.loop1:	dex
	bne	.loop1
	inc	Z13
	bne	.fwd1
	inc	Z14
.fwd1:	sec
	sbc	#$01
	bne	delay
	rts


motor_on_time_tab:
	fcb	$01,$30,$28,$24,$20,$1e,$1d,$1c
	fcb	$1c,$1c,$1c,$1c

motor_off_time_tab:
	fcb	$70,$2c,$26,$22,$1f,$1e,$1d,$1c
	fcb	$1c,$1c,$1c,$1c

nib_tab:
	fcb	$96,$97,$9a,$9b,$9d,$9e,$9f,$a6
	fcb	$a7,$ab,$ac,$ad,$ae,$af,$b2,$b3
	fcb	$b4,$b5,$b6,$b7,$b9,$ba,$bb,$bc
	fcb	$bd,$be,$bf,$cb,$cd,$ce,$cf,$d3
	fcb	$d6,$d7,$d9,$da,$db,$dc,$dd,$de
	fcb	$df,$e5,$e6,$e7,$e9,$ea,$eb,$ec
	fcb	$ed,$ee,$ef,$f2,$f3,$f4,$f5,$f6
	fcb	$f7,$f9,$fa,$fb,$fc,$fd,$fe,$ff

denib_tab	equ	*-$96
	fcb	$00,$01,$98,$99,$02,$03,$9c,$04
	fcb	$05,$06,$a0,$a1,$a2,$a3,$a4,$a5
	fcb	$07,$08,$a8,$a9,$aa,$09,$0a,$0b
	fcb	$0c,$0d,$b0,$b1,$0e,$0f,$10,$11
	fcb	$12,$13,$b8,$14,$15,$16,$17,$18
	fcb	$19,$1a,$c0,$c1,$c2,$c3,$c4,$c5
	fcb	$c6,$c7,$c8,$c9,$ca,$1b,$cc,$1c
	fcb	$1d,$1e,$d0,$d1,$d2,$1f,$d4,$d5
	fcb	$20,$21,$d8,$22,$23,$24,$25,$26
	fcb	$27,$28,$e0,$e1,$e2,$e3,$e4,$29
	fcb	$2a,$2b,$e8,$2c,$2d,$2e,$2f,$30
	fcb	$31,$32,$f0,$f1,$33,$34,$35,$36
	fcb	$37,$38,$f8,$39,$3a,$3b,$3c,$3d
	fcb	$3e,$3f


; On entry:
;   A = command
;	$00 = read 16-sector
;	$01 = write 16-sector
;	$80 = read 18-sector
rwts_inner:
	sta	rwts_cmd
	lda	#$02
	sta	Dd475
	asl
	sta	Dd471
	ldx	Z00
	cpx	Z01
	beq	.fwd1
	ldx	Z01
	lda	q7l,x
.loop1:	ldy	#$08
	lda	q6l,x
.loop2:	cmp	q6l,x
	bne	.loop1
	dey
	bne	.loop2
	ldx	Z00
	stx	Z01
.fwd1:	lda	q7l,x
	lda	q6l,x
	ldy	#$08
.loop3:	lda	q6l,x
	pha
	pla
	pha
	pla
	stx	Dd473
	cmp	q6l,x
	bne	.fwd2
	dey
	bne	.loop3
.fwd2:	php
	lda	mtr_on,x
	lda	#$d8
	sta	Z14
	lda	Z02
	cmp	Z03
	beq	.fwd3
	sta	Z03
	plp
	ldy	#$00
	php
.fwd3:	ror
	bcc	.fwd4
	lda	drv0_en,x
	bcs	.fwd5
.fwd4:	lda	drv1_en,x
.fwd5:	ror	Z0a
	plp
	php
	bne	.fwd6
	ldy	#$07
.loop4:	jsr	delay
	dey
	bne	.loop4
	ldx	Dd473
.fwd6:	lda	rwts_track
	jsr	Sd417
	plp
	bne	.fwd7
	ldy	Z14
	bpl	.fwd7
.loop5:	ldy	#$12
.loop6:	dey
	bne	.loop6
	inc	Z13
	bne	.loop5
	inc	Z14
	bne	.loop5

.fwd7:	lda	rwts_cmd	; is command read or write?
	ror
	php
	bcc	.loop7		;   read

	jsr	pre_nibble	; write

.loop7:	lda	#48
	sta	addr_field_search_retry_counter

.loop8:	ldx	Dd473

	lda	rwts_cmd	; 16- or 18-sector?
	bpl	.fwd8		;   16-sector

; 18-sector - read a data field instead of an address field
	sta	Z1a
	jsr	read_data_field_18
	bcc	.fwd9
	bcs	.loop9		; always taken

; 16-sector - read an address field
.fwd8:	jsr	read_address_field
	bcc	.fwd9

; address field not found
.loop9:	dec	addr_field_search_retry_counter
	bpl	.loop8

; too many errors searching for address field
.loop10:
	lda	Dd461
	pha
	lda	#$60
	jsr	Sd449
	dec	Dd475
	beq	.fwd10
	lda	#$04
	sta	Dd471
	lda	#$00
	jsr	Sd417
	pla
.loop11:
	jsr	Sd417
	jmp	.loop7

.fwd9:	ldy	rwts18_sector
	cpy	Dd461
	beq	.fwd11
	lda	Dd461
	pha
	tya
	jsr	Sd449
	pla
	dec	Dd471
	bne	.loop11
	beq	.loop10		; always taken

.fwd10:	pla
	lda	#$40
	plp
	jmp	.fwd16

.fwd11:	lda	rwts_cmd
	bmi	.fwd12

	ldy	rwts_sector
	lda	interleave_tab,y
	cmp	Z10
	bne	.loop9

.fwd12:	plp
	bcs	.fwd18
	lda	rwts_cmd
	bpl	.fwd13

	ldy	rwts_sector
	sty	Z1a
	jsr	read_data_field_18

	bcc	.fwd14		; This three-instruction sequence could just be jmp .fwd14
	sec
	bcs	.fwd14		; always taken

.fwd13:	jsr	read_data_field_16

.fwd14:	bcc	.fwd15
	clc
	php
	bcc	.loop9
.fwd15:	ldx	#$00
	stx	Z0d
	jsr	post_nibble
	ldx	Dd473
.rev1:	lda	#$00
	clc
	bcc	.fwd17
.fwd16:	sec
.fwd17:	sta	Z06
	lda	mtr_off,x
	rts

.fwd18:	jsr	Sd03a
	bcc	.rev1
	lda	#$10
	bne	.fwd16		; always taken


Sd417:	asl
	jsr	Sd41f
	lsr	Dd461
	rts


Sd41f:	sta	Z0c
	jsr	Sd442
	lda	Dd461,y
	bit	Z0a
	bmi	.fwd1
	lda	Dd469,y
.fwd1:	sta	Dd461
	lda	Z0c
	bit	Z0a
	bmi	.fwd2
	sta	Dd469,y
	bpl	.fwd3
.fwd2:	sta	Dd461,y
.fwd3:	jmp	seek_track


Sd442:	txa
	lsr
	lsr
	lsr
	lsr
	tay
	rts


Sd449:	pha
	lda	Z02
	ror
	ror	Z0a
	jsr	Sd442
	pla
	asl
	bit	Z0a
	bmi	.fwd1
	sta	Dd469,y
	bpl	.rtn
.fwd1:	sta	Dd461,y
.rtn:	rts


Dd461:	fcb	$00,$00,$00,$00,$00,$00,$00,$00
Dd469:	fcb	$00,$00,$00,$00,$00,$00,$00,$00
Dd471:	fcb	$00

addr_field_search_retry_counter:
	fcb	$00

Dd473:	fcb	$00
Dd474:	fcb	$00
Dd475:	fcb	$00


interleave_tab:
	fcb	$00,$04,$08,$0c,$01,$05,$09,$0d
	fcb	$02,$06,$0a,$0e,$03,$07,$0b,$0f


; ? 18-sector data field read
read_data_field_18:
	lda	#$20
	sta	Z15
	tay
.loop1:	lda	#$84
	dec	Z15
	beq	.fwd3
.loop2:	dey
	beq	.loop2
	nop
	nop
	lda	q6l,x
	bpl	.loop2
	cmp	#$d5		; check for data field prologue 1st byte
	bne	.loop2
.loop3:	lda	q6l,x
	bpl	.loop3
	cmp	#$aa		; check for data field prologue 2nd byte
	bne	.loop1
.loop4:	lda	q6l,x
	bpl	.loop4
	cmp	#$ad		; check for data field prologue 3rd byte
	bne	.loop1
	sec

.loop5:	lda	q6l,x
	bpl	.loop5
	rol
	sta	rwts18_sector_temp

.loop6:	lda	q6l,x
	bpl	.loop6
	and	rwts18_sector_temp
	sta	rwts18_sector
	lda	Z1a
	bmi	.fwd1

.loop7:	ldy	#86		; read 86 nibbles into secondary buffer, reverse order
	lda	#$00
.loop8:	dey
	sty	Z0d
.loop9:	ldy	q6l,x
	bpl	.loop9
	eor	denib_tab,y
	ldy	Z0d
	sta	rwts_sec_buf,y
	bne	.loop8

.loop10:			; read 256 nibbles into primary buffer, forward order
	sty	Z0d
.loop11:
	ldy	q6l,x
	bpl	.loop11
	eor	denib_tab,y
	ldy	Z0d
	sta	rwts_pri_buf,y
	iny
	bne	.loop10

.loop12:
	ldy	q6l,x		; get checksum
	bpl	.loop12
	dec	Z1a
	bpl	.loop7
	cmp	denib_tab,y
	bne	.fwd2
.fwd1:	clc
	rts
.fwd2:	lda	#$85
.fwd3:	sta	Z06
	sec
	rts


; subroutine called by boot1
e_d505:	lda	text_on
	lda	mixed_off
	lda	txt_page_1

	lda	#rwts_data_buf>>8
	sta	rwts_buf+1
	lda	#rwts_data_buf&$ff
	sta	rwts_buf

	lda	#$01
	sta	Z02
	sta	Z03
	rts


; convert block number to track and sector
Sd51d:	lda	#$00
	sta	rwts_track
	ldx	disk_block_num+1
	ldy	disk_block_num

	cpx	#$01		; is the block number greater than $100?
	bcc	.fwd5		;   under $100, 16-sector

	bne	.fwd1		;   $200 or over, 18-sector

	cpy	#$8a		; is the block number greater than $18a
	bcc	.fwd5		;   under $18a, 16-sector

; 18-sector
.fwd1:	lda	Ze7
	cmp	#$02
	beq	.fwd2
	jsr	Sd87e

	ldx	disk_block_num+1	; subtract $18a to get side B relative block number
	ldy	disk_block_num
.fwd2:	tya
	sec
	sbc	#$8a
	tay
	txa
	sbc	#$01
	tax
	tya

; 18-sector (side B)
;restoring divsion by 18 sectors/track for side B
	sec
.loop1:	sbc	#18
	bcs	.fwd3
	dex
	bmi	.fwd4
	sec
.fwd3:	inc	rwts_track
	bcs	.loop1
.fwd4:	clc
	adc	#18
	sta	rwts_sector
	lda	rwts_track
	cmp	#$23
	bcc	.no_int_err_0c
	jmp	int_err_0c
.no_int_err_0c:
	lda	#$84
	bne	.fwd7	; always taken

; 16-sector
.fwd5:	lda	Ze7
	cmp	#$01
	beq	.fwd6
	jsr	Sd856
	
; convert block number to track and sector, 16-sector (side A)
	ldx	disk_block_num+1
	ldy	disk_block_num
.fwd6:	tya
	and	#$0f
	sta	rwts_sector
	txa
	asl
	asl
	asl
	asl
	sta	rwts_track
	tya
	lsr
	lsr
	lsr
	lsr
	ora	rwts_track
	clc
	adc	#$03
	cmp	#$23
	bcs	int_err_0c
	sta	rwts_track
	lda	#$00

; 16- and 18-sector paths rejoin here
.fwd7:	sta	rd_main_ram
	jsr	rwts
	bcs	int_err_0e
	ldy	Ded07
	sta	wr_main_ram,y	; indexed to get main or card

	ldy	#$00
.loop2:	lda	rwts_data_buf,y
	sta	(Zb2),y
	iny
	bne	.loop2

	sta	wr_main_ram
	inc	disk_block_num
	bne	.fwd8
	inc	disk_block_num+1
.fwd8:	inc	Zb3
	lda	Zb3
	cmp	#$c0
	bcc	.rtn
	lda	#$08
	sta	Zb3
	lda	#$01
	sta	Ded07
.rtn:	rts


; disk I/O error
int_err_0e:
	lda	#$0e
	jmp	int_error


Ld5c8:	inc	rwts_sector
	lda	rwts_sector
	and	#$0f
	bne	.fwd1
	ldx	rwts_track
	inx
	cpx	#$23
	bcs	Ld5f3
	stx	rwts_track
.fwd1:	sta	rwts_sector
	inc	Zb3
	clc
	rts


Sd5df:	ldy	#$00
	sta	rd_main_ram
.loop1:	lda	(Zb2),y
	sta	rwts_data_buf,y
	iny
	bne	.loop1
	lda	#$01
	jsr	rwts
	bcc	Ld5c8
Ld5f3:	rts


int_err_0c:
	lda	#$0c
	jmp	int_error


; disk I/O error
int_err_0e_alt:
	lda	#$0e
	jmp	int_error


read_sector:
	lda	#$00
	jsr	rwts
	bcs	int_err_0e_alt
	ldy	#$00
	sta	rd_main_ram

.loop1:	lda	rwts_data_buf,y
	sta	(Zb2),y
	iny
	bne	.loop1

	inc	disk_block_num
	bne	.noincblkhi
	inc	disk_block_num+1
.noincblkhi:
	inc	rwts_sector
	lda	rwts_sector
	and	#$0f
	bne	.noinctrk
	ldx	rwts_track
	inx
	cpx	#$23
	bcs	Ld5f3
	stx	rwts_track
.noinctrk:
	sta	rwts_sector
	inc	Zb3
	clc
	rts

; end of low-level disk routines


Sd62f:	jsr	op_new_line
	lda	#$00
	sta	Zd4
	if	iver<=iver2d
	jmp	home
	else
	rts
	endif


msg_default_is:
	text_str	" (Default is "
Dd646:	text_str	"*) >"
msg_len_default_is	equ	*-msg_default_is


; On entry:
;   A = default value - 1
Sd64a:	clc
	adc	#'1'
	sta	Dd646
	prt_msg_ret	default_is


	if	iver>=iver2b
max_save_position:	fcb	$00
	endif


msg_position:
	fcb	char_cr
	text_str	"Position 1-"
	if	iver==iver2a
	text_str	"4"
	else
msg_position_max_ascii:	text_str	"*"
	endif

msg_len_position	equ	*-msg_position


msg_drive:
	fcb	char_cr
	text_str	"Drive 1 or 2"
msg_len_drive	equ	*-msg_drive


msg_slot:
	fcb	char_cr
	text_str	"Slot 1-7"
msg_len_slot	equ	*-msg_slot


Dd67c:	fcb	$05


msg_pos_drive_slot_verify:
	fcb	char_cr,char_cr
	text_str	"Position "
Dd688:	text_str	"*; Drive #"
Dd692:	text_str	"*; Slot "
Dd69a:	text_str	"*."
	fcb	char_cr
	text_str	"Are you sure? (Y/N) >"
msg_len_pos_drive_slot_verify	equ	*-msg_pos_drive_slot_verify


msg_insert_save:
	fcb	char_cr
	text_str	"Insert"
	if	iver==iver2d
	fcb	char_tab
	else
	text_str	" "
	endif
	text_str	"SAVE disk into Drive #"
Dd6d0:	text_str	"*."
msg_len_insert_save	equ	*-msg_insert_save

msg_yes:
	text_str	"YES"
	fcb	char_cr
msg_len_yes	equ	*-msg_yes

msg_no:
	text_str	"NO"
	fcb	char_cr
msg_len_no	equ	*-msg_no


Sd6d9:	prt_msg	position
	lda	Ze1
	jsr	Sd64a
.loop1:	jsr	Sda78
	cmp	#char_cr
	beq	.fwd1
	sec
	sbc	#'1'
	if	iver==iver2a
	cmp	#4
	else
	cmp	max_save_position
	endif
	bcc	.fwd2
	jsr	Sdd39
	jmp	.loop1

.fwd1:	lda	Ze1
.fwd2:	sta	Ze3
	clc
	adc	#'1'
	sta	Dd688
	sta	Dd8d1
	sta	Dd99d
	ora	#$80
	jsr	Sdaee
	prt_msg	drive
	lda	Ze2
	jsr	Sd64a
.loop2:	jsr	Sda78
	cmp	#$0d
	beq	.fwd3
	sec
	sbc	#'1'
	cmp	#2
	bcc	.fwd4
	jsr	Sdd39
	jmp	.loop2

.fwd3:	lda	Ze2
.fwd4:	sta	Ze4
	clc
	adc	#'1'
	sta	Dd6d0
	sta	Dd692
	ora	#$80
	jsr	Sdaee

	lda	romid2_save	; IIc family?
	bne	.fwd5		;   no
	lda	#$05		; yes, force slot 5
	bne	.fwd7

.fwd5:	prt_msg	slot
	lda	Dd67c
	jsr	Sd64a
.loop3:	jsr	Sda78
	cmp	#$0d
	beq	.fwd6
	sec
	sbc	#'1'
	cmp	#$07
	bcc	.fwd7
	jsr	Sdd39
	jmp	.loop3
.fwd6:	lda	Dd67c
.fwd7:	sta	Ze5
	clc
	adc	#'1'
	sta	Dd69a

	ldx	romid2_save	; IIc family?
	beq	.fwd8		;   yes
	ora	#$80		; no
	jsr	Sdaee

.fwd8:	prt_msg	pos_drive_slot_verify
.loop4:	jsr	Sda78
	cmp	#'y'
	beq	.fwd10
	cmp	#'Y'
	beq	.fwd10
	cmp	#char_cr
	beq	.fwd10
	cmp	#'n'
	beq	.fwd9
	cmp	#'N'
	beq	.fwd9
	jsr	Sdd39
	jmp	.loop4

.fwd9:	prt_msg	no
	jmp	Sd6d9

.fwd10:	prt_msg	yes
	lda	Ze4
	sta	Z02
	inc	Z02
	ldx	Ze5
	inx
	txa
	asl
	asl
	asl
	asl
	sta	Z00
	lda	Ze3

	if	iver==iver2a

; exactly four save locations, each eight tracks
	asl
	asl
	asl
	sta	rwts_track
	lda	Ze3
	lsr
	php
	clc
	adc	rwts_track
	sta	rwts_track
	lda	#$00
	plp
	bcc	.fwd11
	lda	#$08
.fwd11:	sta	rwts_sector

	else

	ldx	max_save_position
	cpx	#$03
	beq	.fwd12
	clc
	adc	#$03
.fwd12:	tax
	lda	save_start_track_tbl,X
	sta	rwts_track
	lda	save_start_sector_tbl,X
	sta	rwts_sector

	endif

	prt_msg	insert_save

Sd7f2:	prt_msg	press_return
.loop5:	jsr	Sda78
	cmp	#char_cr
	beq	.fwd13
	jsr	Sdd39
	jmp	.loop5
.fwd13:	rts


msg_press_return:
	fcb	char_cr
	text_str	"Press [RETURN] to continue."
	fcb	char_cr
	if	iver>=iver2h
	fcb	char_cr
	fcb	char_cr
	endif
msg_len_press_return	equ	*-msg_press_return


	if	iver>=iver2b
save_start_track_tbl:	fcb	$00,$0b,$17		; three save positions
			fcb	$00,$08,$11,$19		; four save positions
save_start_sector_tbl:	fcb	$00,$08,$00		; three save positions
			fcb	$00,$08,$00,$08		; four save positions
	endif


msg_insert_story:
	fcb	char_cr
	text_str	"Insert"
	if	iver==iver2d
	fcb	char_tab
	else
	text_str	" "
	endif
	text_str	"Side "	
Dd833:	text_str	"* of the STORY disk into Drive #1."
	fcb	char_cr
	if	iver>=iver2h
	fcb	char_cr
	fcb	char_cr
	endif
msg_len_insert_story	equ	*-msg_insert_story


Sd856:	lda	#'1'
	sta	Dd833
	lda	#$01
	sta	Ze7
.loop1:	prt_msg	insert_story
	jsr	Sd7f2
	lda	#$00
	sta	rwts_sector
	sta	rwts_track
	lda	#$01
	sta	Z02
	lda	#$00
	jsr	rwts
	bcs	.loop1
	bcc	Ld8ac		; always taken

Sd87e:	lda	#$32
	sta	Dd833
	lda	#$02
	sta	Ze7
	lda	Z02
	pha
	lda	#$01
	sta	Z02
	pla
	cmp	#$02
	beq	Ld8ac
.loop2:	prt_msg	insert_story
	jsr	Sd7f2
	lda	#$00
	sta	rwts_sector
	sta	rwts_track
	lda	#$84
	jsr	rwts
	bcs	.loop2
Ld8ac:	lda	#$ff
	sta	Zd4
	rts


msg_save_position:
	text_str	"Save Position"
	fcb	char_cr
msg_len_save_position	equ	*-msg_save_position

msg_saving_position:
	fcb	char_cr,char_cr
	text_str	"Saving"
	if	iver==iver2d
	fcb	char_tab
	else
	text_str	" "
	endif
	text_str	"position "
Dd8d1:	text_str	"* ..."
	fcb	char_cr
	if	iver>=iver2h
	fcb	char_cr
	fcb	char_cr
	endif
msg_len_saving_position	equ	*-msg_saving_position


op_save:
	jsr	Sd62f
	prt_msg	save_position
	jsr	Sd6d9
	prt_msg	saving_position
	lda	hdr_game_ver
	sta	D1176
	lda	hdr_game_ver+1
	sta	D1176+1
	lda	Zeb
	sta	D1178
	lda	Zeb+1
	sta	D1178+1
	lda	Zed
	sta	D117a
	lda	Zed+1
	sta	D117a+1

	ldx	#$02
.loop1:	lda	pc,x
	sta	D117c,x
	dex
	bpl	.loop1

	lda	#(hdr_arch>>8)-1
	sta	Zb3
	jsr	Sd5df
	bcc	.fwd1

.loop2:	jsr	Sd87e

	if	iver<=iver2d
	jsr	home
	endif

	lda	#$16
	sta	cursrv
	jsr	vtab
	jmp	store_result_zero

.fwd1:	lda	#(hdr_arch>>8)-5
	sta	Zb3
	lda	#$04
	sta	Z73
.loop3:	jsr	Sd5df
	bcs	.loop2
	dec	Z73
	bne	.loop3
	lda	Z81
	sta	Zb3
	ldx	hdr_pure
	inx
	stx	Z6d
.loop4:	jsr	Sd5df
	bcs	.loop2
	dec	Z6d
	bne	.loop4

	jsr	Sd87e

	if	iver<=iver2d
	jsr	home
	endif

	lda	#$16
	sta	cursrv
	jsr	vtab
	lda	Ze4
	sta	Ze2
	lda	Ze5
	sta	Dd67c
	lda	Ze3
	sta	Ze1
	lda	#$01
	ldx	#$00
	jmp	store_result_xa


msg_restore_position:
	text_str	"Restore Position"
	fcb	char_cr
msg_len_restore_position	equ	*-msg_restore_position


msg_restoring_position:
	fcb	char_cr,char_cr
	text_str	"Restoring position "
Dd99d:	text_str	"* ..."
	fcb	char_cr
	if	iver>=iver2h
	fcb	char_cr
	fcb	char_cr
	endif
msg_len_restoring_position	equ	*-msg_restoring_position


op_restore:
	jsr	Sd62f
	prt_msg	restore_position
	jsr	Sd6d9
	prt_msg	restoring_position

	ldx	#$1f
.loop1:	lda	local_vars,x
	sta	D0100,x
	dex
	bpl	.loop1

	lda	#(hdr_arch>>8)-1
	sta	Zb3
	jsr	read_sector
	bcs	.loop2
	lda	D1176
	cmp	hdr_game_ver
	bne	.loop2
	lda	D1176+1
	cmp	hdr_game_ver+1
	beq	.fwd1

.loop2:	ldx	#$1f
.loop3:	lda	D0100,x
	sta	local_vars,x
	dex
	bpl	.loop3
	jsr	Sd87e

	if	iver<=iver2d
	jsr	home
	endif
	lda	#$16
	sta	cursrv
	jsr	vtab
	jmp	store_result_zero

.fwd1:	lda	hdr_flags2
	sta	Z6d
	lda	hdr_flags2+1
	sta	Z6e

	lda	#(hdr_arch>>8)-5
	sta	Zb3
	lda	#$04
	sta	Z73
.loop4:	jsr	read_sector
	bcs	.loop2
	dec	Z73
	bne	.loop4
	lda	Z81
	sta	Zb3
	jsr	read_sector
	bcs	.loop2
	lda	Z6d
	sta	hdr_flags2
	lda	Z6e
	sta	hdr_flags2+1
	lda	hdr_pure
	sta	Z6d
.loop5:	jsr	read_sector
	bcs	.loop2
	dec	Z6d
	bne	.loop5

	lda	D1178
	sta	Zeb
	lda	D1178+1
	sta	Zeb+1

	lda	D117a
	sta	Zed
	lda	D117a+1
	sta	Zed+1

	ldx	#$02
.loop6:	lda	D117c,x
	sta	pc,x
	dex
	bpl	.loop6

	jsr	Sedc1
	jsr	Sd87e

	if	iver<=iver2d
	jsr	home
	endif

	lda	#$16
	sta	cursrv
	jsr	vtab
	lda	Ze4
	sta	Ze2
	lda	Ze5
	sta	Dd67c
	lda	Ze3
	sta	Ze1
	lda	#$02
	ldx	#$00
	jmp	store_result_xa


Sda78:	cld
	txa
	pha
	tya
	pha
.loop1:	jsr	rdkey
	and	#$7f
	cmp	#$0d
	bne	.fwd1
	jmp	.fwd6

.fwd1:	cmp	#$7f
	bne	.fwd2
	jmp	.fwd6

.fwd2:	ldx	#$0a
.loop2:	cmp	Ddad8,x
	beq	.fwd3
	dex
	bpl	.loop2
	bmi	.fwd4
.fwd3:	lda	Ddae3,x
	bne	.fwd6
.fwd4:	cmp	#$20
	bcc	.fwd5

	if	iver<=iver2d
	cmp	#$2b
	beq	.fwd5
	endif

	cmp	#$3c
	bcc	.fwd6
	cmp	#$3f
	beq	.fwd6
	cmp	#$7b
	bcs	.fwd5
	cmp	#$61
	bcs	.fwd6
	cmp	#$41
	bcc	.fwd5
	cmp	#$5b
	bcc	.fwd6
.fwd5:	jsr	Sdd39
	jmp	.loop1
.fwd6:	sta	Zd7
	adc	rndloc
	sta	rndloc
	eor	rndloc+1
	sta	rndloc+1
	pla
	tay
	pla
	tax
	lda	Zd7
	rts


Ddad8:	fcb	$08,$15,$0b,$0a,$3c,$5f,$3e,$40
	fcb	$25
	if	iver<=iver2b
	fcb	$5e,$26
	else
	fcb	$26,$5e
	endif

Ddae3:	fcb	$0b,$07,$0e,$0d,$2c,$2d,$2e,$32
	fcb	$35
	if	iver<=iver2b
	fcb	$36,$37
	else
	fcb	$37,$0e
	endif


Sdaee:	sta	Zd7
	txa
	pha
	tya
	pha
	lda	Zd7
	jsr	cout
	pla
	tay
	pla
	tax
	rts


Sdafe:	jsr	Sf446
	lda	#$00
	sta	Zd0
	sta	Zd1
	ldy	wndtop
	sty	Zd5
	dec	argcnt
	dec	argcnt
	beq	.fwd3
	lda	arg3
	sta	Z6e
	lda	#$00
	sta	Z70
	sta	Z6f
	dec	argcnt
	beq	.fwd1
	lda	arg4
	sta	Z6f
	lda	arg4+1
	sta	Z70
.fwd1:	bit	kbd_strb
.loop1:	lda	Z6e
	sta	Z6d
.loop2:	ldx	#$0a
.loop3:	lda	#$40
	jsr	Sfca8
	dex
	bne	.loop3
	bit	kbd
	bmi	.fwd3
	dec	Z6d
	bne	.loop2
	lda	Z6f
	ora	Z70
	bne	.fwd2
	jmp	.fwd10

.fwd2:	jsr	Sf5f9
	lda	acc
	beq	.loop1
	jmp	.fwd10

.fwd3:	ldy	#$00
.loop4:	jsr	Sda78
	cmp	#$0e
	beq	.fwd7
	cmp	#$07
	beq	.fwd7
	cmp	#$0d
	beq	.fwd8
	cmp	#$7f
	beq	.fwd5
	cmp	#$0b
	beq	.fwd5
	sta	D0200,y
	iny
.loop5:	ldx	invflg
	bpl	.fwd4
	ora	#$80
.fwd4:	jsr	Sdaee

	if	iver==iver2a
	cpy	Zbe
	else
	cpy	#$4d
	endif

	bcc	.loop4
.loop6:	jsr	Sda78
	cmp	#$0d
	beq	.fwd8
	cmp	#$7f
	beq	.fwd5
	cmp	#$0b
	beq	.fwd5
	jsr	Sdd39
	jmp	.loop6

.fwd5:	dey
	bmi	.fwd6
	lda	#$08
	jsr	Sdaee
	lda	#$a0
	jsr	Sdaee
	lda	#$08
	bne	.loop5
.fwd6:	ldy	#$00
.fwd7:	jsr	Sdd39
	jmp	.loop4

.fwd8:	lda	#$8d
	sta	D0200,y
	iny
	sty	Z9f
	sty	Zde
	jsr	Sdaee
.loop7:	lda	D01ff,y
	cmp	#$41
	bcc	.fwd9
	cmp	#$5b
	bcs	.fwd9
	adc	#$20
.fwd9:	and	#$7f
	sta	(Zc3),y
	dey
	bne	.loop7
	jsr	Sdbf3
	lda	Z9f
	rts
.fwd10:	lda	#$00
	rts


; On entry:
;   A:X  message address
;   Y    message length
msg_out:
	stx	.lda+1
	sta	.lda+2
	sty	Z6f
	ldx	#$00
.loop1:
.lda	fcb	$bd,$00,$00	; lda $0000,x	; self-modifying code, MUST be absolute,x
	ldy	invflg
	bpl	.fwd1
	ora	#$80
.fwd1:	jsr	Sdaee
	inx
	dec	Z6f
	bne	.loop1
	rts


Ldbf2:	rts

Sdbf3:	lda	Zd4
	beq	Ldbf2
	lda	ostream_2_state
	beq	Ldbf2
	lda	cswl
	pha
	lda	cswl+1
	pha
	lda	cursrh
	pha
	lda	D057b
	pha
	lda	Ddc35
	sta	cswl
	lda	Ddc36
	sta	cswl+1
	lda	#$00
	sta	cursrh
	sta	D057b
	ldy	#$00
.loop1:	lda	D0200,y
	jsr	cout
	iny
	dec	Zde
	bne	.loop1
	pla
	sta	D057b
	pla
	sta	cursrh
	pla
	sta	cswl+1
	pla
	sta	cswl
	rts


Ddc34:	fcb	$00
Ddc35:	fcb	$00
Ddc36:	fcb	$00


Sdc37:	prt_msg	printer_slot
	lda	#$00
	jsr	Sd64a
	jsr	Sda78
	cmp	#$0d
	beq	.fwd1
	sec
	sbc	#$30
	cmp	#$08
	bcs	Sdc37
	bcc	.fwd2
.fwd1:	lda	#$01
.fwd2:	clc
	adc	#$c0
	sta	Ddc36
	jsr	Sdd17
	inc	Ddc34
	lda	cswl
	pha
	lda	cswl+1
	pha
	lda	Ddc35
	sta	cswl
	lda	Ddc36
	sta	cswl+1
	lda	#$89
	jsr	cout
	lda	#$b8
	jsr	cout
	lda	#$b0
	jsr	cout
	lda	#$ce
	jsr	cout
	lda	cswl
	sta	Ddc35
	lda	cswl+1
	sta	Ddc36
	pla
	sta	cswl+1
	pla
	sta	cswl
	rts


op_split_window:
	lda	hdr_flags_1
	and	#$20
	beq	Ldcd7
	lda	arg1
	beq	Sdcd8
	if	iver==iver2a
	cmp	#$17
	else
	cmp	#$18
	endif
	bcs	Ldcd7
	ldx	Zd9
	beq	.fwd1
	lda	wndtop
	sec
	sbc	arg1
	bcs	.fwd2
.fwd1:	lda	arg1
	if	iver==iver2a
	sta	wndbot
	endif
	sta	Zd9
	if	iver==iver2a
	jsr	home
	endif
.fwd2:	lda	#$18
	sta	wndbot
	lda	arg1
	sta	wndtop
	cmp	Zd5
	bcc	.fwd3
	sta	Zd5
.fwd3:	lda	#$00
	sta	cursrh
	sta	D057b
	lda	#$17
	sta	cursrv
	jsr	vtab
Ldcd7:	rts


Sdcd8:	lda	#$00
	sta	wndtop
	sta	Zd5
	sta	Zd9
	rts


op_set_window:
	lda	hdr_flags_1
	and	#$01
	beq	Ldcd7
	lda	Zd9
	beq	Ldcd7
	lda	arg1
	bne	.fwd1
	lda	#$ff
	sta	Zd4
	lda	#$00
	sta	Zc2

	if	iver<=iver2d
	sta	cursrh
	sta	D057b
	else
	lda	Zd0
	sta	D057b
	sta	cursrh
	endif

	lda	#$17
	sta	cursrv

	if	iver<=iver2d
	bne	.fwd2
	else
	jmp	.fwd2
	endif

.fwd1:	cmp	#$01
	bne	Ldcd7
	sta	Zc2
	lda	#$00
	sta	Zd4
	sta	cursrh
	sta	D057b
	sta	cursrv
.fwd2:	jmp	vtab


Sdd17:	lda	#char_cr+$80
	jmp	cout


op_sound_effect:
	lda	hdr_flags_1
	and	#$20
	beq	.rtn
	ldx	arg1
	dex
	beq	Sdd39
	dex
	bne	.rtn
	ldy	#$ff
.loop1:	lda	#$10
	jsr	Sfca8
	lda	spkr
	dey
	bne	.loop1
.rtn:	rts


Sdd39:	jmp	bell


Sdd3c:	lda	#$00
	sta	Zf7
.loop1:	ldy	#$00
.loop2:	sta	D1000,y
	iny
	bne	.loop2
	inc	Zf7
	lda	Zf7
	sta	wr_card_ram
.loop3:	sta	D1000,y
	iny
	bne	.loop3
	sta	wr_main_ram
	dec	Zf7
.loop4:	lda	D1000,y
	cmp	Zf7
	bne	.fwd1
	iny
	bne	.loop4
	inc	Zf7
	sta	rd_card_ram
.loop5:	lda	D1000,y
	cmp	Zf7
	bne	.fwd1
	iny
	bne	.loop5
	sta	rd_main_ram
	lda	Zf7
	bne	.loop1
	clc
	rts
.fwd1:	sta	rd_main_ram
	sec
	rts


romid2_save:	fcb	$00
Ddd82:	fcb	$00
Ddd83:	fcb	$00


; interpreter startup entry point jumped from boot1
interp_start:
	lda	Z2b
	sta	Z00
	sta	Z01

	if	iver>=iver2b
	lda	#cout1>>8
	sta	cswl+1
	lda	#cout1&$ff
	sta	cswl
	endif

	ldx	#$00
	stx	rwts_sector
	stx	Zb2

	inx			; read rest of interpreter starting with track 1
	stx	rwts_track

	stx	Z02
	stx	Z03

	lda	#$df		; starting at $df00
	sta	Zb3

	lda	#25		; sector count
	sta	Z6d

.loop1:	jsr	read_sector
	dec	Z6d
	bne	.loop1

	lda	#$ff
	sta	invflg

	lda	romid
	cmp	#$06		; is the computer an Apple IIe or later?
	beq	.fwd1		; yes
	jmp	computer_inadequate

.fwd1:	lda	romid2
	sta	romid2_save
	beq	.fwd2
	jsr	Sdd3c
	bcs	computer_inadequate
.fwd2:	jsr	sl3fw

restart:	lda	Z01
	ldx	Z03
	sta	Ddd82
	stx	Ddd83
	jsr	home
	lda	#$0a
	sta	cursrv
	lda	#$1b
	sta	cursrh
	sta	D057b
	jsr	vtab
	prt_msg_alt	story_loading

	lda	#$00		; clear interp zero page vars
	ldx	#interp_zp_origin
.loop2:	sta	Z00,x
	inx
	bne	.loop2

	inc	Zeb
	inc	Zed
	inc	Zd4
	inc	ostream_1_state
	inc	Ze7

	lda	#hdr_arch>>8
	sta	Z81
	sta	Zb3

	lda	#$00
	sta	Ded07
	jsr	Sd51d

	lda	hdr_arch	; check header architecture version version
	cmp	#$04
	beq	Lde21

	lda	#$0f
	jmp	int_error

computer_inadequate:
	lda	#$05
	sta	cursrv
	jsr	vtab
	lda	#$00
	jmp	int_error

Lde21:
	if	iver>=iver2b
	lda	hdr_pure	; heck header size of impure memory
	cmp	#$ad
	bcc	.fwd1a

	lda	#$0d
	jmp	int_error

.fwd1a:	cmp	#$80
	bcc	.fwd1b
	lda	#$03
	bne	.fwd1c
.fwd1b:	lda	#$04
.fwd1c:	sta	max_save_position
	clc
	adc	#$30
	sta	msg_position_max_ascii
	endif

	ldx	hdr_high_mem	; base of high memory
	inx
	stx	Z82
	lda	hdr_flags_1
	ora	#$33
	sta	hdr_flags_1

	lda	#iver>>8	; set interpreter number
	sta	hdr_interp_ver
	lda	#$40+(iver&$ff)	; set interpreter version
	sta	hdr_interp_rev

	lda	#24		; set screen dimensiosn
	sta	hdr_scr_height
	lda	#80
	sta	hdr_scr_width

	lda	hdr_globals
	clc
	adc	Z81
	sta	Z84
	lda	hdr_globals+1
	sta	Z83

	lda	hdr_abbrev
	clc
	adc	Z81
	sta	Z88
	lda	hdr_abbrev+1
	sta	Z87

	lda	hdr_object
	clc
	adc	Z81
	sta	Z8a
	lda	hdr_object+1
	sta	Z89

	jsr	Seeef
	jsr	home

	lda	hdr_init_pc
	sta	pc+1
	lda	hdr_init_pc+1
	sta	pc

	jsr	Sedc1
	ldx	wndwdt
	dex
	stx	Zbf
	lda	Ddc34
	bpl	.fwd3
	lda	#$01
	sta	Ddc34
	sta	ostream_2_state
	ora	hdr_flags2+1
	sta	hdr_flags2+1
.fwd3:	jsr	home
; fall into main loop

main_loop:
	lda	#$00
	sta	argcnt
	ldy	Z7a
	sta	rd_main_ram,y	; indexed to get main or card
	ldy	pc
	lda	(Z78),y
	sta	rd_main_ram
	inc	pc
	bne	.fwd4
	jsr	Sef2f
.fwd4:	tay
	sta	opcode
	bmi	op_80_ff
	jmp	op_00_7f

op_80_ff:
	cmp	#$b0
	bcs	op_b0_ff
	jmp	op_80_af

op_b0_ff:
	cmp	#$c0
	bcs	op_c0_ff
	jmp	op_b0_bf

; opcode $c0..$ff: VAR format
op_c0_ff:
	cmp	#$ec		; is it call_vs2 (up to 8 args)?
	beq	op_ec		;   yes

	jsr	Sef50
	sta	Z68
	ldx	#$00
	stx	Z6a
	beq	.fwd1		; always taken

.loop1:	lda	Z68
	asl
	asl
	sta	Z68
.fwd1:	and	#$c0
	bne	.fwd2
	jsr	Se075
	jmp	.fwd4

.fwd2:	cmp	#$40
	bne	.fwd3
	jsr	Se071
	jmp	.fwd4

.fwd3:	cmp	#$80
	bne	Ldf08
	jsr	Se089
.fwd4:	ldx	Z6a
	lda	acc
	sta	arg1,x
	lda	acc+1
	sta	arg1+1,x
	inc	argcnt
	inx
	inx
	stx	Z6a
	cpx	#$08
	bcc	.loop1
Ldf08:	lda	opcode
	cmp	#$e0
	bcs	Ldf11
	jmp	Le04a

Ldf11:	and	#$1f
	tay
	lda	tab_var_lo,y
	sta	Ldf20+1
	lda	tab_var_hi,y
	sta	Ldf20+2
Ldf20	jsr	$ffff		; self-modifying code
	jmp	main_loop


int_err_01:
	lda	#$01
	jmp	int_error


; call_vf2, up to eight args
op_ec:	jsr	Sef50
	sta	Z68
	jsr	Sef50
	sta	Z69
	lda	Z68
	ldx	#$00
	stx	Z6a
	beq	.loop2
.loop1:	lda	Z68
	asl
	asl
	sta	Z68
.loop2:	and	#$c0
	bne	.fwd1
	jsr	Se075
	jmp	.fwd3

.fwd1:	cmp	#$40
	bne	.fwd2
	jsr	Se071
	jmp	.fwd3

.fwd2:	cmp	#$80
	bne	Ldf08
	jsr	Se089

.fwd3:	ldx	Z6a
	lda	acc
	sta	arg1,x
	lda	acc+1
	sta	arg1+1,x
	inc	argcnt
	inx
	inx
	stx	Z6a
	cpx	#$10
	beq	Ldf08
	cpx	#$08
	bne	.loop1
	lda	Z69
	sta	Z68
	jmp	.loop2


; 0OP instructions (opcodes $b0..$bf)
op_b0_bf:
	and	#$0f
	tay
	lda	tab_0op_lo,y
	sta	.jsr+1
	lda	tab_0op_hi,y
	sta	.jsr+2
.jsr:	jsr	$ffff		; self-modifying code
	jmp	main_loop


int_err_02:
	lda	#$02
	jmp	int_error


op_80_af:
	and	#$30
	bne	.fwd2
	ldy	Z7a
	sta	rd_main_ram,y	; indexed to get main or card
	ldy	pc
	lda	(Z78),y
	sta	rd_main_ram
	inc	pc
	bne	.fwd1
	jsr	Sef2f
.fwd1:	tay
	jmp	.fwd3

.fwd2:	and	#$20
	bne	.fwd5
.fwd3:	sta	arg1+1
	ldy	Z7a
	sta	rd_main_ram,y	; indexed to get main or card
	ldy	pc
	lda	(Z78),y
	sta	rd_main_ram
	inc	pc
	bne	.fwd4
	jsr	Sef2f
.fwd4:	tay
	sta	arg1
	inc	argcnt
	jmp	.fwd6

.fwd5:	jsr	Se089
	jsr	Se066
.fwd6:	lda	opcode
	and	#$0f
	tay
	lda	tab_1op_lo,y
	sta	Ldfea+1
	lda	tab_1op_hi,y
	sta	Ldfea+2
Ldfea:	jsr	$ffff		; self-modifying code
	jmp	main_loop


; unreferenced - was used in e.g. ZIP interpreter F
int_err_03:
	lda	#$03
	jmp	int_error


; opcodes $00..$7f
op_00_7f:
	and	#$40
	bne	op_40_7f
	sta	arg1+1
	ldy	Z7a
	sta	rd_main_ram,y	; indexed to get main or card
	ldy	pc
	lda	(Z78),y
	sta	rd_main_ram
	inc	pc
	bne	.fwd1
	jsr	Sef2f
.fwd1:	tay
	sta	arg1
	inc	argcnt
	jmp	Le01c


; opcodes $40..$7f
op_40_7f:
	jsr	Se089
	jsr	Se066
Le01c:	lda	opcode
	and	#$20
	bne	.fwd2
	sta	arg2+1
	ldy	Z7a
	sta	rd_main_ram,y	; indexed to get main or card
	ldy	pc
	lda	(Z78),y
	sta	rd_main_ram
	inc	pc
	bne	.fwd1
	jsr	Sef2f
.fwd1:	tay
	sta	arg2
	jmp	.fwd3

.fwd2:	jsr	Se089
	lda	acc
	sta	arg2
	lda	acc+1
	sta	arg2+1
.fwd3:	inc	argcnt
Le04a:	lda	opcode
	and	#$1f
	tay
	lda	tab_2op_lo,y
	sta	.jsr+1
	lda	tab_2op_hi,y
	sta	.jsr+2
.jsr:	jsr	$ffff		; self-modifying code
	jmp	main_loop


int_err_04:
	lda	#$04
	jmp	int_error


Se066:	lda	acc
	sta	arg1
	lda	acc+1
	sta	arg1+1
	inc	argcnt
	rts


Se071:	lda	#$00
	beq	Le078		; always taken

Se075:	jsr	Sef50
Le078:	sta	acc+1
	jsr	Sef50
	sta	acc
	rts


Se080:	tax
	bne	Le08e
	jsr	op_pop
	jmp	push_acc

Se089:	jsr	Sef50
	beq	op_pop
Le08e:	cmp	#$10
	bcs	Le09f
	asl
	tax
	lda	local_vars-2,x
	sta	acc
	lda	local_vars-1,x
	sta	acc+1
	rts

Le09f:	jsr	Se14b
	lda	(Z6d),y
	sta	acc+1
	iny
	lda	(Z6d),y
	sta	acc
	rts


op_pop:	lda	Zeb
	bne	.fwd1
	sta	Zeb+1
.fwd1:	dec	Zeb
	bne	.fwd2
	ora	Zeb+1
	beq	int_err_05	; data stack underflow
.fwd2:	ldy	Zeb
	lda	Zeb+1
	beq	.fwd3
	lda	D0e56,y
	sta	acc
	tax
	lda	D1056,y
	sta	acc+1
	rts

.fwd3:	lda	D0d56,y
	sta	acc
	tax
	lda	D0f56,y
	sta	acc+1
	rts


int_err_05:
	lda	#$05
	jmp	int_error


push_acc:
	ldx	acc
	lda	acc+1

; push word in A:X onto data stack
push_ax:
	pha
	ldy	Zeb
	lda	Zeb+1
	beq	.fwd1

	if	iver==iver2a
	tax			; wrong! how did this ever work at all?
	else
	txa
	endif
	sta	D0e56,y
	pla
	sta	D1056,y
	jmp	.fwd2

.fwd1:	txa
	sta	D0d56,y
	pla
	sta	D0f56,y
.fwd2:	inc	Zeb
	bne	.fwd3
	lda	Zeb
	ora	Zeb+1
	bne	int_err_06	; data stack overflow
	inc	Zeb+1
.fwd3:	rts


int_err_06:
	lda	#$06
	jmp	int_error


Le10d:	tax
	bne	Le12d
	lda	Zeb
	bne	.fwd1
	sta	Zeb+1
.fwd1:	dec	Zeb
	bne	push_acc
	ora	Zeb+1
	beq	int_err_05
	bne	push_acc	; always taken


; store a zero result into variable (or stack) designated by next byte of program
store_result_zero:
	lda	#$00
	ldx	#$00

; store result in X:A into acc and variable (or stack) designated by next byte of program
store_result_xa:
	sta	acc
	stx	acc+1

; store result in acc into variable (or stack) designated by next byte of program
store_result:
	jsr	Sef50
	beq	push_acc
Le12d:	cmp	#$10
	bcs	.fwd2

; store result in acc into local variable specified by A
	asl
	tax
	lda	acc
	sta	local_vars-2,x
	lda	acc+1
	sta	local_vars-1,x
	rts

; store result in acc into global variable specified by A (offset by $10)
.fwd2:	jsr	Se14b
	lda	acc+1
	sta	(Z6d),y
	iny
	lda	acc
	sta	(Z6d),y
	rts


Se14b:	sec
	sbc	#$10
	ldy	#$00
	sty	Z6e
	asl
	rol	Z6e
	clc
	adc	Z83
	sta	Z6d
	lda	Z6e
	adc	Z84
	sta	Z6e
Le160:	rts


predicate_false:
	jsr	Sef50
	bpl	Le172
Le166:	and	#$40
	bne	Le160
	jmp	Sef50


predicate_true:
	jsr	Sef50
	bpl	Le166
Le172:	tax
	and	#$40
	beq	.fwd1
	txa
	and	#$3f
	sta	acc
	lda	#$00
	sta	acc+1
	beq	.fwd3		; always taken

.fwd1:	txa
	and	#$3f
	tax
	and	#$20
	beq	.fwd2
	txa
	ora	#$e0
	tax
.fwd2:	stx	acc+1
	jsr	Sef50
	sta	acc
	lda	acc+1
	bne	Le1a7
.fwd3:	lda	acc
	bne	.fwd4
	jmp	op_rfalse

.fwd4:	cmp	#$01
	bne	Le1a7
	jmp	op_rtrue

Le1a7:	lda	acc
	sec
	sbc	#$02
	tax
	lda	acc+1
	sbc	#$00
	sta	Z6d
	ldy	#$00
	sty	Z6e
	asl
	rol	Z6e
	asl
	rol	Z6e
	txa
	adc	pc
	bcc	.fwd5
	inc	Z6d
	bne	.fwd5
	inc	Z6e
.fwd5:	sta	pc
	lda	Z6d
	ora	Z6e
	beq	op_nop
	lda	Z6d
	clc
	adc	pc+1
	sta	pc+1
	lda	Z6e
	adc	pc+2
	and	#$03
	sta	pc+2
	jmp	Sedc1


op_nop:	rts


Se1e3:	lda	arg1
	sta	acc
	lda	arg1+1
	sta	acc+1
	rts


; unreferenced - see S1b1d in ZIP revision F
Le1ec:	lda	hdr_flags2+1
	ora	#$04
	sta	hdr_flags2+1
	rts


; 0OP instructions (no operands), opcodes $b0..$bf
	optab_start	tab_0op,16
	optab_ent	op_rtrue
	optab_ent	op_rfalse
	optab_ent	op_print	; (literal string)
	optab_ent	op_print_ret	; (literal string)
	optab_ent	op_nop
	optab_ent	op_save
	optab_ent	op_restore
	optab_ent	op_restart
	optab_ent	op_ret_popped
	optab_ent	op_pop
	optab_ent	op_quit
	optab_ent	op_new_line
	optab_ent	op_show_status	; [nop, some games might mistakenly use]
	optab_ent	op_verify
	optab_ent	int_err_02	; [illegal]
	optab_ent	int_err_02	; [illegal]


; 1OP instructions (one operand), opcodes $80..$af
	optab_start	tab_1op,16
	optab_ent	op_jz
	optab_ent	op_get_sibling
	optab_ent	op_get_child
	optab_ent	op_get_parent
	optab_ent	op_get_prop_len	; get length of property (given addr)
	optab_ent	op_inc
	optab_ent	op_dec
	optab_ent	op_print_addr
	optab_ent	op_call		; call_1s
	optab_ent	op_remove_obj
	optab_ent	op_print_obj
	optab_ent	op_ret		; with value
	optab_ent	op_jump
	optab_ent	op_print_paddr
	optab_ent	op_load
	optab_ent	op_not


; 2OP instructions (two operand), opcodes $20..$7f
; The 2OP table is also used for VAR instructions (0-4 or 0-8 operands), opcodes $c0..$df
	optab_start	tab_2op,32
	optab_ent	int_err_04	; [illegal]
	optab_ent	op_je
	optab_ent	op_jl
	optab_ent	op_jg
	optab_ent	op_dec_chk
	optab_ent	op_inc_chk
	optab_ent	op_jin		; jump if object a is direct child of object b
	optab_ent	op_test		; (bitmap)
	optab_ent	op_or
	optab_ent	op_and
	optab_ent	op_test_attr
	optab_ent	op_set_attr
	optab_ent	op_clear_attr
	optab_ent	op_store
	optab_ent	op_insert_obj
	optab_ent	op_loadw
	optab_ent	op_loadb
	optab_ent	op_get_prop
	optab_ent	op_get_prop_addr
	optab_ent	op_get_next_prop
	optab_ent	op_add
	optab_ent	op_sub
	optab_ent	op_mul
	optab_ent	op_div
	optab_ent	op_mod
	optab_ent	op_call		; call_2s
	optab_ent	int_err_04
	optab_ent	int_err_04
	optab_ent	int_err_04
	optab_ent	int_err_04
	optab_ent	int_err_04
	optab_ent	int_err_04

; VAR instructions (0-4 operands, 0-8 for call_vs2 and call_vn2), opcodes $e0..$ff
	optab_start	tab_var,32
	optab_ent	op_call		; call_vs (call in Z-Machine v3 and earlier)
	optab_ent	op_storew
	optab_ent	op_storeb
	optab_ent	op_put_prop
	optab_ent	op_sread
	optab_ent	op_print_char
	optab_ent	op_print_num
	optab_ent	op_random
	optab_ent	op_push
	optab_ent	op_pull
	optab_ent	op_split_window
	optab_ent	op_set_window
	optab_ent	op_call		; call_vs2
	optab_ent	op_erase_window
	optab_ent	op_erase_line
	optab_ent	op_set_cursor
	optab_ent	op_get_cursor	; [nop]
	optab_ent	op_set_text_state
	optab_ent	op_buffer_mode
	optab_ent	op_output_stream
	optab_ent	op_input_stream	; [nop[
	optab_ent	op_sound_effect
	optab_ent	op_read_char
	optab_ent	op_scan_table
	optab_ent	int_err_01
	optab_ent	int_err_01
	optab_ent	int_err_01
	optab_ent	int_err_01
	optab_ent	int_err_01
	optab_ent	int_err_01
	optab_ent	int_err_01
	optab_ent	int_err_01


op_rtrue:
	ldx	#$01
Le2b7:	lda	#$00
Le2b9:	stx	arg1
	sta	arg1+1
	jmp	op_ret

op_rfalse:
	ldx	#$00
	beq	Le2b7


op_print:
	ldx	#$05
.loop1:	lda	pc,x
	sta	Z7b,x
	dex
	bpl	.loop1
	jsr	Sef7e
	ldx	#$05
.loop2:	lda	Z7b,x
	sta	pc,x
	dex
	bpl	.loop2
	rts


op_print_ret:
	jsr	op_print
	jsr	op_new_line
	jmp	op_rtrue


op_ret_popped:
	jsr	op_pop
	jmp	Le2b9


op_verify:
	jsr	op_new_line
	ldx	#$03
	lda	#$00
	if	iver>=iver2b
	sta	Zd7
	endif
.loop1:	sta	Z71,x
	sta	Z7b,x
	dex
	bpl	.loop1
	lda	#$40
	sta	Z7b
	lda	hdr_length
	sta	Z6e
	lda	hdr_length+1
	asl
	rol	Z6e
	rol	Z71
	asl
	sta	Z6d
	rol	Z6e
	rol	Z71
	lda	#$00
	sta	disk_block_num
	sta	disk_block_num+1
	jmp	.fwd1

.loop2:	lda	Z7b
	bne	.fwd2
.fwd1:	lda	#$09
	sta	Zb3
	lda	#$00
	sta	Ded07
	jsr	Sd51d

	if	iver>=iver2b
 	lda	Zd7
 	bne	.fwd2
 	lda	Ze7
 	cmp	#$02
 	bne	.fwd2
	prt_msg_alt	be_patient
 	inc	Zd7
	endif

.fwd2:	ldy	Z7b
	lda	rwts_data_buf,y
	inc	Z7b
	bne	.fwd3
	inc	Z7c
	bne	.fwd3
	inc	Z7d
.fwd3:	clc
	adc	Z73
	sta	Z73
	bcc	.fwd4
	inc	Z74
.fwd4:	lda	Z7b
	cmp	Z6d
	bne	.loop2
	lda	Z7c
	cmp	Z6e
	bne	.loop2
	lda	Z7d
	cmp	Z71
	bne	.loop2
	lda	hdr_checksum+1
	cmp	Z73
	bne	.fwd5
	lda	hdr_checksum
	cmp	Z74
	bne	.fwd5
	jmp	predicate_true

.fwd5:	jmp	predicate_false

	if	iver>=iver2b
msg_be_patient:
	fcb	char_cr
	text_str	"Please be patient, this takes a while"
	fcb	char_cr
msg_len_be_patient	equ	*-msg_be_patient
	endif


op_jz:	lda	arg1
	ora	arg1+1
	beq	Le394
Le36c:	jmp	predicate_false


op_get_sibling:
	lda	arg1
	ldx	arg1+1
	jsr	setup_object
	ldy	#$08
	bne	Le383		; always taken


op_get_child:
	lda	arg1
	ldx	arg1+1
	jsr	setup_object
	ldy	#$0a
Le383:	lda	(Z6d),y
	tax
	iny
	lda	(Z6d),y
	jsr	store_result_xa
	lda	acc
	bne	Le394
	lda	acc+1
	beq	Le36c
Le394:	jmp	predicate_true


op_get_parent:
	lda	arg1
	ldx	arg1+1
	jsr	setup_object
	ldy	#$06
	lda	(Z6d),y
	tax
	iny
	lda	(Z6d),y
	jmp	store_result_xa


op_get_prop_len:
	lda	arg1+1
	clc
	adc	Z81
	sta	Z6e
	lda	arg1
	sec
	sbc	#$01
	sta	Z6d
	bcs	.fwd1
	dec	Z6e
.fwd1:	ldy	#$00
	lda	(Z6d),y
	bmi	.fwd3
	and	#$40
	beq	.fwd2
	lda	#$02
	bne	.fwd4
.fwd2:	lda	#$01
	bne	.fwd4
.fwd3:	and	#$3f
.fwd4:	ldx	#$00
	jmp	store_result_xa


op_inc:	lda	arg1
	jsr	Se080
	inc	acc
	bne	.fwd1
	inc	acc+1
.fwd1:	jmp	Le3f4


op_dec:	lda	arg1
	jsr	Se080
	lda	acc
	sec
	sbc	#$01
	sta	acc
	lda	acc+1
	sbc	#$00
	sta	acc+1
Le3f4:	lda	arg1
	jmp	Le10d


op_print_addr:
	lda	arg1
	sta	Z6d
	lda	arg1+1
	sta	Z6e
	jsr	Secf8
	jmp	Sef7e


op_remove_obj:
	lda	arg1
	ldx	arg1+1
	jsr	setup_object
	lda	Z6d
	sta	Z6f
	lda	Z6e
	sta	Z70
	ldy	#$07
	lda	(Z6d),y
	sta	Z71
	dey
	lda	(Z6d),y
	tax
	lda	Z71
	ora	(Z6d),y
	beq	.rtn
	lda	Z71
	jsr	setup_object
	ldy	#$0a
	lda	(Z6d),y
	tax
	iny
	lda	(Z6d),y
	cmp	arg1
	bne	.loop1
	cpx	arg1+1
	bne	.loop1
	ldy	#$08
	lda	(Z6f),y
	iny
	iny
	sta	(Z6d),y
	dey
	lda	(Z6f),y
	iny
	iny
	sta	(Z6d),y
	bne	.fwd1
.loop1:	jsr	setup_object
	ldy	#$08
	lda	(Z6d),y
	tax
	iny
	lda	(Z6d),y
	cmp	arg1
	bne	.loop1
	cpx	arg1+1
	bne	.loop1
	ldy	#$08
	lda	(Z6f),y
	sta	(Z6d),y
	iny
	lda	(Z6f),y
	sta	(Z6d),y
.fwd1:	lda	#$00
	ldy	#$06
	sta	(Z6f),y
	iny
	sta	(Z6f),y
	iny
	sta	(Z6f),y
	iny
	sta	(Z6f),y
.rtn:	rts


op_print_obj:
	lda	arg1
	ldx	arg1+1
	jsr	setup_object
	ldy	#$0c
	lda	(Z6d),y
	tax
	iny
	lda	(Z6d),y
	sta	Z6d
	stx	Z6e
	inc	Z6d
	bne	.fwd1
	inc	Z6e
.fwd1:	jsr	Secf8
	jmp	Sef7e


op_ret:	lda	Zed
	sta	Zeb
	lda	Zed+1
	sta	Zeb+1
	jsr	op_pop
	stx	Z6e
	txa
	beq	.fwd1
	dex
	txa
	asl
	sta	Z6d

.loop1:	jsr	op_pop
	ldy	Z6d
	sta	local_vars+1,y
	txa
	sta	local_vars,y
	dec	Z6d
	dec	Z6d
	dec	Z6e
	bne	.loop1

.fwd1:	jsr	op_pop
	stx	pc+1
	sta	pc+2
	jsr	op_pop
	sta	pc
	jsr	op_pop
	stx	Zed
	sta	Zed+1
	jsr	Sedc1
	jsr	Se1e3
Le4db:	jmp	store_result	; self-modifying code - jmp target changed by code at Sf5f9 and Lf67c


op_jump:
	jsr	Se1e3
	jmp	Le1a7


op_print_paddr:
	lda	arg1
	sta	Z6d
	lda	arg1+1
	sta	Z6e
	jsr	Sef65
	jmp	Sef7e


op_load:
	lda	arg1
	jsr	Se080
	jmp	store_result


op_not:	lda	arg1
	eor	#$ff
	tax
	lda	arg1+1
	eor	#$ff
; fall into store_result_ax

; store result in A:X into variable (or stack) designated by next byte of program
store_result_ax:
	stx	acc
	sta	acc+1
	jmp	store_result


op_jl:	jsr	Se1e3
	jmp	Le513


op_dec_chk:
	jsr	op_dec
Le513:	lda	arg2
	sta	Z6d
	lda	arg2+1
	sta	Z6e
	jmp	Le53c


op_jg:	lda	arg1
	sta	Z6d
	lda	arg1+1
	sta	Z6e
	jmp	Le534


op_inc_chk:
	jsr	op_inc
	lda	acc
	sta	Z6d
	lda	acc+1
	sta	Z6e
Le534:	lda	arg2
	sta	acc
	lda	arg2+1
	sta	acc+1
Le53c:	lda	Z6e
	eor	acc+1
	bpl	.fwd1
	lda	Z6e
	cmp	acc+1
	bcc	Le583
	jmp	predicate_false

.fwd1:	lda	acc+1
	cmp	Z6e
	bne	.fwd2
	lda	acc
	cmp	Z6d
.fwd2:	bcc	Le583
	jmp	predicate_false


; is object ARG1 in object ARG2?
op_jin:	lda	arg1
	ldx	arg1+1
	jsr	setup_object
	ldy	#$06
	lda	(Z6d),y
	cmp	arg2+1
	bne	Le570
	iny
	lda	(Z6d),y
	cmp	arg2
	beq	Le583
Le570:	jmp	predicate_false


op_test:
	lda	arg2
	and	arg1
	cmp	arg2
	bne	Le570
	lda	arg2+1
	and	arg1+1
	cmp	arg2+1
	bne	Le570
Le583:	jmp	predicate_true

op_or:	lda	arg1
	ora	arg2
	tax
	lda	arg1+1
	ora	arg2+1
	jmp	store_result_ax


op_and:	lda	arg1
	and	arg2
	tax
	lda	arg1+1
	and	arg2+1
	jmp	store_result_ax


op_test_attr:
	jsr	setup_attribute
	lda	Z72
	and	Z70
	sta	Z72
	lda	Z71
	and	Z6f
	ora	Z72
	bne	Le583
	jmp	predicate_false


op_set_attr:
	jsr	setup_attribute
	ldy	#$00
	lda	Z72
	ora	Z70
	sta	(Z6d),y
	iny
	lda	Z71
	ora	Z6f
	sta	(Z6d),y
	rts


op_clear_attr:
	jsr	setup_attribute
	ldy	#$00
	lda	Z70
	eor	#$ff
	and	Z72
	sta	(Z6d),y
	iny
	lda	Z6f
	eor	#$ff
	and	Z71
	sta	(Z6d),y
	rts


op_store:
	lda	arg2
	sta	acc
	lda	arg2+1
	sta	acc+1
	lda	arg1
	jmp	Le10d


op_insert_obj:
	jsr	op_remove_obj
	lda	arg1
	ldx	arg1+1
	jsr	setup_object
	lda	Z6d
	sta	Z6f
	lda	Z6e
	sta	Z70
	lda	arg2+1
	ldy	#$06
	sta	(Z6d),y
	tax
	lda	arg2
	iny
	sta	(Z6d),y
	jsr	setup_object
	ldy	#$0a
	lda	(Z6d),y
	sta	Z72
	lda	arg1+1
	sta	(Z6d),y
	iny
	lda	(Z6d),y
	tax
	lda	arg1
	sta	(Z6d),y
	txa
	ora	Z72
	beq	.rtn
	txa
	ldy	#$09
	sta	(Z6f),y
	dey
	lda	Z72
	sta	(Z6f),y
.rtn:	rts


op_loadw:
	jsr	Se643
	jsr	Sef3b
Le632:	sta	acc+1
	jsr	Sef3b
	sta	acc
	jmp	store_result


op_loadb:
	jsr	Se647
	lda	#$00
	beq	Le632


Se643:	asl	arg2
	rol	arg2+1

Se647:	lda	arg2
	clc
	adc	arg1
	sta	Z7b
	lda	arg2+1
	adc	arg1+1
	sta	Z7c
	lda	#$00
	adc	#$00
	sta	Z7d
	jmp	Sed80


op_get_prop:
	jsr	Sf1e3
.loop1:	jsr	Sf201
	cmp	arg2
	beq	.fwd2
	bcc	.fwd1
	jsr	Sf230
	jmp	.loop1

.fwd1:	lda	arg2
	sec
	sbc	#$01
	asl
	tay
	lda	(Z89),y
	sta	acc+1
	iny
	lda	(Z89),y
	sta	acc
	jmp	store_result

.fwd2:	jsr	Sf206
	iny
	cmp	#$01
	beq	.fwd3
	cmp	#$02
	beq	.fwd4

	lda	#$07
	jmp	int_error

.fwd3:	lda	(Z6d),y
	ldx	#$00
	beq	.fwd5		; always taken

.fwd4:	lda	(Z6d),y
	tax
	iny
	lda	(Z6d),y
.fwd5:	sta	acc
	stx	acc+1
	jmp	store_result


op_get_prop_addr:
	if	iver==iver2a

	jsr	Sf1e3
.loop1:	jsr	Sf201
	cmp	arg2
	beq	.fwd1
	bcc	Le6ce
	jsr	Sf230
	jmp	.loop1

.fwd1:	jsr	Sf206

	else

	lda	arg1
	ldx	arg1+1
	jsr	setup_object
	ldy	#$0c
	lda	(Z6d),Y
	clc
	adc	Z81
	tax
	iny
	lda	(Z6d),Y
	sta	Z6d
	stx	Z6e
	ldy	#$00
	lda	(Z6d),Y
	asl
	tay
	iny
.loop2b:
	lda	(Z6d),Y
	and	#$3f
	cmp	arg2
	beq	.fwd8b
	bcs	.fwd2b
	jmp	Le6ce

.fwd2b:	lda	(Z6d),Y
	and	#$80
	beq	.fwd3b
	iny
	lda	(Z6d),Y
	and	#$3f
	jmp	.fwd5b

.fwd3b:	lda	(Z6d),Y
	and	#$40
	beq	.fwd4b
	lda	#$02
	jmp	.fwd5b

.fwd4b:	lda	#$01
.fwd5b:	tax
.loop3b:
	iny
	bne	.fwd6b
	inc	Z6e
.fwd6b:	dex
	bne	.loop3b
	iny
	tya
	clc
	adc	Z6d
	sta	Z6d
	bcc	.fwd7b
	inc	Z6e
.fwd7b:	ldy	#$00
	jmp	.loop2b
.fwd8b:	lda	(Z6d),Y
	and	#$80
	beq	.fwd9b
	iny
	lda	(Z6d),Y
	and	#$3f
	jmp	.fwd11b
.fwd9b:	lda	(Z6d),Y
	and	#$40
	beq	.fwd10b
	lda	#$02
	jmp	.fwd11b

.fwd10b:
	lda	#$01
.fwd11b:

	endif

	iny
	tya
	clc
	adc	Z6d
	sta	acc
	lda	Z6e
	adc	#$00
	sec
	sbc	Z81
	sta	acc+1
	jmp	store_result

Le6ce:	jmp	store_result_zero


op_get_next_prop:
	jsr	Sf1e3
	lda	arg2
	beq	.fwd2
.loop1:	jsr	Sf201
	cmp	arg2
	beq	.fwd1
	bcc	Le6ce
	jsr	Sf230
	jmp	.loop1

.fwd1:	jsr	Sf21e
.fwd2:	jsr	Sf201
	ldx	#$00
	jmp	store_result_xa


op_add:
	lda	arg1
	clc
	adc	arg2
	tax
	lda	arg1+1
	adc	arg2+1
	jmp	store_result_ax


op_sub:
	lda	arg1
	sec
	sbc	arg2
	tax
	lda	arg1+1
	sbc	arg2+1
	jmp	store_result_ax


op_mul:	jsr	Se7c6
.loop1:	ror	Zcc
	ror	Zcb
	ror	arg2+1
	ror	arg2
	bcc	.fwd1
	lda	arg1
	clc
	adc	Zcb
	sta	Zcb
	lda	arg1+1
	adc	Zcc
	sta	Zcc
.fwd1:	dex
	bpl	.loop1
	ldx	arg2
	lda	arg2+1
	jmp	store_result_ax


op_div:
	jsr	divide
	ldx	Zc7
	lda	Zc8
	jmp	store_result_ax


op_mod:
	jsr	divide
	ldx	Zc9
	lda	Zca
	jmp	store_result_ax


divide:	lda	arg1+1
	sta	Zce
	eor	arg2+1
	sta	Zcd
	lda	arg1
	sta	Zc7
	lda	arg1+1
	sta	Zc8
	bpl	.fwd1
	jsr	Se782
.fwd1:	lda	arg2
	sta	Zc9
	lda	arg2+1
	sta	Zca
	bpl	.fwd2
	jsr	Se774
.fwd2:	jsr	Se790
	lda	Zcd
	bpl	.fwd3
	jsr	Se782
.fwd3:	lda	Zce
	bpl	Le781

Se774:	lda	#$00
	sec
	sbc	Zc9
	sta	Zc9
	lda	#$00
	sbc	Zca
	sta	Zca
Le781:	rts


Se782:	lda	#$00
	sec
	sbc	Zc7
	sta	Zc7
	lda	#$00
	sbc	Zc8
	sta	Zc8
	rts


Se790:	lda	Zc9
	ora	Zca
	beq	int_err_08
	jsr	Se7c6
.loop1:	rol	Zc7
	rol	Zc8
	rol	Zcb
	rol	Zcc
	lda	Zcb
	sec
	sbc	Zc9
	tay
	lda	Zcc
	sbc	Zca
	bcc	.fwd1
	sty	Zcb
	sta	Zcc
.fwd1:	dex
	bne	.loop1
	rol	Zc7
	rol	Zc8
	lda	Zcb
	sta	Zc9
	lda	Zcc
	sta	Zca
	rts


int_err_08:
	lda	#$08
	jmp	int_error


Se7c6:	ldx	#$10
	lda	#$00
	sta	Zcb
	sta	Zcc
	clc
	rts


op_je:	dec	argcnt
	bne	.fwd1
	lda	#$09
	jmp	int_error

.fwd1:	lda	arg1
	ldx	arg1+1
	cmp	arg2
	bne	.fwd2
	cpx	arg2+1
	beq	.rtn_t
.fwd2:	dec	argcnt
	beq	.rtn_f
	cmp	arg3
	bne	.fwd3
	cpx	arg3+1
	beq	.rtn_t
.fwd3:	dec	argcnt
	beq	.rtn_f
	cmp	arg4
	bne	.rtn_f
	cpx	arg4+1
	bne	.rtn_f
.rtn_t:	jmp	predicate_true

.rtn_f:	jmp	predicate_false


op_call:
	lda	arg1
	ora	arg1+1
	bne	.fwd1
	ldx	#$00
	jmp	store_result_xa

.fwd1:	ldx	Zed
	lda	Zed+1
	jsr	push_ax
	lda	pc
	jsr	push_ax
	ldx	pc+1
	lda	pc+2
	jsr	push_ax
	lda	#$00
	asl	arg1
	rol	arg1+1
	rol
	sta	pc+2
	asl	arg1
	rol	arg1+1
	rol	pc+2
	lda	arg1+1
	sta	pc+1
	lda	arg1
	sta	pc
	jsr	Sedc1
	jsr	Sef50
	sta	Z6f
	sta	Z70
	beq	.fwd2
	lda	#$00
	sta	Z6d
.loop1:	ldy	Z6d
	ldx	local_vars,y
	lda	local_vars+1,y
	jsr	push_ax
	jsr	Sef50
	sta	Z6e
	jsr	Sef50
	ldy	Z6d
	sta	local_vars,y
	lda	Z6e
	sta	local_vars+1,y
	iny
	iny
	sty	Z6d
	dec	Z6f
	bne	.loop1

; if present, copy arg2 through arg8 to the first local variables
.fwd2:	dec	argcnt
	beq	.fwd3

	lda	arg2
	sta	local_vars
	lda	arg2+1
	sta	local_vars+1
	dec	argcnt
	beq	.fwd3

	lda	arg3
	sta	local_vars+2
	lda	arg3+1
	sta	local_vars+3
	dec	argcnt
	beq	.fwd3

	lda	arg4
	sta	local_vars+4
	lda	arg4+1
	sta	local_vars+5
	dec	argcnt
	beq	.fwd3

	lda	arg5
	sta	local_vars+6
	lda	arg5+1
	sta	local_vars+7
	dec	argcnt
	beq	.fwd3

	lda	arg6
	sta	local_vars+8
	lda	arg6+1
	sta	local_vars+9
	dec	argcnt
	beq	.fwd3

	lda	arg7
	sta	local_vars+10
	lda	arg7+1
	sta	local_vars+11
	dec	argcnt
	beq	.fwd3

	lda	arg8
	sta	local_vars+12
	lda	arg8+1
	sta	local_vars+13

.fwd3:	ldx	Z70
	txa
	jsr	push_ax
	lda	Zeb+1
	sta	Zed+1
	lda	Zeb
	sta	Zed
	rts


op_storew:
	asl	arg2
	rol	arg2+1
	jsr	Se8f4
	lda	arg3+1
	sta	(Z6d),y
	iny
	bne	Le8ef

op_storeb:
	jsr	Se8f4
Le8ef:	lda	arg3
	sta	(Z6d),y
	rts


Se8f4:	lda	arg2
	clc
	adc	arg1
	sta	Z6d
	lda	arg2+1
	adc	arg1+1
	clc
	adc	Z81
	sta	Z6e
	ldy	#$00
	rts


op_put_prop:
	jsr	Sf1e3
.loop1:	jsr	Sf201
	cmp	arg2
	beq	.fwd1
	bcc	int_err_0a
	jsr	Sf230
	jmp	.loop1

.fwd1:	jsr	Sf206
	iny
	cmp	#$01
	beq	.fwd2
	cmp	#$02
	bne	int_err_0b
	lda	arg3+1
	sta	(Z6d),y
	iny
.fwd2:	lda	arg3
	sta	(Z6d),y
	rts


int_err_0a:
	lda	#$0a
	jmp	int_error


int_err_0b:
	lda	#$0b
	jmp	int_error


op_print_char:
	lda	arg1
	jmp	Sf311


op_print_num:
	lda	arg1
	sta	Zc7
	lda	arg1+1
	sta	Zc8
	lda	Zc8
	bpl	.fwd1
	lda	#$2d
	jsr	Sf311
	jsr	Se782
.fwd1:	lda	#$00
	sta	Zcf
.loop1:	lda	Zc7
	ora	Zc8
	beq	.fwd2
	lda	#$0a
	sta	Zc9
	lda	#$00
	sta	Zca
	jsr	Se790
	lda	Zc9
	pha
	inc	Zcf
	bne	.loop1
.fwd2:	lda	Zcf
	bne	.loop2
	lda	#$30
	jmp	Sf311

.loop2:	pla
	clc
	adc	#$30
	jsr	Sf311
	dec	Zcf
	bne	.loop2
	rts


op_random:
	lda	arg1
	ora	arg1+1
	bne	.fwd1
	sta	Ze8
	sta	Ze8+1
	jmp	store_result_zero

.fwd1:	lda	Ze8
	ora	Ze8+1
	bne	.fwd3
	lda	arg1+1
	bpl	.fwd2
	eor	#$ff
	sta	Ze8+1
	lda	arg1
	eor	#$ff
	sta	Ze8
	inc	Ze8
	lda	#$00
	sta	Zc0
	sta	Zc1
	beq	.fwd3		; always taken

.fwd2:	lda	arg1
	sta	arg2
	lda	arg1+1
	sta	arg2+1
	jsr	Sf2ff
	stx	arg1
	and	#$7f
	sta	arg1+1
	jsr	divide
	lda	Zc9
	clc
	adc	#$01
	sta	acc
	lda	Zca
	adc	#$00
	sta	acc+1
	jmp	store_result

.fwd3:
	if	iver>=iver2b
	lda	arg1
	sta	Ze8
	lda	arg1+1
	sta	Ze8+1
	endif

	lda	Zc1
	cmp	Ze8+1
	bcc	.fwd4
	lda	Zc0
	cmp	Ze8
	bcc	.fwd4
	beq	.fwd4
	lda	#$01
	sta	Zc0
	lda	#$00
	sta	Zc1
.fwd4:	lda	Zc0
	sta	acc
	lda	Zc1
	sta	acc+1
	inc	Zc0
	bne	.fwd5
	inc	Zc1
.fwd5:	jmp	store_result


op_push:
	ldx	arg1
	lda	arg1+1
	jmp	push_ax


op_pull:
	jsr	op_pop
	lda	arg1
	jmp	Le10d


op_scan_table:
	lda	arg2
	sta	Z7b
	lda	arg2+1
	sta	Z7c
	lda	#$00
	sta	Z7d
	jsr	Sed80
.loop1:	jsr	Sef3b
	sta	Z6e
	jsr	Sef3b
	cmp	arg1
	bne	.fwd1
	lda	Z6e
	cmp	arg1+1
	beq	.fwd2
.fwd1:	dec	arg3
	bne	.loop1
	lda	arg3+1
	beq	.fwd4
	dec	arg3+1
	jmp	.loop1

.fwd2:	sec
	lda	Z7b
	if	iver<=iver2c
	sbc	#$01
	else
	sbc	#$02
	endif
	sta	Z7b
	bcs	.fwd3
	dec	Z7c
.fwd3:	sta	acc
	lda	Z7c
	sta	acc+1
	jsr	store_result
	jmp	predicate_true

.fwd4:	lda	#$00
	sta	acc
	sta	acc+1
	jsr	store_result
	jmp	predicate_false


op_sread:
	lda	arg1+1
	clc
	adc	Z81
	sta	Zc4
	lda	arg1
	sta	Zc3
	lda	arg2+1
	clc
	adc	Z81
	sta	Zc6
	lda	arg2
	sta	Zc5
	ldy	#$00
	lda	(Zc3),y
	cmp	#$4f
	bcc	.fwd1
	lda	#$4e
.fwd1:	sta	Zbe
	jsr	Sdafe
	sta	Z9f
	lda	#$00
	sta	Za0
	ldy	#$01
	sta	(Zc5),y
	sty	Z9d
	iny
	sty	Z9e
.loop1:	ldy	#$00
	lda	(Zc5),y
	beq	.fwd2

	if	iver==iver2a
	cmp	#$3c
	else
	cmp	#$3b
	endif

	bcc	.fwd3

.fwd2:
	if	iver==iver2a
	lda	#$3b
	else
	lda	#$3a
	endif

	sta	(Zc5),y
.fwd3:	iny
	cmp	(Zc5),y
	bcc	.rtn
	lda	Z9f
	ora	Za0
	bne	.fwd4
.rtn:	rts

.fwd4:	lda	Za0
	cmp	#$09
	bcc	.fwd5
	jsr	Seb3e
.fwd5:	lda	Za0
	bne	.fwd6
	ldx	#$08
.loop2:	sta	Z8b,x
	dex
	bpl	.loop2
	jsr	Seb30
	lda	Z9d
	ldy	#$03
	sta	(Za1),y
	tay
	lda	(Zc3),y
	jsr	Seb6b
	bcs	.fwd7
	jsr	Seb5f
	bcc	.fwd6
	inc	Z9d
	dec	Z9f
	jmp	.loop1

.fwd6:	lda	Z9f
	beq	.fwd8
	ldy	Z9d
	lda	(Zc3),y
	jsr	Seb5a
	bcs	.fwd8
	ldx	Za0
	sta	Z8b,x
	dec	Z9f
	inc	Za0
	inc	Z9d
	jmp	.loop1

.fwd7:	sta	Z8b
	dec	Z9f
	inc	Za0
	inc	Z9d
.fwd8:	lda	Za0
	beq	.loop1
	jsr	Seb30
	lda	Za0
	ldy	#$02
	sta	(Za1),y
	jsr	Sf0ac
	jsr	Seb96
	ldy	#$01
	lda	(Zc5),y
	clc
	adc	#$01
	sta	(Zc5),y
	jsr	Seb30
	ldy	#$00
	sty	Za0
	lda	acc+1
	sta	(Za1),y
	iny
	lda	acc
	sta	(Za1),y
	lda	Z9e
	clc
	adc	#$04
	sta	Z9e
	jmp	.loop1


Seb30:	lda	Zc5
	clc
	adc	Z9e
	sta	Za1
	lda	Zc6
	adc	#$00
	sta	Za2
	rts


Seb3e:	lda	Z9f
	beq	.rtn
	ldy	Z9d
	lda	(Zc3),y
	jsr	Seb5a
	bcs	.rtn
	dec	Z9f
	inc	Za0
	inc	Z9d
	bne	Seb3e
.rtn:	rts


Deb54:	fcb	$21,$3f,$2c,$2e,$0d,$20      	; "!?,.. "


Seb5a:	jsr	Seb6b
	bcs	Leb94

Seb5f:	ldx	#$05
.loop1:	cmp	Deb54,x
	beq	Leb94
	dex
	bpl	.loop1
	clc
	rts


Seb6b:	sta	Zd7
	lda	hdr_vocab
	ldy	hdr_vocab+1
	sta	Z7c
	sty	Z7b
	lda	#$00
	sta	Z7d
	jsr	Sed80
	jsr	Sef3b
	sta	Z6f
.loop1:	jsr	Sef3b
	cmp	Zd7
	beq	.fwd1
	dec	Z6f
	bne	.loop1
	lda	Zd7
	clc
	rts

.fwd1:	lda	Zd7
Leb94:	sec
	rts


Seb96:	lda	hdr_vocab
	ldy	hdr_vocab+1
	sta	Z7c
	sty	Z7b
	lda	#$00
	sta	Z7d
	jsr	Sed80
	jsr	Sef3b
	clc
	adc	Z7b
	sta	Z7b
	bcc	.fwd1
	inc	Z7c
.fwd1:	jsr	Sed80
	jsr	Sef3b
	sta	Za5
	sta	Z6d
	lda	#$00
	sta	Z6e
	sta	Z6f
	jsr	Sef3b
	sta	Za4
	jsr	Sef3b
	sta	Za3
	lda	#$00
	sta	Zf4
	sta	Zf5
	sta	Zf6
	ldx	Za5
.loop1:	clc
	lda	Zf4
	adc	Za3
	sta	Zf4
	lda	Zf5
	adc	Za4
	sta	Zf5
	lda	Zf6
	adc	#$00
	sta	Zf6
	dex
	bne	.loop1
	clc
	lda	Zf4
	adc	Z7b
	sta	Zf4
	lda	Zf5
	adc	Z7c
	sta	Zf5
	lda	Zf6
	adc	Z7d
	sta	Zf6

	if	iver>=iver2b
	lda	Zf4
	sec
	sbc	Za5
	sta	Zf4
	lda	Zf5
	sbc	#$00
	sta	Zf5
	endif

	lsr	Za4
	ror	Za3
.loop2:	asl	Z6d
	rol	Z6e
	rol	Z6f
	lsr	Za4
	ror	Za3
	bne	.loop2
	clc
	lda	Z7b
	adc	Z6d
	sta	Z7b
	lda	Z7c
	adc	Z6e
	sta	Z7c
	lda	Z7d
	adc	Z6f
	sta	Z7d
	sec
	lda	Z7b
	sbc	Za5
	sta	Z7b
	bcs	.loop3
	lda	Z7c
	sec
	sbc	#$01
	sta	Z7c
	bcs	.loop3
	lda	Z7d
	sbc	#$00
	sta	Z7d
.loop3:	lsr	Z6f
	ror	Z6e
	ror	Z6d
	lda	Z7b
	sta	Z70
	lda	Z7c
	sta	Z71
	lda	Z7d
	sta	Z72
	jsr	Sed80
	jsr	Sef3b
	cmp	Z94
	bcc	.fwd2
	bne	.fwd6
	jsr	Sef3b
	cmp	Z95
	bcc	.fwd2
	bne	.fwd6
	jsr	Sef3b
	cmp	Z96
	bcc	.fwd2
	bne	.fwd6
	jsr	Sef3b
	cmp	Z97
	bcc	.fwd2
	bne	.fwd6
	jsr	Sef3b
	cmp	Z98
	bcc	.fwd2
	bne	.fwd6
	jsr	Sef3b
	cmp	Z99
	beq	.fwd10
	bcs	.fwd6
.fwd2:	lda	Z70
	clc
	adc	Z6d
	sta	Z7b
	lda	Z71
	adc	Z6e

	if	iver==iver2a
	sta	Z7c
	lda	Z72
	adc	Z6f
	sta	Z7d
	lda	Z7d
	cmp	Zf6
	else
	bcs	.fwd5
	sta	Z7c
	lda	#$00
	sta	Z7d
	lda	Z7c
	cmp	Zf5
	endif

	beq	.fwd3
	bcs	.fwd5
	bcc	.fwd7		; always taken

.fwd3:
	if	iver==iver2a
	lda	Z7c
	cmp	Zf5
	beq	.fwd4
	bcs	.fwd5
	bcc	.fwd7		; always taken
	endif

.fwd4:	lda	Z7b
	cmp	Zf4
	bcc	.fwd7
	beq	.fwd7

.fwd5:	lda	Zf4
	sta	Z7b
	lda	Zf5
	sta	Z7c
	lda	Zf6
	sta	Z7d
	jmp	.fwd7

.fwd6:	lda	Z70
	sec
	sbc	Z6d
	sta	Z7b
	lda	Z71
	sbc	Z6e
	sta	Z7c
	lda	Z72
	sbc	Z6f
	sta	Z7d
.fwd7:	lda	Z6f
	bne	.fwd8
	lda	Z6e
	bne	.fwd8
	lda	Z6d
	cmp	Za5
	bcc	.fwd9
.fwd8:	jmp	.loop3

.fwd9:	lda	#$00
	sta	acc
	sta	acc+1
	rts

.fwd10:	lda	Z70
	sta	acc
	lda	Z71
	sta	acc+1
	rts


Secf8:	lda	Z6d
	sta	Z7b
	lda	Z6e
	sta	Z7c
	lda	#$00
	sta	Z7d
	jmp	Sed80


Ded07:	fcb	$00
Ded08:	fcb	$00
Ded09:	fcb	$00
Ded0a:	fcb	$00
Ded0b:	fcb	$00
Ded0c:	fcb	$00
Ded0d:	fcb	$00
Ded0e:	fcb	$00
Ded0f:	fcb	$00
Ded10:	fcb	$00
Ded11:	fcb	$00
Ded12:	fcb	$00


Led13:	lda	hdr_length+1
	sta	Z6f
	lda	hdr_length
	ldy	#$05
.loop1:	lsr
	ror	Z6f
	dey
	bpl	.loop1
	sta	Z70
.loop2:	jsr	Sed72
	bcc	.rtn
	jsr	Sd51d
	lda	Ded07
	cmp	#$01
	bne	.loop2
	lda	Zb3

	if	iver==iver2a
	cmp	#$95
	else
	cmp	#$96
	endif

	bne	.loop2
	lda	#$00
	sta	Ded07
	lda	#$00
	sta	Ded08
.loop3:	lda	#$09
	sta	Zb3
	jsr	Sed72
	bcc	.rtn
	jsr	Sd51d
	ldy	#$09
	lda	Ded08
	ldx	#$01
	sta	rd_main_ram
	jsr	S086b
	inc	Ded08
	lda	Ded08
	cmp	#$4f
	bcc	.loop3
	jsr	home
	lda	#$02
	sta	cursrv
	jmp	Sd87e

.rtn:	rts


Sed72:	lda	Z6f
	sec
	sbc	#$01
	sta	Z6f
	lda	Z70
	sbc	#$00
	sta	Z70
	rts


Sed80:	lda	Z7d
	bne	.fwd2
	lda	Z7c

	if	iver==iver2a
	cmp	#$ae
	bcs	.fwd1
	adc	#$12
	else
	cmp	#$ad
	bcs	.fwd1
	adc	#$13
	endif

	ldy	#$00
	beq	.fwd3
.fwd1:
	if	iver==iver2a
	sbc	#$a6
	else
	sbc	#$a5
	endif

	ldy	#$01
	bne	.fwd3
.fwd2:	cmp	#$01
	bne	.fwd4
	lda	Z7c
	cmp	#$3b
	bcs	.fwd4

	if	iver==iver2a
	adc	#$5a
	else
	adc	#$5b
	endif

	ldy	#$01
.fwd3:	sty	Z80
	sta	Z7f
.rtn:	rts

.fwd4:	lda	Z7d
	ldy	Z7c
	jsr	See03
	clc

	if	iver==iver2a
	adc	#$95
	else
	adc	#$96
	endif

	sta	Z7f
	ldy	#$01
	sty	Z80
	lda	Dee02
	beq	.rtn
	jmp	Sedc1		; unnecessary, could just fall through


Sedc1:	lda	pc+2
	bne	.fwd2
	lda	pc+1

	if	iver==iver2a
	cmp	#$ae
	bcs	.fwd1
	adc	#$12
	else
	cmp	#$ad
	bcs	.fwd1
	adc	#$13
	endif

	ldy	#$00
	beq	.fwd3
.fwd1:
	if	iver==iver2a
	sbc	#$a6
	else
	sbc	#$a5
	endif

	ldy	#$01
	bne	.fwd3
.fwd2:	cmp	#$01
	bne	.fwd4
	lda	pc+1
	cmp	#$3b
	bcs	.fwd4

	if	iver==iver2a
	adc	#$5a
	else
	adc	#$5b
	endif

	ldy	#$01
.fwd3:	sty	Z7a
	sta	Z79
.rtn:	rts

.fwd4:	lda	pc+2
	ldy	pc+1
	jsr	See03
	clc

	if	iver==iver2a
	adc	#$95
	else
	adc	#$96
	endif

	sta	Z79
	ldy	#$01
	sty	Z7a
	lda	Dee02
	beq	.rtn
	jmp	Sed80


Dee02:	fcb	$00


See03:	sta	Ded0a
	sty	Ded09
	ldx	#$00
	stx	Dee02
	jsr	Seed7
	bcc	.fwd1
	ldx	Ded0b
	lda	D0b56,x
	sta	Ded0b
	tax
	lda	Ded0a
	sta	D0c56,x
	lda	Ded09
	sta	D0cd6,x
	tay
	txa
	pha
	lda	Ded0a
	jsr	See5f
	dec	Dee02
	pla
	rts

.fwd1:	sta	Ded0c
	cmp	Ded0b
	bne	.fwd2
	rts

.fwd2:	ldy	Ded0b
	lda	D0b56,y
	sta	Ded0f
	lda	Ded0c
	jsr	Seeb9
	ldy	Ded0b
	lda	Ded0c
	jsr	See93
	lda	Ded0c
	sta	Ded0b
	rts


See5f:	cmp	#$01
	bcc	.fwd2
	bne	.fwd1
	cpy	#$8a
	bcc	.fwd2
.fwd1:	sta	disk_block_num+1
	sty	disk_block_num
	txa
	clc

	if	iver==iver2a
	adc	#$95
	else
	adc	#$96
	endif

	sta	Zb3
	ldx	#$01
	stx	Ded07
	jmp	Sd51d

.fwd2:	tya
	sec
	sbc	#$3b
	pha
	txa
	clc

	if	iver==iver2a
	adc	#$95
	else
	adc	#$96
	endif

	tay
	sta	rd_main_ram
	ldx	#$01
	stx	D086a
	ldx	#$00
	pla
	jmp	S086b


See93:	sta	Ded11
	sty	Ded10
	tax
	tya
	sta	D0bd6,x
	lda	D0b56,y
	sta	Ded12
	txa
	ldx	Ded12
	sta	D0bd6,x
	txa
	ldx	Ded11
	sta	D0b56,x
	lda	Ded11
	sta	D0b56,y
	rts


Seeb9:	tax
	lda	D0b56,x
	sta	Ded0d
	lda	D0bd6,x
	sta	Ded0e
	tax
	lda	Ded0d
	sta	D0b56,x
	lda	Ded0e
	ldx	Ded0d
	sta	D0bd6,x
	rts


Seed7:
	if	iver==iver2a
	ldx	#$2a
	else
	ldx	#$29
	endif

.loop1:	lda	Ded0a
	cmp	D0c56,x
	beq	.fwd1
.loop2:	dex
	bpl	.loop1
	sec
	rts

.fwd1:	tya
	cmp	D0cd6,x
	bne	.loop2
	txa
	clc
	rts


Seeef:
	if	iver==iver2a
	ldx	#$2a
	else
	ldx	#$29
	endif

	stx	Ded0b
	lda	#$ff
.loop1:	sta	D0c56,x
	dex
	bpl	.loop1
	ldx	#$00
	ldy	#$01
.loop2:	tya
	sta	D0bd6,x
	inx
	iny

	if	iver==iver2a
	cpx	#$2b
	else
	cpx	#$2a
	endif

	bcc	.loop2
	lda	#$00
	dex
	sta	D0bd6,x
	ldx	#$00
	ldy	#$ff

	if	iver==iver2a
	lda	#$2a
	else
	lda	#$29
	endif

.loop3:	sta	D0b56,x
	inx
	iny
	tya

	if	iver==iver2a
	cpx	#$2b
	else
	cpx	#$2a
	endif

	bcc	.loop3
	jmp	Led13


Sef23:	pha
	inc	Z7c
	bne	.fwd1
	inc	Z7d
.fwd1:	jsr	Sed80
	pla
	rts


Sef2f:	pha
	inc	pc+1
	bne	.fwd1
	inc	pc+2
.fwd1:	jsr	Sedc1
	pla
	rts


Sef3b:	ldy	Z80
	sta	rd_main_ram,y	; indexed to get main or card
	ldy	Z7b
	lda	(Z7e),y
	sta	rd_main_ram
	inc	Z7b
	bne	.fwd1
	jsr	Sef23
.fwd1:	tay
	rts


Sef50:	ldy	Z7a
	sta	rd_main_ram,y	; indexed to get main or card
	ldy	pc
	lda	(Z78),y
	sta	rd_main_ram
	inc	pc
	bne	.fwd1
	jsr	Sef2f
.fwd1:	tay
	rts


Sef65:	lda	Z6d
	asl
	sta	Z7b
	lda	Z6e
	rol
	sta	Z7c
	lda	#$00
	rol
	sta	Z7d
	asl	Z7b
	rol	Z7c
	rol	Z7d
	jmp	Sed80


Lef7d:	rts

Sef7e:	ldx	#$00
	stx	Za6
	stx	Zaa
	dex
	stx	Za7
.loop1:	jsr	Sf064
	bcs	Lef7d
	sta	Za8
	tax
	beq	.fwd4
	cmp	#$04
	bcc	.fwd7
	cmp	#$06
	bcc	.fwd5
	jsr	Sf046
	tax
	bne	.fwd1
	lda	#$5b
.loop2:	clc
	adc	Za8
.loop3:	jsr	Sf311
	jmp	.loop1

.fwd1:	cmp	#$01
	bne	.fwd2
	lda	#$3b
	bne	.loop2		; always taken

.fwd2:	lda	Za8
	sec
	sbc	#$06
	beq	.fwd3
	tax
	lda	Df195,x
	jmp	.loop3

.fwd3:	jsr	Sf064
	asl
	asl
	asl
	asl
	asl
	sta	Za8
	jsr	Sf064
	ora	Za8
	jmp	.loop3

.fwd4:	lda	#$20		; always taken
	bne	.loop3

.fwd5:	sec
	sbc	#$03
	tay
	jsr	Sf046
	bne	.fwd6
	sty	Za7
	jmp	.loop1

.fwd6:	sty	Za6
	cmp	Za6
	beq	.loop1
	lda	#$00
	sta	Za6
	beq	.loop1
.fwd7:	sec
	sbc	#$01
	asl
	asl
	asl
	asl
	asl
	asl
	sta	Za9
	jsr	Sf064
	asl
	clc
	adc	Za9
	tay
	lda	(Z87),y
	sta	Z6e
	iny
	lda	(Z87),y
	sta	Z6d
	lda	Z7d
	pha
	lda	Z7c
	pha
	lda	Z7b
	pha
	lda	Za6
	pha
	lda	Zaa
	pha
	lda	Zac
	pha
	lda	Zab
	pha
	jsr	Sf052
	jsr	Sef7e
	pla
	sta	Zab
	pla
	sta	Zac
	pla
	sta	Zaa
	pla
	sta	Za6
	pla
	sta	Z7b
	pla
	sta	Z7c
	pla
	sta	Z7d
	ldx	#$ff
	stx	Za7
	jsr	Sed80
	jmp	.loop1


Sf046:	lda	Za7
	bpl	.fwd1
	lda	Za6
	rts

.fwd1:	ldy	#$ff
	sty	Za7
	rts


Sf052:	lda	Z6d
	asl
	sta	Z7b
	lda	Z6e
	rol
	sta	Z7c
	lda	#$00
	rol
	sta	Z7d
	jmp	Sed80


Sf064:	lda	Zaa
	bpl	.fwd1
	sec
	rts

.fwd1:	bne	.fwd2
	inc	Zaa
	jsr	Sef3b
	sta	Zac
	jsr	Sef3b
	sta	Zab
	lda	Zac
	lsr
	lsr
	jmp	.fwd5

.fwd2:	sec
	sbc	#$01
	bne	.fwd3
	lda	#$02
	sta	Zaa
	lda	Zab
	sta	Z6d
	lda	Zac
	asl	Z6d
	rol
	asl	Z6d
	rol
	asl	Z6d
	rol
	jmp	.fwd5

.fwd3:	lda	#$00
	sta	Zaa
	lda	Zac
	bpl	.fwd4
	lda	#$ff
	sta	Zaa
.fwd4:	lda	Zab
.fwd5:	and	#$1f
	clc
	rts


Sf0ac:	lda	#$05
	ldx	#$08
.loop1:	sta	Z94,x
	dex
	bpl	.loop1
	lda	#$09
	sta	Zad
	lda	#$00
	sta	Zae
	sta	Zaf
.loop2:	ldx	Zae
	inc	Zae
	lda	Z8b,x
	sta	Za8
	bne	.fwd1
	lda	#$05
	bne	.loop3		; always taken

.fwd1:	lda	Za8
	jsr	Sf143
	beq	.fwd3
	clc
	adc	#$03
	ldx	Zaf
	sta	Z94,x
	inc	Zaf
	dec	Zad
	bne	.fwd2
	jmp	Lf15c

.fwd2:	lda	Za8
	jsr	Sf143
	cmp	#$02
	beq	.fwd4
	lda	Za8
	sec
	sbc	#$3b
	bpl	.loop3
.fwd3:	lda	Za8
	sec
	sbc	#$5b
.loop3:	ldx	Zaf
	sta	Z94,x
	inc	Zaf
	dec	Zad
	bne	.loop2
	jmp	Lf15c

.fwd4:	lda	Za8
	jsr	Sf133
	bne	.loop3
	lda	#$06
	ldx	Zaf
	sta	Z94,x
	inc	Zaf
	dec	Zad
	beq	Lf15c
	lda	Za8
	lsr
	lsr
	lsr
	lsr
	lsr
	and	#$03
	ldx	Zaf
	sta	Z94,x
	inc	Zaf
	dec	Zad
	beq	Lf15c
	lda	Za8
	and	#$1f
	jmp	.loop3


Sf133:	ldx	#$19
.loop1:	cmp	Df195,x
	beq	.fwd1
	dex
	bne	.loop1
	rts

.fwd1:	txa
	clc
	adc	#$06
	rts


Sf143:	cmp	#$61
	bcc	.fwd1
	cmp	#$7b
	bcs	.fwd1
	lda	#$00
	rts

.fwd1:	cmp	#$41
	bcc	.fwd2
	cmp	#$5b
	bcs	.fwd2
	lda	#$01
	rts

.fwd2:	lda	#$02
	rts


Lf15c:	lda	Z95
	asl
	asl
	asl
	asl
	rol	Z94
	asl
	rol	Z94
	ora	Z96
	sta	Z95
	lda	Z98
	asl
	asl
	asl
	asl
	rol	Z97
	asl
	rol	Z97
	ora	Z99
	tax
	lda	Z97
	sta	Z96
	stx	Z97
	lda	Z9b
	asl
	asl
	asl
	asl
	rol	Z9a
	asl
	rol	Z9a
	ora	Z9c
	sta	Z99
	lda	Z9a
	ora	#$80
	sta	Z98
	rts


Df195:	fcb	$00,char_cr
	fcb	"0123456789"
	fcb	".,!?_#'"
	fcb	$22		; double quote
	fcb	"/"
	fcb	"\\"		; this is a single backslash, escaped
	fcb	"-:()"


setup_object:
	stx	Z6e
	asl
	sta	Z6d
	rol	Z6e
	ldx	Z6e
	asl
	rol	Z6e
	asl
	rol	Z6e
	asl
	rol	Z6e
	sec
	sbc	Z6d
	sta	Z6d
	lda	Z6e
	stx	Z6e
	sbc	Z6e
	sta	Z6e
	lda	Z6d
	clc
	adc	#$70
	bcc	.fwd1
	inc	Z6e
.fwd1:	clc
	adc	Z89
	sta	Z6d
	lda	Z6e
	adc	Z8a
	sta	Z6e
	rts


Sf1e3:	lda	arg1
	ldx	arg1+1
	jsr	setup_object
	ldy	#$0c
	lda	(Z6d),y
	clc
	adc	Z81
	tax
	iny
	lda	(Z6d),y
	sta	Z6d
	stx	Z6e
	ldy	#$00
	lda	(Z6d),y
	asl
	tay
	iny
	rts


Sf201:	lda	(Z6d),y
	and	#$3f
	rts


Sf206:	lda	(Z6d),y
	and	#$80
	beq	.fwd1
	iny
	lda	(Z6d),y
	and	#$3f
	rts

.fwd1:	lda	(Z6d),y
	and	#$40
	beq	.fwd2
	lda	#$02
	rts

.fwd2:	lda	#$01
	rts


Sf21e:	jsr	Sf206
	tax
.loop1:	iny
	bne	.fwd1
	inc	Z6d
	bne	.fwd1
	inc	Z6e
.fwd1:	dex
	bne	.loop1
	iny
	rts


Sf230:	jsr	Sf21e
	tya
	clc
	adc	Z6d
	sta	Z6d
	bcc	.fwd1
	inc	Z6e
.fwd1:	ldy	#$00
	rts


setup_attribute:
	lda	arg1
	ldx	arg1+1
	jsr	setup_object
	lda	arg2
	cmp	#$10
	bcc	.fwd3
	sbc	#$10
	tax
	cmp	#$10
	bcc	.fwd1
	sbc	#$10
	tax
	lda	Z6d
	clc
	adc	#$04
	sta	Z6d
	bcc	.fwd2
	inc	Z6e
	jmp	.fwd2

.fwd1:	lda	Z6d
	clc
	adc	#$02
	sta	Z6d
	bcc	.fwd2
	inc	Z6e
.fwd2:	txa
.fwd3:	sta	Z71
	ldx	#$01
	stx	Z6f
	dex
	stx	Z70
	lda	#$0f
	sec
	sbc	Z71
	tax
	beq	.fwd4
.loop1:	asl	Z6f
	rol	Z70
	dex
	bne	.loop1
.fwd4:	ldy	#$00
	lda	(Z6d),y
	sta	Z72
	iny
	lda	(Z6d),y
	sta	Z71
	rts


msg_internal_error:
	text_str	"Internal error "
Df2a4:	text_str	"00.  "
msg_len_internal_error	equ	*-msg_internal_error


; On entry:
;   A = error number
int_error:
	ldy	#$01		; divide by 10, storing into message
.loop1:	ldx	#0
.loop2:	cmp	#10
	bcc	.fwd1
	sbc	#10
	inx
	bne	.loop2
.fwd1:	ora	#$30
	sta	Df2a4,y
	txa
	dey
	bpl	.loop1
	prt_msg	internal_error
	jmp	Lf2ce


op_quit:
	jsr	op_new_line
Lf2ce:	prt_msg	end_of_session
	jmp	*		; deliberately hang


msg_end_of_session:
	text_str	"End of session."
	fcb	char_cr
msg_len_end_of_session	equ	*-msg_end_of_session


op_restart:
	ldx	#$00
	stx	wndtop
	lda	ostream_2_state
	beq	.fwd1
	dex
	stx	Ddc34
.fwd1:	jsr	Sd856
	jmp	restart


; Unreferenced? See S14dc in ZIP revision F
Sf2fc:	lda	#$fb
	rts


Sf2ff:	inc	rndloc
	dec	rndloc+1
	lda	rndloc
	adc	Zc0
	tax
	lda	rndloc+1
	sbc	Zc1
	sta	Zc0
	stx	Zc1
	rts


Sf311:	sta	Zd7
	ldx	ostream_3_state
	beq	.fwd1

	if	iver==iver2a
	jsr	Sf3b3
	else
	jmp	Sf3b3
	endif

.fwd1:	ldx	ostream_1_state
	bne	.fwd2
	ldx	ostream_2_state
	bne	.fwd2
	rts

.fwd2:	lda	Zd7
	ldx	Zbd
	bne	.fwd6
	cmp	#char_cr
	bne	.fwd3
	jmp	op_new_line

.fwd3:	cmp	#' '
	bcc	.rtn
	ldx	invflg
	bpl	.fwd4
	ora	#$80
.fwd4:	ldx	Zd1
	sta	D0200,x
	ldy	Zd0
	cpy	Zbf
	bcc	.fwd5
	jmp	Lf3cd

.fwd5:	inc	Zd0
	inc	Zd1
.rtn:	rts

.fwd6:	sta	Zd7
	cmp	#$20
	bcc	.rtn2
	lda	D057b
	cmp	#$50
	bcs	.rtn2
	lda	cursrh
	cmp	#$50
	bcs	.rtn2
	lda	Zc2
	beq	.fwd7
	lda	cursrv
	cmp	wndtop
	bcs	.rtn2
	bcc	.fwd8		; always taken

.fwd7:	lda	cursrv
	cmp	wndtop
	bcc	.rtn2
.fwd8:	lda	ostream_1_state
	beq	.fwd9
	lda	Zd7
	ora	#$80
	jsr	cout
.fwd9:	lda	Zc2
	bne	.rtn2
	lda	Zd4
	beq	.rtn2
	lda	ostream_2_state
	beq	.rtn2
	lda	cswl
	pha
	lda	cswl+1
	pha
	lda	D057b
	pha
	lda	cursrh
	pha
	lda	Ddc35
	sta	cswl
	lda	Ddc36
	sta	cswl+1
	lda	Zd7
	jsr	cout
	pla
	sta	cursrh
	pla
	sta	D057b
	pla
	sta	cswl+1
	pla
	sta	cswl
.rtn2:	rts


Sf3b3:	tax
	lda	Zb9
	clc
	adc	Zb7
	sta	Z6d
	lda	Zba
	adc	Zb8
	sta	Z6e
	ldy	#$00
	txa
	sta	(Z6d),y
	inc	Zb9
	bne	.rtn
	inc	Zba
.rtn:	rts


Lf3cd:	lda	#$a0
	stx	Zd3
.loop1:	cmp	D0200,x
	beq	.fwd1
	dex
	bne	.loop1
	ldx	Zbf
.fwd1:	stx	Zd2
	stx	Zd1
	jsr	op_new_line
	ldx	Zd2
	ldy	#$00
.loop2:	inx
	cpx	Zd3
	bcc	.fwd2
	beq	.fwd2
	sty	Zd0
	sty	Zd1
	rts

.fwd2:	lda	D0200,x
	sta	D0200,y
	iny
	bne	.loop2


op_new_line:
	ldx	Zd1
	lda	#$8d
	sta	D0200,x
	inc	Zd1
	lda	ostream_1_state
	beq	.fwd2
	lda	Zc2
	bne	.fwd1
	inc	Zd5
.fwd1:	ldx	Zd5
	inx
	cpx	wndbot
	bcc	.fwd2
	lda	wndtop
	sta	Zd5
	inc	Zd5
	bit	kbd_strb
	prt_msg_alt	more
.loop1:	bit	kbd
	bpl	.loop1
	bit	kbd_strb
	ldy	#$06
.loop2:	lda	#$08
	jsr	cout
	dey
	bne	.loop2
	jsr	clreol
.fwd2:	jsr	Sf446
	lda	#$00
	sta	Zd0
	sta	Zd1
	rts


Sf446:	ldy	Zd1
	beq	.rtn
	sty	Zde
	lda	ostream_1_state
	beq	.fwd1
	ldx	#$00
.loop1:	lda	D0200,x
	jsr	Sdaee
	inx
	dey
	bne	.loop1
.fwd1:	lda	Zc2
	bne	.rtn
	jsr	Sdbf3
.rtn:	rts


op_show_status:
	rts


; Note that buffer mode only applies to the lower window,
; and buffering never happens for the upper window.
; (In Z-Machine v6, every window has its own buffer mode
; flag.)
op_buffer_mode:
	ldx	arg1
	bne	.fwd1
	jsr	Sf446
	ldx	#$00
	stx	Zd1
	inx
	stx	Zbd
	rts

.fwd1:	dex
	bne	.rtn
	stx	Zbd
.rtn:	rts


op_output_stream:
	ldx	arg1
	bmi	ostream_deselect
	dex
	beq	ostream_select_1
	dex
	beq	ostream_select_2
	dex
	beq	ostream_select_3
	dex
	beq	ostream_select_4
	rts

ostream_deselect:
	inx
	beq	ostream_deselect_1
	inx
	beq	ostream_deselect_2
	inx
	beq	ostream_deselect_3
	inx
	beq	ostream_deselect_4
	rts

; output stream 1 is the screen
ostream_select_1:
	inx
	stx	ostream_1_state
	rts

ostream_deselect_1:
	stx	ostream_1_state
	rts

; output stream 2 is the printer
ostream_select_2:
	inx
	stx	ostream_2_state
	lda	hdr_flags2+1
	ora	#$01
	sta	hdr_flags2+1
	lda	Ddc34
	bne	.rtn
	jsr	Sdc37
.rtn:	rts

ostream_deselect_2:
	stx	ostream_2_state
	lda	hdr_flags2+1
	and	#$fe
	sta	hdr_flags2+1
	rts

; output stream 3 is a Z-machine table
; selecting stream 3 can be done recursively
ostream_select_3:
	inx
	stx	ostream_3_state
	lda	arg2+1
	clc
	adc	Z81
	ldx	arg2
	stx	Zb7
	sta	Zb8
	lda	#$02
	sta	Zb9
	lda	#$00
	sta	Zba
	rts

ostream_deselect_3:
	if	iver>=iver2c
	lda	ostream_3_state		; if no output stream 3 was selected, do nothing.
	beq	.fwd2
; This above fix appears to introduce a new bug, in that the following
; "stx ostream_3_state" instruction (outside the conditional assembly)
; will always store 1, even if the ostream table stack is empty.
	endif
	stx	ostream_3_state
	lda	Zb9
	clc
	adc	Zb7
	sta	Z6d
	lda	Zba
	adc	Zb8
	sta	Z6e
	lda	#$00
	tay
	sta	(Z6d),y
	ldy	#$01
	lda	Zb9
	sec
	sbc	#$02
	sta	(Zb7),y
	bcs	.fwd1
	dec	Zba
.fwd1:	lda	Zba
	dey
	sta	(Zb7),y
	lda	#$00
	sta	Zb6
.fwd2	rts

; output stream 4, if it existed, would be a script file of user input
ostream_select_4:
ostream_deselect_4:
	rts


op_set_cursor:
	if	iver==iver2a

	lda	hdr_flags_1
	and	#$10
	beq	.rtn
	lda	Zc2
	bne	.fwd2
	ldx	arg1
	dex
	txa
	clc
	adc	wndtop
	sta	cursrv
	ldx	Zbd
	bne	.fwd1
	sta	Zd5

.fwd1:	ldx	arg2
	dex
	stx	D057b
	stx	cursrh
	jmp	vtab

.rtn:	rts

.fwd2:	ldx	arg1
	dex
	stx	cursrv
	jmp	.fwd1

	else

	lda	hdr_flags_1
	and	#$10
	beq	.rtn
	ldy	Zbd
	beq	.rtn
	ldy	Zc2
	beq	.rtn
	ldx	arg1
	dex
	stx	cursrv

	ldx	arg2
	dex
	stx	D057b
	stx	cursrh
	jmp	vtab

.rtn:	rts

	endif



op_get_cursor:
op_input_stream:
	rts


op_set_text_state:
	lda	arg1
	bne	.fwd1
	lda	#$ff
	sta	invflg
.rtn:	rts

.fwd1:	cmp	#$01
	bne	.rtn
	lda	hdr_flags_1
	and	#$02
	beq	.rtn
	lda	#$3f
	sta	invflg
	rts


op_erase_line:
	lda	hdr_flags_1
	and	#$10
	beq	Lf559
	lda	arg1
	cmp	#$01
	bne	Lf559
	jmp	clreol

Lf559:	rts


op_erase_window:
	lda	hdr_flags_1
	and	#$01
	beq	Lf559
	lda	arg1
	beq	.fwd1
	cmp	#$01
	beq	.fwd2
	cmp	#$ff
	bne	Lf559
	jsr	Sdcd8
	jmp	home

.fwd1:	lda	wndtop
	sta	Zd5
	jsr	home
	lda	#$17
	sta	cursrv
	jmp	vtab

.fwd2:	lda	wndtop
	pha
	ldx	#$00
	stx	wndtop
	sta	wndbot
	jsr	home
	lda	#$18
	sta	wndbot
	pla
	sta	wndtop
	sta	cursrv
	dec	cursrv
	jmp	vtab


op_read_char:
	lda	arg1
	cmp	#$01
	bne	.fwd3
	lda	wndtop
	sta	Zd5

	if	iver<=iver2d
	lda	#$00
	sta	Zd0
	else
	inc	Zd5
	lda	#$00
	endif

	sta	Zd1
	dec	argcnt
	beq	.fwd2
	lda	arg2
	sta	Z6e
	lda	#$00
	sta	Z70
	sta	Z6f
	dec	argcnt
	beq	.fwd1
	lda	arg3
	sta	Z6f
	lda	arg3+1
	sta	Z70
.fwd1:	bit	kbd_strb
.loop1:	lda	Z6e
	sta	Z6d
.loop2:	ldx	#$0a
.loop3:	lda	#$40
	jsr	Sfca8
	dex
	bne	.loop3
	bit	kbd
	bmi	.fwd2
	dec	Z6d
	bne	.loop2
	lda	Z6f
	ora	Z70
	beq	.fwd3
	jsr	Sf5f9
	lda	acc
	bne	.fwd3
	beq	.loop1		; always taken

.fwd2:	jsr	Sda78
	ldx	#$00
	jmp	store_result_xa

.fwd3:	jmp	store_result_zero


Sf5f9:	lda	#Lf67c>>8
	sta	Le4db+2
	lda	#Lf67c&$ff
	sta	Le4db+1
	lda	Z6e
	pha
	lda	Z70
	pha
	lda	Z6f
	pha
	ldx	Zed
	lda	Zed+1
	jsr	push_ax
	lda	pc
	jsr	push_ax
	ldx	pc+1
	lda	pc+2
	jsr	push_ax
	lda	#$00
	asl	Z6f
	rol	Z70
	rol
	sta	pc+2
	asl	Z6f
	rol	Z70
	rol	pc+2
	lda	Z70
	sta	pc+1
	lda	Z6f
	sta	pc
	jsr	Sedc1
	jsr	Sef50
	sta	Z6f
	sta	Z70
	beq	.fwd1
	lda	#$00
	sta	Z6d
.loop1:	ldy	Z6d
	ldx	local_vars,y
	lda	local_vars+1,y
	jsr	push_ax
	jsr	Sef50
	sta	Z6e
	jsr	Sef50
	ldy	Z6d
	sta	local_vars,y
	lda	Z6e
	sta	local_vars+1,y
	iny
	iny
	sty	Z6d
	dec	Z6f
	bne	.loop1
.fwd1:	ldx	Z70
	txa
	jsr	push_ax
	lda	Zeb
	sta	Zed
	lda	Zeb+1
	sta	Zed+1
	jmp	main_loop


Lf67c:	lda	#store_result>>8
	sta	Le4db+2
	lda	#store_result&$ff
	sta	Le4db+1
	pla
	pla
	pla
	sta	Z6f
	pla
	sta	Z70
	pla
	sta	Z6e
	rts


msg_more:
	text_str	"[MORE]"
msg_len_more	equ	*-msg_more


msg_printer_slot:
	fcb	char_cr
	text_str	"Printer Slot 1-7: "
msg_len_printer_slot	equ	 *-msg_printer_slot

msg_story_loading:
	text_str	"The story is loading ..."
msg_len_story_loading	equ	*-msg_story_loading

	if	iver==iver2a
	fillto	$f700,$ff
	else
	fillto	$f800,$00
	endif
