FROM registry.cn-shanghai.aliyuncs.com/heltec-org/etl-deps-compiler as builder

# Add our code
COPY . .

RUN ./rebar3 as docker_etl tar
RUN mkdir -p /opt/docker
RUN tar -zxvf _build/docker_etl/rel/*/*.tar.gz -C /opt/docker
RUN mkdir -p /opt/docker/update

FROM alpine as runner
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

RUN apk add --no-cache --update ncurses dbus gmp libsodium gcc
RUN ulimit -n 64000

WORKDIR /opt/etl

ENV COOKIE=etl \
    # Write files generated during startup to /tmp
    RELX_OUT_FILE_PATH=/tmp \
    # add miner to path, for easy interactions
    PATH=$PATH:/opt/etl/bin

COPY --from=builder /opt/docker /opt/etl
COPY scripts/start.sh /opt/etl/scripts/start.sh
COPY scripts/reset.sh /opt/etl/scripts/reset.sh

# ENTRYPOINT ["/opt/etl/bin/blockchain_etl"]
# CMD ["foreground"]

ENTRYPOINT ["/bin/sh"]
# CMD "/opt/etl/bin/blockchain_etl foreground"
