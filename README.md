# rvint
Subroutines which implement RISC-V M extension functionality on I, E, and Zmmul instruction sets.

Currently unsigned 32 or 64 bit division is provided. 

Signed division, and signed and unsigned multiplication will be added as will support for multi-word operations, and integer I/O in various bases.

CPU_BITS in config.s should be set to 32 or 64 as appropriate for your processor. Test code is designed to run on a Linux-like operating system. I use https://riscv-programming.org/ale/
