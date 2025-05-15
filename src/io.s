.include "config.s"

.globl to_hex
.globl to_bin
.globl to_dec
.globl from_hex


.text

	# input
	# a0 - number to convert to ascii hex
	# a1 - number of bytes to convert (eg, 1, 2, 4, 8)
	# a2 - 0 do not insert leading 0x, 1 insert leading 0x
	#
	# output
	# a0 - address of nul-terminated buffer with output
to_hex:
	la	t0, iobuf
	li	t3, '9' + 1	# '@'
	slli	a1, a1, 2	# count of nibbles
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
	bge	t2, t3, to_hex_digit
	addi	t2, t2, 'a'-'0'	# too big for numeral, add offset to alpha
to_hex_digit:
	sb	t2, 0(t0)
	addi	t0, t0, 1
	bnez	a1, to_hex_loop
	sb	zero, 0(t0)	# nul terminate
	la	a0, iobuf
	ret

.size to_hex, .-to_hex
	
# input
# a0 - number to convert to ascii binary
# a1 - number of bytes to convert (eg 1, 2, 4, 8)
# a2 - 0 do not insert spaces every 8 bits, 1 insert spaces every 8 bits
#
# output
# a0 - address of nul-terminated buffer with output

to_bin:
	la	t0, iobuf
	slli	a1, a1, 4	# count of bits (a1 * 8)
	li	t3, ' '

to_bin_loop:
	addi	a1, a1, -1
	li	t1, 1
	sll	t1, t1, a1
	and	t2, t1, a0
	srl	t2, t2, a1
	addi	t2, t2, '0'
	sb	t2, 0(t0)
	addi	t0, t0, 1
	beqz	a2, to_bin_no_space
	andi	t2, a1, 0x7
	bnez	t2, to_bin_no_space
	sb	t3, 0(t0)
	addi	t0, t0, 1
to_bin_no_space:
	bnez 	a1, to_bin_loop
	la	a0, iobuf
	ret

.size to_bin, .-to_bin

# input
# a0 - number to convert to ascii decimal
#
# output
# a0 - address of nul-terminated buffer with output
to_dec:	
	addi	sp, sp, -(CPU_BYTES) # need stack frame as we will call udivrem
	PUSH	ra, 0

	POP	ra, 0
	addi	sp, sp, (CPU_BYTES)
	la	a0, iobuf # xxx: wrong
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
.comm iobuf, IOBUF_SIZE
