.include "config.s"

.globl nmul
.globl mul32
.globl m128

.text


################################################################################
# routine: nmul
#
# Native word length signed/unsigned multiplication. RV32I/RV32E/RV64I.
#
# Optimizations:
# - Swaps operands to ensure the smaller value is the multiplier (loop counter).
# - Uses 'ctz' (Count Trailing Zeros) if HAS_ZBB is defined to skip zero bits.
#
# input registers:
# a0 = multiplicand
# a1 = multiplier
#
# output registers:
# a0 = product
################################################################################

nmul:
	# Optimization: Swap operands to minimize loop iterations
	# We want the multiplier (a1) to be the smaller unsigned value.
	bgeu	a0, a1, nmul_no_swap
	mv	a2, a0
	mv	a0, a1
	mv	a1, a2
nmul_no_swap:

	# Setup
	mv	a2, a0			# a2 = multiplicand
	li	a0, 0			# a0 = product (accumulator)

	# Optimization: Skip blocks of zeros (Zbb Extension)
.if HAS_ZBB
nmul_loop:
	beqz	a1, nmul_done		# Exit if multiplier is 0

	ctz	a3, a1			# a3 = Count Trailing Zeros of multiplier
	srl	a1, a1, a3		# Shift multiplier right by count
	sll	a2, a2, a3		# Shift multiplicand left by count

	# LSB of multiplier is now guaranteed to be 1
	add	a0, a0, a2		# product += multiplicand

	# Prepare for next bit
	srli	a1, a1, 1		# Shift multiplier right by 1
	slli	a2, a2, 1		# Shift multiplicand left by 1
	j	nmul_loop

.else
	# Standard Shift-and-Add Loop
nmul_loop:
	andi	a3, a1, 1		# Check LSB
	beqz	a3, nmul_skip
	add	a0, a0, a2		# product += multiplicand
nmul_skip:
	srli	a1, a1, 1		# Shift multiplier right
	slli	a2, a2, 1		# Shift multiplicand left
	bnez	a1, nmul_loop
.endif

nmul_done:
	ret
.size nmul, .-nmul

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
	
.if CPU_BITS == 64
################################################################################
# routine: m128
#
# 64x64-bit to 128-bit Multiplication (Signed/Unsigned).
#
# Optimizations:
# - Swap: Ensures Multiplier is the smaller operand.
# - Zbb Tight Loop: Uses 'ctz' to skip zeros and performs unconditional adds.
# - Unrolling: Base ISA path unrolled 2x to reduce branch overhead.
#
# Input:  a0, a1 (operands), a2 (sign flag)
# Output: a0 (Low), a1 (High)
################################################################################
m128:
	# --- 1. Sign & Absolute Value Setup ---
	li	a7, 0			# a7 = Final Sign Flag (0 = Pos)

	beqz	a2, m128_setup_unsigned

	# Calculate Final Sign
	xor	t0, a0, a1
	slt	a7, t0, zero

	# Branchless Absolute Value
	srai	t0, a0, 63
	xor	a0, a0, t0
	sub	a0, a0, t0		# a0 = |a0|

	srai	t0, a1, 63
	xor	a1, a1, t0
	sub	a1, a1, t0		# a1 = |a1|

m128_setup_unsigned:
	# --- 2. Swap Optimization ---
	# Minimize iterations by making a1 the smaller value
	bgeu	a0, a1, m128_no_swap
	mv	t0, a0
	mv	a0, a1
	mv	a1, t0
m128_no_swap:

	# --- 3. Register Setup ---
	# a4: Mcand Low (SM_L)
	# a6: Mcand High (SM_H)
	# a5: Multiplier (MP)
	# a0: Product Low (P_L)
	# a1: Product High (P_H)

	mv	a4, a0
	mv	a5, a1
	li	a6, 0
	li	a0, 0
	li	a1, 0

	# Early exit
	beqz	a5, m128_finalize

# ==============================================================================
# Path A: Zbb Optimized Loop (Skip Zeros -> Unconditional Add)
# ==============================================================================
.if HAS_ZBB
m128_zbb_loop:
	ctz	t0, a5			# Count trailing zeros
	beqz	t0, m128_zbb_add	# If LSB is 1 (ctz=0), skip shift logic

	# 1. Skip Zeros in Multiplier
	srl	a5, a5, t0

	# 2. Variable 128-bit Shift of Mcand (a6:a4) << t0
	sll	a6, a6, t0
	li	t1, 64
	sub	t1, t1, t0
	srl	t2, a4, t1
	or	a6, a6, t2
	sll	a4, a4, t0

m128_zbb_add:
	# 3. Unconditional Add (LSB is known to be 1)
	# P_L += SM_L
	add	t1, a0, a4
	sltu	t2, t1, a0		# Carry?
	mv	a0, t1
	# P_H += SM_H + Carry
	add	a1, a1, a6
	add	a1, a1, t2

	# 4. Advance 1 bit (Consume the 1 we just added)
	srli	a5, a5, 1
	beqz	a5, m128_finalize	# Done if multiplier empty

	# Shift 128-bit Mcand Left by 1
	srli	t0, a4, 63
	slli	a6, a6, 1
	or	a6, a6, t0
	slli	a4, a4, 1

	j	m128_zbb_loop

# ==============================================================================
# Path B: Base ISA Loop (Unrolled 2x)
# ==============================================================================
.else
m128_base_loop:
	# --- Bit 0 ---
	andi	t0, a5, 1
	beqz	t0, m128_base_skip1

	# Add
	add	t1, a0, a4
	sltu	t2, t1, a0
	mv	a0, t1
	add	a1, a1, a6
	add	a1, a1, t2

m128_base_skip1:
	srli	a5, a5, 1		# Mult >> 1
	# Shift Mcand << 1
	srli	t0, a4, 63
	slli	a6, a6, 1
	or	a6, a6, t0
	slli	a4, a4, 1
	
	beqz	a5, m128_finalize	# Early exit check

	# --- Bit 1 ---
	andi	t0, a5, 1
	beqz	t0, m128_base_skip2

	# Add
	add	t1, a0, a4
	sltu	t2, t1, a0
	mv	a0, t1
	add	a1, a1, a6
	add	a1, a1, t2

m128_base_skip2:
	srli	a5, a5, 1		# Mult >> 1
	# Shift Mcand << 1
	srli	t0, a4, 63
	slli	a6, a6, 1
	or	a6, a6, t0
	slli	a4, a4, 1

	bnez	a5, m128_base_loop
.endif

m128_finalize:
	# --- 4. Final Negation ---
	beqz	a7, m128_done

	# Negate 128-bit
	not	a0, a0
	not	a1, a1
	addi	a0, a0, 1
	sltu	t0, a0, 1
	add	a1, a1, t0

m128_done:
	ret
.size m128, .-m128

.endif
