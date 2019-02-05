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
        -d) DEBUG=yes
            ;;
    esac
    shift
done

LOGFILE="/tmp/fc-$ID.log"
SOCK="/tmp/fc-$ID.sock"
rm -f "$SOCK"

CURL=(curl --silent --show-error --header Content-Type:application/json --unix-socket "${SOCK}" --write-out "HTTP %{http_code}")

curl_put() {
    local URL_PATH="$1"
    local OUTPUT RC
    OUTPUT="$("${CURL[@]}" -X PUT --data @- "http://localhost/${URL_PATH#/}" 2>&1)"
    RC="$?"
    if [ "$RC" -ne 0 ]; then
        echo "Error: curl PUT ${URL_PATH} failed with exit code $RC, output:"
        echo "$OUTPUT"
        return 1
    fi
    # Error if output doesn't end with "HTTP 2xx"
    if [[ "$OUTPUT" != *HTTP\ 2[0-9][0-9] ]]; then
        echo "Error: curl PUT ${URL_PATH} failed with non-2xx HTTP status code, output:"
        echo "$OUTPUT"
        return 1
    fi
}

us_start=$(($(date +%s%N)/1000))

$FC --api-sock "$SOCK" 2> "$LOGFILE" &
FC_PID=$!

while [ ! -e "$SOCK" ]; do
    sleep 0.001s
done

# This script provides a full-featured bash implementation, and a fast Go implementation. Set
# this to 'go' to get the fast one.
CONFIG_IMPL=go

if [ "$CONFIG_IMPL" = "go" ]; then
    # Configure the VM by using the config-fc Go program
    ./config-fc $SOCK
else
    # Configure the VM by calling the API with 'curl'
# Create VM
curl_put '/machine-config' <<EOF
{   
    "vcpu_count": $CORES,
    "mem_size_mib": $MEM,
    "cpu_template": "T2",
    "ht_enabled": true
}
EOF

# Kernel
KERNEL_ARGS="panic=1 pci=off reboot=k tsc=reliable ipv6.disable=1 init=/init"
if [ "x$DEBUG" = "x" ]; then
    KERNEL_ARGS="$KERNEL_ARGS quiet 8250.nr_uarts=0"
else
    KERNEL_ARGS="$KERNEL_ARGS console=ttyS0"
fi
curl_put '/boot-source' <<EOF
{
  "kernel_image_path": "$KERNEL",
  "boot_args": "$KERNEL_ARGS"
}
EOF

# set rootfs
curl_put '/drives/1' <<EOF
{
  "drive_id": "1",
  "path_on_host": "$ROOTFS",
  "is_root_device": true,
  "is_read_only": true
}
EOF

curl_put '/actions' <<EOF
{
    "action_type": "InstanceStart"
}
EOF

fi 

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
