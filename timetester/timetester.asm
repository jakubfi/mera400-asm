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
	.const	TIMER_PROC_TIME_US 23 ; measured correction for timer interrupt serving
	; TODO: re measure timer_proc with 'ib' now!
test_time_ns:
	.dword	(LOOPS * TIMER_CYCLE_MS * 1000000) - (LOOPS * TIMER_PROC_TIME_US * 1000)

; ------------------------------------------------------------------------
timer_proc:
	ib	loops		; loops++, if loops < 0 ...
	lip			; ...then next test loop
	lw	r5, [measure]	; if loops==0, then load the exit adddres from last "measure" call
	md	[STACKP]	; and replace pre-interrupt IC stored on stack with it, so the test loop
	rw	r5, -SP_IC	; breaks, and control is transferred back to after the original "lj measure"
.kim:	lip

loops:	.res	1

; ------------------------------------------------------------------------
; ARGUMENTS:
;  r4 - loop type:
	.const	LOOP_NULL 0	; null-loop (calibration loop)
	.const	LOOP_1 1	; 1-word test loop
	.const	LOOP_2 2	; 2-words test loop (anything >1)
;  r5 - word 1
;  r6 - word 2
; RETURN VALUE (exit is through timer interrupt, but it's a return value anyway):
;  r6 - count, high
;  r7 - count, low
measure:
	.res	1

	rz	.counter

	cwt	r4, LOOP_NULL	; if LOOP_NULL ...
	jes	.instr_prepared	; ... done, no instruction inserted, else:
	rw	r5, .i11	; at least one instruction needs to be inserted
	rw	r5, .i21	; do it for both loops
	cwt	r4, LOOP_1	; if LOOP_1 ...
	jes	.instr_prepared	; ... done, one instruction inserted, else:
	rw	r6, .i22	; LOOP_2 - insert second instruction
.instr_prepared:
	lw	r4, [.jmptab+r4]

	lw	r5, -(LOOPS+1)	; timer interrupt counter (+1 for the trigger)
	rw	r5, loops
	lwt	r6, 0		; loop counter, high
	lwt	r7, 0		; loop counter, low

	fi	izero		; clear interrupts
	im	timer_enable	; enable timer interrupt
	hlt			; wait for timer interrupt to fire just before the test loop
	uj	r4		; jump to selected test loop

.loop_null:
	ib	.counter
	uj	.loop_null
.loop_1:
	ib	.counter
.i11:	nop
	uj	.loop_1
.loop_2:
	ib	.counter
.i21:	nop
.i22:	nop
	uj	.loop_2

	uj	[measure]	; never reached, [measure] is popped in timer handler
.jmptab:
	.word	.loop_null, .loop_1, .loop_2
.counter:
	.res	1

; ------------------------------------------------------------------------
; ARGUMETS:
;  r7 - test address
run_test:
	.res	1

	rw	r7, .taddr
	im	imask

	lw	r1, r7
	lw	r2, PC
	lj	puts

	lw	r1, '\t'
	lw	r2, PC
	lj	putc

	; calibrate
	lw	r7, [.taddr]
	lw	r4, [r7+3]
	lw	r5, [r7+5]
	lw	r6, [r7+6]
	lj	measure
	im	izero
	lw	r7, [measure.counter]
	rw	r7, .cal_loops

	; measure
	lw	r7, [.taddr]
	lw	r4, [r7+4]
	lw	r5, [r7+7]
	lw	r6, [r7+8]
	lj	measure
	im	izero
	lw	r7, [measure.counter]
	rw	r7, .test_loops

	; calculate result
	ld	test_time_ns
	dw	.test_loops
	lw	r3, r2
	ld	test_time_ns
	dw	.cal_loops
	sw	r3, r2	; result
	rw	r3, .measured_time_ns

	im	imask

	; print result
	lw	r1, [.measured_time_ns]
	lw	r2, .str_buf
	lj	unsigned2asc
	lw	r1, .str_buf
	lw	r2, PC
	lj	puts

	lw	r1, ' '
	lw	r2, PC
	lj	putc

	lw	r1, 'ns'
	lw	r2, PC
	lj	put2c

	lw	r1, '\t'
	lw	r2, PC
	lj	putc

	lw	r1, [.cal_loops]
	lw	r2, .str_buf
	lj	unsigned2asc
	lw	r1, .str_buf
	lw	r2, PC
	lj	puts

	lw	r1, ' '
	lw	r2, PC
	lj	putc

	lw	r1, [.test_loops]
	lw	r2, .str_buf
	lj	unsigned2asc
	lw	r1, .str_buf
	lw	r2, PC
	lj	puts

	lw	r1, '\r\n'
	lw	r2, PC
	lj	put2c

	im	izero

	uj	[run_test]
.taddr:	.res	1
.cal_loops:
	.res	1
.test_loops:
	.res	1
.measured_time_ns:
	.res	1
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
	hlt			; make sure first two timer interrupts pass by
	hlt			; those are prone to have a shorter cycle
	hlt			; +1 just in case
	im	izero

	lw	r1, test_table
	rw	r1, test_ptr

next_test:
	lw	r7, [test_ptr]
	lj	run_test

	lw	r7, [test_ptr]
	awt	r7, 9
	cw	r7, test_end
	jes	fin
	rw	r7, test_ptr
	uj	next_test

fin:
	hlt
	ujs	fin

test_ptr:
	.word	test_table

	.const	END -1
	.asciiz "LW   "	.word END lw r1, r1 .word END
	.asciiz "AW   "	.word END aw r1, r1 .word END

test_table:
	.asciiz "LW   "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		lw r1, r1	.word 0
	.asciiz "AW   "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		aw r1, r1	.word 0
;	.asciiz "AC   "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		ac r1, r1	.word 0
;	.asciiz "SW   "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		sw r1, r1	.word 0
;	.asciiz "CW   "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		cw r1, r1	.word 0
;	.asciiz "OR   "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		or r1, r1	.word 0
;	.asciiz "XR   "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		xr r1, r1	.word 0
;	.asciiz "AWT+ "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		awt r1, 1	.word 0
	.asciiz "AWT- "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		awt r1, -1	.word 0
	.asciiz "SHC1 "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		shc r1, 1	.word 0
	.asciiz "SHC0 "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		shc r1, 0	.word 0
;	.asciiz "CWT  "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		cwt r1, 1	.word 0
;	.asciiz "LWT  "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		lwt r1, 1	.word 0
;	.asciiz "UJS0 "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		ujs 0		.word 0
	.asciiz "SXU  "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		sxu r1		.word 0
	.asciiz "SLZ  "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		slz r1		.word 0
;	.asciiz "ZLB  "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		zlb r1		.word 0
;	.asciiz "NGA  "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		nga r1		.word 0
;	.asciiz "NGL  "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		ngl r1		.word 0
;	.asciiz "RPC  "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		rpc r1		.word 0
;	.asciiz "LPC  "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		lpc r1		.word 0
	.asciiz "RKY  "	.word	LOOP_NULL,	LOOP_1	.word 0		.word 0		rky r1		.word 0
	.asciiz "LD   "	.word	LOOP_1,		LOOP_2	lwt r1, 0	.word 0		lwt r1, 0	ld r1
	.asciiz "LF   "	.word	LOOP_1,		LOOP_2	lwt r1, 0	.word 0		lwt r1, 0	lf r1
;	.asciiz "LL   "	.word	LOOP_1,		LOOP_2	lwt r1, 0	.word 0		lwt r1, 0	ll r1
;	.asciiz "LA   "	.word	LOOP_1,		LOOP_2	lwt r1, 0	.word 0		lwt r1, 0	la r1
;	.asciiz "MD!!!"	.word	LOOP_1,		LOOP_2	lwt r1, 0	.word 0		lwt r1, 0	md r1 ; TODO: ona się wykona!!!!!
	.asciiz "AD   "	.word	LOOP_1,		LOOP_2	lwt r1, 0	.word 0		lwt r1, 0	ad r1
;	.asciiz "SD   "	.word	LOOP_1,		LOOP_2	lwt r1, 0	.word 0		lwt r1, 0	sd r1
;	.asciiz "MW   "	.word	LOOP_1,		LOOP_2	lwt r1, 0	.word 0		lwt r1, 0	mw r1
;	.asciiz "DW   "	.word	LOOP_1,		LOOP_2	lwt r1, 0	.word 0		lwt r1, 0	dw r1

	.asciiz "P4/Bm"	.word	LOOP_1,		LOOP_1	lw r1, r1	.word 0		lw r1, r1+r1	.word 0
	.asciiz "P4/KA"	.word	LOOP_1,		LOOP_1	awt r1, 1	.word 0		awt r1, -1	.word 0
	.asciiz "P5   "	.word	LOOP_2,		LOOP_2	lw r1, r0	.word 0		lw r1, [r0]	.word 0
	.asciiz "WX   "	.word	LOOP_1,		LOOP_1	shc r1, 1	.word 0		shc r1, 2	.word 0
test_end:

stack:
	.res	16

scratch:
