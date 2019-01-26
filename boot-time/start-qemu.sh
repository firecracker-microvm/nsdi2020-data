#! /bin/bash

rand=$RANDOM
QEMU=../bin/qemu-system-x86_64
LOGFILE=./qemu-$rand.log
MACHINE=pc

while [ $# -gt 0 ]; do
    case $1 in
        -b) shift; QEMU=$1
            ;;
        -k) shift; KERNEL=$1
            ;;
        -r) shift; ROOTFS=$1
            ;;
        -t) shift; TIMEFILE=$1
            ;;
        -l) shift; LOGFILE=$1
            ;;
        -m) shift; MACHINE=$1
            ;;
        -d) DEBUG=yes
            ;;
    esac
    shift
done

# TODO: Enable serial console output on debug

# Common QEMU command line options
QEMU="$QEMU 
        -L ../bin/bios \
        -smp 1 \
        -m 512 \
        -accel kvm \
        -cpu host \
        -machine $MACHINE \
        -display none \
        -nographic \
        -vga none \
        -nic none \
        -no-acpi \
        -device isa-debug-exit,iobase=0xf4,iosize=0x4 \
"

CMDLINE="reboot=k tsc=reliable ipv6.disable=1 8250.nr_uarts=0 quiet panic=-1 ro"


us_start=$(($(date +%s%N)/1000))

${QEMU} \
    -device virtio-blk-pci,drive=d0 \
        -drive if=none,id=d0,format=raw,file=../img/boot-time-disk.img \
    -kernel ../img/boot-time-pci-vmlinuz \
    -append "root=/dev/vda init=/init ${CMDLINE}"


us_end=$(($(date +%s%N)/1000))

us_time=$(expr $us_end - $us_start)

if [ "x$TIMEFILE" = "x" ]; then
    echo $us_time
else
    echo $us_time >> $TIMEFILE
fi
