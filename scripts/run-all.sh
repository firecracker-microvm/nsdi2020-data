#! /bin/sh

DIR=$1

if [ -z $DIR ]; then
   echo "Please specify a directory for the data"
   exit 1
fi

sudo ./00_setup_host.sh

sudo ./run-system.sh -d $DIR

./run-boot-serial.sh   -d $DIR
./run-boot-net.sh      -d $DIR
./run-boot-parallel.sh -d $DIR -p 10
./run-boot-parallel.sh -d $DIR -p 50
./run-boot-parallel.sh -d $DIR -p 100
./run-boot-kernel.sh   -d $DIR

./run-mem.sh           -d $DIR
./run-net.sh           -d $DIR
