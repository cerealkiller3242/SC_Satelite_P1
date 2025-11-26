# ============================================================================
# sbi_console.s - Console I/O via SBI (no acceso directo a UART)
# ============================================================================
# SBI Extension 0x10: Console (env_uart)
# Function 0: putchar(a0)
# Function 1: getchar(a0)

.section .text
.globl sbi_putchar
.globl sbi_puts

# ============================================================================
# sbi_putchar(a0=char) - Imprime un carácter via SBI
# ============================================================================
sbi_putchar:
    # a0 = character
    li a7, 0x10               # ext: 0x10 (Console)
    li a6, 0                  # func: 0 (putchar)
    ecall
    ret

# ============================================================================
# sbi_puts(a0=string*) - Imprime una cadena via SBI
# ============================================================================
sbi_puts:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw a0, 4(sp)              # Guardar puntero de cadena
    
    mv t0, a0                  # t0 = puntero a cadena
    
.sbi_puts_loop:
    lb a0, 0(t0)               # Cargar carácter
    beqz a0, .sbi_puts_done    # Si es \0, terminar
    
    # Llamar sbi_putchar
    li a7, 0x10
    li a6, 0
    ecall
    
    addi t0, t0, 1
    j .sbi_puts_loop
    
.sbi_puts_done:
    lw a0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 8
    ret
