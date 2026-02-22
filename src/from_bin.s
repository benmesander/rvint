.include "config.s"
.include "mul-macs.s"
.globl from_bin
.text


################################################################################
# routine: from_bin
#
# Read an ASCII binary string into a register. The parsing of the value
# stops when we read the first non-binary character.
# RV32E compatible.
#
# input registers:
# a0 = pointer to number to convert from binary, terminated with non-binary char.
#
# output registers:
# a0 = pointer (advanced to point to non-binary char)
# a1 = number
# a2 = error check: 0 if no digits found, otherwise 1
################################################################################

from_bin:
	li	a1, 0
	li	a2, 0
	li	a5, 1
from_bin_bit:
	lb	a3, (a0)
	addi	a4, a3, -'0'
	bgtu	a4, a5, from_bin_done

	li	a2, 1		# we found a bit
	slli	a1, a1, 1
	or	a1, a1, a4	# add new bit
	addi	a0, a0, 1
	j	from_bin_bit

from_bin_done:
	ret
.size from_bin, .-from_bin
