.include "config.s"
.globl bits_ctz
.globl bits_clz
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
# input registers:
# a0 = number
#
# output registers:
# a0 = result containing the number of leading zeroes in the input
################################################################################

bits_clz:
	beqz	a0, bits_clz_is_zero
	mv	a3, zero	# a3 result accumulator
	li	a2, -1		# a2 mask register
				# a1 intermediate results

.if CPU_BITS == 64
	slli	a2, a2, 32	# 1's in upper 32 bits
	and	a1, a2, a0
	bnez	a1, bits_clz_upper_16
	addi	a3, a3, 32	# add 32 zeroes
	slli	a0, a0, 32	# move up value
.endif

bits_clz_upper_16:
	slli	a2, a2, 16	# 1's in upper 16 bits
	and	a1, a2, a0
	bnez	a1, bits_clz_upper_8
	addi	a3, a3, 16
	slli	a0, a0, 16

bits_clz_upper_8:
	slli	a2, a2, 8
	and	a1, a2, a0
	bnez	a1, bits_clz_upper_4
	addi	a3, a3, 8
	slli	a0, a0, 8

bits_clz_upper_4:
	slli	a2, a2, 4
	and	a1, a2, a0
	bnez	a1, bits_clz_upper_2
	addi	a3, a3, 4
	slli	a0, a0, 4

bits_clz_upper_2:
	slli	a2, a2, 2
	and	a1, a2, a0
	bnez	a1, bits_clz_upper_1
	addi	a3, a3, 2
	slli	a0, a0, 2

bits_clz_upper_1:
	slli	a2, a2, 1
	and	a1, a2, a0
	bnez	a1, bits_clz_done
	addi	a3, a3, 1

bits_clz_done:
	mv	a0, a3
	ret

bits_clz_is_zero:
	li	a0, CPU_BITS
	ret

.size	bits_clz, .-bits_clz
