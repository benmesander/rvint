.include "config.s"

.globl _start
_start:
	j	end
	

print_hash_table:
	la	a2, hash_table		# a2 - current element address
	li	a0, 0			# a0 - element index in table

print_hash_table_loop:	
	lw	a1, FLAGSOFFSET(a2)	# a1 - scratch
	mv	s1, a1			# save - a1->s1
	andi	a3, a1, FLAG_INUSE	# a3 - scratch	XXX: SKIP ENTRY IF NOTINUSE
	la	a1, space
	bnez	a3, pht_notinuse
	la	a1, inuse
pht_notinuse:	
	# XXX: Print element number, colon

	mv	s2, a2			# save - a2->s2
	mv	s0, a0			# save - a0->s0
	li	a2, 1
	jal	print

	andi	a3, s1, FLAG_TOMBSTONE
	la	a1, space
	bnez	a3, pht_notdeadyet
	la	a1, tomb
pht_notdeadyet:	
	li	a2, 1
	jal	print

	la	a1, colon
	li	a2, 1
	jal	print


.if CPU_BITS == 64
	ld	a1, KEYOFFSET(a2)
.else
	lw	a1, KEYOFFSET(a2)
.endif
	# XXX: NULL
	mv	a0, a1
	jal	strlen
	mv	a2, a0
	jal	print

	la	a1, colon
	li	a2, 1
	jal	print

.if CPU_BITS == 64
	ld	a1, KEYOFFSET(a2)
.else
	lw	a1, KEYOFFSET(a2)
.endif
	# XXX: NULL
	mv	a0, a1
	jal	strlen
	mv	a2, a0
	jal	print

	
	mv	a2, s2
	mv	a0, s0
	addi	a2, a2, ELEMENTLEN
	addi	a0, a0, 1
	sltiu	a1, a0, HASHENTRIES
	bnez	a1, print_hash_table_loop
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

_end:
        li	a0, 0	# exit code
        li	a7, 93	# exit syscall
        ecall

inuse:	.string	"I"
tomb:	.string	"T"
space:	.string "   "	# secretly 3 spaces, choose your own adventure
nl:	.string	"\n"
colon:	.string	":"
