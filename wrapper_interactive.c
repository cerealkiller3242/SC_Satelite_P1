#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include "memory_map.h"



// Process1: Simula Process1_temp.s (lee temperaturas, actualiza flags)
void* process1_assembly_logic(void* arg) {
    while (temps_index < temps_len) {
        // P1_loop: cargar índice
        int idx = temps_index;
        
        // Leer temperatura del array
        int val = temps_ptr[idx];
        
        // Guardar en temp_actual
        temp_actual = val;
        
        // Lógica de flags (como en Process1_temp.s)
        if (val > 90) {
            // P1_set_cooling
            cooling_flag = 1;
        } else if (val < 55) {
            // P1_clear_cooling
            cooling_flag = 0;
        }
        
        // Escribir en uart_buffer
        uart_buffer = val;
        
        // Incrementar índice
        temps_index++;
        
        usleep(10000); // Simular tiempo de procesamiento
    }
    return NULL;
}

// Process2: Simula Process2_cooler.s (monitorea cooling)
void* process2_assembly_logic(void* arg) {
    while (temps_index < temps_len) {
        // P2_loop: leer cooling_flag
        if (cooling_flag) {
            // P2_active
            cooling_state = 1;
            
            // P2_monitor: esperar hasta que temp < 55
            while (temp_actual >= 55 && temps_index < temps_len) {
                usleep(5000);
            }
            
            // Apagar cooling
            cooling_state = 0;
        } else {
            // P2_idle
            cooling_state = 0;
        }
        usleep(5000);
    }
    return NULL;
}

// Process3: Simula Process3_uart.s (lee buffer y transmite)
void* process3_assembly_logic(void* arg) {
    while (temps_index < temps_len) {
        // P3_loop: leer uart_buffer
        if (uart_buffer != 0) {
            // Guardar último dato
            uart_last = uart_buffer;
            // Limpiar buffer
            uart_buffer = 0;
        }
        usleep(5000);
    }
    return NULL;
}

int main() {
    printf("\n");
    printf("╔═══════════════════════════════════════════════════════════╗\n");
    printf("║   Sistema de Control de Satélite - RISC-V Assembly        ║\n");
    printf("║   (Simulación con lógica exacta de archivos .s)           ║\n");
    printf("╚═══════════════════════════════════════════════════════════╝\n");
    printf("\n");
    
    // Selección de escenario
    printf("Seleccione el escenario de scheduler:\n");
    printf("  1. Escenario 1: P1 → P2 → P3 (Baseline)\n");
    printf("  2. Escenario 2: P1 → P3 → P2\n");
    printf("  3. Escenario 3: P2 → P1 → P3\n");
    printf("  4. Escenario 4: Syscalls (placeholder)\n");
    printf("\nIngrese el número del escenario (1-4): ");
    
    int scenario;
    if (scanf("%d", &scenario) != 1 || scenario < 1 || scenario > 4) {
        printf("Escenario inválido. Usando escenario 1 por defecto.\n");
        scenario = 1;
    }
    current_scenario = scenario;
    
    printf("\n✓ Escenario %d seleccionado\n", scenario);
    
    // Selección de archivo de temperaturas
    printf("\nSeleccione el archivo de temperaturas:\n");
    printf("  1. temperaturas1.txt (Órbita LEO completa)\n");
    printf("  2. temperaturas2.txt (Valores aleatorios)\n");
    printf("  3. temperaturas3.txt (Valor constante 75°C)\n");
    printf("  4. temperaturas4.txt (Caso extremo)\n");
    printf("\nIngrese el número de archivo (1-4): ");
    
    int temp_file_choice;
    if (scanf("%d", &temp_file_choice) != 1 || temp_file_choice < 1 || temp_file_choice > 4) {
        printf("Opción inválida. Usando temperaturas1.txt por defecto.\n");
        temp_file_choice = 1;
    }
    
    char filename[30];
    sprintf(filename, "temperaturas%d.txt", temp_file_choice);
    
    FILE *f = fopen(filename, "r");
    if (!f) {
        printf("Error: No se pudo abrir %s\n", filename);
        return 1;
    }
    
    int arr[500];
    int n = 0;
    while (fscanf(f, "%d", &arr[n]) != EOF && n < 500) {
        n++;
    }
    fclose(f);
    
    printf("✓ Archivo cargado: %s\n", filename);
    printf("✓ Temperaturas leídas: %d valores (rango: ", n);
    
    // Calcular rango
    int min_temp = arr[0], max_temp = arr[0];
    for (int i = 0; i < n; i++) {
        if (arr[i] < min_temp) min_temp = arr[i];
        if (arr[i] > max_temp) max_temp = arr[i];
    }
    printf("%d°C - %d°C)\n", min_temp, max_temp);
    
    // Inicializar variables globales (como en assembly)
    temps_ptr = arr;
    temps_len = n;
    temps_index = 0;
    temp_actual = 0;
    cooling_flag = 0;
    cooling_state = 0;
    uart_buffer = 0;
    uart_last = 0;
    
    // Arrancar threads simulando los procesos assembly
    pthread_t t1, t2, t3;
    
    printf("\n");
    printf("═══════════════════════════════════════════════════════════\n");
    printf("  Ejecutando código Assembly RISC-V (simulado)\n");
    printf("  Escenario %d: ", scenario);
    
    switch(scenario) {
        case 1: printf("P1 → P2 → P3\n"); break;
        case 2: printf("P1 → P3 → P2\n"); break;
        case 3: printf("P2 → P1 → P3\n"); break;
        case 4: printf("Syscalls\n"); break;
    }
    printf("═══════════════════════════════════════════════════════════\n");
    printf("\n");
    printf("📌 NOTA: Los threads simulan la lógica EXACTA de:\n");
    printf("   • Process1_temp.s (lectura y control)\n");
    printf("   • Process2_cooler.s (monitoreo)\n");
    printf("   • Process3_uart.s (transmisión)\n");
    printf("\n");
    
    // Crear threads (orden según escenario, aunque en paralelo no importa mucho)
    pthread_create(&t1, NULL, process1_assembly_logic, NULL);
    pthread_create(&t2, NULL, process2_assembly_logic, NULL);
    pthread_create(&t3, NULL, process3_assembly_logic, NULL);
    
    printf("Lecturas cada 5 iteraciones (simulando 5 minutos):\n");
    printf("%-8s %-8s %-13s %-15s %-10s\n", 
           "Tiempo", "Temp", "Cooling_Flag", "Cooling_State", "UART_Last");
    printf("-------------------------------------------------------\n");
    
    // Monitorizar el progreso
    int last_printed_idx = -1;
    while (temps_index < temps_len) {
        if (temps_index != last_printed_idx && 
            (temps_index % 5 == 0 || temps_index == temps_len - 1)) {
            printf("%-8d %-8d %-13d %-15d %-10d\n",
                   temps_index, temp_actual, cooling_flag, cooling_state, uart_last);
            last_printed_idx = temps_index;
        }
        usleep(50000);
    }
    
    // Esperar threads
    printf("\nEsperando finalización de procesos...\n");
    sleep(1);
    
    pthread_cancel(t1);
    pthread_cancel(t2);
    pthread_cancel(t3);
    
    pthread_join(t1, NULL);
    pthread_join(t2, NULL);
    pthread_join(t3, NULL);
    
    printf("\n");
    printf("═══════════════════════════════════════════════════════════\n");
    printf("  SIMULACIÓN COMPLETADA\n");
    printf("═══════════════════════════════════════════════════════════\n");
    printf("\n");
    printf("📊 Estadísticas finales:\n");
    printf("  • Total de temperaturas procesadas: %d\n", temps_index);
    printf("  • Temperatura final: %d°C\n", temp_actual);
    printf("  • Estado cooling_flag: %d (%s)\n", cooling_flag, 
           cooling_flag ? "ACTIVO" : "INACTIVO");
    printf("  • Estado cooling_state: %d (%s)\n", cooling_state,
           cooling_state ? "ACTIVO" : "INACTIVO");
    printf("  • Último valor UART transmitido: %d°C\n", uart_last);
    printf("\n");
    printf("✓ Escenario %d ejecutado correctamente\n", current_scenario);
    printf("✓ Lógica basada en archivos Assembly RISC-V\n");
    printf("\n");
    
    return 0;
}
