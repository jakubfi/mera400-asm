	.include cpu.inc
	.include io.inc

	uj	start

data1:	.word	0, 1, 2, 3, 4, 5, 6, 0
data2:	.word	0, 9, 9, 9, 9, 9, 9, 0

imask:	.res 0

	.org	OS_START
	.include kz.asm
	.include stdio.asm

start:
	lw	r1, data1+1
	lw	r2, data2+1
	lw	r3, 0
	lj	memcmp
halt:
	hlt	044
	ujs	halt

; XPCT r1 : 0

