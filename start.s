    .option rvc
    .section .text._start
    .globl _start
    .extern main
    .extern __bss_start
    .extern __bss_end
    .extern __stack_top

_start:
    # Configurar stack pointer PRIMERO
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
    # Imprimir "START" vía UART directo (OpenSBI lo permite)
    li t0, 0x10000000
    li t1, 'S'
    sb t1, 0(t0)
    li t1, 'T'
    sb t1, 0(t0)
    li t1, 'A'
    sb t1, 0(t0)
    li t1, 'R'
    sb t1, 0(t0)
    li t1, 'T'
    sb t1, 0(t0)
    li t1, '\n'
    sb t1, 0(t0)
    
    # Llamar a main
    call main
    
    # Si main retorna, loop infinito
_hang:
    j _hang

# Helper function para imprimir START
sbi_putchar_start:
    # Guardar RA
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # Imprimir S
    li a0, 'S'
    li a7, 0x10
    li a6, 0
    ecall
    
    # Imprimir T
    li a0, 'T'
    li a7, 0x10
    li a6, 0
    ecall
    
    # Imprimir A
    li a0, 'A'
    li a7, 0x10
    li a6, 0
    ecall
    
    # Imprimir R
    li a0, 'R'
    li a7, 0x10
    li a6, 0
    ecall
    
    # Imprimir T
    li a0, 'T'
    li a7, 0x10
    li a6, 0
    ecall
    
    # Imprimir newline
    li a0, '\n'
    li a7, 0x10
    li a6, 0
    ecall
    
    # Restaurar RA y retornar
    lw ra, 0(sp)
    addi sp, sp, 4
    ret
