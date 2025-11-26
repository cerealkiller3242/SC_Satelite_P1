#ifndef MEMORY_MAP_H
#define MEMORY_MAP_H

// Tipos básicos para RISC-V sin libc
typedef unsigned int uint32_t;
typedef unsigned char uint8_t;

// Estado de temperatura y sistemas
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

// =============================================================================
// ESCENARIOS (Problema de Requisitos)
// =============================================================================
// SCENARIO=1: P1 → P2 → P3
// SCENARIO=2: P1 → P3 → P2
// SCENARIO=3: P2 → P1 → P3
// SCENARIO=4: P1 → P2 → P3 con syscalls

// =============================================================================
// MÉTRICAS DE DEBUGGING (Problema 3)
// =============================================================================

// Ciclos de CPU por proceso (rdcycle)
extern unsigned long long cycle_count_p1;
extern unsigned long long cycle_count_p2;
extern unsigned long long cycle_count_p3;

// Contador de interrupciones por proceso
extern unsigned int interrupt_count_p1;
extern unsigned int interrupt_count_p2;
extern unsigned int interrupt_count_p3;

// Contadores globales de eventos
extern unsigned long total_interrupts;
extern unsigned long total_context_switches;
extern unsigned long total_syscalls;

// Timing - Ciclos CPU
extern unsigned long long cycle_start;
extern unsigned long long cycle_end;
extern unsigned long long total_cycles;

#define STACK_SIZE 1024

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
