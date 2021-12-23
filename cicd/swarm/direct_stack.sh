#!/bin/bash

set -e

export DOCKER_BUILDKIT=1
export SSH_SERVER_NAME=cto
export STACK_NAME=myapp
export REMOTE_PROJECT_PATH="/home/docker/${STACK_NAME}"
export DOCKER_REGISTRY_USERNAME="${DOCKER_REGISTRY_USERNAME?Variable not set}"
export DOCKER_REGISTRY_PASSWORD="${DOCKER_REGISTRY_PASSWORD?Variable not set}"
export DOCKER_REGISTRY="${DOCKER_REGISTRY?Variable not set}"
export DOCKER_IMAGE_PREFIX="${DOCKER_IMAGE_PREFIX?Variable not set}"

docker login -u "${DOCKER_REGISTRY_USERNAME}" -p "${DOCKER_REGISTRY_PASSWORD}" "${DOCKER_REGISTRY}"

docker-compose build
docker-compose push

docker-compose -f docker-compose.yml config > "${STACK_NAME}".yml
scp "${STACK_NAME}".yml "${SSH_SERVER_NAME}:${REMOTE_PROJECT_PATH}/"

ssh -tt -o StrictHostKeyChecking=no "${SSH_SERVER_NAME}" \
"docker login -u ${DOCKER_REGISTRY_USERNAME} -p ${DOCKER_REGISTRY_PASSWORD} ${DOCKER_REGISTRY} \
&& cd ${REMOTE_PROJECT_PATH} && docker stack deploy -c ${STACK_NAME}.yml --with-registry-auth $STACK_NAME"

rm "${STACK_NAME}".yml
