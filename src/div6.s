.include "config.s"
.include "mul-macs.s"

.globl div6
.text

# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div6
#
# Signed fast division by 6.
# Algorithm: abs(n) / 6 -> restore sign.
#
# input:  a0 = signed dividend
# output: a0 = signed quotient
################################################################################
div6:
	# preamble: compute sign mask (t0) and abs(n) (a0)
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0	# a0 = abs(n)

	# estimate quotient: q = abs(n) / 6
	# base: n * (1/2 + 1/8) = n * 0.625
	# target: n * 4/6 = n * 0.666...
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
	# diff = 6q - abs(n)
	mul6	a2, a1, a2	# a2 = 6 * q
	sub	a2, a2, a0	# a2 = 6q - abs(n)

	# threshold 1: diff <= -6 (i.e. < -5)
	slti	a3, a2, -5
	add	a1, a1, a3	# q += 1

.if CPU_BITS == 64
	# threshold 2: diff <= -12 (i.e. < -11)
	# handles max 63-bit error (2)
	slti	a3, a2, -11
	add	a1, a1, a3	# q += 1
.endif

	# postamble: restore sign
	xor	a0, a1, t0
	sub	a0, a0, t0

	ret
.size div6, .-div6
