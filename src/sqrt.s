.include "config.s"

.globl isqrt

.text
################################################################################
# routine: isqrt
#
# Compute floor(sqrt(N)) using a binary non-restoring algorithm.
# RV32E compatible.
#
# input:  a0 = n
# output: a0 = root
################################################################################
isqrt:
	# a0: remainder (n)
	# a1: scratch / trial
	# a2: scratch
	# a3: place
	# a4: root

	li	a4, 0		# root = 0
	beqz	a0, isqrt_cleanup # Quick exit for 0

	# Initialize 'place' (a3)
	# We want the highest power of 4 that is <= n.

.if HAS_ZBB
	# Optimization: Use Count Leading Zeros to find MSB
	# If n has L leading zeros, the MSB index is (BITS - 1 - L).
	# We want 'place' to be an even power of 2 near that MSB.
	
	clz	a3, a0		# a3 = Leading Zeros (L)
	li	a2, CPU_BITS - 1
	sub	a3, a2, a3	# a3 = MSB_Index = (BITS - 1) - L
	
	# Align to even boundary (clear bit 0) to ensure power of 4
	# place = 1 << (index & ~1)
	andi	a3, a3, -2	# Align down to even
	li	a2, 1
	sll	a3, a2, a3	# place = 1 << index
	
	# Fall through to main loop directly
	j	isqrt_main_loop
.else
	# Standard: Start at max power of 4 and shift down
	li	a3, 1
.if CPU_BITS == 64
	slli	a3, a3, 62
.else	# CPU_BITS == 32
	slli	a3, a3, 30
.endif

# Adjust 'place' down until place <= n
isqrt_adjust_place_loop:
	# Note: bltu is unsigned compare.
	# If place > n, shift down.
	bltu	a0, a3, isqrt_shift_place
	j	isqrt_main_loop

isqrt_shift_place:
	srli	a3, a3, 2
	bnez	a3, isqrt_adjust_place_loop
	# If place becomes 0 (n=0), handled by initial beqz check or loop logic
.endif

	# Main digit-by-digit loop
isqrt_main_loop:
	beqz	a3, isqrt_done

	add	a1, a4, a3	# trial = root + place
	
	# If remainder (a0) >= trial (a1):
	bltu	a0, a1, isqrt_next_iter
	
	sub	a0, a0, a1	# remainder -= trial
	slli	a2, a3, 1	# a2 = place * 2
	add	a4, a4, a2	# root += place * 2

isqrt_next_iter:
	srli	a4, a4, 1	# root >>= 1
	srli	a3, a3, 2	# place >>= 2
	j	isqrt_main_loop

isqrt_done:
	mv	a0, a4		# result = root

isqrt_cleanup:
	ret
.size isqrt, .-isqrt
