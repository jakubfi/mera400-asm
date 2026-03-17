	.cpu	mera400

	.include cpu.inc
	.include io.inc

	uj	start

timer_enable:
	.word	IMASK_GROUP_H
imask:	.word	IMASK_CH10_15
izero:	.word	IMASK_NONE

	.org	INTV_TIMER
	.word	timer_proc
	.org	STACKP
	.word	stack

	.org	OS_START

	.include kz.asm
	.include stdio.asm

; ------------------------------------------------------------------------
	.const	CH 15
	.const	PC CH\IO_CHAN | 0\IO_DEV
uzdat_list:
	.word	PC, -1

; ------------------------------------------------------------------------
	.const	LOOPS 10
	.const	TIMER_CYCLE_MS 10

; ------------------------------------------------------------------------
timer_proc:
	ib	loops		; loops++, if loops < 0 ...
	lip			; ...then next test loop
	lw	r5, [measure]	; else: load the exit adddres from last "measure" call
	md	[STACKP]	; and replace pre-interrupt IC stored on stack with it, so the test loop
	rw	r5, -SP_IC	; breaks, and control is transferred back to after the original "lj measure"
	lip
loops:	.res	1

; ------------------------------------------------------------------------
measure:
	.res	1

	lwt	r1, 0
	lwt	r2, 0

	lw	r5, -(LOOPS+1)		; timer interrupt counter (+1 for the trigger)
	rw	r5, loops		; make it available globally for the timer interrupt handler

	fi	izero			; clear interrupts
	im	timer_enable		; enable timer interrupt
	hlt				; wait for timer interrupt to fire just before the test loop
.loop:	
	aw	r2, 3 ; number of instructions in the test loop
	ac	r1, 0
	ujs	.loop
	; never reached. program returns to the address of the caller from the timer handler

; ------------------------------------------------------------------------
run_test:
	.res	1

	im	imask

	; measure
	lj	measure
	im	izero

	; after measure: 
	; r1 - MSW number of executed instructions
	; r2 - LSW

	lw	r1, r2

.print:
	; print result
	lw	r2, .str_buf
	lj	unsigned2asc
	lw	r1, .str_buf
	lw	r2, PC
	lj	puts

	lw	r1, '0 '
	lw	r2, PC
	lj	put2c

	lw	r1, 'IP'
	lw	r2, PC
	lj	put2c
	lw	r1, 'S '
	lw	r2, PC
	lj	put2c
	lw	r1, '\r\n'
	lw	r2, PC
	lj	put2c

	uj	[run_test]

.str_buf:
	.res	16

; ------------------------------------------------------------------------
; ---- MAIN --------------------------------------------------------------
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

	im	timer_enable
	hlt			; Make sure first two timer interrupts pass by. Those are prone to have
	hlt			; a shorter cycle when clock is enabled after the program has started.
	hlt			; +1 just in case
	im	izero

.loop:
	lj	run_test
	uj	.loop

stack:
