FROM linuxkit/alpine:4768505d40f23e198011b6f2c796f985fe50ec39 AS kernel-build
RUN apk add \
    argp-standalone \
    bash \
    bc \
    binutils-dev \
    bison \
    build-base \
    curl \
    flex \
    gmp-dev \
    installkernel \
    kmod \
    libarchive-tools \
    libelf-dev \
    linux-headers \
    mpc1-dev \
    mpfr-dev \
    ncurses-dev \
    openssl \
    openssl-dev \
    perl \
    sed \
    xz \
    xz-dev \
    zlib-dev

RUN mkdir /out

ENV KERNEL_VERSION=4.14.94
ENV KERNEL_SOURCE=https://www.kernel.org/pub/linux/kernel/v4.x/linux-${KERNEL_VERSION}.tar.xz
RUN curl -fsSLO ${KERNEL_SOURCE} && \
    bsdtar xf linux-${KERNEL_VERSION}.tar.xz && \
    mv linux-${KERNEL_VERSION} /linux
COPY /microvm-kernel-config /linux/.config

WORKDIR /linux

# Configure and compile the kernel
# (individual run commands for easier debug)
RUN make oldconfig
RUN make -j "$(getconf _NPROCESSORS_ONLN)" KCFLAGS="-fno-pie"
RUN cp arch/x86_64/boot/bzImage /out/kernel
RUN cp System.map /out
RUN make -j "$(getconf _NPROCESSORS_ONLN)" KCFLAGS="-fno-pie" INSTALL_MOD_PATH=/tmp/kernel-modules modules_install
RUN cd /tmp/kernel-modules && bsdtar cf /out/kernel.tar .

# Package it up
FROM scratch
ENTRYPOINT []
CMD []
WORKDIR /
COPY --from=kernel-build /out/* /

