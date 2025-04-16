/* 
 * Linker Script for Kernel Debugging
 * ----------------------------------
 * This script defines how the linker should arrange the kernel binary in memory.
 * It ensures proper memory layout and symbol resolution, enabling us to debug 
 * the kernel with tools like GDB using named symbols (e.g., "break kernel_start")
 * instead of raw memory addresses.
 */
ENTRY(_start) /* Signifies the starting point of the execution in the kernel */
OUTPUT_FORMAT(binary) /* Sets the output format */
SECTIONS /* Defines memory layout of the output */
{
    . = 1M; /* Sets the start of the section at 1MB mark (match the kernel load address) */
    .text : ALIGN(4096) /* Program code - ALIGN(4096) set page boundary */
    {   /* Tells the linker to take all .text sections from the input files and put them into the .text section of the output file */
        *(.text) 
    }

    .rodata : ALIGN(4096) /* Read-only data */
    {
        *(.rodata)
    }

    .data : ALIGN(4096) /* Initialized data */
    {
        *(.data)
    }

    .bss : ALIGN(4096) /* Unintialized data */
    {
        *(COMMON)
        *(.bss)
    }
    .asm : ALIGN(4096) /* custom section */
    {
        *(.asm)
    }
}