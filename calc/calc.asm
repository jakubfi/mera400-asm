	.cpu mera400
	.include cpu.inc

	rl	data		; store second argument

	rky	r4		; read keys: bit 13: 0=dword, 1=float, bits 14-15 op
	cw	r4, 7		; >7 => error
	jg	err

	md	r4		; store the operation
	ll	ops+r4
	rw	r5, op
	rw	r6, op+1

op:	.res	2

done:	hlt
	ujs	done

err:	lw	r1, [-1]
	hlt
	ujs	err

ops:	ad	data
	sd	data
	mw	data
	dw	data
	af	data
	sf	data
	mf	data
	df	data
data:
