.include "config.s"

.text

	# input
	# a0 - hex number to convert to ascii
	# a1 - number of bytes to convert (eg, 1, 2, 4, 8)
	# a2 - 0 do not insert leading 0x, 1 insert leading 0x
	#
	# output
	# a0 - address of null-terminated buffer with output
to_hex:
	la	t0, iobuf
	li	t3, '9' + 1	# '@'
	slli	a1, a1, 2	# count of nibbles
	beqz	a2, to_hex_loop
	li	t1, 0x7830	# '0x' in ascii, little-endian
	sw	t1, 0(t0)
	addi	t0, t0, 2
	
to_hex_loop:	
	addi	a1, a1, -1
	slli	t1, a1, 2
	srl	t2, a0, t1
	andi	t2, t2, 0xf
	addi	t2, t2, '0'	# numeral
	bge	t2, t3, to_hex_digit
	addi	t2, t2, 'a'-'0'	# too big for numeral, add offset to alpha
to_hex_digit:
	sb	t2, 0(t0)
	addi	t0, t0, 1
	bnez	a1, to_hex_loop
	sb	zero, 0(t0)	# nul terminate
	la	a0, iobuf
	ret
.bss

.comm iobuf, 65	# reserves 65 bytes for an i/o buffer
