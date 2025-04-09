# OS Dev Guideline

This file contains step by step guideline.

## Progresss Diagram
![progress.png](./assets/progress.png)

## 1. Initialize Bootloader and Reset Segment Registers

*boot.asm*

```Assembly
[ORG 0x7c00]    ; Tell the assembly memory origin starts at 0x7c00
[BITS 16]       ; 16-bit Real Mode

start:
    jmp 0:registers_reset_step1 ; Far jump to set CS = 0 (cannot directly set CS to 0)

; Reset Segment Registers Step 1
registers_reset_step1:
    cli ; disable interrupt, to prevent the CPU interrupt when resetting registers
    mov ax, 0x0000
    mov ss, ax
    mov sp, ax
    
    ; Set up SS & SP so CALL & RET instruction don't crash when using the stack
    mov ss, ax
    mov sp, 0x7c00
    call registers_reset_step2
    sti ; re-enable interrupt

; Reset Segment Registers Step 2
registers_reset_step2:
    mov ax, 0x0000
    mov ds, ax
    mov es, ax
    mov fs, ax
    ret

boot_main:
    jmp $   ; infinity jump

; Filling the remain bytes to 0
times 510 - ($-$$) db 0
dw 0xAA55
```

---
## 2. Setting up and Switching to Protected Mode

*boot.asm*

```Assembly
[ORG 0x7c00]    ; Tell the assembly memory origin starts at 0x7c00

; =================== REAL MODE SETTING ==============================================
[BITS 16]       ; 16-bit Real Mode
start:
    jmp 0:registers_reset_step1 ; Far jump to set CS = 0 (cannot directly set CS to 0)

; Reset Segment Registers Step 1
registers_reset_step1:
    cli ; disable interrupt, to prevent the CPU interrupt when resetting registers
    mov ax, 0x0000
    mov ss, ax
    mov sp, ax

    ; Set up SS & SP so CALL & RET instruction don't crash when using the stack
    mov ss, ax
    mov sp, 0x7c00
    call registers_reset_step2
    sti ; re-enable interrupt

; Reset Segment Registers Step 2
registers_reset_step2:
    mov ax, 0x0000
    mov ds, ax
    mov es, ax
    mov fs, ax
    ret

; =================== PROTECTED MODE SETTING ========================================
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

.load_protected:
    cli ; disable interrupt
    lgdt[gtd_descriptor] ; loads the address and size of GDT into the CPU’s internal GDTR register

    ; switch to Protected Mode
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    jmp CODE_SEG:load32

; Setting up Global Descriptor Table (GDT)
gdt_start:
gdt_null:   ; Always start with a null descriptor | Each descriptor is exact 8 bytes long
    dd 0x00
    dd 0x00

; Define the code segment decriptor (Offset = 0x8)
gdt_code:
    dw 0xFFFF       ; Limit Low - 16 bits
    dw 0x0000       ; Base Low - 16 bits
    db 0x00         ; Base Middle - 8 bits
    db 10011010b    ; Access Byte (Code RX, Ring 0) - 8 bits
    db 11111100b    ; Limit High + Flags - 8 bits
    db 0x00         ; High Base - 8 bits

; Define the data segment decriptor (Offset = 0x10)
gdt_data:
    dw 0xFFFF       ; Limit Low - 16 bits
    dw 0x0000       ; Base Low - 16 bits
    db 0x00         ; Base Middle - 8 bits
    db 10010010b    ; Access Byte (Data RW, Ring 0) - 8 bits
    db 11111100b    ; Limit High + Flags - 8 bits
    db 0x00         ; High Base - 8 bits

gdt_end:
    ; pass

; Define the size and starting point of GDT
gtd_descriptor:
    dw gdt_end - gdt_start - 1 ; Size of GDT (Limit)
    dd gdt_start    ; Linear address of GDT (Base)

[BITS 32]
load32:
    mov ax, DATA_SEG
    ; load all data segment register with DATA_SEG selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    ; Setting up the stack
    mov ebp, 0x00200000
    mov esp, ebp

    ; infinity loop
    jmp $

; Filling the remain bytes to 0
times 510 - ($-$$) db 0
dw 0xAA55
```

### 2.1 Debugging with `gdb`
1. Compile `nasm -f bin -o boot.bin boot.asm`

2. In terminal run `qemu-system-x86_64 -s -S -hda boot.bin`. QEMU will start but freeze to wait for input from gdb.
  - `-s` : a shorthand for -gdb tcp::1234 which start a GDB server at TCP port 1234
  - `-S` : make QEMU stop execution until you tell it to continue in GDB

3. In another terminal run:
  - 3.1 `gdb` 
  - 3.2 `target remote localhost:1234` to start gdb and connect to QEMU
  - 3.3 `break *0x7c00` set a breakpoint at 0x7c00 (the address where bootloader loaded)
    - Use `continue` or `c` to continue.
    - `layout asm` to show assembly layout.
    - `stepi` or `si` to step through each instruction.
    - `register info` or `reg info` to show all register.

---
## 3. Enable A20 Line

```Assembly
; Source: https://wiki.osdev.org/A20_Line#Fast_A20_Gate
; Modified by ttran.tech
; Test A20 and set if A20 does not set.
[bits 32]

start_protected_mode:
	jmp is_A20_on? ; test for A20 line when starting Protected Mode

enable_A20:	; enable A20 if A20 line is cleared
	in al, 0x92
	or al, 2
	out 0x92, al
	jmp is_A20_on? ; re-test A20 line

is_A20_on?:
	pushad
	mov edi,0x112345  ;odd megabyte address.
	mov esi,0x012345  ;even megabyte address.
	mov [esi],esi     ;making sure that both addresses contain diffrent values.
	mov [edi],edi     ;(if A20 line is cleared the two pointers would point to the address 0x012345 that would contain 0x112345 (edi)) 
	cmpsd             ;compare addresses to see if the're equivalent.
	popad
	jne A20_on        ;if not equivalent , A20 line is set.
	jmp enable_A20    ;if equivalent, the A20 line is cleared, jmp to enable_A20.
	
A20_on:
	; do others task here
```

---
## 4. Install Cross Compiler

### 4.1 CCross Compiler Successful Builds 
- Check for working combined version of binutils and gcc
    - [Cross Compiler Successful Builds](https://wiki.osdev.org/Cross-Compiler_Successful_Builds)

### 4.2 Downloads
- binutils-2.35: https://ftp.gnu.org/gnu/binutils/

- gcc-10.2.0: https://ftp.lip6.fr/pub/gcc/releases/gcc-10.2.0/

### 4.3 Install Dependencies
```Bash
sudo apt install build-essential -y
sudo apt install bison -y
sudo apt install flex -y
sudo apt install libgmp3-dev -y
sudo apt install libmpc-dev -y
sudo apt install libmpfr-dev -y
sudo apt-get install libmpc-dev -y
sudo apt install texinfo -y
sudo apt install libcloog-isl-dev -y
sudo apt install libisl-dev -y
```

### 4.4 Install `binutils`
```Bash
export PREFIX="$HOME/opt/cross"
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"

cd $HOME/src

mkdir build-binutils
cd build-binutils
../binutils-2.35/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror
make
make install
```

### 4.5 Install `gcc`
```Bash
export PREFIX="$HOME/opt/cross"
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"

cd $HOME/src

# The $PREFIX/bin dir _must_ be in the PATH. We did that above. MUST install binutils first.
which -- $TARGET-as || echo $TARGET-as is not in the PATH

mkdir build-gcc
cd build-gcc
../gcc-10.2.0/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers --disable-hosted-libstdcxx
make all-gcc
make all-target-libgcc
make all-target-libstdc++-v3
make install-gcc
make install-target-libgcc
make install-target-libstdc++-v3
```

### 4.6 Test New Compiler
```Bash
$HOME/opt/cross/bin/$TARGET-gcc --version
```

**Output**
```Bash
i686-elf-gcc (GCC) 10.2.0
Copyright (C) 2020 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

## 5. Load Kernel Into Memory
- Create a simple disk driver to load the kernel into memory and pass the control to the kernel.

### 5.1 Build Script (build.sh)
- This script sets up the PATH to the cross compiler installed in step 4. 
- Allows the Makefile to locate and execute GCC Cross Compiler instead of the system compiler.

```Bash
#/bin/bash
export PREFIX="$HOME/opt/cross"
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"
make all
```

### 5.2 Makefile Config
```Makefile
# Defines a variables FILES containing the objects files to be linked
# together to form the kernel binary.
FILES = ./build/kernel.asm.o

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
	i686-elf-gcc -T ./scr/linker.ld -o ./bin/kernel.bin -ffreestanding -O0 -nostdlib ./build/kernelfull.o

# Build the boot sector binary
./bin/boot.bin: ./src/boot/boot.asm
	nasm -f bin ./src/boot/boot.asm -o ./bin/boot.bin

# Assemble the kernel.asm into an object file
./build/kernel.asm.o: ./src/kernel.asm
# -f elf: tells NASM to ouput in the ELF format (Executable and Linkable Format)
	nasm -f elf -g ./src/kernel.asm -o ./build/kernel.asm.o

# clean up build
clean:
	rm -rf ./bin/boot.bin

# run
run:
	qemu-system-x86_64 -hda ./bin/boot.bin

# run qemu with remote dbg
run-remote:
	qemu-system-x86_64 -s -S -hda boot.bin
```

- This script defines how the linker should arrange the kernel binary in memory.

### 5.3 Linker Script
```LinkerScript
/* 
 * Linker Script for Kernel Debugging
 * ----------------------------------
 * This script defines how the linker should arrange the kernel binary in memory.
 * It ensures proper memory layout and symbol resolution, enabling us to debug 
 * the kernel with tools like GDB using named symbols (e.g., "break kernel_start")
 * instead of raw memory addresses.
 */
ENTRY(_start) /* Signifies the starting point of the execution in the kernel */
OUTPUT_FORMAT(binary) /* Sets the output format */
SECTIONS /* Defines memory layout of the output */
{
    . = 1M; /* Sets the start of the section at 1MB mark (match the kernel load address) */
    .text : /* Program code */
    {   /* Tells the linker to take all .text sections from the input files and put them into the .text section of the output file */
        *(.text) 
    }

    .rodata : /* Read-only data */
    {
        *(.rodata)
    }

    .data : /* Initialized data */
    {
        *(.data)
    }

    .bss : /* Unintialized data */
    {
        *(COMMON)
        *(.bss)
    }
}
```

### 5.4 Disk Driver Source Code

```Assembly
load_kernel:
    ; LBA number sectors:
    ;   0: bootloader
    ;   1: second sector
    mov eax, 1          ; load LBA number sector into EAX (second sector - kernel code)
    mov ecx, 100        ; total sectors to read, bytes = 512 * 100 = 51,200 bytes loaded
    mov edi, 0x0100000  ; the address in memory to load the sectors into
    call ata_lba_read
    ; Once the sectors loaded, jump to where the kernel was loaded
    ; and execute the kernel.asm file.
    ; CODE_SEG ensures the CS register becomes the code selector specified in the GDT
    ; enforcing the GDT code rules for execution.
    jmp CODE_SEG:0x0100000

ata_lba_read:
    mov ebx, eax    ; backup the LBA
    ; Send the hightest 8 bits of the LBA to hard disk controller
    shr eax, 24     ; EAX = 0000 0000 0000 0000
    ;
    ; Control Bit (0xE0/0xF0)
    ; 0xE0 (1110 0000): Master drive
    ; 0xF0 (1111 0000): Slave drive
    ;
    ; Bit:  7 6 5 4 3 2 1 0
    ;       1 1 1 0 0 0 0 0
    ;       V v V V \_____/   
    ;       │ │ │ │   │
    ;       │ │ │ │   │ 
    ;       │ │ │ │   │
    ;       │ │ │ │   └─ bits 24-27 of the block number (LBA addressing) (bit 0-3)
    ;       │ │ │ │
    ;       │ │ │ └─ Drive select: 1 = master, 0 = slave (bit 4)
    ;       │ │ └─ Always set 1 (bit 5)
    ;       │ └─ LBA mode: 0 = CHS Addressing, 1 = LBA Addressing (bit 6)
    ;       └─ Always set 1 (bit 7)
    ;
    or eax, 0xE0    ; set control bits (select Master drive) | EAX = 0000 0000 0000 0000 1110 0000
    mov dx, 0x1F6   ; sets dx to port 0x1F6 (Drive/Head register)
    out dx, al      ; sends request (control bytes) to Drive/Head register (port 0x1F6)

    ; Send the total sectors to read to port 0x1F2
    mov eax, ecx
    mov dx, 0x1F2   ; load port number
    out dx, al      ; send request to port

    ; *** SEND LBA BYTE TO DISK CONTROL BOARD ***
    ; Send LBA Low Byte (bit 0-7) to port 0x1F3
    mov eax, ebx    ; restore the backup LBA
    mov dx, 0x1F3   ; load port number
    out dx, al      ; send request to port

    ; Send LBA Mid Byte (bit 8-15) to port 0x1F4
    mov eax, ebx    ; restore the back LBA
    shr eax, 8
    mov dx, 0x1F4   ; load port number
    out dx, al      ; send request to port

    ; Send LBA High Byte (bit 16-23) to port 0x1F5
    mov eax, ebx
    shr eax, 16
    mov dx, 0x1F5   ; load port number
    out dx, al      ; send request to port
    ; *** FINISH SEND LBA BYTE ***

    ; Send READ command to port 0x1F7
    mov al, 0x20
    mov dx, 0x1F7   ; load port number
    out dx, al      ; send request to port

    ; Read all sectors into memory
.next_sector:
    push ecx

    ; Check for READ status from disk
.try_again:
    mov dx, 0x1F7
    in al, dx
    test al, 8
    jz .try_again

    ; Read 256 words (512 bytes) at a time
    mov ecx, 256
    mov edx, 0x1F0
    rep insw
    pop ecx
    loop .next_sector
    ret
```
