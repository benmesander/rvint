.include "config.s"
.globl gcd

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

