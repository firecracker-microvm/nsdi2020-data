FROM rust:1.37.0

COPY / /

RUN git clone https://github.com/intel/cloud-hypervisor.git
WORKDIR /cloud-hypervisor
RUN git checkout f0082fecb9fcc6485a1baa4c8559cd7562d388b9 && \
    git config --local user.email "you@example.com" && \
    git config --local user.name "Your Name" && \
    git am /patches/*

RUN cargo build --release

RUN mkdir -p /res
RUN cp target/release/cloud-hypervisor /res

ENTRYPOINT cp -r /res/* /out
