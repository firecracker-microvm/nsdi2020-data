#! /bin/sh
# A script to gather some system information

DIR=../data/test
while [ $# -gt 0 ]; do
    case $1 in
        -d) shift; DIR=$1
            ;;
    esac
    shift
done


SYS=${DIR}/sys
mkdir -p ${SYS}

date                     > ${SYS}/sys_date.txt
cat /proc/cpuinfo        > ${SYS}/sys_cpuinfo.txt
cat /proc/cmdline        > ${SYS}/sys_kernel-cmdline.txt
free                     > ${SYS}/sys_memory.txt
cat /proc/meminfo        > ${SYS}/sys_meminfo.txt
uname -a                 > ${SYS}/sys_uname.txt
lsb_release -a           > ${SYS}/sys_lsb_release.txt
numactl --hardware       > ${SYS}/sys_numactl.txt
lstopo-no-graphics -c -v > ${SYS}/sys_lstopo.txt
lspci -xxxx              > ${SYS}/sys_lspci-xxxx.txt
lspci -vvv -nn           > ${SYS}/sys_lspci.txt
dmidecode                > ${SYS}/sys_dmidecode.txt
dmesg                    > ${SYS}/sys_dmesg.txt

../bin/qemu-system-x86_64 --version > ${SYS}/sys_qemu.txt
../bin/firecracker --version        > ${SYS}/sys_firecracker.txt
../bin/linuxkit version             > ${SYS}/sys_linuxkit.txt
