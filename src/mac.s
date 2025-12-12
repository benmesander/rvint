# math macro functions

# Absolute Value
# src and dest can be the same
.macro abs dest src scratch
.if HAS_ZBB
	neg	\scratch, \src			# scratch = -src
	max	\dest, \src, \scratch		# src = max(src, -src)
.else
	srai	\scratch, \src, CPU_BITS-1	# scratch = mask (-1 or 0)
	add	\dest, \src, \scratch		# dest = src + mask
	xor	\dest, \dest, \scratch		# dest = (src + mask) ^ mask
.endif
.endm	
