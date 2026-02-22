.include "config.s"
.include "mul-macs.s"

.globl div13
.text

# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div13
#
# Signed fast division by 13.
# Algorithm: abs(n) / 13 -> restore sign.
# Core Logic: Uses the optimized div13u series (Max Error 1).
#
# input:  a0 = signed dividend
# output: a0 = signed quotient
################################################################################
div13:
	# preamble: compute sign mask (t0) and abs(n) (a0)
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0	# a0 = abs(n)

	# estimate quotient: q = abs(n) / 13
	# base: n * 5/8 * 63/64
	srli	a1, a0, 1
	srli	a2, a0, 3
	add	a1, a1, a2	# a1 = n * 0.625

	srli	a2, a1, 6
	sub	a1, a1, a2	# a1 = n * 0.61523...

	# series expansion
	srli	a2, a1, 12
	add	a1, a1, a2
	srli	a2, a1, 24
	add	a1, a1, a2
.if CPU_BITS == 64
	srli	a2, a1, 48
	add	a1, a1, a2
.endif

	# final shift: q_est = q_accum / 8
	srli	a1, a1, 3

	# negative remainder correction
	# diff = 13q - abs(n)
	mul13	a2, a1, a2	# a2 = 13 * q
	sub	a2, a2, a0	# a2 = 13q - abs(n)

	# threshold check: is diff <= -13?
	# -13 < -12 -> 1 (correction needed)
	slti	a3, a2, -12
	add	a1, a1, a3	# q_final = q + correction

	# postamble: restore sign
	xor	a0, a1, t0
	sub	a0, a0, t0

	ret
.size div13, .-div13
