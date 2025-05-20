.include "config.s"

.globl isqrt

# compute the integer square root
# a0 - input (unsigned)
# a0 - output
#
# XXX: improve efficiency by removing the multiplication
isqrt:
	FRAME	5
	PUSH	ra, 0
	PUSH	s0, 1
	PUSH	s1, 2
	PUSH	s2, 3
	PUSH	s3, 4
	
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
	# s3 - n

	li	s0, 2
	mv	s3, a0
isqrt_shift_loop:
#	srl	t0, a0, s0
#	bnez	t0, isqrt_bit_setting
#	addi	s0, s0, 2
#	j	isqrt_shift_loop
.if CPU_BITS == 64
	li	s0, 62
.else
	li	s0, 30
.endif

# fix registers below

isqrt_bit_setting:	
	li	s2, 0
isqrt_bit_setting_loop:
	bltz	s0, isqrt_done
	slli	s2, s2, 1
	addi	s1, s2, 1

	mv	a0, s1
	mv	a1, s1
	call	nmul		# large_cand * large_cand
	srl	t0, s3, s0	# t0 = n >> shift
	bgtu	a0, t0, isqrt_bit_setting_loop_end
	mv	s2, s1		# result = large_cand
	
isqrt_bit_setting_loop_end:	
	addi	s0, s0, -2	# shift -= 2
	j	isqrt_bit_setting_loop

isqrt_done:	
	mv	a0, s2

isqrt_skip:
	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	POP	s2, 3
	POP	s3, 4
	EFRAME	5
	ret

.size isqrt, .-isqrt

