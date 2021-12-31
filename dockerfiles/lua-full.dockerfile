FROM alpine:3.15.0

RUN apk update \
    && apk add --no-cache lua5.4 lua5.4-dev \
    && apk add --no-cache --virtual .build-deps build-base git curl


RUN git clone https://github.com/keplerproject/luarocks.git \
    && cd luarocks \
    && sh ./configure \
    && make build install \
    && cd \
    && apk del --purge .build-deps \
    && rm -rf /var/cache/apk/* /tmp/* /root/.cache/luarocks

WORKDIR /app
COPY . /app

ENTRYPOINT [ "lua", "temp.lua" ]
