.include "config.s"
.include "mul-macs.s"

.if CONSTANT_TABLE
.section .srodata, "a", @progbits
.align 3
M_div5:
	.quad 0x6666666666666667
.endif

.globl div5
.text

.if HAS_ZMMUL == 1
################################################################################
# routine: div5
#
# Signed fast division by 5 for processors with a multiply instruction
# Algorithm: "Magic Number" - Hacker's Delight 2nd ed. sec 10.3,
# Suitable for RV32I_Zmmul, RV64I_Zmmul
# Note: unless your core has the Zkt instruction, this may not run in
#       constant time, consult your vendor documentation.
#
# input:  a0 = signed dividend
# output: a0 = signed quotient
################################################################################
div5:

.if CPU_BITS == 64
.if CONSTANT_TABLE
	ld	a2, M_div5
.else
	# this option is best for constant time (no possibility of cache miss)
#	li	a2, 0x6666666666666667
	lui	a2, 0x66666
	addi	a2, 0x666
	slli	a3, a2, 32
	add	a2, a3, a2
	addi	a2, a2, 1	# ...67
.endif
	mulh	a1, a0, a2
	slti	a2, a0, 0	# a2 = 1 if a0 < 0 (negative), else 0
	srai	a1, a1, 1	# shift q right once - do after slti to avoid stall
.else
	li	a2, 0x66666667  # (2**33+3)/5
	mulhsu	a1, a0, a2	# q = floor(M*n/2**32)
	slti	a2, a0, 0	# a2 = 1 if a0 < 0 (negative), else 0
.endif
	add	a0, a1, a2	# q = a0 = a1 + a2

	ret
.else
# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div5
#
# Signed fast division by 5 without using M extension.
# This routine provides a single, implementation for
# RV32I, RV32E, and RV64I.
#
# Algorithm: abs(n) / 5 -> restore sign.
#
# input registers:
#   a0 = signed dividend (32 or 64 bits)
#
# output registers:
#   a0 = quotient (signed, a0 / 5)
#
################################################################################

div5:
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0	# a0 = abs(n), t0 = sign flag

	# Initial Estimate: q = n * 0.75
	# n - n/4 = 0.75n
	srli	a2, a0, 2
	sub	a1, a0, a2

	# Series Expansion: Converge 0.75 -> 0.8
	srli	a2, a1, 4
	add	a1, a1, a2	# q += q >> 4
	srli	a2, a1, 8
	add	a1, a1, a2	# q += q >> 8
	srli	a2, a1, 16
	add	a1, a1, a2	# q += q >> 16
.if CPU_BITS == 64
	srli	a2, a1, 32
	add	a1, a1, a2	# q += q >> 32
.endif

	# Final Shift: q_est = (n * 0.8) / 4 = n / 5
	srli	a1, a1, 2

# Check = 5 * q_est
	mul5	a2, a1, a2	
	
	# Diff = 5q - abs(n)
	# Range if exact: [-4, 0]
	# Range if under: [-9, -5]
	sub	a2, a2, a0

	# Threshold Check: Is Diff <= -5?
	# -5 < -4 -> 1 (Correction needed)
	slti	a3, a2, -4

	# Apply Correction
	add	a1, a1, a3	# a1 = q_ab

	# restore sign
	xor	a0, a1, t0
	sub	a0, a0, t0
	ret
.endif
.size div5, .-div5
