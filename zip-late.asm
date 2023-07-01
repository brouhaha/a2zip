; Infocom ZIP (Z-Machine architecture v3) interpreter for Apple II,

; The ZIP interpreter is copyrighted by Infocom, Inc.

; This partially reverse-engineered source code is
; Ccopyright 2023 Eric Smith <spacewar@gmail.com>

	cpu	6502

iver3f	equ	$0306

iver3h	equ	$0308

iver3k	equ	$030b

iver3m	equ	$030d


	ifndef	iver
iver	equ	iver3f
	endif


char_bs		equ	$08
char_cr		equ	$0d
char_del	equ	$7f


fillto	macro	addr, val
	while	* < addr
size	set	addr-*
	if	size > 256
size	set	256
	endif
	fcb	[size] val
	endm
	endm

text_str	macro	arg
	fcb	arg
	endm

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


; disk zero page variables:
		org	$60

Z60:		rmb	1
Z61:		rmb	1
Z62:		rmb	1
Z63:		rmb	1
rwts_sector:	rmb	1
rwts_track:	rmb	1
Z66:		rmb	1
rwts_cmd:	rmb	1
rwts_buf:	rmb	2
Z6a:		rmb	1
rwts_slotx16:	rmb	1
Z6c:	rmb	1
Z6d:	rmb	1
Z6e:	rmb	1
Z6f:	rmb	1
Z70:	rmb	1
Z71:	rmb	1
	rmb	1
Z73:	rmb	1
Z74:	rmb	1


; interpreter zero page variables
	org	$80

opcode:	rmb	1
argcnt:	rmb	1

arg1:	rmb	2
arg2:	rmb	2
arg3:	rmb	2
arg4:	rmb	2

Z8a:	rmb	1
Z8b:	rmb	1
Z8c:	rmb	2
Z8e:	rmb	2
Z90:	rmb	2
acb:	rmb	2
Z94:	rmb	2
pc:	rmb	2
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
Za3:	rmb	2
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
Zb0:	rmb	1
Zb1:	rmb	1
Zb2:	rmb	1
Zb3:	rmb	1
Zb4:	rmb	1
	rmb	5
Zba:	rmb	1
Zbb:	rmb	1
Zbc:	rmb	1
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
Zd3:	rmb	2
Zd5:	rmb	1
Zd6:	rmb	1
Zd7:	rmb	1
Zd8:	rmb	1
Zd9:	rmb	1
Zda:	rmb	1
Zdb:	rmb	1
Zdc:	rmb	1
Zdd:	rmb	1
Zde:	rmb	1
Zdf:	rmb	1
Ze0:	rmb	1
	rmb	1
Ze2:	rmb	1
	rmb	1
Ze4:	rmb	1
	rmb	4
Ze9:	rmb	1
Zea:	rmb	1
Zeb:	rmb	1
Zec:	rmb	1
Zed:	rmb	1
	rmb	2
Zf0:	rmb	1
Zf1:	rmb	1
Zf2:	rmb	1
Zf3:	rmb	1
Zf4:	rmb	1
	rmb	1
Zf6:	rmb	1
Zf7:	rmb	1
Zf8:	rmb	1
	rmb	2
Zfb	rmb	1


D0100	equ	$0100
D01ff	equ	$01ff

D0200	equ	$0200

cur80h	equ	$057b

D0835	equ	$0835


	org	$2900
rwts_sec_buf_size	equ	86

rwts_data_buf:	rmb	256
rwts_pri_buf:	rmb	256
rwts_sec_buf:	rmb	rwts_sec_buf_size

	align	$0100

D2c00:		rmb	256
D2d00:		rmb	256

		rmb	256

stk_low_bytes:	rmb	256	; stack, low bytes
stk_high_bytes:	rmb	256	; stack, high bytes

local_vars:	rmb	30

		rmb	2

D3120:		rmb	2	; save hdr_game_ver
D3122:		rmb	2	; save Z94
D3124:		rmb	3	; save PC

	align	$0100

; game header

hdr_arch	rmb	1	; Z-machine architecture version
hdr_flags_1	rmb	1	; flags 1
hdr_game_ver	rmb	2	; game version
hdr_high_mem	rmb	2	; base of high memory
hdr_init_pc	rmb	2	; initial value of program counter (byte address)
hdr_vocab	rmb	2	; location of dictionary
hdr_object	rmb	2	; object table
hdr_globals	rmb	2	; global variables
hdr_pure	rmb	2	; base of pure (immutable) memory
hdr_flags2	rmb	2
		rmb	6	; "serial" (usually game release date)
hdr_abbrev	rmb	2	; abbreviation table
hdr_length	rmb	2
hdr_checksum	rmb	2


; Apple II I/O
kbd		equ	$c000
kbd_strb	equ	$c010
rdc3rom		equ	$c017	; IIe and newer
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
rdkey	equ	$fd0c
cout	equ	$fded
bell	equ	$ff3a

	org	$0900

; RWTS caller - unused?
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
S093a:	stx	Z6e
	stx	D0d51
	sec

	lda	q6h,x		; check write protect
	lda	q7l,x
	bmi	.exit

	lda	rwts_sec_buf
	sta	Z6d

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
	bne	.lp2Z
.loop2:	lda	rwts_sec_buf,y
.lp2Z:	eor	rwts_sec_buf-1,y
	tax
	lda	nib_tab,x
	ldx	Z6e
	sta	q6h,x
	lda	q6l,x
	dey
	bne	.loop2

; write primary buffer
	lda	Z6d
	nop
.loop3:	eor	rwts_pri_buf,y
	tax
	lda	nib_tab,x
	ldx	D0d51
	sta	q6h,x
	lda	q6l,x
	lda	rwts_pri_buf,y
	iny
	bne	.loop3

	tax			; write checksum
	lda	nib_tab,x
	ldx	Z6e
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
	cpy	Z6d
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
	sty	Z6d
.loop7:	ldy	q6l,x
	bpl	.loop7
	eor	denib_tab,y
	ldy	Z6d
	sta	rwts_sec_buf,y
	bne	.loop6

; read primary buffer in forward order
.loop8:	sty	Z6d
.loop9:	ldy	q6l,x
	bpl	.loop9
	eor	denib_tab,y
	ldy	Z6d
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
read_data_field_16_fail:	sec
	rts


; search for and read address field
read_address_field:
	ldy	#$fc
	sty	Z6d
.loop1:	iny
	bne	.loop2
	inc	Z6d
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
.loop6:	sta	Z6e
.loop7:	lda	q6l,x
	bpl	.loop7
	rol
	sta	Z6d
.loop8:	lda	q6l,x
	bpl	.loop8
	and	Z6d
	sta	Z6f,y
	eor	Z6e
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
	sta	Z6c
	cmp	D0d3e
	beq	.rtn
	lda	#$00
	sta	Z6d
.loop1:	lda	D0d3e
	sta	Z6e
	sec
	sbc	Z6c
	beq	.fwd4
	bcs	.fwd1
	eor	#$ff
	inc	D0d3e
	bcc	.fwd2
.fwd1:	adc	#$fe
	dec	D0d3e
.fwd2:	cmp	Z6d
	bcc	.fwd3
	lda	Z6d
.fwd3:	cmp	#$0c
	bcs	denib_tab
	tay
	sec
	jsr	.subr1
	lda	motor_on_time_tab,y
	jsr	delay
	lda	Z6e
	clc
	jsr	.subr2
	lda	motor_off_time_tab,y
	jsr	delay
	inc	Z6d
	bne	.loop1
.fwd4:	jsr	delay
	clc
.subr1:	lda	D0d3e
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
	inc	Z73
	bne	.fwd1
	inc	Z74
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
;       $00 = read 16-sector
;       $01 = write 16-sector
rwts_inner:
	sta	rwts_cmd
	lda	#$02
	sta	D0d52
	asl
	sta	D0d4e
	ldx	Z60
	cpx	Z61
	beq	.fwd1
	ldx	Z61
	lda	q7l,x
.loop1:	ldy	#$08
	lda	q6l,x
.loop2:	cmp	q6l,x
	bne	.loop1
	dey
	bne	.loop2
	ldx	Z60
	stx	Z61
.fwd1:	lda	q7l,x
	lda	q6l,x
	ldy	#$08
.loop3:	lda	q6l,x
	pha
	pla
	pha
	pla
	stx	D0d50
	cmp	q6l,x
	bne	.fwd2
	dey
	bne	.loop3
.fwd2:	php
	lda	mtr_on,x
	lda	#$d8
	sta	Z74
	lda	Z62
	cmp	Z63
	beq	.fwd3
	sta	Z63
	plp
	ldy	#$00
	php
.fwd3:	ror
	bcc	.fwd4
	lda	drv0_en,x
	bcs	.fwd5
.fwd4:	lda	drv1_en,x
.fwd5:	ror	Z6a
	plp
	php
	bne	.fwd6
	ldy	#$07
.loop4:	jsr	delay
	dey
	bne	.loop4
	ldx	D0d50
.fwd6:	lda	rwts_track
	jsr	S0cf4
	plp
	bne	.fwd7
	ldy	Z74
	bpl	.fwd7
.loop5:	ldy	#$12
.loop6:	dey
	bne	.loop6
	inc	Z73
	bne	.loop5
	inc	Z74
	bne	.loop5

.fwd7:	lda	rwts_cmd	; is command read or write?
	ror
	php
	bcc	L0c73		;   read

	jsr	pre_nibble	; write

L0c73:	lda	#48
	sta	addr_field_search_retry_counter
L0c78:	ldx	D0d50
	jsr	read_address_field
	bcc	L0ca4

; address field not found
L0c80:	dec	addr_field_search_retry_counter
	bpl	L0c78

; too many errors searching for address field
L0c85:	lda	D0d3e
	pha
	lda	#$60
	jsr	S0d26
	dec	D0d52
	beq	L0cbb
	lda	#$04
	sta	D0d4e
	lda	#$00
	jsr	S0cf4
	pla
L0c9e:	jsr	S0cf4
	jmp	L0c73

L0ca4:	ldy	Z71
	cpy	D0d3e
	beq	L0cc2
	lda	D0d3e
	pha
	tya
	jsr	S0d26
	pla
	dec	D0d4e
	bne	L0c9e
	beq	L0c85		; always taken

L0cbb:	pla
	lda	#$40
	plp
	jmp	L0ce4

L0cc2:	ldy	rwts_sector	; logical sector number
	lda	D0835,y		; map to physical sector number via interleave table in boot1
	cmp	Z70		; does it match physical sector number?
	bne	L0c80		;   no

	plp
	bcs	L0ceb
	jsr	read_data_field_16
	php
	bcs	L0c80
	plp

	ldx	#$00
	stx	Z6d
	jsr	post_nibble
	ldx	D0d50
L0cdf:	lda	#$00
	clc
	bcc	L0ce5
L0ce4:	sec
L0ce5:	sta	Z66
	lda	mtr_off,x
	rts

L0ceb:	jsr	S093a
	bcc	L0cdf
	lda	#$10
	bne	L0ce4		; always taken



S0cf4:	asl
	jsr	S0cfc
	lsr	D0d3e
	rts


S0cfc:	sta	Z6c
	jsr	S0d1f
	lda	D0d3e,y
	bit	Z6a
	bmi	L0d0b
	lda	D0d46,y
L0d0b:	sta	D0d3e
	lda	Z6c
	bit	Z6a
	bmi	L0d19
	sta	D0d46,y
	bpl	L0d1c
L0d19:	sta	D0d3e,y
L0d1c:	jmp	seek_track


S0d1f:	txa
	lsr
	lsr
	lsr
	lsr
	tay
	rts


S0d26:	pha
	lda	Z62
	ror
	ror	Z6a
	jsr	S0d1f
	pla
	asl
	bit	Z6a
	bmi	.fwd1
	sta	D0d46,y
	bpl	.rtn
.fwd1:	sta	D0d3e,y
.rtn:	rts

D0d3e:	fcb	$00,$00,$00,$00,$00,$00,$00,$00
D0d46:	fcb	$00,$00,$00,$00,$00,$00,$00,$00
D0d4e:	fcb	$00

addr_field_search_retry_counter:
	fcb	$00

D0d50:	fcb	$00
D0d51:	fcb	$00
D0d52:	fcb	$00


; subroutine called by boot1
e_0d53:	lda	text_on
	lda	mixed_off
	lda	txt_page_1

	lda	#rwts_data_buf>>8
	sta	rwts_buf+1
	lda	#rwts_data_buf&$ff
	sta	rwts_buf

	lda	#$01
	sta	Z62
	sta	Z63
	rts


; convert block number to track and sector
S0d6b:	lda	Zea
	and	#$0f
	sta	rwts_sector
	lda	Zeb
	and	#$0f
	asl
	asl
	asl
	asl
	sta	rwts_track
	lda	Zea
	and	#$f0
	lsr
	lsr
	lsr
	lsr
	ora	rwts_track
	clc
	cld
	adc	#$03
	cmp	#$24
	bcs	int_err_0c
	sta	rwts_track

read_sector:
	lda	#$00
	jsr	rwts_inner
	bcs	int_err_0e_alt
	ldy	#$00
L0d98:	lda	rwts_data_buf,y
	sta	(Zec),y
	iny
	bne	L0d98
	inc	Zea
	bne	L0da6
	inc	Zeb
L0da6:	inc	rwts_sector
	lda	rwts_sector
	and	#$0f
	bne	L0db7
	ldx	rwts_track
	inx
	cpx	#$24
	bcs	L0dce
	stx	rwts_track
L0db7:	sta	rwts_sector
	inc	Zed
	clc
	rts


e_0dbd:	ldy	#$00
L0dbf:	lda	(Zec),y
	sta	rwts_data_buf,y
	iny
	bne	L0dbf
	lda	#$01
	jsr	rwts_inner
	bcc	L0da6
L0dce:	rts


int_err_0c:
	lda	#$0c
	jmp	int_error


int_err_0e_alt:
	lda	#$0e
	jmp	int_error


e_0dd9:	jsr	op_new_line
	lda	#$00
	sta	wndtop
	jsr	home
	lda	#$00
	sta	Zdf
	sta	cursrh
	sta	cur80h
	sta	cursrv
	jmp	S144e


msg_default_is:	text_str	" (Default is "
D0dfe:	text_str	"*) >"
msg_len_default_is	equ	*-msg_default_is


S0e02:	clc
	adc	#'1'
	sta	D0dfe
	prt_msg_ret	default_is


msg_position:
	fcb	char_cr
	text_str	"Position 0-7"
msg_len_position	equ	*-msg_position


msg_drive:
	fcb	char_cr
	text_str	"Drive 1 or 2"
msg_len_drive	equ    *-msg_drive


msg_slot:
	fcb	char_cr
	text_str	"Slot 1-7"
msg_len_slot	equ	*-msg_slot


D0e34:	fcb	$05


msg_pos_drive_slot_verify:
	fcb	char_cr,char_cr
	text_str	"Position "
D0e40:	text_str	"*; Drive #"
D0e4a	text_str	"*; Slot "
D0e52:	text_str	"*."
	fcb	char_cr
	text_str	"Are you sure? (Y/N) >"
msg_len_pos_drive_slot_verify	equ	*-msg_pos_drive_slot_verify
	

msg_insert_save:
	fcb	char_cr
	text_str	"Insert SAVE disk into Drive #"
D0e88:	text_str	"*."
msg_len_insert_save	equ	*-msg_insert_save


msg_yes:
D0e8a:	text_str	"YES"
	fcb	char_cr
msg_len_yes	equ	*-msg_yes


msg_no:
D0e8e:	text_str	"NO"
	fcb	char_cr
msg_len_no	equ	*-msg_no


S0e91:	prt_msg	position
	ldx	Zf0
	dex
	txa
	jsr	S0e02
.loop1:	jsr	S11c5
	cmp	#char_cr
	beq	.fwd1
	sec
	sbc	#'0'
	cmp	#8
	bcc	.fwd2
	jsr	bell
	jmp	.loop1

.fwd1:	lda	Zf0
.fwd2:	sta	Zf2
	clc
	adc	#$30
	sta	D0e40
	sta	D1063
	sta	D110c
	jsr	S1275
	prt_msg	drive
	lda	Zf1
	jsr	S0e02
.loop2:	jsr	S11c5
	cmp	#$0d
	beq	.fwd3
	sec
	sbc	#'1'
	cmp	#2
	bcc	.fwd4
	jsr	bell
	jmp	.loop2

.fwd3:	lda	Zf1
.fwd4:	sta	Zf3
	clc
	adc	#'1'
	sta	D0e88
	sta	D0e4a
	jsr	S1275

	lda	romid2_save		; IIc family?
	bne	.fwd5			;   no
	lda	#$05			; yes, force slot 5
	bne	.fwd7

.fwd5:	prt_msg	slot
	lda	D0e34
	jsr	S0e02
.loop3:	jsr	S11c5
	cmp	#$0d
	beq	.fwd6
	sec
	sbc	#$31
	cmp	#$07
	bcc	.fwd7
	jsr	bell
	jmp	.loop3
.fwd6:	lda	D0e34
.fwd7:	sta	Zf4
	clc
	adc	#'1'
	sta	D0e52

	ldx	romid2_save	; IIc family?
	beq	.fwd8		;   yes
	jsr	S1275

.fwd8:	prt_msg	pos_drive_slot_verify
.loop4:	jsr	S11c5
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
	jsr	bell
	jmp	.loop4

.fwd9:	prt_msg	no
	jmp	S0e91

.fwd10:	prt_msg	yes
	lda	Zf3
	sta	Zf1
	sta	Z62
	inc	Z62
	ldx	Zf4
	stx	D0e34
	inx
	txa
	asl
	asl
	asl
	asl
	sta	Z60
	lda	Zf2
	sta	Zf0
	asl
	asl
	sta	rwts_track
	lda	#$00
	sta	rwts_sector

	prt_msg	insert_save

S0f9e:	prt_msg	press_return
.loop5:	jsr	S11c5
	cmp	#char_cr
	beq	.fwd13
	jsr	bell
	jmp	.loop5
.fwd13:	rts


msg_press_return:
	fcb	char_cr
	text_str	"Press [RETURN] to continue."
	fcb	char_cr
	text_str	">"
msg_len_press_return	equ	*-msg_press_return


msg_insert_story:
	fcb	char_cr
	text_str	"Insert the STORY disk into Drive #1."
msg_len_insert_story	equ	*-msg_insert_story


S0ff8:	lda	D172e
	ldx	D172d
	sta	Z62
	stx	Z60
	lda	Zf1
	bne	.fwd2
.loop1:	prt_msg	insert_story
	jsr	S0f9e
	ldx	#$01
	stx	rwts_sector
	dex
	stx	rwts_track
	txa
	jsr	rwts_inner
	bcc	.fwd1
	jmp	int_err_0e_alt

.fwd1:	lda	#$29
	sta	Z8e+1
	lda	#$00
	sta	Z8e
	ldx	#$08
	inx
	stx	Z90+1
	lda	#$00
	sta	Z90
	ldy	#$00
.loop2:	lda	(Z8e),y
	cmp	(Z90),y
	bne	.loop1
	iny
	bne	.loop2
.fwd2:	lda	#$ff
	sta	Zdf
	rts


msg_save_position:
D1043:	text_str	"Save Position"
	fcb	char_cr
msg_len_save_position	equ	*-msg_save_position


msg_saving_position:
	fcb	char_cr,char_cr
	text_str	"Saving position "
D1063:	text_str	"* ..."
	fcb	char_cr
msg_len_saving_position	equ	*-msg_saving_position


op_save:
	lda	wndtop
	pha
	jsr	e_0dd9
	prt_msg	save_position
	jsr	S0e91
	prt_msg	saving_position
	lda	hdr_game_ver
	sta	D3120
	lda	hdr_game_ver+1
	sta	D3120+1
	lda	Z94
	sta	D3122
	lda	Z94+1
	sta	D3122+1

	ldx	#$02
.loop1:	lda	pc,x
	sta	D3124,x
	dex
	bpl	.loop1

	lda	#(hdr_arch>>8)-1
	sta	Zed
	jsr	e_0dbd
	bcc	.fwd1

.loop2:	jsr	S0ff8
	pla
	sta	wndtop
	jsr	home
	jmp	predicate_false

.fwd1:	lda	#(hdr_arch>>8)-3
	sta	Zed
	jsr	e_0dbd
	bcs	.loop2
	jsr	e_0dbd
	bcs	.loop2
	lda	Za3
	sta	Zed
	ldx	hdr_pure
	inx
	stx	Z8e
.loop4:	jsr	e_0dbd
	bcs	.loop2
	dec	Z8e
	bne	.loop4

	jsr	S0ff8
	pla
	sta	wndtop
	jsr	home
	jmp	predicate_true


msg_restore_position:
	text_str	"Restore Position"
	fcb	char_cr
msg_len_restore_position	equ	*-msg_restore_position


msg_restoring_position:
	fcb	char_cr,char_cr
	text_str	"Restoring position "
D110c:	text_str	"* ..."
	fcb	char_cr
msg_len_restoring_position	equ	*-msg_restoring_position


op_restore:
	lda	wndtop
	pha
	jsr	e_0dd9
	prt_msg	restore_position
	jsr	S0e91
	prt_msg	restoring_position

	ldx	#$1f
.loop1:	lda	local_vars,x
	sta	D0100,x
	dex
	bpl	.loop1

	lda	#(hdr_arch>>8)-1
	sta	Zed
	jsr	read_sector
	bcs	.loop2
	lda	D3120
	cmp	hdr_game_ver
	bne	.loop2
	lda	D3120+1
	cmp	hdr_game_ver+1
	beq	.fwd1

.loop2:	ldx	#$1f
.loop3:	lda	D0100,x
	sta	local_vars,x
	dex
	bpl	.loop3

	jsr	S0ff8
	pla
	sta	wndtop
	jsr	home
	jmp	predicate_false

.fwd1:	lda	hdr_flags2
	sta	Z8e
	lda	hdr_flags2+1
	sta	Z8e+1

	lda	#(hdr_arch>>8)-3
	sta	Zed
	jsr	read_sector
	bcs	.loop2
	jsr	read_sector
	bcs	.loop2
	lda	Za3
	sta	Zed
	jsr	read_sector
	bcs	.loop2
	lda	Z8e
	sta	hdr_flags2
	lda	Z8e+1
	sta	hdr_flags2+1
	lda	hdr_pure
	sta	Z8e
.loop5:	jsr	read_sector
	bcs	.loop2
	dec	Z8e
	bne	.loop5

	lda	D3122
	sta	Z94
	lda	D3122+1
	sta	Z94+1

	ldx	#$02
.loop6:	lda	D3124,x
	sta	pc,x
	dex
	bpl	.loop6

	lda	#$00
	sta	Z99
	jsr	S0ff8
	pla
	sta	wndtop
	jsr	home
	jmp	predicate_true


S11c5:	cld
	txa
	pha
	tya
	pha
.loop1:	lda	D172b
	beq	.fwd0
	lda	cur80h
	sta	cursrh
.fwd0:	jsr	rdkey
	and	#$7f
	cmp	#$0d
	bne	.fwd1
	jmp	.fwd6

.fwd1:	cmp	#$7f
	bne	.fwd2
	jmp	.fwd6

.fwd2:	cmp	#$08
	bne	.fwd3
	jmp	.fwd6

.fwd3:	cmp	#$20
	bcc	.fwd5
	cmp	#$2b
	beq	.fwd5
	cmp	#$3c
	bne	.fwd4
	lda	#$2c
	bne	.fwd6		; always taken

.fwd4:	cmp	#$5f
	bne	.fwd4a
	lda	#$2d
	bne	.fwd6		; always taken

.fwd4a:	cmp	#$3e
	bne	.fwd4b
	lda	#$2e
	bne	.fwd6		; always taken

.fwd4b:	cmp	#$29
	bne	.fwd4c
	lda	#$30
	bne	.fwd6		; always taken

.fwd4c:	cmp	#$40
	bne	.fwd4d
	lda	#$32
	bne	.fwd6		; always taken

.fwd4d:	cmp	#$25
	bne	.fwd4e
	lda	#$35
	bne	.fwd6		; always taken

.fwd4e:	cmp	#$5e
	bne	.fwd4f
	lda	#$36
	bne	.fwd6		; always taken

.fwd4f:	cmp	#$26
	bne	.fwd4g
	lda	#$37
	bne	.fwd6		; always taken

.fwd4g:	cmp	#$2a
	bne	.fwd4h
	lda	#$38
	bne	.fwd6		; always taken

.fwd4h:	cmp	#$28
	bne	.fwd4i
	lda	#$39
	bne	.fwd6		; always taken

.fwd4i:	cmp	#$3c
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
.fwd5:	jsr	bell
	jmp	.loop1

.fwd6:	sta	Ze2
	adc	rndloc
	sta	rndloc
	eor	rndloc+1
	sta	rndloc+1
	pla
	tay
	pla
	tax
	lda	Ze2
	rts


S1275:	sta	Ze2
	txa
	pha
	tya
	pha
	lda	Ze2
	cmp	#$60
	bcc	.fwd1
	cmp	#$80
	bcs	.fwd1
	ldx	D172b
	bne	.fwd1
	and	#$df
.fwd1:	ora	#$80
	jsr	cout
	pla
	tay
	pla
	tax
	rts


e_1296:	jsr	S156f
	ldy	wndtop
	sty	Ze0
	inc	Ze0
	ldy	#$00
.loop1:	jsr	S11c5
	cmp	#$0d
	beq	.fwd3
	cmp	#$7f
	beq	.fwd1
	cmp	#$08
	beq	.fwd1
	sta	D0200,y
	iny
.loop2:	jsr	S1275
	cpy	#$4d
	bcc	.loop1
.loop3:	jsr	S11c5
	cmp	#char_cr
	beq	.fwd3
	cmp	#char_del
	beq	.fwd1
	jsr	bell
	jmp	.loop3

.fwd1:	dey
	bmi	.fwd2
	lda	#$08
	jsr	S1275
	lda	#$20
	jsr	S1275
	lda	#$08
	bne	.loop2		; always taken

.fwd2:	jsr	bell
	ldy	#$00
	beq	.loop1		; always taken

.fwd3:	lda	#$8d
	sta	D0200,y
	iny
	sty	Zc2
	sty	Ze9
	jsr	S1275
.loop4:	lda	D01ff,y
	cmp	#$41
	bcc	.fwd4
	cmp	#$5b
	bcs	.fwd4
	adc	#$20
.fwd4:	sta	(arg1),y
	dey
	bpl	.loop4
	jsr	S1328
	lda	Zc2
	ldx	D172b
	bne	.rtn
	cmp	#$28
	bcc	.rtn
	inc	Ze0
.rtn:	rts


; On entry:
;   A:X  message address
;   Y    message length
msg_out:
	stx	.lda+1
	sta	.lda+2
	ldx	#$00
.loop1:
.lda:	fcb	$bd,$00,$00	; lda $0000,x	; self-modifying code, MUST be absolute, X
	jsr	S1275
	inx
	dey
	bne	.loop1
	rts


L1327:	rts

S1328:	lda	Zdf
	beq	L1327
	lda	hdr_flags2+1
	and	#$01
	beq	L1327
	lda	cswl
	pha
	lda	cswl+1
	pha
	lda	cursrh
	pha
	lda	cur80h
	pha
	lda	D13ad
	sta	cswl
	lda	D13ae
	sta	cswl+1
	lda	#$00
	sta	cursrh
	sta	cur80h
	lda	D13ac
	cmp	#$01
	bne	.fwd1
	inc	D13ac
	lda	#$89
	jsr	cout
	lda	cswl+1
	sta	D13ae
	lda	cswl
	sta	D13ad
	lda	#$b8
	jsr	cout
	lda	#$b0
	jsr	cout
	lda	#$ce
	jsr	cout
	lda	#$8d
	jsr	cout
.fwd1:	ldy	#$00
.loop1:	lda	D0200,y
	jsr	cout
	iny
	dec	Ze9
	bne	.loop1
	pla
	sta	cur80h
	pla
	sta	cursrh
	pla
	sta	cswl+1
	pla
	sta	cswl
	rts


msg_printer_slot
	fcb	char_cr
	text_str	"Printer Slot 1-7: "
msg_len_printer_slot	equ	 *-msg_printer_slot


D13ac:	fcb	$00                     	; "."
D13ad:	fcb	$00                     	; "."
D13ae:	fcb	$00                     	; "."


S13af:	prt_msg	printer_slot
	lda	#$00
	jsr	S0e02
	jsr	S11c5
	cmp	#$0d
	beq	.fwd1
	sec
	sbc	#$30
	cmp	#$08
	bcs	S13af
	bcc	.fwd2
.fwd1:	lda	#$01
.fwd2:	clc
	adc	#$c0
	sta	D13ae
	jsr	S144e
	inc	D13ac
	rts


op_split_window:
	lda	hdr_flags_1
	and	#$20
	beq	L1412
	lda	arg1
	beq	L1413
	ldx	Ze4
	bne	L1412
	cmp	#$14
	bcs	L1412
	pha
	clc
	adc	#$01
	sta	wndbot
	sta	Ze4
	jsr	home
	lda	#$18
	sta	wndbot
	pla
	clc
	adc	#$01
	sta	wndtop
	lda	#$01
	sta	cursrh
	sta	cur80h
	lda	#$16
	sta	cursrv
	jmp	S144e
L1412:	rts

L1413:	lda	#$01
	sta	wndtop
	lda	#$00
	sta	Ze0
	sta	Ze4
	rts


op_set_window:
	lda	hdr_flags_1
	and	#$20
	beq	L1412
	lda	Ze4
	beq	L1412
	lda	arg1
	bne	.fwd1
	sta	Zfb
	lda	#$01
	sta	cursrh
	sta	cur80h
	lda	#$16
	sta	cursrv
	bne	.fwd2		; alway taken

.fwd1:	cmp	#$01
	bne	L1412
	sta	Zfb
	lda	#$00
	sta	cursrh
	sta	cur80h
	sta	cursrv
.fwd2:	jmp	S144e


S144e:	lda	D172b
	beq	.fwd1
	lda	#char_cr
	bne	.fwd2
.fwd1:	lda	#char_cr+$80
.fwd2:	jmp	cout


msg_internal_error:
	text_str	"Internal error "
D146b:	text_str	"00."
msg_len_internal_error	equ	*-msg_internal_error


; On entry:
;   A = error number
int_error:
	cld
	ldy	#$01		; divide error number by 10, storing into message
.loop1:	ldx	#0
.loop2:	cmp	#10
	bcc	.fwd1
	sbc	#10
	inx
	bne	.loop2
.fwd1:	ora	#$30
	sta	D146b,y
	txa
	dey
	bpl	.loop1
	prt_msg	internal_error
; fall into op_quit

op_quit:
	jsr	op_new_line
	prt_msg	end_of_session
	jmp	*		; deliberate hang


msg_end_of_session:
	text_str	"End of story."
	fcb	char_cr
msg_len_end_of_session	equ	*-msg_end_of_session


op_restart:
	ldx	#$00
	stx	wndtop
	lda	hdr_flags2+1
	and	#$01
	beq	.fwd1
	dex
	stx	D13ac
.fwd1:	jmp	restart


msg_interpreter_version:
	text_str	"Apple II Version "
	fcb	$40+(iver&$ff)
	fcb	char_cr
msg_len_interpreter_version	equ	*-msg_interpreter_version


print_interpreter_version:
	jsr	op_new_line
	prt_msg_ret	interpreter_version


S14dc:	lda	#$bf
	rts


S14df:	inc	rndloc
	dec	rndloc+1
	lda	rndloc
	adc	Zf7
	tax
	lda	rndloc+1
	sbc	Zf8
	sta	Zf7
	stx	Zf8
	rts


S14f1:	cmp	#char_cr
	beq	op_new_line
	cmp	#' '
	bcc	.rrn
	ldx	Zdd
	sta	D0200,x
	cpx	Zf6
	bcs	.fwd1
	inc	Zdd
.rrn:	rts

.fwd1:	lda	#$20
.loop1:	cmp	D0200,x
	beq	.fwd2
	dex
	bne	.loop1
	ldx	Zf6
.fwd2:	stx	Zde
	stx	Zdd
	jsr	op_new_line
	ldx	Zde
	ldy	#$00
.loop2:	inx
	cpx	Zf6
	bcc	.fwd3
	beq	.fwd3
	sty	Zdd
	rts

.fwd3:	lda	D0200,x
	sta	D0200,y
	iny
	bne	.loop2		; always taken?


op_new_line:
	lda	Zfb
	bne	.fwd1
	inc	Ze0
.fwd1:	ldx	Zdd
	lda	#$8d
	sta	D0200,x
	inc	Zdd
	ldx	Ze0
	inx
	cpx	wndbot
	bcc	S156f
	jsr	op_show_status
	ldx	wndtop
	inx
	stx	Ze0
	bit	kbd_strb
	prt_msg_alt	more
.loop1:	bit	kbd
	bpl	.loop1
	bit	kbd_strb
	lda	#$00
	sta	cursrh
	sta	cur80h
	jsr	clreol
	ldx	Zdd
	beq	L1588
; fall into S156f


S156f:	ldy	Zdd
	beq	L1588
	sty	Ze9
	ldx	#$00
.loop1:	lda	D0200,x
	jsr	S1275
	inx
	dey
	bne	.loop1
	jsr	S1328
	lda	#$00
	sta	Zdd
L1588:	rts


msg_more:
	text_str	"[MORE]"
msg_len_more	equ	*-msg_more


op_show_status:
	jsr	S156f
	lda	cur80h
	pha
	lda	cursrh
	pha
	lda	cursrv
	pha
	lda	Zdd
	pha
	lda	Z9e
	pha
	lda	Z9d
	pha
	lda	Z9c
	pha
	lda	Zca
	pha
	lda	Zc9
	pha
	lda	Zcf
	pha
	lda	Zce
	pha
	lda	Zcd
	pha
	lda	Zdb
	pha
	lda	wndtop
	pha

	ldx	Zf6
.loop1:	lda	D0200,x
	sta	D3120,x
	lda	#$20
	sta	D0200,x
	dex
	bpl	.loop1

	lda	#$00
	sta	Zdd
	sta	Zdf
	sta	wndtop
	sta	cursrh
	sta	cur80h
	sta	cursrv
	jsr	vtab
	lda	#$3f
	sta	invflg
	lda	#$10
	jsr	S1a03
	lda	Z8c
	jsr	S1cfc
	lda	D172b
	beq	.fwd1
	lda	#$3c
	bne	.fwd2
.fwd1:	lda	#$17
.fwd2:	sta	Zdd
	lda	#$20
	jsr	S14f1
	lda	#$11
	jsr	S1a03
	lda	Zdc
	bne	.fwd3

	lda	#'S'
	jsr	S14f1
	lda	#'c'
	jsr	S14f1
	lda	#'o'
	jsr	S14f1
	lda	#'r'
	jsr	S14f1
	lda	#'e'
	jsr	S14f1
	lda	#':'
	jsr	S14f1
	lda	#' '
	jsr	S14f1
	lda	Z8c
	sta	Zd3
	lda	Z8c+1
	sta	Zd3+1
	jsr	print_num
	lda	#$2f
	bne	.fwd6		; always taken

.fwd3:	lda	#'T'
	jsr	S14f1
	lda	#'i'
	jsr	S14f1
	lda	#'m'
	jsr	S14f1
	lda	#'e'
	jsr	S14f1
	lda	#':'
	jsr	S14f1
	lda	#' '
	jsr	S14f1
	lda	Z8c
	bne	.fwd4
	lda	#$18
.fwd4:	cmp	#char_cr
	bcc	.fwd5
	sbc	#$0c
.fwd5:	sta	Zd3
	lda	#$00
	sta	Zd3+1
	jsr	print_num
	lda	#$3a
.fwd6:	jsr	S14f1
	lda	#$12
	jsr	S1a03
	lda	Z8c
	sta	Zd3
	lda	Z8c+1
	sta	Zd3+1
	lda	Zdc
	bne	.fwd7
	jsr	print_num
	jmp	.fwd11

.fwd7:	lda	Z8c
	cmp	#$0a
	bcs	.fwd8
	lda	#$30
	jsr	S14f1
.fwd8:	jsr	print_num
	lda	#' '
	jsr	S14f1
	lda	#$11
	jsr	S1a03

	lda	Z8c		; print AM or PM
	cmp	#$0c
	bcs	.fwd9
	lda	#'a'
	bne	.fwd10
.fwd9:	lda	#'p'
.fwd10:
	jsr	S14f1
	lda	#'m'
	jsr	S14f1

.fwd11:	ldx	#$00
.loop2:	lda	D0200,x
	jsr	S1275
	inx
	cpx	Zdd
	bcc	.loop2
.loop3:	cpx	wndwdt
	bcs	.fwd12
	lda	#' '+$80
	jsr	cout
	inx
	bne	.loop3
.fwd12:	lda	#$ff
	sta	invflg
	ldx	Zf6
.loop4:	lda	D3120,x
	sta	D0200,x
	dex
	bpl	.loop4
	pla
	sta	wndtop
	pla
	sta	Zdb
	pla
	sta	Zcd
	pla
	sta	Zce
	pla
	sta	Zcf
	pla
	sta	Zc9
	pla
	sta	Zca
	pla
	sta	Z9c
	pla
	sta	Z9d
	pla
	sta	Z9e
	pla
	sta	Zdd
	pla
	sta	cursrv
	pla
	sta	cursrh
	pla
	sta	cur80h
	jsr	vtab
	ldx	#$ff
	stx	Zdf
	inx
	stx	Z9f
	rts


msg_story_loading:
	text_str	"The story is loading ..."
msg_len_story_loading	equ  *-msg_story_loading


D172b:		fcb	$00
romid2_save:	fcb	$00
D172d:		fcb	$00
D172e:		fcb	$00


msg_80_col:
	text_str	"80-COLUMN DISPLAY? (Y/N) >"
msg_len_80_col	equ	*-msg_80_col


; interpreter startup entry point jumped from boot1
interp_start:
	lda	Z2b
	sta	Z60
	sta	Z61

	ldx	#$00
	stx	rwts_sector
	stx	Zec

	inx			; read rest of interpreter starting with track 1
	stx	rwts_track

	stx	Z62
	stx	Z63

	lda	#$18		; starting at $1800
	sta	Zed

	lda	#17		; sector count
	sta	Z8e

.loop1:	jsr	read_sector
	dec	Z8e
	bne	.loop1


	lda	#$ff
	sta	invflg

	lda	romid		; is the computer an Apple IIe or later?
	sta	romid2_save
	cmp	#$06
	bne	.fwd3		;   no

	lda	romid2
	bne	.fwd1
	sta	romid2_save
.fwd1:	lda	rdc3rom
	bmi	.fwd3

	jsr	home
	lda	#$0a
	sta	cursrv
	lda	#$05
	sta	cursrh
	jsr	vtab
	prt_msg	80_col

.loop2:	jsr	rdkey
	cmp	#'n'+$80
	beq	.fwd3
	cmp	#'N'+$80
	beq	.fwd3
	cmp	#'y'+$80
	beq	.fwd2
	cmp	#'Y'+$80
	beq	.fwd2
	jsr	bell
	jmp	.loop2
.fwd2:	jsr	sl3fw
	lda	#$ff
	bne	.fwd4		; always taken

.fwd3:	lda	#$00
.fwd4:	sta	D172b

restart:
	lda	Z61
	ldx	Z63
	sta	D172d
	stx	D172e
	jsr	home
	lda	#$0a
	sta	cursrv
	lda	D172b
	bne	.fwd5
	lda	#$08
	sta	cursrh
	bne	.fwd6
.fwd5:	lda	#$1b
	sta	cursrh
	sta	cur80h
.fwd6:	jsr	vtab
	prt_msg_alt	story_loading

	lda	#$00		; clear interp zero page vars
	ldx	#$80
.loop3:	sta	$00,x
	inx
	bne	.loop3

	tax
	lda	#$ff
.loop4:	sta	D2c00,x
	sta	D2d00,x
	inx
	bne	.loop4
	txa
.loop5:	sta	D2442,x
	inx
	bne	.loop5
	inc	Z94
	inc	Z94+1
	inc	Zdf
	inc	Zaa
	lda	#$32
	sta	Za3
	sta	Zed
	jsr	S0d6b
	ldx	hdr_high_mem
	inx
	stx	Za3+1
	txa
	clc
	adc	Za3
	sta	Za5
	jsr	S14dc
	sec
	sbc	Za5
	beq	int_err_00
	bcs	L1839

int_err_00:
	lda	#$00
	jmp	int_error

L1839:	sta	Za6
	lda	hdr_flags_1
	ora	#$20
	sta	hdr_flags_1
	and	#$02
	sta	Zdc

	lda	hdr_globals
	clc
	adc	Za3
	sta	Zad
	lda	hdr_globals+1
	sta	Zac

	lda	hdr_abbrev
	clc
	adc	Za3
	sta	Zb1
	lda	hdr_abbrev+1
	sta	Zb0

	lda	hdr_vocab
	clc
	adc	Za3
	sta	Zaf
	lda	hdr_vocab+1
	sta	Zae

	lda	hdr_object
	clc
	adc	Za3
	sta	Zb3
	lda	hdr_object+1
	sta	Zb2

.loop6:	lda	Zea
	cmp	Za3+1
	bcs	.fwd7
	jsr	S0d6b
	jmp	.loop6

.fwd7:	lda	hdr_init_pc
	sta	pc+1
	lda	hdr_init_pc+1
	sta	pc

	lda	#$01
	sta	wndtop
	sta	Ze0
	ldx	wndwdt
	dex
	stx	Zf6
	lda	D13ac
	bpl	.fwd8

	lda	hdr_flags2+1
	ora	#$01
	sta	hdr_flags2+1
	lda	#$02
	sta	D13ac

.fwd8:	jsr	home
; fall into main loop

main_loop:
	lda	D13ac
	bne	.fwd9
	lda	hdr_flags2+1
	and	#$01
	beq	.fwd9
	jsr	S13af

.fwd9:	lda	#$00
	sta	argcnt
	jsr	S2336
	sta	opcode
	tax
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
	jsr	S2336
	sta	Z8a
	ldx	#$00
	stx	Z8b
	beq	.fwd1

.loop1:	lda	Z8a
	asl
	asl
	sta	Z8a
.fwd1:	and	#$c0
	bne	.fwd2
	jsr	S19d6
	jmp	.fwd4

.fwd2:	cmp	#$40
	bne	.fwd3
	jsr	S19d2
	jmp	.fwd4

.fwd3:	cmp	#$80
	bne	.fwd5
	jsr	S19ea
.fwd4:	ldx	Z8b
	lda	Z8c
	sta	arg1,x
	lda	Z8c+1
	sta	arg1+1,x
	inc	argcnt
	inx
	inx
	stx	Z8b
	cpx	#$08
	bcc	.loop1
.fwd5:	lda	opcode
	cmp	#$e0
	bcs	.fwd6
	jmp	L19b3
.fwd6:	ldx	#$94
	ldy	#$1b
	and	#$1f
	cmp	#$0c
	bcc	L1935

	lda	#$01
	jmp	int_error

L1935:	stx	Z8e
	sty	Z8e+1
	asl
	tay
	lda	(Z8e),y
	sta	L1946+1
	iny
	lda	(Z8e),y
	sta	L1946+2
L1946:	jsr	$0000
	jmp	main_loop

op_b0_bf:
	ldx	#$26
	ldy	#$1b
	and	#$0f
	cmp	#$0e
	bcc	L1935
	lda	#$02
	jmp	int_error

op_80_af:
	and	#$30
	bne	.fwd1
	jsr	S19d6
	jmp	.fwd3

.fwd1:	cmp	#$10
	bne	.fwd2
	jsr	S19d2
	jmp	.fwd3

.fwd2:	cmp	#$20
	bne	int_err_03
	jsr	S19ea
.fwd3:	jsr	S19c7
	ldx	#$42
	ldy	#$1b
	lda	opcode
	and	#$0f
	cmp	#$10
	bcc	L1935

int_err_03:
	lda	#$03
	jmp	int_error


op_00_7f:
	and	#$40
	bne	.fwd1
	jsr	S19d2
	jmp	.fwd2

.fwd1:	jsr	S19ea
.fwd2:	jsr	S19c7
	lda	opcode
	and	#$20
	bne	.fwd3
	jsr	S19d2
	jmp	.fwd4

.fwd3:	jsr	S19ea
.fwd4:	lda	Z8c
	sta	arg2
	lda	Z8c+1
	sta	arg2+1
	inc	argcnt
L19b3:	ldx	#$62
	ldy	#$1b
	lda	opcode
	and	#$1f
	cmp	#$19
	bcs	int_err_04
	jmp	L1935

int_err_04:
	lda	#$04
	jmp	int_error


S19c7:	lda	Z8c
	sta	arg1
	lda	Z8c+1
	sta	arg1+1
	inc	argcnt
	rts


S19d2:	lda	#$00
	beq	L19d9		; always taken

S19d6:	jsr	S2336
L19d9:	sta	Z8c+1
	jsr	S2336
	sta	Z8c
	rts


S19e1:	tax
	bne	L19ef
	jsr	op_pop
	jmp	push_Z8c

S19ea:	jsr	S2336
	beq	op_pop
L19ef:	cmp	#$10
	bcs	S1a03
	sec
	sbc	#$01
	asl
	tax
	lda	local_vars,x
	sta	Z8c
	lda	local_vars+1,x
	sta	Z8c+1
	rts

S1a03:	jsr	S1a74
	lda	(Z8e),y
	sta	Z8c+1
	iny
	lda	(Z8e),y
	sta	Z8c
	rts

op_pop:	dec	Z94
	beq	int_err_05
	ldy	Z94
	ldx	stk_low_bytes,y
	stx	Z8c
	lda	stk_high_bytes,y
	sta	Z8c+1
	rts


int_err_05:
	lda	#$05
	jmp	int_error


; push word in Z8c onto data stack
push_Z8c:
	ldx	Z8c
	lda	Z8c+1

; push word in A:X onto data stack
push_ax:
	ldy	Z94
	sta	stk_high_bytes,y
	txa
	sta	stk_low_bytes,y
	inc	Z94
	beq	int_err_06	; data stack overflow
	rts


int_err_06:
	lda	#$06
	jmp	int_error


S1a3d:	tax
	bne	L1a53
	dec	Z94
	bne	push_Z8c
	beq	int_err_05	; always taken


; store a zero result into variable (or stack) designated by next byte of program
store_result_zero:
	lda	#$00

; store byte result in Z8c low into variable (or stack) designated by next byte of program
store_result_byte:
	sta	Z8c
	lda	#$00
	sta	Z8c+1

; store result in Z8c into variable (or stack) designated by next byte of program
store_result:
	jsr	S2336
	beq	push_Z8c	; var 0? if yes, push stack
L1a53:	cmp	#$10		; local variable?
	bcs	.fwd2		;   no

; store result in Z8c into local variable specified by A (offset by 1)
	sec
	sbc	#$01
	asl
	tax
	lda	Z8c
	sta	local_vars,x
	lda	Z8c+1
	sta	local_vars+1,x
	rts

; store result in Z8c into global variable specified by A (offset by $10)
.fwd2:	jsr	S1a74
	lda	Z8c+1
	sta	(Z8e),y
	iny
	lda	Z8c
	sta	(Z8e),y
	rts


S1a74:	sec
	sbc	#$10
	ldy	#$00
	sty	Z8e+1
	asl
	rol	Z8e+1
	clc
	adc	Zac
	sta	Z8e
	lda	Z8e+1
	adc	Zad
	sta	Z8e+1
L1a89:	rts


predicate_false:
	jsr	S2336
	bpl	L1a9b
L1a8f:	and	#$40
	bne	L1a89
	jmp	S2336


predicate_true:
	jsr	S2336
	bpl	L1a8f
L1a9b:	tax
	and	#$40
	beq	.fwd1
	txa
	and	#$3f
	sta	Z8c
	lda	#$00
	sta	Z8c+1
	beq	.fwd3		; always taken

.fwd1:	txa
	and	#$3f
	tax
	and	#$20
	beq	.fwd2
	txa
	ora	#$e0
	tax
.fwd2:	stx	Z8c+1
	jsr	S2336
	sta	Z8c
.fwd3:	lda	Z8c+1
	bne	L1ad0
	lda	Z8c
	bne	.fwd4
	jmp	op_rfalse

.fwd4:	cmp	#$01
	bne	L1ad0
	jmp	op_rtrue

L1ad0:	jsr	S1b0a
	jsr	S1b0a
	lda	#$00
	sta	Z8e+1
	lda	Z8c+1
	sta	Z8e
	asl
	rol	Z8e+1
	lda	Z8c
	clc
	adc	pc
	bcc	.fwd5
	inc	Z8e
	bne	.fwd5
	inc	Z8e+1
.fwd5:	sta	pc
	lda	Z8e
	ora	Z8e+1
	beq	op_nop
	lda	Z8e
	clc
	adc	pc+1
	sta	pc+1
	lda	Z8e+1
	adc	Z98
	and	#$01
	sta	Z98
	lda	#$00
	sta	Z99

op_nop:	rts


S1b0a:	lda	Z8c
	sec
	sbc	#$01
	sta	Z8c
	bcs	.rtn
	dec	Z8c+1
.rtn:	rts


S1b16:	inc	Z8c
	bne	.rtn
	inc	Z8c+1
.rtn:	rts


S1b1d:	lda	arg1
	sta	Z8c
	lda	arg1+1
	sta	Z8c+1
	rts


; 0OP instructions (no operands), opcodes $b0..$bf
D1b26:	fdb	op_rtrue
	fdb	op_rfalse
	fdb	op_print	; (literal string)
	fdb	op_print_ret	; (literal string)
	fdb	op_nop		; no-op
	fdb	op_save
	fdb	op_restore
	fdb	op_restart
	fdb	op_ret_popped
	fdb	op_pop
	fdb	op_quit
	fdb	op_new_line
	fdb	op_show_status
	fdb	op_verify


; 1OP instructions (one operand), opcodes $80..$af
D1b42:	fdb	op_jz
	fdb	op_get_sibling
	fdb	op_get_child
	fdb	op_get_parent
	fdb	op_get_prop_len	; get length of prperty (given addr)
	fdb	op_inc
	fdb	op_dec
	fdb	op_print_addr
	fdb	int_err_03
	fdb	op_remove_obj
	fdb	op_print_obj
	fdb	op_ret
	fdb	op_jump
	fdb	op_print_paddr	; print string at word address
	fdb	op_load
	fdb	op_not


; 2OP instructions (two operand), opcodes $20..$7f
; The 2OP table is also used for VAR instructions (0-4 operands), opcodes $c0..$df
D1b62:	fdb	int_err_04	; [illegal]
	fdb	op_je
	fdb	op_jl
	fdb	op_jg
	fdb	op_dec_chk
	fdb	op_inc_chk
	fdb	op_jin		; jump if object a is direct child of object b
	fdb	op_test		; (bitmap)
	fdb	op_or
	fdb	op_and
	fdb	op_test_attr
	fdb	op_set_attr
	fdb	op_clear_attr
	fdb	op_store
	fdb	op_insert_obj
	fdb	op_loadw
	fdb	op_loadb
	fdb	op_get_prop
	fdb	op_get_prop_addr
	fdb	op_get_next_prop
	fdb	op_add
	fdb	op_sub
	fdb	op_mul
	fdb	op_div
	fdb	op_mod
; z-machine version 1 has an addtional instruction here, which
; prints a string at the byte address that is the sum of ARG1
; and ARG2. z-machine version 4 reuses the opcode for call_2s.


; VAR instructions (0-4 operands), opcodes $e0..$ff
	fdb	op_call
	fdb	op_storew
	fdb	op_storeb
	fdb	op_put_prop
	fdb	op_sread
	fdb	op_print_char
	fdb	op_print_num
	fdb	op_random
	fdb	op_push
	fdb	op_pull
	fdb	op_split_window
	fdb	op_set_window


op_rtrue:
	ldx	#$01
L1bae:	lda	#$00
L1bb0:	stx	arg1
	sta	arg1+1
	jmp	op_ret

op_rfalse:
	ldx	#$00
	beq	L1bae


op_print:
	lda	Z98
	sta	Z9e
	lda	pc+1
	sta	Z9d
	lda	pc
	sta	Z9c
	lda	#$00
	sta	Z9f
	jsr	S2554
	ldx	#$05
.loop2:	lda	Z9c,x
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
	jmp	L1bb0


op_verify:
	jsr	print_interpreter_version
	ldx	#$03
	lda	#$00
.loop1:	sta	Z90,x
	sta	Z9c,x
	dex
	bpl	.loop1
	lda	#$40
	sta	Z9c
	lda	hdr_length
	sta	Z8e+1
	lda	hdr_length+1
	asl
	sta	Z8e
	rol	Z8e+1
	rol	acb
	lda	#acb+1		; modify code in S236c subroutine
	sta	L2376+1
.loop2:	jsr	S236c
	clc
	adc	Z90
	sta	Z90
	bcc	.fwd1
	inc	Z90+1
.fwd1:	lda	Z9c
	cmp	Z8e
	bne	.loop2
	lda	Z9d
	cmp	Z8e+1
	bne	.loop2
	lda	Z9e
	cmp	acb
	bne	.loop2
	lda	#Za3+1		
	sta	L2376+1		; modify code in S236c subroutine
	lda	hdr_checksum+1
	cmp	Z90
	bne	L1c41
	lda	hdr_checksum
	cmp	Z90+1
	bne	L1c41
	jmp	predicate_true

L1c41:	jmp	predicate_false


op_jz:	lda	arg1
	ora	arg1+1
	beq	L1c66
L1c4a:	jmp	predicate_false


op_get_sibling:
	lda	arg1
	jsr	setup_object
	ldy	#$05
	bne	L1c5d		; always taken


op_get_child:
	lda	arg1
	jsr	setup_object
	ldy	#$06
L1c5d:	lda	(Z8e),y
	jsr	store_result_byte
	lda	Z8c
	beq	L1c4a
L1c66:	jmp	predicate_true


op_get_parent:
	lda	arg1
	jsr	setup_object
	ldy	#$04
	lda	(Z8e),y
	jmp	store_result_byte


op_get_prop_len:
	lda	arg1+1
	clc
	adc	Za3
	sta	Z8e+1
	lda	arg1
	sec
	sbc	#$01
	sta	Z8e
	bcs	.fwd1
	dec	Z8e+1
.fwd1:	ldy	#$00
	jsr	S27a9
	clc
	adc	#$01
	jmp	store_result_byte


op_inc:	lda	arg1
	jsr	S19e1
	jsr	S1b16
	jmp	L1ca5


op_dec:	lda	arg1
	jsr	S19e1
	jsr	S1b0a
L1ca5:	lda	arg1
	jmp	S1a3d


op_print_addr:
	lda	arg1
	sta	Z8e
	lda	arg1+1
	sta	Z8e+1
	jsr	S2433
	jmp	S2554


op_remove_obj:
	lda	arg1
	jsr	setup_object
	lda	Z8e
	sta	Z90
	lda	Z8e+1
	sta	Z90+1
	ldy	#$04
	lda	(Z8e),y
	beq	.rtn
	jsr	setup_object
	ldy	#$06
	lda	(Z8e),y
	cmp	arg1
	bne	.loop1
	ldy	#$05
	lda	(Z90),y
	iny
	sta	(Z8e),y
	bne	.fwd1
.loop1:	jsr	setup_object
	ldy	#$05
	lda	(Z8e),y
	cmp	arg1
	bne	.loop1
	ldy	#$05
	lda	(Z90),y
	sta	(Z8e),y
.fwd1:	lda	#$00
	ldy	#$04
	sta	(Z90),y
	iny
	sta	(Z90),y
.rtn:	rts


op_print_obj:
	lda	arg1

S1cfc:	jsr	setup_object
	ldy	#$07
	lda	(Z8e),y
	tax
	iny
	lda	(Z8e),y
	sta	Z8e
	stx	Z8e+1
	inc	Z8e
	bne	.fwd1
	inc	Z8e+1
.fwd1:	jsr	S2433
	jmp	S2554


op_ret:	lda	Z94+1
	sta	Z94
	jsr	op_pop
	stx	Z8e+1
	txa
	beq	.fwd1
	dex
	txa
	asl
	sta	Z8e

.loop1:	jsr	op_pop
	ldy	Z8e
	sta	local_vars+1,y
	txa
	sta	local_vars,y
	dec	Z8e
	dec	Z8e
	dec	Z8e+1
	bne	.loop1

.fwd1:	jsr	op_pop
	stx	pc+1
	sta	Z98
	jsr	op_pop
	stx	Z94+1
	sta	pc
	lda	#$00
	sta	Z99
	jsr	S1b1d
	jmp	store_result


op_jump:
	jsr	S1b1d
	jmp	L1ad0


op_print_paddr:
	lda	arg1
	sta	Z8e
	lda	arg1+1
	sta	Z8e+1
	jsr	S2542
	jmp	S2554


op_load:
	lda	arg1
	jsr	S19e1
	jmp	store_result


op_not:	lda	arg1
	eor	#$ff
	tax
	lda	arg1+1
	eor	#$ff
; fall into store_result_ax

; store result in A:X into variable (or stack) designated by next byte of program
store_result_ax:
	stx	Z8c
	sta	Z8c+1
	jmp	store_result


op_jl:	jsr	S1b1d
	jmp	L1d89


op_dec_chk:
	jsr	op_dec
L1d89:	lda	arg2
	sta	Z8e
	lda	arg2+1
	sta	Z8e+1
	jmp	L1db2


op_jg:	lda	arg1
	sta	Z8e
	lda	arg1+1
	sta	Z8e+1
	jmp	L1daa


op_inc_chk:
	jsr	op_inc
	lda	Z8c
	sta	Z8e
	lda	Z8c+1
	sta	Z8e+1
L1daa:	lda	arg2
	sta	Z8c
	lda	arg2+1
	sta	Z8c+1
L1db2:	jsr	S1db9
	bcc	L1def
	bcs	L1ddc

S1db9:	lda	Z8e+1
	eor	Z8c+1
	bpl	L1dc4
	lda	Z8e+1
	cmp	Z8c+1
	rts

L1dc4:	lda	Z8c+1
	cmp	Z8e+1
	bne	L1dce
	lda	Z8c
	cmp	Z8e
L1dce:	rts


; isobject ARG1 in thing ARG2?
op_jin:	lda	arg1
	jsr	setup_object
	ldy	#$04
	lda	(Z8e),y
	cmp	arg2
	beq	L1def
L1ddc:	jmp	predicate_false


op_test:
	lda	arg2
	and	arg1
	cmp	arg2
	bne	L1ddc
	lda	arg2+1
	and	arg1+1
	cmp	arg2+1
	bne	L1ddc
L1def:	jmp	predicate_true


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


; test thing attribute
op_test_attr:
	jsr	setup_attribute
	lda	acb+1
	and	Z90+1
	sta	acb+1
	lda	acb
	and	Z90
	ora	acb+1
	bne	L1def
	jmp	predicate_false


op_set_attr:
	jsr	setup_attribute
	ldy	#$00
	lda	acb+1
	ora	Z90+1
	sta	(Z8e),y
	iny
	lda	acb
	ora	Z90
	sta	(Z8e),y
	rts


op_clear_attr:
	jsr	setup_attribute
	ldy	#$00
	lda	Z90+1
	eor	#$ff
	and	acb+1
	sta	(Z8e),y
	iny
	lda	Z90
	eor	#$ff
	and	acb
	sta	(Z8e),y
	rts


op_store:
	lda	arg2
	sta	Z8c
	lda	arg2+1
	sta	Z8c+1
	lda	arg1
	jmp	S1a3d


op_insert_obj:
	jsr	op_remove_obj
	lda	arg1
	jsr	setup_object
	lda	Z8e
	sta	Z90
	lda	Z8e+1
	sta	Z90+1
	lda	arg2
	ldy	#$04
	sta	(Z8e),y
	jsr	setup_object
	ldy	#$06
	lda	(Z8e),y
	tax
	lda	arg1
	sta	(Z8e),y
	txa
	beq	.rtn
	ldy	#$05
	sta	(Z90),y
.rtn:	rts


op_loadw:
	jsr	S1e94
	jsr	S236c
L1e85:	sta	Z8c+1
	jsr	S236c
	sta	Z8c
	jmp	store_result


op_loadb:
	jsr	S1e98
	beq	L1e85


S1e94:	asl	arg2
	rol	arg2+1

S1e98:	lda	arg2
	clc
	adc	arg1
	sta	Z9c
	lda	arg2+1
	adc	arg1+1
	sta	Z9d
	lda	#$00
	sta	Z9e
	sta	Z9f
	rts


op_get_prop:
	jsr	S2788
.loop1:	jsr	S27a4
	cmp	arg2
	beq	.fwd2
	bcc	.fwd1
	jsr	S27b1
	jmp	.loop1

.fwd1:	lda	arg2
	sec
	sbc	#$01
	asl
	tay
	lda	(Zb2),y
	sta	Z8c+1
	iny
	lda	(Zb2),y
	sta	Z8c
	jmp	store_result

.fwd2:	jsr	S27a9
	iny
	tax
	beq	.fwd3
	cmp	#$01
	beq	.fwd4

	lda	#$07
	jmp	int_error

.fwd3:	lda	(Z8e),y
	ldx	#$00
	beq	.fwd5		; always taken

.fwd4:	lda	(Z8e),y
	tax
	iny
	lda	(Z8e),y
.fwd5:	sta	Z8c
	stx	Z8c+1
	jmp	store_result


op_get_prop_addr:
	jsr	S2788
.loop1:	jsr	S27a4
	cmp	arg2
	beq	.fwd1
	bcc	L1f1e
	jsr	S27b1
	jmp	.loop1

.fwd1:	inc	Z8e
	bne	.fwd2
	inc	Z8e+1
.fwd2:	tya
	clc
	adc	Z8e
	sta	Z8c
	lda	Z8e+1
	adc	#$00
	sec
	sbc	Za3
	sta	Z8c+1
	jmp	store_result

L1f1e:	jmp	store_result_zero


op_get_next_prop:
	jsr	S2788
	lda	arg2
	beq	.fwd2
.loop1:	jsr	S27a4
	cmp	arg2
	beq	.fwd1
	bcc	L1f1e
	jsr	S27b1
	jmp	.loop1

.fwd1:	jsr	S27b1
.fwd2:	jsr	S27a4
	jmp	store_result_byte


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


op_mul:	jsr	S2014
.loop1:	ror	Zd8
	ror	Zd7
	ror	arg2+1
	ror	arg2
	bcc	.fwd1
	lda	arg1
	clc
	adc	Zd7
	sta	Zd7
	lda	arg1+1
	adc	Zd8
	sta	Zd8
.fwd1:	dex
	bpl	.loop1
	ldx	arg2
	lda	arg2+1
	jmp	store_result_ax


op_div:
	jsr	divide
	ldx	Zd3
	lda	Zd3+1
	jmp	store_result_ax


op_mod:
	jsr	divide
	ldx	Zd5
	lda	Zd6
	jmp	store_result_ax


divide:	lda	arg1+1
	sta	Zda
	eor	arg2+1
	sta	Zd9
	lda	arg1
	sta	Zd3
	lda	arg1+1
	sta	Zd3+1
	bpl	.fwd1
	jsr	S1fd0
.fwd1:	lda	arg2
	sta	Zd5
	lda	arg2+1
	sta	Zd6
	bpl	.fwd2
	jsr	S1fc2
.fwd2:	jsr	S1fde
	lda	Zd9
	bpl	.fwd3
	jsr	S1fd0
.fwd3:	lda	Zda
	bpl	L1fcf

S1fc2:	lda	#$00
	sec
	sbc	Zd5
	sta	Zd5
	lda	#$00
	sbc	Zd6
	sta	Zd6
L1fcf:	rts


S1fd0:	lda	#$00
	sec
	sbc	Zd3
	sta	Zd3
	lda	#$00
	sbc	Zd3+1
	sta	Zd3+1
	rts


S1fde:	lda	Zd5
	ora	Zd6
	beq	int_err_08
	jsr	S2014
.loop1:	rol	Zd3
	rol	Zd3+1
	rol	Zd7
	rol	Zd8
	lda	Zd7
	sec
	sbc	Zd5
	tay
	lda	Zd8
	sbc	Zd6
	bcc	.fwd1
	sty	Zd7
	sta	Zd8
.fwd1:	dex
	bne	.loop1
	rol	Zd3
	rol	Zd3+1
	lda	Zd7
	sta	Zd5
	lda	Zd8
	sta	Zd6
	rts


int_err_08:
	lda	#$08
	jmp	int_error


S2014:	ldx	#$10
	lda	#$00
	sta	Zd7
	sta	Zd8
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
	jmp	store_result_byte

.fwd1:	ldx	Z94+1
	lda	pc
	jsr	push_ax
	ldx	pc+1
	lda	Z98
	jsr	push_ax
	lda	#$00
	sta	Z99
	asl	arg1
	rol	arg1+1
	rol
	sta	Z98
	lda	arg1+1
	sta	pc+1
	lda	arg1
	sta	pc
	jsr	S2336
	sta	Z90
	sta	Z90+1
	beq	.fwd2
	lda	#$00
	sta	Z8e
.loop1:	ldy	Z8e
	ldx	local_vars,y
	lda	local_vars+1,y
	sty	Z8e
	jsr	push_ax
	jsr	S2336
	sta	Z8e+1
	jsr	S2336
	ldy	Z8e
	sta	local_vars,y
	lda	Z8e+1
	sta	local_vars+1,y
	iny
	iny
	sty	Z8e
	dec	Z90
	bne	.loop1

; if present, copy arg2 through arg4 to the first local variables
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

.fwd3:	ldx	Z90+1
	txa
	jsr	push_ax
	lda	Z94
	sta	Z94+1
	rts


op_storew:
	asl	arg2
	rol	arg2+1
	jsr	S20fa
	lda	arg3+1
	sta	(Z8e),y
	iny
	bne	L20f5

op_storeb:
	jsr	S20fa
L20f5:	lda	arg3
	sta	(Z8e),y
	rts


S20fa:	lda	arg2
	clc
	adc	arg1
	sta	Z8e
	lda	arg2+1
	adc	arg1+1
	clc
	adc	Za3
	sta	Z8e+1
	ldy	#$00
	rts


op_put_prop:
	jsr	S2788
.loop1:	jsr	S27a4
	cmp	arg2
	beq	.fwd1
	bcc	int_err_0a
	jsr	S27b1
	jmp	.loop1

.fwd1:	jsr	S27a9
	iny
	tax
	beq	.fwd2
	cmp	#$01
	bne	int_err_0b
	lda	arg3+1
	sta	(Z8e),y
	iny
.fwd2:	lda	arg3
	sta	(Z8e),y
	rts


int_err_0a:
	lda	#$0a
	jmp	int_error


int_err_0b:
	lda	#$0b
	jmp	int_error


op_print_char:
	lda	arg1
	jmp	S14f1


op_print_num:
	lda	arg1
	sta	Zd3
	lda	arg1+1
	sta	Zd3+1

print_num:
	lda	Zd3+1
	bpl	.fwd1
	lda	#$2d
	jsr	S14f1
	jsr	S1fd0
.fwd1:	lda	#$00
	sta	Zdb
.loop1:	lda	Zd3
	ora	Zd3+1
	beq	.fwd2
	lda	#$0a
	sta	Zd5
	lda	#$00
	sta	Zd6
	jsr	S1fde
	lda	Zd5
	pha
	inc	Zdb
	bne	.loop1
.fwd2:	lda	Zdb
	bne	.loop2
	lda	#$30
	jmp	S14f1

.loop2:	pla
	clc
	adc	#$30
	jsr	S14f1
	dec	Zdb
	bne	.loop2
	rts


op_random:
	lda	arg1
	sta	arg2
	lda	arg1+1
	sta	arg2+1
	jsr	S14df
	stx	arg1
	and	#$7f
	sta	arg1+1
	jsr	divide
	lda	Zd5
	sta	Z8c
	lda	Zd6
	sta	Z8c+1
	jsr	S1b16
	jmp	store_result


op_push:
	ldx	arg1
	lda	arg1+1
	jmp	push_ax


op_pull:
	jsr	op_pop
	lda	arg1
	jmp	S1a3d


op_sread:
	jsr	op_show_status
	lda	arg1+1
	clc
	adc	Za3
	sta	arg1+1
	lda	arg2+1
	clc
	adc	Za3
	sta	arg2+1
	jsr	e_1296
	sta	Zc2
	lda	#$00
	sta	Zc3
	ldy	#$01
	sta	(arg2),y
	sty	Zc0
	iny
	sty	Zc1
.loop1:	ldy	#$00
	lda	(arg2),y
	beq	.fwd1
	cmp	#$3c
	bcc	.fwd2
.fwd1:	lda	#$3b
	sta	(arg2),y
.fwd2:	iny
	cmp	(arg2),y
	bcc	.rtn
	lda	Zc2
	ora	Zc3
	bne	.fwd3
.rtn:	rts

.fwd3:	lda	Zc3
	cmp	#$06
	bcc	.fwd4
	jsr	S228d
.fwd4:	lda	Zc3
	bne	.fwd6
	ldx	#$05
.loop2:	sta	Zb4,x
	dex
	bpl	.loop2
	jsr	S227f
	lda	Zc0
	ldy	#$03
	sta	(Zc4),y
	tay
	lda	(arg1),y
	jsr	S22ba
	bcs	.fwd7
	jsr	S22a8
	bcc	.fwd6
	inc	Zc0
	dec	Zc2
	jmp	.loop1

.fwd6:	lda	Zc2
	beq	.fwd8
	ldy	Zc0
	lda	(arg1),y
	jsr	S22a3
	bcs	.fwd8
	ldx	Zc3
	sta	Zb4,x
	dec	Zc2
	inc	Zc3
	inc	Zc0
	jmp	.loop1

.fwd7:	sta	Zb4
	dec	Zc2
	inc	Zc3
	inc	Zc0
.fwd8:	lda	Zc3
	beq	.loop1
	jsr	S227f
	lda	Zc3
	ldy	#$02
	sta	(Zc4),y
	jsr	S2670
	jsr	S22cc
	ldy	#$01
	lda	(arg2),y
	clc
	adc	#$01
	sta	(arg2),y
	jsr	S227f
	ldy	#$00
	sty	Zc3
	lda	Z8c+1
	sta	(Zc4),y
	iny
	lda	Z8c
	sta	(Zc4),y
	lda	Zc1
	clc
	adc	#$04
	sta	Zc1
	jmp	.loop1


S227f:	lda	arg2
	clc
	adc	Zc1
	sta	Zc4
	lda	arg2+1
	adc	#$00
	sta	Zc5
	rts

S228d:	lda	Zc2
	beq	.rtn
	ldy	Zc0
	lda	(arg1),y
	jsr	S22a3
	bcs	.rtn
	dec	Zc2
	inc	Zc3
	inc	Zc0
	bne	S228d
.rtn:	rts


S22a3:	jsr	S22ba
	bcs	L22ca

S22a8:	ldx	#$05
L22aa:	cmp	D22b4,x
	beq	L22ca
	dex
	bpl	L22aa
	clc
	rts


D22b4:	fcb	$21,$3f,$2c,$2e,$8d,$20      	; "!?,.. "


S22ba:	tax
	ldy	#$00
	lda	(Zae),y
	tay
	txa
.loop1:	cmp	(Zae),y
	beq	L22ca
	dey
	bne	.loop1
	clc
	rts
L22ca:	sec
	rts


S22cc:	ldy	#$00
	lda	(Zae),y
	clc
	adc	#$01
	adc	Zae
	sta	Z8c
	lda	Zaf
	adc	#$00
	sta	Z8c+1
	lda	(Z8c),y
	sta	Zc8
	jsr	S1b16
	lda	(Z8c),y
	sta	Zc7
	jsr	S1b16
	lda	(Z8c),y
	sta	Zc6
	jsr	S1b16
.loop1:	ldy	#$00
	lda	(Z8c),y
	cmp	Zba
	bne	.fwd1
	iny
	lda	(Z8c),y
	cmp	Zbb
	bne	.fwd1
	iny
	lda	(Z8c),y
	cmp	Zbc
	bne	.fwd1
	iny
	lda	(Z8c),y
	cmp	Zbd
	beq	.fwd4
.fwd1:	lda	Zc8
	clc
	adc	Z8c
	sta	Z8c
	bcc	.fwd2
	inc	Z8c+1
.fwd2:	lda	Zc6
	sec
	sbc	#$01
	sta	Zc6
	bcs	.fwd3
	dec	Zc7
.fwd3:	ora	Zc7
	bne	.loop1
	sta	Z8c
	sta	Z8c+1
	rts

.fwd4:	lda	Z8c+1
	sec
	sbc	Za3
	sta	Z8c+1
	rts


S2336:	lda	Z99
	bne	.fwd3
	lda	pc+1
	ldy	Z98
	bne	.fwd1
	cmp	Za3+1
	bcs	.fwd1
	adc	Za3
	bne	.fwd2
.fwd1:	ldx	#$00
	stx	Z9f
	jsr	S23a2
.fwd2:	sta	Z9b
	ldx	#$ff
	stx	Z99
	inx
	stx	Z9a
.fwd3:	ldy	pc
	lda	(Z9a),y
	inc	pc
	bne	.fwd4
	ldy	#$00
	sty	Z99
	inc	pc+1
	bne	.fwd4
	inc	Z98
.fwd4:	tay
	rts


S236c:	lda	Z9f
	bne	L238e
	lda	Z9d
	ldy	Z9e
	bne	L237e
L2376:	cmp	Za3+1		; self-modifying code, operand modified
	bcs	L237e
	adc	Za3
	bne	L2385
L237e:	ldx	#$00
	stx	Z99
	jsr	S23a2
L2385:	sta	Za1
	ldx	#$ff
	stx	Z9f
	inx
	stx	Za0
L238e:	ldy	Z9c
	lda	(Za0),y
	inc	Z9c
	bne	.fwd4
	ldy	#$00
	sty	Z9f
	inc	Z9d
	bne	.fwd4
	inc	Z9e
.fwd4:	tay
	rts


S23a2:	sta	Za8
	sty	Za9
	ldx	#$00
	stx	Za7
.loop1:	cmp	D2c00,x
	bne	.loop2
	tya
	cmp	D2d00,x
	beq	.fwd1
	lda	Za8
.loop2:	inc	Za7
	inx
	cpx	Za6
	bcc	.loop1
	jsr	S2419
	ldx	Zab
	stx	Za7
	lda	Za8
	sta	D2c00,x
	sta	Zea
	lda	Za9
	and	#$01
	sta	D2d00,x
	sta	Zeb
	txa
	clc
	adc	Za5
	sta	Zed
	jsr	S0d6b
	bcs	int_err_0e
.fwd1:	ldy	Za7
	lda	D2442,y
	cmp	Zaa
	beq	.fwd4
	inc	Zaa
	bne	.fwd3
	jsr	S2419
	ldx	#$00
.loop3:	lda	D2442,x
	beq	.fwd2
	sec
	sbc	Za2
	sta	D2442,x
.fwd2:	inx
	cpx	Za6
	bcc	.loop3
	lda	#$00
	sec
	sbc	Za2
	sta	Zaa
.fwd3:	lda	Zaa
	sta	D2442,y
.fwd4:	lda	Za7
	clc
	adc	Za5
	rts


int_err_0e:
	lda	#$0e
	jmp	int_error


S2419:	ldx	#$00
	stx	Zab
	lda	D2442
	inx
.loop1:	cmp	D2442,x
	bcc	.fwd1
	lda	D2442,x
	stx	Zab
.fwd1:	inx
	cpx	Za6
	bcc	.loop1
	sta	Za2
	rts


S2433:	lda	Z8e
	sta	Z9c
	lda	Z8e+1
	sta	Z9d
	lda	#$00
	sta	Z9e
	sta	Z9f
	rts


D2442:	fcb	[256]$00


S2542:	lda	Z8e
	asl
	sta	Z9c
	lda	Z8e+1
	rol
	sta	Z9d
	lda	#$00
	sta	Z9f
	rol
	sta	Z9e
L2553:	rts


S2554:	ldx	#$00
	stx	Zc9
	stx	Zcd
	dex
	stx	Zca
.loop1:	jsr	S2628
	bcs	L2553
	sta	Zcb
	tax
	beq	.fwd4
	cmp	#$04
	bcc	.fwd7
	cmp	#$06
	bcc	.fwd5
	jsr	S261c
	tax
	bne	.fwd1
	lda	#$5b
.loop2:	clc
	adc	Zcb
.loop3:	jsr	S14f1
	jmp	.loop1

.fwd1:	cmp	#$01
	bne	.fwd2
	lda	#$3b
	bne	.loop2
.fwd2:	lda	Zcb
	sec
	sbc	#$06
	beq	.fwd3
	tax
	lda	D2745,x
	jmp	.loop3

.fwd3:	jsr	S2628
	asl
	asl
	asl
	asl
	asl
	sta	Zcb
	jsr	S2628
	ora	Zcb
	jmp	.loop3

.fwd4:	lda	#$20
	bne	.loop3		; always taken

.fwd5:	sec
	sbc	#$03
	tay
	jsr	S261c
	bne	.fwd6
	sty	Zca
	jmp	.loop1

.fwd6:	sty	Zc9
	cmp	Zc9
	beq	.loop1
	lda	#$00
	sta	Zc9
	beq	.loop1		; alway taken

.fwd7:	sec
	sbc	#$01
	asl
	asl
	asl
	asl
	asl
	asl
	sta	Zcc
	jsr	S2628
	asl
	clc
	adc	Zcc
	tay
	lda	(Zb0),y
	sta	Z8e+1
	iny
	lda	(Zb0),y
	sta	Z8e
	lda	Z9e
	pha
	lda	Z9d
	pha
	lda	Z9c
	pha
	lda	Zc9
	pha
	lda	Zcd
	pha
	lda	Zcf
	pha
	lda	Zce
	pha
	jsr	S2542
	jsr	S2554
	pla
	sta	Zce
	pla
	sta	Zcf
	pla
	sta	Zcd
	pla
	sta	Zc9
	pla
	sta	Z9c
	pla
	sta	Z9d
	pla
	sta	Z9e
	ldx	#$ff
	stx	Zca
	inx
	stx	Z9f
	jmp	.loop1


S261c:	lda	Zca
	bpl	.fwd1
	lda	Zc9
	rts

.fwd1:	ldy	#$ff
	sty	Zca
	rts


S2628:	lda	Zcd
	bpl	.fwd1
	sec
	rts

.fwd1:	bne	.fwd2
	inc	Zcd
	jsr	S236c
	sta	Zcf
	jsr	S236c
	sta	Zce
	lda	Zcf
	lsr
	lsr
	jmp	.fwd5

.fwd2:	sec
	sbc	#$01
	bne	.fwd3
	lda	#$02
	sta	Zcd
	lda	Zce
	sta	Z8e
	lda	Zcf
	asl	Z8e
	rol
	asl	Z8e
	rol
	asl	Z8e
	rol
	jmp	.fwd5

.fwd3:	lda	#$00
	sta	Zcd
	lda	Zcf
	bpl	.fwd4
	lda	#$ff
	sta	Zcd
.fwd4:	lda	Zce
.fwd5:	and	#$1f
	clc
	rts


S2670:	lda	#$05
	tax
.loop1:	sta	Zba,x
	dex
	bpl	.loop1
	lda	#$06
	sta	Zd0
	lda	#$00
	sta	Zd1
	sta	Zd2
.loop2:	ldx	Zd1
	inc	Zd1
	lda	Zb4,x
	sta	Zcb
	bne	.fwd1
	lda	#$05
	bne	.loop3		; alway taken

.fwd1:	lda	Zcb
	jsr	S2706
	beq	.fwd3
	clc
	adc	#$03
	ldx	Zd2
	sta	Zba,x
	inc	Zd2
	dec	Zd0
	bne	.fwd2
	jmp	L271f

.fwd2:	lda	Zcb
	jsr	S2706
	cmp	#$02
	beq	.fwd4
	lda	Zcb
	sec
	sbc	#$3b
	bpl	.loop3
.fwd3:	lda	Zcb
	sec
	sbc	#$5b
.loop3:	ldx	Zd2
	sta	Zba,x
	inc	Zd2
	dec	Zd0
	bne	.loop2
	jmp	L271f

.fwd4:	lda	Zcb
	jsr	S26f6
	bne	.loop3
	lda	#$06
	ldx	Zd2
	sta	Zba,x
	inc	Zd2
	dec	Zd0
	beq	L271f
	lda	Zcb
	lsr
	lsr
	lsr
	lsr
	lsr
	and	#$03
	ldx	Zd2
	sta	Zba,x
	inc	Zd2
	dec	Zd0
	beq	L271f
	lda	Zcb
	and	#$1f
	jmp	.loop3


S26f6:	ldx	#$19
.loop1:	cmp	D2745,x
	beq	.fwd1
	dex
	bne	.loop1
	rts

.fwd1:	txa
	clc
	adc	#$06
	rts


S2706:	cmp	#$61
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


L271f:	lda	Zbb
	asl
	asl
	asl
	asl
	rol	Zba
	asl
	rol	Zba
	ora	Zbc
	sta	Zbb
	lda	Zbe
	asl
	asl
	asl
	asl
	rol	Zbd
	asl
	rol	Zbd
	ora	Zbf
	tax
	lda	Zbd
	ora	#$80
	sta	Zbc
	stx	Zbd
	rts


D2745:	fcb	$00,char_cr
	fcb	"0123456789"
	fcb	".,!?_#'"
	fcb	$22		; double quote
	fcb	"/"
	fcb	"\\"		; this is a single backslash, escaped
	fcb	"-:()"


setup_object:
	sta	Z8e
	ldx	#$00
	stx	Z8e+1
	asl
	rol	Z8e+1
	asl
	rol	Z8e+1
	asl
	rol	Z8e+1
	clc
	adc	Z8e
	bcc	.fwd1
	inc	Z8e+1
.fwd1:	clc
	adc	#$35
	bcc	.fwd2
	inc	Z8e+1
.fwd2:	clc
	adc	Zb2
	sta	Z8e
	lda	Z8e+1
	adc	Zb3
	sta	Z8e+1
	rts


S2788:	lda	arg1
	jsr	setup_object
	ldy	#$07
	lda	(Z8e),y
	clc
	adc	Za3
	tax
	iny
	lda	(Z8e),y
	sta	Z8e
	stx	Z8e+1
	ldy	#$00
	lda	(Z8e),y
	asl
	tay
	iny
	rts


S27a4:	lda	(Z8e),y
	and	#$1f
	rts


S27a9:	lda	(Z8e),y
	lsr
	lsr
	lsr
	lsr
	lsr
	rts


S27b1:	jsr	S27a9
	tax
.loop1:	iny
	dex
	bpl	.loop1
	iny
	rts


; set up for attribute operations on object ARG1
setup_attribute:
	lda	arg1
	jsr	setup_object
	lda	arg2
	cmp	#$10
	bcc	.fwd2
	sbc	#$10
	tax
	lda	Z8e
	clc
	adc	#$02
	sta	Z8e
	bcc	.fwd1
	inc	Z8e+1
.fwd1:	txa
.fwd2:	sta	acb
	ldx	#$01
	stx	Z90
	dex
	stx	Z90+1
	lda	#$0f
	sec
	sbc	acb
	tax
	beq	.fwd3
.loop1:	asl	Z90
	rol	Z90+1
	dex
	bne	.loop1
.fwd3:	ldy	#$00
	lda	(Z8e),y
	sta	acb+1
	iny
	lda	(Z8e),y
	sta	acb
	rts


	fillto	$2800,$00
