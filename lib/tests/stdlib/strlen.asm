	.include cpu.inc
	.include io.inc

	uj	start

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

	lw	r1, [r7]
	lw	r5, [r1]
	awt	r1, 1
	lj	strlen
	cw	r1, r5
	jn	.err
	awt	r7, 1
	ujs	.loop

.err:	hlt	044
	ujs	.err
.done:	hlt	077
	ujs	.done

tests:	.word	t1, t2, t3, t4, t5, t6, t7, -1
t2:	.word	0	.ascii "\0"
t1:	.word	1	.ascii "a\0"
t3:	.word	2	.ascii "aa\0"
t4:	.word	3	.ascii "aab\0"
t5:	.word	4	.ascii "aabc\0"
t6:	.word	3	.ascii "aab\0\0"
t7:	.word	0	.ascii "\0aab\0"

; XPCT ir : 0xec3f
