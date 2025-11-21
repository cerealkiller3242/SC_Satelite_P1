.option rvc
.section .text
    .globl process3_start

process3_start:

P3_loop:
    # Leer ciclos de CPU (Problema 3: rdcycle)
    rdcycle t0
    rdcycleh t1                # Upper 32 bits
    la t2, cycle_count_p3
    sw t0, 0(t2)               # Guardar low 32 bits
    sw t1, 4(t2)               # Guardar high 32 bits
    
    # Verificar si el sistema sigue activo
    la t3, temps_index
    lw t4, 0(t3)
    la t5, temps_len
    lw t6, 0(t5)
    bge t4, t6, P3_done    # Si terminó, ir a done
    
    la t0, uart_buffer
    lw t1, 0(t0)

    beqz t1, P3_loop    # buffer vacío → idle

    # guardar último dato recibido
    la t2, uart_last
    sw t1, 0(t2)

    # limpiar buffer
    sw zero, 0(t0)

    j P3_loop

P3_done:
    # Procesamiento completo, entrar en espera
    wfi
    # Si se despierta, verificar nuevamente
    j P3_loop
