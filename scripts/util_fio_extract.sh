#! /bin/sh


while [ $# -gt 0 ]; do
    case $1 in
        -d) shift; DIR=$1
            ;;
    esac
    shift
done

TESTS="rand-read-4k rand-read-4k-qd1"
TESTS="$TESTS rand-write-4k rand-write-4k-qd1"
TESTS="$TESTS rand-read-128k rand-read-128k-qd1"
TESTS="$TESTS rand-write-128k rand-write-128k-qd1"

RAW=${DIR}/raw

process() {
    local bm=$1
    local in=$2
    local out=$3

    local r_iops=$(cat $in | jq '.jobs[0].read.iops')
    local r_bw=$(cat $in | jq '.jobs[0].read.bw')
    local r_lat99=$(cat $in | jq '.jobs[0].read.clat_ns.percentile["99.000000"]')
    local w_iops=$(cat $in | jq '.jobs[0].write.iops')
    local w_bw=$(cat $in | jq '.jobs[0].write.bw')
    local w_lat99=$(cat $in | jq '.jobs[0].write.clat_ns.percentile["99.000000"]')

    echo "$bm $r_iops $r_bw $r_lat99 $w_iops $w_bw $w_lat99" >> $out
}


PRE=fio-fc
OUT=${DIR}/${PRE}.dat
echo "# Benchmark rd_iops rd_bw rd_lat99 wr_iops wr_bw wr_lat99" > $OUT
for TEST in $TESTS; do
    process $TEST ${RAW}/${PRE}-${TEST}.json $OUT
done

PRE=fio-chv
OUT=${DIR}/${PRE}.dat
echo "# Benchmark rd_iops rd_bw rd_lat99 wr_iops wr_bw wr_lat99" > $OUT
for TEST in $TESTS; do
    process $TEST ${RAW}/${PRE}-${TEST}.json $OUT
done

PRE=fio-qemu
OUT=${DIR}/${PRE}.dat
echo "# Benchmark rd_iops rd_bw rd_lat99 wr_iops wr_bw wr_lat99" > $OUT
for TEST in $TESTS; do
    process $TEST ${RAW}/${PRE}-${TEST}.json $OUT
done

PRE=fio-metal
OUT=${DIR}/${PRE}.dat
echo "# Benchmark rd_iops rd_bw rd_lat99 wr_iops wr_bw wr_lat99" > $OUT
for TEST in $TESTS; do
    process $TEST ${RAW}/${PRE}-${TEST}.json $OUT
done
