# rvint
Subroutines which implement RISC-V M extension functionality on I, and Zmmul instruction sets. If there is interest, I could support other instruction sets such as E.

Currently signed and unsigned 32 or 64 bit division routines are provided for the RV32I, RV64I, RV32Zmmul, and RV64Zmmul instruction sets.

Signed and unsigned multiplication will be added as will support for multi-word operations, and integer I/O in various bases.

CPU_BITS in config.s should be set to 32 or 64 as appropriate for your processor. Test code is designed to run on a Linux-like operating system. I use https://riscv-programming.org/ale/
