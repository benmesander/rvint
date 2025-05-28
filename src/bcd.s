.include "config.s"
.text
# need to decide on bcd format (number digits, how to mark negative, etc.)
#
# bcd_add, bcd_sub, bcd_valid, to_bcd, from_bcd, others?
#	
bcd_valid:
	ret
.size bcd_valid, .-bcd-valid
