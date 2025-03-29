; Extract 0x4A1B (0100 1010 0001 1011)
; 1. use AND to bitmask 0000Fh (or 0x000F) to extract the last digit
; 2. either convert it to string char or number char
; 3. shift the original value to the right 4 times (4 bits each digit)
; 4. Repeat 1
[bits 16]
[org 7c00h]

start:
	mov ax, 0x4A1B
	mov cx, 4 ; loop 4 times
	
extract_char:
	mov bx, ax ; copy AX to BL, avoid messing the original value
	and bl, 0Fh ; AND BL with 0x000F to extract the last character and store the character in BL
    cmp bl, 0Ah ; compare to 10, less than 10 is number, greater than 10 is one the letter from A to F
	jl extract_number ; jump to extract_number if BL is less than 10
	add bl, 37h ; convert A~F to character by adding 0x37 (or 55 in decimal)
				; Example: A = 10 in decimal, 10 + 55 = 65 and 65 is ASCII code for 'A'
	jmp print_char

extract_number:
	add bl, 30h
	jmp print_char

print_char:
	push ax
	mov ah, 0eh
	mov al, bl
	mov bx, 0
	int 10h
	pop ax
	jmp shift_right

shift_right:
	shr ax, 4
	loop extract_char

halt:
	cli
	hlt

times 510-($-$$) db 0
dw 0AA55h