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
_charset:
	.res	1

	lwt	r6, 0

.dump:
	lw	r1, r6
	lw	r2, TERM
	lj	putc

	awt	r6, 1
	cw	r6, 128
	jes	.end

	; newline maybe?
	lw	r1, r6
	nr	r1, 0b11111
	cw	r1, 0
	jn	.dump
	lw	r2, TERM
	lw	r1, '\r\n'
	lj	put2c

	ujs	.dump
.end:
	lw	r2, TERM
	lw	r1, '\n\r'
	lj	put2c
	lw	r2, TERM
	lw	r1, '\n\r'
	lj	put2c
	uj	[_charset]

; ------------------------------------------------------------------------
charset:
	.res	1

	lw	r2, TERM
	lw	r1, .banner
	lj	puts

	lj	_charset
	uj	[charset]
.banner:
	.asciiz "----[ Basic character set ]-----------------------------------------------------------------------\n\r"

; ------------------------------------------------------------------------
charset_gfx:
	.res	1

	lw	r2, TERM
	lw	r1, .banner
	lj	puts

	lw	r2, TERM
	lw	r1, 0x1b46
	lj	put2c

	lj	_charset

	lw	r2, TERM
	lw	r1, 0x1b47
	lj	put2c

	uj	[charset_gfx]
.banner:
	.asciiz "----[ Graphics character set ]--------------------------------------------------------------------\n\r"

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
test_keys:
	.res	1

	lw	r2, TERM
	lw	r1, .banner
	lj	puts

.loop:
	; read key
	lw	r2, TERM
	lj	getc
	lw	r7, r1

	; 'Znak'
	lw	r1, .s_znak
	lw	r2, TERM
	lj	puts

	; hex representation
	lw	r1, r7
	lw	r2, .buf
	lj	hex2asc
	lw	r1, .buf
	lw	r2, TERM
	lj	puts

	; character, literal
	lw	r1, ' ('
	lw	r2, TERM
	lj	put2c
	lw	r1, r7
	lw	r2, TERM
	lj	putc
	lw	r1, ')'
	lw	r2, TERM
	lj	putc

	; newline
	lw	r1, '\r\n'
	lw	r2, TERM
	lj	put2c

	ujs	.loop


	uj	[test_keys]
.buf:	.res	20
.s_znak:.asciiz "\n\rChar: "
.banner:
	.asciiz "----[ Key press test ]----------------------------------------------------------------------------\n\r"

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
	lj	charset
	lj	charset_gfx
	lj	test_keys

