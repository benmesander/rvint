.include "config.s"
.include "mul-macs.s"

.globl to_hex
.globl to_bin
.globl to_dec
.globl to_decu
.globl from_hex
.globl from_bin
.globl from_decu
.globl from_dec

.bss
.globl iobuf
.equ IOBUF_SIZE, 80 # one punch card worth (note nul terminator makes capacity 79)
.equ IOBUF_CAPACITY, IOBUF_SIZE-1
.comm iobuf, IOBUF_SIZE, 4

.text

################################################################################
# routine: to_hex
#
# Convert a value in a register to an ASCII hexadecimal string.
# RV32E compatible
#
# input registers:
# a0 = number to convert to ascii hex
# a1 = number of bytes to convert (eg, 1, 2, 4, 8)
# a2 = 0 do not insert leading 0x, 1 insert leading 0x
#
# output registers:
# a0 = address of nul (\0)-terminated buffer with output
# a1 = length of string
################################################################################
to_hex:
	la	a3, iobuf	# output pointer
	li	t0, '9'
	slli	a1, a1, 1	# count of nibbles
	beqz	a2, to_hex_loop
	li	a4, 0x7830	# '0x' in ascii, little-endian
	sw	a4, 0(a3)
	addi	a3, a3, 2

to_hex_loop:
	addi	a1, a1, -1
	slli	a4, a1, 2
	srl	a5, a0, a4
	andi	a5, a5, 0xf
	addi	a5, a5, '0'	# numeral
	ble	a5, t0, to_hex_digit
	addi	a5, a5, 'a'-('0'+10) # too big for numeral, add offset to alpha
to_hex_digit:
	sb	a5, 0(a3)
	addi	a3, a3, 1
	bnez	a1, to_hex_loop
	sb	zero, 0(a3)	# nul terminate
	la	a0, iobuf
	sub	a1, a3, a0
	ret

.size to_hex, .-to_hex

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

################################################################################
# routine: to_decu
#
# Convert unsigned integer to ASCII decimal string.
# RV32I, RV32E, RV64I, RV128I, RV32IM, RV64IM, RV128IM
# Optimizations:
# - HAS_M: Uses hardware div/rem (Fastest).
# - HAS_ZBA: Uses optimal sh2add/sh3add for corrections (via mul10 macro)
# - Base: Uses robust series expansion for div10u.
#
# Input:  a0 = unsigned number
# Output: a0 = address of string buffer
#         a1 = length of string
################################################################################
to_decu:
	# 1. setup buffer (work backwards)
	la	a2, iobuf
	addi	a2, a2, IOBUF_CAPACITY
	mv	a1, a2			# end pointer
	sb	zero, 0(a2)		# nul-terminate

	# 2. loop setup
	mv	a3, a0			# a3 = n

to_decu_loop:
	addi	a2, a2, -1		# decrement buffer ptr

.if HAS_M
	# path 1: hardware division
	li	t0, 10
	remu	a5, a3, t0		# a5 = n % 10 (digit)
	divu	a3, a3, t0		# a3 = n / 10 (next n)

.else
	# path 2: series expansion
	# estimate q = n * 0.1
	srli	t0, a3, 2
	sub	a4, a3, t0		# a4 = n * 0.75

	srli	t0, a4, 4
	add	a4, a4, t0
	srli	t0, a4, 8
	add	a4, a4, t0
	srli	t0, a4, 16
	add	a4, a4, t0

.if CPU_BITS >= 64
	srli	t0, a4, 32
	add	a4, a4, t0
.endif

.if CPU_BITS == 128
	# extends series to 128 bits
	srli	t0, a4, 64
	add	a4, a4, t0
.endif
	srli	a4, a4, 3		# a4 = q_est

	# correction check: diff = 10*q - n
	mul10	a5, a4, t0		# a5 = 10 * q (uses t0 as scratch)
	sub	a5, a5, a3		# a5 = diff

	# threshold: diff <= -10
	slti	t0, a5, -9		# t0 = correction (0 or 1)
	add	a3, a4, t0		# a3 = n_new

	# remainder calculation
	# digit = -diff - 10*correction
	sub	a5, zero, a5		# a5 = -diff
	mul10	t1, t0, t2		# t1 = 10 * c (uses t2 as scratch)
	sub	a5, a5, t1		# a5 = digit
.endif

	# store digit
	addi	a5, a5, '0'
	sb	a5, 0(a2)

	bnez	a3, to_decu_loop

	# 3. finalize
	mv	a0, a2			# return start ptr
	sub	a1, a1, a2		# return length
	ret
.size to_decu, .-to_decu
	
################################################################################
# routine: to_dec
#
# Convert a signed integer to an ASCII decimal string.
# Wrapper strategy:
#   if (n >= 0) return to_decu(n);
#   else        return prepend('-', to_decu(-n));
#
# Usage:
#   Input:  a0 = signed number
#   Output: a0 = address of string
#           a1 = length of string
################################################################################

.globl to_dec
to_dec:
    # Case 1: Positive (or Zero)
    # Optimization: Tail-call to_decu (no stack frame needed).

    bgez    a0, to_decu     # If a0 >= 0, just jump to to_decu

    # Case 2: Negative
    # We must save ra because we make a standard call to to_decu.
    
    # ABI Note: We allocate 4 words (16 bytes) to ensure 16-byte
    # stack alignment on RV32. On RV64, this allocates 32 bytes,
    # which is also aligned.
    FRAME   4
    PUSH    ra, 3           # Save RA at the top of the frame
    neg     a0, a0          # a0 = -a0 (Negate input)
    call    to_decu         # Returns: a0=ptr, a1=len
    # Prepend '-'
    # to_decu fills the buffer backwards, so we have space 
    # before the returned pointer.
    li      t0, '-'
    addi    a0, a0, -1      # Back up pointer by 1 byte
    sb      t0, 0(a0)       # Store minus sign
    addi    a1, a1, 1       # Increment length
    # Restore and Return
    POP     ra, 3           # Restore RA
    EFRAME  4
    ret
.size to_dec, .-to_dec


################################################################################
# routine: from_hex
#
# Read an ASCII hexidecimal string into a register. The parsing of the value
# stops when we read the first non-hex character.
# RV32E compatible.
#
# input registers:
# a0 = pointer to number to convert from hex, terminated with non-hex char.
#
# output registers:
# a0 = pointer (advanced to point to non-hex char)
# a1 = number
# a2 = error check: 0 if no digits found, otherwise 1
################################################################################
	
from_hex:
	li	a1, 0
	li	a2, 0
	li	a5, 9
	li	t0, 5
from_hex_nibble:
	lb	a3, (a0)

	# Handle 0-9
	addi	a4, a3, -'0'
	bleu	a4, a5, from_hex_add_digit

	# Handle a-f and A-F by converting to uppercase
	andi	a3, a3, 0xDF	# clear bit 5 (cvt to upper)
	addi	a4, a3, -'A'
	bgtu	a4, t0, from_hex_done
	addi	a4, a4, 10	# A-F -> 10-15

from_hex_add_digit:
	li	a2, 1		# we found a digit
	slli	a1, a1, 4	# shift result left by 4 bits
	add	a1, a1, a4	# add new nibble
	addi	a0, a0, 1
	j	from_hex_nibble

from_hex_done:
	ret
.size from_hex, .-from_hex

################################################################################
# routine: from_bin
#
# Read an ASCII binary string into a register. The parsing of the value
# stops when we read the first non-binary character.
# RV32E compatible.
#
# input registers:
# a0 = pointer to number to convert from binary, terminated with non-binary char.
#
# output registers:
# a0 = pointer (advanced to point to non-binary char)
# a1 = number
# a2 = error check: 0 if no digits found, otherwise 1
################################################################################

from_bin:
	li	a1, 0
	li	a2, 0
	li	a5, 1
from_bin_bit:
	lb	a3, (a0)
	addi	a4, a3, -'0'
	bgtu	a4, a5, from_bin_done

	li	a2, 1		# we found a bit
	slli	a1, a1, 1
	or	a1, a1, a4	# add new bit
	addi	a0, a0, 1
	j	from_bin_bit

from_bin_done:
	ret
.size from_bin, .-from_bin

################################################################################
# routine: from_decu
#
# Read an ASCII unsigned decimal string into a register. The parsing of the value
# stops when we read the first non-decimal character.
# RV32E compatible.
#
# input registers:
# a0 = pointer to number to convert from decimal, terminated with non-decimal char.
#
# output registers:
# a0 = pointer (advanced to point to non-decimal char)
# a1 = number
# a2 = error check: 0 if no digits found, otherwise 1
################################################################################

from_decu:
	li	a1, 0
	li	a2, 0
	li	t1, 9

from_decu_digit:
	lb	t0, (a0)
	addi	a5, t0, -'0'
	bgtu	a5, t1, from_decu_done

	li	a2, 1
	mul10	a1, a1, a3
	add	a1, a1, a5	# add in new digit
	addi	a0, a0, 1
	j	from_decu_digit

from_decu_done:
	ret
.size from_decu, .-from_decu

################################################################################
# routine: from_dec
#
# Read an ASCII signed decimal string into a register. The parsing of the value
# stops when we read the first non-decimal character.
# RV32E compatible.
#
# input registers:
# a0 = pointer to number to convert from decimal, terminated with non-decimal char.
#
# output registers:
# a0 = pointer (advanced to point to non-decimal char)
# a1 = number
# a2 = error check: 0 if no digits found, otherwise 1
################################################################################

from_dec:
	FRAME	1
	PUSH	ra, 0

	li	a3, 0	# sign bit (not used by from_decu)
	li	a4, '-'
	lb	a2, (a0)
	beq	a2, a4, from_dec_handle_minus
	li	a4, '+'
	beq	a2, a4, from_dec_handle_plus
	j	from_dec_convert

from_dec_handle_minus:
	li	a3, 1
from_dec_handle_plus:
	addi	a0, a0, 1

from_dec_convert:
	jal	from_decu
	beq	a3, zero, from_dec_done
	sub	a1, zero, a1

from_dec_done:
	POP	ra, 0
	EFRAME	1
	ret

.size from_dec, .-from_dec

