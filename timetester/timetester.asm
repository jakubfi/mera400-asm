	.cpu	mera400

	.include cpu.inc
	.include io.inc

	uj	start

timer_enable:
	.word	IMASK_GROUP_H
imask:	.word	IMASK_CH10_15
izero:	.word	IMASK_NONE
exitto:	.res	1

	.org	INTV_TIMER
	.word	timer_proc
	.org	STACKP
	.word	stack

	.org	OS_START

	.include kz.asm
	.include stdio.asm

; ------------------------------------------------------------------------
	.const	LOOPS 25
	.const	TIMER_CYCLE_MS 10
	.const	TIMER_PROC_TIME_US 23
test_time_ns:
	.dword	(LOOPS * TIMER_CYCLE_MS * 1000000) - (LOOPS * TIMER_PROC_TIME_US * 1000)
final_time_ns:
	.res	1
cal:	.res	1
test:	.res	1
buf:	.res	16

; ------------------------------------------------------------------------
	.const	CH 15
	.const	PC CH\IO_CHAN | 0\IO_DEV
uzdat_list:
	.word	PC, -1

; ------------------------------------------------------------------------
timer_proc:
	irb	r3, .exit
	lw	r7, [exitto]
	md	[STACKP]
	rw	r7, -SP_IC
.exit:	lip

; ------------------------------------------------------------------------
start:
	; initialize KZ
	lw	r1, CH
	lw	r2, uzdat_list
	lj	kz_init
	im	imask

	lw	r1, '\r\n'
	lw	r2, PC
	lj	put2c

	im	izero

main_loop:

calibrate:
	lwt	r1, 0		; loop counter, low word
	lwt	r2, 0		; loop counter, high word
	lw	r3, -(LOOPS+3)	; timer interrupt counter (+1 for the trigger)

	lw	r7, cal_done
	rw	r7, exitto
	fi	izero
	im	timer_enable	; enable timer interrupt
	hlt			; wait for the user to enable timer
	hlt			; first fire of the clock interrupt can be a little wonky
	hlt			; second one too
.loop:
	awt	r1, 1
	ac	r2, 0
	ujs	.loop

cal_done:
	im	izero
	rw	r1, cal

	lwt	r1, 0		; loop counter, low word
	lwt	r2, 0		; loop counter, high word
	lw	r3, -(LOOPS+3)	; timer interrupt counter (+1 for the trigger)

	lw	r7, results
	rw	r7, exitto
	fi	izero
	im	timer_enable
	hlt			; wait for timer
	hlt
	hlt
.loop:
	lw	r7, r7

	awt	r1, 1
	ac	r2, 0
	ujs	.loop

results:
	im	izero
	rw	r1, test

	; calculate result
	ld	test_time_ns
	dw	test
	lw	r3, r2
	ld	test_time_ns
	dw	cal
	sw	r3, r2	; result
	rw	r3, final_time_ns

	im	imask

	; print result
	lw	r1, [final_time_ns]
	lw	r2, buf
	lj	unsigned2asc
	lw	r1, buf
	lw	r2, PC
	lj	puts

	lw	r1, '\r\n'
	lw	r2, PC
	lj	put2c

	im	izero

	uj	main_loop
h:	hlt
	ujs	h

stack:
