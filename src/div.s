.include "config.s"

.globl divremu
.globl divrem
.globl div3
	
.text

################################################################################
# routine: divremu
#
# Unsigned integer division without using M extension.
# This division is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses the restoring division algorithm. It can be used to emulate
# the RISC-V M extension div, rem, divw, and remw instructions.
#
# input registers:
# a0 = dividend
# a1 = divisor
#
# output registers:
# a0 = quotient
# a1 = remainder
################################################################################

# uses a0-a5

divremu:
	# check for division by zero, if so immediately return
	beqz	a1, divremu_zero

	mv	a2, a0		# dividend
	mv	a3, a1		# divisor
	li	a0, 0		# quotient
	li	a1, 0		# remainder
	li	a5, 1		# set bit to the highest bit position
	slli	a5, a5, CPU_BITS-1

divremu_loop:
	slli	a1, a1, 1	# shift remainder left by 1
	and	a4, a2, a5	# Isolate the highest bit of the dividend
	snez	a4, a4
	add	a1, a1, a4	# insert next dividend bit into remainder

	# Check if remainder is greater than or equal to divisor
	bltu	a1, a3, divremu_continue
	sub	a1, a1, a3	# subtract divisor from remainder
	add	a0, a0, a5	# add bit to quotient

divremu_continue:
	srli	a5, a5, 1	# shift the bit mask to the right
	bnez	a5, divremu_loop
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

################################################################################
# routine: div3
#
# Unsigned 32-bit integer division by 3 without using M extension. Suitable
# for RV32E.	
#
# input registers:
# a0 = dividend
#
# output registers:
# a0 = quotient
################################################################################

div3:	
	# a0 contains n
	srli	a1, a0, 2	# a1: q = n >> 2
	srli	a2, a0, 4	# a2: n >> 4
	add	a1, a2, a1	# a1: q = (n >> 2) + (n >> 4)
	srli	a2, a1, 4	# a2: q >> 4
	add	a1, a2, a1	# a1: q = q + (q >> 4)
	srli	a2, a1, 8	# a2: q >> 8
	add	a1, a2, a1	# a1: q = q + (q >> 8)
	srli	a2, a1, 16	# a2: q >> 16
	add	a1, a2, a1	# a1: final q estimate

	slli	a2, a1, 1	# a2: q * 2
	add	a2, a2, a1	# a2: q * 3
	sub	a2, a0, a2	# a2: r = n - q * 3

	sltiu	a0, a2, 3	# a0 = 1 if r < 3, else 0
	xori	a0, a0, 1	# a0 = 0 if r < 3, else 1
	add	a0, a1, a0	# a0 = q + correction

.if CPU_BITS == 64
	slli	a0, a0, 32	# get rid of any sign extension
	srli	a0, a0, 32
.endif
	ret




.size divrem, .-divrem
