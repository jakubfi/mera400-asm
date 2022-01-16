	.cpu mera400

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

; ------------------------------------------------------------------------

	.const	CH 15
	.const	FLOP CH\IO_CHAN | 2\IO_DEV
uzdat_list:
	.word	-1

	.const	TRACKS 76
	.const	SPT 26
	.const	SECT_LEN 128

; ------------------------------------------------------------------------
; r1 - image address
; r2 - device specification
; r3 - length (in words)
write_image:
	.res	1
	lw	r5, r3
	lw	r7, r1
	lw	r6, r2

.loop:
	; first byte
	lw	r1, [r7]
	shc	r1, 12
	nr	r1, 0b00001111
	or	r1, 0b01000000
	lw	r2, r6
	lj	putc

	; second byte
	lw	r1, [r7]
	shc	r1, 6
	nr	r1, 0b00111111
	or	r1, 0b01000000
	lw	r2, r6
	lj	putc

	; third byte
	lw	r1, [r7]
	nr	r1, 0b00111111
	or	r1, 0b01000000
	lw	r2, r6
	lj	putc

	awt	r7, 1
	drb	r5, .loop

	; end of transmission
	lw	r1, 0b01010000
	lw	r2, r6
	lj	putc

	uj	[write_image]

; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------

start:
	lw	r1, CH
	lw	r2, uzdat_list
	lj	kz_init

	im	imask

	lw      r1, 1	; sector
	lw      r2, 1	; track
	shc     r2, -5
	or      r1, r2
	lw      r2, 0	; drive
	or      r1, r2
	lw      r2, FLOP
	lj      kz_seek

	lw	r1, dt_data
	lw	r2, FLOP
	lw	r3, dt_data_end
	sw	r3, dt_data
	lj	write_image

	lw	r2, FLOP
	lj	kz_detach
	lj	kz_reset

halt:	hlt
	ujs	halt

dt_data:
	.include dt.inc
dt_data_end:
