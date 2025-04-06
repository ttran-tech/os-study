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

```
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

Downloads:

binutils-2.35: https://ftp.gnu.org/gnu/binutils/

gcc-10.2.0: https://ftp.lip6.fr/pub/gcc/releases/gcc-10.2.0/

```
sudo apt install build-essential
sudo apt install bison
sudo apt install flex
sudo apt install libgmp3-dev
sudo apt install libmpc-dev
sudo apt install libmpfr-dev
sudo apt-get install libmpc-dev
sudo apt install texinfo
sudo apt install libcloog-isl-dev
sudo apt install libisl-dev 

###### Install binutils #######################################################
export PREFIX="$HOME/opt/cross"
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"

cd $HOME/src

mkdir build-binutils
cd build-binutils
../binutils-2.35/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror
make
make install

###### Install GCC #######################################################

export PREFIX="$HOME/opt/cross"
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"

cd $HOME/src

# The $PREFIX/bin dir _must_ be in the PATH. We did that above.
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