ARG ARCH=
FROM ${ARCH}alpine as prepare

ENV XMRIG_VERSION=v6.19.2
ENV XMRIG_URL=https://github.com/xmrig/xmrig.git
# 1. apk add git make cmake libstdc++ gcc g++ automake libtool autoconf linux-headers
# 2. git clone https://github.com/xmrig/xmrig.git
# 3. mkdir xmrig/build
# 4. cd xmrig/scripts && ./build_deps.sh && cd ../build
# 5. cmake .. -DXMRIG_DEPS=scripts/deps -DBUILD_STATIC=ON
# 6. make -j$(nproc)
RUN echo 'https://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories
RUN apk add git make cmake libstdc++ gcc g++ automake libtool autoconf \
    linux-headers hwloc-dev libuv-dev openssl-dev

RUN git clone ${XMRIG_URL} /xmrig && \
    cd /xmrig && git checkout ${XMRIG_VERSION}

WORKDIR /xmrig/scripts
RUN mkdir -p /xmrig/build && chmod 755 *.sh\
    ./build_deps.sh
WORKDIR /xmrig/build
RUN cmake .. -DXMRIG_DEPS=scripts/deps -DBUILD_STATIC=ON -DHWLOC_LIBRARY=/usr/lib/libhwloc.so \
    -DWITH_OPENCL=OFF -DWITH_CUDA=OFF && \
    make -j$(nproc) 

ADD config.json /xmrig/build/conf/

FROM ${ARCH}alpine

ARG BUILD_DATE
ARG VCS_REF

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF

COPY --from=prepare /xmrig/build/xmrig /xmrig/xmrig

ADD start.sh /

ENTRYPOINT [ "/start.sh" ]
