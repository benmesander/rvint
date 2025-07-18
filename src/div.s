	.include "config.s"

.globl divremu
.globl divrem
.globl div3u
.globl div10u
	
.text

################################################################################
# routine: divremu
#
# Unsigned integer division using a restoring algorithm.
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
	mv	a0, zero		# a0 will hold the remainder, initialized to 0.
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

# calls divremu, which uses a0-a5.
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
	add	a0, a1, a3	# a0 = q + correction
	ret
	
.size div10u, .-div10u
