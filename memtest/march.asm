; ------------------------------------------------------------------------
.struct march_step:
	.num:	.res 1
	.fun:	.res 1
	.read:	.res 1
	.write:	.res 1
	.fail:	.res 1
	.name:	.res 3
.endstruct

	.const	NA 0xa5a5 ; unused march step argument

march_seq:
	.word	1, march_up_w,	NA,	0,	march_up_w.fail		.asciiz "uR-W0"
	.word	2, march_up_rw,	0,	0xffff,	march_up_rw.fail	.asciiz "uR0W1"
	.word	3, march_up_rw,	0xffff,	0,	march_up_rw.fail	.asciiz "uR1W0"
	.word	4, march_dn_rw,	0,	0xffff,	march_dn_rw.fail	.asciiz "dR0W1"
	.word	5, march_dn_rw,	0xffff,	0,	march_dn_rw.fail	.asciiz "dR1W0"
	.word	6, march_up_r,	0,	NA,	march_up_r.fail		.asciiz "uR0W-"
march_seq_end:

; ------------------------------------------------------------------------
; r1 - min addr
; r2 - max addr
; r4 - write value
march_up_w:
	.res	1

	awt	r1, -1
	sw	r1, r2
	awt	r2, 1
.loop:
	pw	r4, r2+r1
.cont:
	irb	r1, .loop
.bail:
	uj	[march_up_w]

; make sure OPRQ does not crash during this step
.fail:
	lj	march_fail_handler
	brc	TEST_CANCELLATION_FLAG
	ujs	.bail
	ujs	.cont

; ------------------------------------------------------------------------
; r1 - min addr
; r2 - max addr
; r3 - expected read
; r4 - write value
march_up_rw:
	.res	1
	rws	r5, .r5

	awt	r1, -1
	sw	r1, r2
	awt	r2, 1
.loop:
	tw	r5, r2+r1
	cw	r3, r5
	jn	.fail
.cont:
	pw	r4, r2+r1
	irb	r1, .loop
.bail:
	lws	r5, .r5
	uj	[march_up_rw]
.r5:	.res	1

.fail:
	lj	march_fail_handler
	brc	TEST_CANCELLATION_FLAG
	ujs	.bail
	ujs	.cont

; ------------------------------------------------------------------------
; r1 - min addr
; r2 - max addr
; r3 - expected read
; r4 - write value
march_dn_rw:
	.res	1
	rws	r5, .r5

	awt	r1, -1
	sw	r2, r1
.loop:
	tw	r5, r1+r2
	cw	r3, r5
	jn	.fail
.cont:
	pw	r4, r1+r2
	drb	r2, .loop
.bail:
	lws	r5, .r5
	uj	[march_dn_rw]
.r5:	.res	1

.fail:
	lj	march_fail_handler
	brc	TEST_CANCELLATION_FLAG
	ujs	.bail
	ujs	.cont

; ------------------------------------------------------------------------
; r1 - min addr
; r2 - max addr
; r3 - expected read
march_up_r:
	.res	1
	rws	r5, .r5

	awt	r1, -1
	sw	r1, r2
	awt	r2, 1
.loop:
	tw	r5, r2+r1
	cw	r3, r5
	jn	.fail
.cont:
	irb	r1, .loop
.bail:
	lws	r5, .r5
	uj	[march_up_r]
.fail:
	lj	march_fail_handler
	brc	TEST_CANCELLATION_FLAG
	ujs	.bail
	ujs	.cont
.r5:	.res	1

