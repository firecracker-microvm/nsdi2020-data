#! /bin/sh

#set -x

# Run a large number of Firecracker and QEMU starts in parallel to test latency behavior under contention

ITER=1000
DIR=../data/
CORES=1
MEM=256
PARALLEL=100

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

FC_RES=${DIR}/boot-times-parallel-${PARALLEL}-fc.dat
QEMU_RES=${DIR}/boot-times-parallel-${PARALLEL}-qemu.dat
RES=${DIR}/boot-times-parallel-${PARALLEL}.csv

rm -f ${FC_RES} ${QEMU_RES} ${RES}

killall firecracker 2> /dev/null
seq 1 $ITER | xargs -L1 -P$PARALLEL ./start-fc.sh -b ../bin/firecracker \
                  -k ../img/boot-time-vmlinux \
                  -r ../img/boot-time-disk.img \
                  -c $CORES \
                  -m $MEM \
                  -t ${FC_RES}

killall firecracker 2> /dev/null

killall qemu-system-x86_64 2> /dev/null

seq 1 $ITER | xargs -L1 -P$PARALLEL  ./start-qemu.sh -b ../bin/qemu-system-x86_64 \
                    -k ../img/boot-time-vmlinuz \
                    -r ../img/boot-time-disk.img \
                    -c $CORES \
                    -m $MEM \
                    -t ${QEMU_RES}

killall qemu-system-x86_64 2> /dev/null
rm -f *.log

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
