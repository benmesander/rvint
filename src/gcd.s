.include "config.s"
.globl gcd
.globl lcm

.text

################################################################################
# routine: gcd
#
# Compute the greatest common divisor (gcd) of two unsigned numbers.
# 64 bit algorithm on 64-bit CPUs, 32-bit algorithm on 32-bit CPUs.
#
# input registers:
# a0 = first number (u)
# a1 = second number (v)
#
# output registers:
# a0 = gcd(u, v)
################################################################################
gcd:
	FRAME	4
	PUSH	ra, 0
	PUSH	s0, 1
	PUSH	s1, 2
	PUSH	s2, 3

	beqz	a0, gcd_return_v
	beqz	a1, gcd_return_u

	mv	s0, a0		# s0 = u
	mv	s1, a1		# s1 = v

	call	bits_ctz
	mv	s2, a0		# s2 = i
	mv	a0, s1
	call	bits_ctz	# a0 = j
	srl	s0, s0, s2	# u >>= i
	srl	s1, s1, a0	# v >>= j

	bgtu	a0, s2, gcd_loop
	mv	s2, a0
gcd_loop:			# s2 = k = min(i, j)
	bltu	s0, s1, gcd_skip_swap
	mv	a3, s1
	mv	s1, s0		# register swap s0 <> s1
	mv 	s0, a3

gcd_skip_swap:	
	sub	s1, s1, s0	# v -= u
	beqz	s1, gcd_done
	
	mv	a0, s1
	call	bits_ctz
	srl	s1, s1, a0
	j 	gcd_loop
	
gcd_done:
	sll	a0, s0, s2	# result = u << k

gcd_cleanup:	
	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	POP	s2, 3
	EFRAME	4	
	ret

gcd_return_v:
	mv	a0, a1
gcd_return_u:
	j	gcd_cleanup

.size	gcd, .-gcd
	
################################################################################
# routine: lcm
#
# Compute the least common multiple (lcm) of two unsigned numbers.
# 64 bit algorithm on 64-bit CPUs, 32-bit algorithm on 32-bit CPUs.
#
# input registers:
# a0 = u
# a1 = v
#
# output registers:
# a0 = lcm(u,v)
################################################################################
lcm:
	FRAME	3
	PUSH	ra, 0
	PUSH	s0, 1
	PUSH	s1, 2

	beqz	a0, lcm_check_a1	# check to see if both a0 and a1 are 0

lcm_start:	
	bltu	a0, a1, lcm_skip_swap

	mv	a3, a0
	mv	a0, a1		# register swap a0 <> a1
	mv 	a1, a3

lcm_skip_swap:	
	mv	s0, a0
	mv	s1, a1

	jal	gcd		# gcd result in a0
	mv	a1, a0		# divide a0 by gcd result
	mv	a0, s0
	call	divremu		# result in a0
	mv	a1, s1		# multiply by a1
	call	nmul		# result in a0

lcm_cleanup:	
	POP 	ra, 0
	POP	s0, 1
	POP	s1, 2
	EFRAME	3
	ret

lcm_check_a1:
	bnez	a1, lcm_start
	j	lcm_cleanup	# if a0, a1 both zero, return zero
	
.size lcm, .-lcm
