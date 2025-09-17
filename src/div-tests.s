.include "config.s"
.text
	
# runs on linux

# Test Categories:
# Basic Division (small numbers)
# Zero Dividend
# Zero Divisor
# Divisor Greater than Dividend
# Negative Dividend or Divisor
# Large Dividend and Divisor
#
# Test Case Structure:
# Each test case will:
# Load values into registers.
# Call the function under test.

.globl _start

_start:

	# 1. Basic Division (Dividend = 10, Divisor = 3)
	# Expected Result: Quotient = 3, Remainder = 1 (since 10 ÷ 3 = 3 remainder 1)

test1:
	la	a1, test1s
	li	a2, 7
	call	title

	li	a0, 10		# Load dividend (10) into a0
	li	a1, 3		# Load divisor (3) into a1
	jal	divremu		# Call divremu

	# Check results
	# a0 (quotient) should be 3
	# a1 (remainder) should be 1

	addi	a0, a0, -3
	bnez	a0, test1_fail
	addi	a1, a1, -1
	bnez	a1, test1_fail

	la	a1, pass
	call	result
	
	j	test2

test1_fail:

	la	a1, fail
	call	result
	
test2:

	# 2. Zero Dividend (Dividend = 0, Divisor = 3)
	# Expected Result: Quotient = 0, Remainder = 0 (since 0 ÷ 3 = 0 remainder 0)

	la	a1, test2s
	li	a2, 7
	call	title

	li	a0, 0		# Load dividend (0) into a0
	li	a1, 3		# Load divisor (3) into a1
	jal	divremu		# Call divremu

	# Check results
	# a0 (quotient) should be 0
	# a1 (remainder) should be 0

	bnez	a0, test2_fail
	bnez	a1, test2_fail

	la	a1, pass
	call	result

	j	test3

test2_fail:

	la	a1, fail
	call	result

test3:

	# 3. Zero Divisor (Dividend = 10, Divisor = 0)
	# Expected Result: Division by zero returns Qoutient = 0, Remainder = 0

	la	a1, test3s
	li	a2, 7
	call	title

	li	a0, 10		# Load dividend (10) into a0
	li	a1, 0		# Load divisor (0) into a1
	jal	divremu		# Call divremu

	# Check results
	# a0 (quotient) should be -1
	# a1 (remainder) should be 10

	addi	a1, a1, -10
	bnez	a1, test3_fail
	addi	a0, a0, 1
	bnez	a0, test3_fail

	la	a1, pass
	call	result

	j	test4

test3_fail:

	la	a1, fail
	call	result

test4:

	# 4. Divisor Greater than Dividend (Dividend = 3, Divisor = 10)
	# Expected Result: Quotient = 0, Remainder = 3 (since 3 ÷ 10 = 0 remainder 3)

	la	a1, test4s
	li	a2, 7
	call	title

	li	a0, 3		# Load dividend (3) into a0
	li	a1, 10		# Load divisor (10) into a1
	jal	divremu		# Call divremu

	# Check results
	# a0 (quotient) should be 0
	# a1 (remainder) should be 3

	bnez	a0, test4_fail
	addi	a1, a1, -3
	bnez	a1, test4_fail

	la	a1, pass
	call	result
	j	test5

test4_fail:
	la	a1, fail
	call	result

test5:

	# 5. Negative Dividend (Dividend = -10, Divisor = 3)
	# Expected Result: Quotient = -3, Remainder = -1 (since -10 ÷ 3 = -3 remainder -1)

	la	a1, test5s
	li	a2, 7
	call	title

	li	a0, -10		# Load dividend (-10) into a0
	li	a1, 3		# Load divisor (3) into a1
	jal	divrem		# Call divrem
	
	# Check results
	# a0 (quotient) should be -3
	# a1 (remainder) should be 1
	
	addi	a0, a0, 3
	bnez	a0, test5_fail
	addi	a1, a1, 1
	bnez	a1, test5_fail
	
	la	a1, pass
	call	result
	j	test6
	
test5_fail:
	la	a1, fail
	call	result

test6:

	# 6. Negative Divisor (Dividend = 10, Divisor = -3)
	# Expected Result: Quotient = -3, Remainder = -1 (since 10 ÷ -3 = -3 remainder -1)

	la	a1, test6s
	li	a2, 7
	call	title
	
	li	a0, 10		# Load dividend (10) into a0
	li	a1, -3		# Load divisor (-3) into a1
	jal	divrem		# Call divrem

	# Check results
	# a0 (quotient) should be -3
	# a1 (remainder) should be -1
	
	addi	a0, a0, 3
	bnez	a0, test6_fail
	addi	a1, a1, 1
	bnez	a0, test6_fail

	la	a1, pass
	call	result

	j	test7

test6_fail:
	la	a1, fail
	call	result

test7:

	# 7. Both Dividend and Divisor Negative (Dividend = -10, Divisor = -3)
	# Expected Result: Quotient = 3, Remainder = -1 (since -10 ÷ -3 = 3 remainder -1)

	la	a1, test7s
	li	a2, 7
	call	title

	li	a0, -10		# Load dividend (-10) into a0
	li	a1, -3		# Load divisor (-3) into a1
	jal	divrem		# Call divrem

	# Check results
	# a0 (quotient) should be 3
	# a1 (remainder) should be -1

	addi	a0, a0, -3
	bnez	a0, test7_fail
	addi	a1, a1, 1
	bnez	a1, test7_fail

	la	a1, pass
	call	result

	j	test8

test7_fail:
	la	a1, fail
	call	result

test8:

	# 8. Large Dividend (Dividend = 123456, Divisor = 123)
	# Expected Result: Quotient = 1007, Remainder = 105 (since 123456 ÷ 123 = 1007 remainder 105)

	la	a1, test8s
	li	a2, 7
	call	title

	li	a0, 123456	# Load dividend (123456) into a0
	li	a1, 123		# Load divisor (123) into a1
	jal	divremu		# Call divremu

	# Check results
	# a0 (quotient) should be 1003
	# a1 (remainder) should be 87

	addi	a0, a0, -1003
	bnez	a0, test8_fail
	addi	a1, a1, -87
	bnez	a1, test8_fail

	la	a1, pass
	call	result

	j	test9

test8_fail:

	la	a1, fail
	call	result

test9:

	# 9. Edge Case: Large Dividend and Divisor (Dividend = 1024, Divisor = 2)
	# Expected Result: Quotient = 512, Remainder = 0 (since 1024 ÷ 2 = 512 remainder 0)

	la	a1, test9s
	li	a2, 7
	call	title

	li	a0, 1024	# Load dividend (1024) into a0
	li	a1, 2		# Load divisor (2) into a1
	jal	divremu		# Call divremu

	# Check results
	# a0 (quotient) should be 512
	# a1 (remainder) should be 0

	addi	a0, a0, -512
	bnez	a0, test9_fail
	bnez	a1, test9_fail

	la	a1, pass
	call	result
	j	test10

test9_fail:
	la	a1, fail
	call	result

test10:

	# 10. Maximum Dividend (Dividend = MAX_INT, Divisor = 1)
	# Expected Result: Quotient = MAX_INT, Remainder = 0 (since MAX_INT ÷ 1 = MAX_INT remainder 0)

	la	a1, test10s
	li	a2, 8
	call	title

	li	a0, 2147483647	# Load maximum 32-bit signed integer into a0
	li	a1, 1		# Load divisor (1) into a1
	jal	divremu		# Call divremu

	# Check results
	# a0 (quotient) should be 2147483647
	# a1 (remainder) should be 0

	li	a2, -2147483647
	add	a0, a0, a2
	bnez	a0, test10_fail
	bnez	a1, test10_fail

	la	a1, pass
	call	result
	j	test11

test10_fail:

	la	a1, fail
	call	result

test11:

	# 11. hashtable test
	# Expected Result: Quotient = 4, Remainder = 21

	la	a1, test11s
	li	a2, 8
	call	title

	li	a0, 433
	li	a1, HASHENTRIES	# 103

	jal	divremu		# Call divremu

	# Check results
	# a0 (quotient) should be 4
	# a1 (remainder) should be 21
	mv	s0, a0
	mv	s1, a1
	call	to_decu
	mv	a2, a1
	mv	a1, a0
	call	print
	la	a1, space
	li	a2, 1
	call	print
	mv	a0, s1
	call	to_decu
	mv	a2, a1
	mv	a1, a0
	call	print
	la	a1, space
	li	a2, 1
	call	print

	mv	a0, s0
	mv	a1, s1
	addi	a0, a0, -4
	bnez	a0, test11_fail
	addi	a1, a1, -21
	bnez	a1, test11_fail

	la	a1, pass
	call	result
	j	div3u_tests

test11_fail:

	la	a1, fail
	call	result

# --- div3u tests ---

div3u_tests:
	# Test 1: 0
	li	a0, 0
	li	a1, 0
	call	div3u_test_case
	# Test 2: 1
	li	a0, 1
	li	a1, 0
	call	div3u_test_case
	# Test 3: 2
	li	a0, 2
	li	a1, 0
	call	div3u_test_case
	# Test 4: 3
	li	a0, 3
	li	a1, 1
	call	div3u_test_case
	# Test 5: 0x7fffffff
	li	a0, 0x7fffffff
	li	a1, 0x2aaaaaaa
	call	div3u_test_case
	# Test 6: 0x80000000
	li	a0, 0x80000000
	li	a1, 0x2aaaaaaa
	call	div3u_test_case
	# Test 7: 0xffffffff
	li	a0, 0xffffffff
	li	a1, 0x55555555
	call	div3u_test_case

.if CPU_BITS == 64
	# 64-bit test values
	# Test 8: 0x100000000
	li	a0, 0x100000000
	li	a1, 0x55555555
	call	div3u_test_case
	# Test 9: 0x7fffffffffffffff
	li	a0, 0x7fffffffffffffff
	li	a1, 0x2aaaaaaaaaaaaaaa
	call	div3u_test_case
	# Test 10: 0x8000000000000000
	li	a0, 0x8000000000000000
	li	a1, 0x2aaaaaaaaaaaaaaa
	call	div3u_test_case
	# Test 11: 0xffffffffffffffff
	li	a0, -1
	li	a1, 0x5555555555555555
	call	div3u_test_case
.endif
	j	div10u_tests

#
# a0 = value to divide, a1 = expected result
#
div3u_test_case:
	FRAME	1
	PUSH	ra, 0
	# Save input and expected value in s-registers
	mv	s0, a0		# input
	mv	s1, a1		# expected

	# Print test number
	la	t3, div3u_test_counter
	lw	t6, 0(t3)
	addi	t6, t6, 1
	sw	t6, 0(t3)
	mv	a0, t6
	call	to_decu
	mv	a2, a1
	mv	a1, a0
	call	print

	# Print label
	la	a1, colon
	li	a2, 2
	call	print
	la	a1, div3u_label
	li	a2, 6
	call	print

	# Print input in hex
.if CPU_BITS == 64
	li	a1, 8
.else
	li	a1, 4
.endif
	li	a2, 1
	mv	a0, s0
	call	to_hex
	mv	a2, a1
	mv	a1, a0
	call	print
	la	a1, space
	li	a2, 1
	call	print

	# Call div3u
	mv	a0, s0
	call	div3u
	mv	s2, a0		# result

	# Print result in hex
.if CPU_BITS == 64
	li	a1, 8
.else
	li	a1, 4
.endif
	li	a2, 1
	mv	a0, s2
	call	to_hex
	mv	a2, a1
	mv	a1, a0
	call	print
	la	a1, space
	li	a2, 1
	call	print

	# Compare result to expected (s1)
	mv	a0, s2
	mv	a1, s1
	bne	a0, a1, div3u_fail
	la	a1, pass
	call	result
	POP 	ra, 0
	EFRAME 	1
	ret

div3u_fail:
	# Print expected value in hex
.if CPU_BITS == 64
	li	a1, 8
.else
	li	a1, 4
.endif
	li	a2, 1
	mv	a0, s1
	call	to_hex
	mv	a2, a1
	mv	a1, a0
	call	print
	la	a1, space
	li	a2, 1
	call	print
	la	a1, fail
	call	result
	POP 	ra,0
	EFRAME 	1
	ret

# --- div10u tests ---
div10u_tests:
	# Test 1: 0 / 10 = 0
	li	a0, 0
	li	a1, 0
	call	div10u_test_case

	# Test 2: 9 / 10 = 0
	li	a0, 9
	li	a1, 0
	call	div10u_test_case

	# Test 3: 10 / 10 = 1
	li	a0, 10
	li	a1, 1
	call	div10u_test_case

	# Test 4: 19 / 10 = 1
	li	a0, 19
	li	a1, 1
	call	div10u_test_case

	# Test 5: 123 / 10 = 12
	li	a0, 123
	li	a1, 12
	call	div10u_test_case

	# Test 6: 0x7fffffff / 10 = 214748364
	li	a0, 0x7fffffff
	li	a1, 214748364
	call	div10u_test_case

	# Test 7: 0x80000000 / 10 = 214748364
	li	a0, 0x80000000
	li	a1, 214748364
	call	div10u_test_case

	# Test 8: 0xffffffff / 10 = 429496729
	li	a0, 0xffffffff
	li	a1, 429496729
	call	div10u_test_case

.if CPU_BITS == 64
	# 64-bit test cases
	# Test 9: 0x100000000 / 10 = 0x19999999
	li	a0, 0x100000000
	li	a1, 0x19999999
	call	div10u_test_case

	# Test 10: 0x7fffffffffffffff / 10 = 0xcccccccccccccc
	li	a0, 0x7fffffffffffffff
	li	a1, 0x0ccccccccccccccc
	call	div10u_test_case
	
	# Test 11: 0xffffffffffffffff / 10 = 0x1999999999999999
	li	a0, -1
	li	a1, 0x1999999999999999
	call	div10u_test_case
.endif

	j	div5u_tests

#
# a0 = value to divide, a1 = expected result
#
div10u_test_case:
	FRAME	1
	PUSH	ra, 0
	# Save input and expected value
	mv	s0, a0		# input n
	mv	s1, a1		# expected quotient

	# Print test number
	la	t3, div10u_test_counter
	lw	t6, 0(t3)
	addi	t6, t6, 1
	sw	t6, 0(t3)
	mv	a0, t6
	call	to_decu
	mv	a2, a1
	mv	a1, a0
	call	print

	# Print label
	la	a1, colon
	li	a2, 2
	call	print
	la	a1, div10u_label
	li	a2, 8
	call	print

	# Print input in hex
.if CPU_BITS == 64
	li	a1, 8
.else
	li	a1, 4
.endif
	li	a2, 1
	mv	a0, s0
	call	to_hex
	mv	a2, a1
	mv	a1, a0
	call	print
	la	a1, space
	li	a2, 1
	call	print
	
	# Call div10u
	mv	a0, s0
	call	div10u
	mv	s2, a0		# result

	# Print result in hex
.if CPU_BITS == 64
	li	a1, 8
.else
	li	a1, 4
.endif
	li	a2, 1
	mv	a0, s2
	call	to_hex
	mv	a2, a1
	mv	a1, a0
	call	print
	la	a1, space
	li	a2, 1
	call	print
	
	# Check result
	mv	a0, s2
	bne	a0, s1, div10u_fail

	# Pass
	la	a1, pass
	call	result
	POP	ra, 0
	EFRAME	1
	ret

div10u_fail:
	# Print expected value in hex
.if CPU_BITS == 64
	li	a1, 8
.else
	li	a1, 4
.endif
	li	a2, 1
	mv	a0, s1
	call	to_hex
	mv	a2, a1
	mv	a1, a0
	call	print
	la	a1, space
	li	a2, 1
	call	print
	la	a1, fail
	call	result
	POP	ra, 0
	EFRAME	1
	ret

# --- div5u tests ---
div5u_tests:
	# Test 1: 0 / 5 = 0
	li	a0, 0
	li	a1, 0
	call	div5u_test_case

	# Test 2: 1 / 5 = 0
	li	a0, 1
	li	a1, 0
	call	div5u_test_case

	# Test 3: 4 / 5 = 0
	li	a0, 4
	li	a1, 0
	call	div5u_test_case

	# Test 4: 5 / 5 = 1
	li	a0, 5
	li	a1, 1
	call	div5u_test_case

	# Test 5: 9 / 5 = 1
	li	a0, 9
	li	a1, 1
	call	div5u_test_case

	# Test 6: 10 / 5 = 2
	li	a0, 10
	li	a1, 2
	call	div5u_test_case

	# Test 7: 123 / 5 = 24
	li	a0, 123
	li	a1, 24
	call	div5u_test_case

	# Test 8: 0x7fffffff / 5 = 0x19999999
	li	a0, 0x7fffffff
	li	a1, 0x19999999
	call	div5u_test_case

	# Test 9: 0x80000000 / 5 = 0x19999999
	li	a0, 0x80000000
	li	a1, 0x19999999
	call	div5u_test_case

	# Test 10: 0xffffffff / 5 = 0x33333333
	li	a0, 0xffffffff
	li	a1, 0x33333333
	call	div5u_test_case

.if CPU_BITS == 64
	# 64-bit test cases
	# Test 11: 0x100000000 / 5 = 0x33333333
	li	a0, 0x100000000
	li	a1, 0x33333333
	call	div5u_test_case

	# Test 12: 0x7fffffffffffffff / 5 = 0x1999999999999999
	li	a0, 0x7fffffffffffffff
	li	a1, 0x1999999999999999
	call	div5u_test_case

	# Test 13: 0x8000000000000000 / 5 = 0x1999999999999999
	li	a0, 0x8000000000000000
	li	a1, 0x1999999999999999
	call	div5u_test_case

	# Test 14: 0xffffffffffffffff / 5 = 0x3333333333333333
	li	a0, -1
	li	a1, 0x3333333333333333
	call	div5u_test_case
.endif

	j	_end

#
# a0 = value to divide, a1 = expected result
#
div5u_test_case:
	FRAME	1
	PUSH	ra, 0
	# Save input and expected value
	mv	s0, a0		# input n
	mv	s1, a1		# expected quotient

	# Print test number
	la	t3, div5u_test_counter
	lw	t6, 0(t3)
	addi	t6, t6, 1
	sw	t6, 0(t3)
	mv	a0, t6
	call	to_decu
	mv	a2, a1
	mv	a1, a0
	call	print

	# Print label
	la	a1, colon
	li	a2, 2
	call	print
	la	a1, div5u_label
	li	a2, 7
	call	print

	# Print input in hex
.if CPU_BITS == 64
	li	a1, 8
.else
	li	a1, 4
.endif
	li	a2, 1
	mv	a0, s0
	call	to_hex
	mv	a2, a1
	mv	a1, a0
	call	print
	la	a1, space
	li	a2, 1
	call	print
	
	# Call div5u
	mv	a0, s0
	call	div5u
	mv	s2, a0		# result

	# Print result in hex
.if CPU_BITS == 64
	li	a1, 8
.else
	li	a1, 4
.endif
	li	a2, 1
	mv	a0, s2
	call	to_hex
	mv	a2, a1
	mv	a1, a0
	call	print
	la	a1, space
	li	a2, 1
	call	print
	
	# Check result
	mv	a0, s2
	bne	a0, s1, div5u_fail

	# Pass
	la	a1, pass
	call	result
	POP	ra, 0
	EFRAME	1
	ret

div5u_fail:
	# Print expected value in hex
.if CPU_BITS == 64
	li	a1, 8
.else
	li	a1, 4
.endif
	li	a2, 1
	mv	a0, s1
	call	to_hex
	mv	a2, a1
	mv	a1, a0
	call	print
	la	a1, space
	li	a2, 1
	call	print
	la	a1, fail
	call	result
	POP	ra, 0
	EFRAME	1
	ret
_end:
	
	li	a0, 0		# exit code
	li	a7, 93		# syscall exit
	ecall

print:	
title:
	li	a0, 1
	li	a7, 64
	ecall
	ret

result:
	li	a0, 1
	li	a2, 5
	li	a7, 64
	ecall
	ret


test1s:	.asciz	"test1: "
test2s:	.asciz	"test2: "
test3s:	.asciz	"test3: "
test4s:	.asciz	"test4: "
test5s:	.asciz	"test5: "
test6s:	.asciz	"test6: "
test7s:	.asciz	"test7: "
test8s:	.asciz	"test8: "
test9s:	.asciz	"test9: "
test10s:	.asciz	"test10: "
test11s:	.asciz	"test11: "
pass:	.asciz	"pass\n"
fail:	.asciz	"fail\n"
space:	.asciz	" "
colon:	.asciz	": "

.data
.align 2
div3u_label:		.asciz	"div3u "
div10u_label:		.asciz	"div10u: "
div3u_test_counter:	.word	0
div10u_test_counter:	.word	0
div5u_label:		.asciz	"div5u: "
div5u_test_counter:	.word	0
