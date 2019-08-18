#! /bin/sh

ITER=1000
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

FC_DAT=${RAW}/boot-serial-fc.dat
FC_CDF=${DIR}/boot-serial-fc-cdf.dat

FC_NET_DAT=${RAW}/boot-serial-fc-net.dat
FC_NET_CDF=${DIR}/boot-serial-fc-net-cdf.dat

CHV_DAT=${RAW}/boot-serial-chv.dat
CHV_CDF=${DIR}/boot-serial-chv-cdf.dat

CHV_BZ_DAT=${RAW}/boot-serial-chv-bz.dat
CHV_BZ_CDF=${DIR}/boot-serial-chv-bz-cdf.dat

CHV_NET_DAT=${RAW}/boot-serial-chv-net.dat
CHV_NET_CDF=${DIR}/boot-serial-chv-net-cdf.dat

QEMU_DAT=${RAW}/boot-serial-qemu.dat
QEMU_CDF=${DIR}/boot-serial-qemu-cdf.dat

QEMU_QBOOT_DAT=${RAW}/boot-serial-qboot.dat
QEMU_QBOOT_CDF=${DIR}/boot-serial-qboot-cdf.dat

QEMU_QBOOT_NET_DAT=${RAW}/boot-serial-qboot-net.dat
QEMU_QBOOT_NET_CDF=${DIR}/boot-serial-qboot-net-cdf.dat

CSV=${DIR}/boot-serial.csv

rm -f ${FC_DAT} ${QEMU_DAT} ${QEMU_QBOOT_DAT} ${CSV}
rm -f ${FC_CDF} ${QEMU_CDF} ${QEMU_QBOOT_CDF}

rm -f ${CHV_DAT} ${CHV_CDF} ${CHV_BZ_DAT} ${CHV_BZ_CDF}
rm -f ${CHV_NET_DAT} ${CHV_NET_CDF}

rm -f ${FC_NET_DAT} ${QEMU_QBOOT_NET_DAT}
rm -f ${FC_NET_CDF} ${QEMU_QBOOT_NET_CDF}

# Firecracker base
killall -9 firecracker 2> /dev/null
for i in $(seq ${ITER}); do
    echo "Firecracker: $i"
    ./util_start_fc.sh -b ../bin/firecracker \
                  -k ../img/boot-time-vmlinux \
                  -r ../img/boot-time-disk.img \
                  -c $CORES \
                  -m $MEM \
                  -t ${FC_DAT}
    sleep 1
    killall -9 firecracker 2> /dev/null
done
rm -f *.log
./util_gen_cdf.py ${FC_DAT} ${FC_CDF}

# Firecracker base + Network
killall -9 firecracker 2> /dev/null
for i in $(seq ${ITER}); do
    echo "Firecracker+Net: $i"
    ./util_start_fc.sh -b ../bin/firecracker \
                  -k ../img/boot-time-vmlinux \
                  -r ../img/boot-time-disk.img \
                  -c $CORES \
                  -m $MEM \
                  -i 0 \
                  -n \
                  -t ${FC_NET_DAT}
    sleep 1
    killall -9 firecracker 2> /dev/null
done
rm -f *.log
./util_gen_cdf.py ${FC_NET_DAT} ${FC_NET_CDF}

# Cloud Hypervisor base
killall -9 cloud-hypervisor 2> /dev/null
for i in $(seq ${ITER}); do
    echo "Cloud Hypervisor: $i"
    ./util_start_cloudhv.sh -b ../bin/cloud-hypervisor \
                  -k ../img/boot-time-vmlinux \
                  -r ../img/boot-time-disk.img \
                  -c $CORES \
                  -m $MEM \
                  -t ${CHV_DAT}
    sleep 1
    killall -9 cloud-hypervisor 2> /dev/null
done
rm -f *.log
./util_gen_cdf.py ${CHV_DAT} ${CHV_CDF}

# Cloud Hypervisor bzImage
killall -9 cloud-hypervisor 2> /dev/null
for i in $(seq ${ITER}); do
    echo "Cloud Hypervisor(bz): $i"
    ./util_start_cloudhv.sh -b ../bin/cloud-hypervisor \
                  -k ../img/boot-time-vmlinuz \
                  -r ../img/boot-time-disk.img \
                  -c $CORES \
                  -m $MEM \
                  -t ${CHV_BZ_DAT}
    sleep 1
    killall -9 cloud-hypervisor 2> /dev/null
done
rm -f *.log
./util_gen_cdf.py ${CHV_BZ_DAT} ${CHV_BZ_CDF}

# Cloud Hypervisor net
killall -9 cloud-hypervisor 2> /dev/null
for i in $(seq ${ITER}); do
    echo "Cloud Hypervisor+net: $i"
    ./util_start_cloudhv.sh -b ../bin/cloud-hypervisor \
                  -k ../img/boot-time-vmlinux \
                  -r ../img/boot-time-disk.img \
                  -c $CORES \
                  -m $MEM \
                  -n \
                  -t ${CHV_NET_DAT}
    sleep 1
    killall -9 cloud-hypervisor 2> /dev/null
done
rm -f *.log
./util_gen_cdf.py ${CHV_NET_DAT} ${CHV_NET_CDF}

# Qemu base
killall -9 qemu-system-x86_64 2> /dev/null
for i in $(seq ${ITER}); do
    echo "Qemu: $i"
    ./util_start_qemu.sh -b ../bin/qemu-system-x86_64 \
                    -k ../img/boot-time-pci-vmlinuz \
                    -r ../img/boot-time-disk.img \
                    -c $CORES \
                    -m $MEM \
                    -t ${QEMU_DAT}
    sleep 1
    killall -9 qemu-system-x86_64 2> /dev/null
done
rm -f *.log
./util_gen_cdf.py ${QEMU_DAT} ${QEMU_CDF}

# Qemu with qboot
killall -9 qemu-system-x86_64 2> /dev/null
for i in $(seq ${ITER}); do
    echo "Qemu+qboot: $i"
    ./util_start_qemu.sh -b ../bin/qemu-system-x86_64 \
                    -k ../img/boot-time-pci-vmlinuz \
                    -r ../img/boot-time-disk.img \
                    -w qboot.bin \
                    -c $CORES \
                    -m $MEM \
                    -t ${QEMU_QBOOT_DAT}
    sleep 0.4
    killall -9 qemu-system-x86_64 2> /dev/null
done
rm -f *.log
./util_gen_cdf.py ${QEMU_QBOOT_DAT} ${QEMU_QBOOT_CDF}

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
                    -t ${QEMU_QBOOT_NET_DAT}
    sleep 0.4
    killall -9 qemu-system-x86_64 2> /dev/null
done
rm -f *.log
./util_gen_cdf.py ${QEMU_QBOOT_NET_DAT} ${QEMU_QBOOT_NET_CDF}


# Create R compliant data
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
