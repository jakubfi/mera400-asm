;
; Simple terminal echo (or double echo if h/w echo is turned on)
; Works with device 0 in character channel 15 (see CH and TERM constants)
;

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
	.const	TERM CH\IO_CHAN | 0\IO_DEV
str:	.asciiz "\r\nReady\r\n"

; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------

start:
	lw	r1, CH
	lj	kz_init

	im	imask

	lw	r1, str
	lw	r2, TERM
	lj	puts

.loop:
	; read key
	lw	r2, TERM
	lj	getc
	lw	r7, r1
	lw	r2, TERM
	lj	putc

	ujs	.loop

