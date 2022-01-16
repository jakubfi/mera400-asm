
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

	.const	CH	15
	.const	PC	CH\IO_CHAN | 0\IO_DEV
	.const	FLOP	CH\IO_CHAN | 2\IO_DEV
uzdat_list:
	.word	PC, -1

	.const	TRACKS	76
	.const	SPT	26
	.const	HEADER_LEN 4
	.const	SECT_LEN 128

drive:	.word	0
retries:.word	0
conf_retries:
	.word	0

; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------

start:

	; seed prng

	lj	tmrandom
	lj	seed

	kz_init(CH, uzdat_list)

	im	imask

	kz_reset(FLOP)

	rndfill(wrbuf, 128/2)

	; write data

	kz_wrseek(50\KZ_FLOPPY_TRACK | 13\KZ_FLOPPY_SECTOR, FLOP)
	write(wrbuf, FLOP, 128)
	kz_detach(FLOP)

	; read data

	kz_seek(50\KZ_FLOPPY_TRACK | 13\KZ_FLOPPY_SECTOR, FLOP)
	read(rdbuf, FLOP, 128)
	kz_detach(FLOP)

	; print data

	put2c('\n\r', PC)
	put2c('\n\r', PC)
	puts(rdbuf, PC)
	put2c('\n\r', PC)
	put2c('\n\r', PC)
	puts(wrbuf, PC)
	put2c('\n\r', PC)
	put2c('\n\r', PC)

	memcmp(rdbuf, wrbuf, 128/2)

	cwt	r1, 0
	jes	halt
err:	hlt	1
	ujs	err

halt:	hlt
	ujs	halt

wrbuf:	.res	128/2
	.word	0
rdbuf:	.res	128/2
	.word	0



