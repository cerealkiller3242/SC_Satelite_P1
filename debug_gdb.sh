#!/bin/bash
# Script para debuggear satelite.elf con GDB y QEMU
# Uso: ./debug_gdb.sh

echo "==================================================================="
echo "  Debugger RISC-V - Sistema de Control de Satélite"
echo "==================================================================="
echo ""

# Verificar que satelite.elf existe
if [ ! -f satelite.elf ]; then
    echo "❌ Error: satelite.elf no encontrado"
    echo "   Ejecuta: make baremetal"
    exit 1
fi

echo "✓ Ejecutable encontrado: satelite.elf"
echo ""
echo "Iniciando QEMU con GDB server en puerto 1234..."
echo ""

# Ejecutar QEMU en background con GDB server
qemu-system-riscv32 \
    -machine virt \
    -nographic \
    -bios none \
    -kernel satelite.elf \
    -s \
    -S &

QEMU_PID=$!

# Esperar que QEMU inicie
sleep 1

echo ""
echo "==================================================================="
echo "  QEMU iniciado (PID: $QEMU_PID)"
echo "==================================================================="
echo ""
echo "Conectando GDB..."
echo ""

# Crear script de comandos GDB
cat > /tmp/gdb_commands.txt << 'EOF'
# Conectar a QEMU
target remote :1234

# Saltar al entry point (_start en 0x80000000)
# QEMU arranca en 0x1000 (reset vector), pero nuestro código está en 0x80000000
set $pc = _start

# Configurar breakpoints útiles
break trap_handler
break process1_start
break process2_start
break process3_start
break P1_idle
break P2_done
break P3_done

# Mostrar info inicial
info registers pc sp
info breakpoints

# Comandos disponibles
echo \n=================================================================\n
echo   GDB conectado a QEMU RISC-V\n
echo =================================================================\n
echo \n
echo Breakpoints configurados:\n
echo   - trap_handler    (interrupciones de timer)\n
echo   - process1_start  (inicio de P1)\n
echo   - process2_start  (inicio de P2)\n
echo   - process3_start  (inicio de P3)\n
echo   - P1_idle         (P1 termina)\n
echo   - P2_done         (P2 termina)\n
echo   - P3_done         (P3 termina)\n
echo \n
echo Comandos útiles:\n
echo   continue (c)           - Ejecutar hasta breakpoint\n
echo   step (s)               - Paso a paso (entra en funciones)\n
echo   stepi (si)             - Paso a paso (instrucción)\n
echo   next (n)               - Paso a paso (no entra en funciones)\n
echo   info registers         - Ver todos los registros\n
echo   info registers pc sp   - Ver PC y SP\n
echo   print current_scenario - Ver variable\n
echo   print temps_index      - Ver índice de temperaturas\n
echo   x/10i $pc              - Desarmar 10 instrucciones desde PC\n
echo   backtrace (bt)         - Ver call stack\n
echo   quit                   - Salir (mata QEMU)\n
echo \n
echo =================================================================\n
echo \n

# Info de CSRs importantes
echo CSRs importantes:\n
echo   mtvec   = 
info registers mtvec
echo   mstatus = 
info registers mstatus
echo   mepc    = 
info registers mepc
echo   mcause  = 
info registers mcause
echo \n

# Definir comandos personalizados para ver métricas (Problema 3)
define show_metrics
    echo \n=== MÉTRICAS DE DEBUGGING (Problema 3) ===\n
    echo \nCiclos de CPU (rdcycle):\n
    printf "  P1: %llu (0x%llx)\n", cycle_count_p1, cycle_count_p1
    printf "  P2: %llu (0x%llx)\n", cycle_count_p2, cycle_count_p2
    printf "  P3: %llu (0x%llx)\n", cycle_count_p3, cycle_count_p3
    echo \nÚltimo PC capturado:\n
    printf "  P1: 0x%08x\n", last_pc_p1
    printf "  P2: 0x%08x\n", last_pc_p2
    printf "  P3: 0x%08x\n", last_pc_p3
    echo \nÚltimo SP capturado:\n
    printf "  P1: 0x%08x\n", last_sp_p1
    printf "  P2: 0x%08x\n", last_sp_p2
    printf "  P3: 0x%08x\n", last_sp_p3
    echo \nContador de interrupciones:\n
    printf "  P1: %u\n", interrupt_count_p1
    printf "  P2: %u\n", interrupt_count_p2
    printf "  P3: %u\n", interrupt_count_p3
    echo \nÚltima causa de trap:\n
    printf "  mcause: 0x%08x ", last_mcause
    if last_mcause == 0x80000007
        echo (Timer interrupt)\n
    else
        if last_mcause == 11
            echo (Environment call)\n
        else
            echo (Unknown)\n
        end
    end
    echo \n=========================================\n
end

echo \n=== COMANDO PERSONALIZADO ===\n
echo   show_metrics           - Ver todas las métricas de debugging\n
echo ==============================\n
echo \n

EOF

# Detectar qué GDB usar (riscv32-linux-gnu-gdb, gdb-multiarch o gdb)
if command -v riscv32-linux-gnu-gdb &> /dev/null; then
    GDB_CMD="riscv32-linux-gnu-gdb"
    echo "✓ Usando riscv32-linux-gnu-gdb"
elif command -v gdb-multiarch &> /dev/null; then
    GDB_CMD="gdb-multiarch"
    echo "✓ Usando gdb-multiarch"
elif command -v gdb &> /dev/null; then
    GDB_CMD="gdb"
    echo "⚠ Usando gdb estándar (puede tener limitaciones con RISC-V)"
    echo "  Recomendado instalar: sudo dnf install gdb-gdbserver"
else
    echo "❌ Error: No se encontró GDB"
    echo "   Instala GDB:"
    echo "     - Fedora/RHEL: sudo dnf install gdb"
    echo "     - Ubuntu/Debian: sudo apt install gdb-multiarch"
    echo "     - Arch: sudo pacman -S gdb-multiarch"
    kill $QEMU_PID 2>/dev/null
    rm /tmp/gdb_commands.txt
    exit 1
fi

# Ejecutar GDB con el script
$GDB_CMD satelite.elf -x /tmp/gdb_commands.txt

# Limpiar
echo ""
echo "Cerrando QEMU..."
kill $QEMU_PID 2>/dev/null
rm /tmp/gdb_commands.txt

echo "✓ Sesión de debug finalizada"
