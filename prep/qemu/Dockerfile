FROM ubuntu:18.04

RUN apt update && \
    apt install -y \
        build-essential \
        git \
        libtool \
        libpixman-1-dev \
        libglib2.0-dev \
        pkg-config \
        python \
        libc6-dev-i386

RUN git clone git://git.qemu.org/qemu.git && \
    cd qemu && \
    git checkout v4.2.0

WORKDIR /qemu

RUN ./configure \
        --target-list=x86_64-softmmu \
        --static \
        --disable-attr \
        --disable-blobs \
        --disable-bluez \
        --disable-bochs \
        --disable-brlapi \
        --disable-bzip2 \
        --disable-cap-ng \
        --disable-cloop \
        --disable-curl \
        --disable-curses \
        --disable-dmg \
        --disable-fdt \
        --disable-glusterfs \
        --disable-gnutls \
        --disable-gtk \
        --disable-guest-agent \
        --disable-libiscsi \
        --disable-libnfs \
        --disable-libssh \
        --disable-libusb \
        --disable-live-block-migration \
        --disable-lzo \
        --disable-modules \
        --disable-netmap \
        --disable-nettle \
        --disable-opengl \
        --disable-opengl \
        --disable-parallels \
        --disable-qcow1 \
        --disable-qed \
        --disable-qom-cast-debug \
        --disable-rbd \
        --disable-rdma \
        --disable-rdma \
        --disable-replication \
        --disable-sdl \
        --disable-seccomp \
        --disable-sheepdog \
        --disable-slirp \
        --disable-snappy \
        --disable-spice \
        --disable-tpm \
        --disable-usb-redir \
        --disable-vde \
        --disable-vdi \
        --disable-virtfs \
        --disable-vnc \
        --disable-vnc-jpeg \
        --disable-vnc-png \
        --disable-vnc-sasl \
        --disable-vte \
        --disable-vvfat \
        --disable-xen

RUN make -j "$(getconf _NPROCESSORS_ONLN)"

RUN apt install -y seabios

RUN mkdir -p /res/bios && \
    cp x86_64-softmmu/qemu-system-x86_64 /res && \
    cp -r /usr/share/seabios/* /res/bios && \
    cp pc-bios/efi-e1000.rom /res/bios && \
    cp pc-bios/efi-virtio.rom /res/bios

RUN cd / && \
    git clone https://github.com/bonzini/qboot && \
    cd qboot && \
       git checkout 94d3b1b5d1fc30bd7b63af9d07cb8db89a5f4868

WORKDIR /qboot

RUN make && \
    cp bios.bin /res/bios/qboot.bin

ENTRYPOINT cp -r /res/* /out
