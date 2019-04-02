FROM ubuntu:16.04

RUN apt update && \
    apt install -y \
        build-essential \
        git \
        libtool \
        libpixman-1-dev \
        libglib2.0-dev \
        pkg-config \
        python

RUN git clone git://github.com/intel/qemu-lite.git && \
    cd qemu-lite && \
    git checkout qemu-2.7-lite

WORKDIR /qemu-lite

RUN ./configure \
        --target-list=x86_64-softmmu \
        --static \
        --disable-attr \
        --disable-blobs \
        --disable-bluez \
        --disable-brlapi \
        --disable-bzip2 \
        --disable-cap-ng \
        --disable-curl \
        --disable-curses \
        --disable-fdt \
        --disable-glusterfs \
        --disable-gnutls \
        --disable-gtk \
        --disable-guest-agent \
        --disable-libiscsi \
        --disable-libnfs \
        --disable-libssh2 \
        --disable-libusb \
        --disable-lzo \
        --disable-modules \
        --disable-netmap \
        --disable-nettle \
        --disable-opengl \
        --disable-opengl \
        --disable-qom-cast-debug \
        --disable-rbd \
        --disable-rdma \
        --disable-rdma \
        --disable-sdl \
        --disable-seccomp \
        --disable-slirp \
        --disable-snappy \
        --disable-spice \
        --disable-tpm \
        --disable-usb-redir \
        --disable-vde \
        --disable-virtfs \
        --disable-vnc \
        --disable-vnc-jpeg \
        --disable-vnc-png \
        --disable-vnc-sasl \
        --disable-vte \
        --disable-xen

RUN make -j "$(getconf _NPROCESSORS_ONLN)"

RUN mkdir -p /res && \
        cp x86_64-softmmu/qemu-system-x86_64 /res/qemu-lite-system-x86_64

ENTRYPOINT cp -r /res/* /out
