    .option rvc
    .section .text._start
    .globl _start
    .extern main
    .extern kernel_start
    .extern trap_handler
    .extern setup_timer
    .extern __bss_start
    .extern __bss_end
    .extern __stack_top

_start:
    # Configurar stack pointer
    la sp, __stack_top
    
    # Limpiar BSS
    la t0, __bss_start
    la t1, __bss_end
clear_bss:
    bge t0, t1, bss_done
    sw zero, 0(t0)
    addi t0, t0, 4
    j clear_bss

bss_done:
    # =================================================================
    # CONFIGURAR TRAP VECTOR (pero SIN habilitar interrupciones aún)
    # =================================================================
    
    # 1. Configurar trap vector (mtvec) - modo directo
    la t0, trap_handler
    csrw mtvec, t0
    
    # 2. Configurar MIE para timer (pero sin habilitar globalmente aún)
    li t0, 0x80                 # bit 7 = Machine Timer Interrupt Enable
    csrw mie, t0                # csrw (no csrs) para evitar habilitar otros bits
    
    # NOTA: NO habilitamos MSTATUS.MIE todavía
    # El scheduler_start habilitará las interrupciones cuando esté listo
    
    # =================================================================
    # INICIAR SISTEMA
    # =================================================================
    
    # Llamar a main (esto llama a kernel_start, que llama a scheduler_start)
    call main
    
    # Si main retorna, loop infinito
_hang:
    j _hang
