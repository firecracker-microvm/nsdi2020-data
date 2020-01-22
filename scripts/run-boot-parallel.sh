#! /bin/sh

#set -x

# Run a large number of Firecracker and QEMU starts in parallel to test latency behavior under contention

ITER=1000
DIR=../data/test
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
    if [ -n "$1" ]; then
        local DAT=${RAW}/boot-parallel-${PARALLEL}-fc-file.dat
        local CDF=${DIR}/boot-parallel-${PARALLEL}-fc-file-cdf.dat
        local ARG=-s
    else
        local DAT=${RAW}/boot-parallel-${PARALLEL}-fc-api.dat
        local CDF=${DIR}/boot-parallel-${PARALLEL}-fc-api-cdf.dat
        local ARG=
    fi

    rm -f ${DAT} ${CDF}

    echo "Firecracker"

    killall -9 firecracker 2> /dev/null
    seq 1 $ITER | xargs -L1 -P$PARALLEL ./util_start_fc.sh -b ../bin/firecracker $ARG \
                        -k ../img/boot-time-pci-vmlinux \
                        -r ../img/boot-time-disk.img \
                        -c $CORES \
                        -m $MEM \
                        -t ${DAT}
    sleep 10
    killall -9 firecracker 2> /dev/null
    rm -f *.log
    ./util_gen_cdf.py ${DAT} ${CDF}
}

run_cloudhv() {
    local DAT=${RAW}/boot-parallel-${PARALLEL}-chv.dat
    local CDF=${DIR}/boot-parallel-${PARALLEL}-chv-cdf.dat

    rm -f ${DAT} ${CDF}

    echo "Cloud Hypervisor"

    killall -9 cloud-hypervisor 2> /dev/null
    seq 1 $ITER | xargs -L1 -P$PARALLEL ./util_start_cloudhv.sh -b ../bin/cloud-hypervisor \
                        -k ../img/boot-time-pci-vmlinux \
                        -r ../img/boot-time-disk.img \
                        -c $CORES \
                        -m $MEM \
                        -t ${DAT} > /dev/null
    sleep 10
    killall -9 cloud-hypervisor 2> /dev/null
    rm -f *.log
    ./util_gen_cdf.py ${DAT} ${CDF}
}

run_qemu() {
    local DAT=${RAW}/boot-parallel-${PARALLEL}-qemu.dat
    local CDF=${DIR}/boot-parallel-${PARALLEL}-qemu-cdf.dat

    rm -f ${DAT} ${CDF}

    echo "Qemu+qboot"

    seq 1 $ITER | xargs -L1 -P$PARALLEL  ./util_start_qemu.sh -b ../bin/qemu-system-x86_64 \
                        -k ../img/boot-time-pci-vmlinuz \
                        -r ../img/boot-time-disk.img \
                        -w qboot.bin \
                        -c $CORES \
                        -m $MEM \
                        -t ${DAT}
    sleep 10
    killall -9 qemu-system-x86_64 2> /dev/null
    rm -f *.log
    ./util_gen_cdf.py ${DAT} ${CDF}
}

run_firecracker
run_firecracker sock
run_cloudhv
run_qemu
