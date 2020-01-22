#! /bin/sh

# Measure boot times for different kernels

#set -x

ITER=200
DIR=../data/test
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

    local DAT=${RAW}/${PRE}-api.dat
    local CDF=${DIR}/${PRE}-api-cdf.dat

    rm -f ${DAT} ${CDF}
    
    killall -9 firecracker 2> /dev/null
    for i in $(seq ${ITER}); do
        echo "Firecracker ${KERNEL}: $i"
        ./util_start_fc.sh -b ../bin/firecracker -s \
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

run_cloudhv() {
    CHV_BZ_DAT=${RAW}/boot-serial-chv-bz.dat
    CHV_BZ_CDF=${DIR}/boot-serial-chv-bz-cdf.dat

    # Cloud Hypervisor bzImage
    killall -9 cloud-hypervisor 2> /dev/null
    for i in $(seq ${ITER}); do
        echo "Cloud Hypervisor(bz): $i"
        ./util_start_cloudhv.sh -b ../bin/cloud-hypervisor \
                                -k ../img/boot-time-pci-vmlinuz \
                                -r ../img/boot-time-disk.img \
                                -c $CORES \
                                -m $MEM \
                                -t ${CHV_BZ_DAT}
        sleep 1
        killall -9 cloud-hypervisor 2> /dev/null
    done
    rm -f *.log
    ./util_gen_cdf.py ${CHV_BZ_DAT} ${CHV_BZ_CDF}
}

run_firecracker ../img/boot-time-vmlinux          boot-serial-fc-nopci
#run_firecracker ../img/boot-time-linuxkit-vmlinux boot-serial-fc-linuxkit
run_cloudhv
