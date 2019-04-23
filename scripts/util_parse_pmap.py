#! /usr/bin/env python3

# A skanky script to parse a 'pmap' output
# Prints the size of the executable (including shared library code) and data

import sys
import os
import collections

if len(sys.argv) != 2:
    sys.exit("Please provide a input file name")

infn = sys.argv[1]

# Data is a list of Counters
data = []
num_cols = 0

executable = 0
data = 0
ro_data = 0

with open(infn, 'r') as f:
    for line in f:
        l = line.strip()
        if len(l) == 0:
            continue
        elems = l.split()

        if len(elems) < 5:
            continue
        if elems[0].startswith("-"):
            continue
        if elems[0].startswith("total"):
            continue
        if elems[0].endswith(":"):
            continue
        if elems[0] == "Address":
            continue

        mode = elems[4]
        sz = int(elems[1])

        if mode.startswith("r-x"):
            executable += sz
        elif mode.startswith("rw"):
            data += sz
        elif mode.startswith("r--"):
            ro_data += sz
        elif mode == "-----":
            continue
        else:
            print("Unexpected mode:")
            print(l)
            sys.exit(1)

sys.stdout.write("%d %d" % (executable, data))
