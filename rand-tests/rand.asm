	.cpu	mera400

	.include cpu.inc
	.include io.inc

	uj	start

imask:	.word	IMASK_CH10_15
izero:	.word	IMASK_NONE

dummy:	hlt	045	; halt on interrupts that shouldn't happen
	ujs	dummy

stack:	.res	11*4, 0x0ded

	.org	STACKP
	.word	stack
	.org	OS_START

	.include kz.asm
	.include stdio.asm
	.include prng.inc

; ------------------------------------------------------------------------
	.const	CH 15
	.const	TERM CH\IO_CHAN | 0\IO_DEV

rand:	.res	2
str_buf:.res	16
; ------------------------------------------------------------------------
; ---- MAIN --------------------------------------------------------------
; ------------------------------------------------------------------------
start:
	lj	tmrandom
	rw	r1, rand

	lw	r1, CH
	lj	kz_init
	im	imask

        ; print result
        lw      r1, [rand]
        lw      r2, str_buf
        lj      unsigned2asc
        lw      r1, str_buf
        lw      r2, TERM
        lj      puts

        lw      r1, '\r\n'
        lw      r2, TERM
        lj      put2c

	uj	start

