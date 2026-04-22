.include "config.s"
.include "mul-macs.s"

.globl div12
.text

# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div12
#
# Signed fast division by 12.
# Algorithm: abs(n) / 12 -> restore sign.
# Optimization: Defers correction until after the divide-by-4 shift, 
#               allowing a simple threshold check instead of mul12.
#
# input:  a0 = signed dividend
# output: a0 = signed quotient
################################################################################
div12:
	# preamble: compute sign mask (t0) and abs(n) (a0)
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0	# a0 = abs(n)

	# estimate quotient q3 = abs(n) / 3
	# series: 1/4 + 1/16 + 1/64 ...
	srli	a1, a0, 2
	srli	a2, a0, 4
	add	a1, a1, a2	# q = (n >> 2) + (n >> 4)
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

	# final shift: q12 = q3 / 4
	srli	a1, a1, 2	# a1 = q_est (n/12)

	# negative remainder correction
	# diff = 12q - abs(n)
	mul12	a2, a1, a3	# a2 = 12 * q (uses mul3 + slli 2)
	sub	a2, a2, a0	# a2 = 12q - abs(n)

	# threshold check: is diff <= -12?
	# -12 < -11 -> 1 (correction needed)
	slti	a3, a2, -11
	add	a1, a1, a3	# q_final = q + correction

	# postamble: restore sign
	xor	a0, a1, t0
	sub	a0, a0, t0

	ret
.size div12, .-div12
