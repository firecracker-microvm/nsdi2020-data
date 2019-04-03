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

# virt-x86-4.0-rc0
RUN git clone https://github.com/intel/nemu.git && \
    cd nemu && \
    git checkout cf191a1d18c67b304886e4c904a18973ef35aa20

WORKDIR /nemu

# Based on tools/build_x86_64_virt.sh
# except:
# - disable-cap-ng
# - disable-rbd
# - disable-virtfs
# - static
RUN ./configure \
        --target-list=x86_64_virt-softmmu \
        --static \
        --extra-cflags="-O3 -fno-semantic-interposition -falign-functions=32 -D_FORTIFY_SOURCE=2 -fPIE" \
        --disable-fdt \
        --disable-libiscsi \
        --disable-libnfs \
        --disable-libssh2 \
        --disable-linux-aio \
        --disable-lzo \
        --disable-bzip2 \
        --disable-modules \
        --disable-netmap \
        --disable-qom-cast-debug \
        --disable-seccomp \
        --disable-snappy \
        --disable-tcmalloc \
        --disable-tools \
        --disable-tpm \
        --disable-virtfs \
        --disable-tcg \
        --disable-capstone \
        --disable-xen \
        --disable-xen-pci-passthrough \
        --disable-wdt \
        --disable-audio \
        --disable-bluetooth \
        --disable-usb-redir \
        --disable-spice \
        --disable-vnc \
        --disable-whpx \
        --disable-hvf \
        --disable-gtk \
        --disable-vte \
        --disable-sdl \
        --disable-rdma \
        --disable-vxhs \
        --disable-vvfat \
        --disable-parallels \
        --disable-dmg \
        --disable-gnutls \
        --disable-nettle \
        --enable-attr \
        --enable-kvm \
        --enable-vhost-crypto \
        --enable-vhost-net \
        --enable-vhost-scsi \
        --enable-vhost-user \
        --enable-vhost-vsock \
        --disable-cap-ng \
        --disable-rbd \
        --disable-virtfs

RUN make -j "$(getconf _NPROCESSORS_ONLN)"

RUN cd / && \
        apt update && \
        apt install -y curl && \
        OVMF_URL=$(curl --silent https://api.github.com/repos/intel/ovmf-virt/releases/latest | grep -o https://.*OVMF.fd) && \
        curl -fsSLO $OVMF_URL

RUN mkdir -p /res/bios && \
        cp x86_64_virt-softmmu/qemu-system-x86_64_virt /res/nemu-system-x86_64 && \
        cp /OVMF.fd /res/bios

ENTRYPOINT cp -r /res/* /out
