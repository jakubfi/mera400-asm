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
	.const	PC	CH\IO_CHAN | 0\IO_DEV
uzdat_list:
	.word	PC, TERM, -1

; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------

start:

	; initialize KZ

	lw	r1, CH
	lw	r2, uzdat_list
	lj	kz_init

	im	imask

	; ----------------------------------------------------------------

	lw	r2, TERM
	lw	r1, banner
	lj	puts

	lw	r1, 65535
	lw	r2, buf
	lj	unsigned2asc2

	lw	r2, TERM
	lw	r1, buf
	lj	puts

h:	hlt
	ujs	h

banner:.asciiz	"This is a test.\n\r"
buf:	.res	16
