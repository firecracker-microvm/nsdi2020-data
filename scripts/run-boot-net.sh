#! /bin/sh

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

FC_NET_DAT=${RAW}/boot-serial-fc-net.dat
FC_NET_CDF=${DIR}/boot-serial-fc-net-cdf.dat

CHV_NET_DAT=${RAW}/boot-serial-chv-net.dat
CHV_NET_CDF=${DIR}/boot-serial-chv-net-cdf.dat



run_firecracker() {
    local DAT=${RAW}/boot-serial-fc-net-api.dat
    local CDF=${DIR}/boot-serial-fc-net-api-cdf.dat

    rm -f ${DAT} ${CDF}

    # Firecracker base + Network
    killall -9 firecracker 2> /dev/null
    for i in $(seq ${ITER}); do
        echo "Firecracker+Net: $i"
        ./util_start_fc.sh -b ../bin/firecracker -s \
                           -k ../img/boot-time-vmlinux \
                           -r ../img/boot-time-disk.img \
                           -c $CORES \
                           -m $MEM \
                           -i 0 \
                           -n \
                           -t ${DAT}
        sleep 1
        killall -9 firecracker 2> /dev/null
    done
    rm -f *.log
    ./util_gen_cdf.py ${DAT} ${CDF}
}

run_cloudhv() {
    local DAT=${RAW}/boot-serial-chv-net.dat
    local CDF=${DIR}/boot-serial-chv-net-cdf.dat

    rm -f ${DAT} ${CDF}

    # Cloud Hypervisor net
    killall -9 cloud-hypervisor 2> /dev/null
    for i in $(seq ${ITER}); do
        echo "Cloud Hypervisor+net: $i"
        ./util_start_cloudhv.sh -b ../bin/cloud-hypervisor \
                                -k ../img/boot-time-pci-vmlinux \
                                -r ../img/boot-time-disk.img \
                                -c $CORES \
                                -m $MEM \
                                -i 0 \
                                -n \
                                -t ${DAT}
        sleep 1
        killall -9 cloud-hypervisor 2> /dev/null
    done
    rm -f *.log
    ./util_gen_cdf.py ${DAT} ${CDF}
}

run_qemu() {
    local DAT=${RAW}/boot-serial-qboot-net.dat
    local CDF=${DIR}/boot-serial-qboot-net-cdf.dat

    rm -f ${DAT} ${CDF}
    
    # Qemu with qboot + Network
    killall -9 qemu-system-x86_64 2> /dev/null
    for i in $(seq ${ITER}); do
        echo "Qemu+qboot+Net: $i"
        ./util_start_qemu.sh -b ../bin/qemu-system-x86_64 \
                             -k ../img/boot-time-pci-vmlinuz \
                             -r ../img/boot-time-disk.img \
                             -w qboot.bin \
                             -c $CORES \
                             -m $MEM \
                             -i 0 \
                             -n \
                             -t ${DAT}
        sleep 1
        killall -9 qemu-system-x86_64 2> /dev/null
    done
    rm -f *.log
    ./util_gen_cdf.py ${DAT} ${CDF}
}

run_firecracker
run_cloudhv
run_qemu
