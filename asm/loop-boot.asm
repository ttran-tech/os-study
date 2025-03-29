; loop print_char routine and print number 7 to the screen 3 times
[bits 16]
[org 0x7c00]

start:
    mov cl, 3 ; used for loop instruction to loop 3 times
    mov cx, 5 ; print 5 time   

print_char: ; print char 3 times
    mov ah, 0eh
    mov al, 037h ; 7
    mov bx, 0
    int 10h
    loop print_char ; loop n times based on the value in CL register
halt:
    cli ; clear interrupt flag
    hlt ; halt execution

times 510-($-$$) db 0;
; boot signature 0xAA55 (little endian)
db 055h
db 0AAh