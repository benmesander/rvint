# edit config.s to match target
TARGET	?=riscv64
ARCH	?=rv64gc
ABI	?=lp64

#TARGET	?=riscv32
#ARCH	?=rv32gc
#ABI	?=ilp32d
CC	:= clang
LD	:= ld.lld
CFLAGS	:= --target=$(TARGET) -march=$(ARCH) -mabi=$(ABI)
LDFLAGS	:=

SRCS	:= div.s mul.s io.s div-tests.s mul-tests.s sqrt.s alg-tests.s gcd.s bits.s
OBJS	:= $(SRCS:.s=.o)
EXES	:= div-tests.x mul-tests.x alg-tests.x

DIV_TESTS_OBJS	:= div-tests.o div.o
MUL_TESTS_OBJS	:= mul-tests.o mul.o io.o div.o
ALG_TESTS_OBJS	:= alg-tests.o mul.o sqrt.o io.o div.o gcd.o bits.o

.PHONY:	all clean

all: $(EXES)

%.o: %.s
	$(CC) $(CFLAGS) -c $< -o $@

div.o:	div.s config.s
mul.o:	mul.s config.s
io.o:	io.s config.s
sqrt.o:	sqrt.s config.s
gcd.o:	gcd.s config.s
bits.o:	bits.s config.s

div-tests.x: $(DIV_TESTS_OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

mul-tests.x: $(MUL_TESTS_OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

alg-tests.x: $(ALG_TESTS_OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

clean:
	rm -f $(OBJS) $(EXES)
