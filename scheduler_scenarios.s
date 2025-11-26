# ============================================================================
# scheduler_scenarios.s - Scheduler con 4 escenarios diferentes
# ============================================================================
# Con contadores de context switches, syscalls y logging

.option rvc
.section .text

.globl scheduler_start

.extern sbi_putchar
.extern process1_temp_sbi
.extern process2_cooler_sbi
.extern process3_uart_sbi
.extern current_scenario
.extern total_context_switches
.extern total_syscalls
.extern total_interrupts
.extern cycle_start
.extern cycle_end
.extern total_cycles

# Macro para incrementar un contador (dirección en t7, valor en t8)
.macro inc_counter addr_reg, val_reg
    la \addr_reg, \addr_reg
    lw \val_reg, 0(\addr_reg)
    addi \val_reg, \val_reg, 1
    sw \val_reg, 0(\addr_reg)
.endm

# Macro para simular una interrupción (incrementar contador y context switch)
.macro interrupt_simulated
    # Incrementar total_interrupts (usando s0, s1 como temporales)
    la s0, total_interrupts
    lw s1, 0(s0)
    addi s1, s1, 1
    sw s1, 0(s0)
    
    # Incrementar total_context_switches
    la s0, total_context_switches
    lw s1, 0(s0)
    addi s1, s1, 1
    sw s1, 0(s0)
.endm

# ============================================================================
# MAIN SCHEDULER - Ejecuta según el escenario
# ============================================================================
scheduler_start:
    # Capturar ciclo inicial
    rdcycle a5
    la a6, cycle_start
    sw a5, 0(a6)
    
    # Cargar escenario actual
    la t5, current_scenario
    lw t6, 0(t5)                  # t6 = current_scenario (1-4)
    
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
    
    # Saltar según escenario
    li t1, 1
    beq t6, t1, scenario1
    
    li t1, 2
    beq t6, t1, scenario2
    
    li t1, 3
    beq t6, t1, scenario3
    
    li t1, 4
    beq t6, t1, scenario4
    
    # Default: escenario 1
    j scenario1

# ============================================================================
# SCENARIO 1: P1 → P2 → P3 (PREEMPTIVE - Loop de 100 iteraciones)
# ============================================================================
scenario1:
    # Imprimir headers una sola vez
    li t0, 0x10000000
    li t1, 'P'
    sb t1, 0(t0)
    li t1, '1'
    sb t1, 0(t0)
    li t1, '_'
    sb t1, 0(t0)
    li t1, 'S'
    sb t1, 0(t0)
    li t1, '\n'
    sb t1, 0(t0)

s1_process_loop:
    # LOOP: Llamar P1→P2→P3 repetidamente hasta procesar 100 temperaturas
    
    # P1: Leer UNA temperatura
    call process1_temp_sbi
    
    # Simular interrupción entre P1 y P2
    interrupt_simulated
    
    # P2: Procesar cooler
    call process2_cooler_sbi
    
    # Simular interrupción entre P2 y P3
    interrupt_simulated
    
    # P3: Monitorear UART
    call process3_uart_sbi
    
    # Simular interrupción después de P3
    interrupt_simulated
    la t0, temps_index
    lw t1, 0(t0)
    la t2, temps_len
    lw t3, 0(t2)
    
    # Si temps_index < temps_len, continuar loop
    blt t1, t3, s1_process_loop
    
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
    
    # Terminar (halt loop infinito)
    j scenario_done

# ============================================================================
# SCENARIO 2: P1 → P3 → P2
# ============================================================================
# ============================================================================
# SCENARIO 2: P1 → P3 → P2 (PREEMPTIVE - Loop de 100 iteraciones)
# ============================================================================
scenario2:
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
    li t1, '\n'
    sb t1, 0(t0)

s2_process_loop:
    # LOOP: Llamar P1→P3→P2 repetidamente
    
    # P1: Leer UNA temperatura
    call process1_temp_sbi
    
    # Simular interrupción entre P1 y P3
    interrupt_simulated
    
    # P3: Monitorear UART
    call process3_uart_sbi
    
    # Simular interrupción entre P3 y P2
    interrupt_simulated
    
    # P2: Procesar cooler
    call process2_cooler_sbi
    
    # Simular interrupción después de P2
    interrupt_simulated
    la t0, temps_index
    lw t1, 0(t0)
    la t2, temps_len
    lw t3, 0(t2)
    
    # Si temps_index < temps_len, continuar loop
    blt t1, t3, s2_process_loop
    
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
    li t1, '3'
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
    
    # Terminar
    j scenario_done

# ============================================================================
# SCENARIO 3: P2 → P1 → P3 (PREEMPTIVE - Loop de 100 iteraciones)
# ============================================================================
scenario3:
    # Imprimir header una sola vez
    li t0, 0x10000000
    li t1, 'P'
    sb t1, 0(t0)
    li t1, '2'
    sb t1, 0(t0)
    li t1, '_'
    sb t1, 0(t0)
    li t1, 'S'
    sb t1, 0(t0)
    li t1, '\n'
    sb t1, 0(t0)

s3_process_loop:
    # LOOP: Llamar P2→P1→P3 repetidamente
    
    # P2: Procesar cooler
    call process2_cooler_sbi
    
    # Simular interrupción entre P2 y P1
    interrupt_simulated
    
    # P1: Leer UNA temperatura
    call process1_temp_sbi
    
    # Simular interrupción entre P1 y P3
    interrupt_simulated
    
    # P3: Monitorear UART
    call process3_uart_sbi
    
    # Simular interrupción después de P3
    interrupt_simulated
    la t0, temps_index
    lw t1, 0(t0)
    la t2, temps_len
    lw t3, 0(t2)
    
    # Si temps_index < temps_len, continuar loop
    blt t1, t3, s3_process_loop
    
    # Si llegamos aquí, procesamos todas las 100 temperaturas
    li t0, 0x10000000
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
    li t1, '1'
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
    
    # Terminar
    j scenario_done

# ============================================================================
# SCENARIO 4: P1 → P2 → P3 (PREEMPTIVE - Loop de 100 iteraciones, similar a S1)
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
    li t1, '\n'
    sb t1, 0(t0)

s4_process_loop:
    # LOOP: Este escenario no se usa en este archivo
    # Usar scheduler_scenarios_s4.s en su lugar
    j scenario_done
    
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
    
    # Terminar
    j scenario_done


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
    
    # LOOP INFINITO - SIN REINICIAR scenario_done
scenario_final_loop:
    j scenario_final_loop
    
    # Loop infinito (QEMU lo terminará con timeout)
    j scenario_done

# ============================================================================
# Función auxiliar: print_decimal
# Entrada: t3 = número a imprimir (0-999)
# Salida: Imprime en UART
# Usa: t0, t4, t5, t6
# ============================================================================
print_decimal:
    # Guardar ra
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # t3 ya tiene el número
    # Imprimir centenas
    li t4, 100
    li t6, 0                  # centenas = 0
    
    blt t3, t4, print_dec_tens  # Si < 100, saltar centenas
    
    div t6, t3, t4            # centenas = t3 / 100
    rem t3, t3, t4            # t3 = t3 % 100
    
    addi t6, t6, 48           # Convertir a ASCII
    sb t6, 0(t0)
    
print_dec_tens:
    # Imprimir decenas
    li t4, 10
    div t6, t3, t4            # decenas = t3 / 10
    rem t3, t3, t4            # unidades = t3 % 10
    
    addi t6, t6, 48           # Convertir a ASCII
    sb t6, 0(t0)
    
    # Imprimir unidades
    addi t3, t3, 48           # Convertir a ASCII
    sb t3, 0(t0)
    
    # Restaurar ra
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

