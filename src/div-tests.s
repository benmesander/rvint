	# runs on linux

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
	# Call the divrem function.
	# Check the values in a0 (quotient) and a1 (remainder).

.globl _start

_start:

	#1. Basic Division (Dividend = 10, Divisor = 3)
	# Expected Result: Quotient = 3, Remainder = 1 (since 10 ÷ 3 = 3 remainder 1)

test1:
	la a1, test1s
	li a2, 7
	call title

	li      a0, 10         # Load dividend (10) into a0
	li      a1, 3          # Load divisor (3) into a1
	jal     divremu         # Call divremu

	# Check results
	# a0 (quotient) should be 3
	# a1 (remainder) should be 1

	addi a0, a0, -3
	bnez a0, test1_fail
	addi a1, a1, -1
	bnez a1, test1_fail

	la a1, pass
	call result
	
	j test2

test1_fail:

	la a1, fail
	call result
	
test2:

	#2. Zero Dividend (Dividend = 0, Divisor = 3)
	#Expected Result: Quotient = 0, Remainder = 0 (since 0 ÷ 3 = 0 remainder 0)

	la a1, test2s
	li a2, 7
	call title

	li      a0, 0          # Load dividend (0) into a0
	li      a1, 3          # Load divisor (3) into a1
	jal     divremu         # Call divremu

	# Check results
	# a0 (quotient) should be 0
	# a1 (remainder) should be 0

	bnez a0, test2_fail
	bnez a1, test2_fail

	la a1, pass
	call result

	j test3

test2_fail:

	la a1, fail
	call result

test3:

	#3. Zero Divisor (Dividend = 10, Divisor = 0)
	#Expected Result: Division by zero returns Qoutient = 0, Remainder = 0

	la a1, test3s
	li a2, 7
	call title

	li      a0, 10         # Load dividend (10) into a0
	li      a1, 0          # Load divisor (0) into a1
	jal     divremu         # Call divremu

	# Check results
	# a0 (quotient) should be -1
	# a1 (remainder) should be 10

	addi a0, a0, -10
	bnez a0, test3_fail
	addi a1, a1, 1
	bnez a1, test3_fail

	la a1, pass
	call result

	j test4

test3_fail:

	la a1, fail
	call result

test4:

	#4. Divisor Greater than Dividend (Dividend = 3, Divisor = 10)
	#Expected Result: Quotient = 0, Remainder = 3 (since 3 ÷ 10 = 0 remainder 3)

	la a1, test4s
	li a2, 7
	call title

	li      a0, 3          # Load dividend (3) into a0
	li      a1, 10         # Load divisor (10) into a1
	jal     divremu         # Call divremu

	# Check results
	# a0 (quotient) should be 0
	# a1 (remainder) should be 3

	bnez a0, test4_fail
	addi a1, a1, -3
	bnez a1, test4_fail

	la a1, pass
	call result
	j test5

test4_fail:
	la a1, fail
	call result

test5:

	#5. Negative Dividend (Dividend = -10, Divisor = 3)
	#Expected Result: Quotient = -3, Remainder = -1 (since -10 ÷ 3 = -3 remainder -1)

	la a1, test5s
	li a2, 7
	call title

	li      a0, -10        # Load dividend (-10) into a0
	li      a1, 3          # Load divisor (3) into a1
	jal     divrem         # Call divrem
	
	# Check results
	# a0 (quotient) should be -3
	# a1 (remainder) should be 1
	
	addi a0, a0, 3
	bnez a0, test5_fail
	addi a1, a1, 1
	bnez a1, test5_fail
	
	la a1, pass
	call result
	j test6
	
test5_fail:
	la a1, fail
	call result

test6:

	#6. Negative Divisor (Dividend = 10, Divisor = -3)
	#Expected Result: Quotient = -3, Remainder = -1 (since 10 ÷ -3 = -3 remainder -1)

	la a1, test6s
	li a2, 7
	call title
	
	li      a0, 10         # Load dividend (10) into a0
	li      a1, -3         # Load divisor (-3) into a1
	jal     divrem         # Call divrem

	# Check results
	# a0 (quotient) should be -3
	# a1 (remainder) should be -1
	
	addi a0, a0, 3
	bnez a0, test6_fail
	addi a1, a1, 1
	bnez a0, test6_fail

	la a1, pass
	call result

	j test7

test6_fail:
	la a1, fail
	call result

test7:

	#7. Both Dividend and Divisor Negative (Dividend = -10, Divisor = -3)
	#Expected Result: Quotient = 3, Remainder = -1 (since -10 ÷ -3 = 3 remainder -1)

	la a1, test7s
	li a2, 7
	call title

	li      a0, -10        # Load dividend (-10) into a0
	li      a1, -3         # Load divisor (-3) into a1
	jal     divrem         # Call divrem

	# Check results
	# a0 (quotient) should be 3
	# a1 (remainder) should be -1

	addi a0, a0, -3
	bnez a0, test7_fail
	addi a1, a1, 1
	bnez a1, test7_fail

	la a1, pass
	call result

	j test8

test7_fail:
	la a1, fail
	call result

test8:

	#8. Large Dividend (Dividend = 123456, Divisor = 123)
	#Expected Result: Quotient = 1007, Remainder = 105 (since 123456 ÷ 123 = 1007 remainder 105)

	la a1, test8s
	li a2, 7
	call title

	li      a0, 123456     # Load dividend (123456) into a0
	li      a1, 123        # Load divisor (123) into a1
	jal     divremu         # Call divremu

	# Check results
	# a0 (quotient) should be 1003
	# a1 (remainder) should be 87

	addi a0, a0, -1003
	bnez a0, test8_fail
	addi a1, a1, -87
	bnez a1, test8_fail

	la a1, pass
	call result

	j test9

test8_fail:

	la a1, fail
	call result

test9:

	#9. Edge Case: Large Dividend and Divisor (Dividend = 1024, Divisor = 2)
	#Expected Result: Quotient = 512, Remainder = 0 (since 1024 ÷ 2 = 512 remainder 0)

	la a1, test9s
	li a2, 7
	call title

	li      a0, 1024       # Load dividend (1024) into a0
	li      a1, 2          # Load divisor (2) into a1
	jal     divremu         # Call divremu

	# Check results
	# a0 (quotient) should be 512
	# a1 (remainder) should be 0

	addi a0, a0, -512
	bnez a0, test9_fail
	bnez a1, test9_fail

	la a1, pass
	call result
	j test10

test9_fail:
	la a1, fail
	call result

test10:

	#10. Maximum Dividend (Dividend = MAX_INT, Divisor = 1)
	#Expected Result: Quotient = MAX_INT, Remainder = 0 (since MAX_INT ÷ 1 = MAX_INT remainder 0)

	la a1, test10s
	li a2, 8
	call title

	li      a0, 2147483647 # Load maximum 32-bit signed integer into a0
	li      a1, 1          # Load divisor (1) into a1
	jal     divremu         # Call divremu

	# Check results
	# a0 (quotient) should be 2147483647
	# a1 (remainder) should be 0

	li a2, -2147483647
	add a0, a0, a2
	bnez a0, test10_fail
	bnez a1, test10_fail

	la a1, pass
	call result
	j _end

test10_fail:

	la a1, fail
	call result

_end:
	
        li a0, 0            # exit code
        li a7, 93           # syscall exit
        ecall

title:
	li a0, 1
	li a7, 64
	ecall
	ret

result:
	li a0, 1
	li a2, 5
	li a7, 64
	ecall
	ret


test1s: .asciz  "test1: "
test2s: .asciz  "test2: "
test3s: .asciz  "test3: "
test4s: .asciz  "test4: "
test5s: .asciz  "test5: "
test6s: .asciz  "test6: "
test7s: .asciz  "test7: "
test8s: .asciz  "test8: "
test9s: .asciz  "test9: "
test10s: .asciz  "test10: "
pass: .asciz "pass\n"
fail: .asciz "fail\n"
	
