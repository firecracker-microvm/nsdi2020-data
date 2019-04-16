#! /bin/bash

ID=$RANDOM
QEMU=../bin/qemu-system-x86_64
CORES=1
MEM=256
ARCH=pc


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
        -t) shift; TIMEFILE=$1
            ;;
        -a) shift; ARCH=$1
            ;;
        -f) shift; FW=$1
            ;;
        -d) DEBUG=yes
            ;;
    esac
    shift
done


# Common QEMU command line options
QEMU="$QEMU \
        -L ../bin/bios \
        -smp $CORES \
        -m $MEM \
        -accel kvm \
        -cpu host \
        -machine $ARCH \
        -display none \
        -nographic \
        -vga none \
        -nic none \
        -no-acpi \
        -device isa-debug-exit,iobase=0xf4,iosize=0x4 \
"

KERNEL_ARGS="reboot=k tsc=reliable ipv6.disable=1 panic=-1 ro"
if [ "x$DEBUG" = "x" ]; then
    KERNEL_ARGS="$KERNEL_ARGS 8250.nr_uarts=0 quiet"
else
    KERNEL_ARGS="$KERNEL_ARGS console=ttyS0"
fi

if [ "x$RAMDISK" != "x" ]; then
    QEMU="$QEMU \
        -initrd $RAMDISK \
        "
fi

if [ "x$ROOTFS" != "x" ]; then
    QEMU="$QEMU \
        -device virtio-blk-pci,drive=d0 \
        -drive if=none,id=d0,format=raw,readonly=on,file=$ROOTFS \
        "
    ROOT="root=/dev/vda"
fi

if [ "x$FW" != "x" ]; then
    QEMU="$QEMU \
        -bios $FW \
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
