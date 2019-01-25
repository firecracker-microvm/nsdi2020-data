#! /bin/sh

SOCK=./foo.sock
KERNEL=../img/boot-time-vmlinux
ROOTFS=../img/boot-time-disk.img

../bin/firecracker --api-sock $SOCK &
FC_PID=$!

# Create VM
curl -s --unix-socket "$SOCK" -i \
     -X PUT "http://localhost/machine-config" \
     -H "accept: application/json" \
     -H "Content-Type: application/json" \
         -d "{
        \"vcpu_count\": 1,
        \"mem_size_mib\": 512,
        \"cpu_template\": \"T2\",
        \"ht_enabled\": true
    }"

# Set kernel
curl -s --unix-socket "$SOCK" -i \
     -X PUT "http://localhost/boot-source" \
     -H "accept: application/json" \
     -H "Content-Type: application/json" \
         -d "{
        \"kernel_image_path\": \"$KERNEL\",
        \"boot_args\": \"console=ttyS0 reboot=k panic=1 pci=off init=/init\"
    }"

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
    }"

# start
curl -s --unix-socket "$SOCK" -i \
     -X PUT "http://localhost/actions" \
     -H  "accept: application/json" \
     -H  "Content-Type: application/json" \
         -d "{
        \"action_type\": \"InstanceStart\"
     }"

wait $FC_PID
rm ${SOCK}
