.include "config.s"
.include "mul-macs.s"

.globl div9u

.text

# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div9u
#
# Unsigned fast division by 9.
# Approximation: q = n * (1/9)
# Series: 1/9 = (7/8) * (1/8) * (1 + 1/64 + 1/4096...)
#
# RV32E Compatible.
#
# input:  a0 = dividend
# output: a0 = quotient
################################################################################    
div9u:
	# approximate quotient: q_accum = n * (8/9)
	# start with n * (7/8)
	srli	a2, a0, 3	# a2 = n >> 3
	sub	a1, a0, a2	# a1 = n - (n >> 3) = n * 0.875
	# series expansion: multiply by (1 + 1/64 + 1/4096...)
	srli	a2, a1, 6
	add	a1, a1, a2	# q += q >> 6
	srli	a2, a1, 12
	add	a1, a1, a2	# q += q >> 12
	srli	a2, a1, 24
	add	a1, a1, a2	# q += q >> 24
.if CPU_BITS == 64
	srli	a2, a1, 48
	add	a1, a1, a2	# q += q >> 48
.endif

	# final adjustment: q = (n * 8/9) / 8 = n / 9
	srli	a1, a1, 3	# a1 = q_approx

	# negative remainder -9 < -8 -> 1 (correction), -8 < -8 -> 0 (no corr)
	mul9	a3, a1, a2
	sub	a2, a3, a0
	slti	a3, a2, -8
	add	a0, a1, a3	# q = q + correction

	ret
.size div9u, .-div9u
