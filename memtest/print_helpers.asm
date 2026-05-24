; ------------------------------------------------------------------------
print_module_space:
	.res	1

	shc	r1, 3
	nr	r1, 0b1111
	lj	hex4bit2asc
	shc	r1, 8
	zrb	r1
	or	r1, ' '
	lj	put2c

	uj	[print_module_space]

; ------------------------------------------------------------------------
; print yes/no value
; r1 - boolean to print
print_yesno:
	.res	1
	lw	r1, [.str_bool_tab+r1]
	lj	puts
	uj	[print_yesno]
.str_no:
	.asciiz "NIE"
.str_yes:
	.asciiz "TAK"
.str_bool_tab:
	.word	.str_no, .str_yes

; ------------------------------------------------------------------------
; toggle boolean variable, print it with description
; r1 - description
; r2 - var address (local r7)
bool_toggle_print:
	.res	1
	rws	r7, .r7
	lw	r7, r2

	lj	puts

	lwt	r1, 1
	xm	r1, r7

	lw	r1, [r7]
	lj	print_yesno

	lw	r1, '\r\n'
	lj	put2c

	lws	r7, .r7
	uj	[bool_toggle_print]
.r7:	.res	1
