.include "config.s"
.include "mul-macs.s"

.globl divremu
.globl divrem

	.text

################################################################################
# routine: divremu
#
# Unsigned integer division using a restoring algorithm.
# RV32I/RV32E/RV64I compatible (uses a0-a3, t0-t2).
# This started from the routine in vmon, I think written by Bruce Hout and
# grew over time.
#
# NOTE: This routine must NOT clobber a4 or a5. The signed divrem wrapper 
#       relies on these registers being preserved across the call to avoid 
#       stack overhead on RV32E.
#
# input registers:
# a0 = dividend
# a1 = divisor
#
# output registers:
# a0 = quotient
# a1 = remainder
################################################################################

.equ    MSB_SHIFT, (CPU_BITS - 1)

.if DIVREMU_UNROLLED == 0

###### ROLLED VERSION (Small Size) #############################################

divremu:
	# Check for division by zero
	beqz	a1, divremu_zero

	mv	a2, a0			# Use a2 for dividend/quotient
	mv	a0, zero		# a0 will hold the remainder

.if HAS_ZBB
	# Optimization: Skip leading zeros
	clz	t0, a2			# Count leading zeros of Dividend
	li	a3, CPU_BITS
	sub	a3, a3, t0		# Loop Count = CPU_BITS - LeadingZeros

	# Align the MSB of the dividend to the MSB position of the register
	sll	a2, a2, t0

	# Edge case: If dividend was 0, a3 is 0. Skip loop.
	beqz	a3, divremu_done
.else
	li	a3, CPU_BITS		# Use a3 as the loop counter
.endif

divremu_loop:
	# Extract MSB
	srli	t0, a2, MSB_SHIFT

	# Shift Remainder and Merge new bit
.if HAS_ZBA
	# sh1add rd, rs1, rs2  ->  rd = rs2 + (rs1 << 1)
	sh1add	a0, a0, t0
.else
	slli	a0, a0, 1
	or	a0, a0, t0
.endif

	# Shift Dividend left
	slli	a2, a2, 1

	# Compare Remainder vs Divisor
	sltu	t1, a0, a1		# t1 = 1 if Rem < Div (Fail)

	# Branchless Subtract
.if HAS_ZICOND
	# If t1 (Fail) is set, subtract 0. If clear, subtract Divisor.
	czero.nez t2, a1, t1		# this makes me so happy
.else
	addi	t2, t1, -1		# Mask: 0 if Fail, -1 if Pass
	and	t2, a1, t2		# t2 = Divisor or 0
.endif

	sub	a0, a0, t2

	# Update Quotient Bit
	xori	t1, t1, 1		# Invert: 1 = Pass
	or	a2, a2, t1		# Add bit to quotient

	# Loop maintenance
	addi	a3, a3, -1
	bnez	a3, divremu_loop

	# Fall through to 'COMMON EPILOGUE'
.else

###### UNROLLED VERSION (4x) #############################################

.macro DIV_STEP
	# Shift Remainder & Merge MSB
	srli	t0, a2, MSB_SHIFT

.if HAS_ZBA == 1
	sh1add	a0, a0, t0
.else
	slli	a0, a0, 1
	or	a0, a0, t0
.endif

	# Prepare Dividend/Quotient
	slli	a2, a2, 1

	# Compare
	sltu	t0, a0, a1	# t0 = 1 if Rem < Div (Fail)

	# Branchless Subtraction Logic
.if HAS_ZICOND == 1
	czero.nez t2, a1, t0	# this makes me so happy
.else
	addi	t1, t0, -1	# Mask
	and	t2, a1, t1	# Filter
.endif
	sub	a0, a0, t2

	# Update Quotient Bit
	xori	t0, t0, 1
	or	a2, a2, t0
.endm

divremu:
	beqz	a1, divremu_zero

	mv	a2, a0		# a2 = Dividend
	mv	a0, zero	# a0 = Remainder
	li	a3, (CPU_BITS/4)# Loop counter (8 or 16)

div_loop_4x:
	DIV_STEP
	DIV_STEP
	DIV_STEP
	DIV_STEP

	addi	a3, a3, -1
	bnez	a3, div_loop_4x

.endif

###### COMMON EPILOGUE #########################################################

divremu_done:
	mv	a1, a0			# Remainder
	mv	a0, a2			# Quotient
	ret

divremu_zero:
	mv	a1, a0			# Remainder = Dividend
	li	a0, -1			# Quotient = MAX
	ret

.size divremu, .-divremu

################################################################################
# routine: divrem
#
# Signed integer division - rounds towards zero.
# RV32E/RV32I/RV64I Compatible
#
# Constraints:
# - Relies on divremu NOT clobbering a4 or a5.
#
# input:  a0 = dividend (N), a1 = divisor (D)
# output: a0 = quotient (Q), a1 = remainder (R)
################################################################################

.equ	SIGN_BIT_SHIFT, (CPU_BITS - 1)

divrem:
	# Setup Stack and Save Inputs
	FRAME	1
	PUSH	ra, 0

	mv	t0, a0		# t0 = Original N
	mv	t1, a1		# t1 = Original D

	# Handle Zero Divisor
	beq	t1, zero, divrem_by_zero

	# Handle Overflow (INT_MIN / -1)
.if HAS_ZBS == 1
	bseti	t2, zero, SIGN_BIT_SHIFT
.else
	# Construct INT_MIN safely for both 32/64
	li	t2, 1
	slli	t2, t2, SIGN_BIT_SHIFT	# t2 = INT_MIN (0x800...00)
.endif

	# Check conditions
	bne	t0, t2, divrem_abs	# If N != INT_MIN, safe
	li	a2, -1			# CHANGED: t3 -> a2 (RV32E fix)
	beq	t1, a2, divrem_overflow # If N==MIN && D==-1, Overflow

divrem_abs:
	# Compute Absolute Values (Branchless)
	# Generate Sign Masks (0 = Pos, -1 = Neg)
	srai	a4, t0, SIGN_BIT_SHIFT	# CHANGED: t4 -> a4 (Sign Mask N)
	srai	a5, t1, SIGN_BIT_SHIFT	# CHANGED: t5 -> a5 (Sign Mask D)

	# Apply Abs(N)
	xor	a0, t0, a4
	sub	a0, a0, a4		# a0 = abs(N)

	# Apply Abs(D)
	xor	a1, t1, a5
	sub	a1, a1, a5		# a1 = abs(D)

	# Perform Unsigned Division
	# WARNING: We assume divremu does NOT clobber a4 or a5.
	jal	divremu
	# Returns: a0 = abs(Q), a1 = abs(R)

	# Apply Signs (Branchless)

	# Quotient Sign: Sign(N) ^ Sign(D)
	xor	t0, a4, a5		# t0 = Sign Mask Q
	xor	a0, a0, t0
	sub	a0, a0, t0		# Q = Q * Sign

	# Remainder Sign: Sign(N)
	# If N was negative (a4 = -1), we negate R.
	# If N was positive (a4 = 0), we leave R.
	xor	a1, a1, a4
	sub	a1, a1, a4		# R = R * Sign(N)

divrem_cleanup_stack:
	POP	ra, 0
	EFRAME	1
	ret

# --- Exception Paths ---

divrem_by_zero:
	li	a0, -1			# Spec: Q = -1 (all 1s)
	mv	a1, t0			# Spec: R = Dividend
	j	divrem_cleanup_stack

divrem_overflow:
	# Return INT_MIN / 0
.if HAS_ZBS == 1
	bseti	a0, zero, SIGN_BIT_SHIFT	# Q = INT_MIN
.else
	li	a0, 1
	slli	a0, a0, SIGN_BIT_SHIFT	# Q = INT_MIN
.endif
	li	a1, 0			# R = 0
	j	divrem_cleanup_stack

.size divrem, .-divrem
