#include "memory_map.h"

extern void scheduler_start();
extern void sbi_putchar(char c);

void kernel_start(int *temps, int len)
{
    // Configurar variables globales para procesos
    temps_ptr = temps;
    temps_len = len;
    temps_index = 0;
    interrupt_count_p1 = 0;
    
    // Print kernel start
    sbi_putchar('K');
    sbi_putchar('E');
    sbi_putchar('R');
    sbi_putchar('N');
    sbi_putchar('E');
    sbi_putchar('L');
    sbi_putchar(':');
    sbi_putchar('S');
    sbi_putchar('\n');
    
    // Llamar al scheduler
    scheduler_start();
}
