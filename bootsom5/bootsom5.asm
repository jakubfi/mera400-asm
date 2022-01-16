
	.cpu	mera400

	.include cpu.inc
	.include io.inc

; configure memory pages 2-7 in segment 0

memcfg:
	lw	r1, 2\MEM_PAGE
	lw	r2, 2\MEM_FRAME

.loop:
	ou	r1, r2 + MEM_CFG
	.word	.no, .en, .ok, .pe
.no:
.en:
.pe:	hlt	001
.ok:	aw	r1, 1\MEM_PAGE
	aw	r2, 1\MEM_FRAME
	cl	r1, 8\MEM_PAGE
	jes	memclr
	ujs	.loop

; clear memory contents

memclr:
	lw	r1, 0x8000-clr_start
.loop:
	rz	r1+clr_start-1
	drb	r1, .loop

; bootstrap

	rky	r1		; device address
	lw	r6, 0x6000<<1	; load address (byte)
	lw	r7, iseq	; sector sequence start
	lw	r5, 2		; starting track

; position the heads

detach:
	ou	r1, KZ_CMD_DEV_DETACH + r1
	.word	.no, detach, .ok, .pe
.no:
.pe:	hlt	002
.ok:

seek:
	lw	r2, r5
	shc	r2, -5		; shift track number into position
	or	r2, [r7]	; overlay sector number from the sequence
.en:
	; 0b00_0_0_ttttttt_sssss
	ou	r2, KZ_CMD_CTL4 + r1
	.word	.no, .en, .ok, .pe
.no:
.pe:	hlt	003

	.org	INTV
	.org	OS_START

.ok:

; read the data

	lw	r3, 128
read:
	in	r2, KZ_CMD_DEV_READ + r1
	.word	.no, read, .ok, .pe
.no:
.pe:	hlt	004
.ok:
	rb	r2, r6
	awt	r6, 1
	drb	r3, read

; next sector

next:
	awt	r7, 1		; next sector
	cl	r7, iseq_e	; last sector?
	jn	detach		; no - again
	lw	r7, iseq	; yes - start from 1...
	awt	r5, 1		; ...on the next track
	cwt	r5, 6		; last track?
	jes	done		; yes - done
	uj	detach		; no - again

done:
	hlt	000
	uj	0x600d		; start the system

iseq:	.word	1, 7, 13, 19, 25, 5, 11, 17, 23, 3,  9, 15, 21
	.word	2, 8, 14, 20, 26, 6, 12, 18, 24, 4, 10, 16, 22
iseq_e:

; start of memory region to clear
clr_start:
