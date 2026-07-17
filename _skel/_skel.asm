	.cpu	mera400

	.include cpu.inc
	.include io.inc

	mcl
	uj	start

imask:	.word	IMASK_CH10_15 ; see /usr/share/emas/include/cpu.inc for more
izero:	.word	IMASK_NONE

dummy:	hlt	045	; halt on interrupts that shouldn't happen
	ujs	dummy

stack:	.res	11*4, 0x0ded

	; 0x40 — 32 interrupt vectors - all dummy by default
	.org	INTV
	.res	32, dummy
	; 0x60 — EXL (syscall) handler - dummy by default
	.org	EXLV
	.word	dummy
	; 0x61 — interrupt stack pointer - by default after the program
	.org	STACKP
	.word	stack

	; 0x70 — first usable address
	.org	OS_START

	; channel/device I/O driver
	.include kz.asm
	; putc/getc/puts/write/read etc.
	.include stdio.asm

; ------------------------------------------------------------------------
	.const	CH 15
	.const	TERM CH\IO_CHAN | 0\IO_DEV

; ------------------------------------------------------------------------
; ---- MAIN --------------------------------------------------------------
; ------------------------------------------------------------------------
start:

	; program code goes here

.wait:	hlt
	ujs	.wait

stack:
