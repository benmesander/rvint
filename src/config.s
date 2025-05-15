.equ CPU_BITS,64		# set for 32-bit or 64-bit processor (ie, RV32I or RV64I)


################################################################################

.equ CPU_BYTES,CPU_BITS/8	# bytes per word

.macro PUSH reg_to_save, offset_val, base_reg
.if CPU_BITS == 64
	sd \reg_to_save, \offset_val(\base_reg) # RV64I double word
.else
	sw \reg_to_save, \offset_val(\base_reg) # RV32I word
.endif
.endm

.macro POP reg_to_load, offset_val, base_reg
.if CPU_BITS == 64
	ld \reg_to_load, \offset_val(\base_reg)
.else
	lw \reg_to_load, \offset_val(\base_reg)
.endif
.endm

	
