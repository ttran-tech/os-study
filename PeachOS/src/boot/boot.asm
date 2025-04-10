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
; Starts Protected Mode
start_protected_mode:
	jmp is_A20_on? ; test for A20 line when starting Protected Mode

; ; Enables A20 line
enable_A20:
	in al, 0x92
	or al, 2
	out 0x92, al
	jmp is_A20_on? ; re-test A20 line

; ; Test if A20 line is enabled
is_A20_on?:
	pushad
	mov edi,0x112345  ; odd megabyte address.
	mov esi,0x012345  ; even megabyte address.
	mov [esi],esi     ; making sure that both addresses contain diffrent values.
	mov [edi],edi     ; (if A20 line is cleared the two pointers would point to the address 0x012345 that would contain 0x112345 (edi)) 
	cmpsd             ; compare addresses to see if the're equivalent.
	popad
	jne A20_on        ; if not equivalent , A20 line is set.
	jmp enable_A20    ; if equivalent, the A20 line is cleared, jmp to enable_A20.

A20_on:
    jmp load_kernel

; LOAD THE KERNEL
load_kernel:
    ; LBA number sectors:
    ;   0: bootloader
    ;   1: second sector
    mov eax, 1          ; load LBA number sector into EAX (second sector - kernel code)
    mov ecx, 100        ; total number of sectors to read, bytes = 512 * 100 = 51,200 bytes loaded (ECX = sector count)
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
    push ecx    ; temporary saves sector count to the stack

    ; Check for READ status from disk
.try_again:
    mov dx, 0x1F7   ; set status port of ATA (hard drive)
    in al, dx       ; read status into AL
    test al, 8      ; test the 3rd bit (bit 3 = DRQ "data request")
    jz .try_again   ; try again if not ready

    ; Read 256 words (512 bytes) at a time
    mov ecx, 256
    mov edx, 0x1F0
    rep insw
    pop ecx
    loop .next_sector
    ret

; Filling the remain bytes to 0
times 510 - ($-$$) db 0
dw 0xAA55
