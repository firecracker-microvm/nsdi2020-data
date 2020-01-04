#! /bin/sh

DIR=../data/test

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
mkdir -p ${RAW}

PRE=${RAW}/fio-metal
echo "# Benchmark rd_iops rd_bw wr_iops wr_bw" > $OUT

for TEST in $TESTS; do
    echo "Running $TEST"
    fio --output-format=json --output=$PRE-$TEST.json --section=$TEST ../etc/fio-metal.cfg
done
