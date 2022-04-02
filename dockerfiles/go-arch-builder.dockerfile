ARG DOCKER_IMAGE_PREFIX=
FROM ${DOCKER_IMAGE_PREFIX}archlinux:base-devel

ARG BUILDKIT_INLINE_CACHE=1

RUN pacman -Syu --noconfirm go hugo rsync git openssh && pacman -Scc --noconfirm
