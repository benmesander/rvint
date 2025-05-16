.include "config.s"

.globl to_hex
.globl to_bin
.globl to_dec
.globl to_decu
.globl from_hex


.text

# input
# a0 - number to convert to ascii hex
# a1 - number of bytes to convert (eg, 1, 2, 4, 8)
# a2 - 0 do not insert leading 0x, 1 insert leading 0x
#
# output
# a0 - address of nul-terminated buffer with output
# a1 - length of string
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
	
# input
# a0 - number to convert to ascii binary
# a1 - number of bytes to convert (eg 1, 2, 4, 8)
# a2 - 0 do not insert spaces every 8 bits, 1 insert spaces every 8 bits
#
# output
# a0 - address of nul-terminated buffer with output
# a1 - length of string

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
	bnez 	a1, to_bin_loop

	sb	zero, 0(t0)
	la	a0, iobuf
	sub	a1, t0, a0
	ret

.size to_bin, .-to_bin

# input
# a0 - unsigned number to convert to ascii decimal
#
# output
# a0 - address of nul-terminated buffer with output
# a1 - length of string
to_decu:	
	FRAME	3
	PUSH	ra, 0
	PUSH	s0, 1
	PUSH	s1, 2

	mv	s1, a0			# save original number

	la	s0, iobuf
	addi	s0, s0, 79		# IOBUF_SIZE-1
	sb	zero, 0(s0)
	bnez	s1, to_decu_loop	# input is not zero

	addi	s0, s0, -1
	li	t0, '0'
	sb	t0, 0(s0)
	j	to_decu_retvals

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
	addi	t0, t0, 79		# IOBUF_SIZE-1
	sub	a1, t0, a0

	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	EFRAME	3
	ret

.size to_decu, .-to_decu

# input
# a0 - signed number to convert to ascii decimal
#
# output
# a0 - address of nul-terminated buffer with output
# a1 - length of string
to_dec:
	# xxx
	ret
.size to_dec, .-to_dec

# input
# a0 - pointer to number to convert from hex
from_hex:
	ret
.size from_hex, .-from_hex


.bss
.globl iobuf
.equ IOBUF_SIZE, 80 # one punch card worth
.comm iobuf, IOBUF_SIZE, 4
