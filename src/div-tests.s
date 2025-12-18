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

######################################################################
# div3u tests

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

######################################################################
# div5u tests

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

######################################################################
# div6u tests

.dword	600
.dword	div6u_label
.dword	6
.dword	0
.dword	0
.dword	div6u
.dword	1

.dword	601
.dword	div6u_label
.dword	6
.dword	5
.dword	0
.dword	div6u
.dword	1

.dword	602
.dword	div6u_label
.dword	6
.dword	6
.dword	1
.dword	div6u
.dword	1

.dword	603
.dword	div6u_label
.dword	6
.dword	11
.dword	1
.dword	div6u
.dword	1

.dword	604
.dword	div6u_label
.dword	6
.dword	123
.dword	20
.dword	div6u
.dword	1

.dword	605
.dword	div6u_label
.dword	6
.dword	0x7fffffff
.dword	0x15555555
.dword	div6u
.dword	1

.dword	606
.dword	div6u_label
.dword	6
.dword	0x80000000
.dword	0x15555555
.dword	div6u
.dword	1

.dword	607
.dword	div6u_label
.dword	6
.dword	0xffffffff
.dword	0x2aaaaaaa
.dword	div6u
.dword	1

.if CPU_BITS == 64

.dword	608
.dword	div6u_label
.dword	6
.dword	0x100000000
.dword	0x2aaaaaaa
.dword	div6u
.dword	1

.dword	609
.dword	div6u_label
.dword	6
.dword	0x7fffffffffffffff
.dword	0x1555555555555555
.dword	div6u
.dword	1

.dword	610
.dword	div6u_label
.dword	6
.dword	0x8000000000000000
.dword	0x1555555555555555
.dword	div6u
.dword	1

.dword	611
.dword	div6u_label
.dword	6
.dword	-1
.dword	0x2aaaaaaaaaaaaaaa
.dword	div6u
.dword	1
	
.endif

######################################################################
# div7u tests

.dword	700
.dword	div7u_label
.dword	6
.dword	0
.dword	0
.dword	div7u
.dword	1

.dword	701
.dword	div7u_label
.dword	6
.dword	7
.dword	1
.dword	div7u
.dword	1

.dword	702
.dword	div7u_label
.dword	6
.dword	13
.dword	1
.dword	div7u
.dword	1

.dword	703
.dword	div7u_label
.dword	6
.dword	49
.dword	7
.dword	div7u
.dword	1

.dword	704
.dword	div7u_label
.dword	6
.dword	2147483647
.dword	306783378
.dword	div7u
.dword	1

.dword	705
.dword	div7u_label
.dword	6
.dword	2863311530
.dword	409044504
.dword	div7u
.dword	1

.dword	706
.dword	div7u_label
.dword	6
.dword	4294967289
.dword	613566755
.dword	div7u
.dword	1

.dword	707
.dword	div7u_label
.dword	6
.dword	4294967295
.dword	613566756
.dword	div7u
.dword	1

.if CPU_BITS == 64

.dword	708
.dword	div7u_label
.dword	6
.dword	4294967296
.dword	613566756
.dword	div7u
.dword	1

.dword	709
.dword	div7u_label
.dword	6
.dword	0x7FFFFFFFFFFFFFFF
.dword	1317624576693539401
.dword	div7u
.dword	1

.dword	710
.dword	div7u_label
.dword	6
.dword	0xAAAAAAAAAAAAAAAA
.dword	1756832768924719201
.dword	div7u
.dword	1

.dword	711
.dword	div7u_label
.dword	6
.dword	0x5555555555555555
.dword	878416384462359600
.dword	div7u
.dword	1

.dword	712
.dword	div7u_label
.dword	6
.dword	0xFFFFFFFFFFFFFFF8
.dword	2635249153387078801
.dword	div7u
.dword	1

.dword	713
.dword	div7u_label
.dword	6
.dword	0xFFFFFFFFFFFFFFF9
.dword	2635249153387078801
.dword	div7u
.dword	1

.dword	714
.dword	div7u_label
.dword	6
.dword	0xFFFFFFFFFFFFFFFF
.dword	2635249153387078802
.dword	div7u
.dword	1

.endif

######################################################################
# div9u tests

######################################################################
# div10u tests

.dword	1000
.dword	div10u_label
.dword	7
.dword	0
.dword	0
.dword	div10u
.dword	1

.dword	1001
.dword	div10u_label
.dword	7
.dword	9
.dword	0
.dword	div10u
.dword	1

.dword	1002
.dword	div10u_label
.dword	7
.dword	10
.dword	1
.dword	div10u
.dword	1

.dword	1003
.dword	div10u_label
.dword	7
.dword	19
.dword	1
.dword	div10u
.dword	1

.dword	1004
.dword	div10u_label
.dword	7
.dword	123
.dword	12
.dword	div10u
.dword	1

.dword	1005
.dword	div10u_label
.dword	7
.dword	0x7fffffff
.dword	214748364
.dword	div10u
.dword	1

.dword	1006
.dword	div10u_label
.dword	7
.dword	0x80000000
.dword	214748364
.dword	div10u
.dword	1

.dword	1007
.dword	div10u_label
.dword	7
.dword	0xffffffff
.dword	429496729
.dword	div10u
.dword	1

.if CPU_BITS == 64

.dword	1008
.dword	div10u_label
.dword	7
.dword	0x100000000
.dword	0x19999999
.dword	div10u
.dword	1

.dword	1009
.dword	div10u_label
.dword	7
.dword	0x7fffffffffffffff
.dword	0x0ccccccccccccccc
.dword	div10u
.dword	1

.dword	1010
.dword	div10u_label
.dword	7
.dword	-1
.dword	0x1999999999999999
.dword	div10u
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
# Jal the function under test.

.globl _start

_start:

	# 1. Basic Division (Dividend = 10, Divisor = 3)
	# Expected Result: Quotient = 3, Remainder = 1 (since 10 ÷ 3 = 3 remainder 1)

test1:
	la	a1, test1s
	li	a2, 7
	jal	print

	li	a0, 10		# Load dividend (10) into a0
	li	a1, 3		# Load divisor (3) into a1
	jal	divremu		# Jal divremu

	# Check results
	# a0 (quotient) should be 3
	# a1 (remainder) should be 1

	addi	a0, a0, -3
	bnez	a0, test1_fail
	addi	a1, a1, -1
	bnez	a1, test1_fail

	la	a1, pass
	jal	result
	
	j	test2

test1_fail:

	la	a1, fail
	jal	result
	
test2:

	# 2. Zero Dividend (Dividend = 0, Divisor = 3)
	# Expected Result: Quotient = 0, Remainder = 0 (since 0 ÷ 3 = 0 remainder 0)

	la	a1, test2s
	li	a2, 7
	jal	print

	li	a0, 0		# Load dividend (0) into a0
	li	a1, 3		# Load divisor (3) into a1
	jal	divremu		# Jal divremu

	# Check results
	# a0 (quotient) should be 0
	# a1 (remainder) should be 0

	bnez	a0, test2_fail
	bnez	a1, test2_fail

	la	a1, pass
	jal	result

	j	test3

test2_fail:

	la	a1, fail
	jal	result

test3:

	# 3. Zero Divisor (Dividend = 10, Divisor = 0)
	# Expected Result: Division by zero returns Qoutient = 0, Remainder = 0

	la	a1, test3s
	li	a2, 7
	jal	print

	li	a0, 10		# Load dividend (10) into a0
	li	a1, 0		# Load divisor (0) into a1
	jal	divremu		# Jal divremu

	# Check results
	# a0 (quotient) should be -1
	# a1 (remainder) should be 10

	addi	a1, a1, -10
	bnez	a1, test3_fail
	addi	a0, a0, 1
	bnez	a0, test3_fail

	la	a1, pass
	jal	result

	j	test4

test3_fail:

	la	a1, fail
	jal	result

test4:

	# 4. Divisor Greater than Dividend (Dividend = 3, Divisor = 10)
	# Expected Result: Quotient = 0, Remainder = 3 (since 3 ÷ 10 = 0 remainder 3)

	la	a1, test4s
	li	a2, 7
	jal	print

	li	a0, 3		# Load dividend (3) into a0
	li	a1, 10		# Load divisor (10) into a1
	jal	divremu		# Jal divremu

	# Check results
	# a0 (quotient) should be 0
	# a1 (remainder) should be 3

	bnez	a0, test4_fail
	addi	a1, a1, -3
	bnez	a1, test4_fail

	la	a1, pass
	jal	result
	j	test5

test4_fail:
	la	a1, fail
	jal	result

test5:

	# 5. Negative Dividend (Dividend = -10, Divisor = 3)
	# Expected Result: Quotient = -3, Remainder = -1 (since -10 ÷ 3 = -3 remainder -1)

	la	a1, test5s
	li	a2, 7
	jal	print

	li	a0, -10		# Load dividend (-10) into a0
	li	a1, 3		# Load divisor (3) into a1
	jal	divrem		# Jal divrem
	
	# Check results
	# a0 (quotient) should be -3
	# a1 (remainder) should be 1
	
	addi	a0, a0, 3
	bnez	a0, test5_fail
	addi	a1, a1, 1
	bnez	a1, test5_fail
	
	la	a1, pass
	jal	result
	j	test6
	
test5_fail:
	la	a1, fail
	jal	result

test6:

	# 6. Negative Divisor (Dividend = 10, Divisor = -3)
	# Expected Result: Quotient = -3, Remainder = -1 (since 10 ÷ -3 = -3 remainder -1)

	la	a1, test6s
	li	a2, 7
	jal	print
	
	li	a0, 10		# Load dividend (10) into a0
	li	a1, -3		# Load divisor (-3) into a1
	jal	divrem		# Jal divrem

	# Check results
	# a0 (quotient) should be -3
	# a1 (remainder) should be -1
	
	addi	a0, a0, 3
	bnez	a0, test6_fail
	addi	a1, a1, 1
	bnez	a0, test6_fail

	la	a1, pass
	jal	result

	j	test7

test6_fail:
	la	a1, fail
	jal	result

test7:

	# 7. Both Dividend and Divisor Negative (Dividend = -10, Divisor = -3)
	# Expected Result: Quotient = 3, Remainder = -1 (since -10 ÷ -3 = 3 remainder -1)

	la	a1, test7s
	li	a2, 7
	jal	print

	li	a0, -10		# Load dividend (-10) into a0
	li	a1, -3		# Load divisor (-3) into a1
	jal	divrem		# Jal divrem

	# Check results
	# a0 (quotient) should be 3
	# a1 (remainder) should be -1

	addi	a0, a0, -3
	bnez	a0, test7_fail
	addi	a1, a1, 1
	bnez	a1, test7_fail

	la	a1, pass
	jal	result

	j	test8

test7_fail:
	la	a1, fail
	jal	result

test8:

	# 8. Large Dividend (Dividend = 123456, Divisor = 123)
	# Expected Result: Quotient = 1007, Remainder = 105 (since 123456 ÷ 123 = 1007 remainder 105)

	la	a1, test8s
	li	a2, 7
	jal	print

	li	a0, 123456	# Load dividend (123456) into a0
	li	a1, 123		# Load divisor (123) into a1
	jal	divremu		# Jal divremu

	# Check results
	# a0 (quotient) should be 1003
	# a1 (remainder) should be 87

	addi	a0, a0, -1003
	bnez	a0, test8_fail
	addi	a1, a1, -87
	bnez	a1, test8_fail

	la	a1, pass
	jal	result

	j	test9

test8_fail:

	la	a1, fail
	jal	result

test9:

	# 9. Edge Case: Large Dividend and Divisor (Dividend = 1024, Divisor = 2)
	# Expected Result: Quotient = 512, Remainder = 0 (since 1024 ÷ 2 = 512 remainder 0)

	la	a1, test9s
	li	a2, 7
	jal	print

	li	a0, 1024	# Load dividend (1024) into a0
	li	a1, 2		# Load divisor (2) into a1
	jal	divremu		# Jal divremu

	# Check results
	# a0 (quotient) should be 512
	# a1 (remainder) should be 0

	addi	a0, a0, -512
	bnez	a0, test9_fail
	bnez	a1, test9_fail

	la	a1, pass
	jal	result
	j	test10

test9_fail:
	la	a1, fail
	jal	result

test10:

	# 10. Maximum Dividend (Dividend = MAX_INT, Divisor = 1)
	# Expected Result: Quotient = MAX_INT, Remainder = 0 (since MAX_INT ÷ 1 = MAX_INT remainder 0)

	la	a1, test10s
	li	a2, 8
	jal	print

	li	a0, 2147483647	# Load maximum 32-bit signed integer into a0
	li	a1, 1		# Load divisor (1) into a1
	jal	divremu		# Jal divremu

	# Check results
	# a0 (quotient) should be 2147483647
	# a1 (remainder) should be 0

	li	a2, -2147483647
	add	a0, a0, a2
	bnez	a0, test10_fail
	bnez	a1, test10_fail

	la	a1, pass
	jal	result
	j	test11

test10_fail:

	la	a1, fail
	jal	result

test11:
	# Expected Result: Quotient = 4, Remainder = 21

	la	a1, test11s
	li	a2, 8
	jal	print

	li	a0, 433
	li	a1, 103

	jal	divremu

	# Check results
	# a0 (quotient) should be 4
	# a1 (remainder) should be 21
	mv	s0, a0
	mv	s1, a1
	jal	to_decu
	mv	a2, a1
	mv	a1, a0
	jal	print
	la	a1, space
	li	a2, 1
	jal	print
	mv	a0, s1
	jal	to_decu
	mv	a2, a1
	mv	a1, a0
	jal	print
	la	a1, space
	li	a2, 1
	jal	print

	mv	a0, s0
	mv	a1, s1
	addi	a0, a0, -4
	bnez	a0, test11_fail
	addi	a1, a1, -21
	bnez	a1, test11_fail

	la	a1, pass
	jal	result
	#	j	div3u_tests
	j	foo

test11_fail:

	la	a1, fail
	jal	result

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
	jalr	a1		# jal routine

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

_end:
	li	a0, 0		# exit code
	li	a7, 93		# sysjal exit
	ecall

print:	
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
div3u_label:		.asciz	"div3u "
div5u_label:		.asciz	"div5u: "
div6u_label:		.asciz	"div6u: "
div7u_label:		.asciz	"div7u: "
div8u_label:		.asciz	"div9u: "
div10u_label:		.asciz	"div10u: "
div11u_label:		.asciz	"div11u: "
div12u_label:		.asciz	"div12u: "
div13u_label:		.asciz	"div13u: "
div100u_label:		.asciz	"div100u: "
div1000u_label:		.asciz	"div1000u "
div3_label:		.asciz	"div3 "
div5_label:		.asciz	"div5: "
div6_label:		.asciz	"div6: "
div7_label:		.asciz	"div7: "
div8_label:		.asciz	"div9: "
div10_label:		.asciz	"div10: "
div11_label:		.asciz	"div11: "
div12_label:		.asciz	"div12: "
div13_label:		.asciz	"div13: "
div100_label:		.asciz	"div100: "
div1000_label:		.asciz	"div1000 "

