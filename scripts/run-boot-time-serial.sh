#! /bin/sh

#set -x

ITER=1000
DIR=../data/
CORES=1
MEM=256

while [ $# -gt 0 ]; do
    case $1 in
        -i) shift; ITER=$1
            ;;
        -d) shift; DIR=$1
            ;;
    esac
    shift
done

mkdir -p ${DIR}

FC_RES=${DIR}/boot-times-serial-fc.dat
QEMU_RES=${DIR}/boot-times-serial-qemu.dat
QEMU_INITRD_RES=${DIR}/boot-times-serial-qemu-initrd.dat
RES=${DIR}/boot-times-serial.csv

rm -f ${FC_RES} ${QEMU_RES} ${QEMU_INITRD_RES} ${RES}

killall firecracker 2> /dev/null
for i in $(seq ${ITER}); do
    ./start-fc.sh -b ../bin/firecracker \
                  -k ../img/boot-time-pci-vmlinux \
                  -r ../img/boot-time-disk.img \
                  -c $CORES \
                  -m $MEM \
                  -t ${FC_RES}
    sleep 0.4
    killall firecracker 2> /dev/null
done
rm -f *.log
./gen-cdf.py ${FC_RES}

killall qemu-system-x86_64 2> /dev/null
for i in $(seq ${ITER}); do
    ./start-qemu.sh -b ../bin/qemu-system-x86_64 \
                    -k ../img/boot-time-pci-vmlinuz \
                    -r ../img/boot-time-disk.img \
                    -c $CORES \
                    -m $MEM \
                    -t ${QEMU_RES}
    sleep 0.4
    killall qemu-system-x86_64 2> /dev/null
done
rm -f *.log
./gen-cdf.py ${QEMU_RES}

killall qemu-system-x86_64 2> /dev/null
for i in $(seq ${ITER}); do
    ./start-qemu.sh -b ../bin/qemu-system-x86_64 \
                    -k ../img/boot-time-pci-vmlinuz \
                    -a ../img/boot-time-initrd.img \
                    -c $CORES \
                    -m $MEM \
                    -t ${QEMU_INITRD_RES}
    sleep 0.4
    killall qemu-system-x86_64 2> /dev/null
done
rm -f *.log
./gen-cdf.py ${QEMU_INITRD_RES}


# Munch the data
echo "bootsecs,vmm" > ${RES}
while IFS= read -r l; do
    # $l is in microseconds
    s=$(echo "scale=3; $l/1000000" | bc)
    echo "$s,qemu" >> ${RES}
done < ${QEMU_RES}

while IFS= read -r l; do
    # $l is in [microseconds ms]
    us=$(echo $l | cut -d ' ' -f1)
    s=$(echo "scale=3; $us/1000000" | bc)
    echo "$s,firecracker-e2e" >> ${RES}
done < ${FC_RES}

while IFS= read -r l; do
    # $l is in [microseconds ms]
    ms=$(echo $l | cut -d ' ' -f2)
    s=$(echo "scale=3; $ms/1000" | bc)
    echo "$s,firecracker" >> ${RES}
done < ${FC_RES}
