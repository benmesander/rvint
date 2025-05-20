.include "config.s"

.globl _start
_start:
	li	a0, 0
	li	a1, 9
	li	a2, 3
	call	sqrt_test

	j	_end

# test # a0
header:
	FRAME	2
	PUSH	ra, 0
	PUSH	s0, 1
	mv	s0, a0
	
	la	a1, test
	li	a2, 5
	call	print
	
	mv	a0, s0
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

# a0 test #
# a1 number
# a2 expected result
	
sqrt_test:
	FRAME	5
	PUSH	ra, 0
	PUSH	s0, 1
	PUSH	s1, 2
	PUSH	s2, 3
	PUSH	s3, 4
	mv	s0, a0
	mv	s1, a1
	mv	s2, a2

	call	header

	mv	a0, s1
	call	to_decu
	mv	a2, a1
	mv	a1, a0
	call	print

	la	a1, equals
	li	a2, 3
	call	print

	mv	a0, s1
	call	isqrt
	mv 	s3, a0
	call	to_decu
	mv	a2, a1
	mv	a1, a0
	call	print

	la	a1, space
	li	a2, 1
	call	print

	sub	s2, s2, s3
	bnez	s2, sqrt_test_fail
	la	a1, pass
	
sqrt_test_fail:
	la	a1, fail

sqrt_test_done:	
	li	a2, 5
	call	print
	
	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	POP	s2, 3
	POP	s3, 4
	EFRAME	5
	ret


# a1 - ptr to string to print
# a2 - # bytes to print
print:
	li	a0, 1	# stdout
	li	a7, 64	# write syscall
	ecall
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
