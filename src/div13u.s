.include "config.s"
.include "mul-macs.s"

.globl div13u
.text

# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div13u
#
# Unsigned fast division by 13.
# Optimizations: 
# - Robust Estimator (Max Error 1) to support 64-bit inputs.
# - Negative Remainder Trick to minimize correction instructions.
#
# input:  a0 = dividend
# output: a0 = quotient
################################################################################	
div13u:
	# estimator: q = n * (1/13)
	# base: n * 5/8 * 63/64 approx n * 0.6152...
	# target: n * 8/13 = n * 0.6153...
	srli	a1, a0, 1
	srli	a2, a0, 3
	add	a1, a1, a2	# a1 = n * 0.625

	srli	a2, a1, 6
	sub	a1, a1, a2	# a1 = n * 0.61523...

	# series expansion (1 + 2^-12 + ...)
	srli	a2, a1, 12
	add	a1, a1, a2
	srli	a2, a1, 24
	add	a1, a1, a2
.if CPU_BITS == 64
	srli	a2, a1, 48
	add	a1, a1, a2
.endif

	srli	a1, a1, 3	# q_est = q_accum / 8

	# negative remainder & correction
	mul13	a2, a1, a2	# a2 = 13 * q
	sub	a2, a2, a0	# a2 = 13q - n (Negative Remainder)

	# threshold: if diff <= -13 (i.e. < -12), add 1
	slti	a3, a2, -12
	add	a0, a1, a3	# q + correction

	ret	
.size div13u, .-div13u
