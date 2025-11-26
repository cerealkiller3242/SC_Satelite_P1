# ============================================================================
# processes_sbi_s4.s - Procesos ESCENARIO 4 SOLO
# ============================================================================
# Incluye syscall_dispatcher que despacha syscalls
# Procesos identicos a processes_sbi.s pero con dispatcher integrado

.option rvc
.section .text

.globl process1_temp_sbi
.globl process2_cooler_sbi
.globl process3_uart_sbi
.globl syscall_dispatcher

.extern temps_ptr
.extern temps_len
.extern temps_index
.extern interrupt_count_p1

# ============================================================================
# SYSCALL DISPATCHER: Simula syscalls con despacho basado en a7
# ============================================================================
# a7 contiene el número de syscall
# Syscall 20: Ejecutar process1_temp_sbi
# Syscall 21: Ejecutar process2_cooler_sbi
# Syscall 22: Ejecutar process3_uart_sbi
# ============================================================================
syscall_dispatcher:
    # Determinar qué syscall ejecutar basándose en a7
    li t0, 20
    beq a7, t0, syscall_20        # Syscall 20: process1_temp
    
    li t0, 21
    beq a7, t0, syscall_21        # Syscall 21: process2_cooler
    
    li t0, 22
    beq a7, t0, syscall_22        # Syscall 22: process3_uart
    
    # Si no coincide, simplemente retornar
    ret

syscall_20:
    # Guardar ra y llamar a process1_temp_sbi
    addi sp, sp, -4
    sw ra, 0(sp)
    call process1_temp_sbi
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

syscall_21:
    # Guardar ra y llamar a process2_cooler_sbi
    addi sp, sp, -4
    sw ra, 0(sp)
    call process2_cooler_sbi
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

syscall_22:
    # Guardar ra y llamar a process3_uart_sbi
    addi sp, sp, -4
    sw ra, 0(sp)
    call process3_uart_sbi
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# ============================================================================
# PROCESS 1: Lectura preemptiva de UNA temperatura por invocación
# ============================================================================
process1_temp_sbi:
    # Leer ciclo actual
    rdcycle t0
    la t2, cycle_count_p1
    sw t0, 0(t2)
    
    # Verificar si quedan temperaturas (temps_index < temps_len)
    la t0, temps_index
    lw t1, 0(t0)           # t1 = index actual
    la t2, temps_len
    lw t3, 0(t2)           # t3 = length (100)
    bge t1, t3, p1_done    # Si index >= 100, terminar (no más temperaturas)
    
    # Verificar bounds
    bltz t1, p1_done       # Si index < 0, terminar
    
    # Cargar temperatura: temps[index]
    la t0, temps_ptr
    lw t0, 0(t0)           # t0 = puntero al array
    beqz t0, p1_done       # Si NULL, terminar
    
    slli t2, t1, 2         # t2 = index * 4 (offset en bytes)
    add t2, t0, t2         # t2 = &temps[index]
    lw t4, 0(t2)           # t4 = temps[index] (temperatura)
    
    # Guardar temperatura actual
    la t5, temp_actual
    sw t4, 0(t5)
    
    # LÓGICA DE FLAGS - Comparar con thresholds
    # Si temp > 90: activar cooling
    li t6, 90
    bgt t4, t6, p1_set_cooling
    
    # Si temp < 55: desactivar cooling
    li t6, 55
    blt t4, t6, p1_clear_cooling
    
    j p1_print_temp

p1_set_cooling:
    la t5, cooling_flag
    li t6, 1
    sw t6, 0(t5)
    # Imprimir flag activation con identificador P1
    li t0, 0x10000000
    li t1, 'P'
    sb t1, 0(t0)
    li t1, '1'
    sb t1, 0(t0)
    li t1, ':'
    sb t1, 0(t0)
    li t1, '['
    sb t1, 0(t0)
    li t1, 'C'
    sb t1, 0(t0)
    li t1, 'O'
    sb t1, 0(t0)
    li t1, 'N'
    sb t1, 0(t0)
    li t1, ']'
    sb t1, 0(t0)
    li t1, ' '
    sb t1, 0(t0)
    j p1_print_temp

p1_clear_cooling:
    la t5, cooling_flag
    sw zero, 0(t5)
    # Imprimir flag deactivation con identificador P1
    li t0, 0x10000000
    li t1, 'P'
    sb t1, 0(t0)
    li t1, '1'
    sb t1, 0(t0)
    li t1, ':'
    sb t1, 0(t0)
    li t1, '['
    sb t1, 0(t0)
    li t1, 'C'
    sb t1, 0(t0)
    li t1, 'O'
    sb t1, 0(t0)
    li t1, 'F'
    sb t1, 0(t0)
    li t1, 'F'
    sb t1, 0(t0)
    li t1, ']'
    sb t1, 0(t0)
    li t1, ' '
    sb t1, 0(t0)
    j p1_print_temp

p1_print_temp:
    # Imprimir temperatura actual (formato: P1:T[XX]) con identificador
    li t0, 0x10000000
    li t1, 'P'
    sb t1, 0(t0)
    li t1, '1'
    sb t1, 0(t0)
    li t1, ':'
    sb t1, 0(t0)
    li t1, 'T'
    sb t1, 0(t0)
    li t1, '['
    sb t1, 0(t0)
    
    # Obtener índice actual
    la t1, temps_index
    lw t1, 0(t1)
    
    # Convertir a ASCII (2 dígitos)
    li t2, 10
    div t3, t1, t2         # t3 = tens
    rem t2, t1, t2         # t2 = ones
    
    # Imprimir decena
    addi t3, t3, 48        # Convertir a ASCII
    sb t3, 0(t0)
    
    # Imprimir unidad
    addi t2, t2, 48        # Convertir a ASCII
    sb t2, 0(t0)
    
    li t1, ']'
    sb t1, 0(t0)
    li t1, ' '
    sb t1, 0(t0)
    
    # Incrementar temps_index (CRÍTICO: solo UNA temperatura por invocación)
    la t1, temps_index
    lw t2, 0(t1)
    addi t2, t2, 1
    sw t2, 0(t1)
    
    # RETORNAR (para que se ejecute el siguiente proceso)
    ret

p1_done:
    ret

# ============================================================================
# PROCESS 2: Cooler Control basado en temperatura
# ============================================================================
process2_cooler_sbi:

p2_loop:
    # Leer cooling_flag
    la t1, cooling_flag
    lw t2, 0(t1)
    
    # Si flag está activo, imprimir estado del cooler
    beqz t2, p2_cooler_off
    
    # Cooler ON con identificador P2
    li t0, 0x10000000
    li t1, 'P'
    sb t1, 0(t0)
    li t1, '2'
    sb t1, 0(t0)
    li t1, ':'
    sb t1, 0(t0)
    li t1, '['
    sb t1, 0(t0)
    li t1, 'C'
    sb t1, 0(t0)
    li t1, 'o'
    sb t1, 0(t0)
    li t1, 'O'
    sb t1, 0(t0)
    li t1, 'N'
    sb t1, 0(t0)
    li t1, ']'
    sb t1, 0(t0)
    li t1, ' '
    sb t1, 0(t0)
    j p2_continue

p2_cooler_off:
    # Cooler OFF con identificador P2
    li t0, 0x10000000
    li t1, 'P'
    sb t1, 0(t0)
    li t1, '2'
    sb t1, 0(t0)
    li t1, ':'
    sb t1, 0(t0)
    li t1, '['
    sb t1, 0(t0)
    li t1, 'C'
    sb t1, 0(t0)
    li t1, 'o'
    sb t1, 0(t0)
    li t1, 'F'
    sb t1, 0(t0)
    li t1, 'F'
    sb t1, 0(t0)
    li t1, ']'
    sb t1, 0(t0)
    li t1, ' '
    sb t1, 0(t0)

p2_continue:
    # Leer temp_actual
    la t1, temp_actual
    lw t2, 0(t1)
    
    # Imprimir "P2:T=XX " con identificador
    li t0, 0x10000000
    li t1, 'P'
    sb t1, 0(t0)
    li t1, '2'
    sb t1, 0(t0)
    li t1, ':'
    sb t1, 0(t0)
    li t1, 'T'
    sb t1, 0(t0)
    li t1, '='
    sb t1, 0(t0)
    
    # Convertir temperatura a ASCII (2 dígitos)
    li t3, 10
    div t4, t2, t3         # t4 = decena
    rem t5, t2, t3         # t5 = unidad
    
    addi t4, t4, 48
    sb t4, 0(t0)
    
    addi t5, t5, 48
    sb t5, 0(t0)
    
    li t1, ' '
    sb t1, 0(t0)
    
    
p2_done:
    ret

# ============================================================================
# PROCESS 3: UART Monitor (Preemptive - retorna después de una iteración)
# ============================================================================
process3_uart_sbi:
    # Capture CPU cycles (rdcycle)
    rdcycle t0
    la t2, cycle_count_p3
    sw t0, 0(t2)
    
    # Check if system still active (temps_index < temps_len)
    la t3, temps_index
    lw t4, 0(t3)
    la t5, temps_len
    lw t6, 0(t5)
    bge t4, t6, p3_done         # If done processing, exit
    
    # Read from UART buffer (check one time for data)
    la t0, uart_buffer
    lw t1, 0(t0)
    
    beqz t1, p3_return          # If buffer empty, just return
    
    # Save last received datum
    la t2, uart_last
    sw t1, 0(t2)
    
    # Clear buffer
    sw zero, 0(t0)
    
    # Print received data marker con identificador P3
    li t0, 0x10000000
    li t1, 'P'
    sb t1, 0(t0)
    li t1, '3'
    sb t1, 0(t0)
    li t1, ':'
    sb t1, 0(t0)
    li t1, 'R'
    sb t1, 0(t0)
    li t1, ':'
    sb t1, 0(t0)
    
p3_return:
    # Retornar para que se ejecute el siguiente proceso
    ret

p3_done:
    # Si ya procesamos todas las temperaturas, solo retornar
    ret
