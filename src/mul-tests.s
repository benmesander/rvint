.include "config.s"

.globl _start
_start:

# nmul 0 x 0 = 0
test1:
	li	a0, 1
	li	a1, 0
	li	a2, 0
	li	a3, 0
	call	nmul_test

test2:	
	li	a0, 2
	li	a1, 0
	li	a2, 0x12345678
	li	a3, 0
	call	nmul_test

test3:	
	li	a0, 3
	li	a1, 0x12345678
	li	a2, 0
	li	a3, 0
	call	nmul_test

test4:
	li	a0, 4
	li	a1, 0xabcdef01
	li	a2, 1
	li	a3, 0xabcdef01
	call	nmul_test

test5:
	li	a0, 5
	li	a1, 1
	li	a2, 0xabcdef01
	li	a3, 0xabcdef01
	call	nmul_test

test6:
	li	a0, 6
	li	a1, 2
	li	a2, 3
	li	a3, 6
	call	nmul_test

test7:
	li	a0, 7
	li	a1, 0xf0
	li	a2, 0xf0
	li	a3, 0xe100
	call	nmul_test

test8:
	li	a0, 8
	li	a1, 0xffff
	li	a2, 0xffff
	li	a3, 0xfffe0001
	call	nmul_test

test9:
	li	a0, 9
	li	a1, 0x10000
	li	a2, 0xffff
	li	a3, 0xffff0000
	call	nmul_test

test10:
	li	a0, 10
	li	a1, 0
	li	a2, 0
	li	a3, 0
	li	a4, 0
	li	a5, 0
	call	mul32_test

test11:
	li	a0, 11
	li	a1, -2
	li	a2, 3
	li	a3, -6
.if CPU_BITS == 64
	slli	a3, a3, 32
	srli	a3, a3, 32
.endif
	li	a4, -1
.if CPU_BITS == 64
	slli	a4, a4, 32
	srli	a4, a4, 32
.endif
	li	a5, 1
	call	mul32_test

test12:
	li	a0, 12
	li	a1, 2
	li	a2, -3
	li	a3, -6
.if CPU_BITS == 64
	slli	a3, a3, 32
	srli	a3, a3, 32
.endif
	li	a4, -1
.if CPU_BITS == 64
	slli	a4, a4, 32
	srli	a4, a4, 32
.endif
	li	a5, 1
	call	mul32_test
	
test13:
	li	a0, 13
	li	a1, -2
	li	a2, -3
	li	a3, 6
	li	a4, 0
	li	a5, 1
	call	mul32_test

test14:
	li	a0, 14
	li	a1, 2
	li	a2, 3
	li	a3, 6
	li	a4, 0
	li	a5, 0
	call	mul32_test

.if CPU_BITS == 64
test15:	
	li	a0, 15
	li	a1, 0
	li	a2, 0
	li	a3, 0
	li	a4, 0
	li	a5, 0
	call	mul128_test

test16:
	li	a0, 16
	li	a1, -1
	li	a2, -245
	li	a3, 0
	li	a4, 245
	li	a5, 1
	call	mul128_test

test17:
	li	a0, 17
	li	a1, -1223
	li	a2, -245
	li	a3, 0
	li	a4, 0x49273
	li	a5, 0
	call	mul128_test

.endif
	j	_end
	
# a1 - ptr to string to print
# a2 - # bytes to print
print:
	li	a0, 1	# stdout
	li	a7, 64	# write syscall
	ecall
	ret

print_pass:
	la	a1, pass
	li	a2, 5
	j	print

print_fail:
	la	a1, fail
	li	a2, 5
	j	print

print_header:
	FRAME	2
	PUSH	ra, 0
	PUSH	s0, 1
	mv	s0, a0
	la	a1, test
	li	a2, 5
	call	print
	mv	a0, s0
	li	a1, 1
	li	a2, 1
	call	to_decu
	mv	a2, a1
	mv	a1, a0
	call	print
	la	a1, colon
	li	a2, 2
	call	print
	POP	ra, 0
	POP	s0, 1
	EFRAME	2
	ret

# a0 x a1 =
print_eqn:
	FRAME	3
	PUSH	ra, 0
	PUSH	s0, 1
	PUSH	s1, 2

	mv	s0, a0
	mv	s1, a1
	li	a1, CPU_BYTES
	li	a2, 1
	call	to_hex
	mv	a2, a1
	mv	a1, a0
	call	print
	la	a1, x
	li	a2, 3
	call	print
	mv	a0, s1
	li	a1, CPU_BYTES
	li	a2, 1
	call	to_hex
	mv	a2, a1
	mv	a1, a0
	call	print
	la	a1, equals
	li	a2, 3
	call	print

	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	EFRAME	3
	ret

# test # a0
# compute a1 * a2
# expected value a3
nmul_test:
	FRAME	4
	PUSH	ra, 0
	PUSH	s0, 1
	PUSH	s1, 2
	PUSH	s2, 3
	mv	s0, a1		# multiplicand
	mv	s1, a2		# multiplier
	mv	s2, a3		# expected result

	call	print_header	# print test number a0

	mv	a0, s0		# print the equation
	mv	a1, s1
	call	print_eqn

	mv	a0, s0		# compute the result
	mv	a1, s1
	call	nmul
	
	mv	s0, a0		# print the result
	li	a1, CPU_BYTES
	li	a2, 1
	call	to_hex
	mv	a2, a1
	mv	a1, a0
	call	print
	la	a1, space
	li	a2, 1
	call	print

	sub	a3, s2, s0
	bnez	a3, nmul_test_fail

	call	print_pass
	j	nmul_test_done
	
nmul_test_fail:	
	call	print_fail
	
nmul_test_done:
	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	POP	s2, 3
	EFRAME	4
	ret

# test # a0
# compute a1 * a2
# expected value a3:a4
# signed flag: a5
mul32_test:
	FRAME	6
	PUSH	ra, 0
	PUSH	s0, 1
	PUSH	s1, 2
	PUSH	s2, 3
	PUSH	s3, 4
	PUSH	s4, 5

	mv	s0, a1		# multiplier
	mv	s1, a2		# multiplicand
	mv	s2, a3		# expected value lo
	mv	s3, a4		# expected value hi
	mv	s4, a5		# signed flag

	call	print_header	# print test number a0

	mv	a0, s0		# print the equation
	mv	a1, s1
	call	print_eqn

	mv	a0, s0		# compute the result
	mv	a1, s1
	mv	a2, s4
	call	mul32
	# a0 - low 32
	# a1 - high 32
	mv	s0, a0		# save result
	mv	s1, a1


	mv	a0, a1
	li	a1, CPU_BYTES
	li	a2, 1
	call	to_hex
	mv	a2, a1
	mv	a1, a0
	call	print

	la	a1, colon
	li	a2, 1
	call	print

	mv	a0, s0
	li	a1, CPU_BYTES
	li	a2, 1
	call	to_hex
	mv	a2, a1
	mv	a1, a0
	call	print

	la	a1, space
	li	a2, 1
	call 	print

	sub	a3, s2, s0
	bnez	a3, mul32_test_fail
	sub	a4, s3, s1
	bnez	a4, mul32_test_fail

	call	print_pass
	j	mul32_test_done
	
mul32_test_fail:	
	call	print_fail
	
mul32_test_done:
	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	POP	s2, 3
	POP	s3, 4
	POP	s4, 5
	EFRAME	6
	ret

_end:
        li	a0, 0	# exit code
        li	a7, 93	# exit syscall
        ecall

.if CPU_BITS == 64
# test # a0
# compute a1 * a2
# expected value a3:a4
mul128_test:
	FRAME	6
	PUSH	ra, 0
	PUSH	s0, 1
	PUSH	s1, 2
	PUSH	s2, 3
	PUSH	s3, 4
	PUSH	s4, 5
	mv	s0, a1		# multiplicand
	mv	s1, a2		# multiplier
	mv	s2, a3		# expected value lo
	mv	s3, a4		# expected value high
	mv	s4, a4		# signedness (0 unsigned, 1 signed)

	call	print_header	# print test number a0

	mv	a0, s0		# print the equation
	mv	a1, s1
	call	print_eqn
	

	mv	a0, s0
	mv	a1, s1
	mv	a2, s4
	call	m128
	mv	s0, a0		# product lo
	mv	s1, a1		# product hi

	mv	a0, s1
	li	a1, 8
	li	a2, 1
	call	to_hex

	mv	a2, a1
	mv	a1, a0
	call	print

	la	a1, colon
	li	a2, 1
	call	print
	
	mv	a0, s0
	li	a1, 8
	li	a2, 1
	call	to_hex

	mv	a2, a1
	mv	a1, a0
	call	print
	
	la	a1, space
	li	a2, 1
	call	print

	sub	a3, s2, s1
	bnez	a3, mul_128_fail
	sub	a4, s3, s0
	bnez	a4, mul_128_fail

	call	print_pass
	j	mul_128_cleanup
mul_128_fail:	
	call	print_fail
mul_128_cleanup:	
	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	POP	s2, 3
	POP	s3, 4
	POP	s4, 5
	EFRAME	6
	ret
.endif


test:	.asciz	"test "
pass:	.asciz	"pass\n"
fail:	.asciz	"fail\n"
colon:	.asciz	": "
x:	.asciz	" x "
equals:	.asciz	" = "
nl:	.asciz	"\n"
space:	.asciz	" "
