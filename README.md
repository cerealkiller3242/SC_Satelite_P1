# SC_Satelite_P1 - Sistema de Control Térmico de Satélite en RISC-V

**Proyecto de Scheduling Preemptivo con 3 Procesos Concurrentes en Arquitectura RISC-V 32-bit**

---

## 📋 Descripción General

Este proyecto implementa un **sistema de scheduling preemptivo** en arquitectura RISC-V emulado en QEMU, que simula el control térmico de un satélite en órbita. El sistema ejecuta **3 procesos independientes** de forma concurrente mediante interrupciones de timer hardware (round-robin con quantum de 10,000 ciclos), demostrando conceptos fundamentales de sistemas operativos embebidos.

### Características Principales

- ✅ **3 procesos concurrentes** (P1, P2, P3) con sincronización de datos compartidos
- ✅ **Scheduling preemptivo round-robin** basado en interrupciones de timer
- ✅ **4 escenarios diferentes** que varían el orden de ejecución
- ✅ **Escenario 4 con syscalls** para emular llamadas al sistema
- ✅ **Compilación RISC-V baremetal** sin depender del kernel Linux
- ✅ **Ejecución en QEMU** con output via UART/SBI

---

## 🎯 Los 3 Procesos del Sistema

### **Proceso 1 (P1): Lectura de Temperaturas**
```
Responsabilidad: Monitorear sensores térmicos del satélite

Acciones:
  1. Lee temperatura[i] del array
  2. Compara con umbrales:
     - Si T > 90°C  → cooling_flag = 1 (ACTIVO)
     - Si T < 55°C  → cooling_flag = 0 (INACTIVO)
  3. Imprime: "P1: [CON] T=XX°C" o "P1: [COFF] T=XX°C"
  4. Incrementa temps_index
  5. Se repite 100 veces (una temperatura por interrupción)

```

### **Proceso 2 (P2): Monitoreo del Sistema de Enfriamiento**
```
Responsabilidad: Supervisar el estado del cooling

Acciones:
  1. Lee cooling_flag (escrito por P1)
  2. Verifica estado actual del cooler
  3. Imprime: "P2: COOLER [ON]" o "P2: COOLER [OFF]"
  4. Registra cambios de estado

Sincronización: Depende del P1
```

### **Proceso 3 (P3): Supervisión de Buffer UART**
```
Responsabilidad: Gestionar comunicación serial

Acciones:
  1. Monitorea el estado del buffer UART
  2. Chequea si hay datos disponibles
  3. Registra último dato recibido
  4. Imprime: "P3: UART recibido..."

Característica: Crítico para comunicación
```

---

## 🎪 Los 4 Escenarios de Scheduling

| # | Nombre | Orden | Descripción | Caso de Uso |
|---|--------|-------|-------------|------------|
| **S1** | Baseline | P1→P2→P3 | Orden secuencial natural | Caso base de comparación |
| **S2** | Alt. Orden 1 | P1→P3→P2 | UART antes que monitoring | Cuando telemetría es crítica |
| **S3** | Alt. Orden 2 | P2→P1→P3 | Monitoring primero | Cuando estado previo es importante |
| **S4** | Con Syscalls | P1→P2→P3 + ECALL | Syscalls integradas | Emular OS real con interrupciones |

### Diferencia S1-S3 vs S4

```
ESCENARIOS 1-3 (Flujo Normal):
Scheduler → [Restaurar contexto] → [Ejecutar proceso] → Interrupt → Switch

ESCENARIO 4 (Con Syscalls):
Scheduler → [Restaurar contexto] → [ECALL] → [dispatcher] → [Ejecutar] → Interrupt → Switch
```


---

## 🛠️ Requisitos Previos

### 1. Toolchain RISC-V 32-bit

```bash
# En Debian/Ubuntu:
sudo apt-get install gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu

# O instalar riscv32 específicamente:
sudo apt-get install gcc-riscv32-linux-gnu binutils-riscv32-linux-gnu
```

**Verificar instalación:**
```bash
riscv32-linux-gnu-gcc --version
riscv32-linux-gnu-as --version
riscv32-linux-gnu-ld --version
```

### 2. QEMU System Emulator

```bash
# En Debian/Ubuntu:
sudo apt-get install qemu-system-riscv32

# Verificar:
qemu-system-riscv32 --version
```

### 3. Utilidades (opcional pero recomendado)

```bash
# Para desensamblado y análisis:
sudo apt-get install binutils

# Para profiling:
sudo apt-get install linux-tools-generic
```

---

## 🚀 Cómo Ejecutar el Proyecto

### Opción 1: Compilación Rápida de un Escenario

```bash
cd /c/Users/cerea/OneDrive/Documentos/SC_Satelite_P1

# Compilar Escenario 1 (S1: P1→P2→P3)
make SCENARIO=1 baremetal

# Ejecutar con timeout de 3 segundos
timeout 3 qemu-system-riscv32 -machine virt -m 128M -serial stdio \
  -display none -kernel satelite.elf -monitor none 2>&1 > /tmp/riscv_output.txt

# Ver el output
cat /tmp/riscv_output.txt
```

### Opción 2: Compilar y Ejecutar Todos los Escenarios

```bash
cd /c/Users/cerea/OneDrive/Documentos/SC_Satelite_P1

# Escenario 1
make SCENARIO=1 baremetal
timeout 3 qemu-system-riscv32 -machine virt -m 128M -serial stdio \
  -display none -kernel satelite.elf -monitor none 2>&1 > /tmp/s1_output.txt
echo "=== ESCENARIO 1 ===" && cat /tmp/s1_output.txt

# Escenario 2
make SCENARIO=2 baremetal
timeout 3 qemu-system-riscv32 -machine virt -m 128M -serial stdio \
  -display none -kernel satelite.elf -monitor none 2>&1 > /tmp/s2_output.txt
echo "=== ESCENARIO 2 ===" && cat /tmp/s2_output.txt

# Escenario 3
make SCENARIO=3 baremetal
timeout 3 qemu-system-riscv32 -machine virt -m 128M -serial stdio \
  -display none -kernel satelite.elf -monitor none 2>&1 > /tmp/s3_output.txt
echo "=== ESCENARIO 3 ===" && cat /tmp/s3_output.txt

# Escenario 4 (con syscalls)
make SCENARIO=4 baremetal
timeout 3 qemu-system-riscv32 -machine virt -m 128M -serial stdio \
  -display none -kernel satelite.elf -monitor none 2>&1 > /tmp/s4_output.txt
echo "=== ESCENARIO 4 ===" && cat /tmp/s4_output.txt
```

### Opción 3: Compilar con Diferentes Sets de Temperaturas

```bash
# SET1: Órbita LEO realista (defecto)
make SCENARIO=1 TEMPERATURAS_SET=1 baremetal
timeout 3 qemu-system-riscv32 -machine virt -m 128M -serial stdio \
  -display none -kernel satelite.elf -monitor none

# SET2: Valores aleatorios
make SCENARIO=1 TEMPERATURAS_SET=2 baremetal
timeout 3 qemu-system-riscv32 -machine virt -m 128M -serial stdio \
  -display none -kernel satelite.elf -monitor none

# SET3: Temperatura constante 75°C
make SCENARIO=1 TEMPERATURAS_SET=3 baremetal
timeout 3 qemu-system-riscv32 -machine virt -m 128M -serial stdio \
  -display none -kernel satelite.elf -monitor none

# SET4: Rango lineal (0-100°C)
make SCENARIO=1 TEMPERATURAS_SET=4 baremetal
timeout 3 qemu-system-riscv32 -machine virt -m 128M -serial stdio \
  -display none -kernel satelite.elf -monitor none
```

### Opción 4: Limpiar y Recompilar Todo

```bash
cd /c/Users/cerea/OneDrive/Documentos/SC_Satelite_P1

# Limpiar archivos compilados
make clean

# Compilar Escenario 1
make SCENARIO=1 baremetal

# Ejecutar
timeout 3 qemu-system-riscv32 -machine virt -m 128M -serial stdio \
  -display none -kernel satelite.elf -monitor none
```

### Opción 5: Compilar un Escenario Combinado

```bash
# Escenario 2 con SET de temperaturas 3
make SCENARIO=2 TEMPERATURAS_SET=3 baremetal
timeout 3 qemu-system-riscv32 -machine virt -m 128M -serial stdio \
  -display none -kernel satelite.elf -monitor none
```

---

## 📊 Output Esperado

### Estructura del Output

```
KERNEL:S
START
[SCH] ESCENARIO_NUMBER
P1_S
[CON] T[00] [CON] T=92
[COFF] T[01] [COFF] T=45
[CON] T[02] [CON] T=78
...
P1D
P2_S
P2: Temperature=45, Cooler OFF
...
P2D
P3_S
P3: UART Status=0x00
...
P3D
FINISH
```

### Interpretación

| Símbolo | Significado |
|---------|-------------|
| `KERNEL:S` | Kernel iniciado y configurado |
| `[SCH] N` | Scheduler seleccionó escenario N |
| `P1_S` | Proceso 1 comenzó |
| `[CON] T=XX` | Cooling activado a temperatura XX°C |
| `[COFF] T=XX` | Cooling desactivado a temperatura XX°C |
| `P1D` | Proceso 1 terminó (100 temperaturas procesadas) |
| `P2_S` / `P2D` | Proceso 2 comenzó/terminó |
| `P3_S` / `P3D` | Proceso 3 comenzó/terminó |
| `FINISH` | Sistema completó toda la ejecución |

---

## 🔍 Flags de Compilación

El Makefile soporta las siguientes variables:

```bash
SCENARIO      # Escenario a ejecutar (1, 2, 3, o 4)
              # Default: 1

TEMPERATURAS_SET  # Set de temperaturas a usar (1, 2, 3, o 4)
                  # Default: 1

CFLAGS        # -march=rv32imac_zicsr -mabi=ilp32 -static -nostdlib
ASFLAGS       # -march=rv32imac_zicsr -mabi=ilp32
LDFLAGS       # -static -nostdlib -T linker.ld
```

---

## 🎓 Fundamentos Técnicos

### Mecanismo de Scheduling

```
Quantum = 10,000 ciclos de CPU

Ciclo 0:        P1 ejecuta
Ciclo 10,000:   ⚡ TIMER INTERRUPT
                Context Save (32 registros + PC + SP)
                Scheduler selecciona siguiente
                Context Restore
                MRET → P2 ejecuta

Ciclo 20,000:   ⚡ TIMER INTERRUPT
                Context Save
                Scheduler selecciona siguiente
                Context Restore
                MRET → P3 ejecuta

Ciclo 30,000:   ⚡ TIMER INTERRUPT
                Context Save
                Scheduler selecciona siguiente
                Context Restore
                MRET → P1 ejecuta (vuelve al inicio)
```

### Sincronización Entre Procesos

**Sin locks explícitos** - Sincronización por variables compartidas:

```
P1: cooling_flag ← (temp > 90) ? 1 : 0   [ESCRIBE]
                ↓
P2: if (cooling_flag == 1) print("ON")   [LEE]
```

**Memory barriers** implementados mediante:
- Volatile loads/stores en memoria
- Context switches que actúan como synchronization points

---

## 🧪 Validación y Testing

### Verificar Compilación Correcta

```bash
# Ver símbolos del ELF
riscv32-linux-gnu-nm satelite.elf | grep -E "process|scheduler"

# Ver secciones
riscv32-linux-gnu-objdump -h satelite.elf

# Desensamblado completo
riscv32-linux-gnu-objdump -D satelite.elf > satelite.dump
```

### Emulación en C (Alternativa)

Para testing rápido sin QEMU:

```bash
# Compilar emulador C
make interactive

# Ejecutar en modo automático
echo -e '1\n1' | ./satelite_interactive

# Ejecutar interactivamente
./satelite_interactive
```

---

## 📈 Rendimiento Esperado

### Métricas por Escenario (10,000 ciclos/quantum)

```
ESCENARIO 1 (P1→P2→P3):
  P1:     300 iteraciones × 33 ciclos/iteración ≈ 9,900 ciclos
  P2:     100 chequeos × 98 ciclos/chequeo ≈ 9,800 ciclos
  P3:     100 monitores × 95 ciclos/monitor ≈ 9,500 ciclos
  Total:  ~3,000 ms (3 segundos de ejecución)

ESCENARIO 4 (Con Syscalls):
  Overhead de ECALL/dispatcher ≈ 5-10%
  Tiempo total: ~3,150 ms (3.15 segundos)
```

---

## 🐛 Troubleshooting

### Problema: "riscv32-linux-gnu-gcc: not found"

**Solución:**
```bash
# Verificar instalación
which riscv32-linux-gnu-gcc

# Si no existe, instalar
sudo apt-get install gcc-riscv32-linux-gnu binutils-riscv32-linux-gnu

# O usar path explícito en Makefile
RISCV_PREFIX = /usr/bin/riscv32-linux-gnu-
```

### Problema: "qemu-system-riscv32: not found"

**Solución:**
```bash
# Instalar QEMU
sudo apt-get install qemu-system-riscv32

# Verificar
which qemu-system-riscv32
```

### Problema: Timeout durante ejecución

**Causas posibles:**
- Timeout muy corto (usar `timeout 3` mínimo)
- Ciclo infinito en algún proceso
- Memoria insuficiente (usar `-m 128M`)

**Solución:**
```bash
# Aumentar timeout a 5 segundos
timeout 5 qemu-system-riscv32 -machine virt -m 128M -serial stdio \
  -display none -kernel satelite.elf -monitor none
```

### Problema: Output vacío o incompleto

**Causas:**
- Buffer UART no flushed
- Ejecución terminó antes de esperado

**Solución:**
```bash
# Ver el output guardado
cat /tmp/riscv_output.txt | head -50

# Usar strace para debug
strace -e write timeout 3 qemu-system-riscv32 -machine virt -m 128M \
  -kernel satelite.elf 2>&1 | grep "START\|FINISH"
```

---

## 📚 Estructura de Código

### Flujo de Ejecución Simplificado

```
_start (start.s)
  │
  ├─ Configurar CSRs (mtvec, mstatus, mie)
  ├─ Inicializar stacks (P1, P2, P3)
  │
  ▼
kernel_start (kernel.c)
  │
  ├─ temps_ptr = dirección del array
  ├─ temps_len = 100
  ├─ Imprimir "KERNEL:S"
  │
  ▼
scheduler_start (scheduler_scenarios.s)
  │
  ├─ Seleccionar escenario (S1-S4)
  ├─ Cargar contexto del proceso inicial
  │
  ▼
MRET → Ejecución de Procesos
  │
  ├─ P1: Lee temperatura, escribe cooling_flag
  ├─ P2: Lee cooling_flag, registra estado
  ├─ P3: Chequea buffer UART
  │
  ▼ (Cada 10,000 ciclos)
TIMER INTERRUPT → trap_handler
  │
  ├─ Context Save (guardar registros)
  ├─ scheduler_interrupt_handler (seleccionar siguiente)
  ├─ Context Restore (cargar registros)
  │
  ▼
MRET → Continuar con siguiente proceso
```

---

## 📝 Variables Globales Importantes

```c
// Array de temperaturas (100 valores)
int *temps_ptr;

// Longitud del array
int temps_len;

// Índice actual (0-99)
int temps_index;

// Flag de cooling (0 = OFF, 1 = ON)
unsigned int cooling_flag;

// Estado del cooler
unsigned int cooler_state;

// Ciclos leídos por rdcycle
unsigned long long cycle_count_p1;
unsigned long long cycle_count_p2;
unsigned long long cycle_count_p3;

// Contador de interrupciones
unsigned int interrupt_count_p1;
```

---

## 🔐 Arquitectura de Seguridad

### Modo de Ejecución

- **Machine Mode (M-mode)**: Scheduler, trap handler, interrupts
**Nota**: Actualmente todos los procesos corren en M-mode. En un OS real, correrían en U-mode.

### Protección de Contexto

```
Context Save (Interrupt):
  ✓ 32 registros guardados en PCB
  ✓ PC guardado en mepc
  ✓ SP guardado
  
Context Restore (Scheduler):
  ✓ 32 registros restaurados
  ✓ PC restaurado mediante MRET
  ✓ SP restaurado
```

---

