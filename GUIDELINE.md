# OS Dev Guideline

This file contains step by step guideline.

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