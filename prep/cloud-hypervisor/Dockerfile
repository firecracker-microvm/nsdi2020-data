FROM rust:1.40.0

COPY / /

RUN git clone https://github.com/intel/cloud-hypervisor.git
WORKDIR /cloud-hypervisor
RUN git checkout 38c0d328c2b79662e0c146c06a23d6d8e7d35c64 && \
    git config --local user.email "you@example.com" && \
    git config --local user.name "Your Name" && \
    git am /patches/*

RUN cargo build --release

RUN mkdir -p /res
RUN cp target/release/cloud-hypervisor /res

ENTRYPOINT cp -r /res/* /out
