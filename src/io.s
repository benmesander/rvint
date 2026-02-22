.include "config.s"
.include "mul-macs.s"


.bss
.globl iobuf
.comm iobuf, IOBUF_SIZE, 4

.text


