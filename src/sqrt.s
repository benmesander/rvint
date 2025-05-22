.include "config.s"

.globl isqrt

# compute the integer square root of an unsigned number
# a0 - input (n)
# a0 - output (root)
#
# Algorithm: Non-restoring binary square root (based on Hacker's Delight, Fig 11-2)
# This version avoids multiplication/division in the main loop for efficiency
# and is known to correctly compute floor(sqrt(N)).
isqrt:
	FRAME	4		# Frame for ra, s0, s1, s2 (4 words * CPU_BITS/8 bytes)
	PUSH	ra, 0		# Save return address
	PUSH	s0, 1		# s0 will store 'place' (the bit/place value)
	PUSH	s1, 2		# s1 will store 'root'
	PUSH	s2, 3		# s2 will store 'remainder' (initially n_original)

# Register usage for main state variables:
# s0: place (current bit value being tested, starts high, shifts right by 2)
# s1: root (result being built up)
# s2: remainder (starts as n_original, gets reduced)
#
# Temporary (caller-saved) registers used:
# t0: scratch, trial_value (root + place)
# t1: scratch, (place << 1)

	mv	s2, a0		# s2 = remainder = n_original (copy input n)
	li	s1, 0		# s1 = root = 0

	# Initialize 'place' (s0) to the highest power of 4 (1 << (CPU_BITS - 2))
	# This corresponds to the (CPU_BITS/2 - 1)-th bit pair.
	li	s0, 1
.if CPU_BITS == 64
	slli	s0, s0, 62	# place = 1 << 62
.else  # CPU_BITS == 32
	slli	s0, s0, 30	# place = 1 << 30
.endif

# Adjust 'place' (s0) so that it's the largest power of 4 less than or equal to remainder (s2)
isqrt_adjust_place_loop:
	beqz	s0, isqrt_main_loop_entry # If place becomes 0, proceed (handles n=0,1)
	bltu	s2, s0, isqrt_place_too_large # If remainder < place, then place is too large
	j	isqrt_main_loop	# Place is okay or smaller

isqrt_place_too_large:
	srli	s0, s0, 2	# place >>= 2
	j	isqrt_adjust_place_loop

	# Main loop: while place (s0) > 0
isqrt_main_loop:
	beqz	s0, isqrt_done	# If place is 0, we are done

	add	t0, s1, s0	# t0 = trial_value = root + place
	bltu	s2, t0, isqrt_skip_subtraction # If remainder < trial_value, skip subtraction
	# Path where remainder >= trial_value:
	sub	s2, s2, t0	# remainder -= trial_value
	slli	t1, s0, 1	# t1 = place << 1 (which is 2 * place)
	add	s1, s1, t1	# root += (place << 1)
isqrt_skip_subtraction:
	srli	s1, s1, 1	# root >>= 1
	srli	s0, s0, 2	# place >>= 2
	j	isqrt_main_loop

isqrt_done:
	mv	a0, s1		# Final result is in root (s1)

isqrt_cleanup: # Common cleanup path
	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	POP	s2, 3
	EFRAME 4
	ret

.size isqrt, .-isqrt
