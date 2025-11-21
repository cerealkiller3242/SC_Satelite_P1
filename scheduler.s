    .option rvc
    .section .text
    .globl scheduler_start

    .extern pcb_p1
    .extern pcb_p2
    .extern pcb_p3
    .extern current_scenario
    .extern current_process_id
    .extern setup_timer


scheduler_start:
    # =================================================================
    # INICIALIZACIÓN: Saltar al primer proceso del escenario
    # =================================================================
    # Después de esto, las interrupciones de timer manejan el scheduling
    
    # Determinar primer proceso según escenario
    la t6, current_scenario
    lw t6, 0(t6)
    
    li t5, 1
    beq t6, t5, start_scenario_1
    
    li t5, 2
    beq t6, t5, start_scenario_2
    
    li t5, 3
    beq t6, t5, start_scenario_3
    
    # Por defecto, escenario 1
    j start_scenario_1

start_scenario_1:
    # P1 → P2 → P3: empezar con P1
    li t0, 1
    j jump_to_first_process

start_scenario_2:
    # P1 → P3 → P2: empezar con P1
    li t0, 1
    j jump_to_first_process

start_scenario_3:
    # P2 → P1 → P3: empezar con P2
    li t0, 2
    j jump_to_first_process

jump_to_first_process:
    # t0 = ID del primer proceso
    # Actualizar current_process_id
    la t1, current_process_id
    sw t0, 0(t1)
    
    # =================================================================
    # AHORA SÍ: Habilitar interrupciones y configurar timer
    # =================================================================
    # En este punto los PCBs ya están inicializados por kernel_start
    
    # Habilitar interrupciones globales (MSTATUS.MIE = bit 3)
    li t6, 0x8
    csrs mstatus, t6
    
    # Configurar timer inicial
    # Guardar t0 (ID del proceso) antes de llamar
    mv s0, t0
    call setup_timer
    mv t0, s0
    
    # Saltar al proceso (las interrupciones harán el resto)
    li t5, 1
    beq t0, t5, jump_p1
    li t5, 2
    beq t0, t5, jump_p2
    li t5, 3
    beq t0, t5, jump_p3

jump_p1:
    la t1, pcb_p1
    lw t2, 0(t1)                # PC
    lw sp, 4(t1)                # SP
    jr t2

jump_p2:
    la t1, pcb_p2
    lw t2, 0(t1)                # PC
    lw sp, 4(t1)                # SP
    jr t2

jump_p3:
    la t1, pcb_p3
    lw t2, 0(t1)                # PC
    lw sp, 4(t1)                # SP
    jr t2

# =================================================================
# NOTA: El código antiguo de scheduler_loop ya no se usa
# El scheduling ahora se maneja en trap_handler.s
# =================================================================

scheduler_loop:

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
