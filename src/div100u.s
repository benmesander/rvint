.include "config.s"
.include "mul-macs.s"

.globl div100u
.text

# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div100u
#
# Unsigned fast division by 100.
# Algorithm: Direct series expansion for 0.64.
# Base: 0.5 + 0.125 + 0.015625 = 0.640625.
# Series: 1 - 1/1024 + 1/2^20...
#
# input:  a0 = unsigned dividend
# output: a0 = quotient
################################################################################	
div100u:
	# estimator: q = n * 0.64
	# base: n * (1/2 + 1/8 + 1/64)
	srli	a1, a0, 1
	srli	a2, a0, 3
	add	a1, a1, a2
	srli	a2, a0, 6
	add	a1, a1, a2	# a1 = n * 0.640625

	# series expansion
	# correct 0.640625 -> 0.64 (factor is approx 1 - 1/1024)
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
	srli	a1, a1, 6	# q_est

	# correction
	# calculate negative remainder: diff = 100q - n
	mul100	a2, a1, a3	# a2 = 100 * q
	sub	a2, a2, a0	# a2 = 100q - n

	# threshold: if diff <= -100 (i.e. < -99), add 1
	slti	a3, a2, -99
	add	a0, a1, a3	# q + correction

	ret
.size div100u, .-div100u
