FROM linuxkit/alpine:86cd4f51b49fb9a078b50201d892a3c7973d48ec AS mirror

RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/
RUN apk add --no-cache --initdb -p /out \
    alpine-baselayout \
    apk-tools \
    busybox \
    ca-certificates \
    iperf3 \
    musl \
    openssh-server \
    tini \
    util-linux \
    && true
RUN mv /out/etc/apk/repositories.upstream /out/etc/apk/repositories

# Build fio (no alpine package)
# Based on https://github.com/dmonakhov/docker-image--alpine-fio/blob/guilt/master/Dockerfile
FROM alpine:3.9 AS fio-build
RUN apk --no-cache add \
    make \
    alpine-sdk \
    zlib-dev \
    libaio-dev \
    linux-headers \
    coreutils
RUN git clone https://github.com/axboe/fio && \
    cd fio && \
    git checkout fio-3.13 && \
    ./configure --build-static && \
    make -j $(nproc) && \
    mkdir /out && \
    cp ./fio /out

FROM scratch
ENTRYPOINT []
WORKDIR /
COPY --from=mirror /out/ /
COPY etc/ /etc/
COPY usr/ /usr/
COPY --from=fio-build /out/fio /usr/bin/fio
RUN mkdir -p /etc/ssh /root/.ssh && chmod 0700 /root/.ssh
CMD ["/sbin/tini", "/usr/bin/ssh.sh"]
