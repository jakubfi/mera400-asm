
	.cpu	mera400

	.include cpu.inc
	.include io.inc

	uj	start

imask:	.word	IMASK_ALL & ~(IMASK_CPU_H | IMASK_GROUP_L)

dummy:	lip

stack:	.res	11*4, 0x0ded

	.org	INTV
	.res	32, dummy
	.org	EXLV
	.word	dummy
	.org	STACKP
	.word	stack
	.org	OS_START

	.include kz.asm
	.include stdio.asm
	.include prng.inc
	#include "stdio_macros.h"

; ------------------------------------------------------------------------

FLOP:	.word	0
uzdat_list:
	.word	-1

; ------------------------------------------------------------------------
; r5 - disk address
; r6 - bytes to test
; return: r1 - 0=ok
floptest:
	.res	1

	rw	r7, .regs
	lw	r7, r6
	srz	r7

	rndfill(wrbuf, r7)
	memset(rdbuf, r7, 0)

	; write data

	kz_wrseek(r5, [FLOP])
	cwt	r1, 0
	jn	.done
	write(wrbuf, [FLOP], r6)
	cwt	r1, 0
	jn	.done
	kz_detach([FLOP])
	cwt	r1, 0
	jn	.done

	; read data

	kz_seek(r5, [FLOP])
	cwt	r1, 0
	jn	.done
	read(rdbuf, [FLOP], r6)
	cwt	r1, 0
	jn	.done
	kz_detach([FLOP])
	cwt	r1, 0
	jn	.done

	memcmp(rdbuf, wrbuf, r7)
.done:
	lw	r7, [.regs]
	uj	[floptest]
.regs:	.res	1

; ------------------------------------------------------------------------
	.const	TEST_VEC_SIZE 2
testv:
	.word	7\KZ_FLOPPY_TRACK | 3\KZ_FLOPPY_SECTOR, 8
	.word	1\KZ_FLOPPY_TRACK | 26\KZ_FLOPPY_SECTOR, 128
	.word	50\KZ_FLOPPY_TRACK | 25\KZ_FLOPPY_SECTOR, 4*128
	.word	20\KZ_FLOPPY_TRACK | 12\KZ_FLOPPY_SECTOR, 128
	.word	73\KZ_FLOPPY_TRACK | 26\KZ_FLOPPY_SECTOR, 128
	.word	0

; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------

start:
	rky	r7
	rw	r7, FLOP
	lj	tmrandom
	lj	seed
	lw	r7, [FLOP]
	srz	r7
	nr	r7, 0b1111
	kz_init(r7, uzdat_list)
	im	imask

	lw	r7, testv
.loop:
	lw	r5, [r7]
	cwt	r5, 0
	jes	.done
	lw	r6, [r7+1]
	lj	floptest
	cwt	r1, 0
	jn	err
	awt	r7, TEST_VEC_SIZE
	ujs	.loop
.done:
	kz_reset([FLOP])

halt:	hlt
	ujs	halt

err:	hlt	1
	ujs	err

	.equ	wrbuf .
	.equ	rdbuf wrbuf + 4*128


