#include "memory_map.h"

int temp_actual = 0;
int cooling_flag = 0;
int uart_buffer = 0;
int uart_last = 0;
int cooling_state = 0;

int *temps_ptr = 0;
int temps_len = 0;
int temps_index = 0;

int current_scenario = 1;  // Por defecto se usa el Escenario 1
