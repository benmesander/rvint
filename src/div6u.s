.include "config.s"
.include "mul-macs.s"

.globl div6u
.text

# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	

################################################################################
# routine: div6u
#
# Unsigned fast division by 6.
# Algorithm: Series expansion + Dual Threshold Correction.
#
# input:  a0 = unsigned dividend
# output: a0 = unsigned quotient
################################################################################
div6u:
	# estimate quotient: q = n / 6
	# base: n * (1/2 + 1/8) = n * 0.625
	srli	a1, a0, 1
	srli	a2, a0, 3
	add	a1, a1, a2

	# series expansion (converges to 0.666...)
	srli	a2, a1, 4
	add	a1, a1, a2
	srli	a2, a1, 8
	add	a1, a1, a2
	srli	a2, a1, 16
	add	a1, a1, a2
.if CPU_BITS == 64
	srli	a2, a1, 32
	add	a1, a1, a2
.endif

	# final shift: q_est = q_accum / 4
	srli	a1, a1, 2

	# negative remainder calculation
	# diff = 6q - n
	mul6	a2, a1, a2	# a2 = 6 * q
	sub	a2, a2, a0	# a2 = 6q - n

	# threshold 1: diff <= -6 (i.e. < -5)
	# handles estimation error of 1
	slti	a3, a2, -5
	add	a1, a1, a3	# q += 1

.if CPU_BITS == 64
	# threshold 2: diff <= -12 (i.e. < -11)
	# handles estimation error of 2 (possible for >60-bit inputs)
	slti	a3, a2, -11
	add	a1, a1, a3	# q += 1
.endif

	mv	a0, a1
	ret
.size div6u, .-div6u
