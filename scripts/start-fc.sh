#! /bin/bash -e

# defaults
ID=$RANDOM
FC=../bin/firecracker
CORES=1
MEM=256

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
        -t) shift; TIMEFILE=$1
            ;;
        -l) shift; LOGFILE=$1
            ;;
        -s) shift; SOCK=$1
            ;;
        -d) DEBUG=$1
            ;;
    esac
    shift
done

LOGFILE="/tmp/fc-$ID.log"
SOCK="/tmp/fc-$ID.sock"
rm -f "$SOCK"

us_start=$(($(date +%s%N)/1000))

$FC --api-sock "$SOCK" 2> "$LOGFILE" &
FC_PID=$!

while [ ! -e "$SOCK" ]; do
    sleep 0.001s
done

# Configure the VM by using the config-fc Go program
../bin/config-fc -s $SOCK -k ${KERNEL} -r ${ROOTFS} -c ${CORES} -m ${MEM} ${DEBUG}

wait $FC_PID || true
us_end=$(($(date +%s%N)/1000))

fc_time=$(grep -oE '[0-9]+ ms' "$LOGFILE" | grep -oE '[0-9]+')
us_time=$(expr $us_end - $us_start)

if [ "x$TIMEFILE" = "x" ]; then
    echo "$us_time $fc_time"
else
    echo "$us_time" "$fc_time" >> "$TIMEFILE"
fi

rm "$SOCK"
