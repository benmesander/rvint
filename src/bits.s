.include "config.s"
.globl	bits_ctz
.globl	alt_ctz
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

# branchless but larger:
alt_ctz:
	sub	a1, zero, a0
	and	a1, a1, a0		# a1: y = x & -x
	sltiu	a2, a1, 1		# a2: bz = y ? 0: 1
.if CPU_BITS == 64
	li	t1, 1
	slli	t0, t1, 32
	addi	t0, t0, -1		# 0x00000000ffffffff
	and	t2, a1, t0
	sltiu	t2, t2, 1
	slli	t2, t2, 5
	li	t0, 0x0000ffff0000ffff
	and	a3, a1, t0
	sltiu	a3, a3, 1
	slli	a3, a3, 4
	li	t0, 0x00ff00ff00ff00ff
	and	a4, a1, t0
	sltiu	a4, a4, 1
	slli	a4, a4, 3
	li	t0, 0x0f0f0f0f0f0f0f0f
	and	a5, a1, t0
	sltiu	a5, a5, 1
	slli	a5, a5, 2
	li	t0, 0x3333333333333333
	and	a6, a1, t0
	sltiu	a6, a6, 1
	slli	a6, a6, 1
	li	t0, 0x5555555555555555
	and	a7, a1, t0
	sltiu	a7, a7, 1

	add	a0, a2, t2
.else # CPU_BITS == 32	
	li	t0, 0x0000ffff		# a3: b4 = (y & 0x0000ffff) ? 0 : 16
	and	a3, a1, t0
	sltiu	a3, a3, 1		
	slli	a3, a3, 4
	li	t0, 0x00ff00ff		# a4: b3 = (y & 0x00ff00ff) ? 0 : 8
	and	a4, a1, t0
	sltiu	a4, a4, 1
	slli	a4, a4, 3		
	li	t0, 0x0f0f0f0f		# a5: b2 = (y & 0x0f0f0f0f) ? 0 : 4
	and	a5, a1, t0
	sltiu	a5, a5, 1
	slli	a5, a5, 2		
	li	t0, 0x33333333		# a6: b1 = (y & 0x33333333) ? 0 : 2
	and	a6, a1, t0
	sltiu	a6, a6, 1
	slli	a6, a6, 1		
	li	t0, 0x55555555		# a7: b0 = (y & 0x55555555) ? 0 : 1
	and	a7, a1, t0
	sltiu	a7, a7, 1
	mv	a0, a2
.endif
	add	a0, a0, a3		# return bz + b4 + b3 + b2 + b1 + b0
	add	a0, a0, a4
	add	a0, a0, a5
	add	a0, a0, a6
	add	a0, a0, a7
	ret

.size	alt_ctz, .-alt_ctz



.if CPU_BITS == 1

#include <stdint.h> // For uint64_t

// Lookup table for converting De Bruijn sequence index to CTZ count.
// The indices are derived from the specific magic number used.
static const int deBruijn_ctz64_lookup[64] = {
    63,  0, 58,  1, 59, 47, 53,  2,
    60, 39, 48, 27, 54, 33, 42,  3,
    61, 51, 37, 40, 49, 18, 28, 20,
    55, 30, 34, 11, 43, 14, 22,  4,
    62, 57, 46, 52, 38, 26, 32, 41,
    50, 36, 17, 19, 29, 10, 13, 21,
    56, 45, 25, 31, 35, 16,  9, 12,
    44, 24, 15,  8, 23,  7,  6,  5
};

// 64-bit De Bruijn sequence magic number.
static const uint64_t deBruijn_magic_64 = 0x07EDD5E59A4E28C2ULL;

// Constant for the right shift (64 - log2(table_size))
// Table size is 64, log2(64) = 6. So, 64 - 6 = 58.
static const int deBruijn_shift_64 = 58;

/**
 * @brief Counts trailing zeros in a 64-bit unsigned integer using a De Bruijn sequence.
 *
 * @param x The 64-bit unsigned integer.
 * @return The number of trailing zeros (0-63). Returns 64 if x is 0.
 */
int ctz64_debruijn(uint64_t x) {
    if (x == 0) {
        return 64; // Convention for CTZ(0)
    }

    // 1. Isolate the least significant bit: y = x & -x
    uint64_t y = x & -x;

    // 2. Multiply by the magic De Bruijn number
    // 3. Shift to get the index
    uint64_t index = (y * deBruijn_magic_64) >> deBruijn_shift_64;

    // 4. Lookup the CTZ value
    return deBruijn_ctz64_lookup[index];
}

/* Example Usage:
#include <stdio.h>
int main() {
    uint64_t test_values[] = {0, 1, 2, 8, 0x10000ULL, 0x8000000000000000ULL};
    int num_tests = sizeof(test_values) / sizeof(test_values[0]);

    for (int i = 0; i < num_tests; ++i) {
        printf("ctz64(0x%016llx) = %d\n", test_values[i], ctz64_debruijn(test_values[i]));
    }
    // Expected output:
    // ctz64(0x0000000000000000) = 64
    // ctz64(0x0000000000000001) = 0
    // ctz64(0x0000000000000002) = 1
    // ctz64(0x0000000000000008) = 3
    // ctz64(0x0000000000010000) = 16
    // ctz64(0x8000000000000000) = 63
    return 0;
}
*/



# Input in a0
    slli    a1, a0, 1      # a1 = x * 2
    add     a0, a0, a1     # a0 = x * 3
    slli    a1, a0, 2      # a1 = (x * 3) * 4 = x * 12
    add     a0, a0, a1     # a0 = x * 15
    slli    a1, a0, 4      # a1 = (x * 15) * 16 = x * 240
    add     a0, a0, a1     # a0 = x * 255
    slli    a1, a0, 8      # a1 = x * 255 * 256
    sub     a0, a1, a0     # a0 = x * (255 * 256 - 255) = x * 0x07EDD5E59A4E28C2

.endif


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
