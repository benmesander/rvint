.include "config.s"

.text
	
.globl _start
_start:
	li	a0, 0
	li	a1, 9
	li	a2, 3
	call	sqrt_test

.if CPU_BITS == 64
	li	a0, 1
	li	a1, 92423004303
	li	a2, 304011
	call	sqrt_test
.endif

	li	a0, 2
	li	a1, 40
	li	a2, 30
	li	a3, 10
	call	gcd_test

	li	a0, 3
	li	a1, 2390842
	li	a2, 4234
	li	a3, 2
	call	gcd_test


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
	mv	s2, a2	# expected result

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
	mv 	s3, a0		# caculated result
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

sqrt_test_fail:
	la	a1, fail
	j	sqrt_test_done


# input
# a0 test #
# a1 u
# a2 v
# a3 expected gcd
gcd_test:

	FRAME	5
	PUSH	ra, 0
	PUSH	s0, 1
	PUSH	s1, 2
	PUSH	s2, 3
	PUSH	s3, 4
	mv	s1, a1
	mv	s2, a2
	mv 	s3, a3

	call	header

	mv	a0, s1
	call	to_decu
	mv	a2, a1
	mv	a1, a0
	call	print

	la	a1, space
	li	a2, 1
	call	print

	mv	a0, s2
	call	to_decu
	mv	a2, a1
	mv	a1, a0
	call	print

	la	a1, equals
	li	a2, 3
	call	print

	mv	a0, s1
	mv	a1, s2
	call	gcd
	mv	s2, a0

	call	to_decu
	mv	a2, a1
	mv	a1, a0
	call	print

	la	a1, space
	li	a2, 1
	call	print

	sub	s2, s2, s3
	bnez	s2, gcd_test_fail
	la	a1, pass

gcd_test_done:
	li	a2, 5
	call	print

	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	POP	s2, 3
	POP	s3, 4
	EFRAME	5
	ret

gcd_test_fail:
	la	a1, fail
	j	gcd_test_done
	

	

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
