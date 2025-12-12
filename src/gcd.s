.include "config.s"
.globl gcd
.globl lcm

.text

################################################################################
# routine: gcd
#
# Compute GCD of two unsigned numbers. RV32I/RV32E/RV64I compatible.
#
# Optimizations:
# - HAS_M: Uses 'remu' (Euclidean algorithm) for O(log N) speed.
# - Base/Zbb: Uses Stein's Algorithm (Binary GCD) for O(log N) without div.
#
# input:  a0 (u), a1 (v)
# output: a0 gcd(u,v) (result)
################################################################################

gcd:
	# Handle Base Cases: gcd(0, v) = v, gcd(u, 0) = u
	beqz	a0, gcd_return_v
	beqz	a1, gcd_return_u

.if HAS_M
	# =========================================================
	# Strategy 1: Euclidean Algorithm (Modulo)
	# Requires M Extension. Fastest/Smallest.
	# =========================================================
gcd_mod_loop:
	remu	t0, a0, a1	# t0 = u % v
	mv	a0, a1		# u = v
	mv	a1, t0		# v = remainder
	bnez	a1, gcd_mod_loop
	ret

.else
	# =========================================================
	# Strategy 2: Stein's Algorithm (Binary GCD)
	# Best for processors without hardware division.
	# =========================================================
	
	# 1. Find common factors of 2 (k)
	or	t0, a0, a1	# t0 = u | v
.if HAS_ZBB
	ctz	a2, t0		# a2 = k = ctz(u | v)
	srl	a0, a0, a2	# u >>= k
	srl	a1, a1, a2	# v >>= k
.else
	# Manual CTZ Loop for 'k' if no Zbb
	li	a2, 0
gcd_find_k:
	andi	t0, t0, 1
	bnez	t0, gcd_remove_u_zeros
	srli	a0, a0, 1
	srli	a1, a1, 1
	or	t0, a0, a1
	addi	a2, a2, 1
	j	gcd_find_k
.endif

gcd_remove_u_zeros:
	# 2. Divide u by 2 until odd
.if HAS_ZBB
	ctz	t0, a0
	srl	a0, a0, t0
.else
gcd_u_loop:
	andi	t0, a0, 1
	bnez	t0, gcd_inner_loop
	srli	a0, a0, 1
	j	gcd_u_loop
.endif

gcd_inner_loop:
	# 3. Divide v by 2 until odd
.if HAS_ZBB
	ctz	t0, a1
	srl	a1, a1, t0
.else
gcd_v_loop:
	andi	t0, a1, 1
	bnez	t0, gcd_check_swap
	srli	a1, a1, 1
	j	gcd_v_loop
.endif

gcd_check_swap:
	# 4. Ensure u <= v
	bgeu	a1, a0, gcd_sub
	mv	t0, a0
	mv	a0, a1
	mv	a1, t0

gcd_sub:
	# 5. v = v - u
	sub	a1, a1, a0
	bnez	a1, gcd_inner_loop

	# 6. Restore common factor of 2: result = u << k
	sll	a0, a0, a2
	ret
.endif

gcd_return_v:
	mv	a0, a1
gcd_return_u:
	ret
.size gcd, .-gcd

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
