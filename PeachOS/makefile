all : boot.bin
	nasm -f bin -o boot.bin boot.asm

clean:
	rm -f boot.bin

run:
	qemu-system-x86_64 -hda boot.bin


