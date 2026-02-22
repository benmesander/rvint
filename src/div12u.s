.include "config.s"
.include "mul-macs.s"

.globl div12u
.text

# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div12u
#
# Unsigned fast division by 12 without using M extension.
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
div12u:
	# compute approximate quotient
	# n/2 + n/8 = 0.625n
	srli	a1, a0, 1	# a1 = (n >> 1)
	srli	a2, a0, 3	# a2 = (n >> 3)
	add	a1, a1, a2	# a1 = q = (n >> 1) + (n >> 3)

	# continue series expansion
	srli	a2, a1, 4	# a2 = (q >> 4)
	add	a1, a1, a2	# a1 = q = q + (q >> 4)
	srli	a2, a1, 8	# a2 = (q >> 8)
	add	a1, a1, a2	# a1 = q = q + (q >> 8)
	srli	a2, a1, 16	# a2 = (q >> 16)
	add	a1, a1, a2	# a1 = q = q + (q >> 16)
.if CPU_BITS == 64
	srli	a2, a1, 32	# a2 = (q >> 32)
	add	a1, a1, a2	# a1 = q + (q >> 32)
.endif
	srli	a1, a1, 3

	# compute remainder
	mul12	a2, a1, a2	# a2 = q*12
	sub	a2, a2, a0	# negative remainder
	slti	a3, a2, -11
	add	a0, a1, a3	# a0 = q = q + correction
	ret

.size div12u, .-div12u
