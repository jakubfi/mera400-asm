
	.cpu	mera400

	.include cpu.inc
	.include io.inc

	uj	start

imask:	.word	IMASK_ALL & ~(IMASK_CPU_H | IMASK_GROUP_L)

dummy:	lip

stack:	.res	11*4, 0xdead

	.org	INTV
	.res	32, dummy
	.org	EXLV
	.word	dummy
	.org	STACKP
	.word	stack
	.org	OS_START

	.include kz.asm
	.include stdio.asm
	#include "stdio_macros.h"

; ------------------------------------------------------------------------

	.const	CH	15
	.const	PC	CH\IO_CHAN | 0\IO_DEV
	.const	FLOP	CH\IO_CHAN | 2\IO_DEV
uzdat_list:
	.word	PC, -1

	.const	TRACKS	76
	.const	SPT	26
	.const	SECT_LEN 128


; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------

start:
	kz_init(CH, uzdat_list)
	im	imask

	kz_wrseek(1\KZ_FLOPPY_TRACK | 1\KZ_FLOPPY_SECTOR, FLOP)
.loop:
	read(len, PC, 2)
	lwt	r2, 1
	cwt	r1, 0
	jl	.eloop

	lw	r7, [len]
	cwt	r7, 0
	jes	.done

	read(buf, PC, [len])
	lwt	r2, 2
	cwt	r1, 0
	jl	.eloop

	write(buf, FLOP, [len])
	cwt	r1, 0
	jls	.nack
	lw	r1, ok
	lw	r2, PC
	lw	r3, 1
	lj	write
	uj	.loop
.nack:
	lw	r1, fail
	lw	r2, PC
	lw	r3, 1
	lj	write
.eloop:
	hlt	1
	ujs	.eloop

.done:
	kz_detach(FLOP)
.hloop:	hlt	7
	ujs	.hloop

len:	.res	1
ok:	.word	0xbaba
fail:	.word	0xdede
buf:
