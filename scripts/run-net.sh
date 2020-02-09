#! /bin/sh

# Run some network benchmark

TIME=30
DIR=../data/test
CORES=2
MEM=512

while [ $# -gt 0 ]; do
    case $1 in
        -t) shift; TIME=$1
            ;;
        -d) shift; DIR=$1
            ;;
    esac
    shift
done

RAW=${DIR}/raw
mkdir -p ${RAW}

FC_PRE=${RAW}/net-fc
FC_RES=${DIR}/net-fc.txt

CHV_PRE=${RAW}/net-chv
CHV_RES=${DIR}/net-chv.txt

QEMU_PRE=${RAW}/net-qemu
QEMU_RES=${DIR}/net-qemu.txt

LOCAL_PRE=${RAW}/net-localhost
LOCAL_RES=${DIR}/net-localhost.txt

ID=0
TAP_DEV=$(./util_ipam.sh -t $ID)
TAP_IP=$(./util_ipam.sh -h $ID)
VM_IP=$(./util_ipam.sh -v $ID)

SSH="ssh -i ../etc/ssh-bench.key -F ../etc/ssh-config root@${VM_IP}"

run_remote() {
    pre=$1
    res=$2

    echo "Starting iperf server in VM"
    ${SSH} "iperf3 -s -D"
    sleep 2

    echo "Starting iperf to VM (1 stream)"
    iperf3 -t ${TIME} -J -c ${VM_IP} > ${pre}-rx-01.json
    RX01=$(cat ${pre}-rx-01.json | jq '.end.sum_sent.bits_per_second')
    RX01G=$(echo "scale = 2; ${RX01} / (1000 * 1000 * 1000)" | bc)
    sleep 2

    echo "Starting iperf to VM (10 streams)"
    iperf3 -t ${TIME} -J -P 10 -c ${VM_IP} > ${pre}-rx-10.json
    RX10=$(cat ${pre}-rx-10.json | jq '.end.sum_sent.bits_per_second')
    RX10G=$(echo "scale = 2; ${RX10} / (1000 * 1000 * 1000)" | bc)
    sleep 2

    echo "Starting iperf server on host"
    iperf3 -s -D -1
    sleep 2

    echo "Starting iperf from VM (1 stream)"
    ${SSH} "iperf3 -t ${TIME} -J -c ${TAP_IP}" > ${pre}-tx-01.json
    TX01=$(cat ${pre}-tx-01.json | jq '.end.sum_sent.bits_per_second')
    TX01G=$(echo "scale = 2; ${TX01} / (1000 * 1000 * 1000)" | bc)
    sleep 2

    echo "Starting iperf server on host"
    iperf3 -s -D
    sleep 2

    echo "Starting iperf from VM (10 streams)"
    ${SSH} "iperf3 -t ${TIME} -J -P10 -c ${TAP_IP}" > ${pre}-tx-10.json
    TX10=$(cat ${pre}-tx-10.json | jq '.end.sum_sent.bits_per_second')
    TX10G=$(echo "scale = 2; ${TX10} / (1000 * 1000 * 1000)" | bc)

    killall -9 iperf3 2> /dev/null

    echo "Ping test"
    ping -n -c 20 ${VM_IP} > ${pre}-ping.txt

    # Print result summary
    printf "1-stream\t10-streams\n"                    > ${res}
    printf "RX\tTX\tRX\tTX\n"                         >> ${res}
    printf "${RX01G}\t${TX01G}\t${RX10G}\t${TX10G}\n" >> ${res}
}


run_loopback() {
    echo "Loopback..."
    echo "Starting iperf3"
    iperf3 -s -D

    echo "Starting iperf (1 stream)"
    iperf3 -t ${TIME} -J -c ${TAP_IP} > ${LOCAL_PRE}-rx-01.json
    RX01=$(cat ${LOCAL_PRE}-rx-01.json | jq '.end.sum_sent.bits_per_second')
    RX01G=$(echo "scale = 2; ${RX01} / (1000 * 1000 * 1000)" | bc)
    sleep 2

    echo "Starting iperf (10 streams)"
    iperf3 -t ${TIME} -J -P 10 -c ${TAP_IP} > ${LOCAL_PRE}-rx-10.json
    RX10=$(cat ${LOCAL_PRE}-rx-10.json | jq '.end.sum_sent.bits_per_second')
    RX10G=$(echo "scale = 2; ${RX10} / (1000 * 1000 * 1000)" | bc)

    killall -9 iperf3 2> /dev/null

    echo "Ping test"
    ping -n -c 20 ${TAP_IP} > ${LOCAL_PRE}-ping.txt

    # Print result summary
    printf "1-stream\t10-streams\n"                    > ${LOCAL_RES}
    printf "RX\tTX\tRX\tTX\n"                         >> ${LOCAL_RES}
    printf "${RX01G}\t${RX01G}\t${RX10G}\t${RX10G}\n" >> ${LOCAL_RES}

    killall -9 iperf3 2> /dev/null
}

run_firecracker() {
    killall -9 firecracker 2> /dev/null
    echo "Firecracker: Starting..."
    ./util_start_fc.sh \
        -b ../bin/firecracker \
        -k ../img/bench-ssh-vmlinux \
        -r ../img/bench-ssh-disk.img \
        -c $CORES \
        -m $MEM \
        -i $ID \
        -s -n \
        &

    # 10 seconds should be enough
    sleep 10
    run_remote ${FC_PRE} ${FC_RES}
    killall -9 firecracker 2> /dev/null
    killall -9 iperf3 2> /dev/null
}

run_cloudhv() {
    killall -9 cloud-hypervisor 2> /dev/null
    echo "cloud-hypervisor: Starting..."
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
        run_remote ${CHV_PRE} ${CHV_RES}
        killall -9 cloud-hypervisor 2> /dev/null
}

run_qemu() {
    killall -9 qemu-system-x86_64 2> /dev/null
    echo "qemu: Starting..."
    ./util_start_qemu.sh \
        -b ../bin/qemu-system-x86_64 \
        -k ../img/bench-ssh-vmlinuz \
        -r ../img/bench-ssh-disk.img \
        -c $CORES \
        -m $MEM \
        -i $ID \
        -n \
        &

    # 10 seconds should be enough
    sleep 10
    run_remote ${QEMU_PRE} ${QEMU_RES}
    killall -9 qemu-system-x86_64 2> /dev/null
    killall -9 iperf3 2> /dev/null
}


killall -9 firecracker 2> /dev/null
killall -9 cloud-hypervisor 2> /dev/null
killall -9 qemu-system-x86_64 2> /dev/null
killall -9 iperf3 2> /dev/null

sleep 5
run_loopback

if [ $(grep -c rdrand /proc/cpuinfo) -eq 0 ]; then
    echo "benchmark rootfs needs CPU rdrand support"
    exit 1
fi

sleep 5
run_firecracker
sleep 5
run_cloudhv
sleep 5
run_qemu
