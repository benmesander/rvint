.include "config.s"

.bss
# I/O buffer used by to_*.s routines for output
.globl iobuf
.comm iobuf, IOBUF_SIZE, 4


