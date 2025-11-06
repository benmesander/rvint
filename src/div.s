	.include "config.s"

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
	
.text

################################################################################
# routine: divremu
#
# Unsigned integer division using a restoring algorithm.
# RV32E compatible.
#
# input registers:
# a0 = dividend
# a1 = divisor
#
# output registers:
# a0 = quotient
# a1 = remainder
################################################################################

divremu:
	# Check for division by zero
	beqz	a1, divremu_zero

	mv	a2, a0		# Use a2 for the dividend; it will become the quotient.
	mv	a0, zero	# a0 will hold the remainder, initialized to 0.
	li	a3, CPU_BITS	# Use a3 as the loop counter.

divremu_loop:
	# Step 1: Shift the remainder left by 1.
	slli	a0, a0, 1

	# Step 2: Bring the next bit from the dividend (MSB of a2) into the remainder.
	bltz	a2, set_rem_bit

continue_shift:
	# Step 3: Shift the dividend left.
	slli	a2, a2, 1

	# Step 4: Fast Path - If remainder < divisor, do nothing else this iteration.
	bltu	a0, a1, continue_loop
	
	# Step 5: If remainder >= divisor, subtract and set the quotient bit.
	sub	a0, a0, a1
	ori	a2, a2, 1

continue_loop:
	# Step 6: Decrement the counter and loop if not finished.
	addi	a3, a3, -1
	bnez	a3, divremu_loop
	j	done

set_rem_bit:
	ori	a0, a0, 1
	j	continue_shift

done:
	# Final result arrangement
	mv	a1, a0
	mv	a0, a2
	ret

divremu_zero:
	mv	a1, a0
	li	a0, -1
	ret

.size divremu, .-divremu

################################################################################
# routine: divrem
#
# Signed integer division - rounds towards zero.
# This division is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses the restoring division algorithm. It can be used to emulate
# the RISC-V M extension div, rem, divw, and remw instructions.
#
# input registers:
# a0 = dividend (N)
# a1 = divisor (D)
#
# output registers:
# a0 = quotient (Q)
# a1 = remainder (R)
################################################################################

# calls divremu, which uses a0-a3.
# stash a0, a1 in t0, t1
# this uses t0-t5 to avoid the s regs

divrem:
	FRAME	1
	PUSH	ra, 0
	mv	t0, a0			# t0 = Original N
	mv	t1, a1			# t1 = Original D

	# Handle original division by zero (signed spec)
	beq	t1, zero, divrem_by_zero

	# Handle overflow: MIN_INT / -1
.if CPU_BITS == 32
	li	t2, 0x80000000		# t2 = INT_MIN for RV32I
.else # CPU_BITS == 64
	li	t2, 1
	slli	t2, t2, (CPU_BITS - 1)	# t2 = LONG_MIN for RV64I
.endif
	li	t3, -1			# t3 = -1 (for divisor check)
	beq	t0, t2, divrem_check_overflow_denom # Check original N
	j	divrem_continue

divrem_check_overflow_denom:
	beq	t1, t3, divrem_overflow	# Check original D

divrem_continue:
	# Original N in t0, Original D in t1.
	srai	t4, t0, (CPU_BITS - 1)	# t2 = sign_N_mask
	srai	t5, t1, (CPU_BITS - 1)	# t3 = sign_D_mask

	xor	a0, t0, t4
	sub	a0, a0, t4		# a0 now holds abs(N)

	xor	a1, t1, t5
	sub	a1, a1, t5		# a1 now holds abs(D)

	call	divremu
	# divremu returns: a0 = abs(Q), a1 = abs(R)
	# Original N/D and intermediate abs(N)/abs(D) in t0,t1 are now clobbered.
	# Sign masks are safe in t4, t5.

	# Apply signs.
	# abs_Q in a0, abs_R in a1.
	# sign_N_mask in t4. sign_D_mask in t5.

	# Quotient sign: sign_N_mask ^ sign_D_mask
	# Use t0 (clobbered by divremu, now free) for sign_Q_mask.
	xor	t0, t4, t5		# t0 = sign_Q_mask
	xor	a0, a0, t0		# Apply sign to quotient a0
	sub	a0, a0, t0

	# Remainder sign: sign_N_mask (in t4)
	beq	t4, zero, divrem_cleanup_stack # If original N was positive, R sign is ok
	# Original N was negative. If R (abs_R in a1) is non-zero, negate it.
	bne	a1, zero, divrem_negate_remainder
	j	divrem_cleanup_stack

divrem_negate_remainder:
	sub	a1, zero, a1		# Negate remainder
	j	divrem_cleanup_stack

divrem_by_zero: # Handles original D == 0
	li	a0, -1			# Quotient = -1
	# Original dividend was saved in t0 at the very start of this routine
	mv	a1, t0			# Remainder = Original Dividend
	j	divrem_cleanup_stack

divrem_overflow:   # Handles MIN_INT / -1
.if CPU_BITS == 32
	li	a0, 0x80000000		# Quotient = INT_MIN for RV32I
.else # CPU_BITS == 64
	li	a0, 1
	slli	a0, a0, (CPU_BITS - 1)	# Quotient = LONG_MIN for RV64I
.endif
	mv	a1, zero		# Remainder = 0
divrem_cleanup_stack:
	POP	ra, 0
	EFRAME	1
	ret

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
	srli    a1, a0, 2      # a1: q = n >> 2
	srli    a2, a0, 4      # a2: n >> 4
	add     a1, a2, a1     # a1: q = (n >> 2) + (n >> 4)
	srli    a2, a1, 4      # a2: q >> 4
	add     a1, a2, a1     # a1: q = q + (q >> 4)
	srli    a2, a1, 8      # a2: q >> 8
	add     a1, a2, a1     # a1: q = q + (q >> 8)
	srli    a2, a1, 16     # a2: q >> 16
	add     a1, a2, a1     # a1: q = q + (q >> 16)
.if CPU_BITS == 64
	srli    a2, a1, 32     # a2: q >> 32
	add     a1, a2, a1     # a1: q = q + (q >> 32)
.endif
	# Remainder calculation
	slli    a2, a1, 1      # a2: q * 2
	add     a2, a2, a1     # a2: q * 3
	sub     a2, a0, a2     # a2: r = n - q * 3

.if CPU_BITS == 64
        # Correction step for 64-bit (5 instructions)
        # Handles errors up to 6+. Calculates floor(r*11/32).
        slli    a0, a2, 3       # a0: r * 8
        add     a0, a0, a2      # a0: r * 9
        slli    a2, a2, 1       # a2: r * 2
        add     a0, a0, a2      # a0: r * 11
        srli    a0, a0, 5       # a0: correction amount
.else
        # Correction step for 32-bit (4 instructions)
        # Sufficient for errors up to 5. Calculates floor((5r+5)/16).
        addi    a0, a2, 5       # a0: r + 5
        slli    a2, a2, 2       # a2: r << 2
        add     a0, a0, a2      # a0: (r + 5) + (r << 2)
        srli    a0, a0, 4       # a0: correction amount
.endif

        add     a0, a1, a0      # a0: q + correction

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
	srli	a1, a0, 1	# a1 = (n >> 1)
	srli	a2, a0, 2	# a2 = (n >> 2)
	add	a1, a1, a2	# a1 = q = (n >> 1) + (n >> 2)
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
	slli	a2, a1, 2	# a2 = q*4
	add	a2, a2, a1	# a2 = q*4 + q = q*5
	sub	a2, a0, a2	# a2 = r = n - q*5

	# Add correction q + (7*r >> 5)
	slli	a3, a2, 3	# a3 = r*8
	sub	a2, a3, a2	# a2 = (r*8) - r = r*7
	srli	a2, a2, 5	# a2 = 7*r >> 5
	add	a0, a1, a2	# a0 = q + (7*r >> 5)
	ret
.size div5u, .-div5u
	
.if 0 == 1
div5u:
        # Estimate quotient: q_est = (n >> 3) + (n >> 4)
        # This is a fast, XLEN-agnostic under-estimate (n * 0.1875)
        srli    a1, a0, 3               # a1 = n >> 3
        srli    a2, a0, 4               # a2 = n >> 4
        add     a1, a1, a2              # a1 = q_est

        # Calculate remainder: r = n - q*5
        slli    a2, a1, 2               # a2 = q_est * 4
        add     a2, a2, a1              # a2 = q_est * 5
        sub     a2, a0, a2              # a2 = r = n - q_est*5

        # Add correction: q + (7*r >> 5)
        slli    a3, a2, 3               # a3 = r * 8
        sub     a2, a3, a2              # a2 = (r * 8) - r = r * 7
        srli    a2, a2, 5               # a2 = (r * 7) >> 5
        add     a0, a1, a2              # a0 = q_est + correction

        ret

.size div5u, .-div5u
.endif


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
	slli	a2, a1, 2	# a2 = q * 4
	slli	a3, a1, 1	# a3 = q * 2
	add	a2, a2, a3	# a2 = q * 6
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
	slli	a3, a2, 3	# a3 = r * 8
	add	a3, a3, a2	# a3 = r * 9
	slli	a4, a2, 1	# a4 = r * 2
	add	a3, a3, a4	# a3 = r * 11
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
	srli	a3, a1, 24	# a3 = (q >> 24)
	add	a1, a1, a2	# a1 = q + (q >> 12)
	add	a1, a1, a3	# a1 = q + (q >> 12) + (q >> 24)
	srli	a1, a1, 2	# a1 = q >> 2
.if CPU_BITS == 64
	srli	a2, a1, 48	# a2 = (q >> 48)
	add	a1, a1, a2	# a1 = q + (q >> 48)
.endif

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
# Unsigned fast division by 9 without using M extension.
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
div9u:
        # Phase 1: approximate quotient
        # Common start: use subtractive refinement style (guarantees under/estimate)
        srli    a2, a0, 3       # a2 = n >> 3
        sub	a1, a0, a2	# a1 = q = n - (n >> 3)

        srli    a2, a1, 6	# a2 = q >> 6
        add     a1, a1, a2	# a1 = q + (q >> 6)
        srli    a2, a1, 12	# a2 = q >> 12
        add     a1, a1, a2	# a1 = q + (q >> 12)
        srli    a2, a1, 24	# a2 = q >> 24
        add     a1, a1, a2	# a1 = q + (q >> 24)

.if CPU_BITS == 64
        # extra refinement for 64-bit (keeps remainder small enough for fixed-point correction)
        srli    a2, a1, 36	# a2 = q >> 36
        add     a1, a1, a2	# a2 = q + (q >> 36)
        srli    a2, a1, 48	# a2 = q >> 48
        add     a1, a1, a2	# a2 = q + (q >> 48)
.endif

        srli    a1, a1, 3        # a1 = q = q >> 3

        # Phase 2: remainder r = n - 9*q
        slli    a2, a1, 3        # a2 = q*8
        add     a3, a1, a2       # a3 = q*9
        sub     a2, a0, a3       # a2 = r = n - 9*q

.if CPU_BITS == 32
        # Phase 3 (RV32): correction
        # if r >= 9 then q+1 else q
        sltiu   a3, a2, 9        # a3 = 1 if r < 9
        xori    a3, a3, 1        # a3 = 1 if r >= 9
.endif

.if CPU_BITS == 64
        # Phase 3 (RV64):  correction
	# corr = floor(r/9) using (r * 5) >> 4
	slli	a3, a2, 2	# a3 = r * 4
	add	a3, a3, a2	# a3 = r * 5
	srli	a3, a3, 4	# a3 = (r * 5) >> 4
.endif

        add     a0, a1, a3       # final quotient
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
	# Phase 1: Calculate approximate quotient q.
	srli	a1, a0, 1	# a1 = (n >> 1)
	srli	a2, a0, 2	# a2 = (n >> 2)
	add	a1, a1, a2	# a1 = (n >> 1) + (n >> 2)
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
	srli	a1, a1, 3	# a1 = q = q >> 3 (Final approximate quotient)

	# Phase 2: Calculate r = n - 10*q
	slli	a2, a1, 1	# a2 = q * 2
	slli	a3, a2, 2	# a3 = (q * 2) * 4 = q * 8
	add	a2, a2, a3	# a2 = (q * 2) + (q * 8) = q * 10
	sub	a3, a0, a2	# a3 = r = n - (q * 10)

	# Phase 3: Add correction if r >= 10. This logic is robust for both 32 and 64 bits.
	sltiu	a3, a3, 10	# a3 = 1 if r < 10, else 0
	xori	a3, a3, 1	# a3 = 1 if r >= 10, else 0 (correction factor)
	add	a0, a1, a3	# a0 = q + (r > 9)
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
	slli	a1, a2, 4
	slli	a3, a2, 2
	sub	a1, a1, a3
	sub	a1, a1, a2
	sub	a1, a0, a1	# a1 = r = n - q8*11

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
	srli	a1, a0, 1	# a1 = (n >> 1)
	srli	a2, a0, 3	# a2 = (n >> 3)
	add	a1, a1, a2	# a1 = q = (n >> 1) + (n >> 3)
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
	slli	a2, a1, 1
	add	a2, a2, a1
	slli	a2, a2, 2	# a2 = q*12
	sub	a2, a0, a2	# a1 = r = n - q*12

	# correct approximate quotient
	sltiu	a3, a1, 12	# a3 = 1 if r < 12, else 0
	xori	a3, a3, 1	# a3 = 1 if r >= 12, else 0
	add	a0, a2, a3	# a0 = q = q + correction
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
	slli	a2, a1, 4
	slli	a3, a1, 2
	sub	a2, a2, a3
	add	a2, a2, a1	# a2 = q*13
	sub	a2, a0, a2	# a2 = r = n - q*13

	# correct estimated quotient
	# compute corr = floor(r / 13) using (r * 5) >> 6
	slli	a3, a2, 2	# a3 = r * 4
	add	a3, a3, a2	# a3 = r * 5
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

.if CPU_BITS == 64
	# 64-bit specific approximation steps
	# This is derived from q = (n>>1)+(n>>3); q = q + (q>>6); ...
	srli    a2, a1, 6
	add     a1, a1, a2	# a1 = a1 + (a1>>6)
	srli    a2, a1, 12
	add     a1, a1, a2  	# a1 = a1 + (a1>>12)
	srli    a2, a1, 24
	add     a1, a1, a2  	# a1 = a1 + (a1>>24)
	srli    a2, a1, 48
	add     a1, a1, a2  	# a1 = a1 + (a1>>48)
.else
	# 32-bit specific approximation steps
	# This sequence approximates (n * 0.64) for 32-bit n.
	srli    a2, a0, 6   	# a2 = (n >> 6)
	add     a1, a1, a2  	# a1 = (n >> 1) + (n >> 3) + (n >> 6)
	srli    a2, a0, 10  	# a2 = (n >> 10)
	sub     a1, a1, a2  	# ... - (n >> 10)
	srli    a2, a0, 12  	# a2 = (n >> 12)
	add     a1, a1, a2  	# ... + (n >> 12)
	srli    a2, a0, 13  	# a2 = (n >> 13)
	add     a1, a1, a2  	# ... + (n >> 13)
	srli    a2, a0, 15  	# a2 = (n >> 15)
	sub     a1, a1, a2  	# ... - (n >> 15)
	srli    a2, a1, 20  	# a2 = (q_approx >> 20)
	add     a1, a1, a2  	# a1 = q_approx + (q_approx >> 20)
.endif
	srli	a1, a1, 6	# a1 = q_est

	# Compute remainder from estimated quotient (XLEN-agnostic)
	# n*100 = (n << 6) + (n << 5)) + (n << 2)
	# This is safe from overflow because the max quotient for 64-bit
	# (UINT64_MAX / 100) is << 64.
	slli    a2, a1, 6   	# a2 = q_est * 64
	slli    a3, a1, 5   	# a3 = q_est * 32
	add     a2, a2, a3  	# a2 = q_est * 96
	slli    a3, a1, 2   	# a3 = q_est * 4
	add     a2, a2, a3  	# a2 = q_est * 100
	sub     a2, a0, a2  	# a2 = r = n - q_est * 100


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
        # The 32-bit sequence is a high-precision fixed-point multiply.
        # q = [ (n>>1) + t + (n>>15) + (t>>11) + (t>>14) ] >> 9
        # where t = (n>>7) + (n>>8) + (n>>12)

        # Compute t = (n>>7) + (n>>8) + (n>>12)
        srli    a2, a0, 7
        srli    a3, a0, 8
        add     a2, a2, a3
        srli    a3, a0, 12
        add     a2, a2, a3      # a2 = t

        # Compute q = (n>>1) + (n>>15)
        srli    a1, a0, 1
        srli    a3, a0, 15
        add     a1, a1, a3

        # Add t and its shifted terms to q
        add     a1, a1, a2      # q = q + t
        srli    a3, a2, 11
        add     a1, a1, a3      # q = q + (t>>11)
        srli    a3, a2, 14
        add     a1, a1, a3      # q = q + (t>>14)

.if CPU_BITS == 64
        # 64-bit specific approximation steps (extend the series)
        srli    a3, a2, 22
        add     a1, a1, a3      # q = q + (t>>22)
        srli    a3, a2, 28
        add     a1, a1, a3      # q = q + (t>>28)
        srli    a3, a2, 44
        add     a1, a1, a3      # q = q + (t>>44)
        srli    a3, a2, 56
        add     a1, a1, a3      # q = q + (t>>56)
.endif

        # Common final shift for the quotient
        srli    a1, a1, 9       # a1 = q_est = (approximation >> 9)

        # Compute remainder from estimated quotient (XLEN-agnostic)
        # n*1000 = (n << 10) - (n << 4) - (n << 3)
        #        = 1024*n - 16*n - 8*n = 1000*n
        slli    a2, a1, 10      # a2 = q_est * 1024
        slli    a3, a1, 4       # a3 = q_est * 16
        sub     a2, a2, a3      # a2 = q_est * 1008
        slli    a3, a1, 3       # a3 = q_est * 8
        sub     a2, a2, a3      # a2 = q_est * 1000
        sub     a2, a0, a2      # a2 = r = n - q_est * 1000

        # Compute correction to estimated quotient (XLEN-agnostic)
        # The approximation is designed to be floor(n/1000), so the
        # remainder 'r' can be in the range [0, 1999].
        # If r >= 1000, we must add 1 to the quotient.

        # Compare remainder 'a2'
        sltiu   a3, a2, 1000    # a3 = 1 if r < 1000, else 0

        # Invert logic: a3 = 1 if r >= 1000, else 0
        xori    a3, a3, 1       # a3 = correction factor (0 or 1)

        # Add correction 'a3' to quotient 'a1'
        add     a0, a1, a3      # a0 = q_final = q_est + correction
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
        srai    t0, a0, 31              # t0 = (n < 0) ? -1 : 0
.else
        srai    t0, a0, 63              # t0 = (n < 0) ? -1 : 0
.endif
        xor     a1, a0, t0              # a1 = n ^ sign
        sub     a1, a1, t0              # a1 = (n ^ sign) - sign = abs(n)

        # Core: Unsigned divide by 3 (div3u) operating on a1 (abs(n))
        # We use a0 as a temporary copy of abs(n) for the remainder calc.
        mv      a0, a1                  # a0 = abs(n)
        srli    a1, a1, 2               # a1: q = abs(n) >> 2
        srli    a2, a0, 4               # a2: abs(n) >> 4
        add     a1, a2, a1              # a1: q = q + (abs(n) >> 4)
        srli    a2, a1, 4               # a2: q >> 4
        add     a1, a2, a1              # a1: q = q + (q >> 4)
        srli    a2, a1, 8               # a2: q >> 8
        add     a1, a2, a1              # a1: q = q + (q >> 8)
        srli    a2, a1, 16              # a2: q >> 16
        add     a1, a2, a1              # a1: q = q + (q >> 16)
.if CPU_BITS == 64
        srli    a2, a1, 32              # a2: q >> 32
        add     a1, a2, a1              # a1: q = q + (q >> 32)
.endif

        # Remainder calculation
        # a1 = q_est, a0 = abs(n)
        slli    a2, a1, 1               # a2: q_est * 2
        add     a2, a2, a1              # a2: q_est * 3
        sub     a2, a0, a2              # a2: r = abs(n) - q_est * 3

        # Correction step (calculates correction in a0)
.if CPU_BITS == 64
        # Correction step for 64-bit (5 instructions)
        slli    a0, a2, 3               # a0: r * 8
        add     a0, a0, a2              # a0: r * 9
        slli    a2, a2, 1               # a2: r * 2
        add     a0, a0, a2              # a0: r * 11
        srli    a0, a0, 5               # a0: correction amount
.else
        # Correction step for 32-bit (4 instructions)
        addi    a0, a2, 5               # a0: r + 5
        slli    a2, a2, 2               # a2: r << 2
        add     a0, a0, a2              # a0: (r + 5) + (r << 2)
        srli    a0, a0, 4               # a0: correction amount
.endif
        add     a1, a1, a0              # a1 = q_est + correction = abs(n)/3

        # Postamble: Re-apply the original sign (from t0)
        # a1 has the unsigned quotient `q`, t0 has the sign mask
        xor     a0, a1, t0              # a0 = q ^ sign
        sub     a0, a0, t0              # a0 = (q ^ sign) - sign

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
        srai    a1, a0, 2
        srai    a2, a0, 4
        sub     a1, a1, a2      # a1 = (n>>2) - (n>>4)
        srai    a2, a0, 6
        add     a1, a1, a2      # a1 = q_est

        # Compute remainder r = n - (q_est * 5)
        # We can use (q_est * 4) + q_est
        slli    a2, a1, 2       # a2 = q_est * 4
        add     a2, a2, a1      # a2 = q_est * 5
        sub     a2, a0, a2      # a2 = r = n - (q_est * 5)

        # Branch-free correction.
        # Division truncates toward zero, so q must be:
        #   q_est + 1, if r > 4
        #   q_est - 1, if r < -4
        #   q_est,     otherwise

	# t0 = correction for case 1: (n >= 0 && r < 0) ? 1 : 0
        slti    t0, a0, 0       # t0 = (n < 0) ? 1 : 0
        xori    t0, t0, 1       # t0 = (n >= 0) ? 1 : 0
        slti    t1, a2, 0       # t1 = (r < 0) ? 1 : 0
        and     t0, t0, t1      # t0 = 1 if (n >= 0) AND (r < 0)

        # t1 = correction for case 2: (n < 0 && r > 0) ? 1 : 0
        slti    t1, a0, 0       # t1 = (n < 0) ? 1 : 0
        slt    a0, x0, a2      	# a0 = (r > 0) ? 1 : 0
        and     t1, t1, a0      # t1 = 1 if (n < 0) AND (r > 0)

        # Apply corrections
        add     a1, a1, t1      # a1 = q_est + (correction 2)
        sub     a0, a1, t0      # a0 = q_final = a1 - (correction 1)

        ret

.size div5, .-div5
