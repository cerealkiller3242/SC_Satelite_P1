#ifndef PCB_H
#define PCB_H

#include <stdint.h>

struct PCB {
    uint32_t pc;
    uint32_t sp;
    uint32_t regs[32];
};

extern struct PCB pcb_p1;
extern struct PCB pcb_p2;
extern struct PCB pcb_p3;

#endif
