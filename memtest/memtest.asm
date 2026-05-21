	.cpu mera400

	.include cpu.inc
	.include io.inc

	mcl

	rky	r1

	lw	r2, r1
	nr	r2, 1
	rw	r2, once

	lw	r2, r1
	nr	r2, 0b0000000011111110
	rw	r2, term

	lw	r2, r1
	shc	r2, 8
	nr	r2, 0b1111111
	lw	r1, 1
	rw	r1, test_map_standard+r2

	uj	start

imask:	.word	IMASK_PARITY | IMASK_NOMEM | IMASK_GROUP_L
seg1:	.word	0\SR_Q | 1\SR_NB
seg0:	.word	0\SR_Q | 0\SR_NB
term:	.res	1
once:	.res	1
cur_step:
	.res	1
cur_frame:
	.res	1

; ------------------------------------------------------------------------

	.org	INTV
	.res	1, int_unexpected
	.res	1, int_mem_parity
	.res	1, int_mem_segfault
	.res	25, int_unexpected
	.res	1, int_oprq
	.res	3, int_unexpected
	.org	STACKP
	.res	1, stack

	.org	OS_START

; ------------------------------------------------------------------------
int_mem_parity:
	rws	r1, .r1

	md	[STACKP]
	lw	r1, [-SP_R0]
	or	r1, ?1
	md	[STACKP]
	rw	r1, -SP_R0			; set parity error flag

	lw	r1, [cur_step]
	lw	r1, [r1+march_step.fail]	; get current fail handler

	md	[STACKP]
	rw	r1, -SP_IC			; update return address

	lws	r1, .r1
	lip
.r1:	.res	1

; ------------------------------------------------------------------------
; simulate memory error by flipping one bit 20 words ahead
; WARNING: this is flakey, for testing purposes only
int_oprq:
	rws	r3, .r3
	rws	r4, .r4

	lwt	r4, 1

	lw	r3, r1+r2
	aw	r3, 20
	nr	r3, 0x0fff
	xm	r4, r3

	lws	r3, .r3
	lws	r4, .r4
	lip
.r3:	.res	1
.r4:	.res	1

; ------------------------------------------------------------------------
int_mem_segfault:
	hlt	045

; ------------------------------------------------------------------------
int_unexpected:
	hlt	046

; ------------------------------------------------------------------------
; busy character print
; r1 - character to print
putc:
	.res	1

.retry:
	md	[term]
	ou	r1, KZ_CMD_DEV_WRITE
	.word	.ok, .en, .ok, .ok
.en:	ujs	.retry
.ok:	uj	[putc]

; ------------------------------------------------------------------------
; busy character read
; RETURN: r1 - character read
getc:
	.res	1

.retry:
	md	[term]
	in	r1, KZ_CMD_DEV_READ
	.word	.ok, .en, .ok, .ok
.en:	ujs	.retry
.ok:	uj	[getc]

; ------------------------------------------------------------------------
; r1 - 2-char to print
put2c:
	.res	1

	shc	r1, 8
	lj	putc
	shc	r1, 8
	lj	putc

	uj	[put2c]

; ------------------------------------------------------------------------
; Print 0-terminated string
; r1 - address of a 0-terminated string to print
puts:
	.res	1
	rws	r5, .r5

	lw	r5, r1+r1 ; string address

.loop:
	lb	r1, r5
	zlb	r1
	cwt	r1, '\0'
	jes	.done

	lj	putc

	awt	r5, 1
	ujs	.loop

.done:
	lws	r5, .r5
	uj	[puts]

.r5:	.res	1

; ------------------------------------------------------------------------
; Convert number to a hex ascii representation
;
; r1 - value
; r2 - buffer address
hex2asc:
	.res	1

	slz	r2
	lwt	r4, 4 ; 4 digits
.loop:
	shc	r1, -4 ; shift quad into position
	lw	r3, r1
	nr	r3, 0xf
	cwt	r3, 9
	blc	?G
	awt	r3, 'a'-'0'-10
	awt	r3, '0'
	rb	r3, r2

	awt	r2, 1
	drb	r4, .loop
	lwt	r3, 0
	rb	r3, r2

	uj	[hex2asc]

; ------------------------------------------------------------------------
; r1 - 4bit value
; RETURN r1 - 0-f ASCII char
hex4bit2asc:
	.res	1

	cwt	r1, 9
	blc	?G
	awt	r1, 'a'-'0'-10
	awt	r1, '0'

	uj	[hex4bit2asc]

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

	uj	[march_up_w]

; not used, just for consistency and so that OPRQ does not crash the test
.fail:
	lj	handle_fail
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

	lws	r5, .r5
	uj	[march_up_rw]
.r5:	.res	1

.fail:
	lj	handle_fail
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

	lws	r5, .r5
	uj	[march_dn_rw]
.r5:	.res	1

.fail:
	lj	handle_fail
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

	lws	r5, .r5
	uj	[march_up_r]
.fail:
	lj	handle_fail
	ujs	.cont
.r5:	.res	1

; ------------------------------------------------------------------------
handle_fail:
	.res	1
	ra	.regs
	mb	seg0

	; test status:
	;  * cur_step - current MARCH step
	;  * cur_frame - currently tested frame
	;  * r2+r1 - current address
	;  * r5 - value read
	;  * r3 - expected read

	lw	r7, r2+r1	; current address

	; print MARCH step
	lw	r1, [cur_step]
	aw	r1, march_step.name
	lj	puts

	; space
	lw	r1, ' '
	lj	putc

	; print module + space
	lw	r1, [cur_frame]
	shc	r1, 3
	nr	r1, 0b1111
	lj	hex4bit2asc
	shc	r1, 8
	zrb	r1
	or	r1, ' '
	lj	put2c

	; print frame + space
	lw	r1, [cur_frame]
	nr	r1, 0b111
	lj	hex4bit2asc
	shc	r1, 8
	zrb	r1
	or	r1, ' '
	lj	put2c

	; print address
	lw	r1, r7
	lw	r2, tmp
	lj	hex2asc
	lw	r1, tmp
	lj	puts

	; space
	lw	r1, ' '
	lj	putc

	; print read value
	lw	r1, r5
	lw	r2, tmp
	lj	hex2asc
	lw	r1, tmp
	lj	puts

	; print parity error indicator
	bb	r0, ?1
	ujs	.newline
	lw	r1, ' P'
	lj	put2c
	er	r0, ?1

.newline:
	; line end
	lw	r1, '\n\r'
	lj	put2c

	mb	seg1
	la	.regs
	uj	[handle_fail]
.regs:	.res	7

; ------------------------------------------------------------------------
; r1 - sequential module and frame number (0b000000000mmmmfff)
; r2 - segment/page as for OU instruction
configure_frame:
	.res	1

	lw	r3, r1
	nr	r3, 0b111	; mask everything except frame number in r3
	shc	r3, -5		; enplace frame number in r3
	shc	r1, 2		; enplace module number in r1
	nr	r1, 0b11110	; mask everything but module in r1
	or	r3, r1		; r3 - final module/frame for OU (0b00000000fffmmmm0)

	ou	r2, r3 + MEM_CFG
	.word	.no, .en, .ok, .pe
.no:	hlt	010
.en:	hlt	011
.pe:	hlt	012
.ok:
	uj	[configure_frame]

; ------------------------------------------------------------------------
; r1 - march step pointer (local r7)
; r2 - frame test map pointer (local r6)
step_all_frames:
	.res	1
	rws	r7, .r7
	lw	r7, r1
	lw	r6, r2

	lwt	r5, 0	; current module and frame 0b000000000mmmmfff

.loop_frame:
	lw	r1, [r6+r5]
	cwt	r1, 0
	jes	.next_frame

	; configure frame
	lw	r1, r5
	lw	r2, 1\MEM_SEGMENT | 0\MEM_PAGE
	lj	configure_frame

	rw	r5, cur_frame

	; run march step over currently configured frame
	mb	seg1
	lw	r1, 0x0000
	lw	r2, 0x0fff
	lw	r3, [r7+march_step.read]
	lw	r4, [r7+march_step.write]
	lj	[r7+march_step.fun]
	mb	seg0

	; deconfigure frame
	lw	r1, r5
	lw	r2, 15\MEM_SEGMENT | 15\MEM_PAGE
	lj	configure_frame

.next_frame:
	awt	r5, 1
	cw	r5, 0b1111111
	jgs	.done
	ujs	.loop_frame

.done:
	lws	r7, .r7
	uj	[step_all_frames]

.r7:	.res 1

; ------------------------------------------------------------------------
.struct march_step:
	.fun:	.res 1
	.read:	.res 1
	.write:	.res 1
	.fail:	.res 1
	.name:	.res 3
.endstruct

	.const	NA 0xa5a5 ; unused march step argument

march_seq:
	.word	march_up_w,	NA,	0,	march_up_w.fail		.asciiz "uR-W0"
	.word	march_up_rw,	0,	0xffff,	march_up_rw.fail	.asciiz "uR0W1"
	.word	march_up_rw,	0xffff,	0,	march_up_rw.fail	.asciiz "uR1W0"
	.word	march_dn_rw,	0,	0xffff,	march_dn_rw.fail	.asciiz "dR0W1"
	.word	march_dn_rw,	0xffff,	0,	march_dn_rw.fail	.asciiz "dR1W0"
	.word	march_up_r,	0,	NA,	march_up_r.fail		.asciiz "uR0W-"
march_seq_end:

; ------------------------------------------------------------------------
march_run:
	.res	1
	rws	r7, .r7

	lw	r7, march_seq

.loop_march:
	; run current march step over all frames
	lw	r1, r7
	rw	r7, cur_step
	lw	r2, test_map_standard
	lj	step_all_frames

	awt	r7, march_step
	cw	r7, march_seq_end
	jn	.loop_march

	lws	r7, .r7
	uj	[march_run]

.r7:	.res 1

; ------------------------------------------------------------------------
test_map_standard:
	.res	16*8, 0		; 16 modules, 8 frames each (3-bit frame address, 32KW modules)
test_map_standard_end:

test_map_mega:
	.res	16*16, 0	; 16 modules, 16 frames each (4-bit frame address, 64KW modules)
test_map_mega_end:

; ------------------------------------------------------------------------
; --- MAIN ---------------------------------------------------------------
; ------------------------------------------------------------------------
start:
	im	imask

	lw	r1, .greet
	lj	puts

.loop:
	lj	march_run
	lw	r1, [once]
	bc	r1, 1
	hlt
	ujs	.loop

.greet:
	.asciiz	" Test pamieci MARCH C-\n\r"

; ------------------------------------------------------------------------
stack:
	.res	4
tmp:
	.res	5
memtest_lowest_addr:

