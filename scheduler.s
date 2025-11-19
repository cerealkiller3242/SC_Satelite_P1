    .option rvc
    .section .text
    .globl scheduler_start

    .extern pcb_p1
    .extern pcb_p2
    .extern pcb_p3
    .extern current_scenario


scheduler_start:

scheduler_loop:
    # Cargar el escenario actual
    la t6, current_scenario
    lw t6, 0(t6)
    
    # Saltar al escenario correspondiente
    li t5, 1
    beq t6, t5, scenario_1
    
    li t5, 2
    beq t6, t5, scenario_2
    
    li t5, 3
    beq t6, t5, scenario_3
    
    li t5, 4
    beq t6, t5, scenario_4
    
    # Por defecto, escenario 1
    j scenario_1

# ESCENARIO 1: P1P2P3

scenario_1:
    li t0, 1
    jal ra, run_process

    li t0, 2
    jal ra, run_process

    li t0, 3
    jal ra, run_process

    j scheduler_loop

# ESCENARIO 2: P1P3P2

scenario_2:
    li t0, 1
    jal ra, run_process

    li t0, 3
    jal ra, run_process

    li t0, 2
    jal ra, run_process

    j scheduler_loop

# ESCENARIO 3: P2P1P3

scenario_3:
    li t0, 2
    jal ra, run_process

    li t0, 1
    jal ra, run_process

    li t0, 3
    jal ra, run_process

    j scheduler_loop

# ESCENARIO 4: Syscalls (placeholder)

scenario_4:


    li t0, 1
    jal ra, run_process

    li t0, 2
    jal ra, run_process

    li t0, 3
    jal ra, run_process

    j scheduler_loop


# FUNCIONES AUXILIARES

# t0 = id del proceso
run_process:
    # guardar el id del proceso actual
    # restaurar contexto del proceso seleccionado

    li t5, 1
    beq t0, t5, load_p1
    
    li t5, 2
    beq t0, t5, load_p2
    
    li t5, 3
    beq t0, t5, load_p3
    
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
