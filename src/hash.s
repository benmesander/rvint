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
.align 2
	
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
	jal	divremu		        # a0=quotient, a1=remainder
	addi	a1, a1, 1		# Add 1 to the remainder

	# Scale step by ELEMENTLEN (18)
	slli	a0, a1, 4		# a0 = value * 16
	slli	a1, a1, 1		# a1 = value * 2
	add	a0, a1, a0		# a0 = value * 18
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
# a0 = value if successful, 0 if table is full
################################################################################
hash_insert:
	FRAME	3
	PUSH	ra, 0
	PUSH	s0, 1			# Save value in s0 
	PUSH	s1, 2			# Save key ptr in s1 

	mv	s1, a0			# Save key pointer
	mv	s0, a1			# Save value
	jal	sum_key			# Get key sum
	mv	a5, a0			# Save key sum
	jal	hash_h1			# Get initial index

	# Scale index by ELEMENTLEN (18) using shift-and-add:
	# val * 18 = (val * 16) + (val * 2)
	mv	t0, a0			# t0 = original value
	slli	t1, t0, 4		# t1 = value * 16
	slli	t0, t0, 1		# t0 = value * 2
	add	t0, t1, t0		# t0 = value * 18 (initial scaled byte offset)

	la	a1, hash_table
	add	a1, a1, t0		# Entry pointer
	lw	a2, FLAGSOFFSET(a1)
	andi	a3, a2, FLAG_INUSE
	bnez	a3, hash_insert_probe_init_offset
	# First slot is empty - use it
	li	a2, FLAG_INUSE
	sw	a2, FLAGSOFFSET(a1)
.if CPU_BITS == 64
	sd	s1, KEYOFFSET(a1)
	sd	s0, VALOFFSET(a1)
.else
	sw	s1, KEYOFFSET(a1)
	sw	s0, VALOFFSET(a1)
.endif
	mv	a0, s0			# Return value
	j	hash_insert_ret

hash_insert_probe_init_offset:
	mv	a2, t0			# Initialize a2 with initial scaled byte offset
hash_insert_probe:
	mv	a0, a5			# Load saved key sum
	jal	hash_h2			# Get pre-scaled step
	mv	a3, a0			# Save pre-scaled step
	la	a4, hash_table		# Base
	li	a5, HASHENTRIES		# Initialize probe counter
	li	t1, (ELEMENTLEN * HASHENTRIES)  # Total table size in bytes

insert_probe_loop:
	beqz	a5, hash_insert_full
	add	a2, a2, a3		# Next position (step already scaled)
	
	# Wrap offset if needed using conditional subtraction
	# This works because:
	# 1. a2 (current_offset) < table_size
	# 2. a3 (step) < table_size
	# Therefore: new_a2 = a2 + a3 < 2 * table_size
	# So one subtraction is sufficient to wrap
	blt	a2, t1, insert_probe_check  # Skip subtraction if already in bounds
	sub	a2, a2, t1		# Wrap to start of table

insert_probe_check:
	add	a1, a4, a2		# Entry pointer
	lw	a0, FLAGSOFFSET(a1)
	andi	a0, a0, FLAG_INUSE
	beqz	a0, insert_probe_found
	addi	a5, a5, -1		# Decrement probe counter
	j	insert_probe_loop

insert_probe_found:
	li	a0, FLAG_INUSE
	sw	a0, FLAGSOFFSET(a1)
.if CPU_BITS == 64
	sd	s1, KEYOFFSET(a1)
	sd	s0, VALOFFSET(a1)
.else
	sw	s1, KEYOFFSET(a1)
	sw	s0, VALOFFSET(a1)
.endif
	mv	a0, s0			# Return value
	j	hash_insert_ret

hash_insert_full:
	li	a0, 0			# Return null

hash_insert_ret:
	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	EFRAME	3
	ret

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
	FRAME	4
	PUSH	ra, 0
	PUSH	s0, 1			# Current offset in s0 
	PUSH	s1, 2			# Key ptr in s1 
	PUSH	a5, 3			# Key sum in a5 

	mv	s1, a0			# Save key pointer
	jal	sum_key			# Get key sum
	mv	a5, a0			# Save key sum
	jal	hash_h1			# Get initial index

	# Scale index by ELEMENTLEN (18) using shift-and-add:
	# val * 18 = (val * 16) + (val * 2)
	mv	t0, a0			# t0 = original value
	slli	t1, t0, 4		# t1 = value * 16
	slli	t0, t0, 1		# t0 = value * 2
	add	s0, t1, t0		# s0 = value * 18

	mv	a2, s0			# Current offset in a2
	la	a3, hash_table		# Table base in a3
	li	a4, HASHENTRIES		# Counter in a4
	li	t1, (ELEMENTLEN * HASHENTRIES)  # Total table size in bytes

retrieve_probe_loop:
	beqz	a4, hash_retrieve_fail
	add	a1, a3, a2		# Entry pointer in a1
	lw	a0, FLAGSOFFSET(a1)
	andi	t0, a0, FLAG_INUSE	# Use t0 to preserve a0 for tombstone check
	andi	a0, a0, FLAG_TOMBSTONE

	beqz	t0, retrieve_check_tombstone

.if CPU_BITS == 64
	ld	a0, KEYOFFSET(a1)
.else
	lw	a0, KEYOFFSET(a1)
.endif
	mv	t0, a1			# Save entry pointer
	mv	a1, s1			# Original key pointer
	jal	strcmp
	mv	a1, t0			# Restore entry pointer
	beqz	a0, retrieve_found

	j	retrieve_calc_next_probe

retrieve_check_tombstone:
	bnez	a0, retrieve_calc_next_probe
	j	hash_retrieve_fail

retrieve_calc_next_probe:
	mv	a0, a5			# Load saved key sum
	jal	hash_h2			# Get pre-scaled step
	add	s0, s0, a0		# Add pre-scaled step to offset

	# Wrap offset if needed using conditional subtraction
	blt	s0, t1, retrieve_probe_continue  # Skip subtraction if in bounds
	sub	s0, s0, t1		# Wrap to start of table

retrieve_probe_continue:
	mv	a2, s0			# Update a2 with new offset
	addi	a4, a4, -1		# Decrement probe counter
	j	retrieve_probe_loop

retrieve_found:
.if CPU_BITS == 64
	ld	a0, VALOFFSET(a1)
.else
	lw	a0, VALOFFSET(a1)
.endif
	j	hash_retrieve_ret

hash_retrieve_fail:
	li	a0, 0			

hash_retrieve_ret:
	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	POP	a5, 3
	EFRAME	4
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
	FRAME	4
	PUSH	ra, 0
	PUSH	s0, 1			# Current offset in s0 
	PUSH	s1, 2			# Key ptr in s1 
	PUSH	a5, 3			# Key sum in a5 

	mv	s1, a0			# Save key pointer
	jal	sum_key			# Get key sum
	mv	a5, a0			# Save key sum
	jal	hash_h1			# Get initial index

	# Scale index by ELEMENTLEN (18) using shift-and-add:
	# val * 18 = (val * 16) + (val * 2)
	mv	t0, a0			# t0 = original value
	slli	t1, t0, 4		# t1 = value * 16
	slli	t0, t0, 1		# t0 = value * 2
	add	s0, t1, t0		# s0 = value * 18

	mv	a2, s0			# Current offset in a2
	la	a3, hash_table		# Table base
	li	a4, HASHENTRIES		# Counter
	li	t1, (ELEMENTLEN * HASHENTRIES)  # Total table size in bytes

remove_probe_loop:
	beqz	a4, hash_remove_fail
	add	a1, a3, a2		# Entry pointer
	lw	a0, FLAGSOFFSET(a1)
	andi	t0, a0, FLAG_INUSE	# Use t0 to preserve a0 for tombstone check
	andi	t2, a0, FLAG_TOMBSTONE

	beqz	t0, remove_check_tombstone

.if CPU_BITS == 64
	ld	a0, KEYOFFSET(a1)
.else
	lw	a0, KEYOFFSET(a1)
.endif
	mv	t0, a1			# Save entry pointer
	mv	a1, s1			# Original key pointer
	jal	strcmp
	mv	a1, t0			# Restore entry pointer
	beqz	a0, remove_found

	j	remove_calc_next_probe

remove_check_tombstone:
	bnez	t2, remove_calc_next_probe
	j	hash_remove_fail

remove_calc_next_probe:
	mv	a0, a5			# Load saved key sum
	jal	hash_h2			# Get pre-scaled step
	add	s0, s0, a0		# Add pre-scaled step to offset

	# Wrap offset if needed using conditional subtraction
	blt	s0, t1, remove_probe_continue  # Skip subtraction if in bounds
	sub	s0, s0, t1		# Wrap to start of table

remove_probe_continue:
	mv	a2, s0			# Update a2 with new offset
	addi	a4, a4, -1		# Decrement probe counter
	j	remove_probe_loop

remove_found:
.if CPU_BITS == 64
	ld	a0, VALOFFSET(a1)
.else
	lw	a0, VALOFFSET(a1)
.endif
	lw	a2, FLAGSOFFSET(a1)
	li	a3, FLAG_TOMBSTONE
	or	a2, a2, a3		# Set tombstone bit
	li	a3, ~FLAG_INUSE
	and	a2, a2, a3		# Clear in-use bit
	sw	a2, FLAGSOFFSET(a1)
	j	hash_remove_ret

hash_remove_fail:
	li	a0, 0

hash_remove_ret:
	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	POP	a5, 3
	EFRAME	4
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
	FRAME	6
	PUSH	ra, 0
	PUSH	s0, 1			# Current offset in s0 
	PUSH	s1, 2			# Table base in s1 
	PUSH	a4, 3			# Key sum in a4 
	PUSH	a5, 4			# Count in a5 
	PUSH	s2, 5			# Save original value

	la	s1, hash_table
	li	s0, 0			# Current offset
	li	a5, 0			# Count
	li	t1, (ELEMENTLEN * HASHENTRIES)  # Total table size in bytes

scan_loop:
	beq	s0, t1, rehash_done

	add	a2, s1, s0		# Entry pointer
	lw	a1, FLAGSOFFSET(a2)
	andi	a1, a1, FLAG_INUSE
	beqz	a1, scan_next

.if CPU_BITS == 64
	ld	a0, KEYOFFSET(a2)
	ld	s2, VALOFFSET(a2)	# Save original value in s2 
	lw	a0, KEYOFFSET(a2)
	lw	s2, VALOFFSET(a2)	# Save original value in s2 
.endif
	mv	a3, a0			# Save key pointer
	jal	sum_key
	mv	a4, a0			# Save key sum
	jal	hash_h1

	# Scale index by ELEMENTLEN (18) using shift-and-add:
	# val * 18 = (val * 16) + (val * 2)
	mv	t0, a0			# t0 = original value
	slli	t1, t0, 4		# t1 = value * 16
	slli	t0, t0, 1		# t0 = value * 2
	add	a0, t1, t0		# a0 = value * 18

	bge	s0, a0, scan_next

	add	a2, s1, s0		# Current entry
	lw	a1, FLAGSOFFSET(a2)
.if CPU_BITS == 64
	ld	a3, KEYOFFSET(a2)
.else
	lw	a3, KEYOFFSET(a2)
.endif

	sw	zero, FLAGSOFFSET(a2)

	mv	a2, a0			# Try pos (already scaled)
	li	a0, HASHENTRIES		# Initialize probe counter
	li	t1, (ELEMENTLEN * HASHENTRIES)  # Total table size in bytes

try_insert:
	beqz	a0, scan_next
	add	a1, s1, a2		# Entry at try pos
	lw	t0, FLAGSOFFSET(a1)
	andi	t0, t0, FLAG_INUSE
	bnez	t0, try_next

	li	t0, FLAG_INUSE
	sw	t0, FLAGSOFFSET(a1)
.if CPU_BITS == 64
	sd	a3, KEYOFFSET(a1)
	sd	s2, VALOFFSET(a1)	# Use saved value from s2 
.else
	sw	a3, KEYOFFSET(a1)
	sw	s2, VALOFFSET(a1)	# Use saved value from s2 
.endif
	addi	a5, a5, 1
	j	scan_next

try_next:
	mv	a0, a4			# Load saved key sum
	jal	hash_h2			# Get pre-scaled step
	add	a2, a2, a0		# Add pre-scaled step to offset

	# Wrap offset if needed using conditional subtraction
	blt	a2, t1, try_insert_continue  # Skip subtraction if in bounds
	sub	a2, a2, t1		# Wrap to start of table

try_insert_continue:
	addi	a0, a0, -1		# Decrement probe counter
	j	try_insert

scan_next:
	addi	s0, s0, ELEMENTLEN
	j	scan_loop

rehash_done:
	mv	a0, a5			# Return count
	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	POP	a4, 3
	POP	a5, 4
	POP	s2, 5			# Restore s2
	EFRAME	6
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

