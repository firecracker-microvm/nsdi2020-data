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

PCI_DAT=${RAW}/boot-serial-fc-pci.dat
PCI_CDF=${DIR}/boot-serial-fc-pci-cdf.dat

LK_DAT=${RAW}/boot-serial-fc-linuxkit.dat
LK_CDF=${DIR}/boot-serial-fc-linuxkit-cdf.dat

rm -f ${PCI_DAT} ${PCI_CDF} ${LK_DAT} ${LK_CDF}

killall -9 firecracker 2> /dev/null
for i in $(seq ${ITER}); do
    echo "Firecracker+PCI kernel: $i"
    ./util_start_fc.sh -b ../bin/firecracker \
                  -k ../img/boot-time-pci-vmlinux \
                  -r ../img/boot-time-disk.img \
                  -c $CORES \
                  -m $MEM \
                  -t ${PCI_DAT}
    sleep 0.4
    killall -9 firecracker 2> /dev/null
done
rm -f *.log
./util_gen_cdf.py ${PCI_DAT} ${PCI_CDF}

killall -9 firecracker 2> /dev/null
for i in $(seq ${ITER}); do
    echo "Firecracker+LinuxKit kernel: $i"
    ./util_start_fc.sh -b ../bin/firecracker \
                  -k ../img/boot-time-linuxkit-vmlinux \
                  -r ../img/boot-time-disk.img \
                  -c $CORES \
                  -m $MEM \
                  -t ${LK_DAT}
    sleep 0.4
    killall -9 firecracker 2> /dev/null
done
rm -f *.log
./util_gen_cdf.py ${LK_DAT} ${LK_CDF}
