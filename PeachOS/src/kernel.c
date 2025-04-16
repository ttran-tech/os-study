#include <stddef.h>
#include <stdint.h>
#include "kernel.h"
#include "idt/idt.h"

uint16_t *video_mem = 0;
uint16_t terminal_row = 0;
uint16_t terminal_col = 0;

// Merge character and color code
uint16_t terminal_make_char(char c, char color) 
{
    return (color << 8) | c; // A character is a combined of 2 bytes (character + color code)
} 

// Set character to video memory at x, y coordinators
void terminal_putchar(int x, int y, char c, char color)
{
    video_mem[(y * VGA_WIDTH) + x] = terminal_make_char(c, color);
}

// Write chatacter to the terminal
void terminal_writechar(char c, char color)
{
    if (c == '\n')
    {
        terminal_row += 1; // Row increase when character is a newline
        terminal_col = 0;  // Reset column to 0
        return;
    }

    terminal_putchar(terminal_col, terminal_row, c, color);
    terminal_col += 1;

    // Increase row and reset column if terminal_col reach the MAX WIDTH pixel
    if (terminal_col >= VGA_WIDTH)
    {   
        terminal_row += 1;
        terminal_col = 0;
    }
}

// Initialize and clear the terminal
void terminal_init()
{
    video_mem = (uint16_t *)(0xB8000); // Initialize video memory
    terminal_row = 0;
    terminal_col = 0;

    for (int y = 0; y < VGA_HEIGHT; y++)
    {
        for (int x = 0; x <VGA_WIDTH; x++)
        {
            terminal_putchar(x, y, ' ', 0);
        }
    }
}

// Get the length of a string
size_t strlen(const char *str)
{
    size_t len = 0;
    while(str[len])
        len++;
    return len;
}

// Print a string to the screen
void print(const char * str)
{
    size_t len = strlen(str);
    for (int i = 0; i < len; i++)
    {
        terminal_writechar(str[i], 15);
    }
}

void kernel_main()
{
    terminal_init();
    print("\n Welcome to PeachOS.\n A greeting message from the kernel.\n");
    print("\n Hello World!");

    idt_init();

}