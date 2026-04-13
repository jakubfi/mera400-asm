
	.equ	CMD_WRITE 0b11000\4
	.equ	CMD_READ 0b10100\4

	mcl

	; read full UZDAT address from binary keys into r7:
	;  * bits 8..10 - device address
	;  * bits 11..14 - channel address
	rky	r7

; ------------------------------------------------------------------------
; --- memory configuration -----------------------------------------------
; ------------------------------------------------------------------------

	; r1: current page
	lwt	r1, 2
memcfg:
	; r2: logical address (segment is always 0)
	lw	r2, r1
	shc	r2, 4
	; r3: physical address (memory module is always 0, 1:1 page:frame mapping)
	lw	r3, r1
	shc	r3, 11
	; configure page
	ou	r2, r3 + 1
	.word	.err, .err, .ok, .err
.err:
	; treat anything unusual as an error
	hlt	1
.ok:
	; next page
	awt	r1, 1
	cwt	r1, 8
	jls	memcfg

; ------------------------------------------------------------------------
; --- UZDAT 'reset' ------------------------------------------------------
; ------------------------------------------------------------------------

reset:
	in	r1, CMD_READ + r7
	.word	dump, dump, dump, dump

; ------------------------------------------------------------------------
; --- memory dump --------------------------------------------------------
; ------------------------------------------------------------------------

dump:
	; r1: current memory address
	lwt	r1, 0

.word_loop:
	; r3: word to transfer
	lw	r3, [r1]
	; r4: nibble counter
	lwt	r4, 4

.nibble_loop:
	; r5: nibble to send
	lw	r5, r3
	nr	r5, 0xf
.io_retry:
	ou	r5, CMD_WRITE + r7
	.word	.err, .en, .ok, .err
.err:	hlt	2
.en:	ujs	.io_retry
.ok:
	; next nibble
	shc	r3, 4
	drb	r4, .nibble_loop

	; next word
	awt	r1, 1
	jvs	.fin
	ujs	.word_loop
.fin:
	; all done
	hlt	0

