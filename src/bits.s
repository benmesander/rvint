.include "config.s"
.globl	bits_ctz
.globl	bits_clz
.text

################################################################################
# routine: bits_ctz
#
# Count the number of trailing zeroes in a number via binary search - O(log n).
# This is useful for processors with no B extension. This routine provides the
# functionality of the ctz instruction (on 32-bit processors) and ctzw (on
# 64-bit processors).
# RV32I/RV32E/RV64I compatible.
#
# input registers:
# a0 = number
#
# output registers:
# a0 = result containing the count of trailing zeroes
################################################################################
bits_ctz:
	# 1. Handle Zero Input (Return CPU_BITS)
	bnez	a0, bits_ctz_start
	li	a0, CPU_BITS
	ret

bits_ctz_start:
	# Accumulator for zeros (use a1 to free a0 for shifting)
	li	a1, 0

	# 64-bit Check (RV64 Only)
.if CPU_BITS == 64
	# Shift left by 32. If result != 0, low 32 bits are occupied.
	slli	t0, a0, 32
	bnez	t0, bits_ctz_check_16
	
	# Low 32 are empty. Add 32 to count and shift input.
	addi	a1, a1, 32
	srli	a0, a0, 32
.endif

	# 16-bit Check
bits_ctz_check_16:
	# Shift left by (CPU_BITS - 16) to isolate lower 16 bits
	slli	t0, a0, (CPU_BITS - 16)
	bnez	t0, bits_ctz_check_8
	addi	a1, a1, 16
	srli	a0, a0, 16

	# 8-bit Check
bits_ctz_check_8:
	slli	t0, a0, (CPU_BITS - 8)
	bnez	t0, bits_ctz_check_4
	addi	a1, a1, 8
	srli	a0, a0, 8

	# 4-bit Check
bits_ctz_check_4:
	slli	t0, a0, (CPU_BITS - 4)
	bnez	t0, bits_ctz_check_2
	addi	a1, a1, 4
	srli	a0, a0, 4

	# 2-bit Check
bits_ctz_check_2:
	slli	t0, a0, (CPU_BITS - 2)
	bnez	t0, bits_ctz_check_1
	addi	a1, a1, 2
	srli	a0, a0, 2

	# 1-bit Check
bits_ctz_check_1:
	# If LSB is 0, add 1.
	andi	t0, a0, 1
	bnez	t0, bits_ctz_done
	addi	a1, a1, 1

bits_ctz_done:
	mv	a0, a1
	ret
.size bits_ctz, .-bits_ctz


################################################################################
# routine: bits_clz
#
# Count the number of leading zeroes in a number via binary search - O(log n).
# This is useful for processors with no B extension. This routine provides the
# functionality of the clz instruction (on 32-bit processors) and clzw (on
# 64-bit processors).
# RV32E compatible.
#
# Algorithm from figure 5.11 Hackers Delight, 2nd ed.
#
# input registers:
# a0 = number
#
# output registers:
# a0 = result containing the number of leading zeroes in the input
################################################################################

bits_clz:
	beqz	a0, bits_clz_is_zero	# a0 = x
	li	a3, 1		# a3 = n (accumulator)

.if CPU_BITS == 32
	srli	a2, a0, 16	# a2 = x >> 16
	bnez	a2, bits_clz_1
	addi	a3, a3, 16
	slli	a0, a0, 16
bits_clz_1:	
	srli	a2, a0, 24
	bnez	a2, bits_clz_2
	addi	a3, a3, 8
	slli	a0, a0, 8
bits_clz_2:
	srli	a2, a0, 28
	bnez	a2, bits_clz_3
	addi	a3, a3, 4
	slli	a0, a0, 4
bits_clz_3:
	srli	a2, a0, 30
	bnez	a2, bits_clz_4
	addi	a3, a3, 2
	slli	a0, a0, 2
bits_clz_4:
	srli	a2, a0, 31
.else # CPU_BITS == 64
	srli	a2, a0, 32
	bnez	a2, bits_clz_1
	addi	a3, a3, 32
	slli	a0, a0, 32
bits_clz_1:
	srli	a2, a0, 48
	bnez	a2, bits_clz_2
	addi	a3, a3, 16
	slli	a0, a0, 16
bits_clz_2:
	srli	a2, a0, 56
	bnez	a2, bits_clz_3
	addi	a3, a3, 8
	slli	a0, a0, 8
bits_clz_3:	
	srli	a2, a0, 60
	bnez	a2, bits_clz_4
	addi	a3, a3, 4
	slli	a0, a0, 4
bits_clz_4:
	srli	a2, a0, 62
	bnez	a2, bits_clz_5
	addi	a3, a3, 2
	slli	a0, a0, 2
bits_clz_5:
	srli	a2, a0, 63
.endif # CPU_BITS == 32
	sub	a0, a3, a2
	ret
bits_clz_is_zero:
	li	a0, CPU_BITS
	ret

.size bits_clz, .-bits_clz
