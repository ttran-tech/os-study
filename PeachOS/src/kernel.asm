[BITS 32]
global _start
extern kernel_main ; notify NASM kernel_main is a external function

CODE_SEGMENT equ 0x08 
DATA_SEGMENT equ 0x10

_start:
    mov ax, DATA_SEGMENT ; Setting up segment registers to poin to DATA_SEG
    ; load all data segment register with DATA_SEG selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Setting up the stack pointer to 0x200000,
    ; any stack operations will start at 0x200000
    mov ebp, 0x00200000 
    mov esp, ebp
    
    ; Enable the A20 line
    in al, 0x92
    or al, 2
    out 0x92, al

    call kernel_main ; call kernel_main which defined in C code

    jmp $

; add sector boundary, padding the rest of kernel sector with 0 to match 512 bytes each sector
times 512 - ($ - $$) db 0 