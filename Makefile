# =============================================================================
# Makefile para SC_Satelite_P1
# Sistema de control de satélite en RISC-V Assembly
# =============================================================================

# Toolchain RISC-V
RISCV_PREFIX = riscv32-linux-gnu-
CC = $(RISCV_PREFIX)gcc
AS = $(RISCV_PREFIX)as
LD = $(RISCV_PREFIX)ld
OBJDUMP = $(RISCV_PREFIX)objdump

# Flags
CFLAGS = -Wall -g -O2 -march=rv32imac -mabi=ilp32 -static -nostdlib -nostartfiles
ASFLAGS = -march=rv32imac -mabi=ilp32
LDFLAGS = -static -nostdlib -T linker.ld

# Archivos fuente
C_SOURCES = main_riscv.c kernel.c memory_map.c stacks.c
ASM_SOURCES = start.s scheduler.s \
              Processes/Process1_temp.s \
              Processes/Process2_cooler.s \
              Processes/Process3_uart.s

# Objetos
C_OBJECTS = $(C_SOURCES:.c=.o)
ASM_OBJECTS = $(ASM_SOURCES:.s=.o)

# Ejecutables
TARGET = satelite.elf
INTERACTIVE = satelite_interactive

.PHONY: all baremetal interactive run dump sim clean

# Por defecto: versión interactiva
all: interactive

# =============================================================================
# RISC-V BARE-METAL (sin I/O, configuración fija)
# =============================================================================
baremetal: $(TARGET)

$(TARGET): $(C_OBJECTS) $(ASM_OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $^
	@echo "✓ Compilado: $(TARGET)"
	@$(OBJDUMP) -h $(TARGET) | grep -E "\.text|\.data|\.bss"

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

Processes/%.o: Processes/%.s
	$(AS) $(ASFLAGS) $< -o $@

# Desensamblado
dump: $(TARGET)
	$(OBJDUMP) -D $(TARGET) > $(TARGET).dump
	@echo "✓ Desensamblado: $(TARGET).dump"

# QEMU
sim: $(TARGET)
	@echo "Ejecutando RISC-V en QEMU..."
	qemu-system-riscv32 -machine virt -nographic -bios none -kernel $(TARGET)

# =============================================================================
# EMULACIÓN EN C (con I/O interactivo)
# =============================================================================
interactive: wrapper_interactive.c memory_map.c
	@echo "Compilando emulación C con I/O..."
	gcc -Wall -g -pthread wrapper_interactive.c memory_map.c -o $(INTERACTIVE)
	@echo "✓ Compilado: $(INTERACTIVE)"

run: interactive
	./$(INTERACTIVE)

# =============================================================================
# LIMPIEZA
# =============================================================================
clean:
	rm -f *.o Processes/*.o $(TARGET) $(INTERACTIVE) *.elf.dump
