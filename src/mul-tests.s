.globl _start
_start:

test1:

_end:
	
        li a0, 0            # exit code
        li a7, 93           # syscall exit
        ecall
