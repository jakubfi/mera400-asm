	.include cpu.inc
	.include io.inc

	uj	start

imask:	.res 0

	.org	OS_START
	.include kz.asm
	.include stdio.asm

start:
	lw	r7, tests
	lw	r6, 1 ; just a test position, so it's easier to see where we are when debuging
.loop:
	lw	r1, [r7+1]
	cw	r1, '**'
	jes	.done

	lw	r1, r7+1
	lj	atoi

	cw	r1, [r7]
	jn	.err
	awt	r7, 5
	awt	r6, 1
	ujs	.loop

.err:	hlt	044
	ujs	.err
.done:	hlt	077
	ujs	.done

tests:
	.word	0	.ascii	"0\0      "
	.word	1	.ascii	"1\0      "
	.word	10	.ascii	"10\0     "
	.word	100	.ascii	"100\0    "
	.word	1000	.ascii	"1000\0   "
	.word	10000	.ascii	"10000\0  "
	.word	-1	.ascii	"-1\0     "
	.word	-10	.ascii	"-10\0    "
	.word	-100	.ascii	"-100\0   "
	.word	-1000	.ascii	"-1000\0  "
	.word	-10000	.ascii	"-10000\0 "
	.word	9	.ascii	"9\0      "
	.word	99	.ascii	"99\0     "
	.word	999	.ascii	"999\0    "
	.word	9999	.ascii	"9999\0   "

	.word	32767	.ascii	"32767\0  "
	.word	32768	.ascii	"32768\0  "
	.word	32769	.ascii	"32769\0  "
	.word	65535	.ascii	"65535\0  "
	.word	0	.ascii	"65536\0  "
	.word	1	.ascii	"65537\0  "
	.word	-32767	.ascii	"-32767\0 "
	.word	-32768	.ascii	"-32768\0 "
	.word	32767	.ascii	"-32769\0 "

	.word	1	.ascii	"1 \0     "
	.word	0	.ascii	" 1\0     "
	.word	0	.ascii	"+1\0     "
	.word	1	.ascii	"1a\0     "
	.word	-1	.ascii	"-1a\0    "
	.word	10000	.ascii	"10000a\0 "
	.word	-10000	.ascii	"-10000a\0"
	.word	0	.ascii	"**       "

; XPCT ir : 0xec3f
