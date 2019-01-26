QEMU_COMMON="-smp 1\
             -m 512 \
             -accel kvm \
             -balloon none \
             -display none \
             -cpu host \
             -device isa-debug-exit,iobase=0xf4,iosize=0x4 \
             "

QMD_CMD_COMMON="reboot=k tsc=reliable ipv6.disable=1 8250.nr_uarts=0 quiet panic=-1 ro"
