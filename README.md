# rvint

Integer-based mathematical subroutines which implement RISC-V M and B
extension functionality on I, and Zmmul instruction sets. If there is
interest, I could support other instruction sets such as E.

These routines are designed to be both concise and efficient, although
where those two goals clash, I went with concise.

![Screenshot of tests](rvint.png "Screenshot of tests")


## Division

### On 32-bit processors
- 32-bit by 32-bit signed and unsigned division with 32-bit result and remainder.
### On 64-bit processors
- 64-bit by 64-bit signed and unsigned division with 64-bit result and remainder.

### On both
- Fast division of 32-bit unsigneds by three

## Multiplication

### On 32-bit processors:
- 32-bit by 32-bit signed and unsigned multiplication with 32-bit result.
- 32-bit by 32-bit signed and unsigned multiplication with 64-bit result.

### on 64-bit processors:
- 32-bit by 32-bit signed and unsigned multiplication with 64-bit result.
- 64-bit by 64-bit signed and unsigned multiplication with 64-bit result.
- 64-bit by 64-bit signed and unsigned multiplication with 128-bit result.

## Base Conversions & I/O Operations

These operations support 32-bit numbers on 32-bit architectures and
64-bit numbers on 64-bit architectures.

- ASCII binary to binary.
- ASCII unsigned decimal to binary.
- ASCII signed decimal to two's complement binary.
- ASCII hexadecimal to binary.
- binary to ASCII binary.
- two's complement binary to ASCII signed decimal.
- unsigned binary to unsigned ASCII decimal.
- binary to ASCII hexadecimal.

## Square Root
- 32-bit integer square root on 32-bit processors.
- 64-bit integer square root on 64-bit processors.

## Greatest Common Divisor
- 32-bit GCD of two unsigned 32-bit numbers on 32-bit processors.
- 64-bit GCD of two unsigned 64-bit numbers on 64-bit processors.

## Least Common Multiple
- 32-bit LCM of two unsigned 32-bit numbers on 32-bit processors.
- 64-bit LCM of two unsigned 64-bit numbers on 64-bit processors.

## Bit Operations
- Count leading zeroes in 32-bit number on 32-bit processors.
- Count leading zeroes in 64-bit number on 64-bit processors.
- Count trailing zeroes in 32-bit number on 32-bit processors.
- Count trailing zeroes in 64-bit number on 64-bit processors.

## Hash Table
- Double hashing collision resolution
- Linear probing with tombstone deletion
- Configurable table size and entry format
- O(1) average case insert, retrieve, remove operations
- Rehashing to optimize probe sequences
- Iterator interface for traversing entries

## Building

clang, lld, and make are assumed. I'm currently using clang 18.
The TARGET, ARCH, and ABI should be edited in the Makefile,
and the CPU_BITS constant should be set to match in config.s

A static library, `librvint.a`, will be created to link against.

## Tests

The test programs assume Linux syscalls are available. In particular
syscall 64 is write and 93 is exit.

## Running

- I use this emulator to run RV32I code: https://riscv-programming.org/ale/
- I'm running RV64 code on a scaleway elastic metal cloud instance: https://labs.scaleway.com/en/em-rv1/

## API

### Bit manipulation - [bits.s](src/bits.s):


```riscv

################################################################################
# routine: bits_ctz
#
# Count the number of trailing zeroes in a number via binary search - O(log n).
# This is useful for processors with no B extension. This routine provides the
# functionality of the ctz instruction (on 32-bit processors) and ctzw (on
# 64-bit processors).
#
# input registers:
# a0 = number
#
# output registers:
# a0 = result containing the number of trailing zeroes
################################################################################

################################################################################
# routine: bits_clz
#
# Count the number of leading zeroes in a number via binary search - O(log n).
# This is useful for processors with no B extension. This routine provides the
# functionality of the clz instruction (on 32-bit processors) and clzw (on
# 64-bit processors).
#
# input registers:
# a0 = number
#
# output registers:
# a0 = result containing the number of leading zeroes in the input
################################################################################
```

### Division - [div.s](src/div.s):

```riscv
################################################################################
# routine: divremu
#
# Unsigned integer division without using M extension.
# This division is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses the restoring division algorithm. It can be used to emulate
# the RISC-V M extension divu, remu, divuw, and remuw instructions.
#
# input registers:
# a0 = dividend
# a1 = divisor
#
# output registers:
# a0 = quotient
# a1 = remainder
################################################################################

################################################################################
# routine: divrem
#
# Signed integer division - rounds towards zero.
# This division is 64-bit on 64-bit CPUs and 32-bit on 32-bit CPUs.
# It uses the restoring division algorithm. It can be used to emulate
# the RISC-V M extension div, rem, divw, and remw instructions.
#
# input registers:
# a0 = dividend (N)
# a1 = divisor (D)
#
# output registers:
# a0 = quotient (Q)
# a1 = remainder (R)
################################################################################

################################################################################
# routine: div3
#
# Unsigned 32-bit integer division by 3 without using M extension. Suitable
# for RV32E.
#
# input registers:
# a0 = dividend
#
# output registers:
# a0 = quotient
################################################################################
```

### Algorithms: [gcd.s](src/gcd.s)

```riscv
################################################################################
# routine: gcd
#
# Compute the greatest common divisor (gcd) of two unsigned numbers.
# 64 bit algorithm on 64-bit CPUs, 32-bit algorithm on 32-bit CPUs.
#
# input registers:
# a0 = first number (u)
# a1 = second number (v)
#
# output registers:
# a0 = gcd(u, v)
################################################################################

################################################################################
# routine: lcm
#
# Compute the least common multiple (lcm) of two unsigned numbers.
# 64 bit algorithm on 64-bit CPUs, 32-bit algorithm on 32-bit CPUs.
#
# input registers:
# a0 = u
# a1 = v
#
# output registers:
# a0 = lcm(u,v)
################################################################################
```

### I/O and Base Conversion [io.s](src/io.s)

```riscv
################################################################################
# routine: to_hex
#
# Convert a value in a register to an ASCII hexadecimal string.
#
# input registers:
# a0 = number to convert to ascii hex
# a1 = number of bytes to convert (eg, 1, 2, 4, 8)
# a2 = 0 do not insert leading 0x, 1 insert leading 0x
#
# output registers:
# a0 = address of nul (\0)-terminated buffer with output
# a1 = length of string
################################################################################

################################################################################
# routine: to_bin
#
# Convert a value in a register to an ASCII binary string.
#
# input registers:
# a0 = number to convert to ascii binary
# a1 = number of bytes to convert (eg 1, 2, 4, 8)
# a2 = 0 do not insert spaces every 8 bits, 1 insert spaces every 8 bits
#
# output registers:
# a0 = address of nul (\0)-terminated buffer with output
# a1 = length of string
################################################################################

################################################################################
# routine: to_decu
#
# Convert a value in a register to an unsigned ASCII decimal string.
#
# input registers:
# a0 = unsigned number to convert to ascii unsigned decimal
#
# output registers:
# a0 = address of nul-terminated (\0) buffer with output
# a1 = length of string
################################################################################

################################################################################
# routine: to_dec
#
# Convert a value in a register to a signed ASCII decimal string.
#
# input registers:
# a0 = signed number to convert to ascii signed decimal
#
# output registers:
# a0 = address of nul-terminated (\0) buffer with output
# a1 = length of string
################################################################################

################################################################################
# routine: from_hex
#
# Read an ASCII hexidecimal string into a register. The parsing of the value
# stops when we read the first non-hex character.
#
# input registers:
# a0 = pointer to number to convert from hex, terminated with non-hex char.
#
# output registers:
# a0 = pointer (advanced to point to non-hex char)
# a1 = number
# a2 = error check: 0 if no digits found, otherwise 1
################################################################################

################################################################################
# routine: from_bin
#
# Read an ASCII binary string into a register. The parsing of the value
# stops when we read the first non-binary character.
#
# input registers:
# a0 = pointer to number to convert from binary, terminated with non-binary char.
#
# output registers:
# a0 = pointer (advanced to point to non-binary char)
# a1 = number
# a2 = error check: 0 if no digits found, otherwise 1
################################################################################

################################################################################
# routine: from_decu
#
# Read an ASCII unsigned decimal string into a register. The parsing of the value
# stops when we read the first non-decimal character.
#
# input registers:
# a0 = pointer to number to convert from decimal, terminated with non-decimal char.
#
# output registers:
# a0 = pointer (advanced to point to non-decimal char)
# a1 = number
# a2 = error check: 0 if no digits found, otherwise 1
################################################################################

################################################################################
# routine: from_dec
#
# Read an ASCII signed decimal string into a register. The parsing of the value
# stops when we read the first non-decimal character.
#
# input registers:
# a0 = pointer to number to convert from decimal, terminated with non-decimal char.
#
# output registers:
# a0 = pointer (advanced to point to non-decimal char)
# a1 = number
# a2 = error check: 0 if no digits found, otherwise 1
################################################################################

```

### Multiplication [mul.s](src/mul.s)

```riscv
################################################################################
# routine: nmul
#
# Native word length (64 on 64-bit processors, 32 on 32-bit processors)
# multiplication via shift-and-add technique.
#
# - RV32I: 32x32 -> 32 bit result (signed or unsigned)
# - RV64I: 64x64 -> 64 bit result (signed or unsigned)
# Implemented using only RV32I / RV64I base instructions (No 'M' Extension).
# This provides the functionality of the M extension mul/mulu/mulw instructions
#
# input registers:
# a0 = CPU_BITS-bit multiplicand
# a1 = CPU_BITS-bit multiplier
#
# output registers:
# a0 = CPU_BITS-bit product (lower bits)
################################################################################

################################################################################
# routine: mul32
#
# Unified (RV64I and RV32I) Unsigned/Signed 32x32-bit to 64-bit multiply. This
# provides the functionality of the M extension mul/mulh instructions
#
# input registers:
# a0 = op1
# a1 = op2
# a2 = signed_flag: 0=unsigned, 1=signed
#
# output registers:
# a0 = product low word
# a1 = product high word
################################################################################

################################################################################
# routine: m128
#
# 64x64-bit to 128-bit Multiplication (Signed/Unsigned) on 64-bit processors.
# This provides the functionality of the mulhu/mulhsu instructions on RV64.
#
# input registers:
# a0 = 64-bit Operand 1 (multiplicand)
# a1 = 64-bit Operand 2 (multiplier)
# a2 = Signedness flag (0 for unsigned, non-zero for signed)
#
# output registers:
# a0 = Lower 64 bits of the 128-bit product
# a1 = Upper 64 bits of the 128-bit product
################################################################################
```

### Square Root [sqrt.s](src/sqrt.s)

```riscv
################################################################################
# routine: isqrt
#
# Compute the integer square root of an unsigned number - floor(sqrt(N)).
# Algorithm: Non-restoring binary square root. On 64-bit processors this is
# a 64-bit algorithm, on 32-bit, it is 32-bits.
#
# input registers:
# a0 = n
# output registers:
# a0 = root - isqrt(n)
################################################################################

```

### Hash Table [hash.s](src/hash.s)

```riscv
################################################################################
# Hash Table Implementation
#
# A doubly-hashed open addressing hash table optimized for RISC-V.
# Features:
# - Configurable table size (default prime number 103)
# - Double hashing for collision resolution
# - Tombstone-based deletion for maintaining probe sequences
# - In-place rehashing without extra memory allocation
# - Support for both 32-bit and 64-bit architectures
# - Optimized probe sequence using conditional subtraction
# - No M-extension dependency (no hardware multiply/divide)
#
# Key functions:
# - Insertion, retrieval, and removal of key-value pairs
# - Iteration over entries
# - Memory-efficient rehashing
################################################################################

################################################################################
# routine: hash_insert
#
# Insert a key-value pair into the hash table using double hashing.
# Probes until an empty slot or tombstone is found. Uses double hashing
# for collision resolution with h1 for initial position and h2 for step size.
#
# The probing sequence is optimized to avoid expensive division operations:
# 1. Initial position = h1(key) * ELEMENTLEN
# 2. Step size = h2(key) (pre-scaled by ELEMENTLEN)
# 3. Each probe: new_pos = current_pos + step_size
# 4. Wrap using conditional subtraction since new_pos < 2 * table_size
#
# input registers:
# a0 = pointer to key string
# a1 = value to insert
#
# output registers:
# a0 = value if successful, 0 if table is full
################################################################################

################################################################################
# routine: hash_retrieve
#
# Retrieve a value from the hash table by key.
# Uses double hashing to probe until key is found or empty slot is reached.
# Handles both in-use and tombstone slots during probing.
#
# Uses the same optimized probing sequence as hash_insert.
#
# input registers:
# a0 = pointer to key string to look up
#
# output registers:
# a0 = value if found, 0 if not found
################################################################################

################################################################################
# routine: hash_remove
#
# Remove an entry from the hash table by key.
# Uses double hashing to find the entry, then marks it as a tombstone
# rather than completely clearing it to maintain probe sequences.
#
# Uses the same optimized probing sequence as hash_insert.
#
# input registers:
# a0 = pointer to key string to remove
#
# output registers:
# a0 = value that was removed if found, 0 if not found
################################################################################

################################################################################
# routine: hash_rehash
#
# Rebuild table to remove tombstones and optimize probe sequences.
# Uses in-place algorithm to avoid extra memory allocation.
#
# Uses the same optimized probing sequence as hash_insert.
#
# input registers:
# none
#
# output registers:
# a0 = number of entries rehashed
################################################################################
```

The hash table implementation provides an efficient key-value store optimized for RISC-V architectures. It uses double hashing for collision resolution, which provides better clustering properties than linear or quadratic probing. The implementation is designed to work efficiently in bare metal environments by avoiding dynamic memory allocation and expensive operations.

Key features:
- O(1) average case for insertions, retrievals and deletions
- Configurable table size (default 103)
- Support for both 32-bit and 64-bit architectures
- Memory-efficient in-place rehashing
- Maintains probe chain integrity using tombstone deletion
- Provides iteration capability over entries
- Optimized probe sequence without expensive division operations
- No dependency on M-extension (hardware multiply/divide)

The implementation uses two hash functions:
1. h1(key) - Primary hash for initial probe position
2. h2(key) - Secondary hash for probe step size (pre-scaled by ELEMENTLEN)

The probing sequence is optimized to avoid expensive division operations:
1. Initial position = h1(key) * ELEMENTLEN (using shift-and-add)
2. Step size = h2(key) (pre-scaled by ELEMENTLEN)
3. Each probe: new_pos = current_pos + step_size
4. Wrap using conditional subtraction since new_pos < 2 * table_size

Deletion is handled using tombstones to maintain probe sequences, with periodic rehashing available to reclaim space and optimize probe lengths. The rehashing algorithm is designed to work in-place without requiring additional memory allocation, making it suitable for bare metal environments.
