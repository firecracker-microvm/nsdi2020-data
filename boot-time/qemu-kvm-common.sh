QEMU_COMMON="-smp 1\
             -m 512 \
             -accel kvm \
             -balloon none \
             -display none \
             -cpu host \
             -device isa-debug-exit,iobase=0xf4,iosize=0x4 \
             "
             
