#ifndef MEMORY_MAP_H
#define MEMORY_MAP_H

// Tipos básicos para RISC-V sin libc
typedef unsigned int uint32_t;
typedef unsigned char uint8_t;

extern int temp_actual;
extern int cooling_flag;
extern int uart_buffer;
extern int uart_last;
extern int cooling_state;

extern int *temps_ptr;
extern int temps_len;
extern int temps_index;

// Variable para seleccionar el escenario del scheduler
extern int current_scenario;

#define STACK_SIZE 512

// IDs de los procesos
#define P1 1
#define P2 2
#define P3 3

// Escenarios del scheduler
#define SCENARIO_1_P1P2P3 1
#define SCENARIO_2_P1P3P2 2  
#define SCENARIO_3_P2P1P3 3  
#define SCENARIO_4_SYSCALLS 4

#endif
