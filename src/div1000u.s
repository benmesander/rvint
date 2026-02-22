.include "config.s"
.include "mul-macs.s"

.globl div1000u
.text

# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div1000u
#
# Unsigned fast division by 1000 without M extension.
# Algorithm: Chained Division (n / 10) / 100.
#
# input:  a0 = unsigned dividend
# output: a0 = quotient
################################################################################	
div1000u:
	# calculate q = n / 10
	# estimator: n * 0.8
	srli	a2, a0, 2
	sub	a1, a0, a2	# a1 = n * 0.75

	# series for 0.8
	srli	a2, a1, 4
	add	a1, a1, a2
	srli	a2, a1, 8
	add	a1, a1, a2
	srli	a2, a1, 16
	add	a1, a1, a2
.if CPU_BITS == 64
	srli	a2, a1, 32
	add	a1, a1, a2
.endif
	srli	a1, a1, 3	# a1 = q_est (n/10)

	# correction for div10
	mul10	a2, a1, a3	# a2 = 10 * q
	sub	a2, a2, a0	# a2 = 10q - n
	slti	a3, a2, -9
	add	a0, a1, a3	# a0 = result of n/10

	# calculate q = a0 / 100
	# estimator: n * 0.64 (optimized series)
	# base: n * (1/2 + 1/8 + 1/64) = n * 0.640625
	srli	a1, a0, 1
	srli	a2, a0, 3
	add	a1, a1, a2
	srli	a2, a0, 6
	add	a1, a1, a2	# a1 = n * 0.640625

	# series for 0.64
	srli	a2, a1, 10
	sub	a1, a1, a2	# correct 0.6406 -> 0.64
	srli	a2, a1, 20
	add	a1, a1, a2	# refine
.if CPU_BITS == 64
	srli	a2, a1, 40
	add	a1, a1, a2
.endif
	srli	a1, a1, 6	# a1 = q_est (n/1000)

	# correction for div100
	mul100	a2, a1, a3	# a2 = 100 * q
	sub	a2, a2, a0	# a2 = 100q - n
	slti	a3, a2, -99
	add	a0, a1, a3	# a0 = final result

	ret
.size div1000u, .-div1000u
