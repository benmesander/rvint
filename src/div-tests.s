.include "config.s"
.data
.align	8
divtab:	
.equ 	offset_testnum, 0
.equ	offset_label, 	8
.equ	offset_len,	16
.equ	offset_dividend,24
.equ	offset_quotient,32
.equ	offset_ptr, 	40
.equ	offset_flags,	48
.equ	struct_len, 	56

.dword	300		# testnum
.dword	div3u_label	# pointer to nul-terminated ascii string
.dword	6		# len of label
.dword	0		# dividend
.dword	0		# quotient
.dword	div3u		# pointer to routine
.dword	1		# flags, 0 = end of list	

.dword	301
.dword	div3u_label
.dword	6
.dword	1
.dword	0
.dword	div3u
.dword	1

.dword	302
.dword	div3u_label
.dword	6
.dword	2
.dword	0
.dword	div3u
.dword	1
	
.dword	303
.dword	div3u_label
.dword	6
.dword	3
.dword	1
.dword	div3u
.dword	1

.dword	304
.dword	div3u_label
.dword	6
.dword	0x7fffffff
.dword	0x2aaaaaaa
.dword	div3u
.dword	1

.dword	305
.dword	div3u_label
.dword	6
.dword	0x80000000
.dword	0x2aaaaaaa
.dword	div3u
.dword	1
	
.dword	306
.dword	div3u_label
.dword	6
.dword	0xffffffff
.dword	0x55555555
.dword	div3u
.dword	1

.if CPU_BITS == 64

.dword	307
.dword	div3u_label
.dword	6
.dword	0x100000000
.dword	0x55555555
.dword	div3u
.dword	1

.dword	308
.dword	div3u_label
.dword	6
.dword	0x7fffffffffffffff
.dword	0x2aaaaaaaaaaaaaaa
.dword	div3u
.dword	1

.dword	309
.dword	div3u_label
.dword	6
.dword	0x8000000000000000
.dword	0x2aaaaaaaaaaaaaaa
.dword	div3u
.dword	1

.dword	310
.dword	div3u_label
.dword	6
.dword	-1
.dword	0x5555555555555555
.dword	div3u
.dword	1

.endif	

.dword	500
.dword	div5u_label
.dword	6
.dword	0
.dword	0
.dword	div5u
.dword	1

.dword	501
.dword	div5u_label
.dword	6
.dword	1
.dword	0
.dword	div5u
.dword	1

.dword	502
.dword	div5u_label
.dword	6
.dword	4
.dword	0
.dword	div5u
.dword	1

.dword	503
.dword	div5u_label
.dword	6
.dword	5
.dword	1
.dword	div5u
.dword	1

.dword	504
.dword	div5u_label
.dword	6
.dword	9
.dword	1
.dword	div5u
.dword	1

.dword	505
.dword	div5u_label
.dword	6
.dword	10
.dword	2
.dword	div5u
.dword	1

.dword	506
.dword	div5u_label
.dword	6
.dword	123
.dword	24
.dword	div5u
.dword	1

.dword	507
.dword	div5u_label
.dword	6
.dword	0x7fffffff
.dword	0x19999999
.dword	div5u
.dword	1

.dword	508
.dword	div5u_label
.dword	6
.dword	0x80000000
.dword	0x19999999
.dword	div5u
.dword	1

.dword	509
.dword	div5u_label
.dword	6
.dword	0xffffffff
.dword	0x33333333
.dword	div5u
.dword	1

.if CPU_BITS == 64

.dword	510
.dword	div5u_label
.dword	6
.dword	0x100000000
.dword	0x33333333
.dword	div5u
.dword	1

.dword	511
.dword	div5u_label
.dword	6
.dword	0x7fffffffffffffff
.dword	0x1999999999999999
.dword	div5u
.dword	1

.dword	512
.dword	div5u_label
.dword	6
.dword	0x8000000000000000
.dword	0x1999999999999999
.dword	div5u
.dword	1

.dword	513
.dword	div5u_label
.dword	6
.dword	-1
.dword	0x3333333333333333
.dword	div5u
.dword	1

.endif

# loop terminator
.dword	0
.dword	0
.dword	0
.dword	0
.dword	0
.dword	0
.dword	0



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

	# straight line division tests
	# dividend, divisor, expected quotient, actual quotient
	# 32 or 64 bits
	# test number counter
	# test name
	# output format:
	# 1: div10u: 0x0000000000000000 0x0000000000000000 pass
	# 2: div10u: 0x0000000000000009 0x0000000000000000 fail 0x0000000000000007

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
	# Expected Result: Quotient = 4, Remainder = 21

	la	a1, test11s
	li	a2, 8
	call	title

	li	a0, 433
	li	a1, 103

	jal	divremu

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
	#	j	div3u_tests
	j	foo

test11_fail:

	la	a1, fail
	call	result

.macro	load	reg addr
.if CPU_BITS == 64
	ld	\reg, \addr
.else
	lw	\reg, \addr
.endif
.endm

foo:	
	la	s0, divtab
loopy:	
	load	a0, offset_flags(s0)
	beqz	a0, _end

	load	a0, offset_testnum(s0)	# s0 = testnum
	jal	to_dec
	mv	a2, a1
	mv	a1, a0
	jal	print
	la	a1, colon	# ": "
	li	a2, 2
	jal	print

	load	a1, offset_label(s0)	# label
	load	a2, offset_len(s0)	# len of label
	jal	print

	load	s1,offset_dividend(s0)	# s1 = dividend
	mv	a0, s1
	li	a1, CPU_BYTES
	li	a2, 1
	jal	to_hex		# convert dividend to hex
	mv	a2, a1
	mv	a1, a0
	jal	print		# print dividend
	la	a1, space
	li	a2, 1
	jal	print		# print space

	load	a0, offset_quotient(s0)	# expected quotient is in 16(s0)
	mv	s2, a0		# expected quotient is in s2
	li	a1, CPU_BYTES
	li	a2, 1
	jal	to_hex
	mv	a2, a1
	mv	a1, a0
	jal	print		# print expected quotient
	la	a1, space
	li	a2, 1
	jal	print		# print space

	load	a1, offset_ptr(s0)	# routine pointer
	mv	a0, s1		# get dividend in a0
	jalr	a1		# call routine

	bne	a0, s2, test_fail
	
	la	a1, pass
	li	a2, 5
	jal	print
	j	next
	
test_fail:
	li	a1, CPU_BYTES
	li	a2, 1
	jal	to_hex
	mv	a2, a1
	mv	a1, a0
	jal	print
	la	a1, space
	li	a2, 1
	jal	print
	la	a1, fail
	li	a2, 5
	jal	print
next:
	addi	s0, s0, struct_len
	j	loopy



# --- div6u tests ---
div6u_tests:
	# Test 1: 0 / 6 = 0
	li	a0, 0
	li	a1, 0
	call	div6u_test_case

	# Test 2: 5 / 6 = 0
	li	a0, 5
	li	a1, 0
	call	div6u_test_case

	# Test 3: 6 / 6 = 1
	li	a0, 6
	li	a1, 1
	call	div6u_test_case

	# Test 4: 11 / 6 = 1
	li	a0, 11
	li	a1, 1
	call	div6u_test_case

	# Test 5: 123 / 6 = 20
	li	a0, 123
	li	a1, 20
	call	div6u_test_case

	# Test 6: 0x7fffffff / 6 = 0x15555555
	li	a0, 0x7fffffff
	li	a1, 0x15555555
	call	div6u_test_case

	# Test 7: 0x80000000 / 6 = 0x15555555
	li	a0, 0x80000000
	li	a1, 0x15555555
	call	div6u_test_case

	# Test 8: 0xffffffff / 6 = 0x2aaaaaaa
	li	a0, 0xffffffff
	li	a1, 0x2aaaaaaa
	call	div6u_test_case

.if CPU_BITS == 64
	# 64-bit test cases
	# Test 9: 0x100000000 / 6 = 0x2aaaaaaa
	li	a0, 0x100000000
	li	a1, 0x2aaaaaaa
	call	div6u_test_case

	# Test 10: 0x7fffffffffffffff / 6 = 0x1555555555555555
	li	a0, 0x7fffffffffffffff
	li	a1, 0x1555555555555555
	call	div6u_test_case
	
	# Test 11: 0x8000000000000000 / 6 = 0x1555555555555555
	li	a0, 0x8000000000000000
	li	a1, 0x1555555555555555
	call	div6u_test_case

	# Test 12: 0xffffffffffffffff / 6 = 0x2aaaaaaaaaaaaaaa
	li	a0, -1
	li	a1, 0x2aaaaaaaaaaaaaaa
	call	div6u_test_case
.endif
	j	div10u_tests

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

	j	_end


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

#
# a0 = value to divide, a1 = expected result
#
div6u_test_case:
	FRAME	1
	PUSH	ra, 0
	# Save input and expected value
	mv	s0, a0		# input n
	mv	s1, a1		# expected quotient

	# Print test number
	la	t3, div6u_test_counter
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
	la	a1, div6u_label
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
	
	# Call div6u
	mv	a0, s0
	call	div6u
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
	bne	a0, s1, div6u_fail

	# Pass
	la	a1, pass
	call	result
	POP	ra, 0
	EFRAME	1
	ret

div6u_fail:
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
div3u_test_counter:	.word	0
div5u_label:		.asciz	"div5u: "
div5u_test_counter:	.word	0
div6u_label:		.asciz	"div6u: "
div6u_test_counter:	.word	0
div10u_label:		.asciz	"div10u: "
div10u_test_counter:	.word	0


