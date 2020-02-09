#! /bin/bash

ID=$RANDOM
CLOUDHV=../bin/cloud-hypervisor
CORES=1
MEM=256
NET=

while [ $# -gt 0 ]; do
    case $1 in
        -i) shift; ID=$1
            ;;
        -b) shift; CLOUDHV=$1
            ;;
        -k) shift; KERNEL=$1
            ;;
        -r) shift; ROOTFS=$1
            ;;
        -c) shift; CORES=$1
            ;;
        -m) shift; MEM=$1
            ;;
        -n) NET=on
            ;;
        -f) shift; DISK=$1
            ;;
        -t) shift; TIMEFILE=$1
            ;;
        -d) DEBUG=yes
            ;;
    esac
    shift
done

[ "x$DEBUG" != "x" ] && set -x


# Common CLOUDHV command line options
CLOUDHV="$CLOUDHV --cpus boot=$CORES --memory size=${MEM}M "

KERNEL_ARGS="reboot=k tsc=reliable ipv6.disable=1 panic=-1 ro"
if [ "x$DEBUG" = "x" ]; then
    CLOUDHV="$CLOUDHV --serial off --console null"
    KERNEL_ARGS="$KERNEL_ARGS quiet"
else
    CLOUDHV="$CLOUDHV --serial tty --console off"
    KERNEL_ARGS="$KERNEL_ARGS console=ttyS0"
fi

if [ "x$ROOTFS" != "x" ]; then
    CLOUDHV="$CLOUDHV --disk path=$ROOTFS "
    ROOT="root=/dev/vda"
fi
if [ "x$DISK" != "x" ]; then    
    CLOUDHV="$CLOUDHV path=$DISK "
fi

if [ "x$NET" != "x" ]; then
    TAP_DEV=$(./util_ipam.sh -t $ID)
    TAP_IP=$(./util_ipam.sh -h $ID)
    VM_MAC=$(./util_ipam.sh -a $ID)
    VM_IP=$(./util_ipam.sh -v $ID)
    VM_MASK=$(./util_ipam.sh -m $ID)

    KERNEL_ARGS="$KERNEL_ARGS ip=$VM_IP::$TAP_IP:$VM_MASK::eth0:off"
    CLOUDHV="$CLOUDHV --net tap=$TAP_DEV,MAC=$VM_MAC "
fi

us_start=$(($(date +%s%N)/1000))

${CLOUDHV} \
    --kernel "$KERNEL" \
    --cmdline "$ROOT init=/init $KERNEL_ARGS"

us_end=$(($(date +%s%N)/1000))
us_time=$(expr $us_end - $us_start)

if [ "x$TIMEFILE" = "x" ]; then
    echo "$us_time"
else
    echo "$us_time" >> "$TIMEFILE"
fi
