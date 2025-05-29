.include "config.s"
.text
.globl	_start
.globl	print
_start:
	# test 0 - print empty table
	la	a1, test
	li	a2, 5
	jal	print
	li	a0, 0
	call	to_decu
	mv	a2, a1
	mv	a1, a0
	jal	print
	la	a1, nl
	li	a2, 1
	jal	print
	jal	print_hash_table

	# test 1 - insert a key/value
	la	a0, oink
	la	a1, bar
	call	hash_insert

#	la	a0, oink
#	call	sum_key
#	call	to_decu
#	mv	a2, a1
#	mv	a1, a0
#	call	print


	la	a1, test
	li	a2, 5
	jal	print
	li	a0, 1
	call	to_decu
	mv	a2, a1
	mv	a1, a0
	jal	print
	la	a1, nl
	li	a2, 1
	jal	print
	jal	print_hash_table



	j	end
	
################################################################################
# routine: print_hash_table
#
# Print the hash table contents in the specified format.
# For each entry with nonzero flags, prints:
# <index>: <flags>:<key_ptr>(<string>):<value>
#
# Uses only rv32i/rv64i instructions.
# No input/output registers.
################################################################################
print_hash_table:
	FRAME	6
	PUSH	ra, 0
PUSH	s0, 1			# Entry counter
PUSH	s1, 2			# Current entry pointer
PUSH	s2, 3			# Save flags
PUSH	s3, 4			# Save key pointer
PUSH	s4, 5			# Save value

# Print header
la	a1, header_str
li	a2, 28			# Length of header string
jal	print

# Initialize
li	s0, 0			# Entry counter = 0
la	s1, hash_table		# Current entry pointer = hash_table

print_hash_loop:
# Check if we've processed all entries
li	t0, HASHENTRIES
beq	s0, t0, print_hash_done

# Load flags
lw	s2, FLAGSOFFSET(s1)
beqz	s2, print_hash_next	# Skip if flags are zero

# Print entry number
	mv	a0, s0
	PUSH	ra, -1
	jal	to_decu			# Convert to decimal string
	mv	a2, a1			# Save length in a2
	mv	a1, a0			# Move string pointer to a1 for print
	jal	print
	POP	ra, -1
	
	# Print ": "
	la	a1, colon_space
	li	a2, 2
	jal	print

	# Print flags
	andi	t0, s2, FLAG_TOMBSTONE
	beqz	t0, print_no_t
	la	a1, tomb
	j	print_t_done
print_no_t:
	la	a1, space_char
print_t_done:
	li	a2, 1
	jal	print

	andi	t0, s2, FLAG_INUSE
	beqz	t0, print_no_i
	la	a1, inuse
	j	print_i_done
print_no_i:
	la	a1, space_char
print_i_done:
	li	a2, 1
	jal	print

	# Print colon
	la	a1, colon
	li	a2, 1
	jal	print

	# Print key pointer in hex
.if CPU_BITS == 64
	ld	s3, KEYOFFSET(s1)
	li	a1, 8			# 8 bytes for 64-bit
.else
	lw	s3, KEYOFFSET(s1)
	li	a1, 4			# 4 bytes for 32-bit
.endif
	mv	a0, s3
	li	a2, 1			# Include 0x prefix
	PUSH	ra, -1
	jal	to_hex			# Convert to hex string
	mv	a2, a1			# Save length in a2
	mv	a1, a0			# Move string pointer to a1 for print
	jal	print
	POP	ra, -1

	# Print key string in parentheses
	la	a1, open_paren
	li	a2, 1
	jal	print
	mv	a1, s3			# Key string pointer
	mv	a0, s3
	PUSH	ra, -1
	jal	strlen			# Get string length
	mv	a2, a0			# Length for print
	jal	print
	POP	ra, -1
	la	a1, close_paren
	li	a2, 1
	jal	print

	# Print colon
	la	a1, colon
	li	a2, 1
	jal	print

	# Print value in hex
.if CPU_BITS == 64
	ld	s4, VALOFFSET(s1)
	li	a1, 8			# 8 bytes for 64-bit
.else
	lw	s4, VALOFFSET(s1)
	li	a1, 4			# 4 bytes for 32-bit
.endif
	mv	a0, s4
	li	a2, 1			# Include 0x prefix
	PUSH	ra, -1
	jal	to_hex			# Convert to hex string
	mv	a2, a1			# Save length in a2
	mv	a1, a0			# Move string pointer to a1 for print
	jal	print
	POP	ra, -1

	# Print newline
	la	a1, nl
	li	a2, 1
	jal	print

print_hash_next:
	addi	s0, s0, 1		# Increment counter
	addi	s1, s1, ELEMENTLEN	# Move to next entry
	j	print_hash_loop

print_hash_done:
	# Print footer
	la	a1, footer_str
	li	a2, 26			# Length of footer string
	jal	print

	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	POP	s2, 3
	POP	s3, 4
	POP	s4, 5
	EFRAME	6
	ret

# in: a0 - ptr to string
# out: a0 - count
# clobbers a0, t0, t1
strlen:
	mv	t0, a0
strlen_loop:	
	lb	t1, 0(a0)
	beqz	t1, strlen_done
	addi	a0, a0, 1
	j	strlen_loop
strlen_done:
	sub	a0, a0, t0
	ret

# a1 - ptr to string to print
# a2 - # bytes to print
print:
	li	a0, 1	# stdout
	li	a7, 64	# write syscall
	ecall
	ret

end:
        li	a0, 0	# exit code
        li	a7, 93	# exit syscall
        ecall

.data
header_str:	.string "--- start of hash table ---\n"
footer_str:	.string "--- end of hash table ---\n"
colon_space:	.string ": "
inuse:		.string "I"
tomb:		.string "T"
space_char:	.string " "
open_paren:	.string "("
close_paren:	.string ")"
nl:		.string "\n"
colon:		.string ":"
test:		.string "test "
oink:		.string "oink"
knio:		.string "knio"
inko:		.string "inko"
foo:		.string "foo"
bar:		.string "bar"
