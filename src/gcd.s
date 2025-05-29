.include "config.s"
.globl gcd
.globl lcm

.text

################################################################################
# routine: gcd
#
# Compute the greatest common divisor (gcd) of two unsigned numbers.
# 64 bit algorithm on 64-bit CPUs, 32-bit algorithm on 32-bit CPUs.
#
# input registers:
# a0 = first number (u)
# a1 = second number (v)
#
# output registers:
# a0 = gcd(u, v)
################################################################################
gcd:
	# Use s0 and s1 for our main variables
	FRAME	3
	PUSH	ra, 0
	PUSH	s0, 1
	PUSH	s1, 2

	beqz	a0, gcd_return_v
	beqz	a1, gcd_return_u

	mv	s0, a0		# s0 = u
	mv	s1, a1		# s1 = v

gcd_loop:			
	bltu	s0, s1, gcd_skip_swap
	mv	t0, s0		# Save u
	mv	s0, s1		# u = v
	mv	s1, t0		# v = old u

gcd_skip_swap:	
	sub	s1, s1, s0	# v -= u
	bnez	s1, gcd_loop	# Continue if v != 0
	
	mv	a0, s0		# Return u

gcd_cleanup:	
	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	EFRAME	3
	ret

gcd_return_v:
	mv	a0, a1
gcd_return_u:
	j	gcd_cleanup

.size	gcd, .-gcd
	
################################################################################
# routine: lcm
#
# Compute the least common multiple (lcm) of two unsigned numbers.
# 64 bit algorithm on 64-bit CPUs, 32-bit algorithm on 32-bit CPUs.
#
# input registers:
# a0 = u
# a1 = v
#
# output registers:
# a0 = lcm(u,v)
################################################################################
lcm:
	FRAME	3
	PUSH	ra, 0
	PUSH	s0, 1
	PUSH	s1, 2

	beqz	a0, lcm_check_a1	# check to see if both a0 and a1 are 0

lcm_start:	
	mv	s0, a0		# Save first number
	mv	s1, a1		# Save second number

	# Calculate GCD first
	jal	gcd		# gcd result in a0
	mv	a1, a0		# Move GCD to divisor register
	mv	a0, s0		# First number
	call	divremu		# Divide first number by GCD
	mv	t0, a0		# Save quotient temporarily

	mv	a0, t0		# Load saved quotient
	mv	a1, s1		# Second number
	call	nmul		# Multiply to get LCM

lcm_cleanup:	
	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	EFRAME	3
	ret

lcm_check_a1:
	bnez	a1, lcm_start
	j	lcm_cleanup	# if a0, a1 both zero, return zero
	
.size lcm, .-lcm
