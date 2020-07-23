FROM alpine:3.12.0

ARG DOCKER_CLI_VERSION="19.03.9"
ENV DOWNLOAD_URL="https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_CLI_VERSION.tgz"

# install docker client
RUN apk --update add curl \
    && mkdir -p /tmp/download \
    && curl -L $DOWNLOAD_URL | tar -xz -C /tmp/download \
    && mv /tmp/download/docker/docker /usr/local/bin/ \
    && rm -rf /tmp/download \
    && apk del curl \
    && rm -rf /var/cache/apk/*

# install bash
RUN apk --update add bash

COPY ./entrypoint.sh /entrypoint.sh
WORKDIR /mnt
ENTRYPOINT [ "/entrypoint.sh" ]
