#! /bin/sh

. ./qemu-kvm-common.sh

qemu-system-x86_64 \
    ${QEMU_COMMON} \
    -no-acpi \
    -machine q35 \
    -kernel ../img/boot-time-pci-vmlinuz \
    -initrd ../img/boot-time-initrd.img \
    -append "init=/init ${QMD_CMD_COMMON}"

# -append "root=/dev/vda init=/init console=ttyS0"
# -device virtio-net-device,netdev=n0,mac=5a:39:97:06:c0:fd -netdev user,id=n0 \

