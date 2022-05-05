FROM python:3.10.1-slim as builder

WORKDIR /home/ubuntu

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc git

RUN pip install --no-cache commitizen

USER 1000:1000

WORKDIR /home/ubuntu/repo
