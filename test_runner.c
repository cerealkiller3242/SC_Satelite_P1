#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "memory_map.h"

// Prototipos para kernel_start
extern void kernel_start(int *temps, int len);

// Implementaciones en C que simulan los procesos (usando las variables globales)

void process1_c() {
    // lee temps_ptr y temps_index, actualiza temp_actual, cooling_flag y uart_buffer
    while (temps_index < temps_len) {
        int idx = temps_index;
        int val = temps_ptr[idx];
        temp_actual = val;
        if (val > 90) cooling_flag = 1;
        else if (val < 55) cooling_flag = 0;
        uart_buffer = val;
        temps_index++;
        // Simular trabajo
        usleep(10000);
    }
}

void process2_c() {
    while (1) {
        if (cooling_flag) {
            cooling_state = 1;
            // esperar hasta que temp < 55
            while (temp_actual > 55) {
                usleep(5000);
            }
            cooling_state = 0;
        } else {
            cooling_state = 0;
        }
        usleep(5000);
    }
}

void process3_c() {
    while (1) {
        if (uart_buffer != 0) {
            uart_last = uart_buffer;
            uart_buffer = 0;
        }
        usleep(5000);
    }
}

// Scheduler en C simple: lanzar los procesos en hilos para simular concurrencia cooperativa
#include <pthread.h>

int main_sim() {
    // Llamar a kernel_start (que inicializa temps_ptr y temps_len)
    kernel_start(temps, temps_len);

    pthread_t t1, t2, t3;
    pthread_create(&t1, NULL, (void*(*)(void*))process1_c, NULL);
    pthread_create(&t2, NULL, (void*(*)(void*))process2_c, NULL);
    pthread_create(&t3, NULL, (void*(*)(void*))process3_c, NULL);

    // Monitorizar el progreso y terminar cuando temps_index alcance temps_len
    while (temps_index < temps_len) {
        printf("idx=%d temp=%d cooling_flag=%d cooling_state=%d uart_last=%d\n",
               temps_index, temp_actual, cooling_flag, cooling_state, uart_last);
        usleep(50000);
    }

    // Esperar un poco y salir
    sleep(1);
    return 0;
}

int main() {
    // Leer temperaturas1.txt y llamar a kernel_start
    FILE *f = fopen("temperaturas1.txt", "r");
    if (!f) {
        printf("No se pudo abrir temperaturas1.txt\n");
        return 1;
    }
    int arr[500];
    int n = 0;
    while (fscanf(f, "%d", &arr[n]) != EOF) n++;
    fclose(f);

    // inicializar globals como lo hace kernel_start
    kernel_start(arr, n);

    // arrancar la simulación en hilos
    pthread_t t1, t2, t3;
    pthread_create(&t1, NULL, (void*(*)(void*))process1_c, NULL);
    pthread_create(&t2, NULL, (void*(*)(void*))process2_c, NULL);
    pthread_create(&t3, NULL, (void*(*)(void*))process3_c, NULL);

    while (temps_index < temps_len) {
        printf("idx=%d temp=%d cooling_flag=%d cooling_state=%d uart_last=%d\n",
               temps_index, temp_actual, cooling_flag, cooling_state, uart_last);
        usleep(50000);
    }

    sleep(1);
    return 0;
}

