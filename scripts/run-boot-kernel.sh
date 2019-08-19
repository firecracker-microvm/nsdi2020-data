#! /bin/sh

# Measure boot times for different kernels

#set -x

ITER=200
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

RAW=${DIR}/raw
mkdir -p ${RAW}

run_firecracker() {
    local KERNEL=$1
    local PRE=$2

    local DAT=${RAW}/${PRE}.dat
    local CDF=${DIR}/${PRE}-cdf.dat

    rm -f ${DAT} ${CDF}
    
    killall -9 firecracker 2> /dev/null
    for i in $(seq ${ITER}); do
        echo "Firecracker+PCI kernel: $i"
        ./util_start_fc.sh -b ../bin/firecracker \
                           -k ../img/${KERNEL} \
                           -r ../img/boot-time-disk.img \
                           -c $CORES \
                           -m $MEM \
                           -t ${DAT}
        sleep 1
        killall -9 firecracker 2> /dev/null
    done
    rm -f *.log
    ./util_gen_cdf.py ${DAT} ${CDF}
}

run_firecracker ../img/boot-time-vmlinux boot-serial-fc-nopci
run_firecracker ../img/boot-time-linuxkit-vmlinux boot-serial-fc-linuxkit
