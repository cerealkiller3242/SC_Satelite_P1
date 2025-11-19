.section .text
.globl process1_start

# Process1 ahora usa variables globales temps_ptr y temps_index

process1_start:

P1_loop:
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
    li t7, 55
    blt t4, t7, P1_clear_cooling

    j P1_continue

P1_set_cooling:
    la t8, cooling_flag
    li t9, 1
    sw t9, 0(t8)
    j P1_continue

P1_clear_cooling:
    la t8, cooling_flag
    sw zero, 0(t8)
    j P1_continue

P1_continue:
    # escribir en buffer UART (no imprimir)
    la t9, uart_buffer
    sw t4, 0(t9)

    # incrementar índice
    la t0, temps_index
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)

    j P1_loop
