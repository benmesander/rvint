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
	call	mul32_test

test11:
	li	a0, 11
	li	a1, -2
	li	a2, 3
	li	a3, -1
	li	a4, -6
	call	mul32_test


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
	li	a1, 4
	li	a2, 1
	call	to_hex
	mv	a2, a1
	mv	a1, a0
	call	print
	la	a1, x
	li	a2, 3
	call	print
	mv	a0, s1
	li	a1, 4
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
	mv	s0, a1
	mv	s1, a2
	mv	s2, a3

	call	print_header	# print test number a0

	mv	a0, s0		# print the equation
	mv	a1, s1
	call	print_eqn

	mv	a0, s0		# compute the result
	mv	a1, s1
	call	nmul
	
	mv	s0, a0		# print the result
	li	a1, 4
	li	a2, 1
	call	to_hex
	mv	a2, a1
	mv	a1, a0
	call	print
	la	a1, space
	li	a2, 1
	call	print

	sub	a3, a3, s0
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
# signed flag in a3 
# expected value a3:a4
mul32_test:
	FRAME	5
	PUSH	ra, 0
	PUSH	s0, 1
	PUSH	s1, 2
	PUSH	s2, 3
	PUSH	s3, 4
	mv	s0, a1
	mv	s1, a2
	mv	s2, a3
	mv	s3, a3

	call	print_header	# print test number a0

	mv	a0, s0		# print the equation
	mv	a1, s1
	call	print_eqn

	mv	a0, s0		# compute the result
	mv	a1, s1
	mv	a2, s3
	call	mul32
	# a0 - low 32
	# a1 - high 32
	
	mv	s0, a0		# save result
	mv	s1, a1

	li	a1, 4
	li	a2, 1
	call	to_hex
	mv	a2, a1
	mv	a1, a0
	call	print

	la	a1, colon
	li	a2, 1
	call	print

	mv	a0, s1
	li	a1, 4
	li	a2, 1
	call	to_hex
	mv	a2, a1
	mv	a1, a0
	call	print

	la	a1, space
	li	a2, 1
	call 	print

	sub	a3, a3, s0
	bnez	a3, mul32_test_fail
	sub	a4, a4, s1
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
	EFRAME	5
	ret

_end:
        li	a0, 0	# exit code
        li	a7, 93	# exit syscall
        ecall




test:	.asciz	"test "
pass:	.asciz	"pass\n"
fail:	.asciz	"fail\n"
colon:	.asciz	": "
x:	.asciz	" x "
equals:	.asciz	" = "
nl:	.asciz	"\n"
space:	.asciz	" "
