# Defines a variables FILES containing the objects files to be linked
# together to form the kernel binary.
FILES = ./build/kernel.asm.o ./build/kernel.o
INCLUDES = -I./src
FLAGS = -g -ffreestanding -falign-jumps -falign-functions -falign-labels -falign-loops -fstrength-reduce -fomit-frame-pointer -finline-functions -fno-builtin -Wno-unused-function -Wno-unused-label -Wno-unused-paramater -Werror -nostdlib -nostartfiles -nodefaultlibs -Wall -O0 -Iinc

###############################################################################
# Syntax
# Target: Dependency_1 Dependency_2
#	Command_1
#	Command_2
###############################################################################

# Build all target
all: ./bin/boot.bin ./bin/kernel.bin
# Remove old os.bin, -rf recursive and force to remove all files and directories
	rm -rf ./bin/os.bin
# Concatenate *.bin files into a single os.bin in sector order:
# 	Sector 0: boot.bin
# 	Sector 1: kernel.bin
# if: input file
	dd if=./bin/boot.bin >> ./bin/os.bin
	dd if=./bin/kernel.bin >> ./bin/os.bin
# Padding the rest of the file with zeros in multiple of 512 (block size * # of empty sectors).
# bs = block size.
# count = # of empty sectors.
	dd if=/dev/zero bs=512 count=100 >> ./bin/os.bin

# Build the kernel sector binary.
./bin/kernel.bin: $(FILES)
# i686-elf-ld: link the object files (*.o) into a single object file.
# -g: enable debugging information.
# -relocatable: tells the linnker to create a relocatable output.
#				the object files can be used as input to the linker again.
# kernelfull.o: contains all the code that will be in the final kernel binary
	i686-elf-ld -g -relocatable $(FILES) -o ./build/kernelfull.o
# i686-elf-gcc: link the object files into a binary using the linker script (-T <path to linker script>).
# -ffreestanding: freestanding code (not hosted by an OS).
# -O0: no optimize.
# -nostdlib: no link to standard libraries.
	i686-elf-gcc $(FLAGS) -T ./src/linker.ld -o ./bin/kernel.bin -ffreestanding -O0 -nostdlib ./build/kernelfull.o

# Build the boot sector binary
./bin/boot.bin: ./src/boot/boot.asm
	nasm -f bin ./src/boot/boot.asm -o ./bin/boot.bin

# Assemble the kernel.asm into an object file
./build/kernel.asm.o: ./src/kernel.asm
# -f elf: tells NASM to ouput in the ELF format (Executable and Linkable Format)
	nasm -f elf -g ./src/kernel.asm -o ./build/kernel.asm.o

./build/kernel.o: ./src/kernel.c
	i686-elf-gcc $(INCLUDES) $(FLAGS) -std=gnu99 -c ./src/kernel.c -o ./build/kernel.o

# clean up build
clean:
	rm -rf ./bin/boot.bin
	rm -rf ./bin/kernel.bin
	rm -rf ./bin/os.bin
	rm -rf $(FILES)
	rm -rf ./build/kernelfull.o
	
# run
run:
	qemu-system-x86_64 -hda ./bin/os.bin

# run qemu with remote dbg
dbg:
	qemu-system-x86_64 -s -S -hda ./bin/os.bin


# gdb internal debug
# target remote | qemu-system-x86_64 -S -gdb stdio -hda ./bin/os.bin