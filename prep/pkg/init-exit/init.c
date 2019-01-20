#include <sys/io.h>
#include <stdio.h>

/*
 * This little program is a mock 'init' process. It writes to
 * two IO ports:
 * - PORT_QEMU is debug port setup in qemu with the 'isa-debug-exit'
 *   device. A write to it causes qemu to call exit(val).
 * - PORT_FC is a debug port in firecracker which cause it to
 *   write a timestamp to the log.
 *
 * Both can be used to measure kernel boot times.
 */

#define PORT_QEMU   0x00f4
#define PORT_FC     0x03f0
#define PORT_FC_VAL 123

int main(void)
{
    int r;

    /* Enable writing to the port */
    r = ioperm(PORT_QEMU, 1, 1);
    if (r) {
        fprintf(stderr, "Error setting up port access to 0x%x, quitting\n", PORT_QEMU);
        return -1;
    }

    r = ioperm(PORT_FC, 1, 1);
    if (r) {
        fprintf(stderr, "Error setting up port access to 0x%x, quitting\n", PORT_FC);
        return -1;
    }

    outb(PORT_FC_VAL, PORT_FC);
    outb(0, PORT_QEMU);
    return 0;
}
