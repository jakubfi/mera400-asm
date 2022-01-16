	.cpu	mera400

	.include cpu.inc
	.include io.inc

	uj	start

imask:	.word	IMASK_NONE ; IMASK_PARITY, IMASK_NOMEM, IMASK_CPU_H, IMASK_IFPOWER, IMASK_GROUP_H, IMASK_CH0_1, IMASK_CH2_3, IMASK_CH4_9, IMASK_CH10_15, IMASK_GROUP_L
izero:	.word	IMASK_NONE

dummy:	hlt	045	; halt on interrupts that shouldn't happen
	ujs	dummy

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

; ------------------------------------------------------------------------
	.const	CH 15
	.const	TERM CH\IO_CHAN | 0\IO_DEV
uzdat_list:
	.word	TERM, -1

; ------------------------------------------------------------------------
; ---- MAIN --------------------------------------------------------------
; ------------------------------------------------------------------------
start:


h:	hlt
	ujs	h

