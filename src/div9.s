.include "config.s"
.include "mul-macs.s"

.globl div9
.text

# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div9
#
# Signed fast division by 9.
# Algorithm: abs(n) / 9 -> restore sign.
# Core Logic: uses the efficient div9u series (n * 7/8 * geometric_series).
#
# input:  a0 = signed dividend (32 or 64 bits)
# output: a0 = signed quotient
################################################################################
div9:
	# preamble: compute sign mask (t0) and abs(n) (a0)
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0	# a0 = abs(n)

	# estimate quotient: q = abs(n) / 9
	# target: q_accum = n * (8/9)
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

	# negative remainder correction
	# diff = 9q - abs(n)
	mul9	a3, a1, a2	# a3 = 9 * q
	sub	a2, a3, a0	# a2 = 9q - abs(n)

	# threshold check: is diff <= -9?
	# -9 < -8 -> 1 (correction needed)
	slti	a3, a2, -8
	add	a1, a1, a3	# q_final = q + correction

	# postamble: restore sign
	xor	a0, a1, t0
	sub	a0, a0, t0

	ret
.size div9, .-div9
