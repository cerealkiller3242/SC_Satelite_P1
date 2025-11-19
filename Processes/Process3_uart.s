.section .text
    .globl process3_start

process3_start:

P3_loop:
    la t0, uart_buffer
    lw t1, 0(t0)

    beqz t1, P3_loop    # buffer vacío → idle

    # guardar último dato recibido
    la t2, uart_last
    sw t1, 0(t2)

    # limpiar buffer
    sw zero, 0(t0)

    j P3_loop
