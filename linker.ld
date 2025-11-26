/* Linker script para RISC-V 32-bit
 * Sistema satelital con scheduler y procesos
 */

OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x80200000, LENGTH = 128M
}

SECTIONS
{
    . = 0x80200000;
    
    .text : {
        *(.text._start)
        *(.text*)
        . = ALIGN(4);
    } > RAM
    
    .rodata : {
        *(.rodata*)
        . = ALIGN(4);
    } > RAM
    
    .data : {
        *(.data*)
        *(.sdata*)
        . = ALIGN(4);
    } > RAM
    
    .bss : {
        __bss_start = .;
        *(.bss*)
        *(.sbss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > RAM
    
    /* Stack begins right after BSS */
    . = ALIGN(4096);
    __stack_top = .;
}
