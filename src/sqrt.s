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
# Register usage
# a1: scratch, trial_value (root + place)
# a2: scratch, (place << 1)
# a3: place (current bit value being tested, starts high, shifts right by 2)
# a4: root (result being built up)
# a0: remainder (starts as n_original, gets reduced)

	li	a4, 0		# a4 = root = 0

	# Initialize 'place' (a3) to the highest power of 4 (1 << (CPU_BITS - 2))
	# This corresponds to the (CPU_BITS/2 - 1)-th bit pair.
	li	a3, 1
.if CPU_BITS == 64
	slli	a3, a3, 62	# place = 1 << 62
.else  # CPU_BITS == 32
	slli	a3, a3, 30	# place = 1 << 30
.endif

# Adjust 'place' (a3) so that it's the largest power of 4 less than or equal to remainder (a0)
isqrt_adjust_place_loop:
	beqz	a3, isqrt_main_loop # If place becomes 0, proceed (handles n=0,1)
	bltu	a0, a3, isqrt_place_too_large # If remainder < place, then place is too large
	j	isqrt_main_loop	# Place is okay or smaller

isqrt_place_too_large:
	srli	a3, a3, 2	# place >>= 2
	j	isqrt_adjust_place_loop

	# Main loop: while place (a3) > 0
isqrt_main_loop:
	beqz	a3, isqrt_done	# If place is 0, we are done

	add	a1, a4, a3	# a1 = trial_value = root + place
	bltu	a0, a1, isqrt_skip_subtraction # If remainder < trial_value, skip subtraction
	# Path where remainder >= trial_value:
	sub	a0, a0, a1	# remainder -= trial_value
	slli	a2, a3, 1	# a2 = place << 1 (which is 2 * place)
	add	a4, a4, a2	# root += (place << 1)
isqrt_skip_subtraction:
	srli	a4, a4, 1	# root >>= 1
	srli	a3, a3, 2	# place >>= 2
	j	isqrt_main_loop

isqrt_done:
	mv	a0, a4		# Final result is in root (a4)

isqrt_cleanup:
	ret

.size isqrt, .-isqrt
