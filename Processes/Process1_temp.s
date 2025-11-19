.section .text
.globl process1_start

# Inputs:
#   a0 = puntero al array de temperaturas
#   a1 = puntero al índice actual


process1_start:

P1_loop:
    # cargar índice
    lw t0, 0(a1)       # índice en a1

    # temperatura = temps[index]
    slli t1, t0, 2
    add t2, a0, t1
    lw t3, 0(t2)

    # guardar valor global
    la t4, temp_actual
    sw t3, 0(t4)

    # lógica de flags
    # activar enfriamiento
    li t5, 90
    bgt t3, t5, P1_set_cooling

    # desactivar enfriamiento
    li t6, 55
    blt t3, t6, P1_clear_cooling

    j P1_continue

P1_set_cooling:
    la t7, cooling_flag
    li t8, 1
    sw t8, 0(t7)
    j P1_continue

P1_clear_cooling:
    la t7, cooling_flag
    sw zero, 0(t7)
    j P1_continue

P1_continue:
    # escribir en buffer UART (no imprimir)
    la t9, uart_buffer
    sw t3, 0(t9)

    # incrementar índice
    addi t0, t0, 1
    sw t0, 0(a1)

    j P1_loop


.section .data
temp_actual: .word 0


