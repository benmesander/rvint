.include "config.s"
.include "mul-macs.s"

.globl div10u
.text

# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div10u
#
# Unsigned fast division by 10 without using M extension.
# This routine is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses a series expansion to implement division.
# Suitable for use on RV32E architectures.
#
# input registers:
# a0 = unsigned dividend (32 or 64 bits)
#
# output registers:
# a0 = quotient (unsigned)
################################################################################
div10u:
	# calculate approximate quotient q_accum = n * 0.8
	# n - (n >> 2) = 0.75n
	srli	a2, a0, 2
	sub	a1, a0, a2

	# series expansion
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

	# final adjustment: (n * 0.8) / 8 = n / 10
	srli	a1, a1, 3

	# calculate r = n - 10*q
	mul10	a2, a1, a3	# a2 = 10q
	sub	a2, a2, a0	# negative remainder

	# correction - diff < -9 implies remainder >= 10
	slti	a3, a2, -9
	add	a0, a1, a3

	ret
.size div10u, .-div10u
