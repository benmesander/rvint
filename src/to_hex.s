.include "config.s"
.include "mul-macs.s"

.globl to_hex

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
	sh	a4, 0(a3)
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
