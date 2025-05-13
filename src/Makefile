all: div-tests.x

div.o: div.s config.s
	clang --target=riscv32 -march=rv32gc -mabi=ilp32d div.s -c -o div.o

div-tests.o: div-tests.s config.s
	clang --target=riscv32 -march=rv32gc -mabi=ilp32d div-tests.s -c -o div-tests.o

div-tests.x: div-tests.o div.o
	ld.lld div.o div-tests.o -o div-tests.x

clean:
	rm *.o *.x
