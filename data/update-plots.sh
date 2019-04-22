#!/bin/sh

DIRS="m5d.metal rn.haswell rn.nehalem"

for DIR in $DIRS; do
    gnuplot -e "base='$DIR'" gnuplot/boot-serial-all.gpl
    gnuplot -e "base='$DIR'" gnuplot/boot-serial.gpl
    gnuplot -e "base='$DIR'" gnuplot/boot-parallel.gpl
done
