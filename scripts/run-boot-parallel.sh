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

RAW=${DIR}/raw
mkdir -p ${RAW}

FC_DAT=${RAW}/boot-times-parallel-${PARALLEL}-fc.dat
FC_CDF=${DIR}/boot-times-parallel-${PARALLEL}-fc-cdf.dat

QEMU_DAT=${RAW}/boot-times-parallel-${PARALLEL}-qemu.dat
QEMU_CDF=${DIR}/boot-times-parallel-${PARALLEL}-qemu-cdf.dat

CSV=${DIR}/boot-times-parallel-${PARALLEL}.csv

rm -f ${FC_DAT} ${QEMU_DAT} ${CSV}

killall firecracker 2> /dev/null

seq 1 $ITER | xargs -L1 -P$PARALLEL ./util_start_fc.sh -b ../bin/firecracker \
                  -k ../img/boot-time-vmlinux \
                  -r ../img/boot-time-disk.img \
                  -c $CORES \
                  -m $MEM \
                  -t ${FC_DAT}
sleep 10
killall firecracker 2> /dev/null
rm -f *.log
./util_gen_cdf.py ${FC_DAT} ${FC_CDF}


killall qemu-system-x86_64 2> /dev/null
seq 1 $ITER | xargs -L1 -P$PARALLEL  ./util_start_qemu.sh -b ../bin/qemu-system-x86_64 \
                    -k ../img/boot-time-pci-vmlinuz \
                    -r ../img/boot-time-disk.img \
                    -w qboot.bin \
                    -c $CORES \
                    -m $MEM \
                    -t ${QEMU_DAT}
sleep 10
killall qemu-system-x86_64 2> /dev/null
rm -f *.log
./util_gen_cdf.py ${QEMU_DAT} ${QEMU_CDF}

# Munch the data
echo "bootsecs,vmm" > ${CSV}

while IFS= read -r l; do
    # $l is in microseconds
    s=$(echo "scale=3; $l/1000000" | bc)
    echo "$s,qemu" >> ${CSV}
done < ${QEMU_DAT}

while IFS= read -r l; do
    # $l is in [microseconds ms]
    us=$(echo $l | cut -d ' ' -f1)
    s=$(echo "scale=3; $us/1000000" | bc)
    echo "$s,firecracker-e2e" >> ${CSV}
done < ${FC_DAT}

while IFS= read -r l; do
    # $l is in [microseconds ms]
    ms=$(echo $l | cut -d ' ' -f2)
    s=$(echo "scale=3; $ms/1000" | bc)
    echo "$s,firecracker" >> ${CSV}
done < ${FC_DAT}
