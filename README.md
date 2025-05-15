# rvint

Integer-based mathematical subroutines which implement RISC-V M
extension functionality on I, and Zmmul instruction sets. If there is
interest, I could support other instruction sets such as E.

Currently signed and unsigned 32 or 64 bit division routines are
provided for RV32I, RV64I, and similar instruction sets.

## Division

### On 32-bit processors
- 32-bit by 32-bit signed and unsigned division with 32-bit result and remainder.
### On 64-bit processors
- 64-bit by 64-bit signed and unsigned division with 64-bit result and remainder.

Note: signed division routine will be further optimized

## Multiplication

### On 32-bit processors:
- 32-bit by 32-bit signed and unsigned multiplication with 32-bit result.
- 32-bit by 32-bit signed and unsigned multiplication with 64-bit result. (not yet implemented)

### on 64-bit processors:
- 32-bit by 32-bit signed and unsigned multiplication with 64-bit result. (not yet implemented)
- 64-bit by 64-bit signed and unsigned multiplication with 64-bit result.
- 64-bit by 64-bit signed and unsigned multiplication with 128-bit result. (not yet implemented)

## Base Conversions & I/O Operations (not yet implemented)

These operations support 32-bit numbers on 32-bit architectures and
64-bit numbers on 64-bit architectures.

- ASCII binary to binary
- ASCII signed decimal to two's complement binary
- ASCII hexadecimal to binary

- binary to ASCII binary
- two's complement binary to ASCII signed decimal
- binary to ASCII hexadecimal




CPU_BITS in config.s should be set to 32 or 64 as appropriate for your processor. Test code is designed to run on a Linux-like operating system. I use https://riscv-programming.org/ale/
