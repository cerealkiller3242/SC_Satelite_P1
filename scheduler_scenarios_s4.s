# ============================================================================
# scheduler_scenarios_s4.s - Scheduler ESCENARIO 4 SOLO
# ============================================================================
# Escenario 4 usa SYSCALLS en lugar de llamadas directas
# Este archivo reemplaza scheduler_scenarios.s cuando SCENARIO=4

.option rvc
.section .text

.globl scheduler_start

.extern sbi_putchar
.extern syscall_dispatcher
.extern current_scenario
.extern total_context_switches
.extern total_syscalls
.extern total_interrupts
.extern cycle_start
.extern cycle_end
.extern total_cycles

# ============================================================================
# MAIN SCHEDULER - Escenario 4 SOLO
# ============================================================================
scheduler_start:
    # Capturar ciclo inicial
    rdcycle a5
    la a6, cycle_start
    sw a5, 0(a6)
    
    # Cargar escenario actual
    la t5, current_scenario
    lw t6, 0(t5)                  # t6 = current_scenario (debe ser 4)
    
    # Cargar UART
    li t0, 0x10000000
    
    # Imprimir header
    li t1, '['
    sb t1, 0(t0)
    li t1, 'S'
    sb t1, 0(t0)
    li t1, 'C'
    sb t1, 0(t0)
    li t1, 'H'
    sb t1, 0(t0)
    li t1, ']'
    sb t1, 0(t0)
    li t1, ' '
    sb t1, 0(t0)
    
    # Imprimir número del escenario
    addi t1, t6, 48               # t6 + '0'
    sb t1, 0(t0)
    
    li t1, '\n'
    sb t1, 0(t0)

# ============================================================================
# SCENARIO 4: P1 → P2 → P3 usando SYSCALLS
# ============================================================================
scenario4:
    # Imprimir header una sola vez
    li t0, 0x10000000
    li t1, 'P'
    sb t1, 0(t0)
    li t1, '1'
    sb t1, 0(t0)
    li t1, '_'
    sb t1, 0(t0)
    li t1, 'S'
    sb t1, 0(t0)
    li t1, '4'
    sb t1, 0(t0)
    li t1, '\n'
    sb t1, 0(t0)

s4_process_loop:
    # LOOP: P1→P2→P3 usando SYSCALLS simulados
    # Llamamos a syscall_dispatcher que despacha según a7
    
    # SYSCALL 20: Ejecutar process1_temp_sbi
    li a7, 20                  # a7 = syscall_id = 20
    call syscall_dispatcher    # Dispatcher que simula ecall
    
    # Incrementar contador de syscalls
    la s0, total_syscalls
    lw s1, 0(s0)
    addi s1, s1, 1
    sw s1, 0(s0)
    
    # SYSCALL 21: Ejecutar process2_cooler_sbi
    li a7, 21                  # a7 = syscall_id = 21
    call syscall_dispatcher
    
    # Incrementar contador de syscalls
    la s0, total_syscalls
    lw s1, 0(s0)
    addi s1, s1, 1
    sw s1, 0(s0)
    
    # SYSCALL 22: Ejecutar process3_uart_sbi
    li a7, 22                  # a7 = syscall_id = 22
    call syscall_dispatcher
    
    # Incrementar contador de syscalls
    la s0, total_syscalls
    lw s1, 0(s0)
    addi s1, s1, 1
    sw s1, 0(s0)
    
    # Verificar si se procesaron todas las temperaturas
    la t0, temps_index
    lw t1, 0(t0)
    la t2, temps_len
    lw t3, 0(t2)
    
    # Si temps_index < temps_len, continuar loop
    blt t1, t3, s4_process_loop
    
    # Si llegamos aquí, procesamos todas las 100 temperaturas
    li t0, 0x10000000
    li t1, 'P'
    sb t1, 0(t0)
    li t1, '1'
    sb t1, 0(t0)
    li t1, 'D'
    sb t1, 0(t0)
    li t1, '\n'
    sb t1, 0(t0)
    
    li t1, 'P'
    sb t1, 0(t0)
    li t1, '2'
    sb t1, 0(t0)
    li t1, 'D'
    sb t1, 0(t0)
    li t1, '\n'
    sb t1, 0(t0)
    
    li t1, 'P'
    sb t1, 0(t0)
    li t1, '3'
    sb t1, 0(t0)
    li t1, 'D'
    sb t1, 0(t0)
    li t1, '\n'
    sb t1, 0(t0)
    
    # Imprimir [DONE]
    li t1, '['
    sb t1, 0(t0)
    li t1, 'D'
    sb t1, 0(t0)
    li t1, 'O'
    sb t1, 0(t0)
    li t1, 'N'
    sb t1, 0(t0)
    li t1, 'E'
    sb t1, 0(t0)
    li t1, ']'
    sb t1, 0(t0)
    li t1, '\n'
    sb t1, 0(t0)

# ============================================================================
# FIN DE EJECUCIÓN - Mostrar estadísticas y loop infinito
# ============================================================================
scenario_done:
    # Capturar ciclo final
    rdcycle a5
    la a6, cycle_end
    sw a5, 0(a6)
    
    # Calcular ciclos totales (cycle_end - cycle_start)
    lw a7, 0(a6)               # a7 = cycle_end
    la a6, cycle_start
    lw t0, 0(a6)               # t0 = cycle_start
    sub t1, a7, t0             # t1 = total_cycles = cycle_end - cycle_start
    la a6, total_cycles
    sw t1, 0(a6)
    
    # Imprimir newline y separador
    li t0, 0x10000000
    li t2, '\n'
    sb t2, 0(t0)
    li t2, '='
    sb t2, 0(t0)
    li t2, '='
    sb t2, 0(t0)
    li t2, '='
    sb t2, 0(t0)
    li t2, '\n'
    sb t2, 0(t0)
    
    # Imprimir "Tiempo Total: "
    li t2, 'T'
    sb t2, 0(t0)
    li t2, 'i'
    sb t2, 0(t0)
    li t2, 'e'
    sb t2, 0(t0)
    li t2, 'm'
    sb t2, 0(t0)
    li t2, 'p'
    sb t2, 0(t0)
    li t2, 'o'
    sb t2, 0(t0)
    li t2, ' '
    sb t2, 0(t0)
    li t2, 'T'
    sb t2, 0(t0)
    li t2, 'o'
    sb t2, 0(t0)
    li t2, 't'
    sb t2, 0(t0)
    li t2, 'a'
    sb t2, 0(t0)
    li t2, 'l'
    sb t2, 0(t0)
    li t2, ':'
    sb t2, 0(t0)
    li t2, ' '
    sb t2, 0(t0)
    li t2, '0'
    sb t2, 0(t0)
    li t2, 'x'
    sb t2, 0(t0)
    
    # Convertir t1 a hexadecimal (8 dígitos)
    li t3, 28               # Empezar con bit 28 (32-4)
    
hex_loop_final:
    srl t4, t1, t3          # Desplazar para obtener nibble
    andi t4, t4, 0xf        # Máscara para 4 bits
    
    # Convertir nibble a ASCII hex
    li t5, 9
    ble t4, t5, hex_digit_numeric_final
    addi t4, t4, 55         # A-F: 10-15 → 65-70 (A-F)
    j hex_digit_print_final
hex_digit_numeric_final:
    addi t4, t4, 48         # 0-9 → 48-57
    
hex_digit_print_final:
    sb t4, 0(t0)
    
    # Siguiente nibble
    addi t3, t3, -4
    bge t3, zero, hex_loop_final
    
    # Newline
    li t2, '\n'
    sb t2, 0(t0)
    li t2, '='
    sb t2, 0(t0)
    li t2, '='
    sb t2, 0(t0)
    li t2, '='
    sb t2, 0(t0)
    li t2, '\n'
    sb t2, 0(t0)
    
    # LOOP INFINITO
scenario_final_loop:
    j scenario_final_loop
