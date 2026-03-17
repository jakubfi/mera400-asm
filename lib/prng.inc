; ------------------------------------------------------------------------
; Get a reasonably random 32-bit number.
; It is obtained by interrupting a tight loop with the timer interrupt,
; each time storing two least significant bits of the return address
; RETURN: [r1, r2] - 32-bit random number
tmrandom:
	.res	1
	im	.im_0
	lwt	r4, -32
	lw	r1, [INTV_TIMER]
	rw	r1, .otimv
	lw	r1, [STACKP]
	rw	r1, .ostck
	lw	r1, .prngtimer
	rw	r1, INTV_TIMER
	lw	r1, .stack
	rw	r1, STACKP
	im	.im_tm
.loop:
	nop
	nop
	nop
	nop
	nop
	cwt	r4, -1
	jgs	.fin
	ujs	.loop
.fin:
	im	.im_0
	lw	r4, [.otimv]
	rw	r4, INTV_TIMER
	lw	r4, .ostck
	rw	r4, STACKP
	uj	[tmrandom]

; ------------------------------------------------------------------------
; Extract random bits from interrupted program address
.prngtimer:
	md	[STACKP]
	lw	r3, [-SP_IC]

	srz	r3
	sly	r1
	srz	r3
	sly	r1

	cwt	r4, -16
	blc	?E
	lw	r2, r1
	awt	r4, 2

	lip

.im_tm:	.word	IMASK_GROUP_H
.im_0:	.word	0
.otimv:	.res	1
.ostck:	.res	1
.stack:	.res	2*4

; ------------------------------------------------------------------------
; Park-Miller-Carta pseudo-random number generator implementation for MERA-400
;
; RETURN: [r1, r2] - random 31-bit number
urand:	.res	1
	lw	r1, [.seed+1]
	sxu	r1		; set X if low seed is negative

	; lo = cpmc * (seed & 0xFFFF)
	lw	r2, .cpmc
	mw	.seed+1
	; correct for signed multiply if low seed was negative
	brc	?X
	ad	.ufix
	rd	.lo

	; hi = cpmc * (seed >> 16)
	lw	r2, .cpmc
	mw	.seed
	rd	.hi

	; lo += (hi & 0x7FFF) << 16
	lw	r1, [.hi+1]
	nr	r1, 0x7fff
	lwt	r2, 0
	ad	.lo
	rd	.lo

	; lo += hi >> 15
	lw	r2, [.hi]
	lw	r1, [.hi+1]	; r1 just for temporary use here
	slz	r1		; just to set Y to .hi+1's MSB
	sly	r2
	lwt	r1, 0
	sly	r1
	ad	.lo

	; if (lo > 0x7FFFFFFF) lo -= 0x7FFFFFFF
	blc	?M
	sd	.fix
.done:
	; seed = lo
	rd	.seed
	uj	[urand]

	.const	.cpmc 16807
.seed:	.dword	1
.fix:	.dword	0x7fffffff
.ufix:	.dword	0x10000 * .cpmc
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
