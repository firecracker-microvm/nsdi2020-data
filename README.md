# Firecracker benchmarking code

This repository contains scripts and data from Firecracker benchmarks. It is designed to be largely reproducible.



## Build the pre-requisites

The `./prep` directory contains scripts and other tools required to
run the tests. Most tests uses minimal OS images build with
`linuxkit`. It also contains a slightly modified version of
firecracker and builds a new, statically linked binary for qemu.

The following should build everything:
```
cd ./prep
make -C firecracker
make -C qemu
make -C config-fc
make -C linuxkit
make -C pkg
make -C img
```

Binaries (and BIOS) are placed into `./bin` and kernel and root
filesystem images are placed into `./img`.

A working `docker` and `go` installation is required for building, but
not for running the tests and you should be able to copy the `./bin`
and `./img` directories to a target system to run tests there without
these pre-requisites.
