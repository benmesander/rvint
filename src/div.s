.include "config.s"
.include "mul-macs.s"

.globl divremu
.globl divrem
.globl div3u
.globl div5u
.globl div6u
.globl div7u
.globl div9u
.globl div10u
.globl div11u
.globl div12u
.globl div13u
.globl div100u
.globl div1000u
.globl div3
.globl div5
.globl div7
.globl mod3u
.globl mod3

.text

################################################################################
# routine: divremu
#
# Unsigned integer division using a restoring algorithm. This started as
# something from vmon, I think written by Bruce Hout, but it mutated over time.
# RV32E compatible (uses a0-a3, t0-t2).
#
# Configuration:
# - DIVREMU_UNROLLED: 0 (Small/Slow) or 1 (Fast/Large)
# - CPU_BITS:         32 or 64
# - HAS_ZBB:          0 or 1 (clz)
# - HAS_ZBA:          0 or 1 (sh1add)
# - HAS_ZICOND:       0 or 1 (czero.nez)
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
	czero.nez t2, a1, t1
.else
	addi	t2, t1, -1		# Mask: 0 if Fail, -1 if Pass
	and	t2, a1, t2		# t2 = Divisor or 0
.endif

	sub	a0, a0, t2

	# Step 6: Update Quotient Bit
	xori	t1, t1, 1		# Invert: 1 = Pass
	or	a2, a2, t1		# Add bit to quotient

	# Loop maintenance
	addi	a3, a3, -1
	bnez	a3, divremu_loop

	# Fall through to 'COMMON EPILOGUE'
.else

###### UNROLLED VERSION (4x Speed) #############################################

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
# Handles 32-bit or 64-bit based on CPU_BITS.
#
# Constraints:
# Relies on divremu NOT clobbering t4 or t5 (ABI deviation for speed).
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
	li	t3, -1
	beq	t1, t3, divrem_overflow # If N==MIN && D==-1, Overflow

divrem_abs:
	# Compute Absolute Values (Branchless)
	# Generate Sign Masks (0 = Pos, -1 = Neg)
	srai	t4, t0, SIGN_BIT_SHIFT	# t4 = Sign Mask N (Kept for later)
	srai	t5, t1, SIGN_BIT_SHIFT	# t5 = Sign Mask D (Kept for later)

	# Apply Abs(N)
	xor	a0, t0, t4
	sub	a0, a0, t4		# a0 = abs(N)

	# Apply Abs(D)
	xor	a1, t1, t5
	sub	a1, a1, t5		# a1 = abs(D)

	# Perform Unsigned Division
	# WARNING: We assume divremu does NOT clobber t4 or t5.
	call	divremu
	# Returns: a0 = abs(Q), a1 = abs(R)

	# Apply Signs (Branchless)

	# Quotient Sign: Sign(N) ^ Sign(D)
	xor	t0, t4, t5		# t0 = Sign Mask Q
	xor	a0, a0, t0
	sub	a0, a0, t0		# Q = Q * Sign

	# Remainder Sign: Sign(N)
	# If N was negative (t4 = -1), we negate R.
	# If N was positive (t4 = 0), we leave R.
	xor	a1, a1, t4
	sub	a1, a1, t4		# R = R * Sign(N)

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
	li	a0, 1
	slli	a0, a0, SIGN_BIT_SHIFT	# Q = INT_MIN
	li	a1, 0			# R = 0
	j	divrem_cleanup_stack

.size divrem, .-divrem

################################################################################
# routine: div3u
#
# Unsigned fast division by 3 without using M extension.
# This routine is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses a fast multiply/shift/add/correct algorithm.
# Suitable for use on RV32E architectures.
#
# input registers:
# a0 = unsigned dividend (32 or 64 bits)
#
# output registers:
# a0 = quotient (unsigned)
################################################################################
div3u:
	# a0 contains n
	srli	a1, a0, 2		# a1: q = n >> 2
	srli	a2, a0, 4		# a2: n >> 4
	add	a1, a2, a1		# a1: q = (n >> 2) + (n >> 4)
	srli	a2, a1, 4		# a2: q >> 4
	add	a1, a2, a1		# a1: q = q + (q >> 4)
	srli	a2, a1, 8		# a2: q >> 8
	add	a1, a2, a1		# a1: q = q + (q >> 8)
	srli	a2, a1, 16		# a2: q >> 16
	add	a1, a2, a1		# a1: q = q + (q >> 16)
.if CPU_BITS == 64
	srli	a2, a1, 32		# a2: q >> 32
	add	a1, a2, a1		# a1: q = q + (q >> 32)
.endif
	# Remainder calculation
	mul3	a2, a1, a2
	sub	a2, a0, a2		# a2: r = n - q * 3

.if CPU_BITS == 64
	# Correction step for 64-bit
	# Handles errors up to 6+. Calculates floor(r*11/32).
	mul11	a0, a2, a0	# a0 = r * 11
	srli	a0, a0, 5	# a0 = 11r/32: correction amount
.else
	# Correction step for 32-bit
	# Sufficient for errors up to 5. Calculates floor((5r+5)/16).
	mul5	a0, a2, a0
	addi	a0, a0, 5
	srli	a0, a0, 4	# a0/16: correction amount
.endif

	add	a0, a1, a0	# a0: q + correction
	ret

.size div3u, .-div3u

################################################################################
# routine: div5u
#
# Unsigned fast division by 5 without using M extension.
# This routine is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses a fast multiply/shift/add/correct algorithm.
# Suitable for use on RV32E architectures.
#
# input registers:
# a0 = unsigned dividend (32 or 64 bits)
#
# output registers:
# a0 = quotient (unsigned)
################################################################################
div5u:
	srli	a2, a0, 2
	sub	a1, a0, a2
	srli	a2, a1, 4	# a2 = (q >> 4)
	add	a1, a1, a2	# a1 = q + (q >> 4)
	srli	a2, a1, 8	# a2 = (q >> 8)
	add	a1, a1, a2	# a1 = q + (q >> 8)
	srli	a2, a1, 16	# a2 = (q >> 16)
	add	a1, a1, a2	# a1 = q + (q >> 16)
.if CPU_BITS == 64
	srli	a2, a1, 32	# a2 = (q >> 32)
	add	a1, a1, a2	# a1 = q + (q >> 32)
.endif
	srli	a1, a1, 2	# a1 = q = q >> 2 (Final approximate quotient)

	# Calculate r = n - q*5
	mul5	a2, a1, a2	# a2 = q * 5
	sub	a2, a2, a0
	slti	a3, a2, -4
	add	a0, a1, a3	# a0 = q + correction
	ret
.size div5u, .-div5u

################################################################################
# routine: div6u
#
# Unsigned fast division by 6 without using M extension.
# This routine is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses a fast multiply/shift/add/correct algorithm.
# Suitable for use on RV32E architectures.
#
# input registers:
# a0 = unsigned dividend (32 or 64 bits)
#
# output registers:
# a0 = quotient (unsigned)
################################################################################
div6u:
	# Calculate approximate quotient q_est.
	srli	a1, a0, 1	# a1 = (n >> 1)
	srli	a2, a0, 3	# a2 = (n >> 3)
	add	a1, a1, a2	# q = (n >> 1) + (n >> 3)
	srli	a2, a1, 4	# a2 = (q >> 4)
	add	a1, a1, a2	# q = q + (q >> 4)
	srli	a2, a1, 8	# a2 = (q >> 8)
	add	a1, a1, a2	# q = q + (q >> 8)
	srli	a2, a1, 16	# a2 = (q >> 16)
	add	a1, a1, a2	# q = q + (q >> 16)
.if CPU_BITS == 64
	srli	a2, a1, 32	# a2 = (q >> 32)
	add	a1, a1, a2	# q = q + (q >> 32)
.endif
	srli	a1, a1, 2	# q = q >> 2

	# Calculate negative remainder r = n - 6*q
	mul6	a2, a1, a2	# a2 = q * 6
	sub	a2, a2, a0
	slti	a3, a2, -5	# calculate correction
	add	a0, a1, a3	# apply correction
	ret
.size	div6u, .-div6u

################################################################################
# routine: div7u
#
# Unsigned fast division by 7 without using M extension.
# This routine is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses a fast multiply/shift/add/correct algorithm.
# Suitable for use on RV32E architectures.
#
# input registers:
# a0 = unsigned dividend (32 or 64 bits)
#
# output registers:
# a0 = quotient (unsigned)
################################################################################
div7u:
	srli	a1, a0, 1	# a1 = (n >> 1)
	srli	a2, a0, 4	# a2 = (n >> 4)
	add	a1, a1, a2	# a1 = q = (n >> 1) + (n >> 4)
	srli	a2, a1, 6	# a2 = (q >> 6)
	add	a1, a1, a2	# a1 = q = q + (q >> 6)
	srli	a2, a1, 12	# a2 = (q >> 12)
	add	a1, a1, a2
	srli	a2, a1, 24	# a2 = (q >> 24)
	add	a1, a1, a2	# a1 = q + (q >> 24)
.if CPU_BITS == 64
	srli	a2, a1, 48	# a2 = (q >> 48)
	add	a1, a1, a2	# a1 = q + (q >> 48)
.endif
	srli	a1, a1, 2	# a1 = q >> 2

	slli	a2, a1, 3	# (q * 8)
	sub	a2, a2, a1	# a3 = (q * 7) = (q * 8) - q
	sub	a2, a2, a0	# negative remainder
	slti	a3, a2, -6
	add	a0, a1, a3	# correct quotient
	ret

.size	div7u, .-div7u

################################################################################
# routine: div9u
#
# Unsigned fast division by 9.
# Approximation: q = n * (1/9)
# Series: 1/9 = (7/8) * (1/8) * (1 + 1/64 + 1/4096...)
#
# RV32E Compatible.
#
# input:  a0 = dividend
# output: a0 = quotient
################################################################################    
div9u:
	# Approximate Quotient: q_accum = n * (8/9)
	# Start with n * (7/8)
	srli	a2, a0, 3	# a2 = n >> 3
	sub	a1, a0, a2	# a1 = n - (n >> 3) = n * 0.875
	# Series expansion: Multiply by (1 + 1/64 + 1/4096...)
	srli	a2, a1, 6
	add	a1, a1, a2	# q += q >> 6
	srli	a2, a1, 12
	add	a1, a1, a2	# q += q >> 12
	srli	a2, a1, 24
	add	a1, a1, a2	# q += q >> 24
.if CPU_BITS == 64
	srli	a2, a1, 48
	add	a1, a1, a2	# q += q >> 48
.endif

	# Final adjustment: q = (n * 8/9) / 8 = n / 9
	srli	a1, a1, 3	# a1 = q_approx

	# Negative Remainder -9 < -8 -> 1 (correction), -8 < -8 -> 0 (no corr)
	mul9	a3, a1, a2
	sub	a2, a2, a0
	slti	a3, a2, -8
	add	a0, a1, a3	# q = q + correction

	ret
.size div9u, .-div9u

################################################################################
# routine: div10u
#
# Unsigned fast division by 10 without using M extension.
# This routine is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses a fast multiply/shift/add/correct algorithm.
# Suitable for use on RV32E architectures.
#
# input registers:
# a0 = unsigned dividend (32 or 64 bits)
#
# output registers:
# a0 = quotient (unsigned)
################################################################################
div10u:
	# Phase 1: Calculate approximate quotient
	# Target: q_accum = n * 0.8

	# n - (n >> 2) = 0.75n
	srli	a2, a0, 2
	sub	a1, a0, a2

	# series expansion
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

	# Final adjustment: (n * 0.8) / 8 = n / 10
	srli	a1, a1, 3

	# Phase 2: Calculate r = n - 10*q
	mul10	a2, a1, a3	# a2 = 10q
	sub	a2, a2, a0	# negative remainder

	# Phase 3: Correction - Diff < -9 implies remainder >= 10
	slti	a3, a2, -9
	add	a0, a1, a3

	ret
.size div10u, .-div10u

################################################################################
# routine: div11u
#
# Unsigned fast division by 11 without using M extension.
# This routine is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses a fast multiply/shift/add/correct algorithm.
# Suitable for use on RV32E architectures.
#
# input registers:
# a0 = unsigned dividend (32 or 64 bits)
#
# output registers:
# a0 = quotient (unsigned)
################################################################################	
div11u:
	srli	a1, a0, 1	# a1 = (n >> 1)
	srli	a2, a0, 2	# a2 = (n >> 2)
	add	a1, a1, a2	# a1 = (n >> 1) + (n >> 2)
	srli	a2, a0, 5	# a2 = (n >> 5)
	sub	a1, a1, a2	# a1 = (n >> 1) + (n >> 2) - (n >> 5)
	srli	a2, a0, 7	# a2 = (n >> 7)
	add	a1, a1, a2	# a1 = q = (n >> 1) + (n >> 2) - (n >> 5) + (n >> 7)
	srli	a2, a1, 10	# a2 = (q >> 10)
	add	a1, a1, a2	# a1 = q = q + (q >> 10)
	srli	a2, a1, 20	# a2 = (q >> 20)
	add	a1, a1, a2	# a1 = q = q + (q >> 20)
.if CPU_BITS == 64
	srli	a2, a1, 40	# a2 = (q >> 40)
	add	a1, a1, a2	# a1 = q = q + (q >> 40)
.endif

	srli	a2, a1, 3	# a2 = q = (q >> 3) (note: a1 = q << 3)

	# compute remainder
	mul11	a1, a2, a3	# a1 = q_est * 11
	sub	a1, a1, a0	# negative remainder
	# Threshold Check: Is Diff < -10?
	# -11 < -10 -> 1 (Correction needed)
	# -10 < -10 -> 0 (No correction)
	slti	a3, a1, -10
	add	a0, a2, a3	# a0 = q = q_est + correction
	ret

.size div11u, .-div11u

################################################################################
# routine: div12u
#
# Unsigned fast division by 12 without using M extension.
# This routine is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses a fast multiply/shift/add/correct algorithm.
# Suitable for use on RV32E architectures.
#
# input registers:
# a0 = unsigned dividend (32 or 64 bits)
#
# output registers:
# a0 = quotient (unsigned)
################################################################################	
div12u:
	# compute approximate quotient
	# n/2 + n/8 = 0.625n
	srli	a1, a0, 1	# a1 = (n >> 1)
	srli	a2, a0, 3	# a2 = (n >> 3)
	add	a1, a1, a2	# a1 = q = (n >> 1) + (n >> 3)

	# continue series expansion
	srli	a2, a1, 4	# a2 = (q >> 4)
	add	a1, a1, a2	# a1 = q = q + (q >> 4)
	srli	a2, a1, 8	# a2 = (q >> 8)
	add	a1, a1, a2	# a1 = q = q + (q >> 8)
	srli	a2, a1, 16	# a2 = (q >> 16)
	add	a1, a1, a2	# a1 = q = q + (q >> 16)
.if CPU_BITS == 64
	srli	a2, a1, 32	# a2 = (q >> 32)
	add	a1, a1, a2	# a1 = q + (q >> 32)
.endif
	srli	a1, a1, 3

	# compute remainder
	mul12	a2, a1, a2	# a2 = q*12
	sub	a2, a2, a0	# negative remainder
	slti	a3, a2, -11
	add	a0, a1, a3	# a0 = q = q + correction
	ret

.size div12u, .-div12u

################################################################################
# routine: div13u
#
# Unsigned fast division by 13 without using M extension.
# This routine is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses a fast multiply/shift/add/correct algorithm.
# Suitable for use on RV32E architectures.
#
# input registers:
# a0 = unsigned dividend (32 or 64 bits)
#
# output registers:
# a0 = quotient (unsigned)
################################################################################	
div13u:
	# estimate quotient
	# n / 2 + n / 16 = 9/16 * n
	srli	a1, a0, 1	# a1 = (n >> 1)
	srli	a2, a0, 4	# a2 = (n >> 4)
	add	a1, a1, a2	# a1 = q = (n >> 1) + (n >> 4)

	srli	a2, a1, 4	# a2 = (q >> 4) 
	add	a1, a1, a2	# a1 = q + (q >> 4)
	srli	a2, a2, 1	# a2 = (q >> 5) parallel addition
	add	a1, a1, a2	# a1 = q + (q >> 4) + (q >> 5)
	srli	a2, a1, 12	# a2 = (q >> 12)
	add	a1, a1, a2	# a1 = q + (q >> 12)
	srli	a2, a2, 12	# a2 = (q >> 24) parallel addition
	add	a1, a1, a2	# a1 = q + (q >> 12) + (q >> 24)
.if CPU_BITS == 64
	# refine quotient for 64 bit values
	srli	a2, a2, 24
	add	a1, a1, a2
.endif
	srli	a1, a1, 3	# a1 = q = q >> 3

	# compute remainder
	mul13	a2, a1, a2
	sub	a2, a0, a2	# a2 = r = n - q*13

	# correct estimated quotient
	# compute corr = floor(r / 13) using (r * 5) >> 6
	mul5	a3, a2, a3
	srli	a3, a3, 6	# (approx r / 12.8)
	add	a0, a1, a3	# a0 = q + correction

	ret

.size div13u, .-div13u

################################################################################
# routine: div100u
#
# Unsigned fast division by 100 without using M extension.
# This routine is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses a fast multiply/shift/add/correct algorithm.
# Suitable for use on RV32E architectures.
#
# input registers:
# a0 = unsigned dividend (32 or 64 bits)
#
# output registers:
# a0 = quotient (unsigned)
################################################################################	
div100u:
	# estimate quotient
	srli	a1, a0, 1	# a1 = (n >> 1)
	srli	a2, a0, 3	# a2 = (n >> 3)
	add	a1, a1, a2	# a1 = (n >> 1) + (n >> 3)

	# Series Expansion: q *= 1.01587... (Target 0.6349)
	srli	a2, a1, 6
	add	a1, a1, a2	# q += q >> 6
	srli	a2, a1, 12
	add	a1, a1, a2	# q += q >> 12
	srli	a2, a1, 24
	add	a1, a1, a2	# q += q >> 24
.if CPU_BITS == 64
	srli	a2, a1, 48
	add	a1, a1, a2	# q += q >> 48
.endif

	# Precision Correction: q *= 1.0078... (Target 0.64)
	# Current: 0.6349. Target 0.64. Gap is ~1/128.
	srli	a2, a1, 7
	add	a1, a1, a2	# q += q >> 7

	# Final shift: (n * 0.64) / 64 = n / 100
	srli	a1, a1, 6	# a1 = q_approx

	# Compute remainder from estimated quotient
	mul100	a2, a1, a2
	sub	a2, a2, a0	# negative remainder
	slti	a3, a2, -99
	add	a0, a1, a3	# a0 = q = q + correction
	ret

.size div100u, .-div100u


################################################################################
# routine: div1000u
#
# Unsigned fast division by 1000 without using M extension.
# This routine is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses a fast multiply/shift/add/correct algorithm.
# Suitable for use on RV32E architectures.
#
# The series approximation for 64-bit numbers results in large errors in the
# estimated quotient. We use a macro, estimate_q, to refine the 64-bit estimate.
# While we need to do three passes worst case, we make each pass use successively
# fewer terms, so the 2nd and 3rd passes are faster than the first.
#
# Approximate cycle count:
# RV32I/RV32E: 25
# RV32I w/ZBA: 24
# RV64I:       66
# RV54I w/ZBA: 57
#
# input registers:
# a0 = unsigned dividend (32 or 64 bits)
#
# output registers:
# a0 = quotient (unsigned)
################################################################################	


# Macro: estimate_q
# Args: dest register, src register, and 2 scratch registers.
# + LEVEL (0=Tiny, 1=Medium, 2=Full)
.macro estimate_q dest src scr1 scr2 LEVEL
	# Calculate t
	# t = (3n >> 8) + (n >> 12)
	# Level 2 (Full) must use shifts to avoid 64-bit overflow of (3*n).
	# Levels 0/1 (Med/Tiny) can use Zba sh1add for speed.
.if \LEVEL < 2 && HAS_ZBA
	sh1add	\scr1, \src, \src
	srli	\scr1, \scr1, 8
.else
	srli	\scr1, \src, 7
	srli	\scr2, \src, 8
	add	\scr1, \scr1, \scr2
.endif
	srli	\scr2, \src, 12
	add	\scr1, \scr1, \scr2	# scr1 = t

	# Calculate Base q
	srli	\dest, \src, 1		# q = n >> 1
.if \LEVEL >= 1
	srli	\scr2, \src, 15
	add	\dest, \dest, \scr2	# q += n >> 15
.endif

	# Add t Terms
	add	\dest, \dest, \scr1	# q += t

.if \LEVEL >= 1
	# Medium/Full Terms
	srli	\scr2, \scr1, 11
	add	\dest, \dest, \scr2
	srli	\scr2, \scr1, 14
	add	\dest, \dest, \scr2
	
	# Partial 64-bit Extension (Bits 22, 28)
.if CPU_BITS == 64
	srli	\scr2, \scr1, 22
	add	\dest, \dest, \scr2
	srli	\scr2, \scr1, 28
	add	\dest, \dest, \scr2
.endif
.endif

.if \LEVEL == 2 && CPU_BITS == 64
	# Full 64-bit Extension (Bits 44, 56)
	srli	\scr2, \scr1, 44
	add	\dest, \dest, \scr2
	srli	\scr2, \scr1, 56
	add	\dest, \dest, \scr2
.endif

	# Final Shift
	srli	\dest, \dest, 9
.endm

##### CODE BEGINS HERE #####

div1000u:
	# [PASS 1] Full Precision (Level 2) - for 32-bit this is all that is needed
	# Input: a0. Output: a1.
	estimate_q a1, a0, a2, a3, 2
	mul1000	a2, a1, a3
	sub	a2, a0, a2	# a2 = r1

.if CPU_BITS == 64
	# [PASS 2] Medium Precision (Level 1)
	# Input: a2 (r1). Output: a3.
	estimate_q a3, a2, a4, a5, 1
	mul1000	a4, a3, a5
	sub	a4, a2, a4	# a4 = r2

	# [PASS 3] Tiny Precision (Level 0)
	# Input: a4 (r2). Output: a5.
	estimate_q a5, a4, a2, a0, 0
	mul1000	a2, a5, a0
	sub	a2, a4, a2	# a2 = r3

	# combine
	add	a0, a1, a3
	add	a0, a0, a5

	# correct
	slti	a5, a2, 1000
	xori	a5, a5, 1
	add	a0, a0, a5
	ret

.else
	# 32-bit path
	sub	a2, zero, a2
	sltiu	a3, a2, 1000
	xori	a3, a3, 1
	add	a0, a1, a3
	ret
.endif
.size div1000u, .-div1000u

################################################################################
# routine: div3
#
# Signed fast division by 3 without using M extension.
# This routine is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses a fast multiply/shift/add/correct algorithm.
# Suitable for use on RV32E architectures.
#
# input registers:
# a0 = signed dividend (32 or 64 bits)
#
# output registers:
# a0 = quotient (signed)
################################################################################
div3:

# Preamble: Compute sign mask (t0) and abs(n) (a1)
	srai	t0, a0, CPU_BITS-1	# t0 = (n < 0) ? -1 : 0
	xor	a0, a0, t0		# a0 = n ^ sign
	sub	a0, a0, t0		# a0 = (n ^ sign) - sign = abs(n)

	srli	a1, a0, 2		# a1: q = abs(n) >> 2
	srli	a2, a0, 4		# a2: abs(n) >> 4
	add	a1, a2, a1		# a1: q = q + (abs(n) >> 4)
	srli	a2, a1, 4		# a2: q >> 4
	add	a1, a2, a1		# a1: q = q + (q >> 4)
	srli	a2, a1, 8		# a2: q >> 8
	add	a1, a2, a1		# a1: q = q + (q >> 8)
	srli	a2, a1, 16		# a2: q >> 16
	add	a1, a2, a1		# a1: q = q + (q >> 16)
.if CPU_BITS == 64
	srli	a2, a1, 32		# a2: q >> 32
	add	a1, a2, a1		# a1: q = q + (q >> 32)
.endif

	# Remainder calculation
	# a1 = q_est, a0 = abs(n)
	mul3	a2, a1, a2		# a2 = q_est * 3
	sub	a2, a0, a2		# a2: r = abs(n) - q_est * 3

	# Correction step (calculates correction in a0)
.if CPU_BITS == 64
	# Correction step for 64-bit (5 instructions)
	mul11	a0, a2, a0		# a0 = r * 11
	srli	a0, a0, 5		# a0: correction amount
.else
	# Correction step for 32-bit (4 instructions)
	mul5	a3, a2, a3
	addi	a3, a3, 5
	srli	a0, a3, 4
.endif
	add	a1, a1, a0		# a1 = q_est + correction = abs(n)/3

	# Postamble: Re-apply the original sign (from t0)
	# a1 has the unsigned quotient `q`, t0 has the sign mask
	xor	a0, a1, t0		# a0 = q ^ sign
	sub	a0, a0, t0		# a0 = (q ^ sign) - sign

	ret
.size div3, .-div3


################################################################################
# routine: div5
#
# Signed fast division by 5 without using M extension.
# This routine provides a single, implementation for
# RV32I, RV32E, and RV64I.
#
# It uses a fast approximation, followed by a remainder calculation
# and a two-way branch-free correction to handle truncation toward zero.
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

.size div5, .-div5

################################################################################
# routine: div7
#
# Signed fast division by 7.
# Optimizations: Optimized register flow, Negative Remainder Trick.
#
# Input:  a0 = dividend (signed)
# Output: a0 = quotient (signed)
################################################################################
div7:
	# t0 = Sign Mask (-1 if neg, 0 if pos)
.if CPU_BITS == 64
	srai	t0, a0, 63
.else
	srai	t0, a0, 31
.endif
	
	# Compute abs(n) in place
	xor	a0, a0, t0
	sub	a0, a0, t0
	# Now a0 = abs(n)

	# Unsigned Division (q = abs(n) / 7)
	
	# Initial Estimate: q = n * 0.5625 (9/16)
	# n/2 + n/16
	srli	a1, a0, 1
	srli	a2, a0, 4
	add	a1, a1, a2	# a1 = n * 0.5625

	# Series Expansion: Converge 0.5625 -> 0.5714... (4/7)
	srli	a2, a1, 6
	add	a1, a1, a2	# q += q >> 6
	srli	a2, a1, 12
	add	a1, a1, a2	# q += q >> 12
	srli	a2, a1, 24
	add	a1, a1, a2	# q += q >> 24
.if CPU_BITS == 64
	srli	a2, a1, 48
	add	a1, a1, a2	# q += q >> 48
.endif

	# Final Shift: q_est = (n * 4/7) / 4 = n / 7
	srli	a1, a1, 2

	# Check & Correct (Negative Remainder)
	
	# Calculate 7 * q
	# 7x = 8x - x
	slli	a2, a1, 3	# a2 = 8q
	sub	a2, a2, a1	# a2 = 7q
	
	# Diff = 7q - abs(n)
	# If exact: Diff = -r (0..-6)
	# If under: Diff = -r - 7 (-7..-13)
	sub	a2, a2, a0

	# Threshold Check: Is Diff <= -7?
	# -7 < -6 -> 1 (Correction needed)
	slti	a3, a2, -6

	# Apply Correction
	add	a1, a1, a3	# a1 = q_abs

	# Restore Sign
	xor	a0, a1, t0
	sub	a0, a0, t0

	ret
	.size div7, .-div7

################################################################################
# routine: mod3
#
#
# Calculate a0 (signed) modulus 3
#
# RV32I, RV32E, and RV64I.
#
# # input registers:
#   a0 = number to check for divisibility by 3
#
# output registers:
#   a0 = signed remainder of a0/3
#
################################################################################

mod3:
	srai	t0, a0, CPU_BITS-1	# t0 = -1 if neg, 0 if pos
	xor	a0, a0, t0
	sub	a0, a0, t0
	j	mod3_body

################################################################################
# routine: mod3u
#
#
# Caclulcate the modulus of a0 (unsigned) by 3
#
# RV32I, RV32E, and RV64I.
#
# # input registers:
#   a0 = number to calculate modulus of 3
#
# output registers:
#   a0 = unsigned remainder of a0/3
#
################################################################################
mod3u:
	li	t0, 0		# positive sign

mod3_body:
.if CPU_BITS == 64	
	# fold 64->32
	srli	a1, a0, 32
.if HAS_ZBA
	zext.w	a0, a0
.else
	slli	a0, a0, 32
	srli	a0, a0, 32
.endif
	add	a0, a0, a1
.endif

	# Fold 32 -> 16
	# n = (n & 0xFFFF) + (n >> 16)
.if HAS_ZBA
	zext.h	a1, a0		# a1 = n & 0xFFFF
.else
	srli	a1, a0, 16
	slli	a0, a0, 16
.endif
	srli	a0, a0, 16
	add	a0, a0, a1


	# Fold 16 -> 8
	# n = (n & 0xFF) + (n >> 8)
	srli	a1, a0, 8
	andi	a0, a0, 0xFF
	add	a0, a0, a1

	# Fold 8 -> 4
	# n = (n & 0xF) + (n >> 4)
	srli	a1, a0, 4
	andi	a0, a0, 0xF
	add	a0, a0, a1

	# Standard Fold
	# Reduces max ~45 down to max 17.
	srli	a1, a0, 4
	andi	a0, a0, 0xF
	add	a0, a0, a1

	# Final Cleanup (Fold 4 -> 4)
	# Reduces 17 down to 2.
	srli	a1, a0, 4
	add	a0, a0, a1
	andi	a0, a0, 0xF

	# Remainder Lookup
	# Input a0 is 0..15. We need to map this to n % 3.
	# We use a 32-bit magic number as a lookup table.
	# Binary: ... 00 10 01 00 (repeating) -> 0, 1, 2, 0 ...
	li	a1, 0x24924924
	slli	a0, a0, 1	# Convert index to bit offset (x2)
	srl	a0, a1, a0	# Shift table down by offset
	andi	a0, a0, 3	# Mask the bottom 2 bits

	# apply sign mask
	xor	a0, a0, t0	# if t0 = 0, a0 unchanged
	sub	a0, a0, t0	# if t0 =-1, a0 becomes -a0

	ret

.size mod3u, .-mod3u
.size mod3, .-mod3

################################################################################
# routine: divtst5
#
#
# Check if a0 (signed) is divisible by 5
#
# RV32I, RV32E, and RV64I.
#
# # input registers:
#   a0 = number to check for divisibility by 5
#
# output registers:
#   a0 = 1 if divisible by 5, else 0
#
################################################################################

divtst5:
	abs	a0, a0, a1

	# FALLTHROUGH to divtst5u

################################################################################
# routine: divtst5u
#
#
# Check if a0 (unsigned) is divisible by 5 via parallel folding.
#
# RV32I, RV32E, and RV64I.
#
# # input registers:
#   a0 = number to check for divisibility by 5
#
# output registers:
#   a0 = 1 if divisible by 5, else 0
#
################################################################################
divtst5u:
.if CPU_BITS == 64	
	# fold 64->32
	srli	a1, a0, 32
.if HAS_ZBA
	zext.w	a0, a0
.else
	slli	a0, a0, 32
	srli	a0, a0, 32
.endif
	add	a0, a0, a1
.endif

	# Fold 32 -> 16
	# n = (n & 0xFFFF) + (n >> 16)
.if HAS_ZBA
	zext.h	a1, a0		# a1 = n & 0xFFFF
.else
	srli	a1, a0, 16
	slli	a0, a0, 16	# Clear top bits
.endif
	srli	a0, a0, 16
	add	a0, a0, a1


	# Fold 16 -> 8
	# n = (n & 0xFF) + (n >> 8)
	srli	a1, a0, 8
	andi	a0, a0, 0xFF
	add	a0, a0, a1

	# Fold 8 -> 4
	# n = (n & 0xF) + (n >> 4)
	srli	a1, a0, 4
	andi	a0, a0, 0xF
	add	a0, a0, a1

	# Final Cleanup (Fold 4 -> 4)
	# The sum from step 4 can be up to ~30 (0x1E).
	# We fold one last time to ensure n <= 15.
	srli	a1, a0, 4
	add	a0, a0, a1
	andi	a0, a0, 0xF

	# Lookup Table
	# Valid: 0, 5, 10, 15
	# Binary: 1000 0100 0010 0001 = 0x8421
	li	a1, 0x8421
.if HAS_ZBS
	bext	a0, a1, a0
.else
	srl	a0, a1, a0
	andi	a0, a0, 1
.endif
	ret

.size divtst5u, .-divtst5u
.size divtst5, .-divtst5

###############################################################################
# routine: divtst7
#
#
# Check if a0 (signed) is divisible by 7
#
# RV32I, RV32E, and RV64I.
#
# # input registers:
#   a0 = number to check for divisibility by 7
#
# output registers:
#   a0 = 1 if divisible by 5, else 0
#
################################################################################

################################################################################
# routine: divtst7
#
# Check if a0 (signed) is divisible by 7.
# Returns: a0 = 1 (true) or 0 (false).
# Constraints: Defines CPU_BITS (32 or 64).
################################################################################
divtst7:
	abs	a0, a0, a1

	# FALLTHROUGH to divtst7u

################################################################################
# routine: divtst7u
#
# Check if a0 (unsigned) is divisible by 7.
# Algorithm: Parallel Folding using Modulo Factors (4, 2, 4, 2).
# Complexity: O(1) - No loops.
################################################################################

divtst7u:
.if CPU_BITS == 64
	# Fold 64 -> 32 (Factor 4)
	# n = (n & Low) + 4*(n >> 32)
	srli	a1, a0, 32
.if HAS_ZBA
	zext.w	a0, a0
.else
	slli	a0, a0, 32
	srli	a0, a0, 32
.endif
	slli	a1, a1, 2	# * 4
	add	a0, a0, a1
.endif

	# Fold 32 -> 16 (Factor 2)
	# n = (n & 0xFFFF) + 2*(n >> 16)
.if HAS_ZBA
	zext.h	a1, a0
	srli	a0, a0, 16
	slli	a0, a0, 1	# * 2
.else
	srli	a1, a0, 16	# Upper
	slli	a0, a0, 16	# Clear Upper
	srli	a0, a0, 16	# Lower
	slli	a1, a1, 1	# Upper * 2
.endif
	add	a0, a0, a1

	# Fold 16 -> 8 (Factor 4)
	# n = (n & 0xFF) + 4*(n >> 8)
	srli	a1, a0, 8
.if HAS_ZBB
	zext.b	a0, a0
.else
	andi	a0, a0, 0xFF
.endif
	slli	a1, a1, 2	# * 4
	add	a0, a0, a1

	# Fold 8 -> 4 (Factor 2)
	# n = (n & 0xF) + 2*(n >> 4)
	srli	a1, a0, 4
	andi	a0, a0, 0xF
	slli	a1, a1, 1	# * 2
	add	a0, a0, a1

	# Final Cleanup (Input max ~45)
	# Switch to Octal Fold (Sum of 3-bit digits) for final reduction.
	# n = (n & 7) + (n >> 3)
	
	# Pass 1: Max 45 -> 10
	srli	a1, a0, 3
	andi	a0, a0, 7
	add	a0, a0, a1
	
	# Pass 2: Max 10 -> 3 (or 7->7, 14->7)
	# Guarantees result is 0..7
	srli	a1, a0, 3
	andi	a0, a0, 7
	add	a0, a0, a1

	# Lookup Result
	# Divisible by 7 in 0..7 is {0, 7}.
	# Mask 0x81 (1000 0001)
	li	a1, 0x81
.if HAS_ZBS
	bext	a0, a1, a0
.else
	srl	a0, a1, a0
	andi	a0, a0, 1
.endif
	ret

.size divtst7u, .-divtst7u
.size divtst7, .-divtst7

# -----------------------------------------------------------------------
# divtst9: Check if a0 is divisible by 9
# Target: RV32I, RV32E, RV64I
# -----------------------------------------------------------------------
divtst9:
.if CPU_BITS == 64
    # ---------------------------------------------------------
    # RV64 Pre-Fold Optimization
    # Reduces 64-bit input to ~35 bits instantly.
    # Logic: 2^32 = 4 (mod 9). 
    #	     n = Lower32 + (Upper32 * 4)
    # ---------------------------------------------------------
    srli    a1, a0, 32	    # a1 = Upper 32 bits
    slli    a2, a1, 2	    # a2 = Upper * 4
    
    slli    a0, a0, 32	    # \ 
    srli    a0, a0, 32	    # / Zero-extend Lower 32 bits
    
    add	    a0, a0, a2	    # n = Lower + (Upper * 4)
.endif

    # ---------------------------------------------------------
    # Main Folding Loop
    # Stride: 6 bits. (2^6 = 64 == 1 mod 9)
    # ---------------------------------------------------------
    li	    a1, 63	    # Mask 0x3F (6 bits)

loop9:
    and	    a2, a0, a1	    # digit = n & 63
    srli    a0, a0, 6	    # n = n >> 6
    add	    a0, a0, a2	    # n = remaining + digit
    bltu    a1, a0, loop9   # Keep folding if n > 63

    # ---------------------------------------------------------
    # Final Cleanup: Octal Palindrome Check
    # At this point, n is in [0, 63].
    # n is divisible by 9 iff (n & 7) == (n >> 3).
    # ---------------------------------------------------------
    srli    a1, a0, 3	    # a1 = Upper 3 bits (n >> 3)
    andi    a0, a0, 7	    # a0 = Lower 3 bits (n & 7)
    
    xor	    a0, a0, a1	    # XOR is 0 if halves are equal
    sltiu   a0, a0, 1	    # Return 1 if result is 0, else 0
    ret

.size divtst9, .-divtst9

# -----------------------------------------------------------------------
# divtst11: Check if a0 is divisible by 11
# Strategy:
#   1. Pre-fold 32-bit chunks (RV64 only).
#   2. Fold 10-bit chunks (Addition).
#   3. Fold 5-bit chunks (Subtraction/Alternating Sum).
#   4. Tiny cleanup loop.
# -----------------------------------------------------------------------
divtst11:
.if CPU_BITS == 64
    # ---------------------------------------------------------
    # RV64 Pre-Fold
    # Property: 2^32 = 4 (mod 11).
    # n = Lower32 + (Upper32 * 4)
    # ---------------------------------------------------------
    srli    a1, a0, 32	    # a1 = Upper
    slli    a2, a1, 2	    # a2 = Upper * 4
    
    slli    a0, a0, 32	    # \ 
    srli    a0, a0, 32	    # / Zero-extend Lower
    
    add	    a0, a0, a2	    # n = Lower + (Upper * 4)
.endif

    # ---------------------------------------------------------
    # Stage 1: 10-bit Folding
    # Property: 2^10 = 1024 = 1 (mod 11).
    # We sum 10-bit chunks until n <= 1023.
    # ---------------------------------------------------------
    li	    a1, 1023	    # Mask 0x3FF

loop11_stage1:
    and	    a2, a0, a1	    # digit = n & 1023
    srli    a0, a0, 10	    # n = n >> 10
    add	    a0, a0, a2	    # n += digit
    bltu    a1, a0, loop11_stage1

    # ---------------------------------------------------------
    # Stage 2: 5-bit Alternating Fold
    # At this point, n is 0..1023.
    # Property: 2^5 = 32 = -1 (mod 11).
    # n = 32*High + Low	 =>  n (mod 11) = Low - High
    # ---------------------------------------------------------
    srli    a1, a0, 5	    # a1 = High (n >> 5)
    andi    a0, a0, 31	    # a0 = Low	(n & 31)

    # We calculate (Low - High).
    # Range of Low: 0..31, Range of High: 0..31.
    # Range of (Low - High): -31 to +31.
    # We add a bias of 33 (3 * 11) to keep the result positive.
    # n_new = Low - High + 33. Range: [2, 64].
    
    sub	    a0, a0, a1
    addi    a0, a0, 33

    # ---------------------------------------------------------
    # Final Check
    # n is now in [2, 64]. We check if it is a multiple of 11.
    # We can use a tiny subtraction loop (max 5 iterations).
    # ---------------------------------------------------------
    li	    a1, 11
sub11:
    bltu    a0, a1, check11
    sub	    a0, a0, a1
    j	    sub11

check11:
    # If remainder is 0, original n was divisible by 11.
    sltiu   a0, a0, 1
    ret

.size divtst11, .-divtst11

.text
    .globl divtst13

# -----------------------------------------------------------------------
# divtst13: Check if a0 is divisible by 13
# Target: RV32I, RV32E, RV64I
# -----------------------------------------------------------------------
divtst13:
.if CPU_BITS == 64
    # ---------------------------------------------------------
    # RV64 Pre-Fold Optimization
    # Logic: 2^32 mod 13 calculation:
    #	     2^12 = 1 (mod 13)
    #	     2^24 = 1 (mod 13)
    #	     2^32 = 2^24 * 2^8 = 1 * 256 = 256.
    #	     256 = 19 * 13 + 9.
    #	     So, 2^32 = 9 (mod 13).
    # Formula: n = Lower32 + (Upper32 * 9)
    # ---------------------------------------------------------
    srli    a1, a0, 32	    # a1 = Upper
    
    # Calculate a1 * 9 using shifts (a1*8 + a1)
    slli    a2, a1, 3	    # a2 = Upper * 8
    add	    a2, a2, a1	    # a2 = Upper * 9
    
    slli    a0, a0, 32	    # \
    srli    a0, a0, 32	    # / Zero-extend Lower
    
    add	    a0, a0, a2	    # n = Lower + (Upper * 9)
.endif

    # ---------------------------------------------------------
    # Stage 1: 12-bit Folding (Addition)
    # Property: 2^12 = 4096 = 1 (mod 13).
    # We sum 12-bit chunks until n <= 4095.
    # ---------------------------------------------------------
    li	    a1, 4095	    # Mask 0xFFF

loop13_stage1:
    and	    a2, a0, a1	    # digit = n & 0xFFF
    srli    a0, a0, 12	    # n = n >> 12
    add	    a0, a0, a2	    # n += digit
    bltu    a1, a0, loop13_stage1

    # ---------------------------------------------------------
    # Stage 2: 6-bit Alternating Fold (Subtraction)
    # At this point, n is 0..4095 (12 bits).
    # Property: 2^6 = 64 = -1 (mod 13).
    # n = 64*High + Low	 =>  n (mod 13) = Low - High
    # ---------------------------------------------------------
    srli    a1, a0, 6	    # a1 = High (n >> 6)
    andi    a0, a0, 63	    # a0 = Low	(n & 63)

    # We calculate (Low - High).
    # Range of Low: 0..63, Range of High: 0..63.
    # Range of (Low - High): -63 to +63.
    # Bias: 65 (5 * 13) to ensure result is positive [2, 128].
    
    sub	    a0, a0, a1
    addi    a0, a0, 65

    # ---------------------------------------------------------
    # Final Check
    # n is now in [2, 128].
    # Use a tiny subtract loop (max ~9 iterations).
    # ---------------------------------------------------------
    li	    a1, 13
sub13:
    bltu    a0, a1, check13
    sub	    a0, a0, a1
    j	    sub13

check13:
    # If remainder is 0, original n was divisible by 13.
    sltiu   a0, a0, 1
    ret

.size divtst13, .-divtst13

# -----------------------------------------------------------------------
# divtst100: Check if unsigned a0 is divisible by 100
# Logic: Return (a0 % 4 == 0) AND (a0 % 25 == 0)
# -----------------------------------------------------------------------
divtst100:
    # ---------------------------------------------------------
    # 1. Fast Modulo 4 Check
    # If the last 2 bits are not 0, it's not divisible by 4 (or 100).
    # ---------------------------------------------------------
    andi    t0, a0, 3	    # Extract last 2 bits
    bnez    t0, fail_div100 # If not 00, return 0

    # ---------------------------------------------------------
    # 2. Modulo 25 Check
    # We proceed to check if a0 is divisible by 25.
    # ---------------------------------------------------------

.if CPU_BITS == 64
    # Optional RV64 Optimization:
    # Since we are about to loop 20-bit chunks, a 64-bit input
    # requires 4 chunks. We can pre-fold slightly to speed it up.
    # However, the 20-bit loop below converges fast enough (2-3 iters)
    # that explicit pre-folding code saves minimal cycles here.
.endif

    # --- Stage 1: 20-bit Fold (Addition) ---
    # Property: 2^20 = 1 (mod 25).
    # We sum 20-bit chunks.
    li	    a1, 0xFFFFF	    # Mask 20 bits

loop100_stage1:
    and	    a2, a0, a1	    # digit = n & 0xFFFFF
    srli    a0, a0, 20	    # n = n >> 20
    add	    a0, a0, a2	    # n += digit
    bltu    a1, a0, loop100_stage1
    # Result is now <= ~21 bits (approx 2 million)

    # --- Stage 2: 10-bit Alternating Fold (Subtraction) ---
    # Property: 2^10 = 1024 = -1 (mod 25).
    # n = High*1024 + Low  =>  n (mod 25) = Low - High
    srli    a1, a0, 10	    # a1 = High (n >> 10)
    andi    a0, a0, 1023    # a0 = Low	(n & 1023)

	# Calculate Low - High.
	# High can be up to ~1024 (from stage 1 result).
	# Low is < 1024.
	# Result can be negative. We add a Bias. Must be multiple of 24
	# 1250 (50 * 25) is sufficient and fits in 12-bit immediate
	sub	a0, a0, a1
	addi	a0, a0, 1250

    # --- Stage 3: Tiny Cleanup Loop ---
    # n is now in range [0, ~3500].
    # We subtract 25 until n < 25.
    li	    a1, 25
sub25:
    bltu    a0, a1, check25
    sub	    a0, a0, a1
    j	    sub25

check25:
    # If n == 0, it is divisible by 25.
    # Since we already passed Mod 4, it is divisible by 100.
    sltiu   a0, a0, 1
    ret

fail_div100:
    li	    a0, 0
    ret

.size divtst100, .-divtst100

# -----------------------------------------------------------------------
# divtst1000: Check if unsigned a0 is divisible by 1000
# Logic: Return (a0 % 8 == 0) AND ((a0 / 8) % 125 == 0)
# -----------------------------------------------------------------------
divtst1000:
    # ---------------------------------------------------------
    # 1. Fast Modulo 8 Check
    # If the last 3 bits are not 0, it fails immediately.
    # ---------------------------------------------------------
    andi    t0, a0, 7	    # Extract last 3 bits
    bnez    t0, fail_div1000

    # ---------------------------------------------------------
    # 2. Divide by 8
    # We strip the last 3 zero bits. 
    # The problem reduces to checking if the remaining bits are divisible by 125.
    # ---------------------------------------------------------
    srli    a0, a0, 3

    # ---------------------------------------------------------
    # 3. Modulo 125 Check (10-bit Folding)
    # Property: 2^10 = 1024 = 24 (mod 125).
    # Rule: Next_N = (High * 24) + Low
    # ---------------------------------------------------------
    li	    a1, 1023	    # Mask 0x3FF (10 bits)

loop1000:
    # Split N into High (remaining) and Low (digit)
    and	    a2, a0, a1	    # a2 = Low (digit)
    srli    a0, a0, 10	    # a0 = High
    
    # Calculate High * 24
    # 24 = 16 + 8, so High*24 = (High << 4) + (High << 3)
    slli    t0, a0, 4	    # t0 = High * 16
    slli    t1, a0, 3	    # t1 = High * 8
    add	    a0, t0, t1	    # a0 = High * 24
    
    # Add Low
    add	    a0, a0, a2	    # n = (High * 24) + Low
    
    # Continue if n > 1023 (Safe threshold where fold shrinks n)
    bltu    a1, a0, loop1000

    # ---------------------------------------------------------
    # 4. Final Cleanup
    # n is now in range [0, ~1600].
    # (Worst case fold: 1023*24 + 1023 approx 25k, shrinks fast in next iter)
    # We subtract 125 until n < 125.
    # ---------------------------------------------------------
    li	    a1, 125
sub125:
    bltu    a0, a1, check125
    sub	    a0, a0, a1
    j	    sub125

check125:
    # If n == 0, it is divisible by 125 (and thus original was by 1000).
    sltiu   a0, a0, 1
    ret

fail_div1000:
    li	    a0, 0
    ret

.size divtst1000, .-divtst1000

