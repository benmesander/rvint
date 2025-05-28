.include "config.s"

.equ KEYSIZE, CPU_BYTES
.equ VALSIZE, CPU_BYTES
.equ HASHENTRIES, 103	# prime

.equ FLAGSOFFSET, 0
.equ FLAGSIZE, 2
.equ KEYOFFSET, FLAGSIZE
.equ VALOFFSET, FLAGSIZE + KEYSIZE
.equ ELEMENTLEN, FLAGSIZE + KEYSIZE + VALSIZE

# bitmasks
.equ FLAG_INUSE,	0x01
.equ FLAG_TOMBSTONE,	0x02

.data
.align 2
	
hash_table:
.rept HASHENTRIES
.space ELEMENTLEN, 0
.endr	

.text

# in
# a0 - ptr to key
# a1 - ptr to val
# out
# a0 - ptr to inserted val, or null
hash_insert:
	FRAME	2
	PUSH	ra, 0
	PUSH	s0, 1

	li	a2, 0			# accumulator
hash_insert_sum_key:
	lb	a3, 0(a0)
	add	a2, a2, a3
	add	a0, a0, 1
	bnez	a3, hash_insert_sum_key

	mv	a0, a3
	mv	s0, a1
	jal	hash_h1			# a0 = hash
	mv	a1, s0			# a1 = value (ptr)
	la	a4, hash_table		# a4 = table base pointer
	add	a4, a4, a0		# a4 = table element pointer
	lw	a3, FLAGSOFFSET(a4)	# a3 = flags
	andi	a5, a3, FLAG_INUSE
	bnez	a5, hash_insert_collision
	ori	a3, a3, FLAG_INUSE
	sw	a3, FLAGSOFFSET(a4)
.if CPU_BITS == 64
	sd	a0, KEYOFFSET(a4)
	sd	a1, VALOFFSET(a4)
.else
	sw	a0, KEYOFFSET(a4)
	sw	a1, VALOFFSET(a4)
.endif

hash_insert_done:
	POP	ra, 0
	POP	s0, 1
	EFRAME	2
	ret

hash_insert_collision:	

.size	hash_insert, .-hash_insert


# in
# a0 - ptr to key	
# out
# a0 - ptr to retrieved val, or null
hash_retrieve:

# in
# a0 - ptr to key	
# out
# a0 - ptr to deleted val, or null
hash_remove:


# in
# a0 = value to hash
# out
# a0 = hash value	
hash_h1:
	li	a1, HASHENTRIES
	jal	divremu
	mv	a0, a1
	ret

# in
# a0 = value to hash
# out
# a0 = hash value	
hash_h2:
	li	a1, HASHENTRIES - 1
	jal	divremu
	addi	a0, a1, 1
	ret
