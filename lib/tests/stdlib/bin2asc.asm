	.include cpu.inc
	.include io.inc

	uj	start

tests:	.word	t1, t2, t3, t4, t5, t6, t7, t8, -1
imask:	.res 0

	.org	OS_START
	.include kz.asm
	.include stdio.asm

start:
	lw	r7, tests
.loop:
	lw	r5, [r7]
	cwt	r5, -1
	jes	.done

	lw	r1, [r5]
	lw	r2, buf
	lj	bin2asc

	lw	r1, buf
	lw	r2, r5+2
	lw	r3, [r5+1]
	lj	memcmp

	cw	r1, 0
	jn	.err
	awt	r7, 1
	ujs	.loop

.err:	hlt	044
	ujs	.err
.done:	hlt	077
	ujs	.done

t1:	.word	0, 9		.ascii "0000000000000000\0\0"
t2:	.word	1, 9		.ascii "0000000000000001\0\0"
t3:	.word	2, 9		.ascii "0000000000000010\0\0"
t4:	.word	3, 9		.ascii "0000000000000011\0\0"
t5:	.word	4, 9		.ascii "0000000000000100\0\0"
t6:	.word	65535, 9	.ascii "1111111111111111\0\0"
t7:	.word	65534, 9	.ascii "1111111111111110\0\0"
t8:	.word	32767, 9	.ascii "0111111111111111\0\0"

buf:	.res	9, 0

; XPCT ir : 0xec3f
