	.cpu	mera400
	.include cpu.inc
	.include io.inc
	uj	start

imask:	.word	IMASK_ALL & ~IMASK_CPU_H
memfault:
	.word	0
memparity:
	.word	0
mem_size:
	.word	0
dummy:  hlt	045
	ujs	dummy
nomem:
	ib	memfault
	lip
	hlt	077
parity:
	ib	memparity
	lip
	hlt	077

	.org	INTV
	.res	32, dummy
	.org	EXLV
	.word   dummy
	.org	STACKP
	.word   stack

	.org	OS_START
	.include kz.asm
	.include stdio.asm

	.const	CH	15
	.const	TERM	CH\IO_CHAN | 0\IO_DEV

segment:.word	1
page:	.word	15
module:	.word	0
frame:	.word	0

; ------------------------------------------------------------------------
; r1, r2 - segment, page
; r3, r4 - module, frame
mem_cfg:
	.res	1

	lw	r1, [segment]
	lw	r2, [page]
	lw	r3, [module]

	slz	r3	; module in place
	or	r3, 1	; memory configuration in place
	shc	r4, -5	; frame in place
	or	r3, r4	; frame/module in r3

	shc	r2, -12	; page in place
	or	r2, r1	; page/segment in r2

	lwt	r1, 0	; return: OK
.retry:
	ou	r2, r3
	.word	.no, .en, .ok, .pe
.no:	lwt	r1, 1	; return: no answer
	ujs	.fin
.en:	ujs	.retry	; should not happen?
.pe:	lwt	r1, 2	; return: partity error (should not happen)
.ok:

.fin:
	uj	[mem_cfg]

; ------------------------------------------------------------------------
print_write_reqs:
	.res	1

	lw	r1, .txt
	lw	r2, TERM
	lj	puts

	rz	module
	rz	frame
	.const	MAGIC 0b1100110000110011

.new_module:
	lw	r1, 16
	rw	r1, .frames_in_module	; 16 frames in a module by default

	lw	r4, 15
	lj	mem_cfg			; configure frame 15 from current module

	cw	r1, 0
	jn	.bits_4			; if that didn't work, assume 4-bit address (16 frames)

	mb	segment
	lw	r4, 15
	pw	r4, 0xf000		; write 15 there
	mb	.zero

	lw	r4, 7
	lj	mem_cfg			; configure frame 7 from current module

	mb	segment
	lw	r4, 7
	pw	r4, 0xf000		; write 7 there
	mb	.zero

	lw	r4, 15
	lj	mem_cfg			; configure back frame 15

	mb	segment
	tw	r4, 0xf000		; read the value stored there
	mb	.zero

	cwt	r4, 15			; is the value stored there 15? or 7?
	jn	.bits_3			; it's 7 => 3-bit address (significant bit has been cut)
	jes	.bits_4			; if it's 15, value stored in frame 7 didn't overwrite value in frame 15 => 4-bit address

.bits_3:
	lw	r1, 8
	rw	r1, .frames_in_module
.bits_4:
	rz	memfault
	rz	memparity

.next_frame:
	lw	r4, [frame]
	lj	mem_cfg
	cw	r1, 0
	je	.conf_ok

	lw	r1, [.system]
	cw	r1, 1
	je	.system_ok
	uj	.conf_fail

.conf_ok:
	rz	.system
	lw	r4, MAGIC
	mb	segment
	pw	r4, 0xf000
	lw	r4, 0
	tw	r4, 0xf000
	mb	.zero

	lw	r2, [memfault]
	rz	memfault
	cw	r2, 0
	jn	.write_fail

	lw	r2, [memparity]
	rz	memparity
	cw	r2, 0
	jn	.parity_fail

	cw	r4, MAGIC
	jn	.read_fail

	jes	.all_ok

.system_ok:
	lw	r1, [mem_size]
	awt	r1, 4
	rw	r1, mem_size
	lw	r1, 'S'
	ujs	.print
.conf_fail:
	lw	r1, 'C'
	ujs	.print
.write_fail:
	lw	r1, 'W'
	ujs	.print
.parity_fail:
	lw	r1, 'P'
	ujs	.print
.read_fail:
	lw	r1, 'R'
	ujs	.print
.all_ok:
	lw	r1, [mem_size]
	awt	r1, 4
	rw	r1, mem_size
	lw	r1, '.'
.print:
	lw	r2, TERM
	lj	putc

	lw	r1, [frame]
	awt	r1, 1
	rw	r1, frame
	cw	r1, [.frames_in_module]
	jn	.next_frame

	lw	r1, '\r\n'
	lw	r2, TERM
	lj	put2c

	rz	frame
	lw	r1, [module]
	awt	r1, 1
	rw	r1, module
	cw	r1, 16
	jn	.new_module

	lw	r1, .msize
	lw	r2, TERM
	lj	puts
	lw	r1, [mem_size]
	lw	r2, .buf
	lj	unsigned2asc2
	lw	r1, .buf
	lw	r2, TERM
	lj	puts
	lw	r1, .msizet
	lw	r2, TERM
	lj	puts

	uj	[print_write_reqs]

.txt:	.asciiz	"\r\nMemory check map:\r\n--------------------------\r\n"
.msize:	.asciiz	"\r\nMemory size: "
.msizet:.asciiz	" kwords\n\r"
.buf:	.res	10
.zero:	.word	0
.int:	.word	0
.system:.word	1
.frames_in_module:
	.word	16

; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------

start:
	mcl
	lw	r1, CH
	lj	kz_init

	lw	r1, nomem
	rw	r1, INTV_NOMEM
	lw	r1, parity
	rw	r1, INTV_PARITY

	im	imask

	lj	print_write_reqs

	hlt

stack:
