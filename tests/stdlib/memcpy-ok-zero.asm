	.include cpu.inc
	.include io.inc

	uj	start

	.org	9
	.word	-1, 1, 2, 3, 4, 5, 6, -2
	.org	19
	.word	-3, 0, 0, 0, 0, 0, 0, -4

imask:	.res 0

	.org	OS_START
	.include kz.asm
	.include stdio.asm

start:
	lw	r1, 20
	lw	r2, 10
	lw	r3, 0
	lj	memcpy
halt:
	hlt	044
	ujs	halt

; XPCT r1 : 0

; XPCT [9]  : -1
; XPCT [10] : 1
; XPCT [11] : 2
; XPCT [12] : 3
; XPCT [13] : 4
; XPCT [14] : 5
; XPCT [15] : 6
; XPCT [16] : -2

; XPCT [19] : -3
; XPCT [20] : 0
; XPCT [21] : 0
; XPCT [22] : 0
; XPCT [23] : 0
; XPCT [24] : 0
; XPCT [25] : 0
; XPCT [26] : -4
