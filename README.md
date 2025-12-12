# rvint

Integer-based mathematical subroutines which implement RISC-V M and B
extension functionality on I, and Zmmul instruction sets. There is
partial support for the reduced functionality E instruction set
where this is easy to do and doesn't involve a performance tradeoff.

These routines are designed to be both concise and efficient, although
where those two goals clash, I went with concise.

![Screenshot of tests](rvint.png "Screenshot of tests")


## Division

### On 32-bit processors (RV32I, RV32E)
- 32-bit by 32-bit signed and unsigned division with 32-bit result and remainder.
- Fast 32-bit unsigned division by 3
- Fast 32-bit unsigned division by 5
- Fast 32-bit unsigned division by 6
- Fast 32-bit unsigned division by 7 (no tests)
- Fast 32-bit unsigned division by 9 (no tests)
- Fast 32-bit unsigned division by 10
- Fast 32-bit unsigned division by 11 (no tests)
- Fast 32-bit unsigned division by 12 (no tests)
- Fast 32-bit unsigned division by 13 (no tests)
- Fast 32-bit unsigned division by 100 (no tests)
- Fast 32-bit unsigned division by 1000 (no tests)
- Fast 32-bit signed division by 3 (no tests)
- Fast 32-bit signed division by 5 (no tests)
- Fast 32-bit signed division by 6 (no tests)
- Fast 32-bit signed division by 7 (no tests)
- Fast 32-bit signed division by 9 (no tests)
- Fast 32-bit signed division by 10 (no tests)
- Fast 32-bit signed division by 11 (no tests)
- Fast 32-bit signed division by 12 (no tests)
- Fast 32-bit signed division by 13 (no tests)
- Fast 32-bit signed division by 100 (no tests)
- Fast 32-bit signed division by 1000 (no tests)

### On 64-bit processors (RV64I)
- 64-bit by 64-bit signed and unsigned division with 64-bit result and remainder.
- Fast 64-bit unsigned division by 3
- Fast 64-bit unsigned division by 5
- Fast 64-bit unsigned division by 6
- Fast 64-bit unsigned division by 7 (no tests)
- Fast 64-bit unsigned division by 9 (no tests)
- Fast 64-bit unsigned division by 10
- Fast 64-bit unsigned division by 11 (no tests)
- Fast 64-bit unsigned division by 12 (no tests)
- Fast 64-bit unsigned division by 13 (no tests)
- Fast 64-bit unsigned division by 100 (no tests)
- Fast 64-bit unsigned division by 1000 (no tests)
- Fast 64-bit signed division by 3 (no tests)
- Fast 64-bit signed division by 5 (no tests)
- Fast 64-bit signed division by 6 (no tests)
- Fast 64-bit signed division by 7 (no tests)
- Fast 64-bit signed division by 9 (no tests)
- Fast 64-bit signed division by 10 (no tests)
- Fast 64-bit signed division by 11 (no tests)
- Fast 64-bit signed division by 12 (no tests)
- Fast 64-bit signed division by 13 (no tests)
- Fast 64-bit signed division by 100 (no tests)
- Fast 64-bit signed division by 1000 (no tests)

## Multiplication

### On 32-bit processors (RV32E, RV32I):
- 32-bit by 32-bit signed and unsigned multiplication with 32-bit result.
- 32-bit by 32-bit signed and unsigned multiplication with 64-bit result.

### on 64-bit processors (RV64i):
- 32-bit by 32-bit signed and unsigned multiplication with 64-bit result.
- 64-bit by 64-bit signed and unsigned multiplication with 64-bit result.
- 64-bit by 64-bit signed and unsigned multiplication with 128-bit result.

## Base Conversions & I/O Operations

These operations support 32-bit numbers on 32-bit architectures and
64-bit numbers on 64-bit architectures. All routines are RV32E, RV32I,
and RV64I compatible.

- ASCII binary to binary.
- ASCII unsigned decimal to binary.
- ASCII signed decimal to two's complement binary.
- ASCII hexadecimal to binary.
- binary to ASCII binary.
- two's complement binary to ASCII signed decimal.
- unsigned binary to unsigned ASCII decimal.
- binary to ASCII hexadecimal.

## Square Root (RV32E, RV32I, and RV64I compatible)
- 32-bit integer square root on 32-bit processors.
- 64-bit integer square root on 64-bit processors.

## Greatest Common Divisor (RV32E, RV32I, and RV64I compatible)
- 32-bit GCD of two unsigned 32-bit numbers on 32-bit processors.
- 64-bit GCD of two unsigned 64-bit numbers on 64-bit processors.

## Least Common Multiple (RV32E, RV32I, and RV64I compatible)
- 32-bit LCM of two unsigned 32-bit numbers on 32-bit processors.
- 64-bit LCM of two unsigned 64-bit numbers on 64-bit processors.

## Bit Operations (RV32E, RV32I, and RV64I compatible)
- Count leading zeroes in 32-bit number on 32-bit processors.
- Count leading zeroes in 64-bit number on 64-bit processors.
- Count trailing zeroes in 32-bit number on 32-bit processors.
- Count trailing zeroes in 64-bit number on 64-bit processors.

## Building

clang, lld, and make are assumed. I'm currently using clang 18.
The TARGET, ARCH, and ABI should be edited in the Makefile,
and the CPU_BITS constant should be set to match in config.s
HAS_... flags should be set for available extensions.

A static library, `librvint.a`, will be created to link against.

Only certain routines support RV32E. The routines that do not
currently give compile errors; this will be fixed in the future. RV64E
is not a focus as I am unaware of any real world implementations. The
Makefile has a CH32V003 target that is an RV32EC_zicsr target.

## Tests

The test programs assume Linux syscalls are available. In particular
syscall 64 is write and 93 is exit.

## Running

- I use this emulator to run RV32I code: https://riscv-programming.org/ale/
- I'm running RV64 code on a scaleway elastic metal cloud instance: https://labs.scaleway.com/en/em-rv1/

## API

### Bit manipulation - [bits.s](src/bits.s):

---

These routines implement functionality in the ZBB ISA extension for CPUs which do not have
this available. Despite being efficiently implemented (they run in O(log n) time), they are
heavyweight enough that they are not useful in places like inner loops in division routines.

---

#### bits_ctz

Count number of trailing zeroes on CPUs with no ZBB extension. O(log n). RV32E/RV32I/RV64I compatible.

| Configuration       | Cycles (32) | Cycles (64) |
|--------------|-------------|-------------|
| Best Case    | 3           | 3           |
| Average Case | ~21         | ~25         |
| Worst Case   | 23          | 27          |

##### Input
a0 = number

##### Output
a0 = count of trailing zeroes

---

#### bits_clz

Count number of leading zeroes on CPUs with no ZBB extension. O(log n). RV32E/RV32I/RV64I compatible.

| Configuration       | Cycles (32) | Cycles (64) |
|--------------|-------------|-------------|
| Best Case    | 3           | 3           |
| Average Case | ~21         | ~25         |
| Worst Case   | 23          | 27          |

##### Input
a0 = number

##### Output
a0 = count of leading zeroes

---

### Division - [div.s](src/div.s):

Signed and unsigned division for CPUs without dividers.

The initial implementation of divremu came from the division routine in the rvmon monitor.
I believe this code originally came from Bruce Hout on reddit. It has been heavily extended
to minimize the number of cycles by using ISA extensions and restructuring the code by
selectively unrolling parts. The divrem routine is a wrapper which enables signed division.

---

#### divremu

Unsigned integer division for CPUs without M extension. RV32E/RV32I/RV64I compatible.
Restoring division algorithm. Available in ROLLED (compact) and UNROLLED (faster) versions
(this is selected in config.s with the DIVREMU_UNROLLED flag). Worst-case performance:

| Configuration                     | Cycles (32) | Cycles (64) |
|----------------------------|-------------|-------------|
| Base ISA (Rolled)          | 455         | 903         |
| Base ISA (Unrolled)        | 351         | 695         |
| With Extensions (Rolled)   | 391         | 775         |
| With Extensions (Unrolled) | 287         | 567         |

##### Input
a0 = dividend
a1 = divisor

##### Output
a0 = quotient
a1 = remainder

---

#### divrem

Signed integer division that rounds towards zero. RV32E/RV32I/RV64I compatible
restoring division algorithm. Uses divremu, so performance depends upon whether
that routine is used in ROLLED or UNROLLED form. Worst case performance:

| Configuration                     | Cycles (32) | Cycles (64) |
|----------------------------|-------------|-------------|
| Base ISA (Rolled)          | 496         | 944         |
| Base ISA (Unrolled)        | 392         | 736         |
| With Extensions (Rolled)   | 430         | 814         |
| With Extensions (Unrolled) | 326         | 606         |

##### Input
a0 = dividend
a1 = divisor

##### Output
a0 = quotient
a1 = remainder

---

The following division routines are branchless, straight line code
that execute in a fixed number of cycles for all inputs, and thus are
suitable for cryptographic applications.

Initial implementation was done from Hacker's Delight, 2nd edition. The
algorithms were extended to 64 bits, and agressively optimized using the
peculiar features of the RISC-V ISA to minimize the cycle count. The
algorithmic approach is to use a series expansion to estimate the quotient,
then an estimated remainder is calculated, and the quotient is corrected.

---

#### div3u 

Unsigned integer divide by 3. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 15          | 17          |
| With Extensions | 14          | 16          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div5u 

Unsigned integer divide by 5. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 15          | 17          |
| With Extensions | 14          | 16          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div6u 

Unsigned integer divide by 6. You may be better off calling div3u and
shifting the result. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 18          | 22          |
| With Extensions | 17          | 21          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div7u 

Unsigned integer divide by 7. Note that only the base ISA is used here, so there
is no accelleration from ISA extensions. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 16          | 20          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div9u

Unsigned integer divide by 9. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 15          | 17          |
| With Extensions | 14          | 16          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div10u

Unsigned integer divide by 10. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 16          | 18          |
| With Extensions | 15          | 17          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div11u

Unsigned integer divide by 11.  RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 18          | 20          |
| With Extensions | 15          | 17          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div12u

Unsigned integer divide by 12.  RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 17          | 19          |
| With Extensions | 16          | 18          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div13u

Unsigned integer divide by 13. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 18          | 20          |
| With Extensions | 16          | 18          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div100u

Unsigned integer divide by 100. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 10          | 21          |
| With Extensions | 17          | 19          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div1000u

Unsigned integer divide by 1000. This basically divides by 10, then by 100. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 37          | 41          |
| With Extensions | 35          | 39          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div3

Signed integer divide by 3. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 24          | 26          |
| With Extensions | 23          | 25          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div5

Signed integer divide by 5. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 24          | 26          |
| With Extensions | 23          | 25          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div6

Signed integer divide by 6. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 27          | 31          |
| With Extensions | 26          | 30          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div7

Signed integer divide by 7. Note that ISA extensions are not used by this routine. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 25          | 29          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div9

Signed integer divide by 9. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 24          | 26          |
| With Extensions | 23          | 25          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div10

Signed integer divide by 10. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 25          | 27          |
| With Extensions | 24          | 26          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div11

Signed integer divide by 11. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 27          | 29          |
| With Extensions | 24          | 26          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div12

Signed integer divide by 12. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 26          | 28          |
| With Extensions | 25          | 27          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div13

Signed integer divide by 13. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 27          | 31          |
| With Extensions | 25          | 29          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div100

Signed integer divide by 100. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 24          | 26          |
| With Extensions | 22          | 24          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### div1000

Signed integer divide by 1000. I was able to slightly change the
series expansion for 63 bit numbers (one bit reserved for sign), thus
the signed divide by 1000 is one cycle shorter than the unsigned
divide by 1000 on 64-bit architectures! RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 39          | 41          |
| With Extensions | 36          | 38          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

The below remainder routines are based on Hacker's Delight 2nd Edition, but this 
and the other remainder routines I didn't implement are of limited utility
as it's faster to calculate the quotient and calculate the remainder from
that.

I could modify the above routines to also return the remainder in addition	
to the quotient, which seems useful, but would likely cost 3-4
instructions per routine. Not yet sure if I want to do this or not, I'm interested
which approach library users would find most helpful.

These routines run in constant time and are branchless.

---

#### mod3u

unsigned integer remainder after division by 3. RV32E/RV32I/RV64I

| Configuration          | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 21          | 23          |
| With Extensions | 19          | 21          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

#### mod3

signed integer remainder after division by 3. RV32E/RV32I/RV64I

| Configuration   | Cycles (32) | Cycles (64) |
|-----------------|-------------|-------------|
| Base ISA        | 24          | 26          |
| With Extensions | 22          | 24          |

##### Input
a0 = dividend

##### Output
a0 = quotient

---

### Algorithms: [gcd.s](src/gcd.s)

---

These routines calculate the greatest common divisor (gcd) and least
common multiple (lcm) of two numbers. They can take advantage of the M
and Zbb extensions, if available.

---

#### gcd

Computes greatest common divisor of two numbers, gcd(u,v). Can take
advantage of M and Zbb extensions. With M extension it uses Euclid's
algorithm. If M is not present, it computes the gcd via Stein's
algorithm. O(log n). RV32E/RV32I/RV64I

Average Cycle Counts

| Configuration | Cycles (32) | Cycles (64) |
|---------------|-------------|-------------|
| Base ISA      | ~500        | ~1000       |
| With Zbb      | ~150        | ~300        |
| With M        | ~100        | ~400        |

##### Input
a0 = u<br>
a1 = v

##### Output
a0 = result

---

#### lcm

Computes the least common multiple of two numbers, lcm(u, v). Computes
via lcm(u,v) = (u / gcd(u,v)) * v.  Can take advantage of M and Zbb
extensions. O(log n). RV32E/RV32I/RV64I

Average cycle counts

| Configuration | Cycles (32) | Cycles (64) |
|---------------|-------------|-------------|
| Base ISA      | ~1200       | ~2500       |
| With Zbb      | ~750        | ~1500       |
| With M        | ~250        | ~500        |

##### Input
a0 = u<br>
a1 = v

##### Output
a0 = result

---

### I/O and Base Conversion [io.s](src/io.s)

---

#### to_hex

Convert a value in a register to an ASCII hexadecimal string. RV32E/RV32I/RV64I

Cycle Counts

| Configuration | Prefix? (a2) | Cycle Count | Notes |
|---------------|--------------|-------------|-------|
| 8-bit (Byte)  | No           | 31          | 2 nibbles |
| 32-bit (Word) | No           | 97          | 8 nibbles |
| 32-bit (Word) | Yes (0x)     | 100         | Add prefix overhead |
| 64-bit (Long) | No           | 185         | 16 nibbles (RV64 only) |
 
##### Input
a0 = number to convert to ASCII hex<br>
a1 = number of bytes to convert (eg 1, 2, 4, 8)<br>
a2 = 0 do not insert leading 0x, 1 insert leading 0x

##### Output
a0 = address of nul (\0) terminated buffer with output<br>
a1 = length of string

---

#### to_bin

Convert a value in a register to an ASCII binary string. RV32E/RV32I/RV64I

Cycle Counts with a2=3

| Configuration | Input Width | Cycle Count |
|---------------|-------------|-------------| 
| Base ISA      | 32          | 438         |
| Base ISA      | 64          | 870         |
| With Zbs      | 32          | 406         |
| With Zbs      | 64          | 806         |

##### Input
a0 = number to convert to ascii binary<br>
a1 = number of bytes to convert (eg 1, 2, 4, 8)<br>
a2 = flags (0=none, 1=0b prefix, 2=spaces every 8 bits, 3=both)

##### Output
a0 = address of nul (\0)-terminated buffer with output<br>
a1 = length of string

---

#### to_decu

Convert a value in a register to an ASCII unsigned decimal string. RV32E/RV32I/RV64I/RV128I
This routine has an inline implemention of the div10u series expansion in it.


| Configuration | Cycles (32) | Cycles (64) | Cycles (128) |
|---------------|-------------|-------------|--------------|
| Base ISA      | 230         | 590         | 1,450        |
| Base + Zba    | 194         | 495         | 1,220        |
| Base + M      | ~410        | ~850        | Not recommended|

##### Input
a0 = unsigned number to convert to ascii decimal

##### Output
a0 = address of nul (\0)-terminated buffer with output<br>
a1 = length of string

---

#### to_dec

Convert a value in a register to an ASCII signed decimal string. RV32E/RV32I/RV64I/RV128I
This routine is a wrapper around to_decu.

| Configuration | Cycles (32) | Cycles (64) | Cycles (128) |
|---------------|-------------|-------------|--------------|
| Base ISA      | ~245        | ~605        | ~1,465       |
| Base + Zba    | ~209        | ~510        | ~1,235       |
| Base + M      | ~425        | ~865        | Not recommended|

##### Input
a0 = signed number to convert to ascii decimal

##### Output
a0 = address of nul (\0)-terminated buffer with output<br>
a1 = length of string

---






```riscv
################################################################################
# routine: to_hex
#
# Convert a value in a register to an ASCII hexadecimal string.
# RV32E compatible
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
# RV32E compatible.
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
# RV32E compatible
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
# RV32E compatible.
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
# RV32E compatible.
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
# RV32E compatible.
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
# RV32E compatible.
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

