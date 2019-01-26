FROM ubuntu:18.04

RUN apt update && \
    apt install -y \
        build-essential \
        git \
        libtool \
        libpixman-1-dev \
        libglib2.0-dev \
        pkg-config \
        python

RUN git clone git://git.qemu.org/qemu.git && \
    cd qemu && \
    git checkout v3.1.0

WORKDIR /qemu

RUN ./configure \
    --target-list=x86_64-softmmu \
    --static \
    --disable-slirp \
    --disable-blobs \
    --disable-modules \
    --disable-gnutls \
    --disable-nettle \
    --disable-sdl \
    --disable-gtk \
    --disable-vte \
    --disable-vnc \
    --disable-virtfs \
    --disable-opengl \
    --disable-xen \
    --disable-fdt \
    --disable-bluez \
    --disable-rdma \
    --disable-vde \
    --disable-netmap \
    --disable-cap-ng \
    --disable-spice \
    --disable-libnfs \
    --disable-bochs \
    --disable-dmg \
    --disable-vdi \
    --disable-parallels \
    --disable-sheepdog \
    --disable-replication \
    --disable-tpm \
    --disable-qom-cast-debug \
    --disable-live-block-migration \
    --disable-qcow1 \
    --disable-vvfat \
    --disable-qed \
    --disable-cloop \
    --disable-guest-agent

RUN make -j "$(getconf _NPROCESSORS_ONLN)"

RUN mkdir -p /res/bios && \
    cp x86_64-softmmu/qemu-system-x86_64 /res && \
    cp pc-bios/* /res/bios || true

ENTRYPOINT cp -r /res/* /out
