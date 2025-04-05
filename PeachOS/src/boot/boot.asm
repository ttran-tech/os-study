[ORG 0x7c00]    ; Tell the assembly memory origin starts at 0x7c00

; =================== REAL MODE SETTING ==============================================
[BITS 16]       ; 16-bit Real Mode
start:
    jmp 0:registers_reset_step1 ; Far jump to set CS = 0 (cannot directly set CS to 0)

; Reset Segment Registers Step 1
registers_reset_step1:
    cli ; disable interrupt, to prevent the CPU interrupt when resetting registers
    mov ax, 0x0000

    ; Set up SS & SP so CALL & RET instruction don't crash when using the stack
    mov ss, ax
    mov sp, 0x7c00
    call registers_reset_step2
    sti ; re-enable interrupt
    jmp load_protected

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
VGA_MEMORY equ 0xB8000

load_protected:
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
    mov esi, msg_A20_on             ; prepare the string to call print_string function
    mov ah, [msg_A20_on_color]    ; add color code
    call print_string
    hang:
        ; infinity loop
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


msg_A20_on: db "A20 is on ", 0
msg_A20_on_color: db 0x2F
msg_A20_off: db "A20 is off ", 0
msg_A20_off_color: db 0xCF

; Filling the remain bytes to 0
times 510 - ($-$$) db 0
dw 0xAA55