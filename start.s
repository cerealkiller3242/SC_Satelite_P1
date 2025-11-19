    .option rvc
    .section .text._start
    .globl _start
    .extern main
    .extern kernel_start
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
    # Llamar a main
    call main
    
    # Si main retorna, loop infinito
_hang:
    j _hang
