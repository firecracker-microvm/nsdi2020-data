#! /bin/bash

# Script to compute IP address related things per VM ID

case $1 in
    -m) # Mask on host
        echo -n "255.255.255.252"
        ;;
    -l) # Prefix length on host
        echo -n "/30"
        ;;
    -t) # Name of Tap device
        shift; ID=$1
        echo -n "bench-tap-$ID"
        ;;
    -h) # Host IP address
        shift; ID=$1
        printf '169.254.%s.%s' $(((4 * ID + 2) / 256)) $(((4 * ID + 2) % 256))
        ;;
    -v) # VM IP address
        shift; ID=$1
        printf '169.254.%s.%s' $(((4 * ID + 1) / 256)) $(((4 * ID + 1) % 256))
        ;;
    -a) # Hardware Address (ie MAC) address in VM
        shift; ID=$1
        printf '02:FC:00:00:%02X:%02X' $((ID / 256)) $((ID % 256))
        ;;
esac
