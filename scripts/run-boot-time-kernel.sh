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

mkdir -p ${DIR}

RES_PCI=${DIR}/boot-times-fc-pci.dat
RES_LK=${DIR}/boot-times-fc-linuxkit.dat

rm -f ${RES_PCI} ${RES_LK}

killall firecracker 2> /dev/null
for i in $(seq ${ITER}); do
    ./start-fc.sh -b ../bin/firecracker \
                  -k ../img/boot-time-pci-vmlinux \
                  -r ../img/boot-time-disk.img \
                  -c $CORES \
                  -m $MEM \
                  -t ${RES_PCI}
    sleep 0.4
    killall firecracker 2> /dev/null
done
rm -f *.log
./gen-cdf.py ${RES_PCI}

killall firecracker 2> /dev/null
for i in $(seq ${ITER}); do
    ./start-fc.sh -b ../bin/firecracker \
                  -k ../img/boot-time-linuxkit-vmlinux \
                  -r ../img/boot-time-disk.img \
                  -c $CORES \
                  -m $MEM \
                  -t ${RES_LK}
    sleep 0.4
    killall firecracker 2> /dev/null
done
rm -f *.log
./gen-cdf.py ${RES_LK}
