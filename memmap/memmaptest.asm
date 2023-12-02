	.cpu	mera400
	.include	cpu.inc
	uj	start


	.org	OS_START

; ------------------------------------------------------------------------
; r1 - segment
; r2 - page
; r3 - module
; r4 - frame
mem_cfg:
	.res	1

	slz	r3	; module in place
	or	r3, 1	; memory configuration in place
	shc	r4, -5	; frame in place
	or	r3, r4	; frame/module in r3

	shc	r2, -12	; page in place
	or	r2, r1	; page/segment in r2

	lwt	r1, 0	; return: OK
.retry:
	ou	r2, r3
	.word	.no, .en, .ok, .pe
.no:	lwt	r1, 1	; return: no answer
	ujs	.fin
.en:	ujs	.retry	; should not happen?
.pe:	lwt	r1, 2	; return: partity error (should not happen)
.ok:

.fin:
	uj	[mem_cfg]

; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
; ------------------------------------------------------------------------
start:
	mcl
	lj	mem_cfg
	hlt
