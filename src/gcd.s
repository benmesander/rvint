.include "config.s"
.globl gcd

# compute the gcd of two unsigned numbers
# input
# a0 - first number (u)
# a1 - second number (v)
# output
# a0 result

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
	xor	s0, s0, s1
	xor	s1, s0, s1	# register swap s0 <> s1
	xor	s0, s0, s1
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
	
