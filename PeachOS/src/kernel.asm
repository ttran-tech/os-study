[BITS 32]
global _start

CODE_SEG equ 0x08
DATA_SEG equ 0x10
VGA_MEMORY equ 0xB8000

_start:
    mov ax, DATA_SEG ; Setting up segment registers to poin to DATA_SEG
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

    mov esi, msg
    mov ah, [msg_color]
    call print_string

    jmp $

print_string:
    mov edi, VGA_MEMORY
    .print_char:
        lodsb
        cmp al, 0
        je .done
        mov [edi], al
        mov byte [edi+1], ah
        add edi, 2
        jmp .print_char
    .done:
        ret


msg: db "Hello World, Kernel! ", 0
msg_color: db 0x2F

times 512 - ($ - $$) db 0 ; add sector boundary, padding the rest of kernel sector with 0 to match 512 bytes each sector