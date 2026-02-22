.include "config.s"
.include "mul-macs.s"

.globl mod3u
.globl mod3

.text
	
# Below is based on Hacker's Delight 2nd Edition Chapter 10, but this routine
# and the other remainder routines I didn't implement are kind of useless 
# as it's faster to calculate the quotient and calculate the remainder from
# that. I could modify the above routines to also return the remainder in addition	
# to the quotient, which seems useful, but would likely cost 3-4
# instructions per routine. Not yet sure if I want to do this or not.

######################################################################
# routine: mod3
#
# calculate a0 % 3 (signed)
#
# input:  a0 = signed integer
# output: a0 = signed remainder
######################################################################
mod3:
	# preamble: abs(n) and save sign mask in t0
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0
	j	mod3_reduction

######################################################################
# routine: mod3u
#
# calculate a0 % 3 (unsigned)
#
# input:  a0 = unsigned integer
# output: a0 = unsigned remainder
######################################################################
mod3u:
	li	t0, 0		# sign mask = 0

mod3_reduction:
	# estimate q = n / 3
	# base: n * 5/16
	srli	a1, a0, 2
	srli	a2, a0, 4
	add	a1, a1, a2

	# series expansion (1/3)
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
	# a1 = q_est (approx n/3)

	# calculate remainder
	# diff = 3*q_est - n
	mul3	a2, a1, a2	# a2 = 3 * q_est
	sub	a2, a2, a0	# a2 = diff

	# threshold: if diff <= -3, we missed by 3
	slti	a3, a2, -2	# a3 = correction (0 or 1)

	# remainder = -diff - 3*correction
	sub	a2, zero, a2	# a2 = -diff
	mul3	a3, a3, a4	# a3 = 3 * correction
	sub	a0, a2, a3	# a0 = remainder

	# restore sign
	xor	a0, a0, t0
	sub	a0, a0, t0

	ret
.size mod3, .-mod3
.size mod3u, .-mod3u
