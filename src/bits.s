.include "config.s"
.globl bits_ctz
.globl bits_clz

# count trailing zeroes via binary search (use for processors with no B extension)
# input
# a0 number
# output
# a0 result

bits_ctz:
	beqz	a0, bits_ctz_is_zero
	mv	t2, zero	# result

.if CPU_BITS == 64
	li	t1, -1
	srli	t1, t1, 32
	and	t0, a0, t1
	bnez	t0, bits_ctz_lower_16
	addi	t2, t2, 32
	srli	a0, a0, 32
.endif

bits_ctz_lower_16:
	li	t1, 0xffff
	and	t0, a0, t1
	bnez	t0, bits_ctz_lower_8
	addi	t2, t2, 16	# lower 16 are zero, add to count
	srli	a0, a0, 16

bits_ctz_lower_8:
	andi	t0, a0, 0xff
	bnez	t0, bits_ctz_lower_4
	addi	t2, t2, 8
	srli	a0, a0, 8

bits_ctz_lower_4:
	andi	t0, a0, 0xf
	bnez	t0, bits_ctz_lower_2
	addi	t2, t2, 4
	srli	a0, a0, 4

bits_ctz_lower_2:
	andi	t0, a0, 0x3
	bnez	t0, bits_ctz_lower_1
	addi	t2, t2, 2
	srli	a0, a0, 2

bits_ctz_lower_1:
	andi	t0, a0, 0x1
	bnez	t0, bits_ctz_done
	addi	t2, t2, 1

bits_ctz_done:
	mv	a0, t2
	ret

bits_ctz_is_zero:
	li	a0, CPU_BITS
	ret

.size	bits_ctz, .-bits_ctz

# count leading zeroes via binary search (use for processors with no B extension)
# input
# a0 number
# output
# a0 result

bits_clz:
	beqz	a0, bits_clz_is_zero
	mv	t2, zero	# result

.if CPU_BITS == 64
	srli	t0, a0, 32
	bnez	t0, bits_clz_upper_16
	addi	t2, t2, 32



	li	t1, -1
	slli	t1, t1, 32
	and	t0, a0, t1
	bnez	t0, bits_clz_upper_16
	addi	t2, t2, 32
	srli	a0, a0, 32
.endif



bits_clz_is_zero:
	mv	a0, t2
	ret

bits_clz_is_zero:
	li	a0, 32
	ret


.size	bits_clz, .-bits_clz
