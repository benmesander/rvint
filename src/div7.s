.include "config.s"
.include "mul-macs.s"

.if CONSTANT_TABLE
.section .srodata, "a", @progbits
.align 3
M_div7:
	.quad 0x4924924924924925
.endif

.globl div7
.text

.if HAS_ZMMUL == 1
################################################################################
# routine: div7
#
# Signed fast division by 7 for processors with a multiply instruction
# Algorithm: "Magic Number" - Hacker's Delight 2nd ed. sec 10.3,
# Suitable for RV32I_Zmmul, RV64I_Zmmul
# Note: unless your core has the Zkt instruction, this may not run in
#       constant time, consult your vendor documentation.
#
# input:  a0 = signed dividend
# output: a0 = signed quotient
################################################################################
div7:

.if CPU_BITS == 64
.if CONSTANT_TABLE
	ld      a2, M_div7
.else
        li      a2, 0x4924924924924925
.endif
        mulh    a1, a0, a2
        slti    a2, a0, 0       # Hides multiplier stall
        srai    a1, a1, 1       # Exact shift for 64-bit positive magic number
.else
        li      a2, 0x92492493  # (2**34+5)/7
        mulhsu  a1, a0, a2      # Signed * Unsigned entirely skips the need for 'add'
        slti    a2, a0, 0       # Hides multiplier stall
        srai    a1, a1, 2       # Exact shift for 32-bit mulhsu path
.endif
        add     a0, a1, a2      # Final sign adjustment correction

        ret
.else
# The following routines started with the Hacker's Delight 2nd edition
# Chapter 10 routines, but were extended to handle 64 bits which involved
# refining the series expansions and the correction steps. In some
# cases I managed to save an instruction or two in the correction step.
	
################################################################################
# routine: div7
#
# Signed fast division by 7.
# RV32I, RV32E, RV64I
#
# Input:  a0 = dividend (signed)
# Output: a0 = quotient (signed)
################################################################################
div7:
	# preamble: compute sign mask (t0) and abs(n) (a0)
	srai	t0, a0, CPU_BITS-1
	xor	a0, a0, t0
	sub	a0, a0, t0	# a0 = abs(n)

	# estimate quotient: q = abs(n) / 7
	# base: n * 0.5625 (9/16)
	srli	a1, a0, 1
	srli	a2, a0, 4
	add	a1, a1, a2

	# series expansion: converge 0.5625 -> 0.5714...
	srli	a2, a1, 6
	add	a1, a1, a2	# q += q >> 6
	srli	a2, a1, 12
	add	a1, a1, a2	# q += q >> 12
	srli	a2, a1, 24
	add	a1, a1, a2	# q += q >> 24
.if CPU_BITS == 64
	srli	a2, a1, 48
	add	a1, a1, a2	# q += q >> 48
.endif

	# final shift: q_est = (n * 4/7) / 4 = n / 7
	srli	a1, a1, 2

	# negative remainder calculation
	# diff = 7q - abs(n)
	slli	a2, a1, 3	# a2 = 8q
	sub	a2, a2, a1	# a2 = 7q
	sub	a2, a2, a0	# a2 = diff

	# threshold check 1: diff <= -7 (i.e. < -6)
	slti	a3, a2, -6
	add	a1, a1, a3	# q += 1

.if CPU_BITS == 64
	# threshold check 2: diff <= -14 (i.e. < -13)
	# This handles the rare cases where estimation error is 2.
	slti	a3, a2, -13
	add	a1, a1, a3	# q += 1
.endif

	# postamble: restore sign
	xor	a0, a1, t0
	sub	a0, a0, t0
	ret
.endif
.size div7, .-div7
