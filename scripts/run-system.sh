#! /bin/sh
# A script to gather some system information

DIR=../data/
while [ $# -gt 0 ]; do
    case $1 in
        -d) shift; DIR=$1
            ;;
    esac
    shift
done

mkdir -p ${DIR}

date > ${DIR}/sys_date.txt
cat /proc/cpuinfo > ${DIR}/sys_cpuinfo.txt
cat /proc/cmdline > ${DIR}/sys_kernel-cmdline.txt
free > ${DIR}/sys_memory.txt
cat /proc/meminfo > ${DIR}/sys_meminfo.txt
numactl --hardware > ${DIR}/sys_numactl.txt
lstopo-no-graphics -c > ${DIR}/sys_lstopo.txt
uname -a > ${DIR}/sys_uname.txt
lsb_release -a > ${DIR}/sys_lsb_release.txt
dmidecode > ${DIR}/sys_dmidecode.txt
lspci -vvv > ${DIR}/sys_lspci.txt
dmesg > ${DIR}/sys_dmesg.txt

../bin/qemu-system-x86_64 --version > ${DIR}/sys_qemu.txt
../bin/firecracker --version  > ${DIR}/sys_firecracker.txt
