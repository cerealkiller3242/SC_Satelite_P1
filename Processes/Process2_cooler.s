.option rvc
.section .text
    .globl process2_start

process2_start:

P2_loop:
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

    # esperar temperatura < 55
P2_monitor:
    la t4, temp_actual
    lw t5, 0(t4)

    li t6, 55
    bgt t5, t6, P2_monitor

    # apagando cooling
    la t2, cooling_state
    sw zero, 0(t2)

    j P2_loop


# ENFRIAMIENTO APAGADO

P2_idle:
    # estado interno
    la t2, cooling_state
    sw zero, 0(t2)

    j P2_loop
