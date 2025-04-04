; Extract 0x4A1B (0100 1010 0001 1011) and print as 4A1B
; 1. use AND to bitmask 0xF0 to extract the first digit
; 2. either convert it to string char or number char
; 3. shift the original value to the right 4 times (4 bits each digit)
; 4. Repeat 1
[bits 16]
[org 7c00h]

start:
	mov ax, 0x4A1B	; load value into AX register
	mov cx, 4 ; loop 4 times
	
extract_char:
	mov bl, ah ; copy the AH  to BL (BL = 4A)
	and bl, 0F0h ; AND BL with bitmask 0xF0 to extract the first character and store the character in BL (BL = 40)
	shr bl, 4  ; shift bl to the right 4 bits (BL = 04)
    cmp bl, 0Ah ; compare to 10, less than 10 is number, greater than 10 is one the letter from A to F
	jl extract_number ; jump to extract_number if BL is less than 10
	add bl, 37h ; convert A~F to character by adding 0x37 (or 55 in decimal)
				; Example: A = 10 in decimal, 10 + 55 = 65 and 65 is ASCII code for 'A'
	jmp print_char

extract_number:
	add bl, 30h
	jmp print_char

print_char:
	push ax	; push AX into the stack to retain the original value
	mov ah, 0eh
	mov al, bl
	mov bx, 0
	int 10h
	pop ax ; restore original value back to AX
	jmp shift_left_ax

shift_left_ax:
	shl ax, 4 ; shift the original value to the left 4 bits, the 2nd character will be the first characters and so on.
	loop extract_char

halt:
	cli
	hlt

times 510-($-$$) db 0
dw 0AA55h