# edit config.s to match target
# RV64GC
#TARGET	?=riscv64
#ARCH	?=rv64gc
#ABI	?=lp64

#RV32GC
TARGET	?=riscv32
ARCH	?=rv32gc
ABI	?=ilp32d

#CH32V003 - RV32E 
#TARGET	?=riscv32
#ARCH	?=rv32ec_zicsr
#ABI	?=ilp32e

CC	:= clang
LD	:= ld.lld
CFLAGS	:= --target=$(TARGET) -march=$(ARCH) -mabi=$(ABI)
LDFLAGS	:=

SRCS	:= div.s mul.s io.s div-tests.s mul-tests.s sqrt.s alg-tests.s gcd.s bits.s
OBJS	:= $(SRCS:.s=.o)
EXES	:= div-tests.x mul-tests.x alg-tests.x 
LIB	:= librvint.a

DIV_TESTS_OBJS	:= div-tests.o div.o io.o
MUL_TESTS_OBJS	:= mul-tests.o mul.o io.o div.o
ALG_TESTS_OBJS	:= alg-tests.o mul.o sqrt.o io.o div.o gcd.o bits.o

.PHONY:	all clean

all: $(EXES) $(LIB)

%.o: %.s
	$(CC) $(CFLAGS) -c $< -o $@

div.o:	div.s config.s mul-macs.s
mul.o:	mul.s config.s
io.o:	io.s config.s
sqrt.o:	sqrt.s config.s
gcd.o:	gcd.s config.s
bits.o:	bits.s config.s

div-tests.x: div-tests.o $(LIB) 
	$(LD) $(LDFLAGS) $^ -o $@

mul-tests.x: mul-tests.o $(LIB) 
	$(LD) $(LDFLAGS) $^ -o $@

alg-tests.x: alg-tests.o $(LIB)
	$(LD) $(LDFLAGS) $^ -o $@

$(LIB): $(OBJS)
	$(AR) $(ARFLAGS) $(LIB) $(OBJS)

clean:
	rm -f $(OBJS) $(EXES) $(LIB)
