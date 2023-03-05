	.cpu mera400

; test 64k COMPUTEX memory module

	.include cpu.inc
	.include io.inc

	mcl
	uj	start

	.const	MAGIC1 0b1010101000000000
	.const	MAGIC2 0b0101010100000000

patterns:
	; [pattern, number of positions (with subsequent shifts) to test]
	.word	0b0000000000000000, 1
	.word	0b1111111111111111, 1
	.word	0b1000000000000000, 16
	.word	0b0111111111111111, 16
	.word	0b1010101010101010, 2
patterns_end:

imask:	.word	IMASK_ALL_MEM | 0\SR_NB

; ------------------------------------------------------------------------
mem_int:
	hlt	044
	ujs	mem_int

; ------------------------------------------------------------------------
; r2 - pattern
test:
	.res	1
	lw	r4, mem_start
.wrloop:
	rw	r2, r4
	irb	r4, .wrloop

	lw	r4, mem_start
.rdloop:
	cw	r2, [r4]
	jes	.cont
	hlt	076
.cont:	irb	r4, .rdloop
	je	[test]

; ------------------------------------------------------------------------
; r7 - test vector
test_pat:
	.res	1
	lw	r2, [r7]
	lw	r3, [r7+1]
.loop:
	lj	test
	shc	r2, 1
	awt	r3, -1
	jz	[test_pat]
	ujs	.loop

; ------------------------------------------------------------------------
test_addr:
	.res	1
	lw	r4, mem_start
.wrloop:
	rw	r4, r4
	irb	r4, .wrloop

	lw	r4, mem_start
.rdloop:
	cw	r4, [r4]
	jes	.cont
	hlt	076
.cont:	irb	r4, .rdloop
	je	[test_addr]

; ------------------------------------------------------------------------
unexpected_int:
	hlt	077
	ujs	unexpected_int

; ------------------------------------------------------------------------

	; squeeze as much as possible before the interrupt vector table

	.org	INTV
	.res	32, unexpected_int
	.org	OS_START

; ------------------------------------------------------------------------
conf_all:
	.res	1
	lwt	r2, 2		; starting page number
.next:
	lw	r1, r2
	shc	r1, 4		; move bits to the page number position, segment is always 0

	lw	r3, r2
	shc	r3, 11			; move bits to the frame number position
	nr	r3, 0b0000000011100000	; lower bits - frame number
	lw	r4, r2
	shc	r4, 2			; move bits to the memory module number position
	nr	r4, 0b0000000000000010	; highest bit - memory module number
	aw	r3, r4
	aw	r3, MEM_CFG

	ou	r1, r3
	.word	.no, .en, .ok, .pe
.no:	hlt	010
.en:	hlt	011
.pe:	hlt	012

.ok:
	awt	r2, 1
	cwt	r2, 16
	je	[conf_all]
	ujs	.next

; ------------------------------------------------------------------------
frame_marks:
	.res	1

	lwt	r2, 2	; start frame number
.nxt:
	lw	r3, r2
	shc	r3, 11			; move bits to the frame number position
	nr	r3, 0b0000000011100000  ; lower bits - frame number
	lw	r4, r2
	shc	r4, 2			; move bits to the memory module number position
	nr	r4, 0b0000000000000010	; highest bit - memory module number
	aw	r3, r4

	lw	r1, 2\MEM_PAGE | 0\MEM_SEGMENT	; configure frame always in seg 0 page 2

	ou	r1, r3 + MEM_CFG
	.word	.no, .en, .ok, .pe
.no:	hlt	020
.en:	hlt	021
.pe:	hlt	022

.ok:
	; store the frame marker
	lw	r1, MAGIC1 + r2
	rw	r1, 0x2000
	lw	r1, MAGIC2 + r2
	rw	r1, 0x2001

	awt	r2, 1
	cwt	r2, 16
	je	[frame_marks]

	; "deconfigure" page
	lw	r1, 15\MEM_PAGE | 15\MEM_SEGMENT	; configure frame always in seg 0 page 2
	ou	r1, r3 + MEM_CFG
	.word	.ok2, .ok2, .ok2, .ok2
.ok2:
	ujs	.nxt

; ------------------------------------------------------------------------
test_mapping:
	.res	1

	lwt	r5, 2	; starting page number
	lwt	r6, 0	; starting segment number

	lwt	r2, 2	; starting frame number

.next_page:

	lw	r1, r5
	shc	r1, 4	; enplace page bits
	aw	r1, r6	; enplace segment bits

.next_frame:
	lw	r3, r2
	shc	r3, 11			; move bits to the frame number position
	nr	r3, 0b0000000011100000  ; lower bits - frame number
	lw	r4, r2
	shc	r4, 2			; move bits to the memory module number position
	nr	r4, 0b0000000000000010	; highest bit - memory module number
	aw	r3, r4
	rw	r3, .t3
	ou	r1, r3 + MEM_CFG
	.word	.no, .en, .ok, .pe
.no:	hlt	040
.en:	hlt	041
.pe:	hlt	042

.ok:
	; check frame marker
	rw	r6, .nb
	mb	.nb			; set segment
	lw	r4, r1
	nr	r4, 0b1111000000000000	; set address '0' within the page

	tw	r3, r4
	cw	r3, MAGIC1 + r2
	jn	.fail1
	tw	r3, r4+1
	cw	r3, MAGIC2 + r2
	jn	.fail2

	; "deconfigure" page
	rw	r1, .t1
	lw	r1, 15\MEM_PAGE | 15\MEM_SEGMENT	; configure frame always in seg 0 page 2
	lw	r3, [.t3]
	ou	r1, r3 + MEM_CFG
	.word	.ok2, .ok2, .ok2, .ok2
.ok2:
	lw	r1, [.t1]
	awt	r2, 1
	cwt	r2, 16
	jes	.seg_done
	ujs	.next_frame

.seg_done:
	lwt	r2, 2	; starting frame number
	awt	r5, 1
	cwt	r6, 15	; is this the last segment?
	jes	.last_seg
	cwt	r5, 16	; test the last page
	jes	.next_segment
	uj	.next_page
.last_seg: ; for last segment, don't test last page
	cwt	r5, 15
	jes	.next_segment
	uj	.next_page
.next_segment:
	lwt	r5, 0
	awt	r6, 1
	cwt	r6, 16
	je	.done
	uj	.next_page

.done:
	mb	imask
	uj	[test_mapping]
.fail1:
	hlt	053
.fail2:
	hlt	054
.nb:	.res	1
.t1:	.res	1
.t3:	.res	1

; ------------------------------------------------------------------------
start:
	; prepare interrupt vectors
	lw	r1, mem_start
	rw	r1, STACKP
	lw	r1, mem_int
	rw	r1, INTV_PARITY
	rw	r1, INTV_NOMEM
	im	imask

	; mark all frames
	lj	frame_marks

	; run mapping test
	lj	test_mapping

	; configure all OS memory: 64k, 2 modules 32k each
	lj	conf_all

	; run addressing test
	lj	test_addr

	; run all pattern tests
	lwt	r7, patterns
nx_pat:
	lj	test_pat
done:
	awt	r7, 2
	cwt	r7, patterns_end
	blc	?E
	lwt	r7, patterns
	uj	nx_pat

mem_start:
