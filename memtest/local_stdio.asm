; NOTE: local stdio library functions to reduce memory footprint

term:	.res	1

; ------------------------------------------------------------------------
; busy character print
; r1 - character to print
putc:
	.res	1

	lw	r2, [term]
.retry:
	ou	r1, KZ_CMD_DEV_WRITE+r2
	.word	.no, .retry, .ok, .ok
.no:	hlt	020

.ok:	uj	[putc]

; ------------------------------------------------------------------------
; character read
; RETURN: r1 - character read or -1 if none read
getc_nonblocking:
	.res	1

	md	[term]
	in	r1, KZ_CMD_DEV_READ
	.word	.no, .en, .ok, .ok
.no:
.en:	lwt	r1, -1
.ok:	uj	[getc_nonblocking]

; ------------------------------------------------------------------------
; busy character read
; RETURN: r1 - character read
getc:
	.res	1

	lw	r2, [term]
.retry:
	in	r1, KZ_CMD_DEV_READ+r2
	.word	.no, .retry, .ok, .ok
.no:	hlt	021

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

	lw	r5, r1+r1	; word->byte string addr

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
; r1 - value
; r2 - buffer address
hex2asc:
	.res	1
	rws	r5, .r5

	slz	r2	; word->byte addr
	lwt	r5, 4	; 4 digits
.loop:
	shc	r1, -4	; shift quad into position
	lw	r3, r1
	nr	r3, 0xf
	cwt	r3, 9
	blc	?G
	awt	r3, 'a'-'0'-10
	awt	r3, '0'
	rb	r3, r2

	awt	r2, 1
	drb	r5, .loop
	lwt	r3, 0
	rb	r3, r2

	lws	r5, .r5
	uj	[hex2asc]
.r5:	.res	1

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
; Reat 4-bit value. Values >0xf are silently truncated to 4 bits
; RETURN: r1 - 4-bit value
read_4bit_hex:
	.res	1

	lj	getc
	cw	r1, '9'
	blc	?G
	awt	r1, -('a'-'0'-10)
	awt	r1, -'0'
	nr	r1, 0b1111

	uj	[read_4bit_hex]

; ------------------------------------------------------------------------
; RETURN: r1 - 8-bit value
read_8bit_hex:
	.res	1
	rws	r5, .r5

	lj	read_4bit_hex
	lw	r5, r1
	shc	r5, -4

	lj	read_4bit_hex
	or	r1, r5

	lws	r5, .r5
	uj	[read_8bit_hex]
.r5:	.res	1
