.include "config.s"
.include "mul-macs.s"
.globl from_dec
.text


################################################################################
# routine: from_dec
#
# Read an ASCII signed decimal string into a register. The parsing of the value
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

from_dec:
	FRAME	1
	PUSH	ra, 0

	li	a5, 0	# sign bit (not used by from_decu)
	li	a4, '-'
	lb	a2, (a0)
	beq	a2, a4, from_dec_handle_minus
	li	a4, '+'
	beq	a2, a4, from_dec_handle_plus
	j	from_dec_convert

from_dec_handle_minus:
	li	a5, 1
from_dec_handle_plus:
	addi	a0, a0, 1

from_dec_convert:
	jal	from_decu
	beq	a5, zero, from_dec_done
	sub	a1, zero, a1

from_dec_done:
	POP	ra, 0
	EFRAME	1
	ret

.size from_dec, .-from_dec
