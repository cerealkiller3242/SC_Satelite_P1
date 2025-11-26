#include "memory_map.h"

// Estado de temperatura y sistemas
int temp_actual = 0;
int cooling_flag = 0;
int uart_buffer = 0;
int uart_last = 0;
int cooling_state = 0;

int *temps_ptr = 0;
int temps_len = 0;
int temps_index = 0;

int current_scenario = 1;  // Por defecto se usa el Escenario 1

// =============================================================================
// MÉTRICAS DE DEBUGGING (Problema 3)
// =============================================================================

// Ciclos de CPU por proceso (rdcycle)
unsigned long long cycle_count_p1 = 0;
unsigned long long cycle_count_p2 = 0;
unsigned long long cycle_count_p3 = 0;

// Contador de interrupciones por proceso
unsigned int interrupt_count_p1 = 0;
unsigned int interrupt_count_p2 = 0;
unsigned int interrupt_count_p3 = 0;

// Contadores globales de eventos
unsigned long total_interrupts = 0;
unsigned long total_context_switches = 0;
unsigned long total_syscalls = 0;

// Timing - Ciclos CPU
unsigned long long cycle_start = 0;
unsigned long long cycle_end = 0;
unsigned long long total_cycles = 0;
