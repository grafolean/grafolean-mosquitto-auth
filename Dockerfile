FROM debian:buster-slim

ENV MOSQUITTO_VERSION=1.6.12
ENV MOSQUITTO_GO_AUTH_VERSION=1.3.2

RUN \
    apt-get update && \
    apt-get install -y -q --no-install-recommends libwebsockets8 libc-ares2 openssl uuid && \
    apt-get install -y -q --no-install-recommends build-essential git wget ca-certificates golang-go libwebsockets-dev libc-ares-dev uuid-dev && \
    \
    groupadd mosquitto && \
    mkdir -p /var/log/mosquitto/ /var/lib/mosquitto/ && \
    useradd -s /sbin/nologin mosquitto -g mosquitto -d /var/lib/mosquitto && \
    \
    echo "BUILDING mosquitto $MOSQUITTO_VERSION:" && \
    mkdir /build && \
    cd /build && \
    wget "https://mosquitto.org/files/source/mosquitto-$MOSQUITTO_VERSION.tar.gz" && \
    tar -xvzf "mosquitto-$MOSQUITTO_VERSION.tar.gz" && \
    cd "mosquitto-$MOSQUITTO_VERSION" && \
    make WITH_SRV=yes WITH_ADNS=no WITH_DOCS=no WITH_MEMORY_TRACKING=no WITH_TLS_PSK=no WITH_WEBSOCKETS=yes WITH_PERSISTENCE=no install && \
    \
    echo "BUILDING mosquitto-go-auth:" && \
    cd /build && \
    wget "https://github.com/iegomez/mosquitto-go-auth/archive/$MOSQUITTO_GO_AUTH_VERSION.tar.gz" -O mosquitto-go-auth.tar.gz && \
    tar -xvzf mosquitto-go-auth.tar.gz && \
    cd "mosquitto-go-auth-$MOSQUITTO_GO_AUTH_VERSION" && \
    export CGO_CFLAGS="-I/usr/local/include -fPIC" && \
    export CGO_LDFLAGS="-shared" && \
    make && \
    install -s -m755 go-auth.so /usr/local/lib/ && \
    \
    rm -rf /build/ && \
    apt-get purge -y build-essential git wget ca-certificates golang-go libwebsockets-dev libc-ares-dev uuid-dev && \
    apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/ /var/cache/apt/* /tmp/* && \
    rm -rf /root/go/* /root/.cache

ADD mosquitto.conf /etc/mosquitto/mosquitto.conf

EXPOSE 1883
EXPOSE 9883

USER mosquitto

ENTRYPOINT ["mosquitto", "-c", "/etc/mosquitto/mosquitto.conf"]
