.include "config.s"
.include "mul-macs.s"

.globl div3u

.text

# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div3u
#
# Unsigned fast division by 3 without using M extension.
# This routine is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses a series approximation to implement division.
# Suitable for use on RV32E architectures.
#
# input registers:
# a0 = unsigned dividend (32 or 64 bits)
#
# output registers:
# a0 = quotient (unsigned)
################################################################################
div3u:
	# 1. Series Expansion (Computes Q_est)
	#    Generates an under-estimate of N/3
	srli	a1, a0, 2		# a1 = n >> 2
	srli	a2, a0, 4		# a2 = n >> 4
	add	a1, a2, a1		# a1 = (n>>2) + (n>>4)
	srli	a2, a1, 4		
	add	a1, a2, a1		# a1 += a1 >> 4
	srli	a2, a1, 8		
	add	a1, a2, a1		# a1 += a1 >> 8
	srli	a2, a1, 16		
	add	a1, a2, a1		# a1 += a1 >> 16
.if CPU_BITS == 64
	srli	a2, a1, 32		
	add	a1, a2, a1		# a1 += a1 >> 32
.endif

	# 2. Calculate Remainder / Error Term
	#    R = N - 3*Q_est
	mul3	a2, a1, a2		# a2 = 3 * Q_est
	sub	a2, a0, a2		# a2 = N - 3*Q_est (Remainder/Error)

	# 3. Linear Correction (Branchless)
	#    Correction = floor(R / 3) approx floor((R * 11) / 32)
	mul11	a3, a2, a0		# a3 = R * 11

	#    Correction = (R * 11) >> 5
	srli	a3, a3, 5
	
	# 4. Final Addition
	add	a0, a1, a3		# Q_final = Q_est + Correction
	ret

.size div3u, .-div3u
