# Set these appropriately for your processor

.equ 	CPU_BITS,	32	# set for 32-bit or 64-bit processor (ie, RV32I or RV64I)
.equ	HAS_ZBA,	0	# 1 = has Zba extension - address extension
.equ	HAS_ZBB, 	0	# 1 = has Zbb extension
.equ	HAS_ZBS,	0	# 1 = has Zbs extension - single bit instructions
.equ	HAS_ZICOND, 	0	# 1 = has Zicond extension

# Macros and constants used in subroutines
	
.equ 	CPU_BYTES,	CPU_BITS/8	# bytes per word

# build options

.equ 	DIVREMU_UNROLLED, 1	# 1 = unrolled 4x version, 0 = compact version



# XXX: move this stuff to rvhash

# hash table stuff
.equ KEYSIZE, CPU_BYTES
.equ VALSIZE, CPU_BYTES
.equ HASHENTRIES, 103	# prime

.equ _ACTUAL_FLAG_DATA_SIZE, 2      // Actual size of flag data (for documentation)
.equ FLAGS_STORAGE_SIZE, CPU_BYTES  // Flags stored in a CPU_BYTES slot for alignment

.equ FLAGSOFFSET, 0                 // Flags at the start of the element
.equ KEYOFFSET, FLAGS_STORAGE_SIZE    // Key starts after allocated space for flags
.equ VALOFFSET, FLAGS_STORAGE_SIZE + KEYSIZE // Value starts after flags and key
.equ ELEMENTLEN, FLAGS_STORAGE_SIZE + KEYSIZE + VALSIZE // Total element length, ensures alignment

# bitmasks
.equ FLAG_INUSE,	0x01
.equ FLAG_TOMBSTONE,	0x02
# end hash table stuff





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

.macro FRAME num_regs
	addi	sp, sp, -CPU_BYTES*\num_regs
.endm

.macro EFRAME num_regs
	addi	sp, sp, CPU_BYTES*\num_regs
.endm
