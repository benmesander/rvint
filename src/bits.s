.include "config.s"
.globl	bits_ctz
.globl	bits_clz
.text

################################################################################
# routine: bits_ctz
#
# Count the number of trailing zeroes in a number via optimized binary search.
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
	mv	a3, zero        # Initialize count to 0

.if CPU_BITS == 64
	# Check if the bit is in the lower 32 bits
	andi	a1, a0, 0xFFFFFFFF  # Isolate lower 32 bits
	bnez	a1, bits_ctz_search  # If they are not zero, search them

	# Lower 32 bits were zero, search upper 32 bits
	addi	a3, a3, 32          # Add 32 to count
	srli	a1, a0, 32          # a1 = upper 32 bits
.else
	mv	a1, a0              # For 32-bit, start with full value
.endif

bits_ctz_search:
	# Check lower 16 bits
	andi	a2, a1, 0xffff
	bnez	a2, bits_ctz_check8
	addi	a3, a3, 16
	srli	a1, a1, 16

bits_ctz_check8:
	# Check lower 8 bits
	andi	a2, a1, 0xff
	bnez	a2, bits_ctz_check4
	addi	a3, a3, 8
	srli	a1, a1, 8

bits_ctz_check4:
	# Check lower 4 bits
	andi	a2, a1, 0xf
	bnez	a2, bits_ctz_check2
	addi	a3, a3, 4
	srli	a1, a1, 4

bits_ctz_check2:
	# Check lower 2 bits
	andi	a2, a1, 0x3
	bnez	a2, bits_ctz_final
	addi	a3, a3, 2
	srli	a1, a1, 2

bits_ctz_final:
	# Use LSB directly in count
	andi	a1, a1, 0x1     # Get LSB
	xori	a1, a1, 0x1     # Invert LSB (1->0, 0->1)
	add	a0, a3, a1      # Add to running count
	ret

bits_ctz_is_zero:
	li	a0, CPU_BITS
	ret

.size	bits_ctz, .-bits_ctz

################################################################################
# routine: bits_clz
#
# Count the number of leading zeroes in a number via optimized binary search.
# This is useful for processors with no B extension. This routine provides the
# functionality of the clz instruction (on 32-bit processors) and clzw (on
# 64-bit processors).
#
# input registers:
# a0 = number
#
# output registers:
# a0 = result containing the number of leading zeroes in the input
#
# clobbers:
# a0-a3
################################################################################

bits_clz:
	beqz	a0, bits_clz_is_zero
	mv	a3, zero        # Start count at 0

.if CPU_BITS == 64
	# Check if upper 32 bits are zero
	srli	a2, a0, 32
	beqz	a2, bits_clz_upper32
	mv	a0, a2          # Use upper 32 bits
	j	bits_clz_check16
bits_clz_upper32:
	addi	a3, a3, 32     # Add 32 to count
.endif

bits_clz_check16:
	# Check upper 16 bits
	srli	a2, a0, 16
	beqz	a2, bits_clz_skip16
	mv	a0, a2          # Use upper 16 bits
	j	bits_clz_check8
bits_clz_skip16:
	addi	a3, a3, 16     # Add 16 to count
	slli	a0, a0, 16     # Normalize value for next check

bits_clz_check8:
	# Check upper 8 bits
	srli	a2, a0, 24
	beqz	a2, bits_clz_skip8
	mv	a0, a2          # Use upper 8 bits
	j	bits_clz_check4
bits_clz_skip8:
	addi	a3, a3, 8      # Add 8 to count
	slli	a0, a0, 8      # Normalize value for next check

bits_clz_check4:
	# Check upper 4 bits
	srli	a2, a0, 28
	beqz	a2, bits_clz_skip4
	mv	a0, a2          # Use upper 4 bits
	j	bits_clz_check2
bits_clz_skip4:
	addi	a3, a3, 4      # Add 4 to count
	slli	a0, a0, 4      # Normalize value for next check

bits_clz_check2:
	# Check upper 2 bits
	srli	a2, a0, 30
	beqz	a2, bits_clz_skip2
	mv	a0, a2          # Use upper 2 bits
	j	bits_clz_msb
bits_clz_skip2:
	addi	a3, a3, 2      # Add 2 to count
	slli	a0, a0, 2      # Normalize value for next check

bits_clz_msb:
	# Get final count using MSB
	srli	a2, a0, 31     # Get MSB
	xori	a2, a2, 1      # Invert MSB (1->0, 0->1)
	add	a0, a3, a2     # Add to running count
	ret

bits_clz_is_zero:
	li	a0, CPU_BITS
	ret

.size bits_clz, .-bits_clz
