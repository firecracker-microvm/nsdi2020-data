# Firecracker benchmarking code

This repository contains all the scripts, source code, and data used for our NSDI 2020 paper on "Firecracker: Lightweight Virtualization for Serverless Applications".


## Build the pre-requisites

The `./prep` directory contains scripts and other tools required to
run the tests. Most tests uses minimal OS images build with
`linuxkit`. It also contains a slightly modified version of
firecracker and builds a new, statically linked binary for qemu.

The following should build everything:
```
cd ./prep
make
```

Binaries (and BIOS) are placed into `./bin` and kernel and root
filesystem images are placed into `./img`.

A working `docker` and `go` installation is required for building, but
not for running the tests and you should be able to copy the `./bin`
and `./img` directories to a target system to run tests there without
these pre-requisites.

## Prepare the host

This assumes you are running on a Ubuntu system.

Install some host side utilities

```
sudo apt update
sudo apt install -y \
    iperf3 \
    jq \
    hwloc-nox
    numactl \
```

## Running the tests

There are a bunch of scripts in `./scripts`. They assume you are in the `./scripts` directory when you run them.

```
cd ./scripts
./run-all.sh ../data/test
```

configures the host system and runs most of the tests. Test results are stored in the directory provided.
