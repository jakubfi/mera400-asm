; ------------------------------------------------------------------------
; Get a reasonably random 32-bit number.
; It is obtained by interrupting a tight loop with the timer interrupt,
; each time storing two least significant bits of the return address
; RETURN: [r1, r2] - 32-bit random number
tmrandom:
	.res	1
	im	.im_0
	lwt	r4, -16
	lw	r1, [INTV_TIMER]
	rw	r1, .otimv
	lw	r1, [STACKP]
	rw	r1, .ostck
	lw	r1, prngtimer
	rw	r1, INTV_TIMER
	lw	r1, .stack
	rw	r1, STACKP
	im	.im_tm

.l1:	nop
.l2:	nop
.l3:	nop
.l4:	nop
.l5:	nop
.l6:	nop
.l7:	nop
.l8:	ujs	.l1

.fin:
	im	.im_0
	lw	r4, [.otimv]
	rw	r4, INTV_TIMER
	lw	r4, .ostck
	rw	r4, STACKP
	uj	[tmrandom]
.im_tm:	.word	IMASK_GROUP_H
.im_0:	.word	0
.otimv:	.res	1
.ostck:	.res	1
.stack:	.res	2*4

; ------------------------------------------------------------------------
; Extract random bit from interrupted program address
prngtimer:
	md	[STACKP]
	lw	r3, [-SP_IC]
	srz	r3
	sly	r1

	irb	r4, .cont
	lw	r3, tmrandom.fin
	md	[STACKP]
	rw	r3, -SP_IC
.cont:
	lip


; ------------------------------------------------------------------------
; Unsigned multiply
; r1 - multipier address
; r2 - multiplicand
; return: [r1, r2] = r2 * [r1]
umul:
	lw	r3, [r1]
	sxl	r3
	srz	r3
	rw	r3, r1
	lw	r3, r2
	mw	r1
	slz	r2
	sly	r1
	jxs	.do_fix
	uj	r4
.do_fix:
	aw	r2, r3
	ac	r1, 0
	uj	r4

; ------------------------------------------------------------------------
; Park-Miller-Carta pseudo-random number generator implementation for MERA-400
;
; RETURN: [r1, r2] - random 31-bit number
urand:	.res	1

	; lo = cpmc * (seed & 0xFFFF)
	lw	r2, .cpmc
	;lw	r1, .seed+1
	;rj	r4, umul
	mw	.seed+1
	rd	.lo

	; hi = cpmc * (seed >> 16)
	lw	r2, .cpmc
	;lw	r1, .seed
	;rj	r4, umul
	mw	.seed
	rd	.hi

	; lo += (hi & 0x7FFF) << 16
	lw	r1, [.hi+1]
	nr	r1, 0x7fff
	lwt	r2, 0
	ad	.lo
	rd	.lo

	; lo += hi >> 15
	lwt	r1, 0
	lw	r2, [.hi]
	lw	r3, [.hi+1]
	slz	r3
	sly	r2
	sly	r1
	ad	.lo

	; if (lo > 0x7FFFFFFF) lo -= 0x7FFFFFFF;
	cl	r1, 0x8000
	jls	.done
	sd	.fix
.done:
	; seed = lo
	rd	.seed

	uj	[urand]

	.const	.cpmc 16807
.seed:	.dword	1
.fix:	.dword	0x7fffffff
.lo:	.res	2
.hi:	.res	2

; ------------------------------------------------------------------------
; Seed the PRNG
;
; in: [r1, r2] - seed
seed:	.res	1
	rd	urand.seed
	uj	[seed]

; ------------------------------------------------------------------------
; Fill buffer with random data
;
; r1 - buffer address
; r2 - words to fill
rndfill:
	.res	1

	rl	.regs

	cwt	r2, 0
	jes	.done

	lw	r5, r1
	lw	r6, r2
.loop:
	lj	urand
	rw	r1, r5
	awt	r5, 1
	awt	r6, -1
	jz	.done
	rw	r2, r5
	awt	r5, 1
	awt	r6, -1
	jz	.done
	ujs	.loop
.done:
	ll	.regs
	uj	[rndfill]
.regs:	.res	3

; vim: tabstop=8 shiftwidth=8 autoindent syntax=emas
