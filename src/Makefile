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
AR_SRCS	:= div.s div3u.s div5u.s div6u.s div7u.s div9u.s div10u.s div11u.s div12u.s \
		div13u.s div100u.s div1000u.s div3.s div5.s div6.s div7.s div9.s div10.s \
		div11.s div12.s div13.s div100.s div1000.s divrem.s mul128.s nmul.s \
		mul32.s io.s sqrt.s gcd.s bits.s
SRCS	:= $(TST_SRCS) $(AR_SRCS)
OBJS	:= $(AR_SRCS:.s=.o)
TST_OBJS:= $(TST_SRCS:.s=.o)
EXES	:= $(TST_SRCS:.s=.x)
LIB	:= librvint.a

.PHONY:	all clean

all: $(EXES) $(LIB)

%.o: %.s config.s mul-macs.s
	$(CC) $(CFLAGS) -c $< -o $@

$(EXES): %x: %o $(LIB)
	$(LD) $(LDFLAGS) $^ -o $@

$(LIB): $(OBJS)
	$(AR) $(ARFLAGS) $(LIB) $(OBJS)

clean:
	rm -f $(OBJS) $(TST_OBJS) $(EXES) $(LIB)
