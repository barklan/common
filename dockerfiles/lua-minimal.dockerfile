# docker run -v /var/run/docker.sock:/var/run/docker.sock --privileged -v "$(pwd)":/workdir barklan/lua
FROM alpine:3.15.0

RUN apk update \
    && apk add --no-cache lua5.4

WORKDIR /workdir

ENTRYPOINT [ "lua5.4" ]
