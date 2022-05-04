ARG DOCKER_IMAGE_PREFIX=
FROM ${DOCKER_IMAGE_PREFIX}archlinux:base

ARG BUILDKIT_INLINE_CACHE=1

RUN pacman -Syu --noconfirm \
    rsync git openssh xh fd sd choose lua ripgrep gzip findutils python docker docker-compose \
    && pacman -Scc --noconfirm
