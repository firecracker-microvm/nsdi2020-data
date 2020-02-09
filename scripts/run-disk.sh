#! /bin/sh

DIR=../data/test
CORES=2
MEM=512
FILE=../img/disk-bench.img

while [ $# -gt 0 ]; do
    case $1 in
        -d) shift; DIR=$1
            ;;
        -f) shift; FILE=$1
            ;;
    esac
    shift
done

TESTS="rand-read-4k rand-read-4k-qd1"
TESTS="$TESTS rand-write-4k rand-write-4k-qd1"
TESTS="$TESTS rand-read-128k rand-read-128k-qd1"
TESTS="$TESTS rand-write-128k rand-write-128k-qd1"

RAW=${DIR}/raw
mkdir -p ${RAW}

# Create a file if it does not exist
[ -e $FILE ] || fallocate -l 10G $FILE

killall -9 firecracker 2> /dev/null
killall -9 cloud-hypervisor 2> /dev/null
killall -9 qemu-system-x86_64 2> /dev/null

ID=0
VM_IP=$(./util_ipam.sh -v $ID)
SSH="ssh -i ../etc/ssh-bench.key -F ../etc/ssh-config root@${VM_IP}"

run_firecracker() {
    local PRE=fio-fc

    echo "Firecracker: Starting"
    ./util_start_fc.sh -b ../bin/firecracker \
        -k ../img/bench-ssh-vmlinux -r ../img/bench-ssh-disk.img \
        -c $CORES -m $MEM -i $ID \
        -s -n -f $FILE &

    # 10 seconds should be enough
    sleep 10

    # Copy config
    cat ../etc/fio-vm.cfg | ${SSH} "cat > fio-vm.cfg"

    for TEST in $TESTS; do
        echo "Running $TEST"
        ${SSH} "fio --output-format=json --output=$PRE-$TEST.json --section=$TEST fio-vm.cfg"
        ${SSH} "cat $PRE-$TEST.json" > ${RAW}/${PRE}-${TEST}.json
    done

    killall -9 firecracker 2> /dev/null
}

run_cloudhv() {
    local PRE=fio-chv

    echo "Cloud Hypervisor: Starting"
    ./util_start_cloudhv.sh -b ../bin/cloud-hypervisor \
        -k ../img/bench-ssh-vmlinux -r ../img/bench-ssh-disk.img \
        -c $CORES -m $MEM -i $ID \
        -n -f $FILE &

    # 10 seconds should be enough
    sleep 10

    # Copy config
    cat ../etc/fio-vm.cfg | ${SSH} "cat > fio-vm.cfg"

    for TEST in $TESTS; do
        echo "Running $TEST"
        ${SSH} "fio --output-format=json --output=$PRE-$TEST.json --section=$TEST fio-vm.cfg"
        ${SSH} "cat $PRE-$TEST.json" > ${RAW}/${PRE}-${TEST}.json
    done

    killall -9 cloud-hypervisor 2> /dev/null
}

run_qemu() {
    local PRE=fio-qemu

    echo "qemu: Starting"
    ./util_start_qemu.sh -b ../bin/qemu-system-x86_64 \
    -k ../img/bench-ssh-vmlinuz -r ../img/bench-ssh-disk.img -w qboot.bin \
    -c $CORES -m $MEM -i $ID \
    -n -f $FILE &

    # 10 seconds should be enough
    sleep 10

    # Copy config
    cat ../etc/fio-vm.cfg | ${SSH} "cat > fio-vm.cfg"

    for TEST in $TESTS; do
        echo "Running $TEST"
        ${SSH} "fio --output-format=json --output=$PRE-$TEST.json --section=$TEST fio-vm.cfg"
        ${SSH} "cat $PRE-$TEST.json" > ${RAW}/${PRE}-${TEST}.json
    done
    killall -9 qemu-system-x86_64 2> /dev/null
}

run_firecracker
sleep 5
run_qemu
sleep 5
run_cloudhv
