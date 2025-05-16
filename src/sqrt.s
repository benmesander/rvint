.include "config.s"

.globl isqrt

# compute the integer square root
# a0 - input (unsigned)
# a0 - output

isqrt:
	FRAME	4
	PUSH	ra, 0
	PUSH	s0, 1
	PUSH	s1, 2
	PUSH	s2, 3
	
	li	t0, 2
	blt	a0, t0, isqrt_skip

	# compute using digit by digit algorithm, https://en.wikipedia.org/wiki/Integer_square_root
	# register usage:
	# a0 - n
	# 
	# t0 - scratch
	# s0 - shift
	# s1 - large_cand
	# s2 - result

	li	s0, 2
isqrt_shift_loop:
	srl	t0, a0, s0
	bnez	t0, isqrt_bit_setting
	addi	s0, s0, 2
	j	isqrt_shift_loop

# fix registers below

isqrt_bit_setting:	
	li	s2, 0
isqrt_bit_setting_loop:
	bge	s0, zero, isqrt_done
	slli	s2, s2, 1
	addi	s1, s2, 1

	# xxx: set up stuff
	call	nmul
	


isqrt_done:	
	mv	a0, s2
isqrt_skip:
	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	POP	s2, 3
	EFRAME	4
	ret

.size isqrt, .-isqrt

