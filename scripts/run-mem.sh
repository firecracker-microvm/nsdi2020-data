#! /bin/sh

DIR=../data/test
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

CHV_PRE=${RAW}/mem-chv
CHV_RES=${DIR}/mem-chv.dat

CHV_BZ_PRE=${RAW}/mem-chv-bz
CHV_BZ_RES=${DIR}/mem-chv-bz.dat

QEMU_PRE=${RAW}/mem-qemu
QEMU_RES=${DIR}/mem-qemu.dat

killall -9 firecracker 2> /dev/null
killall -9 cloud-hypervisor 2> /dev/null
killall -9 qemu-system-x86_64 2> /dev/null

ID=0
VM_IP=$(./util_ipam.sh -v $ID)
SSH="ssh -i ../etc/ssh-bench.key -F ../etc/ssh-config root@${VM_IP}"

calc() {
    mem=$1
    inf=$2
    vm_inf=$3
    pmap_inf=$4
    outf=$5

    l=$(tail -1 ${inf})
    mem_kb=$(echo "$mem * 1024" | bc)
    vss=$(echo $l | cut -d' ' -f2)
    rss=$(echo $l | cut -d' ' -f3)

    vm_total=$(grep MemTotal:      $vm_inf | awk '{print $2}')
    vm_free=$(grep MemFree:        $vm_inf | awk '{print $2}')
    vm_avail=$(grep MemAvailable:  $vm_inf | awk '{print $2}')
    # On some system we don't get memory from within the VM.
    [ -z $vm_total ] && vm_total=0
    [ -z $vm_free  ] && vm_free=0
    [ -z $vm_avail ] && vm_avail=0
    
    pmap_data=$(./util_parse_pmap.py $pmap_inf)

    echo "$mem_kb $vss $rss $vm_total $vm_free $vm_avail $pmap_data" >> $outf
}

echo "# VMSZ VSS RSS VM_TOTAL VM_FREE VM_AVAIL PMAP_EXEC PMAP_DATA (sizes in KB)" > ${FC_RES}
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

        calc $MEM ${FC_PRE}-$MEM.txt ${FC_PRE}-$MEM-vm.txt ${FC_PRE}-$MEM-pmap.txt ${FC_RES}
        sleep 5
done

echo "# VMSZ VSS RSS VM_TOTAL VM_FREE VM_AVAIL PMAP_EXEC PMAP_DATA (sizes in KB)" > ${CHV_RES}
for MEM in $MEMSZS; do
    echo "Cloud Hypervisor+net: $MEM MB"
    ./util_start_cloudhv.sh \
        -b ../bin/cloud-hypervisor \
        -k ../img/bench-ssh-vmlinux \
        -r ../img/bench-ssh-disk.img \
        -c $CORES \
        -m $MEM \
        -i $ID \
        -n \
        &

        # 10 seconds should be enough
        sleep 10

        # there is no r missing below. comm is limited to 16 chars
        ps -o pid,vsz,rss,command -C cloud-hyperviso > ${CHV_PRE}-$MEM.txt
        pmap -x $(pgrep cloud-hyperviso) > ${CHV_PRE}-$MEM-pmap.txt
        ${SSH} "cat /proc/meminfo" > ${CHV_PRE}-$MEM-vm.txt
        killall -9 cloud-hypervisor 2> /dev/null

        calc $MEM ${CHV_PRE}-$MEM.txt ${CHV_PRE}-$MEM-vm.txt ${CHV_PRE}-$MEM-pmap.txt ${CHV_RES}
        sleep 5
done

echo "# VMSZ VSS RSS VM_TOTAL VM_FREE VM_AVAIL PMAP_EXEC PMAP_DATA (sizes in KB)" > ${QEMU_RES}
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

        calc $MEM ${QEMU_PRE}-$MEM.txt ${QEMU_PRE}-$MEM-vm.txt ${QEMU_PRE}-$MEM-pmap.txt ${QEMU_RES}
        sleep 5
done
