#include "idt.h"
#include "config.h"
#include "kernel.h"
#include "memory/memory.h"

struct idt_descriptor_t idt_descriptors[PEACHOS_TOTAL_INTERRUPTS]; // define an array of IDT descriptors or IDT entries.
struct idtr_t idtr; // define IDT Register or IDTR

extern void idt_load(struct idtr_t *idtr); // define the external function from idt.asm

void idt_zero()
{
    print("Divide by zero error.\n");
}

/**
 * This function is used to map an interrupt to a function address.
 * 
 * For example, if you passed 0x80 as the interrupt number, then
 * whenever you run INT 0x80, the CPU will execute the code at the
 * function address provided.
 */
void idt_set_function(int interrupt_number, void *address)
{
    struct idt_descriptor_t *idt_descriptor = &idt_descriptors[interrupt_number];
    idt_descriptor->offset_low = (uint32_t) address & 0x0000FFFF; // Extract the lower 16 bits
    idt_descriptor->selector = KERNEL_CODE_SELECTOR; // Assign the code segment in the GDT 0x08
    idt_descriptor->zero = 0x00;
    idt_descriptor->type_attributes = 0xEE; // 1110 1110
    idt_descriptor->offset_high = (uint32_t) address >> 16; // Extract the higer 16 bits 
}

void idt_init()
{
    // Fills IDT array with NULL value
    memset(idt_descriptors, 0, sizeof(idt_descriptors));

    // Assigns the actual table size
    idtr.limit = sizeof(idt_descriptors) - 1;

    // Assigns the base address of where the interrupt descriptor table is stored
    idtr.base = (uint32_t) idt_descriptors;

    // Map idt_zero function to the interrupt_number
    int interrupt_number = 0x0;
    idt_set_function(interrupt_number, idt_zero);

    // Load the interrupt descriptor table
    idt_load(&idtr);
}