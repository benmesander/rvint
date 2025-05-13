.include "config.s"

.global divremu

.text

# Unsigned integer division without using M extension
# uses the restoring division algorithm
# in: a0 = dividend
# in: a1 = divisor
# out: a0 = quotient 
# out: a1 = remainder
divremu:
	# check for division by zero, if so immediately return
	beqz	a1, divremu_zero
	
	mv	t0, a0		# dividend
	mv	t1, a1		# divisor
	li	a0, 0		# quotient
	li	a1, 0		# remainder
	li	t3, 1		# set bit to the highest bit position
	slli	t3, t3, CPU_BITS-1

divremu_loop:
	slli	a1, a1, 1	# shift remainder left by 1
	and	t2, t0, t3	# Isolate the highest bit of the dividend
	snez	t2, t2
	add	a1, a1, t2	# insert next dividend bit into remainder

	# Check if remainder is greater than or equal to divisor
	bltu	a1, t1, divremu_continue
	sub	a1, a1, t1	# subtract divisor from remainder
	add	a0, a0, t3	# add bit to quotient

divremu_continue:
	srli	t3, t3, 1	# shift the bit mask to the right
	bnez	t3, divremu_loop
	ret

divremu_zero:
	li	a0, -1		# return quotient, remainder = -1 as error code
	li	a1, -1
	ret

.size divrem, .-divrem
