	lwt	r2, 8
	rw	r2, 16
	uj	loop
	.org	0400
loop:   LW	r1, [8+r2]
        UJS	loop
