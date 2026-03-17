	.cpu	mera400

	.include cpu.inc
	.include io.inc

	uj	start

imask:	.word	IMASK_ALL & ~IMASK_CPU_H
imask0:	.word	IMASK_NONE

dummy:	hlt	045
	ujs	dummy

stack:	.res	11*4, 0x0ded

	.org	INTV
	.res	32, dummy
	.org	EXLV
	.word	dummy
	.org	STACKP
	.word	stack
	.org	OS_START

	.include kz.asm
	.include stdio.asm

; ------------------------------------------------------------------------

	.const	CH 15
	.const	TERM	CH\IO_CHAN | 3\IO_DEV
uzdat_list:
	.word	TERM, -1

; ------------------------------------------------------------------------
choinka:
	.res	1
	lw	r7, .banner<<1
.loop:
	lw	r1, 10000
.waste:
	drb	r1, .waste
	lw	r2, TERM
	lb	r1, r7
	zlb	r1
	cwt	r1, 0
	jes	.fin
	lj	putc
	awt	r7, 1
	ib	.col
	ujs	.loop

	lw	r2, TERM
	lw	r1, '\n\r'
	lj	put2c
	lw	r1, -80
	rw	r1, .col
	ujs	.loop
.fin:
	uj	[choinka]
.banner:
	.ascii "SUBSKRYBUJ MERA-400  "
	.word 0
.col:	.word -80

; ------------------------------------------------------------------------
clrscr:
	.res	1

	lw	r2, TERM
	lw	r1, 0x1b48
	lj	put2c
	lw	r2, TERM
	lw	r1, 0x1b4a
	lj	put2c

	uj	[clrscr]

; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------

start:

	; initialize KZ

	lw	r1, CH
	lw	r2, uzdat_list
	lj	kz_init

	im	imask

	lj	clrscr
rep:
	lj	choinka
	ujs	rep
	hlt

