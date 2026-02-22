.include "config.s"
.include "mul-macs.s"

.globl div11	
.text

# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div11
#
# Signed fast division by 11.
# Algorithm: abs(n) / 11 -> restore sign.
# Estimator: 3 * (n/4 - n/128) = n * 93/128.
#
# input:  a0 = signed dividend
# output: a0 = signed quotient
################################################################################
div11:
	# preamble: compute sign mask (t0) and abs(n) (a0)
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0	# a0 = abs(n)

	# estimate quotient: q = abs(n) / 11
	# base: n * 93/128 (matches previous n * 0.7265...)
	# calc: 3 * (n/4 - n/128)
	srli	a1, a0, 2
	srli	a2, a0, 7
	sub	a1, a1, a2	# a1 = n/4 - n/128
	mul3	a1, a1, a2	# a1 = 3 * a1 (uses a2 as scratch)

	# series expansion: refine to 8/11 (period 10 bits)
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

	# negative remainder correction
	# diff = 11q - abs(n)
	mul11	a2, a1, a2	# a2 = 11 * q
	sub	a2, a2, a0	# a2 = 11q - abs(n)

	# threshold check: is diff <= -11?
	# -11 < -10 -> 1 (correction needed)
	slti	a3, a2, -10
	add	a1, a1, a3	# q_final = q + correction

	# postamble: restore sign
	xor	a0, a1, t0
	sub	a0, a0, t0

	ret
.size div11, .-div11
