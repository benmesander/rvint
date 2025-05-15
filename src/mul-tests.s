.include "config.s"

.globl _start
_start:

test1:
	li	a0, 0
	call	print_header
	j	_end
	
# a1 - ptr to string to print
# a2 - # bytes to print
print:
	li	a0, 1	# stdout
	li	a7, 64	# write syscall
	ecall
	ret

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

_end:
        li	a0, 0	# exit code
        li	a7, 93	# exit syscall
        ecall




test:	.asciz	"test "
pass:	.asciz	"pass\n"
fail:	.asciz	"fail\n"
colon:	.asciz	":\n"
