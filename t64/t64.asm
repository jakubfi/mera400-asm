	.cpu mera400

; test <= 64K system memory (Elwro or Computex):

	.include cpu.inc
	.include io.inc

	.const	MAGIC1 0b1010101000000000
	.const	MAGIC2 0b0101010100000000

	mcl

	; read from keys and store the number of memory pages to test (>=3 needed)
	rky	r1
	cwt	r1, 3
	jls	bad_page_cnt
	rw	r1, page_cnt
	; calculate and store last memory test address
	shc	r1, -12
	awt	r1, -1
	rw	r1, mem_test_end_addr

	uj	start

bad_page_cnt:
	hlt	1

imask:	.word	IMASK_PARITY | IMASK_NOMEM | 0\SR_NB
page_cnt:
	.res	1
mem_test_end_addr:
	.res	1

; ------------------------------------------------------------------------
int_mem_parity:
	hlt	044
int_mem_segfault:
	hlt	045
int_unexpected:
	hlt	046

; ------------------------------------------------------------------------
test_addr:
	.res	1
	lw	r4, mem_test_start_addr
.wrloop:
	rw	r4, r4
	cl	r4, [mem_test_end_addr]
	jes	.do_reads
	awt	r4, 1
	ujs	.wrloop

.do_reads:
	lw	r4, mem_test_start_addr
.rdloop:
	cw	r4, [r4]
	jes	.cont
	hlt	076
.cont:	cl	r4, [mem_test_end_addr]
	je	[test_addr]
	awt	r4, 1
	ujs	.rdloop

; ------------------------------------------------------------------------
march_seq:
	.word	march_up_w0
	.word	march_up_r0_w1
	.word	march_up_r1_w0
	.word	march_dn_r0_w1
	.word	march_dn_r1_w0
	.word	march_up_r0
march_seq_end:

; ------------------------------------------------------------------------
; uses: r7
test_march:
	.res	1
	lw	r7, march_seq
.loop:
	lj	[r7]
	awt	r7, 1
	cw	r7, march_seq_end
	jn	.loop
	uj	[test_march]

; ------------------------------------------------------------------------
fail:
	hlt	077

; ------------------------------------------------------------------------

	.org	INTV
	.res	1, int_unexpected
	.res	1, int_mem_parity
	.res	1, int_mem_segfault
	.res	29, int_unexpected
	.org	STACKP
	.res	1, mem_test_start_addr ; don't care if stack overwrites test area (test failed anyway)

	.org	OS_START

; ------------------------------------------------------------------------
conf_all:
	.res	1
	lwt	r2, 2			; starting page number
.next:
	lw	r1, r2
	shc	r1, -12			; move bits to the page number position, segment is always 0

	lw	r3, r2
	shc	r3, -5			; move bits to the frame number position
	nr	r3, 0b0000000011100000	; lower bits - frame number
	lw	r4, r2
	shc	r4, 2			; move bits to the memory module number position
	nr	r4, 0b0000000000000010	; highest bit - memory module number
	aw	r3, r4

	ou	r1, r3 + MEM_CFG
	.word	.no, .en, .ok, .pe
.no:	hlt	010
.en:	hlt	011
.pe:	hlt	012
.ok:
	awt	r2, 1
	cw	r2, [page_cnt]
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
	cw	r2, [page_cnt]
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
	cw	r2, [page_cnt]
	jes	.seg_done
	ujs	.next_frame

.seg_done:
	lwt	r2, 2	; starting frame number
	awt	r5, 1
	md	[page_cnt]
	cwt	r6, -1	; is this the last segment?
	jes	.last_seg
	cw	r5, [page_cnt]	; test the last page
	jes	.next_segment
	uj	.next_page
.last_seg: ; for last segment, don't test last page
	md	[page_cnt]
	cwt	r5, -1
	jes	.next_segment
	uj	.next_page
.next_segment:
	lwt	r5, 0
	awt	r6, 1
	cw	r6, [page_cnt]
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
march_up_w0:
	.res	1

	lw	r1, mem_test_start_addr-1
	lw	r4, [mem_test_end_addr]
	sw	r1, r4
	awt	r4, 1
	lwt	r2, 0
.loop:
	rz	r4+r1
	irb	r1, .loop

	uj	[march_up_w0]

; ------------------------------------------------------------------------
march_up_rw:
	.res	1

	lw	r1, mem_test_start_addr-1
	lw	r4, [mem_test_end_addr]
	sw	r1, r4
	awt	r4, 1
.loop:
	cw	r2, [r4+r1]
	jn	fail
	rw	r3, r4+r1
	irb	r1, .loop

	uj	[march_up_rw]

; ------------------------------------------------------------------------
march_up_r0_w1:
	.res	1

	lwt	r2, 0
	lwt	r3, -1
	lj	march_up_rw

	uj	[march_up_r0_w1]

; ------------------------------------------------------------------------
march_up_r1_w0:
	.res	1

	lwt	r2, -1
	lwt	r3, 0
	lj	march_up_rw

	uj	[march_up_r1_w0]

; ------------------------------------------------------------------------
march_dn_rw:
	.res	1

	lw	r4, mem_test_start_addr-1
	lw	r1, [mem_test_end_addr]
	sw	r1, r4
.loop:
	cw	r2, [r4+r1]
	jn	fail
	rw	r3, r4+r1
	drb	r1, .loop

	uj	[march_dn_rw]

; ------------------------------------------------------------------------
march_dn_r0_w1:
	.res	1

	lwt	r2, 0
	lwt	r3, -1
	lj	march_dn_rw

	uj	[march_dn_r0_w1]

; ------------------------------------------------------------------------
march_dn_r1_w0:
	.res	1

	lwt	r2, -1
	lwt	r3, 0
	lj	march_dn_rw

	uj	[march_dn_r1_w0]

; ------------------------------------------------------------------------
march_up_r0:
	.res	1

	lw	r1, mem_test_start_addr-1
	lw	r4, [mem_test_end_addr]
	sw	r1, r4
	awt	r4, 1
	lwt	r2, 0
.loop:
	cw	r2, [r4+r1]
	jn	fail
	irb	r1, .loop

	uj	[march_up_r0]

; ------------------------------------------------------------------------
; --- MAIN ---------------------------------------------------------------
; ------------------------------------------------------------------------
start:
	im	imask

	lj	frame_marks	; mark all frames
	lj	test_mapping	; run mapping test
	lj	conf_all	; configure all pages into OS memory segment
	lj	test_addr	; run addressing test
.loop:
	lj	test_march	; run MARCH C- test in an infinite loop
	ujs	.loop

mem_test_start_addr:
