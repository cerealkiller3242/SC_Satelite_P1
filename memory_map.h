#ifndef MEMORY_MAP_H
#define MEMORY_MAP_H

#include <stdint.h>

extern int temp_actual;
extern int cooling_flag;
extern int uart_buffer;
extern int uart_last;

extern int *temps_ptr;
extern int temps_len;

#define STACK_SIZE 512

// Process IDs
#define P1 1
#define P2 2
#define P3 3

#endif
