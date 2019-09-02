#! /bin/bash

set -x

# Make sure the key is nio world readable
# can cause silent failures in a number of tests
chmod 0600 ../etc/ssh-bench.key

## Sets up a system
## Mostly copied/adjusted from:
## https://github.com/firecracker-microvm/firecracker-demo

# Number of Tap devices to create
NUM_TAPS="${1:-1}"

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

##
## Configure the host
##
## - Configure packet forwarding
## - Avoid "nf_conntrack: table full, dropping packet"
## - Avoid "neighbour: arp_cache: neighbor table overflow!"
##
modprobe kvm_intel
sysctl -w net.ipv4.conf.all.forwarding=1

sysctl -w net.ipv4.netfilter.ip_conntrack_max=99999999
sysctl -w net.nf_conntrack_max=99999999
sysctl -w net.netfilter.nf_conntrack_max=99999999

sysctl -w net.ipv4.neigh.default.gc_thresh1=1024
sysctl -w net.ipv4.neigh.default.gc_thresh2=2048
sysctl -w net.ipv4.neigh.default.gc_thresh3=4096

##
## Create and configure network taps (delete existing ones)
##

MASK=$(./util_ipam.sh -m)
PREFIX_LEN=$(./util_ipam.sh -l)

for ((i=0; i<NUM_TAPS; i++)); do

    DEV=$(./util_ipam.sh -t $i)
    IP=$(./util_ipam.sh -h $i)

    ip link del "$DEV" 2> /dev/null || true
    ip tuntap add dev "$DEV" mode tap

    sysctl -w net.ipv4.conf.${DEV}.proxy_arp=1 > /dev/null
    sysctl -w net.ipv6.conf.${DEV}.disable_ipv6=1 > /dev/null

    ip addr add "${IP}${PREFIX_LEN}" dev "$DEV"
    ip link set dev "$DEV" up
done
