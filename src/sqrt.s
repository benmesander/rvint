.include "config.s"

.globl isqrt

# compute the integer square root of an unsigned number
# a0 - input (n)
# a0 - output (root)
#
# Algorithm: Digit-by-digit restoring binary square root.
# This version avoids multiplication in the main loop for efficiency.
isqrt:
	FRAME	4		# Frame for ra, s0, s1, s2 (4 words * CPU_BITS/8 bytes)
	PUSH	ra, 0		# Save return address
	PUSH	s0, 1		# s0 will store shift_for_n
	PUSH	s1, 2		# s1 will store root
	PUSH 	s2, 3		# s2 will store n_original
	# Register usage for main state variables:
	# s0: shift_for_n (iterator, from CPU_BITS-2 down to -2 for loop termination)
	# s1: root (result being built up)
	# s2: n_original (the input number n)
	#
	# Temporary (caller-saved) registers used:
	# t3: remainder_working
	# t0: scratch_register (for bit pairs and trial_subtractor)

	mv	s2, a0		# s2 = n_original (copy input n)
	li	s1, 0		# s1 = root = 0
	li	t3, 0		# t3 = remainder_working = 0

	li	s0, CPU_BITS-2	# Initial shift_for_n for n[63:62] or n[31:30]

isqrt_digit_loop:
	# Loop while shift_for_n (s0) >= 0.
	# The loop terminates when s0 becomes -2 (after processing the n[1:0] pair).
	bltz	s0, isqrt_done  

	# remainder_working = (remainder_working << 2)
	slli	t3, t3, 2

	# Extract the next two bits from n_original (s2) using shift_for_n (s0)
	# current_pair_of_n_bits = (n_original >> shift_for_n) & 0x3
	srl	t0, s2, s0	# t0 = n_original (s2) >> shift_for_n (s0)
	andi	t0, t0, 0x3	# t0 = current pair of bits from n (n[s0+1 : s0])
	
	# Add current_pair_of_n_bits to remainder_working
	# remainder_working |= current_pair_of_n_bits
	or	t3, t3, t0      

	# Shift current_root (s1) left by 1 to make space for the bit being determined
	slli	s1, s1, 1

	# Form the trial_subtractor.
	# If the new root bit were 1, the part of the root already formed (s1, now shifted)
	# would be (root_so_far << 1). The trial_subtractor is (root_so_far << 1) | 1.
	# Since s1 currently holds (root_so_far << 1), trial_subtractor is (s1 | 1).
	ori	t0, s1, 1       # t0 = trial_subtractor

	# if (remainder_working >= trial_subtractor)
	bltu	t3, t0, isqrt_skip_subtraction # If remainder < trial_subtractor, skip
	# Path where current root bit is 1:
	sub	t3, t3, t0	# remainder_working = remainder_working - trial_subtractor
	ori	s1, s1, 1	# Set current bit of root (s1) to 1
isqrt_skip_subtraction:
	# If remainder_working < trial_subtractor, the current bit of root remains 0.
	# (s1 already reflects this due to the earlier "slli s1, s1, 1" and no "ori s1, s1, 1" on this path).

	addi	s0, s0, -2	# Decrement shift_for_n to process the next lower pair of bits
	j	isqrt_digit_loop

isqrt_done:
	mv	a0, s1		# Final result is in root (s1)

isqrt_cleanup:			# Common cleanup path
	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	POP	s2, 3
	EFRAME	4		# Match FRAME 4 (deallocate 4 words)
	ret

.size isqrt, .-isqrt
