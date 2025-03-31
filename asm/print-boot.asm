[ORG 0x7c00]
[BITS 16]

start:
    jmp 0:reset_segment_registers

reset_segment_registers:
    cli ; disable interrupt when reseting registers
    mov ax, 0x00
    ; set all segment registers to 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov es, ax
    mov sp, 0x7c00 ; set up stack starts at 0x7c00
    sti ; re-enable interrupt

print_string:
    mov bx, 0
    mov si, message ; copy message to source index register
    cld ; to ensure lodsb increases SI register after each acess

put_char:
    lodsb ; load byte from DS:SI (message) into AL
    cmp al, 0
    je halt ; done when AL = 0
    mov ah, 0x0e
    int 0x10
    jmp put_char

halt:
    cli
    hlt

message: db "Hello World", 0
times 510-($-$$) db 0
dw 0xAA55