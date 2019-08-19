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
        -p) shift; PARALLEL=$1
            ;;
    esac
    shift
done

RAW=${DIR}/raw
mkdir -p ${RAW}

run_firecracker() {
    FC_DAT=${RAW}/boot-parallel-${PARALLEL}-fc.dat
    FC_CDF=${DIR}/boot-parallel-${PARALLEL}-fc-cdf.dat

    rm -f ${FC_DAT} ${FC_CDF}

    killall -9 firecracker 2> /dev/null
    seq 1 $ITER | xargs -L1 -P$PARALLEL ./util_start_fc.sh -b ../bin/firecracker \
                        -k ../img/boot-time-vmlinux \
                        -r ../img/boot-time-disk.img \
                        -c $CORES \
                        -m $MEM \
                        -t ${FC_DAT}
    sleep 10
    killall -9 firecracker 2> /dev/null
    rm -f *.log
    ./util_gen_cdf.py ${FC_DAT} ${FC_CDF}
}

run_cloudhv() {
    CHV_DAT=${RAW}/boot-parallel-${PARALLEL}-chv.dat
    CHV_CDF=${DIR}/boot-parallel-${PARALLEL}-chv-cdf.dat

    rm -f ${CHV_DAT} ${CHV_CDF}

    killall -9 cloud-hypervisor 2> /dev/null
    seq 1 $ITER | xargs -L1 -P$PARALLEL ./util_start_cloudhv.sh -b ../bin/cloud-hypervisor \
                        -k ../img/boot-time-pci-vmlinux \
                        -r ../img/boot-time-disk.img \
                        -c $CORES \
                        -m $MEM \
                        -t ${CHV_DAT}
    sleep 10
    killall -9 cloud-hypervisor 2> /dev/null
    rm -f *.log
    ./util_gen_cdf.py ${CHV_DAT} ${CHV_CDF}
}

run_qemu() {
    QEMU_DAT=${RAW}/boot-parallel-${PARALLEL}-qemu.dat
    QEMU_CDF=${DIR}/boot-parallel-${PARALLEL}-qemu-cdf.dat

    rm -f ${QEMU_DAT} ${QEMU_CDF}

    killall -9 qemu-system-x86_64 2> /dev/null
    seq 1 $ITER | xargs -L1 -P$PARALLEL  ./util_start_qemu.sh -b ../bin/qemu-system-x86_64 \
                        -k ../img/boot-time-pci-vmlinuz \
                        -r ../img/boot-time-disk.img \
                        -w qboot.bin \
                        -c $CORES \
                        -m $MEM \
                        -t ${QEMU_DAT}
    sleep 10
    killall -9 qemu-system-x86_64 2> /dev/null
    rm -f *.log
    ./util_gen_cdf.py ${QEMU_DAT} ${QEMU_CDF}
}

run_firecracker
run_cloudhv
run_qemu
