.include "config.s"

.globl nmul
.globl mul32
.globl m128

.text

################################################################################
# routine: nmul
#
# Native word length (64 on 64-bit processors, 32 on 32-bit processors)
# multiplication via shift-and-add technique.
#
# - RV32I: 32x32 -> 32 bit result (signed or unsigned)
# - RV64I: 64x64 -> 64 bit result (signed or unsigned)
# Implemented using only RV32I / RV64I base instructions (No 'M' Extension).
# This provides the functionality of the M extension mul/mulu/mulw instructions
#
# input registers:
# a0 = CPU_BITS-bit multiplicand
# a1 = CPU_BITS-bit multiplier
#
# output registers:
# a0 = CPU_BITS-bit product (lower bits)
################################################################################

nmul:
	# a0: product (starts at 0, accumulates, becomes output)
	# a1: current_multiplier (starts with original a1, then shifts right, modified)
	# a2: current_multiplicand (starts with original a0, then shifts left)
	# a3: temporary for LSB check

	mv	a2, a0			# a2 = current_multiplicand (from input a0)
        # Input a1 (operand2) will be used directly as current_multiplier and be modified.
	mv	a0, zero		# a0 = product = 0 (a0 will hold the result)

nmul_loop:
	andi	a3, a1, 1		# t2 = LSB of current_multiplier (a1)
	beqz	a3, nmul_skip		# LSB is 0, skip addition
	add	a0, a0, a2		# product (a0) += current_multiplicand (a2)
nmul_skip:
	srli	a1, a1, 1		# Shift current_multiplier (a1) right by 1 (logical)
	slli	a2, a2, 1		# Shift current_multiplicand (a2) left by 1 (logical)
	bnez	a1, nmul_loop		# exit loop when multiplier is 0

	ret				# a0 contains result

.size	nmul, .-nmul

################################################################################
# routine: mul32
#
# Unified (RV64I and RV32I) Unsigned/Signed 32x32-bit to 64-bit multiply. This
# provides the functionality of the M extension mul/mulh instructions
#
# input registers:
# a0 = op1
# a1 = op2
# a2 = signed_flag: 0=unsigned, 1=signed
#
# output registers:
# a0 = product low word
# a1 = product high word
################################################################################

mul32:	
	FRAME	3				# Allocate stack frame for ra, s0, s1
	PUSH	ra, 0				# Save ra to stack
	PUSH	s0, 1				# Save s0 to stack
	PUSH	s1, 2				# Save s1 to stack

	# Registers:
	# a0: op1_in -> abs_op1_for_mult (temporarily via a5) -> pl_accumulator -> prod_low_out
	# a1: op2_in -> abs_op2_for_mult (temporarily via s0) -> ph_accumulator -> prod_high_out
	# a2: signed_flag_in
	# s0: mp (shifting multiplier) - starts as abs_op2 (was a6)
	# a5: sm_l (shifted multiplicand low) - starts as abs_op1
	# s1: sm_h (shifted multiplicand high) (was a7)
	# a4: op1_is_negative_temp, op2_is_negative_temp, scratch
	# a3: scratch (LSB, sums, carries, done)
	# t0: final_sign_is_negative

	# --- Argument and Sign Processing ---
	mv	a5, a0				# a5 = op1 (will become abs_op1, then sm_l)
	mv	s0, a1				# s0 = op2 (will become abs_op2, then mp)
	mv	t0, zero			# t0 (final_sign_is_negative) = 0

	beqz	a2, mul32_unsigned_args # If unsigned_flag (a2==0), skip sign handling

	# Signed path (a2 != 0)
	mv	a4, zero			# a4 will hold op1_is_negative
	slt	a3, a5, zero			# a3 = (op1 < 0)
	beqz	a3, mul32_op1_abs_done
	mv	a4, a3				# op1_is_negative = 1
	sub	a5, zero, a5			# a5 = abs(op1)
.if CPU_BITS == 64
	slli	a5, a5, 32			# zero top 32 bits of a5
	srli	a5, a5, 32
.endif

mul32_op1_abs_done:
	# a3 is free now, use for op2_is_negative
	mv	a3, zero
	slt	a7, s0, zero			# a7 used as temp for (op2 < 0) - using a7 as it's free here
	beqz	a7, mul32_op2_abs_done
	mv	a3, a7				# op2_is_negative = 1
	sub	s0, zero, s0			# s0 = abs(op2)
.if CPU_BITS == 64
	slli 	s0, s0, 32			# zero top 32 bits of s0
	srli 	s0, s0, 32
.endif
mul32_op2_abs_done:
	xor	t0, a4, a3			# t0 (final_sign_is_negative) = op1_is_neg ^ op2_is_neg

mul32_unsigned_args:
	# Inputs for core loop:
	# a5 holds abs_multiplicand (becomes initial sm_l)
	# s0 holds abs_multiplier (becomes initial mp)
	# t0 holds final_sign_is_negative

	# --- Initialization for Core Unsigned Multiplication Loop ---
	mv	a0, zero			# a0 (pl - product_low_accumulator) = 0
	mv	a1, zero			# a1 (ph - product_high_accumulator) = 0
	# a5 is already sm_l
	mv	s1, zero			# s1 (sm_h - shifted_multiplicand_high) = 0
	# s0 is already mp

	# --- Core Unsigned Multiplication Loop (terminates when mp (s0) is 0) ---
mul32_loop:
	beqz	s0, mul32_end_loop		# If mp (multiplier in s0) is 0, done.

	andi	a3, s0, 1			# a3 = LSB of mp (s0)
	beqz	a3, mul32_skip_add

	# Add shifted_multiplicand (s1:a5 which is sm_h:sm_l) to product (a1:a0 which is ph:pl)
.if CPU_BITS == 32
	add	a3, a0, a5			# a3 = pl + sm_l
	sltu	a4, a3, a0			# a4 = carry_low = (pl_new < pl_old)
	mv	a0, a3				# pl = sum_low

	add	a3, a1, s1			# a3 = ph + sm_h
	add	a1, a3, a4			# ph = ph + sm_h + carry_low
.else // CPU_BITS == 64
	add	a3, a0, a5			# a3_64 = pl_zx32 + sm_l_zx32
	srli	a4, a3, 32			# a4 = carry_low (0 or 1, from bit 32 of sum)
	slli	a0, a3, 32			# Zero-extend new pl (a0)
	srli	a0, a0, 32

	add	a3, a1, s1
	add	a3, a3, a4			# a3_64 = ph_zx32 + sm_h_zx32 + carry_low
	slli	a1, a3, 32			# Zero-extend new ph (a1)
	srli	a1, a1, 32
.endif

mul32_skip_add:	
	# Right-shift multiplier (s0 which is mp) by 1
	srli	s0, s0, 1

	# Left-shift 64-bit shifted_multiplicand (s1:a5 which is sm_h:sm_l) by 1
	# Only shift multiplicand if multiplier is not yet zero (implicit: loop continues if s0!=0)
.if CPU_BITS == 32
	srli	a3, a5, 31			# a3 = MSB of sm_l (a5[31]) -> carry to sm_h
	slli	a5, a5, 1			# sm_l = sm_l << 1
	slli	s1, s1, 1			# sm_h = sm_h << 1
	or	s1, s1, a3			# sm_h = sm_h | carry_from_sm_l
.else // CPU_BITS == 64
	srli	a3, a5, 31			# a3 gets a5[31] (value is 0 or 1)

	slli	a5, a5, 1
	slli	a4, a5, 32			# Temp a4 for zero-extending a5
	srli	a5, a4, 32

	slli	s1, s1, 1
	or	s1, s1, a3
	slli	a4, s1, 32			# Temp a4 for zero-extending s1
	srli	s1, a4, 32
.endif
	j mul32_loop # Check loop condition (s0) again

mul32_end_loop:	
	# Product is now in a1:a0 (ph:pl)
	# t0 holds final_sign_is_negative
	# a2 holds original signed_flag

	# --- Post-Processing: Negate result if signed and negative ---
	beqz 	a2, mul32_done_restore		# If not signed_flag
	beqz 	t0, mul32_done_restore		# If not final_sign_is_negative

	# Negate 64-bit product a1:a0 (ph:pl)
.if CPU_BITS == 32
	xori	a0, a0, -1			# pl = ~pl
	xori	a1, a1, -1			# ph = ~ph
	addi	a0, a0, 1			# pl = pl + 1
	seqz	a3, a0				# If pl is now 0, original ~pl was 0xFFFFFFFF (so carry)
	add	a1, a1, a3			# ph = ph + carry
.else // CPU_BITS == 64
	# Create mask 0x00000000FFFFFFFF in a3
	li	a4, 1
	slli	a4, a4, 32			# a4 = 0x100000000
	addi	a3, a4, -1			# a3 = 0x00000000FFFFFFFF (mask)

	xor	a0, a0, a3			# a0 = ~pl[31:0], remains zx32
	xor	a1, a1, a3			# a1 = ~ph[31:0], remains zx32

	add	a4, a0, 1			# a4_64 = pl_zx32_inverted + 1
	srli	a3, a4, 32			# a3 = carry from bit 31 of (a0_inv+1)
	slli	a0, a4, 32			# Zero-extend the new a0 ( (a0_inv+1)[31:0] )
	srli	a0, a0, 32

	add	a4, a1, a3			# a4_64 = ph_zx32_inverted + carry
	slli	a1, a4, 32			# Zero-extend the new a1
	srli	a1, a1, 32
.endif

mul32_done_restore:
	POP	s1, 2				# Restore s1 from stack
	POP	s0, 1				# Restore s0 from stack
	POP	ra, 0				# Restore ra from stack
	EFRAME	3				# Deallocate stack frame

mul32_done: # Original done label, keep for compatibility if anything jumps here.
	# Result is in a0 (low), a1 (high)
	ret

.size	mul32, .-mul32	

.if CPU_BITS == 64
	
################################################################################
# routine: m128
#
# 64x64-bit to 128-bit Multiplication (Signed/Unsigned) on 64-bit processors.
# This provides the functionality of the mulhu/mulhsu instructions on RV64.
#
# input registers:
# a0 = 64-bit Operand 1 (multiplicand)
# a1 = 64-bit Operand 2 (multiplier)
# a2 = Signedness flag (0 for unsigned, non-zero for signed)
#
# output registers:
# a0 = Lower 64 bits of the 128-bit product
# a1 = Upper 64 bits of the 128-bit product
################################################################################

m128:
	FRAME	3				# s0=SM_H, s1=final_neg_flag, ra
	PUSH	ra, 0
	PUSH	s0, 1
	PUSH	s1, 2

	# --- Argument Preparation & Sign Handling ---
	# Registers:
	# a0: P_L (Product Low accumulator) -> Product_Low_out
	# a1: P_H (Product High accumulator) -> Product_High_out
	# a2: Signedness_flag_in (persistent)
	# a3: Scratch (LSB of MP, op1_neg_temp, carry for final negation, temp_sum_low)
	# a4: |operand1| -> SM_L (Shifted Multiplicand Low)
	# a5: |operand2| -> MP (Multiplier)
	# a6: Scratch (op2_neg_temp, carry_low from P_L+SM_L)
	# s0: SM_H (Shifted Multiplicand High) (was t1)
	# s1: final_product_is_negative_flag (was a7)
	# t0: Scratch (general purpose, e.g. for boolean checks)

	# Move operands to temporary registers to free up a0, a1 for product accumulation.
	mv	a4, a0				# a4 will hold |operand1| (initially operand1, becomes SM_L)
	mv	a5, a1				# a5 will hold |operand2| (initially operand2, becomes MP)
	mv	s1, zero			# s1 (final_product_is_negative_flag) = 0
	beqz a2, m128_unsigned_args	# If a2 is 0, skip sign processing

	# Signed multiplication path (a2 != 0)
	# a3 will store if op1 was negative, a6 if op2 was negative
	mv	a3, zero			# op1_is_negative_temp = 0
	slt	a6, a4, zero			# Check if operand1 (in a4) is negative
	beqz	a6, m128_op1_abs_done
	mv	a3, a6				# op1_is_negative_temp = 1
	sub	a4, zero, a4			# a4 = abs(operand1)

m128_op1_abs_done:
	mv	a6, zero			# op2_is_negative_temp = 0
	slt	t0, a5, zero			# Check if operand2 (in a5) is negative (use t0 as scratch)
	beqz	t0, m128_op2_abs_done
	mv	a6, t0				# op2_is_negative_temp = 1
	sub	a5, zero, a5			# a5 = abs(operand2)

m128_op2_abs_done:
	xor	s1, a3, a6			# s1 (final_product_is_negative) = op1_is_neg ^ op2_is_neg

m128_unsigned_args:	
	# At this point:
	# a4 holds |operand1| (this will be SM_L initially)
	# a5 holds |operand2| (this will be MP initially)
	# s1 holds the final_product_is_negative_flag

	# --- Initialization for Core Unsigned 64x64 -> 128-bit Multiplication Loop ---
	mv	a0, zero			# a0 (P_L - Product Low accumulator) = 0
	mv	a1, zero			# a1 (P_H - Product High accumulator) = 0
	# a4 is already SM_L (Shifted Multiplicand Low)
	mv	s0, zero			# s0 (SM_H - Shifted Multiplicand High) = 0
	# a5 is already MP (Multiplier)

	# --- Core Unsigned Multiplication Loop (terminates when MP (a5) is 0) ---
m128_loop:
	beqz	a5, m128_end_loop		# If MP (Multiplier in a5) is 0, end loop

	# Check LSB of MP (Multiplier in a5)
	andi	a3, a5, 1			# a3 = LSB of MP
	beqz	a3, m128_skip_add		# If LSB is 0, skip adding SM to P

	# LSB is 1: Add 128-bit SM (s0:a4) to 128-bit P (a1:a0)
	# P_L (a0) = P_L (a0) + SM_L (a4)
	# P_H (a1) = P_H (a1) + SM_H (s0) + carry_from_low_addition
	add	a3, a0, a4			# a3 (temp_sum_low) = P_L + SM_L
	sltu	a6, a3, a0			# a6 (carry_low) = (temp_sum_low < P_L_old) ? 1 : 0
	mv	a0, a3				# Update P_L

	add	a1, a1, s0			# P_H = P_H + SM_H
	add	a1, a1, a6			# P_H = P_H + carry_low

m128_skip_add:	
	# Right-shift 64-bit MP (Multiplier in a5) by 1 (logical)
	srli	a5, a5, 1

	# Left-shift 128-bit SM (Shifted Multiplicand in s0:a4) by 1 (logical)
	# Only shift if multiplier (a5) is not zero yet (already checked by loop condition)
	srli	a3, a4, 63			# a3 = MSB of SM_L (this is the carry from SM_L to SM_H)
	slli	a4, a4, 1			# SM_L <<= 1
	slli	s0, s0, 1			# SM_H <<= 1
	or	s0, s0, a3			# SM_H |= carry_from_SM_L

	j	m128_loop			# Check loop condition (a5) again

m128_end_loop:	
	# Unsigned 128-bit product is now in a1:a0 (P_H:P_L)
	# s1 holds final_product_is_negative_flag
	# a2 holds original signed_flag_in

	# --- Post-Processing: Negate 128-bit result if signed and negative ---
	beqz	a2, m128_done_restore	# If not signed_flag_in, skip negation
	beqz	s1, m128_done_restore	# If not final_product_is_negative_flag, skip

	# Negate the 128-bit product in a1:a0 (2's complement)
	xori	a0, a0, -1			# P_L = ~P_L
	xori	a1, a1, -1			# P_H = ~P_H

	addi	a0, a0, 1			# P_L = P_L + 1
	seqz	a3, a0				# a3 = (P_L_new == 0) ? 1 : 0 (this is the carry to P_H)
        # This works because if P_L was 0xFF...FF before addi,
        # it becomes 0 and sets a3 to 1.
	add	a1, a1, a3			# P_H = P_H + carry

m128_done_restore:
	POP	s1, 2
	POP	s0, 1
	POP	ra, 0
	EFRAME	3
m128_done:	
	# Final 128-bit result is in a1:a0 (High:Low)
	ret
.size	m128, .-m128

.endif
