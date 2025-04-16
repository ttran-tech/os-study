#ifndef MEMORY_H
#define MEMORY_H
#include <stddef.h>

/**
 * Fill a block of memory with a particular value.
 * 
 * ptr:     starting address of memory to be filled.
 * c:       value to be filled.
 * size:    number of bytes to be filled starting from ptr. 
 */
void *memset(void *ptr, int c, size_t size);

#endif