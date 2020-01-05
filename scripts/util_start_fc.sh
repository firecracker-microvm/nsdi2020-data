#! /bin/bash -e

# defaults
ID=$RANDOM
FC=../bin/firecracker
CORES=1
MEM=256
NET=
SOCK=

while [ $# -gt 0 ]; do
    case $1 in
        -i) shift; ID=$1
            ;;
        -b) shift; FC=$1
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
        -l) shift; LOGFILE=$1
            ;;
        -s) SOCK=on
            ;;
        -d) DEBUG=$1
            ;;
    esac
    shift
done

[ "x$LOGFILE" == "x" ] && LOGFILE="/tmp/fc-$ID.log"
[ "$SOCK" == "on" ] && SOCK="/tmp/fc-$ID.sock"

rm -f "$SOCK"

NETCFG=
if [ "x$NET" != "x" ]; then
    TAP_DEV=$(./util_ipam.sh -t $ID)
    TAP_IP=$(./util_ipam.sh -h $ID)
    VM_MAC=$(./util_ipam.sh -a $ID)
    VM_IP=$(./util_ipam.sh -v $ID)
    VM_MASK=$(./util_ipam.sh -m $ID)
    NETCFG="-n ${TAP_DEV},${TAP_IP},${VM_MAC},${VM_IP},${VM_MASK}"
fi

DISKCFG=
if [ "x$DISK" != "x" ]; then
    DISKCFG="-disk $DISK"
fi

if [ "x$SOCK" == "x" ]; then
    # Use config file
    CFG_FILE="/tmp/fc-$ID.json"
    
    # Write config file
    ../bin/config-fc -o ${CFG_FILE} -k ${KERNEL} -r ${ROOTFS} -c ${CORES} -m ${MEM} ${NETCFG} ${DISKCFG} ${DEBUG}
    
    us_start=$(($(date +%s%N)/1000))
    $FC --no-api --config-file "$CFG_FILE" 2> "$LOGFILE"
else
    us_start=$(($(date +%s%N)/1000))

    # Use the API socket
    $FC --api-sock "$SOCK" 2> "$LOGFILE" &
    FC_PID=$!

    while [ ! -e "$SOCK" ]; do
        sleep 0.001s
    done

    # Configure the VM using the socket
    ../bin/config-fc -s $SOCK -k ${KERNEL} -r ${ROOTFS} -c ${CORES} -m ${MEM} ${NETCFG} ${DISKCFG} ${DEBUG}

    wait $FC_PID || true
fi
us_end=$(($(date +%s%N)/1000))

fc_time=$(grep -oE '[0-9]+ ms' "$LOGFILE" | grep -oE '[0-9]+')
us_time=$(expr $us_end - $us_start)

if [ "x$TIMEFILE" = "x" ]; then
    echo "$us_time $fc_time"
else
    echo "$us_time" "$fc_time" >> "$TIMEFILE"
fi

rm -f "$SOCK"
