; Some useful macros

blt	macro	dest
	bcc	dest
	endm

bge	macro	dest
	bcs	dest
	endm

dasl	macro	adr1,adr2
	ifnb	adr2
	lda	adr1
	asl	a
	sta	adr2
	lda	adr1+1
	rol	a
	sta	adr2+1
	else
	asl	adr1
	rol	adr1+1
	endif
	endm

dlsr	macro	adr1,adr2
	ifnb	adr2
	lda	adr1+1
	lsr	a
	sta	adr2+1
	lda	adr1
	ror	a
	sta	adr2
	else
	lsr	adr1+1
	ror	adr1
	endif
	endm

dror	macro	adr1,adr2
	ifnb	adr2
	lda	adr1+1
	ror	a
	sta	adr2+1
	lda	adr1
	ror	a
	sta	adr2
	else
	ror	adr1+1
	ror	adr1
	endif
	endm

drol	macro	adr1,adr2
	ifnb	adr2
	lda	adr1
	rol	a
	sta	adr2
	lda	adr1+1
	rol	a
	sta	adr2+1
	else
	rol	adr1
	rol	adr1+1
	endif
	endm

dor	macro	adr1,adr2,adr3
	lda	adr1+1
	ora	adr2+1
	sta	adr3+1
	lda	adr1
	ora	adr2
	sta	adr3
	endm

dand	macro	adr1,adr2,adr3
	lda	adr1+1
	and	adr2+1
	sta	adr3+1
	lda	adr1
	and	adr2
	sta	adr3
	endm

d1comp	macro	adr1,adr2
	lda	adr1
	eor	#$ff
	sta	adr2
	lda	adr1+1
	eor	#$ff
	sta	adr2+1
	endm

dadc	macro	adr1,adr2,adr3
	lda	adr1
	adc	adr2
	sta	adr3
	lda	adr1+1
	adc	adr2+1
	sta	adr3+1
	endm

dsbc	macro	adr1,adr2,adr3
	lda	adr1
	sbc	adr2
	sta	adr3
	lda	adr1+1
	sbc	adr2+1
	sta	adr3+1
	endm

dadd	macro	adr1,adr2,adr3
	clc
	dadc	adr1,adr2,adr3
	endm

dsub	macro	adr1,adr2,adr3
	sec
	dsbc	adr1,adr2,adr3
	endm

add	macro	adr1,adr2,adr3
	ifnb	adr1
	lda	adr1
	endif
	clc
	adc	adr2
	ifnb	adr3
	sta	adr3
	endif
	endm

sub	macro	adr1,adr2,adr3
	ifnb	adr1
	lda	adr1
	endif
	sec
	sbc	adr2
	ifnb	adr3
	sta	adr3
	endif
	endm

daddb1	macro	addr,byte
	clc
	lda	addr
	adc	byte
	sta	addr
	bcc	label
	inc	addr+1
label:
	endm

dsubb1	macro	addr,byte
	sec
	lda	addr
	sbc	byte
	sta	addr
	bcs	label
	dec	addr+1
label:
	endm

daddb2	macro	addr,byte
	ifnb	byte
	add	addr,byte,addr
	else
	add	,addr,addr
	endif
	bcc	label
	inc	addr+1
label:
	endm

dsubb2	macro	addr,byte
	ifnb	byte
	sub	addr,byte,addr
	else
	sub	,addr,addr
	endif
	bcs	label
	dec	addr+1
label:
	endm

dinc	macro	addr
	inc	addr
	bne	label
	inc	addr+1
label:
	endm

ddec	macro	addr
	dsubb2	addr,#$01,addr
	endm

ddec2	macro	addr
	dsubb2	addr,#$02,addr
	endm

dmov	macro	adr1,adr2
	lda	adr1
	sta	adr2
	lda	adr1+1
	sta	adr2+1
	endm

dmovi	macro	data,adr2
	lda	#((data)&$ff)
	sta	adr2
	lda	#((data)>>8)
	sta	adr2+1
	endm

dmovi2	macro	data,adr2
	lda	#((data)>>8)
	sta	adr2+1
	lda	#((data)&$ff)
	sta	adr2
	endm

pul	macro	adr
	irp	dest,ALLARGS
	pla
	sta	dest
	endm
	endm

psh	macro	adr
	irp	src,ALLARGS
	lda	src
	pha
	endm
	endm

dpul	macro	adr
	pul	adr+1
	pul	adr
	endm

dpul2	macro	adr
	pul	adr
	pul	adr+1
	endm

dpsh	macro	adr
	psh	adr
	psh	adr+1
	endm

mov	macro	adr1
	ifnb	adr1
	lda	adr1
	endif
	shift
	irp	dest,ALLARGS
	sta	dest
	endm
	endm

inca	macro
	add	,#$01
	endm

deca	macro
	sub	,#$01
	endm

tsta	macro
	ora	#$00
	endm

str	macro	text
	db	text
	endm

jeq	macro	adr
	bne	label
	jmp	adr
label:
	endm

jne	macro	adr
	beq	label
	jmp	adr
label:
	endm

jcc	macro	adr
	bcs	label
	jmp	adr
label:
	endm

jcs	macro	adr
	bcc	label
	jmp	adr
label:
	endm

jlt	macro	adr
	bge	label
	jmp	adr
label:
	endm

jge	macro	adr
	blt	label
	jmp	adr
label:
	endm

jgt	macro	adr
	blt	label
	bcc	label
	jmp	adr
label:
	endm

jpl	macro	adr
	bmi	label
	jmp	adr
label:
	endm

jmi	macro	adr
	bpl	label
	jmp	adr
label:
	endm

jsreq	macro	adr,adr2
	bne	label
	jsr	adr
	ifnb	adr2
	jmp	adr2
	endif
label:
	endm

jsrne	macro	adr,adr2
	beq	label
	jsr	adr
	ifnb	adr2
	jmp	adr2
	endif
label:
	endm

jsrcc	macro	adr,adr2
	bcs	label
	jsr	adr
	ifnb	adr2
	jmp	adr2
	endif
label:
	endm

jsrcs	macro	adr,adr2
	bcc	label
	jsr	adr
	ifnb	adr2
	jmp	adr2
	endif
label:
	endm

jsrlt	macro	adr,adr2
	bge	label
	jsr	adr
	ifnb	adr2
	jmp	adr2
	endif
label:
	endm

jsrge	macro	adr,adr2
	blt	label
	jsr	adr
	ifnb	adr2
	jmp	adr2
	endif
label:
	endm

jsrgt	macro	adr,adr2
	blt	label
	beq	label
	jsr	adr
	ifnb	adr2
	jmp	adr2
	endif
label:
	endm

jsrpl	macro	adr,adr2
	bmi	label
	jsr	adr
	ifnb	adr2
	jmp	adr2
	endif
label:
	endm

jsrmi	macro	adr,adr2
	bpl	label
	jsr	adr
	ifnb	adr2
	jmp	adr2
	endif
label:
	endm

rtseq	macro	adr
	bne	label
	rts
label:
	endm

rtsne	macro	adr
	beq	label
	rts
label:
	endm

rtscc	macro	adr
	bcs	label
	rts
label:
	endm

rtscs	macro	adr
	bcc	label
	rts
label:
	endm

rtslt	macro	adr
	bge	label
	rts
label:
	endm

rtsge	macro	adr
	blt	label
	rts
label:
	endm

rtsgt	macro	adr
	blt	label
	beq	label
	rts
label:
	endm

rtspl	macro	adr
	bmi	label
	rts
label:
	endm

rtsmi	macro	adr
	bpl	label
	rts
label:
	endm


rtop:	macro
	if	iver<iver3
	jmp	mnloop
	else
	rts
	endif
	endm


rtopeq:	macro
	bne	label
	rtop
label:
	endm


dtst	macro	addr
	lda	addr+1
	ora	addr
	endm

dtstbe	macro	adr1,adr2
	dtst	adr1
	beq	adr2
	endm

dtstbn	macro	adr1,adr2
	dtst	adr1
	bne	adr2
	endm

dtstje	macro	adr1,adr2
	dtst	adr1
	jeq	adr2
	endm

dtstjn	macro	adr1,adr2
	dtst	adr1
	jne	adr2
	endm

dtstre	macro	adr1
	dtst	adr1
	rtseq
	endm

dtstrn	macro	adr1
	dtst	adr1
	rtsne
	endm

dtst2	macro	addr
	lda	addr
	ora	addr+1
	endm

dts2be	macro	adr1,adr2
	dtst2	adr1
	beq	adr2
	endm

dts2bn	macro	adr1,adr2
	dtst2	adr1
	bne	adr2
	endm

dts2je	macro	adr1,adr2
	dtst2	adr1
	jeq	adr2
	endm

dts2jn	macro	adr1,adr2
	dtst2	adr1
	jne	adr2
	endm

dts2re	macro	adr1,adr2
	dtst2	adr1
	rtseq	adr2
	endm

dts2rn	macro	adr1,adr2
	dtst2	adr1
	rtsne	adr2
	endm

dxbne	macro	adr
	dex
	bne	adr
	endm

dybne	macro	adr
	dey
	bne	adr
	endm

dxbeq	macro	adr
	dex
	beq	adr
	endm

dybeq	macro	adr
	dey
	beq	adr
	endm

dxbpl	macro	adr
	dex
	bpl	adr
	endm

dybpl	macro	adr
	dey
	bpl	adr
	endm

dxbmi	macro	adr
	dex
	bmi	adr
	endm

dybmi	macro	adr
	dey
	bmi	adr
	endm

ixbne	macro	adr
	inx
	bne	adr
	endm

iybne	macro	adr
	iny
	bne	adr
	endm

decbe	macro	adr1,adr2
	dec	adr1
	beq	adr2
	endm

decbn	macro	adr1,adr2
	dec	adr1
	bne	adr2
	endm

decje	macro	adr1,adr2
	dec	adr1
	jeq	adr2
	endm

decjn	macro	adr1,adr2
	dec	adr1
	jne	adr2
	endm

decabe	macro	adr1
	deca
	beq	adr1
	endm

decabn	macro	adr1
	deca
	bne	adr1
	endm

decabp	macro	adr1
	deca
	bpl	adr1
	endm

decabm	macro	adr1
	deca
	bmi	adr1
	endm

tstabe	macro	adr1
	tsta
	beq	adr1
	endm

tstabn	macro	adr1
	tsta
	bne	adr1
	endm

tstabp	macro	adr1
	tsta
	bpl	adr1
	endm

tstabm	macro	adr1
	tsta
	bmi	adr1
	endm

tstaje	macro	adr1
	tsta
	jeq	adr1
	endm

tstarp	macro
	tsta
	rtspl
	endm

cmpbe	macro	adr1,adr2
	cmp	adr1
	beq	adr2
	endm

cmpbn	macro	adr1,adr2
	cmp	adr1
	bne	adr2
	endm

cmpbl	macro	adr1,adr2
	cmp	adr1
	blt	adr2
	endm

cmpbg	macro	adr1,adr2
	cmp	adr1
	bge	adr2
	endm

cmpbm	macro	adr1,adr2
	cmp	adr1
	bmi	adr2
	endm

cmpbp	macro	adr1,adr2
	cmp	adr1
	bpl	adr2
	endm

cmpje	macro	adr1,adr2
	cmp	adr1
	jeq	adr2
	endm

cmpjl	macro	adr1,adr2
	cmp	adr1
	jlt	adr2
	endm

cmpjse	macro	adr1,adr2,adr3
	cmp	adr1
	jsreq	adr2,adr3
	endm

cmpjsn	macro	adr1,adr2
	cmp	adr1
	jsrne	adr2
	endm

cmpjsg	macro	adr1,adr2
	cmp	adr1
	jsrge	adr2
	endm

cmpre	macro	adr1
	cmp	adr1
	rtseq
	endm

cmprn	macro	adr1
	cmp	adr1
	rtsne
	endm

cpxbe	macro	adr1,adr2
	cpx	adr1
	beq	adr2
	endm

cpxbg	macro	adr1,adr2
	cpx	adr1
	bge	adr2
	endm

cpxrgt	macro	adr1
	cpx	adr1
	rtsgt
	endm

cpybn	macro	adr1,adr2
	cpy	adr1
	bne	adr2
	endm

fillto	macro	addr, val
	while	* < addr
size	set	addr-*
	if	size > 256
size	set	256
	endif
	fcb	[size] val
	endm
	endm
