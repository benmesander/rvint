.include "config.s"
.include "mul-macs.s"

.globl div100
.text

# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div100
#
# Signed fast division by 100.
# Algorithm: abs(n) / 100 -> restore sign.
# Core Logic: uses the optimized div100u series (n * 0.64).
#
# input:  a0 = signed dividend
# output: a0 = signed quotient
################################################################################
div100:
	# preamble: compute sign mask (t0) and abs(n) (a0)
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0	# a0 = abs(n)

	# estimate quotient: q = abs(n) / 100
	# base: n * 0.640625 (1/2 + 1/8 + 1/64)
	srli	a1, a0, 1
	srli	a2, a0, 3
	add	a1, a1, a2
	srli	a2, a0, 6
	add	a1, a1, a2	# a1 = n * 0.640625

	# series expansion
	# correct 0.6406 -> 0.64 (factor approx 1 - 1/1024)
	srli	a2, a1, 10
	sub	a1, a1, a2

	# refine (factor 1 + 1/2^20)
	srli	a2, a1, 20
	add	a1, a1, a2

.if CPU_BITS == 64
	# refine (factor 1 + 1/2^40)
	srli	a2, a1, 40
	add	a1, a1, a2
.endif

	# final shift: (n * 0.64) / 64 = n / 100
	srli	a1, a1, 6	# a1 = q_est

	# correction
	# diff = 100q - abs(n)
	mul100	a2, a1, a3	# a2 = 100 * q
	sub	a2, a2, a0	# a2 = 100q - abs(n)

	# threshold check: is diff <= -100?
	# -100 < -99 -> 1 (correction needed)
	slti	a3, a2, -99
	add	a1, a1, a3	# q_final = q + correction

	# postamble: restore sign
	xor	a0, a1, t0
	sub	a0, a0, t0

	ret
.size div100, .-div100
