.include "config.s"
.globl lcm

.text

################################################################################
# routine: lcm
#
# Compute the least common multiple (lcm) of two unsigned numbers.
# Formula: lcm(u,v) = (u / gcd(u,v)) * v. RV32I/RV32E/RV64I compatible.
#
# Optimizations:
# - HAS_M: Inlines hardware div/mul to avoid function call overhead.
#
# Input:  a0 (u), a1 (v)
# Output: a0 (lcm)
################################################################################

lcm:
	# Check for zero inputs early (lcm(0, x) = 0)
	beqz	a0, lcm_return_zero
	beqz	a1, lcm_return_zero

	# Setup Stack (Need to preserve ra, s0, s1 across calls)
	FRAME	3
	PUSH	ra, 0
	PUSH	s0, 1
	PUSH	s1, 2

	mv	s0, a0		# s0 = u
	mv	s1, a1		# s1 = v

	# 1. Calculate GCD(u, v)
	# Result returns in a0
	jal	gcd

	# 2. Calculate u / GCD
	# Input: a0=u, a1=gcd
	mv	a1, a0		# Move GCD to divisor
	mv	a0, s0		# Move u to dividend

.if HAS_M
	divu	a0, a0, a1	# a0 = u / gcd
.else
	call	divremu		# a0 = u / gcd
.endif

	# 3. Calculate (u/gcd) * v
	# Input: a0=(u/gcd), a1=v
	mv	a1, s1		# Move v to multiplier

.if HAS_M
	mul	a0, a0, a1	# a0 = result * v
.else
	call	nmul		# a0 = result * v
.endif

	# Cleanup and Return
	POP	s1, 2
	POP	s0, 1
	POP	ra, 0
	EFRAME	3
	ret

lcm_return_zero:
	li	a0, 0
	ret
.size lcm, .-lcm
	
