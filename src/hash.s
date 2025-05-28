.equ KEYSIZE, 4
.equ VALSIZE, 4
.equ HASHENTRIES, 103	# prime

.equ FLAGSOFFSET, 0
.equ FLAGSIZE, 1
.equ KEYOFFSET, FLAGSIZE
.equ VALOFFSET, FLAGSIZE + KEYSIZE
.equ ELEMENTLEN, FLAGSIZE + KEYSIZE + VALSIZE

.equ FLAG_DELETED, 0x01

.bss
	
.rept HASHENTRIES
.space ELEMENTLEN
.endr	

.text

# in
# a0 - ptr to key
# a1 - ptr to val
# out
# a0 - ptr to inserted val, or null
hash_insert:

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

	
