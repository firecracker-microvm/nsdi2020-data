#! /bin/sh

DIR=../data/

while [ $# -gt 0 ]; do
    case $1 in
        -d) shift; DIR=$1
            ;;
    esac
    shift
done

process() {
    local bm=$1
    local in=$2
    local out=$3

    local r_iops=$(cat $in | jq '.jobs[0].read.iops')
    local r_bw=$(cat $in | jq '.jobs[0].read.bw')
    local w_iops=$(cat $in | jq '.jobs[0].write.iops')
    local w_bw=$(cat $in | jq '.jobs[0].write.bw')

    echo "$bm $r_iops $r_bw $w_iops $w_bw" >> $out
}


TESTS="rand-read-4k rand-read-4k-qd1"
TESTS="$TESTS rand-write-4k rand-write-4k-qd1"
TESTS="$TESTS rand-read-128k rand-read-128k-qd1"
TESTS="$TESTS rand-write-128k rand-write-128k-qd1"

RAW=${DIR}/raw
mkdir -p ${RAW}

PRE=${RAW}/fio-metal
OUT=${DIR}/fio-metal.dat
echo "# Benchmark rd_iops rd_bw wr_iops wr_bw" > $OUT

for TEST in $TESTS; do
    echo "Running $TEST"
    fio --output-format=json --output=$PRE-$TEST.json --section=$TEST ../etc/fio-metal.cfg
    process $TEST ${PRE}-${TEST}.json $OUT
done
