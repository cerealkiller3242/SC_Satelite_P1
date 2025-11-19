#include "memory_map.h"
#include "stacks.h"
#include "pcb.h"

extern void scheduler_start();

extern void process1_start();
extern void process2_start();
extern void process3_start();

struct PCB pcb_p1 = {0};
struct PCB pcb_p2 = {0};
struct PCB pcb_p3 = {0};

void kernel_start(int *temps, int len)
{
    temps_ptr = temps;
    temps_len = len;

    // inicializar los PCBs
    pcb_p1.pc = (uint32_t)process1_start;
    pcb_p1.sp = (uint32_t)(stack_p1 + STACK_SIZE);

    pcb_p2.pc = (uint32_t)process2_start;
    pcb_p2.sp = (uint32_t)(stack_p2 + STACK_SIZE);

    pcb_p3.pc = (uint32_t)process3_start;
    pcb_p3.sp = (uint32_t)(stack_p3 + STACK_SIZE);

    // llamar al scheduler
    scheduler_start();
}
