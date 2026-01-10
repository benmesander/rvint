.include "config.s"

.globl mul32

.text

################################################################################
# routine: mul32
#
# Signed 32x32 -> 64-bit multiplication.
#
# Constraints:
# - No M-Extension instructions.
# - RV32E Compatible (Uses only a0-a5, t0-t2).
#
# Input:  a0 = multiplicand (signed 32-bit)
#         a1 = multiplier (signed 32-bit)
# Output: a0 = product low (signed 32-bit, sign-extended on RV64)
#         a1 = product high (signed 32-bit, sign-extended on RV64)
################################################################################

mul32:
.if CPU_BITS == 64
	# ---------------------------------------------------------
	# RV64I Implementation
	# ---------------------------------------------------------
	
	# 1. Sign Extend Inputs
	sext.w	a0, a0
	sext.w	a1, a1

	# 2. Determine Result Sign
	xor	t0, a0, a1		# t0 = Sign Diff

	# 3. Absolute Values
.if HAS_ZBB
	neg	t1, a0
	max	a0, a0, t1		# a0 = max(a0, -a0) = abs(a0)
	neg	t1, a1
	max	a1, a1, t1		# a1 = max(a1, -a1) = abs(a1)
.else
	srai	t1, a0, 63
	xor	a0, a0, t1
	sub	a0, a0, t1
	srai	t1, a1, 63
	xor	a1, a1, t1
	sub	a1, a1, t1
.endif

	# 4. Swap for Optimization (Smallest as Multiplier)
	bgeu	a0, a1, mul32_rv64_no_swap
	mv	t1, a0
	mv	a0, a1
	mv	a1, t1
mul32_rv64_no_swap:

	# Setup Loop
	# a0 = Mcand (Large)
	# a1 = Multiplier (Small)
	mv	a2, a0			# a2 = Working Mcand
	li	a0, 0			# a0 = Accumulator
	
	# Optimization: Early exit for 0
	beqz	a1, mul32_rv64_split

# ==============================================================================
# Path A: Zbb Optimized Loop (Skip Zeros)
# ==============================================================================
.if HAS_ZBB
mul32_rv64_loop:
	ctz	t1, a1			# Find count of trailing zeros
	srl	a1, a1, t1		# Shift multiplier right by count
	sll	a2, a2, t1		# Shift multiplicand left by count
	
	add	a0, a0, a2		# Unconditional Add (LSB is known 1)

	srli	a1, a1, 1		# Consume the '1'
	slli	a2, a2, 1		# Shift Mcand
	bnez	a1, mul32_rv64_loop	# Continue if multiplier not empty
	
# ==============================================================================
# Path B: Base ISA Loop
# ==============================================================================
.else
mul32_rv64_loop:
	andi	t1, a1, 1		# Check LSB
	beqz	t1, mul32_rv64_skip
	add	a0, a0, a2		# Accum += Mcand
mul32_rv64_skip:
	srli	a1, a1, 1		# Multiplier >> 1
	slli	a2, a2, 1		# Mcand << 1
	bnez	a1, mul32_rv64_loop
.endif

	# 5. Restore Sign & Split
	bgez	t0, mul32_rv64_split
	
.if HAS_ZBB
	neg	a0, a0
.else
	sub	a0, zero, a0
.endif

mul32_rv64_split:
	srli	a1, a0, 32
	sext.w	a1, a1
	sext.w	a0, a0
	ret

.else
	# ---------------------------------------------------------
	# RV32I / RV32E Implementation
	# ---------------------------------------------------------
	# Note: Zbb loop is not implemented for RV32 here because 
	# variable 64-bit shifting on 32-bit registers is costly 
	# and register constrained (RV32E). We stick to the standard loop.

	# 1. Determine Result Sign
	xor	a5, a0, a1

	# 2. Absolute Values
.if HAS_ZBB
	neg	t0, a0
	max	a0, a0, t0
	neg	t0, a1
	max	a1, a1, t0
.else
	srai	t0, a0, 31
	xor	a0, a0, t0
	sub	a0, a0, t0
	srai	t0, a1, 31
	xor	a1, a1, t0
	sub	a1, a1, t0
.endif

	# 3. Swap for Optimization
	bgeu	a0, a1, mul32_rv32_no_swap
	mv	t0, a0
	mv	a0, a1
	mv	a1, t0
mul32_rv32_no_swap:

	# 4. Loop Setup
	mv	a2, a1			# a2 = Multiplier (Small)
	mv	a3, a0			# a3 = Mcand Low
	li	a4, 0			# a4 = Mcand High
	li	t0, 0			# t0 = Prod Low
	li	t1, 0			# t1 = Prod High

mul32_rv32_loop:
	andi	t2, a2, 1
	beqz	t2, mul32_rv32_skip

	# Add 64-bit: Product += Mcand
	add	t0, t0, a3		# Lo += Lo
	sltu	t2, t0, a3		# Carry?
	add	t1, t1, t2		# Hi += Carry
	add	t1, t1, a4		# Hi += Hi

mul32_rv32_skip:
	srli	a2, a2, 1		# Multiplier >> 1
	beqz	a2, mul32_rv32_sign

	# Shift 64-bit: Mcand << 1
	slli	a4, a4, 1		# Hi << 1
	srli	t2, a3, 31		# Extract MSB of Lo
	or	a4, a4, t2		# Merge MSB into Hi
	slli	a3, a3, 1		# Lo << 1
	j	mul32_rv32_loop

mul32_rv32_sign:
	# 5. Restore Sign
	bgez	a5, mul32_rv32_done

	# Negate 64-bit (Product = ~Product + 1)
	not	t0, t0
	not	t1, t1
	addi	t0, t0, 1		# Lo += 1
	sltu	t2, t0, 1		# Carry out of Low?
	add	t1, t1, t2		# Hi += Carry

mul32_rv32_done:
	mv	a0, t0
	mv	a1, t1
	ret
.endif
.size mul32, .-mul32
