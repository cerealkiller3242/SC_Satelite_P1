    .option rvc
    .section .text
    .globl trap_handler
    .globl setup_timer
    .extern current_process_id
    .extern pcb_p1
    .extern pcb_p2
    .extern pcb_p3
    .extern next_scheduled_process

# =============================================================================
# TRAP HANDLER - Maneja interrupciones de timer
# =============================================================================
# Guarda el contexto completo del proceso actual en su PCB
# Llama al scheduler para obtener el siguiente proceso
# Restaura el contexto del siguiente proceso
# =============================================================================

trap_handler:
    # Verificar mcause para confirmar que es timer interrupt
    csrr t0, mcause
    li t1, 0x80000007           # Bit 31 = 1 (interrupt), código 7 = timer
    bne t0, t1, trap_error      # Si no es timer, error
    
    # Guardar contexto en stack temporal
    csrw mscratch, sp           # Salvar SP actual en mscratch
    
    # Cargar dirección del área temporal y posicionarse al final
    la sp, temp_context_save
    addi sp, sp, 256            # Apuntar al final del área (256 bytes)
    
    # Guardar todos los registros (stack crece hacia abajo)
    addi sp, sp, -128           # Reservar espacio para 32 registros
    sw x1, 0(sp)                # ra
    # x2 (sp) se guarda después desde mscratch
    sw x3, 8(sp)                # gp
    sw x4, 12(sp)               # tp
    sw x5, 16(sp)               # t0
    sw x6, 20(sp)               # t1
    sw x7, 24(sp)               # t2
    sw x8, 28(sp)               # s0
    sw x9, 32(sp)               # s1
    sw x10, 36(sp)              # a0
    sw x11, 40(sp)              # a1
    sw x12, 44(sp)              # a2
    sw x13, 48(sp)              # a3
    sw x14, 52(sp)              # a4
    sw x15, 56(sp)              # a5
    sw x16, 60(sp)              # a6
    sw x17, 64(sp)              # a7
    sw x18, 68(sp)              # s2
    sw x19, 72(sp)              # s3
    sw x20, 76(sp)              # s4
    sw x21, 80(sp)              # s5
    sw x22, 84(sp)              # s6
    sw x23, 88(sp)              # s7
    sw x24, 92(sp)              # s8
    sw x25, 96(sp)              # s9
    sw x26, 100(sp)             # s10
    sw x27, 104(sp)             # s11
    sw x28, 108(sp)             # t3
    sw x29, 112(sp)             # t4
    sw x30, 116(sp)             # t5
    sw x31, 120(sp)             # t6
    
    # Guardar mepc (PC donde se interrumpió)
    csrr t0, mepc
    sw t0, 124(sp)
    
    # Recuperar SP original de mscratch y guardarlo
    csrr t1, mscratch
    sw t1, 4(sp)                # Guardar SP original en posición x2
    
    # Copiar contexto temporal al PCB del proceso actual
    la t0, current_process_id
    lw t0, 0(t0)                # Cargar ID del proceso actual
    
    li t1, 1
    beq t0, t1, save_to_p1
    li t1, 2
    beq t0, t1, save_to_p2
    li t1, 3
    beq t0, t1, save_to_p3
    j trap_done                 # Error: proceso inválido

save_to_p1:
    la t2, pcb_p1
    j copy_context_to_pcb
save_to_p2:
    la t2, pcb_p2
    j copy_context_to_pcb
save_to_p3:
    la t2, pcb_p3

copy_context_to_pcb:
    # t2 = dirección del PCB destino
    # sp = dirección del contexto temporal
    
    # Copiar PC (está en offset 124 del stack temporal)
    lw t3, 124(sp)
    sw t3, 0(t2)                # PCB.pc = mepc
    
    # Copiar SP (está en offset 4 del stack temporal)
    lw t3, 4(sp)
    sw t3, 4(t2)                # PCB.sp = sp original
    
    # Copiar 32 registros a PCB.regs[0..31]
    # Stack temporal tiene: x1,x2,x3...x31 en offsets 0,4,8...124
    addi t2, t2, 8              # t2 apunta a PCB.regs[0]
    mv t4, sp                   # t4 = fuente (stack temporal)
    li t5, 32                   # contador de registros
copy_regs_loop:
    lw t3, 0(t4)                # Leer registro del stack
    sw t3, 0(t2)                # Escribir a PCB.regs[]
    addi t4, t4, 4              # Siguiente registro en stack
    addi t2, t2, 4              # Siguiente posición en PCB
    addi t5, t5, -1
    bnez t5, copy_regs_loop


    # Guardar mcause
    csrr t3, mcause
    la t4, last_mcause
    sw t3, 0(t4)
    
    # Guardar PC y SP en variables last_pc_pX / last_sp_pX según proceso actual
    la t0, current_process_id
    lw t0, 0(t0)
    
    li t1, 1
    beq t0, t1, save_metrics_p1
    li t1, 2
    beq t0, t1, save_metrics_p2
    li t1, 3
    beq t0, t1, save_metrics_p3
    j metrics_done

save_metrics_p1:
    # Guardar PC de P1
    lw t3, 124(sp)              # PC desde stack temporal
    la t4, last_pc_p1
    sw t3, 0(t4)
    
    # Guardar SP de P1
    lw t3, 4(sp)                # SP desde stack temporal
    la t4, last_sp_p1
    sw t3, 0(t4)
    
    # Incrementar contador de interrupciones de P1
    la t4, interrupt_count_p1
    lw t3, 0(t4)
    addi t3, t3, 1
    sw t3, 0(t4)
    j metrics_done

save_metrics_p2:
    # Guardar PC de P2
    lw t3, 124(sp)
    la t4, last_pc_p2
    sw t3, 0(t4)
    
    # Guardar SP de P2
    lw t3, 4(sp)
    la t4, last_sp_p2
    sw t3, 0(t4)
    
    # Incrementar contador de interrupciones de P2
    la t4, interrupt_count_p2
    lw t3, 0(t4)
    addi t3, t3, 1
    sw t3, 0(t4)
    j metrics_done

save_metrics_p3:
    # Guardar PC de P3
    lw t3, 124(sp)
    la t4, last_pc_p3
    sw t3, 0(t4)
    
    # Guardar SP de P3
    lw t3, 4(sp)
    la t4, last_sp_p3
    sw t3, 0(t4)
    
    # Incrementar contador de interrupciones de P3
    la t4, interrupt_count_p3
    lw t3, 0(t4)
    addi t3, t3, 1
    sw t3, 0(t4)

metrics_done:
    # Continuar con el flujo normal

trap_done:
    # Reprogramar timer para próxima interrupción
    jal ra, setup_timer
    
    # Llamar al scheduler para obtener siguiente proceso
    jal ra, get_next_process
    # Retorna en a0 el ID del siguiente proceso
    
    # Actualizar current_process_id
    la t0, current_process_id
    sw a0, 0(t0)
    
    # Cargar contexto del siguiente proceso
    li t1, 1
    beq a0, t1, load_from_p1
    li t1, 2
    beq a0, t1, load_from_p2
    li t1, 3
    beq a0, t1, load_from_p3
    j trap_error

load_from_p1:
    la t2, pcb_p1
    j restore_context_from_pcb
load_from_p2:
    la t2, pcb_p2
    j restore_context_from_pcb
load_from_p3:
    la t2, pcb_p3

restore_context_from_pcb:
    # t2 = dirección del PCB fuente
    
    # Cargar PC a mepc
    lw t3, 0(t2)
    csrw mepc, t3
    
    # Cargar SP a mscratch (temporal, restaurar al final)
    lw t4, 4(t2)
    csrw mscratch, t4
    
    # Cargar registros desde PCB.regs[0..31]
    addi t2, t2, 8              # t2 apunta a PCB.regs[0]
    
    lw x1, 0(t2)                # ra (x1)
    # x2 (sp) se restaura al final desde mscratch
    lw x3, 8(t2)                # gp (x3)
    lw x4, 12(t2)               # tp (x4)
    lw x5, 16(t2)               # t0 (x5)
    lw x6, 20(t2)               # t1 (x6)
    # x7 (t2) NO se restaura aquí, lo haremos al final
    # lw x7, 24(t2)             # SKIP: t2 aún se necesita como puntero
    lw x8, 28(t2)               # s0/fp (x8)
    lw x9, 32(t2)               # s1 (x9)
    lw x10, 36(t2)              # a0 (x10)
    lw x11, 40(t2)              # a1 (x11)
    lw x12, 44(t2)              # a2 (x12)
    lw x13, 48(t2)              # a3 (x13)
    lw x14, 52(t2)              # a4 (x14)
    lw x15, 56(t2)              # a5 (x15)
    lw x16, 60(t2)              # a6 (x16)
    lw x17, 64(t2)              # a7 (x17)
    lw x18, 68(t2)              # s2 (x18)
    lw x19, 72(t2)              # s3 (x19)
    lw x20, 76(t2)              # s4 (x20)
    lw x21, 80(t2)              # s5 (x21)
    lw x22, 84(t2)              # s6 (x22)
    lw x23, 88(t2)              # s7 (x23)
    lw x24, 92(t2)              # s8 (x24)
    lw x25, 96(t2)              # s9 (x25)
    lw x26, 100(t2)             # s10 (x26)
    lw x27, 104(t2)             # s11 (x27)
    lw x28, 108(t2)             # t3 (x28)
    lw x29, 112(t2)             # t4 (x29)
    lw x30, 116(t2)             # t5 (x30)
    lw x31, 120(t2)             # t6 (x31)
    
    # Restaurar t2 (x7) - se hace al final porque se usaba como puntero
    lw x7, 24(t2)               # t2 (x7)
    
    # Restaurar SP desde mscratch (último para no corromper registros)
    csrr sp, mscratch
    
    # Retornar del trap (salta a mepc con estado restaurado)
    mret

trap_error:
    # Loop infinito en caso de error
    j trap_error

# =============================================================================
# SETUP TIMER - Configura MTIMECMP para próxima interrupción
# =============================================================================
# QEMU virt machine memory-mapped timer registers:
# MTIME:    0x0200BFF8 (64-bit, read-only, incrementa cada ciclo)
# MTIMECMP: 0x02004000 (64-bit, genera interrupt cuando MTIME >= MTIMECMP)
# =============================================================================

setup_timer:
    # Cargar MTIME actual (64-bit)
    li t0, 0x0200BFF8
    lw t1, 0(t0)                # MTIME low
    lw t2, 4(t0)                # MTIME high
    
    # Sumar quantum (10000 ciclos)
    li t3, 10000
    add t1, t1, t3              # Sumar a low word
    sltu t4, t1, t3             # Detectar overflow (carry)
    add t2, t2, t4              # Sumar carry a high word
    
    # Escribir a MTIMECMP (64-bit)
    # Truco: escribir -1 a low primero para evitar interrupt espuria
    li t0, 0x02004000
    li t5, -1
    sw t5, 0(t0)                # MTIMECMP low = 0xFFFFFFFF (temporal)
    sw t2, 4(t0)                # MTIMECMP high = valor correcto
    sw t1, 0(t0)                # MTIMECMP low = valor correcto
    
    ret

# =============================================================================
# GET NEXT PROCESS - Determina siguiente proceso según escenario
# =============================================================================
# Retorna en a0 el ID del siguiente proceso (1, 2 o 3)
# =============================================================================

get_next_process:
    # Obtener escenario actual
    la t0, current_scenario
    lw t0, 0(t0)
    
    # Obtener proceso actual
    la t1, current_process_id
    lw t1, 0(t1)
    
    # Obtener índice dentro del escenario
    la t2, scenario_index
    lw t3, 0(t2)
    addi t3, t3, 1              # Incrementar índice
    li t4, 3
    rem t3, t3, t4              # Módulo 3 (0, 1, 2)
    sw t3, 0(t2)                # Guardar nuevo índice
    
    # Determinar siguiente según escenario
    li t4, 1
    beq t0, t4, scenario_1_next
    li t4, 2
    beq t0, t4, scenario_2_next
    li t4, 3
    beq t0, t4, scenario_3_next
    # Default: scenario 1
    j scenario_1_next

scenario_1_next:
    # P1 → P2 → P3
    li t4, 0
    beq t3, t4, return_p1
    li t4, 1
    beq t3, t4, return_p2
    j return_p3

scenario_2_next:
    # P1 → P3 → P2
    li t4, 0
    beq t3, t4, return_p1
    li t4, 1
    beq t3, t4, return_p3
    j return_p2

scenario_3_next:
    # P2 → P1 → P3
    li t4, 0
    beq t3, t4, return_p2
    li t4, 1
    beq t3, t4, return_p1
    j return_p3

return_p1:
    li a0, 1
    ret
return_p2:
    li a0, 2
    ret
return_p3:
    li a0, 3
    ret

# =============================================================================
# DATOS
# =============================================================================

    .section .bss
    .align 4
temp_context_save:
    .space 256                  # Espacio para guardar contexto temporalmente

    .section .data
    .globl current_process_id
current_process_id:
    .word 1                     # Proceso inicial: P1

scenario_index:
    .word 0                     # Índice dentro del escenario (0, 1, 2)
