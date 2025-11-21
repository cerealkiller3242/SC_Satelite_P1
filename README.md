# 🛰️ Sistema de Control de Satélite - RISC-V Assembly

Sistema de control de temperatura para satélite implementado en **RISC-V Assembly (RV32IMAC_Zicsr)** con multitarea preemptiva mediante interrupciones de timer.

---

## 📋 Tabla de Contenidos

- [Descripción](#-descripción)
- [Problemas Resueltos](#-problemas-resueltos)
- [Arquitectura](#️-arquitectura)
- [Compilación y Ejecución](#-compilación-y-ejecución)
- [Debugging](#-debugging)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Documentación Adicional](#-documentación-adicional)

---

## 📖 Descripción

Este proyecto implementa un **sistema bare-metal** en RISC-V para controlar la temperatura de un satélite. El sistema gestiona tres procesos concurrentes que interactúan a través de variables compartidas en memoria:

1. **Process1_temp** (`Process1_temp.s`): Lee temperaturas del array y actualiza `temp_actual`
2. **Process2_cooler** (`Process2_cooler.s`): Monitorea la temperatura y controla el sistema de enfriamiento
3. **Process3_uart** (`Process3_uart.s`): Transmite datos de temperatura a través de un buffer UART simulado

### Características Clave

- ✅ **Multitarea preemptiva**: Timer interrupts cada 10,000 ciclos
- ✅ **Context switching completo**: 32 registros + PC + SP guardados en PCB
- ✅ **Sin syscalls**: Interrupciones puras de hardware (MTIMECMP/MTIME)
- ✅ **Terminación WFI**: Los procesos entran en `wfi` cuando terminan su trabajo
- ✅ **3 escenarios**: Diferentes órdenes de ejecución de procesos
- ✅ **Emulación en C**: `wrapper_interactive.c` para comparación y testing

---

## 🎯 Problemas Resueltos

| # | Problema | Estado | Descripción |
|---|----------|--------|-------------|
| 1 | Interrupciones de Timer | ✅ Completado | Multitarea preemptiva con quantum de 10,000 ciclos |
| 2 | Debugging con GDB | ✅ Completado | GDB automation + backtrace con execinfo.h |
| 3 | Extracción de Ciclos | ✅ Completado | rdcycle + 13 métricas (PC, SP, interrupciones) |
| 4 | Métricas Avanzadas | ✅ Completado | Tiempo, memoria, CPU, page faults, I/O |
| 5 | Memory Profiling | ✅ Completado | Snapshots, leak detection, trend analysis |
| 6 | Performance Profiling | ✅ Completado | gprof, perf, hotspots, optimizaciones |

**Total de líneas agregadas**: ~515 líneas en `wrapper_interactive.c` (de 624 a 1139 líneas)

---

### ✅ Problema 1: Interrupciones de Timer

**Objetivo**: Implementar multitarea preemptiva con quantum fijo de 10,000 ciclos.

**Solución**:
- **Archivo**: `trap_handler.s` (307 líneas)
- **CSRs configurados**: `mtvec`, `mie`, `mstatus`, `mepc`, `mcause`, `mscratch`
- **Direcciones MMIO**:
  - MTIME: `0x0200BFF8` (contador de ciclos)
  - MTIMECMP: `0x02004000` (comparador para interrupciones)
- **Context switch**: Guarda/restaura 32 registros + PC + SP en PCB de cada proceso
- **Scheduler**: Round-robin entre procesos activos

**Archivos relacionados**:
```
trap_handler.s       → Handler completo de interrupciones
start.s              → Configuración inicial de CSRs
scheduler.s          → Selección de primer proceso
Processes/*.s        → Procesos con lógica WFI
```

**Documentación**: Ver `trap_handler.s` para detalles técnicos.

---

### ✅ Problema 2: Debugging con GDB

**Objetivo**: Implementar herramientas de debugging para análisis de ejecución.

**Solución**:
- **GDB Script**: `debug_gdb.sh` (script bash ejecutable)
  - Lanza QEMU con `-s -S` (puerto 1234, pausa inicial)
  - Conecta GDB automáticamente
  - Establece breakpoints en puntos clave
  - Muestra CSRs (mtvec, mstatus, mepc, mcause)
  
- **Backtrace en C**: `wrapper_interactive.c`
  - Usa `<execinfo.h>` para capturar stack traces
  - Signal handlers para SIGINT (Ctrl+C), SIGSEGV, SIGTERM
  - Función `print_backtrace()` con contexto del sistema
  - Compilado con `-rdynamic` para símbolos completos

**Archivos relacionados**:
```
debug_gdb.sh         → Script automatizado de debugging
GDB_GUIDE.md         → Guía completa de uso de GDB (15+ secciones)
BACKTRACE_DEMO.md    → Demostración de backtrace en C
wrapper_interactive.c → Emulación con backtrace integrado
```

**Uso rápido**:
```bash
# Debugging RISC-V con GDB
$ ./debug_gdb.sh

# Emulación C con backtrace
$ make interactive && ./satelite_interactive
# (Presiona Ctrl+C durante la ejecución para ver el stack trace)
```

**Documentación**:
- `GDB_GUIDE.md`: Guía exhaustiva de debugging
- `BACKTRACE_DEMO.md`: Ejemplos prácticos de backtrace

---

### ✅ Problema 3: Extracción de Ciclos (rdcycle)

**Objetivo**: Extraer métricas de ciclos, PC, SP e interrupciones de cada proceso.

**Solución**:
- **Variables globales** (13 nuevas en `memory_map.h/c`):
  - `cycle_count_p1/p2/p3` (unsigned long long): Contador de ciclos
  - `last_pc_p1/p2/p3` (unsigned int): Último Program Counter
  - `last_sp_p1/p2/p3` (unsigned int): Último Stack Pointer
  - `interrupt_count_p1/p2/p3` (unsigned int): Total de interrupciones
  - `last_mcause` (unsigned int): Última causa de interrupción

- **Instrumentación RISC-V**:
  - `rdcycle/rdcycleh` al inicio de cada proceso (Process1/2/3.s)
  - `trap_handler.s` captura PC, SP y mcause automáticamente
  - Incremento de `interrupt_count_pX` en cada interrupción

- **Extracción de métricas**:
  - **Con GDB**: `./debug_gdb.sh` → comando `show_metrics`
  - **Sin GDB**: `./inspect_metrics.sh` (muestra direcciones)
  - **En C**: `print_metrics()` con estimación de ciclos

**Archivos modificados**:
```
memory_map.h              → +13 variables
memory_map.c              → +13 inicializaciones
trap_handler.s            → +95 líneas (captura de métricas)
Processes/Process1.s      → +5 líneas (rdcycle)
Processes/Process2.s      → +5 líneas (rdcycle)
Processes/Process3.s      → +5 líneas (rdcycle)
wrapper_interactive.c     → print_metrics()
debug_gdb.sh              → comando show_metrics
inspect_metrics.sh        → script nuevo
```

**Uso**:

1. **Debugging con GDB** (RISC-V):
```bash
$ ./debug_gdb.sh
(gdb) show_metrics
# Muestra todas las métricas en tiempo real
```

2. **Inspección rápida**:
```bash
$ ./inspect_metrics.sh
# Muestra direcciones de memoria de todas las métricas
```

3. **Emulación C**:
```bash
$ make run
# Al finalizar:

╔═══════════════════════════════════════════════════════════╗
║   MÉTRICAS DE DEBUGGING (Problema 3)                      ║
╚═══════════════════════════════════════════════════════════╝

⏱️  TIMING:
  Process1: 0.123456 segundos
  Process2: 0.088432 segundos
  Process3: 0.060823 segundos

🔄 ESTIMACIÓN DE CICLOS (basado en tiempo real):
  Process1: ~1234560 ciclos
  Process2: ~884320 ciclos
  Process3: ~608230 ciclos
  (Asumiendo 10 MHz de clock)
```

---

### ✅ Problema 4: Métricas de Tiempo, Memoria y CPU

**Objetivo**: Recopilar métricas avanzadas de rendimiento del sistema.

**Solución**:
- **Tiempo**: 
  - `clock_gettime(CLOCK_MONOTONIC)` para tiempo wall-clock
  - `getrusage()` para tiempo de usuario y sistema
  - Cálculo de eficiencia de CPU
  
- **Memoria**: 
  - `getrusage()` → `ru_maxrss` (RSS máximo)
  - `/proc/self/status` → VmPeak, VmSize, VmRSS, VmData, VmStk, VmExe
  - `mallinfo2()` para estadísticas del heap (glibc >= 2.33)
  
- **CPU**: 
  - `ru_utime` (tiempo de usuario)
  - `ru_stime` (tiempo de sistema)
  - Porcentaje de uso de CPU
  
- **Adicional**:
  - Page faults (minor y major)
  - Context switches (voluntarios e involuntarios)
  - Operaciones de I/O (block input/output)

**Archivos modificados**:
```
wrapper_interactive.c  → +300 líneas de métricas
  - print_advanced_metrics()
  - read_proc_status()
  - format_bytes()
  - struct system_metrics
```

**Uso**:
```bash
$ make run
# Al finalizar la simulación, verás:
╔═══════════════════════════════════════════════════════════╗
║   MÉTRICAS AVANZADAS (Problema 4)                         ║
╚═══════════════════════════════════════════════════════════╝

⏰ TIEMPO DE EJECUCIÓN:
  Tiempo total (wall-clock): 1.234567 segundos
  Tiempo total (milisegundos): 1234.57 ms

🖥️  TIEMPO DE CPU:
  Tiempo de usuario: 1.200000 segundos (97.20%)
  Tiempo de sistema: 0.034567 segundos (2.80%)
  Tiempo total CPU: 1.234567 segundos (100.00%)

💾 MEMORIA:
  RSS máximo: 4.56 MB
  VmPeak: 12.34 MB
  VmSize: 11.89 MB
  VmRSS: 4.56 MB
  VmData: 2.10 MB
  VmStk: 136.00 KB
  VmExe: 36.00 KB

📄 PAGE FAULTS:
  Minor page faults: 523
  Major page faults: 0
  Total page faults: 523

🔄 CONTEXT SWITCHES:
  Voluntarios: 45
  Involuntarios: 12
  Total: 57

💿 OPERACIONES DE I/O:
  Block input operations: 0
  Block output operations: 8
```

**Documentación**: Ver `wrapper_interactive.c` líneas 80-300 para detalles de implementación.

---

### ✅ Problema 5: Memory Profiling

**Objetivo**: Análisis continuo y detallado del uso de memoria durante la ejecución.

**Solución**:
- **Memory Snapshots**: Captura periódica (cada 10 iteraciones)
  - VmSize, VmRSS, VmData, VmStk
  - Heap allocated/free (mallinfo2)
  - Timestamp y contexto (temps_index)
  
- **Análisis de Tendencias**:
  - Detección de memory leaks (crecimiento constante)
  - Detección de picos de memoria (>50% sobre promedio)
  - Estadísticas: min, max, avg, rango
  
- **Visualización**:
  - Tabla de evolución temporal
  - Gráfico ASCII de tendencias
  - Patrones de uso identificados
  
- **Recomendaciones automáticas**:
  - Posibles memory leaks
  - Optimizaciones sugeridas
  - Mejoras en gestión de memoria

**Implementación**:
```c
// Estructura de snapshot
typedef struct {
    struct timespec timestamp;
    long vm_size, vm_rss, vm_data, vm_stk;
    size_t heap_allocated, heap_free;
    int temps_processed;  // Contexto
} MemorySnapshot;

// Hasta 100 snapshots durante ejecución
MemorySnapshot memory_snapshots[100];

// Captura automática cada 10 iteraciones
capture_memory_snapshot();
```

**Archivos modificados**:
```
wrapper_interactive.c  → +318 líneas
  - capture_memory_snapshot()
  - analyze_memory_trend()
  - print_memory_profiling()
  - estimate_stack_usage()
```

**Uso**:
```bash
$ make run
# Selecciona escenario y archivo
# Durante la ejecución se capturan snapshots automáticamente
# Al finalizar:

╔═══════════════════════════════════════════════════════════╗
║   MEMORY PROFILING (Problema 5)                           ║
╚═══════════════════════════════════════════════════════════╝

📸 SNAPSHOTS CAPTURADOS: 12

📊 EVOLUCIÓN DE MEMORIA:
Snap   Tiempo(s)    VmRSS      VmSize     VmData     VmStk      Heap      
───────────────────────────────────────────────────────────────────────────
0      0.000        4560 KB    11890 KB   2100 KB    136 KB     128 KB    
1      0.100        4572 KB    11890 KB   2100 KB    136 KB     132 KB    
2      0.200        4580 KB    11890 KB   2100 KB    136 KB     136 KB    
...

📈 ESTADÍSTICAS DE RSS:
  Mínimo: 4560 KB
  Máximo: 4620 KB
  Promedio: 4585 KB
  Rango: 60 KB

📈 ANÁLISIS DE TENDENCIA:
  RSS inicial: 4560 KB → final: 4600 KB (Δ +40 KB)
  Heap inicial: 131072 B → final: 139264 B (Δ +8192 B)
  ✓ Uso de memoria estable

🔍 DETECCIÓN DE PATRONES:
  ✓ Uso de memoria estable (crecimiento: 15.0%)
  ✓ Sin picos anormales de memoria

💡 RECOMENDACIONES:
  ✓ Gestión de memoria correcta
  ✓ Sin memory leaks detectados
```

---

### ✅ Problema 6: Profiling de Rendimiento

**Objetivo**: Análisis de performance con herramientas de profiling (gprof, perf).

**Solución**:
- **Makefile targets**:
  - `make profile`: Compila con flag `-pg` para gprof
  - `make run-profile`: Ejecuta y genera `gprof_report.txt`
  - `make profile-top`: Muestra top 10 funciones rápidamente
  - `make clean-profile`: Limpia archivos de profiling

- **Script de análisis**: `performance_analysis.sh`
  - Detección automática de herramientas (gprof, perf, time)
  - Análisis con `/usr/bin/time -v` (métricas detalladas)
  - Profiling con gprof (flat profile + call graph)
  - Profiling con perf (eventos hardware, si disponible)
  - Comparación RISC-V vs C (tamaño binario, LOC)

- **Métricas integradas** en `wrapper_interactive.c`:
  - **Hotspots**: Identificación de funciones críticas por tiempo
  - **CPU vs I/O**: Análisis de utilización (CPU-bound vs I/O-bound)
  - **Context switches**: Voluntarios vs involuntarios
  - **Comparación arquitecturas**: RISC-V vs x86_64
  - **Recomendaciones**: Sugerencias de optimización automáticas

**Archivos modificados**:
```
Makefile                      → +30 líneas (targets de profiling)
wrapper_interactive.c         → +225 líneas (print_performance_profiling)
performance_analysis.sh       → script nuevo (análisis multi-herramienta)
```

**Uso**:

1. **Profiling básico con gprof**:
```bash
$ make run-profile
# Genera automáticamente gprof_report.txt
$ cat gprof_report.txt  # Ver reporte completo
```

2. **Análisis completo**:
```bash
$ ./performance_analysis.sh
# Ejecuta análisis con todas las herramientas disponibles
# Genera: time_report.txt, gprof_report.txt, perf.data
```

3. **Ver profiling en ejecución normal**:
```bash
$ make run
# Al finalizar, se muestra automáticamente:

╔═══════════════════════════════════════════════════════════╗
║   PERFORMANCE PROFILING (Problema 6)                      ║
╚═══════════════════════════════════════════════════════════╝

🔥 HOTSPOTS DETECTADOS:
────────────────────────────────────────────────────────────
  Process1 (Temperatura):  45.23% (0.123456 s)
  Process2 (Cooler):       32.45% (0.088432 s)
  Process3 (UART):         22.32% (0.060823 s)

  ⚠️  HOTSPOT CRÍTICO: Process1 (45.23% del tiempo total)

⚙️  ANÁLISIS CPU vs I/O:
────────────────────────────────────────────────────────────
  User time:      0.250000 s
  System time:    0.022000 s
  CPU time:       0.272000 s
  Wall time:      0.272711 s
  CPU utilization: 99.74%

  ℹ️  Alto uso de CPU: Programa CPU-bound

🔄 CONTEXT SWITCHES:
────────────────────────────────────────────────────────────
  Voluntarios:     234
  Involuntarios:   12
  Total:           246
  Rate:            902.15 switches/seg

🔬 COMPARACIÓN RISC-V vs C:
────────────────────────────────────────────────────────────
  Arquitectura C:      x86_64 (nativo)
  Arquitectura RISC-V: rv32imac_zicsr (emulado)

  Ventajas de C:
    ✓ Ejecución nativa (sin overhead de emulación)
    ✓ Compilador optimizado para x86_64
    ✓ Mejor integración con profiling tools

  Ventajas de RISC-V:
    ✓ Código más compacto (~13KB)
    ✓ ISA simplificada y predecible
    ✓ Menor consumo de memoria
    ✓ Ideal para sistemas embebidos

🛠️  PROFILING AVANZADO:
────────────────────────────────────────────────────────────
  Para análisis con gprof:
    make profile             # Compilar con -pg
    make run-profile         # Ejecutar y generar reporte
    make profile-top         # Ver top 10 funciones

  Para análisis completo:
    ./performance_analysis.sh  # Multi-herramienta

  Para profiling de RISC-V:
    qemu-system-riscv32 -icount shift=0 ...  # Contar inst.
    qemu-system-riscv32 -d in_asm ...        # Ver inst.

💡 RECOMENDACIONES:
────────────────────────────────────────────────────────────
  • Process1 consume 45% del tiempo
    → Optimizar lectura de temperaturas
    → Considerar buffering de datos
```

**Comparación de herramientas**:

| Herramienta | Propósito | Ventajas | Limitaciones |
|-------------|-----------|----------|--------------|
| **gprof** | Profiling de funciones | Portable, fácil uso | Solo tiempo CPU, no I/O |
| **perf** | Eventos hardware | Muy preciso, bajo overhead | Requiere permisos |
| **time** | Métricas globales | Siempre disponible | No detalla funciones |
| **QEMU -icount** | Conteo instrucciones | Determinista para RISC-V | Solo emulación |

---

## 🏗️ Arquitectura

### Esquema de Interrupciones

```
┌─────────────┐
│ Process 1/2/3│ ← Ejecutando código de proceso
└──────┬──────┘
       │
       ▼ Timer interrupt cada 10,000 ciclos
┌──────────────────┐
│  trap_handler    │ ← Entry point (mtvec apunta aquí)
│  - Valida mcause │
│  - Guarda ctx    │
│  - Setup timer   │
│  - Scheduler     │
│  - Restaura ctx  │
└──────┬───────────┘
       │
       ▼ mret (vuelve a proceso)
┌─────────────┐
│ Process 1/2/3│ ← Continúa ejecución (posiblemente otro proceso)
└─────────────┘
```

### Memory Map

| Dirección | Descripción |
|-----------|-------------|
| `0x80000000` | Código (`.text`) |
| `0x80001000` | Datos (`.data`) |
| `0x80002000` | BSS (`.bss`) - Variables globales |
| `0x80010000` | Stack del kernel |
| `0x80020000` | Stack Process 1 |
| `0x80030000` | Stack Process 2 |
| `0x80040000` | Stack Process 3 |
| `0x0200BFF8` | MTIME (MMIO - timer counter) |
| `0x02004000` | MTIMECMP (MMIO - timer compare) |

---

## 🔧 Compilación y Ejecución

### Prerrequisitos

```bash
# Toolchain RISC-V
$ sudo apt-get install gcc-riscv64-unknown-elf gdb-multiarch qemu-system-misc

# O usar el toolchain de 32 bits:
$ sudo apt-get install gcc-riscv32-linux-gnu
```

### Compilar RISC-V Binary

```bash
# Compilar satelite.elf
$ make

# Ver desensamblado
$ make dump

# Ejecutar en QEMU
$ make sim
```

### Compilar Emulación en C

```bash
# Compilar wrapper interactivo
$ make interactive

# Ejecutar
$ ./satelite_interactive
# Selecciona escenario (1-4)
# Selecciona archivo de temperaturas (1-4)
```

---

## 🐛 Debugging

### Método 1: Script Automatizado (Recomendado)

```bash
$ ./debug_gdb.sh
```

Esto hace:
1. Inicia QEMU con `-s -S` (puerto 1234, pausa)
2. Conecta GDB automáticamente
3. Establece breakpoints en:
   - `trap_handler` (interrupciones)
   - `process1_start`, `process2_start`, `process3_start`
   - `P1_idle`, `P2_done`, `P3_done` (terminación)
4. Muestra CSRs: mtvec, mstatus, mepc, mcause
5. Proporciona comandos útiles en pantalla

### Método 2: Manual

```bash
# Terminal 1: Iniciar QEMU
$ qemu-system-riscv32 -machine virt -nographic -bios none \
  -kernel satelite.elf -s -S

# Terminal 2: Conectar GDB
$ riscv32-linux-gnu-gdb satelite.elf
(gdb) target remote :1234
(gdb) break trap_handler
(gdb) continue
```

### Comandos Útiles de GDB

```gdb
# Ver registros
(gdb) info registers

# Ver CSRs
(gdb) print/x $mstatus
(gdb) print/x $mepc
(gdb) print/x $mcause

# Ver memoria
(gdb) x/32xw 0x0200BFF8    # MTIME
(gdb) x/2xw 0x02004000     # MTIMECMP

# Ver PCB de procesos
(gdb) x/34xw &pcb_p1       # 32 regs + PC + SP
(gdb) print current_process_id

# Backtrace
(gdb) bt
```

### Backtrace en Emulación C

```bash
$ ./satelite_interactive
# Durante la ejecución, presiona Ctrl+C:
^C

╔═══════════════════════════════════════════════════════════╗
║   SEÑAL RECIBIDA: 2 (INTERRUPT (Ctrl+C))
╚═══════════════════════════════════════════════════════════╝

┌────────────────────────────────────────────────────────┐
│ BACKTRACE: Signal Handler
└────────────────────────────────────────────────────────┘
Obtained 6 stack frames:
  [0] ./satelite_interactive(print_backtrace+0x45) [0x...]
  [1] ./satelite_interactive(signal_handler+0x89) [0x...]
  [2] /lib/x86_64-linux-gnu/libc.so.6(+0x42520) [0x...]
  ...
```

---

## 📁 Estructura del Proyecto

```
SC_Satelite_P1/
├── README.md                    ← Este archivo
├── GDB_GUIDE.md                 ← Guía completa de GDB (Problema 2)
├── BACKTRACE_DEMO.md            ← Demo de backtrace en C (Problema 2)
├── debug_gdb.sh                 ← Script de debugging (Problema 2)
│
├── Makefile                     ← Build system
├── linker.ld                    ← Linker script (memory layout)
│
├── start.s                      ← Entry point + CSR setup
├── scheduler.s                  ← Selección de primer proceso
├── trap_handler.s               ← Interrupt handler + context switch (Problema 1)
│
├── main_riscv.c                 ← Main loop (llama a scheduler)
├── kernel.c / kernel.h          ← Funciones de kernel
├── memory_map.c / memory_map.h  ← Variables globales
├── stacks.c / stacks.h          ← Inicialización de stacks
│
├── Processes/
│   ├── Process1_temp.s          ← Lectura de temperatura
│   ├── Process2_cooler.s        ← Control de enfriamiento
│   └── Process3_uart.s          ← Transmisión UART
│
├── wrapper_interactive.c        ← Emulación en C con backtrace (Problema 2)
│
├── tests/
│   ├── test1.txt                ← Temperaturas de prueba
│   ├── test2.txt
│   ├── test3.txt
│   └── test4.txt
│
└── satelite.elf                 ← Binario RISC-V generado
```

---

## 📚 Documentación Adicional

### Problema 1 (Interrupciones)

- **`trap_handler.s`**: Código fuente con comentarios extensos
  - Sección 1: Entry point y validación de mcause
  - Sección 2: Context save (32 regs + PC + SP)
  - Sección 3: Timer setup (MTIMECMP + quantum)
  - Sección 4: Scheduler (round-robin)
  - Sección 5: Context restore
  - Sección 6: mret

### Problema 2 (Debugging)

- **`GDB_GUIDE.md`**: Guía completa (70+ secciones)
  - Quick start (script vs manual)
  - Breakpoints (15+ ubicaciones sugeridas)
  - Inspección (registros, CSRs, memoria, variables)
  - Debugging de interrupciones (MTIME/MTIMECMP)
  - Análisis de context switch (PCB inspection)
  - 5 ejemplos prácticos
  - Scripting avanzado
  - Troubleshooting

- **`BACKTRACE_DEMO.md`**: Demostración práctica
  - ¿Qué es el backtrace?
  - 3 escenarios (normal, Ctrl+C, SIGSEGV)
  - Comparación C vs RISC-V
  - 4 ejercicios prácticos
  - Limitaciones y alternativas

### Archivos de Código

Cada archivo `.s` y `.c` tiene comentarios detallados explicando:
- Propósito del archivo
- Registros utilizados
- Variables accedidas
- Algoritmo implementado
- Notas de sincronización

---

## 🚀 Quick Start

### 1. Compilar todo

```bash
$ make clean && make all
```

### 2. Ejecutar en QEMU (RISC-V)

```bash
$ make sim
```

### 3. Ejecutar emulación (C)

```bash
$ make run
# Selecciona escenario 1, archivo 1
```

### 4. Debugging con GDB

```bash
$ ./debug_gdb.sh
# GDB se conecta automáticamente
# Breakpoints ya establecidos
# Usa 'continue' para ejecutar
```

### 5. Probar backtrace en C

```bash
$ ./satelite_interactive
# Durante la ejecución, presiona Ctrl+C
# Verás el stack trace completo
```

---

## 🧪 Testing

### Tests Incluidos

- **test1.txt**: Órbita LEO completa (100 muestras)
- **test2.txt**: Ciclo día/noche extremo (80 muestras)
- **test3.txt**: Anomalía térmica (50 muestras)
- **test4.txt**: Condiciones normales (60 muestras)

### Escenarios de Scheduler

- **Escenario 1**: P1 → P2 → P3 (baseline)
- **Escenario 2**: P1 → P3 → P2
- **Escenario 3**: P2 → P1 → P3
- **Escenario 4**: Syscalls (placeholder)

---

## 📊 Progreso

| Problema | Estado | Archivos |
|----------|--------|----------|
| **1. Interrupciones** | ✅ Completo | `trap_handler.s`, `start.s`, `Processes/*.s` |
| **2. Debugging GDB** | ✅ Completo | `debug_gdb.sh`, `GDB_GUIDE.md`, `BACKTRACE_DEMO.md` |
| **3. rdcycle + Métricas PC/SP** | ✅ Completo | `Processes/*.s`, `trap_handler.s`, `memory_map.c`, `inspect_metrics.sh` |
| **4. Métricas Tiempo/Memoria/CPU** | ✅ Completo | `wrapper_interactive.c` (+300 líneas) |
| **5. Memory Profiling** | ✅ Completo | `wrapper_interactive.c` (+318 líneas, snapshots automáticos) |
| **6. Performance Profiling** | ⏳ Pendiente | - |

---

## 🔗 Referencias

- [RISC-V ISA Spec](https://riscv.org/technical/specifications/)
- [RISC-V Privileged Spec](https://github.com/riscv/riscv-isa-manual/releases/tag/Priv-v1.12)
- [QEMU RISC-V Docs](https://www.qemu.org/docs/master/system/target-riscv.html)
- [GDB Manual](https://sourceware.org/gdb/documentation/)

---

## 📝 Licencia

Este proyecto es para fines educativos (Sistemas de Computadores).

---

## 👤 Autor

**cerealkiller** - Universidad [Tu Universidad]

---

**¡Sistema funcionando con interrupciones de timer y debugging completo!** 🎉
