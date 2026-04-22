.include "config.s"
.include "mul-macs.s"
.globl to_bin
.text

################################################################################
# routine: to_bin
#
# Convert a value in a register to an ASCII binary string.
# RV32E compatible.	
#
# Optimizations:
# - Zbs: Uses 'bext' to extract bits directly (saves 'srl' + 'andi').
#
# input registers:
# a0 = number to convert to ascii binary
# a1 = number of bytes to convert (eg 1, 2, 4, 8)
# a2 = flags (0=none, 1=0b prefix, 2=spaces every 8 bits, 3=both)
#
# output registers:
# a0 = address of nul (\0)-terminated buffer with output
# a1 = length of string
################################################################################
to_bin:
	mv	a5, a0		# Move value to a5 (free up a0 for return)
	la	a0, iobuf	# a0 = Base Address (Return Value)
	mv	a3, a0		# a3 = Current Pointer
	# Prefix Logic (Bit 0)
	andi	a4, a2, 1
	beqz	a4, to_bin_start
	# Smallest '0b' store: use a 32-bit constant load + half-word store
	li	a4, 0x6230	# '0b' (little endian)
	sh	a4, 0(a3)	# Store 2 bytes
	addi	a3, a3, 2
to_bin_start:
	slli	a1, a1, 3	# convert bytes to bits
	addi	a1, a1, -1	# a1 = Bit Index (Start at MSB)
to_bin_loop:
	# Bit Extraction
.if HAS_ZBS
	bext	a4, a5, a1	# a4 = (val >> index) & 1
.else
	srl	a4, a5, a1
	andi	a4, a4, 1
.endif
	addi	a4, a4, '0'	# Convert to ASCII
	sb	a4, 0(a3)
	addi	a3, a3, 1

	# Spacing Logic (Bit 1)
	andi	a4, a2, 2	# Check Flag
	beqz	a4, to_bin_next
	andi	a4, a1, 7	# Check Boundary (Index % 8)
	bnez	a4, to_bin_next
	beqz	a1, to_bin_next	# Skip if last bit
	li	a4, ' '
	sb	a4, 0(a3)
	addi	a3, a3, 1

to_bin_next:
	addi	a1, a1, -1
	bgez	a1, to_bin_loop
	sb	zero, 0(a3)	# Null terminate
	sub	a1, a3, a0	# Length = Current - Base
	ret
.size to_bin, .-to_bin
