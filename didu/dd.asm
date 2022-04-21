
	.cpu	mera400

	.include cpu.inc
	.include io.inc

	uj	start

imask:	.word	IMASK_ALL & ~(IMASK_CPU_H | IMASK_GROUP_L)

dummy:	hlt	045
	ujs	dummy

stack:	.res	11*4, 0x0ded

	.org	INTV
	.res	32, dummy
	.org	EXLV
	.word	dummy
	.org	STACKP
	.word	stack
	.org	OS_START

	.include kz.asm
	.include stdio.asm
	.include crc.asm

; ------------------------------------------------------------------------

	.const	CH	15
	.const	PC	CH\IO_CHAN | 0\IO_DEV
	.const	FLOP	CH\IO_CHAN | 2\IO_DEV

; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------

	.const	SECT_LEN	128		; bytes
	.const	CMD_LEN		2		; words
	.const	RESP_LEN	1		; words
	.const	DATA_LEN	SECT_LEN/2	; words

	.const	CMD_FIRST	CMD_RESET
	.const	CMD_RESET	1
	.const	CMD_SEEK_RD	2
	.const	CMD_READ	3
	.const	CMD_LAST	CMD_READ

; incomming command
cmd:	.res	1
addr:	.res	1
cmd_crc:.res	1

; outgoing response
resp:	.res	1
resp_crc:
	.res	1

; outgoing data
data:	.res	DATA_LEN
data_crc:
	.res	1

data_ready:
	.res	1

cmd_map:
	.word	0, cmd_do_reset, cmd_do_seek_rd, cmd_do_read

	.const	RESP_UNKNOWN	0
	.const	RESP_OK		1
	.const	RESP_BAD_CMD	2
	.const	RESP_BAD_CRC	3
	.const	RESP_IOERR	4

; ------------------------------------------------------------------------
start:
	; initialize KZ

	lw	r1, CH
	lj	kz_init

	im	imask

.loop:
	rz	data_ready
	rz	resp

	lj	cmd_read	; read (command, address, crc) from PC
	ujs	.send_response	; returns here if error
				; returns here if OK to continue
	md	[cmd]
	lj	[cmd_map]	; run command procedure
	
.send_response:

	lj	send_response	; always send response

	lwt	r1, 0		; is data available?
	cw	r1, [data_ready]
	jes	.loop		; no, loop over

	lj	send_data	; send data if available

	ujs	.loop
	ujs	.loop

; ------------------------------------------------------------------------
; Read the command from PC, check CRC, check if the command is known
cmd_read:
	.res	1
	lw	r1, cmd
	lw	r2, PC
	lwt	r3, CMD_LEN+1
	lj	readw

	lw	r1, cmd
	lwt	r2, CMD_LEN<<1
	lj	crc16

	cw	r1, [cmd_crc]
	jes	.crc_ok
.bad_crc:
	lwt	r1, RESP_BAD_CRC
	rw	r1, resp
	uj	[cmd_read]	; return to call_addr if error
.crc_ok:
	lw	r1, [cmd]
	cw	r1, CMD_FIRST
	jls	.bad_cmd
	lw	r1, [cmd]
	cw	r1, CMD_LAST
	jgs	.bad_cmd
.all_ok:
	md	[cmd_read]
	uj	1		; return to call_addr+1 if OK
.bad_cmd:
	lwt	r1, RESP_BAD_CMD
	rw	r1, resp
	uj	[cmd_read]	; return to call_addr if error

; ------------------------------------------------------------------------
cmd_do_reset:
	.res	1

        lw      r2, FLOP
        lj      kz_reset

	lwt	r1, RESP_OK
	rw	r1, resp
	uj	[cmd_do_reset]

; ------------------------------------------------------------------------
cmd_do_seek_rd:
	.res	1

        lw      r2, FLOP
        lj      kz_detach

	lw	r1, [addr]
        lw      r2, FLOP
        lj      kz_seek

	lwt	r1, RESP_OK
	rw	r1, resp
	uj	[cmd_do_seek_rd]

; ------------------------------------------------------------------------
cmd_do_read:
	.res	1
	; read data from disk

	lw	r1, data
	lw	r2, FLOP
	lw	r3, SECT_LEN
	lj	read

	cw	r1, 0
	jls	.io_error

	lw	r1, 1
	rw	r1, data_ready
	lw	r1, RESP_OK
	rw	r1, resp
	ujs	.end

.io_error:
	lw	r1, [kz_last_intspec]
	shc	r1, 8
	zrb	r1
	or	r1, RESP_IOERR
	rw	r1, resp
.end:
	uj	[cmd_do_read]

; ------------------------------------------------------------------------
send_response:
	.res	1

	; calculate crc for response
	lw	r1, resp
	lwt	r2, RESP_LEN<<1
	lj	crc16
	rw	r1, resp_crc

	; send response and crc
	lw	r1, resp
	lw	r2, PC
	lw	r3, RESP_LEN+1
	lj	writew

	uj	[send_response]

; ------------------------------------------------------------------------
send_data:
	.res	1

	; calculate crc for data
	lw	r1, data
	lw	r2, SECT_LEN
	lj	crc16
	rw	r1, data_crc

	; send data and crc
	lw	r1, data
	lw	r2, PC
	lw	r3, DATA_LEN + 1
	lj	writew

	uj	[send_data]

