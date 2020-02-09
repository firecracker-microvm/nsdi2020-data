#! /bin/sh

ITER=500
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
    if [ -n "$1" ]; then
        local DAT=${RAW}/boot-serial-fc-file.dat
        local CDF=${DIR}/boot-serial-fc-file-cdf.dat
        local ARG=-s
    else
        local DAT=${RAW}/boot-serial-fc-api.dat
        local CDF=${DIR}/boot-serial-fc-api-cdf.dat
        local ARG=
    fi
    rm -f ${DAT} ${CDF}

    # Firecracker base
    killall -9 firecracker 2> /dev/null
    for i in $(seq ${ITER}); do
        echo "Firecracker: $i"
        ./util_start_fc.sh -b ../bin/firecracker $ARG \
                           -k ../img/boot-time-pci-vmlinux \
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
    local DAT=${RAW}/boot-serial-chv.dat
    local CDF=${DIR}/boot-serial-chv-cdf.dat

    rm ${DAT} ${CDF}

    # Cloud Hypervisor base
    killall -9 cloud-hypervisor 2> /dev/null
    for i in $(seq ${ITER}); do
        echo "Cloud Hypervisor: $i"
        ./util_start_cloudhv.sh -b ../bin/cloud-hypervisor \
                                -k ../img/boot-time-pci-vmlinux \
                                -r ../img/boot-time-disk.img \
                                -c $CORES \
                                -m $MEM \
                                -t ${DAT}
        sleep 1
        killall -9 cloud-hypervisor 2> /dev/null
    done
    rm -f *.log
    ./util_gen_cdf.py ${DAT} ${CDF}
}

run_qemu() {
    local DAT=${RAW}/boot-serial-qemu.dat
    local CDF=${DIR}/boot-serial-qemu-cdf.dat

    rm -f ${DAT} ${CDF}
    
    killall -9 qemu-system-x86_64 2> /dev/null
    for i in $(seq ${ITER}); do
        echo "Qemu: $i"
        ./util_start_qemu.sh -b ../bin/qemu-system-x86_64 \
                             -k ../img/boot-time-pci-vmlinuz \
                             -r ../img/boot-time-disk.img \
                             -c $CORES \
                             -m $MEM \
                             -t ${DAT}
        sleep 1
        killall -9 qemu-system-x86_64 2> /dev/null
    done
    rm -f *.log
    ./util_gen_cdf.py ${DAT} ${CDF}
}

run_qemu_qboot() {
    local DAT=${RAW}/boot-serial-qboot.dat
    local CDF=${DIR}/boot-serial-qboot-cdf.dat

    rm -f ${DAT} ${CDF}

    killall -9 qemu-system-x86_64 2> /dev/null
    for i in $(seq ${ITER}); do
        echo "Qemu+qboot: $i"
        ./util_start_qemu.sh -b ../bin/qemu-system-x86_64 \
                             -k ../img/boot-time-pci-vmlinuz \
                             -r ../img/boot-time-disk.img \
                             -w qboot.bin \
                             -c $CORES \
                             -m $MEM \
                             -t ${DAT}
        sleep 1
        killall -9 qemu-system-x86_64 2> /dev/null
    done
    rm -f *.log
    ./util_gen_cdf.py ${DAT} ${CDF}
}

run_qemu_uvm() {
    local DAT=${RAW}/boot-serial-qemu-uvm.dat
    local CDF=${DIR}/boot-serial-qemu-uvm-cdf.dat

    rm -f ${DAT} ${CDF}

    killall -9 qemu-system-x86_64 2> /dev/null
    for i in $(seq ${ITER}); do
        echo "Qemu MicroVM: $i"
        ./util_start_qemu_uvm.sh -b ../bin/qemu-system-x86_64 \
                                 -k ../img/boot-time-pci-vmlinuz \
                                 -r ../img/boot-time-disk.img \
                                 -c $CORES \
                                 -m $MEM \
                                 -t ${DAT}
        sleep 1
        killall -9 qemu-system-x86_64 2> /dev/null
    done
    rm -f *.log
    ./util_gen_cdf.py ${DAT} ${CDF}
}

run_firecracker
run_firecracker sock
run_cloudhv
run_qemu
run_qemu_qboot
run_qemu_uvm
