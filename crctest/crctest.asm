
	.cpu	mera400

	.include cpu.inc
	.include io.inc

	uj	start

imask:	.word	IMASK_ALL & ~(IMASK_CPU_H | IMASK_GROUP_L)

dummy:	hlt	045
	ujs	dummy

stack:	.res	11*4, 0x0ded

	.org	INTV
	.res	32, dummy
	.org	EXLV
	.word	dummy
	.org	STACKP
	.word	stack
	.org	OS_START

; ------------------------------------------------------------------------

	.const	CH 15
	.const	TERM	CH\IO_CHAN | 0\IO_DEV

	.include kz.asm
	.include stdio.asm
	.include crc.asm

; ------------------------------------------------------------------------

#define hex2asc(val, str)	\
	lw	r1, val		\
	lw	r2, str		\
	lj	hex2asc
	
#define puts(buf, dev)		\
	lw	r1, buf		\
	lw	r2, dev		\
	lj	puts

#define crc16(buf, len)		\
	lw	r1, buf		\
	lw	r2, len		\
	lj	crc16

#define kz_init(chan) \
	lw	r1, chan	\
	lj	kz_init	

; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
start:
	mcl

	kz_init(CH)

	im	imask

	crc16(buf, buf_len)
	hex2asc(r1, out)
	puts(out, TERM)

.lhlt:	hlt
	ujs	.lhlt

; ------------------------------------------------------------------------
buf:	.ascii "123456789"
	.const buf_len 9
out:	.res	16

