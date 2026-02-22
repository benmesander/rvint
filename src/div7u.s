.include "config.s"
.include "mul-macs.s"

.globl div7u

.text

# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div7u
#
# Unsigned fast division by 7 without using M extension.
# This routine is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses a series expansion algorithm to implement division.
# Suitable for use on RV32E architectures.
#
# input registers:
# a0 = unsigned dividend (32 or 64 bits)
#
# output registers:
# a0 = quotient (unsigned)
################################################################################
div7u:
	srli	a1, a0, 1	# a1 = (n >> 1)
	srli	a2, a0, 4	# a2 = (n >> 4)
	add	a1, a1, a2	# a1 = q = (n >> 1) + (n >> 4)
	srli	a2, a1, 6	# a2 = (q >> 6)
	add	a1, a1, a2	# a1 = q = q + (q >> 6)
	srli	a2, a1, 12	# a2 = (q >> 12)
	add	a1, a1, a2
	srli	a2, a1, 24	# a2 = (q >> 24)
	add	a1, a1, a2	# a1 = q + (q >> 24)
.if CPU_BITS == 64
	srli	a2, a1, 48	# a2 = (q >> 48)
	add	a1, a1, a2	# a1 = q + (q >> 48)
.endif
	srli	a1, a1, 2	# a1 = q >> 2

	slli	a2, a1, 3	# (q * 8)
	sub	a2, a2, a1	# a3 = (q * 7) = (q * 8) - q
	sub	a2, a2, a0	# negative remainder
	slti	a3, a2, -6
	add	a0, a1, a3	# correct quotient
.if CPU_BITS == 64
	# Correction Step 2 (64-bit only): Add another 1 if diff <= -14
	# We reuse the original diff in a2
	slti	a3, a2, -13
	add	a0, a0, a3
.endif
	ret

.size	div7u, .-div7u
