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
	.org	EXLV
	.word	measure.code+1
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
	.const	TIMER_PROC_TIME_US 30 ; measured correction for timer interrupt serving
test_time_ns:
	.float	99700000 ; (LOOPS * TIMER_CYCLE_MS * 1000000) - (LOOPS * TIMER_PROC_TIME_US * 1000) emas can't float :-(

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

	rz	.counter		; reset the loop counter
	lw	r5, -(LOOPS+1)		; timer interrupt counter (+1 for the trigger)
	rw	r5, loops		; make it available globally for the timer interrupt handler

	lw	r2, .code		; r2 is a pointer to loop code destination
	lw	r3, 1+.code-.loop	; r3 is loop instruction counter, starting from 3 (for the "ib .counter" + "ujs")
	lw	r7, [test_ptr]		; r7 = current test program instruction pointer
.next_instruction:
	lw	r1, [r7]		; r1 = current test program instruction
	awt	r7, 1			; point r7 to the next instruction
	cw	r1, END			; is this the end?
	jes	.write_ujs
	rw	r1, r2			; write current instruction into test loop
	awt	r2, 1			; next instruction destination
	awt	r3, 1			; increase instruction counter
	ujs	.next_instruction
.write_ujs:
	or	r3, [.ujs]		; "insert" the ujs instruction template
	rw	r3, r2			; store updated ujs
	rw	r7, test_ptr		; store current test pointer for the caller

	; predefined register and memory contents
	rz	scratch
	lwt	r0, -1
	lwt	r2, 1
	lwt	r3, -1
	lw	r4, timer_enable
	lw	r5, scratch<<1
	lw	r6, scratch
	lwt	r7, 0

	fi	izero			; clear interrupts
	im	timer_enable		; enable timer interrupt
	hlt				; wait for timer interrupt to fire just before the test loop

; ---- TEST LOOP ------------
.loop:	ib	.counter
.code:	.res	16
; ---------------------------

	; never reached. program returns to the address of the caller from the timer handler
.counter:
	.res	1
.ujs:	.word	0b_111_000_1_000_000_000

; ------------------------------------------------------------------------
run_test:
	.res	1

	im	imask

	; print test name
	lw	r1, [test_ptr]
	lw	r2, PC
	lj	puts

	lw	r1, '\t'
	lw	r2, PC
	lj	putc

	; move the test pointer
	lw	r1, [test_ptr]
	aw	r1, 3
	rw	r1, test_ptr

	; calibrate
	lj	measure
	im	izero
	lw	r7, [measure.counter]
	rw	r7, .cal_loops		; store as first word of float mantissa

	; measure
	lj	measure
	im	izero
	lw	r7, [measure.counter]
	rw	r7, .test_loops		; store as first word of float mantissa

	; convert measurements to float
	rz	.cal_loops+1		; second word of float mantissa = 0
	rz	.test_loops+1		; second word of float mantissa = 0
	lwt	r1, 15
	rw	r1, .cal_loops+2	; float exponent = 15
	rw	r1, .test_loops+2	; float exponent = 15
	lf	.cal_loops
	nrf
	rf	.cal_loops
	lf	.test_loops
	nrf
	rf	.test_loops

	; calculate result
	lf	test_time_ns
	df	.cal_loops
	rf	.measured_time_ns
	lf	test_time_ns
	df	.test_loops
	sf	.measured_time_ns
	rf	.measured_time_ns

	im	imask

	; convert result back to 16-bit int
	lw	r1, [.measured_time_ns]
	lw	r4, [.measured_time_ns+2]
	zlb	r4
.shift_loop:
	cwt	r4, 15
	jes	.print
	jgs	.print_none
	srz	r1
	awt	r4, 1
	ujs	.shift_loop

.print:
	; print result
	lw	r2, .str_buf
	lj	unsigned2asc
	lw	r1, .str_buf
	lw	r2, PC
	lj	puts
.print_none:
	lw	r1, ' '
	lw	r2, PC
	lj	putc

	lw	r1, 'ns'
	lw	r2, PC
	lj	put2c

	lw	r1, '\r\n'
	lw	r2, PC
	lj	put2c

	im	izero

	uj	[run_test]
.cal_loops:
	.res	3
.test_loops:
	.res	3
.measured_time_ns:
	.res	3
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
restart:
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
	lj	run_test
	lw	r7, [test_ptr]
	cw	r7, test_end
	jes	fin
	uj	next_test
fin:
	im	izero
	hlt
	uj	restart

test_ptr:
	.word	test_table

	.const	END -1
test_table:
	; r0=-1, r2=1, r3=-1, r6=scratch, r7=0
	; --- normal argument --------------------------------------------
	.asciiz "LW   "		.word END 			lw r1, r1 .word END ; 2500
	.asciiz "TW   "		.word END 			tw r1, r7 .word END ; 3750
	.asciiz "LS   "		.word END 			ls r1, r1 .word END ; 3930
	.asciiz "RI   "		lw r6, scratch .word END 	lw r6, scratch ri r6, r1 .word END ; 4310
	.asciiz "RW   "		.word END 			rw r1, r6 .word END ; 3510
	.asciiz "PW   "		.word END 			pw r1, r6 .word END ; 3520
	.asciiz "RJ   "		lw r2, measure.code+3 .word END	lw r2, measure.code+3 rj r1, r2 .word END ; 2810
	.asciiz "IS   "		rz r6 .word END			rz r6 is r3, r6 .word END ; 5860
	.asciiz "IS/P "		rz r6 jn r7 .word END		rz r6 is r7, r6 jn r7 .word END ; 4220
	.asciiz "BB   "		.word END			bb r7, r2 .word END ; 2660 // Ra * N != N
	.asciiz "BM   "		.word END			bm r3, r6 .word END ; 4220 // [N] * Ra != Ra
	.asciiz "BS   "		lwt r7, 3 .word END		lwt r7, 3 bs r3, r2 .word END ; 3140 // Ra * R7 != N * R7
	.asciiz "BC   "		.word END			bc r3, r7 .word END ; 2650 // Ra * N == N
	.asciiz "BN   "		.word END			bn r3, r3 .word END ; 2660 // Ra * N != 0
	; OU (not measured)
	; IN (not measured)

	; --- F/D --------------------------------------------------------
	.asciiz "AD   "		.word END			ad r7 .word END ; 8780
	.asciiz "SD   "		.word END			sd r7 .word END ; 8760
	; MW
	; DW
	; AF
	; SF
	; MF
	; DF

	; --- normal argument --------------------------------------------
	.asciiz "AW   "		.word END 			aw r1, r1 .word END ; 2660
	.asciiz "AC   "		.word END 			ac r1, r1 .word END ; 2650
	.asciiz "SW   "		.word END 			sw r1, r1 .word END ; 2660
	.asciiz "CW   "		.word END 			cw r1, r1 .word END ; 2660
	.asciiz "OR   "		.word END 			or r1, r1 .word END ; 2650
	.asciiz "OM   "		.word END		 	om r1, r6 .word END ; 5290
	.asciiz "NR   "		.word END 			nr r1, r1 .word END ; 2660
	.asciiz "NM   "		.word END 			nm r1, r6 .word END ; 5280
	.asciiz "ER   "		.word END 			er r1, r1 .word END ; 2660
	.asciiz "EM   "		.word END 			em r1, r6 .word END ; 5300
	.asciiz "XR   "		.word END 			xr r1, r1 .word END ; 2660
	.asciiz "XM   "		.word END		 	xm r1, r6 .word END ; 5280
	.asciiz "CL   "		.word END 			cl r1, r1 .word END ; 2660
	.asciiz "LB   "		.word END			lb r1, r5 .word END ; 5500
	.asciiz "RB   "		.word END			rb r1, r5 .word END ; 6420
	.asciiz "CB   "		.word END			cb r1, r5 .word END ; 5500

	; --- KA1 --------------------------------------------------------
	.asciiz "AWT/+"		.word END 			awt r1, 1 .word END ; 2660
	.asciiz "AWT/-"		.word END 			awt r1, -1 .word END ; 3140
	.asciiz "TRB  "		.word END 			trb r7, 1 .word END ; 2660
	.asciiz "IRB=0"		lwt r1, -1 .word END		lwt r1, -1 irb r1, 0 .word END ; 2660
	.asciiz "IRB!0"		lwt r1, -2 .word END 		lwt r1, -2 irb r1, 0 .word END ; 3140
	.asciiz "DRB=0"		lwt r1, 1 .word END		lwt r1, 1 drb r1, 0 .word END ; 2660
	.asciiz "DRB!0"		lwt r1, 2 .word END 		lwt r1, 2 drb r1, 0 .word END ; 3140
	.asciiz "CWT  "		.word END 			cwt r1, 1 .word END ; 2650
	.asciiz "LWT  "		.word END 			lwt r1, 1 .word END ; 2510
	.asciiz "LWS  "		.word END 			lws r1, 1 .word END ; 4230
	.asciiz "RWS  "		.word END 			rws r1, 2 .word END ; 3990

	; --- JS ---------------------------------------------------------
	.asciiz "UJS  "		.word END			ujs 0 .word END ; 2650
	.asciiz "JLS  "		.word END			jls 0 .word END ; 2660
	.asciiz "JES  "		.word END			jes 0 .word END ; 2650
	.asciiz "JGS  "		.word END			jgs 0 .word END ; 2650
	.asciiz "JVS  "		lw r0, r3 .word END		lw r0, r3 jvs 0 .word END ; 2660
	.asciiz "JXS  "		.word END			jxs 0 .word END ; 2660
	.asciiz "JYS  "		.word END			jys 0 .word END ; 2660
	.asciiz "JCS  "		.word END			jcs 0 .word END ; 2660

	; --- KA2 --------------------------------------------------------
	.asciiz "BLC  "		.word END			blc 1<<8 .word END ; 2650 // R0(0÷7) ∧ b == b
	.asciiz "EXL  "		      lw r1, [scratch] awt r2, -4 rw r1, scratch .word END
				exl 0 lw r1, [STACKP]  awt r1, -4 rw r1, STACKP  .word END ; 12080
	.asciiz "BRC  "		.word END			brc 1 .word END ; 2660 // R0(8÷15) ∧ b == b
	; NRF

	; --- C ----------------------------------------------------------
	.asciiz "RIC  "		.word END			ric r1 .word END ; 2180
	.asciiz "ZLB  "		.word END			zlb r1 .word END ; 2350
	.asciiz "SXU  "		.word END			sxu r1 .word END ; 2180
	.asciiz "NGA  "		.word END			nga r1 .word END ; 2660
	.asciiz "SLZ  "		.word END			slz r1 .word END ; 2350
	.asciiz "SLY  "		.word END			sly r1 .word END ; 2350
	.asciiz "SLX  "		.word END			slx r1 .word END ; 2350
	.asciiz "SRY  "		.word END			sry r1 .word END ; 2830
	.asciiz "NGL  "		.word END			ngl r1 .word END ; 2350
	.asciiz "RPC  "		.word END			rpc r1 .word END ; 2180
	.asciiz "SHC/1"		.word END			shc r1, 1 .word END ; 2830
	.asciiz "SHC/0"		.word END			shc r1, 0 .word END ; 7700
	.asciiz "RKY  "		.word END			rky r1 .word END ; 2180
	.asciiz "ZRB  "		.word END			zrb r1 .word END ; 2350
	.asciiz "SXL  "		.word END			sxl r1 .word END ; 2180
	.asciiz "NGC  "		.word END			ngc r1 .word END ; 2660
	.asciiz "SVZ  "		.word END			svz r1 .word END ; 2350
	.asciiz "SVY  "		.word END			svy r1 .word END ; 2350
	.asciiz "SVX  "		.word END			svx r1 .word END ; 2350
	.asciiz "SRX  "		.word END			srx r1 .word END ; 2820
	.asciiz "SRZ  "		.word END			srz r1 .word END ; 2830
	.asciiz "LPC  "		.word END			lpc r1 .word END ; 2170

	; --- S ----------------------------------------------------------
	; HLT 1900 until CPU halts (not measured)
	; MCL 13960 - instruction time + interface timeout (not measured)
	.asciiz "SIT  "		.word END			sit .word END ; 2200
	.asciiz "SIL  "		.word END			sil .word END ; 2190
	.asciiz "SIU  "		.word END			siu .word END ; 2190
	.asciiz "CIT  "		.word END			cit .word END ; 2200
	.asciiz "LIP  "		lw r7, [scratchp] lw r6, r7 awt r7, 4 rw r7, scratch lf lip_data rf r6     .word END
				lw r7, [STACKP]   lw r6, r7 awt r7, 4 rw r7, STACKP  lf lip_data rf r6 lip .word END ; 9620
	; GIU (not measured)
	; GIL (not measured)

	; --- J ----------------------------------------------------------
	.asciiz "UJ   "		lw r1, measure.code+3 .word END			lw r1, measure.code+3 uj r1 .word END ; 2500
	.asciiz "JL   "		lw r1, measure.code+3 .word END			lw r1, measure.code+3 jl r1 .word END ; 2500
	.asciiz "JE   "		lw r1, measure.code+3 .word END			lw r1, measure.code+3 je r1 .word END ; 2500
	.asciiz "JG   "		lw r1, measure.code+3 .word END			lw r1, measure.code+3 jg r1 .word END ; 2510
	.asciiz "JZ   "		lw r1, measure.code+3 .word END			lw r1, measure.code+3 jz r1 .word END ; 2500
	.asciiz "JM   "		lw r1, measure.code+3 .word END			lw r1, measure.code+3 jm r1 .word END ; 2510
	.asciiz "JN   "		lw r1, measure.code+4 lwt r0, 0 .word END	lw r1, measure.code+4 lwt r0, 0 jn r1 .word END ; 2500
	.asciiz "LJ   "		lw r1, measure.code+3 .word END			lw r1, measure.code+3 lj r1 .word 0 .word END ; 4000

	; --- L ----------------------------------------------------------
	.asciiz "LD   "		lwt r1, 0 .word END		lwt r1, 0 ld r1 .word END ; 5630
	.asciiz "LF   "		lwt r1, 0 .word END		lwt r1, 0 lf r1 .word END ; 7210
	.asciiz "LA   "		lwt r1, 0 .word END		lwt r1, 0 la r1 .word END ; 13480
	.asciiz "LL   "		lwt r1, 0 .word END		lwt r1, 0 ll r1 .word END ; 7200
	.asciiz "TD   "		lwt r1, 0 .word END		lwt r1, 0 td r1 .word END ; 5620
	.asciiz "TF   "		lwt r1, 0 .word END		lwt r1, 0 tf r1 .word END ; 7200
	.asciiz "TA   "		lwt r1, 0 .word END		lwt r1, 0 ta r1 .word END ; 13480
	.asciiz "TL   "		lwt r1, 0 .word END		lwt r1, 0 tl r1 .word END ; 7200

	; --- G ----------------------------------------------------------
	.asciiz "RD   "		.word END			rd r6 .word END ; 5160
	.asciiz "RF   "		.word END			rf r6 .word END ; 6500
	.asciiz "RA   "		.word END			ra r6 .word END ; 11960
	.asciiz "RL   "		.word END			rl r6 .word END ; 6520
	.asciiz "PD   "		.word END			pd r6 .word END ; 5180
	.asciiz "PF   "		.word END			pf r6 .word END ; 6500
	.asciiz "PA   "		.word END			pa r6 .word END ; 11840
	.asciiz "PL   "		.word END			pl r6 .word END ; 6500

	; --- B/N --------------------------------------------------------
	.asciiz "MB   "		.word END			mb r6 .word END ; 3740
	.asciiz "IM   "		.word END			im r4 .word END ; 3750
	.asciiz "KI   "		.word END			ki r6 .word END ; 3510
	; FI 3740 (not measured)
	.asciiz "SP   "		lw r1, sp_data .word END	lw r1, sp_data sp r1 .word END ; 6920
	.asciiz "MD   "		lw r1, r1+r1 .word END		md r7 lw r1, r1 .word END ; 2510
	.asciiz "RZ   "		.word END 			rz r6 .word END ; 3510
	.asciiz "IB   "		.word END		 	ib r6 .word END ; 5460

	; --- other ------------------------------------------------------
	.asciiz "NEF  "		.word END			jn r7 .word END ; 2200

	; --- CPU states -------------------------------------------------
	.asciiz "P4/Bm"		lw r1, r1 .word END		lw r1, r1+r1 .word END
	.asciiz "P4/UA"		awt r1, 1 .word END		awt r1, -1 .word END
	.asciiz "P5   "		lw r1, r7 .word END		lw r1, [r7] .word END
	.asciiz "WX   "		shc r1, 1 .word END		shc r1, 2 .word END
	.asciiz "WA   "		slz r1 .word END		nga r1 .word END
	.asciiz "W&   "		rpc r1 .word END		nga r1 .word END
	.asciiz "WE   "		lwt r1, 1 drb r1, 0 .word END	lwt r1, 2 drb r1, 0 .word END ; 480
test_end:

sp_data: ; IC, R0, SR
	.word	measure.code+3, -1, IMASK_GROUP_H
lip_data: ; IC, R0, SR
	.word	measure.code+10, -1, IMASK_GROUP_H

stack:
	.res	16
scratchp:
	.word scratch
scratch:
