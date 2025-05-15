.include "config.s"

.globl _start
_start:

# nmul 0 x 0 = 0
test1:
	li	a0, 1
	call	print_header
	li	a0, 0
	li	a1, 0
	call	print_eqn
	
	mv	a0, zero
	mv	a1, zero
	call	nmul
	mv	s0, a0

	li	a1, 4
	li	a2, 1
	call	to_hex

	mv	a2, a1
	mv	a1, a0
	call	print

	la	a1, space
	li	a2, 1
	call print

	bnez	s0, test1_fail
	call	print_pass
	j	test2
test1_fail:
	call	print_fail
test2:	

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
	call	to_hex
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

	mv	a0, s0
	mv	a1, s1
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
	POP	s1, 3
	EFRAME	3
	ret

_end:
        li	a0, 0	# exit code
        li	a7, 93	# exit syscall
        ecall




test:	.asciz	"test "
pass:	.asciz	"pass\n"
fail:	.asciz	"fail\n"
colon:	.asciz	":"
x:	.asciz	" x "
equals:	.asciz	" = "
nl:	.asciz	"\n"
space:	.asciz	" "
