; Infocom EZIP (Z-Machine architecture v4) interpreter for Apple II,

; The EZIP interpreter is copyrighted by Infocom, Inc.

; This partially reverse-engineered source code is
; Ccopyright 2023 Eric Smith <spacewar@gmail.com>

	cpu	6502

; The differences between revisions stated here is not comprehensizve.

iver_a	equ	$0501	; Released with:
			;    Beyond Zork r49 870917

iver_c	equ	$0503	; Released with:
			;    Border Zone r9 871008

iver_e	equ	$0505	; Released with:
			;    Hitchhiker's Guide to the Galaxy
			;        (Solid Gold) r31 871119
			;    Zork I (Solid Gold) r52 871125

iver_f	equ	$0506	; Released with:
			;    Sherlock r21 871214
			;    Beyond Zork r57 871221

iver_h	equ	$0508	; Released with:
			;    Sherlock r26 880127 (need to verify interpreter)
			;    Leather Goddesses of Phobos
			;        (Solid Gold) r4 880405
			;    Planetfall (Solid Gold) r10 880531
			;    Wishbringer (Sold Gold) r23 880706


char_tab	equ	$09
char_cr		equ	$0d
char_del	equ	$7f


	ifndef	iver
iver	equ	iver_a
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

; A macro is used for text string beause different versions
; of EZIP used the high bit set or not.
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

; macro to fetch one byte from the PC and increment the PC
; Post-condition:
;   A = fetched byte
;   Y = fetched byte
fetch_pc_byte_inline	macro
	ldy	pc_phys_page+2
	sta	rd_main_ram,y	; indexed to get main or card RAM
	ldy	pc
	lda	(pc_phys_page),y
	sta	rd_main_ram	; set back to main RAM
	inc	pc
	bne	.no_page_cross
	jsr	advance_pc_page
.no_page_cross:
	tay
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
		org	$0000

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
wndtop	equ	$22
wndbot	equ	$23
cursrh	equ	$24
cursrv	equ	$25
bas2l	equ	$2a
invflg	equ	$32
cswl	equ	$36
rndloc	equ	$4e


; interpreter zero page variables
interp_zp_origin	equ	$56
	org	interp_zp_origin

opcode:		rmb	1
argcnt:		rmb	1

arg1:		rmb	2
arg2:		rmb	2
arg3:		rmb	2
arg4:		rmb	2
arg5:		rmb	2
arg6:		rmb	2
arg7:		rmb	2
arg8:		rmb	2

Z68:		rmb	1
Z69:		rmb	1
Z6a:		rmb	1

acc:		rmb	2

Z6d:		rmb	2
Z6f:		rmb	2
Z71:		rmb	2
Z73:		rmb	2

pc:		rmb	3
pc_phys_page:	rmb	3	; physical address of page holding current PC
				; third byte is 0/1 for page in main/aux RAM

aux_ptr:	rmb	3
aux_phys_page:	rmb	3	; physical address of page holding current aux ptr
				; third byte is 0/1 for page in main/aux RAM

first_ram_page:	rmb	1

Z82:		if	iver<=iver_c
		rmb	1
		else
		rmb	2
		endif

Z83:		rmb	1

Z84:		rmb	1
		rmb	2
Z87:		rmb	1
Z88:		rmb	1
Z89:		rmb	1
Z8a:		rmb	1
Z8b:		rmb	1
Z8c:		rmb	1	; new compared to EZIP?
Z8d:		rmb	1	; new compared to EZIP?
		rmb	8
Z96:		rmb	1
Z97:		rmb	1
Z98:		rmb	1
Z99:		rmb	1
Z9a:		rmb	1

Z9b:		rmb	1
Z9c:		rmb	1
Z9d:		rmb	1
Z9e:		rmb	1
Z9f:		rmb	1
Za0:		rmb	1
Za1:		rmb	1
Za2:		rmb	1
Za3:		rmb	1
Za4:		rmb	1
Za5:		rmb	1
Za6:		rmb	1
Za7:		rmb	1
Za8:		rmb	1
Za9:		rmb	1
Zaa:		rmb	1
Zab:		rmb	1
Zac:		rmb	1
Zad:		rmb	1
Zae:		rmb	1
Zaf:		rmb	1
Zb0:		rmb	1
Zb1:		rmb	1
Zb2:		rmb	1
Zb3:		rmb	1
Zb4:		rmb	1

disk_block_num:	rmb	2

Zb7:		rmb	1
Zb8:		rmb	1
		rmb	2
Zbb:		rmb	1
Zbc:		rmb	1
Zbd:		rmb	1
Zbe:		rmb	1
Zbf:		rmb	1
		rmb	2
Zc2:		rmb	1
Zc3:		rmb	1
Zc4:		rmb	1
Zc5:		rmb	2
Zc7:		rmb	1
Zc8:		rmb	1
Zc9:		rmb	1
Zca:		rmb	1
Zcb:		rmb	1
Zcc:		rmb	2
Zce:		rmb	2

		if	iver<=iver_c
Zd0:		rmb	2
		endif

Zd2:		rmb	1
Zd3:		rmb	1
Zd4:		rmb	1
Zd5:		rmb	1
Zd6:		rmb	1
Zd7:		rmb	1
Zd8:		rmb	1
Zd9:		rmb	1
Zda:		rmb	1
		rmb	1
Zdc:		rmb	1
		rmb	1
Zde:		rmb	1
		rmb	4
Ze3:		rmb	1
		rmb	2
Ze6:		rmb	1
Ze7:		rmb	1
Ze8:		rmb	1
Ze9:		rmb	1
Zea:		rmb	1
		rmb	1
Zec:		rmb	1
Zed:		rmb	2
		rmb	1
stk_ptr:	rmb	2
Zf2:		rmb	2
		rmb	2
ostream_1_state:	rmb	1
ostream_2_state:	rmb	1
ostream_3_state:	rmb	1
Zf9:		rmb	1
Zfa:		rmb	1
Zfb:		rmb	1
Zfc:		rmb	1


D0100	equ	$0100

D0200	equ	$0200

D057b	equ	$057b

D0855	equ	$0855
S0856	equ	$0856
S08a9	equ	$08a9
L08b7	equ	$08b7
S08c5	equ	$08c5
S08e1	equ	$08e1
S08ef	equ	$08ef
S090b	equ	$090b
S0927	equ	$0927
S093b	equ	$093b
S095e	equ	$095e

	org	$0a00
rwts_sec_buf_size	equ	86

rwts_data_buf:	rmb	256	; user data
rwts_pri_buf:	rmb	256	; disk nibbles
rwts_sec_buf:	rmb	86	; disk nibbles

		align	$0080

local_vars:	rmb	32

D0ca0:		rmb	2	; save hdr_game_ver
D0ca2:		rmb	2	; save stk_ptr
D0ca4:		rmb	2	; save Zf2
D0ca6:		rmb	3	; save PC
D0ca9:		rmb	1
D0caa:		rmb	50	; size unknown

		align	$0100

D0d00:		rmb	$80
D0d80:		rmb	$80
D0e00:		rmb	$80
D0e80:		rmb	$80

D0f00:		rmb	$0100
D1000:		rmb	$0100
D1100:		rmb	$0100
D1200:		rmb	$0100

max_main_ram_addr	equ	$c000

max_main_ram_pages	equ	(max_main_ram_addr-*)>>8


; game header

hdr_arch:	rmb	1	; Z-machine architecture version
hdr_flags_1:	rmb	1	; flags 1
hdr_game_ver:	rmb	2	; game version
hdr_high_mem:	rmb	2	; base of high memory
hdr_main_routine: rmb	2	; packed address of initial main routine
				; in prev arch, was just the initial PC
hdr_vocab:	rmb	2	; location of dictionary
hdr_object:	rmb	2	; object table
hdr_globals:	rmb	2	; global variable table
hdr_pure:	rmb	2	; base of pure (immutable) memory
hdr_flags2:	rmb	2	; flags 2
		rmb	6	; "serial" (usually game release date)
hdr_abbrev:	rmb	2	; abbreviation table
hdr_length:	rmb	2	; length of file (divided by 4 for v4 and v5)
hdr_checksum:	rmb	2	; checksum of file
hdr_interp_platform: rmb 1	; interpreter platform number
hdr_interp_rev:	rmb	1	; interpretr revision
hdr_screen_height: rmb	1	; screen height, lines of text
hdr_scr_width:	rmb	1	; screen width, characters
hdr_scr_width_units: rmb 2	; screen width, "units"
hdr_scr_height_units: rmb 2	; screeen height, "units"
hdr_font_width_units: rmb 1	; font width, "units"
hdr_font_height_units: rmb 1	; font height, "units"
		rmb	1	; unused
hdr_unknown_29:	rmb	1	; undocumented for v5 arch
		rmb	1	; unused
hdr_unknown_2b:	rmb	1	; undocumented for v5 arch
		rmb	1	; default background color
		rmb	1	; default foreground color
hdr_term_char_tbl: rmb 2	; addr of terminating characters table (bytes)
hdr_os3_pixels_sent: rmb 2	; total width of pixels of text sent to output stream 3
hdr_std_rev_num: rmb	2
		rmb	2	; alphabet table address (bytes), 0 for default
		rmb	2	; header extension table address (byters)


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

Dc061	equ	$c061
Dc062	equ	$c062

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


; Apple II monitor ROM locations
; These are named prefaced with mon_ because the ROM isn't mapped,
; so trampoline functions in low memory are used to call them.
mon_cout1	equ	$fdf0


	org	$d000

rwts:
	nop
	nop
	nop
	php
	sei
	jsr	rwts_inner
	bcs	Ld00d
	plp
	clc
	rts
Ld00d:	plp
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


write_data_field:
	stx	Z0e
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

; read prinary buffer in forward order
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
	bcs	.loop9

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
	bcc	.fwd14		; unnecessary
	sec
	bcs	.fwd14

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

.fwd18:	jsr	write_data_field
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

; read 86 nibbles into secondary buffer, reverse order
.loop7:	ldy	#rwts_sec_buf_size
	lda	#$00
.loop8:	dey
	sty	Z0d
.loop9:	ldy	q6l,x
	bpl	.loop9
	eor	denib_tab,y
	ldy	Z0d
	sta	rwts_sec_buf,y
	bne	.loop8

; read 256 nibbles into primary buffer, forward order
.loop10:
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
	ldy	q6l,x
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


; subrutine called by boot1
Sd505:	lda	text_on
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

	if	iver<=iver_c

	cpx	#$01		; is the block number greater than $100
	bcc	.fwd5		;   under $100, 16-sector
	bne	.fwd1		;   $200 or over, 18-sector
	cpy	#$8a		; is the block number greater than $18a
	bcc	.fwd5		;   under $18as, 16-sector

	else

	cpx	Z82+1		; is the block number greater than?
	bcc	.fwd5		;   under $100, 16-sector
	bne	.fwd1		;   $200 or over, 18-sector
	cpy	Z82		; is the block number greater than?
	bcc	.fwd5		;   under $18as, 16-sector

	endif

; 18-sector
.fwd1:	lda	Zec
	cmp	#$02
	beq	.fwd2
	jsr	Sd899

	ldx	disk_block_num+1	; subtract $18a to get side B relative block number
	ldy	disk_block_num
.fwd2:	tya

	if	iver<=iver_c

	sec
	sbc	#$8a
	tay
	txa
	sbc	#$01
	tax
	tya

	else

	sec
	sbc	Z82
	tay
	txa
	sbc	Z82+1
	tax
	tya

	endif


; restoring division by 18 sectors/track for side B
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
	cmp	#35		; max track is 34
	bcc	.no_int_err_0c
	jmp	int_err_0c

.no_int_err_0c:
	lda	#$84
	bne	.fwd7		; always taken

; 16-sector
.fwd5:	lda	Zec
	cmp	#$01
	beq	.fwd6
	jsr	Sd871

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
	adc	#4		; first track of side A image
	cmp	#35		; max track is 34
	bcs	int_err_0c
	sta	rwts_track
	lda	#$00

; 16- and 18-sector paths rejoin here
.fwd7:	sta	rd_main_ram
	jsr	rwts
	bcs	int_err_0e
	ldy	Df090
	sta	wr_main_ram,y	; indexed to get main or card

	ldy	#$00
.loop2:	lda	rwts_data_buf,y
	sta	(Zb7),y
	iny
	bne	.loop2

	sta	wr_main_ram
	inc	disk_block_num
	bne	.fwd8
	inc	disk_block_num+1
.fwd8:	inc	Zb8
	lda	Zb8
	cmp	#$c0
	bcc	.rtn
	lda	#$08
	sta	Zb8
	lda	#$01
	sta	Df090
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
	cpx	#35		; max track is 34
	bcs	Ld5f3
	stx	rwts_track
.fwd1:	sta	rwts_sector
	inc	Zb8
	clc
	rts


Sd5df:	ldy	#$00
	sta	rd_main_ram
.loop1:	lda	(Zb7),y
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
	lda	#$00		; read command
	jsr	rwts
	bcs	int_err_0e_alt
	ldy	#$00
	sta	rd_main_ram

.loop1:	lda	rwts_data_buf,y
	sta	(Zb7),y
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
	cpx	#$23		; max track is 34
	bcs	Ld5f3
	stx	rwts_track
.noinctrk:
	sta	rwts_sector
	inc	Zb8
	clc
	rts

; end of low-level disk routines


Sd62f:	jsr	new_line
	lda	#$00
	sta	Zd9
	rts


msg_default_is:
	text_str	" (Default is "
Dd644:	text_str	"*) >"
msg_len_default_is	equ	*-msg_default_is


; On entry
;   A = default value - 1
Sd648:	clc
	adc	#'1'
	sta	Dd644
	prt_msg_ret	default_is


max_save_position:
	fcb	$00


msg_position:
	fcb	char_cr
	text_str	"Position 1-"
msg_position_max_ascii:	text_str	"*"
msg_len_position	equ	*-msg_position


msg_drive:
	fcb	char_cr
	text_str	"Drive 1 or 2"
msg_len_drive	equ	*-msg_drive


msg_slot:
	fcb	char_cr
	text_str	"Slot 1-7"
msg_len_slot	equ	*-msg_slot


Dd67b:	fcb	$05


msg_pos_drive_slot_verify:
	fcb	char_cr,char_cr
	text_str	"Position "
Dd687:	text_str	"*; Drive #"
Dd691:	text_str	"*; Slot "
Dd699:	text_str	"*."
	fcb	char_cr
	text_str	"Are you sure? (Y/N) >"
msg_len_pos_drive_slot_verify	equ    *-msg_pos_drive_slot_verify


msg_insert_save:
	fcb	char_cr
	text_str	"Insert SAVE disk into Drive #"
Dd6cf:	text_str	"*."
msg_len_insert_save	equ	*-msg_insert_save


msg_yes:
	text_str	"YES"
	fcb	char_cr
msg_len_yes	equ	*-msg_yes


msg_no:
	text_str	"NO"
	fcb	char_cr
msg_len_no	equ	*-msg_no


Sd6d8:	prt_msg	position
	lda	Ze6
	jsr	Sd648
.loop1:	bit	kbd_strb
	jsr	Sfd3f
	cmp	#char_cr
	beq	.fwd1
	sec
	sbc	#'1'
	cmp	max_save_position
	bcc	.fwd2
	jsr	Sdcfb
	jmp	.loop1

.fwd1:	lda	Ze6
.fwd2:	sta	Ze8
	clc
	adc	#'1'
	sta	Dd687
	sta	Dd8ec
	sta	Dd9dc
	ora	#$80
	jsr	Sdb39
	prt_msg	drive
	lda	Ze7
	jsr	Sd648
.loop2:	bit	kbd_strb
	jsr	Sfd3f
	cmp	#char_cr
	beq	.fwd3
	sec
	sbc	#'1'
	cmp	#2
	bcc	.fwd4
	jsr	Sdcfb
	jmp	.loop2

.fwd3:	lda	Ze7
.fwd4:	sta	Ze9
	clc
	adc	#'1'
	sta	Dd6cf
	sta	Dd691
	ora	#$80
	jsr	Sdb39

	lda	romid2_save	; IIc family?
	bne	.fwd5		;   no
	lda	#$05		; yes, force slot 6
	bne	.fwd7

.fwd5:	prt_msg	slot
	lda	Dd67b
	jsr	Sd648
.loop3:	bit	kbd_strb
	jsr	Sfd3f
	cmp	#char_cr
	beq	.fwd6
	sec
	sbc	#'1'
	cmp	#$07
	bcc	.fwd7
	jsr	Sdcfb
	jmp	.loop3
.fwd6:	lda	Dd67b
.fwd7:	sta	Zea
	clc
	adc	#'1'
	sta	Dd699

	ldx	romid2_save	; IIc family?
	beq	.fwd8		;   yes
	ora	#$80		; no
	jsr	Sdb39

.fwd8:	prt_msg	pos_drive_slot_verify
.loop4:	bit	kbd_strb
	jsr	Sfd3f
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
	jsr	Sdcfb
	jmp	.loop4

.fwd9:	prt_msg	no
	jmp	Sd6d8

.fwd10:	prt_msg	yes
	lda	Ze9
	sta	Z02
	inc	Z02
	ldx	Zea
	inx
	txa
	asl
	asl
	asl
	asl
	sta	Z00
	lda	Ze8

	ldx	max_save_position
	cpx	#$03
	beq	.fwd12
	clc
	adc	#$03
.fwd12:	tax
	lda	save_start_track_tbl,x
	sta	rwts_track
	lda	save_start_sector_tbl,x
	sta	rwts_sector

	prt_msg	insert_save

Sd7fc:	prt_msg	press_return
.loop5:	bit	kbd_strb
	jsr	Sfd3f
	cmp	#char_cr
	beq	.fwd13
	jsr	Sdcfb
	jmp	.loop5
.fwd13:	rts


msg_press_return:
	fcb	char_cr
	text_str	"Press [RETURN] to continue."
	fcb	char_cr
msg_len_press_return	equ	*-msg_press_return


save_start_track_tbl:
	fcb	$00,$0b,$17		; three save positions
	fcb	$00,$08,$11,$19		; four save positions

save_start_sector_tbl:
	fcb	$00,$08,$00		; three save positions
	fcb	$00,$08,$00,$08		; four save positions


msg_insert_story:
	fcb	char_cr
	text_str	"Insert Side "
Dd84e:	text_str	"* of the STORY disk into Drive #1."
	fcb	char_cr
msg_len_insert_story	equ	*-msg_insert_story


Sd871:	lda	#'1'
	sta	Dd84e
	lda	#$01
	sta	Zec
.loop1:	prt_msg	insert_story
	jsr	Sd7fc
	lda	#$00
	sta	rwts_sector
	sta	rwts_track
	lda	#$01
	sta	Z02
	lda	#$00
	jsr	rwts
	bcs	.loop1
	bcc	Ld8c7		; always taken


Sd899:
	if	iver>=iver_e
	lda	$f0d4
	beq	.fwd1
	jmp	Sd871
	endif

.fwd1	lda	#'2'
	sta	Dd84e
	lda	#$02
	sta	Zec
	lda	Z02
	pha
	lda	#$01
	sta	Z02
	pla
	cmp	#$02
	beq	Ld8c7
.loop2:	prt_msg	insert_story
	jsr	Sd7fc
	lda	#$00
	sta	rwts_sector
	sta	rwts_track
	lda	#$84
	jsr	rwts
	bcs	.loop2
Ld8c7:	lda	#$ff
	sta	Zd9
	rts


msg_save_position:
	text_str	"Save Position"
	fcb	char_cr
msg_len_save_position	equ	*-msg_save_position


msg_saving_position
	fcb	char_cr,char_cr
	text_str	"Saving position "
Dd8ec:	text_str	"* ..."
	fcb	char_cr
msg_len_saving_position	equ	*-msg_saving_position


op_save:
	lda	#$4e		; argcnt matters (new in XZIP)
	ldx	argcnt
	beq	.fwd0
	lda	#$50
.fwd0:	sta	Dfdee

	jsr	Sd62f
	prt_msg	save_position
	jsr	Sd6d8
	prt_msg	saving_position
	lda	hdr_game_ver
	sta	D0ca0
	lda	hdr_game_ver+1
	sta	D0ca0+1
	lda	stk_ptr
	sta	D0ca2
	lda	stk_ptr+1
	sta	D0ca2+1
	lda	Zf2
	sta	D0ca4
	lda	Zf2+1
	sta	D0ca4+1

	ldx	#$02
.loop1:	lda	pc,x
	sta	D0ca6,x
	dex
	bpl	.loop1

	lda	Dfdee
	sta	D0ca9
	cmp	#$50
	bne	.fwd1

	ldy	#$00
	lda	(arg3),y
	tay
.loop2:	lda	(arg3),y
	sta	D0caa,y
	dey
	bpl	.loop2

.fwd1:	lda	#$0c
	sta	Zb8
	jsr	Sd5df
	bcc	.fwd2

.loop3:	jsr	Sd899
	jmp	store_result_zero

.fwd2:	lda	Dfdee
	cmp	#$50
	bne	.fwd3
	lda	arg1+1
	clc
	adc	first_ram_page
	sta	Zb8
	ldx	arg2+1
	inx
	stx	Z6d
	jmp	.loop5

.fwd3:	lda	#$0f
	sta	Zb8
	lda	#$04
	sta	Z73
.loop4:	jsr	Sd5df
	bcs	.loop3
	dec	Z73
	bne	.loop4
	lda	first_ram_page
	sta	Zb8
	ldx	hdr_pure
	inx
	stx	Z6d
.loop5:	jsr	Sd5df
	bcs	.loop3
	dec	Z6d
	bne	.loop5
	jsr	Sd899
	lda	Ze9
	sta	Ze7
	lda	Zea
	sta	Dd67b
	lda	Ze8
	sta	Ze6
	lda	#$01
	ldx	#$00
	jmp	store_result_xa


msg_restore_position:
	text_str	"Restore Position"
	fcb		char_cr
msg_len_restore_position	equ	*-msg_restore_position


msg_restoring_position:
	fcb	char_cr,char_cr
	text_str	"Restoring position "
Dd9dc:	text_str	"* ..."
	fcb	char_cr
msg_len_restoring_position	equ	*-msg_restoring_position


op_restore:
	lda	#$4e
	ldx	argcnt
	beq	.fwd1
	lda	#$50
.fwd1:	sta	Dfdee
	jsr	Sd62f
	prt_msg	restore_position
	jsr	Sd6d8
	prt_msg	restoring_position
	lda	Dfdee
	cmp	#$50
	bne	.fwd2
	jmp	.fwd8

.fwd2:	ldx	#$1f
.loop1:	lda	local_vars,x
	sta	D0100,x
	dex
	bpl	.loop1

	lda	#$00
	sta	Df090
	lda	#$0c
	sta	Zb8
	jsr	read_sector
	bcs	.fwd3
	lda	D0ca0
	cmp	hdr_game_ver
	bne	.fwd3
	lda	D0ca0+1
	cmp	hdr_game_ver+1
	beq	.fwd4

.fwd3:	ldx	#$1f
.loop2:	lda	D0100,x
	sta	local_vars,x
	dex
	bpl	.loop2

.rev1:	jsr	Sd899
	jmp	store_result_zero

.fwd4:	lda	hdr_flags2
	sta	Z6d
	lda	hdr_flags2+1
	sta	Z6d+1

	lda	#$0f
	sta	Zb8
	lda	#$04
	sta	Z73
.loop3:	jsr	read_sector
	bcc	.fwd5
	jmp	int_err_0e

.fwd5:	dec	Z73
	bne	.loop3
	lda	first_ram_page
	sta	Zb8
	jsr	read_sector
	bcc	.fwd6
	jmp	int_err_0e

.fwd6:	lda	Z6d
	sta	hdr_flags2
	lda	Z6d+1
	sta	hdr_flags2+1
	lda	hdr_pure
	sta	Z6d
.rev2:	jsr	read_sector
	bcc	.fwd7
	jmp	int_err_0e

.fwd7:	dec	Z6d
	bne	.rev2
	lda	D0ca2
	sta	stk_ptr
	lda	D0ca2+1
	sta	stk_ptr+1
	lda	D0ca4
	sta	Zf2
	lda	D0ca4+1
	sta	Zf2+1
	ldx	#$02
.loop4:	lda	D0ca6,x
	sta	pc,x
	dex
	bpl	.loop4
.loop5:	jsr	Sd899
	jsr	find_pc_page
	lda	Ze9
	sta	Ze7
	lda	Zea
	sta	Dd67b
	lda	Ze8
	sta	Ze6
	lda	#$02
	ldx	#$00
	jmp	store_result_xa

.fwd8:	lda	#$00
	sta	Df090
	lda	#$0a
	sta	Zb8
	jsr	read_sector
	bcs	.fwd11
	ldy	#$00
	lda	(arg3),y
	tay
	clc
	adc	#$a0
	clc
	adc	#$0a
	tax
.loop6:	lda	(arg3),y
	cmp	rwts_data_buf,x
	bne	.fwd11
	dex
	dey
	bpl	.loop6
	lda	arg1+1
	clc
	adc	first_ram_page
	sta	Z6d+1
	lda	#$00
	sta	Z6d
	lda	arg2
	clc
	adc	arg1
	sta	Z6f
	lda	arg2+1
	adc	#$00
	sta	Z6f+1
	jsr	Sf0fb
	lda	#$0a
	sta	Zb8
	jsr	read_sector
	bcc	.fwd9
	jmp	int_err_0e

.fwd9:	ldy	arg1
.loop7:	lda	rwts_data_buf,y
	sta	(Z6d),y
	jsr	Sf0fb
	bcc	.loop5
	iny
	bne	.loop7
	lda	#$0a
	sta	Zb8
	jsr	read_sector
	bcc	.fwd10
	jmp	int_err_0e

.fwd10:
	ldy	#$00
	jmp	.loop7

.fwd11:	jmp	.rev1


op_save_illegal:
op_restore_illegal:
	rts		; why not raise an internal error?


op_save_undo:
op_restore_undo:
	jmp	store_result_zero


Sdb39:	sta	Zdc
	txa
	pha
	tya
	pha
	lda	Zdc
	jsr	S08ef
	cmp	#$8d
	bne	.fwd1
	lda	hdr_unknown_29
	sta	D057b
.fwd1:	pla
	tay
	pla
	tax
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
.lda:	fcb	$bd,$00,$00	; lda $0000,x	; self-modifying code, MUST be absolute,x
	ldy	invflg
	bpl	.fwd1
	ora	#$80
.fwd1:	jsr	Sdb39
	inx
	dec	Z6f
	bne	.loop1
	rts


Ldb6f:	rts

Sdb70:	lda	Zd9
	beq	Ldb6f
	lda	ostream_2_state
	beq	Ldb6f
	lda	cswl
	pha
	lda	cswl+1
	pha
	lda	D057b
	pha
	lda	Ddbaa
	sta	cswl
	lda	Ddbaa+1
	sta	cswl+1
	lda	#$00
	sta	D057b
	ldy	#$00
.loop1:	lda	D0200,y
	jsr	S08ef
	iny
	dec	Ze3
	bne	.loop1
	pla
	sta	D057b
	pla
	sta	cswl+1
	pla
	sta	cswl
	rts


Ddba9:	fcb	$00
Ddbaa:	fdb	$0000


Sdbac:	prt_msg	printer_slot
	lda	#$00
	jsr	Sd648
	jsr	Sfd3f
	cmp	#char_cr
	beq	Ldbca
	sec
	sbc	#'0'
	cmp	#$08
	bcs	Sdbac
	bcc	Ldbcc
Ldbca:	lda	#$01
Ldbcc:	clc
	adc	#$c0
	sta	Ddbaa+1
	jsr	Sdcd9
	inc	Ddba9

; send sequence <control-I>80N to convince printer firmware to use
; 80 columns
	lda	cswl
	pha
	lda	cswl+1
	pha
	lda	Ddbaa
	sta	cswl
	lda	Ddbaa+1
	sta	cswl+1
	lda	#$89
	jsr	S08ef
	lda	#$b8
	jsr	S08ef
	lda	#$b0
	jsr	S08ef
	lda	#$ce
	jsr	S08ef
	lda	cswl
	sta	Ddbaa
	lda	cswl+1
	sta	Ddbaa+1
	pla
	sta	cswl+1
	pla
	sta	cswl
	rts


op_split_window:
	lda	arg1
	beq	Sdc51
	cmp	#24
	bcs	Ldc59
	sta	Zde
	lda	#24
	sta	wndbot
	lda	wndtop
	sta	Z6d
	lda	arg1
	sta	wndtop
	cmp	Zda
	bcc	.fwd1
	sta	Zda
.fwd1:	lda	#$00
	sta	Dfde7
	sta	Dfde9
	sta	Dfdeb
	lda	cursrv
	cmp	Z6d
	bcc	.fwd2
	cmp	wndtop
	bcs	Ldc59
	lda	wndtop
	sta	cursrv
	lda	hdr_unknown_29
.rev1:	sta	D057b
	jmp	S08a9

.fwd2:	lda	#$00
	sta	cursrv
	beq	.rev1		; always taken


Sdc51:	lda	#$00
	sta	wndtop
	sta	Zda
	sta	Zde
Ldc59:	rts


op_set_window:
	lda	Zde
	beq	Ldc59
	jsr	Sf8e1
	ldx	Zc7
	lda	cursrv
	sta	Dfdea,x
	sta	Dfde6,x
	lda	D057b
	sta	Dfde8,x
	lda	arg1
	bne	.fwd1
	lda	#$ff
	sta	Zd9
	lda	Dfded
	sta	Zc4
	lda	#$00
	sta	Zc7
	beq	.fwd2		; always taken

.fwd1:	cmp	#$01
	bne	Ldc59
	sta	Zc7
	lda	Zc4
	sta	Dfded
	lda	#$00
	sta	Zd9
	lda	#$4f
	sta	Zc4
.fwd2:	ldx	Zc7
	lda	Dfdf2,x
	jsr	Sfab4
	ldx	Zc7
	lda	Dfdea,x
	sta	cursrv
	lda	Dfde6,x
	lda	Dfde8,x
	sta	D057b
	jmp	S08a9


op_set_margins:
	jsr	Sf8e1
	lda	arg2
	sta	hdr_unknown_2b
	lda	arg1
	sta	hdr_unknown_29
	sta	D057b
	lda	#$4f
	sec
	sbc	arg2
	sbc	arg1
	sta	Zc4
	sta	Dfded
	rts


Sdccf:	jsr	S08e1
	lda	hdr_unknown_29
	sta	D057b
	rts


Sdcd9:	lda	#$8d
	jmp	S08ef


op_sound_effect:
	lda	hdr_flags_1
	and	#$20
	beq	.rtn
	ldx	arg1
	dex
	beq	Sdcfb
	dex
	bne	.rtn
	ldy	#$ff
.loop1:	lda	#$10
	jsr	S0927
	lda	spkr
	dey
	bne	.loop1
.rtn:	rts


Sdcfb:	jmp	L08b7		; bell


Sdcfe:	lda	#$00
	sta	Zfc
.loop1:	ldy	#$00
.loop2:	sta	D1000,y
	iny
	bne	.loop2
	inc	Zfc
	lda	Zfc
	sta	wr_card_ram
.loop3:	sta	D1000,y
	iny
	bne	.loop3
	sta	wr_main_ram
	dec	Zfc
.loop4:	lda	D1000,y
	cmp	Zfc
	bne	Ldd3e
	iny
	bne	.loop4
	inc	Zfc
	sta	rd_card_ram
.loop5:	lda	D1000,y
	cmp	Zfc
	bne	Ldd3e
	iny
	bne	.loop5
	sta	rd_main_ram
	lda	Zfc
	bne	.loop1
	clc
	rts

Ldd3e:	sta	rd_main_ram
	sec
	rts


op_set_colour:
op_draw_picture:
op_erase_picture:
	rts


op_picture_data:
	jmp	predicate_false


romid2_save:
	fcb	$00
Ddd48:	fcb	$00
Ddd49:	fcb	$00


; interpreter startup entry point jumped from boot1
interp_start:
	lda	bas2l+1
	sta	Z00
	sta	Z01

	lda	#mon_cout1>>8
	sta	cswl+1
	lda	#mon_cout1&$ff
	sta	cswl

	ldx	#$00
	stx	rwts_sector
	stx	Zb7

	inx			; read rest of interpreter starting with track 1
	stx	rwts_track

	stx	Z02
	stx	Z03

	lda	#$de		; starting at $de00
	sta	Zb8

	lda	#34		; sector count
	sta	Z6d

.loop1:	jsr	read_sector
	dec	Z6d
	bne	.loop1

	lda	#$ff
	sta	invflg

	jsr	S093b
	bcc	.fwd1
	bcs	Ldddd		; always taken

.fwd1:	lda	romid2_save
	beq	.fwd2
	jsr	Sdcfe
	bcs	Ldddd
.fwd2:	jsr	S095e

restart:
	lda	Z01
	ldx	Z03
	sta	Ddd48
	stx	Ddd49
	jsr	Sdccf
	lda	#$0a
	sta	cursrv
	lda	#$1b
	sta	cursrh
	sta	D057b
	jsr	S08a9		; vtab

	prt_msg_alt	story_loading

	lda	#$00		; clear interp zero page vars
	ldx	#interp_zp_origin
.loop2:	sta	Z00,x
	inx
	bne	.loop2

	inc	stk_ptr
	inc	Zf2
	inc	Zd9
	inc	ostream_1_state
	inc	Zec

	lda	#hdr_arch>>8
	sta	first_ram_page
	sta	Zb8

	lda	#$00
	sta	Df090

	if	iver>=iver_e
	lda	#$01
	sta	Z82+1
	endif

	jsr	Sd51d

	lda	hdr_arch	; check header architecture version
	cmp	#$05
	beq	Ldde9

	lda	#$0f
	jmp	int_error

Ldddd:	lda	#$05
	sta	cursrv
	jsr	S08a9
	lda	#$00
	jmp	int_error
Ldde9:	lda	hdr_pure
	cmp	#$ad
	bcc	.fwd1a

	lda	#$0d
	jmp	int_error

.fwd1a:
	lda	#$03		; no computation, just always use 3 save positions
	sta	max_save_position
	clc
	adc	#$30
	sta	msg_position_max_ascii

	if	iver<=iver_c

	ldx	hdr_high_mem	; base of high memory
	inx
	stx	Z82

	else

	lda	hdr_high_mem	; base of high memory
	sta	Z82+1
	lda	hdr_high_mem+1
	sta	Z82

	rept	6
	lsr	Z82+1
	ror	Z82
	endm

	endif

	lda	hdr_flags_1
	ora	#$30		; bit 4: fixed-space style available
				; bit 5: sound effects available
	sta	hdr_flags_1

; set interpreter platform number
	lda	#2		;   2 for Apple IIe
	ldx	romid2_save
	bne	.fwd2
	lda	#9		; 9 for Apple IIc
.fwd2:	sta	hdr_interp_platform

	lda	#$40+(iver&$ff)	; set intpreter revision
	sta	hdr_interp_rev

; screen size in "units"
	lda	#0
	sta	hdr_scr_width_units
	sta	hdr_scr_height_units
	lda	#80
	sta	hdr_scr_width_units+1
	lda	#24
	sta	hdr_scr_height_units+1

; font size in "units"
	lda	#1
	sta	hdr_font_width_units
	sta	hdr_font_height_units

; screen size in characters
	lda	#24
	sta	hdr_screen_height
	lda	#80
	sta	hdr_scr_width

	lda	hdr_globals
	clc
	adc	first_ram_page
	sta	Z84
	lda	hdr_globals+1
	sta	Z83

	lda	hdr_abbrev
	clc
	adc	first_ram_page
	sta	Z88
	lda	hdr_abbrev+1
	sta	Z87

	lda	hdr_object
	clc
	adc	first_ram_page
	sta	Z8a
	lda	hdr_object+1
	sta	Z89

	lda	hdr_term_char_tbl
	ora	hdr_term_char_tbl+1
	beq	Lde7f
	lda	hdr_term_char_tbl
	clc
	adc	first_ram_page
	sta	Z8c
	lda	hdr_term_char_tbl+1
	sta	Z8b
Lde7f:	jsr	Sf278
	lda	Z8c
	ora	Z8b
	beq	Lde97
	ldy	#$ff
Lde8a:	iny
	lda	(Z8b),y
	beq	Lde97
	cmp	#$ff
	bne	Lde8a
	lda	#$01
	sta	Zb4
Lde97:	jsr	Sdccf

	lda	hdr_main_routine
	sta	pc+1
	lda	hdr_main_routine+1
	sta	pc

	jsr	find_pc_page
	ldx	#80		; constant, rather than wndwdt in older
	dex
	stx	Zc4
	stx	Dfded
	lda	Ddba9
	bpl	.fwd3

	lda	#$01
	sta	Ddba9
	sta	ostream_2_state
	ora	hdr_flags2+1	; git 8 of hdr_flags2 is not defined for v5
	sta	hdr_flags2+1

.fwd3:	jsr	Sdccf
; fall into main loop

main_loop:
	lda	#$00
	sta	argcnt

	fetch_pc_byte_inline
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

op_c0_ff:
	cmp	#$ec		; is it call_vs2 (up to 8 args)?
	bne	.fwd1
	jmp	op_ec		;   yes

.fwd1:	cmp	#$fa		; is it call_vn2 (up to 8 args)?
	bne	.fwd1a
	jmp	op_fa		;   yes

.fwd1a:	jsr	fetch_pc_byte
	sta	Z68
	ldx	#$00
	stx	Z6a
	beq	.fwd1b		; always taken

.loop1:	lda	Z68
	asl
	asl
	sta	Z68
.fwd1b:	and	#$c0
	bne	.fwd2
	jsr	Se0db
	jmp	.fwd4

.fwd2:	cmp	#$40
	bne	.fwd3
	jsr	Se0d7
	jmp	.fwd4

.fwd3:	cmp	#$80
	bne	dispatch_var
	jsr	Se0ef
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

dispatch_var:
	lda	opcode
	cmp	#$e0
	bcs	dispatch_var_op_tab
	cmp	#$c0
	bcc	op_extended
	jmp	dispatch_2op_tab

dispatch_var_op_tab:
	and	#$1f
	tay
	lda	tab_var_lo,y
	sta	.jsr+1
	lda	tab_var_hi,y
	sta	.jsr+2
.jsr	jsr	$ffff		; self-modifying code
	jmp	main_loop


op_extended:
	cmp	#$0b
	bcs	int_err_10

	tay
	lda	tab_ext_lo,y
	sta	.jsr+1
	lda	tab_ext_hi,y
	sta	.jsr+2
.jsr	jsr	$ffff
	jmp	main_loop


; unreferenced
	lda	#$01
	jmp	int_error


int_err_10:
	lda	#$10
	jmp	int_error


; call_vs2, up to eight args
; call_vn2, up to eight args
op_ec:
op_fa:
	jsr	fetch_pc_byte
	sta	Z68
	jsr	fetch_pc_byte
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
	jsr	Se0db
	jmp	.fwd3

.fwd1:	cmp	#$40
	bne	.fwd2
	jsr	Se0d7
	jmp	.fwd3

.fwd2:	cmp	#$80
	bne	dispatch_var
	jsr	Se0ef

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
	bne	.fwd4
	jmp	dispatch_var

.fwd4:	cpx	#$08
	bne	.loop1
	lda	Z69
	sta	Z68
	jmp	.loop2


; 0OP instructions
op_b0_bf:
	cmp	#$be		; extend?
	beq	op_be
	and	#$0f
	tay
	lda	tab_0op_lo,y
	sta	.jsr+1
	lda	tab_0op_hi,y
	sta	.jsr+2
.jsr	jsr	$ffff		; self-modifying code
	jmp	main_loop


; unreferenced?
	lda	#$02
	jmp	int_error


op_be:	jsr	fetch_pc_byte
	sta	opcode
	jmp	op_c0_ff


op_80_af:
	and	#$30
	bne	.fwd2

	fetch_pc_byte_inline
	jmp	.fwd3

.fwd2:	and	#$20
	bne	.fwd5
.fwd3:	sta	arg1+1

	fetch_pc_byte_inline
	sta	arg1
	inc	argcnt
	jmp	dispatch_1op

.fwd5:	jsr	Se0ef
	jsr	Se0cc
dispatch_1op:
	lda	opcode
	and	#$0f
	tay
	lda	tab_1op_lo,y
	sta	.jsr+1
	lda	tab_1op_hi,y
	sta	.jsr+2
.jsr	jsr	$ffff		; self-modifying code
	jmp	main_loop


; unreferenced - was used in e.g. ZIP intepreter F
	lda	#$03
	jmp	int_error


op_00_7f:
; check type of first arg
	and	#$40
	bne	.fwd1

; first arg is immediate byte
	sta	arg1+1		; A contains zero
	fetch_pc_byte_inline
	sta	arg1
	inc	argcnt
	jmp	.fwd2

.fwd1:
; first arg is a variable
	jsr	Se0ef
	jsr	Se0cc		; store acc in arg1 and increment argcnt

.fwd2:
; check type of second arg
	lda	opcode
	and	#$20
	bne	.fwd3

; second arg is immediate byte
	sta	arg2+1		; A contains zero
	fetch_pc_byte_inline
	sta	arg2
	jmp	.fwd4

.fwd3:
; second arg is variable
	jsr	Se0ef
	lda	acc
	sta	arg2
	lda	acc+1
	sta	arg2+1

.fwd4:	inc	argcnt

dispatch_2op_tab:
	lda	opcode
	and	#$1f
	tay
	lda	tab_2op_lo,y
	sta	.jsr+1
	lda	tab_2op_hi,y
	sta	.jsr+2
.jsr	jsr	$ffff		; self-modifying code
	jmp	main_loop


int_err_04:
	lda	#$04
	jmp	int_error


Se0cc:	lda	acc
	sta	arg1
	lda	acc+1
	sta	arg1+1
	inc	argcnt
	rts


Se0d7:	lda	#$00
	beq	Le0de		; always taken

Se0db:	jsr	fetch_pc_byte
Le0de:	sta	acc+1
	jsr	fetch_pc_byte
	sta	acc
	rts


Se0e6:	tax
	bne	Le0f4
	jsr	pop_acc
	jmp	push_acc

Se0ef:	jsr	fetch_pc_byte
	beq	pop_acc
Le0f4:	cmp	#$10
	bcs	Le105
	asl
	tax
	lda	local_vars-2,x
	sta	acc
	lda	local_vars-1,x
	sta	acc+1
	rts

Le105:	jsr	find_global_var
	lda	(Z6d),y
	sta	acc+1
	iny
	lda	(Z6d),y
	sta	acc
	rts


pop_acc:
	lda	stk_ptr
	bne	Le118
	sta	stk_ptr+1
Le118:	dec	stk_ptr
	bne	Le120
	ora	stk_ptr+1
	beq	int_err_05
Le120:	ldy	stk_ptr
	lda	stk_ptr+1
	beq	Le132
	lda	D1000,y
	sta	acc
	tax
	lda	D1200,y
	sta	acc+1
	rts
Le132:	lda	D0f00,y
	sta	acc
	tax
	lda	D1100,y
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
	ldy	stk_ptr
	lda	stk_ptr+1
	beq	Le159
	txa
	sta	D1000,y
	pla
	sta	D1200,y
	jmp	Le161
Le159:	txa
	sta	D0f00,y
	pla
	sta	D1100,y
Le161:	inc	stk_ptr
	bne	Le16d
	lda	stk_ptr
	ora	stk_ptr+1
	bne	int_err_06	; data stack overflow
	inc	stk_ptr+1
Le16d:	rts


int_err_06:
	lda	#$06
	jmp	int_error


Le173:	tax
	bne	Le193
	lda	stk_ptr
	bne	.fwd1
	sta	stk_ptr+1
.fwd1:	dec	stk_ptr
	bne	push_acc
	ora	stk_ptr+1
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
	jsr	fetch_pc_byte
	beq	push_acc
Le193:	cmp	#$10
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
.fwd2:	jsr	find_global_var
	lda	acc+1
	sta	(Z6d),y
	iny
	lda	acc
	sta	(Z6d),y
	rts


; On entry:
;   A = global var number +$10
; On exit:
;   Z6d points to global variable
find_global_var:
	sec
	sbc	#$10
	ldy	#$00
	sty	Z6d+1
	asl
	rol	Z6d+1
	clc
	adc	Z83
	sta	Z6d
	lda	Z6d+1
	adc	Z84
	sta	Z6d+1
Le1c6:	rts


predicate_false:
	jsr	fetch_pc_byte
	bpl	Le1d8
Le1cc:	and	#$40
	bne	Le1c6
	jmp	fetch_pc_byte


predicate_true:
	jsr	fetch_pc_byte
	bpl	Le1cc
Le1d8:	tax
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
	jsr	fetch_pc_byte
	sta	acc
	lda	acc+1
	bne	Le20d
.fwd3:	lda	acc
	bne	.fwd4
	jmp	op_rfalse

.fwd4:	cmp	#$01
	bne	Le20d
	jmp	op_rtrue

Le20d:	lda	acc
	sec
	sbc	#$02
	tax
	lda	acc+1
	sbc	#$00
	sta	Z6d
	ldy	#$00
	sty	Z6d+1
	asl
	rol	Z6d+1
	asl
	rol	Z6d+1
	txa
	adc	pc
	bcc	.fwd5
	inc	Z6d
	bne	.fwd5
	inc	Z6d+1
.fwd5:	sta	pc
	lda	Z6d
	ora	Z6d+1
	beq	op_nop
	lda	Z6d
	clc
	adc	pc+1
	sta	pc+1
	lda	Z6d+1
	adc	pc+2
	and	#$03
	sta	pc+2
	jmp	find_pc_page


op_nop:	rts


Se249:	lda	arg1
	sta	acc
	lda	arg1+1
	sta	acc+1
	rts


; unreferenced - see S1b1d in ZIP revision F
	lda	hdr_flags2+1
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
	optab_ent	op_save_illegal
	optab_ent	op_restore_illegal
	optab_ent	op_restart
	optab_ent	op_ret_popped
	optab_ent	op_catch
	optab_ent	op_quit
	optab_ent	op_new_line
	optab_ent	op_show_status	; [nop, some games might mistakenly use])
	optab_ent	op_verify
	optab_ent	op_extended
	optab_ent	op_piracy	; [always a true predicate, indicating game is authentic]


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
	optab_ent	op_call_1s
	optab_ent	op_remove_obj
	optab_ent	op_print_obj
	optab_ent	op_ret		; with value
	optab_ent	op_jump
	optab_ent	op_print_paddr
	optab_ent	op_load
	optab_ent	op_call_1n


; 2OP instructions (two operand), opcodes $20..$7f
; The 2OP table is also used for VAR instructions (0-4 or 0-8 operands),
; opcodes $e0..$df
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
	optab_ent	op_call_2s
	optab_ent	op_call_2n
	optab_ent	op_set_colour	; [nop]
	optab_ent	op_throw
	optab_ent	int_err_04	; [illegal]
	optab_ent	int_err_04	; [illegal]
	optab_ent	int_err_04	; [illegal]


; VAR instructions (0-4 operands, 0-8 for call_vs2 and call_vn2),
; opcodes $e0..$ff
	optab_start	tab_var,32
	optab_ent	op_call_vs	; (up to 3 args)
	optab_ent	op_storew
	optab_ent	op_storeb
	optab_ent	op_put_prop
	optab_ent	op_aread	; (sread in v1 through v4)
	optab_ent	op_print_char
	optab_ent	op_print_num
	optab_ent	op_random
	optab_ent	op_push
	optab_ent	op_pull
	optab_ent	op_split_window
	optab_ent	op_set_window
	optab_ent	op_call_vs2	; (up to 7 args)
	optab_ent	op_erase_window
	optab_ent	op_erase_line
	optab_ent	op_set_cursor
	optab_ent	op_get_cursor
	optab_ent	op_set_text_style
	optab_ent	op_buffer_mode
	optab_ent	op_output_stream
	optab_ent	op_input_stream	; [nop]
	optab_ent	op_sound_effect
	optab_ent	op_read_char
	optab_ent	op_scan_table
	optab_ent	op_not
	optab_ent	op_call_vn	; (up to 3 args)
	optab_ent	op_call_vn2	; (up to 7 args)
	optab_ent	op_tokenise
	optab_ent	op_encode_text
	optab_ent	op_copy_table
	optab_ent	op_print_table
	optab_ent	op_check_arg_count


; EXT instructions
	optab_start	tab_ext,11
	optab_ent	op_save
	optab_ent	op_restore
	optab_ent	op_log_shift
	optab_ent	op_art_shift
	optab_ent	op_set_font
	optab_ent	op_draw_picture	; [nop, not in v5 spec]
	optab_ent	op_picture_data	; [not in v5 spec]
	optab_ent	op_erase_picture	; [nop, not in v5 spec]
	optab_ent	op_set_margins	; [not in v5 spec]
	optab_ent	op_save_undo	; [not implemented, returns 0 (fail),
					;  according to spec should return -1]
	optab_ent	op_restore_undo	; [not implemented, returns 0 (fail)]


op_rtrue:
	ldx	#$01
Le333:	lda	#$00
Le335:	stx	arg1
	sta	arg1+1
	jmp	op_ret


op_rfalse:
	ldx	#$00
	beq	Le333


op_print:
	ldx	#$05
.loop1:	lda	pc,x
	sta	aux_ptr,x
	dex
	bpl	.loop1
	jsr	Sf307
	ldx	#$05
.loop2:	lda	aux_ptr,x
	sta	pc,x
	dex
	bpl	.loop2
	rts


op_print_ret:
	jsr	op_print
	jsr	op_new_line
	jmp	op_rtrue


op_ret_popped:
	jsr	pop_acc
	jmp	Le335


op_catch:
	ldx	Zf2+1
	lda	Zf2
	jmp	store_result_xa


op_piracy:
	jmp	predicate_true		; always reports game is authentic


op_jz:	lda	arg1
	ora	arg1+1
	beq	Le39d
Le375:	jmp	predicate_false


op_get_sibling:
	lda	arg1
	ldx	arg1+1
	jsr	setup_object
	ldy	#$08
	bne	Le38c		; always taken


op_get_child:
	lda	arg1
	ldx	arg1+1
	jsr	setup_object
	ldy	#$0a
Le38c:	lda	(Z6d),y
	tax
	iny
	lda	(Z6d),y
	jsr	store_result_xa
	lda	acc
	bne	Le39d
	lda	acc+1
	beq	Le375
Le39d:	jmp	predicate_true


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
	adc	first_ram_page
	sta	Z6d+1
	lda	arg1
	sec
	sbc	#$01
	sta	Z6d
	bcs	.fwd1
	dec	Z6d+1
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
	jsr	Se0e6
	inc	acc
	bne	.fwd1
	inc	acc+1
.fwd1:	jmp	Le3fd


op_dec:	lda	arg1
	jsr	Se0e6
	lda	acc
	sec
	sbc	#$01
	sta	acc
	lda	acc+1
	sbc	#$00
	sta	acc+1
Le3fd:	lda	arg1
	jmp	Le173


op_print_addr:
	lda	arg1
	sta	Z6d
	lda	arg1+1
	sta	Z6d+1
	jsr	Sf081
	jmp	Sf307


op_remove_obj:
	lda	arg1
	ldx	arg1+1
	jsr	setup_object
	lda	Z6d
	sta	Z6f
	lda	Z6d+1
	sta	Z6f+1
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
	stx	Z6d+1
	inc	Z6d
	bne	.fwd1
	inc	Z6d+1
.fwd1:	jsr	Sf081
	jmp	Sf307


op_ret:	lda	Zf2
	sta	stk_ptr
	lda	Zf2+1
	sta	stk_ptr+1
	jsr	pop_acc
	stx	Z6d+1
	jsr	pop_acc
	sta	Dfdef
	ldx	Z6d+1
	beq	.fwd1
	dex
	txa
	asl
	sta	Z6d

.loop1:	jsr	pop_acc
	ldy	Z6d
	sta	local_vars+1,y
	txa
	sta	local_vars,y
	dec	Z6d
	dec	Z6d
	dec	Z6d+1
	bne	.loop1

.fwd1:	jsr	pop_acc
	stx	pc+1
	sta	pc+2
	jsr	pop_acc
	stx	call_store_result_flag
	sta	pc
	jsr	pop_acc
	stx	Zf2
	sta	Zf2+1
	lda	pc
	bne	.fwd2
	lda	pc+1
	bne	.fwd2
	lda	pc+2
	bne	.fwd2
	jsr	Se249
	jmp	Lfd19

.fwd2:	jsr	find_pc_page
	lda	call_store_result_flag
	beq	.fwd3
	rts

.fwd3:	jsr	Se249
	jmp	store_result


op_jump:
	jsr	Se249
	jmp	Le20d


op_print_paddr:
	lda	arg1
	sta	Z6d
	lda	arg1+1
	sta	Z6d+1
	jsr	Sf2ee
	jmp	Sf307


op_load:
	lda	arg1
	jsr	Se0e6
	jmp	store_result


op_jl:	jsr	Se249
	jmp	Le52e


op_dec_chk:
	jsr	op_dec
Le52e:	lda	arg2
	sta	Z6d
	lda	arg2+1
	sta	Z6d+1
	jmp	Le557


op_jg:	lda	arg1
	sta	Z6d
	lda	arg1+1
	sta	Z6d+1
	jmp	Le54f


op_inc_chk:
	jsr	op_inc
	lda	acc
	sta	Z6d
	lda	acc+1
	sta	Z6d+1
Le54f:	lda	arg2
	sta	acc
	lda	arg2+1
	sta	acc+1
Le557:	lda	Z6d+1
	eor	acc+1
	bpl	.fwd1
	lda	Z6d+1
	cmp	acc+1
	bcc	Le59e
	jmp	predicate_false

.fwd1:	lda	acc+1
	cmp	Z6d+1
	bne	.fwd2
	lda	acc
	cmp	Z6d
.fwd2:	bcc	Le59e
	jmp	predicate_false


; is object ARG1 in (a direct child of) object ARG2?
op_jin:	lda	arg1
	ldx	arg1+1
	jsr	setup_object
	ldy	#$06
	lda	(Z6d),y
	cmp	arg2+1
	bne	Le58b
	iny
	lda	(Z6d),y
	cmp	arg2
	beq	Le59e
Le58b:	jmp	predicate_false


op_test:
	lda	arg2
	and	arg1
	cmp	arg2
	bne	Le58b
	lda	arg2+1
	and	arg1+1
	cmp	arg2+1
	bne	Le58b
Le59e:	jmp	predicate_true


op_or:	lda	arg1
	ora	arg2
	tax
	lda	arg1+1
	ora	arg2+1
Le5aa:	stx	acc
	sta	acc+1
	jmp	store_result


op_and:	lda	arg1
	and	arg2
	tax
	lda	arg1+1
	and	arg2+1
	jmp	Le5aa


op_test_attr:
	jsr	setup_attribute
	lda	Z71+1
	and	Z6f+1
	sta	Z71+1
	lda	Z71
	and	Z6f
	ora	Z71+1
	bne	Le59e
	jmp	predicate_false


op_set_attr:
	jsr	setup_attribute
	ldy	#$00
	lda	Z71+1
	ora	Z6f+1
	sta	(Z6d),y
	iny
	lda	Z71
	ora	Z6f
	sta	(Z6d),y
	rts


op_clear_attr:
	jsr	setup_attribute
	ldy	#$00
	lda	Z6f+1
	eor	#$ff
	and	Z71+1
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
	jmp	Le173


op_insert_obj:
	jsr	op_remove_obj
	lda	arg1
	ldx	arg1+1
	jsr	setup_object
	lda	Z6d
	sta	Z6f
	lda	Z6d+1
	sta	Z6f+1
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
	sta	Z71+1
	lda	arg1+1
	sta	(Z6d),y
	iny
	lda	(Z6d),y
	tax
	lda	arg1
	sta	(Z6d),y
	txa
	ora	Z71+1
	beq	.rtn
	txa
	ldy	#$09
	sta	(Z6f),y
	dey
	lda	Z71+1
	sta	(Z6f),y
.rtn:	rts


op_loadw:
	jsr	Se662
	jsr	fetch_aux_byte
Le651:	sta	acc+1
	jsr	fetch_aux_byte
	sta	acc
	jmp	store_result


op_loadb:
	jsr	Se666
	lda	#$00
	beq	Le651


Se662:	asl	arg2
	rol	arg2+1

Se666:	lda	arg2
	clc
	adc	arg1
	sta	aux_ptr
	lda	arg2+1
	adc	arg1+1
	sta	aux_ptr+1
	lda	#$00
	adc	#$00
	sta	aux_ptr+2
	jmp	find_aux_page


op_get_prop:
	jsr	Sf56c
.loop1:	jsr	Sf58a
	cmp	arg2
	beq	.fwd2
	bcc	.fwd1
	jsr	Sf5b9
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

.fwd2:	jsr	Sf58f
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
	lda	arg1
	ldx	arg1+1
	jsr	setup_object
	ldy	#$0c
	lda	(Z6d),y
	clc
	adc	first_ram_page
	tax
	iny
	lda	(Z6d),y
	sta	Z6d
	stx	Z6d+1
	ldy	#$00
	lda	(Z6d),y
	asl
	tay
	iny
.loop2b:
	lda	(Z6d),y
	and	#$3f
	cmp	arg2
	beq	.fwd8b
	bcs	.fwd2b
	jmp	Le751

.fwd2b:	lda	(Z6d),y
	and	#$80
	beq	.fwd3b
	iny
	lda	(Z6d),y
	and	#$3f
	jmp	.fwd5b

.fwd3b:	lda	(Z6d),y
	and	#$40
	beq	.fwd4b
	lda	#$02
	jmp	.fwd5b

.fwd4b:	lda	#$01
.fwd5b:	tax
.loop3b:
	iny
	bne	.fwd6b
	inc	Z6d+1
.fwd6b:	dex
	bne	.loop3b
	iny
	tya
	clc
	adc	Z6d
	sta	Z6d
	bcc	.fwd7b
	inc	Z6d+1
.fwd7b:	ldy	#$00
	jmp	.loop2b

.fwd8b:	lda	(Z6d),y
	and	#$80
	beq	.fwd9b
	iny
	lda	(Z6d),y
	and	#$3f
	jmp	.fwd11b

.fwd9b:	lda	(Z6d),y
	and	#$40
	beq	.fwd10b
	lda	#$02
	jmp	.fwd11b

.fwd10b:
	lda	#$01
.fwd11b:
	iny
	tya
	clc
	adc	Z6d
	sta	acc
	lda	Z6d+1
	adc	#$00
	sec
	sbc	first_ram_page
	sta	acc+1
	jmp	store_result

Le751:	jmp	store_result_zero


op_get_next_prop:
	jsr	Sf56c
	lda	arg2
	beq	.fwd2
.loop1:	jsr	Sf58a
	cmp	arg2
	beq	.fwd1
	bcc	Le751
	jsr	Sf5b9
	jmp	.loop1

.fwd1:	jsr	Sf5a7
.fwd2:	jsr	Sf58a
	ldx	#$00
	jmp	store_result_xa


op_add:	lda	arg1
	clc
	adc	arg2
	tax
	lda	arg1+1
	adc	arg2+1
	jmp	Le5aa


op_sub:	lda	arg1
	sec
	sbc	arg2
	tax
	lda	arg1+1
	sbc	arg2+1
	jmp	Le5aa


op_mul:	jsr	Se849
.loop1:	ror	Zd0+1
	ror	Zd0
	ror	arg2+1
	ror	arg2
	bcc	.fwd1
	lda	arg1
	clc
	adc	Zd0
	sta	Zd0
	lda	arg1+1
	adc	Zd0+1
	sta	Zd0+1
.fwd1:	dex
	bpl	.loop1
	ldx	arg2
	lda	arg2+1
	jmp	Le5aa


op_div:	jsr	divide
	ldx	Zcc
	lda	Zcc+1
	jmp	Le5aa


op_mod:	jsr	divide
	ldx	Zce
	lda	Zce+1
	jmp	Le5aa


; On exit:
;   quotient in Zcc
;   remainder in Zce
divide:	lda	arg1+1
	sta	Zd3
	eor	arg2+1
	sta	Zd2
	lda	arg1
	sta	Zcc
	lda	arg1+1
	sta	Zcc+1
	bpl	.fwd1
	jsr	Se805
.fwd1:	lda	arg2
	sta	Zce
	lda	arg2+1
	sta	Zce+1
	bpl	.fwd2
	jsr	Se7f7
.fwd2:	jsr	Se813
	lda	Zd2
	bpl	.fwd3
	jsr	Se805
.fwd3:	lda	Zd3
	bpl	Le804


Se7f7:	lda	#$00
	sec
	sbc	Zce
	sta	Zce
	lda	#$00
	sbc	Zce+1
	sta	Zce+1
Le804:	rts


Se805:	lda	#$00
	sec
	sbc	Zcc
	sta	Zcc
	lda	#$00
	sbc	Zcc+1
	sta	Zcc+1
	rts


Se813:	lda	Zce
	ora	Zce+1
	beq	int_err_08
	jsr	Se849
.loop1:	rol	Zcc
	rol	Zcc+1
	rol	Zd0
	rol	Zd0+1
	lda	Zd0
	sec
	sbc	Zce
	tay
	lda	Zd0+1
	sbc	Zce+1
	bcc	.fwd1
	sty	Zd0
	sta	Zd0+1
.fwd1:	dex
	bne	.loop1
	rol	Zcc
	rol	Zcc+1
	lda	Zd0
	sta	Zce
	lda	Zd0+1
	sta	Zce+1
	rts


int_err_08:
	lda	#$08
	jmp	int_error


Se849:	ldx	#$10
	lda	#$00
	sta	Zd0
	sta	Zd0+1
	clc
	rts


op_throw:
	lda	arg2
	sta	Zf2
	lda	arg2+1
	sta	Zf2+1
	jmp	op_ret


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


; call instructions that do not store a result
op_call_1n:
op_call_2n:
op_call_vn:
op_call_vn2:
	lda	#$01
	sta	call_store_result_flag
	bne	Le89d


; call instructions that store a result
op_call_1s:
op_call_2s:
op_call_vs:
op_call_vs2
	lda	#$00
	sta	call_store_result_flag

Le89d:	lda	arg1
	ora	arg1+1
	bne	do_call
	lda	call_store_result_flag
	beq	.fwd1
	rts

.fwd1:	ldx	#$00
	jmp	store_result_xa


; do_call is extracted from op_call because in Z-machine architecture v5,
; main procdure is called at game startup
do_call:
	ldx	Zf2
	lda	Zf2+1
	jsr	push_ax
	lda	pc
	ldx	call_store_result_flag
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
	jsr	find_pc_page
	jsr	fetch_pc_byte
	sta	Z6f
	sta	Z6f+1
	beq	.fwd2
	lda	#$00
	sta	Z6d
.loop1:	ldy	Z6d
	ldx	local_vars,y
	lda	local_vars+1,y
	jsr	push_ax
	ldy	Z6d
	lda	#$00
	sta	local_vars,y
	sta	local_vars+1,y
	iny
	iny
	sty	Z6d
	dec	Z6f
	bne	.loop1
	

.fwd2:	lda	Dfdef
	jsr	push_ax

; if present, copy arg2 through arg8 to the first local variables
	dec	argcnt
	lda	argcnt
	sta	Dfdef
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

.fwd3:	ldx	Z6f+1
	txa
	jsr	push_ax
	lda	stk_ptr+1
	sta	Zf2+1
	lda	stk_ptr
	sta	Zf2
	rts


op_storew:
	asl	arg2
	rol	arg2+1
	jsr	Se99a
	lda	arg3+1
	sta	(Z6d),y
	iny
	bne	Le995

op_storeb:
	jsr	Se99a
Le995:	lda	arg3
	sta	(Z6d),y
	rts


Se99a:	lda	arg2
	clc
	adc	arg1
	sta	Z6d
	lda	arg2+1
	adc	arg1+1
	clc
	adc	first_ram_page
	sta	Z6d+1
	ldy	#$00
	rts


op_put_prop:
	jsr	Sf56c
.loop1:	jsr	Sf58a
	cmp	arg2
	beq	.fwd1
	bcc	int_err_0a
	jsr	Sf5b9
	jmp	.loop1

.fwd1:	jsr	Sf58f
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
	jmp	Sf69a


op_print_num:
	lda	arg1
	sta	Zcc
	lda	arg1+1
	sta	Zcc+1
	lda	Zcc+1
	bpl	.fwd1
	lda	#$2d
	jsr	Sf69a
	jsr	Se805
.fwd1:	lda	#$00
	sta	Zd4
.loop1:	lda	Zcc
	ora	Zcc+1
	beq	.fwd2
	lda	#$0a
	sta	Zce
	lda	#$00
	sta	Zce+1
	jsr	Se813
	lda	Zce
	pha
	inc	Zd4
	bne	.loop1
.fwd2:	lda	Zd4
	bne	.loop2
	lda	#$30
	jmp	Sf69a

.loop2:	pla
	clc
	adc	#$30
	jsr	Sf69a
	dec	Zd4
	bne	.loop2
	rts


op_random:
	lda	arg1
	ora	arg1+1
	bne	.fwd1
	sta	Zed
	sta	Zed+1
	jmp	store_result_zero

.fwd1:	lda	Zed
	ora	Zed+1
	bne	.fwd3
	lda	arg1+1
	bpl	.fwd2
	eor	#$ff
	sta	Zed+1
	lda	arg1
	eor	#$ff
	sta	Zed
	inc	Zed
	lda	#$00
	sta	Zc5
	sta	Zc5+1
	beq	.fwd3		; always taken

.fwd2:	lda	arg1
	sta	arg2
	lda	arg1+1
	sta	arg2+1
	jsr	Sf688
	stx	arg1
	and	#$7f
	sta	arg1+1
	jsr	divide
	lda	Zce
	clc
	adc	#$01
	sta	acc
	lda	Zce+1
	adc	#$00
	sta	acc+1
	jmp	store_result

.fwd3:	lda	Zc5+1
	cmp	Zed+1
	bcc	.fwd4
	lda	Zc5
	cmp	Zed
	bcc	.fwd4
	beq	.fwd4
	lda	#$01
	sta	Zc5
	lda	#$00
	sta	Zc5+1
.fwd4:	lda	Zc5
	sta	acc
	lda	Zc5+1
	sta	acc+1
	inc	Zc5
	bne	.fwd5
	inc	Zc5+1
.fwd5:	jmp	store_result


op_push:
	ldx	arg1
	lda	arg1+1
	jmp	push_ax


op_pull:
	jsr	pop_acc
	lda	arg1
	jmp	Le173


op_scan_table:
	lda	arg3+1
	bmi	.fwd3
	ora	arg3
	beq	.fwd3
	lda	argcnt
	cmp	#$04
	beq	.fwd0
.loop0:	lda	#$82
	sta	arg4
.fwd0:	lda	arg4
	beq	.loop0
	lda	#$00
	asl	arg4
	rol
	lsr	arg4
	sta	Dfdee
	lda	Dfdee
	bne	.fwd5
	lda	arg1
	sta	arg1+1
.fwd5:	lda	arg2
	sta	aux_ptr
	lda	arg2+1
	sta	aux_ptr+1
	lda	#$00
	sta	aux_ptr+2
	jsr	find_aux_page
.loop1:	lda	aux_ptr
	fcb	$8d		; sta absolute
	fdb	Z6f+1
	lda	aux_ptr+1
	fcb	$8d		; sta absolute
	fdb	Z71
	lda	aux_ptr+2
	fcb	$8d		; sta absolute
	fdb	Z71+1
	jsr	fetch_aux_byte
	cmp	arg1+1
	bne	.fwd6
	lda	Dfdee
	beq	.fwd4
	jsr	fetch_aux_byte
	cmp	arg1
	beq	.fwd4
.fwd6:	fcb	$ad		; lda absolute
	fdb	Z6f+1
	clc
	adc	arg4
	sta	aux_ptr
	bcc	.fwd1
	fcb	$ad		; lda absolute
	fdb	Z71
	adc	#$00
	sta	aux_ptr+1
	fcb	$ad		; lda absolute
	fdb	Z71+1
	adc	#$00
	sta	aux_ptr+2
	jsr	find_aux_page
.fwd1:	dec	arg3
	bne	.loop1
	lda	arg3+1
	beq	.fwd3
	dec	arg3+1
	bne	.loop1		; always taken

.fwd3:	lda	#$00
	sta	acc
	sta	acc+1
	jsr	store_result
	jmp	predicate_false

.fwd4:	fcb	$ad		; lda absolute
	fdb	Z6f+1
	sta	acc
	fcb	$ad		; lda absolute
	fdb	Z71
	sta	acc+1
	jsr	store_result
	jmp	predicate_true


op_not:	lda	arg1
	eor	#$ff
	sta	acc
	lda	arg1+1
	eor	#$ff
	sta	acc+1
	jmp	store_result


op_copy_table:
	lda	arg2
	ora	arg2+1
	bne	.fwd1
	jmp	.fwd9
.fwd1:	lda	arg3+1
	cmp	#$7f
	bcc	.fwd2
	jmp	.fwd10

.fwd2:	lda	arg1+1
	cmp	arg2+1
	bcc	.fwd4
	beq	.fwd3
	jmp	.fwd5

.fwd3:	lda	arg1
	cmp	arg2
	beq	.fwd4
	bcs	.fwd5
.fwd4:	lda	arg1
	clc
	adc	arg3
	sta	Z6d
	lda	arg1+1
	adc	arg3+1
	cmp	arg2+1
	bcc	.fwd5
	bne	.fwd6
	lda	Z6d
	cmp	arg2
	beq	.fwd5
	bcs	.fwd6
.fwd5:	lda	#$00
	sta	aux_ptr+2
	lda	arg1+1
	sta	aux_ptr+1
	lda	arg1
	sta	aux_ptr
	jsr	find_aux_page
	lda	arg2
	sta	Z6d
	lda	arg2+1
	clc
	adc	first_ram_page
	sta	Z6d+1
	lda	arg3
	sta	Z6f
	lda	arg3+1
	sta	Z6f+1
.loop1:	jsr	Sf0fb
	bcc	.rtn
	jsr	fetch_aux_byte
	ldy	#$00
	sta	(Z6d),y
	inc	Z6d
	bne	.loop1
	inc	Z6d+1
	jmp	.loop1

.rtn:	rts

.fwd6:	lda	arg3
	sta	Z6f
	lda	arg3+1
	sta	Z6f+1
	jsr	Sf0fb
	lda	arg1
	clc
	adc	Z6f
	sta	Z6d
	lda	arg1+1
	adc	Z6f+1
	clc
	adc	first_ram_page
	sta	Z6d+1
	lda	arg2
	clc
	adc	Z6f
	sta	Z71
	lda	arg2+1
	adc	Z6f+1
	clc
	adc	first_ram_page
	sta	Z71+1
.loop2:	ldy	#$00
	lda	(Z6d),y
	sta	(Z71),y
	lda	Z6d
	bne	.fwd7
	dec	Z6d+1
.fwd7:	dec	Z6d
	lda	Z71
	bne	.fwd8
	dec	Z71+1
.fwd8:	dec	Z71
	jsr	Sf0fb
	bcs	.loop2
	rts

.fwd9:	lda	arg1
	sta	Z6d
	lda	arg1+1
	clc
	adc	first_ram_page
	sta	Z6d+1
	lda	arg3
	sta	Z6f
	lda	arg3+1
	sta	Z6f+1
	ldy	#$00
.loop3:	jsr	Sf0fb
	bcc	.rtn2
	lda	#$00
	sta	(Z6d),y
	iny
	bne	.loop3
	inc	Z6d+1
	jmp	.loop3

.rtn2:	rts

.fwd10:	lda	arg3
	eor	#$ff
	sta	arg3
	lda	arg3+1
	eor	#$ff
	sta	arg3+1
	inc	arg3
	bne	.fwd11
	inc	arg3+1
.fwd11:	jmp	.fwd5


op_check_arg_count:
	lda	arg1
	cmp	Dfdef
	bcc	.rtn_t
	beq	.rtn_t
	jmp	predicate_false

.rtn_t:	jmp	predicate_true


op_log_shift:
	lda	arg1
	sta	acc
	lda	arg1+1
	sta	acc+1
	lda	arg2
	cmp	#$80
	bcs	.fwd1
	tay
.loop1:	asl	acc
	rol	acc+1
	dey
	bne	.loop1
	jmp	store_result

.fwd1:	eor	#$ff
	tay
.loop2:	lsr	acc+1
	ror	acc
	dey
	bpl	.loop2
	jmp	store_result


op_art_shift:
	lda	arg2
	cmp	#$80
	bcc	op_log_shift
	ldx	arg1
	stx	acc
	ldx	arg1+1
	stx	acc+1
	eor	#$ff
	tay
.loop1:	lda	arg1+1
	asl
	ror	acc+1
	ror	acc
	dey
	bpl	.loop1
	jmp	store_result


op_aread:
	lda	arg1+1
	clc
	adc	first_ram_page
	sta	Zc9
	lda	arg1
	sta	Zc8
	lda	#$00
	sta	Zb2
	sta	Zb3
	ldx	argcnt
	dex
	beq	.fwd1
	ldx	#$00
	lda	arg2+1
	ora	arg2
	beq	.fwd1
	lda	arg2+1
	clc
	adc	first_ram_page
	sta	Zcb
	lda	arg2
	sta	Zca
	ldx	#$01
.fwd1:	stx	Dfdf1
	jsr	Sfada
	lda	Dfdf1
	beq	.fwd2
	jsr	Secec
.fwd2:	lda	#$f0
	sta	Dfdf1
	lda	Dfdf0
	ldx	#$00
	jmp	store_result_xa


; core of aread and tokenize
Secec:	ldy	#$01
	lda	(Zc8),y
	sta	Za1
	lda	#$00
	sta	Za2
	sta	(Zca),y
	iny
	sty	Z9f
	sty	Za0
.loop1:	ldy	#$00
	lda	(Zca),y
	beq	.fwd1
	cmp	#$3b
	bcc	.fwd2
.fwd1:	lda	#$3a
	sta	(Zca),y
.fwd2:	iny
	cmp	(Zca),y
	bcc	.rtn
	lda	Za1
	ora	Za2
	bne	.fwd3
.rtn:	rts

.fwd3:	lda	Za2
	cmp	#$09
	bcc	.fwd4
	jsr	See46
.fwd4:	lda	Za2
	bne	.fwd5
	ldx	#$08
.loop2:	sta	Z8d,x
	dex
	bpl	.loop2
	jsr	See38
	lda	Z9f
	ldy	#$03
	sta	(Za3),y
	tay
	lda	(Zc8),y
	jsr	See74
	bcs	.fwd6
	jsr	See68
	bcc	.fwd5
	inc	Z9f
	dec	Za1
	jmp	.loop1

.fwd5:	lda	Za1
	beq	.fwd7
	ldy	Z9f
	lda	(Zc8),y
	jsr	See63
	bcs	.fwd7
	ldx	Za2
	sta	Z8d,x
	dec	Za1
	inc	Za2
	inc	Z9f
	jmp	.loop1

.fwd6:	sta	Z8d
	dec	Za1
	inc	Za2
	inc	Z9f
.fwd7:	lda	Za2
	beq	.loop1
	jsr	See38
	lda	Za2
	ldy	#$02
	sta	(Za3),y
	jsr	Sf435
	jsr	See9f
	ldy	#$01
	lda	(Zca),y
	clc
	adc	#$01
	sta	(Zca),y
	ldy	#$00
	sty	Za2
	lda	Zb2
	beq	.fwd8
	lda	acc+1
	ora	acc
	beq	.fwd9
.fwd8:	lda	acc+1
	sta	(Za3),y
	iny
	lda	acc
	sta	(Za3),y
.fwd9:	lda	Za0
	clc
	adc	#$04
	sta	Za0
	jmp	.loop1


op_tokenise:
	lda	arg1+1
	clc
	adc	first_ram_page
	sta	Zc9
	lda	arg1
	sta	Zc8
	lda	arg2+1
	clc
	adc	first_ram_page
	sta	Zcb
	lda	arg2
	sta	Zca
	dec	argcnt
	dec	argcnt
	beq	.fwd2
	lda	#$01
	sta	Zb3
	lda	#$00
	dec	argcnt
	beq	.fwd1
	lda	#$01
.fwd1:	sta	Zb2
	jmp	.fwd3

.fwd2:	lda	#$00
	sta	Zb3
	sta	Zb2
.fwd3:	jmp	Secec


op_encode_text:
	lda	arg1+1
	clc
	adc	first_ram_page
	sta	Zc9
	lda	arg1
	sta	Zc8
	lda	arg3
	clc
	adc	Zc8
	sta	Zc8
	lda	arg3+1
	adc	Zc9
	sta	Zc9
	lda	arg4+1
	clc
	adc	first_ram_page
	sta	Zcb
	lda	arg4
	sta	Zca
	lda	#$09
	sta	Za1
	lda	#$00
	sta	Za2
	ldx	#$08
.loop1:	sta	Z8d,x
	dex
	bpl	.loop1
.loop2:	ldy	Za2
	lda	(Zc8),y
	jsr	See63
	bcs	.fwd1
	ldy	Za2
	lda	(Zc8),y
	ldx	Za2
	sta	Z8d,x
	inc	Za2
	dec	Za1
	bne	.loop2
.fwd1:	lda	Za2
	beq	.rtn
	jsr	Sf435
	ldy	#$05
.loop3:	lda	Z96,y
	sta	(Zca),y
	dey
	bpl	.loop3
.rtn:	rts


See38:	lda	Zca
	clc
	adc	Za0
	sta	Za3
	lda	Zcb
	adc	#$00
	sta	Za4
	rts


See46:	lda	Za1
	beq	.rtn
	ldy	Z9f
	lda	(Zc8),y
	jsr	See63
	bcs	.rtn
	dec	Za1
	inc	Za2
	inc	Z9f
	bne	See46
.rtn:	rts


Dee5c:	fcb	$21,$3f,$2c,$2e,$0d,$20,$00   	; "!?,.. ."


See63:	jsr	See74
	bcs	Lee9d

See68:	ldx	#$06
.loop1:	cmp	Dee5c,x
	beq	Lee9d
	dex
	bpl	.loop1
	clc
	rts


See74:	sta	Zdc
	lda	hdr_vocab
	ldy	hdr_vocab+1
	sta	aux_ptr+1
	sty	aux_ptr
	lda	#$00
	sta	aux_ptr+2
	jsr	find_aux_page
	jsr	fetch_aux_byte
	sta	Z6f
.loop1:	jsr	fetch_aux_byte
	cmp	Zdc
	beq	.fwd1
	dec	Z6f
	bne	.loop1
	lda	Zdc
	clc
	rts

.fwd1:	lda	Zdc
Lee9d:	sec
	rts


See9f:	lda	Zb3
	beq	.fwd0
	lda	arg3+1
	ldy	arg3
	jmp	.fwd0a
.fwd0:	lda	hdr_vocab
	ldy	hdr_vocab+1
.fwd0a:	sta	aux_ptr+1
	sty	aux_ptr
	lda	#$00
	sta	aux_ptr+2
	jsr	find_aux_page
	jsr	fetch_aux_byte
	clc
	adc	aux_ptr
	sta	aux_ptr
	bcc	.fwd1
	inc	aux_ptr+1
.fwd1:	jsr	find_aux_page
	jsr	fetch_aux_byte
	sta	Za7
	sta	Z6d
	lda	#$00
	sta	Z6d+1
	sta	Z6f
	jsr	fetch_aux_byte
	sta	Za6
	jsr	fetch_aux_byte
	sta	Za5
	lda	Za6
	bpl	.fwd1a
	jmp	.fwd11

.fwd1a:	lda	#$00
	sta	Zf9
	sta	Zfa
	sta	Zfb
	ldx	Za7
.loop1:	clc
	lda	Zf9
	adc	Za5
	sta	Zf9
	lda	Zfa
	adc	Za6
	sta	Zfa
	lda	Zfb
	adc	#$00
	sta	Zfb
	dex
	bne	.loop1
	clc
	lda	Zf9
	adc	aux_ptr
	sta	Zf9
	lda	Zfa
	adc	aux_ptr+1
	sta	Zfa
	lda	Zfb
	adc	aux_ptr+2
	sta	Zfb
	lda	Zf9
	sec
	sbc	Za7
	sta	Zf9
	lda	Zfa
	sbc	#$00
	sta	Zfa
	lsr	Za6
	ror	Za5
.loop2:	asl	Z6d
	rol	Z6d+1
	rol	Z6f
	lsr	Za6
	ror	Za5
	bne	.loop2
	clc
	lda	aux_ptr
	adc	Z6d
	sta	aux_ptr
	lda	aux_ptr+1
	adc	Z6d+1
	sta	aux_ptr+1
	lda	aux_ptr+2
	adc	Z6f
	sta	aux_ptr+2
	sec
	lda	aux_ptr
	sbc	Za7
	sta	aux_ptr
	bcs	.loop3
	lda	aux_ptr+1
	sec
	sbc	#$01
	sta	aux_ptr+1
	bcs	.loop3
	lda	aux_ptr+2
	sbc	#$00
	sta	aux_ptr+2
.loop3:	lsr	Z6f
	ror	Z6d+1
	ror	Z6d
	lda	aux_ptr
	sta	Z6f+1
	lda	aux_ptr+1
	sta	Z71
	lda	aux_ptr+2
	sta	Z71+1
	jsr	find_aux_page
	jsr	fetch_aux_byte
	cmp	Z96
	bcc	.fwd2
	bne	.fwd6
	jsr	fetch_aux_byte
	cmp	Z97
	bcc	.fwd2
	bne	.fwd6
	jsr	fetch_aux_byte
	cmp	Z98
	bcc	.fwd2
	bne	.fwd6
	jsr	fetch_aux_byte
	cmp	Z99
	bcc	.fwd2
	bne	.fwd6
	jsr	fetch_aux_byte
	cmp	Z9a
	bcc	.fwd2
	bne	.fwd6
	jsr	fetch_aux_byte
	cmp	Z9b
	beq	.fwd10
	bcs	.fwd6
.fwd2:	lda	Z6f+1
	clc
	adc	Z6d
	sta	aux_ptr
	lda	Z71
	adc	Z6d+1
	bcs	.fwd5
	sta	aux_ptr+1
	lda	#$00
	sta	aux_ptr+2
	lda	aux_ptr+1
	cmp	Zfa
	beq	.fwd3
	bcs	.fwd5
	bcc	.fwd7		; always taken
.fwd3:	lda	aux_ptr
	cmp	Zf9
	bcc	.fwd7
	beq	.fwd7

.fwd5:	lda	Zf9
	sta	aux_ptr
	lda	Zfa
	sta	aux_ptr+1
	lda	Zfb
	sta	aux_ptr+2
	jmp	.fwd7

.fwd6:	lda	Z6f+1
	sec
	sbc	Z6d
	sta	aux_ptr
	lda	Z71
	sbc	Z6d+1
	sta	aux_ptr+1
	lda	Z71+1
	sbc	Z6f
	sta	aux_ptr+2
.fwd7:	lda	Z6f
	bne	.fwd8
	lda	Z6d+1
	bne	.fwd8
	lda	Z6d
	cmp	Za7
	bcc	.fwd9
.fwd8:	jmp	.loop3

.fwd9:	lda	#$00
	sta	acc
	sta	acc+1
	rts

.fwd10:	lda	Z6f+1
	sta	acc
	lda	Z71
	sta	acc+1
	rts

.fwd11:	lda	#$ff
	eor	Za6
	sta	Za6
	lda	#$ff
	eor	Za5
	sta	Za5
	inc	Za5
	bne	.loop4
	inc	Za6
.loop4:	lda	aux_ptr
	sta	Z6f+1
	lda	aux_ptr+1
	sta	Z71
	lda	aux_ptr+2
	sta	Z71+1
	jsr	fetch_aux_byte
	cmp	Z96
	bne	.fwd12
	jsr	fetch_aux_byte
	cmp	Z97
	bne	.fwd12
	jsr	fetch_aux_byte
	cmp	Z98
	bne	.fwd12
	jsr	fetch_aux_byte
	cmp	Z99
	bne	.fwd12
	jsr	fetch_aux_byte
	cmp	Z9a
	bne	.fwd12
	jsr	fetch_aux_byte
	cmp	Z9b
	beq	.fwd10
.fwd12:	lda	Z6f+1
	clc
	adc	Za7
	sta	aux_ptr
	bcc	.fwd13
	lda	Z71
	adc	#$00
	sta	aux_ptr+1
	lda	#$00
	sta	aux_ptr+2
	jsr	find_aux_page
.fwd13:	dec	Za5
	bne	.loop4
	lda	Za6
	beq	.fwd9
	dec	Za6
	jmp	.loop4


Sf081:	lda	Z6d
	sta	aux_ptr
	lda	Z6d+1
	sta	aux_ptr+1
	lda	#$00
	sta	aux_ptr+2
	jmp	find_aux_page


Df090:	fcb	$00
Df091:	fcb	$00
Df092:	fcb	$00
Df093:	fcb	$00
Df094:	fcb	$00
Df095:	fcb	$00
Df096:	fcb	$00
Df097:	fcb	$00
Df098:	fcb	$00
Df099:	fcb	$00
Df09a:	fcb	$00
Df09b:	fcb	$00

	if	iver>=iver_e
Df0d4:	fcb	$00
	endif


Lf09c:
	if	iver>=iver_e

; This 16-bit compare seems totally wrong. It compares the low byte first.

	lda	hdr_high_mem
	cmp	hdr_length
	bcc	.fwd2
	bne	.fwd1
	lda	hdr_high_mem+1
	cmp	hdr_length+1
	bcc	.fwd2
.fwd1	lda	#$01
	sta	Df0d4
.fwd2:
	endif

	lda	hdr_length+1
	sta	Z6f
	lda	hdr_length
	ldy	#$05
.loop1:	lsr
	ror	Z6f
	dey
	bpl	.loop1
	sta	Z6f+1
.loop2:	jsr	Sf0fb
	bcc	.rtn
	jsr	Sd51d
	lda	Df090
	cmp	#$01
	bne	.loop2
	lda	Zb8
	cmp	#$96
	bne	.loop2
	lda	#$00
	sta	Df090
	lda	#$00
	sta	Df091
.loop3:	lda	#$0a
	sta	Zb8
	jsr	Sf0fb
	bcc	.rtn
	jsr	Sd51d
	ldy	#$0a
	lda	Df091
	ldx	#$01
	sta	rd_main_ram
	jsr	S0856
	inc	Df091
	lda	Df091
	cmp	#$4f
	bcc	.loop3
	jsr	Sdccf
	lda	#$02
	sta	cursrv

	if	iver>=iver_e

	lda	Df0d4
	bne	.rtn

	endif

	jmp	Sd899

.rtn:	rts


Sf0fb:	lda	Z6f
	sec
	sbc	#$01
	sta	Z6f
	lda	Z6f+1
	sbc	#$00
	sta	Z6f+1
	rts


find_aux_page:
	lda	aux_ptr+2
	bne	.fwd2
	lda	aux_ptr+1
	cmp	#$ad
	bcs	.fwd1
	adc	#$13
	ldy	#$00
	beq	.fwd3		; always taken

.fwd1:	sbc	#$a5
	ldy	#$01
	bne	.fwd3		; always taken

.fwd2:	cmp	#$01
	bne	.fwd4
	lda	aux_ptr+1
	cmp	#$3b
	bcs	.fwd4
	adc	#$5b
	ldy	#$01
.fwd3:	sty	aux_phys_page+2
	sta	aux_phys_page+1
.rtn:	rts

.fwd4:	lda	aux_ptr+2
	ldy	aux_ptr+1
	jsr	find_page
	clc
	adc	#$96
	sta	aux_phys_page+1
	ldy	#$01
	sty	aux_phys_page+2
	lda	Df18b
	beq	.rtn
	jmp	find_pc_page		; unnecessary, could just fall through


; find PC page
find_pc_page:
	lda	pc+2
	bne	.fwd2
	lda	pc+1
	cmp	#max_main_ram_pages
	bcs	.fwd1
	adc	#hdr_arch>>8
	ldy	#$00
	beq	.fwd3		; always taken

.fwd1:	sbc	#$a5		; FIXME - not sure how this is determiend
	ldy	#$01
	bne	.fwd3		; always taken

.fwd2:	cmp	#$01
	bne	.fwd4
	lda	pc+1
	cmp	#$3b		; FIXME - not sure how this is determiend
	bcs	.fwd4
	adc	#$5b		; FIXME - not sure how this is determiend
	ldy	#$01
.fwd3:	sty	pc_phys_page+2
	sta	pc_phys_page+1
.rtn:	rts

.fwd4:	lda	pc+2
	ldy	pc+1
	jsr	find_page
	clc
	adc	#$96		; FIXME - not sure how this is determiend
	sta	pc_phys_page+1
	ldy	#$01
	sty	pc_phys_page+2
	lda	Df18b
	beq	.rtn
	jmp	find_aux_page


Df18b:	fcb	$00


find_page:
	sta	Df093
	sty	Df092
	ldx	#$00
	stx	Df18b
	jsr	Sf260
	bcc	.fwd1
	ldx	Df094
	lda	D0d00,x
	sta	Df094
	tax
	lda	Df093
	sta	D0e00,x
	lda	Df092
	sta	D0e80,x
	tay
	txa
	pha
	lda	Df093
	jsr	fetch_page
	dec	Df18b
	pla
	rts

.fwd1:	sta	Df095
	cmp	Df094
	bne	.fwd2
	rts

.fwd2:	ldy	Df094
	lda	D0d00,y
	sta	Df098
	lda	Df095
	jsr	Sf242
	ldy	Df094
	lda	Df095
	jsr	Sf21c
	lda	Df095
	sta	Df094
	rts


fetch_page:
	cmp	#$01
	bcc	.fwd2
	bne	.fwd1
	cpy	#$8a
	bcc	.fwd2
.fwd1:	sta	disk_block_num+1
	sty	disk_block_num
	txa
	clc
	adc	#$96		; FIXME - not sure how this is determined
	sta	Zb8
	ldx	#$01
	stx	Df090
	jmp	Sd51d

.fwd2:	tya
	sec
	sbc	#$3b		; FIXME - not sure how this is determined
	pha
	txa
	clc
	adc	#$96		; FIXME - not sure how this is determined
	tay
	sta	rd_main_ram
	ldx	#$01
	stx	D0855
	ldx	#$00
	pla
	jmp	S0856


Sf21c:	sta	Df09a
	sty	Df099
	tax
	tya
	sta	D0d80,x
	lda	D0d00,y
	sta	Df09b
	txa
	ldx	Df09b
	sta	D0d80,x
	txa
	ldx	Df09a
	sta	D0d00,x
	lda	Df09a
	sta	D0d00,y
	rts


Sf242:	tax
	lda	D0d00,x
	sta	Df096
	lda	D0d80,x
	sta	Df097
	tax
	lda	Df096
	sta	D0d00,x
	lda	Df097
	ldx	Df096
	sta	D0d80,x
	rts


Sf260:	ldx	#$29		; FIXME - not sure how this is determined
.loop1:	lda	Df093
	cmp	D0e00,x
	beq	.fwd1
.loop2:	dex
	bpl	.loop1
	sec
	rts

.fwd1:	tya
	cmp	D0e80,x
	bne	.loop2
	txa
	clc
	rts


Sf278:	ldx	#$29		; FIXME - not sure how this is determined
	stx	Df094
	lda	#$ff
.loop1:	sta	D0e00,x
	dex
	bpl	.loop1
	ldx	#$00
	ldy	#$01
.loop2:	tya
	sta	D0d80,x
	inx
	iny
	cpx	#$2a		; FIXME - not sure how this is determined
	bcc	.loop2
	lda	#$00
	dex
	sta	D0d80,x
	ldx	#$00
	ldy	#$ff
	lda	#$29		; FIXME - not sure how this is determined
.loop3:	sta	D0d00,x
	inx
	iny
	tya
	cpx	#$2a
	bcc	.loop3
	jmp	Lf09c


Sf2ac:	pha
	inc	aux_ptr+1
	bne	.fwd1
	inc	aux_ptr+2
.fwd1:	jsr	find_aux_page
	pla
	rts


advance_pc_page:
	pha
	inc	pc+1
	bne	Lf2bf
	inc	pc+2
Lf2bf:	jsr	find_pc_page
	pla
	rts


; Fetch one byte from the aux ptr and increment the aux ptr
; On exit:
;   A = fetched byte
;   Y = fetched byte
fetch_aux_byte:
	ldy	aux_phys_page+2
	sta	rd_main_ram,y
	ldy	aux_ptr
	lda	(aux_phys_page),y
	sta	rd_main_ram
	inc	aux_ptr
	bne	.fwd1
	jsr	Sf2ac
.fwd1:	tay
	rts


; Fetch one byte from the PC and increment the PC
; On exit:
;   A = fetched byte
;   Y = fetched byte
fetch_pc_byte:
	fetch_pc_byte_inline
	rts


Sf2ee:	lda	Z6d
	asl
	sta	aux_ptr
	lda	Z6d+1
	rol
	sta	aux_ptr+1
	lda	#$00
	rol
	sta	aux_ptr+2
	asl	aux_ptr
	rol	aux_ptr+1
	rol	aux_ptr+2
	jmp	find_aux_page


Lf306:	rts

Sf307:	ldx	#$00
	stx	Za8
	stx	Zac
	dex
	stx	Za9
.loop1:	jsr	Sf3ed
	bcs	Lf306
	sta	Zaa
	tax
	beq	.fwd4
	cmp	#$04
	bcc	.fwd7
	cmp	#$06
	bcc	.fwd5
	jsr	Sf3cf
	tax
	bne	.fwd1
	lda	#$5b
.loop2:	clc
	adc	Zaa
.loop3:	jsr	Sf69a
	jmp	.loop1

.fwd1:	cmp	#$01
	bne	.fwd2
	lda	#$3b
	bne	.loop2		; always taken

.fwd2:	lda	Zaa
	sec
	sbc	#$06
	beq	.fwd3
	tax
	lda	Df51e,x
	jmp	.loop3

.fwd3:	jsr	Sf3ed
	asl
	asl
	asl
	asl
	asl
	sta	Zaa
	jsr	Sf3ed
	ora	Zaa
	jmp	.loop3

.fwd4:	lda	#$20
	bne	.loop3		; always taken

.fwd5:	sec
	sbc	#$03
	tay
	jsr	Sf3cf
	bne	.fwd6
	sty	Za9
	jmp	.loop1

.fwd6:	sty	Za8
	cmp	Za8
	beq	.loop1
	lda	#$00
	sta	Za8
	beq	.loop1		; always taken

.fwd7:	sec
	sbc	#$01
	asl
	asl
	asl
	asl
	asl
	asl
	sta	Zab
	jsr	Sf3ed
	asl
	clc
	adc	Zab
	tay
	lda	(Z87),y
	sta	Z6d+1
	iny
	lda	(Z87),y
	sta	Z6d
	lda	aux_ptr+2
	pha
	lda	aux_ptr+1
	pha
	lda	aux_ptr
	pha
	lda	Za8
	pha
	lda	Zac
	pha
	lda	Zae
	pha
	lda	Zad
	pha
	jsr	Sf3db
	jsr	Sf307
	pla
	sta	Zad
	pla
	sta	Zae
	pla
	sta	Zac
	pla
	sta	Za8
	pla
	sta	aux_ptr
	pla
	sta	aux_ptr+1
	pla
	sta	aux_ptr+2
	ldx	#$ff
	stx	Za9
	jsr	find_aux_page
	jmp	.loop1


Sf3cf:	lda	Za9
	bpl	.fwd1
	lda	Za8
	rts

.fwd1:	ldy	#$ff
	sty	Za9
	rts


Sf3db:	lda	Z6d
	asl
	sta	aux_ptr
	lda	Z6d+1
	rol
	sta	aux_ptr+1
	lda	#$00
	rol
	sta	aux_ptr+2
	jmp	find_aux_page


Sf3ed:	lda	Zac
	bpl	.fwd1
	sec
	rts

.fwd1:	bne	.fwd2
	inc	Zac
	jsr	fetch_aux_byte
	sta	Zae
	jsr	fetch_aux_byte
	sta	Zad
	lda	Zae
	lsr
	lsr
	jmp	.fwd5

.fwd2:	sec
	sbc	#$01
	bne	.fwd3
	lda	#$02
	sta	Zac
	lda	Zad
	sta	Z6d
	lda	Zae
	asl	Z6d
	rol
	asl	Z6d
	rol
	asl	Z6d
	rol
	jmp	.fwd5

.fwd3:	lda	#$00
	sta	Zac
	lda	Zae
	bpl	.fwd4
	lda	#$ff
	sta	Zac
.fwd4:	lda	Zad
.fwd5:	and	#$1f
	clc
	rts


Sf435:	lda	#$05
	ldx	#$08
.loop1:	sta	Z96,x
	dex
	bpl	.loop1
	lda	#$09
	sta	Zaf
	lda	#$00
	sta	Zb0
	sta	Zb1
.loop2:	ldx	Zb0
	inc	Zb0
	lda	Z8d,x
	sta	Zaa
	bne	.fwd1
	lda	#$05
	bne	.loop3		; alway taken

.fwd1:	lda	Zaa
	jsr	get_letter_case
	beq	.fwd3
	clc
	adc	#$03
	ldx	Zb1
	sta	Z96,x
	inc	Zb1
	dec	Zaf
	bne	.fwd2
	jmp	Lf4e5

.fwd2:	lda	Zaa
	jsr	get_letter_case
	cmp	#$02
	beq	.fwd4
	lda	Zaa
	sec
	sbc	#$3b
	bpl	.loop3
.fwd3:	lda	Zaa
	sec
	sbc	#$5b
.loop3:	ldx	Zb1
	sta	Z96,x
	inc	Zb1
	dec	Zaf
	bne	.loop2
	jmp	Lf4e5

.fwd4:	lda	Zaa
	jsr	Sf4bc
	bne	.loop3
	lda	#$06
	ldx	Zb1
	sta	Z96,x
	inc	Zb1
	dec	Zaf
	beq	Lf4e5
	lda	Zaa
	lsr
	lsr
	lsr
	lsr
	lsr
	and	#$03
	ldx	Zb1
	sta	Z96,x
	inc	Zb1
	dec	Zaf
	beq	Lf4e5
	lda	Zaa
	and	#$1f
	jmp	.loop3


Sf4bc:	ldx	#$19
.loop1:	cmp	Df51e,x
	beq	.fwd1
	dex
	bne	.loop1
	rts

.fwd1:	txa
	clc
	adc	#$06
	rts


; On entry:
;   A = charcter
; On return:
;   A = $00 for lower case alpha
;       $01 for upper case alpha
;       $02 for non-alpha
get_letter_case:
	cmp	#'a'
	bcc	.fwd1
	cmp	#'z'+1
	bcs	.fwd1
	lda	#$00
	rts

.fwd1:	cmp	#'A'
	bcc	.fwd2
	cmp	#'Z'+1
	bcs	.fwd2
	lda	#$01
	rts

.fwd2:	lda	#$02
	rts


Lf4e5:	lda	Z97
	asl
	asl
	asl
	asl
	rol	Z96
	asl
	rol	Z96
	ora	Z98
	sta	Z97
	lda	Z9a
	asl
	asl
	asl
	asl
	rol	Z99
	asl
	rol	Z99
	ora	Z9b
	tax
	lda	Z99
	sta	Z98
	stx	Z99
	lda	Z9d
	asl
	asl
	asl
	asl
	rol	Z9c
	asl
	rol	Z9c
	ora	Z9e
	sta	Z9b
	lda	Z9c
	ora	#$80
	sta	Z9a
	rts


Df51e:	fcb	$00,char_cr
	fcb	"0123456789"
	fcb	".,!?_#'"
	fcb	$22		; double quote
	fcb	"/"
	fcb	$5c		; backslash
	fcb	"-:()"


setup_object:
	stx	Z6d+1
	asl
	sta	Z6d
	rol	Z6d+1
	ldx	Z6d+1
	asl
	rol	Z6d+1
	asl
	rol	Z6d+1
	asl
	rol	Z6d+1
	sec
	sbc	Z6d
	sta	Z6d
	lda	Z6d+1
	stx	Z6d+1
	sbc	Z6d+1
	sta	Z6d+1
	lda	Z6d
	clc
	adc	#$70
	bcc	.fwd1
	inc	Z6d+1
.fwd1:	clc
	adc	Z89
	sta	Z6d
	lda	Z6d+1
	adc	Z8a
	sta	Z6d+1
	rts


Sf56c:	lda	arg1
	ldx	arg1+1
	jsr	setup_object
	ldy	#$0c
	lda	(Z6d),y
	clc
	adc	first_ram_page
	tax
	iny
	lda	(Z6d),y
	sta	Z6d
	stx	Z6d+1
	ldy	#$00
	lda	(Z6d),y
	asl
	tay
	iny
	rts

Sf58a:	lda	(Z6d),y
	and	#$3f
	rts


Sf58f:	lda	(Z6d),y
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


Sf5a7:	jsr	Sf58f
	tax
.loop1:	iny
	bne	.fwd1
	inc	Z6d
	bne	.fwd1
	inc	Z6d+1
.fwd1:	dex
	bne	.loop1
	iny
	rts


Sf5b9:	jsr	Sf5a7
	tya
	clc
	adc	Z6d
	sta	Z6d
	bcc	.fwd1
	inc	Z6d+1
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
	inc	Z6d+1
	jmp	.fwd2

.fwd1:	lda	Z6d
	clc
	adc	#$02
	sta	Z6d
	bcc	.fwd2
	inc	Z6d+1
.fwd2:	txa
.fwd3:	sta	Z71
	ldx	#$01
	stx	Z6f
	dex
	stx	Z6f+1
	lda	#$0f
	sec
	sbc	Z71
	tax
	beq	.fwd4
.loop1:	asl	Z6f
	rol	Z6f+1
	dex
	bne	.loop1
.fwd4:	ldy	#$00
	lda	(Z6d),y
	sta	Z71+1
	iny
	lda	(Z6d),y
	sta	Z71
	rts


msg_internal_error:
	text_str	"Internal error "
Df62d:	text_str	"00.  "
msg_len_internal_error	equ	*-msg_internal_error


; On entry:
;   A = error number
; Does not return
int_error:
	ldy	#$01
.loop1:	ldx	#0
.loop2:	cmp	#10
	bcc	.fwd1
	sbc	#10
	inx
	bne	.loop2
.fwd1:	ora	#$30
	sta	Df62d,y
	txa
	dey
	bpl	.loop1
	prt_msg	internal_error
	jmp	Lf657


; Does not return
op_quit:
	jsr	new_line
Lf657:	prt_msg	end_of_session
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
	stx	Ddba9
.fwd1:	jsr	Sd871
	jmp	restart


; Unreferenced. See S14dc in ZIP version F
	lda	#$fb
	rts


Sf688:	inc	rndloc
	dec	rndloc+1
	lda	rndloc
	adc	Zc5
	tax
	lda	rndloc+1
	sbc	Zc5+1
	sta	Zc5
	stx	Zc5+1
	rts


Sf69a:	sta	Zdc
	ldx	ostream_3_state
	beq	.fwd1
	jmp	Lf728

.fwd1:	ldx	ostream_1_state
	bne	.fwd2
	ldx	ostream_2_state
	bne	.fwd2
	rts

.fwd2:	lda	Zdc
	ldx	Zc2
	bne	Sf6d6
	cmp	#char_cr
	bne	.fwd3
	jmp	new_line

.fwd3:	cmp	#' '
	bcc	.rtn
	ldx	invflg
	bpl	.fwd4
	ora	#$80
.fwd4:	ldx	Zd6
	sta	D0200,x

	if	iver<=iver_c

	ldy	Zd5
	cpy	Zc4

	else

	lda	Zc7
	bne	.fwd5
	ldy	Zd5
	inc	Zd5
	cpy	Zc4

	endif

	bcc	.fwd5
	jmp	Lf742

.fwd5:
	if	iver<=iver_c
	inc	Zd5
	endif

	inc	Zd6
.rtn:	rts


Sf6d6:	sta	Zdc
	lda	D057b
	cmp	#$50
	bcs	.rtn
	lda	Zc7
	beq	.fwd1
	lda	cursrv
	cmp	wndtop
	bcs	.rtn
	bcc	.fwd2		; always taken

.fwd1:	lda	cursrv
	cmp	wndtop
	bcc	.rtn
.fwd2:	lda	ostream_1_state
	beq	.fwd3
	lda	Zdc
	ora	#$80
	jsr	Sdb39
.fwd3:	lda	Zd9
	beq	.rtn
	lda	ostream_2_state
	beq	.rtn
	lda	cswl
	pha
	lda	cswl+1
	pha
	lda	D057b
	pha
	lda	Ddbaa
	sta	cswl
	lda	Ddbaa+1
	sta	cswl+1
	lda	Zdc
	jsr	S08ef
	pla
	sta	D057b
	pla
	sta	cswl+1
	pla
	sta	cswl
.rtn:	rts


Lf728:	tax
	lda	Zbe
	clc
	adc	Zbc
	sta	Z6d
	lda	Zbf
	adc	Zbd
	sta	Z6d+1
	ldy	#$00
	txa
	sta	(Z6d),y
	inc	Zbe
	bne	.rtn
	inc	Zbf
.rtn:	rts


Lf742:	lda	#$a0
	stx	Zd8
.loop1:	cmp	D0200,x
	beq	.fwd1
	dex
	bne	.loop1
	ldx	Zc4
.fwd1:	stx	Zd7
	stx	Zd6
	jsr	new_line
	ldx	Zd7
	ldy	#$00
.loop2:	inx
	cpx	Zd8
	bcc	.fwd2
	beq	.fwd2
	sty	Zd5
	sty	Zd6
	rts

.fwd2:	lda	D0200,x
	sta	D0200,y
	iny
	bne	.loop2


op_new_line:
	ldx	ostream_3_state
	beq	new_line
	lda	#char_cr
	jmp	Lf728


new_line:
	ldx	Zd6
	lda	#$8d
	sta	D0200,x
	inc	Zd6
	lda	ostream_1_state
	beq	.fwd2
	lda	Zc7
	bne	.fwd2
	inc	Zda
	ldx	Zda
	cpx	wndbot
	bne	.fwd2
	lda	wndtop
	sta	Zda

	if	iver>=iver_c
	inc	Zda
	inc	Zda
	endif

	bit	kbd_strb
	lda	hdr_unknown_29
	sta	D057b
	prt_msg_alt	more
.loop1:	bit	kbd
	bpl	.loop1
	bit	kbd_strb
	ldy	#$06
.loop2:	lda	#$08
	jsr	S08ef
	dey
	bne	.loop2
	jsr	S08c5
.fwd2:	jsr	Sf7ca
	jsr	Sf7e4
	lda	#$00
	sta	Zd5
	sta	Zd6
	rts


Sf7ca:	ldy	Zd6
	beq	.rtn
	sty	Ze3
	lda	ostream_1_state
	beq	.fwd1
	ldx	#$00
.loop1:	lda	D0200,x
	jsr	Sdb39
	inx
	dey
	bne	.loop1
.fwd1:	jsr	Sdb70
.rtn:	rts


Sf7e4:	lda	hdr_os3_pixels_sent+1
	ora	hdr_os3_pixels_sent
	beq	Lf812
	lda	hdr_os3_pixels_sent+1
	sec
	sbc	#$01
	sta	hdr_os3_pixels_sent+1
	lda	hdr_os3_pixels_sent
	sbc	#$00
	sta	hdr_os3_pixels_sent
	lda	hdr_os3_pixels_sent+1
	ora	hdr_os3_pixels_sent
	bne	Lf812
	lda	hdr_std_rev_num+1
	sta	Z6f
	lda	hdr_std_rev_num
	sta	Z6f+1
	jsr	Sfcea
Lf812:	rts


op_show_status:
	rts


op_verify:
	jsr	new_line
	ldx	#$03
	lda	#$00
	sta	Zdc
.loop1:	sta	Z71,x
	sta	aux_ptr,x
	dex
	bpl	.loop1
	lda	#$40
	sta	aux_ptr
	lda	hdr_length
	sta	Z6d+1
	lda	hdr_length+1
	asl
	rol	Z6d+1
	rol	Z71
	asl
	sta	Z6d
	rol	Z6d+1
	rol	Z71
	lda	#$00
	sta	disk_block_num
	sta	disk_block_num+1

	jmp	.fwd1
.loop2:	lda	aux_ptr
	bne	.fwd2
.fwd1:	lda	#$0a
	sta	Zb8
	lda	#$00
	sta	Df090
	jsr	Sd51d
	lda	Zdc
	bne	.fwd2
	lda	Zec
	cmp	#$02
	bne	.fwd2
	prt_msg_alt	be_patient
	inc	Zdc
.fwd2:	ldy	aux_ptr
	lda	rwts_data_buf,y
	inc	aux_ptr
	bne	.fwd3
	inc	aux_ptr+1
	bne	.fwd3
	inc	aux_ptr+2
.fwd3:	clc
	adc	Z73
	sta	Z73
	bcc	.fwd4
	inc	Z73+1
.fwd4:	lda	aux_ptr
	cmp	Z6d
	bne	.loop2
	lda	aux_ptr+1
	cmp	Z6d+1
	bne	.loop2
	lda	aux_ptr+2
	cmp	Z71
	bne	.loop2
	lda	hdr_checksum+1
	cmp	Z73
	bne	.rtn_f
	lda	hdr_checksum
	cmp	Z73+1
	bne	.rtn_f
	jmp	predicate_true

.rtn_f:	jmp	predicate_false


msg_be_patient:
	fcb	char_cr
	text_str	"Please be patient, this takes a while"
	fcb	char_cr
msg_len_be_patient	equ	*-msg_be_patient


; Note that buffer mode only applies to the lower window,
; and buffering never happens for the upper window.
; (In Z-Machine v6, every window has its own buffer mode
; flag.)
op_buffer_mode:
	ldx	arg1
	bne	.fwd1
	jsr	Sf8e1
	ldx	#$01
	stx	Zc2
	rts

.fwd1:	dex
	bne	.rtn
	stx	Zc2
.rtn:	rts


Sf8e1:	jsr	Sf7ca
	ldx	#$00
	stx	Zd6
	rts


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
	beq	osteram_deselect_3
	inx
	beq	ostream_deselect_4
	rts


; output stream 1 is the screen
ostream_select_1:
	inx
	stx	ostream_1_state
	rts

ostream_deselect_1:
	if	iver<=iver_e
	jsr	Sf8e1
	endif

	stx	ostream_1_state
	rts


; output stream 2 is the transcript (printer)
ostream_select_2:
	inx
	stx	ostream_2_state
	lda	hdr_flags2+1
	ora	#$01
	sta	hdr_flags2+1
	lda	Ddba9
	bne	.rtn
	jsr	Sdbac
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
	adc	first_ram_page
	ldx	arg2
	stx	Zbc
	sta	Zbd
	lda	#$02
	sta	Zbe
	lda	#$00
	sta	Zbf
	rts

osteram_deselect_3:
	lda	ostream_3_state
	beq	.fwd2
	stx	ostream_3_state
	lda	Zbe
	clc
	adc	Zbc
	sta	Z6d
	lda	Zbf
	adc	Zbd
	sta	Z6d+1
	lda	#$00
	tay
	sta	(Z6d),y
	ldy	#$01
	lda	Zbe
	sec
	sbc	#$02
	sta	(Zbc),y
	bcs	.fwd1
	dec	Zbf
.fwd1:	lda	Zbf
	dey
	sta	(Zbc),y
	lda	#$00
	sta	Zbb
.fwd2:	rts


; output stream 4, if it existed, would be a script file of user input
ostream_select_4:
ostream_deselect_4:
	rts


op_set_cursor:
	jsr	Sf8e1
	ldx	arg1
	dex
	stx	cursrv
	ldx	arg2
	dex
	stx	D057b
	jmp	S08a9


op_get_cursor:
	lda	arg1
	sta	Z6d
	lda	arg1+1
	clc
	adc	first_ram_page
	sta	Z6d+1
	ldy	cursrv
	ldx	D057b
	inx
	iny
	tya
	ldy	#$01
	sta	(Z6d),y
	dey
	tya
	sta	(Z6d),y
	iny
	iny
	sta	(Z6d),y
	iny
	txa
	sta	(Z6d),y
	rts


op_input_stream:
	rts


op_set_text_style:
	if	iver>=iver_e
	jsr	Sf8e1
	endif

	lda	arg1
	bne	.fwd1
	lda	#$ff
	sta	invflg
.rtn:	rts

.fwd1:	cmp	#$01
	bne	.rtn
	lda	#$3f
	sta	invflg
	rts


op_erase_line:
	lda	arg1
	cmp	#$01
	bne	Lf9cb
	jsr	Sf8e1
	jmp	S08c5

Lf9cb:	rts


op_erase_window:
	jsr	Sf8e1
	fcb	$8d		; sta absolute
	fdb	Z6d
	lda	D057b
	fcb	$8d		; sta absolute
	fdb	Z6d+1
	lda	cursrv
	fcb	$8d		; sta absolute
	fdb	Z73
	lda	arg1
	beq	.fwd1
	cmp	#$01
	beq	.fwd2
	cmp	#$ff
	bne	Lf9cb
	jsr	Sdc51
	jmp	Sdccf

.fwd1:	lda	wndtop
	sta	Zda
	jsr	Sdccf
	ldx	#$00
	jmp	.fwd3

.fwd2:	lda	wndtop
	pha
	ldx	#$00
	stx	wndtop
	sta	wndbot
	jsr	Sdccf
	lda	#$18
	sta	wndbot
	pla
	sta	wndtop
	ldx	#$01
.fwd3:	lda	#$00
	sta	Dfdea,x
	sta	Dfde6,x
	sta	Dfde8,x
	cpx	Zc7
	beq	.rtn

	fcb	$ad		; lda absolute
	fdb	Z6d
	fcb	$ad		; lda absolute
	fdb	Z6d+1
	sta	D057b
	fcb	$ad		; lda absolute
	fdb	Z73
	sta	cursrv
	jmp	S08a9

.rtn:	rts


op_print_table:
	if	iver>=iver_f
	lda	Zc7
	beq	.fwd0
	endif

	jsr	Sf8e1
.fwd0:	lda	arg1
	sta	aux_ptr
	lda	arg1+1
	sta	aux_ptr+1
	lda	#$00
	sta	aux_ptr+2
	jsr	find_aux_page
	lda	arg2
	cmp	#$00
	beq	.rtn
	sta	Z6f+1
	sta	Z6f
	dec	argcnt
	lda	argcnt
	cmp	#$01
	beq	.fwd1
	lda	arg3
.fwd1:	sta	Z71
	lda	cursrh
	sta	Z6d
	lda	D057b
	sta	Z6d+1
	lda	cursrv
	sta	Z73
.loop1:	jsr	fetch_aux_byte

	if	iver<=iver_e
	jsr	Sf6d6
	else
	jsr	Sf69a
	endif

	dec	Z6f
	bne	.loop1
	dec	Z71
	beq	.rtn

	if	iver<=iver_e
	lda	Z6d
	endif

	lda	Z6d+1
	sta	D057b
	ldx	Z73
	inx
	stx	Z73
	stx	cursrv
	jsr	S08a9
	lda	Z6f+1
	sta	Z6f
	jmp	.loop1

.rtn:	rts


op_set_font:
	lda	arg1
	ldx	Zc7
	cmp	Dfdf2,x
	beq	.fwd1
	jsr	Sf8e1
	lda	arg1
	jsr	Sfab4
	bcs	.fwd2
.fwd1:	ldx	Zc7
	lda	Dfdf2,x
	pha
	lda	arg1
	sta	Dfdf2,x
	pla
	ldx	#$00
	jmp	store_result

.fwd2:	jmp	store_result_zero


Sfab4:	ldx	romid2_save
	bne	.fwd3
	cmp	#$01
	beq	.fwd1
	cmp	#$03
	bne	.fwd3
	lda	#$3f
	sta	invflg
	lda	#$1b
	jsr	S08ef
	jmp	.fwd2

.fwd1:	lda	#$18
	jsr	S08ef
	lda	#$ff
	sta	invflg
.fwd2:	clc
	rts

.fwd3:	sec
	rts


Sfada:	jsr	Sf8e1
	lda	#$00
	sta	Z6d+1
	sta	Z6d
	sta	Z6f+1
	sta	Z6f
	sta	Dfdf0
	ldy	wndtop
	sty	Zda

	if	iver==iver_a
	inc	Zda
	endif

	tay
	lda	(Zc8),y
	cmp	#$4f
	bcc	.fwd1
	lda	#$4e
.fwd1:	sta	Zc3
	iny
	lda	(Zc8),y
	tax
	inx
	inx
	stx	Dfde3
	jsr	Sfbbe
.loop1:	lda	Z6d+1
	beq	.fwd2
	jsr	Sfc54
	bcc	.fwd3
	jmp	.rtn

.fwd2:	jsr	Sfd3f
.fwd3:	jsr	Sfc68
	bcs	.fwd4
	sta	Dfdf0
	cmp	#$0d
	beq	.fwd10
	jmp	.fwd11

.fwd4:
	if	iver>=iver_c
	tay
	bmi	.fwd9
	endif

	cmp	#$0d
	beq	.fwd10
	cmp	#$7f
	beq	.fwd8
	ldy	Dfde3
	cpy	Zc3
	bcs	.fwd9
	cmp	#$80
	bcs	.fwd7
	sta	Dfde4
	cmp	#$80
	bcs	.fwd6
	ldx	invflg
	bpl	.fwd5
	ora	#$80
.fwd5:	jsr	Sdb39
.fwd6:	lda	Dfde4
	cmp	#$41
	bcc	.fwd7
	cmp	#$5b
	bcs	.fwd7
	adc	#$20
.fwd7:	sta	(Zc8),y
	inc	Dfde3
	jmp	.loop1

.fwd8:	lda	Dfde3
	cmp	#$02
	beq	.fwd9
	dec	Dfde3
	lda	#$08
	jsr	Sdb39
	lda	#$a0
	jsr	Sdb39
	lda	#$08
	jsr	Sdb39
	jmp	.loop1

.fwd9:	jsr	Sdcfb
	jmp	.loop1

.fwd10:	sta	Dfdf0
	lda	#$8d
	jsr	Sdb39

	if	iver>=iver_c
	inc	Zda
	endif

	lda	Zd9
	beq	.fwd11
	lda	hdr_flags2+1
	and	#$01
	beq	.fwd11
	ldy	Dfde3
	lda	#$0d
	sta	(Zc8),y
	ldx	Dfde3
	dex
	stx	Za1
	dex
.loop2:	lda	(Zc8),y
	sta	D0200,x
	dey
	dex
	bpl	.loop2
	jsr	Sfc8e
	jsr	Sdb70
.fwd11:	ldy	Dfde3
	lda	#$00
	sta	(Zc8),y
	dey
	dey
	tya
	ldy	#$01
	sta	(Zc8),y
.rtn:	rts


Sfbbe:	lda	argcnt
	cmp	#$02
	beq	.ret
	lda	arg3
	sta	Z6d+1
	lda	argcnt
	cmp	#$04
	bne	.ret
	lda	arg4
	sta	Z6f
	lda	arg4+1
	sta	Z6f+1
.ret:	rts


Sfbd7:	bit	kbd_strb
.loop1:	jsr	Sfc33
	lda	Z6d
	bne	.loop2
	lda	Z6d+1
	sta	Z6d
.loop2:	ldx	#$08
.loop3:	lda	#$30
	jsr	S0927
	dex
	bne	.loop3
	bit	kbd
	bmi	.rtn_cc
	dec	Z6d
	beq	.fwd1
	bne	.loop2
.fwd1:	jsr	Sfc47
	lda	Z6f+1
	beq	.rtn_cs
	jsr	Sfcea
	lda	acc
	bne	.rtn_cs
	lda	Zda
	cmp	wndtop
	beq	.loop1
	jsr	Sfc18
	jmp	.loop1

.rtn_cs:
	sec
	rts

.rtn_cc:
	clc
	rts


Sfc18:	ldy	#$01
.loop1:	iny
	cpy	Dfde3
	beq	.fwd1
	lda	(Zc8),y
	cmp	#$80
	bcs	.loop1
	ora	#$80
	jsr	Sdb39
	jmp	.loop1

.fwd1:	lda	wndtop
	sta	Zda
	rts


Sfc33:	ldx	invflg
	txa
	eor	#$c0
	sta	invflg
	lda	#$a0
	jsr	Sdb39
	lda	#$08
	jsr	Sdb39
	stx	invflg
	rts


Sfc47:	pha
	lda	#$a0
	jsr	Sdb39
	lda	#$08
	jsr	Sdb39
	pla
	rts


Sfc54:	jsr	Sfbd7
	bcc	.fwd1		; this instruction is redundant
	bcs	.rtn_cs		; always taken, could be just a branch to an rts

.fwd1:	jsr	Sfd35
	beq	Sfc54
	jsr	Sfc47
	clc
	bcc	.rtn		; always taken - this could just be an rts

.rtn_cs:
	sec
.rtn:	rts


Sfc68:	pha
	lda	Z8c
	ora	Z8b
	beq	.fwd2
	pla
	ldx	Zb4
	beq	.fwd1
	cmp	#$80
	bcs	.rtn_cc
	bcc	.rtn_cs
.fwd1:	ldy	#$00
.loop1:	cmp	(Z8b),y
	beq	.rtn_cc
	pha
	lda	(Z8b),y
	beq	.fwd2
	pla
	iny
	bne	.loop1
.fwd2:	pla
.rtn_cs:
	sec
	rts

.rtn_cc:
	clc
	rts


Sfc8e:	ldy	#$00
	ldx	#$00
.loop1:	lda	D0200,y
	cmp	#$80
	bcs	.fwd2
	cmp	#$00
	bne	.fwd1
	lda	#$8d
.fwd1:	sta	D0200,x
	inx
.fwd2:	iny
	cpy	Za1
	bne	.loop1
	stx	Ze3
	rts


op_read_char:
	lda	arg1
	cmp	#$01
	bne	.fwd4
	jsr	Sf8e1
	lda	wndtop
	sta	Zda

	if	iver>=iver_c
	inc	Zda
	endif

	lda	#$00
	sta	Zd6
	sta	Z6d+1
	sta	Z6d
	sta	Z6f+1
	sta	Z6f
	dec	argcnt
	beq	.fwd2
	lda	arg2
	sta	Z6d+1
	dec	argcnt
	beq	.fwd1
	lda	arg3
	sta	Z6f
	lda	arg3+1
	sta	Z6f+1
.fwd1:	jsr	Sfc54
	bcs	.fwd4
	bcc	.fwd3
.fwd2:	jsr	Sfd3f
.fwd3:	ldx	#$00
	jmp	store_result_xa

.fwd4:	jmp	store_result_zero


Sfcea:	lda	Z6d+1
	pha
	lda	Z6d
	pha
	lda	Z6f+1
	sta	arg1+1
	pha
	lda	Z6f
	sta	arg1
	pha
	ldx	#$01
	stx	argcnt
	dex
	stx	call_store_result_flag
	lda	pc
	pha
	lda	pc+1
	pha
	lda	pc+2
	pha
	lda	#$00
	sta	pc+2
	sta	pc+1
	sta	pc
	jsr	do_call
	jmp	main_loop


Lfd19:	pla
	pla
	pla
	sta	pc+2
	pla
	sta	pc+1
	pla
	sta	pc
	jsr	find_pc_page
	pla
	sta	Z6f
	pla
	sta	Z6f+1
	pla
	sta	Z6d
	pla
	sta	Z6d+1
	rts


Dfd34:	fcb	$00


Sfd35:	pha
	lda	#$01
	sta	Dfd34
	pla
	jmp	Lfd46

Sfd3f:	pha
	lda	#$00
	sta	Dfd34
	pla

Lfd46:	cld
	txa
	pha
	tya
	pha
.loop1:	jsr	S090b
	lda	kbd
	and	#$7f
	cmp	#char_cr
	bne	.fwd1
	jmp	.fwd7

.fwd1:	cmp	#char_del
	bne	.fwd2
	jmp	.fwd7

.fwd2:	ldx	#$0a
.loop2:	cmp	Dfdcd,x
	beq	.fwd3
	dex
	bpl	.loop2
	bmi	.fwd4		; always taken
.fwd3:	lda	Dfdd8,x
	jmp	.fwd9

.fwd4:	cmp	#$20
	bcc	.fwd5
	cmp	#$3c
	bcc	.fwd7
	cmp	#$7c
	beq	.fwd7
	cmp	#$3f
	beq	.fwd7
	cmp	#$7b
	bcs	.fwd5
	cmp	#$61
	bcs	.fwd7
	cmp	#$41
	bcc	.fwd5
	cmp	#$5b
	bcc	.fwd7
.fwd5:	jsr	Sdcfb
	lda	Dfd34
	bne	.fwd6
	jmp	.loop1

.fwd6:	lda	#$00
.fwd7:	cmp	#$30
	bcc	.fwd9
	cmp	#$3a
	bcs	.fwd9
	ldx	Dc061
	bmi	.fwd8
	ldx	Dc062
	bpl	.fwd9
.fwd8:	clc
	adc	#$54
	cmp	#$84
	bne	.fwd9
	clc
	adc	#$0a
.fwd9:	sta	Zdc
	adc	rndloc
	sta	rndloc
	eor	rndloc+1
	sta	rndloc+1
	pla
	tay
	pla
	tax
	lda	Zdc
	rts


Dfdcd:	fcb	$0b,$0a,$08,$15,$3c,$5f,$3e,$40	; "....<_>@"
	fcb	$25,$5e,$26               	; "%^&"

Dfdd8:	fcb	$81,$82,$83,$84,$2c,$2d,$2e,$32	; "....,-.2"
	fcb	$35,$36,$37               	; "567"


Dfde3:	fcb	$00
Dfde4:	fcb	$00
call_store_result_flag:	fcb	$00
Dfde6:	fcb	$00
Dfde7:	fcb	$00
Dfde8:	fcb	$00
Dfde9:	fcb	$00
Dfdea:	fcb	$00
Dfdeb:	fcb	$00,$00
Dfded:	fcb	$00

	if	iver>=iver_e
Zd0:	fdb	$0000
	endif

Dfdee:	fcb	$00
Dfdef:	fcb	$00
Dfdf0:	fcb	$00
Dfdf1:	fcb	$00

Dfdf2:	fcb	$01,$01


msg_more:	text_str	"[MORE]"
msg_len_more	equ	*-msg_more


msg_printer_slot:
	fcb	char_cr
	text_str	"Printer Slot 1-7: "
msg_len_printer_slot	equ	 *-msg_printer_slot


msg_story_loading:
	text_str	"The story is loading ..."
msg_len_story_loading	equ	*-msg_story_loading


	align	$0100,$00
