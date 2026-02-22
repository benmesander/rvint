.include "config.s"
.include "mul-macs.s"

.globl div11u
.text

# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div11u
#
# Unsigned fast division by 11.
# Base: 3 * (n/4 - n/128) = n * 93/128.
#
# input:  a0 = unsigned dividend
# output: a0 = quotient
################################################################################	
div11u:
	# estimator: q = n * (1/11)
	# base: n * 93/128
	# calc: 3 * (n >> 2 - n >> 7)
	srli	a1, a0, 2
	srli	a2, a0, 7
	sub	a1, a1, a2	# a1 = n/4 - n/128
	mul3	a1, a1, a2	# a1 = 3 * a1 (uses a2 as scratch)

	# series expansion (1 + 2^-10 + ...)
	# factor 93/128 matches the required 10-bit period of 1/11
	srli	a2, a1, 10
	add	a1, a1, a2
	srli	a2, a1, 20
	add	a1, a1, a2
.if CPU_BITS == 64
	srli	a2, a1, 40
	add	a1, a1, a2
.endif

	# final shift: q_est = q_accum / 8
	srli	a1, a1, 3

	# negative remainder & correction
	mul11	a2, a1, a2	# a2 = 11 * q
	sub	a2, a2, a0	# a2 = 11q - n (negative remainder)

	# threshold: if diff <= -11 (i.e. < -10), add 1
	slti	a3, a2, -10
	add	a0, a1, a3	# q + correction

	ret	
.size div11u, .-div11u
