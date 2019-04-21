#! /bin/sh

DIR=../data/
CORES=2
MEM=512

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

FC_PRE=fio-fc
QEMU_PRE=fio-qemu

killall -9 firecracker 2> /dev/null
killall -9 qemu-system-x86_64 2> /dev/null

ID=0
VM_IP=$(./util_ipam.sh -v $ID)
SSH="ssh -i ../etc/ssh-bench.key -F ../etc/ssh-config root@${VM_IP}"

echo "Firecracker: Starting"
./util_start_fc.sh \
    -b ../bin/firecracker \
    -k ../img/bench-ssh-vmlinux \
    -r ../img/bench-ssh-disk.img \
    -c $CORES \
    -m $MEM \
    -i $ID \
    -n \
    -f $FILE \
    &

# 10 seconds should be enough
sleep 10

# Copy config
cat ../etc/fio-vm.cfg | ${SSH} "cat > fio-vm.cfg"

for TEST in $TESTS; do
    echo "Running $TEST"
    ${SSH} "fio --output-format=json --output=$FC_PRE-$TEST.json --section=$TEST fio-vm.cfg"
    ${SSH} "cat $FC_PRE-$TEST.json" > ${RAW}/${FC_PRE}-${TEST}.json
done
killall -9 firecracker 2> /dev/null

sleep 5
./util_start_qemu.sh \
    -b ../bin/qemu-system-x86_64 \
    -k ../img/bench-ssh-vmlinuz \
    -r ../img/bench-ssh-disk.img \
    -w qboot.bin \
    -c $CORES \
    -m $MEM \
    -i $ID \
    -n \
    -f $FILE \
    &

# 10 seconds should be enough
sleep 10

# Copy config
cat ../etc/fio-vm.cfg | ${SSH} "cat > fio-vm.cfg"

for TEST in $TESTS; do
    echo "Running $TEST"
    ${SSH} "fio --output-format=json --output=$QEMU_PRE-$TEST.json --section=$TEST fio-vm.cfg"
    ${SSH} "cat $QEMU_PRE-$TEST.json" > ${RAW}/${QEMU_PRE}-${TEST}.json
done
killall -9 qemu-system-x86_64 2> /dev/null
