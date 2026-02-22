.include "config.s"
.include "mul-macs.s"
.globl from_decu
.text


################################################################################
# routine: from_decu
#
# Read an ASCII unsigned decimal string into a register. The parsing of the value
# stops when we read the first non-decimal character.
# RV32E compatible.
#
# input registers:
# a0 = pointer to number to convert from decimal, terminated with non-decimal char.
#
# output registers:
# a0 = pointer (advanced to point to non-decimal char)
# a1 = number
# a2 = error check: 0 if no digits found, otherwise 1
################################################################################

from_decu:
	li	a1, 0
	li	a2, 0
	li	t1, 9

from_decu_digit:
	lb	t0, (a0)
	addi	a4, t0, -'0'
	bgtu	a4, t1, from_decu_done

	li	a2, 1
	mul10	a1, a1, a3
	add	a1, a1, a4	# add in new digit
	addi	a0, a0, 1
	j	from_decu_digit

from_decu_done:
	ret
.size from_decu, .-from_decu
