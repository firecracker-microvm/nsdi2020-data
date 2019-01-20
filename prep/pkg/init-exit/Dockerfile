FROM linuxkit/alpine:4768505d40f23e198011b6f2c796f985fe50ec39 AS build
RUN apk add gcc musl-dev
COPY /init.c .
RUN mkdir /out && \
    gcc -O -static -Wall -Werror -o /out/init init.c

# Package it up
FROM scratch
ENTRYPOINT []
CMD []
WORKDIR /
COPY --from=build /out/* /

