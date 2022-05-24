FROM archlinux:base-devel

ARG BUILDKIT_INLINE_CACHE=1

RUN pacman -Syu --noconfirm neovim git openssh && pacman -Scc --noconfirm

RUN useradd -m "testuser"

USER 1000:1000

RUN mkdir -p /home/testuser/.config/nvim/lua

WORKDIR /home/testuser/tests

