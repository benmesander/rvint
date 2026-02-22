.include "config.s"
.include "mul-macs.s"
.globl from_hex
.text


################################################################################
# routine: from_hex
#
# Read an ASCII hexidecimal string into a register. The parsing of the value
# stops when we read the first non-hex character.
# RV32E compatible.
#
# input registers:
# a0 = pointer to number to convert from hex, terminated with non-hex char.
#
# output registers:
# a0 = pointer (advanced to point to non-hex char)
# a1 = number
# a2 = error check: 0 if no digits found, otherwise 1
################################################################################
	
from_hex:
	li	a1, 0
	li	a2, 0
	li	a5, 9
	li	t0, 5
from_hex_nibble:
	lb	a3, (a0)

	# Handle 0-9
	addi	a4, a3, -'0'
	bleu	a4, a5, from_hex_add_digit

	# Handle a-f and A-F by converting to uppercase
	andi	a3, a3, 0xDF	# clear bit 5 (cvt to upper)
	addi	a4, a3, -'A'
	bgtu	a4, t0, from_hex_done
	addi	a4, a4, 10	# A-F -> 10-15

from_hex_add_digit:
	li	a2, 1		# we found a digit
	slli	a1, a1, 4	# shift result left by 4 bits
	add	a1, a1, a4	# add new nibble
	addi	a0, a0, 1
	j	from_hex_nibble

from_hex_done:
	ret
.size from_hex, .-from_hex
