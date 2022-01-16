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
	.const	LOOPS 25
	.const	TIMER_CYCLE_MS 10
	.const	TIMER_PROC_TIME_US 23
test_time_ns:
	.dword	(LOOPS * TIMER_CYCLE_MS * 1000000) - (LOOPS * TIMER_PROC_TIME_US * 1000)
measured_time_ns:
	.res	1
cal_loops:
	.res	1
test_loops:
	.res	1
str_buf:
	.res	16

; ------------------------------------------------------------------------
timer_proc:
	irb	r3, .kim	; if (r3 < 0) then next test loop
	lw	r7, [measure]	; otherwise: load the exit adddres from last "measure" call
	md	[STACKP]	; and replace pre-interrupt IC stored on stack with it, so the test loop
	rw	r7, -SP_IC	; breaks, and control is transferred back to after the original "lj measure"
.kim:	lip

; ------------------------------------------------------------------------
; ARGUMENTS:
;  r4 - loop type:
	.const	LOOP_NULL 0	; null-loop (calibration loop)
	.const	LOOP_1 1	; 1-word test loop
	.const	LOOP_2 2	; 2-words test loop
;  r5 - word 1
;  r6 - word 2
; RETURN VALUE (exit through timer interrupt, but anyway):
;  r1 - count, high
;  r2 - count, low
measure:
	.res	1

	lwt	r1, 0		; loop counter, high
	lwt	r2, 0		; loop counter, low
	lw	r3, -(LOOPS+1)	; timer interrupt counter (+1 for the trigger)

	cwt	r4, 0		; LOOP_NULL
	jes	.instr_prepared	; done, no instruction inserted
	rw	r5, .loop_1	; at least one instruction needs to be inserted
	rw	r5, .loop_2	; do it for both loops
	cwt	r4, 1		; LOOP_1
	jes	.instr_prepared	; done, one instruction inserted
	rw	r6, .loop_2+1	; LOOP_2 - insert second instruction

.instr_prepared:
	lw	r4, [.jmptab+r4]

	fi	izero		; clear interrupts
	im	timer_enable	; enable timer interrupt
	hlt			; wait for timer interrupt to fire just before the test loop
	uj	r4		; jump to selected test loop

.loop_null:
	awt	r2, 1
	ac	r1, 0
	ujs	.loop_null
.loop_1:
	nop
	awt	r2, 1
	ac	r1, 0
	ujs	.loop_1
.loop_2:
	nop
	nop
	awt	r2, 1
	ac	r1, 0
	ujs	.loop_2

	uj	[measure]	; never reached, [measure] is popped in timer handler
.jmptab:
	.word	.loop_null, .loop_1, .loop_2

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
	hlt			; make sure first two timer interrupts pass by
	hlt			; those are prone to have a shorter cycle
	hlt			; +1 just in case
	im	izero

main_loop:

	; calibrate
	lwt	r4, LOOP_NULL
	lj	measure
	im	izero
	rw	r2, cal_loops

	; measure
	lwt	r4, LOOP_1
	lw	r5, r0 lw r7, r7
	lj	measure
	im	izero
	rw	r2, test_loops

	; calculate result
	ld	test_time_ns
	dw	test_loops
	lw	r3, r2
	ld	test_time_ns
	dw	cal_loops
	sw	r3, r2	; result
	rw	r3, measured_time_ns

	im	imask

	; print result
	lw	r1, [measured_time_ns]
	lw	r2, str_buf
	lj	unsigned2asc
	lw	r1, str_buf
	lw	r2, PC
	lj	puts

	lw	r1, '\r\n'
	lw	r2, PC
	lj	put2c

	im	izero

	uj	main_loop

test_table:
	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		lw r7, r7	.word 0
	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		shc r7, 1	.word 0
	.word	LOOP_1,		LOOP_1	shc r7, 1	.word 0		shc r7, 2	.word 0
	.word	LOOP_1,		LOOP_1	lw r7, r7	.word 0		lw r7, r7+r7	.word 0
	.word	LOOP_2,		LOOP_2	lw r7, r0	.word 0		lw r7, [r0]	.word 0
	.word	0xffff

stack:
