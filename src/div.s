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
.globl div6
.globl div7
.globl div9
.globl div10
.globl div11	
.globl div12
.globl div13
.globl div100
.globl div1000
.globl mod3u
.globl mod3

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
	li	a0, 1
	slli	a0, a0, SIGN_BIT_SHIFT	# Q = INT_MIN
	li	a1, 0			# R = 0
	j	divrem_cleanup_stack

.size divrem, .-divrem
	
# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div3u
#
# Unsigned fast division by 3 without using M extension.
# This routine is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses a series approximation to implement division.
# Suitable for use on RV32E architectures.
#
# input registers:
# a0 = unsigned dividend (32 or 64 bits)
#
# output registers:
# a0 = quotient (unsigned)
################################################################################
div3u:
	# 1. Series Expansion (Computes Q_est)
	#    Generates an under-estimate of N/3
	srli	a1, a0, 2		# a1 = n >> 2
	srli	a2, a0, 4		# a2 = n >> 4
	add	a1, a2, a1		# a1 = (n>>2) + (n>>4)
	srli	a2, a1, 4		
	add	a1, a2, a1		# a1 += a1 >> 4
	srli	a2, a1, 8		
	add	a1, a2, a1		# a1 += a1 >> 8
	srli	a2, a1, 16		
	add	a1, a2, a1		# a1 += a1 >> 16
.if CPU_BITS == 64
	srli	a2, a1, 32		
	add	a1, a2, a1		# a1 += a1 >> 32
.endif

	# 2. Calculate Remainder / Error Term
	#    R = N - 3*Q_est
	mul3	a2, a1, a2		# a2 = 3 * Q_est
	sub	a2, a0, a2		# a2 = N - 3*Q_est (Remainder/Error)

	# 3. Linear Correction (Branchless)
	#    Correction = floor(R / 3) approx floor((R * 11) / 32)
	mul11	a3, a2, a0		# a3 = R * 11

	#    Correction = (R * 11) >> 5
	srli	a3, a3, 5
	
	# 4. Final Addition
	add	a0, a1, a3		# Q_final = Q_est + Correction
	ret

.size div3u, .-div3u
	
################################################################################
# routine: div5u
#
# Unsigned fast division by 5 without using M extension.
# This routine is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses a series expansion algorithm to implement division.
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
# Unsigned fast division by 6.
# Algorithm: Series expansion + Dual Threshold Correction.
#
# input:  a0 = unsigned dividend
# output: a0 = unsigned quotient
################################################################################
div6u:
	# estimate quotient: q = n / 6
	# base: n * (1/2 + 1/8) = n * 0.625
	srli	a1, a0, 1
	srli	a2, a0, 3
	add	a1, a1, a2

	# series expansion (converges to 0.666...)
	srli	a2, a1, 4
	add	a1, a1, a2
	srli	a2, a1, 8
	add	a1, a1, a2
	srli	a2, a1, 16
	add	a1, a1, a2
.if CPU_BITS == 64
	srli	a2, a1, 32
	add	a1, a1, a2
.endif

	# final shift: q_est = q_accum / 4
	srli	a1, a1, 2

	# negative remainder calculation
	# diff = 6q - n
	mul6	a2, a1, a2	# a2 = 6 * q
	sub	a2, a2, a0	# a2 = 6q - n

	# threshold 1: diff <= -6 (i.e. < -5)
	# handles estimation error of 1
	slti	a3, a2, -5
	add	a1, a1, a3	# q += 1

.if CPU_BITS == 64
	# threshold 2: diff <= -12 (i.e. < -11)
	# handles estimation error of 2 (possible for >60-bit inputs)
	slti	a3, a2, -11
	add	a1, a1, a3	# q += 1
.endif

	mv	a0, a1
	ret
.size div6u, .-div6u

################################################################################
# routine: div7u
#
# Unsigned fast division by 7 without using M extension.
# This routine is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses a series expansion algorithm to implement division.
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
.if CPU_BITS == 64
	# Correction Step 2 (64-bit only): Add another 1 if diff <= -14
	# We reuse the original diff in a2
	slti	a3, a2, -13
	add	a0, a0, a3
.endif
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
	# approximate quotient: q_accum = n * (8/9)
	# start with n * (7/8)
	srli	a2, a0, 3	# a2 = n >> 3
	sub	a1, a0, a2	# a1 = n - (n >> 3) = n * 0.875
	# series expansion: multiply by (1 + 1/64 + 1/4096...)
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

	# final adjustment: q = (n * 8/9) / 8 = n / 9
	srli	a1, a1, 3	# a1 = q_approx

	# negative remainder -9 < -8 -> 1 (correction), -8 < -8 -> 0 (no corr)
	mul9	a3, a1, a2
	sub	a2, a3, a0
	slti	a3, a2, -8
	add	a0, a1, a3	# q = q + correction

	ret
.size div9u, .-div9u

################################################################################
# routine: div10u
#
# Unsigned fast division by 10 without using M extension.
# This routine is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses a series expansion to implement division.
# Suitable for use on RV32E architectures.
#
# input registers:
# a0 = unsigned dividend (32 or 64 bits)
#
# output registers:
# a0 = quotient (unsigned)
################################################################################
div10u:
	# calculate approximate quotient q_accum = n * 0.8
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

	# final adjustment: (n * 0.8) / 8 = n / 10
	srli	a1, a1, 3

	# calculate r = n - 10*q
	mul10	a2, a1, a3	# a2 = 10q
	sub	a2, a2, a0	# negative remainder

	# correction - diff < -9 implies remainder >= 10
	slti	a3, a2, -9
	add	a0, a1, a3

	ret
.size div10u, .-div10u

################################################################################
# routine: div11u
#
# Unsigned fast division by 11.
# Base: 3 * (n/4 - n/128) = n * 93/128.
#
# input:  a0 = unsigned dividend
# output: a0 = quotient
################################################################################	
div11u:
	# estimator: q = n * (1/11)
	# base: n * 93/128
	# calc: 3 * (n >> 2 - n >> 7)
	srli	a1, a0, 2
	srli	a2, a0, 7
	sub	a1, a1, a2	# a1 = n/4 - n/128
	mul3	a1, a1, a2	# a1 = 3 * a1 (uses a2 as scratch)

	# series expansion (1 + 2^-10 + ...)
	# factor 93/128 matches the required 10-bit period of 1/11
	srli	a2, a1, 10
	add	a1, a1, a2
	srli	a2, a1, 20
	add	a1, a1, a2
.if CPU_BITS == 64
	srli	a2, a1, 40
	add	a1, a1, a2
.endif

	# final shift: q_est = q_accum / 8
	srli	a1, a1, 3

	# negative remainder & correction
	mul11	a2, a1, a2	# a2 = 11 * q
	sub	a2, a2, a0	# a2 = 11q - n (negative remainder)

	# threshold: if diff <= -11 (i.e. < -10), add 1
	slti	a3, a2, -10
	add	a0, a1, a3	# q + correction

	ret	
.size div11u, .-div11u
	
################################################################################
# routine: div12u
#
# Unsigned fast division by 12 without using M extension.
# This routine is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses a series expansion algorithm to implement division.
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
# Unsigned fast division by 13.
# Optimizations: 
# - Robust Estimator (Max Error 1) to support 64-bit inputs.
# - Negative Remainder Trick to minimize correction instructions.
#
# input:  a0 = dividend
# output: a0 = quotient
################################################################################	
div13u:
	# estimator: q = n * (1/13)
	# base: n * 5/8 * 63/64 approx n * 0.6152...
	# target: n * 8/13 = n * 0.6153...
	srli	a1, a0, 1
	srli	a2, a0, 3
	add	a1, a1, a2	# a1 = n * 0.625

	srli	a2, a1, 6
	sub	a1, a1, a2	# a1 = n * 0.61523...

	# series expansion (1 + 2^-12 + ...)
	srli	a2, a1, 12
	add	a1, a1, a2
	srli	a2, a1, 24
	add	a1, a1, a2
.if CPU_BITS == 64
	srli	a2, a1, 48
	add	a1, a1, a2
.endif

	srli	a1, a1, 3	# q_est = q_accum / 8

	# negative remainder & correction
	mul13	a2, a1, a2	# a2 = 13 * q
	sub	a2, a2, a0	# a2 = 13q - n (Negative Remainder)

	# threshold: if diff <= -13 (i.e. < -12), add 1
	slti	a3, a2, -12
	add	a0, a1, a3	# q + correction

	ret	
.size div13u, .-div13u

################################################################################
# routine: div100u
#
# Unsigned fast division by 100.
# Algorithm: Direct series expansion for 0.64.
# Base: 0.5 + 0.125 + 0.015625 = 0.640625.
# Series: 1 - 1/1024 + 1/2^20...
#
# input:  a0 = unsigned dividend
# output: a0 = quotient
################################################################################	
div100u:
	# estimator: q = n * 0.64
	# base: n * (1/2 + 1/8 + 1/64)
	srli	a1, a0, 1
	srli	a2, a0, 3
	add	a1, a1, a2
	srli	a2, a0, 6
	add	a1, a1, a2	# a1 = n * 0.640625

	# series expansion
	# correct 0.640625 -> 0.64 (factor is approx 1 - 1/1024)
	srli	a2, a1, 10
	sub	a1, a1, a2

	# refine (factor 1 + 1/2^20)
	srli	a2, a1, 20
	add	a1, a1, a2

.if CPU_BITS == 64
	# refine (factor 1 + 1/2^40)
	srli	a2, a1, 40
	add	a1, a1, a2
.endif

	# final shift: (n * 0.64) / 64 = n / 100
	srli	a1, a1, 6	# q_est

	# correction
	# calculate negative remainder: diff = 100q - n
	mul100	a2, a1, a3	# a2 = 100 * q
	sub	a2, a2, a0	# a2 = 100q - n

	# threshold: if diff <= -100 (i.e. < -99), add 1
	slti	a3, a2, -99
	add	a0, a1, a3	# q + correction

	ret
.size div100u, .-div100u

################################################################################
# routine: div1000u
#
# Unsigned fast division by 1000 without M extension.
# Algorithm: Chained Division (n / 10) / 100.
#
# input:  a0 = unsigned dividend
# output: a0 = quotient
################################################################################	
div1000u:
	# calculate q = n / 10
	# estimator: n * 0.8
	srli	a2, a0, 2
	sub	a1, a0, a2	# a1 = n * 0.75

	# series for 0.8
	srli	a2, a1, 4
	add	a1, a1, a2
	srli	a2, a1, 8
	add	a1, a1, a2
	srli	a2, a1, 16
	add	a1, a1, a2
.if CPU_BITS == 64
	srli	a2, a1, 32
	add	a1, a1, a2
.endif
	srli	a1, a1, 3	# a1 = q_est (n/10)

	# correction for div10
	mul10	a2, a1, a3	# a2 = 10 * q
	sub	a2, a2, a0	# a2 = 10q - n
	slti	a3, a2, -9
	add	a0, a1, a3	# a0 = result of n/10

	# calculate q = a0 / 100
	# estimator: n * 0.64 (optimized series)
	# base: n * (1/2 + 1/8 + 1/64) = n * 0.640625
	srli	a1, a0, 1
	srli	a2, a0, 3
	add	a1, a1, a2
	srli	a2, a0, 6
	add	a1, a1, a2	# a1 = n * 0.640625

	# series for 0.64
	srli	a2, a1, 10
	sub	a1, a1, a2	# correct 0.6406 -> 0.64
	srli	a2, a1, 20
	add	a1, a1, a2	# refine
.if CPU_BITS == 64
	srli	a2, a1, 40
	add	a1, a1, a2
.endif
	srli	a1, a1, 6	# a1 = q_est (n/1000)

	# correction for div100
	mul100	a2, a1, a3	# a2 = 100 * q
	sub	a2, a2, a0	# a2 = 100q - n
	slti	a3, a2, -99
	add	a0, a1, a3	# a0 = final result

	ret
.size div1000u, .-div1000u
	
################################################################################
# routine: div3
#
# Signed fast division by 3.
# Algorithm: Abs(n) -> Unsigned Div -> Restore Sign.
# Suitable for RV32I, RV32I, RV64I	
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
.size div3, .-div3

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

.size div5, .-div5

################################################################################
# routine: div6
#
# Signed fast division by 6.
# Algorithm: abs(n) / 6 -> restore sign.
#
# input:  a0 = signed dividend
# output: a0 = signed quotient
################################################################################
div6:
	# preamble: compute sign mask (t0) and abs(n) (a0)
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0	# a0 = abs(n)

	# estimate quotient: q = abs(n) / 6
	# base: n * (1/2 + 1/8) = n * 0.625
	# target: n * 4/6 = n * 0.666...
	srli	a1, a0, 1
	srli	a2, a0, 3
	add	a1, a1, a2

	# series expansion (converges to 0.666...)
	srli	a2, a1, 4
	add	a1, a1, a2
	srli	a2, a1, 8
	add	a1, a1, a2
	srli	a2, a1, 16
	add	a1, a1, a2
.if CPU_BITS == 64
	srli	a2, a1, 32
	add	a1, a1, a2
.endif

	# final shift: q_est = q_accum / 4
	srli	a1, a1, 2

	# negative remainder calculation
	# diff = 6q - abs(n)
	mul6	a2, a1, a2	# a2 = 6 * q
	sub	a2, a2, a0	# a2 = 6q - abs(n)

	# threshold 1: diff <= -6 (i.e. < -5)
	slti	a3, a2, -5
	add	a1, a1, a3	# q += 1

.if CPU_BITS == 64
	# threshold 2: diff <= -12 (i.e. < -11)
	# handles max 63-bit error (2)
	slti	a3, a2, -11
	add	a1, a1, a3	# q += 1
.endif

	# postamble: restore sign
	xor	a0, a1, t0
	sub	a0, a0, t0

	ret
.size div6, .-div6

################################################################################
# routine: div7
#
# Signed fast division by 7.
# RV32I, RV32E, RV64I
#
# Input:  a0 = dividend (signed)
# Output: a0 = quotient (signed)
################################################################################
div7:
	# preamble: compute sign mask (t0) and abs(n) (a0)
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0	# a0 = abs(n)

	# estimate quotient: q = abs(n) / 7
	# base: n * 0.5625 (9/16)
	srli	a1, a0, 1
	srli	a2, a0, 4
	add	a1, a1, a2

	# series expansion: converge 0.5625 -> 0.5714...
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

	# final shift: q_est = (n * 4/7) / 4 = n / 7
	srli	a1, a1, 2

	# negative remainder calculation
	# diff = 7q - abs(n)
	slli	a2, a1, 3	# a2 = 8q
	sub	a2, a2, a1	# a2 = 7q
	sub	a2, a2, a0	# a2 = diff

	# threshold check 1: diff <= -7 (i.e. < -6)
	slti	a3, a2, -6
	add	a1, a1, a3	# q += 1

.if CPU_BITS == 64
	# threshold check 2: diff <= -14 (i.e. < -13)
	# This handles the rare cases where estimation error is 2.
	slti	a3, a2, -13
	add	a1, a1, a3	# q += 1
.endif

	# postamble: restore sign
	xor	a0, a1, t0
	sub	a0, a0, t0
	ret

.size div7, .-div7

################################################################################
# routine: div9
#
# Signed fast division by 9.
# Algorithm: abs(n) / 9 -> restore sign.
# Core Logic: uses the efficient div9u series (n * 7/8 * geometric_series).
#
# input:  a0 = signed dividend (32 or 64 bits)
# output: a0 = signed quotient
################################################################################
div9:
	# preamble: compute sign mask (t0) and abs(n) (a0)
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0	# a0 = abs(n)

	# estimate quotient: q = abs(n) / 9
	# target: q_accum = n * (8/9)
	# start with n * (7/8)
	srli	a2, a0, 3	# a2 = n >> 3
	sub	a1, a0, a2	# a1 = n - (n >> 3) = n * 0.875

	# series expansion: multiply by (1 + 1/64 + 1/4096...)
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

	# final adjustment: q = (n * 8/9) / 8 = n / 9
	srli	a1, a1, 3	# a1 = q_approx

	# negative remainder correction
	# diff = 9q - abs(n)
	mul9	a3, a1, a2	# a3 = 9 * q
	sub	a2, a3, a0	# a2 = 9q - abs(n)

	# threshold check: is diff <= -9?
	# -9 < -8 -> 1 (correction needed)
	slti	a3, a2, -8
	add	a1, a1, a3	# q_final = q + correction

	# postamble: restore sign
	xor	a0, a1, t0
	sub	a0, a0, t0

	ret
.size div9, .-div9

################################################################################
# routine: div10
#
# Signed fast division by 10.
# Algorithm: abs(n) / 10 -> restore sign.
# Core Logic: Uses the div10u series (n * 0.8 / 8).
#
# input:  a0 = signed dividend
# output: a0 = signed quotient
################################################################################
div10:
	# preamble: compute sign mask (t0) and abs(n) (a0)
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0	# a0 = abs(n)

	# estimate quotient: q = abs(n) / 10
	# target: q_accum = n * 0.8
	# start with n * 0.75
	srli	a2, a0, 2
	sub	a1, a0, a2

	# series expansion: converge 0.75 -> 0.8
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

	# final adjustment: q = (n * 0.8) / 8 = n / 10
	srli	a1, a1, 3	# a1 = q_approx

	# negative remainder correction
	# diff = 10q - abs(n)
	mul10	a2, a1, a3	# a2 = 10 * q
	sub	a2, a2, a0	# a2 = 10q - abs(n)

	# threshold check: is diff <= -10?
	# -10 < -9 -> 1 (correction needed)
	slti	a3, a2, -9
	add	a1, a1, a3	# q_final = q + correction

	# postamble: restore sign
	xor	a0, a1, t0
	sub	a0, a0, t0

	ret
.size div10, .-div10

################################################################################
# routine: div11
#
# Signed fast division by 11.
# Algorithm: abs(n) / 11 -> restore sign.
# Estimator: 3 * (n/4 - n/128) = n * 93/128.
#
# input:  a0 = signed dividend
# output: a0 = signed quotient
################################################################################
div11:
	# preamble: compute sign mask (t0) and abs(n) (a0)
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0	# a0 = abs(n)

	# estimate quotient: q = abs(n) / 11
	# base: n * 93/128 (matches previous n * 0.7265...)
	# calc: 3 * (n/4 - n/128)
	srli	a1, a0, 2
	srli	a2, a0, 7
	sub	a1, a1, a2	# a1 = n/4 - n/128
	mul3	a1, a1, a2	# a1 = 3 * a1 (uses a2 as scratch)

	# series expansion: refine to 8/11 (period 10 bits)
	srli	a2, a1, 10
	add	a1, a1, a2
	srli	a2, a1, 20
	add	a1, a1, a2
.if CPU_BITS == 64
	srli	a2, a1, 40
	add	a1, a1, a2
.endif

	# final shift: q_est = q_accum / 8
	srli	a1, a1, 3

	# negative remainder correction
	# diff = 11q - abs(n)
	mul11	a2, a1, a2	# a2 = 11 * q
	sub	a2, a2, a0	# a2 = 11q - abs(n)

	# threshold check: is diff <= -11?
	# -11 < -10 -> 1 (correction needed)
	slti	a3, a2, -10
	add	a1, a1, a3	# q_final = q + correction

	# postamble: restore sign
	xor	a0, a1, t0
	sub	a0, a0, t0

	ret
.size div11, .-div11
	
################################################################################
# routine: div12
#
# Signed fast division by 12.
# Algorithm: abs(n) / 12 -> restore sign.
# Optimization: Defers correction until after the divide-by-4 shift, 
#               allowing a simple threshold check instead of mul11.
#
# input:  a0 = signed dividend
# output: a0 = signed quotient
################################################################################
div12:
	# preamble: compute sign mask (t0) and abs(n) (a0)
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0	# a0 = abs(n)

	# estimate quotient q3 = abs(n) / 3
	# series: 1/4 + 1/16 + 1/64 ...
	srli	a1, a0, 2
	srli	a2, a0, 4
	add	a1, a1, a2	# q = (n >> 2) + (n >> 4)
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

	# final shift: q12 = q3 / 4
	srli	a1, a1, 2	# a1 = q_est (n/12)

	# negative remainder correction
	# diff = 12q - abs(n)
	mul12	a2, a1, a3	# a2 = 12 * q (uses mul3 + slli 2)
	sub	a2, a2, a0	# a2 = 12q - abs(n)

	# threshold check: is diff <= -12?
	# -12 < -11 -> 1 (correction needed)
	slti	a3, a2, -11
	add	a1, a1, a3	# q_final = q + correction

	# postamble: restore sign
	xor	a0, a1, t0
	sub	a0, a0, t0

	ret
.size div12, .-div12

################################################################################
# routine: div13
#
# Signed fast division by 13.
# Algorithm: abs(n) / 13 -> restore sign.
# Core Logic: Uses the optimized div13u series (Max Error 1).
#
# input:  a0 = signed dividend
# output: a0 = signed quotient
################################################################################
div13:
	# preamble: compute sign mask (t0) and abs(n) (a0)
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0	# a0 = abs(n)

	# estimate quotient: q = abs(n) / 13
	# base: n * 5/8 * 63/64
	srli	a1, a0, 1
	srli	a2, a0, 3
	add	a1, a1, a2	# a1 = n * 0.625

	srli	a2, a1, 6
	sub	a1, a1, a2	# a1 = n * 0.61523...

	# series expansion
	srli	a2, a1, 12
	add	a1, a1, a2
	srli	a2, a1, 24
	add	a1, a1, a2
.if CPU_BITS == 64
	srli	a2, a1, 48
	add	a1, a1, a2
.endif

	# final shift: q_est = q_accum / 8
	srli	a1, a1, 3

	# negative remainder correction
	# diff = 13q - abs(n)
	mul13	a2, a1, a2	# a2 = 13 * q
	sub	a2, a2, a0	# a2 = 13q - abs(n)

	# threshold check: is diff <= -13?
	# -13 < -12 -> 1 (correction needed)
	slti	a3, a2, -12
	add	a1, a1, a3	# q_final = q + correction

	# postamble: restore sign
	xor	a0, a1, t0
	sub	a0, a0, t0

	ret
.size div13, .-div13

################################################################################
# routine: div100
#
# Signed fast division by 100.
# Algorithm: abs(n) / 100 -> restore sign.
# Core Logic: uses the optimized div100u series (n * 0.64).
#
# input:  a0 = signed dividend
# output: a0 = signed quotient
################################################################################
div100:
	# preamble: compute sign mask (t0) and abs(n) (a0)
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0	# a0 = abs(n)

	# estimate quotient: q = abs(n) / 100
	# base: n * 0.640625 (1/2 + 1/8 + 1/64)
	srli	a1, a0, 1
	srli	a2, a0, 3
	add	a1, a1, a2
	srli	a2, a0, 6
	add	a1, a1, a2	# a1 = n * 0.640625

	# series expansion
	# correct 0.6406 -> 0.64 (factor approx 1 - 1/1024)
	srli	a2, a1, 10
	sub	a1, a1, a2

	# refine (factor 1 + 1/2^20)
	srli	a2, a1, 20
	add	a1, a1, a2

.if CPU_BITS == 64
	# refine (factor 1 + 1/2^40)
	srli	a2, a1, 40
	add	a1, a1, a2
.endif

	# final shift: (n * 0.64) / 64 = n / 100
	srli	a1, a1, 6	# a1 = q_est

	# correction
	# diff = 100q - abs(n)
	mul100	a2, a1, a3	# a2 = 100 * q
	sub	a2, a2, a0	# a2 = 100q - abs(n)

	# threshold check: is diff <= -100?
	# -100 < -99 -> 1 (correction needed)
	slti	a3, a2, -99
	add	a1, a1, a3	# q_final = q + correction

	# postamble: restore sign
	xor	a0, a1, t0
	sub	a0, a0, t0

	ret
.size div100, .-div100

################################################################################
# routine: div1000
#
# Signed fast division by 1000.
# Algorithm: abs(n) / 1000 -> restore sign.
# Core Logic: uses the optimized div1000u chained division (n/10)/100.
#
# input:  a0 = signed dividend
# output: a0 = signed quotient
################################################################################
div1000:
	# preamble: compute sign mask (t0) and abs(n) (a0)
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0	# a0 = abs(n)

	# calculate q1 = abs(n) / 10
	# estimator: n * 0.8
	srli	a2, a0, 2
	sub	a1, a0, a2	# a1 = n * 0.75

	# series for 0.8
	srli	a2, a1, 4
	add	a1, a1, a2
	srli	a2, a1, 8
	add	a1, a1, a2
	srli	a2, a1, 16
	add	a1, a1, a2
	# can skip refinement for 64 bit here as signed number
	# only has 63 bits, and testing shows we don't need it.
	
	srli	a1, a1, 3	# a1 = q_est (n/10)

	# correction for div10
	mul10	a2, a1, a3	# a2 = 10 * q
	sub	a2, a2, a0	# a2 = 10q - n
	slti	a3, a2, -9
	add	a0, a1, a3	# a0 = result of n/10

	# calculate q = q1 / 100
	# estimator: n * 0.64 (optimized series)
	# base: n * (1/2 + 1/8 + 1/64) = n * 0.640625
	srli	a1, a0, 1
	srli	a2, a0, 3
	add	a1, a1, a2
	srli	a2, a0, 6
	add	a1, a1, a2	# a1 = n * 0.640625

	# series for 0.64
	srli	a2, a1, 10
	sub	a1, a1, a2	# correct 0.6406 -> 0.64
	srli	a2, a1, 20
	add	a1, a1, a2	# refine
.if CPU_BITS == 64
	srli	a2, a1, 40
	add	a1, a1, a2
.endif
	srli	a1, a1, 6	# a1 = q_est (n/1000)

	# correction for div100
	mul100	a2, a1, a3	# a2 = 100 * q
	sub	a2, a2, a0	# a2 = 100q - n
	slti	a3, a2, -99
	add	a1, a1, a3	# q_final = q + correction

	# postamble: restore sign
	xor	a0, a1, t0
	sub	a0, a0, t0

	ret
.size div1000, .-div1000	
	
# Below is based on Hacker's Delight 2nd Edition Chapter 10, but this routine
# and the other remainder routines I didn't implement are kind of useless 
# as it's faster to calculate the quotient and calculate the remainder from
# that. I could modify the above routines to also return the remainder in addition	
# to the quotient, which seems useful, but would likely cost 3-4
# instructions per routine. Not yet sure if I want to do this or not.

######################################################################
# routine: mod3
#
# calculate a0 % 3 (signed)
#
# input:  a0 = signed integer
# output: a0 = signed remainder
######################################################################
mod3:
	# preamble: abs(n) and save sign mask in t0
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0
	j	mod3_reduction

######################################################################
# routine: mod3u
#
# calculate a0 % 3 (unsigned)
#
# input:  a0 = unsigned integer
# output: a0 = unsigned remainder
######################################################################
mod3u:
	li	t0, 0		# sign mask = 0

mod3_reduction:
	# estimate q = n / 3
	# base: n * 5/16
	srli	a1, a0, 2
	srli	a2, a0, 4
	add	a1, a1, a2

	# series expansion (1/3)
	srli	a2, a1, 4
	add	a1, a1, a2
	srli	a2, a1, 8
	add	a1, a1, a2
	srli	a2, a1, 16
	add	a1, a1, a2
.if CPU_BITS == 64
	srli	a2, a1, 32
	add	a1, a1, a2
.endif
	# a1 = q_est (approx n/3)

	# calculate remainder
	# diff = 3*q_est - n
	mul3	a2, a1, a2	# a2 = 3 * q_est
	sub	a2, a2, a0	# a2 = diff

	# threshold: if diff <= -3, we missed by 3
	slti	a3, a2, -2	# a3 = correction (0 or 1)

	# remainder = -diff - 3*correction
	sub	a2, zero, a2	# a2 = -diff
	mul3	a3, a3, a4	# a3 = 3 * correction
	sub	a0, a2, a3	# a0 = remainder

	# restore sign
	xor	a0, a0, t0
	sub	a0, a0, t0

	ret
.size mod3, .-mod3
.size mod3u, .-mod3u
