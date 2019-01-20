FROM alpine:3.8 AS extract

ENV DEB_URLS="https://mirrors.edge.kernel.org/ubuntu/pool/main/l/linux/linux-image-4.15.0-44-generic_4.15.0-44.47_i386.deb \
              https://mirrors.edge.kernel.org/ubuntu/pool/main/l/linux/linux-modules-4.15.0-44-generic_4.15.0-44.47_amd64.deb \
              https://mirrors.edge.kernel.org/ubuntu/pool/main/l/linux/linux-modules-extra-4.15.0-44-generic_4.15.0-44.47_amd64.deb \
              https://mirrors.edge.kernel.org/ubuntu/pool/main/l/linux/linux-headers-4.15.0-44_4.15.0-44.47_all.deb \
              https://mirrors.edge.kernel.org/ubuntu/pool/main/l/linux/linux-headers-4.15.0-44-generic_4.15.0-44.47_amd64.deb \
              "

RUN apk add --no-cache curl dpkg tar && true
WORKDIR /deb
RUN mkdir extract
RUN for url in ${DEB_URLS}; do \
        echo "Extracting: $url"; \
        curl -fsSL -o dl.deb $url && \
        dpkg-deb -x dl.deb . ;\
    done

RUN for d in lib/modules/*; do depmod -b . $(basename $d); done

RUN mkdir /out
RUN cp -a boot/vmlinuz-* /out/kernel
RUN cp -a boot/config-* /out/kernel_config
RUN cp -a boot/System.map-* /out/System.map
RUN tar cf /out/kernel.tar lib
RUN tar cf /out/kernel-dev.tar usr || true

FROM scratch
WORKDIR /
ENTRYPOINT []
CMD []
COPY --from=extract /out/* /
