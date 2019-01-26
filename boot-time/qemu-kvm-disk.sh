#! /bin/sh

. ./qemu-kvm-common.sh

${QEMU} \
    -no-acpi \
    -device virtio-blk-pci,drive=d0 \
        -drive if=none,id=d0,format=raw,file=../img/boot-time-disk.img \
    -kernel ../img/boot-time-pci-vmlinuz \
    -append "root=/dev/vda init=/init ${QMD_CMD_COMMON}"

# -append "root=/dev/vda init=/init console=ttyS0"
# -device virtio-net-device,netdev=n0,mac=5a:39:97:06:c0:fd -netdev user,id=n0 \

