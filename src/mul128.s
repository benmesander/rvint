.include "config.s"

.globl m128

.text
	
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
