#! /bin/bash

rand=$RANDOM
FC=../bin/firecracker
LOGFILE=./fc-$rand.log
SOCK=./fc-$rand.sock
CORES=1
MEM=256

while [ $# -gt 0 ]; do
    case $1 in
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
        -d) DEBUG=yes
            ;;
    esac
    shift
done

# TODO: Enable serial console output on debug

us_start=$(($(date +%s%N)/1000))
$FC --api-sock $SOCK 2> ${LOGFILE} &
FC_PID=$!

# Create VM
curl -s --unix-socket "$SOCK" -i \
     -X PUT "http://localhost/machine-config" \
     -H "accept: application/json" \
     -H "Content-Type: application/json" \
         -d "{
        \"vcpu_count\": $CORES,
        \"mem_size_mib\": $MEM,
        \"cpu_template\": \"T2\",
        \"ht_enabled\": true
    }" > /dev/null

# Set kernel
curl -s --unix-socket "$SOCK" -i \
     -X PUT "http://localhost/boot-source" \
     -H "accept: application/json" \
     -H "Content-Type: application/json" \
         -d "{
        \"kernel_image_path\": \"$KERNEL\",
        \"boot_args\": \"reboot=k panic=1 pci=off init=/init\"
    }" > /dev/null

# set rootfs
curl -s --unix-socket "$SOCK" -i \
     -X PUT "http://localhost/drives/rootfs" \
     -H "accept: application/json" \
     -H "Content-Type: application/json" \
         -d "{
        \"drive_id\": \"rootfs\",
        \"path_on_host\": \"$ROOTFS\",
        \"is_root_device\": true,
        \"is_read_only\": false
    }" > /dev/null

# start
curl -s --unix-socket "$SOCK" -i \
     -X PUT "http://localhost/actions" \
     -H  "accept: application/json" \
     -H  "Content-Type: application/json" \
         -d "{
        \"action_type\": \"InstanceStart\"
     }" > /dev/null

wait $FC_PID
us_end=$(($(date +%s%N)/1000))

fc_time=$(grep -oE '[0-9]+ ms' $LOGFILE | grep -oE '[0-9]+')
us_time=$(expr $us_end - $us_start)

if [ "x$TIMEFILE" = "x" ]; then
    echo $us_time $fc_time
else
    echo $us_time $fc_time >> $TIMEFILE
fi

rm ${SOCK}
