.include "config.s"
.include "mul-macs.s"

.globl div10
.text

# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div10
#
# Signed fast division by 10.
# Algorithm: abs(n) / 10 -> restore sign.
# Core Logic: Uses the div10u series (n * 0.8 / 8).
#
# input:  a0 = signed dividend
# output: a0 = signed quotient
################################################################################
div10:
	# preamble: compute sign mask (t0) and abs(n) (a0)
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0	# a0 = abs(n)

	# estimate quotient: q = abs(n) / 10
	# target: q_accum = n * 0.8
	# start with n * 0.75
	srli	a2, a0, 2
	sub	a1, a0, a2

	# series expansion: converge 0.75 -> 0.8
	srli	a2, a1, 4
	add	a1, a1, a2	# q += q >> 4
	srli	a2, a1, 8
	add	a1, a1, a2	# q += q >> 8
	srli	a2, a1, 16
	add	a1, a1, a2	# q += q >> 16
.if CPU_BITS == 64
	srli	a2, a1, 32
	add	a1, a1, a2	# q += q >> 32
.endif

	# final adjustment: q = (n * 0.8) / 8 = n / 10
	srli	a1, a1, 3	# a1 = q_approx

	# negative remainder correction
	# diff = 10q - abs(n)
	mul10	a2, a1, a3	# a2 = 10 * q
	sub	a2, a2, a0	# a2 = 10q - abs(n)

	# threshold check: is diff <= -10?
	# -10 < -9 -> 1 (correction needed)
	slti	a3, a2, -9
	add	a1, a1, a3	# q_final = q + correction

	# postamble: restore sign
	xor	a0, a1, t0
	sub	a0, a0, t0

	ret
.size div10, .-div10
