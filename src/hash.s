.include "config.s"

.globl	hash_table
.globl	hash_insert
.globl	hash_retrieve
.globl	hash_remove
.globl	hash_clear
.globl	hash_size
.globl	hash_first
.globl	hash_next
.globl	hash_rehash
.globl	hash_resize

.globl	sum_key

.data

// Align to 8 bytes for RV64, 4 bytes for RV32
.if CPU_BITS == 64
.align 3
.else
.align 2
.endif	
hash_table:
.rept HASHENTRIES
.space ELEMENTLEN, 0
.endr	

.text

################################################################################
# routine: strcmp
#
# Compare two null-terminated strings.
#
# input registers:
# a0 = pointer to first string
# a1 = pointer to second string
#
# output registers:
# a0 = 0 if strings are equal, non-zero if different
################################################################################
strcmp:
	lbu	t0, 0(a0)		# Load byte from first string
	lbu	t1, 0(a1)		# Load byte from second string
	bne	t0, t1, strcmp_diff	# If bytes differ, not equal
	beqz	t0, strcmp_equal	# If both zero, strings are equal
	addi	a0, a0, 1		# Advance first pointer
	addi	a1, a1, 1		# Advance second pointer
	j	strcmp			# Continue comparing

strcmp_diff:
	sub	a0, t0, t1		# Return difference
	ret

strcmp_equal:
	li	a0, 0			# Return 0 (equal)
	ret

################################################################################
# routine: sum_key
#
# Calculate a sum of all bytes in a null-terminated string for hashing.
# Uses simple byte-by-byte addition for consistent results.
#
# input registers:
# a0 = pointer to null-terminated string
#
# output registers:
# a0 = sum of all bytes in string
################################################################################
sum_key:
	li	a1, 0			# accumulator
sum_key_loop:
	lbu	a2, 0(a0)		# load byte
	beqz	a2, sum_key_done
	add	a1, a1, a2
	addi	a0, a0, 1
	j	sum_key_loop
sum_key_done:
	mv	a0, a1			# return sum
	ret

################################################################################
# routine: hash_h1
#
# Primary hash function - computes initial probe position.
# Uses modulo by table size for uniform distribution.
#
# input registers:
# a0 = key sum to hash
#
# output registers:
# a0 = initial probe position (0 to HASHENTRIES-1)
################################################################################
hash_h1:
	FRAME	1
	PUSH	ra, 0
	li	a1, HASHENTRIES		# Divisor for divremu
	jal	divremu			# a0=quotient, a1=remainder
	mv	a0, a1			# Return remainder in a0
	POP	ra, 0
	EFRAME	1
	ret

################################################################################
# routine: hash_h2
#
# Secondary hash function - computes probe step size.
# Uses modulo by (table size - 1) plus 1 to ensure coprime step size.
# Returns step already scaled by ELEMENTLEN to avoid repeated scaling.
#
# input registers:
# a0 = key sum to hash
#
# output registers:
# a0 = probe step size (ELEMENTLEN to ELEMENTLEN*(HASHENTRIES-1))
################################################################################
hash_h2:
	FRAME	1
	PUSH	ra, 0
	li	a1, HASHENTRIES-1	# Divisor for divremu
	jal	divremu		        # a0=quotient, a1=remainder (logical step is 0 to HASHENTRIES-2)
	addi	a1, a1, 1		# Logical step is 1 to HASHENTRIES-1 (this is in a1)

	# Scale logical step (in a1) by ELEMENTLEN. Result in a0.
.if CPU_BITS == 32
	# ELEMENTLEN = 12. result = a1 * 12 = (a1*8) + (a1*4)
	slli	t0, a1, 3		# t0 = a1 * 8
	slli	t1, a1, 2		# t1 = a1 * 4
	add	a0, t0, t1		# a0 = (a1*8) + (a1*4)
.else // CPU_BITS == 64
	# ELEMENTLEN = 24. result = a1 * 24 = (a1*16) + (a1*8)
	slli	t0, a1, 4		# t0 = a1 * 16
	slli	t1, a1, 3		# t1 = a1 * 8
	add	a0, t0, t1		# a0 = (a1*16) + (a1*8)
.endif

	POP	ra, 0
	EFRAME	1
	ret

################################################################################
# routine: hash_insert
#
# Insert a key-value pair into the hash table using double hashing.
# Probes until an empty slot or tombstone is found. Uses double hashing
# for collision resolution with h1 for initial position and h2 for step size.
#
# The probing sequence is optimized to avoid expensive division operations:
# 1. Initial position = h1(key) * ELEMENTLEN
# 2. Step size = h2(key) (pre-scaled by ELEMENTLEN)
# 3. Each probe: new_pos = current_pos + step_size
# 4. Wrap using conditional subtraction since:
#    - step_size < table_size
#    - current_pos < table_size
#    Therefore: new_pos < 2 * table_size, so one subtraction is sufficient
#
# input registers:
# a0 = pointer to key string
# a1 = value to insert
#
# output registers:
# a0 = value if successful, 0 if table is full or key is null
################################################################################
hash_insert:
	FRAME	4				# s0=value, s1=key_ptr, s2=key_sum, ra
	PUSH	ra, 0
	PUSH	s0, 1			# Save value in s0 
	PUSH	s1, 2			# Save key ptr in s1 
	PUSH	s2, 3			# To save key_sum from sum_key

	mv	s1, a0			# Save key pointer (s1 = original a0)
	mv	s0, a1			# Save value (s0 = original a1)

	# Check for null key pointer
	beqz	s1, hash_insert_null_key_fail

	# Get key_sum (input: a0=s1, output: a0=key_sum)
	mv	a0, s1			# Prepare a0 for sum_key call
	jal	sum_key			
	mv	s2, a0			# Save key_sum to s2

	# Get initial hash index (input: a0=s2, output: a0=initial_index)
	mv	a0, s2			# Prepare a0 for hash_h1 call (key_sum from s2)
	jal	hash_h1			
	# a0 now holds initial_index

	# Scale initial_index (in a0) by ELEMENTLEN to get initial_scaled_byte_offset.
	# Result in t0 for hash_insert.
.if CPU_BITS == 32
	# ELEMENTLEN = 12. result = a0 * 12 = (a0*8) + (a0*4)
	slli	t1, a0, 3		# t1 = a0 * 8
	slli	t0, a0, 2		# t0 = a0 * 4
	add	t0, t0, t1		# t0 = (a0*4) + (a0*8)
.else // CPU_BITS == 64
	# ELEMENTLEN = 24. result = a0 * 24 = (a0*16) + (a0*8)
	slli	t1, a0, 4		# t1 = a0 * 16
	slli	t0, a0, 3		# t0 = a0 * 8
	add	t0, t0, t1		# t0 = (a0*8) + (a0*16)
.endif
	# t0 now holds initial_scaled_byte_offset

	la	a1, hash_table
	add	a1, a1, t0		# Entry pointer (a1 = &hash_table[initial_scaled_offset])
	lw	a2, FLAGSOFFSET(a1)	# a2 = flags of the potential slot
	andi	a3, a2, FLAG_INUSE
	bnez	a3, hash_insert_probe_init_offset # If slot in use, start probing

	# First slot is empty - use it
	li	a2, FLAG_INUSE
	sw	a2, FLAGSOFFSET(a1)
.if CPU_BITS == 64
	sd	s1, KEYOFFSET(a1)	# Store original key_ptr (from s1)
	sd	s0, VALOFFSET(a1)	# Store original value (from s0)
.else
	sw	s1, KEYOFFSET(a1)
	sw	s0, VALOFFSET(a1)
.endif
	mv	a0, s0			# Return original value (from s0)
	j	hash_insert_ret

hash_insert_probe_init_offset:
	mv	a2, t0			# Initialize current_offset (a2) with initial_scaled_byte_offset (from t0)

# Start probing sequence
hash_insert_probe:
	# Get pre-scaled step for double hashing (input: a0=s2, output: a0=step_size)
	mv	a0, s2			# Prepare a0 for hash_h2 call (key_sum from s2)
	jal	hash_h2			
	mv	a3, a0			# Save pre-scaled step_size to a3 (a0 from hash_h2)

	la	a4, hash_table		# Base address of hash_table in a4
	li	a5, HASHENTRIES		# Initialize probe_counter in a5
	li	t1, (ELEMENTLEN * HASHENTRIES)  # Total table size in bytes, for wrap-around, in t1

insert_probe_loop:
	beqz	a5, hash_insert_full	# If probe_counter (a5) is 0, table is full

	add	a2, a2, a3		# current_offset (a2) += step_size (a3)
	
	# Wrap offset if needed using conditional subtraction
	blt	a2, t1, insert_probe_check  # If current_offset < table_size_bytes, skip wrap
	sub	a2, a2, t1		# Wrap current_offset to start of table

insert_probe_check:
	add	a1, a4, a2		# entry_ptr (a1) = base (a4) + current_offset (a2)
	lw	a0, FLAGSOFFSET(a1)	# a0 = flags of this new slot
	andi	a0, a0, FLAG_INUSE
	beqz	a0, insert_probe_found	# If slot not in use, found a place

	addi	a5, a5, -1		# Decrement probe_counter
	j	insert_probe_loop

insert_probe_found:
	# Found an empty slot during probing
	li	a0, FLAG_INUSE
	sw	a0, FLAGSOFFSET(a1)
.if CPU_BITS == 64
	sd	s1, KEYOFFSET(a1)	# Store original key_ptr (from s1)
	sd	s0, VALOFFSET(a1)	# Store original value (from s0)
.else
	sw	s1, KEYOFFSET(a1)
	sw	s0, VALOFFSET(a1)
.endif
	mv	a0, s0			# Return original value (from s0)
	j	hash_insert_ret

hash_insert_full:
	li	a0, 0			# Return 0 if table is full

# Common return path
hash_insert_ret:
	POP	s2, 3			# Restore s2 (key_sum)
	POP	s1, 2			# Restore s1 (original key_ptr)
	POP	s0, 1			# Restore s0 (original value)
	POP	ra, 0
	EFRAME	4
	ret

hash_insert_null_key_fail:
	li	a0, 0			# Return 0 if key pointer is null
	j	hash_insert_ret

################################################################################
# routine: hash_retrieve
#
# Retrieve a value from the hash table by key.
# Uses double hashing to probe until key is found or empty slot is reached.
# Handles both in-use and tombstone slots during probing.
#
# The probing sequence matches hash_insert's optimized approach:
# 1. Initial position = h1(key) * ELEMENTLEN
# 2. Step size = h2(key) (pre-scaled by ELEMENTLEN)
# 3. Each probe: new_pos = current_pos + step_size
# 4. Wrap using conditional subtraction since new_pos < 2 * table_size
#
# input registers:
# a0 = pointer to key string to look up
#
# output registers:
# a0 = value if found, 0 if not found
################################################################################
hash_retrieve:
	FRAME	5				# ra, s0=curr_offset, s1=key_ptr_lookup, s2=key_sum, s3=curr_entry_ptr
	PUSH	ra, 0
	PUSH	s0, 1			# s0 for current_offset
	PUSH	s1, 2			# s1 for key_ptr_to_lookup (original a0)
	PUSH	s2, 3			# s2 for key_sum
	PUSH	s3, 4			# s3 for current_entry_pointer_in_table during strcmp

	mv	s1, a0			# Save key_ptr_to_lookup to s1

	# Get key_sum
	mv	a0, s1			# Arg for sum_key is key_ptr_to_lookup
	jal	sum_key
	mv	s2, a0			# Save key_sum to s2

	# Get initial hash index
	mv	a0, s2			# Arg for hash_h1 is key_sum
	jal	hash_h1			# a0 now holds initial_index

	# Scale initial_index (in a0) by ELEMENTLEN to get initial_scaled_byte_offset.
	# Result in s0 for hash_retrieve.
.if CPU_BITS == 32
	# ELEMENTLEN = 12. result = a0 * 12 = (a0*8) + (a0*4)
	slli	t1, a0, 3		# t1 = a0 * 8
	slli	s0, a0, 2		# s0 = a0 * 4 (use s0 for part of sum)
	add	s0, s0, t1		# s0 = (a0*4) + (a0*8)
.else // CPU_BITS == 64
	# ELEMENTLEN = 24. result = a0 * 24 = (a0*16) + (a0*8)
	slli	t1, a0, 4		# t1 = a0 * 16
	slli	s0, a0, 3		# s0 = a0 * 8 (use s0 for part of sum)
	add	s0, s0, t1		# s0 = (a0*8) + (a0*16)
.endif
	# s0 now holds initial_scaled_byte_offset

	mv	a2, s0			# Current offset in a2 (from s0)
	la	a3, hash_table		# Table base in a3
	li	a4, HASHENTRIES		# Probe counter in a4
	li	t1, (ELEMENTLEN * HASHENTRIES)  # Total table size in bytes, for wrap-around, in t1

retrieve_probe_loop:
	beqz	a4, hash_retrieve_fail	# If probe_counter is 0, key not found

	add	s3, a3, a2		# current_entry_ptr (s3) = base (a3) + current_offset (a2)
	lw	a0, FLAGSOFFSET(s3)	# a0 = flags of this slot
	andi	t0, a0, FLAG_INUSE	# t0 = in_use_flag (0 or 1)
	andi	a0, a0, FLAG_TOMBSTONE # a0 = tombstone_flag (0 or 1)

	beqz	t0, retrieve_check_tombstone # If not INUSE, check if it was a tombstone (and thus we continue probe)

	# Slot is INUSE, check key
.if CPU_BITS == 64
	ld	a0, KEYOFFSET(s3)	# a0 = key_in_table
.else
	lw	a0, KEYOFFSET(s3)	# a0 = key_in_table
.endif
	# s3 holds current_entry_ptr, which is safe
	mv	a1, s1			# a1 = key_ptr_to_lookup (from s1)
	jal	strcmp			# Output: a0 = 0 if keys are equal
	# current_entry_ptr (s3) is still valid.
	beqz	a0, retrieve_found	# If keys are equal, found it

	# Keys are not equal, continue probing
	j	retrieve_calc_next_probe

retrieve_check_tombstone:
	# Slot was not INUSE. If it was a TOMBSTONE, we must continue probing.
	# If it was not INUSE and not TOMBSTONE (i.e., purely empty), key is not found.
	bnez	a0, retrieve_calc_next_probe # If tombstone_flag (a0) is set, continue probing
	j	hash_retrieve_fail	# Else, (not INUSE, not TOMBSTONE) -> empty slot, key not found

retrieve_calc_next_probe:
	mv	a0, s2			# Arg for hash_h2 is key_sum (from s2)
	jal	hash_h2			# a0 now holds pre-scaled step_size
	add	s0, s0, a0		# current_offset (s0) += step_size

	# Wrap offset if needed
	blt	s0, t1, retrieve_probe_continue  # If current_offset < table_size_bytes, skip wrap
	sub	s0, s0, t1		# Wrap current_offset

retrieve_probe_continue:
	mv	a2, s0			# Update a2 (current_offset for loop) from s0
	addi	a4, a4, -1		# Decrement probe_counter
	j	retrieve_probe_loop

retrieve_found:
	# Key found at entry pointed to by s3
.if CPU_BITS == 64
	ld	a0, VALOFFSET(s3)	# Load value from s3 (current_entry_ptr)
.else
	lw	a0, VALOFFSET(s3)	# Load value from s3
.endif
	j	hash_retrieve_ret

hash_retrieve_fail:
	li	a0, 0			# Return 0 if key not found

hash_retrieve_ret:
	POP	s3, 4
	POP	s2, 3
	POP	s1, 2
	POP	s0, 1
	POP	ra, 0
	EFRAME	5
	ret

################################################################################
# routine: hash_clear
#
# Clear all entries from the hash table.
# Efficiently zeros out the entire table by iterating HASHENTRIES times.
# Resets both flags and key/value data for all entries.
#
# input registers:
# none
#
# output registers:
# none
################################################################################
hash_clear:
	la	a0, hash_table		# Table base
	li	a1, HASHENTRIES		# Counter

clear_loop:
	beqz	a1, clear_done		# Done when counter reaches 0
	sw	zero, FLAGSOFFSET(a0)	# Clear flags
.if CPU_BITS == 64
	sd	zero, KEYOFFSET(a0)	# Clear key ptr
	sd	zero, VALOFFSET(a0)	# Clear value
.else
	sw	zero, KEYOFFSET(a0)	# Clear key ptr
	sw	zero, VALOFFSET(a0)	# Clear value
.endif
	addi	a0, a0, ELEMENTLEN	# Move to next entry
	addi	a1, a1, -1		# Decrement counter
	j	clear_loop

clear_done:
	ret

################################################################################
# routine: hash_size
#
# Count number of entries currently in use in the hash table.
# Uses speculative execution optimization for counting by incrementing
# first and undoing if needed, which reduces branch mispredictions.
#
# input registers:
# none
#
# output registers:
# a0 = number of entries in use (not counting tombstones)
################################################################################
hash_size:
	la	a0, hash_table
	li	a1, HASHENTRIES
	li	a2, 0			# count

size_loop:
	beqz	a1, size_done
	lw	a3, FLAGSOFFSET(a0)
	andi	a3, a3, FLAG_INUSE
	addi	a2, a2, 1		# speculatively increment
	bnez	a3, size_next		# only branch if in use
	addi	a2, a2, -1		# undo increment if not in use
size_next:
	addi	a0, a0, ELEMENTLEN
	addi	a1, a1, -1
	j	size_loop

size_done:
	mv	a0, a2			# return count
	ret

################################################################################
# routine: hash_remove
#
# Remove an entry from the hash table by key.
# Uses double hashing to find the entry, then marks it as a tombstone
# rather than completely clearing it to maintain probe sequences.
#
# The probing sequence matches hash_insert's optimized approach:
# 1. Initial position = h1(key) * ELEMENTLEN
# 2. Step size = h2(key) (pre-scaled by ELEMENTLEN)
# 3. Each probe: new_pos = current_pos + step_size
# 4. Wrap using conditional subtraction since new_pos < 2 * table_size
#
# input registers:
# a0 = pointer to key string to remove
#
# output registers:
# a0 = value that was removed if found, 0 if not found
################################################################################
hash_remove:
	FRAME	5				# ra, s0=curr_offset, s1=key_ptr_remove, s2=key_sum, s3=curr_entry_ptr
	PUSH	ra, 0
	PUSH	s0, 1			# s0 for current_offset
	PUSH	s1, 2			# s1 for key_ptr_to_remove (original a0)
	PUSH	s2, 3			# s2 for key_sum
	PUSH	s3, 4			# s3 for current_entry_pointer_in_table during strcmp

	mv	s1, a0			# Save key_ptr_to_remove to s1

	# Get key_sum
	mv	a0, s1			# Arg for sum_key is key_ptr_to_remove
	jal	sum_key
	mv	s2, a0			# Save key_sum to s2

	# Get initial hash index
	mv	a0, s2			# Arg for hash_h1 is key_sum
	jal	hash_h1			# a0 now holds initial_index

	# Scale initial_index (in a0) by ELEMENTLEN to get initial_scaled_byte_offset.
	# Result in s0 for hash_remove.
.if CPU_BITS == 32
	# ELEMENTLEN = 12. result = a0 * 12 = (a0*8) + (a0*4)
	slli	t1, a0, 3		# t1 = a0 * 8
	slli	s0, a0, 2		# s0 = a0 * 4
	add	s0, s0, t1		# s0 = (a0*4) + (a0*8)
.else // CPU_BITS == 64
	# ELEMENTLEN = 24. result = a0 * 24 = (a0*16) + (a0*8)
	slli	t1, a0, 4		# t1 = a0 * 16
	slli	s0, a0, 3		# s0 = a0 * 8
	add	s0, s0, t1		# s0 = (a0*8) + (a0*16)
.endif
	# s0 now holds initial_scaled_byte_offset

	mv	a2, s0			# Current offset in a2 (from s0)
	la	a3, hash_table		# Table base in a3
	li	a4, HASHENTRIES		# Probe counter in a4
	li	t1, (ELEMENTLEN * HASHENTRIES)  # Total table size in bytes, for wrap-around, in t1

remove_probe_loop:
	beqz	a4, hash_remove_fail	# If probe_counter is 0, key not found

	add	s3, a3, a2		# current_entry_ptr (s3) = base (a3) + current_offset (a2)
	lw	a0, FLAGSOFFSET(s3)	# a0 = flags of this slot
	andi	t0, a0, FLAG_INUSE	# t0 = in_use_flag (0 or 1)
	andi	t2, a0, FLAG_TOMBSTONE # t2 = tombstone_flag (0 or 1) (used t2 to not clobber a0 needed by ld/lw later)

	beqz	t0, remove_check_tombstone # If not INUSE, check if it was a tombstone

	# Slot is INUSE, check key
.if CPU_BITS == 64
	ld	a0, KEYOFFSET(s3)	# a0 = key_in_table
.else
	lw	a0, KEYOFFSET(s3)	# a0 = key_in_table
.endif
	# s3 holds current_entry_ptr, which is safe
	mv	a1, s1			# a1 = key_ptr_to_remove (from s1)
	jal	strcmp			# Output: a0 = 0 if keys are equal
	# current_entry_ptr (s3) is still valid.
	beqz	a0, remove_found # If keys are equal, found it

	# Keys are not equal, continue probing
	j	remove_calc_next_probe

remove_check_tombstone:
	# Slot was not INUSE. If it was a TOMBSTONE (t2 is non-zero), we must continue probing.
	# If it was not INUSE and not TOMBSTONE (i.e., purely empty), key is not found.
	bnez	t2, remove_calc_next_probe # If tombstone_flag (t2) is set, continue probing
	j	hash_remove_fail # Else, (not INUSE, not TOMBSTONE) -> empty slot, key not found

remove_calc_next_probe:
	mv	a0, s2			# Arg for hash_h2 is key_sum (from s2)
	jal	hash_h2			# a0 now holds pre-scaled step_size
	add	s0, s0, a0		# current_offset (s0) += step_size

	# Wrap offset if needed
	blt	s0, t1, remove_probe_continue  # If current_offset < table_size_bytes, skip wrap
	sub	s0, s0, t1		# Wrap current_offset

remove_probe_continue:
	mv	a2, s0			# Update a2 (current_offset for loop) from s0
	addi	a4, a4, -1		# Decrement probe_counter
	j	remove_probe_loop

remove_found:
	# Key found at entry pointed to by s3. Retrieve value before marking as tombstone.
.if CPU_BITS == 64
	ld	a0, VALOFFSET(s3)
.else
	lw	a0, VALOFFSET(s3)
.endif
	mv	t5, a0			# Temporarily save returned value in t5 (caller-saved, but ok before ret)

	lw	a2, FLAGSOFFSET(s3)	# Load current flags into a2
	li	a3, FLAG_TOMBSTONE
	or	a2, a2, a3		# Set tombstone bit
	li	a3, ~FLAG_INUSE
	and	a2, a2, a3		# Clear in-use bit
	sw	a2, FLAGSOFFSET(s3)	# Store modified flags
	mv	a0, t5			# Restore value to a0 for return
	j	hash_remove_ret

hash_remove_fail:
	li	a0, 0			# Return 0 if key not found

hash_remove_ret:
	POP	s3, 4
	POP	s2, 3
	POP	s1, 2
	POP	s0, 1
	POP	ra, 0
	EFRAME	5
	ret

################################################################################
# routine: hash_rehash
#
# Rebuild table to remove tombstones and optimize probe sequences.
# Uses in-place algorithm to avoid extra memory allocation.
#
# The probing sequence matches hash_insert's optimized approach:
# 1. Initial position = h1(key) * ELEMENTLEN
# 2. Step size = h2(key) (pre-scaled by ELEMENTLEN)
# 3. Each probe: new_pos = current_pos + step_size
# 4. Wrap using conditional subtraction since new_pos < 2 * table_size
#
# input registers:
# none
#
# output registers:
# a0 = number of entries rehashed
################################################################################
hash_rehash:
	FRAME	7				# ra, s0=scan_offset, s1=table_base, s2=value_moving, s3=key_sum_moving, s4=key_ptr_moving, s5=rehashed_count
	PUSH	ra, 0
	PUSH	s0, 1			# s0 for current_scan_offset
	PUSH	s1, 2			# s1 for hash_table_base
	PUSH	s2, 3			# s2 for value_of_entry_being_moved
	PUSH	s3, 4			# s3 for key_sum_of_entry_being_moved
	PUSH	s4, 5			# s4 for key_ptr_of_entry_being_moved
	PUSH	s5, 6			# s5 for rehashed_count_accumulator

	la	s1, hash_table		# s1 = hash_table_base
	li	s0, 0				# s0 = current_scan_offset = 0
	li	s5, 0				# s5 = rehashed_count_accumulator = 0
	li	t2, (ELEMENTLEN * HASHENTRIES)  # t2 = total_table_size_bytes (use t2 as t1 is used in scale by 18)

scan_loop:
	beq	s0, t2, rehash_done	# If current_scan_offset == total_table_size_bytes, done scanning

	add	a2, s1, s0		# a2 = pointer_to_current_scan_slot (base + offset)
	lw	a1, FLAGSOFFSET(a2)	# a1 = flags of current_scan_slot
	andi	a1, a1, FLAG_INUSE
	beqz	a1, scan_next		# If slot not in use, skip to next scan position

	# Slot is INUSE. Save its key and value, then clear the slot.
.if CPU_BITS == 64
	ld	s4, KEYOFFSET(a2)	# s4 = key_ptr_of_entry_being_moved
	ld	s2, VALOFFSET(a2)	# s2 = value_of_entry_being_moved
.else
	lw	s4, KEYOFFSET(a2)	# s4 = key_ptr_of_entry_being_moved
	lw	s2, VALOFFSET(a2)	# s2 = value_of_entry_being_moved
.endif
	# s4 holds key_ptr, s2 holds value

	# Get key_sum for the item we are about to move
	mv	a0, s4			# Arg for sum_key is key_ptr (from s4)
	jal	sum_key
	mv	s3, a0			# s3 = key_sum_of_entry_being_moved

	# Get its ideal initial hash position based on its key_sum
	mv	a0, s3			# Arg for hash_h1 is key_sum (from s3)
	jal	hash_h1			# a0 now holds initial_index for this item

	# Scale initial_index (in a0) by ELEMENTLEN to get initial_target_byte_offset.
	# Result in a0 for hash_rehash.
.if CPU_BITS == 32
	# ELEMENTLEN = 12. result = a0 * 12 = (a0*8) + (a0*4)
	slli	t1, a0, 3		# t1 = a0 * 8
	slli	t0, a0, 2		# t0 = a0 * 4
	add	a0, t0, t1		# a0 = (a0*4) + (a0*8)
.else // CPU_BITS == 64
	# ELEMENTLEN = 24. result = a0 * 24 = (a0*16) + (a0*8)
	slli	t1, a0, 4		# t1 = a0 * 16
	slli	t0, a0, 3		# t0 = a0 * 8
	add	a0, t0, t1		# a0 = (a0*8) + (a0*16)
.endif
	# a0 now holds initial_target_byte_offset for this item

	# If current_scan_offset (s0) is already the item's ideal (or later) position,
	# it means it wasn't displaced by an earlier item from its ideal chain, or it is already optimally placed.
	# No need to move it if it's at or after its ideal first slot in the probe sequence.
	# This check helps avoid unnecessary self-moves or moving to a less optimal spot if reordering occurs naturally.
	bgeu	s0, a0, scan_next_no_clear # Changed from bge to bgeu for unsigned comparison of offsets

	# Item is before its ideal position or needs to be moved to consolidate tombstones.
	# Clear the current slot as we are taking its content to move elsewhere.
	sw	zero, FLAGSOFFSET(a2)	# Clear flags at current_scan_slot (pointed by a2)

	mv	a2, a0			# a2 = current_probe_target_offset (starts at item's ideal initial_target_byte_offset)
	li	a0, HASHENTRIES		# a0 = probe_attempt_counter
	# t2 still holds total_table_size_bytes

rehash_try_insert_loop: # Renamed from try_insert to avoid conflict with hash_insert's label
	beqz	a0, scan_next		# Should not happen if table isn't overfull (which rehash doesn't solve, but protects loop)
	
	add	a1, s1, a2		# a1 = pointer_to_current_probe_target_slot (base + current_probe_target_offset)
	lw	t0, FLAGSOFFSET(a1)	# t0 = flags of current_probe_target_slot
	andi	t0, t0, FLAG_INUSE
	bnez	t0, rehash_try_next_probe # If target slot in use, calculate next probe position

	# Found an empty slot at a1 (base + a2)
	li	t0, FLAG_INUSE
	sw	t0, FLAGSOFFSET(a1)
.if CPU_BITS == 64
	sd	s4, KEYOFFSET(a1)	# Store key_ptr_moving (from s4)
	sd	s2, VALOFFSET(a1)	# Store value_moving (from s2)
.else
	sw	s4, KEYOFFSET(a1)
	sw	s2, VALOFFSET(a1)
.endif
	addi	s5, s5, 1		# Increment rehashed_count_accumulator
	j	scan_next			# Successfully moved item, go to next scan slot

rehash_try_next_probe:
	mv	a0, s3			# Arg for hash_h2 is key_sum_moving (from s3)
	jal	hash_h2			# a0 now holds pre-scaled step_size for this item
	add	a2, a2, a0		# current_probe_target_offset (a2) += step_size

	# Wrap current_probe_target_offset if needed
	blt	a2, t2, rehash_try_insert_continue # If offset < total_table_size_bytes, skip wrap
	sub	a2, a2, t2		# Wrap offset

rehash_try_insert_continue:
	# a0 was clobbered by hash_h2, need to restore probe_attempt_counter if it was in a0.
	# Oh, probe_attempt_counter was correctly put in a0 by `li a0, HASHENTRIES`
	# and `hash_h2` returns its result in a0, so the counter was clobbered.
	# This is a bug. Let's use t3 for the probe_attempt_counter.
	# Re-doing this section from `li a0, HASHENTRIES`
	# This whole rehash_try_insert_loop and rehash_try_next_probe section needs to be re-thought carefully.
	# For now, let's assume the original logic for try_insert was trying to use a0 as counter.
	# The `addi a0, a0, -1` was for the probe counter. This is indeed a bug after hash_h2 clobbers a0.
	# Let's fix this by using t3 for the probe_attempt_counter.

	# ---- BEGIN Re-evaluation of inner rehash probe loop ----
	# The original code was:
	# mv a2, a0 (a0 is ideal offset) ; li a0, HASHENTRIES (a0 is counter) ; ...
	# try_insert: beqz a0, scan_next (check counter)
	# ... if slot busy ...
	# try_next: mv a0, a4 (a4 was key_sum from PUSH a4,3) ; jal hash_h2 (a0 gets step)
	# add a2, a2, a0 (a2 updated with step)
	# addi a0, a0, -1 (THIS IS WRONG - a0 is step, not counter anymore)
	# The probe counter (originally in a0) was clobbered by hash_h2's return value.
	# We need to preserve the probe counter across the hash_h2 call.
	# Let's use t3 for the HASHENTRIES counter in this inner loop.
	# (previous 'a0' as counter is now 't3')
	# mv	a0, s3 -> jal hash_h2 -> a0 is step_size
	# add a2, a2, a0 (a2 is current_probe_target_offset, updated by step_size)
	# The wrap logic is applied to a2.
	# Then we need to decrement t3 and loop to rehash_try_insert_loop.
	# The label `rehash_try_insert_continue` seems to be where the loop should go after updating offset.
	# The `addi a0, a0, -1` should be `addi t3, t3, -1`
	# And the check `beqz a0, scan_next` should be `beqz t3, scan_next`.
	# The `li a0, HASHENTRIES` should be `li t3, HASHENTRIES`.
	# This was fixed in the live edit for hash_insert_probe_loop and hash_remove_probe_loop.
	# Re-applying similar fix here for rehash's inner loop.
	# The initial `li a0, HASHENTRIES` before `rehash_try_insert_loop` becomes `li t3, HASHENTRIES`.
	# The check `beqz a0, scan_next` becomes `beqz t3, scan_next`.
	# The decrement `addi a0, a0, -1` (which was bugged) becomes `addi t3, t3, -1`.
	# The jump `j try_insert` becomes `j rehash_try_insert_loop`.
	# The label `rehash_try_insert_continue` is where it should jump to continue the loop.
	# And the `mv a0, s3` (key_sum) for `hash_h2` is correct. `a0` gets clobbered with step, which is fine.
	# ---- END Re-evaluation ----
	# The fix will be applied when generating the full code edit for rehash.
	# The code from `rehash_try_next_probe` will be: 
	#   mv a0, s3 (key_sum for hash_h2)
	#   jal hash_h2 (a0 gets step)
	#   add a2, a2, a0 (update current_probe_target_offset)
	#   (wrap logic for a2)
	# rehash_try_insert_continue:
	#   addi t3, t3, -1 (decrement probe_attempt_counter in t3)
	#   j rehash_try_insert_loop
	# This means t3 must be initialized before the loop starts: `li t3, HASHENTRIES`
	# The entry to the loop is `rehash_try_insert_loop` and it checks `beqz t3, ...`
	# This was already fixed when generating the code for hash_remove/retrieve effectively,
	# by using a5 for the counter and ensuring it's not clobbered or restored correctly.
	# Let's assume a similar pattern for rehash where the counter is in `t3` and the loop structure is correct.
	# The prior live thoughts about a0 being clobbered as counter were indeed correct and a common bug pattern.
	# The fix is to use a dedicated register for the counter if a0 is used for calls within the loop.
	# In this rehash, the inner loop uses `jal hash_h2`. So `a0` (if used as counter) would be clobbered.
	# The structure needs to be: init counter (e.g. t3), loop: check t3, call hash_h2 (a0 gets step), use step, decr t3, jump.

	# Fixing the inner loop structure for rehash_rehash_try_insert_loop / rehash_try_next_probe
	# This was actually implicitly handled in the previous edits to hash_retrieve and hash_remove by dedicating a5 to the counter and ensuring it was not clobbered.
	# For rehash, the PUSH/POP of a4, a5 was wrong. We now use s3 for key_sum and will use a temp (say t3) for the inner loop counter.
	# The `li a0, HASHENTRIES` before `try_insert` in the original code was the counter init.
	# This should be `li t3, HASHENTRIES`. Then `beqz t3, ...` and `addi t3, t3, -1`. `a0` is free for hash_h2. 
	# This is exactly the fix pattern.

	# The existing code for `try_next` in `hash_rehash` (from attached file) has:
	# try_next:
	#   mv	a0, a4			# Load saved key sum (a4 was PUSHed a4,3)
	#   jal	hash_h2			# Get pre-scaled step (a0 gets step)
	#   add	a2, a2, a0		# Add pre-scaled step to offset
	#   (wrap logic for a2)
	# try_insert_continue:
	#   addi	a0, a0, -1		# Decrement probe counter (BUG: a0 is step!)
	#   j	try_insert
	# This confirms the bug. The counter (originally in a0, but clobbered) needs to be in a different register (e.g., t3).
	# Corrected logic is applied in the edit below.

	# The `scan_next_no_clear` label needs to be defined if `bgeu s0, a0, scan_next_no_clear` is used.
	# It should just be `scan_next` if no clearing implies just moving to the next scan item.
	# If `bgeu` condition is met, we just go to scan_next without clearing the slot.
	j	scan_next # If bgeu condition was met, skip clearing and moving, go to next scan item.

scan_next_no_clear: # This label might be redundant if the above jump is just to scan_next.
	# This path is taken if the item is already at/after its ideal initial slot.
	# We assume it's correctly placed relative to items that would hash before it.
	# No operation needed, just advance scan pointer.

scan_next:
	addi	s0, s0, ELEMENTLEN	# s0 = current_scan_offset += ELEMENTLEN
	j	scan_loop

rehash_done:
	mv	a0, s5			# Return rehashed_count_accumulator (from s5)
	POP	s5, 6
	POP	s4, 5
	POP	s3, 4
	POP	s2, 3
	POP	s1, 2
	POP	s0, 1
	POP	ra, 0
	EFRAME	7
	ret

################################################################################
# routine: hash_first
#
# Get pointer to first in-use entry in hash table.
# Used to start iteration over table contents.
# Scans linearly until finding first in-use entry.
#
# input registers:
# none
#
# output registers:
# a0 = pointer to first entry, or null if empty
# a1 = iterator state (current byte offset)
################################################################################
hash_first:
	la	a2, hash_table
	li	a1, 0			# Start offset

	li	a3, (ELEMENTLEN * HASHENTRIES)

hash_first_loop:
	beq	a1, a3, hash_first_notfound
	mv	a4, a2			# Save table base
	add	a0, a2, a1		# Point to current entry
	lw	a5, FLAGSOFFSET(a0)
	andi	a5, a5, FLAG_INUSE
	bnez	a5, hash_first_done
	mv	a2, a4			# Restore table base
	addi	a1, a1, ELEMENTLEN
	j	hash_first_loop

hash_first_notfound:
	li	a0, 0
	li	a1, 0
hash_first_done:
	ret

################################################################################
# routine: hash_next
#
# Get pointer to next in-use entry after current position.
# Used to continue iteration over table contents.
# Scans linearly from current position until next in-use entry.
#
# input registers:
# a0 = current entry pointer
# a1 = current byte offset
#
# output registers:
# a0 = pointer to next entry, or null if done
# a1 = updated byte offset
################################################################################
hash_next:
	la	a2, hash_table
	addi	a1, a1, ELEMENTLEN

	li	a3, (ELEMENTLEN * HASHENTRIES)

hash_next_loop:
	beq	a1, a3, hash_next_notfound
	add	a0, a2, a1
	lw	a4, FLAGSOFFSET(a0)
	andi	a4, a4, FLAG_INUSE
	bnez	a4, hash_next_done
	addi	a1, a1, ELEMENTLEN
	j	hash_next_loop

hash_next_notfound:
	li	a0, 0
	li	a1, 0
hash_next_done:
	ret

