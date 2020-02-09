#! /bin/bash

ID=$RANDOM
QEMU=../bin/qemu-system-x86_64
CORES=1
MEM=256
NET=

while [ $# -gt 0 ]; do
    case $1 in
        -i) shift; ID=$1
            ;;
        -b) shift; QEMU=$1
            ;;
        -k) shift; KERNEL=$1
            ;;
        -r) shift; ROOTFS=$1
            ;;
        -k) shift; RAMDISK=$1
            ;;
        -c) shift; CORES=$1
            ;;
        -m) shift; MEM=$1
            ;;
        -n) NET=on
            ;;
        -f) shift; DISK=$1
            ;;
        -t) shift; TIMEFILE=$1
            ;;
        -d) DEBUG=yes
            ;;
    esac
    shift
done

# Common QEMU command line options
QEMU="$QEMU \
        -L ../bin/bios -bios qboot.bin \
        -M microvm,x-option-roms=off,pit=off,pic=off,isa-serial=off,rtc=off \
        -smp $CORES -m $MEM \
        -accel kvm -cpu host \
        -nodefaults -no-user-config -nographic -display none \
        -device isa-debug-exit,iobase=0xf4,iosize=0x4 \
"

KERNEL_ARGS="reboot=k tsc=reliable ipv6.disable=1 panic=-1 ro"
if [ "x$DEBUG" = "x" ]; then
    KERNEL_ARGS="$KERNEL_ARGS 8250.nr_uarts=0 quiet"
else
    KERNEL_ARGS="$KERNEL_ARGS console=hvc0"
    QEMU="$QEMU \
         -chardev stdio,id=virtiocon0 \
         -device virtio-serial-device \
         -device virtconsole,chardev=virtiocon0 \
         "
fi

if [ "x$RAMDISK" != "x" ]; then
    QEMU="$QEMU \
        -initrd $RAMDISK \
        "
fi

if [ "x$ROOTFS" != "x" ]; then
    QEMU="$QEMU \
        -device virtio-blk-device,drive=d0 \
        -drive if=none,id=d0,format=raw,readonly=on,file=$ROOTFS \
        "
    ROOT="root=/dev/vda"
fi

if [ "x$NET" != "x" ]; then
    TAP_DEV=$(./util_ipam.sh -t $ID)
    TAP_IP=$(./util_ipam.sh -h $ID)
    VM_MAC=$(./util_ipam.sh -a $ID)
    VM_IP=$(./util_ipam.sh -v $ID)
    VM_MASK=$(./util_ipam.sh -m $ID)

    KERNEL_ARGS="$KERNEL_ARGS ip=$VM_IP::$TAP_IP:$VM_MASK::eth0:off"

    QEMU="$QEMU \
        -device virtio-net-device,mac=$VM_MAC,netdev=n0 \
        -netdev tap,id=n0,script=no,ifname=$TAP_DEV"
else
    QEMU="$QEMU \
         -nic none \
         "
fi

if [ "x$DISK" != "x" ]; then
    QEMU="$QEMU \
        -device virtio-blk,drive=d1 \
        -drive if=none,id=d1,format=raw,file=$DISK \
        "
fi

us_start=$(($(date +%s%N)/1000))

${QEMU} \
    -kernel "$KERNEL" \
    -append "$ROOT init=/init $KERNEL_ARGS"

us_end=$(($(date +%s%N)/1000))
us_time=$(expr $us_end - $us_start)

if [ "x$TIMEFILE" = "x" ]; then
    echo "$us_time"
else
    echo "$us_time" >> "$TIMEFILE"
fi
