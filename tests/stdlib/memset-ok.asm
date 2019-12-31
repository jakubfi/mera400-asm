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
	lw	r2, 6
	lw	r3, 999
	lj	memset
halt:
	hlt	044
	ujs	halt

; XPCT [9]  : -1
; XPCT [10] : 999
; XPCT [11] : 999
; XPCT [12] : 999
; XPCT [13] : 999
; XPCT [14] : 999
; XPCT [15] : 999
; XPCT [16] : -2
