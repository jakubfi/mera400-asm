	.cpu mera400

	.include cpu.inc
	.include io.inc
	.include mega.inc

	.const	OPRQ_SIMULATED_ERROR_OFFSET 20
	.const	NUM_MODULES 16
	.const	NUM_FRAMES_STD 8
	.const	NUM_FRAMES_MEGA 16
	.const	MAGIC 0b_10101010_00110011
	.const	PARITY_FLAG ?1
	.const	SEGFAULT_FLAG ?2
	.const	TEST_CANCELLATION_FLAG ?7
	.const	ESC 27
	.const	BIT_LCASE 0b100000
	.const	KEYS_TERM_ADDR 0b_00000000_11111110
	.const	KEYS_MEGA 0b_00000000_00000001
	.const	KEYS_MOD_CNT 0b_00011111_00000000
	.const	KEYS_MOD_CNT_SHIFT 8

	mcl
	rky	r1

	; get terminal address
	lw	r2, r1
	nr	r2, KEYS_TERM_ADDR
	rw	r2, term

	; get MEGA test indicator
	lw	r2, r1
	nr	r2, KEYS_MEGA
	rw	r2, keys_mega

	; get count of modules to test
	lw	r2, r1
	nr	r2, KEYS_MOD_CNT
	shc	r2, KEYS_MOD_CNT_SHIFT
	rw	r2, keys_module_cnt

	uj	start

imask_zero:
	.word	0
imask_test:
	.word	IMASK_PARITY | IMASK_NOMEM | IMASK_GROUP_L
imask_mapping:
	.word	IMASK_PARITY | IMASK_NOMEM
seg1:	.word	0\SR_Q | 1\SR_NB
seg0:	.word	0\SR_Q | 0\SR_NB

keys_mega: ; test MEGA modules? (otherwise test standard modules)
	.res	1
keys_module_cnt: ; how many (standard or MEGA) modules to test
	.res	1
cur_step: ; current MARCH C- step
	.res	1
cur_frame: ; currently tested module and frame (binary: mmmmfff)
	.res	1
sys_pages: ; number of hardwired system pages
	.res	1
computex: ; Computex memory presence flag
	.res	1
mega: ; Amepol's MEGA memory presence flag
	.res	1
run_in_loop: ; loop interactive test indefinitely
	.word	0
stop_on_error: ; pause the test after each error
	.word	0

; ------------------------------------------------------------------------
	.org	INTV
	.res	32, int_unexpected
	.org	STACKP
	.res	1, stack

; ------------------------------------------------------------------------
	.org	OS_START
	.include local_stdio.asm
	.include march.asm
	.include print_helpers.asm

; ------------------------------------------------------------------------
; TODO: handle MEGA memory

; frame map and frame properties
	.const	STD_FRAME_STATE		0b_00000000_00000111
	.const	MEGA_FRAME_STATE	0b_00000000_00111000
	.const	TEST_ACTIVE		0b_00000000_01000000
	.const	SYS_FRAME		0b_00000000_10000000
	.const	FRAME_ADDR		0b_11111111_00000000

; Possible STD_FRAME_STATE values:
	.const	FRAME_ST_NOCONF	0 ; no answer for configuration request (no controller manages such frame, faulty controller, ...)
	.const	FRAME_ST_NORW	1 ; no answer for read/write request (but controller said it had the frame. weird)
	.const	FRAME_ST_EMPTY	2 ; frame returned an empty read (all 1s + parity error or all 0s + no parity error -> missing/faulty memory board)
	.const	FRAME_ST_OK	3 ; frame availabe for use (and auto selected for full test)

	.const	MAP_STD_SIZE	16*8	; 16 modules, 8 frames each (3-bit frame address, 32KW modules)
	.const	MAP_MEGA_SIZE	16*16	; 16 modules, 16 frames each (4-bit frame address, 64KW modules)

test_map_standard:
	.res	MAP_STD_SIZE, 0
test_map_standard_end:
test_map_mega:
	.res	MAP_MEGA_SIZE, 0
test_map_mega_end:

; ------------------------------------------------------------------------
int_mem_parity_mapping:
	rws	r1, .r1

	md	[STACKP]
	lw	r1, [-SP_R0]
	or	r1, PARITY_FLAG
	md	[STACKP]
	rw	r1, -SP_R0			; set parity error flag

	lws	r1, .r1
	lip
.r1:	.res	1

; ------------------------------------------------------------------------
int_mem_segfault_mapping:
	rws	r1, .r1

	md	[STACKP]
	lw	r1, [-SP_R0]
	or	r1, SEGFAULT_FLAG
	md	[STACKP]
	rw	r1, -SP_R0			; set segfault error flag

	lws	r1, .r1
	lip
.r1:	.res	1

; ------------------------------------------------------------------------
int_mem_parity_test:
	rws	r1, .r1

	md	[STACKP]
	lw	r1, [-SP_R0]
	or	r1, PARITY_FLAG
	md	[STACKP]
	rw	r1, -SP_R0			; set parity error flag

	lw	r1, [cur_step]
	lw	r1, [r1+march_step.fail]	; get current fail handler

	md	[STACKP]
	rw	r1, -SP_IC			; update return address

	lws	r1, .r1
	lip
.r1:	.res	1

; ------------------------------------------------------------------------
; simulate memory error by flipping one bit 20 words ahead
; honored only when test is running in NB!=0
int_oprq_test:
	rws	r5, .r5
	rws	r6, .r6

	; is memory test running? (NB!=0)
	md	[STACKP]
	lw	r6, [-SP_SR]
	nr	r6, 15\SR_NB
	jz	.skip

	lwt	r6, 1

	lw	r5, r1+r2	; r1+r2 contain the current address during test
	aw	r5, OPRQ_SIMULATED_ERROR_OFFSET
	nr	r5, 0x0fff
	xm	r6, r5

.skip:
	lws	r5, .r5
	lws	r6, .r6
	lip
.r5:	.res	1
.r6:	.res	1

; ------------------------------------------------------------------------
int_mem_segfault_test:
	hlt	045
	ujs	int_mem_segfault_test

; ------------------------------------------------------------------------
int_unexpected:
	hlt	046
	ujs	int_unexpected

; ------------------------------------------------------------------------
; called every time march test finds an error
march_fail_handler:
	.res	1
	ra	.regs
	mb	seg0

	; test data available here:
	;  * [cur_step] - current MARCH step
	;  * [cur_frame] - currently tested frame
	;  * r2+r1 - current address
	;  * r5 - value read
	;  * r3 - expected read

	; running with or without terminal?
	lw	r7, [term]
	cwt	r7, 0
	jn	.handle_terminal

	; no-terminal error handling output
	; shuffle data for the user
	lw	r4, r5		; r4 = value read
	lw	r5, r3		; r5 = expected read
	lw	r3, r2+r1	; r3 = current address
	md	[cur_step]
	lw	r1, [march_step.num] ; r1 = march step
	lw	r2, [cur_frame] ; r2 = current frame

	hlt	077	; wait for the user to read the error data
	uj	.fin	; continue the test

.handle_terminal:
	lw	r7, r2+r1	; current address

	; print MARCH step
	lw	r1, [cur_step]
	aw	r1, march_step.name
	lj	puts

	; space
	lw	r1, ' '
	lj	putc

	; print module + space
	lw	r1, [cur_frame]
	lj	print_module_space

	; print frame + space
	lw	r1, [cur_frame]
	nr	r1, 0b111
	lj	hex4bit2asc
	shc	r1, 8
	zrb	r1
	or	r1, ' '
	lj	put2c

	; print address
	lw	r1, r7
	lw	r2, tmp
	lj	hex2asc
	lw	r1, tmp
	lj	puts

	; space
	lw	r1, ' '
	lj	putc

	; print read value
	lw	r1, r5
	lw	r2, tmp
	lj	hex2asc
	lw	r1, tmp
	lj	puts

	; print parity error indicator
	bb	r0, PARITY_FLAG
	ujs	.checks_done
	lw	r1, ' P'
	lj	put2c
	er	r0, PARITY_FLAG

.checks_done:
	; stop on error?
	lw	r1, [stop_on_error]
	cwt	r1, 0
	jes	.print_newline
	; print continue/cancel message
	lw	r1, .str_continue
	lj	puts
	; read key
	lj	getc
	; 'X'?
	er	r1, BIT_LCASE
	cw	r1, 'X'
	jn	.print_newline	; no -> continue
	or	r0, TEST_CANCELLATION_FLAG ; yes -> raise flag
.print_newline:
	; line end
	lw	r1, '\n\r'
	lj	put2c
.fin:
	mb	seg1
	la	.regs
	uj	[march_fail_handler]
.regs:	.res	7
.str_continue:
	.asciiz	" (ENTER - kontynuuj, X - przerwij)"

; ------------------------------------------------------------------------
; r1 - sequential module and frame number (0b000000000mmmmfff)
; r2 - segment/page as for OU instruction
; RETURN: r1 - 0=ok, 1=no answer
configure_frame:
	.res	1

	lw	r3, r1
	nr	r3, 0b111	; mask everything except frame number in r3
	shc	r3, -5		; enplace frame number in r3
	shc	r1, 2		; enplace module number in r1
	nr	r1, 0b11110	; mask everything but module in r1
	or	r3, r1		; r3 - final module/frame for OU (0b00000000fffmmmm0)

	ou	r2, r3 + MEM_CFG
	.word	.no, .en, .ok, .pe
.no:	lwt	r1, 1
	ujs	.fin
.en:	hlt	010
	ujs	.en
.pe:	hlt	011
	ujs	.pe
.ok:	lwt	r1, 0
.fin:
	uj	[configure_frame]

; ------------------------------------------------------------------------
; r1 - march step pointer (local r7)
; RETURN: r1 - 1=test cancelled
step_all_frames:
	.res	1
	rl	.regs
	lw	r7, r1
	lw	r6, test_map_standard

	lwt	r5, 0	; current module and frame (0b000000000mmmmfff)

.loop_frame:
	; 'X' cancels the test (only between frames)
	lj	getc_nonblocking
	er	r1, BIT_LCASE
	cw	r1, 'X'
	jn	.is_test_active
	or	r0, TEST_CANCELLATION_FLAG
	jes	.done

.is_test_active:
	; skip frames not marked for test
	lw	r1, [r6+r5]
	nr	r1, TEST_ACTIVE
	cwt	r1, 0
	jes	.next_frame

	; skip unaccessible frames
	lw	r1, [r6+r5]
	nr	r1, STD_FRAME_STATE
	cwt	r1, 2
	jls	.next_frame

	; skip system frames
	lw	r1, [r6+r5]
	nr	r1, SYS_FRAME
	cwt	r1, 0
	jn	.next_frame

.configure_frame:
	; configure frame
	lw	r1, r5
	lw	r2, 1\MEM_SEGMENT | 0\MEM_PAGE
	lj	configure_frame
	cwt	r1, 0
	jes	.run_march_step
	hlt	015	; failed frame configuration, should not happen
	ujs	-2

.run_march_step:
	rw	r5, cur_frame
	er	r0, PARITY_FLAG
	; run march step over currently configured frame
	lw	r1, 0x0000
	lw	r2, 0x0fff
	lw	r3, [r7+march_step.read]
	; WARNING: have to use r4, sorry :-(
	lw	r4, [r7+march_step.write]
	mb	seg1
	lj	[r7+march_step.fun]
	mb	seg0

	; deconfigure frame
	lw	r1, r5
	lw	r2, 15\MEM_SEGMENT | 15\MEM_PAGE
	lj	configure_frame
	cwt	r1, 0
	jes	.next_frame
	hlt	016
	ujs	-2

.next_frame:
	brc	TEST_CANCELLATION_FLAG
	ujs	.done

	awt	r5, 1
	cw	r5, NUM_MODULES * NUM_FRAMES_STD
	jes	.done
	uj	.loop_frame

.done:
	ll	.regs
	uj	[step_all_frames]

.regs:	.res 3

; ------------------------------------------------------------------------
march_run:
	.res	1
	rws	r7, .r7

	er	r0, TEST_CANCELLATION_FLAG
	lw	r7, march_seq

.loop_march:
	; run current march step over all frames
	lw	r1, r7
	rw	r7, cur_step
	lj	step_all_frames
	; test cancelled?
	brc	TEST_CANCELLATION_FLAG
	jes	.fin

	awt	r7, march_step
	cw	r7, march_seq_end
	jn	.loop_march

.fin:
	lws	r7, .r7
	uj	[march_run]

.r7:	.res 1

; ------------------------------------------------------------------------
; return: r1 - number of hardwired system pages
check_sys_pages:
	.res	1
	rws	r6, .r6

	lw	r6, SYS_FRAME
	lwt	r1, 0
	; module, segment - always 0 for system memory
	lwt	r2, 0	; page
	lwt	r3, 0	; frame

.next_frame:
	ou	r2, r3 + MEM_CFG
	.word	.system_frame, .err, .configurable_frame, .err
.err:	hlt	030
	ujs	.err
.system_frame:
	; allocation failed = hardwired system frame
	om	r6, test_map_standard+r1
	awt	r1, 1	; sys_frames++
	cwt	r1, 2	; last checked frame?
	jes	.fin	; yes
	aw	r2, 1\MEM_PAGE	; no - next page
	aw	r3, 1\MEM_FRAME	; next frame
	ujs	.next_frame
.configurable_frame:
	; "dealocate" the non-system frame 1
	lw	r2, 15\MEM_SEGMENT + 15\MEM_PAGE
	ou	r2, r3 + MEM_CFG
	.word	.dealloc_err, .dealloc_err, .fin, .dealloc_err
.dealloc_err:
	hlt	031
	ujs	.dealloc_err
.fin:
	lws	r6, .r6
	uj	[check_sys_pages]
.r6:	.res	1

; ------------------------------------------------------------------------
; Check Computex memory presence
; Heuristic: memory answers to IN commands
; Test: read allocation register for frame 0/2. Not destrictive, no side effects
; RETURN: r1 - 0=absent, 1=present
check_computex:
	.res	1

	lwt	r1, 0
	lw	r3, 0\MEM_MODULE + 2\MEM_FRAME
	in	r2, r3 + MEM_CFG
	.word	.absent, .err, .present, .err
.err:	hlt	032
	ujs	.err
.present:
	lwt	r1, 1
.absent:
	uj	[check_computex]

; ------------------------------------------------------------------------
; Check Amepol's MEGA memory presence
; Heuristic: Memory answers to all OU commands with N[6]=1, even for system pages
; Test: deallocate frame 0/0. Not destructive, no side effects
; RETURN: r1 - 0=absent, 1=present
check_mega:
	.res	1

	lw	r1, 0
	lw	r2, 0\MEM_SEGMENT + 0\MEM_PAGE
	lw	r3, 0\MEM_MODULE + 0\MEM_FRAME
	ou	r2, r3 + MEM_CFG + MEGA_FREE
	.word	.absent, .err, .present, .err
.err:	hlt	033
	ujs	.err
.present:
	lwt	r1, 1
.absent:
	uj	[check_mega]

; ------------------------------------------------------------------------
clear_map_mem_std:
	.res	1

	lw	r2, MAP_STD_SIZE
.loop:
	rz	test_map_standard-1 + r2
	drb	r2, .loop

	uj	[clear_map_mem_std]

; ------------------------------------------------------------------------
map_mem_std:
	.res	1
	rl	.regs

	lw	r5, [sys_pages] ; current frame number. start from module 0, frame right after system pages
	lw	r6, test_map_standard

.loop_frame:
	; try configuring frame
	lw	r1, r5
	lw	r2, 1\MEM_SEGMENT | 0\MEM_PAGE
	lj	configure_frame
	cwt	r1, 0	; 0: OK, 1: no answer
	jes	.frame_ok
	ujs	.next_frame	; frame missing, gg go next

.frame_ok:
	ib	r6+r5		; advance frame state: frame configured OK

	; try writing and reading back from the frame
	er	r0, PARITY_FLAG | SEGFAULT_FLAG
	lw	r1, MAGIC
	mb	seg1
	pw	r1, 0
	shc	r1, 8
	tw	r1, 0
	mb	seg0

	; check for segfault
	brc	SEGFAULT_FLAG	; skip if no segfault
	ujs	.deconfigure	; segfault
	ib	r6+r5		; advance frame state: no segfault

	; check for empty read
	cw	r1, 0
	jes	.zeroes_read
	cw	r1, 0xffff
	jes	.ones_read
	ib	r6+r5		; advance frame state: not an empty read (data != {0,ffff})
	ujs	.deconfigure

.zeroes_read:
	bb	r0, PARITY_FLAG	; skip if parity error
	ujs	.deconfigure
	ib	r6+r5		; advance frame state: all 1s, but with parity error

.ones_read:
	brc	PARITY_FLAG	; skip if no parity error
	ujs	.deconfigure
	ib	r6+r5		; advance frame state: all 1s, but no parity error

.deconfigure:
	; deconfigure frame
	lw	r1, r5
	lw	r2, 15\MEM_SEGMENT | 15\MEM_PAGE
	lj	configure_frame

.next_frame:
	awt	r5, 1
	cw	r5, NUM_MODULES * NUM_FRAMES_STD
	jes	.done
	ujs	.loop_frame

.done:
	ll	.regs
	uj	[map_mem_std]
.regs:	.res	3

; ------------------------------------------------------------------------
print_mem_map_std:
	.res	1
	rl	.regs

	lw	r5, 0	; current frame

	lw	r1, .str_map
	lj	puts
	lw	r1, .str_legend
	lj	puts

	lw	r1, .str_table_header
	lj	puts

.loop_frame:
	; is this the start of a new row?
	lw	r1, r5
	nr	r1, 0b11111
	cwt	r1, 0
	jn	.print_header	; no, skip row header
	lw	r1, '\n\r'
	lj	put2c		; yes, newline

.print_header:
	; is this start of a new module?
	lw	r1, r5
	nr	r1, 0b111
	cwt	r1, 0
	jn	.print_frame	; no, skip module header
	lw	r1, ' '
	lj	putc		; yes, print module header

	lw	r1, r5
	lj	print_module_space

.print_frame:
	lw	r1, [test_map_standard+r5]
	nr	r1, SYS_FRAME
	jz	.print_frame_type
	lw	r1, 'S'
	lj	putc
	ujs	.next_frame

.print_frame_type:
	lw	r1, [test_map_standard+r5]
	nr	r1, STD_FRAME_STATE
	lw	r1, [.map_frame_markings+r1]
	lj	putc

.next_frame:
	awt	r5, 1
	cw	r5, NUM_MODULES * NUM_FRAMES_STD
	jes	.done
	ujs	.loop_frame

.done:
	lw	r1, '\n\r'
	lj	put2c
	lw	r1, '\n\r'
	lj	put2c

	ll	.regs
	uj	[print_mem_map_std]
.regs:	.res	3

.str_map:
	.asciiz "Mapa kwantow pamieci standardowej:\n\r\n\r"
.str_legend:
	.asciiz "[S] systemowy  [+] dostepny  [_] brak  [?] brak odp. r/w  [X] pusty odczyt\n\r\n\r"
.str_table_header:
	.asciiz "   01234567   01234567   01234567   01234567"
.map_frame_markings:
	; visual representation of the state stored on STD_FRAME_STATE bits
	.word	'_', '?', 'X', '+'

; ------------------------------------------------------------------------
setup:
	.res	1

	; clear the memory map
	lj	clear_map_mem_std

	; check system segments
	lj	check_sys_pages
	rw	r1, sys_pages

	; check for Amepol's MEGA memory
	lj	check_mega
	rw	r1, mega

	; check for Computex' memory
	lj	check_computex
	rw	r1, computex

	; install interrupt handlers for mapping the memory
	lw	r1, int_mem_parity_mapping
	rw	r1, INTV_PARITY
	lw	r1, int_mem_segfault_mapping
	rw	r1, INTV_NOMEM
	im	imask_mapping

	; Map out standard memory
	lj	map_mem_std

	; disable interrupts
	im	imask_zero

	; install interrupt handlers for the test
	lw	r1, int_mem_parity_test
	rw	r1, INTV_PARITY
	lw	r1, int_mem_segfault_test
	rw	r1, INTV_NOMEM
	lw	r1, int_oprq_test
	rw	r1, INTV_OPRQ

	uj	[setup]

; ------------------------------------------------------------------------
initial_printout:
	.res	1

	; print greeting
	lw	r1, str_greet
	lj	puts

	; print system segments
	lw	r1, str_sysmem
	lj	puts
	lw	r1, [sys_pages]
	aw	r1, '0'
	lj	putc
	lw	r1, '\n\r'
	lj	put2c

	; print Amepol's MEGA memory presence
	lw	r1, str_mega
	lj	puts
	lw	r1, [mega]
	lj	print_yesno
	lw	r1, '\n\r'
	lj	put2c

	; print Computex' memory presence
	lw	r1, str_computex
	lj	puts
	lw	r1, [computex]
	lj	print_yesno
	lw	r1, '\n\r'
	lj	put2c

	; Print memory map
	lj	print_mem_map_std

	uj	[initial_printout]

; ------------------------------------------------------------------------
select_modules_auto:
	.res	1

	lw	r1, TEST_ACTIVE
	lw	r2, test_map_standard

.loop:
	; deactivate test for the frame
	em	r1, r2
	lw	r3, [r2]
	nr	r3, STD_FRAME_STATE
	cw	r3, FRAME_ST_OK
	jn	.next
	om	r1, r2
.next:
	awt	r2, 1
	cw	r2, test_map_standard_end
	jes	.fin
	ujs	.loop

.fin:
	uj	[select_modules_auto]

; ------------------------------------------------------------------------
; r2 - number of modules to test (>0)
select_modules_keys:
	.res	1
	rws	r5, .r5

	; cap module count at 16
	cwt	r2, 17
	jls	.count_ok
	lwt	r2, 16

.count_ok:
	shc	r2, -3
	lw	r3, 0
.loop:
	lw	r5, TEST_ACTIVE
	om	r5, test_map_standard+r3

	awt	r3, 1
	cw	r3, r2
	jes	.fin
	ujs	.loop
.fin:
	lws	r5, .r5
	uj	[select_modules_keys]
.r5:	.res	1

; ------------------------------------------------------------------------
print_menu:
	.res	1

	lw	r1, .str_menu1
	lj	puts
	lw	r1, .str_menu2
	lj	puts
	lw	r1, .str_menu3
	lj	puts
	lw	r1, .str_menu4
	lj	puts
	lw	r1, '\n\r'
	lj	put2c

	uj	[print_menu]

.str_menu1:	.asciiz " <L> Zapetlanie testu          <S> Stop po bledzie\n\r"
.str_menu2:	.asciiz " <T> Test dostepnych kwantow   <K> Test wybranego kwantu\n\r"
.str_menu3:	.asciiz " <M> Test wybranego modulu     <P> Pokaz mape pamieci\n\r"
.str_menu4:	.asciiz " Dowolny inny klawisz - pokaz menu\n\r"

; ------------------------------------------------------------------------
clear_frame_selection:
	.res	1

	lw	r1, TEST_ACTIVE
	lw	r2, 0
.loop:
	em	r1, test_map_standard+r2
	awt	r2, 1
	cw	r2, NUM_MODULES * NUM_FRAMES_STD
	jes	.fin
	ujs	.loop
.fin:
	uj	[clear_frame_selection]

; ------------------------------------------------------------------------
; RETURN: r1 - module number (0-f)
read_module:
	.res	1
	rws	r5, .r5

	lw	r1, .str_read_module
	lj	puts

	lj	read_4bit_hex
	lw	r5, r1

	lw	r1, '\r\n'
	lj	put2c

	lw	r1, r5

	lws	r5, .r5
	uj	[read_module]
.str_read_module:
	.asciiz	"Podaj nr modulu (0-f): "
.r5:	.res	1

; ------------------------------------------------------------------------
; RETURN: r1 - frame number (0-7)
read_frame:
	.res	1
	rws	r5, .r5

	lw	r1, .str_read_frame
	lj	puts

	lj	read_4bit_hex
	lw	r5, r1
	nr	r5, 7

	lw	r1, '\r\n'
	lj	put2c

	lw	r1, r5

	lws	r5, .r5
	uj	[read_frame]
.str_read_frame:
	.asciiz	"Podaj nr kwantu (0-7): "
.r5:	.res	1

; ------------------------------------------------------------------------
select_frame:
	.res	1
	rws	r5, .r5
	rws	r6, .r6

	lj	read_module
	shc	r1, -3
	lw	r5, r1		; r5 - module number

	lj	read_frame
	or	r5, r1

	lw	r1, '\r\n'
	lj	put2c

	lw	r6, TEST_ACTIVE
	om	r6, r5+test_map_standard

	lws	r5, .r5
	lws	r6, .r6
	uj	[select_frame]
.r5:	.res	1
.r6:	.res	1

; ------------------------------------------------------------------------
select_module:
	.res	1
	rws	r5, .r5
	rws	r6, .r6

	lj	read_module	; r1 - module number (0-f)
	shc	r1, -3
	lw	r6, TEST_ACTIVE
.loop:
	om	r6, test_map_standard+r1
	awt	r1, 1
	lw	r5, r1
	nr	r5, 0b111
	jz	.fin
	ujs	.loop

.fin:
	lws	r5, .r5
	lws	r6, .r6
	uj	[select_module]
.r5:	.res	1
.r6:	.res	1

; ------------------------------------------------------------------------
handle_menu:
	.res	1
	rw	r7, .r7

	lj	getc
	lw	r7, r1
	lw	r1, '\n\r'
	lj	put2c
	er	r7, BIT_LCASE	; convert to uppercase
	cw	r7, 'T'
	jes	.menu_test_all
	cw	r7, 'P'
	jes	.menu_show_map
	cw	r7, 'K'
	jes	.menu_test_frame
	cw	r7, 'M'
	jes	.menu_test_module
	cw	r7, 'L'
	jes	.menu_loop
	cw	r7, 'S'
	jes	.menu_stop
	ujs	.menu_print_menu

.menu_loop:
	lw	r1, .str_loop
	lw	r2, run_in_loop
	lj	bool_toggle_print
	ujs	.fin
.menu_stop:
	lw	r1, .str_stop
	lw	r2, stop_on_error
	lj	bool_toggle_print
	ujs	.fin
.menu_test_all:
	lj	select_modules_auto
	ujs	.run_test
.menu_print_menu:
	lj	print_menu
	ujs	.fin
.menu_show_map:
	lj	print_mem_map_std
	ujs	.fin
.menu_test_frame:
	lj	clear_frame_selection
	lj	select_frame
	ujs	.run_test
.menu_test_module:
	lj	clear_frame_selection
	lj	select_module
	ujs	.run_test
.run_test:
	; print start test
	lw	r1, .str_test_start
	lj	puts

	; run test
.loop_test:
	im	imask_test
	lj	march_run
	im	imask_zero
	; test cancelled?
	brc	TEST_CANCELLATION_FLAG
	jes	.test_cancelled
	; loop the test?
	lw	r1, [run_in_loop]
	cwt	r1, 0
	jes	.test_done
	ujs	.loop_test
.test_done:
	lw	r1, .str_test_end
	lj	puts
	ujs	.fin
.test_cancelled:
	lw	r1, .str_test_cancelled
	lj	puts
.fin:
	lw	r7, [.r7]
	uj	[handle_menu]
.r7:	.res	1
.str_test_start:
	.asciiz	"Start testu (X aby przerwac)\n\r"
.str_test_end:
	.asciiz "Koniec testu\n\r"
.str_test_cancelled:
	.asciiz "\n\rTest przerwany\n\r"
.str_loop:
	.asciiz	"Test zapetlony: "
.str_stop:
	.asciiz	"Zatrzymanie na kazdym bledzie: "

; ------------------------------------------------------------------------
; --- MAIN ---------------------------------------------------------------
; ------------------------------------------------------------------------
start:
	lj	setup

	; running with or without terminal?
	lw	r1, [term]
	cwt	r1, 0
	jes	run_no_terminal

; ------------------------------------------------------------------------
run_terminal:
	lj	initial_printout
	lj	print_menu
.loop:
	lj	handle_menu
	ujs	.loop

; ------------------------------------------------------------------------
run_no_terminal:
	lw	r2, [keys_module_cnt]
	cwt	r2, 0
	jes	.auto
	lj	select_modules_keys
	ujs	.run
.auto:
	lj	select_modules_auto
.run:
	im	imask_test
.loop:
	lj	march_run
	ujs	.loop

; ------------------------------------------------------------------------
str_greet:	.asciiz "\n\rTest pamieci MARCH C-\n\r------------------------------------------\n\r"
str_sysmem:	.asciiz	"Strony systemowe: "
str_computex:	.asciiz "Pamiec Computex: "
str_mega:	.asciiz "Pamiec MEGA (Amepol): "
stack:	.res	4*4
tmp:	.res	10

memtest_lowest_addr:

