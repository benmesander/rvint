# Set these appropriately for your processor

.equ 	CPU_BITS,	32	# set for 32-bit or 64-bit processor (ie, RV32I or RV64I)
.equ	HAS_ZBA,	0	# 1 = has Zba extension - address extension
.equ	HAS_ZBB, 	0	# 1 = has Zbb extension
.equ	HAS_ZBS,	0	# 1 = has Zbs extension - single bit instructions
.equ	HAS_ZICOND, 	0	# 1 = has Zicond extension
.equ	HAS_M,		0	# 1 = has M (integer math) extension

# Macros and constants used in subroutines
	
.equ 	CPU_BYTES,	CPU_BITS/8	# bytes per word

# build options

.equ 	DIVREMU_UNROLLED, 1	# 1 = unrolled 4x version, 0 = compact version

# stack frames

.macro PUSH reg_to_save, offset_val
.if CPU_BITS == 64
	sd \reg_to_save, \offset_val*CPU_BYTES(sp) # RV64I double word
.else
	sw \reg_to_save, \offset_val*CPU_BYTES(sp) # RV32I word
.endif
.endm

.macro POP reg_to_load, offset_val
.if CPU_BITS == 64
	ld \reg_to_load, \offset_val*CPU_BYTES(sp)
.else
	lw \reg_to_load, \offset_val*CPU_BYTES(sp)
.endif
.endm

.set STACK_ALIGN, 16

.macro FRAME num_regs
    .set BYTES_NEEDED, \num_regs * CPU_BYTES
    .set STACK_SIZE, ((BYTES_NEEDED + STACK_ALIGN - 1) / STACK_ALIGN) * STACK_ALIGN
    
    # Safety Check: Ensure STACK_SIZE is actually a multiple of 16
    .if (STACK_SIZE % 16) != 0
        .error "Calculated STACK_SIZE is not 16-byte aligned"
    .endif

    addi sp, sp, -STACK_SIZE
.endm

.macro EFRAME num_regs
    .set BYTES_NEEDED, \num_regs * CPU_BYTES
    .set STACK_SIZE, ((BYTES_NEEDED + STACK_ALIGN - 1) / STACK_ALIGN) * STACK_ALIGN
    
    addi sp, sp, STACK_SIZE
.endm

