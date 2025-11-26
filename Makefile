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

# Default scenario if not specified
SCENARIO ?= 1

# Default temperature set if not specified
TEMPERATURAS_SET ?= 1

# Flags
CFLAGS = -Wall -g -O2 -march=rv32imac_zicsr -mabi=ilp32 -static -nostdlib -nostartfiles -DSCENARIO=$(SCENARIO) -DTEMPERATURAS_SET=$(TEMPERATURAS_SET)
ASFLAGS = -march=rv32imac_zicsr -mabi=ilp32
LDFLAGS = -static -nostdlib -T linker.ld

# Archivos fuente
C_SOURCES = main_riscv.c kernel.c memory_map.c stacks.c

# Seleccionar archivos ASM según SCENARIO
ifeq ($(SCENARIO),4)
    # Escenario 4: Archivos separados con syscalls
    ASM_SOURCES = start.s sbi_console.s scheduler_scenarios_s4.s processes_sbi_s4.s
else
    # Escenarios 1-3: Archivos estándar con interrupciones
    ASM_SOURCES = start.s sbi_console.s scheduler_scenarios.s processes_sbi.s
endif

# Objetos
C_OBJECTS = $(C_SOURCES:.c=.o)
ASM_OBJECTS = $(ASM_SOURCES:.s=.o)

# Ejecutables
TARGET = satelite.elf
INTERACTIVE = satelite_interactive

.PHONY: all baremetal interactive run dump sim clean help

# Help target
help:
	@echo "╔═══════════════════════════════════════════════════════════╗"
	@echo "║   SC_Satelite_P1 - Makefile Help                          ║"
	@echo "╚═══════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "COMPILACIÓN RISC-V BAREMETAL:"
	@echo "  make baremetal                  # Compilar con defaults"
	@echo "  make SCENARIO=1 baremetal       # Escenario 1 (P1→P2→P3)"
	@echo "  make SCENARIO=2 baremetal       # Escenario 2 (P1→P3→P2)"
	@echo "  make SCENARIO=3 baremetal       # Escenario 3 (P2→P1→P3)"
	@echo "  make SCENARIO=4 baremetal       # Escenario 4 (Syscalls)"
	@echo ""
	@echo "TEMPERATURA:"
	@echo "  make TEMPERATURAS_SET=1 baremetal  # SET1: Órbita LEO"
	@echo "  make TEMPERATURAS_SET=2 baremetal  # SET2: Aleatorio"
	@echo "  make TEMPERATURAS_SET=3 baremetal  # SET3: Constante 75°C"
	@echo "  make TEMPERATURAS_SET=4 baremetal  # SET4: Rango lineal"
	@echo ""
	@echo "EJEMPLO COMBINADO:"
	@echo "  make SCENARIO=2 TEMPERATURAS_SET=2 baremetal"
	@echo ""
	@echo "EMULACIÓN C (x86_64):"
	@echo "  make interactive                # Compilar emulación"
	@echo "  ./satelite_interactive          # Ejecutar (interactivo)"
	@echo "  echo -e '1\\n1' | ./satelite_interactive  # Automático"
	@echo ""
	@echo "QEMU:"
	@echo "  make sim                        # Ejecutar en QEMU"
	@echo ""
	@echo "UTILIDADES:"
	@echo "  make clean                      # Limpiar objetos"
	@echo "  make dump                       # Desensamblado"
	@echo "  make help                       # Esta ayuda"
	@echo ""

# Por defecto: mostrar ayuda
all: help

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
	@echo "Compilando emulación C con I/O y backtrace..."
	gcc -Wall -g -rdynamic -pthread wrapper_interactive.c memory_map.c -o $(INTERACTIVE)
	@echo "✓ Compilado: $(INTERACTIVE) (con símbolos de backtrace)"

run: interactive
	./$(INTERACTIVE)

# =============================================================================
# PERFORMANCE PROFILING (Problema 6)
# =============================================================================

# Compilar con profiling habilitado (gprof)
profile: wrapper_interactive.c memory_map.c
	@echo "Compilando con profiling (gprof)..."
	gcc -Wall -g -pg -rdynamic -pthread wrapper_interactive.c memory_map.c -o $(INTERACTIVE)_prof
	@echo "✓ Compilado: $(INTERACTIVE)_prof (con profiling)"
	@echo ""
	@echo "Para usar:"
	@echo "  1. Ejecutar: ./$(INTERACTIVE)_prof"
	@echo "  2. Analizar: gprof $(INTERACTIVE)_prof gmon.out > analysis.txt"
	@echo "  3. Ver: cat analysis.txt"

# Ejecutar profiling completo
run-profile: profile
	@echo "Ejecutando con profiling..."
	./$(INTERACTIVE)_prof
	@echo ""
	@echo "Generando reporte de profiling..."
	gprof $(INTERACTIVE)_prof gmon.out > gprof_report.txt
	@echo "✓ Reporte generado: gprof_report.txt"
	@echo ""
	@head -50 gprof_report.txt

# Análisis rápido (top 10 funciones)
profile-top: gmon.out
	@echo "Top 10 funciones por tiempo de CPU:"
	@gprof -b $(INTERACTIVE)_prof gmon.out | grep -A 15 "Flat profile:" | tail -15

# Limpiar archivos de profiling
clean-profile:
	rm -f gmon.out $(INTERACTIVE)_prof gprof_report.txt perf.data perf.data.old

# =============================================================================
# LIMPIEZA
# =============================================================================
clean:
	rm -f *.o Processes/*.o Processes/Scenario4/*.o $(TARGET) $(INTERACTIVE) $(INTERACTIVE)_prof *.elf.dump gmon.out gprof_report.txt perf.data perf.data.old
