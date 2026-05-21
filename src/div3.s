.include "config.s"
.include "mul-macs.s"

.if CONSTANT_TABLE
.section .srodata, "a", @progbits
.align 3
M_div3:
	.quad 0x5555555555555556	# M = (2**63 + 2) / 3
.endif

.globl div3
.text

.if HAS_ZMMUL == 1
################################################################################
# routine: div3
#
# Signed fast division by 3 for processors with a multiply instruction
# Algorithm: "Magic Number" - Hacker's Delight 2nd ed. sec 10.3,
# Suitable for RV32I_Zmmul, RV64I_Zmmul
# Note: unless your core has the Zkt instruction, this may not run in
#       constant time, consult your vendor documentation.
#
# input:  a0 = signed dividend
# output: a0 = signed quotient
################################################################################
div3:

.if CPU_BITS == 64
.if CONSTANT_TABLE
	ld	a2, M_div3
.else
	# this option is best for constant time (no possibility of cache miss)
	li	a2, 0x5555555555555556
.endif
	mulh	a1, a0, a2
.else
	li	a2, 0x55555556	# M = magic number, (2**32+2)/3
	mulhsu	a1, a0, a2	# q = floor(M*n/2**32)
.endif
	slti	a2, a0, 0	# a2 = 1 if a0 < 0 (negative), else 0
	add	a0, a1, a2	# q = a0 = a1 + a2

	ret
.else
# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div3
#
# Signed fast division by 3.
# Algorithm: Abs(n) -> Unsigned Div -> Restore Sign.
# Suitable for RV32E, RV32I, RV64I
#
# input:  a0 = signed dividend
# output: a0 = signed quotient
################################################################################
div3:
	# 1. Preamble: Compute Sign Mask (t0) and Abs(n) (a0)
	srai	t0, a0, CPU_BITS-1	# t0 = -1 if n < 0, else 0
	xor	a0, a0, t0		# a0 = n ^ sign
	sub	a0, a0, t0		# a0 = (n ^ sign) - sign = abs(n)

	# 2. Series Expansion (Approximates Q_abs = abs(n) / 3)
	srli	a1, a0, 2
	srli	a2, a0, 4
	add	a1, a2, a1		# q = (n >> 2) + (n >> 4)
	srli	a2, a1, 4
	add	a1, a2, a1		# q += q >> 4
	srli	a2, a1, 8
	add	a1, a2, a1		# q += q >> 8
	srli	a2, a1, 16
	add	a1, a2, a1		# q += q >> 16
.if CPU_BITS == 64
	srli	a2, a1, 32
	add	a1, a2, a1		# q += q >> 32
.endif

	# 3. Calculate Remainder / Error
	#    R = abs(n) - 3*Q_est
	mul3	a2, a1, a2		# a2 = 3 * Q_est
	sub	a2, a0, a2		# a2 = abs(n) - 3*Q_est (Remainder)

	# 4. Branchless Correction
	#    Correction = (R * 11) >> 5
	mul11	a3, a2, a0		# a3 = R * 11
	srli	a3, a3, 5
	add	a1, a1, a3		# a1 = Q_abs (corrected)

	# 5. Postamble: Restore Sign
	xor	a0, a1, t0
	sub	a0, a0, t0

	ret
.endif
.size div3, .-div3
