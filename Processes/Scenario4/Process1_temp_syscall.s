.option rvc
.section .text
.globl process1_start

# Version for Scenario 4: same logic as Process1_temp.s but uses ECALL
# to voluntarily yield / perform a "syscall" after each iteration.

process1_start:

P1_loop:
    # Leer ciclos de CPU (Problema 3: rdcycle)
    rdcycle t0
    rdcycleh t1                # Upper 32 bits
    la t2, cycle_count_p1
    sw t0, 0(t2)               # Guardar low 32 bits
    sw t1, 4(t2)               # Guardar high 32 bits

    # Verificar si quedan temperaturas por procesar
    la t0, temps_index
    lw t1, 0(t0)       # t1 = índice actual
    la t2, temps_len
    lw t3, 0(t2)       # t3 = longitud total
    bge t1, t3, P1_idle    # Si index >= len, ir a idle

    # cargar índice desde temps_index
    la t0, temps_index
    lw t0, 0(t0)       # índice

    # cargar puntero al array de temps
    la t1, temps_ptr
    lw t1, 0(t1)       # t1 = temps_ptr

    # temperatura = temps[index]
    slli t2, t0, 2
    add t3, t1, t2
    lw t4, 0(t3)

    # guardar valor global
    la t5, temp_actual
    sw t4, 0(t5)

    # lógica de flags
    # activar enfriamiento
    li t6, 90
    bgt t4, t6, P1_set_cooling

    # desactivar enfriamiento
    li t6, 55
    blt t4, t6, P1_clear_cooling

    j P1_continue

P1_set_cooling:
    la t5, cooling_flag
    li t6, 1
    sw t6, 0(t5)
    j P1_continue

P1_clear_cooling:
    la t5, cooling_flag
    sw zero, 0(t5)
    j P1_continue

P1_continue:
    # escribir en buffer UART (no imprimir)
    la t5, uart_buffer
    sw t4, 0(t5)

    # incrementar índice
    la t0, temps_index
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)

    # Simulate a syscall / yield: place a7 = 0 (YIELD) and ecall
    li a7, 0
    ecall

    j P1_loop

P1_idle:
    # Todas las temperaturas procesadas, entrar en modo de espera
    wfi
    # Si se despierta por una interrupción, verificar si hay trabajo nuevo
    j P1_loop
