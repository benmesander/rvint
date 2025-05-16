.include "config.s"

.globl isqrt

# compute the integer square root
# a0 - input (unsigned)
# a0 - output

isqrt:
	li	t1, 2
	blt	a0, t1, isqrt_skip

	# compute using digit by digit algorithm, https://en.wikipedia.org/wiki/Integer_square_root
	# register usage:
	# a0 - n
	# t0 - shift
	# t1 - temporary
	# t2 - large_cand
	# t3 - result

	li	t0, 2
isqrt_shift_loop:
	srl	t1, a0, t0
	bnez	t1, isqrt_bit_setting
	addi	t0, t0, 2
	j	isqrt_shift_loop

isqrt_bit_setting:	
	li	t3, 0
isqrt_bit_setting_loop:
	bge	t0, zero, xxx
	


isqrt_done:	
	mv	a0, t3
isqrt_skip:
	ret

.size isqrt, .-isqrt

