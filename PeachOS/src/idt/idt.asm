; This assembly code is a wrapper around the lidt instruction
; which allows to load the IDT from within the C code.
;
section .asm ; this file will be loaded into .asm section in the kernel

global idt_load ; declare idt_load  as a global function which can be called from other files

idt_load:
    push ebp
    mov ebp, esp

    mov ebx, [ebp+8] ; load 1st argument from the function into EBX (the address of the IDT)
    lidt [ebx]  ; load IDT entry into CPU register (IDTR)
    pop ebp
    ret

; Once the LIDT instruction is executed, the processor will switch the current Interrupt Vector Table
; to the table passed to the LIDT instruction. Then, any interrupts will be found in the custom IDT