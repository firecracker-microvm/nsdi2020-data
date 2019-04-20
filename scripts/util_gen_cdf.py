#! /usr/bin/env python3

# A somewhat skanky script to convert the raw data files generated from the
# boot time scripts into a data file with a CDF usable from gnuplot. A data
# file which contains multiple columns it will generate a data file with
# multiple sections.

import sys
import os
import collections

if len(sys.argv) != 3:
    sys.exit("Please provide a input and output file name")

infn = sys.argv[1]
outfn = sys.argv[2]

# Data is a list of Counters
data = []
num_cols = 0

with open(infn, 'r') as f:
    for line in f:
        l = line.strip()
        if len(l) == 0 or l[0] == "#":
            continue
        elems = l.split()

        # create initial data structure (or sanity check)
        if len(data) == 0:
            for _ in elems:
                data.append(collections.Counter())
            num_cols = len(elems)
        else:
            if num_cols != len(elems):
                sys.exit("Odd data file: %d != %d", len(data), len(elems))

        for i in range(num_cols):
            n = int(elems[i])
            data[i][n] += 1

totals = []
for i in range(num_cols):
    totals.append(sum(data[i].values()))

with open(outfn, 'w') as f:
    for i in range(num_cols):
        first = True
        s = 0.0
        for item in sorted(data[i].items()):
            t = item[0]
            c = item[1]
            if first:
                f.write("%d %f\n" % (t, s))
                first = False
            s += c/float(totals[i])
            f.write("%d %f\n" % (t, s))
        f.write("\n\n")
