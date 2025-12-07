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
.globl divtst3
.globl divtst3u

.text

################################################################################
# routine: divremu
#
# Unsigned integer division using a restoring algorithm.
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
	# Step 1: Extract MSB
	srli	t0, a2, MSB_SHIFT

	# Step 2: Shift Remainder and Merge new bit
.if HAS_ZBA
	# sh1add rd, rs1, rs2  ->  rd = rs2 + (rs1 << 1)
	sh1add	a0, a0, t0
.else
	slli	a0, a0, 1
	or	a0, a0, t0
.endif

	# Step 3: Shift Dividend left
	slli	a2, a2, 1

	# Step 4: Compare Remainder vs Divisor
	sltu	t1, a0, a1		# t1 = 1 if Rem < Div (Fail)

	# Step 5: Branchless Subtract
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
	# --- 1. Shift Remainder & Merge MSB ---
	srli	t0, a2, MSB_SHIFT

.if HAS_ZBA == 1
	sh1add	a0, a0, t0
.else
	slli	a0, a0, 1
	or	a0, a0, t0
.endif

	# --- 2. Prepare Dividend/Quotient ---
	slli	a2, a2, 1

	# --- 3. Compare ---
	sltu	t0, a0, a1		# t0 = 1 if Rem < Div (Fail)

	# --- 4. Branchless Subtraction Logic ---
.if HAS_ZICOND == 1
	czero.nez t2, a1, t0
.else
	addi	t1, t0, -1		# Mask
	and	t2, a1, t1		# Filter
.endif
	sub	a0, a0, t2

	# --- 5. Update Quotient Bit ---
	xori	t0, t0, 1
	or	a2, a2, t0
.endm

divremu:
	beqz	a1, divremu_zero

	mv	a2, a0			# a2 = Dividend
	mv	a0, zero		# a0 = Remainder
	li	a3, (CPU_BITS / 4)	# Loop counter (8 or 16)

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
# - Relies on divremu NOT clobbering t4 or t5 (ABI deviation for speed).
#
# input:  a0 = dividend (N), a1 = divisor (D)
# output: a0 = quotient (Q), a1 = remainder (R)
################################################################################

.equ	SIGN_BIT_SHIFT, (CPU_BITS - 1)

divrem:
	# 1. Setup Stack and Save Inputs
	FRAME	1
	PUSH	ra, 0

	mv	t0, a0		# t0 = Original N
	mv	t1, a1		# t1 = Original D

	# 2. Handle Zero Divisor
	beq	t1, zero, divrem_by_zero

	# 3. Handle Overflow (INT_MIN / -1)
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
	# 4. Compute Absolute Values (Branchless)
	# Generate Sign Masks (0 = Pos, -1 = Neg)
	srai	t4, t0, SIGN_BIT_SHIFT	# t4 = Sign Mask N (Kept for later)
	srai	t5, t1, SIGN_BIT_SHIFT	# t5 = Sign Mask D (Kept for later)

	# Apply Abs(N)
	xor	a0, t0, t4
	sub	a0, a0, t4		# a0 = abs(N)

	# Apply Abs(D)
	xor	a1, t1, t5
	sub	a1, a1, t5		# a1 = abs(D)

	# 5. Perform Unsigned Division
	# WARNING: We assume divremu does NOT clobber t4 or t5.
	call	divremu
	# Returns: a0 = abs(Q), a1 = abs(R)

	# 6. Apply Signs (Branchless)

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
	srli	a0, a0, 5	# a0 = 11r/32: correction amoutn
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
	sub	a2, a0, a2	# a2 = r = n - q*5

	# Add correction q + (7*r >> 5)
	slli	a3, a2, 3	# a3 = r*8
	sub	a3, a3, a2	# a3 = (r*8) - r = r*7
	srli	a3, a3, 5	# a3 = 7*r >> 5
	add	a0, a1, a3	# a0 = q + (7*r >> 5)
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
	# Phase 1: Calculate approximate quotient q.
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

	# Phase 2: Calculate remainder r = n - 6*q
	mul6	a2, a1, a3	# a2 = q * 6
	sub	a2, a0, a2	# a2 = r = n - q * 6

	# Phase 3: Correction
.if CPU_BITS == 32
	# For 32-bit, the error is at most 1, so a simple check is sufficient.
	sltiu	a3, a2, 6	# a3 = 1 if r < 6 
	xori	a3, a3, 1	# a3 = 1 if r >= 6 (r > 5)
.endif
.if CPU_BITS == 64
	# For 64-bit, we use a fast magic number multiplication to find
	# the correction amount, which is floor(r * 11 / 64).
	# This single step is sufficient to produce the correct result.
	mul11	a3, a2, a3
	srli	a3, a3, 6	# a3 = floor((r * 11) / 64) -> correction amount
.endif
	add	a0, a1, a3	# a0 = q_approx + correction
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
	sub	a3, a2, a1	# a3 = (q * 7) = (q * 8) - q
	sub	a2, a0, a3	# a2 = r = n - (q * 7)

	sltiu	a3, a2, 7	# a3 = 1 if r < 7
	xori	a3, a3, 1	# a3 = 1 if r >= 7 (r > 6)
	add	a0, a1, a3	# q = q + (r > 6)
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
	# Phase 1: Approximate Quotient
	# Target: q_accum = n * (8/9)
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

	# Phase 2: Remainder (r = n - 9q)
	mul9	a3, a1, a2
	sub	a2, a0, a3	# a2 = r = n - 9*q

	# Phase 3: Correction
	# If r >= 9, we under-estimated q by 1.
	sltiu	a3, a2, 9	# a3 = 1 if r < 9
	xori	a3, a3, 1	# a3 = 1 if r >= 9
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

	# Continue series expansion...
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
	sub	a3, a0, a2	# a3 = r

	# Phase 3: Correction
	sltiu	a3, a3, 10
	xori	a3, a3, 1
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
	mul11	a1, a2, a3	# a1 = q * 11
	sub	a1, a0, a1	# a1 = r = n - q * 11

	sltiu	a3, a1, 11	# a3 = 1 if r < 11, else 0
	xori	a3, a3, 1	# a3 = 1 if r >= 11, else 0
	add	a0, a2, a3	# a0 = q = q + correction
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
	sub	a2, a0, a2	# a1 = r = n - q*12

	# correct approximate quotient
	sltiu	a3, a2, 12	# a3 = 1 if r < 12, else 0
	xori	a3, a3, 1	# a3 = 1 if r >= 12, else 0
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
	sub	a2, a0, a2	# a2 = r = n - q_est * 100

	# compute correction to estimated quotient
	sltiu	a3, a2, 100	# a3 = 1 if r < 100, else 0
	xori	a3, a3, 1	# a3 = 1 if r >= 100, else 0
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
# input registers:
# a0 = unsigned dividend (32 or 64 bits)
#
# output registers:
# a0 = quotient (unsigned)
################################################################################	
div1000u:
	# This routine calculates q = (n * (2^9 / 1000)) >> 9
	# The approximation is q_est = (n * 0.512)
	# The 32-bit sequence is
	# q = [ (n>>1) + t + (n>>15) + (t>>11) + (t>>14) ] >> 9
	# where t = (n>>7) + (n>>8) + (n>>12)

	# Compute t = (n>>7) + (n>>8) + (n>>12)
	srli	a2, a0, 7
	srli	a3, a0, 8
	add	a2, a2, a3
	srli	a3, a0, 12
	add	a2, a2, a3	# a2 = t

	# Compute q = (n>>1) + (n>>15)
	srli	a1, a0, 1
	srli	a3, a0, 15
	add	a1, a1, a3

	# Add t and its shifted terms to q
	add	a1, a1, a2	# q = q + t
	srli	a3, a2, 11
	add	a1, a1, a3	# q = q + (t>>11)
	srli	a3, a2, 14
	add	a1, a1, a3	# q = q + (t>>14)

.if CPU_BITS == 64
	# 64-bit specific approximation steps (extend the series)
	srli	a3, a2, 22
	add	a1, a1, a3	# q = q + (t>>22)
	srli	a3, a2, 28
	add	a1, a1, a3	# q = q + (t>>28)
	srli	a3, a2, 44
	add	a1, a1, a3	# q = q + (t>>44)
	srli	a3, a2, 56
	add	a1, a1, a3	# q = q + (t>>56)
.endif

	# Common final shift for the quotient
	srli	a1, a1, 9	# a1 = q_est = (approximation >> 9)

	# Compute remainder from estimated quotient (XLEN-agnostic)
	# n*1000 = (n << 10) - (n << 4) - (n << 3)
	#	 = 1024*n - 16*n - 8*n = 1000*n
	slli	a2, a1, 10	# a2 = q_est * 1024
	slli	a3, a1, 4	# a3 = q_est * 16
	sub	a2, a2, a3	# a2 = q_est * 1008
	slli	a3, a1, 3	# a3 = q_est * 8
	sub	a2, a2, a3	# a2 = q_est * 1000
	sub	a2, a0, a2	# a2 = r = n - q_est * 1000

	# Compute correction to estimated quotient (XLEN-agnostic)
	# The approximation is designed to be floor(n/1000), so the
	# remainder 'r' can be in the range [0, 1999].
	# If r >= 1000, we must add 1 to the quotient.

	# Compare remainder 'a2'
	sltiu	a3, a2, 1000	# a3 = 1 if r < 1000, else 0

	# Invert logic: a3 = 1 if r >= 1000, else 0
	xori	a3, a3, 1	# a3 = correction factor (0 or 1)

	# Add correction 'a3' to quotient 'a1'
	add	a0, a1, a3	# a0 = q_final = q_est + correction
	ret

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
.if CPU_BITS == 32
	srai	t0, a0, 31		# t0 = (n < 0) ? -1 : 0
.else
	srai	t0, a0, 63		# t0 = (n < 0) ? -1 : 0
.endif
	xor	a1, a0, t0		# a1 = n ^ sign
	sub	a1, a1, t0		# a1 = (n ^ sign) - sign = abs(n)

	# Core: Unsigned divide by 3 (div3u) operating on a1 (abs(n))
	# We use a0 as a temporary copy of abs(n) for the remainder calc.
	mv	a0, a1			# a0 = abs(n)
	srli	a1, a1, 2		# a1: q = abs(n) >> 2
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
	slli	a2, a1, 1		# a2: q_est * 2
	add	a2, a2, a1		# a2: q_est * 3
	sub	a2, a0, a2		# a2: r = abs(n) - q_est * 3

	# Correction step (calculates correction in a0)
.if CPU_BITS == 64
	# Correction step for 64-bit (5 instructions)
	slli	a0, a2, 3		# a0: r * 8
	add	a0, a0, a2		# a0: r * 9
	slli	a2, a2, 1		# a2: r * 2
	add	a0, a0, a2		# a0: r * 11
	srli	a0, a0, 5		# a0: correction amount
.else
	# Correction step for 32-bit (4 instructions)
	addi	a0, a2, 5		# a0: r + 5
	slli	a2, a2, 2		# a2: r << 2
	add	a0, a0, a2		# a0: (r + 5) + (r << 2)
	srli	a0, a0, 4		# a0: correction amount
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
# This routine provides a single, XLEN-agnostic implementation for
# RV32I, RV32E, and RV64I.
#
# It uses a fast approximation, followed by a remainder calculation
# and a two-way branch-free correction to handle truncation toward zero.
#
# input registers:
#   a0 = signed dividend (32 or 64 bits, matching XLEN)
#
# output registers:
#   a0 = quotient (signed, a0 / 5)
#
################################################################################

div5:
	# Estimate quotient. This is a stable, XLEN-agnostic approximation
	# of n * 0.2. q_est = (n>>2) - (n>>4) + (n>>6)
	srai	a1, a0, 2
	srai	a2, a0, 4
	sub	a1, a1, a2	# a1 = (n>>2) - (n>>4)
	srai	a2, a0, 6
	add	a1, a1, a2	# a1 = q_est

	# Compute remainder r = n - (q_est * 5)
	# We can use (q_est * 4) + q_est
	slli	a2, a1, 2	# a2 = q_est * 4
	add	a2, a2, a1	# a2 = q_est * 5
	sub	a2, a0, a2	# a2 = r = n - (q_est * 5)

	# Branch-free correction.
	# Division truncates toward zero, so q must be:
	#   q_est + 1, if r > 4
	#   q_est - 1, if r < -4
	#   q_est,     otherwise

	# t0 = correction for case 1: (n >= 0 && r < 0) ? 1 : 0
	slti	t0, a0, 0	# t0 = (n < 0) ? 1 : 0
	xori	t0, t0, 1	# t0 = (n >= 0) ? 1 : 0
	slti	t1, a2, 0	# t1 = (r < 0) ? 1 : 0
	and	t0, t0, t1	# t0 = 1 if (n >= 0) AND (r < 0)

	# t1 = correction for case 2: (n < 0 && r > 0) ? 1 : 0
	slti	t1, a0, 0	# t1 = (n < 0) ? 1 : 0
	slt    a0, x0, a2		# a0 = (r > 0) ? 1 : 0
	and	t1, t1, a0	# t1 = 1 if (n < 0) AND (r > 0)

	# Apply corrections
	add	a1, a1, t1	# a1 = q_est + (correction 2)
	sub	a0, a1, t0	# a0 = q_final = a1 - (correction 1)

	ret

.size div5, .-div5

################################################################################
# routine: divtst3
#
#
# Check if a0 (signed) is divisible by 3
#
# RV32I, RV32E, and RV64I.
#
# # input registers:
#   a0 = number to check for divisibility by 3
#
# output registers:
#   a0 = 1 if divisible by 3, else 0
#
################################################################################

divtst3:
	# --- Absolute Value (Signed -> Unsigned) ---
.if CPU_BITS == 64
	srai	t0, a0, 63	# t0 = -1 if neg, 0 if pos
.else
	srai	t0, a0, 31
.endif
	xor	a0, a0, t0	# Flip bits
	sub	a0, a0, t0	# Add 1 (Complete Abs Val)

	# FALLTHROUGH to divtst3u

################################################################################
# routine: divtst3u
#
#
# Check if a0 (unsigned) is divisible by 3
#
# RV32I, RV32E, and RV64I.
#
# # input registers:
#   a0 = number to check for divisibility by 3
#
# output registers:
#   a0 = 1 if divisible by 3, else 0
#
################################################################################
divtst3u:
.if CPU_BITS == 64
	# RV64 Optimization: Fold top 32 bits into bottom.
	# 2^32 = 1 (mod 3). We want (Upper + Lower).
	srli	a2, a0, 32	# a2 = Upper
.if HAS_ZBA == 1
	zext.w	a0, a0
.else
	slli	a0, a0, 32	# \ Clear Upper bits from a0
	srli	a0, a0, 32	# / (Zero Extend)
.endif
	add	a0, a0, a2	# a0 = Lower + Upper
.endif

	li	a1, 15		# Invariant: Mask 0xF and Loop Limit

loop3:
	and	a2, a0, a1	# digit = n & 15
	srli	a0, a0, 4	# n = n >> 4
	add	a0, a0, a2	# n = n + digit
	bltu	a1, a0, loop3	# Continue while n > 15

	# Final Check: n is 0..15. Valid: 0, 3, 6, 9, 12, 15
	# Bitmask: 1001 0010 0100 1001 = 0x9249
	li	a1, 0x9249
.if HAS_ZBS == 1
	bext	a0, a1, a0	# a0 = (a1 >> a0) & 1
.else
	srl	a0, a1, a0	# Shift mask by remaining n
	andi	a0, a0, 1	# Isolate bit 0
.endif
	ret

.size divtst3u, .-divtst3u
.size divtst3, .-divtst3

# -----------------------------------------------------------------------
# divtst5: Check if a0 is divisible by 5
# -----------------------------------------------------------------------
divtst5:
.if CPU_BITS == 64
    # RV64 Optimization: Bulk fold the top 32 bits.
    # Since 2^32 = (2^4)^8 = 16^8 = 1^8 = 1 (mod 5).
    srli    a2, a0, 32
    add	    a0, a0, a2	    # n = n_low + n_high
.endif

    li	    a1, 15	    # Invariant: Mask 0xF and Loop Limit
			    # We fold 4 bits at a time (16 = 1 mod 5)

# loops ~8 times on 32 bit, ~9 times on 64 bit machines.
loop5:
    and	    a2, a0, a1	    # digit = n & 15
    srli    a0, a0, 4	    # n = n >> 4
    add	    a0, a0, a2	    # n = n + digit
    bltu    a1, a0, loop5   # Continue while n > 15

    # Final Check: n is 0..15. Valid: 0, 5, 10, 15
    # Bitmask: 1000 0100 0010 0001 = 0x8421
    li	    a1, 0x8421
    srl	    a0, a1, a0	    # Shift mask by remaining n
    andi    a0, a0, 1	    # Isolate bit 0
    ret

.size divtst5, .-divtst5

# -----------------------------------------------------------------------
# divtst7: Check if a0 is divisible by 7
# Logic:
#   2^3 = 8 == 1 (mod 7).
#   We fold groups of 3 bits (Octal digits).
#   n = (n & 7) + (n >> 3) preserves n % 7.
# -----------------------------------------------------------------------
divtst7:
    li	    a1, 7	    # Invariant: Mask 0x7 and Limit
			    # We fold 3 bits at a time.
# 11 iterations max on 32-bit, 22 on 64-bit
loop7:
    and	    a2, a0, a1	    # digit = n & 7
    srli    a0, a0, 3	    # n = n >> 3
    add	    a0, a0, a2	    # n = n + digit
    bltu    a1, a0, loop7   # Continue while n > 7
    
    # Final Check: n is 0..7
    # Divisible by 7 in this range: 0, 7.
    # We need a bitmask with bits 0 and 7 set.
    # Binary: 1000 0001
    # Hex:    0x81
    li	    a1, 0x81	    # Load Look-up Table
    srl	    a0, a1, a0	    # Shift bit to position 0
    andi    a0, a0, 1	    # Isolate result
    ret

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
    # High can be up to ~2048 (from stage 1 result).
    # Low is < 1024.
    # Result can be negative. We add a Bias.
    # Bias = 2500 (100 * 25). Keeps result positive.
    
    sub	    a0, a0, a1
# XXXXX	   addi	   a0, a0, 2500

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

