	.include cpu.inc
	.include io.inc

	uj	start

buf:	.res	9, 0
tests:	.word	t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, -1
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
	lj	unsigned2asc

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

t1:	.word	0, 1		.ascii "0\0"
t2:	.word	1, 1		.ascii "1\0"
t3:	.word	2, 1		.ascii "2\0"
t4:	.word	3, 1		.ascii "3\0"
t5:	.word	4, 1		.ascii "4\0"
t6:	.word	10, 2		.ascii "10\0\0"
t7:	.word	100, 2		.ascii "100\0"
t8:	.word	1000, 3		.ascii "1000\0\0"
t9:	.word	10000, 3	.ascii "10000\0"
t10:	.word	32767, 3	.ascii "32767\0"
t11:	.word	32768, 3	.ascii "32768\0"
t12:	.word	65534, 3	.ascii "65534\0"
t13:	.word	65535, 3	.ascii "65535\0"

; XPCT ir : 0xec3f
