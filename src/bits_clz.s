.include "config.s"
.globl	bits_clz
.text

################################################################################
# routine: bits_clz
#
# Count Leading Zeros.
# Returns the number of zero bits starting from the MSB.
# Returns CPU_BITS if the input is 0.
#
# input:  a0 = input value
# output: a0 = count of leading zeros
################################################################################

bits_clz:
	# 1. Handle Zero Input (Return CPU_BITS)
	bnez	a0, bits_clz_start
	li	a0, CPU_BITS
	ret

bits_clz_start:
	li	a1, 0

	# 64-bit Check (RV64 Only)
.if CPU_BITS == 64
	# Check upper 32 bits
	srli	t0, a0, 32
	bnez	t0, bits_clz_check_16
	
	# Upper 32 are empty. Add 32 to count and shift left (to move bits to MSB side).
	addi	a1, a1, 32
	slli	a0, a0, 32
.endif

	# 16-bit Check
bits_clz_check_16:
	srli	t0, a0, (CPU_BITS - 16)
	bnez	t0, bits_clz_check_8
	addi	a1, a1, 16
	slli	a0, a0, 16

	# 8-bit Check
bits_clz_check_8:
	srli	t0, a0, (CPU_BITS - 8)
	bnez	t0, bits_clz_check_4
	addi	a1, a1, 8
	slli	a0, a0, 8

	# 4-bit Check
bits_clz_check_4:
	srli	t0, a0, (CPU_BITS - 4)
	bnez	t0, bits_clz_check_2
	addi	a1, a1, 4
	slli	a0, a0, 4

	# 2-bit Check
bits_clz_check_2:
	srli	t0, a0, (CPU_BITS - 2)
	bnez	t0, bits_clz_check_1
	addi	a1, a1, 2
	slli	a0, a0, 2

	# 1-bit Check (MSB)
bits_clz_check_1:
	# Check MSB
	srli	t0, a0, (CPU_BITS - 1)
	bnez	t0, bits_clz_done
	addi	a1, a1, 1

bits_clz_done:
	mv	a0, a1
	ret
.size bits_clz, .-bits_clz
