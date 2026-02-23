.include "config.s"
.include "mul-macs.s"
.globl to_decu
.text

################################################################################
# routine: to_decu
#
# Convert unsigned integer to ASCII decimal string.
# RV32I, RV32E, RV64I, RV128I, RV32IM, RV64IM, RV128IM
# Optimizations:
# - HAS_M: Uses hardware div/rem (Fastest).
# - HAS_ZBA: Uses optimal sh2add/sh3add for corrections (via mul10 macro)
# - Base: Uses robust series expansion for div10u.
#
# Input:  a0 = unsigned number
# Output: a0 = address of string buffer
#         a1 = length of string
################################################################################
to_decu:
	# 1. setup buffer (work backwards)
	la	a2, iobuf
	addi	a2, a2, IOBUF_CAPACITY
	mv	a1, a2			# end pointer
	sb	zero, 0(a2)		# nul-terminate

	# 2. loop setup
	mv	a3, a0			# a3 = n

to_decu_loop:
	addi	a2, a2, -1		# decrement buffer ptr

.if HAS_M
	# path 1: hardware division
	li	t0, 10
	remu	a5, a3, t0		# a5 = n % 10 (digit)
	divu	a3, a3, t0		# a3 = n / 10 (next n)

.else
	# path 2: series expansion
	# estimate q = n * 0.1
	srli	t0, a3, 2
	sub	a4, a3, t0		# a4 = n * 0.75

	srli	t0, a4, 4
	add	a4, a4, t0
	srli	t0, a4, 8
	add	a4, a4, t0
	srli	t0, a4, 16
	add	a4, a4, t0

.if CPU_BITS >= 64
	srli	t0, a4, 32
	add	a4, a4, t0
.endif

.if CPU_BITS == 128
	# extends series to 128 bits
	srli	t0, a4, 64
	add	a4, a4, t0
.endif
	srli	a4, a4, 3		# a4 = q_est

	# correction check: diff = 10*q - n
	mul10	a5, a4, t0		# a5 = 10 * q (uses t0 as scratch)
	sub	a5, a5, a3		# a5 = diff

	# threshold: diff <= -10
	slti	t0, a5, -9		# t0 = correction (0 or 1)
	add	a3, a4, t0		# a3 = n_new

	# remainder calculation
	# digit = -diff - 10*correction
	sub	a5, zero, a5		# a5 = -diff
	mul10	t1, t0, t2		# t1 = 10 * c (uses t2 as scratch)
	sub	a5, a5, t1		# a5 = digit
.endif

	# store digit
	addi	a5, a5, '0'
	sb	a5, 0(a2)

	bnez	a3, to_decu_loop

	# 3. finalize
	mv	a0, a2			# return start ptr
	sub	a1, a1, a2		# return length
	ret
.size to_decu, .-to_decu
