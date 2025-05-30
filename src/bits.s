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
#
# input registers:
# a0 = number
#
# output registers:
# a0 = result containing the number of trailing zeroes
#
# clobbers:
# a0-a3
################################################################################

bits_ctz:
	beqz	a0, bits_ctz_is_zero
	mv	a3, zero	# result

.if CPU_BITS == 64
	li	a2, -1
	srli	a2, a2, 32
	and	a1, a0, a2
	bnez	a1, bits_ctz_lower_16
	addi	a3, a3, 32
	srli	a0, a0, 32
.endif

bits_ctz_lower_16:
	srli	a2, a2, 16
	and	a1, a0, a2
	bnez	a1, bits_ctz_lower_8
	addi	a3, a3, 16	# lower 16 are zero, add to count
	srli	a0, a0, 16

bits_ctz_lower_8:
	andi	a1, a0, 0xff
	bnez	a1, bits_ctz_lower_4
	addi	a3, a3, 8
	srli	a0, a0, 8

bits_ctz_lower_4:
	andi	a1, a0, 0xf
	bnez	a1, bits_ctz_lower_2
	addi	a3, a3, 4
	srli	a0, a0, 4

bits_ctz_lower_2:
	andi	a1, a0, 0x3
	bnez	a1, bits_ctz_lower_1
	addi	a3, a3, 2
	srli	a0, a0, 2

bits_ctz_lower_1:
	andi	a1, a0, 0x1
	bnez	a1, bits_ctz_done
	addi	a3, a3, 1

bits_ctz_done:
	mv	a0, a3
	ret

bits_ctz_is_zero:
	li	a0, CPU_BITS
	ret

.size	bits_ctz, .-bits_ctz

################################################################################
# routine: bits_clz
#
# Count the number of leading zeroes in a number via binary search - O(log n).
# This is useful for processors with no B extension. This routine provides the
# functionality of the clz instruction (on 32-bit processors) and clzw (on
# 64-bit processors).
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
