.include "config.s"

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
	la	t0, iobuf
	li	t3, '9'
	slli	a1, a1, 1	# count of nibbles
	beqz	a2, to_hex_loop
	li	t1, 0x7830	# '0x' in ascii, little-endian
	sw	t1, 0(t0)
	addi	t0, t0, 2

to_hex_loop:
	addi	a1, a1, -1
	slli	t1, a1, 2
	srl	t2, a0, t1
	andi	t2, t2, 0xf
	addi	t2, t2, '0'	# numeral
	ble	t2, t3, to_hex_digit
	addi	t2, t2, 'a'-('0'+10) # too big for numeral, add offset to alpha
to_hex_digit:
	sb	t2, 0(t0)
	addi	t0, t0, 1
	bnez	a1, to_hex_loop
	sb	zero, 0(t0)	# nul terminate
	la	a0, iobuf
	sub	a1, t0, a0
	ret

.size to_hex, .-to_hex

################################################################################
# routine: to_bin
#
# Convert a value in a register to an ASCII binary string.
#
# input registers:
# a0 = number to convert to ascii binary
# a1 = number of bytes to convert (eg 1, 2, 4, 8)
# a2 = 0 do not insert spaces every 8 bits, 1 insert spaces every 8 bits
#
# output registers:
# a0 = address of nul (\0)-terminated buffer with output
# a1 = length of string
################################################################################

to_bin:
	la	t0, iobuf
	slli	a1, a1, 3	# count of bits (a1 * 8)
	li	t3, ' '

to_bin_loop:
	addi	a1, a1, -1
	srl	t2, a0, a1
	andi	t2, t2, 1
	addi	t2, t2, '0'
	sb	t2, 0(t0)
	addi	t0, t0, 1
	beqz	a2, to_bin_no_space
	andi	t2, a1, 0x7
	bnez	t2, to_bin_no_space
	beqz	a1, to_bin_no_space	# no trailing space
	sb	t3, 0(t0)
	addi	t0, t0, 1
to_bin_no_space:
	bnez	a1, to_bin_loop

	sb	zero, 0(t0)
	la	a0, iobuf
	sub	a1, t0, a0
	ret

.size to_bin, .-to_bin

################################################################################
# routine: to_decu
#
# Convert a value in a register to an unsigned ASCII decimal string.
#
# input registers:
# a0 = unsigned number to convert to ascii unsigned decimal
#
# output registers:
# a0 = address of nul-terminated (\0) buffer with output
# a1 = length of string
################################################################################
to_decu:
	FRAME	3
	PUSH	ra, 0
	PUSH	s0, 1
	PUSH	s1, 2

	mv	s1, a0			# save original number

	la	s0, iobuf
	addi	s0, s0, IOBUF_CAPACITY
	sb	zero, 0(s0)

to_decu_loop:
	addi	s0, s0, -1
	mv	a0, s1
	li	a1, 10
	call	divremu			# a0 quotient a1, remainder
	addi	a1, a1, '0'
	sb	a1, 0(s0)
	mv	s1, a0
	bnez	s1, to_decu_loop

to_decu_retvals:
	mv	a0, s0
	la	t0, iobuf
	addi	t0, t0, IOBUF_CAPACITY
	sub	a1, t0, a0

	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	EFRAME	3
	ret

.size to_decu, .-to_decu

################################################################################
# routine: to_dec
#
# Convert a value in a register to a signed ASCII decimal string.
#
# input registers:
# a0 = signed number to convert to ascii signed decimal
#
# output registers:
# a0 = address of nul-terminated (\0) buffer with output
# a1 = length of string
################################################################################

to_dec:
	FRAME	3
	PUSH	ra, 0
	PUSH	s0, 1
	PUSH	s1, 2

	mv	s1, a0

	la	s0, iobuf
	addi	s0, s0, IOBUF_CAPACITY
	sb	zero, 0(s0)

	mv	t0, zero		# t0 will be a flag: 1 if original number was negative and non-zero
					# For MIN_INT, it will become negative.
	bgez	s1, to_dec_abs_done	# If s1 >= 0, skip negation
	li	t0, 1			# Set negative flag
	sub	s1, zero, s1
to_dec_abs_done:
	# s1 now holds the absolute value (or MIN_INT if original was MIN_INT, which is treated as 2^(N-1) unsigned)
	# t0 holds 1 if a minus sign is needed, 0 otherwise.

to_dec_loop:
	addi	s0, s0, -1
	mv	a0, s1
	li	a1, 10
	call	divremu			# Output: a0=quotient, a1=remainder
	addi	a1, a1, '0'
	sb	a1, 0(s0)
	mv	s1, a0
	bnez s1, to_dec_loop

	# After loop, s0 points to the most significant digit.
	# Now, if the number was negative (t0 == 1), prepend '-'
	beqz	t0, to_dec_retval
	addi	s0, s0, -1
	li	t1, '-'
	sb	t1, 0(s0)

to_dec_retval:
	mv	a0, s0
	la	t1, iobuf
	addi	t1, t1, IOBUF_CAPACITY
	sub	a1, t1, a0
	POP s1, 2
	POP s0, 1
	POP ra, 0
	EFRAME 3
	ret

.size to_dec, .-to_dec

################################################################################
# routine: from_hex
#
# Read an ASCII hexidecimal string into a register. The parsing of the value
# stops when we read the first non-hex character.
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
	li	t2, 9
	li	t3, 5
from_hex_nibble:
	lb	t0, (a0)

	# Handle 0-9
	addi	t1, t0, -'0'
	bleu	t1, t2, from_hex_add_digit

	# Handle a-f and A-F by converting to uppercase
	andi	t0, t0, 0xDF	# clear bit 5 (cvt to upper)
	addi	t1, t0, -'A'
	bgtu	t1, t3, from_hex_done
	addi	t1, t1, 10	# A-F -> 10-15

from_hex_add_digit:
	li	a2, 1		# we found a digit
	slli	a1, a1, 4	# shift result left by 4 bits
	add	a1, a1, t1	# add new nibble
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
	li	t2, 1
from_bin_bit:
	lb	t0, (a0)
	addi	t1, t0, -'0'
	bgtu	t1, t2, from_bin_done

	li	a2, 1		# we found a bit
	slli	a1, a1, 1
	or	a1, a1, t1	# add new bit
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
	li	t2, 9

from_decu_digit:
	lb	t0,(a0)
	addi	t1, t0, -'0'
	bgtu	t1, t2, from_decu_done

	li	a2, 1
	slli	t3, a1, 1	# t3 = a1 * 2
	slli	t4, a1, 3	# t4 = a1 * 8
	add	a1, t3, t4	# a1 = a1 * 10
	add	a1, a1, t1	# add in new digit
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

	li	t5, 0	# sign bit (not used by from_decu)
	li	t1, '-'
	lb	t0, (a0)
	beq	t0, t1, from_dec_handle_minus
	li	t1, '+'
	beq	t0, t1, from_dec_handle_plus
	j	from_dec_convert

from_dec_handle_minus:
	li	t5, 1
from_dec_handle_plus:
	addi	a0, a0, 1

from_dec_convert:
	jal	from_decu
	beq	t5, zero, from_dec_done
	sub	a1, zero, a1

from_dec_done:
	POP	ra, 0
	EFRAME	1
	ret

.size from_dec, .-from_dec

