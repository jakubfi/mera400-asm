	.include cpu.inc
	.include io.inc

	uj	start

	.org	9
data:	.word	-1, 1, 2, 3, 4, 5, 6, -2

imask:	.res 0

	.org	OS_START
	.include kz.asm
	.include stdio.asm

start:
	lw	r1, data+1
	lw	r2, 0
	lw	r3, 9
	lj	memset
halt:
	hlt	044
	ujs	halt

; XPCT [9]  : -1
; XPCT [10] : 1
; XPCT [11] : 2
; XPCT [12] : 3
; XPCT [13] : 4
; XPCT [14] : 5
; XPCT [15] : 6
; XPCT [16] : -2
