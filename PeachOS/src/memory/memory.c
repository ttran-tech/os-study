#include "memory.h"

/**
 * Fill a block of memory with a particular value.
 * 
 * ptr:     starting address of memory to be filled.
 * c:       value to be filled.
 * size:    number of bytes to be filled starting from ptr. 
 */
void *memset(void *ptr, int c, size_t size)
{
    char* c_ptr = (char*) ptr;
    for (int i = 0; i < size; i++)
    {
        c_ptr[i] = (char)c;
    }
    return ptr;
}