.option rvc
.section .text
    .globl process2_start

# Scenario 4: cooler using ECALL to yield

process2_start:

P2_loop:
    # Leer ciclos de CPU (Problema 3: rdcycle)
    rdcycle t0
    rdcycleh t1                # Upper 32 bits
    la t2, cycle_count_p2
    sw t0, 0(t2)               # Guardar low 32 bits
    sw t1, 4(t2)               # Guardar high 32 bits

    # Verificar si el sistema aún está procesando temperaturas
    la t0, temps_index
    lw t1, 0(t0)
    la t2, temps_len
    lw t3, 0(t2)
    bge t1, t3, P2_done    # Si todas las temps procesadas, terminar

    # leer flag de enfriamiento
    la t0, cooling_flag
    lw t1, 0(t0)

    # si cooling_flag == 1 → estamos en cooling_on
    bnez t1, P2_active

    # si cooling_flag == 0 → estamos en cooling_off
    j P2_idle


# ENFRIAMIENTO ACTIVADO

P2_active:
    la t2, cooling_state
    li t3, 1
    sw t3, 0(t2)

    # esperar temperatura < 55 (pero con yields para permitir scheduling)
P2_monitor:
    la t4, temp_actual
    lw t5, 0(t4)

    li t6, 55
    bgt t5, t6, P2_before_yield
    j P2_after_monitor

P2_before_yield:
    # yield to scheduler via ecall
    li a7, 0
    ecall
    j P2_monitor

P2_after_monitor:
    # apagando cooling
    la t2, cooling_state
    sw zero, 0(t2)

    # yield once before continue loop
    li a7, 0
    ecall

    j P2_loop


# ENFRIAMIENTO APAGADO

P2_idle:
    # estado interno
    la t2, cooling_state
    sw zero, 0(t2)

    # yield to let other processes run
    li a7, 0
    ecall

    j P2_loop

P2_done:
    # Trabajo terminado, entrar en espera
    wfi
    # Si se despierta, verificar si hay nuevo trabajo
    j P2_loop
