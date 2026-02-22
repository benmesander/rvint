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

TST_SRCS:= div-tests.s mul-tests.s alg-tests.s
AR_SRCS	:= div.s divrem.s mul128.s nmul.s mul32.s io.s sqrt.s gcd.s bits.s
SRCS	:= $(TST_SRCS) $(AR_SRCS)
OBJS	:= $(AR_SRCS:.s=.o)
EXES	:= $(TST_SRCS:.s=.x)
LIB	:= librvint.a

.PHONY:	all clean

all: $(EXES) $(LIB)

%.o: %.s config.s mul-macs.s
	$(CC) $(CFLAGS) -c $< -o $@

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
