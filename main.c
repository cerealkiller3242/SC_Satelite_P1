#include <stdio.h>
#include "memory_map.h"

extern void kernel_start(int *temps, int len);

int temps[500];

int main() {
    FILE *f = fopen("temperaturas1.txt", "r");
    if (!f) {
        printf("No se pudo abrir temperaturas.txt\n");
        return 1;
    }

    int n = 0;
    while (fscanf(f, "%d", &temps[n]) != EOF) n++;
    fclose(f);

    kernel_start(temps, n);
    return 0;
}
