.include "config.s"

.globl nmul
.globl mul32
.globl m128

.text

# native word length multiplication via shift-and-add technique
#
# - RV32I: 32x32 -> 32 bit result (signed or unsigned)
# - RV64I: 64x64 -> 64 bit result (signed or unsigned)
# Implemented using only RV32I / RV64I base instructions (No 'M' Extension).
#
# Calling convention:
#   Inputs:
#     a0: CPU_BITS-bit signed multiplicand
#     a1: CPU_BITS-bit signed multiplier
#
#   Outputs:
#     a0: CPU_BITS-bit signed product (lower bits)
#
#   CPU_BITS comes from config.s, it is either 32 or 64.
#

nmul:
	# t0: current_multiplicand (starts with original a0, then shifts left)
	# a1: current_multiplier (starts with original a1, then shifts right, modified)
	# a0: product (starts at 0, accumulates, becomes output)
	# t1: loop_count
	# t2: temporary for LSB check

	mv	t0, a0			# t0 = current_multiplicand (from input a0)
        # Input a1 (operand2) will be used directly as current_multiplier and be modified.
	mv	a0, zero		# a0 = product = 0 (a0 will hold the result)
	li	t1, CPU_BITS		# t1 = loop_count

nmul_loop:
	andi	t2, a1, 1		# t2 = LSB of current_multiplier (a1)
	beqz	t2, nmul_skip		# LSB is 0, skip addition
	add	a0, a0, t0		# product (a0) += current_multiplicand (t0)
nmul_skip:
	srli	a1, a1, 1		# Shift current_multiplier (a1) right by 1 (logical)
	slli	t0, t0, 1		# Shift current_multiplicand (t0) left by 1 (logical)
	addi	t1, t1, -1
	bnez	t1, nmul_loop

	ret				# a0 contains result

.size	nmul, .-nmul

#
# Unified (RV64I and RV32I) Unsigned/Signed 32x32-bit to 64-bit multiply 
# - No 'M' Extension. Uses only argument and temporary registers. No stack frame.
#
# Inputs: a0 (op1), a1 (op2), a2 (signed_flag: 0=unsigned, 1=signed)
# Outputs: a0 (prod_low), a1 (prod_high)
#

mul32:	
	# Registers:
	# a0: op1_in -> abs_op1_for_mult -> pl_accumulator -> prod_low_out
	# a1: op2_in -> abs_op2_for_mult (temporarily) -> ph_accumulator -> prod_high_out
	# a2: signed_flag_in
	# t0: sm_l (shifted multiplicand low) - starts as abs_op1
	# t1: mp (shifting multiplier) - starts as abs_op2
	# t2: sm_h (shifted multiplicand high)
	# t3: op1_is_negative_temp, op2_is_negative_temp, scratch
	# t4: count
	# t5: scratch (LSB, sums, carries)
	# t6: final_sign_is_negative

	# --- Argument and Sign Processing ---
	mv	t0, a0				# t0 = op1
	mv	t1, a1				# t1 = op2
	mv	t6, zero			# t6 (final_sign_is_negative) = 0

	beqz	a2, mul32_unsigned_args # If unsigned_flag (a2==0), skip sign handling

	# Signed path (a2 != 0)
	mv	t3, zero			# t3 will hold op1_is_negative
	slt	t5, t0, zero			# t5 = (op1 < 0)
	beqz	t5, mul32_op1_abs_done
	mv	t3, t5				# op1_is_negative = 1
	sub	t0, zero, t0			# t0 = abs(op1)
.if CPU_BITS == 64
	slli	t0, t0, 32			# zero top 32 bits of t0
	srli	t0, t0, 32
.endif

mul32_op1_abs_done:
	# t5 is free now, use for op2_is_negative
	mv	t5, zero
	slt	t2, t1, zero			# t2 used as temp for (op2 < 0)
	beqz	t2, mul32_op2_abs_done
	mv	t5, t2				# op2_is_negative = 1
	sub	t1, zero, t1			# t1 = abs(op2)
.if CPU_BITS == 64
	slli 	t1, t1, 32			# zero top 32 bits of t1
	srli 	t1, t1, 32
.endif
mul32_op2_abs_done:
	xor	t6, t3, t5			# t6 (final_sign_is_negative) = op1_is_neg ^ op2_is_neg

mul32_unsigned_args:
	# Inputs for core loop:
	# t0 holds abs_multiplicand (becomes initial sm_l)
	# t1 holds abs_multiplier (becomes initial mp)
	# t6 holds final_sign_is_negative

	# --- Initialization for Core Unsigned Multiplication Loop ---
	mv	a0, zero			# a0 (pl - product_low_accumulator) = 0
	mv	a1, zero			# a1 (ph - product_high_accumulator) = 0
	# t0 is already sm_l
	mv	t2, zero			# t2 (sm_h - shifted_multiplicand_high) = 0
	# t1 is already mp
	li	t4, 32				# t4 (count) = 32

	# --- Core Unsigned Multiplication Loop (32 iterations for 32x32) ---
mul32_loop:
	beqz	t4, mul32_end_loop

	andi	t5, t1, 1			# t5 = LSB of mp (t1)
	beqz	t5, mul32_skip

	# Add shifted_multiplicand (t2:t0 which is sm_h:sm_l) to product (a1:a0 which is ph:pl)
.if CPU_BITS == 32
	add	t5, a0, t0			# t5 = pl + sm_l
	sltu	t3, t5, a0			# t3 = carry_low = (pl_new < pl_old)
	mv	a0, t5				# pl = sum_low

	add	t5, a1, t2			# t5 = ph + sm_h
	add	a1, t5, t3			# ph = ph + sm_h + carry_low
.else // CPU_BITS == 64
	add	t5, a0, t0			# t5_64 = pl_zx32 + sm_l_zx32
	srli	t3, t5, 32			# t3 = carry_low (0 or 1, from bit 32 of sum)
	slli	a0, t5, 32			# Zero-extend new pl (a0)
	srli	a0, a0, 32

	add	t5, a1, t2
	add	t5, t5, t3			# t5_64 = ph_zx32 + sm_h_zx32 + carry_low
	slli	a1, t5, 32			# Zero-extend new ph (a1)
	srli	a1, a1, 32
.endif

mul32_skip:	
	# Right-shift multiplier (t1 which is mp) by 1
	srli	t1, t1, 1

	# Left-shift 64-bit shifted_multiplicand (t2:t0 which is sm_h:sm_l) by 1
.if CPU_BITS == 32
	srli	t5, t0, 31			# t5 = MSB of sm_l (t0[31]) -> carry to sm_h
	slli	t0, t0, 1			# sm_l = sm_l << 1
	slli	t2, t2, 1			# sm_h = sm_h << 1
	or	t2, t2, t5			# sm_h = sm_h | carry_from_sm_l
.else // CPU_BITS == 64
	srli	t5, t0, 31			# t5 gets t0[31] (value is 0 or 1)

	slli	t0, t0, 1
	slli	t3, t0, 32			# Temp t3 for zero-extending t0
	srli	t0, t3, 32

	slli	t2, t2, 1
	or	t2, t2, t5
	slli	t3, t2, 32			# Temp t3 for zero-extending t2
	srli	t2, t3, 32
.endif

	addi	t4, t4, -1			# count--
	bnez	t4, mul32_loop

mul32_end_loop:	
	# Product is now in a1:a0 (ph:pl)
	# t6 holds final_sign_is_negative
	# a2 holds original signed_flag

	# --- Post-Processing: Negate result if signed and negative ---
	beqz 	a2, mul32_done			# If not signed_flag
	beqz 	t6, mul32_done			# If not final_sign_is_negative

	# Negate 64-bit product a1:a0 (ph:pl)
.if CPU_BITS == 32
	xori	a0, a0, -1			# pl = ~pl
	xori	a1, a1, -1			# ph = ~ph
	addi	a0, a0, 1			# pl = pl + 1
	seqz	t5, a0				# If pl is now 0, original ~pl was 0xFFFFFFFF (so carry)
	add	a1, a1, t5			# ph = ph + carry
.else // CPU_BITS == 64
	# Create mask 0x00000000FFFFFFFF in t5
	li	t3, 1
	slli	t3, t3, 32			# t3 = 0x100000000
	addi	t5, t3, -1			# t5 = 0x00000000FFFFFFFF (mask)

	xor	a0, a0, t5			# a0 = ~pl[31:0], remains zx32
	xor	a1, a1, t5			# a1 = ~ph[31:0], remains zx32

	add	t3, a0, 1			# t3_64 = pl_zx32_inverted + 1
	srli	t5, t3, 32			# t5 = carry from bit 31 of (a0_inv+1)
	slli	a0, t3, 32			# Zero-extend the new a0 ( (a0_inv+1)[31:0] )
	srli	a0, a0, 32

	add	t3, a1, t5			# t3_64 = ph_zx32_inverted + carry
	slli	a1, t3, 32			# Zero-extend the new a1
	srli	a1, a1, 32
.endif

mul32_done:
	# Result is in a0 (low), a1 (high)
	ret

.size	mul32, .-mul32	

.if CPU_BITS == 64
	
# RV64I: 64x64-bit to 128-bit Multiplication (Signed/Unsigned, Software Implementation)
# No 'M' Extension. Leaf function (no stack frame for ra or s-registers).
#
# Calling convention:
#   Inputs:
#     a0: 64-bit Operand 1 (multiplicand)
#     a1: 64-bit Operand 2 (multiplier)
#     a2: Signedness flag (0 for unsigned, non-zero for signed)
#
#   Outputs:
#     a0: Lower 64 bits of the 128-bit product
#     a1: Upper 64 bits of the 128-bit product
#
# Register Usage (all caller-saved or argument/return registers):
#   Input Arguments:
#     a0 (op1_in), a1 (op2_in), a2 (signed_flag_in)
#
#   Output Registers (accumulate product):
#     a0 (P_L - Product Low)
#     a1 (P_H - Product High)
#
#   Temporary Registers:
#     t0: SM_L (Shifted Multiplicand Low) - starts as abs(op1_in)
#     t1: SM_H (Shifted Multiplicand High) - starts as 0
#     t2: MP (Multiplier, shifts right) - starts as abs(op2_in)
#     t3: count (loop counter, 64 down to 0)
#     t4: scratch / op1_is_negative_temp / carry for 128-bit add
#     t5: scratch / op2_is_negative_temp / intermediate sum for 128-bit add
#     t6: final_product_is_negative_flag (0 or 1)
#

m128:
	# --- Argument Preparation & Sign Handling ---
	# Move operands to temporary registers to free up a0, a1 for product accumulation.
	mv	t0, a0				# t0 will hold |operand1| (initially operand1)
	mv	t2, a1				# t2 will hold |operand2| (initially operand2)
	mv	t6, zero			# t6 (final_product_is_negative_flag) = 0
	beqz a2, m128_unsigned			# If a2 is 0, skip sign processing

	# Signed multiplication path (a2 != 0)
	# t4 will store if op1 was negative, t5 if op2 was negative
	mv	t4, zero			# op1_is_negative_temp = 0
	slt	t5, t0, zero			# Check if operand1 (in t0) is negative
	beqz	t5, m128_op1_abs_done
	mv	t4, t5				# op1_is_negative_temp = 1
	sub	t0, zero, t0			# t0 = abs(operand1)

m128_op1_abs_done:
	mv	t5, zero			# op2_is_negative_temp = 0
	slt	t3, t2, zero			# Check if operand2 (in t2) is negative (use t3 as scratch)
	beqz	t3, m128_op2_abs_done
	mv	t5, t3				# op2_is_negative_temp = 1
	sub	t2, zero, t2			# t2 = abs(operand2)

m128_op2_abs_done:
	xor	t6, t4, t5			# t6 (final_product_is_negative) = op1_is_neg ^ op2_is_neg

m128_unsigned:	
	# At this point:
	# t0 holds |operand1| (this will be SM_L initially)
	# t2 holds |operand2| (this will be MP initially)
	# t6 holds the final_product_is_negative_flag (0 if unsigned or if signed product is positive)

	# --- Initialization for Core Unsigned 64x64 -> 128-bit Multiplication Loop ---
	mv	a0, zero			# a0 (P_L - Product Low accumulator) = 0
	mv	a1, zero			# a1 (P_H - Product High accumulator) = 0
	# t0 is already SM_L (Shifted Multiplicand Low)
	mv	t1, zero			# t1 (SM_H - Shifted Multiplicand High) = 0
	# t2 is already MP (Multiplier)
	li	t3, 64				# t4 (count) = 64 iterations

	# --- Core Unsigned Multiplication Loop ---
m128_loop:
	beqz	t3, m128_end_loop		# If count is 0, exit loop

	# Check LSB of MP (Multiplier in t2)
	andi	t4, t2, 1			# t4 = LSB of MP
	beqz	t4, m128_skip_add		# If LSB is 0, skip adding SM to P

	# LSB is 1: Add 128-bit SM (t1:t0) to 128-bit P (a1:a0)
	# P_L (a0) = P_L (a0) + SM_L (t0)
	# P_H (a1) = P_H (a1) + SM_H (t1) + carry_from_low_addition
	add	t4, a0, t0			# t4 (temp_sum_low) = P_L + SM_L
	sltu	t5, t4, a0			# t5 (carry_low) = (temp_sum_low < P_L_old) ? 1 : 0
	mv	a0, t4				# Update P_L

	add	a1, a1, t1			# P_H = P_H + SM_H
	add	a1, a1, t5			# P_H = P_H + carry_low

m128_skip_add:	
	# Right-shift 64-bit MP (Multiplier in t2) by 1 (logical)
	srli	t2, t2, 1

	# Left-shift 128-bit SM (Shifted Multiplicand in t1:t0) by 1 (logical)
	srli	t4, t0, 63			# t4 = MSB of SM_L (this is the carry from SM_L to SM_H)
	slli	t0, t0, 1			# SM_L <<= 1
	slli	t1, t1, 1			# SM_H <<= 1
	or	t1, t1, t4			# SM_H |= carry_from_SM_L

	addi	t3, t3, -1			# count--
	bnez	t3, m128_loop			# Loop if count is not zero

m128_end_loop:	
	# Unsigned 128-bit product is now in a1:a0 (P_H:P_L)
	# t6 holds final_product_is_negative_flag
	# a2 holds original signed_flag_in

	# --- Post-Processing: Negate 128-bit result if signed and negative ---
	beqz	a2, m128_done			# If not signed_flag_in, skip negation
	beqz	t6, m128_done			# If not final_product_is_negative_flag, skip

	# Negate the 128-bit product in a1:a0 (2's complement)
	xori	a0, a0, -1			# P_L = ~P_L
	xori	a1, a1, -1			# P_H = ~P_H

	addi	a0, a0, 1			# P_L = P_L + 1
	seqz	t4, a0				# t4 = (P_L_new == 0) ? 1 : 0 (this is the carry to P_H)
        # This works because if P_L was 0xFF...FF before addi,
        # it becomes 0 and sets t4 to 1.
	add	a1, a1, t4			# P_H = P_H + carry

m128_done:	
	# Final 128-bit result is in a1:a0 (High:Low)
	ret
.size	m128, .-m128

.endif
