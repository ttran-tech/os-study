all : boot.asm
	nasm -f bin -o boot.bin boot.asm

clean:
	rm -f boot.bin boot.o boot.elf

run:
	qemu-system-x86_64 -hda boot.bin

run-remote:
	qemu-system-x86_64 -s -S -hda boot.bin