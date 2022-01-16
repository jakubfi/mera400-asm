	.include cpu.inc
	.include io.inc

	uj	start

data:	.word	-1
	.ascii	"123456789"
	.word	-2

imask:	.res 0

	.org	OS_START
	.include crc.asm

start:
	lw	r1, data+1
	lw	r2, 9
	lj	crc16
halt:
	hlt	044
	ujs	halt

; XPCT r1 : 0xE5CC
