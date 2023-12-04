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
	.const	TIMER_PROC_TIME_US 30 ; measured correction for timer interrupt serving
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
measure:
	.res	1

	rz	.counter		; reset the loop counter
	lw	r5, -(LOOPS+1)		; timer interrupt counter (+1 for the trigger)
	rw	r5, loops		; make it available globally for the timer interrupt handler

	lw	r2, .code		; r2 is a pointer to loop code destination
	lw	r3, 1+.code-.loop	; r3 is loop instruction counter, starting from 3 (for the "ib .couter" + "ujs")
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

	fi	izero			; clear interrupts
	im	timer_enable		; enable timer interrupt
	hlt				; wait for timer interrupt to fire just before the test loop

; ---- TEST LOOP ------------
.loop:	ib	.counter
.code:	.res	32
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
	rw	r7, .cal_loops

	; measure
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

;	lw	r1, '\t'
;	lw	r2, PC
;	lj	putc
;
;	lw	r1, [.cal_loops]
;	lw	r2, .str_buf
;	lj	unsigned2asc
;	lw	r1, .str_buf
;	lw	r2, PC
;	lj	puts
;
;	lw	r1, ' '
;	lw	r2, PC
;	lj	putc
;
;	lw	r1, [.test_loops]
;	lw	r2, .str_buf
;	lj	unsigned2asc
;	lw	r1, .str_buf
;	lw	r2, PC
;	lj	puts

	lw	r1, '\r\n'
	lw	r2, PC
	lj	put2c

	im	izero

	uj	[run_test]
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
	lj	run_test
	lw	r7, [test_ptr]
	cw	r7, test_end
	jes	fin
	uj	next_test
fin:
	hlt
	ujs	fin

test_ptr:
	.word	test_table

	.const	END -1
test_table:
	; --- normal argument --------------------------------------------
	.asciiz "LW   "		.word END 			lw r1, r1 .word END ; 2500
	.asciiz "TW   "		lwt r1, 0 .word END 		lwt r1, 0 tw r1, r1 .word END ; 3750
	.asciiz "LS   "		.word END 			ls r1, r1 .word END ; 3930
	.asciiz "RI   "		lw r1, scratch .word END 	lw r1, scratch ri r1, r1 .word END ; 4310
	.asciiz "RW   "		lw r1, scratch .word END 	lw r1, scratch rw r1, r1 .word END ; 3510
	.asciiz "PW   "		lw r1, scratch .word END 	lw r1, scratch pw r1, r1 .word END ; 3520
	.asciiz "RJ   "		lw r2, measure.code+3 .word END	lw r2, measure.code+3 rj r1, r2 .word END ; 2810
	.asciiz "IS   "		lwt r1, -1 lw r2, scratch rz r2 .word END	lwt r1, -1 lw r2, scratch rz r2 is r1, r2 .word END ; TODO: time
	.asciiz "IS/P "		lwt r1, 0 lw r2, scratch rz r2 jgs -1 .word END	lwt r1, 0 lw r2, scratch rz r2 is r1, r2 jgs -1 .word END ; TODO: time
	; BB
	; BM
	; BS
	; BC
	; BN
	; OU
	; IN

	; --- F/D --------------------------------------------------------
	.asciiz "AD   "		lwt r1, 0 .word END		lwt r1, 0 ad r1 .word END ; 8780
	.asciiz "SD   "		lwt r1, 0 .word END		lwt r1, 0 sd r1 .word END ; 8760
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
	.asciiz "OM   "		lw r1, scratch .word END 	lw r1, scratch om r1, r1 .word END ; 5290
	.asciiz "NR   "		.word END 			nr r1, r1 .word END
	.asciiz "NM   "		lw r1, scratch .word END 	lw r1, scratch nm r1, r1 .word END
	.asciiz "ER   "		.word END 			er r1, r1 .word END
	.asciiz "EM   "		lw r1, scratch .word END 	lw r1, scratch em r1, r1 .word END
	.asciiz "XR   "		.word END 			xr r1, r1 .word END
	.asciiz "XM   "		lw r1, scratch .word END 	lw r1, scratch xm r1, r1 .word END
	.asciiz "CL   "		.word END 			cl r1, r1 .word END ; 2660
	.asciiz "LB   "		lwt r1, 0 .word END		lwt r1, 0 lb r1, r1 .word END ; 5500
	.asciiz "RB   "		lw r1, scratch<<1 .word END	lw r1, scratch<<1 rb r1, r1 .word END ; 6420
	.asciiz "CB   "		lwt r1, 0 .word END		lwt r1, 0 cb r1, r1 .word END ; 5500

	; --- KA1 --------------------------------------------------------
	.asciiz "AWT/+"		.word END 			awt r1, 1 .word END ; 2660
	.asciiz "AWT/-"		.word END 			awt r1, -1 .word END ; 3140
	; TRB
	; IRB
	; DRB
	.asciiz "CWT  "		.word END 			cwt r1, 1 .word END
	.asciiz "LWT  "		.word END 			lwt r1, 1 .word END ; 2510
	.asciiz "LWS  "		.word END 			lws r1, 1 .word END ; 4230
	.asciiz "RWS  "		.word END 			rws r1, 2 .word END ; 3990

	; --- JS ---------------------------------------------------------
	.asciiz "UJS/+"		.word END			ujs 0 .word END ; 2650
	.asciiz "UJS/-"		.word END			ujs -1 .word END ; 3140
	.asciiz "JLS  "		lw r0, ?L .word END		lw r0, ?L jls 0 .word END ; 2660
	.asciiz "JES  "		lw r0, ?E .word END		lw r0, ?E jes 0 .word END
	.asciiz "JGS  "		lw r0, ?G .word END		lw r0, ?G jgs 0 .word END
	.asciiz "JVS  "		lw r0, ?V .word END		lw r0, ?V jvs 0 .word END
	.asciiz "JXS  "		lw r0, ?X .word END		lw r0, ?X jxs 0 .word END
	.asciiz "JYS  "		lw r0, ?Y .word END		lw r0, ?Y jys 0 .word END
	.asciiz "JCS  "		lw r0, ?C .word END		lw r0, ?C jcs 0 .word END

	; --- KA2 --------------------------------------------------------
	; BLC
	; EXL
	; BRC
	; NRF

	; --- C ----------------------------------------------------------
	.asciiz "RIC  "		.word END			ric r1 .word END ; 2180
	.asciiz "ZLB  "		.word END			zlb r1 .word END ; 2350
	.asciiz "SXU  "		.word END			sxu r1 .word END ; 2180
	.asciiz "NGA  "		.word END			nga r1 .word END ; 2660
	.asciiz "SLZ  "		.word END			slz r1 .word END ; 2350
	.asciiz "SLY  "		.word END			sly r1 .word END
	.asciiz "SLX  "		.word END			slx r1 .word END
	.asciiz "SRY  "		.word END			sry r1 .word END ; 2830
	.asciiz "NGL  "		.word END			ngl r1 .word END
	.asciiz "RPC  "		.word END			rpc r1 .word END
	.asciiz "SHC/1"		.word END			shc r1, 1 .word END ; 2830
	.asciiz "SHC/0"		.word END			shc r1, 0 .word END ; 7700
	.asciiz "RKY  "		.word END			rky r1 .word END
	.asciiz "ZRB  "		.word END			zrb r1 .word END
	.asciiz "SXL  "		.word END			sxl r1 .word END
	.asciiz "NGC  "		.word END			ngc r1 .word END
	.asciiz "SVZ  "		.word END			svz r1 .word END ; 2350
	.asciiz "SVY  "		.word END			svy r1 .word END
	.asciiz "SVX  "		.word END			svx r1 .word END
	.asciiz "SRX  "		.word END			srx r1 .word END ; 2820
	.asciiz "SRZ  "		.word END			srz r1 .word END
	.asciiz "LPC  "		.word END			lpc r1 .word END

	; --- S ----------------------------------------------------------
	; HLT
	; MCL
	.asciiz "SIT  "		.word END			sit .word END ; 2200
	.asciiz "SIL  "		.word END			sil .word END
	.asciiz "SIU  "		.word END			siu .word END
	.asciiz "CIT  "		.word END			cit .word END
	; LIP
	; no 2nd CPU, this would measure interface timeout
	;.asciiz "GIU  "		.word END			giu .word END
	;.asciiz "GIL  "		.word END			gil .word END

	; --- J ----------------------------------------------------------
	.asciiz "UJ   "		lw r1, measure.code+3 .word END			lw r1, measure.code+3 uj r1 .word END ; 2500
	.asciiz "JL   "		lw r1, measure.code+5 lw r0, ?L .word END	lw r1, measure.code+5 lw r0, ?L jl r1 .word END
	.asciiz "JE   "		lw r1, measure.code+5 lw r0, ?E .word END	lw r1, measure.code+5 lw r0, ?E je r1 .word END
	.asciiz "JG   "		lw r1, measure.code+5 lw r0, ?G .word END	lw r1, measure.code+5 lw r0, ?G jg r1 .word END
	.asciiz "JZ   "		lw r1, measure.code+5 lw r0, ?Z .word END	lw r1, measure.code+5 lw r0, ?Z jz r1 .word END
	.asciiz "JM   "		lw r1, measure.code+5 lw r0, ?M .word END	lw r1, measure.code+5 lw r0, ?M jm r1 .word END
	.asciiz "JN   "		lw r1, measure.code+5 lw r0, 0 .word END	lw r1, measure.code+5 lw r0, 0 jn r1 .word END
	.asciiz "LJ   "		lw r1, measure.code+5 lw r0, 0 .word END	lw r1, measure.code+5 lw r0, 0 lj r1 .word 0 .word END ; 4000

	; --- L ----------------------------------------------------------
	.asciiz "LD   "		lwt r1, 0 .word END		lwt r1, 0 ld r1 .word END ; 5630
	.asciiz "LF   "		lwt r1, 0 .word END		lwt r1, 0 lf r1 .word END ; 7210
	.asciiz "LA   "		lwt r1, 0 .word END		lwt r1, 0 la r1 .word END ; 13480
	.asciiz "LL   "		lwt r1, 0 .word END		lwt r1, 0 ll r1 .word END ; 7200
	; TD
	; TF
	; TA
	; TL

	; --- G ----------------------------------------------------------
	; RD
	; RF
	; RA
	; RL
	; PD
	; PF
	; PA
	; PL

	; --- B/N --------------------------------------------------------
	.asciiz "MB   "		rz scratch lw r1, scratch .word END	rz scratch lw r1, scratch mb r1 .word END ; 3740
	.asciiz "IM   "		lw r1, timer_enable .word END	lw r1, timer_enable im r1 .word END ; 3750
	.asciiz "KI   "		lw r1, scratch .word END	lw r1, scratch ki r1 .word END ; 3510
	; FI
	; SP
	; MD
	.asciiz "RZ   "		lw r1, scratch .word END 		lw r1, scratch rz r1 .word END ; 3510
	.asciiz "IB   "		rz scratch lw r1, scratch .word END 	rz scratch lw r1, scratch ib r1 .word END ; 5460

	; --- other ------------------------------------------------------
	.asciiz "NEF  "		lw r0, ?L .word END		lw r0, 0 jls 0 .word END ; 2200

	; --- CPU states -------------------------------------------------
	.asciiz "P4/Bm"		lw r1, r1 .word END		lw r1, r1+r1 .word END
	.asciiz "P4/UA"		awt r1, 1 .word END		awt r1, -1 .word END
	.asciiz "P5   "		lwt r1, 0 lw r1, r1 .word END	lwt r1, 0 lw r1, [r1] .word END
	.asciiz "WX   "		shc r1, 1 .word END		shc r1, 2 .word END
	.asciiz "WA   "		slz r1 .word END		nga r1 .word END
	.asciiz "W&   "		rpc r1 .word END		nga r1 .word END
test_end:

stack:
	.res	16

scratch:
