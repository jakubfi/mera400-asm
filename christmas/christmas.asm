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
	.const	TERM	CH\IO_CHAN | 0\IO_DEV
uzdat_list:
	.word	TERM, -1

; ------------------------------------------------------------------------
choinka:
	.res	1

	lw	r2, TERM
	lw	r1, .banner
	lj	puts

	uj	[choinka]
.banner:
	.include raw.inc
	.word 0

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
	lj	choinka
	hlt

