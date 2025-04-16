#ifndef IDT_H
#define IDT_H
#include <stdint.h>

// Represents an interrupt entry in the IDT
struct idt_descriptor_t 
{
    uint16_t offset_low; // Offset Low 0-15 (16 bits)
    uint16_t selector;  // Used to identify a sgment in GDT/LDT entry (16 bits)
    uint8_t zero;   // ALways 0, does nothing (8 bits)
    uint8_t type_attributes; // Descriptor type and attribute (8 bits)
    uint16_t offset_high;   // Offset High 16-31 (16 bits)
} __attribute__((packed)); // pack the structure members together without adding any padding bytes between them.

struct idtr_t
{
    uint16_t limit; // Size of descriptor table -1
    uint32_t base; // Base address of the start of the IDT
} __attribute__((packed));

void idt_init();

#endif