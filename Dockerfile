FROM bash:5.0
COPY ./entrypoint.sh /entrypoint.sh
WORKDIR /mnt
ENTRYPOINT [ "/entrypoint.sh" ]