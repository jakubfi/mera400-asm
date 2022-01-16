	.include cpu.inc
	.include io.inc

	uj	start

data:	.word	-1, 1, 2, 3, 4, 5, 6, -2

imask:	.res 0

	.org	OS_START
	.include crc.asm

start:
	lw	r1, data
	lw	r2, 0
	lj	crc16
halt:
	hlt	044
	ujs	halt

; XPCT r1 : 0x1d0f
