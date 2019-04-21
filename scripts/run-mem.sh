#! /bin/sh

DIR=../data/
CORES=1

while [ $# -gt 0 ]; do
    case $1 in
        -d) shift; DIR=$1
            ;;
    esac
    shift
done

MEMSZS="128 256 512 1024 1536 2048 3072 4096 6144 8192"

RAW=${DIR}/raw
mkdir -p ${RAW}

FC_PRE=${RAW}/mem-fc
FC_RES=${DIR}/mem-fc.dat

QEMU_PRE=${RAW}/mem-qemu
QEMU_RES=${DIR}/mem-qemu.dat

killall -9 firecracker 2> /dev/null
killall -9 qemu-system-x86_64 2> /dev/null

ID=0
VM_IP=$(./util_ipam.sh -v $ID)
SSH="ssh -i ../etc/ssh-bench.key -F ../etc/ssh-config root@${VM_IP}"

calc() {
    mem=$1
    inf=$2
    vm_inf=$3
    outf=$4

    l=$(tail -1 ${inf})
    mem_kb=$(echo "$mem * 1024" | bc)
    vss=$(echo $l | cut -d' ' -f2)
    rss=$(echo $l | cut -d' ' -f3)

    vm_total=$(grep MemTotal:      $vm_inf | awk '{print $2}')
    vm_free=$(grep MemFree:        $vm_inf | awk '{print $2}')
    vm_avail=$(grep MemAvailable:  $vm_inf | awk '{print $2}')
    
    echo "$mem_kb $vss $rss $vm_total $vm_free $vm_avail" >> $outf
}

echo "# VMSZ VSS RSS VM_TOTAL VM_FREE VM_AVAIL (sizes in KB)" > ${FC_RES}
for MEM in $MEMSZS; do
    echo "Firecracker+net: $MEM MB"
    ./util_start_fc.sh \
        -b ../bin/firecracker \
        -k ../img/bench-ssh-vmlinux \
        -r ../img/bench-ssh-disk.img \
        -c $CORES \
        -m $MEM \
        -i $ID \
        -n \
        &

        # 10 seconds should be enough
        sleep 10
        
        ps -o pid,vsz,rss,command -C firecracker > ${FC_PRE}-$MEM.txt
        pmap -x $(pgrep firecracker) > ${FC_PRE}-$MEM-pmap.txt
        ${SSH} "cat /proc/meminfo" > ${FC_PRE}-$MEM-vm.txt
        killall -9 firecracker 2> /dev/null

        calc $MEM ${FC_PRE}-$MEM.txt ${FC_PRE}-$MEM-vm.txt ${FC_RES}
        sleep 5
done

set -x

echo "# VMSZ VSS RSS VM_TOTAL VM_FREE VM_AVAIL (sizes in KB)" > ${QEMU_RES}
for MEM in $MEMSZS; do
    echo "qemu+net: $MEM MB"
    ./util_start_qemu.sh \
        -b ../bin/qemu-system-x86_64 \
        -k ../img/bench-ssh-vmlinuz \
        -r ../img/bench-ssh-disk.img \
        -w qboot.bin \
        -c $CORES \
        -m $MEM \
        -i $ID \
        -n \
        &

        # 10 seconds should be enough
        sleep 10
        
        ps -o pid,vsz,rss,command -C qemu-system-x86_64 > ${QEMU_PRE}-$MEM.txt
        # pgrep arg needs to be qemu-system-x86 not qemu-system-x86_64
        pmap -x $(pgrep qemu-system-x86) > ${QEMU_PRE}-$MEM-pmap.txt
        ${SSH} "cat /proc/meminfo" > ${QEMU_PRE}-$MEM-vm.txt
        killall -9 qemu-system-x86_64 2> /dev/null

        calc $MEM ${QEMU_PRE}-$MEM.txt ${QEMU_PRE}-$MEM-vm.txt ${QEMU_RES}
        sleep 5
done
