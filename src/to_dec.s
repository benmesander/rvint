.include "config.s"
.include "mul-macs.s"
.globl to_dec
.text
	
################################################################################
# routine: to_dec
#
# Convert a signed integer to an ASCII decimal string.
# Wrapper strategy:
#   if (n >= 0) return to_decu(n);
#   else        return prepend('-', to_decu(-n));
#
# Usage:
#   Input:  a0 = signed number
#   Output: a0 = address of string
#           a1 = length of string
################################################################################

.globl to_dec
to_dec:
    # Case 1: Positive (or Zero)
    # Optimization: Tail-call to_decu (no stack frame needed).

    bgez    a0, to_decu     # If a0 >= 0, just jump to to_decu

    # Case 2: Negative
    # We must save ra because we make a standard call to to_decu.
    
    FRAME   1
    PUSH    ra, 0           # Save RA
    neg     a0, a0          # a0 = -a0 (Negate input)
    call    to_decu         # Returns: a0=ptr, a1=len
    # Prepend '-'
    # to_decu fills the buffer backwards, so we have space 
    # before the returned pointer.
    li      t0, '-'
    addi    a0, a0, -1      # Back up pointer by 1 byte
    sb      t0, 0(a0)       # Store minus sign
    addi    a1, a1, 1       # Increment length
    # Restore and Return
    POP     ra, 0           # Restore RA
    EFRAME  1
    ret
.size to_dec, .-to_dec
