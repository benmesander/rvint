.include "config.s"

.globl isqrt

.text

################################################################################
# routine: isqrt
#
# Compute the integer square root of an unsigned number - floor(sqrt(N)).
# Algorithm: Non-restoring binary square root. On 64-bit processors this is
# a 64-bit algorithm, on 32-bit, it is 32-bits.
#
# input registers:
# a0 = n
# output registers:
# a0 = root - isqrt(n)
################################################################################
	
isqrt:
# Register usage for main state variables:
# t4: place (current bit value being tested, starts high, shifts right by 2)
# t3: root (result being built up)
# a0: remainder (starts as n_original, gets reduced)
#
# Temporary (caller-saved) registers used:
# t0: scratch, trial_value (root + place)
# t1: scratch, (place << 1)

	li	t3, 0		# t3 = root = 0

	# Initialize 'place' (t4) to the highest power of 4 (1 << (CPU_BITS - 2))
	# This corresponds to the (CPU_BITS/2 - 1)-th bit pair.
	li	t4, 1
.if CPU_BITS == 64
	slli	t4, t4, 62	# place = 1 << 62
.else  # CPU_BITS == 32
	slli	t4, t4, 30	# place = 1 << 30
.endif

# Adjust 'place' (t4) so that it's the largest power of 4 less than or equal to remainder (a0)
isqrt_adjust_place_loop:
	beqz	t4, isqrt_main_loop # If place becomes 0, proceed (handles n=0,1)
	bltu	a0, t4, isqrt_place_too_large # If remainder < place, then place is too large
	j	isqrt_main_loop	# Place is okay or smaller

isqrt_place_too_large:
	srli	t4, t4, 2	# place >>= 2
	j	isqrt_adjust_place_loop

	# Main loop: while place (t4) > 0
isqrt_main_loop:
	beqz	t4, isqrt_done	# If place is 0, we are done

	add	t0, t3, t4	# t0 = trial_value = root + place
	bltu	a0, t0, isqrt_skip_subtraction # If remainder < trial_value, skip subtraction
	# Path where remainder >= trial_value:
	sub	a0, a0, t0	# remainder -= trial_value
	slli	t1, t4, 1	# t1 = place << 1 (which is 2 * place)
	add	t3, t3, t1	# root += (place << 1)
isqrt_skip_subtraction:
	srli	t3, t3, 1	# root >>= 1
	srli	t4, t4, 2	# place >>= 2
	j	isqrt_main_loop

isqrt_done:
	mv	a0, t3		# Final result is in root (t3)

isqrt_cleanup:
	ret

.size isqrt, .-isqrt
