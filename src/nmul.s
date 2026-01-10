.include "config.s"

.globl nmul

.text

################################################################################
# routine: nmul
#
# Native word length signed/unsigned multiplication. RV32I/RV32E/RV64I.
#
# Optimizations:
# - Swaps operands to ensure the smaller value is the multiplier (loop counter).
# - Uses 'ctz' (Count Trailing Zeros) if HAS_ZBB is defined to skip zero bits.
#
# input registers:
# a0 = multiplicand
# a1 = multiplier
#
# output registers:
# a0 = product
################################################################################

nmul:
	# Optimization: Swap operands to minimize loop iterations
	# We want the multiplier (a1) to be the smaller unsigned value.
	bgeu	a0, a1, nmul_no_swap
	mv	a2, a0
	mv	a0, a1
	mv	a1, a2
nmul_no_swap:

	# Setup
	mv	a2, a0			# a2 = multiplicand
	li	a0, 0			# a0 = product (accumulator)

	# Optimization: Skip blocks of zeros (Zbb Extension)
.if HAS_ZBB
nmul_loop:
	beqz	a1, nmul_done		# Exit if multiplier is 0

	ctz	a3, a1			# a3 = Count Trailing Zeros of multiplier
	srl	a1, a1, a3		# Shift multiplier right by count
	sll	a2, a2, a3		# Shift multiplicand left by count

	# LSB of multiplier is now guaranteed to be 1
	add	a0, a0, a2		# product += multiplicand

	# Prepare for next bit
	srli	a1, a1, 1		# Shift multiplier right by 1
	slli	a2, a2, 1		# Shift multiplicand left by 1
	j	nmul_loop

.else
	# Standard Shift-and-Add Loop
nmul_loop:
	andi	a3, a1, 1		# Check LSB
	beqz	a3, nmul_skip
	add	a0, a0, a2		# product += multiplicand
nmul_skip:
	srli	a1, a1, 1		# Shift multiplier right
	slli	a2, a2, 1		# Shift multiplicand left
	bnez	a1, nmul_loop
.endif

nmul_done:
	ret
.size nmul, .-nmul
