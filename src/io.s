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
	# isolate byte of interest
	addi	a1, a1, -1	# zero-base count to an index
	li	t0, 0xff
	slli	t1, a1, 3	# t1 = a1 * 8
	sll	t0, t0, t1



.bss

.comm iobuf, 65	# reserves 65 bytes for an i/o buffer
