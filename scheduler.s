    .section .text
    .globl scheduler_start

    .extern pcb_p1
    .extern pcb_p2
    .extern pcb_p3
    .extern current_scenario


scheduler_start:

scheduler_loop:
    #ESCENARIO 1 → P1 → P2 → P3
    li t0, 1
    jal ra, run_process

    li t0, 2
    jal ra, run_process

    li t0, 3
    jal ra, run_process

    j scheduler_loop




# t0 = id del proceso
run_process:
    # guardar el id del proceso actual
    # restaurar contexto del proceso seleccionado

    beq t0, 1, load_p1
    beq t0, 2, load_p2
    beq t0, 3, load_p3
    ret

load_p1:
    la t1, pcb_p1
    j restore_context
load_p2:
    la t1, pcb_p2
    j restore_context
load_p3:
    la t1, pcb_p3

restore_context:
    lw t2, 0(t1)     # PC
    lw sp, 4(t1)     # SP
    jr t2
