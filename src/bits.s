.include "config.s"
.globl bits_ctz
.globl bits_clz

# count trailing zeroes
# input
# a0 number
# output
# a0 result

bits_ctz:
	ret
.size	bits_ctz, .-bits_ctz
	
# count leading zeroes
# input
# a0 number
# output
# a0 result

bits_clz:
	ret
.size	bits_clz, .-bits_clz
