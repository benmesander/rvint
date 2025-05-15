# edit config.s to match target
TARGET?=riscv64
ARCH?=rv64gc
ABI?=lp64

#TARGET?=riscv32
#ARCH?=rv32gc
#ABI?=ilp32d

all: div-tests.x mul-tests.x

div.o: div.s config.s 
	clang --target=$(TARGET) -march=$(ARCH) -mabi=$(ABI) div.s -c -o div.o

mul.o: mul.s config.s
	clang --target=$(TARGET) -march=$(ARCH) -mabi=$(ABI) mul.s -c -o mul.o

div-tests.o: div-tests.s config.s div.s
	clang --target=$(TARGET) -march=$(ARCH) -mabi=$(ABI) div-tests.s -c -o div-tests.o

mul-tests.o: mul-tests.s config.s mul.s
	clang --target=$(TARGET) -march=$(ARCH) -mabi=$(ABI) mul-tests.s -c -o mul-tests.o

div-tests.x: div-tests.o div.o
	ld.lld div.o div-tests.o -o div-tests.x

mul-tests.x: mul-tests.o mul.o
	ld.lld mul.o mul-tests.o -o mul-tests.x


clean:
	rm *.o *.x
